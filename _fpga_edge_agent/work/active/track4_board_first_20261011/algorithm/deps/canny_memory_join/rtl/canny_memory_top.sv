// MJ01/03/04：计算结果仅在cache FLUSH + queue end实际排空后终结。
module canny_memory_top #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080
)(
    input logic clk,rst,
    input logic job_valid,output wire job_ready,input logic [63:0] job_id,
    input logic [31:0] state_base,queue_base,
    input logic cancel_valid,input logic [63:0] cancel_id,
    output wire pixel_valid,input logic pixel_ready,output wire [20:0] pixel_index,
    output wire pixel_edge,output wire [63:0] pixel_job_id,
    output wire done_valid,input logic done_ready,output wire [63:0] done_job_id,
    output logic [1:0] outcome,output logic [7:0] reason,
    output logic [21:0] enqueue_count,pop_count,output_count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    output wire [1023:0] flat_wdata,output wire [1:0] flat_select,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    localparam integer unsigned N=WIDTH*HEIGHT;
    localparam logic [32:0] STATE_BYTES=33'(((N+255)/256)*64),QUEUE_BYTES=33'(((N+15)/16)*64);
    typedef enum logic [3:0] {IDLE,CFG_CACHE_REQ,CFG_CACHE_WAIT,CFG_QUEUE_REQ,CFG_QUEUE_WAIT,
        START,RUN,FLUSH_REQ,FLUSH_WAIT,SEAL_REQ,SEAL_WAIT,DONE,FLUSH_DECIDE} control_t;
    control_t control;
    logic [63:0] active_id;
    logic [31:0] saved_state_base,saved_queue_base;
    logic cancel_sticky,memory_error_sticky,close_error_sticky,queue_configured;
    wire matching_cancel=cancel_valid && cancel_id==((control==IDLE)?job_id:active_id);
    wire cancellation=cancel_sticky || matching_cancel;
    wire [32:0] state_end={1'b0,state_base}+STATE_BYTES,queue_end={1'b0,queue_base}+QUEUE_BYTES;
    wire regions_legal=state_base[5:0]==0 && queue_base[5:0]==0 &&
        state_end<=33'h100000000 && queue_end<=33'h100000000 &&
        (state_end<={1'b0,queue_base} || queue_end<={1'b0,state_base});
    wire abort_private=control!=IDLE && control!=DONE && cancellation;
    logic c_cfg_ready,c_cfg_rsp_valid,c_cfg_rsp_error,c_req_ready,c_rsp_valid,c_rsp_claimed,c_rsp_error,c_rsp_aborted;
    logic [1:0] c_rsp_old;
    logic claim_valid,claim_ready;logic [20:0] claim_index;
    logic q_cfg_ready,q_cfg_rsp_valid,q_cfg_rsp_error,q_req_ready,q_rsp_valid,q_rsp_error,q_rsp_aborted;
    logic [20:0] q_rsp_index;
    logic q_seal_ready,q_seal_rsp_valid,q_seal_rsp_error,q_seal_rsp_drained;
    logic [21:0] q_seal_head,q_seal_tail,q_seal_committed;
    logic c_quarantined,q_quarantined,a_quarantined;
    logic [63:0] c_active_id,q_active_id;
    logic h_job_ready,h_state_req_valid,h_state_rsp_ready,h_queue_req_valid,h_queue_rsp_ready;
    logic [1:0] h_state_op;logic [20:0] h_state_index,h_queue_index;
    logic h_queue_push,h_pixel_valid,h_done_valid;
    logic [1:0] h_outcome;logic [7:0] h_reason;
    logic [21:0] h_enqueue,h_pop,h_output;
    logic [63:0] h_done_id;
    logic [1:0] rpc_req_valid,rpc_req_ready,rpc_write,rpc_rsp_valid,rpc_rsp_ready;
    logic [31:0] rpc_addr[0:1];logic [511:0] rpc_wdata[0:1],rpc_rdata;
    logic rpc_error,rpc_drained;
    assign flat_wdata={rpc_wdata[1],rpc_wdata[0]};
    assign job_ready=!rst && control==IDLE && !quarantined;
    assign pixel_valid=!rst && control==RUN && h_pixel_valid;
    assign done_valid=!rst && control==DONE;
    assign done_job_id=active_id;
    assign quarantined=c_quarantined || q_quarantined || a_quarantined;

    canny_state_cache #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.RAM_TAGS(1'b1),.PACK_DATA_WAYS(1'b1),.DSP_WB(1'b1)) class_cache(
        .clk(clk),.rst(rst),.cfg_valid(control==CFG_CACHE_REQ),.cfg_ready(c_cfg_ready),.cfg_base(saved_state_base),.cfg_job_id(active_id),
        .cfg_rsp_valid(c_cfg_rsp_valid),.cfg_rsp_ready(control==CFG_CACHE_WAIT),.cfg_rsp_error(c_cfg_rsp_error),
        .abort_private_valid(abort_private),.abort_job_id(active_id),
        .req_valid((control==RUN && h_state_req_valid) || control==FLUSH_REQ),.req_ready(c_req_ready),
        .req_op(control==FLUSH_REQ ? 2'd3 : h_state_op),.req_index(control==FLUSH_REQ ? 21'd0 : h_state_index),
        .rsp_valid(c_rsp_valid),.rsp_ready(control==FLUSH_WAIT || (control==RUN && h_state_rsp_ready)),
        .rsp_old(c_rsp_old),.rsp_claimed(c_rsp_claimed),.rsp_error(c_rsp_error),.rsp_aborted(c_rsp_aborted),
        .claim_valid(claim_valid),.claim_ready(claim_ready),.claim_index(claim_index),
        .line_req_valid(rpc_req_valid[0]),.line_req_ready(rpc_req_ready[0]),.line_write(rpc_write[0]),.line_addr(rpc_addr[0]),.line_wdata(rpc_wdata[0]),
        .line_rsp_valid(rpc_rsp_valid[0]),.line_rsp_ready(rpc_rsp_ready[0]),.line_rdata(rpc_rdata),.line_error(rpc_error),.line_drained(rpc_drained),
        .quarantined(c_quarantined),.active_job_id(c_active_id));
    canny_work_queue #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.RAM_CARRY(1'b1),.DSP_WRITER(1'b1)) work_queue(
        .clk(clk),.rst(rst),.cfg_valid(control==CFG_QUEUE_REQ),.cfg_ready(q_cfg_ready),.cfg_base(saved_queue_base),.cfg_job_id(active_id),
        .cfg_rsp_valid(q_cfg_rsp_valid),.cfg_rsp_ready(control==CFG_QUEUE_WAIT),.cfg_rsp_error(q_cfg_rsp_error),
        .claim_valid(claim_valid),.claim_ready(claim_ready),.claim_index(claim_index),
        .queue_req_valid(control==RUN && h_queue_req_valid),.queue_req_ready(q_req_ready),.queue_push(h_queue_push),.queue_index(h_queue_index),
        .queue_rsp_valid(q_rsp_valid),.queue_rsp_ready(control==RUN && h_queue_rsp_ready),.queue_rsp_index(q_rsp_index),.queue_rsp_error(q_rsp_error),.queue_rsp_aborted(q_rsp_aborted),
        .seal_valid(control==SEAL_REQ),.seal_ready(q_seal_ready),.seal_end_job(1'b1),.seal_job_id(active_id),
        .seal_rsp_valid(q_seal_rsp_valid),.seal_rsp_ready(control==SEAL_WAIT),.seal_rsp_error(q_seal_rsp_error),.seal_rsp_drained(q_seal_rsp_drained),
        .seal_rsp_head(q_seal_head),.seal_rsp_tail(q_seal_tail),.seal_rsp_committed(q_seal_committed),
        .abort_private_valid(abort_private),.abort_job_id(active_id),
        .line_req_valid(rpc_req_valid[1]),.line_req_ready(rpc_req_ready[1]),.line_write(rpc_write[1]),.line_addr(rpc_addr[1]),.line_wdata(rpc_wdata[1]),
        .line_rsp_valid(rpc_rsp_valid[1]),.line_rsp_ready(rpc_rsp_ready[1]),.line_rdata(rpc_rdata),.line_error(rpc_error),.line_drained(rpc_drained),
        .quarantined(q_quarantined),.active_job_id(q_active_id));
    hysteresis_core_memory #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) hysteresis(
        .clk(clk),.rst(rst),.job_valid(control==START),.job_id(active_id),.job_ready(h_job_ready),
        .cancel_valid(abort_private),.cancel_id(active_id),
        .state_req_valid(h_state_req_valid),.state_req_ready(control==RUN && c_req_ready),.state_req_op(h_state_op),.state_req_index(h_state_index),
        .state_rsp_valid(control==RUN && c_rsp_valid),.state_rsp_ready(h_state_rsp_ready),
        .state_rsp_old(c_rsp_old),.state_rsp_claimed(c_rsp_claimed),.state_rsp_error(c_rsp_error),.state_rsp_aborted(c_rsp_aborted),
        .queue_req_valid(h_queue_req_valid),.queue_req_ready(control==RUN && q_req_ready),.queue_req_push(h_queue_push),.queue_req_index(h_queue_index),
        .queue_rsp_valid(control==RUN && q_rsp_valid),.queue_rsp_ready(h_queue_rsp_ready),.queue_rsp_index(q_rsp_index),.queue_rsp_error(q_rsp_error),.queue_rsp_aborted(q_rsp_aborted),
        .pixel_valid(h_pixel_valid),.pixel_ready(control==RUN && pixel_ready),.pixel_index(pixel_index),.pixel_edge(pixel_edge),.pixel_job_id(pixel_job_id),
        .done_valid(h_done_valid),.done_ready(control==RUN),.done_job_id(h_done_id),.outcome(h_outcome),.reason(h_reason),
        .enqueue_count(h_enqueue),.pop_count(h_pop),.output_count(h_output));
    line_rpc_arbiter2 line_arbiter(.clk(clk),.rst(rst),.req_valid(rpc_req_valid),.req_ready(rpc_req_ready),.req_write(rpc_write),
        .data_select(flat_select),.req_addr(rpc_addr),.req_data(rpc_wdata),.rsp_valid(rpc_rsp_valid),.rsp_ready(rpc_rsp_ready),.rsp_data(rpc_rdata),.rsp_error(rpc_error),.rsp_drained(rpc_drained),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(a_quarantined));
    always_ff @(posedge clk)begin
        if(rst)begin
            control<=IDLE;active_id<=0;saved_state_base<=0;saved_queue_base<=0;
            cancel_sticky<=0;memory_error_sticky<=0;close_error_sticky<=0;queue_configured<=0;
            outcome<=0;reason<=0;enqueue_count<=0;pop_count<=0;output_count<=0;
        end else begin
            if(control!=IDLE && control!=DONE && matching_cancel)cancel_sticky<=1;
            if(control!=IDLE && control!=DONE && line_rsp_valid && line_rsp_ready && line_error)memory_error_sticky<=1;
            if(!quarantined)case(control)
                IDLE:if(job_valid && job_ready)begin
                    active_id<=job_id;saved_state_base<=state_base;saved_queue_base<=queue_base;
                    cancel_sticky<=matching_cancel;memory_error_sticky<=0;close_error_sticky<=0;queue_configured<=0;
                    enqueue_count<=0;pop_count<=0;output_count<=0;outcome<=0;reason<=0;
                    if(!regions_legal)begin outcome<=1;reason<=8'h10;control<=DONE;end
                    else control<=CFG_CACHE_REQ;
                end
                CFG_CACHE_REQ:if(c_cfg_ready)control<=CFG_CACHE_WAIT;
                CFG_CACHE_WAIT:if(c_cfg_rsp_valid)begin
                    if(c_cfg_rsp_error)begin outcome<=1;reason<=8'h10;control<=DONE;end
                    else control<=CFG_QUEUE_REQ;
                end
                CFG_QUEUE_REQ:if(q_cfg_ready)control<=CFG_QUEUE_WAIT;
                CFG_QUEUE_WAIT:if(q_cfg_rsp_valid)begin
                    queue_configured<=!q_cfg_rsp_error;
                    if(q_cfg_rsp_error)begin outcome<=1;reason<=8'h10;control<=FLUSH_REQ;end
                    else control<=START;
                end
                START:if(h_job_ready)control<=RUN;
                RUN:if(h_done_valid)begin
                    outcome<=h_outcome;reason<=h_reason;enqueue_count<=h_enqueue;pop_count<=h_pop;output_count<=h_output;control<=FLUSH_REQ;
                end
                FLUSH_REQ:if(c_req_ready)control<=FLUSH_WAIT;
                FLUSH_WAIT:if(c_rsp_valid)begin
                    if(c_rsp_error && !c_rsp_aborted)close_error_sticky<=1;
                    control<=FLUSH_DECIDE;
                end
                FLUSH_DECIDE:begin
                    // 错误FLUSH回复只终结请求；cfg_ready才证明旧cache配置已关闭。
                    if(c_cfg_ready)begin
                        if(queue_configured)control<=SEAL_REQ;
                        else begin outcome<=1;reason<=8'h10;control<=DONE;end
                    end else if(c_req_ready)control<=FLUSH_REQ;
                end
                SEAL_REQ:if(q_seal_ready)control<=SEAL_WAIT;
                SEAL_WAIT:if(q_seal_rsp_valid && q_seal_rsp_drained)begin
                    if(memory_error_sticky || close_error_sticky || (q_seal_rsp_error && !cancellation && outcome==0))begin outcome<=1;reason<=8'h13;end
                    else if(outcome!=1 && cancellation)begin outcome<=2;reason<=0;end
                    control<=DONE;
                end
                DONE:if(done_ready)control<=IDLE;
                default:begin end
            endcase
        end
    end
endmodule
