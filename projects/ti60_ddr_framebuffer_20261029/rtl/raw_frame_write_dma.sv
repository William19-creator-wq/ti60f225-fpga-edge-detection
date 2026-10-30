// RAW8 frame writer. Input is a show-ahead FIFO in the AXI domain.
// Reserve a whole burst before AW so an overflow/abort never truncates AXI W.
// Exactly 1920*1080 bytes are written, with 2 KiB bursts and a 1 KiB final burst.
module raw_frame_write_dma #(
 parameter integer FRAME_BYTES=1920*1080
)(
 input logic clk,rst,start,input logic [31:0] base_address,
 input logic eof_valid,eof_ok,input logic abort_frame,
 input logic [127:0] stream_data,input logic stream_valid,
 input logic [10:0] stream_available,output logic stream_ready,
 output logic busy,done,good,
 output logic [31:0] awaddr,output logic [7:0] awlen,
 output wire [2:0] awsize,output wire [1:0] awburst,
 output logic awvalid,input logic awready,
 output wire [127:0] wdata,output wire [15:0] wstrb,
 output wire wlast,output wire wvalid,input logic wready,
 input logic bvalid,input logic [1:0] bresp,output wire bready
);
 localparam [2:0] IDLE=0,WAIT_DATA=1,ADDRESS=2,DATA=3,RESPONSE=4,DRAIN=5,FINISH=6;
 logic [2:0] state;
 logic [31:0] remaining;
 logic [8:0] burst_beats,left;
 logic ended,failed;
 logic [8:0] next_beats;
 wire [8:0] boundary_beats=9'd256-{1'b0,awaddr[11:4]};
 always_comb begin
   next_beats=(remaining>128)?9'd128:remaining[8:0];
   if(next_beats>boundary_beats)next_beats=boundary_beats;
   awvalid=state==ADDRESS;
   stream_ready=(state==DATA&&wready)||(state==DRAIN);
 end
 assign awsize=3'd4;assign awburst=2'b01;
 assign wdata=stream_data;assign wstrb=16'hffff;
 assign wlast=left==1;assign wvalid=state==DATA&&stream_valid;
 assign bready=state==RESPONSE;
 always_ff @(posedge clk)begin
   done<=0;
   if(rst)begin
     state<=IDLE;busy<=0;good<=0;awaddr<=0;awlen<=0;
     remaining<=0;burst_beats<=0;left<=0;ended<=0;failed<=0;
   end else begin
     if(busy)begin
       if(eof_valid)begin ended<=1;if(!eof_ok)failed<=1;end
       if(abort_frame)failed<=1;
     end
     case(state)
       IDLE:if(start)begin
         busy<=1;good<=0;awaddr<=base_address;remaining<=FRAME_BYTES/16;
         ended<=0;failed<=base_address[3:0]!=0;state<=WAIT_DATA;
       end
       WAIT_DATA:begin
         if(failed||abort_frame||(eof_valid&&!eof_ok))state<=DRAIN;
         else if(remaining==0)state<=FINISH;
         else if(stream_available>=next_beats&&next_beats!=0)begin
           burst_beats<=next_beats;left<=next_beats;awlen<=next_beats-1;state<=ADDRESS;
         end else if(ended)begin failed<=1;state<=DRAIN;end
       end
       ADDRESS:if(awready)state<=DATA;
       DATA:if(wvalid&&wready)begin
         left<=left-1;
         if(left==1)state<=RESPONSE;
       end
       RESPONSE:if(bvalid)begin
         if(bresp!=0)begin failed<=1;state<=DRAIN;end
         else begin
           remaining<=remaining-burst_beats;
           awaddr<=awaddr+({23'd0,burst_beats}<<4);state<=WAIT_DATA;
         end
       end
       // EOF mailbox must follow producer FIFO writes; the integration waits
       // for synchronized FIFO count to settle before asserting eof_valid here.
       DRAIN:if(ended&&!stream_valid&&stream_available==0)begin
         busy<=0;done<=1;good<=0;state<=IDLE;
       end
       FINISH:begin
         if(stream_valid||failed||abort_frame||(eof_valid&&!eof_ok))begin failed<=1;state<=DRAIN;end
         else if(ended)begin busy<=0;done<=1;good<=1;state<=IDLE;end
       end
       default:state<=IDLE;
     endcase
   end
 end
endmodule
