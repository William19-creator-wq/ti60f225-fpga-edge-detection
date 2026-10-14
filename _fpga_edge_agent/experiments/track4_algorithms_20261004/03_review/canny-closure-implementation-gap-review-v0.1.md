# 完整 Canny 八邻域闭包：实施缺口限定审阅 v0.1

2026-10-05；任务 `CANNY-CLOSURE-IMPLEMENTATION-GAP-REVIEW-001`。按唯一根 v0.2 与 PLAN_TEMPLATE 压缩组织。`READ_ONLY_REVIEW / NOT_READY_FOR_IMPLEMENTATION / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN`。仅本新报告可写；R2 v1、48 输入基线/快照、R4C、LOAD/GRAD、其他设计、R1、源码、数据库及正式状态均只读。

## A. 结论、边界与实际来源

本轮结论：**精确八邻域 BFS 的集合规则和逻辑协议已有可检查设计；最接近实施的缺口是“同一真实 S 的 32bit/16B 后端适配”、“CLASS 初态与 EDGE 不可变发布的目录/holder 接力”、“这个有限实体的微调度、资源和独立验证基线”三项。** 缺的并非另换近似算法。当前不能把这些逻辑合同写成已经可综合的存储服务，也不能把局部 R2、R1 的证据称为完整 A4。

### 通用计划字段

- Goal：定位当前完整 1920×1080、全部强种子、无限定链长/轮次、完整 N 容量队列及全 N EDGE 导出的最关键实施阻塞，提出一个有限、可审查的设计增量。
- Current state：当前 R4C v0.2 全文 346 行、LG v0.1 全文 393 行、PERFORMANCE v0.2 全文 396 行、PB v0.1 全文 162 行已实际读回；其余采用来源为下表限定范围。没有新业务实现。
- Target state：后续将下面 ΔCLOSE-01 的字段、实体、每操作沿表/资源表和验证权威冻结成指定设计，独立审阅后提交具体批准；本报告本身不变成批准卡。
- Gap / Open questions：A3 的 C-GAP01…03；未来生产摄像/HDMI、RC、R3、完整目录/QoS 保持各自 OPEN，不降低原要求。
- Assumptions：单 J/单 scratch、一个逻辑 S 写会话、静态偶 W=6…1920/H=5…1080，生产固定 1920×1080；只使用板卡现有 DDR；无算法 fps 新门。成功有限时间须真实有限后端服务及有限消费前提。
- Dependencies：R4C/C0/R2、LG、DIR、RAW 的原子/关闭语义、INTEGRATION 的显式地址迁移、PB 的物理子集及真实 DDR public wrapper；规范门槛保持。
- Milestones / Detailed steps：整体集合与数量→实际桥反例→一个有限增量→逐接口/操作/资源→独立验证与追踪→根审阅；没有实现/EDA 里程碑已经执行。
- State transitions：仅报告候选；不改 PROJECT_STATE、TASK_LEDGER、Manifest、审批版本、硬件状态或 DB。
- Artifacts and hashes：A2 是实际来源；本报告保存后全文读回的 hash/bytes/行数另报，不自含自身 hash。
- Validation：本次是实际文件读取、字段/地址/容量整数核算与设计反例；所有模型/TB/仿真/综合/PNR/STA/bit/实物均 NOT_RUN。
- Failure handling：保旧真实 fire、S logical_commit、不同前缀和 UNKNOWN；独立 close 不能等待 credit/父 retire，错误/Q 不授发布或复用。
- Human approval gates：R2 v1 的审批尚未收到用户批准；R1 批准不覆盖 R4/LG。本报告不要求泛化批准。未来完整指定设计及共同基线获批后才生成业务源码/模型/TB/脚本、运行工具。
- Rollback / Completion criteria：只交付本报告与可检查的下个设计边界；撤候选不回写旧来源。全文读回、来源核对和根交接完成报告任务；不称完整 Canny/整包完成。

### A2. 实际采用来源（行号为本轮实际阅读范围）

报告内相对链接从本目录回到控制面；SHA 为本轮实际计算。来源状态均按其原文保留；有限阅读不是全文阅读。没有 Git commit，不伪造。实际入口按 AGENTS 规定依序读 config/AGENTS、AGENT_PROMPT、PROJECT_CONFIG、PROJECT_STATE/TASK_LEDGER、database/README，再读 Manifest/规范/模板；正式 DB 仍 NOT_CONFIGURED，未访问 DB。

