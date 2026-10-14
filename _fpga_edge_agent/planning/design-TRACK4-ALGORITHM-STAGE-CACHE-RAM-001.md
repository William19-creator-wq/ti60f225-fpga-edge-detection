# TRACK4-ALGORITHM-STAGE-CACHE-RAM-001：单RAM阶段权限快照、单序列器与真实服务 v0.1

2026-10-05；**NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。只新写本设计卡。DRB、SC、LG、DIR、旧输入、R1及五份已验收交付入口保持只读；无业务源码、脚本、模型、TB、build、网络、硬件、数据库或正式状态动作。本卡没有继承R1的业务实施批准。

## 通用计划字段

- Goal：把SC的32×295bit热cache候选明确改成一块native20×512 RAM与唯一300bit装配体，给出保留完整身份、旧请求履约、归还和真实读取节拍的可审阅合同。
- Current state：SC v0.1保存9440bit hotcache及selected15845bit部分账；hot hit最早4间隔。DRB指出冷存消息候选须另计15RE与校验；相关实现均不存在。
- Target state：只有经O全文查验并完整写入/读回的行，结合真实热stage/child资格，才服务原LOOKUP；单序列器串行服务所有cache读写。正常功能、身份和效果不变，存储与服务变更显式冻结。
- Gap：CR-B01…07见I。本文给逐沿候选、selected空间变化及参数式；原publication白名单、完整admin/RETURN桥、算术时序及全机服务仍OPEN。
- Assumptions：Ti60F225、core同域posedge、同步高rst；100MHz仅候选。默认32行，H1第33行只为隔离的几何候选，不启用新family/HP。
- Open questions：完整权限/操作矩阵、旧published集合定位、admin值与资格保存、原目录/新cache仲裁、permit/effects服务、H1新族、完整FF/LUT/资源和实际时序。
- Dependencies：A的真实SHA与范围；Root H1布局/新族仍未作为冻结来源；不修改原SC/LG/DRB事实。
- Milestones：整体行为→唯一实例→字段/接口→中文微沿→正常与反例→服务/资源→联合缺口→读回→Root审阅→成熟后指定READY批准→work实现与验证。
- Detailed steps：当前仅设计保存/读回/交接，不自动启动任何实现或测试。
- State transitions：本卡NOT_READY；局部候选状态见E。正式PROJECT_STATE、ledger、Manifest及数据库不改。
- Artifacts and hashes：本卡最终全文读回后另报SHA/bytes/行数，A列实际只读来源；不存在新代码或可执行输入manifest。
- Validation：仅有限来源核读、精确整数与协议走查；G全部NOT_RUN。设计计算、RTL数值/协议、原语、资源、STA、bit和人工硬件观察分别取证。
- Failure handling：partial/unknown/错echo保原grant及expected；cache invalid不等free；不能清旧valid、RAM或额度假造quiet。
- Human approval gates：本轮获准纯设计；重要存储/流控/时序变化待联合成熟指定批准，不申请不成熟范围。
- Rollback：撤回新卡候选，原SC hotcache与DIR D3合同仍为旧设计输入；本轮没有旧源码或旧卡差异。
- Completion criteria：本轮只完成设计全文读回和Root审阅入口；完整算法/生产链fit、持续IO、仿真/PNR/STA/bit仍由整包真实证据承担。

## A. 状态、来源与采用边界

任务ID TRACK4-ALGORITHM-STAGE-CACHE-RAM-001，v0.1。控制面入口→config/AGENTS→AGENT_PROMPT→PROJECT_CONFIG→state/ledger→DB README已按序实际重读。唯一规范v0.2此前全文读过，本轮hash未变并重读344–415/468–650；PLAN_TEMPLATE本轮全文。数据库仍未配置，纯设计不启动数据库运行节点。

| 实际来源（控制面相对路径，除规范） | 本轮真实阅读/采用范围 | SHA256 |
|---|---|---|
| 工程根AI_Agent_代码可理解性规范_增补提案_v0.2.md | 前次全文、本轮限定344–415/468–650及标题检索；RTL A–L/映射/门槛/模板 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| planning/PLAN_TEMPLATE.md | 本轮全文154行 | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md，SC v0.1 | 本轮1–110/111–208/209–298分段全文；角色/616与740/旧held/全查与selected | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md，DIR | 本轮仅94–182逐行；descriptor/pin/holder全文、native/RETURN/部分175账 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| planning/design-TRACK4-ALGORITHM-LOAD-GRAD-001-v0.1-before-readiness-review.md，LG精确快照 | 初读LG原卡仅301–324，写作中修订后按相同SHA快照再次实际核301–324；191词/独立credit/真实logical与未知M_i | 25AFA46EAF11F59C1F2942708E803DCEE3C84B609619B27C2FA8C10E6804B22D |
| planning/design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md，DRB | 前次全文读回；本轮仅131–143/199–217，冷cache消息、单实例/时间与63191范围 | A2620B069928341CC316DFC7676902B394070D1B245A6C0FB9926F92F522996C |

本卡不是把SC的OPEN变成已解决事实：SC A3-01…05仍为联合输入缺口。ROOT给出的H1/RC_AUX新位置与单冷cache只是候选消息；本卡不改H1地址、不授新pin、不采用HP或新的内部H1族。原SC object0…25、LOOKUP schema和五child不能凭RAM还有空词自动扩展。

