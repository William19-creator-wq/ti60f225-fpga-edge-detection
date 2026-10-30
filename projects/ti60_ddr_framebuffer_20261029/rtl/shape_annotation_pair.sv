// Display-only annotation for two adjacent full-resolution RGB pixels.
// The caller latches frame and target metadata together at a display frame
// boundary. Scope equality is mandatory; stale targets never mark new RGB.
// One registered cycle; VS/HS/DE and pixel data have identical latency.
// Boxes are inclusive, centers use exact half-pixel coordinates (rasterized
// down for the cross). C1..C4 and R1..R4 label the sorted target slots.
module shape_annotation_pair #(
    parameter integer W=1920,H=1080
)(
    input wire clk,rst,enable,
    input wire in_vs,in_hs,in_de,input wire [47:0] in_rgb,
    input wire [10:0] in_x,in_y,
    input wire frame_valid,input wire [95:0] frame_scope,
    input wire targets_valid,input wire [95:0] target_scope,
    input wire [3:0] target_mask,input wire [7:0] target_class,
    input wire [175:0] target_box,input wire [95:0] target_center2,
    output reg out_vs,out_hs,out_de,output reg [47:0] out_rgb
);
    function automatic [4:0] glyph(input [3:0] symbol,input [2:0] row);
        reg [34:0] bitmap;
        begin
            case(symbol)
                0:bitmap={5'b01110,5'b10001,5'b10000,5'b10000,5'b10000,5'b10001,5'b01110}; // C
                1:bitmap={5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001}; // R
                2:bitmap={5'b00100,5'b01100,5'b00100,5'b00100,5'b00100,5'b00100,5'b01110}; // 1
                3:bitmap={5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b01000,5'b11111}; // 2
                4:bitmap={5'b11110,5'b00001,5'b00001,5'b01110,5'b00001,5'b00001,5'b11110}; // 3
                5:bitmap={5'b00010,5'b00110,5'b01010,5'b10010,5'b11111,5'b00010,5'b00010}; // 4
                default:bitmap=0;
            endcase
            glyph=bitmap[(6-row)*5+:5];
        end
    endfunction
    function automatic [23:0] annotated(input [23:0] colour,input [10:0] x,y);
        integer i;
        reg [10:0] x0,y0,x1,y1,cx,cy,label_x,label_y,lx,ly;
        reg [1:0] cls;
        reg [4:0] bits;
        reg edge_pixel,center_pixel,label_pixel;
        begin
            annotated=colour;
            if(enable&&in_de&&frame_valid&&targets_valid&&frame_scope==target_scope&&x<W&&y<H)begin
                // Lowest slot wins if display decorations overlap.
                for(i=3;i>=0;i=i-1)begin
                    x0=target_box[i*44+:11];y0=target_box[i*44+11+:11];
                    x1=target_box[i*44+22+:11];y1=target_box[i*44+33+:11];
                    cx=target_center2[i*24+1+:11];cy=target_center2[i*24+13+:11];
                    cls=target_class[i*2+:2];
                    edge_pixel=((x==x0||x==x1)&&y>=y0&&y<=y1)||((y==y0||y==y1)&&x>=x0&&x<=x1);
                    center_pixel=(x==cx&&({1'b0,y}+3>={1'b0,cy})&&({1'b0,y}<={1'b0,cy}+3))||
                        (y==cy&&({1'b0,x}+3>={1'b0,cx})&&({1'b0,x}<={1'b0,cx}+3));
                    label_x=x0<=W-11?x0:11'(W-11);label_y=y0>=8?y0-8:y0+1;
                    lx=x-label_x;ly=y-label_y;label_pixel=0;bits=0;
                    if(x>=label_x&&y>=label_y&&ly<7)begin
                        if(lx<5)begin bits=glyph(cls==1?4'd0:4'd1,ly[2:0]);label_pixel=bits[4-lx];end
                        else if(lx>=6&&lx<11)begin bits=glyph(4'(i+2),ly[2:0]);label_pixel=bits[10-lx];end
                    end
                    if(target_mask[i]&&(cls==1||cls==2)&&x0<x1&&y0<y1&&x1<W&&y1<H&&
                        (edge_pixel||center_pixel||label_pixel))annotated=cls==1?24'h00ffff:24'h00ff00;
                end
            end
        end
    endfunction
    always @(posedge clk)begin
        if(rst)begin out_vs<=0;out_hs<=0;out_de<=0;out_rgb<=0;end
        else begin
            out_vs<=in_vs;out_hs<=in_hs;out_de<=in_de;
            out_rgb<={annotated(in_rgb[47:24],in_x+11'd1,in_y),annotated(in_rgb[23:0],in_x,in_y)};
        end
    end
endmodule
