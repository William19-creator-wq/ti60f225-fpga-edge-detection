// Read two RGB32 pixels per video cycle; strip the unused high byte of each.
module rgb32_pair_unpack(
 input logic clk,rst,flush,
 input logic [127:0] in_data,input logic in_valid,output wire in_ready,
 output wire [47:0] out_rgb,output wire out_valid,input logic out_ready
);
 logic [127:0] held;logic valid,second;
 assign out_rgb={held[55:32],held[23:0]};assign out_valid=valid&&!flush;
 assign in_ready=!flush&&(!valid||(out_ready&&second));
 always_ff @(posedge clk)begin
   if(rst||flush)begin held<=0;valid<=0;second<=0;end
   else begin
     if(out_valid&&out_ready)begin held<=held>>64;second<=!second;if(second)valid<=0;end
     if(in_valid&&in_ready)begin held<=in_data;valid<=1;second<=0;end
   end
 end
endmodule
