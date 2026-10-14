# TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001：生产控制冷记录的实际存放候选 v0.2

2026-10-04。LOCAL_STORAGE_DESIGN／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。按 PLAN_TEMPLATE 完成两块core域RAM的布局、短事务及真实保持设计；保持十一项、1920×1080、完整Canny/原识别/板载DDR目标。本卡不把局部RAM容量或条件时钟沿预算当成完整工程证明。

## 通用计划字段

- Goal：将HANDOFF持久关联与完成缓存映射到实际EFX_RAM10，明确源体保持、组提交、读取及替换保护，不靠20bit输出冒充宽held。
- Current state：v0.1已选323word关联及379word独立body缓存；本v0.2具体计入双端完整CMD快照，修正FILL缓存owner，并冻结两短事务的本地提交顺序及FETCH三body缓存形成时点。没有算法实现。
- Target state：选定本局部布局/接口，与实际owner/热状态/epoch及全机服务联合冻结后进入指定批准、实施和软件验证。
- Gap/Open questions：MR-B01…03见I；全O目录、共享FE、DDR/CDC、全资源/最坏服务仍OPEN。
- Assumptions：core100为候选时钟；RAM两端同一core时钟；单短事务引擎；固定五个业务owner；每次CMD形成前实际原body及资源身份已被唯一业务owner保留。
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

REQ03：每事务先预留响应/读取完整私有接收容量，并把完整源体复制进CMD；真实CMD fire后引擎只用目的private快照，不在RAM锁内等外部提供下一词。整组完整写入后才valid。读/比较/复制期间同组不可替换，禁止任何同址读写。元数据端口锁不跨DDR、renderer或SCAN等待。

REQ04：源held/目的private是真实容量。20bit RAM不能直接代914bit稳定体；取消/STOP仍履约旧已接纳记录，STOP热槽不等RAM忙而失效。

REQ05：完整cache精确请求比较后才重放原回复；miss只是不存在当前可重放窗口，不能证明旧OPEN无创建，不重新grant已退资源。所有会话先核，cold/warm reset不擦真实旧债。

正常：CORE实际保有906登记private→短写46词并取得真实内存ACK→仍由CORE原pending保候选身份→另写REGISTER缓存92词并取得正确ACK→CORE才允许registered业务资格及914 ACK对外有效。两事务之间RAM不连锁，存储valid不授早登记。边界：OPEN缓存原459变461需24词，组总44；只写旧43词须拒绝，不把最后class截掉。失败：读取旧cache期间新完成候选可在其原owner保持，不能覆盖正在读的cache，也不能占未列无限队列。

## C. 职责、连接和推进

五业务owner已有真实private/held → 单调度器选择并复制完整源体 → CMD966双端held/private → RAM短事务引擎 → 原始记录/缓存两RAM → READ_IMAGE及ACK → 真实业务owner核full key/事实并提交业务状态。DDR/RX/ROW/SCAN不经过本元数据引擎传大数据。新提议停止采用原独立STOP/sticky，旧关闭仍允许用短事务引擎。

| 单元 | 唯一职责/状态 | 限制 |
|---|---|---|
| RECORD_SCHEDULER | 一份CMD966源held、真实owner选择及轮转索引；统一DATA/ACK目的private | 不变更业务记录，不新分配borrow/row_seq；单总事务无隐藏5份新CMD队列 |
| RECORD_MEMORY_ENGINE | 一份CMD966目的private、phase/word计数、读取/比较、响应及组有效位 | 原源体914是该private的一部分，不另省或重复计；不持目录权限，不等DDR回复 |
| CORE/O/ROW/OUT/FETCH | 提供其已经真实拥有的全记录/当前请求；接收并核全identity，保留结果和各自ledger | 原资源pin及业务private按真实关闭条件保留；复制值不授原实体复用，实际集成须MR-B01核对 |

