// Camera/display baseline and Canny share the original DDR, never its PHY.
module integration_frame_system #(parameter integer W=1920,H=1080,EDGE_ONLY_DISPLAY=0,HISTORY_SOURCE=0)(
    output reg [95:0] debug_video,
    output reg [63:0] perf_video,
    input wire core_clk,video_clk,cold_reset_n,enable,worker_enable,bus_reset_n,
    input wire video_vs,video_de,input wire [47:0] video_rgb,
    input wire video_source_valid,input wire [5:0] video_source_slot,input wire [63:0] video_source_id,
    output wire [63:0] source_pins,output wire [5:0] display_source_slot,
    input wire source_lock,lock_source_valid,input wire [63:0] lock_source_id,
    input wire scan_vs,scan_hs,scan_de,input wire [47:0] scan_rgb,input wire [2:0] mode,
    input wire [10:0] cfg_threshold,input wire [1:0] cfg_filter,input wire [31:0] cfg_config_id,
    input wire freeze_request,use_snapshot,
    output wire [1:0] out_edges,output wire out_snapshot_valid,frozen,
    output wire [95:0] display_scope,output wire [63:0] display_sensor_frame,display_processing_cycles,
    output wire display_recognition,display_target_overflow,output wire [3:0] display_target_mask,
    output wire [7:0] display_target_class,display_unknown_reasons,output wire [21:0] display_unknown_count,
    output wire [175:0] display_target_box,output wire [95:0] display_target_center2,
    output wire out_vs,out_hs,out_de,output wire [47:0] out_rgb,
    output wire display_valid,output wire [10:0] display_threshold,output wire [1:0] display_filter,
    output wire quarantined,output wire [31:0] completed_jobs,failed_jobs,underflow_rows,
    input wire b_awvalid,
    output wire b_awready,
    input wire [31:0] b_awaddr,
    input wire [3:0] b_awid,
    input wire [7:0] b_awlen,
    input wire [2:0] b_awsize,
    input wire [1:0] b_awburst,
    input wire [3:0] b_awcache,
    input wire [2:0] b_awprot,
    input wire b_awlock,
    input wire b_wvalid,
    output wire b_wready,
    input wire [127:0] b_wdata,
    input wire [15:0] b_wstrb,
    input wire b_wlast,
    output wire b_bvalid,
    input wire b_bready,
    output wire [3:0] b_bid,
    output wire [1:0] b_bresp,
    input wire b_arvalid,
    output wire b_arready,
    input wire [31:0] b_araddr,
    input wire [3:0] b_arid,
    input wire [7:0] b_arlen,
    input wire [2:0] b_arsize,
    input wire [1:0] b_arburst,
    input wire [3:0] b_arcache,
    input wire [2:0] b_arprot,
    input wire b_arlock,
    output wire b_rvalid,
    input wire b_rready,
    output wire [127:0] b_rdata,
    output wire [3:0] b_rid,
    output wire [1:0] b_rresp,
    output wire b_rlast,
    output wire m_awvalid,
    input wire m_awready,
    output wire [31:0] m_awaddr,
    output wire [3:0] m_awid,
    output wire [7:0] m_awlen,
    output wire [2:0] m_awsize,
    output wire [1:0] m_awburst,
    output wire [3:0] m_awcache,
    output wire [2:0] m_awprot,
    output wire m_awlock,
    output wire m_wvalid,
    input wire m_wready,
    output wire [127:0] m_wdata,
    output wire [15:0] m_wstrb,
    output wire m_wlast,
    input wire m_bvalid,
    output wire m_bready,
    input wire [3:0] m_bid,
    input wire [1:0] m_bresp,
    output wire m_arvalid,
    input wire m_arready,
    output wire [31:0] m_araddr,
    output wire [3:0] m_arid,
    output wire [7:0] m_arlen,
    output wire [2:0] m_arsize,
    output wire [1:0] m_arburst,
    output wire [3:0] m_arcache,
    output wire [2:0] m_arprot,
    output wire m_arlock,
    input wire m_rvalid,
    output wire m_rready,
    input wire [127:0] m_rdata,
    input wire [3:0] m_rid,
    input wire [1:0] m_rresp,
    input wire m_rlast
);
(* ASYNC_REG="TRUE" *) reg [1:0] reset_pipe;
always @(posedge core_clk or negedge cold_reset_n) if(!cold_reset_n)reset_pipe<=3;else reset_pipe<={reset_pipe[0],1'b0};
wire rst=|reset_pipe;
wire [87:0] worker_debug;
wire [63:0] worker_perf;
reg [63:0] perf_hold;
wire [95:0] debug_core;
reg debug_request,debug_ack,debug_vs_previous;
(* ASYNC_REG="TRUE" *) reg [1:0] debug_request_sync,debug_ack_sync;
reg [95:0] debug_hold;
// Atomic bundled-data mailbox. Payload held from ACK until the NEXT request;
// no independently synchronized binary counters are used as a video snapshot.
always @(posedge core_clk or negedge cold_reset_n)begin
    if(!cold_reset_n)begin debug_request_sync<=0;debug_ack<=0;debug_hold<=0;perf_hold<=0;end
    else begin
        debug_request_sync<={debug_request_sync[0],debug_request};
        if(debug_request_sync[1]!=debug_ack)begin
            debug_hold<=debug_core;perf_hold<=worker_perf;debug_ack<=debug_request_sync[1];
        end
    end
end
always @(posedge video_clk or negedge cold_reset_n)begin
    if(!cold_reset_n)begin debug_request<=0;debug_ack_sync<=0;debug_video<=0;perf_video<=0;debug_vs_previous<=0;end
    else begin
        debug_ack_sync<={debug_ack_sync[0],debug_ack};debug_vs_previous<=scan_vs;
        if(scan_vs&&!debug_vs_previous&&debug_ack_sync[1]==debug_request)begin
            debug_video<=debug_hold;perf_video<=perf_hold;debug_request<=!debug_request;
        end
    end
end
wire [5:0] pub_source_slot;
wire discarded_valid;wire [63:0] discarded_frame;
wire pub_toggle,pub_slot,retired_valid,worker_q,bridge_q,display_q,inner_q,outer_q;
wire [31:0] pub_config_id;wire [63:0] pub_sensor_frame,pub_processing_cycles;
wire pub_recognition,pub_target_overflow;wire [3:0] pub_target_mask;wire [7:0] pub_target_class,pub_unknown_reasons;
wire [175:0] pub_target_box;wire [95:0] pub_target_center2;wire [21:0] pub_unknown_count;
wire [63:0] pub_frame,retired_frame;wire [10:0] pub_threshold;wire [1:0] pub_filter;
wire line_req_valid,line_req_ready,line_write,line_rsp_valid,line_rsp_ready,line_error,line_drained;
wire [31:0] line_addr;wire [511:0] line_wdata,line_rdata;
assign quarantined=worker_q|bridge_q|display_q|inner_q|outer_q;
assign debug_core={3'd0,outer_q,inner_q,display_q,bridge_q,worker_q,worker_debug};
wire a_awvalid;
wire a_awready;
wire [31:0] a_awaddr;
wire [3:0] a_awid;
wire [7:0] a_awlen;
wire [2:0] a_awsize;
wire [1:0] a_awburst;
wire [3:0] a_awcache;
wire [2:0] a_awprot;
wire a_awlock;
wire a_wvalid;
wire a_wready;
wire [127:0] a_wdata;
wire [15:0] a_wstrb;
wire a_wlast;
wire a_bvalid;
wire a_bready;
wire [3:0] a_bid;
wire [1:0] a_bresp;
wire a_arvalid;
wire a_arready;
wire [31:0] a_araddr;
wire [3:0] a_arid;
wire [7:0] a_arlen;
wire [2:0] a_arsize;
wire [1:0] a_arburst;
wire [3:0] a_arcache;
wire [2:0] a_arprot;
wire a_arlock;
wire a_rvalid;
wire a_rready;
wire [127:0] a_rdata;
wire [3:0] a_rid;
wire [1:0] a_rresp;
wire a_rlast;
wire d_awvalid;
wire d_awready;
wire [31:0] d_awaddr;
wire [3:0] d_awid;
wire [7:0] d_awlen;
wire [2:0] d_awsize;
wire [1:0] d_awburst;
wire [3:0] d_awcache;
wire [2:0] d_awprot;
wire d_awlock;
wire d_wvalid;
wire d_wready;
wire [127:0] d_wdata;
wire [15:0] d_wstrb;
wire d_wlast;
wire d_bvalid;
wire d_bready;
wire [3:0] d_bid;
wire [1:0] d_bresp;
wire d_arvalid;
wire d_arready;
wire [31:0] d_araddr;
wire [3:0] d_arid;
wire [7:0] d_arlen;
wire [2:0] d_arsize;
wire [1:0] d_arburst;
wire [3:0] d_arcache;
wire [2:0] d_arprot;
wire d_arlock;
wire d_rvalid;
wire d_rready;
wire [127:0] d_rdata;
wire [3:0] d_rid;
wire [1:0] d_rresp;
wire d_rlast;
wire i_awvalid;
wire i_awready;
wire [31:0] i_awaddr;
wire [3:0] i_awid;
wire [7:0] i_awlen;
wire [2:0] i_awsize;
wire [1:0] i_awburst;
wire [3:0] i_awcache;
wire [2:0] i_awprot;
wire i_awlock;
wire i_wvalid;
wire i_wready;
wire [127:0] i_wdata;
wire [15:0] i_wstrb;
wire i_wlast;
wire i_bvalid;
wire i_bready;
wire [3:0] i_bid;
wire [1:0] i_bresp;
wire i_arvalid;
wire i_arready;
wire [31:0] i_araddr;
wire [3:0] i_arid;
wire [7:0] i_arlen;
wire [2:0] i_arsize;
wire [1:0] i_arburst;
wire [3:0] i_arcache;
wire [2:0] i_arprot;
wire i_arlock;
wire i_rvalid;
wire i_rready;
wire [127:0] i_rdata;
wire [3:0] i_rid;
wire [1:0] i_rresp;
wire i_rlast;
canny_board_worker #(.W(W),.H(H),.GRAY_SNAPSHOT(EDGE_ONLY_DISPLAY),.HISTORY_SOURCE(HISTORY_SOURCE)) worker(
 .video_source_valid,.video_source_slot,.video_source_id,.source_pins,.publish_source_slot(pub_source_slot),
 .discarded_valid,.discarded_frame,
 .debug_status(worker_debug),.debug_perf(worker_perf),.core_clk,.video_clk,.cold_reset_n,.enable(enable&&!quarantined&&worker_enable),.video_vs,.video_de,.video_rgb,
 .cfg_threshold,.cfg_filter,.cfg_config_id,.cfg_recognition(mode==6),.publish_config_id(pub_config_id),.publish_sensor_frame(pub_sensor_frame),
 .publish_recognition(pub_recognition),.publish_target_mask(pub_target_mask),.publish_target_class(pub_target_class),
 .publish_target_box(pub_target_box),.publish_target_center2(pub_target_center2),
 .publish_unknown_count(pub_unknown_count),.publish_unknown_reasons(pub_unknown_reasons),
 .publish_target_overflow(pub_target_overflow),.publish_processing_cycles(pub_processing_cycles),
 .publish_toggle(pub_toggle),.publish_slot(pub_slot),.publish_frame(pub_frame),
 .publish_threshold(pub_threshold),.publish_filter(pub_filter),.retired_valid,.retired_frame,
 .quarantined(worker_q),.completed_jobs,.failed_jobs,
 .line_req_valid,.line_req_ready,.line_write,.line_addr,.line_wdata,.line_rsp_valid,.line_rsp_ready,.line_rdata,.line_error,.line_drained);
integration_frame_reader #(.W(W),.H(H),.EDGE_ONLY(EDGE_ONLY_DISPLAY),.HISTORY_LOCK(HISTORY_SOURCE)) display_reader(
 .source_lock,.lock_source_valid,.lock_source_id,.required_config_id(cfg_config_id),.discarded_valid,.discarded_frame,
 .publish_source_slot(pub_source_slot),.display_source_slot(display_source_slot),
 .core_clk,.video_clk,.cold_reset_n,.enable(enable&&!quarantined),.publish_toggle(pub_toggle),.publish_slot(pub_slot),.publish_frame(pub_frame),
 .publish_threshold(pub_threshold),.publish_filter(pub_filter),
 .publish_config_id(pub_config_id),.publish_sensor_frame(pub_sensor_frame),
 .publish_recognition(pub_recognition),.publish_target_mask(pub_target_mask),.publish_target_class(pub_target_class),
 .publish_target_box(pub_target_box),.publish_target_center2(pub_target_center2),
 .publish_unknown_count(pub_unknown_count),.publish_unknown_reasons(pub_unknown_reasons),
 .publish_target_overflow(pub_target_overflow),.publish_processing_cycles(pub_processing_cycles),
 .in_vs(scan_vs),.in_hs(scan_hs),.in_de(scan_de),.in_rgb(scan_rgb),.freeze_request,.use_snapshot,
 .out_edges,.out_snapshot_valid,.frozen,.display_scope,.display_sensor_frame,.display_processing_cycles,
 .display_recognition,.display_target_overflow,.display_target_mask,.display_target_class,
 .display_unknown_reasons,.display_unknown_count,.display_target_box,.display_target_center2,.out_vs,.out_hs,.out_de,.out_rgb,
 .display_valid,.display_threshold,.display_filter,.retired_valid,.retired_frame,.underflow_rows,.quarantined(display_q),
 .arvalid(d_arvalid),.arready(d_arready),.araddr(d_araddr),.arid(d_arid),.arlen(d_arlen),
 .rvalid(d_rvalid),.rready(d_rready),.rdata(d_rdata),.rid(d_rid),.rresp(d_rresp),.rlast(d_rlast));
