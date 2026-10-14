
// synopsys translate_off
`timescale 1 ns / 1 ps													
// synopsys translate_on

module `IP_MODULE_NAME(efx_csi2_rx) #(
    parameter tLPX_NS = 50,
    parameter tINIT_NS = 100000,
    parameter tCLK_TERM_EN_NS = 38,
    parameter tD_TERM_EN_NS = 35,
    parameter tHS_SETTLE_NS = 85,
    parameter tHS_PREPARE_ZERO_NS = 145,
    parameter NUM_DATA_LANE = 4,
    parameter HS_BYTECLK_MHZ = 187,
    parameter CLOCK_FREQ_MHZ = 100,
    parameter DPHY_CLOCK_MODE = "Continuous",  //"Continuous", "Discontinuous"
    parameter PIXEL_FIFO_DEPTH = 1024,
    parameter AREGISTER = 8,
    parameter ENABLE_USER_DESKEWCAL = 0,
    parameter ENABLE_VCX = 0,
    parameter FRAME_MODE = "GENERIC",    //1-ACCURATE, 0-GENERIC
    parameter ASYNC_STAGE = 2,
    parameter PACK_TYPE = 4'b1111
)(
    input logic           reset_n,
    input logic           clk,				//100Mhz
    input logic           reset_byte_HS_n,
    input logic           clk_byte_HS,
    input logic           reset_pixel_n,
    input logic           clk_pixel,
    // LVDS clock lane   
    input logic           Rx_LP_CLK_P, 
	input logic           Rx_LP_CLK_N,
    output logic          Rx_HS_enable_C, 
	output logic          LVDS_termen_C,
	
    // LVDS RX data lane
    input logic  [NUM_DATA_LANE-1:0]      Rx_LP_D_P, 
	input logic  [NUM_DATA_LANE-1:0]      Rx_LP_D_N,
    input logic  [7:0]                    Rx_HS_D_0,
    input logic  [7:0]                    Rx_HS_D_1,
    input logic  [7:0]                    Rx_HS_D_2,
    input logic  [7:0]                    Rx_HS_D_3,
    input logic  [7:0]                    Rx_HS_D_4,
    input logic  [7:0]                    Rx_HS_D_5,
    input logic  [7:0]                    Rx_HS_D_6,
    input logic  [7:0]                    Rx_HS_D_7,
    // control signal to LVDS IO
    output logic [NUM_DATA_LANE-1:0]      Rx_HS_enable_D, 
	output logic [NUM_DATA_LANE-1:0]      LVDS_termen_D,
	output logic [NUM_DATA_LANE-1:0]      fifo_rd_enable,                            
	input  logic [NUM_DATA_LANE-1:0]      fifo_rd_empty,
    output logic [NUM_DATA_LANE-1:0]      DLY_enable_D,
	output logic [NUM_DATA_LANE-1:0]      DLY_inc_D,
	input  logic [NUM_DATA_LANE-1:0]      u_dly_enable_D, //user control the IO delay
	input  logic [NUM_DATA_LANE-1:0]      u_dly_inc_D, //user control the IO delay

    //AXI4-Lite Interface
    input                 axi_clk,
    input                 axi_reset_n,
    input          [5:0]  axi_awaddr,//Write Address. byte address.
    input                 axi_awvalid,//Write address valid.
    output logic          axi_awready,//Write address ready.
    input          [31:0] axi_wdata,//Write data bus.
    input                 axi_wvalid,//Write valid.
    output logic          axi_wready,//Write ready.
                          
    output logic          axi_bvalid,//Write response valid.
    input                 axi_bready,//Response ready.      
    input          [5:0]  axi_araddr,//Read address. byte address.
    input                 axi_arvalid,//Read address valid.
    output logic          axi_arready,//Read address ready.
    output logic   [31:0] axi_rdata,//Read data.
    output logic          axi_rvalid,//Read valid.
    input                 axi_rready,//Read ready.
	
    output logic          hsync_vc0,
    output logic          hsync_vc1,
    output logic          hsync_vc2,
    output logic          hsync_vc3,
    output logic          vsync_vc0,
    output logic          vsync_vc1,
    output logic          vsync_vc2,
    output logic          vsync_vc3,
    
    output logic          hsync_vc4,
    output logic          hsync_vc5,
    output logic          hsync_vc6,
    output logic          hsync_vc7,
    output logic          hsync_vc8,
    output logic          hsync_vc9,
    output logic          hsync_vc10,
    output logic          hsync_vc11,
    output logic          hsync_vc12,
    output logic          hsync_vc13,
    output logic          hsync_vc14,
    output logic          hsync_vc15,
    output logic          vsync_vc4,
    output logic          vsync_vc5,
    output logic          vsync_vc6,
    output logic          vsync_vc7,
    output logic          vsync_vc8,
    output logic          vsync_vc9,
    output logic          vsync_vc10,
    output logic          vsync_vc11,
    output logic          vsync_vc12,
    output logic          vsync_vc13,
    output logic          vsync_vc14,
    output logic          vsync_vc15,
    
    output logic [1:0]    vc,
    output logic [1:0]    vcx,
    output logic [15:0]   word_count,
    output logic [15:0]   shortpkt_data_field,
    output logic [5:0]    datatype,
    output logic [3:0]    pixel_per_clk,
    output logic [63:0]   pixel_data,
    output logic          pixel_data_valid,
`ifdef MIPI_CSI2_RX_DEBUG
    input  logic [31:0]   mipi_debug_in,
    output logic [31:0]   mipi_debug_out,
`endif
`ifdef MIPI_CSI2_RX_PIXEL_SIDEBAND
    output logic [15:0]   pixel_line_num,
    output logic [15:0]   pixel_frame_num,
    output logic [5:0]    pixel_datatype,
    output logic [15:0]   pixel_wordcount,
    output logic [1:0]    pixel_vc,
    output logic [1:0]    pixel_vcx,
`endif
    output logic          irq
    
);