业务owner编码3bit：0CORE、1O、2ROW、3OUT、4FETCH，5…7非法。D0 registry归CORE、loan归O、assign关联归ROW、out关联归OUT；C0 OPEN/CLOSE归O、ASSIGN归ROW、OUT_RETURN归OUT、REGISTER/FILL归CORE、FETCH归FETCH。FILL_TERM323由ROW/FILL发给CORE，最终ACK331的判定者是CORE，不能把该接收完成缓存给ROW当第二writer。来源端口固定绑定，body中的owner不能让不相干caller自选权限。

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
| 2 FILL | req17/reply17 | req95…111/reply112…128 | CORE |
| 3 OUT_RETURN | req28/reply28 | req129…156/reply157…184 | OUT |
| 4 CLOSE | req25/reply25 | req185…209/reply210…234 | O |
| 5 REGISTER | req46/reply46 | req235…280/reply281…326 | CORE |
| 6 FETCH | req16/TERM18/ACK18 | req327…342/TERM343…360/ACK361…378 | FETCH |

C0每族只有index0；379词/7580bit，原body7407，padding173。379…511不授访问，kind7非法。选择**各body独立词对齐**，不用上轮另一拼接373词口径。两块合702词/14040bit、padding393，剩322词未分配。FETCH重放TERM342给其真实原响应端，ACK350是已被FETCH正确消费的下层确认记录，不作为新上层reply。形成和重放次序见D4；原actor实际接线仍MR-B01。

### D2. 文档内无实现体接口

HEADER52高到低＝epoch32/op2/table1/kind3/index3/word_count7/owner3/ticket1。**CMD966＝HEADER52/source914**；ACK61＝原HEADER52/status2/reason5/done1/matched1；READ_IMAGE966＝原HEADER52/body914。各valid/ready不在body，均同core沿前握手、全文held及目的private。ACK和IMAGE回原header，不嵌套再复制966bit CMD；scheduler的当前CMD源体及原actor pending仍供全身份核验。

op0 UPDATE_RECORD、1 READ_RECORD只table0/D0；2 WRITE_CACHE、3 MATCH_REPLAY只table1/C0。UPDATE_RECORD word_count精确等D1该记录词数L时为WRITE_RECORD，word_count=0时唯一解释为RETIRE_RECORD；其它词数非法。WRITE_CACHE word_count必须等整组；READ_RECORD等该记录；MATCH_REPLAY等本组总词数。表/role/index/epoch/词数/源布局错误在首WE/RE前拒绝。READ_RECORD的source914规范全0；UPDATE_RECORD低位为D1完整record，其余高位0；MATCH_REPLAY低位是当前完整原request，其余高位0。RETIRE的0是显式动作编码，不是实际RE数量：引擎仍按kind派生固定L逐词读取，不能因header0直接跳到done。

WRITE_CACHE source低位为该族**完整原final ACK**，其余高位0。固定从此不可变快照派生各独立body，不能把914bit当成整REGISTER组1820bit拼接：

| 族 | source中有效body/原请求提取（含端点） | 写入组词数 |
|---|---|---:|
| OPEN | 原GRANT461；OPEN＝source[460:74] | 20+24=44 |
| ASSIGN | 原ACK581；request＝source[580:172] | 21+30=51 |
| FILL | 原ACK331；TERM323＝source[330:8] | 17+17=34 |
| OUT_RETURN | 原ACK553；request＝source[552:8] | 28+28=56 |
| CLOSE | 原ACK499；request＝source[498:8] | 25+25=50 |
| REGISTER | 原ACK914；request＝source[913:8] | 46+46=92 |
| FETCH | 原ACK350；TERM＝source[349:8]；FETCH315＝source[349:35] | 16+18+18=52 |

每个segment按原body低词在前独立输出20bit，末词高padding写0。先核source的规范高0及该族原业务编码，再发WE；full semantic合法性、真实grant及真实终态由原owner判定。CMD目的快照整事务不移位破坏；动态选词是已计源体的组合选择，不能隐加914bit第二移位寄存器。读取assembly仍在已计IMAGE源914中，只有IMAGE valid0且旧数据真实关闭时允许开始新assembly。

914不是20的倍数。选词可用组合高补0的920bit视图，**不增加920bit状态寄存器**；每segment原body界外均输出0。读IMAGE前其914bit assembly规范置0，capture只把该body范围内实际有用位放到对应低位，末词高padding另核0、不写到914之外。REGISTER906末词仅6有效位，ACK914末词14有效位；不能用固定20bit窄片跨过assembly上界，也不能把两个缓存segment直接拼成一份914。

