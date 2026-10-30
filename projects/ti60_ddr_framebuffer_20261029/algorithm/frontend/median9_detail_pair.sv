// MD-M1：普通中值并行检查原窗口的细线证据；全部字段共用九级推进。
// 只恢复同中心原灰度，不递归引用新输出，不改变原中值排序器。
module median9_detail_pair #(
    parameter integer W=1920,H=1080,D=16,S=4
)(
    input wire clk,rst,frame_start,flush,
    input wire in_valid,output wire in_ready,input wire [143:0] in_window_pair,
    input wire median_enable,detail_enable,
    input wire [10:0] in_x_even,in_y,input wire in_sof,in_eol,in_eof,
    output wire out_valid,input wire out_ready,output wire [15:0] out_y_pair,
    output wire [10:0] out_x_even,out_y,output wire out_sof,out_eol,out_eof,empty
);
    wire [15:0] ordinary;
    median9_pair legacy(
        .clk(clk),.rst(rst),.frame_start(frame_start),.flush(flush),
        .in_valid(in_valid),.in_ready(in_ready),.in_window_pair(in_window_pair),
        .median_enable(median_enable),.in_x_even(in_x_even),.in_y(in_y),
        .in_sof(in_sof),.in_eol(in_eol),.in_eof(in_eof),
        .out_valid(out_valid),.out_ready(out_ready),.out_y_pair(ordinary),
        .out_x_even(out_x_even),.out_y(out_y),.out_sof(out_sof),.out_eol(out_eol),.out_eof(out_eof),.empty(empty)
    );
    wire advance=in_ready;
    localparam logic signed [8:0] D_POS=D,D_NEG=-D,S_POS=S,S_NEG=-S;
    localparam logic [8:0] BACKGROUND_SPAN=2*S;
    logic [7:0] pair_min_s1[0:1][0:3],pair_max_s1[0:1][0:3];
    wire [7:0] pair_min_input[0:1][0:3],pair_max_input[0:1][0:3];
    wire [3:0] near_input[0:1],positive_input[0:1],negative_input[0:1];
    logic [3:0] near_s1[0:1],positive_s1[0:1],negative_s1[0:1];
    logic [1:0] enabled_inside_s1;
    logic [15:0] center_pipe[0:8];
    logic [3:0] qualified_input[0:1],qualified_s2[0:1];
    logic [7:0] minimum_input[0:1][0:3],maximum_input[0:1][0:3];
    logic [7:0] minimum_s2[0:1][0:3],maximum_s2[0:1][0:3];
    logic [3:0] keep_s3[0:1],keep_s4[0:1];
    logic [4:0] keep_tail[0:1];

    function automatic integer tangent_first(input integer direction);
        case(direction) 0:tangent_first=1;1:tangent_first=0;2:tangent_first=3;default:tangent_first=2;endcase
    endfunction
    function automatic integer tangent_last(input integer direction);
        case(direction) 0:tangent_last=7;1:tangent_last=8;2:tangent_last=5;default:tangent_last=6;endcase
    endfunction
    function automatic [15:0] ordered(input logic[7:0] a,b);
        ordered=a<=b?{b,a}:{a,b};
    endfunction
    // 六背景值用平衡比较树；不把串行六次归约放在同一时序路径。
    generate for(genvar lane=0;lane<2;lane=lane+1)begin:lane_evidence
        for(genvar direction=0;direction<4;direction=direction+1)begin:orientation
            localparam integer FIRST=tangent_first(direction),LAST=tangent_last(direction);
            // 八邻居恰分成四个相对点对，当前方向的背景是其余三个点对。
            localparam integer B0=(direction==0)?1:0,B1=(direction<=1)?2:1,B2=(direction<=2)?3:2;
            wire [15:0] input_order=ordered(in_window_pair[lane*72+FIRST*8+:8],in_window_pair[lane*72+LAST*8+:8]);
            wire signed [8:0] first_difference=$signed({1'b0,in_window_pair[lane*72+32+:8]})
                -$signed({1'b0,in_window_pair[lane*72+FIRST*8+:8]});
            wire signed [8:0] last_difference=$signed({1'b0,in_window_pair[lane*72+32+:8]})
                -$signed({1'b0,in_window_pair[lane*72+LAST*8+:8]});
            assign pair_min_input[lane][direction]=input_order[7:0];
            assign pair_max_input[lane][direction]=input_order[15:8];
            assign near_input[lane][direction]=first_difference>=S_NEG&&first_difference<=S_POS
                &&last_difference>=S_NEG&&last_difference<=S_POS;
            assign positive_input[lane][direction]=first_difference>=D_POS&&last_difference>=D_POS;
            assign negative_input[lane][direction]=first_difference<=D_NEG&&last_difference<=D_NEG;
            wire [15:0] min01=ordered(pair_min_s1[lane][B0],pair_min_s1[lane][B1]);
            wire [15:0] max01=ordered(pair_max_s1[lane][B0],pair_max_s1[lane][B1]);
            wire [15:0] min_all=ordered(min01[7:0],pair_min_s1[lane][B2]);
            wire [15:0] max_all=ordered(max01[15:8],pair_max_s1[lane][B2]);
            assign minimum_input[lane][direction]=min_all[7:0];
            assign maximum_input[lane][direction]=max_all[15:8];
            assign qualified_input[lane][direction]=enabled_inside_s1[lane]&&near_s1[lane][direction]
                &&((positive_s1[lane][B0]&&positive_s1[lane][B1]&&positive_s1[lane][B2])
                  ||(negative_s1[lane][B0]&&negative_s1[lane][B1]&&negative_s1[lane][B2]));
        end
        assign out_y_pair[lane*8+:8]=keep_tail[lane][4]?center_pipe[8][lane*8+:8]:ordinary[lane*8+:8];
    end endgenerate

    always_ff @(posedge clk)begin
        if(rst||frame_start||flush)begin
            enabled_inside_s1<=0;
            for(integer lane=0;lane<2;lane=lane+1)begin
                qualified_s2[lane]<=0;keep_s3[lane]<=0;keep_s4[lane]<=0;keep_tail[lane]<=0;
            end
        end else if(advance)begin
            center_pipe[0]<={in_window_pair[104+:8],in_window_pair[32+:8]};
            for(integer stage=1;stage<9;stage=stage+1)center_pipe[stage]<=center_pipe[stage-1];
            for(integer lane=0;lane<2;lane=lane+1)begin
                enabled_inside_s1[lane]<=median_enable&&detail_enable
                    &&(int'(in_x_even)+lane>0)&&(int'(in_x_even)+lane<W-1)&&(in_y>0)&&(in_y<H-1);
                near_s1[lane]<=near_input[lane];
                positive_s1[lane]<=positive_input[lane];negative_s1[lane]<=negative_input[lane];
                for(integer direction=0;direction<4;direction=direction+1)begin
                    pair_min_s1[lane][direction]<=pair_min_input[lane][direction];
                    pair_max_s1[lane][direction]<=pair_max_input[lane][direction];
                end
                qualified_s2[lane]<=qualified_input[lane];
                for(integer direction=0;direction<4;direction=direction+1)begin
                    minimum_s2[lane][direction]<=minimum_input[lane][direction];
                    maximum_s2[lane][direction]<=maximum_input[lane][direction];
                    keep_s3[lane][direction]<=qualified_s2[lane][direction]
                        &&({1'b0,maximum_s2[lane][direction]}-{1'b0,minimum_s2[lane][direction]}<=BACKGROUND_SPAN);
                end
                keep_s4[lane]<=keep_s3[lane];
                keep_tail[lane]<={keep_tail[lane][3:0],|keep_s4[lane]};
            end
        end
    end
    // synthesis translate_off
    initial if(D!=16||S!=4)$fatal(1,"median detail: only selected A D16/S4 implemented");
    initial if(W<6||W>1920||W%2!=0||H<5||H>1080)$fatal(1,"median detail dimensions");
    // synthesis translate_on
endmodule
