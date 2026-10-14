// 上板用 Sobel 帧任务。沿用真实 RGB reader、R1 与 packed writer，不绕过 DDR。
module board_sobel_rpc #(parameter integer WIDTH=1920,HEIGHT=1080)(
    input wire clk,rst,axi_enable,job_valid, output wire job_ready,
    input wire [141:0] job_cj, input wire [194:0] job_origin,
    input wire [63:0] job_handle, input wire [31:0] source_base,result_base,
    output wire done_valid,input wire done_ready,
    output wire [95:0] done_scope,output wire [194:0] done_origin,
    output reg [1:0] outcome,output reg [31:0] reason,
    output wire algorithm_req_valid,input wire algorithm_req_ready,
    output wire algorithm_write,output wire [31:0] algorithm_addr,
    output wire [511:0] algorithm_wdata,
    input wire algorithm_rsp_valid,output wire algorithm_rsp_ready,
    input wire [511:0] algorithm_rdata,input wire algorithm_error,algorithm_drained,
    output wire quarantined,
    output wire  frontend_job_valid,
    input wire  frontend_job_ready,
    output wire [109:0] frontend_job,
    output wire  frontend_input_valid,
    input wire  frontend_input_ready,
    output wire [73:0] frontend_input,
    input wire  frontend_output_valid,
    output wire  frontend_output_ready,
    input wire [138:0] frontend_output,
    input wire  frontend_status_valid,
    output wire  frontend_status_ready,
    input wire [162:0] frontend_status,
    output wire  frontend_cancel,
    output wire  reader_job_valid,
    input wire  reader_job_ready,
    output wire [95:0] reader_job,
    input wire  reader_config_valid,
    output wire  reader_config_ready,
    input wire  reader_config_error,
    input wire  reader_pixel_valid,
    output wire  reader_pixel_ready,
    input wire [137:0] reader_pixel,
    input wire  reader_done_valid,
    output wire  reader_done_ready,
    input wire [161:0] reader_status,
    output wire  reader_cancel,
    output wire [63:0] reader_cancel_id,
    input wire  reader_line_valid,
    output wire  reader_line_ready,
    input wire  reader_line_write,
    input wire [31:0] reader_line_addr,
    input wire [511:0] reader_line_wdata,
    output wire  reader_reply_valid,
    input wire  reader_reply_ready,
    output wire [511:0] reader_reply_data,
    output wire  reader_reply_error,
    output wire  reader_reply_drained,
    output wire  writer_config_valid,
    input wire  writer_config_ready,
    output wire [95:0] writer_config,
    input wire  writer_config_reply_valid,
    output wire  writer_config_reply_ready,
    input wire  writer_config_error,
    output wire  writer_pixel_valid,
    input wire  writer_pixel_ready,
    output wire [85:0] writer_pixel,
    output wire  writer_abort,
    output wire [63:0] writer_abort_id,
    input wire  writer_done_valid,
    output wire  writer_done_ready,
    input wire [25:0] writer_status,
    input wire  writer_line_valid,
    output wire  writer_line_ready,
    input wire  writer_line_write,
    input wire [31:0] writer_line_addr,
    input wire [511:0] writer_line_wdata,
    output wire  writer_reply_valid,
    input wire  writer_reply_ready,
    output wire [511:0] writer_reply_data,
    output wire  writer_reply_error,
    output wire  writer_reply_drained
);
    localparam IDLE=0,WCFG=1,WREPLY=2,FSTART=3,RSTART=4,RREPLY=5,RUN=6,DONE=7;
    reg [3:0] state;
    reg [141:0] cj;reg [194:0] origin;reg [63:0] handle;
    reg [31:0] src,dst;reg r_closed,f_closed,w_closed;
    wire r_job_ready,r_cfg_valid,r_cfg_error,r_valid,r_ready,r_done,r_q;
    wire [73:0] r_fp;wire [1:0] r_outcome;wire [7:0] r_reason;
    wire f_job_ready,f_valid,f_ready,f_done;wire [2:0] f_code;
    wire [1:0] f_edge;wire [10:0] f_x,f_y;
    wire w_cfg_ready,w_cfg_valid,w_cfg_error,w_ready,w_done,w_error,w_aborted,w_drained,w_q;
    reg held;reg lane;reg [1:0] edge_pair;reg [20:0] pixel_index;
    wire pixel_fire=held&&w_ready;
    wire [1:0] req_valid,req_ready,req_write,rsp_valid,rsp_ready;
    wire [31:0] addr[0:1];wire [511:0] wdata[0:1],rdata;
    wire rpc_error,rpc_drained,rpc_q;
    assign job_ready=!rst&&axi_enable&&state==IDLE&&!quarantined;
    assign done_valid=!rst&&state==DONE;
    assign done_scope=cj[95:0];assign done_origin=origin;
    assign quarantined=r_q||w_q||rpc_q;
    assign f_ready=!held;
    wire f_in_ready;
    assign r_ready=state==RUN&&f_in_ready;
    assign reader_job_valid=state==RSTART;assign r_job_ready=reader_job_ready;assign reader_job={handle,src};
    assign r_cfg_valid=reader_config_valid;assign reader_config_ready=state==RREPLY;assign r_cfg_error=reader_config_error;
    assign r_valid=reader_pixel_valid;assign reader_pixel_ready=r_ready;assign r_fp=reader_pixel[73:0];
    assign reader_cancel=1'b0;assign reader_cancel_id=handle;
    assign r_done=reader_done_valid;assign reader_done_ready=state==RUN&&!r_closed;
    assign r_outcome=reader_status[65:64];assign r_reason=reader_status[73:66];assign r_q=reader_status[161];
    assign req_valid[0]=reader_line_valid;assign reader_line_ready=req_ready[0];assign req_write[0]=reader_line_write;
    assign addr[0]=reader_line_addr;assign wdata[0]=reader_line_wdata;
    assign reader_reply_valid=rsp_valid[0];assign rsp_ready[0]=reader_reply_ready;
    assign reader_reply_data=rdata;assign reader_reply_error=rpc_error;assign reader_reply_drained=rpc_drained;
    assign frontend_job_valid=state==FSTART;assign f_job_ready=frontend_job_ready;
    assign frontend_job={cj[139:129],2'd1,cj[140],cj[95:0]};
    assign frontend_input_valid=r_valid&&state==RUN;assign frontend_input=r_fp;assign f_in_ready=frontend_input_ready;
    assign f_valid=frontend_output_valid;assign frontend_output_ready=f_ready;
    assign f_edge=frontend_output[17:16];assign f_x=frontend_output[28:18];assign f_y=frontend_output[39:29];
    assign frontend_cancel=1'b0;assign f_done=frontend_status_valid;assign frontend_status_ready=state==RUN&&!f_closed;
    assign f_code=frontend_status[2:0];
    assign writer_config_valid=state==WCFG;assign w_cfg_ready=writer_config_ready;assign writer_config={handle,dst};
    assign w_cfg_valid=writer_config_reply_valid;assign writer_config_reply_ready=state==WREPLY;assign w_cfg_error=writer_config_error;
    assign writer_pixel_valid=held;assign w_ready=writer_pixel_ready;assign writer_pixel={handle,pixel_index,edge_pair[lane]};
    assign writer_abort=1'b0;assign writer_abort_id=handle;
    assign w_done=writer_done_valid;assign writer_done_ready=state==RUN&&!w_closed;
    assign w_error=writer_status[22];assign w_aborted=writer_status[23];assign w_drained=writer_status[24];assign w_q=writer_status[25];
    assign req_valid[1]=writer_line_valid;assign writer_line_ready=req_ready[1];assign req_write[1]=writer_line_write;
    assign addr[1]=writer_line_addr;assign wdata[1]=writer_line_wdata;
    assign writer_reply_valid=rsp_valid[1];assign rsp_ready[1]=writer_reply_ready;
    assign writer_reply_data=rdata;assign writer_reply_error=rpc_error;assign writer_reply_drained=rpc_drained;
    line_rpc_arbiter2 arbiter(.clk,.rst,.req_valid,.req_ready,.req_write,.req_addr(addr),.req_data(wdata),
        .rsp_valid,.rsp_ready,.rsp_data(rdata),.rsp_error(rpc_error),.rsp_drained(rpc_drained),.quarantined(rpc_q),
        .line_req_valid(algorithm_req_valid),.line_req_ready(algorithm_req_ready),.line_write(algorithm_write),
        .line_addr(algorithm_addr),.line_wdata(algorithm_wdata),.line_rsp_valid(algorithm_rsp_valid),
        .line_rsp_ready(algorithm_rsp_ready),.line_rdata(algorithm_rdata),.line_error(algorithm_error),.line_drained(algorithm_drained));
    always @(posedge clk)begin
        if(rst)begin
            state<=IDLE;cj<=0;origin<=0;handle<=0;src<=0;dst<=0;
            held<=0;lane<=0;edge_pair<=0;pixel_index<=0;r_closed<=0;f_closed<=0;w_closed<=0;outcome<=0;reason<=0;
        end else begin
            if(f_valid&&f_ready)begin held<=1;lane<=0;edge_pair<=f_edge;end
            if(pixel_fire)begin pixel_index<=pixel_index+1'b1;if(lane)held<=0;else lane<=1;end
            case(state)
                IDLE:if(job_valid&&job_ready)begin
                    cj<=job_cj;origin<=job_origin;handle<=job_handle;src<=source_base;dst<=result_base;
                    pixel_index<=0;held<=0;r_closed<=0;f_closed<=0;w_closed<=0;outcome<=0;reason<=0;state<=WCFG;
                end
                WCFG:if(w_cfg_ready)state<=WREPLY;
                WREPLY:if(w_cfg_valid)begin
                    if(w_cfg_error)begin outcome<=1;reason<=1;state<=DONE;end else state<=FSTART;
                end
                FSTART:if(f_job_ready)state<=RSTART;
                RSTART:if(r_job_ready)state<=RREPLY;
                RREPLY:if(r_cfg_valid)begin
                    if(r_cfg_error)begin outcome<=1;reason<=2;state<=DONE;end else state<=RUN;
                end
                RUN:begin
                    if(r_done&&!r_closed)begin r_closed<=1;if(r_outcome!=0)begin outcome<=1;reason[7:0]<=r_reason;end end
                    if(f_done&&!f_closed)begin f_closed<=1;if(f_code!=0)begin outcome<=1;reason[10:8]<=f_code;end end
                    if(w_done&&!w_closed)begin w_closed<=1;if(w_error||w_aborted||!w_drained)begin outcome<=1;reason[11]<=1;end end
                    if(r_closed&&f_closed&&w_closed&&!held)state<=DONE;
                end
                DONE:if(done_ready)state<=IDLE;
                default:state<=IDLE;
            endcase
        end
    end
endmodule
