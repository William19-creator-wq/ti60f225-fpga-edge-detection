//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : memory_test.v
// Version        : 1.5
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-09-20 15:36:30
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module memory_test#(
parameter                       AXI_DW = 32,//axi data width
parameter                       AXI_AW = 32,//axi addr width
parameter                       MEM_AW = 32,//axi saddr to (saddr + (2**MEN_AW - 1)) address space;recommend axi addr width 
parameter                       DDR_CLK_PERIOD  = 32'd800_000_000,
parameter                       AXI_CLK_PERIOD  = 32'd100_000_000,
parameter                       DDR_DATA_WIDTH  = 32
)                                                      
(
//Globle Signals
input                           rstn,
input                           clk,
//User input information
input                           mode_en,//0:stop;1:work
input           [1:0]           addr_mode,//00:imode;01:fmode;10:rmode;
input           [1:0]           axi_mode,//01:Write Only; 10:Read Only; 00:Read and Write;
input           [AXI_AW-1:0]    saddr,//start addr
input           [AXI_AW-1:0]    faddr,//fixed addr
input           [1:0]           data_mode,//00:imode;01:fmode;10:rmode;
input           [AXI_DW-1:0]    fdata,//fixed data
input           [2:0]           len_mode,//00:imode;01:fmode;10:rmode;
input           [7:0]           flen,//fixed len
//Master AXI4 Write Bus Interface
output  wire    [7:0]           m_axi_awid,
output  wire    [AXI_AW-1:0]    m_axi_awaddr,
output  wire    [7:0]           m_axi_awlen,
output  wire    [2:0]           m_axi_awsize,
output  wire    [1:0]           m_axi_awburst,
output  wire                    m_axi_awlock,
output  wire    [3:0]           m_axi_awcache,
output  wire    [2:0]           m_axi_awprot,
output  wire                    m_axi_awvalid,
input                           m_axi_awready,
output  wire    [AXI_DW-1:0]    m_axi_wdata,
output  wire    [AXI_DW/8-1:0]  m_axi_wstrb,
output  wire                    m_axi_wlast,
output  wire                    m_axi_wvalid,
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
output  wire                    m_axi_arvalid,
input                           m_axi_arready,
input           [7:0]           m_axi_rid,
input           [AXI_DW-1:0]    m_axi_rdata,
input           [1:0]           m_axi_rresp,
input                           m_axi_rlast,
input                           m_axi_rvalid,
output  wire                    m_axi_rready,
// error informaton interface
output  wire                    error,
output  wire    [15:0]          err_cnt,
output  wire    [AXI_AW-1:0]    err_addr,
output  wire    [7:0]           err_position,
output  wire    [AXI_DW-1:0]    ref_data,
output  wire    [AXI_DW-1:0]    err_data,

//ddrtest efficiency statistic
input           StatiClr  , //(I)Staistics Couter Clear
output  [23:0]  TestTime  , //(O)Test Time      
output  [47:0]  OpTotCyc  , //(O)Total Operate Cycle Counter
output  [47:0]  OpActCyc  , //(O)Actual Operate Cycle Counter
output  [ 9:0]  OpEffic   , //(O)Operate Efficiency
output  [ 9:0]  RdOpEffic , //(O)Read Operate Efficiency
output  [ 9:0]  WrOpEffic , //(O)Write Operate Efficiency
output  [15:0]  BandWidth , //(O)BandWidth
output  [9:0]   WrPeriMin , //Write Minimum Period For One Burst
output  [9:0]   WrPeriAvg , //Write Average Period For One Burst
output  [9:0]   WrPeriMax , //Write maximum Period For One Burst
output  [9:0]   RdPeriMin , //Read Minimum Period For One Burst
output  [9:0]   RdPeriAvg , //Read Average Period For One Burst
output  [9:0]   RdPeriMax , //Read maximum Period For One Burst
output          TimeOut    //(O)TimeOut
);

// Prameter Define

// Register Define

