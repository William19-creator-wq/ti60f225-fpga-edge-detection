# TRACK4-ALGORITHM-CLOSURE-WIRING-001：唯一 O/S/J 的有限联合接线设计 v0.1

2026-10-05；LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。依[PLAN_TEMPLATE](PLAN_TEMPLATE.md)形成可读回候选，仅新增本卡，BK/CH及所有既有来源不改。本文补实际 owner、完整位置、握手与复用条件；不将接口选择说成已有 RTL。

## A. 通用计划、边界与读取事实

- Goal / Target state：把真实登记→唯一 ACQUIRE→安装→INIT→访问→quiet→CH/RETURN→发布接成一条有限路径，保持完整1080p精确Canny。
- Current state / Gap：R1软件交付已完成；R2 v1/48尚未获批；BK/CH已给宽体和无环关闭顺序，但注册入口、S的CH context、490 producer和O内部copy/native job未落位。
- Assumptions：Ti60F225/I3、仅现有板载资源、一个core/J/scratch/S/O、原共享DDR adapter/journal；core100MHz仍候选，显示1080p60独立于算法速度，不新增算法fps门。
- Open questions / Dependencies：CW-B01真实物理资格；CW-B02全机native服务/完整scalar与实例；CW-B03共同files/cases/工具与批准基线；确切证据见I。原LG ALLOC/其他SRC/GC接口不借本卡伪完成。
- Milestones / Detailed steps：B整体→C owner→D逐连接→E旧沿/错误→F费用/语言→G/H→根独立联合审阅；共同阻塞闭合后再由根形成指定版本审批。
- State transitions / Artifacts and hashes：只本文LOCAL_DESIGN，来源表是读取版本而非新正式baseline；自身hash另报，不自嵌。
- Validation / Failure handling：只读、有限整数/位宽/链接检查；所有实现/仿真/综合/PNR/STA/bit NOT_RUN。旧held履约，未知效果保Q，计时不能制造释放。
- Human approval gates：本卡未批准、不提出新审批问题；R1/预检批准不覆盖本卡。PostgreSQL仍NOT_CONFIGURED，不访问数据库/网络/硬件，不改正式状态或Manifest。
- Rollback / Completion criteria：只新增本卡可审阅，原材料/旧卡/冻结R2/R1保持；局部接线自洽不等完整十一项实现、full fit或物理通过。

本轮重读入口AGENTS→config规则/运行提示词/路径→state/ledger→database README→config真实Manifest（SHA `7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D`）。Manifest目前只含预检/R1批准，未增加本卡记录。规范前轮全文919行、本轮重读251–323/344–435/468–503；模板本轮全文154行。

