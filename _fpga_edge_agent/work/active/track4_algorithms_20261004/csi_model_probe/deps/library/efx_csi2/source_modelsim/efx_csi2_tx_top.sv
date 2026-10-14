`timescale 1 ns / 1 ps
module `IP_MODULE_NAME(efx_csi2_tx_top) #(
    parameter HS_DATA_WIDTH = 16,
    parameter tINIT_NS = 400000,
    parameter tINIT_SKEWCAL_NS = 100000,
    parameter HS_BYTECLK_MHZ = 156,
    parameter DPHY_CLOCK_MODE = "Continuous", 
    parameter NUM_DATA_LANE = 4,
    parameter PACK_TYPE = 4'b1111,
    parameter PIXEL_FIFO_DEPTH = 1024,  
    parameter ENABLE_VCX = 0,
    parameter FRAME_MODE = "GENERIC",    
    parameter ENABLE_SKEWCAL_INIT = 1,
    parameter ASYNC_STAGE = 2
)(
    input logic           reset_byte_HS_n,
    input logic           clk_byte_HS,
    input logic           reset_pixel_n,
    input logic           clk_pixel,
    input logic           reset_esc_n,
    input logic           clk_esc,
    output logic                       TxUlpsClk,
    output logic                       TxUlpsExitClk,
    input  logic                       TxUlpsActiveClkNot,
    output logic [NUM_DATA_LANE-1:0]   TxUlpsEsc,
    output logic [NUM_DATA_LANE-1:0]   TxUlpsExit,
    output logic [NUM_DATA_LANE-1:0]   TxRequestEsc,
    output logic [NUM_DATA_LANE-1:0]   TxSkewCalHS,
    input  logic [NUM_DATA_LANE-1:0]   TxStopStateD,
    input  logic                       TxStopStateC,
    input  logic [NUM_DATA_LANE-1:0]   TxUlpsActiveNot,
    input  logic [NUM_DATA_LANE-1:0]   TxReadyHS,
    output logic [NUM_DATA_LANE-1:0]   TxRequestHS,
    output logic                       TxRequestHSc,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS0,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS1,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS2,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS3,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS4,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS5,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS6,
    output logic [HS_DATA_WIDTH-1:0]   TxDataHS7,
    output logic [1:0]                 TxReqValidHS0,
    output logic [1:0]                 TxReqValidHS1,
    output logic [1:0]                 TxReqValidHS2,
    output logic [1:0]                 TxReqValidHS3,
    output logic [1:0]                 TxReqValidHS4,
    output logic [1:0]                 TxReqValidHS5,
    output logic [1:0]                 TxReqValidHS6,
    output logic [1:0]                 TxReqValidHS7,
    input  logic          axi_clk,
    input  logic          axi_reset_n,
    input  logic   [5:0]  axi_awaddr,
    input  logic          axi_awvalid,
    output logic          axi_awready,
    input  logic   [31:0] axi_wdata,
    input  logic          axi_wvalid,
    output logic          axi_wready,
    output logic          axi_bvalid,
    input  logic          axi_bready,
    input  logic   [5:0]  axi_araddr,
    input  logic          axi_arvalid,
    output logic          axi_arready,
    output logic   [31:0] axi_rdata,
    output logic          axi_rvalid,
    input                 axi_rready,
    input logic           hsync_vc0,
    input logic           hsync_vc1,
    input logic           hsync_vc2,
    input logic           hsync_vc3,
    input logic           vsync_vc0,
    input logic           vsync_vc1,
    input logic           vsync_vc2,
    input logic           vsync_vc3,
    input logic           hsync_vc4,
    input logic           hsync_vc5,
    input logic           hsync_vc6,
    input logic           hsync_vc7,
    input logic           hsync_vc8,
    input logic           hsync_vc9,
    input logic           hsync_vc10,
    input logic           hsync_vc11,
    input logic           hsync_vc12,
    input logic           hsync_vc13,
    input logic           hsync_vc14,
    input logic           hsync_vc15,
    input logic           vsync_vc4,
    input logic           vsync_vc5,
    input logic           vsync_vc6,
    input logic           vsync_vc7,
    input logic           vsync_vc8,
    input logic           vsync_vc9,
    input logic           vsync_vc10,
    input logic           vsync_vc11,
    input logic           vsync_vc12,
    input logic           vsync_vc13,
    input logic           vsync_vc14,
    input logic           vsync_vc15,
    input logic [5:0]     datatype,   
    input logic [63:0]    pixel_data,
    input logic           pixel_data_valid,
    input logic [15:0]    haddr,   
    input logic [15:0]    line_num,
    input logic [15:0]    frame_num,
`ifdef MIPI_CSI2_TX_DEBUG
    input  logic [31:0]   mipi_debug_in,
    output logic [31:0]   mipi_debug_out,
`endif
    output logic          irq
);
genvar i;
//pragma protect
//pragma protect begin
`protected

    MTI!#o;,p<57xQ5OUi^HK'D\'k*E>w]3?&smX[v3E^|.35D[J=\V}7WR8'\-w}8n}z2-{32O<WZz
    *KOJ$=@QJ-*$DZG'?pi^;!$E=3e7e!UksCuzlEI|p_X5'UBOD$Ru\w}AGl'{|iD]uo$x;E@E^{o1
    ^0BQ<V7Z@3c1_HV2DY^~X]Ka+J[}>aw9o^?o!G>{W>A-m]G~emIT6}w]Z^-rEWO;_C,J?%remuez
    rWpZ\<2]5G5$2,*~pap-+TGXJ<R!1zh^pm@X},eflB-$KUY--[BB^0J\{v;|DZzG#n2pYT*Tp<8.
    ZCC}s]K;vv=sgH]'>XD{]*CC?X}lUlM2D3Y#]<~'~AJ?'AA+AK24QVY[!v1u$s?o!>{KVGDAse=#
    uDp>]lX@Tr<Ole!KKR#~SY#Q@v+~#SJ[*?HxHZD3+_l"Z^{[jBnl}x-'z([?Y{~wYrte,Bl8uV\l
    7",C#u%>$1G"c}x-oOx$A(Qmv\uYnso><uOoQo@T!E78'sO*}e\5K]l#QC>Zxsx#zAQ}k7D1k{B]
    Lu\zGV^RkeZ11s=vnYb7W5V2j-~XEA>I;!J^=o-^_BBS1aovGzJZ0H--pBar?B-\;K[}*/zDZC\a
    ~k71^$4OjD[Jz1k6~-Q}zRw^V*^]l@w[@RV$r*Bk$%$l[D=2Qe^oo=kY,[V$2OG\vG{z&A8~XRif
    Tr#x2Bn^$]?@}IB[aBvnj@KZN,pkZ|DrJj}_1AsvOoUYlZ$r7]o?mWuaKn}GIm~V*Qpsioo+JuD5
    ;?sH'<u$?~Gm}+A[J!J{CR\n!??DR~:un-Y%>BRXqAop^Y,<k1+3Aenxs=4!X<KVAn=53DC=Az35
    HQao@w'$;5A,_z?P<DHmr\2BTA]a1''mljQ78V*p[0[J[Y,=azN7-]>,eOp5"/$eoX)E>QvuDZ>#
    eG[)zJT[S#w+ky~7x^Q*1\VA@kY-V!ZaGBPOi'Bi}!uqSFaX*Vq,pmT1rp!}$=5Xo,GFBOaewDuv
    JAG_sR@ZrCC'ulVl*@HG5GQ<*|Xa*,H_KxYwC^Q]$lTvD@1R~n-[JB$11'$U]@Ou@jlA<W3xJoVu
    W1Is}J*?!Hvm<=<Omrm+BQCJ>UCo'C6rZ2ohz[ow{QX5r-uEUQ],T*<xO?+5<Cu_B5CUoH\ZIUWr
    'V{r)6Hw3wZlC=cGH3Elz?>WxUJrRiUz_x23,;\vOnGU+$x7}ZvuG\G-R*~Kza$Ec['!,e]J3G~x
    I[\$lI62\OjG$~pRkQ^klp1'l]Eeo}5v{wks2vp*Z_ZOh@<Jso15{,un+b<e7_Wx$e[773jTU*xA
    ]Wn-;k,{wB=}a{IO@Zs3a>=r7'_Gm$vxJWG_lB4GZo#1ji^aD;2I)VBp2?>!1$DJ*mV~W]]D_We\
    >nUQXu=apXj,[Qu7O?'Q]X}na6*j@~~<Apvp1wZR]!E)Q+C\=#r;orZ?=]5WWvi~<$3T?{[]elV!
    zm^C=E1'Ww2vkr{uem~#'nY\+v[aOiRH_ZZ>0*UuYu1]#\e[aprE_pOCaHR[^\_x17=f:u7i!j!!
    ZB@saO[n#5xzJLzQ3,a}E~?$7OJ[Dne>w\.eYpDv2-}pAA+]o#+B1[uToQ*paXUw'-#xJ,}KaJ*u
    $}wWY+xNGAHrO!p^sX$}KC3vA*_^1m!Q1~p,&4<ewoU+!u/]UvjVxQw~=xs}j~sS<a,j2Y_s_E7!
    @XwQ~VxXn>]W<B{z/GV*OZTAT3$};$ouEE}73!G}]Gb~D2j!Gw,nr~lYkWzlj}nWn>D7;,^Z^+AZ
    &JwY\E!,7Bka$7BGxv>3p~l*5xTZIC<]rmr,vX\<vFt/!=i<O#T2k>T^l<Z<lkUp1@o<.iQJHjuV
    [,{{,E9XavH<]?Y'=VVJA-@CQ\IN!X{sLgL]{{W7CR[_><[IAjoPE'[mIs~s1YOYC=I+1~j5mX<,
    'rmRtj8B~w?Ep,HOWCZ>eTJBm^;~ep5GX2\XG#=;*#3Qe^UwI}R1!;jckxV_I'[GY@]a3$3jpW]#
    +RVkapA[~X\3Bm-+G{K'#e-w~sV~]^wn3O,_W$>2@T@nIV}jVlIGv<Q]*_e-v5#W@n\wK<mYP>T]
    <_T+]j{{!'XWVKaO!-vC2b_"$}'x*}AC@^^Y#5YCGAu!DX[iO53AU^aHaE]2~r!_Im'[P[H;nD=r
    27ejwiR\7O@;A!\?#DB5sj7i]KrK1,ivUY'~-@,3?]X2_bBAAX5alp?-W-DTRa(Q]XkW=kEJqGT!
    $+1{1d&T+UE4!l{w&\U'D7pVETw~72C2}v5Tpv_=;qY5*r!sr_DaZo7D3JbAoDlVe;uaYR#{eK![
    ZnuLv5A$]^v!L=OiWKOe+oX]idpuI$j[E_Tjx[Q^}Br}A=lO[W5#'nf4Q^=wTli,uDmHg[o>up>]
    k_x^A$U$iv!},W*pTvInA!>1nWa-JW{Z]#B<\s{<wQB>TKA$D_aH[tOOw7'j_x/M}J]'@-7{=KQ'
    =\UOUHeTD=*omlH#zmw[w1}HYv2z\[kk*-pGjuXA\,,*6x;QxXTvTH><@eHH1Cn_s)MGTm=2VIuA
    >2E!<Jn*$-e\#r};^Kx~$Y-eV,o!AVZu+}CT^QrM~]*rBaarQ1;15w5^BT1@;vV5pJQmBk{O'5@*
    mx]W/Bj*Q?C3p:>,IKnTmR{DD>}karQA,YI,$=kV,Bevp2ke,~#*]aRWxR^>3EDYDEqX\3@Do5KY
    ?<U[CKUGHIuR'D~-{Xz;{lYv*f>xZn$3T>s|HrI_GO<Vn1aY=2wu1@oDI@IY#O7\<]uZv,@uYnGx
    @v'l+aruD#\;Jo\Y(E_}Q#Uw_$_[aI_RW.l#=Op,x7\u<7[nCJr]O\:@e+_13pUKjA?<12#<>;HL
    BK1jHAe;T]\\f<rE'nU+rR>wz]DvU_<Z>pRe$Qwxv$Y[>/rr>w@DOT_Y[s[Z=[<O?V'r\>5=Qi_p
    _j}J!;9\l]Q*2_\RoB@_N3I*T(D[m~QZH*6L)/lBr1IaE^$RE3IYXTBe@;]\u2ioseKTra)}!,o\
    {E\7Y#k!>TG8^=?Xv!T~=on25W1o]3vBSe^H'~ICaO\i5?,vCl\?w[D_$t)C[<>}XQn=C3aRWYEz
    Q@msnO?R*<*u+lkfD6JBC?CHT'd=}QR"~5xv|!5I-U=vvH,\WE!oW$;\l]_A>aOVoGuKpL\$p$?C
    5lvpl51p?{<aI=CrvkO^*E^BA7_A\_oGU_V!Y'D55QE5!HSr<@TVaG3B_1YvI~TC@]<L\5$o[*,2
    lo!e{_w-11zxID?7}EBuBgDKnvI\-\jBrj=bH*AwJGuklzU*8J]!Ksz'5*~EAtI}{I<a{z#xG]+,
    D#n=po[#H3o;sDR,5sm^>uu[@QBv?^f-I=[-Q2prszYe^z=OIEYK{Bs_>->Q,?l*3=pYr@R#,oRq
    _KK!UHB$exA]UaOwv9VAn39}#u=<<H[{_>Bx$X5.}R!U#e[^YDv2Hnml[*Ep$WT!UB@@'3jK\7i]
    2sO^'^DwBzYC*XBG{jsQ}Er1B]EIO>=vp~K^T$\KrQZ?Ir-kO[@BIWAnxujoW'V<*?GD+=p=">Cz
    $~v'a$2@Z=7n]wO!{$-3OD7!$aAX{GDU]Y}^J_$;@v}*<3oWvIE@ZsJ6rzv^C*A,iV$="&o_R'7r
    @wDnX!75Qe},;*a\n<oCDusxI$5RT'2VwH~D3$LouKu][@HAA~lYipR]a[$C<1@e\IKKER[oiA}n
    azA;+DO^=>EKT,!Wo3DkX2vre>r]-3J9RdgWQp#Z[u>QGpxCYG[2<V!d$m!@Dp~AOu-+a=ws=BX;
    l~H]++a-@oD;[p5n5Y!Z/?jil-_2jEs;}(>-ARB}o$-U-QBQvx6CK\vo22!>T3K0s\>12v!K[_GX
    B^xlB>V*@(OiKpco2ATvV*x_,l'^i{aJ\7RB!@~RKHa<\ulOFtVY#um<vj,>{V<zo@j_W=};{Xz{
    @+D}ZWREa~gVURjD_*iI;u-q^H_Yxv,+Fe-{$G}3Qlul{>Rs@DjI>_XR$#,lp2'Ke$RwpzD,KQ>G
    {Us$OX5E-#OE}2s{$g<]}BY-h/9rI<*iV}sEWn'r;\QR35oI3'Ec4<wG@~LCWvp;e-<$aas^e!-T
    1J*Y-XOr^l-<7TU-{Yw~XJx:Q$1G#$+sZoolGG-Z7x\IQi;;o=5#6nRQC;{,ZQ,~C^'=-!Bjj}=n
    DoXj\n]Unp!5jqpU3Ow7$l[x]lkC]KHDC#'oXpv*ol>z2Xn]zVG$3;&t|l^2Q^;Z+JB<G<=Y@mnr
    UAjTW$*>3Y<]J.7w[ju'5x\D7#V3=^=,iKvQ#KD7HA>7>~0wVj@}HTRHTR*Tov1MQ1C_QBnmHC@B
    >_$7yQ@nwln2;e352;>5He+WkAQ~sgwa5?Y;$3Izjmom}wIaVB'jQ_G,[-'GnX3[*Y.5ris[Cn@G
    6^aD#=RA]>ls1xaU]!]**B7vuE+7Z}-*3^E;;P$uIzY$$e-}ilo+CDI'1BnRErXRwOACQe;.N*Nz
    Iuw,sY57?I}}vzVL<X[]j!ruYJRmIv*~RY^<E_+\l,3X!R1W4iR=~>*G*rzDjo7QG-v+V>Gi#/}{
    CT1+mC%V<Qo(BH*UO=?o7>VXT}X*:Nov]!7A~JDGQk]}Zz_lCnF^}~u#j[s#=#k>$-!Bjjs|,_e]
    ip1l7^IswX<OjOE'QWWUor{}ZYup0kj{1WxI[4=~Ho<5mrE'$jC_UH7v,uX7uKw,+@}<5#m<>e_*
    r5?<G,5@'nE2Dzw^sI2*<WM(xrka+sz+F+x#w5Jp~K'RoInl'G3V}5mnaA^RXY_ED0)NYH2'%~o,
    OV=H'*JOx3O7xeG~nxR?2Ce8V;ZR\aUnOXnO,5j=5+2_+DGzA<TCTjz}e;X?DQs-v*Y]#>_^l!V!
    #rkD*iKO]=rXd'Hn!xwp=*h'e;xC']i7-=-)U,K@>>GKCl+^onvxXI;Q&z_j_iE#pZ+erGIuQCkY
    ]O{x]Rwl>^I1{7I?kovX]7GACCRrzmQ]{[Ij{xj$lQAwwa},[T1w*'zaJK>~UY!s;KpE2,Tr{7O-
    OHAOerCZX2w^pK-Bnz?+Xz;!KG^v}>1r\V'<@E2@1a{;*_2I>AIzu@\?sRxZ<\Ie<Z<->epwa=i&
    T,>X8hQBKn9X_RvTnJT~R{$+BBjV2@pGCvw^a}R\~_neJ[{k+u')IBH{$'EBzZ@,j[K@Iu'\=iEi
    sj<Ex\7^j1vkf2YpiH1v,x\UWV5~X{^KTusQkxs25B7<~(}$$+IuZIDn\'}E-JQv?Oar$e3QjYQi
    Cp\2@^*}Dv}$p'V\Z<H='U.ka]wzn~In5!W=l~A:VjT2I7Z>LuH53)w]@?#+sK,[E?^eji}\72Y,
    D#;'<xApx@On[^Z=,u]#A]Y!{W$p#KIE'ORaj2p[!k2Iu~Inn*!5_7D7VGV!&vrVQoG$=Z*Ev311
    2T'AkVZ;G$HA\^-K1N)$<pHXvp5DO??3C~]ISQ>DjHXV5_ICnRDZz;DH19NjQ_XI^5^!e;x$Wpx_
    'BX\sW<_C1]K[2uYu7V_x;OCTz\hasV]mDW^C1#Ken~\O!wV<raT\l2BpK7jH-Wx@sJeOuU$x^VX
    PUI5rps1\V}*,UzZA|YaTWOjwx2G-m5c:i}'$kn;l[K7@nzU>BWeTIVC1eR{]'kUJL7sWX,m2@np
    Ens1GGvXW2De;@rjZn]_Q+15!7keiaBFXITTH-HAy)\vUvV-=H{*Uem*--l[n7j_=!BGW}{A~H5l
    1w/opZEA>oII3d$1D}u]2p/wju5*aj-W7_j>,VuVH^?$pV+=wIGsDG=$)=2r5,ox}^UvrBn>w<{x
    7Y!{r<RWZ'Ho2'^R5Y=X_YQn[z2}J3-Drn<
`endprotected
//pragma protect end
