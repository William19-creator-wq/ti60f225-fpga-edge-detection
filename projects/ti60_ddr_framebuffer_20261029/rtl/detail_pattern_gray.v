// 六列线宽依次为1/2/4/8/16/32像素；三行依次是竖线、横线、棋盘格。
// 组合输出，没有改变视频拍数。32/224灰度避免全0/全1掩盖数据位问题。
module detail_pattern_gray(
    input wire [10:0] pixel_x,
    input wire [7:0] local_y,
    output wire [7:0] gray
);
    reg [2:0] width_log2;
    reg bright;
    always @* begin
        if(pixel_x<11'd320) width_log2=0;
        else if(pixel_x<11'd640) width_log2=1;
        else if(pixel_x<11'd960) width_log2=2;
        else if(pixel_x<11'd1280) width_log2=3;
        else if(pixel_x<11'd1600) width_log2=4;
        else width_log2=5;
        if(local_y<8'd64) bright=pixel_x[width_log2];
        else if(local_y<8'd128) bright=local_y[width_log2];
        else bright=pixel_x[width_log2]^local_y[width_log2];
    end
    assign gray=bright ? 8'd224 : 8'd32;
endmodule
