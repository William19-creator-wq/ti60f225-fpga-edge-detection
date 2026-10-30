
/////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2013-2021 Efinix Inc. All rights reserved.
//
// Description:
// Example top file for ti60f225 dev kit OOB design
//
// Language:  Verilog 2001
//Ti60f225_sc431hai2hdmi_v6：
//使用了最新版本的framebuffer_v3;
// ------------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////////
//`define SOFT_TAP 1
`include "ddr3_controller/ddr3_parameter.vh"
// `include "define.v"

module ti60f225_oob_top #(

	parameter                       RANK_RATIO         = 1,       // # of unique CS outputs per rank
	parameter                       ASYN_AXI_CLK       = `ASYN_AXI_CLK, 
	parameter                       RANKS              = `RANKS,
	parameter                       CK_WIDTH           = `CK_WIDTH,       // # of CK/CK# outputs to memory   
	parameter                       CKE_WIDTH          = `CKE_WIDTH,       // # of cke outputs
	parameter                       CS_WIDTH           = `CS_WIDTH,       // # of unique CS outputs
	parameter                       BANK_WIDTH         = `BANK_WIDTH,       // # of bank bits
	parameter                       ROW_WIDTH          = `ROW_WIDTH,       // DRAM address bus width
	parameter                       COL_WIDTH          = `COL_WIDTH,      // column address width
	parameter                       DM_WIDTH           = `DM_WIDTH,       // # of DM (data mask)
	parameter                       DQS_WIDTH          = `DQS_WIDTH,       // # of DQS (strobe)
	parameter                       DQ_WIDTH           = `DQ_WIDTH,      // # of DQ (data)
	parameter                       ODT_WIDTH          = `ODT_WIDTH,
	parameter                       DQ_CNT_WIDTH       = `DQ_CNT_WIDTH,       // = ceil(log2(DQ_WIDTH))
	parameter                       DQS_CNT_WIDTH      = `DQS_CNT_WIDTH,       // = ceil(log2(DQS_WIDTH))  
	parameter                       DRAM_WIDTH         = `DRAM_WIDTH,       // # of DQ per DQS   
	parameter                       DATA_WIDTH         = `DATA_WIDTH,
	parameter                       ADDR_WIDTH         = `ADDR_WIDTH,    
	parameter                       AXI_ID_WIDTH       = `AXI_ID_WIDTH,
	parameter                       AXI_ADDR_WIDTH     = `AXI_ADDR_WIDTH,
	parameter                       AXI_DATA_WIDTH     = `AXI_DATA_WIDTH
)
(

  (* syn_peri_port = 0 *) input jtag_inst1_CAPTURE,
  (* syn_peri_port = 0 *) input jtag_inst1_DRCK,
  (* syn_peri_port = 0 *) input jtag_inst1_RESET,
  (* syn_peri_port = 0 *) input jtag_inst1_RUNTEST,
  (* syn_peri_port = 0 *) input jtag_inst1_SEL,
  (* syn_peri_port = 0 *) input jtag_inst1_SHIFT,
  (* syn_peri_port = 0 *) input jtag_inst1_TCK,
  (* syn_peri_port = 0 *) input jtag_inst1_TDI,
  (* syn_peri_port = 0 *) input jtag_inst1_TMS,
  (* syn_peri_port = 0 *) input jtag_inst1_UPDATE,
  (* syn_peri_port = 0 *) output jtag_inst1_TDO,

   //Clocks 
	input	wire	i_arstn,
    input wire key_minus_n,key_plus_n,
    input wire key_probe_minus_n,key_probe_plus_n,
    input wire key_mode_n, // KEY3，A3，低有效；KEY0仍为i_arstn
    input	wire	i_mipi_rx_pclk,
    input wire  vid_clk_dvi2,
    input wire hdmi_tx_slow_clk,
    input wire CLK_5M,
    input  wire CLK_25M,
	output  wire    pll_inst1_RSTN,
	input	wire	i_pll_locked,
	input 	wire  	pll_locked,
	output  wire    pll_inst4_RSTN,
	input   wire    pll_inst4_LOCKED,
	output  wire  	USER_PLL_RSTN,
    output 	wire 	DDR3_PLL_RSTN,
	input 	wire  	user_pll_locked,
    //CSI Interface
    input	 wire		io_cam_sda_IN,
    output wire   io_cam_sda_OUT,
    output wire		io_cam_sda_OE,

    output io_cam_scl_OUT,
    input io_cam_scl_IN,
    output io_cam_scl_OE,

    output	wire		o_cam_rst_p,
    
    input	wire		i_cam_ck_LP_P_IN,
    input	wire		i_cam_ck_LP_N_IN,
    output	wire		o_cam_ck_HS_TERM,
    output	wire		o_cam_ck_HS_ENA,
    input	wire		i_cam_ck_CLKOUT,
    
    input	wire	[7:0]			cam_d0_HS_IN,
    input	  wire		      cam_d0_LP_P_IN,
    input	  wire		      cam_d0_LP_N_IN,
    output	wire		      cam_d0_HS_TERM,
    output	wire		      cam_d0_HS_ENA,
    output	wire		      cam_d0_RST,
    output	wire		      cam_d0_FIFO_RD,
    input	  wire		      cam_d0_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d1_HS_IN,
    input	  wire		        cam_d1_LP_P_IN,
    input	  wire		        cam_d1_LP_N_IN,
    output	wire		        cam_d1_HS_TERM,
    output	wire		        cam_d1_HS_ENA,
    output	wire		        cam_d1_RST,
    output	wire		        cam_d1_FIFO_RD,
    input	  wire		        cam_d1_FIFO_EMPTY,
    
    input 	wire	[7:0]			cam_d2_HS_IN,
    input	  wire		        cam_d2_LP_P_IN,
    input	  wire		        cam_d2_LP_N_IN,
    output	wire		        cam_d2_HS_TERM,
    output	wire		        cam_d2_HS_ENA,
    output	wire		        cam_d2_RST,
    output	wire		        cam_d2_FIFO_RD,
    input	  wire		        cam_d2_FIFO_EMPTY,  
   
    input 	wire	[7:0]			cam_d3_HS_IN,
    input	  wire		        cam_d3_LP_P_IN,
    input	  wire		        cam_d3_LP_N_IN,
    output	wire		        cam_d3_HS_TERM,
    output	wire		        cam_d3_HS_ENA,
    output	wire		        cam_d3_RST,
    output	wire		        cam_d3_FIFO_RD,
    input	  wire		        cam_d3_FIFO_EMPTY,

	
	input 					tx_cal_clk_90edge,
  	input 					rx_cal_clk,
  	input 					tx_cal_clk,
	input                              core_clk,     // CORE CLK @ 100MHz
	input                              sdram_clk,    // SDRAM CK @ 400MHz
	// PLL status flags  
	output [2:0]                       pll_shift,  
	output [4:0]                       pll_shift_sel,
	output                             pll_shift_ena,  
	// memory interface ports
	output                             ddr_ck_hi,
	output                             ddr_ck_lo,
	output                             ddr_reset_n,
	output [CKE_WIDTH-1:0]             ddr_cke,     
	output [ROW_WIDTH-1:0]             ddr_addr,
	output [BANK_WIDTH-1:0]            ddr_ba,
	output                             ddr_cas_n,
 
	output [CS_WIDTH*RANK_RATIO-1:0]   ddr_cs_n,
	output                             ddr_ras_n,
	output                             ddr_we_n,
	
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_hi,
	input  [DQS_WIDTH-1:0]             ddr_dqs_in_lo,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_hi,
	input  [DQ_WIDTH-1:0]              ddr_dq_in_lo,
	
	output [DQS_WIDTH-1:0]             ddr_dqs_oe,
	output [DQS_WIDTH-1:0]             ddr_dqs_oe_n,
	output [DQ_WIDTH-1:0]              ddr_dq_oe,  
	output [DQS_WIDTH-1:0]             ddr_dqs_out_hi,
	output [DQS_WIDTH-1:0]             ddr_dqs_out_lo,
	output [DQ_WIDTH-1:0]              ddr_dq_out_hi,
	output [DQ_WIDTH-1:0]              ddr_dq_out_lo,
	output [DM_WIDTH-1:0]              ddr_dm_hi,
	output [DM_WIDTH-1:0]              ddr_dm_lo,
	output [ODT_WIDTH-1:0]             ddr_odt,

       //LED
       output [7:2] led,

       // MIPI DSI
       input	wire	                     i_mipi_tx_pclk		,
       output	wire	                     mipi_dp_clk_LP_P_OUT		,
       output	wire	                     mipi_dp_clk_LP_N_OUT		,
       output	wire	[7:0] 	              mipi_dp_clk_HS_OUT		,
       output	wire	                     mipi_dp_clk_HS_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OUT	,
       output	wire	                     mipi_dp_data2_LP_P_OUT	,
       output	wire	                     mipi_dp_data1_LP_P_OUT	,
       output	wire	                     mipi_dp_data0_LP_P_OUT	,
       output	wire	                     mipi_dp_data3_LP_N_OUT	,
       output	wire	                     mipi_dp_data2_LP_N_OUT	,
       output	wire	                     mipi_dp_data1_LP_N_OUT	,
       output	wire	                     mipi_dp_data0_LP_N_OUT	,
       output	wire	[7:0] 	              mipi_dp_data0_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data1_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data2_HS_OUT	       ,
       output	wire	[7:0] 	              mipi_dp_data3_HS_OUT	       ,
       output	wire	                     mipi_dp_data3_HS_OE		,
       output	wire	                     mipi_dp_data2_HS_OE		,
       output	wire	                     mipi_dp_data1_HS_OE		,
       output	wire	                     mipi_dp_data0_HS_OE		,

       output	wire	                     mipi_dp_clk_RST		,
       output	wire	                     mipi_dp_data0_RST		,
       output	wire	                     mipi_dp_data1_RST		,
       output	wire	                     mipi_dp_data2_RST		,
       output	wire	                     mipi_dp_data3_RST		,
       output	wire	                     mipi_dp_clk_LP_P_OE		,
       output	wire	                     mipi_dp_clk_LP_N_OE		,
       output	wire	                     mipi_dp_data3_LP_P_OE	,
       output	wire	                     mipi_dp_data3_LP_N_OE	,
       output	wire	                     mipi_dp_data2_LP_P_OE	,
       output	wire	                     mipi_dp_data2_LP_N_OE	,
       output	wire	                     mipi_dp_data1_LP_P_OE	,
       output	wire	                     mipi_dp_data1_LP_N_OE	,
       output	wire	                     mipi_dp_data0_LP_P_OE	,
       output	wire	                     mipi_dp_data0_LP_N_OE	,

       input  wire	                     mipi_dp_data0_LP_P_IN	,
       input  wire	                     mipi_dp_data0_LP_N_IN	,
       output	wire	                     LCD_RST_P			,
       output wire                        LCD_POWER			,

       // hdmi interface

    output tmds_tx_clk_TX_OE,
    output [9:0] tmds_tx_clk_TX_DATA,
    output tmds_tx_clk_TX_RST,
    output tmds_tx_data0_TX_OE,
    output [9:0] tmds_tx_data0_TX_DATA,
    output tmds_tx_data0_TX_RST,
    output tmds_tx_data1_TX_OE,
    output [9:0] tmds_tx_data1_TX_DATA,
    output tmds_tx_data1_TX_RST,
    output tmds_tx_data2_TX_OE,
    output [9:0] tmds_tx_data2_TX_DATA,
    output tmds_tx_data2_TX_RST


);

