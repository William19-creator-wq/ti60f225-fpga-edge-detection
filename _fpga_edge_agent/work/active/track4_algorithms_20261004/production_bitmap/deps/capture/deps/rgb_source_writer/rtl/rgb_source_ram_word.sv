// SW02：双bank共享同步RE/WE；4×512×20 RAM10承载每地址64bit，高16恒零。
module rgb_source_ram_word(
    input wire clk,rd_en,input wire [8:0] rd_addr,output wire [63:0] rd_word,
    input wire wr_en,input wire [8:0] wr_addr,input wire [63:0] wr_word
);
    wire [79:0] padded={16'd0,wr_word};
    wire [79:0] result;
    for(genvar lane=0;lane<4;lane++)begin:word_lane
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
            .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),.WE_POLARITY(2'b11),
            .RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),.RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)) ram(
            .WCLK(clk),.WE({2{wr_en}}),.WCLKE(wr_en),.WADDREN(1'b1),.WDATA(padded[lane*20+:20]),.WADDR(wr_addr),
            .RCLK(clk),.RE(rd_en),.RST(1'b0),.RADDREN(1'b1),.RDATA(result[lane*20+:20]),.RADDR(rd_addr));
    end
    assign rd_word=result[63:0];
    // synthesis translate_off
    always @(posedge clk)begin
        if(rd_en && rd_addr[8])$fatal(1,"Source RE outside two payload banks");
        if(wr_en && wr_addr[8])$fatal(1,"Source WE outside two payload banks");
        if(rd_en && wr_en && rd_addr==wr_addr)$fatal(1,"Source forbidden RE/WE collision");
    end
    // synthesis translate_on
endmodule
