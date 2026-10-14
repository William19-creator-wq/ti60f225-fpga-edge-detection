# TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001：单实例生产服务、QoS与重叠预算 v0.1

2026-10-05；CONDITIONAL_SERVICE_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。按PLAN_TEMPLATE。只新建本卡，原设计、R1冻结源与五份已验收交付入口保持只读；不生成源码、脚本、模型、TB或可执行测试，不运行构建、硬件、网络或数据库动作。

## 通用计划字段

- Goal：把五camera ring、共享单IMPORT、生产ROW与单CONTROL元数据引擎置于同一个可计算、可检查的服务账；区分真实单实例并行、序列化依赖和待验证最大等待。
- Current state：资源审查已有167/175具名RAM部分小计、63191bit条件逻辑容器、DIR普通串行lookup尺度；R1局部实测已完成。PB/ROW/SCAN/CONTROL仍缺正常有限服务、全机热状态和完整组合。
- Target state：以实际服务参数、完整holder/schema和同一实例调度形成正常采集、1080p60供数、COPY及算法不饿死的可行区域，联合冻结后才READY/指定批准。
- Gap：SB-B01…07见I；本文给必要条件、条件预算与候选调度，不把条件值当实测STA/QoS。
- Assumptions：Ti60F225/I3、SC431HAI彩色、1920×1080、完整Canny/原识别及质量；仅板卡已有资源、允许DDR。显示固定60Hz，采集与算法导入率独立；core100MHz与DDR1.6GB/s仅候选/名义参数。
- Open questions：真实DDR响应/刷新/关闭界、camera到达包络、单route的解包与低优先burst阻塞、所有metadata/CDC消费者界、首行/row1/bank归还、权限快路径与热状态位置。
- Dependencies：A的当前hash；LOAD-GRAD/STAGE-CAPABILITY已保存并仅核本卡所需有限范围，仍为未批准/未联合冻结候选；Root H1-layout delta未存卡核读前仅作候选消息。
- Milestones：流量/单位→唯一engine→服务参数→跨行依赖→期限/容量→完整身份/停止→数值例及验证→联合复审→READY/指定批准→work实现及真实工具验证。
- Detailed steps / State transitions：只推进本卡设计；不更改正式state/ledger/Manifest/DB，不把子局部PASS升级全机PASS。
- Artifacts and hashes：本卡及A来源；实际输出SHA/bytes在全文读回后另报。没有可执行输入manifest。
- Validation：G是文字计划，NOT_RUN；本轮只有精确整数/参数式核算，数值/时序/原语/资源/实机分开取证。
- Failure handling：held履约、旧fire先记，UNKNOWN/Q不复用；超时只定义故障，SAFE/拒绝不作正常服务证明。
- Human approval gates：当前纯设计授权，不申请未成熟版本批准；新QoS/缓存/快路径/握手/存放属于重要结构选择，联合成熟后等待用户批准指定版本/范围/基线。
- Rollback：撤回本卡候选引用即可；不覆盖旧卡、不删除日志、不改R1或原HDK。
- Completion criteria：本轮是保存、全文读回与交根审阅；完整目标须十一功能的真实仿真、综合、PNR、STA及bit，bit后停止。

## A. 来源、状态与采用边界

本会话实际按控制面入口顺序核读config规则/运行提示词/路径、state/ledger/DB README；本轮重核同hash。唯一规范v0.2此前完整核读、当前相同SHA `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`，重读§9映射及模板部分；PLAN_TEMPLATE当前全文分段核读，SHA `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79`。原DB仍未配置；纯设计不启动数据库运行节点。

| 实际来源（控制面相对路径） | 实际采用范围 | SHA256 |
|---|---|---|
| experiments/track4_algorithms_20261004/03_review/production-resource-gap-review-v0.1.md | 前一任务全文191行读回；§3–7唯一实例、逐op、IMPORT/行期限，本轮同hash | 3785F7187E1F1537DBC2B3DCB9EE0A7777D43B11B8F573AEE992FF7F75CED585 |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md，PB | 本轮54–114/138–149逐行；其它为关键词有限阅读。五ring、单COPY、route、最大128拍/RX/关闭与现CLOCK候选 | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 |
| planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md，INT v0.8 | 前一任务1–271分段全文，本轮同hash；59–65/95–142/178/238–243 | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF |
| planning/design-TRACK4-ALGORITHM-PERFORMANCE-001.md，PERF | 前一任务1–396补全读回，本轮同hash；E2/E3/E5/E9/302–310 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 |
| planning/design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md，MR v0.2 | 前一任务1–235全文；62–85/89–123/131–145/157–189 | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 |
| planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md，ROW | 前一任务48–180逐行，本轮同hash；83–104/108–142/150–161 | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8 |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md，H | 前一任务69–149/174–207；118–124族共享/缓存与关闭 | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 |
| planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md，SC | 前一任务67–192逐行；77–85/95–126/132–174 | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md，DIR | 前一任务1–116/118–231有限段；94–112/127–141/151–182 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md，CAP v0.1 | 本轮实际仅184–226逐行；仅引用候选191词/selected15845/单槽最早hit节拍，非联合采纳 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| planning/design-TRACK4-ALGORITHM-LOAD-GRAD-001.md，LG v0.1 | 本轮实际仅301–324逐行；仅引用候选logical数量、cold位置与单credit沿下界，非联合采纳 | 25AFA46EAF11F59C1F2942708E803DCEE3C84B609619B27C2FA8C10E6804B22D |

本卡既不改原DIR D3的pin→descriptor/holder全文查验义务，也不默采未定稿capability快路径。旧RAW地址/目录与生产32bit schema仍须显式联合。原H1 [0x05440000,0x054C0000)与现ring冲突只引用资源审查；**该段不采用、不改地址**。Root消息提出把H1放RC_AUX未分配尾，待其独立layout delta保存/实际SHA与目录/typed/额外pin共同核读后另吸收；本卡不自行授权任何新对象/区域。

