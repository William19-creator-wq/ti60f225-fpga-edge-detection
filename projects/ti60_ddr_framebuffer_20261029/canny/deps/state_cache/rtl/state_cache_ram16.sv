// Parameterized synchronous 16-bit RAM. RE updates Q after the edge;
// the caller consumes Q on the following edge. Contents are not reset.
module state_cache_ram16 #(parameter integer ADDR_WIDTH=9)(
    input logic clk,re,we,input logic [ADDR_WIDTH-1:0] address,input logic [15:0] data,
    output logic [15:0] q
);
    logic [15:0] memory[0:(1<<ADDR_WIDTH)-1];
    always_ff @(posedge clk)begin
        if(we)memory[address]<=data;
        if(re)q<=memory[address];
    end
endmodule