ticket只是内部单在途运输相位，不是资源身份或会话号：冷合法开始0；两端CMD、DATA、ACK及source pin都真实关闭后才翻转供下一事务；同core无重传/滞留队列，不允许凭ticket重放业务。错误echo/未知旧结果保在途并隔离；不因ticket相等或epoch更新清债。真实记录的完整ref/key/seq由原owner保存并核验，物理index永不代它们。内存单元不新增64bit耗尽命名空间。

ACK status0 COMPLETE/reason0/done1；1 REJECTED/非0/done0；2 QUARANTINED/非0/done0；3非法。本族reason5：0NONE、1FIELD、2SESSION、3LOCKED、4SOURCE_CHANGED、5NATIVE_FAULT、6UNKNOWN、7RESET_ISOLATION，8…31非法，不能cast成业务族reason。matched仅MATCH_REPLAY有效：hit1先真实交付IMAGE再形成成功ACK；miss0无IMAGE但done1，只说明比较/窗口判定完成。其它op matched规范0。

IMAGE只用于READ_RECORD或MATCH_REPLAY命中。body的低位为实际选中一份记录/回复，未用高位0；table/kind/index/原HEADER全过程匹配。接收方仍核其完整业务身份和合法编码，再使用其值；完成内存copy不等业务grant/effects闭合。MATCH请求部分逐词核CMD目的快照内完整原请求与cached完整原请求，包括其所有未用padding；不只比seq。FETCH命中只读出TERM342，不把ACK350发到ROW；ACK350是整个valid组内保存的原真实确认值，本端口不另外读出它，也不以缓存存在授新AR。

### D3. 真正的保持与热状态

每份CMD966在形成时一次从原完整记录复制source914；其源held直到CMD fire保持，目的private此后直到本元数据事务关闭保持。引擎WRITE/MATCH只读此目的快照，所有segment可由D2固定抽取，不在操作中回读原owner的可变body。原actor仍保持当前事务身份、实际源/loan/银行权限和业务运输，不因CMD已复制或cachevalid1就允许实体复用。读取IMAGE的914bit assembly是源IMAGE实际payload，不是额外免费窗口；目的还需独立完整private。

本卡明确增加的逻辑运输body：CMD双端2×966=1932；ACK双端122；IMAGE双端1932，合**3986bit**，比v0.1增加1828bit。目的CMD的914写源和源IMAGE中的914读assembly已分别计，不能再加同一实例一次，也不能无证删目的private。D0 valid16/C0 valid7另23bit，共列**4009bit**下界；phase、native pending/索引/compare、epoch/仲裁/错误与owner热镜像另列，不是完整FF。原业务运输body仍保留，冷RAM不自动扣掉它们。

单引擎一次一个短事务，操作时锁目标组及源体，不与任何组同址读写。cachevalid在新写前撤销可见性，未完整写定不能再立；老cache替换须所有旧比较/复制已闭合，且原owner允许历史窗口退出。活loan/registry/关联不可用缓存替换规则销毁；改写/失效须其真实owner证明旧引用/运输已闭合。

正在读取的组物理锁在native pending/最后capture关闭、完整独立IMAGE已形成后可结束；IMAGE持有复制值。写锁在整组实际WE及valid提交结束后解除。若该记录仍代表真实对象/loan权限，其业务引用由原owner独立pin到使用结束，不能拿RAM锁释放代其归还。**物理锁释放不等单引擎可接第二CMD**：当前CMD/DATA/ACK/private仍真实关闭后才复用。元数据接收空间在开工前预留；其实际接纳、核验和复制只等本地容量，不等业务ACK对外ready、DDR或SCAN关闭。若这些本地消费者仍停顿，单引擎仍busy，不宣称其它owner服务有最坏上界。

### D4. 业务提交与两短事务的唯一owner顺序

存储valid仅说明指定记录全文已经写定，不能单独授业务权限、absence或FREE。actor的现有接纳private/原事务ledger是真实pending；不能增加未计数的每owner宽shadow再省原private。拆事务期间登记/借用/assign/out的实际身份及资源仍被原actor保留，普通读者不能绕过其业务提交门。

