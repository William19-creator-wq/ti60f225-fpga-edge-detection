// synopsys translate_off
`timescale 1 ns / 1 ps													
// synopsys translate_on

module `IP_MODULE_NAME(efx_csi2_tx) #(
    parameter tLPX_NS = 50,
    parameter tINIT_NS = 100000,
    parameter tINIT_SKEWCAL_NS = 100000,
    parameter tLP_EXIT_NS = 100,
    parameter tCLK_ZERO_NS = 262,
    parameter tCLK_TRAIL_NS = 60,
    parameter tCLK_POST_NS = 60,
    parameter tCLK_PRE_NS = 10,
    parameter tCLK_PREPARE_NS = 38,
    parameter tHS_PREPARE_NS = 40,
    parameter tWAKEUP_NS = 1000,
    parameter tHS_EXIT_NS = 100,
    parameter tHS_ZERO_NS = 105,
    parameter tHS_TRAIL_NS = 60, 
    parameter NUM_DATA_LANE = 4,
    parameter HS_BYTECLK_MHZ = 187,
    parameter CLOCK_FREQ_MHZ = 100,
    parameter DPHY_CLOCK_MODE = "Continuous", ////"Continuous", "Discontinuous"
    parameter PACK_TYPE = 4'b1111,
    parameter PIXEL_FIFO_DEPTH = 2048,  //if double buffering is enable, 2 power value of DEPTH = (MAX_HRES/8) x 2
    parameter ENABLE_VCX = 0,
    parameter FRAME_MODE = "GENERIC",    //1-ACCURATE, 0-GENERIC
    parameter ASYNC_STAGE = 2
)(
    input logic           reset_n,
    input logic           clk,				//100Mhz
    input logic           reset_byte_HS_n,
    input logic           clk_byte_HS,
    input logic           reset_pixel_n,
    input logic           clk_pixel,
    // LVDS clock lane   
	output logic          Tx_LP_CLK_P,	
	output logic          Tx_LP_CLK_P_OE,	
	output logic          Tx_LP_CLK_N,
	output logic          Tx_LP_CLK_N_OE,
	output logic [7:0]    Tx_HS_C,
	output logic          Tx_HS_enable_C,
	
	// ----- DLane 0 -----------
    // LVDS data lane
    output logic [NUM_DATA_LANE-1:0]         Tx_LP_D_P,
    output logic [NUM_DATA_LANE-1:0]         Tx_LP_D_P_OE, 
	output logic [NUM_DATA_LANE-1:0]         Tx_LP_D_N,
    output logic [NUM_DATA_LANE-1:0]         Tx_LP_D_N_OE,
	output logic [7:0]                       Tx_HS_D_0,
	output logic [7:0]                       Tx_HS_D_1,
	output logic [7:0]                       Tx_HS_D_2,
	output logic [7:0]                       Tx_HS_D_3,
	output logic [7:0]                       Tx_HS_D_4,
	output logic [7:0]                       Tx_HS_D_5,
	output logic [7:0]                       Tx_HS_D_6,
	output logic [7:0]                       Tx_HS_D_7,
	output logic [NUM_DATA_LANE-1:0]         Tx_HS_enable_D,

    //AXI4-Lite Interface
    input  logic          axi_clk, 
    input  logic          axi_reset_n,
    input  logic   [5:0]  axi_awaddr,//Write Address. byte address.
    input  logic          axi_awvalid,//Write address valid.
    output logic          axi_awready,//Write address ready.
    input  logic   [31:0] axi_wdata,//Write data bus.
    input  logic          axi_wvalid,//Write valid.
    output logic          axi_wready,//Write ready.
                          
    output logic          axi_bvalid,//Write response valid.
    input  logic          axi_bready,//Response ready.      
    input  logic   [5:0]  axi_araddr,//Read address. byte address.
    input  logic          axi_arvalid,//Read address valid.
    output logic          axi_arready,//Read address ready.
    output logic   [31:0] axi_rdata,//Read data.
    output logic          axi_rvalid,//Read valid.
    input                 axi_rready,//Read ready.
    
    input logic           hsync_vc0,
    input logic           hsync_vc1,
    input logic           hsync_vc2,
    input logic           hsync_vc3,
    input logic           vsync_vc0,
    input logic           vsync_vc1,
    input logic           vsync_vc2,
    input logic           vsync_vc3,
    
    input logic           hsync_vc4,
    input logic           hsync_vc5,
    input logic           hsync_vc6,
    input logic           hsync_vc7,
    input logic           hsync_vc8,
    input logic           hsync_vc9,
    input logic           hsync_vc10,
    input logic           hsync_vc11,
    input logic           hsync_vc12,
    input logic           hsync_vc13,
    input logic           hsync_vc14,
    input logic           hsync_vc15,
    input logic           vsync_vc4,
    input logic           vsync_vc5,
    input logic           vsync_vc6,
    input logic           vsync_vc7,
    input logic           vsync_vc8,
    input logic           vsync_vc9,
    input logic           vsync_vc10,
    input logic           vsync_vc11,
    input logic           vsync_vc12,
    input logic           vsync_vc13,
    input logic           vsync_vc14,
    input logic           vsync_vc15,
    
    input logic [5:0]     datatype,   // data type of the Long Packet
    input logic [63:0]    pixel_data,
    input logic           pixel_data_valid,
    //input logic [15:0]    word_count,
    input logic [15:0]    haddr,   //16 bit total Horizontal number of pixels
    input logic [15:0]    line_num,
    input logic [15:0]    frame_num,	
`ifdef MIPI_CSI2_TX_DEBUG
    input  logic [31:0]   mipi_debug_in,
    output logic [31:0]   mipi_debug_out,
`endif
    output logic          irq
    
);

