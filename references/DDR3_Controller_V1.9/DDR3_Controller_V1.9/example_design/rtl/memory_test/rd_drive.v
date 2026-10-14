//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : rd_drive.v
// Version        : 1.4
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 15:35:41
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module rd_drive#(
parameter                       AXI_DW = 32,    
parameter                       AXI_AW = 32
)    
(
//Globle Signals
input                           rstn,
input                           clk,
input           [1:0]           r_axi_mode,
//addr fifo interface 
output  wire                    u2_rdreq,
input           [AXI_AW+7:0]    u2_q,
input                           u2_empty,
//bresp fifo interface 
output  wire                    u4_rdreq,
input           [1:0]           u4_q,
input                           u4_empty,
//Master AXI4 Read Bus Interface
output  wire    [7:0]           m_axi_arid,
output  reg     [AXI_AW-1:0]    m_axi_araddr,
output  reg     [7:0]           m_axi_arlen,
output  wire    [2:0]           m_axi_arsize,
output  wire    [1:0]           m_axi_arburst,
output  wire                    m_axi_arlock,
output  wire    [3:0]           m_axi_arcache,
output  wire    [2:0]           m_axi_arprot,
output  reg                     m_axi_arvalid,
input                           m_axi_arready
);
// Parameter Define
parameter AXSIZE     = AXI_DW/8;
parameter AXSIZE_WTH = $clog2(AXSIZE);

// Register Define

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
BsvQFTh4pqT7MXLoPTwxOLhGfxu1cmj5tfodY3CrK89z5n1A1LYMaC8fpfiY4Tye
U/IDP/lNcUgiPezhox/TtvJXTdUtrABC6UKKqj64uv1V32L+upaz3Ndnxlx58HzN
llo91oGu0nn+7WHy7QeAuGpkGjGl1LtiiJWiBl+uvTrJ0cW4zRfpg4iknr5Bn8Uh
SpPLQZ+sHoHPBFL2+fxCLTO4pstePc645m5EcZPQ3V30SvYKhd2/yXOJzJlgJsuQ
SLuCsA8GpQDASC50db1WleAGFgpIYQKj3NH7il5sLh5rd3J3zk05BqbY69yzhz1f
OAYNBQq/zbH+nJa9GKiIjg==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
QqS0ZbqdDTad4nXK4AzBIpHncIUQGNBVSce2LZ0JJG/YnL5iFwfdoCk+uzp5d8DF
Xe//yrc1wRF6hsQQNcLJR8qT64Aoa6yj6sVAiPJ+QAn4rNEGhUvQ/DVKt0QKtqlR
x9uOar4m649PzjnlDH93ymPPMfdkJPRqRnGxISO5/Oc=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=1568)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
