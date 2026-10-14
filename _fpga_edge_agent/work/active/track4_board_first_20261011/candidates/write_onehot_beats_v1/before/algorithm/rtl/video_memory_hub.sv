// DH03..06：公共三客户端读写链路。算法只保存方向，payload由实际leaf保存。
module video_memory_hub #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,parameter bit FLAT_WRITES=0,BORROW_WRITE_BODY=0,EXCLUSIVE_FLAT_WRITES=0
)(
    input logic clk,rst,axi_enable,producer_local_quarantined,
    input logic camera_req_valid,output wire camera_req_ready,
    input logic [31:0] camera_addr,input logic [511:0] camera_data,
    output wire camera_rsp_valid,input logic camera_rsp_ready,output wire camera_error,camera_drained,
    input logic algorithm_req_valid,output wire algorithm_req_ready,input logic algorithm_write,
    input logic [31:0] algorithm_addr,input logic [511:0] algorithm_wdata,
    input wire [2559:0] flat_wdata,input wire [4:0] flat_select,
    output wire algorithm_rsp_valid,input logic algorithm_rsp_ready,
    output wire [511:0] algorithm_rdata,output wire algorithm_error,algorithm_drained,
    input logic display_enable,display_cancel,span_req_valid,output wire span_req_ready,
    input logic [31:0] span_addr,input logic [13:0] span_bytes,
    output wire display_data_valid,input logic display_data_ready,output wire [127:0] display_data,
    output wire display_done_valid,input logic display_done_ready,
    output wire [1:0] display_outcome,output wire [7:0] display_reason,output wire display_drained,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,output wire m_axi_wvalid,input logic m_axi_wready,
    output wire [127:0] m_axi_wdata,output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,input logic m_axi_rvalid,output wire m_axi_rready,
    input logic [127:0] m_axi_rdata,input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast,
    output wire algorithm_live,read_occupied,read_physical_idle,write_busy,
    output wire read_quarantined,write_quarantined,quarantined,
    output logic direction_quarantined,output wire [2:0] read_fault_reason,write_fault_reason
);
    logic algorithm_active,locked_write;
    wire read_available,write_available,read_rsp_valid,write_rsp_valid;
    wire [511:0] read_data;
    wire read_error,read_drained,write_error,write_drained;
    wire [1:0] write_req_valid,write_req_ready,write_rsp_vector,write_rsp_ready,write_errors,write_drains;
    wire [31:0] write_addr[0:1];wire [511:0] write_data[0:1];
    wire read_line_q,read_span_q,read_bus_q,write_bridge_q,write_local_q;
    wire direction_known=algorithm_write===1'b0 || algorithm_write===1'b1;
    assign quarantined=producer_local_quarantined || read_quarantined || write_quarantined || direction_quarantined;
    wire new_allowed=!rst && axi_enable && !quarantined;
    wire new_algorithm=new_allowed && !algorithm_active && direction_known;
    wire algorithm_fire=algorithm_req_valid && algorithm_req_ready;
    wire algorithm_reply_fire=algorithm_rsp_valid && algorithm_rsp_ready;
    assign algorithm_live=algorithm_active;
    assign algorithm_req_ready=new_algorithm && (algorithm_write ? write_available : read_available);
    assign algorithm_rsp_valid=!rst && algorithm_active && (locked_write ? write_rsp_valid : read_rsp_valid);
    assign algorithm_rdata=locked_write ? 512'd0 : read_data;
    assign algorithm_error=locked_write ? write_error : read_error;
    assign algorithm_drained=locked_write ? write_drained : read_drained;
    // E1/2：consume UNKNOWN不清active。无新512/地址holding或假内存回执。
    always_ff @(posedge clk)begin
        if(rst)begin algorithm_active<=0;locked_write<=0;direction_quarantined<=0;end
        else begin
            if(new_allowed && !algorithm_active && algorithm_req_valid && !direction_known)direction_quarantined<=1;
            if(algorithm_fire)begin algorithm_active<=1;locked_write<=algorithm_write;end
            if(algorithm_reply_fire && algorithm_drained)algorithm_active<=0;
        end
    end
    assign write_req_valid={algorithm_req_valid && new_algorithm && algorithm_write,camera_req_valid && new_allowed};
    assign write_addr[0]=camera_addr;assign write_addr[1]=algorithm_addr;
    assign write_data[0]=camera_data;assign write_data[1]=algorithm_wdata;
    assign camera_req_ready=write_req_ready[0] && new_allowed;
    assign camera_rsp_valid=write_rsp_vector[0];assign camera_error=write_errors[0];assign camera_drained=write_drains[0];
    assign write_available=write_req_ready[1];assign write_rsp_valid=write_rsp_vector[1];
    assign write_error=write_errors[1];assign write_drained=write_drains[1];
    assign write_rsp_ready={algorithm_active && locked_write && algorithm_rsp_ready,camera_rsp_ready};
    axi_write_pair_service #(.ADDRESS_BYTES(ADDRESS_BYTES),.FLAT_WRITES(FLAT_WRITES),.BORROW_WRITE_BODY(BORROW_WRITE_BODY),
        .BEAT_FIRST_WRITE(FLAT_WRITES&&BORROW_WRITE_BODY),.EXCLUSIVE_FLAT_WRITES(EXCLUSIVE_FLAT_WRITES)) write_service(
        .flat_wdata,.flat_select,        .clk,.rst,.enable(axi_enable),.c_req_valid(write_req_valid),.c_req_ready(write_req_ready),
        .c_addr(write_addr),.c_data(write_data),.c_rsp_valid(write_rsp_vector),.c_rsp_ready(write_rsp_ready),
        .c_error(write_errors),.c_drained(write_drains),
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,.m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .busy(write_busy),.quarantined(write_quarantined),.bridge_quarantined(write_bridge_q),
        .local_quarantined(write_local_q),.fault_reason(write_fault_reason)
    );
    wire span_available;
    assign span_req_ready=span_available && new_allowed && display_enable;
    // E3：跨方向Q不变成enable下降；旧span已接受范围内的物理分段仍是旧借用。
    axi_read_pair_service #(.ADDRESS_BYTES(ADDRESS_BYTES)) read_service(
        .clk,.rst,.arbiter_enable(axi_enable),.algorithm_enable(axi_enable),
        .display_enable(display_enable && axi_enable),.display_cancel,
        .line_req_valid(algorithm_req_valid && new_algorithm && !algorithm_write),.line_req_ready(read_available),
        .line_addr(algorithm_addr),.line_rsp_valid(read_rsp_valid),
        .line_rsp_ready(algorithm_active && !locked_write && algorithm_rsp_ready),
        .line_rdata(read_data),.line_error(read_error),.line_drained(read_drained),
        .span_req_valid(span_req_valid && new_allowed && display_enable),.span_req_ready(span_available),.span_addr,.span_bytes,
        .display_data_valid,.display_data_ready,.display_data,.display_done_valid,.display_done_ready,
        .display_outcome,.display_reason,.display_drained,
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast,
        .line_quarantined(read_line_q),.span_quarantined(read_span_q),.bus_quarantined(read_bus_q),
        .quarantined(read_quarantined),.bus_fault_reason(read_fault_reason),
        .physical_idle(read_physical_idle),.physical_occupied(read_occupied)
    );
endmodule
