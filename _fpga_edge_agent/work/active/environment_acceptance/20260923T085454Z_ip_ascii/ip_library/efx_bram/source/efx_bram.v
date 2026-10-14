module `IP_MODULE_NAME(efx_bram) #(

parameter CLK_POLARITY      = 1'b1, 	//clk polarity;  0:falling edge; 1:rising edge
parameter CLKE_POLARITY     = 1'b1, 	//clke polarity for one clk mode; 0:active low; 1:active high
parameter CLKA_POLARITY     = 1'b1, 	//clk A polarity;  0:falling edge; 1:rising edge
parameter CLKEA_POLARITY    = 1'b1, 	//clke A polarity; 0:active low; 1:active high
parameter WEA_POLARITY	    = 1'b1, 	//we A polarity;    0:active low; 1:active high
parameter OUTPUT_REG_A   	= 1'b0, 	// Output register enable; 1:add pipe-line read register
parameter BYTEENA_POLARITY  = 1'b1,     // byteen polarity		0:active low; 1:active high 
parameter CLKB_POLARITY     = 1'b1, 	//clk A polarity;  0:falling edge; 1:rising edge
parameter CLKEB_POLARITY    = 1'b1, 	//clke A polarity; 0:active low; 1:active high
parameter WEB_POLARITY	    = 1'b1, 	//we B polarity;    0:active low; 1:active high
parameter OUTPUT_REG_B   	= 1'b0, 	// Output register enable; 1:add pipe-line read register
parameter BYTEENB_POLARITY  = 1'b1,     // byteen polarity		0:active low; 1:active high 
parameter WCLKE_POLARITY    = 1'b1, 	//wclke polarity; 0:active low; 1:active high
parameter WCLK_POLARITY     = 1'b1, 	//wclk polarity;  0:falling edge; 1:rising edge
parameter RCLK_POLARITY     = 1'b1, 	// rclk polarity; 0:falling edge; 1:rising edge
parameter WE_POLARITY	    = 1'b1, 	//we polarity;    0:active low; 1:active high
parameter RE_POLARITY       = 1'b1, 	// re polarity;	  0:active low  ; 1:active high
parameter OUTPUT_REG        = 1'b0, 	// Output register enable; 1:add pipe-line read register
parameter BYTEEN_POLARITY   = 1'b1,		//byteen polarity;    0:active low; 1:active high   
parameter WCLKE_ENABLE 		= 1'b1, 	//1: Enable  the port for waddren pin  ; 0: disable 
parameter WE_ENABLE 		= 1'b1,		//1: Enable  the port for WE pin ; 0: disable 
parameter RE_ENABLE 		= 1'b1,		//1: Enable  the port for RE pin ; 0: disable 
parameter BYTEEN_ENABLE 	= 1'b1,		//1: Enable  the port for Byteen pins ; 0: disable 
parameter RST_POLARITY 	    = 1'b1,    	// rst polarity
parameter RESET_RAM 	    = "ASYNC", 	// reset mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG 	    = "ASYNC", 	// reset mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDREN_POLARITY   = 1'b1,    	// addren polarity
parameter RESET_ENABLE 		= 1'b1,		//1: Enable  the port for reset pin  ; 0: disable 
parameter ADDREN_ENABLE 	= 1'b1,		//1: Enable  the port for addren pin  ; 0: disable 
parameter CLK_MODE			= 2,		//1: ONE CLK Mode; CLK pin will provide the clock source to the memory
									    //2: TWO CLK Mode; wclk pin will provide the clock source for write operation ; rclk pin will provide the clock source for read operation
parameter WADDREN_POLARITY  = 1'b1,    	// waddren polarity
parameter RADDREN_POLARITY  = 1'b1,     // raddren polarity
parameter CLKEA_ENABLE 		= 1'b1, 	//1: Enalbe the port for clke_a pin  ; 0: dislable 
parameter WEA_ENABLE 		= 1'b1,		//1: Enable the port for we_a pin ; 0: disable 
parameter BYTEENA_ENABLE 	= 1'b1,		//1: Enable the port for Byteen_a pins ; 0: disable 
                                        //
parameter CLKEB_ENABLE 		= 1'b1, 	//1: Enalbe the port for clke_b pin  ; 0: dislable 
parameter WEB_ENABLE 		= 1'b1,		//1: Enable the port for we_b pin ; 0: disable 
parameter BYTEENB_ENABLE 	= 1'b1,		//1: Enable the port for Byteen_b pins ; 0: disable 
parameter RSTA_POLARITY 	= 1'b1,    	// rst A polarity
parameter RESET_RAM_A 	    = "ASYNC", 	// reset A mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG_A 	= "ASYNC", 	// reset A mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDRENA_POLARITY  = 1'b1,    	// addrena polarity
parameter RSTB_POLARITY 	= 1'b1,    	// rst A polarity
parameter RESET_RAM_B 	    = "ASYNC", 	// reset A mode on ram;  "NONE": RST signals does not affect the RAM output.
										//					  "ASYNC": RAM output resets asynchronously to RCLK.
										//                     "SYNC": RAM output resets synchronously to RCLK. 
parameter RESET_OUTREG_B 	= "ASYNC", 	// reset A mode on output register
										//					   "NONE": RST signals does not affect the RAM output register		
										//					  "ASYNC": RAM output register resets asynchronously to RCLK.
parameter ADDRENB_POLARITY  = 1'b1,   	// addrenb polarity
parameter RESET_A_ENABLE 	= 1'b1,		//1: Enable the port for reset_a pin  ; 0: disable 
parameter ADDREN_A_ENABLE 	= 1'b1,		//1: Enable the port for addren_a pin  ; 0: disable 
parameter RESET_B_ENABLE 	= 1'b1,		//1: Enable the port for reset_b pin  ; 0: disable 
parameter ADDREN_B_ENABLE 	= 1'b1,		//1: Enable the port for addren_b pin  ; 0: disable 
parameter WADDREN_ENABLE 	= 1'b1,		//1: Enable the port for waddren pin  ; 0: disable 
parameter RADDREN_ENABLE 	= 1'b1,		//1: Enable the port for raddren pin  ; 0: disable 

parameter ADDR_WIDTH_A      = 3,
parameter DATA_WIDTH_A      = 16,
parameter ADDR_WIDTH_B      = 3,
parameter DATA_WIDTH_B      = 16,
parameter BYTEEN_WIDTH      = 2,
parameter BYTEEN_WIDTH_A    = 2,
parameter BYTEEN_WIDTH_B    = 2,
parameter MEMORY_TYPE		= "SP_RAM",  //1:sp_ram, 2:sdp_ram, 3:tdp_ram
parameter WRITE_MODE		= "READ_FIRST",
parameter WRITE_MODE_A		= "READ_FIRST",
parameter WRITE_MODE_B		= "READ_FIRST",
parameter FAMILY            = "TITANIUM",  //1:Titanium, 0:Trion
parameter GROUP_DATA_WIDTH  = 8,
parameter GROUP_DATA_WIDTH_A= 8,
parameter GROUP_DATA_WIDTH_B= 8,
parameter MEMORY_MODE       = "SPEED",  //1:speed, 2:area
parameter WIDTH_RATIO       = 4
)


(
//////////// data input/output ///////////////////
input wire [DATA_WIDTH_A-1:0] wdata_a,
input wire [DATA_WIDTH_B-1:0] wdata_b,
output wire [DATA_WIDTH_A-1:0] rdata_a,
output wire [DATA_WIDTH_B-1:0] rdata_b,

///////// Single Port RAM/ROM ports ////////////
input wire clk,
input wire [ADDR_WIDTH_A-1:0] addr,
input wire wclke,
input wire [BYTEEN_WIDTH-1:0] byteen,
input wire we,
input wire re,
//Titanium extra ports
input wire reset,
input wire addren,

//////////// Simple Dual Port RAM ports ///////////
input wire wclk,
input wire [ADDR_WIDTH_A-1:0] waddr,
input wire rclk,
input wire [ADDR_WIDTH_B-1:0] raddr,
//Titanium extra ports
input wire waddren,
input wire raddren,

//////////True Dual Port RAM/ROM ports ////////////////
input wire clke,
input wire clk_a, 
input wire clke_a,
input wire we_a,
input wire [BYTEEN_WIDTH_A-1:0] byteen_a,
input wire [ADDR_WIDTH_A-1:0 ] addr_a,
input wire clk_b, 
input wire clke_b,
input wire we_b,
input wire [BYTEEN_WIDTH_B-1:0] byteen_b,
input wire [ADDR_WIDTH_B-1:0 ] addr_b,
//Titanium extra ports
input wire reset_a,
input wire addren_a,
input wire reset_b,
input wire addren_b
);

generate
	if (MEMORY_TYPE == "SP_RAM") //Single Port RAM
	begin: SP_RAM_gen
		//if (BYTEEN_ENABLE == 1)
		//begin
		
	    `IP_MODULE_NAME(efx_single_port_ram) #(
	      .CLK_POLARITY    	(CLK_POLARITY   ),	
	      .WCLKE_POLARITY  	(WCLKE_POLARITY ),	
	      .WE_POLARITY	 	(WE_POLARITY	),	
	      .WRITE_MODE  	 	(WRITE_MODE  	),	
	      .RE_POLARITY     	(RE_POLARITY    ),	
	      .OUTPUT_REG      	(OUTPUT_REG     ),	
	      .BYTEEN_POLARITY 	(BYTEEN_POLARITY),	
	      .WCLKE_ENABLE 	(WCLKE_ENABLE 	),	
	      .WE_ENABLE 		(WE_ENABLE 		),	
	      .RE_ENABLE 		(RE_ENABLE 		),	
	      .BYTEEN_ENABLE 	(BYTEEN_ENABLE 	),
	      
	      .BYTEEN_WIDTH		(BYTEEN_WIDTH	),
	      .ADDR_WIDTH_A		(ADDR_WIDTH_A	),
	      .DATA_WIDTH_A		(DATA_WIDTH_A	),
	      
	      .FAMILY			(FAMILY			),
             
	         //Titanium extra paramters 
	      .RST_POLARITY 	(RST_POLARITY	), 	
	      .RESET_RAM 	    (RESET_RAM 	    ),
	      .RESET_OUTREG 	(RESET_OUTREG 	),
	      .ADDREN_POLARITY  (ADDREN_POLARITY),
	      .RESET_ENABLE 	(RESET_ENABLE 	),
	      .ADDREN_ENABLE 	(ADDREN_ENABLE 	)
        ) 
	    spram_inst
	    (
	      .clk		(clk	),
	      .addr		(addr	),
	      .wclke	(wclke	),
	      .byteen	(byteen	),
	      .we		(we		),
	      .wdata_a	(wdata_a),
	      .re		(re		),
	      .rdata_a	(rdata_a),
	      .reset	(reset	),
	      .addren	(addren	)
	    );
		//end
		//else if (BYTEEN_ENABLE == 0) 
		//begin
		//	
		//	`IP_MODULE_NAME(efx_single_port_ram) #(
		//      .CLK_POLARITY    	(CLK_POLARITY   ),	
	    //      .WCLKE_POLARITY  	(WCLKE_POLARITY ),	
	    //      .WE_POLARITY	 	(WE_POLARITY	),	
	    //      .WRITE_MODE  	 	(WRITE_MODE  	),	
	    //      .RE_POLARITY     	(RE_POLARITY    ),	
	    //      .OUTPUT_REG      	(OUTPUT_REG     ),	
	    //      .BYTEEN_POLARITY 	(BYTEEN_POLARITY),	
	    //      .WCLKE_ENABLE 	(WCLKE_ENABLE 	),	
	    //      .WE_ENABLE 		(WE_ENABLE 		),	
	    //      .RE_ENABLE 		(RE_ENABLE 		),	
	    //      .BYTEEN_ENABLE 	(BYTEEN_ENABLE 	),
	    //      
	    //      .BYTEEN_WIDTH		(BYTEEN_WIDTH	),
		//      .ADDR_WIDTH_A		(ADDR_WIDTH_A	),
		//      .DATA_WIDTH_A		(DATA_WIDTH_A	),
		//      .DATA_WIDTH_B		(DATA_WIDTH_B	),
		//      
		//      .FAMILY			(FAMILY			),
        //      
	    //      //Titanium extra paramters 
	    //      .RST_POLARITY 	(RST_POLARITY	), 	
	    //      .RESET_RAM 	    (RESET_RAM 	    ),
	    //      .RESET_OUTREG 	(RESET_OUTREG 	),
	    //      .ADDREN_POLARITY  (ADDREN_POLARITY),
	    //      .RESET_ENABLE 	(RESET_ENABLE 	),
	    //      .ADDREN_ENABLE 	(ADDREN_ENABLE 	)
        //    ) 
		//    spram_inst
		//    (
		//      .clk		(clk	),
		//      .addr		(addr	),
		//      .wclke	(wclke	),
		//      .we		(we		),
		//      .wdata_a(wdata_a),
		//      .re		(re		),
		//      .rdata_a(rdata_a),
		//      .reset	(reset	),
		//      .addren	(addren	)
		//    );
		//end
	end
	else if (MEMORY_TYPE == "SDP_RAM") //Simple Dual Port RAM
	begin: SDP_RAM_gen
		
		`IP_MODULE_NAME(efx_simple_dual_port_ram) #(
	      .CLK_POLARITY    	(CLK_POLARITY   ),
	      .WCLK_POLARITY    (WCLK_POLARITY  ),		
	      .WCLKE_POLARITY  	(WCLKE_POLARITY ),	
	      .WE_POLARITY	 	(WE_POLARITY	),	
	      .WRITE_MODE  	 	(WRITE_MODE  	),	
	      
	      .RCLK_POLARITY    (RCLK_POLARITY  ),	
	      .RE_POLARITY     	(RE_POLARITY    ),	
	      .OUTPUT_REG      	(OUTPUT_REG     ),	
	      .BYTEEN_POLARITY 	(BYTEEN_POLARITY),
	      .CLK_MODE			(CLK_MODE),
	      .WCLKE_ENABLE 	(WCLKE_ENABLE 	),	
	      .WE_ENABLE 		(WE_ENABLE 		),	
	      .RE_ENABLE 		(RE_ENABLE 		),	
	      .BYTEEN_ENABLE 	(BYTEEN_ENABLE 	),
	      
	      .BYTEEN_WIDTH		(BYTEEN_WIDTH	),
		  .ADDR_WIDTH_A		(ADDR_WIDTH_A	),
		  .DATA_WIDTH_A		(DATA_WIDTH_A	),
		  .ADDR_WIDTH_B		(ADDR_WIDTH_B	),
		  .DATA_WIDTH_B		(DATA_WIDTH_B	),
		  
		  .FAMILY			(FAMILY			),
          
	      //Titanium extra paramters 
	      .RST_POLARITY 	(RST_POLARITY	), 	
	      .RESET_RAM 	    (RESET_RAM 	    ),
	      .RESET_OUTREG 	(RESET_OUTREG 	),
	      .RADDREN_POLARITY (RADDREN_POLARITY),
	      .WADDREN_POLARITY (WADDREN_POLARITY),
	      .RESET_ENABLE 	(RESET_ENABLE 	),
	      .RADDREN_ENABLE 	(RADDREN_ENABLE ),
	      .WADDREN_ENABLE 	(WADDREN_ENABLE)
	    )
	      sdpram_inst
		(
		  .clk		(clk		),
		  .wclk		(wclk		),
		  .wclke	(wclke		),
		  .byteen	(byteen		),
		  .we		(we			),
		  .waddr	(waddr		),
		  .wdata_a	(wdata_a	),
		  .rclk		(rclk		),
		  .re		(re			),
		  .raddr	(raddr		),
		  .rdata_b	(rdata_b	),
		  .reset	(reset		),
		  .waddren	(waddren	),
		  .raddren	(raddren	)
		  
		);
		
	end
	else if (MEMORY_TYPE == "TDP_RAM") //True Dual Port RAM
	begin: TDP_RAM_gen
		
		`IP_MODULE_NAME(efx_true_dual_port_ram) #(
	
	      //Trion and Titanium parameters
	      .CLK_POLARITY    (CLK_POLARITY	),
	      .CLKE_POLARITY   (CLKE_POLARITY	),					
	      .CLKA_POLARITY   (CLKA_POLARITY   ),
	      .CLKEA_POLARITY  (CLKEA_POLARITY  ),
	      .WEA_POLARITY	   (WEA_POLARITY	),
	      .WRITE_MODE_A    (WRITE_MODE_A    ),
	      .OUTPUT_REG_A    (OUTPUT_REG_A    ),
	      .BYTEENA_POLARITY(BYTEENA_POLARITY),
	      .CLKB_POLARITY   (CLKB_POLARITY   ),
	      .CLKEB_POLARITY  (CLKEB_POLARITY  ),
	      .WEB_POLARITY	   (WEB_POLARITY    ),
	      .WRITE_MODE_B    (WRITE_MODE_B    ),
	      .OUTPUT_REG_B    (OUTPUT_REG_B    ),
	      .BYTEENB_POLARITY(BYTEENB_POLARITY),
	      
	      .BYTEEN_WIDTH_A	(BYTEEN_WIDTH_A	),
	      .BYTEEN_WIDTH_B	(BYTEEN_WIDTH_B	),
		  .ADDR_WIDTH_A		(ADDR_WIDTH_A	),
		  .DATA_WIDTH_A		(DATA_WIDTH_A	),
		  .ADDR_WIDTH_B		(ADDR_WIDTH_B	),
		  .DATA_WIDTH_B		(DATA_WIDTH_B	),
		  
		  .FAMILY			(FAMILY			),
	      
	      
	      //Port Enable  
	      .CLK_MODE		  (CLK_MODE		),			
	      .CLKEA_ENABLE   (CLKEA_ENABLE ),
	      .WEA_ENABLE 	  (WEA_ENABLE 	),	
	      .BYTEENA_ENABLE (BYTEENA_ENABLE ),   
	      .CLKEB_ENABLE   (CLKEB_ENABLE ),
	      .WEB_ENABLE 	  (WEB_ENABLE 	),	
	      .BYTEENB_ENABLE (BYTEENB_ENABLE ),
          
	      
	      //Titanium extra paramters 
	      .RSTA_POLARITY 	(RSTA_POLARITY 	   ),
	      .RESET_RAM_A 		(RESET_RAM_A 	   ),		  	
	      .RESET_OUTREG_A 	(RESET_OUTREG_A    ),
	      .ADDRENA_POLARITY (ADDRENA_POLARITY  ),
	      .RSTB_POLARITY 	(RSTB_POLARITY 	   ),
	      .RESET_RAM_B 	    (RESET_RAM_B 	   ),
	      .RESET_OUTREG_B 	(RESET_OUTREG_B    ),
	      .ADDRENB_POLARITY (ADDRENB_POLARITY  ),
          
	      //Port Enable  
	      .RESET_A_ENABLE 	(RESET_A_ENABLE ),
	      .ADDREN_A_ENABLE  (ADDREN_A_ENABLE),
	      .RESET_B_ENABLE 	(RESET_B_ENABLE ),
	      .ADDREN_B_ENABLE  (ADDREN_B_ENABLE)
	    ) 
	      tdpram_inst
		(
		  .clk		(clk	),
		  .clke		(clke	),
		  .clk_a	(clk_a	),
		  .clke_a	(clke_a	),
		  .we_a		(we_a	),
		  .byteen_a	(byteen_a),
		  .addr_a	(addr_a	),
		  .wdata_a	(wdata_a),
		  .rdata_a	(rdata_a),
		  .clk_b	(clk_b	),
		  .clke_b	(clke_b	),
		  .we_b		(we_b	),
		  .byteen_b	(byteen_b),
		  .addr_b	(addr_b	),
		  .wdata_b	(wdata_b),
		  .rdata_b	(rdata_b),
		  .reset_a	(reset_a),
		  .addren_a	(addren_a),
		  .reset_b	(reset_b),
		  .addren_b	(addren_b)
		  
		);
	end
	else if (MEMORY_TYPE == "SP_ROM") //Single Port ROM
	begin: SP_ROM_gen
		
		`IP_MODULE_NAME(efx_single_port_rom) #(
		
		  .CLK_POLARITY    	(CLK_POLARITY   ),	
	      .RE_POLARITY     	(RE_POLARITY    ),	
	      .OUTPUT_REG      	(OUTPUT_REG     ),	
	      .RE_ENABLE 		(RE_ENABLE 		),	
	      
	      .BYTEEN_WIDTH		(BYTEEN_WIDTH	),
		  .ADDR_WIDTH_A		(ADDR_WIDTH_A	),
		  .DATA_WIDTH_A		(DATA_WIDTH_A	),
		  .FAMILY           (FAMILY         ),
          
	      //Titanium extra paramters 
	      .RST_POLARITY 	(RST_POLARITY	), 	
	      .RESET_RAM 	    (RESET_RAM 	    ),
	      .RESET_OUTREG 	(RESET_OUTREG 	),
	      .ADDREN_POLARITY  (ADDREN_POLARITY),
	      .RESET_ENABLE 	(RESET_ENABLE 	),
	      .ADDREN_ENABLE 	(ADDREN_ENABLE 	)
	      
	    )
		sprom_inst
		(
		  .clk		(clk	),
		  .addr		(addr	),
		  .re		(re		),
		  .rdata_a	(rdata_a),
		  .reset	(reset	),
		  .addren	(addren)
		  
		);
	end
	else if (MEMORY_TYPE == "DP_ROM") //Dual Port ROM
	begin: DP_ROM_gen
		
		`IP_MODULE_NAME(efx_dual_port_rom) #(
	
	      //Trion and Titanium parameters
	      .CLK_POLARITY    ( CLK_POLARITY  ),
	      .CLKE_POLARITY   ( CLKE_POLARITY ),					
	      .CLKA_POLARITY   ( CLKA_POLARITY  ),
	      .CLKEA_POLARITY  ( CLKEA_POLARITY ),
	      
          .OUTPUT_REG_A    ( OUTPUT_REG_A   ),
	      .CLKB_POLARITY   ( CLKB_POLARITY  ),
	      .CLKEB_POLARITY  ( CLKEB_POLARITY ),
	      .OUTPUT_REG_B    ( OUTPUT_REG_B   ),
	      
	      
	      //Port Enable  
	      .CLK_MODE		(CLK_MODE		),			
	      .CLKEA_ENABLE (CLKEA_ENABLE 	),
	      .CLKEB_ENABLE (CLKEB_ENABLE 	),
	      
	      
	      //Titanium extra paramters 
	      .RSTA_POLARITY 	(RSTA_POLARITY 	   ),
	      .RESET_RAM_A 		(RESET_RAM_A 	   ),		  	
	      .RESET_OUTREG_A 	(RESET_OUTREG_A    ),
	      .ADDRENA_POLARITY (ADDRENA_POLARITY  ),
	      .RSTB_POLARITY 	(RSTB_POLARITY 	   ),
	      .RESET_RAM_B 	    (RESET_RAM_B 	   ),
	      .RESET_OUTREG_B 	(RESET_OUTREG_B    ),
	      .ADDRENB_POLARITY (ADDRENB_POLARITY  ),
          
	      //Port Enable  
	      .RESET_A_ENABLE 	(RESET_A_ENABLE ),
	      .ADDREN_A_ENABLE  (ADDREN_A_ENABLE),
	      .RESET_B_ENABLE 	(RESET_B_ENABLE ),
	      .ADDREN_B_ENABLE  (ADDREN_B_ENABLE),
	      
	      //DATA and ADDR
	      .DATA_WIDTH_A    (DATA_WIDTH_A),
	      .DATA_WIDTH_B    (DATA_WIDTH_B),
	      .ADDR_WIDTH_A    (ADDR_WIDTH_A),
	      .ADDR_WIDTH_B    (ADDR_WIDTH_B),
	      .FAMILY          (FAMILY)
	    )  
	      dprom_inst 
		(
		  .clk		(clk	),
		  .clke		(clke	),
		  .clk_a	(clk_a	),
		  .clke_a	(clke_a	),
		  .addr_a	(addr_a	),
		  .rdata_a	(rdata_a),
		  .clk_b	(clk_b	),
		  .clke_b	(clke_b	),
		  .addr_b	(addr_b	),
		  .rdata_b	(rdata_b),
		  .reset_a	(reset_a),
		  .addren_a	(addren_a),	
		  .reset_b	(reset_b),
		  .addren_b	(addren_b)
		  
		);
	end
endgenerate

endmodule





















