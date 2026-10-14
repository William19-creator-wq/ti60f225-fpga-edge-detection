/////////////////////////////////////////////////////////////////////////////
//           _____       
//          / _______    Copyright (C) 2013-2021 Efinix Inc. All rights reserved.
//         / /       \   
//        / /  ..    /   simple_dual_port_ram_fifo.v
//       / / .'     /    
//    __/ /.'      /     Description:
//   __   \       /      EFX FIFO
//  /_/ /\ \_____/ /     
// ____/  \_______/      
//
// *******************************
// Revisions:
//
// *******************************

module `IP_MODULE_NAME(efx_fifo_ram) #(
    parameter FAMILY        = "TRION",
    parameter WR_DEPTH      = 512,
    parameter RD_DEPTH      = 512,
    parameter WDATA_WIDTH   = 8,
    parameter RDATA_WIDTH   = 8,
    parameter WADDR_WIDTH   = 9,
    parameter RADDR_WIDTH   = 9,
    parameter OUTPUT_REG    = 1,
    parameter RAM_MUX_RATIO = 4,
    parameter ENDIANESS 	 = 0, //0: Big endian (default)   1: Little endian 
    parameter RAM_STYLE     = "block_ram"
) (
    input  wire                     wclk,
    input  wire                     rclk,
    input  wire                     we,
    input  wire                     re,
    input  wire [(WDATA_WIDTH-1):0] wdata,
    input  wire [(WADDR_WIDTH-1):0] waddr,
    input  wire [(RADDR_WIDTH-1):0] raddr,
    output wire [(RDATA_WIDTH-1):0] rdata
);

localparam MEM_DEPTH         = (WR_DEPTH > RD_DEPTH) ? WR_DEPTH : RD_DEPTH;
localparam MEM_DATA_WIDTH    = (WDATA_WIDTH > RDATA_WIDTH) ? RDATA_WIDTH : WDATA_WIDTH;   
localparam LSB_WIDTH         = (WADDR_WIDTH > RADDR_WIDTH) ? (WADDR_WIDTH - RADDR_WIDTH) : (RADDR_WIDTH - WADDR_WIDTH);
localparam RDATA_WDATA_RATIO = (RDATA_WIDTH <= WDATA_WIDTH/32) ? "ONE_THIRTYTWO" :
                               (RDATA_WIDTH <= WDATA_WIDTH/16) ? "ONE_SIXTEENTH" :
                               (RDATA_WIDTH <= WDATA_WIDTH/8)  ? "ONE_EIGHTH"    :
                               (RDATA_WIDTH <= WDATA_WIDTH/4)  ? "ONE_FOURTH"    :
                               (RDATA_WIDTH <= WDATA_WIDTH/2)  ? "ONE_HALF"      :
                               (RDATA_WIDTH <= WDATA_WIDTH)    ? "ONE"           :
                               (RDATA_WIDTH <= WDATA_WIDTH*2)  ? "TWO_TIMES"     :
                               (RDATA_WIDTH <= WDATA_WIDTH*4)  ? "FOUR_TIMES"    :
                               (RDATA_WIDTH <= WDATA_WIDTH*4)  ? "EIGHT_TIMES"   :
                               (RDATA_WIDTH <= WDATA_WIDTH*4)  ? "SIXTEEN_TIMES" : "THIRTYTWO_TIMES";

(* syn_ramstyle = RAM_STYLE *) reg [MEM_DATA_WIDTH-1:0] ram[MEM_DEPTH-1:0];
reg [RDATA_WIDTH-1:0]    r_rdata_1P;
reg [RDATA_WIDTH-1:0]    r_rdata_2P;

wire                     re_int;

generate
    if (FAMILY == "TRION") begin
        if (RDATA_WDATA_RATIO == "ONE") begin
            always @ (posedge wclk) begin
                if (we)
                    ram[waddr] <= wdata;
            end
    
            always @ (posedge rclk) begin
                if (re_int) begin
                    r_rdata_1P <= ram[raddr];
                end
                r_rdata_2P <= r_rdata_1P;
            end
        end
        
        else if (RDATA_WDATA_RATIO == "ONE_THIRTYTWO" || RDATA_WDATA_RATIO == "ONE_SIXTEENTH" || RDATA_WDATA_RATIO == "ONE_EIGHTH" || RDATA_WDATA_RATIO == "ONE_FOURTH"  || RDATA_WDATA_RATIO == "ONE_HALF" ) begin
            if (ENDIANESS == 0) begin 
            	integer i;
            	always @ (posedge wclk) begin
                	for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (we) begin
                            ram[{waddr,LSB_WIDTH'(RAM_MUX_RATIO-1-i)}] <= wdata[((WDATA_WIDTH/RAM_MUX_RATIO)*i) +: WDATA_WIDTH/RAM_MUX_RATIO];
                        end
                    end
                end
                always @ (posedge rclk) begin 
                	if (re_int) begin
                		r_rdata_1P <= ram[raddr];
                    end
                		r_rdata_2P <= r_rdata_1P;
                end
            end
            else begin //endianess == 1
            	integer i;
            	always @ (posedge wclk) begin
            		for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (we) begin
                            ram[{waddr,LSB_WIDTH'(i)}] <= wdata[((WDATA_WIDTH/RAM_MUX_RATIO)*i) +: WDATA_WIDTH/RAM_MUX_RATIO];
                        end
                    end
                end
                always @ (posedge rclk) begin 
                	if (re_int) begin
                		r_rdata_1P <= ram[raddr];
                	end
                		r_rdata_2P <= r_rdata_1P;
                end
            end
        end
        
        else if (RDATA_WDATA_RATIO == "TWO_TIMES" || RDATA_WDATA_RATIO == "FOUR_TIMES"  || RDATA_WDATA_RATIO == "EIGHT_TIMES"  || RDATA_WDATA_RATIO == "SIXTEEN_TIMES"  ||RDATA_WDATA_RATIO == "THIRTYTWO_TIMES" ) begin
            //integer i;
        	if (ENDIANESS == 0) begin
        		always @ (posedge wclk) begin
        			if (we)
        				ram[waddr] <= wdata;
        		end
        		integer i;
        		always @ (posedge rclk) begin
        			for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (re_int) begin
                    		r_rdata_1P[((RDATA_WIDTH/RAM_MUX_RATIO)*i) +: RDATA_WIDTH/RAM_MUX_RATIO] <= ram[{raddr,LSB_WIDTH'(RAM_MUX_RATIO-1-i)}];
                    	end
                        	r_rdata_2P <= r_rdata_1P;
                    end
                end 
            end
            else begin //endianess == 1
            	always @ (posedge wclk) begin
        			if (we)
        				ram[waddr] <= wdata;
        		end
        		integer i;
        		always @ (posedge rclk) begin
        			for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (re_int) begin
                    		r_rdata_1P[((RDATA_WIDTH/RAM_MUX_RATIO)*i) +: RDATA_WIDTH/RAM_MUX_RATIO] <= ram[{raddr,LSB_WIDTH'(i)}];
                    	end
                        	r_rdata_2P <= r_rdata_1P;
                    end
                end
            end
        end
        if (OUTPUT_REG) begin
            assign re_int = re;
            assign rdata  = r_rdata_2P;            
        end
        else begin
            assign re_int = re;
            assign rdata  = r_rdata_1P;
        end
    end
    else begin
        if (RDATA_WDATA_RATIO == "ONE") begin
            always @ (posedge wclk) begin
                if (we)
                    ram[waddr] <= wdata;
            end
    
            always @ (posedge rclk) begin
                if (re_int) begin
                    r_rdata_1P <= ram[raddr];
                    r_rdata_2P <= r_rdata_1P;
                end
            end
        end 
        else if (RDATA_WDATA_RATIO == "ONE_THIRTYTWO" || RDATA_WDATA_RATIO == "ONE_SIXTEENTH" || RDATA_WDATA_RATIO == "ONE_EIGHTH" || RDATA_WDATA_RATIO == "ONE_FOURTH"  || RDATA_WDATA_RATIO == "ONE_HALF" ) begin
            //integer i;
            if (ENDIANESS == 0) begin
            	integer i;
            	always @ (posedge wclk) begin
            		for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (we) begin
                            	ram[{waddr,LSB_WIDTH'(RAM_MUX_RATIO-1-i)}] <= wdata[((WDATA_WIDTH/RAM_MUX_RATIO)*i) +: WDATA_WIDTH/RAM_MUX_RATIO];
                        end
                    end
                 end
               	always @ (posedge rclk) begin 
               		if (re_int) begin
               			r_rdata_1P <= ram[raddr];
               			r_rdata_2P <= r_rdata_1P;
               		end
               	end
            end
            
            else begin //endianess == 1
            	integer i;
            	always @ (posedge wclk) begin
            		for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (we) begin
                            	ram[{waddr,LSB_WIDTH'(i)}] <= wdata[((WDATA_WIDTH/RAM_MUX_RATIO)*i) +: WDATA_WIDTH/RAM_MUX_RATIO];
                        end
                    end
                 end
               	always @ (posedge rclk) begin 
               		if (re_int) begin
               			r_rdata_1P <= ram[raddr];
               			r_rdata_2P <= r_rdata_1P;
               		end
               	end
            end
        end
        else if (RDATA_WDATA_RATIO == "TWO_TIMES" || RDATA_WDATA_RATIO == "FOUR_TIMES"  || RDATA_WDATA_RATIO == "EIGHT_TIMES"  || RDATA_WDATA_RATIO == "SIXTEEN_TIMES"  || RDATA_WDATA_RATIO == "THIRTYTWO_TIMES" ) begin
        	//integer i;
        	if (ENDIANESS == 0) begin
        		always @ (posedge wclk) begin
        			if (we)
        				ram[waddr] <= wdata;
        		end
        		integer i;
            	always @ (posedge rclk) begin
            		for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (re_int) begin
                    		r_rdata_1P[((RDATA_WIDTH/RAM_MUX_RATIO)*i) +: RDATA_WIDTH/RAM_MUX_RATIO] <= ram[{raddr,LSB_WIDTH'(RAM_MUX_RATIO-1-i)}];
                    		r_rdata_2P                                                               <= r_rdata_1P;
                    	end
                    end
                end 
            end
            
            else begin //endianess ==1
        		always @ (posedge wclk) begin
        			if (we)
        				ram[waddr] <= wdata;
        		end
        		integer i;
            	always @ (posedge rclk) begin
            		for (i=0; i<RAM_MUX_RATIO; i=i+1) begin
                    	if (re_int) begin
                    		r_rdata_1P[((RDATA_WIDTH/RAM_MUX_RATIO)*i) +: RDATA_WIDTH/RAM_MUX_RATIO] <= ram[{raddr,LSB_WIDTH'(i)}];
                    		r_rdata_2P                                                               <= r_rdata_1P;
                    	end
                    end
                end 
            end
        end
        // NIC
        //if (MODE == "STANDARD") begin     
        //    if (OUTPUT_REG) begin
        //        reg re_r;
        //        always @ (posedge rclk) begin
        //            re_r <= re;
        //        end
        //        assign re_int = re | re_r;        
        //        assign rdata  = r_rdata_2P;            
        //    end
        //    else begin
        //        assign re_int = re;
        //        assign rdata  = r_rdata_1P;
        //    end
        //end
        //else begin
        //    assign re_int = re;
        //    assign rdata  = r_rdata_1P;
        //end    
        if (OUTPUT_REG) begin
            reg re_r;
            always @ (posedge rclk) begin
                re_r <= re;
            end
            assign re_int = re | re_r;        
            assign rdata  = r_rdata_2P;            
        end
        else begin
            assign re_int = re;
            assign rdata  = r_rdata_1P;
        end    
    end
endgenerate

endmodule

////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013-2021 Efinix Inc. All rights reserved.              
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
////////////////////////////////////////////////////////////////////////////////
