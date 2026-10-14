//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : data_gen.v
// Version        : 1.4
// Date Created   : 2023-03-06 10:37:59
// Last Modified  : 2023-05-30 15:36:43
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`timescale 1 ns / 1 ns
module data_gen#(
parameter                       AXI_DW = 32
)
(
//Globle Signals
input                           rstn,
input                           clk,
//User input information
input                           mode_en,
input           [1:0]           data_mode,
input           [AXI_DW-1:0]    fdata,
//prbs
input           [AXI_DW-1:0]    rdata,
//data interface
output  reg     [AXI_DW-1:0]    data,
input                           data_ready,
output  reg                     data_valid
);
// Parameter Define 
parameter State_idle  = 3'd0;
parameter State_mode  = 3'd1;
parameter State_rmode = 3'd2;
parameter State_fmode = 3'd3;
parameter State_imode = 3'd4;
parameter State_nmode = 3'd5;
parameter State_trs   = 3'd6;
parameter AXISIZE = AXI_DW/8;
// Register Define
reg     [2:0]                   cur_state;
reg     [2:0]                   next_state;
reg     [1:0]                   r_data_mode;
reg     [7:0]                   idata;

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
HG9mbd0DaU6x4WEVoOyVXTyd8tyVJjEBf1XpRsynSscXuLgu3YZ1Xj8n6sjYWQGt
Z9AbNUOD3NXlA/UyPRJ0OVkRyAtH7sNhIcb6f5ngn591lSaehbF94Pq1TDoNZ5Wb
K3nPJPs9BN/p1ilv9FXqBFhRR0S86elaQR9/HMkgzb10mePWP7zT1so8gfoZ/tK5
v8fXDHSLykn1ZziFmlL03ss5JGPdc2C2IksV06Kqnm3UzOkBYlPvg4keljyWQFhC
rQtJaAjffDnCYUrzPcfE3xIgIBogZBXc0HMzktiB/AFD7GNvNm2FvbJhgurwt/EH
u7tFHC6bMKqo5DbRvxvQMQ==
`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
mPDdc59Ocd8sysYXyQlHBqMVnKHPQVnYR39NGu0L6yT12LV4gYfv6boqQSMgcuNk
EJiIGvCUnrA7+xMQ9tGgsiaqc5f2uwMEeXFWTHIizUh8Dy+VgGh7DCWVrWePaRlA
eH6z/j4QtcihLPujsanT3JKA5bzXc6apAlXYqun/2ko=
`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=3200)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
