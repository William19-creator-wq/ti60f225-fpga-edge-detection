// FC06/07：请求保持到业务终态，响应实际ACK后才再开下一包。
module display_fetch_link(
    input logic core_clk,video_clk,safe_reset_n,
    input logic video_request_valid,output wire video_request_ready,input logic [480:0] video_request,
    input logic video_cancel,
    output wire video_receipt_valid,input logic video_receipt_ready,output wire [614:0] video_receipt,
    output logic video_busy,video_quarantined,
    output wire service_valid,input logic service_claim_ready,output wire [480:0] service_request,
    output wire service_cancel,input logic service_receipt_valid,output wire service_receipt_ready,input logic [614:0] service_receipt,
    output wire transport_live,output wire [386:0] transport_ref,output wire core_idle,output logic core_quarantined
);
    import display_fetch_pkg::*;
    (* ASYNC_REG="TRUE" *) logic [1:0] video_reset,core_reset,core_idle_sync,cancel_sync,video_q_sync;
    wire video_running=video_reset==0,core_running=core_reset==0;
    logic cancel_level,core_claimed,await_response_ack;
    request_t video_current,core_request_view;
    receipt_t video_receipt_view,core_receipt_view;
    wire req_src_ready,req_dst_valid,req_dst_ready,rsp_src_ready,rsp_src_valid;
    wire [480:0] req_dst_data;wire [614:0] rsp_dst_data;
    wire req_src_run,req_dst_run,rsp_src_run,rsp_dst_run;
    assign core_request_view=req_dst_data;assign core_receipt_view=service_receipt;
    assign video_receipt_view=rsp_dst_data;
    assign video_request_ready=video_running && !video_busy && !video_quarantined && core_idle_sync[1] && req_src_ready;
    atomic_mailbox #(.PAYLOAD_WIDTH(481)) requests(
        .src_clk(video_clk),.dst_clk(core_clk),.safe_reset_n,
        .src_valid(video_request_valid && !video_busy && !video_quarantined && core_idle_sync[1]),.src_ready(req_src_ready),.src_data(video_request),
        .dst_valid(req_dst_valid),.dst_ready(req_dst_ready),.dst_data(req_dst_data),.src_running(req_src_run),.dst_running(req_dst_run));
    assign service_request=req_dst_data;
    assign service_valid=core_running && req_dst_valid && !core_claimed && !await_response_ack && !core_quarantined && !video_q_sync[1];
    assign service_cancel=core_running && cancel_sync[1];
    assign rsp_src_valid=core_running && core_claimed && service_receipt_valid;
    assign service_receipt_ready=core_running && core_claimed && rsp_src_ready;
    wire response_source_fire=rsp_src_valid&&rsp_src_ready;
    assign req_dst_ready=response_source_fire;
    atomic_mailbox #(.PAYLOAD_WIDTH(615)) receipts(
        .src_clk(core_clk),.dst_clk(video_clk),.safe_reset_n,
        .src_valid(rsp_src_valid),.src_ready(rsp_src_ready),.src_data(service_receipt),
        .dst_valid(video_receipt_valid),.dst_ready(video_receipt_ready),.dst_data(rsp_dst_data),.src_running(rsp_src_run),.dst_running(rsp_dst_run));
    assign video_receipt=rsp_dst_data;
    assign core_idle=core_running && !core_claimed && !await_response_ack && !req_dst_valid && rsp_src_ready && service_claim_ready && !core_quarantined && !video_q_sync[1];
    assign transport_live=core_running && (core_claimed || await_response_ack || req_dst_valid || core_quarantined || video_q_sync[1]);
    assign transport_ref=demand_ref(core_request_view.demand);
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)video_reset<=2'b11;else video_reset<={video_reset[0],1'b0};
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)core_reset<=2'b11;else core_reset<={core_reset[0],1'b0};
    always_ff @(posedge video_clk or negedge safe_reset_n)
        if(!safe_reset_n)core_idle_sync<=0;else core_idle_sync<={core_idle_sync[0],core_idle};
    always_ff @(posedge core_clk or negedge safe_reset_n)
        if(!safe_reset_n)begin cancel_sync<=0;video_q_sync<=0;end
        else begin cancel_sync<={cancel_sync[0],cancel_level};video_q_sync<={video_q_sync[0],video_quarantined};end
    always_ff @(posedge video_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin video_busy<=0;video_quarantined<=0;video_current<=0;cancel_level<=0;end
        else if(video_running)begin
            if(video_request_valid&&video_request_ready)begin video_current<=video_request;video_busy<=1;cancel_level<=video_cancel;end
            if(video_busy&&video_cancel)cancel_level<=1;
            if(video_receipt_valid&&video_receipt_ready)begin
                video_busy<=0;cancel_level<=0;
                if(!video_busy || video_receipt_view.bank!=video_current.bank || video_receipt_view.ticket[478:0]!=video_current.demand ||
                   (video_receipt_view.row_granted && video_receipt_view.ticket.generation==0) || video_receipt_view.outcome==3 || !video_receipt_view.drained)
                    video_quarantined<=1;
            end
        end
    end
    always_ff @(posedge core_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin core_claimed<=0;await_response_ack<=0;core_quarantined<=0;end
        else if(core_running)begin
            if(service_valid&&service_claim_ready)core_claimed<=1;
            if(response_source_fire)begin
                core_claimed<=0;await_response_ack<=1;
                if(core_receipt_view.outcome==3 || !core_receipt_view.drained)core_quarantined<=1;
            end
            if(await_response_ack&&rsp_src_ready)await_response_ack<=0;
            if(video_q_sync[1])core_quarantined<=1;
        end
    end
    // synthesis translate_off
    always @(posedge core_clk)if(core_running)
        if(response_source_fire && (!core_claimed || !req_dst_valid))$fatal(1,"Fetch response without held request");
    // synthesis translate_on
endmodule
