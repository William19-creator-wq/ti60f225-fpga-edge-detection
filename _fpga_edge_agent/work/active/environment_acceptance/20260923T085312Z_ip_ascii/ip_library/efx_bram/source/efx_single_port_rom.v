////////////////////////////////////////////////////////////////////////////
//           _____       
//          / _______    Copyright (C) 2013-2022 Efinix Inc. All rights reserved.
//         / /       \   
//        / /  ..    /   efx_single_port_ram.v
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

module `IP_MODULE_NAME(efx_single_port_rom) (
	//Trion and Titanium ports
	clk,		// clock input for one clock mode
	addr, 		// address input

  
    re, 		// Read-enable input
    rdata_a, 	// Read data output     
     
	//Titanium extra ports
	reset,		 // reset	
	addren	     // address enable
 );

//`include "bram_decompose.vh"

//Trion and Titanium parameters 
parameter CLK_POLARITY  = 1'b1; 		//clk polarity;  0:falling edge; 1:rising edge

parameter RE_POLARITY    = 1'b1; 		// re polarity;	  0:active low  ; 1:active high
parameter OUTPUT_REG     = 1'b0; 		// Output register enable; 1:add pipe-line read register

parameter RE_ENABLE 		= 1'b1;		//1: Enable  the port for RE pin ; 0: disable 


//Titanium extra paramters 
parameter RST_POLARITY 	    = 1'b1;    	// rst polarity
parameter RESET_RAM 	    = "ASYNC"; 	// reset mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG 	    = "ASYNC"; 	// reset mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDREN_POLARITY  = 1'b1;    	// addren polarity


//Port Enable  
parameter RESET_ENABLE 		= 1'b1;		//1: Enable  the port for reset pin  ; 0: disable 
	
parameter ADDREN_ENABLE 	= 1'b1;		//1: Enable  the port for addren pin  ; 0: disable 

parameter WRITE_MODE        = "READ_FIRST";

parameter FAMILY     = "TITANIUM";

parameter DATA_WIDTH_A      = 16;
parameter ADDR_WIDTH_A      = 3;
parameter BYTEEN_WIDTH      = 2;

//Trion and Titanium ports
input clk;
input [ADDR_WIDTH_A-1:0] addr;

input re; 
output [DATA_WIDTH_A-1:0] rdata_a;

//Titanium extra ports
input reset;	
input addren;

wire w_wclk;
wire w_rclk;
wire w_wclke;
wire [BYTEEN_WIDTH-1:0] w_byteen;

wire w_re;
wire w_reset;
wire w_addren;

assign w_re   = (RE_ENABLE==1)  ? re : RE_POLARITY;

//Titanium extra ports
assign w_reset   = (RESET_ENABLE==1)  ? reset   : (RST_POLARITY==1'b1) ? 1'b0: 1'b1;
assign w_addren = (ADDREN_ENABLE==1)? addren : ADDREN_POLARITY;

 	`IP_MODULE_NAME(bram_wrapper_mwm) #(
		//Trion and Titanium parameters 
		.WCLK_POLARITY(1'b1), 	
		.WCLKE_POLARITY(1'b1),
		.WE_POLARITY(1'b1), 		
		.WRITE_MODE("READ_FIRST"),		
				
		.RCLK_POLARITY(CLK_POLARITY), 	
		.RE_POLARITY(RE_POLARITY), 		
		.OUTPUT_REG(OUTPUT_REG),	
		
		.DATA_WIDTH_A(DATA_WIDTH_A),
		.DATA_WIDTH_B(DATA_WIDTH_A),
		.ADDR_WIDTH_A(ADDR_WIDTH_A),
		.ADDR_WIDTH_B(ADDR_WIDTH_A),
		.BYTEEN_WIDTH(BYTEEN_WIDTH),
		.FAMILY(FAMILY),
		
		.BYTEEN_POLARITY(1'b1),
		
		//Titanium extra paramters 
		.RST_POLARITY(RST_POLARITY),   	
		.RESET_RAM(RESET_RAM), 			
		.RESET_OUTREG(RESET_OUTREG), 	
		.WADDREN_POLARITY(ADDREN_POLARITY),
		.RADDREN_POLARITY(ADDREN_POLARITY) 
		
	) brams (
		.wclk(clk), 
		.wclke(1'b1),
		.we(1'b0), 
		.byteen({BYTEEN_WIDTH{1'b0}}),
        
        .waddr({ADDR_WIDTH_A{1'b0}}), 
		.wdata({DATA_WIDTH_A{1'b0}}),
          
		.rclk(clk), 
		.re(w_re), 
		.raddr(addr), 
		.rdata(rdata_a),
		      
        
		//Titanium extra ports
		.reset(w_reset), 	// reset	
		.waddren(w_addren), // write address enable
		.raddren(w_addren)  // read address enable	
	);
 
 
endmodule