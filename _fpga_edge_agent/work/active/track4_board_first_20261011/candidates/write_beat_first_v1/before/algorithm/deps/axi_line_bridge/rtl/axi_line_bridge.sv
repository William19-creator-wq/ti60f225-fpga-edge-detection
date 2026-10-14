// AB01..03：64B快照→四拍128bit AXI；末W不是成功，未知owner不得复用。
module axi_line_bridge #(
    parameter logic [32:0] ADDRESS_BYTES=33'h10000000,
    parameter bit USE_RAM_WRITE_BUFFER=0,NARROW_RAM_READ=0,
    parameter bit DSP_READ_BUFFER=1'b0,BORROW_WRITE_BUFFER=1'b0
)(
    input logic clk,rst,enable,
    input logic line_req_valid,output wire line_req_ready,input logic line_write,
    input logic [31:0] line_addr,input logic [511:0] line_wdata,
    output wire line_rsp_valid,input logic line_rsp_ready,output wire [511:0] line_rdata,
    output logic line_error,line_drained,output wire quarantined,
    output wire m_axi_awvalid,input logic m_axi_awready,output wire [31:0] m_axi_awaddr,
    output wire [3:0] m_axi_awid,output wire [7:0] m_axi_awlen,output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output wire m_axi_wvalid,input logic m_axi_wready,output logic [127:0] m_axi_wdata,
    output wire [15:0] m_axi_wstrb,output wire m_axi_wlast,
    input logic m_axi_bvalid,output wire m_axi_bready,input logic [3:0] m_axi_bid,input logic [1:0] m_axi_bresp,
    output wire m_axi_arvalid,input logic m_axi_arready,output wire [31:0] m_axi_araddr,
    output wire [3:0] m_axi_arid,output wire [7:0] m_axi_arlen,output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    input logic m_axi_rvalid,output wire m_axi_rready,input logic [127:0] m_axi_rdata,
    input logic [3:0] m_axi_rid,input logic [1:0] m_axi_rresp,input logic m_axi_rlast
);
    typedef enum logic [2:0] {IDLE,AW,W,B,AR,R,REPLY,QUARANTINE} state_t;
    state_t state;
    logic [31:0] address;
    wire [511:0] write_buffer;
    wire [127:0] narrow_write_buffer;
    wire [511:0] read_buffer;
    logic [511:0] next_read_buffer;
    logic [1:0] beat_index;
    logic read_error,uncertain,notice_valid,drain_tail,wait_real_b;
    wire physical_live=state==AW || state==W || state==B || state==AR || state==R;
    wire unsafe_clock=uncertain || !enable;
    wire [32:0] request_end={1'b0,line_addr}+33'd64;
    wire write_accept=line_req_valid&&line_req_ready&&line_write;
    wire read_reset=rst || (state==IDLE && line_req_valid && line_req_ready);
    wire read_capture=!rst && state==R && m_axi_rvalid && m_axi_rid==0 &&
        m_axi_rlast==(beat_index==3);
    generate if(BORROW_WRITE_BUFFER)begin: borrowed_write_body
        // 限定调用契约：已接受的生产者与正文保持到真实回复，隔离时禁止复用。
        // AW/W/B/REPLY沿与原桥一致；当前四拍索引只选择同一份持有正文。
        assign write_buffer=line_wdata;
        assign narrow_write_buffer=line_wdata[beat_index*128+:128];
    end else if(USE_RAM_WRITE_BUFFER)begin: ram_write_snapshot
      if(NARROW_RAM_READ)begin: beat_readout
        // 各128bit拍补成130bit，20位RAM字分别容纳四拍对应的5bit。
        // 接受沿仍写全512bit快照；同步窄读直接供AXI，不借用已接受后的生产者正文。
        wire [519:0] padded_input={2'd0,line_wdata[511:384],2'd0,line_wdata[383:256],
            2'd0,line_wdata[255:128],2'd0,line_wdata[127:0]};
        wire [129:0] padded_output;
        wire next_read=!rst&&(state==AW||(m_axi_wvalid&&m_axi_wready&&!m_axi_wlast));
        wire [1:0] read_beat=state==AW?2'd0:beat_index+2'd1;
        assign narrow_write_buffer=padded_output[127:0];
        assign write_buffer=512'd0;
        for(genvar stripe=0;stripe<26;stripe++)begin: words
            wire [19:0] stripe_input={padded_input[390+stripe*5+:5],padded_input[260+stripe*5+:5],
                padded_input[130+stripe*5+:5],padded_input[stripe*5+:5]};
            EFX_RAM10 #(.READ_WIDTH(5),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) storage(
                .WCLK(clk),.WE({2{write_accept}}),.WCLKE(1'b1),.WADDREN(1'b1),
                .WDATA(stripe_input),.WADDR(9'd0),
                .RCLK(clk),.RE(next_read),.RST(1'b0),.RADDREN(1'b1),
                .RDATA(padded_output[stripe*5+:5]),.RADDR({9'd0,read_beat}));
        end
      end else begin: full_readout
        wire [519:0] padded_input={8'd0,line_wdata};
        wire [519:0] padded_output;
        assign write_buffer=padded_output[511:0];
        assign narrow_write_buffer=128'd0;
        // 接受沿写完整快照；下一AW沿同步读回，W只能在AW实际交付后开始。
        // 26个20位条带用空闲RAM换512个FF；旧回复消费前不会覆盖这份快照。
        for(genvar stripe=0;stripe<26;stripe++)begin: words
            EFX_RAM10 #(.READ_WIDTH(20),.WRITE_WIDTH(20),.OUTPUT_REG(1'b0),.WRITE_MODE("READ_UNKNOWN")) storage(
                .WCLK(clk),.WE({2{write_accept}}),.WCLKE(1'b1),.WADDREN(1'b1),
                .WDATA(padded_input[stripe*20+:20]),.WADDR(9'd0),
                .RCLK(clk),.RE(state==AW),.RST(1'b0),.RADDREN(1'b1),
                .RDATA(padded_output[stripe*20+:20]),.RADDR(9'd0));
        end
      end
    end else begin: ff_write_snapshot
        logic [511:0] held_data;
        assign write_buffer=held_data;
        assign narrow_write_buffer=128'd0;
        always_ff @(posedge clk)begin
            if(rst)held_data<=0;
            else if(write_accept)held_data<=line_wdata;
        end
    end endgenerate
    generate if(DSP_READ_BUFFER)begin:dsp_read_snapshot
        // 四拍各自持有固定128bit切片；有效R拍只更新对应bank，其它拍与held回复保持。
        // 同步rst及IDLE接受沿清全512bit，与原快照一致；RRESP错误仍采样正文。
        for(genvar bank=0;bank<4;bank++)begin:beats
            wire [143:0] padded_input={16'd0,m_axi_rdata};
            wire [143:0] padded_output;
            wire bank_ce=read_reset || (read_capture && beat_index==2'(bank));
            assign read_buffer[bank*128+:128]=padded_output[127:0];
            for(genvar stripe=0;stripe<4;stripe++)begin:words
                wire [35:0] register_input=padded_input[stripe*36+:36];
                wire [47:0] registered_output;
                assign padded_output[stripe*36+:36]=registered_output[35:0];
                EFX_DSP48 #(.MODE("NORMAL"),.SIGNED(1'b0),.A_REG(1'b0),.B_REG(1'b0),
                    .C_REG(1'b0),.P_REG(1'b0),.OP_REG(1'b0),.W_REG(1'b0),.O_REG(1'b1),
                    .P_EXT("ALIGN_RIGHT"),.C_EXT("ALIGN_RIGHT"),
                    .M_SEL("P"),.N_SEL("C"),.W_SEL("X"),.SHIFTER(1'b0),
                    .RST_SYNC(1'b1),.O_REG_USE_CE(1'b1),.O_REG_USE_RST(1'b1)) storage(
                    .A(register_input[35:17]),.B(18'h20000),
                    .C({1'b0,register_input[16:0]}),.CASCIN(48'd0),.OP(2'b00),
                    .SHIFT_ENA(1'b0),.CLK(clk),.CE(bank_ce),.RST(read_reset),
                    .O(registered_output),.CASCOUT(),.OVFL());
            end
        end
    end else begin:ff_read_snapshot
        logic [511:0] held_data;
        assign read_buffer=held_data;
        always_ff @(posedge clk)begin
            if(read_reset)held_data<=0;
            else if(read_capture)held_data<=next_read_buffer;
        end
    end endgenerate
    assign line_req_ready=!rst && enable && state==IDLE;
    assign line_rsp_valid=!rst && (state==REPLY || (state==QUARANTINE && notice_valid));
    assign line_rdata=line_error ? 512'd0 : read_buffer;
    assign quarantined=state==QUARANTINE;
    assign m_axi_awvalid=!rst && state==AW;
    assign m_axi_awaddr=address;assign m_axi_awid=0;assign m_axi_awlen=3;assign m_axi_awsize=4;assign m_axi_awburst=1;
    assign m_axi_wvalid=!rst && state==W;assign m_axi_wstrb=16'hffff;assign m_axi_wlast=beat_index==3;
    assign m_axi_bready=!rst && (state==B || (state==QUARANTINE && wait_real_b));
    assign m_axi_arvalid=!rst && state==AR;
    assign m_axi_araddr=address;assign m_axi_arid=0;assign m_axi_arlen=3;assign m_axi_arsize=4;assign m_axi_arburst=1;
    assign m_axi_rready=!rst && (state==R || (state==QUARANTINE && drain_tail));
    always_comb begin
        if(USE_RAM_WRITE_BUFFER&&NARROW_RAM_READ)m_axi_wdata=narrow_write_buffer;
        else case(beat_index)
            0:m_axi_wdata=write_buffer[127:0];
            1:m_axi_wdata=write_buffer[255:128];
            2:m_axi_wdata=write_buffer[383:256];
            3:m_axi_wdata=write_buffer[511:384];
        endcase
        next_read_buffer=read_buffer;
        case(beat_index)
            0:next_read_buffer[127:0]=m_axi_rdata;
            1:next_read_buffer[255:128]=m_axi_rdata;
            2:next_read_buffer[383:256]=m_axi_rdata;
            3:next_read_buffer[511:384]=m_axi_rdata;
        endcase
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            state<=IDLE;address<=0;beat_index<=0;read_error<=0;uncertain<=0;
            notice_valid<=0;drain_tail<=0;wait_real_b<=0;line_error<=0;line_drained<=1;
        end else begin
            if(physical_live && !enable)uncertain<=1;
            case(state)
                IDLE:if(line_req_valid && line_req_ready)begin
                    address<=line_addr;beat_index<=0;
                    read_error<=0;uncertain<=0;notice_valid<=0;drain_tail<=0;wait_real_b<=0;line_error<=0;line_drained<=1;
                    if(line_addr[5:0]!=0 || request_end>ADDRESS_BYTES)begin line_error<=1;state<=REPLY;end
                    else state<=line_write ? AW : AR;
                end
                AW:if(m_axi_awready)state<=W;
                W:if(m_axi_wready)begin if(beat_index==3)state<=B;else beat_index<=beat_index+2'd1;end
                B:if(m_axi_bvalid)begin
                    if(m_axi_bid!=0 || unsafe_clock)begin
                        state<=QUARANTINE;notice_valid<=1;line_error<=1;line_drained<=0;wait_real_b<=m_axi_bid!=0;
                    end else begin state<=REPLY;line_error<=m_axi_bresp!=0;end
                end
                AR:if(m_axi_arready)state<=R;
                R:if(m_axi_rvalid)begin
                    if(m_axi_rid!=0 || m_axi_rlast!=(beat_index==3))begin
                        state<=QUARANTINE;notice_valid<=1;line_error<=1;line_drained<=0;
                        drain_tail<=!(m_axi_rid==0 && m_axi_rlast);
                    end else begin
                        read_error<=read_error || m_axi_rresp!=0;
                        if(beat_index==3)begin
                            if(unsafe_clock)begin state<=QUARANTINE;notice_valid<=1;line_error<=1;line_drained<=0;end
                            else begin state<=REPLY;line_error<=read_error || m_axi_rresp!=0;end
                        end else beat_index<=beat_index+2'd1;
                    end
                end
                REPLY:if(line_rsp_ready)state<=IDLE;
                QUARANTINE:begin
                    if(notice_valid && line_rsp_ready)notice_valid<=0;
                    if(drain_tail && m_axi_rvalid && m_axi_rid==0 && m_axi_rlast)drain_tail<=0;
                    if(wait_real_b && m_axi_bvalid && m_axi_bid==0)wait_real_b<=0;
                end
            endcase
        end
    end
    // synthesis translate_off
    initial if(ADDRESS_BYTES<64 || ADDRESS_BYTES>33'h100000000 || ADDRESS_BYTES[5:0]!=0)$fatal(1,"AXI bridge capacity");
    always @(posedge clk)if(!rst)begin
        if(line_rsp_valid && !line_error && !line_drained)$fatal(1,"AXI bridge unsafe success");
        if(m_axi_awvalid && m_axi_arvalid)$fatal(1,"AXI bridge owner overlap");
        if(quarantined && (line_req_ready || m_axi_awvalid || m_axi_arvalid || m_axi_wvalid))$fatal(1,"AXI bridge unknown owner reused");
    end
    // synthesis translate_on
endmodule