## B. 整体外部行为

SB-REQ01：camera每个实际模式帧在预先ARM/reservation下独立采集/封存，不能等慢算法、冻结或OBS；算法仅选择完整源，未选与采集失败分别计。保留真实capture origin/CFG/link、COPY目的与SRC/J/PCTX历史。

REQ02：每个正常显示scan按同源完整planes/历史render及时形成全部1080行；HDMI固定1080p60不暂停。重复旧完整结果仍计60次真实plane读；SAFE/underflow是故障统计，不作为成功供数。

REQ03：单CONTROL、单ROW renderer、单IMPORT和PB保守单已issued物理burst是本卡预算实例。给每一个fresh、held、已accepted、close与metadata义务真实位置、排队与服务界；不为每owner复制引擎或增加匿名queue。

REQ04：f_capture、f_algorithm_import、f_freeze_import、f_algorithm_complete独立。只固定f_display=60；本卡不规定算法1fps、60fps或新场景门。正常已接纳job必须有正且有限的算法/NUM/存储服务，不以超时、容量拒绝或SEARCH_INCOMPLETE维持所谓速度。

REQ05：权限/初始化/latest/原子组/同帧关系与关闭事实不因QoS加速而改变；warm STOP不撤held、不擦effects，父引用和bank各自真正闭合后才复用。未知保Q。

正常路径：camera预ARM→ring封存/latest→按单COPY两目的导入完整RGB→关闭读写并返ring→注册immutable SRC→SOURCE/单J→全Canny/闭包/识别→完整bundle→四exec/行填料与渲染→真实VSYNC采用→持续行扫描→各层独立close/retire/return。COPY只搬bytes，不计算/伪造算法结果。边界路径：前一row输出/本row填料/下一stage权限关闭可以并行，但只有各自旧资格已经成立才推进；无输入FULL不能渲染本行，末R不能覆盖旧route。

## C. 唯一实例和数据/控制/错误连接

| MOD | 唯一职责/状态位置 | 连接和实例边界 |
|---|---|---|
| SB-DDR_ADMISSION | 在提AR/AW valid之前选择一份已合法候选，锁类别/原身份/长度与deadline资格 | 复用实际DDR controller39类块；不是新增PHY，也不让QoS自行授权裸地址 |
| SB-DDR_ROUTE | 唯一旧R_ROUTE、RX128及两decoder holding；独立W_CTX和写holding | PB单burst保守范围；末R/B/新空位不代route/旧effects闭合，holding成本待具体字段 |
| SB-CAPTURE | 五ring/下一ARM、当前writer/closing/latest | camera不可反压；31缓冲候选与CSI11不同实例；COPY不共享camera writer4RAM而免费增加空间 |
| SB-IMPORT | 一个COPY，ALG/FREEZE_FALLBACK互斥，锁完整origin/目的/独立copy_seq | 共用DDR/RX资格；读写各实际计，先保下一CAP，冻结补源不等J/gate/scratch |
| SB-ROW | 两input、一个renderer/writer、三out，完整RowCtx/READ/RETURN | 40payload块含input18/RX7/output15；跨行可并行，同input填/读不能同时授权 |
| SB-META | MR的一套scheduler/engine、CMD966/IMAGE966/ACK61双端、D0/C0两RAM | 一次短事务；原各actor保存未选候选，源/目的实存，不暗加五宽CMD队列 |
| SB-LIFETIME | 原O/CORE/ROW/OUT/FETCH/SCAN各own真实pin/ctx/bank/loan/close事实 | 服务选择不代grant；七owner下级关闭/应用/CDC仍须联合 |

中文连接草图：

```text
camera到达 → ingress/RAW/RGB → CAMERA写ring ─┐
sealed ring → 单IMPORT读ring/写SRC ─────────┼→ 预issue仲裁 → 唯一DDR/R_ROUTE/W_CTX
完整bundle → FETCH读planes → RX/解包input ─┘                    ↓真实响应/effects
                             input A填y / input B读y−1 → 单ROW → out三bank → 固定SCAN
原actor旧pending → 单CMD → MR D0/C0 → IMAGE/ACK → 原actor提交/退休
STOP/错误/close：独立容量先接纳 → 履约旧held/issued → 分层真quiet；不等数据队列空
```

整体检查点：只允许不同实例/不同bank/独立已保留运输槽重叠。同一MR job、same-bank写读、同一COPY第二目的、未关闭route和新route均不能重叠。未知并行条件列SB-B02，不以示意图证明吞吐。

## D. 参数、接口与组合检查

### D1. 单位和完整流量

N=2,073,600 pixels，P=1,036,800 pairs；RGB一帧6,220,800B、GRAD32N=8,294,400B、CLASS2N=518,400B、EDGE N=259,200B、ANN2N=518,400B。logical bytes、16B AXI data beats、burst、native RE/WE、metadata job、NUM调用与core周期分别计。

| 参数/派生 | 合法意义与计算 | 保持边界 |
|---|---|---|
| f_c | 实际capture模式的完整帧率/到达包络平均项，≥0 | 未冻结实际SC431HAI模式；不能从HDMI60推camera60 |
| f_A / f_F | 单COPY ALG / 冻结补源实际接纳率，≥0；f_i=f_A+f_F | 同copy只一个目的，显式重算/同capture去重另核；f_A不等成功完成率 |
| f_d | 60次完整显示扫描/s | 2200×1125、pixel148.5MHz/pair74.25MHz；每行14.8148148µs |
| F_core / η | 实际生产core Hz及有效DDR data效率0<η≤1 | 本卡100MHz/nominal1.6GB/s仅算例；η必须实测或有真实有限服务合同 |
| B_display | mode5最坏27bit/pixel，419,904,000B/s；每行6480B/405beats | 最坏仍需读RGB/EDGE/ANN；show关不取消完整资格 |
| B_capture | 6,220,800·f_c B/s写ring | CRC/control/物理rounding/命令等待另计，RAW10到RGB算术服务也另计 |
| B_import | 12,441,600·f_i B/s读ring+写SRC | 不只计目的写；完整读/写各388800beats；128量子每方向3038burst，最后64beat |
| B_algorithm | Σ实际job率×其全阶段真实physical bytes/effects | 包含SRC再读、CLASS/GRAD、BFS/QUEUE、POINT及RC多遍/表/journal/RMW；不是只计logical tiny record |
| B_other | 选定通信/观察、回读、padding/CLEAR等未入上行的真实data | 不重复算已在B_algorithm的postimage；未选GE不自动加入主链 |

