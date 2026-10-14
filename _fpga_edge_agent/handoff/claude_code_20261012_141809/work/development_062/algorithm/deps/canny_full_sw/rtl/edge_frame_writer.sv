// PB01/02：顺序edge精确转1bit位图或兼容8bit；低index位于低bit，子handle不是CJ截断。
module edge_frame_writer #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,ITEM_BITS=8
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [63:0] cfg_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output wire cfg_rsp_error,
    input logic in_valid,output wire in_ready,input logic [20:0] in_index,input logic in_edge,input logic [63:0] in_id,
    input logic abort_valid,input logic [63:0] abort_id,
    output wire done_valid,input logic done_ready,output wire done_error,done_aborted,done_drained,
    output wire [21:0] count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    logic [63:0] active_id;
    wire in_bad=in_id!=active_id || {1'b0,in_index}!=count;
    packed_frame_line_sink #(.ITEM_BITS(ITEM_BITS),.ITEMS(WIDTH*HEIGHT),.ID_BITS(64),.DSP_BUFFER(1'b1)) sink(
        .clk(clk),.rst(rst),.cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_base(cfg_base),.cfg_id(cfg_id),
        .cfg_rsp_valid(cfg_rsp_valid),.cfg_rsp_ready(cfg_rsp_ready),.cfg_rsp_error(cfg_rsp_error),
        .in_valid(in_valid),.in_ready(in_ready),.in_data({ITEM_BITS{in_edge}}),.in_bad(in_bad),.abort_valid(abort_valid),.abort_id(abort_id),
        .done_valid(done_valid),.done_ready(done_ready),.done_error(done_error),.done_aborted(done_aborted),.done_drained(done_drained),.count(count),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(quarantined));
    always_ff @(posedge clk)begin if(rst)active_id<=0;else if(cfg_valid && cfg_ready)active_id<=cfg_id;end
    // synthesis translate_off
    initial if(ITEM_BITS!=1 && ITEM_BITS!=8) $fatal(1,"PB edge representation must be1 or8 bits");
    // synthesis translate_on
endmodule
