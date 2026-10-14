# TRACK4-ALGORITHM-METADATA-TRANSPORT-001：稳定冷上下文与窄消息候选 v0.1

- Goal：将条件逻辑 body 账中的重复宽身份运输转为真实 immutable context 引用，降低 FF 压力，同时保存两端 held/private、跨域关闭与原效果义务。
- Current state：资源缺口审查列出63191bit条件逻辑容器，其中HANDOFF14814、published ROW11508、采用SCAN cold后余23570；这些不是实测FF，也不是全机不可能结论。
- Target state：先分清各原实例/域/寿命，再给一份具名完整 RMT-ROW-v1 候选；ROW四族改显式新schema，完整原472身份双域冷存，来源/目的保持槽仍独立。
- Gap：全机联合设计、真实域/clock/reset/CDC与ROW deadline未闭合；SCAN/HANDOFF其它ref方案仅候选分类，不据此扣数。
- Assumptions：Ti60F225；core100MHz、pair74.25MHz均沿生产候选，非已验收全机时钟；原实际原语支持独立WCLK/RCLK的事实来自PIO182。
- Open questions：A3；影响当前正确性或正常服务的项保持OPEN。
- Dependencies：A2原来源与SC846D实际限定引用；不隐性吸收H1或新cache-memory讨论。
- Milestones：只读分类→保存候选→联合ROW/SCAN/CONTROL评审→补齐成本/接线→READY→用户指定批准→实现。
- Detailed steps：B整体，C owner，D schema/相容增量，E中文逐沿，F RAM/hot/每op成本，G/H验证和追踪。
- State transitions：文档NOT_READY / NOT_APPROVED；metadata状态见E1，正式状态不改。
- Artifacts and hashes：来源A2；保存后的自身真实摘要另交接，不自引用。
- Validation：本轮合同/数值设计分析；仿真、综合、PNR、STA、bit、硬件均NOT_RUN。
- Failure handling：错handle、bad echo、partial/未知effects/Q保留原metadata及bank，不以cachemiss或timeout返还。
- Human approval gates：本卡为新接口替换增量，R1批准不涵盖；未READY不申请实施。
- Rollback：不采纳时维持原宽body合同；本轮没有源码需要回滚。
- Completion criteria：具名候选的字段/实例/微周期与实际读回完成；正常期限和全机fit仍待联合证明。

## A. 状态、范围与实际来源

### A1. 本轮范围

任务TRACK4-ALGORITHM-METADATA-TRANSPORT-001，v0.1，2026-10-05，**NOT_READY / NOT_APPROVED**。仅新写本设计卡。原planning、R1、原HDK、五交付入口、审批/数据库/硬件状态只读；无业务源码、功能脚本、TB、网络、构建或硬件操作。

完整具名候选限 **RMT-ROW-v1**：原 published ROW/OWNED/RELEASE/ACK四族的双方完整身份用冷记录承载，并用稳定handle+小后缀运输。五RowCtx、3000bit本地族、SCAN/CONTROL/HANDOFF现有合同保持；其它冷存/ref方向分类而不偷偷减账。SC原32cache/32mask规模与846D摘要不改；H1 object26/+299selected-state或cache移RAM是另项未冻结提议，未被本卡吸收。

### A2. 实际阅读及摘要

路径均在`_fpga_edge_agent/`，摘要SHA256；规范/PLAN_TEMPLATE已按本轮项目入口沿用前项实际阅读，hash分别4E468071…C7BADB2、99B7DA32…BA7DE79。下面限定范围不冒称全文重审。

