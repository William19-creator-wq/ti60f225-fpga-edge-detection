# TRACK4-RECTANGLE-REFINE-001 v1：完整旋转矩形的分段、六遍 TLS 与三/四边

2026-10-11。LOCAL_DESIGN / PARENT_READBACK_PENDING / NOT_IMPLEMENTED。本轮只写短设计，没有 RTL、TB、功能脚本或 EDA。引用用户持续自主推进、整合优先、免新增长草图与独立测试、本地审计；不冒称指定版本已获用户批准。父读回后再指定首块的编码范围，当前不得实施。本卡按 PLAN_TEMPLATE 合并必要字段。

- Goal / Target：复用现有完整 LINE、POINT V2、唯一 scalar、STATS/FIT/ANGLE，完成 49 offset/run、TLS0/1/2 严格六遍、全部 PAIR、任意旋转四边/三边及整短边缺失路线；随后按冻结量化边核验 RECT。原五基础六高阶与原场景保持。
- Current / Gap：主包已有 Hough/NMS LINE 与数值核；没有 coarse SEG、六遍细化、PAIR、完整 RECT 及其接入。CF 圆候选为独立静态通过，仍非主包 A6 完成。
- Assumptions：Ti60F225 V4 + SC431HAI，1920×1080，E≤2073600；单 core 正沿、同步高有效共同 rst，可暂停内部 DDR/NUM 请求；显示使用最近完整结果。没有新增第二 NUM、第二 STATS/FIT/ANGLE 或 DDR512 FF 快照。
- Dependencies / Open：父调度真实 DDR/PACK/NUM/ANGLE/geometry lease；阈值/guard 配置与同帧 LINE META 一致；全后端的资源/时延、质量、FINAL/ANN 接入未闭合。首块数值回调可独立推进，整机未标 READY。
- Milestones：短卡读回 → 首块 line-point 数值候选 → CELL/EXT 工作缓存及 coarse → 六遍 TLS → PAIR/组装 → 冻结 RECT 核验 → 父接入与实际 Efinity。每次只落实明确增量。
- Failure / Rollback：数值局部退化拒绝当前段/候选；计数/重放不一致、真实容量、格式或完整搜索预算未完成为整帧失败；UNKNOWN 保持归属直到共同冷复位。候选不改主包、058 冻结输入、031交付物、原资料或数据库。后续回退候选不覆盖历史编译证据。
- Completion：完整循环、真实写回/关闭和父整机证据均需成立；代码/静态走查不能证明 95% 质量、实时或实物效果。人工下载/观察仍由用户操作。

## A. 来源、基线与实施边界

旧完整设计阅读顺序：[R4 E4–E7](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) → [ALGORITHMS OP04–07](design-TRACK4-RECOGNITION-ALGORITHMS-001.md) → [EXECUTION OP04–07](design-TRACK4-RECOGNITION-EXECUTION-001.md) → [NUMERIC E5](design-TRACK4-RECOGNITION-NUMERIC-001.md)。本卡是这些数学/成员路线对当前可读板端工程的最小适配，不移植旧完整 O/OBJ/物理池目录。

| 已实际读取输入 | SHA256 |
|---|---|
| R4-RECOGNITION 当前稿 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| RECOGNITION-ALGORITHMS 当前稿 | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB |
| RECOGNITION-EXECUTION 当前稿 | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178 |
| RECOGNITION-NUMERIC | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A |
| main board/rtl/board_hough_dense.sv | 73ADB9BD92C061621497ED1FED282CDA7D748579DCEAE7504EB78AF32D44E427 |
| main board/recognition_numeric/stats_core.sv | 93FCA025A54F7FD8DA04AF6D3E56CF6D37CA3C0584DF745BB12A7B587BCE9A5C |
| main board/recognition_numeric/fit_core.sv | 875083D9835283FCABA45372A08BE2CF2B8056AA99F310F24DA15135565242F6 |
| main board/recognition_numeric/angle_core.sv | EA8B6F8E0E22112BD2D51B40A2E746A966500B3AF6A00C0835B4C66BC3863730 |
| main scalar_core_words.sv（058输入） | 6266734BEDD5CD1439355CC2153AE4B3FB0630079CADF9097433D9A0F89E4037 |
| main board_algorithm_rpc.sv（058输入） | 7F4B21CE09F81FBF2236E54000748B32FD522F889AD4997860292B3E5544EE93 |
| geometry_numeric_share_merged_v1_2 的 stats wrapper | 14228BE6277F5CDC5989D1D002D62C4590514E941BDEF5D55530D76527835A22 |
| circle_refine_v1 的 CF（独立静态已读） | 9412A428E8841F017F0D435651CFA5040AC5D334D8BB841ABF8E95194BA601DE |

