# TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001：生产控制冷记录的实际存放候选 v0.1

2026-10-04。LOCAL_STORAGE_DESIGN／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。按 PLAN_TEMPLATE 完成两块core域RAM的布局、短事务及真实保持设计；保持十一项、1920×1080、完整Canny/原识别/板载DDR目标。本卡不把局部RAM容量或条件时钟沿预算当成完整工程证明。

## 通用计划字段

- Goal：将HANDOFF持久关联与完成缓存映射到实际EFX_RAM10，明确源体保持、组提交、读取及替换保护，不靠20bit输出冒充宽held。
- Current state：上轮核出323word关联及379word独立body缓存，两RAM容量可放；端口、保持与调度结构未选。没有算法实现。
- Target state：选定本局部布局/接口，与实际owner/热状态/epoch及全机服务联合冻结后进入指定批准、实施和软件验证。
- Gap/Open questions：MR-B01…03见I；全O目录、共享FE、DDR/CDC、全资源/最坏服务仍OPEN。
- Assumptions：core100为候选时钟；RAM两端同一core时钟；单短事务引擎；固定五个业务owner；源已形成的完整私有记录真实可pin。
- Dependencies：A实际冻结来源及唯一v0.2规范/模板；生产O/CORE/ROW/OUT/FETCH仍各有唯一业务权限。
- Milestones/Detailed steps：来源→确切物理地址→端口/源体/组提交→沿表/失败→有限审阅→与全局联合冻结→READY/指定批准→work实现及验证。
- State transitions：仅设计阶段；正式PROJECT_STATE/数据库不改，不增加全局第八epoch owner。
- Artifacts and hashes：A为源身份，输出及审阅实际hash另记；没有可执行输入manifest。
- Validation：G是文字场景、全部NOT_RUN；原语模型已只读，未运行。
- Failure handling：未完整写定的记录无valid；坏会话/体变化/未知保持原义务并隔离；已held响应不能撤回。
- Human approval gates：不继承IP预检为业务实现许可；当前不申请不完整设计批准，不生成源码/功能脚本/TB。
- Rollback：原稿/HDK/工具不改；候选布局撤回时保留旧来源与差异，不宣称被撤方案已验证。
- Completion criteria：两RAM实际逻辑/时序和接口正确须真实验证；完整目标仍需所有十一功能至bit，当前未完成。

## A. 来源及整体到局部阅读

