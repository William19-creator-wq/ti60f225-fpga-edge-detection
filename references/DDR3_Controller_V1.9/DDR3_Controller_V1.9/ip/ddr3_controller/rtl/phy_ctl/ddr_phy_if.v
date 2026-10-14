//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ddr_phy_if.v
// Version        : 1.3
// Date Created   : 2023-02-23 10:37:59
// Last Modified  : 2023-02-23 10:37:59
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/


  `timescale 1ps/1ps
module ddr_phy_if #(
parameter                       tCK          = 1500,        
parameter                       WL           = 5,           
parameter                       nCL          = 5,                   
parameter                       CK_RATIO     = 4,           
parameter                       BANK_WIDTH   = 2,
parameter                       RANK_RATIO   = 1,           
parameter                       DQ_WIDTH     = 64,
parameter                       DQS_WIDTH    = 8,
parameter                       DM_WIDTH     = 8,
parameter                       ROW_WIDTH    = 14,
parameter                       CS_WIDTH     = 1,
parameter                       ODT_WIDTH    = 1,
parameter                       CKE_WIDTH    = 1       

)(
// clock & reset
input                           core_clk,            // CORE CLK @ 100MHz
input                           sdram_clk,           // SDRAM CK @ 400MHz
input                           rx_cal_clk,          // SDRAM CK @ 400MHz
input                           tx_cal_clk,          // SDRAM CK @ 400MHz
input                           tx_cal_clk_90edge,   // SDRAM CK @ 400MHz
input                           sdram_rst,
input                           rx_clk_rst,
input                           tx_data_rst,
input                           rst,
input                           tx_clk_rst,

input                           phy_cmd_wr_en,
input                           phy_data_wr_en,
input           [31:0]          phy_ctl_wd,
input                           phy_ctl_wr,
output                          phy_ctl_full,
output                          phy_cmd_full,
output                          phy_data_full,
output                          wl_sm_start,
output  reg     [1:0]           dqs_bit_sample_err,
output  reg                     dq_bit_sample_ok,
output  reg                     ddr_dq_vld_r,
input                           dq_check_en,
input                           rdlvl_dqs_check_ena,
input                           idelay_ld,
input                           wrlvl_rank_done,
input                           wr_level_delay,
input                           mpr_rdlvl_dly,
input                           mpr_rdlvl_en,
input                           dqs_invert,
// From/to calibration logic/soft PHY
input                           init_calib_complete,
input           [CK_RATIO-1:0]  mux_cke,
input           [CS_WIDTH*RANK_RATIO*CK_RATIO-1:0] 
                                mux_cs_n,
input           [CK_RATIO-1:0]  mux_ras_n,
input           [CK_RATIO-1:0]  mux_cas_n,
input           [CK_RATIO-1:0]  mux_we_n,
input           [CK_RATIO*BANK_WIDTH-1:0] 
                                mux_bank,
input           [CK_RATIO*ROW_WIDTH-1:0]  
                                mux_address,
input           [1:0]           mux_odt,
input           [2*CK_RATIO*DQ_WIDTH-1:0] 
                                mux_wrdata,
input           [2*CK_RATIO*DM_WIDTH-1:0] 
                                mux_wrdata_mask,
input                           mux_reset_n,
output                          phy_rddata_valid,
output           [2*CK_RATIO*DQ_WIDTH-1:0]
                                phy_rd_data,
output           [8-1:0]        debug_fifo,                                
output           [8-1:0]        overflow_fifo,                                
// DDR bus signals
output                          ddr_ck_hi,
output                          ddr_ck_lo,
output           [CKE_WIDTH-1:0]ddr_cke,
output                          ddr_reset_n,
output           [CS_WIDTH*RANK_RATIO-1:0]
                                ddr_cs_n,
output                          ddr_ras_n,
output                          ddr_cas_n,
output                          ddr_we_n,
output           [BANK_WIDTH-1:0]
                                ddr_ba,
output           [ROW_WIDTH-1:0]ddr_addr,
               
input            [DQS_WIDTH-1:0]ddr_dqs_in_hi,
input            [DQS_WIDTH-1:0]ddr_dqs_in_lo,
input            [DQ_WIDTH-1:0] ddr_dq_in_hi,
input            [DQ_WIDTH-1:0] ddr_dq_in_lo,

output  reg                     phy_dqs_oe,
output  reg                     phy_dq_oe,
output           [DQS_WIDTH-1:0]ddr_dqs_out_hi,
output           [DQS_WIDTH-1:0]ddr_dqs_out_lo,
output  reg      [DQ_WIDTH-1:0] ddr_dq_out_hi,
output  reg      [DQ_WIDTH-1:0] ddr_dq_out_lo,
output  reg      [DM_WIDTH-1:0] ddr_dm_hi,
output  reg      [DM_WIDTH-1:0] ddr_dm_lo,
output  reg      [ODT_WIDTH-1:0]ddr_odt

);

//Parameter Define
localparam CWL_M =  WL ;//+ nAL;
localparam CMD_WTH = (CKE_WIDTH+3+ (CS_WIDTH*RANK_RATIO)+BANK_WIDTH+ROW_WIDTH) *CK_RATIO;
localparam DFIFO_WTH =2*CK_RATIO*(DQ_WIDTH + DM_WIDTH);
localparam FIFO_DEPTH =16;
localparam WR  = 4'b0100;
localparam RD  = 4'b0101;
localparam POS = 2'b10;
localparam NEG = 2'b01;

//Register Define
reg                             u1_wrreq_r;
reg     [CMD_WTH+1:0]           u1_data_r;
reg                             u2_wrreq_r;
reg     [31:0]                  u2_data_r;
reg                             u4_wrreq;
reg     [2*CK_RATIO*(DQ_WIDTH)-1:0]    
                                u4_data;
reg     [CK_RATIO-1:0]          rd_data_cke  ;
reg     [CS_WIDTH*RANK_RATIO*CK_RATIO-1:0]
                                rd_data_cs_n ;
reg     [CK_RATIO-1:0]          rd_data_ras_n;
reg     [CK_RATIO-1:0]          rd_data_cas_n;
reg     [CK_RATIO-1:0]          rd_data_we_n ;
reg     [CK_RATIO*BANK_WIDTH-1:0]
                                rd_data_ba   ;
reg     [CK_RATIO*ROW_WIDTH-1:0]       
                                rd_data_addr ;
reg                             rd_data_cke_r1;
reg                             mux_odt_r1;
reg                             mux_odt_r2;
reg                             mux_odt_r3;
reg     [WL+1:0]                mux_odt_delay;
reg                             rd_data_cs_n_r1;
reg                             rd_data_ras_n_r1;
reg                             rd_data_cas_n_r1;
reg                             rd_data_we_n_r1;
reg     [BANK_WIDTH-1:0]        rd_data_ba_r1   ;
reg     [ROW_WIDTH-1:0]         rd_data_addr_r1 ;
reg                             ddr_ctl_wren;
reg                             wr_cmd_en;
reg     [1:0]                   mem_dqs_out;
reg     [2*CK_RATIO*DQ_WIDTH-1:0]
                                mem_dq_out   ;
reg     [2*DQ_WIDTH-1:0]        mem_dq_out_r1;
reg     [2*CK_RATIO*DM_WIDTH-1:0]      
                                mem_dm_out   ;
reg     [2*DM_WIDTH-1:0]        mem_dm_out_r1;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_hi_r1;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_hi_r2;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_hi_r3;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_lo_r1;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_lo_r2;
reg     [DQ_WIDTH-1:0]          ddr_dq_in_lo_r3;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_hi_r1;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_hi_r2;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_hi_r3;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_lo_r1;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_lo_r2;
reg     [DQS_WIDTH-1:0]         ddr_dqs_in_lo_r3;
reg     [1:0]                   wr_data_cnt;
reg     [2*CK_RATIO-1:0]        rd_dq_ena;
reg     [WL+2:0]                wr_data_en;
reg     [WL+4:0]                wr_ctl_en;
(* async_reg = "true" *)reg     idelay_ld_r1;
(* async_reg = "true" *)reg     idelay_ld_r2;
(* async_reg = "true" *)reg     idelay_ld_r3;
reg                             wrcal_delay;
reg                             rdlvl_check_ena_r1;
reg                             rdlvl_check_ena_r2;
reg                             rdlvl_check_ena_r3;
reg                             rdlvl_check_ena;
reg                             wrlvl_check_ena;
(* async_reg = "true" *)reg     dq_check_en_r1;
(* async_reg = "true" *)reg     dq_check_en_r2;
(* async_reg = "true" *)reg     dq_check_en_r3;
reg                             dq_in_hi_r1;
reg                             dq_in_hi_r2;
reg                             dq_in_lo_r1;
reg                             dq_in_lo_r2;
reg     [1:0]                   dq_bit_sample_cnt;
reg     [DQS_WIDTH-1:0]         dqs_sample_err;
(* async_reg = "true" *)reg     ddr_rden_r1;
(* async_reg = "true" *)reg     ddr_rden_r2;
(* async_reg = "true" *)reg     ddr_rden_r3;
reg     [1:0]                   dqs_sample_reslut[DQS_WIDTH-1:0];
(* async_reg = "true" *)reg     ddr_wren_r1;
(* async_reg = "true" *)reg     ddr_wren_r2;
(* async_reg = "true" *)reg     ddr_wren_r3;
(* async_reg = "true" *)reg     ddr_wren_r4;
(* async_reg = "true" *)reg     ddr_wren_r5;
reg     [3:0]                   stable_cnt[DQS_WIDTH-1:0];
reg     [DQS_WIDTH-1:0]         dq_in_hi_or_prev;
reg     [DQS_WIDTH-1:0]         flag_ck_posedge;
reg     [DQS_WIDTH-1:0]         flag_ck_negedge;
reg     [DQS_WIDTH-1:0]         rd_data_edge_detect_r;
reg     [nCL+6:0]               rd_data_en_ctl;
reg                             rd_data_en;
reg                             wl_dqs_out_en ;
reg                             wl_dqs_en     ;
reg                             wl_dqs_en_r1  ;
reg                             wl_dqs_en_r2  ;
//Wire Define
wire                            u1_wrreq_ns;
wire    [CMD_WTH+1:0]           u1_data_ns;
wire                            u1_wrreq;
wire    [CMD_WTH+1:0]           u1_data;
wire                            u1_almfull;
wire                            u1_full;
wire                            u1_progfull;
wire                            u1_empty;
wire                            u1_rdreq;
wire    [CMD_WTH+1:0]           u1_q;
wire                            u2_wrreq_ns;
wire    [31:0]                  u2_data_ns;
wire                            u2_wrreq;
wire    [31:0]                  u2_data;
wire    [31:0]                  u2_q;
wire                            u2_almfull;
wire                            u2_full;
wire                            u2_empty;
wire                            u2_rdreq;
wire                            u3_wrreq;
wire    [2*CK_RATIO*(DQ_WIDTH/8+DQ_WIDTH)-1:0] 
                                u3_data;
wire    [2*CK_RATIO*(DQ_WIDTH/8+DQ_WIDTH)-1:0] 
                                u3_q;
wire                            u3_almfull;
wire                            u3_full;
wire                            u3_empty;
wire                            u3_rdreq;
wire    [2*CK_RATIO*(DQ_WIDTH)-1:0]    
                                u4_q;
wire                            u4_almfull;
wire                            u4_full;
wire                            u4_empty;
wire                            u4_wrreq_temp;
wire                            u4_rdreq;
wire    [2*DQ_WIDTH-1:0]        ddr_dq_data;
wire                            cmd_fifo_afull;
wire                            cmd_fifo_full;
wire                            ctl_fifo_full;
wire                            ctl_fifo_afull;
wire    [CMD_WTH+1:0]           phy_din;
wire    [3:0]                   ddr_cmd;
wire    [2:0]                   phy_cmd;
wire    [5:0]                   phy_data_offset;
wire                            wr_data_en_ns;
wire                            wr_data_en_temp;
wire                            wr_ctl_en_temp;
wire                            dqs_bit_and_hi;
wire                            dqs_bit_and_lo;
wire                            wr_dqs_en0;
wire                            wr_dqs_en1;
wire                            wr_dq_in_en;
wire    [DQ_WIDTH/8-1:0]        dq_in_hi_or;
wire    [DQ_WIDTH/8-1:0]        dq_in_lo_or;
wire    [DQ_WIDTH-1:0]          ddr_dq_out_hi_temp1;
wire    [DQ_WIDTH-1:0]          ddr_dq_out_lo_temp1;
wire    [DM_WIDTH-1:0]          ddr_dm_hi_temp1;
wire    [DM_WIDTH-1:0]          ddr_dm_lo_temp1;
wire    [DQ_WIDTH-1:0]          ddr_dq_out_hi_temp2;
wire    [DQ_WIDTH-1:0]          ddr_dq_out_lo_temp2;
wire    [DM_WIDTH-1:0]          ddr_dm_hi_temp2;
wire    [DM_WIDTH-1:0]          ddr_dm_lo_temp2;
wire    [2*DQ_WIDTH-1:0]        mem_dq_out_r0;
wire    [2*DM_WIDTH-1:0]        mem_dm_out_r0;
wire    [1:0]                   dqs_sample_edge  [DQS_WIDTH-1:0];
wire    [1:0]                   dqs_sample       [DQS_WIDTH-1:0];
wire    [DQS_WIDTH-1:0]         dqs_sample_r     [1:0]          ;
wire    [5:0]                   u1_rdata_cnt;
wire    [5:0]                   u1_wdata_cnt;
wire                            u1_rdreq_temp;
reg     [1:0]                   u2_rd_cmd_cnt;
wire                            u2_rdreq_temp;
wire    [5:0]                   u2_rdata_cnt;
wire    [5:0]                   u2_wdata_cnt;
reg                             rd_ctl_en;
reg     [1:0]                   u1_rd_cmd_cnt;
reg                             rd_cmd_en;
wire    [4:0]                   u1_rddata_count;
wire    [4:0]                   u2_rddata_count;
wire                            ddr_rden;
wire                            ddr_wren;
reg                             ddr_rden_dly;
reg                             ddr_wren_dly;

`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="http://ipencrypter.com Version: 20.0.8"
`pragma protect author="author-a"
`pragma protect author_info="author-a-details"
`pragma protect data_method="aes256-cbc"

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
Z/SgumTp3NvZaMY6QNe+gjm++mqwb093nBwpyWSO9c07m2aNK6TPea6iZTGSl6sR
AXPqFgh/cFP5FwZIECZ5i0pUQpEaPiHDP8/26hitjylkjUQtEmWm/5L0TYkRq7Ll
1b+fq9mB49HZF0zj6i8/3jZmhJdmywklZiSahiAXY+Q=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
fhm4ZDDuwJ0Fp9rjwH4+2dIcqsOiO2AHsBdinC7Q+iq2bi15BApcSLqJWM5rbxhw
WVVNFrpzyRG9eOjqTJPFjl3UfLTPB5OrJvSrvFYYW4dnA2NwLvzH083kDGJSPnUR
NHvVsV4dQelaBQS/syJCxInxcl1D8iwrqi0GC0yuIaQJkefFMwT2f+m8F9XxyhyO
l57euwWVSGkBqsnRpqrl0OyVtLzy4Fd1H9CWME43GFK8hSMa+rwEzu2daU3cQrWK
uXc736vSTxzPxS9w3QN7RmYD9rdPzjHUsxIS+I51edjq5Kpt3WxzpsxG5MTxiueu
3le6urWZWWbpRQvgLDxZ3A==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
aiLxB0UePSk17BFuAwxBdCemFPivN8urXxK94UVeYnfvKwmGLZY+vfoViQ+wTNiv
UNdjDWiNyp9CqEivPEX9QDhnb71u+lUrNLCjVnWriWj6pcAbwYI8m3PUJRYP/F38
3cGzzjOCEsxdJ72NisM7obAz3XA0eLN5x3aNChzuzHc=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
bpEeXg1oePHtAdzUf9yw7TpLTAXJnWw+i7Wxo6Nqmj8WTLPLEB/h3ICcbfEYr3MR
AD7tZFxrCYnv475Kru9PWLZjWTK904AuiYDon5S6O4kuBjKhA7p0HkPSi/SVtQsa
Znp2F4kAsFVovTbFUugmTE9lxgNIDpIiZwAcY6Wmujjq/wi0DnT4+JhJNN/wlZ8B
OKnk2wCkAvLpcDIBHod7DBR3WEyGyq8+J3QObStYDSeCQKKdtyAUZmK192MCxSfo
/2ZaDffadsBkSrRb+V41wFQN/LEzM3heGAdsrqn/W60rpxsZcVJjG9acoMF/ecRD
TzC31ZPDLE3yIPXOO6bauA==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
hjnyTV0e0kvxAjXicHzGFWNkn6K1FepH15a/ND1Bb2t6d7hnvzkPhAPtHMvRe450
XIL4pHX6r9pSkJd7rnRl0F3jxBGY0XTbmlBVEkpd50mH4bhyLLEK0rYIjRJjPUF3
J5qPTwdurWwgJSuSp5KOBrSE+9uvVwwkrOhIDw4nlN0e/VnXrKqP0xfL+egpDRNK
+51UpuyfhrBTf5rJVaNPCk08OLtvHH/XQ48wmgeqUZBBeoffHZ5utEkkjmIiIoZn
9YDzQTSlY4l4lF9nBdzC2E0flduW1Gf2CkXNqtZa4iJNGf6ySXzGm0hwCbc8BKXT
GC2kWhOQaguFrNofettWRg==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=29632)
`pragma protect data_block
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
wawHQQ/XK25uQs5fr3DPnQ==
`pragma protect end_protected
endmodule
