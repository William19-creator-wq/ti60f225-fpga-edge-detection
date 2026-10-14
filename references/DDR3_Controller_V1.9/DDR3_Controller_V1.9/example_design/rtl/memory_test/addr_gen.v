//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : addr_gen.v
// Version        : 1.4
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 15:35:06
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module addr_gen#(
parameter                       AXI_DW    = 32,
parameter                       AXI_AW    = 32,
parameter                       MEM_AW    = 20
)
(
input                           rstn,
input                           clk,
//User input information
input                           mode_en,
input           [1:0]           addr_mode,//00,imode;01,fmode;10,rmode;
input           [1:0]           axi_mode,//01:Write Only; 10:Read Only; 00:Read and Write;
input           [AXI_AW-1:0]    saddr,
input           [AXI_AW-1:0]    faddr,
//prbs
input           [MEM_AW-1:0]    raddr,
//len interface
input           [7:0]           len,
input           [7:0]           rlen,
input           [7:0]           flen,
input           [8:0]           rule_len,
input           [2:0]           r_len_mode,
//fifo empty
input                           u1_emptyo,
input                           u2_emptyo,
input                           u3_emptyo,
input                           u4_emptyo,
//addr interface
output  reg     [AXI_AW-1:0]    addr,
input                           addr_ready,
output  reg                     addr_valid,
output  reg     [1:0]           r_axi_mode,
output  reg     [1:0]           r_addr_mode
);
// Parameter Define 
parameter State_idle  = 3'd0;
parameter State_mode  = 3'd1;
parameter State_rmode = 3'd2;
parameter State_fmode = 3'd3;
parameter State_imode = 3'd4;
parameter State_nmode = 3'd5;
parameter State_trs   = 3'd6;
parameter State_wait  = 3'd7;
parameter AXISIZE = AXI_DW/8;
parameter AXSIZE_WTH = $clog2(AXISIZE);
// Register Define
reg     [2:0]                   cur_state;
reg     [2:0]                   next_state;
// Wire Define

//Encryption begin
`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="http://ipencrypter.com Version: 20.0.8"
`pragma protect author="author-a"
`pragma protect author_info="author-a-details"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
RtvGwIS48aOJktQojbpfMOIgil4lIaqXAV0nLa9ykD4wXMuKOnDDoLtucbi612E2
nHYrxCiboo9hyLTMBFW9iFP8LG4nmySpyKJYR0PUVlzqGmOA4iVT8azJIxBcy82q
ztb9hhqjP/gZWchATguvu20Yuc3ytESS98B2SpkIzyd96G9Ti1SvijeDWrIiThpr
7gOfskWRfB0tRC6EW7lsj2kh4iqMqwiVjn4+RY/W1XtuMSC4XPAFjudOlMEKtw7d
9GPSFyk2TW/SHgcdinOc23VdU0Yy20SevjiJfDP86947BcWNEtJEUeGvvEBPbpng
ZPnushOC5WRdxLbv18yAuw==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
Fye/bl/g2NbzfdM05Z5UatJB4seislc2rn23pA9L3PLktFR867oDf1cw1KOlZcPG
fD17jlHUDdjd4LC+8HV0tdVBRLtZ8w+OfpAq8RJybDj1hFPh63QFbjgCgMkygsbx
u3/z7CB8p1Xv4W70Vf4s4vVoSMi/7mPhw66ULkjQuZc=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=4864)
`pragma protect data_block
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
oS7+XiAVQB8JuH8cZYNnoA==
`pragma protect end_protected
endmodule
