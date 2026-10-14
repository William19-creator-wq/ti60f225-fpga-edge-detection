/****************************************************************************************
*
*    File Name:  tb.v
*
* Dependencies:  ddr3.v, ddr3_parameters.vh
*
*  Description:  Micron SDRAM DDR3 (Double Data Rate 3) test bench
*
*         Note: -Set simulator resolution to "ps" accuracy
*               -Set Debug = 0 to disable $display messages
*
*   Disclaimer   This software code and all associated documentation, comments or other 
*  of Warranty:  information (collectively "Software") is provided "AS IS" without 
*                warranty of any kind. MICRON TECHNOLOGY, INC. ("MTI") EXPRESSLY 
*                DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
*                TO, NONINFRINGEMENT OF THIRD PARTY RIGHTS, AND ANY IMPLIED WARRANTIES 
*                OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT 
*                WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
*                OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
*                FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING THE USE OR 
*                THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF ITS CORRECTNESS, 
*                ACCURACY, RELIABILITY, OR OTHERWISE. THE ENTIRE RISK ARISING OUT OF USE 
*                OR PERFORMANCE OF THE SOFTWARE REMAINS WITH YOU. IN NO EVENT SHALL MTI, 
*                ITS AFFILIATED COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT, 
*                INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, 
*                WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS INTERRUPTION, 
*                OR LOSS OF INFORMATION) ARISING OUT OF YOUR USE OF OR INABILITY TO USE 
*                THE SOFTWARE, EVEN IF MTI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
*                DAMAGES. Because some jurisdictions prohibit the exclusion or 
*                limitation of liability for consequential or incidental damages, the 
*                above limitation may not apply to you.
*
*                Copyright 2003 Micron Technology, Inc. All rights reserved.
*
****************************************************************************************/

