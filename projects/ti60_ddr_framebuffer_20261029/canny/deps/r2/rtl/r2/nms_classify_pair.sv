// SI-REQ02 / E4 / U-NC：两级NMS，负侧严格大于、正侧允许相等。
module nms_classify_pair #(
    parameter integer W=1920, H=1080
) (
    input wire clk, rst, frame_start, data_flush,
    input wire in_valid, output wire in_ready,
    input wire [287:0] in_window_pair,
    input wire [10:0] threshold_low, threshold_high,
    input wire [10:0] in_x_even, in_y,
    input wire in_sof, in_eol, in_eof,
    output wire out_valid, input wire out_ready,
    output wire [3:0] out_class_pair,
    output wire [10:0] out_x_even, out_y,
    output wire out_sof, out_eol, out_eof,
    output wire empty
);
    logic [1:0] valid_pipe;
    logic [24:0] coordinate_s1, coordinate_s2;
    logic [10:0] center_s1 [0:1], negative_s1 [0:1], positive_s1 [0:1];
    logic [1:0] outer_s1;
    logic [10:0] low_s1, high_s1;
    logic [3:0] classes_s2;
    logic [10:0] negative_input [0:1], positive_input [0:1];
    wire advance = !valid_pipe[1] || out_ready;
    assign in_ready = !rst && advance;
    assign out_valid = !rst && valid_pipe[1];
    assign out_class_pair = classes_s2;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even} = coordinate_s2;
    assign empty = !(|valid_pipe);

    always_comb begin : select_neighbors
        for (integer lane=0; lane<2; lane=lane+1) begin
            // 每窗a…i为9个16bit容器；仅中心e的dir参与方向选择。
            case (in_window_pair[lane*144+75 +: 2])
                2'b00: begin
                    negative_input[lane] = in_window_pair[lane*144+48 +: 11];
                    positive_input[lane] = in_window_pair[lane*144+80 +: 11];
                end
                2'b01: begin
                    negative_input[lane] = in_window_pair[lane*144 +: 11];
                    positive_input[lane] = in_window_pair[lane*144+128 +: 11];
                end
                2'b10: begin
                    negative_input[lane] = in_window_pair[lane*144+16 +: 11];
                    positive_input[lane] = in_window_pair[lane*144+112 +: 11];
                end
                default: begin
                    negative_input[lane] = in_window_pair[lane*144+96 +: 11];
                    positive_input[lane] = in_window_pair[lane*144+32 +: 11];
                end
            endcase
        end
    end
    always_ff @(posedge clk) begin : classify_pipeline
        if (rst || frame_start || data_flush) begin
            valid_pipe <= 2'b0;
        end else if (advance) begin
            valid_pipe <= {valid_pipe[0],in_valid};
            coordinate_s1 <= {in_eof,in_eol,in_sof,in_y,in_x_even};
            coordinate_s2 <= coordinate_s1;
            low_s1 <= threshold_low;
            high_s1 <= threshold_high;
            for (integer lane=0; lane<2; lane=lane+1) begin
                center_s1[lane] <= in_window_pair[lane*144+64 +: 11];
                negative_s1[lane] <= negative_input[lane];
                positive_s1[lane] <= positive_input[lane];
                outer_s1[lane] <= ({1'b0,in_x_even}+lane == 0)
                    || ({1'b0,in_x_even}+lane == W-1) || in_y == 0 || in_y == H-1;
                if (outer_s1[lane] || center_s1[lane] == 0
                    || center_s1[lane] <= negative_s1[lane]
                    || center_s1[lane] < positive_s1[lane])
                    classes_s2[lane*2 +: 2] <= 2'b00;
                else if (center_s1[lane] > high_s1)
                    classes_s2[lane*2 +: 2] <= 2'b10;
                else if (center_s1[lane] > low_s1)
                    classes_s2[lane*2 +: 2] <= 2'b01;
                else classes_s2[lane*2 +: 2] <= 2'b00;
            end
        end
    end
endmodule
