# TRACK4-ALGORITHM-RECOGNITION-STAGE-MAP-001：识别阶段权限、稀疏有效集与复用 v0.1

## A. 状态、范围与阅读入口

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。任务属完整识别路线的 RA-B01 / NS-B01 衔接；本文采用 PLAN_TEMPLATE 的 A–L，先整体 B、职责 C、接口 D，再局部 E、语言/预算 F、验证 G 与追踪 H。原十一项交付未完成。
Goal：给26类对象明确阶段权限上限，解决 ANCHOR 稀疏构造/压紧与 VC 双区间的真实有效性，区分 HIST 物理引用和数学延迟，明确复用不越过 SEAL 或权限 fence。Current state：R4R 只有阶段算法和通用有效前缀；RA/NS 尚缺真实阶段映射。Target state：真实 O/STORE/SC 连接、管理桥和费用闭合后形成可实施版本。
Gap / Open questions：SM-B01 真实阶段 owner、phase通知、INIT/CLEAR/有效集/SC缓存接线；SM-B02 管理 SEAL/新可写版本/COMMIT retained 资格与空集合路径；SM-B03 全机控制/运输/资源与服务时间；SM-B04 RA-J 单槽租约、逐lane关闭、DDR可见性/no-future。全部 OPEN；选定本卡算法权限/局部证明不把这些阻塞关闭。
Assumptions：N=2,073,600、1920×1080、512θ×277ρ，保留五基础/六高阶、原目标/旋转/重叠/缺边/负样本/质量要求；仅板卡现有资源，板载 DDR 已获允许。没有新增目标尺度、噪声边界或降低分辨率。本文不改变对象编码、物理地址、原 RQ/RSP/NUM 体及SC的3位阶段生命周期状态。
Dependencies / Milestones / Detailed steps：现行字段/字典→阶段与权限→真实有效集→复用关闭→预算/管理桥→独立审阅/读回→共同吸收→指定 READY/批准→独立 work 实现验证。只纯文档、静态元数据与文档事件允许；没有新业务代码、模型/TB/可执行测试/脚本或 EDA。
State transitions / Human approval gates / Rollback：本地设计阶段不改 PROJECT_STATE。Manifest 的 R1 与预检范围不包含识别实现；本地审计例外不扩用。已提出的 R2/Q0 指定审批问题保持待答，不因本卡重复提问。保留旧卡不改；删除候选资格、回到旧文档依据需保留检查点历史。
Artifacts and hashes：本卡身份由外部文档检查点登记；无 Git commit。事实与本卡选择分别说明。

| 来源及本轮用途 | SHA256 |
|---|---|
| [R4R v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)：D3/D7/E1–E8、263位解释、VC gid | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [RA v0.1](design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md)：首次INIT、RMW、组门、既有费用 | 33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA |
| [NS v0.1](design-TRACK4-ALGORITHM-RECOGNITION-NMS-LIFECYCLE-001.md)：32批CLEAR/四行有效及顺序 | 85B837A89412AB10D299AF1FDEA02DFCF8915A01B065F6EE525DDAA847326504 |
| [PK v0.1](design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md) / [26类32实例字典](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json) | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 / D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)：真实640位描述、pool与逻辑commit | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)：D5阶段fence/真实quiet/admin分离 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [旧 EX](design-TRACK4-RECOGNITION-EXECUTION-001.md)：六遍算法第六遍CELL来源；旧RAM布局不采用 | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178 |
| [RAW](design-TRACK4-ALGORITHM-RAW-STORE-001.md) / [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)：ordinary RSP与退槽次序 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD / 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 |

## B. 整体行为及阶段

SM-REQ01：实际 phase 来自真实 RC/STORE 阶段事件和 O/SC 安装；RQ 自带 object/op 不授予 phase。权限表是上限，真实身份、许可、格式、有效集、初始化、排他/最新视图和局部gate全部成立才访问。
SM-REQ02：CLEAR 成功建立物理初始化；其零数据是否可作有效记录，必须按schema判断。ANCHOR 零POINT/CIRC零半径/VC state0不能当真实候选；HIST等数字0与CELL/EXT显式 valid0空格则是合法数据。物理初始化集合、已构造记录集合与算法完成集合分别保存。
SM-REQ03：压紧 ANCHOR 保留每个真实桶槽恰一次；VC 维持圆/矩形原 gid；SEAL 冻结当前stage version，不等永久 immutable COMMIT。失败/错echo/未知效果保原历史与引用，不从清零/响应消费推导成功。
SM-REQ04：HIST 清零只等待旧物理引用关闭，不等待需要下一tile输入的数学判峰；RAW/SMOOTH峰仍全部保留、跨tile 567bit halo 和 plateau 原语义不变。第六遍TLS仍M2、真实CELL计算，最终输出完整ANN及64RECORD。

