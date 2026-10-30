// Display-only vertical OR. Three RAM copies supply y-1,y,y+1 in one cycle.
// Row publication tags prevent mixing incomplete rows or successive frames.
// Horizontal neighbours are combined by the presenter one pair later.
module overlay_edge_history #(parameter integer W=1920,H=1080)(
 input wire clk,rst,write_valid,input wire [1:0] write_edges,
 input wire [10:0] write_x,write_y,input wire [31:0] write_frame,
 input wire read_valid,input wire [10:0] read_x,read_y,input wire [31:0] read_frame,
 output wire [1:0] vertical_edges
);
 reg [7:0] complete;
 // All visible old-frame rows have drained before first DE of the next
 // input frame (vertical blank exceeds the six-line display delay).
 // One shared frame tag avoids three 8-to-1 32-bit tag muxes.
 reg initialized;reg [31:0] stored_frame;reg [7:0] row_tag[0:7];
 wire [12:0] wa={write_y[2:0],write_x[10:1]};
 always @(posedge clk)begin
  if(rst)begin
   complete<=0;initialized<=0;stored_frame<=0;
   for(integer r=0;r<8;r=r+1)begin row_tag[r]<=0;end
  end else if(write_valid)begin
   if(!initialized||stored_frame!=write_frame)begin
    initialized<=1;stored_frame<=write_frame;complete<=write_x==W-2?(8'b1<<write_y[2:0]):8'b0;
   end else if(write_x==W-2)complete[write_y[2:0]]<=1;
   if(write_x==W-2)row_tag[write_y[2:0]]<=write_y[10:3];
  end
 end
 wire [1:0] values[0:2];
 for(genvar k=0;k<3;k=k+1)begin:neighbour
  reg [1:0] memory[0:8191];reg [1:0] value;reg good;
  wire [10:0] row= k==0?read_y-11'd1:(k==2?read_y+11'd1:read_y);
  wire inside_row=k==0?read_y!=0:(k==2?read_y!=H-1:1'b1);
  wire [12:0] ra={row[2:0],read_x[10:1]};
  always @(posedge clk)begin
   if(write_valid)memory[wa]<=write_edges;
   if(read_valid)value<=memory[ra];
   good<=!rst&&read_valid&&inside_row&&complete[row[2:0]]&&initialized&&stored_frame==read_frame&&row_tag[row[2:0]]==row[10:3];
  end
  assign values[k]=good?value:2'b00;
 end
 assign vertical_edges=values[0]|values[1]|values[2];
endmodule
