
//TODO: separate RAM models and checking logic
module monitor_tdp (
	//Trion and Titanium ports
	clk_a, 		// A-port clk
	rdata_a, 	// A-port read address output
	clke_a,		// A-port clk enable
    byteen_a,	// A-port Byteen input 
    we_a, 		// A-port write enable 
	addr_a, 	// A-port address input
    wdata_a,	// A-port write data input
    state_a,

	clk_b, 		// B-port clk
	rdata_b, 	// B-port read address output
	clke_b,		// B-port clk enable
    byteen_b,	// B-port Byteen input 
    we_b, 		// B-port write enable 
	addr_b, 	// B-port address input
    wdata_b,	// B-port write data input
    state_b,
	     
	//Titanium extra ports
	bram_rst_a,	// A-port reset 
	addren_a,	// A-port address enable
	
	bram_rst_b,	// B-port reset 
	addren_b	// B-port address enable
);
//`include "bram_decompose.vh"
parameter       MEMORY_TYPE = "SP_RAM";	// 1:SP_RAM, 2:SDP_RAM, 3:TDP_RAM
parameter       CLK_MODE = 2;
//Trion and Titanium parameters
parameter CLKA_POLARITY     = 1'b1; 		
parameter CLKEA_POLARITY    = 1'b1; 		
parameter WEA_POLARITY	    = 1'b1; 		
parameter OUTPUT_REG_A   	= 1'b1; 	
parameter [0:0] BYTEENA_POLARITY  = 1'b1;     
parameter CLKB_POLARITY     = 1'b1; 		
parameter CLKEB_POLARITY    = 1'b1; 		
parameter WEB_POLARITY	    = 1'b1; 		
parameter OUTPUT_REG_B   	= 1'b1; 	
parameter [0:0] BYTEENB_POLARITY  = 1'b1;     
//Port Enable  	
parameter CLKEA_ENABLE 		= 1'b1; 	
parameter WEA_ENABLE 		= 1'b1;		
parameter BYTEENA_ENABLE 	= 1'b1;		
parameter CLKEB_ENABLE 		= 1'b1; 	
parameter WEB_ENABLE 		= 1'b1;		
parameter BYTEENB_ENABLE 	= 1'b1;		
//Titanium extra paramters 
parameter RSTA_POLARITY 	= 1'b1;    	
parameter RESET_RAM_A 	    = "SYNC"; 	
parameter RESET_OUTREG_A 	= "NONE"; 	
parameter ADDRENA_POLARITY  = 1'b1;    	
parameter RSTB_POLARITY 	= 1'b1;    	
parameter RESET_RAM_B 	    = "SYNC"; 	
parameter RESET_OUTREG_B 	= "NONE"; 	
parameter ADDRENB_POLARITY  = 1'b1;   	
//Port Enable  
parameter RESET_A_ENABLE 	= 1'b1;		
parameter ADDREN_A_ENABLE 	= 1'b1;		
parameter RESET_B_ENABLE 	= 1'b1;		
parameter ADDREN_B_ENABLE 	= 1'b1;

parameter DATA_WIDTH_A          = 16;
parameter DATA_WIDTH_B          = 16;
parameter ADDR_WIDTH_A          = 4;
parameter ADDR_WIDTH_B          = 4;
parameter BYTEEN_WIDTH_A        = 2;
parameter BYTEEN_WIDTH_B        = 2;
parameter GROUP_DATA_WIDTH_A    = 8;
parameter GROUP_DATA_WIDTH_B    = 8;
parameter WRITE_MODE_A          = "READ_FIRST";
parameter WRITE_MODE_B          = "READ_FIRST";
parameter FAMILY                = "TITANIUM";

input                       clk_a; 
input  [DATA_WIDTH_A-1:0 ]  rdata_a;
input                       clke_a;
input                       we_a;
input [BYTEEN_WIDTH_A-1:0]  byteen_a;                                      
input [ADDR_WIDTH_A-1:0 ]   addr_a; 
input [DATA_WIDTH_A-1:0 ]   wdata_a;
input                       bram_rst_a;
input                       addren_a;
input signed [31:0]         state_a;

input                       clk_b; 
input  [DATA_WIDTH_B-1:0 ]  rdata_b;
input                       clke_b;
input                       we_b;
input [BYTEEN_WIDTH_B-1:0]  byteen_b;
input [ADDR_WIDTH_B-1:0 ]   addr_b; 
input [DATA_WIDTH_B-1:0 ]   wdata_b;
input                       bram_rst_b;
input                       addren_b;
input signed [31:0]         state_b;

//localparam WRITE_MODE_B = DECOMPOSE_WRITE_MODE;
//localparam WRITE_MODE_A = DECOMPOSE_WRITE_MODE;

wire clk_a_i;
wire clk_b_i;
wire we_a_i;
wire we_b_i;
wire addren_a_i;
wire addren_b_i;
wire bram_rst_a_i;
wire bram_rst_b_i;
wire clke_a_i;
wire clke_b_i;
wire [BYTEEN_WIDTH_A-1:0] byteen_a_i;
wire [BYTEEN_WIDTH_B-1:0] byteen_b_i;
assign clk_a_i = CLKA_POLARITY ~^ clk_a;
assign clk_b_i = CLKB_POLARITY ~^ clk_b;
assign we_a_i = WEA_POLARITY ~^ we_a;
assign we_b_i = WEB_POLARITY ~^ we_b;
assign addren_a_i = FAMILY == "TRION" ? 1'b1 : ADDRENA_POLARITY ~^ addren_a;
assign addren_b_i = FAMILY == "TRION" ? 1'b1 : ADDRENB_POLARITY ~^ addren_b;
assign bram_rst_a_i = RSTA_POLARITY ~^ bram_rst_a;
assign bram_rst_b_i = RSTB_POLARITY ~^ bram_rst_b;
//assign clke_a_i = (MEMORY_TYPE == "TDP_RAM")? CLKEA_POLARITY ~^ clke_a: CLKEA_POLARITY;
//assign clke_b_i = (MEMORY_TYPE == "TDP_RAM")? CLKEB_POLARITY ~^ clke_b: CLKEB_POLARITY;
assign clke_a_i = CLKEA_POLARITY ~^ clke_a;
assign clke_b_i = CLKEB_POLARITY ~^ clke_b;
assign byteen_a_i = {BYTEEN_WIDTH_A{BYTEENA_POLARITY}} ~^ byteen_a;
assign byteen_b_i = {BYTEEN_WIDTH_B{BYTEENB_POLARITY}} ~^ byteen_b;