| 操作/唯一判定者 | 已存在的真实承诺及短事务顺序 | 业务发布/退休边界 |
|---|---|---|
| REGISTER / CORE | 原906 private与D parent/exec保持；WRITE_RECORD D0 46词→消费正确memory ACK；生成内部不可变914候选→WRITE_CACHE C0 92词→正确memory ACK | 两项均真完成才registered业务资格及914 ACK有效；早到STOP独立sticky，已存D0不能因此开启OPEN；两次总138 WE，不是一条7bit count命令 |
| OPEN成功 / O | O先在真实目录/原pending形成唯一grant及pins，并保持其真实created事实。WRITE_RECORD loan451的23词→正确ACK；以内部原GRANT461快照WRITE_CACHE44词→正确ACK | 再对外形成原GRANT，STOP也不撤历史成功。D0 valid仍0、写中或两事务之间都可能已创建，不能由valid0/cachemiss推no_loan_proved；CORE的NO-LOAN created_seen只由CORE正确消费class0置位，O不能直接写它 |
| OPEN原始不创建 / O | 必须NO-LOAN class1全部真实证据成立；不写loan；只WRITE_CACHE44词 | 正确memory ACK之后对外原拒绝；诊断class2/未知class3不授absence。慢对外reply仍是原owner held债 |
| ASSIGN成功 / ROW | 原RowCtx/input/row_seq已真实占位并保原assign_seq；WRITE_RECORD关联64的4词→正确ACK；WRITE_CACHE51词→正确ACK | 再对外ACK581；assoc valid不代RowCtx/input资格。错误不造FREE或再次分配 |
| FILL接收 / CORE | 正确接纳原TERM323并核本地当前assignment与真实事实；原private更新完成ledger、产生不可变ACK331候选；WRITE_CACHE34词 | 成功memory ACK后ACK331对外有效；原ROW所持FULL input/renderer/out仍按其真实生命周期关闭，不由本缓存回收 |
| OUT_RESERVE关联 / OUT | 实际按原ROW_TARGET472授予bank后保真实KEY/目标/代次；WRITE_RECORD KEY164的9词→正确memory ACK | 再按原OUT族形成业务grant，D0仅复制KEY关联而不是完整bank目录；失败/停止保真实已占bank，不由valid0退还 |
| OUT_RETURN / OUT | 原未发布bank的真实关闭/返回决定先不可逆地记录于其actual ledger；WRITE_CACHE56词 | 正确memory ACK后原ACK553对外有效；槽复用另等所有原运输/引用闭合和D0退休，不依valid0判断返回成功 |
| BULK_CLOSE / O | 先核并冻结原loan真实关闭决定；WRITE_CACHE50词 | 成功memory ACK后ACK499对外有效；实体FREE与原reply/value-cache独立；旧D0 loan退休另等真实旧loan引用/运输閉合 |
| FETCH终结 / FETCH | 真实关闭单burst后TERM342形成并交付ROW；ROW真实接纳后回ACK350；FETCH核并消费正确完整ACK350，保副本→WRITE_CACHE52词 | ACK350尚未真实存在前不能伪造三body缓存或等cache再发TERM。写中仍可定位原active TERM/事务完成窗口；正确memory ACK后退出该本地cache job。DDR route引用已按其独立真实证据关闭，不为冷复制再借回旧route |

后三类失败/取消/Q仍遵守原族真实状态和闭合事实；本metadata ACK不升级为业务成功。拒绝坏echo或unknown时保真实原pending/效果与第一错误，不能用MEM done1补业务proof。命中历史缓存只重放原回复，不重新安装registry、申请input或创建loan；FETCH重放仍为342，后续返回ACK按原真实完成窗口处理。

D0正常销毁选RETIRE_RECORD，不把WRITE全0或cold clear当正常接口。原owner先真实冻结“旧业务effects/本地生产/ordinary读写引用/原typed运输与借用已闭合且不再授新操作”的依据，保该实际完整身份及source原record，才形成op0/count0 CMD。这里不要求本次RETIRE pending/CMD/ACK先消失，也不要求依赖D0退休才能建立的最终FREE先成立：退休候选只持元数据值/原资格，不授新ordinary。engine锁同D0记录，须其valid1、授权旧epoch且逐词完整等原record/padding；e[L+3]用旧比较累计决定，匹配才撤valid并形成明确memory ACK。无valid、错body/role/session或未知保原状态并拒绝/Q，不用miss自证退休。撤valid后到RETIRE ACK实际正确消费仍禁owner槽复用，所有残存CMD/DATA/ACK/本地pending结束才可新WRITE；正常重放由原typed完成窗口处理，不再发第二RETIRE。

