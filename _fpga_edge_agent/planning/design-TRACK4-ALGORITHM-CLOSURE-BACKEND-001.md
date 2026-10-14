# TRACK4-ALGORITHM-CLOSURE-BACKEND-001：单S的完整span授权与真实后端操作设计 v0.1

2026-10-05；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)紧凑组织。LOCAL_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本卡将[R4C v0.3](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) B01中的具体微操作落为有限候选；原公共消息、八邻域BFS、全N导出、1080p及十一项目标保持。它不是现有RTL或真实DDR行为已经通过的证明。

## A. 计划、边界与真实来源

- Goal：规定一个真实S、两份完整span许可、两槽journal、独立物理请求/关闭，以及LOAD/CLO的初始化与返回顺序。
- Current state：R1软件实验已交付；R2 v1/48仍未获批准；R4C已选择DDR/no-cache但完整rounded授权、native状态写及shared raw身份原来未冻结。
- Target state：与O/CH/共享physical adapter联合审读，本卡所有必需前提闭合并形成共同基线后，才申请具体实施批准。
- Gap/Open questions：BK-B01真实IP可见性/隔离/服务资格；BK-B02 O安装/permit源保护与CH交接接线；BK-B03全机调度、实例和确切files/cases/timeout。不得将Q运行当正常成功。
- Assumptions：Ti60F225/I3、仅现有板载DDR；core100MHz仍生产候选，当前无本范围网表/STA；单J/scratch、原L/C单业务credit、一真实S。单S不能复制给LOAD和CLO并行。
- Dependencies：下表实际来源；现有IP/R1授权均不覆盖本卡。没有新增网络、软件、模型或保护区读取。
- Milestones/Detailed steps：B行为→C职责→D新内部IF与原消息相容→E有限操作/沿→F真实实例与单位→G/H→联合消除当前阻塞→READY/指定批准→work实现/仿真/综合/PNR/STA/bit。
- State transitions：只本文LOCAL_DESIGN；正式节点、Manifest、PostgreSQL与硬件状态不改。前一目标轮实际新增三主卡修订及事件，分类PROGRESS。
- Artifacts/hashes：A1为读取事实，尚非冻结共同批准基线；自身hash在事件记录，不自嵌。
- Validation：只读源、合同/整数/位宽分析及文件读回；全部功能/EDA NOT_RUN。
- Failure handling：旧held兑现、真实效果和UNKNOWN保留；独立CLOSE可推进已知本地债，不能用timer、一次读回或reset制造settled。
- Human approval gates：当前不READY、不重复询问R2；未获本范围指定批准不生成RTL、参考、脚本、TB或工程。
- Rollback：只新增本卡；R4C/RAW/DIR等原版本、冻结R2、R1与HDK只读，不执行候选接口迁移。
- Completion criteria：本卡需联合设计无当前正确性阻塞；完整目标仍需十一功能实际代码、仿真、综合、布局布线、时序与bit证据。

### A1. Root实际读取与采用范围

| 当前文件 | SHA256 / 实际范围 |
|---|---|
| [R4C](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)，500行/100929B | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；前轮全部实际delta与301–500，本轮135–218、304–346；原typed及E8/F2为边界 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，231行 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；本轮全文，descriptor/pin/journal及11RAM候选 |
| [PB](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md)，162行 | `0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40`；本轮首尾全文输出中段截断后实际40–123补读，全162覆盖；共享route/RX/W_CTX |
| [RAW](design-TRACK4-ALGORITHM-RAW-STORE-001.md)，367行 | `7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD`；86–188、247–263；只取ledger/latest/错误来源，不采用旧26bit/UART/PC生产后端 |
| [MR](design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md)，235行 | `4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662`；81–194输出截断处141–177补读；短锁与真实两端成本，不借914窗口装完整LG |
| [LG](design-TRACK4-ALGORITHM-LOAD-GRAD-001.md)，393行 | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；107–147、279–324；原CLASS唯一ACQUIRE/191词与三scope |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，298行 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；90–180；仅核gen/完整scope RETURN，不采用hotcache替代逐访问全查 |
| [INT](design-TRACK4-ALGORITHM-INTEGRATION-001.md)，271行 | `C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF`；119–144；DR201/713/731/AP472只是候选 |
| [C2公开DDR](../work/active/track4_ip_precheck_20261004/C2/rtl/ddr3_controller/ddr3_top.v) | `7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A`；仅1–192，192为加密起点注释，不读保护实现 |
| [C2参数](../work/active/track4_ip_precheck_20261004/C2/rtl/ddr3_controller/ddr3_parameter.vh) | `688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80`；全文54；ADDR32/DATA128/ID4/DQ16/ASYN1 |
| [旧写master](../work/active/track4_ip_precheck_20261004/C2/rtl/frame_buffer_V3/ddr_wr_buffer.v) | `182C396ECD29E838323CEDEE9AA17ED5EF33713884DDE1216BD30A6A58FB7311`；25–67、386–428；没有BRESP，末W fire推进，不能继承其done |
| [预检报告](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md) | `0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA`；48–67；map成功不证明DDR功能，CSI无key，未完成全物理检查 |

