// Exact clock delay, including video blanking. No ready/backpressure interface.
// 512-word native tiles avoid rounding the 6600-cycle scan delay to 8192.
// The read and write slots are always distinct; memory contents need no reset.
module scan_delay_ram #(
    parameter integer WIDTH=54, DELAY=6600
)(
    input wire clk,rst,
    input wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data,
    output reg valid
);
    localparam integer TILES=(DELAY+1+511)/512;
    localparam integer CAPACITY=TILES*512;
    localparam integer AW=$clog2(CAPACITY);
    localparam integer BW=(TILES>1)?$clog2(TILES):1;
    localparam integer LANES=(WIDTH+19)/20;
    reg [AW-1:0] write_pointer;
    reg [AW:0] warm_count;
    wire [AW-1:0] read_pointer=write_pointer>=DELAY ?
        write_pointer-AW'(DELAY) : write_pointer+AW'(CAPACITY-DELAY);
    reg [BW-1:0] read_tile;
    wire [LANES*20-1:0] padded={{(LANES*20-WIDTH){1'b0}},in_data};
    wire [WIDTH-1:0] tile_data[0:TILES-1];
    always @(posedge clk)begin
        read_tile<=BW'(read_pointer>>9);
        if(rst)begin write_pointer<=0;warm_count<=0;valid<=0;end
        else begin
            write_pointer<=write_pointer==CAPACITY-1?0:write_pointer+1'b1;
            if(warm_count<DELAY)warm_count<=warm_count+1'b1;
            valid<=warm_count>=DELAY;
        end
    end
    for(genvar tile=0;tile<TILES;tile++)begin:bank
        wire we=(write_pointer>>9)==tile;
        wire re=(read_pointer>>9)==tile;
        wire [LANES*20-1:0] result;
        for(genvar lane=0;lane<LANES;lane++)begin:word
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
                .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),.WE_POLARITY(2'b11),
                .RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),.RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)) payload(
                .WCLK(clk),.WE({2{we}}),.WCLKE(we),.WADDREN(1'b1),.WDATA(padded[lane*20+:20]),.WADDR(write_pointer[8:0]),
                .RCLK(clk),.RE(re),.RST(1'b0),.RADDREN(1'b1),.RDATA(result[lane*20+:20]),.RADDR(read_pointer[8:0]));
        end
        assign tile_data[tile]=result[WIDTH-1:0];
    end
    assign out_data=tile_data[read_tile];
    // synthesis translate_off
    initial if(DELAY<1||WIDTH<1)$fatal(1,"Invalid delay storage geometry");
    always @(posedge clk)if(!rst&&write_pointer==read_pointer)$fatal(1,"Delay read/write collision");
    // synthesis translate_on
endmodule
