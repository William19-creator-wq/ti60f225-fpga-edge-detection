// 960x540 RGB stored as {8'b0, RGB888}: 2,073,600 bytes per 2 MiB slot.
// Four pixels per AXI128 word, first pixel in least significant 32 bits.
// A/B use the same format; no alignment padding is required at row boundaries.
module thumbnail_frame_pack(
 input logic clk,rst,start,abort_frame,
 input logic pixel_valid,input logic [23:0] pixel,
 input logic [9:0] pixel_x,pixel_y,input logic last_pixel,
 output logic word_valid,output logic [127:0] word_data,input logic word_ready,
 output logic finish_valid,input logic finish_ready,output logic finish_ok
);
 logic active,failed;
 logic [19:0] count;
 logic [95:0] partial;
 logic [9:0] expected_x,expected_y;
 logic ending;
 always_ff @(posedge clk)begin
   word_valid<=0;
   if(rst)begin
     active<=0;failed<=0;count<=0;partial<=0;word_data<=0;ending<=0;
     expected_x<=0;expected_y<=0;finish_valid<=0;finish_ok<=0;
   end else begin
     if(finish_valid&&finish_ready)finish_valid<=0;
     if(word_valid&&!word_ready)failed<=1;
     if(start&&!active&&!ending&&!finish_valid)begin
       active<=1;failed<=0;count<=0;expected_x<=0;expected_y<=0;
     end
     if(active&&pixel_valid)begin
       if(pixel_x!=expected_x||pixel_y!=expected_y||count>=518400)failed<=1;
       if(expected_x==959)begin expected_x<=0;expected_y<=expected_y+1;end
       else expected_x<=expected_x+1;
       case(count[1:0])
         0:partial[31:0]<={8'd0,pixel};
         1:partial[63:32]<={8'd0,pixel};
         2:partial[95:64]<={8'd0,pixel};
         3:begin word_data<={8'd0,pixel,partial};word_valid<=1;end
       endcase
       count<=count+1;
       if(last_pixel)begin
         active<=0;ending<=1;
         if(count!=518399||pixel_x!=959||pixel_y!=539)failed<=1;
       end
     end
     // Observe acceptance of the final packed word before producing EOF metadata.
     if(ending)begin
       ending<=0;finish_valid<=1;
       finish_ok<=!failed&&count==518400&&!(word_valid&&!word_ready);
     end
     if(abort_frame&&active)begin active<=0;failed<=1;ending<=1;end
   end
 end
endmodule