| phase4 值 / 名称 | 正常职责与进入/离开证明 |
|---|---|
| 0 PREPARE | SC BINDING期间仅真实provider prepare INIT；普通业务权限为空。首次按对象阶段准备不是RJ接纳全清。 |
| 1 POINT_BUILD | 全N读EDGE/GRAD、真实完整POINT append；最后真实COMMIT(E)含E0。 |
| 2 ANCHOR_BUCKET | 按384桶各两槽挑rank，真实稀疏槽数；没有将桶空零作POINT读。 |
| 3 ANCHOR_PACK | 冻结原桶map，升序压紧、真实compact_prefix及SEAL(M)。 |
| 4 SEED_BUILD | 全a<b、distinct排名替换/排序，SEAL(S)，S≤256。 |
| 5 CIRCLE_HIST | 单中心完整16tile、跨tile峰、SEAL RAW/SMOOTH。 |
| 6 CIRCLE_FIT | 原五遍/批16上下文与真实统计；distinct CIRC全局append，所有中心结束才CIRC SEAL(C)。 |
| 7 LINE_WORK | 原32批全票/真实CLEAR、四行快照、NMS、全局LINE append并SEAL(L)。 |
| 8 SEG_COARSE | 全LINE/offset，用两组CELL形成coarse SEG，SEAL(G)。 |
| 9 SEG_FINE | 全G段六遍TLS，EXT复用、M2投影到CELL，完整384位fine更新；保持coarse。 |
| 10 PAIR_BUILD | 全VALID fine pairs，PAIR append/SEAL(P)。 |
| 11 RECT_BUILD | 全四/三边合法组装与验证，RECT全局append/SEAL(R)。 |
| 12 VERIFY | 冻结C/R及geometry；圈/矩形逐候选完整VC400原子写，保持1024偏移。 |
| 13 SELECT | VC真实候选全核验完成才读取state1/2；完整FINAL append，VC2→3，最后SEAL(F)。 |
| 14 OUTPUT | 只读冻结FINAL，DRAW、全N ANN、64RECORD canonical写与真实COMMIT；F0同样完整输出。 |
| 15 STOP | 不发新ordinary；原held/admin/RETURN/CLOSE/NUM仍按旧身份履约，不能把STOP当quiet。 |

正常序列0→1→2→3→4→(5→6，每中心重复)→7→8→9→10→11→12→13→14→15；S=0拟4→7，但CIRC空对象INIT/SEAL0真实管理路径未闭合，见SM-B02，不把绕过视已可执行。其它空集合仍有真实SEAL/管理终止，没有假0byte许可。阶段值不能覆盖 SC FREE/BINDING/LIVE/FENCING/CLOSING/RETURNED_METADATA/Q 的事实；Q继续保留当前phase/身份。
正常例：仅矩形C0/R1，VERIFY写gid1024，SELECT读1024；不读0、不把valid_count1解释index<1。ANCHOR仅桶383的slot0已构造，PACK最终记录0为该原点；初始record0全零不当合法源。无目标：E0/M0/S0/L0/G0/P0/C0/R0/F0仍需完整空结果管理、ANN与RECORD输出，不承诺吞吐。

## C. 责任与真实连接

MOD-SM-SCHED（RC）拥有已核typed RSP后的算法游标和镜像事实；MOD-SM-GUARD（STORE）拥有真实成功effects、稀疏构造/压紧/VC核验证明；MOD-O/SC拥有ref/version/grant/phase installation、INIT prefix和生命周期。前两者的局部字段不能当O/SC许可。
数据：RC→原RQ799/KEY287→STORE guard→RA assembly/journal→真实物理读写→原RSP872→RC matching expected；O/SC检查与stage fence贯穿，NUM仍原单调用者契约。变更：RC阶段意图→可信STORE旧义务关闭→O真实FENCE/RETURN(若需)/recapture→ACTIVE ACK→后续沿恢复新请求；这条通知/证明实际body尚SM-B01。
选择独立STORE权威map与RC镜像，避免caller自报或额外public QUERY/op6；所需字段、真实事件和费用必须落实。镜像可在响应hold期间落后，不要求同周期一致；只有匹配RSP消费、旧运输静止后的事务边界才比较。整体检查点为本卡B/C/D及未决清单，不宣称界面呈现即用户已理解。

## D. 权限上限、接口与组合检查

R/W/C/S/K/A对应原op0/1/2/3/4/5；没有第七种public操作。C=整表capacity与完整rounded真清；S=真实valid_count及stage封存；K只POINT/ANN/RECORD，A只DENSE16。INIT是可信provider管理路径，不是ordinary C自动资格；各表首次使用前按真实rounded逐16B准备，完整消息仍SM-B01/02。
表中“—”拒新业务操作；未列出的phase/op均拒。每条仍须真实H/gen/revision/ref/version/grant/许可、canonical/范围/排他/完成gate，不把此表写成无条件allow位图。READ集合见E，各个C/S/K不可套record数据寻址或造length0普通permit。

