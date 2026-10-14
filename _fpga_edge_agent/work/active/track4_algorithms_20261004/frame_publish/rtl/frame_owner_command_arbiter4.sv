// FP07 / IF07：接受后保存整包；轮转只在真实回执交付后改变。
module frame_owner_command_arbiter4 (
    input logic core_clk, rst,
    input logic [3:0] client_cmd_valid,
    output logic [3:0] client_cmd_ready,
    input logic [3:0][940:0] client_command,
    input logic [3:0][63:0] client_offer_sequence,
    output logic [3:0] client_reply_valid,
    input logic [3:0] client_reply_ready,
    output logic [3:0][941:0] client_reply,
    output logic owner_cmd_valid,
    input logic owner_cmd_ready,
    output logic [940:0] owner_command,
    output logic [63:0] owner_offer_sequence,
    input logic owner_reply_valid,
    output logic owner_reply_ready,
    input logic [941:0] owner_reply,
    output wire idle
);
    typedef enum logic [1:0] {IDLE, REQUEST, REPLY} state_t;
    state_t state;
    logic [1:0] turn, selected, choice;
    logic choice_valid;
    logic [940:0] held_command;
    logic [63:0] held_sequence;
    integer candidate;
    assign idle = state == IDLE;

    always_comb begin
        choice_valid = 0;
        choice = turn;
        candidate = 0;
        for (integer offset = 0; offset < 4; offset = offset + 1) begin
            candidate = (int'(turn) + offset) & 3;
            if (!choice_valid && client_cmd_valid[candidate]) begin
                choice_valid = 1;
                choice = 2'(candidate);
            end
        end
        client_cmd_ready = 0;
        client_reply_valid = 0;
        client_reply = '0;
        owner_cmd_valid = !rst && state == REQUEST;
        owner_command = held_command;
        owner_offer_sequence = held_sequence;
        owner_reply_ready = 0;
        if (!rst && state == IDLE && choice_valid)
            client_cmd_ready[choice] = 1;
        if (!rst && state == REPLY) begin
            client_reply_valid[selected] = owner_reply_valid;
            client_reply[selected] = owner_reply;
            owner_reply_ready = client_reply_ready[selected];
        end
    end

    always_ff @(posedge core_clk) begin
        if (rst) begin
            state <= IDLE;
            turn <= 0;
            selected <= 0;
            held_command <= 0;
            held_sequence <= 0;
        end else case (state)
            IDLE: if (choice_valid && client_cmd_ready[choice]) begin
                selected <= choice;
                held_command <= client_command[choice];
                held_sequence <= client_offer_sequence[choice];
                state <= REQUEST;
            end
            REQUEST: if (owner_cmd_valid && owner_cmd_ready) state <= REPLY;
            REPLY: if (owner_reply_valid && owner_reply_ready) begin
                turn <= selected + 2'd1;
                state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule
