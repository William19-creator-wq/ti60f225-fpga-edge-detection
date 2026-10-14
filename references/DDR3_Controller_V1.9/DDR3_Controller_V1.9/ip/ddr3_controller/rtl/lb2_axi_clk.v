//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : lb2_axi_clk.v
// Version        : 1.1
// Date Created   : 2023-04-23 10:37:59
// Last Modified  : 2023-04-23 10:37:59
// Abstract       : ---
//
//Copyright (c) 2020-2023 Elitestek,Inc. All Rights Reserved.
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/


module lb2_axi_clk #(
parameter                       USER_DW    = 256,
parameter                       USER_MW    = 32,
parameter                       BANK_WIDTH = 3,
parameter                       COL_WIDTH  = 12,
parameter                       RANK_WIDTH = 2,
parameter                       ROW_WIDTH  = 16,
parameter                       ADDR_WIDTH = RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH
)
(
input                           axi_clk, 
input                           core_clk, 
input                           rstn,   
input                           axi_rstn,   
input                           axi_user_en,  
input           [2:0]           axi_user_cmd,
input           [ADDR_WIDTH-1:0]axi_user_addr, 
output                          axi_user_ready, 

input                           axi_user_wren,   
input           [USER_DW-1:0]   axi_user_wdata,
input           [USER_MW-1:0]   axi_user_mask,
input                           axi_user_end,                                 
output                          axi_user_wrdy,  
   
output          [USER_DW-1:0]   axi_user_rd_data,      
output                          axi_user_rd_end,       
output                          axi_user_rd_valid, 

//----------------local bus----------------//
output                          lb_user_en,  
output          [2:0]           lb_user_cmd,
output          [ADDR_WIDTH-1:0]lb_user_addr, 
input                           lb_user_ready, 

output                          lb_user_wren,   
output          [USER_DW-1:0]   lb_user_wdata,
output          [USER_MW-1:0]   lb_user_mask,
output                          lb_user_end,                                 
input                           lb_user_wrdy,  
   
input           [USER_DW-1:0]   lb_user_rd_data,      
input                           lb_user_rd_end,       
input                           lb_user_rd_valid

);
//Parameter Define

//Register Define


//Wire Define
wire                            u1_wrreq;
wire    [ADDR_WIDTH+2:0]        u1_data;
wire                            u1_almfull;
wire                            u1_full;
wire                            u1_progfull;
wire                            u1_empty;
wire                            u1_rdreq;
wire    [ADDR_WIDTH+2:0]        u1_q;

wire                            u2_wrreq;
wire    [USER_DW+USER_MW:0]     u2_data;
wire    [USER_DW+USER_MW:0]     u2_q;
wire                            u2_almfull;
wire                            u2_full;
wire                            u2_empty;
wire                            u2_rdreq;

wire                            u3_wrreq;
wire    [USER_DW:0]             u3_data;
wire    [USER_DW:0]             u3_q;
wire                            u3_almfull;
wire                            u3_full;
wire                            u3_empty;
wire                            u3_rdreq;

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
X5ZGV3NBdzQ7P2V6ZdMIBxwXAh0Psd0OKmQVVH+KuSMKc7s1dTj07NR+J93gBZUu
pcU47SjbQFwVH8DMw26AKfUJSob/F+Z48+UzFMub9IUybI4lhX9RJs6WRhOPgeS9
qG7/Ez1p8U5JydXKnkduuuQC2BFuoQpjUWO4A1E4D5c=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
tivKH3Dd6ly7gI9IMtzguxlKNcI6iDF9zwF4zF4Zae5Xt/+IYMLT7HrZQFpdcIUC
mD2KADK2KIuS+v4ETZv4eZMYbHHS5Z3HOcAj6RwxTvR2FqNS+GlQDNiaOVzPwoLv
0U4N3t4L/AXyfPORUapOyuIqYuNl3Z0/pmnlkwB8h8E9xHZN+vkfVofdauMsqrT0
WhZjP8BztOs34MAYcfS67y6nNe9hmoArKAJk1NYYo5Esjnw3VLr1ld0mdLTvofBi
/Y43nsCNYnyhl0WnuTW6Ynb2KPZZvB/NLu6sbS+FhTf1J4O0kIwTyqVJDvhu6qbA
yjbAxAxTQhgIJHVd0Kq3lg==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
rr0cogqVtre5JUxAQuWQQix/nJgNWRtaZlgwCF2odZ9pQqTs+b1OQPQw4iqWAxFr
BvdjjIqMlKzl4BJGAYpSDrB00goj3w82/y6KwyOFJsfeOl+qVuFGixr/uNEpprdb
Qf3uRlWeL1Tfwv4CJ8SI9PTGh88aIcyD/pL0cm3eH0s=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
Tw5qfsd37iUYw8J6PjZO/KPeoeDqS04fwuFkSW4TdDdBG6gMDwvAV3qHrNlq/JYg
2Ms8lZD9O5MoxWF1WYZlFe/SYrBoEacfUTsaXqxEJtokfsvLDVkfI042j0YO2Bcv
3nEj4onqFm0m6zT4SZXNTVRfLvj1DqaezgMhvy6Gk0NYCNeJmZIYzhduRA7rHQ1T
VY0N5ZgnHxj+nfIpudhKuwoP/S9ln/ZAXLPKWgt7xpfUpkccNOYUdKkukRACzdLK
W78w3HgbeX5BWkfEzjr+WNm8o+/ggGpUOzTJmOhGOAyF+fNIkJYTDAmprl08nbnC
CkxZJSdrdxXPgVK7MCWaCg==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
VZ4uI/CyenupXC7zBOCe4aUtA4/Bt8abKHg1vK/jdn44xQ5W0ozgfC6vOq7SlMrF
+xdzVAjHGk4mONCO9NnipiQwXwKx9ipuQCR9616iMVIOHhTs53VX09S02M9PWlds
a/rb5llbM0DsV6AiszL6Txa7RsjUNwcAnrTDZAGgs73BuzS8w1Q5r9IRaOIgjKHX
YjPKW+/OC4Sba7jm9iONw3FhN2X+Y6CJE/2jA+jk4+s7JQGjL3dZt3AaySiV+iLP
arAQgqT7YT/jvOwlmWoW7ar++85gFy0IQRsCo+nyiqx976RZOxDN0/aMUy3VGipb
Asf0d37/lNh6e7y+DCc+eQ==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=8016)
`pragma protect data_block
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
`pragma protect end_protected
endmodule