logic [7:0] RxDataHS_0, RxDataHS_1, RxDataHS_2, RxDataHS_3, RxDataHS_4, RxDataHS_5, RxDataHS_6, RxDataHS_7;
logic RxValidHS_0, RxValidHS_1, RxValidHS_2, RxValidHS_3, RxValidHS_4, RxValidHS_5, RxValidHS_6, RxValidHS_7;
// logic [NUM_DATA_LANE-1:0][7:0] RxDataHS;
logic [NUM_DATA_LANE-1:0] RxValidHS, RxSyncHS;
logic RxUlpsClkNot, RxUlpsActiveClkNot;
logic [NUM_DATA_LANE-1:0] RxErrEsc, RxErrControl, RxErrSotSyncHS;
logic [NUM_DATA_LANE-1:0] RxUlpsEsc, RxUlpsActiveNot, RxSkewCalHS, RxStopState; 

generate
if (NUM_DATA_LANE == 1) begin
// assign RxDataHS[0] = RxDataHS_0;
assign RxValidHS_0 = RxValidHS[0];
assign RxValidHS_1 = 1'b0;
assign RxValidHS_2 = 1'b0;
assign RxValidHS_3 = 1'b0;
assign RxValidHS_4 = 1'b0;
assign RxValidHS_5 = 1'b0;
assign RxValidHS_6 = 1'b0;
assign RxValidHS_7 = 1'b0;
end             
else if (NUM_DATA_LANE == 2) begin
// assign RxDataHS[0] = RxDataHS_0;
// assign RxDataHS[1] = RxDataHS_1;
assign RxValidHS_0 = RxValidHS[0];
assign RxValidHS_1 = RxValidHS[1];
assign RxValidHS_2 = 1'b0;
assign RxValidHS_3 = 1'b0;
assign RxValidHS_4 = 1'b0;
assign RxValidHS_5 = 1'b0;
assign RxValidHS_6 = 1'b0;
assign RxValidHS_7 = 1'b0;
end
else if (NUM_DATA_LANE == 4) begin
// assign RxDataHS[0] = RxDataHS_0;
// assign RxDataHS[1] = RxDataHS_1;
// assign RxDataHS[2] = RxDataHS_2;
// assign RxDataHS[3] = RxDataHS_3;
assign RxValidHS_0 = RxValidHS[0];
assign RxValidHS_1 = RxValidHS[1];
assign RxValidHS_2 = RxValidHS[2];
assign RxValidHS_3 = RxValidHS[3];
assign RxValidHS_4 = 1'b0;
assign RxValidHS_5 = 1'b0;
assign RxValidHS_6 = 1'b0;
assign RxValidHS_7 = 1'b0;
end
else if (NUM_DATA_LANE == 8) begin
// assign RxDataHS[0] = RxDataHS_0;
// assign RxDataHS[1] = RxDataHS_1;
// assign RxDataHS[2] = RxDataHS_2;
// assign RxDataHS[3] = RxDataHS_3;
// assign RxDataHS[4] = RxDataHS_4;
// assign RxDataHS[5] = RxDataHS_5;
// assign RxDataHS[6] = RxDataHS_6;
// assign RxDataHS[7] = RxDataHS_7;
assign RxValidHS_0 = RxValidHS[0];
assign RxValidHS_1 = RxValidHS[1];
assign RxValidHS_2 = RxValidHS[2];
assign RxValidHS_3 = RxValidHS[3];
assign RxValidHS_4 = RxValidHS[4];
assign RxValidHS_5 = RxValidHS[5];
assign RxValidHS_6 = RxValidHS[6];
assign RxValidHS_7 = RxValidHS[7];
end                              
endgenerate