localparam DEPTH_A = 2**ADDR_WIDTH_A;
localparam DEPTH_B = 2**ADDR_WIDTH_B;
localparam DWA = DATA_WIDTH_A;
localparam DWB = DATA_WIDTH_B;
localparam AB_RATIO = (DATA_WIDTH_A / DATA_WIDTH_B);
localparam BA_RATIO = (DATA_WIDTH_B / DATA_WIDTH_A);
localparam AB_RATIO_WID = $clog2(AB_RATIO);
localparam BA_RATIO_WID = $clog2(BA_RATIO);
localparam DATA_WIDTH_MAX = DATA_WIDTH_A > DATA_WIDTH_B ? DATA_WIDTH_A : DATA_WIDTH_B;
localparam RATIO_WID = AB_RATIO_WID > BA_RATIO_WID ? AB_RATIO_WID : BA_RATIO_WID == 0 ? 1 : BA_RATIO_WID;    
reg [DATA_WIDTH_A-1:0] mem_reg[DEPTH_A-1:0];
reg [DATA_WIDTH_A*DEPTH_A-1:0] mem;
reg [ADDR_WIDTH_A-1:0] r_addr_a = 'hx;
reg [ADDR_WIDTH_B-1:0] r_addr_b = 'hx;

reg [DATA_WIDTH_A-1:0] mask_wdata_a;
reg [DATA_WIDTH_B-1:0] mask_wdata_b;
reg [DATA_WIDTH_A-1:0] mask_wdata_a_clk;
reg [DATA_WIDTH_B-1:0] mask_wdata_b_clk;
reg [DATA_WIDTH_A-1:0] mask_wdata_temp_a;
reg [DATA_WIDTH_B-1:0] mask_wdata_temp_b;
reg [ADDR_WIDTH_A-1:0] addr_a_i = 'hx;
reg [ADDR_WIDTH_B-1:0] addr_b_i = 'hx;
reg [ADDR_WIDTH_A-1:0] addr_a_r1 = 'hx;
reg [ADDR_WIDTH_B-1:0] addr_b_r1 = 'hx;
reg [ADDR_WIDTH_A-1:0] addr_a_r2 = 'hx;
reg [ADDR_WIDTH_B-1:0] addr_b_r2 = 'hx;
reg [DATA_WIDTH_A-1:0] exp_rdata_a_r1 = 'hx;
reg [DATA_WIDTH_A-1:0] exp_rdata_a_r2 = 'hx;
reg                    we_a_r1 = 0; 
reg                    we_a_r2 = 0; 
reg                    wclke_a_r1 = 0; 
reg                    wclke_a_r2 = 0; 
reg [DATA_WIDTH_A-1:0] wdata_a_r1 = 0;
reg [DATA_WIDTH_A-1:0] wdata_a_r2 = 0;
reg [DATA_WIDTH_B-1:0] exp_rdata_b_r1 = 'hx;
reg [DATA_WIDTH_B-1:0] exp_rdata_b_r2 = 'hx;
reg                    we_b_r1 = 0; 
reg                    we_b_r2 = 0; 
reg                    wclke_b_r1 = 0; 
reg                    wclke_b_r2 = 0; 
reg [DATA_WIDTH_B-1:0] wdata_b_r1 = 0;
reg [DATA_WIDTH_B-1:0] wdata_b_r2 = 0;
reg		       clke_a_r1 = 0;
reg		       clke_b_r1 = 0;
reg		       clke_a_r2 = 0;
reg		       clke_b_r2 = 0;
reg  [DATA_WIDTH_A-1:0 ]  rdata_a_r1;
reg  [DATA_WIDTH_B-1:0 ]  rdata_b_r1;

wire [DATA_WIDTH_A-1:0] final_exp_rdata_a;
wire [DATA_WIDTH_B-1:0] final_exp_rdata_b;
wire                    final_we_a;
wire                    final_we_b;
wire                    final_clke_a;
wire                    final_clke_b;
wire                    wr_same_addr;
wire			wr_same_addr_a;
wire			wr_same_addr_b;
wire [RATIO_WID-1:0]    data_sel;

reg clke_a_i_clk;
reg clke_b_i_clk;
reg we_a_i_clk;
reg we_b_i_clk;
reg [ADDR_WIDTH_A-1:0] addr_a_i_clk;
reg [ADDR_WIDTH_B-1:0] addr_b_i_clk;


assign wr_same_addr = addr_a_i >> BA_RATIO_WID == addr_b_i >> AB_RATIO_WID;
assign wr_same_addr_a = addr_a_i >> BA_RATIO_WID == addr_b_i_clk >> AB_RATIO_WID;
assign wr_same_addr_b = addr_a_i_clk >> BA_RATIO_WID == addr_b_i >> AB_RATIO_WID;
integer i = 0;
integer success_cnt_a = 0;
integer success_cnt_b = 0;
integer failure_cnt = 0;
integer collision_cnt = 0;
integer number_clka =0;
integer number_clkb =0;
 
