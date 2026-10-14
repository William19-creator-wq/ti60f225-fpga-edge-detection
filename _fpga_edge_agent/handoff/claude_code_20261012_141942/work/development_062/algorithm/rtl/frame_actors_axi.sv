// FA01/02/05：两个独立执行模块。Source/Result 租约和 RX close 由调用控制器管理。
module frame_actors_axi #(
    parameter integer WIDTH = 1920, HEIGHT = 1080, RESULT_ITEM_BITS = 1,
    parameter logic [32:0] ADDRESS_BYTES = 33'h10000000,parameter bit FLAT_WRITES=0,BORROW_WRITE_BODY=0,EXCLUSIVE_FLAT_WRITES=0,
    parameter bit ENABLE_CIRCLE_REFINE=1'b0,ONEHOT_EXCLUSIVE_BEATS=0
)(
    input logic clk, rst, axi_enable,
    input logic cap_job_valid, output wire cap_job_ready,
    input logic [31:0] cap_base, input logic [63:0] cap_handle,
    input logic [95:0] cap_scope, input logic [1:0] cap_bayer,
    input logic in_valid, output wire in_ready, input logic [19:0] raw_pair,
    input logic [10:0] in_x_even, in_y, input logic [2:0] in_markers,
    input logic in_bad, input logic [63:0] in_handle,
    input logic cap_cancel_valid, input logic [63:0] cap_cancel_id,
    output wire cap_done_valid, input logic cap_done_ready,
    output wire [63:0] cap_done_id, output wire [95:0] cap_done_scope,
    output wire [1:0] cap_outcome, cap_failed_stage, output wire [7:0] cap_reason,
    output wire [21:0] cap_raw_pairs, cap_rgb_pairs, cap_written_lines, cap_discarded_rgb,
    output wire [31:0] cap_logical_bytes, cap_physical_bytes,
    output wire cap_stop, cap_quarantined,
    input logic alg_sobel_mode,
    input logic alg_job_valid, output wire alg_job_ready,
    input logic [141:0] alg_cj, input logic [194:0] alg_origin, input logic [63:0] alg_handle,
    input logic [31:0] source_base, class_base, queue_base, result_base, gradient_base,
    input logic alg_cancel_valid, input logic [95:0] alg_cancel_scope,
    output wire grad_valid, input logic grad_ready, output wire [184:0] grad_payload,
    output wire alg_done_valid, input logic alg_done_ready,
    output wire [95:0] alg_done_scope, output wire [194:0] alg_done_origin,
    output wire [1:0] alg_outcome, output wire [31:0] alg_reason,
    output wire [20:0] reader_pairs, canny_input, canny_class,
    output wire [21:0] output_pixels, edge_pixels, discarded_fp,
    output wire [591:0] r2_status_snapshot, output wire [3:0] alg_phase,
    output wire alg_quarantined, quarantined,
    input logic display_enable, display_cancel, span_req_valid, output wire span_req_ready,
    input logic [31:0] span_addr, input logic [13:0] span_bytes,
    output wire display_data_valid, input logic display_data_ready, output wire [127:0] display_data,
    output wire display_done_valid, input logic display_done_ready,
    output wire [1:0] display_outcome, output wire [7:0] display_reason, output wire display_drained,
    output wire memory_quarantined, algorithm_live, read_occupied, read_physical_idle, write_busy,
    output wire read_quarantined, write_quarantined, direction_quarantined,
    output wire [2:0] read_fault_reason, write_fault_reason,
    output wire m_axi_awvalid, input logic m_axi_awready, output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid, output wire [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize, output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid, input logic m_axi_wready,
    output wire [127:0] m_axi_wdata, output wire [15:0] m_axi_wstrb, output wire m_axi_wlast,
    input logic m_axi_bvalid, output wire m_axi_bready,
    input logic [3:0] m_axi_bid, input logic [1:0] m_axi_bresp,
    output wire m_axi_arvalid, input logic m_axi_arready, output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid, output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize, output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid, output wire m_axi_rready, input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid, input logic [1:0] m_axi_rresp, input logic m_axi_rlast
);
    wire camera_req_valid, camera_req_ready, camera_rsp_valid, camera_rsp_ready, camera_error, camera_drained;
    wire [31:0] camera_addr;
    wire [511:0] camera_data;
    wire algorithm_req_valid, algorithm_req_ready, algorithm_write, algorithm_rsp_valid, algorithm_rsp_ready;
    wire algorithm_error, algorithm_drained;
    wire [31:0] algorithm_addr;
    wire [511:0] algorithm_wdata, algorithm_rdata;
    wire [2559:0] flat_wdata;wire [4:0] flat_select;
    wire cap_internal_ready, cap_input_ready, cap_internal_stop, camera_write;
    wire alg_internal_ready, algorithm_local_q;
    wire producer_local_quarantined = cap_quarantined || algorithm_local_q;
    wire new_allowed = !rst && axi_enable && !memory_quarantined && !producer_local_quarantined;
    assign cap_job_ready = cap_internal_ready && new_allowed;
    assign alg_job_ready = alg_internal_ready && new_allowed;
    assign in_ready = cap_input_ready && !memory_quarantined;
    assign cap_stop = cap_internal_stop || memory_quarantined;
    assign quarantined = producer_local_quarantined || memory_quarantined;

    raw_source_join #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) capture_actor (
        .clk, .rst, .job_valid(cap_job_valid && new_allowed), .job_ready(cap_internal_ready),
        .job_base(cap_base), .job_handle(cap_handle), .job_scope(cap_scope), .phase(cap_bayer),
        .in_valid(in_valid && !memory_quarantined), .in_ready(cap_input_ready), .raw_pair,
        .in_x_even, .in_y, .in_markers, .in_bad, .in_handle,
        .cancel_valid(cap_cancel_valid), .cancel_id(cap_cancel_id),
        .done_valid(cap_done_valid), .done_ready(cap_done_ready), .done_id(cap_done_id), .done_scope(cap_done_scope),
        .outcome(cap_outcome), .reason(cap_reason), .failed_stage(cap_failed_stage),
        .accepted_raw(cap_raw_pairs), .accepted_rgb(cap_rgb_pairs), .written_lines(cap_written_lines),
        .discarded_rgb(cap_discarded_rgb), .logical_bytes(cap_logical_bytes), .physical_bytes(cap_physical_bytes),
        .source_stop(cap_internal_stop), .quarantined(cap_quarantined),
        .line_req_valid(camera_req_valid), .line_req_ready(camera_req_ready), .line_write(camera_write),
        .line_addr(camera_addr), .line_wdata(camera_data), .line_rsp_valid(camera_rsp_valid),
        .line_rsp_ready(camera_rsp_ready), .line_rdata(512'd0), .line_error(camera_error), .line_drained(camera_drained)
    );
    board_algorithm_rpc #(.WIDTH(WIDTH), .HEIGHT(HEIGHT), .RESULT_ITEM_BITS(RESULT_ITEM_BITS), .ADDRESS_BYTES(ADDRESS_BYTES),
        .ENABLE_CIRCLE_REFINE(ENABLE_CIRCLE_REFINE)) algorithm_actor (
        .flat_wdata,.flat_select,        .sobel_mode(alg_sobel_mode), .clk, .rst, .axi_enable, .job_valid(alg_job_valid && new_allowed), .job_ready(alg_internal_ready),
        .job_cj(alg_cj), .job_origin(alg_origin), .job_handle(alg_handle),
        .source_base, .class_base, .queue_base, .result_base, .gradient_base,
        .cancel_valid(alg_cancel_valid), .cancel_scope(alg_cancel_scope),
        .grad_valid, .grad_ready, .grad_payload, .done_valid(alg_done_valid), .done_ready(alg_done_ready),
        .done_scope(alg_done_scope), .done_origin(alg_done_origin), .outcome(alg_outcome), .reason(alg_reason),
        .reader_pairs, .canny_input, .canny_class, .output_pixels, .edge_pixels, .discarded_fp,
        .r2_status_snapshot, .phase(alg_phase), .quarantined(alg_quarantined),
        .producer_local_quarantined(algorithm_local_q),
        .algorithm_req_valid, .algorithm_req_ready, .algorithm_write, .algorithm_addr, .algorithm_wdata,
        .algorithm_rsp_valid, .algorithm_rsp_ready, .algorithm_rdata, .algorithm_error, .algorithm_drained,
        .memory_quarantined
    );
    video_memory_hub #(.ADDRESS_BYTES(ADDRESS_BYTES),.FLAT_WRITES(FLAT_WRITES),.BORROW_WRITE_BODY(BORROW_WRITE_BODY),.EXCLUSIVE_FLAT_WRITES(EXCLUSIVE_FLAT_WRITES),
        .ONEHOT_EXCLUSIVE_BEATS(ONEHOT_EXCLUSIVE_BEATS)) memory_hub (
        .flat_wdata,.flat_select,        .clk, .rst, .axi_enable, .producer_local_quarantined,
        .camera_req_valid, .camera_req_ready, .camera_addr, .camera_data,
        .camera_rsp_valid, .camera_rsp_ready, .camera_error, .camera_drained,
        .algorithm_req_valid, .algorithm_req_ready, .algorithm_write, .algorithm_addr, .algorithm_wdata,
        .algorithm_rsp_valid, .algorithm_rsp_ready, .algorithm_rdata, .algorithm_error, .algorithm_drained,
        .display_enable, .display_cancel, .span_req_valid, .span_req_ready, .span_addr, .span_bytes,
        .display_data_valid, .display_data_ready, .display_data, .display_done_valid, .display_done_ready,
        .display_outcome, .display_reason, .display_drained,
        .m_axi_awvalid, .m_axi_awready, .m_axi_awaddr, .m_axi_awid, .m_axi_awlen, .m_axi_awsize, .m_axi_awburst,
        .m_axi_wvalid, .m_axi_wready, .m_axi_wdata, .m_axi_wstrb, .m_axi_wlast,
        .m_axi_bvalid, .m_axi_bready, .m_axi_bid, .m_axi_bresp,
        .m_axi_arvalid, .m_axi_arready, .m_axi_araddr, .m_axi_arid, .m_axi_arlen, .m_axi_arsize, .m_axi_arburst,
        .m_axi_rvalid, .m_axi_rready, .m_axi_rdata, .m_axi_rid, .m_axi_rresp, .m_axi_rlast,
        .algorithm_live, .read_occupied, .read_physical_idle, .write_busy,
        .read_quarantined, .write_quarantined, .direction_quarantined, .read_fault_reason, .write_fault_reason,
        .quarantined(memory_quarantined)
    );
endmodule
