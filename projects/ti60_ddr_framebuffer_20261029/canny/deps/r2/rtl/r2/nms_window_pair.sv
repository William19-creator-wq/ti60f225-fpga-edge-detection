// SI-REQ02 / E4 / U-NW：两行原M/dir，八个8bit RAM10，同步读/延迟写。
module nms_window_pair #(parameter integer W=1920,H=1080) (
    input wire clk,rst,frame_start,data_flush,
    input wire in_valid,output wire in_ready,input wire [31:0] in_pair,
    input wire [10:0] in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output logic [287:0] out_window_pair,
    output logic [10:0] out_x_even,out_y,output logic out_sof,out_eol,out_eof,
    output wire empty
);
    localparam logic [9:0] LAST_Q=W/2-1;
    localparam logic [10:0] LAST_ROW=H-1;
    localparam logic [2:0] IDLE=0,REAL=1,REPLAY=2,TAIL=3,WAIT_EOF=4;
    localparam logic [1:0] NONE_PENDING=0,REAL_PENDING=1,REPLAY_PENDING=2,TAIL_PENDING=3;
    logic [2:0] phase;
    logic [1:0] pending;
    logic [9:0] input_q,input_replay_q,pending_q,horizontal_q;
    logic [10:0] input_row,pending_row,horizontal_row;
    logic [31:0] pending_pair;
    logic horizontal_valid,output_present;
    logic [47:0] left_column,center_column0,center_column1;
    wire advance=!output_present||out_ready;
    wire active=!rst&&!frame_start&&!data_flush&&advance;
    wire real_issue=active&&phase==REAL&&in_valid;
    wire replay_issue=active&&phase==REPLAY;
    wire rd_en=real_issue||replay_issue;
    // RAM只使用本模块受限游标。raw metadata另由C0按真实N fire核对。
    wire [9:0] rd_addr=real_issue?input_q:input_replay_q;
    wire [9:0] wr_addr=pending_q;
    wire recent_wr_en=active&&pending==REAL_PENDING;
    wire older_wr_en=recent_wr_en&&pending_row!=0;
    wire [31:0] recent_read,older_read;
    genvar bank,byte_index;
    generate for(bank=0;bank<2;bank=bank+1) begin : line_bank
        wire write_enable=bank==0?recent_wr_en:older_wr_en;
        wire [31:0] write_pair=bank==0?pending_pair:recent_read;
        for(byte_index=0;byte_index<4;byte_index=byte_index+1) begin : byte_plane
            wire [7:0] read_byte;
            EFX_RAM10 #(
                .READ_WIDTH(8),.WRITE_WIDTH(8),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
                .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),
                .WE_POLARITY(2'b11),.RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),
                .RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)
            ) ram(
                .WCLK(clk),.WE({1'b0,write_enable}),.WCLKE(write_enable),.WADDREN(1'b1),
                .WDATA(write_pair[byte_index*8 +: 8]),.WADDR(wr_addr),
                .RCLK(clk),.RE(rd_en),.RST(1'b0),.RADDREN(1'b1),.RADDR(rd_addr),.RDATA(read_byte)
            );
            if(bank==0) assign recent_read[byte_index*8 +: 8]=read_byte;
            else assign older_read[byte_index*8 +: 8]=read_byte;
        end
    end endgenerate
    assign in_ready=!rst&&phase==REAL&&advance;
    assign out_valid=!rst&&output_present;
    assign empty=phase==IDLE&&pending==NONE_PENDING&&!horizontal_valid&&!output_present;
    logic vertical_valid;logic [47:0] new_column0,new_column1;logic [10:0] new_row;
    always_comb begin : choose_vertical_history
        vertical_valid=0;new_column0=0;new_column1=0;new_row=0;
        if(pending==REAL_PENDING&&pending_row!=0) begin
            vertical_valid=1;new_row=pending_row-11'd1;
            if(pending_row==1) begin
                new_column0={pending_pair[15:0],recent_read[15:0],recent_read[15:0]};
                new_column1={pending_pair[31:16],recent_read[31:16],recent_read[31:16]};
            end else begin
                new_column0={pending_pair[15:0],recent_read[15:0],older_read[15:0]};
                new_column1={pending_pair[31:16],recent_read[31:16],older_read[31:16]};
            end
        end else if(pending==REPLAY_PENDING) begin
            vertical_valid=1;new_row=LAST_ROW;
            new_column0={recent_read[15:0],recent_read[15:0],older_read[15:0]};
            new_column1={recent_read[31:16],recent_read[31:16],older_read[31:16]};
        end
    end
    function automatic [143:0] row_major(input logic [47:0] l,c,r);
        row_major={r[47:32],c[47:32],l[47:32],r[31:16],c[31:16],l[31:16],r[15:0],c[15:0],l[15:0]};
    endfunction
    always_ff @(posedge clk) begin : window_steps
        if(rst||frame_start||data_flush) begin
            phase<=frame_start&&!rst&&!data_flush?REAL:IDLE;
            pending<=NONE_PENDING;input_q<=0;input_row<=0;input_replay_q<=0;
            pending_q<=0;pending_row<=0;pending_pair<=0;
            horizontal_valid<=0;horizontal_q<=0;horizontal_row<=0;
            left_column<=0;center_column0<=0;center_column1<=0;
            output_present<=0;out_window_pair<=0;out_x_even<=0;out_y<=0;
            out_sof<=0;out_eol<=0;out_eof<=0;
        end else if(advance) begin
            output_present<=0;pending<=NONE_PENDING;
            if(vertical_valid) begin
                if(horizontal_valid) begin
                    output_present<=1;
                    out_window_pair[143:0]<=row_major(left_column,center_column0,center_column1);
                    out_window_pair[287:144]<=row_major(center_column0,center_column1,
                        pending_q==0?center_column1:new_column0);
                    out_x_even<={horizontal_q,1'b0};out_y<=horizontal_row;
                    out_sof<=horizontal_q==0&&horizontal_row==0;
                    out_eol<=horizontal_q==LAST_Q;
                    out_eof<=horizontal_q==LAST_Q&&horizontal_row==LAST_ROW;
                end
                left_column<=pending_q==0?new_column0:center_column1;
                center_column0<=new_column0;center_column1<=new_column1;
                horizontal_q<=pending_q;horizontal_row<=new_row;horizontal_valid<=1;
            end else if(pending==TAIL_PENDING) begin
                output_present<=1;
                out_window_pair[143:0]<=row_major(left_column,center_column0,center_column1);
                out_window_pair[287:144]<=row_major(center_column0,center_column1,center_column1);
                out_x_even<={horizontal_q,1'b0};out_y<=horizontal_row;
                out_sof<=horizontal_q==0&&horizontal_row==0;out_eol<=horizontal_q==LAST_Q;
                out_eof<=horizontal_q==LAST_Q&&horizontal_row==LAST_ROW;horizontal_valid<=0;
            end
            case(phase)
                REAL:if(real_issue) begin
                    pending<=REAL_PENDING;pending_q<=input_q;pending_row<=input_row;pending_pair<=in_pair;
                    if(input_q==LAST_Q) begin
                        if(input_row==LAST_ROW) begin phase<=REPLAY;input_replay_q<=0;end
                        else begin input_q<=0;input_row<=input_row+11'd1;end
                    end else input_q<=input_q+10'd1;
                end
                REPLAY:begin
                    pending<=REPLAY_PENDING;pending_q<=input_replay_q;pending_row<=LAST_ROW;
                    if(input_replay_q==LAST_Q) phase<=TAIL;
                    else input_replay_q<=input_replay_q+10'd1;
                end
                TAIL:begin pending<=TAIL_PENDING;phase<=WAIT_EOF;end
                WAIT_EOF:if(output_present&&out_ready&&out_eof&&pending==NONE_PENDING&&!horizontal_valid)
                    phase<=IDLE;
                default:begin end
            endcase
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"NMS window dimensions");
    always @(posedge clk) begin
        if(rd_en&&rd_addr>=W/2) $fatal(1,"NMS read range");
        if((recent_wr_en||older_wr_en)&&wr_addr>=W/2) $fatal(1,"NMS write range");
        if(rd_en&&(recent_wr_en||older_wr_en)&&rd_addr==wr_addr) $fatal(1,"NMS RAM collision");
        if(active&&vertical_valid&&pending_q!=0&&(!horizontal_valid||horizontal_row!=new_row||horizontal_q+1!=pending_q))
            $fatal(1,"NMS horizontal sequence");
    end
    // synthesis translate_on
endmodule