generate
    if (AB_RATIO == 1) begin
        assign data_sel = 0;
    end else if (AB_RATIO > 1) begin
        assign data_sel = addr_b_i[AB_RATIO_WID-1:0];
    end else begin
        assign data_sel = addr_a_i[BA_RATIO_WID-1:0];
    end
endgenerate


initial begin
    //$display("Loading init_hex.mem ...");
    $readmemh("init_hex.mem", mem_reg);
    //$display("---- Dump of mem_reg after readmemh ----");
    //for (int i = 0; i < DEPTH_A; i++) begin
    //    $display("Line %0d : 0x%0h", i, mem_reg[i]);
    //end
    //$display("----------------------------------------");

    //$display("---- Dump of mem after reassignment ----");    
    for (i=0; i<DEPTH_A ; i=i+1) begin
        mem[i*DWA +: DWA] = mem_reg[i];
	//$display("Line %0d : 0x%0h", i, mem[i*DWA +: DWA]);
    end
    //$display("----------------------------------------");

end

initial begin
    if ((AB_RATIO_WID > 0 && BA_RATIO_WID != 0) ||
        (BA_RATIO_WID > 0 && AB_RATIO_WID != 0)) begin
        $error("Unexpected Write Read Ratio. AB_RATIO: %0d, BA_RATIO: %0d, AB_RATIO_WID: %0d, BA_RATIO_WID: %0d", 
                AB_RATIO, BA_RATIO, AB_RATIO_WID, BA_RATIO_WID);
        #10 $stop;
    end

    if (DATA_WIDTH_A*DEPTH_A != DATA_WIDTH_B*DEPTH_B) begin
        $error("Size of Port A and Port B mismatch. DATA_WIDTH_A: %0d, DEPTH_A: %0d, DATA_WIDTH_B: %0d, DEPTH_B: %0d", DATA_WIDTH_A, DEPTH_A, DATA_WIDTH_B, DEPTH_B);
        #10 $stop;
    end
    
    if ($rtoi($ceil($itor(DATA_WIDTH_A)/GROUP_DATA_WIDTH_A)) != BYTEEN_WIDTH_A) begin
        $error("byte enable width of Port A mismatch. DATA_WIDTH_A: %0d, GROUP_DATA_WIDTH_A: %0d, BYTEEN_WIDTH_A: %0d", DATA_WIDTH_A, GROUP_DATA_WIDTH_A, BYTEEN_WIDTH_A);
        #10 $stop;
    end
    
    if ($rtoi($ceil($itor(DATA_WIDTH_B)/GROUP_DATA_WIDTH_B)) != BYTEEN_WIDTH_B) begin
        $error("byte enable width of Port B mismatch. DATA_WIDTH_B: %0d, GROUP_DATA_WIDTH_B: %0d, BYTEEN_WIDTH_B: %0d", DATA_WIDTH_B, GROUP_DATA_WIDTH_B, BYTEEN_WIDTH_B);
        #10 $stop;
    end
end

generate
    //port a
    if (OUTPUT_REG_A) begin
        assign final_exp_rdata_a = exp_rdata_a_r2;
        assign final_we_a = we_a_r2;
        assign final_clke_a = wclke_a_r2;
    end else begin
        assign final_exp_rdata_a = exp_rdata_a_r1;
        assign final_we_a = we_a_r1;
        assign final_clke_a = wclke_a_r1;
    end

    //port b
    if (OUTPUT_REG_B) begin
        assign final_exp_rdata_b = exp_rdata_b_r2;
        assign final_we_b = we_b_r2;
        assign final_clke_b = wclke_b_r2;
    end else begin
        assign final_exp_rdata_b = exp_rdata_b_r1;
        assign final_we_b = we_b_r1;
        assign final_clke_b = wclke_b_r1;
    end
endgenerate


