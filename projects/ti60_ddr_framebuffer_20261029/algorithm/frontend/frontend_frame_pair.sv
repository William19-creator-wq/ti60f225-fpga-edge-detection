// FE-01…08；OP-01。单job身份/配置不变，局部OK只证明本核完整交付。
module frontend_frame_pair #(
    parameter integer W = 1920, parameter integer H = 1080,
    parameter integer MEDIAN_DETAIL_ENABLE = 0,
    parameter integer RUNTIME_FILTER_CONFIG = 0, RUNTIME_EDGE_CONFIG = 0,
    parameter integer MEDIAN_DETAIL_DIFF = 16, MEDIAN_DETAIL_SIMILARITY = 4,
    parameter integer SOBEL_COHERENCE_ENABLE = 0,
    parameter integer SOBEL_COHERENCE_MIN_DIFF = 16,
    parameter integer SOBEL_WEAK_ENABLE = 0,
    parameter integer SOBEL_WEAK_MIN_DIFF = 18,
    parameter integer SOBEL_WEAK_THRESHOLD_DROP = 0,
    parameter integer EDGE_CONTEXT_ENABLE = 0,
    parameter integer EDGE_THIN_ENABLE = 0,
    parameter integer EDGE_THIN_MODE = 1,
    parameter integer EDGE_CONTEXT_THRESHOLD_DROP = 16,
    parameter integer DIAGONAL_ENABLE = 0,
    parameter integer DIAGONAL_MIN_DIFF = 19
) (
    input wire clk, input wire rst,
    input wire job_valid, output wire job_ready,
    input wire [31:0] job_epoch, job_frame_id, job_config_id,
    input wire job_median_enable, input wire [1:0] job_output_kind,
    input wire job_detail_enable, job_edge_enhance,
    input wire [10:0] job_threshold,
    input wire in_valid, output wire in_ready, input wire [47:0] in_rgb,
    input wire [10:0] in_x_even, in_y,
    input wire in_sof, in_eol, in_eof, in_bad,
    output wire out_valid, input wire out_ready, output wire [15:0] out_y_filtered,
    output wire [1:0] out_edge, output wire [10:0] out_x_even, out_y,
    output wire out_sof, out_eol, out_eof,
    output wire [31:0] out_epoch, out_frame_id, out_config_id,
    input wire cancel,
    // 整机独占式复用：Canny灰度前端直接交付中值结果，随后借用同一窗口/Sobel。
    input wire external_sobel_owner,external_sobel_start,external_sobel_flush,external_sobel_open,
    input wire external_sobel_in_valid,output wire external_sobel_in_ready,
    input wire [40:0] external_sobel_input,
    output wire external_sobel_out_valid,input wire external_sobel_out_ready,
    output wire [108:0] external_sobel_output,output wire external_sobel_empty,
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
    reg median_locked,detail_locked,enhance_locked; reg [1:0] kind_locked; reg [10:0] threshold_locked;
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
    wire [15:0] sobel_center;
    wire [1:0] sobel_edge;
    wire [24:0] sobel_coordinate;
    wire gray_output=external_sobel_owner||kind_locked==0;
    // Runtime choice is immutable for this job; both paths retain coordinates.
    wire enhance_active=!RUNTIME_EDGE_CONFIG||enhance_locked;
    wire context_active=(EDGE_CONTEXT_ENABLE!=0)&&!gray_output&&enhance_active;
    wire context_input_ready,context_valid,context_empty;
    wire [15:0] context_center;
    wire [1:0] context_edge;
    wire [24:0] context_coordinate;
    // 两个输出槽的输入ready只取已登记占用数，切断共享Sobel/高斯的ready环。
    // 帧身份仍由本job持有；槽内保存两个像素及其全部坐标、marker和edge。
    reg [42:0] output_slots [0:1];
    reg output_write_slot,output_read_slot;
    reg [1:0] output_count;
    wire output_slot_ready=output_count!=2;
    wire output_slot_valid=!rst&&running&&(gray_output?median_valid:(context_active?context_valid:sobel_valid));
    wire [42:0] output_slot_data=gray_output?
        {me,ml,ms,my,mx,2'b0,median_pair}:
        (context_active?{context_coordinate,context_edge,context_center}:{sobel_coordinate,sobel_edge,sobel_center});
    wire output_slot_push=output_slot_valid&&output_slot_ready;
    wire [40:0] shared_input=external_sobel_owner?external_sobel_input:{me,ml,ms,my,mx,median_pair};
    wire shared_start=external_sobel_owner?external_sobel_start:frame_start;
    wire shared_flush=external_sobel_owner?external_sobel_flush:flush;
    wire shared_open=!external_sobel_owner||external_sobel_open;
    wire window_input_ready;
    assign win2_ready=gray_output?(output_slot_ready&&running):window_input_ready;
    assign external_sobel_in_ready=external_sobel_owner&&window_input_ready;
    rgb_to_y_pair gray (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .in_valid(!rst && job_state == ACTIVE && in_valid && !cancel && !input_invalid),
        .in_ready(gray_ready), .in_rgb(in_rgb), .in_x_even(in_x_even), .in_y(in_y),
        .in_sof(in_sof), .in_eol(in_eol), .in_eof(in_eof),
        .out_valid(gray_valid), .out_ready(win1_ready), .out_y_pair(gray_pair),
        .out_x_even(gx0), .out_y(gy0), .out_sof(gs), .out_eol(gl), .out_eof(ge), .empty(gray_empty)
    );
    window3x3_pair #(.W(W),.H(H)) window_before_median (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .in_valid(gray_valid), .in_ready(win1_ready), .in_y_pair(gray_pair),
        .in_x_even(gx0), .in_y(gy0), .in_sof(gs), .in_eol(gl), .in_eof(ge),
        .out_valid(win1_valid), .out_ready(median_ready), .out_window_pair(window1_pair),
        .out_x_even(wx1), .out_y(wy1), .out_sof(w1s), .out_eol(w1l), .out_eof(w1e), .empty(win1_empty)
    );
    generate if(MEDIAN_DETAIL_ENABLE!=0)begin : detail_median
        median9_detail_pair #(.W(W),.H(H),.D(MEDIAN_DETAIL_DIFF),.S(MEDIAN_DETAIL_SIMILARITY)) median (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .detail_enable(!external_sobel_owner&&(!RUNTIME_FILTER_CONFIG||detail_locked)),.median_enable(median_locked), .in_valid(win1_valid), .in_ready(median_ready),
        .in_window_pair(window1_pair), .in_x_even(wx1), .in_y(wy1),
        .in_sof(w1s), .in_eol(w1l), .in_eof(w1e),
        .out_valid(median_valid), .out_ready(win2_ready), .out_y_pair(median_pair),
        .out_x_even(mx), .out_y(my), .out_sof(ms), .out_eol(ml), .out_eof(me), .empty(median_empty)
    );
    end else begin : ordinary_median
    median9_pair median (
        .clk(clk), .rst(rst), .frame_start(frame_start), .flush(flush),
        .median_enable(median_locked), .in_valid(win1_valid), .in_ready(median_ready),
        .in_window_pair(window1_pair), .in_x_even(wx1), .in_y(wy1),
        .in_sof(w1s), .in_eol(w1l), .in_eof(w1e),
        .out_valid(median_valid), .out_ready(win2_ready), .out_y_pair(median_pair),
        .out_x_even(mx), .out_y(my), .out_sof(ms), .out_eol(ml), .out_eof(me), .empty(median_empty)
    );
    end endgenerate
    window3x3_pair #(.W(W),.H(H)) window_before_sobel (
        .clk(clk), .rst(rst), .frame_start(shared_start), .flush(shared_flush),
        .in_valid(external_sobel_owner?external_sobel_in_valid:(median_valid&&!gray_output)),
        .in_ready(window_input_ready), .in_y_pair(shared_input[15:0]),
        .in_x_even(shared_input[26:16]), .in_y(shared_input[37:27]),
        .in_sof(shared_input[38]), .in_eol(shared_input[39]), .in_eof(shared_input[40]),
        .out_valid(win2_valid), .out_ready(sobel_ready&&shared_open), .out_window_pair(window2_pair),
        .out_x_even(wx2), .out_y(wy2), .out_sof(w2s), .out_eol(w2l), .out_eof(w2e), .empty(win2_empty)
    );
    sobel_pair #(.RUNTIME_EDGE_CONFIG(RUNTIME_EDGE_CONFIG),.COHERENCE_ENABLE(SOBEL_COHERENCE_ENABLE),
        .COHERENCE_MIN_DIFF(SOBEL_COHERENCE_MIN_DIFF),
        .WEAK_ENABLE(SOBEL_WEAK_ENABLE),.WEAK_MIN_DIFF(SOBEL_WEAK_MIN_DIFF),
        .WEAK_THRESHOLD_DROP(SOBEL_WEAK_THRESHOLD_DROP),
        .DIAGONAL_ENABLE(DIAGONAL_ENABLE),.DIAGONAL_MIN_DIFF(DIAGONAL_MIN_DIFF)) sobel (
        .clk(clk), .rst(rst), .frame_start(shared_start), .flush(shared_flush),
        .enhance_enable(!external_sobel_owner&&enhance_active),
        .output_kind(external_sobel_owner?2'd1:kind_locked), .threshold(external_sobel_owner?11'd0:threshold_locked),
        .in_valid(win2_valid&&shared_open), .in_ready(sobel_ready), .in_window_pair(window2_pair),
        .in_x_even(wx2), .in_y(wy2), .in_sof(w2s), .in_eol(w2l), .in_eof(w2e),
        .out_valid(sobel_valid), .out_ready(external_sobel_owner?external_sobel_out_ready:
            ((context_active?context_input_ready:output_slot_ready)&&running)),
        .out_y_pair(sobel_center), .out_edge(sobel_edge),
        .out_gx_pair(unused_gx), .out_gy_pair(unused_gy), .out_l1_pair(unused_l1),
        .out_x_even(sobel_coordinate[10:0]), .out_y(sobel_coordinate[21:11]),
        .out_sof(sobel_coordinate[22]), .out_eol(sobel_coordinate[23]), .out_eof(sobel_coordinate[24]), .empty(sobel_empty)
    );
    generate if(EDGE_CONTEXT_ENABLE!=0&&EDGE_THIN_ENABLE!=0)begin : thin_spatial_context
        wire packed_valid,packed_ready,pack_empty,window_valid,window_ready,window_empty,filter_empty;
        wire [47:0] packed_pair;
        wire [431:0] context_window;
        wire [24:0] packed_coordinate,window_coordinate;
        wire context_start=frame_start&&!external_sobel_owner&&job_output_kind==1&&(!RUNTIME_EDGE_CONFIG||job_edge_enhance);
        wire context_flush=flush||(frame_start&&(external_sobel_owner||job_output_kind!=1||(RUNTIME_EDGE_CONFIG&&!job_edge_enhance)));
        edge_thin_pack_pair #(.THRESHOLD_DROP(EDGE_CONTEXT_THRESHOLD_DROP)) pack (
            .clk(clk),.rst(rst),.frame_start(frame_start),.data_flush(flush),
            .in_valid(sobel_valid&&context_active&&running),.in_ready(context_input_ready),
            .in_center_pair(sobel_center),.in_seed_pair(sobel_edge),
            .in_gx_pair(unused_gx),.in_gy_pair(unused_gy),.in_l1_pair(unused_l1),.threshold(threshold_locked),
            .in_x_even(sobel_coordinate[10:0]),.in_y(sobel_coordinate[21:11]),
            .in_sof(sobel_coordinate[22]),.in_eol(sobel_coordinate[23]),.in_eof(sobel_coordinate[24]),
            .out_valid(packed_valid),.out_ready(packed_ready),.out_pair(packed_pair),
            .out_x_even(packed_coordinate[10:0]),.out_y(packed_coordinate[21:11]),
            .out_sof(packed_coordinate[22]),.out_eol(packed_coordinate[23]),.out_eof(packed_coordinate[24]),.empty(pack_empty));
        edge_thin_window_pair #(.W(W),.H(H)) window (
            .clk(clk),.rst(rst),.frame_start(context_start),.data_flush(context_flush),
            .in_valid(packed_valid),.in_ready(packed_ready),.in_pair(packed_pair),
            .in_x_even(packed_coordinate[10:0]),.in_y(packed_coordinate[21:11]),
            .in_sof(packed_coordinate[22]),.in_eol(packed_coordinate[23]),.in_eof(packed_coordinate[24]),
            .out_valid(window_valid),.out_ready(window_ready),.out_window_pair(context_window),
            .out_x_even(window_coordinate[10:0]),.out_y(window_coordinate[21:11]),
            .out_sof(window_coordinate[22]),.out_eol(window_coordinate[23]),.out_eof(window_coordinate[24]),.empty(window_empty));
        edge_thin_filter_pair #(.W(W),.H(H),.MODE(EDGE_THIN_MODE)) filter (
            .clk(clk),.rst(rst),.frame_start(frame_start),.data_flush(flush),
            .in_valid(window_valid),.in_ready(window_ready),.in_window_pair(context_window),
            .in_x_even(window_coordinate[10:0]),.in_y(window_coordinate[21:11]),
            .in_sof(window_coordinate[22]),.in_eol(window_coordinate[23]),.in_eof(window_coordinate[24]),
            .out_valid(context_valid),.out_ready(output_slot_ready&&running),
            .out_center_pair(context_center),.out_edge_pair(context_edge),
            .out_x_even(context_coordinate[10:0]),.out_y(context_coordinate[21:11]),
            .out_sof(context_coordinate[22]),.out_eol(context_coordinate[23]),.out_eof(context_coordinate[24]),.empty(filter_empty));
        assign context_empty=pack_empty&&window_empty&&filter_empty;

    end else if(EDGE_CONTEXT_ENABLE!=0)begin : spatial_context
        wire packed_valid,packed_ready,pack_empty,window_valid,window_ready,window_empty,filter_empty;
        wire [31:0] packed_pair;
        wire [287:0] context_window;
        wire [24:0] packed_coordinate,window_coordinate;
        wire context_start=frame_start&&!external_sobel_owner&&job_output_kind==1&&(!RUNTIME_EDGE_CONFIG||job_edge_enhance);
        wire context_flush=flush||(frame_start&&(external_sobel_owner||job_output_kind!=1||(RUNTIME_EDGE_CONFIG&&!job_edge_enhance)));
        edge_context_pack_pair #(.THRESHOLD_DROP(EDGE_CONTEXT_THRESHOLD_DROP)) pack (
            .clk(clk),.rst(rst),.frame_start(frame_start),.data_flush(flush),
            .in_valid(sobel_valid&&context_active&&running),.in_ready(context_input_ready),
            .in_center_pair(sobel_center),.in_seed_pair(sobel_edge),
            .in_gx_pair(unused_gx),.in_gy_pair(unused_gy),.in_l1_pair(unused_l1),.threshold(threshold_locked),
            .in_x_even(sobel_coordinate[10:0]),.in_y(sobel_coordinate[21:11]),
            .in_sof(sobel_coordinate[22]),.in_eol(sobel_coordinate[23]),.in_eof(sobel_coordinate[24]),
            .out_valid(packed_valid),.out_ready(packed_ready),.out_pair(packed_pair),
            .out_x_even(packed_coordinate[10:0]),.out_y(packed_coordinate[21:11]),
            .out_sof(packed_coordinate[22]),.out_eol(packed_coordinate[23]),.out_eof(packed_coordinate[24]),.empty(pack_empty));
        edge_context_window_pair #(.W(W),.H(H)) window (
            .clk(clk),.rst(rst),.frame_start(context_start),.data_flush(context_flush),
            .in_valid(packed_valid),.in_ready(packed_ready),.in_pair(packed_pair),
            .in_x_even(packed_coordinate[10:0]),.in_y(packed_coordinate[21:11]),
            .in_sof(packed_coordinate[22]),.in_eol(packed_coordinate[23]),.in_eof(packed_coordinate[24]),
            .out_valid(window_valid),.out_ready(window_ready),.out_window_pair(context_window),
            .out_x_even(window_coordinate[10:0]),.out_y(window_coordinate[21:11]),
            .out_sof(window_coordinate[22]),.out_eol(window_coordinate[23]),.out_eof(window_coordinate[24]),.empty(window_empty));
        edge_context_filter_pair #(.W(W),.H(H)) filter (
            .clk(clk),.rst(rst),.frame_start(frame_start),.data_flush(flush),
            .in_valid(window_valid),.in_ready(window_ready),.in_window_pair(context_window),
            .in_x_even(window_coordinate[10:0]),.in_y(window_coordinate[21:11]),
            .in_sof(window_coordinate[22]),.in_eol(window_coordinate[23]),.in_eof(window_coordinate[24]),
            .out_valid(context_valid),.out_ready(output_slot_ready&&running),
            .out_center_pair(context_center),.out_edge_pair(context_edge),
            .out_x_even(context_coordinate[10:0]),.out_y(context_coordinate[21:11]),
            .out_sof(context_coordinate[22]),.out_eol(context_coordinate[23]),.out_eof(context_coordinate[24]),.empty(filter_empty));
        assign context_empty=pack_empty&&window_empty&&filter_empty;
    end else begin : no_spatial_context
        assign context_input_ready=1'b0;
        assign context_valid=1'b0;
        assign context_empty=1'b1;
        assign context_center=16'b0;
        assign context_edge=2'b0;
        assign context_coordinate=25'b0;
    end endgenerate
    assign external_sobel_out_valid=external_sobel_owner&&sobel_valid;
    assign external_sobel_output={sobel_coordinate,unused_l1,unused_gy,unused_gx,sobel_edge,sobel_center};
    assign external_sobel_empty=win2_empty&&sobel_empty;
    assign out_valid = !rst && running && output_count!=0;
    assign {out_eof,out_eol,out_sof,out_y,out_x_even,out_edge,out_y_filtered}=output_slots[output_read_slot];
    wire output_fire = out_valid && out_ready;
    always @(posedge clk) begin
        if(rst||frame_start||flush) begin
            output_count<=0;output_write_slot<=0;output_read_slot<=0;
        end else begin
            if(output_slot_push) begin
                output_slots[output_write_slot]<=output_slot_data;
                output_write_slot<=!output_write_slot;
            end
            if(output_fire)output_read_slot<=!output_read_slot;
            case({output_slot_push,output_fire})
                2'b10:output_count<=output_count+2'd1;
                2'b01:output_count<=output_count-2'd1;
                default:begin end
            endcase
        end
    end
    assign out_epoch = epoch_locked; assign out_frame_id = frame_locked; assign out_config_id = config_locked;
    assign status_valid = !rst && job_state == STATUS;
    assign status_epoch = epoch_locked; assign status_frame_id = frame_locked; assign status_config_id = config_locked;
    assign status_in_pairs = accepted_pairs; assign status_out_pairs = delivered_pairs;
    wire all_empty = output_count==0 && gray_empty && win1_empty && median_empty &&
        (gray_output||(win2_empty&&sobel_empty&&(!context_active||context_empty)));
    always @(posedge clk) begin
        if (rst) begin
            job_state <= IDLE;
            epoch_locked <= 0; frame_locked <= 0; config_locked <= 0;
            median_locked <= 0; detail_locked<=0; enhance_locked<=1; kind_locked <= 0; threshold_locked <= 0;
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
                    detail_locked <= job_detail_enable; enhance_locked<=job_edge_enhance;
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
        $fatal(1, "frontend_frame_pair: illegal dimensions");
    // synthesis translate_on
endmodule
