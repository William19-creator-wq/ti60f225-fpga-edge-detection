# TRACK4-ALGORITHM-STAGE-CAPABILITY-001：阶段身份、权限快照与分范围关闭联合设计

- Goal：为生产 O 目录增加可审阅的阶段注册、普通访问快照和权限切换合同，消除每次数据访问重复读完整冷身份的潜在瓶颈；真实 STORE 的算法规则与效果台账继续承担动态资格。
- Current state：生产目录 v0.1、RAW/R4C/R4R 均为设计来源；原 DIR D3 明确逐次 pin 全文→holder 全文→phase。新增快照尚不存在，不能视为已有授权。R1 已绑定交付及原厂资料只读。
- Target state：先保存完整阶段上下文，后授实际 pin；ordinary access 采用经 O 全查建立的权限快照；每个 provider 独立排空、RETURN、形成原 CLOSE_ACK，最后汇合 metadata retirement。
- Gap：LOAD/SRC/GRAD 来源与新 typed provider 由并行 LOAD-GRAD 卡冻结；publication fence 的真实桥、完整权限事件和全机资源/服务预算尚未闭合。
- Assumptions：Ti60F225；production core 单上升沿域，100 MHz 仅候选目标。这里只设计内部接口，不配置时钟、引脚、工具、数据库或正式状态。
- Open questions：见 A3、D6、F4；这些项阻塞实现和 READY_FOR_REVIEW。
- Dependencies：A2 冻结阅读来源，以及尚未冻结的 LOAD-GRAD 卡；不能凭聊天中的候选宽度自动升级基线。
- Milestones：联合合同审查→补齐桥与成本→保存读回修订→READY_FOR_REVIEW→用户明确批准指定版本/范围/基线→实现验证。
- Detailed steps：阅读次序为 B 整体→C owner→D 交接→E 逐沿草图→F 数值/存储/服务→G 验证→H 双向追踪。
- State transitions：文档状态 NOT_READY / NOT_APPROVED；业务阶段状态见 E1，正式硬件状态不变。
- Artifacts and hashes：本卡自身摘要由保存后的实际读回交接；A2 仅列实际来源摘要，不伪造 commit。
- Validation：本轮仅只读合同核查与文档数值走查；所有可执行验证 NOT_RUN。
- Failure handling：未知 grant、部分分配、错误 echo 或未闭合旧 effects 均保留真实义务，进入阻塞或 Q；没有自动 rollback/free。
- Human approval gates：本卡不是 R1 批准的扩展。达到 READY 后按现有 Approval Manifest 请求指定设计批准；本轮不申请实现。
- Rollback：撤回本候选时保持旧 D3 全查与旧上下文/关闭合同；无源码差异需要回滚。
- Completion criteria：本轮完成可读设计卡、明确 OPEN、保存和实际读回；不声称全机可装下、算法已实现或测试已通过。

## A. 状态、来源与边界

### A1. 版本与权限

任务 ID 为 TRACK4-ALGORITHM-STAGE-CAPABILITY-001，设计 v0.1，2026-10-05。关联完整生产算法的 O/STAGE/STORE 合同，非独立算法功能。状态 **NOT_READY / NOT_APPROVED**。本轮允许设计文档；禁止业务 RTL、功能脚本、模型、TB、构建或物理工具执行。不得改写 R1、原 HDK、既有交付、Approval Manifest、数据库或正式硬件状态。当前正式状态与数据库设置沿控制面保留。

### A2. 实际阅读来源与范围

摘要均为 SHA256。完整文件范围与本轮限定读取分开记录，不将检索命中冒称全文重审。

