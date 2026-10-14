# 三行双时钟缓存、资格与关闭 v1

- Goal：让已实现display_handoff的row0资格和candidate_closed逐步来自实际行数据生命周期，完成生产显示所需三bank缓存叶单元。
- Current state：handoff v1+J1/owner v1+J3已RTL/MAP/网表验证；条件prepared/closed目前由TB提供。没有生产行bank。
- Target state：三固定bank、每行960个RGB/EDGE/ANN双像素记录；真实核心写入、整行资格跨域、视频同步读取及归还；18个原生RAM预算，实际仿真/MAP再核对。
- Gap：尚无三bank内存/资格/读流水/归还代码。DDR读取和scan调度下一层接，不以模拟io_closed证明真实DDR。
- Assumptions：core100MHz/video pair约74.25MHz，共同safe冷复位；父提供有效结果租约及真实io/producer闭合资格，必须保持到对应bank停止写。
- Open questions：匹配DDR动态模型、预取/QoS/TMDS/最终物理CDC仍整机待证，不阻塞行缓存本身。三bank预算不能再偷偷增第四bank。
- Dependencies：冻结的atomic_mailbox、frame_owner_pkg、v0.2、实际native EFX_RAM10模型和已核行缓存原语合同；原样复制。
- Milestones：设计读回→pkg/native RAM/单bank/三bank→独立参考/TB→1080p与异常/借用回归→MAP→登记。
- Detailed steps：B整体→C模块/连线→D相容接口→E中文操作→F语言→G/H验证及追踪。
- State transitions：本稿READY_FOR_REVIEW读回/呈现后依用户“统计完后自行进行，无需我的批准”继续；不伪称逐版人工批准。
- Artifacts and hashes：新work/display_rows；baseline冻结输入SHA；RunId不可覆盖，脚本与实际源绑定，fatal非零探针。
- Validation：完整ticket、所有54bit、数量/坐标/同步RE/气泡/holding/借用关闭/共享safe reset、近max、三bank并发及真实Ti60 MAP。
- Failure handling：未知闭合不publish/不abort；身份写错误Q并保留义务；错误读返回error/零且不发RE；错误release不归还；隔离不能作已关闭。
- Human approval gates：自主软件授权及本地审计例外沿用；没有安装、下载、外网、硬件操作。最终bit后停止。
- Rollback：只新增work/active/track4_algorithms_20261004/display_rows，原HDK/安装/旧staging及已登记源码不动。
- Completion criteria：本缓存叶单元软件/实际MAP交付；真实预取与完整系统仍继续，不缩小五基础六高阶目标。

## A. 范围与文件

TRACK4-DISPLAY-ROWS-001 v1，关联B4/A3/A5/A6及DH02/DH06。计划11份自写：rtl/display_row_pkg.sv、row_ram54.sv、display_row_bank.sv、display_rows3.sv；tb/tb_display_rows.sv、tb/tb_row_scan_join.sv；model/row_reference.py；scripts/run_rows_sim.ps1/run_rows_map.ps1；project/display_rows_component.xml/.sdc。真实mapped后延迟/物理CDC不在本叶单元证明范围。

冻结至少当前已登记mailbox、owner pkg、handoff/pkg、实际timing及native RAM模型、此设计、v0.2。bank映射与所有行为在下文完整规定；初始没有新业务源码/测试，生成前实际读回。原样依赖单列，自写数不含依赖。

## B. 外部行为与样例

