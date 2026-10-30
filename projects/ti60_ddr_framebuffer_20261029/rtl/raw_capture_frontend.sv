// Camera domain, four Bayer bytes per input beat. SOF/EOF are frame events,
// not inferred from pixel count. An armed slot is consumed only on SOF.
// pix4 uses ReadAhead {P1,P0,P3,P2}; shift order preserves its DDR reader format.
module raw_capture_frontend (
 input logic clk,rst,sof,eof,de,line_end,input logic [31:0] pix4,
 input logic armed,output logic arm_consumed,
 input logic [63:0] timestamp,
 output logic fifo_valid,output logic [127:0] fifo_data,input logic fifo_ready,
 output logic finish_valid,input logic finish_ready,
 output logic finish_ok,output logic [63:0] finish_frame_id,finish_timestamp,
 output logic [31:0] dropped_frames
);
 logic active,bad,de_d;
 logic [9:0] line_beats;
 logic [10:0] lines;
 logic [19:0] beats;
 logic [1:0] pack_count;
 logic [95:0] packed_prefix;
 logic [63:0] frame_counter,frame_stamp;
 always_ff @(posedge clk)begin
   arm_consumed<=0;fifo_valid<=0;de_d<=de;
   if(rst)begin
     active<=0;bad<=0;de_d<=0;line_beats<=0;lines<=0;beats<=0;
     pack_count<=0;packed_prefix<=0;fifo_data<=0;
     finish_valid<=0;finish_ok<=0;finish_frame_id<=0;finish_timestamp<=0;
     dropped_frames<=0;frame_counter<=0;frame_stamp<=0;
   end else begin
     if(finish_valid&&finish_ready)finish_valid<=0;
     if(fifo_valid&&!fifo_ready)bad<=1;
     if(sof)begin
       frame_counter<=frame_counter+1;
       if(armed&&!active&&!finish_valid)begin
         active<=1;bad<=0;arm_consumed<=1;frame_stamp<=timestamp;
         line_beats<=0;lines<=0;beats<=0;pack_count<=0;
       end else dropped_frames<=dropped_frames+1;
       if(active)bad<=1;
     end
     if(active)begin
       if(de)begin
         line_beats<=line_beats+1;beats<=beats+1;
         if(line_beats>=480||beats>=518400)bad<=1;
         packed_prefix<={packed_prefix[63:0],pix4};pack_count<=pack_count+1;
         if(pack_count==3)begin fifo_data<={packed_prefix,pix4};fifo_valid<=1;end
       end
       // CSI DE may have bubbles inside an HS line. Only HS ends a line.
       if(line_end)begin
         if(line_beats!=480)bad<=1;
         line_beats<=0;lines<=lines+1;
       end
       if(eof)begin
         active<=0;finish_valid<=1;
         finish_frame_id<=frame_counter;finish_timestamp<=frame_stamp;
         finish_ok<=!bad&&!de&&beats==518400&&pack_count==0&&
            ((lines==1080&&!line_end)||(lines==1079&&line_end&&line_beats==480))&&
            !(fifo_valid&&!fifo_ready);
       end
     end
   end
 end
endmodule