必要平均条件：`419904000 + 6220800·f_c + 12441600·f_i + B_algorithm + B_other < η·1600000000`。PB70已有完整camera/COPY/display式；PERF289的camera+display情景不能单独作为全服务证明。若f_c=f_i=60，则前三项1,539,648,000B/s、必要η>0.96228且未计算法/其它；这是条件尺度，不新增60fps导入要求。用参数式可求 `f_i < (η·1600000000−419904000−6220800·f_c−B_algorithm−B_other)/12441600`；分子≤0时该情景不可行，不得改正常统计掩盖。

当前五ring/六SRC/三结果的arena124.25MiB是容量候选；f_i通常由单J/scratch、完整处理/返还、SRC空槽及冻结意图决定，不为赶平均带宽强制每capture import或擅设低fps。capture closing≤1与ring reuse仍需D4服务/寿命证明。

### D2. 服务参数与候选QoS合同

定义每类别k∈{DISPLAY,CAMERA,IMPORT,ALGORITHM}的有限data服务包络 `β_k(t)=r_k·max(0,t−ℓ_k)`：r单位B/s，ℓ单位s；仅在实际合格backlog、校准/健康正常、消费者已预留且按界消费时承诺。必要`Σr_k≤η·1.6GB/s`、r_DISPLAY>419.904MB/s、r_CAMERA>6.2208·f_c MB/s、r_IMPORT>12.4416·f_i MB/s、r_ALGORITHM>0，并核算法实际工作量；正平均率之外还须deadline/最大不可服务间隔。

`ℓ_k`必须包含一个此前已published/issued不可撤事务、slave ready/firstR/B、refresh/rowmiss/turnaround、route排空/decoder引用、metadata许可及仲裁停顿；不能把nominal一beat/core写成已验证连续R。额外定义：`A_max`=AR/AW held最久接纳；`R_gap_max`=合法burst内响应最长gap；`B_max`=末W到匹配B及可见性最长；`Q_route(n,plane)`=从选定burst到旧route真实可复用最长；`C_ack_max`=本地metadata接收/核验/复制/ACK最长；实际值全部OPEN。

候选选择策略（新增设计，未实现）：只在**未提public valid**的完整fresh候选中按最近真实视频期限与camera水位/reuse期限选取，保留IMPORT/ALGORITHM正的保底服务配额和最大grant间隔；不要只用display>camera>algorithm无限严格优先。低优先新burst只有在其已证明nonpreemptive阻塞界＋guard不侵占最近硬期限时才publish；最大低优先量子q_L可取≤128的参数，研究32或更小，不变成新并发channel。q=32会令一次COPY每方向12150burst（总24300），比128的总6076更大命令成本，须重新算η/等待；不能只计降低阻塞的好处。

一旦AR/AW/W/typed request valid已形成，held体与类别/身份固定直到真fire；deadline变紧不能撤掉它或换成current ROW。已经issued的旧burst先履约、读数据按原route移交，write/B/effects真实结账，才重新选择。不从AXI ID4推出16并发；若单burst候选不能满足可行区域，必须在批准前修订有界多route/credit/端口/资源设计。

close/error/STOP有独立接纳槽、sticky和状态；它们不能抢掉旧data response，也不能因数据满无处接纳。效果关闭和最后cache/目录退休可独立前进；给予close/metadata明确最坏等待与有限配额，不能“close永远最高”饿死行，也不能等display空闲才允许旧effects收尾。共用MR/RAM/native端口的每份job实际计入单实例总利用与nonpreemptive阻塞。

### D3. 接口合同与身份保留

本卡不新增可编译端口或packed业务消息。下列是需要共同冻结的内部交接语义，当前完整schema/actor接线为SB-B04；不能提前拿摘要/裸地址作为原权限。

| IF | 提供方→使用方 / 已有完整身份和数值 | 接纳、保持及组合要求 |
|---|---|---|
| SB-IF01 QUALIFIED_CANDIDATE | 原CAMERA/COPY/FETCH/STORE→预issue仲裁；完整原请求、实际ref/version/pin/namespace/长度/类别和历史deadline | 原请求仍在其真实源held/private；新valid只在接收空间/旧权限成立后形成。调度ticket/index不授业务权限；坏echo保真实债 |
| IF02 PHYSICAL_ROUTE | 仲裁→PB R_ROUTE/W_CTX→RX/decoder/写holding；原owner/对象/plane/byte范围/beat序/LAST/目的 | 16B对齐、SIZE4/INCR/ID0/max128/4KiB子集；AW/W/B与AR/R分别真计，末R不释放引用、末W不settled |
| IF03 ROW_FILL_READY | FETCH/ROW_OWNER→single ROW；RowCtx865/KEY164、INPUT FULL/旧OUT_RESERVE/READ资格 | FULL/末写/全mask旧事实先成立；两个input填与读分bank，完整copy仍借历史ctx；最晚READY另核CDC/OWNED |
| IF04 META_JOB | 原actor→MR CMD966/IMAGE966/ACK61双端，header52/原source914 | 原D0/C0完整record/cache词数、RETIRE/全文比较规则不改；一次短事务，ready仅真实空间，原actor候选/资源pin保持 |
| IF05 BOUND_PROFILE | 设计预算/后续真实观测→各scheduler；F_core、服务率/最大等待/消费者界/原模式与工具baseline | 参数具单位与适用scope，换clock/mode/geometry/profile重算；无实测值不把参数贴常量后宣称通过 |
| IF06 LOCAL_QUIET | 原route/decoder/MR/ROW/COPY→原owner的quiet/START汇合 | 旧held/原pending/child/journal/effects全部真实闭合，warm不清FIFO凑empty；不增加第八epoch owner |

