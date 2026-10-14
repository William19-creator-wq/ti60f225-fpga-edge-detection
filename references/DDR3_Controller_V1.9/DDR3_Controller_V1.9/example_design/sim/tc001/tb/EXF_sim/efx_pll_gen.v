//--------------------------------------------------------------------------
// https://www.elitestek.com
// Copyright@2019. All rights reserved. 易灵思（深圳）科技有限公司
//--------------------------------------------------------------------------
// Module : clock_gen
// Author : Bruce Chen
// Contact: bruce.chen@elitestek.com
// Version: V1.0
// Date   : Nov.18th.2019
//--------------------------------------------------------------------------
// Decription : clock generator for psram simulation
//--------------------------------------------------------------------------

`timescale 10ps/1ps

module efx_pll_gen
#(
parameter FREQ_CLK_MHZ = 100,
parameter CLK_OUT0_ENA = 1,
parameter CLK_OUT0_MHZ = 100,
parameter CLK_OUT1_ENA = 1,
parameter CLK_OUT1_MHZ = 400,
parameter CLK_OUT2_ENA = 1,
parameter CLK_OUT2_MHZ = 400,
parameter CLK_OUT3_ENA = 1,
parameter CLK_OUT3_MHZ = 400,
parameter CLK_OUT4_ENA = 1,
parameter CLK_OUT4_MHZ = 100
)
(
input	        clk_ref			        ,
input	        rst			            ,
input	[2:0]   pll_shift			    ,
input	[4:0]   pll_shift_sel			,
input	        pll_shift_ena			,
output reg      clk_out0		        ,
output reg      clk_out1	            ,
output reg      clk_out2	            ,
output reg      clk_out3	            ,
output reg      clk_out4	            ,
output reg      pll_locked
);

reg       [2:0]   pll_shift_r [4:0];
reg       [7:0]   pll_clk_out0_r ;
reg       [7:0]   pll_clk_out1_r ;
reg       [7:0]   pll_clk_out2_r ;
reg       [7:0]   pll_clk_out3_r ;
reg       [7:0]   pll_clk_out4_r ;
localparam CYCLE 	    = 100000/FREQ_CLK_MHZ;
localparam CYCLE_SETP 	= CYCLE/8;

localparam CYCLE_0 	    = 100000/CLK_OUT0_MHZ;
localparam CYCLE_1 	    = 100000/CLK_OUT1_MHZ;
localparam CYCLE_2 	    = 100000/CLK_OUT2_MHZ;
localparam CYCLE_3 	    = 100000/CLK_OUT3_MHZ;
localparam CYCLE_4 	    = 100000/CLK_OUT4_MHZ;

localparam M 	    = 4;         //a feedback multiplier counter : 1, 2, 4
localparam N 	    = 1;         //pre-divider counter : 1, 2, 4
localparam O 	    = 1;         //post-divider counter : 1, 2, 4, 8, 16, 32, 64, 128

localparam C_FBK	= 40;
localparam F_IN 	= FREQ_CLK_MHZ;
localparam F_PFD 	= F_IN/N;
localparam F_VCO    = (F_PFD * M * O * C_FBK );
localparam F_PLL    = F_VCO / O;
//localparam F_OUT    = (F_IN * M * C_FBK) / (N * C);

localparam CYCLE_DELAY_SETP 	= 10000/ (F_PLL/4);


always @ ( * ) begin
	  if (rst)
      pll_locked <= 1'b0;
      else
      #(500*CYCLE)
      pll_locked <= 1'b1;
end

generate
genvar s;
for (s = 0; s < 5; s = s + 1) begin

always @ (posedge clk_ref or posedge rst) 
begin
    if (rst)
        pll_shift_r[s] <= 3'b0;
    else if(pll_shift_ena && pll_shift_sel[s]) 
        pll_shift_r[s] <= pll_shift;
    else;    
end
end
endgenerate

generate
if (CLK_OUT0_ENA == 1) begin: GEN_CLK_OUT0

genvar i;
for (i = 0; i < 8; i = i + 1) begin

initial begin
   pll_clk_out0_r[i] = 1'b0;
   //wait(pll_locked)
    #(100*CYCLE)
    #(CYCLE_DELAY_SETP * i)
   forever #(CYCLE_0/2) pll_clk_out0_r[i] = ~pll_clk_out0_r[i];
end

end

always @ ( * ) begin
	  if (rst)
        clk_out0 <= 1'b0;
      else 
      case(pll_shift_r[0]) 
        3'd0   : clk_out0 <= pll_clk_out0_r[0];
        3'd1   : clk_out0 <= pll_clk_out0_r[1];
        3'd2   : clk_out0 <= pll_clk_out0_r[2];
        3'd3   : clk_out0 <= pll_clk_out0_r[3];
        3'd4   : clk_out0 <= pll_clk_out0_r[4];
        3'd5   : clk_out0 <= pll_clk_out0_r[5];
        3'd6   : clk_out0 <= pll_clk_out0_r[6];
        3'd7   : clk_out0 <= pll_clk_out0_r[7];
        default: clk_out0 <= pll_clk_out0_r[0];
       endcase 
end




end else begin

always @ ( * ) begin
	  if (rst)
      clk_out0 <= 1'b0;
      else
      #(100*CYCLE)
      clk_out0 <= 1'bz;
end

end
endgenerate

generate
if (CLK_OUT1_ENA == 1) begin: GEN_CLK_OUT1

genvar i;
for (i = 0; i < 8; i = i + 1) begin

initial begin
   pll_clk_out1_r[i] = 1'b0;
   //wait(pll_locked)
    #(100*CYCLE)
    #(CYCLE_DELAY_SETP * i)
   forever #(CYCLE_1/2) pll_clk_out1_r[i] = ~pll_clk_out1_r[i];
end

always @ ( * ) begin
	  if (rst)
        clk_out1 <= 1'b0;
      else if(pll_shift_r[1] == i) 
        clk_out1 <= pll_clk_out1_r[i];
end
end

end else begin

always @ ( * ) begin
	  if (rst)
      clk_out1 <= 1'b0;
      else
      #(100*CYCLE)
      clk_out1 <= 1'bz;
end

end
endgenerate

generate
if (CLK_OUT2_ENA == 1) begin: GEN_CLK_OUT2

genvar i;
for (i = 0; i < 8; i = i + 1) begin

initial begin
   pll_clk_out2_r[i] = 1'b0;
   //wait(pll_locked)
    #(100*CYCLE)
    #(CYCLE_DELAY_SETP * i)
   forever #(CYCLE_2/2) pll_clk_out2_r[i] = ~pll_clk_out2_r[i];
end

always @ ( * ) begin
	  if (rst)
        clk_out2 <= 1'b0;
      else if(pll_shift_r[2] == i) 
        clk_out2 <= pll_clk_out2_r[i];
end
end

end else begin

always @ ( * ) begin
	  if (rst)
      clk_out2 <= 1'b0;
      else
      #(100*CYCLE)
      clk_out2 <= 1'bz;
end

end
endgenerate


generate
if (CLK_OUT3_ENA == 1) begin: GEN_CLK_OUT3

genvar i;
for (i = 0; i < 8; i = i + 1) begin

initial begin
   pll_clk_out3_r[i] = 1'b0;
   //wait(pll_locked)
    #(100*CYCLE)
    #(CYCLE_DELAY_SETP * i)
   forever #(CYCLE_3/2) pll_clk_out3_r[i] = ~pll_clk_out3_r[i];
end

always @ ( * ) begin
	  if (rst)
        clk_out3 <= 1'b0;
      else if(pll_shift_r[3] == i) 
        clk_out3 <= pll_clk_out3_r[i];
end
end

end else begin

always @ ( * ) begin
	  if (rst)
      clk_out3 <= 1'b0;
      else
      #(100*CYCLE)
      clk_out3 <= 1'bz;
end

end
endgenerate

generate
if (CLK_OUT4_ENA == 1) begin: GEN_CLK_OUT4

genvar i;
for (i = 0; i < 8; i = i + 1) begin

initial begin
   pll_clk_out4_r[i] = 1'b1;
  // wait(pll_locked)
    #(100*CYCLE)
    #(CYCLE_DELAY_SETP * i)
   forever #(CYCLE_4/2) pll_clk_out4_r[i] = ~pll_clk_out4_r[i];
end

always @ ( * ) begin
	  if (rst)
        clk_out4 <= 1'b0;
      else if(pll_shift_r[4] == i) 
        clk_out4 <= pll_clk_out4_r[i];
end
end

end else begin

always @ ( * ) begin
	  if (rst)
      clk_out4 <= 1'b0;
      else
      #(100*CYCLE)
      clk_out4 <= 1'bz;
end

end
endgenerate
/*
function integer lowest_common_multiple(input a,input b,output c);
    integer m;
    integer g;
    m = a<b ? a : b;
    while(m)begin
     if( (a%m) & (b%m))
        g = m;
     else
        m = m - 1;
    end
    c = (a*b)/g;    
endfunction

   function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
   endfunction
*/
endmodule