本次末核发现当前LG变为67457B/393行、SHA `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；不假报当前LG仍等原hash。Root已保存原卡64243B/387行的上述精确只读快照，本轮实际核该快照hash与301–324。另实际限定读当前LG65–67/347–349/369–371/383–385：这次修改区分审批前具体验证设计/审读与批准后实际执行，字段/协议D/E/F/H未改。本卡结构数量只绑定原精确快照，不声称全文重审当前LG；未来仿真/STA未运行不是先获批前阻塞。

## B. 整体外部行为与样例

| REQ | 可检查行为 |
|---|---|
| CR-01 | 原阶段H160、namespace、非零stage_generation、独立child revision、完整ref/version/grant与STORE动态资格逐项保留；operation_id/tx_seq0仍合法。 |
| CR-02 | 默认32行，每行295真实bit占15个20bit词；只有真实全查、15词写入、15词读回及后续提交成功后，才发布热row_valid。partial body不授权。 |
| CR-03 | 唯一LOOKUP req616/rsp740各depth1，唯一300bit assembly，唯一cache-RAM序列器；不声称4间隔或每拍一请求，不为INSTALL/UPDATE复制原语/端口/宽装配体。 |
| CR-04 | fence先停新publication，旧trusted promise/permit/effect/RSP照实履约；原snapshot失效须等该child真实access quiet。hot valid不是grant/归还/metadata退休证明。 |
| CR-05 | installed/return_requested/returned/pin_metadata_retired、五child与三stage、原expected/admin/RETURN/body、global序列均独立保留。hot row_valid清零不清这些债。 |
| CR-06 | 同一child权限变化不改变其它child revision；RETURN完成先于依赖它的typed CLOSE_ACK/admin完成，wholeholder退休最后汇合。 |
| CR-07 | cold读末capture后的后续沿才能使用完整body；native同时读写禁止，同址碰撞不靠模型行为。坏范围/word/padding/identity不发native/permit或保Q，不假释放。 |
| CR-08 | normal LOOKUP、INSTALL、CAPTURE、UPDATE、admin读/归还分享同一序列器；等待quiet在原owner台账中，不占引擎阻死旧LOOKUP。服务/响应反压有真实界，未给界不称正常达速。 |
| CR-09 | H1第33行仅隔离候选，不能把RC非法object26当合法内部H1；原32slot masks与M1正文保持原事实，未联合批准则row32不可访问。 |

正常样例：child0 SRC读资格已全查、slot0完整cache已提交、SC原source历史/STORE动态状态合法；原IF-SC03接纳req616后串行读15词，末capture后核原tuple/身份，再核足宽范围和STORE/permit空间，形成原740回复。reply fire只交付许可，其真实借用/effects还由原ledger收账。

边界样例：CLASS scope1开始fence，SRC scope0与GRAD scope2仍live。只封scope1新publication；已published CLASS请求仍用旧revision、旧cold row与可信白名单履约。scope1 quiet后invalidate/RETURN→其ACK502，stage0/SRC/GC仍保各自债。不能将stage0整体cache失效或等待整个stage0 FREE才RETURN。

partial样例：原BIND真实取得一pin后，在第7个cache词写入期间收到cancel。installed事实已经存在；本短native job保assembly/旧expected完成写入与核读，不开放ordinary。随后按真实grant办理关闭/RETURN，UNKNOWN保Q；不能丢半写body与300bit值、清mask后自称从未安装。

外部完整算法、1080p、五基础/六高阶、质量与显示60Hz不变。本卡只改变stage-kind权限快照的存放和服务；f_capture/f_import/f_complete仍独立，不新增算法fps要求，不通过拒绝合法目标维护所谓正常服务。

## C. 唯一模块职责与连接

| MOD | 唯一职责、状态位置与依赖 |
|---|---|
| CR-O | 原SC-O唯一管理stage/child、grant四mask、generation/revision与可信admin/fence来源；只有O可产生待写cache值。原M1正文与pin/descriptor/journal不移入新RAM。 |
| CR-SEQ | O内部唯一短native任务序列器，锁job_kind/row/word、req或可信admin借用，读写同一RAM；不是新增五份队列，不把等待actor quiet作为长端口锁。 |
| CR-RAM | 一块native20×512 1R1W、同core读写；本候选每沿最多一条RE或WE，OUTPUT_REG0、RE下一沿capture、完整20bit写WE11。 |
| CR-ASSEMBLY | 唯一300bit装配体；LOOKUP逐词覆盖后验证；WRITE/readback期间保原完整expected，逐词比较原值，不用第二300bit。 |
| CR-STORE/ACTOR | 沿SC原角色持有完整typedRQ/expected、trusted oldpromise、permit/borrow/journal/raw effects和RSP；冷cache不计算动态latest/valid/atomicity，不绕过STORE。 |

中文整体连接：

```text
原parent/fullcontext → O REGISTER/BIND/full查 → 原pin/descriptor/M1
                                       ↓ 可信完整cache值/旧grant事实
原STORE LOOKUP616 ─→ depth1请求 → 唯一CR-SEQ ↔ 一RAM480词
                                   ↕唯一300bit assembly
                                   ↓ fullcheck/range/STORE/permit
                         原LOOKUP740 held → 原STORE raw/effects
可信FENCE → actor封新pub，旧白名单继续 → 真实access quiet
         → invalidate → 完整RETURN/ACK → 依赖的CLOSE/COMMIT → metadata retire
