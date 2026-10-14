////////////////////////////////////////////////////////////////////////////
//           _____       
//          / _______    Copyright (C) 2013-2022 Efinix Inc. All rights reserved.
//         / /       \   
//        / /  ..    /   tb_top.v
//       / / .'     /    
//    __/ /.'      /     Description:
//   __   \       /    
//  /_/ /\ \_____/ /     
// ____/  \_______/      
//
// *******************************
// Revisions:
// 0.0 Initial rev
//
// *******************************

module `IP_MODULE_NAME(efx_true_dual_port_ram) (
	//Trion and Titanium ports
	clk,		// clock input for one clock mode
	clke,		// clk enable
    
	clk_a, 		// A-port clk
	clke_a,		// A-port clk enable
    byteen_a,	// A-port Byteen input 
    we_a, 		// A-port write enable 
	addr_a, 	// A-port address input
    wdata_a,	// A-port write data input
	rdata_a, 	// A-port read address output
  
	clk_b, 		// B-port clk
	clke_b,		// B-port clk enable
    byteen_b,	// B-port Byteen input 
    we_b, 		// B-port write enable 
	addr_b, 	// B-port address input
    wdata_b,	// B-port write data input
	rdata_b, 	// B-port read address output
	     
	//Titanium extra ports
	reset_a,	// A-port reset 
	addren_a,	// A-port address enable
	
	reset_b,	// B-port reset 
	addren_b	// B-port address enable
	
 );

//`include "bram_decompose.vh"
	
//Trion and Titanium parameters
parameter CLK_POLARITY  = 1'b1; 		//clk polarity for one clk mode;  0:falling edge; 1:rising edge 
parameter CLKE_POLARITY = 1'b1; 		//clke polarity for one clk mode; 0:active low; 1:active high

parameter CLKA_POLARITY  = 1'b1; 		//clk A polarity;  0:falling edge; 1:rising edge
parameter CLKEA_POLARITY = 1'b1; 		//clke A polarity; 0:active low; 1:active high
parameter WEA_POLARITY	 = 1'b1; 		//we A polarity;    0:active low; 1:active high

parameter OUTPUT_REG_A   	= 1'b0; 	// Output register enable; 1:add pipe-line read register
parameter BYTEENA_POLARITY  = 1'b1;     // byteen polarity		0:active low; 1:active high 

parameter CLKB_POLARITY  = 1'b1; 		//clk A polarity;  0:falling edge; 1:rising edge
parameter CLKEB_POLARITY = 1'b1; 		//clke A polarity; 0:active low; 1:active high
parameter WEB_POLARITY	 = 1'b1; 		//we B polarity;    0:active low; 1:active high

parameter OUTPUT_REG_B   	= 1'b0; 	// Output register enable; 1:add pipe-line read register
parameter BYTEENB_POLARITY  = 1'b1;     // byteen polarity		0:active low; 1:active high 


//Port Enable  
parameter CLK_MODE			= 2;		//1: ONE CLK Mode; CLK pin will provide the clock source to the memory
										//2: TWO CLK Mode; clk_a and clk_b 
parameter CLKEA_ENABLE 		= 1'b1; 	//1: Enalbe the port for clke_a pin  ; 0: dislable 
parameter WEA_ENABLE 		= 1'b1;		//1: Enable the port for we_a pin ; 0: disable 
parameter BYTEENA_ENABLE 	= 1'b1;		//1: Enable the port for Byteen_a pins ; 0: disable 

parameter CLKEB_ENABLE 		= 1'b1; 	//1: Enalbe the port for clke_b pin  ; 0: dislable 
parameter WEB_ENABLE 		= 1'b1;		//1: Enable the port for we_b pin ; 0: disable 
parameter BYTEENB_ENABLE 	= 1'b1;		//1: Enable the port for Byteen_b pins ; 0: disable 


