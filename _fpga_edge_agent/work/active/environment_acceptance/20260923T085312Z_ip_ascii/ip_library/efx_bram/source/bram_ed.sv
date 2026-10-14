
//`define TEST_SP_RAM
`define TEST_SDP_RAM
//`define TEST_TDP_RAM

module `IP_MODULE_NAME(bram_ed) #(
)   
(
	pll_inst1_CLKOUT1,
	pll_inst1_CLKOUT2,
	i_reset_n,	//active low - from GPIO (weak-pull-up) - GPIOL_11 (USER_BTN2) - SW7
	i_start_n,	//connect to GPIO to trigger start (weak-pull-up) - GPIOR_29 (USER_BTN3) - SW1

    user_led0_blue,
    user_led0_green,
    user_led0_red,
    
    user_led1_blue,
    user_led1_green,
    user_led1_red,
    
    pll_inst1_RSTN,     //connect to pll_inst1_RSTN
    pll_inst1_LOCKED   //connect to pll_inst1_LOCKED
 );

 /*
 USER_LED1:  
    - if green means completed/done
    - no light means not started or in reset
 USER_LED0: 
    - if red means fail
    - if green means pass
 */
 
input  pll_inst1_CLKOUT1;
input  pll_inst1_CLKOUT2;

input i_reset_n;
input i_start_n;

output user_led0_blue;
output user_led0_green;
output user_led0_red;

output user_led1_blue;
output user_led1_green;
output user_led1_red;
 
output pll_inst1_RSTN;
input  pll_inst1_LOCKED;

logic wclk;
logic rclk;

wire o_done;
wire o_pass;
wire o_fail;

assign user_led1_blue = 1'b0;
assign user_led1_green = o_pass;
assign user_led1_red = o_fail;

assign user_led0_blue = o_done;
assign user_led0_green = ~o_done & pll_inst1_LOCKED;
assign user_led0_red = 1'b0;

assign pll_inst1_RSTN = i_reset_n;
assign wclk = pll_inst1_CLKOUT1;
assign rclk = pll_inst1_CLKOUT2;

`ifdef TEST_SP_RAM
//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

`include "ip/bram_sp_mem/bram_sp_mem_define.vh"	

logic				we;
logic				re;
logic				adren;
logic [ADDR_WIDTH_A-1:0]	addr;
logic [DATA_WIDTH_A-1:0]	wdata_a;
logic [DATA_WIDTH_A-1:0]	rdata_a;
logic [BYTEEN_WIDTH-1:0]	byteen;
logic				wclke;

 bram_sp_mem inst_memory (
	.re(re),
	.we(we),
	.addren(adren),
	.reset(~pll_inst1_LOCKED),
	.addr(addr),
	.wdata_a(wdata_a),
	.rdata_a(rdata_a),
	.clk(wclk),
	.byteen(byteen),
	.wclke(wclke)
 );

 `IP_MODULE_NAME(mem_bist_sp_async) #(
    .OUT_REG(OUTPUT_REG),
    .BYTEEN_WIDTH(BYTEEN_WIDTH),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .DATA_WIDTH_A(DATA_WIDTH_A)
 ) inst_bist (
	 //Clock and Control
	.clk(wclk),
	.reset(~pll_inst1_LOCKED),
	.start(~i_start_n),

	//Memory Interface//
	.we(we),
	.re(re),
	.adren(adren),
	.addr(addr),
	.wdata_a(wdata_a),
	.rdata_a(rdata_a),
	.byteen(byteen),
	.wclke(wclke),

	//BIST status
	.done(o_done),
	.pass(o_pass),
	.fail(o_fail)

 );

`endif

`ifdef TEST_SDP_RAM

//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

