# 七项拟合/距离：子运算与寄存器复用中文草图 v0.1

2026-10-06，纯设计，NOT_IMPLEMENTED/NOT_RUN；关联FIT主卡v0.2的F-B02。本页是可读的数学/沿步骤表，不是可执行脚本、ROM微码或已生成的RTL。七kind均保留，原source与ANGLE待批基线不改。

## 1. 先理解共同提交规则

父只拥有当前外部请求及16个192bit工作槽w0…w15。每步的操作数在形成命令前已有效，命令按主卡的406bit规则保持到bridge接纳；实际子请求/序号由bridge管理。WAIT_RETURN看到桥缓存valid只决定去QUALIFY_RETURN；下一沿检查旧403bit缓存并真实result_fire，再写唯一目的。ADVANCE再使用新槽，不能同沿写完立即当旧值读取。

一沿最多写一个工作槽。局部MOVE/SHIFT/NEG也各占提交沿：先在192bit或必要扩展域形成真值，按所列类型查高位零/符号再写。不是隐式截低位；SHIFT可能需要比原类型多shift位的真值域。w15复合字段也只一沿一次写，anis/μ各有有效位。

类型记号uN无符号、sN二补码。MUL/ADD两输入全u则result unsigned，有s则signed；SUB恒signed；DIV_RNE的分母已正、按u传，分子按所列符号。COMPARE返回0相等/1小于/2大于，高位0，target2。SQRT_RNE输入u、B0/flags0。写u槽时完整385值高位必须0；写s槽必须全符号扩展。目标宽度是私有算术容器，不抢先替代父的几何/normal/质量守卫。

所有逐连接slot在新父请求时先清有效性；不必功能清零3072bit数据。写入时形成规范192bit sign/zero扩展。没有当前有效slot不读取为零统计。父PACK只能在所需slot/字段均有效、private pending0且桥quiet时形成外部结果。

## 2. 圆LS与LS诊断（kind11/17）

输入从外部held payload读取：n21/Au43/Bs44/Cu43/Ds56/Fs56，kind11另det_min u16。先做n/输入资格；具体错误矩阵仍主卡F-B04，不在此借表顺序掩盖尚未冻的分类。

| 步 | 运算/输入 | 私有target与目的 | 结果使用与守卫 |
|---|---|---|---|
| L01 | ADD A(u43), C(u43) | 44→w0 u44 | T，保持至质量分母形成 |
| L02 | MUL A(u43), C(u43) | 86→w13 u86 | AC，下一产品形成期间保持 |
| L03 | MUL B(s44), B(s44) | 88→w14，检查非负后u88 | B²全宽，不能当signed负值 |
| L04 | SUB w13(u86), w14(u88) | 89→w1 s89 | Δ；≤0局部退化；T>0后再后续 |
| L05 | MUL T(u44), T(u44) | 88→w2 u88 | T²，非零；保持至最终quality |
| L06 | 局部SHIFT：正Δ先宽扩展再×4 | 检查u88→w12 | AC<2^86使4Δ<2^88；真值检查后才收 |
| L07 | MUL w12(u88), 65535(u16) | 104→w3 u104 | quality分子，保持至最后除法 |
| L08 | 仅kind11：MUL det_min(u16), w2(u88) | 104→w15 u104 | 条件门右侧 |
| L09 | 仅kind11：COMPARE w3(u104), w15(u104) | 2→w11 u2 | 左<右拒绝；等号通过。17不执行L08/09 |
| L10 | 仅kind11：MUL D(s56), C(u43) | 99→w13 s99 | DC；原AC已用于Δ可覆盖 |
| L11 | 仅kind11：MUL B(s44), F(s56) | 100→w14 s100 | BF；原B²已用于Δ可覆盖 |
| L12 | 仅kind11：SUB w13(s99), w14(s100) | 101→w4 s101 | Nx完整值 |
| L13 | 仅kind11：MUL A(u43), F(s56) | 99→w13 s99 | AF覆盖过期DC |
| L14 | 仅kind11：MUL B(s44), D(s56) | 100→w14 s100 | BD覆盖过期BF |
| L15 | 仅kind11：SUB w13(s99), w14(s100) | 101→w5 s101 | Ny |
| L16 | 局部SHIFT Nx×16 | 宽算/检查s105→w6 | Q4分子，不借旧s101直接窄移 |
| L17 | 局部SHIFT Ny×16 | 宽算/检查s105→w7 | Q4分子 |
| L18 | DIV_RNE w6(s105), 正Δ(u89) | 106→w8 s106 | 宽cx商；下一局部沿查s18域，域外GEOM_RANGE，不请求target18 |
| L19 | cx域通过后DIV_RNE w7(s105), 正Δ(u89) | 106→w9 s106 | 宽cy商；下一局部沿查s18；不在cx失败后继续算cy |
| L20 | 所有kind：DIV_RNE w3(u104), w2(u88) | 17→w10 u17 | 查≤65535后收quality16；kind17由L07直接跳到此 |
| L21 | PACK（局部控制，不写slot） | kind11中心/n/quality；17仅n/quality | 385bit padding0，旧w8/w9只能11读取 |

