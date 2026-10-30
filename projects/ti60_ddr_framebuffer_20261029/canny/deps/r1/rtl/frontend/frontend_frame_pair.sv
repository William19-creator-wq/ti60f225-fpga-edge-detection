// FE-01…08；OP-01。单job身份/配置不变，局部OK只证明本核完整交付。
module cny_frontend_frame_pair #(parameter integer W = 1920, parameter integer H = 1080, parameter integer MEDIAN_ONLY=0) (
    input wire clk, input wire rst,
    input wire job_valid, output wire job_ready,
    input wire [31:0] job_epoch, job_frame_id, job_config_id,
    input wire job_median_enable, input wire [1:0] job_output_kind,
    input wire [10:0] job_threshold,
    input wire in_valid, output wire in_ready, input wire [47:0] in_rgb,
    input wire [10:0] in_x_even, in_y,
    input wire in_sof, in_eol, in_eof, in_bad,
    output wire out_valid, input wire out_ready, output wire [15:0] out_y_filtered,
    output wire [1:0] out_edge, output wire [10:0] out_x_even, out_y,
    output wire out_sof, out_eol, out_eof,
    output wire [31:0] out_epoch, out_frame_id, out_config_id,
    input wire cancel,
    output wire status_valid, input wire status_ready, output reg [2:0] status_code,
    output wire [31:0] status_epoch, status_frame_id, status_config_id,
    output wire [20:0] status_in_pairs, status_out_pairs,
    output reg [10:0] status_error_x, status_error_y
);
    localparam [1:0] IDLE=0, ACTIVE=1, FLUSH_TAIL=2, STATUS=3;
    localparam [20:0] N = (W/2)*H;
    localparam [9:0] LAST_Q = W/2 - 1;
    localparam [10:0] LAST_ROW = H - 1;
    reg [1:0] job_state;
    reg [31:0] epoch_locked, frame_locked, config_locked;
    reg median_locked; reg [1:0] kind_locked; reg [10:0] threshold_locked;
    reg [9:0] input_expected_q;
    reg [10:0] input_expected_row;
    reg [20:0] accepted_pairs, delivered_pairs;
    wire running = job_state == ACTIVE || job_state == FLUSH_TAIL;
    wire job_fire = job_valid && job_ready;
    wire frame_start = job_fire && job_output_kind < 2;
    wire cancel_active = !rst && running && cancel;
    wire gray_ready;
    assign job_ready = !rst && job_state == IDLE;
    assign in_ready = !rst && job_state == ACTIVE && !cancel && gray_ready;
    wire input_fire = in_valid && in_ready;
    wire bad_coordinates = in_x_even != {input_expected_q,1'b0} || in_y != input_expected_row;
    wire bad_markers = in_sof != (input_expected_q == 0 && input_expected_row == 0) ||
                       in_eol != (input_expected_q == LAST_Q) ||
                       in_eof != (input_expected_q == LAST_Q && input_expected_row == LAST_ROW);
    wire input_invalid = in_bad || bad_coordinates || bad_markers;
    wire input_error = input_fire && input_invalid;
    // input_error不能组合关gray_ready；坏组只从数值路径阻断，实际接纳仍计数。
    wire flush = cancel_active || input_error;
    wire gray_valid, win1_valid, median_valid, win2_valid, sobel_valid;
    wire win1_ready, median_ready, win2_ready, sobel_ready;
    wire gray_empty, win1_empty, median_empty, win2_empty, sobel_empty;
    wire [15:0] gray_pair, median_pair;
    wire [143:0] window1_pair, window2_pair;
    wire [10:0] gx0, gy0, wx1, wy1, mx, my, wx2, wy2;
    wire gs, gl, ge, w1s, w1l, w1e, ms, ml, me, w2s, w2l, w2e;
    wire [21:0] unused_gx, unused_gy, unused_l1;
    cny_rgb_to_y_pair gray (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .in_valid(!rst && job_state == ACTIVE && in_valid && !cancel && !input_invalid),
        .in_ready(gray_ready), .in_rgb(in_rgb), .in_x_even(in_x_even), .in_y(in_y),
        .in_sof(in_sof), .in_eol(in_eol), .in_eof(in_eof),
        .out_valid(gray_valid), .out_ready(win1_ready), .out_y_pair(gray_pair),
        .out_x_even(gx0), .out_y(gy0), .out_sof(gs), .out_eol(gl), .out_eof(ge), .empty(gray_empty)
    );
    cny_window3x3_pair #(.W(W),.H(H)) window_before_median (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .in_valid(gray_valid), .in_ready(win1_ready), .in_y_pair(gray_pair),
        .in_x_even(gx0), .in_y(gy0), .in_sof(gs), .in_eol(gl), .in_eof(ge),
        .out_valid(win1_valid), .out_ready(median_ready), .out_window_pair(window1_pair),
        .out_x_even(wx1), .out_y(wy1), .out_sof(w1s), .out_eol(w1l), .out_eof(w1e), .empty(win1_empty)
    );
    cny_median9_pair median (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .median_enable(median_locked), .in_valid(win1_valid), .in_ready(median_ready),
        .in_window_pair(window1_pair), .in_x_even(wx1), .in_y(wy1),
        .in_sof(w1s), .in_eol(w1l), .in_eof(w1e),
        .out_valid(median_valid), .out_ready(win2_ready), .out_y_pair(median_pair),
        .out_x_even(mx), .out_y(my), .out_sof(ms), .out_eol(ml), .out_eof(me), .empty(median_empty)
    );
    // Canny consumes the grayscale/median stream before its own Gaussian and
    // gradient stage. Do not build a redundant Sobel window just to return its
    // unchanged center pixel. Default keeps the standalone frontend contract.
    generate if(MEDIAN_ONLY)begin:median_output
        assign win2_ready=out_ready&&running;
        assign sobel_valid=median_valid;
        assign out_y_filtered=median_pair;assign out_edge=0;
        assign out_x_even=mx;assign out_y=my;assign out_sof=ms;assign out_eol=ml;assign out_eof=me;
        assign win2_empty=1'b1;assign sobel_empty=1'b1;
    end else begin:with_sobel
    cny_window3x3_pair #(.W(W),.H(H)) window_before_sobel (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .in_valid(median_valid), .in_ready(win2_ready), .in_y_pair(median_pair),
        .in_x_even(mx), .in_y(my), .in_sof(ms), .in_eol(ml), .in_eof(me),
        .out_valid(win2_valid), .out_ready(sobel_ready), .out_window_pair(window2_pair),
        .out_x_even(wx2), .out_y(wy2), .out_sof(w2s), .out_eol(w2l), .out_eof(w2e), .empty(win2_empty)
    );
    cny_sobel_pair sobel (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .output_kind(kind_locked), .threshold(threshold_locked),
        .in_valid(win2_valid), .in_ready(sobel_ready), .in_window_pair(window2_pair),
        .in_x_even(wx2), .in_y(wy2), .in_sof(w2s), .in_eol(w2l), .in_eof(w2e),
        .out_valid(sobel_valid), .out_ready(out_ready && running),
        .out_y_pair(out_y_filtered), .out_edge(out_edge),
        .out_gx_pair(unused_gx), .out_gy_pair(unused_gy), .out_l1_pair(unused_l1),
        .out_x_even(out_x_even), .out_y(out_y),
        .out_sof(out_sof), .out_eol(out_eol), .out_eof(out_eof), .empty(sobel_empty)
    );
    end endgenerate
    assign out_valid = !rst && running && sobel_valid;
    wire output_fire = out_valid && out_ready;
    assign out_epoch = epoch_locked; assign out_frame_id = frame_locked; assign out_config_id = config_locked;
    assign status_valid = !rst && job_state == STATUS;
    assign status_epoch = epoch_locked; assign status_frame_id = frame_locked; assign status_config_id = config_locked;
    assign status_in_pairs = accepted_pairs; assign status_out_pairs = delivered_pairs;
    wire all_empty = gray_empty && win1_empty && median_empty && win2_empty && sobel_empty;
    always @(posedge clk) begin
        if (rst) begin
            job_state <= IDLE;
            epoch_locked <= 0; frame_locked <= 0; config_locked <= 0;
            median_locked <= 0; kind_locked <= 0; threshold_locked <= 0;
            input_expected_q <= 0; input_expected_row <= 0;
            accepted_pairs <= 0; delivered_pairs <= 0;
            status_code <= 0; status_error_x <= 0; status_error_y <= 0;
        end else begin
            if (input_fire) accepted_pairs <= accepted_pairs + 21'd1;
            if (output_fire) delivered_pairs <= delivered_pairs + 21'd1;
            if (cancel_active) begin
                status_code <= 3'd1; status_error_x <= 0; status_error_y <= 0; job_state <= STATUS;
            end else if (input_error) begin
                status_code <= in_bad ? 3'd2 : bad_coordinates ? 3'd3 : 3'd4;
                status_error_x <= in_x_even; status_error_y <= in_y; job_state <= STATUS;
            end else case (job_state)
                IDLE: if (job_fire) begin
                    epoch_locked <= job_epoch; frame_locked <= job_frame_id; config_locked <= job_config_id;
                    median_locked <= job_median_enable; kind_locked <= job_output_kind; threshold_locked <= job_threshold;
                    accepted_pairs <= 0; delivered_pairs <= 0;
                    input_expected_q <= 0; input_expected_row <= 0;
                    status_error_x <= 0; status_error_y <= 0;
                    if (job_output_kind >= 2) begin status_code <= 3'd5; job_state <= STATUS; end
                    else job_state <= ACTIVE;
                end
                ACTIVE: if (input_fire) begin
                    if (input_expected_q == LAST_Q) begin
                        input_expected_q <= 0;
                        if (input_expected_row == LAST_ROW) job_state <= FLUSH_TAIL;
                        else input_expected_row <= input_expected_row + 11'd1;
                    end else input_expected_q <= input_expected_q + 10'd1;
                end
                FLUSH_TAIL: if (all_empty) begin
                    status_code <= accepted_pairs == N && delivered_pairs == N ? 3'd0 : 3'd6;
                    status_error_x <= 0; status_error_y <= 0; job_state <= STATUS;
                end
                STATUS: if (status_ready) job_state <= IDLE;
                default: job_state <= IDLE;
            endcase
        end
    end
    // synthesis translate_off
    initial if (W < 4 || W > 1920 || W % 2 != 0 || H < 3 || H > 1080)
        $fatal(1, "cny_frontend_frame_pair: illegal dimensions");
    // synthesis translate_on
endmodule
