

`timescale 1ps/1ps
module history_frame_buffer #(
parameter I_VID_WIDTH       = 16,
parameter O_VID_WIDTH       = 16,
parameter AXI_DATA_WIDTH	= 512,
parameter AXI_ADDR_WIDTH 	= 33,
parameter	WR_FIFO_DEPTH	= 1024,    
parameter	RD_FIFO_DEPTH 	= 1024,
parameter START_ADDR		= 33'h000201900,
parameter BURST_LEN         = 8'd15,
parameter FB_NUM			= 3,//2 buffer ,3 buffer 
parameter MAX_VID_WIDTH		= 1920 ,//video width 
parameter MAX_VID_HIGHT		= 1080 ,//wideo height
parameter O_FRAME_WIDTH     = 1920,
parameter O_FRAME_HEIGHT    = 1080,
parameter AXI_STRB_WIDTH 	= AXI_DATA_WIDTH/8
) (

input wire i_hs, // CSI line envelope, DE bubbles do not end a line
input wire command_valid,
input wire command_freeze_valid,input wire [5:0] command_freeze_slot,input wire [63:0] command_freeze_id,
input wire [63:0] processing_source_pins,
output wire video_source_valid,output wire [5:0] video_source_slot,output wire [63:0] video_source_id,
input wire command_compare,input wire [5:0] command_a,command_b,
input wire video_rgb_vs,video_rgb_de,input wire [47:0] video_rgb,
output wire [47:0] compare_rgb,output wire compare_rgb_valid,input wire compare_rgb_ready,
output wire compare_read_mode,output wire [129:0] compare_status,
input wire [1:0] command_mode,
input wire [5:0] command_index,
input wire [1:0] bresp,
output wire [1:0] playback_mode,
output wire [5:0] playback_position,
output wire [6:0] history_count,
output wire [63:0] source_frame_id,
output wire history_fault,
input 												axi_clk,
input 												rst_n,

input	wire								i_clk	,
input	wire								i_vs, //active hgih
input	wire								i_de, //active high
input	wire	[I_VID_WIDTH-1:0] 			vin ,

input	wire							o_clk	,
input   wire                   fifo_rd_period,//!!
output wire                    m_axis_tuser,
output wire                    m_axis_tvalid ,
input  wire                    m_axis_tready,
output wire                    m_axis_tlast,
output wire  [O_VID_WIDTH-1:0] m_axis_tdata,



output 	[5:0] 								awid,
output  [AXI_ADDR_WIDTH-1:0] 	            awaddr,
output  [7:0] 								awlen,
output  [2:0] 								awsize,
output  [1:0] 								awburst,
output  [3:0] 								awcache,
output [2:0]                                awprot,
output  									    awlock,
output  									    awvalid,
output  									    awcobuf,
output  									    awapcmd,
output  									    awallstrb,
output  									    awqos,
input 										    awready,

output [5:0] 									arid,
output  [AXI_ADDR_WIDTH-1:0] 	                araddr,
output  [7:0] 								    arlen,
output  [2:0] 								    arsize,
output  [1:0] 								    arburst,
output  									    arlock,
output  									    arvalid,
output  									    arapcmd,
output 										    arqos,
input 										    arready,
output  [3:0] 									arcache,
output [2:0]                    arprot,

output  [AXI_DATA_WIDTH-1:0] 	wdata,  
output  [AXI_STRB_WIDTH-1:0] 	wstrb,
output  											wlast,
output  											wvalid,
input 												wready,

input [5:0] 									    rid,
input [AXI_DATA_WIDTH-1:0] 		rdata,
input 												rlast,
input 												rvalid,
output  											rready,
input [1:0] 									    rresp,

input [5:0] 									    bid,
input 												bvalid,
output  											bready,
output			[31:0]								test_rd_fifo_rddata,   
output	[31:0]								        test_wdata,
output	[31:0]								        test_rdata,
output [7:0] test_BURST_LEN
);

wire wr_clk_rst_n,axi_clk_rst_n,rd_clk_rst_n;
rst_n_piple #(.DLY(3)) cr(.clk(i_clk),.rst_n_i(rst_n),.rst_n_o(wr_clk_rst_n));
rst_n_piple #(.DLY(3)) ar(.clk(axi_clk),.rst_n_i(rst_n),.rst_n_o(axi_clk_rst_n));
rst_n_piple #(.DLY(3)) vr(.clk(o_clk),.rst_n_i(rst_n),.rst_n_o(rd_clk_rst_n));
reg vs_last=0,hs_last=0,active_vs=1;
wire camera_line_end=hs_last&&!i_hs;
reg [63:0] timestamp=0;
always @(posedge i_clk)begin
  vs_last<=i_vs;hs_last<=i_hs;
  if(i_de)active_vs<=i_vs;
  if(!wr_clk_rst_n)timestamp<=0;else timestamp<=timestamp+1;
end
wire sof=(i_vs!=vs_last)&&(i_vs==active_vs);
wire eof=(i_vs!=vs_last)&&(i_vs!=active_vs);
reg [2:0] period_sync=0;
always @(posedge axi_clk)period_sync<={period_sync[1:0],fifo_rd_period};
wire boundary=period_sync[1]&&!period_sync[2];
wire read_busy,read_done,read_fault;
wire raw_busy,compare_busy,raw_fault,compare_fault;
reg read_kind=0;
wire select_command,selection_apply;wire [1:0] select_mode;wire [5:0] select_index;
wire select_freeze_valid;wire [5:0] select_freeze_slot;wire [63:0] select_freeze_id;
wire compare_enabled,preparing,pair_valid,front_bank;
wire [63:0] compare_a_id,compare_b_id;wire [31:0] compare_failures;
wire job_start,job_done,job_good;wire [31:0] job_base;wire [63:0] job_source_id,job_completed_id;
wire [1:0] wa_valid,wa_ready,wd_valid,wd_ready,wd_last,wb_valid,wb_ready;
wire [1:0][31:0] wa_addr;wire [1:0][7:0] wa_len;wire [1:0][2:0] wa_size;
wire [1:0][1:0] wa_burst,wb_resp;wire [1:0][127:0] wd_data;wire [1:0][15:0] wd_strb;
assign compare_status={compare_enabled,preparing,compare_a_id,compare_b_id};
assign read_busy=raw_busy||compare_busy;
assign read_fault=raw_fault||compare_fault;
reg wait_drain=0;reg [5:0] blank_window=0;reg read_start=0;
wire selected_valid;wire [31:0] selected_base;
wire reset_read_fifo=!axi_clk_rst_n||boundary||wait_drain||blank_window!=0;
always @(posedge axi_clk)begin
  read_start<=0;
  if(!axi_clk_rst_n)begin wait_drain<=0;blank_window<=0;read_kind<=0;end
  else if(boundary)begin wait_drain<=1;blank_window<=0;end
  else if(wait_drain&&!read_busy)begin wait_drain<=0;blank_window<=32;end
  else if(blank_window!=0)begin
    blank_window<=blank_window-1;
    if(blank_window==1&&selected_valid)begin
      read_kind<=compare_enabled&&pair_valid&&!preparing;read_start<=1;
    end
  end
end
wire owner_fault;
history_compare_control compare_control(
 .command_freeze_valid(command_freeze_valid),.command_freeze_slot(command_freeze_slot),.command_freeze_id(command_freeze_id),
 .select_freeze_valid(select_freeze_valid),.select_freeze_slot(select_freeze_slot),.select_freeze_id(select_freeze_id),
 .clk(axi_clk),.rst(!axi_clk_rst_n),.command_valid(command_valid),.command_compare(command_compare),
 .command_mode(command_mode),.command_index(command_index),.command_a(command_a),.command_b(command_b),
 .select_command(select_command),.select_mode(select_mode),.select_index(select_index),
 .selection_apply(selection_apply),.selected_valid(selected_valid),.selected_id(source_frame_id),
 .boundary(blank_window!=0),.frame_tick(boundary),.reader_drained(!read_busy&&blank_window!=0),
 .job_start(job_start),.job_base(job_base),.job_source_id(job_source_id),
 .job_done(job_done),.job_good(job_good),.job_completed_id(job_completed_id),
 .compare_enabled(compare_enabled),.preparing(preparing),.pair_valid(pair_valid),.front_bank(front_bank),
 .a_id(compare_a_id),.b_id(compare_b_id),.failed_pairs(compare_failures));
thumbnail_capture_engine thumbnail_writer(
 .axi_clk(axi_clk),.video_clk(o_clk),.reset_n(rst_n),.start(job_start),.target_base(job_base),.source_id(job_source_id),
 .busy(),.done(job_done),.good(job_good),.completed_source_id(job_completed_id),
 .video_vs(video_rgb_vs),.video_de(video_rgb_de),.video_rgb(video_rgb),
 .awaddr(wa_addr[1]),.awlen(wa_len[1]),.awsize(wa_size[1]),.awburst(wa_burst[1]),.awvalid(wa_valid[1]),.awready(wa_ready[1]),
 .wdata(wd_data[1]),.wstrb(wd_strb[1]),.wlast(wd_last[1]),.wvalid(wd_valid[1]),.wready(wd_ready[1]),
 .bvalid(wb_valid[1]),.bresp(wb_resp[1]),.bready(wb_ready[1]));
frame_write_share writes(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.c_awvalid(wa_valid),.c_awready(wa_ready),.c_awaddr(wa_addr),.c_awlen(wa_len),
 .c_awsize(wa_size),.c_awburst(wa_burst),.c_wvalid(wd_valid),.c_wready(wd_ready),.c_wdata(wd_data),.c_wstrb(wd_strb),
 .c_wlast(wd_last),.c_bvalid(wb_valid),.c_bready(wb_ready),.c_bresp(wb_resp),
 .awvalid(awvalid),.awready(awready),.awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),
 .wvalid(wvalid),.wready(wready),.wdata(wdata),.wstrb(wstrb),.wlast(wlast),.bvalid(bvalid),.bready(bready),.bresp(bresp));
frame_descriptor_mailbox #(.WIDTH(71)) source_identity(
 .src_clk(axi_clk),.src_rst(!rst_n),.src_valid(1'b1),.src_ready(),
 .src_data({selected_valid&&!read_kind,selected_base[26:21],source_frame_id}),
 .dst_clk(o_clk),.dst_rst(!rst_n),.dst_valid(),.dst_ready(1'b1),
 .dst_data({video_source_valid,video_source_slot,video_source_id}));
raw_frame_store #(.EXTERNAL_PINS(1),.DIRECT_FREEZE(1)) store(
 .freeze_target_valid(select_freeze_valid),.freeze_target_slot(select_freeze_slot),.freeze_target_id(select_freeze_id),
 .external_pins(processing_source_pins),
 .axi_clk(axi_clk),.cam_clk(i_clk),.reset_n(rst_n),.enable(axi_clk_rst_n),
 .sof(sof),.eof(eof),.de(i_de),.line_end(camera_line_end),.pix4(vin),.cam_timestamp(timestamp),
 .command_valid(select_command),.command_mode(select_mode),.command_index(select_index),
 .display_boundary(blank_window!=0),.reads_drained(!read_busy&&blank_window!=0),
 .mode(playback_mode),.position(playback_position),.selected_valid(selected_valid),.selected_base(selected_base),
 .selected_frame_id(source_frame_id),.apply(selection_apply),.history_count(history_count),.fault(owner_fault),
 .capture_drops(),.slot_drops(),.bad_frames(),
 .awaddr(wa_addr[0]),.awlen(wa_len[0]),.awsize(wa_size[0]),.awburst(wa_burst[0]),.awvalid(wa_valid[0]),.awready(wa_ready[0]),
 .wdata(wd_data[0]),.wstrb(wd_strb[0]),.wlast(wd_last[0]),.wvalid(wd_valid[0]),.wready(wd_ready[0]),.bvalid(wb_valid[0]),.bresp(wb_resp[0]),.bready(wb_ready[0]));
assign history_fault=owner_fault||read_fault;
assign awid=0;assign awcache=0;assign awprot=0;assign awlock=0;assign awqos=0;
assign awcobuf=0;assign awapcmd=0;assign awallstrb=1;
assign arid=0;assign arcache=0;assign arprot=0;assign arlock=0;assign arqos=0;assign arapcmd=0;
wire [127:0] pixel_data;
wire pixel_valid,fifo_full;
wire [10:0] fifo_used;
wire [10:0] fifo_free;
wire [1:0][31:0] read_addr;wire [1:0][7:0] read_len;wire [1:0][2:0] read_size;
wire [1:0][1:0] read_burst;wire [1:0] read_arvalid,read_rready,read_pvalid;
wire [1:0][127:0] read_pixels;
assign araddr=read_addr[read_kind];assign arlen=read_len[read_kind];assign arsize=read_size[read_kind];
assign arburst=read_burst[read_kind];assign arvalid=read_arvalid[read_kind];assign rready=read_rready[read_kind];
assign pixel_data=read_pixels[read_kind];assign pixel_valid=read_pvalid[read_kind];
raw_frame_read_dma reader(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.start(read_start&&!read_kind),.cancel(boundary||wait_drain),
 .base_address(selected_base),.fifo_free(fifo_free),.busy(raw_busy),.done(),.fault(raw_fault),
 .araddr(read_addr[0]),.arlen(read_len[0]),.arsize(read_size[0]),.arburst(read_burst[0]),.arvalid(read_arvalid[0]),.arready(arready&&!read_kind),
 .rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid&&!read_kind),.rready(read_rready[0]),
 .pixel_data(read_pixels[0]),.pixel_valid(read_pvalid[0]),.pixel_ready(!fifo_full&&!reset_read_fifo&&!read_kind));
comparison_read_dma compare_reader(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.start(read_start&&read_kind),.cancel(boundary||wait_drain),
 .front_bank(front_bank),.fifo_free(fifo_free),.busy(compare_busy),.done(),.fault(compare_fault),
 .araddr(read_addr[1]),.arlen(read_len[1]),.arsize(read_size[1]),.arburst(read_burst[1]),.arvalid(read_arvalid[1]),.arready(arready&&read_kind),
 .rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid&&read_kind),.rready(read_rready[1]),
 .pixel_data(read_pixels[1]),.pixel_valid(read_pvalid[1]),.pixel_ready(!fifo_full&&!reset_read_fifo&&read_kind));
wire [127:0] read_word;wire read_valid,read_ready,write_ready;
assign fifo_full=!write_ready;
raw_capture_fifo #(.WIDTH(128),.DEPTH(1024)) read_fifo(
 .cold_reset_n(!reset_read_fifo),.wr_clk(axi_clk),.rd_clk(o_clk),
 .wr_valid(pixel_valid&&write_ready&&!reset_read_fifo),.wr_data(pixel_data),.wr_ready(write_ready),
 .wr_accept(),.wr_running(),.wr_overflow(),.wr_loss_count(),.wr_free(fifo_free),
 .rd_valid(read_valid),.rd_data(read_word),.rd_ready(read_ready),.rd_running(),.rd_fault(),.rd_available());
reg video_period_d=0;
reg video_read_hold=1,seen_read_reset=0;
(* async_reg="true" *) reg [1:0] read_kind_sync=0;
always @(posedge o_clk)begin
 if(!rd_clk_rst_n)read_kind_sync<=0;else read_kind_sync<={read_kind_sync[0],read_kind};
end
assign compare_read_mode=read_kind_sync[1];
wire raw_word_ready,compare_word_ready;
assign read_ready=compare_read_mode?compare_word_ready:raw_word_ready;
rgb32_pair_unpack compare_unpack(
 .clk(o_clk),.rst(!rd_clk_rst_n),.flush(video_read_hold||!compare_read_mode||(fifo_rd_period&&!video_period_d)),
 .in_data(read_word),.in_valid(read_valid&&compare_read_mode),.in_ready(compare_word_ready),
 .out_rgb(compare_rgb),.out_valid(compare_rgb_valid),.out_ready(compare_rgb_ready));
reg [1:0] read_reset_sync=2'b11;
always @(posedge o_clk)begin
 video_period_d<=fifo_rd_period;
 read_reset_sync<={read_reset_sync[0],reset_read_fifo};
 if(!rd_clk_rst_n||(fifo_rd_period&&!video_period_d))begin video_read_hold<=1;seen_read_reset<=0;end
 else if(video_read_hold)begin
   if(read_reset_sync[1])seen_read_reset<=1;
   if(seen_read_reset&&!read_reset_sync[1])video_read_hold<=0;
 end
end
raw_pair_unpack unpack(
 .clk(o_clk),.rst(!rd_clk_rst_n),.flush(video_read_hold||(fifo_rd_period&&!video_period_d)),
 // Synthetic RAW keeps the original HDMI timing generator supplied during comparison.
 .in_data(compare_read_mode?128'd0:read_word),.in_valid(compare_read_mode||read_valid),.in_ready(raw_word_ready),
 .out_data(m_axis_tdata),.out_valid(m_axis_tvalid),.out_ready(m_axis_tready),
 .out_sof(m_axis_tuser),.out_eol(m_axis_tlast));
assign test_BURST_LEN=127;assign test_wdata=wdata[31:0];assign test_rdata=rdata[31:0];
assign test_rd_fifo_rddata=read_word[31:0];
endmodule
