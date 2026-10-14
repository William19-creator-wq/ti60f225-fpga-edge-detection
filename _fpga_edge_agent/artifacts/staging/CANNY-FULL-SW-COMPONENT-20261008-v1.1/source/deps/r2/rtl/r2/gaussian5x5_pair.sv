// SI-REQ02 / E2 / G-W01…04：四行原灰度，五级算术，仅H3舍入。
module gaussian5x5_pair #(parameter integer W=1920,H=1080) (
    input wire clk,rst,frame_start,data_flush,
    input wire in_valid,output wire in_ready,input wire [15:0] in_pair,
    input wire [10:0] in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output wire [15:0] out_pair,
    output wire [10:0] out_x_even,out_y,output wire out_sof,out_eol,out_eof,
    output wire empty
);
    localparam logic [9:0] LAST_Q=W/2-1;
    localparam logic [10:0] LAST_ROW=H-1;
    localparam logic [2:0] IDLE=0,REAL=1,BOTTOM0=2,BOTTOM1=3,TAIL=4,WAIT_EOF=5;
    localparam logic [2:0] NONE_PENDING=0,REAL_PENDING=1,BOTTOM0_PENDING=2,BOTTOM1_PENDING=3,TAIL_PENDING=4;
    logic [2:0] phase,pending;
    logic [9:0] input_q,replay_q,pending_q;
    logic [10:0] input_row,pending_row;
    logic [15:0] pending_pair;
    wire [15:0] bank_read[0:3];
    wire [3:0] rd_en,wr_en;
    logic v1_event,v2_event,v1_tail,v2_tail,h1_valid,h2_valid,h3_valid;
    logic [9:0] v1_q,v2_q,horizontal_q;
    logic [10:0] v1_row,v2_row,horizontal_row;
    logic [8:0] v1_outer[0:1],v1_near[0:1];logic [10:0] v1_center6[0:1];
    logic [11:0] vertical_sum[0:1];
    logic [11:0] col0,col1,col2,col3;logic horizontal_valid;
    logic [12:0] h1_outer[0:1],h1_near[0:1];logic [14:0] h1_center6[0:1];
    logic [15:0] h2_sum[0:1];logic [15:0] h3_pair;
    logic [24:0] h1_coordinate,h2_coordinate,h3_coordinate;
    wire advance=!h3_valid||out_ready;
    wire active=!rst&&!frame_start&&!data_flush&&advance;
    wire real_issue=active&&phase==REAL&&in_valid;
    wire bottom_issue=active&&(phase==BOTTOM0||phase==BOTTOM1);
    wire [9:0] rd_addr=real_issue?input_q:replay_q;
    genvar bank,lane;
    generate for(bank=0;bank<4;bank=bank+1) begin : line_bank
        // 顶部只读已建立行；r>=4才读全部bank，读地址与旧写地址不同。
        assign rd_en[bank]=bottom_issue || (real_issue&&input_row>=2&&(input_row>=4||bank<input_row));
        assign wr_en[bank]=active&&pending==REAL_PENDING&&pending_row[1:0]==bank;
        for(lane=0;lane<2;lane=lane+1) begin : pixel_lane
            EFX_RAM10 #(
                .READ_WIDTH(8),.WRITE_WIDTH(8),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
                .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),
                .WE_POLARITY(2'b11),.RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),
                .RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)
            ) ram(
                .WCLK(clk),.WE({1'b0,wr_en[bank]}),.WCLKE(wr_en[bank]),.WADDREN(1'b1),
                .WDATA(pending_pair[lane*8 +: 8]),.WADDR(pending_q),
                .RCLK(clk),.RE(rd_en[bank]),.RST(1'b0),.RADDREN(1'b1),
                .RADDR(rd_addr),.RDATA(bank_read[bank][lane*8 +: 8])
            );
        end
    end endgenerate
    assign in_ready=!rst&&phase==REAL&&advance;
    assign out_valid=!rst&&h3_valid;
    assign out_pair=h3_pair;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even}=h3_coordinate;
    assign empty=phase==IDLE&&pending==NONE_PENDING&&!v1_event&&!v2_event
        &&!horizontal_valid&&!h1_valid&&!h2_valid&&!h3_valid;
    logic [7:0] vertical_samples[0:1][0:4];
    logic column_event;logic [10:0] center_row;
    always_comb begin : select_five_rows
        column_event=0;center_row=0;
        for(integer pixel=0;pixel<2;pixel=pixel+1) begin
            for(integer r=0;r<5;r=r+1) vertical_samples[pixel][r]=0;
            if(pending==REAL_PENDING&&pending_row>=2) begin
                column_event=1;center_row=pending_row-11'd2;
                if(pending_row==2) begin
                    vertical_samples[pixel][0]=bank_read[0][pixel*8 +: 8];
                    vertical_samples[pixel][1]=bank_read[0][pixel*8 +: 8];
                    vertical_samples[pixel][2]=bank_read[0][pixel*8 +: 8];
                    vertical_samples[pixel][3]=bank_read[1][pixel*8 +: 8];
                end else if(pending_row==3) begin
                    vertical_samples[pixel][0]=bank_read[0][pixel*8 +: 8];
                    vertical_samples[pixel][1]=bank_read[0][pixel*8 +: 8];
                    vertical_samples[pixel][2]=bank_read[1][pixel*8 +: 8];
                    vertical_samples[pixel][3]=bank_read[2][pixel*8 +: 8];
                end else begin
                    for(integer r=0;r<4;r=r+1)
                        vertical_samples[pixel][r]=bank_read[(pending_row+r)&3][pixel*8 +: 8];
                end
                vertical_samples[pixel][4]=pending_pair[pixel*8 +: 8];
            end else if(pending==BOTTOM0_PENDING) begin
                column_event=1;center_row=H-2;
                for(integer r=0;r<4;r=r+1)
                    vertical_samples[pixel][r]=bank_read[(H-4+r)&3][pixel*8 +: 8];
                vertical_samples[pixel][4]=bank_read[(H-1)&3][pixel*8 +: 8];
            end else if(pending==BOTTOM1_PENDING) begin
                column_event=1;center_row=H-1;
                vertical_samples[pixel][0]=bank_read[(H-3)&3][pixel*8 +: 8];
                vertical_samples[pixel][1]=bank_read[(H-2)&3][pixel*8 +: 8];
                for(integer r=2;r<5;r=r+1)
                    vertical_samples[pixel][r]=bank_read[(H-1)&3][pixel*8 +: 8];
            end
        end
    end
    logic [11:0] horizontal_samples[0:1][0:4];
    logic horizontal_event;
    always_comb begin : select_five_columns
        horizontal_event=v2_event&&horizontal_valid;
        for(integer pixel=0;pixel<2;pixel=pixel+1)
            for(integer c=0;c<5;c=c+1) horizontal_samples[pixel][c]=0;
        if(v2_event&&horizontal_valid) begin
            horizontal_samples[0][0]=col0;horizontal_samples[0][1]=col1;
            horizontal_samples[0][2]=col2;horizontal_samples[0][3]=col3;
            horizontal_samples[1][0]=col1;horizontal_samples[1][1]=col2;
            horizontal_samples[1][2]=col3;
            if(v2_tail||v2_q==0) begin
                horizontal_samples[0][4]=col3;
                horizontal_samples[1][3]=col3;horizontal_samples[1][4]=col3;
            end else begin
                horizontal_samples[0][4]=vertical_sum[0];
                horizontal_samples[1][3]=vertical_sum[0];horizontal_samples[1][4]=vertical_sum[1];
            end
        end
    end
    always_ff @(posedge clk) begin : gaussian_steps
        if(rst||frame_start||data_flush) begin
            phase<=frame_start&&!rst&&!data_flush?REAL:IDLE;
            pending<=NONE_PENDING;input_q<=0;input_row<=0;replay_q<=0;
            pending_q<=0;pending_row<=0;pending_pair<=0;
            v1_event<=0;v2_event<=0;v1_tail<=0;v2_tail<=0;
            h1_valid<=0;h2_valid<=0;h3_valid<=0;
            horizontal_valid<=0;horizontal_q<=0;horizontal_row<=0;
            col0<=0;col1<=0;col2<=0;col3<=0;
            v1_q<=0;v2_q<=0;v1_row<=0;v2_row<=0;
            h1_coordinate<=0;h2_coordinate<=0;h3_coordinate<=0;h3_pair<=0;
        end else if(advance) begin
            pending<=NONE_PENDING;
            // V1取旧pending/旧RAM；V2只读旧V1，不在这一沿穿透。
            v1_event<=column_event||pending==TAIL_PENDING;
            v1_tail<=pending==TAIL_PENDING;v1_q<=pending_q;v1_row<=center_row;
            v2_event<=v1_event;v2_tail<=v1_tail;v2_q<=v1_q;v2_row<=v1_row;
            h1_valid<=horizontal_event;h2_valid<=h1_valid;h3_valid<=h2_valid;
            h2_coordinate<=h1_coordinate;h3_coordinate<=h2_coordinate;
            if(horizontal_event)
                h1_coordinate<={horizontal_q==LAST_Q&&horizontal_row==LAST_ROW,
                    horizontal_q==LAST_Q,horizontal_q==0&&horizontal_row==0,
                    horizontal_row,horizontal_q,1'b0};
            for(integer pixel=0;pixel<2;pixel=pixel+1) begin
                v1_outer[pixel]<={1'b0,vertical_samples[pixel][0]}+{1'b0,vertical_samples[pixel][4]};
                v1_near[pixel]<={1'b0,vertical_samples[pixel][1]}+{1'b0,vertical_samples[pixel][3]};
                v1_center6[pixel]<=({3'b0,vertical_samples[pixel][2]}<<2)
                    +({3'b0,vertical_samples[pixel][2]}<<1);
                vertical_sum[pixel]<={3'b0,v1_outer[pixel]}+({3'b0,v1_near[pixel]}<<2)+{1'b0,v1_center6[pixel]};
                h1_outer[pixel]<={1'b0,horizontal_samples[pixel][0]}+{1'b0,horizontal_samples[pixel][4]};
                h1_near[pixel]<={1'b0,horizontal_samples[pixel][1]}+{1'b0,horizontal_samples[pixel][3]};
                h1_center6[pixel]<=({3'b0,horizontal_samples[pixel][2]}<<2)
                    +({3'b0,horizontal_samples[pixel][2]}<<1);
                h2_sum[pixel]<={3'b0,h1_outer[pixel]}+({3'b0,h1_near[pixel]}<<2)+{1'b0,h1_center6[pixel]};
                h3_pair[pixel*8 +: 8]<=(h2_sum[pixel]+16'd128)>>8;
            end
            if(v2_event) begin
                if(v2_tail) horizontal_valid<=0;
                else begin
                    if(v2_q==0) begin
                        col0<=vertical_sum[0];col1<=vertical_sum[0];col2<=vertical_sum[0];
                    end else begin col0<=col2;col1<=col3;col2<=vertical_sum[0];end
                    col3<=vertical_sum[1];horizontal_q<=v2_q;horizontal_row<=v2_row;horizontal_valid<=1;
                end
            end
            case(phase)
                REAL:if(real_issue) begin
                    pending<=REAL_PENDING;pending_q<=input_q;pending_row<=input_row;pending_pair<=in_pair;
                    if(input_q==LAST_Q) begin
                        if(input_row==LAST_ROW) begin phase<=BOTTOM0;replay_q<=0;end
                        else begin input_q<=0;input_row<=input_row+11'd1;end
                    end else input_q<=input_q+10'd1;
                end
                BOTTOM0,BOTTOM1:begin
                    pending<=phase==BOTTOM0?BOTTOM0_PENDING:BOTTOM1_PENDING;pending_q<=replay_q;
                    if(replay_q==LAST_Q) begin phase<=phase==BOTTOM0?BOTTOM1:TAIL;replay_q<=0;end
                    else replay_q<=replay_q+10'd1;
                end
                TAIL:begin pending<=TAIL_PENDING;phase<=WAIT_EOF;end
                WAIT_EOF:if(h3_valid&&out_ready&&out_eof&&pending==NONE_PENDING
                    &&!v1_event&&!v2_event&&!horizontal_valid&&!h1_valid&&!h2_valid) phase<=IDLE;
                default:begin end
            endcase
        end
    end
    // synthesis translate_off
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080) $fatal(1,"Gaussian dimensions");
    always @(posedge clk) begin
        for(integer b=0;b<4;b=b+1) begin
            if(rd_en[b]&&rd_addr>=W/2) $fatal(1,"Gaussian read range");
            if(wr_en[b]&&pending_q>=W/2) $fatal(1,"Gaussian write range");
            if(rd_en[b]&&wr_en[b]&&rd_addr==pending_q) $fatal(1,"Gaussian RAM collision");
        end
        if(active&&v2_event&&v2_tail&&!horizontal_valid) $fatal(1,"Gaussian TAIL missing history");
        if(active&&v2_event&&!v2_tail&&v2_q!=0&&(!horizontal_valid||horizontal_row!=v2_row||horizontal_q+1!=v2_q))
            $fatal(1,"Gaussian horizontal sequence");
    end
    // synthesis translate_on
endmodule
