// RR01..05：每个视频时隙不可回压；S0锁旧帧配置，S1颜色与同步一起输出。
module display_renderer #(
    parameter integer IMAGE_WIDTH=1920, IMAGE_HEIGHT=1080
)(
    input logic clk,rst,
    input logic in_de,in_hs,in_vs,in_frame_start,
    input logic [10:0] in_x_even,in_y,
    input logic [53:0] in_pair,
    input logic [111:0] in_render,
    input logic in_pixels_valid,in_identity_good,
    output logic [47:0] out_rgb_pair,
    output logic out_de,out_hs,out_vs,out_frame_start,
    output logic [10:0] out_x_even,out_y,
    output logic [1:0] out_error
);
    typedef struct packed {
        logic [47:0] rgb;
        logic [15:0] gray;
        logic [1:0] edge_bits;
        logic [3:0] ann;
        logic [2:0] mode;
        logic top_half,show_edge,show_ann;
        logic [23:0] edge_color,ann01_color,ann10_color,ann11_color;
        logic de,hs,vs,frame_start;
        logic [10:0] x_even,y;
        logic [1:0] error;
    } pixel_snapshot_t;
    pixel_snapshot_t snapshot,next_snapshot;
    logic [47:0] rendered;

    // RR03：移位前扩成16位；总和最大65408，舍入与R1相同。
    function automatic logic [7:0] gray8(input logic [23:0] rgb);
        logic [15:0] r,g,b,total;
        begin
            r={8'd0,rgb[23:16]};g={8'd0,rgb[15:8]};b={8'd0,rgb[7:0]};
            total=(r<<6)+(r<<3)+(r<<2)+r+
                  (g<<7)+(g<<4)+(g<<2)+(g<<1)+
                  (b<<4)+(b<<3)+(b<<2)+b+16'd128;
            return total[15:8];
        end
    endfunction
    function automatic logic [23:0] select_color(
        input pixel_snapshot_t p,input logic lane
    );
        logic [23:0] original_color;
        logic [7:0] gray;
        logic edge_bit;
        logic [1:0] ann_code;
        begin
            original_color=lane ? p.rgb[47:24] : p.rgb[23:0];
            gray=lane ? p.gray[15:8] : p.gray[7:0];
            edge_bit=p.edge_bits[lane];ann_code=lane ? p.ann[3:2] : p.ann[1:0];
            case(p.mode)
                0:return p.top_half ? {3{gray}} : edge_bit ? 24'hffffff : 24'h000000;
                1:return original_color;
                2:return {3{gray}};
                3:return edge_bit ? 24'hffffff : 24'h000000;
                4:return p.show_edge && edge_bit ? p.edge_color : original_color;
                5:begin
                    // RR02：非透明ANN优先，再边缘；00绝不覆盖原色。
                    if(p.show_ann && ann_code!=0)begin
                        case(ann_code)
                            1:return p.ann01_color;
                            2:return p.ann10_color;
                            3:return p.ann11_color;
                        endcase
                    end
                    return p.show_edge && edge_bit ? p.edge_color : original_color;
                end
                default:return 24'd0;
            endcase
        end
    endfunction
    always_comb begin
        next_snapshot='0;
        next_snapshot.rgb=in_pair[47:0];
        next_snapshot.gray={gray8(in_pair[47:24]),gray8(in_pair[23:0])};
        next_snapshot.edge_bits=in_pair[49:48];next_snapshot.ann=in_pair[53:50];
        next_snapshot.mode=in_render[111:109];
        next_snapshot.top_half=in_y<in_render[108:98];
        next_snapshot.edge_color=in_render[97:74];next_snapshot.ann01_color=in_render[73:50];
        next_snapshot.ann10_color=in_render[49:26];next_snapshot.ann11_color=in_render[25:2];
        next_snapshot.show_edge=in_render[1];next_snapshot.show_ann=in_render[0];
        next_snapshot.de=in_de;next_snapshot.hs=in_hs;next_snapshot.vs=in_vs;next_snapshot.frame_start=in_frame_start;
        next_snapshot.x_even=in_x_even;next_snapshot.y=in_y;
        if(in_de)begin
            if(in_render[111:109]>5 || in_render[108:98]!=IMAGE_HEIGHT/2 || in_x_even[0] || in_x_even>=IMAGE_WIDTH || in_y>=IMAGE_HEIGHT)next_snapshot.error=2;
            else if(!in_identity_good)next_snapshot.error=3;
            else if(!in_pixels_valid)next_snapshot.error=1;
        end
        rendered=0;
        if(snapshot.de && snapshot.error==0)
            rendered={select_color(snapshot,1'b1),select_color(snapshot,1'b0)};
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            snapshot<='0;out_rgb_pair<=0;out_de<=0;out_hs<=0;out_vs<=0;out_frame_start<=0;
            out_x_even<=0;out_y<=0;out_error<=0;
        end else begin
            // S1只读旧snapshot；同沿S0提交的新render不影响这两个旧像素。
            snapshot<=next_snapshot;out_rgb_pair<=rendered;
            out_de<=snapshot.de;out_hs<=snapshot.hs;out_vs<=snapshot.vs;out_frame_start<=snapshot.frame_start;
            out_x_even<=snapshot.x_even;out_y<=snapshot.y;out_error<=snapshot.error;
        end
    end
    // synthesis translate_off
    initial if(IMAGE_WIDTH<4 || IMAGE_WIDTH>1920 || IMAGE_WIDTH%2 || IMAGE_HEIGHT<2 || IMAGE_HEIGHT>1080 || IMAGE_HEIGHT%2)$fatal(1,"Renderer geometry");
    // synthesis translate_on
endmodule
