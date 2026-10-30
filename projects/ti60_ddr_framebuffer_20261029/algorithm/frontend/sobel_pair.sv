// FE-04 / OP-07：六级Sobel；中心、梯度诊断及edge共用一次输出握手。
module sobel_pair #(
    parameter integer RUNTIME_EDGE_CONFIG = 0,
    parameter integer COHERENCE_ENABLE = 0,
    parameter integer COHERENCE_MIN_DIFF = 16,
    parameter integer WEAK_ENABLE = 0,
    parameter integer WEAK_MIN_DIFF = 18,
    parameter integer WEAK_THRESHOLD_DROP = 0,
    parameter integer DIAGONAL_ENABLE = 0,
    parameter integer DIAGONAL_MIN_DIFF = 19
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         frame_start,
    input  wire         flush,
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [143:0] in_window_pair,
    input  wire [1:0]   output_kind,
    input  wire [10:0]  threshold,
    input  wire         enhance_enable, // held for the entire job, like threshold
    input  wire [10:0]  in_x_even,
    input  wire [10:0]  in_y,
    input  wire         in_sof,
    input  wire         in_eol,
    input  wire         in_eof,
    output wire         out_valid,
    input  wire         out_ready,
    output wire [15:0]  out_y_pair,
    output logic [1:0]  out_edge,
    output wire [21:0]  out_gx_pair,
    output wire [21:0]  out_gy_pair,
    output logic [21:0] out_l1_pair,
    output wire [10:0]  out_x_even,
    output wire [10:0]  out_y,
    output wire         out_sof,
    output wire         out_eol,
    output wire         out_eof,
    output wire         empty
);
    logic [5:0] valid_pipe;
    logic [24:0] coordinate_pipe [0:5];
    logic [15:0] center_pipe [0:5];
    // side索引：0右，1左，2下，3上。
    logic [8:0] corner_sums_s1 [0:1][0:3];
    logic [8:0] middle_twice_s1 [0:1][0:3];
    logic [9:0] side_sums [0:1][0:3];
    logic signed [10:0] signed_gradient_x [0:1];
    logic signed [10:0] signed_gradient_y [0:1];
    logic [9:0] absolute_x_s4 [0:1];
    logic [9:0] absolute_y_s4 [0:1];
    logic [10:0] l1_magnitude [0:1];
    logic signed [10:0] gradient_delay_x [0:2][0:1];
    logic signed [10:0] gradient_delay_y [0:2][0:1];
    wire [1:0] threshold_compare;
    wire raw_sobel = (RUNTIME_EDGE_CONFIG != 0) && !enhance_enable;
    wire pipeline_advance = !valid_pipe[5] || out_ready;
    // v2：相同窗口的方向支持旁路，默认关闭以保留原Sobel接口语义。
    localparam logic signed [8:0] SUPPORT_MIN = COHERENCE_MIN_DIFF;
    localparam logic signed [8:0] SUPPORT_NEG_MIN = -SUPPORT_MIN;
    logic signed [8:0] row_difference_s1 [0:1][0:2];
    logic signed [8:0] column_difference_s1 [0:1][0:2];
    // bit0正向、bit1负向；S3必须与同窗口Gx/Gy处于同一阶段。
    logic [1:0] support_x_s2 [0:1], support_y_s2 [0:1];
    logic [1:0] support_x_s3 [0:1], support_y_s3 [0:1];
    logic [1:0] coherence_s4, coherence_s5;
    // v3/R1～R3：全三项支持只补充原edge；与基础旁路共用推进事件。
    localparam logic signed [8:0] WEAK_MIN = WEAK_MIN_DIFF;
    localparam logic signed [8:0] WEAK_NEG_MIN = -WEAK_MIN;
    localparam logic [10:0] WEAK_DROP = WEAK_THRESHOLD_DROP;
    wire [10:0] weak_threshold = (threshold >= WEAK_DROP)
        ? threshold - WEAK_DROP : 11'd0; // 低阈值饱和，禁止无符号回绕。
    logic [1:0] weak_x_s2 [0:1], weak_y_s2 [0:1];
    logic [1:0] weak_x_s3 [0:1], weak_y_s3 [0:1];
    logic [1:0] weak_coherence_s4, weak_coherence_s5;
    // v4.1/R1：双轴同时支持的斜向种子，补回被全三项规则拒绝的弱斜边。
    localparam logic signed [8:0] DIAGONAL_MIN=DIAGONAL_MIN_DIFF;
    localparam logic signed [8:0] DIAGONAL_NEG_MIN=-DIAGONAL_MIN;
    logic [1:0] diagonal_x_s2 [0:1],diagonal_y_s2 [0:1];
    logic [1:0] diagonal_x_s3 [0:1],diagonal_y_s3 [0:1];
    logic [1:0] diagonal_s4,diagonal_s5;
    function automatic [1:0] diagonal_majority(
        input logic signed [8:0] first,second,third
    );
        logic [1:0] pos_count,neg_count;
        begin
            pos_count={1'b0,first>=DIAGONAL_MIN}+{1'b0,second>=DIAGONAL_MIN}+{1'b0,third>=DIAGONAL_MIN};
            neg_count={1'b0,first<=DIAGONAL_NEG_MIN}+{1'b0,second<=DIAGONAL_NEG_MIN}+{1'b0,third<=DIAGONAL_NEG_MIN};
            diagonal_majority={neg_count>=2'd2,pos_count>=2'd2};
        end
    endfunction
    function automatic in_diagonal_band(input logic signed [10:0] gx,gy);
        logic [10:0] ax,ay;
        begin
            ax=gx<0?-gx:gx;ay=gy<0?-gy:gy;
            // 绝对值<=1020，先以11位表示，两倍<=2040而不截成10位。
            in_diagonal_band=(ax!=0)&&(ay!=0)&&(ax<=(ay<<1))&&(ay<=(ax<<1));
        end
    endfunction

    function automatic [1:0] unanimous_support(
        input logic signed [8:0] first, second, third
    );
        unanimous_support = {
            (first <= WEAK_NEG_MIN) && (second <= WEAK_NEG_MIN) && (third <= WEAK_NEG_MIN),
            (first >= WEAK_MIN) && (second >= WEAK_MIN) && (third >= WEAK_MIN)};
    endfunction

    function automatic [1:0] majority_support(
        input logic signed [8:0] first, second, third
    );
        logic [1:0] positive_count, negative_count;
        begin
            // 比较结果先扩2位，三个布尔值之和才能表示0～3。
            positive_count = {1'b0, first >= SUPPORT_MIN}
                + {1'b0, second >= SUPPORT_MIN} + {1'b0, third >= SUPPORT_MIN};
            negative_count = {1'b0, first <= SUPPORT_NEG_MIN}
                + {1'b0, second <= SUPPORT_NEG_MIN} + {1'b0, third <= SUPPORT_NEG_MIN};
            majority_support = {negative_count >= 2'd2, positive_count >= 2'd2};
        end
    endfunction

    function automatic direction_supported(
        input logic signed [10:0] gradient, input logic [1:0] support_bits
    );
        direction_supported = ((gradient > 11'sd0) && support_bits[0])
            || ((gradient < 11'sd0) && support_bits[1]);
    endfunction

    function automatic [9:0] absolute_gradient11 (
        input logic signed [10:0] gradient
    );
        logic signed [10:0] positive_value;
        begin
            // 合法窗口范围±1020，因此不会出现11bit的最负值−1024。
            positive_value = (gradient < 11'sd0) ? -gradient : gradient;
            absolute_gradient11 = positive_value[9:0];
        end
    endfunction

    assign in_ready = !rst && pipeline_advance;
    assign out_valid = !rst && valid_pipe[5];
    assign empty = !(|valid_pipe);
    assign out_y_pair = center_pipe[5];
    assign out_gx_pair = {gradient_delay_x[2][1], gradient_delay_x[2][0]};
    assign out_gy_pair = {gradient_delay_y[2][1], gradient_delay_y[2][0]};
    assign {out_eof, out_eol, out_sof, out_y, out_x_even} = coordinate_pipe[5];
    assign threshold_compare[0] = (output_kind == 2'd1) && (raw_sobel ?
        (l1_magnitude[0] > threshold) : (
        ((l1_magnitude[0] > threshold) && ((COHERENCE_ENABLE == 0) || coherence_s5[0]))
        || ((WEAK_ENABLE != 0) && (l1_magnitude[0] > weak_threshold) && weak_coherence_s5[0])
        || ((DIAGONAL_ENABLE != 0) && (l1_magnitude[0] > threshold) && diagonal_s5[0])));
    assign threshold_compare[1] = (output_kind == 2'd1) && (raw_sobel ?
        (l1_magnitude[1] > threshold) : (
        ((l1_magnitude[1] > threshold) && ((COHERENCE_ENABLE == 0) || coherence_s5[1]))
        || ((WEAK_ENABLE != 0) && (l1_magnitude[1] > weak_threshold) && weak_coherence_s5[1])
        || ((DIAGONAL_ENABLE != 0) && (l1_magnitude[1] > threshold) && diagonal_s5[1])));

    always_ff @(posedge clk) begin : sobel_pipeline
        if (rst || flush || frame_start) begin
            valid_pipe <= 6'b0;
        end else if (pipeline_advance) begin
            valid_pipe <= {valid_pipe[4:0], in_valid};
            coordinate_pipe[0] <= {in_eof, in_eol, in_sof, in_y, in_x_even};
            center_pipe[0] <= {in_window_pair[104 +: 8], in_window_pair[32 +: 8]};
            for (integer stage = 1; stage < 6; stage = stage + 1) begin
                coordinate_pipe[stage] <= coordinate_pipe[stage-1];
                center_pipe[stage] <= center_pipe[stage-1];
            end
            for (integer lane = 0; lane < 2; lane = lane + 1) begin
                // S1：先零扩为signed9位再作差，范围±255，不能用8位相减。
                for (integer line = 0; line < 3; line = line + 1) begin
                    row_difference_s1[lane][line] <=
                        $signed({1'b0, in_window_pair[lane*72+line*24+16 +: 8]})
                        - $signed({1'b0, in_window_pair[lane*72+line*24 +: 8]});
                    column_difference_s1[lane][line] <=
                        $signed({1'b0, in_window_pair[lane*72+48+line*8 +: 8]})
                        - $signed({1'b0, in_window_pair[lane*72+line*8 +: 8]});
                end
                support_x_s2[lane] <= majority_support(row_difference_s1[lane][0],
                    row_difference_s1[lane][1], row_difference_s1[lane][2]);
                support_y_s2[lane] <= majority_support(column_difference_s1[lane][0],
                    column_difference_s1[lane][1], column_difference_s1[lane][2]);
                support_x_s3[lane] <= support_x_s2[lane];
                support_y_s3[lane] <= support_y_s2[lane];
                // S2/S3：同一窗口的三行或三列全部达到较低差值门槛。
                weak_x_s2[lane] <= unanimous_support(row_difference_s1[lane][0],
                    row_difference_s1[lane][1], row_difference_s1[lane][2]);
                weak_y_s2[lane] <= unanimous_support(column_difference_s1[lane][0],
                    column_difference_s1[lane][1], column_difference_s1[lane][2]);
                weak_x_s3[lane] <= weak_x_s2[lane];
                weak_y_s3[lane] <= weak_y_s2[lane];
                diagonal_x_s2[lane]<=diagonal_majority(row_difference_s1[lane][0],
                    row_difference_s1[lane][1],row_difference_s1[lane][2]);
                diagonal_y_s2[lane]<=diagonal_majority(column_difference_s1[lane][0],
                    column_difference_s1[lane][1],column_difference_s1[lane][2]);
                diagonal_x_s3[lane]<=diagonal_x_s2[lane];
                diagonal_y_s3[lane]<=diagonal_y_s2[lane];
                diagonal_s4[lane]<=in_diagonal_band(signed_gradient_x[lane],signed_gradient_y[lane])
                    &&direction_supported(signed_gradient_x[lane],diagonal_x_s3[lane])
                    &&direction_supported(signed_gradient_y[lane],diagonal_y_s3[lane]);
                diagonal_s5[lane]<=diagonal_s4[lane];
                // S4：主梯度方向需与多数支持同号；幅值相等时两方向对称处理。
                coherence_s4[lane] <=
                    ((absolute_gradient11(signed_gradient_x[lane]) >= absolute_gradient11(signed_gradient_y[lane]))
                        && direction_supported(signed_gradient_x[lane], support_x_s3[lane]))
                    || ((absolute_gradient11(signed_gradient_y[lane]) >= absolute_gradient11(signed_gradient_x[lane]))
                        && direction_supported(signed_gradient_y[lane], support_y_s3[lane]));
                coherence_s5[lane] <= coherence_s4[lane];
                weak_coherence_s4[lane] <=
                    ((absolute_gradient11(signed_gradient_x[lane]) >= absolute_gradient11(signed_gradient_y[lane]))
                        && direction_supported(signed_gradient_x[lane], weak_x_s3[lane]))
                    || ((absolute_gradient11(signed_gradient_y[lane]) >= absolute_gradient11(signed_gradient_x[lane]))
                        && direction_supported(signed_gradient_y[lane], weak_y_s3[lane]));
                weak_coherence_s5[lane] <= weak_coherence_s4[lane];
                // S1：先扩9bit；a,b,c/d,e,f/g,h,i分别是0…8字节。
                corner_sums_s1[lane][0] <= {1'b0, in_window_pair[lane*72+16 +: 8]}
                    + {1'b0, in_window_pair[lane*72+64 +: 8]};
                corner_sums_s1[lane][1] <= {1'b0, in_window_pair[lane*72 +: 8]}
                    + {1'b0, in_window_pair[lane*72+48 +: 8]};
                corner_sums_s1[lane][2] <= {1'b0, in_window_pair[lane*72+48 +: 8]}
                    + {1'b0, in_window_pair[lane*72+64 +: 8]};
                corner_sums_s1[lane][3] <= {1'b0, in_window_pair[lane*72 +: 8]}
                    + {1'b0, in_window_pair[lane*72+16 +: 8]};
                middle_twice_s1[lane][0] <= {in_window_pair[lane*72+40 +: 8], 1'b0};
                middle_twice_s1[lane][1] <= {in_window_pair[lane*72+24 +: 8], 1'b0};
                middle_twice_s1[lane][2] <= {in_window_pair[lane*72+56 +: 8], 1'b0};
                middle_twice_s1[lane][3] <= {in_window_pair[lane*72+8 +: 8], 1'b0};
                // S2：各侧扩10bit再相加，0…1020。
                for (integer side = 0; side < 4; side = side + 1)
                    side_sums[lane][side] <= {1'b0, corner_sums_s1[lane][side]}
                        + {1'b0, middle_twice_s1[lane][side]};
                // S3：零扩11bit后转signed，不能把10bit的正1020解释为负数。
                signed_gradient_x[lane] <= $signed({1'b0, side_sums[lane][0]})
                    - $signed({1'b0, side_sums[lane][1]});
                signed_gradient_y[lane] <= $signed({1'b0, side_sums[lane][2]})
                    - $signed({1'b0, side_sums[lane][3]});
                // S4和S5：绝对值10bit，求和前扩11bit，联合上界1530。
                absolute_x_s4[lane] <= absolute_gradient11(signed_gradient_x[lane]);
                absolute_y_s4[lane] <= absolute_gradient11(signed_gradient_y[lane]);
                l1_magnitude[lane] <= {1'b0, absolute_x_s4[lane]}
                    + {1'b0, absolute_y_s4[lane]};
                gradient_delay_x[0][lane] <= signed_gradient_x[lane];
                gradient_delay_y[0][lane] <= signed_gradient_y[lane];
                gradient_delay_x[1][lane] <= gradient_delay_x[0][lane];
                gradient_delay_y[1][lane] <= gradient_delay_y[0][lane];
                gradient_delay_x[2][lane] <= gradient_delay_x[1][lane];
                gradient_delay_y[2][lane] <= gradient_delay_y[1][lane];
                // S6：严格大于；F0的kind/threshold整job快照稳定。
                out_l1_pair[lane*11 +: 11] <= l1_magnitude[lane];
                out_edge[lane] <= threshold_compare[lane];
            end
        end
    end
    // synthesis translate_off
    initial if(DIAGONAL_ENABLE!=0&&(DIAGONAL_MIN_DIFF!=18&&DIAGONAL_MIN_DIFF!=19))
        $fatal(1,"sobel_pair: v4.1 supports diagonal D18 or D19");
    initial if (COHERENCE_ENABLE != 0 &&
        COHERENCE_MIN_DIFF != 16 && COHERENCE_MIN_DIFF != 20)
        $fatal(1, "sobel_pair: v2 supports D=16 or D=20");
    initial if (WEAK_ENABLE != 0 && ((COHERENCE_ENABLE == 0) || (COHERENCE_MIN_DIFF != 20)
        || !((WEAK_MIN_DIFF == 16 && WEAK_THRESHOLD_DROP == 8)
            || (WEAK_MIN_DIFF == 18 && WEAK_THRESHOLD_DROP == 0))))
        $fatal(1, "sobel_pair: v3 requires base D20 and approved weak candidate A or B");
    // synthesis translate_on
endmodule
