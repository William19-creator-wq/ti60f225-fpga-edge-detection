// v4/R1/R2：只用原seed判定，新增点不递归传播；复制补边不作真实邻居。
module edge_context_filter_pair #(parameter integer W=1920,H=1080) (
    input wire clk,rst,frame_start,data_flush,
    input wire in_valid,output wire in_ready,input wire [287:0] in_window_pair,
    input wire [10:0] in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output wire [15:0] out_center_pair,
    output logic [1:0] out_edge_pair,output wire [10:0] out_x_even,out_y,
    output wire out_sof,out_eol,out_eof,output wire empty
);
    logic [1:0] valid_pipe;
    logic [24:0] coordinate_s1,coordinate_s2;
    logic [15:0] center_s1,center_s2;
    logic [1:0] seed_s1,weak_s1,neighbor_s1,gap_s1;
    logic [1:0] neighbor_input,gap_input;
    wire advance=!valid_pipe[1]||out_ready;
    assign in_ready=!rst&&advance;
    assign out_valid=!rst&&valid_pipe[1];
    assign empty=!(|valid_pipe);
    assign out_center_pair=center_s2;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even}=coordinate_s2;
    always_comb begin : spatial_evidence
        integer x,y,dx,dy,first,second;
        logic [8:0] seeds;
        logic [1:0] centre_direction,first_direction,second_direction;
        neighbor_input=0;gap_input=0;
        for(integer lane=0;lane<2;lane=lane+1)begin
            x=int'(in_x_even)+lane;y=int'(in_y);seeds=0;
            for(integer sample=0;sample<9;sample=sample+1)begin
                dx=sample%3-1;dy=sample/3-1;
                seeds[sample]=(x+dx>=0)&&(x+dx<W)&&(y+dy>=0)&&(y+dy<H)
                    &&in_window_pair[lane*144+sample*16+11];
            end
            neighbor_input[lane]=|(seeds&9'b111101111);
            centre_direction=in_window_pair[lane*144+72+:2];
            case(centre_direction)
                0:begin first=1;second=7;end
                2:begin first=3;second=5;end
                1:begin first=2;second=6;end
                default:begin first=0;second=8;end
            endcase
            first_direction=in_window_pair[lane*144+first*16+8+:2];
            second_direction=in_window_pair[lane*144+second*16+8+:2];
            gap_input[lane]=seeds[first]&&seeds[second]
                &&((first_direction^centre_direction)!=2'd2)
                &&((second_direction^centre_direction)!=2'd2);
        end
    end
    always_ff @(posedge clk)begin
        if(rst||frame_start||data_flush)valid_pipe<=0;
        else if(advance)begin
            valid_pipe<={valid_pipe[0],in_valid};
            coordinate_s1<={in_eof,in_eol,in_sof,in_y,in_x_even};
            coordinate_s2<=coordinate_s1;
            center_s1<={in_window_pair[208+:8],in_window_pair[64+:8]};
            center_s2<=center_s1;
            neighbor_s1<=neighbor_input;gap_s1<=gap_input;
            for(integer lane=0;lane<2;lane=lane+1)begin
                seed_s1[lane]<=in_window_pair[lane*144+75];
                weak_s1[lane]<=in_window_pair[lane*144+74];
                out_edge_pair[lane]<=seed_s1[lane]?neighbor_s1[lane]:(weak_s1[lane]&&gap_s1[lane]);
            end
        end
    end
endmodule
