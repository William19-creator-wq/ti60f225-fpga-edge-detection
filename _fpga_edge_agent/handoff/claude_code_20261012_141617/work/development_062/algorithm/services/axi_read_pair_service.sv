// RP01..04：实际line/span叶共享唯一DDR读口；物理idle不等于应用closed。
module axi_read_pair_service #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,arbiter_enable,algorithm_enable,display_enable,display_cancel,
    input logic line_req_valid,output wire line_req_ready,input logic [31:0] line_addr,
    output wire line_rsp_valid,input logic line_rsp_ready,output wire [511:0] line_rdata,
    output wire line_error,line_drained,
    input logic span_req_valid,output wire span_req_ready,input logic [31:0] span_addr,
    input logic [13:0] span_bytes,
    output wire display_data_valid,input logic display_data_ready,output wire [127:0] display_data,
    output wire display_done_valid,input logic display_done_ready,
    output wire [1:0] display_outcome,output wire [7:0] display_reason,output wire display_drained,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast,
    output wire line_quarantined,span_quarantined,bus_quarantined,quarantined,
    output wire [2:0] bus_fault_reason,output wire physical_idle,physical_occupied
);
    wire [1:0] client_arvalid,client_arready,client_rvalid,client_rready;
    wire [1:0][31:0] client_araddr;
    wire [1:0][3:0] client_arid,client_rid;
    wire [1:0][7:0] client_arlen;
    wire [1:0][2:0] client_arsize;
    wire [1:0][1:0] client_arburst,client_rresp;
    wire [1:0][127:0] client_rdata;
    wire [1:0] client_rlast;
    wire line_available,span_available;
    // E1：只堵新的应用接收，held数据/终态及已经公开的AR/R均不屏蔽。
    assign quarantined=line_quarantined || span_quarantined || bus_quarantined;
    assign line_req_ready=line_available && !quarantined;
    assign span_req_ready=span_available && !quarantined;

    axi_line_bridge #(.ADDRESS_BYTES(ADDRESS_BYTES),.DSP_READ_BUFFER(1'b1)) algorithm_line (
        .clk,.rst,.enable(algorithm_enable),
        .line_req_valid(line_req_valid && !quarantined),.line_req_ready(line_available),
        .line_write(1'b0),.line_addr,.line_wdata(512'd0),
        .line_rsp_valid,.line_rsp_ready,.line_rdata,.line_error,.line_drained,.quarantined(line_quarantined),
        // 固定read，不提供写服务，也不制造B响应或写成功。
        .m_axi_awvalid(),.m_axi_awready(1'b0),.m_axi_awaddr(),.m_axi_awid(),.m_axi_awlen(),.m_axi_awsize(),.m_axi_awburst(),
        .m_axi_wvalid(),.m_axi_wready(1'b0),.m_axi_wdata(),.m_axi_wstrb(),.m_axi_wlast(),
        .m_axi_bvalid(1'b0),.m_axi_bready(),.m_axi_bid(4'd0),.m_axi_bresp(2'd0),
        .m_axi_arvalid(client_arvalid[1]),.m_axi_arready(client_arready[1]),.m_axi_araddr(client_araddr[1]),
        .m_axi_arid(client_arid[1]),.m_axi_arlen(client_arlen[1]),.m_axi_arsize(client_arsize[1]),.m_axi_arburst(client_arburst[1]),
        .m_axi_rvalid(client_rvalid[1]),.m_axi_rready(client_rready[1]),.m_axi_rdata(client_rdata[1]),
        .m_axi_rid(client_rid[1]),.m_axi_rresp(client_rresp[1]),.m_axi_rlast(client_rlast[1])
    );
    display_span_axi #(.ADDRESS_BYTES(ADDRESS_BYTES),.READ_ID(4'd2)) display_span (
        .clk,.rst,.enable(display_enable),.cancel(display_cancel),
        .req_valid(span_req_valid && !quarantined),.req_ready(span_available),.req_addr(span_addr),.req_bytes(span_bytes),
        .data_valid(display_data_valid),.data_ready(display_data_ready),.data(display_data),
        .done_valid(display_done_valid),.done_ready(display_done_ready),.outcome(display_outcome),.reason(display_reason),
        .drained(display_drained),.quarantined(span_quarantined),
        .m_axi_arvalid(client_arvalid[0]),.m_axi_arready(client_arready[0]),.m_axi_araddr(client_araddr[0]),
        .m_axi_arid(client_arid[0]),.m_axi_arlen(client_arlen[0]),.m_axi_arsize(client_arsize[0]),.m_axi_arburst(client_arburst[0]),
        .m_axi_rvalid(client_rvalid[0]),.m_axi_rready(client_rready[0]),.m_axi_rdata(client_rdata[0]),
        .m_axi_rid(client_rid[0]),.m_axi_rresp(client_rresp[0]),.m_axi_rlast(client_rlast[0])
    );
    // E4：Q只禁止新选择；arbiter自己的pending AR仍保持至真实fire。
    axi_read_arbiter2 #(.ADDRESS_BYTES(ADDRESS_BYTES)) read_bus (
        .clk,.rst,.enable(arbiter_enable && !quarantined),
        .c_arvalid(client_arvalid),.c_arready(client_arready),.c_araddr(client_araddr),.c_arid(client_arid),
        .c_arlen(client_arlen),.c_arsize(client_arsize),.c_arburst(client_arburst),
        .c_rvalid(client_rvalid),.c_rready(client_rready),.c_rdata(client_rdata),.c_rid(client_rid),.c_rresp(client_rresp),.c_rlast(client_rlast),
        .m_axi_arvalid,.m_axi_arready,.m_axi_araddr,.m_axi_arid,.m_axi_arlen,.m_axi_arsize,.m_axi_arburst,
        .m_axi_rvalid,.m_axi_rready,.m_axi_rdata,.m_axi_rid,.m_axi_rresp,.m_axi_rlast,
        .idle(physical_idle),.occupied(physical_occupied),.quarantined(bus_quarantined),.fault_reason(bus_fault_reason)
    );
endmodule