assign d_awvalid=1'b0;
assign d_awaddr=32'd0;
assign d_awid=4'd0;
assign d_awlen=8'd0;
assign d_awsize=3'd4;
assign d_awburst=2'd1;
assign d_awcache=4'd3;
assign d_awprot=3'd0;
assign d_awlock=1'b0;
assign d_wvalid=1'b0;
assign d_wdata=128'd0;
assign d_wstrb=16'd0;
assign d_wlast=1'b0;
assign d_bready=1'b0;
assign d_arsize=3'd4;
assign d_arburst=2'd1;
assign d_arcache=4'd3;
assign d_arprot=3'd0;
assign d_arlock=1'b0;
assign a_awcache=4'd3;
assign a_awprot=3'd0;
assign a_awlock=1'b0;
assign a_arcache=4'd3;
assign a_arprot=3'd0;
assign a_arlock=1'b0;
axi_line_bridge axi_transport(.clk(core_clk),.rst,.enable(enable),.line_req_valid,.line_req_ready,.line_write,.line_addr,.line_wdata,.line_rsp_valid,.line_rsp_ready,.line_rdata,.line_error,.line_drained,.quarantined(bridge_q),.m_axi_awvalid(a_awvalid),.m_axi_awready(a_awready),.m_axi_awaddr(a_awaddr),.m_axi_awid(a_awid),.m_axi_awlen(a_awlen),.m_axi_awsize(a_awsize),.m_axi_awburst(a_awburst),.m_axi_wvalid(a_wvalid),.m_axi_wready(a_wready),.m_axi_wdata(a_wdata),.m_axi_wstrb(a_wstrb),.m_axi_wlast(a_wlast),.m_axi_bvalid(a_bvalid),.m_axi_bready(a_bready),.m_axi_bid(a_bid),.m_axi_bresp(a_bresp),.m_axi_arvalid(a_arvalid),.m_axi_arready(a_arready),.m_axi_araddr(a_araddr),.m_axi_arid(a_arid),.m_axi_arlen(a_arlen),.m_axi_arsize(a_arsize),.m_axi_arburst(a_arburst),.m_axi_rvalid(a_rvalid),.m_axi_rready(a_rready),.m_axi_rdata(a_rdata),.m_axi_rid(a_rid),.m_axi_rresp(a_rresp),.m_axi_rlast(a_rlast));
wire [1:0] worker_share_awvalid;
assign worker_share_awvalid[0]=d_awvalid;
assign worker_share_awvalid[1]=1'b0;
wire [1:0] worker_share_awready;
assign d_awready=worker_share_awready[0];
assign a_awready=i_awready;
wire [1:0][31:0] worker_share_awaddr;
assign worker_share_awaddr[0]=d_awaddr;
assign worker_share_awaddr[1]=a_awaddr;
wire [1:0][3:0] worker_share_awid;
assign worker_share_awid[0]=d_awid;
assign worker_share_awid[1]=a_awid;
wire [1:0][7:0] worker_share_awlen;
assign worker_share_awlen[0]=d_awlen;
assign worker_share_awlen[1]=a_awlen;
wire [1:0][2:0] worker_share_awsize;
assign worker_share_awsize[0]=d_awsize;
assign worker_share_awsize[1]=a_awsize;
wire [1:0][1:0] worker_share_awburst;
assign worker_share_awburst[0]=d_awburst;
assign worker_share_awburst[1]=a_awburst;
wire [1:0][3:0] worker_share_awcache;
assign worker_share_awcache[0]=d_awcache;
assign worker_share_awcache[1]=a_awcache;
wire [1:0][2:0] worker_share_awprot;
assign worker_share_awprot[0]=d_awprot;
assign worker_share_awprot[1]=a_awprot;
wire [1:0] worker_share_awlock;
assign worker_share_awlock[0]=d_awlock;
assign worker_share_awlock[1]=a_awlock;
wire [1:0] worker_share_wvalid;
assign worker_share_wvalid[0]=d_wvalid;
assign worker_share_wvalid[1]=1'b0;
wire [1:0] worker_share_wready;
assign d_wready=worker_share_wready[0];
assign a_wready=i_wready;
wire [1:0][127:0] worker_share_wdata;
assign worker_share_wdata[0]=d_wdata;
assign worker_share_wdata[1]=a_wdata;
wire [1:0][15:0] worker_share_wstrb;
assign worker_share_wstrb[0]=d_wstrb;
assign worker_share_wstrb[1]=a_wstrb;
wire [1:0] worker_share_wlast;
assign worker_share_wlast[0]=d_wlast;
assign worker_share_wlast[1]=a_wlast;
wire [1:0] worker_share_bvalid;
assign d_bvalid=worker_share_bvalid[0];
assign a_bvalid=i_bvalid;
wire [1:0] worker_share_bready;
assign worker_share_bready[0]=d_bready;
assign worker_share_bready[1]=1'b0;
wire [1:0][3:0] worker_share_bid;
assign d_bid=worker_share_bid[0];
assign a_bid=i_bid;
wire [1:0][1:0] worker_share_bresp;
assign d_bresp=worker_share_bresp[0];
assign a_bresp=i_bresp;
wire [1:0] worker_share_arvalid;
assign worker_share_arvalid[0]=d_arvalid;
assign worker_share_arvalid[1]=a_arvalid;
wire [1:0] worker_share_arready;
assign d_arready=worker_share_arready[0];
assign a_arready=worker_share_arready[1];
wire [1:0][31:0] worker_share_araddr;
assign worker_share_araddr[0]=d_araddr;
assign worker_share_araddr[1]=a_araddr;
wire [1:0][3:0] worker_share_arid;
assign worker_share_arid[0]=d_arid;
assign worker_share_arid[1]=a_arid;
wire [1:0][7:0] worker_share_arlen;
assign worker_share_arlen[0]=d_arlen;
assign worker_share_arlen[1]=a_arlen;
wire [1:0][2:0] worker_share_arsize;
assign worker_share_arsize[0]=d_arsize;
assign worker_share_arsize[1]=a_arsize;
wire [1:0][1:0] worker_share_arburst;
assign worker_share_arburst[0]=d_arburst;
assign worker_share_arburst[1]=a_arburst;
wire [1:0][3:0] worker_share_arcache;
assign worker_share_arcache[0]=d_arcache;
assign worker_share_arcache[1]=a_arcache;
wire [1:0][2:0] worker_share_arprot;
assign worker_share_arprot[0]=d_arprot;
assign worker_share_arprot[1]=a_arprot;
wire [1:0] worker_share_arlock;
assign worker_share_arlock[0]=d_arlock;
assign worker_share_arlock[1]=a_arlock;
wire [1:0] worker_share_rvalid;
assign d_rvalid=worker_share_rvalid[0];
assign a_rvalid=worker_share_rvalid[1];
wire [1:0] worker_share_rready;
assign worker_share_rready[0]=d_rready;
assign worker_share_rready[1]=a_rready;
wire [1:0][127:0] worker_share_rdata;
assign d_rdata=worker_share_rdata[0];
assign a_rdata=worker_share_rdata[1];
wire [1:0][3:0] worker_share_rid;
assign d_rid=worker_share_rid[0];
assign a_rid=worker_share_rid[1];
wire [1:0][1:0] worker_share_rresp;
assign d_rresp=worker_share_rresp[0];
assign a_rresp=worker_share_rresp[1];
wire [1:0] worker_share_rlast;
assign d_rlast=worker_share_rlast[0];
assign a_rlast=worker_share_rlast[1];
board_axi_share #(.BASELINE_PORT0(0)) worker_share(.clk(core_clk),.rst,.enable(enable),.quarantined(inner_q),.fault_reason(),.write_idle(),.read_idle(),.drained(),.write_errors(),.read_errors(),.c_awvalid(worker_share_awvalid),.m_awvalid(),.c_awready(worker_share_awready),.m_awready('0),.c_awaddr(worker_share_awaddr),.m_awaddr(),.c_awid(worker_share_awid),.m_awid(),.c_awlen(worker_share_awlen),.m_awlen(),.c_awsize(worker_share_awsize),.m_awsize(),.c_awburst(worker_share_awburst),.m_awburst(),.c_awcache(worker_share_awcache),.m_awcache(),.c_awprot(worker_share_awprot),.m_awprot(),.c_awlock(worker_share_awlock),.m_awlock(),.c_wvalid(worker_share_wvalid),.m_wvalid(),.c_wready(worker_share_wready),.m_wready('0),.c_wdata(worker_share_wdata),.m_wdata(),.c_wstrb(worker_share_wstrb),.m_wstrb(),.c_wlast(worker_share_wlast),.m_wlast(),.c_bvalid(worker_share_bvalid),.m_bvalid('0),.c_bready(worker_share_bready),.m_bready(),.c_bid(worker_share_bid),.m_bid('0),.c_bresp(worker_share_bresp),.m_bresp('0),.c_arvalid(worker_share_arvalid),.m_arvalid(i_arvalid),.c_arready(worker_share_arready),.m_arready(i_arready),.c_araddr(worker_share_araddr),.m_araddr(i_araddr),.c_arid(worker_share_arid),.m_arid(i_arid),.c_arlen(worker_share_arlen),.m_arlen(i_arlen),.c_arsize(worker_share_arsize),.m_arsize(i_arsize),.c_arburst(worker_share_arburst),.m_arburst(i_arburst),.c_arcache(worker_share_arcache),.m_arcache(i_arcache),.c_arprot(worker_share_arprot),.m_arprot(i_arprot),.c_arlock(worker_share_arlock),.m_arlock(i_arlock),.c_rvalid(worker_share_rvalid),.m_rvalid(i_rvalid),.c_rready(worker_share_rready),.m_rready(i_rready),.c_rdata(worker_share_rdata),.m_rdata(i_rdata),.c_rid(worker_share_rid),.m_rid(i_rid),.c_rresp(worker_share_rresp),.m_rresp(i_rresp),.c_rlast(worker_share_rlast),.m_rlast(i_rlast));