| 来源 | SHA256 | 本轮实际范围 |
|---|---|---|
| `experiments/track4_algorithms_20261004/03_review/production-resource-gap-review-v0.1.md`，191行 | `3785F7187E1F1537DBC2B3DCB9EE0A7777D43B11B8F573AEE992FF7F75CED585` | 全文分1–105/106–191读回，§3/4唯一实例与§5/6成本 |
| `planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md`，217行 | `1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8` | L48–142，RowCtx865、5ctx、独立3000/11508、payload/970沿；未称全文 |
| `planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md`，245行 | `3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243` | L67–132，其中67–110单独补读，111–132明确ctx/Q/ARM/30306账 |
| `planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md`，223行 | `F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67` | L69–112，REGISTER/OPEN/ASSIGN/FETCH/FILL/RETURN/CLOSE各真实body/slot/sourceledger |
| `planning/design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md` | `39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10` | L143–196，ROW472全字段、原双端11508、native与domain/clock候选未闭合 |
| `planning/design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md` | `4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662` | L60–95；core D0/C0已有唯一记录/两端CMD及IMAGE/ACK不能删 |
| `planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md`，298行 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7` | 前一子任务实际全文保存/读回；本卡仅引用D1–D6（L92–138）与F1–F3（L184–226）：ALG stage32、metadata/quota不由miss释放、shared端口/未证fit；不宣称本任务重新全文读SC |

control入口/规则/状态沿本轮已实际读回；正式硬件baseline未通过与DB未配置不改。本卡只引用有限源，不替全项目盘点或全算法验收。

### A3. OPEN与影响

| OPEN | 需要补齐的真实合同/责任 |
|---|---|
| MT-B01 | 各原ROW owner唯一接线、无隐含第二wide槽、源472 immutable source lease及目的image480如何实际组成OUT owner内部职责；需ROW/OUT owner联审，才能扣对应原11508实例。 |
| MT-B02 | core/pair clock/reset/CDC具体实现与时序、rowdata/metadata的真实跨域quiet桥及正式隔离；PIO190仍有真实core-clock缺口，不能借同频消除CDC。 |
| MT-B03 | normal稳态/两首行ROW deadline、两镜像写/query单引擎与原CONTROL/DDR/render/SCAN服务，条件177 RAM未包含其它未知实例；资源/服务owner联审。 |
| MT-B04 | 原dup/replay/bad echo/first fault/Q各owner完整映射，metadata RETIRE控制和data-bank RETURN相容；收到ACK不等整体FREE，需joint事件矩阵。 |
| MT-B05 | SCAN/HANDOFF稳定context ref的真实owner、完整source/目的寿命与跨域cold replicas/assembly；目前只有分类，不产生这两组的节约结论。 |

## B. 整体外部行为与不变量

不改变图像/显示/算法要求，也不降低正常服务目标。metadata冷记录不存pixel payload、不授对象访问pin、不伪ROW_READY/OWNED/APPLIED。ROW_READY仍取完整960pair/2304词真实WE及原pipeline/pending闭合；显示资格仍原SCAN/VSYNC的真正采用。新handle只是完整472历史的引用，必须在真实已COMMIT的记录与同代bank下验证。

| REQ | 要求 |
|---|---|
| MT-01 | source held、destination private、持久originalcontext、cold copy、decoder/assembly分别列实例和有效期；可共用时给actual lease，不按名称扣数。 |
| MT-02 | 先全record写入、nativeeffects settled、校验与COMMIT，后发布引用；末词高padding0。handle非零generation唯一，不由slot数字证明权限。 |
| MT-03 | 公开新窄消息保持到fire，目的private完整接纳且借coldcontext至语义履约；旧fire先于cancel，不能以invalidate撤旧held。 |
| MT-04 | 两域各有真实读取/消息/控制/引用quiet；RETURNED_METADATA/Q占原bank额度，metadata ack与原data bank FREE不是同一事实。 |
| MT-05 | 不默改原ROW472四族、SCAN/CONTROL/HANDOFF宽body；替换需新联合版本/审批与验证，不能只把RTLwire缩短。 |
| MT-06 | 热位、native词、RAM数量、端口/每op间隔与clock分开计算；正常deadline未证不称通过，失败SAFE/Q不当正常吞吐。 |

正常例：core完整渲染bank1/genG行y0，冻结真实ROW472并镜像写入两RAM→COMMIT→窄ROW128→pair完整读24词核原历史→OWNED135→原data正常读取→RELEASE136→core真实原bank关闭→ACK143→各business运输/private结束→metadata QUIET/ACK→后续真正复用。边界例：旧bank1 metadata closing时新ROW不得覆盖；bad ACK/旧handle不能清新generation；Q不FREE；cancel沿旧ROW/RELEASE已fire照计，独立停止新提议但仍兑现旧结果。

## C. 先区分原实例与允许的引用条件

### C1. 全机三组分类，尚未冻结的方案不扣数

| 原实例/域/寿命 | 必须保留的独立义务 | 可选引用方向及当前决定 |
|---|---|---|
| SCAN4×CTX840，D原执行域 | current/future/closing/Q完整身份与真实parent仍存；core registry906是另owner/域 | 已审查cold340词含CTX/cache不是所有transport。不可拿同一RAM作跨域第三端口。此项保持原cold候选1块与余23570账。 |
| SCAN8×EVENT1021，两端各ctx一个 | 旧普通held/private不能被即时Q覆盖；Q444与actualframe/adopted/原CTX寿命独立 | 若另有真实stableSCANhandle128，候选EVENT309=handle128+原181suffix；8份2472代8168的节约5696仅消息算式，需新cold/复制/域/reader成本，MT-B05不扣。 |
| SCAN PREPARE841/979、独立lastcache1820 | prepare在途可能grant、两端pending/高水位/完整原request/result不可因后来CTX出现而消失 | PREPARE时CTX尚未存在，不能借其slot作handle。PLAN若无真正immutable provider/lease继续宽body；未知reply保可能grant。 |
| SCAN ARM642/650、lastcache1292、group198 | 历史成功重放不重装membership；deadline即时选择，group关闭不等ctxretire | 两个KEY256可以研究换真实已preparedctx refs，但必须全查immutableCTX/firstROW/role/target，新增cold读不免费。暂不改宽body或组预算。 |
| SCAN STOP/CTRL/CORE_CLOSE/DISPOSE及Q444 | STOP每ctx独立、立即阻新业务且旧held履约；Q冻结前缀不随SAFE变化 | 关键关闭通道不被body-query/ROW满阻塞；不把动态计数/closefacts只留下livectx指针。当前保独立。 |
| HANDOFF14814运输（两端full族） | REGISTER/OPEN/ASSIGN/FETCH/FILL/RETURN/CLOSE的seq/prefix/effects、sourceheld/目的private独立；persistent6240/completion7407是另用途 | 可研究REGISTER的CTX840引用与ASSIGN/FETCH稳定RowCtx/loan引用；共享CONTROL已冷存registry/cache不授权借其未结束slot。新refwire需cold-record lease至最后body作用与回复结束，MT-B05不扣14814。 |
| 五RowCtx865、两input/三out | 输入RETURN后math/copy/out仍借ctx；outpixel复制后按原仅独立scanref，五上界才成立 | 若冷存五×44=220词，需要core唯一端口/lease/完整检查及renderer历史render hot镜像。当前保4325body，不挤DIR M1剩39词或拿跨域SCAN余172词。 |
| published ROW四族11508 | 三bank×每族各sourceheld+目的private，四族原body包含472稳定历史加小后缀 | 本卡选RMT-ROW-v1：两镜像cold记录+显式窄四族；每个源/目的窄保持槽仍独立，不合并取消义务。 |
| CONTROL sourceCMD/目的CMD/sourceIMAGE/目的IMAGE | 3986body+23valid+88局部热=4097是既有独立端点与单sequencer | 不因coldD0/C0存在删其914assembly；新RMT用自己具名engine/assembly成本，未免费复制CONTROL。 |

### C2. 具名RMT职责与连接

RMT_CORE位于原OUT owner/core职责内，唯一分配metadata generation、freeze source472、两镜像写/COMMIT、core query与bank lifecycle。RMT_PAIR位于原PIO接收/释放owner/pair职责内，唯一query D0/read480，结合原SCAN/bank/native/pixel真实台账形成OWNED/RELEASE及metadata quiet。它们不取代ROW_RENDER、原outdata15RAM、SCANctx/parent pin或HDMIserializer。

IF-MT01=源原历史472冻结/镜像COMMIT与WRITE_ACK；IF-MT02=四族窄消息core↔pair；IF-MT03=目的私有coldquery（core C0、pair D0）；IF-MT04=跨域metadata quiet/receipt；IF-MT05=原bank/native/adapter/SCAN真实事实桥。两RAM是不同物理copy与域端口，不能用单RAM声称core/pair都随时读；每域sequencer只一条query，原FIFO/数据读取并行需实际独立RAM资源。

## D. RMT-ROW-v1 schema、所有权与显式delta

### D1. 冷记录与handle

完整ROW472字段沿PIO163不改：job96/plan64/display64/render_generation64/scan64/bank_id2/bank_generation64/target_y11/pair_count11/link32。全部unsigned，原字段顺序高→低；serialize native固定原body低20bit先，每bank24词，word23低12bit有效/高8bit0。bank0/1/2起址0/24/48，最后词23/47/71；72..511未授权存其它object。

两物理镜像 **RMT_C0、RMT_D0** 各EFX_RAM10 native20×512/1R1W/OUTPUT_REG0。C0 WCLK/RCLK=core；D0 WCLK=core、RCLK=pair；source owner双写同一20bit/data/WE11，ADDREN按真实RE/WE，RE下一本域沿capture；no同址R/W。C0由core核读，D0只在COMMIT之后经稳定窄notice与CDC资格允许pair读；不借C0剩余容量免复制D0。原模型支持双clock是能力事实，不是本新实现CDC/STA已通过。

新handle **RMT_HANDLE128**（低→高）：epoch32/meta_generation64/bank_id2/kind2/zero28。kind1=RMT_ROW，0/2/3本候选拒绝；bank3非法。epoch与真实原job/授权会话相符，meta_generation由core独立next64+exhausted1初1；max一次、下一分配拒绝、不回绕；warm/link换会话不清序列。meta_generation不是bank_generation、scan exec、plan64或source handle的CAST。只有actual record COMMITTED/epoch/gen/bank匹配且provider真实parent资格才允许取body。原bank_generation仍472cold保存及每次完整语义检查。

### D2. 新窄四族（明确替换，未被旧卡吸收）

| 新IF-MT02方向 | body、sourceheld与目的private |
|---|---|
| core→pair ROW128 | RMT_HANDLE128；引用一份真实已COMMIT、完整960pair原ROW历史。源notice形成前core已锁其context生命期；目的只收到handle不等OWNED。 |
| pair→core OWNED135 | 原ROW128/status2/reason5；status/reason语义继续原族，成功必须真全472资格与原bank接纳。 |
| pair→core RELEASE136 | RMT_HANDLE128/kind2/drained1/reason5；kind0CONSUMED/1DISCARDED/2Q、3非法。drained只原provider真证据。 |
| core→pair ACK143 | 原RELEASE136/status2/reason5；完整echo，错handle/后缀不返他人bank。 |

每bank每族各sourceheld+destination private一份，深度1，3×2×(128+135+136+143)=**3252body bit**，另valid/CDC。原fullbody被共享immutable冷身份引用，独立的源/目的valid、业务状态、引用、expected、取消/firstfault仍各自真实保存。没有把两个槽合一。每context一生各族最多一份相应正常proposal；重复/晚消息由原状态/完整handle/window判断，不授新引用/重跑数据effects，未冻结的全dup矩阵MT-B04阻READY。

原wire ROW472/OWNED479/RELEASE480/ACK487没有自动变窄。联合版本需把producer、CDC、destination semantic/fullcold checker、expected/echo、close/测试追踪一起替换；没有批准前继续旧宽族。global native/bank资格IF05仍保旧合同，不能仅对消息类型名“ROW”改位宽。新handle没有授pin权限。

### D3. 源保持/目的private与copy engine

IF-MT01 source472是实际冻结的原OUT owner源槽。accepted时建立不可变source lease，保持全部472直到WRITE_ACK正确消费；不是fire后马上让producer重写。core engine另有独立image480用于packing/逐词读回，不因cold已有body就省掉destination private/assembly。source472是共享给引擎的真实稳定借用实例，期间唯一owner不得修改；lease拒绝/BUSY时source旧valid/body继续保持。

WRITE_ACK200=handle128/原bank_generation64/status2/reason5/committed1，独立held201bit含valid。成功只有双镜像全部24真实WE、native写pending闭合、C0全文读回等于source472且高8padding0、原数据ROW完整资格仍真才formed。若最后写/验证遇cancel，记真实effects但失去新正常notice资格；已经published的ACK/ROW保持履约。partial双写/错核未知保context/bankQ，不给另一generation。

IF-MT03一次目的查询借原narrow destination private体直到CHECK/APPLY完成；query由完整handle定位，不把当前slot猜历史。core IMAGE480、pair IMAGE480各独立；末词高8检查先于取低472。语义仍核完整job/plan/display/render/exec/link/target/bankgen/960与原真实SCAN/OUT数据台账。query期旧private消息不得被cancel覆写；响应/应用不能与最后RE capture同沿穿透。没有第三跨域读端口，没有免费FULLBODY transport engine。

### D4. CDC、quiet与RETIRE控制

各bank四族独立mailbox，核心要求是source body在实际source接纳/同步通知/目的capture及ack完成前稳定；控制同步只跨单bit（选toggle+2flop的7state/族候选见F2），不能逐bit同步128/135/136/143当一致消息。full destination narrow body在其本域真实capture后保private直到semantic完成。cross-domain sourcefire、destinationcapture、semanticowned/released与transportclosed是不同事件。

独立 **MD_QUIET132**=handle128/data_reads_closed1/business_messages_closed1/context_refs_closed1/no_unknown1，pair→core；**MD_ACK140**=原132/status2/reason5/accepted1，core→pair。各端各1held/private，2×(132+140)=544bodybit，valid4、两mailbox控制14另计。它们只认证真实metadata关闭收据，不叫“已经FREE”；data/native/pixel/serializer真实资格由IF05原owner提供。满ROW/query不能阻该独立close控制，接收容量已预留，但状态/回执处理仍需真实公平服务。

MD_QUIET前pair无未来metadata/data RE、已issued RE都capture、原ROW/ACK私有应用结束、OWNED/RELEASE运输与context refs真闭合、无未知。其条件不等自己的MD_QUIET/MD_ACK先消失；core收到/核对后先回MD_ACK，不能等它自己的返回ACK消费或整bankfree。meta保持RETURNED_METADATA至两端MD运输/私有及core/PAIR各自business运输quiet完成；core观察真实CDCack/return-to-idle后后续沿撤C0/D0可见、才允许下一写。pair在提交MD_QUIET后永久禁止该generation新query，MD控制只凭真实保留header/原expected履约；因此不会出现writer重用后旧pair还读D0。

Q/UNKNOWN没有no_unknown1、不产生正常MD_QUIET/FREE。异步reset/软件epoch不单端清toggle/私有体/allocator；共同reset或正式隔离须全体oldlink/effects废弃授权，MT-B02仍OPEN。fixed HDMI h/v继续，不靠停钟闭合metadata；SAFE可报告真实缺行，不当正常服务证明。

## E. 中文操作草图与状态

### E1. 每bank生命周期

core metadata state3：0FREE、1FILLING、2COMMITTED、3PUBLISHED、4CLOSING、5RETURNED_METADATA、6Q、7非法。pair mirror header有相应本域有效/关闭历史，不能直接取异步core多位state作资格。每域3bank各持epoch32/gen64/state3/bodyvalid1/coretransportmask4/pairtransportmask4/core_nativepending1/pair_nativepending1/row_refs_closed1/corequiet1/pairquiet1/Q1=114bit候选；**core/pair两域header分别实存3×114，共684bit**，跨域对方facts只能从实际稳定消息/收据更新。它们是实际记录摘要，不能取代完整原bank/SCAN/effects台账。首个ROW由可信core已COMMIT的notice授只读query lease；pair先保存provisional epoch/gen而不宣称本域bodyvalid，完整cold核对后才置本域有效，避免必须先OWNED才能查询的环。

不变量：全24双WE+检查后才COMMITTED；generation唯一；bodyCOMMITTED以后不改直到真retire；冷body与两端narrow借用实际生存期重合；旧published held先履约；data-bank release不自动回收metadata；MD接收/ACK不直接FREE；no unknown不能由count等或cachemiss推断；同一native RAM一次最多一条read/write，no collision。

### E2. 双镜像写与可见逐沿（core无stall最早表）

e0接受实际source472并锁lease，不穿透写；e1核完整原ROW/真实outbank/data完成/epoch、预留FREE metadata和新gen；e2将source零扩至480的独立image。e3..e26每沿只写当前旧image低20到C0/D0同址并移位；最后词高8零，地址必须23/47/71末端。e27等旧最后写pending已关；e28..e51逐RE C0，e29..e52 capture入480，不在RE沿用新data。e53核全472=仍immutable source及padding0；e54以旧完整事实提交core metadata bodyvalid/COMMITTED及对D0只读可发布资格，pair header由其自己的notice/coldcheck另沿建立，不直接写异步pair多位state。e55才形成WRITE_ACK和具备资格的ROW128，最早e56被core本域源消费者接纳；跨域pair接纳还需实际CDC/目的容量，不能也写成core e56。原source lease在WRITE_ACK消费后后续沿可结束，最早e57下一同engine工作。反压延长，不预支同沿pop的新空槽。

当ROW被交付，新handle引用cold而非已复用source472；source/目标narrow记录继续独立。cancel在末WE或COMMIT附近先记真实fire/effects，再封新proposal；已formedROW不得被撤；Q保本generation及真实数据前缀。

### E3. 查询、OWNED/RELEASE逐沿（各域自己的clock）

e0接纳完整narrow体到destination private，建立query lease；e1检查handle/kind/epoch/gen/已COMMIT provider资格、该族真实预期及coldrecord地址；首个pair ROW按E1可信commitnotice与provisional header，后续族须已核本域header。e2..e25 RE24，e3..e26capture480；e27先检查高8/完整历史；e28以旧body+真实原owner数据/SCAN/nativefacts应用，首ROW此时才置pair bodyvalid，e29才形成须发送的窄回执，最早e30由其本域源侧接纳，真实跨域目的接纳还另加CDC。后续e31可开始下一需该engine的事务（当对应本域reply/source槽真实消费释放）。无回复的事件也不得在末capture沿提前应用。core/pair各一个query-sequencer，队列/源private保持不免费并行；query总线不得阻独立MD控制接纳。

ROW：只有truectx/目标/首行/期限/原读取资格匹配才OWNED；更晚的APPLIED属于SCAN，非此查询结果。RELEASE：pair真实no_future_RE/pending/pixelcopy等关闭后冻结kind/drained；core核原完整历史与自己的writer/body/transport结束后ACK。wrong echo保持原expected，控制close仍能排已知债，unknown进Q。未选择candidate可以真实DISCARD，不等待不存在APPLIED。

### E4. 跨域quiet与重复使用

旧typedACK被pair接纳/应用并且各business消息refs/native真闭合后，pair冻结MD_QUIET。core已知同handle/native/消息闭合时接纳，后续形成MD_ACK；其正确消费后仍等两个控制mailbox的真实transport idle与本地private引用结束。最后quiet变化沿只记状态，下一个旧facts全真且无新control的core沿才能FREE。新的FILLING不得覆盖RETURNED_METADATA/Q；其他两bank可推进，但不加第四bank或第六RowCtx。

反例走查：只收到窄ACK便重写D0，旧pair query可能读新体；本设计以MD no_future_RE和两端运输关闭挡住。只有单冷RAM却给两个域各随时读违反端口；本设计两镜像收费。用CTX指针代动态Q前缀会改变原冻结Q；本卡保SCAN444不动。等整体SCAN退休才返本bank又会堵后续row；本方案metadata close只等自己的bank/消息引用，parent大图pin继续独立。

## F. 容量、热位与微周期预算

### F1. RAM数量与padding

每镜像3×472=1416body；3×24×20=1440nativeused、padding24；两镜像body2832/native2880/padding48bit。两只20×512 nominal/addressable20480bit，实际未分配17600bit不能给其他owner无代价使用。原outdata15RAM/ROWpayload40/CONTROL2/SCANcold1/DIR11不删。按保守已列175候选+本新增2=**177**、名义256−177=79只是剩余预算参数；其他未落位的RAM/FF/LUT/DSP/PLL/CDC仍OPEN。没有证明177实际映射或全机fit。

### F2. 具名selected hot，不当完整FF/XLR

| 新实际逻辑实例 | bits | 范围/保持条件 |
|---|---:|---|
| 四族每bank双端narrow bodies | 3252 | 24个独立sourceheld/destinationprivate，不合并 |
| core唯一source472+image480/valid2/counter5/address9/pending1/op2/state3 | 974 | source472 lease真实不变直到WRITE_ACK；image480独立接纳/读回、检查末8padding |
| pair唯一image480/valid1/counter5/address9/pending1/phase3 | 499 | 一条coldquery、另一条请求在真实private排队 |
| 两域各三header114bit | 684 | core/pair各本域独立epoch/gen/flags/masks保closing/returned/Q；不是原SCAN完整ctx/physical ledger |
| metadata next64/exhaust1 | 65 | independent nonzero序列，warm不得复位 |
| 四族24valid+12mailbox×7控制 | 108 | 7=source_toggle1/dest_ack_toggle1/req_sync2/ack_sync2/pending1；这只是选择骨架，真实CDC/复位MT-B02 |
| WRITE_ACK200+valid1 | 201 | copy已提交与源lease结束有独立回执 |
| MD_QUIET/MD_ACK双端body544+valid4+2mailbox×7 | 562 | 两方向独立控制；不等它自己先消失才接受 |
| **selected subtotal** | **6345** | explicit fields计算，不是综合FF、packedXLR或全机总量 |

原11508仅body，新subtotal还计部分新状态，所以条件逻辑容器替换算式**63191−11508+6345=58028bit**，差5163；其余HANDOFF14814、SCAN余23570、五RowCtx4325、本地3000、pair638、rowpayload1219、CONTROL4097、NO-LOAN20均不扣。此式不是全机FF节省实测；只说明本明确ROW子候选如何取代原双端宽body，且另增加两RAM及reader/writer/CDC路径。原4097 engine、DIR/stage/AUX/算法热位仍不在63191，不能把58028除60800当fit。

metadata各QUERY sourceprivate实际指向的lease与originalsemantic facts、真实CDC寄存器/同步布局、warm-link/firstfault/CRC可选检查、仲裁/计数/overflow/复位/状态映射、原OUT/SCANbank/physical计数及private parentctx完整唯一实例尚须联审。width比较/packing/mux的LUT/ADD/SRL、100MHz/74.25MHz时序和全部资源未综合；本卡不承诺0DSP。source472不凭FREE RAM免费消失；body在实际C0/D0提交后其借用才能改为稳定handle。

### F3. 每operation native与间隔

| op | 实际nativeissue | 本候选无stall最早间隔/边沿 | 未计的真实等待 |
|---|---|---|---|
| PUBLISH_RECORD | 两镜像同时24WE，另C0核读24RE；同时双WE是两RAM实际各24事件 | e0→COMMIT e54，ROW/WRITE_ACK最早e56fire，下一coreengine最早e57 | 原render/source资格、排队、WRITE_ACK反压、已占metadata/Q |
| core QUERY/semantic CHECK | C0 24RE及下一capture，目的narrow/private保留 | e0→apply e28，若reply最早e30fire，下一e31 | core别的publish/query排队、真实bank/readfacts、回复 |
| pair QUERY/semantic CHECK | D0 24RE及下一capture | 同e28/e30/e31但pair clock | private/SCAN/真实期限、pixel/readpending与消费者 |
| MD QUIET/ACK | 不以cold读代原fullclosure；沿用hotheader/原expected和真实closed facts | 消费事实后后续形成；不能给固定全关闭上界 | 控制CDC/运输idle、native/pixel、unknown/oldheld，MT-B02/03 |
| actual RETIRE/FREE | 撤metadata可见标志，不整RAM清零 | 最后一项closed记录后的后续旧资格沿 | 两域真实quiet/transport、原bank复用规则 |

native连续24RE的末capture并非第24沿的完整语义成功；记录写/读/query/业务效果是不同事件。按候选频率，57core间隔0.57µs、31pair间隔约0.417509µs只是微流程最早尺度；从e0到e30为30间隔而下一ope31是31，不能混称。metadata query所需次数与four-business事务安排须实际trace，不假每row只有一次，也不将元数据与970renderer、DDRfill串/并行随意混用。

core/pair两个metadata engines是实际独立实例，F2已收费，C0/D0各读端各一；core WRITE时不能同时给C0另一个query。真正同域复用/priority/maximum-unserved时间和两首行保障MT-B03；即使177<256或0.57µs看似小，也没有全ROW deadline证明。连续h/v不能停，缺deadline给真实SAFE/error，而正常成功条件必须另证。

### F4. RTL A–L与跨语言

| 项 | 本任务合同 |
|---|---|
| A数值 | 身份全宽/无符号；word_index0..23，bank×24+word先足宽核≤71；472低→高24word末高8zero；gen扩65检查max不回绕；counts不由expected960代实际。 |
| B时钟/观察 | 两域各posedge旧fire与下一沿capture；CDC源交付/目的接纳分开。TB将来保存pre-edge并post-NBA比较，不直接跨域同沿判断。 |
| C接受 | 本域valid&&ready&&!rst，full不借同沿pop；source/data/private/CDCack容量独立。 |
| D有效 | bodyvalid只在全COMMIT后；handle miss非法不等record不存在/metadata已退；两端valid保持各自义务。 |
| E反压 | 新source/private保持完整narrowbody；SOURCE472 lease固定；issuedRE必须捕获；cancel不撤oldheld。 |
| F延迟 | E2/E3/F3最早表，stall与真实CDC/关闭无固定上界未证明；不是完整row服务表。 |
| G复位 | 同域同步禁fire，跨域共同reset/隔离与toggle初始会话由真实link授权，未闭合MT-B02；nativeRAM由valid隔离非整阵reset。 |
| H配置 | original472 history冻结、generation/epoch原子提交bodyvalid；currentUI/mode不改已formedbody。 |
| I存储 | 两mirror20×512/1R1W及唯一各域engine；不同行数据RAM共享读端，no同址碰撞，closing/Q仍三bank额度。 |
| J身份 | newmetadata generation与原bankgen/scan/plan都分开；每个ref查完整原472与epoch；原release后缀全echo。 |
| K CDC | 稳定body+实际mailbox/control同步；每域private与读证据独立；不将多位state直接sync，独立clock与reset/STA待实现核。 |
| L实现 | Ti60/Efinity候选，双clock能力源PIO182，资源6345selected+2RAM不是已map；normal行期限/clockflow联合OPEN。 |

本轮C++/可执行模型N/A。未来协议参考独立以完整472原历史/实际事件作为oracle，并另建sourceheld、destprivate、contextlease与nativeeffects scoreboards；新窄wire传的是同一事务identity引用，不改变pixel数量/颜色/coords。软件正确不能代CDC/STA或实际metadata lifespan。

## G. 实施及验证计划（未执行）

获批前只修设计/联合hash。将来实施顺序：newschema/owner接线→双mirror实际native与fullpadding→sourcelease/immutableCOMMIT→four-family窄桥及cold检查→metadataquiet/Q/reset→normal服务与资源/STA；没有把源码路径当已生成。计划职责符号`rmt_row_context_core`、`rmt_row_context_pair`、`rmt_row_mailbox`，文件划分由联合设计再冻结。

| TEST | 独立场景与期望来源 | 状态 |
|---|---|---|
| MT-T01 | oldROW472字段按PIO163逐位重建、三bank24word地址/末高8；sourceBODY与两镜像实际WE/RE一致，不读72或错误bank3。 | NOT_RUN |
| MT-T02 | 写末词/COMMIT沿前后cancel/反压，ROW/WRITE_ACK不穿透形成，source472 lease持到ACK消费；partialmirrorQ不free。 | NOT_RUN |
| MT-T03 | 两端窄held/private独立stall，原fullhistory oracle查handle，wronggen/epoch/kind/echo/link/960不赋owned/release。 | NOT_RUN |
| MT-T04 | sourcefire/目的capture/semantic/CDCack分别记事件，异步clockphase与暂停/复位/return-to-idle，稳定总线不逐bit同步。 | NOT_RUN |
| MT-T05 | RELEASE同沿cancel/末nativecapture，旧fire先兑现；RETURNED_METADATA、badACK与Q不覆盖，metadataquiet不等自身ACK先消失。 | NOT_RUN |
| MT-T06 | 两future首行+oldlastrow三bank满、current/next/candidate与metadataquery单端口调度，实际worstservice/normaldeadline；SAFE失败不算成功。 | NOT_RUN |
| MT-T07 | gen初1/max一次/exhaust、warm新link旧metadata未知、晚msg、duplicate范围；miss不证明退、无implicit第三端口。 | NOT_RUN |
| MT-T08 | 条件63191每原实例一次对应新oldexit、source/private/engine/CDC/原globalledger唯一资源，map/PNR/STA真实FF与packedXLR分开。 | NOT_RUN |

将来记录确定性边界、clockphase、随机seed/输入hash、原wide事务↔新handle/coldbody的对应，每typedflag来自其真实owner。没有在本轮生成测试/脚本或运行工具。

## H. 双向追踪

| REQ | MOD/IF/中文草图 | 计划符号 | TEST/期望来源 | 实际代码/证据 |
|---|---|---|---|---|
| MT-01/02 | RMT_CORE IF01/03，D1/3 E2 | rmt_row_context_core | T01/02/08，原472/native事件 | 未生成/NOT_RUN |
| MT-03/05 | CORE/PAIR IF02，D2/3 E3 | rmt_row_mailbox | T03/04，原完整history与oldfire | 未生成/NOT_RUN |
| MT-04 | CORE/PAIR/原OUT IF04/05，D4 E4 | rmt_row_metadata_closure | T05/07，真实bank/transportquiet | 未生成/NOT_RUN |
| MT-06 | 两engine/服务owner，F1–3 | rmt_row_native_engine | T06/08，独立trace/资源与deadline | 未生成/NOT_RUN |

反向必要性：双mirror承担两个真实read域；sourcelease和image分别承担承诺与实际private读回；窄msg只去掉重复身份值，不去掉两端义务；MD独立控制防数据满阻关闭；唯一engine和cost承担非免费复制/端口。其它SCAN/HANDOFF候选尚无实际替换单元，故没有为其伪建已完成代码映射。

## I. 门槛与审阅

整体/owner/schema/中文逐沿、字段/微周期与验证追踪已保存候选；MT-B01..05影响组合/正常服务，不能勾“无阻塞”。**NOT_READY / NOT_APPROVED**；保存读回及实际hash在交接消息给出。Root与ROW/SCAN/资源owner联合读回后再形成指定READY版本及新基线，未批准继续不生成代码。本卡没有写Approval Manifest或DB。

## J. 变更与恢复

显式delta是ROW四族wire/fullheld历史的承载方式、两个mirror/lease/transport/关闭接口和服务成本，属于新接口/重要存储策略，不能归R1内部小调整。所有oldplans/R1/five-delivery保持原hash。恢复要核本卡、A2旧source、审批与actualsource owner/lifetime；若epoch/reset/domain/clock或context方案变更，重审D/E/F/T04–08。SCAN/HANDOFF分析未被吸收前旧宽body继续存在。

## K. 本轮实录

实际只读resource报告全文及A2有限源，保存本中文设计卡；无业务RTL/script/TB/模型，无仿真/综合/PNR/STA/bit/下载/网络/DB或硬件操作。63191/58028仅条件逻辑容器算式，6345只selected新状态；没有宣布实测FF降至某值、全机不能实现或已fit。

## L. 人工阅读说明

先读C1区分各种宽副本为何存在，再读B/C2整体，再D看新wire/旧472冷记录引用和谁仍保存held，E按原clock沿确认COMMIT/收据/FREE顺序，F核两RAM/末词padding/热位/每op收费，G/H看实施前必须验证什么。新卡降低的是具体ROW元数据重复身份存放，完整算法与正常显示仍按原目标；后续选择其它组必须新增实际生命周期/端口/成本，不能把本卡样式当自动优化所有widebody的批准。