//Titanium extra paramters 
parameter RSTA_POLARITY 	= 1'b1;    	// rst A polarity
parameter RESET_RAM_A 	    = "ASYNC"; 	// reset A mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG_A 	= "ASYNC"; 	// reset A mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDRENA_POLARITY  = 1'b1;    	// addrena polarity

parameter RSTB_POLARITY 	= 1'b1;    	// rst A polarity
parameter RESET_RAM_B 	    = "ASYNC"; 	// reset A mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG_B 	= "ASYNC"; 	// reset A mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDRENB_POLARITY  = 1'b1;   	// addrenb polarity

//Port Enable  
parameter RESET_A_ENABLE 	= 1'b1;		//1: Enable the port for reset_a pin  ; 0: disable 
parameter ADDREN_A_ENABLE 	= 1'b1;		//1: Enable the port for addren_a pin  ; 0: disable 

parameter RESET_B_ENABLE 	= 1'b1;		//1: Enable the port for reset_b pin  ; 0: disable 
parameter ADDREN_B_ENABLE 	= 1'b1;		//1: Enable the port for addren_b pin  ; 0: disable 

parameter WRITE_MODE_A          = "READ_FIRST";
parameter WRITE_MODE_B          = "READ_FIRST";
parameter DATA_WIDTH_A          = 16;
parameter DATA_WIDTH_B          = 16;
parameter ADDR_WIDTH_A          = 4;
parameter ADDR_WIDTH_B          = 4;
parameter BYTEEN_WIDTH_A        = 2;
parameter BYTEEN_WIDTH_B        = 2;
parameter FAMILY                = "TITANIUM";

//Trion and Titanium ports
input clk;
input clke;

input clk_a; 
input clke_a;
input we_a;
input [BYTEEN_WIDTH_A-1:0] byteen_a;
input [ADDR_WIDTH_A-1:0 ] addr_a; 
input [DATA_WIDTH_A-1:0 ] wdata_a;
output [DATA_WIDTH_A-1:0 ]rdata_a;

input clk_b; 
input clke_b;
input we_b;
input [BYTEEN_WIDTH_B-1:0] byteen_b;
input [ADDR_WIDTH_B-1:0 ] addr_b; 
input [DATA_WIDTH_B-1:0 ] wdata_b;
output [DATA_WIDTH_B-1:0 ]rdata_b;

//Titanium extra ports
input reset_a;
input addren_a;

input reset_b;
input addren_b;

////////////////// wires //////////////////
wire w_clk_a;
wire w_clke_a;
wire [BYTEEN_WIDTH_A-1:0] w_byteen_a;
wire w_we_a;

wire w_clk_b;
wire w_clke_b;
wire [BYTEEN_WIDTH_B-1:0] w_byteen_b;
wire w_we_b;

wire w_reset_a;
wire w_addren_a;

wire w_reset_b;
wire w_addren_b;


assign w_clk_a    = (CLK_MODE==2)      ? clk_a : clk;
assign w_clke_a   = (CLKEA_ENABLE==1)  ? ((CLK_MODE==2) ? clke_a : clke) : CLKEA_POLARITY;
assign w_byteen_a = (BYTEENA_ENABLE==1)? byteen_a : {BYTEEN_WIDTH_A{BYTEENA_POLARITY}};
assign w_we_a     = (WEA_ENABLE==1)    ? we_a : WEA_POLARITY;

assign w_clk_b    = (CLK_MODE==2)      ? clk_b : clk;
assign w_clke_b   = (CLKEB_ENABLE==1)  ? ((CLK_MODE==2) ? clke_b : clke)  : CLKEB_POLARITY;
assign w_byteen_b = (BYTEENB_ENABLE==1)? byteen_b : {BYTEEN_WIDTH_B{BYTEENB_POLARITY}};
assign w_we_b     = (WEB_ENABLE==1)    ? we_b : WEB_POLARITY;


