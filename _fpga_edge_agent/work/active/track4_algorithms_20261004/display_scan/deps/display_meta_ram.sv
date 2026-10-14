// PF07：EDGE/ANN原始字节暂存1KB；写完资格后才读，输出是同步RE结果。
module display_meta_ram(
    input logic clk,write_enable,read_enable,input logic [8:0] write_address,read_address,
    input logic [15:0] write_data,output wire [15:0] read_data
);
    EFX_RAM10 #(.READ_WIDTH(16),.WRITE_WIDTH(16),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) memory(
        .WCLK(clk),.WE({2{write_enable}}),.WCLKE(1'b1),.WADDREN(1'b1),.WDATA(write_data),.WADDR(write_address),
        .RCLK(clk),.RE(read_enable),.RST(1'b0),.RADDREN(1'b1),.RDATA(read_data),.RADDR(read_address));
endmodule