| 输入 | SHA256 | 使用范围 |
|---|---|---|
| [HANDOFF](design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md) | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 | registry906/loan451/assign64/outKEY164及7族有限cache/原held |
| [NO-LOAN修订](design-TRACK4-ALGORITHM-NO-LOAN-CLOSE-001.md) | 3E075B87350009EAF391D937C176D34070A7C6EE97157C1A5F1B0F8BEA7E653E | GRANT461、已创建/原始不创建/诊断/未知分类，不以缓存miss证明无loan |
| [实际RAM核对](../experiments/track4_algorithms_20261004/03_review/production-unique-resource-and-control-ram-v0.1.md) | F3D84B4AB57CF457139C238B3F5988E73F3092BB94D7AFB6D0998BFEC2657C47 | 323/379词、native能力、wide held/热状态不得默删 |
| [SCAN](design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | D在pair域、STOP及Q即时资格；其冷记录不放入本core两RAM |
| native EFX_RAM10 | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 | C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v；1R1W/20×512/同步读/同址未定义 |

规范4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；模板99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。B整体→C职责→D布局/接口→E沿表与中文操作→F/G/H/I。原整合及来源未吸收本增量，不直接混接。

## B. 整体行为及要求

MR-REQ01：core域真实保存16份持久关联和7份最后完整completion。SCAN的pair域CTX/即时采用独立，不用同core容量结论偷偷跨域共享。

REQ02：业务owner决定对象/exec/borrow/银行权限，内存引擎只搬运已被实际owner保留的完整记录。物理slot/valid/短事务ticket不授读写DDR、创建loan或释放引用。

REQ03：每事务先预留响应/读取完整私有接收容量与源体pin；整组完整写入后才valid。读/比较/复制期间同组不可替换，禁止任何同址读写。元数据端口锁不跨DDR、renderer或SCAN等待。

REQ04：源held/目的private是真实容量。20bit RAM不能直接代914bit稳定体；取消/STOP仍履约旧已接纳记录，STOP热槽不等RAM忙而失效。

REQ05：完整cache精确请求比较后才重放原回复；miss只是不存在当前可重放窗口，不能证明旧OPEN无创建，不重新grant已退资源。所有会话先核，cold/warm reset不擦真实旧债。

正常：CORE实际保有906登记private→短写46词→后续沿记录valid→真实内存ACK→CORE再形成业务REGISTER ACK。边界：OPEN缓存原459变461需24词，组总44；只写旧43词须拒绝，不把最后class截掉。失败：读取旧cache期间新完成候选可在其原owner保持，不能覆盖正在读的cache，也不能占未列无限队列。

## C. 职责、连接和推进

五业务owner已有真实private/held → 单调度器选择并保源体 → CMD → RAM短事务引擎 → 原始记录/缓存两RAM → READ_IMAGE及ACK → 真实业务owner核full key/事实并提交业务状态。DDR/RX/ROW/SCAN不经过本元数据引擎传大数据。新提议停止采用原独立STOP/sticky，旧关闭仍允许用短事务引擎。

| 单元 | 唯一职责/状态 | 限制 |
|---|---|---|
| RECORD_SCHEDULER | 一份CMD源held、选中owner及真实源pin，轮转索引 | 不变更业务记录，不新分配borrow/row_seq；单总事务无隐藏5份新CMD队列 |
| RECORD_MEMORY_ENGINE | 一份CMD目的private、phase/word计数、读取/比较、响应及组有效位 | 不持目录权限，不等DDR回复，不推定source销毁资格 |
| CORE/O/ROW/OUT/FETCH | 提供其已经真实拥有的全记录/当前请求；接收并核全identity，保留结果和各自ledger | 当前已有private/held不能在RAM还读它时复用；实际集成须MR-B01核对 |

业务owner编码3bit：0CORE、1O、2ROW、3OUT、4FETCH，5…7非法。D0 registry归CORE、loan归O、assign关联归ROW、out关联归OUT；C0 OPEN/CLOSE归O、ASSIGN/FILL归ROW、OUT_RETURN归OUT、REGISTER归CORE、FETCH归FETCH。来源端口固定绑定，body中的owner不能让不相干caller自选权限。

## D. 实际存放、接口与组合

### D1. 两块原语及记录边界

D0/C0均READ_WIDTH=WRITE_WIDTH=20、depth512、9bit地址、OUTPUT_REG0、WCLK/RCLK同core候选100MHz。全词WE11为两半10bit；无事务时WE00/RE0，不能只用ADDREN0假停。WADDREN/RADDREN在实际WE/RE置1，避免继承旧地址。

| D0类别/kind | 每份body/word | 合法index及基址 | owner |
|---|---|---|---|
| 0 registry | 906/46 | 0…3，0/46/92/138；最终183 | CORE |
| 1 loan原OPEN+borrow | 451/23 | 0…3，184/207/230/253；最终275 | O |
| 2 assign关联 | 64/4 | 0…4，276/280/284/288/292；最终295 | ROW |
| 3 outKEY关联 | 164/9 | 0…2，296/305/314；最终322 | OUT |

D0用323词/6460bit，原body6240，padding220；323…511不授记录访问。kind4…7非法；每份末word未用高bit规范0。真实目录与RowCtx不被这些关联取代。

| C0 kind/族 | 各body的词数 | 连续地址/末端（inclusive） | owner |
|---|---|---|---|
| 0 OPEN | req20/reply24 | req0…19/reply20…43 | O |
| 1 ASSIGN | req21/reply30 | req44…64/reply65…94 | ROW |
| 2 FILL | req17/reply17 | req95…111/reply112…128 | ROW |
| 3 OUT_RETURN | req28/reply28 | req129…156/reply157…184 | OUT |
| 4 CLOSE | req25/reply25 | req185…209/reply210…234 | O |
| 5 REGISTER | req46/reply46 | req235…280/reply281…326 | CORE |
| 6 FETCH | req16/TERM18/ACK18 | req327…342/TERM343…360/ACK361…378 | FETCH |

C0每族只有index0；379词/7580bit，原body7407，padding173。379…511不授访问，kind7非法。选择**各body独立词对齐**，不用上轮另一拼接373词口径。两块合702词/14040bit、padding393，剩322词未分配。FETCH重放TERM342给其真实原响应端，ACK350仍是原下层确认记录，不把两个body当一份新上层reply；其具体消费适配仍MR-B01。

### D2. 文档内无实现体接口

CMD52高到低＝epoch32/op2/table1/kind3/index3/word_count7/owner3/ticket1；ACK61＝原52/status2/reason5/done1/matched1；READ_IMAGE966＝原52/body914。各valid/ready不在body，均同core沿前握手、全文held及目的private。

op0 WRITE_RECORD、1 READ_RECORD只table0/D0；2 WRITE_CACHE、3 MATCH_REPLAY只table1/C0。WRITE的word_count必须精确等整记录/整组；READ_RECORD等该记录；MATCH_REPLAY等本组总词数。表/role/index/epoch/词数/来源保持资格错误在首WE/RE前拒绝。

ticket只是内部单在途运输相位，不是资源身份或会话号：冷合法开始0；两端CMD、DATA、ACK及source pin都真实关闭后才翻转供下一事务；同core无重传/滞留队列，不允许凭ticket重放业务。错误echo/未知旧结果保在途并隔离；不因ticket相等或epoch更新清债。真实记录的完整ref/key/seq由原owner保存并核验，物理index永不代它们。内存单元不新增64bit耗尽命名空间。

ACK status0 COMPLETE/reason0/done1；1 REJECTED/非0/done0；2 QUARANTINED/非0/done0；3非法。本族reason5：0NONE、1FIELD、2SESSION、3LOCKED、4SOURCE_CHANGED、5NATIVE_FAULT、6UNKNOWN、7RESET_ISOLATION，8…31非法，不能cast成业务族reason。matched仅MATCH_REPLAY有效：hit1先真实交付IMAGE再形成成功ACK；miss0无IMAGE但done1，只说明比较/窗口判定完成。其它op matched规范0。

IMAGE只用于READ_RECORD或MATCH_REPLAY命中。body的低位为实际选中一份记录/回复，未用高位0；FRAME/kind/原CMD全过程匹配。接收方仍核其完整业务身份和合法编码，再使用其值；完成内存copy不等业务grant/effects闭合。MATCH请求部分逐词核源当前原请求与cached完整原请求，包括其所有未用padding；不只比seq。

### D3. 真正的保持与热状态

WRITE_CACHE的原request/reply（FETCH三份）必须在**整个组**期间各自持久pin；当前源body总线最多914bit，每次由受保护原记录提供一份，切segment只由引擎固定沿推进。不能只pin当前20bit词或在request写完就允许原reply变化。WRITE_RECORD同理。读取IMAGE的914bit assembly是源IMAGE实际payload，不是额外免费窗口；目的还需独立完整private。

本卡明确增加的逻辑运输body：CMD/ACK双端2×(52+61)=226；IMAGE双端2×966=1932，合2158bit。源IMAGE中的914 assembly已计，不能再加同一实例一次，也不能无证删目的private。D0 valid16/C0 valid7另23bit，共列2181bit下界；phase、native pending/索引/compare/保持pin、epoch/仲裁/错误与owner热镜像另列，不是完整FF。原业务运输body仍保留，冷RAM不自动扣掉它们。

单引擎一次一个短事务，操作时锁目标组及源体，不与任何组同址读写。cachevalid在新写前撤销可见性，未完整写定不能再立；老cache替换须所有旧比较/复制已闭合，且原owner允许历史窗口退出。活loan/registry/关联不可用缓存替换规则销毁；改写/失效须其真实owner证明旧引用/运输已闭合。

正在读取的组物理锁在native pending/最后capture关闭、完整独立IMAGE已形成后可结束；IMAGE持有复制值。若该记录仍代表真实对象/loan权限，其业务引用由原owner独立pin到使用结束，不能拿RAM锁释放代其归还。元数据锁不跨任何DDR/B/R等待，不阻另一owner关闭。

## E. 中文操作及条件沿预算

1. 调度器只选沿前完整候选和真实可保持源/接收空间；建立源pin并形成CMD。只用一份CMD运输，未选候选仍在其原业务容器，未声明新的五份完整队列。已stop不选新ordinary，旧关闭/返还metadata继续可调度。
2. e0真实CMD fire并进入目的private；e1按旧完整资格核会话/role/table/kind/index/词数、cache/记录替换及DATA/ACK预留。坏者形成明确拒绝不WE/RE；任何新资格不穿透到同沿RAM访问。
3. 写L词：e2…e[L+1]各实际WE一个合法完整词，逐segment独立尾padding0；源旧体保持。e[L+2]按实际写计数/最后WE/no pending核整组完成并立valid；e[L+3]才形成ACK。ACK源最早e[L+4]fire，目的private最早e[L+5]消费，下一CMD不早于e[L+6]。
4. 读L词：e2…e[L+1]逐词RE；e3…e[L+2]capture前沿的同步RDATA与原pending索引；不读新同沿RE的数据。最后capture后e[L+3]形成完整IMAGE。其fire最早e[L+4]；e[L+5]形成ACK，最早e[L+6]fire，目的privatee[L+7]消费，下一CMD不早于e[L+8]。native输出直接进入已预留assembly，无无限capture队列。
5. MATCH_REPLAY：先按请求Lq词同步读/比较，最后比较capture在e[Lq+2]，下一旧资格沿才看累计结果。miss无IMAGE、成功ACK matched0；hit从e[Lq+3]开始回复Lp词RE，最后capture e[Lq+Lp+3]，IMAGE e[Lq+Lp+4]；DATA/ACK/私有消费依前述独立阶段，下一CMD不早于e[Lq+Lp+9]。FETCH逐body派送/确认由真实端点适配，不能自行把TERM/ACK合并为新可重复grant。
6. 所有以上沿预算都要求开始后源体持续稳定、DATA/ACK消费者已真实预留且按最早沿服务。Lmax92时WRITE下一命令≥98间隔；最大REGISTER比较46+回复46时MATCH下一命令≥101间隔。若这些条件成立，core100的最早局部间隔分别0.98µs/1.01µs；它们是最早可达调度界，**不是有停顿情况下的最坏服务上界**。实际公平服务必须加入每个owner的有限消费上界/等待数量及别的工作。
7. DATA或ACK慢时完整body保持、source pin继续；native已完不继续乱WE/RE。STOP/Q热状态照常锁定，不等当前事务完成才停止新业务。缓存已有原结果不能被新的partial写成功覆写；失败或源变化保原业务债、invalid/unknown和真实写前缀，不造成功。
8. cold合法共同隔离后valid/phase/ticket初始化，RAM mem不清；无valid记录不能RE。warm关闭按旧实际fire先结算，完成已接纳metadata、源pin/DATA/ACK及各业务实体后才参加原七owner QUIET/START；实际归属与下级应用证据MR-B02，不清valid制造静默。

不变量：仅owner授业务权限；组可见即全文完整；每RE有真实pending与原索引；source体/IMAGE/ACK不随UI或停止变化；cachemiss不证absence；slot复用与原typed身份寿命分离；元数据锁无DDR等待环。

## F. 语言及映射

C++业务N/A：纯RTL元数据单元候选；未来事件参考需独立标准/工具/容器/错误契约。共同数值为D的整数/词布局/padding；硬件执行为E的实际WE/RE/capture/消息；对应关系按完整原source identity与CMD/IMAGE/ACK实际事件，不能用数组写完当业务commit。

RTL A数值：地址9bit、wordcount/index7bit、actual-record位宽D；先宽扩核base+index<512。B时钟：同coreposedge/OUTPUT_REG0；C事件：形成/源fire/目的接纳/native/数据交付/ACK消费各独立；D valid：未提交/未初始化不可读；E保持：整组source pin和宽held真实存在；F时间：E条件沿表，不给伪最坏期限；G复位：cold隔离/warm真实排空；H配置：record来自历史原体，不当前UI；I存储：两1R1W/无同址/固定702词；J身份：index/ticket不授权，actualfullkey由owner核；K CDC：本单元无跨域RAM，SCAN/pair及其它mailbox另验；L实现：Ti60F225/I3/SV2009/Efinity2026.1.132候选，两RAM及2181bit列出下界，实际推断/STA/FF/LUT未运行。

## G. 实施及验证计划（NOT_RUN）

冻结MR-B01…03及联合baseline→指定批准→control_record_scheduler/ram_engine与owner适配→真实厂商RAM模型和独立事件参考→局部/整包回归→综合/布局布线/route后STA/bit。当前无这些文件。

| TEST | 要求/事件 | 期望 | 状态 |
|---|---|---|---|
| MR-T01 | 01/03 所有记录及边界 | 各最后词正确、不访问未分配/512，padding0，旧43词GRANT组拒绝 | NOT_RUN |
| T02 | 02 role/裸index/epoch/ticket错 | 首WE/RE前拒绝；不能grant或释放业务，错echo保债 | NOT_RUN |
| T03 | 03/04 写中source变/停止/冷旧mem | 不立完整valid；STOP独立；合法cold由valid隔离，不按reset清mem | NOT_RUN |
| T04 | 03/04 cache读取并新写、DATA/ACK停顿 | 组不覆写，完整复制后才解物理锁，业务引用仍独立 | NOT_RUN |
| T05 | 05 全文同seq异body/cachemiss/旧成功 | 无重grant；miss不no-loan；完整padding/会话先核 | NOT_RUN |
| T06 | 04/05 同沿lastcapture与IMAGE、warmepoch | 新捕获不穿透；旧义务真实结束才授权，ticket不擦债 | NOT_RUN |
| T07 | 03/04 五owner竞争/关闭/时钟 | 独立STOP、无跨DDR锁；真实有限服务与全面资源/STA另核，不靠最早沿证明 | NOT_RUN |

## H. 双向追踪

| REQ | 单元/接口/草图 | 拟符号（未生成） | TEST/证据 |
|---|---|---|---|
| 01/03 | RAM布局/D1/E3–5 | control_record_ram_engine | T01/03/04；static模型能力，未运行 |
| 02/04 | scheduler/owner/D2–3/E1–2/7 | control_record_owner_adapter | T02/03/07；实际源pin接线OPEN |
| 05 | cache/owner/D2/E5/8 | control_completion_cache_adapter | T05/06；原结果规则，未实现 |

每个拟单元可回溯上述原存储/关闭缺口；没有实际代码/注释/测试位置。

## I. 门槛及J/K/L恢复/实录/阅读

MR-B01：实际五owner源private/held pin、完整semantic验证、FETCH三body读取适配、响应/IMAGE空间及冷记录销毁依据尚未联合接线；不能仅凭本端口声明完成组合。MR-B02：元数据子owner warm关闭/epoch应用与原七owner、真实热状态/错误隔离尚未冻结。MR-B03：全机唯一实例/实际FF/LUT/源体word选择/仲裁及有停顿的最坏服务、文件输入manifest/工具检查未完成。

规范10.3①B行为；②C职责/来源；③D布局及候选接口；④E状态/不变量/中文沿；⑤F语言映射；⑥B/D/E走查；⑦G/H验证追踪；⑧上述阻塞不满足；⑨保存读回/有限审阅另记；⑩v0.1与来源明确而实际实现基线未冻结。NOT_READY，不生成代码。

相对上轮报告，本卡选择独立body对齐379词和单core短事务引擎，新增宽IMAGE真实副本及metadata/valid下界，明确SCAN冷记录属于pair域而非本core RAM。布局/保持/接口/时序都是重要设计选择，不能按内部优化继承批准。原来源保持hash；将来吸收要共同修订schema、草图、资源和测试。当前只有纯文档/只读分析，未新增算法work、业务代码、功能测试、sim/map/PNR/STA/bit/hex、网络安装、数据库/正式state/硬件动作。按A→B/C→D→E→F/G/H/I阅读；完整任务及理解验收待实际证据。
