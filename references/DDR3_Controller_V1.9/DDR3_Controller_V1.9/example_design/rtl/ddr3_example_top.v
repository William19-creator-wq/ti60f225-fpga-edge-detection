//***************************************************************/
//
// Moudel Name    : ddr3_example_top.v
// Version        : 1.1
// Date Created   : 2023-02-23 10:37:59
// Last Modified  : 2023-02-24 15:27:41
// Abstract       : ---
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`include "ddr3_controller/ddr3_parameter.vh"
`include "define.v"
module ddr3_example_top #
(
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

   // Clock and reset ports
   input                              axi_clk,      
   input                              core_clk,     // CORE CLK @ 100MHz
   input                              sdram_clk,    // SDRAM CK @ 400MHz
   input                              rx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk_90edge,   // SDRAM CK @ 400MHz
   input                              pll_locked,
   input                              user_pll_locked,
    // debug core ports
`ifdef  Efinity_Debug  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& 
  input                               jtag_inst1_CAPTURE ,
  input                               jtag_inst1_DRCK    ,
  input                               jtag_inst1_RESET   ,
  input                               jtag_inst1_RUNTEST ,
  input                               jtag_inst1_SEL     ,
  input                               jtag_inst1_SHIFT   ,
  input                               jtag_inst1_TCK     ,
  input                               jtag_inst1_TDI     ,
  input                               jtag_inst1_TMS     ,
  input                               jtag_inst1_UPDATE  ,
  output                              jtag_inst1_TDO     ,
`endif  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
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
   output [ODT_WIDTH-1:0]             ddr_odt

   );


      
//Parameter Define
parameter FREQ = 200;			// default is 100 MHz.  Redefine as needed.
`ifndef SIM
    localparam CNT_INIT = 1.5*FREQ*1000;
`else
    localparam CNT_INIT = 10;