```

整体检查：只有CR-RAM新增一实例；原目录RAM读取fullcheck、M1 context、pin写/RETURN仍走原真实端口及仲裁。不能把CR-SEQ、目录adapter和ROW/DDR当免费并行引擎。R5非stage-kind访问不走本coldcache，其原D3全查与共享目录竞争不删；H1没有因此得到新端口或授权。

## D. 字段、接口与组合检查

### D1. 295bit与native布局

本候选为原SC字段规定明确低位到高位布局，不更改原字段宽度；这是一项待联合批准的存储布局选择。

| 字段 | assembly bit | 含义/资格来源 |
|---|---|---|
| ref64 / version64 / grant64 | 0…63 / 64…127 / 128…191 | 原真实O descriptor/pin，完整相等；非零规则沿原合同 |
| base32 | 192…223 | 生产地址，不能沿旧26bit AP截断 |
| byte_capacity29 | 224…252 | 实际逻辑容量，rounded/tail资格仍由STORE全文规则核 |
| record_bits10 | 253…262 | 原精确对象格式，不把PROFILE1024当DDR record |
| item_capacity22 | 263…284 | 原fullcontext/descriptor几何，不信caller自报 |
| pin_access2 | 285…286 | 0READ/1WRITE/2RMW，3非法；物理保护RMW与ordinary资格分开 |
| typed_op_mask6 | 287…292 | 真实O/STORE权限快照，不替动态phase/admin资格；完整操作矩阵仍OPEN |
| snapshot_valid1 / immutable1 | 293 / 294 | 已全查的historical body标记/真实immutable资格；不能单独授权 |
| native padding5 | 295…299 | 实际写0；读时检查真实高5，不预先mask后假称正确 |

第j词=assembly[20j…20j+19]，j0…14，低词先。末词14低15bit对应280…294，高5bit实际0；不同于SC stage正文LG最后低19bit。LOOKUP read覆盖完整300bit包括高5，只有后续验证成功才用其中295bit。

| 配置 | native行/容量 | 有效/未分配范围 |
|---|---|---|
| 默认32 | 32×15=480词，logical9440bit/native9600bit/padding160bit | 行0…31；词0…479；480…511共32词640bit未分配 |
| H1隔离候选33 | 33×15=495词，logical9735bit/native9900bit/padding165bit | 新行32词480…494；495…511共17词340bit未分配；未冻前不访问 |
| 原语 | native20×512=10240bit，一RAM10候选 | 不把空词/标称padding授其它对象或新增queue |

默认映射严格沿SC106：slot0=SRC read、1=CLASS LOAD write、2=GRAD build write（retain1）；3…5=CLO CLASS/QUEUE/EDGE；6…31=RC objects0…25。retain0/QUEUE缺席仅据真实原J/fastpath规则，空tuple/row_valid0不能反推never-granted。SC object5字段可数值编码26，却**语义非法**；H1不能默塞slot32、object26或复用PROFILE/HP来取得权限。新内部family、holder、namespace、typed bridge和额外pin须Root独立明确并联合冻结。

地址计算先用row_index6和word_index4。row_base10=zero_extend(row6)×15；addr_sum10=row_base10+zero_extend(word4)，最大非法原始值945+15=960仍在10bit中。先核row<ROW_COUNT（32/候选33）、word<15、addr_sum<512且在该行15词内，之后才截成native address9；不因bit9丢失而回绕。row31是465…479；候选row32是480…494；row63/word15均拒绝且RE/WE0。ROW_COUNT是设计配置而非未验证运行时切换。

### D2. 热资格与cold value的分界

新增hot `row_valid[31:0]`表示本cold行已完整写/核读且可被相应stage/child资格引用；它独立于cold bit293与原四grant masks。普通成功必须hot row_valid=1、cold bit293=1、stage/child历史gen/revision/ACTIVE或trusted oldpromise资格与完整tuple一致。invalidate只清hot row_valid；cold旧body保留供RETURN/metadata事实使用，历史bit293仍可能1，不能据此发ordinary permit。

FENCE开始时不提前清row_valid：先更新原child新publication屏障，原oldpromise继续读原cold值；相应真实access quiet已是旧事实后才清hot row_valid。INSTALL/UPDATE短任务期间行hot valid0，cold可半写但不对ordinary可见；最后逐词readback验证后后续沿才可能置1，child BINDING/FENCING仍不开放新ordinary。跨一child多slot UPDATE须旧promise全部quiet后重核/重写该child所有存在slot，再发布完整新revision并消费ACTIVE_ACK；没有换grant的槽也重新绑定，新revision不覆盖其它child。

hot三stage H/gen/state/phase、五child revision/state/证据、installed/return_requested/returned/pin_metadata_retired四mask、两global allocator/permit allocator、原context/descriptor/pin assembly及req/rsp仍原独立实例。stagegen/childrevision不保在每个295bit冷行；因此只能在该stage旧metadata已真结束后复用stage header，换revision必须在封新/旧quiet/全组更新期间原子发布资格，不能用新header解释未重写的旧行。相关原admin完整expected/new revision候选值/lease仍须真实保存，未在selected表中的部分为CR-B03。

### D3. 交接合同（无实现体）

| IF | 提供/使用方与字段 | 接纳、保持、失败和所有权 |
|---|---|---|
| CR-IF01 LOOKUP | 原SC-STORE↔O；沿SC110原req616/rsp740 | 固定各depth1；req含完整H160/ns4/stage2/gen64/rev64/object5/op5/access2/ref64/version64/grant64/tx64/index32/count22，rsp完整echo/status2/reason6/permit64/address32/first_bit3/length7/record_bits10。不改原packed schema/状态编码；原typed reason显式映射仍OPEN。 |
| IF02 CACHE_TASK | 可信O fullcheck/INSTALL/CAPTURE/UPDATE/admin→CR-SEQ | job_kind2/row6只是定位，不授权限；完整可信原request/expected、tuple、H/gen/revision/epoch及grant事实由原O held/private lease锁定。WRITE值300bit含padding0只来自全查，不接受caller自报cache。具体admin packed体/源与目的存放未冻，不假填位数0。 |
| IF03 NATIVE | CR-SEQ↔CR-RAM | rd_addr9/RE1/ADDR_EN1/rd_data20，wr_addr9/WE2/ADDR_EN1/wr_data20，读写同core；WE=11完整20bit。每沿RE xor WE，未访问ADDR_EN/RE/WE0；RE后下沿capture，未发原语无pending，不读未分配词。 |
| IF04 FENCE/QUIET | 原O↔STORE/ACTOR，沿SC122–136 | 原completeKEY/oldrevision/typed spans白名单由可信ledger证明；caller不能自报old_held。FENCE独立接纳sticky/control，旧fire先记，不能组合撤ready/valid；quiet不等本RETURN/CLOSE_ACK/admin结果先交付。 |
| IF05 FULLCHECK/RETURN | O↔原DIR/holder/provider | pin512/descriptor640/fullholder/STORE动态资格与真实RETURN/ACK保持；invalid行仍凭installed与完整expected读取旧tuple。错echo不减count；returnedmetadata/ACK运输仍占额，不用缓存值代原完整查验。 |
| IF06 COMPLETION/RETIRE | CR-SEQ→原lookup receiver或可信admin owner | lookup740和admin completion各原实际held槽，不借未来pop预支空间；consumer实际capture或合法借用完毕才局部retire。admin完整宽度/ledger待联合；permit/raw effects在外层继续实存，reply fire不等stage quiet。 |

IF01的e0以下只指原SC桥实际合法接纳的fire，不另造坏请求准入/ready协议。原bridge决定ACTIVE或trusted FENCING oldpromise是否合法；未冻结白名单/原typed→raw对应时不开放candidate。原PUBLIC held req/rsp、REGISTER/admin/RETURN仍保持其完整body，不通过新row索引重建旧身份。

逐连接检查：SC的hot identity/geometry改由15词capture获得，但原fullH/gen/revision由真实热header及锁定req查验；STORE dynamic/JOURNAL仍从原owner来，不能从cold值猜。旧SC hot4间隔改为E3的21/23候选；未来caller timeout/调度必须重算，不能沿原4值。非stagekind/R5与REGISTER M1正文不走cold LOOKUP fastpath；其原全查与仲裁不变。H1新family桥、各admin消息与publish whitelist仍BLOCKING。

## E. 唯一序列器与中文微时序

### E1. 局部状态、寄存器和不变量

CR-SEQ state4候选0IDLE、1PRECHECK、2READ、3READ_TAIL、4VERIFY、5PURPOSE_CHECK、6PUBLISH、7WAIT_RESPONSE、8RETIRE、9WRITE、10VERIFY_READ、11VERIFY_TAIL、12WRITE_VALIDATE、13WRITE_COMMIT、14FAULT、15非法。job_kind2：0LOOKUP_READ、1WRITE_CAPTURE、2ADMIN_READ、3非法。row6/base10、issue_count4/capture_count4（0…15）、read_pending1/tag4、job_valid1/assembly_valid1/reason6各一个；43bit只是本卡具名sequencer字段，不是完整控制预算。

LOOKUP沿用原616/740槽；WRITE/ADMIN_READ借原可信admin完整held/private，其精确存放与新revision pending不免费。assembly300在一次job期间只归该job；LOOKUP用逐词实际读填满，WRITE保原value到整个readback及completion消费者真正捕获。pending tag保存上次RE的word index；每沿先capture旧pending，再提交本沿新RE的pending/tag，不用本沿新tag写旧data。

不变量：I1一个job、一assembly、一个原语；I2未完整capture不VERIFY，末capture不能同沿穿透成RSP；I3hot row_valid=0不取消installed/unknown；I4旧body/admin身份从受保护lease取得，不能用current J/gen回调；I5ordinary/fullgroup发布在完整cold写/核读之后；I6RE/WE不同沿，no同址collision；I7seq等待quiet时不锁引擎，WAIT_RESPONSE仅保已formed旧body；I8FAULT/Q保原assembly/tuple/expected和真实债，未给独立故障保存位置时不声称还能服务其它job。

### E2. 原fullcheck、INSTALL、CAPTURE与UPDATE

REGISTER M1原LG56/CLO22/RC113正文先真实写完、逐词读回、验证来源；REGISTER仅BINDING/预约，不授三livepin。各provider原BIND/prepare触发实际ACQUIRE一次，installed在真实grant证据成立时记，而非等cache valid。原pin/descriptor32+32全文与fullcontext/holder/phase核成功后，O构造300bit写值并锁历史source/expected lease。新RAM不是这个fullcheck的替代。

只有旧cache义务不存在（初装），或旧child真实access quiet、旧pin/returnedmetadata该结束的事实均已成立（更新）才开始WRITE。旧unknown/lateACK/partial pin不能被新行覆盖。UPDATE中的等待保在原O/child/transport台账，先释放短native job；不让CR-SEQ进入WAIT_QUIET占住引擎，因为旧typed LOOKUP/RETURN可能正是quiet前提。

多slot同child UPDATE保守逐条fullcheck、WRITE/readback；全部存在slot完成前child保持FENCING/BINDING，新revision候选由原admin完整expected保存。最终以原完整通知/ACTIVE_ACK消费后的后续沿开放新ordinary；未换grant的同行槽也核新revision资格，其他child不改。动态valid_count/tail/latest仍由STORE处理，不每像素写cache。原SC-A3完整mutation/fence桥未闭合不能启用。

### E3. 普通hit：15RE、21响应/23下一请求的最早候选

下表为所有原输入前提/消费者ready满足、native固定读延迟1、PURPOSE_CHECK组合时序可实现、原permit空间立即满足时的**最早沿合同**；不是实际100MHz承诺或最坏服务界。每行事件先用沿前旧值，沿后更新。

| 沿 | 唯一动作/旧状态 |
|---|---|
| e0 | 原IF01真实接纳req616，锁request；job/assembly valid隔离，300bit先置0供装配，不提RE/permit。 |
| e1 | PRECHECK固定stage/child/slot/range/原准入与hot资格，存合法base10与row；非法早退出不发RE。此沿不预支第一次RE。 |
| e2…e16 | READ逐词j0…14发RE；e2无旧capture，e3以后可同时capture上一词并发下一RE。RE与WE始终互斥。 |
| e3…e17 | 依据旧pending/tag capture真实word0…14到300bit；e17仅尾capture/记录complete，不能用该沿新assembly形成许可。 |
| e18 | VERIFY用已完整旧assembly，核高5为0、cold snapshot_valid、full ref/version/grant、历史H/gen/rev/ns/slot及实际原phase/准入；不匹配明确失败，无permit。 |
| e19 | PURPOSE_CHECK足宽范围、原STORE动态资格、原permit/ledger空间；成功只计算候选值，若消费者/allocator/检查未满足停在此且保持旧req/body。 |
| e20 | PUBLISH从已核旧事实写完整rsp740/permit唯一分配事实与valid；不在本沿交付新RSP。错误也只形成明确原内部status/reason，不做raw effect。 |
| e21或以后 | WAIT_RESPONSE最早RSP真fire；保持反压期间全部echo/原revision/address/permit，native端口不提新任务。 |
| e22或以后 | RETIRE只结该lookup本地req/RSP/pending/assembly借用；permit/effects仍由原ledger保留。该沿后进入IDLE。 |
| e23或以后 | 下一个原请求最早真fire；不能靠e21 pop同沿提前接纳或覆盖oldrequest。 |

所以response最早21个interval，连续请求fire最早相隔23个interval；15个RE issue与15capture是不同事件，不是30个额外周期。100MHz纯尺度210ns/230ns，只是未STA候选；不继承SC热hit4间隔，不宣称每拍吞吐。invalid slot/hot缺失可在e1后走原明确error completion，不能读未分配行；需要fullbody才能发现的padding/tuple错仍须完整读取。cachemiss/error均不能令pin count或installed消失。

地址共同数值：index32+count22先33bit；item_end×record_bits10先43bit，rounding加7先44bit；byte offset从完整结果取，base32+offset/length以足够42bit域预检，另object_end=base32+capacity29先33bit。先核item/byte逻辑边界、length1…64、physical DDR arena与完整rounded/RMW初始化规则，再收窄32bit address/3bit first_bit。乘加大组合能否在单PURPOSE_CHECK沿实现是CR-B05；若分级，必须把新增间隔和各pending位实列，不能继续引用21/23。

### E4. WRITE_CAPTURE：同一300bit、15WE＋15RE核读

本卡主动选择逐词readback作为新RAM发布证据；原SC没有把此成本冻结，故它是新的未批准服务/存储候选。readback只比较native值和可信原expected，不能覆盖expected后和自己比。

| 相对沿 | 唯一动作/可见性 |
|---|---|
| e0 | 可信admin原job接纳，锁row及原完整历史lease，将padding0的300bit完整写值保存到唯一assembly；行hot valid0，assembly是expected而非可见cold权限。 |
| e1 | PRECHECK核row/word/全查来源、snapshot_valid1、padding0/精确格式、旧quiet与禁止覆盖条件，reason置原NONE；非法保原grant/expected并形成明确失败或Q。 |
| e2…e16 | WRITE j0…14全20bitWE11；末词高5实际0。assembly不变，cancel/fence只记真实旧事件，不中断本短事务或丢partial。 |
| e17…e31 | VERIFY_READ逐词RE0…14；最后WE已是旧事实才RE；每沿最多一个nativeissue。 |
| e18…e32 | 旧pending/tag捕获读回词，与未覆写的expected对应20bit逐词比较；reason sticky保存不匹配，末capture沿不直接发布。 |
| e33 | WRITE_VALIDATE核全部15capture/完整padding/累计比较与原identity/lease仍合法；错误hot0/Q保原expected/真实installed，不借Q冒正常服务。 |
| e34 | WRITE_COMMIT只有旧validate成功且原发布资格仍成立才置row_valid；若cancel/fence已取消新ordinary，则可保存已核cold body，但hot仍0/child不ACTIVE，实际grant仍需关闭。 |
| e35 | PUBLISH形成原admin completion held；表示存入/核读事实与是否可发布必须区分，不自报普通ACTIVE。具体原完整admin回复体/语义桥CR-B03。 |
| e36或以后 | 原admin使用者真正capture或合法借用结束后completion fire；源assembly/lease此前保持。 |
| e37或以后 | RETIRE关闭本job/pending/借用，后进入IDLE；旧grant或child还未关闭时其ledger仍保留。 |
| e38或以后 | 下一cache任务最早接纳。 |

每行WRITE_CAPTURE最早38个任务占用间隔、15WE＋15RE，不是15拍全成功；原目录fullcheck/ACQUIRE/holder/context与admin等待在此之外。ADMIN_READ复用E3的15词读取、末capture后完整校验与PURPOSE_CHECK，最早同21响应/23下一任务；它不要求ordinary ACTIVE或hot row_valid1，但必须有可信原installed/RETURN/metadata expected lease，并继续原pin/holder全文核验。不能把读取旧cold tuple当RETURN已完成。

### E5. 仲裁、fence、保持与真正quiet

原每类actor/可信admin各保原有限held槽，CR-SEQ只在IDLE选一job，不另造并发输入队列。选择是一次有限原语事务，不抢占15词read/write/readback；已accepted/formed rsp不能被紧急UPDATE换掉。正常公平/consumer最坏等待仍需CR-B04；只给round-robin名字不证明服务。INSTALL/CAPTURE/UPDATE的fullcheck与cache短job经同O调度，原DIR/M1端口实际读写另仲裁，不为每操作声称一个engine。

FENCE独立control接纳先登记当沿旧fire，随后原actor封新publication；accepted LOOKUP或trusted已published typed产生的有限raw spans仍用旧revision。不得直接把row_valid或STORE ready组合清0挡旧held。需要具体完整KEY/cutoff/span白名单的可信桥，且其原保留位置不删除（CR-B02）；cache索引/自报old_held不构成白名单。

相应STORE权限/geometry/可影响旧访问的phase变更必须服从这个屏障，旧promise排空前不能先提交新权限，再用“当前phase不合法”拒绝已经承诺的旧span。真实动态latest/初始化/atomic效果仍按原STORE事件办理，不能冻结成猜测快照；完整哪些事件必须fence、哪些是本阶段合法dynamic推进在CR-B01逐表联合。

access quiet必须核原published集合、lookup req/rsp/job/pending、accepted native/DDR/journal/permit/borrow/effects/heldRSP都真结束；只有后续旧quiet允许invalidate/RETURN。已经retained且依赖无writer/RETURN的COMMIT/CLOSE admin不是新ordinary写，保持其原完整expected/资格，accessquiet不等它自身末级结果先交付；最终metadata retirement仍等admin/terminal/transport真空。WRITE readback虽只本地native，发生cancel时也保存其完整借用/tuple，不能因hot0抹除。

原RETURN核精确tuple和真正quiet→真ACK消费→pins_closed后后续typed CLOSE_ACK；returnedmetadata/运输仍占原额度。POINT writer→READ须原WRITE effects完成、RETURN旧writer、真实retained COMMIT immutable/token、metadata运输该闭合的已闭，再授新READ/fullcheck/revision；GRAD沿LG/SC close-before-parent-commit。所有partial/unknown保四mask/expected，不能以缓存miss、lookup replyfire或row_valid0代返还。若FAULT必须长期保唯一300bit而无另经批准存放，CR-SEQ阻塞其它任务；本卡不虚构故障无限吞吐。

stage FREE只在原五child/parent/terminal/controls/transport/query/native/effects全部旧真空后；清相应hot标记隔离cold旧字，不强制整RAM清零。warm reset保global stagegen/caprev/permit与原债、已issued native/旧pending按原全域隔离合同处理；未知Q不复用。同步rst火0和禁新接纳不能被误用为“外部grant已不存在”的证明，cold重建必须原硬件/所有域隔离授权。

## F. 服务、selected空间与语言合同

### F1. 一实例的每操作代价

令Q是真正内部LOOKUP数，K为真实cache row安装/重写数，U为各次UPDATE受影响存在slot数，V为admin cold row读数。Q不等LG的29,030,405 logical数量；一typed CLEAR/DENSE/RMW可能多个span/lookup，SEAL/COMMIT空数据走原admin，不生成0byte permit。没有Q/M_i不报告帧时间。

| op | 新cache原语/局部最早占用 | 完整额外服务/限制 |
|---|---|---|
| hit LOOKUP | 15RE；最早RSP21、下一req23 | queue、STORE动态检查/permit、reply停顿、算术新增级数、外层raw/effects另计；一次depth1串行 |
| ADMIN_READ | 15RE；局部最早21/23 | 原fullpin/descriptor/holder/RETURN/control等待另计，无hot valid也不授ordinary |
| INSTALL/CAPTURE | 每row15WE＋15RE；短job最早38 | 原32+32 fulllookup、源context/lease、真实ACQUIRE/grant写、prepare/active ACK另计 |
| UPDATE k存在slot | cache15kWE＋15kRE，保守38k短job | 至少原64k full查issues＋该stage56/22/113正文读；旧quiet/RETURN/metadata/新grant/新revision全部真实计 |
| INVALIDATE/FENCE | 热资格变化不必零写15词 | 原可信全体oldpromise/close/RETURN/admin桥与最长等待另计，不是免费清债 |

固定32条首次全安装情景：SC原cold context191read＋32×64 full查=2239 readissues；新增cache readback480使这一列至少2719 readissues，新cache写480。若同情景完整grant更新64write/条，其2048write＋正文191write＋cache480write也是2719；这是条件计数，原allocator/origin/lease/provider/journal和各原ACK仍另计，不是整体start固定2719拍。

对一个正常hit，候选服务槽间隔可表达 `C_lookup_slot = 23 + W_select + S_precheck + S_native + S_verify + S_purpose + S_reply + S_retire`，各S为超过E3基准沿的真实非负等待/新增级数；这是从可选该task到其下一task接纳机会的槽账，response交付最早21另记。若使用已证最坏界，以上量代相应界才能成为上界。native当前读延迟1不允许随意填S_native0而忽略共享端口排队。对非空且仅由正常全词成功READ/WRITE任务组成的序列，令Q_h为正常成功hit数，以首taskfire到末responsefire定义 `C_seq_window ≥ 23Q_h + 38K + 23V − 2`；若计到末本地RETIRE则扣1。如此不把单task e0→e21误写成23个实际等待间隔。early-error、cachemiss与其它控制事务依其真实分支另计，Q_total不能直接当Q_h；外部fullcheck/admin/阶段控制M_i与所有真实停顿仍加在实际路径中，此式不是墙钟帧上界。

如后续给出真实最坏服务参数，可按唯一序列器逐task求 `C_job_max = C_base + ΣS_max + W_max`，完整stage序列再加fullcheck/phase/NUM/DDR/close并按实际依赖求完成界。fresh调度不能替旧held；正常硬期限/持续camera/1080p60沿DRB重新核，不以名义1.6GB/s或旧hot4间隔代冷cache。H1、R5非stagekind均不自动纳入Q或略去其原目录争用。

### F2. cold-to-hot selected变化（不是完整FF/XLR）

| 唯一候选项 | 默认32 selected bit/实例 | 与原SC的关系 |
|---|---:|---|
| 保留原SC selected除hotcache | 15845−9440=6405 | 三stage699、五revision320、两next130、四mask128、五child40、context2257、LOOKUP1358、REGISTER219/37、permit65、pin/desc1152仍各原实例；只扣9440一次 |
| 新唯一assembly | 300 | READ全部实际capture；WRITE/readback保expected；不是额外32×300或免费source/receiver副本 |
| 新hot row_valid | 32 | 与四grant masks/child state独立，不把RAM bit293当即时屏障 |
| 新具名sequencer | 43 | state4+kind2+row6+base10+issue4+capture4+pendingtag4+pending1+jobvalid1+assemblyvalid1+reason6；算术/ledger/完整admin/arbiter等未知另列 |
| **selected候选合** | **6780** | 15845−9440+300+32+43；相同已列口径净减9065bit，不能称实际省9065FF或全机fit |
| 新cold RAM | **1×native20×512** | 实际使用9600bit/480词，完整原语10240bit；热selected不把cold body再算9440FF |

原SC的REGISTER词37保其M1串行词/held槽，新CR-SEQ43负责cache-RAM pending/word，不将未知同名控制免费合并；如未来同一实际寄存器复用，必须给依赖/同时寿命证明后去重。stage next/permit allocator若原RAW唯一实例合并，也按实际scope去重，未证明不提前扣。完整REGISTER_ACK291、FENCE/admin/ACTIVATE/RETURN/METADATARETIRE源/目的held与expected、partial granted tuple保存/新revision pending、public旧白名单/KEY/cutoff、arithmetic pipeline、permit/raw/journal effectledger、原seq/hot与M1/目录arbiter状态、RMW/transport/各actor上下文/全CDC仍未知；不是零bit。这些与63191/SC15845可能重复，禁止直接相加后宣称准确全机FF。

H1隔离候选另账：在原hot假设中第33行295bit＋四mask各加1合**299bit**，所以旧selected类比16144，但H1独立完整holder/family/epoch/revision/control未包含。改cold后该行另15词300nativebit（真实295＋padding5），每个原四mask32→33合132而不是128，新row_valid也32→33；同一300assembly/43seq的有限字段已容33。仅相同具名口径selected为16144−9735+300+33+43=**6785**（比32版多5热bit），不代表H1授权/完整账。33 masks不能继续称32；HP/H1 identity与newfamily映射仍CR-B06，默认row32禁访。

原DIR11RAM及SC M1正文不动：RESULT0…281；LG282…337/CLO338…359/RC360…472、余39词；三stage3814body/191nativewords3820，目录native用101408bit仍SC候选事实。新cache专用一RAM不借M1余39词，也不缩冷完整PROFILE/RJ。若沿原非共享FE部分175前提，新增cache成为**部分176**；共享FE部分167则168。H1第33行同一新RAM能容的几何不增加第二cache RAM；其它新对象/冷holder等未知。176不含完整全机热状态/所有未映射实例，不是fit证据，不从256比例作PASS。

### F3. RTL A–L与三份契约

| 项 | 本任务合同/未决 |
|---|---|
| A数值 | D1的295/300/末高5、row6/word4/addr10→9预检；所有原身份不截断，index/end乘加先扩宽；seq/gen非零/终生不重用，operation/tx0合法 |
| B时钟 | 唯一core posedge，native读写同域、OUTPUT_REG0、RE后下一沿capture；沿前fire与沿后寄存器分开，TB未来post-NBA查新状态/pre-edge记真实事务 |
| C接纳 | 原req/rsp valid&&ready&&!rst真fire；仅旧IDLE/空间成立接下一task，pop同沿不预支；本卡不改原typed/oldpromise准入 |
| D有效 | row_valid/coldbit293/assemblyvalid/jobvalid/installed独立；ordinary资格invalid不发新ordinary native/permit，有可信原expected的ADMIN_READ按E4仍读旧完整body；旧pending真实完成，正常0数据不等absence |
| E保持 | req616/rsp740、原admin expected与唯一assembly、完整sideband固定到真实交付/借用关闭，fence/cancel不换旧revision/tuple |
| F时间 | E3 15RE、21RSP/23next；E4 15WE+15RE、36completion/38next均最早候选；所有真实等待/算术pipeline/消费者界OPEN |
| G复位 | 同步高禁fire/newRE/WE，旧物理与外部grant隔离仍须原CONTROL；warm保global序列/unknown/expected/pending，不将RAM清零当RETURN |
| H配置 | 固定ROW_COUNT32；33仅未来联合冻结；权限/phase由可信owner，更新先封新/旧quiet、全写核读、资格最后发布，旧fires先记 |
| I存储 | 一20×512 1R1W、单300体、每沿最多一native op、RE1cycle、全WE11、高padding0、不同时读写/同址碰撞；空词不授对象 |
| J身份 | 原H/J/ns/gen/rev/ref/version/grant/tx/body一致，固定slot/child不混，cold locator无独立授权，旧回调不借current header |
| K CDC | 本单元同core无新CDC；原camera/DDR/VIDEO multi-bit稳定桥不由本卡证明，epoch/session/warm隔离仍原owner |
| L实现 | Ti60/SV2009/现装Efinity只为候选目标，native实例/参数须后续原语和实际map/PT/PNR/STA核；100MHz与selected6780/部分176都不是实测 |

C++生产代码N/A，本轮不生成模型。共同数值契约：独立参考按原字段/范围/精确身份与D1word布局给gold，保留所有非法与padding检查。硬件执行契约：真oldfire/native RE/capture/WE/formed held/RSP/permit/RETURN旧事实逐事件计，不能由函数返回替时间。对应契约：原typed事务→有限raw span/LOOKUP→独立permit/effect→原RSP/close/RETURN的完整KEY/gen/rev/序号一对多关系；比较时按真实交付/commit，不能从DUT内部row_valid/seq状态生成oracle或把cache invalid判grant已退。

## G. 独立反例、实施与验证计划（全部NOT_RUN）

当前下一步仅联合设计审阅/补齐I；将来获指定批准后先原语单实例/完整字段，再LOOKUP，后INSTALL/UPDATE/fence/RETURN与整包。拟职责 `stage_cache_native_store`、`stage_cache_sequencer` 为计划名称，不是已生成模块、脚本或TB；可合在一个O单元中，实例数不因文件名变化。

| TEST | 初始/事件/独立期望与观察 | 状态 |
|---|---|---|
| CR-T01 | 所有32映射、末slot31/word14、word15/row63及32版row32；独立表计算地址，非法RE/WE0、无截断回绕、末高5实际0。 | NOT_RUN |
| T02 | 15RE连续/停顿、旧pending tag与新RE同沿、最后e17capture；独立native时刻表检查e18才verify/e20formed/e21fire/e23next，不仅看PASS标签。 | NOT_RUN |
| T03 | bit0/64/128/192/253/285/293/294错、padding5非0；完整旧tuple/权限/namespace/gen/rev逐一错，绝无permit/effects，不假减count。 | NOT_RUN |
| T04 | full300 write15/读回15、每词人为独立gold/bitflip、cancel第0/7/14词、readback最后词错；expected始终原体，错Q/installed保留，高padding不能mask掉。 | NOT_RUN |
| T05 | reply/admin held长停、WRITE/LOOKUP/UPDATE同时候选、始终一assembly/一seq/native一op；次序/实际服务和有限capacity独立scoreboard，已formed不替换。 | NOT_RUN |
| T06 | FENCE沿旧held/同沿fire、trusted published typed后续raw、无可信白名单自报old_held；旧债履约、新publication封住，不能row_valid0/ready0堵quiet。 | NOT_RUN |
| T07 | CLASS scope1返还、SRC/G仍live/closing；独立5revision/四mask、returnedmetadata仍占额；RETURN不等其typedACK/wholeholderRETIRE。 | NOT_RUN |
| T08 | partial realgrant而cache未发布、错ACQUIRE/RETURN echo、latecallback与新stagegen；不擦installed，不能从miss推never-started/free。 | NOT_RUN |
| T09 | POINT writer→read与E=0 token、GC close-before-parent-commit、原retained admin；有效dataquiet不等依赖RETURN的admin回包，admin held不能随valid消失。 | NOT_RUN |
| T10 | UPDATE同child多slot含未换grantslot、同时其它child req、真ACTIVE_ACK反压；全组新revision资格最后开放，别的child旧revision保持。 | NOT_RUN |
| T11 | warm/cold隔离、native在途/reset、max generation/exhaust；保旧expected/effects/identity，未全部旧quiet不能FREE；fault无额外300保存位置则诚实阻塞。 | NOT_RUN |
| T12 | 单seqQ/K/V从独立typed→raw trace导出，readback/startup/UPDATE全文开销、其余R5/ROW/DDR公平与deadline同时核；不乘logical13N/29M直接造fps。 | NOT_RUN |
| T13 | 默认H1族/object26非法，33几何单独fixture须新合法族/holder/bridge指定批准；原RC0..25不变，33mask与额外H1债独立，未批准不运行。 | NOT_RUN |
| T14 | 实际唯一RAM/FF/LUT/DSP/clock/port/STA/bit；只在批准work与工具baseline核，partial176/6780计算不能替map或PNR。 | NOT_RUN |

验证前冻结独立字段gold、合法原SC/LG/DIR/物理接口hash、原controller mode、clock/consumer服务profile、pre-edge/post-NBA取样、种子和全部调度。真实15RE/15WE/capture/compare/response计数、最大等待与source前后hash必须输出；有限timeout标失败或未知，不替RETURN/Q恢复。仿真、工具资源、布局时序、bit、人工硬件与用户理解各记实际scope；本轮都未运行。

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 拟职责（未生成） | TEST/期望来源 | 实际代码/证据 |
|---|---|---|---|---|
| 01/07 SC110–118 | O/SEQ/ASSEMBLY，IF01/03，D1/E3 | stage_cache_lookup | T01–03/12，独立原身份/地址/native事件 | 待实现/NOT_RUN |
| 02/03 SC198/DRB133 | RAM/ASSEMBLY/SEQ，IF02/03/06，E2/4/F2 | stage_cache_native_store/sequencer | T02/04/05/14，原可信snapshot与原语读回 | 待实现/NOT_RUN |
| 04/05 SC122–146 | O/STORE/ACTOR，IF04/05，D2/E5 | stage_cache_permission_barrier | T06–11，原published/RETURN/admin ledger | 待实现/NOT_RUN |
| 06/08 SC132–178 | O/SEQ/原providers，IF05/06，E5/F1 | child_cache_closure/schedule | T05–12，原fullclose事实/独立服务trace | 待实现/NOT_RUN |
| 09 SC106/Root消息 | O/原family，D1/F2 | optional_H1_cache_binding | T13，指定新族未冻结 | 不适用默认32/NOT_RUN |

反向：冷store服务完整snapshot所以必要；单seq/assembly来自有限资源和真实原语；hot row_valid因cold资格不能即时隔离且旧grant不能被抹除；barrier/childclosure来自兑现旧promise/避免RETURN环；readback因本候选选择真实cold完整发布证据，成本显式承担。未来代码符号/actualhash/测试结果再定位，不编空泛要求合理化新功能。

## I. NOT_READY门槛与当前缺口

| BLOCKING | 证据缺口、影响和下一项 |
|---|---|
| CR-B01 | SC/LG完整phase/operation/permission与typed/raw/admin桥、production32bit adapter尚未联合冻结；保证原接口/无错误CAST/实际源目的完整体后复审。 |
| B02 | FENCE可信旧published KEY/cutoff/有限span白名单、旧promise允许LOOKUP的接线/保存/计数未闭；不能ready0或self-declared old_held绕过，先列真实slots与逐事件原来源。 |
| B03 | INSTALL/CAPTURE/UPDATE/admin completion/RETURN/partial granted tuple及新revision候选的完整held/private/lease存放未合账；43/300不代全体transport，不能做实现。 |
| B04 | 单seq/O/native目录/M1与R5/ROW/DDR公平、最长consumer停顿/许可/effects/quiet服务界，Q/K/V/M_i及真正正常期限未知；按DRB独立fc/fi/fd核。 |
| B05 | 尚须联合冻结原语具体输入baseline/参数、PURPOSE_CHECK组合或具体流水级数、目标clock与唯一实例设计预算，并完成G具体工具/独立方法/判据设计审读；分级或多issue须先改微沿/字段账。真实原语仿真/综合/STA按指定批准后执行，不作为先获批条件，当前未测仅是不具实际验收证据。 |
| B06 | 可选H1 row32族/holder/namespace/schema/额外pin/299或33mask完整债与Root独立布局delta未联合；默认禁止，不能自动采用HP/SC object26。 |
| B07 | 继承SC partial/unknown/RETURNmetadata与warm外部隔离/故障保存/回收实际桥未完；原四mask、expected/fullcold继续保，不能清资格假close。 |

规范10.3：①B有整体/样例；②C唯一职责/连接与原复用；③D字段/接口相容但B01/02/03未完；④E实际沿与中文草图；⑤F RTL A–L/三契约；⑥D/E反例及G场景；⑦G/H初始追踪；⑧无当前阻塞不满足；⑨保存/最终全文读回/实际SHA另交Root；⑩v0.1仅设计/输入hash明确，新依赖未联合。保持NOT_READY，不请求不成熟实施批准。

审批前须关闭的是以上有限接口/身份/存放/级数/服务设计与具体验证准备缺口，不是要求先产生业务代码或运行G测试。批准后再生成独立输入、RTL/TB/runner并执行仿真/综合/STA；未运行本身不使成熟设计永远不能READY，实际测试结果也不能替代尚未闭合的设计合同。

## J. 变更与恢复

本卡明确将SC hot32×295改cold一RAM/300assembly/热row_valid，增加每ordinary lookup15RE和原接口等待；逐词readback增加INSTALL/UPDATE15RE，不是旧hot4间隔内的内部调整。原M1正文、所有grant/关闭义务不改。没有更新SC/DRB来抹旧事实；新储存/流控/时间选择待联合指定批准。

恢复时先核A与本卡actualhash、原SC/LG/DRB/目录/新H1版本和真正批准，再核真实oldheld/partial/native/admin与family映射；源或scope变更先修设计。不能因为一RAM空间能容495词就授H1，不能因为cold bit293或hot valid0就解释为pin已返。

## K. 本轮实际记录

仅按入口读规则、规范/模板与A范围，静态整数和逐沿/生命周期走查；写本Markdown，无功能性分析程序。6780/6785/480/495/2719等由现有PowerShell静态表达式核算，未保存可执行脚本。最终全文实际读回与source前后hash检查另交Root；本轮没有代码、模型、TB、sim/map/PT/PNR/STA/bit、安装/许可/网络/DB或正式状态变化，R1原实测不成为本cache功能证据。

## L. 中文阅读与交付

先B正常完整请求与旧held场景→C唯一engine/assembly→D1逐字段/row/word地址→D2热资格与四mask→D3交接→E3 hit真实e0…e23→E4写/readback e0…e38→E5 fence/RETURN/admin与错误→F空间/服务→G/H→I缺口。实用观察草图是“RE word14后下一沿先capture，再下一沿验证，后续才形成reply”，不是“读到最后词同时授许可”。修改存放查D1/E1/E4/F2/T01/04/14；修改权限查D2/D3/E2/E5/T06–11；修改服务查E3/E4/F1/DRB/T12，不能只改常量。

本轮交付纯设计候选，未证明资源fit、算法速度或正常连续IO；用户理解验收待实际阅读/反馈，未作答不声称理解。完整软件目标与bit后人工闸门沿原整体流程。
