
`resetall
`timescale 1ns/1ps

  module efx_fifo_wrapper(
			  //Output
			  almost_full_o,
			  prog_full_o,
			  full_o,
			  overflow_o,
			  wr_ack_o,
			  datacount_o,
			  wr_datacount_o,
			  empty_o,
			  almost_empty_o,
			  prog_empty_o,
			  underflow_o,
			  rd_valid_o,
			  rdata,
			  rd_datacount_o,
			  //Input
			  clk_i,
			  wr_clk_i,
			  rd_clk_i,
			  wr_en_i,
			  rd_en_i,
			  a_rst_i,
			  wdata);
//Parameter and localparam for ports declaration
   parameter SYNC_CLK	= 1;
   parameter DEPTH	= 512; //Must be power of 2
   parameter DATA_WIDTH	= 32;
   localparam WCNT_WIDTH	= depth2width(DEPTH); //Removed feature
   localparam RCNT_WIDTH	= depth2width(DEPTH); //Removed feature
   parameter MODE		= "STANDARD";
   parameter OUTPUT_REG		= 0;
   parameter PIPELINE_REG	= 1;
   parameter OPTIONAL_FLAGS	= 1;
   parameter PROGRAMMABLE_FULL	= "NONE";
   parameter PROG_FULL_ASSERT	= DEPTH;
   parameter PROG_FULL_NEGATE	= PROG_FULL_ASSERT;
   parameter PROGRAMMABLE_EMPTY	= "NONE";
   parameter PROG_EMPTY_ASSERT	= 0;
   parameter PROG_EMPTY_NEGATE	= PROG_EMPTY_ASSERT;

//Ports declaration
   //Output
   output wire 			almost_full_o;
   output wire 			prog_full_o;
   output wire 			full_o;
   output wire 			overflow_o;
   output wire 			wr_ack_o;
   output wire [WCNT_WIDTH-1:0] datacount_o;
   output wire [WCNT_WIDTH-1:0] wr_datacount_o;
   output wire 			empty_o;
   output wire 			almost_empty_o;
   output wire 			prog_empty_o;
   output wire 			underflow_o;
   output reg 			rd_valid_o;
   output wire [DATA_WIDTH-1:0] rdata;
   output wire [RCNT_WIDTH-1:0] rd_datacount_o;
   //Input
   input 			clk_i;
   input 			wr_clk_i;
   input 			rd_clk_i;
   input 			wr_en_i;
   input 			rd_en_i;
   input 			a_rst_i;
   input [DATA_WIDTH-1:0] 	wdata;
   
//Encryption begin
/*--------------------------------------------------------------*\
                       The main code
\*--------------------------------------------------------------*/
//--------------------------------------------------------------------
// Local Function
`include "efx_fifo_functions.vh"

//--------------------------------------------------------------------
// Masked Signals/Parameters
   //Start: Asymmetrical Width parameter calculation and signal assignment
   //Minimum RDATA_WIDTH stops at odd number
   localparam WR_DEPTH = DEPTH;         //Removed Asym Feature
   localparam WDATA_WIDTH = DATA_WIDTH; //Removed Asym Feature
   localparam RDATA_WIDTH = DATA_WIDTH; //Removed Asym Feature
   localparam RDATA_WIDTH_MIN	= (WDATA_WIDTH % 2) ? (WDATA_WIDTH) :
				  (WDATA_WIDTH % 4) ? (WDATA_WIDTH / 2) :
				  (WDATA_WIDTH % 8) ? (WDATA_WIDTH / 4) :
				                      (WDATA_WIDTH / 8);
   //Maximum RDATA_WIDTH depends on WR_DEPTH, minimum WR_DEPTH=16
   localparam RDATA_WIDTH_MAX	= ((WR_DEPTH < 32)  || (WR_DEPTH % 2)) ? (WDATA_WIDTH) :
				  ((WR_DEPTH < 64)  || (WR_DEPTH % 4)) ? (WDATA_WIDTH * 2) :
				  ((WR_DEPTH < 128) || (WR_DEPTH % 8)) ? (WDATA_WIDTH * 4) :
				                                         (WDATA_WIDTH * 8);
   //Filter input RDATA_WIDTH to fit 8:1, 4:1, 2:1, 1:1, 1:2, 1:4, 1:8 W/R ratio
   //Smaller input RDATA_WIDTH will match to larger effective width, max 8*WDATA_WIDTH
   localparam RDATA_WIDTH_EFF	= (RDATA_WIDTH <= RDATA_WIDTH_MIN) ? RDATA_WIDTH_MIN :
				  (RDATA_WIDTH >  RDATA_WIDTH_MAX) ? RDATA_WIDTH_MAX :
				  (RDATA_WIDTH <= WDATA_WIDTH/4) ? WDATA_WIDTH/4 :
				  (RDATA_WIDTH <= WDATA_WIDTH/2) ? WDATA_WIDTH/2 :
				  (RDATA_WIDTH <= WDATA_WIDTH)   ? WDATA_WIDTH :
				  (RDATA_WIDTH <= WDATA_WIDTH*2) ? WDATA_WIDTH*2 :
				  (RDATA_WIDTH <= WDATA_WIDTH*4) ? WDATA_WIDTH*4 :
				                                   WDATA_WIDTH*8;
   localparam WADDR_WIDTH	= depth2width(WR_DEPTH);
   localparam ASYM_WIDTH	= (WDATA_WIDTH !== RDATA_WIDTH_EFF);
   localparam RD_DEPTH		= WR_DEPTH * WDATA_WIDTH / RDATA_WIDTH_EFF;
   localparam RADDR_WIDTH	= depth2width(RD_DEPTH);
   //localparam DATA_WIDTH_RATIO;

   wire [WADDR_WIDTH-1:0] wr_adr_o;
   wire [RADDR_WIDTH-1:0] rd_adr_o;
   wire 		  rd_ram, wr_ram;
   wire [RDATA_WIDTH_EFF-1:0] rdata_int; //Internal rdata
   //If RDATA_WIDTH is configured correctly, rdata should take the correct value
   //If not, either MSB of rdata_int is masked, or MSB of rdata is unassigned
   assign rdata = rdata_int;
   //End: Asymmetrical Width parameter calculation and signal assignment

   wire rd_valid_int; //Internal rd_valid
generate
   if (OUTPUT_REG == 1)
     if (SYNC_CLK == 0)
       always @(posedge rd_clk_i)
	 rd_valid_o <= rd_valid_int;
     else /* (SYNC_CLK == 1) */
       always @(posedge clk_i)
	 rd_valid_o <= rd_valid_int;
   else /* (OUTPUT_REG == 0) */
     always @(*)
       rd_valid_o = rd_valid_int;
endgenerate

   //Start: datacount_o signal assignment
   //If user input width < log2(fifo_depth)-1, LSB will be truncated
   //Internal datacounts
   wire [WADDR_WIDTH-1:0] datacount_int;
   wire [WADDR_WIDTH-1:0] wr_datacount_int;
   wire [RADDR_WIDTH-1:0] rd_datacount_int;

generate
   if (WCNT_WIDTH < WADDR_WIDTH) begin
      assign datacount_o = datacount_int[WADDR_WIDTH:WADDR_WIDTH-WCNT_WIDTH];
      assign wr_datacount_o = wr_datacount_int[WADDR_WIDTH:WADDR_WIDTH-WCNT_WIDTH];
   end
   else begin
      assign datacount_o = datacount_int;
      assign wr_datacount_o = wr_datacount_int;
   end

   if (RCNT_WIDTH < RADDR_WIDTH) begin
      assign rd_datacount_o = rd_datacount_int[RADDR_WIDTH:RADDR_WIDTH-RCNT_WIDTH];
   end
   else begin
      assign rd_datacount_o = rd_datacount_int;
   end
endgenerate
   //End: Datacount_o signal assignment

//--------------------------------------------------------------------
// Module Instantiation
// Read/Write Domain State Machine and Flags
generate begin : fifo_ctl
   if (SYNC_CLK == 1)
   efx_syncfifo_ctl #(
		      // Parameters
		      .SYNC_CLK		  (SYNC_CLK),
		      .WR_DEPTH		  (WR_DEPTH),
		      .RD_DEPTH		  (RD_DEPTH),
		      .WADDR_WIDTH	  (WADDR_WIDTH),
		      .RADDR_WIDTH	  (RADDR_WIDTH),
		      .ASYM_WIDTH	  (ASYM_WIDTH),
		      .MODE		  (MODE),
		      .OPTIONAL_FLAGS	  (OPTIONAL_FLAGS),
		      .PROGRAMMABLE_FULL  (PROGRAMMABLE_FULL),
		      .PROG_FULL_ASSERT	  (PROG_FULL_ASSERT),
		      .PROG_FULL_NEGATE   (PROG_FULL_NEGATE),
		      .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY),
		      .PROG_EMPTY_ASSERT  (PROG_EMPTY_ASSERT),
		      .PROG_EMPTY_NEGATE  (PROG_EMPTY_NEGATE))
   u_efx_syncfifo_ctl (
		       // Outputs
		       .empty_o		(empty_o),
		       .almost_empty_o	(almost_empty_o),
		       .prog_empty_o	(prog_empty_o),
		       .underflow_o	(underflow_o),
		       .full_o		(full_o),
		       .almost_full_o	(almost_full_o),
		       .prog_full_o	(prog_full_o),
		       .overflow_o	(overflow_o),
		       .wr_adr_o	(wr_adr_o),
		       .rd_adr_o	(rd_adr_o),
		       .wr_ack_o	(wr_ack_o),
		       .wr_ram	        (wr_ram),
		       .rd_valid_o	(rd_valid_int),
		       .rd_ram	        (rd_ram),
		       .datacount_o	(datacount_int),
		       // Inputs
		       .clk_i		(clk_i),
		       .a_rst_i		(a_rst_i),
		       .wr_en_i		(wr_en_i),
		       .rd_en_i		(rd_en_i));
   else /* (SYNC_CLK == 0) */
   efx_asyncfifo_ctl #(
		       // Parameters
		       .SYNC_CLK	   (SYNC_CLK),
		       .WR_DEPTH	   (WR_DEPTH),
		       .RD_DEPTH	   (RD_DEPTH),
		       .WADDR_WIDTH	   (WADDR_WIDTH),
		       .RADDR_WIDTH	   (RADDR_WIDTH),
		       .ASYM_WIDTH	   (ASYM_WIDTH),
		       .MODE		   (MODE),
		       .PIPELINE_REG	   (PIPELINE_REG),
		       .OPTIONAL_FLAGS	   (OPTIONAL_FLAGS),
		       .PROGRAMMABLE_FULL  (PROGRAMMABLE_FULL),
		       .PROG_FULL_ASSERT   (PROG_FULL_ASSERT),
		       .PROG_FULL_NEGATE   (PROG_FULL_NEGATE),
		       .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY),
		       .PROG_EMPTY_ASSERT  (PROG_EMPTY_ASSERT),
		       .PROG_EMPTY_NEGATE  (PROG_EMPTY_NEGATE))
   u_efx_asyncfifo_ctl (
			// Outputs
			.wr_almost_full_o  (almost_full_o),
			.wr_prog_full_o	   (prog_full_o),
			.wr_full_o	   (full_o),
			.overflow_o	   (overflow_o),
			.wr_adr_o	   (wr_adr_o),
			.wr_ack_o	   (wr_ack_o),
			.wr_ram		   (wr_ram),
			.wr_datacount_o	   (wr_datacount_int),
			.rd_empty_o	   (empty_o),
			.rd_almost_empty_o (almost_empty_o),
			.rd_prog_empty_o   (prog_empty_o),
			.underflow_o	   (underflow_o),
			.rd_adr_o	   (rd_adr_o),
			.rd_valid_o	   (rd_valid_int),
			.rd_ram		   (rd_ram),
			.rd_datacount_o	   (rd_datacount_int),
			// Inputs
			.wr_clk_i	   (wr_clk_i),
			.wr_en_i	   (wr_en_i),
			.rd_clk_i	   (rd_clk_i),
			.rd_en_i	   (rd_en_i),
			.a_rst_i	   (a_rst_i));
end
endgenerate

// RAM instantiation
generate begin : ram
   if (SYNC_CLK == 1)
   simple_dual_port_ram_fifo
     #( // Parameters
	.SYNC_CLK	(SYNC_CLK),
	.WR_DEPTH	(WR_DEPTH),
	.RD_DEPTH	(RD_DEPTH),
   	.WDATA_WIDTH	(WDATA_WIDTH),
   	.RDATA_WIDTH	(RDATA_WIDTH_EFF),
   	.WADDR_WIDTH	(WADDR_WIDTH),
   	.RADDR_WIDTH	(RADDR_WIDTH),
   	.OUTPUT_REG	(OUTPUT_REG),
	.ASYM_WIDTH	(ASYM_WIDTH),
   	.MODE		(MODE))
   u_simple_dual_port_ram_fifo
     ( // Outputs
       .rdata		(rdata_int),
       // Inputs
       .wdata		(wdata),
       .waddr		(wr_adr_o),
       .raddr		(rd_adr_o),
       .we		(wr_ram),
       .re		(rd_ram),
       .clk		(clk_i),
       .wclk		(1'b0),
       .rclk		(1'b0));

   else /* (SYNC_CLK == 0) */
   simple_dual_port_ram_fifo
     #( // Parameters
	.SYNC_CLK	(SYNC_CLK),
	.WR_DEPTH	(WR_DEPTH),
	.RD_DEPTH	(RD_DEPTH),
   	.WDATA_WIDTH	(WDATA_WIDTH),
   	.RDATA_WIDTH	(RDATA_WIDTH_EFF),
   	.WADDR_WIDTH	(WADDR_WIDTH),
   	.RADDR_WIDTH	(RADDR_WIDTH),
   	.OUTPUT_REG	(OUTPUT_REG),
	.ASYM_WIDTH	(ASYM_WIDTH),
   	.MODE		(MODE))
   u_simple_dual_port_ram_fifo
     ( // Outputs
       .rdata		(rdata_int),
       // Inputs
       .wdata		(wdata),
       .waddr		(wr_adr_o),
       .raddr		(rd_adr_o),
       .we		(wr_ram),
       .re		(rd_ram),
       .clk		(1'b0),
       .wclk		(wr_clk_i),
       .rclk		(rd_clk_i));
end
endgenerate
   
endmodule   









module efx_asyncfifo_ctl
#(
  parameter SYNC_CLK		= 0,
  parameter WR_DEPTH		= 1025,
  parameter RD_DEPTH		= 1025,
  parameter WADDR_WIDTH		= depth2width(WR_DEPTH),
  parameter RADDR_WIDTH		= depth2width(RD_DEPTH),
  parameter ASYM_WIDTH		= 0,
  parameter MODE		= "STANDARD",
  parameter PIPELINE_REG	= 1,
  parameter OPTIONAL_FLAGS	= 1,
  parameter PROGRAMMABLE_FULL	= "NONE",
  parameter PROG_FULL_ASSERT	= 1024,
  parameter PROG_FULL_NEGATE	= 1025,
  parameter PROGRAMMABLE_EMPTY	= "NONE",
  parameter PROG_EMPTY_ASSERT	= 1,
  parameter PROG_EMPTY_NEGATE	= 0
)
(// output
 output wire 		       wr_almost_full_o,
 output wire 		       wr_prog_full_o,
 output wire 		       wr_full_o,
 output reg 		       overflow_o,
 output reg [WADDR_WIDTH-1:0]  wr_adr_o,
 output reg 		       wr_ack_o,
 output wire 		       wr_ram,
 output wire [WADDR_WIDTH-1:0] wr_datacount_o,
 output wire 		       rd_empty_o,
 output wire 		       rd_almost_empty_o,
 output wire 		       rd_prog_empty_o,
 output reg 		       underflow_o,
 output reg [RADDR_WIDTH-1:0]  rd_adr_o,
 output reg 		       rd_valid_o,
 output wire 		       rd_ram,
 output wire [RADDR_WIDTH-1:0] rd_datacount_o,
 // input    
 input 			       wr_clk_i,
 input 			       wr_en_i,
 input 			       rd_clk_i,
 input 			       rd_en_i,
 input 			       a_rst_i);
//--------------------------------------------------------------------
// Local Function
`include "efx_fifo_functions.vh"

