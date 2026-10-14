// FE-02 / OP-02：两 lane RGB888，三级灰度，单 core 时钟。
// 接口与逐步中文读回见 docs/arithmetic-implementation.md。
module rgb_to_y_pair (
    input  wire        clk,
    input  wire        rst,
    input  wire        frame_start,
    input  wire        flush,
    input  wire        in_valid,
    output wire        in_ready,
    input  wire [47:0] in_rgb,
    input  wire [10:0] in_x_even,
    input  wire [10:0] in_y,
    input  wire        in_sof,
    input  wire        in_eol,
    input  wire        in_eof,
    output wire        out_valid,
    input  wire        out_ready,
    output logic [15:0] out_y_pair,
    output wire [10:0] out_x_even,
    output wire [10:0] out_y,
    output wire        out_sof,
    output wire        out_eol,
    output wire        out_eof,
    output wire        empty
);
    logic [2:0] valid_pipe;
    logic [24:0] coordinate_pipe [0:2];
    logic [15:0] rgb_weighted_terms [0:1][0:2];
    logic [15:0] red_expanded [0:1];
    logic [15:0] green_expanded [0:1];
    logic [15:0] blue_expanded [0:1];
    logic [15:0] red_term_s1 [0:1];
    logic [15:0] green_term_s1 [0:1];
    logic [15:0] blue_term_s1 [0:1];
    logic [15:0] red_green_s2 [0:1];
    logic [15:0] blue_round_s2 [0:1];
    logic [15:0] gray_round [0:1];
    wire pipeline_advance = !valid_pipe[2] || out_ready;

    // flush不能组合取消已经触发错误的ready；只有rst屏蔽传输。
    assign in_ready = !rst && pipeline_advance;
    assign out_valid = !rst && valid_pipe[2];
    assign empty = !(|valid_pipe);
    assign {out_eof, out_eol, out_sof, out_y, out_x_even} = coordinate_pipe[2];

    always_comb begin : weighted_gray_values
        for (integer lane = 0; lane < 2; lane = lane + 1) begin
            // 所有移位在扩为16bit之后进行，最大总和含舍入为65408。
            red_expanded[lane] = {8'b0, in_rgb[lane*24+16 +: 8]};
            green_expanded[lane] = {8'b0, in_rgb[lane*24+8 +: 8]};
            blue_expanded[lane] = {8'b0, in_rgb[lane*24 +: 8]};
            rgb_weighted_terms[lane][0] = (red_expanded[lane] << 6)
                + (red_expanded[lane] << 3) + (red_expanded[lane] << 2)
                + red_expanded[lane];
            rgb_weighted_terms[lane][1] = (green_expanded[lane] << 7)
                + (green_expanded[lane] << 4) + (green_expanded[lane] << 2)
                + (green_expanded[lane] << 1);
            rgb_weighted_terms[lane][2] = (blue_expanded[lane] << 4)
                + (blue_expanded[lane] << 3) + (blue_expanded[lane] << 2)
                + blue_expanded[lane];
            gray_round[lane] = red_green_s2[lane] + blue_round_s2[lane];
        end
    end

    always_ff @(posedge clk) begin : gray_pipeline
        // 数据不必清零；valid清空隔离旧job，优先级独立于反压。
        if (rst || flush || frame_start) begin
            valid_pipe <= 3'b0;
        end else if (pipeline_advance) begin
            valid_pipe <= {valid_pipe[1:0], in_valid};
            coordinate_pipe[0] <= {in_eof, in_eol, in_sof, in_y, in_x_even};
            coordinate_pipe[1] <= coordinate_pipe[0];
            coordinate_pipe[2] <= coordinate_pipe[1];
            for (integer lane = 0; lane < 2; lane = lane + 1) begin
                red_term_s1[lane] <= rgb_weighted_terms[lane][0];
                green_term_s1[lane] <= rgb_weighted_terms[lane][1];
                blue_term_s1[lane] <= rgb_weighted_terms[lane][2];
                red_green_s2[lane] <= red_term_s1[lane] + green_term_s1[lane];
                blue_round_s2[lane] <= blue_term_s1[lane] + 16'd128;
                out_y_pair[lane*8 +: 8] <= gray_round[lane][15:8];
            end
        end
    end
endmodule
