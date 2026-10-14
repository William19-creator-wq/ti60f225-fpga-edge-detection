// DH01..06：真实采集/完整Canny及旧Source显示读取共享实际双向AXI。
module capture_display_axi #(
    parameter integer WIDTH=1920,HEIGHT=1080,
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,axi_enable,
    input logic job_valid,output wire job_ready,input logic [141:0] job_cj,
    input logic [194:0] job_origin,input logic [63:0] job_handle,input logic [1:0] bayer_phase,
    input logic [31:0] source_base,class_base,queue_base,result_base,
    input logic in_valid,output wire in_ready,input logic [19:0] raw_pair,
    input logic [10:0] in_x_even,in_y,input logic [2:0] in_markers,input logic in_bad,input logic [63:0] in_handle,
    input logic rx_close_valid,output wire rx_close_ready,input logic [63:0] rx_close_handle,
    input logic [194:0] rx_close_origin,input logic rx_close_good,
    input logic cancel_valid,input logic [95:0] cancel_scope,
    output wire grad_valid,input logic grad_ready,output wire [184:0] grad_payload,
    output wire done_valid,input logic done_ready,output wire [95:0] done_scope,output wire [194:0] done_origin,
    output logic [1:0] outcome,output logic [31:0] reason,
    output logic [21:0] source_pairs,output logic [20:0] reader_pairs,canny_input,canny_class,
    output logic [21:0] output_pixels,edge_pixels,discarded_fp,output wire [591:0] r2_status_snapshot,
    output wire [3:0] phase,output wire source_stop,quarantined,
    input logic display_enable,display_cancel,span_req_valid,output wire span_req_ready,
    input logic [31:0] span_addr,input logic [13:0] span_bytes,
    output wire display_data_valid,input logic display_data_ready,output wire [127:0] display_data,
    output wire display_done_valid,input logic display_done_ready,
    output wire [1:0] display_outcome,output wire [7:0] display_reason,output wire display_drained,
    output wire memory_quarantined,algorithm_live,read_occupied,read_physical_idle,write_busy,
    output wire read_quarantined,write_quarantined,direction_quarantined,
    output wire [2:0] read_fault_reason,write_fault_reason,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output wire [127:0] m_axi_wdata,output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    wire camera_req_valid,camera_req_ready,camera_rsp_valid,camera_rsp_ready,camera_error,camera_drained;
    wire [31:0] camera_addr;wire [511:0] camera_data;
    wire algorithm_req_valid,algorithm_req_ready,algorithm_write,algorithm_rsp_valid,algorithm_rsp_ready,algorithm_error,algorithm_drained;
    wire [31:0] algorithm_addr;wire [511:0] algorithm_wdata,algorithm_rdata;
    wire producer_local_quarantined;
    capture_canny_rpc #(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.ADDRESS_BYTES(ADDRESS_BYTES)) core(
        .clk,.rst,.axi_enable,.job_valid,.job_ready,.job_cj,.job_origin,
        .job_handle,.bayer_phase,.source_base,.class_base,.queue_base,.result_base,.in_valid,
        .in_ready,.raw_pair,.in_x_even,.in_y,.in_markers,.in_bad,.in_handle,
        .rx_close_valid,.rx_close_ready,.rx_close_handle,.rx_close_origin,.rx_close_good,.cancel_valid,.cancel_scope,
        .grad_valid,.grad_ready,.grad_payload,.done_valid,.done_ready,.done_scope,.done_origin,
        .outcome,.reason,.source_pairs,.reader_pairs,.canny_input,.canny_class,.output_pixels,
        .edge_pixels,.discarded_fp,.r2_status_snapshot,.phase,.source_stop,.quarantined,.camera_req_valid,
        .camera_req_ready,.camera_addr,.camera_data,.camera_rsp_valid,.camera_rsp_ready,.camera_error,.camera_drained,
        .algorithm_req_valid,.algorithm_req_ready,.algorithm_write,.algorithm_addr,.algorithm_wdata,.algorithm_rsp_valid,.algorithm_rsp_ready,
        .algorithm_rdata,.algorithm_error,.algorithm_drained,.memory_quarantined,.producer_local_quarantined
    );
    video_memory_hub #(.ADDRESS_BYTES(ADDRESS_BYTES)) memory_hub(
        .clk,.rst,.axi_enable,.producer_local_quarantined,.camera_req_valid,.camera_req_ready,.camera_addr,
        .camera_data,.camera_rsp_valid,.camera_rsp_ready,.camera_error,.camera_drained,.algorithm_req_valid,.algorithm_req_ready,
        .algorithm_write,.algorithm_addr,.algorithm_wdata,.algorithm_rsp_valid,.algorithm_rsp_ready,.algorithm_rdata,.algorithm_error,
        .algorithm_drained,.display_enable,.display_cancel,.span_req_valid,.span_req_ready,.span_addr,.span_bytes,
        .display_data_valid,.display_data_ready,.display_data,.display_done_valid,.display_done_ready,.display_outcome,.display_reason,
        .display_drained,.m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,
        .m_axi_awburst,.m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,.m_axi_bvalid,
        .m_axi_bready,.m_axi_bid,.m_axi_bresp,.m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,
        .m_axi_arlen,.m_axi_arsize,.m_axi_arburst,.m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,
        .m_axi_rresp,.m_axi_rlast,.algorithm_live,.read_occupied,.read_physical_idle,.write_busy,.read_quarantined,
        .write_quarantined,.direction_quarantined,.read_fault_reason,.write_fault_reason,
        .quarantined(memory_quarantined)
    );
endmodule
