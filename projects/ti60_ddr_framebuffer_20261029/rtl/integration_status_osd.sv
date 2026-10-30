// Compact fixed-position status: M<mode> T<threshold in hex> F<filter> S<menu>.
// Threshold/filter come from the displayed frame, not unsampled button requests.
// One registered pixel-pair stage preserves sync/RGB alignment.
module integration_status_osd #(
    parameter integer W=1920,H=1080,HISTORY_STATUS=0
)(
    input wire [79:0] history_status,
    input wire [129:0] compare_status,input wire [5:0] compare_a_selection,compare_b_selection,
    input wire [31:0] source_counts,source_rates,
    input wire [4:0] source_reasons,
    input wire [63:0] fps_counts,fps_rates,
    input wire [15:0] fps_errors,
    input wire fps_valid,
    input wire [95:0] canny_debug,
    input wire [63:0] canny_perf,
    input wire [15:0] canny_frame,
    input wire clk,rst,in_vs,in_hs,in_de,
    input wire [47:0] in_rgb,
    input wire [2:0] active_mode,
    input wire [10:0] active_threshold,
    input wire [1:0] active_filter,
    input wire menu_open,
    input wire active_edge_enhance,
    input wire [2:0] menu_item,
    input wire [4:0] key_levels_n,
    output reg out_vs,out_hs,out_de,
    output reg [47:0] out_rgb
);
    reg vs_d;
    reg [10:0] x,y;
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
            22:glyph=35'b00111_00010_00010_00010_10010_10010_01100; // J
            23:glyph=35'b11110_10001_10001_11110_10100_10010_10001; // R
            24:glyph=35'b10001_10001_10001_11111_10001_10001_10001; // H
            25:glyph=35'b01110_10001_10001_10001_10101_10010_01101; // Q
            26:glyph=35'b10001_10001_10001_10001_10001_01010_00100; // V
            27:glyph=35'b10001_11001_11001_10101_10011_10011_10001; // N
            28:glyph=35'b01110_10001_10000_10111_10001_10001_01110; // G
            default:glyph=0;
        endcase
    endfunction
    function automatic [23:0] pixel(input [23:0] original,input [10:0] px,py);
        integer cell_x,gx,gy,row,field;
        reg [15:0] count_value,rate_value;
        reg [4:0] c;
        reg [34:0] bits;
        reg on_panel;reg [23:0] foreground,background;
        begin
            pixel=original;on_panel=0;c=31;gx=0;gy=0;foreground=24'hffffff;background=24'h101010;
            if(px>=16&&px<528&&py>=16&&(py<80||(active_mode==5&&py<240)))begin
                cell_x=(int'(px)-16)/32;gx=((int'(px)-16)%32)/4;gy=((int'(py)-16)%32)/4;
                c=31;
                if(py<48)case(cell_x)
                    0:c=16;1:c={2'b0,active_mode};3:c=17;
                    4:c={2'b0,active_threshold[10:8]};5:c={1'b0,active_threshold[7:4]};6:c={1'b0,active_threshold[3:0]};
                    8:c=15;9:c={3'b0,active_filter};11:c=18;12:c={4'b0,menu_open};
                    14:c=14;15:c={4'b0,active_edge_enhance};
                    default:c=31;
                endcase
                else if(py<80)case(cell_x)
                    0:c=19;
                    1:c={4'b0,!key_levels_n[4]};2:c={4'b0,!key_levels_n[3]};3:c={4'b0,!key_levels_n[2]};
                    5:c=20;6:c={4'b0,!key_levels_n[1]};7:c={4'b0,!key_levels_n[0]};
                    9:c=21;10:c={2'b0,menu_item};
                    default:c=31;
                endcase
                else if(py<112)case(cell_x)
                    0:c=22; // J completed jobs
                    1,2,3,4:c={1'b0,canny_debug[(4-cell_x)*4+:4]};
                    6:c=15; // F failed attempts
                    7,8,9,10:c={1'b0,canny_debug[16+(10-cell_x)*4+:4]};
                    12:c=18;13:c={1'b0,canny_debug[35:32]};
                    14:c=12;15:c={1'b0,canny_debug[39:36]};
                    default:c=31;
                endcase
                else if(py<144)case(cell_x)
                    0:c=23;1:c={1'b0,canny_debug[47:44]};2:c={1'b0,canny_debug[43:40]};
                    4:c=25;5:c={1'b0,canny_debug[95:92]};6:c={1'b0,canny_debug[91:88]};
                    8:c=21;
                    9,10,11,12,13:c={1'b0,canny_debug[56+(13-cell_x)*4+:4]};
                    default:c=31;
                endcase
                else if(py<176)case(cell_x)
                    0:c=13; // D displayed frame handle
                    1,2,3,4:c={1'b0,canny_frame[(4-cell_x)*4+:4]};
                    6:c=24;7:c={1'b0,canny_debug[55:52]};8:c={1'b0,canny_debug[51:48]};
                    10:c=10;11:c={1'b0,canny_debug[87:84]}; // A active handle low nibble
                    default:c=31;
                endcase
                // Last retired frame times, hexadecimal MILLISECONDS:
                // C capture, P preprocessing, H full hysteresis/export,
                // T complete acquisition-to-display-ACK iteration.
                else if(py<208)case(cell_x)
                    0:c=12;
                    1,2,3,4:c={1'b0,canny_perf[(4-cell_x)*4+:4]};
                    6:c=20;
                    7,8,9,10:c={1'b0,canny_perf[16+(10-cell_x)*4+:4]};
                    default:c=31;
                endcase
                else case(cell_x)
                    0:c=24;
                    1,2,3,4:c={1'b0,canny_perf[32+(4-cell_x)*4+:4]};
                    6:c=17;
                    7,8,9,10:c={1'b0,canny_perf[48+(10-cell_x)*4+:4]};
                    default:c=31;
                endcase
                on_panel=1;
            end
            // Separate fixed panel: no extra pixel pipeline stage or scan changes.
            // Hexadecimal counts and integer frames in the last one-second window.
            if(px>=560&&px<1072&&py>=16&&py<304)begin
                cell_x=(int'(px)-560)/32;gx=((int'(px)-560)%32)/4;
                row=(int'(py)-16)/32;gy=((int'(py)-16)%32)/4;
                c=31;count_value=0;rate_value=0;field=0;
                if(row==0)case(cell_x)
                    0:c=11;1:c=3;2:c=0;3:c=1; // B301: Catalog DDR, history and paired comparison candidate
                    6:c=26;7:c={4'b0,fps_valid};
                    default:c=31;
                endcase
                else if(row<=4)begin
                    field=row-1;count_value=fps_counts[field*16+:16];rate_value=fps_rates[field*16+:16];
                    case(cell_x)
                        0:case(row)1:c=12;2:c=20;3:c=13;default:c=24;endcase
                        1,2,3,4:c={1'b0,count_value[(4-cell_x)*4+:4]};
                        6:c=23;
                        7,8,9,10:c={1'b0,rate_value[(10-cell_x)*4+:4]};
                        default:c=31;
                    endcase
                end else if(row==5)case(cell_x)
                    0:c=14;1,2,3,4:c={1'b0,fps_errors[(4-cell_x)*4+:4]};
                    default:c=31;
                endcase
                else if(row==6||row==7)begin
                    field=row-6;count_value=source_counts[field*16+:16];rate_value=source_rates[field*16+:16];
                    case(cell_x)
                        0:c=(row==6)?26:11; // V raw VS intervals, B rejected geometry
                        1,2,3,4:c={1'b0,count_value[(4-cell_x)*4+:4]};
                        6:c=23;
                        7,8,9,10:c={1'b0,rate_value[(10-cell_x)*4+:4]};
                        default:c=31;
                    endcase
                end else case(cell_x)
                    0:c=21;1:c={4'b0,source_reasons[4]};2:c={1'b0,source_reasons[3:0]};
                    default:c=31;
                endcase
                on_panel=1;
            end
            if(HISTORY_STATUS&&px>=1104&&px<1680&&py>=16&&py<80)begin
                cell_x=(int'(px)-1104)/32;gx=((int'(px)-1104)%32)/4;gy=((int'(py)-16)%32)/4;c=31;
                if(py<48)case(cell_x)
                    0:c=20;1:c={3'b0,history_status[78:77]};
                    3:c=21;4:c={3'b0,history_status[76:75]};5:c={1'b0,history_status[74:71]};
                    7:c=24;8:c={2'b0,history_status[70:68]};9:c={1'b0,history_status[67:64]};
                    11:c=14;12:c={4'b0,history_status[79]};
                    default:c=31;
                endcase
                else begin
                    if(cell_x==0)c=15;
                    else if(cell_x>=1&&cell_x<=16)c={1'b0,history_status[(16-cell_x)*4+:4]};
                end
                on_panel=1;
            end
            if(HISTORY_STATUS&&px>=1104&&px<1680&&py>=80&&py<208)begin
                cell_x=(int'(px)-1104)/32;gx=((int'(px)-1104)%32)/4;gy=((int'(py)-80)%32)/4;c=31;
                if(py<112)case(cell_x)
                    0:c=10;1:c={3'd0,compare_a_selection[5:4]};2:c={1'b0,compare_a_selection[3:0]};
                    4:c=11;5:c={3'd0,compare_b_selection[5:4]};6:c={1'b0,compare_b_selection[3:0]};
                    8:c=12;9:c={4'd0,compare_status[129]};default:c=31;
                endcase
                else if(compare_status[129]&&py<144)case(cell_x)
                    0:c=10;2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17:c={1'b0,compare_status[64+(17-cell_x)*4+:4]};default:c=31;
                endcase
                else if(compare_status[129]&&py<176)case(cell_x)
                    0:c=11;2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17:c={1'b0,compare_status[(17-cell_x)*4+:4]};default:c=31;
                endcase
                else if(compare_status[129]&&compare_status[128])case(cell_x)
                    0:c=20;1:c=23;2:c=14;3:c=20;4:c=10;5:c=23;6:c=21;7:c=27;8:c=28;default:c=31;
                endcase
                on_panel=1;background=24'h101018;foreground=24'hffff80;
            end
            // Disjoint panels share font decode and glyph bit selection.
            bits=glyph(c);
            if(on_panel)pixel=(gx<5&&gy<7&&bits[34-gy*5-gx])?foreground:background;
        end
    endfunction
    // All panel/glyph boundaries are even and glyphs are four pixels wide.
    // An aligned two-pixel pair therefore shares one overlay decision; compute
    // that decision once while preserving the two distinct underlying pixels.
    wire overlay_region=(x>=16&&x<528&&y>=16&&(y<80||(active_mode==5&&y<240)))||
                        (x>=560&&x<1072&&y>=16&&y<304)||
                        (HISTORY_STATUS&&x>=1104&&x<1680&&y>=16&&y<208);
    wire [23:0] overlay_pixel=pixel(24'd0,x,y);
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
            out_rgb<=overlay_region?{overlay_pixel,overlay_pixel}:in_rgb;
        end
    end
endmodule