deadline必须来自真实SCAN target/physical时序和历史RowCtx，跨pair→core的相位/CDC守卫要显式扣除；不能拿未观察的target_frame当已APPLIED或直接跨域采多bit。保留完整KEY256、source/target y、bank generation、borrow、COPY origin与其目的；无效/缺图与数据0不同。

DIR D3现为pin512/descriptor640/完整holder查验；32+32真实native读issue/普通op仍可能主导。新STAGE-CAPABILITY一次BIND验证＋immutable能力快照是**未联合采纳的替代设计**，须保全H/role/ref/version/grant/generation、mutation屏障与STORE实时prefix/tail/latest/commit。未批准新快路径前，服务μ_DIR不得静默从64词变成0或1拍；每个FETCH burst/算法logical请求、SOURCE/GRAD reader到底查哪份缓存需明确。CAP222–226的候选initial全查为2239 readissues，grant更新另2048 writeissues；stable普通hit最早e0…e4共4间隔且单槽，不等1次/core。实际Q个内部lookup与recapture/phase/effects须从typed到raw逐项展开，不能拿logical次数直接乘4宣称帧时间。

Root另提出**消息候选、尚无冻结新卡**：把32×295bit能力cache改成单独native20×512 RAM，每行15词、32行480词（若未来33行则495词），保一份约300bit assembly与真实热stage/child资格。冷hit须15个真实RE/capture，再完整check/publish/held与消费者等待，不能仍沿用hot版本4间隔，也不能把15RE当完整reply上界。该候选只针对stage-kind权限路径，不能默认改R5的非stage-kind通路；算法实际Q个lookup及shared端口/phase服务必须重算。额外一RAM及其热assembly/locator/控制去重另入完整实例账；未联合冻结前不修改CAP原hash或本卡任何已证预算，不新增算法fps门。

### D4. 累计入出、ring复用与IMPORT界

对camera不可暂停包络α_c(t)=σ_c+ρ_c t（记录或byte单位先统一），normal容量须满足 `sup_t[α_c(t)−β_c(t)]＋在途/拆record/预约 ≤ 真实ingress/holding容量`。CAM_ITEM220×1024不是1024RGB pixel，RAW/RGB拆/packing及峰值要按实际mode定；50MHz四pixel/沿只是峰值条件。FIFO深度不能抵无限服务停顿。

五ring的正常同时角色仍writer1/closing1/latest1/COPY1/future ARM1，不能靠这个表自证closing≤1。必须给真实nextSOF时刻、receiver/CRC/write/B/可见性/通知最长关闭、latest替换与COPY返pindeadline，并逐slot演化保证下一ARM有真实FREE reservation。完成COPY不等immutable SRC能立即复用；六SRC lease/三结果/OBS/冻结/closing元数据另核正常容量。

单COPY对齐全RGB在q=128时读3038burst、写3038burst、data共777600beats；最后两方向各64beat。独占nominal的7.776ms只是byte理想时间。保守chunk流程：锁完整R_ROUTE→收读burst/RX及原响应→W_CTX独立锁旧chunk→从旧RX/holding喂全W→匹配B/可见性及旧refs/effects关闭→后续chunk。R物理响应结束后W可推进，不能等整个COPY commit才放route；同时不免费增加一套camera writer bank供COPY。

若IMPORT有真实r_I/ℓ_I和有限本地处理/关闭界，可条件预算 `T_copy ≤ ℓ_I + 12441600/r_I + C_import_local/F_core + T_visibility + T_readclose + T_writeclose + T_register`，其中服务包络r_I已包括物理burst阻塞/仲裁者，不再把同一等待重复加。若按逐burst界求和则改用6076个相应服务项，不与上述r_I重复；CFG/PCTX/SRC许可、purpose、CRC/数量及cancel未知效果仍保持。只有该界小于被pin ring的真实reuse deadline，且camera下一reservation有界，才可作正常接纳证明。

## E. 单实例微时序、真正重叠与可行区域

### E1. MR最早间隔与已知单行占用

沿用MR184–189：e0 CMD fire；写L词e2…e[L+1]、e[L+2]提交、e[L+3]形成ACK，下一CMD最早e[L+6]；读最后capture后独立IMAGE/ACK，下一CMD≥L+8；RETIRE≥L+7；MATCH hit≥Lq+Lp+9。它们均是无stall的最早间隔；真实最坏再加接收/判定/消费者/排队界，不能当作实测服务承诺。

| normal operation | 已知最早MR间隔 | 来源/独立义务 |
|---|---:|---|
| REGISTER906 record46+cache92 | 150 | 两job；仅完整两次成功后registered，非每line一次 |
| BULK_OPEN loan23+cache44 | 79 | 原GRANT已被真实O保存；一个exec一次 |
| ASSIGN assoc4+cache51 | 67 | 每真实RowCtx/行一次；先占input/完整ctx |
| FETCH final三body cache52 | 58/实际burst | TERM342→ACK350真消费之后；最多8burst，不能恒定按5 |
| FILL cache34 | 40 | 正确末native写/关闭/TERM已成立 |
| OUT_RESERVE KEY关联9词WRITE | 15 | 正常每输出row一次，out真实资格另核 |
| assign关联4词RETIRE | 11 | 原RowCtx/input/renderer/out普通引用真退出后；正常每行一次退休的稳态条件 |
| outKEY9词RETIRE | 16 | 原bank/ROW_TARGET/旧代次真关闭后；稳态每行一次 |
| BULK_CLOSE cache50 / loan RETIRE23 / registry RETIRE46 | 56 / 30 / 53 | exec尾段真正关闭的额外job，不能藏进每line571 |

