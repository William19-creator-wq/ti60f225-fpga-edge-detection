// DH01：稳定源holding + req/ack两FF。两个端口只能共同安全冷复位。
module atomic_mailbox #(parameter integer PAYLOAD_WIDTH=1137)(
    input logic src_clk,dst_clk,safe_reset_n,
    input logic src_valid,output wire src_ready,input logic [PAYLOAD_WIDTH-1:0] src_data,
    output wire dst_valid,input logic dst_ready,output wire [PAYLOAD_WIDTH-1:0] dst_data,
    output wire src_running,dst_running
);
    (* ASYNC_REG="TRUE" *) logic [1:0] src_reset,dst_reset,req_sync,ack_sync,dst_run_sync;
    logic request_toggle,ack_toggle,seen_request,src_pending,dst_pending;
    logic [PAYLOAD_WIDTH-1:0] source_hold;
    assign src_running=src_reset==0;assign dst_running=dst_reset==0;
    assign src_ready=src_running && dst_run_sync[1] && !src_pending;
    assign dst_valid=dst_running && dst_pending;
    // 目的域资格晚于源hold稳定；实际采样后ACK才允许源更改下一包。
    assign dst_data=source_hold;
    always_ff @(posedge src_clk or negedge safe_reset_n)
        if(!safe_reset_n)src_reset<=2'b11;else src_reset<={src_reset[0],1'b0};
    always_ff @(posedge dst_clk or negedge safe_reset_n)
        if(!safe_reset_n)dst_reset<=2'b11;else dst_reset<={dst_reset[0],1'b0};
    always_ff @(posedge src_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin ack_sync<=0;dst_run_sync<=0;end
        else begin ack_sync<={ack_sync[0],ack_toggle};dst_run_sync<={dst_run_sync[0],dst_running};end
    end
    always_ff @(posedge dst_clk or negedge safe_reset_n)
        if(!safe_reset_n)req_sync<=0;else req_sync<={req_sync[0],request_toggle};
    always_ff @(posedge src_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin request_toggle<=0;src_pending<=0;source_hold<=0;end
        else if(src_running)begin
            if(src_pending && ack_sync[1]==request_toggle)src_pending<=0;
            if(src_valid && src_ready)begin source_hold<=src_data;request_toggle<=!request_toggle;src_pending<=1;end
        end
    end
    always_ff @(posedge dst_clk or negedge safe_reset_n)begin
        if(!safe_reset_n)begin ack_toggle<=0;seen_request<=0;dst_pending<=0;end
        else if(dst_running)begin
            if(!dst_pending && req_sync[1]!=seen_request)begin seen_request<=req_sync[1];dst_pending<=1;end
            if(dst_valid && dst_ready)begin dst_pending<=0;ack_toggle<=seen_request;end
        end
    end
    // synthesis translate_off
    initial if(PAYLOAD_WIDTH<1 || PAYLOAD_WIDTH>1207)$fatal(1,"Mailbox width");
    // synthesis translate_on
endmodule
