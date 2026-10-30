// FE-03 / OP-06：每lane 19比较器，九级；旁路中心保持相同延迟。
module median9_pair (
    input  wire         clk,
    input  wire         rst,
    input  wire         frame_start,
    input  wire         flush,
    input  wire         in_valid,
    output wire         in_ready,
    input  wire [143:0] in_window_pair,
    input  wire         median_enable,
    input  wire [10:0]  in_x_even,
    input  wire [10:0]  in_y,
    input  wire         in_sof,
    input  wire         in_eol,
    input  wire         in_eof,
    output wire         out_valid,
    input  wire         out_ready,
    output logic [15:0] out_y_pair,
    output wire [10:0]  out_x_even,
    output wire [10:0]  out_y,
    output wire         out_sof,
    output wire         out_eol,
    output wire         out_eof,
    output wire         empty
);
    logic [8:0] valid_pipe;
    logic [24:0] coordinate_pipe [0:8];
    logic [15:0] center_bypass [0:7];
    logic [7:0] row_first_s1 [0:1][0:8];
    logic [7:0] row_second_s2 [0:1][0:8];
    logic [7:0] row_order [0:1][0:8];
    logic [7:0] candidates_s4 [0:1][0:6];
    logic [7:0] candidates_s5 [0:1][0:3];
    logic [7:0] median_candidates [0:1][0:2];
    logic [7:0] candidates_s7 [0:1][0:2];
    logic [7:0] candidates_s8 [0:1][0:1];

    // 每个16bit比较结果是{max,min}，min/max共用一次比较。
    logic [15:0] row_first_compare [0:1][0:2];
    logic [15:0] row_second_compare [0:1][0:2];
    logic [15:0] row_finish_compare [0:1][0:2];
    logic [15:0] low_compare_s4 [0:1];
    logic [15:0] high_compare_s4 [0:1];
    logic [15:0] middle_compare_s4 [0:1];
    logic [15:0] low_compare_s5 [0:1];
    logic [15:0] high_compare_s5 [0:1];
    logic [15:0] middle_compare_s5 [0:1];
    logic [15:0] middle_compare_s6 [0:1];
    logic [15:0] compare_s7 [0:1];
    logic [15:0] compare_s8 [0:1];
    logic [15:0] compare_s9 [0:1];
    wire pipeline_advance = !valid_pipe[8] || out_ready;

    function automatic [15:0] compare_unsigned8 (
        input logic [7:0] left_value,
        input logic [7:0] right_value
    );
        begin
            if (left_value <= right_value)
                compare_unsigned8 = {right_value, left_value};
            else
                compare_unsigned8 = {left_value, right_value};
        end
    endfunction

    assign in_ready = !rst && pipeline_advance;
    assign out_valid = !rst && valid_pipe[8];
    assign empty = !(|valid_pipe);
    assign {out_eof, out_eol, out_sof, out_y, out_x_even} = coordinate_pipe[8];

    always_comb begin : median_comparisons
        for (integer lane = 0; lane < 2; lane = lane + 1) begin
            for (integer row = 0; row < 3; row = row + 1) begin
                row_first_compare[lane][row] = compare_unsigned8(
                    in_window_pair[lane*72+row*24 +: 8],
                    in_window_pair[lane*72+row*24+8 +: 8]);
                row_second_compare[lane][row] = compare_unsigned8(
                    row_first_s1[lane][row*3+1], row_first_s1[lane][row*3+2]);
                row_finish_compare[lane][row] = compare_unsigned8(
                    row_second_s2[lane][row*3], row_second_s2[lane][row*3+1]);
            end
            low_compare_s4[lane] = compare_unsigned8(row_order[lane][0], row_order[lane][3]);
            high_compare_s4[lane] = compare_unsigned8(row_order[lane][2], row_order[lane][5]);
            middle_compare_s4[lane] = compare_unsigned8(row_order[lane][1], row_order[lane][4]);
            low_compare_s5[lane] = compare_unsigned8(candidates_s4[lane][0], candidates_s4[lane][1]);
            high_compare_s5[lane] = compare_unsigned8(candidates_s4[lane][2], candidates_s4[lane][3]);
            middle_compare_s5[lane] = compare_unsigned8(candidates_s4[lane][5], candidates_s4[lane][6]);
            middle_compare_s6[lane] = compare_unsigned8(candidates_s5[lane][3], candidates_s5[lane][2]);
            compare_s7[lane] = compare_unsigned8(median_candidates[lane][0], median_candidates[lane][1]);
            compare_s8[lane] = compare_unsigned8(candidates_s7[lane][1], candidates_s7[lane][2]);
            compare_s9[lane] = compare_unsigned8(candidates_s8[lane][0], candidates_s8[lane][1]);
        end
    end

    always_ff @(posedge clk) begin : median_pipeline
        if (rst || flush || frame_start) begin
            valid_pipe <= 9'b0;
        end else if (pipeline_advance) begin
            valid_pipe <= {valid_pipe[7:0], in_valid};
            coordinate_pipe[0] <= {in_eof, in_eol, in_sof, in_y, in_x_even};
            for (integer stage = 1; stage < 9; stage = stage + 1)
                coordinate_pipe[stage] <= coordinate_pipe[stage-1];
            center_bypass[0] <= {in_window_pair[104 +: 8], in_window_pair[32 +: 8]};
            for (integer stage = 1; stage < 8; stage = stage + 1)
                center_bypass[stage] <= center_bypass[stage-1];

            for (integer lane = 0; lane < 2; lane = lane + 1) begin
                for (integer row = 0; row < 3; row = row + 1) begin
                    row_first_s1[lane][row*3] <= row_first_compare[lane][row][7:0];
                    row_first_s1[lane][row*3+1] <= row_first_compare[lane][row][15:8];
                    row_first_s1[lane][row*3+2] <= in_window_pair[lane*72+row*24+16 +: 8];
                    row_second_s2[lane][row*3] <= row_first_s1[lane][row*3];
                    row_second_s2[lane][row*3+1] <= row_second_compare[lane][row][7:0];
                    row_second_s2[lane][row*3+2] <= row_second_compare[lane][row][15:8];
                    row_order[lane][row*3] <= row_finish_compare[lane][row][7:0];
                    row_order[lane][row*3+1] <= row_finish_compare[lane][row][15:8];
                    row_order[lane][row*3+2] <= row_second_s2[lane][row*3+2];
                end
                // M4：L01max/L2/H01min/H2/M01min/M01max/M2。
                candidates_s4[lane][0] <= low_compare_s4[lane][15:8];
                candidates_s4[lane][1] <= row_order[lane][6];
                candidates_s4[lane][2] <= high_compare_s4[lane][7:0];
                candidates_s4[lane][3] <= row_order[lane][8];
                candidates_s4[lane][4] <= middle_compare_s4[lane][7:0];
                candidates_s4[lane][5] <= middle_compare_s4[lane][15:8];
                candidates_s4[lane][6] <= row_order[lane][7];
                // M5：A/C/min(M01max,M2)/M01min；M6组成A/B/C。
                candidates_s5[lane][0] <= low_compare_s5[lane][15:8];
                candidates_s5[lane][1] <= high_compare_s5[lane][7:0];
                candidates_s5[lane][2] <= middle_compare_s5[lane][7:0];
                candidates_s5[lane][3] <= candidates_s4[lane][4];
                median_candidates[lane][0] <= candidates_s5[lane][0];
                median_candidates[lane][1] <= middle_compare_s6[lane][15:8];
                median_candidates[lane][2] <= candidates_s5[lane][1];
                candidates_s7[lane][0] <= compare_s7[lane][7:0];
                candidates_s7[lane][1] <= compare_s7[lane][15:8];
                candidates_s7[lane][2] <= median_candidates[lane][2];
                candidates_s8[lane][0] <= candidates_s7[lane][0];
                candidates_s8[lane][1] <= compare_s8[lane][7:0];
                // F0的整job快照稳定；S9寄存选择，停顿输出不受组合配置影响。
                out_y_pair[lane*8 +: 8] <= median_enable
                    ? compare_s9[lane][15:8] : center_bypass[7][lane*8 +: 8];
            end
        end
    end
endmodule
