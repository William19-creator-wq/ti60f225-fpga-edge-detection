// SC02：512×16同步RAM；Q在RE沿后更新，调用方下一沿capture；不清数据阵列。
module state_cache_ram16(
    input logic clk,re,we,input logic [8:0] address,input logic [15:0] data,
    output logic [15:0] q
);
    logic [15:0] memory[0:511];
    always_ff @(posedge clk)begin
        if(we)memory[address]<=data;
        if(re)q<=memory[address];
    end
endmodule
