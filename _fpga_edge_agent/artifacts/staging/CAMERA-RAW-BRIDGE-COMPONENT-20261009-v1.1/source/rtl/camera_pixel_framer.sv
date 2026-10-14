// RB01/02/03/04：像素域形状检查。只报告本地停止/形状，不认证CSI CRC。
module camera_pixel_framer #(
    parameter integer IMAGE_WIDTH=1920, IMAGE_HEIGHT=1080
)(
    input logic pixel_clk,cold_reset_n,wr_running,wr_ready,
    input logic request_toggle,input logic [63:0] request_handle,
    input logic cancel_level,terminal_ack,
    input logic [63:0] pixel_data,input logic pixel_valid,hs,vs,rx_fault,
    input logic [3:0] pixel_per_clock,input logic [5:0] datatype,
    input logic [1:0] virtual_channel,input logic [15:0] word_count,
    output wire wr_valid,output wire [127:0] wr_data,output wire busy,
    output logic terminal_toggle,output logic [63:0] terminal_handle,
    output logic [1:0] terminal_outcome,output logic [7:0] terminal_reason,
    output logic [21:0] terminal_groups,output logic [10:0] terminal_lines,
    output logic terminal_shape
);
    localparam integer LINE_GROUPS=IMAGE_WIDTH/4;
    typedef enum logic [2:0] {DISARMED,WAIT_IDLE,WAIT_SOF,FRAME,WAIT_END,TERM} pixel_state_t;
    pixel_state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] reset_pipe,request_sync,cancel_sync,ack_sync;
    logic seen_request,old_hs,old_vs,line_started;
    logic [63:0] active_handle;
    logic [9:0] line_groups;
    logic [10:0] row;
    logic [21:0] accepted_groups;
    logic fail;logic [1:0] failure_outcome;logic [7:0] failure_reason;
    wire running=reset_pipe==0;
    wire start_frame=state==WAIT_SOF && vs && !old_vs;
    wire collecting=state==FRAME || start_frame;
    wire hfall=old_hs && !hs,vfall=old_vs && !vs;
    wire metadata_good=pixel_per_clock==4 && datatype==6'h2b && virtual_channel==0 && word_count==16'(IMAGE_WIDTH*5/4);
    wire geometry_good=hs && vs && line_groups<LINE_GROUPS && row<IMAGE_HEIGHT;
    // 错误优先禁止本沿写；容量不足仍给FIFO一个实际拒绝事件。
    assign wr_valid=running && collecting && pixel_valid && metadata_good && geometry_good && !cancel_sync[1] && !rx_fault;
    wire write_fire=wr_valid && wr_ready;
    wire [2:0] markers={row==IMAGE_HEIGHT-1 && line_groups==LINE_GROUPS-1,
                        line_groups==LINE_GROUPS-1,row==0 && line_groups==0};
    assign wr_data={row,line_groups[8:0],1'b0,markers,active_handle,pixel_data[39:0]};
    assign busy=state!=DISARMED;

    always_comb begin
        fail=0;failure_outcome=1;failure_reason=0;
        if(state!=DISARMED && state!=TERM)begin
            if(cancel_sync[1])begin fail=1;failure_outcome=2;failure_reason=1;end
            else if(rx_fault)begin fail=1;failure_reason=5;end
            else if(wr_valid && !wr_ready)begin fail=1;failure_outcome=3;failure_reason=2;end
            else if(collecting && pixel_valid && !metadata_good)begin fail=1;failure_reason=3;end
            else if(collecting && pixel_valid && !geometry_good)begin fail=1;failure_reason=4;end
            else if(state==FRAME && hfall && (!line_started || line_groups!=LINE_GROUPS))begin fail=1;failure_reason=4;end
            else if(state==FRAME && vfall && !(hfall && line_started && line_groups==LINE_GROUPS && row==IMAGE_HEIGHT-1))begin fail=1;failure_reason=4;end
            else if(state==WAIT_END && (pixel_valid || hs))begin fail=1;failure_reason=4;end
        end
    end

    always_ff @(posedge pixel_clk or negedge cold_reset_n)
        if(!cold_reset_n)reset_pipe<=2'b11;else reset_pipe<={reset_pipe[0],1'b0};
    always_ff @(posedge pixel_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin request_sync<=0;cancel_sync<=0;ack_sync<=0;end
        else begin request_sync<={request_sync[0],request_toggle};cancel_sync<={cancel_sync[0],cancel_level};ack_sync<={ack_sync[0],terminal_ack};end
    end
    always_ff @(posedge pixel_clk or negedge cold_reset_n)begin
        if(!cold_reset_n)begin
            state<=DISARMED;seen_request<=0;active_handle<=0;old_hs<=0;old_vs<=0;
            line_started<=0;line_groups<=0;row<=0;accepted_groups<=0;
            terminal_toggle<=0;terminal_handle<=0;terminal_outcome<=0;terminal_reason<=0;
            terminal_groups<=0;terminal_lines<=0;terminal_shape<=0;
        end else if(running)begin
            old_hs<=hs;old_vs<=vs;
            if(fail)begin
                state<=TERM;terminal_toggle<=!terminal_toggle;terminal_handle<=active_handle;
                terminal_outcome<=failure_outcome;terminal_reason<=failure_reason;
                terminal_groups<=accepted_groups;terminal_lines<=row;terminal_shape<=0;
            end else begin
                if(write_fire)begin accepted_groups<=accepted_groups+22'd1;line_groups<=line_groups+10'd1;line_started<=1;end
                case(state)
                    DISARMED: if(request_sync[1]!=seen_request && wr_running)begin
                        seen_request<=request_sync[1];active_handle<=request_handle;
                        accepted_groups<=0;line_groups<=0;row<=0;line_started<=0;state<=WAIT_IDLE;
                    end
                    WAIT_IDLE: if(!vs && !hs)state<=WAIT_SOF;
                    WAIT_SOF: if(start_frame)state<=FRAME;
                    FRAME: if(hfall)begin
                        line_groups<=0;line_started<=0;row<=row+11'd1;
                        if(row==IMAGE_HEIGHT-1)begin
                            if(vfall)begin
                                state<=TERM;terminal_toggle<=!terminal_toggle;terminal_handle<=active_handle;
                                terminal_outcome<=0;terminal_reason<=0;terminal_groups<=accepted_groups;
                                terminal_lines<=11'(IMAGE_HEIGHT);terminal_shape<=1;
                            end else state<=WAIT_END;
                        end
                    end
                    WAIT_END: if(vfall)begin
                        state<=TERM;terminal_toggle<=!terminal_toggle;terminal_handle<=active_handle;
                        terminal_outcome<=0;terminal_reason<=0;terminal_groups<=accepted_groups;
                        terminal_lines<=11'(IMAGE_HEIGHT);terminal_shape<=1;
                    end
                    TERM: if(ack_sync[1]==terminal_toggle)state<=DISARMED;
                    default: state<=DISARMED;
                endcase
            end
        end
    end
endmodule
