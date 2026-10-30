// Capture-domain validation and AXI-domain completion are deliberately separate.
// eof_valid/eof_ok arrive through a handshake mailbox after the final FIFO write.
// No frame may be published on WLAST alone: every accepted AW needs its B response.
module frame_commit_guard #(
 parameter integer FRAME_BYTES=1920*1080
)(
 input logic clk,rst,start,
 input logic eof_valid,eof_ok,
 input logic aw_fire,input logic [7:0] awlen,
 input logic w_fire,input logic [15:0] wstrb,
 input logic b_fire,input logic [1:0] bresp,
 input logic fifo_empty,writer_idle,
 input logic abort_frame,
 output logic busy,done,good,
 output logic [15:0] pending_responses,
 output logic [31:0] error_count
);
 logic ended,failed;
 logic [31:0] bytes_written,bytes_announced;
 logic [4:0] strobes;
 always_comb begin
   strobes=0;
   for(integer k=0;k<16;k=k+1)strobes=strobes+wstrb[k];
 end
 always_ff @(posedge clk)begin
   done<=0;
   if(rst)begin
     busy<=0;good<=0;ended<=0;failed<=0;bytes_written<=0;
     bytes_announced<=0;pending_responses<=0;error_count<=0;
   end else begin
     if(start&&!busy)begin
       busy<=1;good<=0;ended<=0;failed<=0;bytes_written<=0;
       bytes_announced<=0;pending_responses<=0;
     end else if(busy)begin
       if(eof_valid)begin ended<=1;if(!eof_ok)failed<=1;end
       if(abort_frame)begin failed<=1;ended<=1;end
       if(aw_fire)bytes_announced<=bytes_announced+(({24'd0,awlen}+1)<<4);
       if(w_fire)bytes_written<=bytes_written+strobes;
       case({aw_fire,b_fire})
         2'b10:pending_responses<=pending_responses+1;
         2'b01:begin
           if(pending_responses!=0)pending_responses<=pending_responses-1;
           else failed<=1;
         end
       endcase
       if(b_fire&&bresp!=0)failed<=1;
       if(bytes_written>FRAME_BYTES||bytes_announced>FRAME_BYTES)failed<=1;
       // Settled cycle also excludes same-cycle FIFO dequeue/transaction activity.
       if(ended&&pending_responses==0&&fifo_empty&&writer_idle&&!aw_fire&&!w_fire&&!b_fire&&!abort_frame&&!eof_valid)begin
         busy<=0;done<=1;
         good<=!failed&&bytes_written==FRAME_BYTES&&bytes_announced==FRAME_BYTES;
         if(failed||bytes_written!=FRAME_BYTES||bytes_announced!=FRAME_BYTES)error_count<=error_count+1;
       end
     end
   end
 end
endmodule