| object | R 上限 | W 上限 | C 上限 | S / K / A 上限与关键门 |
|---|---|---|---|---|
| 0 EDGE | 1：已封存全N | — | — | 同图真实只读资格 |
| 1 GRAD | 1：已封存全N | — | — | canonical32，不借实时像素 |
| 2 POINT | 2、5–9、11–13：已COMMIT [0,E) | 1：index=实际append E | — | K1(E)；构造前真实provider INIT |
| 3 ANCHOR | 2：真实桶占用；3：下一原occupied源；4：compact [0,M) | 2：桶追加/替换；3：真实copy_hold压紧 | 2：构造首清 | S3(M)；原map和PACK单调扫描见E1 |
| 4 SEED | 4：真实built；5–6：[0,S) | 4：distinct append/替换/排序 | 4：首构造 | S4(S)；排序所有真实entries，不读零valid0洞 |
| 5 HIST | 5：当前完整clear tile | 5：当前tile latest计数 | 5：16次/实际中心 | 无S；每tile全效果结束、halo物理引用分离 |
| 6 RAW_PEAK | 6：sealed [0,raw_count) | 5：完整峰append | 5：当前中心新可写版 | S5(raw_count)；下中心需真实新可写版 |
| 7 SMOOTH_PEAK | 6：sealed [0,smooth_count) | 5：完整峰append | 5：当前中心新可写版 | S5(smooth_count)；halo/plateau末义务全空 |
| 8 DENSE | 7：当前batch全票完成 | —（只内部A的RMW） | 7：32次full4432 | A7：原16lane；dense_ready不是clear完成 |
| 9 NMS | 7：真实已完成rowθ及277项 | 7：NS允许的复制row/下一r | 7：首次全1108 | 无逐row S；旧rolling引用先关、保共享单位邻位 |
| 10 LINE | 8：[0,L) | 7：全局append | — | S7(L)；顺序1…511,0/r升，首次INIT |
| 11 CELL | 8、9：完整clear两组8192 | 8：offset对；9：第六遍冻结M2 | 8：各offset对；9：每第六遍 | 无S；full C不是只clear一个4096 side |
| 12 EXT | 9：当前clear4096 | 9：第二/四遍scatter | 9：第二/四遍 | 无S；两遍结束才改用途 |
| 13 SEG | 9：[0,G) coarse；10–11：[0,G)完成fine | 8：coarse append；9：原coarse不变的384位更新 | — | S8(coarse G)、S9(fine G)选择；newwriter桥OPEN |
| 14 PAIR | 11：[0,P) | 10：全局append | — | S10(P)选择；全枚举结束，首次INIT |
| 15 CIRC | 6：实际distinct prefix；12：sealed [0,C) | 6：全局distinct append | 4：仅S0空路径、桥OPEN | S6(C)选择，仅所有中心结束；S4(0)空路径OPEN |
| 16 RECT | 12：sealed [0,R) | 11：全局append | — | S11(R)选择；所有实际候选结束，首次INIT |
| 17 VC | 12：仅已完整核验两前缀；13：全真实gid集 | 12：expectedgid完整1/2；13：2→3完整body | — | 不S/K；C/R与verified两组实际证明，首次INIT |
| 18 COVER | 11–12：当前完整clear quad | 11–12：当前candidate/side bitmap | 11–12：每实际coverage quad | 无S；全16384不能四次full C冒称side clear |
| 19 FINAL | 13：[0,F)实际keeper；14：sealed [0,F) | 13：keeper append | — | S13(F)，禁止K；首次INIT，F≤64 |
| 20 DRAW | 14：全F完整构造后[0,F) | 14：对应FINAL顺序append | — | 完成gate；无S/K，首次INIT |
| 21 ANN | —（RC本次无回读用途） | 14：全N逐行逐位置 | — | K14(N)，首次INIT不替完整覆盖 |
| 22 RECORD | —（RC本次无回读用途） | 14：全64，包括未用0 | — | K14(64)，payload低7=F；首次INIT |
| 23 COVER_META | 11–12：本次实际已完成side | 11–12：本次四个完整metadata | — | 首次INIT，不读旧candidate/zero正den洞 |
| 24 CIRCLE_CTX | 6：当前active已完整lane | 6：真实≤16上下文/五遍更新 | — | 首次INIT；lane_valid与pass/route/seed独立 |
| 25 FIT_STATS | 6、9、11–12：实际purpose/active已初始化统计 | 6：LS/radius；9：TLS；11：四侧TLS；12：圆LS/矩形四侧TLS | 6、9、11–12：切到fresh统计前full16 | purpose=LS/RADIUS/TLS由真实阶段事件；额外lane/purpose账OPEN |

首次INIT与算法C仅在同ref/version/授权、实际fullrounded写、无intervening dirty且真实证书共同结算时合并。POINT/LINE/SEG/PAIR/RECT/FINAL/DRAW/ANN/RECORD只列真实首次INIT，未添加算法full C；CIRC另有S0路径的实际full C。后续重新构造的ref/version有自己的真实INIT，不能靠原表这行省掉。