DR01：固定3bank，每bank一行W/2个54bit记录；正常W1920/H1080，参数W偶数4..1920/H偶数2..1080。既有三结果预算无第四个行bank。
DR02：core接受完整fill ticket并holding回复；仅合法、递增精确generation且父持有结果租约时进入FILL。成功回复消费后可写。每次写按本行地址0..W/2−1和同generation，全部接纳才整行完整。
DR03：publish还须父真实io_closed/producer_closed，严格同generation；ticket经原子mailbox到视频。源bank在published→return期间不可写，metadata及RAM稳定，完整行资格不能由最后一个请求提出或不足数量推定。
DR04：视频实际接受row ticket取得读借用；RE使用native双时钟同步读取、两holding槽及一个pending，信用防覆盖，稳态每video周期可一record。所有54bit与地址/error一起保持到实际消费；不会反压物理扫描，扫描调度在父模块。
DR05：只有pending/holding均空才接受release。CONSUMED还需本行所有合法顺序record真正消费；DISCARDED可未读或部分读但无在途。返回完整原ticket及kind，core消费return后下一沿才FREE；generation++或max后exhausted，不回绕。
DR06：未发布FILL可在io/producer真正闭合、无当前写后abort；core holding DISCARDED return同完整ticket，不造视频访问。未知闭合不归还。错代写/发布/abort隔离保留当前bank；错读有明确error记录，错release只有error脉冲且保留读借用。
DR07：三个bank互不覆盖、独立ready/return/row/RE；组合用真实row0资格匹配handoff candidate的seq/scan/result/Origin/policy，只有视频已拥有对应完整行才VS apply。候选取消等待它真实停止读并归还，再汇总父DDR关闭；本单元不冒充最后一项。

正常：bank0 fill row0→960条真实write→父io/producer闭合→publish→video接收→row0准备完整→VS换帧→960次读/消费→CONSUMED→core return消费→下一代填另一行。bank1为next，bank2为candidate row0，三者有完整不同ticket。
边界：holding最后一个record时release ready0、core仍不可写；实际消费与pending结清后release。错误旧gen读返回零/error，不发RAM RE且不增加行完成；未知io_closed永不publish/abort。取消在中间行等待排空，DISCARDED说明借用关闭，不能叫完整画面。

## C. 职责与连接

M0 row pkg：完整ticket及返回kind的唯一位序。M1 row_ram54：3条20bit×512 native RAM stripe、2深度bank共6RAM，core写/video同步读；数据高补6bit0、低54bit可精确重建；不负责访问权。M2 display_row_bank：独占一个bank的填充、资格与真实pending/holding/释放；两个既有atomic_mailbox，core→video543、video→core545，拥有代次/计数/隔离。视频owned不再复制543bit ticket：mailbox源holding在core等待return时始终不改变，由资格保护稳定借用。
M3 display_rows3：三M2固定例化，公开三个独立通道/状态；不隐增第四bank，也不做DDR arbiter。父按匹配ticket选择current/next/candidate。

```text
DDR/row assembler(后接) → core fill/顺序write/publish → M2/M1(core写)
M2 543bit原子资格 → video row actual fire → 同ticket读借用 → M1同步RE → M2 pending/2holding → 扫描/renderer(后接)
video真实release → M2 545bit原子return → core实际消费 → FREE next generation
实际row0 ticket资格 → display_handoff prepared；父汇总row return+DDR闭合 → candidate_closed
```

独立return通道不等下一行或下一次VS，没有填充等待return而return又等整个scan fence的环。source数据稳定直到无旧RE/holding，不能将transport ack当实际视频消费。

## D. 接口与组合检查

ticket543高→低：generation64、sequence64、scan64、result64、policy64、Origin195、target_y11、source_y11、mode3、required_mask3。generation为该bank本地非0单调身份，其余来自完整owner/handoff，result全局非0不回绕；Origin完整保留，不缩成slot。三个bank固定实例定位，不在ticket猜bank。return545为ticket543/kind2（0CONSUMED、1DISCARDED；2/3非法）。pair54={ann4,edge2,rgb48}；RGB高lane1低lane0，each24={R,G,B}；edge bit0 lane0，ann[1:0] lane0/[3:2] lane1。

所有输入/输出unsigned；core及video各正沿fire，TB负沿驱动/沿前观察，正沿后值才更新。core接口：fill_valid/ready/ticket543→fill_reply_valid/ready/ticket543/status3（0OK、1FIELD、2IDENTITY、3EXHAUSTED）；wr_valid/ready/gen64/address10/data54；publish_valid/ready/gen64，加独立实时io_closed/producer_closed；abort_valid/ready/gen64，同资格；return_valid/ready/ticket543/kind2；core_busy/exhausted/quarantined/write_error。视频接口：row_valid/ready/ticket543、owned；rd_request_valid/ready/gen64/address10→rd_response_valid/ready/data54/address10/error；release_valid/ready/gen64/kind2→release_error脉冲。

