//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ddr_phy_wrlvl.v
// Version        : 1.0
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

module ddr_phy_wrlvl # (
parameter                       TCQ         = 100,
parameter                       DQ_WIDTH    = 64,
parameter                       DRAM_WIDTH  = 8,
parameter                       DQS_WIDTH   = 2
)
(
input                           clk,
input                           rst,
input                           wr_level_start,
input                           write_calib,
input                           wl_sm_start,
input                           dq_bit_sample_ok,

output          [7:0]           wrlvl_dq_check,
output  reg                     dqs_invert ,
output  reg                     dq_check_en ,
output  reg                     wrlvl_rank_done ,
output  reg                     wr_level_done ,
output  reg                     wrlvl_shift_ena,  
output  reg     [2:0]           wrlvl_phise_shift,
output  reg     [2:0]           wrlvl_shift
   );

//Parameter Define
localparam              PHISE_TAPS     = 8;
localparam              PLL_SHIFT_NUM  = 4;
localparam              WL_DQS_NUM     = 16;
localparam              PLL_BLANK_NUM  = 64;

localparam              PLL_SHIFT_WTH  = clogb2(PLL_SHIFT_NUM); 
localparam              WL_DQS_WTH     = clogb2(WL_DQS_NUM); 
localparam              TAP_WTH        = clogb2(PHISE_TAPS);
localparam              BLANK_NUM_WTH  = clogb2(PLL_BLANK_NUM);
 
localparam              IDLE           = 3'h0;
localparam              WLDQSEN_WAIT   = 3'h1;
localparam              DQS_WAIT       = 3'h2;
localparam              WL_EADG_CHECK  = 3'h3;
localparam              PLL_SHIFT      = 3'h4;
localparam              SEND_DQS_INC   = 3'h5;
localparam              SEND_DQS_INVERT= 3'h6;
localparam              DQ_CHECK_DONE  = 3'h7;

//Register Define
reg     [2:0]                   cur_state;
reg     [2:0]                   next_state;  
reg     [WL_DQS_WTH-1:0]        wrlvl_check_cnt;
reg     [PLL_SHIFT_WTH-1:0]     pll_shift_cnt;
reg     [2:0]                   wr_level_shift_cnt;
reg     [BLANK_NUM_WTH-1:0]     pll_blank_cnt;
(* async_reg = "true" *)reg                             dq_bit_ok_r1;
reg                             dq_bit_ok_r2;
reg                             dq_bit_ok_r3;
reg     [7:0]                   dq_dynmic_shift;
reg                             check_err;
reg                             check_err_r;
reg     [TAP_WTH-1:0]           rising_tap;
reg                             rising_tap_vld;
reg     [TAP_WTH-1:0]           next_rising_tap;
reg                             next_rising_tap_vld;
reg     [TAP_WTH-1:0]           first_rising_tap;
reg                             first_rising_tap_vld;
reg     [TAP_WTH-1:0]           failling_tap;
reg                             failling_tap_vld;
reg     [TAP_WTH-1:0]           next_failling_tap;
reg                             next_failling_tap_vld;
reg                             replace_flag;
reg     [TAP_WTH-1:0]           calibrate_tap;
reg                             last_flag;
reg                             clean_flag;
reg     [3:0]                   check_err_cnt;
reg                             dqs_invert_r1;
reg                             dqs_invert_r2;

//Wire Define
wire    [TAP_WTH-1:0]           calibrate_1tmp;
wire    [TAP_WTH-1:0]           calibrate_2tmp;
wire    [TAP_WTH-1:0]           calibrate_3tmp;
wire                            case_1tmp;
wire                            case_2tmp;
wire                            case_3tmp;
wire    [TAP_WTH-1:0]           tap_cnt;  
wire                            dqs_invert_edge;
//wire    [7:0]                 check_debug = 8'b01111111;

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
hy6tLQVQfS1MOk5CzNN8opUoVcVOnGF9cAYcHkivdlM8p7VOrVOs8j2PiOTw5w5O
8pJQBJpmFB81vn4Kr+hVPY+Klr0FYEg5LKpILgShKozQoNnYhV5+3woVto2urHQV
pag+dRo2885/3MEfKhVS+/L4LVFe4wATSSpLHMynX6A=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
J/IH2eDAhkDspsqIr9a/dXs6gcyLahXRoT+hwfBH6qWmllxZV2LAytzTaYz49G4S
FW6DkcpzvAq91dnmstGQ5nzdpY5Xo9buGd78+/bUm34SzxvcuGWd7GS2zW+lsVT+
HZOnpviZr+TULUN6xb/rXtUF2QYkGMLfmaVyAQSt1kcnxtSMBgKJ3dWQ7Ww0nCRQ
mNtwH+ajUXfm2kDVPlzNBha/FFrGiTCfNsuXn7rlZ9Hy7GSsWV2w4XLUmdrgfpvI
F9R/hpRIm5Piq2rm5qEUF5rXLk779kl+UZtARgq8WSV6Ukb70srVPg+b0oHRb/FR
imvK272sIL6mKfaZMtF5Jw==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
e78JbOJ2Xlb04meaQ6/GfqnlLuU5oidklcsPrGGmxthvzOcK1Nw4eCiQOYhTHzHq
+vyRzwQm6fy5mcY/pGOtn2lqrcoP8EjYffIVrX6nzTbb7kmQRM2Sxin/hYKBV0VN
dIR0GzN9PJMKygejjHxahlrAUlUmj5ipcOrSgaO2uro=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
OWAt7Ikwlwzrh2KTiK73hmko7bzKu9+HRT41FLuXlpLwK5W+TPBysJiDJ7qr2lX6
Kb+lbmuYDWP+UvrZAcPoguFHslSFEvFiaY8Ceu1lgmmwu8USLh1bmzZ7XM7tF0Fx
wtEEcKxR5jkpKMH6m3dgUmS3vz3ChkdtQewe2WgSnfGxBH4+61kzWdRIPhFC+0ex
u+7IwjvE9O5ElGcxfIAZCspksF+Kz6pFfWmT+qynQCMuqnuM4BdH2B6cm47Eiw8a
lsRb0SPnnx4TJNu/wcZRiKjhsQweS3qJvjBBr5+1g39Arc/nbJ88h+zS9j0hB/nP
r7UcTL6IDKfNznORlc3C4w==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
S9hNlEKP2qfeXSG7cr3Rg4UgmFraaLIPY7rVk+Uku24vflJiIoMFsPGhq6NuJUdo
1JHpxd2/OXKaZVhaHw+zBmVXX+aVXWcma4HdVu+p8eAM7bQR+/iyKmsiBic/yAfD
GY1MyPFH1BLrivdcsB7EggDZVqYUyVXl/NV9QrDdiwy6xSwPwgpl2/9B0C3nAbNV
XbG0Fn538LILcHJe3lZkLebKV2zkiurPmom91LBujSFgZMVIUmHtMmkzRy+qf7nx
y78LgwQKTFUZF96pYkUKqopgbaVG+3zvmhcgLfOfd2Jdv+douUPffvg5r0p2ILdd
FzAIextnh4zBMzlwXBwAfg==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=15488)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
