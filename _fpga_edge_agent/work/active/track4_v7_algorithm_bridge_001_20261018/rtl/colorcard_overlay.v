// 空间细节诊断A区：第0..191行，直接RGB细线/棋盘格。
// 单像素时钟域；DE/VS原样旁路，不增加延迟；其余行逐位保留相机RGB。
module colorcard_overlay (
    input wire clk, rst_n, vs, de,
    input wire [7:0] camera_r, camera_g, camera_b,
    output reg [7:0] out_r, out_g, out_b
);
    reg vs_q, de_q;
    reg [11:0] x;
    reg [10:0] y;
    wire [7:0] gray;
    detail_pattern_gray pattern(.pixel_x(x[10:0]),.local_y(y[7:0]),.gray(gray));
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
        {out_r,out_g,out_b} = {camera_r,camera_g,camera_b};
        if (rst_n && de && y < 11'd192) {out_r,out_g,out_b} = {gray,gray,gray};
    end
endmodule