| 来源 | 摘要 | 本轮实际读取/使用范围 |
|---|---|---|
| 根目录 `AI_Agent_代码可理解性规范_增补提案_v0.2.md`，919 行 | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2` | 既有全文阅读摘要未变；本轮 L195–317、344–535、576–782，采用整体/接口/中文草图/RTL A–L/审批门槛 |
| `planning/PLAN_TEMPLATE.md`，154 行 | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` | 本轮全文；本卡填写通用字段及 A–L |
| `planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md`，231 行 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA` | 本轮精确 L27–119，及 D4/D5/F 的字段、M0/M1、native 数值；沿前次全文与限定 delta 记录，不冒称本轮全文重新审核 |
| `experiments/track4_algorithms_20261004/03_review/production-stage-holder-review-v0.1.md`，101 行 | `D8967256E44D1C2AD4190F9E217E56C3FB371BBA92E020ED25D5ADB2F4AF28B7` | 本轮全文；其 149 词、7004/9980 bit 均是旧候选下界，本卡明确修订 |
| `planning/design-TRACK4-ALGORITHM-RAW-STORE-001.md`，367 行 | `7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD` | 本轮 L81–185、232–264，及检索选行；AR348/AP466、完整 grant/RETURN/RETIRE、journal 与 typed close |
| `planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md`，346 行 | `5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11` | 本轮 L70–162 及 E/close 检索选行；LC270、CLJ438、RQ324、CLOSE294/ACK502 |
| `planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md`，460 行 | `AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257` | 本轮 L87–166、245–280 及 close/E 检索选行；RJ2257、26 objects、RQ799、CLOSE295/ACK504、POINT 权限切换 |
| `planning/design-TRACK4-ALGORITHM-PERFORMANCE-001.md` | `A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469` | 本轮 L189–211；地址扩位、logical/raw/目录成本区别与 13N+4 |

控制面 AGENTS、bootstrap 入口、配置规则/提示、PROJECT_CONFIG、state/ledger、DB README、WORKFLOW 已按入口读回；本卡不把运行提示当永久规则。并行 LOAD-GRAD 新卡尚未以最终文件/hash纳入 A2：LG1119、LOAD_ALLOC1076/ACK1213、GRAD close-before-parent-commit 属**联合候选**，保存版本与互操作闭合是 A3-01。

### A3. 当前阻塞项

| OPEN | 缺口、影响及承担者 |
|---|---|
| A3-01 | 并行 LOAD-GRAD 新来源卡实际版本/hash与 SRC/GC provider 完整绑定、原始 LOAD 分配/部分分配 ledger；影响 REGISTER、SRC/G 权限、无 pin 拒绝。由 LOAD-GRAD owner 与 O 联审。 |
| A3-02 | actor 已 published held 请求如何进入 STORE/O publication fence 白名单，所有 namespace 的桥及实际保存位置；不能用新 ready=0 撤销旧承诺。影响 CAP_REVOKE、RETURN 与死锁。由 O/STORE/actor 联审。 |
| A3-03 | phase 与 descriptor/grant 变更的完整通知集及各原 STORE 的可检查权限表；任何绕过 fence 的 writer 都破坏快照。影响 ordinary hit 安全。由各 STORE 与 O 联审。 |
| A3-04 | 完整热状态、端口缓冲/原 ledger 的唯一实例映射、LUT/XLR/DSP、共享 M1/目录/DDR 服务和持续输入输出时序；本文只有可核字段下界与显式服务次数。由资源/性能 owner 联审。 |
| A3-05 | 部分 grant、wrong echo、pending RETURN 的具体恢复与 warm reset 隔离桥尚未冻结；Q 不能自动消债。影响失败/复位。由 CONTROL/O 联审。 |

这些项没有因写完文档消失；可以继续只读评审和修订，不能生成受影响实现。

## B. 整体行为与要求

本设计处理阶段身份、访问资格和真实关闭的关系，不改变 1080p、完整 Canny、识别质量、五基础/六高阶算法与原输出要求。PROFILE 八片上实例与 45 个 DDR 对象分开；不把 PROFILE 填进 descriptor DDR 槽。生产目录 64 descriptor/64 pin 是容量选择，**不证明 64 pin 并发够用**。

| REQ | 可检查的规则 |
|---|---|
| SC-01 | 原 H160=JID96/operation_id64，operation_id 首个 0 合法；namespace 必须参加匹配。stage_generation 独立、非零、终生不重用，不能用 load_id/recognition_id/SCANKEY 截断代替。 |
| SC-02 | BINDING 先写全冷上下文并校验真实来源，再安装实际 grants；保存上下文不等于 ACTIVE。ordinary access 只在对应 child ACTIVE。 |
| SC-03 | 快照只由 O 从真实 descriptor/pin/原 holder 及 STORE 证据生成。命中必须检查 full H、namespace、stage generation、cap revision、object、ref/version/grant、原 phase/operation 与完整范围。 |
| SC-04 | 已 held/accepted requests、已发 permits、child borrow、journal、raw effects、RSP 必须履约。撤权先禁止**新发布**，保持旧事实，排空后才失效或更换。 |
| SC-05 | 每个 child LOCAL_ACCESS_QUIET→自身 pin RETURN/ACK→相应 typed CLOSE_ACK；CLOSE_ACK 不等待它自身交付或整个 holder RETIRE。 |
| SC-06 | RETURNED_METADATA、closing、partial grant 和 unknown 均仍占原额度；cache miss、错 echo、cancel、通知被消费都不证明 free。 |
| SC-07 | 整 stage METADATA_RETIRE 等全部 child 与父原持有/终态/运输/查询/native/effects 真实闭合；动态 latest/valid_count/tail/initialized-prefix/atomicity 仍由真实 STORE 负责。 |
| SC-08 | WRITE→READ 和 immutable publication 先排空旧写与归还 writepin，不复用旧 grant；原 refs 与独立新 grant/revision 的关系可追踪。 |
| SC-09 | 新快照是显式 DIR D3 接线变更候选；未批准/未实现时旧全查合同继续有效。字段/存储/服务/验证不冒充已实测。 |

正常路径：真实 parent 历史与原 provider 分配→REGISTER 完整 body→BINDING 安装原 grants→真实 BIND/PREPARE 成功被消费→child ACTIVE→STORE 接合法 typed请求并办理 LOOKUP→实际 raw/journal effects→typed结果→分 child 关闭→RETURN→typed close证书→父终态/metadata retirement。边界路径：load_id=0 仍合法，但 stage_generation=0 拒绝；retain0 的 G ref/tuple 全 0 且 never-granted，不等待不存在的 G 准备、close 或 token；部分 grant 后失败保留 installed mask及其身份，不能按拒绝回包清零。

## C. owner、职责与连接

| MOD | 职责、状态拥有者及依赖 |
|---|---|
| SC-O | O 唯一写 stage header、cold body、cache、installed/returned ledger、generation/revision 分配器。复用生产目录 native 几何；不计算算法、不猜 STORE 动态可见性或 actor quiet。 |
| SC-STORE | 原 CLASS/closure、RC、以及新 SRC/GC typed providers 唯一持有各自 requests/effects/journal/latest/closed 台账；提供真实准备、phase、publication fence、local quiet 与末级证书。不是第二 O 生命周期 writer。 |
| SC-ACTOR | L/C/RC/SRC reader/GC 原 actor；停止新 publication 时仍兑现旧 held，保留完整原身份/expected/RSP/TERM。不能以私有 valid 清零代 RETURN。 |
| SC-PARENT | J/O 原 parent 与分配 owner；绑定真实 J/RESULT/source lease，并汇合真实 terminal、private retirement 与 publication。LOAD 的原来源交并行卡；本卡不创第二 source lease。 |

整体连接按 IF 编号：SC-PARENT→SC-O 的 IF-SC01 REGISTER；SC-O↔真实 directory/pin 的 IF-SC02 CAPTURE/INSTALL；SC-STORE↔SC-O 的 IF-SC03 LOOKUP；SC-O↔SC-STORE/SC-ACTOR 的 IF-SC04 FENCE/UPDATE/ACTIVE；SC-STORE→SC-O 的 IF-SC05 LOCAL_ACCESS_QUIET，继而 O 的 IF-SC06 PIN_RETURN/ACK；SC-PARENT/各 provider→O 的 IF-SC07 METADATA_RETIRE。原 R4C/R4R BIND/RQ/RSP/CLOSE/TERM 的完整 body 与真实原债仍保留，不通过 CAST 改成新内部包。

汇合采用五个 child scopes：0=stage0 SRC read；1=stage0 CLASS LOAD；2=stage0 GRAD build（retain1）；3=stage1 CLOSURE 的 CLASS/conditional QUEUE/EDGE；4=stage2 RC 的 26 typed objects。scope0/1/2 共享完整 LG，但独立 close债。CLASS 的原 ACK502 pins_released 只认证 scope1；scope0/2 仍 live/closing 不妨碍真实 scope1 先返 pin与证书。stage0槽仍保留，不能因此被新 LG覆盖。

## D. 内部接口与组合检查

### D1. 共同时序与身份

接口都是候选 core 同域、posedge、无符号字段、固定有限 depth1 请求/响应槽。fire 为沿前旧 valid&&ready&&!rst；capture 不穿透成 downstream fire；valid body、身份与 sideband 在反压时保持。末响应沿只能记录真实事件，不能同沿读“新 empty”提前形成 close/ACTIVE/retire。cancel、phase更新与 flush 不组合撤回已经 published 的旧请求/响应。

H160 是原字段而非新 generation。holder_link160 保生产布局 kind4/index6/generation64/epoch32/zero54：kind3=ALG_STAGE，index0/1/2；generation 采用 O 新 stage_generation，epoch 保原完整32；zero54必须0。原 operation_id0合法，stagegen/grant/revision0非法。namespace4沿原 RAW role：1SOURCE、2LOAD、3CLOSURE、4GRAD、5RECOGNITION；REGISTER 的stage0/1/2分别限2/3/5，LOOKUP的stage0按固定child0/1/2限1/2/4。stage_index2编码3非法；不能只靠 H 相等跨端口授权。descriptor/pin canonicalFREE仍按 DIR；全局 generation序列保留，旧 ref不能复用。

### D2. IF-SC01 STAGE_REGISTER

可信 parent 发 BEGIN218，低位到高位为 stage_index2/namespace4/epoch32/H160/schema8/body_bits12；schema1=LG1119、2=CLJ438、3=RJ2257，body_bits必须对应，不从任意 length分配缓冲。随后 WORD28=data20/word_index7/last1，低词先、连续索引，最后词未用高位0。LG56词、CLO22词、RC113词。BEGIN接纳时仅保留空stage及新非零generation，进入 BINDING；WORD最后写完后还须读回完整 body与来源再形成 REGISTER_ACK，不能把最后 RAM写沿当多RAM原子提交。

REGISTER_ACK internal body固定 BEGIN218 echo/stage_generation64/status2/reason6/registered1=291bit。内部 status0=OK、1=REFUSED、2=BLOCKED、3=QUARANTINED；reason6取0NONE、1BUSY、2IDENTITY、3LAYOUT、4RANGE、5PERMISSION、6BARRIER、7UNREGISTERED、8EXHAUSTED、9PROVIDER、10UNKNOWN，其余非法。REFUSED只证明此次注册没有建立 ordinary资格，不自动证明此前分配/partial grants为空。BLOCKED等待真实旧义务；不创建幂等重复 effects。错误完整body/echo保留原expected与分配ledger，按事实拒绝或Q。

三个冷 body：LG1119=J657/原LC270/source_image_id64/admission_ref64/grad_build_ref64，来源由并行卡核；CLJ438、RJ2257保原字段全宽，RJ包含完整 PROFILE1024。原 LC270/CJ142不改；旧 BUILD_BIND1012/ACK1212只对应 EDGE/ANN/RECORD，**不能推定已分配 CLASS/G**。并行 LOAD_ALLOC1076/ACK1213是本卡注册的待冻结前置，不能借 stagegen充当 buildref。

### D3. IF-SC02 CAPTURE/INSTALL 与 ACTIVE

REGISTER只预留对应child的quota/缓存位置并保存body，**不预先建立三livepins**。各原typedprovider BIND/prepare再触发唯一一次真实O ACQUIRE/ACK；CLASS pin仍由原S BIND277建立，不能先授同pin再让原S重复bind，或改变其合法拒绝无CLASS pin的旧保证。O在已保存 body下，从完整 SOURCE_ORIGIN/lease/descriptor、真实 BUILD/committed状态、完整原 pin/grant 与namespace核资格。阶段 grants 不由 REGISTER caller自报后直接相信。pin字段 ref64/version64/grant64全部保存，installed mask仅在真实授予时置位，失败回包未获核对则保未知事实。BINDING只允许实际provider prepare流程已授权的内部初始化；不开放普通 READ/WRITE。真实原 BIND成功被其使用者消费、各必需 provider准备完成，后续沿才能置 child ACTIVE。

slot0..2=SRCr/CLASSw/GRADw；retain0 slot2是never-granted，tuple全0，不伪造归还。slot3..5=CLO CLASS/QUEUE/EDGE，QUEUE缺席只接受原S fastpath真实证明。slot6..31=RC object0..25，保原26种精确格式；POINT builder属于RC该pool，不能另加两pin而称额度不变。ALLOC/原writer拥有权在 fullbody来源校验前后必须可追踪。新caprevision与 stagegen不同，由独立单调分配器生成，非零且max仅用一次，下一分配EXHAUSTED拒绝，不回绕。revision保存**每个child一份（5×64bit）**，同child槽共享；CLASS/G更新不使仍live的SRC旧revision失效，stage0不是一个共用revision。

### D4. IF-SC03 STAGE_LOOKUP 普通访问

候选请求616：H160/namespace4/stage_index2/stage_generation64/cap_revision64/object5/typed_op5/access2/ref64/version64/grant64/tx_seq64/item_index32/item_count22。field顺序固定低→高，tx_seq沿原typed事务身份0合法；typed_op/object依原namespace精确解码，不依名称混合。access 0READ、1WRITE、2RMW、3非法。回复740=echo616/status2/reason6/permit64/address32/first_bit3/byte_length7/record_bits10；byte_length仅成功1..64，地址按生产实际边界检查。内部reason不硬cast为原typedreason，SC-STORE负责明确映射，映射尚属A3-03。

O命中检查原H/role、stagegen、caprevision、ACTIVE、精确tuple、该slot snapshot_valid、原phase与operation白名单；geometry从cache而非caller取得。范围先用足宽 index+count、index×record_bits、bit_end、base+byte_offset+length计算并核item_capacity/byte_capacity，后才收窄地址。WRITE权下保护字节RMW不是新ordinary READ资格；mutable own READ/RMW仍须真实S排他与最新journal路径。成功permit为独立非零单调64bit序号，原permit消费/子借用/effects闭合前不释放ledger。相同请求echo不授第二个effect；cachemiss形成BLOCKED/UNREGISTERED或Q，**不作pin已退证明**。

LOOKUP只对应实际数据span，item_count>0且该次byte_length≤64；更大typed CLEAR拆成真实有限raw spans，DENSE组按真实16个受保护项核。无数据SEAL/COMMIT（包括E=0 POINT COMMIT）走原STORE/O内部admin与全查资格，不制造0byte permit；typed_op_mask的SEAL/COMMIT位由admin使用，不等于LOOKUP要读取不存在的record。原成功空POINT token必须真实生成，不能因本LOOKUP只支持非空span而拒绝合法E=0任务。

这里明确提议覆盖 **DIR D3 仅 holder_kind3 且 ACTIVE ordinary access 的 per-access冷读**：用已全查capture的hot identity/geometry+真实STORE动态资格；REGISTER/INSTALL、CAPTURE/UPDATE、RETURN/RETIRE仍全查，其他holder kinds仍旧pin全文→holder全文→phase。旧 RAW AR348/AP466也未自动改成616/740：新内部桥与production32bit迁移必须按本卡及物理接口联合批准接线。不能给旧26bitAP直接塞32bit地址。

动态 valid_count/initialized-prefix/QUEUE tail/latest/expected phasecommit、16组atomic、partial full16B RMW合法span、raw effects与immutable publication条件不在cache里猜；SC-STORE继续实际核查，若需physical16B超logical字节权限，按DIR/PERF另核完整同对象rounded且已初始化范围。ordinary快照不提供裸DDR绕过STORE路径。

### D5. IF-SC04 FENCE/REVOKE/UPDATE/ACTIVE

FENCE以完整stage/child/H/gen/oldrevision固定身份发起。停止的是actor新publication；已held请求及STORE已接受/已发permit属于旧revision履约集合。STORE保持其ready/真实处理路径直到旧promise完成，不能因fence组合屏蔽造成held永不fire。原已published的完整KEY、旧revision及保存位置必须由可信actor/STORE ledger证明，caller不得以self-declared old_held绕过fence。

仅当对应child原published集合、accepted/native/DDR/journal/borrow/permit/heldRSP真实闭合，O才失效受影响slot，然后真实RETURN旧pin（若权限变更需返）、实际结束旧returnedmetadata、重新全查新ref/version/grant、构造新child revision与cache。同child中没有换grant的槽也必须在旧promise已静止后绑定新revision；其他child不被改revision。新版所有字段写完后以snapshot_valid最后发布；ACTIVE ACK消费后的后续沿才恢复新ordinary请求。同对象只更新valid_count/tail/latest由STORE处理，不触发每像素cold recapture；几何/ref/version/grant/access/holder/生命周期/immutable资格或权限phase变更必须经过fence。

数据访问资格与最终publication admin义务分开：已经accepted的COMMIT/CLOSE原完整expected/control body保持，不能撤掉；当其本身依赖RETURN/无writer时，access-data quiet不等待该末级admin结果先交付，否则形成循环。这只允许真实已retained的parent/STORE publication资格继续办理元数据，不允许旧writepin失效后新发ordinary数据写。admin held及响应仍由原owner履约，whole metadata retirement必须等它们真空；完整admin来源/封存台账桥尚属A3-02/03，未闭合不可实现快照。

严格条件：需要列全所有可以变更上述字段的O/STORE写事件；没有此完整通知桥，缓存不可启用（A3-02/03）。public typed RQ/RSP原body和expected仍保留，新增内部 revision不是替代原echo校验。更新阶段不同时接纳同child新generation，不用cachemiss或invalidate清installed/returned ledger。

### D6. IF-SC05/06/07：分 child quiet、RETURN、metadata retire

LOCAL_ACCESS_QUIET由真实provider冻结证据：完整child/H/gen/revision/实际pinmask、原cutoff/末seq、已接受requests/read/write/native/journal/permit/borrow/heldRSP全部结清；不等待本次RETURN/typedCLOSE_ACK或整体holder退休。BODY及与原CLOSE证书的精确字段映射需合并新SRC/GC接口（A3-01/02），不以一位quiet替代完整证据。O核精确原tuple发RETURN；错误RETURN echo不减count，already_returned须实际ledger同一身份，不重复RETURN。RETURN ACK后相应访问pin闭合，returnedmetadata及ACK运输仍占额度。

原 R4C CLOSE294/ACK502和RC CLOSE295/ACK504保原counts/overflow/closed字段。R4C成功关闭证书要求原status0/reason0等事实；RC合法status1/reason的完整close可结清原credit，但仍登记失败并阻止COMPLETE，不能把两类证书同名就统一。它们的access_pins_closed依据**自己的**scope RETURN实际完成；不会等待wholeholder retirement。末RSP fire后后续沿形成ACK，RETURN不能等待此ACK先交付。

METADATA_RETIRE需要各存在child的真实terminal/close消费、query/control/REGISTER/LOOKUP/RETURN输送槽、冷RAM/native事务、old permits/borrow/effects及原parent obligations全空。RC private refs退休仍是O真实清单；access pin返还不是private对象已退休。stage仅在这些事实已是旧状态时FREE，可清body有效标记而非强制RAM全清；global allocators不复位。closing、returnedmetadata、wrong/unknown仍阻塞同stage复用。

GRAD retain1联合顺序采用并行卡最新候选：P真实写及CS→GC provider CLOSE并消费真实writepin RETURN/close证书→另发parent O GRAD_COMMIT245→无writer且真初始化/effects settled下生成immutable/version/token→COMMIT_ACK→GC term/运输闭合→metadata retirement。parent COMMIT是完整 retained LG/provider close ledger授权的内部publication，**不借已返writepin再写ordinary数据，不等整个holder RETIRE**。原CLASS初始commit非immutable，仍按CLASS独立原close。该新增parent接口与字段最终冻结属A3-01/03。

## E. 局部状态、不变量与中文操作草图

### E1. state与不变量

stage state3候选：0FREE、1BINDING、2LIVE、3FENCING、4CLOSING、5RETURNED_METADATA、6Q、7非法。每个child另有state3及publication-fence-ack/localquiet/close-certificate-consumed/terminal-consumed/metadataquiet五位（8bit/child）。总stage状态是呈现摘要，**不能替代五child真状态**；阶段phase4由原真实STORE事件映射，编码/全operation矩阵在A3-03冻结，不由请求自选。

重要不变量：I1无完整body不得安装ordinary权限；I2 H0合法但gen/revision/grant0无资格；I3 snapshot_valid只由完整全查最后发布；I4 installed/returned ledger不随cache valid清零；I5 oldpromise和effect先履约后invalidate；I6 scope1关闭不等scope0/2全退；I7 RETURN_ACK不等依赖它的CLOSE_ACK或METADATA_RETIRE；I8 cache不包含动态STORE真相；I9 global序列max一次且exhaust阻止下一次，不复用canonicalFREE ref；I10每个效果与original KEY/grant/revision唯一对应。

### E2. 注册与初始化逐沿

e0沿前FREE且旧transport空时接BEGIN，保存完整218bit，分配新stagegen并推进单调序列；该沿不接第一WORD穿透。e1以后按预期word_index接词、按真实WE写M1。last仅第55/21/112词合法；小于body_bits的末词高padding必须0。最后词写沿只记录完成，不设ACTIVE。

随后O逐词读回完整body至唯一assembly，最后capture后的后续VALIDATE沿核完整J/原context/PROFILE/source与分配来源；错误体保留原身份与分配facts。VALIDATE成功仅得到REGISTERED/BINDING和quota reservation。各真实provider BIND/prepare触发其唯一ACQUIRE，逐个记录tuple/installed，不在原S BIND前预授CLASSpin；中途wrongACK或unknown不擦之前成功pin。realoriginal BIND/prepare响应被实际使用者消费并成为旧事实后，发布完整snapshot/revision，后续ACTIVE_ACK交付，再后续才ordinary可接受。retain0从真实J.algorithm2获得，不从零Gref推断无债。

### E3. 普通请求逐沿

e0旧lookup槽空、对应child ACTIVE时capture616；capture沿不发permit。e1核固定slot/完整identity/grant/oldphase，e2足宽范围及STORE动态资格检查；e3才写740回复并置valid，最早e4由相邻receiver采样。错误只形成明确内部状态，不发raw请求。reply反压保持，后续配置不改变原revision；成功permit的实际借用/效果另由原ledger收账，不能因reply被消费就释放。

本候选仅一个lookup req/rsp pair depth1，不声称每拍吞吐。下一请求不得覆盖old response/permit accounting；dispatcher负责八旧RAW client公平服务，生产新client联合排队另核。STORE可先保存typedRQ再申请lookup，但它保留原完整RQ/expected直到真typedRSP或close处理完成。

### E4. 撤权、旧held与关闭逐沿

e0请求fence时，旧fires仍照实记账；若本沿actor已有旧held待fire，它仍属于oldrevision，不能撤valid。e1后actor停止生成新publication、报告可信fence边界及完整旧published集合；STORE继续履约这些KEY，并兑现已接受raw/journal effects及heldRSP。新请求在门口排队，不叠加新pin取代旧债。

最后原RSP/permit/borrow/effect消费沿只记真实清账；后续旧localquiet允许O invalidates相关snapshot，再全身份RETURN。RETURN ACK被消费后后续STORE pinsclosed真，之后形成自己的typedCLOSE_ACK。原actor消费CLOSE_ACK、terminal/control再排空；returnedmetadata/冷body仍保留，直到其scope和parent metadata obligations结束。若wrong响应/close，保原expected与真实effect，独立close路径仍可推进已知债，未知部分Q，不假清。

必须保留的反例：在FENCING时直接把STORE ready=0，actor已held请求不会fire，localquiet永不真；若RETURN等待typedCLOSE_ACK，而ACK又等pins_closed，也永不推进；若CLASS ACK等整个stage0退休，又SRC/GC等CLASS终态，也成环。本设计分别用trusted旧promise履约、RETURN前置和child-scope独立关闭破环，实际桥未冻结前保持NOT_READY。

### E5. 权限转换与跨stage接力

RC POINT构造完成并accepted原COMMIT_POINT时，开始RC child的writer→reader publication barrier：停新ordinary publication，旧WRITE数据效果/permit/journal/RSP履约，确认真实初始化/前缀/dirty结清→RETURN旧writer→依据完整retained原COMMIT admin和真实无writer证据提交immutable/version/token→原COMMIT响应消费→此pinreturnedmetadata/运输结束→授独立READ grant→全查/新childrevision/capture→后续READ。E=0也按原有效空前缀真生成token。不能先宣称COMMITTED仍有writer，不能等RC整体CLOSE才能返writer，也不能把原WRITE grant当READ。原held COMMIT不因data snapshot失效而消失：按D5分开的完整admin资格履约，其真实接线是A3-02/03。

GRAD immutable publication采用D6的close-before-parent-commit；ANN/RECORD immutable publication也须按真实无writer规则联审，对其读者的新外部EXEC grants仍分别记账，不占本stage32slots代替external12额度。CLASS LOAD→CLOSURE：先scope1旧requests/effects→RETURN→正确ACK502→L终态消费及原single-S写会话结清，才可scope3真实exclusive bind；scope0/2或stage0 returnedmetadata尚有债时保留stage0，不要求先FREE整个holder。queue缺席只据旧fastpath真实条件；scope3、4各持fullcontext，H同值不合并。

### E6. 失败、reset与metadata retirement

未grant且真实no-effect拒绝可报告never-started，不等待不存在provider；partial安装失败按installed mask关闭实际pins，unknown grant保留Q与originalexpected。取消保持已有commit与效果历史，但撤发布资格。cold/lookupmiss不改变quota、readcount、writepin或lifecycle。

rst同步高时fire0、禁新接纳；软reset/epoch变更必须原CONTROL隔离所有old transport、真实pins/effects或保持Q证据后才重建。不得局部清stage/cache而让外部旧grant继续进来；不支持未说明的电源重置后持久恢复。warm epoch保global stagegen/caprev/permit next/exhaust，max用后只拒绝。metadata全部事实旧真且无本沿新control/query，再在后续沿撤bodyvalid并FREE；原body不需逐词reset，但下一REGISTER完整覆写且验证前隔离。

## F. 字段、native RAM、资源与服务预算

### F1. cold几何：唯一O副本、M1共用端口

| body | bits | native20词 | M1词地址 | 末词真实位/padding |
|---|---:|---:|---|---|
| 原RESULT3份 | 3×1879=5637 | 282 | 0..281，每份94 | 每份19/1 |
| 新完整LG | 1119 | 56 | 282..337 | 19/1 |
| 原CLJ | 438 | 22 | 338..359 | 18/2 |
| 原RJ（含PROFILE1024） | 2257 | 113 | 360..472 | 17/3 |
| 空余 | — | 39 | 473..511 | 非已授权对象 |

新增stage body3814bit、native191×20=3820bit、padding6bit；M1 body9451/native473×20=9460/padding9bit。明确覆盖旧review LC270+CLJ438+RJ2257的149词候选，不修改该旧报告历史。目录native已用由97588增至**101408bit**；可address104448、nominal112640仍原11 RAM10候选；余3040bit=journal48词960+M065词1300+M139词780，不能把nominal padding当可存实际字段。PROFILE8独立RAM实例不变；DIR45DDR对象不变。

M1为唯一native20×512，1R1W、OUTPUT_REG0，读RE沿后下一capture沿；全20bit词写WE=11（两个10bit），含末词高padding0。ADDREN与实际读/写一致，禁止同址读写；REGISTER/CAPTURE与原RESULT访问经唯一有界burst仲裁，最多一条nativeissue/沿的保守预算。cold不是新的191份FF，也不是每pin复制RJ2257；原actor held/expected/private上下文不能凭O已有副本就消失。

### F2. hot字段与唯一实例候选

固定32cache行，每行295bit：ref64/version64/grant64/base32/byte_capacity29/record_bits10/item_capacity22/pin_access2/typed_op_mask6/snapshot_valid1/immutable1，合9440bit。stage/child/object/role固定映射不需每行重复body，但其mux/译码需LUT预算。typed_op_mask是原operation资格的受控capture，不代STORE原phase及dynamic checks；完整映射A3-03尚未闭合。valid_count/tail/latest/initialized-prefix不复制到cache。

| 唯一逻辑实例 | 本文可核selected state bits | 保存理由/限制 |
|---|---:|---|
| cache32×295 | 9440 | 身份/geometry/perms快照；pipeline寄存器另核 |
| 三stage header：H160/gen64/state3/phase4/flags2 | 699 | flags为完整body已核/原bindsuccess已消费；不能替代child prepare台账 |
| 五child caprevision64 | 320 | 分开CLASS/SRC/G revision，避免CLASS barrier废掉仍live SRC旧promise |
| stagegen与caprevision两个next64/exhaust1 | 130 | 独立序列；不用DIR refgen替代 |
| installed/return_requested/returned/pin_metadata_retired四个32mask | 128 | valid清零仍保真实grant和quota；需要partial安装tuple真存 |
| 五child state3+五证据位 | 40 | 不压成一个CLASSclose控制；证据位必须来自原完整ledger |
| 唯一完整context assembly | 2257 | cold body校验/完整RJ/profile，LG/CLO高位zero；非32份context |
| LOOKUP req616/rsp740与valid2 | 1358 | 各depth1，不能省掉held echo |
| REGISTER BEGIN218与valid1 | 219 | 帧/namespace原身份固定 |
| REGISTER词20/valid1/address9/wordcounter7 | 37 | 原M1仲裁、读capture等额外状态另核 |
| permit next64/exhaust1 | 65 | 若与RAW已有唯一permitallocator合并，实际唯一实例去重，不重复宣称已预算 |
| DIR唯一descriptor640/pin512读回assembly | 1152 | 原RAW已指出需另列；不是native RAM body位数，不为每cache行复制 |
| **selected总和** | **15845** | 部分字段可核下界，**不是完整FF/XLR预算，也不能直接除器件XLR称fit** |

新增REGISTER_ACK291/valid、FENCE/admin/RSP/ACTIVATE/RETURN/METADATARETIRE完整held、已published白名单及KEY保存、lookup arithmetic pipeline、prepare/归还transport、scope完整cutoff/count/overflow台账、partial前置ALLOC/原expected、串行native引擎/仲裁状态、DIR既有seq/hot/journal、STORE journal byte/postimage/atomic groups、真实原actorcontexts均须完整唯一实例清单（A3-01/02/04）。表中没有把这些隐形计为0；既有stage review7004/9980、DIR selected436、资源review175RAM均不包括完整本单元。

Ti60 datasheet资源上限256 RAM10/160 DSP/60800 XLR等是器件事实，**11块目录或全机已列175块只是候选部分**，不能证明可装下。宽加乘比较、32way mux、完整identity匹配、phase译码与时序未综合；本卡不承诺0DSP或某个完整LUT/FF值。R1实际3411 packed XLR是成熟前端/外壳报告，不能外推为全算法或本cache成本。

### F3. 服务成本：native issue与clock interval分别计数

按保守单issue仲裁：三个cold body合191词写、191词读；读连续n词，第一RE到最后capture需n个间隔（跨n+1个边沿），最后capture后还需VALIDATE/发布后续沿，不写成“n拍全成功”。initial全查每实际pin读pin32+descriptor32=64issues；最大32条时2048，另读fullcontexts191得到**2239 readissues**。grant更新若完整descriptor32+pin32write，32条另2048writeissues；真实origin/SOURCElease/allocator/provider/journal/原BIND及ACK服务另加，以上不是整体start固定latency。

每次权限UPDATE受影响k条至少64k全查issues+该stage fullcontext56/22/113词读取；若返旧/授新还要真实更新与ACK。phase动态latest/valid/tail变化不应每像素触发recapture，但所有权限变更不得漏fence。旧held/effect/backpressure在没有外部服务公平性证明时没有固定完成上限；timeout记未知/Q，不能模拟已闭合。

stable ordinary hit草图e0capture→e1identity→e2range/STORE资格→e3publish→最早e4fire，0 cold nativeissues，至少4clock intervals加停顿与真实permit/DDR/journal服务；单槽不能假设1/cycle。用Q表示真正内部lookup次数，hit成本不是13N×4；一typed CLEAR/CLAIM/DENSE_ADD16可能多个raw资格和更新。旧PERF13N+4=26956804为GENERAL LOAD+closure **logical**数量；若每logical都简单串行64native读，尺度为1725235456cycles=17.25235456s@100MHz，但非实际trace或本新模型的帧时间。需逐typed→raw→lookup与控制recapture排程后才核持续camera/HDMI/QoS（A3-04）。

### F4. RTL A–L与跨语言

| 项 | 设计契约/未知 |
|---|---|
| A数值 | 全identity无截断；index32×recordbits10先42bit，index+count先33bit，base32+offset+len先至少33bit；核真实物理高位/对象half-open/end再收窄，满计数拒绝不回绕。6bit reason/3bit state非法编码明确拒绝。 |
| B时钟 | 单core posedge候选；沿前旧fire，沿后新寄存器，下一接收沿采样；仿真观察post-NBA且保存pre-edge事务。 |
| C接受 | valid&&ready&&!rst；BEGIN/WORD/lookup独立槽，full不能借本沿pop预支空槽；旧held不因fence取消。 |
| D有效 | valid0不等数值0；installed/returned与cachevalid独立；padding0且bodyvalid最后发布。 |
| E反压 | 所有reply/admin/typed旧body与identity保留；内部配置变化不改heldrevision；不可暂停输入不能凭此cache保证容量。 |
| F时间 | E2/E3/E4逐沿与F3issue区分；未证明固定phaseclose时间及全机吞吐。 |
| G复位 | 同步高禁fire/accept；warmepoch不能清序列和旧债；完整外部隔离桥OPEN，native RAM不强制reset整阵。 |
| H配置 | phase/permission由真实owner事件采样，全记录写完snapshot_valid提交；同时旧request fire仍按旧revision办理，后续再改。 |
| I存储 | F1 M1共享1R1W/native20×512，no同址读写；32cache固定、3stage与5child，unknown占额；不能给M1两consumer各许一读。 |
| J身份 | 完整JID/H/namespace/gen/revision/ref/version/grant/tx seq对齐；零operation合法、零generation非法。 |
| K CDC | 新单元无CDC；production camera/DDR/HDMI跨域桥由各原卡，本卡不能当CDC证明。 |
| L实现 | Ti60F225/Efinity候选SV；100MHz未证；11RAM组织与15845selected bits为计算，不是map/PNR；phase/ledger/端口/完整FF/DSP及fair服务OPEN。 |

C++本轮N/A：不生成数学或可执行协议模型。未来独立参考需分别判定共同数值身份/地址规则、硬件旧fire/hold/fence规则、原typed事务到lookup/permit/effect/RETURN的一对多对应，不从未来RTL内部cache控制生成同构oracle。参考不得用cachevalid判pin释放。

## G. 实施与验证计划（尚未执行）

允许下一步只有联合设计审阅/补齐A3→新版本读回。将来获批后按 REGISTER/native→fullbind/capture→普通lookup→fence/转换→分child close/retire增量实施；任何源/接口/资源边界差异先修设计。拟符号 `stage_registry`、`stage_capability_lookup`、`stage_permission_barrier` 为职责计划，不强制三个RTL文件；本轮没有这些源码。

| TEST | 场景、期望与依据 | 状态 |
|---|---|---|
| SC-T01 | H operation0及同H跨namespace，gen0非法；next=max一次后exhaust，FREE不复用ref。依据SC-01/D1原H与DIRgeneration。 | NOT_RUN |
| SC-T02 | fullLG56/CLJ22/RJ113词、错length/index/last/padding、M1RESULT仲裁；lastwrite沿绝不ACTIVE。独立字段布局与F1地址作oracle。 | NOT_RUN |
| SC-T03 | BINDING partialgrants、wrongecho、retain0G不存在；只有真实原bind/prepare消费后ACTIVE。原LC/CLJ/RJ及LOAD新增来源联合核。 | NOT_RUN |
| SC-T04 | hit/miss、fulltuple错一位、stalegen/revision、越界/42bit乘法/末词/RMW full16B；miss不减count，STOREdynamic仍生效。 | NOT_RUN |
| SC-T05 | actor oldheld在fence沿、旧fire同cancel、response反压/permit子借用/16journal effects；全部履约后才失效，新publication排队。独立promise/effect事件scoreboard。 | NOT_RUN |
| SC-T06 | CLASS CLOSE先RETURN再ACK、SRC/G仍closing；RETURN_ACK不得等wholeholderRETIRE。对比原ACK502、并行typedprovider真实ledger。 | NOT_RUN |
| SC-T07 | POINT WRITE→READ、新独立grant/version/revision；oldpartial/returnedmetadata没完不叠新pin；immutable COMMIT无writer。 | NOT_RUN |
| SC-T08 | retain1GC CLOSE→RETURN→CLOSE_ACK消费→parentO COMMIT→GCterm，retain0没有该链；COMMIT不能再ordinarywrite。 | NOT_RUN |
| SC-T09 | R4Cstatus1与RCstatus1证书差异、wrongclosecounts/overflow/lateRSP；只真实已闭合债更新，错误Q不free。 | NOT_RUN |
| SC-T10 | fivechild/parentoriginalheld/query/control/native全空以后后续沿metadataretire；returned占原quota、cachemiss无释放证明。 | NOT_RUN |
| SC-T11 | reset/warmepoch/隔离、全局序列max、旧transport晚回、phase更新与lookup同沿；无backdoor原权限mutation。 | NOT_RUN |
| SC-T12 | 完整unique-instanceFF/RAM/DSP map、不同scope真实并行native/DDR/continuousI/O排程与无内部未约束，F3计数从独立rawtrace导出。 | NOT_RUN |

测试平台时钟100MHz为将来候选，不是R1 25MHz项目移植；确定性边界逐沿枚举，随机stall/cancel至少保存seed和完整输入hash。仿真数值/协议、综合资源、PNR/STA、bit文件、实体观察分别记录，不能以软件参考或状态名PASS代替其余结果。

## H. 双向追踪

| REQ | MOD / IF / 草图 | 计划职责符号（未生成） | TEST/独立期望 | 实际源码/证据 |
|---|---|---|---|---|
| SC-01/02 | SC-O/PARENT，IF01/02，E1/2 | stage_registry | T01–03，原body与DIRseq | 待实现/NOT_RUN |
| SC-03/07/09 | SC-O/STORE，IF03，D4/F1–3 | stage_capability_lookup | T04/11/12，真实STORE/rawtrace | 待实现/NOT_RUN |
| SC-04/08 | SC-O/STORE/ACTOR，IF04，E3–5 | stage_permission_barrier | T05/07/08，oldpromise/effects原事件 | 待实现/NOT_RUN |
| SC-05/06 | SC-O/STORE，IF05/06，D6/E4 | child_pin_closure | T06/09，原close证书/实际RETURN | 待实现/NOT_RUN |
| SC-06/07 | SC-O/PARENT/ACTOR，IF07，E6 | stage_metadata_retirement | T10/11，原terminal/transport/目录 | 待实现/NOT_RUN |

反向检查：registry因完整body先于grant而必要；lookup因明确D3增量及范围不变而必要；barrier因兑现旧promise而必要；childclosure因CLASS/SRC/G独立闭合避免环而必要；metadataretirement因保持冷identity/quota而必要。原所有者与O都保存真实不同生命周期资料，不能因重名删掉原expected/private state。没有业务代码，故不存在可声称已完成的代码—测试映射。

## I. 设计门槛与评审

①整体B和样例、②C职责连接、③D接口/显式delta、④E中文草图、⑤F语言/几何、⑥D6/E4反例走查、⑦G/H计划均已有可审阅内容；③/⑤/⑥仍受A3阻塞。⑧无当前阻塞条件**不满足**。⑨本卡已保存，最终全文读回后的实际字节/行数/hash在交接消息给出，不将自引用摘要写入正文；⑩v0.1与只设计范围明确，LOAD新卡还未冻结。

因此**NOT_READY_FOR_REVIEW / NOT_APPROVED**，不请求实现批准，不承接R1授权。先由Root联合读回LOAD、SC、资源缺口与原supplierclose，补齐A3后才可新版本READY_FOR_REVIEW，并按既有Approval Manifest批准指定范围/基线。本卡没有写入审批/数据库。

## J. 变更与恢复

这是生产DIRD3从每普通访问冷全查到可验证权限快照的明确行为/流控/存储策略候选；旧合同不能无声改变。旧stage review149词只含LC270，现fullLG1119改191词，涉及M1几何、资源、注册来源；旧7004/9980bit下界不再代表本新字段。只写本卡，不覆写旧来源报告或并行LOAD文件。恢复须重读本卡hash、源hash、完整LOAD新版本与审批状态；若来源变化，记录受影响接口与草图，不沿未批准候选生成实现。

## K. 本轮实录与限制

只读源合同、规范、模板和数值/生命周期检查；保存本中文设计文档。本轮无业务源码、脚本/TB、仿真、综合、PNR、STA、bit或硬件动作。R1已绑定交付只读且不被改为本卡证据。A2范围有限，不声称已全文复核所有项目、完整算法已实现、64pin足够或全机资源/速度已满足。

## L. 人工阅读与交接

先读B了解为什么需要阶段身份与独立关闭，再读C分清O/STORE/actor，D看每项保证和接线delta，E按真实沿核旧promise/RETURN/close顺序，F核字段与native总数和未闭合成本，G/H核可执行验证前要补齐什么。需要改变权限时改D3–D6/E4–E6/F与T05–11；需要改变body时改D2/F1/T02及LOAD来源，不能仅改字段表。

本轮完成的是联合设计候选；正式理解验收待用户实际阅读/反馈，不能把说明已输出称用户已理解。下一步继续联合设计核查与Root审阅，A3关闭后再形成指定READY版本；完整软件目标、生产接口、资源服务与算法质量的验收仍按各原合同推进。
