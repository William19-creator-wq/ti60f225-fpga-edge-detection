// FT01/06/07，主卡D2/E6：桥拥有私有请求身份及缓存，关闭child后才发布结果。
module scalar_bridge #(
    parameter logic [63:0] RESET_SEQUENCE=64'd0,
    parameter bit BORROW_COMMAND=0,BORROW_RESULT=0,CLOSE_SEQUENCE=0,CHILD_RETURN_WORDS=0
)(
    input logic clk,rst,
    input logic cmd_valid,input logic [405:0] cmd_body,output logic cmd_ready,
    output logic result_valid,output logic [402:0] result_body,input logic result_ready,
    input logic abort,output logic bridge_quiet,
    output logic child_req_valid,output logic [621:0] child_req_body,input logic child_req_ready,
    input logic child_rsp_valid,input logic [584:0] child_rsp_body,output logic child_rsp_ready,
    output logic child_cancel_valid,output logic [175:0] child_cancel_id,input logic child_quiet,
    input wire [4:0] result_word_index,output wire [15:0] result_word16,
    output wire [4:0] child_rsp_word_index,input wire [15:0] child_rsp_word16
);
    import fit_protocol_pkg::*;
    typedef enum logic [2:0] {IDLE,CMD_CHECK,SEND,WAIT_CHILD,CHILD_CLOSE,RESULT_HELD} bridge_state_t;
    bridge_state_t state;
    wire [405:0] accepted_command;
    logic [405:0] command_snapshot;
    logic [384:0] result_snapshot;
    logic [17:0] result_metadata;
    wire [384:0] result_value=BORROW_RESULT?
        (result_metadata[9:8]==VALUE?child_rsp_body[VALUE_LO+:385]:385'd0):result_snapshot;
    wire [402:0] cached_result={result_value,result_metadata};
    generate if(CHILD_RETURN_WORDS&&BORROW_RESULT)begin:borrowed_return_word
        // 与完整BORROW_RESULT同一元数据门：abort/耗尽/错ID会置零，不能借child旧成功值。
        // RESULT_HELD在child quiet后仍读取；此口不能依child_rsp_valid关闭。
        assign child_rsp_word_index=result_word_index;
        assign result_word16=result_metadata[9:8]==VALUE?child_rsp_word16:16'd0;
    end else begin:no_return_word_sideband
        // 默认缓存/完整正文仍走原result_body；新未连接端口不参与原流程。
        assign child_rsp_word_index=5'd0;
        assign result_word16=16'd0;
    end endgenerate
    // 只在FIT内部启用：父published_command到result_fire保持；child full到下次调用保持。
    assign accepted_command=BORROW_COMMAND?cmd_body:command_snapshot;
    logic [63:0] next_sequence;
    wire [63:0] pending_sequence;
    generate if(CLOSE_SEQUENCE)begin:shared_sequence
        // SEND至child quiet保留本次实际ID；关闭后才推进下一ID，省去第二份64位持有。
        assign pending_sequence=next_sequence;
    end else begin:copied_sequence
        logic [63:0] snapshot;
        assign pending_sequence=snapshot;
        always_ff @(posedge clk)begin
            if(rst)snapshot<=0;
            else if(state==SEND&&child_req_valid&&child_req_ready)snapshot<=next_sequence;
        end
    end endgenerate
    logic exhausted,sticky_abort;
    logic [175:0] offered_id,pending_id;
    logic raw_matrix_ok,raw_identity_ok;
    logic [1:0] raw_outcome;
    logic [7:0] raw_reason;
    task automatic save_result(input logic [384:0] value,input logic [7:0] why,
                               input logic [1:0] outcome);
        begin
            result_snapshot<=value;result_metadata<={why,outcome,accepted_command[7:0]};
        end
    endtask

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
            state<=IDLE; next_sequence<=RESET_SEQUENCE;
            exhausted<=0; sticky_abort<=0; command_snapshot<=0; result_snapshot<=0;result_metadata<=0;
        end else begin
            if(state!=IDLE && abort) sticky_abort<=1;
            case(state)
                IDLE:if(cmd_valid && cmd_ready) begin
                    command_snapshot<=cmd_body; sticky_abort<=abort; state<=CMD_CHECK;
                end
                CMD_CHECK:begin
                    if(sticky_abort || abort) begin
                        save_result(385'd0,NONE,CANCEL_DROP);state<=RESULT_HELD;
                    end else if(exhausted) begin
                        save_result(385'd0,CAPACITY,FRAME_FAIL);state<=RESULT_HELD;
                    end else state<=SEND;
                end
                SEND:if(child_req_valid && child_req_ready) begin
                    if(&next_sequence) exhausted<=1;
                    else if(!CLOSE_SEQUENCE) next_sequence<=next_sequence+64'd1;
                    state<=WAIT_CHILD;
                end
                WAIT_CHILD:if(child_rsp_valid && child_rsp_ready) begin
                    if(sticky_abort || abort)
                        save_result(385'd0,NONE,CANCEL_DROP);
                    else if(!raw_identity_ok || !raw_matrix_ok)
                        save_result(385'd0,INTERNAL,FRAME_FAIL);
                    else save_result(child_rsp_body[VALUE_LO+:385],raw_reason,raw_outcome);
                    state<=CHILD_CLOSE;
                end
                CHILD_CLOSE:begin
                    if(sticky_abort || abort)
                        save_result(385'd0,NONE,CANCEL_DROP);
                    if(child_quiet)begin
                        if(CLOSE_SEQUENCE&&!exhausted)next_sequence<=next_sequence+64'd1;
                        state<=RESULT_HELD;
                    end
                end
                RESULT_HELD:if(result_valid && result_ready) state<=IDLE;
                default:state<=IDLE;
            endcase
        end
    end
endmodule
