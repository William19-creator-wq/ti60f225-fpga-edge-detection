// WQ02：独立读写地址；q在RE沿后更新，调用者下一沿capture。
// 不清RAM。有效范围由父模块metadata给出；父模块避免同地址RE/WE。
module queue_ram16_1r1w(
    input logic clk,re,we,
    input logic [8:0] read_address,write_address,
    input logic [15:0] data,
    output logic [15:0] q
);
    logic [15:0] words[0:511];
    always_ff @(posedge clk)begin
        if(we)words[write_address]<=data;
        if(re)q<=words[read_address];
    end
endmodule
