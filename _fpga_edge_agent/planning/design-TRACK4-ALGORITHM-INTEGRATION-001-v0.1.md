# TRACK4-ALGORITHM-INTEGRATION-001：五类剩余工作的整包组合设计 v0.1

2026-10-04；GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本稿统筹最新五类工作，引用现行局部合同；没有用新增目录或文档数量表示任务已经完成。

## 通用计划字段

- Goal：完整推进实际非DDR存储/通信、性能资源、生产输入输出、整包统一，以及获批后的实现/软件验证至bit。
- Current state：R1至R4、CONTROL/REPLAY/VIEW和RAW候选已存在；RAW协议、性能和生产IO正在独立复审/设计；没有本次业务代码或完整构建产物。
- Target state：明确实际可实现结构、完整接口和局部草图、共同文件/质量/验证基线后统一提交指定版本批准；随后在work连续实现和真实运行。
- Gap：目前生产存储尚无已绑定容量、物理连接及带宽保证；旧单slot无法自然接受连续相机新帧；原数值与对象/控制合同存在待合并扩展。
- Assumptions：生产1920×1080，完整八邻域Canny，圆/任意旋转矩形及原质量评价保持；Ti60F225/I3、SC431HAI彩色为软件目标；实体未到货。
- Open questions：用户已回答“必须只用板卡现有资源”；生产算法工作存储限定现板、DDR排除、无新增模块，PC仅仿真/参考/观察。实际低工作集结构、生产服务和完整局部合同仍待证明。
- Dependencies：唯一根v0.2、PLAN_TEMPLATE、A节局部候选及原控制面审批；没有数据库/Manifest例外。
- Milestones / Detailed steps：实际资源差距→存储结构→全机同时寿命/时限→生产IO/CDC→本稿接口/文件/参考/场景统一→完整复审→READY→指定批准→work实现→仿真→综合/PT/PNR/STA→bit/登记停止。
- State transitions：只记录本稿设计状态，不改原PROJECT_STATE/TASK_LEDGER/数据库状态。
- Artifacts and hashes：当前候选来源见A；未来实际共同manifest须包含所有源/设计/工具/IP/pin/输入/schema版本和摘要。
- Validation：文档、数值/协议、功能仿真、综合网表/时序、bit、实机分别计；当前全部功能/构建NOT_RUN。
- Failure handling：真实硬件/带宽缺口保留；wrong echo、未完成原子组、未退休引用或部分帧不伪成功；软件失败不通过缩图、限制场景或裁剪功能隐藏。
- Human approval gates：满足规范10.3后才提交成熟版本集合；本轮五类工作请求支持设计推进，尚未构成对未完成版本的批准；point5仍明确是获批后的实现。
- Rollback：仅新增本稿及本轮记录，原HDK只读、旧局部保留；降标稿仍WITHDRAWN_BY_USER。
- Completion criteria：本五类完成须有真实完整范围的代码、功能和工具证据；bit后停止。DDR A3仍暂缓，不从原任务表抹去或判通过。

## A. 最新范围与候选版本

用户本轮明确要求完成剩下五类，并继续排除DDR。此前160×120、单目标、1处理帧/s提案已明确撤回：[历史降标稿](design-TRACK4-BRAM-FEASIBILITY-001.md)，不纳入任何当前指标、接口或实施基线。随后在本轮设计边界询问中，用户明确回答“必须只用板卡现有资源”；因此外接非DDR存储模块不在允许路线，PC64MiB arena也不能作为板上生产工作存储，仅保留为逻辑仿真/低速观察接口。

原[整包v0.3](design-TRACK4-ALGORITHM-BATCH-001.md)仍统筹原十一项及批准边界；本稿是新组合附件，尚未回写其关闭状态。原A3 DEFERRED_BY_USER。显示60Hz、采集fps、算法处理fps、外部通信耗时分别报告，不重新设1fps验收。

本轮实际核对的候选来源（均未获整包实施批准）：

