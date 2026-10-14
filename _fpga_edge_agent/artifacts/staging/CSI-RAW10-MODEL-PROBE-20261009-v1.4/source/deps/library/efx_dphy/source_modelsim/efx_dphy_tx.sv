`timescale 1 ns / 1 ps
module `IP_MODULE_NAME(efx_dphy_tx) #(
    parameter tLPX_NS = 50,
    parameter tLP_EXIT_NS = 100,
    parameter tCLK_ZERO_NS = 262,
    parameter tCLK_TRAIL_NS = 60,
    parameter tCLK_PRE_NS = 10,
    parameter tCLK_POST_NS = 60,
    parameter tCLK_PREPARE_NS = 38,
    parameter tHS_PREPARE_NS = 40,
    parameter tWAKEUP_NS = 1000,
    parameter tHS_EXIT_NS = 100,
    parameter tHS_ZERO_NS = 105,
    parameter tHS_TRAIL_NS = 60,
    parameter HS_BYTECLK_MHZ = 187,
    parameter CLOCK_FREQ_MHZ = 100,
    parameter NUM_DATA_LANE = 4,
    parameter DPHY_CLOCK_MODE = "Continuous"
)(
    input  logic       clk,
    input  logic       reset_n,
    input  logic       clk_byte_HS, 
	input  logic       reset_byte_HS_n,
	output logic       Tx_LP_CLK_P,
	output logic       Tx_LP_CLK_P_OE,
	output logic       Tx_LP_CLK_N,
	output logic       Tx_LP_CLK_N_OE,
	output logic       Tx_HS_enable_C,
	input  logic       TxRequestHSc,
	output logic [7:0] Tx_HS_C,
    output logic       TxReadyHSc,
	input  logic       TxUlpsClk,   
	input  logic       TxUlpsExitClk,   
	output logic       TxUlpsActiveClkNot,
	output logic       TxStopStateC,
    output logic [NUM_DATA_LANE-1:0]      Tx_LP_D_P,
    output logic [NUM_DATA_LANE-1:0]      Tx_LP_D_P_OE,
	output logic [NUM_DATA_LANE-1:0]      Tx_LP_D_N,
    output logic [NUM_DATA_LANE-1:0]      Tx_LP_D_N_OE,
	output logic [7:0]                    Tx_HS_D_0,
	output logic [7:0]                    Tx_HS_D_1,
	output logic [7:0]                    Tx_HS_D_2,
	output logic [7:0]                    Tx_HS_D_3,
	output logic [7:0]                    Tx_HS_D_4,
	output logic [7:0]                    Tx_HS_D_5,
	output logic [7:0]                    Tx_HS_D_6,
	output logic [7:0]                    Tx_HS_D_7,
	output logic [NUM_DATA_LANE-1:0]      Tx_HS_enable_D,
    input  logic [NUM_DATA_LANE-1:0]      TxRequestHS,
	input  logic [7:0]                    TxDataHS_0,
	input  logic [7:0]                    TxDataHS_1,
	input  logic [7:0]                    TxDataHS_2,
	input  logic [7:0]                    TxDataHS_3,
	input  logic [7:0]                    TxDataHS_4,
	input  logic [7:0]                    TxDataHS_5,
	input  logic [7:0]                    TxDataHS_6,
	input  logic [7:0]                    TxDataHS_7,
	output logic [NUM_DATA_LANE-1:0]      TxReadyHS,
	input  logic [NUM_DATA_LANE-1:0]      TxSkewCalHS,
	input  logic [NUM_DATA_LANE-1:0]      TxRequestEsc, 
    output logic [NUM_DATA_LANE-1:0]      TxStopStateD,
	input  logic [NUM_DATA_LANE-1:0]      TxUlpsExit,   
    output logic [NUM_DATA_LANE-1:0]      TxUlpsActiveNot,
	input  logic [NUM_DATA_LANE-1:0]      TxUlpsEsc,   
	input  logic [NUM_DATA_LANE-1:0]      TxLpdtEsc,
	input  logic [NUM_DATA_LANE-1:0]      TxValidEsc,
	input  logic [7:0]                    TxDataEsc_0,
	input  logic [7:0]                    TxDataEsc_1,
	input  logic [7:0]                    TxDataEsc_2,
	input  logic [7:0]                    TxDataEsc_3,
	input  logic [7:0]                    TxDataEsc_4,
	input  logic [7:0]                    TxDataEsc_5,
	input  logic [7:0]                    TxDataEsc_6,
	input  logic [7:0]                    TxDataEsc_7,
	output logic [NUM_DATA_LANE-1:0]      TxReadyEsc
);
//pragma protect
//pragma protect begin
`protected

    MTI!#XTo;zr=<Dl3OA]GCRYZKzKar#G\HjlV,|%i{'i[KD[7Z5]u[W+Q@!o(+T@7vOxkB-sm^<;\
    '*W;J$a@7Q-H,p+3*QIiE5]jOI#1YwTUQrj17K2zB-K;lTXj#$2A'jVo~sV*oTA[xPY-!C+{X!]C
    M@Q^<ArU=lv!0<s{m@][BLnD+Iao~[NEbY>;x@o\i+<CZ,;G3|W<Bv~nx!U=AO=rK1m[jE5QwX)a
    ^3IxxTaZR[QY+IPlzVUTr^=El+~2YEv/^-UC<-upu<3Z5$b0Z{{l37ekPsxmD~<-p,rnTQQ[!1AB
    @7kJ?vF1n[^lB7OI>{X'~,[R!@K7;OA-r\vuGXCX}[3lu+^z\@Jom^lnj*sONjVI*^s]*~'$eI{;
    >$+;rnA[r'l<zCNmD7mNAC#;AtlVnvY3$2m[j^0I_l_aHB?=Ou-E<}KBIT+-s27*C+Ak<{E!OO]{
    =5xx=p[l+JeA\r2)6s\QeKe@waxnT9pR?URx-<>nn,w_TjM$VpeAYYXD<y+Unm1TXrX*u=kHm7=!
    zvnv5C}i]_7Du\hJ5{B,vk~n>{XW[5H{V'a@5^XRTu[2EusvA03Gj$$\<?b-QA{o@W$3IrQ%[HR$
    \>O*ZvX]R,naA7K^a<aJI>Z5?rw!5+Q+OHJEc'ZJ^ZR7i>D5}UT5$RCG#.NK>naB_D,rzEU_,U;V
    ZQZ|L7{A$$?>xSC2A~piOwsJ^J=T[7IzXx~TV>~DGY,Ow5jD}*O~'X\lA>mDW!5kozQJQ~B-*p8_
    D2CbQeTwvaoI:gLB#Ual8Rn3}cl]A}ETT+d*JI@e;\xplRsVwo3>wm;(G3[E*kBVRs,Z@VI@[?J$
    Ym@z,DJ^I71wzT+G-E,@7*{rIVODRDOv}C+#-]T;#Ya@uBAp~x#Y.j~}w@jWep<+{ZwHlAl2'wxA
    'Hs+{\ezx]?pE_5DoXsH{*G[RYKsiV*[poe|l@->I1=Xn7'2R_VIV@B,mozDcEZH_oVT]HI=uPOl
    us|y'XmC[K+!'=ra1i=*VOE'ClQ@z}'Q(7_Klr^<RZe'I*lJ{$1;>kX-]p>a]CR3!y9!{szfuTEC
    ?+e],#J\^-@[7{ABt/$ala*uXE9rR{3E}wYaT{^3nBlH's'OR$s[n[YLHa3?]]nUvA2#-lYn<=Hl
    r,$xiUe{pzA{#D,mOvBQ2+{5v,${1iRWuCD<QnZ7w>B\-j^R^m2-]1l}U$z?\ZT2X7o[^i<ABC-#
    B|n^A1GR@]1mj]IHZCD[2a:kCH--\GWQI7;$#ol5uZ[ejZD_jWW7+x=_a5AfYI3OB>QI^Hz_DTpe
    w}T-n15}in!ku}7o^GT1l+H@}Z]^m1tJ$@>D_i>As]lqi+=~UCaw[x}Gn5,uw>$#[_nU{ron/j]D
    !'Xem=7C'\>lr=Yo2G{=a-wz~BWW<\lp1S^HKT{^ea;Vl20wqaH*C#1;lvXT;kDTo~l*msIviY*G
    v]zz^?'o}#za^'!<rHB<*BN?*R!pD!}_=R!:$YIDC{<GUv,-?xCxP@Q\;ivGlCaYro7!DEA1mCnx
    vWR+]SUATk'@O\KHTr~[5*Rl^3wECZ>w$Qnz\eG?;eA+XZ=#oO=[V^!pR'>>Dz+n_ZTo-*]r\PY@
    ~2mrIOkGGXBJj\5]<Z<6GJ^2DPo$*!!YjVEe!sxROxZ=W};=A3s{Oeu<;$PB<+1vYn{>1[2Dk'~=
    {$XFRw>~xOvuWO1TK+7IBqI=XG^X==ZBj2#7K2_GcW7J@p=1+-rz#/9VCB,RpDExHH-K$RXr,U+x
    zVxWnCajQW+?-xK$ZJo!a,#Kz'~Izrrusp\;+W5diXoa<RG>lDox=H,,Y@~BUauV?HJ<HOi-TTD]
    [{_>_JmCH{lIQGiAQmJznHHUaYkRh57j@ds*JuJ9|s[plHH}7qVoZ\-<{>e+2G/RxW^-^X$AEpZu
    YA@I5?H97f{Ek@{QUaN'B}m^3_-W<sn9T5R]r@!Y-*}}GujVR{lB\oiZ'Yxj8ZQ<TEAj?avvH#Y-
    Qv333Gk7UK<Qz&'^=2VE]r"BXo!h}il'kw3@w]A;n,T-\s]w'j^sx@<I"lA']e]irqK.v}WpJB2?
    gOD3@/zmY]oe{@<lI$>,![=IQWA{G$JXEmY*<!51[5Tv,5[t@=]w}A_Z=@U2/6x@TuR2B>Ii5oA<
    XGs>x]\e?WTOO=WR@RZ_^]Z$<wiDQTtx;$UlJ{_6j<pR};*321Ez!a~>Y=\=x'HXRk,RUV*,pZYI
    WxW!~}jI^;v$LW+Im^W][E#C@WTDm1m\IX$[]e^$p5k\p\Ur{%sH\iIk>V9j$e-o7ReOsW'CEJzD
    amxmzQe+O]*YYYmM+rI;kj}u^+rKD3GjFGpK<GIl$=1'a}jvr#aa=GR7x=w-7<*[[jiWAusW@?EX
    >EQZ[,mU^oE>?ji
`endprotected
//pragma protect end