// Wire Define
//seq interface
wire    [AXI_AW-1:0]            addr;
wire                            addr_ready;
wire                            o_addr_ready;
wire                            rw_addr_ready;
wire                            addr_valid;
wire    [1:0]                   r_addr_mode;
wire    [1:0]                   r_axi_mode;
wire    [AXI_DW-1:0]            data;
wire                            data_ready;
wire                            o_data_ready;
wire                            rw_data_ready;
wire                            data_valid;
wire    [7:0]                   len;
wire                            len_ready;
wire                            o_len_ready;
wire                            rw_len_ready;
wire                            len_valid;
//fifo empty
wire                            u1_emptyo; 
wire                            u2_emptyo;
wire                            u3_emptyo;
wire                            u4_emptyo;
//prbs interface
wire    [MEM_AW-1:0]            raddr;
wire    [7:0]                   rlen;
wire    [AXI_DW-1:0]            rdata;
//Master AXI4 RW Write Bus Interface
wire    [7:0]                   rw_axi_awid;
wire    [AXI_AW-1:0]            rw_axi_awaddr;
wire    [7:0]                   rw_axi_awlen;
wire    [2:0]                   rw_axi_awsize;
wire    [1:0]                   rw_axi_awburst;
wire                            rw_axi_awlock;
wire    [3:0]                   rw_axi_awcache;
wire    [2:0]                   rw_axi_awprot;
wire                            rw_axi_awvalid;
wire    [AXI_DW-1:0]            rw_axi_wdata;
wire    [AXI_DW/8-1:0]          rw_axi_wstrb;
wire                            rw_axi_wlast;
wire                            rw_axi_wvalid;
wire                            rw_axi_bready;
//Master AXI4 RW Read Bus Interface
wire    [7:0]                   rw_axi_arid;
wire    [AXI_AW-1:0]            rw_axi_araddr;
wire    [7:0]                   rw_axi_arlen;
wire    [2:0]                   rw_axi_arsize;
wire    [1:0]                   rw_axi_arburst;
wire                            rw_axi_arlock;
wire    [3:0]                   rw_axi_arcache;
wire    [2:0]                   rw_axi_arprot;
wire                            rw_axi_arvalid;
wire                            rw_axi_rready;
//Master AXI4 Only Write Bus Interface
wire    [7:0]                   o_axi_awid;
wire    [AXI_AW-1:0]            o_axi_awaddr;
wire    [7:0]                   o_axi_awlen;
wire    [2:0]                   o_axi_awsize;
wire    [1:0]                   o_axi_awburst;
wire                            o_axi_awlock;
wire    [3:0]                   o_axi_awcache;
wire    [2:0]                   o_axi_awprot;
wire                            o_axi_awvalid;
wire    [AXI_DW-1:0]            o_axi_wdata;
wire    [AXI_DW/8-1:0]          o_axi_wstrb;
wire                            o_axi_wlast;
wire                            o_axi_wvalid;
wire                            o_axi_bready;
//Master AXI4 Only Read Bus Interface
wire    [7:0]                   o_axi_arid;
wire    [AXI_AW-1:0]            o_axi_araddr;
wire    [7:0]                   o_axi_arlen;
wire    [2:0]                   o_axi_arsize;
wire    [1:0]                   o_axi_arburst;
wire                            o_axi_arlock;
wire    [3:0]                   o_axi_arcache;
wire    [2:0]                   o_axi_arprot;
wire                            o_axi_arvalid;
wire                            o_axi_rready;

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
l4qXnH4gVCYOzS+9xsHPlvdCIo/YsgvB3+kXgz4c6x2NgNCF6XM9qgT1eLc4sLsV
zvxFtWLTIhVWB05VkdDeJnfPNc17oFneHsdY0OiMFsQvA3jo+kik9bu1LeIzi86L
lpst2KNtnrartwQYM+s2UezAVQHIkmxfHBKkb4gNXMHq6TAC2M1atCfr5Mrbf5JT
f6UAb1YWsHC8Im58T1xuf/xVob4v6xESRnt+jgkwA82oEmqSz4LOSIkWmklKegPW
b1/pL7D9+eVbzbGPvaWgowWxV2mO1M9mKue6hKm8WnuJfKzqLVg3VFjjrOQs6cLc
WiDrBc9wB7QmekQRk4+eXA==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
Gl+t3PDbvOyL3Rv6rKvkDlP0seLXV4f58V8mzwGF7fRG6XOFqY8k9yGbGeyhtnkm
KY7YEd9lKHYxqTGfwwqHjLY2wQjRFmGEo4NV4Plbk/6hkYOrb3cLBYmd61tYDPlK
KX19GAZfi+KdsnmQdRn1DOY+dGNfLMBVutiImDXWQDU=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=18720)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