源码根均为 `work/active/track4_board_first_20261011/`，后续只能在新 `candidates/rectangle_refine_v1/board/rtl/` 落独立增量，首块建议名 `board_line_point_math.sv`（尚未生成）。原完整设计含大量尚未实现的对象/目录与物理池，不能因本文引用而宣称它们已有代码。

真实输入差异：当前 RPC Hough 实例 `.line_min_support(21'd16)`；旧完整算法提议默认为3。矩形后端无法补回被16提前删掉的峰。父接入应明确采用的参数，Hough 与后端锁同一个值，并核 LINE META 回显。采用旧默认3需父显式改配置并承担更多峰/表容量，不能默默保留16却宣称实现原默认。旧阈值只是算法参数，均不是场景尺寸限制。

## B/C. 整体行为与模块划分

`完整 LINE META/有效前缀 → 逐峰49 offset → 两 offset 分组 CELL/run → 全 coarse SEG → 逐段六遍/TLS0–2 → 全 VALID SEG 的 PAIR → 四边后再三边组装 → 冻结四量化边核验 → RECT/META → 父 FINAL/ANN`。

| MOD（计划） | 职责、实际复用及保持边界 |
|---|---|
| RP line-point math，首块 | POINT 与粗/细线的一次 offset、残差、切向、gradient 门；借唯一 scalar，自己不做 DDR、STATS 或成员选择。 |
| RW workspace | DDR-backed CELL48/EXT80 的单行 RMW、清表与逐子位置 run；一个 RAM10 缓存完整64B，不保存512 FF。 |
| RL line/segment coordinator | LINE/offset 全遍、SEG384、固定 M0/M1/M2 和六遍；借现 STATS kind12/FIT kind12 与 ANGLE kind16。 |
| RG rectangle reduce/assembler | 原细线方向门/交点/均值/共同轴/三边远端及冻结边数学；小型 typed 微序列使用同一个 scalar，不开第二核。 |
| RV verify/output | 四侧统一最近侧分配、四侧统计/精确可见覆盖、RECT/META；最终 SELECT/ANN 属父后续接入。 |

全部 coarse 完整写回后才改 CELL→EXT；全部 fine 已 VALID/REJECTED 且没有 PENDING/旧回复后才 PAIR；所有 PAIR 形成完毕后才组合。不边覆盖临时表边借旧数据。VALID/REJECTED fine 冻结，最终核验不重拟合它。

RR-REQ01：49 offset、两个独立 CELL、完整 submask/run 保留；RR-REQ02：三次 TLS、严格六遍及旧成员重放；RR-REQ03：全 PAIR、四/三边、任意旋转与整短边缺失；RR-REQ04：冻结四量化边统一核验；RR-REQ05：单 owner/完整精度/真实关闭/容量失败。撤回的96–768、长宽比、最多4目标、20%遮挡与噪声硬界限均不恢复。图外/域外几何或启发式漏检仍计质量 FN，U形与同像素缺边矩形的混淆仍计 FP。

## D. 接口、字段与逐连接契约

**IF01 START/LINE/POINT。** 接受 `start&&start_ready` 锁 scope96、E21、LINE_count11（0…1024）、base32、阈值/guard；配置持有到真实 DONE/失败收尾。POINT V2 low-to-high：gx s11/gy s11/flags2/zero8/x11/y11/theta9/zero1，64bit，rowmajor 严增，尾 padding 零；沿现 POINT/PM 合法性检查，不撤销实际 gradient 域。LINE 是64bit条目，不是64B：theta9/rho9/votes21/zero25，八项/64B，总1024×8=8192B；只读实际有效前缀，theta≤511/rho≤276/votes≥同帧阈值。现 LINE 地址06700000，META06500000；META layout3、scope/E/line_count/line_min/base/LANES 与真实 Hough done 一致才能开始。POINT05000000保持到后端全部关闭。

