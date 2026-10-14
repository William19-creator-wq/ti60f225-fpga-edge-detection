# TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001：生产行全局交接候选 v0.1

2026-10-04；GLOBAL_INTERFACE_DETAIL／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。按 PLAN_TEMPLATE 填写。本卡补 ROW/SCAN 之间的登记、真实借用、分配、填料及关闭合同；不缩小五基础、六高阶、1920×1080、完整八邻域 Canny、原识别与质量要求。PC 仅参考、仿真和观察。

## 通用计划字段

- Goal：将板载 DDR 完整平面经真实借用、全行输入银行、渲染输出银行交到固定扫描，并独立关闭各层义务。
- Current state：已有 Ti60F225/I3 工程及参考综合成功证据；新增生产算法未实现。ROW v0.2 有局部银行/渲染合同，SCAN v0.2 有提前 exec 与真实采用合同，完整交接此前 OPEN。
- Target state：本卡与实际目录、DDR adapter、CDC、服务和全资源共同冻结，形成指定批准基线后连续实施、仿真、综合、布局布线、时序和 bit 验证。
- Gap/Open questions：H-B01…05 见 I；本卡的新增 typed 消息只是候选，未迁移旧 PC/UART 后端或假设保护 IP 行为。
- Assumptions：core100 候选、4 scan exec、5 RowCtx、2 input、3 out、1 renderer、1 issued 物理 burst；服务够用须独立证明。
- Dependencies：A 的真实 SHA256 来源，唯一 v0.2 规范与原控制面治理。
- Milestones/Detailed steps：实际来源→整体关闭次序→字段/局部草图→独立有限复核→目录/DDR/服务/资源/文件联合冻结→READY→指定批准→work 实施与真实验证。
- State transitions：本卡只记录设计阶段；正式 PROJECT_STATE、数据库、硬件闸门不改。
- Artifacts and hashes：A 是输入基线，本文及审阅报告是设计产物，不是可执行代码基线。
- Validation：G 仅文字场景、均 NOT_RUN；实际阅读和有限算术/协议审阅另记。
- Failure handling：旧 fire 与已形成 held 履约；未知效果或未知 grant 保留引用并 Q，不能伪造归还。
- Human approval gates：原 IP-PRECHECK v1/v1.1/v1.2 不覆盖本卡业务源码或测试。当前未达到 READY，不申请批准不完整卡。
- Rollback：原 HDK 只读，本卡不改工程/约束；候选修订保存旧版本与实际摘要，获批实现仅在指定独立 work。
- Completion criteria：完整十一项真实实现及软件验证至 bit，全局阻塞关闭；当前未满足。

## A. 范围、来源与阅读入口