入口/config/prompt/state/ledger/DB/Manifest与模板已实际读取；唯一v0.2 hash仍`4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`，此前全文阅读有效，本轮重读§10–13适用部分。独立代理读回范围在本轮事件单独记，不署为Root新全文。原controller未导出drained/fence/isolation_ack/health_fail，cal_done仅是公开校准状态；通用Efinix文档不补成Elitestek v1.1的真实关闭合同。

## B. 可观察行为和要求

| REQ | 本候选保证/必要前提 |
|---|---|
| BK-01 | 原RQ324/RSP449/op0…5、CLOSE294/ACK502不改；完整正常CLASS→精确CLO→全N/P EDGE，失败不补后缀成功 |
| BK-02 | logical item许可与full16B/64B INIT物理span分开；O从完整真实pin/descriptor/holder重新计算，地址和init标志不是caller自授权 |
| BK-03 | CLASS/QUEUE两个许可和两journal槽同时真实保留，两个postimage及tail只有一个logical_commit可见门；不半提交、不重复claim |
| BK-04 | 独立FPI local_seq与sharedA global raw_seq分配；每个held/body/expected/effect/末capture均有实际位置，旧响应不释放其他scope |
| BK-05 | 新BUILD真CLEAR，CLASS LOAD清一次/CLO继承；physical和native真实成本、五通道事件、frame时间分账 |
| BK-06 | master侧完整匹配ID/RESP/LAST/拍数/范围与校准准入；真实IP资格未建立、未知effects时不得置physical_settled、RETURN或immutable发布 |

正常例：同一CLASS word有两个可达弱点；首次claim完整保邻bit/queue原entry，提交后真实写回和回应/退组，再次claim读到最新11及其邻01，分别只append一次。边界例：QUEUE tail1245184的地址0x04000000须保持32bit；不截成SRC0。失败例：j0写成功、j1响应无法判定，保两postimage/已提交tail和分别known/UNKNOWN，禁止全图发布，真实独立关闭不能取得时停Q。

## C. 唯一实例与连接

O安装完整scope→S_BINDSET→S验证并完成必要INIT→原BIND/ACTIVE门→L/C RQ324→S验证/两span AUTH→共享journal→FPI→sharedA唯一DR/AXI→真实回复→S状态/许可结束→RSP449；关闭分离FPI_CLOSE、permit END、scope RETURN、typed ACK、CH冻结值与metadata退休。

| MOD | 唯一责任/实际实体 |
|---|---|
| BK-S | 一份logical_state_queue_service内sequencer；原bind/context/typed ledger、地址、group/tail、INIT与FPI本地序号；不自授pin或O immutable |
| BK-O | 生产目录内span lease adapter；真实授予/两许可记录、源冷body业务lease和独立END/RETURN；native短锁不持到DDR |
| BK-J | 原16×29词共享journal和176bit效果台账；本S原子保留最多两槽，一assembly；不另加影子大表/CLASS cache |
| BK-A | PB/shared physical adapter的一个R4S frontend；实际global raw_seq及旧DR→AXI、独立R_ROUTE/RX/W_CTX。其它ROW/CAM/IMPORT/GC不复制本桥，原业务端口仍分别核 |

不采用SC hotcache或另coldcache。O每次span AUTH仍全查pin32/descriptor32/完整holder；本卡明确一次受保护span lease覆盖本opcode的read→write→settle，不能将这个选择泛化为跨opcode缓存。parent/M1全文在许可寿命内按实际业务lease禁止换代，动态S资格仍由唯一S判。

## D. 新内部IF、身份和相容

所有新body按高→低列字段，均unsigned，同core独立valid/ready深度1、沿前旧状态fire，held全文不变。它们是候选新协议，未自动替换原public或AP472。