接口保持原RQ799/RSP872、KEY287、object5/op5/index32/length21/payload512；phase4属于真实上下文不添加caller端口。所有索引无符号记录序号，bitpack按PK42/33位扩展、实际rounded16B跨度保护；镜像字段按E具名。SC原LOOKUP616/740的item_count>0及span≤64只用于数据许可，不授zero SEAL/COMMIT；管理资格需完整 retained body独立存放。
权限phase、ref/version/grant/access/holder/lifecycle/immutable变化依SC D5真实fence；valid_count/tail/latest只由STORE真实事件更新，无每POINT冷recapture。全旧published/accepted/native/DDR/journal/permit/borrow/heldRSP闭合后才失效旧slot、必要RETURN、新完整快照、ACTIVE真实消费后后续沿恢复。fence停新publication，不组合阻断已held旧请求的ready。
进入最终permission phase15也须旧data quiet/fence；开始停止/取消仅内部stop-publication/closing状态，旧permission phase保持至旧promise兑现，不能先flip STOP屏蔽其ready。
COMMIT/CLOSE retained admin不因access fence消失；若其本身需无writer/RETURN，数据quiet不等待该admin结果先交付。原SEAL后的新写版本、空对象管理、stage freeze通知并未已有完整桥，保持SM-B02。成功完整OBJ响应与真实old运输静止分别检查；坏echo计raw但不推进镜像、不释放原expected。

## E. 局部中文操作草图与不变量

### E1. ANCHOR：原槽存在、单调扫描和压紧分开

每个owner各保存384×2bit bucket_count（0/1/2，3非法）；本次真实完整构造首清/初始化闭合才建立全0空桶证明，失败/取消或任意phase变化不清该map。STORE只按真实完整canonical WRITE及effects成立更新，RC只按对应正确成功RSP消费更新。追加仅s==旧count且count<2、成功后count++；替换只能s<旧count且rank满足原算法，不增count。bucket READ仅index=2b+s且s<count[b]，不因物理初清/valid_count有权读取空POINT。
进入phase3前结束全部旧桶操作/NUM/运输/引用并真实phase切换，冻结两份原count map。两owner各 compact_prefix10（0…768）；STORE另 copy_hold64 / pending1 / source_frontier10（0…768）。该frontier兼当前受保护源：从0开始，依冻结map跳过原空槽，下一READ必须等于其找到的最小原occupied index；没有caller任选源的自由。
真实SOURCE READ、完整原KEY/RSP/canonical核后保存copy_hold并置pending；源READ RSP真实fire且其旧运输/引用静止后才释放响应槽，copy_hold仍独立保存，不能撤回held回复。只允许目标index=STORE compact_prefix、payload逐bit等copy_hold、destination≤frontier。全部目标原子WRITE/effects结束后STORE prefix++，只有真实匹配WRITE成功RSP消费才RC prefix++；未结束permit/native/borrow/旧持有者前不能释放hold、推进frontier或开始下一源。失败保原frontier/pending/hold及历史，不跨过未知源。
目标总不大于正在扫描的源：源严格升，已构造目标数量最多已访问原槽数；已完成压紧只会覆盖当前/更早源，不覆盖未来原槽。原count map不会被目标WRITE改变；不重新读覆盖后的旧源。扫描至768、pending及全部旧义务空，两owner prefix相等且等原count和M，才真实SEAL(M)；后续phase4只读新compact [0,M)。没有把CLEAR零当存在证明。
部分字段账：两count map1536bit＋两prefix20bit＋STORE hold/pending/frontier75bit＝1631bit。STORE和RC事务/RSP/阶段/错误/完整身份/序号及循环适配其它状态仍SM-B03；此数不是完整RTL/FF，也未从旧私有RAM免费扣除。

### E2. VC：candidate集合、完成集合、状态转换分开

STORE/RC各 C11/R11/verified_c11/verified_r11，范围0…1024，共88bit部分proof账。C/R来源是实际CIRC/RECT全局append成功、完整SEAL及真实身份/版本（RC仍须matching RSP）；进入12时冻结两表真实count，不取caller payload、初始化字节或合格候选数量。
candidate集合为[0,C)∪[1024,1024+R)。VERIFY按圆ordinal升然后矩形ordinal升，expectedgid由verified_c或1024+verified_r产生；不从C+R造连续地址。核验直接读取已sealed源geometry并重放POINT；VC零初态只当前expectedgid内部保护RMW可见，不能发ordinary READ当实际候选。
拒绝完整VC state1/其余0；合格完整state2和全部指标/geometry，400位同一次原子WRITE可见。STORE真实效果完成才相应verified++，RC正确expectedgid RSP消费才镜像++；verified是核验完成数，包含拒绝。VERIFY普通READ只允许已完成的两个verified区间，遇真实candidate state0为INVARIANT。
两owner verified_c=C、verified_r=R且末NUM/OBJ/effects/运输全闭合，才fence到13。SELECT不whole-SEAL VC，保同真实writer资格，经完整原子WRITE允许2→3（重复也3），其余398bit必须逐bit等实际旧stored VC（STORE保护读核，非caller自报canonical）；禁新的0→1/2，1不可变、3不能重选。全verified集遍历读值均核完整state/schema及真实gid，保原排序、best400独立及精确dedup。FINAL完整成功append后才改变对应keeper VC；失败期间记录二者真实前缀，没有跨对象rollback承诺。
DIR通用valid_count可作cardinality，不能作此表地址上界或完工证明。权威两集合与SC缓存/descriptor的实际连接尚SM-B01，不能从本卡字段名认定桥已存在。部分新增proof合1631+88=1719bit；计费范围与运输/body区别见F。

