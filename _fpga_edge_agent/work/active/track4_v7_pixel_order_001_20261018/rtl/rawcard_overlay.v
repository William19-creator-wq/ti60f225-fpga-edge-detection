// 空间细节诊断B区：第224..415行，插入灰色场景对应的BGGR细线/棋盘格。
// 每个RAW位置单独计算，不把同一字的两个像素复制。相机其他区域逐位通过。
// 不修改同步、不增加拍数；首行相位在VS下降沿归零，与现有debayer计数一致。
module rawcard_overlay (
    input wire clk, rst_n, vs, de,
    input wire [15:0] camera_raw,
    output reg [15:0] out_raw,
    output wire raw_y_odd // 与当前输入RAW字同拍；VS下降沿归零，DE下降沿翻行
);
    reg vs_q, de_q;
    reg [9:0] word_x;
    reg [10:0] line_y;
    assign raw_y_odd = line_y[0];
    wire [7:0] gray_low,gray_high;
    wire [10:0] local_y=line_y-11'd224;
    detail_pattern_gray low_pattern(.pixel_x({word_x,1'b0}),.local_y(local_y[7:0]),.gray(gray_low));
    detail_pattern_gray high_pattern(.pixel_x({word_x,1'b1}),.local_y(local_y[7:0]),.gray(gray_high));
    always @(posedge clk) begin
        if (!rst_n) begin vs_q<=0;de_q<=0;word_x<=0;line_y<=0; end
        else begin
            vs_q<=vs;de_q<=de;
            if (vs_q && !vs) begin word_x<=0;line_y<=0;end
            else begin
                if(de) word_x<=word_x+10'd1;else word_x<=0;
                if(de_q && !de && line_y!=11'h7ff) line_y<=line_y+11'd1;
            end
        end
    end
    always @* begin
        out_raw=camera_raw;
        if(rst_n && de && line_y>=11'd224 && line_y<11'd416) begin
            out_raw={gray_high,gray_low};
        end
    end
endmodule