| IF | 明确body/方向与规则 |
|---|---|
| BK-IF00 S_BINDSET | O→S **839**=`H160/stagegen64/epoch32/role4/CLASS(ref64,version64,grant64)/QUEUE同192/EDGE同192/installed_mask3`；S→O **847**=`echo839/status2/reason6`。由原S BIND唯一ACQUIRE后O实际tuple产生，不能caller填grant。LOAD mask001/其余tuple0，CLO class/edge必有、QUEUE按真实fastpath/bind事实；epoch与H/原完整LC或CLJ及O冷holder一致。所有原270/277/438/511仍保留；839/847只安装内部资格，不能代ACTIVE/INIT完成。新839只换当前访问scope，不清CLASS初态shadow353、CHgen/父来源lease/returnedmetadata及持续auth_seq/FPI local_seq；CLASS原初态按ref/version/initialtoken关联，不以新H冒充旧LOAD来源 |
| BK-IF01 S_AUTH | S→O **599**=`H160/stagegen64/role4/ref64/version64/grant64/auth_seq64/op4/index21/count22/span_base32/span_end33/init1/access2`；两端原body保持。普通op0…4沿原typed含义映射到实际object item；op5没有data授权；新内部op6=CLEAR、7…15非法。init1仅op6，不是初始化已完证据 |
| BK-IF02 AUTH_RSP | O→S **674**=`echo599/permit64/status2/reason6/initialized1/span_held1/latest_required1`；两份真实目的674同时存，不用一个槽覆盖。success0/reason0/permit非0/span_held1；ordinary initialized1，CLEAR可initialized0；mutable ordinary latest_required1。失配不结expected。O保持同receipt直到其END及回执运输关闭 |
| BK-IF03 PERMIT_END | S→O **676**=`原receipt674/outcome2`，O→S **684**=`echo676/status2/reason6`。outcome0 USED_SETTLED、1 UNUSED_NO_PHYSICAL、2 FAILED_CLOSED、3 PROOF_PENDING。0…2均须真实无未来本permit访问/route/native引用；2允许原写入内容/prefix仍UNKNOWN但实际无未来效果已由合法关闭证据建立，绝不改写原失败历史。3只报告未结债、不释放。正确RELEASED0/reason0才S记permit closed；不等父RETIRE或typed RSP消费 |
| BK-IF04 FPI | S→sharedA **KEY329**=`H160/local_seq64/permit64/op2/address32/length7`；RQ**841**=KEY329/payload512，RSP**859**=KEY329/status2/reason6/value512/effect2/written7/settled1。op0 READ/1 WRITE，其余非法；当前只16B普通和16/32/48/64B CLEAR、对齐16。S local_seq与auth_seq及DR raw_seq分别分配不互cast；readonly payload0、WRITE高于length bytes为0 |
| BK-IF05 FPI_CLOSE | S→A **289**=`H160/cutoff64/last_valid1/last_local_seq64`；ACK**501**=`echo289/accepted64/response_created64/settled64/closed8/status2/reason6/unknown1/overflow3`。独立于数据槽，cutoff是当前H真实FPI RQ fire含INIT、不计typed RQ。closed8为新publication封闭/旧held兑现/实际bus债结束/route-RX引用空/W holding空/旧data回执空/无未来效果资格/本H台账冻结；正确count/cutoff/last/overflow0/unknown0且全closed1才证明本通道quiet |

AUTH/END/BIND内部reason6：0NONE/1IDENTITY/2PHASE/3RANGE/4INIT/5WRITER/6CAPACITY/7NATIVE/8UNKNOWN/9EXHAUSTED/10CANCEL/11PROTOCOL/12REPLAY，13…63非法。status0成功、1REFUSED、2BLOCKED、3Q。AUTH BLOCKED为本次未授新许可的终结诊断，不自动循环重发；END outcome3/BLOCKED保原许可与债，只能在实际新的合法关闭proof到达后再形成outcome2的终结请求，不能计时或重放相同请求凑释放。Q或错echo保原真实created/expected，reply的permit0不证明所有grant为空。FPI status/effect/written/settled沿RAW D3的精确组合及原因族适配，unknown响应消费不清effect debt。各族向R4C reason5按身份/规范→5、真实storage失败→6、phase→9、close→11、取消→10、容量→8、耗尽→13明确映射，保first error/mask，不数值cast。

FPI_CLOSE_ACK.unknown只表示尚未证明关闭的未来effects/事务资格；不是旧写内容或已发生prefix仍UNKNOWN的历史位。真实合法关闭可令future-debt结束且unknown0，但原effectUNKNOWN/written0/cause/首次证据保持未知，不能增加成功数。A一次只持一个真实H绑定，旧H所有请求/关闭/回复运输及引用兑现后才接受新绑定；完整H/stagegen/role由O的IF00与原holder来源核实，local_seq分配器持续，不能因换role、换H或重放BINDSET清零或覆写旧expected/ledger。LOAD/CLO沿原不同scope，不让迟到旧关闭释放新绑定；这种运输隔离仍须联合实际接线验证。

普通AUTH：index/count是真object item。LOAD将public pair i转CLASS item2i/count2，CLASS read/claim为pixel/count1，CLAIM另对QUEUE tail/count1，QUEUE read为head/count1，EDGE pair i为item2i/count2。access0是mutable writer/RMW权限下的保护读子访问，不新建immutable READpin；access1写、2RMW、3非法，O核请求与原pin关系。grant/role/fullholder/stagegen来自真实IF00和O已存来源，scalar相同也不授权。

