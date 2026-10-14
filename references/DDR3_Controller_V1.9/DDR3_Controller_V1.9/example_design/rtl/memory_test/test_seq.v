//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : test_seq.v
// Version        : 1.2
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 15:36:20
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module test_seq#(
parameter                       AXI_DW    = 32,
parameter                       AXI_AW    = 32,
parameter                       MEM_AW    = 20
)
(
//Globle Signals
input                           rstn,
input                           clk,
//User input information
input                           mode_en,
input           [1:0]           addr_mode,
input           [1:0]           axi_mode,
input           [AXI_AW-1:0]    saddr,
input           [AXI_AW-1:0]    faddr,
input           [1:0]           data_mode,
input           [AXI_DW-1:0]    fdata,
input           [2:0]           len_mode,
input           [7:0]           flen,
//fifo empty
input                           u1_emptyo,
input                           u2_emptyo,
input                           u3_emptyo,
input                           u4_emptyo,
//prbs
input           [MEM_AW-1:0]    raddr,
input           [AXI_DW-1:0]    rdata,
input           [7:0]           rlen,
//seq interface
output  wire    [AXI_AW-1:0]    addr,
input                           addr_ready,
output  wire                    addr_valid,
output  wire    [1:0]           r_addr_mode,
output  wire    [1:0]           r_axi_mode,
output  wire    [AXI_DW-1:0]    data,
input                           data_ready,
output  wire                    data_valid,
output  wire    [7:0]           len,
input                           len_ready,
output  wire                    len_valid
);

// Parameter Define 

// Register Define

// Wire Define
wire    [2:0]                   r_len_mode;
wire    [8:0]                   rule_len;
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
NusZEk1RNS5isFaXiEmudcS3GrBoOLALvvbiBBCr11tR8CzbuUFdorZ1iiQ2hFHH
IvXu22k9uJwr7nW5oAfomyP/vfifjCzQIQJTZQOD+L8VjY+b/c0FOrPTy/jzAllz
mob1Hib2LJs71PIW6+ypI0s02fWF+UQr+mwc8Of4kx3ditglXPJKqmhhRsVHVnjy
4kiJyImP5vH7g8Xj4YFzb8oJH9ywLo1fFYhgbg9tDlhFYVFSjx6q8snQAxOt3ayR
HU7a1e61edBohSwTU7kfN4LKK0bCr1zjFkENEHWGUvJCce3i/8wPXLaNX/NWEQ/Z
YSY04X3sH4iJ18gRHSzJ8g==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
AQLnqpaE29aE7Xtc7WRbcQ/mXdhTDDHv74doddnOBixQMrZGOSeVLFVe5PNbTQeJ
EfEMsnwM8Oqa9TrlulysggyiBN7ulVRmAURL7rlitFnG5ClicjW4g53MCFaoWGQp
el6LpGDlzJHCbyx4rDjI4JOPwjVCnTd2JH6bewe2SV8=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=4128)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