`endif    
  /////////////////////////////////////////////////////////
  // Wire declarations
  reg  [19:0]                       cnt;    
  wire                              clk;
  wire                              rst;
  wire                              mmcm_locked;
  reg                               aresetn;
  wire                              app_sr_active;
  wire                              app_ref_ack;
  wire                              app_zq_ack;

  wire                              cal_done;

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

  wire                              mode_en;
  wire [1:0]                        addr_mode;
  wire [1:0]                        axi_mode;
  wire [AXI_ADDR_WIDTH-1:0]         saddr;
  wire [AXI_ADDR_WIDTH-1:0]         faddr;
  wire [1:0]                        data_mode;
  wire [AXI_DATA_WIDTH-1:0]         fdata;
  wire [2:0]                        len_mode;
  wire [7:0]                        flen;
  wire                              error;
  wire [15:0]                       err_cnt;
  wire [AXI_ADDR_WIDTH-1:0]         err_addr;
  wire [7:0]                        err_position;
  wire [AXI_DATA_WIDTH-1:0]         ref_data;
  wire [AXI_DATA_WIDTH-1:0]         err_data; 
  wire                              StatiClr  ;
  wire [23:0]                       TestTime  ;
  wire [47:0]                       OpTotCyc  ;
  wire [47:0]                       OpActCyc  ;
  wire [ 9:0]                       OpEffic   ;
  wire [ 9:0]                       RdOpEffic ;
  wire [ 9:0]                       WrOpEffic ;
  wire [15:0]                       BandWidth ;
  wire [9:0]                        WrPeriMin ;
  wire [9:0]                        WrPeriAvg ;
  wire [9:0]                        WrPeriMax ;
  wire [9:0]                        RdPeriMin ;
  wire [9:0]                        RdPeriAvg ;
  wire [9:0]                        RdPeriMax ;
  wire                              TimeOut   ;  
//***************************************************************************
  wire [2:0]                        vio_pll_shift;  
  wire [4:0]                        vio_pll_shift_sel;
  wire                              vio_pll_shift_ena; 
  wire                              pos_pll_shift_ena; 
  wire [2:0]                        phy_pll_shift;  
  wire [4:0]                        phy_pll_shift_sel;
  wire                              phy_pll_shift_ena; 
  wire                              ddr_reset; 
  wire                              sys_rst;
  wire  [2:0]                       phy_wr_pll_shift;
  wire                              idelay_ld       ;
  wire                              mpr_rdlvl_dly   ;
  wire  [7:0]                       wrlvl_dq_check  ;
  wire  [7:0]                       rd_level_dqs_check;  
  wire  [2:0]                       rdlvl_shift;  
  wire  [2:0]                       wrlvl_shift;  
  wire  [15:0]                      debug_fifo;  
  wire  [15:0]                      overflow_fifo;  
  wire  [6:0]                       init_cur_state;  
  wire  [35:0]                      ddr_debug_port;  
  wire                              app_rdy;  
  wire                              user_clk;  
  wire                              ddr_rstn;  
// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************

ddr3_top                 u_ddr3_top
      (
      
    .axi_clk                (axi_clk             ),
    .core_clk               (core_clk            ),
    .sdram_clk              (sdram_clk           ),  
    .rx_cal_clk             (rx_cal_clk          ),
    .tx_cal_clk             (tx_cal_clk          ),
    .tx_cal_clk_90edge      (tx_cal_clk_90edge   ),
    .rstn                   (ddr_rstn            ),      
    .pll_shift              (pll_shift           ),
    .pll_shift_sel          (pll_shift_sel       ),
    .pll_shift_ena          (pll_shift_ena       ),       
///////////////DDR BUS
    .ddr_ck_hi              (ddr_ck_hi           ),
    .ddr_ck_lo              (ddr_ck_lo           ),
    .ddr_cke                (ddr_cke             ),    
    .ddr_reset_n            (ddr_reset_n         ),
    .ddr_cs_n               (ddr_cs_n            ),
    .ddr_ras_n              (ddr_ras_n           ),
    .ddr_cas_n              (ddr_cas_n           ),
    .ddr_we_n               (ddr_we_n            ),     
    .ddr_addr               (ddr_addr            ),
    .ddr_ba                 (ddr_ba              ),

    .ddr_dqs_oe             (ddr_dqs_oe          ),
    .ddr_dqs_oe_n           (ddr_dqs_oe_n        ),
    .ddr_dq_oe              (ddr_dq_oe           ),
    .ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
    .ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
    .ddr_dq_in_hi           (ddr_dq_in_hi        ),
    .ddr_dq_in_lo           (ddr_dq_in_lo        ),

    .ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
    .ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
    .ddr_dq_out_hi          (ddr_dq_out_hi       ),
    .ddr_dq_out_lo          (ddr_dq_out_lo       ),
    
    .ddr_dm_hi              (ddr_dm_hi           ),
    .ddr_dm_lo              (ddr_dm_lo           ),
    .ddr_odt                (ddr_odt             ),

// Application interface ports
       .app_sr_req                     (1'b0),
       .app_ref_req                    (1'b0),
       .app_zq_req                     (1'b0),
       .app_sr_active                  (app_sr_active),
       .app_ref_ack                    (app_ref_ack),
       .app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
       .s_axi_awid                     (s_axi_awid        ),
       .s_axi_awaddr                   (s_axi_awaddr      ),
       .s_axi_awlen                    (s_axi_awlen       ),
       .s_axi_awsize                   (s_axi_awsize      ),
       .s_axi_awburst                  (s_axi_awburst     ),
       .s_axi_awlock                   (s_axi_awlock      ),
       .s_axi_awcache                  (s_axi_awcache     ),
       .s_axi_awprot                   (s_axi_awprot      ),
       .s_axi_awqos                    (4'h0              ),
       .s_axi_awvalid                  (s_axi_awvalid     ),
       .s_axi_awready                  (s_axi_awready     ),
// Slave Interface Write Data Ports
       .s_axi_wdata                    (s_axi_wdata       ),
       .s_axi_wstrb                    (s_axi_wstrb       ),
       .s_axi_wlast                    (s_axi_wlast       ),
       .s_axi_wvalid                   (s_axi_wvalid      ),
       .s_axi_wready                   (s_axi_wready      ),
// Slave Interface Write Response Ports
       .s_axi_bid                      (s_axi_bid         ),
       .s_axi_bresp                    (s_axi_bresp       ),
       .s_axi_bvalid                   (s_axi_bvalid      ),
       .s_axi_bready                   (s_axi_bready      ),
// Slave Interface Read Address Ports
       .s_axi_arid                     (s_axi_arid        ),
       .s_axi_araddr                   (s_axi_araddr      ),
       .s_axi_arlen                    (s_axi_arlen       ),
       .s_axi_arsize                   (s_axi_arsize      ),
       .s_axi_arburst                  (s_axi_arburst     ),
       .s_axi_arlock                   (s_axi_arlock      ),
       .s_axi_arcache                  (s_axi_arcache     ),
       .s_axi_arprot                   (s_axi_arprot      ),
       .s_axi_arqos                    (4'h0              ),
       .s_axi_arvalid                  (s_axi_arvalid     ),
       .s_axi_arready                  (s_axi_arready     ),
// Slave Interface Read Data Ports
       .s_axi_rid                      (s_axi_rid         ),
       .s_axi_rdata                    (s_axi_rdata       ),
       .s_axi_rresp                    (s_axi_rresp       ),
       .s_axi_rlast                    (s_axi_rlast       ),
       .s_axi_rvalid                   (s_axi_rvalid      ),
       .s_axi_rready                   (s_axi_rready      ),
//DEBUG       
       .wrlvl_dq_check                 (wrlvl_dq_check    ) ,
       .rd_level_dqs_check             (rd_level_dqs_check) ,
       .rdlvl_shift                    (rdlvl_shift       ) ,
       .wrlvl_shift                    (wrlvl_shift       ) ,
       .init_cur_state                 (init_cur_state    ) ,
       .idelay_ld                      (idelay_ld         ) ,
       .mpr_rdlvl_dly                  (mpr_rdlvl_dly     ) ,
       .ddr_debug_port                 (ddr_debug_port    ) ,
       .cal_done                       (cal_done          ) 
       );
// End of User Design top instance

//***************************************************************************
// The traffic generation module instantiated below drives traffic (patterns)
// on the application interface of the memory controller
//***************************************************************************
//***************************************************************************

`ifdef Efinity_Debug
edb_top edb_top_inst (
    .bscan_CAPTURE               ( jtag_inst1_CAPTURE      ),
    .bscan_DRCK                  ( jtag_inst1_DRCK         ),
    .bscan_RESET                 ( jtag_inst1_RESET        ),
    .bscan_RUNTEST               ( jtag_inst1_RUNTEST      ),
    .bscan_SEL                   ( jtag_inst1_SEL          ),
    .bscan_SHIFT                 ( jtag_inst1_SHIFT        ),
    .bscan_TCK                   ( jtag_inst1_TCK          ),
    .bscan_TDI                   ( jtag_inst1_TDI          ),
    .bscan_TMS                   ( jtag_inst1_TMS          ),
    .bscan_UPDATE                ( jtag_inst1_UPDATE       ),
    .bscan_TDO                   ( jtag_inst1_TDO          ),
    .mem_clk                     ( user_clk                ),
    .mem_StatiClr                ( StatiClr                ),
    .mem_TestTime                ( TestTime                ),
    .mem_OpTotCyc                ( OpTotCyc                ),
    .mem_OpActCyc                ( OpActCyc                ),
    .mem_OpEffic                 ( OpEffic                 ),
    .mem_RdOpEffic               ( RdOpEffic               ),
    .mem_WrOpEffic               ( WrOpEffic               ),
    .mem_BandWidth               ( BandWidth               ),
    .mem_WrPeriMin               ( WrPeriMin               ),
    .mem_WrPeriAvg               ( WrPeriAvg               ),
    .mem_WrPeriMax               ( WrPeriMax               ),
    .mem_RdPeriMin               ( RdPeriMin               ),
    .mem_RdPeriAvg               ( RdPeriAvg               ),
    .mem_RdPeriMax               ( RdPeriMax               ),
    .mem_TimeOut                 ( TimeOut                 ),
    .mem_error                   ( error                   ),
    .mem_err_cnt                 ( err_cnt                 ),
    .mem_err_addr                ( err_addr                ),
    .mem_err_position            ( err_position            ),
    .mem_ref_data                ( ref_data                ),
    .mem_err_data                ( err_data                ),
    .mem_cal_done                ( cal_done                ),
    .mem_ddr_reset               ( ddr_reset               ),
    .mem_mode_en                 ( mode_en                 ),
    .mem_addr_mode               ( addr_mode               ),
    .mem_axi_mode                ( axi_mode                ),
    .mem_data_mode               ( data_mode               ),
    .mem_len_mode                ( len_mode                ),
    .mem_saddr                   ( saddr                   ),
    .mem_faddr                   ( faddr                   ),
    .mem_fdata                   ( fdata                   ),
    .mem_flen                    ( flen                    ),
    .phy_debug_clk                    ( sdram_clk          ),
    .phy_debug_idelay_ld              ( idelay_ld          ),
    .phy_debug_mpr_rdlvl_dly          ( mpr_rdlvl_dly      ),
    .phy_debug_wrlvl_dq_check         ( wrlvl_dq_check     ),
    .phy_debug_rd_level_dqs_check     ( rd_level_dqs_check ),
    .phy_debug_init_cur_state         ( init_cur_state     ),
    .phy_debug_rdlvl_shift            ( rdlvl_shift        ),
    .phy_debug_wrlvl_shift            ( wrlvl_shift        ),
    .phy_debug_pll_shift_ena          (pll_shift_ena       ),
    .phy_debug_pll_shift_sel          (pll_shift_sel       ),
    .phy_debug_pll_shift              (pll_shift           ),    
    .phy_debug_ddr_cs_n               (ddr_cs_n            ),
    .phy_debug_ddr_ras_n              (ddr_ras_n           ),
    .phy_debug_ddr_cas_n              (ddr_cas_n           ),
    .phy_debug_ddr_we_n               (ddr_we_n            ),     
    .phy_debug_ddr_addr               (ddr_addr            ),
    .phy_debug_ddr_ba                 (ddr_ba              ),

    .phy_debug_ddr_dqs_oe             (ddr_dqs_oe          ),
    .phy_debug_ddr_dq_oe              (ddr_dq_oe           ),
    .phy_debug_ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
    .phy_debug_ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
    .phy_debug_ddr_dq_in_hi           (ddr_dq_in_hi        ),
    .phy_debug_ddr_dq_in_lo           (ddr_dq_in_lo        ),
    .phy_debug_error                  (error               ),

    .phy_debug_ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
    .phy_debug_ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
    .phy_debug_ddr_dq_out_hi          (ddr_dq_out_hi       ),
    .phy_debug_ddr_dq_out_lo          (ddr_dq_out_lo       ),
     .la0_clk               ( user_clk ),
    .la0_s_axi_awvalid      ( s_axi_awvalid ),
    .la0_s_axi_awready      ( s_axi_awready ),
    .la0_s_axi_awaddr       ( s_axi_awaddr ),
    .la0_s_axi_awlen        ( s_axi_awlen ),
    .la0_s_axi_awsize       ( s_axi_awsize ),
    .la0_s_axi_wready       ( s_axi_wready ),
    .la0_s_axi_wvalid       ( s_axi_wvalid ),
    .la0_s_axi_wdata        ( s_axi_wdata ),
    .la0_s_axi_wlast        ( s_axi_wlast ),
    .la0_s_axi_bvalid       ( s_axi_bvalid ),
    .la0_s_axi_bready       ( s_axi_bready ),
    .la0_s_axi_bresp        ( s_axi_bresp ),
    .la0_s_axi_arvalid      ( s_axi_arvalid ),
    .la0_s_axi_arready      ( s_axi_arready ),
    .la0_s_axi_araddr       ( s_axi_araddr ),
    .la0_s_axi_arlen        ( s_axi_arlen ),
    .la0_s_axi_rready       ( s_axi_rready ),
    .la0_s_axi_rvalid       ( s_axi_rvalid ),
    .la0_s_axi_rdata        ( s_axi_rdata ),
    .la0_s_axi_rresp        ( s_axi_rresp ),
    .la0_s_axi_rlast        ( s_axi_rlast ),
    .la0_ddr_debug_port     ( ddr_debug_port ),
    .la0_error              ( error )
);

