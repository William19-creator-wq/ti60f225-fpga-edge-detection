/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2025 Efinix Inc. All rights reserved.
//
// fir.v
//
//  Systolic FIR Filter
// 
//  Optimize DSP performance and area.
//
//  y[n]=x[n]*h[n] + x[n-1]*h[n-1] + ... + x[0]*h[0]
//
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

/**
 * Single TAP of the filter
 */
module tap (clk, aclr, ena, x_in, y_in, x_out, y_out) ;

   parameter DATA_WIDTH = 18 ;
   parameter COEF_WIDTH = 18 ;
   parameter ACCUM_WIDTH = 36 ;
   parameter COEF = 1;
   
   localparam MULT_WIDTH = DATA_WIDTH+COEF_WIDTH;
   
   input 		                       clk, aclr, ena ;
   input signed [DATA_WIDTH-1:0] 	   x_in ;
   input signed [ACCUM_WIDTH-1:0] 	   y_in ;
   output signed [DATA_WIDTH-1:0] 	   x_out ;
   output signed [ACCUM_WIDTH-1:0] 	   y_out ;

   reg signed [COEF_WIDTH-1:0] 		   h_r ;
   reg signed [DATA_WIDTH-1:0] 		   x_r [0:1] ;
   reg signed [MULT_WIDTH-1:0] 		   m_r ;
   reg signed [ACCUM_WIDTH-1:0] 	   y_r ;
   

    always@(posedge clk or negedge aclr) begin
	  if (~aclr) begin
		 x_r[0] <= 0 ;
		 x_r[1] <= 0 ;
		 h_r <= 0 ;
		 m_r <= 0;
		 y_r <= 0 ;
	  end
	  else if (ena) begin
		 // capture the data_in and data_out shifts
		 x_r[0] <= x_in;
		 x_r[1] <= x_r[0];

		 // setup the coef data
		 // Use register so that mult is fully registered
		 h_r <= COEF ;
		 
		 // multiply data and coef
		 // register output
		 m_r <= x_r[1] * h_r ;

		 // Now accumulate
		 y_r <= m_r + y_in ;
	  end
   end // always@ (posedge clk)

   // Assign the outputs
   assign x_out = x_r[1] ;
   assign y_out = y_r ;

endmodule // tap

/**
 * Top-level parameterized filter that instatiates Taps
 */
module fir (clk, aclr, ena, x, y) ;
   
   parameter DATA_WIDTH = 18;
   parameter COEF_WIDTH = 18;
   parameter NUM_TAPS = 36;
   // Max accumulator width is
   // DATA_WIDTH + COEF_WIDTH + LOG2(NUM_TAPS)
   localparam ACCUM_WIDTH = DATA_WIDTH+COEF_WIDTH+6;
   
   input 		                       clk, aclr, ena ;
   input signed [DATA_WIDTH-1:0] 	   x ;
   output signed [ACCUM_WIDTH-1:0] 	   y ;

   wire signed [DATA_WIDTH-1:0] 	   x_w [0:NUM_TAPS] ;
   wire signed [ACCUM_WIDTH-1:0] 	   y_w [0:NUM_TAPS] ;
   reg signed [DATA_WIDTH-1:0] 		   x_r ;
   reg signed [ACCUM_WIDTH-1:0] 	   y_r ;

   /**
	* Connect input & output data
	*/
   always@(posedge clk or negedge aclr) begin
	  if (~aclr) begin
		 x_r <= 0 ;
		 y_r <= 0 ;
	  end
	  else if (ena) begin
		 x_r <= x ;
		 y_r <= y_w[NUM_TAPS] ;
	  end
   end
   assign x_w[0] = x_r ;
   assign y_w[0] = 0 ;
   assign y = y_r ;
      
   /**
	* Instantiate al the taps
	*/
   genvar n; 
   generate 
	  for (n=0; n < NUM_TAPS; n = n+1) begin : TAP 
		 tap u (
				.clk(clk), 
				.aclr(aclr), 
				.ena(ena),
				.x_in(x_w[n]),
				.y_in(y_w[n]),
				.x_out(x_w[n+1]),
				.y_out(y_w[n+1])
				); 
		 defparam u.DATA_WIDTH = DATA_WIDTH;
		 defparam u.COEF_WIDTH = COEF_WIDTH;
		 defparam u.ACCUM_WIDTH = ACCUM_WIDTH;
		 // For now coefficient data calculated here
		 defparam u.COEF = n + 3;
      end 
   endgenerate
   
endmodule // fir

//////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2016 Efinix Inc. All rights reserved.
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
