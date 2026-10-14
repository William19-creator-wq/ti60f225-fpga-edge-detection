// RJ01..05：实际写帧和实际共享写服务；这里只保存拒绝配置回执。
module rgb_axi_write_join #(
    parameter integer WIDTH=1920, HEIGHT=1080,
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,backend_enable,
    input logic job_valid,output wire job_ready,
    input logic [31:0] job_base,input logic [63:0] job_handle,
    output wire job_rsp_valid,input logic job_rsp_ready,output wire job_rsp_error,
    input logic in_valid,output wire in_ready,input logic [47:0] in_rgb,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,
    input logic in_bad,input logic [63:0] in_handle,
    input logic cancel_valid,input logic [63:0] cancel_id,
    output wire done_valid,input logic done_ready,output wire [63:0] done_id,
    output wire [1:0] outcome,output wire [7:0] reason,
    output wire [21:0] accepted_pairs,written_lines,
    output wire [31:0] logical_bytes,physical_bytes,
    input logic algo_req_valid,output wire algo_req_ready,
    input logic [31:0] algo_addr,input logic [511:0] algo_data,
    output wire algo_rsp_valid,input logic algo_rsp_ready,output wire algo_error,algo_drained,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output wire [127:0] m_axi_wdata,
    output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,
    input logic [1:0] m_axi_bresp,
    output wire source_stop,source_quarantined,write_quarantined,quarantined,write_busy,
    output wire [2:0] fault_reason
);
    localparam integer FRAME_BYTES=3*WIDTH*HEIGHT;
    localparam integer FRAME_ALLOCATION=((FRAME_BYTES+63)/64)*64;
    logic rejected_cfg;
    wire child_job_ready,child_cfg_valid,child_cfg_error,child_in_ready,child_stop;
    wire writer_req_valid,writer_req_ready,writer_rsp_valid,writer_rsp_ready;
    wire [31:0] writer_addr;
    wire [511:0] writer_data;
    wire [1:0] request_valid,request_ready,response_valid,response_ready,response_error,response_drained;
    wire [31:0] request_addr[0:1];
    wire [511:0] request_data[0:1];
    wire service_bridge_q,service_local_q;

    // E1/2：先作33位整帧范围检查；非法配置只产生一个固定错误回执。
    wire [32:0] frame_end={1'b0,job_base}+33'(FRAME_ALLOCATION);
    wire grant_known=(^job_base!==1'bx) && (^job_handle!==1'bx);
    wire grant_legal=grant_known && job_base[5:0]==0 && frame_end<=ADDRESS_BYTES;
    wire new_source_allowed=backend_enable && !quarantined;
    assign quarantined=source_quarantined || write_quarantined;
    assign job_ready=!rst && !rejected_cfg && new_source_allowed && child_job_ready;
    wire job_fire=job_valid && job_ready;
    assign job_rsp_valid=!rst && (rejected_cfg || child_cfg_valid);
    assign job_rsp_error=rejected_cfg ? 1'b1 : child_cfg_error;
    always_ff @(posedge clk)begin
        if(rst)rejected_cfg<=0;
        else begin
            if(rejected_cfg && job_rsp_ready)rejected_cfg<=0;
            if(job_fire && !grant_legal)rejected_cfg<=1;
        end
    end

    // E3：相同资格同时用于输入valid和公开ready，禁止出现只在一侧的fire。
    assign in_ready=child_in_ready && new_source_allowed;
    assign source_stop=child_stop || quarantined || !backend_enable;
    rgb_source_writer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) source_writer(
        .clk,.rst,.job_valid(job_fire && grant_legal),.job_ready(child_job_ready),.job_base,.job_handle,
        .job_rsp_valid(child_cfg_valid),.job_rsp_ready(job_rsp_ready && !rejected_cfg),.job_rsp_error(child_cfg_error),
        .in_valid(in_valid && new_source_allowed),.in_ready(child_in_ready),.in_rgb,.in_x_even,.in_y,
        .in_markers,.in_bad,.in_handle,.cancel_valid,.cancel_id,
        .done_valid,.done_ready,.done_id,.outcome,.reason,.accepted_pairs,.written_lines,.logical_bytes,.physical_bytes,
        .source_stop(child_stop),.quarantined(source_quarantined),
        .line_req_valid(writer_req_valid),.line_req_ready(writer_req_ready),.line_write(),
        .line_addr(writer_addr),.line_wdata(writer_data),
        .line_rsp_valid(writer_rsp_valid),.line_rsp_ready(writer_rsp_ready),.line_rdata(512'd0),
        .line_error(response_error[0]),.line_drained(response_drained[0])
    );

    // E4：cancel/source_stop不能撤回writer已公开的packet。Q只阻新接纳，旧通知照常归还。
    assign request_valid={algo_req_valid && !quarantined,writer_req_valid && !quarantined};
    assign request_addr[0]=writer_addr;assign request_data[0]=writer_data;
    assign request_addr[1]=algo_addr;assign request_data[1]=algo_data;
    assign writer_req_ready=request_ready[0] && !quarantined;
    assign algo_req_ready=request_ready[1] && !quarantined;
    assign writer_rsp_valid=response_valid[0];assign response_ready={algo_rsp_ready,writer_rsp_ready};
    assign algo_rsp_valid=response_valid[1];assign algo_error=response_error[1];assign algo_drained=response_drained[1];
    axi_write_pair_service #(.ADDRESS_BYTES(ADDRESS_BYTES)) write_service(
        .clk,.rst,.enable(backend_enable),
        .c_req_valid(request_valid),.c_req_ready(request_ready),.c_addr(request_addr),.c_data(request_data),
        .c_rsp_valid(response_valid),.c_rsp_ready(response_ready),.c_error(response_error),.c_drained(response_drained),
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,
        .m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .busy(write_busy),.quarantined(write_quarantined),.bridge_quarantined(service_bridge_q),
        .local_quarantined(service_local_q),.fault_reason
    );
    // synthesis translate_off
    initial begin
        if(WIDTH<4 || WIDTH>1920 || WIDTH%2 || HEIGHT<2 || HEIGHT>1080)$fatal(1,"RGB AXI join geometry");
        if(ADDRESS_BYTES<64 || ADDRESS_BYTES>33'h100000000 || ADDRESS_BYTES[5:0]!=0)$fatal(1,"RGB AXI join capacity");
    end
    always @(posedge clk)if(!rst && rejected_cfg && child_cfg_valid)$fatal(1,"Two configuration reply owners");
    // synthesis translate_on
endmodule
