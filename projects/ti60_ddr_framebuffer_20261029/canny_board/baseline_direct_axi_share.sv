// Two physical AXI128 masters share the existing DDR controller, in core_clk.
// Port 0: unchanged camera/display RAW buffers, below 64 MiB.
// Port 1: snapshots/algorithms, 64..128 MiB. IDs are preserved, not frame IDs.
// At most one outstanding burst PER DIRECTION; reads and writes remain parallel.
// Ownership lasts through the actual B / final R handshake, never just AW/WLAST.
// rst is legal only with the DDR bus reset/quiescent. enable blocks NEW grants.
module baseline_direct_axi_share #(parameter integer BASELINE_PORT0=1) (
    input logic clk, rst, enable,
    input logic [1:0] c_awvalid, output logic [1:0] c_awready,
    input logic [1:0][31:0] c_awaddr, input logic [1:0][3:0] c_awid,
    input logic [1:0][7:0] c_awlen, input logic [1:0][2:0] c_awsize,
    input logic [1:0][1:0] c_awburst, input logic [1:0][3:0] c_awcache,
    input logic [1:0][2:0] c_awprot, input logic [1:0] c_awlock,
    input logic [1:0] c_wvalid, output logic [1:0] c_wready,
    input logic [1:0][127:0] c_wdata, input logic [1:0][15:0] c_wstrb,
    input logic [1:0] c_wlast, output logic [1:0] c_bvalid,
    input logic [1:0] c_bready, output wire [1:0][3:0] c_bid,
    output wire [1:0][1:0] c_bresp,
    input logic [1:0] c_arvalid, output logic [1:0] c_arready,
    input logic [1:0][31:0] c_araddr, input logic [1:0][3:0] c_arid,
    input logic [1:0][7:0] c_arlen, input logic [1:0][2:0] c_arsize,
    input logic [1:0][1:0] c_arburst, input logic [1:0][3:0] c_arcache,
    input logic [1:0][2:0] c_arprot, input logic [1:0] c_arlock,
    output logic [1:0] c_rvalid, input logic [1:0] c_rready,
    output wire [1:0][127:0] c_rdata, output wire [1:0][3:0] c_rid,
    output wire [1:0][1:0] c_rresp, output wire [1:0] c_rlast,
    output wire m_awvalid, input logic m_awready, output wire [31:0] m_awaddr,
    output wire [3:0] m_awid, output wire [7:0] m_awlen,
    output wire [2:0] m_awsize, output wire [1:0] m_awburst,
    output wire [3:0] m_awcache, output wire [2:0] m_awprot, output wire m_awlock,
    output wire m_wvalid, input logic m_wready, output wire [127:0] m_wdata,
    output wire [15:0] m_wstrb, output wire m_wlast,
    input logic m_bvalid, output wire m_bready,
    input logic [3:0] m_bid, input logic [1:0] m_bresp,
    output wire m_arvalid, input logic m_arready, output wire [31:0] m_araddr,
    output wire [3:0] m_arid, output wire [7:0] m_arlen,
    output wire [2:0] m_arsize, output wire [1:0] m_arburst,
    output wire [3:0] m_arcache, output wire [2:0] m_arprot, output wire m_arlock,
    input logic m_rvalid, output wire m_rready, input logic [127:0] m_rdata,
    input logic [3:0] m_rid, input logic [1:0] m_rresp, input logic m_rlast,
    output wire write_idle, read_idle, drained,
    output logic quarantined, output logic [3:0] fault_reason,
    output logic [31:0] write_errors, read_errors
);

    reg write_owner,read_owner;
    reg [7:0] baseline_writes,baseline_reads;
    wire bw_start=!write_owner&&c_awvalid[0]&&m_awready;
    wire bw_end=!write_owner&&m_bvalid&&c_bready[0];
    wire br_start=!read_owner&&c_arvalid[0]&&m_arready;
    wire br_end=!read_owner&&m_rvalid&&c_rready[0]&&m_rlast;
    // With no Canny request, every baseline signal has its original direct
    // semantics, including BREADY before AW and native per-frame cancellation.
    assign m_awvalid=c_awvalid[write_owner];
    assign m_awaddr=c_awaddr[write_owner];assign m_awid=c_awid[write_owner];
    assign m_awlen=c_awlen[write_owner];assign m_awsize=c_awsize[write_owner];
    assign m_awburst=c_awburst[write_owner];assign m_awcache=c_awcache[write_owner];
    assign m_awprot=c_awprot[write_owner];assign m_awlock=c_awlock[write_owner];
    assign m_wvalid=c_wvalid[write_owner];assign m_wdata=c_wdata[write_owner];
    assign m_wstrb=c_wstrb[write_owner];assign m_wlast=c_wlast[write_owner];
    assign m_bready=c_bready[write_owner];
    assign m_arvalid=c_arvalid[read_owner];
    assign m_araddr=c_araddr[read_owner];assign m_arid=c_arid[read_owner];
    assign m_arlen=c_arlen[read_owner];assign m_arsize=c_arsize[read_owner];
    assign m_arburst=c_arburst[read_owner];assign m_arcache=c_arcache[read_owner];
    assign m_arprot=c_arprot[read_owner];assign m_arlock=c_arlock[read_owner];
    assign m_rready=c_rready[read_owner];
    assign c_bid={2{m_bid}};assign c_bresp={2{m_bresp}};
    assign c_rdata={2{m_rdata}};assign c_rid={2{m_rid}};
    assign c_rresp={2{m_rresp}};assign c_rlast={2{m_rlast}};
    always_comb begin
        c_awready=0;c_wready=0;c_bvalid=0;c_arready=0;c_rvalid=0;
        c_awready[write_owner]=m_awready;c_wready[write_owner]=m_wready;
        c_bvalid[write_owner]=m_bvalid;
        c_arready[read_owner]=m_arready;c_rvalid[read_owner]=m_rvalid;
    end
    assign write_idle=!write_owner&&baseline_writes==0;
    assign read_idle=!read_owner&&baseline_reads==0;
    assign drained=write_idle&&read_idle;
    // No global stop bit is allowed to interrupt the baseline video master.
    // Algorithm faults remain contained in the worker and its inner arbiters.
    always_comb begin quarantined=0;fault_reason=0;write_errors=0;read_errors=0;end
    always @(posedge clk or posedge rst)begin
        if(rst)begin write_owner<=0;read_owner<=0;baseline_writes<=0;baseline_reads<=0;end
        else begin
            if(!write_owner)begin
                case({bw_start,bw_end})
                    2'b10:if(baseline_writes!=255)baseline_writes<=baseline_writes+1'b1;
                    2'b01:if(baseline_writes!=0)baseline_writes<=baseline_writes-1'b1;
                    default:begin end
                endcase
                if(enable&&baseline_writes==0&&!c_awvalid[0]&&!c_wvalid[0]&&!m_bvalid&&c_awvalid[1])write_owner<=1;
            end else if(m_bvalid&&m_bready)write_owner<=0;
            if(!read_owner)begin
                case({br_start,br_end})
                    2'b10:if(baseline_reads!=255)baseline_reads<=baseline_reads+1'b1;
                    2'b01:if(baseline_reads!=0)baseline_reads<=baseline_reads-1'b1;
                    default:begin end
                endcase
                if(enable&&baseline_reads==0&&!c_arvalid[0]&&!m_rvalid&&c_arvalid[1])read_owner<=1;
            end else if(m_rvalid&&m_rready&&m_rlast)read_owner<=0;
        end
    end
endmodule
