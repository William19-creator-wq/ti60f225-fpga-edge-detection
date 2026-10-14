// FP01..05：一个真实Result事务；中文状态草图见design-v1 E/MOD1。
module frame_result_manager #(
    parameter integer WIDTH = 1920, HEIGHT = 1080
)(
    input logic core_clk, rst, halt, pause_new_requests,
    input logic producer_quarantined,
    input logic request_valid, output wire request_ready,
    input logic [63:0] request_token, request_source,
    input logic [194:0] request_origin,
    input logic [141:0] request_cj,
    input logic [111:0] request_render,
    input logic cancel_valid, input logic [63:0] cancel_token,
    output wire job_valid, input logic job_ready,
    output wire [941:0] job_bundle,
    input logic producer_done_valid, output wire producer_done_ready,
    input logic [63:0] producer_done_result,
    input logic [194:0] producer_done_origin,
    input logic [95:0] producer_done_scope,
    input logic [1:0] producer_outcome,
    input logic [31:0] producer_reason,
    input logic [21:0] producer_pixels, producer_discard,
    output logic producer_cancel_valid,
    output wire [63:0] producer_cancel_result,
    output wire [95:0] producer_cancel_scope,
    output wire cmd_valid, input logic cmd_ready,
    output wire [940:0] command,
    output wire [63:0] offer_sequence,
    input logic reply_valid, output wire reply_ready,
    input logic [941:0] reply,
    input logic sequence_valid, output wire sequence_ready,
    input logic [63:0] sequence_value, input logic sequence_exhausted,
    output wire route_valid, input logic route_ready,
    output wire [1136:0] route_request,
    input logic route_reply_valid, output wire route_reply_ready,
    input logic [1206:0] route_reply,
    output logic route_cancel_valid,
    output wire [63:0] route_cancel_sequence,
    output wire applied_valid, input logic applied_ready,
    output wire [63:0] applied_sequence,
    output wire [941:0] applied_bundle,
    output wire [63:0] previous_result,
    output wire completion_valid, input logic completion_ready,
    output wire [63:0] completion_token,
    output wire [1:0] completion_outcome,
    output wire [3:0] completion_status,
    output wire [63:0] completion_reason,
    output wire [941:0] completion_bundle,
    output logic quarantined,
    output wire idle
);
    import frame_owner_pkg::*;
    import display_handoff_pkg::*;
    localparam logic [21:0] PIXELS = 22'(WIDTH*HEIGHT);
    typedef enum logic [4:0] {
        IDLE, ALLOC_REQUEST, ALLOC_REPLY, START_JOB, WAIT_JOB,
        END_REQUEST, END_REPLY, SEQUENCE, OFFER_REQUEST, OFFER_REPLY,
        ROUTE_REQUEST, ROUTE_REPLY, APPLY_REQUEST, APPLY_REPLY, APPLIED,
        DROP_REQUEST, DROP_REPLY, FINISHED, Q
    } state_t;
    state_t state;
    reply_t context_bundle, answer;
    command_t command_view;
    route_request_t route_view;
    route_response_t route_answer;
    logic [63:0] token, sequence_id, prior_result;
    logic [7:0] end_flags, drop_flags;
    logic [1:0] outcome;
    logic [3:0] status;
    logic [63:0] reason;
    logic cancel_seen, actor_started, actor_cancel_sent, route_sent, route_cancel_sent;
    wire matching_cancel = cancel_valid && cancel_token == token &&
                           state != IDLE && state != FINISHED && state != Q;

    assign answer = reply;
    assign route_answer = route_reply;
    assign command = command_view;
    assign route_request = route_view;
    assign idle = state == IDLE;
    assign request_ready = !rst && state == IDLE && !pause_new_requests &&
                           !halt && !producer_quarantined && !quarantined;
    assign job_valid = !rst && state == START_JOB;
    assign job_bundle = context_bundle;
    assign producer_done_ready = !rst && state == WAIT_JOB;
    assign producer_cancel_result = context_bundle.result_handle;
    assign producer_cancel_scope = context_bundle.cj[95:0];
    assign cmd_valid = !rst && (state == ALLOC_REQUEST || state == END_REQUEST ||
                       state == OFFER_REQUEST || state == APPLY_REQUEST || state == DROP_REQUEST);
    assign reply_ready = !rst && (state == ALLOC_REPLY || state == END_REPLY ||
                         state == OFFER_REPLY || state == APPLY_REPLY || state == DROP_REPLY);
    assign offer_sequence = sequence_id;
    assign sequence_ready = !rst && state == SEQUENCE && !sequence_exhausted &&
                            !cancel_seen && !matching_cancel && !halt && !quarantined;
    assign route_valid = !rst && state == ROUTE_REQUEST;
    assign route_reply_ready = !rst && state == ROUTE_REPLY;
    assign route_cancel_sequence = sequence_id;
    assign applied_valid = !rst && state == APPLIED;
    assign applied_sequence = sequence_id;
    assign applied_bundle = context_bundle;
    assign previous_result = prior_result;
    assign completion_valid = !rst && state == FINISHED;
    assign completion_token = token;
    assign completion_outcome = outcome;
    assign completion_status = status;
    assign completion_reason = reason;
    assign completion_bundle = context_bundle;

    wire closing_cancel = cancel_seen || matching_cancel;
    wire uncertain = halt || producer_quarantined || quarantined;
    wire done_matches = producer_done_result == context_bundle.result_handle &&
                        producer_done_origin == context_bundle.origin &&
                        producer_done_scope == context_bundle.cj[95:0];
    wire good_count = producer_pixels == PIXELS && producer_discard == 0;
    wire same_reply = answer.source_handle == context_bundle.source_handle &&
                      answer.result_handle == context_bundle.result_handle &&
                      answer.origin == context_bundle.origin &&
                      answer.cj == context_bundle.cj && answer.body == context_bundle.body &&
                      answer.policy == context_bundle.policy &&
                      answer.source_slot == context_bundle.source_slot &&
                      answer.result_slot == context_bundle.result_slot;
    wire same_route = route_answer.kind == HC_OFFER &&
                      route_answer.sequence_id == sequence_id && route_answer.cause == 0 &&
                      route_answer.policy == context_bundle.policy &&
                      route_answer.bundle == context_bundle;

    always_comb begin
        command_view = '0;
        command_view.source_handle = context_bundle.source_handle;
        command_view.result_handle = context_bundle.result_handle;
        command_view.origin = context_bundle.origin;
        command_view.cj = context_bundle.cj;
        command_view.body = context_bundle.body;
        command_view.policy = context_bundle.policy;
        case (state)
            ALLOC_REQUEST: command_view.op = ALLOC_RESULT;
            END_REQUEST: begin command_view.op = RESULT_END; command_view.flags = end_flags; end
            OFFER_REQUEST: command_view.op = OFFER;
            APPLY_REQUEST: command_view.op = APPLY;
            DROP_REQUEST: begin command_view.op = DROP_RESULT; command_view.flags = drop_flags; end
            default: command_view.op = ALLOC_RESULT;
        endcase
        route_view = '0;
        route_view.kind = HC_OFFER;
        route_view.sequence_id = sequence_id;
        route_view.target_policy = context_bundle.policy;
        route_view.bundle = context_bundle;
    end

    // 只在公开END之前调用：后续halt/cancel不能改写held flags及终态。
    task automatic prepare_end(input logic [7:0] flags,
                               input logic [1:0] next_outcome,
                               input logic [63:0] next_reason);
        begin
            end_flags <= flags;
            outcome <= next_outcome;
            reason <= next_reason;
            state <= END_REQUEST;
        end
    endtask
    task automatic isolate;
        begin quarantined <= 1; reason[34] <= 1; state <= Q; end
    endtask
    task automatic prepare_drop(input logic [7:0] flags,
                                input logic [1:0] next_outcome,
                                input logic [3:0] next_status,
                                input logic [63:0] next_reason);
        begin
            drop_flags <= flags;
            outcome <= next_outcome;
            status <= next_status;
            reason <= next_reason;
            state <= DROP_REQUEST;
        end
    endtask

    always_ff @(posedge core_clk) begin
        if (rst) begin
            state <= IDLE; context_bundle <= '0;
            token <= 0; sequence_id <= 0; prior_result <= 0;
            end_flags <= 0; drop_flags <= 0; outcome <= 0; status <= OK; reason <= 0;
            cancel_seen <= 0; actor_started <= 0; actor_cancel_sent <= 0;
            route_sent <= 0; route_cancel_sent <= 0;
            producer_cancel_valid <= 0; route_cancel_valid <= 0; quarantined <= 0;
        end else begin
            producer_cancel_valid <= 0;
            route_cancel_valid <= 0;
            if (halt || producer_quarantined) quarantined <= 1;
            if (matching_cancel) cancel_seen <= 1;
            if (state == WAIT_JOB && actor_started && !actor_cancel_sent &&
                (closing_cancel || uncertain)) begin
                producer_cancel_valid <= 1;
                actor_cancel_sent <= 1;
            end
            if (state == ROUTE_REPLY && route_sent && !route_cancel_sent && closing_cancel) begin
                route_cancel_valid <= 1;
                route_cancel_sent <= 1;
            end
            case (state)
                IDLE: if (request_valid && request_ready) begin
                    context_bundle <= '0;
                    context_bundle.source_handle <= request_source;
                    context_bundle.origin <= request_origin;
                    context_bundle.cj <= request_cj;
                    context_bundle.body[111:0] <= request_render;
                    token <= request_token; sequence_id <= 0; prior_result <= 0;
                    outcome <= 0; status <= OK; reason <= 0; end_flags <= 0; drop_flags <= 0;
                    cancel_seen <= 0; actor_started <= 0; actor_cancel_sent <= 0;
                    route_sent <= 0; route_cancel_sent <= 0;
                    state <= ALLOC_REQUEST;
                end
                ALLOC_REQUEST: if (cmd_valid && cmd_ready) state <= ALLOC_REPLY;
                ALLOC_REPLY: if (reply_valid && reply_ready) begin
                    if (answer.op != ALLOC_RESULT) isolate();
                    else if (answer.status != OK) begin
                        context_bundle <= answer; status <= answer.status;
                        outcome <= 1; state <= FINISHED;
                    end else if (answer.source_handle == 0 || answer.result_handle == 0 ||
                                 answer.source_slot >= 6 || answer.result_slot >= 3 ||
                                 answer.origin[194:131] != answer.source_handle ||
                                 answer.origin[66:3] != answer.source_handle ||
                                 answer.origin[2:0] != answer.source_slot ||
                                 answer.cj[141:64] != context_bundle.cj[141:64] ||
                                 answer.cj[63:0] != answer.origin[130:67] ||
                                 answer.body[111:0] != context_bundle.body[111:0]) isolate();
                    else begin
                        context_bundle <= answer;
                        if (uncertain) prepare_end(0, 3, 64'h0000000400000000);
                        else if (closing_cancel) prepare_end(8'h06, 2, 64'h0000000200000000);
                        else if (answer.body[111:109] == 1 || answer.body[111:109] == 2)
                            prepare_end(8'h07, 0, 0);
                        else state <= START_JOB;
                    end
                end
                START_JOB: if (job_valid && job_ready) begin
                    actor_started <= 1;
                    if (uncertain) prepare_end(0, 3, 64'h0000000400000000);
                    else state <= WAIT_JOB;
                end
                WAIT_JOB: begin
                    if (producer_done_valid && producer_done_ready && done_matches) begin
                        if (producer_outcome == 3 || uncertain)
                            prepare_end(0, 3, {32'd4, producer_reason});
                        else if (producer_outcome == 1 || (producer_outcome == 0 && !good_count))
                            prepare_end(8'h06, 1,
                                {30'd0, closing_cancel, (producer_outcome == 0 && !good_count), producer_reason});
                        else if (producer_outcome == 2 || closing_cancel)
                            prepare_end(8'h06, 2, {32'd2, producer_reason});
                        else prepare_end(8'h07, 0, {32'd0, producer_reason});
                    end else if (uncertain) prepare_end(0, 3, 64'h0000000400000000);
                end
                END_REQUEST: if (cmd_valid && cmd_ready) state <= END_REPLY;
                END_REPLY: if (reply_valid && reply_ready) begin
                    if (end_flags == 0 || answer.op != RESULT_END || answer.status != OK || !same_reply)
                        isolate();
                    else begin
                        context_bundle <= answer;
                        if (!end_flags[0]) state <= FINISHED;
                        else if (closing_cancel)
                            prepare_drop(8'h02, 2, OK, reason | 64'h0000000200000000);
                        else if (uncertain)
                            prepare_drop(8'h02, 1, QUARANTINED, reason | 64'h0000000400000000);
                        else state <= SEQUENCE;
                    end
                end
                SEQUENCE: begin
                    if (closing_cancel) prepare_drop(8'h02, 2, OK, reason | 64'h0000000200000000);
                    else if (uncertain) prepare_drop(8'h02, 1, QUARANTINED, reason | 64'h0000000400000000);
                    else if (sequence_exhausted) prepare_drop(8'h02, 1, EXHAUSTED, reason);
                    else if (sequence_valid && sequence_ready) begin
                        if (sequence_value == 0) begin
                            quarantined <= 1;
                            prepare_drop(8'h02, 1, FIELD, reason | 64'h0000000400000000);
                        end else begin sequence_id <= sequence_value; state <= OFFER_REQUEST; end
                    end
                end
                OFFER_REQUEST: if (cmd_valid && cmd_ready) state <= OFFER_REPLY;
                OFFER_REPLY: if (reply_valid && reply_ready) begin
                    if (answer.op != OFFER) isolate();
                    else if (answer.status != OK)
                        // OFFER拒绝未把R_DONE交给显示；真实DROP回执仍是释放前提。
                        prepare_drop(8'h02, 1, answer.status, reason);
                    else if (!same_reply || uncertain) isolate();
                    else begin context_bundle <= answer; state <= ROUTE_REQUEST; end
                end
                ROUTE_REQUEST: if (route_valid && route_ready) begin
                    route_sent <= 1;
                    state <= ROUTE_REPLY;
                end
                ROUTE_REPLY: if (route_reply_valid && route_reply_ready) begin
                    if (!same_route) isolate();
                    else if (route_answer.status == HC_OK && route_answer.has_active &&
                             !route_answer.candidate_closed) begin
                        prior_result <= route_answer.previous_result;
                        state <= APPLY_REQUEST;
                    end else if (route_answer.status == HC_CANCELED && route_answer.candidate_closed)
                        prepare_drop(8'h0a, 2, OK, reason | 64'h0000000200000000);
                    else isolate();
                end
                APPLY_REQUEST: if (cmd_valid && cmd_ready) state <= APPLY_REPLY;
                APPLY_REPLY: if (reply_valid && reply_ready) begin
                    if (answer.op != APPLY || answer.status != OK || !same_reply) isolate();
                    else begin context_bundle <= answer; state <= APPLIED; end
                end
                APPLIED: if (applied_valid && applied_ready) state <= FINISHED;
                DROP_REQUEST: if (cmd_valid && cmd_ready) state <= DROP_REPLY;
                DROP_REPLY: if (reply_valid && reply_ready) begin
                    if (answer.op != DROP_RESULT || answer.status != OK || !same_reply) isolate();
                    else begin context_bundle <= answer; state <= FINISHED; end
                end
                FINISHED: if (completion_valid && completion_ready) state <= IDLE;
                Q: state <= Q;
                default: isolate();
            endcase
        end
    end
    // synthesis translate_off
    initial if (WIDTH < 4 || WIDTH > 1920 || WIDTH % 2 != 0 ||
                HEIGHT < 2 || HEIGHT > 1080 || HEIGHT % 2 != 0)
        $fatal(1, "Frame result geometry");
    // synthesis translate_on
endmodule