| 来源 | 实际SHA256 | 本稿采用范围 |
|---|---|---|
| [R1 v1](design-TRACK4-ALGORITHM-R1-001.md) | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 | 固定点灰度/中值/Sobel与原FE计划；局部READY不等整包READY |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | C0唯一FE owner、Gaussian/梯度/NMS/class/GRAD、CS592 |
| [R2 FILES v0.1](design-TRACK4-ALGORITHM-R2-FILES-001.md) | E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842 | 21计划文件/10TB与独立数值/向量职责；不是全包清单 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D | NUM_ID176、REQ622/RESP585、全部typed数值/ROM |
| [闭包 v0.2](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 | 完整BFS、LOAD/CLOSURE角色化身份及全N EDGE |
| [识别 v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 全POINT/LS/TLS/核验/去重/ANN/RECORD和真close |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | CFG/P/C/J/V/手势/RESET唯一owner；新桥扩展尚未合并 |
| [REPLAY v0.2](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | PLAN/三provider/真实JOIN/OUT/RT/CLOSE/RELEASE |
| [VIEW桥 v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | CERT schema2、prejob revoke/return、PLAN_EXIT/QUIET/epoch授权 |
| [RAW v0.2](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 3EC3C2A9005241708AAD2CF75A3DDB6B2630F08BA6D2390DADF933FFE7CFF56C | 原v0.1根实际1–363全文读取并按同hash保存快照；v0.2修订两处reset/journal反例，待独立复核；仅参考/观察候选，不是生产存储 |
| [R5结构选项](../experiments/track4_algorithms_20261004/03_review/r5-implementation-architecture-options-v0.1.md) | 22B7BEBAAB6B8DC2661F74DB95B3054BF72069B4A72F826949369D08A70FD7D9 | 根本轮实际1–257全文读取；C仅core候选、D生产硬件未知，不把外部数组当片上RAM |

共享schema和计划文件不能只按以上摘要自动生成；各body字段仍以对应局部D/F为依据，增加桥扩展必须形成具体联合版本，不把旧主稿当已接受新端口。

## B. 整体外部行为和五类关闭标准

| REQ | 可观察行为 | 完成所需直接证据 |
|---|---|---|
| INT-01 实际存储 | FPGA产生全部算法/原子组/目录/commit，外部仅保存原始bytes；容量、权限、初始化、读写完成及关闭明确 | 实际可用接口/pin/资源/带宽合同、完整有限控制器设计、真实byte读回/故障/close验证 |
| INT-02 性能资源 | 全机同时存活的RAM10/FF/DSP/PLL、缓存和后端容量逐项计；每阶段真实等待和处理周期分开 | 闭合分配与最坏服务预算，获批后实际资源与STA/处理报告；不以资源填满当优化成功 |
| INT-03 生产IO | 实际SC431HAI配置/RAW/CSI→缓存→core→同帧完整RGB/EDGE/ANN→HDMI1920×1080@60Hz | 正确模式/LUT、pin电气/相关clock、CDC/reset、不可暂停到达与固定扫描容量/服务证明、完整软件工程 |
| INT-04 整包 | 明确各身份/数值族/owner与文件职责；独立oracle、文字场景、中文草图和双向关联统一 | 每个必需连接字段和生命周期相容，无重复writer/暗藏数组/未审lookup，具体基线及复审 |
| INT-05 实施 | 获完整设计批准后，在work生成真实代码/模型/TB/runner/工程/约束，运行至bit | 实际源码hash、命令/日志、功能/网表/PT/PNR/STA/bit；bit后不下载 |

正常路径：SOURCE完整封存→注册源→原JOB锁完整CFG→R2/LOAD先准备→全CLASS/GRAD真实commit→CLOSURE精确集合/全EDGE→RC全候选核验/ANN/RECORD→私有refs实际退休→CERT2完整bundle→VIEW联合父引用→REPLAY借用/像素→固定视频采用→各层真实退休→下一帧或epoch。

失败路径：例如DENSE logical_commit后第二raw写失败，真实已提交事实和副作用保存，后续不发布成功图；独立raw关闭证明未知效果、typed局部close及目录退还，错误终态不等同取消收条。未知不回收引用，不靠reset消债。

## C. 唯一职责与完整数据/控制连接

| 组合组 | owner和保证 | 当前限制 |
|---|---|---|
| SOURCE/BOOTSTRAP | 新源接纳、原RGB/profile bytes初始化覆盖和源登记；不代算class/GT | 原族端口与生产capture尚需INT-B02/03 |
| CFG/JOB | KEY/CFG/RESET和JOB各唯一writer，J锁旧C，FE只由选定stream owner驱动 | 新桥prejob撤offer和QUIET汇合须联合吸收 |
| R2/LOAD/GRAD | C0计算，LOAD只收CLASS，GRAD collector独立收完整typed梯度；计数/终态不混用 | FK两支独立stall，提前错误状态必须有容量 |
| S/O/RAW | S执行claim、DENSE/RMW、journal/latest；O独占descriptor/pin/ref/版本/权限/退休；raw只读写bytes | PC64MiB只为仿真/低速观察候选，按用户最新边界不能作为生产后端 |
| R3/R4 | NUM单caller0保持精确ID；闭包、识别及ANN全在FPGA，typed组效果真实结束才成功 | 不能把RAW seq当NUM或同宽H跨角色cast |
| VIEW/REPLAY | O/V联合grant，P OPEN获plane借用，M产生OUT；各层真close/return，PLAN_EXIT后才父RETURN | V_LATCHED、VIEW_TERM、OUT EOF都不是生产APPLIED或显示退休 |
| CAMERA/VIDEO | 连续source到达、域缓冲与固定扫描；生产采用和退休自己产生证据 | 实际后端、连续新BUILD/旧VIEW并存与带宽未闭合 |
| 参考/检查 | 黄金从原image/profile生成；协议检查按真实events；host byte service不执行数学 | 从DUT候选日志构造GT或回填结果均不允许 |

数据路径和控制路径分别前进；CLOSE/RESET/错误通知独立容量，不因满数据队列无法收尾。子quiet不等待父term已经消费，父term的形成也不反向阻止source效果关闭。

## D. 共同接口目录与必须吸收的差异

| IF / 消息族 | 位宽、来源和转换 | 合并规则 |
|---|---|---|
| INT-IF01 控制源 | CFG212/P539/C539/J657/V788；CONTROL D1/D2 | P/C同宽不同意义；JID96=epoch/job_frame/config，逐命名字段转子核 |
| IF02 流段 | CJ142、原FP、CS592/CLASS/GRAD；R2 D/C0/FK | 先准备LOAD/GRAD才启动；真实CS不等全EDGE或几何成功 |
| IF03 LOAD/CLOSURE | LC270/PREPARED277/LC_TERM776，CLJ438/BIND511/CL_TERM1013，RQ324/RSP449/CLOSE294/ACK502 | H160按role包含不同load/closure id；两role独立台账，真实LOAD关闭后才移交CLASS |
| IF04 RC | RJ2257/RB184，KEY287/RQ799/RSP872，CLOSE295/ACK504，TERM2606 | reason6族与闭包reason5不同；RC成功ACK/TERM规则采用v0.2，不拿错echo结债 |
| IF05 NUM | ID176/REQ622/RESP585与R3 cancel/quiet | NUM call_seq独立；owner0单caller，应用/丢弃旧held响应分开，不凭OBJclose清NUM |
| IF06 byte授权/RAW | AR348/AP466、KEY195/RQ707/RSP725、C231/ACK442/T469 | 高到低消息fields与低地址byte packing分开；raw关闭只证明raw债，不代typed close或O退休 |
| IF07 bundle | CERT352 schema2，COMMIT1201/REPLY232，VIEW父RETURN352/ACK360 | COMPLETE_CERT含private_refs_retired1，旧schema1拒绝；仅实际私有目录退休后成功COMMIT |
| IF08 prejob源 | REVOKE160/ACK168、SOURCE_RETURN160/ACK172 | 各独立namespace；同沿旧offer真fire优先，撤offer须正确ACK与真实revoke_idle；不造job0 |
| IF09 图像重放 | PLAN616、OPEN619/REPLY888、RQ360/RR421、JOIN413/OUT404、原CLOSE/RELEASE/RT1171 | SOURCE/EDGE/ANN各独立provider/credit；OUT404真正输入生产适配，不只LED摘要 |
| IF10 plan/view关闭 | PLAN_EXIT267、VIEW_TERM497、VIEW_CANCEL128/RECEIPT135 | RT消费→后续GAP/全部旧债空→EXIT→父RETURN→对象退休→VIEW_TERM；published EXIT/TERM按原保持规则 |
| IF11 reset授权 | QUIESCE96/QUIET111、START128/七ACK140，再原RESET receipt/done | 本reset事务不计入旧业务allheldempty；P不得从首PLAN自行授权新epoch |
| IF12 生产IO | 新camera/capture、存储仲裁、video采用/退休、CDC消息 | 完整字段/clock/服务期限须生产稿固定；暂不编造宽度、pin或已有通过证据 |

本整合稿要求CONTROL/REPLAY吸收VIEW D6 Δ01…08，形成联合版本后才称接口统一。具体必改：SOURCE登记/撤销/返还、J_CTX pin到全部term消费、O父引用、VIEW取消入口、P退出、七owner授权ACK、真实raw/O quiet及私有work退休。旧manual CANCEL128仍对已经移交的J返回TOO_LATE；新增VIEW_CANCEL不改变其含义。

旧R5选项中的16B raw提议不优先于RAW实际8client/64B候选：新整合采用RAW D2/D6字段；若生产backend增并发、改block或clock，必须重审journal、台账、缓冲和CLOSE语义，不能称内部小优化。

组合反例走查：CLASS成对提交与cancel同沿保留已提交事实；两个ANN像素在同byte RMW不得覆盖邻位；RC_CLOSE_ACK合法failedclose可结债但阻COMPLETE；PLAN_EXIT前父不得返图；prejob revoke接受沿已真转移不能再S_ONLY返源；epoch授权不能通过先清held或O.valid凑QUIET。

## E. 整包中文操作草图与资源生命周期

INT-OP01 看完整范围。先读B五类行为，再C owner与D消息族，确认A3暂缓、低指标撤回和高指标保持。

INT-OP02 选真实后端。核容量/地址/端口/电气/有效带宽与最坏等待。当前41,113,469B保守对象总量远超Ti60片上327680B；PC服务可验证逻辑，生产路径另须实际可实现结构。只按内存数组能分配不准入生产。

INT-OP03 建源。SOURCE取得独占writer、初始化实际RGB/profile全覆盖、核全图canonical后commit并注册S；此后fixture或PC不能私自改原图。准备LOAD和GRAD全角色资格，之后才能CJ启动；不可暂停相机要求缓冲和后端服务保证。

INT-OP04 全算法。R2计算CLASS/GRAD，FK每支真消费；LOAD/GRAD末写和pending关闭才commit。闭包种子/八邻域/claim+queue真正结束后完整EDGE。RC按POINT/候选/拟合/冻结核验/精确去重/ANN与RECORD执行；NUM和raw独立台账。

INT-OP05 减空间但不改结果。闭包结束后CLASS/QUEUE须真实typed close、pin和private引用退休才可复用；GRAD/POINT只有最后核验/ANN读取及NUM义务结束才能退休。ANN程序生成、POINT改重算或BFS改扫描都是重要结构变更，需独立证明等值与周期，不在此擅自生效。

INT-OP06 发布与显示。建立完整CERT2、先实际退还private refs，再O/V唯一联合采用；P借用后按同源坐标读三plane，OUT交生产视频适配。视频仅在真实帧边界有完整预取资格时采用，旧像素流水/行缓存/serializer退休后归还旧引用；单slot旧VIEW不允许新BUILD覆盖。

INT-OP07 停止与失败。旧fire、logical_commit与物理effects先真实结账，再停止新业务。未知raw债允许独立raw CLOSE先推进；只有正确完整证明才结效果债并关闭typed服务，私有对象仍需O逐份退还。没有Q证据闭合就不开放下一epoch。

INT-OP08 统一实施。成熟版本及全部源/输入/工具/schema清单保存读回并独立复审后统一申请指定批准；获批后只在work创建真实文件，按G执行，成功到bit登记即停止。

## F. 语言、独立参考与数值/时间对应

SV2009候选。RTL保持沿前真实fire、旧状态计算/沿后提交，时序非阻塞、组合完整阻塞、明确signed/扩位/RNE/floor/饱和；每局部F仍是具体数值权威，不以本总述代替。

独立数学参考职责：直接整图RGB灰度、普通九值排序、每级各自复制边界的卷积、明确方向/NMS/双阈值；独立集合BFS从强种子得到全N边缘。几何参考从原image/profile和独立GT测量候选/支撑/量化误差，不能把DUT日志当真实目标。

协议参考独立记录req、rsp、read capture、logical_commit、raw effects、phase、close、typed terminal和pin return，按完整身份匹配；最终数值相同不能代时序正确。PC bytes服务只storage，不计算candidate、CLASS、DENSE、TLS、ANN或token。

质量评价按每类P/R≥95%、同类IoU≥0.5的最大基数一对一匹配，失败或容量图保留在分母/失败统计；数据开发与独立验收划分、种子/原图/GT摘要先冻结，旋转、重叠、缺边、噪声、负样本均为测量轴，不能重置已撤回的场景硬界限。完整fixtures/GT算法/样本数仍INT-B05。

时钟暂不混用25MHz局部观察、RAW27MHz候选与100MHz预算；共同core及生产多个相关clock由真实资源/IO设计确定。同步器窄例外、真实generated clock和CDC保持按具体层级约束，不把全端口/全clock组false_path当通过。

## G. 文件职责、实施顺序及验证矩阵（未生成/未运行）

工作根仍为 _fpga_edge_agent/work/active/track4_algorithms_20261004/，当前不存在。以下为整包候选文件组，不是假称已经完成的源码/精确冻结清单；现R1/FE/R2 FILES的逐文件合同原样引用，其余具体模块内部由对应新局部冻结。

| 文件组/候选核心路径 | 责任及阅读次序 | 要求/接口和测试 |
|---|---|---|
| rtl/common/track4_types_pkg.sv、ram10_bank.sv、reset_sync.sv | 共同schema、真native端口、复位；先读每个type命名字段，再读owner | 全D/F，T01/T02/T08 |
| rtl/frontend/原六文件；rtl/r1/现五文件 | 单FE、中值/灰度/原Sobel及局部观察；原R1/FRONTEND清单展开后不新增第二核 | INT-04，IF02，T01/T02 |
| rtl/r2/现13文件 | C0/Gaussian/gradient/fork/NMS/class、R2局部观察；R2 FILES准确路径为来源 | IF02，T01/T02/T03 |
| rtl/r3/numeric_core.sv、numeric_rom.sv | typed算术/乘除根/LS/TLS/ROM、cancel/quiet；内部职责须进一步映射 | IF05，T04 |
| rtl/storage/object_directory.sv、byte_authorizer.sv、atomic_journal.sv、typed_store.sv、raw_adapter.sv | descriptor/pin/权限、bytes/RMW/latest、所有原子组/phase/close | IF03/04/06/07，T05/T06 |
| rtl/storage/source_bootstrap.sv、grad_collector.sv、plane_provider.sv | 实际SRC/GRAD全覆盖、immutable读回和真实return | IF02/08/09，T02/T05/T07 |
| rtl/closure/class_loader.sv、hysteresis_controller.sv | LC→精确BFS→全EDGE→真实close | IF03，T03/T05/T06 |
| rtl/recognition/recognition_controller.sv、point_builder.sv、circle_engine.sv、rectangle_engine.sv、verify_dedup.sv、annotation_engine.sv | 全RC阶段/核验/排序/去重/光栅/records；不是PC计算 | IF04/05，T04/T07/T09 |
| rtl/control/config_owner.sv、key_events.sv、job_dispatcher.sv、epoch_reset.sv | D/P/C、手势、单J、QUIET与授权，增量桥端口需联合版本 | IF01/08/11，T02/T06 |
| rtl/replay/view_bridge.sv、plane_replay.sv、pixel_renderer.sv | O/V父引用、P borrow/EXIT、同源像素与叠加 | IF07/09/10，T07 |
| rtl/io/通信组、camera组、video组、production_top.sv | 真实后端/pin、CSI、固定视频和完整防裁剪；未选定结构不填假文件/IP | IF12，T08/T10 |
| model/frontend_reference.py、canny_stream_reference.py、numeric_reference.py、closure_reference.py、recognition_reference.py、render_reference.py | 独立数值模型按阶段分开，不共用RTL FSM/journal实现 | T01/T03/T04/T07/T09 |
| model/protocol_scoreboard.py、byte_service.py、quality_evaluator.py、fixture_manifest | 事件检查、raw-only后端、独立GT匹配及来源身份 | T02/T05/T06/T09 |
| sim/frontend、sim/r2现10TB及sim/r3/storage/closure/recognition/control/replay/io/integration | 单元/组合/full1080p、错误/时序与容量；具体TB列表须逐接口补齐 | T01…T10 |
| scripts/run_package_sim.ps1、run_package_build.ps1、project/full_package.xml/.peri.xml/.sdc | 真实已安装工具、日志/期限/失败、PT/PNR/STA/bit；不生成stub工程 | T08/T10 |
| reports/design-source-test-trace、中文操作说明、实际产物manifest | 从行为到接口、局部步骤、符号与真实报告双向索引 | T11 |

| TEST | 输入/事件 | 期望来源与通过标准 | 当前 |
|---|---|---|---|
| INT-T01 数值阶段 | 黑/白/极值、全部边界、方向平局、阈值相等、median重复 | 独立整数参考逐像素/逐typed结果；全1080p，数值规范先冻结 | NOT_RUN |
| T02 时间配置 | valid0、气泡、每口stall、末像素/状态同沿、变更CFG | 真实数量/身份/历史快照，无穿透/撤held/错frame | NOT_RUN |
| T03 全闭包 | 逆序长蛇链、斜连、环、孤立弱边、无强/无弱、全N队列 | 等独立可达集合，完整N含0，真实最后写闭合 | NOT_RUN |
| T04 NUM与geometry | 所有NUM合法/拒绝/溢出/RNE；圆/任意旋转矩形拟合与冻结诊断 | NUM_ID/定点与geometry稳定，局部误差契约与独立GT | NOT_RUN |
| T05 原子目录 | samebyte/RMW、claim与queue尾N、DENSE16、第17journal槽、padding/权限/版本错 | 成对可见/latest、未授权无效果、正确REF/pin返还，不变成主机算法 | NOT_RUN |
| T06 失败关闭 | known/partial/full/unknown、wrong echo、postcommit reset、迟到ACK/term | 保存真前缀/commit、独立close无环、未知不解Q、所有控制回执实际消费 | NOT_RUN |
| T07 VIEW/render | mode0重复偶行、全部6mode/颜色/开关、prejob撤offer、EXIT/RETURN | 同RGB/EDGE/ANN/JID，O/V唯一grant、真实退休后复用；非RC缺ANN合法/RC零目标全0ANN | NOT_RUN |
| T08 物理core | 动态输入/profile、全core实例、实际native RAM/速度级/pin/clock/PT/PNR/STA | 完整有效扇出、资源符合预算、目标时序/约束覆盖，无黑盒/虚拟宽IO/小top替全包 | NOT_RUN |
| T09 质量 | 独立开发/验收GT，negative/overlap/noise/遮挡/rotation完整图 | 每类P/R95%+IoU0.5最大基数一对一；所有错误计入，不改期望掩失败 | NOT_RUN |
| T10 生产连续IO | 实际模式到达、最坏backend等待、不同clock相位/复位、HDMI帧边界 | 缓冲/QoS/CDC/采用/退休成立，采集/算法fps/显示Hz分别实测 | NOT_RUN |
| T11 交付一致性 | 指定设计/source/input/schema/tool/project/log/bit/trace | 读回真实文件和稳定符号，正反可定位；bit后停止 | NOT_RUN |

实施按依赖连续进行，不因每个局部文件再申请一次批准；成熟同范围批准持续有效。当前局部FSM、全部文件/确切端口和运行期限未闭合，不能把这张职责表标为已完整冻结。

## H. 双向追踪

| 用户五类 / 原要求 | MOD/IF/OP | 计划文件组 | TEST | 当前直接证据 |
|---|---|---|---|---|
| 1 / A4/A6 | S/O/RAW/provider，IF03…08，OP02/03/04/07 | storage/closure/recognition | T03/05/06/08 | 实际文档/容量/协议审阅；无硬件backend |
| 2 / 所有算法 | 全core，OP05/F | 完整performance/resource、cache/clock/NUM | T01/04/08/10 | 候选预算，完整预算仍OPEN |
| 3 / B1/B4/A5 | SOURCE/CAMERA/VIDEO，IF12，OP03/06 | io/production_top | T07/10 | 参考来源事实；非DDR生产结构仍OPEN |
| 4 / B5/规范 | 全D/G/F，OP01/08 | schemas/models/sim/trace/中文说明 | T01…11 | 本整合候选和原局部；未冻结/未实现 |
| 5 / 软件至bit | 全组，OP08/G | work、实际工程/runner/产物日志 | T08/11 | NOT_RUN；无指定整包实施批准 |

反向每个文件必须承担上表的算法、实际协议/IO、独立验证或可复现证据责任。PC只储存bytes的服务与黄金模型物理隔离；不把黄金结果送入DUT。原A3及实机下载/观察不作为本软件阶段的已完成项。

## I. 门槛与真实阻塞

| ID | 当前缺口 | 允许继续的工作与证据 |
|---|---|---|
| INT-B01 | 用户已限定仅现板、无DDR/新增模块；当前fullframe方案不fit，实际低工作集/后端服务仍未证明 | 只核现板BRAM/Flash/连接、重算/流式/生命周期与信息/带宽差距；不能再选择外接存储或PC arena闭合生产项 |
| B02 | RAW两处reset/postcommit journal局部反例及typed原子/目录/SOURCE/GRAD完整内部未闭合 | 独立RAW复审→修订新版本/保持旧快照→原子与目录FSM/OP冻结 |
| B03 | CAMERA/VIDEO多域、最坏服务/双bundle、真实pin/完整约束尚缺 | 新生产IO稿、真实模式/GE/管脚核对；不恢复DDR |
| B04 | 共享/复用真实生命周期、全部native RAM10/FF/DSP/PLL与后端周期未冻结 | 新性能稿、地址/packing/RMW/仲裁/时间表，不用旧局部225RAM/100MHz数字当实测 |
| B05 | 所有接口完整字段、Δ01…08联合版本、profile/fixture/GT/确切文件与期限未冻结 | 本稿D/G作为组合入口，完成共享registry与独立复审；不以标题齐全关闭 |
| B06 | 指定版本整包实施批准、work/构建审批、正式DB前置仍未满足 | 设计成熟后一次提交具体范围/基线和必要治理条件；不预写代码或更改权限 |

规范10.3整体范围/职责/候选接口、操作/验证/追踪已有内容；真实依赖/完整局部/资源/文件基线仍未闭合，⑧无阻塞不满足。保持NOT_READY，不申请批准未成熟整包。

## J. 变更与恢复

本稿纳入用户最新五类，保持DDR排除、高指标和低指标撤回。旧VIEW扩展首次集中映射到CONTROL/REPLAY，未默改其旧接口。实际新增存储、clock、并发、双bundle、程序ANN或GRAD重算均影响设计边界，先修订相应REQ/IF/OP/TEST并复审，批准后的变化按规范处理。

## K. 本轮实录

只读现文档、源摘要和纯设计。根实际全文读回RAW1–363、R5结构选项1–257及整包/范围表，其他局部采用前序同hash读取及本轮必要字段核查；不把本轮rg片段称为新全文独立复审。无业务源码、功能脚本/模型/TB/工程/SDC，未运行仿真/综合/PNR/STA/bit或设备/网络/安装。原资料、正式状态/Manifest/DB未改。

## L. 中文阅读与交付边界

先看B五类关闭条件→C谁拥有何数据→D接口目录与差异→E正常/失败及生命周期→F参考角色→G文件/验证→H追踪→I具体缺口。文档完成度、业务实现度、软件验证和实机验证分别陈述。当前交付为整合候选；不足之处已定位，不声称五类全部完成或已证明整机可实现。