logic TxStopStateC;
logic TxUlpsClk, TxUlpsExitClk, TxUlpsActiveClkNot, TxRequestHS_int, TxReadyHS_int, TxRequestHSc;
logic [NUM_DATA_LANE-1:0] TxSkewCalHS, TxRequestEsc, TxUlpsExit, TxUlpsEsc, TxStopStateD, TxUlpsActiveNot;
logic [NUM_DATA_LANE-1:0] TxRequestHS, TxReadyHS;
logic [7:0] TxDataHS0, TxDataHS1, TxDataHS2, TxDataHS3, TxDataHS4, TxDataHS5, TxDataHS6, TxDataHS7;

`IP_MODULE_NAME(efx_dphy_tx) #(
    .tLPX_NS              (tLPX_NS        ),
    .tLP_EXIT_NS          (tLP_EXIT_NS    ),
    .tCLK_ZERO_NS         (tCLK_ZERO_NS   ),
    .tCLK_TRAIL_NS        (tCLK_TRAIL_NS  ), 
    .tCLK_PRE_NS          (tCLK_PRE_NS    ),
    .tCLK_POST_NS         (tCLK_POST_NS   ),      
    .tCLK_PREPARE_NS      (tCLK_PREPARE_NS),    
    .tHS_PREPARE_NS       (tHS_PREPARE_NS ),   
    .tWAKEUP_NS           (tWAKEUP_NS     ),
    .tHS_EXIT_NS          (tHS_EXIT_NS    ),
    .tHS_ZERO_NS          (tHS_ZERO_NS    ),
    .tHS_TRAIL_NS         (tHS_TRAIL_NS   ),
    .HS_BYTECLK_MHZ       (HS_BYTECLK_MHZ),
    .CLOCK_FREQ_MHZ       (CLOCK_FREQ_MHZ),
    .NUM_DATA_LANE        (NUM_DATA_LANE),
    .DPHY_CLOCK_MODE      (DPHY_CLOCK_MODE)
) dphy_tx_inst (
    .reset_n              (reset_n),
    .clk                  (clk),				
    .reset_byte_HS_n      (reset_byte_HS_n),
    .clk_byte_HS          (clk_byte_HS),
    //To LVDS clock lane   
    .Tx_LP_CLK_P          (Tx_LP_CLK_P), 
    .Tx_LP_CLK_P_OE       (Tx_LP_CLK_P_OE), 
	.Tx_LP_CLK_N          (Tx_LP_CLK_N),
    .Tx_LP_CLK_N_OE       (Tx_LP_CLK_N_OE), 
    .Tx_HS_enable_C       (Tx_HS_enable_C), 
	
    //PPI clock lane
    .TxRequestHSc         (TxRequestHSc),
    .Tx_HS_C              (Tx_HS_C),
    .TxReadyHSc           (),
    .TxUlpsClk            (TxUlpsClk),   // Transmit Ultra Low power on clock lane
    .TxUlpsExitClk        (TxUlpsExitClk),
    .TxUlpsActiveClkNot   (TxUlpsActiveClkNot),
    .TxStopStateC         (TxStopStateC),
    
    //To LVDS data lane
    .Tx_LP_D_P            (Tx_LP_D_P),
    .Tx_LP_D_P_OE         (Tx_LP_D_P_OE),
    .Tx_LP_D_N            (Tx_LP_D_N),
    .Tx_LP_D_N_OE         (Tx_LP_D_N_OE),    
    .Tx_HS_D_0            (Tx_HS_D_0),
    .Tx_HS_D_1            (Tx_HS_D_1),
    .Tx_HS_D_2            (Tx_HS_D_2),
    .Tx_HS_D_3            (Tx_HS_D_3),
    .Tx_HS_D_4            (Tx_HS_D_4),
    .Tx_HS_D_5            (Tx_HS_D_5),
    .Tx_HS_D_6            (Tx_HS_D_6),
    .Tx_HS_D_7            (Tx_HS_D_7),
    .Tx_HS_enable_D       (Tx_HS_enable_D),
	//PPI data lane       
	.TxRequestHS          (TxRequestHS),
	.TxDataHS_0           (TxDataHS0),
	.TxDataHS_1           (TxDataHS1),
	.TxDataHS_2           (TxDataHS2),
	.TxDataHS_3           (TxDataHS3),
	.TxDataHS_4           (TxDataHS4),
	.TxDataHS_5           (TxDataHS5),
	.TxDataHS_6           (TxDataHS6),
	.TxDataHS_7           (TxDataHS7),
	.TxReadyHS            (TxReadyHS),
	.TxSkewCalHS          (TxSkewCalHS),
	.TxRequestEsc         (TxRequestEsc),
	.TxStopStateD         (TxStopStateD),
	.TxUlpsExit           (TxUlpsExit),
	.TxUlpsActiveNot      (TxUlpsActiveNot),
	.TxUlpsEsc            (TxUlpsEsc),
	//LPDT mode only supported in DSI
	.TxLpdtEsc            ({NUM_DATA_LANE{1'b0}}),
	.TxValidEsc           ({NUM_DATA_LANE{1'b0}}),
	.TxDataEsc_0          (8'h0),
	.TxDataEsc_1          (8'h0),
	.TxDataEsc_2          (8'h0),
	.TxDataEsc_3          (8'h0),
	.TxDataEsc_4          (8'h0),
	.TxDataEsc_5          (8'h0),
	.TxDataEsc_6          (8'h0),
	.TxDataEsc_7          (8'h0),
	.TxReadyEsc           ()
);

`IP_MODULE_NAME(efx_csi2_tx_top) #(
    .HS_DATA_WIDTH         (8),
    .tINIT_NS              (tINIT_NS),
    .tINIT_SKEWCAL_NS      (tINIT_SKEWCAL_NS),
    .HS_BYTECLK_MHZ        (HS_BYTECLK_MHZ),
    .DPHY_CLOCK_MODE       (DPHY_CLOCK_MODE),
    .NUM_DATA_LANE         (NUM_DATA_LANE), 
    .PACK_TYPE             (PACK_TYPE),
    .PIXEL_FIFO_DEPTH      (PIXEL_FIFO_DEPTH),
    .ENABLE_VCX            (ENABLE_VCX),
    .FRAME_MODE            (FRAME_MODE),
    .ENABLE_SKEWCAL_INIT   (0),   //do not enable skew cal for soft DPHY
    .ASYNC_STAGE           (ASYNC_STAGE)
) csi2_tx_top_inst (
    .clk_byte_HS             (clk_byte_HS),
    .reset_byte_HS_n         (reset_byte_HS_n),
    .reset_pixel_n           (reset_pixel_n),
    .clk_pixel               (clk_pixel),
    .reset_esc_n             (reset_n),
    .clk_esc                 (clk),
    .axi_clk                 (axi_clk),
    .axi_reset_n             (axi_reset_n),
    .axi_awaddr              (axi_awaddr),
    .axi_awvalid             (axi_awvalid),
    .axi_awready             (axi_awready),
    .axi_wdata               (axi_wdata),
    .axi_wvalid              (axi_wvalid),
    .axi_wready              (axi_wready),                        
    .axi_bvalid              (axi_bvalid),
    .axi_bready              (axi_bready),
    .axi_araddr              (axi_araddr),
    .axi_arvalid             (axi_arvalid),
    .axi_arready             (axi_arready),
    .axi_rdata               (axi_rdata),
    .axi_rvalid              (axi_rvalid),
    .axi_rready              (axi_rready),
    
    .TxUlpsClk               (TxUlpsClk),
    .TxUlpsExitClk           (TxUlpsExitClk),
    .TxUlpsEsc               (TxUlpsEsc   ),
    .TxUlpsExit              (TxUlpsExit  ),
    .TxRequestEsc            (TxRequestEsc),
    .TxUlpsActiveClkNot      (TxUlpsActiveClkNot),
    .TxSkewCalHS             (TxSkewCalHS),
    .TxStopStateD            (TxStopStateD),   
    .TxStopStateC            (TxStopStateC),
    .TxUlpsActiveNot         (TxUlpsActiveNot),
    .TxReadyHS               (TxReadyHS),
    .TxRequestHS             (TxRequestHS),
	.TxRequestHSc            (TxRequestHSc),	
    .TxDataHS0               (TxDataHS0),
    .TxDataHS1               (TxDataHS1),
    .TxDataHS2               (TxDataHS2),
    .TxDataHS3               (TxDataHS3),
    .TxDataHS4               (TxDataHS4),
    .TxDataHS5               (TxDataHS5),
    .TxDataHS6               (TxDataHS6),
    .TxDataHS7               (TxDataHS7),
    .TxReqValidHS0           (),
    .TxReqValidHS1           (),
    .TxReqValidHS2           (),
    .TxReqValidHS3           (),  
    .TxReqValidHS4           (),
    .TxReqValidHS5           (),
    .TxReqValidHS6           (),
    .TxReqValidHS7           (), 
    .hsync_vc0               (hsync_vc0),
    .hsync_vc1               (hsync_vc1),
    .hsync_vc2               (hsync_vc2),
    .hsync_vc3               (hsync_vc3),
    .vsync_vc0               (vsync_vc0),
    .vsync_vc1               (vsync_vc1),
    .vsync_vc2               (vsync_vc2),
    .vsync_vc3               (vsync_vc3), 
    
    .hsync_vc4               (hsync_vc4),
    .hsync_vc5               (hsync_vc5),
    .hsync_vc6               (hsync_vc6),
    .hsync_vc7               (hsync_vc7),
    .hsync_vc8               (hsync_vc8),
    .hsync_vc9               (hsync_vc9),
    .hsync_vc10              (hsync_vc10),
    .hsync_vc11              (hsync_vc11),
    .hsync_vc12              (hsync_vc12),
    .hsync_vc13              (hsync_vc13),
    .hsync_vc14              (hsync_vc14),
    .hsync_vc15              (hsync_vc15),
    .vsync_vc4               (vsync_vc4),
    .vsync_vc5               (vsync_vc5),
    .vsync_vc6               (vsync_vc6),
    .vsync_vc7               (vsync_vc7),
    .vsync_vc8               (vsync_vc8),
    .vsync_vc9               (vsync_vc9),
    .vsync_vc10              (vsync_vc10),
    .vsync_vc11              (vsync_vc11),
    .vsync_vc12              (vsync_vc12),
    .vsync_vc13              (vsync_vc13),
    .vsync_vc14              (vsync_vc14),
    .vsync_vc15              (vsync_vc15),
    .datatype                (datatype),  
    .pixel_data              (pixel_data), 
    .pixel_data_valid        (pixel_data_valid),
    .haddr                   (haddr),   //16 bit
    .line_num                (line_num),
    .frame_num               (frame_num),	
`ifdef MIPI_CSI2_TX_DEBUG
    .mipi_debug_in           (mipi_debug_in),
    .mipi_debug_out          (mipi_debug_out),
`endif 
    .irq                     (irq)
);

endmodule