最多8burst形状的ASSIGN/FETCH/FILL合67+8×58+40=**571**最早间隔；另正常out关联写/两关联退休42，已知steady MR工作量为**613**最早间隔/行。具体burst数与真实退休时间决定哪个行period承担它，不强令每行8或在错误路径造退休。100MHz例613=6.13µs；按1080×60是39,722,400最早间隔/s，但blank、首行/关闭/其它owner/重放及所有stall仍另计；这个平均占用不能替deadline。

MR当前job即使native锁已放，CMD/IMAGE/ACK/private未真结束也不能接第二CMD；已started longjob的blocking为其**实际最坏job界**，不是Lmax92的98最早数。新普通metadata要有deadline-aware准入、保留close份额与最大消费者等待；若IMAGE/ACK可永远notready则成功墙钟无上界。STOP sticky不等待MR job退出。

### E2. 条件streaming RX界与cross-row流水

既有ROW decoder两135bit holding＋reserved≤2、RGB每record七lane同时WE、EDGE/ANN每record八个16bitword逐沿WE。候选正常streaming界：从一个burst首数据可消费开始，`C_dec(n,plane) ≤ δ_front + max(n·g_R,n·d_plane) + δ_tail`，d_RGB=1、d_EDGE=d_ANN=8，g_R是R/RX实际供料周期上界；已RE下一沿capture，holding有预约，旧值才WE。δ包括真实首RE/捕获、native尾/route证书，未测值OPEN；必须核连续RGB能一record/core、plane末尾不多WE、R满128与两holding安全，不能从720条数据倒推已达到此界。

若条件g_R≤1成立，405 data beats的到达可与720 logical native写真正重叠，数据工作量界为360+120+240=720再加各burstδ/等待。此处不能依赖任意R停顿的slave；若g_R更大，应逐burst用max重新计，不先取720固定值。若实现等待整个burst收完再逐词解包，保守data项至少405+720=1125间隔再加overhead，必须承认期限区间更紧。

跨行合法示意（实例各只有一份）：当前video读out C的y−2；input A经DDR/RX填y与MR ASSIGN/FETCH/FILL推进；另一input B已经FULL，单ROW读y−1并写一个已预留out；MR的out关联与旧行RETIRE在同一套engine内串行穿插。ROW读银行与新填银行不同，RX仍一个，MR仍一个，renderer仍一个；MR本地RAM与ROW payload RAM不同可并行。只有真正input RETURN/ACK/后续FREE后，该input才能填下一行；renderer本行私有P/holding/stage/tail关闭后才开始后继，不能用第四out/第三input隐藏时间。

本行不能与自身未FULL填料重叠render。已发表ROW的完整body交给对应bank/OUT的原独立held后，renderer可释放自身私有流水；若实际owner必须等待ROW/OWNED才能释放，增加μ_renderer_release，不默认0。FIFO物理锁释放不等旧ctx/loan/base可复用。

### E3. 参数化逐行可行区域

取`L=floor(F_core·14.8148148µs)−G_phase`，G_phase含core/pair实际相位、deadline跨域观测守卫。100MHz且G_phase=0的纯算例L=1481；不能用1481.48148小数周期发原语。定义μ_FILL为实际DIR/holder/plane许可、额外semantic判定/本地运输和未计decoder overhead；J_DDR为全部当前行burst调度/held/refresh/route等待；J_META为其它已经started/更早deadline/必要close job阻塞及消费者等待。

**保守候选A，不修改当前FETCH/cache先后：** 若g_R≤1且MR每个FETCH完cache后才接下一同族新请求，则 `C_fill ≤ 720 + 571 + μ_FILL + J_DDR + J_META`。保持保守序列链，以α/β与实际grant界使剩余项有上界；DIR lookup不免费。纯L1481例仅余**190周期**给上述未知项；如果进一步把42个out/retire占用也顺序压到同一路径，是720+613=1333、余**148周期**。两数只是条件预算窗口，不声称真实刷新/CSI/core可以满足。反之若burst receive与decode不重叠，1125+571=1696已超过L1481且未算等待，A在该实现/clock条件下不可行，应改设计。

`C_render_busy ≤ 970 + μ_OUT + μ_INPUT_READ + μ_renderer_release`，`C_ready_to_video ≤ C_render_busy + μ_publish/CDC/OWNED`；970从已得完整input/out资格的e0算，已知OUT关联15属于μ_OUT里的已计一部分，不重复加两遍。未确定READ/ROW族/CDC界不可填0。steady每line需renderer周期≤L、input补给/返还和single RX周期≤L、MR所有真实job负载及最大等待符合本行deadline，且out消耗/归还保留bank；这些只是必要/组合条件，不能仅把两式取max便证明capacity。

由跨行pipeline可以在稳态使用不同资源的`max(C_fill_cycle,C_render_cycle,bank-cycle)`代替“每行fill完再同周期render”的粗暴相加，但前提为warm-up已完成、两input与三out真实bank状态存在、单ctx/pending/held位置足够、真实周期依赖不互等。首行、bank满与切换必须另验。

**候选B，重要握手/ownership修订：** 若A余量不足，可研究在真正FETCH TERM/ACK350及读route refs已经关闭、完整旧cache source914已被MR CMD目的private真实接纳后，将旧completion值pin转到MR的现有不可变快照；FETCH原data运输槽可接一份下一合法请求，同时旧cache job仍只占单MR。须新增明确的METADATA_TAIL owner/定位/关闭事实、所有重放必须能查旧CMD或cache、旧ACK不能被新请求身份覆盖，且原高水位/取消/epoch纳入quiet。尾ref/state成本及唯一CMD源/目的/ACK保持要列账，不能免费假设第二FETCH slot或五份CMD队列。当前MR/H未冻结此交接，本卡不默称B成立，不提前从571删464。若B合法实现，可把cache工作与后续burst的data/decoder部分重叠，但MR全部613及其它jobs的总占用仍真实存在。

