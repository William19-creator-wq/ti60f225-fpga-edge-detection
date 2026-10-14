`timescale 1 ns / 1 ps
module `IP_MODULE_NAME(efx_csi2_rx_top) #(
    parameter HS_DATA_WIDTH = 16,
    parameter tINIT_NS = 400000,
	parameter CLOCK_FREQ_MHZ = 100,
    parameter NUM_DATA_LANE = 4,
    parameter PACK_TYPE = 4'b1111,
    parameter AREGISTER = 8,
    parameter ENABLE_VCX = 0,
	parameter FRAME_MODE = "GENERIC",    
    parameter ASYNC_STAGE = 2,
    parameter PIXEL_FIFO_DEPTH = 1024  
)(
    input logic           reset_n,
    input logic           clk,				
    input logic           reset_byte_HS_n,
    input logic           clk_byte_HS,
    input logic           reset_pixel_n,
    input logic           clk_pixel,
    input   logic                       RxUlpsClkNot,
    input   logic                       RxUlpsActiveClkNot,
    input   logic [NUM_DATA_LANE-1:0]   RxClkEsc,      
    input   logic [NUM_DATA_LANE-1:0]   RxErrEsc,
    input   logic [NUM_DATA_LANE-1:0]   RxErrControl,
    input   logic [NUM_DATA_LANE-1:0]   RxErrSotSyncHS,
    input   logic [NUM_DATA_LANE-1:0]   RxUlpsEsc,
    input   logic [NUM_DATA_LANE-1:0]   RxUlpsActiveNot,
    input   logic [NUM_DATA_LANE-1:0]   RxSkewCalHS,
    input   logic [NUM_DATA_LANE-1:0]   RxStopState,
    input   logic [NUM_DATA_LANE-1:0]   RxSyncHS,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS0,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS1,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS2,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS3,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS4,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS5,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS6,
    input   logic [HS_DATA_WIDTH-1:0]   RxDataHS7,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS0,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS1,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS2,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS3,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS4,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS5,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS6,
    input   logic [HS_DATA_WIDTH/8-1:0] RxValidHS7,
    input                 axi_clk,
    input                 axi_reset_n,
    input          [5:0]  axi_awaddr,
    input                 axi_awvalid,
    output logic          axi_awready,
    input          [31:0] axi_wdata,
    input                 axi_wvalid,
    output logic          axi_wready,
    output logic          axi_bvalid,
    input                 axi_bready,
    input          [5:0]  axi_araddr,
    input                 axi_arvalid,
    output logic          axi_arready,
    output logic   [31:0] axi_rdata,
    output logic          axi_rvalid,
    input                 axi_rready,
    output logic          hsync_vc0,
    output logic          hsync_vc1,
    output logic          hsync_vc2,
    output logic          hsync_vc3,
    output logic          vsync_vc0,
    output logic          vsync_vc1,
    output logic          vsync_vc2,
    output logic          vsync_vc3,
    output logic          hsync_vc4,
    output logic          hsync_vc5,
    output logic          hsync_vc6,
    output logic          hsync_vc7,
    output logic          hsync_vc8,
    output logic          hsync_vc9,
    output logic          hsync_vc10,
    output logic          hsync_vc11,
    output logic          hsync_vc12,
    output logic          hsync_vc13,
    output logic          hsync_vc14,
    output logic          hsync_vc15,
    output logic          vsync_vc4,
    output logic          vsync_vc5,
    output logic          vsync_vc6,
    output logic          vsync_vc7,
    output logic          vsync_vc8,
    output logic          vsync_vc9,
    output logic          vsync_vc10,
    output logic          vsync_vc11,
    output logic          vsync_vc12,
    output logic          vsync_vc13,
    output logic          vsync_vc14,
    output logic          vsync_vc15,
    output logic [1:0]    vc,
    output logic [1:0]    vcx,
    output logic [15:0]   word_count,
    output logic [15:0]   shortpkt_data_field,
    output logic [5:0]    datatype,
    output logic [3:0]    pixel_per_clk,
    output logic [63:0]   pixel_data,
    output logic          pixel_data_valid,
`ifdef MIPI_CSI2_RX_DEBUG
    input  logic [31:0]   mipi_debug_in,
    output logic [31:0]   mipi_debug_out,
`endif
`ifdef MIPI_CSI2_RX_PIXEL_SIDEBAND
    output logic [15:0]   pixel_line_num,
    output logic [15:0]   pixel_frame_num,
    output logic [5:0]    pixel_datatype,
    output logic [15:0]   pixel_wordcount,
    output logic [1:0]    pixel_vc,
    output logic [1:0]    pixel_vcx,
`endif
    output logic          irq
);
//pragma protect
//pragma protect begin
`protected

    MTI!#@wB2*mp+_$Y[QU~*<RC^*zZ=<*r,-leeFB:Gt/61=A_mR;>.Gmv3}Q{riA[;zM3h*~B$1*#
    u-rJTzr!Bse[jNm1jH,l5B}Okle3R^2os{,D_J}Nt_,]<cw7i?Gl-uu]V<*$v[Fx=D;CY^i^HZpK
    {wC+UTA{z5i|YVwuET[*nw<I|{U77^Ws5~$VGk<=ue,jTI]kwCKG\z--5N_U-U+7A~BX@]GxZBW[
    O}UEk'>U;V&{Y<UnU[[;tT*w[AXozb12Z3nRvHkparJoXnuIpK,,-$"Zs7*"m^Wv73{xU[32I3x~
    lK7]:[x3oQZ7muT\'n<E_zpED^OU2AoVaa-G@*9bG>{^jR+Oj_]{.Yn\#[ZRU@Dv^P1-{ee_O{UV
    v3VaU\liJe]7xiJs[*Z'JvBjW}-^CoGB2]eZC@:?^~nD*Z~iC+UX7sz\7?neVYs@-(Z|'IjUoVDW
    ;RVxO2-e7{QKlC[[Rffz;Ea+{=KeDD$~xE@wr-WTsiuV~-AG'G$iaQ3->rse[Ue!l1kE=o}a7{D*
    {>ooOvVG!'$1?K\?w~-~v3@IV+kK+=uuRnk6oI?Y_]}oEu7O7i__WO'D{CW2cU['*oREu}G?>Aj{
    ly{n!^~{sWz[~~&>5;nV7>KrB##}ns]=U$oLJ6}[-njH}**xuT=i{uU1U}s1T$[[GRqM=ja$xm_n
    WU=K\'Wl|+eTX{$?{I=!eWDvRAH'{Axk3\D[;1A1llUx'{^VT-E'_dVW3o,ZE+@=RTz,UzA_^}p;
    A]vICsp?@slBQun7BDQe[$o<]7IH{+T]pBswTpI~$QTrDwiGHHrnKrw1GJx@FC?oY%"@'[u@_JwJ
    oA2P]5XnR$~=,fn,]~_+ET^E?3kT}j,ko\'!Q?}D_EXsYHs1UH%6}_ouInW!AlO[8*}!GolYjuj]
    AURAn'u3~VGurEz-=27XBRvau]l[B>5mRO?aB,w\@f^pk[1Z+VO,?TXa_X~rr{J}_>I[<2_+E[#}
    {_0?e7[3]Q]rE}7XBRE~Sp0yjsIkIrAX1>o?27#V(Be}rt,uK*^2QkospD>\*GWe;=p$lw{[CpnG
    aZo?z5#e*VYprY{Ye;([2ITg:?NE~R<o*^]ow,!_iJ_vK>Ake\=Q,m>n[ER$vvkKR=+JIj{DUCK{
    XZZma-Cg7EKE5Q3wDZ++)o*$mTnGE'D{{Zo},~p<''laa$t+]D<^m>zgGIWx}]?no_,2Z'xkG_i^
    Ds,a_ri,_+CW5}j_lRi{[,+<'kuYezBYw}+Zu=7#-{-uIC>W'^'I=sj}Uj1u[~CRBiZ,*;!WE1!O
    n*OKj7BiaR{2PlGKoz3HWo_YXGR-rpk]iFfAoiDD~>?X]}~TrZ\xxi'pBU!=msX$l7On]]2k^[Yi
    QimB=k*.K>u,Ar{W,<]l#lH;a[mlJ+R2oVm_+ej#I2K;k.JjwuBBiO;[T~$kDX,?uJ+<s>CX'7*B
    @aCHzAwTr^Z\oGo{B2wRwU:k\7Iq[]loe=pjk1@A]maW\jmarI\5I;vBIsja]-m=[T+Zook[z@2<
    [$1\B+Y]_&5-1-AVw[z]B?o_U]1kBj7#1;]25xp3X^tAIAJv3aBIJsxH,On!\m=?j!-}Y*Y7eBV>
    \JY;o~-I_,X3U5aCvi@ef$@!KUB[KSH{^K[@~To-,zz2*7WXODrBQD'a\*,eZV*~}jDu]3E{~wVa
    nWX}v1;5Opc;_<>R&E^2p_;rOl@A3kj];13]JQ?_!OJvOpkDDrB8vKOnnH,R;5-xp#^pAGa_D5'C
    oXA]-]xmgo7#H&Q{_}_1#A}ClDj7el{C-7\#j{[_X@X]o=B*1rx!Yi!o,v^:{UBEKwKB77]Ilx{[
    Io]Jll[^)pz_iD7x,}e@^9='=W!$u\[Hjw1TG7RR^75+Qmf~o[vp23_;jDI;em?67sHx=C3~6J*+
    1r[@3OA+$[wvjJ7]UG}DnLQiQHrpV~,nRrN]CxO_s~[oGpw\ej_QZ5^+.7WDA+=5QKs<BqZoBKTO
    zE+T1X+'R5H}{!Wr?Ety_XaKU,$rm5aZ^2\{9>lwX2TT,BXvQ>,@7V3@CW+;?2EHrn5n\6)E5#Jx
    [k{_#Q]#C+#|_?rR7=_+AxUU'oI?G$}J*>=#Xw=n<v7~so<U;lU'iXH2*Z!2?QnW7em5ze~l>_+7
    ~YX5qY@v3x@\_O-!;}VDG3-;E1K{nED\2B_xB=rxu}d?Vn!Q^=Qv-_;$Yk@YQ1udVHYp[nB=kw'3
    -BwrN]R!TxQz]zZn^z<b1oe\n+Ye'EH?I;C2>}Z3I,!pU^wTk8Qv]imXHG}o$Q(EHz2O'-o(C]^J
    [Xn^77kZGDw*zn+~z'_G_anOe{l\7Q[#{pD312A,Q=k^OWK\v*x*x25ZI@I!hXEK2Ru+Bv2;3w'v
    'fj=a~dkI]n:pZV<c#B!!TQQ#G,XDZEZ{<A[~Ql<OBBYnlm5K=j[\mX}i3\+_Q#Gp}IGKlU3wis1
    'rHK@r+,#lmOOYQ@Corj]V[ne!=kl*YGU_7j]Dn;RI{lxYWD*7^TZc'[Yayd;}<+ark~d5l1Cx5!
    VYe<];s*Gkx]]3,^aT-Del[\<]!OAEU2}#C3ER7\=DK+]2l>EBznQ-sTGX+lwAXH-/*Aa!lX2V2r
    +W1I@!12T1NZIAx2*{'+U7uVA>2Oz-=sYYO=cC@ED0[;DKi<GITUriQjEuj_E\CO]${U^2Ri{?'H
    pX7?Q*A[?\J\_=jH3V},3n$ImQYnHr\I1>2rB#A*nR}IkUZ,BYD+U5v1?m!}Du@*YGjke<i$J>E^
    7j$mBW$m=rXa;*p[YIZa,/Se'w[BvZkpxRoUY7[z]i;\A!,I[{Zs$\p8+[rGKCjp;,i?(AYYVz\Z
    {Ao#}I;Cu!{,^>XV].owzC"K+Ijl_~2;<*@UO2Qi5r]X}Dr'];s.kx*Zf\^xuJTT}s;$>iT{pP\A
    +U{zO]u{5U^#J$1WZ]G>v*?7Az$-\!-{!}+[G[pmY=l>-'wUYrU<U71CKx^{QY\_Dori$pB@x*i[
    irxiWEk{H0i*@#YvQU#^^lHU~vR-Hp>skorC?=z~WZavjl.CVj]xW{7C^{}Oaa!s7~{$5!KT*UI\
    ZO^WGu~is@mBQpB}R{TaQ'O@ET<mlvj7V@>]wR;d,@!}H-{]?UvEq->~2Jj;#VxATkAD$f:u7Gu}
    eTAQT$i>xwmx]ZVdYUm*$~a{P<Os{S7eOCIs2Z{}$n0j!H!U'?=J_OeDzr{Q2-}_2ZkaC{V!X\[D
    B3aY=]pr?7nAVs@1OoGnrj{~>l3(CWJsInXH@U[joCmvbEYGoaX}{2a*Kkl'mg}2ju?<$i>aJCCu
    Zb~Tp5J}I>keD!Clap#Y#a_$AsQYG=E@*7YW<v}~,<-O!up!$z#$B'i5@![7Xac^>n7r[7DGVomG
    kCXY@I]aVG]D2EjUqP$-Z+_aE~fkoJ!^jkQ7+u$3sunZH<sTTz1r!e71@>B]v,O~s3Kn,=?C@l{I
    J<mo~*n;<<}CO1ax3w^W5i>wo,np~1ui(~r^7+j[Y\#X^\3oa[I7{=jn3=OU<>[k$'UO<@v>WT8D
    e;Ga'nvjuYvYk-Ei[$l$_HO=iOEoK\ozMKDk#arZlEB'a)l-Ypa*pU-{T5EQk5^#YkS?E_Tj_eTw
    IXADMp=2]Y$?HjZEZw+^Q53!p6c]mBl"_>I;m{nGE~Ze_,ooUCE[OxTrIv!*#C3Z*7Dn9&~XHJJ+
    r<D_jEQVmr'rl{[[v#=H2J2e~3'wX?.;5izXzO=#<on+lir5JJs}nV@w-A'=ju~']j_oRWQj^~ox
    vEJKw'EC,RuVX5usX,E:1{_#Y\XxeCV{Z]r]$Q[3jr#O*jX!Oj+I;BD@f*!RY2wB<8T_7>V3A,Xj
    jGtsT5GlEGnn1wx4x@QJesnI*[}]oA]UD#}u!a5#\P7W7\Y;K<-O+uz]>Gu,*r~'<m'}e3[ro-?w
    A?><l55GXrHCn@)vXlZ@*Amm^UOx,[1Ov1<1B*}6GZR=}lX^=Y#vZR+w3OXa+x>>v\_+w_jOp$@a
    V*+C>|w}n[][lKueor'GQQLm15n{TZa|g*;p;(FACKU@B?[H1<G_2Q_KY$@?*Ze[<<G>nR}UDB\,
    \X@O#ur>]7<?RW2Y<{o1A[Za={<#\iJ(m<v]u=HXErTs^Y+wbe$1TyQGj?\3=nj@jR21^_RKOm\'
    3zWTmei^A;uD_B_ZKn\?*51+eDb%=@U{VaD^~$s_ap-=QxD-^Pu{zTQH<l28X}^\qXH[l'7K\KOU
    UjY^K__Ew|unT^lAsCeH2}5Q-x,;2\D'IZU^{nf/T_>kdmI<p1<~Yf!}]Hm$TI!]ix#l;ITXQrz[
    $#?5WB;VVaw5TjpKX'lo}K%]XYow{KrnAr!3^AZ'*up<DTEOO7lxp!_3snH<UK3sQ}u_p1uOCr2:
    A${3=A*?R.~7^\]D!s1^_2j7+7f\7i]w}Aaz73YGs5oHY'KB3Z7*ow-Y*\D}>Qk{vz^2a$#Q]-m^
    ^z+IBr's>[Yy3_u-u\{Vv-G7Iu5EH=3V"T};V~5@U-j[n3QsJ!w$]jaDG#OWU;n+;D;CO}Qu,5zT
    YoY#Q7zjJtn5rAYB<YWYvU\ZKwL#Q7ZsEaj,xA_zeAa^kXl}$o@3HY-t@<J<]Kn2*&x+Y=%y3n<x
    GO]wUOWuU-xos=\'4tRDDY[=]<Q-n+7i7!~xEV*Z+A1^Br@*<1kw7\r=sTUX<+Uo{A5AGw71#j(H
    a$e'C_x5u<{Y3YB55ReqT^snViCo8~H=RTj{vQXVkI{5vhU_AW2wVZ13Q=WsvTD!sz$np2(G$W@H
    nv~t'k2}2lx;-v5jo[{p#hH$<GB3pCz*MVzo;xoBTABli7+B#eJ;JsnY2bT1TH$KY'Z|z?7nA8Iu
    'j1ZY$n$n+Z+'rpr{}>rzx1k-adM8{}DEN7Rl="v>=HRiYlQ4\K3HoXrU>CG\E|zZpaBlmv+Ep1n
    j\vj!37slzKgCA3nnOJnj!^~F2v]@'-WI^rHsJxm$psmA,mD=4_D+mHCl!$-AwoH[G_+@*(rY>mP
    z(c\IZI;sk<&IX*-var#&{arHv!xQ='pO_BGzDBkUE7H'<eJzw[]W[K<Yd[kz]P=rX\V3QI}EB$y
    +R*Bu${TGGsJpo*s%]G2IE+v^m'Tx-Ue~YCZR5XZZ{z=#k{{o=v*@~U'2,DinXY#oj^$-s$=H[<5
    EJ7\JI?R$%5Rm@fHjT[*>VvD$!sgkx{v[OYa2Rjkoi[wl@U[YE~H,V<w1vQpZ'wnz_n@w[#^Hsn{
    aR[Ro,^p1lzeEzV=zo'\kj>Jnj]D^VAUs$+O\QjeO_[{*-2D@QEG^[Gj]$_E~1W]+{pWh>']m^=Z
    $l/C}w5=!~}QEH-Bw>I"l-^xqo!\ZiDC-yvxW$5u5!$JGY[QKrx*An,c!Q~UZ*,^<a-U0*;C$A}K
    rloQ2k<rKv>=]Vk+xqoo-JI#Ikvxe=+1?D#U$D.a^1m%5uJ1GeJW7Hjp}$A<XH3vu>ZOD~*]IuU~
    vsi2diaW$:^*,Ca,Y{^;{uj#WWkz~32'=<s)o}rr2^=U=32{x;Ol_u^Z]A;?\em$sx@{ozKz$v[s
    1-WkR$xG=3n3wXIRE}XHTev@]Conv$$k*>CO<GrZw=v=@QD,usZm>IkTez#;r,X_K\#C,C?;C;pK
    u=1IsJ,n5X]n*1!uqw{]Bbs3vW'r]uUTwvl[WA{}T[;A=BAU{\MA}_[311m~O:ww+nJOu7@C}ZPZ
    <m]_ZC_L;jZUXYQ21'a![@~us2$T=PiopocQlH@8GsC$_R2IGIJQqXU}Ci}Xjy6_1!Xi's=3C{pg
    n$spJBI7{l}KaasB^=CK=>QoUDQev#ppcW{j='HX7pz-}noX*zCJn)KswpL=#Kzr<$D.0@s'?^\]
    _^l=W>=lQ2'V_J^C-7vYU-Ynk&;H@}[UrjG<O^W<>2{-pOC$OGG#e@{wK{>n@^#5vO[[2_DR@x,a
    $C#sx-3B5wcQ[aA{E_+%?>31Ez#o\sHWIl?^UVVE,Hx1<=]R_5U$~Y\J*;V#Kve\$CQ[97_sw1Q?
    JIOZ,r'\ze;OIH'c'OJH>-+!s{j~UrA^(=np$+OrVXlk]2GT;}-GrTTxWs+-XA-E'"['-X7~KU3[
    *[TY_=WHC?o'kE*#ra_Q>}OYQZ=nzkY-svsComN>T\#)k\'xG2e2iV[='\*vX',uN3AY?},322=D
    mV^~mj2l*eslz@UCz2C6r]=C}2K>w}\K*kO@Vx;!iV?EVBDn?[WC!sa=U+7-$2Oef=^RBy\(\,<s
    ls@$vV\Up!-oa,{#ups}WH@lD*]miG+v2<n<1AWpJD\]\V+C7OijN9d3X\}l{+V7GlCXO!+^_D,O
    +VC@eHOTCGY?Xr-a,EI;AOJmw=z;UH!>D'l~7RG\7x[jEJ\UX<V0,_=TbuY$\mAl2<w1CEx+_V_=
    !H>2]zn~~T}G'v7+O^C%9s!*v!XG3
`endprotected
//pragma protect end
