//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : wr_drive.v
// Version        : 1.4
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 15:35:30
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module wr_drive#(
parameter                       AXI_DW = 32,
parameter                       AXI_AW = 32
)
(
//Globle Signals
input                           rstn,
input                           clk,
//axi work mode
input           [1:0]           r_axi_mode,
//seq interface
input           [AXI_AW-1:0]    addr,
output  wire                    addr_ready,
input                           addr_valid,
input           [1:0]           r_addr_mode,
input           [AXI_DW-1:0]    data,
output  wire                    data_ready,
input                           data_valid,
input           [7:0]           len,
output  wire                    len_ready,
input                           len_valid,
//check interface
input                           read_end,
//data fifo interface
output  wire                    u1_wrreq,
input                           u1_full,
output  wire    [AXI_DW-1:0]    u1_data,
//addr+len fifo interface
output  wire                    u2_wrreq,
input                           u2_full,
output  wire    [AXI_AW+7:0]    u2_data,
input           [AXI_AW-1:0]    u2_q,
input                           u2_empty,
//bresp fifo interface
output  wire                    u4_wrreq,
input                           u4_full,
output  wire    [1:0]           u4_data,
//Master AXI4 Write Bus Interface
output  wire    [7:0]           m_axi_awid,
output  wire    [AXI_AW-1:0]    m_axi_awaddr,
output  wire    [7:0]           m_axi_awlen,
output  wire    [2:0]           m_axi_awsize,
output  wire    [1:0]           m_axi_awburst,
output  wire                    m_axi_awlock,
output  wire    [3:0]           m_axi_awcache,
output  wire    [2:0]           m_axi_awprot,
output  reg                     m_axi_awvalid,
input                           m_axi_awready,
output  wire    [AXI_DW-1:0]    m_axi_wdata,
output  wire    [AXI_DW/8-1:0]  m_axi_wstrb,
output  reg                     m_axi_wlast,
output  reg                     m_axi_wvalid,
input                           m_axi_wready,
input           [7:0]           m_axi_bid,
input           [1:0]           m_axi_bresp,
input                           m_axi_bvalid,
output  wire                    m_axi_bready
);

// Parameter Define 
parameter AXSIZE     = AXI_DW/8;
parameter AXSIZE_WTH = $clog2(AXSIZE);

// Register Define
reg     [7:0]                   burst_cnt;
reg                             waddr_wait;
reg                             burst_wait;
reg     [7:0]                   r_len;
reg     [AXI_AW-1:0]            r_addr;

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
CXU+AkncE8YergMF83zmnxCduZG/2y7Feq9QGKQIlzfC5XGPI5rW6epE/LfGS1KP
5rsupnhtxtPK5v/aXIa8VsTneaCoNLpoYZCQV4+btQaav/pj2L1GdzZleBwH+uxw
FENjgE8BZGlEcTShaFn1M+S/mL3riLJtovhB/t975wxNoFTlxwfv/h3hF8OajiO/
oPmyy35sAIAzLKqmyHA1rbicqYR/9LExrsOmuzTfowkbPHAPIP5THBHO82WOLvG/
000mmFrLgeQm0vKQfsSoUTWB4w0Y587e0n3UaKpQ1VzVcLSs+TZ2HklkB07QO2Rg
yZheB2ngV1Zdd1QQW9E2kg==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
GBhgVlUB1llNplY2iXD6xqqjIubNVOkTcA04xpQkXadhE2GTxTx6LbzbWgmzZujL
zctquhZmpu4vidIRzLusFYmgEFL90JpyRSQnMRcxjACHNKWKzMrM1WLpXoMhBFcG
AYXvwWJsC8Av/xaYhAX94/NeaF/B1cy3KTlxa2iArp0=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=7344)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
