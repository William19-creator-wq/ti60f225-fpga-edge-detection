// Clock-indexed video payload store. Read offsets select the same central ROI
// twice without stretching pixels. Sync signals must use a separate zero-offset
// delay: remapping colour must never move HDMI timing or change its total length.
// At cycle t the synchronous output is input[t-DELAY+read_offset]. All callers
// keep the offset within MAX_OFFSET and select only coordinates within that row.
module scan_offset_ram #(
    parameter integer WIDTH=53,DELAY=6600,MAX_OFFSET=240,RAM_WIDTH=20
)(
    input wire clk,rst,input wire [WIDTH-1:0] in_data,
    input wire signed [13:0] read_offset,
    output wire [WIDTH-1:0] out_data,output reg valid
);
    localparam integer DEPTH=10240/RAM_WIDTH,LOCAL_AW=$clog2(DEPTH);
    localparam integer TILES=(DELAY+MAX_OFFSET+1+DEPTH-1)/DEPTH;
    localparam integer CAPACITY=TILES*DEPTH,AW=$clog2(CAPACITY);
    localparam integer BW=TILES>1?$clog2(TILES):1,LANES=(WIDTH+RAM_WIDTH-1)/RAM_WIDTH;
    reg [AW-1:0] write_pointer;
    reg [AW:0] warm_count;
    wire signed [15:0] read_index=$signed({1'b0,write_pointer})-16'(DELAY)+read_offset;
    wire [AW-1:0] read_pointer=read_index<0?AW'(read_index+CAPACITY):AW'(read_index);
    reg [BW-1:0] read_tile;
    wire [LANES*RAM_WIDTH-1:0] padded={{(LANES*RAM_WIDTH-WIDTH){1'b0}},in_data};
    wire [WIDTH-1:0] tile_data[0:TILES-1];
    always @(posedge clk)begin
        read_tile<=BW'(read_pointer>>LOCAL_AW);
        if(rst)begin write_pointer<=0;warm_count<=0;valid<=0;end
        else begin
            write_pointer<=write_pointer==CAPACITY-1?0:write_pointer+1'b1;
            if(warm_count<DELAY+MAX_OFFSET)warm_count<=warm_count+1'b1;
            valid<=warm_count>=DELAY+MAX_OFFSET;
        end
    end
    for(genvar tile=0;tile<TILES;tile++)begin:bank
        wire we=(write_pointer>>LOCAL_AW)==tile;
        wire re=(read_pointer>>LOCAL_AW)==tile;
        wire [LANES*RAM_WIDTH-1:0] result;
        for(genvar lane=0;lane<LANES;lane++)begin:word
            EFX_RAM10 #(.READ_WIDTH(RAM_WIDTH),.WRITE_WIDTH(RAM_WIDTH),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_FIRST"),
                .WCLK_POLARITY(1'b1),.WCLKE_POLARITY(1'b1),.WADDREN_POLARITY(1'b1),.WE_POLARITY(2'b11),
                .RCLK_POLARITY(1'b1),.RE_POLARITY(1'b1),.RST_POLARITY(1'b1),.RADDREN_POLARITY(1'b1)) payload(
                .WCLK(clk),.WE({2{we}}),.WCLKE(we),.WADDREN(1'b1),.WDATA(padded[lane*RAM_WIDTH+:RAM_WIDTH]),.WADDR(write_pointer[LOCAL_AW-1:0]),
                .RCLK(clk),.RE(re),.RST(1'b0),.RADDREN(1'b1),.RDATA(result[lane*RAM_WIDTH+:RAM_WIDTH]),.RADDR(read_pointer[LOCAL_AW-1:0]));
        end
        assign tile_data[tile]=result[WIDTH-1:0];
    end
    assign out_data=tile_data[read_tile];
    // synthesis translate_off
    initial if(DELAY<1||MAX_OFFSET<0||MAX_OFFSET>=DELAY||CAPACITY>16384||WIDTH<1||
        !(RAM_WIDTH==5||RAM_WIDTH==10||RAM_WIDTH==20))$fatal(1,"Invalid offset delay geometry");
    always @(posedge clk)if(!rst&&(write_pointer==read_pointer||read_offset>MAX_OFFSET||read_offset< -MAX_OFFSET))
        $fatal(1,"Offset outside owned history");
    // synthesis translate_on
endmodule