**IF02 DDR/PACK。** 原 native req_valid/ready、write、addr32、rsp_valid/ready、data512、error/drained；单在途预约。POINT 每块 held，lane0…7只在该点全部数值/token/工作RMW关闭后推进；一个 POINT 块的处理需要 RW DDR 时，先把块内数据串行复制到一个 RAM10（32×16），真实消费原 read reply后再RW，不能 held 原读回复同时等同一 native 口第二读/写。此 POINT RAM 与 RW 行缓存是两个不同寿命，预算分别列出。单点64可用4×16字读出，不另加512 FF。RW同一行 read回复串行复制32×16到自己的RAM后消费，修改相应128位entry、完整顺序PACK0…7、等待真实WRITE error/drained回复后才换行/下一点；连续同cell见到上次真实写回。PACK无ready，复用父已 COMPLETE 的 gradient_store/共享pack owner，每段完整八字，包括高零；原物理owner/AXI地址与正文保持到真正关闭。

**IF03 私有记录/空间。** 全低bit先、低byte先，旧 logical fields 不改：

| 记录 | 编码与发布 |
|---|---|
| CELL48 / EXT80 | 原CELL32/EXT64低字段 + submask16；mask记录全部真实Q4子位置，valid/min/max一致；count不代替mask。DDR每项128，未用高位零，四项/64B。 |
| SEG384 | 低coarse128：peak10/theta9/rho9/offset s6/tlo s18/thi s18/n21/occupied12/maxgap18/flags7；高fine256：nx s32/ny s32/rho s18/tlo s18/thi s18/n21/Sx s33/Sy s33/anis16/occupied12/maxgap18/flags5。 |
| PAIR64 | s0_id10/s1_id10/diagnostic_theta9/zero35，s0<s1。八项/64B，全部512前缀；诊断theta取支持较强段，同票低id。 |
| RECT512 | kind2/flags4/parent_pair9/四segment_id10/present4/八vertex s18/四support21/四eligible21/score16/SSE53/四maxres16/zero8。kind0四侧，kind1三侧，缺段id0；present随顶点规范化同步旋转。 |

SEG采用64B stride低384/high128zero，写完整64B的真实B/通知已消费后才增加有效前缀或提交fine。fine state位combined379/380跨原细字边界：0PENDING/1VALID/2REJECTED，3非法；censored在fine bit2/3，其余flags按旧稿。REJECTED数值全零而coarse保留。1025 SEG/RECT、513 PAIR整帧CAPACITY，不截前缀成功。

建议新DDR区（半开范围，父接入前做33bit对齐/容量/全表不重叠核验）：CELL双表07200000…07220000（128KiB）；EXT在所有coarse关闭后复用CELL0的07200000…07210000（64KiB）；SEG07220000…07230000（64KiB）；PAIR07230000…07231000（4KiB）；RECT07240000…07250000（64KiB）；RECT_META07250000…07250040。COVER先保留07260000…07270000供后续精确核验卡冻结布局。本卡不改当前任何地址。CF最大已列至070A0080，以上不重叠；POINT/其它完整目录仍由父整体核查，不能只凭本小表授权。

**IF04 数值/lease。** 原 REQ622/RSP585/ID176、完整A192/B192及返回385，25×16资格后才收窄；返回字index24保留第385bit语义，非VALUE归零、borrow bank不依valid/quiet清零。NUM_ID新调用者标签拟C4（RP）/C5（RG），64位序号、owner字节0、scope96；冷复位外不清序号，MAX一次后禁止新调用，UNKNOWN不伪close。标签由父核全工程后定，接受的N直到真实 child quiet保持。

现 geometry wrapper使用 ENABLE_GEOMETRY=1、GEOMETRY_FULL_FIT=0：只向 FIT送真实kind12；stat632从START到STAT关闭保持，FIT完成并quiet后才stat_ready。STATS context拟D2/64seq/owner0/scope，完整E个POINT tokens，include=false也提交ordinal，END真实raw_seen=E。TAG/取消规则沿CF；known失败可ABORT_SCAN再消费同ID STAT/quiet，异ID隔离不消费。ANGLE kind16每峰提取C/S signed17（返回低0…16/17…33、高零），tag拟C6、真实reply消费且ANGLEquiet后改theta。没有新增ROM或第二ANGLE。

矩形方向/距离/交点/最终TLS诊断由RG借同scalar完成，不因需要kind13/14/15/18就悄开全FIT。后续若决定复用完整FIT须另限定其实际新增面积/时间与参数；本卡资源估计不把全FIT展开当零成本。

## E. 局部短操作次序

### E1. 首个可编码块：RP 两模式数值回调（尚未编码）

