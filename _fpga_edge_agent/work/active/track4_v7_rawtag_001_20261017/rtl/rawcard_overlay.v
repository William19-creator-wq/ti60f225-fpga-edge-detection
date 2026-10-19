// 在已有两像素RAW流中插入已知GBRG样本，适配P00及现有HDMI红蓝旁路交换。
// 第224..319行八色，第320..415行16级灰阶。相机数据在其余区域逐位通过。
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
    reg [23:0] rgb;
    reg [7:0] gray;
    integer k;
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
        // 高电平192、低电平32，避免仅凭全0/全1验证数据通路。
        if      (word_x<10'd120) rgb=24'hc0c0c0;
        else if (word_x<10'd240) rgb=24'hc0c020;
        else if (word_x<10'd360) rgb=24'h20c0c0;
        else if (word_x<10'd480) rgb=24'h20c020;
        else if (word_x<10'd600) rgb=24'hc020c0;
        else if (word_x<10'd720) rgb=24'hc02020;
        else if (word_x<10'd840) rgb=24'h2020c0;
        else                   rgb=24'h202020;
        gray=0;
        for(k=1;k<16;k=k+1) if(word_x>=k*60) gray=k*17;
        if(line_y>=11'd320) rgb={gray,gray,gray};
        out_raw=camera_raw;
        if(rst_n && de && line_y>=11'd224 && line_y<11'd416) begin
            if(line_y[0]) out_raw={rgb[15:8],rgb[23:16]}; // 奇数行：低R、高G
            else          out_raw={rgb[7:0],rgb[15:8]};   // 偶数行：低G、高B
        end
    end
endmodule