assign sys_rst       = ddr_reset & pll_locked & user_pll_locked;

`else
reg mode_en_start;
reg [9:0]cal_done_cnt;
always @ (posedge user_clk or negedge sys_rst)
begin   
    if(sys_rst == 1'b0)
        cal_done_cnt <= 'b0;
    else if(cal_done == 1'b1 )   
        cal_done_cnt <= cal_done_cnt +1;
end

always @ (posedge user_clk or negedge sys_rst)
begin   
    if(sys_rst == 1'b0)
        mode_en_start <= 1'b0;
    else if(&cal_done_cnt == 1 )   
        mode_en_start <= 1'b1;
end

assign mode_en = mode_en_start;
assign saddr = 28'b0;
assign faddr = 28'b0; 
assign fdata = 128'hffff_0000_5555_aaaa_aaaa_5555_9999_6666; 
assign flen  = 8'd63; 

assign addr_mode  = 2'b00; //
assign axi_mode   = 2'b00; 
assign data_mode  = 2'b00; 
assign len_mode   = 3'b010; 
assign sys_rst       = pll_locked;
`endif

always @(posedge user_clk or negedge sys_rst) begin
	if (!sys_rst)
		cnt <= 0;
    else if (cnt != CNT_INIT) 
        cnt <= cnt + 20'd1;
	else 
        cnt <= cnt;
