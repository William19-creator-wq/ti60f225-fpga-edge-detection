// Exact 512-word tiles avoid rounding a three-row cache up to four rows.
// Native RAM10 has synchronous independent read/write clocks; no RAM reset.
module canny_row_ram #(parameter integer WIDTH=128)(
    input wire write_clk,write_enable,input wire [8:0] write_address,input wire [WIDTH-1:0] write_data,
    input wire read_clk,read_enable,input wire [8:0] read_address,output wire [WIDTH-1:0] read_data
);
    localparam integer LANES=(WIDTH+19)/20;
    wire [LANES*20-1:0] padded={{(LANES*20-WIDTH){1'b0}},write_data};
    wire [LANES*20-1:0] result;
    for(genvar lane=0;lane<LANES;lane++)begin:ram_lane
        // Independent clocks cannot promise the old value on a collision.
        // The row-bank ownership handshake must prevent reading a bank while
        // DDR fills it. Match the native asynchronous-port RAM contract.
        EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN"),
            .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),.WE_POLARITY(2'b11),
            .RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),.RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)) payload(
            .WCLK(write_clk),.WE({2{write_enable}}),.WCLKE(write_enable),.WADDREN(1'b1),.WDATA(padded[lane*20+:20]),.WADDR(write_address),
            .RCLK(read_clk),.RE(read_enable),.RST(1'b0),.RADDREN(1'b1),.RDATA(result[lane*20+:20]),.RADDR(read_address));
    end
    assign read_data=result[WIDTH-1:0];
endmodule
