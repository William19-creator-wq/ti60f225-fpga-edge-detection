// Exact 2x2 box average after Bayer conversion, preserving RGB byte order.
// Two adjacent input pixels per cycle; one 960x540 RGB888 pixel on odd rows.
// The source reader must only present complete, leased frames in raster order.
module rgb_thumbnail_2x2 (
 input logic clk,rst,frame_start,
 input logic valid,input logic [47:0] rgb_pair,
 input logic [9:0] pair_x,input logic [10:0] row_y,
 output logic pixel_valid,output logic [23:0] pixel,
 output logic [9:0] pixel_x,output logic [9:0] pixel_y,
 output logic last_pixel
);
 logic [26:0] row_sums [0:959];
 logic [26:0] previous_sum,current_sum;
 logic [26:0] horizontal_sum;
 logic pipe_valid;
 logic [9:0] pipe_x,pipe_y;
 for(genvar c=0;c<3;c=c+1)begin
   assign horizontal_sum[c*9+:9]={1'b0,rgb_pair[c*8+:8]}+{1'b0,rgb_pair[24+c*8+:8]};
 end
 always_ff @(posedge clk)begin
   if(valid&&pair_x<960)begin
     previous_sum<=row_sums[pair_x];
     if(!row_y[0])row_sums[pair_x]<=horizontal_sum;
   end
   current_sum<=horizontal_sum;
   pipe_x<=pair_x;pipe_y<=row_y[10:1];
   pipe_valid<=valid&&row_y[0]&&pair_x<960&&row_y<1080;
   pixel_valid<=pipe_valid;pixel_x<=pipe_x;pixel_y<=pipe_y;
   last_pixel<=pipe_valid&&pipe_x==959&&pipe_y==539;
   for(integer c=0;c<3;c=c+1)
     pixel[c*8+:8]<=({1'b0,previous_sum[c*9+:9]}+{1'b0,current_sum[c*9+:9]})>>2;
   if(rst||frame_start)begin pipe_valid<=0;pixel_valid<=0;last_pixel<=0;end
 end
endmodule
