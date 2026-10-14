// FP06：这是消费者闭合记录，不替代owner账本，也不从超时猜测释放。
module frame_result_retire (
    input logic core_clk, rst, halt,
    input logic applied_valid,
    output wire applied_ready,
    input logic [63:0] applied_sequence,
    input logic [941:0] applied_bundle,
    input logic [63:0] previous_result,
    input logic oldclosed_valid,
    output wire oldclosed_ready,
    input logic [386:0] oldclosed_ref,
    output logic cmd_valid,
    input logic cmd_ready,
    output logic [940:0] command,
    input logic reply_valid,
    output wire reply_ready,
    input logic [941:0] reply,
    output wire retired_valid,
    input logic retired_ready,
    output wire [386:0] retired_ref,
    output wire root_retire_capacity,
    output logic quarantined,
    output wire idle
);
    import frame_owner_pkg::*;
    typedef enum logic [1:0] {EMPTY, ACTIVE, RETIRING} kind_t;
    typedef enum logic [1:0] {IDLE, REQUEST, REPLY, EVENT} state_t;
    kind_t kind [0:2];
    logic [386:0] reference_id [0:2];
    logic [141:0] config_job [0:2];
    logic closed [0:2];
    state_t state;
    logic [1:0] selected;
    logic [386:0] event_ref;
    reply_t applied_view, reply_view;
    command_t command_view;
    integer active_slot, active_count, retiring_count, closed_slot;
    logic applied_matches, reply_matches;

    assign applied_view = applied_bundle;
    assign reply_view = reply;
    assign command = command_view;
    assign applied_ready = !rst && !halt && !quarantined && state == IDLE;
    assign oldclosed_ready = !rst;
    assign reply_ready = !rst && state == REPLY;
    assign retired_valid = !rst && state == EVENT;
    assign retired_ref = event_ref;
    assign idle = state == IDLE;
    assign root_retire_capacity = !rst && !halt && !quarantined && retiring_count < 2;

    always_comb begin
        active_slot = -1;
        active_count = 0;
        retiring_count = 0;
        closed_slot = -1;
        for (integer slot = 0; slot < 3; slot = slot + 1) begin
            if (kind[slot] == ACTIVE) begin
                active_slot = slot;
                active_count = active_count + 1;
            end
            if (kind[slot] == RETIRING) begin
                retiring_count = retiring_count + 1;
                if (closed[slot] && closed_slot < 0) closed_slot = slot;
            end
        end
        applied_matches = applied_view.op == APPLY && applied_view.status == OK &&
                          applied_sequence != 0 && applied_view.result_slot < 3 &&
                          applied_view.result_handle != 0 && active_count <= 1;
        // 必须先判槽范围，不能让非法slot3成为数组访问。
        if (applied_view.result_slot < 3)
            applied_matches = applied_matches && kind[applied_view.result_slot] == EMPTY;
        if (active_slot < 0)
            applied_matches = applied_matches && previous_result == 0;
        else
            applied_matches = applied_matches &&
                              previous_result == reference_id[active_slot][322:259];

        command_view = '0;
        command_view.op = RETIRE;
        command_view.flags = 8'h0a;
        command_view.source_handle = reference_id[selected][194:131];
        command_view.result_handle = reference_id[selected][322:259];
        command_view.origin = reference_id[selected][194:0];
        command_view.cj = config_job[selected];
        command_view.policy = reference_id[selected][258:195];
        cmd_valid = !rst && state == REQUEST;
        reply_matches = reply_view.op == RETIRE && reply_view.status == OK &&
                        reply_view.source_handle == command_view.source_handle &&
                        reply_view.result_handle == command_view.result_handle &&
                        reply_view.origin == command_view.origin &&
                        reply_view.cj == command_view.cj &&
                        reply_view.policy == command_view.policy &&
                        reply_view.result_slot == selected &&
                        reply_view.source_slot == command_view.origin[2:0];
    end

    always_ff @(posedge core_clk) begin
        if (rst) begin
            state <= IDLE;
            selected <= 0;
            event_ref <= 0;
            quarantined <= 0;
            for (integer slot = 0; slot < 3; slot = slot + 1) begin
                kind[slot] <= EMPTY;
                reference_id[slot] <= 0;
                config_job[slot] <= 0;
                closed[slot] <= 0;
            end
        end else begin
            if (halt) quarantined <= 1;
            // 同沿early closed与新APPLY可共同成立：旧槽只改kind，保留closed事实。
            if (oldclosed_valid && oldclosed_ready)
                for (integer slot = 0; slot < 3; slot = slot + 1)
                    if (kind[slot] != EMPTY && oldclosed_ref == reference_id[slot])
                        closed[slot] <= 1;
            case (state)
                IDLE: begin
                    if (applied_valid && applied_ready) begin
                        if (!applied_matches) quarantined <= 1;
                        else begin
                            if (active_slot >= 0) kind[active_slot] <= RETIRING;
                            kind[applied_view.result_slot] <= ACTIVE;
                            reference_id[applied_view.result_slot] <=
                                {applied_sequence, applied_view.result_handle,
                                 applied_view.policy, applied_view.origin};
                            config_job[applied_view.result_slot] <= applied_view.cj;
                            closed[applied_view.result_slot] <= 0;
                        end
                    end else if (!halt && !quarantined && closed_slot >= 0) begin
                        selected <= 2'(closed_slot);
                        state <= REQUEST;
                    end
                end
                REQUEST: if (cmd_valid && cmd_ready) state <= REPLY;
                REPLY: if (reply_valid && reply_ready) begin
                    if (!reply_matches) begin
                        quarantined <= 1;
                        state <= IDLE;
                    end else begin
                        event_ref <= reference_id[selected];
                        kind[selected] <= EMPTY;
                        closed[selected] <= 0;
                        state <= EVENT;
                    end
                end
                EVENT: if (retired_valid && retired_ready) state <= IDLE;
                default: begin quarantined <= 1; state <= IDLE; end
            endcase
        end
    end
endmodule
