// BGGR实测校正：偶数行低B/高G，奇数行低G/高R。
// 组合变换，不新增流水拍；row_odd必须与当前raw_in同拍。
// 暗场15..16取黑电平16。white_tag_01未饱和，Q8增益R=317,G=256,B=582。
// 人工RAW色卡在本模块之后插入；LA探针仍采校正之前的原始字节。
module raw_bggr_balance (
    input wire enable,
    input wire row_odd,
    input wire [15:0] raw_in,
    output wire [15:0] raw_out
);
    function [7:0] subtract_black;
        input [7:0] sample;
        begin subtract_black=(sample>8'd16)?sample-8'd16:8'd0; end
    endfunction
    function [7:0] red_balance;
        input [7:0] sample;
        reg [17:0] x, scaled;
        begin
            x={10'd0,subtract_black(sample)};
            // 317=256+64-4+1；显式18位，最大值75891+128，不溢出。
            scaled=(x<<8)+(x<<6)-(x<<2)+x+18'd128;
            red_balance=(scaled>=18'd65280)?8'd255:scaled[15:8];
        end
    endfunction
    function [7:0] blue_balance;
        input [7:0] sample;
        reg [17:0] x, scaled;
        begin
            x={10'd0,subtract_black(sample)};
            // 582=512+64+4+2；最大值139098+128，不使用回绕截断。
            scaled=(x<<9)+(x<<6)+(x<<2)+(x<<1)+18'd128;
            blue_balance=(scaled>=18'd65280)?8'd255:scaled[15:8];
        end
    endfunction
    assign raw_out=!enable ? raw_in : row_odd ?
        {red_balance(raw_in[15:8]),subtract_black(raw_in[7:0])} :
        {subtract_black(raw_in[15:8]),blue_balance(raw_in[7:0])};
endmodule