end
assign ddr_rstn = (cnt == CNT_INIT);


generate
if (ASYN_AXI_CLK) begin
assign user_clk = axi_clk;

end else begin
assign user_clk = core_clk;
end
endgenerate

memory_test    #(
.AXI_DW                       (AXI_DATA_WIDTH         ),
.AXI_AW                       (AXI_ADDR_WIDTH         ),
.MEM_AW                       (28                     ),
.DDR_CLK_PERIOD               (32'd800_000_000        ),
.AXI_CLK_PERIOD               (32'd200_000_000        ),
.DDR_DATA_WIDTH               (16                     )
)              
u_memory_test(
.rstn                         (ddr_rstn               ),
.clk                          (user_clk               ),
.mode_en                      (mode_en                ),
.addr_mode                    (addr_mode              ),
.axi_mode                     (axi_mode               ),
.saddr                        (saddr                  ),
.faddr                        (faddr                  ),
.data_mode                    (data_mode              ),
.fdata                        (fdata                  ),
.len_mode                     (len_mode               ),
.flen                         (flen                   ),
//AXI4 

.m_axi_awid                   (s_axi_awid             ),
.m_axi_awaddr                 (s_axi_awaddr           ),
.m_axi_awlen                  (s_axi_awlen            ),
.m_axi_awsize                 (s_axi_awsize           ),
.m_axi_awburst                (s_axi_awburst          ),
.m_axi_awlock                 (s_axi_awlock           ),
.m_axi_awcache                (s_axi_awcache          ),
.m_axi_awprot                 (s_axi_awprot           ),
//.m_axi_awqos                  (),
.m_axi_awvalid                (s_axi_awvalid          ),
.m_axi_awready                (s_axi_awready          ),
.m_axi_wdata                  (s_axi_wdata            ),
.m_axi_wstrb                  (s_axi_wstrb            ),
.m_axi_wlast                  (s_axi_wlast            ),
.m_axi_wvalid                 (s_axi_wvalid           ),
.m_axi_wready                 (s_axi_wready           ),
.m_axi_bready                 (s_axi_bready           ),
.m_axi_bid                    (s_axi_bid              ),
.m_axi_bresp                  (s_axi_bresp            ),
.m_axi_bvalid                 (s_axi_bvalid           ),
.m_axi_arid                   (s_axi_arid             ),
.m_axi_araddr                 (s_axi_araddr           ),
.m_axi_arlen                  (s_axi_arlen            ),
.m_axi_arsize                 (s_axi_arsize           ),
.m_axi_arburst                (s_axi_arburst          ),
.m_axi_arlock                 (s_axi_arlock           ),
.m_axi_arcache                (s_axi_arcache          ),
.m_axi_arprot                 (s_axi_arprot           ),
//.m_axi_arqos                  (),
.m_axi_arvalid                (s_axi_arvalid          ),
.m_axi_arready                (s_axi_arready          ),
.m_axi_rready                 (s_axi_rready           ),
.m_axi_rid                    (s_axi_rid              ),
.m_axi_rdata                  (s_axi_rdata            ),
.m_axi_rresp                  (s_axi_rresp            ),
.m_axi_rlast                  (s_axi_rlast            ),
.m_axi_rvalid                 (s_axi_rvalid           ),
//ddrtest efficiency statistic
.StatiClr                     (StatiClr               ),
.TestTime                     (TestTime               ),
.OpTotCyc                     (OpTotCyc               ),
.OpActCyc                     (OpActCyc               ),
.OpEffic                      (OpEffic                ),
.RdOpEffic                    (RdOpEffic              ),
.WrOpEffic                    (WrOpEffic              ),
.BandWidth                    (BandWidth              ),
.WrPeriMin                    (WrPeriMin              ),
.WrPeriAvg                    (WrPeriAvg              ),
.WrPeriMax                    (WrPeriMax              ),
.RdPeriMin                    (RdPeriMin              ),
.RdPeriAvg                    (RdPeriAvg              ),
.RdPeriMax                    (RdPeriMax              ),
.TimeOut                      (TimeOut                ),
// error informaton interface
.error                        (error                  ),
.err_cnt                      (err_cnt                ),
.err_addr                     (err_addr               ),
.err_position                 (err_position           ),
.ref_data                     (ref_data               ),
.err_data                     (err_data               )
);

function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2
endmodule
