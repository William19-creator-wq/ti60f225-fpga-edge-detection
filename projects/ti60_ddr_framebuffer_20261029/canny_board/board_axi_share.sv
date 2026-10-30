// Two physical AXI128 masters share the existing DDR controller, in core_clk.
// Port 0: unchanged camera/display RAW buffers, below 64 MiB.
// Port 1: snapshots/algorithms, 64..128 MiB. IDs are preserved, not frame IDs.
// At most one outstanding burst PER DIRECTION; reads and writes remain parallel.
// Ownership lasts through the actual B / final R handshake, never just AW/WLAST.
// rst is legal only with the DDR bus reset/quiescent. enable blocks NEW grants.
module board_axi_share #(parameter integer BASELINE_PORT0=1) (
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
    // 57 bits: address32, id4, len8, size3, burst2, cache4, prot3, lock1.
    wire [1:0][56:0] aw = { {c_awaddr[1],c_awid[1],c_awlen[1],c_awsize[1],c_awburst[1],c_awcache[1],c_awprot[1],c_awlock[1]},
                           {c_awaddr[0],c_awid[0],c_awlen[0],c_awsize[0],c_awburst[0],c_awcache[0],c_awprot[0],c_awlock[0]} };
    wire [1:0][56:0] ar = { {c_araddr[1],c_arid[1],c_arlen[1],c_arsize[1],c_arburst[1],c_arcache[1],c_arprot[1],c_arlock[1]},
                           {c_araddr[0],c_arid[0],c_arlen[0],c_arsize[0],c_arburst[0],c_arcache[0],c_arprot[0],c_arlock[0]} };
    logic write_active, read_active, write_owner, read_owner;
    logic aw_done, w_done, ar_done, w_started;
    logic [56:0] aw_hold, ar_hold;
    logic [8:0] write_left, read_left;
    logic [1:0] write_credit, read_credit;
    wire choose_w = c_awvalid[0] ? (c_awvalid[1] && write_credit==0) : 1'b1;
    wire choose_r = c_arvalid[0] ? (c_arvalid[1] && read_credit==0) : 1'b1;
    wire select_w = !rst && enable && !quarantined && !write_active && |c_awvalid;
    wire select_r = !rst && enable && !quarantined && !read_active && |c_arvalid;
    // The legacy framebuffer restarts its request FSM at frame boundaries.
    // Release only an outer port-0 grant for which DDR has accepted NOTHING.
    // Suppress VALID and upstream READY in the cancellation cycle as well:
    // simultaneous downstream READY must not turn a withdrawn header into a
    // new DDR transaction. Once AW or any W beat was accepted, ownership and
    // all protocol checks remain strict until the response has drained.
    wire cancel_pending_w = BASELINE_PORT0 && write_active && !write_owner &&
        !aw_done && !w_started &&
        (c_awvalid[0]!==1'b1 || aw[0]!==aw_hold);
    wire cancel_pending_r = BASELINE_PORT0 && read_active && !read_owner &&
        !ar_done && (c_arvalid[0]!==1'b1 || ar[0]!==ar_hold);
    // 3:1 preference under contention. Neither camera/display nor worker starves.
    function automatic logic legal(input logic owner, input logic [56:0] header);
        logic [31:0] address;
        logic [12:0] bytes_in_burst;

        begin
            address=header[56:25];
            bytes_in_burst=({5'd0,header[20:13]}+13'd1)<<4;
            // Every region boundary is 4-KiB aligned. The independent page
            // check below guarantees end <= next page. Thus a START inside
            // the region implies the entire positive-length burst is inside,
            // including a burst ending exactly at the region upper bound.
            // No 33-bit end-address adder/comparator is necessary.
            legal=(^header!==1'bx) && address[3:0]==0 && header[12:10]==3'd4 &&
                  header[9:8]==2'd1 && !header[0] &&
                  ({1'b0,address[11:0]}+bytes_in_burst<=13'd4096) &&
                  ((owner || !BASELINE_PORT0) ?
                    (address[31:27]==0 && address[26]) : address[31:26]==0);
        end
    endfunction
    assign {m_awaddr,m_awid,m_awlen,m_awsize,m_awburst,m_awcache,m_awprot,m_awlock}=aw_hold;
    assign {m_araddr,m_arid,m_arlen,m_arsize,m_arburst,m_arcache,m_arprot,m_arlock}=ar_hold;
    assign m_awvalid=!rst && write_active && !aw_done && !cancel_pending_w;
    assign m_wvalid=!rst && write_active && !w_done && !cancel_pending_w && c_wvalid[write_owner];
    assign m_wdata=c_wdata[write_owner];
    assign m_wstrb=c_wstrb[write_owner];
    assign m_wlast=c_wlast[write_owner];
    // W may precede AW acceptance: never make WVALID depend on AWREADY.
    assign m_bready=!rst && write_active && aw_done && w_done && c_bready[write_owner];
    assign c_bid={2{m_bid}}; assign c_bresp={2{m_bresp}};
    assign m_arvalid=!rst && read_active && !ar_done && !cancel_pending_r;
    assign m_rready=!rst && read_active && ar_done && c_rready[read_owner];
    assign c_rdata={2{m_rdata}}; assign c_rid={2{m_rid}};
    assign c_rresp={2{m_rresp}}; assign c_rlast={2{m_rlast}};
    assign write_idle=!rst && !write_active && !quarantined;
    assign read_idle=!rst && !read_active && !quarantined;
    assign drained=write_idle && read_idle;
    wire aw_fire=m_awvalid && m_awready;
    wire w_fire=m_wvalid && m_wready;
    wire b_fire=m_bvalid && m_bready;
    wire ar_fire=m_arvalid && m_arready;
    wire r_fire=m_rvalid && m_rready;
    logic [3:0] detected;
    always_comb begin
        c_awready=0; c_wready=0; c_bvalid=0; c_arready=0; c_rvalid=0;
        if(!rst && write_active && !cancel_pending_w)begin
            if(!aw_done)c_awready[write_owner]=m_awready;
            if(!w_done)c_wready[write_owner]=m_wready;
            if(aw_done && w_done)c_bvalid[write_owner]=m_bvalid;
        end
        if(!rst && read_active && !cancel_pending_r)begin
            if(!ar_done)c_arready[read_owner]=m_arready;
            else c_rvalid[read_owner]=m_rvalid;
        end
        detected=0;
        if(select_w && legal(choose_w,aw[choose_w])!==1'b1)detected=1;
        else if(select_r && legal(choose_r,ar[choose_r])!==1'b1)detected=2;
        else if(write_active && !aw_done && !cancel_pending_w && (c_awvalid[write_owner]!==1'b1 || aw[write_owner]!==aw_hold))detected=3;
        else if(read_active && !ar_done && !cancel_pending_r && (c_arvalid[read_owner]!==1'b1 || ar[read_owner]!==ar_hold))detected=4;
        else if(w_fire && m_wlast!==(write_left==1))detected=5;
        else if(m_bvalid && (!write_active || !(aw_done || aw_fire) || !(w_done || (w_fire && m_wlast))))detected=6;
        else if(m_bvalid && write_active && m_bid!==m_awid)detected=7;
        else if(m_rvalid && (!read_active || !(ar_done || ar_fire)))detected=8;
        else if(m_rvalid && read_active && m_rid!==m_arid)detected=9;
        else if(r_fire && m_rlast!==(read_left==1))detected=10;
    end
    always_ff @(posedge clk)begin
        if(rst)begin
            write_active<=0; read_active<=0; write_owner<=0; read_owner<=0;
            aw_done<=0; w_done<=0; ar_done<=0; w_started<=0; aw_hold<=0; ar_hold<=0;
            write_left<=0; read_left<=0; write_credit<=3; read_credit<=3;
            quarantined<=0; fault_reason<=0; write_errors<=0; read_errors<=0;
        end else begin
            if(!quarantined && detected!=0)begin quarantined<=1; fault_reason<=detected;end
            if(select_w && detected==0)begin
                write_active<=1; write_owner<=choose_w; aw_hold<=aw[choose_w];
                aw_done<=0; w_done<=0; w_started<=0; write_left<={1'b0,c_awlen[choose_w]}+9'd1;
                if(choose_w)write_credit<=3;
                else if(write_credit!=0)write_credit<=write_credit-2'd1;
            end
            if(select_r && detected==0)begin
                read_active<=1; read_owner<=choose_r; ar_hold<=ar[choose_r]; ar_done<=0;
                read_left<={1'b0,c_arlen[choose_r]}+9'd1;
                if(choose_r)read_credit<=3;
                else if(read_credit!=0)read_credit<=read_credit-2'd1;
            end
            if(aw_fire)aw_done<=1;
            if(ar_fire)ar_done<=1;
            if(w_fire)begin
                w_started<=1;
                if(write_left!=0)write_left<=write_left-9'd1;
                if(m_wlast)w_done<=1;
            end
            if(b_fire && m_bresp!=0)write_errors<=write_errors+32'd1;
            if(r_fire && m_rresp!=0)read_errors<=read_errors+32'd1;
            // Protocol ambiguity preserves the lease. Traffic can drain, but only
            // a coordinated reset may reuse an address after unknown completion.
            if(b_fire && !quarantined && detected==0)write_active<=0;
            if(r_fire)begin
                if(read_left!=0)read_left<=read_left-9'd1;
                if(m_rlast && !quarantined && detected==0)read_active<=0;
            end
            if(cancel_pending_w)begin
                write_active<=0;aw_done<=0;w_done<=0;w_started<=0;write_left<=0;
            end
            if(cancel_pending_r)begin
                read_active<=0;ar_done<=0;read_left<=0;
            end
        end
    end
endmodule
