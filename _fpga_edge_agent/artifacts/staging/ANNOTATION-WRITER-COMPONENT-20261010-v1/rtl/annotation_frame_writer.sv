// AW01..08 / 设计E：标注头与标签图的真实写入。调用者持有当前R_WORKING借用。
// 只核对canonical描述，不以字段正确代替账本授权；不解释图形识别元数据。
module annotation_frame_writer #(
    parameter integer IMAGE_WIDTH = 1920,
    parameter integer IMAGE_HEIGHT = 1080,
    parameter logic [32:0] ADDRESS_BYTES = 33'h10000000
)(
    input  logic clk,
    input  logic rst,

    input  logic job_valid,
    output wire  job_ready,
    input  logic [941:0] job_bundle,
    output wire  job_reply_valid,
    input  logic job_reply_ready,
    output logic job_reply_error,

    input  logic header_valid,
    output wire  header_ready,
    input  logic [511:0] header_data,
    input  logic [6:0] header_index,
    input  logic [63:0] header_handle,

    input  logic body_valid,
    output wire  body_ready,
    input  logic [3:0] body_pair,
    input  logic [20:0] body_index,
    input  logic [63:0] body_handle,
    input  logic body_last,

    input  logic cancel_valid,
    input  logic [63:0] cancel_handle,
    output wire  done_valid,
    input  logic done_ready,
    output logic [63:0] done_handle,
    output logic [95:0] done_scope,
    output logic [194:0] done_origin,
    output logic [1:0] done_outcome,
    output logic [7:0] done_reason,
    output wire [6:0] done_headers,
    output logic [21:0] done_pairs,
    output wire [21:0] done_lines,
    output wire done_drained,
    output wire quarantined,

    output wire line_req_valid,
    input  logic line_req_ready,
    output wire line_write,
    output wire [31:0] line_addr,
    output wire [511:0] line_wdata,
    input  logic line_rsp_valid,
    output wire line_rsp_ready,
    input  logic line_error,
    input  logic line_drained
);
    import frame_owner_pkg::*;

    localparam integer PIXELS = IMAGE_WIDTH * IMAGE_HEIGHT;
    localparam integer PAIRS = PIXELS / 2;
    localparam logic [31:0] RGB_BYTES = 32'(3 * PIXELS);
    localparam logic [31:0] EDGE_BYTES = 32'((PIXELS + 7) / 8);
    localparam logic [31:0] ANN_BYTES = 32'(4224 + (PIXELS + 3) / 4);
    localparam logic [1:0] NORMAL = 2'd0, ERROR = 2'd1, CANCELLED = 2'd2;

    typedef enum logic [3:0] {
        IDLE, JOB_REPLY, HEADER_ACCEPT, HEADER_REQUEST, HEADER_RESPONSE,
        BODY_CONFIG, BODY_ACK, BODY_RUN, DONE, Q
    } state_t;
    state_t state;

    reply_t incoming;
    assign incoming = job_bundle;
    logic [31:0] annotation_base;
    logic [31:0] header_address;
    logic [511:0] header_buffer;
    logic [6:0] header_count;
    logic [21:0] successful_body_lines;
    logic cancel_sticky;
    logic [7:0] working_reason;

    wire matching_cancel = cancel_valid && cancel_handle == done_handle &&
        state != IDLE && state != DONE && state != Q;
    wire stopping = cancel_sticky || matching_cancel;

    function automatic logic [31:0] align64(input logic [31:0] length);
        return (length + 32'd63) & 32'hffffffc0;
    endfunction

    // AW01：所有地址来自实际owner回执的固定槽布局；先用33位验证末端。
    function automatic logic canonical_job(input reply_t value);
        logic [31:0] source_base, result_base, ann_base;
        logic [95:0] source_desc, edge_desc, ann_desc;
        logic legal_ranges;
        begin
            source_base = 32'(value.source_slot) * 32'h00800000;
            result_base = 32'h03000000 + 32'(value.result_slot) * 32'h00800000;
            ann_base = result_base + 32'h00100000;
            source_desc = {source_base, RGB_BYTES, align64(RGB_BYTES)};
            edge_desc = {result_base, EDGE_BYTES, align64(EDGE_BYTES)};
            ann_desc = {ann_base, ANN_BYTES, align64(ANN_BYTES)};
            legal_ranges = {1'b0, source_base} + {1'b0, align64(RGB_BYTES)} <= ADDRESS_BYTES &&
                {1'b0, result_base} + {1'b0, align64(EDGE_BYTES)} <= ADDRESS_BYTES &&
                {1'b0, ann_base} + {1'b0, align64(ANN_BYTES)} <= ADDRESS_BYTES;
            return (^value !== 1'bx) && value.op == ALLOC_RESULT && value.status == OK &&
                value.source_handle != 0 && value.result_handle != 0 && value.policy != 0 &&
                value.source_slot < 6 && value.result_slot < 3 &&
                value.origin[194:131] == value.source_handle &&
                value.origin[66:3] == value.source_handle &&
                value.origin[2:0] == value.source_slot &&
                value.cj[63:0] == value.origin[130:67] &&
                value.cj[106:96] == IMAGE_WIDTH && value.cj[117:107] == IMAGE_HEIGHT &&
                value.cj[128:118] <= value.cj[139:129] &&
                value.body[111:109] == 5 && value.body[108:98] == IMAGE_HEIGHT / 2 &&
                value.body[399:112] == {source_desc, edge_desc, ann_desc} && legal_ranges;
        end
    endfunction

    wire sink_cfg_ready, sink_cfg_rsp_valid, sink_cfg_error;
    wire sink_input_ready, sink_done_valid, sink_done_error, sink_done_aborted;
    wire sink_done_drained, sink_q;
    wire [21:0] sink_count;
    wire sink_req_valid, sink_rsp_ready;
    wire [31:0] sink_addr;
    wire [511:0] sink_data;
    wire body_phase = state == BODY_RUN;
    wire body_bad = body_index != 21'(sink_count) || body_handle != done_handle ||
        body_last != (sink_count == 22'(PAIRS - 1));

    // AW03：class_frame_writer拒绝标签3，故直接复用允许全部4bit值的packed sink。
    packed_frame_line_sink #(.ITEM_BITS(4), .ITEMS(PAIRS), .ID_BITS(64)) body_sink (
        .clk(clk), .rst(rst),
        .cfg_valid(state == BODY_CONFIG && !rst), .cfg_ready(sink_cfg_ready),
        .cfg_base(annotation_base + 32'd4224), .cfg_id(done_handle),
        .cfg_rsp_valid(sink_cfg_rsp_valid), .cfg_rsp_ready(state == BODY_ACK && !rst),
        .cfg_rsp_error(sink_cfg_error),
        .in_valid(body_valid && body_phase), .in_ready(sink_input_ready),
        .in_data(body_pair), .in_bad(body_bad),
        .abort_valid(stopping), .abort_id(done_handle),
        .done_valid(sink_done_valid), .done_ready(body_phase && !rst),
        .done_error(sink_done_error), .done_aborted(sink_done_aborted),
        .done_drained(sink_done_drained), .count(sink_count),
        .line_req_valid(sink_req_valid), .line_req_ready(line_req_ready && body_phase),
        .line_write(), .line_addr(sink_addr), .line_wdata(sink_data),
        .line_rsp_valid(line_rsp_valid && body_phase), .line_rsp_ready(sink_rsp_ready),
        .line_rdata(512'd0), .line_error(line_error), .line_drained(line_drained),
        .quarantined(sink_q)
    );

    assign job_ready = !rst && state == IDLE;
    assign job_reply_valid = !rst && state == JOB_REPLY;
    assign header_ready = !rst && state == HEADER_ACCEPT && !stopping;
    assign body_ready = !rst && body_phase && sink_input_ready;
    assign done_valid = !rst && state == DONE;
    assign done_drained = !rst && state == DONE;
    assign quarantined = state == Q;
    assign done_headers = header_count;
    assign done_lines = successful_body_lines;

    // AW04/05：状态选择两段RPC；公开请求不以stopping或外部Q撤回。
    assign line_req_valid = !rst && (state == HEADER_REQUEST || (body_phase && sink_req_valid));
    assign line_write = 1'b1;
    assign line_addr = body_phase ? sink_addr : header_address;
    assign line_wdata = body_phase ? sink_data : header_buffer;
    assign line_rsp_ready = !rst && (state == HEADER_RESPONSE || (body_phase && sink_rsp_ready));

    task automatic finish_job(input logic [1:0] result, input logic [7:0] reason);
        begin
            done_outcome <= result;
            done_reason <= reason;
            state <= DONE;
        end
    endtask

    always_ff @(posedge clk) begin : annotation_control
        if (rst) begin
            state <= IDLE;
            annotation_base <= 0;
            header_address <= 0;
            header_buffer <= 0;
            header_count <= 0;
            successful_body_lines <= 0;
            cancel_sticky <= 0;
            working_reason <= 0;
            job_reply_error <= 0;
            done_handle <= 0;
            done_scope <= 0;
            done_origin <= 0;
            done_outcome <= NORMAL;
            done_reason <= 0;
            done_pairs <= 0;
        end else begin
            if (matching_cancel)
                cancel_sticky <= 1;

            case (state)
                IDLE: begin
                    if (job_valid && job_ready) begin
                        annotation_base <= incoming.body[207:176];
                        done_handle <= incoming.result_handle;
                        done_scope <= incoming.cj[95:0];
                        done_origin <= incoming.origin;
                        job_reply_error <= !canonical_job(incoming);
                        header_count <= 0;
                        successful_body_lines <= 0;
                        done_pairs <= 0;
                        working_reason <= 0;
                        done_reason <= 0;
                        done_outcome <= NORMAL;
                        cancel_sticky <= 0;
                        state <= JOB_REPLY;
                    end
                end
                JOB_REPLY: begin
                    if (job_reply_ready) begin
                        if (job_reply_error)
                            state <= IDLE;
                        else if (stopping)
                            finish_job(CANCELLED, 8'd0);
                        else
                            state <= HEADER_ACCEPT;
                    end
                end
                HEADER_ACCEPT: begin
                    if (stopping) begin
                        finish_job(CANCELLED, working_reason);
                    end else if (header_valid && header_ready) begin
                        if (header_index != header_count || header_handle != done_handle) begin
                            finish_job(ERROR, 8'h02);
                        end else begin
                            header_buffer <= header_data;
                            header_address <= annotation_base + (32'(header_count) << 6);
                            state <= HEADER_REQUEST;
                        end
                    end
                end
                HEADER_REQUEST: begin
                    if (line_req_valid && line_req_ready)
                        state <= HEADER_RESPONSE;
                end
                HEADER_RESPONSE: begin
                    if (line_rsp_valid && line_rsp_ready) begin
                        if (!line_drained) begin
                            state <= Q;
                        end else if (line_error) begin
                            finish_job(ERROR, 8'h08);
                        end else begin
                            header_count <= header_count + 7'd1;
                            if (stopping)
                                finish_job(CANCELLED, working_reason);
                            else if (header_count == 7'd65)
                                state <= BODY_CONFIG;
                            else
                                state <= HEADER_ACCEPT;
                        end
                    end
                end
                BODY_CONFIG: begin
                    if (sink_cfg_ready)
                        state <= BODY_ACK;
                end
                BODY_ACK: begin
                    if (sink_cfg_rsp_valid) begin
                        if (sink_cfg_error)
                            finish_job(ERROR, 8'h10);
                        else
                            state <= BODY_RUN;
                    end
                end
                BODY_RUN: begin
                    if (body_valid && body_ready && body_bad)
                        working_reason <= working_reason | 8'h04;
                    if (line_rsp_valid && line_rsp_ready && line_drained) begin
                        if (line_error)
                            working_reason <= working_reason | 8'h08;
                        else
                            successful_body_lines <= successful_body_lines + 22'd1;
                    end
                    if (sink_q) begin
                        state <= Q;
                    end else if (sink_done_valid) begin
                        // 实际子DONE当沿消费；随后父DONE保留count和身份，不借用子状态。
                        done_pairs <= sink_count;
                        if (!sink_done_drained)
                            state <= Q;
                        else if (working_reason != 0 || (sink_done_error && !sink_done_aborted))
                            finish_job(ERROR, working_reason != 0 ? working_reason : 8'h08);
                        else if (sink_done_aborted)
                            finish_job(CANCELLED, working_reason);
                        else
                            finish_job(NORMAL, working_reason);
                    end
                end
                DONE: begin
                    if (done_ready)
                        state <= IDLE;
                end
                Q: begin
                    // AW06：未知闭合不转换成安全DONE；仅共同冷复位可恢复。
                end
                default: state <= Q;
            endcase
        end
    end

    initial begin
        if (IMAGE_WIDTH < 4 || IMAGE_WIDTH > 1920 || IMAGE_WIDTH % 2 != 0 ||
            IMAGE_HEIGHT < 2 || IMAGE_HEIGHT > 1080 || IMAGE_HEIGHT % 2 != 0)
            $fatal(1, "Unsupported annotation writer geometry");
    end
endmodule