//--------------------------------------------------------------------
// Masked Signals
   wire 	      wr_empty_o, wr_almost_empty_o, wr_prog_empty_o, wr_half_full_o;
   wire 	      rd_almost_full_o, rd_prog_full_o, rd_full_o, rd_half_full_o;
//--------------------------------------------------------------------
// Local Parameters
   localparam WMAX_ADDR = (WR_DEPTH-1);
   localparam RMAX_ADDR = (RD_DEPTH-1);
   localparam WR_SYNC=2;
   localparam RD_SYNC=2;

//--------------------------------------------------------------------
// Local Signals
   wire [RADDR_WIDTH-1:0] rd_adr_int;       //Internal read address
   wire 		  rd_empty_int;
   reg 			  rd_first = 1'b0;
   wire [WADDR_WIDTH-1:0] wr_adr_gray, wr_adr_gray_sync, wr_adr_sync;
   wire [RADDR_WIDTH-1:0] rd_adr_gray, rd_adr_gray_sync, rd_adr_sync;
   // reg  [WADDR_WIDTH-1:0] wr_adr_sync_reg; //Pipelined Sync Addr if enabled
   // reg  [RADDR_WIDTH-1:0] rd_adr_sync_reg; //Pipelined Sync Addr if enabled

//--------------------------------------------------------------------
// Writing and Reading is allowed only for valid operations. That
// is you can not write more into a full FIFO nor can you read
// an empty FIFO.
// Logic for writing and reading ram, wr_ram & rd_ram
   assign wr_ram = (wr_en_i & ~wr_full_o);