registry须原CORE报告/loan/producer/ordinary本地引用均闭合；loan须O原真实关闭承诺及原typed运输/借用闭合；assign关联须ROW原RowCtx/input/renderer/输出的业务effects及ordinary引用真退出；out关联须OUT原发布或私有路径的银行/完整ROW_TARGET及全部旧代次ordinary引用真退出。每项仍可保本次退休身份直到memory ACK，而最终FREE/reuse须其后才能成立，避免先FREE才RETIRE的环。后两种64/164bit冷body不能单独证明全部身份：原owner在CMD形成前后继续核并pin完整RowCtx/ROW_TARGET/physical bank generation，禁止旧CMD、待选退休候选及owner pending跨实体复用。engine全文相等只保护写定记录，不授这些业务关闭事实；具体真实proof与热镜像接线仍MR-B01。

cache组替换在旧比较/复制关闭后由原owner按其高水位/完成窗口规则申请，新完整组发布前撤valid；原pending仍负责已经成功的历史资格。STALE/会话非法/诊断不能无条件替换已有last-completion，内存端不另创建第二高水位权限表。

### D5. 停止、旧会话与本地锁

STOP/warm请求到达沿先结算旧真实CMD/WE/RE/capture/业务grant/fire，再设hot停止资格。禁止新ordinary操作，保留当前快照、原pending、所有成功/可能grant；允许旧关闭和结果cache履约。已有loan而D0 valid0的窗口，O保其实际created/grant；尚未正确消费class0的CORE保any_published/unresolved及可能grant，不能提前自置created_seen或依据未写定/no reply推absence。正在写的旧epoch只能完成在旧会话；未建立真实QUIET前不更新engine授权epoch、不清23valid、不重置ticket。

读取到末RE不等关闭：必须把最后旧RDATA实际capture进原pending索引，下一沿形成独立完整IMAGE才放物理锁。若DATA/ACK慢，已形成的复制值及其valid继续保持，不能再用同一assembly装下一job；source CMD/业务pending与old ticket仍有义务。全业务引用与物理RAM锁分别关闭，warm结果不把其它owner已经拥有的grant撤掉。

本引擎是core域元数据子单元，不新增全局第八epoch owner。它的当前CMD/回复/pending/热错属于相关原owner的QUIET义务；全23valid仅在各实际活实体退休、复制缓存退出旧授权域和全部本地运输结束后，按原授权START重建。七owner到底由哪条真实下级关闭/应用接口汇合本引擎及目标owner，仍MR-B02；不能用一份空busy值代其真实closed/applied ACK。

### D6. 本局部唯一热实例候选

为防止将未列状态视为免费，本v0.2明确选择下列一套共享元数据sequencer，scheduler和engine同core，不各复制一份FSM/完整运输槽。六份body的唯一物理位置仍为D3：scheduler CMD源held/ACK及IMAGE目的private，engine CMD目的private/ACK及IMAGE源held。

| 状态/唯一writer（共享sequencer，除所注） | 位数 | 有效期/含义 |
|---|---:|---|
| phase | 4 | 0IDLE/1SEND_CMD/2CHECK/3WRITE/4COMMIT_WRITE/5READ_COMPARE/6DECIDE/7READ_COPY/8MAKE_IMAGE/9SEND_IMAGE/10MAKE_ACK/11SEND_ACK/12DRAIN/13QUARANTINE，14…15非法；跨阶段保旧真实义务 |
| ticket | 1 | 单总运输关闭后翻转，不是业务身份 |
| owner轮转cursor | 3 | 0…4五owner；每完整job结束后下一owner，5…7非法；各owner多族选择及全机服务MR-B03 |
| selected_owner | 3 | CMD形成时锁住固定端口的owner，直到本job关闭；与header核，不由caller任意改角色 |
| effective_len | 7 | 当前段或整组实际词数≤92；RETIRE取kind的L而非header0 |
| issued_count / captured_count | 7+7 | 当前native段真实事件数；转段先核上一段真实完成，不能回绕或混末capture |
| native_pending valid/index/segment | 1+7+2 | 每RE后唯一待capture，保存其原索引与段；连续每沿capture旧pending并登记新RE，末RE仍保债 |
| compare_equal | 1 | 全文/padding累计，只在真实capture更新；下一沿DECIDE使用完成旧累计 |
| native_lock | 1 | 共一份目标物理锁，绑定CMD中的table/kind/index，不复制23锁；释放条件D3/E |
| sticky_fault / first_reason | 1+5 | 首次本地错误冻结，不用后续成功擦掉；业务错误矩阵/epoch恢复另属原owner |
| 六运输源valid/目的private_valid | 6 | CMD、ACK、IMAGE各两端；ready为真实空/已预留资格，不能当这些body免费或无有效性 |
| authorized_epoch | 32 | 旧会话全部真实关闭且授权START之后才应用，不由CMD自报更新 |
| **本局部列出热位** | **88** | 不包含原五业务owner的资源pin/退休pending/高水位/关闭证明、下级epoch运输及全机状态 |

