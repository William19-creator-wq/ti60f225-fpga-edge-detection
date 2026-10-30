// The caller pins one RAW source until done, including all write responses.
// RGB is observed before algorithms. No backpressure is applied to HDMI timing.
module thumbnail_capture_engine(
 input wire axi_clk,video_clk,reset_n,
 input wire start,input wire [31:0] target_base,input wire [63:0] source_id,
 output reg busy,output wire done,good,output reg [63:0] completed_source_id,
 input wire video_vs,video_de,input wire [47:0] video_rgb,
 output wire [31:0] awaddr,output wire [7:0] awlen,output wire [2:0] awsize,
 output wire [1:0] awburst,output wire awvalid,input wire awready,
 output wire [127:0] wdata,output wire [15:0] wstrb,output wire wlast,wvalid,
 input wire wready,bvalid,input wire [1:0] bresp,output wire bready
);
 reg arm_send;wire arm_ready,arm_receive;wire [63:0] arm_id;
 wire eof_receive;wire [64:0] eof_data;
 reg [3:0] eof_delay;reg eof_good;
 wire dma_done,dma_good;
 assign done=dma_done;assign good=dma_good;
 always @(posedge axi_clk)begin
   if(!reset_n)begin busy<=0;arm_send<=0;eof_delay<=0;eof_good<=0;completed_source_id<=0;end
   else begin
     if(start&&!busy)begin busy<=1;arm_send<=1;end
     if(arm_send&&arm_ready)arm_send<=0;
     if(eof_receive)begin eof_delay<=8;eof_good<=eof_data[64];completed_source_id<=eof_data[63:0];end
     else if(eof_delay!=0)eof_delay<=eof_delay-1;
     if(dma_done)busy<=0;
   end
 end
 // source_id and target_base are latched by the caller throughout busy.
 frame_descriptor_mailbox #(.WIDTH(64)) arm_box(
   .src_clk(axi_clk),.src_rst(!reset_n),.src_valid(arm_send),.src_ready(arm_ready),.src_data(source_id),
   .dst_clk(video_clk),.dst_rst(!reset_n),.dst_valid(arm_receive),.dst_ready(1'b1),.dst_data(arm_id));
 reg vs_d,de_d,armed,capturing,bad_video;
 reg [63:0] capture_id;
 reg [9:0] x;reg [10:0] y;
 wire frame_edge=video_vs&&!vs_d;
 wire begin_frame=frame_edge&&armed;
 wire thumb_valid,thumb_last;wire [23:0] thumb_rgb;wire [9:0] thumb_x,thumb_y;
 wire packed_valid,packed_ready,finish_valid,finish_ready,finish_ok;
 wire [127:0] packed_data;
 always @(posedge video_clk)begin
   if(!reset_n)begin
     vs_d<=0;de_d<=0;armed<=0;capturing<=0;bad_video<=0;capture_id<=0;x<=0;y<=0;
   end else begin
     vs_d<=video_vs;de_d<=video_de;
     if(arm_receive)begin armed<=1;capture_id<=arm_id;end
     if(begin_frame)begin armed<=0;capturing<=1;bad_video<=0;x<=0;y<=0;end
     if(capturing&&video_de)begin
       if(y>=1080)bad_video<=1;
       if(x==959)begin x<=0;y<=y+1;end else x<=x+1;
     end
     if(capturing&&de_d&&!video_de&&x!=0)bad_video<=1;
     if(capturing&&frame_edge)begin capturing<=0;if(x!=0||y!=1080)bad_video<=1;end
     if(thumb_last)capturing<=0;
   end
 end
 rgb_thumbnail_2x2 shrink(
   .clk(video_clk),.rst(!reset_n),.frame_start(begin_frame),.valid(capturing&&video_de),
   .rgb_pair(video_rgb),.pair_x(x),.row_y(y),.pixel_valid(thumb_valid),.pixel(thumb_rgb),
   .pixel_x(thumb_x),.pixel_y(thumb_y),.last_pixel(thumb_last));
 thumbnail_frame_pack pack(
   .clk(video_clk),.rst(!reset_n),.start(begin_frame),.abort_frame(capturing&&frame_edge),
   .pixel_valid(thumb_valid),.pixel(thumb_rgb),.pixel_x(thumb_x),.pixel_y(thumb_y),.last_pixel(thumb_last),
   .word_valid(packed_valid),.word_data(packed_data),.word_ready(packed_ready),
   .finish_valid(finish_valid),.finish_ready(finish_ready),.finish_ok(finish_ok));
 frame_descriptor_mailbox #(.WIDTH(65)) end_box(
   .src_clk(video_clk),.src_rst(!reset_n),.src_valid(finish_valid),.src_ready(finish_ready),
   .src_data({finish_ok&&!bad_video,capture_id}),.dst_clk(axi_clk),.dst_rst(!reset_n),
   .dst_valid(eof_receive),.dst_ready(1'b1),.dst_data(eof_data));
 wire [127:0] stream_data;wire stream_valid,stream_ready;wire [9:0] available;
 raw_capture_fifo #(.WIDTH(128),.DEPTH(512)) fifo(
   .cold_reset_n(reset_n),.wr_clk(video_clk),.rd_clk(axi_clk),
   .wr_valid(packed_valid&&packed_ready),.wr_data(packed_data),.wr_ready(packed_ready),
   .wr_accept(),.wr_running(),.wr_overflow(),.wr_loss_count(),.wr_free(),
   .rd_valid(stream_valid),.rd_data(stream_data),.rd_ready(stream_ready),.rd_running(),.rd_fault(),.rd_available(available));
 raw_frame_write_dma writer(
   .clk(axi_clk),.rst(!reset_n),.start(start&&!busy),.base_address(target_base),
   .eof_valid(eof_delay==1),.eof_ok(eof_good),.abort_frame(1'b0),
   .stream_data(stream_data),.stream_valid(stream_valid),.stream_available({1'b0,available}),.stream_ready(stream_ready),
   .busy(),.done(dma_done),.good(dma_good),.awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),
   .awvalid(awvalid),.awready(awready),.wdata(wdata),.wstrb(wstrb),.wlast(wlast),.wvalid(wvalid),.wready(wready),
   .bvalid(bvalid),.bresp(bresp),.bready(bready));
endmodule
