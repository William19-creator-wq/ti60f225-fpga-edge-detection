// FP01..08：Source/Result/回收/policy共享唯一owner；图像执行和显示仍由外部实际模块提供。
module frame_publish_control #(
    parameter integer WIDTH = 1920, HEIGHT = 1080
)(
    input logic core_clk, rst, halt, owner_quarantined, producer_quarantined,
    input logic pause_new_requests,
    input logic request_valid, output wire request_ready,
    input logic [63:0] request_token, request_source,
    input logic [194:0] request_origin,
    input logic [141:0] request_cj,
    input logic [111:0] request_render,
    input logic cancel_valid, input logic [63:0] cancel_token,
    output wire job_valid, input logic job_ready, output wire [941:0] job_bundle,
    input logic producer_done_valid, output wire producer_done_ready,
    input logic [63:0] producer_done_result,
    input logic [194:0] producer_done_origin,
    input logic [95:0] producer_done_scope,
    input logic [1:0] producer_outcome,
    input logic [31:0] producer_reason,
    input logic [21:0] producer_pixels, producer_discard,
    output wire producer_cancel_valid,
    output wire [63:0] producer_cancel_result,
    output wire [95:0] producer_cancel_scope,
    input logic source_cmd_valid, output wire source_cmd_ready,
    input logic [940:0] source_command,
    output wire source_reply_valid, input logic source_reply_ready,
    output wire [941:0] source_reply,
    input logic policy_cmd_valid, output wire policy_cmd_ready,
    input logic [940:0] policy_command,
    output wire policy_reply_valid, input logic policy_reply_ready,
    output wire [941:0] policy_reply,
    output wire owner_cmd_valid, input logic owner_cmd_ready,
    output wire [940:0] owner_command, output wire [63:0] owner_offer_sequence,
    input logic owner_reply_valid, output wire owner_reply_ready,
    input logic [941:0] owner_reply,
    input logic sequence_valid, output wire sequence_ready,
    input logic [63:0] sequence_value, input logic sequence_exhausted,
    output wire route_valid, input logic route_ready,
    output wire [1136:0] route_request,
    input logic route_reply_valid, output wire route_reply_ready,
    input logic [1206:0] route_reply,
    output wire route_cancel_valid, output wire [63:0] route_cancel_sequence,
    input logic oldclosed_valid, output wire oldclosed_ready,
    input logic [386:0] oldclosed_ref,
    output wire retired_valid, input logic retired_ready,
    output wire [386:0] retired_ref,
    output wire root_retire_capacity,
    output wire completion_valid, input logic completion_ready,
    output wire [63:0] completion_token,
    output wire [1:0] completion_outcome,
    output wire [3:0] completion_status,
    output wire [63:0] completion_reason,
    output wire [941:0] completion_bundle,
    output wire result_idle, owner_bus_idle, retire_idle, quarantined
);
    import frame_owner_pkg::*;
    logic [3:0] client_cmd_valid, client_cmd_ready, client_reply_valid, client_reply_ready;
    logic [3:0][940:0] client_command;
    logic [3:0][63:0] client_sequence;
    logic [3:0][941:0] client_reply;
    wire result_cmd_valid, result_cmd_ready, result_reply_valid, result_reply_ready;
    wire retire_cmd_valid, retire_cmd_ready, retire_reply_valid, retire_reply_ready;
    wire [940:0] result_command, retire_command;
    wire [63:0] result_sequence;
    wire [941:0] result_reply, retire_reply;
    wire applied_valid, applied_ready;
    wire [63:0] applied_sequence, previous_result;
    wire [941:0] applied_bundle;
    wire result_q, retire_q;
    logic boundary_q;
    command_t source_view, policy_view;
    wire source_legal = source_view.op <= SOURCE_END;
    wire policy_legal = policy_view.op == FREEZE || policy_view.op == RESUME || policy_view.op == BARRIER;
    wire policy_window = result_idle && pause_new_requests;

    assign source_view = source_command;
    assign policy_view = policy_command;
    assign quarantined = boundary_q || result_q || retire_q || owner_quarantined;
    // 外部policy可以持有请求等窗口；接受前必须暂停新处理并使Result空闲。
    always_comb begin
        client_cmd_valid = 0;
        client_command = '0;
        client_sequence = '0;
        client_reply_ready = 0;
        client_cmd_valid[0] = source_cmd_valid && source_legal;
        client_command[0] = source_command;
        client_reply_ready[0] = source_reply_ready;
        client_cmd_valid[1] = result_cmd_valid;
        client_command[1] = result_command;
        client_sequence[1] = result_sequence;
        client_reply_ready[1] = result_reply_ready;
        client_cmd_valid[2] = retire_cmd_valid;
        client_command[2] = retire_command;
        client_reply_ready[2] = retire_reply_ready;
        client_cmd_valid[3] = policy_cmd_valid && policy_legal && policy_window;
        client_command[3] = policy_command;
        client_reply_ready[3] = policy_reply_ready;
    end
    assign source_cmd_ready = client_cmd_ready[0] && source_legal;
    assign source_reply_valid = client_reply_valid[0];
    assign source_reply = client_reply[0];
    assign result_cmd_ready = client_cmd_ready[1];
    assign result_reply_valid = client_reply_valid[1];
    assign result_reply = client_reply[1];
    assign retire_cmd_ready = client_cmd_ready[2];
    assign retire_reply_valid = client_reply_valid[2];
    assign retire_reply = client_reply[2];
    assign policy_cmd_ready = client_cmd_ready[3] && policy_legal && policy_window;
    assign policy_reply_valid = client_reply_valid[3];
    assign policy_reply = client_reply[3];

    always_ff @(posedge core_clk)
        if (rst) boundary_q <= 0;
        else if ((source_cmd_valid && !source_legal) || (policy_cmd_valid && !policy_legal))
            boundary_q <= 1;

    frame_result_manager #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) result_manager (
        .core_clk, .rst, .halt(halt || boundary_q || retire_q || owner_quarantined),
        .pause_new_requests, .producer_quarantined,
        .request_valid, .request_ready, .request_token, .request_source,
        .request_origin, .request_cj, .request_render, .cancel_valid, .cancel_token,
        .job_valid, .job_ready, .job_bundle,
        .producer_done_valid, .producer_done_ready, .producer_done_result,
        .producer_done_origin, .producer_done_scope, .producer_outcome,
        .producer_reason, .producer_pixels, .producer_discard,
        .producer_cancel_valid, .producer_cancel_result, .producer_cancel_scope,
        .cmd_valid(result_cmd_valid), .cmd_ready(result_cmd_ready), .command(result_command),
        .offer_sequence(result_sequence), .reply_valid(result_reply_valid),
        .reply_ready(result_reply_ready), .reply(result_reply),
        .sequence_valid, .sequence_ready, .sequence_value, .sequence_exhausted,
        .route_valid, .route_ready, .route_request, .route_reply_valid,
        .route_reply_ready, .route_reply, .route_cancel_valid, .route_cancel_sequence,
        .applied_valid, .applied_ready, .applied_sequence, .applied_bundle, .previous_result,
        .completion_valid, .completion_ready, .completion_token,
        .completion_outcome, .completion_status, .completion_reason, .completion_bundle,
        .quarantined(result_q), .idle(result_idle)
    );
    frame_result_retire result_retire (
        .core_clk, .rst, .halt(halt || boundary_q || result_q || owner_quarantined),
        .applied_valid, .applied_ready, .applied_sequence, .applied_bundle, .previous_result,
        .oldclosed_valid, .oldclosed_ready, .oldclosed_ref,
        .cmd_valid(retire_cmd_valid), .cmd_ready(retire_cmd_ready), .command(retire_command),
        .reply_valid(retire_reply_valid), .reply_ready(retire_reply_ready), .reply(retire_reply),
        .retired_valid, .retired_ready, .retired_ref, .root_retire_capacity,
        .quarantined(retire_q), .idle(retire_idle)
    );
    frame_owner_command_arbiter4 command_arbiter (
        .core_clk, .rst, .client_cmd_valid, .client_cmd_ready,
        .client_command, .client_offer_sequence(client_sequence),
        .client_reply_valid, .client_reply_ready, .client_reply,
        .owner_cmd_valid, .owner_cmd_ready, .owner_command, .owner_offer_sequence,
        .owner_reply_valid, .owner_reply_ready, .owner_reply, .idle(owner_bus_idle)
    );
endmodule