88加D0/C0 valid23为111，与运输3986合列**4097bit**逻辑状态候选和两块RAM。4009仍是body+记录valid小计，不能再称其包含全部本局部热位。phase/lock/epoch等若未来证明派生或共享只能按真实实例扣一次；当前先按本表保留。宽mux/比较/地址算术、owner热镜像和原pending/LUT、实际综合FF及性能不由此表证明。MAKE_IMAGE之前native_lock不随DATA ready变化；DRAIN中仍不接第二CMD。原actor的外部业务ACK等待留原held，不在元数据端添加WAIT_OWNER宽队列；实际本地接收/核验/复制服务MR-B01/03。

WRITE_CACHE的issued_count是整组全局词游标，段由kind及D1固定词边界组合派生，不再另存current_segment。读/比较时issued/captured为当前段计数，pending的index/segment保存实际原RE；MATCH最后请求capture先核真实issued/captured/pending归属并建立DECIDE资格，再为reply段准备0计数和Lp。下一DECIDE旧资格沿使用完整compare累计启动reply首RE；不能把新同沿capture直接穿透决定，不能既复用本表计数又暗增另一段游标。实际LUT/时序及这些计数不变量仍须T11和综合核验。

## E. 中文操作及条件沿预算

1. 调度器只选沿前完整候选和真实源/接收空间；复制完整source914形成CMD966。只用一份CMD运输，未选候选仍在其原业务容器，未声明新的五份完整队列。原actor有真实资源pending并保持到其业务关闭，不因形成快照结束。已stop不选新ordinary，旧关闭/返还metadata继续可调度。
2. e0真实CMD fire并进入目的private；e1按旧完整资格核会话/role/table/kind/index/词数、cache/记录替换及DATA/ACK预留。坏者形成明确拒绝不WE/RE；任何新资格不穿透到同沿RAM访问。
3. 写L词：e2…e[L+1]各实际WE一个合法完整词，逐segment独立尾padding0；CMD目的快照保持。e[L+2]按实际写计数/最后WE/no pending核整组完成并立valid、解除物理锁；e[L+3]才形成ACK。ACK源最早e[L+4]fire，目的private最早e[L+5]消费，下一CMD不早于e[L+6]。WRITE_CACHE最多92，REGISTER的46+92是D4两job总138词，不跨表合为一CMD。
4. 读L词：e2…e[L+1]逐词RE；e3…e[L+2]capture前沿的同步RDATA与原pending索引；不读新同沿RE的数据。最后capture后e[L+3]形成完整IMAGE。其fire最早e[L+4]；e[L+5]形成ACK，最早e[L+6]fire，目的privatee[L+7]消费，下一CMD不早于e[L+8]。native输出直接进入已预留assembly，无无限capture队列。
5. MATCH_REPLAY：先按请求Lq词同步读/比较，最后比较capture在e[Lq+2]，下一旧资格沿才看累计结果。miss无IMAGE、成功ACK matched0；hit从e[Lq+3]开始回复Lp词RE，最后capture e[Lq+Lp+3]，IMAGE e[Lq+Lp+4]；DATA/ACK/私有消费依前述独立阶段，下一CMD不早于e[Lq+Lp+9]。FETCH逐body派送/确认由真实端点适配，不能自行把TERM/ACK合并为新可重复grant。
6. RETIRE读/比L词的RE/capture同步骤4；e[L+3]按旧完整累计决定并撤valid/解锁，e[L+4]才形成ACK，最早e[L+5]fire、e[L+6]目的消费，下一CMD≥e[L+7]。无DATA；header count0不改实际L。停止不抢走已接纳退休的原身份，错误不撤未知记录。
7. 所有以上沿预算都要求CMD快照真实完整、DATA/ACK消费者已真实预留且按最早沿服务。Lmax92时WRITE下一命令≥98间隔；最大REGISTER比较46+回复46时MATCH下一命令≥101间隔。若这些条件成立，core100的最早局部间隔分别0.98µs/1.01µs；它们是最早可达调度界，**不是有停顿情况下的最坏服务上界**。READ_RECORD/MATCH/RETIRE请求RE与返回capture内部不反压；从e1取得锁到WRITE e[L+2]解除为L+1间隔，READ/RETIRE到e[L+3]为L+2，MATCH hit到e[Lq+Lp+4]为Lq+Lp+3，最大分别93/48/95间隔。解锁新状态须下一旧资格沿才可观察：从e0真实接纳到可见native free，最大WRITE/READ或RETIRE/MATCH分别95/50/97间隔。此是无内部故障且按F候选时钟满足的本地native锁预算，不覆盖检查/排队、DATA/ACK停顿、业务归还、全机服务或实际STA。FETCH命中只需请求16+TERM18词，不取18词ACK作上层reply。实际公平服务仍须每个owner有限消费上界和等待数量。
8. DATA或ACK慢时完整body保持、原actor资源pin继续；native已完不继续乱WE/RE。STOP/Q热状态照常锁定，不等当前事务完成才停止新业务。缓存已有原结果不能被新的partial写成功覆写；失败保原业务债、invalid/unknown和真实写前缀，不造成功。
9. cold合法共同隔离后valid/phase/ticket初始化，RAM mem不清；无valid记录不能RE。warm关闭按旧实际fire先结算，完成已接纳metadata、源pin/DATA/ACK及各业务实体后才参加原七owner QUIET/START；实际归属与下级应用证据MR-B02，不清valid制造静默。

