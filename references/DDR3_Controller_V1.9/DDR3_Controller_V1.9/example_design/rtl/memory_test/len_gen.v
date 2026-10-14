//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : len_gen.v
// Version        : 1.4
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 09:34:40
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module len_gen (
//Globle Signals
input                           rstn,
input                           clk,
//User input information
input                           mode_en,
input           [2:0]           len_mode,
input           [7:0]           flen,
//prbs
input           [7:0]           rlen,
//len interface
output  reg     [7:0]           len,
input                           len_ready,
output  reg                     len_valid,
output  reg     [2:0]           r_len_mode,
output  reg     [8:0]           rule_len
);
// Parameter Define 
parameter State_idle  = 4'd0;
parameter State_mode  = 4'd1;
parameter State_rmode = 4'd2;
parameter State_fmode = 4'd3;
parameter State_imode = 4'd4;
parameter State_rule_rmode = 4'd5;
parameter State_rule_imode = 4'd6;
parameter State_nmode = 4'd7;
parameter State_trs   = 4'd8;

// Register Define
reg     [3:0]                   cur_state;
reg     [3:0]                   next_state;
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
IFxBDZwMnb18vr4HWC6H3japTMs9ozvQPvxC3ciEVFP/S4w2QoXFplZFrhKOHrnh
7FgXM+Gt2oKRAlzy7II3ESaO5yjPskXJPJFwRkVvU3J4gtpKMKr4bm4jeNwltgp5
QcLtY0tDdQgyEENnDuQ8i4EJ4y+Y1nJOgBxzRChxpXIAPCrQH9fipLnA9yjUAzkR
xPzn4wQgbXvlA+2RhjiOwezYUaPe45nAyNKkAEBZjWwoMiGZUlhec54nIJeptgBj
/9jG72HhkF0I5M9ANd0WHVQovPWeNOwAokUl2VxbSHrK6+dlA+DEFu9tRVxlBsMq
UX1kZerAzHdOiQfndvs9vg==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
arsUaWOC8coh9HTyvCMZry5Qe6S35U3ZuWOQ95i0q9cWBMSjWhtV65iT9wfNqoZf
yw3K4qbUwIrnspH+XWmnsoI30G72HHIPuzXnSiKru3ho1YeVMqApb6t6EKK9S6WL
Mio2o09A2mTUvmcA5Yv99/cD3W4YLby13QDretiUQiY=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=3952)
`pragma protect data_block
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
R4ZhyTQiC8Xn/0Jn4SzDDA==
`pragma protect end_protected
endmodule
