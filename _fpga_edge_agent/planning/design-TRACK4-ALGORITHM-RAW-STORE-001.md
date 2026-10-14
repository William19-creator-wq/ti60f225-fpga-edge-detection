# TRACK4-ALGORITHM-RAW-STORE-001：完整算法core与PC字节存储边界 v0.2

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / UNAPPROVED / NOT_RUN。本文是候选架构合同，PC保存canonical bytes；算法、对象权限、原子提交与关闭控制留在FPGA。v0.2修订故障reset关闭次序和postcommit失败journal保留/退休；[原v0.1](design-TRACK4-ALGORITHM-RAW-STORE-001-v0.1.md)保留，独立修订复核仍待进行。没有实施、功能模型、工程或工具运行证据。

用户本轮最新限定“必须只用板卡现有资源”，DDR继续排除，不增加存储模块。故本文PC64MiB/串口后端仅保留为完整算法的逻辑仿真与低速观察候选，不属于允许的板上生产工作存储，也不能关闭生产容量/带宽/摄像HDMI门槛；S/O/journal语义若迁移到板载资源须另冻结真实控制器、寿命和服务保证。

## 通用计划字段

- Goal：在不绑定用户指定DDR器件/PHY/IP的前提下，为完整1080p算法core设计真实有限的raw存储边界；FPGA保留CLAIM_APPEND、state+queue/latest、DENSE_ADD16/RMW/count、phase/commit、目录和收尾。
- Current state：控制面按入口顺序读取、唯一v0.2及模板实际读取；R4-CLOSURE/RECOGNITION/R3/VIEW候选及UART原资料已只读核实；没有已实现raw backend。
- Target state：层次、容量、端口、字节序、授权、原子journal、错误和软件epoch可复核；与局部逻辑S/O、serial和全core组合闭合后纳入指定设计批准候选。
- Gap：原子控制器逐操作内部时序/文件、目录完整跨稿接口、SOURCE/GRAD/provider、完整serial decoder/reset/时序及全机资源尚OPEN；64MiB只是PC软件容量提议。
- Assumptions：本域同步高有效rst、上升沿沿前fire、一个arena/处理slot、一个raw data credit；所有算法结果来自FPGA。候选serial与算法共27MHz，100MHz仅历史预算比较，最终整包clock选择未定。
- Open questions：A2；不以主机数组充片上RAM、不新增识别场景硬边界，不要求批准前先写代码或跑工具。
- Dependencies：唯一根v0.2、R4C5B147、R4R AA058、R3 6D071、VIEW C764；CONTROL授权epoch、REPLAY返回、R5真实源/视频与完整文件套件。
- Milestones：B整体→C层次/连接→D端口与组合→E中文局部→F映射/预算→G/H验证追踪→保存读回/独立审阅→闭合真实设计→整包批准→获批后实施。
- Detailed steps：见E1…8；source输入初始化与对象准入→授权/packet→raw访问→journal/逻辑提交→真实效果→typed response→immutable provider→实际归还；失败走独立close或Q。
- State transitions：arena COLD→OPEN_HELD→ACTIVE→STOPPING→RAW_CLOSE_HELD→CLOSE_VALIDATE→TERM_HELD→CLOSED；未知终态QUARANTINE。typed原子组正常IDLE→AUTH→RESERVE→READ_OLD→BUILD_POSTIMAGE→LOGICAL_COMMIT→WRITEBACK→SETTLE→RSP_HELD；postcommit失败进入INVALID_SETTLE，不以typed回复消费回IDLE；未知效果进入保留组的QUARANTINE。
- Artifacts and hashes：本轮仅创建本文；输入实际SHA见A1，本文SHA/bytes由实际全文读回报告，不写自身hash。
- Validation：G全部NOT_RUN；静态位宽/容量、独立数学、协议、完整软件、综合网表、PNR/STA和硬件分别结算。
- Failure handling：known-none、known-partial/full、unknown effects分开；wrong echo不结credit，取消不擦旧fire，数据失败不发布完整结果，未知义务Q保留。
- Human approval gates：仅本纯文档创建/读回授权；无业务实现批准。未READY，不请求用户批准未成熟架构；Manifest/数据库及人工下载观察规则继续。
- Rollback：只停止引用此候选；不改来源、HDK、规则、正式状态或数据库，不恢复覆盖用户文件。
- Completion criteria：完成可读候选、全文读回及审阅交接；批准前冻结真实可综合局部控制/目录/serial/clock/pin/容量与验证计划，获批后才实现和取得工具证据。

## A. 状态、来源与边界

任务ID TRACK4-ALGORITHM-RAW-STORE-001；关联BATCH R4/R5、R2 B03/B05及完整算法core存储边界。无Git commit，不伪造。下一允许行动仅纯设计与独立审阅；实施范围、work路径、相关基线和条件须由成熟整包的明确批准给出，本文件不自授。

### A1. 实际来源