### E3. HIST 复用不等待需要未来tile的结果

保持原567bit有限halo（旧末18raw＋新首9）、RAW/SMOOTH plateau起点/高度/左邻资格与选中心配置。旧tile全部读已真实完成，其末raw复制至独立holding、原native/DDR/permit/borrow/heldRSP/journal引用关闭后，才允许原HIST full CLEAR用于下一tile；不要求“旧末9平滑峰数学判定”此时已经完成。
新tile真实clear→全E投票→当前tile effects闭合→实际读新首9填carry→完成旧末9延迟判峰、写入真实RAW/SMOOTH→持续读新tile。holding保到全部依赖它的判峰/NUM/峰WRITE引用真正结束；空tile也供真实0，不能bubble代值。最后域外0仅邻居补边、全部16tile及末峰关闭才SEAL两完整峰表。
清零条件是旧HIST引用闭合，carry数学pending是独立义务；若CLEAR等carry判峰、carry又等CLEAR后的新首9，会循环等待。本文拆开该条件，未减少567bit、plateau状态或任何原峰。carry/plateau实体与真实引用桥仍SM-B03/04；不能偷用即将清的HIST位来保存carry。

### E4. 重复与封存，不把phase号当真实版本

S0路线选择：真实SEED count0与旧选择/NUM/OBJ义务闭合后，拟在phase4明确CIRC writer/admin资格，真实full CLEAR object15/index0/length1024/payload0（32768B/2048个16B单位），核initialized prefix/settled/valid_count0，再原SEAL length0/payload0取得真实token；正确回执及旧admin/运输闭合后才fence至7。这次首清仅与同一真实合法INIT事件可合并，另跑INIT另算。其O tuple/权限、prefix和空SEAL管理桥尚SM-B02，不能借空对象免掉RA fullrounded策略。
同phase的tile/batch/pass/side/row变化需STORE自己的当前对象tag和真实旧引用/NUM/原子组/effects闭合。数字阵列CLEAR后允许完整初始化域零值；ANCHOR/SEED/LINE/SEG/CIRC/RECT/FINAL/DRAW按真实构造集；NMS按NS真实θ/row gate；CTX按实际active lane；FIT按真实purpose和pass；COVER_META按当前四side完整构造。这些gate未全部有真实消息/冷descriptor连接，SM-B01保持OPEN。
5→6只在完整RAW/SMOOTH SEAL并fence安装read资格后拟合；6→5先全该中心lane/五遍/原峰读/NUM/effects闭合，再真实新writer/version/phase重建RAW/SMOOTH。CIRC count跨中心/route累计不清、不逐中心封存。不得解除原stage SEAL或复用仍held旧version。
8→9先coarse SEAL(G)、真实fence/新的fine writer资格且保存原coarse；不能CLEAR新SEG毁掉coarse。每个fine WRITE完整384位，STORE与原coarse逐bit核相等；FIT full16 CLEAR只在当前batch全部active lane的旧统计读/NUM/效果闭合后统一启动新pass，不以单lane结束清掉其他lane统计。第1/3/5遍fresh TLS217统计及高46零，第2/4遍fresh fullEXT，第6遍fullCELL，两组原8192记录保持容量，冻结M2重新投影TLS2求真实submask端点/occupied/maxgap，不添加第三extension。fine完成freeze/SEAL选择与旧stage新writer/资格沿SM-B02，不借旧EX bank映射免费。
PAIR/CIRC/RECT在全枚举/所有center或实际候选完成后新选择明确stage SEAL；不改变各容器容量、budget/search incomplete和失败政策。FINAL SEAL后phase14 readonly，不再clear；POINT/ANN/RECORD真实COMMIT与writer RETURN/retained admin依SC D5区分，历史ANN/RECORD及全图输入不在当前RC清表。
核验统计选择现有FIT_STATS：phase11每个实际矩形验证、phase12每个矩形重核的四个fresh TLS217用lane0…3及高46零；phase12圆重核fresh LS263用lane0、kind17形成fit_support/quality，不能从不含这些字段的CIRC256或已复用旧fit读诊断。每candidate/新pass仅全部旧active统计/NUM/effects/引用静止后full16 CLEAR，再锁真实purpose/active集合，结果形成并关闭后才复用。COVER的同一冻结inlier遍与四TLS统计保持原R4语义，未选择第五侧或新几何拟合；purpose/active/candidate真实通知与预算仍SM-B01/03。
当前RA E3写“END→退槽→最后ordinary success”，但RAW/BK原ordinary合同为END/冻结→MAKE_RSP/HOLD→真实RSP消费/旧引用静止→RELEASE。本卡选择保原ordinary合同；DENSE lane则须独立保存prefix/失败事实再END/退租/下一lane，wholegroup门跨全部16lane至最终RSP/关联关闭。真实lease/退租body及原因翻译仍SM-B04，不能以名称闭合这项。未来共同修订RA，而不是悄悄修改旧卡。