fill ready仅FREE、非exhausted/Q且没有holding回复；接纳后锁全ticket，CHECK形成holding。合法需generation==next_generation，sequence/scan/result/policy非0，Origin.captureSeq/generation非0且相等、slot<6；y都在H内；mode0..5。mode0 required按target_y< H/2选择001否则010，source_y=2×(target_y mod H/2)；mode1/2 required001、mode3 010、mode4 011、mode5 111，其他source_y=target_y。非法回复不授予写权，保持到消费后FREE。

wr ready仅FILL/计数<PAIR_COUNT；真正fire必须generation当前且address==当前计数，否则write_error且Q、不WE/不释放；合法同沿nativeWE且计数+1。publish ready仅FILL/完整计数/io&producer闭合、无当前write；真正fire核gen，错则Q，正确PUBLISH，mailbox actual source fire转WAIT_RETURN。abort ready仅FILL/io&producer闭合/无当前write，不要求完整数量；真正fire核gen后建立本地DISCARDED holding，源没有曝光到video。

video row ready由父提供，还必须无owned且旧release源邮箱已真正ACK；actual dst fire立owned、issued/served0，ticket由稳定mailbox data给出。RE申请ready由owned/两槽信用且无release提出决定；每次fire校验gen/addr==合法issued数/addr<PAIR_COUNT。合法RE、issued++；非法占一个error response但不RE/不issued。served只在真实合法response消费++，所以错读不能伪补整行。

release ready要求owned/pending0/count0/return mailbox source ready。真正fire核gen、kind0/1，CONSUMED再核served==PAIR_COUNT；不合格error脉冲不改owned、不发送return。合格把完整ticket/kind交给return mailbox、owned0，之后不可RE；core收到并实际交给父消费才FREE且nextgen++。current published ticket在source waiting_return期间稳定，因此video没有逐位同步及易撕裂快照。控制面新fill会先锁core ticket但仅到新的publish source fire才改mailbox source holding，旧video借用已关闭。

身份/布局与handoff相容：row.seq/scan/result/Origin/policy须与candidate/nextscan整包逐字段匹配；mask/行数来自实际完整填充。mode0 source_y是视图映射，不修改原算法的1920×1080处理图。父仍验证result完整及RO授予；未有真实IO资格不做fake close。CDC除control双FF，543bit稳定bus仍需最终物理maxdelay/保持报告，MAP SDC不是物理CDC证明。

## E. 局部中文操作草图

core states FREE→CHECK→REPLY→FILL→PUBLISH→WAIT_RETURN→FREE；错误fill回复消费回FREE，abort转RETURN_LOCAL保持到实际消费，写身份错误转Q保留ticket。fill锁包再验证，验证成功也必须等回复被父实际消费才接受write。所有计数基于旧状态；publish与abort互斥（abort优先），write当拍禁止二者ready避免未结最后WE。published core wr_ready0，不清RAM，只用资格隔离未初始化值。

nativeRAM：WADDR/RADDR低9映射512字，地址bit9选择两个depth bank；3 stripe拼成60bit。WCLK实际合法write fire才WE，RCLK实际合法read fire才RE；WRITE_MODE READ_UNKNOWN/OUTPUT_REG0，禁止同bank访问权冲突，不依赖冲突值。视频锁native depth select及request addr/error到pending；下一正沿用旧pending/nativeRDATA入tail，count=oldcount+oldpending−oldpop；新RE信用基于此结果且<2，保证count+pending≤2。两个slots同时存data54/address10/error，head/tail仅实际pop/capture翻转。

