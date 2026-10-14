// DR01/04：54bit×1024，一个core写口、一个video同步读口；资格由bank拥有。
module row_ram54(
    input logic core_clk,video_clk,write_enable,read_enable,
    input logic [9:0] write_address,read_address,input logic [53:0] write_data,
    output wire [53:0] read_data
);
    wire [59:0] padded={6'd0,write_data};wire [19:0] ram_q[0:1][0:2];
    logic selected_depth;
    always_ff @(posedge video_clk)if(read_enable)selected_depth<=read_address[9];
    for(genvar d=0;d<2;d++)begin: depth
        for(genvar s=0;s<3;s++)begin: stripe
            wire we=write_enable && write_address[9]==d;
            wire re=read_enable && read_address[9]==d;
            // 已授予读借用期间禁止写；不依赖未定义同址跨时钟冲突值。
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) memory(
                .WCLK(core_clk),.WE({2{we}}),.WCLKE(1'b1),.WADDREN(1'b1),.WDATA(padded[s*20+:20]),.WADDR(write_address[8:0]),
                .RCLK(video_clk),.RE(re),.RST(1'b0),.RADDREN(1'b1),.RDATA(ram_q[d][s]),.RADDR(read_address[8:0]));
        end
    end
    wire [59:0] full_data={ram_q[selected_depth][2],ram_q[selected_depth][1],ram_q[selected_depth][0]};
    assign read_data=full_data[53:0];
endmodule