CLEAR AUTH：index21为首16B beat ordinal，count22为本chunk拍数1…4，不是byteoffset或完整QUEUE byte容量；O重算base+16×index/span_end，必须等descriptor当前连续prefix且不越同对象rounded。init1/op6只在真实BUILD/BINDING/排他writer与初始化分支下授，普通RMW仍等全prefix；无需先initialized才能许可CLEAR。成功可写tail padding，guard禁止。

O锁一致pin/descriptor/完整holder到末capture后校验，建立permit记录及源body业务lease后释放native短锁。许可保完整ref/version/grant/holder_generation、span与访问关系到实际END，停止/变更不得越过它；BUSINESS lease留到END，RAM物理锁不留到DDR。CLAIM两许可同时活，统一按CLASS→QUEUE顺序；第二许可失败只释放已知无raw效果的第一份，unknown保Q。两permission与journal容量实际预留前不发保护读。

sharedA使用实际FPI目的841中的KEY329与独立原候选DR held713中的KEY201关联，两个完整body在对应回复生成/关联真空前不可改写；本选择不再加重复KEY寄存器，只另计固定origin_port4/association_valid1。A唯一分配global raw_seq、保DR S96和对应真实permit/H，不能把S local_seq填入DR raw_seq。原DR201/713/731候选不改，并非这些接口已实现；A的FPI859复制完成后独立保持，route引用关闭不等S整图term。接受下一全机源的实际容量/最大等待仍BK-B03，不能因这5个selected bit就说整仲裁免费。

auth_seq和FPI local_seq各由S独立分配，合法共同cold隔离后next0；一份新held形成时消耗一次，发后不重用，最大合法一次后exhausted。LOAD→CLO与warm epoch均不将其归零；新H的FPI cutoff/三个台账从0开始，local_seq仍延续。没有FPI request时last_valid0/last_seq0；否则last为真实末fire，而非未提议或只分配的序号。sharedA raw_seq是它自己的全源序列，不由本FPI重建。

## E. 有限中文操作和旧沿

### E1. 地址、数据和初始化

CLASS pixel p的span=`CLASSbase+16×floor(p/64)`，其2bit在128bit内offset=`2×(p mod64)`；LOAD两pixel为一个4bit nibble。QUEUE entry t的span=`QUEUEbase+16×floor(t/4)`，offset=`32×(t mod4)`；coord低x11/高y11，高10zero。EDGE pair i的span=`EDGEbase+16×floor(i/64)`，offset=`2×(i mod64)`。先宽算base/end33及item乘加，不由窄地址零扩补救；上述合法普通opcode各目标都落一拍。

新CLASS LOAD BUILD一次CLEAR→ordinary LOAD；CLO核既有CLASS proof，绝不重清。新的非零QUEUE/EDGE绑定各CLEAR一次；fastpath queue_ref0无queue grant/INIT。chunk4拍使用len64、AXI LEN3，全payload512零；小图尾1…4拍、LEN=count−1。真实全部W及匹配B/效果资格后，后续旧状态才推进连续prefix。生产8100+129600+4050=141750burst、567000Wbeat、9072000B；6×5 rounded CLASS16/QUEUE128/EDGE16B。重复/乱序/失败不得按byte累计冒prefix。

### E2. 一个S sequencer与成对提交

状态需要5bit，具名阶段为IDLE/VALIDATE/AUTH_SEND/AUTH_WAIT/AUTH_CHECK/RESERVE/READ_SEND/READ_WAIT/READ_CHECK/PREPARE_WORDS/PREPARED_CHECK/LOGICAL_COMMIT/JOURNAL_READ/JOURNAL_CHECK/WRITE_SEND/WRITE_WAIT/WRITE_CHECK/STATE_WORD/END_SEND/END_WAIT/MAKE_RSP/RSP_HOLD/RELEASE/INIT/PHASE/CLOSE/INVALID_SETTLE/Q；28种，28…31非法。各send与wait/valid实际事件分开，错误保存旧事实转失败分支，不跳IDLE。完整session/BIND与scalar表仍与F合并，状态列表不是RTL实现。