function integer log2;
	input	integer	val;
	integer	i;
	begin
		log2 = 0;
		for (i=0; 2**i<val; i=i+1)
			log2 = i+1;
	end
endfunction


//===============================================================================
//localparam
//===============================================================================
localparam WR_FIFO_DEPTH  = 1024;
localparam RD_FIFO_DEPTH  = 1024;

// localparam	MAX_HRES		= 12'd1920;
// localparam	MAX_VRES		= 12'd1080;
// localparam	HSP			= 8'd2;
// localparam	HBP			= 8'd88;
// localparam	HFP			= 8'd120;
// localparam	VSP			= 8'd2;
// localparam	VBP			= 8'd20;
// localparam	VFP			= 8'd20;

localparam HACT     = 1920;
localparam HFP      = 88;
localparam HSP      = 44;
localparam HBP      = 148;

localparam VACT     = 1080;
localparam VFP      = 4;
localparam VSP      = 5;
localparam VBP      = 36;
//===============================================================================
//signal
//===============================================================================
   
wire                              app_sr_active;
wire                              app_ref_ack;
wire                              app_zq_ack;
wire                              cal_done;

// Explicit widths and drivers: no implicit Canny/display/reset nets.
wire canny_ddr_awvalid;
wire canny_ddr_awready;
wire [31:0] canny_ddr_awaddr;
wire [3:0] canny_ddr_awid;
wire [7:0] canny_ddr_awlen;
wire [2:0] canny_ddr_awsize;
wire [1:0] canny_ddr_awburst;
wire [3:0] canny_ddr_awcache;
wire [2:0] canny_ddr_awprot;
wire canny_ddr_awlock;
wire canny_ddr_wvalid;
wire canny_ddr_wready;
wire [127:0] canny_ddr_wdata;
wire [15:0] canny_ddr_wstrb;
wire canny_ddr_wlast;
wire canny_ddr_bvalid;
wire canny_ddr_bready;
wire [3:0] canny_ddr_bid;
wire [1:0] canny_ddr_bresp;
wire canny_ddr_arvalid;
wire canny_ddr_arready;
wire [31:0] canny_ddr_araddr;
wire [3:0] canny_ddr_arid;
wire [7:0] canny_ddr_arlen;
wire [2:0] canny_ddr_arsize;
wire [1:0] canny_ddr_arburst;
wire [3:0] canny_ddr_arcache;
wire [2:0] canny_ddr_arprot;
wire canny_ddr_arlock;
wire canny_ddr_rvalid;
wire canny_ddr_rready;
wire [127:0] canny_ddr_rdata;
wire [3:0] canny_ddr_rid;
wire [1:0] canny_ddr_rresp;
wire canny_ddr_rlast;

wire scan_vs_early,scan_hs_early,scan_de_early;
wire [47:0] scan_rgb_early;
reg bridge_vs_previous,show_canny;
reg [1:0] baseline_frames;
wire canny_display_valid,canny_quarantined,canny_snapshot_valid;
wire [1:0] canny_edges,canny_filter;
wire [10:0] canny_threshold;
wire [31:0] canny_completed,canny_failed,canny_underflows;
wire [95:0] canny_debug,canny_display_scope;
wire [63:0] canny_perf;
wire [47:0] display_pixels;
wire axi_rst_n;


