// SC26/27：请求方先禁止此FrameRef的future；本模块等真实core债归零，不清债。
module display_scope_fence (
    input logic core_clk,video_clk,safe_reset_n,
    input logic video_request_valid,output wire video_request_ready,
    input logic [387:0] video_request,
    output wire video_done_valid,input logic video_done_ready,output wire [387:0] video_done,
    output wire scope_query_valid,output wire [386:0] scope_query_ref,
    input logic scope_live,core_fault,
    output wire old_closed_valid,input logic old_closed_ready,output wire [386:0] old_closed_ref,
    output logic video_quarantined,core_quarantined
);
    typedef enum logic [2:0] {IDLE,PROVE,SEND,WAIT_ACK,Q} state_t;
    state_t state;
    (* ASYNC_REG="TRUE" *) logic [1:0] core_reset,video_reset,core_q_sync;
    wire core_running=core_reset==0,video_running=video_reset==0;
    wire request_src_ready,request_dst_valid,request_dst_ready;
    wire [387:0] request_data;
    wire response_src_ready,response_src_valid,response_dst_valid;
    wire [387:0] response_data;
    logic video_busy;
    logic [387:0] video_current;
    wire request_src_valid=video_running && video_request_valid && !video_busy &&
        !video_quarantined && !core_q_sync[1];
    assign video_request_ready=video_running && !video_busy && !video_quarantined &&
        !core_q_sync[1] && request_src_ready;
    assign video_done_valid=video_running && response_dst_valid && !video_quarantined && !core_q_sync[1];
    assign video_done=response_data;
    assign scope_query_valid=core_running && state==PROVE && !core_quarantined;
    assign scope_query_ref=request_data[386:0];
    assign old_closed_ref=request_data[386:0];
    assign old_closed_valid=core_running && state==PROVE && request_data[387] &&
        !scope_live && !core_fault && !core_quarantined;
    assign response_src_valid=core_running && state==SEND && !core_fault && !core_quarantined;
    // 请求holding直到core真正发送回应；回应holding直到video消费并ACK回core。
    assign request_dst_ready=response_src_valid && response_src_ready;
    atomic_mailbox #(.PAYLOAD_WIDTH(388)) requests (
        .src_clk(video_clk),.dst_clk(core_clk),.safe_reset_n,
        .src_valid(request_src_valid),.src_ready(request_src_ready),.src_data(video_request),
        .dst_valid(request_dst_valid),.dst_ready(request_dst_ready),.dst_data(request_data),
        .src_running(),.dst_running());
    atomic_mailbox #(.PAYLOAD_WIDTH(388)) responses (
        .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,
        .src_valid(response_src_valid),.src_ready(response_src_ready),.src_data(request_data),
        .dst_valid(response_dst_valid),.dst_ready(video_done_valid && video_done_ready),.dst_data(response_data),
        .src_running(),.dst_running());
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)core_reset<=2'b11;else core_reset<={core_reset[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin video_reset<=2'b11;core_q_sync<=0;end
        else begin video_reset<={video_reset[0],1'b0};core_q_sync<={core_q_sync[0],core_quarantined};end
    end
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin video_busy<=0;video_current<=0;video_quarantined<=0;end
        else if(video_running)begin
            if(video_request_valid && video_request_ready)begin video_busy<=1;video_current<=video_request;end
            if(video_done_valid && video_done_ready)begin
                if(!video_busy || response_data!=video_current)video_quarantined<=1;
                else video_busy<=0;
            end
        end
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin state<=IDLE;core_quarantined<=0;end
        else if(core_running)begin
            if(core_fault)begin state<=Q;core_quarantined<=1;end
            else case(state)
                IDLE:if(request_dst_valid)state<=PROVE;
                PROVE:if(!scope_live && (!request_data[387] || old_closed_ready))state<=SEND;
                SEND:if(response_src_valid && response_src_ready)state<=WAIT_ACK;
                WAIT_ACK:if(response_src_ready)state<=IDLE;
                default:begin end
            endcase
        end
    end
    // synthesis translate_off
    always @(posedge core_clk)if(core_running && old_closed_valid && scope_live)
        $fatal(1,"Scope fence claimed live object closed");
    // synthesis translate_on
endmodule
