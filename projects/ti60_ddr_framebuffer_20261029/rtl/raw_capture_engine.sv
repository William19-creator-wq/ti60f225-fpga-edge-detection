// End-to-end capture transport. Slot ownership is provided by frame_history_owner.
// Only one armed/in-flight capture exists; all reset domains must reset together.
module raw_capture_engine (
 input logic axi_clk,cam_clk,reset_n,enable,
 input logic sof,eof,de,line_end,input logic [31:0] pix4,input logic [63:0] cam_timestamp,
 output logic slot_request,input logic slot_grant,slot_drop,input logic [31:0] slot_base,
 output wire frame_done,frame_good,output logic [63:0] frame_id,frame_timestamp,
 output wire [31:0] dropped_frames,
 output wire [31:0] awaddr,output wire [7:0] awlen,output wire [2:0] awsize,
 output wire [1:0] awburst,output wire awvalid,input logic awready,
 output wire [127:0] wdata,output wire [15:0] wstrb,
 output wire wlast,wvalid,input logic wready,input logic bvalid,
 input logic [1:0] bresp,output wire bready
);
 logic waiting_slot,occupied,arm_send;
 logic [31:0] active_base;
 wire arm_ready,arm_receive;wire arm_bit;
 logic armed;
 wire consumed,begin_ready,begin_receive,begin_bit;
 logic begin_pending;
 wire pixel_valid,pixel_ready;wire [127:0] pixel_word;
 wire finish_valid,finish_ready,finish_ok;
 wire [63:0] finish_id,finish_time;
 wire eof_receive;wire [128:0] eof_descriptor;
 wire fifo_valid,fifo_ready;wire [127:0] fifo_data;
 wire [10:0] available;
 wire dma_busy,dma_done,dma_good;
 logic [3:0] eof_delay;
 logic eof_good;
 assign frame_done=dma_done;assign frame_good=dma_good;
 always_ff @(posedge axi_clk)begin
   slot_request<=0;
   if(!reset_n)begin
     waiting_slot<=0;occupied<=0;arm_send<=0;active_base<=0;
     eof_delay<=0;eof_good<=0;frame_id<=0;frame_timestamp<=0;
   end else begin
     if(enable&&!occupied&&!waiting_slot&&!slot_request)begin slot_request<=1;waiting_slot<=1;end
     if(slot_drop)waiting_slot<=0;
     if(slot_grant)begin waiting_slot<=0;occupied<=1;active_base<=slot_base;arm_send<=1;end
     if(arm_send&&arm_ready)arm_send<=0;
     if(dma_done)occupied<=0;
     if(eof_receive)begin
       {eof_good,frame_id,frame_timestamp}<=eof_descriptor;eof_delay<=8;
     end else if(eof_delay!=0)eof_delay<=eof_delay-1;
   end
 end
 frame_descriptor_mailbox #(.WIDTH(1)) arm_mailbox(
   .src_clk(axi_clk),.src_rst(!reset_n),.src_valid(arm_send),.src_ready(arm_ready),.src_data(1'b1),
   .dst_clk(cam_clk),.dst_rst(!reset_n),.dst_valid(arm_receive),.dst_ready(1'b1),.dst_data(arm_bit));
 always_ff @(posedge cam_clk)begin
   if(!reset_n)begin armed<=0;begin_pending<=0;end
   else begin
     if(arm_receive)armed<=1;
     if(consumed)begin armed<=0;begin_pending<=1;end
     if(begin_pending&&begin_ready)begin_pending<=0;
   end
 end
 frame_descriptor_mailbox #(.WIDTH(1)) begin_mailbox(
   .src_clk(cam_clk),.src_rst(!reset_n),.src_valid(begin_pending),.src_ready(begin_ready),.src_data(1'b1),
   .dst_clk(axi_clk),.dst_rst(!reset_n),.dst_valid(begin_receive),.dst_ready(1'b1),.dst_data(begin_bit));
 raw_capture_frontend frontend(
   .clk(cam_clk),.rst(!reset_n),.sof(sof),.eof(eof),.de(de),.line_end(line_end),.pix4(pix4),.armed(armed),.arm_consumed(consumed),
   .timestamp(cam_timestamp),.fifo_valid(pixel_valid),.fifo_data(pixel_word),.fifo_ready(pixel_ready),
   .finish_valid(finish_valid),.finish_ready(finish_ready),.finish_ok(finish_ok),
   .finish_frame_id(finish_id),.finish_timestamp(finish_time),.dropped_frames(dropped_frames));
 frame_descriptor_mailbox #(.WIDTH(129)) end_mailbox(
   .src_clk(cam_clk),.src_rst(!reset_n),.src_valid(finish_valid),.src_ready(finish_ready),
   .src_data({finish_ok,finish_id,finish_time}),.dst_clk(axi_clk),.dst_rst(!reset_n),
   .dst_valid(eof_receive),.dst_ready(1'b1),.dst_data(eof_descriptor));
 // The sensor cannot stall. A rejected word invalidates this frame in frontend,
 // while gating FIFO writes prevents its global sticky-overflow latch stopping
 // subsequent frames. The DMA drains the rejected frame before rearming.
 raw_capture_fifo #(.WIDTH(128),.DEPTH(1024)) pixels(
   .cold_reset_n(reset_n),.wr_clk(cam_clk),.rd_clk(axi_clk),
   .wr_valid(pixel_valid&&pixel_ready),.wr_data(pixel_word),.wr_ready(pixel_ready),
   .wr_accept(),.wr_running(),.wr_overflow(),.wr_loss_count(),
   .rd_ready(fifo_ready),.rd_valid(fifo_valid),.rd_data(fifo_data),
   .rd_running(),.rd_fault(),.rd_available(available));
 raw_frame_write_dma writer(
   .clk(axi_clk),.rst(!reset_n),.start(begin_receive),.base_address(active_base),
   .eof_valid(eof_delay==1),.eof_ok(eof_good),.abort_frame(1'b0),
   .stream_data(fifo_data),.stream_valid(fifo_valid),.stream_available(available),.stream_ready(fifo_ready),
   .busy(dma_busy),.done(dma_done),.good(dma_good),
   .awaddr(awaddr),.awlen(awlen),.awsize(awsize),.awburst(awburst),.awvalid(awvalid),.awready(awready),
   .wdata(wdata),.wstrb(wstrb),.wlast(wlast),.wvalid(wvalid),.wready(wready),
   .bvalid(bvalid),.bresp(bresp),.bready(bready));
endmodule
