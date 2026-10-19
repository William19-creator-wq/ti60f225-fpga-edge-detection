// 保留已验证的 RAW 行相位；算法桥版本取消所有合成图案覆盖。
module rawcard_overlay (
    input wire clk, rst_n, vs, de,
    input wire [15:0] camera_raw,
    output wire [15:0] out_raw,
    output wire raw_y_odd
);
    reg vs_q, de_q;
    reg [10:0] line_y;
    assign raw_y_odd=line_y[0];
    assign out_raw=camera_raw;
    always @(posedge clk) begin
        if(!rst_n)begin vs_q<=0;de_q<=0;line_y<=0;end
        else begin
            vs_q<=vs;de_q<=de;
            if(vs_q&&!vs)line_y<=0;
            else if(de_q&&!de&&line_y!=11'h7ff)line_y<=line_y+11'd1;
        end
    end
endmodule
