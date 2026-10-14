// WP01..05：两个64B写端共用实际bridge快照；UNKNOWN通知不关闭归属。
module axi_write_pair_service #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000
)(
    input logic clk,rst,enable,
    input logic [1:0] c_req_valid,output logic [1:0] c_req_ready,
    input logic [31:0] c_addr[0:1],input logic [511:0] c_data[0:1],
    output logic [1:0] c_rsp_valid,input logic [1:0] c_rsp_ready,
    output wire [1:0] c_error,c_drained,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output wire [127:0] m_axi_wdata,
    output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp,
    output wire busy,quarantined,bridge_quarantined,output logic local_quarantined,
    output wire [2:0] fault_reason
);
    // E1：服务只存身份/额度。512bit写快照由唯一的actual bridge保存。
    logic active,owner,write_complete;
    logic [1:0] camera_credit;
    logic [2:0] first_fault,detected_fault;
    logic selected,can_select,selected_known;
    wire bridge_req_ready,bridge_rsp_valid,bridge_rsp_ready,bridge_error,bridge_drained;
    wire effective_error=bridge_error || local_quarantined;
    wire effective_drained=bridge_drained && !local_quarantined;
    wire bridge_req_valid=|(c_req_valid & c_req_ready);
    wire request_fire=bridge_req_valid && bridge_req_ready;
    wire response_fire=bridge_rsp_valid && bridge_rsp_ready;
    wire last_write_fire=m_axi_wvalid && m_axi_wready && m_axi_wlast;
    assign quarantined=local_quarantined || bridge_quarantined;
    assign busy=active || quarantined;
    assign fault_reason=first_fault!=0 ? first_fault : (bridge_quarantined ? 3'd4 : 3'd0);
    assign c_error={2{effective_error}};assign c_drained={2{effective_drained}};
    // E5：错误后旧通知/真实B不屏蔽，只由实际owner接收方决定ready。
    assign bridge_rsp_ready=!rst && active && c_rsp_ready[owner];
    always_comb begin
        selected=(c_req_valid[0]===1'b1) ?
            ((c_req_valid[1]===1'b1) && camera_credit==0) : 1'b1;
        selected_known=(^c_addr[selected]!==1'bx) && (^c_data[selected]!==1'bx);
        can_select=!rst && enable && !active && !quarantined && bridge_req_ready && (|c_req_valid)!==1'b0;
        detected_fault=0;
        // 已公开回执后不能用新异常改写其error/drained正文。
        if(!rst && !active && m_axi_bvalid===1'b1)detected_fault=2;
        else if(!rst && active && !write_complete && !bridge_rsp_valid &&
                m_axi_bvalid===1'b1 && !last_write_fire)detected_fault=3;
        else if(can_select && ((^c_req_valid===1'bx) || !selected_known))detected_fault=1;
        c_req_ready=0;c_rsp_valid=0;
        // bridge ready不依赖valid；同沿真实接纳避免一份重复544bit holding。
        if(can_select && detected_fault==0 && selected_known && c_req_valid[selected]===1'b1)
            c_req_ready[selected]=1;
        if(!rst && active)c_rsp_valid[owner]=bridge_rsp_valid;
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            active<=0;owner<=0;write_complete<=0;camera_credit<=3;
            local_quarantined<=0;first_fault<=0;
        end else begin
            if(!local_quarantined && detected_fault!=0)begin local_quarantined<=1;first_fault<=detected_fault;end
            if(request_fire)begin
                active<=1;owner<=selected;write_complete<=0;
                if(selected)camera_credit<=3;
                else if(camera_credit!=0)camera_credit<=camera_credit-2'd1;
            end
            if(last_write_fire)write_complete<=1;
            if(response_fire && effective_drained && !quarantined)active<=0;
        end
    end
    // E4：复用真实四拍桥；固定write，未使用的读通道无伪响应。
    axi_line_bridge #(.ADDRESS_BYTES(ADDRESS_BYTES)) write_bridge(
        .clk,.rst,.enable,
        .line_req_valid(bridge_req_valid),.line_req_ready(bridge_req_ready),.line_write(1'b1),
        .line_addr(c_addr[selected]),.line_wdata(c_data[selected]),
        .line_rsp_valid(bridge_rsp_valid),.line_rsp_ready(bridge_rsp_ready),.line_rdata(),
        .line_error(bridge_error),.line_drained(bridge_drained),.quarantined(bridge_quarantined),
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,
        .m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .m_axi_arvalid(),.m_axi_arready(1'b0),.m_axi_araddr(),.m_axi_arid(),.m_axi_arlen(),.m_axi_arsize(),.m_axi_arburst(),
        .m_axi_rvalid(1'b0),.m_axi_rready(),.m_axi_rdata(128'd0),.m_axi_rid(4'd0),.m_axi_rresp(2'd0),.m_axi_rlast(1'b0)
    );
endmodule
