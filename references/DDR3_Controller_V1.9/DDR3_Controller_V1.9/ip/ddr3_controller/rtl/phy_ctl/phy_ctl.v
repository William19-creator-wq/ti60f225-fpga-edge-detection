//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : phy_ctl.v
// Version        : 1.2
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
`timescale 1 ps / 1 ps

module phy_ctl # (

parameter                       DEBUG_WIDTH     = 25,
parameter                       TCQ             = 100,     
parameter                       AL              = "0",     
parameter                       BANK_WIDTH      = 3,       
parameter                       BURST_MODE      = "8",     
parameter                       CK_WIDTH        = 1,       
parameter                       CL              = 5,
parameter                       COL_WIDTH       = 12,      
parameter                       CS_WIDTH        = 1,       
parameter                       CKE_WIDTH       = 1,       
parameter                       CWL             = 5,
parameter                       DM_WIDTH        = 8,       
parameter                       DQ_WIDTH        = 64,      
parameter                       DQS_CNT_WIDTH   = 3,       
parameter                       DQS_WIDTH       = 8,       
parameter                       DRAM_WIDTH      = 8,       
parameter                       RX_CLK_SEL        = 5'b00100, //rx_cal_clk  PLL out sel
parameter                       TX_CLK_SEL        = 5'b01000, //tx_cal_clk  PLL out sel
parameter                       TX_CLK_90EDGE_SEL = 5'b00001, //tx_cal_clk_90edge  PLL out sel
parameter                       CK_RATIO        = 4,       
parameter                       RANK_RATIO      = 1,       
parameter                       RTT_NOM         = "60",    
parameter                       RTT_WR          = "120",   
parameter                       tCK             = 2500,    
parameter                       tRFC            = 110000,  
parameter                       tREFI           = 7800000, 
parameter                       RANKS           = 4,
parameter                       ODT_WIDTH       = 1,
parameter                       ROW_WIDTH       = 16      
)
(
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
// PLL status flags  
output  reg [2:0]               pll_shift,  
output  reg [4:0]               pll_shift_sel,
output                          pll_shift_ena,   
// debug port 
output      [2:0]               rdlvl_shift, 
output      [2:0]               wrlvl_shift, 
output      [DEBUG_WIDTH-1:0]   ddr_phy_debug, 
output                          phy_mc_ctl_full,
output                          phy_mc_cmd_full,
output                          phy_mc_data_full,
output                          init_calib_complete,
output                          phy_rddata_valid,
output      [2*CK_RATIO*DQ_WIDTH-1:0]           
                                phy_rd_data,
input       [CK_RATIO-1:0]      mc_ras_n,
input       [CK_RATIO-1:0]      mc_cas_n,
input       [CK_RATIO-1:0]      mc_we_n,
input       [CK_RATIO*ROW_WIDTH-1:0]             
                                mc_address,
input       [CK_RATIO*BANK_WIDTH-1:0]            
                                mc_bank,
input       [CS_WIDTH*RANK_RATIO*CK_RATIO-1:0] 
                                mc_cs_n,
input                           mc_reset_n,
input       [1:0]               mc_odt,
input       [CK_RATIO*CKE_WIDTH-1:0]      
                                mc_cke,

input       [3:0]               mc_aux_out0,
input       [3:0]               mc_aux_out1,
input                           mc_cmd_wren,
input                           mc_ctl_wren,
input       [2:0]               mc_cmd,
input       [1:0]               mc_cas_slot,
input       [5:0]               mc_data_offset,
input       [5:0]               mc_data_offset_1,
input       [5:0]               mc_data_offset_2,
input       [1:0]               mc_rank_cnt,
input                           mc_wrdata_en,
input       [2*CK_RATIO*DQ_WIDTH-1:0]     
                                mc_wrdata,
input       [2*CK_RATIO*(DQ_WIDTH/8)-1:0] 
                                mc_wrdata_mask,
// DDR bus signals
output                          ddr3_ck_hi,
output                          ddr3_ck_lo,
output      [CKE_WIDTH-1:0]     ddr3_cke,
output                          ddr3_reset_n,
output      [CS_WIDTH*RANK_RATIO-1:0]
                                ddr3_cs_n,
output                          ddr3_ras_n,
output                          ddr3_cas_n,
output                          ddr3_we_n,
output      [BANK_WIDTH-1:0]    ddr3_ba,
output      [ROW_WIDTH-1:0]     ddr3_addr,

output                          ddr3_dqs_oe,
output                          ddr3_dq_oe,
input       [DQS_WIDTH-1:0]     ddr3_dqs_in_hi,
input       [DQS_WIDTH-1:0]     ddr3_dqs_in_lo,
input       [DQ_WIDTH-1:0]      ddr3_dq_in_hi,
input       [DQ_WIDTH-1:0]      ddr3_dq_in_lo,
        
output      [DQS_WIDTH-1:0]     ddr3_dqs_out_hi,
output      [DQS_WIDTH-1:0]     ddr3_dqs_out_lo,
output      [DQ_WIDTH-1:0]      ddr3_dq_out_hi,
output      [DQ_WIDTH-1:0]      ddr3_dq_out_lo,
output      [DM_WIDTH-1:0]      ddr3_dm_hi,
output      [DM_WIDTH-1:0]      ddr3_dm_lo,
output      [ODT_WIDTH-1:0]     ddr3_odt  
  
  );
//Parameter Define
localparam              CLK_PERIOD = tCK * CK_RATIO;

//Register Define

//Wire Define 
wire    [2*CK_RATIO*DQ_WIDTH-1:0]phy_wrdata;
wire    [CK_RATIO*ROW_WIDTH-1:0] phy_address;
wire    [CK_RATIO*BANK_WIDTH-1:0]phy_bank;
wire    [CS_WIDTH*RANK_RATIO*CK_RATIO-1:0] 
                                phy_cs_n;
wire    [CK_RATIO-1:0]          phy_ras_n;
wire    [CK_RATIO-1:0]          phy_cas_n;
wire    [CK_RATIO-1:0]          phy_we_n;
wire                            phy_reset_n;
wire    [3:0]                   calib_aux_out;
wire    [CK_RATIO-1:0]          calib_cke;
wire    [1:0]                   calib_odt;
wire                            write_calib;
wire                            wl_sm_start;
wire                            wl_sm_start_dly;
wire                            calib_ctl_wren;
wire                            calib_cmd_wren;
wire                            calib_wrdata_en;
wire    [2:0]                   calib_cmd;
wire    [1:0]                   calib_seq;
wire    [5:0]                   calib_data_offset_0;
wire    [5:0]                   calib_data_offset_1;
wire    [5:0]                   calib_data_offset_2;
wire    [1:0]                   calib_rank_cnt;
wire    [1:0]                   calib_cas_slot;
wire    [CK_RATIO*ROW_WIDTH-1:0]mux_address;
wire    [3:0]                   mux_aux_out;
wire    [3:0]                   aux_out_map;
wire    [CK_RATIO*BANK_WIDTH-1:0]
                                mux_bank;
wire    [2:0]                   mux_cmd;
wire                            mux_cmd_wren;
wire    [CS_WIDTH*RANK_RATIO*CK_RATIO-1:0]   
                                mux_cs_n;
wire                            mux_ctl_wren;
wire    [1:0]                   mux_cas_slot;
wire    [5:0]                   mux_data_offset;
wire    [5:0]                   mux_data_offset_1;
wire    [5:0]                   mux_data_offset_2;
wire    [CK_RATIO-1:0]          mux_ras_n;
wire    [CK_RATIO-1:0]          mux_cas_n;
wire    [1:0]                   mux_rank_cnt;
wire                            mux_reset_n;
wire    [CK_RATIO-1:0]          mux_we_n;
wire    [2*CK_RATIO*DQ_WIDTH-1:0]              
                                mux_wrdata;
wire    [2*CK_RATIO*(DQ_WIDTH/8)-1:0]          
                                mux_wrdata_mask;
wire                            mux_wrdata_en;
wire    [CK_RATIO-1:0]          mux_cke ;
wire    [1:0]                   mux_odt ;  
    
wire                            dqs_locked_start;
wire                            dqs_locked_done;
wire                            rdlvl_all_dqs_done;
wire    [1:0]                   dqs_bit_sample_err;
wire                            rdlvl_dqs_check_ena;
wire    [DQS_WIDTH-1:0]         wrlvl_dqs_hi;
wire    [DQS_WIDTH-1:0]         wrlvl_dqs_lo;
wire    [DQS_WIDTH-1:0]         ddr_dqs_out_hi;
wire    [DQS_WIDTH-1:0]         ddr_dqs_out_lo;
wire                            wr_level_start;  
wire                            wrlvl_dqs_oe;  
wire                            calib_dq_oe;  
wire                            calib_dqs_oe;  
wire                            wr_level_done;  
wire                            wrlvl_rank_done; 
wire                            wr_level_delay; 
wire                            dqs_invert; 
wire                            dq_check_en; 
wire                            dq_bit_sample_ok; 
wire                            rdlvl_dqs_shift_ena;
wire                            wrlvl_shift_ena;
wire    [2:0]                   rdlvl_dqs_phise_shift;
wire    [2:0]                   wrlvl_phise_shift;
wire    [DM_WIDTH-1:0]          ddr_dm_hi;
wire    [DM_WIDTH-1:0]          ddr_dm_lo;
wire                            phy_rddata_valid_w;
wire    [2*CK_RATIO*DQ_WIDTH-1:0]              
                                phy_rd_data_w;
wire                            mpr_rddata_valid;
wire    [2*CK_RATIO*DQ_WIDTH-1:0]              
                                mpr_rd_data;
wire                            wrcal_rddata_valid;
wire    [2*CK_RATIO*DQ_WIDTH-1:0]
                                wrcal_rd_data;
wire                            mpr_rdlvl_dly;
wire                            idelay_ld;
wire                            wrcal_resume;
wire                            wrcal_pat_resume;
wire    [31:0]                  phy_ctl_wd;  
wire                            phy_dqs_oe;
wire                            phy_dq_oe;
wire                            phy_ctl_full;
wire                            phy_cmd_full;
wire                            phy_data_full;
wire    [2:0]                   shift;  
wire    [4:0]                   shift_sel;
wire                            shift_ena; 
wire                            phy_rst; 
wire    [6:0]                   init_cur_state;
wire    [7:0]                   rd_level_dqs_check;
wire    [7:0]                   wrlvl_dq_check;
reg                             pll_shift_wl_sel;
wire    [16-1:0]                debug_fifo;
wire    [16-1:0]                overflow_fifo;

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
iqeb87dsd+9H+LmqlvsRCHlrQoLzlOXQIcp0k3+Ax3wxVPEqSQDnrgNv4ot8ukm5
kBkftfdDAM1o33PpwQwayY6OdRJvrYETfwHqSKhlx4ejeg2UKM9TmYyEFYCqj8KK
Sz19JXNLfVNHlzqhHx9GYZ6vGOixTksH8CAR7Fwvg8I=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
qk/pwRaXP3O0SDv7QmBrJRX8CHLpOp4JY4Pt+5jj55nPCcCveUhKEn3ZtNpBCSAS
H2IBlbW2wP46i48AAkMZqY0AIG0KXK1HC/XtFwhPu3Nw1xTF9R1LjNABiAThrHJK
lD9R1JZPLbhfOOPo9hTg/R73xYSDqWARqXjyFuOTB6l9wJr27ZlyNlAJcR+cuXWM
57MhPoN6r0eH+w4clfJnfZmym770tJtGhRrGne/g3k8KGgL+A9vJp1OgpcsXIr9H
Cn61YhywuAY+QRECZgGxnBh06dm1j4yTIXP+w7Vu6kygIRxlJ3oqYzSPAldy2Hb0
9LywQFJGtsIe53KJNQ19Xg==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
s02GuxYqm4myfkXmZcgzVVveNa2AyWItNQs+nv47WYM7trcJPafUHX5lQfgjh4MH
Kha9oaqn6GaON3XfHdDt9S0TXXqSZp/RPRc1NXSj9pf9IHXCEt8wE3YM5lLVxwpG
p/Oye585V57HppSDvq3GJBhQxON2ZrZxKxYswkZErmM=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
PRL3iDNsBZ3Kr9Jd25UB5Kmno85+2R8JQH0AfO2+KcWIIGXrMaovikOmAP2dFktM
iVDVC/Xd8/J9rn7p1vBSm4SPGDotolqNnRqI5WkkGL85LBZnGRiOSQHoy0DERi6U
hagmmFlyU+vElv4Uefo65bPr2xBj/4BMZkKCFuSQ4crcbdYZSqNoGAdFvcL4DNWw
4S5gfYk8VjHRuWofeZn4amcmv9cqisH59wUWMlG3MU/ADRj43zx0kb5unam+okQj
XFYxAawUoLTih8Muaj+zgAOvOPesNYeepnYJcxdeV4L6/6O6abOGiI2aOb7tFHhL
DX86UalNiuyNWdKFHW9fZA==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
iSoScLP1jzn9xPL8BTujUjv1eY8Kj3lDXd8Srs6WZw1aXLqY3bZaSwF5bOhokgvd
Fx7wUx24BldObniXgnO36ONbse1Pwn4WbqInfAN1BJi4t1x5VRvrdrwYzYuJ32h4
heBg2Du0Pe8rXtFFZzsKfAOek9ZtoQhczdus/UsFZmLqQ69cy/tdxWwB0FGyqGxs
guQqPNhmM5WkLj13FlsDw7OEoTHPLHIAsIfe6L31VDz4fvwvLRVJcLYZSaPXY9nc
Be7YN+w6wXCmjoO6B+9x+9eFJ2mX6sGS00D2lfhovuRCjnry9G4OEe8Y06SHvFeb
zoyS0fVxI2MjtUU0tEtgCg==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=22656)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