建议先生成一个文件，命名 `board_line_point_math.sv`；只接受 COARSE=0/TLS_POINT=1，mode2/3是已知格式错误。入参为command_valid/ready、command_id176、mode2、POINT64，以及粗线C/S signed17、R0 signed18 Q4，或细线nx/ny signed32 Q30、rho signed18 Q4；normal_sin_tol16是锁定配置。父保持所有输入到response消费且RP quiet；回复echo同ID/mode，offset_signed21/offset_valid1/index6、tangent signed18、distance21、normal_ok1、error/local_reject/drained，未用模式字段规范零。RP无DDR、STATS、ANGLE副作用。无本地暖取消端口；父stop等待已接受回调真实关闭后停新请求，共同rst才作废未知旧预约。

COARSE：每峰父先用原C/S得到 `R0=RNE((128q·32768+8[C(W−1)+S(H−1)])/32768)`，q=rho_bin−138。RP计算 f=16(Cx+Sy)−32768R0（s34容器），K=C²+S²（u33，核正常系数和K≥2^28）；最近半像素offset是精确 `δ=RNE(f/(8√K))`，先保全signed21，只有−24≤δ≤24才产生index=δ+24；域外是未属于任何offset，不能收6位回绕。可用k=floor_sqrt(floor(f²/(64K)))，比较4f²与(2k+1)²64K，以tie-even取k/k+1再恢复sign；不把近似norm直接当真实距离。切向 `t=RNE(8(SX2−CY2)/32768)`，X2/Y2先s13计算；梯度门按完整cross²·65535²≤tol²·K·|G|²。相关最大比较≤128bit，全部通过完整385资格后保存。

TLS_POINT：核nx/ny范围±2^30、K=u65≥2^58，f=s50；使用原NUMERIC/真实FIT kind14相同精确RNE残差语义：q0=RNE(|f|/RNE_sqrt(K))，完整4f²与两半整数边界比较，至多±1修正并重新核界，结果u21。切向t=RNE(8(nyX2−nxY2)/2^30) s18；normal门使用原向量全宽cross²，最大约120bit；不把大q截成16bit再选inlier。M/K可由父一次计算后保持，但首候选不能盲信未核cache；是否加入额外缓存仅在实际diff证明下选择。

局部顺序：接受→检查当前输入→计划typed微步→逐字读operand→原NUM real fire→核identity/header/outcome/full385、25word→8word保存→消费真实回复并等childquiet→下一微步→回复→真实消费且quiet。工作槽16×128，统一低到高8×16读写，两operand各128；错误先归还已确认预约，不加X/截断/第二NUM。微步表在首块编码前由父同卡读回确认；最宽函数仅此两模式，PAIR162bit等后续数学不得塞进RP的128槽。

### E2. 49 offset、CELL/run 与 coarse

每LINE完整E遍，RP只向其唯一合法nearest offset加一票；49×21计数同步16bitRAM，radius1 NMS，平票较小offset，保全部≤25活峰。两个offset一组，完整POINT遍分别写两个CELL（最多13组），按真实子mask从低t到高t：cell=floor(t/16)+2048，sub=t−16floor(t/16)，t=−1明确cell2047/sub15。所有0…4095越界检查后才收12bit，重复位置增加count但不重复mask。

相邻真实位置差>run_gap（旧提议48Q4）分run；记录真实tlo/thi/n/occupied/maxgap。coverage是被占1px cell区间与[tlo,thi]交集的真实长度/span，扣首末部分，不是点数或occupied×16粗估。n≥line_min、occupied≥2及coverage门通过才coarse；全表结束再进入fine。

### E3. 严格六遍与旧成员（TLS只有三次）

| 遍 | 冻结成员/交接 |
|---|---|
| 1 | M0=原peak/nearest offset/normal/coarse闭区间，STATS TLS217，核n=coarse n → FIT12 TLS0与μ0。 |
| 2 | TLS0 residual/normal资格写EXT，新count及M0 old_count；按真实run选shared降/total降/tlo升，shared>0、μ0距闭区间≤32Q4，冻结M1。 |
| 3 | 严格M1统计，核n=run1 n → TLS1/μ1。 |
| 4 | TLS1 EXT、新count及M1 old_count，同择法冻结M2。 |
| 5 | 严格M2统计，核n=run2 n → TLS2、n/Sx/Sy。 |
| 6 | 仍M2，不按TLS2重新选点；只把同一M2投影TLS2，恢复端点/occupied/gap/censored，提交fine。 |

