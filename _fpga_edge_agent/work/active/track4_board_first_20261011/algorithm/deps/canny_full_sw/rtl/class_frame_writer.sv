// FC02/03：原class125位序；完整96bit身份、旧q/row/marker与类别检查。
module class_frame_writer #(
    parameter integer unsigned WIDTH=1920,HEIGHT=1080
)(
    input logic clk,rst,
    input logic cfg_valid,output wire cfg_ready,input logic [31:0] cfg_base,input logic [95:0] cfg_id,
    output wire cfg_rsp_valid,input logic cfg_rsp_ready,output wire cfg_rsp_error,
    input logic in_valid,output wire in_ready,input logic [124:0] in_payload,
    input logic abort_valid,input logic [95:0] abort_id,
    output wire done_valid,input logic done_ready,output wire done_error,done_aborted,done_drained,
    output wire [21:0] count,
    output wire line_req_valid,input logic line_req_ready,output wire line_write,
    output wire [31:0] line_addr,output wire [511:0] line_wdata,
    input logic line_rsp_valid,output wire line_rsp_ready,input logic [511:0] line_rdata,
    input logic line_error,line_drained,output wire quarantined
);
    logic [95:0] active_id;
    logic [9:0] expected_q;
    logic [10:0] expected_y;
    wire in_bad=in_payload[121:26]!=active_id || in_payload[14:4]!={expected_q,1'b0} || in_payload[25:15]!=expected_y ||
        in_payload[122]!=(expected_q==0 && expected_y==0) || in_payload[123]!=(expected_q==WIDTH/2-1) ||
        in_payload[124]!=(expected_q==WIDTH/2-1 && expected_y==HEIGHT-1) || in_payload[1:0]==3 || in_payload[3:2]==3;
    packed_frame_line_sink #(.ITEM_BITS(4),.ITEMS(WIDTH*HEIGHT/2),.ID_BITS(96),.DSP_BUFFER(1'b1)) sink(
        .clk(clk),.rst(rst),.cfg_valid(cfg_valid),.cfg_ready(cfg_ready),.cfg_base(cfg_base),.cfg_id(cfg_id),
        .cfg_rsp_valid(cfg_rsp_valid),.cfg_rsp_ready(cfg_rsp_ready),.cfg_rsp_error(cfg_rsp_error),
        .in_valid(in_valid),.in_ready(in_ready),.in_data(in_payload[3:0]),.in_bad(in_bad),.abort_valid(abort_valid),.abort_id(abort_id),
        .done_valid(done_valid),.done_ready(done_ready),.done_error(done_error),.done_aborted(done_aborted),.done_drained(done_drained),.count(count),
        .line_req_valid(line_req_valid),.line_req_ready(line_req_ready),.line_write(line_write),.line_addr(line_addr),.line_wdata(line_wdata),
        .line_rsp_valid(line_rsp_valid),.line_rsp_ready(line_rsp_ready),.line_rdata(line_rdata),.line_error(line_error),.line_drained(line_drained),.quarantined(quarantined));
    always_ff @(posedge clk)begin
        if(rst)begin active_id<=0;expected_q<=0;expected_y<=0;end
        else if(cfg_valid && cfg_ready)begin active_id<=cfg_id;expected_q<=0;expected_y<=0;end
        else if(in_valid && in_ready)begin
            if(expected_q==WIDTH/2-1)begin expected_q<=0;if(expected_y<HEIGHT-1)expected_y<=expected_y+11'd1;end
            else expected_q<=expected_q+10'd1;
        end
    end
endmodule
