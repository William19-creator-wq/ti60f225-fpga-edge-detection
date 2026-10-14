//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ui_wrapper.v
// Version        : 1.1
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

`timescale 1 ps / 1 ps

module local_bus_ctl #(
parameter                       TCQ        = 100,
parameter                       CK_RATIO   = 2, 
parameter                       USER_DW    = 256,
parameter                       USER_MW    = 32,
parameter                       BANK_WIDTH = 3,
parameter                       COL_WIDTH  = 12,
parameter                       CWL        = 5,
parameter                       BUF_AW     = 5,
parameter                       RANKS      = 4,
parameter                       RANK_WIDTH = 2,
parameter                       ROW_WIDTH  = 16,
parameter                       LB_BUFF_DEPTH  = 16,
parameter                       ADDR_WIDTH = RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH,
parameter                       MEM_ADDR_ORDER = "BANK_ROW_COLUMN"
)
(

input                           clk, 
input                           rst,   
input                           mc_user_en,  
input           [2:0]           mc_user_cmd,
input           [ADDR_WIDTH-1:0]mc_user_addr, 
output                          mc_user_ready, 

input                           mc_user_wren,   
input           [USER_DW-1:0]   mc_user_wdata,
input           [USER_MW-1:0]   mc_user_mask,
input                           mc_user_end,                                 
output                          mc_user_wrdy,  
   
output reg      [USER_DW-1:0]   mc_user_rd_data,      
output reg                      mc_user_rd_end,       
output reg                      mc_user_rd_valid,      

input           [BUF_AW-1:0]    wr_data_addr, 
input                           wr_data_en,             
input                           wr_data_offset,           
output reg      [USER_DW-1:0]   wr_data,          
output reg      [USER_MW-1:0]   wr_data_mask,     
input           [USER_DW-1:0]   rd_data,           
input           [BUF_AW-1:0]    rd_data_addr, 
input                           rd_data_en,             
input                           rd_data_end,            
input                           rd_data_offset,  

output          [BANK_WIDTH-1:0]mc_bank,                 
output          [2:0]           mc_cmd,                    
output          [COL_WIDTH-1:0] mc_col,                   
output          [BUF_AW-1:0]    mc_data_buf_addr,

output          [RANK_WIDTH-1:0]mc_rank,                           
output          [ROW_WIDTH-1:0] mc_row,                                   
output                          mc_use_addr,  
input                           accept_ns             

  );

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
em8fG8mrW4BZ6ihKw7laTvynK5oNEdJGUD3yLrr6vPPP7lx7g3vx7qiU9KZbBXnE
TJnbGGKE4faWEgVLSb35nxqnItOOOXkjfOS3pHfwAMza39Feq4IdKEuMS0ew0mdD
7j8Ntqn2AUf1gY9kQ8u8drvuy0RbDGSQ0R5KsORGFLw=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
h2cnxmYjSz1nct1J2IYaYbvX00sB+/DwZ51YZoHIllTsL7nBOiERFMPhQxjxfOe0
Cmo34vLWuO1vXpDf/T4hngyVbOXz5s1Ejs8CM9RWcdheHMUJ7mQ05jutJHrYScEG
eyy4dxkK3AsGoWR45LwMwwIuXtGarxLs/3/cTIojgUyopm6OPk5P08UoUGw8Ey/A
/8lFRf2/gNdSuXrdKJ0cmdi3QpR2WlZrL8iwe8fsRMhu0DL9lRFE2tVzfQaroMEP
awDOYDFP4tt8ev1Il+N9qHiajdEVPbVy+8qfykQLs4Xye6sUuRv+wC5yeKWgEwOb
0zgutnszfV9Pxbyt0ld9eA==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
ih4YCzHIojcJv2iQji7Cn6T9O0ruBXal213mF9PaOt/JD8tchCeCqi6EVqtA5sWE
J4wg9U9ZuNA6mxJaoPPwhWfpQhKljVRT9X0wu7c691KR2VIokN12GKHc9FMT4h3E
jNEG7VT0G8u+kSGFSBa43l+lFHNrfrVI+vWU8a8M6M8=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
F6ad/dabHuPyrvQwAN9AdRpCCAEPK1I30xUMN3vKko0OLi1/arHfQDGTPPhMV8rs
qIRQVT20RLnp5dJxly56B2CF9bnUzU+9R/VRv/wf2XZwtUtvgUKHJ3nMQ0dxzy9H
EHsH/iGSGlzMYOgQRSDJxldNXsWX8rasd7ErOl0BQgz0U5blzlrYrLAK22N/V57c
Y/5L/kewT4e+H8OEBYV1zGj16h+pdA0dU5hh72JsOM9j6GtlShducRF72ntm2Vtk
AMkFeemcb0oYc0Mn4df15m4ogOxxn9EkV3Nah5Vu38HsB6aBrqjhOz8gVzJ79pI5
X64AX7j3cGAKnQVFmaIYYA==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
YQgGo0U3H9BdTjGP/nAVYdxtRwkcLR8d+kIVKlQTYiPBHVeEXXTOwXos5sV0jXSf
UDRAEwdv3jVDZKPBseFk7QaTFTKFMMlEkdiD9bzRXFgu87kFpT19JINtX71/cw6B
inTm0yu6UqvJ42fcvfn5DCc7Ds7p7avWqnUX9RRjV/OR5j2QfkaUQrKBdH/vrKB3
cmZ+sW1Abzv1v8/cnllX/5jUJ4uFRuzzWI0lP1LEilyoH14QTW8RXhNEn9MTd+Qd
/WNZidc6IAZpVGxBW0dw2uTFjV8VmsFqtwL+mua5EE+z8/spSXxHuUr91qjNzIjt
JdC2y/cuJ7j3lHAQpAqMbQ==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=8768)
`pragma protect data_block
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
`pragma protect end_protected
endmodule