TLS各次anis和相对前次4°方向门保留，完整平方交叉乘，不以rounded quality替门。TLS canonical ny>0或ny0且nx≥0，t=(ny,−nx)；翻号时rho/μ翻号、区间(-thi,-tlo)、censored两端交换。无run/退化局部REJECTED，重放n不符整帧INTERNAL。每次PASS_PREP在旧POINT/工作RMW/NUM/FIT/STAT全部quiet后才清本遍计数，不能同沿新线改变旧成员。

μ=RNE(8(txSx+tySy)/(n2^30))，按旧均值而非新run均值核距离。端点完整恢复 Bn=2^30rho、Bt=2^30t+8[tx(W−1)+ty(H−1)]，den=nx ty−ny tx，坐标分别RNE((Bn ty−ny Bt)/den)、RNE((nx Bt−Bn tx)/den)，负den规范，全宽后核s18；不假定norm精确1。

censor沿R4：像素面积窗Q4闭[-8,16W−8]×[-8,16H−8]，端点图外/guard带及同最终端点投影的所有真实M2成员触guard带均OR置端点flag。guard是强制显式输入（旧稿值未冻结）；建议候选比较值8Q4，但本轮不安装默认或假填0，父须在六遍块实施前明确锁值。此项限制三边推断置信度，可能FN，不是输入场景 admission限制。

### E4. PAIR、任意旋转四边/三边

全VALID SEG a<b，最多523776对；完整2°平行门、共同轴截距非零后写全部PAIR≤512，第513失败。再枚举PAIR a<b最多130816四边组合，四distinct SEG；随后每PAIR×第三SEG最多524288三边组合，third不属于pair，missing_allowed=1/required=3才启用。先原细线3°正交门、原交点在每原[tlo−32,thi+32]，随后强support方向（tie低id）定共同轴，另一轴90°，用保留n/Sx/Sy重算rho再求角。

三边远端由两个原fine uncensored端完整恢复/对齐与endpoint_extension（旧提议8Q4）推缺第四侧，缺长/短边同路线。角点RNE一次，核非零边/面积/不自交/CCW，起点取(y,x)词典最小，present和段号同转。不clip成功几何、不加长宽比/尺寸/目标数量门。

旧主动verify预算4096不是成功截断开关：达到预算且仍有下一合法未评估几何时SEARCH_INCOMPLETE，unassessed至少1，不发布前缀RECT/ANN；只剩被前置门拒绝组合可继续扫描证明真正结束。预算、真实512/1024表容量及启发式选择三者分开。实际预算值在组装块编码前锁定。

### E5. 冻结矩形核验及发布（后续块）

四量化有限边的精确N78/D39，比较NiDj（u117）选最近侧，tie低side；present不改单点侧选择。精确RNE q19先全宽与eligible64Q4/inlier24Q4旧门比较、normal门通过才support，再收q16，SSE53扩54检查。每点最多一侧support，Σsupport≤E。

现STATS一次只持一个context，不能虚称四TLS同时复用：计划四次POINT全遍，每遍仍计算全部四边和相同nearest side，只把当前side的inlier送原STATS kind18，STAT217借RG求n/anis诊断、关闭后存该侧摘要；不向FIT18调用、不重拟合几何。SSE/eligible/coverage亦按该侧同一冻结谓词记录，每侧摘要保留RAM。四遍只增加内读取，不改变任何归属集合。若后续改为一次遍/四统计RAM更新，须另明确实际scalar微步/存储，不在本卡假计收益。

required侧各n≥line_min、全宽anis/精确可见coverage通过；kind0四侧、kind1三present侧required，推断侧仍统计。score与meanSSE用全宽交叉乘，rounded score仅排序/显示。coverage不能用count替长度，必须沿R4 E7的可见边裁窗/覆盖区间并集合同；此精确coverage后续小卡尚未实施。RECT完整写成功后count++，全部组合、真实旧访问/owner关闭后PACK META/WRITE关闭，再DONE。去重/VC/FINAL/ANN尚为父接入，不把RECT候选完成称完整A6。

## F. 资源、时钟与开销

