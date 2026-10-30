// Three row banks, each with a core-clock write port and video-clock read port.
// Immutable frame/config mailbox, VS-only switch, and explicit old AXI drain ACK.
// Production width is 1920; supported test widths are multiples of 16.
// EDGE_ONLY omits unused RGB DDR transactions. Frame/row ownership,
// burst drain, result byte format, scan timing and publication ACK are unchanged.
// Keep the default RGB path for consumers that actually use out_rgb snapshots.
module integration_frame_reader #(parameter integer W=1920,H=1080,EDGE_ONLY=0,HISTORY_LOCK=0)(
    input logic core_clk,video_clk,cold_reset_n,enable,
    input logic publish_toggle,publish_slot,input logic [63:0] publish_frame,
    input wire [5:0] publish_source_slot,output reg [5:0] display_source_slot,
    input wire source_lock,lock_source_valid,input wire [63:0] lock_source_id,input wire [31:0] required_config_id,
    output reg discarded_valid,output reg [63:0] discarded_frame,
    input logic [10:0] publish_threshold,input logic [1:0] publish_filter,
    input logic [31:0] publish_config_id,input logic [63:0] publish_sensor_frame,publish_processing_cycles,
    input logic publish_recognition,publish_target_overflow,input logic [3:0] publish_target_mask,
    input logic [7:0] publish_target_class,publish_unknown_reasons,input logic [21:0] publish_unknown_count,
    input logic [175:0] publish_target_box,input logic [95:0] publish_target_center2,
    input logic in_vs,in_hs,in_de,input logic [47:0] in_rgb,input logic freeze_request,use_snapshot,
    output logic out_vs,out_hs,out_de,output logic [47:0] out_rgb,
    output logic [1:0] out_edges,output logic out_snapshot_valid,output logic frozen,
    output wire [95:0] display_scope,output wire [63:0] display_sensor_frame,display_processing_cycles,
    output wire display_recognition,display_target_overflow,output wire [3:0] display_target_mask,
    output wire [7:0] display_target_class,display_unknown_reasons,output wire [21:0] display_unknown_count,
    output wire [175:0] display_target_box,output wire [95:0] display_target_center2,
    output logic display_valid,output logic [10:0] display_threshold,output logic [1:0] display_filter,
    output logic retired_valid,output logic [63:0] retired_frame,
    output logic [31:0] underflow_rows,output wire quarantined,
    output wire arvalid,input logic arready,output logic [31:0] araddr,
    output wire [3:0] arid,output logic [7:0] arlen,
    input logic rvalid,output wire rready,input logic [127:0] rdata,
    input logic [3:0] rid,input logic [1:0] rresp,input logic rlast
);
    (* ASYNC_REG="TRUE" *) logic [1:0] core_reset_pipe,video_reset_pipe;
    always_ff @(posedge core_clk or negedge cold_reset_n)
        if(!cold_reset_n)core_reset_pipe<=3;else core_reset_pipe<={core_reset_pipe[0],1'b0};
    always_ff @(posedge video_clk or negedge cold_reset_n)
        if(!cold_reset_n)video_reset_pipe<=3;else video_reset_pipe<={video_reset_pipe[0],1'b0};
    wire rst=|core_reset_pipe,video_rst=|video_reset_pipe;
    logic [2:0] done_toggle,release_toggle;
    (* ASYNC_REG="TRUE" *) logic [2:0] release_sync0,release_sync1,done_sync0,done_sync1;
    logic [31:0] bank_generation[0:2];logic [10:0] bank_row[0:2];logic [2:0] bank_good;
    logic [31:0] visible_generation[0:2];logic [10:0] visible_row[0:2];logic [2:0] visible_good,done_seen;
    (* ASYNC_REG="TRUE" *) logic [1:0] publish_sync;
    logic publish_seen,vs_previous,current_slot;
    logic [63:0] current_frame,current_sensor_frame,current_processing_cycles;
    logic [31:0] current_config_id;
    logic current_recognition,current_target_overflow;
    logic [3:0] current_target_mask;logic [7:0] current_target_class,current_unknown_reasons;
    logic [21:0] current_unknown_count;logic [175:0] current_target_box;logic [95:0] current_target_center2;
    logic frame_snapshot;
    assign display_scope={current_config_id,current_frame};
    assign display_sensor_frame=current_sensor_frame;assign display_processing_cycles=current_processing_cycles;
    assign display_recognition=current_recognition;assign display_target_overflow=current_target_overflow;
    assign display_target_mask=current_target_mask;assign display_target_class=current_target_class;
    assign display_unknown_reasons=current_unknown_reasons;assign display_unknown_count=current_unknown_count;
    assign display_target_box=current_target_box;assign display_target_center2=current_target_center2;
    logic request_toggle,request_valid,request_slot;
    logic [63:0] request_frame;
    logic [31:0] request_generation,scan_generation;
    (* ASYNC_REG="TRUE" *) logic [1:0] request_sync;
    logic request_seen;
    logic [10:0] x,y;
    logic [1:0] video_bank;
    logic row_good;
    wire frame_start=in_vs&&!vs_previous;
    wire publication_allowed=HISTORY_LOCK?
        (!source_lock||(!display_valid&&!lock_source_valid)||
         (lock_source_valid&&publish_sensor_frame==lock_source_id&&publish_config_id==required_config_id)):
        (!freeze_request||!display_valid);
    reg discard_toggle,discard_seen;
    reg [63:0] discard_frame_hold;
    (* ASYNC_REG="TRUE" *) reg [1:0] discard_sync;
    // Rejected publications were never read. Return their handle without
    // retiring the visible result bank; the worker must reuse its back bank.
    always_ff @(posedge core_clk)begin
        discarded_valid<=0;
        if(rst)begin discard_sync<=0;discard_seen<=0;discarded_frame<=0;end
        else begin
            discard_sync<={discard_sync[0],discard_toggle};
            if(discard_sync[1]!=discard_seen)begin
                discard_seen<=discard_sync[1];discarded_frame<=discard_frame_hold;discarded_valid<=1;
            end
        end
    end
    wire row_available=display_valid&&visible_good[video_bank]&&
        visible_generation[video_bank]==scan_generation&&visible_row[video_bank]==y;
    wire pixel_available=(x==0)?row_available:row_good;
    wire [12:0] rgb_offset={2'b0,x}+({2'b0,x}<<1);
    wire [12:0] last_rgb_byte=rgb_offset+13'd5;
    wire crossing=rgb_offset[3:0]>10;
    wire [127:0] rgb_read;
    logic [127:0] previous_rgb_read;
    wire [15:0] edge_read;
    logic [3:0] position_saved,edge_position_saved;
    logic crossing_saved,available_saved,vs_saved,hs_saved,de_saved;
    logic [47:0] live_saved;
    logic snapshot_saved;
    wire [255:0] assembled=crossing_saved?{rgb_read,previous_rgb_read}:{128'd0,rgb_read};
    wire [47:0] rgb_bytes=48'(assembled>>{position_saved,3'b000});
    wire [1:0] edge_bits=2'(edge_read>>edge_position_saved);
    // DDR stores R0,G0,B0,R1,G1,B1; canonical pixel is {R,G,B}.
    wire [47:0] frame_rgb={rgb_bytes[31:24],rgb_bytes[39:32],rgb_bytes[47:40],rgb_bytes[7:0],rgb_bytes[15:8],rgb_bytes[23:16]};
    integer b;
    always_ff @(posedge video_clk)begin
        if(video_rst)begin
            publish_sync<=0;publish_seen<=0;vs_previous<=0;current_slot<=0;current_frame<=0;display_valid<=0;
            display_source_slot<=0;current_config_id<=0;current_sensor_frame<=0;current_processing_cycles<=0;current_recognition<=0;
            current_target_overflow<=0;current_target_mask<=0;current_target_class<=0;current_unknown_reasons<=0;
            current_unknown_count<=0;current_target_box<=0;current_target_center2<=0;
            frozen<=0;frame_snapshot<=0;
            discard_toggle<=0;discard_frame_hold<=0;
            display_threshold<=96;display_filter<=1;request_toggle<=0;request_valid<=0;request_slot<=0;request_frame<=0;
            request_generation<=0;scan_generation<=0;x<=0;y<=0;video_bank<=0;row_good<=0;
            done_sync0<=0;done_sync1<=0;done_seen<=0;visible_good<=0;release_toggle<=0;underflow_rows<=0;
            for(integer i=0;i<3;i++)begin visible_generation[i]<=0;visible_row[i]<=0;end
        end else begin
            publish_sync<={publish_sync[0],publish_toggle};
            done_sync0<=done_toggle;done_sync1<=done_sync0;vs_previous<=in_vs;
            for(integer i=0;i<3;i++)if(done_sync1[i]!=done_seen[i])begin
                done_seen[i]<=done_sync1[i];visible_generation[i]<=bank_generation[i];
                visible_row[i]<=bank_row[i];visible_good[i]<=bank_good[i];
            end
            if(frame_start)begin
                // Freeze keeps the complete published owner. A second slot may
                // finish in the worker, but is not retired/reused until resume.
                // Requesting freeze before the first result accepts that first
                // complete result and holds it; no partial capture is exposed.
                frame_snapshot<=use_snapshot||freeze_request;
                frozen<=freeze_request&&(display_valid||publish_sync[1]!=publish_seen);
                x<=0;y<=0;video_bank<=0;row_good<=0;scan_generation<=scan_generation+1;
                request_generation<=scan_generation+1;request_toggle<=!request_toggle;
                if(publication_allowed&&publish_sync[1]!=publish_seen)begin
                    publish_seen<=publish_sync[1];current_slot<=publish_slot;current_frame<=publish_frame;
                    display_source_slot<=publish_source_slot;current_config_id<=publish_config_id;current_sensor_frame<=publish_sensor_frame;current_processing_cycles<=publish_processing_cycles;
                    current_recognition<=publish_recognition;current_target_mask<=publish_target_mask;current_target_class<=publish_target_class;
                    current_target_box<=publish_target_box;current_target_center2<=publish_target_center2;
                    current_unknown_count<=publish_unknown_count;current_unknown_reasons<=publish_unknown_reasons;current_target_overflow<=publish_target_overflow;
                    display_threshold<=publish_threshold;display_filter<=publish_filter;display_valid<=1;
                    request_slot<=publish_slot;request_frame<=publish_frame;request_valid<=1;
                end else begin
                    request_slot<=current_slot;request_frame<=current_frame;request_valid<=display_valid;
                    if(HISTORY_LOCK&&publish_sync[1]!=publish_seen)begin
                        publish_seen<=publish_sync[1];discard_frame_hold<=publish_frame;discard_toggle<=!discard_toggle;
                    end
                end
            end else if(in_de)begin
                if(x==0)begin row_good<=row_available;if(display_valid&&!row_available)underflow_rows<=underflow_rows+1;end
                if(x==W-2)begin
                    x<=0;y<=y==H-1?11'd0:y+11'd1;video_bank<=video_bank==2?2'd0:video_bank+2'd1;
                    release_toggle[video_bank]<=!release_toggle[video_bank];
                end else x<=x+11'd2;
            end
        end
    end
    // Return canonical RGB and matching Canny bits separately. The following
    // streaming presenter performs grayscale/median/Sobel on this exact RGB.
    // Snapshot ownership and metadata change only during vertical blanking.
    always_ff @(posedge video_clk)begin
        previous_rgb_read<=rgb_read;
        if(video_rst)begin
            position_saved<=0;edge_position_saved<=0;crossing_saved<=0;available_saved<=0;
            vs_saved<=0;hs_saved<=0;de_saved<=0;live_saved<=0;snapshot_saved<=0;
            out_vs<=0;out_hs<=0;out_de<=0;out_rgb<=0;out_edges<=0;out_snapshot_valid<=0;
        end else begin
            position_saved<=rgb_offset[3:0];edge_position_saved<=x[3:0];crossing_saved<=crossing;
            available_saved<=pixel_available;vs_saved<=in_vs;hs_saved<=in_hs;de_saved<=in_de;
            live_saved<=in_rgb;snapshot_saved<=frame_snapshot;
            out_vs<=vs_saved;out_hs<=hs_saved;out_de<=de_saved;
            out_rgb<=snapshot_saved?((!EDGE_ONLY&&available_saved)?frame_rgb:48'd0):live_saved;
            out_edges<=snapshot_saved&&available_saved?edge_bits:2'd0;
            out_snapshot_valid<=snapshot_saved&&available_saved&&de_saved;
        end
    end
    typedef enum logic [2:0] {IDLE,WAIT_BANK,PREPARE,ADDRESS,READ_DATA,FAULT} state_t;
    state_t state;
    logic [31:0] generation,source_row_address,result_row_address;
    logic [10:0] row;
    logic [1:0] bank;
    logic [2:0] busy,release_at_start;
    logic edge_part,row_bad;
    logic [12:0] bytes_left,offset;
    logic [6:0] beats_left;
    logic [10:0] burst_bytes;
    logic [8:0] memory_word;
    wire new_request=request_sync[1]!=request_seen;
    wire [12:0] page_left=13'd4096-{1'b0,araddr[11:0]};
    wire [12:0] maximum_bytes=bytes_left<1024?bytes_left:13'd1024;
    wire [12:0] next_burst=maximum_bytes<page_left?maximum_bytes:page_left;
    wire row_write=!rst&&state==READ_DATA&&rvalid&&rready&&rid==4'hd&&rlast==(beats_left==1)&&rresp==0;
    wire [127:0] rgb_bank_read[0:2];
    logic [1:0] read_bank;
    always_ff @(posedge video_clk)read_bank<=video_bank;
    assign rgb_read=rgb_bank_read[read_bank];
    for(genvar row_bank=0;row_bank<3;row_bank++)begin:rgb_bank
        canny_row_ram colour(
            .write_clk(core_clk),.write_enable(row_write&&!edge_part&&bank==row_bank),.write_address(memory_word),.write_data(rdata),
            .read_clk(video_clk),.read_enable(in_de&&video_bank==row_bank),.read_address(last_rgb_byte[12:4]),.read_data(rgb_bank_read[row_bank]));
    end
    wire [15:0] packed_edges;
    for(genvar pixel=0;pixel<16;pixel++)assign packed_edges[pixel]=|rdata[pixel*8+:8];
    canny_row_ram #(.WIDTH(16)) edge_cache(
        .write_clk(core_clk),.write_enable(row_write&&edge_part),.write_address({bank,memory_word[6:0]}),.write_data(packed_edges),
        .read_clk(video_clk),.read_enable(in_de),.read_address({video_bank,7'd0}+{2'd0,x[10:4]}),.read_data(edge_read));
    assign arvalid=!rst&&state==ADDRESS;
    assign arid=4'hd;
    assign rready=!rst&&state==READ_DATA;
    assign quarantined=state==FAULT;
    always_ff @(posedge core_clk)begin
        if(rst)begin
            request_sync<=0;request_seen<=0;release_sync0<=0;release_sync1<=0;
            state<=IDLE;generation<=0;source_row_address<=0;result_row_address<=0;row<=0;bank<=0;
            busy<=0;release_at_start<=0;edge_part<=0;row_bad<=0;bytes_left<=0;offset<=0;beats_left<=0;burst_bytes<=0;
            araddr<=0;arlen<=0;memory_word<=0;done_toggle<=0;bank_good<=0;retired_valid<=0;retired_frame<=0;
            for(integer i=0;i<3;i++)begin bank_generation[i]<=0;bank_row[i]<=0;end
        end else begin
            request_sync<={request_sync[0],request_toggle};release_sync0<=release_toggle;release_sync1<=release_sync0;
            // Never retract an already public AR or abandon its R tail.
            if(new_request&&state!=ADDRESS&&state!=READ_DATA&&state!=FAULT)begin
                request_seen<=request_sync[1];generation<=request_generation;row<=0;bank<=0;busy<=0;
                source_row_address<=request_slot?32'h04800000:32'h04000000;
                result_row_address<=request_slot?32'h06200000:32'h06000000;
                retired_valid<=request_valid;retired_frame<=request_frame;
                state<=request_valid?WAIT_BANK:IDLE;
            end else case(state)
                IDLE:begin end
                WAIT_BANK:if(enable&&(!busy[bank]||release_sync1[bank]!=release_at_start[bank]))begin
                    busy[bank]<=1;release_at_start[bank]<=release_sync1[bank];edge_part<=EDGE_ONLY!=0;row_bad<=0;
                    // M5 consumes only out_edges: start directly in the result
                    // region. Do not spend six RGB bursts before two edge bursts.
                    araddr<=EDGE_ONLY!=0?result_row_address:source_row_address;
                    bytes_left<=EDGE_ONLY!=0?13'(W):13'(W*3);
                    offset<=0;memory_word<=0;state<=PREPARE;
                end
                PREPARE:begin burst_bytes<=11'(next_burst);beats_left<=7'(next_burst>>4);arlen<=8'((next_burst>>4)-1);state<=ADDRESS;end
                ADDRESS:if(arready)state<=READ_DATA;
                READ_DATA:if(rvalid)begin
                    if(rid!=4'hd||rlast!=(beats_left==1))state<=FAULT;
                    else begin
                        if(rresp!=0)row_bad<=1;
                        memory_word<=memory_word+1;beats_left<=beats_left-1;
                        if(beats_left==1)begin
                            if(bytes_left>burst_bytes)begin bytes_left<=bytes_left-burst_bytes;offset<=offset+burst_bytes;araddr<=araddr+burst_bytes;state<=PREPARE;end
                            else if(!edge_part)begin edge_part<=1;araddr<=result_row_address;bytes_left<=13'(W);offset<=0;memory_word<=0;state<=PREPARE;end
                            else begin
                                bank_generation[bank]<=generation;bank_row[bank]<=row;bank_good[bank]<=!row_bad&&rresp==0;
                                done_toggle[bank]<=!done_toggle[bank];source_row_address<=source_row_address+W*3;result_row_address<=result_row_address+W;
                                row<=row+1;bank<=bank==2?2'd0:bank+2'd1;state<=row==H-1?IDLE:WAIT_BANK;
                            end
                        end
                    end
                end
                FAULT:begin end
                default:state<=FAULT;
            endcase
        end
    end
    // synthesis translate_off
    initial if(W<16||W>1920||W%16||H<5||H>1080)$fatal(1,"Unsupported display dimensions");
    // synthesis translate_on
endmodule