| 文件/事实 | SHA256 / 采用范围 |
|---|---|
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；设计/批准与映射 |
| [PLAN_TEMPLATE](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| [R4-CLOSURE v0.2](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11；63263B，STORE324/449、原子claim、全N导出/真实close |
| [RECOGNITION v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257；83901B，OBJ799/872、DENSE_ADD16、POINT与工作容量/held终态 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D；51448B，全部数值运算仍在FPGA |
| [VIEW v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C；64477B，完整bundle/parent与borrow/private退休/epoch候选 |
| [BATCH](design-TRACK4-ALGORITHM-BATCH-001.md) / [ROUTE](design-TRACK4-ALGORITHM-ROUTE-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 / 2D082374D56754CE4D38654B4945D3D736FABD9C5F36FE8E47759CEBCF90E9AE；完整1080p与十一项，具体DDR暂停不等算法停止 |
| UART参考路径B | 工程根“Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4/17_Ti60F225_uart_demo/17_Ti60F225_uart_demo”；原目录全部只读 |
| B/top.xml / top.peri.xml | 301B3A723ADBD6283963B3DF50AFCF27CC2317BCA21103D382B14D9DCE53988D / C8267E62CBA2590834F21AB594115ADF40863DF46F9A27267D85E58392634936；实际全文；Ti60F225/C4旧工程、27MHz GPIO、UART3.3V |
| B/src/top.v / uart_v3/uart_rx_tx.v | 40F08864C60F6ADC208500A78B222A73817BBA3D09A3B1A60D1478AC5D42A60E / F82D6A1EAB269B0D85C4AFA1DF517283B7FD7D98CB0F36D185153C1221BC0EE6；实际全文；27000000/115200、divider234、原8N1.5、error未向top暴露 |
| B/src/uart_v3/uart_tx.v / uart_rx.v | 993E61224D9D098D043B90997EB66D57CD927D8D67A42E33E0EF93C35D9E3993 / E959F763A86796E99DC49E8C533B7D7568C713B27B911C874FCDB2AFA0A9B5DE；实际全文；无held-ready保证/脉冲rx_valid，不直接复用 |
| B/src/sdc/LED_8bit_Test.pt.sdc | A86DF6A7F7E1092A39FE45FDE599010A6CF21BC4518D89F32CC0136788681EA5；实际全文；UART错误引用clk_50m、USER_PERIOD未替换、无27M clock，不能拿历史pass当新证据 |
| 独立协议代理的pin核对 | 其只读报告：R4→GPIOL_02、R14→GPIOR_28、H2→GPIOL_P_10_CLK3_P；package E58A269F05807655F58FC3AE9DE6F96C0E544E075436E93F5C5EC2322CE2A6BD；die E48633E2BE50401FDDB030E20B4E37649B8AF4278C3CADEEA20C438E6C91CFA5；本文未全读巨大die，属于明确代理证据 |
| 独立代理的板文档/模型核对 | 板txt E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8；UART所在BL/BR3.3V，手册“都在TR”与工具冲突不采用；timing模型 D7779F14DC8F4E9047C28D85A6A911029A1676128D5DD94ED8D7AED5A0A22587含I3/C4不同速度，I3身份/工程选择须联合冻结 |

项目规则、运行提示、config/state/ledger/database与Manifest已按入口实际读取；数据库NOT_CONFIGURED，本纯设计不执行数据库操作，也不改状态。来源已在本轮及前序实际全文读取，同hash复核；UART事实是参考工程证据，不确认用户尚未到货实体。本文不继承DDR physical key/MC/grant/917bit job等旧消息。

### A2. OPEN与责任

| OPEN | 当前设计缺口 / 影响 / 责任 |
|---|---|
| RAW-B01 | 各typed原子控制器的完整逐操作内部FSM、byte packing/forward、目录lookup/mutation调度尚未独立局部冻结；影响IF02/03/04和所有commit。S/O设计者按E3/E4另形成局部稿，不靠host代算 |
| RAW-B02 | 真实SOURCE/GRAD收集、fixture bootstrap writer、对象安装/返回/aux RECORD及CONTROL/VIEW授权epoch接口仍未完整合并；raw OPEN不创造已有合法图或profile |
| RAW-B03 | UART新8N1收发、完整packet parser/CRC/重同步、冷复位和软件reset隔离、COM/FT接口及具体测试约束/时限未形成局部设计/文件；本域握手不能代serial实际证据 |
| RAW-B04 | 全core27MHz候选与R1/R2/R3计时/资源/其他时钟、I3/C4选择、完整实际pin/SDC及防裁剪hierarchy尚未联合冻结；100MHz预算非实测 |
| RAW-B05 | 完整数学、协议、byte-only backend、full1080p fixtures/GT、case/manifest/runner/timeout与文件基线OPEN；批准后才生成可执行套件 |
| RAW-B06 | 完整摄像/HDMI60Hz/CDC、真实后端吞吐与生产方案仍R5 OPEN；低速UART不是实时生产输入/输出，十一项总表不缩水 |

成熟候选的本域raw字段、容量、失败区别和控制归属可以独立审阅；以上缺口使本文NOT_READY。不能将工具NOT_RUN本身变成批准前先实现的循环。

## B. 整体外部行为

| REQ | 可检查合同 / 来源 |
|---|---|
| RAW-REQ01 | 生产N2073600、P1036800、完整RGB与全部算法；外部64MiB仅canonical byte存取，R3/closure/recognition/ANN所有算法及对象权限在FPGA。来源用户DDR无关路线、BATCH与R4C/R4R |
| REQ02 | 单arena/单处理slot，不偷偷保留第二整帧。当前逻辑量41,113,469B，共享EDGE只一次；目录/对齐/少量profile显式另计，不声明数组是片上RAM |
| REQ03 | 单raw data credit，真实finite RQ/RSP；授权、地址扩位、初始化覆盖、byte order及unused校验前不访问；每次读取返回实际bytes，写成功只有全部真实效果结束 |
| REQ04 | FPGA journal保护claim state+queue与16票原子可见；RMW latest、计数溢出、phase/commit皆本地。PC既不识别对象语义，也不执行CLAIM/DENSE_ADD |
| REQ05 | held/fire、known-none/partial/full/unknown effects、取消旧交付、独立CLOSE与source ledger有明示规则。wrong echo不结expected，未知不假closed |
| REQ06 | 目录、commit/ref/version/pin/borrow/token唯一owner与真实退休；raw session独立于LOAD/CLOSURE/RECOGNITION逻辑会话，raw CLOSE不代借用归还或完整bundle |
| REQ07 | seq/ref/grant/session/epoch不回绕，软件reset先真实QUIET/返还/close；Q保留，禁止单端reset清债；只有CONTROL的授权事件能准入新epoch |
| REQ08 | 本域raw软件仿真、真实serial/pin及完整core PNR/STA/bit分别证明；普通pattern/四pin小工程不能替完整core，不虚报带宽或识别fps |

触发：父域拥有授权epoch和arena，实际OPEN fire只锁候选，不承诺已存在服务；正确OPEN_ACK后ACTIVE。输入来自完整算法typed事务；PC只读/写byte array及报告自己真实执行状态。输出是完整held RSP、独立CLOSE_ACK/RAW_TERM及可审计prefix；读零值是有效data，不是空响应。源码/模型尚未生成。

正常样例：闭包请求claim某01点→FPGA核CLASS/QUEUE pin与tail→保留两postimage→成对logical commit→raw写CLASS byte和QUEUE word→两实际成功后typed claim response→后续phase commit→全N最终EDGE→recognition→全ANN/record→完整O/VIEW。PC看见的只有地址、长度和bytes。边界：最后一个QUEUE entry=N−1可以claim到tail=N，随后精确结束；没有新容量即失败，不短FIFO/截断成功。未知写/坏echo：旧消息先履约，整slot失去结果发布资格，独立raw CLOSE证明或Q。

arena ACTIVE可以依次服务同一slot的BUILD/完成VIEW/退休后的下一JOB，raw_seq连续不复位。只有前一图所有refs/borrow/held真实返还且目录已退休才复用相关地址；旧VIEW借用未返还会阻止新BUILD。全arena CLOSE用于实验停止、fatal raw fault或软件epoch切换；局部S CLOSE不正常关闭全arena。处理成功与raw会话成功是两种终态：raw健康关闭不证明形状识别质量/帧成功。

## C. 职责、连线与死锁检查

| MOD | 唯一职责 / owner / 边界 |
|---|---|
| RAW-O FPGA对象目录 | 64descriptor/64pin候选，分配范围、版本、writer排他、初始化/commit/返回/退休；不给裸地址调用者自授权限 |
| RAW-S FPGA typed控制器 | 执行LOAD/CLAIM/QUEUE/EDGE及OBJ各种record操作、RMW/计数/journal/phase/commit/CLOSE；现行S/STORE接口适配保留typed身份和真实ledger |
| RAW-A FPGA仲裁/字节适配 | 8client各depth1请求/回复候选，单raw credit、合法span/packing、raw_seq与typed key对应；不给frame功能额外writer |
| RAW-L FPGA packet/serial | 本域raw→有限wire packet、RX ring/CRC/parser、错误通知/期限和独立close；不计算图像/投票/拟合 |
| RAW-K FPGA观察发送 | 镜像真实父消费的冻结状态及真实REPLAY OUT404，有限槽/分段发送到UART；不会第二次消费CS或改父状态，输出反压真实可观察 |
| RAW-P PC byte service | 固定64MiB数组、一次raw读/写、实际source ledger与关闭；不由对象编号执行算法、不造成功token、无自动replay |
| CORE现行算法/VIEW | FE/C0/closure/R3/recognition/render仍真实RTL；只有完整O资格给borrow/provider，PC输入fixture与黄金不能兼任算法 |

路径：CORE typed IF01→S/O IF02→A IF03→L IF04→UART IF05→P byte array→反向RSP→A/S→typed RSP/commit→O→完整provider IF06→REPLAY。关闭：上游停止/取消→S不再新算法，旧published履约→raw CLOSE IF07→实际PC ledger→L/A核证→S各自typed CLOSE→父TERM/O真实返还；全arena最终通知IF08。epoch IF09由CONTROL唯一owner，层层QUIET后才新OPEN。错误L/A/S真实通知→父cancel，只单向收尾。

8client固定候选：0SOURCE/bootstrap、1LOAD、2CLOSURE、3GRAD collector、4RECOGNITION、5REPLAY SRC、6REPLAY EDGE、7REPLAY ANN。每client允许一typed在途，A以轮转仲裁事务；S的一整个原子组不可被另一个writer插入，同addr最新值先journal命中。合法immutable读取也只能在当前组安全界或使用已冻结版本。不宣称多个并行RAM读口。

正常不会形成raw CLOSE等待typed term、typed term等待raw CLOSE请求发出的环：接受close只须停止新提议并兑现自己旧held raw RQ，不须credit先清；PC只等自己已accepted读写/response形成及发送队列排空。typed S关闭只等自身真实raw债结清，父对象退休等typed终态，不反向阻止raw关闭。Q通知不释放未知义务，永久不ready保持，不伪有限成功。

## D. 接口、表示与组合

### D1. 同域、身份与有限事件

本文新消息按列出的高到低字段。S96=authorized_epoch32/raw_session64，raw_session由父reset/arena owner唯一分配；同epoch next0、最大合法一次，下一次EXHAUSTED，不回绕。软件epoch改变不自行授权、不清raw/O状态。raw_seq64在一个S内从0逐published请求消耗，即使取消/错误也不重用；提出后不能撤，最大号可以完整履约后exhausted。各typed tx_seq、NUM call_seq、frame/result/borrow仍原namespace，禁止裸cast。

fire=沿前valid&&ready&&!rst；capture沿不穿透，下游最早后续旧state。计数uint64先临时65bit；达到最大合法值后的下一次事件置overflow并失败，保留最后可表示真实前缀而不回绕。旧fire与cancel/error同沿先结旧承诺，下一旧STOPPING/ABORT禁止新普通提议。valid0不形成事件。旧full即使同沿pop也不接新data；状态/错误/close各独立槽。

### D2. 无实现体端口合同

| IF | body/方向 | 前置、保持、效果与失败 |
|---|---|---|
| IF00 ARENA_OPEN | 父→L/P OPEN256=S96/capacity27/schema8/data_deadline48/close_deadline48/zero29；ACK328=原OPEN256/status2/reason6/provider_instance64 | capacity=67108864、schema1、非0期限；真实PC数组容量及旧服务关闭/无旧writer成立才success0/reason0/非0instance；failure1/非0，其他status非法。不授权任何对象、不表示RGB已初始化；各held |
| IF01 typed clients | CLOSURE保持RQ324/RSP449/CLOSE294/ACK502；RC保持RQ799/RSP872/CLOSE295/ACK504；其他SOURCE/GRAD/REPLAY按各原族适配 | 原record/角色/key/count/token含义不变；不能blindcast为raw body。局部适配及其他族准确port仍B01/B02 |
| IF02 byte授权 | 内部AR348=clientH160/role4/ref64/version64/access2/item_index32/item_count22；AP466=原AR348/permit64/address26/first_bit3/byte_length7/record_bits10/status2/reason6 | O用真实目录/owner pin/初始化与stage核，success0/reason0/permit非0，span1…64；failure1合法非0其余suffix数据0。access0读/1写/2RMW、3非法；record_bits1…512。不是外部调用者传地址自授权；role限定原clientH解释 |
| IF03 RAW本域 | A→L RQ707=KEY195/payload512；L→A RSP725=原KEY195/status2/reason6/value512/effect2/written7/settled1 | KEY195=S96/raw_seq64/op2/address26/length7；op0READ/1WRITE，其余非法；length1…64；单expected/独立接收槽，data highzero，D3规定全部组合 |
| IF04 packet内层 | L↔P 固定body byte stream；packet type/length/CRC见D7 | 一个data请求/响应，close独立；CRC合法只证明传输，不证明semantic成功。无自动重发，dup/错body触发协议失败 |
| IF05 实际UART | rxd→新RX、TX→txd；异步线8N1、115200候选，27MHz divider234 | 无硬件ready线；host遵守一请求/一响应/独立close的有限窗口。RX错误/full显式通知，不静默丢。参考demo8N1.5不继承 |
| IF06 immutable providers | O→SRC/EDGE/ANN provider→REPLAY既有读口 | 只有对应全N commit、身份/版本/borrow合法；读实际byte拼pair并核canonical，不能以class代edge。provider正确性/目录接口B02 |
| IF07 RAW_CLOSE | A→L/P C231=S96/request_cutoff64/last_valid1/last_seq64/first_reason6；ACK442=原C231/source_accepted64/response_created64/source_settled64/closed8/status2/reason6/overflow3 | independent held/ready；真实ledger与截止见D4，ACK suffix reason独立于C.first_reason，不能把wrong echo当释放他人credit |
| IF08 RAW_TERM | A→父T469=S96/status2/first_reason6/mask32/last_seq64/last_valid1/四ledger256/flags8/overflow4 | 四ledger为RQ fire/raw RSP fire/合法success RSP fire/source_settled；raw会话终态，不是frame/quality成功；held，D4矩阵 |
| IF09 epoch/恢复 | CONTROL授权owner→arena/O/L真实QUIET及新epoch事件 | 不是一个input epoch数值改变；actual授权桥/消息须合并VIEW/CONTROL B02。未知义务不能准入新epoch |
| IF10 CORE观察 | 各原唯一owner→K，8独立valid/ready/真实冻结body；K→L CORE699=S96/channel4/record_seq64/part_index8/part_count8/valid_bytes7/payload512 | channel0 CS592、1 LC_TERM776、2 CL_TERM1013、3 RC_TERM2606、4 REPLAY OUT404、5 REPLAY RT1171、6 FINAL512、7 FIRST_ERR930；只镜像父真实消费后的状态，OUT由K实际握手，已published保持；D7明确分段与容量。未冻结其他观察口不靠此表自造 |
| IF11 RAW_CANCEL | 父→A S96；ACK104=原S96/status2/reason6 | 0APPLIED/1ALREADY reason0、2NO_MATCH reason1、3REJECTED合法非0；独立held槽。只匹配沿前旧activeS，新OPEN同沿不成为匹配对象；TERM已published/消费后的旧S保留期间只ALREADY、不改冻结终态。receipt不等实际CLOSE/返还 |

REF64候选=allocation_generation58/index6，generation由O跨软件epoch持久分配，从1开始，最大合法一次而后exhausted；0非法。grant64同理，index6指64pin表，另有独立generation58；version/commit64独立持久序号，不以地址或裸grant替代权限。共同冷run重建须所有参与者与旧wire隔离；旧S不同即拒旧ref/context，即使低index巧合相同。这些新ref表示须与VIEW opaque ref接口合并，当前不是已实现目录。

schema hex高padding：KEY195=49digit/1bit、RQ707=177/1、RSP725=182/3、OPEN256=64/0、OPEN_ACK328=82/0、AR348=87/0、AP466=117/2、C231=58/1、ACK442=111/2、T469=118/3、CORE699=175/1；byte transport的最后byte高padding另按ceil(bits/8)检查，不能把hex pad当byte pad。

### D3. canonical bytes、地址和真实效果

低编号bit/item放较低地址/低bit；raw value/payload byte0=bits7:0，byte1=15:8等，与外部消息字段高到低排列区别。BITPACK表连续排列，item i首bit为i×record_bits；pixel q=yW+x。原logical table bytes按ceil(items×bits/8)，不能改为ceil(recordbits/8)×items后仍用旧容量。SRC24/RGB通道与POINT/GRAD等record内部格式照原schema，不擅自换RGB次序。末byte未用高bit及消息payload未用高bit全0。

地址只由O给的base与受限本地index产生：index32×record_bits10先42bit，首byte/末byte计算先43bit，核真实item范围与object byte容量后再收地址26。addr+len先27bit，需65536≤addr、1≤len≤64、end≤67108864，并在同一授权对象[base,base+capacity)内。range overflow/role/未初始化拒绝发生在任何raw RQ之前。半开end=2^26合法，不能窄为0；addr=2^26−1/len1合法但还须对象授权。caller payload中的坐标/ref字段不是RAM地址。

当前列出的record位宽均满足单record span≤64B；通用descriptor仍须检查实际first_bit与末byte，不因record_bits≤512便假设任何排列都≤64。PROFILE1024在raw目录以两项512bit page组成同一128B实体，两页与whole-profile版本/初始化/规范验证全部完成才安装；不能收窄为10bit record_bits=0，不能用其中一页冒完整profile。新object_kind8候选0…25沿RC命名，26SRC/27CLASS/28QUEUE/29PROFILE_PAGE，其余待目录schema明确后才合法，不能不同族同号blindcast。

READ payload512全0；success0/reason0/effect0NONE/written0/settled1，value低8length为实际bytes高位0。WRITE payload同样只有低8length可非0；success0/reason0/effect1FULL/written=length/settled1/value0，表示本次全部bytes真实完成且操作无后续效果。PC不能先回成功再后台复制。

known failure status1、reason合法非0、settled1/value0：effect0NONE/written0；或effect2PARTIAL/written在1…length−1，表示按升地址顺序已写的准确前缀；或effect1FULL/written=length（全物理写已经发生但该次报告失败），三者都不让逻辑组成功。READ known failure只能NONE/written0。未知failure status2/合法非0/effect3UNKNOWN/written0/settled0/value0；包括packet/连接期限到但无法证明服务未执行。它不伪造无副作用，语义response可真实消费，但另置effect_debt保留KEY/journal/ref，后续实际close证明才结债。status3及其他组合是protocol error。

每raw RSP真实fire都raw_response++；只有完整合法status0增success_response。匹配known failure结expected并失败，匹配unknown结响应关联但留下effect_debt，错KEY/非法body不结expected；invalid valid0不推进。新raw请求须旧expected0、旧rsp槽空、无未结effect_debt且原子组允许；不靠响应出现组合穿透再发新请求。

packed mutable表首次RMW前必须已由FPGA逐byte CLEAR并真实settle，不读取PC分配时的未初始化内容；CLASS/ANN/21bit vote/bitmap等均如此。POINT/SEG/FINAL等整byte record以真实有效前缀初始化，未用洞不读。immutable输入SRC/profile的bootstrap初始化与core准入需B02；PC分配零阵列不自动创造初始化/合法SRC证书。CLEAR效果可逐块完成，整表直到最后成功/无pending才置initialized；途中失败private build无效。

### D4. raw CLOSE、ledger与终态

raw arena session包含全部client，不等于H160各逻辑会话。typed局部close检查其自身group/ledger/pin；正常LOAD→CLOSURE→RC→VIEW继续用同S。fatal raw错误时关闭整个arena，停全部新raw事务/新view/build；已published与合法旧pixel交付先结算。logical service request数量（如≤13N）不能当raw byte请求数或PC source_accepted。

C231在自己旧held RQ兑现后锁cutoff与最后真实RQ seq，允许expected/effect_debt仍在。PC只等当前S自己已accepted byte操作真实停止、读/写pending及response形成/发送队列关闭；不等FPGA guessed credit、typed term或O retire。PC按完整合法packet接纳计source_accepted，按一次实际生成data response计response_created，按其byte操作确实无未来effects计source_settled。UART packet byte数/CRC错误数另为transport诊断，不冒充raw RSP fire。

正确ACK需全文echo C，包括first_reason；accepted=cutoff、response_created=accepted、settled=accepted、overflow3零、closed8全1。closed bits0…7为新请求封闭/request decoder空/PC读写pending空/response形成空/旧软件data TX队列空/本服务writer权限关闭/ledger封存/source closed；ACK本身独立槽不计入旧data空。suffix status0/reason0或status1合法非0均可证明真闭合，但status1本身是新的关闭失败。若source未接纳最后lost packet，accepted≠cutoff，不能自补计数；进入Q，即使PC声称自己的队列为空。此保守设计不自动replay/重试来猜旧WRITE有没有发生。

PC同一UART发送顺序必须旧data response在CLOSE_ACK之前；FPGA有独立RSP/ACK槽，ACK即使先被parser缓存，也只能在旧published raw RSP真实fire并后续旧本地data通路空时验证/结算，不在末data fire沿用新empty提前终结。错误data已经消费可raw count不同于accepted；不强令所有接口计数相等。correct关闭证明只结该S expected/effect_debt，原错误仍保留，不给build/ANN发布资格或清别人的borrow。

T469的flags0…7为arena_bound/raw_close_proved/raw_local_empty/children_quiet/private_refs_retired/all_borrows_returned/drained/cancel_seen。COMPLETE0须own first_reason/mask/overflow0、flags0…6为1/7零、RQ=rawRSP=success=source_settled且实际合法close证书；只证明raw服务与全arena退休义务完成，不证明算法每帧成功。FAILED_DRAINED1须合法非0reason、mask含首次位、flags1…6真，真实前缀不强等；已逻辑提交/物理写事实不擦。CANCELLED_DRAINED2仅首次cancel且reason10，已有故障则FAILED，cancel_seen真；相同真实关闭/返还义务。QUARANTINE3须drained0，未知KEY/ref/pin/effect债保留，先履约本地已经published消息才冻结Q通知；消费Q不释放、不重新OPEN。

实际明确OPEN拒绝、尚无PC绑定/任何raw请求/对象pin的never_started失败例外：bound与close_proved均0，四ledger/seq-valid为0，localempty/childquiet/无私有refs/无borrow/drained由真实absence成立，不等待不存在的CLOSE。wrong OPEN_ACK或失联不能当此例外，绑定未知进入Q；队列安静也不证明never_started。

reason6本地namespace：0NONE/1DESCRIPTOR/2RANGE/3PERMISSION/4LINK/5BACKEND/6PARTIAL/7UNKNOWN/8PROTOCOL/9CLOSE/10CANCEL/11OVERFLOW/12EXHAUSTED/13TIMEOUT/14RESET_ISOLATION/15CAPACITY；16…63非法，mask32 bitj对应非0原因j，高16…31及bit0零。首次原因/定位证据在发生沿锁，后续mask OR；同沿优先授权/范围→raw协议→raw失败→close错误→cancel。上游typed错误用明确adapter映射，不把本码blindcast为R4C reason5、RC reason6或R3 reason8。

FIRST_ERR930=valid1/origin3/first_reason6/expected_KEY195/raw_evidence725，A唯一writer，第一次故障沿锁原证据且之后不覆盖。origin0授权/descriptor、1RAW_RSP、2timer/link、3CLOSE_ACK、4OPEN_ACK、5CANCEL、6internal、7非法；无raw expected时KEY全0，不将这个0伪解释成合法request；证据低位存原body，其余zero，不适用全0。first_reason用本namespace，raw_evidence可保留对方非法编码/错KEY，不据它清credit。原first保存直到TERM及此观察真实发送后才可退役S；channel7通知同一S只一次，不覆盖其他错误。容器不是PC日志替代，第二/后续故障仅mask/真实ledger继续。

### D5. 对象目录、原子journal与容量

外部array=67,108,864B（64MiB），不是Ti60 RAM。保守当前实例：R4R 17,526,269 +GRAD8,294,400 +SRC6,220,800 +EDGE259,200=32,300,669；再CLASS518,400、QUEUE8,294,400=41,113,469B，EDGE只一次。不按不同阶段偷做尚未证明的alias，不在成功时丢POINT/候选。single slot没有第二完整SRC/ANN；旧image仍借用则阻新BUILD。

候选地址管理：保留[0,65536)为guard/无普通raw权限；最多64个独立对象，各base64byte对齐，尾按真实byte capacity而不是允许访问pad。当前保守数据＋最坏64×63对齐＋一个PROFILE128B＋guard=41,183,165B，余25,925,699B。历史profile、多aux/fixture、内部host metadata不自动免费占此余额；实际分配ledger逐项列出，超过arena或64descriptor/pin明确CAPACITY，不默开第二数组。ROW480B/FONT/R3不计入PC数组而留FPGA，目录表属于FPGAmetadata。

descriptor640低到高：ref64/version64/JID96/object_kind8/base26/byte_capacity27/record_bits10/item_capacity22/valid_count22/lifecycle3/immutable1/owner_role4/read_pin_count16/write_pin1/commit64/zero212=640。lifecycle0FREE/1BUILD/2INITIALIZED/3COMMITTED/4RETIRING/5INVALID/6Q、7非法；canonical全零FREE不产生有效ref。descriptor唯一O写，512×20bit的四RAM10候选保存64×640=40960bit；读一descriptor串行32个20bit word，无64路并行mux承诺。

pin512低到高：ref64/version64/clientH160/role4/grant64/access2/borrow_id64/epoch32/active1/zero57=512。64pin=32768bit，四个native16bit RAM10候选；每个实际holder有真实记录/返还，read_pin_count不是代替这些记录的证明。role0NONE、1SOURCE、2LOAD、3CLOSURE、4GRAD、5RECOGNITION、6COMPLETE_OWNER、7REPLAY、8PROFILE，其余非法；按role解释clientH160，与既有不同身份族的适配B02，不能凭同宽cast。writer排他、read only committed版本、stage资格及retire需真实全部pins/borrow/held返还。表满是实际工程容量错误，不是新增目标/场景上限。

journal576低到高：address26/length7/postimage512/physical_state2/cause6/zero23。16entry=9216bit，按29×20bit word/entry实际9280bit，可候选一个RAM10；group metadata（typed KEY/role/version、logical_commit、tail前后/count、entry_count5、dirty/completed16）另列FF。v0.2额外明确每entry的published1/settled1/effect2/written7，共16×11=176bit FF，保留真实写入事实；单serialized未结raw KEY仍由A的expected/effect_debt保存，不隐含16路并发KEY。physical_state0EMPTY/1PREPARED/2SUCCESS/3FAILED，UNKNOWN以cause及effect_debt保存；prepared bytes高padding0。最多16个被保护postimage，不能接受第17个effect组；各原op上界见E4，超界是控制设计错误而非“先做16项后成功”。

原子可见在FPGA的一个LOGICAL_COMMIT事件：所有postimage及queue slot容量/授权已保留，state+queue+tail或全部16vote新值一起在受保护journal/本地metadata可见。后端byte写随后可分多次；凡查同addr先forward journal最新版本，不能读PC旧bytes。单组排他，外部reader没有看到半组的许可；PC可能暂有部分物理bytes，但core不可绕过journal裸读。typed success只在全部raw writes真实成功/无pending之后形成；phase/immutable commit更须dirty全部结清。没有rollback承诺；取消后保留已commit双效果，失败则整个private build无效，不能发布半图。

### D6. 有限缓存与预算

| 容器 | 准确容量/归属 / 候选实现 |
|---|---|
| PC arena | 64MiB byte array；PC单请求，read复制≤64B/WRITE保存≤64B，新配临时buffer不可无限；未初始化对象资格由FPGA管理 |
| O descriptor / pin | 64×640、64×512；候选4+4 RAM10，本地descriptor读回640bit register及pin512bit register另列 |
| S journal | 16×576 logical/16×580 physical，1RAM10候选；当前old byte512、group metadata及typed expected最长799bit另列，不放PC |
| L packet buffers | TX data、TX close、TX CORE、RX data、RX close各256B；RX ring256B，共1536B=12288bit；候选2个native16 RAM10，空间分配/1R1W仲裁另局部冻结，不假称一个8bit模式RAM能容纳全部 |
| K CORE观察 | 八body槽合8004bit＋每槽S96/seq64/part_index8/part_count8/total_bits12/valid1=9516bit，另8×65bit nextseq/exhausted；候选FF。FIRST_ERR原930bit保存也有A owner，镜像副本不可默删；每channel一槽，OUT每pair真实可暂停，状态槽空才准入下个会覆盖它的job/plan |
| A per-client槽 | 8×请求最长799bit、8×回复最长872bit；8×(799+872)=13368bit候选FF；unused highzero，原口独立held。旧full当沿pop不接新请求 |
| A/raw单槽 | RQ707、RSP725、expectedKEY195/credit1、effect_debt KEY195/valid1、C231/ACK442/T469、CANCEL96/ACK104、四64ledger/flags等；各独立位置，不默认alias删槽 |
| L配置/状态 | OPEN256/ACK328、CRC32、RX/TX≤256 byte pointer9、frame count8/length16、UART bit4/divider16、deadline48、各packet/error计数64，明确单owner |
| 原算法局部 | R2窗口28RAM候选、R3自己的ROM/数值容器、ANN ROW480B/FONT1RAM等按原合同仍真实存在；本11RAM候选不能冒充全机预算 |

本层metadata/journal/packet合计候选11RAM10，来自目录4＋pin4＋journal1＋packet2；DSP不新增承诺为0（address扩乘/packing可串行逻辑，实际综合另核），XLR/FF总量仍需完整控制器/CRC/仲裁与core合并后冻结。各RAM1R1W实际native modes/packing端口由局部稿与原资源证据核实；表格是候选可容纳组织，不是综合网表实测。

### D7. serial packet合同与期限

候选wire frame：byte0 A5、byte1 5A、byte2 schema1、byte3 type8、byte4/5 body_length16低byte先、随后固定body bytes、末4byte CRC32低byte先。body消息取最低8bit为第一byte，最后不足8bit高padding0；field整体位序仍D2。CRC polynomial04C11DB7、initFFFFFFFF、final XORFFFFFFFF，按schema/type/length低高/全部body bytes的发送顺序，每byte bit7→0输入，不含magic/CRC；UART每字节LSB first与CRC bit order不同。CRC字节序/高padding/所有body exact length为协议规则，不能用库默认CRC32代替。

type1OPEN32B、2OPEN_ACK41B、3RQ89B、4RSP91B、5CLOSE29B、6CLOSE_ACK56B、7TERM59B、8CORE_RECORD88B；其余非法。FPGA→PC只1/3/5/7/8，PC→FPGA只2/4/6，错方向也是协议错误。最长101B（6header+91body+4CRC），每个256B槽有边界余量。serial TERM只是观察原FPGA T469，不让PC形成其字段。header长度必须等该type固定值再读body，不能由坏length分配巨大buffer。有限parser重同步、UART framing错误和CRC错误都显式sticky；schema/CRC检查完成前不生成任何PC memory effect。新RX/TX必须自写可保持/error接口，原demo仅引脚/clock事实参考。

CORE699固定分段：按IF10已知channel宽度求total_bytes=ceil(bits/8)、part_count=ceil(total_bytes/64)（1…6），低byte先，除末段valid_bytes64、末段为真实余数；最后一byte原body未用高bit0，payload超valid_bytes及CORE699最高5bit padding0。每channel nextseq64独立不回绕；capture锁原body/S/seq不在该沿shift，后续旧FULL取固定低512bit形成当前段packet，实际一个完整packet发送结束后才右移512并推进index，无巨型变量索引payload mux。PC只重组/保存报告bytes，不据报告生成算法结果。CS等状态镜像取父的真实既有消费事件，父预留K槽并核不覆盖旧body，不引入第二CSconsumer；OUT404以K ready实际接纳并与镜像状态分开。下个job/plan会用同状态槽时需它真实空，不能丢观察通知。

TX每packet不可插字节；已发packet完成后，独立CLOSE优先（但不能越过尚未发送的旧RQ packet），DATA与CORE在非关闭状态按轮转一packet公平发送，最长已有101B packet会阻挡当前选择但不无限饿死。fatal close停尚未published的新ordinary像素/算法记录；旧published CORE/OUT和关闭过程中新真实child终态通知仍必须接纳/发送，状态槽不能用raw CLOSE门控，否则childquiet与状态观察会成环。K的status预留在job/plan准入时检查；channel6 FINAL512镜像只能来自S真实完整FINAL write effect后保留的record与明确owner，具体适配B01，不能对未实现记录流自造valid。它们只持有原body拷贝，O真实borrow返还仍由原owner。raw_local_empty包括这些旧观察槽/packet已实际发送，不包括尚未形成的本次T469自身通知；T469发送完及原TERM真实消费后才允许新OPEN/epoch，不能用冷清空槽掩旧wire义务。完整render RGB404经此真实串口输出，防止仅raw地址请求扇出使灰度/选色逻辑被裁剪。

children_quiet只核本arena的typed算法/provider/VIEW子义务，不等待当前RAW_TERM本身或其父先消费RAW_TERM；本通知及发送槽为独立末级义务。TX close/control256B可在C231完整发送及相应close事务不再占TX存储后给T469复用，身份保留至T发送结束；RX ACK独立。SOURCE/job/UI/config动态准入还需B02/B04的新完整driver接口，不能把未连的branch常量化后声称全core防裁剪已完成。

本版本不自动重发：packet duplicate在当前S也是protocol fault，不能再次WRITE或从缓存猜成功；没有收到请求的PC不会补accepted，截止不一致进入Q。为未来增加idempotent retransmit须另设计完整REQ/RESP缓存、seq证明/ACK计数，不能把timeout再发视为内部无变化优化。丢字节/USB断开导致失败/Q是可观察功能失败，不是结果正常成功。

PC仅在FPGA请求后发一RSP；全arena停止时先该RSP、后CLOSE_ACK。不在同一UART并发telemetry/fixture流。RX ring与两个独立回复槽足够协议内最大data+close burst；host违反窗口/full造成明确LINK/CAPACITY及Q，不能靠无限PC→FPGA流量假设有限FIFO可lossless。UART不能靠ready停线，A可以暂停广域请求，PC软件须遵守发送窗口。

候选期限按OPEN锁一次：27MHz data_deadline=270000000tick（10s），close_deadline同值；每raw RQfire/close fire分别计48bit非回绕计时，等待wide本地consumer ready不计为PC service迟到（响应完整capture即可停源期限）。RX interbyte期限提议54000000tick（2s），完整frame有限101B，最终HOST/USB/FT环境与套件B03须核。期限到只提出correct KEY的本地LINK/TIMEOUT unknown-effect response（settled0），不伪造PC关闭或WRITE没发生。timer response一旦published后晚wire reply只作保留证据，不改原held body；pending效果由独立CLOSE/恢复处理。永久本域notready保持，不能用期限清旧held。整体算法wall/cycle期限要按全部passes/实际raw延迟另冻结B05。

带宽仅理想尺度：8N1按nominal115200计算11520wire B/s，完整RQ99B+RSP101B stop-and-wait，每64B READ至少200wire bytes，未计PC/CRC/处理停顿，理想有效3686.4B/s。单读SRC6,220,800B至少1687.5s（28.125min），一次POINT最大读16,588,800B至少4500s（75min）；许多小RMW更慢。不能宣称实时/完整1080p串口验证快速完成，实际serial fullframe执行策略/替代更快raw transport与质量性能方案仍OPEN；本域仿真快raw服务可验证全部RTL算法，但不替代上述串口物理带宽证据。

### D8. pin/clock/STA与防裁剪

候选参考V4 uart输入rxd=R4/GPIOL_02、3.3V弱上拉，输出txd=R14/GPIOR_28、3.3V drive8；工具bank BL/BR，不沿用手册TR文字。clock27MHz=H2/GPIOL_P_10，原peri为1.8V输入gclk，不把UART3.3V复制到clock。实体未到货，pin是经参考及工具数据库核对的候选而非人工硬件确认；新工程/I3速度及实际板资料必须一致。原reset绑定/FIFO缺full处理/旧SDC不得继承。

本候选全部算法、raw目录/serial共core27MHz，无CORE100↔UART27 CDC；外部rxd异步必须至少两级同步、只由后级采样新UART状态。若整包选100MHz或另域，须新完整CDC/reset/baud计时及SDC设计，不照搬本单域假设。27M周期1000/27≈37.037037ns；全core实际setup/hold、同步器第一段窄例外、TX output约束及pad注册层需新局部SDC计划，不在此生成SDC，也不以旧clk_50m delay或全port false_path规避时序。

网表完整性：真实RGBbytes经raw端口→全部算法/数值/atomic controllers→最终EDGE/ANN/RECORD/STATUS→真实serial输出，输入与job/profile动态可变，各branch成果影响完整消息/输出。必须报告所有core层hierarchy、保留cell/net、fullwidth动态数据及实际resource/clock/pin/PNR/STA/bit；不以keep属性、常量pattern、虚拟宽I/O、仅LED/CRC小top、host先算结果或blackbox替代完整core。PC物理服务/相机/HDMI实机仍不作本轮bit后证明。

## E. 局部中文操作草图

### E1. OPEN、初始化与权限

1. CONTROL授权owner先确认旧epoch所有CORE/VIEW/borrow/O及wire义务确实关闭；为本arena分配新S96。cold bootstrap不凭输入S不同丢旧债。捕获OPEN只存ctx，之后按schema/capacity/期限检查，再实际发packet/等待正确ACK。
2. PC实际分配唯一64MiB，不开启第二frame array；服务元数据/copy buffer独立有限，不扫描对象格式。OPEN_ACK只是可存字节，不能造SRC/profile/CLASS合法flag。
3. O分配ref/version/实际对象span与pins；SOURCE fixture bootstrap只在明确专属writer和零active reader阶段纯复制原RGB/profile bytes，之后禁止PC私自改SRC。具体bootstrap消息/完整SRC准入仍B02，不能在本页虚构已安装。
4. FPGA完整SOURCE/GRAD/CLASS控制器验证全覆盖/canonical/snapshot并生成其真实commit；mutable bitpacked表CLEAR逐byte完成后才允许RMW。读取valid_count外/未初始化对象拒绝，不将旧PCbytes当本run零。

### E2. raw读取、写入与仲裁

1. A选最早轮转可服务client，锁原typed KEY/role/version；O串行lookup实际descriptor及pin，给内部permit/span。遇无资格只形成typed明确failure，不提raw RQ。
2. packed item边界用宽index运算/first_bit，必要RMW保留邻居bits；raw opcode/addr/len/payload在提出前全部canonical。RQ published消耗raw_seq，fire建expected；同沿新取消先记旧fire。
3. L保存完整RQ，之后形成完整packet/CRC/TX；PC完整收到且所有检查合法才计accepted并读/写bytes。RAWREAD复制实际有限slice，高unused归零；RAWWRITE只有全部复制完成才success，不修改rawseq/body。
4. FPGA完整RSP fire存独立槽，后续旧VALIDATE核KEY/语义，然后S应用record或失败。应用也不能在末rspfire同沿让下一request穿透；typed/raw两种台账分别真实推进。

### E3. directory、提交和归还

O单writer串行读/改descriptor/pin，在同一受保护ctx形成一致新metadata后才发grant/返回ACK。ALLOC需FREE槽、合法capacity且arena不overlap，generation/version空间可分配；权限只从真实parent/source/job授权衍生。ACQUIRE读需COMMITTED immutable与完全同ref/version，写需当前BUILD独占/正确role与stage。允许读取自身最新mutable时须经过S/journal，不能发raw裸读绕过phase。

COMMIT只能S实际核initialized/全覆盖/padding/所有group/raw debt0/dirty0后通知O，O冻结真实version并分配非0token；PC从不认识commit_token。RETURN匹配真实pin grant/clientH/role/ref/version，错误echo不减引用；RETIRE须所有pins/borrow/held/copy/NUM义务真空，再使descriptor INVALID/FREE而不靠session close清count。已成功commit事实取消后保留，但失去本失败job发布资格。VIEW private_refs_retired只能O实际清单证据，raw CLOSE与S close都不能代替。

目录内部命令/完整source/config/profile/history/RECORD aux wire body还须B01/B02，本文AR/AP仅raw byte授权候选，不能伪装完整VIEW目录已经实现。

### E4. claim与DENSE原子组

CLAIM_APPEND：先核旧CLASS期望01或10、当前tail<N、QUEUE entry授权及两span实际范围；保留journal两个postimage（CLASS1byte、QUEUE4byte）和tail前后。CLASS值从最新forward或合法raw bytes得到，保留该byte其他pixels；queue coord canonical32bit。两postimage全部PREPARED后一个旧LOGICAL_COMMIT沿一起公开CLASS11/QUEUE[tail]/tail+1。之后串行两raw writes；全部success再typed claim成功。预commit检查失败无新logical效果；postcommit取消/部分write失败不得只回滚一半，保留journal/事实，整个build失败至真实关闭。

DENSE_ADD16：原RQ的batch/POINT ordinal/16rho由FPGA校验；16个票目标index由受限本地游标产生，每条21bit旧count从latest值取、先22bit加1核≤E及uint21。最多16个≤4byte postimage，跨相同byte时必须合并同地址最新bits而不能重复覆盖旧读；本当前θ排列通常不同范围，但合并保证不省。全部journal slots/计数PREPARED才一事件公开16新值；后续最多16raw writes，任一失败不返回组success。PC永远不接DENSE opcode。

普通512bit fullbyte record WRITE仅一个≤64byte postimage；bitpacked RECORD RMW沿用同框架。CLEAR可多个独立raw chunks，whole-table initialized/SEAL只最后结算后成立，不声称整个容量原子更新。source/phase commit为FPGAmetadata屏障，须本角色全部dirty/writeback/recordpending无债；无需让PC算class强弱或“确认固定点”。

最小逐沿：e0 typed fire锁ctx；e1以后AUTH/RESERVE；各rawREADfire及RSPvalidation间多沿/任意有限stall；eK旧allprepared LOGICAL_COMMIT；eK+1后逐rawWRITE；末RSPfire先记effects，后续旧all_settled形成typed RSP。正常成功仅在所有entry真实SUCCESS/settled、无expected/effect_debt/pending或held引用、typed RSP已实际消费后，在后续旧空沿释放journal。任何并发cancel先记旧commit/fire、后续STOPPING不新生成组。不是硬件固定Kcycle性能承诺。

postcommit失败/取消的独立分支：立刻将该private BUILD置INVALID并禁止全部新业务读写/phase成功commit/发布，不回滚logical_commit、CLASS/QUEUE/tail或16票事实。所有已published raw请求继续履约；未published的PREPARED后缀停发并记录never-published处分，不能标SUCCESS或已物理写入。保留全部postimage/latest和每entry真实效果，失败typed RSP的消费本身不释放journal。INVALID_SETTLE可独立推进raw CLOSE而不等待O退休；正确close证明及raw本地expected/effect_debt/已published消息/pending真实结清后，只登记已published项没有未来effects的真实关闭事实，并将未published项的logical obligation明确作为INVALID失败处分。raw CLOSE不提供未知写的最终prefix：原effect=UNKNOWN、written=0、cause和首次证据保持未知，不能补成SUCCESS/FULL/猜测前缀；独立entry.settled仅表示source实际关闭，绝不改写旧RSP或增加success计数。此时整组已无任何未来读写，typed失败回复已消费、S内部对postimage的读写权限/held数据/RAM pending和引用实际结束后，后续沿才可退休journal，保留冻结logical_commit、已知前缀及未知事实的终态记录。这一本地借用空不等待父O对象退休或本组typed CLOSE_ACK消费，后者只能引用独立冻结的台账/终态字段，不能继续借journal；这样不等private O退休即可给typed CLOSE真settled证据，O随后按真实pin/返还退对象。没有clear-to-IDLE的成功恢复。wrong/missing close或UNKNOWN未来effects未证关闭时进入Q，保留journal/raw KEY/ref/pin，不假定failure RSP或rst能退它们。

### E5. phase与provider

LOAD_PAIR/CLASS_COMMIT真实统计在FPGA；GENERAL closure严格原8邻域/非环N queue/安全快路径，全N EDGE export；PC不走queue或找strong。RC所有POINT、LS/TLS、coverage/dedup/ANN在FPGA，所有R3 calls使用现行622/585单caller；PC不生成角度或fit。

immutable SRC/EDGE/ANN provider核O已给borrow/ref/version/JID和该plane完整token，再读取raw canonicalbytes拼两lane，保留原source/display/plan身份；真实outputfire才推进本地cursor。mode0访问偶行两遍仍由REPLAY计划，raw random access支持，不以lineFIFO创造回放。RGB/edge/ANN各独立held，A仲裁有公平轮转，不能用live RGB tap阻FE窗口。provider释放与REPLAY CLOSE/RELEASE真实证书按原族，不拿global raw关闭当自动归还。

### E6. 失败、取消与未知

known RSP failure已经settled1仍使当前typed group失败；此前完整logical effects保留，局部raw span未成功不形成typedsuccess。unknown/坏echo锁首次原因和raw KEY，停止所有client新ordinary请求，effect_debt/journal/ref保存。取消不撤old typed/RQ/TXpacket/RSP/TERM；未published的本地候选可丢，但不能擦logicalcommit。

S/父发close不等semanticcredit先清。L兑现已经published packet→锁cutoff→sendCLOSE，PC只结束自己effects/旧response→ACK；A独立ready接ACK并后续核actual source ledger。匹配真实failed-close证书允许结债并FAILED_DRAINED，但原算法结果不再发布。missing/wrong proof保持Q，不超时freeref，不恢复wholearena ACTIVE。晚packet只诊断保留，不改已经published终态。

### E7. 同沿和复位

例：raw WRITE RSPfire与cancel同沿，合法bytes效果/成功prefix记录一次，下一旧ABORT不新提下一group；cancel与最后typed phase commit同沿保留实际token但不发布frame。raw CLOSE_ACK与最后datafire同沿仅缓存ACK，下一旧dataempty才验证。新softwareepoch事件与旧Q/held出现时不能通过；配置同沿OPEN/job用旧冻结版本，当前期限/baud不动态换。未published TERM时，当沿新cancel/错误或新形成CANCEL_ACK会阻止TERM冻结，先实际处理/排空控制回执；一旦TERMpublished，晚匹配cancel只ALREADY，不变body。CANCEL/ACK真实消费并后续旧空才允许退役S/新OPEN，不能从ALREADY receipt推断source已关闭。

共同cold rst在core高有效同步，fire0；UART tx idle1、RX同步/packet有效性隔离，PC服务必须关闭/共同重建旧S，未经证据不以rst清64MiB或credit。外部rxd异步仅同步器第一段窄例外。software reset区分两条实际路径：raw仍健康且各typed能够正常停止/settle时，先停新算法、兑现旧承诺、取得子quiet/borrow及private返回，再关闭arena；发生raw故障、unknown effect或子quiet依赖raw proof时，先停新普通业务并兑现旧published RQ/packet，再独立提出raw CLOSE/接正确ACK，与typed close收尾并行推进，不能等待子quiet才发raw CLOSE。真实raw proof和INVALID_SETTLE结束后才能收typed quiet→真实borrow/private返回→本arena T/观察通知全部消费→CONTROL授权→新S；任何Q不进入新S。两路seq/ref/grant持久exhausted均不软件复位。RESET/COM重连与认证恢复完整端口仍B02/B03。

### E8. 软件人工操作草图（未来实施，当前不执行）

先读整包指定成熟版与批准基线→选择full1080p原RGB/profile/独立GT fixture manifest→按已批准bootstrap只复制原bytes，不预计算CLASS/POINT/候选→开唯一64MiB service/核COM与新8N1→core OPEN/身份/容量回读→触发真实job→查看typed/raw分层实际ledger、完整geom/ANN/record与fail reason→独立黄金比对全N及质量→取消/停止时实际CLOSE和私有返回→保存完整结果/日志/hash。不要从PC预画标注让core只“转发成功”。物理下载/观察及bit后操作当前不执行。

## F. 语言、映射与资源契约

C++未选，实际工具/标准未核，不输出实现。未来PC byte service可考虑既有Python标准库bytearray，固定64MiB、单线程/单operator、有限buffer、按请求顺序；语义为原始bytes，边界检查和异常不能生成算法结果。slice read是独立≤64B快照，WRITE完整效果后应答；异常保存实际已知prefix或UNKNOWN，不用host自动resize允许越界，不用host释放array当目录已退休。实际安装/软件依赖按原批准流程，当前不生成。

| RTL A–L | 本任务合同 |
|---|---|
| A 数值 | D2 body及D3 signed-free地址/index；42/43bit运算、27bitend、uint64临时65、generation58不回绕；BYTE BITPACK/padding一位不能糊 |
| B 时钟/观察 | 单域core27M候选沿前fire；capture→后续校验→应用，不同沿透传；未来TB下降沿drive/沿后稳定观察 |
| C 接受/交付 | raw/typed/PCpacket三种accepted不相混；raw_RQfire不等PC已收到，更不等WRITE完成；CLOSE/TERM独立 |
| D valid/推进 | data0合法，valid0不计数/寻址；初始化/whole-table CLEAR有actual coverage；消息slot/cursor只真实事件 |
| E 反压/保持 | 每口完整body/KEY/profile保持，已published不能取消；UART线无ready所以窗口有限，满显式失败 |
| F 延迟/吞吐 | journal/ROM/目录RAM串行调度、rawrequest每≤64B、PC有限期限，D7低速数字只是理论；原100M算法性能不当27M实测 |
| G 复位 | common合法cold reset隔离旧S；软件reset真实关闭/目录还债，unknown不reset掉；大array不推片上reset |
| H 配置 | OPEN锁容量/期限/schema，job/profile/history仍原owner；同沿提交用旧快照，baud改变须停/关闭后新session |
| I 存储 | PC64MiB实际byte array/单slot；FPGA11RAM候选metadata/journal/packets及有限FF；1R1W/packing/latest不凭表格当证据 |
| J 身份 | S/rawseq/ref/grant/typedH/NUM/JID/borrow分族；bytes→原pixelrecord→pair拼接严格lane/xy，rawaddr非payloadxy |
| K CDC | UART rxd异步两级同步，内部本候选同域；改CORE100/UART27须新CDC/FIFO/reset设计，不自动异步多bit |
| L 实现 | Ti60F225 SV2009候选，新写UART而非复制有许可/握手缺口demo；actualclock/speed/pin/STA/PNR/bit全NOT_RUN，B04尚OPEN |

三份独立映射：①数学参考从原image/profile独立做完整算法/GT，不从DUT候选日志造黄金；memory model不求算法。②硬件执行参考从各真实typed/raw/PC接纳与效果fire分别建ledger，核journal logicalcommit、rawwrite、phase、close/returned，算法函数结束不能替副作用结算。③PCbytes按exactpacking与raw请求对应，软件输出记录与POINT/geom/ANN/fullN逐位比较；模拟partial/UNKNOWN/错echo检查真实prefix，Q不能通过销毁hostarray解除。CRC是传输校验，不是数学oracle或闭包固定点证明。

## G. 实施与验证计划（全NOT_RUN）

先冻结A2局部控制/目录/serial/全core组合，源hash及文件schema/GT计划成熟并独立审阅，纳入指定整包READY与明确批准；获批后增量为directory/byte授权→raw读写→typed journal/claim/DENSE→immutable provider→packet/UART→全core工程/防裁剪→full1080p软件与pin/STA/PNR/bit。当前不生成这些计划文件、脚本、模型、TB、工程或SDC。

| TEST | REQ / IF / 输入与事件 | 期望来源、方法/观察与失败条件 |
|---|---|---|
| RAW-T01 | REQ01/02；64MiB/41,113,469数据，guard、最后byte/end=2^26、len0/65、overlap | 独立容量/宽地址算术；非法在raw fire前拒；全capacity/64descriptor满明确失败，不resize/第二frame |
| T02 | REQ03；21bititem跨byte/64boundary、ANN2/EDGE1、512record、末padding | 独立byte打包/解包与邻位canary，exactbyte/padding；不得用recordceil乘改变旧容量 |
| T03 | REQ03/06；ref/version/role/grant错、未初始化读、immutable写、wrong RETURN | O真实pin账本；无grant不访问，错回不减refcount，旧地址重用不认旧ref |
| T04 | REQ03/05；每RQ/RSP held、valid0/bubble/oldfull+pop、capturefire同沿 | 沿前独立fire计数，各prefix不强等；body保持，invalid不寻址/计数，新消息不穿透 |
| T05 | REQ04；CLAIM两postimage/QUEUE最后entry、samebyte两pixels、postcommit cancel/第二write失败 | independent graph＋journal实际事件，state/queue/tail成对可见、latest不丢邻位；失败无EDGE发布 |
| T06 | REQ04；DENSE16重复物理byte、16slot满、第17effect、count=E/uint21边界 | 16新值原子/计数22bit检查、物理RMW保邻位；oldwrite未知则Q，PC不能代increment |
| T07 | REQ04/05；CLEAR最后chunk/phase commit/padding与rawwritepending | wholeinitialized/phase/token不能早于所有effects；partial clear不读洞/不commit |
| T08 | REQ05；known NONE/PARTIAL/FULL、UNKNOWN、错KEY/非法RSP、高padding | 合法失败不同物理事实保留；UNKNOWN effectdebt不清，wrongkey不结expected，独立prefix/close |
| T09 | REQ05；raw lost request PCaccepted=cutoff−1、RSP旧held、ACK早到、wrongCLOSE | accepted mismatch Q不补；CLOSE不等待猜credit；旧RSP先fire、后旧empty核ACK，无close/data环 |
| T10 | REQ06；CL/RC close冒borrow返回、POINT私有commit、RECORD aux缺失 | 真实O记录/CERT352/不同pin证书，不以rawclose造private_refs_retired，完整bundle缺项拒 |
| T11 | REQ07；seq/ref/grant/session最大合法后下一次、softreset旧Q、输入新epoch同沿 | 不回绕/持久exhausted，授权epoch桥必要；Q held/ref保留，不靠reset销数组过关 |
| T12 | REQ08；magic内同字节、headerlength坏/CRC坏/byte掉/dup/USB断、ring满/line错误 | 独立逐bit CRC/packet期望，未验证不mem effect；LINK/UNKNOWN/Q可观察，旧held不抹，no auto replay |
| T13 | REQ08；RSP+ACK最大burst、rx不可暂停、TX/data/close槽/consumer慢 | 协议内有限容器不丢，独立回复槽；违反窗口明确full/错误，不无限FIFO或静默丢 |
| T14 | REQ08；UART原8N1.5与新8N1、divider234、27M计时/timeout、rxd同步 | 时间/byte完整独立参考及真实sourceclock；baud正确实例，无借旧SDC/clk_50m或整域falsepath |
| T15 | REQ01/08；full1080p原RGB→全部RTL→真EDGE/geom/ANN/record，两类GT/overlap/negative | memory service仅bytes；独立数学/协议/质量三份；不得host预算point/graph/fit或以小图替fullN |
| T16 | REQ08；全core动态job/profile/raw input、不用常量stub、实际Ti60 pin/clock | 获批后完整hierarchy/resource/fanout/网表/PNR/STA/bit独立报告；所有branch真实保留且无missingpath，CRC/LED小top不代 |
| T17 | REQ06/07；旧VIEW借用→新BUILD、私有refs退休/allpins、整体停止及unknown debt reset | 同一slot不能覆盖旧图/另开frame；健康childquiet→returns→rawclose，故障rawclose独立先推进→journal结算→childquiet/returns→epoch，不形成quiet/close环 |
| T18 | REQ05；cancel与logicalcommit/rawfire/末typedcommit/ACK/TERM逐项同沿 | 旧事实先登记，发布TERM保持，晚cancel不擦旧交付；failed prefix不能当完整成功 |

每项未来设置有限seed/cycle/wall/PC服务期限并冻结manifest/hash，全部当前NOT_RUN。实际serial高延迟不能拿fast raw仿真的吞吐冒充；full1080p软件reference与actualRTL计算都要比较，100MHz理想与27M/115200物理试验分别报告。下载/观察及bit后步骤本测试不执行。

## H. 双向追踪

| REQ/来源 | MOD / IF / OP、不变量 | 计划稳定职责（未生成） | TEST / 证据 |
|---|---|---|---|
| REQ01 / 用户、BATCH、R4C/R4R | CORE/S/P；IF01/03；E4/E5；PC only bytes | core_raw_boundary / byte_only_service_contract | T05/06/15；独立math/GT与完整hierarchy，NOT_RUN |
| REQ02 / 完整N逻辑容量 | O/A；D5/6；E1/E3；单slot/nooverlap | object_arena_allocator / capacity_ledger | T01/17；静态算术非RAM实测 |
| REQ03 / typed packing与授权 | O/A/L；IF02/03；E2；wide address/highzero/valid | byte_span_authorizer / packed_record_adapter | T02/03/04/08；接口byte黄金，未实现 |
| REQ04 / 精确claim/票 | S；E4；reserve→logicalcommit→writeback | state_queue_atomic_controller / dense16_atomic_controller / latest_journal | T05/06/07/18；真实atomic参考，局部B01 OPEN |
| REQ05 / 真收尾 | A/S/L/P；IF07/08；E6/E7；oldfire/credit/effectdebt | raw_close_ledger / effect_debt / terminal_controller | T08/09/18；no false equality/Q，未实现 |
| REQ06 / VIEW/private/borrow | O/providers；IF06/09；E3/E5；权限与实际returns | immutable_plane_provider / pin_return / retirement_adapter | T10/17；VIEW352/原REPLAY相容，B02 OPEN |
| REQ07 / CONTROL授权epoch | 父/O/A/L；D1/E7；持久seq/exhausted | arena_epoch_authority / generation_allocator | T11/17；实际跨稿桥OPEN |
| REQ08 / Efinity与实际serial | L/全CORE；IF04/05；D7/8/F | bounded_packet_uart / core_preservation / project_constraint_plan | T12…16；UART只读fact/当前工具NOT_RUN |

反向核每个计划单元仅服务原algorithm、授权/存储语义、真实通信或独立验证；PC byte服务不含任何候选/投票/graph/fit/ANN算法模块。获批后源码/中文注释/实际文件/符号/波形/退出码/report/hash再填写，不将计划名称冒充已有实现。结构/transport/profile选择改变须同步REQ→IF→OP→TEST及父组合。

## I. 门槛、审批与呈现

①B整体/样例；②C职责及原UART只读调查；③D本域完整候选body/相容检查但A2未全闭；④E状态/中文操作；⑤F三份映射；⑥普通/满/失败/取消走查；⑦G/H场景及trace；⑧有当前真实设计缺口不满足；⑨本文保存/实际全文读回另报告；⑩版本/范围/hash明确。

仍LOCAL_DESIGN/NOT_READY/UNAPPROVED/NOT_RUN；未READY，不批准实现。根代理只授权本文件创建/读回，并未取得用户明确成熟设计版本、范围、基线的业务实施批准。Approval Manifest/数据库未登记，原工作副本/编译/额外工具及人工硬件闸门继续。允许下一步是纯设计独立审阅并形成atomic/目录/serial/全core局部合并，不生成代码。

## J. 变更与恢复

旧R4C/R4R把逻辑S与真实backend保持OPEN；本稿明确其算法与目录控制在FPGA，external只有canonical bytes，并给64MiB/单credit/有限journal/真实UART分层候选。没有把原DENSE_ADD/CLAIM接口原样送PC，不继承旧物理DDR消息；64MiB与低速UART为提议，不修改用户场景或已有P/R95/IoU0.5、full1080p。v0.2按根实际全文读取及独立复审交接修订E4失败组退休、D5效果metadata与E7/T17故障reset次序；原v0.1保留，修订独立复核未完成。它没有关闭RAW-B01…06或授权实现。

相对原demo新设计需lossless-window/error/holding/reset/CRC与合理新约束，不能copy历史pass。若增加重发、并发credit、alias、第二帧、PC原子/算法计算、更高baud/独立clock或变更commit/owner，先改本稿及相关局部/trace、读回/独立审阅与批准边界。恢复先核最新hash/实际授权、raw KEY/debt与所有O pins/borrow，Q不自行归零。

## K. 实施与验证实录

本轮只读控制面/规则/候选算法/UART参考及纯文档字段/容量分析，授权只创建本文。无业务RTL/C++/功能Python、模型/脚本/生成器、TB/可执行测试、工程/SDC。未运行仿真/综合/PNR/STA/bit/serial/硬件，没有网络/安装/设备连接、指定DDR器件调查；其他文件/规则/正式状态/Manifest/数据库未修改。

static数学：KEY195/RQ707/RSP725/OPEN256/ACK328/C231/ACK442/T469、AR348/AP466、desc640/pin512/journal576；PC容量与11RAM候选不是实际utilization，不宣称已完成raw provider或完整生产系统。作者自查不称独立审阅，理解验收待用户实际反馈。

## L. 交付与阅读顺序

整包范围→B整体→C算法/存储分层→D1身份→D2端口→D3bytes/effects→D4真实close→D5/6容量/owner/journal→D7/8实际serial与时序→E1…8中文步骤→F三映射→G/H验证与反向追踪→A2/I未决项。

一条完整路径：原RGB/profile数据合法准入→FPGA算法typed request→目录真实授权→journal postimage/原子提交→raw bytes实际读写→typed阶段/全Nimmutablecommit→O/REPLAY借用→raw provider→真实serial像素/记录/终态→真实borrow/private返回→raw close ledger→授权新epoch。PC只copy bytes，不制造计算或闭合证书；失败路径完整保留旧effects而拒发布prefix。

目前交付纯设计候选，完整算法core代码/软件/Efinity综合网表/合理pin/PNR/STA/bit目标未实现。低速serial物理验证与算法数学/软件验证分别列限制；生产摄像、固定HDMI、A3及真实视频/bit后操作不从总需求表删除或冒称完成。改变存储范围看REQ02/D5，改变原子控制看REQ04/E4，改变transport看REQ08/D7/D8；获批后再按实际代码核文档—中文注释—接口—测试一致性。