不变量：仅owner授业务权限；组可见即全文完整；每RE有真实pending与原索引；source体/IMAGE/ACK不随UI或停止变化；cachemiss不证absence；slot复用与原typed身份寿命分离；元数据锁无DDR等待环。

## F. 语言及映射

C++业务N/A：纯RTL元数据单元候选；未来事件参考需独立标准/工具/容器/错误契约。共同数值为D的整数/词布局/padding；硬件执行为E的实际WE/RE/capture/消息；对应关系按完整原source identity与CMD/IMAGE/ACK实际事件，不能用数组写完当业务commit。

RTL A数值：header index3bit、native地址9bit、词数/相对词索引7bit、actual-record位宽D；base与索引先至少10bit扩展核和<512，再窄化native9bit，RETIRE header0仍读实际L，914末词只复制合法body位并核padding。B时钟：同coreposedge/OUTPUT_REG0；C事件：形成/源fire/目的接纳/native/数据交付/ACK消费各独立；D valid：未提交/未初始化不可读、不能据其授业务FREE；E保持：完整CMD快照/宽held真实存在，业务资源pin另保；F时间：E本地native预算与条件运输沿表，不给伪全机期限；G复位：cold隔离/warm真实排空；H配置：record来自历史原体，不当前UI；I存储：两1R1W/无同址/固定702词；J身份：index/ticket不授权，actualfullkey由owner核；K CDC：本单元无跨域RAM，SCAN/pair及其它mailbox另验；L实现：Ti60F225/I3/SV2009/Efinity2026.1.132候选，两RAM、4009body/valid小计及4097含88局部热位候选，实际推断/STA/FF/LUT未运行。

## G. 实施及验证计划（NOT_RUN）

冻结MR-B01…03及联合baseline→指定批准→control_record_scheduler/ram_engine与owner适配→真实厂商RAM模型和独立事件参考→局部/整包回归→综合/布局布线/route后STA/bit。当前无这些文件。

