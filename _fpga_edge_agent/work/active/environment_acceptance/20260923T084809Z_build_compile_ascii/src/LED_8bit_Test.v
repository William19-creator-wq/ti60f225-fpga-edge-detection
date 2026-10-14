/*-----------------------------------------------------------------------
								 \\\|///
							   \\  - -  //
								(  @ @  )  
+-----------------------------oOOo-(_)-oOOo-----------------------------+
CONFIDENTIAL IN CONFIDENCE
This confidential and proprietary software may be only used as authorized
by a licensing agreement from CrazyBingo (Thereturnofbingo).
In the event of publication, the following notice is applicable:
Copyright (C) 2012-20xx CrazyBingo Corporation
The entire notice above must be reproduced on all authorized copies.
Author				:		CrazyBingo
Technology blogs 	: 		www.crazyfpga.com
Email Address 		: 		crazyfpga@qq.com
Filename			:		LED_8bit_Test.v
Date				:		2022-02-08
Description			:		Basic LED Display design.
Modification History	:
Date			By			Version			Change Description
=========================================================================
22/02/08		CrazyBingo	1.0				Original
-------------------------------------------------------------------------
|                                     Oooo								|
+-------------------------------oooO--(   )-----------------------------+
                               (   )   ) /
                                \ (   (_/
                                 \_)
-----------------------------------------------------------------------*/

`timescale 1ns/1ns
module LED_8bit_Test
(
	//global clock
//	input				clk,            //24MHz
//	input				rst_n,
    input               pll_inst1_CLKOUT0,
    input               pll_inst1_LOCKED,

	//led interface
	output  [7:0]       led_data
);
wire    clk_ref = pll_inst1_CLKOUT0;    //96MHz
wire    sys_rst_n = pll_inst1_LOCKED;


//----------------------------
//led display for water
wire	[7:0]	led_data_r;
led_water_display
#(
	.LED_WIDTH	(8)
)
u_led_water_display
(
	//global clock
	.clk		(clk_ref),
	.rst_n		(sys_rst_n),

	//user led output
	.led_data	(led_data_r)
);
assign  led_data = ~led_data_r;


endmodule