**候选C：** 增core时钟、并行decoder或多route/multiple credits均是新物理/端口/CDC/资源选择；未STA/原语/基线批准前不得用“200MHz”或两个engine闭合本表。完整稳定上下文与权限cache改造也须按D3新卡联合，不能牺牲错误/phase/数量/精度/范围。

### E4. 两首行、row1、fresh/held/close竞争

SC采用首行VSYNC前真READY/OWNED合同：尾段旧bank真实归还后，三out只容oldlast＋candidate0＋repeat0。两首行6480×2=12960B、810beats、1440logical WE/5760lane WE；各自row0仅5burst，不能强套最多8，但其它fetch/metadata、oldclosing与bank释放全是真实竞争。

条件warm-up界应给 `T_first2 ≤ T_loan/register + T_fill0_A + max(T_render0_A,T_fill0_B) + T_render0_B + T_ROW/CDC/OWNED + T_bank_wait`，前提是第二input可用、两个out先真实预留，无法重叠时用求和而非max。与尾段59.259259µs比较只是一个机会窗；真正能起工的时刻在oldbank RETURN/ACK后，窗口可能更小。必须另外证明APPLIED后selected0、unselected0 closing、oldlast closing占满三out时至少一bank及时返回，row1在其真实RE deadline前ready；最坏oldclosing要在下一采用前释放。不能靠丢candidate、只显示SAFE来声称normal通过。

fresh DISPLAY或camera新deadline不能替换已held IMPORT/algorithm请求；close进独立控制槽后只能在已经真实可关闭的局部推进，UNKNOWN保Q。新的metadata REGISTER最多92词write可能跨active期限，是否允许启动要看其已证明不可抢占界；不为紧急row中止旧native write造成半cache。close/cache/transport排空与native锁分别有界；先封新ordinary而允许旧ACK/terminal，否则producer和自己的cache互等。

### E5. 完整算法的串行控制数量与结构下界

LG305–324明确补出生产SOURCE的P个RGBpair read，以及retain1 GRAD的P个pair write＋1个O publication commit。相对旧CLASS＋closure `13N+4=26956804`，retain1合29,030,405个logical data/commit请求、retain0合27,993,604；prepare/ALLOC/INIT/权限phase/close/RETURN与metadata M_i仍另计。RGBpair6B可能跨两个16B span；GRADpair8B小写及CLASS nibble在PB全WSTRB下需要真实packing/初始化/RMW/journal，故这个logical数不能写成同数physical beats或burst。

两个独立depth1 credit允许SOURCE与GC保留各自一份请求，并不产生第二物理DDR引擎。SOURCE下一requestfire最早间隔为 `μ_SRC+4`，GC已有下一合法input时为 `μ_G+3`；μ分别包含真实RSP及物理/permission/transport等待，至少1、上界未知。P次请求仅相邻发起之间的严格结构下界分别为 `(P−1)·5=5,183,995`、`(P−1)·4=4,147,196`个core间隔；首请求形成、最后response/terminal与全部控制债另加。100MHz纯尺度为51.83995ms/41.47196ms，**不是可达到的算法帧时间或新fps目标**；真实允许两路径重叠须同时证物理/journal/lookup/输入/credit与其旧effects服务，不能相加两个下界当全机处理时间，也不能从正名义带宽推出μ=1。

完整处理上界只能在各stage的真实数量q_i、后端最坏服务s_i、一次prepare/close/NUM代价M_i与已证并行依赖闭合后计算，例如串行路径 `T_path ≤ [Σ(q_i·s_i+M_i)]/F_core`；有共享单engine的并行路径另加所有争用且逐实际依赖求完成界。CAP的stable hit是替代权限设计的局部结构下界，LG的5/4是provider路径局部下界，ROW970是局部render既定微时序，均不互相替代。f_algorithm_complete由完整实例/服务决定，与f_A、f_c、f_d仍独立。

## F. 63191bit改善方向及语言/时间合同

资源审查的63191是采用SCAN cold后仍独立实存的条件逻辑body尺度，包含未选存放的RowCtx与运输，不是热FF测值，也不是全机fit/不可能性结论。改存放须逐唯一owner/body实例，不从175块比例推全机可用。

候选方向一：immutable J/PLAN/RowCtx/ROW_TARGET完整body保存一次或按真实域各一份；源held/目的private保有效locator、完整generation/epoch和operation delta，通过明确context lease获得原body。合法条件是原context从发布到所有held/private/native/lookup/返回metadata/cached重放借用真结束前不覆写，任何晚callback用旧generation核；各域需要真实完整CDC/mirror，不能跨域传指针或用“当前J”重建旧身份。目标空间公式必须包含每域body副本、每口locator/delta/valid/pending、assembly、cache与索引，而非只扣重复body。

方向二：五RowCtx865各44个20bit词，220词/4400native bit可研究独立cold record＋有限热id/counters/renderer捕获；现DIR M0/M1空段不能自动装下，原stage149词与新LG191词不同候选。每次完整行lookup/初始化/退还等词服务放入μ_FILL/μ_OUT/μ_retire，不能逐pair重读865bit仍宣称一pair/core。Q/STOP/ARM即时资格继续热；cold读取同1R1W端口有真实仲裁/保护。

方向三：同core actor metadata值转交MR现有CMD/IMAGE完整快照，旧context依lease只保一次；D/C0冷cache值不pin已退资源，但其读取/装配必须仍有完整独立held体。若改串行msg/FIFO以省双端FF，接收不能半body可见、末capture/echo与ticket/旧epoch闭合不可删；新增RAM/assembly/credit/phase/服务均进唯一账。这些是新合同，原CMD源/目的两份、IMAGE两份并非已证明可合一。

