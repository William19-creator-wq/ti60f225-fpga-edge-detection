// 小型状态字幕。坐标、mode和threshold均来自同一延迟扫描事务。
// 只覆盖左上320×32区域，字幕不回流到滤波器；组合结果由桥接原输出寄存器接收。
module v7_algorithm_status_pixel(
    input wire [23:0] rgb,
    input wire [10:0] x,y,threshold,
    input wire [2:0] mode,
    input wire available,
    output reg [23:0] pixel
);
    function automatic [34:0] glyph(input reg [7:0] c);
        begin
            case(c)
                "0":glyph=35'b01110_10001_10011_10101_11001_10001_01110;
                "1":glyph=35'b00100_01100_00100_00100_00100_00100_01110;
                "2":glyph=35'b01110_10001_00001_00010_00100_01000_11111;
                "3":glyph=35'b11110_00001_00001_01110_00001_00001_11110;
                "4":glyph=35'b00010_00110_01010_10010_11111_00010_00010;
                "5":glyph=35'b11111_10000_10000_11110_00001_00001_11110;
                "6":glyph=35'b01110_10000_10000_11110_10001_10001_01110;
                "7":glyph=35'b11111_00001_00010_00100_01000_01000_01000;
                "8":glyph=35'b01110_10001_10001_01110_10001_10001_01110;
                "9":glyph=35'b01110_10001_10001_01111_00001_00001_01110;
                "A":glyph=35'b01110_10001_10001_11111_10001_10001_10001;
                "B":glyph=35'b11110_10001_10001_11110_10001_10001_11110;
                "C":glyph=35'b01111_10000_10000_10000_10000_10000_01111;
                "D":glyph=35'b11110_10001_10001_10001_10001_10001_11110;
                "E":glyph=35'b11111_10000_10000_11110_10000_10000_11111;
                "F":glyph=35'b11111_10000_10000_11110_10000_10000_10000;
                "G":glyph=35'b01111_10000_10000_10111_10001_10001_01111;
                "I":glyph=35'b01110_00100_00100_00100_00100_00100_01110;
                "L":glyph=35'b10000_10000_10000_10000_10000_10000_11111;
                "M":glyph=35'b10001_11011_10101_10101_10001_10001_10001;
                "N":glyph=35'b10001_11001_10101_10011_10001_10001_10001;
                "O":glyph=35'b01110_10001_10001_10001_10001_10001_01110;
                "P":glyph=35'b11110_10001_10001_11110_10000_10000_10000;
                "R":glyph=35'b11110_10001_10001_11110_10100_10010_10001;
                "S":glyph=35'b01111_10000_10000_01110_00001_00001_11110;
                "T":glyph=35'b11111_00100_00100_00100_00100_00100_00100;
                "V":glyph=35'b10001_10001_10001_10001_10001_01010_00100;
                "X":glyph=35'b10001_10001_01010_00100_01010_10001_10001;
                "Y":glyph=35'b10001_10001_01010_00100_00100_00100_00100;
                ":":glyph=35'b00000_00100_00100_00000_00100_00100_00000;
                default:glyph=0;
            endcase
        end
    endfunction
    reg [63:0] label_text;
    reg [7:0] character;
    reg [34:0] bitmap;
    integer index,column,row;
    always @* begin
        case(mode)
            0:label_text="COLOR   ";
            1:label_text="GRAY    ";
            2:label_text="MEDIAN  ";
            3:label_text="SOBEL   ";
            4:label_text="OVERLAY ";
            5:label_text="SPLIT   ";
            6:label_text="DIFF X8 ";
            default:label_text="COLOR   ";
        endcase
        pixel=rgb;character=" ";bitmap=0;index=0;column=0;row=0;
        if(x<320&&y<32)begin
            pixel=24'h101010;
            if(x>=280&&x<292&&y>=8&&y<20)
                pixel=available?24'h00ff00:24'hff8000;
            if(x>=16&&x<240&&y>=8&&y<22)begin
                index=(x-16)>>4;column=((x-16)>>1)&7;row=(y-8)>>1;
                if(index<8)character=label_text[63-index*8-:8];
                else case(index)
                    8:character="T";
                    9:character=":";
                    10:character=8'd48+8'(threshold/1000);
                    11:character=8'd48+8'((threshold/100)%10);
                    12:character=8'd48+8'((threshold/10)%10);
                    13:character=8'd48+8'(threshold%10);
                    default:character=" ";
                endcase
                bitmap=glyph(character);
                if(column<5&&bitmap[34-row*5-column])pixel=24'hffffff;
            end
        end
    end
endmodule
