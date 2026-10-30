// ReadAhead memory order: most-significant 16-bit pair first, low byte pixel first.
// One complete word is held; the FIFO supplies the next word on the last pair
// handshake, so steady-state output has no bubbles. Flush discards old prefetch.
module raw_pair_unpack(
 input logic clk,rst,flush,
 input logic [127:0] in_data,input logic in_valid,output wire in_ready,
 output wire [15:0] out_data,output wire out_valid,input logic out_ready,
 output wire out_sof,out_eol
);
 logic [127:0] word_data;logic word_valid;logic [2:0] pair_index;
 logic [9:0] x;logic [10:0] y;
 assign out_data=word_data[127:112];assign out_valid=word_valid&&!flush;
 assign in_ready=!flush&&(!word_valid||(out_ready&&pair_index==7));
 assign out_sof=word_valid&&x==0&&y==0;
 assign out_eol=word_valid&&x==959;
 always_ff @(posedge clk)begin
   if(rst||flush)begin word_valid<=0;word_data<=0;pair_index<=0;x<=0;y<=0;end
   else begin
     if(out_valid&&out_ready)begin
       word_data<=word_data<<16;pair_index<=pair_index+1;
       if(pair_index==7)word_valid<=0;
       if(x==959)begin x<=0;y<=y==1079?0:y+1;end else x<=x+1;
     end
     if(in_valid&&in_ready)begin word_data<=in_data;word_valid<=1;pair_index<=0;end
   end
 end
endmodule