方向四：stage一次完整BIND核查＋稳定权限能力快照减少普通op的DIR读，但snapshot只缓存真实不变授权/geometry，STORE实时initialized/validprefix/queue tail/latest/原子组仍核。mutation/revoke封新ordinary，履约旧pending，再失效/重验证；CLOSE/PIN_RETURN不得等自己的ACK先消失、metadata退休另等真实运输关闭。新LG/CAP191词3820nativebit的候选cold占用比旧149词增加42词840bit，M1 RESULT仍282词、新stage到472余39词；CAP selected15845bit另有大量admin/held/effects/transport未知，既不能全加到63191（可能重复已有实例），也不能从63191直接减去整个body。两卡未联合冻结，不能据此宣称不新增RAM或完整热预算已经通过。

| RTL §8.2 | 本卡契约/当前未知 |
|---|---|
| A 数值 | bytes/beat/burst/word/周期分单位；地址32加法33，seq/gen64扩65不回绕；预算用精确非负整数/有理秒，硬件deadline计数宽度及跨域变换SB-B04 |
| B 时钟 | core候选100、pair74.25/pixel148.5/PHY400分域；原posedge沿前fire、沿后提交，RE下一沿capture；未STA不称clock可用 |
| C 接受 | fresh在发布前调度；真实valid&&ready fire，不按坏echo组合撤已fire；camera无ready，预ARM与容量有证明 |
| D valid | 无效不计/访存；data0/EDGE0/ANN0仍合法数据；reserved/pending计真实容量 |
| E 保持 | AR/AW/W/typed/msg/public ROW/CMD/IMAGE/ACK held原体不变，deadline/cancel不重路由；已issued返回有预约槽 |
| F 时间 | MR最早间隔、ROW970、720dec条件界、服务参数/phase guard/行与COPY期限分别记，未知上界不填0 |
| G 复位 | cold须全域/外部effects授权隔离；warm保旧refs/seq/effects/消息，七owner真quiet后START；不清RAM或FIFO凑闭合 |
| H 配置 | capture/COPY/J/PLAN/render/profile/PCTX历史锁定；新shadow只影响后续接纳；服务/模式/clock变更重算旧在途仍履约 |
| I 存储 | 两input/三out/共享RX128/两decoder holding/单MR D0C0/五ring/单COPY，不默认新增队列或same-bank读写；1R1W/capture尾及padding原合同 |
| J 身份 | SOURCE/capture/COPY/J/PCTX/exec/physical frame/rowseq/borrow/pin均独立核，lane/源target坐标不换；locator必须有真实context lease |
| K CDC | READY/OWNED/RETURN/arm/snapshot/下级epoch完整mailbox与授权session；deadline守卫需实际相位与同步延迟，不能多位直采 |
| L 实现 | Ti60F225/I3/SV2009/现装Efinity候选；单engine和167/175非完整资源/STA，真实FF/LUT/DSP/PLL/端口仍OPEN |

C++/Python生产程序N/A，本卡不生成参考实现；静态预算不是硬件执行。共同数值保持原gray/Canny/几何/ANN及copy bytes；执行契约检查真fire/RE/capture/logical_commit/effects/close；对应契约以提前冻结原image/profile/origin/JID/RowCtx/typed seq与真实输出匹配，不从DUT候选日志生成GT或用TB可暂停源证明camera。

## G. 实施与验证计划（全部NOT_RUN）

先关闭I的服务/身份/存放/调度/schema/工具基线，再纳入整包指定批准；只在work实现相关scheduler/adapter/observer/独立protocol reference与工程。拟职责是production_ddr_admission、production_service_ledger、row_service_schedule、metadata_tail_adapter、context_lease_lookup；名称仅计划，不表示已有文件或新增实施授权。新卡纯设计结束后不自动启动工具。

| TEST | REQ/IF/初始与事件 | 期望/来源与观察门槛 |
|---|---|---|
| SB-T01 | 全量流量；60Hz重复同图、fc与fi不等、冻结补源 | 独立physical trace计camera写/COPY双方向/显示/算法/RMW，不重复或漏计；f完成与接纳分开 |
| T02 | 单burst128/4KiB/最后64beat、q32比较、R/B延迟/refresh | 记录真实最长held/gap/route/effects等待及η；不得只看平均byte率，实际profile绑定 |
| T03 | active近deadline时oldIMPORT AR held、oldwrite等B、算法持续backlog | 旧身份/valid稳定，未来fresh不能覆盖；DISPLAY/CAMERA期限与I/A有限正服务同时满足，未满足判失败 |
| T04 | MR REGISTER92词、IMAGE/ACK慢、FETCH cache与行串行 | 仅一CMD/一次job；真实最坏间隔/阻塞/consumer界，不以98最早值代最坏；STOP独立接纳 |
| T05 | gR多档、首RE/native尾、同bin/RX128/两holding、720/405/2880 | 真实READ/capture/WE时序与容量按原语；有停顿重算Cdec，不把同沿新R用来FULL |
| T06 | fill y/render y−1/scan y−2、bank返回晚、renderer heldROW | 两input三out/单renderer/单RX实际同寿命与full旧资格；Cfill/Crender/CDC各值成立，无免费bank/engine |
| T07 | 最多8burst行y34/187/750与首行5burst、MR各退休/close | 实际CONTROL任务全数计，571/613口径与真实归属一致，RowCtx/OUT原资格真实退休 |
| T08 | two future首行、oldlast、APPLIED后满三out、row1/nextoldclosing | 首行VSYNC前ready、后继RE截止正常全图；SAFE/late/漏行不能PASS |
| T09 | fc实际突发、camera closing跨SOF、COPY最久pin/latest替换 | 累计入出不溢真实容量，五ring真实演化/下一ARM可达，失败与算法skip分开 |
| T10 | candidateB原TERM/ACK真闭合、CMD接纳、late cache/新同seq、cancel/warm | 未冻前不执行；context转交/metadata-tail完整旧身份与查重，高水位、关闭/Q无环，无第二匿名FETCH/CMD |
| T11 | cold/contextlease/快照、wronggen/epoch、phase mutation/返回metadata | 全原请求可回读核验；无当前J替旧callback；lookup等待入服务预算，cachemiss不释放pin |
| T12 | dynamic源/完整算法GT、全机map/PT/PNR/routeSTA/bit | 正常质量/范围保持，所有未知实例真实映射、clock/pin/CDC覆盖；局部R1与名义DDR不代全机 |

