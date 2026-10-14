# TRACK4-ALGORITHM-NO-LOAN-CLOSE-001：无借用关闭的联合语义修订 v0.1

2026-10-04；LOCAL_INTERFACE_DESIGN／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。本卡按 PLAN_TEMPLATE 补充 SCAN v0.2 与生产行 HANDOFF v0.1 的关闭合同，保持完整十一项、1920×1080、完整八邻域 Canny、原识别及质量要求。本文是候选增量；原稿、整合 v0.8 和真实工程尚未吸收，不能混接新旧 schema。

## 通用计划字段

- Goal：使已登记 exec 在 OPEN 从未形成或全部真实拒绝时能够关闭，并防止 STALE/granted0 被误当成不存在旧 grant 的证据。
- Current state：SCAN409 仅编码 never_opened；HANDOFF 明确拒绝但未创建 loan 的路径仍 OPEN。没有当前算法业务实现。
- Target state：唯一 O 给出可区分的原始创建/不创建决定；CORE 对全部尝试作有界折叠；D 只消费联合新语义的真实关闭证据。
- Gap/Open questions：NL-B01…03 见 I；实体目录、CDC、实际资源和恢复仍缺直接证据。
- Assumptions：原四 exec、单族 singleton OPEN 运输、每 exec 最多一次成功生产 loan、原独立 STOP、借用/银行/parent 分层关闭不变。
- Dependencies：A 两份实际来源及 v0.2 唯一规范；当前未批准卡不能为实现授权。
- Milestones/Detailed steps：反例→整体四状态→回复分类/关闭位→中文逐沿草图→有限独立审阅→实体目录与全局 schema/预算冻结→READY→指定批准→实现及验证。
- State transitions：仅文档设计阶段；PROJECT_STATE、数据库和硬件状态不改。
- Artifacts and hashes：A 为读入来源；实际输出摘要及审阅范围另存报告，不自填本文自身 hash。
- Validation：G 全部文字场景、NOT_RUN；容量推导与实际工具结果分开。
- Failure handling：已形成 valid 和真实旧 fire 继续履约；不明结果、矛盾结果、未知 effects 保引用并 Q，不以零值擦债。
- Human approval gates：旧 IP 预检授权不含此业务协议；当前不申请不完整设计批准，不生成源码、功能脚本或 TB。
- Rollback：原 HDK/来源不改；撤回本候选不会使原未解决路径成为已解决；恢复须核 A 及联合版本。
- Completion criteria：本卡接口设计只有在联合依赖关闭后才能 READY；完整目标仍须十一功能及真实软件验证至 bit，当前未满足。

## A. 来源、范围与阅读顺序

