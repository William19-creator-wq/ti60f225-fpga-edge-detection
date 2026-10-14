//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : axi4_onlym_gen.v
// Version        : 1.4
// Date Created   : 2023-03-15 10:37:59
// Last Modified  : 2023-05-30 15:36:01
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module axi4_onlym_gen#(
parameter                       AXI_DW = 32,
parameter                       AXI_AW = 32
)
(
//Globle Signals
input                           rstn,
input                           clk,
input           [1:0]           r_axi_mode,//01b:Write Only; 10b:Read Only;
input           [AXI_AW-1:0]    addr,
input           [7:0]           len,
input           [AXI_DW-1:0]    data,
input                           addr_valid,
//gen ready
output  wire                    addr_ready,
output  wire                    len_ready,
output  wire                    data_ready,
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
output  wire                    m_axi_bready,
//Master AXI4 Read Bus Interface
output  wire    [7:0]           m_axi_arid,
output  wire    [AXI_AW-1:0]    m_axi_araddr,
output  wire    [7:0]           m_axi_arlen,
output  wire    [2:0]           m_axi_arsize,
output  wire    [1:0]           m_axi_arburst,
output  wire                    m_axi_arlock,
output  wire    [3:0]           m_axi_arcache,
output  wire    [2:0]           m_axi_arprot,
output  reg                     m_axi_arvalid,
input                           m_axi_arready,
input           [7:0]           m_axi_rid,
input           [AXI_DW-1:0]    m_axi_rdata,
input           [1:0]           m_axi_rresp,
input                           m_axi_rlast,
input                           m_axi_rvalid,
output  wire                    m_axi_rready
);

// Prameter Define
parameter AXSIZE = AXI_DW/8;
parameter AXSIZE_WTH = $clog2(AXSIZE);

// Register Define
reg     [7:0]                   burst_cnt;
reg                             burst_wait;
reg                             waddr_wait;
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
nRd8Vfahwwl87t0VKNTR08SBUk3fZEwMDd+wEGujWCKV66aHUFn5CubawzM/5j1D
h2PAqYRLol+Z9xLrYBgpDknZI6MzFQrP6mziuVVDcFvPeF9IY4bnMEjG8bH7BOLm
cOPrfPaulhmZlGEnJuXRXweZnZdYs7pvsk3JZg9D78JHgo/fT1yOVW/rTM9Hoqhx
lyNFL2loBRzxySxH/f7pT11RSi7e0zmFDSxEGUdoaFZam+ocZg0gesLKRMODLyeC
SaMiwvSYax8z17wbBz1T2su0LySofdbo7mYM1IhKvGDcrnSiFujRBh4fQYiAIJNj
+gKzrCLL1ngtXFNPpRaigA==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
JCx7mJsORrN5vgOtlnrvCW8d7B5qeZajK3bEhVD5ZzMnUNEoSeHl4vMstzzRaQtX
Be34TpiIkBJtSMVXgZf88CgNvCJt10Z2QrH9ObKS0DKTlLTW7Psdawr6BI8seomP
JGOyfZuBQewgZqjhaEUhjquSaVtgxdOjyrT27OFJJUo=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=4576)
`pragma protect data_block
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
n6gr6yXPyJTamabiTL8ZMg==
`pragma protect end_protected
endmodule