// Only algorithm/capture writes exist here: avoid a redundant write grant stage.
assign i_awvalid=a_awvalid;
assign i_awaddr=a_awaddr;
assign i_awid=a_awid;
assign i_awlen=a_awlen;
assign i_awsize=a_awsize;
assign i_awburst=a_awburst;
assign i_awcache=a_awcache;
assign i_awprot=a_awprot;
assign i_awlock=a_awlock;
assign i_wvalid=a_wvalid;
assign i_wdata=a_wdata;
assign i_wstrb=a_wstrb;
assign i_wlast=a_wlast;
assign i_bready=a_bready;
wire [1:0] board_share_awvalid;
assign board_share_awvalid[0]=b_awvalid;
assign board_share_awvalid[1]=i_awvalid;
wire [1:0] board_share_awready;
assign b_awready=board_share_awready[0];
assign i_awready=board_share_awready[1];
wire [1:0][31:0] board_share_awaddr;
assign board_share_awaddr[0]=b_awaddr;
assign board_share_awaddr[1]=i_awaddr;
wire [1:0][3:0] board_share_awid;
assign board_share_awid[0]=b_awid;
assign board_share_awid[1]=i_awid;
wire [1:0][7:0] board_share_awlen;
assign board_share_awlen[0]=b_awlen;
assign board_share_awlen[1]=i_awlen;
wire [1:0][2:0] board_share_awsize;
assign board_share_awsize[0]=b_awsize;
assign board_share_awsize[1]=i_awsize;
wire [1:0][1:0] board_share_awburst;
assign board_share_awburst[0]=b_awburst;
assign board_share_awburst[1]=i_awburst;
wire [1:0][3:0] board_share_awcache;
assign board_share_awcache[0]=b_awcache;
assign board_share_awcache[1]=i_awcache;
wire [1:0][2:0] board_share_awprot;
assign board_share_awprot[0]=b_awprot;
assign board_share_awprot[1]=i_awprot;
wire [1:0] board_share_awlock;
assign board_share_awlock[0]=b_awlock;
assign board_share_awlock[1]=i_awlock;
wire [1:0] board_share_wvalid;
assign board_share_wvalid[0]=b_wvalid;
assign board_share_wvalid[1]=i_wvalid;
wire [1:0] board_share_wready;
assign b_wready=board_share_wready[0];
assign i_wready=board_share_wready[1];
wire [1:0][127:0] board_share_wdata;
assign board_share_wdata[0]=b_wdata;
assign board_share_wdata[1]=i_wdata;
wire [1:0][15:0] board_share_wstrb;
assign board_share_wstrb[0]=b_wstrb;
assign board_share_wstrb[1]=i_wstrb;
wire [1:0] board_share_wlast;
assign board_share_wlast[0]=b_wlast;
assign board_share_wlast[1]=i_wlast;
wire [1:0] board_share_bvalid;
assign b_bvalid=board_share_bvalid[0];
assign i_bvalid=board_share_bvalid[1];
wire [1:0] board_share_bready;
assign board_share_bready[0]=b_bready;
assign board_share_bready[1]=i_bready;
wire [1:0][3:0] board_share_bid;
assign b_bid=board_share_bid[0];
assign i_bid=board_share_bid[1];
wire [1:0][1:0] board_share_bresp;
assign b_bresp=board_share_bresp[0];
assign i_bresp=board_share_bresp[1];
wire [1:0] board_share_arvalid;
assign board_share_arvalid[0]=b_arvalid;
assign board_share_arvalid[1]=i_arvalid;
wire [1:0] board_share_arready;
assign b_arready=board_share_arready[0];
assign i_arready=board_share_arready[1];
wire [1:0][31:0] board_share_araddr;
assign board_share_araddr[0]=b_araddr;
assign board_share_araddr[1]=i_araddr;
wire [1:0][3:0] board_share_arid;
assign board_share_arid[0]=b_arid;
assign board_share_arid[1]=i_arid;
wire [1:0][7:0] board_share_arlen;
assign board_share_arlen[0]=b_arlen;
assign board_share_arlen[1]=i_arlen;
wire [1:0][2:0] board_share_arsize;
assign board_share_arsize[0]=b_arsize;
assign board_share_arsize[1]=i_arsize;
wire [1:0][1:0] board_share_arburst;
assign board_share_arburst[0]=b_arburst;
assign board_share_arburst[1]=i_arburst;
wire [1:0][3:0] board_share_arcache;
assign board_share_arcache[0]=b_arcache;
assign board_share_arcache[1]=i_arcache;
wire [1:0][2:0] board_share_arprot;
assign board_share_arprot[0]=b_arprot;
assign board_share_arprot[1]=i_arprot;
wire [1:0] board_share_arlock;
assign board_share_arlock[0]=b_arlock;
assign board_share_arlock[1]=i_arlock;
wire [1:0] board_share_rvalid;
assign b_rvalid=board_share_rvalid[0];
assign i_rvalid=board_share_rvalid[1];
wire [1:0] board_share_rready;
assign board_share_rready[0]=b_rready;
assign board_share_rready[1]=i_rready;
wire [1:0][127:0] board_share_rdata;
assign b_rdata=board_share_rdata[0];
assign i_rdata=board_share_rdata[1];
wire [1:0][3:0] board_share_rid;
assign b_rid=board_share_rid[0];
assign i_rid=board_share_rid[1];
wire [1:0][1:0] board_share_rresp;
assign b_rresp=board_share_rresp[0];
assign i_rresp=board_share_rresp[1];
wire [1:0] board_share_rlast;
assign b_rlast=board_share_rlast[0];
assign i_rlast=board_share_rlast[1];
baseline_direct_axi_share #(.BASELINE_PORT0(1)) board_share(.clk(core_clk),.rst(!bus_reset_n),.enable(enable),.quarantined(outer_q),.fault_reason(),.write_idle(),.read_idle(),.drained(),.write_errors(),.read_errors(),.c_awvalid(board_share_awvalid),.m_awvalid(m_awvalid),.c_awready(board_share_awready),.m_awready(m_awready),.c_awaddr(board_share_awaddr),.m_awaddr(m_awaddr),.c_awid(board_share_awid),.m_awid(m_awid),.c_awlen(board_share_awlen),.m_awlen(m_awlen),.c_awsize(board_share_awsize),.m_awsize(m_awsize),.c_awburst(board_share_awburst),.m_awburst(m_awburst),.c_awcache(board_share_awcache),.m_awcache(m_awcache),.c_awprot(board_share_awprot),.m_awprot(m_awprot),.c_awlock(board_share_awlock),.m_awlock(m_awlock),.c_wvalid(board_share_wvalid),.m_wvalid(m_wvalid),.c_wready(board_share_wready),.m_wready(m_wready),.c_wdata(board_share_wdata),.m_wdata(m_wdata),.c_wstrb(board_share_wstrb),.m_wstrb(m_wstrb),.c_wlast(board_share_wlast),.m_wlast(m_wlast),.c_bvalid(board_share_bvalid),.m_bvalid(m_bvalid),.c_bready(board_share_bready),.m_bready(m_bready),.c_bid(board_share_bid),.m_bid(m_bid),.c_bresp(board_share_bresp),.m_bresp(m_bresp),.c_arvalid(board_share_arvalid),.m_arvalid(m_arvalid),.c_arready(board_share_arready),.m_arready(m_arready),.c_araddr(board_share_araddr),.m_araddr(m_araddr),.c_arid(board_share_arid),.m_arid(m_arid),.c_arlen(board_share_arlen),.m_arlen(m_arlen),.c_arsize(board_share_arsize),.m_arsize(m_arsize),.c_arburst(board_share_arburst),.m_arburst(m_arburst),.c_arcache(board_share_arcache),.m_arcache(m_arcache),.c_arprot(board_share_arprot),.m_arprot(m_arprot),.c_arlock(board_share_arlock),.m_arlock(m_arlock),.c_rvalid(board_share_rvalid),.m_rvalid(m_rvalid),.c_rready(board_share_rready),.m_rready(m_rready),.c_rdata(board_share_rdata),.m_rdata(m_rdata),.c_rid(board_share_rid),.m_rid(m_rid),.c_rresp(board_share_rresp),.m_rresp(m_rresp),.c_rlast(board_share_rlast),.m_rlast(m_rlast));
endmodule
