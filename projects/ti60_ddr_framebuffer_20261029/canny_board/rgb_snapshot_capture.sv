// Capture ONE complete source frame without stalling live video. Optional
// GRAY_ONLY uses exactly the Canny grayscale formula and one byte per pixel.
// A start/end record fences each capture across the asynchronous FIFO. FIFO full
// discards the whole snapshot explicitly; it never resets/reuses in-flight data.
// The writer's completion AND the video end fence are required before publishing.
// Memory addresses/handles are granted by frame_owner; this module cannot grant
// itself a slot. cold_reset_n must coincide with DDR reset or proven quiescence.
module rgb_snapshot_capture #(
    parameter integer WIDTH=1920, HEIGHT=1080, FIFO_DEPTH=1024, GRAY_ONLY=0,HISTORY_SOURCE=0
)(
    input logic cold_reset_n, video_clk, core_clk,
    input logic video_vs,video_de,input logic [47:0] video_rgb,
    input wire video_source_valid,input wire [5:0] video_source_slot,input wire [63:0] video_source_id,
    output reg source_pin_valid,output reg [5:0] source_pin_slot,
    input logic job_valid,output wire job_ready,
    input logic [31:0] job_base,job_config_id,input logic [63:0] job_handle,
    input logic cancel_valid,input logic [63:0] cancel_handle,
    output wire done_valid,input logic done_ready,
    output logic done_good,output logic [7:0] done_reason,
    output logic [63:0] done_handle,done_frame_id,output logic [31:0] done_config_id,
    output wire quarantined,
    output wire line_req_valid,input logic line_req_ready,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic line_error,line_drained,
    output logic [31:0] dropped_frames,output wire [31:0] captured_pairs
);
    localparam integer PAIRS=WIDTH*HEIGHT/2, BYTES=WIDTH*HEIGHT*(GRAY_ONLY?1:3);
    (* ASYNC_REG="TRUE" *) logic [1:0] video_reset_pipe,core_reset_pipe;
    wire video_reset=|video_reset_pipe, core_reset=|core_reset_pipe;
    always_ff @(posedge video_clk or negedge cold_reset_n)
        if(!cold_reset_n)video_reset_pipe<=3;else video_reset_pipe<={video_reset_pipe[0],1'b0};
    always_ff @(posedge core_clk or negedge cold_reset_n)
        if(!cold_reset_n)core_reset_pipe<=3;else core_reset_pipe<={core_reset_pipe[0],1'b0};
    // The live video signals are untouched outside this snapshot module.
    // In grayscale mode, VS/DE traverse the converter's SAME three metadata
    // stages as its numerical result. Start/end fences therefore still frame
    // exactly the same source pixels; invalid startup stages cannot arm a frame.
    wire capture_vs,capture_de;
    wire [47:0] capture_rgb;
    generate if(GRAY_ONLY)begin:gray_snapshot
        wire valid,delayed_vs,delayed_de;
        wire [15:0] luminance;
        cny_rgb_to_y_pair converter(
            .clk(video_clk),.rst(video_reset),.frame_start(1'b0),.flush(1'b0),
            .in_valid(1'b1),.in_ready(),.in_rgb(video_rgb),
            .in_x_even(11'd0),.in_y(11'd0),.in_sof(video_vs),.in_eol(video_de),.in_eof(1'b0),
            .out_valid(valid),.out_ready(1'b1),.out_y_pair(luminance),
            .out_x_even(),.out_y(),.out_sof(delayed_vs),.out_eol(delayed_de),.out_eof(),.empty());
        assign capture_vs=valid&&delayed_vs;
        assign capture_de=valid&&delayed_de;
        assign capture_rgb={32'd0,luminance}; // two byte pixels, low byte first
    end else begin:rgb_snapshot
        assign capture_vs=video_vs;assign capture_de=video_de;assign capture_rgb=video_rgb;
    end endgenerate
    logic arm_toggle;
    (* ASYNC_REG="TRUE" *) logic arm_meta,arm_sync;
    logic arm_seen,vs_d,de_d;
    logic [63:0] video_frame;
    logic [31:0] pair_count,row_pairs,row_count;
    logic bad_frame;
    logic source_seen,source_meta_pending;
    logic [63:0] source_id_hold;logic [5:0] source_slot_hold;
    logic [7:0] video_reason;
    typedef enum logic [1:0] {V_IDLE,V_WAIT,V_CAPTURE,V_END} video_state_t;
    video_state_t video_state;
    wire boundary=capture_vs && !vs_d;
    wire fifo_wr_ready,fifo_wr_accept,fifo_wr_running,fifo_wr_overflow;
    wire fifo_rd_valid,fifo_rd_running,fifo_rd_fault;
    logic fifo_wr_valid,fifo_rd_ready;
    logic [79:0] fifo_wr_data;
    wire [79:0] fifo_rd_data;
    wire [31:0] fifo_losses;
    video_async_fifo #(.WIDTH(80),.DEPTH(FIFO_DEPTH)) transport(
        .cold_reset_n,.wr_clk(video_clk),.rd_clk(core_clk),
        .wr_valid(fifo_wr_valid),.wr_data(fifo_wr_data),.wr_ready(fifo_wr_ready),
        .wr_accept(fifo_wr_accept),.wr_running(fifo_wr_running),.wr_overflow(fifo_wr_overflow),.wr_loss_count(fifo_losses),
        .rd_ready(fifo_rd_ready),.rd_valid(fifo_rd_valid),.rd_data(fifo_rd_data),.rd_running(fifo_rd_running),.rd_fault(fifo_rd_fault)
    );
    // Only submit records when credit exists. Unlike video pixels, the end fence
    // is retryable. The explicit bad_frame flag accounts for every dropped pixel.
    always_comb begin
        fifo_wr_valid=0;fifo_wr_data=0;
        if(!video_reset && fifo_wr_ready)begin
            if(video_state==V_WAIT && boundary)begin
                fifo_wr_valid=1;fifo_wr_data={2'd1,14'd0,video_frame+64'd1};
            end else if(video_state==V_CAPTURE && !boundary && capture_de && !bad_frame)begin
                fifo_wr_valid=1;fifo_wr_data={2'd0,30'd0,capture_rgb};
            end else if(HISTORY_SOURCE&&source_meta_pending&&((video_state==V_CAPTURE&&!capture_de)||video_state==V_END))begin
                fifo_wr_valid=1;fifo_wr_data={2'd3,8'd0,source_slot_hold,source_id_hold};
            end else if(video_state==V_END)begin
                fifo_wr_valid=1;fifo_wr_data={2'd2,bad_frame,5'd0,video_reason,32'd0,pair_count};
            end
        end
    end
    always_ff @(posedge video_clk)begin
        if(video_reset)begin
            arm_meta<=0;arm_sync<=0;arm_seen<=0;vs_d<=0;de_d<=0;video_frame<=0;
            video_state<=V_IDLE;pair_count<=0;row_pairs<=0;row_count<=0;bad_frame<=0;video_reason<=0;
            source_seen<=0;source_meta_pending<=0;source_id_hold<=0;source_slot_hold<=0;
        end else begin
            arm_meta<=arm_toggle;arm_sync<=arm_meta;vs_d<=capture_vs;de_d<=capture_de;
            if(boundary)video_frame<=video_frame+64'd1;
            if(fifo_wr_accept&&fifo_wr_data[79:78]==3)source_meta_pending<=0;
            case(video_state)
                V_IDLE:if(arm_sync!=arm_seen)begin arm_seen<=arm_sync;video_state<=V_WAIT;end
                V_WAIT:if(boundary && fifo_wr_accept)begin
                    video_state<=V_CAPTURE;pair_count<=0;row_pairs<=0;row_count<=0;
                    bad_frame<=capture_de;video_reason<=capture_de?8'd1:8'd0;
                    source_seen<=0;source_meta_pending<=0;
                end
                V_CAPTURE:begin
                    if(boundary)begin
                        video_state<=V_END;
                        if(pair_count!=PAIRS || row_count+(de_d?1:0)!=HEIGHT ||
                           (de_d && row_pairs!=WIDTH/2) || capture_de)begin
                            bad_frame<=1;if(!bad_frame)video_reason<=8'd2;
                        end
                    end else begin
                        if(capture_de)begin
                            // Source mailbox settles in vertical blanking. Sample it
                            // with the first actual pixel, not the earlier VS edge.
                            if(HISTORY_SOURCE)begin
                                if(!source_seen)begin
                                    source_seen<=1;source_meta_pending<=1;
                                    source_id_hold<=video_source_id;source_slot_hold<=video_source_slot;
                                end
                                if(!video_source_valid||(source_seen&&(video_source_id!=source_id_hold||video_source_slot!=source_slot_hold)))begin
                                    bad_frame<=1;video_reason<=8'd9;
                                end
                            end
                            pair_count<=pair_count+32'd1;row_pairs<=row_pairs+32'd1;
                            if(!fifo_wr_ready && !bad_frame)begin bad_frame<=1;video_reason<=8'd3;end
                            if(pair_count>=PAIRS || row_pairs>=WIDTH/2 || row_count>=HEIGHT)begin
                                bad_frame<=1;if(!bad_frame)video_reason<=8'd2;
                            end
                        end
                        if(!capture_de && de_d)begin
                            row_pairs<=0;row_count<=row_count+32'd1;
                            if(row_pairs!=WIDTH/2)begin bad_frame<=1;if(!bad_frame)video_reason<=8'd2;end
                        end
                    end
                end
                V_END:if(fifo_wr_accept&&fifo_wr_data[79:78]==2)video_state<=V_IDLE;
            endcase
        end
    end

    typedef enum logic [2:0] {C_IDLE,C_CONFIG,C_ARM,C_STREAM,C_DRAIN,C_REPLY} core_state_t;
    core_state_t core_state;
    logic [31:0] base_locked,popped_pairs;
    logic [10:0] x,y;
    logic abort_pending,start_seen,end_seen,writer_finished,writer_ok;
    logic [7:0] failure_reason;
    wire writer_job_ready,writer_config_valid,writer_config_error;
    wire writer_in_ready,writer_done,writer_stop,writer_quarantine;
    wire [1:0] writer_outcome;
    wire [7:0] writer_reason;
    wire [63:0] writer_done_id;
    wire [21:0] writer_pairs;
    wire pixel_record=fifo_rd_data[79:78]==0;
    wire start_record=fifo_rd_data[79:78]==1;
    wire end_record=fifo_rd_data[79:78]==2;
    wire source_record=fifo_rd_data[79:78]==3;
    wire receiving=core_state==C_STREAM || core_state==C_DRAIN;
    wire matching_cancel=cancel_valid && cancel_handle==done_handle && core_state!=C_IDLE && core_state!=C_REPLY;
    wire writer_input=receiving && fifo_rd_valid && pixel_record && start_seen && !end_seen && !abort_pending && !matching_cancel && !writer_stop && !writer_finished;
    wire writer_cancel=(abort_pending || matching_cancel) && !writer_finished;
    assign job_ready=!core_reset && core_state==C_IDLE && fifo_rd_running && writer_job_ready && !quarantined;
    assign done_valid=!core_reset && core_state==C_REPLY;
    assign quarantined=writer_quarantine || fifo_rd_fault;
    assign captured_pairs={10'd0,writer_pairs};
    always_comb begin
        fifo_rd_ready=0;
        if(receiving && fifo_rd_valid)begin
            if(!pixel_record || !start_seen || end_seen || abort_pending || matching_cancel || writer_stop || writer_finished)fifo_rd_ready=1;
            else fifo_rd_ready=writer_in_ready;
        end
    end
    rgb_source_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.GRAY_ONLY(GRAY_ONLY)) writer(
        .clk(core_clk),.rst(core_reset),.job_valid(core_state==C_CONFIG),.job_ready(writer_job_ready),
        .job_base(base_locked),.job_handle(done_handle),.job_rsp_valid(writer_config_valid),
        .job_rsp_ready(1'b1),.job_rsp_error(writer_config_error),
        .in_valid(writer_input),.in_ready(writer_in_ready),.in_rgb(fifo_rd_data[47:0]),
        .in_x_even(x),.in_y(y),.in_markers({popped_pairs==PAIRS-1,x==WIDTH-2,popped_pairs==0}),
        .in_bad(1'b0),.in_handle(done_handle),.cancel_valid(writer_cancel),.cancel_id(done_handle),
        .done_valid(writer_done),.done_ready(!writer_finished),.done_id(writer_done_id),
        .outcome(writer_outcome),.reason(writer_reason),.accepted_pairs(writer_pairs),.written_lines(),
        .logical_bytes(),.physical_bytes(),.source_stop(writer_stop),.quarantined(writer_quarantine),
        .line_req_valid,.line_req_ready,.line_write(),.line_addr,.line_wdata,
        .line_rsp_valid,.line_rsp_ready,.line_rdata(512'd0),.line_error,.line_drained
    );
    always_ff @(posedge core_clk)begin
        if(core_reset)begin
            core_state<=C_IDLE;arm_toggle<=0;base_locked<=0;done_handle<=0;done_config_id<=0;done_frame_id<=0;
            done_good<=0;done_reason<=0;abort_pending<=0;start_seen<=0;end_seen<=0;writer_finished<=0;writer_ok<=0;
            popped_pairs<=0;x<=0;y<=0;failure_reason<=0;dropped_frames<=0;
            source_pin_valid<=0;source_pin_slot<=0;
        end else begin
            if(matching_cancel)begin abort_pending<=1;failure_reason<=8'd128;end
            if(writer_done && !writer_finished)begin
                writer_finished<=1;writer_ok<=writer_outcome==0 && writer_done_id==done_handle;
                if(writer_outcome!=0 && failure_reason==0)failure_reason<=writer_reason;
            end
            if(receiving && fifo_rd_valid && fifo_rd_ready)begin
                if(start_record && !start_seen && !end_seen)begin start_seen<=1;done_frame_id<=fifo_rd_data[63:0];end
                else if(HISTORY_SOURCE&&source_record&&start_seen&&!end_seen&&!source_pin_valid)begin
                    source_pin_valid<=1;source_pin_slot<=fifo_rd_data[69:64];done_frame_id<=fifo_rd_data[63:0];
                end
                else if(pixel_record && start_seen && !end_seen)begin
                    popped_pairs<=popped_pairs+32'd1;
                    if(x==WIDTH-2)begin x<=0;y<=y+11'd1;end else x<=x+11'd2;
                end else if(end_record && !end_seen)begin
                    end_seen<=1;core_state<=C_DRAIN;
                    if(fifo_rd_data[77] || !start_seen || (HISTORY_SOURCE&&!source_pin_valid) || popped_pairs!=PAIRS || fifo_rd_data[31:0]!=PAIRS)begin
                        abort_pending<=1;
                        if(failure_reason==0)failure_reason<=fifo_rd_data[71:64]!=0 ? fifo_rd_data[71:64]:8'd2;
                    end
                end else begin abort_pending<=1;failure_reason<=8'd4;end
            end
            case(core_state)
                C_IDLE:if(job_valid && job_ready)begin
                    base_locked<=job_base;done_handle<=job_handle;done_config_id<=job_config_id;
                    done_frame_id<=0;done_good<=0;done_reason<=0;popped_pairs<=0;x<=0;y<=0;
                    source_pin_valid<=0;
                    abort_pending<=0;start_seen<=0;end_seen<=0;writer_finished<=0;writer_ok<=0;failure_reason<=0;
                    if(job_base[5:0]!=0 || job_base<32'h04000000 || ({1'b0,job_base}+33'(((BYTES+63)/64)*64))>33'h06000000)begin
                        done_reason<=8'd5;core_state<=C_REPLY;dropped_frames<=dropped_frames+32'd1;
                    end else core_state<=C_CONFIG;
                end
                C_CONFIG:if(writer_job_ready)core_state<=C_ARM;
                C_ARM:if(writer_config_valid)begin
                    if(writer_config_error)begin done_reason<=8'd5;core_state<=C_REPLY;dropped_frames<=dropped_frames+32'd1;end
                    else begin arm_toggle<=!arm_toggle;core_state<=C_STREAM;end
                end
                C_DRAIN:if(end_seen && writer_finished && !quarantined)begin
                    done_good<=writer_ok && !abort_pending && !matching_cancel;
                    done_reason<=failure_reason;
                    if(!writer_ok || abort_pending || matching_cancel)dropped_frames<=dropped_frames+32'd1;
                    core_state<=C_REPLY;
                end
                C_REPLY:if(done_ready)core_state<=C_IDLE;
                default:begin end
            endcase
        end
    end
endmodule