T²−4Δ=(A−C)²+4B²保证quality≤65535；未运行除法不先拿舍入quality作条件门。w0/1/2/3有效保留到L20；w13/14是两个顺序临时产品，只有旧产品已消费才重用。w11条件code与w15右侧门在L09后死亡。不会额外保存第二份LS263。

计数：kind11最多17个已接受私有算术调用，kind17最多7个；局部SHIFT/域守卫/PACK另计，不把调用数当沿数。诊断不进入L10…19。

## 3. TLS与TLS诊断（kind12/18）

输入n/Sx/Sy/Sxx/Syy/Sxy及kind12 anis_min，均从旧held payload读取。w15约定bits17:0为μ s18，bits33:18为anis u16，bits191:34零；两个有效位分别管理，不把整槽当signed数。

### 3.1 协方差、PSD、D/R与质量

| 步 | 运算 | target与目的 | 资格/寿命 |
|---|---|---|---|
| T01 | MUL n(u21), Sxx(u43) | 64→w13 u64 | n≤N使积<2^64 |
| T02 | MUL Sx(s33), Sx(s33) | 66→w14，非负作u66 | 最负平方也不丢最高bit |
| T03 | SUB w13(u64), w14(u66) | 67→w0 s67 | Cxx，保持至PSD |
| T04 | MUL n, Syy | 64→w13 u64 | 第一乘已消费才覆盖 |
| T05 | MUL Sy, Sy | 66→w14非负 | 第二平方 |
| T06 | SUB w13, w14 | 67→w1 s67 | Cyy |
| T07 | MUL n(u21), Sxy(s44) | 65→w13 s65 | 原临时值已过期 |
| T08 | MUL Sx(s33), Sy(s33) | 66→w14 s66 | 有符号协方差项 |
| T09 | SUB w13(s65), w14(s66) | 67→w2 s67 | Cxy，PSD前不收s65 |
| T10 | 局部查Cxx/Cyy≥0/高位，分别收u64 | w0/w1各独立提交沿 | 不同时写两槽 |
| T11 | MUL Cxx(u64), Cyy(u64) | 128→w13 u128 | PSD左侧 |
| T12 | MUL Cxy(s67), Cxy(s67) | 134→w14，非负作u134 | 原s67全宽平方 |
| T13 | COMPARE w13(u128), w14(u134) | 2→w12 | 左<右INTERNAL，成功后才局部收Cxy s65 |
| T14 | ADD Cxx(u64), Cyy(u64) | 65→w13 u65 | trace；0退化 |
| T15 | 局部trace<<16 | 检查u81→w14 | anis分母，保留至T26 |
| T16 | SUB Cxx, Cyy | 65→w3 s65 | u，保留至t分支 |
| T17 | 局部Cxy宽扩展<<1 | 检查s66→w4 | v |
| T18 | MUL u(s65),u(s65) | 130→w7，非负u130 | u² |
| T19 | MUL v(s66),v(s66) | 132→w8，非负u132 | v² |
| T20 | ADD w7(u130),w8(u132) | 133→w5 u133 | D；0退化，原两平方可覆盖 |
| T21 | 局部D<<32 | 检查u165→w7 | root输入 |
| T22 | SQRT_RNE w7(u165) | 83→w6 u83 | Rq16，必须完整根 |
| T23 | MUL Rq16(u83),65535(u16) | 99→w7 u99 | anis分子，原root输入已消费 |
| T24 | 仅12：MUL anis_min(u16),w14(u81) | 97→w8 u97 | 门右侧 |
| T25 | 仅12：COMPARE w7(u99),w8(u97) | 2→w12 | 左<右ILL_CONDITION；18跳过T24/25 |
| T26 | DIV_RNE w7(u99),w14(u81) | 17→w12 u17 | 质量高位守卫≤65535，下一局部沿写w15.anis并置有效；μ字段零但未有效 |

kind18到这里PACK n/anis，决不启动下方几何。T13完成后w13旧PSD乘积、w14旧Cxy²才可覆盖；T26后trace和分母已无用，但Rq16仍需用于构造t。正常n/PSD/D路径与合成错误路径分别覆盖。