### E5. 沿、反压、取消和复位

同core posedge，沿前旧valid&&ready&&!rst定义接受；e0只capture，后续旧状态校验/发下游/等待真实回复。WRITE effect、STORE proof推进、held RSP形成、RC matching消费、运输静止以及阶段ACTIVE恢复是不同事件，不合成同沿新值链。
反压期间全KEY/expected/body/proof/配置保持；等待不会清计数或原map。取消同沿先记已fire及真实效果，再停新publication、兑现旧held、保独立失败/close证据；错echo不推进mirror、不结原credit。rst仅禁新fire及版本隔离，不物理清DDR/槽/Q；真实旧效果/returnedmetadata无证据不得复用。非法phase/table/count、越界或UNKNOWN按原typed失败/Q，不产生新成功token。

## F. 语言、位宽、资源和费用

| RTL A–L | 本卡契约及限制 |
|---|---|
| A 数值 | phase4=0…15；bucket_count2=0…2；compact/frontier10=0…768；C/R/verified11=0…1024。加法先扩1bit核域再窄化；source index=768是终态不可寻址。所有record低位/高padding沿R4R，bit/地址沿PK。 |
| B 时钟/观察 | 共同core posedge，旧状态fire，capture不穿透；未来TB沿后稳定核proof。 |
| C 接受/交付 | typed RQ/RSP、效果/镜像/关闭分别定义；本卡未授额外QUERY或op6，INPUT可暂停。 |
| D valid/推进 | 零payload合法性按schema；clear完成不造候选，verified包含reject；气泡不推进任何count/frontier。 |
| E 反压/保持 | original map、hold、expected、VC冻结C/R、halo和purpose保到真实引用闭合；RSP held时两owner可不同。 |
| F 延迟/吞吐 | 只列符号/传输数；真实fence/租约/DDR/NUM时间缺界，无算法fps或时钟周期保证。 |
| G 复位 | 同步高有效、!rst fire；未获真实闭合不清旧资格/owned槽，不将cold初始化泛化到warm reset。 |
| H 配置 | 原完整RJ/profile/H/gen/revision一次采样；phase与purpose来自真实owner事件，caller不自选。 |
| I 存储 | 原26类32实例、实际packed容量不改；1719bit只本卡ANCHOR/VC显式proof，不含阶段tag/运输/halo/CLK/物理预算。 |
| J 身份 | POINT原N坐标、ANCHOR保完整POINT、VC保持1024偏移；candidate基数不是gid上界，F≤64。 |
| K CDC | 本卡core同域；真实camera/DDR/video/reset跨域仍联合R5/DDR合同，没有新增CDC认证。 |
| L 实现 | 目标Ti60F225/I3，工具/SV/时序/引脚沿整体拟工程；本卡无实现/综合/STA/PNR或fit结论。 |

两owner各11bitcount、10bitfrontier足域，非法bucket3拒绝。1719bit显式字段不能自动说1719FF/XLR，STOREmap RAM/FF落位与端口、其它state/许可body未选；与RA2352、NS142、SC/cache及pool预算按实际实例归属去重，没完整清单不扣账。未增加新DDR对象、没有选择阶段物理alias。
首次fullrounded容量仍24个D7当前对象17,526,400B/1,095,400个16B写：21private415104B/25944，POINT16,588,800B/1,036,800，ANN518400B/32400，当前RECORD4096B/256。只读EDGE/GRAD、其他历史实例和SRC/RING/CLASS/QUEUE/PROFILE/header/pool另账；不是RJ立即全清。
按每真实ref/version实例v的I[o,v]首次INIT0/1、A[o,v]算法整表CLEAR次数、M[o,v]确为同一合法初清事件的合并0/1，总零写数Σ_oΣ_v {u[o] × (I[o,v]+A[o,v]−M[o,v])}；后续新版本的INIT另计，不把I0/1泛作整帧最多一次，不得因值0或prefix满自行M=1。选定HIST跨版本总A=16S、DENSE总A=32；CIRC的S0路径A=1/2048单位，其与INIT独立时两次均记。CELL=3072*A_CELL单位（包含coarse offset对和fine第6遍），EXT=2560*A_EXT（本卡正常每SEG第二/四遍两次），FIT=36*A_FIT（含6/9/11/12实际新统计），COVER=128*V_cov（包含实际RECT_BUILD及VC矩形重核进入bitmap者）。RAW/SMOOTH每center fresh版本、metadata/ctx重复初始化和每失败前缀要按实际事件，未测数量不隐为0。
原RA普通journal每WRITE59native issues，INIT/READ/admin不按59；当前逐recordANN显式N次保护RMW为4,147,200个16B数据传输/66,355,200B和122,342,400native issues，64RECORD512为512传输/8192B和3776issues，仅本策略数据/native账，不含INIT/控制/许可/等待也不是时钟上界。ROW本地每行480B清，1080行518400B；FONT另实例，不从26对象扣。NS复制费用保持原卡。
阶段边：S≥1正常路径2S+13，S1=15、S256=525；0→1若没有旧ACTIVE资格是初次capture，不能谎称每条都是旧fence。S0若将4→7真实空管理桥闭合则13。权限边数不包含不能合并的version/SEAL/COMMIT/RETURN mutator，更不等cycles；同phase局部gate有真实变化也要收费/通知。
共同数学契约：原R3/R4逐位数值与场景目标不变；软件独立数据结构须区分initialized、built、verified、phase/schema。硬件执行契约：上述proof真实效果与匹配回执分别推进。软件↔硬件：桶/原源frontier、C/R与gid、当前tile和版本一一对应，比较实际已交付prefix和终态，不用DUT日志造黄金。C++未选/工具未核，本卡不新造C++模型；Python任意宽参考仍计划未生成。

