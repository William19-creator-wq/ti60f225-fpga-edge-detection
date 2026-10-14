# TRACK4-ALGORITHM-CLOSURE-HANDOFF-001：CLASS初态与EDGE发布的有限交接设计 v0.1

2026-10-05；LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)；只创建本卡，不修改R4C、R1、R2或正式治理。本文提出R4C-B02的具体局部合同，待根独立审读/联合采纳；保存不等B02已正式关闭。

## 通用计划字段

- Goal / Target state：保持完整1080p精确Canny，以实际冷记录、来源租约和握手承载INITIAL353、EDGE_PUBLISH1013/ACK1150，区分初态、S封存、RETURN与O不可变发布。
- Current state / Gap：R4C v0.3已规定新body但运输/存放/寿命未闭；本卡给单context/单sequencer/一只CH0 RAM与有限协议。物理资格、共享native服务与全资源属于原B01/B05，不借本卡宣称完成。
- Assumptions：单core、单J/单scratch；J/S/O是可信硬件owner，来源可暂停；只能板内现有资源。显示1080p60保持，不新增算法fps门，不免费复制DDR桥。
- Open questions / Dependencies：A3具体联合项；A2读取版与原LC/CLJ/CLOSE/RETURN合同。M1余39词、ROW镜像、SC hotcache均不自动采用。
- Milestones / Detailed steps：整体来源→接口/冷布局→旧沿与故障→资源/验证/追踪→独立审读和共同基线；无业务实现。
- State transitions / Artifacts and hashes：仅本页LOCAL_DESIGN；来源见A2，最终本卡全文/链接/位宽核查及SHA另报，不自嵌SHA。
- Validation / Failure handling：G有限场景及独立fire/native台账；旧held履约，known失败独立关闭，UNKNOWN/Q保原记录和真实效果，不伪absence。
- Human approval gates：当前未获批。本轮不提出新审批问题；根联合成熟后按唯一规范处理具体版本/范围/基线。
- Rollback / Completion criteria：本轮唯一新文档可审阅；只读源不回写。局部合同可复核不等完整A4/生产链实现或资源通过。

## A. 入口、来源与未决项

已本轮重读控制面AGENTS→config规则/运行提示词/路径→state/ledger→DB README及Manifest；DB仍NOT_CONFIGURED，未访问数据库。唯一根v0.2前任务已实际全文919行，本文沿用并核当前SHA；模板本轮读回154行。下面严格限定本轮源阅读，历史全文事实不冒称新全文。