always @(*) begin   //port a b
    if (addren_a_i && clke_a_i)
        addr_a_i = addr_a;
    else
        addr_a_i = r_addr_a;

    if (addren_b_i && clke_b_i)
        addr_b_i = addr_b;
    else
        addr_b_i = r_addr_b;

    mask_wdata_temp_a = mem[addr_a_i*DWA +: DWA];
    mask_wdata_temp_b = mem[addr_b_i*DWB +: DWB];
    
    for(i=0 ; i<BYTEEN_WIDTH_A-1 ; i=i+1) begin
        if (byteen_a_i[i]) 
            mask_wdata_temp_a[i*GROUP_DATA_WIDTH_A +: GROUP_DATA_WIDTH_A] = wdata_a[i*GROUP_DATA_WIDTH_A +: GROUP_DATA_WIDTH_A];
        else
            mask_wdata_temp_a[i*GROUP_DATA_WIDTH_A +: GROUP_DATA_WIDTH_A] = mem[addr_a_i*DWA+i*GROUP_DATA_WIDTH_A +: GROUP_DATA_WIDTH_A];
    end
    //last group of data may not be integer multiple
    if (byteen_a_i[BYTEEN_WIDTH_A-1])
        mask_wdata_temp_a[DWA-1 : (BYTEEN_WIDTH_A-1)*GROUP_DATA_WIDTH_A] = 
            wdata_a[DWA-1 : (BYTEEN_WIDTH_A-1)*GROUP_DATA_WIDTH_A];
    else
        mask_wdata_temp_a[DWA-1 : (BYTEEN_WIDTH_A-1)*GROUP_DATA_WIDTH_A] = 
            mem[addr_a_i*DWA+(BYTEEN_WIDTH_A-1)*GROUP_DATA_WIDTH_A +: DWA-(BYTEEN_WIDTH_A-1)*GROUP_DATA_WIDTH_A];

    for(i=0 ; i<BYTEEN_WIDTH_B-1 ; i=i+1) begin
        if (byteen_b_i[i]) 
            mask_wdata_temp_b[i*GROUP_DATA_WIDTH_B +: GROUP_DATA_WIDTH_B] = wdata_b[i*GROUP_DATA_WIDTH_B +: GROUP_DATA_WIDTH_B];
        else
            mask_wdata_temp_b[i*GROUP_DATA_WIDTH_B +: GROUP_DATA_WIDTH_B] = mem[addr_b_i*DWB+i*GROUP_DATA_WIDTH_B +: GROUP_DATA_WIDTH_B];
    end 
    //last group of data may not be integer multiple
    if (byteen_b_i[BYTEEN_WIDTH_B-1])
        mask_wdata_temp_b[DWB-1 : (BYTEEN_WIDTH_B-1)*GROUP_DATA_WIDTH_B] = 
            wdata_b[DWB-1 : (BYTEEN_WIDTH_B-1)*GROUP_DATA_WIDTH_B];
    else
        mask_wdata_temp_b[DWB-1 : (BYTEEN_WIDTH_B-1)*GROUP_DATA_WIDTH_B] = 
            mem[addr_b_i*DWB+(BYTEEN_WIDTH_B-1)*GROUP_DATA_WIDTH_B +: DWB-(BYTEEN_WIDTH_B-1)*GROUP_DATA_WIDTH_B];

    mask_wdata_a = mask_wdata_temp_a;
    mask_wdata_b = mask_wdata_temp_b;
    if (wr_same_addr && clke_a_i && we_a_i && clke_b_i && we_b_i) begin   //addra & b may have different width
        if (AB_RATIO >= 1) begin    //data width of port a >= port b
            if (mask_wdata_temp_a[data_sel*DWB +: DWB] == mask_wdata_temp_b) 
                mask_wdata_b = mask_wdata_temp_b;
            else
                mask_wdata_b = {DWB{1'bx}};
        end else begin
            if (mask_wdata_b[data_sel*DWA +: DWA] == mask_wdata_temp_a) 
                mask_wdata_b[data_sel*DWA +: DWA] = mask_wdata_temp_b[data_sel*DWA +: DWA];
            else
                mask_wdata_b[data_sel*DWA +: DWA] = {DWA{1'bx}};
        end
    end
    
    if (wr_same_addr && clke_a_i && we_a_i && clke_b_i && we_b_i) begin   //addra & b may have different width
        if (AB_RATIO >= 1) begin    //data width of port a >= port b
            if (mask_wdata_a[data_sel*DWB +: DWB] == mask_wdata_temp_b) 
                mask_wdata_a[data_sel*DWB +: DWB] = mask_wdata_temp_a[data_sel*DWB +: DWB];
            else
                mask_wdata_a[data_sel*DWB +: DWB] = {DWB{1'bx}};
        end else begin
            if (mask_wdata_b[data_sel*DWA +: DWA] == mask_wdata_temp_a) 
                mask_wdata_a = mask_wdata_temp_a;
            else
                mask_wdata_a = {DWA{1'bx}};
        end
    end
end

always @(posedge clk_a_i) begin
    if (clke_a_i && we_a_i && !(MEMORY_TYPE == "DP_ROM")) begin
        mem[addr_a_i*DWA +: DWA] <= mask_wdata_a;

        if (wr_same_addr_a || wr_same_addr_b)
            collision_cnt <= collision_cnt + 1;
    end
end

always @(posedge clk_b_i) begin
    if (clke_b_i && we_b_i && !(MEMORY_TYPE == "DP_ROM")) begin
        mem[addr_b_i*DWB +: DWB] <= mask_wdata_b;
    end
end

if (FAMILY == "TRION") begin
	always @(posedge clk_a_i) begin
		rdata_a_r1 <= rdata_a;
	end	
end
else begin
	always @(posedge clk_a_i or posedge bram_rst_a_i) begin
		if(bram_rst_a_i) begin
			rdata_a_r1 <= 'd0;
		end else begin
			rdata_a_r1 <= rdata_a;
		end
	end
end

always @(posedge clk_b_i) begin
    mask_wdata_b_clk <= mask_wdata_b;
    clke_b_i_clk <= clke_b_i;
    we_b_i_clk <= we_b_i;
    addr_b_i_clk <= addr_b_i;
end

always @(posedge clk_a_i) begin
    number_clka <= number_clka + 1;
    addr_a_r1   <= addr_a_i;
    wdata_a_r1  <= wdata_a;
    we_a_r1     <= we_a_i;
    wclke_a_r1  <= clke_a_i;
    addr_a_r2   <= addr_a_r1;
    wdata_a_r2  <= wdata_a_r1;
    we_a_r2     <= we_a_r1;
    wclke_a_r2  <= wclke_a_r1;
    clke_a_r1   <= clke_a_i;
    clke_a_r2   <= clke_a_r1;	    
    
    if (addren_a_i && clke_a_i) begin
        r_addr_a <= addr_a;
    end

    if (FAMILY == "TITANIUM" && OUTPUT_REG_A == 0) begin
        if (clke_a_i) begin
            exp_rdata_a_r2 <= exp_rdata_a_r1; 
        end
    end else if (FAMILY == "TITANIUM" && OUTPUT_REG_A == 1) begin
        if (clke_a_r1) begin
            exp_rdata_a_r2 <= exp_rdata_a_r1; 
        end
    end else begin          //clock enable doesn't affect output registers in Trion
        exp_rdata_a_r2 <= exp_rdata_a_r1; 
    end

    if (clke_a_i) begin
        if (FAMILY == "TITANIUM" && bram_rst_a_i) begin
		if (OUTPUT_REG_A) begin
            		exp_rdata_a_r2 <= {DWA{1'b0}};  //MC: change from exp_rdata_a_r1 to exp_rdata_a_r2
	    		exp_rdata_a_r1 <= {DWA{1'b0}};
		end else begin
	    		exp_rdata_a_r1 <= {DWA{1'b0}};
		end
        end else begin
            case (WRITE_MODE_A)
            "WRITE_FIRST": begin
                if (!we_a_i) begin
		    if (CLK_MODE == 2) begin
                    	if (clke_b_i_clk && we_b_i_clk && wr_same_addr_a) begin
                            if (AB_RATIO >= 1) begin
                            	exp_rdata_a_r1 <= mem[addr_a_i*DWA +: DWA];
                            	//exp_rdata_a_r1[data_sel*DWB +: DWB] <= mask_wdata_b;
			    	exp_rdata_a_r1[data_sel*DWB +: DWB] = mask_wdata_b_clk;
				$display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);
                            end else begin
                            	//exp_rdata_a_r1 <= mask_wdata_b[data_sel*DWA +: DWA];
			    	exp_rdata_a_r1 = mask_wdata_b_clk[data_sel*DWA +: DWA];
				$display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);
                            end
                    	end else begin
                            exp_rdata_a_r1 <= mem[addr_a_i*DWA +: DWA];
			    $display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);
                    	end
		    end else begin
			if (clke_b_i && we_b_i && wr_same_addr) begin
                            if (AB_RATIO >= 1) begin
                            	exp_rdata_a_r1 = mem[addr_a_i*DWA +: DWA];
                            	//exp_rdata_a_r1[data_sel*DWB +: DWB] <= mask_wdata_b;
			    	exp_rdata_a_r1[data_sel*DWB +: DWB] = mask_wdata_b;
				$display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);
                            end else begin
                            	//exp_rdata_a_r1 <= mask_wdata_b[data_sel*DWA +: DWA];
			    	exp_rdata_a_r1 = mask_wdata_b[data_sel*DWA +: DWA];
				$display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);
                            end
                    	end else begin
                            exp_rdata_a_r1 <= mem[addr_a_i*DWA +: DWA];
			    $display("[INFO] time %0t ps Address-A read write_first: %h", $time, addr_a_i);					    
                    	end
		    end
                end else if (we_a_i && !(MEMORY_TYPE == "DP_ROM")) begin
                    exp_rdata_a_r1 <= mask_wdata_a;
                end
            end

            "READ_FIRST": begin
                exp_rdata_a_r1 <= mem[addr_a_i*DWA +: DWA];
		$display("[INFO] time %0t ps Address-A read read_first: %h", $time, addr_a_i);		
            end

            "NO_CHANGE": begin
                if (!we_a_i) begin
                    exp_rdata_a_r1 <= mem[addr_a_i*DWA +: DWA];
                end else if (!(MEMORY_TYPE == "DP_ROM")) begin
                    exp_rdata_a_r1 <= exp_rdata_a_r1;
                end
            end
            endcase
        end
    end
end

if(FAMILY == "TRION") begin
	always @(posedge clk_b_i) begin
		rdata_b_r1 <= rdata_b;
	end
end
else begin
	always @(posedge clk_b_i or posedge bram_rst_b_i) begin
		if(bram_rst_b_i) begin
			rdata_b_r1 <= 'd0;
		end else begin
			rdata_b_r1 <= rdata_b;
		end
	end
end

always @(posedge clk_a_i) begin
    mask_wdata_a_clk <= mask_wdata_a;
    clke_a_i_clk <= clke_a_i;
    we_a_i_clk <= we_a_i;
    addr_a_i_clk <= addr_a_i;
end

always @(posedge clk_b_i) begin
    number_clkb <= number_clkb + 1;
    addr_b_r1   <= addr_b_i;
    wdata_b_r1  <= wdata_b;
    we_b_r1     <= we_b_i;
    wclke_b_r1  <= clke_b_i;
    addr_b_r2   <= addr_b_r1;
    wdata_b_r2  <= wdata_b_r1;
    we_b_r2     <= we_b_r1;
    wclke_b_r2  <= wclke_b_r1;		    
    clke_b_r1   <= clke_b_i;
    clke_b_r2   <= clke_b_r1;
    
    if (addren_b_i && clke_b_i) begin
        r_addr_b <= addr_b;
    end

    if (FAMILY == "TITANIUM" && OUTPUT_REG_B == 0) begin
        if (clke_b_i) begin
            exp_rdata_b_r2 <= exp_rdata_b_r1; 
        end
    end else if (FAMILY == "TITANIUM" && OUTPUT_REG_B == 1) begin
	if (clke_b_r1) begin
            exp_rdata_b_r2 <= exp_rdata_b_r1; 
        end
    end else begin          //clock enable doesn't affect output registers in Trion
        exp_rdata_b_r2 <= exp_rdata_b_r1; 
    end

    if (clke_b_i) begin
        if (FAMILY == "TITANIUM" && bram_rst_b_i) begin
		if (OUTPUT_REG_B) begin
            		exp_rdata_b_r2 <= {DWB{1'b0}}; //MC: Change exp_rdata_b_r1 to exp_rdata_b_r2
	    		exp_rdata_b_r1 <= {DWB{1'b0}};
		end else begin
	    		exp_rdata_b_r1 <= {DWB{1'b0}};
		end
        end else begin
            case (WRITE_MODE_B)
            "WRITE_FIRST": begin
                if (!we_b_i) begin
		    if (CLK_MODE == 2) begin
                        if (clke_a_i_clk && we_a_i_clk && wr_same_addr_b) begin
                            if (AB_RATIO >= 1) begin
                                //exp_rdata_b_r1 <= mask_wdata_a[data_sel*DWB +: DWB];
			        exp_rdata_b_r1 = mask_wdata_a_clk[data_sel*DWB +: DWB];
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);
                            end else begin
                            	exp_rdata_b_r1 <= mem[addr_b_i*DWB +: DWB];
                            	//exp_rdata_b_r1[data_sel*DWA +: DWA] <= mask_wdata_a;
			    	exp_rdata_b_r1[data_sel*DWA +: DWA] = mask_wdata_a_clk;
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);
                            end
                    	end else begin
                        	exp_rdata_b_r1 <= mem[addr_b_i*DWB +: DWB];
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);				
                        end
		    end else begin
			if (clke_a_i && we_a_i && wr_same_addr) begin
                            if (AB_RATIO >= 1) begin
                                //exp_rdata_b_r1 <= mask_wdata_a[data_sel*DWB +: DWB];
			        exp_rdata_b_r1 = mask_wdata_a[data_sel*DWB +: DWB];
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);				
                            end else begin
                            	exp_rdata_b_r1 = mem[addr_b_i*DWB +: DWB];
                            	//exp_rdata_b_r1[data_sel*DWA +: DWA] <= mask_wdata_a;
			    	exp_rdata_b_r1[data_sel*DWA +: DWA] = mask_wdata_a;
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);				
                            end
                    	end else begin
                        	exp_rdata_b_r1 <= mem[addr_b_i*DWB +: DWB];
				$display("[INFO] time %0t ps Address-B read write_first: %h", $time, addr_b_i);				
                        end
		    end
		    
                end else if (we_b_i && !(MEMORY_TYPE == "DP_ROM")) begin
                    exp_rdata_b_r1 <= mask_wdata_b;
                end
            end

            "READ_FIRST": begin
                exp_rdata_b_r1 <= mem[addr_b_i*DWB +: DWB];
		$display("[INFO] time %0t ps Address-B read read_first: %h", $time, addr_b_i);
            end

            "NO_CHANGE": begin
                if (!we_b_i) begin
                    exp_rdata_b_r1 <= mem[addr_b_i*DWB +: DWB];
                end else if (!(MEMORY_TYPE == "DP_ROM")) begin
                    exp_rdata_b_r1 <= exp_rdata_b_r1;
                end
            end
            endcase
        end
    end
end

/*property data_stable_when_clke_0_porta;
	@(posedge clk_a_i) ((clke_a_i == 0 && OUTPUT_REG_A == 0 && (number_clka > 0)) || (clke_a_r2 == 0 && OUTPUT_REG_A == 1 && (number_clka > 0))) |=> (rdata_a != rdata_a_r1);
endproperty

assert property (data_stable_when_clke_0_porta)
else $error("Read data A from DUT changed unexpectedly at time %0t", $time);

property data_stable_when_clke_0_portb;
	@(posedge clk_b_i) ((clke_b_i == 0 && OUTPUT_REG_B == 0 && (number_clkb > 0)) || (clke_b_r2 == 0 && OUTPUT_REG_B == 1 && (number_clkb > 0))) |=> (rdata_b != rdata_b_r1);
endproperty

assert property (data_stable_when_clke_0_portb)
else $error("Read data A from DUT changed unexpectedly at time %0t", $time);*/

localparam [2:0]
	RAM_IDLE = 3'd0,
	RAM_READ = 3'd1,
	RAM_IDLE_RVALID = 3'd2,
	RAM_RVALID_RVALID = 3'd3;

reg [2:0] rstate_a = RAM_IDLE;
reg [2:0] next_rstate_a = RAM_IDLE;
reg [2:0] rstate_b = RAM_IDLE;
reg [2:0] next_rstate_b = RAM_IDLE;

always @(posedge clk_a_i) begin
	if ((clke_a_r1 == 0 && OUTPUT_REG_A == 0 && number_clka > 0) && (rdata_a != rdata_a_r1) && bram_rst_a_i == 0) begin
		$error("1Read data A from DUT changed unexpectedly at time %0t", $time);
	end else if (((clke_a_r2==0 && FAMILY == "TRION" && bram_rst_a_i == 0) || ((rstate_a == RAM_IDLE || rstate_a == RAM_READ) && FAMILY == "TITANIUM")) && OUTPUT_REG_A == 1 && number_clka > 0 && (rdata_a != rdata_a_r1)) begin
		$error("2Read data A from DUT changed unexpectedly at time %0t", $time);
	end
end

always @(posedge clk_b_i) begin
	if ((clke_b_r1 == 0 && OUTPUT_REG_B == 0 && number_clkb > 0) && (rdata_b != rdata_b_r1) && bram_rst_b_i == 0) begin
		$error("1Read data B from DUT changed unexpectedly at time %0t", $time);
	end else if (((clke_b_r2==0 && FAMILY == "TRION" && bram_rst_b_i == 0) || ((rstate_b == RAM_IDLE || rstate_b == RAM_READ) && FAMILY == "TITANIUM")) && OUTPUT_REG_B == 1 && number_clkb > 0 && (rdata_b != rdata_b_r1)) begin
		$error("2Read data B from DUT changed unexpectedly at time %0t", $time);
	end
end

always @(*) begin
	if (FAMILY == "TITANIUM" && bram_rst_a_i) begin
		if (OUTPUT_REG_A) begin
            		exp_rdata_a_r2 <= {DWA{1'b0}};  //MC: change from exp_rdata_a_r1 to exp_rdata_a_r2
	    		exp_rdata_a_r1 <= {DWA{1'b0}};
		end else begin
	    		exp_rdata_a_r1 <= {DWA{1'b0}};
        	end
	end
	
	if (FAMILY == "TITANIUM" && bram_rst_b_i) begin
		if (OUTPUT_REG_B) begin
            		exp_rdata_b_r2 <= {DWB{1'b0}}; //MC: Change exp_rdata_b_r1 to exp_rdata_b_r2
	    		exp_rdata_b_r1 <= {DWB{1'b0}};
		end else begin
	    		exp_rdata_b_r1 <= {DWB{1'b0}};
        	end
	end
end



always @(posedge clk_a_i or posedge bram_rst_a_i) begin
	if(bram_rst_a_i)
		rstate_a <= RAM_IDLE;
	else
		rstate_a <= next_rstate_a;
end

always @(posedge clk_b_i or posedge bram_rst_b_i) begin
	if(bram_rst_b_i)
		rstate_b <= RAM_IDLE;
	else
		rstate_b <= next_rstate_b;
end

always @(*) begin
	//next_rstate_a = rstate_a;
	case (rstate_a)
		RAM_IDLE: begin
			if(clke_a_i && ~we_a_i)
				next_rstate_a = OUTPUT_REG_A ? RAM_READ : RAM_RVALID_RVALID;
			else if(clke_a_i && we_a_i)
				next_rstate_a = (WRITE_MODE_A == "READ_FIRST" || WRITE_MODE_A == "WRITE_FIRST") ? OUTPUT_REG_A ? RAM_READ : RAM_RVALID_RVALID : RAM_IDLE;
			else
				next_rstate_a = RAM_IDLE;
		end
		RAM_READ: begin
			if(clke_a_i && ~we_a_i)
				next_rstate_a = RAM_RVALID_RVALID;
			else if(clke_a_i && we_a_i)
				next_rstate_a = (WRITE_MODE_A == "READ_FIRST" || WRITE_MODE_A == "WRITE_FIRST") ? RAM_RVALID_RVALID : RAM_IDLE_RVALID;
			else if(clke_a_i)
				next_rstate_a = RAM_IDLE_RVALID;
			else if(clke_a_i==0 && FAMILY == "TRION")
				next_rstate_a = RAM_IDLE_RVALID;
			else if(clke_a_i==0 && FAMILY == "TITANIUM")
				next_rstate_a = RAM_READ;
			else
				next_rstate_a = RAM_READ;
		end
		RAM_IDLE_RVALID: begin
			if(clke_a_i && ~we_a_i)
				next_rstate_a = RAM_READ;
			else if (clke_a_i && we_a_i)
				next_rstate_a = (WRITE_MODE_A == "READ_FIRST" || WRITE_MODE_A == "WRITE_FIRST") ? RAM_READ : RAM_IDLE;
			else if (clke_a_i)
				next_rstate_a = RAM_IDLE;
			else if (clke_a_i==0 && FAMILY == "TRION")
				next_rstate_a = RAM_IDLE;
			else if (clke_a_i==0 && FAMILY == "TITANIUM")
				next_rstate_a = RAM_IDLE;
			else
				next_rstate_a = RAM_IDLE;
		end
		RAM_RVALID_RVALID: begin
			if(clke_a_i && ~we_a_i)
				next_rstate_a = RAM_RVALID_RVALID;
			else if (clke_a_i && we_a_i)
				next_rstate_a = (WRITE_MODE_A == "READ_FIRST" || WRITE_MODE_A == "WRITE_FIRST") ? RAM_RVALID_RVALID : (OUTPUT_REG_A ? RAM_IDLE_RVALID : RAM_IDLE);
			else if (clke_a_i)
				next_rstate_a = OUTPUT_REG_A ? RAM_IDLE_RVALID : RAM_IDLE;
			else if (clke_a_i==0 && FAMILY == "TRION")
				next_rstate_a = OUTPUT_REG_A ? RAM_IDLE_RVALID : RAM_IDLE;
			else if (clke_a_i==0 && FAMILY == "TITANIUM")
				next_rstate_a = OUTPUT_REG_A ? RAM_READ : RAM_IDLE;				
			else
				next_rstate_a = OUTPUT_REG_A ? RAM_READ : RAM_IDLE;
		end
		default: next_rstate_a = RAM_IDLE; 
	endcase
end

integer acnt = 0;
always @(posedge clk_a_i) begin //verify WRITE_MODE
    if (((clke_a_r1 && OUTPUT_REG_A == 0) || ((rstate_a == RAM_IDLE_RVALID || rstate_a == RAM_RVALID_RVALID) && OUTPUT_REG_A == 1)) && state_a != 0) begin
        for(acnt=0 ; acnt<DWA ; acnt=acnt+1) begin
            if (final_exp_rdata_a[acnt] === 1'bx) begin
                //pass
            end else begin
                if (final_exp_rdata_a[acnt] === rdata_a[acnt]) begin
          	    $display("%t ps - PASS! BRAM_A read data %h is match expected data %h ,bitwise %d", $time(), rdata_a[acnt], final_exp_rdata_a[acnt], acnt);
                    success_cnt_a = success_cnt_a + 1;
                end else begin
                    $error("%t ps - FAIL! BRAM_A read data %h doesn't match expected data %h ,bitwise $d", $time(), rdata_a[acnt], final_exp_rdata_a[acnt], acnt);
                    $display("info: FAMILY: %s, MEMORY_TYPE: %s, WRITE_MODE_A: %s, ADDR_WIDTH_A: %d, DWB: %d, ADDR_WIDTH_B: %d, DWA: %d, GROUP_DATA_WIDTH_A: %d, GROUP_DATA_WIDTH_A: %d, GROUP_DATA_WIDTH_B: %d, ", FAMILY, MEMORY_TYPE, WRITE_MODE_A, ADDR_WIDTH_A, DWB, ADDR_WIDTH_B, DWA, GROUP_DATA_WIDTH_A, GROUP_DATA_WIDTH_A, GROUP_DATA_WIDTH_B);
                    #10 $stop;
                end
            end
        end
    end
end

always @(*) begin
	//next_rstate_b = rstate_b;
	case (rstate_b)
		RAM_IDLE: begin
			if(clke_b_i && ~we_b_i)
				next_rstate_b = OUTPUT_REG_B ? RAM_READ : RAM_RVALID_RVALID;
			else if(clke_b_i && we_b_i)
				next_rstate_b = (WRITE_MODE_B == "READ_FIRST" || WRITE_MODE_B == "WRITE_FIRST") ? OUTPUT_REG_B ? RAM_READ : RAM_RVALID_RVALID : RAM_IDLE;
			else
				next_rstate_b = RAM_IDLE;
		end
		RAM_READ: begin
			if(clke_b_i && ~we_b_i)
				next_rstate_b = RAM_RVALID_RVALID;
			else if(clke_b_i && we_b_i)
				next_rstate_b = (WRITE_MODE_B == "READ_FIRST" || WRITE_MODE_B == "WRITE_FIRST") ? RAM_RVALID_RVALID : RAM_IDLE_RVALID;
			else if(clke_b_i)
				next_rstate_b = RAM_IDLE_RVALID;
			else if(clke_b_i==0 && FAMILY == "TRION")
				next_rstate_b = RAM_IDLE_RVALID;
			else if(clke_b_i==0 && FAMILY == "TITANIUM")
				next_rstate_b = RAM_READ;
			else
				next_rstate_b = RAM_READ;
		end
		RAM_IDLE_RVALID: begin
			if(clke_b_i && ~we_b_i)
				next_rstate_b = RAM_READ;
			else if (clke_b_i && we_b_i)
				next_rstate_b = (WRITE_MODE_B == "READ_FIRST" || WRITE_MODE_B == "WRITE_FIRST") ? RAM_READ : RAM_IDLE;
			else if (clke_b_i)
				next_rstate_b = RAM_IDLE;
			else if (clke_b_i==0 && FAMILY == "TRION")
				next_rstate_b = RAM_IDLE;
			else if (clke_b_i==0 && FAMILY == "TITANIUM")
				next_rstate_b = RAM_IDLE;
			else
				next_rstate_b = RAM_IDLE;
		end
		RAM_RVALID_RVALID: begin
			if(clke_b_i && ~we_b_i)
				next_rstate_b = RAM_RVALID_RVALID;
			else if (clke_b_i && we_b_i)
				next_rstate_b = (WRITE_MODE_B == "READ_FIRST" || WRITE_MODE_B == "WRITE_FIRST") ? RAM_RVALID_RVALID : (OUTPUT_REG_B ? RAM_IDLE_RVALID : RAM_IDLE);
			else if (clke_b_i)
				next_rstate_b = OUTPUT_REG_B ? RAM_IDLE_RVALID : RAM_IDLE;
			else if (clke_b_i==0 && FAMILY == "TRION")
				next_rstate_b = OUTPUT_REG_B ? RAM_IDLE_RVALID : RAM_IDLE;
			else if (clke_b_i==0 && FAMILY == "TITANIUM")
				next_rstate_b = OUTPUT_REG_B ? RAM_READ : RAM_IDLE;				
			else
				next_rstate_b = OUTPUT_REG_B ? RAM_READ : RAM_IDLE;
		end
		default: next_rstate_b = RAM_IDLE; 
	endcase
end

integer bcnt = 0;
always @(posedge clk_b_i) begin //verify WRITE_MODE
    if (((clke_b_r1 && OUTPUT_REG_B == 0) || ((rstate_b == RAM_IDLE_RVALID || rstate_b == RAM_RVALID_RVALID) && OUTPUT_REG_B == 1)) && state_b != 0) begin
        for(bcnt=0 ; bcnt<DWB ; bcnt=bcnt+1) begin
            if (final_exp_rdata_b[bcnt] === 1'bx) begin //TODO: add collision check
                //pass
            end else begin
                if (final_exp_rdata_b[bcnt] === rdata_b[bcnt]) begin
                	$display("%t ps - PASS! BRAM_B read data %h is match expected data %h ,bitwise %d", $time(), rdata_b[bcnt], final_exp_rdata_b[bcnt], bcnt);
                    	success_cnt_b = success_cnt_b + 1;
                end else begin
                    $error("%t ps - FAIL! BRAM_B read data %h doesn't match expected data %h ,bitwise %d", $time(), rdata_b[bcnt], final_exp_rdata_b[bcnt], bcnt);
                    $display("info: FAMILY: %s, MEMORY_TYPE: %s, WRITE_MODE_B: %s, ADDR_WIDTH_A: %d, DWB: %d, ADDR_WIDTH_B: %d, DWA: %d, GROUP_DATA_WIDTH_A: %d, GROUP_DATA_WIDTH_A: %d, GROUP_DATA_WIDTH_B: %d, ", FAMILY, MEMORY_TYPE, WRITE_MODE_B, ADDR_WIDTH_A, DWB, ADDR_WIDTH_B, DWA, GROUP_DATA_WIDTH_A, GROUP_DATA_WIDTH_A, GROUP_DATA_WIDTH_B);
                    #10 $stop;
                end
            end
        end
    end
end
endmodule