| 来源/实际范围 | SHA256与采用界限 |
|---|---|
| [唯一v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)，919行/61102B | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`；门槛/组合/RTL/追踪 |
| [模板](PLAN_TEMPLATE.md)，154行/10341B | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)，本轮全文1–210/35416B | `2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060`；839/599/676/FPI/两许可/journal/关闭 |
| [CH](design-TRACK4-ALGORITHM-CLOSURE-HANDOFF-001.md)，本轮全文1–218/34283B | `B4659BA70A766A9E6D7EE16244481E80880157FCC4F0F8407EB7D0F5FA51120D`；冷布局/938/490/发布/寿命 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，67–181/231行/34598B | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；640/512/唯一native/返还 |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，90–216/298行/43441B | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；218/28/291、M1/真实grant台账；不采用hotcache/普通LOOKUP |
| [LG](design-TRACK4-ALGORITHM-LOAD-GRAD-001.md)，97–147/148–181/279–313/393行/67457B | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；1119/1195/原prepare与ACTIVE、历史全体；本轮补读151/155/175的控制status与原因族 |
| [R4C](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)，本轮135–156/187–200/265–272，500行/100929B | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；原BIND277/511与LOAD PREPARED，CLO不套LOAD ACTIVE812 |

## B. 整体行为与可检查要求

| REQ | 当前联合保证与反例 |
|---|---|
| CW01 | 原完整LG/CLJ经真实登记与来源核对后才能绑定；SC291不裸cast1195，不由stagegen推对象已分配。 |
| CW02 | 原BIND触发一次ACQUIRE；安装/INIT/原BIND成功/ACTIVE分开成立。未真完成INIT时277/847不能授ordinary。 |
| CW03 | 唯一O更新descriptor prefix；S无descriptor影子。CLEAR END0须真实效果quiet及元数据写读核后才684。 |
| CW04 | J/S均取得同一实际OPEN457，不从stagegen/UI重建CHgen；490仅S encoder产生，O仅回155。 |
| CW05 | O内部copy与full查验借用真实来源/唯一assembly，末capture后检查；不以32issue量子覆写半份体。 |
| CW06 | 原LOAD→CLO顺序保持，353跨scope不清；typed/FPI/CH台账分开，未知不正常发布，取消保旧fire与已提交效果。 |

正常：完整登记→原S prepare/唯一pin→839/847→实际CLEAR/END prefix核→原BIND成功→原PREPARED与ACTIVE→CLASS→353收据/490→449→938收据→RETURN/502/LCterm→CLO真登记/安装→完整BFS/全EDGE→938/RETURN/term→PUB/1150→CH关闭。错误：CLEAR最后W已火但未来效果未知，保原permit/prefix/身份，不能用END0、847或新CH覆盖它；拒绝正常ACTIVE/PUB，独立关闭只能按真实资格推进。

## C. 唯一职责、来源与连接

- CW-J：可信父/registry encoder，保完整LG1119、原CLJ438、BUILD1012、唯一CS592/两term；从SC真实291形成父内部LG完成记录1195，不增加第二CS消费者。
- CW-S：唯一STORE及其CH encoder；原typed/BIND/ledger、安装839、两许可、INITIAL353影子/938源；encoder串行收155，形成自己的490 source交service private。
- CW-O：唯一目录dispatcher、stage登记/真实ACQUIRE/许可/INIT prefix/RETURN、CH来源lease/copy/publication；共享原2257/640/512 assembly及M1，CH另外一只1160 assembly/CH0。
- CW-A/JNL：原共享physical adapter与journal，不是可信父J；保实际FPI/raw/效果/借用，O只认真实事件/原完整permit，不从全局empty一位猜本spanquiet。

整体连接为原J来源→SC登记→M1→原S BIND/唯一ACQUIRE→839/847→599/674→共享JNL/FPI→676/684→449；O OPEN457双目的→J/S records→155/490→938→原RETURN/502/term→129/PUB/1150→276/418。选择及未决已在本轮呈现给根；这只是候选组合，下面继续局部。

## D. 有限逐连接与精确相容选择

### D1. 只选一个O/M1登记运输

本卡选择SC原BEGIN218/WORD28/REGISTER_ACK291作真实cold登记口，限stage0/schema1/fullLG1119与stage1/schema2/fullCLJ438；stage2/schema3未来RC不由本卡实现。LG原1119/1195保持全体，作为J内部业务来源/完成记录；不再并行开一条J→O直接1119/1195物理口。此为明确联合delta，旧LG/SC卡不自动改写。

BEGIN218低→高=`stage_index2/namespace4/epoch32/H160/schema8/body_bits12`；WORD28=`data20/word_index7/last1`，低20bit词先；ACK291=`echo218/stage_generation64/status2/reason6/registered1`。stage0/namespace2/n56/1119；stage1/namespace3/n22/438。H保原操作身份；holder_link字段为kind4（值3=ALG_STAGE）/index6/独立generation64/epoch32/zero54，共160bit，按实际SC92构造，禁止把两160bit盲接。

| 连接/完整位置 | 谁保持、旧事实与复用门 |
|---|---|
| J LG1119/CLJ438源→J BEGIN218/WORD28源→O各218/28 private | J原体保持到正确登记结果及全部copy借用空；两个源体各一，CLJ438可与原父command source同实体仅在实际寿命成立时扣一次。BEGIN旧空才接，不接同沿第一WORD。 |
| O M1写/核→O291源→J291 private | O按282…337/338…359写全部低词和高padding0，末capture后全核原J/LC/ALLOC/BUILD/来源、quota；后沿登记bodyvalid/BINDING，后续形成291。J保BEGIN218作expected，不由最新H重建。 |
| J291→J内部1195完成记录 | 1195=`echo1119/gen64/status2/reason6/registered1/reservation_mask3`，retain由原J.algorithm；正常mask011/111仅在O真实成功保证三scope reservation后形成。不是第三个O1195回复，也不代表live pin。 |

291必须对应BEGIN真实fire，不在ready0/无fire时凭空回应。本卡明确准入拒绝子路径：只捕获坏header作echo且尚未保留stage/gen/quota、真实no-effect时，可形成规范REFUSED；正常接纳路径在BEGIN fire预留stagegen即消耗。预留已发生后partial写/来源失败保真实header/冷前缀，进入Q或独立known关闭，不能将SC“无ordinary”缩成LG“从未建立holder/reservation”，不得伪造allocated1/class_ref/grad_ref。

**SC→LG控制status适配（SC98，LG151/155）**：SC0/reason0只在全echo/gen/registered及真实来源/reservation资格齐备时生成LG0/reason0/registered1；1只有真实本次未建立holder/reservation的absence资格才LG1，否则保真实部分ledger并LG3；2是非终结progress，保BEGIN/fullLG/expected与旧义务、不完成1195，等待真实后继0/1/3或按真实无法继续的Q事实明确LG3/UNKNOWN15；绝不输出1195.status2，也不重发BEGIN或重复分配；3→LG3/registered0，保真实已知mask而不由零猜absence。LG1/3必须合法非零原因。错echo、非法status/reason、SC0却reason非零/registered0/gen0或保留字段错都不正常结清原expected，保原身份/部分ledger独立CLOSE/Q诊断。

**完整reason6逐项映射（SC98→LG175）**：0NONE→0NONE（仅合格success）；1BUSY→3BIND（真实slot/quota/绑定占用使登记不能就绪）；2IDENTITY→2STALE；3LAYOUT→1FIELD；4RANGE→4CAPACITY；5PERMISSION→18PERMISSION；6BARRIER→21INIT（本登记口限旧stage/prepare权限初始化准入屏障，不能要求新stage先ordinary/INIT才能REGISTER）；7UNREGISTERED→3BIND；8EXHAUSTED→14EXHAUSTED；9PROVIDER→23BACKEND；10UNKNOWN→15UNKNOWN。不得把SC6译成GRAD_LAYOUT6或SC8译成MARKER8。来源publication未commit的不同语义需按实际判据走LG20COMMIT的独立诊断，不能假称本SC6已经携带子原因；不能判别的实际Q保15UNKNOWN。SC11…63/非success reason0非法，按原请求登记PROTOCOL12诊断并保expected，非cast后当合法回复。两个原因族没有新增wire字段。

### D2. 原BIND→安装→INIT→原reply/ACTIVE

S先接原LC270/CLJ438到原max438私有位置，核原context/registered M1来源；错误尚未ACQUIRE时保持原合法拒绝无该S pin的保证。O仅接受这个S prepare的唯一ACQUIRE，串行写/读核512 pin及descriptor/installed，真实提交后形成839 source；S839 private全文核H/stagegen/epoch/role/真实tuple，再后沿S847 source→O847 private。错847保expected/已建pin，不重复ACQUIRE。

成功847只证明安装，随后S在BINDING进行必要INIT；LOAD清CLASS一次，CLO继承CLASS proof，只清新QUEUE/EDGE，fastpath真queue absence不清不存在对象。O原ACQUIRE結果/839 source与S private438保持到该次prepare结束；permit599从已安装tuple/实际cursor形成，不从ordinary输入提前寻址。

CLEAR的fullAUTH599（init1/op6）经O全查→两端674→S真实FPI WRITE/859核→END676 outcome0。O单独END_PREFIX job以原674内echo599为唯一更新来源：ref/version/grant/holder全匹配；span属于当前descriptor连续rounded prefix；count1…4与length16×count足宽一致；同permit所有真实FPI/native/JNL/holding子借用及未来效果已关。S的outcome0必须由真实匹配859/物理资格产生，O也核实际许可/子借用台账，不能把outcome位自报当物理证明。

O在descriptor640实际读回上计算新prefix29，33bit先核`oldbase+oldprefix=span_base`、end在rounded内、不跨guard；锁一致metadata→完整32词实际写→独立settle→32RE/末capture→全文核保其余字段→后沿提交prefix事实→后续684 source。source END676及原674保持到正确684私有核；684有效期间本更新不能重做，重复END按同原结果履约，不再加prefix。gap/重复新span不能凑累计数，已issued未知保Q/不推进。

S正确消费684成为旧事实后才下一AUTH/下一CLEAR；最后INIT完成还要全部prefix/permit/旧native/effects真实closed。O不以最后W、B0或cal_done猜physical_settled。所有必需INIT核完/847真实成功为旧事实，S后沿才形成原成功BIND277/511。LOAD：L消费277后才PREPARED，父消费各READY/PREPARED再原ACTIVE224→O原ACK812，O核各pin/INIT及安装ACK已消费后回应；父消费812成为旧事实才CJ。CLO：C消费原511并核原强弱/P/flags成为旧事实后才SELECT/SEED/EXPORT；不发LOAD的三scope ACTIVE224/812，也不造CLO PREPARED277。未全部成功独立关闭partial pins；ACQUIRE已发生的失败不制造原规范“未建立pin/binding”拒绝，未具备合法回应则保expected/Q，不把847代277/511/812。

普通AUTH/两674、END/684仍按BK全体两端位置，674 source兼完整permit记录直到END运输关闭；S599只在完整匹配receipt成为旧事实后复用。O真实END job消费完本source/borrow才可退许可，END不等typed449消费；S仍保独立449/诊断与JNL metadata到其真实RELEASE。新scope只换当前访问资格，不清353/CH association、持续auth_seq/local_seq或返回metadata。

### D3. OPEN457真源双目的与490唯一producer

O核M1 LG/真实ALLOC/BUILD及SOURCE_ORIGIN/lease后从原OPEN384形成原ACK457，保O一个457 source，分别向J既有457 private及S新增完整457 private交付；两输出共享同稳定body，各自独立valid/ready/fire，不等另一路ready，不复制第二个O457。fanout `pending_J/pending_S` 初值11，各真fire仅清自己的bit；最后fire后续旧pending00且旧引用空才复用O457 source，不在同沿发新ACK。

S的457 private是持久CH context，不是stagegen的cast：OPEN echo384保LG_holder_link160/JID96/source64/admission64及真实CHgen64/status。S接受它不等待原BIND/839/ordinary；先核来自实际可信O、固定457格式/非零gen/echo结构，保存资格；以后按真实LG holder_link的stagegen/epoch、原LC三ID与839来源绑定本S LOAD。source/admission全体由O fullM1/原BUILD与J原OPEN expected核实，S不能拿不存在的本地fullLG副本假全查。

S已有旧CH private未结束时ready0，J一路仍可独立接受；新OPEN只在O旧context正式退休后形成，所以不覆盖旧457/353。规范失败ACK也兑现两路，但不激活正常S context。wrong echo/status锁故障/保原期望，不用接收fire当已认证。S457保至本actor正确276/418及所有encoder/typed/来源借用真quiet；资格可在自己关闭后撤，值保到O正式退休后真实新457接受，不能局部reset覆盖。形成HANDLE128严格从本457真实epoch/CHgen及固定kind/zero28取得，不从最新J/UI推算。

S encoder只按稳定INITIAL353取词→O冷kind5写读核→O155 source→S155 private全核；正确155已消费并成为旧事实后，encoder形成其独立490 source=`echo353/INITIAL_handle128/status2/reason6/stored1`→S service490 private。两个490是已有980bit收费的owner迁移，O只有155，不再保第三份490。S service核全353/handle及合法stored，后续才原CLASS_COMMIT成功449；490反压时353与handle保持，不能借确认等尚未出现的S-load938/RETURN。

### D4. O内部copy、records与关闭

| job/实际来源→目的 | 触发、完整借用与完成 |
|---|---|
| COPY_LG kind1，M1 LG56词→O2257→CH1160/CH0 0…55 | OPEN384被O真实接纳且full来源检查/CHgen/M1 metadata lease建立后，排内部job；全M1 capture/核→全CH0写读核→后沿kind1 bodyvalid，才允许OPEN成功457形成。错体/未知不成功opened；保已预留gen/partial记录，独立关闭。 |
| COPY_CLJ kind6，M1 CLO22词→O2257→CH1160/CH0 194…215 | CLO登记ACK291真实消费、O已联核旧LCterm/353/CS/S-load938及原exclusive授予资格，排一次内部job；kind6全核stored为旧事实后才允许该CLO839/原prepare正常完成。不能在CLJ未登记时从latest caller猜full438。 |
| J kinds2/3/4/7，原1012/592/776/1013→146/28→CH0 | 原父唯一接收产生独立宽源；CH0全写/读/核后155。CS592供seal与CH是同父槽两借用/pending；1013同时为PUB expected，保到1150语义终结，不能155后覆写。 |
| S kinds5/8/9，353/938→146/28→CH0 | 938仅同一S原294/typed ledger/真实quiet生成；一个热938在正确155及本记录native/encoder借用空后可换scope，冷两938各47词保历史；原294/502仍独立。 |
| CLOSE/PUB/STOP | 原RETURN/502先行；PUB原1013经kind7+129激活，1150与context128两端独立。原276/418每actor各源/private、O各一轮流，STOP135/144独立，不借record data槽。 |

内部copy没有第三个BEGIN/WORD encoder或外部QUERY，也不增加J/S的BEGIN/WORD计数；O job只改自己的sourcelease/kindvalid/native pending。copy期间保护完整M1 body/gen，短native锁只围绕一致capture/实际更新，业务CH lease一直到CH正式退休。全copy失败仍保真实已写前缀/分配身份；known本地无未来native效果后可失效partial，UNKNOWN/Q不复用stage/CH。

原CH冷419词/8329body/一RAM、M1 LG/CLO地址、全353/1013/1150/938、原CLOSE294/502和FPI289/501不变。本H真实FPI quiet及END/JNL/held449空→938存储收据→RETURN真实ACK→原502→term；LOAD安装CLO不等待CH276/418、M1lease释放或returned pin METADATA_RETIRE。四份512 returned pin仍留原slot至CH所有metadata/admin/transport/parent引用真空。

## E. 唯一O dispatcher与中文沿序

O唯一2257/640/512 assembly由一dispatcher授予REGISTER_VERIFY、FULL_ACQUIRE、FULL_AUTH、END_PREFIX、RETURN、CH_ORIGIN_COPY、CH_SOURCE_CHECK、PUBLISH短microjob；已active job的完整body/partialcapture/nativepending保到该job末capture/check/结果复制真实完成，禁止换job覆写。CH1160由CH唯一record engine保，不与S JNL580/128混用。

不采用原CH每32issue强制换job；本卡选择有限full-check microjob非抢占，完成/存好结果并释放短锁后，round-robin服务下一个已eligible类别。同类别单depth1 credit，无法马上用原assembly的请求保原private并反压；不能接第二份cover。native read后下一沿capture，末capture的下一沿检查；输出source已实际复制好才释放assembly，输出反压不长持原RAM锁。登记WORD逐词WE是可完成的短job，等外部下一WORD时不占完整assembly/native锁；收到全部词后另排完整VERIFY。

每microjob循环界固定：LG56/CLO22、pin/descriptor32、CH最大58、JNL29；AUTH LOAD最多120/CLO单86/claim两份172个readissues（另capture/check），END_PREFIX32初RE+32WE+32读回RE，分别含相应pending/capture/check及等待另计；内部copy分别56/22 M1 RE加同数CH0 WE/RE。固定界只给有限工作量，不能当clock服务上界；不是96clock，不改服务卡原较低floor/排除项。DDR等待不占native job，尚无全eligible类别/µ/ROW期限联合证明。

| 无stall/无仲裁等待的相对沿 | 实际动作与不能提前做的动作 |
|---|---|
| REG e0 BEGIN；e1检查；e2,e4…e2n WORD；e3,e5…e2n+1 WE | 各完整218/28保持，写末padding0；stagegen预留消耗但bodyvalid仍0，不透传第一词。 |
| REG e2n+2 settle；e2n+3…e3n+2 RE，下一沿capture | 同一O assembly完整保存末料；e3n+4全来源核，e3n+5登记commit，e3n+6 formed291，最早e3n+7 fire；J后沿核291再形成内部1195/CLO登记事实。 |
| INSTALL b0 839 fire；b1核；b2 formed847；最早b3 fire | O后沿消费private847，再允许本prepare INIT；原BIND成功、PREPARED和ACTIVE均在各自旧事实之后，不同沿猜已完成。 |
| PREFIX p0 END676 fire；后排job | 32RE/capture全descriptor核→32WE→settle→32RE/capture全核→后沿prefixcommit→下一沿formed684→再后沿最早fire；job有等待时各µ增加，不能提前放下一AUTH。 |
| OPEN a0形成457与pending11；a1可J/S任意真fire | 未fire那一路继续相同457；最后一路实际fire只更新bit，后续旧pending00才源可复用。S可先capture后待当前839绑定，不阻父prepare。 |
| INITIAL i0 S155 private正确接纳；i1核；i2 encoder formed490 | service最早i3采490，后沿核全353/handle再形成449；INITIAL stored不依赖未来938/RETURN。 |

正常沿走查：已注册LG→COPY_LG与457→父/S各真收→原S prepare/安装/INIT更新→原BIND/ACTIVE→完整CLASS及kind5/490→原449/CLOSE→kind8→RETURN/502/LCterm及kind4→登记CLJ/kind6→CLO安装/BFS/全N导出→kind9/RETURN/502/CLterm→PUB→最终CH关闭。每条旧事实之前对应许可门关闭，但旧held继续履约；未提供实际µ时不填一帧耗时。

错误沿走查：END更新job末WE与cancel同沿先记真实WE/旧响应；不能形成新正常ACTIVE，完整descriptor读回保真实prefix/首次原因，若物理资格已known closed可给原END已提交结果并禁止父正常job，若未知Q保原permit/expected。OPEN一目的已收另一反压时STOP/cancel不撤457，未收一路收到原结果后按旧CHgen关闭；source/context不能改成本次UI。PUBLISH同沿cancel保实际descriptor/token和旧1150，父撤新bundle资格，不回滚成未创建。

## F. 具名位置、新增收费与语言契约

当前BK selected21606 + CH selected15792 =37398bit；其中宽body/assembly36553、CH控制845。下表是本候选相对此具名表的增量/补列，不是fullFF或增加的硅片实测。

| 新选择/必须补列的位置 | bits与去重界限 |
|---|---|
| J原LG1119 source、原CLJ438 source、内部LG完成1195 | 2752；LG/SC未在BK/CH selected列这三位置。CLJ source若已在原父账是同完整实体且租约成立时扣一次；1195不是新增O1195第三回复。 |
| registry BEGIN218/WORD28/ACK291两端各1 | 2×(218+28+291)=1074；J source与O private、O source与J private分别收费，不与CH146/28/155共槽。 |
| S完整OPEN457 private/context | 457；O原457 source与J原457 private仍在CH1682中，只加S第三目的；不额外加一个O457。 |
| fanout/新registry selected控制 | 64：pending2；S ctxvalid/ctxqualified/bindmatched3；J源valid2/内部1195valid1；streamvalid6；J state4/cursor7/expected1；O regstate4/recv7/issued7/captured7/pending1/checkvalid1/padfault1；registry firstreason6/sticky1/copyborrow3，共64。其它mux/child/allocator/transport控制仍CW-B02，不把64当fullscalar。 |
| 原O真实stage/grant资格须补列一次 | SC三header699、独立stagegen next/exhaust65、四32bit installed/return_requested/returned/metadata_retired mask128、五child state/证据40，合932；不包含caprevision/hotcache/LOOKUP。三header是原共用目录容量，当前只登记stage0/1，stage2未来入口未实现。若全机原账已有同实际932只扣一次。 |
| 当前具名selected并集下界 | 37398+2752+1074+457+64+932=42677bit；每个有完整实体/租约证明后才能与旧父/O总账去重。非完整FF/fit证据。 |

BK O assembly2257+640+512=3409只计一次，CH/SC同名同实体不再加；CH1160、S580/128、各两端held/private不可因此省掉。J的BUILD1012/CS592/LCterm776/CLterm1013共3393已在CH来源4684里；只在实际原父同槽、borrow寿命覆盖全部seal/copy/PUB时从原父其它总账扣一次。353和一个938共1291仅S源，不能省CH0两个938历史。

两674 source兼真实permit记录，已含599全文；不额外加裸KEY/expected副本，O全机唯一permit next/exhaust65及每permit valid/借用/quiet状态须原账实际并入（仍CW-B02）。A用841与原DR713保持329/201关联，不覆写这两个体才不另加KEY；globalrawseq不由local_seq代替。490 owner迁移仍原980bit，PUB cold1150与O/J热1150各自存在。原DIR journal一RAM已在11中，CH0新增一RAM；registry只用M1原191词，不加RAM，不能从nominal padding挤独立owner。

| RTL A–L | 当前合同 |
|---|---|
| A/J数值身份 | 上述全体unsigned；seq/gen先65bit耗尽预检、byteend33、native算地址至少10后核<512才9。词/pad/位顺序精确，无identity缩窄，H/holderlink/CHgen与stagegen分别核。 |
| B/C时钟接受 | 单core posedge、fire为旧valid&&ready&&!rst；capture不穿透下游；native RE下一沿capture，TB未来非采样沿驱动/更新后观察。 |
| D/E有效保持 | bubble不WE/不计新fire；旧held/expected和全部source lease保持，释放沿不借新空位；输入新配置不改变旧J/PCTX/许可。 |
| F延迟吞吐 | E只给条件最早沿，fulljob/反压/仲裁另µ；无1/cycle承诺，不拿名义DDR带宽造fps。 |
| G/H复位配置 | 同步rst高fire0；warm/cancel先旧fire，保fanout pending/457/353/旧metadata/seq；合法共同隔离后才可清资格。原新epoch本身不证明DDR旧效果消失。 |
| I存储 | M1/CH0原1R1W、OUTPUT_REG0、WE11/同址R/W禁、单issue；body/recordvalid分开；没有S descriptor缓存，不同步清RAM冒initialization。 |
| K/L域实现 | 本卡同core；CSI/HDMI/DDR PHY异步与物理关闭资格仍原合同。Ti60F225/I3/SV2009、现装RAM模型只读；实际full资源/时钟/引脚/STA未运行。 |

三契约分开：共同数值仍原完整Canny/全N EDGE与精确metadata；硬件执行另核全部accepted/stored/fanout/lease/native/RETURN/PUBLISH/stop；参考事务按原JID/H/ref/gen/原词序和各真实fire对应，错/取消只比较实际前缀与关闭，不以父term/CRC复制oracle。C++生产控制N/A，本卡未生成任何语言实现。

## G. 有限验证与实施计划（全部NOT_RUN）

| TEST | 输入/事件、独立期望与追踪 |
|---|---|
| CW-T01 | LG56/CLO22全词/末padding/错schema/H/epoch/来源/缺末词；原完整体独立oracle，原gen不复用，正确stored后才登记；CW01/D1。 |
| CW-T02 | partial登记错误/旧ALLOC存在/重放，SC全部合法reason0…10及非法11/63、错echo/0却reason非零或badgen/registered、BLOCKED2→真实后继0或Q3；1195无status2，SC6→LG21/SC8→LG14逐值独立检查，真实absence才LG1，原expected/部分ledger保留；CW01/D1显式status/reason映射。 |
| CW-T03 | 原BIND合法拒绝、ACQUIRE后847错/停8、INIT未完/277/812各停8；一个pin grant，只正确旧全部gate才CJ/ordinary；CW02。 |
| CW-T04 | CLEAR count1/4、末prefix/guard/gap/重复、BEGIN END/末WE/末capture同沿cancel；真实32初RE/32WE/32读回RE全descriptor保持非目标字段，684前不下一AUTH；CW03。 |
| CW-T05 | OPEN J先/S先/两者同时/各停8、未BIND先收457、另一目的等待时STOP/warm、错echo/nonzero身份；两目的各一次同全体，S不造CHgen；CW04。 |
| CW-T06 | INITIAL155/490/449各停8、错155/490、353跨839换scope；O无490第三槽，stored与490旧真后才449，影子保持；CW04/06。 |
| CW-T07 | COPY_LG/CLJ源56/22/高pad、每末RE/capture/WE停8、CLJ未注册触发尝试；内copy计数不灌J/S BEGIN/WORD，失败不授839/OPEN；CW05。 |
| CW-T08 | AUTH/END_PREFIX/CH_COPY/RETURN/registry并争唯一assembly；暂停只在完整job边界、不覆写partialcapture、旧输出反压不长锁RAM；真实issue/borrow/held独立scoreboard；CW05。 |
| CW-T09 | 6×5三快/GENERAL metadata路径及retain0/1；938 typed含op5不含INIT、FPI另计、RETURN先502、CLO不等CH退休；完整连接全body逐bit/计数；CW06。 |
| CW-T10 | 获批后完整1080p真实LOAD/BFS/全N导出/immutable EDGE，真实FPI与全部metadata/control关闭；独立全N gold，局部fixture不能代功能/PNR/STA；CW01…06。 |

局部25MHz验证用钟、seeds0x431/0x1060、每source/consumer连续停≤8、case上限200000cycle/wall120s；严格X/Z/EOF/hex/finish与实际compared/fire/WE/RE/lease计数。它们是失败监测，不是RTL timeout成功门。T10完整处理时间/工具上限随真实µ/共享服务冻结，不套200000缩图；当前不生成向量/脚本/TB，不先执行测量作为获批前置。

获共同指定批准后计划只在work/r4_closure适配原`logical_state_queue_service`及O/父registry/CH encoder，复用BK/CH已有候选文件名、一个真实native dispatcher与原RAM模型；不新增第二S/DDR/journal。实际filelist/固定source hashes/工具/cases由CW-B03统一，当前只是符号与计划。

## H. 双向追踪与I. 当前门槛

CW01→CW-J/O→D1/E REG→registry_encoder/register_fullbody/registered_snapshot→T01/02；CW02→S/O→D2 INSTALL→scope_install/prepare_gate→T03；CW03→O/S/A→END_PREFIX→prefix_update_job/end_expected→T04；CW04→J/S/O→D3→open_fanout/initial_confirm→T05/06；CW05→O→D4/E→native_fulljob/source_copy_lease→T07/08；CW06→全owner→原关闭/本文接线→scope_final_copy/retained_metadata→T09/10。全部源码/证据NOT_IMPLEMENTED/NOT_RUN；反向这些候选只承担真实交接和资源保留，不新增图像算法或主机生产路径。

| 未决/重要证据 | 影响与下一项有限处理 |
|---|---|
| CW-B01：BK138真实IP no-future-effects/写后可见性/共同reset资格尚缺 | END0/938/physical_settled/RETURN/PUB不能仅自报；根继续按实际controller公开合同与合法获批验证设计闭合，当前不得READY。 |
| CW-B02：BK159/CH173及DIR172完整scalar、eligible job/permit子借用/全机服务尚OPEN | 本卡给有限microjob与收费，不造完整FF/QoS；根需把实际每owner/FPI/JNL/typed借用清账信号、所有控制位/服务长界并入单实例账。真实原LG ALLOC transport/前登记来源位置也需同基线确认，本文未代填。 |
| CW-B03：BK179/CH179仍未有共同实现files/cases/工具基线 | 由根联合冻结本文明确delta与旧完整算法、真实源码计划和有限验证，当前不写新Manifest或baseline。 |

§10.3①整体/样例B，②C，③D，④E，⑤F，⑥B/E/T09，⑦G/H具备候选内容；⑧以上阻塞仍OPEN，⑨保存后真实全文/位宽/链接/hash读回并交根审，⑩v0.1范围与读取版本明确。**NOT_READY**；不将未来仿真/STA当审批前运行要求，不把此文保存当通过。

## J/K/L. 变更、实录与阅读顺序

本新卡明选SC登记运输/J内部1195、END0→O prefix更新、457双目的/S持久ctx、S encoder490、O内部copy/nonpreemptible fulljob。覆盖BK/CH相应联合候选的歧义，原卡字节不动；源/费用/测试随共同版本审阅，不能默以旧card hash称本delta已授权。恢复先核实际版本/审批/未决和旧运输/lease/效果；未知保Q。

本轮只入口/来源只读、本文设计写入及静态文档核算，无业务RTL/模型/脚本/可执行测试/TB/EDA/bit/安装/网络/数据库/硬件/正式状态改变。人工理解验收待用户真实反馈，讲解不代验收。

阅读B整体→C唯一owner→D登记/安装/INIT/context/copy→E旧沿→F位置/去重/语言→G/H有限证明→I仍缺什么。修改注册查CW01/T01/02，改安装/INIT查CW02/03/T03/04，改ctx/490查CW04/T05/06，改复用/关闭查CW05/06/T07…10；完整十一项及生产链仍需实际获批实现和工具证据，bit之后人工步骤不执行。
