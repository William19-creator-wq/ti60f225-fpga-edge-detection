// THIN-M3：先复现v4.1结果，再删除可由同方向种子替代的非峰点。
// 方向交接处保留旧结果；原补点不参与删除，细化输出不作新证据。
module edge_thin_filter_pair #(parameter integer W=1920,H=1080,MODE=1) (
    input wire clk,rst,frame_start,data_flush,
    input wire in_valid,output wire in_ready,input wire [431:0] in_window_pair,
    input wire [10:0] in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output wire [15:0] out_center_pair,
    output logic [1:0] out_edge_pair,output wire [10:0] out_x_even,out_y,
    output wire out_sof,out_eol,out_eof,output wire empty
);
    logic [1:0] valid_pipe;
    logic [24:0] coordinate_s1,coordinate_s2;
    logic [15:0] center_s1,center_s2;
    logic [1:0] seed_s1,weak_s1,neighbor_s1,gap_s1,retain_s1;
    logic [1:0] neighbor_input,gap_input,retain_input;
    wire advance=!valid_pipe[1]||out_ready;
    assign in_ready=!rst&&advance;
    assign out_valid=!rst&&valid_pipe[1];
    assign empty=!(|valid_pipe);
    assign out_center_pair=center_s2;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even}=coordinate_s2;
    always_comb begin : spatial_evidence
        integer x,y,dx,dy,tangent_first,tangent_second,normal_first,normal_second;
        logic [8:0] seeds;
        logic [23:0] center_pixel,first_pixel,second_pixel;
        logic [1:0] d,first_d,second_d;
        logic mixed_direction,normal_inside,delete_center;
        neighbor_input=0;gap_input=0;retain_input=2'b11;
        for(integer lane=0;lane<2;lane=lane+1)begin
            x=int'(in_x_even)+lane;y=int'(in_y);seeds=0;
            center_pixel=in_window_pair[lane*216+96+:24];d=center_pixel[9:8];
            mixed_direction=0;
            for(integer sample=0;sample<9;sample=sample+1)begin
                dx=sample%3-1;dy=sample/3-1;
                seeds[sample]=(x+dx>=0)&&(x+dx<W)&&(y+dy>=0)&&(y+dy<H)
                    &&in_window_pair[lane*216+sample*24+11];
                if(sample!=4&&seeds[sample]&&in_window_pair[lane*216+sample*24+8+:2]!=d)
                    mixed_direction=1;
            end
            neighbor_input[lane]=|(seeds&9'b111101111);
            case(d)
                0:begin tangent_first=1;tangent_second=7;normal_first=3;normal_second=5;
                    normal_inside=x>0&&x<W-1;end
                1:begin tangent_first=2;tangent_second=6;normal_first=0;normal_second=8;
                    normal_inside=x>0&&x<W-1&&y>0&&y<H-1;end
                2:begin tangent_first=3;tangent_second=5;normal_first=1;normal_second=7;
                    normal_inside=y>0&&y<H-1;end
                default:begin tangent_first=0;tangent_second=8;normal_first=2;normal_second=6;
                    normal_inside=x>0&&x<W-1&&y>0&&y<H-1;end
            endcase
            first_d=in_window_pair[lane*216+tangent_first*24+8+:2];
            second_d=in_window_pair[lane*216+tangent_second*24+8+:2];
            gap_input[lane]=seeds[tangent_first]&&seeds[tangent_second]
                &&((first_d^d)!=2'd2)&&((second_d^d)!=2'd2);
            first_pixel=in_window_pair[lane*216+normal_first*24+:24];
            second_pixel=in_window_pair[lane*216+normal_second*24+:24];
            delete_center=center_pixel[11]&&(center_pixel[22:12]!=0)&&normal_inside
                &&!mixed_direction&&((MODE==0)||(d==0)||(d==2))
                &&((seeds[normal_first]&&(first_pixel[9:8]==d)
                        &&(first_pixel[22:12]>=center_pixel[22:12]))
                    ||(seeds[normal_second]&&(second_pixel[9:8]==d)
                        &&(second_pixel[22:12]>center_pixel[22:12])));
            retain_input[lane]=!delete_center;
        end
    end
    always_ff @(posedge clk)begin
        if(rst||frame_start||data_flush)valid_pipe<=0;
        else if(advance)begin
            valid_pipe<={valid_pipe[0],in_valid};
            coordinate_s1<={in_eof,in_eol,in_sof,in_y,in_x_even};coordinate_s2<=coordinate_s1;
            center_s1<={in_window_pair[312+:8],in_window_pair[96+:8]};center_s2<=center_s1;
            neighbor_s1<=neighbor_input;gap_s1<=gap_input;retain_s1<=retain_input;
            for(integer lane=0;lane<2;lane=lane+1)begin
                seed_s1[lane]<=in_window_pair[lane*216+107];
                weak_s1[lane]<=in_window_pair[lane*216+106];
                out_edge_pair[lane]<=(seed_s1[lane]?neighbor_s1[lane]:(weak_s1[lane]&&gap_s1[lane]))
                    &&retain_s1[lane];
            end
        end
    end
    // synthesis translate_off
    initial if(MODE!=0&&MODE!=1)$fatal(1,"THIN: only fixed A/B modes");
    // synthesis translate_on
endmodule
