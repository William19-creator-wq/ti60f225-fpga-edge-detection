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
// 1.0 Fixed No-Change Mode Issue (Addressing More than One Bram from Read Mux),  11 March  2025 A
// *******************************

module `IP_MODULE_NAME(dpram_wrapper_mwm) #(
	//Trion and Titanium parameters 
	parameter CLKA_POLARITY  = 1'b1, 		//clk A polarity,  0:falling edge, 1:rising edge
	parameter CLKEA_POLARITY = 1'b1, 		//clke A polarity, 0:active low, 1:active high
	parameter WEA_POLARITY	 = 1'b1, 		//we A polarity,    0:active low, 1:active high
	parameter WRITE_MODE_A 	 = "READ_FIRST",//write mode A,  "READ_FIRST" 	:Old memory content is read. (default)
											//			  	  "WRITE_FIRST" :Write data is passed to the read port.
											//				  "NO_CHANGE": Previously read data is held.
											
	parameter OUTPUT_REG_A   = 1'b0, 		// Output register enable, 1:add pipe-line read register
	parameter BYTEENA_POLARITY   = 1'b1,     // byteen polarity		0:active low, 1:active high 
	
	parameter CLKB_POLARITY  = 1'b1, 		//clk A polarity,  0:falling edge, 1:rising edge
	parameter CLKEB_POLARITY = 1'b1, 		//clke A polarity, 0:active low, 1:active high
	parameter WEB_POLARITY	 = 1'b1, 		//we B polarity,    0:active low, 1:active high
	parameter WRITE_MODE_B 	 = "READ_FIRST",//write mode A,  "READ_FIRST" 	:Old memory content is read. (default)
											//			  	  "WRITE_FIRST" :Write data is passed to the read port.
											//				  "NO_CHANGE": Previously read data is held.
	
	parameter OUTPUT_REG_B   = 1'b0, 		// Output register enable, 1:add pipe-line read register
	parameter BYTEENB_POLARITY   = 1'b1,     // byteen polarity		0:active low, 1:active high 
	
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
	
    parameter DATA_WIDTH_A          = 16,
    parameter DATA_WIDTH_B          = 16,
    parameter ADDR_WIDTH_A          = 4,
    parameter ADDR_WIDTH_B          = 4,
    parameter BYTEEN_WIDTH_A        = 2,
    parameter BYTEEN_WIDTH_B        = 2,
    parameter FAMILY                = "TITANIUM"
	

	//Titanium Option for byte enable in WEN width = 2 when it is Mode 512x16 or  512x20
)   
(
	//Trion and Titanium ports
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

`include "bram_decompose.vh"
//`include "bram_feature.vh"

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

input reset_a;
input addren_a;

input reset_b;
input addren_b;


localparam MAP_ADDR_WIDTH_A = (address_mapping_table_A_size!=0)?address_mapping_table_A_size:ADDR_WIDTH_A;
localparam MAP_ADDR_WIDTH_B = (address_mapping_table_B_size!=0)?address_mapping_table_B_size:ADDR_WIDTH_B;



wire [MAP_ADDR_WIDTH_A-1:0 ] w_addr_map_a; 
wire [DATA_WIDTH_A-1:0 ] w_wdata_map_a;
wire [DATA_WIDTH_A-1:0 ] w_rdata_map_a;

wire [MAP_ADDR_WIDTH_B-1:0 ] w_addr_map_b; 
wire [DATA_WIDTH_B-1:0 ] w_wdata_map_b;
wire [DATA_WIDTH_B-1:0 ] w_rdata_map_b;

wire clk_a_i;
wire clk_b_i;
assign clk_a_i = clk_a ~^ CLKA_POLARITY;
assign clk_b_i = clk_b ~^ CLKB_POLARITY;


//Reset Support Titanium Only
wire ram_async_rsta; 
wire ram_sync_rsta;
wire outreg_async_rsta;

wire ram_async_rstb; 
wire ram_sync_rstb;
wire outreg_async_rstb;

assign outreg_async_rsta = (RESET_OUTREG_A == "ASYNC") ? (reset_a ~^ RSTA_POLARITY) : 1'b0;
assign ram_async_rsta    = (RESET_RAM_A == "ASYNC")    ? (reset_a ~^ RSTA_POLARITY) : 1'b0;
assign ram_sync_rsta     = (RESET_RAM_A == "SYNC")     ? (reset_a ~^ RSTA_POLARITY) : 1'b0;

assign outreg_async_rstb = (RESET_OUTREG_B == "ASYNC") ? (reset_b ~^ RSTB_POLARITY) : 1'b0;
assign ram_async_rstb    = (RESET_RAM_B == "ASYNC")    ? (reset_b ~^ RSTB_POLARITY) : 1'b0;
assign ram_sync_rstb     = (RESET_RAM_B == "SYNC")     ? (reset_b ~^ RSTB_POLARITY) : 1'b0;


function integer get_current_row_index;
input integer row;//Mode type 
integer x;	
	begin
		get_current_row_index = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if (bram_mapping_table(x,0) < row)
				get_current_row_index = get_current_row_index +1;
		end
	end 
endfunction 

function integer get_current_column_index;
input integer column;//Mode type 
integer x;	
	begin
		get_current_column_index = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if (bram_mapping_table(x,1) < column)
				get_current_column_index = get_current_column_index +1;
		end
	end 
endfunction 


function integer get_max_mux_row_A;
input integer temp;//Mode type
integer x;	
	begin
		get_max_mux_row_A = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if ( get_max_mux_row_A < bram_mapping_table(x,5) )
				get_max_mux_row_A =  bram_mapping_table(x,5);
		end
	end 
endfunction 

function integer get_max_wen_decode_A;
input integer temp;//Mode type
integer x;	
	begin
		get_max_wen_decode_A = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if ( get_max_wen_decode_A < bram_mapping_table(x,6) )
				get_max_wen_decode_A =  bram_mapping_table(x,6);
		end
	end 
endfunction 


function integer get_max_mux_row_B;
input integer temp;//Mode type
integer x;	
	begin
		get_max_mux_row_B = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if ( get_max_mux_row_B < bram_mapping_table(x,12) )
				get_max_mux_row_B =  bram_mapping_table(x,12);
		end
	end 
endfunction 

function integer get_max_wen_decode_B;
input integer temp;//Mode type
integer x;	
	begin
		get_max_wen_decode_B = 0;
		for (x=0; x<bram_mapping_size; x=x+1)
		begin
			if ( get_max_wen_decode_B < bram_mapping_table(x,13) )
				get_max_wen_decode_B =  bram_mapping_table(x,13);
		end
	end 