generate
   if (MODE == "STANDARD") begin
      assign rd_empty_o = rd_empty_int;
      assign rd_ram = (rd_en_i  & ~rd_empty_o);

      assign rd_adr_int = rd_adr_o;
   end
   else /* (MODE == "FWFT") */ begin : rd_fwft_compensate
      assign rd_empty_o = rd_first ? 1'b1 : rd_empty_int;

      //Can't read when datacount = 1
      //Auto read at next clock cycle if empty for first write
      assign rd_ram = (rd_en_i & ~rd_empty_o & (rd_datacount_o != 1)) |
     		      (rd_first & ~rd_empty_int);

      always @(posedge rd_clk_i)
	if (rd_empty_int)
	  rd_first <= 1'b1;
	else if (rd_first)
	  rd_first <= 1'b0;
	else if (rd_datacount_o == {{RADDR_WIDTH-1{1'b0}}, 1'b1} && rd_en_i)
	  rd_first <= 1'b1;

      //rd_adr in FWFT will auto-increment for the first word, hence need to
      // compensate that extra word lost.
      reg datacount_minus;	//Word compensation for FWFT
      if (RD_DEPTH == 2**RADDR_WIDTH)
	assign rd_adr_int = rd_adr_o - datacount_minus;
      else
	assign rd_adr_int = (datacount_minus && (rd_adr_o == {RADDR_WIDTH{1'b0}})) ?
			    RMAX_ADDR : rd_adr_o - datacount_minus;

      always @(posedge rd_clk_i, posedge a_rst_i) begin
	 if (a_rst_i) begin
	    datacount_minus <= 1'b0;
	 end
	 else if (rd_first && ~rd_empty_int) begin
	    datacount_minus  <= 1'b1;
	 end
	 else if (rd_datacount_o == {{RADDR_WIDTH-1{1'b0}},1'b1} && rd_en_i) begin
	    datacount_minus <= 1'b0;
	 end
      end
   end
endgenerate
   
//--------------------------------------------------------------------
// Write Address Counter and optional wr_ack_o Signal
generate
   if (OPTIONAL_FLAGS == 1)
     always @(posedge wr_clk_i, posedge a_rst_i)
       if (a_rst_i)
	 wr_ack_o <= 1'b0;
       else
	 wr_ack_o <= wr_ram;
endgenerate

always @(posedge wr_clk_i, posedge a_rst_i)
  begin
     if(a_rst_i)
       wr_adr_o <= {WADDR_WIDTH{1'b0}};
     else
       if (wr_ram)
	 if(wr_adr_o==WMAX_ADDR)
           wr_adr_o <= {WADDR_WIDTH{1'b0}};
	 else
           wr_adr_o <= wr_adr_o + 1'b1;
  end

// Convert Write address to Gray to sync with Read Domain
bin2gray
  #(.WIDTH(WADDR_WIDTH))
  u_wr_adr_gray(.gray_o(wr_adr_gray),.bin_i(wr_adr_o),.clk_i(wr_clk_i));
// sync to rd_clk_i
pipe_reg
  #(.DEPTH(RD_SYNC),.WIDTH(WADDR_WIDTH))
  u_wr_adr_graysync(.d_o(wr_adr_gray_sync),.d_i(wr_adr_gray),.clk_i(rd_clk_i));
// convert back to binary
gray2bin
  #(.WIDTH(WADDR_WIDTH))
  u_wr_adr_sync(.bin_o(wr_adr_sync),.gray_i(wr_adr_gray_sync));
//Introduced to reduce logic required for FWFT rd_datacount_o

wire wr_adr_change;
generate
    if (PIPELINE_REG == 1) begin : wr_adr_change_gen
        reg [WADDR_WIDTH-1:0] wr_adr_gray_reg;
        always @(posedge rd_clk_i)
          wr_adr_gray_reg <= wr_adr_gray;

        if (RD_SYNC >= 1) begin
            reg wr_adr_change_reg;
            always @(posedge rd_clk_i)
              wr_adr_change_reg <= (wr_adr_gray != wr_adr_gray_reg);

            if (RD_SYNC > 1)
                pipe_reg
                    #(.DEPTH(RD_SYNC-1),.WIDTH(1))
                    u_wr_adr_graysync(.d_o(wr_adr_change),.d_i(wr_adr_change_reg),.clk_i(rd_clk_i));
            else
                assign wr_adr_change = wr_adr_change_reg;
        end
        else
            assign wr_adr_change = (wr_adr_gray != wr_adr_gray_reg);
    end
endgenerate

// generate
//    if (PIPELINE_REG == 0) begin
//       always @(*)
// 	wr_adr_sync_reg = wr_adr_sync;
//    end
//    else /* (PIPELINE_REG == 1) */ begin
//       always @(posedge rd_clk_i)
// 	  wr_adr_sync_reg <= wr_adr_sync;
//    end
// endgenerate

//--------------------------------------------------------------------
// Read Address Counter and rd_valid_o Signal
generate
   if (OPTIONAL_FLAGS == 1)
     if (MODE == "STANDARD") begin
	always @(posedge rd_clk_i, posedge a_rst_i)
	  if (a_rst_i) begin
	     rd_valid_o <= 1'b0;
	  end
	  else begin
	     rd_valid_o <= rd_ram;
	  end
     end
     else /* (MODE == "FWFT") */  begin
	always @(*)
	  rd_valid_o = ~rd_empty_o;
     end
endgenerate

   always @(posedge rd_clk_i, posedge a_rst_i)
     if (a_rst_i) begin
	rd_adr_o <= {RADDR_WIDTH{1'b0}};
     end
     else begin
	if (rd_ram)
	  if(rd_adr_o==RMAX_ADDR)
	    rd_adr_o <= {RADDR_WIDTH{1'b0}};
	  else
	    rd_adr_o <= rd_adr_o + 1'b1;
     end
   
// Convert Read address to Gray to sync with Write Domain
bin2gray
  #(.WIDTH(RADDR_WIDTH))
  u_rd_adr_gray(.gray_o(rd_adr_gray),.bin_i(rd_adr_int),.clk_i(rd_clk_i));
// sync to wr_clk_i
pipe_reg
  #(.DEPTH(WR_SYNC),.WIDTH(RADDR_WIDTH))
  u_rd_adr_graysync(.d_o(rd_adr_gray_sync),.d_i(rd_adr_gray),.clk_i(wr_clk_i));
// convert back to binary
gray2bin
  #(.WIDTH(RADDR_WIDTH))
  u_rd_adr_sync(.bin_o(rd_adr_sync),.gray_i(rd_adr_gray_sync));

wire rd_adr_change;
generate
    if (PIPELINE_REG == 1) begin : rd_adr_change_gen
        reg [RADDR_WIDTH-1:0] rd_adr_gray_reg;
        always @(posedge wr_clk_i)
          rd_adr_gray_reg <= rd_adr_gray;

        if (WR_SYNC >= 1) begin
            reg rd_adr_change_reg;
            always @(posedge wr_clk_i)
              rd_adr_change_reg <= (rd_adr_gray != rd_adr_gray_reg);

            if (WR_SYNC > 1)
                pipe_reg
                    #(.DEPTH(WR_SYNC-1),.WIDTH(1))
                    u_rd_adr_graysync(.d_o(rd_adr_change),.d_i(rd_adr_change_reg),.clk_i(wr_clk_i));
            else
                assign rd_adr_change = rd_adr_change_reg;
        end
        else
            assign rd_adr_change = (rd_adr_gray != rd_adr_gray_reg);
    end
endgenerate

// generate
//    if (PIPELINE_REG == 0) begin
//       always @(*)
// 	rd_adr_sync_reg = rd_adr_sync;
//    end
//    else /* (PIPELINE_REG == 1) */ begin
//       always @(posedge wr_clk_i)
// 	  rd_adr_sync_reg <= rd_adr_sync;
//    end
// endgenerate

//--------------------------------------------------------------------
// Compute Wr & Rd Flags
   efx_fifo_ctl_sm #(//Parameter
		     .SYNC_CLK		 (SYNC_CLK),
		     .DEPTH		 (WR_DEPTH),
		     .ADDR_WIDTH	 (WADDR_WIDTH),
		     .MODE		 (MODE),
		     .OPTIONAL_FLAGS	 (OPTIONAL_FLAGS),
		     .PROGRAMMABLE_FULL	 (PROGRAMMABLE_FULL),
		     .PROG_FULL_ASSERT	 (PROG_FULL_ASSERT),
		     .PROG_FULL_NEGATE	 (PROG_FULL_NEGATE),
		     .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY), 
		     .PROG_EMPTY_ASSERT	 (PROG_EMPTY_ASSERT),
		     .PROG_EMPTY_NEGATE	 (PROG_EMPTY_NEGATE),
		     .PIPELINE_REG	 (PIPELINE_REG),
		     .DOMAIN		 ("WRITE"))
   u_wrflags(
	     // Outputs
	     .empty_o		(wr_empty_o),
	     .almost_empty_o	(wr_almost_empty_o),
	     .prog_empty_o	(wr_prog_empty_o),
	     .half_full_o	(wr_half_full_o),
	     .almost_full_o	(wr_almost_full_o),
	     .prog_full_o	(wr_prog_full_o),
	     .full_o		(wr_full_o),
	     .datacount_o	(wr_datacount_o),
	     // Inputs
	     .wr_adr_i		(wr_adr_o),
	     .rd_adr_i		(rd_adr_sync),
	     .clk_i		(wr_clk_i),
	     .a_rst_i		(a_rst_i),
	     .wr_ram		(wr_ram),
	     .rd_ram		(rd_adr_change),
	     .rd_en_i		(1'b0));

   efx_fifo_ctl_sm #(//Parameter
		     .SYNC_CLK		 (SYNC_CLK),
		     .DEPTH		 (RD_DEPTH),
		     .ADDR_WIDTH	 (RADDR_WIDTH),
		     .MODE		 (MODE),
		     .OPTIONAL_FLAGS	 (OPTIONAL_FLAGS),
		     .PROGRAMMABLE_FULL	 (PROGRAMMABLE_FULL),
		     .PROG_FULL_ASSERT	 (PROG_FULL_ASSERT),
		     .PROG_FULL_NEGATE	 (PROG_FULL_NEGATE),
		     .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY), 
		     .PROG_EMPTY_ASSERT	 (PROG_EMPTY_ASSERT),
		     .PROG_EMPTY_NEGATE	 (PROG_EMPTY_NEGATE),
		     .PIPELINE_REG	 (PIPELINE_REG),
		     .DOMAIN		 ("READ"))
   u_rdflags(
	     // Outputs
	     .empty_o		(rd_empty_int),
	     .almost_empty_o	(rd_almost_empty_o),
	     .prog_empty_o	(rd_prog_empty_o),
	     .half_full_o	(rd_half_full_o),
	     .almost_full_o	(rd_almost_full_o),
	     .prog_full_o	(rd_prog_full_o),
	     .full_o		(rd_full_o),
	     .datacount_o	(rd_datacount_o),
	     // Inputs
	     .wr_adr_i		(wr_adr_sync),
	     .rd_adr_i		(rd_adr_int),
	     .clk_i		(rd_clk_i),
	     .a_rst_i		(a_rst_i),
	     .wr_ram		(wr_adr_change),
	     .rd_ram		(rd_ram && ~rd_first),
	     .rd_en_i		(rd_en_i));

//Optional error signals
generate
   if (OPTIONAL_FLAGS == 1) begin
      always @(posedge wr_clk_i) begin
	 overflow_o <= wr_full_o & wr_en_i;
      end
      always @(posedge rd_clk_i) begin
	 underflow_o <= rd_empty_o & rd_en_i;
      end
   end
endgenerate

endmodule





module efx_fifo_ctl_sm
#(parameter SYNC_CLK		= 1,
  parameter DEPTH		= 1025,
  parameter ADDR_WIDTH		= depth2width(DEPTH),
  parameter MODE		= "STANDARD",
  parameter OPTIONAL_FLAGS	= 1,
  parameter PROGRAMMABLE_FULL	= "NONE",
  parameter PROG_FULL_ASSERT	= 1024,
  parameter PROG_FULL_NEGATE	= 1025,
  parameter PROGRAMMABLE_EMPTY	= "NONE",
  parameter PROG_EMPTY_ASSERT	= 1,
  parameter PROG_EMPTY_NEGATE	= 0,
  parameter PIPELINE_REG	= 1,
  parameter DOMAIN		= "WRITE")
(// output
 output reg 		      empty_o,
 output wire 		      almost_empty_o,
 output wire 		      prog_empty_o,
 output reg 		      half_full_o,
 output reg 		      full_o,
 output wire 		      almost_full_o,
 output wire 		      prog_full_o,
 output wire [ADDR_WIDTH-1:0] datacount_o,
 // input
 input [ADDR_WIDTH-1:0]       wr_adr_i,
 input [ADDR_WIDTH-1:0]       rd_adr_i,
 input 			      clk_i,
 input 			      a_rst_i,
 input 			      wr_ram,
 input 			      rd_ram,
 input 			      rd_en_i);
//--------------------------------------------------------------------
// Local functions
`include "efx_fifo_functions.vh"

// //--------------------------------------------------------------------
// Local Parameters
   localparam [ADDR_WIDTH-1:0] MAX_ADDR   = DEPTH-1;
   localparam HALF_DEPTH = DEPTH>>1;
   localparam EMPTY_ST   = 0; // State: empty
   localparam LT_HF_ST   = 1; // State: less than Half Full
   localparam GTE_HF_ST  = 2; // State: greater than or equal half full
   localparam FULL_ST    = 3; // State: full
   localparam [ADDR_WIDTH-1:0] FULL_COUNT = 0;
					 //(MODE=="STANDARD") ? 0 : 1;
   //FWFT will have one extra word
   //At this point we don't care the extra word introduced and it'll have
   // the same max datacount_o as Standard Mode, due to the complexity of
   // the state machine and flags if included. It'll be nice to have so as
   // to utilize the maximum Depth till wr_adr=rd_adr, however it's not an
   // important feature to be included at the moment.
   localparam MAXSPEED_DIV = ADDR_WIDTH;
   localparam CALC_WIDTH = (ADDR_WIDTH > depth2width(MAXSPEED_DIV)) ? depth2width(MAXSPEED_DIV) : ADDR_WIDTH;

//--------------------------------------------------------------------
// Local Signals
   reg [ADDR_WIDTH-1:0]      datacount_up;
   wire [ADDR_WIDTH-1:0]      datacount_dn;
   reg [1:0] 		 curr_st, next_st;

//--------------------------------------------------------------------
// Compute Word Count.  Word count is the number of words in the
// FIFO. Note that a depth with a power of 2 produces less logic

//    wire [ADDR_WIDTH-1:0] datacount_up_ideal;
// generate
//    if (SYNC_CLK == 1 || PIPELINE_REG == 0)
//      assign datacount_up_ideal = wr_adr_i - rd_adr_i;
//    else if (SYNC_CLK == 0 && PIPELINE_REG == 1) begin
//       reg [ADDR_WIDTH-1:0] wr_adr_reg;
//       reg [ADDR_WIDTH-1:0] rd_adr_reg;
//       assign datacount_up_ideal = wr_adr_reg - rd_adr_reg;
//       if (DOMAIN == "WRITE") begin
// 	 always @(*) wr_adr_reg = wr_adr_i;
// 	 always @(posedge clk_i)
// 	   rd_adr_reg <= rd_adr_i;
//       end
//       else if (DOMAIN == "READ") begin
// 	 always @(*) rd_adr_reg = rd_adr_i;
// 	 always @(posedge clk_i)
// 	   wr_adr_reg <= wr_adr_i;
//       end
//   end
// endgenerate
//    wire 		 compare_ideal;
//    assign compare_ideal = datacount_up_ideal != datacount_up;

   reg 	count_one;
   wire read_last;
generate
   if (MODE == "FWFT" && (SYNC_CLK == 1 || DOMAIN != "WRITE")) begin
      assign read_last = count_one && rd_en_i;
      always @(posedge clk_i) begin
      	 count_one <= (datacount_up == {{ADDR_WIDTH-2{1'b0}},2'b10} && ~wr_ram && rd_ram) ||
      		      (datacount_up == {{ADDR_WIDTH-1{1'b0}},1'b1} && ~wr_ram && ~read_last);// || (empty_o && wr_ram);
      end
   end
endgenerate

generate
   if (SYNC_CLK == 1) begin
      always @(posedge clk_i, posedge a_rst_i) begin
      	 if (a_rst_i)
      	   datacount_up <= {ADDR_WIDTH{1'b0}};
      	 else if (wr_ram) begin
      	    datacount_up <= datacount_up + 1'b1;
      	    if (rd_ram || (read_last && (MODE == "FWFT")))
      	      datacount_up <= datacount_up;
      	    else if (DEPTH != 2**ADDR_WIDTH)
      	      if (datacount_up == MAX_ADDR)
      		datacount_up <= {ADDR_WIDTH{1'b0}};
      	 end
      	 else if (rd_ram) begin
      	    datacount_up <= datacount_up - 1'b1;
      	    if (DEPTH != 2**ADDR_WIDTH)
      	      if (full_o)
      		datacount_up <= MAX_ADDR;
      	 end
      	 //This only applies to FWFT, Standard won't go into this
      	 // since when datacount=1 and rd_en_i, rd_ram will be high
      	 else if (MODE == "FWFT")
           if (read_last)
             datacount_up <= {ADDR_WIDTH{1'b0}};
      end
   end
   else if (SYNC_CLK == 0) begin
      if (PIPELINE_REG == 0)
	always @(*) datacount_up = wr_adr_i - rd_adr_i;
      else if (PIPELINE_REG == 1) begin
	 if (DOMAIN == "WRITE") begin
	    wire [ADDR_WIDTH-1:0] datacount_logic;
	    assign datacount_logic = (wr_adr_i - rd_adr_i) + wr_ram;

	    always @(posedge clk_i, posedge a_rst_i) begin
	       if (a_rst_i) begin
	    	  datacount_up <= {ADDR_WIDTH{1'b0}};
	       end
	       else begin
		  if (DEPTH == 2**ADDR_WIDTH)
	    	    datacount_up <= datacount_logic;
	    	  else begin
		     datacount_up <= (wr_adr_i >= rd_adr_i) ?
				     datacount_logic :
				     datacount_logic - ({ADDR_WIDTH{1'b1}} - MAX_ADDR);
	    	     if ((datacount_up == MAX_ADDR) && wr_ram && ~rd_ram)
	    	       datacount_up <= {ADDR_WIDTH{1'b0}};
		  end
	       end
	    end

	    // reg [ADDR_WIDTH-1:0] datacount_up_test;
	    // wire 		 compare;
	    // assign compare = datacount_up_test != datacount_up;

	    // reg [ADDR_WIDTH-1:0] rd_adr_reg; //ALT
            // wire [CALC_WIDTH:0]  rd_adr_diff; //ALT
            // assign rd_adr_diff = {1'b1,rd_adr_i[CALC_WIDTH-1:0]} - rd_adr_reg[CALC_WIDTH-1:0]; //ALT

	    // always @(posedge clk_i, posedge a_rst_i) begin
	    //    if (a_rst_i) begin
	    // 	  datacount_up_test <= {ADDR_WIDTH{1'b0}};
	    // 	  rd_adr_reg <= {ADDR_WIDTH{1'b0}}; //ALT
	    //    end
	    //    else begin
	    // 	  rd_adr_reg <= rd_adr_i; //ALT
	    // 	  datacount_up_test <= datacount_up_test + wr_ram - rd_adr_diff[CALC_WIDTH-1:0]; //ALT
	    // 	  //datacount_up_test <= (wr_adr_i - rd_adr_i) + wr_ram;
	    // 	  if (DEPTH != 2**ADDR_WIDTH)
	    // 	    if ((datacount_up_test == MAX_ADDR) && wr_ram && ~rd_ram)
	    // 	      datacount_up_test <= {ADDR_WIDTH{1'b0}};
	    // 	    else if (full_o && rd_ram) //ALT
	    // 	      datacount_up_test <= MAX_ADDR - rd_adr_diff[CALC_WIDTH-1:0] + 1'b1; //ALT
	    //    end
	    // end
	 end
	 else if (DOMAIN == "READ") begin
	    wire [ADDR_WIDTH-1:0] datacount_logic;
	    assign datacount_logic = (wr_adr_i - rd_adr_i) - (rd_ram || (read_last && (MODE == "FWFT")));

	    always @(posedge clk_i, posedge a_rst_i) begin
	       if (a_rst_i) begin
	    	  datacount_up <= {ADDR_WIDTH{1'b0}};
	       end
	       else begin
		  if (DEPTH == 2**ADDR_WIDTH)
	    	    datacount_up <= datacount_logic;
	    	  else begin
		     datacount_up <= (wr_adr_i >= rd_adr_i) ?
				     datacount_logic :
				     datacount_logic - ({ADDR_WIDTH{1'b1}} - MAX_ADDR);
		     if (full_o && rd_ram)
	    	       datacount_up <= MAX_ADDR;
		  end
	       end
	    end
	 end
      end
   end
endgenerate

generate
   if (SYNC_CLK == 0 && PIPELINE_REG == 0) begin
      assign datacount_dn = (wr_adr_i - rd_adr_i) - ({ADDR_WIDTH{1'b1}} - MAX_ADDR);
      assign datacount_o = rd_adr_i > wr_adr_i ? datacount_dn : datacount_up;
   end
   else
     assign datacount_o = datacount_up;
endgenerate

//--------------------------------------------------------------------
// Next State: Depends on Current State and datacount_o
always @(*) begin
   next_st = curr_st;
   empty_o = 0;
   half_full_o = 0;
   full_o = 0;
   
   case(curr_st)
     EMPTY_ST : begin
	empty_o = 1;
	if(datacount_o != {ADDR_WIDTH{1'b0}}) //Logic for >0 is not efficient
	//if(datacount_o > 0)
	  begin
	     empty_o = 0;
	     next_st = LT_HF_ST;
	  end
     end
     LT_HF_ST : begin
	if(datacount_o[ADDR_WIDTH-1] == 1'b1) //>=HALF_DEPTH
          next_st = GTE_HF_ST;
	else if(datacount_o == 0) begin
	   empty_o = 1;
           next_st = EMPTY_ST;
	end
     end
     GTE_HF_ST : begin
	half_full_o = 1;
	if(datacount_o == FULL_COUNT) begin
	   full_o  = 1;
	   next_st = FULL_ST;
	end
	else if(datacount_o[ADDR_WIDTH-1] == 1'b0) //<HALF_DEPTH
          next_st = LT_HF_ST;
     end
     FULL_ST : begin
	half_full_o = 1;
	full_o = 1;
	if(datacount_o != FULL_COUNT) begin
	   full_o  = 0;
	   next_st = GTE_HF_ST;
	end
     end
     default : begin
	next_st = EMPTY_ST;
     end
   endcase
end

//--------------------------------------------------------------------
// Current State
always @(posedge clk_i, posedge a_rst_i) begin
  if(a_rst_i)
    curr_st <= EMPTY_ST;
  else
    curr_st <= next_st;
end

//--------------------------------------------------------------------
// Compute Optional Custom Flags
generate
   if (OPTIONAL_FLAGS == 1) begin
      assign almost_empty_o = (next_st==FULL_ST) ? 1'b0 :
			      (next_st==EMPTY_ST) ? 1'b1 : (datacount_o<=1);
      assign almost_full_o  = (next_st==EMPTY_ST) ? 1'b0 :
			      (((DEPTH-datacount_o)<=1) || next_st==FULL_ST);
   end
endgenerate

// Add a flop to the combinatorial output feedback to solve
//  racing issue
generate
   if (PROGRAMMABLE_FULL != "NONE") begin
      reg prog_full_latch;
      always @(posedge clk_i)
	prog_full_latch <= prog_full_o;
      if (PROGRAMMABLE_FULL == "STATIC_SINGLE")
	assign prog_full_o = (next_st==EMPTY_ST) ? 1'b0 :
                             (next_st==FULL_ST)  ? 1'b1 :
                             (prog_full_latch == 1'b0) ? (datacount_o>=PROG_FULL_ASSERT) :
                             (datacount_o>=PROG_FULL_ASSERT);
      else if (PROGRAMMABLE_FULL == "STATIC_DUAL")
	assign prog_full_o = (next_st==EMPTY_ST) ? 1'b0 :
                             (next_st==FULL_ST)  ? 1'b1 :
                             (prog_full_latch == 1'b0) ? (datacount_o>=PROG_FULL_ASSERT) :
                             (datacount_o>=PROG_FULL_NEGATE);
   end
endgenerate

generate
   if (PROGRAMMABLE_EMPTY != "NONE") begin
      reg prog_empty_latch;
      always @(posedge clk_i)
	prog_empty_latch <= prog_empty_o;
      if (PROGRAMMABLE_EMPTY == "STATIC_SINGLE")
	assign prog_empty_o = (next_st==FULL_ST)  ? 1'b0 :
                              (next_st==EMPTY_ST) ? 1'b1 :
                              (prog_empty_latch == 1'b0) ? (datacount_o<=PROG_EMPTY_ASSERT) :
                              (datacount_o<=PROG_EMPTY_ASSERT);
      else if (PROGRAMMABLE_EMPTY == "STATIC_DUAL")
	assign prog_empty_o = (next_st==FULL_ST)  ? 1'b0 :
                              (next_st==EMPTY_ST) ? 1'b1 :
                              (prog_empty_latch == 1'b0) ? (datacount_o<=PROG_EMPTY_ASSERT) :
                              (datacount_o<=PROG_EMPTY_NEGATE);
   end
endgenerate

endmodule







module efx_syncfifo_ctl
#(
  parameter SYNC_CLK		= 1,
  parameter WR_DEPTH		= 1025,
  parameter RD_DEPTH		= 1025,
  parameter WADDR_WIDTH		= depth2width(WR_DEPTH),
  parameter RADDR_WIDTH		= depth2width(RD_DEPTH),
  parameter ASYM_WIDTH		= 0,
  parameter MODE		= "STANDARD",
  parameter OPTIONAL_FLAGS	= 1,
  parameter PROGRAMMABLE_FULL	= "NONE",
  parameter PROG_FULL_ASSERT	= 1024,
  parameter PROG_FULL_NEGATE	= 1025,
  parameter PROGRAMMABLE_EMPTY	= "NONE",
  parameter PROG_EMPTY_ASSERT	= 1,
  parameter PROG_EMPTY_NEGATE	= 0
)
(// output
 output wire 		       empty_o,
 output wire 		       almost_empty_o,
 output wire 		       prog_empty_o,
 output reg 		       underflow_o,
 output wire 		       full_o,
 output wire 		       almost_full_o,
 output wire 		       prog_full_o,
 output reg 		       overflow_o,
 output reg [WADDR_WIDTH-1:0]  wr_adr_o,
 output reg [RADDR_WIDTH-1:0]  rd_adr_o,
 output reg 		       wr_ack_o,
 output wire 		       wr_ram,
 output reg 		       rd_valid_o,
 output wire 		       rd_ram,
 output wire [WADDR_WIDTH-1:0] datacount_o,
 // input
 input 			       clk_i,
 input 			       wr_en_i,
 input 			       rd_en_i,
 input 			       a_rst_i);
//--------------------------------------------------------------------
// Local Function
`include "efx_fifo_functions.vh"
   
//--------------------------------------------------------------------
// Local Parameters
localparam WMAX_ADDR = (WR_DEPTH-1);
localparam RMAX_ADDR = (RD_DEPTH-1);

//--------------------------------------------------------------------
// Masked Signals
   wire 		     half_full_o;

//--------------------------------------------------------------------
// Local Signals
   wire [RADDR_WIDTH-1:0] rd_adr_int;     //Internal read address
   wire [WADDR_WIDTH-1:0] wr_datacount_o;
   wire [RADDR_WIDTH-1:0] rd_datacount_o;

//--------------------------------------------------------------------
// Writing and Reading is allowed only for valid operations. That
// is you can not write more into a full FIFO nor can you read
// an empty FIFO.
// Logic for writing and reading ram, wr_ram & rd_ram
   assign wr_ram = (wr_en_i & ~full_o);
   wire rd_empty_int;
   reg 	rd_first = 1'b0;
generate
   if (MODE == "STANDARD") begin
      assign empty_o = rd_empty_int;
      assign rd_ram = (rd_en_i  & ~empty_o);

      assign rd_adr_int = rd_adr_o;
   end
   else /* (MODE == "FWFT") */ begin : rd_fwft_compensate
      if (ASYM_WIDTH == 0) begin
	 assign empty_o = rd_first ? 1'b1 : rd_empty_int;

	 //Can't read when datacount = 1
	 //Auto read at next clock cycle if empty for first write
	 assign rd_ram = (rd_en_i & ~empty_o & (datacount_o != 1)) |
     			 (rd_first & ~rd_empty_int);

	 always @(posedge clk_i)
	   if (rd_empty_int)
	     rd_first <= 1'b1;
	   else if (rd_first)
	     rd_first <= 1'b0;
	   else if (datacount_o == {{RADDR_WIDTH-1{1'b0}}, 1'b1} && rd_en_i)
	     rd_first <= 1'b1;

	 //rd_adr in FWFT will auto-increment for the first word, hence need to
	 // compensate that extra word lost.
	 reg datacount_minus;	//Word compensation for FWFT
	 if (RD_DEPTH == 2**RADDR_WIDTH)
	   assign rd_adr_int = rd_adr_o - datacount_minus;
	 else
	   assign rd_adr_int = (datacount_minus && (rd_adr_o == {RADDR_WIDTH{1'b0}})) ?
			       RMAX_ADDR : rd_adr_o - datacount_minus;

	 always @(posedge clk_i, posedge a_rst_i) begin
	    if (a_rst_i) begin
	       datacount_minus <= 1'b0;
	    end
	    else if (rd_first && ~rd_empty_int) begin
	       datacount_minus  <= 1'b1;
	    end
	    else if (datacount_o == {{RADDR_WIDTH-1{1'b0}},1'b1} && rd_en_i) begin
	       datacount_minus <= 1'b0;
	    end
	 end
      end
   end
endgenerate

//--------------------------------------------------------------------
// Write Address Counter and optional wr_ack_o Signal
generate
   if (OPTIONAL_FLAGS == 1)
     always @(posedge clk_i, posedge a_rst_i)
       if (a_rst_i)
	 wr_ack_o <= 1'b0;
       else
	 wr_ack_o <= wr_ram;
endgenerate

always @(posedge clk_i, posedge a_rst_i)
  begin
     if(a_rst_i)
       wr_adr_o <= {WADDR_WIDTH{1'b0}};
     else
       if (wr_ram)
	 if(wr_adr_o==WMAX_ADDR)
           wr_adr_o <= {WADDR_WIDTH{1'b0}};
	 else
           wr_adr_o <= wr_adr_o + 1'b1;
  end

//--------------------------------------------------------------------
// Read Address Counter and optional rd_valid_o Signal
generate
   if (OPTIONAL_FLAGS == 1)
     if (MODE == "STANDARD") begin
	always @(posedge clk_i, posedge a_rst_i)
	  if (a_rst_i) begin
	     rd_valid_o <= 1'b0;
	  end
	  else begin
	     rd_valid_o <= rd_ram;
	  end
     end
     else /* (MODE == "FWFT") */  begin
	always @(*)
	  rd_valid_o = ~empty_o;
     end
endgenerate

   always @(posedge clk_i, posedge a_rst_i)
     if (a_rst_i) begin
	rd_adr_o <= {RADDR_WIDTH{1'b0}};
     end
     else begin
	if (rd_ram)
	  if(rd_adr_o==RMAX_ADDR)
	    rd_adr_o <= {RADDR_WIDTH{1'b0}};
	  else
	    rd_adr_o <= rd_adr_o + 1'b1;
     end

//--------------------------------------------------------------------
// Compute Wr & Rd Flags
generate
   if (ASYM_WIDTH == 0) //Write and Read Data Width & Depth same
     begin : sym_width
	efx_fifo_ctl_sm #(
			  .SYNC_CLK	     (SYNC_CLK),
			  .DEPTH	     (WR_DEPTH),
			  .ADDR_WIDTH	     (WADDR_WIDTH),
			  .MODE		     (MODE),
			  .OPTIONAL_FLAGS    (OPTIONAL_FLAGS),
			  .PROGRAMMABLE_FULL (PROGRAMMABLE_FULL),
			  .PROG_FULL_ASSERT  (PROG_FULL_ASSERT),
			  .PROG_FULL_NEGATE  (PROG_FULL_NEGATE),
			  .PROGRAMMABLE_EMPTY(PROGRAMMABLE_EMPTY),
			  .PROG_EMPTY_ASSERT (PROG_EMPTY_ASSERT),
			  .PROG_EMPTY_NEGATE (PROG_EMPTY_NEGATE))
	u_wrrd_flags(
		   // Outputs
		   .empty_o		(rd_empty_int),
		   .almost_empty_o	(almost_empty_o),
		   .prog_empty_o	(prog_empty_o),
		   .half_full_o		(half_full_o),
		   .almost_full_o	(almost_full_o),
		   .prog_full_o		(prog_full_o),
		   .full_o		(full_o),
		   .datacount_o		(datacount_o),
		   // Inputs
		   .wr_adr_i		(wr_adr_o),
		   .rd_adr_i		(rd_adr_int),
		   .clk_i		(clk_i),
		   .a_rst_i		(a_rst_i),
		   .wr_ram		(wr_ram),
		   .rd_ram		(rd_ram && ~rd_first),
		   .rd_en_i		(rd_en_i));
     end
   else /* (ASYM_WIDTH == 1) */ //Asymmetrical Data Width
     //Divide into Write Domain and Read Domain
     //
     begin : asym_width
	wire [WADDR_WIDTH-1:0] rd_adr_asym; //Read Address for Write Flags
	wire [RADDR_WIDTH-1:0] wr_adr_asym; //Write Address for Read Flags
	if (WADDR_WIDTH > RADDR_WIDTH) begin
	   assign rd_adr_asym = {rd_adr_int,{(WADDR_WIDTH-RADDR_WIDTH){1'b0}}};
	   assign wr_adr_asym = wr_adr_o[WADDR_WIDTH-1:WADDR_WIDTH-RADDR_WIDTH];
	end else /* (WADDR_WIDTH < RADDR_WIDTH) */ begin
	   assign rd_adr_asym = rd_adr_int[RADDR_WIDTH-1:RADDR_WIDTH-WADDR_WIDTH];
	   assign wr_adr_asym = {wr_adr_o,{(RADDR_WIDTH-WADDR_WIDTH){1'b0}}};
	end
	efx_fifo_ctl_sm #(
			  .SYNC_CLK	     (SYNC_CLK),
			  .DEPTH	     (WR_DEPTH),
			  .ADDR_WIDTH	     (WADDR_WIDTH),
			  .MODE		     (MODE),
			  .OPTIONAL_FLAGS    (OPTIONAL_FLAGS),
			  .PROGRAMMABLE_FULL (PROGRAMMABLE_FULL),
			  .PROG_FULL_ASSERT  (PROG_FULL_ASSERT),
			  .PROG_FULL_NEGATE  (PROG_FULL_NEGATE),
			  .PROGRAMMABLE_EMPTY(PROGRAMMABLE_EMPTY),
			  .PROG_EMPTY_ASSERT (PROG_EMPTY_ASSERT),
			  .PROG_EMPTY_NEGATE (PROG_EMPTY_NEGATE))
	u_wr_flags(
		// Outputs
		.empty_o	(),
		.almost_empty_o	(),
		.prog_empty_o	(),
		.half_full_o	(half_full_o),
		.almost_full_o	(almost_full_o),
		.prog_full_o	(prog_full_o),
		.full_o		(full_o),
		.datacount_o	(wr_datacount_o),
		// Inputs
		.wr_adr_i	(wr_adr_o),
		.rd_adr_i	(rd_adr_asym),
		.clk_i		(clk_i),
		.a_rst_i	(a_rst_i));
	efx_fifo_ctl_sm #(
			  .SYNC_CLK	     (SYNC_CLK),
			  .DEPTH	     (RD_DEPTH),
			  .ADDR_WIDTH	     (RADDR_WIDTH),
			  .MODE		     (MODE),
			  .OPTIONAL_FLAGS    (OPTIONAL_FLAGS),
			  .PROGRAMMABLE_FULL (PROGRAMMABLE_FULL),
			  .PROG_FULL_ASSERT  (PROG_FULL_ASSERT),
			  .PROG_FULL_NEGATE  (PROG_FULL_NEGATE),
			  .PROGRAMMABLE_EMPTY(PROGRAMMABLE_EMPTY),
			  .PROG_EMPTY_ASSERT (PROG_EMPTY_ASSERT),
			  .PROG_EMPTY_NEGATE (PROG_EMPTY_NEGATE))
	u_rd_flags(
		// Outputs
		.empty_o	(empty_o),
		.almost_empty_o	(almost_empty_o),
		.prog_empty_o	(prog_empty_o),
		.half_full_o	(),
		.almost_full_o	(),
		.prog_full_o	(),
		.full_o		(),
		.datacount_o	(rd_datacount_o),
		// Inputs
		.wr_adr_i	(wr_adr_asym),
		.rd_adr_i	(rd_adr_int),
		.clk_i		(clk_i),
		.a_rst_i	(a_rst_i));
     end
endgenerate

//Would like to take the programmable full/empty out from ctl_sm
// and to divide the modules in ctl_sm to datacount and sm

//Optional error signals
generate
   if (OPTIONAL_FLAGS == 1)
     always @(posedge clk_i) begin
	overflow_o <= full_o & wr_en_i;
	underflow_o <= empty_o & rd_en_i;
     end
endgenerate

endmodule








module bin2gray
#(parameter WIDTH=5)
(// outputs
 output reg [WIDTH-1:0] gray_o,
 // input
 input [WIDTH-1:0] bin_i,
 input clk_i);

//---------------------------------------------------------------------
// Function :   bit_xor
// Description: reduction xor
function bit_xor (
  input [31:0] nex_bit,
  input [31:0] curr_bit,
  input [WIDTH-1:0] xor_in);
  begin : fn_bit_xor
    bit_xor = xor_in[nex_bit] ^ xor_in[curr_bit];
  end
endfunction

   wire [WIDTH-1:0] gray_combi;
// Convert Binary to Gray, bit by bit
generate 
begin
  genvar bit_idx;
  for(bit_idx=0; bit_idx<WIDTH-1; bit_idx=bit_idx+1) begin : gBinBits
    assign gray_combi[bit_idx] = bit_xor(bit_idx+1, bit_idx, bin_i);
  end
  assign   gray_combi[WIDTH-1] = bin_i[WIDTH-1];
end
endgenerate

   always @(posedge clk_i)
     gray_o <= gray_combi;

endmodule 





module gray2bin
#(parameter WIDTH=5)
(// outputs
 output wire [WIDTH-1:0] bin_o,
 // input
 input [WIDTH-1:0] gray_i);

//---------------------------------------------------------------------
// Recursive Module
// Description: reduction xor
generate
   if (WIDTH > 1) begin
      wire [1:0] bin_1;
      assign bin_1 = {gray_i[WIDTH-1], gray_i[WIDTH-1]^gray_i[WIDTH-2]};
      if (WIDTH == 2) begin
	 assign bin_o = bin_1;
      end
      else begin
	 assign bin_o[WIDTH-1] = bin_1[1];
	 gray2bin #(.WIDTH(WIDTH-1)) u_gray2bin (.bin_o(bin_o[WIDTH-2:0]), .gray_i({bin_1[0], gray_i[WIDTH-3:0]}));
      end
   end
   else /* if (WIDTH == 1) */
     assign bin_o = gray_i;
endgenerate
   
endmodule 





module pipe_reg
#(parameter 
  DEPTH = 32,
  WIDTH = 4)
(// output
 output wire [WIDTH-1:0] d_o,
 // input
 input [WIDTH-1:0] d_i,
 input clk_i);

reg [WIDTH-1:0] pipe_reg [DEPTH-1:0];
integer i;

always @(posedge clk_i) begin :rtlPipeBit
  for (i=DEPTH-1; i>0; i = i - 1) begin
    pipe_reg[i] <= pipe_reg[i-1];
  end
  pipe_reg[0] <= d_i;
end
assign d_o = pipe_reg[DEPTH-1];
   




endmodule




module simple_dual_port_ram_fifo
  #(
    parameter SYNC_CLK		= 1,
    parameter WR_DEPTH		= 512,
    parameter RD_DEPTH		= 512,
    parameter WDATA_WIDTH	= 8,
    parameter RDATA_WIDTH	= 8,
    parameter WADDR_WIDTH	= 9,
    parameter RADDR_WIDTH	= 9,
    parameter OUTPUT_REG	= 1,
    parameter ASYM_WIDTH	= 0,
    parameter MODE		= "STANDARD"
    )
   (
    input [(WDATA_WIDTH-1):0]  wdata,
    input [(WADDR_WIDTH-1):0]  waddr,
    input [(RADDR_WIDTH-1):0]  raddr,
    input 		       we, re, clk, wclk, rclk,
    output [(RDATA_WIDTH-1):0] rdata
    );

   //Depth and data width is inversely proportional
   localparam MEM_DEPTH = (WR_DEPTH > RD_DEPTH) ? WR_DEPTH : RD_DEPTH;
   localparam MEM_DATA_WIDTH = (WDATA_WIDTH > RDATA_WIDTH) ? RDATA_WIDTH : WDATA_WIDTH;

   reg [MEM_DATA_WIDTH-1:0]        ram[MEM_DEPTH-1:0];

   reg [RDATA_WIDTH-1:0]       r_rdata_1P;

generate
   if (ASYM_WIDTH == 0) begin
      if (SYNC_CLK == 1) begin
	 always @ (posedge clk) begin
	    if (we)
	      ram[waddr] <= wdata;
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
      else /* (SYNC_CLK == 0) */ begin
	 always @ (posedge wclk)
	   if (we)
	     ram[waddr] <= wdata;

	 always @ (posedge rclk) begin
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
   end
   else /* (ASYM_WIDTH == 1) */ begin //Sync FIFO only
      if (WDATA_WIDTH == RDATA_WIDTH*2) begin
	 always @ (posedge clk) begin : wrwidth_gt_rdwidth
	    integer i;
	    reg     lsbaddr;
	    for (i=0; i<2; i=i+1) begin // : write1
	       lsbaddr = i;
	       if (we) begin
	   	  //ram[{waddr,lsbaddr}] <= wdata[((i+1)*WDATA_WIDTH/2)-1 -: WDATA_WIDTH/2]; //Little Endian
	   	  ram[{waddr,lsbaddr}] <= wdata[(WDATA_WIDTH/(i+1))-1 -: WDATA_WIDTH/2]; //Big Endian
	       end
	    end
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
      else if (WDATA_WIDTH == RDATA_WIDTH/2) begin
	 always @ (posedge clk) begin : wrwidth_lt_rdwidth
	    integer i;
	    reg     lsbaddr;
	    if (we)
	      ram[waddr] <= wdata;
	    for (i=0; i<2; i=i+1) begin
	       lsbaddr = i;
	       if (re) begin
		  //r_rdata_1P[((i+1)*RDATA_WIDTH/2)-1 -: RDATA_WIDTH/2] <= ram[{raddr,lsbaddr}]; //Little Endian
		  r_rdata_1P[(RDATA_WIDTH/(i+1))-1 -: RDATA_WIDTH/2] <= ram[{raddr,lsbaddr}]; //Big Endian
	       end
	    end
	 end
      end
   end
endgenerate

generate
   if (OUTPUT_REG == 1) begin
      reg [RDATA_WIDTH-1:0] r_rdata_2P;
      if (SYNC_CLK == 1)
	always @(posedge clk)
	  r_rdata_2P <= r_rdata_1P;
      else /* (SYNC_CLK == 0) */
	always @(posedge rclk)
	  r_rdata_2P <= r_rdata_1P;
      assign rdata = r_rdata_2P;
   end
   else /* (OUTPUT_REG == 0) */
     assign rdata = r_rdata_1P;
endgenerate

endmodule






 module efx_fifo_wrapper_registers(
			  //Output
			  almost_full_o,
			  prog_full_o,
			  full_o,
			  overflow_o,
			  wr_ack_o,
			  datacount_o,
			  wr_datacount_o,
			  empty_o,
			  almost_empty_o,
			  prog_empty_o,
			  underflow_o,
			  rd_valid_o,
			  rdata,
			  rd_datacount_o,
			  //Input
			  clk_i,
			  wr_clk_i,
			  rd_clk_i,
			  wr_en_i,
			  rd_en_i,
			  a_rst_i,
			  wdata);
//Parameter and localparam for ports declaration
   parameter SYNC_CLK	= 1;
   parameter DEPTH	= 512; //Must be power of 2
   parameter DATA_WIDTH	= 32;
   localparam WCNT_WIDTH	= depth2width(DEPTH); //Removed feature
   localparam RCNT_WIDTH	= depth2width(DEPTH); //Removed feature
   parameter MODE		= "STANDARD";
   parameter OUTPUT_REG		= 0;
   parameter PIPELINE_REG	= 1;
   parameter OPTIONAL_FLAGS	= 1;
   parameter PROGRAMMABLE_FULL	= "NONE";
   parameter PROG_FULL_ASSERT	= DEPTH;
   parameter PROG_FULL_NEGATE	= PROG_FULL_ASSERT;
   parameter PROGRAMMABLE_EMPTY	= "NONE";
   parameter PROG_EMPTY_ASSERT	= 0;
   parameter PROG_EMPTY_NEGATE	= PROG_EMPTY_ASSERT;

//Ports declaration
   //Output
   output wire 			almost_full_o;
   output wire 			prog_full_o;
   output wire 			full_o;
   output wire 			overflow_o;
   output wire 			wr_ack_o;
   output wire [WCNT_WIDTH-1:0] datacount_o;
   output wire [WCNT_WIDTH-1:0] wr_datacount_o;
   output wire 			empty_o;
   output wire 			almost_empty_o;
   output wire 			prog_empty_o;
   output wire 			underflow_o;
   output reg 			rd_valid_o;
   output wire [DATA_WIDTH-1:0] rdata;
   output wire [RCNT_WIDTH-1:0] rd_datacount_o;
   //Input
   input 			clk_i;
   input 			wr_clk_i;
   input 			rd_clk_i;
   input 			wr_en_i;
   input 			rd_en_i;
   input 			a_rst_i;
   input [DATA_WIDTH-1:0] 	wdata;

//--------------------------------------------------------------------
// Local Function
`include "efx_fifo_functions.vh"

//--------------------------------------------------------------------
// Masked Signals/Parameters
   //Start: Asymmetrical Width parameter calculation and signal assignment
   //Minimum RDATA_WIDTH stops at odd number
   localparam WR_DEPTH = DEPTH;         //Removed Asym Feature
   localparam WDATA_WIDTH = DATA_WIDTH; //Removed Asym Feature
   localparam RDATA_WIDTH = DATA_WIDTH; //Removed Asym Feature
   localparam RDATA_WIDTH_MIN	= (WDATA_WIDTH % 2) ? (WDATA_WIDTH) :
				  (WDATA_WIDTH % 4) ? (WDATA_WIDTH / 2) :
				  (WDATA_WIDTH % 8) ? (WDATA_WIDTH / 4) :
				                      (WDATA_WIDTH / 8);
   //Maximum RDATA_WIDTH depends on WR_DEPTH, minimum WR_DEPTH=16
   localparam RDATA_WIDTH_MAX	= ((WR_DEPTH < 32)  || (WR_DEPTH % 2)) ? (WDATA_WIDTH) :
				  ((WR_DEPTH < 64)  || (WR_DEPTH % 4)) ? (WDATA_WIDTH * 2) :
				  ((WR_DEPTH < 128) || (WR_DEPTH % 8)) ? (WDATA_WIDTH * 4) :
				                                         (WDATA_WIDTH * 8);
   //Filter input RDATA_WIDTH to fit 8:1, 4:1, 2:1, 1:1, 1:2, 1:4, 1:8 W/R ratio
   //Smaller input RDATA_WIDTH will match to larger effective width, max 8*WDATA_WIDTH
   localparam RDATA_WIDTH_EFF	= (RDATA_WIDTH <= RDATA_WIDTH_MIN) ? RDATA_WIDTH_MIN :
				  (RDATA_WIDTH >  RDATA_WIDTH_MAX) ? RDATA_WIDTH_MAX :
				  (RDATA_WIDTH <= WDATA_WIDTH/4) ? WDATA_WIDTH/4 :
				  (RDATA_WIDTH <= WDATA_WIDTH/2) ? WDATA_WIDTH/2 :
				  (RDATA_WIDTH <= WDATA_WIDTH)   ? WDATA_WIDTH :
				  (RDATA_WIDTH <= WDATA_WIDTH*2) ? WDATA_WIDTH*2 :
				  (RDATA_WIDTH <= WDATA_WIDTH*4) ? WDATA_WIDTH*4 :
				                                   WDATA_WIDTH*8;
   localparam WADDR_WIDTH	= depth2width(WR_DEPTH);
   localparam ASYM_WIDTH	= (WDATA_WIDTH !== RDATA_WIDTH_EFF);
   localparam RD_DEPTH		= WR_DEPTH * WDATA_WIDTH / RDATA_WIDTH_EFF;
   localparam RADDR_WIDTH	= depth2width(RD_DEPTH);
   //localparam DATA_WIDTH_RATIO;

   wire [WADDR_WIDTH-1:0] wr_adr_o;
   wire [RADDR_WIDTH-1:0] rd_adr_o;
   wire 		  rd_ram, wr_ram;
   wire [RDATA_WIDTH_EFF-1:0] rdata_int; //Internal rdata
   //If RDATA_WIDTH is configured correctly, rdata should take the correct value
   //If not, either MSB of rdata_int is masked, or MSB of rdata is unassigned
   assign rdata = rdata_int;
   //End: Asymmetrical Width parameter calculation and signal assignment

   wire rd_valid_int; //Internal rd_valid
generate
   if (OUTPUT_REG == 1)
     if (SYNC_CLK == 0)
       always @(posedge rd_clk_i)
	 rd_valid_o <= rd_valid_int;
     else /* (SYNC_CLK == 1) */
       always @(posedge clk_i)
	 rd_valid_o <= rd_valid_int;
   else /* (OUTPUT_REG == 0) */
     always @(*)
       rd_valid_o = rd_valid_int;
endgenerate

   //Start: datacount_o signal assignment
   //If user input width < log2(fifo_depth)-1, LSB will be truncated
   //Internal datacounts
   wire [WADDR_WIDTH-1:0] datacount_int;
   wire [WADDR_WIDTH-1:0] wr_datacount_int;
   wire [RADDR_WIDTH-1:0] rd_datacount_int;

generate
   if (WCNT_WIDTH < WADDR_WIDTH) begin
      assign datacount_o = datacount_int[WADDR_WIDTH:WADDR_WIDTH-WCNT_WIDTH];
      assign wr_datacount_o = wr_datacount_int[WADDR_WIDTH:WADDR_WIDTH-WCNT_WIDTH];
   end
   else begin
      assign datacount_o = datacount_int;
      assign wr_datacount_o = wr_datacount_int;
   end

   if (RCNT_WIDTH < RADDR_WIDTH) begin
      assign rd_datacount_o = rd_datacount_int[RADDR_WIDTH:RADDR_WIDTH-RCNT_WIDTH];
   end
   else begin
      assign rd_datacount_o = rd_datacount_int;
   end
endgenerate
   //End: Datacount_o signal assignment

//--------------------------------------------------------------------
// Module Instantiation
// Read/Write Domain State Machine and Flags
generate begin : fifo_ctl
   if (SYNC_CLK == 1)
   efx_syncfifo_ctl #(
		      // Parameters
		      .SYNC_CLK		  (SYNC_CLK),
		      .WR_DEPTH		  (WR_DEPTH),
		      .RD_DEPTH		  (RD_DEPTH),
		      .WADDR_WIDTH	  (WADDR_WIDTH),
		      .RADDR_WIDTH	  (RADDR_WIDTH),
		      .ASYM_WIDTH	  (ASYM_WIDTH),
		      .MODE		  (MODE),
		      .OPTIONAL_FLAGS	  (OPTIONAL_FLAGS),
		      .PROGRAMMABLE_FULL  (PROGRAMMABLE_FULL),
		      .PROG_FULL_ASSERT	  (PROG_FULL_ASSERT),
		      .PROG_FULL_NEGATE   (PROG_FULL_NEGATE),
		      .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY),
		      .PROG_EMPTY_ASSERT  (PROG_EMPTY_ASSERT),
		      .PROG_EMPTY_NEGATE  (PROG_EMPTY_NEGATE))
   u_efx_syncfifo_ctl (
		       // Outputs
		       .empty_o		(empty_o),
		       .almost_empty_o	(almost_empty_o),
		       .prog_empty_o	(prog_empty_o),
		       .underflow_o	(underflow_o),
		       .full_o		(full_o),
		       .almost_full_o	(almost_full_o),
		       .prog_full_o	(prog_full_o),
		       .overflow_o	(overflow_o),
		       .wr_adr_o	(wr_adr_o),
		       .rd_adr_o	(rd_adr_o),
		       .wr_ack_o	(wr_ack_o),
		       .wr_ram	        (wr_ram),
		       .rd_valid_o	(rd_valid_int),
		       .rd_ram	        (rd_ram),
		       .datacount_o	(datacount_int),
		       // Inputs
		       .clk_i		(clk_i),
		       .a_rst_i		(a_rst_i),
		       .wr_en_i		(wr_en_i),
		       .rd_en_i		(rd_en_i));
   else /* (SYNC_CLK == 0) */
   efx_asyncfifo_ctl #(
		       // Parameters
		       .SYNC_CLK	   (SYNC_CLK),
		       .WR_DEPTH	   (WR_DEPTH),
		       .RD_DEPTH	   (RD_DEPTH),
		       .WADDR_WIDTH	   (WADDR_WIDTH),
		       .RADDR_WIDTH	   (RADDR_WIDTH),
		       .ASYM_WIDTH	   (ASYM_WIDTH),
		       .MODE		   (MODE),
		       .PIPELINE_REG	   (PIPELINE_REG),
		       .OPTIONAL_FLAGS	   (OPTIONAL_FLAGS),
		       .PROGRAMMABLE_FULL  (PROGRAMMABLE_FULL),
		       .PROG_FULL_ASSERT   (PROG_FULL_ASSERT),
		       .PROG_FULL_NEGATE   (PROG_FULL_NEGATE),
		       .PROGRAMMABLE_EMPTY (PROGRAMMABLE_EMPTY),
		       .PROG_EMPTY_ASSERT  (PROG_EMPTY_ASSERT),
		       .PROG_EMPTY_NEGATE  (PROG_EMPTY_NEGATE))
   u_efx_asyncfifo_ctl (
			// Outputs
			.wr_almost_full_o  (almost_full_o),
			.wr_prog_full_o	   (prog_full_o),
			.wr_full_o	   (full_o),
			.overflow_o	   (overflow_o),
			.wr_adr_o	   (wr_adr_o),
			.wr_ack_o	   (wr_ack_o),
			.wr_ram		   (wr_ram),
			.wr_datacount_o	   (wr_datacount_int),
			.rd_empty_o	   (empty_o),
			.rd_almost_empty_o (almost_empty_o),
			.rd_prog_empty_o   (prog_empty_o),
			.underflow_o	   (underflow_o),
			.rd_adr_o	   (rd_adr_o),
			.rd_valid_o	   (rd_valid_int),
			.rd_ram		   (rd_ram),
			.rd_datacount_o	   (rd_datacount_int),
			// Inputs
			.wr_clk_i	   (wr_clk_i),
			.wr_en_i	   (wr_en_i),
			.rd_clk_i	   (rd_clk_i),
			.rd_en_i	   (rd_en_i),
			.a_rst_i	   (a_rst_i));
end
endgenerate

// RAM instantiation
generate begin : ram
   if (SYNC_CLK == 1)
   simple_dual_port_ram_fifo_registers
     #( // Parameters
	.SYNC_CLK	(SYNC_CLK),
	.WR_DEPTH	(WR_DEPTH),
	.RD_DEPTH	(RD_DEPTH),
   	.WDATA_WIDTH	(WDATA_WIDTH),
   	.RDATA_WIDTH	(RDATA_WIDTH_EFF),
   	.WADDR_WIDTH	(WADDR_WIDTH),
   	.RADDR_WIDTH	(RADDR_WIDTH),
   	.OUTPUT_REG	(OUTPUT_REG),
	.ASYM_WIDTH	(ASYM_WIDTH),
   	.MODE		(MODE))
   u_simple_dual_port_ram_fifo
     ( // Outputs
       .rdata		(rdata_int),
       // Inputs
       .wdata		(wdata),
       .waddr		(wr_adr_o),
       .raddr		(rd_adr_o),
       .we		(wr_ram),
       .re		(rd_ram),
       .clk		(clk_i),
       .wclk		(1'b0),
       .rclk		(1'b0));

   else /* (SYNC_CLK == 0) */
   simple_dual_port_ram_fifo_registers
     #( // Parameters
	.SYNC_CLK	(SYNC_CLK),
	.WR_DEPTH	(WR_DEPTH),
	.RD_DEPTH	(RD_DEPTH),
   	.WDATA_WIDTH	(WDATA_WIDTH),
   	.RDATA_WIDTH	(RDATA_WIDTH_EFF),
   	.WADDR_WIDTH	(WADDR_WIDTH),
   	.RADDR_WIDTH	(RADDR_WIDTH),
   	.OUTPUT_REG	(OUTPUT_REG),
	.ASYM_WIDTH	(ASYM_WIDTH),
   	.MODE		(MODE))
   u_simple_dual_port_ram_fifo
     ( // Outputs
       .rdata		(rdata_int),
       // Inputs
       .wdata		(wdata),
       .waddr		(wr_adr_o),
       .raddr		(rd_adr_o),
       .we		(wr_ram),
       .re		(rd_ram),
       .clk		(1'b0),
       .wclk		(wr_clk_i),
       .rclk		(rd_clk_i));
end
endgenerate
   
endmodule   







module simple_dual_port_ram_fifo_registers
  #(
    parameter SYNC_CLK		= 1,
    parameter WR_DEPTH		= 512,
    parameter RD_DEPTH		= 512,
    parameter WDATA_WIDTH	= 8,
    parameter RDATA_WIDTH	= 8,
    parameter WADDR_WIDTH	= 9,
    parameter RADDR_WIDTH	= 9,
    parameter OUTPUT_REG	= 1,
    parameter ASYM_WIDTH	= 0,
    parameter MODE		= "STANDARD"
    )
   (
    input [(WDATA_WIDTH-1):0]  wdata,
    input [(WADDR_WIDTH-1):0]  waddr,
    input [(RADDR_WIDTH-1):0]  raddr,
    input 		       we, re, clk, wclk, rclk,
    output [(RDATA_WIDTH-1):0] rdata
    );

   //Depth and data width is inversely proportional
   localparam MEM_DEPTH = (WR_DEPTH > RD_DEPTH) ? WR_DEPTH : RD_DEPTH;
   localparam MEM_DATA_WIDTH = (WDATA_WIDTH > RDATA_WIDTH) ? RDATA_WIDTH : WDATA_WIDTH;

   (* syn_ramstyle = "registers" *) reg [MEM_DATA_WIDTH-1:0]        ram[MEM_DEPTH-1:0];

   reg [RDATA_WIDTH-1:0]       r_rdata_1P;

generate
   if (ASYM_WIDTH == 0) begin
      if (SYNC_CLK == 1) begin
	 always @ (posedge clk) begin
	    if (we)
	      ram[waddr] <= wdata;
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
      else /* (SYNC_CLK == 0) */ begin
	 always @ (posedge wclk)
	   if (we)
	     ram[waddr] <= wdata;

	 always @ (posedge rclk) begin
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
   end
   else /* (ASYM_WIDTH == 1) */ begin //Sync FIFO only
      if (WDATA_WIDTH == RDATA_WIDTH*2) begin
	 always @ (posedge clk) begin : wrwidth_gt_rdwidth
	    integer i;
	    reg     lsbaddr;
	    for (i=0; i<2; i=i+1) begin // : write1
	       lsbaddr = i;
	       if (we) begin
	   	  //ram[{waddr,lsbaddr}] <= wdata[((i+1)*WDATA_WIDTH/2)-1 -: WDATA_WIDTH/2]; //Little Endian
	   	  ram[{waddr,lsbaddr}] <= wdata[(WDATA_WIDTH/(i+1))-1 -: WDATA_WIDTH/2]; //Big Endian
	       end
	    end
	    if (re)
	      r_rdata_1P <= ram[raddr];
	 end
      end
      else if (WDATA_WIDTH == RDATA_WIDTH/2) begin
	 always @ (posedge clk) begin : wrwidth_lt_rdwidth
	    integer i;
	    reg     lsbaddr;
	    if (we)
	      ram[waddr] <= wdata;
	    for (i=0; i<2; i=i+1) begin
	       lsbaddr = i;
	       if (re) begin
		  //r_rdata_1P[((i+1)*RDATA_WIDTH/2)-1 -: RDATA_WIDTH/2] <= ram[{raddr,lsbaddr}]; //Little Endian
		  r_rdata_1P[(RDATA_WIDTH/(i+1))-1 -: RDATA_WIDTH/2] <= ram[{raddr,lsbaddr}]; //Big Endian
	       end
	    end
	 end
      end
   end
endgenerate

generate
   if (OUTPUT_REG == 1) begin
      reg [RDATA_WIDTH-1:0] r_rdata_2P;
      if (SYNC_CLK == 1)
	always @(posedge clk)
	  r_rdata_2P <= r_rdata_1P;
      else /* (SYNC_CLK == 0) */
	always @(posedge rclk)
	  r_rdata_2P <= r_rdata_1P;
      assign rdata = r_rdata_2P;
   end
   else /* (OUTPUT_REG == 0) */
     assign rdata = r_rdata_1P;
endgenerate


//Encryption end

endmodule
