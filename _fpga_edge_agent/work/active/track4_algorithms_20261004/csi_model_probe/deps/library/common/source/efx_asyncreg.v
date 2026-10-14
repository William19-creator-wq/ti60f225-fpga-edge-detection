
// synopsys translate_off
`timescale 1 ns / 1 ps													
// synopsys translate_on

module `IP_MODULE_NAME(efx_asyncreg) #(
    parameter ASYNC_STAGE = 2,
    parameter WIDTH = 4,
    parameter ACTIVE_LOW = 1, // 0 - Active high reset, 1 - Active low reset
    parameter RST_VALUE = 0,
    parameter OFF_ASSERTION = 0 // 1 = Turn off PULSE_WIDTH_CHK assertion for a particular instance 
) (
    input  wire             clk,
    input  wire             reset_n,
    input  wire [WIDTH-1:0] d_i,
    output wire [WIDTH-1:0] d_o
);










`pragma protect begin_protected
`pragma protect version = 1
`pragma protect author = "author-a" , author_info = "author-a-details"
`pragma protect encrypt_agent = "QuestaSim" , encrypt_agent_info = "2023.4"
`pragma protect key_keyowner = "Efinix Inc." , key_keyname = "EFX_K01"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
IjzmeF2ACtI8q/MHPcSQakfCyuQSUgg747Z3U+BWZdCStFbqF/Rhg0VPl8JT+91V
o/8Ohsiw6GnpSIX69XazqGYmhEjb+W7W2ngBYentEXdSyzUYvEbr8i71cL04f1fE
El78uYgSvjFwoDyocXOVYk8JA0v7y6WnabkL02lAqASKGQK55nzfKeUVbJHKHjAY
kIT3Nf7JWK2NVVymI1Zs5QttwrNgKBSqoiPvmy4+16bTQMx4R205Bb4rT1MqSqIc
/5U5/Z1e1tZzOqoEyhfcMMKW0emdBIdByNvteK05ZATt11Uzj2M/Vn1r9KmYd0h1
uYJaS5tuGEuFInBHa7oO8g==
`pragma protect key_keyowner = "Cadence Design Systems." , key_keyname = "CDS_RSA_KEY_VER_2"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
ABJo/BvEH9XbZrt+xPOQ2C7yeLcnebDlRELbHyCdXeeNkZRVZ9m0ie+1HufS/I+3
fC63lnVTenVdf9s4tm1RLd5VBkmFb37ikgaESy2aRKWsdLG6x2OyuODoMDRCjYUa
rxhnwLWh5E55yR3XVZgM2k7/NPP2cTL7iOSCjH4No38siNjs4Fapyc4FFq0TOsQq
PMqsZ5jgmM+ZT8cil0wMt5tpdEOwvchbe1GcZLIhcIFLD/Gb2XtP0Q0QkOlNzuiL
DNyobLTjDkV5si+/23Ng2E7tDq+SX+vJP4ciI63kXtsmQdn1ff2Y64ibNXJtpu/w
K3OoKmk3zFeArSsql8B4/Q==
`pragma protect key_keyowner = "Synopsys" , key_keyname = "SNPS-VCS-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 128 )
`pragma protect key_block
RAoMYYsrw2j05cvQ8NR0lCh+Ia/OGVfdwZqq0pwIkgDzO3Z7ol96oQmQzFfIQY/M
GzEOFdYJTfjnxPvhSPxT1tpq2Fgx6PbC2FMWFtN6/TrG/s01ifIWIZ9Wrfo8Q01l
6XTAESHR1htrOOx6AiDHAQLOlBb0zgfZjayGJBRX7FI=
`pragma protect key_keyowner = "Aldec" , key_keyname = "ALDEC15_001"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
YclPuIbYLW/ftZYybucr9ooblGFkJDcdUWf6kCJBGKpIRjItUB3LdSwcREekRWqf
RGiSRFoyrOTiScT06zZ4fkm+PEKj8O3RU1VMMzDjuEUqkAEELJHNOH71tCSC6MWk
1dop7MZy8BSXhzg3W3RXIA8IGSJRDibliv+SjkbUzg/WceDI176fJmUwGUji93Tw
Zu2vRjA/RTi3ZMzS/2Z9YE156hpipJ/Cu6ca8V3y5Kt6DX4fcCS09xESr6soT5Oz
eKRExN7wu8dvYMUuu1YgCVVR47BBDQi3wdZHqlq1PLaycnNOwBPLOAzA19Hefh/0
2HflB1HYKxojQCcZU7qUgQ==
`pragma protect key_keyowner = "Siemens" , key_keyname = "SIEMENS-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
fMvC6d2jTMqMqGFzPCPWt6pV9wRUCG4/taH3Nfn7RcekdiLyXQEQgm1SN+X+hkbx
Pu7552vaw2ez4j3zrTk2vRPnDAsxY8GidEnkJcULi8kiia9Xy/ePFLxOJHHigkiB
rU7uwrFblcYYBRwQjhMhJDowyR9HVAonxhOWVIlYagtABxLYlNdDEn+N4yPLVCsr
XUWy1E2L5GUFFNQffENN0iyUaKdWAKGIqgIZK1sB3tVOPVsULetSoyzRErWPNZQD
e5jbBBNZGyQQWgOJkOfy280ekoUUEZajqtB1jDvE3k8kbo4rzvr7yTkhSzLqjGod
B2Zpo2FQ//YDRSAaEa9ksQ==
`pragma protect key_keyowner = "Mentor Graphics Corporation" , key_keyname = "MGC-VERIF-SIM-RSA-2"
`pragma protect key_method = "rsa"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 256 )
`pragma protect key_block
TcmE9lQROafuvxGWP3fMVxDoeaiMX6ALoT3detg/qWZ36+yPTc/t8N7/DtSx17Ze
vr6iBb+ge3aAzWAq2QHyVfgVV15dvW/HsOXXTh7UqExiO7Dxa6nHXuAhYMON6NP2
ihfIRSvdnrL2ufvg7A2rCHGAqnr6cVnRLfhNJxtA1lloQbJEtlf/CWNblDxEfyw2
06l3l8pp1rS0E4tMqagmOr+yhNSpcS9vQswFltqroh6kNIE64zKri96HKkRFLNlP
fpsN7plEpLS54SxIMmh8Op+w0a/jXVOxxD+FLepsZWfGiNksENgu2Xo6TvZIQUUN
ZoPzFCMjGk5ZmMyIlytNCw==
`pragma protect data_method = "aes256-cbc"
`pragma protect encoding = ( enctype = "base64" , line_length = 64 , bytes = 4288 )
`pragma protect data_block
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
Ei7EaFpheCmlTJyxUg8TdA==
`pragma protect end_protected