### 3.2 t/L、归一化与规范方向

| 步 | 运算 | target与目的 | 资格/寿命 |
|---|---|---|---|
| T27 | 局部u(s65)<<16 | 检查s81→w7 | T26的anis分子已消费 |
| T28 | 局部v(s66)<<16 | 检查s82→w8 | 原anis门右侧已消费 |
| T29a | u≥0：ADD Rq16(u83),w7(s81) | 85→w7 s85 | tx；ty由w8下一局部沿规范s85 |
| T29b | u<0：SUB Rq16(u83),w7(s81) | 85→w3 s85 | 暂存ty，旧u只剩已锁分支flag，不再读 |
| T30b | u<0：局部MOVE w8(s82)→w7(s85)，再MOVE w3→w8 | 两个提交沿 | tx=v<<16、ty=Rq16−u<<16，不同沿交换，不毁临时ty |
| T31 | MUL tx(s85),tx(s85) | 170→w13非负 | 原trace已过期 |
| T32 | MUL ty(s85),ty(s85) | 170→w14非负 | 原anis分母已消费 |
| T33 | ADD 两非负u170平方 | 171→w12 u171 | L被开方 |
| T34 | SQRT_RNE w12(u171) | 86→w9 u86 | L>0，不用θ9近似TLS |
| T35 | 局部tx(s85)<<30 | 检查s115→w13 | 归一分子 |
| T36 | DIV_RNE w13(s115),L(u86) | 116→w7 s116 | 下一局部沿核±2^30并收s32 |
| T37 | 局部ty(s85)<<30 | 检查s115→w14 | 第二分子 |
| T38 | DIV_RNE w14(s115),L(u86) | 116→w8 s116 | 同样先全商再normal资格，不请求target32 |
| T39 | 局部raw nx=−w8、ny=w7 | 两个提交沿→w10/w11 s32 | 取负先扩s33，核Q30域 |
| T40 | 锁反号flag：ny<0或ny0且nx<0 | 若需反号分别NEG w10/w11 | 不在反号一槽后重判flag；各独立提交 |

输出切向始终t=(ny,−nx)，由最终w11/w10规范normal导出。原w7/w8中的未规范t在T40后死亡，可供rho/μ临时运算；不能PACK这两个已重用槽的旧t。L在两个归一商完成后死亡。Q30分量与K下界的数学依据见数值审查，实际守卫仍保留。

### 3.3 rho先检查，再μ，最后K/M

| 步 | 运算 | target与目的 | 资格/寿命 |
|---|---|---|---|
| T41 | MUL nx(s32),Sx(s33) | 65→w13 s65 | rho统计项 |
| T42 | MUL ny(s32),Sy(s33) | 65→w7 s65 | 未规范tx槽可重用 |
| T43 | ADD w13,w7 | 66→w3 s66 | rho第一和 |
| T44 | MUL nx(s32),(W−1)(u11) | 44→w13 s44 | 第一产品已消费 |
| T45 | MUL ny(s32),(H−1)(u11) | 44→w7 s44 | 同上 |
| T46 | ADD w13,w7 | 45→w8 s45 | origin normal项 |
| T47 | MUL w8(s45),n(u21) | 67→w13 s67 | 分子origin部分 |
| T48 | ADD w3(s66),w13(s67) | 68→w3 s68 | 完整未舍入rho和 |
| T49 | 局部宽SHIFT×8 | 检查s69→w3 | 用Q30分量/字段实际界证明s69，不在s68内先移 |
| T50 | 局部n(u21)<<30 | 检查u52→w4 | 正分母，保留至μ完成 |
| T51 | DIV_RNE w3(s69),w4(u52) | 70→w14 s70 | 下一局部沿查s18几何并收rho；失败不算μ |
| T52 | MUL ny(s32),Sx(s33) | 65→w13 s65 | μ用规范tx=ny |
| T53 | MUL nx(s32),Sy(s33) | 65→w7 s65 | μ的负切向项 |
| T54 | SUB w13,w7 | 66→w8 s66 | txSx+tySy，ty=−nx |
| T55 | 局部宽SHIFT×8 | 检查s69→w8 | 不先舍入均值 |
| T56 | DIV_RNE w8(s69),w4(u52) | 70→w9 s70 | L已死亡；下一局部沿查μ s18，再写w15低18、保留anis并置μ有效 |
| T57 | MUL nx(s32),nx(s32) | 64→w13非负u64 | 原μ第一产品已消费 |
| T58 | MUL ny(s32),ny(s32) | 64→w7非负u64 | 同上 |
| T59 | ADD w13(u64),w7(u64) | 65→w12 u65 | K；核≥2^58，不能把坏normal输出为距离 |
| T60 | SQRT_RNE K(u65) | 33→w13 u33 | M |
| T61 | PACK | nx/ny=w10/w11；tx=ny/ty=−nx；rho=w14；μ/anis=w15；K=w12/M=w13 | 核所有有效资格；278bit有效+107zero |

