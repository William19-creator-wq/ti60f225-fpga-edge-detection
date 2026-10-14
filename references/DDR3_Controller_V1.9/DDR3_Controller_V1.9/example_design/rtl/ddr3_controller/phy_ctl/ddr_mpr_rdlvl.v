//***************************************************************/
//   ______   _   _   _                  _            _
//  |  ____| | | (_) | |                | |          | |
//  | |__    | |  _  | |_    ___   ___  | |_    ___  | | __
//  |  __|   | | | | | __|  / _ \ / __| | __|  / _ \ | |/ /
//  | |____  | | | | | |_  |  __/ \__ \ | |_  |  __/ |   <  
//  |______| |_| |_|  \__|  \___| |___/  \__|  \___| |_|\_\
//
// Moudel Name    : ddr_mpr_rdlvl.v
// Version        : 1.0
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

`timescale 1ps/1ps
module ddr_mpr_rdlvl # (
parameter                       TCQ               = 100,
parameter                       DQS_CNT_WIDTH     = 3,
parameter                       CK_RATIO          = 4,
parameter                       DRAM_WIDTH        = 8,      // # of DQ per DQS
parameter                       DQ_WIDTH          = 64,
parameter                       DQS_WIDTH         = 2
)
(
input                           clk,
input                           rst,
input                           mpr_rdlvl_en,

input                           phy_rddata_valid,
input           [2*CK_RATIO*DQ_WIDTH-1:0]     
                                phy_rd_data,
output  reg                     mpr_rdlvl_dly

);
//Parameter Define

//Register Define
reg     [DRAM_WIDTH-1:0]        mux_rd_fall0_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_fall1_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_rise0_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_rise1_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_fall2_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_fall3_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_rise2_r;
reg     [DRAM_WIDTH-1:0]        mux_rd_rise3_r;
reg                             mpr_rd_rise0_prev_r;
reg                             mpr_rd_fall0_prev_r;
reg                             mpr_rd_rise1_prev_r;
reg                             mpr_rd_fall1_prev_r;
reg                             mpr_rd_rise2_prev_r;
reg                             mpr_rd_fall2_prev_r;
reg                             mpr_rd_rise3_prev_r;
reg                             mpr_rd_fall3_prev_r;
reg                             rd_active_r;
reg                             rd_active_r1;
reg                             rd_active_r2;
reg                             rd_active_r3;
reg                             rd_active_r4;
reg                             rd_active_r5;
reg     [3:0]                   mpr_rdlvl_cnt;
reg     [2:0]                   stable_idel_cnt;
reg                             inhibit_edge_detect_r;
reg                             idel_mpr_pat_detect_r;

//Wire Define   
wire    [DQ_WIDTH-1:0]          rd_data_rise0;
wire    [DQ_WIDTH-1:0]          rd_data_fall0;
wire    [DQ_WIDTH-1:0]          rd_data_rise1;
wire    [DQ_WIDTH-1:0]          rd_data_fall1;
wire    [DQ_WIDTH-1:0]          rd_data_rise2;
wire    [DQ_WIDTH-1:0]          rd_data_fall2;
wire    [DQ_WIDTH-1:0]          rd_data_rise3;
wire    [DQ_WIDTH-1:0]          rd_data_fall3;
wire    [DQS_CNT_WIDTH:0]       rd_mux_sel_r;


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
C6XSrZyRt2N1NGcdt/a+RCh4PyqQKHIHY/LPv1WfmPcEldF1lpeCwHvtYSsKSAop
gkUFo49HNPlW0olkHHU2ACYUzBIjXQ2dQOIdRkQko1y5SHouhLY3VkgbAKCuOE6P
kkJsk05iJUI1tMdZBRkEeLPZcehgCEl5gafzl5koKzM=
`pragma protect key_keyowner="Aldec"
`pragma protect key_method="rsa"
`pragma protect key_keyname="ALDEC15_001"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
zuRq5iUMWtaoZkxzPjNaD3dc7Wiv3F9yMCJ+HiAVWvoUpK8m+ppiidINaPIEYd2C
/IRivFrSWnbaX+6sgrJQ1/Wa/PtwgowbsxoBDXhV8TuhVL6q6BWi3auJK/3BJNvN
Yf3lPzeLhRVU7JtSzymkTP4KwgxSl95fLAw/gtra5ROCRpyB8oXcgMB8PIMcWc/k
a5drU/tviXNJqG+zv+ehxh1xq1AxTGcn0WRa604VqyNivRrXMFv8y1bSgs/H8jOu
4NVqGxoNPhInymDR+v1gt9rQ9k0yQrLBcouxKrGIzjme1Pnf7poIivg70QIkaH33
HImhI9jhq6l93XBHofK2oA==
`pragma protect key_keyowner="Synopsys"
`pragma protect key_method="rsa"
`pragma protect key_keyname="SNPS-VCS-RSA-2"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
b4uJ74yoqAE9fB/s5Kvo/rK9JvTuGskoQWpFtM7/I+XU2Z7aqsMjDPrQ+/D9fN5X
L2Jdv0UIhg7Wlp+17DBAi6sJyOwPAC1OBWjCAsPD65c3FaQxdMCeGB7YOWlGfg6k
dv7iBUWu2WTLvQthZvBT4Y/I43sLSAZoRg3yIhBHkyc=
`pragma protect key_keyowner="Cadence Design Systems."
`pragma protect key_method="rsa"
`pragma protect key_keyname="CDS_RSA_KEY_VER_1"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
TrsD+ukZL5cGHO1nlidLcy7Mrhfrd9SeQ0j/VOXHE+x/Y1QPb4qbZugBzHaUwktg
le0ENPDd8XyNkaSx+vM10PP2yG/cT98JaZX+M1fQaFMuD0SL0Xxud3Xr8jlwpIwX
Wx06tna+E+MzgM7VGjguy3OSa2aOvwFrYOO2wGZytubukt4QPlP3+3deH3LMDX59
GFSHRFI6Tyn1iHhwaNDGQNbzSIhbQE6rZg3mLpPZMjNdM3HOXFr9O4IXcYmdSFr4
dzt6o4S62KjGN+G8MWBR1u85GeLb4Cwx3ygdTNLm2DLdMnPwYmgjogUQFMKrsUOc
KyzjmAmzuUk7TGznu0HbRg==
`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
ilRzN/0wxHVGj1/QkT8eAW6gBx01d9Sk63lItdo/zMRFP1bNkqBsFiYYRAOa85oP
BiZemkPauna1GTohqetm09Ra8CzC7AA+Fydx9YGItcqj2Af2rGRcRiUtxVgDEOSB
BCtfmzsaAoGFV104yRpV6/rdrBY5/uZ7aTIalsopTqn942eBg8+agYZH6uJDvZhJ
YYYsy1mDjcPC7ojcsyvW+ZqYb40EQZkvxZeF1rKy5+Eu/0QQQJcQMIITPztoWCek
TiWsC0wt2TVkCL7D/SSvNklyKOyy0KiIF5ssPFDiqkWVeKTEaGrgGJhQJXIFlwsS
b3Fy5Q8gdlxPndDfIjsdJQ==
`pragma protect encoding=(enctype="base64", line_length=64, bytes=9392)
`pragma protect data_block
Veg6w4jDfIrL1JOWcZXN8UxKtjzn8b8vsU/gV3aQomm7rjbHuVrft/AOGcXpZt68
509yBPPWb8xizvR9CNZWv4c8yPUm4ROVsTBYyhp0pogb75xZMDA8k3KPoWQJ8JMA
s2V2i+DPokCrXALv43WTDuvTC1LMCnUPE2f4QSbJDzW64cduDU9p9wUm9QkMpnrZ
avWUbqK9ffdVUaQ4z/POcyCOrzCRV1XfH9l8XtOqw+Ts6HSn8+1/kgqbQPgE1mc3
dxwq+liOwpkOd/KuS1yMwGr/zG1bSdW1cqyY2pYMSaxgZWts1GIombbZBBy6+/oQ
jCGNaJqZIXe1BeCouPa5t4lKGdGlYCFqCuR853rmop2mEDuFDLB6DziR1HtlWzQW
rGecgAvpB4ZHwUP2eiW48l2GcSHIM6pupBBRrW7IwoN3YEZsfCYmo9jC9+v6MVbL
g0MJLK5ENn4J8vt4vxXNZ2viOEnedMJlCYiYvQd6KN1q/RmL8wyp9B2BGYdZnJi8
Z8NyabY4qGQeCjYye22UwCpAsIt8Tx6yWJoAdolU/r6hPsi4gd5XPcRpLF/JZn6c
3pT4EadoxuC+xEES+uMEmFnUCjOsygL8ZKFgdkqf0UlIReFKbO997L2TtX6tEaxj
5TdHNCiu4HVwL0oSOO/j4lhK8oJ5efey54D1S8Q+yo3k7Xusk7vtfxKYyYNelysr
kyWfOAJeLlkhJEJxt5hIy9/Z7Mxmutw2oIeqYZi5d6Bh5SGkS4lu49k04VdPxCcU
+8E5QodNUGlWf2+rR3QEizsE1dH5/zoAQKH8D9ktCpZBHHajn9ROUWqvlJeg7Wou
ETi25x2lZ22v4RSnPnW6IpHjOJu1gqeIx4E1Q1YaW2yNklwWdS9fRIUOVvVekOAZ
rymbc1sm7TVRItnFw4lxCdOjADjudjogUTr04LLJf4YfL9yC7d1kF3ev6hYGfoWE
HtfiThyOHt7PekVkXB3TI6KqYibzNI0O4GxWlSGE0Prlxeo9hqr65dY0CDbsfrpe
TDwgNJQ8q90TGZYp+l1zp/rTzSke3sWCgusqHqRlEtmFImrsgvFaBiqjoOvSaCMo
vcXoMa8a/SO2VSVDVpc6NoIxv7qTTEwktlxU8pOOMcKtmuYrc3XQEotifJof82+S
vmirlSc63Lmmb34jOymKw4aE2PnDolzecFaSkEMKREZf/bKW1UlUpLRan0rKuCnv
cjEZ3QrnHMrWsS9X3HqR4o7l1z/5oYsRJZlEU91TJcyIPCsCpKbzkHIx5Z3IWL9P
vj58kI5idoXXk3jxte8VsDssIAS+mtTt0exSCTsyc/kPv58C7CUIguej2NogpB2K
WF7WB/sIDpy6uStFKDR6XJfVuY6zfh9c1e2rAitE1+dOGp8+N67e+rVLR4wRbPOP
p595XHPkjT3sTAo2yceDK5UwO/IUuwNwhOxWuTSttQOvAM352H1LJ6VzXOHI+mg/
iiaIIrtwDJzKzcVntsb5z727arUuLu7F75OnelxPEJPvNv18zCBhQVGYsfops9Mj
9+P2H0Q9hCyfYI8f5iRRIuPfLnY03hkkQIqXSqKi7gIVJaOG+RJuQtQOTtawrJWC
qyUe9j74RzQNOuJpDMJoPEfu5UjYTMh7HIbcgJdgtz82SEamfZBfE3ocW3ueDp8e
J84ayaWNCD/DIEP0OOPJQfj/HRdn5ljphWDLE2dn3YE6+0ieCwNMwM/W05+cVa+g
e/RMel2NhMXakhrCTMZ7+v+KrjumtMEPMAqrpEepITV9MRpXN/cq3zmkkltxAtfX
TtLqF+NWgmNNBxkv946ThwPZ6sImMS30GaP0bTJmQR8nXEmJVK0dwo3OmLBPZlP8
CX+qWti5eTeVGGBxlwm1mKMpAzXx4NzmsrslPMIf/PNDWtQrD0Nhtee2Ye/MABRZ
+3FIX/o3pPSx4Nb3d4uxW+Q3jBwAfcfHFtjfH8K7LMSS+jI7AtmWSiVz0SikqyIL
pN6dwusi5wies67yDQ72qLN8ekcpjMEZeUDcFmzE3B95PZVN2777TcxJM37HZKYq
z+phWpklh0q/0TlFaJOJIrU0l0uMkA8EKrThknP7AhpxiMVkOO3i/oZ7YRNN518Y
sKspaLWK0bY8yTdkWjoURbbu5n2nb1S3Ex9wga8r1NzWUySGkhB2VeTfgLSN73g/
YmyOR58gXztTpefgj7a8qZB9zk/obvpqvGpWqHvfEbgy+0rvH9mLKBqs+fHDwtKZ
OHCq48QmFMdn90VlaNW5PxUJnHLmGK6i+HhSEZnaVxufsn8T/koM6iTlpMIBJgfu
o/f+mJ1PqHIwYKZ0QM9L3yMxiue9GXhOXcMgmrdpFRsQaxmFAWZVH9YUYkEiXRp1
MpKRG1rbQo5IFzki3uYRtdsAmcXe2gnvXTY1EPDYFJUheF3shbd+I8FvsHfw0ZxK
0fa4CB4TmBik6I5kEwJA7VWCeWQmNt+qwxkVvEt1R0zNFSIYusmms4fASKbr/BNr
Jm8QfQaRyGks6keJ+JobjNlWCbudP7W1AGx8X9Z9HL4WNx7M47kWWRra2SZ2yuQ3
tBjEy4lzJgfXSJF+qoHB6Ok0XbxYloNb9y4fBDLLaKWqEJZgQTXRU1N4IPU3pKPd
nRN2FF4EGfNb9ygqHgj7Q8jsGn097zzl+834IoTEqbAR9JZR/hEJlgDrlee2FLNN
Y9iw3APcn+puojVU5p5g9cZ7pakZhwQkyKMR1s8+YYZ2IZELJm/+nadBLxYrJck/
hwgUNPVvIMan2ZVWwLg/v7v5TCPB1iH5v7wkRjuVDtNADlZk4K1smDfnRu/bktah
Lb4YQATPY0Ohjg16ratelYT60mC2tWz07gtYbxunqGPnVBq1P5lkg1OGBMExor3Z
rAk+9zJNQSs1YV0tThq7iBlsR6yqPLPZNi3xcmrAAYKvaCHgS/TjMWEjWfR+qWJS
+GEOTYd5Q3ogmMO+FO6yvkEWg4ojtzs7KCyCQElBG55MWlXm9LaHCIyGCulG7qyn
Jg+LxVHGCxhhEH3eVg2ReA51Igik4r6Iu0mqnmEYXnKld/q/lAhAtgYM33JsRjn5
G/L5CBdqq+jz+J/9aAD1ZGu8IsEs6ptay1KnqMQ3EhbGjBzaI2yAolaWq+gecqvw
fp5SvQND6WcBmtJJHxSCxquXj1OA58SFwXh08933HvLubJEBTQi+89a+b8CcIrdB
JErLM1WWbilgMRaSMoK482JTYCZZykgX+o5NTBHkhxRkVwigBoqD04Zkd1LeISiZ
z7mlXxiUVlpIwH/2j6lBS/sSxqIa0PxPnV24OEYAeUqW/kt4lXQnO3pEz5/WW3UH
88wmg9ZaZmrCcziMB4JqHNarGY6eZU68Ny3dgbaZjH6GHwdLF4KX1MC19VmC3lQ+
aVndj7nUoAbkV35spMYYl4CL4rEfj8euMUGDlpfsyv3cWVGFqp+3Br2fQcSjdAwc
PKMJF7pcFTfYtW55ahB0ckw3r4WK4hruf227rienzTHF43IWJFdVHPv68GFxRK6I
ajTcrFDSYlByaXkqI71uH3M+4e5VGnNMfg9bqqwsccpWhc3iTKVZDLXMwaw/cFCx
jZb9Vt7ZlFVLeR4hYTnKWL+n2O70HnFCoVeSXq2kC9pJ/dnNaF9UPwWTLaVtQMsW
tv7qlusfX/9Gj/UzLt+iFW+1EYpWtlbXHuUJY22lzvL13xK75OZJGY0S1M8jYEUE
YHWQmPLHr48oBeZOmPGDcd2Jlmnp8lL8lFhAY6Cp/uL9MGQ+AITnhHuXNpHeohbe
lnYhdBqGNbOUYJtKjhSf6hOhS0pDdWBcI7sNbeeXEOAMnr+kQt9XpKQg31MSPNb6
RtIpg/FSZHn0MkrOttgQDeanTwvhxylsGX+QbiBCaPedR+EVAOr2oho7oF9vysB+
OHvI4UenK12UfdrbXAdY8sef5Gf/aigthY+EEdoGJsbDJWYGzCWJuiuuDNUrrEAx
JLkF/mdwiFqTnEbnJimamnXNkQBfORfcn47qP7J8WzEqI0nxMG0ReZ25q+pdNw5d
EDK6UvjAn4ahrQY5l899RrE0OMmtyrkUW0oDe4uDC5nQqfZWBM3SfYNpG9z0SHNY
edJsrcVAI7PFMTdVvNahrU2LVVs1ZX31CfilnXEO2dWcvHWPZssUdSb5QHHhOW1G
/9NHt7LK0howQ1DMZVqR5+P0dOxkDZsNoNJ6wXpeqsKKlKyMwz46H+Zry+YKYvw9
Gz6bcpb+XvpBnMvX4zh3pmemLSY9pN6bbYg+zkgOgbam+gP4qEjw+1riw16quY35
NA+YLvEWbg2AwPiP2N9icV0v8jmNy9Cj+oGH2dNmi9Iizf5mWsIowHnHmn8Gqesi
VtNiQ0wEt7jVNAels3f5u+D6XPNrsj9LLvow1A9k9/wZqv+4RBRE6JVJQX0kL9o2
w4DqrMFwHPQqW/vxWuSR8uUQFnkn45jMBPXy+72hK9p7/CwEn5hg1T+Qh8YYxREf
bXzLdrNtJ7x7m0ykUYpXhEQmLxdFYL2Zj0sp8vPaFmaBb4/MD+Hggh/TjIxmllmQ
f5dO1JZa7TziE7wzBD6UXH/WJ3X0jv0mZ2QTbbljFoYaJlE8TmPUnfsvaL1/LjEo
fI+SqbZMOjatgSgnBtBjaIYnK8GrlXW1VVWAG7iVLS6D5lWmkWFfTDHgMMntWsEP
J0UTpVKcIBqB2x5cBqTlp8+n/jHiqMspcogVNvW0dFMCS2ezRYqK/vW7VJL50A9O
7XZ2dUGTHWlQjyEIwp3K5UngwSTq7aMKxb+VqkabplWuiIC2W0XAfwnjZbaNEN7s
jsGtA4fzdtRTlscDuGJXZGKLHY31UH9IRN297cSC84SV+IynAi7KL8+T6HJ0rMkx
2Nj7uprWB8LuLmKIN16Q/0v8wDwXhTDHohCIWlzigrcONelccs2uu2kxBQ9GGmgO
ruQCcCK3HuQnUkYtnECP08HY7DwFzt6Hqx1c1b5el7S7gWMkltNOTpqxY4CSgfCZ
ppli6GD4zln8I4+Nouwi7NITwRbAF6sk0GElgX5jsQMbyZEozEpUJIWdo2KihsIi
lZqPwgyBIRJ1zrrgXkgiSFiVqSDujiZbb/kVyDgC0zfd7+ZMZ8OaQwWBdnvrqifl
XPSTY+bySpXZWCf00CatKpunaN+6I4ZFK8UvwSdAPiwQAd6+nia4n79/ymdEwxKT
IiAkOCZd7WcfOMHygO2pce/etw1G04aqgFx6ES8Sw/rICB2Z1sql+Hqx4WcRGT8Q
84mrMPPEoPMFplMKFJ+wzQokbd2KfqIv3uD7XSCfKvm6f/MmtYfOGqD8SXxjW7Ts
oFNW27IaNFx2PbzWGly05fSQhNjUrT4lf7kHeRMJfgtOZOnS4RX44wopkkBW3JCr
vATAPSwGmkQ0/lRcneB13gFjC6RDI+g6gMZ7qU4NV6BYMZJT8OD0iBJrGBpckqgL
ynkM/uNEYE0QpFARsn5cISuzK3HjXwJpl/xBXaM7X471047Zb5nHSZIvGMGx90Pn
153MwxpsmXgZ1jL9WxrRBabBGGAhbv5rXBn37wr7m8NxYJE3nyTAor0T60uS311F
QtgulZ5s7nPBegvtMbcg0olj5pmq2AnsloB1ZUoMI7q1ESWhYVXUkEPix2+b5kL6
9B5Dw1MU/NyIHE/U9j/xhAtaTcjrqt4RpahFXSvSCMvu/77F7b1WmoiRXcbeP6h0
SvYprVvHCw+Jo08ABgo+TJSjobuuReccVBiKnn2qChUvVdg2oez4VjOi6CLnYvb0
LQ2A1q68kLB6uQwSLT4aFgikAwgCDr1JiWbEu4LyQhSJ0Y8CG36vpIahmS2Gk06w
q2y3SKxlllcD/D8LGktEd9nSEizmrwnBXI0Uk11zwjhz3Ae52tFgLeTKzrB9dPCn
yeWng+YCTy5s9dO19/CjapnBLrMZWjrs59QxUuOImG4DH8T1u5AdqYZe/6SvKyyV
jj5NmbzNnYsMGRuJQGTJV7TnXdPqz4zf9rGOqWYdcDWzrrTzYiq5mKylOEJAOmKO
N2vDGKkfAb13ZkZ4ahq8u45YwODfW9IlEfAO1hnM3LmAR/q9YbUrZAdgU/B5PCIW
NwJ9X2tkC+PErA2s3pE2V5beHq1rN+PbEABl7mNp1rQVCJbuTRBVnWDEHnJVclof
HxF9CX7qUaGGb4X+RPZRRLYFbI6NT4zb/mXRBPftV+1Kxuc5LneVnrLUuKl686wd
lvwj2de0J9uPuhqaP7/pHpwtBVhInXG1nBs+r5C0HQZmhPJI2wML3ApD0nXl4As1
FXtpMC2PNwGwtsB4flEA2dlo4BK/ahT0f8RIFcEvifzJ5h9g6eVnSTylrH0x/pcN
9EDK6zpnb3ThOqs8MfBde6hcvq3+LNXI0PrxszAYIigzf5paqaENIfm0rkLzeeb0
CkCDAm9mJqyXs5Fs/MUxLTQ/RWgJz7VrCuuh4CQBSItUAtVZTW3Xflik/INiyY1e
WrFerKlMYC8JJtKb+PsvZXo5Dbq9Oc68TjsVT/g09HEX94F77xez8IoZaiLV1yi/
DmyqeBUYdxkSF1h4N7Hfuz1zXNai7sIX3T5XvEIJKqASqtgpmz4MhW944xRjL4/f
vH+sJ3mFsF/SHZemK5C781b3ow4rUZFU4Z9O56xgYDhhBSKkDWn1ZsU4D5uGMM4X
7dm/26PuIyxZXpT+EVFw/1kD0pS+P4nNs9jR4GkZcC3KCwJ3y0Tunh6gS1UVSZLL
VYqaKJrUInwCY2QOHL83rQCc1SyIXz4i+EFjsW8we4tM9pwcunQS4nbUYADE02Lb
dy7Hl46vq+ErYi6xUhs3NCoOys8SCu1EW3/uPf0wiwmr7BYMpqt530+jAdCUv3sZ
kvq+3ce2saKDF3wBKxFT3p75uooM85mpKFu2FC7FxWeM4HjgElO0I7pDyx6tVNb+
vAFZ/vnLnL53KlcBPApDRdiGdODcehKwjvUvcjbGTtEa++CEE9nV+73br0E/wxSf
BCyYOdSxgDt1QMpd0pZOmCIgVLuzgjkwqn3D7KI3Z2b3W7bnnq6WYAzF0BKRUxIr
Go+APquF029X+dCTIs+KkBzfVmJk5FeixgXZ6ZLpHZdZKwlxtrJTuajwVRWtxsfJ
fsrGFE2WoBHP2RnO0mpy43m60zYoLsJ2qANh7NEAwy7XyvDCfe4fKnlF4P/ebK0m
vTR6rkIce2EwBq/wjvWEK3dG5IfrhFACqW9mAkmUtJ1EANC2R1/tkVWDg0sjbBht
WHMVgBkj2s14QZNaf3FgxZGXcvkkqsF8hiitN/yEpZo5DgKBK5/M/YJPT/+3Fr0V
hzE2BifRiDjxD2yGEHEw4krUFoqr0l3qRh3mRYsaukL2ohEPNAU4BWLkg1j22NSP
wQVnJ6NEzhPiRESwm5fhZud1K/gilQIdouEnzG6kqwqXeZWOmagxCrPwK8v27b5e
PnMH2dtULof3lCRrCb92mmAv/tZ4TwTdKyA/yQvlUkeJwQre0ZBvd/cYfMwH704r
jiLq2lsUX8bxt9umcpHZFyjCDyyOo0QvuIAylODeEH1jNDo+/oT+FSyvf7Ky89ri
HRBiMzzVXFOjwgkRIGtufw86aYbkSefYsKpDQMMBYznfbTmGKtoNjS9EkAAZZkuO
Sd7FiuMzK9FXRYCztooE/VedJvNlIdCe7cEgK8ygoyYdiXrn+Ott5e6/9EKJgzWc
PI0eHv0baKfdyY0TGCvcxuBd81oUIXFOOfVUPhkVmTJs+H+kuIDVTYfLc6GoUmDl
6V9TBPUUqvdaKMQkosqLJmph1dIA+5W6HrNATP4nQqarvhfFb2q6S+GvsDjMq0x9
0cOsM3LXzgA2TzAQ+X4lbYwHTaziYKJzL9SuN1+KenjU5IsXSPKo6Y6TTZ0CAAsy
YDF6dFyvZW5se04K3ddtdYbJX18iL+J1MnFjlqok0p8fF+mhYel1+ny1o+Vc4zfI
TiyP9tgQOncsQBkYb9hlp21xLOuhDo62OHnAPQUQpw6Q7G3RTDdamfTMqTh4iPEF
quJgYnn1vsby2W3DOuMn3zCuKBkghrDqvnS4bYKH51ioI5oQbZibFYy1548y36cE
hAj/PpoPo3a2hkP6+cVeEDlPDOS7u/yjdUfXD0z11eHBKuNC469j5VkKEvxmtdj6
xL/VYCxHjYUrp3JZXkIuedMv4Kj6vQ5iCfm5P8cT4TJN6CfMb1Tn7lAPKIO9wn4n
/1uAXHrS64eXU1gJNEf2wBHR2fQw+2JJaf1Pq0gLdjL3uc7ZVJ2/IydJ6qH4u263
+o2ywU1Zqatzvghesu1kep1d7+gN4n/welKYo34IaVETtSyF5PywkM5QgscYleig
NuilLdPHDnogrDCc4O+fY/NTs5xCYpxf7uOYAypYiYVP3/HFI6TxZc7ECFW/Gdze
++E+SCaljltEB1mgHaZZbUSG9J4hOPoHwkWhQNijsa5cjstcNuC15Z3tUUVubMN0
wpQYGvYq7dq4PrXvBYo1g+afnx8BhdVLx+SMZFAYf27qo79OvwSLBDIS9PPenBha
YAmtbDef684itqxw09csMp4TkJw4Fx6F9hyklaA3GoO+xPRUtBvCuGdgHjD2puPC
6gGcZ8tQ3Wzc0tS4FNmZZQyRgxECSe0wV/qs3tTx9HWSWGJ0KaInzx7gNUB0Om8s
LWs68iSyS+RMUftEdswfb98roTCJnqK2b9teUBOA24FcXw1h6IA7FIpp+6JOgcYM
m+8bTsg0UcfAAF1veTsT/gmZRSXTPQ9yQxU4/AAZBxY50JT5k6ujlaEunqnVdQn+
6UAZXI35KO9YGs6TRVIszbcGPLqWqwwEyZtSPYYYrZDP9Q4ggXg6Yr7NpK3Bmx1H
LzrHe1GJVYhz8JTsuVlkhrgm9YSZ13IxqURNB+hyEDKnTXsM3zKWWGlL6Kd+skG/
BI1dZWyQ/gz9RnPVWwHCVLEfzGo5q9XbuAvfeNrTbR/wDrslyT5dutVZDU1SXyr4
vMFm7/KgMOP5i6UedSL7nYbGElPcRQKkiSDF89nP2viGepSYthWFtCjet2+NIfOC
YSzUA3byAmog5Eij3bLoZSPaBn2RZIkvS+DxXU8627XIIG02DqRXU6dvdLaOWMKx
e6anmlAJ+8/LwHgZfjRq7Ib6zYJZZwPYVJ4tUejIBdtSLwwQ5GtbSMqHhX3aWt+Z
0m0r3ZxhXXf0DnxeFBRVH1G8+ffngzSbF9PnN5zSRZIFBbDvy/HEsgJ5z9cPeTBm
M0+W0PP/oLK9hVX7rDR0VldxJsKYkvFvG7P3A+Rq3rQV9HMsPUolk+VU56CROucF
7Lq/fAQvKH7w/i1zNcGGjbGZu4bhjkCq2V6Ufw8D7w86oOUm+ZVGmw7cC6rtFO6e
klyDun2y+VsFCcEFV4OWlOOSgZ0CSaBFLs6LokBQ2fFx8OgbGNpTQCEFjFWVW+oq
D9N87TkrP3tlufaDVac9tma5S9UqcB+5t2uOy7TrkOSYAkvl7KQYkLkTGXVaNjCn
lnmzPXyYiaZqobHGmuXA7YNNxMPH0L4ZlGlbxb8X05RuxdfYs7JjMDL++KHZ9LOl
id941AcHYqKBGc+kOJXbAXYTm5CKYCbXL14fLrvwV0msEonFnIO+gf+AZtYqvz+W
igvSYMgPmtN30FjqVz7ruVuXbWTiinyhZmH/RplUWAQu+H8ZEZJZbMcOQsUvKwZg
PBJfLjF1ESpbHqEEwiPj+tRbks4QyISyIcgmswNRf3YrTI5Ki/8Q9YOO8ziLjtjJ
+HyLa5ixgOO+nIUvEFpPmJFDzEajmwIEAFSIBFBB6mbkthDsJ5sksDuSn4a0ulzd
tmVeMOvWQJHzVub6c1BaH4TmigACRIFWbe2/Ax4n3zlG60AqJNCFL9lIYyjXsP/I
s1NCnhpWSmsCTwZ/q/LQ8DPhyINrY5Ru4qnk4BhzrisY1dUF1Swj2Qnobp9CIWG+
nMhHa7EFJNuCpW1dO7SwHqmoBAalVY5P5kXVFA/+LV1cr3WD3Y7k/kuxFHCQQ6No
ZxNyZf+x7n846bHqHkrWU7rhr6Er+cAjVUQxY+CpnZ740QH8zN8OoG2NNoGi+g3t
jwBtiFWpDTCE2hS1Q7O0Dyo4tlnVDMh3o6LPbRH/ILpFHCio8oPwYZNW/mcDO38X
wnupYWryJ9RuDjBtfkTp0AgPNHiyyRjmNhmRDjx1+uR1fcKw0Gl+xyr4Qtrazm7w
9ctkg+u5hzvEAygfegxxColXYB1db7EsomAt+SDRVk5MNLCt5wOynEEk9Jru19Nd
KauF3cnFVD+P+Yeu28+m5BmpIYjeetOH21PXlJzbkEwB62yDzlP6C9wqxxkRByJt
GGQEAb7W0TPg54Ndgzy4VxHmfE0kb1tBg6J7fjHJYdxcjpKZWqga4QjTQgI/07pZ
WJQkV4OaI/DAMi0URnkpRJI1NvbbeofcyVhyfywmURNoHeBqZ6WgOOYruK24XiYa
ILfgUpMOOnB9VIi3OZ7ZyqI5m4WmPSQDib2/qJrVxkOOVJU13pP4luYQfoIO9mbt
JMFvDkGck+oUqAv01a4lv8Q0hH1qgbGEomLfuxUHqUwBHii+oG/xzBm91PdbBLE4
sRDK3g/MXEbgmAy+ILwbvVUJOQ5lQBghIFLf7zevnyXdFW7i7Y9k0d2kcS4GMg3E
Kt2DaYbaP1GIJSBdY7/p5J6wWPodT6erDPu3lQWkN2qc9oXwz1D6+O+1ipRkxLyd
sq+S8vmCku2W5I7X21DA3r6PPVo9++fpcxkhGqsQ2yd856AQ5AsudsMnWJJ6sSsH
RTWryjSrYuIo+A586s5PZi9hIa9IzuqTf5mKuAu2hLpFjKoj8W4xWFiwE/FB6Hf6
jZLsYwi+/+v5SwlZjhu6EMiiV+LX/Z9GVKWLAyDp8aMw+DVNkweOV2CACuP2lRD8
+aZbWdWRgHvGpyE3pIMW1G6s+lyLLL820NRBosg+GUxPOo8Mz6pRSNrYVdoPOOWK
5Nv+YzSMf7XAIxFiWH7MVFC96ZBoCMG2CjkaDbg16RkSJlObk6jiVwWeMcP2RIsF
z6zNEc5xPwFLSaaSefvU6dqdyJKdnpR8WqRfRQmuQS6zuyhmQ2KMwWfcPclXB9kK
+FewN1ZKJpc/+R1nz/3Q2z7OUr0CYz5WaZPrUpbOF0ckw9BgBEFq0CuTCWcKAYTP
YMTMjd1dlzV9yh10zzZteIGkN8fYhdJDo6kFU6Fk1tzPG4gcyuMuy+2zs3VMmzy9
pgIeuwwwA/dIEDrWFCTVA3K8McAwiYq+Dj9FGVPCY8cyhLiZv8TKKFNcLM4K87Ro
Ac6K5JnRv3EOrOqLWc0opYkujBWPxD9khpD7o73ZoyUkSAvc/YFdlPVtGsmJxxxO
zUPiv5eyxTPwBzsxih9tdsbkDIssD0pgdpcw0eu4CDnv4I8C7B7/nqPPnzBSW8u3
4jeNlByyWG9p4cIxuKWx1X/Y8YVp3Uyoupw6NIJs4mI7fkA3UfePFg9oNazh3bRI
2EdsLE4Cvxbg/cjLQcdHB62TCAJUBgYFLDkMFVI7jI2qVfwuaHchiYBE3zsbRJhA
G+Pixu00+yTwDzgBC8wtf/DkgLH2AICc1di0G8sDKfbdTQXa+KtXAJrUAyVTr1k5
37HkAR2fakF4r007wgjR2d4U1/7uXWFiED+bp029saVjg4aameatxTMyLrcPepxw
XorPmVXJBcG2Gfv/xr1YU7o71yw7fckTk+fntcv6kPHYVa7LW2wclbX7ntOVma6e
QboU0BhU9rokKMXAQWbKtuOJ1HcBfyspa4+zPW96nzhYolonTcIIbdoSGnK3bs5g
/ABRvvT27UmRXUdoqZXXYVTlrCr/1AfSmaAS81TO7+E7U7BIwF8/0jVxBlse2nSe
i9fimO6pKWyxPerUHkqAUyp/HI/j3b98Jqc9XUnGrVFkY+zQUe+Uo6dKX82oVQG8
egnjKQDJYAYcGx79/cOJpCPSOTKvpgQFlPNAx8z33FzbKsEBECZM3rMgk8KiAsln
mt57RGuAsm++iwNMG/eXXO6mRLWD0gybHj335XJGyw3SA821Vta3tgJqfqms0BvB
5503BRKXDQnyW9wve6AE/nQ8hI19lOvVkchwf1r86txbL/ocNKYfc1F8sJPA3TA5
Kg7f5yRV7RDAj7D0dYKwGSFLJeUhFq2dx8UesCIyAprUJ1C3swCiYV3hqhZQCV97
1XPFymwiZ4UVsgM6nMpL8FyPaIv2Pe2dY6+4sNQdrmdEnBzMkwiCqEqsNt8mUPQd
HWoraCiKqhMJBePFQlpq1TcFdTA1bJsZQq7Mj/OQ0bD5lBBr+pn3mI53V/yClvXy
mU3e6tNe9TX+saxZtD28FZROcQQnaPSInMJ7G5a42sfTKDZqeHDJuAnrb0f3pgV3
e31j4+Up9UzOTapfFCPVTBttnm5uiJPHX2P7R4b3J7b4fzd36GgQkVjqTJsvlpQt
JZyJZOwea67iP0eH/4xt3QhP9B16bZK8k+Gfy/d3LXff9vXr9k7/MrgquGqafyyg
lAE59tAO2D1XKrJnRJICzDxL2tW+VayEucjr75X0RSo=
`pragma protect end_protected
endmodule