| TEST | 要求/事件 | 期望 | 状态 |
|---|---|---|---|
| MR-T01 | 01/03 所有记录及边界 | 各最后词正确、不访问未分配/512，padding0，旧43词GRANT组拒绝 | NOT_RUN |
| T02 | 02 role/裸index/epoch/ticket错 | 首WE/RE前拒绝；不能grant或释放业务，错echo保债 | NOT_RUN |
| T03 | 03/04 CMD fire前held违约、目的快照破坏；fire后外部body/UI变化、停止/冷旧mem | 前两项故障不造完整成功；已正确捕获的快照不受后续外部body/UI变化影响；STOP独立；合法cold由valid隔离，不按reset清mem | NOT_RUN |
| T04 | 03/04 cache读取并新写、DATA/ACK停顿 | 组不覆写，完整复制后才解物理锁，业务引用仍独立 | NOT_RUN |
| T05 | 05 全文同seq异body/cachemiss/旧成功 | 无重grant；miss不no-loan；完整padding/会话先核 | NOT_RUN |
| T06 | 04/05 同沿lastcapture与IMAGE、warmepoch | 新捕获不穿透；旧义务真实结束才授权，ticket不擦债 | NOT_RUN |
| T07 | 03/04 五owner竞争/关闭/时钟 | 独立STOP、无跨DDR锁；真实有限服务与全面资源/STA另核，不靠最早沿证明 | NOT_RUN |
| T08 | 02/04 RETIRE count0、旧record/role/epoch错、末RE后返回未捕获 | 按实际L比较；正确闭合/完整等值才撤valid，ACK消费前不复用；invalid不代absence | NOT_RUN |
| T09 | 03/04 REGISTER46+92两job、OPEN23+44窗口同沿STOP | 原actor pending/实际grant保留；中间valid不授业务资格或no-loan | NOT_RUN |
| T10 | 03/05 FETCH先TERM再ACK350、cache写中同seq重试 | 不等未存在ACK才TERM；active完成窗口精确重放，不再AR；cache回复仅342 | NOT_RUN |
| T11 | 03/04 906/914末词、段切换及全native单实例 | 写padding0；只复制合法位、不窄片越界；比较末capture后旧资格才决定；4097只覆盖列出实例 | NOT_RUN |

## H. 双向追踪

| REQ | 单元/接口/草图 | 拟符号（未生成） | TEST/证据 |
|---|---|---|---|
| 01/03 | RAM布局/D1–3/D6/E3–7 | control_record_ram_engine | T01/03/04/08/11；static模型能力，未运行 |
| 02/04 | scheduler/owner/D2–6/E1–2/8–9 | control_record_owner_adapter | T02/03/07/08/09；实际源pin/退休proof接线OPEN |
| 05 | cache/owner/D2/4/E5/9 | control_completion_cache_adapter | T05/06/10；原结果规则，未实现 |

每个拟单元可回溯上述原存储/关闭缺口；没有实际代码/注释/测试位置。

## I. 门槛及J/K/L恢复/实录/阅读

MR-B01：本卡已明确快照、FILL owner、FETCH形成次序、两job业务门及RETIRE操作，但实际五owner原private/热pending pin、完整semantic与退休proof、FETCH真实确认/错误适配和响应空间尚未联合接线；不能仅凭本端口声明完成组合。MR-B02：元数据子owner warm关闭/epoch应用与原七owner、真实热状态/错误隔离尚未冻结。MR-B03：全机唯一实例/实际FF/LUT/源体word选择/仲裁及有停顿的最坏服务、文件输入manifest/工具检查未完成。

规范10.3①B行为；②C职责/来源；③D布局及候选接口；④E状态/不变量/中文沿；⑤F语言映射；⑥B/D/E走查；⑦G/H验证追踪；⑧上述阻塞不满足；⑨保存读回/有限审阅另记；⑩v0.2与来源明确而实际实现基线未冻结。NOT_READY，不生成代码。

v0.1原字节67E64D557F8CA1469D9320D86719BF8E4442B50EEE6D9E0333A2187A9678DF02保存在[修订前快照](design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001-v0.1-before-full-command.md)。本v0.2保留323/379词，改CMD52→966并实际计3986body/23valid/88局部热位共4097候选，修正FILL缓存归CORE，选定REGISTER/OPEN/ASSIGN两短job和FETCH ACK真实形成之后的缓存，补正常RETIRE与914末词操作，写清物理锁/运输/业务引用分别关闭及旧会话承诺。新接口/保持/时序属于重要设计修订，不能按内部优化继承批准。原来源保持hash；将来吸收要共同修订schema、草图、资源和测试。当前只有纯文档/只读分析，未新增算法work、业务代码、功能测试、sim/map/PNR/STA/bit/hex、网络安装、数据库/正式state/硬件动作。按A→B/C→D→E→F/G/H/I阅读；完整任务及理解验收待实际证据。