这条顺序保证rho几何先于μ几何检查，所有输入stat来自旧快照；输出t不引用已复用的w7/w8。µ写w15时只改低18且保持anis16，上部158零；两字段有效性不互相替代。

## 4. 两线交点（kind13）

先核两normal分量/零/K，K用每条线的两signed32平方（target64）和ADD u65；不用sqrtM，因为交点式不需要它。两线K都检查完才进入分母。

| 步 | 运算 | target/目的 |
|---|---|---|
| I01/I02 | nx0·ny1、ny0·nx1，s32×s32 | 64→w13/w14 s64 |
| I03 | SUB 两产品 | 65→w0 s65=den；0局部退化 |
| I04/I05 | rho0(s18)·ny1(s32)、rho1(s18)·ny0(s32) | 50→w13/w14 s50 |
| I06 | SUB 两产品 | 51→w1 s51 |
| I07 | 局部wide SHIFT w1×2^30 | 检查s81→w1 |
| I08/I09 | nx0(s32)·rho1(s18)、nx1(s32)·rho0(s18) | 50→w13/w14 |
| I10 | SUB 两产品 | 51→w2 s51 |
| I11 | 局部wide SHIFT w2×2^30 | 检查s81→w2 |
| I12 | 若den负，分别wide NEG den/w1/w2 | 正den检查u65→w0；分子检查s82→w1/w2，各提交沿 |
| I13 | DIV_RNE w1(s82),w0正u65 | 83→w3 s83；下一局部沿查x s18 |
| I14 | x域通过后DIV_RNE w2(s82),w0 | 83→w4 s83；下一局部沿查y s18 |
| I15 | PACK x/y | 36bit有效+349zero |

负den同时变号，在更宽域做以容最负值；几何检查在完整商之后，不clip。normal各K前置的具体错误优先次序仍随主卡F-B04冻结。

## 5. 精确法线距离（kind14）

normal/domain/图内point先核。槽：w0K65、w1M33、w2f50、w3q0/最终q21、w4F4 u102；w5候选odd22、w6square44、w7bound109、w13/14临时乘积、w15compare2。

| 步 | 运算 | target/目的与顺序 |
|---|---|---|
| D01/D02 | nx²、ny² s32乘 | 64→w13/w14非负 |
| D03 | ADD 非负产品 | 65→w0；K≥2^58 |
| D04 | SQRT_RNE K | 33→w1=M |
| D05/D06 | nx(s32)·x(u11)、ny(s32)·y(u11) | 43→w13/w14 s43 |
| D07 | ADD 两产品 | 44→w2 s44 |
| D08 | 局部wide SHIFT×16 | 检查s48→w2 |
| D09 | 局部rho(s18)<<30 | 检查s48→w13 |
| D10 | SUB w2(s48),w13(s48) | 50→w2=f |
| D11 | 局部扩s51后取|f| | 检查u50→w13 |
| D12 | DIV_RNE |f|(u50),M(u33) | 21→w3=q0；还不是最终q |
| D13 | MUL f(s50),f(s50) | 100→w14，非负u100 |
| D14 | 局部wide SHIFT平方×4 | 检查u102→w4 |
| D15 | q0>0时形成2q0−1，否则跳过低边界 | u22→w5 |
| D16 | MUL odd(u22),odd(u22) | 44→w6 |
| D17 | MUL w6(u44),K(u65) | 109→w7 |
| D18 | COMPARE F4,w7 | 2→w15；低于或等且q0奇时登记修正−1，跳过首次高检查 |
| D19 | 未选减时形成2q0+1 | u22→w5 |
| D20/D21/D22 | 同两次MUL和COMPARE | 44→w6、109→w7、2→w15；高于或等且q0奇选+1 |
| D23 | 局部宽q0±1或不变 | 查u21→w3；最多一次修正 |
| D24 | 对新q重复低/高边界，两边资格检查 | 复用w5/6/7/15；q偶允许等，q奇严格；不再修正/迭代 |
| D25 | PACK q/K/M | 119bit有效+266zero |

