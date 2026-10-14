// CO08：真实Source管理、RAW/CFA写入和唯一owner。正式父顶层复用manager并共享owner。
module frame_capture_owned_axi #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter logic [63:0] INIT_SOURCE_HANDLE=64'd1
)(
    input logic clk,rst,axi_enable,
    input logic frame_valid,output wire frame_ready,input logic [95:0] frame_scope,input logic [1:0] frame_bayer,
    output wire grant_valid,input logic grant_ready,output wire [3:0] grant_status,
    output wire [63:0] grant_handle,output wire [194:0] grant_origin,
    output wire [95:0] grant_scope,output wire [1:0] grant_bayer,
    input logic in_valid,output wire in_ready,input logic [19:0] raw_pair,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_handle,
    input logic rx_valid,output wire rx_ready,input logic [63:0] rx_handle,
    input logic [95:0] rx_scope,input logic [194:0] rx_origin,input logic rx_good,
    input logic cancel_valid,input logic [63:0] cancel_handle,
    output wire done_valid,input logic done_ready,output wire [63:0] done_handle,
    output wire [194:0] done_origin,output wire [95:0] done_scope,
    output wire [1:0] done_outcome,output wire [7:0] done_reason,
    output wire source_stop,quarantined,output wire [17:0] source_states,output wire [63:0] latest_handle,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output wire [127:0] m_axi_wdata,output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp
);
    wire owner_cmd_valid,owner_cmd_ready,owner_reply_valid,owner_reply_ready;
    wire [940:0] owner_command;wire [941:0] owner_reply;
    wire [8:0] result_states;wire [63:0] freeze_handle,policy;
    wire frozen,owner_q,source_exhausted,result_exhausted;
    frame_owner_read_authority #(.IMAGE_WIDTH(WIDTH),.IMAGE_HEIGHT(HEIGHT),.FRAME_ALIGNMENT(64),.INIT_SOURCE_HANDLE(INIT_SOURCE_HANDLE)) owner(
        .core_clk(clk),.safe_reset_n(!rst),.cmd_valid(owner_cmd_valid),.cmd_ready(owner_cmd_ready),.command(owner_command),
        .offer_sequence(64'd0),.lookup_valid(1'b0),.lookup_ready(),.lookup_demand(479'd0),.lookup_permitted(),.lookup_bundle(),
        .reply_valid(owner_reply_valid),.reply_ready(owner_reply_ready),.reply(owner_reply),
        .source_states,.result_states,.latest_handle,.freeze_handle,.policy,.frozen,.quarantined(owner_q),.source_exhausted,.result_exhausted);

    wire cap_job_valid,cap_job_ready,cap_done_valid,cap_done_ready,cap_cancel_valid,cap_q,manager_q;
    wire [31:0] cap_base;wire [63:0] cap_handle,cap_done_handle,cap_cancel_handle;
    wire [95:0] cap_scope,cap_done_scope;wire [1:0] cap_bayer,cap_outcome,cap_failed_stage;
    wire [7:0] cap_reason;wire [21:0] cap_raw_pairs,cap_rgb_pairs,cap_lines,cap_discarded;
    wire [31:0] cap_logical_bytes,cap_physical_bytes;
    wire actor_input_ready,actor_stop,write_busy,write_q,bridge_q,local_q;
    wire [2:0] write_fault;
    wire raw_gate=!grant_valid && !manager_q && !cap_q && !write_q;
    wire raw_eof_fire=in_valid && in_ready && in_markers[2];
    frame_capture_manager #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) manager(
        .clk,.rst,.halt(!axi_enable || write_q || owner_q),.capture_quarantined(cap_q),
        .frame_valid,.frame_ready,.frame_scope,.frame_bayer,
        .grant_valid,.grant_ready,.grant_status,.grant_handle,.grant_origin,.grant_scope,.grant_bayer,
        .owner_cmd_valid,.owner_cmd_ready,.owner_command,.owner_reply_valid,.owner_reply_ready,.owner_reply,
        .cap_job_valid,.cap_job_ready,.cap_base,.cap_handle,.cap_scope,.cap_bayer,
        .cap_done_valid,.cap_done_ready,.cap_done_handle,.cap_done_scope,.cap_outcome,.cap_reason,
        .cap_raw_pairs,.cap_rgb_pairs,.cap_lines,.cap_discarded,.cap_logical_bytes,.cap_physical_bytes,
        .cap_cancel_valid,.cap_cancel_handle,
        .raw_eof_valid(raw_eof_fire),.raw_eof_handle(in_handle),.raw_eof_scope(cap_scope),
        .rx_valid,.rx_ready,.rx_handle,.rx_scope,.rx_origin,.rx_good,.cancel_valid,.cancel_handle,
        .done_valid,.done_ready,.done_handle,.done_origin,.done_scope,.done_outcome,.done_reason,.quarantined(manager_q));

    wire line_req_valid,line_req_ready,line_write,line_rsp_valid,line_rsp_ready,line_error,line_drained;
    wire [31:0] line_addr;wire [511:0] line_data;
    assign in_ready=actor_input_ready && raw_gate;
    assign source_stop=actor_stop || quarantined;
    assign quarantined=manager_q || cap_q || write_q || owner_q;
    raw_source_join #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) capture_actor(
        .clk,.rst,.job_valid(cap_job_valid),.job_ready(cap_job_ready),.job_base(cap_base),.job_handle(cap_handle),.job_scope(cap_scope),.phase(cap_bayer),
        .in_valid(in_valid && raw_gate),.in_ready(actor_input_ready),.raw_pair,.in_x_even,.in_y,.in_markers,.in_bad,.in_handle,
        .cancel_valid(cap_cancel_valid),.cancel_id(cap_cancel_handle),
        .done_valid(cap_done_valid),.done_ready(cap_done_ready),.done_id(cap_done_handle),.done_scope(cap_done_scope),
        .outcome(cap_outcome),.reason(cap_reason),.failed_stage(cap_failed_stage),
        .accepted_raw(cap_raw_pairs),.accepted_rgb(cap_rgb_pairs),.written_lines(cap_lines),.discarded_rgb(cap_discarded),
        .logical_bytes(cap_logical_bytes),.physical_bytes(cap_physical_bytes),.source_stop(actor_stop),.quarantined(cap_q),
        .line_req_valid,.line_req_ready,.line_write,.line_addr,.line_wdata(line_data),
        .line_rsp_valid,.line_rsp_ready,.line_rdata(512'd0),.line_error,.line_drained);

    wire [1:0] c_req_valid,c_req_ready,c_rsp_valid,c_rsp_ready,c_error,c_drained;
    wire [31:0] c_addr[0:1];wire [511:0] c_data[0:1];
    assign c_req_valid={1'b0,line_req_valid};assign line_req_ready=c_req_ready[0];
    assign c_addr[0]=line_addr;assign c_addr[1]=0;assign c_data[0]=line_data;assign c_data[1]=0;
    assign c_rsp_ready={1'b0,line_rsp_ready};assign line_rsp_valid=c_rsp_valid[0];assign line_error=c_error[0];assign line_drained=c_drained[0];
    axi_write_pair_service writes(
        .clk,.rst,.enable(axi_enable),.c_req_valid,.c_req_ready,.c_addr,.c_data,.c_rsp_valid,.c_rsp_ready,.c_error,.c_drained,
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,
        .m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .busy(write_busy),.quarantined(write_q),.bridge_quarantined(bridge_q),.local_quarantined(local_q),.fault_reason(write_fault));
endmodule