//Titanium extra ports
assign w_reset_a  = (RESET_A_ENABLE==1)  ? reset_a   : (RSTA_POLARITY==1'b1) ? 1'b0: 1'b1;
assign w_addren_a = (ADDREN_A_ENABLE==1) ? addren_a  : ADDRENA_POLARITY;

assign w_reset_b  = (RESET_B_ENABLE==1)  ? reset_b   : (RSTB_POLARITY==1'b1) ? 1'b0: 1'b1;
assign w_addren_b = (ADDREN_B_ENABLE==1) ? addren_b  : ADDRENB_POLARITY;


localparam CLKA_POLARITY_LC = (CLK_MODE==2) ? CLKA_POLARITY : CLK_POLARITY;
localparam CLKB_POLARITY_LC = (CLK_MODE==2) ? CLKB_POLARITY : CLK_POLARITY;

localparam CLKEA_POLARITY_LC = (CLK_MODE==2) ? CLKEA_POLARITY : CLKE_POLARITY;
localparam CLKEB_POLARITY_LC = (CLK_MODE==2) ? CLKEB_POLARITY : CLKE_POLARITY;

 	`IP_MODULE_NAME(dpram_wrapper_mwm) #(
		//Trion and Titanium parameters 
		.CLKA_POLARITY(CLKA_POLARITY_LC),
		.CLKEA_POLARITY(CLKEA_POLARITY_LC),
		.WEA_POLARITY(WEA_POLARITY),
		.WRITE_MODE_A(WRITE_MODE_A),
		
		.OUTPUT_REG_A(OUTPUT_REG_A),
		.BYTEENA_POLARITY(BYTEENA_POLARITY), 
		
		.CLKB_POLARITY(CLKB_POLARITY_LC),
		.CLKEB_POLARITY(CLKEB_POLARITY_LC),
		.WEB_POLARITY(WEB_POLARITY),
		.WRITE_MODE_B(WRITE_MODE_B),
		
		.OUTPUT_REG_B(OUTPUT_REG_B),
		.BYTEENB_POLARITY(BYTEENB_POLARITY), 
		
		//Titanium extra paramters  
		.RSTA_POLARITY(RSTA_POLARITY),
		.RESET_RAM_A(RESET_RAM_A),
		.RESET_OUTREG_A(RESET_OUTREG_A),
		.ADDRENA_POLARITY(ADDRENA_POLARITY),
		
		.RSTB_POLARITY(RSTB_POLARITY),
		.RESET_RAM_B(RESET_RAM_B),
		.RESET_OUTREG_B(RESET_OUTREG_B),
		.ADDRENB_POLARITY(ADDRENB_POLARITY),
		
		.DATA_WIDTH_A(DATA_WIDTH_A),
		.DATA_WIDTH_B(DATA_WIDTH_B),
		.ADDR_WIDTH_A(ADDR_WIDTH_A),
		.ADDR_WIDTH_B(ADDR_WIDTH_B),
		.BYTEEN_WIDTH_A(BYTEEN_WIDTH_A),
		.BYTEEN_WIDTH_B(BYTEEN_WIDTH_B),
        
		.FAMILY(FAMILY)

		
	) brams (
		//Trion and Titanium ports
		.clk_a(w_clk_a),
		.clke_a(w_clke_a),		
		.byteen_a(w_byteen_a),	 
		.we_a(w_we_a), 		
		.addr_a(addr_a), 	
		.wdata_a(wdata_a),	
		.rdata_a(rdata_a), 	
  
		.clk_b(w_clk_b),
		.clke_b(w_clke_b),		
		.byteen_b(w_byteen_b),	 
		.we_b(w_we_b), 		
		.addr_b(addr_b), 	
		.wdata_b(wdata_b),	
		.rdata_b(rdata_b), 	
	     
		//Titanium extra ports
		.reset_a(w_reset_a),	
		.addren_a(w_addren_a),	
		.reset_b(w_reset_b),	
		.addren_b(w_addren_b)	
	
	);
	
 
 
endmodule