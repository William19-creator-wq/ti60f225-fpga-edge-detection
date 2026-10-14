// 板级共用版：请求正文由调用者持有，回复正文由物理服务持有；这里只保留owner。
module line_rpc_arbiter2(
    input logic clk,rst,
    input logic [1:0] req_valid,output wire [1:0] req_ready,input logic [1:0] req_write,
    input logic [31:0] req_addr[0:1],input logic [511:0] req_data[0:1],
    output wire [1:0] rsp_valid,input logic [1:0] rsp_ready,
    output wire [511:0] rsp_data,output wire rsp_error,rsp_drained,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    assign rsp_data=line_rdata;
    assign rsp_error=line_error;
    assign rsp_drained=line_drained;
    board_native_rpc_arbiter2 ownership(
        .clk,.rst,
        .a_valid(req_valid[0]),.a_ready(req_ready[0]),.a_write(req_write[0]),.a_addr(req_addr[0]),.a_wdata(req_data[0]),
        .a_rsp_valid(rsp_valid[0]),.a_rsp_ready(rsp_ready[0]),.a_drained(),
        .b_valid(req_valid[1]),.b_ready(req_ready[1]),.b_write(req_write[1]),.b_addr(req_addr[1]),.b_wdata(req_data[1]),
        .b_rsp_valid(rsp_valid[1]),.b_rsp_ready(rsp_ready[1]),.b_drained(),
        .req_valid(line_req_valid),.req_ready(line_req_ready),.req_write(line_write),.req_addr(line_addr),.req_wdata(line_wdata),
        .rsp_valid(line_rsp_valid),.rsp_ready(line_rsp_ready),.drained(line_drained),.fault(quarantined));
endmodule