## G. 实施及验证计划（未生成/未运行）

拟新增可理解模块边界SM-SCHED/SM-GUARD与真实stage/admin适配，具体文件/符号依共同版本freeze再列实施清单，不能现编路径称已有RTL。须先关闭SM-B01…04、完成完整预算/服务/组合、指定READY范围批准；再独立work实现、参考/TB与EDA。本表只场景文字，无可执行体。

| TEST | 覆盖 | 输入/事件 | 期望与观察 |
|---|---|---|---|
| SM-T01 | REQ01/phase | phase2发VC W、caller改phase字段、SC旧revision | 拒新访问，已有held旧promise继续，不改变phase或权威count |
| SM-T02 | REQ02/E1 | 只有桶383 slot0构造、其余全零；PACK | 仅原index766可读，一次copy到0，M1；不读空0、不漏/重复 |
| SM-T03 | E1/source proof | caller跳过下一occupied源、重读覆盖后的源、payload改1bit | 拒；frontier/pending/hold保原，不推进compact |
| SM-T04 | E1反压 | 源READ/目标WRITE成功RSP分别held、取消/错echo | STORE/RC可暂不等；matching边界才等，错误无mirror推进，不复用未知hold |
| SM-T05 | REQ03/E2 | C0/R1，及C1/R0、C0/R0、C1024/R1024 | gid1024或0正确，count2048不当连续读取；无candidate时不造READ0/0byte许可 |
| SM-T06 | E2完成/状态 | reject1、accept2、未写state0、重复2→3 | verified含reject；SELECT0 INVARIANT，完整400 body，禁止phase13新1/2写及wholeSEAL后偷写 |
| SM-T07 | REQ04/HIST | 跨tile平 plateau/峰、旧halo等待新首9、空tile | 旧HIST物理空后可clear；567与plateau继续，真实新首9后判旧末，无等待环/漏峰 |
| SM-T08 | E4版本/SEG | RAW sealed仍readheld时切center；coarse→fine；M2有孔submask | 拒早复用/旧version写；真实newwriter保coarse，第6遍CELL fresh且不第三扩展 |
| SM-T09 | D/SC fence | old RQ/RSP/DDR/jnl/borrow逐一held、admin等RETURN | 新publication停而old可fire；quiet不等待依赖它的最终admin，ACTIVE后续沿恢复 |
| SM-T10 | E4ordinary/lane | ordinary RSP长期held；DENSE两lane间槽返还 | ordinary不得早free导致源引用消失；DENSE wholegroup/sourcelease保持，未知effects进Q |
| SM-T11 | 空集合/输出 | E/M/S/C/R/F均0，FULL INIT与独立C均执行 | 明确实际管理资格，ANN全N和RECORD64仍写，初清独立计费，不虚报整包成功 |
| SM-T12 | F边界/费用 | count=768/1024终态、bucket3、单位端点、FIT用途切换 | 终态不寻址/扩位核域、非法拒绝、旧NUM静止；真实事件账与静态容量分别核 |
| SM-T13 | E4核验统计 | phase11矩形后phase12圆/矩形，旧FIT内容不同、NUM回复held | 旧引用未静止不得clear；fresh圆LS/四侧TLS及高padding、kind17/18从本次冻结POINT谓词产生，不借CIRC缺字段或旧fit |

拟局部/组合测试均同core旧沿fire、沿后稳定观察、可变反压/DDR延迟/取消/复位；未确定seed/全bench工具范围，不称coverage已过。算法GT质量、camera/HDMI/全机1080p/引脚时序继续整体计划，本卡测试不替代质量验收。

## H. 双向追踪

