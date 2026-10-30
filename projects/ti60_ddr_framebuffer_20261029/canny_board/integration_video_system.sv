// Camera/display baseline and Canny share the original DDR, never its PHY.
module integration_video_system #(parameter integer W=1920,H=1080,HTOTAL=1100)(
    input wire core_clk,video_clk,cold_reset_n,enable,
    input wire video_vs,video_de,input wire [47:0] video_rgb,
    input wire scan_vs,scan_hs,scan_de,input wire [47:0] scan_rgb,input wire [2:0] mode,
    input wire [10:0] cfg_threshold,input wire [1:0] cfg_filter,input wire [31:0] cfg_config_id,
    input wire freeze_request,cfg_overlay_canny,cfg_edge_enhance,cfg_wide_overlay,
    input wire [1:0] cfg_compare,input wire [10:0] cfg_sobel_threshold,
    output wire frozen,algorithm_fault,output wire [2:0] active_mode,
    output wire [10:0] active_threshold,output wire [1:0] active_filter,output wire active_edge_enhance,active_overlay_canny,active_wide_overlay,output wire [1:0] active_compare,
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
wire raw_vs,raw_hs,raw_de,raw_valid;wire [47:0] raw_rgb;wire [1:0] raw_edges;
integration_frame_system #(.W(W),.H(H)) frames(.*,
 .use_snapshot(mode>=5||(mode==4&&cfg_overlay_canny)),
 .out_vs(raw_vs),.out_hs(raw_hs),.out_de(raw_de),.out_rgb(raw_rgb),.out_edges(raw_edges),.out_snapshot_valid(raw_valid));
wire present_vs,present_hs,present_de;wire [47:0] present_rgb;
integration_video_presenter #(.W(W),.H(H),.HTOTAL(HTOTAL),.RUNTIME_FILTER_CONFIG(1),.RUNTIME_EDGE_CONFIG(1),.CANNY_AVAILABLE(1)) presenter(
 .clk(video_clk),.rst(!cold_reset_n),.in_vs(raw_vs),.in_hs(raw_hs),.in_de(raw_de),.in_rgb(raw_rgb),.in_canny_edge(raw_edges),
 .cfg_overlay_canny,.cfg_wide_overlay,.cfg_compare,.cfg_mode(mode),.cfg_threshold(cfg_sobel_threshold),
 .cfg_median_enable(cfg_filter!=0),.cfg_detail_enable(cfg_filter==2),.cfg_edge_enhance,.cfg_config_id,
 .active_mode,.active_threshold,.active_filter,.active_edge_enhance,.active_overlay_canny,.active_wide_overlay,.active_compare,
 .out_vs(present_vs),.out_hs(present_hs),.out_de(present_de),.out_rgb(present_rgb),.sticky_fault(algorithm_fault));
reg present_vs_previous;reg [10:0] x,y;
reg frame_valid,targets_valid;reg [95:0] frame_scope;reg [3:0] target_mask;reg [7:0] target_class;
reg [175:0] target_box;reg [95:0] target_center2;
always @(posedge video_clk)begin
 if(!cold_reset_n)begin
  present_vs_previous<=0;x<=0;y<=0;frame_valid<=0;targets_valid<=0;frame_scope<=0;
  target_mask<=0;target_class<=0;target_box<=0;target_center2<=0;
 end else begin
  present_vs_previous<=present_vs;
  if(present_vs&&!present_vs_previous)begin
   x<=0;y<=0;frame_valid<=display_valid;targets_valid<=display_recognition;frame_scope<=display_scope;
   target_mask<=display_target_mask;target_class<=display_target_class;target_box<=display_target_box;target_center2<=display_target_center2;
  end else if(present_de)begin
   if(x==W-2)begin x<=0;y<=y==H-1?0:y+1'b1;end else x<=x+2'd2;
  end
 end
end
shape_annotation_pair #(.W(W),.H(H)) annotations(
 .clk(video_clk),.rst(!cold_reset_n),.enable(active_mode==6),
 .in_vs(present_vs),.in_hs(present_hs),.in_de(present_de),.in_rgb(present_rgb),.in_x(x),.in_y(y),
 .frame_valid,.frame_scope,.targets_valid,.target_scope(frame_scope),.target_mask,.target_class,.target_box,.target_center2,
 .out_vs,.out_hs,.out_de,.out_rgb);
endmodule