| 实际来源 | SHA256 | 本次依据 |
|---|---|---|
| [SCAN v0.2](design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | D2 CORE_CLOSE409/417、D3 未 OPEN、E3 收尾、F/G/H；原稿保持不变 |
| [HANDOFF v0.1](design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md) | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 | D1 GRANT459、D3 拒绝 OPEN 编码缺口、D4 有限缓存、OP02/06；原稿保持不变 |
| [整合 v0.8](design-TRACK4-ALGORITHM-INTEGRATION-001.md) | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF | 全范围、五类工作与未完成状态；尚未吸收本增量 |

唯一规范 SHA256 为 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；模板为 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。先读 B/C 整体，再 D 接口与组合，E 中文操作，F/G/H，最后 I/J。下文定义明确覆盖 A 所列两卡的相关语义；未联合修订的旧接收方不能接新消息。

## B. 整体行为、反例与要求

NL-REQ01：只有 V 真实成功 PREPARE、CORE 真实 REGISTER 后，才讨论该 exec 的无 loan 关闭。早到 STOP 仍按原四 private 槽持有，不自行创建 registry 或 no-loan 证书。

REQ02：OPEN valid 已形成就成为旧义务，是否已经 fire 不影响这一点。借用号为零、granted0、当前目录没找到以及一段时间无回复，均不足以证明该 exec 从未创建 loan。

REQ03：每一确切 OPEN 的创建结果由唯一 O 给出原始不可变决定。原始 no-create 与诊断拒绝必须在线路上可区分；临时验证引用未退或仍可能晚 grant 时不能发布 no-create。

REQ04：任一成功创建历史永久优先，直到该 exec 真实退休；后来拒绝、停止、loan 返回不把它改成从未创建。未知结果不得被后来单份拒绝清除。

REQ05：无 loan 路径不发送 borrow0 的伪 BULK_CLOSE。它仍须关闭自己的生产消息、renderer、读 effects 和所有旧运输；D 仍独立汇合银行与物理扫描关闭。没有输出不能改报完整显示成功。

反例：O 实际成功创建 loan，但成功回复未知；cache 淘汰后，CORE 重发旧请求收到 STALE/granted0。若仅看 granted0 就报 never_opened，旧对象 pin 会被漏算。新合同将该回复标为 DIAGNOSTIC，保持 U/Q，不授正常关闭。

正常拒绝例：真实登记→新 OPEN→O 原始 no-create 完成且临时 refs 已退→正确完整回复消费→STOP 禁止重试→所有旧运输排空→后续旧资格沿形成 no_loan_proved。晚成功例：STOP 与旧成功回复同沿，先记录真实 borrow，再停新业务，真实返 loan；最终走 G。

## C. 职责与整体交接

O 实际判定 → NL-IF01 GRANT461 → CORE 的每 exec 折叠账本 → NL-IF02 CORE_CLOSE409 → D 本地核验/ACK417 → 原 SCAN_CLOSED/RETIRE/DISPOSE。STOP、真实 BULK_CLOSE、银行退休及 parent RETURN 仍独立。

| MOD | 唯一职责、拥有的状态 | 边界 |
|---|---|---|
| O/BUNDLE_OWNER | 原确切请求、原始判定分类、真实对象 pins/loan 与临时验证 refs | 诊断拒绝不假冒原始决定；缓存只重放复制值，不再创建 |
| CORE/ROW_PRODUCER | 登记的历史 KEY、一次成功 borrow、全部 OPEN 尝试的折叠事实、停止与旧消息债 | 不用原始未核 handle 授读；不因当前 UI、新 seq 或零值擦债 |
| D/SCAN_OWNER | 消费联合关闭语义并核真实 producer 数量、银行和扫描 effects | CORE 报告不代 D 自身闭合，不等待父图整体 FREE |

整体设计检查点：本卡解决否定证据的表达及组合；实际 provider 目录/ledger、运输和端口服务尚未实现，不能进入代码阶段。

## D. 接口、四状态与组合检查

全字段 unsigned，原字段高到低顺序不改；本域 posedge 沿前 valid&&ready 且非 rst 为 fire。源 held 与目的 private 全文保持；跨域运输不等实际业务提交。

### D1. 原始决定分类的明确增量

NL-IF01 将原 GRANT459 尾部追加 decision_class2，形成 **GRANT461＝原 OPEN387／borrow64／status2／reason5／granted1／decision_class2**。OPEN387 不改。保持原字段相对次序，但原459整体位于新体[460:2]，绝对位索引上移2；新class在[1:0]。具体为原OPEN[460:74]、borrow[73:10]、status[9:8]、reason[7:3]、granted[2]、class[1:0]。这是接口变更，不宣称兼容旧459接收器。

| class2 | 名称/输出合法组合 | 提供方实际保证及使用限制 |
|---|---|---|
| 0 | ORIGINAL_CREATED；status0/reason0/granted1/borrow非0 | 原新请求曾真实原子登记唯一 loan/pins；精确重放保相同原结果，不重新授读 |
| 1 | ORIGINAL_NO_CREATE；status2 BUSY 只配reason3 BUSY、7 CLOSING_BUSY或18 CAPACITY，其余合法原始拒绝配status3 REJECTED；granted0/borrow0 | 该确切新请求的原始不可变判定没有提交 loan；临时验证引用已退、无未来创建资格；当前461运输仍须按held履约，精确重放仍是同一历史判定 |
| 2 | DIAGNOSTIC；status3 REJECTED、reason非0、granted0/borrow0 | STALE、SESSION、同 seq 异 body、无法定位原决定等诊断；不证明旧原请求未创建 |
| 3 | UNKNOWN；status3 REJECTED、reason12 UNKNOWN_EFFECT 或19 STICKY_FAULT、granted0/borrow0 | 原决定或 effects 不可确定；保持可能 grant/Q，不提供可用于读的 raw handle |

原 status1 ALREADY 不作为新 OPEN 创建/否定判定；精确重复回原 class/status/reason/borrow，不把原成功改 ALREADY。class1 不允许 STALE2、SESSION16、BAD_ECHO17、UNKNOWN_EFFECT12、STICKY_FAULT19；保留 reason26…31 也不能用于证明。FIELD1 仅在 O 已确定这份新原始请求确实没有创建时可 class1；同 seq 异 body 的 FIELD 必须 class2。理由不是证明来源，class1 仍必须对应真实原始判定与清理事实。

class1 的 reason0非法；忙类3/7/18仅配status2，其余未排除的原始拒绝理由配status3，故FIELD/status2明确非法。能否触发某一理由还须实际O判定/清理路径支持，不能为了填合法编码虚构原始事实。

O 的 pending/held/cache/存活 loan 成功关联窗口精确重放原分类；已淘汰且不存在可验证原决定的旧 seq 仅 class2 STALE。接收方对任何不合组合、错完整 echo、矛盾历史或未经授权 session 保债并 Q。class2 本身不命令无限重试；原单次未知结果由恢复流程解决。

### D2. CORE_CLOSE 原位改名与四状态

NL-IF02 保持 **409/417** 位数及顺序，只把原 never_opened1 原位改为 **no_loan_proved1**。全部字段仍为 KEY256／borrow64／borrow_known1／no_loan_proved1／producer_rows11／producer_messages_closed1／renderer_closed1／read_effects_closed1／loan_closed1／no_unknown1／status2／reason5／report_seq64；ACK417 为原409/status2/reason5/stored1。

409的绝对位域为KEY[408:153]、borrow[152:89]、known[88]、proved[87]、producer_rows[86:76]、五个关闭/未知事实依次[75]/[74]/[73]/[72]/[71]、status[70:69]、reason[68:64]、report_seq[63:0]；ACK417原409在[416:8]、status[7:6]、reason[5:1]、stored[0]。位域相同仍有语义变更，不能按宽度判断旧D兼容。

| exec 状态 | 必须成立的真实条件 | 409 中的编码 |
|---|---|---|
| N 从未发布 OPEN | 登记已成立；从未形成 OPEN valid；新 OPEN 已封闭；所有本地/运输义务已关闭，无 unknown | known0/borrow0/proved1/producer_rows0；loan_closed1 表示实际无创建证明 |
| R 全部尝试明确不创建 | 所有已发布 OPEN 都有正确完整 class1 原始结果；没有成功历史；全部请求/回复/临时引用真排空；不再重试 | 同 N；不发送 borrow0 CLOSE |
| G 曾成功创建 | 曾消费正确完整 class0；保历史 borrow/nonzero known，实际 loan 返回后才 loan_closed1 | known1/borrow非0/proved0；producer_rows 可为0，但其余关闭事实仍要真成立 |
| U 未决或 Q | 任一旧 held、未核回复、诊断不能证明原决定、冲突、未知结果或可能 grant 尚在 | proved0，不能正常关闭；已知旧 borrow 保留；未核 raw borrow 不授读 |

正常关闭 N/R/G 均要求 no_unknown1、全部 producer/renderer/read/message 真实闭合，以及与状态相符的 loan_closed。D 核完整 KEY、所有字段合法组合与本域真实 rows_received/银行事实；N/R 必须 producer_rows0，不自造行。Q 可报告实际冻结事实但不授 SCAN_CLOSED、RETIRE 或释放；未证事实不填1。

### D3. 有界折叠与数值成本

每个真实登记 exec 持有五个累计/活动事实：any_open_published、created_seen、open_unresolved、all_resolved_no_create、unknown_sticky。冷合法登记初值0/0/0/1/0；valid 与所有会话资格另有原 registry 状态，未登记不能读这组初值制造证明。四份增加20bit逻辑状态下界，不将其藏进906或451的 padding。

全局 singleton OPEN 只有一份源 held/目的 private 及反向回复；每 exec 只有一个待判定 OPEN。发布新 OPEN 即置 any/open_unresolved、撤销当前 absence 资格；只有此前请求明确 no-create 且真实运输关闭，才可使用新 seq 重试。一次 class0 后禁止该 exec 新 OPEN；它的 loan 返回不清 created_seen/known/borrow。class1 只折叠确切当前尝试，未知 sticky 不被清掉。精确重复不重复折叠；不同新尝试严格按原高水位规则串行，无须无限保留历史。

all_resolved_no_create记录已完成尝试的累计结论，不把尚未完成尝试算进去：新发布时保其旧值但open_unresolved置1；确切class1完成时保旧累计值并清该未决；class0令created_seen1及累计0；无法证明原决定的class2/3、冲突或坏echo令unknown_sticky1及累计0，不用后来class1恢复它。N/R形成条件还分别检查any与created/unknown/未决，以及全部实际运输关闭；五个状态位不能替代完整当前请求/有限原窗口。

列出 body 修订：OPEN/GRANT 两端成本由1692增至1696（+4）；七组完整 cache 由7405增至7407（+2）。故 HANDOFF 六族12796→12800；登记/关联下界19036→19040；加 FETCH21050→21054；加 cache28455→28461；并列既有 RowCtx4325 后32780→32786。另加20bit折叠状态及未列控制，不称 FF 或完整资源。原 SCAN30306 的409体同宽不变，但 D 接收状态/检查逻辑须明确修订。

### D4. 错误原因与结果

HANDOFF→SCAN 明确按名称映射：共同0…21同名原因沿原定义；RANGE22→FIELD1，COUNT23→ROW_FAULT8，NOT_INITIALIZED24/NOT_COMMITTED25→BAD_CERT14；26…31拒绝，不按裸数值 cast。CLASS 错误或原始证明不足用 BAD_CERT14；未知 effect 用 UNKNOWN_EFFECT12。BUSY不是最终显示成功，停止关闭用真实 CANCELLED5、RESET13 或 DEADLINE6。此前不可恢复故障锁定后，取消不将失败改成成功/取消；同沿先结旧真实事件，再记停止，错误优先级联合后续全局错误矩阵冻结。

## E. 中文局部操作草图与沿规则

1. **登记/早到停止**：先保原 STOP private；REGISTER 完整匹配并实际提交后初始化本 exec 折叠事实，绑定早到 sticky stop。尚未登记不回 no-loan 报告；已停止且从未形成 OPEN valid 的 registry，在其它债闭合后的后续沿走 N。
2. **形成请求**：仅沿前 registered、未 stop、未 created/unknown、没有旧 unresolved 与真实 OPEN 运输槽空时形成新 held387。形成 valid 当沿就记发布/未决；后来取消不能撤掉该体。O 下一旧资格判定，不使用请求出现沿的影子目录授权。
3. **O 判定**：新合法 attempt 在真实目录核验下，要么先提交唯一 loan/pins 再形成 class0；要么先结束所有临时验证/引用并确认 no-create不可逆再形成 class1。缓存/存活成功记录精确命中重放原结果；无法恢复原决定时 class2/3。已形成回复全文保持，不因 STOP 变化。
4. **消费回复**：CORE 先核授权 session、完整原387 echo、seq、borrow、class/status/reason组合及历史。正确 class0 记录 created/known/borrow，清该确切 unresolved；class1 折叠该原尝试；class2不能折叠为no-create，class3或矛盾置 unknown/Q。无本地当前尝试的重复必须查真实有限原窗口；不能归到别人 exec。
5. **同沿与晚回复**：成功回复与 STOP 同沿，先登记真实成功，再 sticky stop，下一沿禁止新 ASSIGN/FETCH并真实返 loan。明确 class1 与 STOP 同沿先记回复，后续旧资格沿等实际运输排空才走 R。STOP 时回复未到保持 U，不能报 N。登记、reply、closed 及报告形成之间均不让新资格穿透。
6. **形成报告**：从旧登记/折叠/运输/效果账本核 N/R/G；N/R无伪 CLOSE，G须 O 真 released ACK已核。所有旧 OPEN结果与运输均封闭、producer/renderer/read事实成立才形成不可变409；原 D 的银行/物理退休继续独立，不等父图整体 FREE。形成后仍按 held 履约，不覆写报告。
7. **重复/矛盾/复位**：拒绝后新 seq 重试回 U；成功后任何拒绝不能清历史。未知不能靠新epoch清除；warm reset 保旧原体/引用直至真实关闭或正式隔离。报告成功承诺之后才发现违背封闭的晚结果，进入独立健康/隔离流程，不改旧 held 成功、不复活旧 exec；确切恢复 schema 仍 NL-B03。

不变量：原始决定有唯一来源；created_seen 一生单调；no_loan_proved 只有全部原尝试已知不创建或确实未发布时成立；诊断不是历史证明；每次新请求撤销当前 absence；计数/零值不能替 effects；关闭源 loan 与复制银行不同寿命。

## F. 语言及对应契约

C++ 业务实现 N/A：本卡仅接口/RTL生命周期设计，未来独立协议参考的标准、编译器、所有权、表示及错误需整包基线冻结。无函数体或可执行测试。

| RTL A–L | 本卡合同/未决 |
|---|---|
| A 数值 | unsigned387/461/409/417，class2合法表；seq64扩65不回绕；20bit累计状态不隐藏 |
| B 时钟 | core/domain旧沿资格，沿后提交，下一沿使用；D pair域另经真实mailbox，不多位直采 |
| C 接受 | valid形成、源fire、目的完整接纳、O创建、回复消费、报告stored各自区别 |
| D valid | 已形成旧请求/回复继续履约；未登记无absence资格，invalid不更新折叠 |
| E 保持 | STOP/reset不撤held；正确回复全体锁定，诊断不清未知 |
| F 时序 | 回复消费同沿不形成关闭；实际运输/目录清理上界未冻结 |
| G 复位 | cold有效性隔离与warm排空分开，unknown不单端清除 |
| H 配置 | 历史KEY/PLAN/parent/mask及决定不随UI变；新旧schema不能混接 |
| I 存储 | 四exec、原单族singleton；缓存/折叠/目录和运输副本分列，端口服务OPEN |
| J 身份 | full echo/key/seq与唯一旧尝试核验，created历史不可被高水位/拒绝抹去 |
| K CDC | source fire不代D stored，报告ACK/复位授权/晚消息隔离NL-B03 |
| L 实现 | Ti60F225/I3、SV2009目标；+6body/+20state只是候选成本，map/STA未运行 |

共同数值契约为编码表与整数身份；硬件执行契约为E真实沿/消息/effects；对应关系按真实有效事件、原确切请求、完整回复与历史grant比较独立oracle，不把软件“返回失败”当成物理无创建证明。

## G. 实施与验证计划（未执行）

先联合 O 目录/原决定窗口、SCAN/HANDOFF schema、错误与恢复、文件/资源→READY/指定批准→独立work实现 O 分类及CORE折叠/D检查→真实协议/CDC故障场景→整包回归和 Efinity 工具验证。当前不创建业务文件或 TB。

| TEST | 要求/事件 | 期望/观察 | 状态 |
|---|---|---|---|
| NL-T01 | 01/02 STOP先登记、OPEN valid未fire | 未登记不报；真实登记后N；已valid则U且原体保持 | NOT_RUN |
| T02 | 03/05 O原始拒绝后STOP | class1/全echo及临时refs闭合，运输真排空后R，无borrow0 CLOSE | NOT_RUN |
| T03 | 04 STOP与晚成功同沿 | G保真实borrow、禁止新业务、真返loan；可rows0但不伪显示成功 | NOT_RUN |
| T04 | 02/03 成功回复丢失、淘汰后STALE | class2不证明absence；U/Q/pin保持 | NOT_RUN |
| T05 | 03 同seq异body FIELD与新原始FIELD | 前者class2；后者仅真实no-create才能class1，不按reason猜 | NOT_RUN |
| T06 | 04 拒绝→新seq重试→成功；成功后拒绝 | 新请求回U；G历史一生保留，no-loan位不置1 | NOT_RUN |
| T07 | 03/04 精确重复、错echo、矛盾class | 原决定重放不重复创建/折叠；矛盾或未知Q | NOT_RUN |
| T08 | 05 回复与报告形成竞争/慢ACK | 旧unresolved阻报告，不同沿资格穿透；held全文不覆写 | NOT_RUN |
| T09 | 05 warmreset/seq耗尽/新旧schema/晚故障 | 旧债不清、未知不放行；版本错拒绝；承诺后独立健康流程 | NOT_RUN |

未来方法为独立 O 事件参考、真实目录/loan ledger、随机CDC相位及停顿；分别核创建数、真实pin与transport prefix、完整字段、D扫描终态。软件结果不代厂商IP或route后STA。

## H. 双向追踪

| REQ | MOD/IF/草图 | 拟符号（未生成） | TEST/实际证据 |
|---|---|---|---|
| 01/02 | registry/CORE，IF02 E1/2 | production_open_attempt_ledger | T01/04/08；来源反例/候选设计 |
| 03 | O，IF01 D1 E3/4 | production_bulk_open_decision | T02/05/07；实体目录未实现 |
| 04 | CORE，D2/3 E4/5/7 | production_open_history_fold | T03/06/07/09；未运行 |
| 05 | CORE/D，IF02 E6/7 | production_core_close_adapter | T02/03/08/09；实际effects/CDC未验证 |

反向拟模块只承担这些旧关闭缺口，不重写图像数学；实际符号、注释、代码和测试位置待批准实施。

## I. 门槛

- NL-B01：O 完整对象/plane目录、真实原始决定窗口及临时引用关闭，与RAW/VIEW/生产loan唯一owner联合落地；class字段本身不是物理证明。
- NL-B02：SCAN/HANDOFF/整合统一schema及文件基线、错误优先级、全资源/端口/服务冻结；本文尚未被原稿吸收。
- NL-B03：真实跨域/复位/epoch及承诺后健康隔离，保护IP仿真与完整工具验证依赖仍缺证据。

规范10.3①B行为及反例；②C职责/来源；③D候选接口和组合；④E局部状态/草图；⑤F语言对应；⑥D/E走查；⑦G/H计划追踪；⑧不满足上述阻塞；⑨保存读回/呈现及有限审阅另记；⑩v0.1范围及A来源明确，实施基线未冻结。保持NOT_READY，不生成代码。

## J. 变更、恢复与K/L实录/阅读

旧 never_opened 无法表达明确原始拒绝后的关闭；仅改名仍不能区分诊断与否定证据。因此联合候选：409/417原位no_loan_proved，GRANT459→461追加class2，五个有界累计事实，以及STALE/错误/同沿规则和新场景。原两卡body算术保留为其历史口径，本卡D3列出差值；不把旧报告当新稿全审或实现通过。

本卡不改原来源或整合v0.8。将来联合吸收须保留原字节、同步所有端点/追踪/预算及新指定批准；当前不能仅把CORE端改名连接旧D。读A→B/C→D→E→F/G/H/I；实际文档保存/限定审阅另存控制面报告。无新RTL/C++、功能脚本/TB、build/sim/map/PNR/STA/bit、网络安装、数据库/正式状态或硬件动作；完整任务仍未完成。
