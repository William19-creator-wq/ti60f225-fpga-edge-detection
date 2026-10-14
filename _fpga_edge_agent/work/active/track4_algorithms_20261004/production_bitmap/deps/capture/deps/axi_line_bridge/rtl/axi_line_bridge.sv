// AB01..03：64B快照→四拍128bit AXI；末W不是成功，未知owner不得复用。
module axi_line_bridge #(parameter logic [32:0] ADDRESS_BYTES=33'h10000000)(
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
    logic [511:0] write_buffer,read_buffer,next_read_buffer;
    logic [1:0] beat_index;
    logic read_error,uncertain,notice_valid,drain_tail,wait_real_b;
    wire physical_live=state==AW || state==W || state==B || state==AR || state==R;
    wire unsafe_clock=uncertain || !enable;
    wire [32:0] request_end={1'b0,line_addr}+33'd64;
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
        case(beat_index)
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
            state<=IDLE;address<=0;write_buffer<=0;read_buffer<=0;beat_index<=0;read_error<=0;uncertain<=0;
            notice_valid<=0;drain_tail<=0;wait_real_b<=0;line_error<=0;line_drained<=1;
        end else begin
            if(physical_live && !enable)uncertain<=1;
            case(state)
                IDLE:if(line_req_valid && line_req_ready)begin
                    address<=line_addr;write_buffer<=line_wdata;read_buffer<=0;beat_index<=0;
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
                        read_buffer<=next_read_buffer;read_error<=read_error || m_axi_rresp!=0;
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
