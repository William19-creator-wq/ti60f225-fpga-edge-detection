// RC02：一行两lane，各1024×10 RAM10，独立读/写地址，不依赖同址模式。
module raw10_line_store_pair #(parameter integer W=1920)(
    input wire clk,rd_en,input wire [9:0] rd_addr,output wire [19:0] rd_pair,
    input wire wr_en,input wire [9:0] wr_addr,input wire [19:0] wr_pair
);
    for(genvar lane=0;lane<2;lane++)begin:pixel_lane
        EFX_RAM10 #(.READ_WIDTH(10),.WRITE_WIDTH(10),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
            .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),.WE_POLARITY(2'b11),
            .RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),.RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)) ram(
            .WCLK(clk),.WE({1'b0,wr_en}),.WCLKE(wr_en),.WADDREN(1'b1),.WDATA(wr_pair[lane*10+:10]),.WADDR(wr_addr),
            .RCLK(clk),.RE(rd_en),.RST(1'b0),.RADDREN(1'b1),.RDATA(rd_pair[lane*10+:10]),.RADDR(rd_addr));
    end
    // synthesis translate_off
    initial if(W<4 || W>1920 || W%2!=0)$fatal(1,"raw10 line geometry");
    always @(posedge clk)begin
        if(rd_en && rd_addr>=W/2)$fatal(1,"raw10 row RE outside image");
        if(wr_en && wr_addr>=W/2)$fatal(1,"raw10 row WE outside image");
        if(rd_en && wr_en && rd_addr==wr_addr)$fatal(1,"raw10 forbidden RE/WE collision");
    end
    // synthesis translate_on
endmodule