| 事件/步骤 | 本次沿允许动作及保持 |
|---|---|
| e0 typed fire | 只捕获RQ324/更新真实accepted，不同沿raw、RAM或response；下一VALIDATE核H/op/coord/index/unused/阶段/容量 |
| AUTH/RESERVE | 独立发599/收674并核全文；两许可和pool真实两槽同时保存后才普通read。唯一pool owner原子选slot0/1，不接受caller指定；两槽不等允许第二group并行 |
| READ_CHECK | 完整859匹配及128bit旧span已捕获为旧状态，才核class初态/准备postimage。CLAIM失败不修改旧class/tail，不向坏coord寻址 |
| PREPARE j0→j1 | 单J_ASSEMBLY580组完整576与native尾4zero，29个20bit WE写j0；全部PREPARED旧真后再复用assembly读QUEUE/组j1/29WE。旧128bit holding可复用，j0已经在受保护真实槽，不能把它留在被覆盖holding中 |
| LOGICAL_COMMIT | 两prepared/实际容量/许可/旧tail都成立后，一沿group_visible及tail_new同时提交，两postimage通过唯一group门可见。不是两块RAM同沿完成；cancel同沿仍记录已提交三效果，后续失败禁发布 |
| JOURNAL_READ/WRITE | 每entry29RE，RE下一沿capture旧pending；末capture后再全文/pad/identity检查。128bit实际复制到PB独立W holding；AXI AW/W held、最后W不造成功，匹配B及真实资格后才该entry可settled。该entry的完整assembly保到STATE_WORD实际WE/更新完成，再换entry并读另一槽，不能只因W holding复制好就覆写原word27 |
| STATE_WORD | 真成功后由仍保本entry的assembly更新journal word27的state/cause，保其postimage高11及原其它位；实际WE完成后续沿才记cold更新/允许复用assembly。176bit published/settled/effect/written由shared pool唯一writer按实际事件更新，不借cold未写定状态冒相同事实 |
| END→MAKE_RSP | END前完成所需latest/native检查，封本组postimage的新读写门，独立冻结结果与关闭/诊断台账；本permit无未来物理访问/native/route/holding引用才END。正确END ACK后形成typed成功RSP。END不等RSP消费；END之后的MAKE_RSP/phase/close只用已冻结scalar/独立449与诊断，不再读journal，仍占槽仅保metadata到合法RELEASE |
| RSP→RELEASE | RSP实际fire后后续旧状态退group槽，旧full pop沿不接新ordinary。其它保留终态值为独立metadata，不借已退journal位置 |

latest命中须完整group/H/ref/version/span及原logical_commit事实；只比address不够。group_visible之前不向读者forward；之后且尚未封END前，内部必要检查可使用两prepared postimage；END后依独立冻结事实，不恢复journal读门。外部无权裸读mutable DDR。当前单ordinary未结清不接下一op，正常第二次sameword claim在前次reply/退组后重新读最新后端，保邻bit，不重复tail++。每组slot保留到真实引用关闭，不能按“另14槽空”偷开并发。

word地址=`29×slot+word`，slot0…15/word0…28，最大463；464…511未授。body576低位address32/length7/postimage512/state2/cause6/zero17；physical580末4bit0。word27为bits540…559，含postimage高11、state在[12:11]、cause在[18:13]、zero559在bit19，完整RMW保原其它位。R4普通postimage低128有效/高384zero；失败/共享其他512bit entry不得靠这一规则清掉它们的数据。

### E3. 停止、两个关闭和返回

当沿先记旧typed/AUTH/FPI/WE/RE/commit/回复火，随后封新publication；已held599/841/END/CLOSE及所有回执兑现。precommit取消不发布新group，已issued读取仍须实际结清；postcommit取消保两postimage、tail、known prefix/UNKNOWN，私有图INVALID，不能回滚成00或让phase成功。

FPI_CLOSE只在本H全部held841已fire后锁真实cutoff/last，允许data expected仍1；A只关当前H的源准入并结自己真实bus/回复/route/holding，不等S typed term、O FREE或parent退休。A整arena的DR source ledger与本H FPI ledger分别计，不强令typed数等physical请求数。错误KEY/状态不会清expected；超额R/B、missing/early LAST、不可归属响应或校准丢失停新业务并Q/UNKNOWN。

已知实际所有effects关闭时可INVALID_SETTLE→完成检查/封postimage读门/冻结独立诊断→各permit END→兑现已published typed失败RSP449并实际消费→确认typed expected/回复借用及journal native/pending/引用旧真空→后续退journal→scope RETURN/真实ACK→typed CLOSE_ACK502。失败reply消费本身不证明物理关闭，也不能跳过它去退槽；若某取消操作从未published回复，其合法处分与真实settled ledger独立登记，不能替已published回复结账。typed最后RSP fire后续沿才502，502不等父METADATA_RETIRE。PERMIT_END只结本span访问资格，不等于scope pin已返；scope RETURN需要全部permit/INIT/ordinary/effects/borrow真quiet，未知借用/效果保Q。

与[CH交接候选](design-TRACK4-ALGORITHM-CLOSURE-HANDOFF-001.md)的具体顺序是：先本H真实FPI quiet、各END与native/journal/held typed RSP旧真空→冻结真实S_FINAL938→CH正确record收据→scope RETURN真实ACK→原502→原终态。938不等RETURN/502，quiet mask不含pins_released。938三个台账只来自typed324/449，含op5、不含BIND/INIT，CLOSE294仍保原tx last；FPI289/501另计841含INIT/last_local_seq，response_created不是typed raw_response。初始化证书353的490在CLASS_COMMIT RSP之前，S独立shadow保到CLO938及该CLASS/CH实际退休，不能借新scope覆盖它。