首RP估计1 RAM10（16×128=2048逻辑bit）、A/B各128FF、返回约70FF、有限control/游标预算≤600FF；合约930FF，**不是综合结果**，无新增DSP/NUM/ROM。完整矩形候选目标增量：RP1 + POINT块缓存1 + RW行缓存1 + offset票1 + RG192位工作槽1 + 四侧摘要1 = **6 RAM10**；RG operand各192FF、current SEG384与前任线/run两个冻结记录、有限控制/身份等另预算，总增量约2–4k FF，LUT/路由未知。禁止把POINT与RW两个并存寿命缓存偷算成一个；也不沿旧32RAM池/40RAM SEG直接分配。DDR backing约260KiB加预留coverage，未新增外设。

主057实际RAM225、XLR61201/60800容量失败；058正在真实运行，本卡不读取其未完成状态冒称通过。CF依赖的HIST/PM/CR及新的矩形增量都需重新计入总预算。剩余RAM并不证明LUT/布线能装下，完整后端接入后必须实际测量。所有新RTL同core域；没有新CDC/芯片引脚/相机或HDMIPHY改动，沿父已有clock/SDC，90.909MHz仅当前预算频率。

最坏 POINT重放：coarse≤14LE，TLS≤6SE，四侧串行核验≤4VE（L/S≤1024、V取旧4096时共36864E）。E=N时约764.4亿POINT访问、611.5GB原POINT读取，还未计CELL/EXT RMW、PAIR组合和数值调用；不是实时能力。即不含数值/DDR停顿而每点只用一core沿，已约841秒；真实全宽乘除/根与25字资格会更慢。显式稀疏E/提前拒绝可少很多，未有典型实测延迟。本卡不降1080p或偷偷限制目标域来换“可实现”。后续需保留数学和范围的性能结构优化。

## G/H/I. 定向验证计划、追踪及停止点

本轮只做设计文字/协议读回；以下均NOT_RUN，不新增TB或独立仿真。

| 文字场景 / REQ | 期望/对应单元 |
|---|---|
| RR01 offset±24/域外、±half tie、t=−1、同cell稀疏submask、连续同cell | RP精确RNE；RW真实读改写与子位置gap，默认零不当有效。 |
| RR02 TLS0/1/2改变、M1/M2 n重放、μ到run32边界、翻号/两端censor | RL六遍，不第三extension；STAT/FIT借用关闭后换线。 |
| RR03 任意旋转、完整短边缺失、图外端点、U负例、PAIR513/SEG1025 | RG原细线先检查、三边不要求四边闭合；容量失败与FP/FN不隐藏。 |
| RR04 最近侧exact tie、推断侧分配、短有限边、小norm、可见length0 | RV有限边不套Q30 K门；present仅影响required，精确coverage不能count替。 |
| RR05 held POINT与RW访问、STAT/FIT同沿、MAX、异ID/UNKNOWN、背压、错误WRITE | IF02/04单预约/独立RAM；known真实排空，UNKNOWN不换owner/暖清。 |

正向：RR01→RP/RW→IF01–03/E1–2；RR02→RL/STATS/FIT→IF04/E3；RR03→RG/PAIR→IF03/E4；RR04→RV→E5；RR05→所有模块→真实fire/close/quiet。反向每个计划文件只承担此表职责，未列单元不顺手编码。

当前①整体/职责②来源③接口/字段④局部次序⑤RTL位宽/借用⑥文字场景⑦增量/追踪已写；⑧完整后端仍有配置/coverage/资源性能/父连接未闭合，不能整包READY；⑨须父保存读回/呈现；⑩首块实施范围必须另明确。当前允许动作仅父独立读回、收束首RP微步/调用者标签和限定候选，不实施本卡所有模块。正式数据库/Manifest未改，不宣称已登记批准。没有C++/参考模型，本卡仅RTL数学与事务合同，不新增跨语言等价证明。

## J/K/L. 恢复与交付说明

这是完整旧算法对当前分时核和DDR backing的局部设计；主要适配为64B native表访问、CELL48/EXT80保submask、严格6遍/单STAT四侧串行核验、显式少量RAM。scope/config/表版本/owner变化先停受影响增量并修卡，旧记录不可blindcast。读回从B/C整体→D交接→E1首块→E2–5后续→F预算，理解验收待用户实际反馈，不设置额外学习门槛。

实际已完成：真实来源和hash、协议/成员生命周期分析、本短卡保存；尚未生成矩形业务源码、测试、约束或工程文件。仿真/综合/布局布线/STA/bit/硬件全部未运行。本卡独立设计不更改父058、当前可交付工程或人工下载/观察状态。
