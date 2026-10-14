# TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001：EXEC 只读整 burst 权限快照 v0.2

2026-10-05，v0.2；依据 [PLAN_TEMPLATE](PLAN_TEMPLATE.md)及[工程根 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本卡保留具名候选 **EBP-v1**，吸收 **EBSF-INC-v0.1** 的 trusted O MUTATE_FENCE 与真实 FETCH PUB_COMMIT/旧 revision 交接设计；不修改已存在的 DIR、RAW、SC、METADATA、PB、HANDOFF、CONTROL、DRB、R1、R2 v1/48 输入或已绑定交付入口。它既不是现有权限合同已支持长 burst 的证明，也不是全机资源/显示 deadline 已通过的声明。上一轮纯候选审阅不是本 v0.2 的 PASS、READY 或实施批准。

- Goal：将生产 kind2 EXEC_PLANE_LOAN 的完整身份与 immutable READ 权限建立一次真实快照，普通 DDR burst 使用新的完整范围许可，减少逐次冷目录全文查验；保留原借用、真实行、旧请求、物理路由、关闭和归还义务。
- Current state：DIR D3 每次普通访问先 pin 全文、再实际 holder 全文及 phase；PB 允许 128 个 16B beat，而 RAW AP466 的 length7 仅 1…64B，SC LOOKUP 的 byte_len7 不能表示 2048B。EXEC 是真实四 context×三 plane 的十二只读 pin 条件额度，尚无本文新接口或工具证据。
- Target state：仅 kind2 普通 READ 改由一次完整建立的 EBP 快照和唯一 long-span lookup sequencer；请求保留完整 KEY/borrow/行/FETCH 身份，响应保留完整 ref/version/grant 和 33bit 半开 end。其它 kind/WRITE/RMW 沿原合同。
- Gap：本 v0.2 已给唯一真实 mutation 入口、PUB_COMMIT 原子冻结旧 FETCH/revision、STOP 同沿规则及分层关闭顺序；真实冷来源保护/读取与父回链、actual owner 接线、长许可到 PB R_ROUTE/关闭证据、完整资源/100MHz 最坏服务、warm/epoch 仍未联合闭合，见 A3。
- Assumptions：保持 1920×1080、全 Canny/复杂识别要求、现有板载 DDR、原显示模式和稳定显示目标；不预设算法 FPS。只选一套共享 EBP 单元，不为每个 actor 复制引擎。真实 descriptor/源历史必须满足实际 layout 和格式，静态 JSON 自身无运行权限。
- Open questions：A3 列出有限五项，不把未知资源或时延填成零；不能因为这些项尚未完成便声称全机不可能。
- Dependencies：本文 A2 的真实来源、DIR O 唯一写者、CONTROL registry/loan owner、ROW_OWNER、FETCH owner、唯一 PB 路由和 RX、原关闭/恢复 owner；没有新增硬件依赖。
- Milestones：M1 本纯设计保存读回；M2 联合五项闭合并核原接口 delta；M3 达到指定 READY 后明确版本/范围/基线审批；M4 才生成业务实现/测试并实际验证。当前只到 M1。
- Detailed steps：先 B 看整体，再 C/D 看 owner 与接线，再 E 看逐沿、冷体/热表和服务，最后 F/G/H/I 看语言、场景、追踪和门槛。
- State transitions：FREE→BINDING→ACTIVE→FENCING→CLOSING→RETURNED_METADATA→FREE；未知入 Q。旧 published/accepted 工作在其旧权限和 ledger 下履约，不能用 state 更新撤掉旧 fire。
- Artifacts and hashes：只修订本文件并保存 v0.1 精确原字节快照；来源、快照和被吸收报告实读范围/hash 在 A2/J。自己的最终 hash 交接时由真实文件读回产生，不在自身正文预写自引用 hash。
- Validation：本轮只做文本/字段/位宽/几何/事件次序核查；G 的功能和工具场景均 NOT_RUN。
- Failure handling：明确拒绝无普通访问；已建的部分 pin/旧 request/unknown effect 独立保留关闭；Q 不通过 cache miss、timeout 或冷体稳定伪造归还。
- Human approval gates：没有 EBP 业务实现批准；原 R1 批准只覆盖 R1。当前 NOT_READY，不请求用户批准未闭合版本，不登记 Manifest/数据库审批。
- Rollback：v0.1 原字节已只读保存在 J 的 before-source-fence 快照；撤回本纯设计修订应明确恢复该基线及引用，不删除历史。实际实现后的回退需另有授权/冻结和真实债务闭合。其它计划、R1/R2 与正式状态本轮全不变。
- Completion criteria：本轮是新候选完整保存/全文读回/来源未改；业务完成另需五项闭合、批准、实际功能/综合/PNR/时序/产物验收，未达到。

## A. 状态、范围与真实来源

### A1. 阅读入口与批准边界

任务 ID 如标题，关联生产 O 目录→D0 registry/loan→ROW/FETCH→PB READ→HANDOFF CLOSE。EBP-v1 是新接口/权限实现替换候选：**明确覆盖 DIR v0.1 D3 中 kind2 的普通 immutable READ 全文查验路径**，并不覆盖建立、变更、关闭、RETURN、metadata retirement，也不覆盖 kind3 算法 SC、kind7 独立 REPLAY、CAMERA、COPY 或其它 holder。旧 DIR D3 仍为生效候选合同；本卡不会自动改变它。新实现须与 DIR/PB/HANDOFF/CONTROL 的实际联合版本一起冻结。可独立继续的工作是纯设计交叉审阅；现在不启动后续业务代码、功能模型、脚本、TB、构建、网络、数据库或实体动作。

### A2. 有限实读与输入 SHA256

行号仅辅助，schema/稳定符号优先。下表分 v0.2 实际重读与被吸收报告中的上一轮实际全文，不冒称把所有旧稿在本次修订全文重读。SC、METADATA 只核来源 hash，其独立候选不作 EXEC 权限来源。当前 EXEC v0.1 原299行和审阅报告132行在修订前均实际全文读完；入口/config/prompt/config/state/ledger/DB/Manifest、WORKFLOW、唯一根规范919行和模板也实际读取，未改正式状态或审批。

| 代号/相对 planning 路径 | 实际读范围 | SHA256 |
|---|---|---|
| DIR / design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md | v0.2 重读 L102–160；上一轮报告实读全文231行，D3/D5/真实修改和RETURN | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| PB / design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md | v0.2 重读 L72–115；上一轮实读全文162行，实际 route/RX/健康/关闭 | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 |
| HANDOFF / design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md | v0.2 重读 L69–144；上一轮实读全文223行，FETCH/TERM/loan原真实owner | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 |
| CTRL / design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md | v0.2 重读 L58–114/L117–155；上一轮实读全文235行，fixed owner/冷记录/52词cache/RETIRE | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 |
| SCAN / design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md | 前一设计任务 L67–132 实读，本轮核 hash | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 |
| REPLAY / design-TRACK4-ALGORITHM-REPLAY-001.md | 前一设计任务 L87–105 实读及相关字段搜索；v0.2只核hash | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B |
| RAW / design-TRACK4-ALGORITHM-RAW-STORE-001.md | 前一设计任务 L111–140/L168–174 实读；上一轮review另核实际RETURN/RETIRE/health；v0.2只核hash | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| DRB / design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md | v0.2修订开始时实际读L150–196，分析绑定右列当时字节；52词cache/58最早job间隔/720/571/613/1481；交接前并行修订未吸收，见下文 | A2620B069928341CC316DFC7676902B394070D1B245A6C0FB9926F92F522996C |
| SC / design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md | 已交付时全文，本轮 hash；其 kind3/32entry 不被本文隐性扩展 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| MT / design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001.md | 已交付时全文，本轮 hash；ROW 冷存候选仍独立 | 6764FD3115B10BF63FECC289B590CFAE29A106FA7BC0640D4A0DB39A12CF339B |
| SLOT / ../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json | 前一设计任务全文11516B；v0.2只核hash；固定SRC/EDGE/ANN/arena不是权限 | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 |
| VIEW / design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md | 上一轮 L97–152 实读，J命名恢复/CERT真实来源/parent与关闭缺口；v0.2核hash，不把旧J packed待澄清藏掉 | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C |
| PS / design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md | 上一轮 L75–95 实读，REQ291/lease/PCTX/BIND真实转移；v0.2核hash | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 |
| EBSF评审 / ../experiments/track4_algorithms_20261004/03_review/exec-source-fence-design-review-v0.1.md | v0.2 实读全文132行/24264B；只审原EXEC v0.1，结论DESIGN_INCREMENT_PROPOSED/NOT_RUN，不是本新稿PASS | F49AE5379B16042FAEB9B6052DFCB6653A758B914E9EF5020E615B6DDFA24253 |
| 原EXEC快照 / design-TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001-v0.1-before-source-fence.md | 精确保存修订前299行/51018B；既有同名若内容不同停止、不覆盖 | 2FC82DB887BA972A45D5F39B613C42AF5892DECF53DB23E25086039F666031F1 |

根规范 v0.2 SHA4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；模板 SHA99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。无 Git commit 证据，不造 commit。表中包含旧候选未批准输入，不等于本卡获得实施批准。

交接前metadata/hash复核：上表除DRB外的来源、review/原快照、根规范/模板均与列值一致；DRB由并行文档任务改为353行/57418B/SHA256 `93C1E563F692A3C7E74020B436234B0481BD086CA4E9C6817849DED31A43A8B9`。本卡仍绑定实际读时A262…996C的有限服务分析，未全文读取或吸收并行新增物理工作量，不把它宣称为冻结新输入或新版PASS；后续联合冻结另核相应版本。这里只报告本次观察，不追逐该并行卡后续hash。

### A3. 有限阻塞清单

| OPEN | 具体缺口、影响与证据 | 联合解决方法/owner |
|---|---|---|
| EBC-B01 | v0.2已给IF06唯一mutation入口/影响范围原则；完整CTX/J/OPEN/borrow/source/cert的真实保护和一致捕获、CORE读取/回执、parent完整回链及J packed共同澄清仍未联合冻结；影响REQ01/02/09、IF01/06 | O+CONTROL+RESULT/SOURCE按D1真实来源表落实protect lease/固定owner端口/部分grant清理；核实际kind2→role7，不以beforeimage或20bit候选代完整源保护 |
| EBC-B02 | v0.2已给IF07 PUB_COMMIT旧revision原子登记与STOP同沿选择、pub_phase/旧held交接；可信RGR/ASSIGN/FILL、实际source wrapper/完成窗口/重复关闭接线及有限运输仍未联合冻结；影响REQ03/06/10、IF02/03/05/07 | ROW/FETCH与O依E4a/E5核实际publication/fire/TERM/52词cache和scope ledger，伪caller old-held不准入，不能凭设计表宣实际wiring完成 |
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
| REQ06 | STOP/cancel/更新同沿先记旧真实fire/effects，尚未published的新候选禁PUB_COMMIT；旧held/accepted保原身份履约或真实失败/Q。先physical permit close/ACK及accessquiet→pin RETURN/ACK→依赖pins_closed的loan CLOSE_ACK→metadata另后退，不把quiet设成它自己所需close的前置。HANDOFF/DIR/PB |
| REQ07 | 给出独立冷 RAM/热字段/真实口数和时延；现有十二 pin 额度不重复增加，原 held/private 不因 cold copy 删除；只声明条件尺度，不宣称 deadline 或总 FF/RAM fit。DRB/CTRL |
| REQ08 | Q/returned metadata 原槽占额度，miss/期限/无响应不证明归还；新 epoch 必须真实旧 wire/跨域 future effects/运输空且序号不复用。DIR/SCAN/RAW |
| REQ09（派生） | O唯一真实修改分支从已核原命令/完整beforeimage求mask12/cause4/pending1，实际权限相关mutation可见前先fence；放native短锁后收尾，不能caller自报holder/mask授权。正常immutable排他先禁止非法几何修改；其它reader计数/合法同leaseBIND不全撤。DIR/RAW/EBSF |
| REQ10（派生） | 可信原FETCH源PUB_COMMIT同沿存完整315＋沿前旧revision并沿后valid，原source fire/新REQ formed/fire各独立；pub_phase3显式跟踪旧promise到真实终态metadata，不以fire前ready0/valid0猜neverissued、不以cache重放授新AR。HANDOFF/CTRL/EBSF |

正常样例：mode5、algorithm2 的已核 PLAN、J 与 source/result 完整绑定，三个真实 immutable plane，O 成功原 OPEN 后快照 ready；ROW_OWNER 真 ASSIGN y34，选用真实 y34 的 RGB 分段和 EDGE/ANN 小 burst，可合计八 burst。每段得到唯一新 permit，保存 PB route 后真实发 AR，真实 R、解码、PERMIT_CLOSE、原 TERM/ACK 逐一完成，再 FILL 成功。八个段不是八个任意 actor 并行授权。

边界样例：2048B 是半页大小，起点 page offset0 或2048且end≤逻辑尾时允许；起点 offset2049不对齐、起点2064配2048B跨4KiB均拒绝且无 AR。plane3、mode5/非 RC、borrow0、rev错、wrong ROWKEY、已 FILL FULL 后新 FETCH、held旧 caprev 没有真实发布白名单都拒绝；合法旧 FETCH 在 STOP 后仍由原承诺完成。job96 可为0；实际非零 generation/borrow/ref/grant 与 job/operation 首0合法分开，不用0当所有字段的“空”。

配置采用原完整 PLAN/CTX 的冻结版本；UI latest、当前 config、源捕获轮转不会重写这份已借用 immutable plane。取消/失败可以结束新生产但不能改已发响应 body、AR 承诺或计数。未知 R、错误 RLAST、额外 beat、bad close 进入保留债务 Q；没有算法数值输出修改、显示质量或帧率降低副作用。

## C. owner、数据路径和必要单元

普通文字路径：真实 D0 registry/loan＋O SOURCE/RESULT/descriptor/pin → **IF01 EBP_BIND** → EB_CTX0/full headers/十二 plane；ROW_OWNER 真实 ASSIGN/RowCtx865 → **IF02 RGR**；原 held FETCH315 由唯一可信 FETCH bridge → **IF03 EB_REQ662** → 共享 lookup → **IF04 EB_RSP1012** → 唯一 PHY route/private＋PB RX → DDR AR/R → decoder/原 HANDOFF TERM；PHY 实际 ledger → **IF05 PERMIT_CLOSE167/ACK176** → O scope quiet → 原 pin RETURN/loan CLOSE_ACK → 原 metadata 退休。

v0.2控制连接：真实ROW/FETCH源候选→**本卡IF07 PUB_COMMIT**（315/旧rev先登记后沿后valid）→旧held/fire及IF03；真实O已核原command/beforeimage→**本卡IF06 MUTATE_FENCE**→目标门关闭/旧scope履约→IF05真physical close与accessquiet→真实RETURN/ACK→原loanCLOSEACK→后来metadata RETIRE。IF06/07是本卡内部事件编号，不与HANDOFF原IF06/07公共family互换。

| MOD | 职责/owner、输入输出及划界 |
|---|---|
| EB-BIND | O 唯一 writer；实际完整建立及核源、descriptor/pin/初始化/commit，保部分安装和 source lease；写 EB_CTX0/headers/cap；不创建第二套 source/history 真相 |
| EB-COLD | 一个 native RAM，O admin 独占建立/审计读写；保完整历史到真退役。普通稳定 lookup 不读冷体；其副本不替代 D0 registry/loan 和 O actual RESULT |
| EB-RGR | ROW_OWNER 原 ASSIGN/FILL/retire 的可信镜像，五个 slot 与原 RowCtx 同寿命；只阻止非法行使用，不替代原行 buffer owner、输出 bank/ROW quiet |
| EB-LOOKUP | 一个 O-core sequencer，查完整热 KEY/borrow/revision/row 和实际 plane 快照、形成精确 readonly span；不盲收 caller 地址/ref、自报 phase 或 old-held |
| EB-FETCH-BRIDGE | 固定实际ROW/FETCH源发布门拥有IF07与单pub_phase；PUB_COMMIT同时冻结原315/旧rev及沿后source valid，再由FETCH保真实expected。旧held不撤、dup重放不再授AR；不删除原52词cache或另加四队列 |
| EB-ROUTE-BRIDGE | PHY/PB 唯一实际 destination private permit/route；先保 route/RX，再发合法 physical READ；不使 CAMERA/COPY/algo 获得 EBP 写权限，不替代原 QoS arbiter |
| EB-FENCE/MUTATE-SEAM | O唯一metadata写入口，从真实已核原命令/beforeimage求影响mask/cause/pending，IF06先gate再合法mutation；独立health/STOP先sticky且保旧fire，放native短锁不持端口等DDR，physicalclose→RETURN→loanACK→metadata后退；不制造source授权或protectedDDR quiet |

全部是拟实现符号，当前无实现。热比较器/冷搬运器只有各一实例，不给四 EXEC 各配宽 assembly。原 CONTROL 的 CMD966/IMAGE966 源 held 与目的 private、原 OPEN/GRANT/FETCH/TERM/CLOSE 两端槽、RowCtx865、PB R_ROUTE/RX 等均继续存在；本卡没有免费删除任何一端。原 accepted CLOSE 不能等待它依赖的整体 metadata RETIRE；IF05 独立应答/容量，不能以新 FETCH 信用作为关闭回复接收条件。

## D. 接口与组合检查

### D1. 保留的原 family、身份与建立来源

保留 HANDOFF 原 REGISTER906/ACK914、OPEN387/GRANT459、ASSIGN409/ACK581、FETCH315、TERM342/ACK350、FILL323/ACK331、BULK_CLOSE491/ACK499。不扩展/重编码其端口，不能把新 suffix status2/reason6 cast 旧 status2/reason5。原 OPEN387=SCANKEY256/parent_ref64/open_seq64/required_mask3；GRANT459=echo387/borrow64/status2/reason5/granted1。它的真实 O loan451=完整 OPEN387＋borrow64，而不是 registry906、CTX840 或 J657 本身。

KEY256=epoch32/plan64/display64/exec64/link32；CTX840=PLAN616/parent_ref64/link32/exec64/target_frame64；J657 全文由 O 实际 RESULT/J 历史取，不从 PLAN.job96 反推。PLAN616 原 job96/source_image_id64/result_id64/render_generation64/display_id64/plan_id64/W11/H11/algorithm2/profile_ref64/render112；job96 内低位 epoch32/frame32/config32，不当作 epoch32+job64。原真实 holder_link160=kind4/index6/generation64/epoch32/zero54；kind2 的 generation 使用实际非零 borrow，index 指实际 O loan slot，不能默认等于 D 注册 slot。pin role 候选明确映射 **kind2→RAW role7 REPLAY/access0 READ**；这个 typed adapter 仍须 B01 合并，不是同宽 H160 就合法。

IF01 建立是 O 内部受保护过程，不另造一份免费外部大 BIND message：原 OPEN fire 锁真 expected，O 配实际 borrow 和需要的真实 typed READ grants；保存真实 CTX/J/OPEN/borrow 后写 context，逐词核读，完整资格和各 true pin 安装成功才发布 EBP ACTIVE，再使原成功 GRANT459 可见。此前 ordinary FETCH 不准用。部分 ACQUIRE 成功、下一 plane 失败时，installed mask 保留各真实 tuple；未知进 Q，known failure 只有已实际清理所有部分 pin 且可证明未开放 ordinary access 才回原无-grant拒绝。没有第二次 ACQUIRE “安装 cache”。source lease/CTRL registry protection 到 clone/check 完成才返；其 held/private/保护状态尚需 B01 逐字段接线。

完整 qualification 至少含：真实 holder/epoch/full CTX 与 J/source/result/profile/cert 一致；source origin/lease 真实对应；descriptor 与 pin 全 ref/version/grant/READ/holder/access/active/borrow 相同；immutable COMMITTED、非零真实 commit、无 writer/dirty/未结发布效果、item_capacity=valid_count=N=2073600、initialized_prefix 连续覆盖完整逻辑 byte 容量、SRC24/EDGE1/ANN2 canonical 格式、所有真正依赖的证书完成。全量 source/current lease 归属由实际 O 保存；冷副本稳定不保证后续 pin 仍 active，mutation 必须经过 E5。

v0.2实际cold来源表不是新的免费BIND大message；每项的真实owner必须持续保护到完整clone/check/fullqual结束，原native短锁与业务lease分离。若跨短读之间body换代或保护没有实际取得，不形成ACTIVE；plan.job96、sourceid非零或最近一次IMAGE不补来源。

| 真实来源／位置 | 完整字段与提交屏障 | 保护与当前缺口 |
|---|---|---|
| CORE registry906／CTRL D0 kind0，46词 | CTX840/D_slot2/register_seq64；CORE真46词record＋92词cache正确完成后才registered | 只能固定CORE源端口提供并保原exec/parent；O不自报owner=CORE。实际读取/protect请求回执B01 |
| O loan451／CTRL D0 kind1，23词 | 原OPEN387/真实borrow64，实际O loan slot与holder kind2/gen=borrow/epoch回链 | 来源O原created/pin/pending保持，D0valid0/cachemiss不证无loan，不能借registryslot猜Oslot |
| DIR SOURCE_ORIGIN512／M0，26词 | src_slot3/epoch32/source_id64/src_ref64/src_version64/CAPTURE_CTX283/purpose2；完整COPY写/返pin/SOURCE_REG最后state2 | 原创建身份不随后来J改，真实ORIGIN_STATE=REGISTERED及完整source匹配；provider封存/父保护仍由真实owner |
| DIR SRC_LEASE522／M0，27词 | 原REQ291/hold_ref64/current_owner2/JID96/bundle_slot2/pin_grant64/state3 | 固定原REQ/holdref/grant/role；currentowner/phase按真BIND更新，不旧522全snapshot判等；真实phase变化经IF06 |
| DIR RESULT_ASSOC1879／M1，94词 | J657/source_id64/SRC EDGE ANN RECORD四ref-version512/result64/CREDIT162/CERT352/PCTX65/state3 | 同历史J/source/result/profile/证书完整；CERT须原provider及私有退休事实，不以自报success位造授权 |
| 原parent/PROFILE/provider事实 | 完整PLAN字段命名恢复及真实parent登记、完整profile实体/封存、被依赖provider证据 | VIEW原J packed及parent完整保护/关闭桥、owner接口未联合冻结，B01仍OPEN；不从相同数字handle凑出处 |

对应原记录全文/padding、descriptor640、pin512和它们真实pending均有成本，assembly1960只保存EB_CTX，不取代来源private或保护状态。不能把SOURCE_ORIGIN26/RESULT94各读一次当作完整source链已证。

### D2. 新接口 schema

均 unsigned；字段表按**从高位到低位**顺序，最后列字段处最低位，组合子结构保留原内部布局。valid/ready 单独，rst 下 fire=0；body published 后直到真实 fire 全文稳定。不同 family 即使同宽也不 blindcast。内部 operation/序号0可合法，borrow/ref/grant/permit/caprevision非零且由指定唯一 owner 分配；明确 absent plane 不是“看到0就猜没授予”。

| IF / body | 字段、方向、前提和结果 |
|---|---|
| IF02 RGR_CTRL257 / RGR_ACK266 | trusted ROW→O：原行身份255=ROWKEY164/O_exec_slot2/borrow64/source_y11/target_y11/row_required3，后接 op2。op0 REGISTER/1 FILL_END/2 RETIRE/3 Q；reply=echo257/status2/reason6/applied1。真实原 ASSIGN/RowCtx/旧 FILL/retire 事实认证，非 caller 自报op权限；单expected，两端源held/目的private各保请求及回复 |
| IF03 EB_REQ662 | trusted FETCH→O：KEY256/borrow64/caprevision64/ROWKEY164/fetch_seq64/plane2/source_y11/target_y11/row_required3/row_byte_offset13/beat_count8/operation2。operation0 READ_BURST，1…3拒绝；plane0 SRC/1 EDGE/2 ANN，3拒绝；beat实际1…128，不是 AXI LEN |
| IF04 EB_RSP1012 | O→trusted FETCH/PHY bridge：echo662/actual_ref64/version64/grant64/permit64/address32/end33/byte_length12/beat_count8/status2/reason6/granted1。成功 status0/reason0/granted1，全实际 tuple/permit非零，length=16×beat；known拒绝 status1/合法非0/granted0，其余结果字段0；BUSY2/合法非0/granted0只证明此次没创建许可；Q3/合法非0/granted0保相关旧ledger，不证明旧pin已返 |
| IF05 PERMIT_CLOSE167 / ACK176 | PHY→O：permit64/borrow64/facts8/raw_R9/forwarded_bytes12/overflow2/status2/reason6；reply=echo167/status2/reason6/closed1。真实源 facts 与原保留完整 EB_RSP1012 的 full KEY/ref/tuple/span 对照，不准只匹配数字permit后接受不可信ledger；请求/回复源held、目的private各独立一槽 |
| IF06 MUTATE_FENCE（内部事件，非公共packed family） | O唯一已核真实command/beforeimage→EB-FENCE：pending1/target_plane_mask12/cause4，共17selected位；完整command/pin512/descriptor640/loan451仍在原真实owner容器。mask bit=3×exec_cache_slot+plane，仅关联位置；由完整旧tuple/holder/source/parent求，不收caller holder_id/mask自授权。mutation可见前按E5先gate、放短锁、旧scope关闭；unknown不推mask0 |
| IF07 PUB_COMMIT（内部事件，原FETCH315端口不扩） | 固定实际ROW/FETCH源发布门：同沿存完整315/沿前caprevision64/valid1=380白名单，沿后原source valid可见；单pub_phase3按E4a跟踪交接。原完整RowCtx/RGR/loan/KEY提供真实coords/mask/归属，不由caller选epoch/old-held；source反压保持完整旧体/旧rev；新候选遇同沿STOP/fence/FULL不提交 |

reason6 新族：0NONE，1IDENTITY，2STATE，3PLANE，4ROW，5RANGE，6ALIGN，7PAGE，8EXHAUST，9BUSY，10STOP，11PIN，12IMMUTABLE，13UNKNOWN，14CLOCK，15LAYOUT，16SOURCE；17…63保留非法，不成为允许的模糊失败。新RGR/close ACK亦用status0成功且reason0/applied或closed1；status1明确拒绝/合法非0/相应bit0，2BUSY/非0/bit0，3Q/非0/bit0，不以busy或Q证明旧账释放。原 public HANDOFF reason5 通过具名语义映射，未知或不可表示错误进入实际 Q/first error，禁止截低5bit。

IF05 facts 从低到高八位分别 ar_published/ar_accepted/no_future_AR/R_channel_closed/RX_closed/decoder_closed/route_closed/no_unknown。正常成功只在真实已接受 beat数对应 byte_length、实际 R 全部收结、无未来R/AR/decoder ref、无 overflow/unknown，status0/reason0/相应facts成立；“never issued”必须实际 ar_published=0/ar_accepted=0/no_future_AR=1且没有旧 held AR，而非 raw_R=0 推测。额外 R 可触发9bit计数/overflow；不能将多R截成128后自证成功。forwarded_bytes12 合法0…2048，包含2048；RX等待/decoder输出 pending 不因为收到 RLAST 自动0。

### D3. 普通许可是新完整范围，不是旧短许可扩权

RAW AR348/AP466 保原 address26、byte_length7=1…64B、record访问及 actor授权；SC LOOKUP 长度7/其 kind3 保原合同。EB_REQ662/EB_RSP1012 为独立内部 family，允许的是实际 **16…2048B aligned READ burst**，address32/end33完整；不复用其长度字段、不把 beat_count 的8bit当 length7、不把 permit64 相同命名当协议兼容。前置验证从原 full holder/pin/type/control/history 来源一次捕获；普通 e0–e6 只覆盖 kind2、当前真实不可变权限和 row guard。

FETCH bridge 保完整旧 FETCH315 expected。仅由真实 source publication 事件冻结 caprevision，取得实际 bound KEY/ROWKEY/borrow/坐标；source payload不提供自授权 address/ref/grant，也不能自报 held=1 来绕 STOP。PHY 取完整新许可并创建自己的 held/private route，完整 body 为1012bit，加 valid为1013；O 回复可复用存储不能当 destination 永远可借的记录。PB ARLEN8 最后由合法实际 count1…128 减1产生；ARID0/SIZE4/BURST01及其余 PB规范不变。新许可只读，不产生 W/WSTRB、journal postimage 或共享 mutable RMW资格。

逐连接检查：IF06已规定唯一O实际修改入口和IF07实际source发布门、旧revision/STOP交接设计；两者的实际owner保护/pending/原完成窗口和wrapper接线仍须联合冻结，不能将文字吸收写成已有wiring。剩余具体delta为D0 registry保护/读取→O fullctx、O J/SOURCE/cert/parent→clone、ROW实际ASSIGN/FILL/retire→RGR、EB许可→PB完整route、真PHYclose→scope债、真实RETURN→原loanACK。单独拿cold稳定、caller holder或“pin不会改”不能省接线；standaloneREPLAY619/888、SOURCE/CLASS/G provider不被暗改。

## E. 局部状态、中文操作草图与实际成本

### E1. 唯一冷体、native RAM 几何和建立

具名 **EB_CTX1948=完整CTX840/J657/原OPEN387/真实borrow64**；不放普通 lookup current值，不删原 ctx/history。**EB_CTX0 一个 native20×512 RAM10**，core 同域1W1R、OUTPUT_REG0候选；O admin 唯一读写，未批准/未推断。四 context每份98词=1960bits，实际body1948，末词低8bit有效/高12bit零。base词0/98/196/294，end词97/195/293/391；392…511的120词/2400bits未分配，不隐性另放 transport。四份 body7792bit、native已用7840bit、padding48；可寻址10240bit、nominalRAM10240bit。word_index7合法0…97，nativeaddr9；slot2只指四context缓存映射，真实Oloan_slot另经完整KEY关联。

中文建立：e0旧 OPEN fire 留 expected及部分pinledger；后续在实际 source/control/result owner保护下把完整来源搬入唯一 **1960bit assembly**，高12zero。不给四个context各配assembly，也不用没有lease的最近一次CTRL readimage。O顺序98次WE，各沿写完整20bit，未用词不当有效；之后顺序98次RE/capture逐词对 still-held immutable assembly 比较，不额外造第二份1960bitreadback。任何同址读写结果不用；admin序列互斥，普通hit不占cold读口。原 source保护/valid必须持续到核读与fullqual完成，不因为第一次wordfire便退。

在所有 context词、真实资格和plane热表都写完/verified后，最后单独提交 context_valid及ACTIVE屏障，再从原owner发布成功GRANT；这不是多RAM/原真实pin同一沿原子提交。地址/runtime历史/原输入 source held/private都是独立预算；clone应在B01列出真实读取owner与保护事件，不能以本文assembly替代它们。invalid/context_valid0的cold stale bytes无需reset全RAM清零，但不能被公开lookup当真实holder。

冷clone中遇真实STOP、native异常、来源保护失去或同历史CTX/J/source/CERT不一致，不提交ACTIVE或新的成功GRANT。已实际创建的每份pin仍留installed及全tuple，原owner真实RETURN/ACK清理；unknown进入Q并保旧记录。不得清RAM、valid0或cachemiss推断“未创建”。已经published的成功GRANT/reply仍全文保持，由真实失败/恢复路径处理后续故障；不能事后改体撤销。

### E2. 十二 plane快照、四 header和五行guard

| 位置与数量 | 单条字段、初值、更新与理由 | 实际 selected bits |
|---|---|---|
| O core plane[4][3] | 328=ref64/version64/grant64/commit64/base32/byte_capacity29/record_bits10/snapshot_valid1；实际 source/ref版本分别保存，slot不是权限；未grant valid0；只有fullqual捕获/安全fence更新 | 3936 |
| O core header[4] | 395=fullKEY256/borrow64/caprevision64/state3/global_required3/mode3/stopped1/context_valid1；FREE全valid0，不清唯一分配器 | 1580 |
| O core masks | installed12/return_requested12/returned12/pin_metadata_retired12；相互独立，cachevalid0不等于returned | 48 |
| O core RGR[5] | 259=ROWKEY164/Oexec_slot2/borrow64/source_y11/target_y11/row_required3/state3/valid1；对同一原RowCtx生存期唯一镜像 | 1295 |
| O core唯一序号owner | caprevision_next64/exhausted1及permit_next64/exhausted1；各独立非零generation，耗尽停新授予，不回绕，最大合法只发一次 | 130 |
| O唯一真实mutation pending | target_plane_mask12/cause4/pending1；初次可信isolated cold start为0；原command/fullbeforeimage仍由真实O持有，不以17bit替代原body | 17 |
| 固定ROW/FETCH源唯一publication phase | pub_phase3；EMPTY0/SOURCE_HELD1/TRANSFERRED2/SETTLING3/TERMINAL_METADATA4/Q5，6/7非法；只真实事件推进，非caller phase | 3 |

header state3明确0FREE/1BINDING/2ACTIVE/3FENCING/4CLOSING/5RETURNED_METADATA/6Q，7非法。FENCING保原caprevision/tuple及真实row lease直至旧published/accepted工作闭合；CLOSING只在普通accessquiet后进入，不残留尚未接纳的合法白名单请求。Q禁止新授予，旧已经承诺的输出/效果保真实账，不以Q自动取消它们。plane valid从actualREADgrant/fullqualification建立，actualcommit必须保持真实token，never-granted只有原模式/真实mask和实际未授予ledger确定，不能从ref0单独解释。固定logicalbytes SRC6220800、EDGE259200、ANN518400；record24/1/2和stride5760/240/480，item数2073600。capacity29必须至少logicalbytes但授权范围以完整逻辑尾及真实initialized end裁切，padding不因capacity较大自动授权。SRC source历史与 RESULT J绑定贯穿引用；其它reader计数变动无需修改 immutable字节几何，但匹配本grant的 active/holder/phase改变必须 E5 fence。

RGR状态0FREE/1ASSIGNED/2FILLING/3FULL/4CLOSING/5RETURNED_METADATA/6Q、7非法；普通新FETCH只ASSIGNED/FILLING。原RowCtx865仍真实拥有输入bank/已绑定输出bank/reader/writer/held/retire，不新增五个row资源。mode0目标dy0…539读SRC sy=2dy/mask001，dy540…1079读EDGE sy=2(dy−540)/mask010；mode1/2SRC001，mode3EDGE010，mode4SRC+EDGE011，mode5三plane111且algorithm2。dy/sy0…1079完整11bit。原SHOW开关不减少已冻结requiredmask，mode6诊断/mode7非法不接生产PLAN。

RGR REGISTER须真实原ASSIGN fire及RowCtx权属/完整ROWKEY一致后才valid；同沿原FILL事务需按旧状态计真实fire，下一状态FULL禁后续新fetch，但以前源held/accepted必须履约。RETIRE先核原RowCtx真实reuse条件与新lookup/permit/FETCHmetadata空，才能valid0；RGR miss不能减少任何pin。control reply和REQUEST保持到各自truefire；RETURNED_METADATA/Q既占原row额度又占header/plane额度，不借valid0偷偷复用slot。

cause4具名0NONE/1PIN_RETURN/2HOLDER_STOP_CLOSE/3DESCRIPTOR_QUAL/4SOURCE_PARENT_REVOKE/5HEALTH_FAULT/6EPOCH_ISOLATION/7REBIND/8RETIRE；9…15非法并转真实错误/Q，不blindcast旧reason。pending1为单一尚未完成真实mutation，后到命令不得覆盖其body/旧beforeimage。pub_phase EMPTY且valid0只在可信首次隔离cold start或该原事务实际退出后成立；warm reset和Q不清它来证明无债。**17+3=20新selected逻辑位**，唯一实例成本另见E6，不是已综合FF。

### E3. readonly range、half-open和4KiB

真正授权由实际 selectedplane base、logicalbyteend、initializedprefix及request给出的已核 source_y/offset/count计算；request不传address。SLOT当前SRC六slot从0按8388608递增；EDGE三slot从50331648按262144递增；ANN三slot从51118080按524288递增，所有实际候选base 4KiB对齐。布局文件明确只有候选固定range、没有runtime权限；bind时实际descriptor必须逐项匹配本族slot/ref/size/格式，否则rejectLAYOUT，不能仅因为地址看起来合理授权。

先核offset13非负、16B倍数，beat_count8在1…128；先扩位计算len12=count×16，合法16…2048。offset+len至少14bit比较≤实际stride；source_y×stride乘法保完整结果，至少24bit容纳当前frame，统一零扩到32bit后与base做33bit加法，再与offset相加，carry/overflow拒绝，不能先收窄到32再检查。最终[a32,e33)⊆[base32,base32+logicalbytes)且≤实际initialized_prefixend/authorizedobjectend；e33不窄化，2^32边界仅在实际object/物理窗口允许时可数学表示，当前生产根本不授权该边界。

当前候选生产arena[0,134217728)及物理DDR[0,268435456)双核；不能沿旧RAW[65536,67108864)限制或只保26bit，否则合法SRC0/高位生产对象会错误/别名。byteaddress32足够当前DDR但由实际映射证明不是caller假设。页内偏移先13bit扩展：address低12bit＋len12≤4096；禁止先截12bit后判跨界。req精确128beat若跨4KiB必须拒绝，FETCH owner按真实PB分段发不同完整请求/FSEQ，不用旧一个request假装全部完成。

固定1080p每个plane行长及完整帧尾均16B对齐，因此本文普通burst请求=physicalalignedspan，**rounded授权范围与请求精确相同，没有新增尾padding读取**。不以physicalslot较大把tail/guard拿来填128beat；末burst不足128则用实际count。未来非alignedwidth/plane尾拒绝本族，若需roundup访问必须另设计真实已初始化roundedregion及对象边界，不能借冷hold稳定批准pad。recordbits10只24/1/2本族，通用512bittypedrecords以及PROFILE独立128B实体不进EBP。

PB单行mode5 RGB5760+EDGE240+ANN480=6480B/405beats。actual4Kbase时RGB最多4burst、EDGE最多2、ANN最多2，共最多8；y34/187/750真实达到8，row0只有5。若base不4K、源format/stride变化，不套8上界，当前bind拒绝LAYOUT而不是悄悄扩大次数/权限。row0不能拿来代表最坏服务。

### E4a. 真实FETCH发布沿、旧revision与源交接

IF07放在固定真实ROW/FETCH源valid形成处。保持原公开FETCH315=ROWKEY164/borrow64/fetch_seq64/plane2/offset13/count8；实际RowCtx865、成功ASSIGN/RGR、完整bound KEY/loan恢复exec slot、坐标和mask，不从caller自报holder或地址构造资格。一个全局白名单 **FETCH315+old_caprevision64+valid1=380bit**；pub_phase3单独计。原singleton route/完成窗口仍B02/B04待联合接线，不新增四个隐含pending队列。

中文操作按下列次序：①原source valid0、全局source/白名单/expected空、真实ACTIVE/RGR ASSIGNED或FILLING且原运输容量允许时才产生候选；②原FETCH owner先核活动与完成cache：同请求只履约/重放原TERM，同seq异body拒绝，STALE不复生；未选的其它exec候选仍在原owner；③PUB_COMMIT同沿冻结原完整315与沿前old revision、置SOURCE_HELD，原source valid沿后可见；④原FETCH fire后目的先保完整315 expected，再由受保护bound记录构造独立EB_REQ662；⑤REQ完整匹配白名单与KEY/ROW/borrow/coords/mask后才交接，普通查验/许可/PB实际route不省；⑥真physical退出后原TERM/ACK/cache/运输独立完成，最后原owner准许替换才EMPTY。

| 原真实事件／沿前状态 | 提交与冲突规则 |
|---|---|
| 新候选，source valid0，PUB_COMMIT与STOP/fence/row FULL同沿 | 禁此尚未published的新提交，不创建白名单/permit；不把它算旧held |
| 合法PUB_COMMIT，无上述阻断 | 同一提交沿写315/oldrevision/valid与SOURCE_HELD，沿后source valid才可见；不能先valid、后补授权 |
| 已SOURCE_HELD，source反压或STOP | 全body/白名单/oldrevision稳定；STOP只禁新候选；真实row/header/source lease保留，不用ready0推neverissued |
| 沿前已published原FETCH与STOP/REQ fire同沿 | 旧fire各计一次；原FETCH fire、新REQ形成、新REQ fire三个独立事件；固定目的完整expected受保护后才TRANSFERRED，白名单不能提前消失 |
| e4实际分配唯一permit，RSP/PB route可后续held | 从实际permit建立即SETTLING，不等RSPfire才记债；完整plane/READ/logical/init/4KiB/health仍核；PB真route/RX后才AR，不以白名单授WRITE，已有held回复不可改体 |
| IF05真退出/正确ACK、local close运输空 | 进入TERMINAL_METADATA；该保留值不再授新AR，但原TERM342/ACK350和CONTROL 52词cache job继续真实完成，不直接复用FETCH槽 |
| 原expected/运输/metadata/实际引用退出 | 原owner允许后才EMPTY；保留的完成cache只是复制值，不pin已退资源、不重建许可 |

唯一phase顺序为EMPTY→PUB_COMMIT→SOURCE_HELD→真实受保护FETCH/REQ交接后TRANSFERRED→实际许可建立后SETTLING→IF05实际退出后TERMINAL_METADATA→原运输/metadata退出后EMPTY。明确未创建许可的合法拒绝，只在request/reply/expected实际结束且真实无AR/route/effect债后进入TERMINAL_METADATA，不虚构IF05许可。BUSY仍待真实重试保TRANSFERRED/旧身份，不重新发布白名单或建第二permit；unknown身份/futureeffects进入Q，保tuple及phase证据，不消费Q回EMPTY。phase不是AR/R关闭证明；真实旧资格已不可信时可以真实失败/Q，不能承诺所有旧读仍成功。

### E4b. 唯一 ordinary lookup逐沿草图

lookup唯一请求662+valid1、O回复1012+valid1、PHY destination route1012+valid1各实际独立；O已fire之后目的private仍保全，不能借源存储代替。已确认真实IF07旧发布身份可在FENCING进入，其完整资格与原row lease保留；普通未发布新候选不能自报old_held/oldrevision越过门。

| 沿/阶段 | 以沿前旧状态计算、提交与可见性 |
|---|---|
| e0 ACCEPT | 当真实valid&&capacityready且非rst fire锁完整REQ；新请求只ACTIVE/不stopped，旧published由真实白名单/相同旧revision批准进入；同步STOP仍先计旧fire，再记禁新标志 |
| e1 IDENTITY | 完整KEY/borrow/caprevision/contextvalid/实际slot关联与RGR全文/coords/mask匹配；新请求须ACTIVE及RGR ASSIGNED/FILLING；真实旧发布白名单在FENCING仍按其保留原grant/row lease履约，不以RGR后来FULL/CLOSING状态拒掉旧承诺。Q不新授予，既有承诺另依实际失败/债务路径闭合；lookup miss明确拒绝，不执行pin减账 |
| e2 PLANE | 选唯一合法plane及完整actualtuple/commit/base/capacity/record；READ only、requiredbit、stableimmutable资格和真实fence epoch完整，不能只看cachevalid |
| e3 SPAN | 先宽算rowaddress/offset/length/end；不得先形成AXI窄值再查；锁oldplane数值保护至permit完结 |
| e4 RESERVE | 查页/物理/初始化/逻辑尾，实际无旧permit/route冲突、generation可用；分配一次非零permit，保真实metadata；忙则明确无新许可BUSY/或合法held等待，不能重复分配 |
| e5 PUBLISH | 形成完整1012回复，suffix合法且实际data完整后才valid；新valid在沿后可见。旧reply不等相邻plane/当前UI，没有被STOP撤掉 |
| e6 最早交付 | 下游此前已有capacityready时真实RSPfire；PHY再保存自己的route/private和完整RX预留后才允许ARpublished，此沿不是DDR传输完成 |

无stall时从e0到最早sourceRSPfire六个clock interval；一级不是0拍函数调用。reply stall冻结全body/valid；已有单permit直到真实IF05metadata排空不能接受第二个成功许可，即使reply已消费，也不是每拍一个成功burst。cold/adminwrite/mutation不能改变这次锁定plane；真正资格修改须先E5对应scope fence与实际关闭，不把e5 PUBLISH当关闭。lookup断言失败形成明确拒绝或Q，绝不通过len0/beat0空许可“成功”。新generation最大值发一次再exhausted，新permit在分配/成功发布前失败不让已对外同编号复用；Q也占该编号和slot。

### E5. mutation、quiet、RETURN与metadata退役

IF06 MUTATE_FENCE是唯一O metadata真实writer内的受信任seam，不是caller API。真实已核ALLOC/RETURN/RETIRE/INVALID/REBIND/epoch/holder-stop等分支，在native WE或相关holder记录可见前，以完整old command/beforeimage、pin/descriptor/holder/source/parent链求target_plane_mask12及cause4，置单pending。mask位置仅3×真实关联exec-cache-slot+plane；也核BINDING的实际partial installed，不能只扫ACTIVE。原body/fullbeforeimage需原O真实expected/RMW副本持有；缺holder/未知beforeimage不能推mask0或拿caller holder_id当授权。未影响本grant的分支仍按原owner执行真实事务，不能静默绕过真正影响它的分支。

| 真实owner事件／资格改变 | fence或保持规则 |
|---|---|
| 本pin active/RETURN/tuple/role/access/borrow/epoch/holder回链改变 | 先封本实际scope，保旧身份；仅fulltuple真RETURN减本账 |
| 本holder STOP/closing/Q/retire/reuse/真实phase不再允许READ | 原owner立即禁新PUB_COMMIT/ordinary；已published与旧fire保原revision，真实失败/关闭独立履约 |
| descriptor ref/version/JID/origin/backend/base/logical/record/capacity/init/immutable/commit/lifecycle/physical_settled/write资格改变 | 正常COMMITTED immutable且本READpin live时，原排他/RETIRE前置先禁止几何/版本/writer修改；fence不能绕过禁止规则。合法撤权/失效经seam保tuple/effects |
| source/parent/result/CERT授权撤销、registration/rebind/epoch隔离影响本grant | 原完整身份求范围；新source/J/epoch不覆旧快照；恢复fullqual与newrevision |
| 其它reader ACQUIRE/RETURN仅read_pin_count改变，本grant仍live | 不全plane revoke、不假RETURN本pin；O真实计数仍更新 |
| 下一policy/config/latest，合法同lease JOB→BUNDLE真实owner/JID/slot迁移 | 原REQ/holdref/grant/role/创建origin不变时不因旧SRC_LEASE522全文不等误拒；若实际provider/holderphase同时撤许可，仍fence |
| 本row FULL/输入输出退休 | 独立RGR新FETCH gate及银行寿命；旧published借原row lease；不自动RETURN wholeloan，不等whole out FREE |

中文变更：先记同沿旧FETCH/REQ/RSP/AR/R/TERM/RETURN/commit实际fire和旧published身份→目标header FENCING/stopped及新发布门关→保留原command/beforeimage及真实业务lease，**放开native RAM短锁**→IF05/真实physical/RETURN/关闭服务独立推进→LOCAL_ACCESS_QUIET→本fulltuple RETURN/ACK→原loan CLOSE_ACK→最终metadata retire。不能持global RAM锁等DDR/holder quiet，也不能用放短锁把实际来源保护一起释放；原pendingbody不被新命令覆盖。actual owner仲裁服务界仍B04，不凭这个顺序宣称无饥饿。

| 真实事件沿／阶段 | 沿前账与后续可见次序 |
|---|---|
| F0 真实mutation/STOP到达且已有旧fire | 旧fire分别如实入账一次；同沿尚未published候选禁止PUB_COMMIT；保原white-list/expected/revision，下一状态目标FENCING/stopped |
| F1 已核O oldbeforeimage/holder完整，安装mask/cause/pending | native资格WE前gate生效；错误/缺source/unknown保Q，不猜空mask；正常immutable禁止分支不commit非法修改 |
| F2 短事务读/提交准备结束 | 放native短锁，原command/完整beforeimage/来源lease继续保留；独立IF05/真实RETURN不得被等待quiet的同一锁阻塞 |
| F3 已建permit真IF05正确ACK/close运输空；未建许可则原expected与真实无AR/route/effect债证明 | 新门关闭；oldheldREQ/RSP/permit/AR/R/RX/decoder/route实际退出或合法neverissued才LOCAL_ACCESS_QUIET，不给未建许可伪造IF05；无需行FULL、loanACK或metadata RETIRE |
| F4 本pending清理的实际RETURN/正确ACK及合法原mutation提交 | quiet后清cache可见资格，保完整旧tuple/body/returnedledger；再原native/holder真实更新或RETURN全文核一次归还并记录returned，不递归等待自己的RETURN_ACK；wrong echo不减账 |
| F5 pins_closed与原491全部关闭事实真齐 | 原assignedrows/TERM/actualAR/R/overflow/refclosed各由owner证明，才能原BULK_CLOSE_ACK499；RETURN不等它，caller八facts不自证 |
| F6 真原运输/引用/metadata退出且owner准许RETIRE | 完整oldrecord比对及正确RETIRE回执后才释放loan/registry/contextmetadata，最后FREE/reuse；不能先FREE再证明metadata空 |

LOCAL_ACCESS_QUIET只要求普通访问与真实physical/许可/close运输债退出。pub_phase TERMINAL_METADATA保留的315/旧rev此时仅metadata复制值，不再ordinary授权或发AR；不能仅因该值存在而阻挡physical quiet，也不能据phase4假定任何physical债已空。原TERM342仍核trueaccepted/decoded/facts、ACK350及CONTROL **52词FETCH/TERM/ACK cache job**；DRB的**58是其最早MR job间隔，单位clock interval，不是58词**。scope物理关闭可以先于原终态metadata退休，整个holder此时仍不得FREE。IF05不等依赖routeclosed的TERM，RETURN不等依赖pins_closed的loanACK，metadata retire不要求holder先FREE，分别避免回环。

健康故障/unknown/真实权限已经失效时，trusted health sticky/gate/Q立即记录，不强保旧读成功；已published成功reply/终态仍全文稳定。真实合法前缀、旧AR/R/effects和未知未来效果保账，Q/INVALID诊断可见不等于tuple/ref/version/grant可清或slot可复用。本seam不制造protected DDR drained/fence证据；没真实闭合就不LOCAL_ACCESS_QUIET、不成功RETURN、不FREE。全scope pinreturned后header可RETURNED_METADATA，完整ctx/hottuple/loan/CLOSEexpected及heldACK保至原owner实际消费并排空RETURN/IF05/FETCH/TERM/CLOSE/control图及跨域futureeffects。coldmiss/rowmiss/valid0/lastR/timeout均非证据；Q保installed/returned/partialgrants/编号，四EXEC占额沿SCAN不变。

局部first reason具名优先：identity/permission/range/source资格→真实native/协议→backend/health→关闭证据→cancel；同沿各真实fire仍先分别结账，first冻结、后来原因记原mask。不得blindcast旧reason编码；已publishedbody不因后来错误改体，实际RETURN后的晚健康故障由独立恢复处理，不给旧borrow新效果。冷clone STOP/失去source保护不能ACTIVE；warm/new epoch不清Q/pin/phase/seq自证无债。

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
| O真实mutation mask12/cause4/pending1＋源pub_phase3 | 17+3=20 |
| **selected总量** | **13828bit** |

这个13,828=原13,808+20，是明确选择的热字段，不包括原CTRL源CMD/IMAGE保持、actualpin/descriptor维护的expected/完整beforeimage/RMW图、source/parent/J/provider保护及资格fact/controlerror、PB原R_ROUTE/RX计数、原GRANT/TERM/CLOSE输运、复制/CDC/Q ledger等。17bit不是完整mutation成本，380bit名单也不替代原FETCH源/目的private；若复用原状态须唯一实例ledger证明，不免费。没有测试/综合证明FF数，也没有保证与现63191body简单相加减。cold1RAM是新成本，不以原D0/目录RAM闲词免费解释。十二pin是原四EXEC×三plane已有条件额度，**不再加十二pin**；全局61/62/63或64是否装下仍需独立整个holder/pinledger证明，本文不确认。

已列全机175RAM候选如果仅吸收本卡则176，另联合MT的2RAM则178；SC CACHE-RAM独立候选、其它尚未列状态不得隐性加入或扣除。256总RAM减候选只作预算参数，没给完整RAM/FF/LUT/DSP/时序/portmapping前不称fit；两层热mux/widecarry/fullKEY比较的100MHz时序亦NOT_RUN。EBroute1012与原PBfullroute可能部分重复，需完整唯一实例ledger核后才能扣；当前先保两份来源private，不能为了资源好看删sourceholding。

DRB现单行fill串行模型：有真实g_R≤1与streaming decoder条件时数据write720，MR原ASSIGN67+八个cache job各最早58interval+FILL40=571，合1291；100MHz G0行deadline1481留190用于μ_FILL＋J_DDR＋J_META。42额外retire服务interval放同一路径则MR613留148；52词cache与58最早interval不可混单位。原cold每burst87都落criticalpath的条件下，720+571+696=1987>1481，差506，尚未计其它；它说明这项重复查验值得替换，**不是全机无条件不可实现证明**。

新lookup e0–e6六interval只是最快合法source交付，八次48的纯尺度，在上述同路假设下余142（或含42余100）；**不能把48自动写成μ_FILL上界**。真实新PERMIT_CLOSE/ACK、RGR控、oldFETCH bridge/sourcelease/mutation、PHYroute/actualAR/R/decoderstall、pinreturn/metadata竞争都计入联合最坏值。给有条件式 L_perm≤6+W_EBP_arb+W_RGR+W_rsp，其中三W必须真实有界；没证据不得写0。完整burst还需Amax＋各R间隙上界＋decoder/refclose＋close/term/MR服务，只有满足实际可证明bounds才可谈100MHz deadline。

单ROW未FULL前不能开始该ROWrenderer970；不同真实bank的跨ROW流水、两input/三output和warmup严格沿PB/DRB，不虚构sameROW并行抵消这些周期。原CONTROL只有一个MR，FETCH/TERM/ACK 52词cache（最早58interval）及OPEN/ASSIGN/FILL/RETIRE保持原合同；新EBcold admin、ROW mirror/MT、PUB_COMMIT/完整source保护、MUTATE_FENCE pending、COPY/ring/CAMERA/算法对真实DDR和metadataQoS竞争均计reservation/fairshare/最大间隙。EBP只加速凭证查验，不增加DDR带宽/inputbank/RX/ring/clock；持续显示服务界EBC-B04仍OPEN。

## F. 语言、位宽与跨域契约

本卡纯文档无C++程序；未来独立参考应是身份/权限/事件与整数范围模型，不是替FPGA执行识别的PC结果。C++标准/工具待批准实现范围核实际版本，不能提前写模型源码。所有字段unsigned，算前扩位；无定点舍入/允许误差，许可、echo、数量、地址必须逐位准确。

| RTL §8.2 | 明确规则/未闭合 |
|---|---|
| A 数值 | len12可2048，count8可128，end33保half-open，offset+len≥14bit/page和13bit，source_y×stride保完整≥24bit再扩32/33；ref/grant/borrow/rev/commit均64；mask12只关联位置不授权，cause4及phase3按E2具名范围，非法不blindcast |
| B 时钟/观察 | EBP/coreadmin/RGR同生产core候选100MHz上升沿；沿前valid&&ready为fire。PUB_COMMIT同沿冻结315/oldrev/名单，沿后原source valid可见；原FETCHfire、新REQ形成、新REQfire分记；PB真实PHY域B05，不凭corecounter读异步facts |
| C 接受/交付 | 单REQ/独立RSP/单permit/独立controlclose，真实capacity；已published旧fire同STOP先入账一次，尚未published新候选同沿gate，不能把两者混成撤旧valid |
| D valid/推进 | nofire不推进count/generation；phase仅真实事件推进，不是physical proof。valid0/cachemiss不证明未创建或grant已返；snapshotvalid只qualification，四masks独立；partial installed亦经fence |
| E 反压/保持 | 全KEY/ROW/315/oldrev/地址/tuple/suffix及原command/fullbeforeimage稳至各自真实退出；source/目的private独立，放native短锁不放来源lease；永久stall/timeout不证明效果清零 |
| F 延迟/吞吐 | e0–e6最快六interval，非PUB_COMMIT到最终metadata完成上界；单permit不得1/cycle；cold98WE+98RE计native延迟，52词cache的58最早interval不是最坏service |
| G 复位 | 可信首次isolated cold start置valid0/phase EMPTY/pending0，不清RAM当授权；warm保/隔离旧phase/Q/installed/编号/债，不用新epoch删旧身份；原恢复owner/七owner桥B05 OPEN |
| H 配置 | 完整PLAN/CTX/J冻结，同沿UI/latest不改旧许可；合法同lease JOB→BUNDLE不凭旧522全文判等误拒；真实权限改变经O seam先旧fire/gate再关闭，重新fullqual/newrev最后valid |
| I 存储 | EB_CTX0唯一20×512/1W1R/O独占、末词low8high12zero、spare不分配，同址readwrite不用；20新selected位只一份；fullbeforeimage/source保护/private仍独立未知预算；五RGR不是五新rowbank |
| J 身份 | fullKEY256/ROWKEY164/FSEQ64/borrow/rev/全CTX/J和受保护真实source链；实际O loan slot不等D registry slot，caller holder_id/mask/phase不授权；原mode0/5、坐标/接口数量不改 |
| K CDC | EBP热表/owner原事实不跨域裸读；PHYprivate/facts8/真实QUIET经受保护桥，不由phase/corecounter/caller自证；各域held/reset/隔离与protected DDR关闭接线B03/B05 OPEN |
| L 实现 | Ti60F225/Efinity仅既有环境参考，本轮不跑工具；1新RAM/selected13828非packedFF，source/parent/完整RMW成本未闭合，100MHz mux/addr/port STA及全机QoS OPEN |

三份跨语言契约：①共同数值参考接actual fullcontext/grant/row/ops，输出拒绝或精确READ span，范围/padding零误差；②硬件按fire、held、nativeRE/WE、oldstate、新提交屏障和effect真实事件执行，不用函数调用次序代替；③参考事务按完整KEY/ROW/FSEQ/permit/ref-version-grant匹配硬件实际source/destinationfire，关闭proof与真实ledger逐位比。resetinvalid只在可信isolatedstart或正式闭合后生效，不能将新epoch删除旧比较项。这些均待后续获批实施，不含当前测试脚本。

## G. 后续实施与验证计划（全部未运行）

拟增量：真实source/parent/J保护与O读取协议→O MUTATE_FENCE/seam真实分支→EBcold/热表/RGR→fixed source PUB_COMMIT/FETCH bridge/独立长许可→PB readonlyroute/physicalclose→RETURN/loanACK/metadata与恢复→资源/100MHzservice。拟符号 EB_BIND、EB_CTX_STORE、EB_LOOKUP、EB_ROW_GUARD、EB_READ_ROUTE、EB_SCOPE_FENCE，以及 EB_MUTATE_FENCE_SEAM/EB_FETCH_PUBLICATION_GUARD；都是未生成的设计定位。具体业务文件清单/套件须联合READY冻结，本轮没有源码、模型、TB或构建。B01–B05/原审批边界未闭合阻止受影响实现；R1或待批R2都不是EBP功能证据。

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
| EBT13 | REQ09/IF06；逐真实ALLOC/RETURN/RETIRE/INVALID/REBIND/epoch/holder-stop writer分支，本pin/descriptor/sourceparent变更；BINDING partial，缺beforeimage，另一reader/合法JOB→BUNDLE | 独立原O command/pin/holder/phase/source ledger给影响mask；所有影响分支native资格WE前gate，禁止的immutable修改不commit；无关count/currentmetadata不误撤权；wrong/missing真实来源不mask0；pending不覆盖，放短锁后IF05/RETURN可独立进 | NOT_RUN |
| EBT14 | REQ10/IF07；actual source valid0候选与STOP/FULL同沿；oldpublished FETCH/REQfire与STOP；dup/cache/同seq异body/STALE；BUSY/Q/未创建许可拒绝 | 独立原FETCH owner看PUB_COMMIT首次可见与完整315/沿前rev；新候选阻断、旧held不撤，三个fire独立；TRANSFERRED/SETTLING/TERMINAL_METADATA按真事件，无第二permit/新AR；52词cache真退出后才复用，phase不是关闭oracle | NOT_RUN |
| EBT15 | REQ01/09；真实CORE registry/J/source/result/CERT/protect，新旧历史混合、来源lease晚返、SOURCE state1/native失败/失保护 | 独立各owner原记录与真实保护事件，完整同历史才建立；固定CORE source口和实际Oloan slot，不caller holder_id自证；state1/valid0不推absence；partial grants真实cleanup/Q、无新ACTIVE/成功GRANT；已publishedreply仍稳 | NOT_RUN |

方法：先局部独立整数/ledger与held/cancel场景，再接口组合/原owner事实驱动，再实际综合/PNR/STA/nativeRAM/100MHzservice。场景文字不是可执行TB。功能检查观察上升沿前fire和沿后稳定，TB调度/seed/timeout需要在批准套件指定；无限外部stall、unknownfutureeffect不得用timeout当成功。资源/时序/硬件下载本轮未运行，实体步骤继续人工闸门。

## H. 双向追踪

| REQ/来源 | MOD、IF与不变量 | 拟代码单元（未生成） | TEST/期望来源 | 实际实现/证据 |
|---|---|---|---|---|
| 01 SCAN/HANDOFF完整ctx及DIR/CTRL来源 | EB-BIND/COLD，IF01/D1/E1，真实同历史保护与部分grant | EB_BIND/EB_CTX_STORE | 01/02/10/15，原field/owner/protect | 未实现/文本核；source接线OPEN |
| 02 DIR D3/D5/RAWrole | EB-BIND/FENCE，fullqual/IF06实际mutation | EB_QUAL_CAPTURE/EB_SCOPE_FENCE | 01/06/09/13，actualpin/desc/holderledger | 未实现/文本核 |
| 03 HANDOFF/PB/短AP | EB-FETCH/RGR/LOOKUP，IF02/03/04/07新族 | EB_FETCH_BRIDGE/EB_ROW_GUARD/EB_LOOKUP | 03/05/06/14，原fullFETCH/ROW/sourceowner | 未实现/文本核 |
| 04 PB/SLOT | EB-LOOKUP，E3完整half-open/padding | EB_SPAN_CHECK | 03/04，独立宽整数layout | 未实现/文本核 |
| 05 PB真实route/RX | EB-ROUTE，IF04/05完整destinationprivate | EB_READ_ROUTE/EB_PERMIT_CLOSE | 07/08，actualAR/R/RXledger | 未实现/文本核 |
| 06 HANDOFF/DIRoldpromise | EB-FENCE，E4a/E5 physicalclose→RETURN→loanACK→metadata | EB_SCOPE_FENCE/EB_RETIRE | 06/08/09/13/14，真实旧fire/term/closure | 未实现/文本核 |
| 07 DRB/CTRL | EB唯一实例/E6selected与conditionalbounds | EB_ADMIN_ARBITER/EB_SERVICE_AUDIT | 10/12，真实resource/service | 未实现/文本核 |
| 08 DIR/SCAN/RAW恢复 | CONTROL实际QUIET/EB-FENCE，F G/K | EB_RECOVERY_BRIDGE | 09/11，actual跨域quiet | 未实现/文本核 |
| 09 DIR D3/D5/RAW/CTRL真实唯一writer、review§4/5/7 | EB-MUTATE/FENCE，IF06/E2/E5 F0–F6、完整beforeimage | EB_MUTATE_FENCE_SEAM/EB_SCOPE_FENCE | 13/15/06/09，实际writer分支/owner记录，不cache自证 | 未实现/设计增量；保护/服务OPEN |
| 10 HANDOFF/CTRL真实source发布与原完成窗口、review§6/7 | EB-FETCH-BRIDGE，IF07/E4a/phase3、同沿gate/oldrevision | EB_FETCH_PUBLICATION_GUARD/EB_FETCH_BRIDGE | 14/05/06/08，原source首次valid/fire/expected/cache | 未实现/设计增量；owner接线OPEN |

反向：EB_MUTATE_FENCE_SEAM→REQ09/02/06→IF06/E5→EBT13/15，EB_FETCH_PUBLICATION_GUARD→REQ10/03/06→IF07/E4a→EBT14/05/06/08；其余拟符号按上表。符号不引入算法/PC识别/新actor，新schema/row镜像/route持有和20selected位不删原source/private/关闭。实际源码/注释/模型/测试反向核尚无实现不能做，静态表不冒称代码trace覆盖。

## I. 门槛与呈现

①整体与正常/边界样例见B；②owner/复用与数据/关闭路径见C；③新旧完整source/接口/逐连接见D，B01–B03仍未闭合；④中文PUB_COMMIT、真实mutation F0–F6、冲突/失败/quiet和存储见E；⑤RTL A–L/语言/CDC见F；⑥场景及服务条件见B/E/G，actual联合deadline未证；⑦后续增量/双向追踪见G/H；⑧五项OPEN，未通过“无阻塞”；⑨全文读回/hash交接仅文件实录，不是独立审阅PASS；⑩版本v0.2/只文档范围明确。当前 **NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。原review仅针对冻结v0.1的窄候选增量，不能转为本卡v0.2 PASS/READY或实施授权；Root仍需实际独立审读。不自动消耗R1批准，不扩大待批R2 v1/48范围。

## J. 变更、相容与恢复

旧DIR D3逐次pin全文→holder全文→phase的合同不动；本卡提出kind2 ordinaryREAD全量资格一次捕获/真实mutationfence替代，其中新length12/end33范围是明确behavior/interface delta，需联合指定版本覆盖。旧RAW1..64B、SC kind3/32cache、独立REPLAY、PB其它actor仍旧契约；stagecache33/H1、MT冷ROW等独立新候选不被吸收。若合并后修改descriptor/holder可变资格或原FIFO/QoS，必须回本卡对应REQ/IF/TEST/资源/草图重新核，不只换数字；已绑定R1交付保持只读。

本次v0.1→v0.2增量：新增REQ09/10、IF06/07及真实source字段链，EB-MUTATE/FENCE与fixed source PUB_COMMIT交接；17bit mutation＋3bit publication phase=20，selected13,808→13,828；实际沿表/旧held失败及physicalclose→RETURN→loanACK→metadata顺序、RTL A–L、EBT13–15和双向追踪同步。原FIFO/slot/generation/pin额度不由本文改变；源保护、PB physical关闭、服务资源及warm继续OPEN。纠正MR单位为52词cache/58最早interval，未降低1080p、完整算法/识别要求，使用板现有DDR边界不变。

已按原字节保全 [v0.1-before-source-fence](design-TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001-v0.1-before-source-fence.md)：299行/51,018B/SHA256 `2FC82DB887BA972A45D5F39B613C42AF5892DECF53DB23E25086039F666031F1`。纯候选审阅 [exec-source-fence-design-review-v0.1](../experiments/track4_algorithms_20261004/03_review/exec-source-fence-design-review-v0.1.md)：132行/24,264B/SHA256 `F49AE5379B16042FAEB9B6052DFCB6653A758B914E9EF5020E615B6DDFA24253`，绑定上述旧卡与只读原合同；本文吸收规则后需新的独立审读，不继承该报告为新版PASS。快照若已有不同内容禁止覆盖；回退用它对照修订，不删除历史/正式审计。

恢复不得把readsnapshot从Q翻ACTIVE后继续旧permit；须实际旧AR/R/运输闭合、sourcepermission重新fullvalidate、独立新caprevision且旧编号不复用。冷clone失败不是业务partialgrant自动无效果；actualpartialpins按真实清理路径，输出明确失败/未完成/Q区别。正式状态/DB/Approval Manifest本轮不改。

## K. 实现与验证实录

本轮仅更新本主Markdown并按字节复制原v0.1到指定快照；其它路径只读。实际读取控制面、唯一v0.2规范919行/模板、本旧卡299行/完整review132行，以及A2列出的真实上下游来源段；保存后主卡逐段全文读回、来源hash复核由最终交接报告精确行数/字节/SHA，不把文件核读叫功能测试。没有业务源码、模型、功能script、TB、向量、仿真、EDA/构建/综合/PNR/STA/bit/hex、网络、DB或硬件；正式state/Manifest、R1、R2 v1/48均未改。G全部NOT_RUN；1RAM/13,828selected/八burst/6interval为设计分析，非utilization/PASS/全机实现证明。Root独立审读仍待完成。

## L. 用户阅读和交付说明

阅读顺序：B整体/五项OPEN→C真实owner与共享单元→D来源链及新旧接口→E1/E2冷记录/真实pin与20新位→E3范围→E4a发布前候选/同沿PUB_COMMIT→E4b普通lookup→E5真实writer fence/physicalclose/RETURN/loanACK/metadata→E6资源服务→F/G/H。正常事务：actual CORE/source/parent/J/context/protect与真pin齐→核读→最后ACTIVE/原GRANT→真ASSIGN/RGR→PUB_COMMIT冻315/oldrev→原FETCHfire→独立REQ/六interval最早许可→PB独立route/RX→actualAR/R/decoder→真IF05→原TERM/ACK/52词cache/FILL。取消事务在O真实事件处gate未发布新候选，旧held/oldfire继续受保护或真实失败；actualphysical/accessquiet→原pinRETURN/ACK→原loanCLOSEACK→实际transport/metadata退出→最后reuse。未来需求按REQ→IF→草图→TEST→联合预算更新，不能只补长度常数。

本卡已把具体方案、字段、几何、窗口、关闭次序和未知范围写清，但尚无全机实施批准/实际验证/理解验收；用户未实际作答不标“已理解”。本轮终点是文档可读回/可评审，后续成熟独立范围可依规范另冻结；本卡的OPEN不阻止与它隔离且已获批的现有范围继续验证。
