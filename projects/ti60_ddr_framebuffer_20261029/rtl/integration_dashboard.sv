// Compact fixed-position status: M<mode> T<threshold in hex> F<filter> S<menu>.
// Threshold/filter come from the displayed frame, not unsampled button requests.
// One registered pixel-pair stage preserves sync/RGB alignment.
module integration_dashboard #(
    parameter integer W=1920,H=1080,CANNY_MODE=0,NOISE_STATUS=0
)(
    input wire clk,rst,in_vs,in_hs,in_de,
    input wire [47:0] in_rgb,
    input wire [2:0] active_mode,
    input wire [10:0] active_threshold,
    input wire [1:0] active_filter,
    input wire menu_open,
    input wire active_edge_enhance,
    input wire [2:0] menu_item,
    input wire [4:0] key_levels_n,
    input wire [1:0] active_noise,
    input wire frozen,wide_overlay,overlay_canny,target_overflow,result_valid,
    input wire [1:0] compare_mode,
    input wire [21:0] unknown_count,input wire [7:0] unknown_reasons,
    input wire [95:0] result_scope,
    input wire [15:0] capture_fps_x10,process_fps_x10,update_fps_x10,display_fps_x10,
    input wire [31:0] processing_ms,
    output reg out_vs,out_hs,out_de,
    output reg [47:0] out_rgb
);
    reg vs_d;
    reg [10:0] x,y;
    reg z,w,o,rv,cs;reg [1:0] cmp;
    reg [21:0] unknown;reg [7:0] reasons;reg [95:0] scope;
    reg [15:0] fps[0:3];reg [31:0] latency;
    function automatic [34:0] glyph(input [4:0] c);
        case(c)
            0:glyph=35'b01110_10001_10011_10101_11001_10001_01110;
            1:glyph=35'b00100_01100_00100_00100_00100_00100_01110;
            2:glyph=35'b01110_10001_00001_00010_00100_01000_11111;
            3:glyph=35'b11110_00001_00001_01110_00001_00001_11110;
            4:glyph=35'b00010_00110_01010_10010_11111_00010_00010;
            5:glyph=35'b11111_10000_10000_11110_00001_00001_11110;
            6:glyph=35'b01110_10000_10000_11110_10001_10001_01110;
            7:glyph=35'b11111_00001_00010_00100_01000_01000_01000;
            8:glyph=35'b01110_10001_10001_01110_10001_10001_01110;
            9:glyph=35'b01110_10001_10001_01111_00001_00001_01110;
            10:glyph=35'b01110_10001_10001_11111_10001_10001_10001;
            11:glyph=35'b11110_10001_10001_11110_10001_10001_11110;
            12:glyph=35'b01111_10000_10000_10000_10000_10000_01111;
            13:glyph=35'b11110_10001_10001_10001_10001_10001_11110;
            14:glyph=35'b11111_10000_10000_11110_10000_10000_11111;
            15:glyph=35'b11111_10000_10000_11110_10000_10000_10000;
            16:glyph=35'b10001_11011_10101_10101_10001_10001_10001; // M
            17:glyph=35'b11111_00100_00100_00100_00100_00100_00100; // T
            18:glyph=35'b01111_10000_10000_01110_00001_00001_11110; // S
            19:glyph=35'b10001_10010_10100_11000_10100_10010_10001; // K
            20:glyph=35'b11110_10001_10001_11110_10000_10000_10000; // P
            21:glyph=35'b11111_00100_00100_00100_00100_00100_11111; // I
            22:glyph=35'b10001_11001_11001_10101_10011_10011_10001; // N
            23:glyph=35'b00000_00000_00000_00000_00000_00110_00110; // .
            24:glyph=35'b11111_00001_00010_00100_01000_10000_11111; // Z
            25:glyph=35'b10001_10001_10001_10101_10101_11011_10001; // W
            26:glyph=35'b01110_10001_10001_10001_10101_10010_01101; // Q
            27:glyph=35'b10001_10001_10001_10001_10001_10001_01110; // U
            28:glyph=35'b01110_10001_10001_10001_10001_10001_01110; // O
            29:glyph=35'b10000_10000_10000_10000_10000_10000_11111; // L
            30:glyph=35'b11110_10001_10001_11110_10100_10010_10001; // R
            default:glyph=0;
        endcase
    endfunction
    function automatic [24:0] overlay_pixel(input [10:0] px,py);
        integer cell_x,gx,gy,field,digit;reg [15:0] rate;
        reg [4:0] c;
        reg [34:0] bits;
        begin
            overlay_pixel=25'd0;
            if(px>=16&&px<688&&py>=16&&py<208)begin
                cell_x=(int'(px)-16)/24;gx=((int'(px)-16)%24)/4;gy=((int'(py)-16)%32)/4;
                c=31;
                if(py<48)case(cell_x)
                    0:c=16;1:c={2'b0,active_mode};3:c=17;
                    4:c={2'b0,active_threshold[10:8]};5:c={1'b0,active_threshold[7:4]};6:c={1'b0,active_threshold[3:0]};
                    8:c=15;9:c={3'b0,active_filter};11:c=18;12:c={4'b0,menu_open};
                    14:c=CANNY_MODE&&(active_mode==5||active_mode==6||(active_mode==4&&cs))?12:14;15:c=CANNY_MODE&&(active_mode==5||active_mode==6||(active_mode==4&&cs))?1:{4'b0,active_edge_enhance};
                    default:c=31;
                endcase
                else if(py<80)case(cell_x)
                    0:c=19;
                    1:c={4'b0,!key_levels_n[4]};2:c={4'b0,!key_levels_n[3]};3:c={4'b0,!key_levels_n[2]};
                    5:c=20;6:c={4'b0,!key_levels_n[1]};7:c={4'b0,!key_levels_n[0]};
                    9:c=21;10:c={2'b0,menu_item};
                    // Heavy results need their stored frame's noise metadata;
                    // do not label an old Canny result with the new live rate.
                    12:if(NOISE_STATUS&&!z&&active_mode<5&&!(active_mode==4&&cs))c=22;
                    13:if(NOISE_STATUS&&!z&&active_mode<5&&!(active_mode==4&&cs))c=active_noise==0?0:active_noise==1?1:active_noise==2?3:5;
                    default:c=31;
                endcase
                else if(py<112)case(cell_x)
                    0:c=24;1:c={4'b0,z};3:c=25;4:c=w?3:1;
                    6:c=26;7:c={3'b0,cmp};9:c=28;10:c={4'b0,o};
                    12:c=27;13:c=unknown>4095?15:{1'b0,unknown[11:8]};14:c=unknown>4095?15:{1'b0,unknown[7:4]};15:c=unknown>4095?15:{1'b0,unknown[3:0]};
                    17:c=12;18:c={4'b0,cs};20:c=30;21:c={4'b0,rv};default:c=31;
                endcase
                else if(py<144)begin
                    field=cell_x/7;digit=cell_x%7;rate=fps[field]>999?999:fps[field];
                    case(digit)
                        0:case(field)0:c=12;1:c=20;2:c=27;default:c=13;endcase
                        1:c=5'(rate/100);2:c=5'((rate/10)%10);3:c=23;4:c=5'(rate%10);default:c=31;
                    endcase
                end else if(py<176)case(cell_x)
                    0:c=21;1:c={1'b0,scope[15:12]};2:c={1'b0,scope[11:8]};3:c={1'b0,scope[7:4]};4:c={1'b0,scope[3:0]};
                    6:c=12;7:c={1'b0,scope[79:76]};8:c={1'b0,scope[75:72]};9:c={1'b0,scope[71:68]};10:c={1'b0,scope[67:64]};
                    12:c=29;13:c={1'b0,latency[31:28]};14:c={1'b0,latency[27:24]};15:c={1'b0,latency[23:20]};16:c={1'b0,latency[19:16]};
                    17:c={1'b0,latency[15:12]};18:c={1'b0,latency[11:8]};19:c={1'b0,latency[7:4]};20:c={1'b0,latency[3:0]};default:c=31;
                endcase
                else case(cell_x)0:c=30;1:c={1'b0,reasons[7:4]};2:c={1'b0,reasons[3:0]};default:c=31;endcase
                bits=glyph(c);
                overlay_pixel={1'b1,(gx<5&&gy<7&&bits[34-gy*5-gx])?24'hffffff:24'h101010};
            end
        end
    endfunction
    wire [24:0] overlay=overlay_pixel(x,y);
    // Pixels arrive in even/odd pairs; 4x font cells have the same value in both.
    always @(posedge clk)begin
        if(rst)begin z<=0;w<=1;o<=0;rv<=0;cs<=0;cmp<=0;unknown<=0;reasons<=0;scope<=0;latency<=0;for(integer k=0;k<4;k=k+1)fps[k]<=0;end
        else if(in_vs&&!vs_d)begin
            z<=frozen;w<=wide_overlay;o<=target_overflow;rv<=result_valid;cs<=overlay_canny;cmp<=compare_mode;
            unknown<=unknown_count;reasons<=unknown_reasons;scope<=result_scope;latency<=processing_ms;
            fps[0]<=capture_fps_x10;fps[1]<=process_fps_x10;fps[2]<=update_fps_x10;fps[3]<=display_fps_x10;
        end
    end
    always @(posedge clk)begin
        if(rst)begin vs_d<=0;x<=0;y<=0;out_vs<=0;out_hs<=0;out_de<=0;out_rgb<=0;end
        else begin
            vs_d<=in_vs;
            if(in_vs&&!vs_d)begin x<=0;y<=0;end
            else if(in_de)begin
                if(x==W-2)begin x<=0;y<=y==H-1?11'd0:y+11'd1;end
                else x<=x+11'd2;
            end
            out_vs<=in_vs;out_hs<=in_hs;out_de<=in_de;
            out_rgb<=overlay[24]?{2{overlay[23:0]}}:in_rgb;
        end
    end
endmodule
