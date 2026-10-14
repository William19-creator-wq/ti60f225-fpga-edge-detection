/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2025 Efinix Inc. All rights reserved.
//
// helloworld.v
//
// *******************************
// Revisions:
// 0.0 Initial rev
// 1.0 Updated to use the Trion T8 board
// *******************************
/////////////////////////////////////////////////////////////////////////////

module helloworld (led, clkin, rstn, reverse);
   parameter DELAY_SIZE = 9;
   parameter WIDTH = 5;
   
   /**
	* DWIDTH is the width of the LED outputs.
	* NUM_PATTERNS is 2xWIDTH.
	* AWIDTH is log2(NUM_PATTERNS).
	* MAX_COUNT is the value where the pattern counter should reset
	**/
   localparam DWIDTH = WIDTH;
   localparam AWIDTH = 4;
   localparam NUM_PATTERNS = 2 * WIDTH;
   localparam MAX_COUNT = NUM_PATTERNS * (2 ** DELAY_SIZE);
   localparam COUNTER_SIZE = AWIDTH + DELAY_SIZE;
         
   output [WIDTH-1:0] led;
   input 			  clkin, rstn;
   (* syn_peri_port = 0 *) input reverse;
		
   wire [AWIDTH-1:0] raddr;
   reg [DWIDTH-1:0]  rdata;
   
   reg [DWIDTH-1:0]  mem [NUM_PATTERNS-1:0];
   reg [COUNTER_SIZE-1:0] counter = 0;

   // Unified Netlist Flow: Instantiate EFX_PLL_V1
   wire clk;
   EFX_PLL_V1 #(
      .N(1),
      .M(32),
      .O(1),
      .CLKOUT0_DIV(32),
      .CLKOUT1_DIV(2),
      .CLKOUT2_DIV(2),
      .REFCLK_FREQ(33.33)
   ) pll_inst1 (
      .CLKIN(clkin),
      .RSTN(rstn),
      .CLKOUT0(clk)
   );

   // LED ROM
   always @(posedge clk) begin
    case (raddr)
        4'h0: rdata <= 5'b00000;
        4'h1: rdata <= 5'b00001;
        4'h2: rdata <= 5'b00011;
        4'h3: rdata <= 5'b00111;
        4'h4: rdata <= 5'b01111;
        4'h5: rdata <= 5'b11111;
        4'h6: rdata <= 5'b11110;
        4'h7: rdata <= 5'b11100;
        4'h8: rdata <= 5'b11000;
        4'h9: rdata <= 5'b10000;
        default: rdata <= 5'b00000;
    endcase
   end

   // Use the high-order counter bits as the ROM address
   assign raddr = counter[COUNTER_SIZE-1:DELAY_SIZE];

   // Delay counter
   always @(posedge clk) begin
	  if(~rstn)
		counter <= 0;
	  else if(reverse)
		if (counter == 0) counter <= MAX_COUNT-1;
		else counter <= counter - 1'b1;
	  else
		if (counter == MAX_COUNT-1) counter <= 0;
		else counter <= counter + 1'b1;
   end

   // Assign LED values, invert since low enables LED
   assign led = ~rdata;

endmodule // helloworld

//////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2025 Efinix Inc. All rights reserved.
//
// This   document  contains  proprietary information  which   is
// protected by  copyright. All rights  are reserved.  This notice
// refers to original work by Efinix, Inc. which may be derivitive
// of other work distributed under license of the authors.  In the
// case of derivative work, nothing in this notice overrides the
// original author's license agreement.  Where applicable, the 
// original license agreement is included in it's original 
// unmodified form immediately below this header.
//
// WARRANTY DISCLAIMER.  
//     THE  DESIGN, CODE, OR INFORMATION ARE PROVIDED “AS IS” AND 
//     EFINIX MAKES NO WARRANTIES, EXPRESS OR IMPLIED WITH 
//     RESPECT THERETO, AND EXPRESSLY DISCLAIMS ANY IMPLIED WARRANTIES, 
//     INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
//     MERCHANTABILITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR 
//     PURPOSE.  SOME STATES DO NOT ALLOW EXCLUSIONS OF AN IMPLIED 
//     WARRANTY, SO THIS DISCLAIMER MAY NOT APPLY TO LICENSEE.
//
// LIMITATION OF LIABILITY.  
//     NOTWITHSTANDING ANYTHING TO THE CONTRARY, EXCEPT FOR BODILY 
//     INJURY, EFINIX SHALL NOT BE LIABLE WITH RESPECT TO ANY SUBJECT 
//     MATTER OF THIS AGREEMENT UNDER TORT, CONTRACT, STRICT LIABILITY 
//     OR ANY OTHER LEGAL OR EQUITABLE THEORY (I) FOR ANY INDIRECT, 
//     SPECIAL, INCIDENTAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES OF ANY 
//     CHARACTER INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
//     GOODWILL, DATA OR PROFIT, WORK STOPPAGE, OR COMPUTER FAILURE OR 
//     MALFUNCTION, OR IN ANY EVENT (II) FOR ANY AMOUNT IN EXCESS, IN 
//     THE AGGREGATE, OF THE FEE PAID BY LICENSEE TO EFINIX HEREUNDER 
//     (OR, IF THE FEE HAS BEEN WAIVED, $100), EVEN IF EFINIX SHALL HAVE 
//     BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGES.  SOME STATES DO 
//     NOT ALLOW THE EXCLUSION OR LIMITATION OF INCIDENTAL OR 
//     CONSEQUENTIAL DAMAGES, SO THIS LIMITATION AND EXCLUSION MAY NOT 
//     APPLY TO LICENSEE.
//
/////////////////////////////////////////////////////////////////////////////


