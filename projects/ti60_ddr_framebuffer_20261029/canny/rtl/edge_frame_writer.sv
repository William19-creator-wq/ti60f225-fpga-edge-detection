// FC02/03：顺序edge像素转连续8bit灰度；子handle不是CJ截断。
module edge_frame_writer #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080,EXTERNAL_STORAGE=0,LANES=1
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [63:0] cfg_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output wire cfg_rsp_error,
    input logic in_valid,output wire in_ready,input logic [20:0] in_index,input logic in_edge,input logic [7:0] in_edges,input logic [63:0] in_id,
    input logic abort_valid,input logic [63:0] abort_id,
    output wire done_valid,input logic done_ready,output wire done_error,done_aborted,done_drained,
    output wire [21:0] count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined,
    output wire storage_clear,storage_write,output wire [511:0] storage_next,
    input wire [511:0] storage_current
);
    logic [63:0] active_id;
    localparam integer unsigned N=WIDTH*HEIGHT,CHUNKS=(N+LANES-1)/LANES;
    wire [21:0] chunk_count;
    wire [24:0] next_pixel=25'(chunk_count)*25'(LANES);
    // Sink counts chunks; public completion/cancellation accounting stays pixels.
    assign count=(next_pixel>25'(N))?22'(N):next_pixel[21:0];
    wire in_bad=in_id!=active_id || {4'b0,in_index}!=next_pixel;
    wire [8*LANES-1:0] expanded_edges;
    for(genvar lane=0;lane<LANES;lane=lane+1)begin:expand
        wire valid_lane=({1'b0,in_index}+22'(lane))<22'(N);
        assign expanded_edges[8*lane+:8]={8{valid_lane && ((LANES==1)?in_edge:in_edges[lane])}};
    end
    initial if(LANES!=1 && LANES!=8)$fatal(1,"Edge writer lanes must be 1 or 8");
    packed_frame_line_sink #(.EXTERNAL_STORAGE(EXTERNAL_STORAGE),.ITEM_BITS(8*LANES),.ITEMS(CHUNKS),.ID_BITS(64)) sink(
        .storage_clear,.storage_write,.storage_next,.storage_current,
        .clk(clk),.rst(rst),.cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_base(cfg_base),.cfg_id(cfg_id),
        .cfg_rsp_valid(cfg_rsp_valid),.cfg_rsp_ready(cfg_rsp_ready),.cfg_rsp_error(cfg_rsp_error),
        .in_valid(in_valid),.in_ready(in_ready),.in_data(expanded_edges),.in_bad(in_bad),.abort_valid(abort_valid),.abort_id(abort_id),
        .done_valid(done_valid),.done_ready(done_ready),.done_error(done_error),.done_aborted(done_aborted),.done_drained(done_drained),.count(chunk_count),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(quarantined));
    always_ff @(posedge clk)begin if(rst)active_id<=0;else if(cfg_valid && cfg_ready)active_id<=cfg_id;end
endmodule