`timescale 1ps / 1ps

module tb_top;


    `include "1024Mb_ddr3_parameters.vh"

    // ports
    reg                         rst_n;
    reg                         ck;
    wire                        ck_n = ~ck;
    reg                         cke;
    reg                         cs_n;
    reg                         ras_n;
    reg                         cas_n;
    reg                         we_n;
    reg           [BA_BITS-1:0] ba;
    reg         [ADDR_BITS-1:0] a;
    wire          [DM_BITS-1:0] dm;
    wire          [DQ_BITS-1:0] dq;
    wire          [DQ_BITS-1:0] dq0;
    wire          [DQ_BITS-1:0] dq1;
    wire         [DQS_BITS-1:0] dqs;
    wire         [DQS_BITS-1:0] dqs_n;
    wire         [DQS_BITS-1:0] tdqs_n;
    wire                        odt;
    
    // mode registers
    reg         [ADDR_BITS-1:0] mode_reg0;                                 //Mode Register
    reg         [ADDR_BITS-1:0] mode_reg1;                                 //Extended Mode Register
    reg         [ADDR_BITS-1:0] mode_reg2;                                 //Extended Mode Register 2
    wire                  [3:0] cl       = {mode_reg0[2], mode_reg0[6:4]} + 4;              //CAS Latency
    wire                        bo       = mode_reg0[3];                    //Burst Order
    reg                   [3:0] bl;                                         //Burst Length
    wire                  [3:0] cwl      = mode_reg2[5:3] + 5;              //CAS Write Latency
    wire                  [3:0] al       = (mode_reg1[4:3] === 2'b00) ? 4'h0 : cl - mode_reg1[4:3]; //Additive Latency
    wire                  [4:0] rl       = cl + al;                         //Read Latency
    wire                  [4:0] wl       = cwl + al;                        //Write Latency

    // dq transmit
    reg                         dq_en;
    reg           [DM_BITS-1:0] dm_out;
    reg           [DQ_BITS-1:0] dq_out;
    reg                         dqs_en;
    reg          [DQS_BITS-1:0] dqs_out;
    assign                      dm       = dq_en ? dm_out : {DM_BITS{1'bz}};
    assign                      dq0      = dq_en ? dq_out : {DQ_BITS{1'bz}};
    assign                      dq1      = dq_en ? ~dq_out : {DQ_BITS{1'bz}};
    assign                      dqs      = dqs_en ? dqs_out : {DQS_BITS{1'bz}};
    assign                      dqs_n    = dqs_en ? ~dqs_out : {DQS_BITS{1'bz}};

    // dq receive
    reg           [DM_BITS-1:0] dm_fifo [4*CL_MAX+BL_MAX+2:0];
    reg           [DQ_BITS-1:0] dq_fifo [4*CL_MAX+BL_MAX+2:0];
    wire          [DQ_BITS-1:0] q0, q1, q2, q3;
    reg                         ptr_rst_n;
    reg                   [1:0] burst_cntr;

    // odt
    reg                         odt_out;
    reg     [(AL_MAX+CL_MAX):0] odt_fifo;
    assign                      odt      = odt_out & !odt_fifo[0];

    // timing definition in tCK units
    real                        tck;
    wire                 [11:0] tccd     = TCCD;
    wire                 [11:0] tcke     = max(ceil(TCKE/tck), TCKE_TCK);
    wire                 [11:0] tckesr   = TCKESR_TCK;
    wire                 [11:0] tcksre   = max(ceil(TCKSRE/tck), TCKSRE_TCK);
    wire                 [11:0] tcksrx   = max(ceil(TCKSRX/tck), TCKSRX_TCK);
    wire                 [11:0] tcl_min  = min_cl(tck);
    wire                  [6:2] mr_cl    = (tcl_min - 4)<<2 | (tcl_min/12);
    wire                 [11:0] tcpded   = TCPDED;
    wire                 [11:0] tcwl_min = min_cwl(tck);
    wire                  [5:3] mr_cwl   = tcwl_min - 5;
    wire                 [11:0] tdllk    = TDLLK;
    wire                 [11:0] tfaw     = ceil(TFAW/tck);
    wire                 [11:0] tmod     = max(ceil(TMOD/tck), TMOD_TCK);
    wire                 [11:0] tmrd     = TMRD;
    wire                 [11:0] tras     = ceil(TRAS_MIN/tck);
    wire                 [11:0] trc      = ceil(TRC/tck);
    wire                 [11:0] trcd     = ceil(TRCD/tck);
    wire                 [11:0] trfc     = ceil(TRFC_MIN/tck);
    wire                 [11:0] trp      = ceil(TRP/tck);
    wire                 [11:0] trrd     = max(ceil(TRRD/tck), TRRD_TCK);
    wire                 [11:0] trtp     = max(ceil(TRTP/tck), TRTP_TCK);
    wire                 [11:0] twr      = ceil(TWR/tck);
    wire                 [11:0] twtr     = max(ceil(TWTR/tck), TWTR_TCK);
    wire                 [11:0] txp      = max(ceil(TXP/tck), TXP_TCK);
    wire                 [11:0] txpdll   = max(ceil(TXPDLL/tck), TXPDLL_TCK);
    wire                 [11:0] txpr     = max(ceil(TXPR/tck), TXPR_TCK);
    wire                 [11:0] txs      = max(ceil(TXS/tck), TXS_TCK);
    wire                 [11:0] txsdll   = TXSDLL;
    wire                 [11:0] tzqcs    = TZQCS;
    wire                 [11:0] tzqoper  = TZQOPER;
    wire                 [11:0] wr       = (twr < 8) ? twr : twr + twr%2;
    wire                 [11:9] mr_wr    = (twr < 8) ? (twr - 4) : twr>>1;

`ifdef TRUEBL4
    wire                 [11:0] tccd_dg  = TCCD_DG;
    wire                 [11:0] trrd_dg  = max(ceil(TRRD_DG/tck), TRRD_DG_TCK);
    wire                 [11:0] twtr_dg  = max(ceil(TWTR_DG/tck), TWTR_DG_TCK);
`endif

    initial begin
        $timeformat (-9, 1, " ns", 1);
`ifdef period
        tck <= `period; 
`else
        tck <= ceil(TCK_MIN);
`endif
        ck <= 1'b1;
        odt_fifo <= 0;
    end


//===========================================================================
//                         FPGA Memory Controller
//===========================================================================
//***************************************************************************
// The following parameters refer to width of various ports
//***************************************************************************
parameter COL_WIDTH             = 10;
parameter CS_WIDTH              = 1;
parameter DM_WIDTH              = 2;
parameter DQ_WIDTH              = 16;
parameter DQS_WIDTH             = 2;
parameter DRAM_WIDTH            = 8;
parameter DEBUG_PORT            = 25;
parameter ODT_WIDTH             = 1;
parameter ROW_WIDTH             = 14;
parameter ADDR_WIDTH            = 28;
parameter BURST_MODE            = "8";
parameter tCK                   = 2500;
parameter C_S_AXI_ID_WIDTH      = 4;
parameter C_S_AXI_ADDR_WIDTH    = 30;
parameter C_S_AXI_DATA_WIDTH    = 64;
localparam MEMORY_WIDTH         = 8;
localparam NUM_COMP             = DQ_WIDTH/MEMORY_WIDTH;
//localparam real TPROP_PCB_CTRL  = 0.00;
//localparam real TPROP_DQS          = 0.00;
//localparam real TPROP_DQS_RD       = 0.00;
//localparam real TPROP_PCB_DATA     = 0.00;
//localparam real TPROP_PCB_DATA_RD  = 0.00;
parameter CA_MIRROR             = "OFF";
wire    ddr_ck;
wire    core_clk;      
wire    sdram_clk;      
wire    rx_cal_clk;      
wire    tx_cal_clk;      
wire    tx_cal_clk_90;      
wire    pll_locked;    
wire[2:0]                                  pll_shift;  
wire[4:0]                                  pll_shift_sel;
wire                                       pll_shift_ena;

wire                                          ddr_dqs_oe;
wire                                          ddr_dq_oe;
wire   [DQS_WIDTH-1:0]                        ddr_dqs_in_hi;
wire   [DQS_WIDTH-1:0]                        ddr_dqs_in_lo;
wire   [DQ_WIDTH-1:0]                         ddr_dq_in_hi;
wire   [DQ_WIDTH-1:0]                         ddr_dq_in_lo;
wire   [DQS_WIDTH-1:0]                        ddr_dqs_out_hi;
wire   [DQS_WIDTH-1:0]                        ddr_dqs_out_lo;
wire   [DQ_WIDTH-1:0]                         ddr_dq_out_hi;
wire   [DQ_WIDTH-1:0]                         ddr_dq_out_lo;
wire   [DM_WIDTH-1:0]                         ddr_dm_hi;
wire   [DM_WIDTH-1:0]                         ddr_dm_lo;
wire                                          ddr3_reset_n;
wire   [DQ_WIDTH-1:0]                         ddr3_dq_fpga;
wire   [DQS_WIDTH-1:0]                        ddr3_dqs_p_fpga;
wire   [DQS_WIDTH-1:0]                        ddr3_dqs_n_fpga;
wire   [ROW_WIDTH-1:0]                        ddr3_addr_fpga;
wire   [3-1:0]                                ddr3_ba_fpga;
wire   [(CS_WIDTH*1)-1:0]                     ddr3_cs_n_fpga;
wire                                          ddr3_ras_n_fpga;
wire                                          ddr3_cas_n_fpga;
wire                                          ddr3_we_n_fpga;
wire   [1-1:0]                                ddr3_cke_fpga;
wire   [1-1:0]                                ddr3_ck_p_fpga;
wire   [1-1:0]                                ddr3_ck_n_fpga;
wire   [DM_WIDTH-1:0]                         ddr3_dm_fpga;  
wire   [ODT_WIDTH-1:0]                        ddr3_odt_fpga;

reg    [(CS_WIDTH*1)-1:0]                     ddr3_cs_n_sdram_tmp;
reg    [DM_WIDTH-1:0]                         ddr3_dm_sdram_tmp;
reg    [ODT_WIDTH-1:0]                        ddr3_odt_sdram_tmp;
wire   [DQ_WIDTH-1:0]                         ddr3_dq_sdram;
reg    [ROW_WIDTH-1:0]                        ddr3_addr_sdram [0:1];
reg    [3-1:0]                                ddr3_ba_sdram [0:1];
reg                                           ddr3_ras_n_sdram;
reg                                           ddr3_cas_n_sdram;
reg                                           ddr3_we_n_sdram;
wire   [(CS_WIDTH*1)-1:0]                     ddr3_cs_n_sdram;
wire   [ODT_WIDTH-1:0]                        ddr3_odt_sdram;
reg    [1-1:0]                                ddr3_cke_sdram;
wire   [DM_WIDTH-1:0]                         ddr3_dm_sdram;
wire   [DQS_WIDTH-1:0]                        ddr3_dqs_p_sdram;
wire   [DQS_WIDTH-1:0]                        ddr3_dqs_n_sdram;
reg    [1-1:0]                                ddr3_ck_p_sdram;
reg    [1-1:0]                                ddr3_ck_n_sdram;
//**************************************************************************//
// Clock Generation
//**************************************************************************//
reg     clk_ref;
  initial
    clk_ref = 1'b0;
  always
    clk_ref = #5000 ~clk_ref;
    
reg     axi_clk;
initial
  axi_clk = 1'b0;
always
  axi_clk = #4000 ~axi_clk;
        
//**************************************************************************//
// Reset Generation
//**************************************************************************//
localparam RESET_PERIOD = 200000; //in pSec 
reg                                sys_rst_n;
  initial begin
    sys_rst_n = 1'b0;
    #RESET_PERIOD
      sys_rst_n = 1'b1;
   end
     
//===========================================================================
//                         FPGA Memory Controller
//===========================================================================   
 efx_pll_gen # (
.FREQ_CLK_MHZ                    (20                ),
.CLK_OUT0_ENA                    (1                 ),
.CLK_OUT0_MHZ                    (400               ),
.CLK_OUT1_ENA                    (1                 ),
.CLK_OUT1_MHZ                    (400               ),
.CLK_OUT2_ENA                    (1                 ),
.CLK_OUT2_MHZ                    (400               ),
.CLK_OUT3_ENA                    (1                 ),
.CLK_OUT3_MHZ                    (400               ),
.CLK_OUT4_ENA                    (1                 ),
.CLK_OUT4_MHZ                    (100               )
)
u_EFX_PLL
(
.clk_ref			             (clk_ref           ),
.rst			                 (!sys_rst_n        ),
.pll_shift			             (pll_shift         ),
.pll_shift_sel			         (pll_shift_sel     ),
.pll_shift_ena			         (pll_shift_ena     ),
.clk_out4		                 (core_clk          ),
.clk_out1	                     (sdram_clk         ),
.clk_out2	                     (rx_cal_clk        ),
.clk_out3	                     (tx_cal_clk        ),
.clk_out0	                     (tx_cal_clk_90     ),
.pll_locked                      (pll_locked        )
);


   ddr3_example_top         u_ip_top
     (
       
    .pll_shift			    (pll_shift         ),
    .pll_shift_sel			(pll_shift_sel     ),
    .pll_shift_ena			(pll_shift_ena     ),       
///////////////DDR BUS
    .ddr_ck_hi              (ddr_ck_hi        ),
    .ddr_ck_lo              (ddr_ck_lo        ),
    .ddr_cke                (ddr3_cke_fpga    ),    
    .ddr_reset_n            (ddr3_reset_n     ),
    .ddr_cs_n               (ddr3_cs_n_fpga   ),
    .ddr_ras_n              (ddr3_ras_n_fpga  ),
    .ddr_cas_n              (ddr3_cas_n_fpga  ),
    .ddr_we_n               (ddr3_we_n_fpga   ),     
    .ddr_addr               (ddr3_addr_fpga   ),
    .ddr_ba                 (ddr3_ba_fpga     ),
    
    .ddr_dqs_oe             (ddr_dqs_oe          ),
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
    .ddr_odt                (ddr3_odt_fpga       ),
     
    .axi_clk                (axi_clk             ),
    .core_clk               (core_clk            ),
    .sdram_clk              (sdram_clk           ),  
    .rx_cal_clk             (rx_cal_clk          ),
    .tx_cal_clk             (tx_cal_clk          ),
    .tx_cal_clk_90edge      (tx_cal_clk_90       ),
    .pll_locked             (pll_locked          )
     );
 
EFX_GPIO_model #
    (
     .BUS_WIDTH                 (1'b1    ),
     .TYPE                      ("OUT"    ),
     .OUT_REG                   (1'b1    ),
     .OUT_DDIO                  (1'b1    ),
     .OUT_RESYNC                (1'b1    ),
     .OUTCLK_INV                (1'b0    ),
     .OE_REG                    (1'b0    ),
     .IN_REG                    (1'b0    ),
     .IN_DDIO                   (1'b0    ),
     .IN_RESYNC                 (1'b1    )
    )
   u_DDIO_CK
     (

     .out_HI              (ddr_ck_hi      ),
     .out_LO              (ddr_ck_lo      ),
     .outclk              (sdram_clk      ),

     .oe                  (1'b0           ),
     .in_HI               (               ),
     .in_LO               (               ),
     .inclk               (               ),
     .io                  (ddr_ck         )
     );
assign ddr3_ck_p_fpga = ddr_ck;
assign ddr3_ck_n_fpga = ~ddr_ck;


EFX_GPIO_model #
    (
     .BUS_WIDTH                 (DQS_WIDTH    ),
     .TYPE                      ("INOUT"    ),
     .OUT_REG                   (1'b1    ),
     .OUT_DDIO                  (1'b1    ),
     .OUT_RESYNC                (1'b1    ),
     .OUTCLK_INV                (1'b0    ),
     .OE_REG                    (1'b0    ),
     .IN_REG                    (1'b1    ),
     .IN_DDIO                   (1'b1    ),
     .IN_RESYNC                 (1'b1    )
    )
   u_DDIO_DQS
     (

     .out_HI              (ddr_dqs_out_hi   ),
     .out_LO              (ddr_dqs_out_lo   ),
     .outclk              (tx_cal_clk       ),

     .oe                  (ddr_dqs_oe       ),
     .in_HI               (ddr_dqs_in_hi    ),
     .in_LO               (ddr_dqs_in_lo    ),
     .inclk               (rx_cal_clk       ),
     .io                  (ddr3_dqs_p_fpga  )
     );    
assign ddr3_dqs_n_fpga = ddr_dqs_oe ? ~ddr3_dqs_p_fpga : 'bz;
     
EFX_GPIO_model #
    (
     .BUS_WIDTH                 (DQ_WIDTH    ),
     .TYPE                      ("INOUT"    ),
     .OUT_REG                   (1'b1    ),
     .OUT_DDIO                  (1'b1    ),
     .OUT_RESYNC                (1'b1    ),
     .OUTCLK_INV                (1'b0    ),
     .OE_REG                    (1'b0    ),
     .IN_REG                    (1'b1    ),
     .IN_DDIO                   (1'b1    ),
     .IN_RESYNC                 (1'b1    )
    )
   u_DDIO_DQ
     (

     .out_HI              (ddr_dq_out_hi  ),
     .out_LO              (ddr_dq_out_lo  ),
     .outclk              (tx_cal_clk_90  ),

     .oe                  (ddr_dq_oe      ),
     .in_HI               (ddr_dq_in_hi   ),
     .in_LO               (ddr_dq_in_lo   ),
     .inclk               (rx_cal_clk     ),
     .io                  (ddr3_dq_fpga   )
     );   

EFX_GPIO_model #
    (
     .BUS_WIDTH                 (DM_WIDTH ),
     .TYPE                      ("OUT"    ),
     .OUT_REG                   (1'b1    ),
     .OUT_DDIO                  (1'b1    ),
     .OUT_RESYNC                (1'b1    ),
     .OUTCLK_INV                (1'b0    ),
     .OE_REG                    (1'b0    ),
     .IN_REG                    (1'b0    ),
     .IN_DDIO                   (1'b0    ),
     .IN_RESYNC                 (1'b1    )
    )
   u_DDIO_DM
     (

     .out_HI              (ddr_dm_hi      ),
     .out_LO              (ddr_dm_lo      ),
     .outclk              (tx_cal_clk_90      ),

     .oe                  (1'b0           ),
     .in_HI               (               ),
     .in_LO               (               ),
     .inclk               (               ),
     .io                  (ddr3_dm_fpga   )
     );
     
     
/*     
    // component instantiation
        ddr3 u_comp_ddr3
          (
           .rst_n   (ddr3_reset_n           ),
           .ck      (ddr3_ck_p_fpga         ),
           .ck_n    (ddr3_ck_n_fpga         ),
           .cke     (ddr3_cke_fpga          ),
           .cs_n    (ddr3_cs_n_fpga         ),
           .ras_n   (ddr3_ras_n_fpga        ),
           .cas_n   (ddr3_cas_n_fpga        ),
           .we_n    (ddr3_we_n_fpga         ),
           .dm_tdqs      (ddr3_dm_fpga           ),
           .ba      (ddr3_ba_fpga           ),
           .addr    (ddr3_addr_fpga         ),
           .dq      (ddr3_dq_fpga           ),
           .dqs     (ddr3_dqs_p_fpga        ),
           .dqs_n   (ddr3_dqs_n_fpga        ),
           .tdqs_n  (                       ),
           .odt     (ddr3_odt_fpga          )
           );
*/
//**************************************************************************//
// Memory Models instantiations
//**************************************************************************//
  always @( * ) begin
    ddr3_addr_sdram[0]   <=   ddr3_addr_fpga;
    ddr3_addr_sdram[1]   <=   (CA_MIRROR == "ON") ?
                                                 {ddr3_addr_fpga[ROW_WIDTH-1:9],
                                                  ddr3_addr_fpga[7], ddr3_addr_fpga[8],
                                                  ddr3_addr_fpga[5], ddr3_addr_fpga[6],
                                                  ddr3_addr_fpga[3], ddr3_addr_fpga[4],
                                                  ddr3_addr_fpga[2:0]} :
                                                 ddr3_addr_fpga;
    ddr3_ba_sdram[0]     <=   ddr3_ba_fpga;
    ddr3_ba_sdram[1]     <=   (CA_MIRROR == "ON") ?
                                                 {ddr3_ba_fpga[3-1:2],
                                                  ddr3_ba_fpga[0],
                                                  ddr3_ba_fpga[1]} :
                                                 ddr3_ba_fpga;

  end
    

    
genvar r,i;
generate
  for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
    for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
      ddr3        u_comp_ddr3
        (
         .rst_n         (ddr3_reset_n                 ),
         .ck            (ddr3_ck_p_fpga               ),
         .ck_n          (ddr3_ck_n_fpga               ),
         .cke           (ddr3_cke_fpga [r]            ),
         .cs_n          (ddr3_cs_n_fpga[r]            ),
         .ras_n         (ddr3_ras_n_fpga              ),
         .cas_n         (ddr3_cas_n_fpga              ),
         .we_n          (ddr3_we_n_fpga               ),
         .dm_tdqs       (ddr3_dm_fpga[i]              ),
         .ba            (ddr3_ba_sdram[r]             ),
         .addr          (ddr3_addr_sdram[r]           ),
         .dq            (ddr3_dq_fpga[MEMORY_WIDTH*(i+1)-1:MEMORY_WIDTH*(i)]),
         .dqs           (ddr3_dqs_p_fpga[i]           ),
         .dqs_n         (ddr3_dqs_n_fpga[i]           ),
         .tdqs_n        (                             ),
         .odt           (ddr3_odt_fpga[r]             )
         );
    end
  end
endgenerate           
           
           
           
    // clock generator
    always @(posedge ck) begin
      ck <= #(tck/2) 1'b0;
      ck <= #(tck) 1'b1;
    end

    function integer ceil;
        input number;
        real number;
        if (number > $rtoi(number))
            ceil = $rtoi(number) + 1;
        else
            ceil = number;
    endfunction

    function integer max;
        input arg1;
        input arg2;
        integer arg1;
        integer arg2;
        if (arg1 > arg2)
            max = arg1;
        else
            max = arg2;
    endfunction

    task power_up;
        begin
            rst_n   <= 1'b0;
            cke     <= 1'b0;
            cs_n    <= 1'b1;
            odt_out <= 1'b0;
            # (10000); // CKE must be LOW 10ns prior to RST# transitioning HIGH.
            @ (negedge ck) rst_n   = 1'b1;
            # (10000) // After RST# transitions HIGH, wait 500us (minus one clock) with CKE LOW. (wait 10 ns instead of 500 us)
            @ (negedge ck) nop(TXPR/tck + 1); // After CKE is registered HIGH and after tXPR has been satisfied, MRS commands may be issued.
        end
    endtask

    task load_mode;
        input   [BA_BITS-1:0] bank;
        input [ADDR_BITS-1:0] addr;
        begin
            case (bank)
                0: mode_reg0 = addr;
                1: mode_reg1 = addr;
                2: mode_reg2 = addr;
            endcase
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b0;
            ba    <= bank;
            a     <= addr;
            @(negedge ck);
        end
    endtask

    task refresh;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            @(negedge ck);
        end
    endtask
     
    task precharge;
        input [BA_BITS-1:0] bank;
        input               ap; //precharge all
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n  <= 1'b0;
            ba    <= bank;
            a     <= (ap<<10);
            @(negedge ck);
        end
    endtask
     
    task activate;
        input  [BA_BITS-1:0] bank;
        input [ROW_BITS-1:0] row;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            ba    <= bank;
            a     <=  row;
            @(negedge ck);
        end
    endtask

    //write task supports burst lengths <= 8
    task write;
        input   [BA_BITS-1:0] bank;
        input  [COL_BITS-1:0] col;
        input                 ap; //Auto Precharge
        input                 bc; //Burst Chop  
        input [8*DM_BITS-1:0] dm;
        input [8*DQ_BITS-1:0] dq;
        reg   [ADDR_BITS-1:0] atemp [2:0];
        integer i;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n  <= 1'b0;
            ba    <= bank;

            atemp[0] = col & 10'h3ff;         //a[ 9: 0] = COL[ 9: 0]
            atemp[1] = ((col>>10) & 1'h1)<<11;//a[   11] = COL[   10]
            atemp[2] = (col>>11)<<13;         //a[ N:13] = COL[ N:11]
            a     <= atemp[0] | atemp[1] | atemp[2] | (ap<<10) | (bc<<12);

            casex ({bc, mode_reg0[1:0]})
                3'bx00, 3'b101:bl=8;
                3'bx1x, 3'b001:bl=4;
            endcase

            dqs_en <= #(wl*tck-tck/2) 1'b1;
            dqs_out <= #(wl*tck-tck/2) {DQS_BITS{1'b1}};
            for (i=0; i<=bl; i=i+1) begin
                dqs_en <= #(wl*tck + i*tck/2) 1'b1;
                if (i%2 == 0) begin
                    dqs_out <= #(wl*tck + i*tck/2) {DQS_BITS{1'b0}};
                end else begin
                    dqs_out <= #(wl*tck + i*tck/2) {DQS_BITS{1'b1}};
                end

                dq_en  <= #(wl*tck + i*tck/2 + tck/4) 1'b1;
                dm_out <= #(wl*tck + i*tck/2 + tck/4) dm>>i*DM_BITS;
                dq_out <= #(wl*tck + i*tck/2 + tck/4) dq>>i*DQ_BITS;
            end
            dqs_en <= #(wl*tck + bl*tck/2 + tck/2) 1'b0;
            dq_en  <= #(wl*tck + bl*tck/2 + tck/4) 1'b0;
            @(negedge ck);  
        end
    endtask

    // read without data verification
    task read;
        input   [BA_BITS-1:0] bank;
        input  [COL_BITS-1:0] col;
        input                 ap; //Auto Precharge
        input                 bc; //Burst Chop  
        reg   [ADDR_BITS-1:0] atemp [2:0];
        integer i;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            ba    <= bank;
            atemp[0] = col & 10'h3ff;         //a[ 9: 0] = COL[ 9: 0]
            atemp[1] = ((col>>10) & 1'h1)<<11;//a[   11] = COL[   10]
            atemp[2] = (col>>11)<<13;         //a[ N:13] = COL[ N:11]
            a     <= atemp[0] | atemp[1] | atemp[2] | (ap<<10) | (bc<<12);

            casex ({bc, mode_reg0[1:0]})
                3'bx00, 3'b101:bl=8;
                3'bx1x, 3'b001:bl=4;
            endcase

            for (i=0; i<(bl/2 + 2); i=i+1) begin
                odt_fifo[rl-wl + i] = 1'b1;
            end
            @(negedge ck);
        end
    endtask

    task zq_calibration;
        input long;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b0;
            ba    <=  0;
            a     <=  long<<10;
            @(negedge ck);
        end
    endtask

    task nop;
        input [31:0] count;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck);
        end
    endtask

    task deselect;
        input [31:0] count;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b1;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck);
        end
    endtask

    task power_down;
        input [31:0] count;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b1;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck);
        end
    endtask

    task self_refresh;
        input [31:0] count;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            cs_n  <= #(tck) 1'b1;
            ras_n <= #(tck) 1'b1;
            cas_n <= #(tck) 1'b1;
            we_n  <= #(tck) 1'b1;
            repeat(count) @(negedge ck);
        end
    endtask

    task pd_change_period;
        input [31:0] new_period;
        begin
            $display ("%m at time %t: INFO: Changing Clock Period to %08.3f ps", $time, new_period);
            power_down (tcksre+1);
            tck <= new_period;
            @(posedge ck);
            @(negedge ck);
            repeat(tcksrx) @(negedge ck);
        end
    endtask

    task sr_change_period;
        input [31:0] new_period;
        begin
            $display ("%m at time %t: INFO: Changing Clock Period to %08.3f ps", $time, new_period);
            self_refresh (tcksre+1);
            tck <= new_period;
            @(posedge ck);
            @(negedge ck);
            repeat(tcksrx) @(negedge ck);
        end
    endtask

    // read with data verification
    task read_verify;
        input   [BA_BITS-1:0] bank;
        input  [COL_BITS-1:0] col;
        input                 ap; //Auto Precharge
        input                 bc; //Burst Chop  
        input [8*DM_BITS-1:0] dm; //Expected Data Mask
        input [8*DQ_BITS-1:0] dq; //Expected Data
        integer i, j;
        begin
            read (bank, col, ap, bc);
            for (i=0; i<bl; i=i+1) begin
                j = (col ^ i)%bl;
                if (!bo) begin 
                    j = (j & -4) + ((col + i) & 3);
                end
                dm_fifo[2*rl + i] = dm>>(i*DM_BITS);
                dq_fifo[2*rl + i] = dq>>(i*DQ_BITS);
            end
        end
    endtask

    // receiver(s) for data_verify process
    dqrx dqrx[DQS_BITS-1:0] (ptr_rst_n, dqs, dq, q0, q1, q2, q3);

    // perform data verification as a result of read_verify task call
    always @(ck) begin:data_verify
        integer i;
        integer j;
        reg [DQ_BITS-1:0] bit_mask;
        reg [DM_BITS-1:0] dm_temp;
        reg [DQ_BITS-1:0] dq_temp;
        
        for (i = !ck; (i < 2/(2.0 - !ck)); i=i+1) begin
            if (dm_fifo[i] === {DM_BITS{1'bx}}) begin
                burst_cntr = 0;
            end else begin

                dm_temp = dm_fifo[i];
                for (j=0; j<DQ_BITS; j=j+1) begin
                    bit_mask[j] = !dm_temp[j/(DQ_BITS/DM_BITS)];
                end

                case (burst_cntr)
                    0: dq_temp =  q0;
                    1: dq_temp =  q1;
                    2: dq_temp =  q2;
                    3: dq_temp =  q3;
                endcase
                //if (((dq_temp & bit_mask) === (dq_fifo[i] & bit_mask)))
                //    $display ("%m at time %t: INFO: Successful read data compare.  Expected = %h, Actual = %h, Mask = %h, i = %d", $time, dq_fifo[i], dq_temp, bit_mask, burst_cntr);
                if ((dq_temp & bit_mask) !== (dq_fifo[i] & bit_mask))
                    $display ("%m at time %t: ERROR: Read data miscompare.  Expected = %h, Actual = %h, Mask = %h, i = %d", $time, dq_fifo[i], dq_temp, bit_mask, burst_cntr);

                burst_cntr = burst_cntr + 1;
            end
        end

        if (!ck) begin
            ptr_rst_n <= (dm_fifo[4] !== {DM_BITS{1'bx}});
            for (i=0; i<=(4*CL_MAX+BL_MAX); i=i+1) begin
                dm_fifo[i] = dm_fifo[i+2];
                dq_fifo[i] = dq_fifo[i+2];
            end
            odt_fifo = odt_fifo>>1;
        end
    end

    // End-of-test triggered in 'subtest.vh'
    task test_done;
        begin
            $display ("%m at time %t: INFO: Simulation is Complete", $time);
            $finish(0);
        end
    endtask

    // Test included from external file
    //`include "subtest.vh"

endmodule

module dqrx (
    ptr_rst_n, dqs, dq, q0, q1, q2, q3
);
/*
`ifdef den1024Mb
    `include "1024Mb_ddr3_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_ddr3_parameters.vh"
`elsif den4096Mb
    `include "4096Mb_ddr3_parameters.vh"
`elsif den8192Mb
    `include "8192Mb_ddr3_parameters.vh"
`else
    // NOTE: Intentionally cause a compile fail here to force the users
    //       to select the correct component density before continuing
    ERROR: You must specify component density with +define+den____Mb.
`endif
*/
`include "1024Mb_ddr3_parameters.vh"

    input  ptr_rst_n;
    input  dqs;
    input  [DQ_BITS/DQS_BITS-1:0] dq;
    output [DQ_BITS/DQS_BITS-1:0] q0;
    output [DQ_BITS/DQS_BITS-1:0] q1;
    output [DQ_BITS/DQS_BITS-1:0] q2;
    output [DQ_BITS/DQS_BITS-1:0] q3;

    reg [1:0] ptr;
    reg [DQ_BITS/DQS_BITS-1:0] q [3:0];

    reg ptr_rst_dly_n;
    always @(ptr_rst_n) ptr_rst_dly_n <= #(TDQSCK + TDQSQ + 2) ptr_rst_n;

    reg dqs_dly;
    always @(dqs) dqs_dly <= #(TDQSQ + 1) dqs;

    always @(negedge ptr_rst_dly_n or posedge dqs_dly or negedge dqs_dly) begin
        if (!ptr_rst_dly_n) begin
            ptr <= 0;
        end else if (dqs_dly || ptr) begin
            q[ptr] <= dq;
            ptr <= ptr + 1;
        end
    end
    
    assign q0 = q[0];
    assign q1 = q[1];
    assign q2 = q[2];
    assign q3 = q[3];
endmodule




