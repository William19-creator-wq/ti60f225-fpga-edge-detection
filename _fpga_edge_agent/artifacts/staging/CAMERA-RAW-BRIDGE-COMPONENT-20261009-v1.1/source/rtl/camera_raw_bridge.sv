// RB01..07：带完整handle的四像素跨域运输；Origin留在稳定核心job快照。
module camera_raw_bridge #(
    parameter integer IMAGE_WIDTH=1920,IMAGE_HEIGHT=1080,BUFFER_DEPTH=1024,
    parameter integer WATCHDOG_CYCLES=50500000
)(
    input logic core_clk,pixel_clk,cold_reset_n,
    input logic job_valid,output wire job_ready,input logic [63:0] job_handle,input logic [194:0] job_origin,
    input logic cancel_valid,input logic [63:0] cancel_handle,
    input logic discard_valid,input logic [63:0] discard_handle,
    input logic [63:0] pixel_data,input logic pixel_valid,hs,vs,rx_fault,
    input logic [3:0] pixel_per_clock,input logic [5:0] datatype,
    input logic [1:0] virtual_channel,input logic [15:0] word_count,
    output wire out_valid,input logic out_ready,output wire [19:0] raw_pair,
    output wire [10:0] out_x_even,out_y,output wire [2:0] out_markers,
    output wire out_bad,output wire [63:0] out_handle,
    output logic done_valid,input logic done_ready,output logic [63:0] done_handle,
    output logic [194:0] done_origin,output logic [1:0] done_outcome,output logic [7:0] done_reason,
    output logic [21:0] done_accepted_groups,done_delivered_pairs,done_discarded_pairs,
    output logic done_shape_complete,done_drained,done_groups_known,
    output wire reception_verified,output logic quarantined,output wire [2:0] phase
);
    localparam integer MAX_GROUPS=IMAGE_WIDTH*IMAGE_HEIGHT/4,TIMER_W=$clog2(WATCHDOG_CYCLES+1);
    typedef enum logic [2:0] {IDLE,RUN,DRAIN,REPORT,WAIT_DISARM,QSTATE} core_state_t;
    core_state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe,term_sync,busy_sync,write_running_sync;
    logic request_toggle,cancel_level,terminal_ack,seen_terminal,terminal_seen,discard_mode;
    logic [63:0] active_handle;logic [194:0] active_origin;
    wire wr_running,wr_ready,wr_valid,wr_accept,wr_overflow,pixel_busy;
    wire [31:0] wr_loss_count;wire [127:0] wr_data,fifo_data;
    wire fifo_valid,fifo_ready,rd_running,rd_fault;
    wire term_toggle;wire [63:0] term_handle;wire [1:0] term_outcome;wire [7:0] term_reason;
    wire [21:0] term_groups;wire [10:0] term_lines;wire term_shape;
    logic [127:0] pair_slot;logic slot_valid,half;
    logic [21:0] popped_groups,delivered_pairs,discarded_pairs,accepted_groups;
    logic [1:0] saved_outcome;logic [7:0] saved_reason;logic saved_shape;
    logic [TIMER_W-1:0] watchdog;
    wire running=reset_pipe==0;
    wire transport_active=state!=IDLE && state!=WAIT_DISARM;
    wire explicit_discard=discard_mode || (discard_valid && discard_handle==active_handle && transport_active);
    assign phase=state;assign reception_verified=1'b0;
    assign job_ready=running && state==IDLE && !quarantined && rd_running && write_running_sync[1] && !busy_sync[1];
    assign fifo_ready=running && transport_active && !slot_valid;
    assign out_valid=running && transport_active && slot_valid && !explicit_discard;
    assign raw_pair=half ? pair_slot[39:20] : pair_slot[19:0];
    assign out_x_even={pair_slot[116:108],2'b00}+(half ? 11'd2 : 11'd0);
    assign out_y=pair_slot[127:117];assign out_handle=pair_slot[103:40];assign out_bad=pair_slot[107];
    assign out_markers=half ? {pair_slot[106:105],1'b0} : {2'b00,pair_slot[104]};
    wire retire=slot_valid && transport_active && (explicit_discard || out_ready);
    wire new_terminal=term_sync[1]!=seen_terminal;

    camera_pixel_framer #(.IMAGE_WIDTH(IMAGE_WIDTH),.IMAGE_HEIGHT(IMAGE_HEIGHT)) framer(
        .pixel_clk,.cold_reset_n,.wr_running,.wr_ready,.request_toggle,.request_handle(active_handle),
        .cancel_level,.terminal_ack,.pixel_data,.pixel_valid,.hs,.vs,.rx_fault,.pixel_per_clock,.datatype,.virtual_channel,.word_count,
        .wr_valid,.wr_data,.busy(pixel_busy),.terminal_toggle(term_toggle),.terminal_handle(term_handle),
        .terminal_outcome(term_outcome),.terminal_reason(term_reason),.terminal_groups(term_groups),.terminal_lines(term_lines),.terminal_shape(term_shape));
    video_async_fifo #(.WIDTH(128),.DEPTH(BUFFER_DEPTH)) records(
        .cold_reset_n,.wr_clk(pixel_clk),.rd_clk(core_clk),.wr_valid,.wr_data,.wr_ready,.wr_accept,.wr_running,.wr_overflow,.wr_loss_count,
        .rd_ready(fifo_ready),.rd_valid(fifo_valid),.rd_data(fifo_data),.rd_running,.rd_fault);

    always_ff @(posedge core_clk or negedge cold_reset_n)
        if(!cold_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge core_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin term_sync<=0;busy_sync<=0;write_running_sync<=0;end
        else begin term_sync<={term_sync[0],term_toggle};busy_sync<={busy_sync[0],pixel_busy};write_running_sync<={write_running_sync[0],wr_running};end
    end
    always_ff @(posedge core_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin
            state<=IDLE;request_toggle<=0;cancel_level<=0;terminal_ack<=0;seen_terminal<=0;terminal_seen<=0;discard_mode<=0;
            active_handle<=0;active_origin<=0;pair_slot<=0;slot_valid<=0;half<=0;
            popped_groups<=0;delivered_pairs<=0;discarded_pairs<=0;accepted_groups<=0;
            saved_outcome<=0;saved_reason<=0;saved_shape<=0;watchdog<=0;quarantined<=0;
            done_valid<=0;done_handle<=0;done_origin<=0;done_outcome<=0;done_reason<=0;
            done_accepted_groups<=0;done_delivered_pairs<=0;done_discarded_pairs<=0;done_shape_complete<=0;done_drained<=0;done_groups_known<=0;
        end else if(running)begin
            if(transport_active)begin
                if(cancel_valid && cancel_handle==active_handle && !terminal_seen)cancel_level<=1;
                if(explicit_discard)discard_mode<=1;
                if(fifo_valid && fifo_ready)begin pair_slot<=fifo_data;slot_valid<=1;half<=0;popped_groups<=popped_groups+22'd1;end
                if(retire)begin
                    if(explicit_discard)discarded_pairs<=discarded_pairs+22'd1;else delivered_pairs<=delivered_pairs+22'd1;
                    if(half)begin slot_valid<=0;half<=0;end else half<=1;
                end
            end
            case(state)
                IDLE: if(job_valid && job_ready)begin
                    active_handle<=job_handle;active_origin<=job_origin;request_toggle<=!request_toggle;state<=RUN;
                    cancel_level<=0;discard_mode<=0;terminal_seen<=0;watchdog<=0;
                    popped_groups<=0;delivered_pairs<=0;discarded_pairs<=0;accepted_groups<=0;saved_shape<=0;
                end
                RUN,DRAIN: begin
                    watchdog<=watchdog+1'b1;
                    if(new_terminal)begin
                        seen_terminal<=term_sync[1];terminal_seen<=1;accepted_groups<=term_groups;
                        saved_outcome<=term_outcome;saved_reason<=term_reason;saved_shape<=term_shape;cancel_level<=0;state<=DRAIN;
                        if(term_outcome==3)quarantined<=1;
                    end
                    if(state==DRAIN && terminal_seen && popped_groups==accepted_groups && !slot_valid)begin
                        done_valid<=1;done_handle<=active_handle;done_origin<=active_origin;
                        done_outcome<=saved_outcome;done_reason<=saved_reason;done_shape_complete<=saved_shape;
                        done_accepted_groups<=accepted_groups;done_delivered_pairs<=delivered_pairs;done_discarded_pairs<=discarded_pairs;
                        done_drained<=1;done_groups_known<=1;state<=REPORT;
                    end else if(watchdog==WATCHDOG_CYCLES-1 ||
                        (new_terminal && (term_handle!=active_handle || term_groups>MAX_GROUPS)) ||
                        (terminal_seen && popped_groups>accepted_groups) ||
                        (slot_valid && pair_slot[103:40]!=active_handle))begin
                        quarantined<=1;state<=REPORT;done_valid<=1;done_handle<=active_handle;done_origin<=active_origin;
                        done_outcome<=3;done_reason<=watchdog==WATCHDOG_CYCLES-1 ? 8'd6 : 8'd7;
                        done_shape_complete<=0;done_drained<=0;done_groups_known<=terminal_seen;
                        done_accepted_groups<=terminal_seen ? accepted_groups : 22'd0;
                        done_delivered_pairs<=delivered_pairs;done_discarded_pairs<=discarded_pairs;
                    end
                end
                REPORT: if(done_valid && done_ready)begin
                    done_valid<=0;
                    if(terminal_seen)terminal_ack<=seen_terminal;
                    state<=quarantined ? QSTATE : WAIT_DISARM;
                end
                WAIT_DISARM: if(!busy_sync[1])begin state<=IDLE;cancel_level<=0;discard_mode<=0;end
                QSTATE: cancel_level<=1;
                default: state<=QSTATE;
            endcase
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%4!=0 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || WATCHDOG_CYCLES<64)$fatal(1,"Camera bridge parameters");
    // synthesis translate_on
endmodule
