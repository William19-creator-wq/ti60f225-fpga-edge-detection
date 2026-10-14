// WP01..05：两个64B写端共用bridge；默认快照，板端可借稳定正文，UNKNOWN通知不关闭归属。
module axi_write_pair_service #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit FLAT_WRITES=0,BORROW_WRITE_BODY=0,BEAT_FIRST_WRITE=0,EXCLUSIVE_FLAT_WRITES=0,
    parameter bit ONEHOT_EXCLUSIVE_BEATS=0
)(
    input logic clk,rst,enable,
    input logic [1:0] c_req_valid,output logic [1:0] c_req_ready,
    input logic [31:0] c_addr[0:1],input logic [511:0] c_data[0:1],
    input wire [2559:0] flat_wdata,input wire [4:0] flat_select,
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
    localparam bit EXCLUSIVE_PROFILE=EXCLUSIVE_FLAT_WRITES&&FLAT_WRITES&&BORROW_WRITE_BODY&&BEAT_FIRST_WRITE;
    // E1：服务存身份/额度；默认锁5bit mask，板端唯一写源profile只锁3bit实际来源。
    logic active,owner,write_complete;
    logic [1:0] camera_credit;
    logic [2:0] first_fault,detected_fault;
    logic selected,can_select,selected_known;
    wire [31:0] selected_address=selected?c_addr[1]:c_addr[0];
    wire [511:0] selected_data;
    wire data_owner=BORROW_WRITE_BODY&&active?owner:selected;
    wire [4:0] data_flat_select;
    wire [5:0] data_picks={data_flat_select&{5{data_owner}},!data_owner};
    wire [1:0] write_beat_index;
    wire [127:0] selected_beat;
    wire [2:0] data_source;
    wire exclusive_mask_legal;
    generate if(FLAT_WRITES)begin:flat_write_tree
        // 单一组合AND/OR树；借用时从接受沿起固定owner与flat来源，不随新请求重选。
        wire [5:0] picks=data_picks;
        assign selected_data=({512{picks[0]}}&c_data[0])|
            ({512{picks[1]}}&flat_wdata[0+:512])|({512{picks[2]}}&flat_wdata[512+:512])|
            ({512{picks[3]}}&flat_wdata[1024+:512])|({512{picks[4]}}&flat_wdata[1536+:512])|
            ({512{picks[5]}}&flat_wdata[2048+:512]);
    end else begin:original_write_tree
        assign selected_data=data_owner?c_data[1]:c_data[0];
    end endgenerate
    generate if(EXCLUSIVE_PROFILE&&ONEHOT_EXCLUSIVE_BEATS)begin:onehot_exclusive_beat_tree
        // WB01：只译码真实锁源与原桥拍号，合法已知正文保留全部128位。
        // 精确case使非法/X/Z控制码全零；源数据的接受前known检查仍用原完整正文。
        reg [5:0] source_onehot;
        reg [3:0] beat_onehot;
        always @*begin
            source_onehot=6'd0;beat_onehot=4'd0;
            case(data_source)
                3'd0:source_onehot=6'b000001;
                3'd1:source_onehot=6'b000010;
                3'd2:source_onehot=6'b000100;
                3'd3:source_onehot=6'b001000;
                3'd4:source_onehot=6'b010000;
                3'd5:source_onehot=6'b100000;
                default:begin end
            endcase
            case(write_beat_index)
                2'd0:beat_onehot=4'b0001;
                2'd1:beat_onehot=4'b0010;
                2'd2:beat_onehot=4'b0100;
                2'd3:beat_onehot=4'b1000;
                default:begin end
            endcase
        end
        wire [127:0] fragments[0:23];
        wire [127:0] pairs[0:11];
        wire [127:0] groups[0:2];
        for(genvar source=0;source<6;source++)begin:sources
            for(genvar beat=0;beat<4;beat++)begin:beats
                wire choose_fragment=source_onehot[source]&beat_onehot[beat];
                wire [127:0] body;
                if(source==0)begin:camera
                    assign body=c_data[0][beat*128+:128];
                end else begin:algorithm
                    assign body=flat_wdata[(source-1)*512+beat*128+:128];
                end
                assign fragments[source*4+beat]={128{choose_fragment}}&body;
            end
        end
        for(genvar pair=0;pair<12;pair++)begin:pair_or
            assign pairs[pair]=fragments[pair*2]|fragments[pair*2+1];
        end
        for(genvar group_index=0;group_index<3;group_index++)begin:group_or
            assign groups[group_index]=pairs[group_index*4]|pairs[group_index*4+1]|
                pairs[group_index*4+2]|pairs[group_index*4+3];
        end
        assign selected_beat=groups[0]|groups[1]|groups[2];
    end else if(EXCLUSIVE_PROFILE)begin:exclusive_beat_tree
        reg [127:0] joined;
        // 唯一来源和桥内原拍号组成固定mux；不把通用多热OR改成优先选择。
        always @*begin
            joined=128'd0;
            case({data_source,write_beat_index})
                5'd0:joined=c_data[0][127:0];
                5'd1:joined=c_data[0][255:128];
                5'd2:joined=c_data[0][383:256];
                5'd3:joined=c_data[0][511:384];
                5'd4:joined=flat_wdata[127:0];
                5'd5:joined=flat_wdata[255:128];
                5'd6:joined=flat_wdata[383:256];
                5'd7:joined=flat_wdata[511:384];
                5'd8:joined=flat_wdata[639:512];
                5'd9:joined=flat_wdata[767:640];
                5'd10:joined=flat_wdata[895:768];
                5'd11:joined=flat_wdata[1023:896];
                5'd12:joined=flat_wdata[1151:1024];
                5'd13:joined=flat_wdata[1279:1152];
                5'd14:joined=flat_wdata[1407:1280];
                5'd15:joined=flat_wdata[1535:1408];
                5'd16:joined=flat_wdata[1663:1536];
                5'd17:joined=flat_wdata[1791:1664];
                5'd18:joined=flat_wdata[1919:1792];
                5'd19:joined=flat_wdata[2047:1920];
                5'd20:joined=flat_wdata[2175:2048];
                5'd21:joined=flat_wdata[2303:2176];
                5'd22:joined=flat_wdata[2431:2304];
                5'd23:joined=flat_wdata[2559:2432];
                default:begin end // 码6/7不可能经合法接受进入实际W。
            endcase
        end
        assign selected_beat=joined;
    end else if(BEAT_FIRST_WRITE&&FLAT_WRITES&&BORROW_WRITE_BODY)begin:fixed_beat_tree
        // 掩码OR与取固定拍可交换：联合解码24个固定切片，保留多热/零选择语义。
        // 拍号来自桥内寄存器；选源仍使用真实接受沿锁定的owner/mask。
        wire [127:0] fragments[0:23];
        for(genvar source=0;source<6;source++)begin:sources
            for(genvar beat=0;beat<4;beat++)begin:beats
                wire [127:0] body;
                wire choose_fragment=data_picks[source]&&(write_beat_index==2'(beat));
                if(source==0)begin:camera
                    assign body=c_data[0][beat*128+:128];
                end else begin:algorithm
                    assign body=flat_wdata[(source-1)*512+beat*128+:128];
                end
                assign fragments[source*4+beat]={128{choose_fragment}}&body;
            end
        end
        reg [127:0] joined;
        always @*begin
            joined=0;
            for(integer fragment=0;fragment<24;fragment=fragment+1)joined=joined|fragments[fragment];
        end
        assign selected_beat=joined;
    end else begin:unused_beat_tree
        assign selected_beat=128'd0;
    end endgenerate
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
    generate if(EXCLUSIVE_PROFILE)begin:exclusive_write_body
        logic [2:0] locked_source,offered_source;
        logic offered_legal;
        logic [4:0] locked_mask;
        assign data_source=locked_source;
        assign exclusive_mask_legal=offered_legal;
        // 精确识别单热；zero/multi-hot/X/Z均无合法算法来源，camera不使用此mask。
        always @*begin
            offered_source=3'd6;offered_legal=1'b1;
            case(flat_select)
                5'b00001:offered_source=3'd1;
                5'b00010:offered_source=3'd2;
                5'b00100:offered_source=3'd3;
                5'b01000:offered_source=3'd4;
                5'b10000:offered_source=3'd5;
                default:offered_legal=1'b0;
            endcase
            locked_mask=5'd0;
            case(locked_source)
                3'd1:locked_mask=5'b00001;
                3'd2:locked_mask=5'b00010;
                3'd3:locked_mask=5'b00100;
                3'd4:locked_mask=5'b01000;
                3'd5:locked_mask=5'b10000;
                default:begin end
            endcase
        end
        // 满512端口保留原正文/X检查语义；实际W只用上面的128固定切片。
        assign data_flat_select=active?locked_mask:flat_select;
        always_ff @(posedge clk)begin
            if(rst)locked_source<=3'd0;
            else if(request_fire)locked_source<=selected ? offered_source : 3'd0;
            // UNKNOWN/localQ不能释放；与原active的真实关闭条件完全一致。
            else if(response_fire && effective_drained && !quarantined)locked_source<=3'd0;
        end
    end else if(BORROW_WRITE_BODY)begin:borrow_write_body
        assign data_source=3'd0;
        assign exclusive_mask_legal=1'b1;
        logic [4:0] locked_flat_select;
        assign data_flat_select=active?locked_flat_select:flat_select;
        always_ff @(posedge clk)begin
            if(rst)locked_flat_select<=0;
            else if(request_fire)locked_flat_select<=flat_select;
            // 和active使用同一真实关闭条件；UNKNOWN或本地隔离仍持有旧来源。
            else if(response_fire && effective_drained && !quarantined)locked_flat_select<=0;
        end
    end else begin:snapshot_write_body
        assign data_source=3'd0;
        assign exclusive_mask_legal=1'b1;
        assign data_flat_select=flat_select;
    end endgenerate
    always_comb begin
        selected=(c_req_valid[0]===1'b1) ?
            ((c_req_valid[1]===1'b1) && camera_credit==0) : 1'b1;
        // X/Z是仿真语言状态；物理电路保留实际额度/B响应检查，避免宽X检测逻辑。
        selected_known=1'b1;
        // synthesis translate_off
        selected_known=(^selected_address!==1'bx) && (^selected_data!==1'bx);
        // synthesis translate_on
        can_select=!rst && enable && !active && !quarantined && bridge_req_ready && (|c_req_valid)!==1'b0;
        detected_fault=0;
        // 已公开回执后不能用新异常改写其error/drained正文。
        if(!rst && !active && m_axi_bvalid===1'b1)detected_fault=2;
        else if(!rst && active && !write_complete && !bridge_rsp_valid &&
                m_axi_bvalid===1'b1 && !last_write_fire)detected_fault=3;
        // 仅显式板端profile：接受前硬拒绝非法mask，不造未接受请求的回复。
        else if(EXCLUSIVE_PROFILE && can_select && selected &&
                c_req_valid[selected]===1'b1 && !exclusive_mask_legal)detected_fault=1;
        // synthesis translate_off
        else if(can_select && ((^c_req_valid===1'bx) || !selected_known))detected_fault=1;
        // synthesis translate_on
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
    axi_line_bridge #(.ADDRESS_BYTES(ADDRESS_BYTES),.USE_RAM_WRITE_BUFFER(1'b1),.NARROW_RAM_READ(1'b1),
        .BORROW_WRITE_BUFFER(BORROW_WRITE_BODY),
        .EXTERNAL_NARROW_WRITE(BEAT_FIRST_WRITE&&FLAT_WRITES&&BORROW_WRITE_BODY)) write_bridge(
        .clk,.rst,.enable,
        .line_req_valid(bridge_req_valid),.line_req_ready(bridge_req_ready),.line_write(1'b1),
        .line_addr(selected_address),.line_wdata(selected_data),
        .line_wdata_beat(selected_beat),.write_beat_index,
        .line_rsp_valid(bridge_rsp_valid),.line_rsp_ready(bridge_rsp_ready),.line_rdata(),
        .line_error(bridge_error),.line_drained(bridge_drained),.quarantined(bridge_quarantined),
        .m_axi_awvalid,.m_axi_awready,.m_axi_awaddr,.m_axi_awid,.m_axi_awlen,.m_axi_awsize,.m_axi_awburst,
        .m_axi_wvalid,.m_axi_wready,.m_axi_wdata,.m_axi_wstrb,.m_axi_wlast,
        .m_axi_bvalid,.m_axi_bready,.m_axi_bid,.m_axi_bresp,
        .m_axi_arvalid(),.m_axi_arready(1'b0),.m_axi_araddr(),.m_axi_arid(),.m_axi_arlen(),.m_axi_arsize(),.m_axi_arburst(),
        .m_axi_rvalid(1'b0),.m_axi_rready(),.m_axi_rdata(128'd0),.m_axi_rid(4'd0),.m_axi_rresp(2'd0),.m_axi_rlast(1'b0)
    );
endmodule
