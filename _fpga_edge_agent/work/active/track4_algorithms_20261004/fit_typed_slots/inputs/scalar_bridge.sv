// FT01/06/07，主卡D2/E6：桥拥有私有请求身份及缓存，关闭child后才发布结果。
module scalar_bridge #(
    parameter logic [63:0] RESET_SEQUENCE=64'd0
)(
    input logic clk,rst,
    input logic cmd_valid,input logic [405:0] cmd_body,output logic cmd_ready,
    output logic result_valid,output logic [402:0] result_body,input logic result_ready,
    input logic abort,output logic bridge_quiet,
    output logic child_req_valid,output logic [621:0] child_req_body,input logic child_req_ready,
    input logic child_rsp_valid,input logic [584:0] child_rsp_body,output logic child_rsp_ready,
    output logic child_cancel_valid,output logic [175:0] child_cancel_id,input logic child_quiet
);
    import fit_protocol_pkg::*;
    typedef enum logic [2:0] {IDLE,CMD_CHECK,SEND,WAIT_CHILD,CHILD_CLOSE,RESULT_HELD} bridge_state_t;
    bridge_state_t state;
    logic [405:0] accepted_command;
    logic [402:0] cached_result;
    logic [63:0] next_sequence,pending_sequence;
    logic exhausted,sticky_abort;
    logic [175:0] offered_id,pending_id;
    logic raw_matrix_ok,raw_identity_ok;
    logic [1:0] raw_outcome;
    logic [7:0] raw_reason;

    always_comb begin
        offered_id={accepted_command[7:0],next_sequence,8'd0,32'd1,32'd0,32'd1};
        pending_id={accepted_command[7:0],pending_sequence,8'd0,32'd1,32'd0,32'd1};
        cmd_ready=!rst && state==IDLE && child_quiet;
        bridge_quiet=cmd_ready;
        result_valid=!rst && state==RESULT_HELD;
        result_body=cached_result;
        child_req_valid=!rst && state==SEND;
        child_req_body={16'd0,accepted_command[214+:192],accepted_command[22+:192],
                        accepted_command[13+:9],accepted_command[12],accepted_command[11],
                        2'd0,accepted_command[8+:3],8'd1,11'd1080,11'd1920,offered_id};
        child_rsp_ready=!rst && state==WAIT_CHILD;
        child_cancel_valid=!rst && (state==SEND || state==WAIT_CHILD) && (sticky_abort || abort);
        child_cancel_id=state==SEND?offered_id:pending_id;
        raw_outcome=child_rsp_body[OUTCOME_LO+:2]; raw_reason=child_rsp_body[REASON_LO+:8];
        raw_identity_ok=child_rsp_body[175:0]==pending_id &&
            child_rsp_body[176+:5]=={2'd0,accepted_command[8+:3]} &&
            child_rsp_body[181+:9]==accepted_command[13+:9];
        raw_matrix_ok=(raw_outcome==VALUE && raw_reason==NONE) ||
            (raw_outcome==FRAME_FAIL && child_rsp_body[VALUE_LO+:385]==0 &&
             (raw_reason==FORMAT || raw_reason==COORD || raw_reason==OVERFLOW ||
              raw_reason==DIV_ZERO || raw_reason==UNSUPPORTED || raw_reason==INTERNAL)) ||
            (raw_outcome==CANCEL_DROP && raw_reason==NONE &&
             child_rsp_body[VALUE_LO+:385]==0 && (sticky_abort || abort));
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state<=IDLE; next_sequence<=RESET_SEQUENCE; pending_sequence<=0;
            exhausted<=0; sticky_abort<=0; accepted_command<=0; cached_result<=0;
        end else begin
            if(state!=IDLE && abort) sticky_abort<=1;
            case(state)
                IDLE:if(cmd_valid && cmd_ready) begin
                    accepted_command<=cmd_body; sticky_abort<=abort; state<=CMD_CHECK;
                end
                CMD_CHECK:begin
                    if(sticky_abort || abort) begin
                        cached_result<={385'd0,NONE,CANCEL_DROP,accepted_command[7:0]}; state<=RESULT_HELD;
                    end else if(exhausted) begin
                        cached_result<={385'd0,CAPACITY,FRAME_FAIL,accepted_command[7:0]}; state<=RESULT_HELD;
                    end else state<=SEND;
                end
                SEND:if(child_req_valid && child_req_ready) begin
                    pending_sequence<=next_sequence;
                    if(&next_sequence) exhausted<=1;
                    else next_sequence<=next_sequence+64'd1;
                    state<=WAIT_CHILD;
                end
                WAIT_CHILD:if(child_rsp_valid && child_rsp_ready) begin
                    if(sticky_abort || abort)
                        cached_result<={385'd0,NONE,CANCEL_DROP,accepted_command[7:0]};
                    else if(!raw_identity_ok || !raw_matrix_ok)
                        cached_result<={385'd0,INTERNAL,FRAME_FAIL,accepted_command[7:0]};
                    else cached_result<={child_rsp_body[VALUE_LO+:385],raw_reason,raw_outcome,accepted_command[7:0]};
                    state<=CHILD_CLOSE;
                end
                CHILD_CLOSE:begin
                    if(sticky_abort || abort)
                        cached_result<={385'd0,NONE,CANCEL_DROP,accepted_command[7:0]};
                    if(child_quiet) state<=RESULT_HELD;
                end
                RESULT_HELD:if(result_valid && result_ready) state<=IDLE;
                default:state<=IDLE;
            endcase
        end
    end
endmodule
