// FA03/04/06：只处理已有、不可变的 RGB Source；采集和 RX close 由上层独立闭合。
module frame_canny_rpc #(
    parameter integer WIDTH = 1920, HEIGHT = 1080, RESULT_ITEM_BITS = 1,
    parameter logic [32:0] ADDRESS_BYTES = 33'h10000000
)(
    input logic clk, rst, axi_enable,
    input logic job_valid, output wire job_ready,
    input logic [141:0] job_cj,
    input logic [194:0] job_origin,
    input logic [63:0] job_handle,
    input logic [31:0] source_base, class_base, queue_base, result_base,
    input logic cancel_valid, input logic [95:0] cancel_scope,
    output wire grad_valid, input logic grad_ready, output wire [184:0] grad_payload,
    output wire done_valid, input logic done_ready,
    output wire [95:0] done_scope, output wire [194:0] done_origin,
    output logic [1:0] outcome, output logic [31:0] reason,
    output logic [20:0] reader_pairs, canny_input, canny_class,
    output logic [21:0] output_pixels, edge_pixels, discarded_fp,
    output wire [591:0] r2_status_snapshot,
    output wire [3:0] phase, output wire quarantined, producer_local_quarantined,
    output wire algorithm_req_valid, input logic algorithm_req_ready,
    output wire algorithm_write, output wire [31:0] algorithm_addr,
    output wire [511:0] algorithm_wdata,
    output wire [2047:0] flat_wdata,output wire [3:0] flat_select,
    input logic algorithm_rsp_valid, output wire algorithm_rsp_ready,
    input logic [511:0] algorithm_rdata,
    input logic algorithm_error, algorithm_drained, memory_quarantined,
    output wire  frontend_job_valid,
    input wire  frontend_job_ready,
    output wire [109:0] frontend_job,
    output wire  frontend_input_valid,
    input wire  frontend_input_ready,
    output wire [73:0] frontend_input,
    input wire  frontend_output_valid,
    output wire  frontend_output_ready,
    input wire [138:0] frontend_output,
    input wire  frontend_status_valid,
    output wire  frontend_status_ready,
    input wire [162:0] frontend_status,
    output wire  frontend_cancel,
    output wire shared_sobel_start,shared_sobel_flush,shared_sobel_open,
    output wire shared_sobel_in_valid,input wire shared_sobel_in_ready,
    output wire [40:0] shared_sobel_input,
    input wire shared_sobel_out_valid,output wire shared_sobel_out_ready,
    input wire [108:0] shared_sobel_output,input wire shared_sobel_empty,
    output wire  reader_job_valid,
    input wire  reader_job_ready,
    output wire [95:0] reader_job,
    input wire  reader_config_valid,
    output wire  reader_config_ready,
    input wire  reader_config_error,
    input wire  reader_pixel_valid,
    output wire  reader_pixel_ready,
    input wire [137:0] reader_pixel,
    input wire  reader_done_valid,
    output wire  reader_done_ready,
    input wire [161:0] reader_status,
    output wire  reader_cancel,
    output wire [63:0] reader_cancel_id,
    input wire  reader_line_valid,
    output wire  reader_line_ready,
    input wire  reader_line_write,
    input wire [31:0] reader_line_addr,
    input wire [511:0] reader_line_wdata,
    output wire  reader_reply_valid,
    input wire  reader_reply_ready,
    output wire [511:0] reader_reply_data,
    output wire  reader_reply_error,
    output wire  reader_reply_drained,
    output wire  writer_config_valid,
    input wire  writer_config_ready,
    output wire [95:0] writer_config,
    input wire  writer_config_reply_valid,
    output wire  writer_config_reply_ready,
    input wire  writer_config_error,
    output wire  writer_pixel_valid,
    input wire  writer_pixel_ready,
    output wire [85:0] writer_pixel,
    output wire  writer_abort,
    output wire [63:0] writer_abort_id,
    input wire  writer_done_valid,
    output wire  writer_done_ready,
    input wire [25:0] writer_status,
    input wire  writer_line_valid,
    output wire  writer_line_ready,
    input wire  writer_line_write,
    input wire [31:0] writer_line_addr,
    input wire [511:0] writer_line_wdata,
    output wire  writer_reply_valid,
    input wire  writer_reply_ready,
    output wire [511:0] writer_reply_data,
    output wire  writer_reply_error,
    output wire  writer_reply_drained
);
    localparam integer PIXELS = WIDTH * HEIGHT, PAIRS = PIXELS / 2;
    localparam logic [32:0] SOURCE_BYTES = 33'(((3*PIXELS+63)/64)*64);
    localparam logic [32:0] CLASS_BYTES = 33'(((PIXELS+255)/256)*64);
    localparam logic [32:0] QUEUE_BYTES = 33'(((PIXELS+15)/16)*64);
    localparam logic [32:0] RESULT_BYTES = 33'(((PIXELS*RESULT_ITEM_BITS+511)/512)*64);
    typedef enum logic [3:0] {
        IDLE, START_CANNY, START_READER, WAIT_READER_CFG, PROCESS, DRAIN, DONE, QUARANTINE
    } state_t;
    state_t state;
    logic [141:0] cj;
    logic [194:0] origin;
    logic [63:0] handle;
    logic [31:0] locked_source, locked_class, locked_queue, locked_result;
    logic reader_started, reader_closed, canny_started, canny_closed, stopping;

    // 输入检查用当前 job；执行、取消和回执一律使用接受沿锁定的上下文。
    wire [32:0] source_end = {1'b0,source_base} + SOURCE_BYTES;
    wire [32:0] class_end = {1'b0,class_base} + CLASS_BYTES;
    wire [32:0] queue_end = {1'b0,queue_base} + QUEUE_BYTES;
    wire [32:0] result_end = {1'b0,result_base} + RESULT_BYTES;
    wire legal = job_cj[106:96] == 11'(WIDTH) && job_cj[117:107] == 11'(HEIGHT) &&
        job_cj[128:118] <= job_cj[139:129] && job_origin[2:0] < 6 &&
        job_cj[31:0] == job_origin[98:67] && job_cj[63:32] == job_origin[130:99] &&
        (source_base[5:0] | class_base[5:0] | queue_base[5:0] | result_base[5:0]) == 0 &&
        source_end <= ADDRESS_BYTES && class_end <= ADDRESS_BYTES &&
        queue_end <= ADDRESS_BYTES && result_end <= ADDRESS_BYTES &&
        (source_end <= {1'b0,class_base} || class_end <= {1'b0,source_base}) &&
        (source_end <= {1'b0,queue_base} || queue_end <= {1'b0,source_base}) &&
        (source_end <= {1'b0,result_base} || result_end <= {1'b0,source_base}) &&
        (class_end <= {1'b0,queue_base} || queue_end <= {1'b0,class_base}) &&
        (class_end <= {1'b0,result_base} || result_end <= {1'b0,class_base}) &&
        (queue_end <= {1'b0,result_base} || result_end <= {1'b0,queue_base});
    wire matching_cancel = cancel_valid && cancel_scope == cj[95:0] && !stopping &&
        state != IDLE && state != DONE && state != QUARANTINE;
    wire child_cancel = stopping || matching_cancel;

    wire r_job_ready, r_cfg_valid, r_cfg_error, r_done_valid, r_done_ready, r_stop, r_q;
    wire r_out_valid, r_out_ready;
    wire [73:0] r_fp;
    wire [63:0] r_id, r_done_id;
    wire [1:0] r_outcome;
    wire [7:0] r_reason;
    wire [20:0] r_prepared, r_output;
    wire [21:0] r_lines, r_discard;
    wire c_job_ready, c_input_ready, c_done_valid, c_done_ready, c_stop, c_q;
    wire [95:0] c_done_scope;
    wire [1:0] c_outcome;
    wire [31:0] c_reason;
    wire [20:0] c_input, c_classes;
    wire [21:0] c_output, c_edges, c_discard;
    wire [591:0] c_status_snapshot;
    wire [1:0] client_valid, client_ready, client_write, client_rsp_valid, client_rsp_ready;
    wire [31:0] client_addr [0:1];
    wire [511:0] client_data [0:1];
    wire [511:0] client_rdata;
    wire client_error, client_drained, algorithm_group_q;
    wire reader_fire = r_done_valid && r_done_ready;
    wire canny_fire = c_done_valid && c_done_ready;
    wire cfg_fire = state == WAIT_READER_CFG && r_cfg_valid;
    wire all_closed = reader_closed && canny_closed;
    wire discard_enabled = canny_closed && child_cancel && reader_started &&
        !reader_closed && state != QUARANTINE;
    wire counts_bad = reader_pairs != 21'(PAIRS) || canny_input != 21'(PAIRS) ||
        canny_class != 21'(PAIRS) || output_pixels != 22'(PIXELS) || discarded_fp != 0;
    logic [31:0] error_events;
    always_comb begin
        error_events = 0;
        if (state == IDLE && job_valid && job_ready && !legal) error_events[0] = 1;
        if ((reader_fire && r_outcome == 1) || (cfg_fire && r_cfg_error)) error_events[3] = 1;
        if (canny_fire && c_outcome == 1) error_events[4] = 1;
        if (state == DRAIN && all_closed && outcome == 0 && !child_cancel && counts_bad)
            error_events[5] = 1;
    end
    assign job_ready = !rst && state == IDLE && axi_enable && !quarantined &&
        r_job_ready && c_job_ready;
    assign done_valid = !rst && state == DONE;
    assign done_scope = cj[95:0];
    assign done_origin = origin;
    assign phase = state;
    assign r2_status_snapshot = canny_started ? c_status_snapshot : 592'd0;
    assign producer_local_quarantined = r_q || c_q || algorithm_group_q || state == QUARANTINE;
    assign quarantined = producer_local_quarantined || memory_quarantined;
    assign r_done_ready = !rst && reader_started && !reader_closed && state != QUARANTINE;
    assign c_done_ready = !rst && canny_started && !canny_closed && state != QUARANTINE;
    assign r_out_ready = discard_enabled || (canny_started && !canny_closed && c_input_ready);

    // reader 的真实事务仍经过原 algorithm_group；这里只移出重复硬件。
    assign reader_job_valid=state==START_READER;assign r_job_ready=reader_job_ready;assign reader_job={handle,locked_source};
    assign r_cfg_valid=reader_config_valid;assign reader_config_ready=state==WAIT_READER_CFG;assign r_cfg_error=reader_config_error;
    assign r_out_valid=reader_pixel_valid;assign reader_pixel_ready=r_out_ready;assign r_fp=reader_pixel[73:0];assign r_id=reader_pixel[137:74];
    assign reader_cancel=child_cancel;assign reader_cancel_id=handle;
    assign r_done_valid=reader_done_valid;assign reader_done_ready=r_done_ready;
    assign r_done_id=reader_status[63:0];assign r_outcome=reader_status[65:64];assign r_reason=reader_status[73:66];
    assign r_prepared=reader_status[94:74];assign r_output=reader_status[115:95];
    assign r_lines=reader_status[137:116];assign r_discard=reader_status[159:138];assign r_stop=reader_status[160];assign r_q=reader_status[161];
    assign client_valid[0]=reader_line_valid;assign reader_line_ready=client_ready[0];assign client_write[0]=reader_line_write;
    assign client_addr[0]=reader_line_addr;assign client_data[0]=reader_line_wdata;
    assign reader_reply_valid=client_rsp_valid[0];assign client_rsp_ready[0]=reader_reply_ready;
    assign reader_reply_data=client_rdata;assign reader_reply_error=client_error;assign reader_reply_drained=client_drained;
    canny_full_top #(.WIDTH(WIDTH), .HEIGHT(HEIGHT), .RESULT_ITEM_BITS(RESULT_ITEM_BITS)) canny (
        .flat_wdata,.flat_select,        .shared_sobel_start,.shared_sobel_flush,.shared_sobel_open,.shared_sobel_in_valid,.shared_sobel_in_ready,
        .shared_sobel_input,.shared_sobel_out_valid,.shared_sobel_out_ready,.shared_sobel_output,.shared_sobel_empty,
        .frontend_job_valid, .frontend_job_ready, .frontend_job, .frontend_input_valid, .frontend_input_ready, .frontend_input, .frontend_output_valid, .frontend_output_ready, .frontend_output, .frontend_status_valid, .frontend_status_ready, .frontend_status, .frontend_cancel, .writer_config_valid, .writer_config_ready, .writer_config, .writer_config_reply_valid, .writer_config_reply_ready, .writer_config_error, .writer_pixel_valid, .writer_pixel_ready, .writer_pixel, .writer_abort, .writer_abort_id, .writer_done_valid, .writer_done_ready, .writer_status, .writer_line_valid, .writer_line_ready, .writer_line_write, .writer_line_addr, .writer_line_wdata, .writer_reply_valid, .writer_reply_ready, .writer_reply_data, .writer_reply_error, .writer_reply_drained,
        
        .clk, .rst, .cj_valid(state == START_CANNY), .cj_ready(c_job_ready), .cj,
        .class_base(locked_class), .queue_base(locked_queue), .result_base(locked_result),
        .in_valid(r_out_valid && canny_started && !canny_closed), .in_ready(c_input_ready), .in_fp(r_fp),
        .grad_valid, .grad_ready, .grad_payload, .cancel_valid(child_cancel), .cancel_scope(cj[95:0]),
        .source_stop(c_stop), .done_valid(c_done_valid), .done_ready(c_done_ready),
        .done_scope(c_done_scope), .outcome(c_outcome), .reason(c_reason),
        .input_pairs(c_input), .class_pairs(c_classes), .output_pixels(c_output), .edge_pixels(c_edges),
        .r2_status_snapshot(c_status_snapshot), .discarded_pixels(c_discard),
        .line_req_valid(client_valid[1]), .line_req_ready(client_ready[1]),
        .line_write(client_write[1]), .line_addr(client_addr[1]), .line_wdata(client_data[1]),
        .line_rsp_valid(client_rsp_valid[1]), .line_rsp_ready(client_rsp_ready[1]),
        .line_rdata(client_rdata), .line_error(client_error), .line_drained(client_drained), .quarantined(c_q)
    );
    line_rpc_arbiter2 algorithm_group (
        .clk, .rst, .req_valid(client_valid), .req_ready(client_ready), .req_write(client_write),
        .req_addr(client_addr), .req_data(client_data), .rsp_valid(client_rsp_valid),
        .rsp_ready(client_rsp_ready), .rsp_data(client_rdata), .rsp_error(client_error), .rsp_drained(client_drained),
        .line_req_valid(algorithm_req_valid), .line_req_ready(algorithm_req_ready), .line_write(algorithm_write),
        .line_addr(algorithm_addr), .line_wdata(algorithm_wdata), .line_rsp_valid(algorithm_rsp_valid),
        .line_rsp_ready(algorithm_rsp_ready), .line_rdata(algorithm_rdata),
        .line_error(algorithm_error), .line_drained(algorithm_drained), .quarantined(algorithm_group_q)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE; cj <= 0; origin <= 0; handle <= 0;
            locked_source <= 0; locked_class <= 0; locked_queue <= 0; locked_result <= 0;
            reader_started <= 0; canny_started <= 0; reader_closed <= 1; canny_closed <= 1; stopping <= 0;
            outcome <= 0; reason <= 0; reader_pairs <= 0; canny_input <= 0; canny_class <= 0;
            output_pixels <= 0; edge_pixels <= 0; discarded_fp <= 0;
        end else begin
            if (r_out_valid && r_out_ready && discard_enabled) discarded_fp <= discarded_fp + 22'd1;
            case (state)
                IDLE: if (job_valid && job_ready) begin
                    cj <= job_cj; origin <= job_origin; handle <= job_handle;
                    locked_source <= source_base; locked_class <= class_base;
                    locked_queue <= queue_base; locked_result <= result_base;
                    reader_started <= 0; canny_started <= 0; reader_closed <= 1; canny_closed <= 1; stopping <= 0;
                    outcome <= 0; reason <= 0; reader_pairs <= 0; canny_input <= 0; canny_class <= 0;
                    output_pixels <= 0; edge_pixels <= 0; discarded_fp <= 0;
                    if (!legal) begin state <= DRAIN; stopping <= 1; outcome <= 1; reason <= 1; end
                    else if (cancel_valid && cancel_scope == job_cj[95:0]) begin
                        state <= DRAIN; stopping <= 1; outcome <= 2;
                    end else state <= START_CANNY;
                end
                START_CANNY: if (c_job_ready) begin
                    canny_started <= 1; canny_closed <= 0;
                    state <= child_cancel ? DRAIN : START_READER;
                end
                START_READER: if (r_job_ready) begin
                    reader_started <= 1; reader_closed <= 0; state <= WAIT_READER_CFG;
                end
                WAIT_READER_CFG: if (r_cfg_valid) begin
                    if (r_cfg_error) begin reader_closed <= 1; stopping <= 1; state <= DRAIN; end
                    else state <= child_cancel ? DRAIN : PROCESS;
                end
                DRAIN: if (all_closed && !quarantined) state <= DONE;
                DONE: if (done_ready) state <= IDLE;
                default: begin end
            endcase
            if (matching_cancel) begin
                stopping <= 1;
                if (outcome == 0) outcome <= 2;
                // 保留已公开 child job/cfg 的接受义务，不能靠取消从启动状态跳走。
                if (state != START_CANNY && state != START_READER && state != WAIT_READER_CFG) state <= DRAIN;
            end
            if (reader_fire) begin
                reader_closed <= 1; reader_pairs <= r_output; state <= DRAIN;
                if (r_outcome != 0) begin stopping <= 1; if (outcome == 0 && r_outcome == 2) outcome <= 2; end
            end
            if (canny_fire) begin
                canny_closed <= 1; canny_input <= c_input; canny_class <= c_classes;
                output_pixels <= c_output; edge_pixels <= c_edges; state <= DRAIN;
                if (c_outcome != 0) begin stopping <= 1; if (outcome == 0 && c_outcome == 2) outcome <= 2; end
            end
            if (|error_events) begin reason <= ((state == IDLE) ? 32'd0 : reason) | error_events; outcome <= 1; stopping <= 1; end
            // 安全 DONE 已公开之后，无关 memory Q 只禁止复用，不改变原回执。
            if (quarantined && state != DONE) begin state <= QUARANTINE; stopping <= 1; outcome <= 1; end
        end
    end
    // synthesis translate_off
    initial begin
        if (WIDTH < 6 || WIDTH > 1920 || WIDTH % 2 || HEIGHT < 5 || HEIGHT > 1080)
            $fatal(1, "Frame algorithm geometry");
        if (RESULT_ITEM_BITS != 1 && RESULT_ITEM_BITS != 8) $fatal(1, "Frame algorithm result format");
    end
    always @(posedge clk) if (!rst) begin
        if ((|client_rsp_valid) && $isunknown({client_rdata,client_error,client_drained})) $fatal(1, "Effective algorithm reply contains X/Z");
        if (done_valid && !all_closed) $fatal(1, "Frame algorithm DONE before true child closure");
        if (reader_fire && r_done_id != handle) $fatal(1, "Frame reader identity changed");
        if (canny_fire && c_done_scope != cj[95:0]) $fatal(1, "Frame Canny identity changed");
        if (r_out_valid && r_out_ready && r_id != handle) $fatal(1, "Frame reader FP identity changed");
    end
    // synthesis translate_on
endmodule