新CLO安装只等旧LOAD合法502已消费、INITIAL490及S-load938正确存储收据、旧LOAD的typed/FPI/permit/journal/native/RETURN控制与该record encoder借用闭合；同时O须联核真实LCterm/353/CS/S-load938并实际授exclusive CLO。不等整个LG/CH退休、CH IF05两actor CLOSE、M1 metadata lease解除或returned pin METADATA_RETIRE，否则会形成CLO安装→CLO完成→CH退休→CLO安装的环。新scope不能覆写仍held的旧控制槽；整个CH context继续保存旧LOAD历史，单S只换访问scope。S839复用前真实确认封存值已复制，这些新端口/lease仍须联合落入O/S/J实际接线，BK-B02未假装关闭。

### E4. 实际IP资格及有限性

当前公开端口直接支持格式候选：ID4固定0、ADDR32、DATA128/WSTRB16全1、SIZE4、INCR01；普通LEN0，CLEAR LEN0…3，≤4拍且4KiB对象base/分段核界。AW/AR与各W保持到各自真实fire，W只在已捕获完整data和合法AW事务下提出；所有预留/RX/pending/WLAST/ID/RESP/计数独立。正常RX借PB7RAM及135bit持料、W128独立；末R释放物理响应，不提前覆盖仍引用的route。

cal_done未真且未建立匹配版本资格时不得新issue；运行中观察到校准/PLL/reset异常封新访问并保旧债。没有发明health_fail或drained硬件pin。master自己的empty可按真实ledger证明，IP no-future-effects/写后可见性/共同reset隔离仍须匹配此controller版本的合同和获批后有限验证，不能用B0、app_sr_active、一次readback或名义时序补造。计时上限只诊断失败/Q，不输出settled成功。没有该资格时本卡仍NOT_READY，不能作为一个永远Q的“完成方案”。

## F. 存储、数值与服务成本

下表冻结本候选独立宽body位置，全部同core寄存器候选；不按RAM/FF实测命名。已有槽列出以防遗漏，新增加和复用边界分别说明。

| 唯一位置 | 位数与寿命 |
|---|---|
| S原BIND private/BIND reply held/typedRQ private/RSP held/CLOSE private/ACK held | 438+511+324+449+294+502=2518；原业务body保留，BIND reply取最大511/LOAD277未用高位0，不借parent当前UI替换或内部ACK847 |
| S BINDSET destination/ACK source | 839+847=1686；context固定至scope关闭，ACK独立held，不在安装途中重建第二pin |
| S AUTH source/两receipt destination/END source/ACK destination | 599+1348+676+684=3307；两许可并存，源599在回复核验后才复用，END不能覆盖receipt |
| S J_ASSEMBLY/oldspan | 580+128=708；完整同步capture/尾padding与旧邻bit；不是PB RX或W holding |
| S FPI source/reply destination/close source/ACK destination | 841+859+289+501=2490；源841发后仍保KEY到匹配回复/效果关闭，两个关闭独立 |
| **上述S body合计** | **10709**；不含scalar/有效性、L/C的另一端、初态证书/phase/池控制或其它模块 |
| O BINDSET source/ACK destination，AUTH private/两receipt source，END private/ACK source | 839+847+599+1348+676+684=4993；两source receipt也作为本permit持久记录，不加一套同body副本，valid和生命周期另计 |
| O fullholder/descriptor/pin assembly | 2257+640+512=3409；明确选择与RC联合的最大2257窗口，LG/CLO未用高位0；后续必须与全机O真实实例合并，不能叠加旧1119或借MR914 |
| A FPI private/reply source/close private/ACK source | 841+859+289+501=2490；响应复制形成后旧RX引用可独立退出；原globalDR713/731/PB route及W/R holding仍另有原唯一实体 |
| A local↔global关联 | port4/valid1=5；完整KEY由仍锁住的841和global713派生，此借用要在实际接线时保持，否则必须补完整329/201而重算，不能先覆写body |

列出的body合计21606bit（S10709+O4993+assembly3409+A2490+关联5），不是全机FF或全部后端预算。只有assembly2257选择实际替代O旧候选实例时才扣一次旧窗口；没有寿命证据不得减原体。既有DIR11RAM/journal1包括在11中、PB RX7/holding135/W128与旧DDR父含桥保持一次；未新增CLASS cache/RX副本。冷body不等同步免费全读。