// Slave Interface Write Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_awid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr;
wire [7:0]                        s_axi_awlen;
wire [2:0]                        s_axi_awsize;
wire [1:0]                        s_axi_awburst;
wire [0:0]                        s_axi_awlock;
wire [3:0]                        s_axi_awcache;
wire [2:0]                        s_axi_awprot;
wire                              s_axi_awvalid;
wire                              s_axi_awready;
// Slave Interface Write Data Ports
wire [AXI_DATA_WIDTH-1:0]         s_axi_wdata;
wire [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb;
wire                              s_axi_wlast;
wire                              s_axi_wvalid;
wire                              s_axi_wready;
// Slave Interface Write Response Ports
wire                              s_axi_bready;
wire [AXI_ID_WIDTH-1:0]           s_axi_bid;
wire [1:0]                        s_axi_bresp;
wire                              s_axi_bvalid;
// Slave Interface Read Address Ports
wire [AXI_ID_WIDTH-1:0]           s_axi_arid;
wire [AXI_ADDR_WIDTH-1:0]         s_axi_araddr;
wire [7:0]                        s_axi_arlen;
wire [2:0]                        s_axi_arsize;
wire [1:0]                        s_axi_arburst;
wire [0:0]                        s_axi_arlock;
wire [3:0]                        s_axi_arcache;
wire [2:0]                        s_axi_arprot;
wire                              s_axi_arvalid;
wire                              s_axi_arready;
// Slave Interface Read Data Ports
wire                              s_axi_rready;
wire [AXI_ID_WIDTH-1:0]           s_axi_rid;
wire [AXI_DATA_WIDTH-1:0]         s_axi_rdata;
wire [1:0]                        s_axi_rresp;
wire                              s_axi_rlast;
wire                              s_axi_rvalid;




////////////////////////////////////////////////////////////////
// System & Debugger
wire    w_arstn;
// wire	w_sysclk_mcu_arstn;
// wire	w_sysclk_mcu_arst;
wire	w_mipi_rx_pclk_arstn;
// FPS旁路只观察CSI输入；与输入、逻辑分析仪使用同一50MHz时钟。
wire [15:0] fps_telemetry_word;
wire fps_packet_start, fps_ready;
wire [31:0] allmode_camera_gray,allmode_raw_gray,allmode_rejected_gray;
wire [4:0] allmode_rejection_reasons;
wire w_mipi_rx_vs,w_mipi_rx_hs,w_mipi_rx_de;
camera_fps_monitor fps_monitor_inst (
    .clk(i_mipi_rx_pclk), .rst_n(w_mipi_rx_pclk_arstn),
    .vs(w_mipi_rx_vs), .hs(w_mipi_rx_hs), .de(w_mipi_rx_de),
    .telemetry_word(fps_telemetry_word), .packet_start(fps_packet_start),
    .measurement_ready(fps_ready),.complete_frame_gray(allmode_camera_gray),
    .raw_frame_gray(allmode_raw_gray),.rejected_frame_gray(allmode_rejected_gray),
    .rejection_reasons(allmode_rejection_reasons)
);

wire	w_mipi_rx_pclk_arst;

wire	[63:0]			w_mipi_rx_data	;

wire					io_systemReset;



//===================================================================================================
//reset module
//===================================================================================================

assign w_arstn  		       = i_pll_locked & pll_locked & user_pll_locked;
assign pll_inst1_RSTN  		= i_arstn;
assign USER_PLL_RSTN      		= i_arstn;
assign mipi_dsi_tx_pll_RSTN 	= i_arstn;
assign DDR3_PLL_RSTN 		= i_arstn;
reset_ctrl
#(
	.NUM_RST		(2),
	.CYCLE			(1),
	.IN_RST_ACTIVE	(4'b00),
	.OUT_RST_ACTIVE	(4'b10)
)
inst_reset_ctrl
(
	.i_arst		({2{w_arstn}}),//({{4{i_pll_locked}},                  {2{i_arstn}}}),
	.i_clk			({2{i_mipi_rx_pclk}}),
	.o_srst		({w_mipi_rx_pclk_arst, w_mipi_rx_pclk_arstn})
);



reg [25:0] cnt = 'd0;
always @( posedge core_clk)
begin 
       cnt <= cnt + 1'b1;
end
// P13/N13 are KEY1/KEY2 inputs. Never drive these pads as LEDs.
assign led[7:2] = 6'b0;

//========================================================================================================
//MIPI RX
//========================================================================================================
wire i_mipi_clk ;
assign i_mipi_clk = core_clk;

		assign	cam_d0_RST		= 1'b0;
		assign	cam_d1_RST		= 1'b0;
		assign  cam_d2_RST = 1'b0;
    assign  cam_d3_RST = 1'b0;
	
wire [15:0] mipi_debug_out;
		

		csi_rx_controller inst_efx_csi2_rx
		(
              .reset_n			(i_arstn),
              .clk				(i_mipi_clk),
              .reset_byte_HS_n	(i_arstn),
              .clk_byte_HS		  (i_cam_ck_CLKOUT),
              .reset_pixel_n		(w_mipi_rx_pclk_arstn),
              .clk_pixel			  (i_mipi_rx_pclk),
              
              .Rx_LP_CLK_P		  (i_cam_ck_LP_P_IN),
              .Rx_LP_CLK_N		  (i_cam_ck_LP_N_IN),
              .Rx_HS_enable_C		(o_cam_ck_HS_ENA),
              .LVDS_termen_C		(o_cam_ck_HS_TERM),
              
              .Rx_LP_D_P			({cam_d3_LP_P_IN, cam_d2_LP_P_IN, cam_d1_LP_P_IN, cam_d0_LP_P_IN}),//(r_mipi_rx_data_LP_P_IN_2P),
              .Rx_LP_D_N			({cam_d3_LP_N_IN, cam_d2_LP_N_IN, cam_d1_LP_N_IN, cam_d0_LP_N_IN}),//(r_mipi_rx_data_LP_N_IN_2P),
              .Rx_HS_D_0			(cam_d0_HS_IN),//(r_mipi_rx_data_HS_IN_2P[0*8+:8]),
              .Rx_HS_D_1			(cam_d1_HS_IN),//(r_mipi_rx_data_HS_IN_2P[1*8+:8]),
              .Rx_HS_D_2			(cam_d2_HS_IN),
              .Rx_HS_D_3			(cam_d3_HS_IN),
              .Rx_HS_D_4			(),
              .Rx_HS_D_5			(),
              .Rx_HS_D_6			(),
              .Rx_HS_D_7			(),
              .Rx_HS_enable_D		({cam_d3_HS_ENA    ,cam_d2_HS_ENA    ,cam_d1_HS_ENA    ,cam_d0_HS_ENA    }),//( w_cam_d_HS_ENA),
              .LVDS_termen_D		({cam_d3_HS_TERM   ,cam_d2_HS_TERM   ,cam_d1_HS_TERM   ,cam_d0_HS_TERM   }),
              .fifo_rd_enable		({cam_d3_FIFO_RD   ,cam_d2_FIFO_RD   ,cam_d1_FIFO_RD   ,cam_d0_FIFO_RD   }),
              .fifo_rd_empty		({cam_d3_FIFO_EMPTY,cam_d2_FIFO_EMPTY,cam_d1_FIFO_EMPTY,cam_d0_FIFO_EMPTY}),
              .DLY_enable_D		       (),
              .DLY_inc_D			(),
              .u_dly_enable_D		(),
              .u_dly_inc_D		       (),
              
              .axi_clk			(1'b0),
              .axi_reset_n		       (1'b0),
              .axi_awaddr			(6'b0),
              .axi_awvalid		       (1'b0),
              .axi_awready		       (),
              .axi_wdata			(32'b0),
              .axi_wvalid			(1'b0),
              .axi_wready			(),
              
              .axi_bvalid			(),
              .axi_bready			(1'b0),
              .axi_araddr			(6'b0),
              .axi_arvalid		       (1'b0),
              .axi_arready		       (),
              .axi_rdata			(),
              .axi_rvalid			(),
              .axi_rready			(1'b1),
              
              .hsync_vc0			(w_mipi_rx_hs),
              .hsync_vc1			(),
              .hsync_vc2			(),
              .hsync_vc3			(),
              .vsync_vc0			(w_mipi_rx_vs),
              .vsync_vc1			(),
              .vsync_vc2			(),
              .vsync_vc3			(),
              .vc				(),
              .word_count			(),
              .shortpkt_data_field        (),
              .datatype			(),
              .pixel_per_clk		(),
              .pixel_data			(w_mipi_rx_data),
              .pixel_data_valid	       (w_mipi_rx_de),
              .irq				(),
              .mipi_debug_out(mipi_debug_out)
		);

//     wire		       w1_mipi_rx_vs;
// wire		       w1_mipi_rx_hs;
// wire	       w1_mipi_rx_de;
// wire	[39:0]			w1_mipi_rx_data	;
// sensor_clipper  sensor_clipper_inst (
//     .clk(i_mipi_rx_pclk),
//     .i_vs(w_mipi_rx_vs),
//     .i_hs(w_mipi_rx_hs),
//     .i_de(w_mipi_rx_de),
//     .i_dat(w_mipi_rx_data[39:0]),

//     .o_hs(w1_mipi_rx_hs),
//     .o_vs(w1_mipi_rx_vs),
//     .o_de(w1_mipi_rx_de),
//     .o_dat(w1_mipi_rx_data)
   
//   );


wire mdebug_pixel_fifo_full     = mipi_debug_out[0] ;
wire mdebug_pixel_fifo_empty    = mipi_debug_out[1] ;
wire mdebug_crc_error           = mipi_debug_out[2] ;
wire mdebug_ecc_1bit_error      = mipi_debug_out[3] ;
wire mdebug_ecc_2bit_error      = mipi_debug_out[4] ;
wire mdebug_undersize_pkt_error = mipi_debug_out[5] ;
wire mdebug_line_vc0_error      = mipi_debug_out[6] ;
wire mdebug_frame_vc0_error    = mipi_debug_out[10];   
wire mdebug_receive_error      = mipi_debug_out[14];


//========================================================================================================
//
//========================================================================================================
		

//*************** imx219 config********************/
// mipi_config_imx219_top u_config_imx219(
// 										.i_sys_clk(CLK_5M)    	,    /////48M 
// 										.sys_rstn(vid_rst_n )    ,
// 										.o_sen_rst_n(o_cam_rstn)  	,
										
										// .o_iic_sda_OE(io_cam_sda_OE) ,
										// .i_iic_sda(io_cam_sda_IN)   	,
										// .o_iic_sda(io_cam_sda_OUT)   	,
										// .o_iic_scl(io_cam_scl)    	
										// ); 	

wire scl_padoen_o;
wire sda_padoen_o;


reg [12:0] i2c_rst_cnt = '0;

always @( posedge CLK_5M or negedge w_arstn )
begin
    if( !w_arstn )
       i2c_rst_cnt <= 'd0;
    else 
       i2c_rst_cnt <= i2c_rst_cnt[12] ? i2c_rst_cnt : i2c_rst_cnt + 1'b1;
end
wire i2c_rst_n = i2c_rst_cnt[12];

i2c_master_ctrl_top u2_i2c_master_ctrl_top(
  /*i*/.clk			(CLK_5M		),
  /*i*/.rst_n			(i2c_rst_n		),
  /*i*/.scl_pad_i     (io_cam_scl_IN),//(1'b1),
  /*o*/.scl_pad_o     (io_cam_scl_OUT),
  /*o*/.scl_padoen_o  (scl_padoen_o),
  /*i*/.sda_pad_i     (io_cam_sda_IN),
  /*o*/.sda_pad_o     (io_cam_sda_OUT),
  /*o*/.sda_padoen_o  (sda_padoen_o)
  
  );
assign o_cam_rst_p = ~w_arstn;
assign io_cam_scl_OE = ~scl_padoen_o;
assign io_cam_sda_OE = ~sda_padoen_o;

//=====================================================================================
//frame buffer
//=====================================================================================
wire [7:0] 	ch0_r;
wire [7:0]    ch0_g;
wire [7:0]    ch0_b;
wire vid_rst_n;
wire [2:0] algorithm_display_mode;
wire camera_rgb_vs, camera_rgb_hs, camera_rgb_de;
wire [47:0] camera_rgb_datax2;
wire ch0_vs;
wire ch0_hs;
wire ch0_de;

wire  [16-1:0] m_axis_tdata;
wire           m_axis_tvalid;
wire           m_axis_tready;
wire           m_axis_tlast;
wire           m_axis_tuser;
wire  fifo_rd_period;
// History control crosses video -> AXI via a stable handshake mailbox.
wire [1:0] history_requested_mode,history_actual_mode;
wire [5:0] history_requested_position,history_actual_position;
wire history_command_pulse,history_command_ready,history_command_axi;
wire [91:0] history_command_data;
wire [79:0] history_status_video;
wire compare_requested,compare_read_mode,compare_rgb_valid,compare_rgb_ready;
wire video_source_valid;wire [5:0] video_source_slot,canny_source_slot;
wire [63:0] video_source_id,canny_source_pins,canny_source_frame;
reg freeze_from_canny=0,freeze_anchor_valid=0;
reg [63:0] freeze_anchor_id=0;
always @(posedge vid_clk_dvi2)begin
 if(!vid_rst_n)begin freeze_from_canny<=0;freeze_anchor_valid<=0;freeze_anchor_id<=0;end
 else if(history_command_pulse)begin
   freeze_from_canny<=history_requested_mode==1&&algorithm_display_mode==5&&!compare_requested;
   freeze_anchor_valid<=canny_display_valid;
   freeze_anchor_id<=canny_source_frame;
 end else if(freeze_from_canny&&!freeze_anchor_valid&&canny_display_valid)begin
   freeze_anchor_valid<=1;freeze_anchor_id<=canny_source_frame;
 end
end
wire [5:0] compare_requested_a,compare_requested_b;
wire [47:0] compare_rgb;
wire [129:0] compare_status_axi,compare_status_video;
reg compare_show=0,compare_frame_missing=0;
reg [9:0] compare_x=0;reg [10:0] compare_y=0;
reg [31:0] compare_missing_frames=0;
wire [6:0] history_count;
wire [63:0] history_source_frame;
wire history_fault;
reg history_command_pending=0;
wire freeze_canny_request=history_requested_mode==1&&algorithm_display_mode==5&&!compare_requested;
wire history_send_valid=history_command_pending&&(!freeze_canny_request||canny_display_valid);
always @(posedge vid_clk_dvi2)begin
 if(!vid_rst_n)history_command_pending<=0;
 else if(history_command_pulse)history_command_pending<=1;
 else if(history_send_valid&&history_command_ready)history_command_pending<=0;
end
frame_descriptor_mailbox #(.WIDTH(92)) history_commands(
 .src_clk(vid_clk_dvi2),.src_rst(!vid_rst_n),.src_valid(history_send_valid),.src_ready(history_command_ready),
 .src_data({freeze_canny_request&&canny_display_valid,canny_source_slot,canny_source_frame,compare_requested,compare_requested_a,compare_requested_b,history_requested_mode,history_requested_position}),.dst_clk(core_clk),.dst_rst(!vid_rst_n),
 .dst_valid(history_command_axi),.dst_ready(1'b1),.dst_data(history_command_data));
// IMX219
  history_frame_buffer #(
.I_VID_WIDTH         (32),
.O_VID_WIDTH         (16),
.START_ADDR          (32'h00000        ),
.AXI_DATA_WIDTH      ( AXI_DATA_WIDTH	),
.AXI_ADDR_WIDTH      ( AXI_ADDR_WIDTH	),
.WR_FIFO_DEPTH	      ( 1024		),    
.RD_FIFO_DEPTH 	      ( 1024 	),
.BURST_LEN  	        (127),
.FB_NUM	              (3),
.MAX_VID_WIDTH	      (960) ,
.MAX_VID_HIGHT	      (1080),
.O_FRAME_WIDTH      (960),
.O_FRAME_HEIGHT     (1080)

)checker0(
 .i_hs(w_mipi_rx_hs),
 .command_freeze_valid(history_command_data[91]),.command_freeze_slot(history_command_data[90:85]),.command_freeze_id(history_command_data[84:21]),
 .processing_source_pins(canny_source_pins),.video_source_valid(video_source_valid),.video_source_slot(video_source_slot),.video_source_id(video_source_id),
 .command_valid(history_command_axi),.command_mode(history_command_data[7:6]),.command_index(history_command_data[5:0]),
 .command_compare(history_command_data[20]),.command_a(history_command_data[19:14]),.command_b(history_command_data[13:8]),
 .video_rgb_vs(camera_rgb_vs),.video_rgb_de(camera_rgb_de),.video_rgb(camera_rgb_datax2),
 .compare_rgb(compare_rgb),.compare_rgb_valid(compare_rgb_valid),.compare_rgb_ready(compare_rgb_ready),
 .compare_read_mode(compare_read_mode),.compare_status(compare_status_axi),
 .bresp(s_axi_bresp),.playback_mode(history_actual_mode),.playback_position(history_actual_position),
 .history_count(history_count),.source_frame_id(history_source_frame),.history_fault(history_fault),
       .axi_clk		(core_clk 	        ),
       .rst_n			(vid_rst_n   ),

/*i*/.i_clk			(i_mipi_rx_pclk      ),
/*i*/.i_vs			(w_mipi_rx_vs	),
/*i*/.i_de			(w_mipi_rx_de & w_mipi_rx_hs	),
// PIXEL-ORDER-001: RAW10 P0 is bits[9:0]. DDR unpack emits the MS halfword first;
// each downstream two-pixel word emits its low byte first. Pack {P1,P0,P3,P2}
// so the visible stream is P0,P1,P2,P3 (the old packing yielded P2,P3,P0,P1).
/*i*/.vin 			({w_mipi_rx_data[19:12],w_mipi_rx_data[9:2],w_mipi_rx_data[39:32],w_mipi_rx_data[29:22]}	),
                     
/*i*/.o_clk			(vid_clk_dvi2),//(i_mipi_rx_pclk	),                  
/*i*/.fifo_rd_period(fifo_rd_period),//(fifo_rd_period  ),

    .m_axis_tdata  (m_axis_tdata),
    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tuser  (m_axis_tuser),
    .m_axis_tlast  (m_axis_tlast),
	

       .awid			(s_axi_awid	),      
       .awaddr		(s_axi_awaddr	),
       .awlen			(s_axi_awlen	),
       .awsize		(s_axi_awsize	),
       .awburst		(s_axi_awburst),
       .awprot    (s_axi_awprot ),
       .awcache   (s_axi_awcache),
       .awlock		(s_axi_awlock	),
       .awvalid		(s_axi_awvalid),
       .awready		(s_axi_awready),

       .arid			(s_axi_arid	  ),
       .araddr		(s_axi_araddr	),
       .arlen			(s_axi_arlen	),
       .arsize		(s_axi_arsize	),
       .arburst 	(s_axi_arburst),

       .arprot    (s_axi_arprot ),
       .arcache   (s_axi_arcache),
       .arlock 		(s_axi_arlock	),
       .arvalid		(s_axi_arvalid),
       .arready		(s_axi_arready),

       .wdata			(s_axi_wdata	),
       .wstrb			(s_axi_wstrb	),
       .wlast			(s_axi_wlast	),
       .wvalid		(s_axi_wvalid	),
       .wready		(s_axi_wready	),


       .rid			  (s_axi_rid	),
       .rdata			(s_axi_rdata	),
       .rlast			(s_axi_rlast	),
       .rvalid 		(s_axi_rvalid	),
       .rready		(s_axi_rready	),
       .rresp			(s_axi_rresp	),

       .bid			  (s_axi_bid	),
       .bvalid		(s_axi_bvalid	),
       .bready	  (s_axi_bready	)
);

		    
		    
cvo_axi # (
    .SYMBOL_WIDTH(8),
    .SYMBOL_NUM(1),
    .PIXEL_NUM(2),
    .HSYNC_POL(1),
    .VSYNC_POL(1),
    .FIFO_DEPTH(1024),
    .FIFO_ALMOST_FULL(1000),
    .MAX_H_VALID(1920),
    .MAX_V_VALID(1080)
  )
  cvo_axi_inst (
    .o_clk          (vid_clk_dvi2   ),
    .rst_n          (vid_rst_n      ),
    .fifo_rd_period (fifo_rd_period ),
    .s_axi_clk      (vid_clk_dvi2   ),
    .s_axis_tdata   (m_axis_tdata   ),
    .s_axis_tvalid  (m_axis_tvalid  ),
    .s_axis_tready  (m_axis_tready  ),
    .s_axis_tlast   (m_axis_tlast   ),
    .s_axis_tuser   (m_axis_tuser   ),
    .H_FRONT_PORCH  (HFP            ),
    .H_SYNC         (HSP            ),
    .H_VALID        (HACT           ),
    .H_BACK_PORCH   (HBP            ),
    .V_FRONT_PORCH  (VFP            ),
    .V_SYNC         (VSP            ),
    .V_VALID        (VACT           ),
    .V_BACK_PORCH   (VBP            ),
     .vout          ({ch0_b,ch0_g}  ),
    .o_hs           (ch0_hs         ),
    .o_vs           (ch0_vs         ),
    .o_de           (ch0_de         )
  );		       


// Efinity Catalog DDR3 Soft Controller 5.16; see ip/frame_ddr3/settings.json.
wire  axi_avalid;
wire  axi_aready;
wire  axi_atype;
wire [7:0] axi_aid;
wire [31:0] axi_aaddr;
wire [7:0] axi_alen;
wire [2:0] axi_asize;
wire [1:0] axi_aburst;
wire [1:0] axi_alock;
wire  axi_wvalid;
wire  axi_wready;
wire [7:0] axi_wid;
wire [127:0] axi_wdata;
wire [15:0] axi_wstrb;
wire  axi_wlast;
wire  axi_bvalid;
wire  axi_bready;
wire [7:0] axi_bid;
wire [1:0] axi_bresp;
wire  axi_rvalid;
wire  axi_rready;
wire [127:0] axi_rdata;
wire [7:0] axi_rid;
wire [1:0] axi_rresp;
wire  axi_rlast;
wire catalog_fault, catalog_done, catalog_pass;
reg [1:0] catalog_ready_sync;
always @(posedge core_clk or negedge w_arstn)
  if(!w_arstn) catalog_ready_sync<=0;
  else catalog_ready_sync<={catalog_ready_sync[0],catalog_done&&catalog_pass};
assign cal_done=catalog_ready_sync[1];
assign ddr_ck_hi=1'b0; assign ddr_ck_lo=1'b1;
assign app_sr_active=0; assign app_ref_ack=0; assign app_zq_ack=0;
assign wrlvl_dq_check=0; assign rd_level_dqs_check=0; assign init_cur_state=0; assign idelay_ld=0; assign mpr_rdlvl_dly=0;
catalog_axi_adapter catalog_bus (
.clk(core_clk),
.rst(!w_arstn),
.enable(cal_done),
.s_awvalid(canny_ddr_awvalid),
.s_awready(canny_ddr_awready),
.s_awaddr(canny_ddr_awaddr),
.s_awid(canny_ddr_awid),
.s_awlen(canny_ddr_awlen),
.s_awsize(canny_ddr_awsize),
.s_awburst(canny_ddr_awburst),
.s_wvalid(canny_ddr_wvalid),
.s_wready(canny_ddr_wready),
.s_wdata(canny_ddr_wdata),
.s_wstrb(canny_ddr_wstrb),
.s_wlast(canny_ddr_wlast),
.s_bvalid(canny_ddr_bvalid),
.s_bready(canny_ddr_bready),
.s_bid(canny_ddr_bid),
.s_bresp(canny_ddr_bresp),
.s_arvalid(canny_ddr_arvalid),
.s_arready(canny_ddr_arready),
.s_araddr(canny_ddr_araddr),
.s_arid(canny_ddr_arid),
.s_arlen(canny_ddr_arlen),
.s_arsize(canny_ddr_arsize),
.s_arburst(canny_ddr_arburst),
.s_rvalid(canny_ddr_rvalid),
.s_rready(canny_ddr_rready),
.s_rdata(canny_ddr_rdata),
.s_rid(canny_ddr_rid),
.s_rresp(canny_ddr_rresp),
.s_rlast(canny_ddr_rlast),
.axi_avalid(axi_avalid),
.axi_aready(axi_aready),
.axi_atype(axi_atype),
.axi_aid(axi_aid),
.axi_aaddr(axi_aaddr),
.axi_alen(axi_alen),
.axi_asize(axi_asize),
.axi_aburst(axi_aburst),
.axi_alock(axi_alock),
.axi_wvalid(axi_wvalid),
.axi_wready(axi_wready),
.axi_wid(axi_wid),
.axi_wdata(axi_wdata),
.axi_wstrb(axi_wstrb),
.axi_wlast(axi_wlast),
.axi_bvalid(axi_bvalid),
.axi_bready(axi_bready),
.axi_bid(axi_bid),
.axi_bresp(axi_bresp),
.axi_rvalid(axi_rvalid),
.axi_rready(axi_rready),
.axi_rdata(axi_rdata),
.axi_rid(axi_rid),
.axi_rresp(axi_rresp),
.axi_rlast(axi_rlast),
.fault(catalog_fault)
);
frame_ddr3 u_frame_ddr3 (
.clk(core_clk),
.core_clk(tx_cal_clk),
.twd_clk(tx_cal_clk_90edge),
.tdqss_clk(sdram_clk),
.tac_clk(rx_cal_clk),
.reset_n(w_arstn),
.reset(ddr_reset_n),
.cs(ddr_cs_n),
.ras(ddr_ras_n),
.cas(ddr_cas_n),
.we(ddr_we_n),
.cke(ddr_cke),
.addr(ddr_addr),
.ba(ddr_ba),
.odt(ddr_odt),
.shift(pll_shift),
.shift_sel(pll_shift_sel),
.shift_ena(pll_shift_ena),
.cal_ena(1'b1),
.cal_done(catalog_done),
.cal_pass(catalog_pass),
.cal_shift_val(),
.cal_fail_log(),
.o_dm_hi(ddr_dm_hi),
.o_dm_lo(ddr_dm_lo),
.i_dqs_hi(ddr_dqs_in_hi),
.i_dqs_lo(ddr_dqs_in_lo),
.i_dqs_n_hi(~ddr_dqs_in_hi),
.i_dqs_n_lo(~ddr_dqs_in_lo),
.o_dqs_hi(ddr_dqs_out_hi),
.o_dqs_lo(ddr_dqs_out_lo),
.o_dqs_n_hi(),
.o_dqs_n_lo(),
.o_dqs_oe(ddr_dqs_oe),
.o_dqs_n_oe(ddr_dqs_oe_n),
.i_dq_hi(ddr_dq_in_hi),
.i_dq_lo(ddr_dq_in_lo),
.o_dq_hi(ddr_dq_out_hi),
.o_dq_lo(ddr_dq_out_lo),
.o_dq_oe(ddr_dq_oe),
.axi_avalid(axi_avalid),
.axi_aready(axi_aready),
.axi_atype(axi_atype),
.axi_aid(axi_aid),
.axi_aaddr(axi_aaddr),
.axi_alen(axi_alen),
.axi_asize(axi_asize),
.axi_aburst(axi_aburst),
.axi_alock(axi_alock),
.axi_wvalid(axi_wvalid),
.axi_wready(axi_wready),
.axi_wid(axi_wid),
.axi_wdata(axi_wdata),
.axi_wstrb(axi_wstrb),
.axi_wlast(axi_wlast),
.axi_bvalid(axi_bvalid),
.axi_bready(axi_bready),
.axi_bid(axi_bid),
.axi_bresp(axi_bresp),
.axi_rvalid(axi_rvalid),
.axi_rready(axi_rready),
.axi_rdata(axi_rdata),
.axi_rid(axi_rid),
.axi_rresp(axi_rresp),
.axi_rlast(axi_rlast)
);

//***************************************************************************
// debayer
//***************************************************************************


wire        rgb_vs;
wire        rgb_hs;
wire        rgb_de;
wire        rgb_valid;
wire [47:0] rgb_datax2;

// 普通室内照度首版灵敏度；整帧快照仍由原桥接层负责。
localparam [10:0] SOBEL_EDGE_THRESHOLD = 11'd64;
wire algorithm_sticky_fault;

// 与桥接同在74.25MHz域；桥接把模式绑定到整帧及在途像素。
wire [10:0] pending_threshold,active_threshold,pending_canny_high;
wire [1:0] pending_filter,active_filter;
wire [2:0] active_mode;
wire [31:0] pending_config_id;
wire menu_open,pending_edge_enhance,active_edge_enhance;
wire [2:0] menu_item;
wire [4:0] key_levels_n;
wire bridge_vs,bridge_hs,bridge_de;
wire [47:0] bridge_rgb;
wire allmode_algorithm_complete,allmode_display_missing;
wire [63:0] allmode_counts,allmode_rates;
wire [31:0] allmode_source_counts,allmode_source_rates;
wire [4:0] allmode_source_reasons;
wire [15:0] allmode_errors;
wire allmode_rates_valid;
allmode_fps_monitor mode_fps_measurement (
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),.camera_gray_async(allmode_camera_gray),
    .mode(active_mode),.vs(bridge_vs),.de(bridge_de),
    .raw_gray_async(allmode_raw_gray),.rejected_gray_async(allmode_rejected_gray),
    .rejection_reasons_async(allmode_rejection_reasons),
    .source_counts(allmode_source_counts),.source_rates(allmode_source_rates),.source_reasons(allmode_source_reasons),
    .algorithm_complete(allmode_algorithm_complete),.display_missing(allmode_display_missing),
    .canny_jobs(canny_debug[15:0]),.canny_frame(canny_display_scope[15:0]),
    .canny_available(show_canny&&canny_display_valid&&!canny_quarantined),
    .counts(allmode_counts),.rates(allmode_rates),.bad_frames(allmode_errors),.rates_valid(allmode_rates_valid)
);
integration_controls #(.HISTORY_AVAILABLE(1),.CANNY_ONLY_AVAILABLE(1),.EDGE_SELECT_AVAILABLE(1),.DEFAULT_EDGE_ENHANCE(0)) fullscreen_mode_control (
    .history_display_position((history_status_video[78:77]==2&&history_status_video[76:71]!=0)?history_status_video[76:71]-6'd1:history_status_video[76:71]),
    .history_mode(history_requested_mode),.history_position(history_requested_position),.history_command(history_command_pulse),
    .compare_enable(compare_requested),.compare_a(compare_requested_a),.compare_b(compare_requested_b),
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),.key_mode_n(key_mode_n),
    .key_minus_n(key_minus_n),.key_plus_n(key_plus_n),
    .key_probe_minus_n(key_probe_minus_n),.key_probe_plus_n(key_probe_plus_n),.key_levels_n(key_levels_n),
    .mode(algorithm_display_mode),.threshold(pending_threshold),.canny_high(pending_canny_high),
    .filter_mode(pending_filter),.menu_open(menu_open),.menu_item(menu_item),
    .edge_enhance(pending_edge_enhance),.overlay_canny(),.wide_overlay(),.freeze_request(),.noise_level(),
    .config_id(pending_config_id)
);

wire m5_source_lock=!compare_requested&&(history_requested_mode==1||history_requested_mode==3||history_status_video[78:77]==3);
wire m5_lock_valid=freeze_from_canny?freeze_anchor_valid:video_source_valid;
wire [63:0] m5_lock_id=freeze_from_canny?freeze_anchor_id:video_source_id;
frame_descriptor_mailbox #(.WIDTH(80)) history_status_transfer(
 .src_clk(core_clk),.src_rst(!vid_rst_n),.src_valid(1'b1),.src_ready(),
 .src_data({history_fault,history_actual_mode,history_actual_position,history_count,history_source_frame}),
 .dst_clk(vid_clk_dvi2),.dst_rst(!vid_rst_n),.dst_valid(),.dst_ready(1'b1),.dst_data(history_status_video));
frame_descriptor_mailbox #(.WIDTH(130)) compare_status_transfer(
 .src_clk(core_clk),.src_rst(!vid_rst_n),.src_valid(1'b1),.src_ready(),.src_data(compare_status_axi),
 .dst_clk(vid_clk_dvi2),.dst_rst(!vid_rst_n),.dst_valid(),.dst_ready(1'b1),.dst_data(compare_status_video));
integration_status_osd #(.HISTORY_STATUS(1)) status_overlay (
    .compare_status(compare_status_video),.compare_a_selection(compare_requested_a),.compare_b_selection(compare_requested_b),
    .history_status(history_status_video),
    .source_counts(allmode_source_counts),.source_rates(allmode_source_rates),.source_reasons(allmode_source_reasons),
    .fps_counts(allmode_counts),.fps_rates(allmode_rates),.fps_errors(allmode_errors),.fps_valid(allmode_rates_valid),
    .canny_debug(canny_debug),.canny_perf(canny_perf),.canny_frame(canny_display_scope[15:0]),
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),.in_vs(bridge_vs),.in_hs(bridge_hs),.in_de(bridge_de),
    .in_rgb(display_pixels),.active_mode(active_mode),.active_threshold(show_canny?canny_threshold:active_threshold),
    .active_filter(active_filter),.menu_open(menu_open),
    .active_edge_enhance(active_edge_enhance),.menu_item(menu_item),.key_levels_n(key_levels_n),
    .out_vs(rgb_vs),.out_hs(rgb_hs),.out_de(rgb_de),.out_rgb(rgb_datax2)
);
// 算法只改变像素，不参与相机/DDR/HDMI 的启动条件。
// 沿用已校色基线的实际 RGB 字节含义，低 24 位是前一个像素。
v7_algorithm_video_pair #(.W(1920),.H(1080),.HTOTAL(1100),.RUNTIME_FILTER_CONFIG(1),.RUNTIME_EDGE_CONFIG(1)) algorithm_bridge (
    .clk(vid_clk_dvi2),.rst(!vid_rst_n),
    .in_vs(camera_rgb_vs),.in_hs(camera_rgb_hs),.in_de(camera_rgb_de),
    .in_rgb(camera_rgb_datax2),
     .cfg_mode((compare_status_video[129]||history_status_video[78:77]==2)?3'd0:algorithm_display_mode),.cfg_threshold(pending_threshold),.cfg_median_enable(pending_filter!=0),
    .cfg_detail_enable(pending_filter==2),.cfg_edge_enhance(pending_edge_enhance),.cfg_config_id(pending_config_id),
    .active_mode(active_mode),.active_threshold(active_threshold),.active_filter(active_filter),.active_edge_enhance(active_edge_enhance),
    .out_vs(bridge_vs),.out_hs(bridge_hs),.out_de(bridge_de),.out_rgb(bridge_rgb),
    .scan_vs_early(scan_vs_early),.scan_hs_early(scan_hs_early),.scan_de_early(scan_de_early),.scan_rgb_early(scan_rgb_early),
    .monitor_algorithm_complete(allmode_algorithm_complete),.monitor_display_missing(allmode_display_missing),
    .sticky_fault(algorithm_sticky_fault)
);

// Canny is a side branch. Original bridge HS/VS/DE go straight to original OSD.
// Early taps align the separate Canny reader; no delay added to baseline output.
// Pixel coordinates follow the final bridge timing, before its OSD register.
wire compare_region=compare_y>=270&&compare_y<810;
assign compare_rgb_ready=compare_read_mode&&bridge_de&&compare_region&&!compare_frame_missing;
always @(posedge vid_clk_dvi2)begin
 if(!vid_rst_n)begin compare_x<=0;compare_y<=0;compare_show<=0;compare_frame_missing<=0;compare_missing_frames<=0;end
 else if(bridge_vs&&!bridge_vs_previous)begin
   compare_x<=0;compare_y<=0;compare_show<=compare_status_video[129];compare_frame_missing<=0;
 end else if(bridge_de)begin
   if(compare_x==959)begin compare_x<=0;compare_y<=compare_y+1;end else compare_x<=compare_x+1;
   if(compare_show&&compare_read_mode&&compare_region&&!compare_rgb_valid&&!compare_frame_missing)begin
     compare_frame_missing<=1;compare_missing_frames<=compare_missing_frames+1;
   end
 end
end
assign display_pixels=compare_show?
    ((compare_read_mode&&compare_region&&compare_rgb_valid&&!compare_frame_missing)?compare_rgb:48'd0):
    (active_mode==5&&m5_source_lock&&(!m5_lock_valid||canny_source_frame!=m5_lock_id))?48'd0:
    show_canny&&canny_snapshot_valid?
    {{24{canny_edges[1]}},{24{canny_edges[0]}}}:bridge_rgb;
always @(posedge vid_clk_dvi2)begin
    if(!vid_rst_n)begin
        bridge_vs_previous<=0;show_canny<=0;baseline_frames<=0;
    end else begin
        bridge_vs_previous<=bridge_vs;
        if(bridge_vs&&!bridge_vs_previous)begin
            if(baseline_frames!=3)baseline_frames<=baseline_frames+1'b1;
            show_canny<=active_mode==5&&canny_display_valid&&!canny_quarantined;
        end
    end
end
// Live controls stay in the video clock domain. Only this one-bit request
// crosses to the core; the worker owns its existing configuration mailbox.
(* ASYNC_REG="TRUE" *) reg [1:0] canny_request_sync;
always @(posedge core_clk or negedge vid_rst_n)
    if(!vid_rst_n)canny_request_sync<=0;
    else canny_request_sync<={canny_request_sync[0],algorithm_display_mode==5&&baseline_frames==3&&!compare_requested&&history_status_video[78:77]!=2};
integration_frame_system #(.EDGE_ONLY_DISPLAY(1),.HISTORY_SOURCE(1)) full_frame_canny(
    .source_lock(m5_source_lock),.lock_source_valid(m5_lock_valid),.lock_source_id(m5_lock_id),
    .video_source_valid(video_source_valid),.video_source_slot(video_source_slot),.video_source_id(video_source_id),
    .source_pins(canny_source_pins),.display_source_slot(canny_source_slot),
    .debug_video(canny_debug),.perf_video(canny_perf),
    .core_clk,.video_clk(vid_clk_dvi2),.cold_reset_n(vid_rst_n),.enable(cal_done),
    .worker_enable(canny_request_sync[1]),.bus_reset_n(axi_rst_n),
    .video_vs(camera_rgb_vs),.video_de(camera_rgb_de),.video_rgb(camera_rgb_datax2),
    .scan_vs(scan_vs_early),.scan_hs(scan_hs_early),.scan_de(scan_de_early),.scan_rgb(scan_rgb_early),
    .mode(3'd5),.cfg_threshold(pending_canny_high),.cfg_filter(pending_filter),.cfg_config_id(pending_config_id),
    .freeze_request(freeze_canny_request),.use_snapshot(1'b1),
    .out_edges(canny_edges),.out_snapshot_valid(canny_snapshot_valid),.frozen(),
    .display_scope(canny_display_scope),.display_sensor_frame(canny_source_frame),.display_processing_cycles(),
    .display_recognition(),.display_target_overflow(),.display_target_mask(),.display_target_class(),
    .display_unknown_reasons(),.display_unknown_count(),.display_target_box(),.display_target_center2(),
    .out_vs(),.out_hs(),.out_de(),.out_rgb(),
    .display_valid(canny_display_valid),.display_threshold(canny_threshold),.display_filter(canny_filter),
    .quarantined(canny_quarantined),.completed_jobs(canny_completed),.failed_jobs(canny_failed),.underflow_rows(canny_underflows),
    .b_awvalid(s_axi_awvalid),
    .m_awvalid(canny_ddr_awvalid),
    .b_awready(s_axi_awready),
    .m_awready(canny_ddr_awready),
    .b_awaddr(s_axi_awaddr),
    .m_awaddr(canny_ddr_awaddr),
    .b_awid(s_axi_awid),
    .m_awid(canny_ddr_awid),
    .b_awlen(s_axi_awlen),
    .m_awlen(canny_ddr_awlen),
    .b_awsize(s_axi_awsize),
    .m_awsize(canny_ddr_awsize),
    .b_awburst(s_axi_awburst),
    .m_awburst(canny_ddr_awburst),
    .b_awcache(s_axi_awcache),
    .m_awcache(canny_ddr_awcache),
    .b_awprot(s_axi_awprot),
    .m_awprot(canny_ddr_awprot),
    .b_awlock(s_axi_awlock),
    .m_awlock(canny_ddr_awlock),
    .b_wvalid(s_axi_wvalid),
    .m_wvalid(canny_ddr_wvalid),
    .b_wready(s_axi_wready),
    .m_wready(canny_ddr_wready),
    .b_wdata(s_axi_wdata),
    .m_wdata(canny_ddr_wdata),
    .b_wstrb(s_axi_wstrb),
    .m_wstrb(canny_ddr_wstrb),
    .b_wlast(s_axi_wlast),
    .m_wlast(canny_ddr_wlast),
    .b_bvalid(s_axi_bvalid),
    .m_bvalid(canny_ddr_bvalid),
    .b_bready(s_axi_bready),
    .m_bready(canny_ddr_bready),
    .b_bid(s_axi_bid),
    .m_bid(canny_ddr_bid),
    .b_bresp(s_axi_bresp),
    .m_bresp(canny_ddr_bresp),
    .b_arvalid(s_axi_arvalid),
    .m_arvalid(canny_ddr_arvalid),
    .b_arready(s_axi_arready),
    .m_arready(canny_ddr_arready),
    .b_araddr(s_axi_araddr),
    .m_araddr(canny_ddr_araddr),
    .b_arid(s_axi_arid),
    .m_arid(canny_ddr_arid),
    .b_arlen(s_axi_arlen),
    .m_arlen(canny_ddr_arlen),
    .b_arsize(s_axi_arsize),
    .m_arsize(canny_ddr_arsize),
    .b_arburst(s_axi_arburst),
    .m_arburst(canny_ddr_arburst),
    .b_arcache(s_axi_arcache),
    .m_arcache(canny_ddr_arcache),
    .b_arprot(s_axi_arprot),
    .m_arprot(canny_ddr_arprot),
    .b_arlock(s_axi_arlock),
    .m_arlock(canny_ddr_arlock),
    .b_rvalid(s_axi_rvalid),
    .m_rvalid(canny_ddr_rvalid),
    .b_rready(s_axi_rready),
    .m_rready(canny_ddr_rready),
    .b_rdata(s_axi_rdata),
    .m_rdata(canny_ddr_rdata),
    .b_rid(s_axi_rid),
    .m_rid(canny_ddr_rid),
    .b_rresp(s_axi_rresp),
    .m_rresp(canny_ddr_rresp),
    .b_rlast(s_axi_rlast),
    .m_rlast(canny_ddr_rlast)
);

wire [15:0] r_gain;
wire [15:0] g_gain;
wire [15:0] b_gain;

// 实测RAW行标记支持BGGR，采用P11；Debugger gain/gamma控件不控制画面。
localparam BAYER_Y_PHASE_XOR = 1'b1;
localparam BAYER_RB_SWAP = 1'b1;
// 相机 RAW 先扣黑电平并白平衡；取消诊断图案，保留原始行奇偶标记。
wire [15:0] diagnostic_raw;
wire diagnostic_raw_y_odd;
wire [15:0] balanced_camera_raw;
raw_bggr_balance balance_inst (
    .enable(vid_rst_n && ch0_de), .row_odd(diagnostic_raw_y_odd),
    .raw_in({ch0_b,ch0_g}), .raw_out(balanced_camera_raw)
);
rawcard_overlay rawcard_inst (
    .clk(vid_clk_dvi2), .rst_n(vid_rst_n), .vs(ch0_vs), .de(ch0_de),
    .camera_raw(balanced_camera_raw), .out_raw(diagnostic_raw), .raw_y_odd(diagnostic_raw_y_odd)
);
debayer_top_2to1 #(.Y_PHASE_XOR(BAYER_Y_PHASE_XOR), .RB_SWAP(BAYER_RB_SWAP)) debayer_top
(
	.in_pclk		  (vid_clk_dvi2),//(i_mipi_rx_pclk ),
	.in_rstn		  (vid_rst_n	),
	
	.raw_vs_i		  (ch0_vs		      ),
	.raw_hs_i		  (ch0_hs		      ),
	.raw_de_i		  (ch0_de		      ),
	.raw_valid_i	(ch0_de	        ),
	.raw_datax4_i	(diagnostic_raw),
	.r_gain       (16'h0100),
  .g_gain       (16'h0100),
  .b_gain       (16'h0100),
	.rgb_vs_o		  (camera_rgb_vs  ),
	.rgb_hs_o		  (camera_rgb_hs  ),
	.rgb_de_o		  (camera_rgb_de  ),
	.rgb_valid_o	(rgb_valid      ),
	.rgb_datax2_o (camera_rgb_datax2)//b,g,r,b,g,r
);
reg rgb_vs_r = 'd0;
always @( posedge hdmi_tx_slow_clk )
begin
  rgb_vs_r <= rgb_vs;
end
assign pos_vs = {rgb_vs_r,rgb_vs} == 2'b01;
reg vid_cnt = 'd0;
reg [7:0] hdmi_tx_rdata ;
reg [7:0] hdmi_tx_gdata ;
reg [7:0] hdmi_tx_bdata ;
reg hdmi_tx_vs;
reg hdmi_tx_hs;
reg hdmi_tx_de;
always @( posedge hdmi_tx_slow_clk )
begin
    if( pos_vs )
      vid_cnt <= 1'b1;
    else if( rgb_de )
      vid_cnt <= ~vid_cnt ;

    if( vid_cnt )
      {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[23:0];
    else 
      {hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata} <= rgb_datax2[47:24];

  hdmi_tx_vs <= rgb_vs;
  hdmi_tx_hs <= rgb_hs;
  hdmi_tx_de <= rgb_de;
end
//==============================================================================
// MIPI DSI
//==============================================================================
// signal 

reg		[25:0]	r_rst_cnt;

wire	[31:0]	w_axi_rdata;
wire			w_axi_awready;
wire			w_axi_wready;
wire			w_axi_arready;
wire			w_axi_rvalid;
wire			w_axi_bvalid;

wire	[6:0]	w_axi_awaddr;
wire			w_axi_awvalid;
wire	[31:0]	w_axi_wdata;
wire			w_axi_wvalid;
wire			w_axi_bready;
wire	[6:0]	w_axi_araddr;
wire			w_axi_arvalid;
wire			w_axi_rready;

wire			w_confdone;
assign w_confdone = 1'b1;

assign  LCD_POWER 			= i_arstn;
assign	LCD_RST_P	      = ~w_arstn;//~r_rst_cnt[23]; LCD复位先释放，然后再释放MIPI 的复位
assign	mipi_dp_clk_RST		= ~i_arstn;
assign	mipi_dp_data0_RST	= ~i_arstn;
assign	mipi_dp_data1_RST	= ~i_arstn;
assign	mipi_dp_data2_RST	= ~i_arstn;
assign	mipi_dp_data3_RST	= ~i_arstn;
////////////////////////////////////////////////////////////////
always@(posedge i_mipi_clk or  negedge w_arstn )
begin
  if ( !w_arstn ) begin
    r_rst_cnt	<= 'd0;
  end else 		
    r_rst_cnt	<= r_rst_cnt[25] ? r_rst_cnt :r_rst_cnt + 1'b1;
end

assign axi_rst_n = r_rst_cnt[25];

reg [26:0] dly_cnt = 'd0;

always @( posedge vid_clk_dvi2 or negedge w_arstn )
begin
  if( !w_arstn )
    dly_cnt <= 'd0;
  else if( w_confdone )
    dly_cnt <= dly_cnt[26] ? dly_cnt :(dly_cnt + 1'b1);
  else 
    dly_cnt <= 'd0;
end 

assign vid_rst_n = dly_cnt[26];




wire hs;
wire vs;
wire de;
wire [7:0] rgb_r;
wire [7:0] rgb_g;
wire [7:0] rgb_b;
  
  // color_bar_rgb #(
  // .HS_POLORY 		(1'b1		),
  // .VS_POLORY 		(1'b1		),
  // .H_FRONT_PORCH 	(HFP		),///2
  // .H_SYNC 		(HSP		),//
  // .H_VALID 		(MAX_HRES	),//
  // .H_BACK_PORCH 	(HBP		),//
  // .V_FRONT_PORCH 	(VFP		),
  // .V_SYNC 		(VSP		),
  // .V_VALID 		(MAX_VRES	),
  // .V_BACK_PORCH 	(VBP		),
  // .TEST_MODE 		(2'd2)
  // )u_color_bar_rgb1(
  // /*i*/.clk	(vid_clk_dvi2),//(vid_clk),
  // /*i*/.rst_n	(vid_rst_n),
  // /*o*/.hs	(hs),
  // /*o*/.vs	(vs),
  // /*o*/.de	(de),
  // // /*O*/.h_cnt (h_cnt),
  // // /*O*/.v_cnt (v_cnt),
  // /*o*/.rgb_r	(rgb_r),    //像素数据、红色分量
  // /*o*/.rgb_g	(rgb_g),    //像素数据、绿色分量
  // /*o*/.rgb_b (rgb_b)    //像素数据、蓝色分量
  
  // );

//=================================================================================
//hdmi tx ctrl 
//=================================================================================
wire                            video_hs;
wire                            video_vs;
wire                            video_de;
wire[7:0]                       video_r;
wire[7:0]                       video_g;
wire[7:0]                       video_b;

assign tmds_tx_data0_TX_OE = 1'b1;
assign tmds_tx_data1_TX_OE = 1'b1;
assign tmds_tx_data2_TX_OE = 1'b1;
assign tmds_tx_clk_TX_OE   = 1'b1;

assign tmds_tx_data0_TX_RST = 1'b0;
assign tmds_tx_data1_TX_RST = 1'b0;
assign tmds_tx_data2_TX_RST = 1'b0;
assign tmds_tx_clk_TX_RST   = 1'b0;

// 	  color_bar color_bar_m0(
// 	.clk(hdmi_tx_slow_clk),
// 	.rst(~vid_rst_n),
// 	.hs(video_hs),
// 	.vs(video_vs),
// 	.de(video_de),
// 	.rgb_r(video_r),
// 	.rgb_g(video_g),
// 	.rgb_b(video_b)
// );

wire [9:0] tmds_data0;
wire [9:0] tmds_data1;
wire [9:0] tmds_data2;
wire [9:0] tmds_clk ;
wire [7:0] gamma_rdata ;
wire [7:0] gamma_gdata ;
wire [7:0] gamma_bdata ;
wire gamma_valid;
wire gamma_hs;
wire gamma_vs;
wire gamma_sel;
wire vio_gamma_sel_unused; // 保留调试接口，但实验旁路由常量确定，避免多驱动。
assign gamma_sel = 1'b0;

wire [7:0] con_rdata ;
wire [7:0] con_gdata ;
wire [7:0] con_bdata ;
wire con_de;
wire con_hs;
wire con_vs;
wire con_sel;

wire [7:0] BRIGHT_SIG    ;
wire CONTRAST_SIG_G;
wire CONTRAST_SIG_R;
wire [7:0] CONTRAST_G    ;
wire CONTRAST_SIG_B;
wire [7:0] BRIGHT        ;
wire [7:0] CONTRAST_R    ;


wire CONTRAST_B    ;


gamma_correction
#(
	.DATA_WIDTH		(8),
	.GAMMA_CURVE	("./rtl/gamma_conrrection/2P2.mem")
)
inst_gamma_correction
(
	.i_pclk		(hdmi_tx_slow_clk),
	.i_rstn		(vid_rst_n),
	
	.i_red		(hdmi_tx_rdata),//(con_rdata  ),//
	.i_green	(hdmi_tx_gdata),//(con_gdata  ),//
	.i_blue		(hdmi_tx_bdata),//(con_bdata  ),//
  .i_valid	(hdmi_tx_de   ),//(con_de     ),//
  .i_hs     (hdmi_tx_hs   ),//(con_hs     ),//
  .i_vs     (hdmi_tx_vs   ),//(con_vs     ),//
	.o_blue		(gamma_bdata		),
  .o_green	(gamma_gdata	  ),
	.o_red		(gamma_rdata		),
	.o_valid	(gamma_valid	  ),
  .o_hs     (gamma_hs       ),
  .o_vs     (gamma_vs       )
);

// 旧信号 hdmi_tx_bdata 实际接编码器 R，维持已验证的 RGB 显示顺序。
wire [7:0] card_r = hdmi_tx_bdata;
wire [7:0] card_g = hdmi_tx_gdata;
wire [7:0] card_b = hdmi_tx_rdata;

dvi_encoder dvi_encoder_m0
(
	.pixelclk      		(hdmi_tx_slow_clk          ),// system clock
	.rst_p         		(~vid_rst_n      ),// reset
	.i_bdata      		(card_b),//(hdmi_tx_rdata ),//(video_b            ),//(bdata_in	),   //
	.i_gdata     		  (card_g),//(hdmi_tx_gdata ),//(video_g            ),//(gdata_in	),   //   
	.i_rdata       		(card_r),//(hdmi_tx_bdata ),//(video_r            ),//(rdata_in	),   //   
  .i_de            	(gamma_sel ? gamma_valid	: hdmi_tx_de      ),//(hdmi_tx_de    ),//(video_de           ),//(rx_de		  ),   //
	.i_hs         		(gamma_sel ? gamma_hs	    : hdmi_tx_hs    ),//(video_hs           ),//(rx_hsync	),   //   
	.i_vs         		(gamma_sel ? gamma_vs	    : hdmi_tx_vs    ),//(video_vs           ),//(rx_vsync	),   //  
	
  .video_format     (2'b00), //// 00 = RGB, 01 = YCbCr 4:2:2, 10 = YCbCr 4:4:4
  .video_VIC        (0),
	.audio_L			    (audio_L),
  .audio_R			    (audio_R),
  .audio_valid		  (audio_valid),
  .audio_N                (6144),     //(20'h01880),//     
  .audio_CTS              (148500),      //(20'h28488),//      
  .audio_sample_frequency (audio_samp_freq),    //(3'b000),// 
  .audio_word_length      ({audio_samp_word_len,audio_max_word_length}),//(4'b1011),//

	.tmds_data0    		(tmds_data0),
  .tmds_data1    		(tmds_data1),
  .tmds_data2    		(tmds_data2),
  .tmds_clk      	  (tmds_clk  )
);
assign tmds_tx_clk_TX_DATA   = ~tmds_clk;
assign tmds_tx_data0_TX_DATA = ~tmds_data0;
assign tmds_tx_data1_TX_DATA = ~tmds_data1;
assign tmds_tx_data2_TX_DATA = ~tmds_data2;

// The legacy gain/gamma VIO outputs are unused (gains already constant).
// Disable its capture-only analyzer in the frame-buffer fit; on-screen counters
// remain available and JTAG programming is independent of this user debug chain.
generate if(1'b0)begin: legacy_capture_debug
debug_edb_top debug_edb_top_inst (
    .bscan_CAPTURE      ( jtag_inst1_CAPTURE  ),
    .bscan_DRCK         ( jtag_inst1_DRCK     ),
    .bscan_RESET        ( jtag_inst1_RESET    ),
    .bscan_RUNTEST      ( jtag_inst1_RUNTEST  ),
    .bscan_SEL          ( jtag_inst1_SEL      ),
    .bscan_SHIFT        ( jtag_inst1_SHIFT    ),
    .bscan_TCK          ( jtag_inst1_TCK      ),
    .bscan_TDI          ( jtag_inst1_TDI      ),
    .bscan_TMS          ( jtag_inst1_TMS      ),
    .bscan_UPDATE       ( jtag_inst1_UPDATE   ),
    .bscan_TDO          ( jtag_inst1_TDO      ),
    .vio0_clk           ( vid_clk_dvi2        ),
    .vio0_r_gain        ( r_gain              ),
    .vio0_g_gain        ( g_gain              ),
    .vio0_b_gain        ( b_gain              ),

    .vio0_gamma_sel     (vio_gamma_sel_unused),
    .la0_clk            ( i_mipi_rx_pclk      ),
    .la0_ch0_g          ( fps_telemetry_word[7:0] ),
    .la0_ch0_b          ( fps_telemetry_word[15:8] ),
    .la0_ch0_de         ( fps_packet_start    ),
    .la0_cal_done       ( fps_ready ) // FPS ONLY: packet ready flag; NOT DDR cal_done
);
end else begin: no_legacy_capture_debug
 // Retain the required user-chain TDI interface pin with a bypass connection.
 // Configuration/JTAG download uses the device controller, not this user chain.
 assign jtag_inst1_TDO=jtag_inst1_TDI;
 assign r_gain=16'h0100;assign g_gain=16'h0100;assign b_gain=16'h0100;
 assign vio_gamma_sel_unused=1'b0;
end endgenerate

endmodule