初次高边界可在已确定减1时跳过，但最终两边资格不跳过（q0时只跳无定义低边界）。|f|与nearby阈值都全宽，inlier/nearest侧归R4，不截q16。本最终真实距离half不可达证明不用于删除D12整数M除法的half-tie测试。

## 6. 有限边距离（kind15）

slot配置：w0/1 p_x/p_y s19，w2/3 d_x/d_y s19，w4K u39，w5z s39，w6c s39后可复用odd u20，w7N u78，w8D u39，w9F4 u80，w10lo u19，w11hi u19，w12mid/最终q u19，w13/14临时产品，w15compare u2。N/D/F4在搜索和最终资格期间始终保留。

| 步 | 运算 | target/目的 |
|---|---|---|
| F01/F02 | SUB 16x(u15)−Ax(s18)、16y−Ay | 19→w0/w1 s19；16x/y先扩位形成 |
| F03/F04 | SUB Bx−Ax、By−Ay | 19→w2/w3 s19 |
| F05/F06 | MUL dx²、dy² | 38→w13/w14非负 |
| F07 | ADD 两平方 | 39→w4K；0退化，其余小K合法 |
| F08/F09 | MUL px·dx、py·dy | 38→w13/w14 s38 |
| F10 | ADD 两产品 | 39→w5=z |
| F11 | 局部比较z≤0/≥K/中间 | z先sign_extend40、K zero_extend40，不将u39直接cast s39 |

分支A（z≤0）：两MUL px²/py²（target38→w13/w14，非负），ADD u39→w7并zero_extend规范u78，下一局部沿w8=D1。

分支B（z≥K）：分别SUB 16x−Bx/16y−By（target19）覆盖已死亡p；再两MUL/ADD同分支A得到N，D1。原A向量在这个分支不再需要。

内部：MUL px·dy、py·dx（target38→w13/14 s38），SUB target39→w6c，MUL c(s39)² target78→w7并核非负u78；下一局部沿MOVE K→w8D。C在形成N后死亡，可覆盖为odd。禁止把K/Q4边线反向规范成Q30 normal。

| 搜索步骤 | 局部/私有运算 | 目标与不变量 |
|---|---|---|
| F12 | 宽SHIFT N×4；分别初始化lo0/hi524287 | w9u80、w10u19、w11u19；各独立提交沿 |
| F13 | lo<hi时mid=(lo+hi)/2 | 和u20，收w12u19；lo=hi则进入最终q |
| F14 | 局部odd=2mid+1 | w6u20，不在u19内先加 |
| F15 | MUL odd(u20),odd(u20) | 40→w13u40 |
| F16 | MUL w13(u40),D(u39) | 79→w13u79，原odd平方已进入锁定命令后可在返值时覆盖 |
| F17 | COMPARE F4(u80),w13(u79) | 2→w15；less或equal且mid偶表示q≤mid |
| F18 | 按旧compare/mid提交hi=mid或lo=mid+1 | 写一个槽，只有真实比较返回后计循环；区间严格缩小、最多19次 |
| F19 | lo=hi时MOVE lo→w12最终q | 不把最后测试mid当结果 |
| F20 | 上界odd=2q+1，两MUL/COMPARE重复F14…17 | q偶允许equal、奇只less；失败INTERNAL |
| F21 | q>0时下界odd=2q−1，两MUL/COMPARE | q偶允许equal、奇只greater；q0不形成负odd |
| F22 | PACK N78/D39/q19 | 136bit有效+249zero，原N/D不换成归一或约分后的另一表示 |

对真实端点/内部分支，Cauchy与Q4输入域给q<2^19，所以hi覆盖唯一结果；最终上/下界再核，没有“满19次即成功”。循环compare若code3为不合法响应，按父内部错误处理，不选默认分支。四边nearest仍NiDj/NjDi u117及tie低侧号，属于父R4而非本核偷偷写入的分类。

## 7. 还需补齐，不能提前标READY

本表覆盖七kind的算术与slot顺序，两个诊断在自己的质量节点结束。单核全资源/最大私有调用次数与最长形成沿、全部模式控制状态/首错矩阵、字段有效性守卫、source/probe与测试/文件基线仍应纳入主卡F-B02…04审阅，不能以表完整宣布RTL或整体设计已通过。

下一步针对本表逐连接核目标宽度、signed标记、每个临时值实际死亡点和一槽一写规则；按具体子步骤生成未来测试覆盖文字，但未获指定批准前不生成任何源码/TB/参考/执行表。本页保持完整识别与原1080p目标，独立数学/桥验证不替代Canny/DDR/相机/HDMI与整包闭合。
