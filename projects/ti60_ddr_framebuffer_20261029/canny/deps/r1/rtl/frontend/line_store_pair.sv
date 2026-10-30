// FE-01/03/04/06/08；OP-03。每行恰两个8bit RAM10，不依赖同址读写模式。
module cny_line_store_pair #(parameter integer W = 1920) (
    input wire clk,
    input wire rd_en, input wire [9:0] rd_addr, output wire [15:0] rd_pair,
    input wire wr_en, input wire [9:0] wr_addr, input wire [15:0] wr_pair
);
    genvar lane;
    generate for (lane = 0; lane < 2; lane = lane + 1) begin : pixel_lane
        EFX_RAM10 #(
            .READ_WIDTH(8), .WRITE_WIDTH(8), .OUTPUT_REG(1'b0),
            .WRITE_MODE("READ_FIRST"),
            .WCLK_POLARITY(1'b1), .WCLKE_POLARITY(1'b1),
            .WADDREN_POLARITY(1'b1), .WE_POLARITY(2'b11),
            .RCLK_POLARITY(1'b1), .RE_POLARITY(1'b1),
            .RST_POLARITY(1'b1), .RADDREN_POLARITY(1'b1)
        ) ram (
            .WCLK(clk), .WE({1'b0, wr_en}), .WCLKE(wr_en), .WADDREN(1'b1),
            .WDATA(wr_pair[lane*8 +: 8]), .WADDR(wr_addr),
            .RCLK(clk), .RE(rd_en), .RST(1'b0), .RADDREN(1'b1),
            .RDATA(rd_pair[lane*8 +: 8]), .RADDR(rd_addr)
        );
    end endgenerate
    // synthesis translate_off
    initial if (W < 4 || W > 1920 || W % 2 != 0)
        $fatal(1, "cny_line_store_pair: illegal W");
    always @(posedge clk) begin
        if (rd_en && rd_addr >= W/2) $fatal(1, "line read out of range");
        if (wr_en && wr_addr >= W/2) $fatal(1, "line write out of range");
        if (rd_en && wr_en && rd_addr == wr_addr)
            $fatal(1, "cny_line_store_pair: forbidden read/write collision");
    end
    // synthesis translate_on
endmodule
