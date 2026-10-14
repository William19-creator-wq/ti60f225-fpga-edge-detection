//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ddr_phy_rdlvl_dqs.v
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

module ddr_phy_rdlvl_dqs #(
parameter                       TCQ             = 100,
parameter                       DQS_CHECK_TIME  = 512,
parameter                       DQS_CNT_WIDTH   = 3,
parameter                       DQS_WIDTH       = 2
)
(
input                           clk,
input                           rst,
input                           rd_dqs_start,
input           [1:0]           dqs_bit_sample_err,

output          [7:0]           rd_level_dqs_check,
output  reg                     rdlvl_dqs_check_ena,
output  reg                     rd_level_dqs_done,
output  reg                     rdlvl_all_dqs_done,
output  reg                     rdlvl_dqs_shift_ena,
output  reg     [2:0]           rdlvl_dqs_phise_shift,
output  reg     [2:0]           rdlvl_shift
);

//Parameter Define
localparam              PHISE_TAPS     = 8;
localparam              PLL_SHIFT_NUM  = 4;
localparam              WIAT_CNT       = 25;
localparam              PLL_BLANK_NUM  = 64;
localparam              TAP_WTH        = clogb2(PHISE_TAPS);
localparam              WIAT_WTH       = clogb2(WIAT_CNT);
localparam              DQS_CHECK_WTH  = clogb2(DQS_CHECK_TIME); 
localparam              PLL_SHIFT_WTH  = clogb2(PLL_SHIFT_NUM); 
localparam              BLANK_NUM_WTH  = clogb2(PLL_BLANK_NUM);
            
localparam              IDLE           = 3'h0;
localparam              RD_DQS_WAIT    = 3'h1;
localparam              RD_DQS_CHECK   = 3'h2;
localparam              PLL_SHIFT      = 3'h3;
localparam              RD_DQS_LOOP    = 3'h4;
localparam              PLL_BLANK      = 3'h5;
localparam              DQS_CHECK_DONE = 3'h6;

//Register Define
reg     [2:0]                   cur_state;
reg     [2:0]                   next_state;
(* async_reg = "true" *)reg     [1:0]                   dqs_bit_sample_r1;
reg     [1:0]                   dqs_bit_sample_r2;
reg     [1:0]                   dqs_bit_sample_r3;
reg     [1:0]                   dqs_bit_sample_r4;
reg     [WIAT_WTH-1:0]          wait_cnt;
reg     [DQS_CHECK_WTH-1:0]     rd_level_dqs_cnt;
reg     [PLL_SHIFT_WTH-1:0]     pll_shift_cnt;
reg     [TAP_WTH-1:0]           rd_level_shift_cnt;
reg     [BLANK_NUM_WTH-1:0]     pll_blank_cnt;
reg     [PHISE_TAPS-1:0]        dqs_dynmic_shift;
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
//Wire Define
wire    [TAP_WTH-1:0]           calibrate_1tmp;
wire    [TAP_WTH-1:0]           calibrate_2tmp;
wire    [TAP_WTH-1:0]           calibrate_3tmp;
wire                            case_1tmp;
wire                            case_2tmp;
wire                            case_3tmp;
wire    [TAP_WTH-1:0]           tap_cnt;  


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
Nm5LHma/iNG5KMPHWzopYhWMqIrCN3ad0ZGkfJ1F1vm22KStzyeJvRq+13oFv/SB
iC/9c1naFPLsMBx1c8IopOIZx2MaRLVpfZ+7bOG+TCh1UKkxFOtcjmMfznMiu9WF
Xk6UxjvBuhB/ym/9rOHhSPbWmmkbf3D/6XSsixZKqw4=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
cgxa5yKl9fVwgreJcBSlkEhWt0mEjKByybXyVyWtzd7Se1uNggyAWFTFC54KbE0C
mN6xFCmEvzO2zHc4eAs+Ad5d6jo2chqrna10NQ8env2N5zEcMOrd0pWgE24t4DdO
MyG3v+h8Y60U8MaTltSwUB545YNO4zLtcz2dBQx3UjM1EYqapL+wpsIt/V2cgTAt
DSoBSzwm1qrW2unbmen5nHR3Z600oLH5ee7A42AIufyhNHv1lOKijhtcTKauFIk+
UYA9/i7tUHF9zoC1HicXpUtM6ZsKKDukkBXkUIQmmBbqMS2vX8ke34U4EO8jrnzM
GrtW4JTGQOBtVih/AIOSjw==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
IA4I8gqxgUnN3ZAa0++M9s8Kp9Gv9IB0PufzPa4DIB03iX93iYUXBhp2/oSO843h
zPRZgAlHbWXmihiFVDUcsoZDHwzHh7t8MNhXlawNjgVsnPUi334jjaogTuqlVdfO
sv2Bfu8z6sE/NcNAubS/sFWjct8nXIpDYeoWjSU0xKc=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
hM1dPd6tcARAwSomSmI84nIhkEo+QYNFiRES6U8/+nwDXMBytqKVcAaqxgagqdq/
P6OkxaMRBgBMUnf3ezRW4OBolW70vtMzcRwkzZ6cO7WtFUbJyvMoPdxs5AVWyDhc
O5Uq5dYGCmx/8zda/X033PFNFnavh3XJmg3juc3siCOC1HXLqVHc3XjpIV8hV0df
7gFlvOxZ8hY0l1d3PAbW6VQPVhvUFFrbFWN/HXt+8p/8wB6/cmXhhyTi0hS/jhPU
ReTP9qFNr3kPczJ9jjRvNIm+SwGl24/qWuQU1Fg0C7UgRH8TD3r48MYU0GUJe+Sf
fs3dL0m2EyQyBy9RbloQqw==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
X9UfcyH821CIQzvKLPloCuWkewjchi/TiXuv7wRM5yKgqZxf2+ViJ9oaCV5HO4ac
ACq/LfmGr5aWcXT8bvEDsIx6UZSSzg/DM1TTQ2IwvwzhJu4Zcocb2bb8c/Fz42vw
kfT4yhXZNeMsdq9TKM55pq8mDLqkbQISp7/1zQ9d6DtneXzdakNuHBjHHoogktlJ
qVH/exoHgrOsPkTKG/pwkT+hzlTTTW3eRsmv7cb2mW4ofKgmm7poJhZLTCxQ54V5
mLWPLCbOcgXHD9K2oa6dhMBduj2iC/Lp9Wt8GP9iNVSWbu6RqBK1bZ2HP6Zqvkyf
RebnKnd5+Hc92mOYkwFIvQ==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=13712)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