| 来源 | SHA256 / bytes / 总行数 | 本轮实际阅读与采用 |
|---|---|---|
| [唯一规范 v0.2](../../../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2` / 61102 / 919 | 全文1–919；截断段896–919补读，§2.2/6/8/10.3/11证据与范围 |
| [PLAN_TEMPLATE](../../../planning/PLAN_TEMPLATE.md) | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` / 10341 / 154 | 全文；通用字段与A…L |
| [R4C v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | `5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11` / 63263 / 346 | 全文1–346；集合、LC/CLJ、STORE、phase、CLOSE、终态、原子性及全N导出 |
| [LOAD/GRAD v0.1](../../../planning/design-TRACK4-ALGORITHM-LOAD-GRAD-001.md) | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171` / 67457 / 393 | 全文1–393；LG1119、真实三scope、无重复grant、close后GRAD publication、191词与工作量 |
| [PERFORMANCE v0.2](../../../planning/design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | `A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469` / 58487 / 396 | 全文1–396；D5地址、E2逻辑工作量、E3服务条件、非fps承诺 |
| [PB v0.1](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | `0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40` / 26058 / 162 | 全文1–162；唯一issued burst、16B/fullWSTRB、R_ROUTE/W_CTX与真实B/R/健康/关闭 |
| [production-directory](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA` / 34598 / 231 | 69–158；固定base、descriptor640、pin512、holder、journal576、初始化和无writer发布 |
| [STAGE-CAPABILITY](../../../planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7` / 43441 / 298 | 90–178；原typed BIND建立唯一pin、RETURN/admin分离、CLASS→CLO不等wholeLOAD退休 |
| [STAGE-CACHE-RAM](../../../planning/design-TRACK4-ALGORITHM-STAGE-CACHE-RAM-001.md) | `487576F7A4DE4B0C3CBAB21ADDF09271ABD1C1E6E1BE6C9DD2BC5146697277E2` / 46599 / 335 | 170–212；冷cache21/23间隔、WRITE38、fence/oldpromise；候选未自动采用 |
| [RAW v0.2](../../../planning/design-TRACK4-ALGORITHM-RAW-STORE-001.md) | `7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD` / 64846 / 367 | 104–227、228–276、350–367；130–145补读截断；仅采用typed/raw分层、journal/latest/INVALID_SETTLE，不采用PC生产存储/旧26bit物理路线 |
| [INTEGRATION v0.8](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md) | `C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF` / 51540 / 271 | 119–143、150–164；DR713/731/AP472迁移、旧DDR族不直接接线、typed/raw关闭分别证明 |
| [R2 v0.3](../../../planning/design-TRACK4-ALGORITHM-R2-001.md) | `416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2` / 29268 / 224 | 61–150；CJ142/FP74/CLASS125/GRAD185/CS592、七必需口/retain与唯一C0 owner；旧“未实现FE”时态不作当前R1事实 |
| [原CANNY v0.4](../../../planning/design-TRACK4-CANNY-001.md) | `224779F89206F4113CB0764617401E96ED53D7CF34DBD43FBB60A800A54C8729` / 49248 / 313 | 52–93、141–211；数值/集合与旧cache/queue资源仅作比较，917bit/旧缓存/phase不继承 |
| [实际C2 DDR parameter](../../../work/active/track4_ip_precheck_20261004/C2/rtl/ddr3_controller/ddr3_parameter.vh) | `688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80` / 972 / 54 | 全文1–54；AXI32/128/ID4、DQ16、ASYN1、时序宏存在，不代表运行资格 |
| [实际C2 DDR public wrapper](../../../work/active/track4_ip_precheck_20261004/C2/rtl/ddr3_controller/ddr3_top.v) | `7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A` / 58209 / 937 | 1–155；52–58时钟/reset、101–151 AW/W/B/AR/R与WSTRB16；未读/解密protected内部、未运行 |
| [当前Manifest](../../../config/APPROVAL_MANIFEST.yaml) | `7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D` / 6558 / 106 | 全文；只有既有预检/R1 scope，不把纯设计/R2待批当R4实施批准 |

本轮还搜索/计数了 C2 frame_buffer 文件定位public链，未采用 axi_ram.v 的仿真RAM/常量OK响应作为 DDR slave 事实；它不能补 PB-B01。未进行网络/datasheet外查、工具或硬件操作。

### A3. 按阻塞力排序的三项

| 当前阻塞 | 真实证据与最小反例 | 当前实施影响 / 可闭合动作 |
|---|---|---|
| **C-GAP01 实际S→DDR bridge未冻结** | R4C44/119–153/147明确latest/atomic/phase真实backendOPEN；RAW115–116还是AP466/address26、RQ707/RSP725；INTEGRATION138–142只是DR32bit候选；PB74–80 fullWSTRB、B后可见/无未来effects未证明。QUEUE base62128128=`0x03B40000`，合法entry1,245,184对应地址67,108,864=`0x04000000`，旧26bit截断为0，落入SRC0而非QUEUE | 必须共同冻结DR_KEY201/RQ713/RSP731/AP472、同对象rounded16B权限/初始化、两个claim postimage、共享burst/收料身份、effects→typed回复/commit/close。public wrapper有口不提供RQ324语义，不能直接wire两个body |
| **C-GAP02 初态/独占/不可变publication与父history未接通** | LC270只含CJ/load/Cref，LG139–157补fullJ/source/admission/Gref；SC104不准REGISTER先授pin，SC172 CLASSclose后才能CLO bind且不等wholeLOAD FREE。R4C232是EDGE_COMMIT后CLOSE；DIR139 COMMITTED必须无writer，SC138 CLASS初始commit非immutable。若把op5 token直接置COMMITTED而writer仍1，违反DIR；若等holder RETIRE才可COMMIT/close，又形成环 | 显式LC→CLASS initial certificate→RETURN/ACK502→LCterm→CLJ/fullholder exclusive重绑；S phase token与O immutable publication token/版本各自身份。父实际保存CS/三term、GRADtoken、CLO终态；不能从同CJ或裸ref推授权，也不能修改原公共body假装已兼容 |
| **C-GAP03 有限实现实体/微时序/资源/验证权威缺失** | R4C285/308明确未来文件/精确case/seed/deadline/schema仍B05；LG303/311–324未合SRC/GC/transport/服务；DIR151 fullpin/fullholder逐词，SC hot4与新cold21/23不能混。13N+4只逻辑次数，REQ数量≠DDR拍数≠周期。没有选一个真实sequencer/存储模式，无法准确写实现或判正确 | 下一设计必须以单S+单物理adapter的操作表、真实持有槽/冷RAM/热FF/LUT/DSP清单、独立全N oracle/事件台账、有限故障与恢复套件及运行政策收敛。实际仿真/STA为获批后执行，不能倒置成审批前先运行要求 |

R4C B03/B04 中 RC/ANN/完整bundle/video 仍是未来总系统任务；不是为了实现“完整闭包核”必须同时先实现整个识别和HDMI。当前必需的CLASS初始资格/底层S/对象访问与关闭不能以未来范围名义跳过。三项可由纯设计闭合，是否随后实现仍须具体批准。

## B. 整体行为及完整数量

保留R4C54–70：初态00 NONE、01 WEAK、10 STRONG、11非法，外框00；所有强种子先接纳为11，之后精确八邻域可达候选才接纳一次。邻居顺序NW/N/NE/W/E/SW/S/SE；原坐标先signed13加偏移/核界再算yW+x，不跨行。全队列非环N entries；head≤tail≤N，head=tail仍有active_pop或pending时不能结束。

生产N=2,073,600/P=1,036,800。CLASS518,400B、QUEUE8,294,400B、EDGE259,200B，合9,072,000B逻辑容量；不含SRC/GRAD/目录/journal/控制/多槽。沿PERF D5/DIR的固定位置，不改任何旧地址：CLASS `[0x03A40000,0x03A40000+518400)`、QUEUE `[0x03B40000,0x03B40000+8294400)`、EDGE选既有三slot中当前真buildref。地址不是授权；各object/slot/ref/version/holder/pin必须真实核验。

普通例：强种子接有拐弯/斜连接/环/分支的长弱链，全部同候选可达点为1；断开的无种子分量0。NO_STRONG全P显式写0，NO_WEAK全N读取仅10→1，两者仍EDGE提交/真实关闭，不启用QUEUE/SEED/BFS。失败保不同raw/good/stored/request/rawresponse/settled前缀，不补P/EOF、不发布半图；Q保身份/未知effect，不从超时推FREE。

## C. 一个可闭合的具体设计增量 ΔCLOSE-01（提议，未自动采用）

建议下一张**单一**设计冻结“完整1080p逻辑闭包核 + 32bit串行S后端 + CLASS独占移交/EDGE发布adapter”，先采用可计算、无cache的正确基线。BFS/全N队列/全N EDGE不变，避免同时引入旧8KiB状态cache/append/prefetch/重放与未联合批准的cold capability cache。无cache会增加服务时间，须如实预算；这不是新增低fps验收。

数据路径：真实C0 CLASS125及父唯一CS592→原L/LC270→单S加载/初态证书→本CLASS scope真实close/RETURN→父LCterm/CLJ→单S exclusive CLOSURE→强种子/队列/八邻居→全P EDGE→S durable phase token/close→CLterm→父O immutable publication→未来同源EDGE reader。retain1 GRAD185→LG-GC自有provider→自己的close/RETURN→O自己的GRAD publication；不接到单S原CLASS信用里，不拿GRADterm挡原CS。

拟职责只有：`class_object_loader`、`exact_hysteresis_controller`/`edge_object_export`、`logical_state_queue_service`、`closure_directory_handoff`、共享`ddr_byte_adapter`；参考/scoreboard/runner按G另冻。名称是计划，无源码存在声明。物理adapter/RX/journal是全机同一真实资源的选定client，不能在闭包与生产链各免费复制一套再算并行。

## D. 明确接口及组合检查

1. **公共typed body保留**：LC270/PREPARED277/CLASS_SEAL863/LC_TERM776；CLJ438/BIND511/CL_TERM1013；RQ324/RSP449/CLOSE294/ACK502/CANCEL167。L与C只在旧L会话/term和本S已结束后移交，一次只一个data held/credit/独立reply位置；新body不blindcast旧body。
2. **raw迁移候选**：DR_KEY201=`S96/seq64/op2/address32/length7`；RQ713=KEY201/payload512、RSP731=KEY201/status2/reason6/value512/effect2/written7/settled1；AP472为AP466仅address26→32。完整端点/加法先足宽检查，不能在address26里先截断再扩32。rawseq、typed tx、Oref/grant、stagegen、Sphase token及Opublication token各自不同namespace。
3. **权限**：CLO CLASS为mutable自身READ/RMW，QUEUE独占READ/RMW，EDGE私有WRITE含同span保护READ；这些不是immutable reader。每次span先查完整descriptor/pin/holder/fullH/phase及动态S最新值/coverage/tail。选择原DIR冷全文方式或新SC/cache必须明确；此建议先原DIR方式，新cache仍未采用。33bitend、足宽index×recordbits、firstbit/length及rounded权限在物理访问前核，不从raw coords寻址。
4. **phase/admin区分**：CLASS_COMMIT、SEED_COMMIT、CLOSURE_COMMIT、EDGE_COMMIT是S的durable数据/阶段证书，不由其名字直接将O descriptor设immutable/COMMITTED。CLASS initial certificate保持mutable接力；每个阶段的权限由S旧FSM与真实已消费成功回复推进。token发行责任须明列，不能合并S的独立token与O的独立commit序列。
5. **EDGE publication具体候选**：保原CL_TERM1013不加字段。父消费完整成功CLterm后，给O新内部`EDGE_PUBLISH1013`（原完整CLterm），O回复`EDGE_PUBLISH_ACK1150=echo1013/version64/publication_token64/status2/reason6/immutable1`。仅trusted父并以原CLJ冷体/真实S封存记录/RETURN/无writer、fullN/edge token、实际effects核验才成功0/reason0/immutable1/两个非零64；拒绝不能冒absence，BLOCKED/UNKNOWN保原retained context与义务。内部码族映射与重复请求行为须在下一卡冻结，不能blindcastR4reason5/SCreason6。O不等CLO holder先RETIRE；该publication/ACK本身必须计运输/资源，scope returnedmetadata保留至其真实结束。它是新候选接口，不声称原来源已具有1150端口。
6. **LG父交接**：原CS唯一在父独立槽接，后续分三个seal；CLASS初态token/close即可移交本S CLOSURE，不要求wholeLOAD FREE；最保守单J先汇合SRC/L/G相关义务，再闭包，若以后要重叠须另证共享adapter/journal/holder隔离。formal CANNY retain0真absence，不等G；CANNY_RC retain1真实fullN GRAD/token，不从CS计数代持久图。

**组合反例走查**：REGISTER先预授CLASS pin→原BIND再授同pin会双计并破坏“合法拒绝无binding”；令CLASS ACK等三scope RETIRE会与GC seal/close互等；EDGE_COMMIT立即COMMITTED会留下writer；Opublication等wholeholderRETIRE又holder等publicationACK会互等。上述方案分别用原typedBIND唯一ACQUIRE、scope独立RETURN、S证书/O发布分层及retained admin破环。每条新桥必须真实保expected/回链，不能只加ready线。

## E. 局部中文操作草图与明确物理代价

### E1. 单S无cache基线

旧IDLE收一个typedRQ只锁全文→后续核H/role/op/phase/index/coord/unused→真实目录授权与单组保留→旧许可成立后读16B span→后续capture/解码→建立postimage→必要logical_commit→发heldAW/W/等匹配B与无未来效果/可见性资格→后续旧all_settled形成typedRSP→实际RSP消费→后续局部空才回IDLE。全body/seq/span/旧ref/version/grant/阶段及active pop保持；cancel沿旧RQ/RSP/逻辑提交/AXI fire照计，后续停止新ordinary，不组合撤ready/valid导致旧held不能兑现。

本候选以16B对齐/SIZE4/INCR/ID0/全WSTRB为物理基线，小随机请求LEN0；一般raw1…64B可跨最多5拍，仍按PB单issued burst/≤128/4KiB及RX/route资格。不继承axi_ram的OK模拟行为。每个physical effect须真核ID/RESP/LAST/拍数/健康；末W不是成功，单B/一次readback也不是隐藏内部无未来effect证据。真实IP若不能提供候选资格，验证失败或Q并回修设计，不能伪造settled。

### E2. 逐操作的完整span/初始化策略（下一卡可直接定稿的候选）

| R4 op | 不变logical动作 | 正常无cache物理数据拍基线 |
|---|---|---:|
| LOAD_PAIR | i对应两2bit初态，核预期坐标/外框/unused，改同class nibble并保邻bits | CLASS16B读1+全span写1 |
| READ_CLASS | 对pixel index核坐标，取低2bit并高30零；general读最新本会话 | CLASS16B读1 |
| CLAIM_APPEND | 核期望10/01、tail<N且old expected_tail一致；预留class与queue两postimage及真实journal位置 | CLASS16B读1+QUEUE16B读1；成对logical_commit；两fullspan写2 |
| READ_QUEUE | entry/head<tail，coord/tail/data0；取32bit/高10零且原append provenance | QUEUE16B读1 |
| EDGE_WRITE_PAIR | 全P包含0，保同byte/16B中的其他合法pixel及tail | EDGE16B读1+全span写1 |
| PHASE_COMMIT | index/coord0及old阶段、tail、无dirty/effect债/fullcoverage/padding正确才非零token | 无像素data拍；真实目录/native/token/phase工作另计 |

CLAIM具体顺序：e0 typed fire只锁→以后分别得到oldclass16/oldqueue16并核完整rounded授权→保class新11和queue新coord32，两entry与tail_new全部准备好→一个旧LOGICAL_COMMIT事件同时公布三个效果→之后串行物理写两个span→两个效果均真实settled才成功RSP/value/tail。所有S查询先journal latest；单组未settled不接第二ordinary，不因同沿replypop透传覆盖。任何postcommit失败，buildINVALID/禁止发布，保两postimage/原tail/物理prefix与UNKNOWN；未published后缀明示处分，已held物理请求继续履约；独立physical CLOSE/INVALID_SETTLE后才typed关闭，journal退休不等待父对象先FREE。共享16entry池仅保留两个槽，不免费另加RAM；全机其它原子组的仲裁/额度仍须联合预算。

保守INIT选择为每个bound mutable对象先真实全rounded16B CLEAR，再普通RMW，已初始化前缀只按连续真实settled推进；不采用“host先清零”或未证明的lazy-init。生产三logical容量均16B整除，CLASS32,400拍、QUEUE518,400拍、EDGE16,200拍，共567,000拍/9,072,000B初始化写；QUEUE fastpath缺席不授pin也不清它。小图N30对应CLASS8B/QUEUE120B/EDGE4B，各需合法rounded16/128/16B初始化与高padding保护，不能越guard/其他slot；这些初始化effects虽不在P个LOAD/GRAD data请求内，close必须覆盖，资源/服务M_i必须计。若选其他初始化路线，须以真实item/rounded coverage改设计，不删这笔成本。

### E3. CLASS初态与EDGE发布保留状态

原L success必须自己raw/good/stored=P、S/Weak/CS一致、真实CLASS token与ACK502，不由CS0自证。S需真实initial token/P/S/Weak/version封存记录：可以将`JID96/ref64/version64/initial_token64/P21/S21/Weak21/coverage_ok1/physical_settled1`作为**353bit候选body**保存；不是现有实现事实。须给实际owner/存放/读写/生命周期和父LCterm副本是否真借用，不能同时声明新增353与“已有完全相同副本所以免费”。M1 191词候选只存LG/CLO/RC body，不自动包含这个新证书或publication运输。

CLO bind核原class_initial_token/metadata与独占grant，SEED遍N/read10→claim10，阶段提交后BFS不得遇10；pop成功核entry才head++，八项各完成一次，末项追加后仍处理新点。最后head=tail且所有active/pending/信用/回复空→CLOSURE_COMMIT→全N导出→EDGE_COMMIT→RETURN/CLOSE→CLterm；父之后发新Opublication。旧LAST/EOF/队列空不能替阶段token或真实close。GC的GRAD publication仍LG自身close-before-parent-commit，不被此新增EDGE接口改写。

### E4. 不伪造周期的可计算账

GENERAL实际closure请求 `2N+2K+B+P+3`，load另`P+1`；两者总≤`13N+4=26,956,804`，B为实际合法邻居READ_CLASS次数≤8K，不能拿neighbor_checks直接代B。无cache表对应正常data读拍=`2P+2N+3K+B=3N+3K+B`、写拍=`2P+2K=N+2K`，总=`4N+5K+B≤17N=35,251,200`拍/564,019,200B。再加上述INIT写9,072,000B，条件总573,091,200B；不包括native目录/pin/holder/journal、AXI命令/响应、phase/token/close/publication、SRC/GRAD、refresh/turnaround/健康或stall。这是候选表的保守数据账，不是物理实测或最低必要带宽。

令各typed op服务上界为`μ_auth(op)+μ_native(op)+r_op μ_read16+w_op μ_write16+μ_effect(op)+μ_reply(op)`，原实际握手外的本地沿另列δ_op；准备、INIT、phase、RETURN/CLOSE、Opublication及父汇合总M。若这些服务/消费前提有限，单S基线可预算`C≤M+Σ真实m_op×(μ_op+δ_op)+有界stall`；不给μ填1或由nominal1.6GB/s除字节当全帧时间。LG retain1另有SRC P读+GC P写+一次O commit，联立logical候选29,030,405，typed次数不是物理拍数。

原DIR cold full lookup要32词pin+32词descriptor+真实holder body读回/验证/assembly和真实动态S资格，每次事务不能跳过；选SC热cache时单LOOKUP本地最早4interval也不等吞吐1/clk，选coldCACHE候选需至少21响应/23下一请求间隔，且capture/更新另38/row。这些是不同未合并选择，只可选一条实际实例账；新设计应列本S每opcode真实lookup/span/admin次数Q，不能以13N×某个摘要拍数冒“完整处理时间”。

fullFF/LUT/DSP/RAM仍未知：至少CLJ/bind/term、RQ+expected、RSP、CLOSE/ACK、cancelreply、游标/activepop、LC/CS/seal独立槽、S最新/commit/partial ledger、353候选封存记录、publication1013/1150、DDR route/holding、O冷回读及native pending均要有实际位置。允许可信借用/合并body只有寿命与仲裁证明确立后扣一次；旧R1/R2、目录4+4/M0/M1/journal及RX的RAM按真实共有实例计，不拿某个175/176或28小计称全机fit。

## F. 语言与对应合同

未来SV2009；unsigned21索引/head/tail先22bit增量，neighbor unsigned24先25bit，坐标偏移signed13，yW+x先32核<N；DDR地址32/end33、bitoffset乘加先足宽（DIR/cache43/44域），seq/gen/token64先65检测耗尽不wrap。RQ unused、queue高10、CLASS/EDGE末padding严格核。C++本报告未计划使用；Python独立可达集合/连通分量参考只在批准后生成，不依RTL FSM/journal/目录token造黄金。

RTL B/C/D/E：单core posedge沿前valid&&ready&&!rst为fire，capture不透传，valid0不计/不当数值0，held全body保持；回复/close独立于data/父term；错误/取消先计旧fire。F：具体本地状态/同步native RE→下一沿capture与实际μ/δ另冻，不把BFS有限性当固定延迟。G：共同reset火0，冷有效性隔离，warm先真关闭/隔离，DDR图不清零冒settled。H/J：全CJ/CLJ/原J/source与ref/version/gen/token绑定，配置更新不改变旧图。I：N非环队列/rounded权/latest/初始化。K：本核同core，DDR ASYN1/物理域与外部camera/video跨域另真实adapter/PIO，不由单域测试代证。L：Ti60/I3/工具沿已有基线，完整资源/STA未执行；未改引脚/工程。

共同数值契约是完整初态可达集合逐Nbit；执行契约是所有真实fire/logical_commit/effect/phase/close/RETURN/publication；对应契约按原JID/CLASS初态token/closure_id、row-major原pixel/lane与独立全图gold比较。CRC/term只诊断不代全图；physical模型只copy字节/注入错误，不替FPGA执行claim/BFS或生成token。

## G. 下一设计的有限验证权威（场景文字，NOT_RUN）

下列是建议下一张卡冻结的最小明确套件，尚无可执行case/vectors/TB或hash。32bit地址例与无cache操作表可以独立设计核算；模型/工具测试待批准。拟文件只在未来独立`work/.../r4_closure`，`rtl/closure/*`、共享schema/adapter、`model/closure_reference.py`、`model/closure_protocol_scoreboard.py`、`sim/tb_*`与runner均计划，不在本轮生成。完整文件数、路径、compile顺序、exacthex/schema/manifest与源工具基线由C-GAP03同一张卡冻结，不再扩无穷文档。

| TEST | 有限输入/事件及实际观察 | 判据/来源 |
|---|---|---|
| CG-T01 集合快路径 | 6×5、8×7、1920×1080；全0、无强全弱、无弱孤立强、TL=TH合法来源 | 初态严格外框00，NO_STRONG/NO_WEAK无QUEUE/SEED假token，全N/P逐bit和真实EDGE写/commit/close；R4C170 |
| CG-T02 生产GENERAL | 1920×1080：全部interior候选/一强其余弱；斜链、蛇链/分支/环、断开无种子岛；源mask由独立确定规则冻结 | 密集interior K=1918×1078=2,067,604、checks=16,540,832，所有pop均interior所以B=8K；closure request25,860,043、含load26,896,844。这只是typedCLASS边界fixture，不宣称R2 NMS一定生成该密集图；全Noracle/真event一致 |
| CG-T03 真实R2衔接 | R2批准后，用其实际完整1080p源/真实CLASS125/CS592，retain0和retain1各一个；GRAD独立提交 | 真C0/父唯一CS、L/三term/初态token和GRADtoken正确，实际closure→Opublication全N比较；不能用typedfixture替这个组合证据 |
| CG-T04 地址/packing | QUEUE entry0/1,245,183/1,245,184/N−1；CLASS相邻2bit/两lane、同16B连续claim；6×5尾pad/guard | 地址0x04000000不截断/不写SRC0；完整邻bit/byte不损坏，未经许可的rounded读写拒绝，padding0。tail=N等generic容量错误注入是拒绝测试，不冒外框00下合法K=N生产图 |
| CG-T05 提交/移交 | op5/CLASS RETURN/LCterm/CLJ、GC close/commit、EDGE durabletoken/RETURN/CLterm/Opublication逐点stall8 | CLASS mutable与GRAD/EDGE immutable分层；一个真实CLASS grant；未publication不供E；保存old fullcontext且无wholeRETIRE↔COMMIT环 |
| CG-T06 物理故障 | 两个claim写的precommit、首AWheld、首W/B、第二AW/W/B、坏ID/RESP/LAST/拍数/校准失效；badreply/badclose分别 | 所有真实effects/旧commit与distinctprefix保存，known失败不成功、UNKNOWN不猜prefix，独立close/Q不返错pin；不是常量OK AXI模型 |
| CG-T07 取消/reset/保持 | SEED末项、activepop第7项追加、EXPORT最后pair、phase/close/RETURN/publication/STATUS同沿cancel；各held8，合法共同reset与非法单端reset | oldfire都计，活动项不跳、termvalid冻结、cancelALREADY不当closed；sharedreset合法隔离后新job，warm未知不复用旧ref/token |
| CG-T08 公平/恢复 | normal间歇bubble/outstall以seed0x431与0x1060的明确有限schedule；三provider/目录/单burst竞争；每known失败后合法关闭新job | 后续卡固定每种schedule最大连续stall与服务机会/μ上界，单个真实共享引擎无饿死；永久notready只保持/监测失败，不生成假恢复 |
| CG-T09 独立权威/资源 | 全widthhex/EOF/X/Z/pad、partialfilter、intentionalfatal三例、真实WLF局部沿；综合网表完整数值扇出 | runner实际compared=N/good事件与各scope台账，partial不fullPASS、fatal不PASS；FULL资源实例去重、STA/bit实际产物另执行 |

有限timeout政策：正常场景cycle限由E4操作次数×已选有限μ/δ/M加明确余量制定；墙钟限由完整vectors/现装工具实情制定且每case有数值，不伪装算法fps目标。服务前提故意违反时有限监测判失败/PROOF_PENDING/Q，不让TB无限运行，也不让RTL以timer伪造close。审批前需要该具体方法/预算设计与审读；实际工具报告不是审批前必做项。

## H. 双向追踪

| REQ/真实来源 | 当前缺口→MOD/IF/局部 | 下一卡计划稳定职责 | 独立TEST / 当前证据 |
|---|---|---|---|
| R4C-REQ01 / LG-REQ01…05 | C-GAP02，父seal/L/S、LC→初态资格→exclusive bind | class loader/directory handoff/full history adapter | T01/03/05/07；来源全文与组合推演，无源码 |
| R4C-REQ02/04/07 | C-GAP03，C seed/pop/八邻居/queue/fastpath | exact hysteresis controller / edge exporter | T01/02/04/07；数学/数量核算，NOT_RUN |
| R4C-REQ03 / RAW246–256 | C-GAP01，S两postimage/logical_commit/latest/INVALID_SETTLE | 单typedS/共享journal/DDR byte adapter | T04/06/07；16B数据账与真实接口差异 |
| R4C-REQ05/08 / DIR139 / SC138 | C-GAP02，Sedge durabletoken→RETURN→CLterm→Opublication | immutable publication/provider binding | T01/03/05；新1013/1150仅候选接口 |
| R4C-REQ06/09 / LG-REQ06…09 | C-GAP01/03，scope close/effects/完整instance/service/工具基线 | protocol scoreboard / resource_service_contract / finite runner | T06…09；设计审阅与静态算术，不是运行 |

反向：新增32bit桥只为合法队列/对象范围与真实效果，353证书/1013publication只为来源/版本/发布关闭相容，无cache基线只为一个可计算实体。未增加别的识别算法或camera/HDMI业务；主机oracle不当生产计算/存储。

## I. 门槛、恢复与实录

①整体行为B；②职责/真实来源C/A2；③相容与精确反例D/A3；④中文局部/old沿E；⑤语言/映射F；⑥正常/故障走查B/D/G；⑦有限设计方向/追踪G/H。⑧仍不满足：三项必须在下一具体设计冻结；本报告不把候选schema/算术当桥已完成。⑨本文保存后全文读回并核hash/links/采用来源，向根交接；⑩v0.1/唯一新报告/只读基线明确。保持NOT_READY，不创建READY/批准记录。

变更候选影响R4C B01/B02/B05、LG B01/B03/B05/B06/B08、DIR B01…03、PB B01/B03/B04及整合DR迁移。旧卡不编辑；恢复需新联合指定版本及实际批准，不能按“内部变量改名”直接实现。若根只选闭包核而隔离生产IO/RC，须在新卡按规范§10.3第8明确未来范围，同时真实S/O/LC→CLO当前接口仍完整；不能拿抽象port/stub证明全FPGA已实现。

实际实施/仿真/综合/PNR/STA/bit/硬件及功能验收全部NOT_RUN。当前R1已有实际交付仍属R1专属证据；R2待批48输入由根管理，本作者未在本报告核读/改它。只读探查和整数核算不称EDA验证；用户理解验收待实际反馈。

## L. 阅读与交接

先A三项结论→B完整集合→C单增量→D actualtyped/raw/holder/publication差异→E单S每操作与物理/服务账→G独立有限套件→H追踪→I状态。下一动作是根独立审读这一限定建议，选择并冻结一个完整后端/交接实现设计；不用先增加更多泛化规划，也不要求在未批准时先生成代码补证。
