/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2025 Efinix Inc. All rights reserved.
//
// pt_demo.v
//
//  Example design using the T8 PLL and Oscillator
// 
// *******************************
// Revisions:
// 0.0 Initial rev
// *******************************
/////////////////////////////////////////////////////////////////////////////

module pt_demo (Oclk, Fclk, Sclk, resetn, locked, pll_resetn, Oled, Fled, Sled, Sled_OE);
   localparam N = 4;
   
   (* syn_peri_port = 0 *) input Oclk;
   (* syn_peri_port = 0 *) input Fclk;
   (* syn_peri_port = 0 *) input Sclk;
   (* syn_peri_port = 0 *) input resetn;
   (* syn_peri_port = 0 *) input locked;
   (* syn_peri_port = 0 *) output pll_resetn;
   (* syn_peri_port = 0 *) output reg [N-1:0] Fled;
   (* syn_peri_port = 0 *) output reg [N-1:0] Oled;
   (* syn_peri_port = 0 *) output reg [N-1:0] Sled;
   (* syn_peri_port = 0 *) output [N-1:0] Sled_OE;

   assign pll_resetn = resetn;
   assign Sled_OE = {N{locked}};
   
   always@(posedge Oclk) begin
	  Oled <= Oled + 1;
   end

   always@(posedge Fclk or negedge resetn) begin
	  if (~resetn)
		Fled <= 0;
	  else if (locked)
		Fled <= Fled + 1;
   end

   always@(posedge Sclk or negedge resetn) begin
	  if (~resetn)
		Sled <= 0;
	  else if (locked)
		Sled <= Sled + 1;
   end

endmodule // pt_demo


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