| 来源 | 实际读取范围/总行数、bytes | SHA256 / 采用界限 |
|---|---|---|
| [唯一v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 前任务全文1–919；本轮hash / 919、61102 | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`；设计/语言/审批 |
| [模板](PLAN_TEMPLATE.md) | 全文1–154 / 154、10341 | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` |
| [R4C v0.3](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 1–3、95–118、204–218、344–354、393–413 / 500、100929 | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；IF13/14、新旧body/RETURN、单S；Root单行消除T0后的当前版 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | 69–158 / 231、34598 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；完整descriptor/pin/holder/初始化/发布与返还 |
| [SCAP](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | 92–216 / 298、43441 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；只用grant台账/child/returnedmetadata边界，未采用普通hot lookup |
| [LG](design-TRACK4-ALGORITHM-LOAD-GRAD-001.md) | 97–174、279–313 / 393、67457 | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；fullLG/原BUILD_BIND/唯一CS、三scope、M1布局 |
| [METADATA_TRANSPORT](design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001.md) | 85–156、158–214 / 257、34341 | `6764FD3115B10BF63FECC289B590CFAE29A106FA7BC0640D4A0DB39A12CF339B`；来源租约/先存后引用/运输quiet原则，ROW新wire/两域镜像不继承 |

| 联合项 | 本卡选择与仍需处理的确切问题 |
|---|---|
| CH-B01 / R4C-B01 | S_FINAL938的字段生成点明确为实际S ledger，O的RETURN/descriptor事实来自实际owner；后端可见性/no-future-effects的真实实现、共同reset隔离与native最长服务仍须原后端设计，不能由该938自报成真。 |
| CH-B02 / R4C-B02 | 本文关闭运输/存放/重放/寿命的候选空白；须根把新S_FINAL、CH协议及metadata leases与原S/O/J接口联合采用并独立核一致，旧卡不会自动变成这些端口。原LG的ALLOC/REGISTER完整运输另项不由本页代替。 |
| CH-B03 / R4C-B05 | 本文具名RAM/热体/有限局部测试；全机实例去重、native公平服务、确切共享文件/工具基线和全R4真实1080p组合仍待根冻结。未来仿真/综合/STA属于获批后执行，不倒置为未批先实现。 |

## B. 整体行为和可检查要求

| REQ | 合同及边界 |
|---|---|
| CH-01 | INITIAL353实际写入/全读回并核fullLG/真实S初态后才可确认；CLASS只INITIALIZED/mutable，CLO接手不清已有CLASS。 |
| CH-02 | 原LG、BUILD_BIND、CS、LCterm、CLJ/CLterm以及S封存历史完整保到最后作用；ref/token/handle非零不授权，J不增加第二CS消费者。 |
| CH-03 | S access quiet→精确scope RETURN→ACK502→原term→O publication；metadata关闭不等wholeLG/CLO先FREE，也不以cache valid判pin已返。 |
| CH-04 | 同一完整发布请求重放返回同version/token；BLOCKED不清信用，错echo不清expected，冲突或未知保记录/Q。 |
| CH-05 | 单真实CH0/单sequencer有限缓冲，全部词/高padding/下一沿capture/held保持收费；不能最后WE沿同时宣称stored/immutable。 |
| CH-06 | cancel先旧fire，已真实O提交保effect；新bundle资格由父禁止。合法共同隔离才重建，局部reset/换epoch不清旧债。 |

正常路径：父真绑定→保护全来源→CH存LG/BUILD→父唯一真CS及LCterm/INITIAL/S-load快照→独占CLO→S-clo访问quiet/RETURN→父真CLterm→完整O发布与ACK→各源/回执/查询quiet→metadata退休。错误例：第二物理postimage未知，S没有quiet/no-future证明，不能以相等计数出版EDGE；保Q并独立报告真实未结。图像数学、全N队列与全N输出完全沿R4C，本页只改变内部交接。

## C. 职责与连接

- CH-J（可信父适配）：从原真BUILD_BIND/ACK、唯一CS fire、LCterm/CLterm fire冻结来源，序列化J类记录并锁PUB expected；不造CS/终态，不运行第二BFS。原BUILD_BIND1012在其实际请求源槽保租约到CH存好，不用最新配置重建历史。
- CH-S（S封存适配）：从同一真实STORE writer生成INITIAL353和S_FINAL938，序列化后等实际存储收据；它不设置O immutable、不替O减pin count。
- CH-O（目录内单sequencer）：CH0 cold、CH generation、真实源校验/metadata leases、重放、原RETURN回链和O descriptor发布；与原目录共享native仲裁，不另造raw引擎。
- 连接IF-CH01 OPEN→IF-CH02 BEGIN/WORD/receipt→IF-CH03 INITIAL确认→原scope RETURN/ACK502→IF-CH04 PUB1013/1150→IF-CH05独立metadata CLOSE；IF-CH06独立STOP。各logical body保持原位宽，内部路由/分词是真新接口。

单context始终属于一个完整J，不开放第二正常J绕过RETURNED_METADATA/Q。SOURCE/GC原data/close/term仍独立；CH不等待它们的data P来接early proof/close，但全父正常进入CLO仍沿R4C保守汇合。READ/WRITE pixel权限只由原pin/STORE授权，本元数据租约不新增access pin。

## D. 精确接口、冷存和组合检查

全部unsigned/高到低字段，除native低20bit先行。所有同域口有valid/ready且fire=旧valid&&旧ready&&!rst；旧full本沿pop不借新空位，无透传。J/S各源槽、O目的私有槽、O回复源与J/S回复私有槽分别存在。来源body在相应receipt/最终ACK语义核对之前不可覆写。

**IF-CH01**：OPEN384=`LG_holder_link160/JID96/source_id64/admission_ref64`；ACK457=`echo384/ch_generation64/status2/reason6/opened1`。O先核实际已登记M1 LG/原BUILD_BIND及真实SOURCE_ORIGIN/lease/ALLOC关联，才保metadata lease并分配非零独立CHgen；不从JID切片或stagegen充CHgen。max只用一次/后续EXHAUSTED，不复用失败预留。规范拒绝未建立本CH资格不证明此前build/pin不存在；部分未知Q。

**IF-CH02**：HANDLE128=`epoch32/ch_generation64/kind4/zero28`；kind0仅context控制，1LG/2BUILD/3CS/4LCterm/5INITIAL/6CLJ/7CLterm/8S-load/9S-clo/10PUB_ACK，11…15非法。BEGIN146=`handle128/body_bits11/word_count7`；WORD28=`data20/word_index7/last1`；WRITE_RECEIPT155=`echo146/status2/reason6/stored1`。各kind尺寸/词数固定下表，连续0…n−1、last唯一末项、高padding0；WORD不能穿透BEGIN沿。O接纳后在CH0的该record建立FILLING私有前缀，不另声称fullbody已收；全写/全读回/来源核完才bodyvalid。J/S按实际port白名单选kind，不能任意caller声明trusted。

1LG/6CLJ由O从已锁M1完整体复制，CH-O source lease保全body；2BUILD/3CS/4LCterm/7CLterm只可信J，5INITIAL/8S-load/9S-clo只可信S；10只O写。J/S两个encoder共享O唯一受理槽，BEGIN逐事务round-robin、active WORD传输不被别kind插入；关闭控制有独立位置。每receipt必全echo/state合法才能释放对应来源租约，bad receipt保旧expected/原身份。

**IF-CH03**：353原body不变，INITIAL_ACK490=`echo353/INITIAL_handle128/status2/reason6/stored1`是本卡新确认口。source353是原S初态冻结槽；encoder仅按稳定body取词，O fullread检查JID/class_ref/version/token/P/S/Weak与true LOAD ledger。WRITE_RECEIPT正确成为旧事实后encoder才形成490；S核490正确实际消费后才能履行CLASS_COMMIT成功RSP449。这不是在353 capture沿已经stored，也不将S token换成O publication token。

这里的stored只检查当前INITIAL body与已锁fullLG/实际S初态生成事实，不能等待尚未形成的S-load938/RETURN/LCterm；其后的exclusive CLO资格才联合核CS/LCterm/938。其它record的WRITE receipt同样只认证本记录已完整存好，不等未来依赖record或publication结果，否则单engine会阻塞依赖消息接纳。

**S_FINAL938（本卡新来源证明）**：`stage_holder_link160/original_CLOSE294/actual_request64/actual_raw_response64/settled_request64/overflow3/access_quiet_mask9/class_initial_token64/edge_durable_token64/valid_pixels22/written_pairs21/strong21/weak21/phase_mask4/queue_tail21/queue_pops21/claims21`。quiet9依次request/read/write/response/native/journal/permit/borrow/no_future_effects；不含pin已RETURN，否则会与RETURN成环。它来自真实S原cutoff/火/phase/effects，不是trusted父填写常量，O再核自己的pin/descriptor/RETURN事实。

load kind8正常资格：stage0/LOAD child、原LC/H、quiet9全1、三overflow0；actual_request=request_cutoff、settled_request=actual_request，last_seq_valid/last_seq与本H最后实际typed RQ火的记录一致（零请求规范0），actual_raw_response等本H真实RSP449火数。正常成功另核raw_response=request；数量cutoff不能与最后seq值混等。P/N、S/Weak及class token一致；edge token/queue三个计数0，phase_mask=0001。clo kind9正常资格：stage1/CLO、原CLJ/H、原close及三个真实台账各自匹配、N/P及初态统计，edge token真非零；GENERAL phase_mask1111且pops=tail=claims≤N，快路径1001/queue三计数0。失败snapshot保实际前缀，settled依原R4 D3的回复已火或合法未published取消处分，不把raw/成功数复制成settled，也不授正常CLO/PUB资格。phase位低→高class/seed/closure/edge，每位只真phase完成建立；不能据caller CLterm flags填。938无pin grant字段，授权必须经O原installed/return ledger与fullpin全文，不把该证书当裸pin权。

938三个台账只含原typed324/449的真实事件，含op5、不含BIND/INIT，original_CLOSE294保持原tx last。实际物理ledger另沿[BK后端候选](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)的FPI841/289/501计入INIT和持续local_seq，不能用FPI response_created充typed raw_response。真实FPI quiet/各END/native/journal/held typed RSP旧空先于938冻结和本记录收据；该收据后才真实RETURN，随后才原502/term，不等待502.pins_released取得938。整个CH IF05关闭只在最终两actor退休，不是LOAD→CLO安装的前置。

**IF-CH04**：可信J用已真消费的原CLterm1013形成PUB1013，其kind7冷记录同时是PUB完整expected，源仍保全原1013直到1150语义结束；不得复制一个“更正确”终态。ACK1150 body严格沿R4C=`echo1013/edge_version64/publication_token64/status2/reason6/immutable1`，伴随独立context HANDLE128(kind0)路由，原body不暗加字段。O源held1150和J目的private1150独立；J ready只看旧接收容量，不用echo组合挡旧reply。

物理激活独立SUBMIT129=`CLterm_handle128/propose1`，propose必须1；J源与O目的各1。先kind7真正stored，再J按原COMPLETE/无stop条件提出SUBMIT，O只在旧pub信用空时fire并锁kind7/full1013。存一个失败/已取消的原terminal不自动PUBLISH；缺SUBMIT不形成1150义务。SUBMIT是原PUB1013的冷运输适配，不能以未存好的handle代body；BLOCKED期间ready0且oldheld SUBMIT已是接纳义务，不能撤回。

status0 PUBLISHED/reason0/immutable1/两非零64；1 REFUSED/immutable0/两0但不证明旧对象不存在；2 BLOCKED/immutable0/两0只progress；3 Q/immutable0，保已真实预留/提交的已知版本或token，不以零猜absence。reason0…10沿R4C D5，11…63非法；禁止硬cast旧R4 reason5/SC reason6。初态确认、OPEN、WRITE receipt均沿同内部编码0OK/1REFUSED/2BLOCKED/3Q；receipt2不置stored、不释放credit；控制拒绝与pub拒绝的物理absence含义各自按真实facts。

**IF-CH05**：J/S各独立CLOSE276=`context_handle128/actor2/begin_cutoff64/word_cutoff64/last_kind4/last_word7/first_reason6/source_fenced1`；ACK418=`echo276/actual_begin64/actual_word64/transport_closed1/native_closed1/context_refs_closed1/reply_closed1/no_unknown1/drained1/status2/reason6`。actor0J/1S，2/3非法；64bit计数先65bit增量/overflow另存，无request时last_kind/word规范0。cutoff只在自身全部oldheld BEGIN/WORD已fire且停止新publication后锁定；不等P/EOF/receipt good或对方CLOSE。O一个独立目的close槽/ACK源槽，两个actor源/回复私有各一，仲裁后完整echo回原actor。

metadata CLOSE不释放DDR pin/base，只关闭自己的metadata新源/查询；已收word/native pending须真结清，已formed receipt/1150履约，partial未发布record可在known closed后失效。status0/reason0/drained1/六位全1且原cutoff相符才正常收据；known失败status1/真实reason/drained1可结本metadata信用但不正常发布；Q status3/drained0保可能旧债。错echo/计数/位/overflow不清expected。不能等待自己的CLOSE_ACK先消失来形成ACK。

**IF-CH06**：可信J→O STOP135=`context_handle128/reason6/unknown1`；ACK144=`echo135/status2/reason6/stopped1`，双方各一个独立held/private。J只把原真实匹配取消/故障事件映射到旧CHgen，不能借当前gen套同沿新context。status0 APPLIED或1 ALREADY均reason0/stopped1，2 NO_MATCH/reason1/stopped0，3 Q/reason9/stopped1；这是专用控制编码，不cast其它族。晚STOP先兑现旧回执、不撤旧held，首次原因sticky；metadata退休也须其transport/private真空。IF05的source_fenced包含禁止新的STOP/publication/query，但此前held继续履约。

| kind / 唯一CH0冷体 | bit / native20词 | 地址闭区间；末词低有效/高零 |
|---|---:|---|
| 1 fullLG | 1119 / 56 | 0…55；19/1 |
| 2 原BUILD_BIND（KEY/source/J/admission/PCTX） | 1012 / 51 | 56…106；12/8 |
| 3 原真CS | 592 / 30 | 107…136；12/8 |
| 4 原LCterm | 776 / 39 | 137…175；16/4 |
| 5 INITIAL | 353 / 18 | 176…193；13/7 |
| 6 fullCLJ | 438 / 22 | 194…215；18/2 |
| 7 原真CLterm/PUB expected | 1013 / 51 | 216…266；13/7 |
| 8 S-load / 9 S-clo | 各938 / 各47 | 267…313 / 314…360；各18/2 |
| 10 最终ACK1150重放 | 1150 / 58 | 361…418；10/10 |

CH0唯一EFX_RAM10 native20×512/1R1W/OUTPUT_REG0，WCLK=RCLK=core，全词WE11，实际RE/WE对应ADDREN，禁止同址R/W；保守每沿只有一种nativeissue。总body8329bit、419词8380nativebit、padding51；419…511未授权别owner。record_base+word先10bit核0…418再窄9bit；body从低20bit开始，末pad真实写0/读回核。没有M1地址或DDR地址变更；这里是一只新增板内RAM，不能扣旧journal/RX或挤M1 39词。

M1原LG282…337/CLO338…359及其stage generation有明确CH metadata lease：其body/回链不得复用至CH真实退休。CH0另外保存全LG/BUILD/CLJ历史，跨class grant转换不改它们；其它SRC/GC scope/admin继续由旧owner保。BUILD的KEY/PCTX/source/原J与true受保护BIND事实一致，CS/Lterm/Cterm各来自原真fire并保valid历史；O从自己的allocation/descriptor/source/lease而非caller flags核来源。原holder动态phase不应与immutable冷body混同。

另保LOAD CLASS与CLO CLASS/QUEUE/EDGE四个原pin的metadata_keep位：真实RETURN一次减descriptor访问计数/撤active，512bit旧tuple仍留原slot，不因RETURN ACK已消费而canonical FREE/覆写，至CH所有admin/检查/ACK/refs真闭合才METADATA_RETIRE。queue缺席该keep位0但必须原fastpath真absence；SOURCE/GC pin另由其owner保。发布全查对已returned tuple核active0/原grant/holder/真实returned ledger，绝不当ordinary active1许可。四份是旧returnedmetadata继续占原pin容量，不能免费新开四slot或说全机pin上界已证。

CH0只有CH-O的native端口，J/S不直接RE，也没有未定义外部QUERY口；源租约/semantic引用由原owner与header登记。S初态353在确认后仍作为本class的immutable影子保到本CLO938生成/作用结束；用原class_ref/version/initialtoken对应CLJ，不从新的CLO H猜原Strong/Weak。source valid可撤，所存值不能被新LOAD或局部session reset覆盖；正式CH关闭/隔离之后才允许复用这353槽，已在F计一次。

## E. 单sequencer、沿表与中文操作草图

context state4：0FREE/1FILLING/2CLASS_INITIAL/3CLO_ACTIVE/4WAIT_FACT/5PUBLISHED/6CLOSING/7Q，8…15非法；record另valid/partial各10mask，returnedmetadata继续占这个context。操作CAPTURE→HEADER_CHECK→WORD_HOLD→WE→SETTLE→RE/CAPTURE→CHECK→COMMIT→RECEIPT；pub另FULL_AUTH/WAIT_FACT/RESERVE/ACK_PREPARE/DESC_WRITE/VERIFY/PUBLISH。Q不改已知token/旧descriptor效果。

| 本地无stall相对沿（n词的新record） | 单实际动作 / 保持 |
|---|---|
| e0 BEGIN fire；e1 header检查 | 仅锁146/来源lease；核kind/gen/期望尺寸与旧record空，不同沿WORD或写 |
| e2,e4,…,e2n WORD fire；e3,e5,…,e2n+1 WE | 一个目的WORD28旧空接纳，下一沿写对应20bit；WE释放沿不借槽接下词，source保持到真fire |
| e2n+2；e2n+3…e3n+2 RE | 旧最后写pending结清，再逐词读回；唯一1160bit assembly，不平行另query |
| e2n+4…e3n+3 capture；e3n+4 CHECK | RE下一沿收料，末capture后独立核完整body/padding/来源租约，不提前用末词 |
| e3n+5 COMMIT；e3n+6 formed；最早e3n+7 receipt fire | 全旧facts好才bodyvalid/初态/注册事实；后续形成155，消费后后续最早e3n+8下一BEGIN |

INITIAL n18 receipt最早61interval、CLterm n51最早160；这些不含原O全查/排队/外部stall，不是成功最坏服务界。已有record replay不写：e0/e1 header，单词e2接纳→e3 RE→e4 capture→e5比较→e6下一词；n词最后compare e4n+1、e4n+2检查、e4n+3形成receipt、最早e4n+4fire。一个sequencer不声称1/cycle，invalid或full不让body被覆盖。

正常接力逐步：①OPEN先全查旧LG/BUILD来源并保护原冷体，序列消费一次；②依固定table写/全核LG/BUILD/CS，INITIAL353入CH0真stored后才INITIAL_ACK及S原op5 RSP；③L提CLOSE，S以旧真实ledger冻结S-load，CH存938，O核fullpin/原tuple/quiet后RETURN，正确RETURN ACK成为旧事实再原ACK502/Lterm；④CH全核Lterm与353/CS/938后允许原exclusive CLO，保CLASS原初态，不等整个LG FREE；⑤CLO完整BFS/导出后S-clo938存好、自己三个实际pin按原逐份RETURN，原ACK502/Cterm消费后才PUB。

⑥O核冷CLJ/CLterm/353/两938及完整J/BUILD、原phase/overflow/队列/全N/P；同时核真实installed/returned masks、全部fullpin、descriptor无writer/dirty、initialized/valid_count=N/physical_settled，所有旧permit/native/effects真空。RETURNED_METADATA不是cold miss，UNKNOWN不是不存在。S的quiet snapshot只封当时旧scope；任何新业务/版本变化使匹配失败，不能沿用旧quiet给另一session。

⑦先真实预留新的O version/publication64（65bit预检，不复用失败序号）；准备ACK1150、在CH0 kind10写58词但valid仍0；受保护同object metadata barrier下完整写EDGE descriptor32词并全读回，保创建J/origin/ref/真实物理facts，descriptor.commit改存O publication token，S durable token留938/CLterm不丢。再读回kind10全核；整个记录及真实无writer资格是旧真后一个PUBLISH沿发布COMMITTED/immutable/version/token与kind10 valid，后续才held1150/新的只读grant。先native写候选字段不授普通读取，不声称多RAM一沿写完。

⑧父独立private接ACK，逐字段核原PUB1013、context、状态/两token并记实际O效果；其未形成完整bundle/借用仍另范围。两actor停止新metadata publication、兑现oldheld后各送IF05；O核真cutoff/native/回复/引用quiet，回ACK，不等wholeholder先RETIRE。context_refs_closed核本actor的真实无未来查询/源借用；不等待O为本CH持有的M1保护lease先解除。两个正确收据消费、所有actor/native/control/private/父借用已是旧quiet且无本沿新事件后，下一沿才撤CH0可见/退O的M1 leases/允许新CHgen。cold字值不需全清。

| 情形/关键沿 | 必须兑现的结果 |
|---|---|
| 末词WE与cancel同沿 | WE真实前缀照记；不得形成新正常stored/publication；后续known close可清partial资格，旧held receipt仍保持 |
| 未收到last/输入中途停顿 | 不伪record complete；停止源并兑现oldheld后独立IF05按真cutoff结已收native前缀，不等缺失词补齐 |
| PUB待writer/effects | 最多一次status2 BLOCKED progress；cold expected保同完整1013，不重复PUB/不释放credit。WAIT_FACT不占CH0/native引擎或阻新S记录/原RETURN/IF05；实际事件后重新全查才最终0/1/3，已held BLOCKED先fire后沿才final |
| 提交前cancel/已知拒绝 | 不PUBLISH；REFUSED reason8或实际拒绝，保其它已建对象/旧effects，metadata known close后恢复需原R4/O真实退休 |
| PUBLISH与cancel同沿/其后 | 旧真实提交保immutable/token与最终成功回执；父把本job bundle资格取消。不能改已formed ACK、回滚descriptor或再分配一份EDGE |
| descriptor/ACK record校验失败、未知物理资格 | 保真实已写/预留历史、禁止授新读/Q；未发布不伪ref不存在，Q收据drained0保context，恢复仅合法共同隔离 |
| bad reply/错误CLOSE echo | 计raw/锁first fault，不清expected；独立IF05可按真closed收账，未证完整则Q，无超时伪free |

重放窗口限context全生命周期：同handle/kind完整重复WORD逐词等于cold才回原stored，不再WE/授grant；同PUB1013真完全相同且kind10已valid只读回同1150。samegen冲突体Q保原记录；另gen/epoch拒绝不改变旧context。每输入族只允许一个未终结proposal；BLOCKED等待时不接第二PUB，最终receipt消费后允许同一旧记录的顺序重放。退休后旧handle只返回无新资格的拒绝，不重建对象/复活pin；global身份不重用，长久未来重复源不承诺保留无限cache。

kind10亦保存已知final REFUSED完整1150，write/read/check后才valid供顺序重放；BLOCKED不占该final记录。Q只有CH0本身仍可信/原记录可完整认证时才存final3；否则保持现有1150诊断源槽/原reserved序号及Q header，不接新PUB/不重放一个猜的cold体，也不释放context。错误路径不是一律能返回正常metadata-drained，有限失败通知不能伪known关闭。

## F. 语言、存储、唯一实例和服务账

| RTL A–L | 本局部合同 |
|---|---|
| A数值 / J身份 | body全宽上述表；64序列/计数先65、address先10，unsigned；stagegen/CHgen/ref/原op0/O token分别核，kind/word/pad保留严格0，无窄化丢身份。 |
| B时钟 / C接受 / D有效 | 单core posedge旧fire，输出注册后稳定；WORD气泡不写/计数不增；valid或recordvalid0不等body0或对象已消失。 |
| E反压 / F延迟 | 源immutable lease及全部private/held保全文；E表真实capture/形成次序。nRE/nWE与native服务/semantic fire分账，永久notready只有限失败监测。 |
| G复位 / H配置 | rst同步高fire0，soft epoch须原CONTROL全旧线/DDR/owner隔离或保Q；暖复位不清分配序列。新配置不改旧LG/J/PCTX或held1013。 |
| I存储 / K CDC | CH0同域1R1W、无碰撞/单issue；不借ROW双clock镜像。不跨异步裸接CH body；未来外部域需真实完整握手，当前N/A跨域CH实现。 |
| L实现 | Ti60F225/I3/SV2009、现装Efinity/Questa与原RAM模型只读目标；一新CH0 RAM+实际encoder/控制/assembly，不为每record复制RAM。频率/STA/full fit仍未执行。 |

| 具名selected容器 | bits / 真实实例收费与扣数条件 |
|---|---|
| J/S BEGIN源各1+O目的1；WORD同；receipt O源1+J/S目的各1 | 3×(146+28+155)=987；两sender轮流，但各旧source/private独立 |
| OPEN384/ACK457两端各1 | 2×841=1682 |
| INITIAL_ACK490 / PUB_ACK1150两端各1 | 980+2300=3280；O reply与J/Sprivate不得合一 |
| PUB ACK的context路由sideband / STOP135与ACK144 | 2×128+2×279=814；同样与valid保持，STOP双端private独立 |
| PUB SUBMIT129两端 | 258；原完整PUB body在kind7及父原1013源槽保expected，绝不只核handle数值 |
| J/S CLOSE源各1+O目的1；ACK O源1+J/S目的各1 | 3×(276+418)=2082；close接纳不借data槽 |
| 唯一CH读回assembly | 1160；最高1150有效/其余零，不拿cold body当热assembly |
| 真实宽来源槽 | BUILD1012/CS592/LCterm776/CLterm1013/INITIAL353/一个S938共4684；前四若已在父账只扣一次，S938只真stored+receipt/oldnative空后才允许用于下一scope |
| header/分配/计数等selected | header450（epoch32/gen64/state4/两holderlink320/recordvalid10/partial10/sourcelease6/nativepending/pubpending/blocked/cancel各1）；CHnext/exhaust65；两actor actual_begin/word四64+overflow4=260；前述29transportvalid+6widevalid+assemblyvalid=36；native kind4/cursor7/address9/pending1/turn1/op3/check1=26；M1 leases2、pin_metadata_keep4、pubbarrier/replaywindow2 |
| selected合计 | 15792bit（9103运输+1160assembly+4684宽来源+845控制）；部分是既有原槽的具名并集，不等新增FF或完整FF/XLR |

另外原O唯一context2257/descriptor640/pin512 assembly、原stage/link/grant/revision/masks、STORE实际phase/计数/permits/atomic、J原KEY/PCTX/CS forks、原CLOSE/RETURN/latecancel、全close证据及mux/地址/校验/LUT/ADD/SRL均保原账，不隐形计0或扣掉。CH冷8329bit另收费一RAM；在175假设上局部变176，但ROW/coldcache等未联合提议不可混加当full fit。cold正文不算FF，可信源借用只有上述真实寿命成立才避免另宽副本。

每新record服务至少nWE+nRE+capture/check/commit/receipt本地间隔；M1源copy另56/22RE与原descriptor32/pin32/fullholder查验，BUILD来源核另真实µ。pub另CH ACK58WE/58RE、descriptor32WE/32RE及原RETURN/allocator/全查。总`C_CH=Σ记录本地服务+µ_source/fullauth+µ_return+µ_pub+µ_close+共享native等待+真实consumer等待`，同动作只计一次；E无stall最早表不是此最坏上界。唯一目录arbiter按每最多32nativeissue quantum交替CH与原业务、active检查上下文保留；CH0端口不等待DDR占锁。真实eligible requester数量/每µ与R5行deadline仍须联合冻结，不把native32quantum直接说全机QoS已证。

跨语言三契约：①共同metadata全body/词序/pad逐bit，pixel/Canny不改；②另证真fire、源租约、native/capture/RETURN/immutable/旧cancel及reset，host循环不证明时间；③独立oracle从原owner实际事件关联完整J/KEY/PCTX/ref/gen/term，比较完整stored及实际known前缀/不同closing结果。C++实施N/A；未写模型、脚本或TB。

## G. 有限实施/验证计划（全部NOT_RUN）

获联合指定批准后拟在R4 work新增`closure_metadata_handoff.sv`、`closure_record_ram.sv`、`closure_metadata_encoder.sv`与J/S/O适配；共享原RAM模型只读，独立协议参考/TB/runner须同基线冻结。现在仅命名计划，无业务目录或可执行文件。局部suite按T01…T10固定case类别，不以原R1工具/bit通过代CH验证。

| TEST | 有限场景 / 独立预期 |
|---|---|
| CH-T01 | 6×5 GENERAL、NO_STRONG、NO_WEAK与生产1920×1080 metadata N/P，retain0/1：完整来源/word/pad/353/938/1013/1150逐bit，三scope不混；metadata fixture不宣称真实BFS通过。 |
| CH-T02 | 全10record逐一末词高pad/缺词/多词/错index/early或missinglast/kind/epoch/gen，接受raw与stored/prefix分计，不错写其它cold范围。 |
| CH-T03 | n18/n51/n58连续与单WORD/RE/receipt各停8，核E最早表、oldfull释放不透传、源完整保持/真实WE/RE/capture，不只PASS字符串。 |
| CH-T04 | 原CLASS grant/RETURN/ACK502/LCterm与CLO新grant交接，SRC/GC仍有metadata，CH body不复用、不CLO重清CLASS、不等待wholeLG先FREE。 |
| CH-T05 | BLOCKED(writer/effect)分别停8后真实事件恢复；progress不清credit、无重复alloc、final独立形成，oldheld BLOCKED不能被成功覆盖。 |
| CH-T06 | 所有record完整重放及PUB重放各2次、同handle冲突/退休后迟到旧handle；原tokens/descriptor一次提交且完整echo，miss不证明原pin返回。 |
| CH-T07 | INITIAL末WE/receipt、RETURN、PUB reserve/descriptor32词首末/verify/PUBLISH/ACK/CLOSE形成前后及同沿cancel/reset；旧真实effect保留，未知Q不free。 |
| CH-T08 | 真cutoff的partial流close、bad receipt/1150/closeecho/count、native未知/永久notready；已知失败完整排债后新job恢复，Q仅合法隔离可重建。 |
| CH-T09 | CHgen/原64计数0与max/exhaust、三identity namespace错配、BUILD/PCTX/source/actualCS或Sledger冲突；没有self-reported完整证明。 |
| CH-T10 | 获批后真实完整1080p LOAD/S→CH→CLO/S→O组合，独立全N EDGE与全部scope台账同时成立；真实R4/T20证据另报，局部metadata fixture不能替代。 |

局部metadata仿真计划core25MHz（验证用钟，不声明生产STA），seeds0x431/0x1060；每source/consumer有限连续停顿≤8，case周期上限200000、wall120s，strict EOF/hex/unused/X/Z/finish、实际compared body/word/fire/native计数。这些固定的是有限失败监测，原µ/后台effects不兑现时失败而不RTL timer伪close。T10真实整图cycle/wall由原R4数据/服务上界另冻，不能套200000删掉正常全图。波形查末WE/RE下一capture/RETURN前后/PUBLISH同沿cancel；人工理解验收待用户真实反馈。

## H. 双向追踪

| REQ/原来源 | MOD/IF/局部 | 计划符号 / TEST；实际证据 |
|---|---|---|
| CH-01 / R4C-REQ01/11 | S/O、02/03、冷kind5/E初态 | initial_source_lease / initial_stored；T01…04/07；NOT_RUN |
| CH-02 / LG139/DIR108 | J/O、01/02、kind1/2/3/4/6/7/M1 leases | parent_origin_snapshot / metadata_lease；T01/02/04/09；NOT_RUN |
| CH-03 / SC132…138/R4C E9 | S/O/J、938/原RETURN/05 | scope_final_snapshot / returned_metadata；T04/07/08/10；NOT_RUN |
| CH-04 / R4C D5 | J/O、04/02、WAIT_FACT/重放窗口 | publication_expected / replay_record；T05/06/08；NOT_RUN |
| CH-05/06 / DIR native/MT租约 | 单O/CH0、全部IF、E/F | record_sequencer / quiet_cutoff；T02/03/07…09；NOT_RUN |

反向：三个实现候选分别承载真实冷序列、RAM边界、来源encoder，J/S/O适配只服务这些REQ；未添加新识别/摄像/显示功能。未来实际源码符号/hash/日志与body/native/closed台账登记，当前只有设计。

## I. 门槛与审阅

①整体B；②唯一owner与C连接；③D完整wire/白名单/布局/旧协议相容；④E状态/旧沿/正常错误/重放；⑤F语言/实例/条件服务；⑥G正常/错误/集成互补；⑦G/H有限计划及双向追踪；⑧联合CH-B01…03未结束；⑨本卡保存后实际全文/位宽/links/hash读回并根独立核；⑩v0.1纯设计、依赖读取版本和未来基线有界。**NOT_READY**，没有实施批准/Manifest登记，不新增审批问题或暂停R1已完成范围。

## J–L. 变更、实录与中文阅读顺序

这是R4C v0.3 B02的新联合候选，新增CH transport/S_FINAL938/INITIAL确认、cold收费与生命周期；原R4C IF13/14 body、BFS/全N容量和原LC/CLJ/term/typed/CLOSE保持。descriptor.commit选O publication token属明确新适配，S durable历史保留，不偷偷改旧卡。恢复核实际最新来源/审批/差异、transport/returnedmetadata与true O作用；未知保Q，不能局部清gen试运行。

本轮只入口与限定源读取、整数/位宽/存放/握手设计及本卡写入；无业务RTL、参考模型、功能脚本/TB、EDA、network/硬件/DB/正式状态变化，全部NOT_RUN。R2 v1/48未获批、R1实作证据与源保持只读；根可独立审读本具体增量后决定联合版本，不把未来STA/仿真当未批先做的前置。

阅读B整体→C来源/owner→D wire与cold表→E按WRITE/capture/RETURN/PUBLISH/quiet逐沿→F真实费用→G/H有限证明→I联合剩余项。CLASS stored不等immutable，S token不等O token，pin RETURN不等metadata FREE，BLOCKED不等final，cold miss不等absence；修改接口同时看D/E/F/T02/05/06，修改寿命看M1 leases/IF05/T04/07/08，最终交付仍待实际代码/工具与用户理解反馈。
