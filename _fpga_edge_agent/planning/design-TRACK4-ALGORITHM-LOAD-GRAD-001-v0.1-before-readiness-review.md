# TRACK4-ALGORITHM-LOAD-GRAD-001 — 真实 SRC / CLASS / GRAD 三支交接

- Goal：补足生产单 J 的阶段 0：真实来源锁定、CLASS/GRAD build 分配、完整阶段注册、三个访问 pin、准备、RGB 输入、CLASS/GRAD 收集、真实关闭和 GRAD 不可变提交。
- Current state：纯设计候选 v0.1；`NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN`。原 R2、CONTROL、R4C、SLOT、PROFILE-SOURCE、production-directory 仍各自保持现有版本；本卡不改这些来源，也不改已验收 R1 文件。
- Target state：三支分别有真实准备和关闭证据；完整父历史贯穿所有事务；父只在实际 CLASS 初始 token、实际 GRAD immutable token（需要时）和所需子终态成立后推进闭包/识别。
- Gap：旧 LC270 只绑定 CLASS；旧 BUILD_BIND 的回复只给 EDGE/ANN/RECORD，未提供本阶段 CLASS/GRAD build；生产 SRC reader、完整 GRAD collector、访问 holder/快照、对应 provider 及全机资源/服务未冻结。
- Assumptions：生产仍 W=1920、H=1080、单 J/单 scratch；静态验证实例沿 R2 的偶 W=6…1920、H=5…1080；使用现有生产目录候选的六不可变 SRC、单 CLASS/GRAD 固定槽。上述目录/后端只是候选依赖，不能冒称已经实现。
- Open questions：见 A3 的 LG-B01…B08。不存在以降分辨率、少写 GRAD、把永久等待当完成或用主机文件代生产存储的豁免。
- Dependencies：唯一根 v0.2；R2/C0；CONTROL 历史 J；PROFILE-SOURCE 生产 SOURCE311/BIND1012；R4C 的真实 L；production-directory；并行 STAGE-CAPABILITY 纯设计；真实 provider/physical adapter 与全机验证。
- Milestones：M1 本卡保存读回；M2 与能力卡/目录/后端联合闭合；M3 资源、服务和组合审核；M4 才可 READY_FOR_REVIEW；M5 指定版本/范围/基线批准后才实施。
- Detailed steps：整体 B→职责 C→逐接口 D→局部中文操作 E→语言 F→验证 G→双向追踪 H→门槛 I；顺序不能倒置为先生成源码再补设计。
- State transitions：局部候选见 E；项目数据库/PROJECT_STATE 的硬件状态不由本卡修改。
- Artifacts and hashes：A2 列实际只读来源；本卡的最终 SHA256 在保存读回报告中记录，不在文件内自包含其自身 hash。
- Validation：本次只有资料实读、组合推演和静态字段/区间算术。没有业务实现、可执行测试、仿真、综合、布局布线或硬件运行。
- Failure handling：分别保留实际来源/事务/写入/关闭事实；已提出的 typed 请求继续兑现，未知义务进入 Q，不伪造 absence、settled、token 或 FREE。
- Human approval gates：本卡未达到 READY_FOR_REVIEW，没有本卡业务实现批准；R1 的既有批准不扩展到本卡。后续仍遵守原工作副本、构建、数据库及人工硬件闸门。
- Rollback：本阶段只增加独立设计卡；原资料、原计划、R1 及工程源码均只读。候选改变以新设计版本记录，不回写历史证据。
- Completion criteria：完成本次设计保存不等于生产实现完成；LG-B01…B08 全闭合、规范十项具备实际证据、用户批准指定版本后才能进入实现。

## A. 状态、来源和阅读入口

### A1. 范围与批准边界

任务 ID `TRACK4-ALGORITHM-LOAD-GRAD-001`，关联 A4 Canny / A6 Recognition 的阶段 0，以及 A3 的真实同源帧持有；版本 v0.1，日期 2026-10-05。当前允许行动为只读调查和本设计卡保存，不生成未来业务 RTL、C++、功能脚本、TB 或原型。

根代理本轮委托原意为：“读取 R2/CJ/GRAD185、CONTROL 历史 J、SLOT、production-directory 与 stage-holder 审阅，补足三 pin 真实注册、PREPARE、采集、COMMIT、关闭/归还；全局依赖保持 OPEN/NOT_READY。”这是一项纯设计委托，不是指定实现版本批准。本卡未登记新的 Approval Manifest/数据库批准，也不新增运行时权限。

阅读顺序：B 的整体行为→C 的三支连接→D1 的完整历史与分配/注册→D2/D3 的数据及封存/关闭→E 的逐模块中文草图→F 的语言契约→G/H 的测试与追踪→I 的未闭合门槛。先看整体，再看共同接口，再看每支内部。

### A2. 本轮实际来源绑定

下表的 hash 为保存前实际 SHA256；范围表示本轮实际有限阅读，不宣称有限阅读等于全文。入口规则依控制 AGENTS 顺序实际读过；唯一根 v0.2 已在先前阶段全文读取，本轮核 hash 未变。行号只辅助定位，节名和完整 hash 为主要定位依据。

