# TRACK4-RECOGNITION-EXECUTION-001：识别内部执行设计 v0.1

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)填写；2026-10-04。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED；业务实现、可执行参考、测试、仿真、综合、PNR/STA均NOT_RUN。** 本稿集中补充识别算法的RAM地址、原子提交、成员冻结、覆盖率、逐行输出及关闭次序。它是设计提议，不是软件已运行的证据。

## A. 状态与阅读入口

- Goal：在整机五基础/六高阶的位置不变前提下，消除ALGORITHMS的AG-B01内部执行歧义，使中文草图能够直接支撑未来编码。
- Current state：已有四phase识别、NUMERIC数值、DATA-JOIN所有权及ALGORITHMS候选；尚无本次识别源码。
- Target state：绑定一份job/profile，按真实事件完成有限扫描、完整记录与ANN，释放义务后交付终态。
- Gap：AG-B02全机FF/DSP、真实DDR服务期限和性能优化，AG-B03质量执行及AG-B04外部契约/批准/数据库仍未解决；本稿不以局部RAM预算或有限终止替代它们。
- Assumptions：预设Ti60F225 V4/I3、SC431HAI彩色四lane、主图1920×1080；这些是软件实验预设，不改正式H0实物状态。core100MHz为待平台验证的目标。
- Open questions：上述外部和整机预算影响实际实施；不把撤回的尺寸、比例、目标数、遮挡/噪声边界恢复为输入限制。
- Dependencies：ALGORITHMS、NUMERIC、DATA-JOIN、RC、CONTROL-JOIN及平台/DDR版本联合吸收。本稿相对差异集中在J节。
- Milestones：保存并全文读回→一次交叉读审→整机预算/性能与外部合同→整体READY→指定版本批准→独立工作副本/实现/真实检查。
- Human approval gates：无实现批准；FRONTEND v1及已有DDR模型申请维持原待回复对象，不新增重复批准问题。正式运行仍核验Manifest/数据库。
- Rollback：只替换本稿及本次索引差异；原始资料、旧设计、正式state/ledger/Manifest/DB保持不动。
- Completion criteria：本稿的局部闭合不等于完整软件完成。全机门槛、批准和真实仿真/综合/PNR/STA/bit证据满足后才有软件验收。

### A1. 实际读取与冻结来源