endfunction 



 //   localparam column_size = (bram_table_loop_mode==1)?bram_table_size:1;
   // wire [DATA_WIDTH_B-1:0] w_rdata [bram_table_size-1:0 ];
   // assign rdata = w_rdata[wdata];
    genvar gen_x;
    genvar gen_y;
	genvar gen_z;

	wire w_clke_a_tmp = clke_a ~^ CLKEA_POLARITY;
	wire w_clke_a;
	assign w_clke_a = w_clke_a_tmp;

	wire w_clke_b_tmp = clke_b ~^ CLKEB_POLARITY;
	wire w_clke_b;
	assign w_clke_b = w_clke_b_tmp;

    generate
			
		wire [DATA_WIDTH_A-1:0 ] rMux_a [get_max_mux_row_A(0):0]; 
		
		if (rMux_mapping_A_size == 0) 
        	begin : g1_if_rmux_mapping_a_size0_1
			if(WRITE_MODE_A == "NO_CHANGE")
			begin : g1_if_write_mode_ano_change_1
				wire w_read_hold_a = (we_a == WEA_POLARITY);
				reg r_read_hold_a_1P = 1'b0;
				reg [DATA_WIDTH_A-1:0 ] r_rMux_hold_a ;
				
				if (OUTPUT_REG_A == 0)
				begin : g1_if_output_reg_a0_1
				
					if (FAMILY == "TRION")
					begin : g1_if_familytrion_1
						always @ (posedge clk_a_i)
						begin
							if(!r_read_hold_a_1P)
								r_rMux_hold_a <= rMux_a[0];
							
							if (w_clke_a)
								r_read_hold_a_1P <= w_read_hold_a;
						end
					end 
					else 
					begin : g1_else_1
						always @ (posedge clk_a_i or posedge ram_async_rsta)
						begin
							if (ram_async_rsta)
							begin : g1_if_ram_async_rsta_1
								r_rMux_hold_a <= {DATA_WIDTH_A{1'b0}};
								r_read_hold_a_1P  <= 1'b0;
							end 
							else 
							begin : g1_else_2
								if(ram_sync_rsta)
								begin : g1_if_ram_sync_rsta_1
									r_rMux_hold_a <= {DATA_WIDTH_A{1'b0}};
									r_read_hold_a_1P  <= 1'b0;
								end 
								else 
								begin : g1_else_3
									if(!r_read_hold_a_1P)
										r_rMux_hold_a <= rMux_a[0];
									
									if (w_clke_a)
										r_read_hold_a_1P <= w_read_hold_a;
										
								end 
							end 
						end
			
					end 
					assign w_rdata_map_a = (r_read_hold_a_1P) ?  r_rMux_hold_a : rMux_a[0];
				
				
				end
				else
				begin : g1_else_4
					reg r_read_hold_a_2P = 1'b0;
					
					if (FAMILY == "TRION")
					begin : g1_if_familytrion_2
					
						always @ (posedge clk_a_i)
						begin
							if(!r_read_hold_a_2P)
								r_rMux_hold_a <= rMux_a[0];
							
							if (w_clke_a)
							begin : g1_if_w_clke_a_1
								r_read_hold_a_1P <= w_read_hold_a;
							end
							
							if ((FAMILY == "TITANIUM" && w_clke_a) || (FAMILY == "TRION"))
							begin : g1_if_familytitaniumw_clke_afamilytrion_1
								r_read_hold_a_2P <= r_read_hold_a_1P;
							end
						end
						assign w_rdata_map_a = (r_read_hold_a_2P) ?  r_rMux_hold_a : rMux_a[0];
					end 
					else 
					begin : g1_else_5
						reg [DATA_WIDTH_A-1:0 ] r_rMux_hold_a_1P ;
						always @ (posedge clk_a_i or posedge ram_async_rsta)
						begin
							if (ram_async_rsta)
							begin : g1_if_ram_async_rsta_2
								r_rMux_hold_a <= {DATA_WIDTH_A{1'b0}};
								r_read_hold_a_1P <= 1'b0;
								r_read_hold_a_2P <= 1'b0;
							end 
							else 
							begin : g1_else_6
								if(ram_sync_rsta)
								begin : g1_if_ram_sync_rsta_2
									r_rMux_hold_a <= {DATA_WIDTH_A{1'b0}};
									r_read_hold_a_1P <= 1'b0;
									r_read_hold_a_2P <= 1'b0;
								end 
								else 
								begin : g1_else_7
									if(!r_read_hold_a_2P)
										r_rMux_hold_a <= rMux_a[0];
									
									if (w_clke_a)
									begin : g1_if_w_clke_a_2
										r_read_hold_a_1P <= w_read_hold_a;
										r_read_hold_a_2P <= r_read_hold_a_1P;

									end 	
								end 
							end 
						end
						always @ (posedge clk_a_i or posedge outreg_async_rsta)
						begin
							if (outreg_async_rsta)
							begin : g1_if_outreg_async_rsta_1
								r_rMux_hold_a_1P <= {DATA_WIDTH_A{1'b0}};
							end
							else 
							begin : g1_else_8
								if (w_clke_a)
									r_rMux_hold_a_1P <= r_rMux_hold_a;
							
							end 
						end 
						
						assign w_rdata_map_a = (r_read_hold_a_2P) ?  r_rMux_hold_a : rMux_a[0];
					
					
					end
					
					
					
				end
			end 
			else 
			begin : g1_else_9
				assign w_rdata_map_a = rMux_a[0];
			end 
        end 
        else 
        begin : g1_else_10
		
            for (gen_y=0; gen_y<rMux_mapping_A_size; gen_y =gen_y +1)
            begin:rDataMux_a
                localparam ADDR_START = rMux_mapping_table_A(gen_y,1);
                localparam ADDR_END   = rMux_mapping_table_A(gen_y,0);
                
                localparam DATA_START = rMux_mapping_table_A(gen_y,3);
                localparam DATA_END   = rMux_mapping_table_A(gen_y,2);
				
				localparam BYPRASSED  = rMux_mapping_table_A(gen_y,6);
								
                if( BYPRASSED == 0 )
				begin : g1_if_byprassed0_1
				
					wire [ADDR_END:ADDR_START] rdSel;
					assign rdSel[ADDR_END:ADDR_START] = w_addr_map_a[ADDR_END:ADDR_START];
					reg [ADDR_END:ADDR_START] r_rdSel_1P;
					wire w_addren_a = FAMILY == "TRION" ? 1'b1 : addren_a ~^ ADDRENA_POLARITY;
					reg [DATA_END:DATA_START] r_rMux_hold_a ;
					
					
					if(WRITE_MODE_A == "NO_CHANGE")
					begin : g1_if_write_mode_ano_change_2
						//Hold Address for read if WE and No-Change Mode. 
						wire w_read_hold_a = (we_a == WEA_POLARITY);  
						reg r_read_hold_a_1P;
						
						
						always @ (posedge clk_a_i)
						begin
							if(w_clke_a & w_addren_a) 
								r_rdSel_1P <= rdSel;
						end
						
						if (OUTPUT_REG_A == 0)
						begin : g1_if_output_reg_a0_2
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_3
								always @ (posedge clk_a_i)
								begin
									if(!r_read_hold_a_1P)
										r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[r_rdSel_1P][DATA_END:DATA_START];
							
									if (w_clke_a)
										r_read_hold_a_1P <= w_read_hold_a;
								end
							end 
							else 
							begin : g1_else_11
								always @ (posedge clk_a_i or posedge ram_async_rsta)
								begin
									if (ram_async_rsta)
									begin : g1_if_ram_async_rsta_3
										r_rMux_hold_a <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_a_1P  <= 1'b0;
									end 
									else 
									begin : g1_else_12
										if(ram_sync_rsta)
										begin : g1_if_ram_sync_rsta_3
											r_rMux_hold_a <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_a_1P  <= 1'b0;
										end 
										else 
										begin : g1_else_13
											if(!r_read_hold_a_1P)
												r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[r_rdSel_1P][DATA_END:DATA_START];
											
											if (w_clke_a)
												r_read_hold_a_1P <= w_read_hold_a;
												
										end 
									end 
								end
							end 
							
							assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_1P) ?  r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[r_rdSel_1P][DATA_END:DATA_START];
						end
						else
						begin : g1_else_14
							//reg [ADDR_END:ADDR_START] r_rdSel_2P = {(ADDR_END-ADDR_START+1){1'b0}};
							reg [ADDR_END:ADDR_START] r_rdSel_2P;
							reg r_read_hold_a_2P;
							always @ (posedge clk_a_i)
							begin
							if ((FAMILY == "TITANIUM" && w_clke_a) || (FAMILY == "TRION"))
								r_rdSel_2P <= r_rdSel_1P;
							end
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_4
								always @ (posedge clk_a_i)
								begin
									if(!r_read_hold_a_2P )
										r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[r_rdSel_2P][DATA_END:DATA_START];
									
									if (w_clke_a)
									begin : g1_if_w_clke_a_3
										r_read_hold_a_1P <= w_read_hold_a;
									end
									
									if ((FAMILY == "TITANIUM" && w_clke_a) || (FAMILY == "TRION"))
									begin : g1_if_familytitaniumw_clke_afamilytrion_2
										r_read_hold_a_2P <= r_read_hold_a_1P;
									end
									
								end
								assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_2P) ? r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[r_rdSel_2P][DATA_END:DATA_START];

							end 
							else //TITANIUM
							begin : g1_else_15
								reg [DATA_END:DATA_START ] r_rMux_hold_a_1P ;
								always @ (posedge clk_a_i or posedge ram_async_rsta)
								begin
									if (ram_async_rsta)
									begin : g1_if_ram_async_rsta_4
										r_rMux_hold_a[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_a_1P <= 1'b0;
										r_read_hold_a_2P <= 1'b0;
									end 
									else 
									begin : g1_else_16
										if(ram_sync_rsta)
										begin : g1_if_ram_sync_rsta_4
											r_rMux_hold_a[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_a_1P <= 1'b0;
											r_read_hold_a_2P <= 1'b0;
										end 
										else 
										begin : g1_else_17
											if(!r_read_hold_a_2P)
												r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[r_rdSel_2P][DATA_END:DATA_START];
											
											if (w_clke_a)
											begin : g1_if_w_clke_a_4
												r_read_hold_a_1P <= w_read_hold_a;
												r_read_hold_a_2P <= r_read_hold_a_1P;
		
											end 	
										end 
									end 
								end
								always @ (posedge clk_a_i or posedge outreg_async_rsta)
								begin
									if (outreg_async_rsta)
									begin : g1_if_outreg_async_rsta_2
										r_rMux_hold_a_1P[DATA_END:DATA_START]  <= {(DATA_END-DATA_START+1){1'b0}};
									end
									else 
									begin : g1_else_18
										if (w_clke_a)
											r_rMux_hold_a_1P[DATA_END:DATA_START]  <= r_rMux_hold_a[DATA_END:DATA_START];
									
									end 
								end 
								
								assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_2P) ? r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[r_rdSel_2P][DATA_END:DATA_START];
					
							end 
						end 
					end 
					else 
					begin : g1_else_19
						always @ (posedge clk_a_i)
						begin
							if(w_clke_a & w_addren_a) 
								r_rdSel_1P <= rdSel;
						end
						
						if (OUTPUT_REG_A == 0)
						begin : g1_if_output_reg_a0_3
						
							assign w_rdata_map_a[DATA_END:DATA_START] = rMux_a[r_rdSel_1P][DATA_END:DATA_START];
						end
						else
						begin : g1_else_20
							reg [ADDR_END:ADDR_START] r_rdSel_2P = {(ADDR_END-ADDR_START+1){1'b0}};
							always @ (posedge clk_a_i)
							begin
								if ((FAMILY == "TITANIUM" && w_clke_a) || (FAMILY == "TRION"))
								r_rdSel_2P <= r_rdSel_1P;
							end
								assign w_rdata_map_a[DATA_END:DATA_START] = rMux_a[r_rdSel_2P][DATA_END:DATA_START];
						end 
					end 
					
                
				end 
				else 
				begin : g1_else_21
	
					if(WRITE_MODE_A == "NO_CHANGE")
					begin : g1_if_write_mode_ano_change_3
						wire w_read_hold_a = (we_a == WEA_POLARITY);
						reg r_read_hold_a_1P = 1'b0;
						reg [DATA_END:DATA_START] r_rMux_hold_a ;
						
						if (OUTPUT_REG_A == 0)
						begin : g1_if_output_reg_a0_4
						
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_5
								always @ (posedge clk_a_i)
								begin
									if(!r_read_hold_a_1P)
										r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[0][DATA_END:DATA_START];
									
									if (w_clke_a)
										r_read_hold_a_1P <= w_read_hold_a;
								end
							end 
							else 
							begin : g1_else_22
								always @ (posedge clk_a_i or posedge ram_async_rsta)
								begin
									if (ram_async_rsta)
									begin : g1_if_ram_async_rsta_5
										r_rMux_hold_a <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_a_1P  <= 1'b0;
									end 
									else 
									begin : g1_else_23
										if(ram_sync_rsta)
										begin : g1_if_ram_sync_rsta_5
											r_rMux_hold_a <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_a_1P  <= 1'b0;
										end 
										else 
										begin : g1_else_24
											if(!r_read_hold_a_1P)
												r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[0][DATA_END:DATA_START];
											
											if (w_clke_a)
												r_read_hold_a_1P <= w_read_hold_a;
												
										end 
									end 
								end
							end 
							
							assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_1P) ?  r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[0][DATA_END:DATA_START];
						end
						else
						begin : g1_else_25
							reg r_read_hold_a_2P = 1'b0;
							
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_6
								always @ (posedge clk_a_i)
								begin
									if(!r_read_hold_a_2P)
										r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[0][DATA_END:DATA_START];
									
									if (w_clke_a)
									begin : g1_if_w_clke_a_5
										r_read_hold_a_1P <= w_read_hold_a;
									end
									
									if ((FAMILY == "TITANIUM" && w_clke_a) || (FAMILY == "TRION"))
									begin : g1_if_familytitaniumw_clke_afamilytrion_3
										r_read_hold_a_2P <= r_read_hold_a_1P;
									end
								end
								assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_2P) ?  r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[0][DATA_END:DATA_START];
							end 
							else 
							begin : g1_else_26
								reg [DATA_END:DATA_START ] r_rMux_hold_a_1P ;
								always @ (posedge clk_a_i or posedge ram_async_rsta)
								begin
									if (ram_async_rsta)
									begin : g1_if_ram_async_rsta_6
										r_rMux_hold_a[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_a_1P <= 1'b0;
										r_read_hold_a_2P <= 1'b0;
									end 
									else 
									begin : g1_else_27
										if(ram_sync_rsta)
										begin : g1_if_ram_sync_rsta_6
											r_rMux_hold_a[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_a_1P <= 1'b0;
											r_read_hold_a_2P <= 1'b0;
										end 
										else 
										begin : g1_else_28
											if(!r_read_hold_a_2P)
												r_rMux_hold_a[DATA_END:DATA_START] <= rMux_a[0][DATA_END:DATA_START];
											
											if (w_clke_a)
											begin : g1_if_w_clke_a_6
												r_read_hold_a_1P <= w_read_hold_a;
												r_read_hold_a_2P <= r_read_hold_a_1P;
		
											end 	
										end 
									end 
								end
								always @ (posedge clk_a_i or posedge outreg_async_rsta)
								begin
									if (outreg_async_rsta)
									begin : g1_if_outreg_async_rsta_3
										r_rMux_hold_a_1P[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
									end
									else 
									begin : g1_else_29
										if (w_clke_a)
											r_rMux_hold_a_1P[DATA_END:DATA_START] <= r_rMux_hold_a[DATA_END:DATA_START];
									
									end 
								end 

								assign w_rdata_map_a[DATA_END:DATA_START] = (r_read_hold_a_2P) ?  r_rMux_hold_a[DATA_END:DATA_START] : rMux_a[0][DATA_END:DATA_START];
							
							end 
						end
					end 
					else 
					begin : g1_else_30
						assign w_rdata_map_a[DATA_END:DATA_START] = rMux_a[0][DATA_END:DATA_START];
					end 
			
			


	
				end 
				
            end
        end

		wire [DATA_WIDTH_B-1:0 ] rMux_b [get_max_mux_row_B(0):0]; 
		if (rMux_mapping_B_size == 0) 
        	begin : g1_if_rmux_mapping_b_size0_1
			if(WRITE_MODE_B == "NO_CHANGE")
			begin : g1_if_write_mode_bno_change_1
				wire w_read_hold_b = (we_b == WEB_POLARITY);
				reg r_read_hold_b_1P = 1'b0;
				reg [DATA_WIDTH_B-1:0 ] r_rMux_hold_b ;
				
				if (OUTPUT_REG_B == 0)
				begin : g1_if_output_reg_b0_1
				
					if (FAMILY == "TRION")
					begin : g1_if_familytrion_7
						always @ (posedge clk_b_i)
						begin
							if(!r_read_hold_b_1P)
								r_rMux_hold_b <= rMux_b[0];
							
							if (w_clke_b)
								r_read_hold_b_1P <= w_read_hold_b;
						end
					
					end 
					else 
					begin : g1_else_31
						always @ (posedge clk_b_i or posedge ram_async_rstb)
						begin
							if (ram_async_rstb)
							begin : g1_if_ram_async_rstb_1
								r_rMux_hold_b <= {DATA_WIDTH_B{1'b0}};
								r_read_hold_b_1P  <= 1'b0;
							end 
							else 
							begin : g1_else_32
								if(ram_sync_rstb)
								begin : g1_if_ram_sync_rstb_1
									r_rMux_hold_b <= {DATA_WIDTH_B{1'b0}};
									r_read_hold_b_1P  <= 1'b0;
								end 
								else 
								begin : g1_else_33
									if(!r_read_hold_b_1P)
										r_rMux_hold_b <= rMux_b[0];
									
									if (w_clke_b)
										r_read_hold_b_1P <= w_read_hold_b;
										
								end 
							end 
						end
					
					
					end 
					assign w_rdata_map_b = (r_read_hold_b_1P) ?  r_rMux_hold_b : rMux_b[0];
				end
				else
				begin : g1_else_34
					reg r_read_hold_b_2P = 1'b0;
					if (FAMILY == "TRION")
					begin : g1_if_familytrion_8
						always @ (posedge clk_b_i)
						begin
							if(!r_read_hold_b_2P)
								r_rMux_hold_b <= rMux_b[0];
							
							if (w_clke_b)
							begin : g1_if_w_clke_b_1
								r_read_hold_b_1P <= w_read_hold_b;
							end
							
							if ((FAMILY == "TITANIUM" && w_clke_b) || (FAMILY == "TRION"))
							begin : g1_if_familytitaniumw_clke_bfamilytrion_1
								r_read_hold_b_2P <= r_read_hold_b_1P;
							end
							
						end
						assign w_rdata_map_b = (r_read_hold_b_2P) ?  r_rMux_hold_b : rMux_b[0];
					end 
					else 
					begin : g1_else_35
						reg [DATA_WIDTH_B-1:0 ] r_rMux_hold_b_1P ;
						always @ (posedge clk_b_i or posedge ram_async_rstb)
						begin
							if (ram_async_rstb)
							begin : g1_if_ram_async_rstb_2
								r_rMux_hold_b <= {DATA_WIDTH_B{1'b0}};
								r_read_hold_b_1P <= 1'b0;
								r_read_hold_b_2P <= 1'b0;
							end 
							else 
							begin : g1_else_36
								if(ram_sync_rstb)
								begin : g1_if_ram_sync_rstb_2
									r_rMux_hold_b <= {DATA_WIDTH_B{1'b0}};
									r_read_hold_b_1P <= 1'b0;
									r_read_hold_b_2P <= 1'b0;
								end 
								else 
								begin : g1_else_37
									if(!r_read_hold_b_2P)
										r_rMux_hold_b <= rMux_b[0];
									
									if (w_clke_b)
									begin : g1_if_w_clke_b_2
										r_read_hold_b_1P <= w_read_hold_b;
										r_read_hold_b_2P <= r_read_hold_b_1P;

									end 	
								end 
							end 
						end
						always @ (posedge clk_b_i or posedge outreg_async_rstb)
						begin
							if (outreg_async_rstb)
							begin : g1_if_outreg_async_rstb_1
								r_rMux_hold_b_1P <= {DATA_WIDTH_B{1'b0}};
							end
							else 
							begin : g1_else_38
								if(w_clke_b)
									r_rMux_hold_b_1P <= r_rMux_hold_b;
							
							end 
						end 
						
						assign w_rdata_map_b = (r_read_hold_b_2P) ?  r_rMux_hold_b : rMux_b[0];		
					end 
				end
			end 
			else 
			begin : g1_else_39
				assign w_rdata_map_b = rMux_b[0];
			end	
        end 
        else 
        begin : g1_else_40
			
            for (gen_y=0; gen_y<rMux_mapping_B_size; gen_y =gen_y +1)
            begin:rDataMux_b
                localparam ADDR_START = rMux_mapping_table_B(gen_y,1);
                localparam ADDR_END   = rMux_mapping_table_B(gen_y,0);
                
                localparam DATA_START = rMux_mapping_table_B(gen_y,3);
                localparam DATA_END   = rMux_mapping_table_B(gen_y,2);
				
				localparam BYPRASSED  = rMux_mapping_table_B(gen_y,6);
                
				if( BYPRASSED == 0 )
				begin : g1_if_byprassed0_2
				
				
				
					wire [ADDR_END:ADDR_START] rdSel;
				        assign rdSel[ADDR_END:ADDR_START] = w_addr_map_b[ADDR_END:ADDR_START];
					reg [ADDR_END:ADDR_START] r_rdSel_1P;
					wire w_addren_b = FAMILY == "TRION" ? 1'b1 : addren_b ~^ ADDRENB_POLARITY; 
					reg [DATA_END:DATA_START] r_rMux_hold_b;

					if(WRITE_MODE_B == "NO_CHANGE")
					begin : g1_if_write_mode_bno_change_2
					
					//Hold Address for read if WE and No-Change Mode. 
						wire w_read_hold_b = (we_b == WEB_POLARITY);  
						reg r_read_hold_b_1P;
					
						always @ (posedge clk_b_i)
						begin
							if(w_clke_b & w_addren_b) 
								r_rdSel_1P <= rdSel;
						end
						
						if (OUTPUT_REG_B == 0)
						begin : g1_if_output_reg_b0_2
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_9
								always @ (posedge clk_b_i)
								begin
									if(!r_read_hold_b_1P)
										r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[r_rdSel_1P][DATA_END:DATA_START];
									if(w_clke_b)
										r_read_hold_b_1P <= w_read_hold_b;
								end
							end 
							begin//TITANIUM
								always @ (posedge clk_b_i or posedge ram_async_rstb)
								begin
									if (ram_async_rstb)
									begin : g1_if_ram_async_rstb_3
										r_rMux_hold_b <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_b_1P  <= 1'b0;
									end 
									else 
									begin : g1_else_41
										if(ram_sync_rstb)
										begin : g1_if_ram_sync_rstb_3
											r_rMux_hold_b <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_b_1P  <= 1'b0;
										end 
										else 
										begin : g1_else_42
											if(!r_read_hold_b_1P)
												r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[r_rdSel_1P][DATA_END:DATA_START];
											
											if (w_clke_b)
												r_read_hold_b_1P <= w_read_hold_b;
												
										end 
									end 
								end
							
							end 
							assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_1P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[r_rdSel_1P][DATA_END:DATA_START];
						end 
						else
						begin : g1_else_43
							reg [ADDR_END:ADDR_START] r_rdSel_2P;
							reg r_read_hold_b_2P;
							always @ (posedge clk_b_i)
							begin
								if ((FAMILY == "TITANIUM" && w_clke_b) || (FAMILY == "TRION"))
								r_rdSel_2P <= r_rdSel_1P;
							end
							
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_10
								always @ (posedge clk_b_i)
								begin
									if(!r_read_hold_b_2P)
										r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[r_rdSel_2P][DATA_END:DATA_START];
									if(w_clke_b)
									begin : g1_if_w_clke_b_3
										r_read_hold_b_1P <= w_read_hold_b;
		
									end
									
									if ((FAMILY == "TITANIUM" && w_clke_b) || (FAMILY == "TRION"))
									begin : g1_if_familytitaniumw_clke_bfamilytrion_2
										r_read_hold_b_2P <= r_read_hold_b_1P;
									end
									
								end
								
								assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_2P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[r_rdSel_2P][DATA_END:DATA_START];
							end 
							else 
							begin : g1_else_44
								reg [DATA_END:DATA_START ] r_rMux_hold_b_1P ;
								always @ (posedge clk_b_i or posedge ram_async_rstb)
								begin
									if (ram_async_rstb)
									begin : g1_if_ram_async_rstb_4
										r_rMux_hold_b[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_b_1P <= 1'b0;
										r_read_hold_b_2P <= 1'b0;
									end 
									else 
									begin : g1_else_45
										if(ram_sync_rstb)
										begin : g1_if_ram_sync_rstb_4
											r_rMux_hold_b[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_b_1P <= 1'b0;
											r_read_hold_b_2P <= 1'b0;
										end 
										else 
										begin : g1_else_46
											if(!r_read_hold_b_2P)
												r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[r_rdSel_2P][DATA_END:DATA_START];
											
											if (w_clke_b)
											begin : g1_if_w_clke_b_4
												r_read_hold_b_1P <= w_read_hold_b;
												r_read_hold_b_2P <= r_read_hold_b_1P;
		
											end 	
										end 
									end 
								end
								always @ (posedge clk_b_i or posedge outreg_async_rstb)
								begin
									if (outreg_async_rstb)
									begin : g1_if_outreg_async_rstb_2
										r_rMux_hold_b_1P[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
									end
									else 
									begin : g1_else_47
										if(w_clke_b)
											r_rMux_hold_b_1P[DATA_END:DATA_START] <= r_rMux_hold_b[DATA_END:DATA_START];
									
									end 
								end 

								assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_2P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[r_rdSel_2P][DATA_END:DATA_START];

							end 
						end 
					end 
					else 
					begin : g1_else_48
					
						always @ (posedge clk_b_i)
						begin
							if(w_clke_b & w_addren_b) 
								r_rdSel_1P <= rdSel;
						end
						
						if (OUTPUT_REG_B == 0)
						begin : g1_if_output_reg_b0_3
							assign w_rdata_map_b[DATA_END:DATA_START] = rMux_b[r_rdSel_1P][DATA_END:DATA_START];
						end 
						else
						begin : g1_else_49
							reg [ADDR_END:ADDR_START] r_rdSel_2P = {(ADDR_END-ADDR_START+1){1'b0}};
							always @ (posedge clk_b_i)
							begin
								if ((FAMILY == "TITANIUM" && w_clke_b) || (FAMILY == "TRION"))
								r_rdSel_2P <= r_rdSel_1P;
							end
								assign w_rdata_map_b[DATA_END:DATA_START] = rMux_b[r_rdSel_2P][DATA_END:DATA_START];
						end 
					
					end 
					
					
                end 
				else 
				begin : g1_else_50
					if(WRITE_MODE_B == "NO_CHANGE")
					begin : g1_if_write_mode_bno_change_3
						wire w_read_hold_b = (we_b == WEB_POLARITY);
						reg r_read_hold_b_1P = 1'b0;
						reg [DATA_END:DATA_START] r_rMux_hold_b ;
						
						if (OUTPUT_REG_B == 0)
						begin : g1_if_output_reg_b0_4
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_11
								always @ (posedge clk_b_i)
								begin
									if(!r_read_hold_b_1P)
										r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[0][DATA_END:DATA_START];
									
									if (w_clke_b)
										r_read_hold_b_1P <= w_read_hold_b;
								end
							end 
							else 
							begin : g1_else_51
								always @ (posedge clk_b_i or posedge ram_async_rstb)
								begin
									if (ram_async_rstb)
									begin : g1_if_ram_async_rstb_5
										r_rMux_hold_b <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_b_1P  <= 1'b0;
									end 
									else 
									begin : g1_else_52
										if(ram_sync_rstb)
										begin : g1_if_ram_sync_rstb_5
											r_rMux_hold_b <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_b_1P  <= 1'b0;
										end 
										else 
										begin : g1_else_53
											if(!r_read_hold_b_1P)
												r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[0][DATA_END:DATA_START];
											
											if (w_clke_b)
												r_read_hold_b_1P <= w_read_hold_b;
												
										end 
									end 
								end
							
							end 
							assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_1P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[0][DATA_END:DATA_START];
						end
						else
						begin : g1_else_54
							reg r_read_hold_b_2P = 1'b0;
							if (FAMILY == "TRION")
							begin : g1_if_familytrion_12
								always @ (posedge clk_b_i)
								begin
									if(!r_read_hold_b_2P)
										r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[0][DATA_END:DATA_START];
									
									if (w_clke_b)
									begin : g1_if_w_clke_b_5
										r_read_hold_b_1P <= w_read_hold_b;
									end
									
									if ((FAMILY == "TITANIUM" && w_clke_b) || (FAMILY == "TRION"))
									begin : g1_if_familytitaniumw_clke_bfamilytrion_3
										r_read_hold_b_2P <= r_read_hold_b_1P;
									end
									
								end
								assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_2P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[0][DATA_END:DATA_START];
							end 
							else 
							begin : g1_else_55
								reg [DATA_END:DATA_START ] r_rMux_hold_b_1P ;
								always @ (posedge clk_b_i or posedge ram_async_rstb)
								begin
									if (ram_async_rstb)
									begin : g1_if_ram_async_rstb_6
										r_rMux_hold_b[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
										r_read_hold_b_1P <= 1'b0;
										r_read_hold_b_2P <= 1'b0;
									end 
									else 
									begin : g1_else_56
										if(ram_sync_rstb)
										begin : g1_if_ram_sync_rstb_6
											r_rMux_hold_b[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
											r_read_hold_b_1P <= 1'b0;
											r_read_hold_b_2P <= 1'b0;
										end 
										else 
										begin : g1_else_57
											if(!r_read_hold_b_2P)
												r_rMux_hold_b[DATA_END:DATA_START] <= rMux_b[0][DATA_END:DATA_START];
											
											if (w_clke_b)
											begin : g1_if_w_clke_b_6
												r_read_hold_b_1P <= w_read_hold_b;
												r_read_hold_b_2P <= r_read_hold_b_1P;
		
											end 	
										end 
									end 
								end
								always @ (posedge clk_b_i or posedge outreg_async_rstb)
								begin
									if (outreg_async_rstb)
									begin : g1_if_outreg_async_rstb_3
										r_rMux_hold_b_1P[DATA_END:DATA_START] <= {(DATA_END-DATA_START+1){1'b0}};
									end
									else 
									begin : g1_else_58
										r_rMux_hold_b_1P[DATA_END:DATA_START] <= r_rMux_hold_b[DATA_END:DATA_START];
									
									end 
								end 

								assign w_rdata_map_b[DATA_END:DATA_START] = (r_read_hold_b_2P) ?  r_rMux_hold_b[DATA_END:DATA_START] : rMux_b[0][DATA_END:DATA_START];
							
							
							
							end 
						
						end
					end 
					else 
					begin : g1_else_59
						assign w_rdata_map_b[DATA_END:DATA_START] = rMux_b[0][DATA_END:DATA_START];
					end	
				
				end 
            end
        end
		
        
		wire [get_max_wen_decode_A(0):0] wen_decode_a ;
        if (wen_sel_mapping_A_size!=0)
        begin : g1_if_wen_sel_mapping_a_size0_1
			for (gen_y=0; gen_y<wen_sel_mapping_A_size; gen_y =gen_y +1)
			begin:wDataEn_A
				localparam ADDR_START = wen_sel_mapping_table_A(gen_y,1);
				localparam ADDR_END   = wen_sel_mapping_table_A(gen_y,0);
				
				localparam SEL_START = wen_sel_mapping_table_A(gen_y,3);
				localparam SEL_END   = wen_sel_mapping_table_A(gen_y,2);
				
				localparam BYPRASSED  = wen_sel_mapping_table_A(gen_y,4);
				
				if( BYPRASSED == 0 )
				begin : g1_if_byprassed0_3
					wire [ADDR_END:ADDR_START] wrSel;
					reg [ADDR_END:ADDR_START]  r_wrSel;

					wire w_addren_a = FAMILY =="TRION" ? 1'b1 : addren_a ~^ ADDRENA_POLARITY; 
					wire w_wrSel_mux = w_clke_a && w_addren_a;
					
					always @ (posedge clk_a_i)
					begin
						if(w_clke_a & w_addren_a) 
							r_wrSel <= w_addr_map_a[ADDR_END:ADDR_START];
					end
				
					assign wrSel = (w_wrSel_mux==1'b1) ? w_addr_map_a[ADDR_END:ADDR_START]: r_wrSel;
					


					for (gen_x=SEL_START; gen_x<(SEL_END+1); gen_x = gen_x +1)
					begin : g1_for_gen_x_1
						assign wen_decode_a[gen_x] = (wrSel==(gen_x-SEL_START))?1'b1:1'b0;
					end 
				end 
				else 
				begin : g1_else_60
										
					for (gen_x=SEL_START; gen_x<(SEL_END+1); gen_x = gen_x +1)
					begin : g1_for_gen_x_2
						assign wen_decode_a[gen_x] = 1'b1;
					end 
				
				end 
				
			end
		end 
		else 
		begin : g1_else_61
			assign wen_decode_a = {(get_max_wen_decode_A(0)+1){1'b1}};
		end 
		
        
        wire [get_max_wen_decode_B(0):0] wen_decode_b ;
        if (wen_sel_mapping_B_size!=0)
        begin : g1_if_wen_sel_mapping_b_size0_1
			for (gen_y=0; gen_y<wen_sel_mapping_B_size; gen_y =gen_y +1)
			begin:wDataEn_B
				localparam ADDR_START = wen_sel_mapping_table_B(gen_y,1);
				localparam ADDR_END   = wen_sel_mapping_table_B(gen_y,0);
				
				localparam SEL_START = wen_sel_mapping_table_B(gen_y,3);
				localparam SEL_END   = wen_sel_mapping_table_B(gen_y,2);
				
				localparam BYPRASSED  = wen_sel_mapping_table_B(gen_y,4);
				
				
				if( BYPRASSED == 0 )
				begin : g1_if_byprassed0_4
					wire [ADDR_END:ADDR_START] wrSel;
					reg [ADDR_END:ADDR_START]  r_wrSel;
					wire w_addren_b = FAMILY == "TRION" ? 1'b1 : addren_b ~^ ADDRENB_POLARITY; 
					wire w_wrSel_mux = w_clke_b && w_addren_b;
					
					always @ (posedge clk_b_i)
					begin
						if(w_clke_b & w_addren_b) 
							r_wrSel <= w_addr_map_b[ADDR_END:ADDR_START];
					end
				
					assign wrSel = (w_wrSel_mux==1'b1) ? w_addr_map_b[ADDR_END:ADDR_START]: r_wrSel;
					
					
					for (gen_x=SEL_START; gen_x<(SEL_END+1); gen_x = gen_x +1)
					begin : g1_for_gen_x_3
						assign wen_decode_b[gen_x] = (wrSel==(gen_x-SEL_START))?1'b1:1'b0;
					end
				end 
				else 
				begin : g1_else_62
					
					for (gen_x=SEL_START; gen_x<(SEL_END+1); gen_x = gen_x +1)
					begin : g1_for_gen_x_4
						assign wen_decode_b[gen_x] = 1'b1;
					end 
				end 
					
			end
		end 
		else 
		begin : g1_else_63
			assign wen_decode_b = {(get_max_wen_decode_B(0)+1){1'b1}};
		end 
		
		//For Mixed Width Mode 
		if (data_mapping_table_A_size!=0)
        	begin : g1_if_data_mapping_table_a_size0_1
			for (gen_y=0; gen_y<data_mapping_table_A_size; gen_y = gen_y +1)
			begin : g1_for_gen_y_5
				assign w_wdata_map_a[data_mapping_table_A(gen_y)] =  wdata_a[gen_y] ;
				assign rdata_a[gen_y]  = w_rdata_map_a[data_mapping_table_B(gen_y)] ;
			end
		end 
		else 
		begin : g1_else_64
			assign w_wdata_map_a = wdata_a;
			assign rdata_a = w_rdata_map_a;
		end 
	
		if (address_mapping_table_A_size!=0)
        begin : g1_if_address_mapping_table_a_size0_1
			for (gen_y=0; gen_y<address_mapping_table_A_size; gen_y = gen_y +1)
			begin : g1_for_gen_y_6
				if (gen_y < ADDR_WIDTH_A)
					assign w_addr_map_a[address_mapping_table_A(gen_y)] =  addr_a[gen_y] ;
				else 
					assign w_addr_map_a[address_mapping_table_A(gen_y)] = 1'b0;
			end
		end 
		else 
		begin : g1_else_65
			assign w_addr_map_a = addr_a;
		end 
	
	
		if (data_mapping_table_B_size!=0)
        begin : g1_if_data_mapping_table_b_size0_1
			for (gen_y=0; gen_y<data_mapping_table_B_size; gen_y = gen_y +1)
			begin : g1_for_gen_y_7
				assign w_wdata_map_b[data_mapping_table_A(gen_y)] =  wdata_b[gen_y] ;
				assign rdata_b[gen_y]  = w_rdata_map_b[data_mapping_table_B(gen_y)] ;
			end
		end 
		else 
		begin : g1_else_66
			assign w_wdata_map_b = wdata_b;
			assign rdata_b = w_rdata_map_b;
		end 
	
		if (address_mapping_table_B_size!=0)
        begin : g1_if_address_mapping_table_b_size0_1
			for (gen_y=0; gen_y<address_mapping_table_B_size; gen_y = gen_y +1)
			begin : g1_for_gen_y_8
				if(gen_y<ADDR_WIDTH_B)
					assign w_addr_map_b[address_mapping_table_B(gen_y)] =  addr_b[gen_y] ;
				else 
					assign w_addr_map_b[address_mapping_table_B(gen_y)] = 1'b0;
			end 
		end 
		else 
		begin : g1_else_67
			assign w_addr_map_b = addr_b;
		end 
			
			
		if (bram_table_loop_mode == 0 ) 
		begin:scan_column_speed
			for (gen_x=0; gen_x<bram_table_size; gen_x =gen_x +1)
			begin:speed_column
				localparam bram_mode_a = bram_decompose_table(gen_x,0); 
				localparam bram_mode_b = bram_decompose_table(gen_x,1); 
				localparam row_count = bram_decompose_table(gen_x,2);
			
				localparam ADDR_WIDTH_ROW_A  = bram_feature_table(bram_mode_a,0);
				localparam DATA_WIDTH_ROW_A  = bram_feature_table(bram_mode_a,1); 
				localparam WEN_WIDTH_ROW_A   = bram_feature_table(bram_mode_a,2); 
	
				localparam ADDR_WIDTH_ROW_B  = bram_feature_table(bram_mode_b,0);
				localparam DATA_WIDTH_ROW_B  = bram_feature_table(bram_mode_b,1); 
				localparam WEN_WIDTH_ROW_B   = bram_feature_table(bram_mode_b,2); 	
				
				localparam START_COLUMN_INDEX = get_current_column_index(gen_x);
										
				for (gen_y=0; gen_y<row_count; gen_y =gen_y +1)
				begin:speed_row
					
					localparam DATA_MAP_INDEX = START_COLUMN_INDEX+gen_y;

					localparam DATA_END_A     = bram_mapping_table(DATA_MAP_INDEX,2);					
					localparam DATA_START_A   = bram_mapping_table(DATA_MAP_INDEX,3);
					localparam DATA_REPART_A   = bram_mapping_table(DATA_MAP_INDEX,4);
					localparam WRSEL_INDEX_A   = bram_mapping_table(DATA_MAP_INDEX,6);
					localparam BYTEEN_INDEX_A  = bram_mapping_table(DATA_MAP_INDEX,8);
					localparam RMUX_INDEX_A    = bram_mapping_table(DATA_MAP_INDEX,5);
				
				
					localparam DATA_END_B     = bram_mapping_table(DATA_MAP_INDEX,9);					
					localparam DATA_START_B   = bram_mapping_table(DATA_MAP_INDEX,10);
					localparam DATA_REPART_B   = bram_mapping_table(DATA_MAP_INDEX,11);
					localparam WRSEL_INDEX_B   = bram_mapping_table(DATA_MAP_INDEX,13);
					localparam BYTEEN_INDEX_B  = bram_mapping_table(DATA_MAP_INDEX,15);	
					localparam RMUX_INDEX_B    = bram_mapping_table(DATA_MAP_INDEX,12);
						
					wire [ADDR_WIDTH_ROW_A-1:0] w_addr_a;
					wire [DATA_WIDTH_ROW_A-1:0] w_wdata_a;
					wire [DATA_WIDTH_ROW_A-1:0] w_rdata_a;
					wire [WEN_WIDTH_ROW_A-1:0]   w_we_a;

					wire [ADDR_WIDTH_ROW_B-1:0] w_addr_b;
					wire [DATA_WIDTH_ROW_B-1:0] w_wdata_b;
					wire [DATA_WIDTH_ROW_B-1:0] w_rdata_b;
					wire [WEN_WIDTH_ROW_B-1:0]   w_we_b;
					
					//assign w_addr_a[ADDR_WIDTH_ROW_A-1:0] = w_addr_map_a[ADDR_WIDTH_ROW_A-1:0];
					//assign w_addr_b[ADDR_WIDTH_ROW_B-1:0]  = w_addr_map_b[ADDR_WIDTH_ROW_B-1:0];	
					
					
					for(gen_z=0;gen_z<ADDR_WIDTH_ROW_A; gen_z=gen_z+1)
					begin : g1_for_gen_z_1
						if(gen_z< ADDR_WIDTH_A) 
							assign w_addr_a[gen_z] = w_addr_map_a[gen_z];
						else
							assign w_addr_a[gen_z] = 1'b0;
					end
					
					for(gen_z=0;gen_z<ADDR_WIDTH_ROW_B; gen_z=gen_z+1)
					begin : g1_for_gen_z_2
						if(gen_z< ADDR_WIDTH_B) 
							assign w_addr_b[gen_z] = w_addr_map_b[gen_z];
						else
							assign w_addr_b[gen_z] = 1'b0;			
					
					end
					
					
					if (DATA_REPART_A == 0)
					begin : g1_if_data_repart_a0_1
						assign w_wdata_a[DATA_WIDTH_ROW_A-1:0] = w_wdata_map_a[DATA_END_A:DATA_START_A];
						assign rMux_a[RMUX_INDEX_A][DATA_END_A:DATA_START_A]   = w_rdata_a[DATA_WIDTH_ROW_A-1:0]; 
					end
					else 
					begin : g1_else_68
						//for Mixed Width Mode 
						for (gen_z=0; gen_z<DATA_REPART_A; gen_z = gen_z+1)
						begin : g1_for_gen_z_3
							localparam MIXED_DATA_START =  DATA_START_A + gen_z*row_count* (DATA_END_B-DATA_START_B+1); //DATA_WIDTH_ROW_B;
							localparam MIXED_DATA_END   =  DATA_END_A   + gen_z*row_count* (DATA_END_B-DATA_START_B+1); //DATA_WIDTH_ROW_B; 
							
							localparam MAPPED_DATA_START =  DATA_WIDTH_ROW_B* gen_z;
							localparam MAPPED_DATA_END   =  DATA_WIDTH_ROW_B*(gen_z+1) -1; 
							
							assign w_wdata_a[MAPPED_DATA_END: MAPPED_DATA_START]  =  w_wdata_map_a[MIXED_DATA_END:MIXED_DATA_START];
							assign rMux_a[RMUX_INDEX_A][MIXED_DATA_END:MIXED_DATA_START]   = w_rdata_a[MAPPED_DATA_END:MAPPED_DATA_START]; 
						end
					end 
	
					if (DATA_REPART_B == 0)
					begin : g1_if_data_repart_b0_1
						assign w_wdata_b[DATA_WIDTH_ROW_B-1:0] = w_wdata_map_b[DATA_END_B:DATA_START_B];
						assign rMux_b[RMUX_INDEX_B][DATA_END_B:DATA_START_B]   = w_rdata_b[DATA_WIDTH_ROW_B-1:0]; 
					end
					else 
					begin : g1_else_69
						//for Mixed Width Mode 
						for (gen_z=0; gen_z<DATA_REPART_B; gen_z = gen_z+1)
						begin : g1_for_gen_z_4
							localparam MIXED_DATA_START =  DATA_START_B + gen_z*row_count*(DATA_END_A-DATA_START_A+1);//DATA_WIDTH_ROW_A;
							localparam MIXED_DATA_END   =  DATA_END_B   + gen_z*row_count*(DATA_END_A-DATA_START_A+1);//DATA_WIDTH_ROW_A; 
							
							localparam MAPPED_DATA_START =  DATA_WIDTH_ROW_A* gen_z;
							localparam MAPPED_DATA_END   =  DATA_WIDTH_ROW_A*(gen_z+1) -1; 
							
							assign w_wdata_b[MAPPED_DATA_END: MAPPED_DATA_START]  =  w_wdata_map_b[MIXED_DATA_END:MIXED_DATA_START];
							assign rMux_b[RMUX_INDEX_B][MIXED_DATA_END:MIXED_DATA_START]   = w_rdata_b[MAPPED_DATA_END:MAPPED_DATA_START]; 
						end
					end 	
							
					assign w_we_a[0] = ( (we_a == WEA_POLARITY) & wen_decode_a[WRSEL_INDEX_A] & (byteen_a[BYTEEN_INDEX_A] == BYTEENA_POLARITY) ) ? WEA_POLARITY: !WEA_POLARITY;
					if ( WEN_WIDTH_ROW_A >1)
					begin : g1_if_wen_width_row_a1_1
						assign w_we_a[1] = ( (we_a == WEA_POLARITY) & wen_decode_a[WRSEL_INDEX_A] & (byteen_a[BYTEEN_INDEX_A] == BYTEENA_POLARITY) ) ? WEA_POLARITY: !WEA_POLARITY;
					end 	

					assign w_we_b[0] = ( (we_b == WEB_POLARITY) & wen_decode_b[WRSEL_INDEX_B] & (byteen_b[BYTEEN_INDEX_B] == BYTEENB_POLARITY) ) ? WEB_POLARITY: !WEB_POLARITY;
					if ( WEN_WIDTH_ROW_B >1)
					begin : g1_if_wen_width_row_b1_1
						assign w_we_b[1] =((we_b == WEB_POLARITY) & wen_decode_b[WRSEL_INDEX_B] & (byteen_b[BYTEEN_INDEX_B] == BYTEENB_POLARITY) )? WEB_POLARITY: !WEB_POLARITY ;
					end 	

					`IP_MODULE_NAME(dpbram_primitive) #(
						.FAMILY(FAMILY),	
	
						//Trion and Titanium parameters 
						.WRITE_WIDTH_A(DATA_WIDTH_ROW_A),
						.READ_WIDTH_A(DATA_WIDTH_ROW_A),
						
						.CLKA_POLARITY(CLKA_POLARITY),  
						.CLKEA_POLARITY(CLKEA_POLARITY), 
						.WEA_POLARITY(WEA_POLARITY),	
						.WRITE_MODE_A(WRITE_MODE_A), 	
						.OUTPUT_REG_A(OUTPUT_REG_A),   
						
						.WRITE_WIDTH_B(DATA_WIDTH_ROW_B),	
						.READ_WIDTH_B(DATA_WIDTH_ROW_B),	
						
						.CLKB_POLARITY(CLKB_POLARITY),  
						.CLKEB_POLARITY(CLKEB_POLARITY), 
						.WEB_POLARITY(WEB_POLARITY),	
						.WRITE_MODE_B(WRITE_MODE_B), 	
						.OUTPUT_REG_B(OUTPUT_REG_B),   

						.ini_index(DATA_MAP_INDEX),
						
						//Titanium extra paramters 
						.RSTA_POLARITY(RSTA_POLARITY), 	
						.RESET_RAM_A(RESET_RAM_A), 	
						.RESET_OUTREG_A(RESET_OUTREG_A), 	
						.ADDRENA_POLARITY(ADDRENA_POLARITY),
						
						.RSTB_POLARITY(RSTB_POLARITY), 	
						.RESET_RAM_B(RESET_RAM_B), 	 	
						.RESET_OUTREG_B(RESET_OUTREG_B), 	
						.ADDRENB_POLARITY(ADDRENB_POLARITY)
						
				
						
					) bram (
					//Trion and Titanium ports
						.CLKA  (clk_a), 		// A-port clk 
						.CLKEA (w_clke_a), 		// A-port clk enable 
						.WEA   (w_we_a), 		// A-port write enable 
						.ADDRA (w_addr_a), 		// A-port address input
						.WDATAA(w_wdata_a), 	// A-port write data input
						.RDATAA(w_rdata_a), 	// A-port read address output
						
						.CLKB  (clk_b), 		// B-port clk 
						.CLKEB (w_clke_b), 		// B-port clk enable 
						.WEB   (w_we_b), 		// B-port write enable 
						.ADDRB (w_addr_b), 		// B-port address input
						.WDATAB(w_wdata_b), 	// B-port write data input
						.RDATAB(w_rdata_b), 	// B-port read address output
					
					//Titanium extra ports
						
						.RSTA	(reset_a), // A-port reset 
						.ADDRENA(addren_a), // A-port address enable
						
						.RSTB(reset_b), // B-port reset 
						.ADDRENB(addren_b) // B-port address enable							
					);					
				end
			end
			
		end
		else if (bram_table_loop_mode == 1 ) 
		begin:scan_row_area
			for (gen_y=0; gen_y<bram_table_size; gen_y =gen_y +1)
			begin:area_row
				
				localparam bram_mode_a = bram_decompose_table(gen_y,0); 
				localparam bram_mode_b = bram_decompose_table(gen_y,1); 
				localparam column_count = bram_decompose_table(gen_y,2);
			
				localparam ADDR_WIDTH_ROW_A  = bram_feature_table(bram_mode_a,0);
				localparam DATA_WIDTH_ROW_A  = bram_feature_table(bram_mode_a,1); 
				localparam WEN_WIDTH_ROW_A   = bram_feature_table(bram_mode_a,2); 
				localparam ADDR_WIDTH_ROW_MAP_A = (ADDR_WIDTH_ROW_A > ADDR_WIDTH_A )? ADDR_WIDTH_A:ADDR_WIDTH_ROW_A;
				
	
				localparam ADDR_WIDTH_ROW_B  = bram_feature_table(bram_mode_b,0);
				localparam DATA_WIDTH_ROW_B  = bram_feature_table(bram_mode_b,1); 
				localparam WEN_WIDTH_ROW_B   = bram_feature_table(bram_mode_b,2); 	
				localparam ADDR_WIDTH_ROW_MAP_B = (ADDR_WIDTH_ROW_B > ADDR_WIDTH_B )? ADDR_WIDTH_B:ADDR_WIDTH_ROW_B;


				
				localparam START_ROW_INDEX = get_current_row_index(gen_y);	
                
         								
				for (gen_x=0; gen_x<column_count; gen_x =gen_x +1)
				begin: area_column
					localparam DATA_MAP_INDEX = START_ROW_INDEX+gen_x;

					localparam DATA_END_A     = bram_mapping_table(DATA_MAP_INDEX,2);					
					localparam DATA_START_A   = bram_mapping_table(DATA_MAP_INDEX,3);
					localparam DATA_REPART_A   = bram_mapping_table(DATA_MAP_INDEX,4);
					localparam WRSEL_INDEX_A   = bram_mapping_table(DATA_MAP_INDEX,6);
					localparam BYTEEN_INDEX_A  = bram_mapping_table(DATA_MAP_INDEX,8);
					localparam RMUX_INDEX_A    = bram_mapping_table(DATA_MAP_INDEX,5);
				
				
					localparam DATA_END_B     = bram_mapping_table(DATA_MAP_INDEX,9);					
					localparam DATA_START_B   = bram_mapping_table(DATA_MAP_INDEX,10);
					localparam DATA_REPART_B   = bram_mapping_table(DATA_MAP_INDEX,11);
					localparam WRSEL_INDEX_B   = bram_mapping_table(DATA_MAP_INDEX,13);
					localparam BYTEEN_INDEX_B  = bram_mapping_table(DATA_MAP_INDEX,15);	
					localparam RMUX_INDEX_B    = bram_mapping_table(DATA_MAP_INDEX,12);
						
					wire [ADDR_WIDTH_ROW_A-1:0] w_addr_a;
					wire [DATA_WIDTH_ROW_A-1:0] w_wdata_a;
					wire [DATA_WIDTH_ROW_A-1:0] w_rdata_a;
					wire [WEN_WIDTH_ROW_A-1:0]   w_we_a;

					wire [ADDR_WIDTH_ROW_B-1:0] w_addr_b;
					wire [DATA_WIDTH_ROW_B-1:0] w_wdata_b;
					wire [DATA_WIDTH_ROW_B-1:0] w_rdata_b;
					wire [WEN_WIDTH_ROW_B-1:0]   w_we_b;
					
					
					for(gen_z=0;gen_z<ADDR_WIDTH_ROW_A; gen_z=gen_z+1)
					begin : g1_for_gen_z_5
						if(gen_z< ADDR_WIDTH_A) 
							assign w_addr_a[gen_z] = w_addr_map_a[gen_z];
						else
							assign w_addr_a[gen_z] = 1'b0;
					end
					
					for(gen_z=0;gen_z<ADDR_WIDTH_ROW_B; gen_z=gen_z+1)
					begin : g1_for_gen_z_6
						if(gen_z< ADDR_WIDTH_B) 
							assign w_addr_b[gen_z] = w_addr_map_b[gen_z];
						else
							assign w_addr_b[gen_z] = 1'b0;			
					
					end
					
					
					if (DATA_REPART_A == 0)
					begin : g1_if_data_repart_a0_2
						assign w_wdata_a[DATA_WIDTH_ROW_A-1:0] = w_wdata_map_a[DATA_END_A:DATA_START_A];
						assign rMux_a[RMUX_INDEX_A][DATA_END_A:DATA_START_A]   = w_rdata_a[DATA_WIDTH_ROW_A-1:0]; 
					end
					else 
					begin : g1_else_70
						//for Mixed Width Mode 
						for (gen_z=0; gen_z<DATA_REPART_A; gen_z = gen_z+1)
						begin : g1_for_gen_z_7
							localparam MIXED_DATA_START =  DATA_START_A + gen_z*column_count* (DATA_END_B-DATA_START_B+1);//DATA_WIDTH_ROW_B;
							localparam MIXED_DATA_END   =  DATA_END_A   + gen_z*column_count* (DATA_END_B-DATA_START_B+1);//DATA_WIDTH_ROW_B; 
							
							localparam MAPPED_DATA_START =  DATA_WIDTH_ROW_B* gen_z;
							localparam MAPPED_DATA_END   =  DATA_WIDTH_ROW_B*(gen_z+1) -1; 
							
							assign w_wdata_a[MAPPED_DATA_END: MAPPED_DATA_START]  =  w_wdata_map_a[MIXED_DATA_END:MIXED_DATA_START];
							assign rMux_a[RMUX_INDEX_A][MIXED_DATA_END:MIXED_DATA_START]   = w_rdata_a[MAPPED_DATA_END:MAPPED_DATA_START]; 
						end
					end 
	
					if (DATA_REPART_B == 0)
					begin : g1_if_data_repart_b0_2
						assign w_wdata_b[DATA_WIDTH_ROW_B-1:0] = w_wdata_map_b[DATA_END_B:DATA_START_B];
						assign rMux_b[RMUX_INDEX_B][DATA_END_B:DATA_START_B]   = w_rdata_b[DATA_WIDTH_ROW_B-1:0]; 
					end
					else 
					begin : g1_else_71
						//for Mixed Width Mode 
						for (gen_z=0; gen_z<DATA_REPART_B; gen_z = gen_z+1)
						begin : g1_for_gen_z_8
							localparam MIXED_DATA_START =  DATA_START_B + gen_z*column_count* (DATA_END_A-DATA_START_A+1);//DATA_WIDTH_ROW_A;
							localparam MIXED_DATA_END   =  DATA_END_B   + gen_z*column_count* (DATA_END_A-DATA_START_A+1);//DATA_WIDTH_ROW_A; 
							
							localparam MAPPED_DATA_START =  DATA_WIDTH_ROW_A* gen_z;
							localparam MAPPED_DATA_END   =  DATA_WIDTH_ROW_A*(gen_z+1) -1; 
							
							assign w_wdata_b[MAPPED_DATA_END: MAPPED_DATA_START]  =  w_wdata_map_b[MIXED_DATA_END:MIXED_DATA_START];
							assign rMux_b[RMUX_INDEX_B][MIXED_DATA_END:MIXED_DATA_START]   = w_rdata_b[MAPPED_DATA_END:MAPPED_DATA_START]; 
						end
					end 	
					
					assign w_we_a[0] = ((we_a == WEA_POLARITY) & wen_decode_a[WRSEL_INDEX_A] & (byteen_a[BYTEEN_INDEX_A] == BYTEENA_POLARITY) ) ? WEA_POLARITY: !WEA_POLARITY;
					if ( WEN_WIDTH_ROW_A >1)
					begin : g1_if_wen_width_row_a1_2
						assign w_we_a[1] = ((we_a == WEA_POLARITY) & wen_decode_a[WRSEL_INDEX_A] & (byteen_a[BYTEEN_INDEX_A] == BYTEENA_POLARITY) ) ?  WEA_POLARITY: !WEA_POLARITY;
					end 	

					assign w_we_b[0] = ((we_b == WEB_POLARITY) & wen_decode_b[WRSEL_INDEX_B] & (byteen_b[BYTEEN_INDEX_B] == BYTEENB_POLARITY)) ?  WEB_POLARITY: !WEB_POLARITY;
					if ( WEN_WIDTH_ROW_B >1)
					begin : g1_if_wen_width_row_b1_2
						assign w_we_b[1] = ((we_b == WEB_POLARITY) & wen_decode_b[WRSEL_INDEX_B] & (byteen_b[BYTEEN_INDEX_B] == BYTEENB_POLARITY)) ? WEB_POLARITY : !WEB_POLARITY;
					end 
									
					`IP_MODULE_NAME(dpbram_primitive) #(
						.FAMILY(FAMILY),	
	
						//Trion and Titanium parameters 
						.WRITE_WIDTH_A(DATA_WIDTH_ROW_A),
						.READ_WIDTH_A(DATA_WIDTH_ROW_A),
						
						.CLKA_POLARITY(CLKA_POLARITY),  
						.CLKEA_POLARITY(CLKEA_POLARITY), 
						.WEA_POLARITY(WEA_POLARITY),	
						.WRITE_MODE_A(WRITE_MODE_A), 	
						.OUTPUT_REG_A(OUTPUT_REG_A),   
						
						.WRITE_WIDTH_B(DATA_WIDTH_ROW_B),	
						.READ_WIDTH_B(DATA_WIDTH_ROW_B),	
						
						.CLKB_POLARITY(CLKB_POLARITY),  
						.CLKEB_POLARITY(CLKEB_POLARITY), 
						.WEB_POLARITY(WEB_POLARITY),	
						.WRITE_MODE_B(WRITE_MODE_B), 	
						.OUTPUT_REG_B(OUTPUT_REG_B),   

						.ini_index(DATA_MAP_INDEX),
						
						//Titanium extra paramters 
						.RSTA_POLARITY(RSTA_POLARITY), 	
						.RESET_RAM_A(RESET_RAM_A), 	
						.RESET_OUTREG_A(RESET_OUTREG_A), 	
						.ADDRENA_POLARITY(ADDRENA_POLARITY),
						
						.RSTB_POLARITY(RSTB_POLARITY), 	
						.RESET_RAM_B(RESET_RAM_B), 	 	
						.RESET_OUTREG_B(RESET_OUTREG_B), 	
						.ADDRENB_POLARITY(ADDRENB_POLARITY)   											
				
						
					) bram (
					//Trion and Titanium ports
						.CLKA  (clk_a), 		// A-port clk 
						.CLKEA (w_clke_a), 		// A-port clk enable 
						.WEA   (w_we_a), 		// A-port write enable 
						.ADDRA (w_addr_a), 		// A-port address input
						.WDATAA(w_wdata_a), 	// A-port write data input
						.RDATAA(w_rdata_a), 	// A-port read address output
						
						.CLKB  (clk_b), 		// B-port clk 
						.CLKEB (w_clke_b), 		// B-port clk enable 
						.WEB   (w_we_b), 		// B-port write enable 
						.ADDRB (w_addr_b), 		// B-port address input
						.WDATAB(w_wdata_b), 	// B-port write data input
						.RDATAB(w_rdata_b), 	// B-port read address output
					
					//Titanium extra ports
						
						.RSTA	(reset_a), // A-port reset 
						.ADDRENA(addren_a), // A-port address enable
						
						.RSTB(reset_b), // B-port reset 
						.ADDRENB(addren_b) // B-port address enable							
					);
					

					
				end
			end
 
		end 
    endgenerate 
 
 
endmodule
