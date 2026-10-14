# TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001：EXEC 只读整 burst 权限快照

2026-10-05，v0.1；依据 [PLAN_TEMPLATE](PLAN_TEMPLATE.md)及[工程根 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本卡仅提出具名候选 **EBP-v1**，不修改已存在的 DIR、RAW、SC、METADATA、PB、HANDOFF、CONTROL、DRB、R1 或已绑定交付入口。它既不是现有权限合同已支持长 burst 的证明，也不是全机资源/显示 deadline 已通过的声明。

- Goal：将生产 kind2 EXEC_PLANE_LOAN 的完整身份与 immutable READ 权限建立一次真实快照，普通 DDR burst 使用新的完整范围许可，减少逐次冷目录全文查验；保留原借用、真实行、旧请求、物理路由、关闭和归还义务。
- Current state：DIR D3 每次普通访问先 pin 全文、再实际 holder 全文及 phase；PB 允许 128 个 16B beat，而 RAW AP466 的 length7 仅 1…64B，SC LOOKUP 的 byte_len7 不能表示 2048B。EXEC 是真实四 context×三 plane 的十二只读 pin 条件额度，尚无本文新接口或工具证据。
- Target state：仅 kind2 普通 READ 改由一次完整建立的 EBP 快照和唯一 long-span lookup sequencer；请求保留完整 KEY/borrow/行/FETCH 身份，响应保留完整 ref/version/grant 和 33bit 半开 end。其它 kind/WRITE/RMW 沿原合同。
- Gap：真实捕获来源与冻结协议、可信 FETCH 发布桥、长许可到 PB R_ROUTE、mutation fence、跨 owner 关闭和 100MHz 联合最坏服务未闭合，见 A3。
- Assumptions：保持 1920×1080、全 Canny/复杂识别要求、现有板载 DDR、原显示模式和稳定显示目标；不预设算法 FPS。只选一套共享 EBP 单元，不为每个 actor 复制引擎。真实 descriptor/源历史必须满足实际 layout 和格式，静态 JSON 自身无运行权限。
- Open questions：A3 列出有限五项，不把未知资源或时延填成零；不能因为这些项尚未完成便声称全机不可能。
- Dependencies：本文 A2 的真实来源、DIR O 唯一写者、CONTROL registry/loan owner、ROW_OWNER、FETCH owner、唯一 PB 路由和 RX、原关闭/恢复 owner；没有新增硬件依赖。
- Milestones：M1 本纯设计保存读回；M2 联合五项闭合并核原接口 delta；M3 达到指定 READY 后明确版本/范围/基线审批；M4 才生成业务实现/测试并实际验证。当前只到 M1。
- Detailed steps：先 B 看整体，再 C/D 看 owner 与接线，再 E 看逐沿、冷体/热表和服务，最后 F/G/H/I 看语言、场景、追踪和门槛。
- State transitions：FREE→BINDING→ACTIVE→FENCING→CLOSING→RETURNED_METADATA→FREE；未知入 Q。旧 published/accepted 工作在其旧权限和 ledger 下履约，不能用 state 更新撤掉旧 fire。
- Artifacts and hashes：新增本文件；来源实读范围/hash 在 A2。自己的最终 hash 交接时由真实文件读回产生，不在自身正文预写自引用 hash。
- Validation：本轮只做文本/字段/位宽/几何/事件次序核查；G 的功能和工具场景均 NOT_RUN。
- Failure handling：明确拒绝无普通访问；已建的部分 pin/旧 request/unknown effect 独立保留关闭；Q 不通过 cache miss、timeout 或冷体稳定伪造归还。
- Human approval gates：没有 EBP 业务实现批准；原 R1 批准只覆盖 R1。当前 NOT_READY，不请求用户批准未闭合版本，不登记 Manifest/数据库审批。
- Rollback：只删除尚未引用的新候选文档可以撤销候选；实际实现后的回退需另有授权/冻结和真实债务闭合。原计划、R1 与正式状态本轮全不变。
- Completion criteria：本轮是新候选完整保存/全文读回/来源未改；业务完成另需五项闭合、批准、实际功能/综合/PNR/时序/产物验收，未达到。

## A. 状态、范围与真实来源

### A1. 阅读入口与批准边界

任务 ID 如标题，关联生产 O 目录→D0 registry/loan→ROW/FETCH→PB READ→HANDOFF CLOSE。EBP-v1 是新接口/权限实现替换候选：**明确覆盖 DIR v0.1 D3 中 kind2 的普通 immutable READ 全文查验路径**，并不覆盖建立、变更、关闭、RETURN、metadata retirement，也不覆盖 kind3 算法 SC、kind7 独立 REPLAY、CAMERA、COPY 或其它 holder。旧 DIR D3 仍为生效候选合同；本卡不会自动改变它。新实现须与 DIR/PB/HANDOFF/CONTROL 的实际联合版本一起冻结。可独立继续的工作是纯设计交叉审阅；现在不启动后续业务代码、功能模型、脚本、TB、构建、网络、数据库或实体动作。

### A2. 有限实读与输入 SHA256

行号仅辅助，schema/稳定符号优先。下表“本轮”是实际读到的范围，不冒称把所有旧稿全文重读。SC、METADATA 曾在其创建任务全文读回，本轮只重新核 hash；不将其摘要当 EXEC 新权限来源。

| 代号/相对 planning 路径 | 实际读范围 | SHA256 |
|---|---|---|
| DIR / design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md | 本轮 L102–141，D3/D5、holder、pin/descriptor、来源和提交 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| PB / design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md | 本轮 L70–92，128beat/4KiB/R_ROUTE/RX/行几何 | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 |
| HANDOFF / design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md | 前一设计任务 L69–112 实读，本轮接口关键字段实际搜索读回/核 hash | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 |
| CTRL / design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md | 前一设计任务 L60–95 实读，本轮核 hash | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 |
| SCAN / design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md | 前一设计任务 L67–132 实读，本轮核 hash | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 |
| REPLAY / design-TRACK4-ALGORITHM-REPLAY-001.md | 本轮 L87–105 完整实读及相关字段实际搜索 | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B |
| RAW / design-TRACK4-ALGORITHM-RAW-STORE-001.md | 本轮 L111–140/L168–174 完整实读，AP466/role/ref/pin/范围 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| DRB / design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md | 本轮 L150–195 完整实读，单 MR/720/571/613/1481 | A2620B069928341CC316DFC7676902B394070D1B245A6C0FB9926F92F522996C |
| SC / design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md | 已交付时全文，本轮 hash；其 kind3/32entry 不被本文隐性扩展 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| MT / design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001.md | 已交付时全文，本轮 hash；ROW 冷存候选仍独立 | 6764FD3115B10BF63FECC289B590CFAE29A106FA7BC0640D4A0DB39A12CF339B |
| SLOT / ../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json | 本轮全文 11516B；固定 SRC/EDGE/ANN/arena，权限免责声明 | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 |

根规范 v0.2 SHA4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；模板 SHA99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。无 Git commit 证据，不造 commit。表中包含旧候选未批准输入，不等于本卡获得实施批准。

### A3. 有限阻塞清单

| OPEN | 具体缺口、影响与证据 | 联合解决方法/owner |
|---|---|---|
| EBC-B01 | 完整 CTX/J/OPEN/borrow 实际来源、pin/descriptor/source/cert 的一致捕获及所有 mutation fence 尚未联合冻结；影响 REQ01/02、IF01 | O+CONTROL+RESULT/SOURCE owner 给逐字段真实来源、保护 lease、部分 grant 清理和建立时序；实际 kind2→role7 bridge 逐连接核 |
| EBC-B02 | 原 FETCH 发布时 caprevision 固定、可信 RGR 与旧发布白名单、STOP/更新/重复关闭的真实 wiring 尚未冻结；影响 REQ03/06、IF02/03/05 | ROW/FETCH owner 与 O 联合核原 held/fire/TERM/MR ledger，不能接受 caller 自报 old-held |
| EBC-B03 | 新 2048B 许可至真实 PB R_ROUTE/RX 的 adapter、PERMIT_CLOSE 实际事实/异常多 R 和终端义务尚未闭合；影响 REQ04/05/06、IF04/05 | PB/PHY owner 冻结新许可族、来源 bridge、计数/关闭证据，绝不 cast AP466/SC 长度或用 caller 证书 |
| EBC-B04 | 热字段唯一实例、综合 mux/宽乘法、原 transport 重叠与 100MHz 单 ROW/CONTROL/ring/QoS 最坏服务未实证；影响 REQ07、E6 | 全机 ledger owner 与 DRB 联合排程，保留带宽、最大间隙/metadata/DDR 延迟；综合/STA 后才能称装得下/快 |
| EBC-B05 | warm reset/跨域未知效果隔离、epoch 持久唯一性与老 wire/RETURNED_METADATA 完整排空桥尚未冻结；影响 REQ06/08、IF05 | CONTROL 恢复 owner 保真实 QUIET 与后续 R/Q，不能 reset 清空 table 作为返还证据 |

这五项只列实际联合缺口；本卡不是先把全机成功当前提再无限扩卡。正常 range/geometry 可纯设计核，但全机 service 与实际授予链未闭合使 NOT_READY。

## B. 整体行为与稳定需求

| REQ | 规则与边界来源 |
|---|---|
| REQ01 | 四真实 EXEC context，每个最多 RGB/SRC、EDGE、ANN 三实际只读 pin；完整 CTX840/J657/OPEN387/borrow64 建立一次，不能用 operation/plan/source ID 非零测试替代真实有效性。来源 SCAN/HANDOFF/DIR |
| REQ02 | 仅真实 COMMITTED、immutable、完整初始化/格式/同源/版本/token、实际 active READ grant、正确 holder/phase 的 plane 可快照；cold 稳定和 pin 计数不是权限证明。DIR D3/D5/RAW |
| REQ03 | 普通请求必须完整匹配 KEY、borrow、caprevision、真实 ROWKEY/坐标/requiredmask/FETCH_seq；新内部 family 支持 1…128beat=16…2048B，原短许可不扩权。HANDOFF/PB/RAW |
| REQ04 | 所有 span 半开、运算先扩位，无 4KiB 跨界/plane 越界/未初始化尾/padding；同一 readonly 许可精确覆盖所请求 physical READ，不授权 WRITE/RMW。PB/DIR/SLOT |
| REQ05 | 一共享 lookup sequencer、一 outstanding EXEC permit、一实际 PB 物理 route；先真正保存 destination route 和完整 RX 容量，再 AR published/accepted；真实全部 R/decoder/route/close 后退休，最后 R 不释放。PB |
| REQ06 | STOP、cancel、更新同沿先记真实旧 fire/effects，再禁新发布；所有旧 held/accepted 继续用旧资格完成。先 quiet→permit close→pin RETURN/ACK，再形成依赖这些事实的 loan CLOSE_ACK；metadata 另后退。HANDOFF/DIR |
| REQ07 | 给出独立冷 RAM/热字段/真实口数和时延；现有十二 pin 额度不重复增加，原 held/private 不因 cold copy 删除；只声明条件尺度，不宣称 deadline 或总 FF/RAM fit。DRB/CTRL |
| REQ08 | Q/returned metadata 原槽占额度，miss/期限/无响应不证明归还；新 epoch 必须真实旧 wire/跨域 future effects/运输空且序号不复用。DIR/SCAN/RAW |

正常样例：mode5、algorithm2 的已核 PLAN、J 与 source/result 完整绑定，三个真实 immutable plane，O 成功原 OPEN 后快照 ready；ROW_OWNER 真 ASSIGN y34，选用真实 y34 的 RGB 分段和 EDGE/ANN 小 burst，可合计八 burst。每段得到唯一新 permit，保存 PB route 后真实发 AR，真实 R、解码、PERMIT_CLOSE、原 TERM/ACK 逐一完成，再 FILL 成功。八个段不是八个任意 actor 并行授权。

边界样例：2048B 是半页大小，起点 page offset0 或2048且end≤逻辑尾时允许；起点 offset2049不对齐、起点2064配2048B跨4KiB均拒绝且无 AR。plane3、mode5/非 RC、borrow0、rev错、wrong ROWKEY、已 FILL FULL 后新 FETCH、held旧 caprev 没有真实发布白名单都拒绝；合法旧 FETCH 在 STOP 后仍由原承诺完成。job96 可为0；实际非零 generation/borrow/ref/grant 与 job/operation 首0合法分开，不用0当所有字段的“空”。

配置采用原完整 PLAN/CTX 的冻结版本；UI latest、当前 config、源捕获轮转不会重写这份已借用 immutable plane。取消/失败可以结束新生产但不能改已发响应 body、AR 承诺或计数。未知 R、错误 RLAST、额外 beat、bad close 进入保留债务 Q；没有算法数值输出修改、显示质量或帧率降低副作用。

## C. owner、数据路径和必要单元

普通文字路径：真实 D0 registry/loan＋O SOURCE/RESULT/descriptor/pin → **IF01 EBP_BIND** → EB_CTX0/full headers/十二 plane；ROW_OWNER 真实 ASSIGN/RowCtx865 → **IF02 RGR**；原 held FETCH315 由唯一可信 FETCH bridge → **IF03 EB_REQ662** → 共享 lookup → **IF04 EB_RSP1012** → 唯一 PHY route/private＋PB RX → DDR AR/R → decoder/原 HANDOFF TERM；PHY 实际 ledger → **IF05 PERMIT_CLOSE167/ACK176** → O scope quiet → 原 pin RETURN/loan CLOSE_ACK → 原 metadata 退休。

| MOD | 职责/owner、输入输出及划界 |
|---|---|
| EB-BIND | O 唯一 writer；实际完整建立及核源、descriptor/pin/初始化/commit，保部分安装和 source lease；写 EB_CTX0/headers/cap；不创建第二套 source/history 真相 |
| EB-COLD | 一个 native RAM，O admin 独占建立/审计读写；保完整历史到真退役。普通稳定 lookup 不读冷体；其副本不替代 D0 registry/loan 和 O actual RESULT |
| EB-RGR | ROW_OWNER 原 ASSIGN/FILL/retire 的可信镜像，五个 slot 与原 RowCtx 同寿命；只阻止非法行使用，不替代原行 buffer owner、输出 bank/ROW quiet |
| EB-LOOKUP | 一个 O-core sequencer，查完整热 KEY/borrow/revision/row 和实际 plane 快照、形成精确 readonly span；不盲收 caller 地址/ref、自报 phase 或 old-held |
| EB-FETCH-BRIDGE | 原唯一 FETCH owner 保原315 expected，发布时冻结 caprevision；保存旧 published 白名单，并将新响应与原请求完整对应；不删除原 MR FETCH/TERM/ACK cache |
| EB-ROUTE-BRIDGE | PHY/PB 唯一实际 destination private permit/route；先保 route/RX，再发合法 physical READ；不使 CAMERA/COPY/algo 获得 EBP 写权限，不替代原 QoS arbiter |
| EB-FENCE | O actual mutation/STOP owner；阻新发布、履约旧请求、等 local access/physical permit 静止、按原实际 pin 归还；原 CLOSE 和跨域 metadata 后退各自有 owner |

全部是拟实现符号，当前无实现。热比较器/冷搬运器只有各一实例，不给四 EXEC 各配宽 assembly。原 CONTROL 的 CMD966/IMAGE966 源 held 与目的 private、原 OPEN/GRANT/FETCH/TERM/CLOSE 两端槽、RowCtx865、PB R_ROUTE/RX 等均继续存在；本卡没有免费删除任何一端。原 accepted CLOSE 不能等待它依赖的整体 metadata RETIRE；IF05 独立应答/容量，不能以新 FETCH 信用作为关闭回复接收条件。

## D. 接口与组合检查

### D1. 保留的原 family、身份与建立来源

保留 HANDOFF 原 REGISTER906/ACK914、OPEN387/GRANT459、ASSIGN409/ACK581、FETCH315、TERM342/ACK350、FILL323/ACK331、BULK_CLOSE491/ACK499。不扩展/重编码其端口，不能把新 suffix status2/reason6 cast 旧 status2/reason5。原 OPEN387=SCANKEY256/parent_ref64/open_seq64/required_mask3；GRANT459=echo387/borrow64/status2/reason5/granted1。它的真实 O loan451=完整 OPEN387＋borrow64，而不是 registry906、CTX840 或 J657 本身。

KEY256=epoch32/plan64/display64/exec64/link32；CTX840=PLAN616/parent_ref64/link32/exec64/target_frame64；J657 全文由 O 实际 RESULT/J 历史取，不从 PLAN.job96 反推。PLAN616 原 job96/source_image_id64/result_id64/render_generation64/display_id64/plan_id64/W11/H11/algorithm2/profile_ref64/render112；job96 内低位 epoch32/frame32/config32，不当作 epoch32+job64。原真实 holder_link160=kind4/index6/generation64/epoch32/zero54；kind2 的 generation 使用实际非零 borrow，index 指实际 O loan slot，不能默认等于 D 注册 slot。pin role 候选明确映射 **kind2→RAW role7 REPLAY/access0 READ**；这个 typed adapter 仍须 B01 合并，不是同宽 H160 就合法。

IF01 建立是 O 内部受保护过程，不另造一份免费外部大 BIND message：原 OPEN fire 锁真 expected，O 配实际 borrow 和需要的真实 typed READ grants；保存真实 CTX/J/OPEN/borrow 后写 context，逐词核读，完整资格和各 true pin 安装成功才发布 EBP ACTIVE，再使原成功 GRANT459 可见。此前 ordinary FETCH 不准用。部分 ACQUIRE 成功、下一 plane 失败时，installed mask 保留各真实 tuple；未知进 Q，known failure 只有已实际清理所有部分 pin 且可证明未开放 ordinary access 才回原无-grant拒绝。没有第二次 ACQUIRE “安装 cache”。source lease/CTRL registry protection 到 clone/check 完成才返；其 held/private/保护状态尚需 B01 逐字段接线。

完整 qualification 至少含：真实 holder/epoch/full CTX 与 J/source/result/profile/cert 一致；source origin/lease 真实对应；descriptor 与 pin 全 ref/version/grant/READ/holder/access/active/borrow 相同；immutable COMMITTED、非零真实 commit、无 writer/dirty/未结发布效果、item_capacity=valid_count=N=2073600、initialized_prefix 连续覆盖完整逻辑 byte 容量、SRC24/EDGE1/ANN2 canonical 格式、所有真正依赖的证书完成。全量 source/current lease 归属由实际 O 保存；冷副本稳定不保证后续 pin 仍 active，mutation 必须经过 E5。

### D2. 新接口 schema

均 unsigned；字段表按**从高位到低位**顺序，最后列字段处最低位，组合子结构保留原内部布局。valid/ready 单独，rst 下 fire=0；body published 后直到真实 fire 全文稳定。不同 family 即使同宽也不 blindcast。内部 operation/序号0可合法，borrow/ref/grant/permit/caprevision非零且由指定唯一 owner 分配；明确 absent plane 不是“看到0就猜没授予”。

| IF / body | 字段、方向、前提和结果 |
|---|---|
| IF02 RGR_CTRL257 / RGR_ACK266 | trusted ROW→O：原行身份255=ROWKEY164/O_exec_slot2/borrow64/source_y11/target_y11/row_required3，后接 op2。op0 REGISTER/1 FILL_END/2 RETIRE/3 Q；reply=echo257/status2/reason6/applied1。真实原 ASSIGN/RowCtx/旧 FILL/retire 事实认证，非 caller 自报op权限；单expected，两端源held/目的private各保请求及回复 |
| IF03 EB_REQ662 | trusted FETCH→O：KEY256/borrow64/caprevision64/ROWKEY164/fetch_seq64/plane2/source_y11/target_y11/row_required3/row_byte_offset13/beat_count8/operation2。operation0 READ_BURST，1…3拒绝；plane0 SRC/1 EDGE/2 ANN，3拒绝；beat实际1…128，不是 AXI LEN |
| IF04 EB_RSP1012 | O→trusted FETCH/PHY bridge：echo662/actual_ref64/version64/grant64/permit64/address32/end33/byte_length12/beat_count8/status2/reason6/granted1。成功 status0/reason0/granted1，全实际 tuple/permit非零，length=16×beat；known拒绝 status1/合法非0/granted0，其余结果字段0；BUSY2/合法非0/granted0只证明此次没创建许可；Q3/合法非0/granted0保相关旧ledger，不证明旧pin已返 |
| IF05 PERMIT_CLOSE167 / ACK176 | PHY→O：permit64/borrow64/facts8/raw_R9/forwarded_bytes12/overflow2/status2/reason6；reply=echo167/status2/reason6/closed1。真实源 facts 与原保留完整 EB_RSP1012 的 full KEY/ref/tuple/span 对照，不准只匹配数字permit后接受不可信ledger；请求/回复源held、目的private各独立一槽 |

reason6 新族：0NONE，1IDENTITY，2STATE，3PLANE，4ROW，5RANGE，6ALIGN，7PAGE，8EXHAUST，9BUSY，10STOP，11PIN，12IMMUTABLE，13UNKNOWN，14CLOCK，15LAYOUT，16SOURCE；17…63保留非法，不成为允许的模糊失败。新RGR/close ACK亦用status0成功且reason0/applied或closed1；status1明确拒绝/合法非0/相应bit0，2BUSY/非0/bit0，3Q/非0/bit0，不以busy或Q证明旧账释放。原 public HANDOFF reason5 通过具名语义映射，未知或不可表示错误进入实际 Q/first error，禁止截低5bit。

IF05 facts 从低到高八位分别 ar_published/ar_accepted/no_future_AR/R_channel_closed/RX_closed/decoder_closed/route_closed/no_unknown。正常成功只在真实已接受 beat数对应 byte_length、实际 R 全部收结、无未来R/AR/decoder ref、无 overflow/unknown，status0/reason0/相应facts成立；“never issued”必须实际 ar_published=0/ar_accepted=0/no_future_AR=1且没有旧 held AR，而非 raw_R=0 推测。额外 R 可触发9bit计数/overflow；不能将多R截成128后自证成功。forwarded_bytes12 合法0…2048，包含2048；RX等待/decoder输出 pending 不因为收到 RLAST 自动0。

### D3. 普通许可是新完整范围，不是旧短许可扩权

RAW AR348/AP466 保原 address26、byte_length7=1…64B、record访问及 actor授权；SC LOOKUP 长度7/其 kind3 保原合同。EB_REQ662/EB_RSP1012 为独立内部 family，允许的是实际 **16…2048B aligned READ burst**，address32/end33完整；不复用其长度字段、不把 beat_count 的8bit当 length7、不把 permit64 相同命名当协议兼容。前置验证从原 full holder/pin/type/control/history 来源一次捕获；普通 e0–e6 只覆盖 kind2、当前真实不可变权限和 row guard。

FETCH bridge 保完整旧 FETCH315 expected。仅由真实 source publication 事件冻结 caprevision，取得实际 bound KEY/ROWKEY/borrow/坐标；source payload不提供自授权 address/ref/grant，也不能自报 held=1 来绕 STOP。PHY 取完整新许可并创建自己的 held/private route，完整 body 为1012bit，加 valid为1013；O 回复可复用存储不能当 destination 永远可借的记录。PB ARLEN8 最后由合法实际 count1…128 减1产生；ARID0/SIZE4/BURST01及其余 PB规范不变。新许可只读，不产生 W/WSTRB、journal postimage 或共享 mutable RMW资格。

逐连接未闭合的具体 delta：D0 registry的保护/读取→O fullctx；O真实J/SOURCE/cert→clone；旧 kind2 phase/pin mutation→EB fence；ROW真实ASSIGN/FILL/retire→RGR；旧FETCH发布→caprevision白名单；EB许可→PB route完整范围；真实PHYclose→Oscope债；scopequiet/RETURN→旧loanCLOSEACK。单独拿冷副本稳定或“pin不会改”不能省其中任何接线。原 standaloneREPLAY619/888、原 SOURCE/CLASS/G typed provider等不被这条桥暗中改写。

## E. 局部状态、中文操作草图与实际成本

### E1. 唯一冷体、native RAM 几何和建立

具名 **EB_CTX1948=完整CTX840/J657/原OPEN387/真实borrow64**；不放普通 lookup current值，不删原 ctx/history。**EB_CTX0 一个 native20×512 RAM10**，core 同域1W1R、OUTPUT_REG0候选；O admin 唯一读写，未批准/未推断。四 context每份98词=1960bits，实际body1948，末词低8bit有效/高12bit零。base词0/98/196/294，end词97/195/293/391；392…511的120词/2400bits未分配，不隐性另放 transport。四份 body7792bit、native已用7840bit、padding48；可寻址10240bit、nominalRAM10240bit。word_index7合法0…97，nativeaddr9；slot2只指四context缓存映射，真实Oloan_slot另经完整KEY关联。

中文建立：e0旧 OPEN fire 留 expected及部分pinledger；后续在实际 source/control/result owner保护下把完整来源搬入唯一 **1960bit assembly**，高12zero。不给四个context各配assembly，也不用没有lease的最近一次CTRL readimage。O顺序98次WE，各沿写完整20bit，未用词不当有效；之后顺序98次RE/capture逐词对 still-held immutable assembly 比较，不额外造第二份1960bitreadback。任何同址读写结果不用；admin序列互斥，普通hit不占cold读口。原 source保护/valid必须持续到核读与fullqual完成，不因为第一次wordfire便退。

在所有 context词、真实资格和plane热表都写完/verified后，最后单独提交 context_valid及ACTIVE屏障，再从原owner发布成功GRANT；这不是多RAM/原真实pin同一沿原子提交。地址/runtime历史/原输入 source held/private都是独立预算；clone应在B01列出真实读取owner与保护事件，不能以本文assembly替代它们。invalid/context_valid0的cold stale bytes无需reset全RAM清零，但不能被公开lookup当真实holder。

### E2. 十二 plane快照、四 header和五行guard

| 位置与数量 | 单条字段、初值、更新与理由 | 实际 selected bits |
|---|---|---|
| O core plane[4][3] | 328=ref64/version64/grant64/commit64/base32/byte_capacity29/record_bits10/snapshot_valid1；实际 source/ref版本分别保存，slot不是权限；未grant valid0；只有fullqual捕获/安全fence更新 | 3936 |
| O core header[4] | 395=fullKEY256/borrow64/caprevision64/state3/global_required3/mode3/stopped1/context_valid1；FREE全valid0，不清唯一分配器 | 1580 |
| O core masks | installed12/return_requested12/returned12/pin_metadata_retired12；相互独立，cachevalid0不等于returned | 48 |
| O core RGR[5] | 259=ROWKEY164/Oexec_slot2/borrow64/source_y11/target_y11/row_required3/state3/valid1；对同一原RowCtx生存期唯一镜像 | 1295 |
| O core唯一序号owner | caprevision_next64/exhausted1及permit_next64/exhausted1；各独立非零generation，耗尽停新授予，不回绕，最大合法只发一次 | 130 |

header state3明确0FREE/1BINDING/2ACTIVE/3FENCING/4CLOSING/5RETURNED_METADATA/6Q，7非法。FENCING保原caprevision/tuple及真实row lease直至旧published/accepted工作闭合；CLOSING只在普通accessquiet后进入，不残留尚未接纳的合法白名单请求。Q禁止新授予，旧已经承诺的输出/效果保真实账，不以Q自动取消它们。plane valid从actualREADgrant/fullqualification建立，actualcommit必须保持真实token，never-granted只有原模式/真实mask和实际未授予ledger确定，不能从ref0单独解释。固定logicalbytes SRC6220800、EDGE259200、ANN518400；record24/1/2和stride5760/240/480，item数2073600。capacity29必须至少logicalbytes但授权范围以完整逻辑尾及真实initialized end裁切，padding不因capacity较大自动授权。SRC source历史与 RESULT J绑定贯穿引用；其它reader计数变动无需修改 immutable字节几何，但匹配本grant的 active/holder/phase改变必须 E5 fence。

RGR状态0FREE/1ASSIGNED/2FILLING/3FULL/4CLOSING/5RETURNED_METADATA/6Q、7非法；普通新FETCH只ASSIGNED/FILLING。原RowCtx865仍真实拥有输入bank/已绑定输出bank/reader/writer/held/retire，不新增五个row资源。mode0目标dy0…539读SRC sy=2dy/mask001，dy540…1079读EDGE sy=2(dy−540)/mask010；mode1/2SRC001，mode3EDGE010，mode4SRC+EDGE011，mode5三plane111且algorithm2。dy/sy0…1079完整11bit。原SHOW开关不减少已冻结requiredmask，mode6诊断/mode7非法不接生产PLAN。

RGR REGISTER须真实原ASSIGN fire及RowCtx权属/完整ROWKEY一致后才valid；同沿原FILL事务需按旧状态计真实fire，下一状态FULL禁后续新fetch，但以前源held/accepted必须履约。RETIRE先核原RowCtx真实reuse条件与新lookup/permit/FETCHmetadata空，才能valid0；RGR miss不能减少任何pin。control reply和REQUEST保持到各自truefire；RETURNED_METADATA/Q既占原row额度又占header/plane额度，不借valid0偷偷复用slot。

### E3. readonly range、half-open和4KiB

真正授权由实际 selectedplane base、logicalbyteend、initializedprefix及request给出的已核 source_y/offset/count计算；request不传address。SLOT当前SRC六slot从0按8388608递增；EDGE三slot从50331648按262144递增；ANN三slot从51118080按524288递增，所有实际候选base 4KiB对齐。布局文件明确只有候选固定range、没有runtime权限；bind时实际descriptor必须逐项匹配本族slot/ref/size/格式，否则rejectLAYOUT，不能仅因为地址看起来合理授权。

先核offset13非负、16B倍数，beat_count8在1…128；先扩位计算len12=count×16，合法16…2048。offset+len至少14bit比较≤实际stride；source_y×stride乘法保完整结果，至少24bit容纳当前frame，统一零扩到32bit后与base做33bit加法，再与offset相加，carry/overflow拒绝，不能先收窄到32再检查。最终[a32,e33)⊆[base32,base32+logicalbytes)且≤实际initialized_prefixend/authorizedobjectend；e33不窄化，2^32边界仅在实际object/物理窗口允许时可数学表示，当前生产根本不授权该边界。

当前候选生产arena[0,134217728)及物理DDR[0,268435456)双核；不能沿旧RAW[65536,67108864)限制或只保26bit，否则合法SRC0/高位生产对象会错误/别名。byteaddress32足够当前DDR但由实际映射证明不是caller假设。页内偏移先13bit扩展：address低12bit＋len12≤4096；禁止先截12bit后判跨界。req精确128beat若跨4KiB必须拒绝，FETCH owner按真实PB分段发不同完整请求/FSEQ，不用旧一个request假装全部完成。

固定1080p每个plane行长及完整帧尾均16B对齐，因此本文普通burst请求=physicalalignedspan，**rounded授权范围与请求精确相同，没有新增尾padding读取**。不以physicalslot较大把tail/guard拿来填128beat；末burst不足128则用实际count。未来非alignedwidth/plane尾拒绝本族，若需roundup访问必须另设计真实已初始化roundedregion及对象边界，不能借冷hold稳定批准pad。recordbits10只24/1/2本族，通用512bittypedrecords以及PROFILE独立128B实体不进EBP。

PB单行mode5 RGB5760+EDGE240+ANN480=6480B/405beats。actual4Kbase时RGB最多4burst、EDGE最多2、ANN最多2，共最多8；y34/187/750真实达到8，row0只有5。若base不4K、源format/stride变化，不套8上界，当前bind拒绝LAYOUT而不是悄悄扩大次数/权限。row0不能拿来代表最坏服务。

### E4. 唯一 ordinary lookup逐沿草图

EB_FETCH_BRIDGE保原FETCH315与真实sourcepublished事件；一个全局白名单 **FETCH315+old_caprevision64+valid1=380bit**，只有已存在真实原held请求才能入。不是四个免费pending队列，也不是caller old_held位。原 FETCH bridge depth1/globalPB route约束仍需B02确认，不暗开四个burst并行。lookup唯一请求662+valid1、O回复1012+valid1、PHY destination route1012+valid1各实际独立；回复就算O已fire目的private仍保全，不能偷共存储。

| 沿/阶段 | 以沿前旧状态计算、提交与可见性 |
|---|---|
| e0 ACCEPT | 当真实valid&&capacityready且非rst fire锁完整REQ；新请求只ACTIVE/不stopped，旧published由真实白名单/相同旧revision批准进入；同步STOP仍先计旧fire，再记禁新标志 |
| e1 IDENTITY | 完整KEY/borrow/caprevision/contextvalid/实际slot关联与RGR全文/coords/mask匹配；新请求须ACTIVE及RGR ASSIGNED/FILLING；真实旧发布白名单在FENCING仍按其保留原grant/row lease履约，不以RGR后来FULL/CLOSING状态拒掉旧承诺。Q不新授予，既有承诺另依实际失败/债务路径闭合；lookup miss明确拒绝，不执行pin减账 |
| e2 PLANE | 选唯一合法plane及完整actualtuple/commit/base/capacity/record；READ only、requiredbit、stableimmutable资格和真实fence epoch完整，不能只看cachevalid |
| e3 SPAN | 先宽算rowaddress/offset/length/end；不得先形成AXI窄值再查；锁oldplane数值保护至permit完结 |
| e4 RESERVE | 查页/物理/初始化/逻辑尾，实际无旧permit/route冲突、generation可用；分配一次非零permit，保真实metadata；忙则明确无新许可BUSY/或合法held等待，不能重复分配 |
| e5 PUBLISH | 形成完整1012回复，suffix合法且实际data完整后才valid；新valid在沿后可见。旧reply不等相邻plane/当前UI，没有被STOP撤掉 |
| e6 最早交付 | 下游此前已有capacityready时真实RSPfire；PHY再保存自己的route/private和完整RX预留后才允许ARpublished，此沿不是DDR传输完成 |

无stall时从e0到最早sourceRSPfire六个clock interval；一级不是0拍函数调用。reply stall冻结全body/valid；已有单permit直到真实IF05metadata排空不能接受第二个成功许可，即使reply已消费，也不是每拍一个成功burst。cold/adminwrite/mutation不能改变这次锁定plane；真正更新需先e5/fence闭合。lookup断言失败形成明确拒绝或Q，绝不通过len0/beat0空许可“成功”。新generation最大值发一次再exhausted，新permit在分配/成功发布前失败不让已对外同编号复用；Q也占该编号和slot。

### E5. mutation、quiet、RETURN与metadata退役

所有影响本grant合法性的DIR更新必须进入EB_FENCE：ref/version/grant/READ资格/holder/borrow/epoch/active、immutable/commit/初始化/布局、holderphase迁移和源授权撤销；不是只有执行器本地cacheinvalidate。O停止**新发布**，保已有white-list和已经fire_REQ旧资格/actualtuple，旧RSP/AR held/accepted/已收R/decoder effect真实履约完。不能通过ready0取消上游旧held；cancel与AR/R/TERM同沿先记旧fire，next-state停止新创建，后续关闭核真实旧ledger。

子scopequiet：真实新REQ门关闭、白名单/expected/heldREQ/RSP/PHYpermit/AR/R/RX/decoder/route引用已完成或合法neverissued实际证明，IF05正确ACK消费且关闭transport旧空，才LOCAL_ACCESS_QUIET。原成功TERM342仍需它的trueaccepted/decoded/facts和ACK350；新permitclose不等整个行FULL或loan退休，以免循环。原MR58词FETCH/TERM/ACK cache事务并未省略；scope可以已物理关闭但原终态metadata尚未退休，这时全holder还不能FREE。

然后O依原完整 pin tuple（ref/version/grant/holder/access/borrow/epoch）真实RETURN一次，保存真实returned及ACK/metadata；多个plane各自ledger，部分返回不等于全十二。**pin RETURN/正确ACK先于依赖pins_closed的原BULK_CLOSE_ACK499**；不得让RETURN等待这个ACK或等待wholecontextmetadataRETIRE。CLOSE_ACK还需原491关闭事实、全部assignedrows/terminal/actualAR/R/overflow/refclosed真实证据，caller八facts不自证，bad echo不返别人的pin。

全scope pinreturned后header可RETURNED_METADATA，但完整ctx/hottuple/loan/原CLOSEexpected及heldACK保留到原owner消费并实际排空相关RETURN/IF05/FETCH/TERM/CLOSE/control读图/运输、实际跨域futureeffectsquiet；之后原loan/registryRETIRE和contextmetadata释放按原owners事件完成，最后FREE。coldmiss、rowmiss、stalevalid0、lastR、timeout均不能替代。Q保持installed/returnedmask、body/context/generation/partialgrants，不发成功ACK也不重用oldref。新的slot若旧metadata还活不分配；一当前/未来/旧closing四EXEC占额度规则保持SCAN原文。

对oldscope复活/权限刷新，须旧普通accessquiet＋真实DIR重新fullvalidate＋新caprevision，在新的contextvalid屏障发布；不能只在cache改ref就解释旧request为新权限。immutablebytes不支持runtimeWRITE，把WRITE→READ的算法提交重建留原kind3合同，不借EB来授权。

### E6. 真实内存、热字段与服务尺度

原DIR pin512四16×512 RAM串行32词；descriptor640四20×512串行32词；kind2实际loan451在D0需ceil451/20=23词。因此原每普通burst **至少32+32+23=87次冷读发射**，pin→holder→phase顺序及源/CERT/registry额外工作未省；八burst至少696次readissue，100MHz即6.96μs的issue尺度。不能把87当包括所有source/phase的总回复上界；registry906本身46词不是与loan451可互换的全文holder。

建立k≤3真实plane：对应pin+descriptor至少64k次RE发射，加真实CTRL registry46/loan23、DIR SOURCE_ORIGIN每源26词、RESULT1879每份94词等**实际所需且有保护的**来源链；不是固定把这些各读一次就证明fullJ/provider都齐。四cold写392WE及核读392RE，nativeRE延迟/capture另计。各真实ACQUIRE/RETURN/descriptor/pin写回本来存在，cachecapture不再增加一次ACQUIRE；本文没有用0拍fullvalidate或假多读口覆盖建立延迟。实际clone服务上界属B01/B04，不把coldwrite98当完整OPEN延迟。

| EBP所选新热位置 | bits（逻辑body/valid，不是实测FF） |
|---|---:|
| 十二plane328、四header395、五RGR259 | 3936+1580+1295=6811 |
| 四pinmasks、两个64bitallocator+exhausted | 48+130=178 |
| 单adminassembly1960+一个readword20 | 1980 |
| 单REQ662+valid、O RSP1012+valid、PHY route1012+valid | 663+1013+1013=2689 |
| PERMIT_CLOSE/ACK两端独立held/private | 2×(167+176)+4valid=690 |
| RGR_CTRL/ACK两端独立held/private | 2×(257+266)+4valid=1050 |
| sequencer/count/status选择 | wordcounter7/nativeaddr9/slot2/phase5/op3/pending1/busy1/assemblyvalid2=30 |
| 唯一真实旧publishedFETCH白名单 | 315+64+1=380 |
| **selected总量** | **13808bit** |

这个13,808是明确选择的热字段，不包括原CTRL源CMD/IMAGE保持、actualpin/descriptor维护的expected/修改图、source保护/资格fact/controlerror、PB原R_ROUTE/RX计数、原GRANT/TERM/CLOSE输运、复制/CDC/Q ledger等；没有测试/综合证明FF数，也没有保证与现63191body可以简单相加或相减。cold1RAM是新成本，不以原D0/目录RAM闲词免费解释。十二pin是原四EXEC×三plane已有条件额度，**不再加十二pin**；全局61/62/63或64是否装下仍需独立整个holder/pinledger证明，本文不确认。

已列全机175RAM候选如果仅吸收本卡则176，另联合MT的2RAM则178；SC CACHE-RAM独立候选、其它尚未列状态不得隐性加入或扣除。256总RAM减候选只作预算参数，没给完整RAM/FF/LUT/DSP/时序/portmapping前不称fit；两层热mux/widecarry/fullKEY比较的100MHz时序亦NOT_RUN。EBroute1012与原PBfullroute可能部分重复，需完整唯一实例ledger核后才能扣；当前先保两份来源private，不能为了资源好看删sourceholding。

DRB现单行fill串行模型：有真实g_R≤1与streaming decoder条件时数据write720，MR原八burst关联571，合1291；100MHz G0行deadline1481留190用于μ_FILL＋J_DDR＋J_META。若把42额外retire词放同一路径，MR613留148。原cold每burst87都落criticalpath的条件下，720+571+696=1987>1481，差506，尚未计其它；它说明这项重复查验值得替换，**不是全机无条件不可实现证明**。

新lookup e0–e6六interval只是最快合法source交付，八次48的纯尺度，在上述同路假设下余142（或含42余100）；**不能把48自动写成μ_FILL上界**。真实新PERMIT_CLOSE/ACK、RGR控、oldFETCH bridge/sourcelease/mutation、PHYroute/actualAR/R/decoderstall、pinreturn/metadata竞争都计入联合最坏值。给有条件式 L_perm≤6+W_EBP_arb+W_RGR+W_rsp，其中三W必须真实有界；没证据不得写0。完整burst还需Amax＋各R间隙上界＋decoder/refclose＋close/term/MR服务，只有满足实际可证明bounds才可谈100MHz deadline。

单ROW未FULL前不能开始该ROWrenderer970；不同真实bank的跨ROW流水、两input/三output和warmup严格沿PB/DRB，不虚构sameROW并行抵消这些周期。原CONTROL只有一个MR，FETCH58/TERM/ACK coldcache和OPEN/ASSIGN/FILL/RETIRE保持原词数；新EBcold admin、ROW mirror/MT、COPY/ring/CAMERA/算法对真实DDR和metadataQoS竞争都留reservation/fairshare/最大间隙要求。EBP仅加速凭证查验，不增加DDR带宽、inputbank、RX、ring容量或clock。持续显示的真实服务界仍EBC-B04 OPEN。

## F. 语言、位宽与跨域契约

本卡纯文档无C++程序；未来独立参考应是身份/权限/事件与整数范围模型，不是替FPGA执行识别的PC结果。C++标准/工具待批准实现范围核实际版本，不能提前写模型源码。所有字段unsigned，算前扩位；无定点舍入/允许误差，许可、echo、数量、地址必须逐位准确。

| RTL §8.2 | 明确规则/未闭合 |
|---|---|
| A 数值 | len12可2048，count8可128，end33保half-open，offset+len≥14bit/page和13bit，source_y×stride保完整≥24bit再扩32/33；ref/grant/borrow/rev/commit均64，不截低index授权 |
| B 时钟/观察 | EBP/coreadmin/RGR同生产core候选100MHz上升沿；沿前valid&&ready为fire，沿后newvalid最早下沿消费；PB真实PHY域/原clockbound属B05，不能凭corecounter观察异步facts |
| C 接受/交付 | 单REQ/独立RSP/单permit/独立controlclose，真实capacity；oldpublished不因STOP取消ready承诺，取消沿先计旧fire |
| D valid/推进 | nofire不推进count/generation；valid0不表示0数据、不证明grant返回；snapshotvalid只qualification，四masks独立 |
| E 反压/保持 | 全KEY/ROW/地址/tuple/suffix稳至fire；source/目的private独立；永久外部stall无completion保证，不伪用有限timeout证明效果清零 |
| F 延迟/吞吐 | e0–e6最快六interval，stall条件式明确；一个outstandingpermit不得宣称1/cycle；cold98WE+98RE计native延迟，不是现实现测量 |
| G 复位 | 本地初次coldisolatedreset使valid0，不清RAM当授权；warmreset须保或隔离旧debt/Q；sharedclock/恢复owner未闭合，B05 |
| H 配置 | 绑定时完整PLAN/CTX/J冻结，同沿UI/config新值不改旧snapshot/许可；mutation先oldfire再FENCE，重新fullvalidate/newrev后可见 |
| I 存储 | EB_CTX0唯一20×512/1W1R/O独占、末词low8high12zero、spare不分配；同址readwrite不用；五RGR与原RowCtx生存期而非五额外rowbank |
| J 身份 | fullKEY256/ROWKEY164/FSEQ64/borrow/rev/全CTX/J；mode0偶行映射与mode5三plane准确，output/HANDOFF原数量和坐标不改 |
| K CDC | EBP热表不跨域裸读；PHYprivate/closed8事实经原受保护request/reply/真实QUIET桥传回；握手/同步/各域reset释放具体wiring B05 OPEN |
| L 实现 | Ti60F225/Efinity现机工具仅既有验证环境参考，本文不跑工具；1新RAM/selected13808不是packedFF，100MHz mux/addr/port STA及全机QoS OPEN |

三份跨语言契约：①共同数值参考接actual fullcontext/grant/row/ops，输出拒绝或精确READ span，范围/padding零误差；②硬件按fire、held、nativeRE/WE、oldstate、新提交屏障和effect真实事件执行，不用函数调用次序代替；③参考事务按完整KEY/ROW/FSEQ/permit/ref-version-grant匹配硬件实际source/destinationfire，关闭proof与真实ledger逐位比。resetinvalid只在可信isolatedstart或正式闭合后生效，不能将新epoch删除旧比较项。这些均待后续获批实施，不含当前测试脚本。

## G. 后续实施与验证计划（全部未运行）

拟增量：O actual mutation/bind接线→EBcold+热表/RGR→trustedFETCHbridge/长许可→PB readonlyroute/close→联合metadata/recovery→资源/100MHzservice。拟符号 EB_BIND、EB_CTX_STORE、EB_LOOKUP、EB_ROW_GUARD、EB_READ_ROUTE、EB_SCOPE_FENCE；具体业务文件清单/套件须联合READY时冻结，现在没有生成文件、源码、TB或构建。任何B01–B05或原完整审批边界缺口阻止受影响实现；R1源码/bit/交付不作为EB功能证据。

| TEST | REQ/接口/初始与事件 | 期望、独立来源及观察 | 执行前状态 |
|---|---|---|---|
| EBT01 | REQ01/02；四真context，完整CTX/J/OPEN/source/cert，十二truegrant及unrequiredplane | 新0job合法；wrongfullfield/ref/version/grant/role/epoch/borrow/commit逐个拒绝；逐源独立Oracle，不能仅重算cachevalid；只truegrant安装一次 | NOT_RUN |
| EBT02 | IF01/E1；部分SRCgrant成功、EDGE拒绝或unknown、clone第97word/pad错 | 无ordinary授权，partialmask保留，真RETURN后才无-grant拒绝；unknownQ保cold/tuple；末词高12必须0，98RE/WE真实事件 | NOT_RUN |
| EBT03 | REQ03/04；count0/1/127/128/129、offset/页界/33carry/arena上下界 | count1..128且alignedlogicalspan允许，2048不窄化，4KiB跨界/plane3/unknownrecord拒绝且AR0；独立大整数范围oracle | NOT_RUN |
| EBT04 | SRC/EDGE/ANN首尾、最后行/last16B、logical尾padding/guard | 真初始化末span允许；physicalslotpad/roundup超logical拒绝；不可变READ永无AW/W或journal写 | NOT_RUN |
| EBT05 | IF02/03；mode0两半偶行、mode1..5/SHOW变化、wrongrow/mask/execslot | full原ROWKEY/真实ASSIGN保证，0..1079完整；FULL后新拒绝、oldheld履约；独立原PLAN/ASSIGN ledger | NOT_RUN |
| EBT06 | e0REQ与STOP/mutation同沿，e5RSPheld及ARpublished/accepted同沿取消 | oldfire真实计一次，body全稳，realwhite-list授权旧request；伪calleroldheld/ref/REV不能绕门；新rev不得重解释旧请求 | NOT_RUN |
| EBT07 | PB RX不足/route忙/ARstall/consumerstall、badRID/RESP/RLAST/额外R | 没真RX/route不publishedAR；原R_ROUTERE/decoderref账真实，lastR不free；错误Q/no成功close，counter可128且overflow不截 | NOT_RUN |
| EBT08 | IF05正常/neverissued/heldAR0R/重复close/wrongpermitborrow | 只有实际无futureeffects才成功；heldAR不能cancel0R假闭合；close先于依赖routeclosed的TERM，终态reply源/目的分别保至fire | NOT_RUN |
| EBT09 | pinRETURN/ACK、loanCLOSE_ACK、returnedmetadata/Q槽满 | 原fulltuple正确只返一次，RETURN先于依赖pinsclosed的CLOSEACK；metadata后来实际空才reuse；miss不减账；四EXEC/十二pin不重复加额度 | NOT_RUN |
| EBT10 | cold同址/源lease晚返、admin/fullvalidate与普通lookup竞争、seq最大耗尽 | 无混epoch/body，最后state/valid提交后才grant；nativepadding0；唯一allocator无reuse，多actor无免费并行引擎 | NOT_RUN |
| EBT11 | warmreset/跨域oldR/term/returnmetadata/新epoch | 保Q和旧scope直到可信QUIET，trueCDCidentity一致；不resetclear证明归还，不用null/缺证据判闭合 | NOT_RUN |
| EBT12 | mode5 y34/187/750八burst与row0五burst，singleMR/ROW/renderer/ring/COPYcamera | actual最大间隙/μ/J/FIFO/QoS+resourceledger满足联合DRB才通过；fast6不是deadlineoracle，模拟actualstalls/G0/hot/cold争用 | NOT_RUN |

方法：先局部独立整数/ledger与held/cancel场景，再接口组合/原owner事实驱动，再实际综合/PNR/STA/nativeRAM/100MHzservice。场景文字不是可执行TB。功能检查观察上升沿前fire和沿后稳定，TB调度/seed/timeout需要在批准套件指定；无限外部stall、unknownfutureeffect不得用timeout当成功。资源/时序/硬件下载本轮未运行，实体步骤继续人工闸门。

## H. 双向追踪

| REQ/来源 | MOD、IF与不变量 | 拟代码单元（未生成） | TEST/期望来源 | 实际实现/证据 |
|---|---|---|---|---|
| 01 SCAN/HANDOFF完整ctx | EB-BIND/COLD，IF01/D1/E1，真实部分grant | EB_BIND/EB_CTX_STORE | 01/02/10，原field/owner | 未实现/文本核 |
| 02 DIR D3/D5/RAWrole | EB-BIND/FENCE，fullqual/实际mutation | EB_QUAL_CAPTURE/EB_SCOPE_FENCE | 01/06/09，actualpin/descledger | 未实现/文本核 |
| 03 HANDOFF/PB/短AP | EB-FETCH/RGR/LOOKUP，IF02/03/04新族 | EB_FETCH_BRIDGE/EB_ROW_GUARD/EB_LOOKUP | 03/05/06，原fullFETCH/ROW | 未实现/文本核 |
| 04 PB/SLOT | EB-LOOKUP，E3完整half-open/padding | EB_SPAN_CHECK | 03/04，独立宽整数layout | 未实现/文本核 |
| 05 PB真实route/RX | EB-ROUTE，IF04/05完整destinationprivate | EB_READ_ROUTE/EB_PERMIT_CLOSE | 07/08，actualAR/R/RXledger | 未实现/文本核 |
| 06 HANDOFF/DIRoldpromise | EB-FENCE，E5先RETURN后CLOSEACK/后metadata | EB_SCOPE_FENCE/EB_RETIRE | 06/08/09，真实旧fire/term | 未实现/文本核 |
| 07 DRB/CTRL | EB唯一实例/E6selected与conditionalbounds | EB_ADMIN_ARBITER/EB_SERVICE_AUDIT | 10/12，真实resource/service | 未实现/文本核 |
| 08 DIR/SCAN/RAW恢复 | CONTROL实际QUIET/EB-FENCE，F G/K | EB_RECOVERY_BRIDGE | 09/11，actual跨域quiet | 未实现/文本核 |

反向：所有拟符号均只对应表中已有明确需求，不引入算法/PC识别/新actor功能。新schema、row镜像和route持有是满足完整长范围权限/旧promise的必要增量，并未以热表节约为理由自行删原来源/关闭。代码/注释/模型/测试反向核尚不能进行，因为没有实现；本文静态selected字段不冒称代码trace覆盖。

## I. 门槛与呈现

①整体与正常/边界样例见B；②owner/复用与数据/关闭路径见C；③新旧接口/完整字段/逐连接见D且B01–B03未闭合；④中文逐沿/状态/存储/quiet见E；⑤位宽/语言/CDC见F；⑥场景及服务条件见B/E/G但actual联合deadline未证；⑦后续增量和双向追踪见G/H；⑧当前五项OPEN，未通过“无阻塞”；⑨本文件保存后需实际全文读回/真实hash交接，非独立审阅通过；⑩版本v0.1和只文档范围明确。当前 **NOT_READY**，没有READY时间或实现批准，不自动消耗原批准。本轮Root可纯设计独立复核；不开始业务实现。

## J. 变更、相容与恢复

旧DIR D3逐次pin全文→holder全文→phase的合同不动；本卡提出kind2 ordinaryREAD全量资格一次捕获/真实mutationfence替代，其中新length12/end33范围是明确behavior/interface delta，需联合指定版本覆盖。旧RAW1..64B、SC kind3/32cache、独立REPLAY、PB其它actor仍旧契约；stagecache33/H1、MT冷ROW等独立新候选不被吸收。若合并后修改descriptor/holder可变资格或原FIFO/QoS，必须回本卡对应REQ/IF/TEST/资源/草图重新核，不只换数字；已绑定R1交付保持只读。

恢复不得把readsnapshot从Q翻ACTIVE后继续旧permit；须实际旧AR/R/运输闭合、sourcepermission重新fullvalidate、独立新caprevision且旧编号不复用。冷clone失败不是业务partialgrant自动无效果；actualpartialpins按真实清理路径，输出明确失败/未完成/Q区别。正式状态/DB/Approval Manifest本轮不改。

## K. 实现与验证实录

本轮只新增本Markdown、只读来源及静态核；没有业务源/模型/功能script/TB/构建/综合/PNR/STA/bit/硬件动作。G全部NOT_RUN；nativeRAM/13,808body/八burst/6interval为设计分析，不当utilization或功能通过；R1实际成功无EBP覆盖。最终保存全文读回与来源hash不变由交接记录真实报告，仍需Root独立评审。

## L. 用户阅读和交付说明

阅读顺序：B整体为什么需要新长许可→C原来源/新共享单元→D完整身份与接口delta→E1/E2冷记录与真实十二pin→E3范围→E4普通逐沿→E5取消/归还→E6代价/服务→F/G/H。完整事务路径：actual OPEN/source/context/pin资格保存并核读→最后ACTIVE屏障/原GRANT成功→真实ROW/FETCH发布旧revision→六阶段最早新READ许可→PB独立route/RX真准备→actualAR/R/decoder→真实PERMIT_CLOSE→原TERM/ACK/FILL→accessquiet/实际pinRETURN→原loanCLOSEACK→transport跨域quiet及metadata后退。未来改需求以相应REQ→IF→草图→TEST→联合预算为入口，不能只补一个长度常数。

本卡已把具体方案、字段、几何、窗口、关闭次序和未知范围写清，但尚无全机实施批准/实际验证/理解验收；用户未实际作答不标“已理解”。本轮终点是文档可读回/可评审，后续成熟独立范围可依规范另冻结；本卡的OPEN不阻止与它隔离且已获批的现有范围继续验证。
