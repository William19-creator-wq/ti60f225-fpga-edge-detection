/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2025 Efinix Inc. All rights reserved.
//
// helloworld_tb.v
//
// This is the test bench for helloworld.v
//
// *******************************
// Revisions:
// 0.0 Initial rev
// 1.0 Updated for Trion T8 board
// *******************************

`timescale 1ns /100ps

module sim ();

   localparam PERIOD = 1000;              // clock period in ns, 1MHz
   localparam DELAY_SIZE = 9;             // Size of the delay counter
   localparam NCYCLE = 2 ** DELAY_SIZE;   // number of cycles per LED change
   localparam WIDTH = 5;
   localparam NUM_TESTS = 10 * WIDTH;
      
   // Connections to the DUT
   reg        clk, rstn, reverse;
   wire [WIDTH-1:0] led;

   // Test values
   integer 	  i, errors = 0;
   reg [WIDTH-1:0]  led_expected = {WIDTH{1'b1}};
   
   // Define the test clock
   initial begin
      clk = 1'b0;
      forever #(PERIOD/2) clk = ~clk;
   end

   // Instantiate the DUT
   helloworld dut (.led(led), .clkin(clk), .rstn(rstn),.reverse(reverse));
   
   initial begin
	  // Generate a waveformfile
	  $dumpfile("outflow/helloworld.vcd");
	  $dumpvars(0, sim);
	  
      $display("--------------Start Helloworld Sim-------------------");
	  $display("Delay size (%d), Cycle Length (%d)", DELAY_SIZE, NCYCLE);

	  // Start with the design reset
	  rstn = 0;
	  reverse = 0;
	  
      // Check for correct initialization of LEDs
      repeat(7)@(posedge clk);
      if(led !== led_expected) begin
         $display("ERROR: LEDs failed to initialize. Actual %b does not equal expected %b", led, led_expected);
         errors = errors + 1;
      end
      else $display("LEDs passed initialization");

	  // Release reset and start testing
	  rstn = 1;
      repeat(7)@(posedge clk);

      // Loop to check for correct LED values
      for(i=0; i<NUM_TESTS; i=i+1) begin
		 // Decide when to reverse direction
		 if (i == NUM_TESTS/2) begin
			$display("Reverse direction");
			reverse = ~reverse;
		 end

		 // Do a full cycle
         repeat(NCYCLE)@(posedge clk);

		 // Calculate expected output
		 if (reverse) led_expected = {~led_expected[0], led_expected[WIDTH-1:1]};
		 else led_expected = {led_expected[WIDTH-2:0], ~led_expected[WIDTH-1]};

		 // Check the results on the negedge
		 @(negedge clk);
		 
         if(led !== led_expected) begin
            $display("ERROR: LEDs mismatch at cycle %d. Actual %b does not equal expected %b", i, led, led_expected);
            errors = errors + 1;
         end
         else $display("LEDs passed at cycle %d. Actual %b matches expected %b", i, led, led_expected);
      end

      if (errors) $display("--------------Helloworld Failed with %d errors -------------------", errors);
      else $display("--------------Helloworld Passed-------------------");
      
      $finish;
   end
endmodule

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
