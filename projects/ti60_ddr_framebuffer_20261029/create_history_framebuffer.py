from pathlib import Path
p=Path(__file__).resolve().parent
s=(p/'rtl/frame_buffer_V4/frame_buffer.v').read_text(encoding='utf-8')
header=s[:s.index('assign test_BURST_LEN')].replace('module frame_buffer','module history_frame_buffer')
header=header.replace('input ','''input wire command_valid,
input wire [1:0] command_mode,
input wire [5:0] command_index,
input wire [1:0] bresp,
output wire [1:0] playback_mode,
output wire [5:0] playback_position,
output wire [6:0] history_count,
output wire [63:0] source_frame_id,
output wire history_fault,
input ''',1)
tail=s[s.index('localparam FIFO_DIPTH'):]
body='''
wire wr_clk_rst_n,axi_clk_rst_n,rd_clk_rst_n;
rst_n_piple #(.DLY(3)) cr(.clk(i_clk),.rst_n_i(rst_n),.rst_n_o(wr_clk_rst_n));
rst_n_piple #(.DLY(3)) ar(.clk(axi_clk),.rst_n_i(rst_n),.rst_n_o(axi_clk_rst_n));
rst_n_piple #(.DLY(3)) vr(.clk(o_clk),.rst_n_i(rst_n),.rst_n_o(rd_clk_rst_n));
reg vs_last=0,active_vs=1;
reg [63:0] timestamp=0;
always @(posedge i_clk)begin
  vs_last<=i_vs;
  if(i_de)active_vs<=i_vs;
  if(!wr_clk_rst_n)timestamp<=0;else timestamp<=timestamp+1;
end
wire sof=(i_vs!=vs_last)&&(i_vs==active_vs);
wire eof=(i_vs!=vs_last)&&(i_vs!=active_vs);
reg [2:0] period_sync=0;
always @(posedge axi_clk)period_sync<={period_sync[1:0],fifo_rd_period};
wire boundary=period_sync[1]&&!period_sync[2];
wire read_busy,read_done,read_fault;
reg wait_drain=0;reg [5:0] blank_window=0;reg read_start=0;
wire selected_valid;wire [31:0] selected_base;
wire reset_read_fifo=!axi_clk_rst_n||boundary||wait_drain||blank_window!=0;
always @(posedge axi_clk)begin
  read_start<=0;
  if(!axi_clk_rst_n)begin wait_drain<=0;blank_window<=0;end
  else if(boundary)begin wait_drain<=1;blank_window<=0;end
  else if(wait_drain&&!read_busy)begin wait_drain<=0;blank_window<=32;end
  else if(blank_window!=0)begin
    blank_window<=blank_window-1;
    if(blank_window==1&&selected_valid)read_start<=1;
  end
end
wire owner_fault;
raw_frame_store store(
 .axi_clk(axi_clk),.cam_clk(i_clk),.reset_n(rst_n),.enable(axi_clk_rst_n),
 .sof(sof),.eof(eof),.de(i_de),.pix4(vin),.cam_timestamp(timestamp),
 .command_valid(command_valid),.command_mode(command_mode),.command_index(command_index),
 .display_boundary(blank_window!=0),.reads_drained(!read_busy&&blank_window!=0),
 .mode(playback_mode),.position(playback_position),.selected_valid(selected_valid),.selected_base(selected_base),
 .selected_frame_id(source_frame_id),.apply(),.history_count(history_count),.fault(owner_fault),
 .capture_drops(),.slot_drops(),.bad_frames(),
 .awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),.awvalid(awvalid),.awready(awready),
 .wdata(wdata),.wstrb(wstrb),.wlast(wlast),.wvalid(wvalid),.wready(wready),.bvalid(bvalid),.bresp(bresp),.bready(bready));
assign history_fault=owner_fault||read_fault;
assign awid=0;assign awcache=0;assign awprot=0;assign awlock=0;assign awqos=0;
assign awcobuf=0;assign awapcmd=0;assign awallstrb=1;
assign arid=0;assign arcache=0;assign arprot=0;assign arlock=0;assign arqos=0;assign arapcmd=0;
wire [127:0] pixel_data;
wire pixel_valid,fifo_full;
wire [10:0] fifo_used;
wire [10:0] fifo_free=11'd1024-fifo_used;
raw_frame_read_dma reader(
 .clk(axi_clk),.rst(!axi_clk_rst_n),.start(read_start),.cancel(boundary||wait_drain),
 .base_address(selected_base),.fifo_free(fifo_free),.busy(read_busy),.done(read_done),.fault(read_fault),
 .araddr(araddr),.arlen(arlen),.arsize(arsize),.arburst(arburst),.arvalid(arvalid),.arready(arready),
 .rdata(rdata),.rresp(rresp),.rlast(rlast),.rvalid(rvalid),.rready(rready),
 .pixel_data(pixel_data),.pixel_valid(pixel_valid),.pixel_ready(!fifo_full));
wire [127:0] rd_fifo_rddata;wire rd_fifo_rdempty,rd_fifo_rden;
reg rd_fifo_rdvalid=0;
always @(posedge o_clk)rd_fifo_rdvalid<=rd_fifo_rden&&!rd_fifo_rdempty;
DC_FIFO #(.FIFO_MODE("Normal"),.DATA_WIDTH(128),.FIFO_DEPTH(1024)) read_fifo(
 .Reset(reset_read_fifo),.WrClk(axi_clk),.WrEn(pixel_valid&&!fifo_full&&!reset_read_fifo),.WrDNum(fifo_used),
 .WrFull(fifo_full),.WrData(pixel_data),.RdClk(o_clk),.RdEn(rd_fifo_rden),.RdDNum(),
 .RdEmpty(rd_fifo_rdempty),.RdData(rd_fifo_rddata));
wire [O_VID_WIDTH-1:0] o_fifo_rd_data;
wire o_fifo_rd_en,o_fifo_rd_empty;
assign test_BURST_LEN=127;assign test_wdata=wdata[31:0];assign test_rdata=rdata[31:0];
assign test_rd_fifo_rddata=rd_fifo_rddata[31:0];
'''
(p/'rtl/history_frame_buffer.sv').write_text(header+body+tail,encoding='utf-8')
print('Created history framebuffer wrapper; fixed RAW8 1080p, AXI128, 1024-word read FIFO.')
