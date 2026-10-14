`include "efx_bram_define.vh"

module bram_ed #(
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
 USER_LED0:  
    - if green means completed/done
    - no light means not started or in reset
 USER_LED1: 
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

generate
if(MEMORY_TYPE=="SP_RAM") begin
//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

logic				we;
logic				re;
logic				addren;
logic [ADDR_WIDTH_A-1:0]	addr;
logic [DATA_WIDTH_A-1:0]	wdata_a;
logic [DATA_WIDTH_A-1:0]	rdata_a;
logic [BYTEEN_WIDTH-1:0]	byteen;
logic				wclke;
logic				clk;
logic 				reset;

assign clk = pll_inst1_CLKOUT1;
assign reset = ~pll_inst1_LOCKED;

 efx_bram inst_memory (
	.addr(addr),
	.wdata_a(wdata_a),
	.rdata_a(rdata_a),
	.clk(clk),
	.*
 );

 mem_bist_sp_async #(
    .OUT_REG(OUTPUT_REG),
    .BYTEEN_WIDTH(BYTEEN_WIDTH),
    .ADDR_WIDTH_A(ADDR_WIDTH_A),
    .DATA_WIDTH_A(DATA_WIDTH_A)
 ) inst_bist (
	 //Clock and Control
	.clk(clk),
	.reset(reset),
	.start(~i_start_n),

	//Memory Interface//
	.we(we),
	.re(re),
	.adren(addren),
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

end

if(MEMORY_TYPE=="SDP_RAM") begin
//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

logic				we;
logic				re;
logic				waddren;
logic				raddren;
logic [ADDR_WIDTH_A-1:0]	waddr;
logic [ADDR_WIDTH_B-1:0]	raddr;
logic [DATA_WIDTH_A-1:0]	wdata_a;
logic [DATA_WIDTH_B-1:0]	rdata_b;
logic [BYTEEN_WIDTH-1:0]	byteen;
logic				wclke;
logic				clk;
logic				wclk;
logic				rclk;
logic 				reset;

assign clk = pll_inst1_CLKOUT1;
if(CLK_MODE == 1) begin
	assign wclk = pll_inst1_CLKOUT1;
	assign rclk = pll_inst1_CLKOUT1;
end
else begin
	assign wclk = pll_inst1_CLKOUT1;
	assign rclk = pll_inst1_CLKOUT2;
end
assign reset = ~pll_inst1_LOCKED;

 efx_bram inst_memory (
	.waddr(waddr),
	.wdata_a(wdata_a),
	.rdata_b(rdata_b),
	.raddr(raddr),
	.*
 );

 mem_bist_sdp_async #(
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
	.reset(reset),
	.start(~i_start_n),

	//Memory Interface//
	.we(we),
	.re(re),
	.wadren(waddren),
	.radren(raddren),
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

end

if(MEMORY_TYPE=="TDP_RAM") begin
//This example design is for full feature turn-on//	
//can only handle single RATIO-4 1:1//

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
logic				clke,clke_a,clke_b;
logic				reset_a,reset_b;
logic				clk,clk_a,clk_b;

assign reset_a = ~pll_inst1_LOCKED;
assign reset_b = ~pll_inst1_LOCKED;
assign clke    = 1'b1;

if(CLK_MODE == 1) begin
	assign clk = pll_inst1_CLKOUT1;
	assign clk_a = pll_inst1_CLKOUT1;
	assign clk_b = pll_inst1_CLKOUT1;
end
else begin
	assign clk = pll_inst1_CLKOUT1;
	assign clk_a = pll_inst1_CLKOUT1;
	assign clk_b = pll_inst1_CLKOUT2;	
end

 efx_bram inst_memory (
	.addr_a(addr_a),
	.addr_b(addr_b),
	.wdata_a(wdata_a),
	.wdata_b(wdata_b),
	.rdata_a(rdata_a),
	.rdata_b(rdata_b),
	.*
 );

 mem_bist_tdp_async #(
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
	.clk_a(clk_a),
	.clk_b(clk_b),
	.reset_a(reset_a),
	.reset_b(reset_b),
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
 
end
endgenerate

endmodule
