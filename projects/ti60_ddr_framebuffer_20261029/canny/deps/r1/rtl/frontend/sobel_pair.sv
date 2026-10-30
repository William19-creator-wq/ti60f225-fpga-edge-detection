// FE-04 / OP-07：六级Sobel；中心、梯度诊断及edge共用一次输出握手。
module cny_sobel_pair (
    input  wire         clk,
    input  wire         rst,
    input  wire         frame_start,
    input  wire         flush,
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [143:0] in_window_pair,
    input  wire [1:0]   output_kind,
    input  wire [10:0]  threshold,
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
    // S1 differences [-255,255] are shared with directional support.
    // S2 holds two signed [-510,510] terms per axis. S3 sums to
    // [-1020,1020]. Six advances, metadata and stall behavior are unchanged.
    logic signed [9:0] gradient_terms_s2 [0:1][0:3];
    logic signed [8:0] row_difference_s1 [0:1][0:2];
    logic signed [8:0] column_difference_s1 [0:1][0:2];
    logic signed [10:0] signed_gradient_x [0:1];
    logic signed [10:0] signed_gradient_y [0:1];
    logic [9:0] absolute_x_s4 [0:1];
    logic [9:0] absolute_y_s4 [0:1];
    logic [10:0] l1_magnitude [0:1];
    logic signed [10:0] gradient_delay_x [0:2][0:1];
    logic signed [10:0] gradient_delay_y [0:2][0:1];
    wire [1:0] threshold_compare;
    wire pipeline_advance = !valid_pipe[5] || out_ready;

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
    assign threshold_compare[0] = (output_kind == 2'd1) && (l1_magnitude[0] > threshold);
    assign threshold_compare[1] = (output_kind == 2'd1) && (l1_magnitude[1] > threshold);

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
                for (integer line=0;line<3;line=line+1) begin
                    row_difference_s1[lane][line] <=
                        $signed({1'b0,in_window_pair[lane*72+line*24+16 +: 8]})
                        - $signed({1'b0,in_window_pair[lane*72+line*24 +: 8]});
                    column_difference_s1[lane][line] <=
                        $signed({1'b0,in_window_pair[lane*72+48+line*8 +: 8]})
                        - $signed({1'b0,in_window_pair[lane*72+line*8 +: 8]});
                end
                gradient_terms_s2[lane][0] <=
                    $signed({row_difference_s1[lane][0][8],row_difference_s1[lane][0]})
                    + $signed({row_difference_s1[lane][2][8],row_difference_s1[lane][2]});
                gradient_terms_s2[lane][1] <= $signed({row_difference_s1[lane][1],1'b0});
                gradient_terms_s2[lane][2] <=
                    $signed({column_difference_s1[lane][0][8],column_difference_s1[lane][0]})
                    + $signed({column_difference_s1[lane][2][8],column_difference_s1[lane][2]});
                gradient_terms_s2[lane][3] <= $signed({column_difference_s1[lane][1],1'b0});
                signed_gradient_x[lane] <=
                    $signed({gradient_terms_s2[lane][0][9],gradient_terms_s2[lane][0]})
                    + $signed({gradient_terms_s2[lane][1][9],gradient_terms_s2[lane][1]});
                signed_gradient_y[lane] <=
                    $signed({gradient_terms_s2[lane][2][9],gradient_terms_s2[lane][2]})
                    + $signed({gradient_terms_s2[lane][3][9],gradient_terms_s2[lane][3]});
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
endmodule