S必须单列scalar：phase5、19份body/assembly有效性、四独立expected（AUTH/FPI/END/FPI_CLOSE）、auth_seq及FPI local_seq各64+exhausted1、actual tail21/old21/new21、两个slot4/slot保留2/entry selector1/prepared2/visible1/settled2、native issued/captured/index各5+pending1、init cursor21/object2、first_reason5/sticky1/cancel1、typed与FPI各三64ledger及各overflow3、session/pool/close/phase相关真实标志。O的许可生命周期、source业务lease及allocator/lock/pending，A的各通道count/expected/health/关闭，全部有效性/错误保存与shared bank/pool仲裁尚BK-B03；本版不对不完整scalar表给假总FF。seq先65bit耗尽预检、tail先22、native地址先足宽核范围，所有非法状态及padding显式失败。

| 正常opcode | full AUTH readissues q×(32pin+32desc+holder) | read16/write16 | journal prepareWE/readbackRE/正常stateWE | AXI五通道fire |
|---|---:|---:|---:|---:|
| LOAD | q1、holder56，120 | 1/1 | 29/29/1 | 5 |
| READ_CLASS | q1、holder22，86 | 1/0 | 0/0/0 | 2 |
| CLAIM | q2、holder22，172 | 2/2 | 58/58/2 | 10 |
| READ_QUEUE | q1、holder22，86 | 1/0 | 0/0/0 | 2 |
| EDGE_WRITE | q1、holder22，86 | 1/1 | 29/29/1 | 5 |

readissue不是完整clock上界。INIT 141750 auth/chunk及独立prefix/native更新/END成本另M_init；四PHASE、binding、CH、RETURN、CLOSE、invalid/journal退槽/错误回执均另M_i。每ordinary write新增word27 WE，GEN正常w=N+2K≤3N，最多6220800状态WE；此前29WE+29RE尺度不含它。每physical read还要PB RX完整7lane WE和一次RE/capture；它们和O/journal使用不同实体，不可混算一个免费端口。

仅条件完成式：C_S≤M_i+Σop n_op·(μ_fullAUTH+μ_Jprepare/readback/state+μ_FPI_r/w+μ_END+μ_reply+δ_local)。每μ必须含实际仲裁、最后capture/check和有限consumer服务，不填1或从573091200/名义带宽得到fps。O/native一次授权全查是有限short job，锁止于permit/错误完整形成，physical等待期间其它合法native job可服务；全机owner数、job最长等待和ROW/CAMdeadline尚未证明。逐任务取得服务前提后再冻结case cycle/wall上限；永久notready只有限失败监测，不承诺成功。

RTL A–L：A上述足宽/padding与精确表；B/C同coreposedge旧状态fire/至少后续沿响应；D invalid不推进计数；E held/body与native末capture债保存；F上述issue/physical/clock单位分开；G同步rst火0且须旧外部effects共同隔离，warm不清seq/unknown；H旧LC/CLJ/BINDSET保持、新配置不改旧许可；I有限槽/1R1W/OUTPUT_REG0/WE11、同址R/W禁止；J H/typed/auth/FPI/raw/permit namespace及item/byte/beat区分；K相机/DDR PHY/视频多域不由本单域卡证明；L SV2009、Ti60F225与现装工具目标、全实例/clock/pin/STA尚未运行。

共同数值契约保持完整CLASS初态→独立集合可达→完整N-bit EDGE；硬件执行独立核真fire/group/effect/prefix/phase/RETURN/关闭；对应以原JID/H/ref/version/原像素及独立typed/auth/FPI/DR映射比较，不拿term或CRC代逐bitgold。host物理模型只bytes/注入协议错误，不运行BFS或生成token。

## G. 实施、有限验证计划（全部NOT_RUN）

未来work/r4_closure下计划修改唯一`logical_state_queue_service.sv`（sequencer/INIT/journal控制分局部职责），新`directory_span_lease_adapter.sv`、`closure_scope_install_adapter.sv`、`closure_physical_frontend.sv`；shared `ddr_byte_adapter`只一份，原其它caller接线仍整包共同清单。独立`closure_reference`和protocol scoreboard/有限TB/runner须获批准后生成；确切compile/files/case/timeout与共同基线仍BK-B03。先真实scope/授权→INIT→普通read/write→atomic→关闭/CH→完整1080p oracle→真实工具/bit登记后停硬件。

