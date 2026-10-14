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

module `IP_MODULE_NAME(dpbram_primitive) #(
	parameter FAMILY = "TITANIUM",	//0:Trion,  1:Titanium
	
	//Trion and Titanium parameters 
	parameter WRITE_WIDTH_A	 = 8, 			// write width
	parameter CLKA_POLARITY  = 1'b1, 		//clk A polarity,  0:falling edge, 1:rising edge
	parameter CLKEA_POLARITY = 1'b1, 		//clke A polarity, 0:active low, 1:active high
	parameter WEA_POLARITY	 = 1'b1, 		//we A polarity,    0:active low, 1:active high
	parameter WRITE_MODE_A 	 = "READ_FIRST",//write mode A,  "READ_FIRST" 	:Old memory content is read. (default)
											//			  	  "WRITE_FIRST" :Write data is passed to the read port.
											//				  "READ_UNKNOWN": Read and writes are unsynchronized, therefore, the results of the address can conflict.
	parameter READ_WIDTH_A	 = 8,   		// read width A
	parameter OUTPUT_REG_A   = 1'b1, 		// Output register enable, 1:add pipe-line read register

	parameter WRITE_WIDTH_B	 = 8, 			// write width
	parameter CLKB_POLARITY  = 1'b1, 		//clk A polarity,  0:falling edge, 1:rising edge
	parameter CLKEB_POLARITY = 1'b1, 		//clke A polarity, 0:active low, 1:active high
	parameter WEB_POLARITY	 = 1'b1, 		//we A polarity,    0:active low, 1:active high
	parameter WRITE_MODE_B 	 = "READ_FIRST",//write mode A,  "READ_FIRST" 	:Old memory content is read. (default)
											//			  	  "WRITE_FIRST" :Write data is passed to the read port.
											//				  "READ_UNKNOWN": Read and writes are unsynchronized, therefore, the results of the address can conflict.
	parameter READ_WIDTH_B	 = 8,   		// read width A
	parameter OUTPUT_REG_B   = 1'b0, 		// Output register enable, 1:add pipe-line read register

	//Titanium extra paramters 
	parameter RSTA_POLARITY 	= 1'b1,    	// rst A polarity
	parameter RESET_RAM_A 	    = "ASYNC", 	// reset A mode on ram,  "NONE": RST signals does not affect the RAM output.
											//					  "ASYNC": RAM output resets asynchronously to RCLK.
											//                     "SYNC": RAM output resets synchronously to RCLK. 
	parameter RESET_OUTREG_A 	= "ASYNC", 	// reset A mode on output register
											//					   "NONE": RST signals does not affect the RAM output register		
											//					  "ASYNC": RAM output register resets asynchronously to RCLK.
	parameter ADDRENA_POLARITY  = 1'b1,    	// addrena polarity
	
	parameter RSTB_POLARITY 	= 1'b1,    	// rst A polarity
	parameter RESET_RAM_B 	    = "ASYNC", 	// reset A mode on ram,  "NONE": RST signals does not affect the RAM output.
											//					  "ASYNC": RAM output resets asynchronously to RCLK.
											//                     "SYNC": RAM output resets synchronously to RCLK. 
	parameter RESET_OUTREG_B 	= "ASYNC", 	// reset A mode on output register
											//					   "NONE": RST signals does not affect the RAM output register		
											//					  "ASYNC": RAM output register resets asynchronously to RCLK.
	parameter ADDRENB_POLARITY  = 1'b1,   	// addrenb polarity

	//Titanium Option for byte enable in WEN width = 2 when it is Mode 512x16 or  512x20
		
	parameter ini_index	 		= 0
						
)   
(
//Trion and Titanium ports
	CLKA, 		// A-port clk 
	CLKEA, 		// A-port clk enable 
	WEA, 		// A-port write enable 
	ADDRA, 		// A-port address input
	WDATAA, 	// A-port write data input
	RDATAA, 	// A-port read address output
	
	CLKB, 		// B-port clk 
	CLKEB, 		// B-port clk enable 
	WEB, 		// B-port write enable 
	ADDRB, 		// B-port address input
	WDATAB, 	// B-port write data input
	RDATAB, 	// B-port read address output

 //Titanium extra ports
    
	RSTA, // A-port reset 
	ADDRENA, // A-port address enable
	
	RSTB, // B-port reset 
	ADDRENB // B-port address enable
							
 );
function integer address_map;
input integer index;//Input data width parameter 
input integer type_; //Mapped data width, Mapped Address Width for Ram 5K(Trion), Mapped Address Width for Ram 10K(Titanium), WEN width for Ram 5K(Trion),  WEN width for Ram 10K(Titanium)
case (index)
0	: address_map=	(type_==0)?	1	:(type_==1)?	12	:(type_==2)?	13	:1;
1	: address_map=	(type_==0)?	1	:(type_==1)?	12	:(type_==2)?	13	:1;
2	: address_map=	(type_==0)?	2	:(type_==1)?	11	:(type_==2)?	12	:1;
3	: address_map=	(type_==0)?	4	:(type_==1)?	10	:(type_==2)?	11	:1;
4	: address_map=	(type_==0)?	4	:(type_==1)?	10	:(type_==2)?	11	:1;
5	: address_map=	(type_==0)?	5	:(type_==1)?	10	:(type_==2)?	11	:1;
6	: address_map=	(type_==0)?	8	:(type_==1)?	9	:(type_==2)?	10	:1;
7	: address_map=	(type_==0)?	8	:(type_==1)?	9	:(type_==2)?	10	:1;
8	: address_map=	(type_==0)?	8	:(type_==1)?	9	:(type_==2)?	10	:1;
9	: address_map=	(type_==0)?	10	:(type_==1)?	9	:(type_==2)?	10	:1;
10	: address_map=	(type_==0)?	10	:(type_==1)?	9	:(type_==2)?	10	:1;
   endcase
endfunction  

localparam  WRITE_DATA_WIDTH_A		= 	address_map(WRITE_WIDTH_A,0);
localparam  WRITE_ADDRESS_WIDTH_A   = 	address_map(WRITE_WIDTH_A,(FAMILY=="TRION")?1:2);

localparam  WRITE_DATA_WIDTH_B		= 	address_map(WRITE_WIDTH_B,0);
localparam  WRITE_ADDRESS_WIDTH_B   = 	address_map(WRITE_WIDTH_B,(FAMILY=="TRION")?1:2);

//Trion and Titanium ports
input	CLKA; 		// A-port clk 
input	CLKEA; 		// A-port clk enable 
input	[0:0] WEA; 	// A-port write enable 
input	[WRITE_ADDRESS_WIDTH_A-1:0] ADDRA; 	// A-port address input
input	[WRITE_DATA_WIDTH_A-1:0] WDATAA; 	// A-port write data input
output	[WRITE_DATA_WIDTH_A-1:0] RDATAA; 	// A-port read address output
	
input	CLKB; 		// B-port clk 
input	CLKEB; 		// B-port clk enable 
input	[0:0] WEB; 	// B-port write enable 
input	[WRITE_ADDRESS_WIDTH_B-1:0] ADDRB; 		// B-port address input
input	[WRITE_DATA_WIDTH_B-1:0] WDATAB; 	// B-port write data input
output	[WRITE_DATA_WIDTH_B-1:0] RDATAB; 	// B-port read address output

 //Titanium extra ports
    
input RSTA; // A-port reset 
input ADDRENA; // A-port address enable
	
input RSTB; // B-port reset 
input ADDRENB; // B-port address enable


`include "bram_ini.vh"
 
    generate 
		if (FAMILY=="TRION")
		begin: efx_dpram_5k_gen
			EFX_DPRAM_5K # (
				.WRITE_WIDTH_A (WRITE_WIDTH_A), 
				.CLKA_POLARITY (CLKA_POLARITY), // clka polarity
				.CLKEA_POLARITY (CLKEA_POLARITY), // clkea polarity
				.WEA_POLARITY (WEA_POLARITY), // wea polarity
				.WRITE_MODE_A (WRITE_MODE_A), // A-port write mode
				
				.READ_WIDTH_A (READ_WIDTH_A), // A-port read width				
				.OUTPUT_REG_A (OUTPUT_REG_A), // A-port output register enable
	

				.WRITE_WIDTH_B (WRITE_WIDTH_B), // B-port write width
				.CLKB_POLARITY (CLKB_POLARITY), // clkb polarity
				.CLKEB_POLARITY(CLKEB_POLARITY), // clkeb polarity
				.WEB_POLARITY  (WEB_POLARITY), // web polarity
				.WRITE_MODE_B  (WRITE_MODE_B), // B-port write mode
				
				.READ_WIDTH_B  (READ_WIDTH_B), // B-port read width
				.OUTPUT_REG_B  (OUTPUT_REG_B), // B-port output register enable
 
			
				.INIT_0  (bram_ini_table(ini_index,16'h0 )), 
				.INIT_1  (bram_ini_table(ini_index,16'h1 )),
				.INIT_2  (bram_ini_table(ini_index,16'h2 )),
				.INIT_3  (bram_ini_table(ini_index,16'h3 )),
				.INIT_4  (bram_ini_table(ini_index,16'h4 )),
				.INIT_5  (bram_ini_table(ini_index,16'h5 )),
				.INIT_6  (bram_ini_table(ini_index,16'h6 )),
				.INIT_7  (bram_ini_table(ini_index,16'h7 )),
				.INIT_8  (bram_ini_table(ini_index,16'h8 )),
				.INIT_9  (bram_ini_table(ini_index,16'h9 )),
				.INIT_A  (bram_ini_table(ini_index,16'hA )),
				.INIT_B  (bram_ini_table(ini_index,16'hB )),
				.INIT_C  (bram_ini_table(ini_index,16'hC )),
				.INIT_D  (bram_ini_table(ini_index,16'hD )),
				.INIT_E  (bram_ini_table(ini_index,16'hE )),
				.INIT_F  (bram_ini_table(ini_index,16'hF )),
				.INIT_10 (bram_ini_table(ini_index,16'h10)),
				.INIT_11 (bram_ini_table(ini_index,16'h11)),
				.INIT_12 (bram_ini_table(ini_index,16'h12)),
				.INIT_13 (bram_ini_table(ini_index,16'h13))
			) 
			 dpram5k (
				//Trion and Titanium ports
				.CLKA (CLKA), // A-port clk 
				.CLKEA (CLKEA), // A-port clk enable 
				.WEA (WEA), // A-port write enable 
				.ADDRA (ADDRA), // A-port address input
				.WDATAA (WDATAA), // A-port write data input
				.RDATAA (RDATAA), // A-port read address output
				
				.CLKB (CLKB), // B-port clk 
				.CLKEB (CLKEB), // B-port clk enable 
				.WEB (WEB), // B-port write enable 
				.ADDRB (ADDRB), // B-port address input
				.WDATAB (WDATAB), // B-port write data input
				.RDATAB (RDATAB) // B-port read address output
			
			);
		end 
		else 
		begin: efx_dpram10_gen
			
			EFX_DPRAM10 # (
			
				.WRITE_WIDTH_A (WRITE_WIDTH_A), 
				.CLKA_POLARITY (CLKA_POLARITY), // clka polarity
				.CLKEA_POLARITY (CLKEA_POLARITY), // clkea polarity
				.WEA_POLARITY (WEA_POLARITY), // wea polarity
				.WRITE_MODE_A (WRITE_MODE_A), // A-port write mode
				
				.READ_WIDTH_A (READ_WIDTH_A), // A-port read width				
				.OUTPUT_REG_A (OUTPUT_REG_A), // A-port output register enable
	

				.WRITE_WIDTH_B (WRITE_WIDTH_B), // B-port write width
				.CLKB_POLARITY (CLKB_POLARITY), // clkb polarity
				.CLKEB_POLARITY(CLKEB_POLARITY), // clkeb polarity
				.WEB_POLARITY  (WEB_POLARITY), // web polarity
				.WRITE_MODE_B  (WRITE_MODE_B), // B-port write mode
				
				.READ_WIDTH_B  (READ_WIDTH_B), // B-port read width
				.OUTPUT_REG_B  (OUTPUT_REG_B), // B-port output register enable
			
			
				//Titanium extra paramters 
                .RSTA_POLARITY 	(RSTA_POLARITY), // rsta polarity
				.RESET_RAM_A 	(RESET_RAM_A), // A-port reset mode on ram 
 				.RESET_OUTREG_A 	(RESET_OUTREG_A), // A-port reset mode on output register
				.ADDRENA_POLARITY 	(ADDRENA_POLARITY), // addrena polarity

				.RSTB_POLARITY 		(RSTB_POLARITY), // rstb polarity
				.RESET_RAM_B 		(RESET_RAM_B), // B-port reset mode on ram 
 				.RESET_OUTREG_B 	(RESET_OUTREG_B), // B-port reset mode on output register
 				.ADDRENB_POLARITY 	(ADDRENB_POLARITY), // addrenb polarity
							
				
				.INIT_0  (bram_ini_table(ini_index, 16'h0 )), 
				.INIT_1  (bram_ini_table(ini_index, 16'h1 )),
				.INIT_2  (bram_ini_table(ini_index, 16'h2 )),
				.INIT_3  (bram_ini_table(ini_index, 16'h3 )),
				.INIT_4  (bram_ini_table(ini_index, 16'h4 )),
				.INIT_5  (bram_ini_table(ini_index, 16'h5 )),
				.INIT_6  (bram_ini_table(ini_index, 16'h6 )),
				.INIT_7  (bram_ini_table(ini_index, 16'h7 )),
				.INIT_8  (bram_ini_table(ini_index, 16'h8 )),
				.INIT_9  (bram_ini_table(ini_index, 16'h9 )),
				.INIT_A  (bram_ini_table(ini_index, 16'hA )),
				.INIT_B  (bram_ini_table(ini_index, 16'hB )),
				.INIT_C  (bram_ini_table(ini_index, 16'hC )),
				.INIT_D  (bram_ini_table(ini_index, 16'hD )),
				.INIT_E  (bram_ini_table(ini_index, 16'hE )),
				.INIT_F  (bram_ini_table(ini_index, 16'hF )),
				.INIT_10 (bram_ini_table(ini_index, 16'h10)),
				.INIT_11 (bram_ini_table(ini_index, 16'h11)),
				.INIT_12 (bram_ini_table(ini_index, 16'h12)),
				.INIT_13 (bram_ini_table(ini_index, 16'h13)),
				.INIT_14 (bram_ini_table(ini_index, 16'h14)),
				.INIT_15 (bram_ini_table(ini_index, 16'h15)),
				.INIT_16 (bram_ini_table(ini_index, 16'h16)),
				.INIT_17 (bram_ini_table(ini_index, 16'h17)),
				.INIT_18 (bram_ini_table(ini_index, 16'h18)),
				.INIT_19 (bram_ini_table(ini_index, 16'h19)),
				.INIT_1A (bram_ini_table(ini_index, 16'h1A)),
				.INIT_1B (bram_ini_table(ini_index, 16'h1B)),
				.INIT_1C (bram_ini_table(ini_index, 16'h1C)),
				.INIT_1D (bram_ini_table(ini_index, 16'h1D)),
				.INIT_1E (bram_ini_table(ini_index, 16'h1E)),
				.INIT_1F (bram_ini_table(ini_index, 16'h1F)),
				.INIT_20 (bram_ini_table(ini_index, 16'h20)),
				.INIT_21 (bram_ini_table(ini_index, 16'h21)),
				.INIT_22 (bram_ini_table(ini_index, 16'h22)),
				.INIT_23 (bram_ini_table(ini_index, 16'h23)),
				.INIT_24 (bram_ini_table(ini_index, 16'h24)),
				.INIT_25 (bram_ini_table(ini_index, 16'h25)),
				.INIT_26 (bram_ini_table(ini_index, 16'h26)),
				.INIT_27 (bram_ini_table(ini_index, 16'h27))
		
			)
			dpram10k(
				//Trion and Titanium ports
				.CLKA (CLKA), // A-port clk 
				.CLKEA (CLKEA), // A-port clk enable 
				.WEA (WEA), // A-port write enable 
				.ADDRA (ADDRA), // A-port address input
				.WDATAA (WDATAA), // A-port write data input
				.RDATAA (RDATAA), // A-port read address output
				
				.CLKB (CLKB), // B-port clk 
				.CLKEB (CLKEB), // B-port clk enable 
				.WEB (WEB), // B-port write enable 
				.ADDRB (ADDRB), // B-port address input
				.WDATAB (WDATAB), // B-port write data input
				.RDATAB (RDATAB), // B-port read address output
			
			
				//Titanium extra ports
				
				.RSTA (RSTA), // A-port reset 
				.ADDRENA (ADDRENA), // A-port address enable
				
				.RSTB (RSTB), // B-port reset 
				.ADDRENB (ADDRENB) // B-port address enable
				

			);
		end
	endgenerate 
      
endmodule