| 来源 | SHA256 / 字节 | 本轮实读范围与使用事实 |
|---|---|---|
| [唯一根 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2` / 61102 | 原全文阅读；本轮重新核 hash，设计前置/十项门槛/RTL及追踪约束 |
| [PLAN_TEMPLATE](PLAN_TEMPLATE.md) | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` / 10341 | 全文，A…L 与通用计划字段 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | `416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2` / 29268 | L1–145，CJ142、FP74、CLASS125、GRAD185、C0 终态/输入停止及数值边界 |
| [C0 附件 v0.1](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md) | `5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844` / 32502 | L25–66、L116–155，另定向读 L67–112 生命周期；原 FP 保持/明确作废例外、CS592、retain0、flush 和失败不等 P/EOF |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | `2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107` / 51859 | L107–146；定向 L173–181；完整 J657、formal retain、PREPARE/CJ/子终态顺序 |
| [SLOT-JOIN](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | `6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA` / 29682 | 定向 L94–104、L134；旧 offer182/BIND883 的关系，单 J/信用/scratch |
| [PROFILE-SOURCE](design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | `6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103` / 30415 | L75–96；SOURCE311/BIND1012、admission 原 lease 转移、不重建/加第二 ref |
| [production-directory](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA` / 34598 | L69–94、L118–158，另已读 D2/D3 字段 L94–128；真实 source origin/lease、pin、固定几何/初始化/无 writer commit/退休 |
| [R4-CLOSURE](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | `5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11` / 63263 | L100–184，另 L78–99；原 LC270/CLASS_SEAL863/PREPARED277/RQ324/RSP449/CLOSE294/ACK502/LC_TERM776 |
| [R4-RECOGNITION](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | `AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257` / 83901 | 已有限读 L102–119、L157–170；本轮定向 L117–136；同 J 的完整 immutable GRAD、canonical 与 RJ2257 |
| [PERFORMANCE](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | `A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469` / 58487 | L195–219；P CLASS+1 commit、SRC bootstrap/GRAD collector 原缺口、13N+4 的口径 |
| [stage-holder 审阅 v0.1](../experiments/track4_algorithms_20261004/03_review/production-stage-holder-review-v0.1.md) | `D8967256E44D1C2AD4190F9E217E56C3FB371BBA92E020ED25D5ADB2F4AF28B7` / 14398 | 原全文阅读及本轮核 hash；旧149词只保存 LC/CLO/RC，LC 不含 SRC/GRAD 完整来源 |
| [STAGE-CAPABILITY v0.1](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7` / 43441 | 新纯设计卡实际有限读L90–151；BEGIN218/WORD28、REGISTER291、五child独立revision、原typedBIND真实ACQUIRE、普通LOOKUP616/740、retained admin/分scopeRETURN；尚未批准/未实现 |

资料原文事实：旧 `LC270=CJ142/load_id64/class_build_ref64`；`H160=JID96/operation_id64`，LOAD 的 operation_id 为 load_id；首个 load_id/recognition_id 为 0 可以合法。目录内部 holder generation 是独立 nonzero64 身份，不能直接 cast/truncate 业务 ID，也不能用业务 ID+1（最大值会溢出）。

候选事实分开：本卡的 LG1119、ALLOC、SOURCE reader、GRAD collector、CLOSE 后 O-COMMIT 及子 scope 都是新设计候选。旧来源没有这些新端口，不能从本卡反推旧源码已具备。

### A3. 当前阻塞项

| BLOCKING | 影响 | 尚缺真实合同/方法 |
|---|---|---|
| LG-B01 holder/register/cache | IF02/03/所有 provider | 与A2绑定的STAGE-CAPABILITY v0.1共同冻结namespace、REGISTER传输/回复码适配、LOOKUP、generation、BINDING INIT/ACTIVE、五child独立revision、子scope quiet、snapshot失效和metadata RETIRE；实际有限阅读/消息对齐不等正式批准 |
| LG-B02 真实 build 分配 | IF01/02/10 | O 的 CLASS/GRAD 私有 ALLOC、预 REGISTER 部分分配/回复保存、固定 scratch 排他、失败退休和原 BUILD_ABORT456/ACK466 相容映射；BIND1212 不提供这些 refs |
| LG-B03 provider/packing | IF04/05/08/09 | 两新 typed provider 与旧 S 的独立绑定/仲裁、物理128bit burst/收料预算、RGB跨span、GRAD64/CLASS4bit 的真实 packing、RMW 与初始化；PC/UART debug/file 不作为生产后端 |
| LG-B04 immutable GRAD 提交 | IF09/10/11 | O 在已真实关闭 writer 后的 publication 接口、full provider 封存记录、descriptor/version/token 更新、初始化/全覆盖、旧 callback metadata 保存和合法查询；不能用 CS 代 token |
| LG-B05 资源/服务 | 全部 | 新 SOURCE/GC、ALLOC/注册/快照/控制/关闭/transport 的真实冷/热/FF/RAM/端口合账；每 serial logical 请求的 service cycles 与全机服务、5-ring no-loss 的联合证明 |
| LG-B06 全 J 终态组合 | IF07/11/12 | CONTROL 旧历史、PCTX、全三支/CLASS+CLO/RC、O 私有退休和最终 JOB_TERM734 的字段/保存/状态变更共同冻结；不得回写旧 CONTROL |
| LG-B07 reset/epoch | IF02–12 | 实际各 owner、physical journal、迟到 reply、generation 耗尽和恢复 fence；局部 rst 不虚构 DDR 已关闭/旧身份可重用 |
| LG-B08 独立证据 | G/H | 正式审批后的 independent vectors、typed 注入、numeric/protocol/组合仿真和资源/STA；本卡没有实现/运行证据 |

可独立继续：逐字段审阅、三支逐连接推演、候选资源下界、文字验证计划及双向追踪。以上任一未闭合，整卡不能 READY_FOR_REVIEW。

## B. 整体外部行为

### B1. 稳定要求

| REQ | 外部规则 |
|---|---|
| LG-REQ01 真来源 | 锁旧 SOURCE311 的 source_id/handle/admission/PCTX 与完整旧 J657；对 SOURCE_ORIGIN512、SRC_LEASE522、descriptor ref/version/immutable/完整RGB建立真实核验；不把 later J、COPYseq 或固定地址当输入身份 |
| LG-REQ02 真注册 | 原 BUILD_BIND1012 成功转移同 admission 后，真实分配 CLASS/需要的GRAD build；全文 LG1119 保存完成后先BINDING和预算reservation，真实pin只由对应typed BIND/PREPARE建立一次；所有 prepare/初始化成为旧已消费事实后才 ACTIVE/CJ |
| LG-REQ03 三支分属 | SRC read、CLASS write、GRAD write 是同一阶段 holder 的三份不同访问资格；旧 L 的 close/pins_released 只覆盖 CLASS，三支各自 quiet/RETURN/ACK；holder 最终退休汇合三个 scope 与旧 metadata |
| LG-REQ04 每 pair 真处理 | SOURCE 精确 P 个RGB48→FP74；C0 形成 P CLASS125 和 retain1 时 P GRAD185；每合法 GRADpair 两个32bit全写，不仅写边缘点或非零点 |
| LG-REQ05 真封存 | C0 的实际 CS592 independently 接收再分发；CLASS 初始 token 由旧 L/S 的 P+1 STORE；GRAD 先真写/close/RETURN，再 O immutable/version/token；同 J 的 full GRAD 给 RC |
| LG-REQ06 正常关闭 | 停止新提议、兑现旧 held、独立收实际reply、确切截止、settled/实际pinreturn与metadata；不等待父 JOB_TERM 或 bundle 先 FREE，不把其它 source lease 存在当本 pin 不能返回 |
| LG-REQ07 失败诚实 | 非法/取消/部分写/未知分别保 raw 前缀和真实义务；C0早失败不等 P/EOF；不生成假图、假token、假absence或假关闭 |
| LG-REQ08 有限状态 | depth1 容量与旧状态流控，无无限 FIFO；generation 非零独立扩65耗尽；完整帧/事务身份不靠坐标或阈值猜测；rst/epoch 有真实 fence |
| LG-REQ09 可核资源与时间 | 追加 SOURCE/GRAD 逻辑操作、控制/元数据、packing/初始化和serial service成本；不把字节、typed请求、DDR beat、周期互相代替 |

formal 模式沿 CONTROL：algorithm1 CANNY 的 retain=0；algorithm2 CANNY_RC 的 retain=1。显示 RGB/gray 不关闭原 J 的已选算法。独立 R2 OBS 的 retain0/1 诊断不等生产算法选择，也不由本卡修改。

### B2. 正常和边界路径

正常 CANNY_RC：旧 source311 真 fire→父锁 J/PCTX/admission→原 BUILD_BIND 真成功→ALLOC 真实 C/G refs→REGISTER LG全文/BINDING预算→三 scope各自typed BIND/PREPARE真实grant/init→父消费三个准备和 ACTIVE 回执→CJ142 真 fire→C0 自己 FJ 真 fire→SOURCE逐pair FP→CLASS到 L/GRAD到 GC→真实 CS 到父独立槽，再分发三份 seal→SOURCE真实read close；L CLASS真实初始commit与自己的close；GC fullwrite真实close/pinreturn→O immutable GRAD commit→三个终态汇合→CLO/后续RC按真实token启动。未找到目标仍须 full GRAD，不能把 recognition F0 当无输入图。

CANNY retain0：Gref/版本/grant 元组全0有“本 J 从未分配/授予”的实际 absence；不发GC PREPARE、不等GRADready/EOF/term/close。仍必须完整 RGB/CLASS、实际CS、CLASScommit/close和全CLO导出。

启动前取消：已 held ALLOC/BIND/PREPARED/CJ 不随取消撤销。已经提出但未接受 CJ 必须兑现后收到实际 CS；只有真实未提出/无 held CJ 的路径才能给 seal.cj_started=0/CS全0。这个0不是 FE OK。已经实际取得的三 scope 必须分别收尾，没取得的 scope 不等待不存在终态。

处理中错误/取消：记本沿旧真实fire→注册停止新提议→C0取消并继续收真实CS；原 private flush 只撤 C0 尚未交付数据，GC已经接受的GRAD、来源已经发出的typed读/写及reply仍真实收尾。正常终态、FAILED_DRAINED、CANCELLED_DRAINED、Q分开；没有自动 timeout。

## C. 职责和整体连接

```text
原 SOURCE311 + CREDIT162 -> 原 J/BUILD_BIND1012 -> IF01 ALLOC -> IF02 LG_REGISTER
                                         完整 J/LC/SRC/admission/GRAD -> O holder
                                    IF03 三scope PREPARE/ACTIVE
                         +------------------+-------------------+
                         |                  |                   |
                    SRC readpin       CLASS writepin       GRAD writepin(可无)
                    IF04 reader        原 L/原 S             IF05 GC/provider
                         | FP74             ^ CLASS125          ^ GRAD185
                         +-------> C0（原FE唯一owner） ----------+
                                      | CS592
                                      v
                           父独立缓存 + IF07 seal fork
                            /          |            \
                    SRC seal        原CLASS_SEAL863   GC seal
                     IF08 close       原CLASScommit   IF09 close/RETURN
                         \              close          IF10 O immutable commit
                          +----------- IF11 三term -------+
                                              |
                                    IF12 后续CLO/RC/私有退休
```

| MOD | 职责/状态拥有者 | 划界与复用 |
|---|---|---|
| LG-J stage preparer/seal fork | 父历史 J、KEY/PCTX、load_id、ALLOC/REGISTER/各prepare/CJ真实facts、三个seal pending、真实子term | CONTROL J 的候选适配；不拥有FE FS、不自封存GRAD，不把L ACK当整holder关闭 |
| LG-O allocation/holder adapter | 真build/descriptor、完整LG冷体、generation、三pin/snapshot与各scope关闭/metadata、GRAD publication | 新目录/能力适配；base/lifetime和accesspin分层，不能凭caller非零ref授权 |
| LG-SRC reader | 单读请求/expected/RSP、RGB→FP候选、pair游标、seal、关闭和SRCterm | 新生产输入源，不能拿“只读完整bundle”的显示REPLAY直接绑定未完成J；不申请第二admission lease |
| 原C0 | CJ、FE唯一所有权、CLASS/GRAD fork、CS592、private flush | R2/C0原数值和协议不改；依真ready可暂停，无无条件跟随摄像每帧处理假设 |
| 原L/原S CLASS scope | 原LC270/PREPARED277/CLASS125/初态token/CLASSclose/LC_TERM776 | 原公共body不改。S此typed绑定只授CLASS，不能从LC得到SRC/GRAD授权 |
| LG-GC collector | GRAD185单槽、canonical/坐标计数、独立写请求/expected/RSP、CSseal、close、commit、GRADterm | 新全frame collector，不做NMS/识别，不用任意Gready影响retain0 |
| LG-provider/physical adapter | 每typedscope真绑定/台账/回复/关闭；共享物理burst与journal仲裁 | 新实体，原L/C的单S业务RQ/credit不改；两新provider各有限depth1，物理并发/收料按PB真实预算 |

整体检查点：三支先分别就绪才启动唯一C0；CS父槽/seal槽独立于数据/RSP/close；SRC RSP接收不得依赖FPready，GC RSP不得依赖GRADready，L RSP保持原独立槽。各scope先返自身pin，再自身close回执；最后holder退休。不存在“返pin等wholeholder退休、wholeholder又等close”的环。

## D. 接口与组合检查

### D1. 原历史、分配与注册

保留原 body：J657=`C539/job_frame32/source_handle64/W11/H11`，JID96由旧J的epoch32/job_frame32/config_id32按原合同明确构造，不能把J657某个低96bit切片当三ID；LC270/CJ142/H160 都不改。实际源采用 PS 生产 SOURCE311=`旧182/admission_ref64/PCTX65`、BUILD_BIND1012=`KEY162/source_id64/J657/admission_ref64/PCTX65` 和 ACK1212。SLOT 的旧182/883/1083仅为历史来源，不能相同线路静默混宽度。

本卡新增 `LG1119 = J657 / LC270 / source_id64 / admission_ref64 / grad_build_ref64`，斜线为高到低全文串接。LC.CJ三ID/尺寸/median/TL/TH必须逐字段由旧J产生并一致；retain由J.algorithm导出。LC.load_id是业务操作身份，LC.class_build_ref是实际ALLOC结果。SOURCE ref为J.source_handle，经原SOURCE311/lease/创建origin完整核验；JID不得替代SRC创建身份（SRC descriptor alloc_job_valid=0/JID=0）。PCTX/KEY来自原受保护BIND历史，不从最新policy取；LG引用该历史必须有真实存活关联，不能只靠同位宽指针。

| IF | 候选 body/提供→使用 | 前置、保证、容量/相容 |
|---|---|---|
| LG-IF01 ALLOC | J→O `LOAD_ALLOC1076=完整原BUILD_BIND1012/load_id64`；ACK1213=`echo1076/class_build_ref64/grad_build_ref64/status2/reason6/allocated1` | 已真实BIND、同原J/KEY/PCTX/source/admission、algorithm1/2、单scratch排他；只建立真实BUILD descriptor与私有owner，尚无ordinary权限。成功Cref非零、Gref仅retain1非零；失败absence须真实没建对象；部分分配保ledger/Q。held request/reply各1，重放原key不再分配。预REGISTER保存/失败O退休为B02 |
| LG-IF02 REGISTER | J→O LG1119；ACK1195=`echo1119/stage_generation64/status2/reason6/registered1/reservation_mask3` | 源、build、全LG、historical link逐项核；cold全文写完/末padding零后才BINDING，只有三scope预算预留，没有live accesspin/ordinary资格。reservation位SRC/CLASS/GRAD，retain1=111、retain0=011；generation独立非零。规范拒绝须真实没有该新holder/reservation，途中部分登记保真实metadata/Q；reserved不是pin已授予 |
| LG-IF03 provider PREPARE/ACTIVE | 新SRC/GC PREPARE224=`H160/stage_gen64`，READY233=`echo224/status2/reason6/prepared1`；原L仍LC270→S BIND277→L PREPARED277。O ACTIVE224→ACK812=`echo224/三组(ref64/version64/grant64)/status2/reason6/active1/pin_mask3`，独立typed namespace | 每provider在BINDING按fullLG/来源/几何实际建立本scope pin一次并准备；CLASS只由原S BIND建立，原合法refusal仍无该S会话pin。L旧LC经内部holder adapter显式查CLASS/gen，不改公共H。原PREPARED只按原S BIND成功；CLASS完整初始化由O额外ACTIVE gate核，不凭277猜测。父消费各READY后发ACTIVE；O核三真实pin/INIT完成才ACK，三元组顺序SRC/CLASS/GRAD，G关闭时全0、mask011，否则111；ACK成旧事实后才CJ |

generation分配/回收：目录O独立预检扩65加法，只发非零64，最大可用值至多一次，exhausted后拒新REGISTER；预留即消耗，失败不能重用。epoch不靠input新值自行更新。`(namespace LOAD, fullH160, stage_gen64, registeredepoch)`匹配真实冷体与旧metadata；business operation_id0合法，generation0不合法。global ref/version/grant与stagegen分别属于不同身份namespace，禁止互相cast。

REGISTER的BINDING只允许内部目录/原BIND与prepare；对应typedbind真实grant后才能用INIT权限初始化，尚不允许普通SRC读/CLASS写/GRAD写。不能先在REGISTER里授CLASS pin再让原S BIND再次授pin，否则原BIND277失败“未建立pin”的语义或全机pin数量被破坏。ACTIVE逐scope核旧ready和真实初始化，不在本沿刚收到READY时透传CJ/数据。服务lookup/cache采用并行能力卡新候选，旧D3全文核每操作仍为原事实；不得静默宣称旧卡已许可快缓存。

ALLOC/REGISTER规范控制回复status0/reason0且success位1，status1/合法非0/success位0仅能表达上述真实拒绝；status3/合法非0/success位0保未知或部分登记，不能由零字段推absence，status2保留非法。PREPARE/ACTIVE status0/reason0/相应ready位1；status1/合法非0/位0表示未就绪但不证明原已取得pin消失，status3保Q、2非法。它们不是data status2定义的REJECTED。未开始的provider若未建立会话，只有O真实无provider/held/effect证据才能自己返该scope已取得的pin/预算而不等不存在term；仅一份失败READY不能证明无义务。

ALLOC不要求尚未存在的stagegrant/GCterm来建立build；REGISTER不要求先普通读/写才保存全body。这消除初始化循环。新build grant也不能反向伪造ALLOC完成。预REGISTER的held ALLOC/部分ref/销毁回执必须有真实有限保存，191词cold下界不涵盖这全部状态。

与SC的传输边界：本卡REGISTER1119/ACK1195是LG parent逻辑接口候选，**不是**SC BEGIN218/WORD28/ACK291直接wire同宽接口。新可信控制adapter锁fullLG，构造stage0/namespaceLOAD/fullH/epoch/schema1/body_bits1119的BEGIN，再按低20bit词索引0…55依序WORD（末高1bit0），保持原LG/expected直到真实SC终态和对应source/budget核验；不能把末词写沿当registered。SC ACK0只在真实完整BEGINecho/gen/registered和本卡资格齐备后映射LG success；SC REFUSED不自动证明本卡此前ALLOC/ref/reservation为空，LG status1还须真实本次未注册证明；SC BLOCKED2不可盲cast为本卡非法2，保原expected/真实旧义务等待或显式Q，不能重复分配；SC UNKNOWN/Q同样保真实事实。准确transport状态、replay/消息槽和complete echo桥仍B01。

SOURCE/GC typed key309不携SC cap_revision/实际pin字段；它们只能由受保护provider绑定快照补入SC LOOKUP616，不能从当前caller猜ref/grant/phase。publication时需把该child旧revision与完整原typed expected/permission保为真实promise，FENCE保持其履约直到closed；5child revision独立，CLASS/GRAD变更不废SRC旧promise。内部LOOKUP740许可/范围/动态STORE证明不能代原RSP366/382完整echo。新增revision快照/permit/桥台账须实际计资源，尚未实现。

### D2. 数据、数值与有限容量

设N=W×H，P=N/2，D=W/2，pair i=0…P−1，x_even=2(i mod D)，y=floor(i/D)。RGB lane0先低x，byte RGB格式沿原FP48实际layout；本卡不改变颜色位序。源logical byte offset=6i，GRAD offset=8i；先扩33核base/length/capacity/slot，不能先窄化、裸用外部地址。

| IF | body、位宽与事件 | 前提与交接检查 |
|---|---|---|
| LG-IF04 SOURCE read/FP | key309=`H160/stage_gen64/tx_seq64/pair_index21`；READ309→provider，RSP366=`echo309/RGB48/status2/reason6/effect_settled1`；reader→C0原FP74 | 只读实际registered SRCr grant；完整RGB descriptor/sourceversion/lease仍真有效。每请求一pair，不用currentJ重认reply；合法settled success形成FP，坐标/markers由旧i，in_bad=0。RSP槽独立收料，与FPready无关；每口request/expected/RSP/FP各depth1，request+expected可同一不可变body但不能在credit1时覆盖 |
| LG-IF05 GRAD185 | C0→GC 原grad64+sideband121；sideband=三ID96/x_even11/y11/SOF/EOL/EOF3；lane0低32 | retain1且prepared/ACTIVE、已真实CJ、本GC旧槽空、无旧stop/rst才ready；先记真实raw fire，再校验ID/预期i/markers及两lane。禁止用当前payload合法性组合撤ready；不得跳过全0/非边缘pair |
| LG-IF06 GRAD write | RQ373=`key309/grad_pair64`；RSP382=`echo373/status2/reason6/effect_settled1` | 已校验pair；每lane Gx低11 signed11、Gy接11 signed11、dir2、high8=0；G范围±1020，abs和≤1530，dir保留R2语义。row-major完整两记录；对应WRITE pin、初始化span及version合法后才真实效果/回复；并非裸地址DDR接口 |

FP markers：SOF仅i0，EOL仅i mod D=D−1，EOF仅i=P−1，最后组同时EOL/EOF；每组同两pixel。GC的同规则检查sideband，原CS.grad计数单位pair；descriptor GRAD valid_count单位pixel N，不能用P填N。两高8均必须0；坏lane定位先lane0。abs先signed12 sign-extend，不能用signed11对最负值直接取abs后误认为合法。

new seq64从0开始，最大值真实至多一次后exhausted，扩65检查；请求提议后held至真fire，不能因取消撤回。每provider只有一份业务信用，正确RSP的echo/旧seq/状态/unused/settled全部规范才结清此credit。错echo、非法reserved或Q只计raw并保真实debt，不能误清陌生操作。普通数据槽按旧空接纳，旧full本沿释放不自动接新数据；输入槽转入RQ在后续独立沿，无新数据同沿透传。

新family data status2：0SUCCESS/reason0/settled1；1FAILED/合法非0reason/settled1只表示此操作已知关闭但本job失败；2REJECTED/合法非0reason/settled1须真实没有该操作效果；3UNKNOWN/合法非0reason/settled0保Q义务。SRC失败RGB48为0且不交FP；Gwrite不返回图样。status1/2不得替代本会话过去义务的close证书。此族与旧R4 RSP449/CS/FE status不同，不能blindcast。

reason6候选：0NONE、1FIELD、2STALE、3BIND、4CAPACITY、5SOURCE、6GRAD_LAYOUT、7COORD、8MARKER、9COUNT、10STORE、11CANCEL、12PROTOCOL、13CLOSE、14EXHAUSTED、15UNKNOWN、16RESET、17NOT_STARTED、18PERMISSION、19VERSION、20COMMIT、21INIT、22SEQUENCE、23BACKEND、24REVOKE；25…63保留非法。终态mask32只bit1…24，bit0/25…31零；旧R4/C0/FS原因保全文，显式映射新first_reason而不改旧字段。

### D3. seal、close、GRAD immutable commit 与终态

| IF | body/方向 | 前置与结果 |
|---|---|---|
| LG-IF07 STREAM_SEAL | 父→SRC/GC，各独立typed `SEAL817=H160/stage_gen64/cj_started1/CS592`；CLASS仍原CLASS_SEAL863 | 父独立CS槽先真接，再注册三pending分发，不在CSfire本沿直透；每接收方独立seal槽1不等data/EOF/term。cj_started=真实CJfire；0只有真正无CJ/无heldCJ，CS全0为未启动证明；CJ已fire即1，哪怕CS内部stream_started0 |
| LG-IF08/09 SOURCE/GRAD CLOSE | 新scope CLOSE359=`H160/stage_gen64/request_cutoff64/last_seq_valid1/last_seq64/first_reason6`；ACK568=`echo359/actual_request64/actual_raw_response64/settled_request64/overflow3/六closed位/status2/reason6` | 六位依request/read/write/response/pin_returned/closed；与data信用独立。己held请求全已fire且不再提议后锁cutoff；允许旧expected仍有效。provider先真实兑现heldreply/关闭effects，scope quiet并RETURN本pin，旧RETURN ACK成为事实再closeACK；不等wholeholder RETIRE/父term/其它lease |
| LG-IF10 O GRAD COMMIT | GC→O `COMMIT245=H160/stage_gen64/full_pairs21`；ACK319=`echo245/commit_token64/status2/reason6/immutable1/effect_settled1` | 仅正常retain1/fullP/fullcanonical/真CS成功、所有GRAD写settled、正确GRADcloseACK已消费、实际writer pin返回和descriptor无writer、init/fullN/version/历史相同才成功。O读取真实provider封存记录和冷LG，不把caller full_pairs当证据。作为O parent publication，非返pin后重新普通写；metadata/context保持至回复/term全部关闭。完整future接口仍B04 |
| LG-IF11 新SRC/GC term | SRC_TERM626；GRAD_TERM691，布局见下段；旧L仍LC_TERM776 | 各独立depth1 held至真fire，消费沿不接新stage；complete须本scope实际证书/本地空及真实C0成功。parent合并真实facts，不从单term推出wholeholder retired |
| LG-IF12 handoff/retire | 父→后续CLO/RC仍原CLJ438/RJ2257；O按三scope闭合/term/COMMIT等metadata真实RETIRE | CLASS初态token闭包使用；GC完整immutable GRAD token由同J保存供RC，不借CS计数代token。SRC/CLASS/G访问pin返还不销相应O-owned对象/admission。原BUILD_ABORT需真实包含新allocated私有objects退休，不能早ACK |

关闭的status/reason及证书：仅status0/reason0、原CLOSE echo正确、actual_request=cutoff且last匹配、actual_raw_response等两端实际RSP fire、settled=actual_request、overflow0、六位全1才证明本scope关闭。first_reason可非0，合法失败/取消仍可有真实成功关闭证书。status1/2/3或不完整证书不能释放未知pin；计数饱和+overflow保Q，不wrap。raw错reply仍计真实fire，不能拿good_response数代raw。最后held RSP的fire只能在后续旧闭合事实形成ACK，不同沿伪造closed。

关闭分属（必须显式改新adapter的内部资格，旧body不改）：原L/S ACK502.pins_released只认证原LC绑定的CLASS scope；不等SRC/GRAD。而新SOURCE ACK只返SRCr，GC ACK只返GRADw。三scope的返回metadata/旧reply/terminal分别闭合后，O才整体RETIRE LG holder。pin真实返还和pin槽metadata复用是不同事件；ACK本身及其旧运输仍held时槽不可再授新人。

**GRAD顺序选择**：GC不先发immutable COMMIT再等未来CLOSE。先写P→真CS→关闭GRAD写provider/返pin→消费CLOSEACK→另发O COMMIT→真实immutable token→GRADterm。CLOSE cutoff只含P个WRITE，不含后续O publication request；工作量统计仍P写+1commit。O COMMIT不能等待holder已RETIRE，否则holder又等该COMMIT/term而互等。CLASS保持原P个LOAD_PAIR+CLASS_COMMIT= P+1 STORE和原close顺序，CLASS初态token不表示不可变GRAD。

SRC_TERM626高到低=`H160/gen64/status2/first_reason6/mask32/loc28/flags8/三pair计数63/四backend计数256/overflow7`。loc28=valid1/stage4/lane1/rawx11/rawy11，无位置全0；stage0prepare/1read/2FP/3seal/4close，其余保留。flags依prepared/cj_started/CS_seen/legal_FP_EOF/backend_closed/pin_returned/local_empty/drained；三pair计数是good_read_pairs/delivered_FP_pairs/discarded_unaccepted_pairs，各21；四64backend计数request/raw_response/success_response/settled_request。正常flags全1、三计数P/P/0、backend各P、首因/mask/loc/overflow0。discard只统计已经由成功读形成、尚未FPfire且明确job作废/终结的候选，不把未发读当discard。

GRAD_TERM691高到低=`H160/gen64/status2/first_reason6/mask32/loc28/flags9/三pair计数63/四backend计数256/commit_token64/overflow7`。stage0prepare/1input/2write/3seal/4close/5commit，其余保留；flags依grad_granted/prepared/cj_started/observed_EOF/legal_EOF/immutable/backend_closed/local_empty/drained；pair计数raw/good/stored；正常全部P、backend各P（只write provider）、token非0、flags全1、无原因/overflow。O commit fire/ack另有实际seen和完整held证据，不挤进P写台账。没有GRAD的formal retain0不生成一份假成功GRADterm。

两个新term status2=0COMPLETE/1FAILED_DRAINED/2CANCELLED_DRAINED/3QUARANTINED；COMPLETE要求真实正常CS及全部本scope条件；2仅first_reason11且无更早错误并drained1；Q优先drained0，保真实partial/token但不得授权正常RC输入。未绑定的规范拒绝可零台账+真实absence drained1，非zero待close义务不能套此特例。termvalid之后全文冻结，迟到cancel仅ALREADY不改诊断。

新SRC/GC CANCEL224=H160/gen64，ACK232=echo224/status2/reason6；0APPLIED/1ALREADY且reason0、2NO_MATCH/reason2、3非法。只匹配旧已注册活动H/gen；旧IDLE同沿新PREPARE不被旧cancel套用；ACK独立held1，ALREADY只表示阻新业务，不证明已drained。原L/CANCEL167及C0cancel沿原合同。末段父仍可取消，COMPLETE形成沿若有新有效cancel按实际优先级判失败；已冻结term不被改写。

### D4. 组合走查与最小反例

1. **LC270直接当三pin授权**：LC只含CJ/loadid/Cref。两个不同SOURCE/admission对应相同CJ，裸LC无法分辨SRC；Gref也不存在。LG1119完整保存、原BIND历史link/sourceorigin/lease核验和明确三元组修补；新lookup尚B01。
2. **CS互等**：GC已经收P且在WAIT_SEAL，父等GCterm才给CS，双方永久等待。父独立CS槽/seal fork与GC独立seal槽解决；CLASS原seal同理。
3. **共holder close误串**：L等CLASS ACK，S把pins_released解释为三pin全空；GC等父看到Lterm才close，于是循环。原ACK只CLASS、新GC不等Lterm、RETURN不等wholeRETIRE；整体退休另汇合。
4. **GRAD COMMIT互等/提前immutable**：COMMIT等writer close，而GC等COMMIT才close；或有writer时先置COMMITTED违反DIR。IF09→IF10固定顺序，Opublication并非新的ordinary write，context保持不先RETIRE。
5. **SRCreply被FP反压阻住**：SRC RSP只在FPready时接，FE窗口填满等CLASS/G效果，shared service又被未接SRCreply占住。独立RSP槽真实预留/接受、physical不得在等上游数据ready时长锁目录/其它scope服务。
6. **早失败held FP**：C0取消后FPready0，来源仍等一个不可能的FPfire，父等sourceclose。原FP合同允许明确job作废/终结；SRC在匹配cancel被注册或旧C0CSvalid明示终结后撤尚未接纳FP，记discard；已typed读仍真实close，不能靠私有flush抹掉。
7. **no-CJ错误证明**：CJ已held未fire就向收集器给cj_started0/CSzero，随后旧CJ仍被C0接纳。父必须保存heldCJ义务，兑现+cancel+真CS，不可发no-start证明。
8. **旧ID合法0与generation非法0混用**：load_id0强行castgen0导致全pin无效；加1到max又wrap0。独立generation allocator在REGISTER前预留，LOAD0照旧合法，耗尽保真实旧scope不冒新grant。
9. **GRAD零值跳写**：EDGE0像素不写，RC全N读GRAD落洞。IF05/06无条件覆盖每合法pair两32bit记录，descriptorvalid_count=N与provider覆盖独立核。
10. **返回accesspin顺便删共享源**：SRC termclose时直接退admission/sourcebase，但另bundle/F/OBS仍读。只返本reader pin，源lease当前owner O和其它真实leases按PS原规则各自退休。

## E. 局部数据、不变量及中文操作草图

### E1. LG-J 父准备和seal分发

保存完整旧J/PCTX/credit/bind历史link，load_id，C/Grefs，REGISTERgen/预算reservation、ACTIVE后实际三元组，source/class/grad准备是否真成功/被消费，ACTIVE/CJ held/started，CS592原子缓存、三pending、各term及cancelACK真实事实。状态候选：IDLE→ALLOC_WAIT→REGISTER_WAIT→PREPARE→ACTIVE_WAIT→CJ_HELD→RUN→WAIT_CHILD→HANDOFF→RETIRE_WAIT→STATUS→GAP；任一错误转STOP/DRAIN/Q，不能从错误直接清旧grant。

操作 LG-J01：旧IDLE且原source/credit/scratch/终态容量齐备时只按原sourcefire锁J；次沿核真实BIND成功，独立发ALLOC1076并保持；回复真接后逐字段验证，在后续沿构造LC/LG；拒绝或部分分配保真实owner/返回路径，不重试成另refs掩盖原失败。

LG-J02：REGISTER全文一次锁住；正确ACK后保存gen/预算reservation，向三provider发准备（retain0完全不发G）。原PREPARED277、各READY及cancelACK独立接收；旧facts全部成功后发ACTIVE，消费O对真实INIT/pin的回执并保存actual pinmap，下一沿才发CJ。heldCJ不能撤；不在CJfire沿首FP。

LG-J03：C0 CSready由预留CS槽容量决定，不等三term/CLASS/G/CRC。真实CSfire沿只原子保存全文；后续形成原CLASSseal和新S/Gseal，各pending独立真fire清位；持有body不跟最新C更新。失败CS仍分发；无C0任务只在真实no-held-CJ证明下发no-start，不能猜测。

LG-J04：独立收三term及close/cancel反馈。formalretain1必须真实GRADtoken完整；CLASStoken闭包启动至少原L完全真close+term且其typedS可重绑。可否CLO与SRC/G后段重叠必须全机S/journal/holder合同另证，默认不以该重叠保证性能；保单J。O私有对象退休、wholeholder退休和最终JOBTERM各有独立facts，不拿JOBTERM消费作为子close前提。

### E2. LG-O allocation/holder/publication

O唯一完整cold LG1119；已有RESULT_ASSOC1879继续保存原J/PCTX/KEY历史。SRC原SOURCE_ORIGIN512/SRC_LEASE522/descriptor真实且不同创建namespace；CLASS/GRAD是原J的JOB_PRIVATE对象。pinmap只存真实ref/version/grant，不把角色名当地址。三个provider的绑定、quiet、returned、returnmetadata、close、term/finalize运输各独立；holder LIVE与资格关闭不同。

LG-O01：核真实BIND记录和scratch空/旧返回metadata容量→接ALLOC只锁请求→后续预检refs及descriptor/回执/失败退休容量→建立C/G真实BUILD，写原JID及完整几何、init状态→冻结ALLOC结果。任何一半已分配后失败保部分登记，不发allocated0/refs0当假absence；与原BUILD_ABORT按真私有清单接口待B02。

LG-O02：REGISTER收LG后完整比对原J、sourceorigin、lease当前BUNDLE、admission、ALLOC结果、CJ和formalretain→cold56词写完及末高padding0→内部BINDING注册与gen/三scope预算→先REGISTER ACK→随后各typedprovider真实BIND/PREPARE时才分别创建一次scope pin/INIT→READY→ACTIVE真实pinmap。原S CLASS BIND成功才有本scope pin，拒绝前不预授一个CLASS livepin。INIT是在实际pin之后的独立已授权内部工作；若在grant后故障不能假造原BIND无pin拒绝或仅从failedREADY清pin，按真实会话/故障和close/Q收尾。REGISTER/prepare任何未知部分登记都保metadata，不借success0抹掉partialgrant。

LG-O03：SOURCE/CLASS/G分别处置quiet/RETURN。返回核自己的oldfullH/gen/ref/version/grant和全部child/effects，不等另一scope/base/wholeholder；真实减计数/回执后仍保metadata。权限变更/cache撤销必须使相应ordinary访问失效并完成既有child；涉及全snapshot重建的屏障/是否允许scope局部失效待能力卡，不能默许旧cache继续用。

LG-O04：GRAD CLOSE证书与pin真返回为旧事实；provider封存记录仍可按oldfullcontext查，immutable COMMIT请求到来→全文核真实fullN/padding/初始化/actualeffects/CS/CJ/原source→真实descriptor无writer/no dirty/版本一致→独立预检非零token/version身份与回执容量→串行提交完整descriptor/immutable/token→后续才ACK319。途中失败保原build/ref/effects，不让caller自填token；COMMIT回执不等GCterm或holder退完。

LG-O05：三scope全部真实close、所有旧RETURN/reply/commit/cancel/term运输/借用真空才退休cold holder/复用index。业务对象仍由O父生命周期决定；GRAD提交给RC后对象不因LOADholder退休删除。SRCbase另待PS所有leases/COPY/旧通知归零。

### E3. LG-SRC reader

重要状态：fullH/gen及已验证SRC pin/context快照，i21/seq64，READ body309/credit，RSP366槽、FP74槽，三pair计数、四backend计数、seal817、close359/ACK568/term626各有效位和原因；oldRQ与expected可共用同一不可改body，credit1不覆盖。状态IDLE→LOOKUP/PREPARE→ARMED→RUN→WAIT_SEAL→CLOSE→SETTLE→STATUS→GAP，错误STOP→DRAIN/CLOSE或Q。

LG-S01：实际PREPARE锁H/gen，先lookup全文LG/sourceorigin/lease/descriptor/尺寸与slot几何，再由本typedprovider在BINDING内向O实际ACQUIRE唯一SRC readpin并核真实ACK/ref/version/grant，保存该child准备快照；失败不靠未核ACK假设无pin。准备只建立来源/容量，不预读像素。只有旧ACTIVE和旧真实CJ/C0输入许可才能提READ。旧credit空、FP与RSP槽都空时提下一i，本候选不在旧FP候选仍held时提前读后一组，故只有真实FPfire后才推进的i不会造成重复请求。body保持到fire；请求fire后锁expected，不能用同沿新RSP直接形成FP。该保守串行结构的真实吞吐必须计入B05，不能以有两个槽就声称预取流水吞吐。

LG-S02：RSPready独立旧槽空，与C0FPready无关。先记raw后校验完整echo/seq/status/settled与权限；successRGB保存，后续形成原FP74，只有真实FPfire推进delivered/i；FP在stall时全部74位保持。read数量由success read事实，FPfire数量由实际交付事实，不能两者同一个计数冒充。

LG-S03：正常已P FP/合法EOF仍收真实CS；失败/取消注册stop，旧typedRQ必须兑现并独立收RSP。明确匹配job作废或观察旧C0CSvalid终结，允许撤尚未FPfire候选并计discard（R2原FP明示例外），不得撤其它typedheld。先登记触发沿实际FPfire/RSPfire，下一沿处理stop/withdraw；不丢已经交付数据或复制假EOF。

LG-S04：自己的heldREAD全fire、停止新读后锁CLOSE截止；继续接RSP/实际settled，pin真RETURN→ACK→providerclose证书；seal/关闭及本地空已成旧事实才形成term。正常全部P和CS成功；半帧失败不等P/EOF。unknown保credit/pin/sourcehistoricalref进入Q，source termdrained0不删共享源。

### E4. LG-GC full GRAD collector

重要状态：H/gen及GRAD pin/context快照，原CJ/尺寸/retain已核；GRAD185输入槽与其accepted_ordinal21、next_input_pair21、stored_prefix21、seq64、write RQ373/expected、RSP382、seal817、close/ACK、commit/ACK319、term691、raw/good/stored、EOF/错误/四台账。输入接受序号、held请求中的pair_index和已settled写前缀分别表示不同事实，不能共用一个仅在write回复推进的游标。coldLG不复制26份；collector自己的不可变输入/回复槽是新增状态，不能漏FF/RAM合账。

LG-G01：仅retain1实际PREPARE→lookup LG/GRAD真实build/幾何→本typedprovider在BINDING实际ACQUIRE唯一GRAD writepin，核ref/version/grant/ACK→依已授权INIT权限完成真实RMW所需span初始化/effects并保存child快照→真READY；具体CLEAR/pack初始化策略仍B03，没实际满足不得READY。内部初始化不计为本GC P个data WRITE，但close必须覆盖它们真实effects。RUN ready只看旧槽空/准备ACTIVE/旧CJ/stop/rst，不看当前合法性。真实GRADfire先raw+1、锁185并把旧next_input_pair保存为accepted_ordinal，然后推进输入接受序号（超P/溢出登记错误而不wrap）；后续以slot自身accepted_ordinal检查ID/期望坐标/标志/两G signed范围及高padding/dir保持语义。非法不寻址、不写，但真实raw/观测EOF照记录并sticky告父取消；完整CS仍必须接。

LG-G02：合法输入按其accepted_ordinal装两32bit原样pair64；只有旧writecredit空才形成独立held RQ373并固定其中pair_index，输入槽搬运完成后才释放。新输入可留下一185槽，但不覆盖oldRQ；没有无限队列。provider真实fire后锁expected；RSP独立接，正确settledsuccess且对应当前stored_prefix才stored+1/前缀+1并结清credit。输入接纳可以领先写回复一份slot，但写前缀不会借next_input_pair提前推进。首次坏回复只计raw/原因，不能盲推进stored_prefix；实际有过partial效果即按真实close或Q处置。

LG-G03：seal槽独立，P输入未齐也能先收失败CS；CS success正常必须完整原CJ和C0原正常谓词，raw/good/stored=P、合法EOF、无本地错误、所有写settled才允许下一步。CS成功不能弥补漏一GRADpair。C0 flush撤未交付private数据，GC此前已接受185和typedwrite仍保持真实债；取消后不等P/EOF，不复制零尾填满。

LG-G04：正常停止普通write，锁cutoff=P和最后seq→独立close并真实返回GRADpin→消费完整ACK为旧facts；然后发O COMMIT245/保持，O真ACK且immutable/token规范→complete。失败路径不发正常COMMIT，实际close后FAILED/CANCELLED_DRAINED；已有token后再失败保token原值但不得作为正常RC资格。unknownclose/Q无新commit，无假immutable。

### E5. provider与同沿/复位规则

每provider保存完整binding和oldholderlink、单business request、raw/success/settled真实台账、heldreply、close/RETURN旧body及真实effects。SRC/G typednamespace分别固定，只能调用各自SRCr/GRADw；caller只能给logicalpair不能给物理地址/permission。原S CLASS namespace独立，不能以同H复用其唯一当前body给新GRAD。

共同同沿规则：所有fire=沿前valid&&ready&&!rst；e0只锁，后续验证/lookup/capture；新grant/ready/close/CS本沿不能立刻透传下一步。普通full不假设sameedge释放可再用。触发错误/取消沿仍计实际旧fire，随后停止新提议。最后RSPfire后的后续旧closed facts才closeACK；ACK期间禁止旧RQready/RSPvalid。first_reason按首次沿锁；同沿局部字段/身份→坐标→marker→数值→reply协议/实际失败→seal/计数→close/commit→cancel，位置保存原raw可表示值不夹紧，后续原因只OR。

rst期不fire、不普通访问；valid/history资格隔离而非清DDR全部值。冷epoch/allocator初始化只在全owner和physical事务真实fence后；warmreset/epoch变化先STOP、结清/隔离typed/physical旧债，generation不倒退，迟到reply只能匹配old完整context。具体域/恢复保留介质仍B07，不能用本地同步rst声称DDR已settled。

## F. 语言与跨语言契约

C++：本卡没有新的C++实现、ABI或生产控制软件，故actual标准/容器/异常实现N/A（未计划生成C++）；未来独立参考应按数学值建full二维G8/Sobel/dir与row-majorrecords，不复制RTL状态机。不得把参考主机分配当生产存储/性能证据；若后续引入C++，另给标准、整数提升/溢出/窄化、所有权/别名/异常和取消契约再批准。

| RTL A–L | 契约/未知 |
|---|---|
| A 数值 | 端口位宽见D；G s11先扩s12；abs/和校验后窄化，坐标/索引/地址乘加先扩22/33；seq/gen/ref不wrap；容器padding实际0，无浮点/饱和偷偷修改图值 |
| B 时钟/观察 | core上升沿旧状态采样，输出注册后稳定；验证在更新后观察，driver只在指定非采样沿改输入；生产core频率/约束STA仍OPEN，R1已验证25MHz不替代本全机STA |
| C 接受/交付 | 所有typed/datum有valid/ready，来源为可暂停immutableSRC；相机no-loss在独立camera/ring/basic链验证，本卡慢算法候选可跳不等于丢camera像素帧 |
| D valid/推进 | 只真实fire推进计数/prefix/坐标；bubble排已有pending但无新data0事件；C0补边/尾重放不增加本SOURCE/GC输入数量 |
| E 反压/保持 | held请求/FP/GRAD槽/reply/seal/term全文保持；唯一明确例外是R2 FP的真job作废/终结撤未接受候选；typed请求无此撤销例外；RSP/CS/close独立位置 |
| F 延迟/吞吐 | e0收context，后续lookup/grant/prepare、ACTIVE再CJ/FJ，然后首FP；reply至少requestfire后续沿。每scope单业务credit，精确service cycles尚OPEN；不能宣称1pair/clk或约定fps |
| G 复位 | core同步接受禁用/valid隔离候选；实际域/释放与物理outstanding fence见B07；不清RAM值假造effectclosed；warmreset不会重发相同gen |
| H 配置 | 完整旧J/CJ/PCTX在准入/绑定锁定；新C/策略更新不改heldLG/FP/GRAD/CS/term；同沿旧取消只匹配旧活动H/gen；display不改formalretain |
| I 存储 | SRC=3N、GRAD=4N、CLASS=ceil(2N/8)，正确logical/rounded边界；固定base只能目录映射、不是授权；RGB可能跨16Bspan，GRAD64/CLASS4bit需真实pack/init/RMW；深度全部有限 |
| J 身份 | SOURCE creation/CAPTURE与J消费身份独立，descriptorSRC JIDzero不等无源；H full+role+gen回链；pairlane0低x、rowmajor、标志规范、CS/GC/CLASS各计数单位一致 |
| K CDC | 业务owner在同core域候选；实际DDR/camera CDC由PB/PIO合同，接口不直接接异步像素/复位；多位body必须完整握手，不单bit同步fullLG |
| L 实现 | 后续RTL/SystemVerilog符号仅G计划；Ti60F225、Efinity现有环境不改。nativecold候选和typed宽度有静态下界，全机FF/RAM/端口/时序未测OPEN；原厂RAM模型只读 |

三份跨语言契约分别成立：

1. 共同数值：原R2的完整G8/Gx/Gy/dir和CLASS结果为逐bit目标；SRC原RGB、两GRAD32、高8zero及坐标/markers全精确，无容差。没有C++运行证据。
2. 硬件执行：输入数值相同也必须另证ready/stall/持有/真实fire/earlycancel/终态关闭/epoch；函数循环不证明硬件时间。所有新typed请求、回执、cutoff/真实effects和provider版本要独立记录比较。
3. 参考到事务：gold pair i对应hardwareFP/GRAD真fire_i的低lane x_even/highlane x_even+1；按旧J三ID/CJ映射，不按当前C；取消只比较真实前缀与closure，不补fullframePASS；reset前后旧generation/refs隔离。向量/场景只在正式批准后另写，不借已有R1模型冒称新完整Canny验证。

### F2. 冷/热/请求工作量候选下界

O冷体：LG1119需ceil(1119/20)=56词，末词低19/高1实际0；CLO438需22，RC2257需113，合191词3820nativebit（body3814/padding6）。M1 RESULT3×94=282仍0…281；LG282…337、CLO338…359、RC360…472，余473…511共39词。相对旧stage审阅149词增加42词840nativebit，旧文件不改。区间不重叠且<512。此为与能力卡对齐的候选，未占用更多RAM，但**不等完整资源已通过**。

新增有限状态下界/接口宽度显式列出：SRC需READ309/expected信用、RSP366、FP74、seal817、close359/ACK568、term626及计数；GC需GRAD185及accepted_ordinal/两游标、RQ373/expected信用、RSP382、seal817、close359/ACK568、COMMIT245/ACK319、term691及计数；parent/O需ALLOC1076/ACK1213、REGISTER1119/ACK1195、ACTIVE224/ACK812、READY/CANCEL与三pending及全实际effect/journal/返回metadata。request与expected可以同一不可变体、CSseal可以经真借用共享已有父冷快照，但这需要实际寿命/端口证明；不能直接把各字段宽度相加声称准确FF，也不能不算它们。

生产P=1,036,800。原PERFORMANCE E2将CLASS load计P+1，GENERAL load+CLO上界13N+4=26,956,804，不包含已明确OPEN的生产SRC reader和GRAD collector。

- 本SOURCE候选：P个logical RGBpair read；没有read COMMIT，close/prepare/lookup另计M_i。
- retain1 GC：P个logical GRADpair write+1个O immutable publication commit，provider close cutoff=P；bytes=4N=8,294,400，descriptorvalid_count=N。
- 相对原13N+4，retain1新增2P+1=2,073,601，总候选上界29,030,405；retain0新增P，总27,993,604。不是新增对象refcount或camera请求数。

每logical请求必须实际算serial service cycles（lookup/ordinary authorization、pack/RMW、journal/effect、physical访问、真实response和credit释放）；各请求服务时间乘上述真实数量再加prepare/close/metadata/初始化M_i。不能用DDR顺序bulk吞吐代serial STORE成本。缓存若未来正式冻结可减少cold逐请求查询，BIND时全体context/refs/geometry真实验证和cache寿命/撤销仍需证明，现D3每操作full lookup不能静默删除。

RGBpair6B在16B span可能跨两span；GRADpair8B对齐base后位于半个16B，但小写并不自动等半WSTRB可用，PB全WSTRB的RMW span须实际初始化并防邻item/对象破坏；CLASS nibble同理。是否打包多个请求、额外CLEAR流量与port使用是B03/B05，不用logicalP推physicalP beats。原单物理burst/128bit收料预留、typed槽/journal16共享预算和fairness必须联合证明；no-loss/frame-rate不从FREE槽数自行推出。

### F3. 新两个单credit数据路径的最早沿间隔

这里只列本卡结构在所有ready立即满足时的沿间隔下界，不是生产latency承诺。令μSRC/μG为各request真fire到其RSP真fire的实际间隔（至少1；所有后端/transport/物理/仲裁stall已含其中），其它ready等待另加。未冻结服务以μ表示，不能填1作为实际预算。

| 路径 | 最早沿事件（requestfire定义为r0） | 下一requestfire下界 |
|---|---|---|
| SOURCE无提前预取 | r0锁expected；r0+μSRC捕获RSP；+1验证并形成FP/清credit；+2真实FPfire推进i；+3形成下一heldREAD；+4下一READfire | μSRC+4，若μ=1为5clk，仅结构下界 |
| GC已有后一合法输入slot | r0锁expected；r0+μG捕获RSP；+1验证/清credit/推进stored；+2旧credit空后形成下一heldwrite；+3下一writefire | μG+3，若μ=1为4clk，仅结构下界；没有输入/校验未完继续等 |

正常SOURCE按P请求的总最小输入时间还含首次prepare/CJ/FJ、尾处理/CS/close；GC为P写并加独立Ocommit/close控制债。控制路径只冻结顺序：CLOSE提议前全部held请求已fire；末RSP/RETURN ACK后的后续旧事实才能closeACK；GC closeACK capture→后续validate→后续COMMIT提议/fire→实际μCOMMIT reply→后续validate/token→后续term。μALLOC/μREGISTER/μPREPARE/μINIT/μACTIVE/μCLOSE/μRETURN/μCOMMIT、native读写端口调度、重放/epoch/phase/transport结束均待真实后端/能力设计给上界，不新增没有依据的timeout或fps承诺。

## G. 实施与验证计划（尚未执行）

以后只在本卡联合闭合/READY且用户批准后，按“接口适配及registration→provider作用域及failure close→source reader→GC完整收集→Oclose后commit→CONTROL组合→全机资源服务/STA”分增量实施。拟路径只在独立 `work/`，计划符号 `load_grad_stage_preparer`、`algorithm_source_pair_reader`、`full_gradient_collector`、`load_grad_provider_adapter`、`gradient_publication_adapter`；本次这些文件/符号均未生成。变更原C0数值/公共LC/H/body需另版本批准，不顺便改。

| TEST | REQ/IF/不变量 | 文字输入/事件条件 | 期望/来源 | 方法与通过标准 | 状态 |
|---|---|---|---|---|---|
| LG-T01 | 01/02、IF01–03 | 两同CJ不同SOURCE/lease；不同旧J/currentC更新；SRCdescriptorJID0 | fullorigin/lease匹配才准入，错source/refs/version拒绝，不误删原图 | typed独立台账/全文echo；全字段与scope真实比较 | 未运行 |
| LG-T02 | 02/08 REGISTER | load_id0/RID0合法，gen0非法；generation近max，reserve失败/重放 | 独立nonzero、MAX一次后exh、不重用；完整cold末padding0 | 正式仿真读回native词/真实grant/拒绝数 | 未运行 |
| LG-T03 | 02/03 PREPARE | CLASS/G分配一半失败、heldALLOC/READY/CJ时cancel | 保真实部分义务；无假absence/no-CJ；held不撤，真close或Q | 注入正确/错echo，追踪ALLOC→refs→REGISTER→pin→RETURN | 未运行 |
| LG-T04 | 04/05 SOURCE | 全0/full255/彩色图、W6H5/生产1080p；跨16Bspan、FP长期stall | P RGBpair完全同序/markers，独立RSP，无跨obj读 | 全pair黄金与真实request/FP fire/地址span/边界 | 未运行 |
| LG-T05 | 04/05 GC | fullGRAD含zero/±1020、1530边界、两高8、dir2、wrongID/coord/marker | 全N32bit覆盖；错误raw真实记不寻址，未写pair不补 | 独立二维数值+完整record/bin/初始化/guard验证 | 未运行 |
| LG-T06 | 03/05 retain0 | algorithm1、Gready永久0、未分配G；algorithm2切displayRGB | retain0无G等待；algorithm2仍fullGRAD，与display无关 | 真实portfire/absence/CSfields/term数量 | 未运行 |
| LG-T07 | 06/07 独立收尾 | 数据/RSP/CS/close各独立stall；GC等待CS时父其它term未完 | CS仍可接/传，close不等数据P/EOF/wholeRETIRE；無循环 | 有限fair ready种子/强制服务机会+真实数，不只有PASS字串 | 未运行 |
| LG-T08 | 06/07 cancel | beforeCJ/noheld、heldCJ、FPheld、Gaccepted185、最后交付沿、CSvalid后cancel | 真前缀计数，FP明示撤例外/typed不撤；错误不假EOF/P | 事件表+每旧fire+所有真实债/term冻结逐字段 | 未运行 |
| LG-T09 | 03 close scope | CLASS先close、SRC/G仍active/closing；共享SRC多bundle/F/OBS | CLASSACK只CLASS且可真实完成；无整holder早退/无源base误删 | 三scope RETURN及metadata/H/gen隔离 | 未运行 |
| LG-T10 | 05 IF09/10 | fullP写，commit和close反压，writer仍1/dirty/少record、错cert | 只有真close/pinreturn后Ocommit；无writerCOMMITTED/token；失败/Q不进RC | actualclose/descriptor/writercount/version/token及GCterm | 未运行 |
| LG-T11 | 06/08 backend | wrong RSP/late oldseq、UNKNOWN、partialwrite、close错echo、overflow | raw计数真，credit不误清、scope保Q，返回metadata不复用 | 独立request/raw/good/settled及truephysicaleffects | 未运行 |
| LG-T12 | 08 reset/epoch | 各held/effect/metadata中warmreset；晚旧reply及新epoch提议 | 无fakeclose/reusedgeneration，真实fence前普通资格拒绝 | domain/transport/persistentcontext共同注入 | 未运行 |
| LG-T13 | 09 resource/service | 生产P、最坏GENERAL/RC、RGB跨span、init/RMW、单burst公平 | 全logical工作量+M_i/physical/RAM/FF/时序，frame服务按真deadline | 真实profiling/synth/Pnr/STA，未知则失败/OPEN不标PASS | 未运行 |
| LG-T14 | 全REQ 组合 | 无目标/多目标/负样本仍完整1080p链；三term与CLO/RC/abort/lease复用 | 同source/J/config/token，GRAD fullN；完整成功或真实failure/Q | 端到端independent oracle和全部typed/目录观察 | 未运行 |

正常numeric、单位/边界、protocol/sameedge/flow、typed-close和production composition各有独立目标，不能相互替代。具体种子/工具命令/许可/RunId将在正式执行卡冻结，本卡不写可执行TB或runner。

## H. 双向追踪

| REQ与来源 | MOD | IF/中文草图/不变量 | 计划符号（未生成） | TEST | 实际代码与证据 |
|---|---|---|---|---|---|
| 01 PS D2/DIR D4/CONTROL D | J/O/SRC | IF01/02/04，J01/O01/S01，完整origin/lease/J分层 | preparer/source reader/holder adapter | T01/03/04/14 | 待实现；只有来源实读 |
| 02 R4 LC/PREPARED+CONTROL PREPARE | J/O/providers | IF01–03，J02/O02，全文后grant/旧ready后CJ | preparer/provider adapter | T02/03 | 待实现/未运行 |
| 03 R4 close scope+DIR pin/lease | O/L/SRC/GC | IF08/09/12，O03/05/S04/G04，pinreturn≠base/holder退 | holder/provider adapters | T09/10/11 | 原LC只CLASS事实；新三scope待实现 |
| 04 R2 GRAD/CJ/retain | SRC/C0/L/GC | IF04–06，S02/G01/02，P/两32record/raw先记 | source reader/full collector | T04/05/06 | 原R2设计非新实现证据 |
| 05 R2CS/R4CLASS/DIR COMMITTED/R4RCfullGRAD | J/O/GC | IF07/10/11，J03/O04/G03/04，close后immutabletoken | seal fork/publication/collector | T07/10/14 | 待实现/未运行 |
| 06 R4真实close/PS共享源 | 所有scope | IF08/09/12，E5，独立RSP/close/metadata | provider adapters | T07/08/09/11 | 组合反例/候选推演 |
| 07 C0FP撤例外/privateflush/真实失败 | SRC/GC/J | S03/G03/J04，CS早失败不等P，typedheld不撤 | reader/collector/preparer | T03/08/11 | 待实现/未运行 |
| 08 DIRgen/CTRL旧fire/根RTL | 全部 | D1/E5/F A–L，oldH+gen/epoch/fence | stage/transport/control | T02/03/12 | 资源/协议静态候选 |
| 09 PERFORMANCE E2/目录/native | J/O/provider/physical | F2+LG-B03/B05，191cold词/新增2P+1，service cycles | 后续实际resource/service card | T13/14 | 仅候选算术；无fullmachine measured数据 |

反向核对：每个计划模块只承担上表REQ；新allocator、registry、source reader、fullcollector、publication、seal fork、独立close和metadata各有明确来源缺口/接口/测试。没有以泛泛“优化”添加其它识别算法、相机配置或后端软件。原L/C0复用限制和新adapter与旧publicbody相容性亦在D明确。

## I. 门槛与评审

①整体行为/样例：B有正常retain1/retain0/prestartcancel/中途失败。②职责/连接：C有事实复用与新实体划界。③明确接口/相容：D有候选schema/位宽/子scope与原body，互等反例；provider/cache/alloc全机仍BLOCKING。④局部中文草图：E有旧facts/held/stall/abort/close/pin/metadata。⑤语言映射：F填写RTL A–L及三共同/执行/事务契约，C++未计划有理由。⑥组合走查/覆盖：D4/G/H有反例与覆盖。⑦实施/验证/追踪：G/H只是文字计划未生成代码。⑧无阻塞：**不满足**，LG-B01…B08仍OPEN。⑨保存/读回/呈现：本卡写后实际全文读回并记录hash/区间/字段算术，向根代理与用户报告入口；不预写已通过。⑩版本/范围/基线：A已绑定，但本卡没有READY/implementation批准。

当前仍 `NOT_READY / NOT_APPROVED`。READY_FOR_REVIEW时间N/A（尚有实际阻塞）；未来只有联合闭合和规范门槛全部具备才提交指定版本给用户。原R1批准和完成证明只属于原范围，不扩展到本卡；本次不写Approval Manifest/数据库/运行状态。

## J. 变更与恢复

旧stage-review cold149词/LC270只能CLASS→本候选fullLG1119/cold191词，新增真实来源/GRAD与两provider、ALLOC/子scope/close后Opublication；属于新的重要接口/行为/存储选择，不是旧实现内部微调。原review和旧规划全部保持hash只读。消息中的“GC先COMMIT内返pin”探索未成为本卡选择，最终选择明确IF09 CLOSE→IF10 O COMMIT；正式后若改变需新版本/追踪再审，不默改。

恢复先核A2实际hash、本卡版本/差异/相关能力卡/全机blocker/原批准有效范围；新依赖变更时先读真实字段再修订本卡。既有R1 frozenhash/交付记录不改；新纯设计卡后续实施路径另批。metadata不能因读取当前大版本或cachemiss清资格。

## K. 实现与验证实录

业务实现、编译、仿真、综合、布局布线、STA、bit/hex、硬件/功能验收：全部未执行，未生成对应产物。R1已存在真实软件交付由其专属记录说明，不拿来填本卡PASS。本轮实际工作仅入口顺序阅读、A2源有限读取/hash、文字设计、static字段求和和native区间检查及本卡保存读回；实际hash由独立报告给出。

## L. 交付与后续阅读

完成的是这张局部纯设计候选与接口/关闭边界。未完成的是LG-B01…B08的全机联合冻结、批准及全部实现/运行。先整体B，再C连接和D共同合同，再E分支内部，最后F/G/H预算与验证；不要先从未来符号名猜代码行为。

一条可读事务路径：原immutableRGB身份/lease→旧J+BIND历史→真实C/GALLOC→LG全文/register/gen→SRCr/CLASSw/Gw分别prepared→ACTIVE→CJ/FJ→真实FP/CLASS/G→父真实CS/seal→CLASS真初态token/自身close；SRC读close；G fullwrite真close/RETURN→Oimmutabletoken→三个term→CLO/RC→各owner真实退休/最终bundle。改变任何来源身份、pin范围、sealed格式、时序/反压、close/commit顺序或资源必须回到对应REQ/IF/草图/TEST修订，不能只有源码注释改变。

设计分析为候选推演，功能与理解验收均待检验；用户未实际作答不标已理解。代码/注释/测试一致性尚无新代码可核，未来批准实施后逐实际符号/参数/更新点/日志验证。本卡本身不要求人下载硬件、不触发硬件闸门。