| REQ/来源 | MOD | IF/局部不变量 | 计划单元（未生成） | TEST | 实際基线/证据 |
|---|---|---|---|---|---|
| SM-REQ01 / SC D5 | SCHED/O/SC/GUARD | D真实phase/fence/held义务 | stage permission/fence adapter，文件待共同freeze | T01/T09 | 仅来源SHA及文档审阅，未实现 |
| SM-REQ02 / R4R D3/E2 | GUARD/SCHED | E1两份bucket_map、单调frontier/copy_hold | anchor occupancy/pack proof | T02–04/T12 | 未实现/未运行 |
| SM-REQ03 / R4R E7 | GUARD/SCHED | E2两区间/verified/400原子/FINAL顺序、E4本次核验统计 | VC candidate/verified guard / fresh FIT_STATS | T05–06/T11/T13 | 未实现/未运行 |
| SM-REQ04 / R4R E2/E5、旧EX第6遍 | SCHED/RA/O | E3 carry引用/E4 freshCELL及sealed newwriter | histogram reuse/segment final projection | T07–08/T12 | 旧算法对照不授旧RAM资源 |
| 真实效果/关闭 / RA/RAW/BK | RA-J/物理/O | E4 ordinary与lane不同退租门 | shared journal/END/return adapter | T09–10 | 接口仍SM-B04，未实现 |
| 完整输出 / R4R E8 | OUTPUT/O | 全N/64显式覆盖、真实COMMIT/retained admin | output stage map | T11 | R1验收仅其原范围，不是识别证据 |

反向：矩阵/稀疏guard/VC guard/carry复用/fineCELL/fence/输出每项均关联以上真实要求，新增权威proof源自现行协议的有效范围缺口；租约桥/资源未知不借空泛需求伪装完成。

## I. 评审与设计门槛

①整体行为/边界例：B；②职责/连接：C；③接口上限与组合：D但真实桥OPEN；④局部proof/中文草图：E；⑤语言/映射/部分费用：F；⑥局部/端到端文字走查：B/E/G；⑦实施/验证/追踪：G/H，具体实施清单待共同freeze；⑧无阻塞未满足SM-B01…04；⑨保存/读回/独立审阅由文档检查点登记；⑩本v0.1范围与来源清楚，但没有实现基线。
READY_FOR_REVIEW：未达到。停止点是未批准设计禁止生成实现，不请求用户批准这个仍有实质缺口的卡。原R1批准保其本义，未新增Approval Manifest/数据库记录。理解验收待用户实际作答，不把本解释标已理解。

## J. 变更与恢复

相比旧R4R/RA/NS，本卡明确phase4值及26表操作上限；新增ANCHOR稀疏STORE/RC proof/单调压紧、VC真实双区间/核验完成proof；拆开HIST物理quiet与数学pending；采用既有M2第6遍freshCELL及VERIFY/RECT实际FIT_STATS新统计；新选择明确ANCHOR/SEED/PAIR/CIRC/RECT/fineSEG的stage SEAL；统一ordinary原RSP消费后退休。
旧来源保持不改，未来共同版本需吸收这些语义及完整admin/fence/实例/预算，重新设计评审与指定批准。不能以此卡配置或设计文档写入视为实现授权，不更改已批准R1代码/结果。
恢复需复核来源hash、文档finaldiff、仍OPEN接口与当前审批；候选字段未落位不与未来版本静默兼容。文档撤回保历史JSONL身份，不执行硬件/DB恢复。

## K. 实现与验证实录

业务代码/参考/TB/功能脚本：未生成；编译/仿真/综合/布局布线/时序/bit：本卡未执行。R1既有证据沿原验收，不重跑或扩称全11项；R2/Q0 pending保持原问题。这里只作文档/容量算术/来源身份检查及有限独立审阅，具体读回/哈希/审阅意见在交付审阅记录。
正式状态仍WAITING_FOR_HARDWARE_BASELINE，Manifest/TASK_LEDGER/数据库和硬件状态不改。PostgreSQL配置只presence核，不输出秘密、不扩R1审计例外；无EDA挂起等待句柄、本卡没有新软件运行。

## L. 交付与人工阅读

阅读 B整体16阶段→C谁拥有事实→D逐表允许什么→E1原槽存在/压紧→E2候选与已核验→E3未来输入和物理引用→E4封存/重建及日志次序→F部分费用→G/H计划与追踪→I未决。本卡与审阅/进度入口按实际检查点身份登记。
人工例：桶383的一点经完整写/effects、正确RSP→冻结bucket map→STORE实际frontier766 READ保存hold→WRITE0完全成功→matching RSP使两prefix1→旧引用静止→SEAL1→新phase4真实ACTIVE后READ0。中间任何held/错echo/未知effect不越过该步骤。
已完成的是本卡有限设计选择与静态核；SM-B01…04、全机RAM/FF/DSP与处理时间、生产输入输出、全部实现和仿真/EDA/bit仍未交付。按完整十一项继续，不把局部卡/资源容量/原R1实验当“保证已证明FPGA全部实现”。