owned ticket持续借用mailbox稳定data，没有独立大ticket FF。release只有旧pending/count都0才可能fire；合法return源真正接纳同沿清owned，数据RAM不清。core接纳实际return前还核完整ticket与current精确相等，否则Q、不把他人ticket交成自己的关闭。gen max真正归还后exhausted1，不回绕。共同reset异步assert、两域两沿release；RAM不清，owned/pending/count/valid资格清。安全共同reset前父须实际停止旧DMA/读写，本叶单元不能验证此平台事实。

不变量：published/owned不可WE；未知producer/io没有整行授予；pending加holding≤2；release没有旧RE/holding；整个ticket及545bitreturn在valid停顿保持；没有通过超时/错误码归还。各bank独立，不串行阻塞另一个bank。

## F. 语言与实现合同

SV_09 enum/packed pkg，组合全赋值、always_ff非阻塞、循环仅静态生成RAM/bank。A位宽ticket543/return545/data54、address10/计数11可表示960，gen64饱和；B正沿前采样；C全ready/valid实际fire，release_error/write_error为本域下一周期可观察脉冲；D气泡不计数；E所有valid输出holding；F nativeRE→pending→holding两周期初延迟，稳态每周期；G共同safe冷复位及两沿release、不清RAM；H fill锁整包/publish后不可变；I 3×1024×54、18RAM设计预算、各bank两holding+pending；J全Origin/seq/scan/result/policy/row/gen及lane顺序；K原样atomic mailbox双向，单bit同步、稳定bus资格；L Ti60F225/I3 MAP目标100/74.25MHz、最终总预算及布线STA待证。

无C++，Python是独立数值/事件参考，不照抄next-state。数学record由frame/row/pair/plane生成，读取逐bit相同；日志每fill/publish/读交付/release/return/安全reset，参考维护不可变行内容及借用集合；不从RTL内部state生成期望。RTL流水holding/未初始化隔离另由边界动态验证。

## G/H. 验证、实施与追踪

T1 DR01/02/03→真实native RAM完整960条、W4/H2边界、错误ticket/mask/source_y/gen、少一条写且闭合、io/producer未知不能publish；字段拒绝不授写。
T2 DR04/05→同步RE首延迟、连续每周期、长response stall、release等待pending/holding、全54bit/顺序/数量、误gen/addr返回error且不RE，旧ticket不能进入新代。
T3 DR06→部分FILL闭合abort、未闭合不abort、错误release不放owned、错误write Q、clock stop共同safe reset、gen近max不回绕；不伪造全系统关闭。
T4 DR01/07→3bank交叉填/读/held return，current/next/candidate真实资格与handoff VS匹配、取消候选在最后holding未消费时不closed；无第四bank。
T5 DR01..07→1920×1080整图行循环至少1帧1036800pair/all54bit，实际两时钟，参考图/lane/error/行ticket；scan时序组合单独核同源与行bank关联。
T6→Ti60F225/I3当前源MAP实际RAM/FF/LUT/ADD，错误和native模型依赖公开。此叶不声称已完成QoS/物理CDC/PNR/STA/bit。

实施依序pkg→RAM→单bank→3bank→参考/TB/runner/project→局部/组合/HD→MAP。DR01→M1/M3→T1/4/5；DR02/03→M2 core→T1；DR04/05→M2 video/pending→T2；DR06→core return/Q+video release→T3；DR07→scan_join TB及父planned线→T4/5。核心反向联系文件/符号与本草图，run/登记初始未执行。

## I/J/K/L. 门槛与交付

B样例/C职责/D相容/E详细步骤/F A–L/G验证/H追踪及A范围/原样输入冻结提供十项实质内容；保存、全文读回和聊天入口后自主软件授权实施。没有当前叶单元阻塞；未实现DDR/QoS/renderer/TMDS及总顶层待后续，不将这些TBD藏成已完成。变化先短卡并读回，不覆盖旧RunId。

阅读顺序整体→交接→局部语句→参考/测试→实际runs；交付按实际接口、数量、RAM、关闭证据核对，再填写K，不填假通过。理解验收未有实际回答，待检验，不阻塞授权工程；原DB/H0及硬件状态保持。初始11份业务文件未生成。