`IP_MODULE_NAME(efx_dphy_rx) #(
    .tLPX_NS              (tLPX_NS),
    .tCLK_TERM_EN_NS      (tCLK_TERM_EN_NS),
    .tD_TERM_EN_NS        (tD_TERM_EN_NS),
    .tHS_SETTLE_NS        (tHS_SETTLE_NS),
    .tHS_PREPARE_ZERO_NS  (tHS_PREPARE_ZERO_NS),
    .HS_BYTECLK_MHZ       (HS_BYTECLK_MHZ),
    .CLOCK_FREQ_MHZ       (CLOCK_FREQ_MHZ),
    .NUM_DATA_LANE        (NUM_DATA_LANE),
    .ENABLE_USER_DESKEWCAL(ENABLE_USER_DESKEWCAL),
    .DPHY_CLOCK_MODE      (DPHY_CLOCK_MODE)
) dphy_rx_inst (
    .reset_n              (reset_n),
    .clk                  (clk),				
    .reset_byte_HS_n      (reset_byte_HS_n),
    .clk_byte_HS          (clk_byte_HS),
    //To LVDS clock lane   
    .Rx_LP_CLK_P          (Rx_LP_CLK_P), 
	.Rx_LP_CLK_N          (Rx_LP_CLK_N),
    .Rx_HS_enable_C       (Rx_HS_enable_C), 
	.LVDS_termen_C        (LVDS_termen_C), 
	
	//ULPS clock
	.RxUlpsClkNot         (RxUlpsClkNot),
	.RxUlpsActiveClkNot   (RxUlpsActiveClkNot),
	
	//To LVDS data lane 0
	.Rx_LP_D_P            (Rx_LP_D_P     ),
	.Rx_LP_D_N            (Rx_LP_D_N     ),
	.Rx_HS_D_0            (Rx_HS_D_0     ),
	.Rx_HS_D_1            (Rx_HS_D_1     ),
	.Rx_HS_D_2            (Rx_HS_D_2     ),
	.Rx_HS_D_3            (Rx_HS_D_3     ),
	.Rx_HS_D_4            (Rx_HS_D_4     ),
	.Rx_HS_D_5            (Rx_HS_D_5     ),
	.Rx_HS_D_6            (Rx_HS_D_6     ),
	.Rx_HS_D_7            (Rx_HS_D_7     ),
	.Rx_HS_enable_D       (Rx_HS_enable_D),
	.LVDS_termen_D        (LVDS_termen_D ),
	.fifo_rd_enable       (fifo_rd_enable),
	.fifo_rd_empty        (fifo_rd_empty ),
	.DLY_enable_D         (DLY_enable_D  ),
	.DLY_inc_D            (DLY_inc_D     ),
	.u_dly_enable_D       (u_dly_enable_D),
	.u_dly_inc_D          (u_dly_inc_D),	                   
	//To CSI2 lane 0      
    .RxUlpsEsc            (RxUlpsEsc),
    .RxUlpsActiveNot      (RxUlpsActiveNot),
    .RxErrEsc             (RxErrEsc),
    .RxErrControl         (RxErrControl),
    .RxErrSotSyncHS       (RxErrSotSyncHS),
    .RxDataHS_0           (RxDataHS_0), 
    .RxDataHS_1           (RxDataHS_1),
    .RxDataHS_2           (RxDataHS_2), 
    .RxDataHS_3           (RxDataHS_3),
    .RxDataHS_4           (RxDataHS_4), 
    .RxDataHS_5           (RxDataHS_5),
    .RxDataHS_6           (RxDataHS_6), 
    .RxDataHS_7           (RxDataHS_7),
    .RxValidHS            (RxValidHS), 
    .RxActiveHS           (),
    .RxSyncHS             (RxSyncHS),
    .RxSkewCalHS          (RxSkewCalHS),
    .RxStopState          (RxStopState),
    //LPDT mode only supported in DSI
    .RxLPDTEsc            (),
    .RxValidEsc           (),
    .RxDataEsc_0          (),
    .RxDataEsc_1          (),
    .RxDataEsc_2          (),
    .RxDataEsc_3          (),
    .RxDataEsc_4          (),
    .RxDataEsc_5          (),
    .RxDataEsc_6          (),
    .RxDataEsc_7          ()
);

`IP_MODULE_NAME(efx_csi2_rx_top) #(
    .HS_DATA_WIDTH         (8),
    .tINIT_NS              (tINIT_NS),
    .CLOCK_FREQ_MHZ        (CLOCK_FREQ_MHZ),
    .NUM_DATA_LANE         (NUM_DATA_LANE),
    .PACK_TYPE             (PACK_TYPE),
    .AREGISTER             (AREGISTER),
    .ENABLE_VCX            (ENABLE_VCX),
    .FRAME_MODE            (FRAME_MODE),
    .ASYNC_STAGE            (ASYNC_STAGE),
    .PIXEL_FIFO_DEPTH      (PIXEL_FIFO_DEPTH)
) csi2_rx_top_inst (
    .reset_n              (reset_n),
    .clk                  (clk),				
    .reset_byte_HS_n      (reset_byte_HS_n),
    .clk_byte_HS          (clk_byte_HS),
    .reset_pixel_n        (reset_pixel_n),
    .clk_pixel            (clk_pixel),
    .axi_clk              (axi_clk),
    .axi_reset_n          (axi_reset_n),
    .axi_awaddr           (axi_awaddr),
    .axi_awvalid          (axi_awvalid),
    .axi_awready          (axi_awready),
    .axi_wdata            (axi_wdata),
    .axi_wvalid           (axi_wvalid),
    .axi_wready           (axi_wready),                        
    .axi_bvalid           (axi_bvalid),
    .axi_bready           (axi_bready),
    .axi_araddr           (axi_araddr),
    .axi_arvalid          (axi_arvalid),
    .axi_arready          (axi_arready),
    .axi_rdata            (axi_rdata),
    .axi_rvalid           (axi_rvalid),
    .axi_rready           (axi_rready),
    
	.RxUlpsClkNot         (RxUlpsClkNot),
	.RxUlpsActiveClkNot   (RxUlpsActiveClkNot),
    .RxErrEsc             (RxErrEsc),
    .RxClkEsc             ({NUM_DATA_LANE{1'b0}}),
    .RxErrControl         (RxErrControl),
    .RxErrSotSyncHS       (RxErrSotSyncHS),
    .RxUlpsEsc            (RxUlpsEsc),
    .RxUlpsActiveNot      (RxUlpsActiveNot),
    .RxSkewCalHS          (RxSkewCalHS),
    .RxStopState          (RxStopState),
    .RxSyncHS             (RxSyncHS),
    .RxDataHS0            (RxDataHS_0),
    .RxDataHS1            (RxDataHS_1),  
    .RxDataHS2            (RxDataHS_2),
    .RxDataHS3            (RxDataHS_3),
    .RxDataHS4            (RxDataHS_4),
    .RxDataHS5            (RxDataHS_5),
    .RxDataHS6            (RxDataHS_6),
    .RxDataHS7            (RxDataHS_7),
    .RxValidHS0           (RxValidHS_0),
    .RxValidHS1           (RxValidHS_1),
    .RxValidHS2           (RxValidHS_2),
    .RxValidHS3           (RxValidHS_3),
    .RxValidHS4           (RxValidHS_4),
    .RxValidHS5           (RxValidHS_5),
    .RxValidHS6           (RxValidHS_6),
    .RxValidHS7           (RxValidHS_7),
    
    .hsync_vc0            (hsync_vc0),
    .hsync_vc1            (hsync_vc1),
    .hsync_vc2            (hsync_vc2),
    .hsync_vc3            (hsync_vc3),
    .vsync_vc0            (vsync_vc0),
    .vsync_vc1            (vsync_vc1),
    .vsync_vc2            (vsync_vc2),
    .vsync_vc3            (vsync_vc3), 
                          
    .hsync_vc4            (hsync_vc4),
    .hsync_vc5            (hsync_vc5),
    .hsync_vc6            (hsync_vc6),
    .hsync_vc7            (hsync_vc7),
    .hsync_vc8            (hsync_vc8),
    .hsync_vc9            (hsync_vc9),
    .hsync_vc10           (hsync_vc10),
    .hsync_vc11           (hsync_vc11),
    .hsync_vc12           (hsync_vc12),
    .hsync_vc13           (hsync_vc13),
    .hsync_vc14           (hsync_vc14),
    .hsync_vc15           (hsync_vc15),
    .vsync_vc4            (vsync_vc4),
    .vsync_vc5            (vsync_vc5),
    .vsync_vc6            (vsync_vc6),
    .vsync_vc7            (vsync_vc7),
    .vsync_vc8            (vsync_vc8),
    .vsync_vc9            (vsync_vc9),
    .vsync_vc10           (vsync_vc10),
    .vsync_vc11           (vsync_vc11),
    .vsync_vc12           (vsync_vc12),
    .vsync_vc13           (vsync_vc13),
    .vsync_vc14           (vsync_vc14),
    .vsync_vc15           (vsync_vc15),
    .vc                   (vc),
    .vcx                  (vcx),
    .word_count           (word_count),
    .shortpkt_data_field  (shortpkt_data_field),
    .datatype             (datatype),  
    .pixel_per_clk        (pixel_per_clk),
    .pixel_data           (pixel_data), 
    .pixel_data_valid     (pixel_data_valid),
`ifdef MIPI_CSI2_RX_DEBUG
    .mipi_debug_in        (mipi_debug_in    ),
    .mipi_debug_out       (mipi_debug_out   ),
`endif 
`ifdef MIPI_CSI2_RX_PIXEL_SIDEBAND
    .pixel_line_num       (pixel_line_num   ),
    .pixel_frame_num      (pixel_frame_num  ),
    .pixel_datatype       (pixel_datatype   ),
    .pixel_wordcount      (pixel_wordcount  ),
    .pixel_vc             (pixel_vc         ),
    .pixel_vcx            (pixel_vcx        ),
`endif 
    .irq                  (irq)
);


endmodule