| 来源 | SHA256；职责 |
|---|---|
| [ALGORITHMS v0.1](design-TRACK4-RECOGNITION-ALGORITHMS-001.md) | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB；算法/字段/版本 |
| [NUMERIC v0.1](design-TRACK4-RECOGNITION-NUMERIC-001.md) | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A；scalar/fit/ROM |
| [DATA-JOIN v0.1](design-TRACK4-DATA-JOIN-001.md) | B09B9FEAC91698E2DC482F92EEB287DB172C5D1A9229D7C9DA226B630FB69408；scope/grant/phase/借用 |
| [RC v0.1](design-TRACK4-RECOGNITION-001.md) | D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5；四phase与图布局 |
| [v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；设计/批准门槛 |
| [VF/Demo实际资料复核](../experiments/track4_full_sw_20261004/01_baseline/vf-demo-supplemental-evidence-v1.md) | 6E8823391907B5D9A42E7DB854E01648EC522952F3DD9E61699AC03CF9B10979；已有DDR/PHY/模型及精确2Gb依赖缺口 |

上述旧文件只读，本稿不隐式覆盖已冻结业务输入。最终联合版本必须显式吸收J节差异。

## B. 整体外部行为

| REQ | 派生于现有用户要求的执行规则 |
|---|---|
| EX-REQ01 | 同一完整SRC/EDGE/GRAD、C570、Origin及PROFILE快照贯穿四phase；动态配置不修改在途job。 |
| EX-REQ02 | 每个同步RAM读先预约capture；完整多word提交后才发布记录资格；旧pending关闭前不换用途。 |
| EX-REQ03 | 圆五遍及矩形六遍重放固定成员，计数不相容为内部失败，不悄悄重新选点。 |
| EX-REQ04 | run间隙和最终可见边覆盖率按真实位置/长度；不以count或occupied/span近似替代。 |
| EX-REQ05 | 全部VC核验/排序/去重后冻结FINAL；ANN按连续像素流写完整头、清单、图及规定尾零。 |
| EX-REQ06 | 取消仍兑现旧RE/capture、NUM/FORMAT和MC承诺；终态、物理释放和本地借用各用实际证据。 |
| EX-REQ07 | 所有缓存、容器和循环有明确容量/界限；容量失败保留为失败帧，不能截断成成功。 |

正常例：接纳合法job→P0完整点集→P1种子/圆→P2线段/矩形→P3统一核验、去重、FINAL冻结、完整ANN→本地关闭、phase fence和grant/PROCESS借用ACK→固定success status。零边缘点也生成count0的完整ANN，不漏关闭。

边界例：同沿取消及已预约RE，先记录沿前真实接受，次沿仍capture旧结果；未提出的新业务停发，已提出W由完整spool供料。无法证明物理关闭则Q/drained0，旧scope与RAM不可复用。

性能含义：有限工作量是终止界，不是帧率保证。HDMI60Hz可重复最近完整bundle；相机/计算帧率独立。识别P/R≥95%仍待包含负样本、重叠和缺边的独立质量执行。

## C. 职责与整体连接

MOD-EX0 job协调器保存唯一经验证的绑定、四phase账本、最早错误和关闭证据；不代替DDR物理账本。
MOD-EX1 native表引擎负责RE预约、capture、逐word完整提交和模式排他；不定义几何门槛。
MOD-EX2 P1执行器负责anchor/seed、radius和固定五遍；MOD-EX3 P2负责DENSE/NMS、真实run、六遍TLS、PAIR与矩形。
MOD-EX4 P3负责冻结geometry核验、coverage、VC/FINAL及排序去重；MOD-EX5负责DRAW/font、row、carry和独立spool。
现有NUM是单inflight数值服务，MC是独立终态/释放服务；旧FORMAT仅在持有者已关闭时分时复用。

阅读连接：MOD-04 → EX-IF01 → EX0 → EX-IF03 / NUM / MC → EX2、EX3、EX4 → EX-IF04 → EX5 → MC ANN；独立EX-IF02 receipt/status和DATA返还连接回MOD-04。数据路径与收尾通道分离，收尾不等下游普通数据空位。

整体检查点：先固定B节外部可见结果，再固定D节绑定/交接，然后阅读E节P1→P2→P3→ANN。新增mask及coverage只服务现有识别，不添加新的业务模式。

## D. 接口与组合检查

### D1. 唯一job与终态容器

EX-IF01候选RC_BIND4731，低bit先：scope623/C570/Origin195/source_camera_cfggen64/RC_borrow_seq64/W11/H11/PROFILE1024/九grant各241。scope含父J486/lease；本稿列的是容器组低到高，各嵌套旧消息内部bit顺序保留其原版本，不反转scope/grant字段；C和Origin不用可变全局值重建。九grant顺序SRC、EDGE、GRAD、META、POINTS、SORTED、CIRC、RECT、ANN，client5、精确base/L/A及perm沿DATA。SRC/EDGE/GRAD R，五TEMP RW，ANN W；permission0非法，富grant由父注册授权产生，调用者裸base不能充当权限。

输入只在协调器IDLE且693bit receipt槽空、实际scope/RC借用及九grant已注册并核验时成为accepted job。receipt槽空时可接纳一次拒绝/忙回执；它不占业务job。W偶数6…1920、H5…1080、N扩位；CFG algorithm2、PROFILE layout2/numeric1/algorithm2、ref/body匹配；保留位、版本、owner/generation/epoch/phase未使用及33bit端点逐项检查。坏输入可握手复制拒绝receipt，但不形成任何业务读取或释放权限。

EX-IF02 receipt693=scope623/RC_borrow_seq64/status2/error4；status沿DATA_CONTROL：0ACCEPTED、1ALREADY、2BUSY、3REJECTED。只在当前已接纳且仍pin的同scope/seq、完整4731bit body完全相等时回ALREADY，不改ctx或重复执行；已忘旧anchor则REJECTED/error10。其它active job占用时BUSY/error14且无效果。结构/保留位/尺寸错error1，scope/借用/grant owner/身份/ref不相容error2，不支持的profile版本error15；其余错误沿DATA统一error4，不新造同名枚举。完整body比较串行分296个16bit块（末11bit），固定现有ctx与请求沿前body，比较期间ready0；不复制第二4731bit长期ctx。等待方必须依ready/valid保持原body。比较期间pin现有ctx，status消费不清其body；比较及相应receipt完成前不退役或改绑。比较结束且receipt可用才fire/形成回执。一份held receipt独立消费；拒绝只回显请求，不归还请求中冒称的对象，父仍按真实注册账本处理。合法接纳与同沿cancel相遇：记录接纳，下一ACTIVE沿进入取消。

候选STATUS965低到高：
scope623/RC_borrow_seq64/phase_closed_mask4/kind2/reason8/E21/line11/segment11/pair10/circ11/rect11/final7/ann_valid1/ann_descriptor96/first_num_valid1/first_num_reason8/first_mc_valid1/first_mc_error3/first_mc_resp2/first_mc_seq64/counts_final1/local_closed1/drained1/success1/borrow_return_acked1/grants_return_acked1。

kind继承0OK/1FAILED_DRAINED/2CANCELLED_DRAINED/3Q；reason0无错、1输入、2容量、3数值、4内部不相容、5MC、6取消、7时钟/隔离、8平台关闭不明，其余保留。NUM原8bit原因、MC原3bit/RESP2/seq64独立保留，不用聚合reason截断原错误。记录沿前第一次实际出现的错误，若同沿NUM与MC均首现，各自记录；聚合优先MC→NUM→内部→容量→取消。取消不掩盖已有失败。

status只属于accepted job。接纳时首错误valid和相应raw字段清零；first_num_valid0则reason0，first_mc_valid0则error/resp/seq均0。OK须reason0及合法ANN descriptor与已授grant完全匹配。失败ann_valid=0且descriptor96全零；counts_final仅全部生成过程结束才为1，其余数量是固定快照。success须kind0、全四phase实际close/fence/release ACK、本地drained、全部grant return ACK及RC PROCESS_BORROW_RETURN ACK同时成立；phase mask只诊断，不替代证据。Q允许local_closed=0/drained=0，提出后不追加改变body。后续旧scope恢复另走父恢复事件。

正常RC借用仍用DATA **PROCESS_BORROW_RETURN702/ACK708，role3**，不另造短return。返还和ACK独立于status消费；合法close后先返还、采样ACK，再冻结status。bad binding不伪造return。scope、C、Origin、profile和九grant全程仅一份4731bit固定容器，各子模块持短key137并pin此ctx，旧义务未闭合不接受新ctx。

### D2. 表与数值交接

EX-IF03沿ALGORITHMS：LOOKUP_REQ147=key137/id10；RESP541=key137/id10/outcome2/reason8/coarse128/fine256；COMMIT531=key137/id10/body384；RECT659=key137/index10/body512。
新增COMMIT_DONE157=key137/id10/outcome2/reason8，与RESP互斥共用541bit holding。COMMIT fire仅表示完整body已复制；DONE表示实际20次WE和发布沿已完成。取消照旧key独立消费DONE，不把接受提交当完成写。

EX-IF04 VC400、FINAL512、DRAW80沿ALGORITHMS字段。FINAL对下游有效事件只有全表冻结，私有keeper append不提前对外有效。全局best400独立；旧512bit组装槽用于其它记录，禁止覆盖best或未消费FORMAT。
NUM_REQ543/RESP540、MC_R155/W152/terminal301/release288及ACK293保持原DATA/NUM版本；logical seq不能等同物理ID0。MC完整key由固定ctx和对应phase/service_seq恢复，不因省FF丢弃错误身份。

### D3. 固定RAM及模式所有权

全部native20×512、9bit地址、core正沿、OUTPUT_REG0；完整20bit写、WE=11。读在发RE的沿后更新，下一沿捕获。不能把10bit使能当字节使能；不依赖同址碰撞结果。关闭旧owner后逐址CLEAR，不整阵功能复位。

| 固定池编号 | 数量 | 用途 |
|---|---:|---|
| B0…31 | 32 | P1 radius17；P2 DENSE32/两CELL/EXT32；P3 VC的一部分 |
| B32…39 | 8 | P1 anchors/两峰表；P2 LINE；P3 VC |
| B40…79 | 40 | P1 seed/ledger/LS/context；P2 SEG384；P3 VC |
| B80…83 | 4 | P2 CELL companion后PAIR；P3四coverage |
| B84…87 | 4 | P2四NMS快照，NMS关闭后CELL companion |
| B88…91 | 4 | FINAL64×32nativeword |
| B92…93 | 2 | 两行2bit map |
| B94…97 | 4 | 四个128×64bit STREAM区域 |
| B98…101 | 4 | 原scatter缓存 |
| B102 | 1 | 原32桶目录 |
| B103/B104 | 2 | 原theta/projection+font ROM |

识别RAM103+两ROM=105。全机候选44 Canny+17DS+105RC+30PL+13CAM−9旧显示FIFO+21DP+4独立reader=225/256。DATA RGB reader4和RC STREAM4独立，不能双重借同一RAM。该算式不是综合报告。

P3池B0…79为80RAM VC，B80…83为coverage；B84…87此时空闲。FINE模式为stripe并行记录，VC模式为线性nativeword，模式转换时必须关闭所有旧RE/capture/WE、NUM、FORMAT、MC segment和本地borrow。

### D4. 组合设计走查

- 经验证4731输入满足DATA富grant与算法2profile前提；旧Canny/reader全部grant/借用ACK后才授RC九grant，不能同时跨旧所有者使用。
- MC R段copy/terminal/release关闭后可归还物理资源；本地STREAM bank仍由语义消费者保持，两个事件不可混同。申请同client下一READ不等前一段的数学处理继续借物理槽。
- 本地LOCAL_TERMINAL231在producer6本地关闭后先交付，再由父fence/return收尾；不先等父fence才能说local_closed。
- 模式/phase单调；P2不读本phaseRECT，P3只读P2已fenced候选。取消不要求继续全部未开始扫描，已提出物理义务由独立入口推进。
- E=0时扫描器EOF立即关闭业务，目录/空清单/图零仍完整；FINAL第65个distinct或CIRC/RECT/SEG1025、PAIR513、V4097均整job失败，ANN不发布prefix。

## E. 局部数据、中文操作草图与不变量

### EX-OP01：预约、读写与关闭

表引擎顺序IDLE→RESERVE→RE→CAPTURE→CALC→逐word WRITE→COMMIT→RESULT_HELD。RESERVE先占capture/response空间、固定bank/address/word/key/purpose；已发RE下一沿必须capture，气泡、下游停顿、cancel不撤销它。body有效后保持到真实消费；不以新ctx解释旧结果。

每个表单owner；读锁跨完整record，写锁跨全部WE。最后word实际WE完成，下一沿才增加visible_count或发布DONE。接收同沿读者仍看沿前资格；不把多word记录中状态位更新当原子记录。CLEAR入口要求旧pending空，CLEAR结束下一沿才开放新模式。

EX-INV01：每个RE恰有一次capture及目的身份。EX-INV02：可见record无部分新/部分旧word。EX-INV03：旧key仍valid、借用或Q时，global ctx和该RAM用途不换代。

冷启动仅平台safe-init且无旧物理义务时失效计数；RAM旧内容由资格和CLEAR隔离。功能rst/cancel仅停新数学业务，保留旧账本/holding/pending及承诺供料；clock-loss进入平台Q，不推断drained。

### EX-OP02：P1圆执行

LINE8为local slot0…1023：depth=slot>>9、addr=slot&511、stripe0…3，四20bit组成80bit，低64有效、高16零。anchor bucket=(tile_y×8+tile_x)×8+(θ>>6)，slot=2bucket+lane，8×6×8×2=768；tile边界/rank21沿ALGORITHMS。后续RAW槽0…511、SMOOTH槽512…1023，换用途前旧anchor/pair读取全部关闭。

FINE40 local row0…1023：depth=row>>9、addr=row&511、20stripe；word j为bit20j…20j+19。

- row0…255 SEED128低128，其余272零；key低到高r17/cy_bias18/cx_bias18，随后rank64/valid1/zero10。
- row256…511 ledger每row四key64（cx signed18/cy signed18/r17/zero11）低256，其余144零。精确CIRC geometry key，比较seed时先按版本解除中心bias。
- row512…527统计：LS n21/A43/B44/C43/D56/F56=263bit，其余零；平均模式n21/sum_distance39=60bit，其余零，两模式排他。
- row528…543 context384；row544…1023 P1不访问。P1入口逐row有限清零，不用RAM功能rst。

context低到高r0_17/lower_sum18/upper_sum18/has_lower1/has_upper1/channel1/c1x18/c1y18/c2x18/c2y18/r1_17/r2_17/state3/eligible21/support21/SSE53/sector64/max_residual16/positive_seen1/negative_seen1/flags4/n_expected21/zero17=384，physical高16零。center字段signed18，sum18无符号；state0UNUSED/1ACTIVE/2REJECTED/3RECORD_READY/4COPIED/5CANCEL_DISCARDED，6/7非法。flags沿CIRC原格式，不直接复制FINAL flags；positive/negative诊断沿NUM圆退化条件，不改变最终membership。

每桶occupancy2=0/1/2：空写新POINT；一条先capture旧rank，若新更小先搬旧到slot1再写新slot0；两条分别capture排序，替换最大或搬旧最小后写新最小。rank及其伴随POINT同源，不能用新POINT配旧rank。occupancy/anchor_done只在最后WE后发布；scatter_done只原scatter实际fire。两分支全闭合才释放当前POINT。
压紧按源slot升序，destordinal≤src：先capture，再写dest，WE完推进；先写后读会破坏未读取源，禁止。全pending空后按有效anchor_count枚举a<b，数量anchor_count(anchor_count−1)/2≤294528；不读取压紧后的无效槽。

seed为有限顺序256表：每合法pair完整扫现有项，查精确key并求最大rank/slot；重复不写，未满append，已满仅新rank更小时替最大，否则诊断rank_pruned。首次满256不停止。全部pair后选择排序每个位置扫剩余项，WORK384保留两个SEED128后交换，MAX72保留rank/slot；ordinal作为seed_id13/high5零。处理前扫较早seed，同精确中心由最早ordinal共用全半径域扫描，不按原pair半径截域。

hist用32池的local RAM0…16，addr=(tile内bin)>>4，每340bit row含16×21bit、高4零；RAM17…31不RE/WE。
probe和投票同资格：d0非零、全宽d0≤131071及hist normal13107。probe置16tile bitmap/计数，不写hist；zero/domain诊断只probe一次，避免每tile重复。每非空tile先512次整row WE零，再完整POINTS遍，每合格点只更新所属tile一个bin：RE→capture340→扩22加一→完整340 WE。提交才推进点。

raw连续19×21bit环窗保存q−9…q+9所需数据，跨tile不清；下一tile建立期间环窗冻结，空tile/域外真实零供给。中心q的RAW/SMOOTH峰判断必须等raw至q+9，旧tile末9bin不能提前判。各路平台82bit=height21/start_radius17/start_raw_count21/start_window_count21/left_less1/active1；正平台左右邻均严格更小才出一峰，取平台最小r。两路同沿结束各保留64bit输出槽、暂停环窗，分别写完再推进；第513峰失败。合法峰q1…131071，bin0/域外只halo；SMOOTH ±8bin，不输出r0=0。

每16峰组读取当前及同路相邻峰，固定lower_sum=前峰+r0、upper_sum=r0+后峰；最近峰分区P为2d0>lower_sum且2d0≤upper_sum，无邻边关闭该比较，tie归较小半径。先全宽domain检查再比边界。五遍不再查询可变峰表：
A：P及c0/r0宽64Q4/normal13107门累计LS，n≥3、Δ/condition/domain通过得c1，保存n_expected。
B：准确重放A资格，仅被平均距离相对c1；n21/sum39，n==n_expected，RNE得r1。
C：保留P，但宽门改冻结c1/r1，LS得c2并新n_expected。
D：准确重放C资格，仅平均距离相对c2，核n相同，RNE得r2；不得用c2重新选择成员。
E：完整POINTS、不再限制P，对冻结c2/r2计算eligible/support/SSE/sector，完整mask后判wholecandidate门。
相对合法signed18中心与图内point的平均distance用全宽uint18，sum39；除法/RNE后再核radius17域，域外候选GEOM_RANGE拒绝。重放n不符整帧INTERNAL，不是普通拟合退化。

A–D同路每POINT仅命中一个分区；E依次检查本组≤16候选。point须等相关commit全部闭合才推进。FINE capture400和WORK384独立，统计读取不覆盖成员快照；中心求解结果用MAX72暂存。每候选精确ledger最多256row读，新key先写未计数位置，再由FORMAT完整copy/fire增加circ_count；cancel DISCARD不当正常copy。CIRC1025失败；物理W仅来自接收方完整复制后的独立源。

STREAM四20条带低64有效。两POINT read bank local addr0…127/128…255；R128先入holding139=data128/index7/last1/error3，完整tag在Rfire与可信record核对，bad_tag保存在控制槽。随后两64bit WE；末奇数第二word仅padding、不增加E。完整copy、匹配成功terminal和真实release ACK后SEALED。
service local_drained只等本段holding/copy/pending/服务借用，不等算法消费bank或phase fence。bank仍私有保持；末wordcapture到独立POINT64后该FF不再借bank，bank自身pending及MC释放关闭后FREE，下一沿重授。每pass旧POINT/pending关，bank保存pass_id/base/service_seq，不按新Rrecord解释旧bank。

stream仲裁为R_COPY两WE、W_FETCH RE/capture、POINT_FETCH RE/capture三角色RR；只授已预约目的空间的角色。算术等待不占stream grant；sealed W不等新POINT。
terminal独立301槽，不等普通POINT/FORMAT；kind1/2真实terminal_fire共同作废未接受逻辑拍，旧capture后DROP、不复活valid。NUM/POINT/FORMAT取消按旧ctx独立DISCARD，已提出req和物理W仍兑现；kind3不产生普通释放。功能暖rst不清record/pending/RAM输出。

精确FF列表：POINT64、两anchor/两峰128、三rank或距离63、384桶occupancy768、LINE capture80、FINE capture400、hist capture340、WORK384、MAX72、ledger64、c0x18/c0y18/ordinal8/valid1/zero3=48（输出seed_id13高5常零）、raw19×21=399、平台164、三个box和63、tile bitmap16+counts336=352、16诊断1024、有界控制512，合**4925**。
另R_RECORD384/terminal301/Rholding139/两bank160×2=1144，合**6069**。
R_RECORD384低到高req266/receipt_seq64/valid1/terminal_seen1/kind2/success1/drained1/error3/actual7/release_held1/ack_seen1/ack_status2/ack_error3/logical_R_count7/stop1/zero23；release288/ACK293由固定record形成，不再复制整个body。
bank160=pass32/base_point21/logical_words8/received_beats7/expected_beats7/read_index8/state3/invalid1/private_borrow_count2/service_seq64/zero7。原NUM/FORMAT512/global ctx/profile/W保持域不在6069重复计，也不能省略全机对应容器。

有界：anchor每point≤2RE/2WE，压紧≤768读/写；每pair≤256seed读；seed选择排序≤32896读/512交换WE，同中心查重≤32640读。hist每中心≤16×512清、投票总≤256E、hist总row读≤2097152；337遍/中心上界不增加。
非像素RC_STAGE的LOCAL_TERMINAL pair/pixel/byte未适用字段规范0，不把1.431TB流量塞physical_done_bytes32；真实64bit统计独立保存。

### EX-OP03：P2 DENSE与NMS

DENSE target k0…15用B(2k)/B(2k+1)，addr=rho；low20及high word bit0为count21，high19零。每batch先清32×512地址，rho277…511零、不参与NMS；完整系数加载后POINT/valid共同CE推进3级乘法。16bin已登记且RMW容量就绪：e0 RE→e1capture并扩22bit加一→e2完整WE→e3才可下一组RE；停顿/DDR另计。

四NMS RAM分别θ0、θ1、rolling前行、rolling末行。每快照word0…276低20票；word277+floor(r/20)存第20bit于r mod20，最后只17bit有效；291word全部写后才snapshot_valid。low/high同RAM必须分次RE/capture，high FF满20位或末rho另WE。
batch0处理θ1…14，保留0/1、14/15；后续先处理旧末θ和新首θ，再内部，旧rolling读关闭后才能覆盖。最后处理511及延迟0；跨π边界镜像整个rho坐标276−r，越0…276邻居不访问。相等票用既有canonical tie，不能重复处理延迟边界。

LINE64：id[9]选两depth组，每组四stripe、addr=id[8:0]；θ9/rho9/count21/zero25，physical80高16零。1025峰为失败。

### EX-OP04：真实CELL/EXT、coarse记录

两个CELL：g0/1，c0…4095，s=c[11:9]，B(16g+2s)及下一bank，addr=c[8:0]。低32为原CELL32；physical位32…39存submask低8。
companion借已关闭NMS4及尚无PAIR的PAIR4，顺序B84…87/B80…83；j=4096g+c，w=j>>1；bank=该8池的w[11:9]，addr=w[8:0]。偶j用低8、奇j用次8存submask高8，高4零。逻辑CELL zero2不变；物理spare是新增私有字段。
EXT c用4s…4s+3的32池，低64为EXT64、physical高16为完整submask，逻辑zero13不变。

cell=floor(tQ4/16)+2048，扩位检查0…4095后收12bit；sub=tQ4−16(cell−2048)∈0…15。例t=−1→cell2047/sub15。重复位置只增count、bit不重复；逐置位位置可恢复真实tlo/thi/maxgap。CELL RMW锁住POINT/cell/companion，保留同word另一cell高8，所有WE完成才放下一点；不用同址转发假设。

每peak49×21bit offset和49bit资格；按两seed一组完整POINT遍、扫描两CELL真实run，最多13E；加offset一遍≤14E/peak。真实相邻t差>48Q4断run，同cell内位置也参与；occupied为不同1px cell数。run覆盖率是占用cell区间与[tlo,thi]交集长度/span，用Q4整数精确首尾扣减；不直接occupied×16/span，span0拒绝。

SEG384位0…127 coarse，128…383 fine；id[9]选两depth组，各20stripe，addr=id[8:0]；word19低4有效、高16零。完整384先写，fine=PENDING，发布沿才segment_count++。必须先存完全部coarse，随后逐段TLS；不能在另seed CELL仍未读完时切EXT。

EX-INV04：submask记录所有量化真实位置；count不代替位置。EX-INV05：PAIR模式启动前全部CELL/EXT/companion义务关闭；不存在同RAM同时两用途。

### EX-OP05：切向与严格六遍TLS

n规范后固定t=(ny,−nx)；n反号时t/rho同号变换，μ反号，区间(-thi,-tlo)，端点censored低/高flags交换；coarse θ归属不变。
端点恢复使用完整方程：Bn=2^30·rhoQ4，Bt=2^30·tQ4+8[tx(W−1)+ty(H−1)]，den=nx·ty−ny·tx；xQ4=RNE((Bn·ty−ny·Bt)/den)，yQ4=RNE((nx·Bt−Bn·tx)/den)。不把实际den改成假定±2^60。

冻结M0=coarse peak/offset/gradient/coarse闭区间；M1=TLS0残差/gradient+run1在TLS0切向闭区间；M2=TLS1残差/gradient+run2在TLS1切向闭区间。旧均值μj=RNE(8(txj Sxj+tyj Syj)/(nj 2^30))；“距旧均值≤2px”明确为dist(μj,run闭区间)≤32Q4，非新run均值。[160,320]中μ336接受、368拒绝。另核shared>0、n≥3、occupied≥2、coverage；按shared降/total降/tlo升选一个run。

| POINT遍 | 操作及冻结结果 |
|---|---|
| 1 | 清217统计、重放M0，核n=coarse n，TLS0/μ0 |
| 2 | 清EXT；新资格TLS0、old_member=M0，选run1并冻结M1 |
| 3 | 清217统计、重放M1，核n=run1计数，TLS1/μ1 |
| 4 | 清EXT；新资格TLS1、old_member=M1，选run2并冻结M2 |
| 5 | 清217统计、重放M2，核n=run2计数，TLS2及n/Sx/Sy |
| 6 | 清CELL，仍重放M2，投影到TLS2，最终端点/occupied/maxgap |

TLS0相对coarse、TLS1相对TLS0、TLS2相对TLS1各核4°及anis；第6遍不改变M2、不暗加第三extension。每遍入口旧NUM、POINT、capture及物理R复制义务闭合，EOF才fit/run扫描；计数在同点全部事务完成时只增一次。
退化/无run为该segment REJECTED，fine数据零、coarse保留；重放n不符、越界/溢出为整帧INTERNAL。

FINE state在combined bit379/380跨word18/19；读取和写提交均锁完整record，最后word19 WE后下一沿发布DONE与完成资格。VALID/REJECTED不再改。不得仅写一个状态word自称原子。

### EX-OP06：PAIR、矩形组装及核验尝试

全部fine完成且无PENDING/COMMIT/响应，关闭companion后下一沿清PAIR count、进入PAIR。
PAIR64用四stripe、addr=id[8:0]，s0_id10/s1_id10/diagnosticθ9/zero35，physical80高16零；s0<s1，θ取较强支撑段coarse θ，同票低id，仅诊断。
遍历a<b核原fine2°平行及共同轴截距非零分离。四边用四distinct段，三边第三段与pair不同；原fine方向先3°正交，原fine交点投影须在[tlo−32,thi+32]。再形成共同轴、各角独立RNE，检查非零边/面积/不自交/CCW。
三边远端由原fine完整恢复，冻结censored/对齐，不读已复用CELL。每次完整核验前先计attempt，拒绝也计；V4097失败。最终四量化边用统一有限边membership，present不改变单点侧选择。
RECT组装可变期间不对物理W有效；完整复制独立spool并SEALED后才请求，保证不等未来数学数据供料。

### EX-OP07：P3 VC、量化边与精确可见覆盖率

顺序POOL_CLOSE→VC_INIT→VERIFY_LOAD→GEOMETRY_CLIP→COVER_CLEAR→POINT_SCAN→COVER_EVAL→FIT_DIAGNOSTIC→VC_COMMIT→SELECT_SCAN→KEEPER_CHECK→CONSUME→FINAL_FREEZE→DRAW_BUILD→ANN_EMIT→LOCAL_CLOSE。

实际ordinal0…C+R−1：圆gid=ordinal，矩形gid=1024+ordinal−C；只扫描真实计数，无效洞旧state不读。VC nativeword a=20gid+word，bank=a>>9，addr=a&511，可跨bank边界；pending保存word/bank/用途。Q/终止ordinal12bit，C/R11bit。
VC state在bit389…390，即word19 bit9/10；INIT只对实际gid word19清state0，SELECT未启用。核验成功先word0…18、最后word19带state2；拒绝完整零body、最后state1。SELECT发现有效gid state0为INTERNAL。消费保留word19其它有效位只改state3，WE关闭才清best_valid。best400独立。

最终边i固定CCW的Vi→V(i+1)。d=B−A，最近侧按四有限边精确N/D选，tie低id，再同一eligibility/support门；法向符号规范不反转d。最终fit_*只从同一冻结geometry inlier遍累计LS263或四TLS217，诊断不写回geometry。present只影响wholecandidate门及required fit质量。

coverage可见窗Q4闭[-8,16W−8]×[-8,16H−8]，只定义长度，不改变bbox/flags/画坐标。λ初[0/1,1/1]；d>0用(L−A)/d、(U−A)/d，d<0用(A−U)/(−d)、(A−L)/(−d)，d0且A不在窗则不可见。正den，完整cross乘取maxlo/minhi；λhi≤λlo无正长度，required拒绝，其它诊断0不除零。
clip候选num signed19/den uint19，比较signed40；最终0≤n≤d的lo/hi四字段uint19。K=d·d uint39，真实t=λ√K/16 px。

单元[j,j+1)：j_base=floor(tlo)，j_last=ceil(thi)−1，span=j_last−j_base+1；bitmap索引j−j_base。可见长度≤sqrt(W²+H²)，主图span≤2204<4096；absolute j uint15、span uint13。
inlier投影z=p·d限[0,K]，j=floor(z/(16√K))，15次二分比较256j²K与z²，走完整乘积，不先RNE投影；只有j_base≤j≤j_last才置位。半开端点不补邻位。

B80…83各一侧4096bit，native0…204，末word高4零；256…271存320bit元数据，其它不访问。
元数据低到高Ax18/Ay18/dx19/dy19/K39/lo_n19/lo_d19/hi_n19/hi_d19/j_base15/j_last15/span13/O13/b0_1/b1_1/coverage16/visible1/required1/zero55。
先清205word、完整四侧元数据WE闭合，再POINT遍；置位RE→capture→WE，保持point/side/bin至WE完。末遍逐侧读205word核span外零，统计occupied O、首末b0/b1。

令Q=dlo dhi，A=b1 nhi dlo−b0 nlo dhi，V=nhi dlo−nlo dhi，B=O+b0 j_base−b1(j_last+1)：
Lcov=B+A√K/(16Q)，Lvis=V√K/(16Q)。
精确门65535Lcov≥threshold Lvis化为T+U√K≥0，T=65535·16BQ，U=65535A−threshold V。同号直接判断，异号比较T²与U²K，方向由正项决定；相等是精确相等。RNE coverage16先二分求floor比值，再用2·65535与2q+1比较半整数界，相等取偶。先核0≤Lcov≤Lvis，违反INTERNAL，不能饱和遮掩。
Q38/A signed40/V40/B signed17/T signed77/U signed59；T²≤154、U²K≤157有效bit。每乘法仍保留scalar完整384bit及385guard/24word，检查高零后才收uint160比较槽，不把完整乘积缩为192bit。

EX-INV06：冻结geometry唯一决定最终membership及dedup；fit诊断不重新拟合。EX-INV07：coverage是可见区间与占用单元真实交集长度，最末裁切和同单元情况亦成立。

### EX-OP08：私有keeper、FINAL与DRAW

SELECT前清四FINAL RAM全部2048word；内部slot bank=slot>>4，addr=(slot&15)×32+word。keeper先完整512快照，26有效word末高8零，再6零word；32WE及pending关闭后才私有count++。重复判断结束或完整keeper后才VC state3。第65 distinct失败整ANN；没有state2及全部NUM/POINT/表义务闭合才final_frozen，对外FINAL有效，此后只读。

全部VC/best借用关闭后B0改DRAW：64条×4word，addr4slot+word≤255，DRAW80沿算法bbox44/labelxy22/charlen3/clip1/zero10。完整F条写完后才row读。
font仍ROM258…355，旧projection RE/capture和NUM全关后进入font用途；pending保存addr/glyph/row/purpose，次沿capture，不在正常RASTER再做projection查询。

圆Q5：C5=2c，Rlo=max(0,2r−stroke)，Rhi=2r+stroke，dy5=32y−cy5。
Ao=Rhi²−dy5²<0跳过；否则外区间ceil((cx5−floor√Ao)/32)…floor((cx5+floor√Ao)/32)。
Ai=Rlo²−dy5²>0时用floor√(Ai−1)删严格内洞，最多两闭区间；RNE_sqrt经平方检查必要时减1得到floor。C5±Rhi signed21、负数数学floor/ceil，最后clip到合法x。
矩形逐侧保守Q5范围逐pixel核精确4N≤stroke²D，四有限capsule union，不加support/法向门或延长成无限线。

### EX-OP09：row、carry、sealed spool与关闭

每row FREE→CLEAR→DRAW→SEALED→COPY→CLOSE→FREE。CLEAR ceil(W/10)word；DRAW按x/10和lane 2bit OR，latest锁bank/addr/data/valid/dirty。同word用latest，换word先WE dirty再RE/capture。所有RMW关闭才SEALED。
COPY只取min(20,2(W−10word))有效bit，不把内部padding插入连续map；全部copy/capture/借用关闭才CLOSE，下一沿FREE，再下一沿可CLEAR。row不直接借给物理W。

四STREAM区域各128×64bit，VERIFY两个区分别candidate/POINT批，完整copy+terminal/release后才同client下一READ。ANN两个区改成独立1024B spool，其余不借来暗扩容量。沿前物理释放与本地语义借用分开记录。

流顺序header128B→list4096B→连续map；LIST FORMAT held阻止公共512槽复用，但不阻止MC收尾。
carry128/fill_count8/input20：只搬入当前余量；满128冻结，分两次64bit WE到FILL spool；两WE完才清carry/继续input余位。不逐行补齐；最后N像素才补到完整128bit，末bit/byte零。W6/H5/N30末4bit和后8byte零。

spool FREE→FILL→SEALED→OFFERED/BORROWED→CLOSE→FREE。SEALED前数据/尾零/FORMAT真实接受/pending/WE全闭合；从SEALED至terminal/release ACK、held W及spool capture/borrow闭合，内容不变。FREE提交后下一沿才重填。
ANN页对齐每段1024B，末段剩余16B倍数，≤64拍、不跨4KiB；主图511段、32664拍。未接受FORMAT不作物理W源；spool复制完整亦须原FORMAT交接实际闭合才放请求。

取消本沿先记真实握手，再停新candidate/NUM/row/未提出spool；预约RE仍capture，valid NUM/FORMAT按旧ctx独立消费/DISCARD；已valid MC req/W及已承诺段由完整spool兑现，不等未来行。未提出FILL/SEALED可在pending闭合后丢弃，未提出permit按DATA归还；关闭不明Q禁止复用。
LOCAL_TERMINAL不等父fence；phase fence/release、grant return、RC role3 borrow return、固定status依次有实际证据。EX-INV08：SUCCESS不是末W握手或本地EOF，而是完整关闭联合结果。

## F. 语言、资源与有限工作量

| RTL A–L | 本稿契约 |
|---|---|
| A 数值 | D1–D3/E4–E9全宽、signed、floor/RNE、收窄先核；几何/地址不回绕，hash置换例外只沿算法。 |
| B 时钟 | core正沿fire，RE沿后更新次沿capture；未来TB正沿后稳定区观察，沿前资格决定本沿接受。 |
| C 接受 | ready/valid真实fire；捕获和响应先预约；物理不能取消的R/terminal独立入口常推进。 |
| D valid | 无效body忽略；业务point只在该点全部事务完成推进一次，气泡不增数量。 |
| E 反压 | key/data/用途及ctx保持；不能撤回旧valid或让spool等未来业务。 |
| F 延迟 | RE→capture；逐word WE→下沿发布；DENSE局部e0/e1/e2/e3；DDR/NUM等待另计。 |
| G 复位 | OP01/E9冷safe-init与功能stop/保持域分开；Q不释放，不整RAM功能清零。 |
| H 配置 | accepted RC_BIND一次固定C/profile/Origin；同沿cancel记录接受后收尾，不热读阈值。 |
| I 存储 | 固定20×512、模式排他及RAM225；submask/VC跨bank/row/spool边界明确。 |
| J 身份 | POINT64 row-major及桶padding沿父稿；geometry Q4、coverage像素面积窗、画x/y clip互不混同。 |
| K CDC | 本稿同core域，无新增CDC；外部MC/DDR/display复位/CDC由父平台闭合，不推定可直接连。 |
| L 实现 | 全机FF/DSP、真实DDR服务与STA仍AG-B02/04；本稿数值容器上界不替代XLR/布局结果。 |

C++仍为未来独立逐位参考角色，沿NUMERIC已核标准/工具；所有权由job局部值对象持有输入view到比较完成，无返回临时引用。固定表域检查先于索引/窄化；显式宽整数/RNE/floor及错误返回，不靠signed溢出。单线程计算核心无网络/DB/硬件副作用，容器容量与失败同B/E。
共同数值是冻结geometry/整数门；硬件执行是上述fire/capture/commit/关闭；软件结果按J/Origin/C/profile、point/候选gid/FINAL slot及ANN连续像素事务比较，取消后无效结果不进入成功比较。软件无cycle语义，不能代替RTL协议检查。

### F1. FF容器估计

沿旧14778已列局部FF，不做跨phase优惠抵扣：
P1改6069替代旧4883，增1186；P2增3911；P3增2392；global RC_BIND4731+receipt693+status965=6389；协调器有界flags/indices/phase/service-close控制预留512，原完整NUM/MC payload槽不因此省略。
合计**29168bit已列候选容器**。不等于全机FF：RGB/相机/显示/DDR/平台及外部MC承诺holding等仍需同一张全机表闭合。局部已列容器亦不能证明Ti60全机装得下。P1精确逐容器见E2；P2/P3分配如下。

| P2新增容器 | bit |
|---|---:|
| 1228工作集替原556 | 672 |
| offset49×21+资格49 | 1078 |
| peak | 128 |
| 两μ | 36 |
| current/best run | 384 |
| cell RMW/snapshot/九邻票 | 128+96+189 |
| 两PAIR/cache engine/输出key-id | 128+541+147 |
| 有界控制 | 384 |
| 小计 | 3911 |

| P3新增容器 | bit |
|---|---:|
| 四侧eligible/SSE/maxres | 360 |
| VC/FINAL游标与提交 | 160 |
| 两READ metadata | 320 |
| coverage/latest/二分 | 256 |
| row latest/pending及两row metadata | 128+128 |
| carry/count/input/消费控制 | 192 |
| 两spool metadata | 320 |
| draw80及shape/font遍历 | 80+320 |
| stop/error/done有界控制 | 128 |
| 小计 | 2392 |

P3复用NUM868统计、1280 derived、392 norm-cache和512组装；norm-cache P3改四(K39/j_base15/span13/visible1)=272bit，旧Q30缓存无同时需求。derived四320bit槽分别侧元数据/point最佳distance/coverage系数/比较诊断；scalar完整385乘积槽不缩窄。READ/spool160 metadata逐一保存state3/offset32/length-cursor/service_seq64/req-terminal-release-pending-borrow事实，完整scope/phase固定ctx提供且保持。

### F2. 工作界与剩余性能问题

DENSE32E组，每组16票；NMS512×277候选、九邻上界，66次快照291word。coarse≤14LE、TLS≤6SE、矩形verify≤VE，合计32E+14LE+6SE+VE，L/S1024/V4096时最多51,027,148,800 POINT访问、408,217,190,400byte（不含padding/控制）。
P1最坏86272E访问、1,431,148,953,600byte；P3默认≤2QE访问、67,947,724,800byte。这些巨大最坏界明确保留给性能优化，不能称实时95%质量已满足。

CELL更新至多3读+3写，EXT4读+4写；SEG20 RE/capture对与20WE+资格沿；coverage205word/侧，clip/floor15/21二分，coverage16搜索；pair523776、三边524288、四边130816。所有循环有界，外部stall无真实服务期限时不能保证固定总延迟。资源利用提高必须以完整预算/瓶颈/真实工具报告和质量比较为依据。

## G. 实施与文字验证计划

获批后的顺序：global binding/表原子性→P1→P2→P3 coverage/VC→FINAL/draw→row/carry/spool→全机联接和真实器件模型→仿真/综合/PNR/STA/bit。拟路径仅为work独立副本中的rc_job_coordinator、rc_native_tables、rc_circle_execution、rc_rectangle_execution、rc_verify_selection、rc_annotation_stream及独立参考/TB，**尚未生成**。

| TEST | 目标 | 场景/期望/观察 |
|---|---|---|
| EX-T01 | REQ01/IF01 | 坏scope/grant/profile receipt拒绝，无MC访问/无伪return；合法同沿cancel仍记accepted。 |
| EX-T02 | REQ02/OP01 | 发RE后cancel+stall仍次沿capture旧key，下一job不能误收；word19前不visible。 |
| EX-T03 | REQ02/OP05 | state跨word18/19，分别停顿/取消；DONE只在完整提交后；lookup不得观察撕裂。 |
| EX-T04 | REQ03/OP02 | 圆五遍n_expected重放、同路近峰/精确ledger；一处计数不符帧失败。 |
| EX-T05 | REQ03/OP05 | TLS2几何变化不改第6遍M2；t翻号同时端点flags交换；μ到run距离16/48分支。 |
| EX-T06 | REQ04/OP04 | t−1/0、同cell多个间隙、重复位置、companion相邻RMW，maxgap精确且zero逻辑不改。 |
| EX-T07 | REQ02/OP03 | θ15/16、511/0、rho边界和equal tie；每θ/r只处理一次，291word snapshot完整。 |
| EX-T08 | REQ04/OP07 | 极远A但图内短可见段，j−base索引；边界半开、同一格首尾部分长度及threshold精确相等。 |
| EX-T09 | REQ04/OP07 | 两不同点数但相同occupied union，coverage相同；Lcov>Lvis内部错不得饱和。 |
| EX-T10 | REQ05/OP07–08 | VC跨512word边界、gid空洞不读、拒绝body零、消费保留fit高bit，FINAL全表才有效。 |
| EX-T11 | REQ05/OP08 | circle内外边界含等号、Ao0/Ai1/负中心、任意旋转有限capsule和标签冲突OR。 |
| EX-T12 | REQ05/OP09 | W6/H5跨row carry、N30末零；1024/4KiB边界、511段主图、FORMAT held与spool复制分离。 |
| EX-T13 | REQ06/OP09 | req/W held时cancel，下游长stall/terminal先到，完整spool供料且旧pending不丢；Q不free。 |
| EX-T14 | REQ06/IF02 | local→fence→grant ACK→role3 return ACK→status；父等status消费不能阻塞前返还。 |
| EX-T15 | REQ07 | 各1025/513/4097/65容量点，整job失败、ANN无prefix、质量统计记失败。 |

全部NOT_RUN。未来逐位参考、RTL同步观察区、随机停顿/复位及真实MC/DDR模型分别验证；已有文档静态字段核算不叫功能测试，不生成可执行场景来绕过批准。

## H. 双向追踪

| REQ | MOD/IF/草图/不变量 | 计划符号 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| 01 | EX0/IF01–02/D1/INV03 | rc_job_coordinator | T01/T14 | 未实现/NOT_RUN |
| 02 | EX1/IF03/OP01、03–05/INV01–02 | rc_native_tables | T02/T03/T07/T10 | 未实现/NOT_RUN |
| 03 | EX2/EX3/OP02、05 | rc_circle_execution、rc_rectangle_execution | T04/T05 | 未实现/NOT_RUN |
| 04 | EX3/EX4/OP04、07/INV04、06–07 | rc_verify_selection | T06/T08/T09 | 未实现/NOT_RUN |
| 05 | EX4/EX5/IF04/OP08–09 | rc_annotation_stream | T10–T12 | 未实现/NOT_RUN |
| 06 | EX0/EX1/EX5/OP01、09/INV03、08 | rc_job_coordinator、rc_annotation_stream | T02/T13/T14 | 未实现/NOT_RUN |
| 07 | 全执行器/F2/B容量政策 | 各有界计数/容量门 | T15 | 未实现/NOT_RUN |

反向：绑定由01，表由02，重复扫描由03，私有mask/coverage由04，FINAL/stream由05，排空/账本由06，有界容器由07承担；没有与要求无关的新核心单元。

## I. 设计门槛与评审

①整体B；②职责C及实际来源A1；③接口/相容D；④局部E/INV；⑤语言F；⑥D4及B正常/失败走查；⑦G/H；⑧**未满足**：AG-B02/03/04及联合版本仍阻塞整机；⑨保存、全文读回和交叉读审实录写K；⑩A1/J范围/版本明确。
本稿不标READY_FOR_REVIEW，不发起实现批准请求。不得因没有尚未批准的代码/测试本身形成循环设计阻塞；当前阻塞来自实际全机预算/依赖/外部合同，不来自“先跑测试才能画草图”。

## J. 相对旧稿、恢复及联合吸收

| 差异 | 旧依据/问题 | 本稿候选与影响 |
|---|---|---|
| job/receipt/status | RC-B04 packed未冻结 | D1 4731/693/965及旧702/708 role3返还；须父控制/DATA联合吸收，不称正式接口已更新。 |
| 物理spare | CELL32/EXT64逻辑padding零，无法恢复真实同cell gap | E4新增私有submask，借NMS+PAIR且互斥，无RAM增加；逻辑zero仍零。 |
| 切向 | NUM只规范n/rho，t/端点符号未明确 | E5 t=(ny,−nx)，μ/区间/censored同时变换。 |
| 旧均值 | “run距μ”可误解成新run均值需额外扫描 | E5明确μ到闭区间距离，测试16/48Q4。 |
| 提交 | COMMIT接受不等20WE完成，state跨word | D2 DONE及E5 whole-record锁，共用541槽。 |
| coverage | 只说1px projection bitmap，裁切/首尾/绝对索引未冻结 | E7像素面积窗、floor/ceil/base及精确根式门，不增加POINT遍。 |
| 输出 | 旧row可被物理W长期借用、copy细节未闭合 | E9独立sealed spool、真实FORMAT接受与carry跨row、物理/语义借用分开。 |
| 预算 | 旧14778并非完整执行holding | F1保守29168已列，225RAM保持，全机FF/DSP仍未证明。 |

全部未实施差异；未来联合版本改变重要接口/结构须一并评审指定版本。恢复核验本稿/父SHA、实际批准、工作副本差异和审计，不凭摘要继续业务写入。

## K. 设计实录

本轮只读原始VF/Demo、既有规则/设计/接口来源和静态字段算术；原始代码/资料、业务副本、正式项目state/ledger/Manifest/DB均未修改。P1/P2/P3代理仅设计/只读，不生成实现或功能脚本。
本稿保存/实际SHA、全文readback、独立交叉核读和字段求和以[本轮审阅](../experiments/track4_full_sw_20261004/05_reviews/recognition-execution-review-v0.1.md)及更新document-checks记录。不存在编译/功能仿真/综合/时序/实机证据。
理解验收待用户实际作答，不以考试阻塞已获批工作。

## L. 阅读、交付与修改入口

阅读顺序：主计划→DATA-JOIN身份/授权→NUMERIC算术→ALGORITHMS目标/字段→本稿B/C/D整体与交接→E1共同事务→E2圆→E3–6矩形→E7–9核验/输出→F预算→G/H验证追踪→J差异。
修改算法门/布局找ALGORITHMS及J；修改数值找NUMERIC/E5/E7；修改point/借用找DATA/D1/D4/E9；修改输出连续性找E8–9并回查TEST T10–14。
本轮交付为内部执行设计；代码/注释/测试一致性核对尚不适用，因为尚无获批实现。整机软件运行、综合/PNR/STA/bit仍未完成，硬件下载以后继续人工闸门。