`include "ip/bram_sdp_mem/bram_sdp_mem_define.vh"

logic				we;
logic				re;
logic				wadren;
logic				radren;
logic [ADDR_WIDTH_A-1:0]	waddr;
logic [ADDR_WIDTH_B-1:0]	raddr;
logic [DATA_WIDTH_A-1:0]	wdata_a;
logic [DATA_WIDTH_B-1:0]	rdata_b;
logic [BYTEEN_WIDTH-1:0]	byteen;
logic				wclke;

 bram_sdp_mem inst_memory (
	.re(re),
	.we(we),
	.waddren(wadren),
	.raddren(radren),
	.reset(~pll_inst1_LOCKED),
	.waddr(waddr),
	.wdata_a(wdata_a),
	.rdata_b(rdata_b),
	.raddr(raddr),
	.wclk(wclk),
	.rclk(rclk),
	.byteen(byteen),
	.wclke(wclke)
 );

 `IP_MODULE_NAME(mem_bist_sdp_async) #(
    .OUT_REG(OUTPUT_REG),
    .BYTEEN_WIDTH(BYTEEN_WIDTH),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_B(ADDR_WIDTH_B),
    .DATA_WIDTH_B(DATA_WIDTH_B)
 ) inst_bist (
	 //Clock and Control
	.wclk(wclk),
	.rclk(rclk),
	.reset(~pll_inst1_LOCKED),
	.start(~i_start_n),

	//Memory Interface//
	.we(we),
	.re(re),
	.wadren(wadren),
	.radren(radren),
	.waddr(waddr),
	.raddr(raddr),
	.wdata_a(wdata_a),
	.rdata_b(rdata_b),
	.byteen(byteen),
	.wclke(wclke),

	//BIST status
	.done(o_done),
	.pass(o_pass),
	.fail(o_fail)

 );

`endif


`ifdef TEST_TDP_RAM
//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

`include "ip/bram_tdp_mem/bram_tdp_mem_define.vh"	

logic				we_a,we_b;
logic				addren_a,addren_b;
logic [ADDR_WIDTH_A-1:0]	addr_a;
logic [ADDR_WIDTH_B-1:0]	addr_b;
logic [DATA_WIDTH_A-1:0]	wdata_a;
logic [DATA_WIDTH_B-1:0]	wdata_b;
logic [DATA_WIDTH_A-1:0]	rdata_a;
logic [DATA_WIDTH_B-1:0]	rdata_b;
logic [BYTEEN_WIDTH_A-1:0]	byteen_a;
logic [BYTEEN_WIDTH_B-1:0]	byteen_b;
logic				clke_a,clke_b;

 bram_tdp_mem inst_memory (
	.we_a(we_a),
	.we_b(we_b),
	.addren_a(addren_a),
	.addren_b(addren_b),
	.reset_a(~pll_inst1_LOCKED),
	.reset_b(~pll_inst1_LOCKED),
	.addr_a(addr_a),
	.addr_b(addr_b),
	.wdata_a(wdata_a),
	.wdata_b(wdata_b),
	.rdata_a(rdata_a),
	.rdata_b(rdata_b),
	.clk_a(wclk),
	.clk_b(rclk),
	.byteen_a(byteen_a),
	.byteen_b(byteen_b),
	.clke_a(clke_a),
	.clke_b(clke_b)
 );

 `IP_MODULE_NAME(mem_bist_tdp_async) #(
    .OUTPUT_REG_A(OUTPUT_REG_A),
    .OUTPUT_REG_B(OUTPUT_REG_B),
    .BYTEEN_WIDTH_A(BYTEEN_WIDTH_A),
    .BYTEEN_WIDTH_B(BYTEEN_WIDTH_B),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .DATA_WIDTH_A(DATA_WIDTH_A),
    .ADDR_WIDTH_B(ADDR_WIDTH_B),
    .DATA_WIDTH_B(DATA_WIDTH_B)
 ) inst_bist (
	 //Clock and Control
	.clk_a(wclk),
	.clk_b(rclk),
	.reset_a(~pll_inst1_LOCKED),
	.reset_b(~pll_inst1_LOCKED),
	.start(~i_start_n),

	//Memory Interface//
	.we_a(we_a),
	.we_b(we_b),
	.addren_a(addren_a),
	.addren_b(addren_b),
	.addr_a(addr_a),
	.addr_b(addr_b),
	.wdata_a(wdata_a),
	.wdata_b(wdata_b),
	.rdata_a(rdata_a),
	.rdata_b(rdata_b),
	.byteen_a(byteen_a),
	.byteen_b(byteen_b),
	.clke_a(clke_a),
	.clke_b(clke_b),

	//BIST status
	.done(o_done),
	.pass(o_pass),
	.fail(o_fail)

 );
 

`endif

endmodule
