// 1920 宽诊断色卡：前96行是白黄青绿紫红蓝黑，随后96行是16级灰阶。
// 单像素时钟域；DE/VS原样旁路，不增加延迟；其余行逐位保留相机RGB。
module colorcard_overlay (
    input wire clk, rst_n, vs, de,
    input wire [7:0] camera_r, camera_g, camera_b,
    output reg [7:0] out_r, out_g, out_b
);
    reg vs_q, de_q;
    reg [11:0] x;
    reg [10:0] y;
    reg [23:0] color;
    reg [7:0] gray;
    integer k;
    // x表示当前即将被编码器采样的像素；行号只在整段DE结束后推进。
    always @(posedge clk) begin
        if (!rst_n) begin
            vs_q <= 1'b0; de_q <= 1'b0; x <= 12'd0; y <= 11'd0;
        end else begin
            vs_q <= vs; de_q <= de;
            if (vs && !vs_q) begin x <= 12'd0; y <= 11'd0; end
            else begin
                if (de) x <= x + 12'd1; else x <= 12'd0;
                if (!de && de_q && y != 11'h7ff) y <= y + 11'd1;
            end
        end
    end
    always @* begin
        if      (x < 12'd240)  color = 24'hffffff;
        else if (x < 12'd480)  color = 24'hffff00;
        else if (x < 12'd720)  color = 24'h00ffff;
        else if (x < 12'd960)  color = 24'h00ff00;
        else if (x < 12'd1200) color = 24'hff00ff;
        else if (x < 12'd1440) color = 24'hff0000;
        else if (x < 12'd1680) color = 24'h0000ff;
        else                  color = 24'h000000;
        gray = 8'd0;
        for (k=1; k<16; k=k+1)
            if (x >= k*120) gray = k*17;
        {out_r,out_g,out_b} = {camera_r,camera_g,camera_b};
        if (rst_n && de && y < 11'd96) {out_r,out_g,out_b} = color;
        else if (rst_n && de && y < 11'd192) {out_r,out_g,out_b} = {gray,gray,gray};
    end
endmodule