| 来源 | 当前 SHA256 | 采用范围/限制 |
|---|---|---|
| [整合 v0.8](design-TRACK4-ALGORITHM-INTEGRATION-001.md) | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF | 完整目标、2 physical bundle 与五类工作；仍 NOT_READY |
| [PB](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 | 真实全拍 DDR 子集候选、R_ROUTE、input18/RX7、行范围；服务/资格 OPEN |
| [ROW v0.2](design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md) | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8 | RowCtx865、KEY164、2 input/3 out、renderer/独立 INPUT_RETURN |
| [SCAN v0.2](design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | CTX840/KEY256、4 exec、STOP262/270、CORE_CLOSE409/417、已发布 ROW 原472族 |
| [PIO](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | 原 ROW472 字段/银行退休、固定 1080p60；旧 scan 分配已由 SCAN 显式覆盖 |
| [VIEW](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | O 唯一完成 bundle/borrow/plane_ref owner；生产长持有是整合增量，非旧单次 RETURN 的隐式兼容 |
| [RAW v0.2](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD | FPGA typed/journal/commit/目录边界；PC64MiB/UART/S96/地址26 只供旧仿真候选，不能移作生产存储 |
| [真实工程与公开 DDR 证据](../experiments/track4_algorithms_20261004/03_review/efinity-project-and-ddr-interface-evidence-v0.1.md) | F75468BBCF448A4B4EB7AD7A435048D46A2FDA736D316262DD146A9313EFC652 | Efinity2026.1.132、C0/C2/I3 已存在；旧 master 不提供完整 B/R 校验、校准准入或排空证明 |

规范 SHA256 为 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2，模板为 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。先读 B/C 整体，再 D 字段与逐连接、E 中文局部步骤、F/G/H，最后 I。来源保持原字节，本卡通过明确增量提出交接，不冒称旧来源已联合实现。

## B. 整体外部行为

H-REQ01：只从唯一 V 实际消费并核完正确成功 PREPARE ACK 后取得 exec/target/parent/slot。ROW_PRODUCER 不预测 VSYNC、不自行分配 exec，也不把提前 exec 当 APPLIED。

REQ02：BUNDLE_OWNER/O 核完整同源已 COMMITTED 的 required planes、版本、范围与实际 parent 后登记 read loan。DDR、FETCH、IMPORT、ROW 不自授权限，caller mask 只是待比较的请求。三个 plane 在同一旧 PLAN 下，不能用 CLASS 代 EDGE、旧 ANN 代新结果或独立拼图。

REQ03：每 exec 按 target_y=0…1079 顺序分配，最多一个未结束的 ASSIGN/FILL 事务；不同 exec 可以各有事务。ROW_OWNER 独立分配全 epoch 唯一 row_seq、input gen 及 5 RowCtx 之一。caller assign_seq 不等于 row_seq。2 input/3 out 不增，FULL 后旧 input 可等待渲染，不能因 FILL 事务结束而 FREE。

REQ04：单 burst 的 R_ROUTE 在已复制并无旧 RX/pending/holding/decoder 引用后退出，不等待全行 FULL。FULL、输入 READ grant、输出 reservation、ROW valid 发布、OWNED、APPLIED 各是独立真实事件。合法 mode5 行分别为405数据拍、720逻辑写、2880 lane WE、960 pair 与2304 output words。

REQ05：STOP 后旧 OPEN/ASSIGN/FILL/OUT 回复仍接纳、结账并退还。未发布输出走私有 RETURN；ROW valid 一旦形成，即使未 fire，也按原472族关闭。输入银行可在实际无未来 RE/银行引用后独立归还。

REQ06：源 loan 在不再新 FETCH、全部旧读与 route/fill 引用关闭后独立返还，不等输出银行整体 FREE、SCAN_CLOSED 或父图 FREE。CORE_CLOSE 另等 producer 消息/renderer 等本地义务；D 再汇合已发布银行、物理扫描及其真实计数，最后 CLOSED/RETIRE/DISPOSE。Q 或坏 echo 不授释放。

正常样例：V 真实成功 PREPARE→REGISTER→O grant→ASSIGN input→分 burst 真填料→FULL→out reservation→input READ→960 pair→input RETURN→2304 WE 真完成→ROW held→D 正确 OWNED→目标真实 VSYNC 采用。停止样例：STOP 早于 REGISTER 时原独立槽保留；匹配登记后立即 stopped，不发新 OPEN；已发 OPEN 的晚成功另登记并返 loan，不把 borrow0 当 never_opened。

## C. 唯一职责、连接与组合检查点

普通文字连接：V→H-IF01 REGISTER→四份 CORE registry；O/BUNDLE_OWNER↔IF02 OPEN/GRANT→ROW_PRODUCER；PRODUCER↔IF03 ASSIGN→ROW_OWNER→IF04 FETCH→DDR/RX/decoder→IF05 FILL_TERM→PRODUCER；ROW 既有 renderer→IF06 私有 out RETURN 或原472族→D；IF07 BULK_CLOSE→O，之后原 CORE_CLOSE→D。独立每 exec STOP262/270 不穿过这些数据口。

| MOD | 唯一拥有与职责 | 不承担事项/依赖 |
|---|---|---|
| V/REGISTER_SOURCE | 已核 PREPARE ACK 的完整历史 CTX/真实 slot 与 register_seq；先保原持久 parent pin | 不以 REGISTER success 造物理采用，不撤原 PREPARE/held 义务 |
| ROW_PRODUCER | 4 CORE registry、OPEN/ASSIGN 分派、stopped、真实 producer 接纳账本、CORE_CLOSE | 不分配 exec/row_seq/input/out/对象版本；不将 CDC 入队当 D 接纳 |
| BUNDLE_OWNER/O | 唯一完成对象、实际 parent/plane_ref/version/commit 与最多4份生产 read loan记录 | byte permit、RAW CLOSE或 cal_done 不代该资格；实际目录映射 H-B02 |
| ROW_OWNER/FILL_OWNER | 5 RowCtx、2 input、row_seq/input gen、实际 WE覆盖/填料结账/输入返回 | 不按裸slot授权，不清未关引用；ASSIGN→RowCtx关联需持久保存 |
| FETCH/DDR_ADAPTER | 1物理 burst、历史 R_ROUTE、ID/RESP/LAST/范围、真实效果与复制转移 | 不授全plane loan，不用旧master末W/末R代关闭；H-B01/03 |
| RENDER/OUT_OWNER | 旧输入读取、单renderer、3 out grant目录及原KEY164关联，真完成后发布ROW | 不以 reservation授READY；不让取消撤ROW held |
| D/SCAN | 原四ctx、独立STOP、真实ROW接纳与银行/扫描/pixel/serializer关闭 | 不据 CORE值相等推效果，不等待不存在的APPLIED |

分支汇合：REGISTER与STOP独立；FETCH退出、input归还、out退休、loan归还、物理退休分别推进；已移交的复制值由其新bank/ctx引用负责。慢通知只阻该槽复用，不阻后端停止与关闭。整体检查点：上述边界已形成，本卡 D/E 继续细化；服务/目录/真实IP/资源仍 OPEN，不进入实现。

## D. 字段、编码与逐连接检查

全 unsigned，字段高到低。core 本域 posedge 沿前 valid&&ready 且非rst为 fire；跨域另区分源实际传输、目的完整接纳与真实业务提交。request/reply/sideband held 后不改。SCAN_KEY256、CTX840、ROW_KEY164、RowCtx865、ROW_TARGET472沿 A 来源，不裸cast不同64bithandle。

### D1. 新 typed 消息（候选无实现体）

| IF/方向 | 明确字段与 body 位数 |
|---|---|
| IF01 V→CORE REGISTER906 | SCAN_CTX840／真实D_slot2／register_seq64；ACK914＝原906／status2／reason5／registered1 |
| IF02 CORE→O BULK_OPEN387 | SCAN_KEY256／parent_ref64／open_seq64／required_mask3；GRANT459＝原387／borrow64／status2／reason5／granted1 |
| IF03 CORE→ROW ROW_ASSIGN409 | SCAN_KEY256／borrow64／assign_seq64／source_y11／target_y11／required_mask3；ACK581＝原409／ROW_KEY164／status2／reason5／assigned1 |
| IF04 ROW→FETCH FETCH315 | ROW_KEY164／borrow64／fetch_seq64／plane2／row_byte_offset13／beat_count8 |
| IF04 FETCH→ROW BURST_TERM342 | 原315／accepted_beats8／decoded_words9／no_future_R1／RX_refs_closed1／decoder_refs_closed1／terminal_status2／reason5；ACK350＝原342／status2／reason5／stored1 |
| IF05 FILL_OWNER→CORE FILL_TERM323 | ROW_KEY164／fill_seq64／terminal_status2／reason5／facts7／burst_issued4／burst_settled4／raw_R9／good_R9／RGB_words9／EDGE_words7／ANN_words8／logical_WE10／lane_WE12／overflow9；ACK331＝原323／status2／reason5／stored1 |
| IF06 RENDER→OUT PRIVATE_OUT_RETURN545 | 原ROW_TARGET472／return_seq64／no_future_write1／native_pending_closed1／writer_refs_closed1／never_published1／request_reason5；ACK553＝原545／status2／reason5／returned1 |
| IF07 CORE→O BULK_CLOSE491 | SCAN_KEY256／borrow64／close_seq64／request_reason5／facts8／assigned_rows11／terminal_rows11／AR_issued14／AR_settled14／raw_R19／good_R19／overflow6；ACK499＝原491／status2／reason5／released1 |

valid/ready 不在 body。所有 seq 独立 namespace、唯一发起owner首1、扩65检查耗尽不回绕；新软件epoch不单端清旧债。ROW_OWNER保留独立row_seq64分配器；assign_seq64仅请求去重，五份有效RowCtx各追加64bit关联元数据，不能藏入原865body。每exec只按旧next_target_y11核下一目标，成功实际分配后计入assigned，BUSY不前进；1080是结束计数，不能作为合法坐标。

接纳 ACK status2：0 APPLIED、1 ALREADY、2 BUSY、3 REJECTED。精确同请求命中原completion窗口时重放原结果，不把原status0改成1；ALREADY仅新完整关闭请求遇已真实关闭的同一活动身份，仍须原目录证据。新 OPEN/ASSIGN/REGISTER 成功仅status0/reason0与其资格bit1；失败资格bit0、grant/ROW_KEY规范0。slot0及borrow/row_seq数值不能单独判断成功。终态status2：0 COMPLETE、1 FAILED_CLOSED、2 CANCELLED_CLOSED、3 QUARANTINED；FAILED/CANCELLED也必须真实关闭才带closed事实，Q不产生FULL/释放。

本族reason5：0 NONE、1 FIELD、2 STALE、3 BUSY、4 EXHAUSTED、5 CANCELLED、6 DEADLINE、7 CLOSING_BUSY、8 ROW_FAULT、9 SOURCE_FAULT、10 UNDERFLOW、11 CLOCK_FAULT、12 UNKNOWN_EFFECT、13 RESET、14 BAD_CERT、15 THIRD_BUNDLE、16 SESSION、17 BAD_ECHO、18 CAPACITY、19 STICKY_FAULT、20 LINK_INIT、21 NOT_FOUND、22 RANGE、23 COUNT、24 NOT_INITIALIZED、25 NOT_COMMITTED；26…31保留拒绝。它是本卡显式命名空间，映射其它族非同值cast；新reason22不同于SCAN的FUTURE_FULL，适配须按名称。

### D2. 登记、借用、赋行与范围

REGISTER 906选择减少重复137bit：V已真实核原979成功ACK的全文echo/status/prepared/parent/slot后才发布；CORE只接该唯一V，不把906用于替未知PREPARE grant消债。固定四个STOP mailbox按真实D slot路由（slot属于wrapper路由，不暗加到原262body）；早到STOP在原每ctx目的private槽保持完整KEY/sticky并立即阻该slot新业务，登记匹配后先绑定stop再回复。REGISTER RX/ACK独立于四STOP槽；不因未登记撤STOP或报告never_opened。

CORE slot不得因CORE_CLOSE已发送便重用。旧CORE报告实际正确ACK消费、其本地消息/producer/loan债已真实结束且不再借完整registry后，新REGISTER才可替换；唯一V的新成功PREPARE还必须建立在D原ctx已真实FREE的分配事实，故不能绕D的银行/扫描退休。stale STOP不得写新exec的stopped或清旧UNKNOWN。

BULK_OPEN核CTX、parent、完整bundle/source/J/result/profile/render绑定、全部借用平面immutable commit及初始化范围。OPEN的required_mask是整个exec访问的并集：mode0＝RGB+EDGE011，mode1/2＝001，mode3＝010，mode4＝011，mode5＝111；OPEN不含target_y，不能按首行mask001只借RGB后无权限读下半EDGE，也不能中途补开或替换原loan。每行ASSIGN的required_mask另外按历史PLAN派生：mode0目标0…539仅RGB001、540…1079仅EDGE010，source_y＝2×(target_y mod540)；其它mode每行mask等其OPEN并集且source_y＝target_y。show开关不减少任何一层required。O至少保留原OPEN387+borrow64=451bit/loan作为请求与归还的真实关联；plane ref/version/base/byte_capacity/commit、pin和父登记是另有实际目录内容，不能认为451已包含全目录。

ASSIGN核正确已知borrow、完整KEY及旧历史PLAN；目标、source_y及行mask必须精确等该PLAN的逐行映射，且行mask是原OPEN整exec并集的子集，不能强求mode0行mask等OPEN mask。ROW_OWNER唯一选真实FREE input及可用RowCtx，先真实占位后形成ACK；无第六ctx或第三input。失败不授任何out。FILL事务结束仅结束该assignment的填料，已经FULL的input、renderer/P或out继续独立占原RowCtx。

FETCH plane0RGB/1EDGE/2ANN，3非法。beat_count为实际1…128，另转AXI LEN=count−1；offset16B对齐，offset+16×count先14bit核RGB5760/EDGE240/ANN480B逻辑行范围，再从实际对象base、source_y与stride先33bit派生byte地址，核对象/guard、4KiB拆分与物理上界。caller不携带裸地址来授权限。行对应RGB360个128bitword、EDGE120/ANN240个16bitword；合法单burst decoded_words最大分别128/120/240，9bit足够。全WSTRB/RMW、初始化rounded span和writer排他仍按PB及真实DDR资格；此只读loan不授写。

### D3. 计数、FULL、私有返回与关闭

FILL facts7低到高：coverage_complete、no_future_AR、read_transactions_closed、RX_closed、decoder_closed、native_writes_closed、no_unknown。overflow9对应从burst_issued到lane_WE的九个计数。成功须其mode全部required真实逐地址覆盖、非required计0、所有facts1/overflow0及正确status0/reason0。mode5成功R405、RGB360/EDGE120/ANN240、logical_WE720、lane_WE2880；burst_issued=burst_settled但各行1…8实际计算，不能恒8。计数相等不能替代无洞覆盖；单plane按连续offset/beat/native地址前进，错误后禁止再造FULL。FAIL/CANCEL保留各口真实前缀、不能强令good_R=raw_R或逻辑WE=laneWE。

BURST_TERM只针对本请求；成功accepted_beats=beat_count、decoded_words为该plane实际WE数量、3proof1且无错。不等全行FULL、不证明whole-loan返回；末R后仍有RX/decoder引用时不得提前形成成功TERM或覆盖R_ROUTE。超额R/计数范围错立即故障/Q并禁止成功终态，计数不回绕；真实被接纳的合法前缀与额外响应故障分记，后续独立关闭证据不能把未知prefix补成正确数据。

PRIVATE_OUT_RETURN只允许原OUT_RESERVE真实成功对应的未发布bank。OUT_OWNER持久保存3×原KEY164与ROW_TARGET472的唯一关联，不能用已消费运输ACK当目录；四proof全1并与真实native/pipeline记录相符才returned1。ROW valid已形成就不能转此族；那时继续原ROW472/OWNED479/RELEASE480/ACK487。输入RETURN174/182候选kind选择0 CONSUMED、1 DISCARDED、2 Q，3非法，原字段宽不改；成功由其真实RE/pending/银行引用结束授予，Q不FREE。上述新增枚举须被ROW联合版本显式吸收，不能宣称旧稿已冻结。

BULK_CLOSE facts8低到高：new_proposals_closed、assignment_messages_closed、row_fill_producers_closed、AR_proposals_closed、read_transactions_closed、route_refs_closed、RX_decoder_writes_closed、no_unknown。这里row_fill_producers只指源读取/填料义务；已复制到银行的renderer和输出退休另层处理。assigned_rows与terminal_rows为同exec正确实际ASSIGN/FILL终结，AR/R计数是源/backend实际ledger，不是ROW数量。每exec每target只成功一次且错误后停新行，故rows≤1080、burst≤8640、mode5 R≤437400，分别11/14/19bit足够；overflow6逐字段冻结，溢出不饱和冒成功。

O核自己的grant、接纳/关闭截止、真实读effect与各引用后才能released1；caller facts全1或cal_done不自证。borrow未知不能发borrow0当有效loan关闭，失去正确OPEN回复须Q并保可能grant。SCAN CORE_CLOSE的never_opened仅由真实owner核无创建loan/无可能grant/无OPEN或后续业务义务提供；已发布OPEN未获明确无grant证据时不成立。已有明确拒绝但从未创建loan的最终编码须与SCAN D3措辞联合冻结，H-B02仍OPEN，不用borrow0偷填。

### D4. 有限运输、去重与容量

每新增族共享一份源held、目的private请求与反向相应held/private回复；单族最多一份未完成运输，4exec由有界dispatcher调度，不凭“每exec一事务”暗加四份运输。STOP四独立槽沿SCAN另计。ready只依空槽与会话准入，不能把已fire坏body当未接纳。业务判定下一旧资格沿后进行，不同沿穿透。

每族另保最后一份完整completion：会话合法后先查正在held/private或存活真实记录的原请求；精确同seq/全文重放原结果，同seq异body拒FIELD；新seq严格大于该族attempt高水位才新判定，成功/失败都更新并保存原完成；旧且不在有限窗口只STALE不复活。存活loan可由原OPEN+borrow重建成功GRANT；活动RowCtx须另存assign_seq关联，不能把它与row_seq合并。关闭成功不可逆：发布returned/released1前必须阻同沿新未知效果；发布后晚父/link故障归独立健康流程，不撤held成功ACK。完整last cache只复制值、不pin已退资源；cache命中不重新授读、不复活FREE代次。

本卡候选body下界：六基础族两端各一份为2×[(387+459)+(409+581)+(323+331)+(545+553)+(491+499)+(906+914)]=12796bit；四registry原906共3624、四loan原451共1804、三out原KEY关联492、五assign_seq关联320，列出19036bit。FETCH/TERM/ACK另2×(315+342+350)=2014，合21050；上述七组完整last cache另6398+1007=7405，合28455bit；既有5 RowCtx4325并列时32780bit。既有ROW本地3000、published ROW11508、SCAN30306/adapter638与input18/RX7/output15不在本新增下界，不重复同一实例。

该表是逻辑body容量，不是FF或整机fit。状态/valid/sequence分配器、高水位、计数、实际完整plane目录、R_ROUTE/holding、预约、generation、端口与CDC另计；源/目的放同clock或共享immutable记录若要省存储，必须证明新实际结构，不能无证扣2份。早到STOP若不沿原四private槽持久保存，须再加4×262=1048bit与valid；source登记本体不能替D侧CTX3360。新增seq分配器及存储映射 H-B03/04；服务不据上述顺序化自证通过。

## E. 中文操作草图

OP01 登记：V消费原成功ACK并核全echo→保parent执行pin→形成906 held；CORE先接空private，按完整历史与真实slot查登记→已有同KEY精确匹配重放，否则核旧本地closed→绑定CTX/slot/seq及该slot早到STOP→后续沿回复；stopped则不OPEN。STOP自己独立先接纳与sticky，不等数据/FILL/REGISTER ACK。

OP02 借用：PRODUCER只用旧registered且非stopped身份提出OPEN；O核同parent/bundle/全plane commit、两physical bundle与真实read loan槽→先登记原OPEN与对象pins→形成GRANT。正确reply消费后CORE登记borrow_known；同沿或此前stop不撤reply，后续只收尾归还；wrong echo保可能grant，不另开第二loan或声明never_opened。

OP03 分配填料：核旧next_target_y、正确loan与真实capacity→ASSIGN held→ROW_OWNER分配row_seq/input generation/RowCtx并保存assign关联→ACK真实消费→由该旧ctx派生合法FETCH。每burst预留整RX容量与旧route资格→保持AR→实际核R并入RX→下一沿RE capture→真实逐word WE→所有旧route引用移交后结BURST_TERM并返ACK→后续burst。不能等整行FULL才释放route。

OP04 全行终结：FILL_OWNER按实际覆盖/计数、末WE/所有read与decoder义务闭合形成不可变TERM；成功才FULL。CORE收到正确完整TERM后先记终态，后续ACK；对应事务结束后可申请下一target，但旧FULL bank/ctx仍占位。STOP后的late FULL也接纳并存真实完成事实，禁止开启新renderer，走未读INPUT_RETURN DISCARDED；失败已闭partial同样独立退input，unknown则Q不复用。

OP05 渲染归还：完整FULL且未stop→先OUT_RESERVE真grant→后INPUT READ真grant→按ROW的旧缓存/四级数学/5lane写。取消时已issued RE捕获，旧WE记真实前缀；只在无未来RE/银行引用后INPUT_RETURN，复制P/cache另持ctx。out未发布且四proof真则545私有退还；若已形成ROW valid，原文保持到D接纳/正确OWNED，再沿原RELEASE/ACK退休，不能撤valid制造“从未发布”。

OP06 关闭汇合：STOP先记本沿旧fire/WE/commit→下一状态禁新ordinary。兑现旧OPEN/ASSIGN/FETCH/FILL/out回复，独立关闭source读/fill/route，形成BULK_CLOSE并取得O真loan返回；不等out银行整体FREE。renderer私有义务与input_RETURN、未发布out_RETURN结束；已发布每ROW得到正确完整OWNED/接纳证明后，producer消息/ACK通路真空，CORE才冻结409。D独立核自己真实received数量与CORE producer_rows，并继续各bank及扫描/pixel/serializer关闭，完成原CLOSED→RETIRE→DISPOSE。

OP07 producer计数：CORE只有消费正确完整ROW对应的OWNED证明才将其target_y一次计入producer_rows；D按本域真实完整ROW接纳独立记rows_received。assign/FILL/JOIN/WE/core侧CDC入队不代它。每exec禁止重复target、按序发布，源最多3份实际out活动记录供去重；正确拒绝OWNED不计接纳、不解除已发布bank关闭债。CORE_CLOSE不等待已published bank整体FREE，但须所有held ROW及相关producer接纳ACK真空。关闭账本之外的银行RELEASE/ACK由独立bank-retirement层继续，不暗借已退休CORE registry。

OP08 reset/恢复：冷共同reset只在全参与者与外部effect正式作废条件下建新会话，RAM由valid/代次隔离；warm reset/失健康用独立STOP与上述真关闭，不单端清FIFO或seq。Q通知消费仍保loan/parent/ctx/unknown记录；原软件epoch/下级7owner ACK汇合与健康恢复schema仍H-B05，不造第8owner或用本卡ACK替全系统QUIET。

不变量：借用覆盖全实际范围；bank写/读不重叠；每REQ原体可定位真实owner；row_seq与assign_seq独立；源copy一旦转移银行不再借旧route；对外held不受当前UI或取消改体；计数不能代效应证书；所有成功归还承诺来自真实旧关闭状态。

## F. 语言与三份对应契约

本卡无 C++ 业务实现；数值参考角色仍独立完整图黄金，不接生产内存/DDR替身。C++实际标准/编译器、容器/所有权/错误与可执行模型需整包文件基线冻结，不以本文批准它。RTL拟SV2009与Ti60F225/I3/Efinity2026.1.132，尚无新compile支持证明。

| RTL A–L | 本卡合同/关键未决 |
|---|---|
| A数值 | D各unsigned宽度/合法编码，地址加法33、行范围14、seq扩65；无隐式截断/回绕，partial真实不补齐 |
| B时钟 | core沿前fire/沿后提交，RX/native下一沿capture；pair/pixel/serializer相位与外部byte clock H-B01/03 |
| C接受 | 源运输、目的完整接纳、业务目录提交、native WE、OWNED证据分别记；无ready摄像/固定scan期限另证明 |
| Dvalid | valid0不推进坐标/ledger；held明确定型，FILL失败不变FULL，新的body不穿透使用 |
| E反压 | singleton族真实空槽才ready，issued R先预留整burst；STOP独立每ctx槽，不等满数据FIFO |
| F延迟 | 无单一端到端固定周期承诺；沿后发布、下一旧沿接纳/判定；ROW条件e970不能代DDR/CDC服务 |
| G复位 | warm保旧义务/Q，冷共同隔离条件未冻结；原消息/目录/seq不得单端清空 |
| H配置 | 完整PLAN/CTX冻结，mask/颜色/源坐标由历史配置派生，同沿UI变化不替已登记版本 |
| I存储 | 4exec/5RowCtx/2input/3out/1renderer；缓存与body有界，实体目录/端口/native映射H-B02/04 |
| J身份 | target/source不同，mode0偶行重复；KEY全匹配、plane同bundle；exec不是physical frame |
| K CDC | 源fire不是D接纳，登记与4STOP独立，完整多位mailbox/复位/会话授权H-B03/05 |
| L实现 | 当前只有原参考综合证据；全机RAM/FF/DSP/clock/PNR/STA/bit未通过，本体下界不称fit |

共同数值契约为原RGB/EDGE/ANN bytes、mode数学与完整像素数量不改；硬件执行另核本卡登记/loan/真实R/native/消息/银行关闭；对应契约按完整epoch/parent/exec/RowCtx/target/source/plane/历史PLAN比较真实输出和独立黄金。DDR memory model只提供真实访问/故障，不计算算法、不以DUT日志制造GT。

## G. 实施与验证计划（全部 NOT_RUN）

实施次序：冻结H-B01…05和相关联合版本/manifest→指定版本与整包范围批准及治理前置→独立work生成schema/registry/bulk loan/row assignment/fetch/fill/return adapter→独立参考与真实模型/TB→局部/组合回归→完整Efinity综合/PT/PNR/route后STA/bit，登记后停止在软件边界。当前无这些文件或可执行测试。

| TEST | 覆盖/事件 | 期望与判断 | 方法/状态 |
|---|---|---|---|
| H-T01 | REQ01，STOP先于REGISTER、same-edge、旧slot新exec | 原private保stop，新register匹配后不OPEN；旧CORE消息未关不覆槽 | 将来独立协议TB，沿后核；未运行 |
| T02 | REQ02，late OPEN成功、BUSY、wrong echo、未知grant | 保存实际loan/pin并返还；未知不报never_opened、第三bundle拒 | 独立O目录参考；未运行 |
| T03 | REQ03，全1080目标/mode0上下边界、mask、assignseq≠rowseq | target0…1079一次、source mapping正确、capacity2/5真满不暗扩 | 将来字段及事件比对；未运行 |
| T04 | REQ04，全1080行跨4KiB/最多8burst及RGB首128拍 | 单burst退出后后续AR可推进，不等FULL；合法范围/WE/计数匹配独立bytes | 真实DDR模型与RAM模型；未运行 |
| T05 | REQ04/05，末R仍decoder持有、RX满、extraR/ID/RESP/LAST错 | 旧route不覆盖，完整closure前无成功TERM/FULL，unknown不假归还 | 将来故障注入；未运行 |
| T06 | REQ05，stop后late FULL/partial、OUT grant后input未grant取消 | 接纳原体，未读input独立返还，out私有RETURN不用不存在INPUT lease | 将来协议TB；未运行 |
| T07 | REQ05，ROW valid未fire时cancel、privateRETURN错误gen | 保原472族，不能“未published”退还；bad echo保bank | 将来各层ledger；未运行 |
| T08 | REQ06，loan已返而out仍读；producer入CDC但D未接纳 | loan按真源闭合返，CORE producer_rows不提早；D不以source count自证 | 跨域随机相位与停顿；未运行 |
| T09 | REQ06，held关闭/慢ACK、重复/STALE/seq耗尽、晚父故障 | 有限窗口原结果，cache不重授；成功ACK不撤，旧债不回绕/复生 | 将来固定种子及边界；未运行 |
| T10 | 全部，current/fallback/candidate竞争、首行期限/连续60Hz | 完整负载不欠载/溢出；safe/Q是真失败，不代正常通过 | 冻结服务曲线后真实整包仿真/资源/STA；未运行 |

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 拟文件/符号（未生成） | TEST/证据状态 |
|---|---|---|---|
| 01 SCAN提前exec与STOP | V/registry IF01，OP01 | production_exec_registry/register_adapter | T01/09；候选来源阅读 |
| 02 VIEW/RAW完整对象 | O IF02/07，OP02/06 | production_bulk_loan_owner/plane_scope_lookup | T02/08；真实目录未实现 |
| 03 ROW唯一bank/ctx | ROW_OWNER IF03/05，OP03/04 | production_row_assign/fill_ledger | T03/06；字段/有限计数设计 |
| 04 PB/native行搬运 | FETCH IF04/05，OP03/04 | production_fetch_router/row_rx_decoder | T04/05/10；真实IP效果资格未验证 |
| 05 ROW/PIO银行义务 | renderer/out IF06及原472，OP05 | production_private_out_return/row_retirement_adapter | T06/07/09；未实现 |
| 06 SCAN真正关闭 | CORE/O/D IF07/原409，OP06…08 | production_core_close/producer_ledger | T08/09/10；CDC/接纳证据未实现 |

反向各拟单元只支撑上述真实要求；既有数学模块不用新接口理由重写，实际代码/注释/测试位置待实施才登记。

## I. 未决门槛与审批

| ID | 当前影响/证据缺口与处理方法 |
|---|---|
| H-B01 | 真实DDR slave子集、连续R、B后可见性/旧effects结束、校准/健康、匹配器件模型与CSI key；实际adapter/IP验证设计负责。公开端口和旧map不能补证。 |
| B02 | O完整对象/plane scope与原RAW/VIEW唯一writer映射；REGISTER/ASSIGN/FILL/私有RETURN/CORE_CLOSE具体联合版本，明确拒OPEN无loan的终态、out关联/闭合目录及错误矩阵；整合owner负责。 |
| B03 | singleton族调度、所有native/R_ROUTE/holding具体结构、四域CDC/reset、camera/显示deadline与最坏公平服务；scheduler/PIO/DDR负责，不据顺序控制提高成功率而降负载。 |
| B04 | 上述body实际RAM/FF存放、7组cache、全部seq/ledger/allocator/ports/错误与全机资源及时序；预算仅下界，实际唯一实例表与映射仍需完成。 |
| B05 | 全局schema/目录/健康与epoch7owner ACK、文件/独立GT/场景共同baseline、成熟整包批准与DB治理前置；当前不创建work或写实现。 |

规范10.3：①B样例有内容；②C复用/责任有内容；③D给候选字段与相容检查但联合schema未冻结；④E中文局部/不变量有内容；⑤F语言/映射有内容且实际边界OPEN；⑥D/E/G有有限走查；⑦G/H有实施/测试/追踪；⑧无阻塞不满足；⑨本文保存/实际读回/呈现与限定独立审阅另记；⑩v0.1与范围/输入明确，实际实现基线未冻结。保持NOT_READY，不将源完整hash或agent自检当用户批准。

## J. 差异与恢复

本卡提出ROW的RP-B02/RP-B03、SCAN的SC-B01中的生产交接候选，不重定义840/865/472数学字段。显式增量：CORE登记906、最多4真实read loan、ASSIGN409、独立row_seq及5×64关联、FETCH315/TERM342、填料323、未发布out545、loan关闭491、INPUT_RETURN kind和独立producer真实接纳账本。它们尚未被旧来源吸收，不能直接接线或称完整全局门槛已关闭。

REGISTER减少重复原ACK字段是基于V唯一真实成功核验与D保ctx的责任选择；ASSIGN不采用caller seq作为row_seq，保持ROW_OWNER唯一分配。若换全ACK复制、并发度、bank数、目录或消息body、冷reset/状态枚举/作用范围，需要版本修订、实际review与指定批准。恢复先查A字节、原审批、差异与报告真实阅读范围，不沿用未批准稿执行。

初稿888987F0EC9E75CB931E06D21BFD216C90265991F640589566F8CDB54AFC391F／33063B已保存在[mode0借用范围澄清前快照](design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001-v0.1-before-mode0-scope.md)。root与独立有限数值/协议阅读发现同一反例：若OPEN将首行001当整exec权限，目标540的EDGE读取没有授权。本修订区分OPEN整exec并集011与ASSIGN逐行001/010；消息body、容量和其它关闭选择不变。实际审阅输入及最后限定复核另存报告，不将旧hash审阅冒称覆盖全部新稿。

## K. 本轮实际记录

当前只有只读来源、字段/容量算术和本候选文档；保存后root实际读回及独立review绑定其真实hash。没有业务RTL/C++、功能脚本/参考程序/TB、工程/约束/IP修改、新工具构建/仿真/综合/布局布线/STA/bit、安装/网络、数据库/正式状态或硬件动作。完整十一项及五类工作未完成。

## L. 阅读与交付

先整合完整目标→本B/C整体→D登记/对象资格/行字段/有限容量→E1…8实际交接及停止→F三份契约→G/H验证追踪→I真实缺口。FULL只为输入完整，ROW valid只为已发布输出银行，OWNED为D接纳证据，APPLIED为真物理采用，RETURN只结束其各自lease。实际代码一致性、功能验收、整包工具验证与用户理解验收均待执行；本卡不代它们。