验证预置实际MODE/profile/原图/GT/hash、clock、固定种子/停顿/故障日程、每口comparison真实计数、最大等待和有限timeout；目前未冻结故G仍NOT_RUN。timeout不能制造成功关闭；必须同时查实际数值/身份/期限/容量/effects。

## H. 双向追踪

| REQ / 来源 | MOD/IF/中文步骤 | 拟职责（未生成） | TEST / 当前证据 |
|---|---|---|---|
| 01 PB30–70 | CAPTURE/IMPORT，D1/D4、E2/E4 | capture/service_ledger/import | T01/02/09；静态流量/生命周期候选 |
| 02 ROW/SC deadline | ROW/DDR/META，IF03、E2–4 | row_service_schedule/physical_adapter | T05–08；970/571/613条件预算，非实测服务 |
| 03 MR/PB singleton | META/ROUTE/IMPORT，IF01/02/04、D2/E1/3 | admission/metadata_tail | T02–07/10；唯一实例与待修订握手 |
| 04 原范围/质量 | 全链/保底份额，D1/2、E3/4 | service_profile/algorithm_trace | T01/03/12；参数可行区域/无新fps |
| 05 DIR/MR/SC关闭 | LIFETIME/contextlease，IF06、D3/D4/F | context_lookup/epoch_adapter | T04/10/11/12；完整身份/refs/effects原则 |

反向每项新职责只承担原输入、同源结果、真实服务或关闭；未来实际文件/符号/hash/测试补入本表，不用空泛需求合理化新功能。H1-layout原对象/地址变化由Root独立delta负责，本卡不反向授权。

## I. NOT_READY门槛与下一项允许行动

| BLOCKING | 影响与下一个具体数值证据 |
|---|---|
| SB-B01 | 实际DDR η/Amax/Rgap/Bmax/refresh/可见性/无未来effects、core/pair/PHY clock与STA未知；需匹配IP/器件、合法服务profile及真实受批准软件验证，名义值不足 |
| B02 | gR/decoder界、单route/holding与MR最坏consumer界、同域native仲裁未冻结；需完整微沿/credit/占用及候选A可行区核算，若不足明确改B或C设计 |
| B03 | actual camera mode/突发、closing≤1/预ARM/COPY pinreuse、SRC/lease正常容量及DISPLAY twofirst/row1/稳态最坏期限未证明；用真实状态寿命和累计服务共同预算 |
| B04 | QUALIFIED/BOUND/METADATA_TAIL/contextlease、完整copy/ring holder、deadline跨域/seq计数位宽及七owner关闭schema还未联合；不以本文抽象IF代实际packed端口 |
| B05 | 63191逻辑body真实cold/held/private/assembly/即时hot、全部RAM/FF/LUT/DSP/PLL/CDC未落位；next逐唯一实例/真实微服务，不能用175fit |
| B06 | LOAD-GRAD/STAGE-CAPABILITY已有限核读实际hash但未联合冻结，H1-layout未实际核卡，本卡不默认采用；后续全文读回、逐差异/mask/权限/布局/资源/时间共同审查 |
| B07 | 全算法M_i/r/w/NUM实际步骤、生产fixture/profile/GT/文件工具及成熟整包baseline未完；需保持原质量范围的参数化完整job处理式和正常服务情景 |

规范10.3：①B整体/正常边界；②C唯一职责与依赖；③D候选IF/参数及相容差异仍有B04；④E旧状态微时序/中文草图；⑤F A–L与三份契约；⑥B/D/E走查及G文字场景；⑦G/H有追踪；⑧B01…07未闭合；⑨本卡保存、全文读回/实际SHA另报；⑩v0.1范围与A输入明确但新依赖未冻结。保持NOT_READY_FOR_REVIEW，不请求用户批准不成熟范围。

## J. 变更与恢复

本卡新增参数化QoS、active/尾段期限及cross-row条件预算；candidateB改变FETCH data结束与metadata-tail的身份/接纳顺序，immutable context lease/权限快照改变存放/查验，都不能按内部优化继承旧实施批准。candidateA尽量保持原cache顺序，但服务值和真实生产schema仍要联合；实际原R1批准范围有效不重复询问。

恢复时先核A/新依赖hash和当前用户边界、旧held/effects/refs/allocator与真正批准，不覆盖原设计；任何被观测超界/带宽不足先记录设计/实际反例，修订具体scope而不调期望或抛掉难例。H1/ring冲突仅等待Root新布局delta，不使用旧冲突段也不借消息授新pin。

## K. 本轮实际记录

只读来源与静态精确整数/参数核算；单COPY beats/bursts、CONTROL613/行周期窗口由本机现有PowerShell表达式算得，未保存可执行分析程序。本卡没有业务代码/TB/scripts、sim/map/PT/PNR/STA/PGM/bit/硬件/网络/安装/许可/数据库或正式状态变更。已完成R1实测仅由原证据承担，本文NOT_RUN。新卡源hash前后核与全文读回另反馈Root。

## L. 中文阅读与交付

先B看正常完整camera/算法/显示边界→C看唯一engine和bank→D1逐字节流量/D2服务参数/D3完整身份/D4环与COPY→E1单MR真占用/E2真实跨行/E3可行区域/E4首行与收尾→F存放改善的身份条件→G/H→I缺口。可读示例是“y−2在扫描、y−1已经FULL渲染、y正在另一input填料”，不能把“y尚未FULL却同时渲染”称优化。当前完成纯设计候选，未证明正常全机fit、处理速度或连续IO；用户理解验收待真实反馈，未来bit后由人下载/观察。