| TEST | 条件与可判断期望 / 追踪 |
|---|---|
| BK-T01 | 839安装错H/gen/epoch/tuple、LC/CLO同H不同role；不重复ACQUIRE、不因wrongACK推no-pin；IF00/BK01/02 |
| BK-T02 | logical AP仅1B、完整16B跨pad/guard、QUEUE0x04000000；O全查599 span，合法padding专用授权、guard拒绝，不能借旧26bit或AP472扩写；BK02 |
| BK-T03 | CLEAR未initialized、连续/重复/gap/尾1…4拍，CLASS LOAD→CLO；各对象只一次实际INIT，CLO不重清；真实141750/567000及小图完整padding；BK05 |
| BK-T04 | 两AUTH/receipt、第二许可拒绝/unknown、两个pool槽不足；不发保护read/半commit，无假return；BK02/03 |
| BK-T05 | CLASS同word两claim、QUEUE邻entry、两个29WE/RE和word27逐沿停顿；当前assembly保到stateWE完成才换槽，唯一atomic gate/tail，原邻bit/postimage高11/padding保持；BK03/05 |
| BK-T06 | AW/W独立held、LEN0/3、RID/BID/RESP/LAST/超额/缺末拍/校准丢失；末W/B0不直接成功，无实际proof则UNKNOWN/Q；BK04/06 |
| BK-T07 | FPI local_seq不同于全机raw_seq、GC/ROW其它端口穿插；实际329↔201原body锁定，回复不返错permit/H；BK04 |
| BK-T08 | commit/末WE/RSP/END/FPI_CLOSE/RETURN同沿cancel，held8/源停止；旧火保真，END前冻结并封postimage新读门，END不等typedRSP、RETURN不等父RETIRE，无循环；BK03/06 |
| BK-T09 | j0真实成功/j1UNKNOWN、wrong close或END、native末capture尚pending、失败typed回复停顿；已published失败RSP消费/真实quiet后才退组，historyUNKNOWN与future-debt分开，正确本地quiet不伪IPfuture-effect，Q不复用；BK06 |
| BK-T10 | 6×5/完整1920×1080 typed密集/长蛇/斜链及获批后真实R2 source组合；独立全N gold、真实成功/失败prefix、完整CH/O publication；BK01 |
| BK-T11 | 所有seq最大合法一次/exhaust、slot15 word28/非授权464、full2257 assembly/尾pad、取消后source换代尝试；无wrap/隐藏副本或裸冷读；BK02/04 |
| BK-T12 | 全机实际RAM/FF/DSP/时钟/引脚、ROW/CAM期限、功能/综合/PNR/STA/bit；不拿本card selected bits或R1局部结果证明十一项；完整目标 |

每normal周期限需由真实n_op/μ/M/有限stall调度冻结，wall限由现装模拟器完整1080p向量估计并实际验证；当前不编造数值、不生成测试。错误slaves/stall只明确fail/Q，不能timeout当成功。期望来自独立集合gold和外部真fire ledger，不读DUT摘要生成oracle。

## H. 双向追踪与I门槛

BK01→S/原324/449/PHASE→E1/E2→唯一storage_service→T01/10/12；BK02→O/599/674/676/684→D fullspan/lease→directory_span_adapter→T02/04/11；BK03→J/group门→E2/E3→journal控制→T04/05/08/09；BK04→S/A/841/859/289/501/201映射→physical_frontend→T06/07/11；BK05→INIT/E1/F成本→initializer分支与预算→T03/05/12；BK06→physical资格/关闭/RETURN→E3/E4→后端核验→T06/08/09/12。全部计划符号未实现/NOT_RUN；反向每新增完整body只承担真实scope、span、关联或关闭，不增图像算法/主机生产职责。

§10.3①②④⑤⑦⑩有上述具体候选；③⑥仍需IF00/O真实安装、permit注册与CH联合接线，⑧BK-B01…03当前OPEN，⑨保存全文读回/Root与独立限定审阅后登记。不得READY。BK-B01需匹配IP公开/厂商合法合同及获批后有限测试方式；BK-B02需与CH真实封存/来源/返回metadata逐连接，不含热cache；BK-B03需native/pool/A全机fairness/实际最大holder窗口唯一实例、完整scalar及文件/验证共同基线。没有靠缩小图像、队列或识别范围解除缺口。

## J/K/L. 恢复、实录与中文阅读顺序

本卡新增839/847、599/674、676/684和FPI841/859/289/501内部候选，明确不同于原AR348/AP472及DR201/713/731；R4C v0.3没有这些实际端口，需未来联合版本吸收/指定批准。未修改R4C、R2 v1/48、R1、原资料或正式治理。原public opcode6仍非法，新CLEAR6只内部AUTH命名空间。

本轮实际文档/来源读回、有限静态位宽与整数核算及独立只读反馈，未生成业务代码/参考/TB/功能脚本/工程/SDC，未仿真/EDA/bit/网络/安装/硬件/DB。作者/根审未解决IP未知时保持NOT_READY，保存文档不算功能通过。

阅读B具体行为→C唯一S/O/J/A→D scope安装/跨度与local/global身份→E1 INIT→E2双postimage/旧沿→E3两个关闭/RETURN→E4真实IP资格→F全部具名body/成本→G/H→I剩余当前阻塞。改变span协议查BK02/D，改原子性查BK03/E2，改global raw关联查BK04/D，改初始化查BK05/E1，改成功/未知关闭查BK06/E3/E4。完整十一项仍未完成，bit之后人工步骤不执行。
