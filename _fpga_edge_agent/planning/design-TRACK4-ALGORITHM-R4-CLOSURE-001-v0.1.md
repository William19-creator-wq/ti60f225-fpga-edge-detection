# TRACK4-ALGORITHM-R4-CLOSURE-001：精确Canny闭包与逻辑对象服务设计 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本文是[整包R4](design-TRACK4-ALGORITHM-BATCH-001.md)的闭包/逻辑存储局部候选，尚未提供真实存储后端、片上资源映射或完整bundle实现。

## 通用计划字段

- Goal：从完整R2分类对象得到精确八邻域强种子可达集合，冻结CLASS/QUEUE/EDGE逻辑容量、唯一owner、原子接纳、可见提交、全N导出及错误关闭。
- Current state：BATCH/R2、CONTROL v0.2、REPLAY v0.2及原CANNY纯数值/集合/有限性章节已实际读取；本局部没有业务实现。
- Target state：完整1920×1080分类加载→提交证书→强种子→精确闭包→全部N边缘→独立关闭证书→不可变EDGE交接有可检查合同；后端及父层闭合后纳入整包指定批准。
- Gap：真实backend/逻辑目录与资源映射、R4识别/GRAD提交、原RGB/ANN与完整bundle、跨软件epoch桥、R5生产源/视频/工具及完整文件基线均OPEN。
- Assumptions：单core域、软件接口可暂停；静态W为偶数6…1920、H5…1080，生产1920×1080；有限图坐标，不作环形像素/环形工作队列。环境最终兑现已提出事务是活性前提。
- Open questions：见A。主机数组只是独立软件验证后端候选，不能当Ti60片上RAM；不使用小图、空stub或分类图代替全1080p最终边缘。
- Dependencies：唯一根v0.2、模板、BATCH、R2/C0、CONTROL/REPLAY、原CANNY中明确采用的纯规则；不继承旧917bit job、phase_key、grant或物理存储消息。
- Milestones：整体集合→owner/容量→接口/提交与组合→局部旧沿/关闭→参考/验证/追踪→真实后端及父组合→独立审阅→整包批准→获批实现/工具。
- Detailed steps：B最终行为→C唯一owner→D身份/接口/逻辑容量→E加载/原子提交/种子/BFS/导出/关闭→F语言与三份对应→G/H验证追踪→A/I阻塞。
- State transitions：只在本文记录LOCAL_DESIGN；不改正式H0、Manifest、数据库或任务状态；保存候选不等于READY或实施批准。
- Artifacts and hashes：A列实际来源hash；本文保存后全文读回hash另报，不自引用；当前没有实施源码/Git提交或全包冻结基线。
- Validation：集合数学、实际握手/原子可见性、全图软件结果、资源/综合/PNR/STA各自验证；G全部NOT_RUN。
- Failure handling：先计旧真实fire，保留各自不同前缀；坏回复不能清credit；独立CLOSE不等credit；无真实关闭/返还证据保持隔离，不发布EDGE或复用他人对象。
- Human approval gates：完整设计版本/实现范围/共同基线指定批准；本页NOT_READY，无业务实现授权。工作副本、构建、数据库与人工硬件闸门仍适用。
- Rollback：本轮只创建本文；旧设计/资料/HDK、业务目录、正式状态/数据库保持。未来受影响实现只在获批work中进行。
- Completion criteria：本局部文字/读回/审阅齐全还不能关闭R4/B03/B05；必须取得真实全N后端、对象目录/组合及工具证据，再统一批准。

## A. 状态、实际来源和阅读入口

任务R4C=TRACK4-ALGORITHM-R4-CLOSURE-001，关联BAT-REQ02/04/05/06、T4-A4及后续A6最终EDGE输入。阅读[整包B/C/D](design-TRACK4-ALGORITHM-BATCH-001.md)→[R2](design-TRACK4-ALGORITHM-R2-001.md)→本文B/C/D→E→F/G/H。用户要求停止指定V4存储器件相关工作并继续算法；该指令不取消设计先行规则。当前仅获准创建本设计，不获准生成代码/参考/脚本/TB/工程或跑构建。

| 实际读取来源 | SHA256及采用范围 |
|---|---|
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；整体先于局部、中文操作/语言/批准规则 |
| [模板](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79；通用字段和A–L |
| [BATCH v0.3](design-TRACK4-ALGORITHM-BATCH-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7；完整十一项及R4/统一批准责任 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2；CLASS125/GRAD185/完整分类不是最终EDGE |
| [C0附件](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md) | 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844；CJ142/CS592真实成功、早失败与唯一FE owner |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107；外层JOB_DISPATCHER/真CS消费/优雅reset/typed V边界 |
| [REPLAY v0.2](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B；最终EDGE只读服务、RQ360/RR421、独立CLOSE338/ACK437及borrow |
| [原CANNY v0.4](design-TRACK4-CANNY-001.md) | 224779F89206F4113CB0764617401E96ED53D7CF34DBD43FBB60A800A54C8729；实际读取B、E1/E2/E3及E4有限性/比较，只采用数值、精确集合、容量、原子接纳、非环队列与安全快路径；旧物理/父生命周期不继承 |
| [闭包资源比较](../experiments/track4_algorithms_20261004/03_review/r4-closure-resource-comparison-v0.1.md) | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C；实际全文读取纯报告，采用扫描等价/容量比较和OPEN结论；其中原模型/datasheet由协议审阅代理及根核验，不冒称本作者直接读取或做了物理映射 |

上表为读取时来源，不是可变父文档的永久冻结。无已有业务源码可复用，下面的端口/状态/符号均是新提议。没有借本任务重新调查指定器件、PHY、校准或IP。

| OPEN | 影响、缺口与后续责任 |
|---|---|
| R4C-B01 | 本逻辑服务的真实backend、原子journal/最新值forward、读延迟/端口/packing/容量与提交/关闭机制未实现或映射；R5必须提出可容纳全1080p且可综合的实际架构及面积/时序/吞吐证据，主机数组不能关闭此项 |
| R4C-B02 | 唯一逻辑对象目录、refs分配/容量证书/独占转移/对象返还/版本与跨软件epoch授权消息尚未与CONTROL冻结；本页规定合同，不能把裸handle当授权 |
| R4C-B03 | 原RGB、可选GRAD提交、识别候选/拟合/核验/去重/ANN及完整bundle注册目录另设计；本文成功只证明最终EDGE，不证明CANNY_RC整体成功或真实APPLIED |
| R4C-B04 | REPLAY的实际EDGE source绑定/底层独立读取、borrow/完整bundle资格，以及R5固定视频/CDC/源不可暂停性/生产pin/完整资源仍OPEN |
| R4C-B05 | 本页完整文件/schema/hex padding、独立参考/协议台账/精确CASE/seed/finite deadline、共同基线及独立组合审阅尚缺；父B05不能关闭 |

可独立继续数学/事务/关闭设计和只读审阅。当前不存在本版本实现批准，正式Manifest/数据库未登记；无需向用户索取未成熟设计的泛化批准。

## B. 整体外部行为与精确集合

输入是同JID/CJ、完整P组的R2初始分类：00 NONE、01 WEAK、10 STRONG，初始11非法；外框初态必须00。令V为全部有限图像素，C为初始01或10的候选集合，S为初始10集合。最终A恰为在C中沿八邻域从任一S可达的集合，EDGE[p]=1当且仅当p属于A。01/10在工作CLASS中接纳后变11；11只表示本job已接纳，不是输入分类码或任意visited旧历史。

| REQ | 可检查规则 |
|---|---|
| R4C-REQ01 | CLASS完整加载/身份坐标/分类规范/统计及真实CS成功、存储提交均成立，才交出完整CLASS证书；提前失败不等P/EOF |
| R4C-REQ02 | 精确八邻域，不限定链长/轮次/目标场景；全部强种子先接纳，再扩展弱点；每点至多入队一次 |
| R4C-REQ03 | 唯一状态写owner；标11及队列append同一逻辑可见提交，未提交最新值可由受保护pending提供，禁止读取旧存储重复claim |
| R4C-REQ04 | 全图非环QUEUE容量N、head≤tail≤N；工作结束须无活动pop/邻居/claim/读写pending并取得阶段提交，不以队列空/安静代替关闭 |
| R4C-REQ05 | 导出全部N像素及P组，显式包含0，原坐标/lane顺序，末byte未用bit为0；EDGE提交前不可供bundle/重放读取 |
| R4C-REQ06 | 错误/取消保留真实前缀，兑现published请求/回复，正确CLOSE证明才能结credit/返还本会话pin；失败不发布、不清别人的ref |
| R4C-REQ07 | no-strong及no-weak快路径与精确集合相等，仍全N导出/真实EDGE提交/关闭；一般分支无10残留可当合法BFS点 |
| R4C-REQ08 | 同job不可变EDGE才能作为REPLAY plane1；source只读原图坐标，按独立可暂停口/关闭证书兑现，不以CLASS替代EDGE |
| R4C-REQ09 | 整图逻辑容量、数学终止、软件运行及实际片上资源/工具分别证明；优化不能把N容量改成会截断的短FIFO |

正常：一个10强点与长01弱链含斜连接/环/分支→所有同候选连通分量被保留。断开链后远端没有强种子的弱分量全0。边界：S=0→全0，Weak=0→仅原10为1；S=Weak=0优先no-strong；两条均不运行QUEUE。一般路径输入10必须全部经种子扫描接纳为11，BFS后来读取10表示一致性错误。任何邻居先检查x/y再计算地址，右边界不能连到下一行最左像素。

成功是完整CLASS证书、精确闭包及全N EDGE提交、真实storage关闭和无错误/取消/溢出共同成立；不是CS0、初始空队列或某个末pair。完整CANNY_RC、bundle和显示另有R4/R5责任。COMMON rst只在全参与者共享reset且外部旧run被合法隔离时可撤事务；软件reset仍须真实关闭，不能仅改变epoch。

## C. 唯一owner、模块与整体路径

| MOD | 唯一责任及数据owner |
|---|---|
| R4C-MOD-J 父JOB_DISPATCHER | 锁CONTROL J及CJ、唯一消费C0真实CS592并保存；分配本epoch load_id/closure_id，准备collector后才启动CJ，转交不可变CS副本/资格；本文没有第二个C0 status消费者或内部FE owner |
| R4C-MOD-O 逻辑目录 | 唯一分配/登记CLASS、QUEUE、EDGE refs、容量和独占资格，管理对象生命周期；具体目录协议与完整bundle尚B02/B03，数字非0不是自授权 |
| R4C-MOD-L class loader | 保存LC270/CJ、CLASS125单槽、独立seal槽、五项计数/EOF、错误与加载终态；只发LOAD_PAIR/CLASS提交，不能直接写状态RAM或消费raw CS |
| R4C-MOD-C closure engine | 保存CLJ438、head/tail、扫描/活动pop/邻居游标、导出pair、backend单credit、阶段token及终态；只发typed操作，不能绕过状态服务或回收目录对象 |
| R4C-MOD-S logical storage service | CLASS/QUEUE/EDGE唯一实际逻辑writer；串行执行load/read/claim+append/queue read/edge write/阶段commit；拥有最新值、受保护pending、真实台账、会话pin及关闭证明。实际backend/packing保持B01 |
| R4C-MOD-E immutable EDGE source | 经O/REPLAY授权绑定已提交EDGE版本，兑现plane1 RQ/RR/CLOSE；不改CLASS/EDGE，不宣布整个bundle完成；实际adapter尚B04 |

普通文本路径：J预留CLASS build并送LC270(IF01)→L真实PREPARED277(IF12)→J获得准备成功才提出CJ→L接CLASS125(IF02)→S LOAD_PAIR(IF05)→J真实CS火后送CLASS_SEAL863(IF03)→S CLASS_COMMIT→LC_TERM776(IF04)→J/O合法独占转移并送CLJ438(IF06)→S BIND511(IF07)→SEED/claim→GENERAL八邻域或安全快路径→全N EDGE_WRITE_PAIR→EDGE_COMMIT→STORAGE_CLOSE294/ACK502(IF08)→CL_TERM1013(IF10)→父收到完整EDGE证据→未来O完整bundle/REPLAY授权→E plane1服务(IF11)。取消/错误走独立IF09/CLOSE，不能经过正常P/EOF门控。

CLASS生命周期是BUILD_LOADING→INITIAL_COMPLETE→EXCLUSIVE_CLOSURE→CLOSURE_COMPLETE或INVALID；QUEUE从EMPTY_BUILD→私有append/read→CLOSED，不循环覆写旧entry；EDGE从PRIVATE_BUILD→EDGE_COMMITTED→父持有的不可变对象，最后一个外部借用真实返还后才可复用。O始终拥有对象，L/C/S只有明确会话职责/独占pin；消费LC/CL终态不自动删除目录对象。一般闭包会改CLASS，原initial commit token只作为起点证明；不许识别/显示同时借原CLASS版本。若未来识别确需原分类副本，必须另提容量与owner，不能隐含免费保存。

S在同一时刻只服务一个已绑定load或closure写会话；LOAD关闭/终态消费后才可将CLASS独占转给C，不能同时存在L写CLASS和C claim。物理共享后端另有adapter隔离，R4C逻辑端口不能把另一会话的回复混进当前台账。S不因C的JOIN、结果接收方或C0 stream结束而等待后台结算；L/C接S回复/CLOSE独立于父终态ready。

整体设计检查点：先明确完整分类和最终EDGE的界限、逻辑容量/唯一写owner、原子接纳/提交/关闭及全N输出，再进入D/E。本文不提供已有帧存储，也不把旧物理授权和phase消息带入新路线。

## D. 身份、容量、端口与组合检查

### D1. 身份/字段和逻辑容量

所有body unsigned；同core沿前valid且ready且非rst为fire，valid/ready不计body。字段表列高到低，组合内部按注明layout；JID96按命名epoch/frame/config字段适配CJ/CONTROL，不能整段盲cast。H160=JID96/operation_id64，load口operation_id是load_id，closure口是closure_id；角色端口分开，S会话/关闭查找键必须含端口角色，不能仅用同数值H跨族查表。若实际adapter合并两族须另携带角色/隔离证据，不能去掉这一前提。父J是这些新增序号唯一分配者，next0/最大值一次/不回绕；与CONTROL新增计数及软件epoch重建桥须B02联合修订。S每会话tx_seq64从0，单信用；新RQ提出前须同时检查tx可分配及真实request台账可增，达到耗尽只关闭已得义务；已held火导致overflow仍照计并隔离，不回滚旧effects。commit_token64由S唯一分配非0版本，须在op5提交前有可分配资格，耗尽不得伪造token或复用旧版本；不能用tx_seq或raw handle冒充。

LC270=CJ142/load_id64/class_build_ref64。CLASS_SEAL863=原LC270/stream_started1/原CS592；stream_started1时CS来自J已真实接纳并锁定的副本，L不能再接C0 raw端口。stream_started0仅允许J证明从未真实启动且没有held CJ义务，CS592必须全0而不解释成原CS成功；它用于准备后取消而未启动C0的源关闭证据，不能伪造一个未发生的status。CLJ438=JID96/closure_id64/class_ref64/class_initial_commit64/queue_ref64/edge_build_ref64/W11/H11。class/edge ref及class_initial_commit非0，并由目录/真实S绑定记录核验；queue_ref允许0仅限S元数据证明S=0或Weak=0的快路径，一般分支必须实际N容量非0ref。闭包W/H须等静态实例及已提交CLASS元数据。

| 逻辑对象 | 容量/布局/生命周期与生产数量 |
|---|---|
| CLASS | N个2bit状态，index=yW+x；bit[2index+1:2index]，00/01/10初态、11接纳；ceil(2N/8)B，生产518400B；新load必须覆盖全部N，末byte padding显式0 |
| QUEUE | 非环N个32bit entry；x[10:0]、y[21:11]、高10bit0，entry index0…N−1；4N B，生产8294400B；只有index<tail有效，不要求清未用entry；tail=N之后不能append |
| EDGE | N个1bit，bit[index]，ceil(N/8)B，生产259200B；所有N均显式写入，末byte padding0；仅EDGE_COMMIT后只读 |

生产N2073600、P1036800，合计9072000B约8.652MiB；不含RGB、GRAD、ANN、识别工作区/目录/pending/对齐及任何多副本。6×5的N30/P15分别8B/120B/4B，CLASS末byte高4bit0、EDGE末byte高2bit0。字节内最低编号像素在低bit，跨byte依编号递增。逻辑byte数不是物理授权/实际RAM组织；真实后端对齐/写粒度/尾部读改写不得越界，相邻对象保护仍B01/B02。

CLASS/QUEUE/EDGE数量显著大于局部流窗历史；主机数组或文件可以验证全N数学与逻辑接口，却不能据此声明这些对象已经装入Ti60片上RAM。本页没有片上分配或新的外部器件方案，R5必须完成实际映射，不借独立OBS的28RAM/22000XLR预算为全机预算。

资源比较报告明确指出，指定CLASS2/QUEUE32/EDGE1容器满容量下界为405/6480/203个10Kbit块（合7088），不是Ti60可容纳的布局；原生模式有效容量/读写兼容族及同址/端口进一步限制推断。203bank只覆盖一份Nbit平面，还需要原candidate重放及真实读改写，不能自动覆盖CLASS、原RGB、GRAD或ANN；Candidate1+A1紧凑下界405，独立两个203bank平面至少406。此处引用协作纯资源证据，不开展器件/IP调查或选择后端，B01/R5保持OPEN。

### D2. 端口与有限容量

| IF | body、方向、前置/结果 |
|---|---|
| R4C-IF01 LOAD_START/BIND | J→L LC270；L→S同LC270 bind、S→L echo270/status2/reason5共277 | L旧IDLE/终态空、独立bind回复槽；e0只锁输入，下一沿校验；S核真实class build容量/独占记录。成功status0/reason0；合法拒绝status1/合法非0reason且未建立pin；2/3及非规范回复非法 |
| R4C-IF02 CLASS | C0→L原CLASS125，低class4，其余sideband121 | 单held接纳槽，旧槽空、本job已ARM且PREPARED已真火、无旧错误/cancel才ready；原lane0低2bit，x/y/IDs/标志layout沿R2；先记真实raw fire，再核身份/坐标/00/01/10/外框/末组标志；不能以当前数据合法性组合撤ready |
| R4C-IF03 CLASS_SEAL | J→L CLASS_SEAL863 | 独立depth1槽，早失败也可接；成功必须stream_started1且CS和LC全文匹配/C0正常谓词与自身CLASS事实合格。未启动路径按D1的0/all-zero证明收尾，不等待不存在CS。L本地故障经sticky反馈J，J继续收真CS并传取消，不立即关status |
| R4C-IF04 LOAD_TERM | L→J LC_TERM776，见D4 | 单held至fire；成功证明CLASS完整与token，失败仅不同真实前缀/关闭；消费沿不接新load |
| R4C-IF05 STORE_RQ/RSP | L或C→S RQ324；S→唯一当前client RSP449，D3 | 一份held request、一份expected credit、独立回复接收位置及S held回复；请求提出后保持；成功/失败回复至少request fire后的后续沿，完整echo；L/C不能同时拥有service |
| R4C-IF06 CLOSURE_START | J→C CLJ438 | 旧IDLE/旧terminal已消费且无旧binding/事务；e0锁全文，后续核字段与S绑定，不在接纳沿读图；非法且无义务可failed_drained，不能清陌生ref |
| R4C-IF07 CLOSURE_BIND | C→S CLJ438；S→C BIND511=echo438/status2/reason5/strong21/weak21/stored_pairs21/flags3 | flags为class_bound/queue_bound/edge_bound；status0/reason0且CLASS完整同initial token、S+Weak≤N、stored_pairs=P、class/edge资格有效、general队列N容量empty才能成功。快路径queue0则queue_bound0；拒绝status1/合法非0reason、counts/flags0且无新binding。wrong echo/不规范回复不能证明未取得pin |
| R4C-IF08 STORAGE_CLOSE/ACK | client→S CLOSE294、S→client ACK502，D3/E6 | 与data独立，不等credit/像素EOF/P/父termready；正确截止/真实台账/settled/全部关闭/pins释放才结本会话，不能把它与REPLAY的CLOSE338混用 |
| R4C-IF09 CANCEL/ACK/FAULT | J→L或C H160；回复167=echo160/status2/reason5；L→J class_fault_sticky1 | cancel0APPLIED/1ALREADY均reason0，2NO_MATCH/reason2，3非法；仅核旧活动H，同沿新start不套旧取消；reply1独立。sticky首次坏CLASS或storage故障后保持到本load终态，下一J沿注册取消；真CS始终独立 |
| R4C-IF10 CLOSURE_TERM | C→J CL_TERM1013，见D4 | 真实提交/关闭后的后续结算或明示Q快照；完整held，终态消费沿不接新job；不等完整bundle已发布 |
| R4C-IF11 EDGE_REPLAY | 已授权E→REPLAY，沿原plane1 RQ360/RR421及CLOSE338/ACK437 | 只读已提交EDGE，同J/source/result/edge版本及borrow由O核；每口1request/read/heldRR，实际绑定/底层读取仍B04，外部字段不变 |
| R4C-IF12 PREPARED | L→J PREPARED277=原LC270/status2/reason5 | 独立held1；status0/reason0只在真实S bind成功成为旧事实后形成，status1/合法非0reason表示启动前未准备；2/3非法。J真实接纳READY成为旧事实后才可提出CJ。取消不能撤已经held的READY，J仍接纳并可选择不启动，随后给IF03未启动证明 |

普通data容量看旧槽；旧full当沿释放不自动再用，避免新数据透传。L/C内只有一个业务request/credit，S逻辑串行；无需无限FIFO。PREPARED、CLASS_SEAL、cancel回复、STORE_RSP、CLOSE_ACK、终态各独立位置，不能互占导致真CS/关闭等数据P/EOF。

### D3. STORE事务、提交与关闭schema

RQ324高到低为H160/tx_seq64/op4/index21/expected_tail21/data32/coord22；coord低x11高y11。以下未用字段必须0，S先核全context/seq/op/范围/coord等于受限index，再寻址。不能用raw payload先访问RAM。opcode6…15保留非法。

S还核角色/阶段权限：load会话仅op0和CLASS_COMMIT；closure GENERAL的SEED只READ_CLASS/期待10的CLAIM/SEED_COMMIT，BFS只READ_QUEUE/READ_CLASS/期待01的CLAIM/CLOSURE_COMMIT；EXPORT只READ_CLASS及EDGE_WRITE_PAIR/EDGE_COMMIT。快路径按已封存元数据直接EXPORT，NO_STRONG无需READ_CLASS；不允许LOAD修改已封存对象、未SEED提交就pop或未CLOSURE提交就GENERAL导出。请求阶段不符明确失败，提交成功成为旧事实后才允许下一阶段，具体backend FSM待B01但该权限保证不能省。

| op | 参数单位/动作；成功结果value32 |
|---|---|
| 0 LOAD_PAIR | index为pair序号0…P−1、coord原x_even/y、data低4bit两初态其余0、tail0；写全部两pixel状态，value0 |
| 1 READ_CLASS | index为pixel0…N−1、coord对应x/y，tail/data0；读取本会话最新逻辑值，value低2bit状态、高30bit0 |
| 2 CLAIM_APPEND | index为pixel、coord合法一致；data低2bit期待初态（SEED只10/BFS只01）其余0；expected_tail等当前tail；原子把该点变11及QUEUE[tail]写合法coord并tail+1；value低2bit原态、bit2 claimed1，其余0 |
| 3 READ_QUEUE | index为head entry且index<逻辑tail，coord/tail/data0；value完整entry32，不删除或循环覆写entry；head仅由C核验成功回复后推进 |
| 4 EDGE_WRITE_PAIR | index为pair序号、coord原图x_even/y、data低2bit边缘其余0、tail0；实际写完整两pixel包括0，value0 |
| 5 PHASE_COMMIT | index/coord0，data低3bit阶段0CLASS/1SEED/2CLOSURE/3EDGE其余0；expected_tail只SEED/CLOSURE为C的tail，其余0；所有此前本会话操作及必要尾padding/最新值已提交且可读后，给非0token；未启用阶段不虚构commit |

RSP449=原RQ324/status2/reason5/value32/queue_tail21/effect_ok1/commit_token64。成功一律status0/reason0/effect_ok1；value按opcode、commit_token仅op5非0其余0；queue_tail是已原子可见tail（load/未启动queue为0）。失败为status1/合法非0reason/effect_ok0/value0/token0/tail0，不伪造没有副作用的证明；若底层部分写或状态未知，整私有build无效并保留pending/pin直到CLOSE或Q，不能再读成成功图。2/3、原因/unused/token/echo异常是坏回复，计raw、不清expected credit。C根据成功合法claim的旧请求期待tail核tail_new=tail_old+1，不能直接用任意返回tail改游标。

S维护逻辑可见state/tail与后端已提交state/queue范围；初始CLASS的S/Weak/P元数据由本会话实际成功LOAD_PAIR effects和规范coverage独立累计，不复制调用方或旧版本统计，CLASS_COMMIT将这些数值与initial token同对象封存。CLAIM成功的两个效果必须同时在S唯一受保护记录中可见。可以用journal/转发保存尚未落后端的两份效果，但不能先把11公布给读取者再等无容量队列；也不能只追加QUEUE却保留旧01。READ_CLASS/READ_QUEUE必须取最新已可见值，读新append不能落到旧后端entry。journal/缓存端口与持久提交实际方案仍B01。阶段commit要求全部已接受操作effects已结清、dirty/尾append/padding可见，不能复制逻辑tail就声称后端提交。

CLOSE294=H160/request_cutoff64/last_seq_valid1/last_seq64/first_reason5。cutoff为本会话STORE_RQ真实fire数（包括op5），last为最后真实tx；零请求则valid0/seq0，非零为valid1。只在自己held STORE_RQ已fire、不再有新提议之后锁截止；允许credit仍1。BIND不是STORE_RQ，不计cutoff，但绑定pin仍包含在关闭义务中。

ACK502=原CLOSE294/actual_request64/actual_raw_response64/settled_request64/overflow3/request_closed1/read_closed1/write_closed1/response_closed1/pins_released1/closed1/status2/reason5。suffix status0/reason0、echo正确、actual_request=cutoff、last一致、actual_raw_response等两端真实RSP fire、settled_request=actual_request、三overflow0及六关闭位全1才是证书。echo内原CLOSE.reason可以非0。status1/合法非0reason明确不能证明；非法/不完整证书不得返pin/ref。settled计每份真实接受请求在RSP火后或CLOSE后合法取消未published操作且全部effects关闭一次，不是good数或raw数的复制。S必须先兑现held RSP，末RSP fire的后续旧闭合状态才能形成ACK；ACKvalid期间无旧RQready/RSPvalid。CLOSE与末RSP可同沿，ACK与RQ/RSP同沿的故障注入使证书失败，真实旧fire仍计。

闭合证书只解除这个H的S内部访问pin/未结credit；O仍拥有CLASS/QUEUE/EDGE，已完成EDGE及其他外部读借用不因它自动删除。wrong bind/RSP/ACK字段不能被当成别人的授权。一个物理S口唯一当前H及真实目录隔离是必须证明的前提，尚B01/B02。

### D4. 原因、计数和两类终态

R4C reason5：0NONE、1BAD_DESCRIPTOR、2BINDING、3CLASS_PROTOCOL、4STREAM_FAIL、5BACKEND_PROTOCOL、6BACKEND_FAIL、7STATE_INCONSISTENCY、8QUEUE_CAPACITY、9COMMIT_FAIL、10CANCEL、11CLOSE_PROOF、12OVERFLOW、13EXHAUSTED、14EXPORT_PROTOCOL；15…31保留非法。mask32按非0原因bit置1，首次reason/位置锁定，后续仅OR。首次沿内优先descriptor/bind→CLASS真实规范/CS→STORE回复协议→真实storage失败/一致性→CLOSE证书→cancel。码族不覆盖CS592/FE原码。

LC_TERM776=原LC270/class_commit64/status2/first_reason5/mask32/loc28/flags6/五计数105/三backend台账192/source_settled64/overflow8。五21bit计数为class_raw_pairs/good_pairs/stored_pairs/strong/weak；flags依次observedEOF/legalEOF/backend_closed/class_complete/drained/stream_started；loc28=valid1/stage4/lane1/raw_x11/raw_y11，stage0validate/1bind/2class/3store/4seal/5commit/6close，7…15保留；valid仅表示字段有位置证据，不保证raw坐标合法，无位置valid0其余0。三64bit台账为STORE request/raw_response/success_response，overflow8对应五计数及三台账。只有真实CLASS/op成功回复才分别推进，不强制失败计数相等。

CL_TERM1013=原CLJ438/status2/first_reason5/mask32/loc48/flags8/算法计数150/三backend台账192/source_settled64/edge_commit64/overflow10。loc48=valid1/stage3/lane1/index21/raw_x11/raw_y11，无位置valid0其余0；valid只表示有位置证据，raw坏坐标不能寻址。stage0bind/1class_read/2claim/3queue/4seed_commit/5closure_commit/6edge/7close；有位置时stage1/2的index单位为pixel，stage3为queue entry，stage6为edge pair，避免坏queue坐标被伪装成pixel0；非位置阶段valid0。flags为class_bound/queue_started/seed_committed/closure_committed/edge_committed/backend_closed/local_empty/drained。算法计数为seed_scan_pixels21/seed_accepted21/head21/tail21/neighbor_checks24/export_pixels21/edge_written_pairs21，共150bit；三64台账同上；overflow10对应七算法计数/三台账，source证书overflow独立检查。

两term status2：0COMPLETE、1FAILED_DRAINED、2CANCELLED_DRAINED、3QUARANTINED。term形成后全文保持，不收新data/不更新冻结计数，消费沿不接下一start。非法未绑定输入可以drained1且无close/token；Q必须drained0并保留可能义务/目录隔离，token字段不能被解释成完整bundle发布证书。drained只证明本子任务取得的义务结清，不代表父目录或未启动识别已结束。

## E. 局部状态、不变量与中文操作草图

### E1. 初始化、容量和不变量

L状态候选IDLE→VALIDATE→BIND_WAIT→ARMED_LOAD→WAIT_SEAL→CLASS_COMMIT→CLOSE→SETTLE→STATUS→GAP→IDLE；错误/取消进入ABORT_DRAIN/CLOSE，坏关闭进入Q_DRAIN/Q_STATUS/QUARANTINE。C状态候选IDLE→VALIDATE→BIND_WAIT→SELECT→SEED_SCAN→SEED_COMMIT→BFS_POP→BFS_NEIGHBOR→CLOSURE_COMMIT→EXPORT→EDGE_COMMIT→CLOSE→SETTLE→STATUS→GAP；快路径跳过未启用queue/seed/BFS/closure commit。状态编码位数待源码schema冻结，非法状态报协议并隔离，不回IDLE假恢复。

L独占LC/CJ、prepared槽、class槽、seal槽、游标/计数、sticky fault、term；C独占CLJ、扫描x/y/index、head/tail、活动pop(valid及x/y)、neighbor_id3/结束valid、导出lane暂存、stage token、term。S独占每会话实际CLASS/QUEUE/EDGE数据和版本、逻辑tail/提交范围、单操作pending、held RSP、关闭记录/ledger。L/C各一个STORE_RQ held与expected_rq/credit，不是两者共享同时用。有效期覆盖最后回复/close/term，不靠清图RAM重建空。

| INV | 条件和理由 |
|---|---|
| R4C-INV01 | 初始CLASS完整P组且只有00/01/10，边界00；commit前无可读完整对象 |
| R4C-INV02 | 一个CLASS写owner；C只经S操作，所有读取最新逻辑版本 |
| R4C-INV03 | 01或10变11与入队成对，成功无反向状态，tail每成功claim增加1，每pixel至多一次 |
| R4C-INV04 | head≤tail≤N，READ_QUEUE仅head<tail；tail=N后遇新候选是错误，不截断 |
| R4C-INV05 | SEED遍历N且seed_accepted=已验证S，SEED提交后BFS不会合法遇10 |
| R4C-INV06 | 每pop八邻居按有限x/y核验，无跨行/重复推进，pending停顿不跳项 |
| R4C-INV07 | head=tail只有无活动pop/邻居/claim/读写pending才逻辑结束；另需真实阶段commit/EDGE提交及close |
| R4C-INV08 | 导出N像素/P组包含0；initial10仅no-weak映射为1，general仅11为1 |
| R4C-INV09 | bad RSP raw++但不结credit、不取坏值寻址；CLOSE独立credit，可凭正确settled证明失败结账 |
| R4C-INV10 | held request/reply/term不撤/不改；取消同沿旧完整原子提交照计，失败整体图无效 |
| R4C-INV11 | 对象refs/版本/epoch不可混用，term消费不替对象返还；Q不自动复用/发布 |

共同rst同步高时所有fire0，L/C/S/E共同清有效身份/pending/held与本run会话；外部旧事务必须共同reset或已合法隔离，不能单端rst清pin后接受旧payload。图RAM不必清，但CLASS的新load完整覆盖、QUEUE tail0及EDGE完整重写/commit保证旧内容不合法。软件epoch变更由CONTROL唯一RESET_OWNER授权，必须关闭本task和E/borrow并消费终态/GAP；具体桥仍B02/B04，PLAN/CLJ中epoch变化不能自身授权重建。

### E2. R4C-OP01：CLASS加载、早失败与提交

1. J先通过O预留N状态build和L/CS终态容量；LC接纳e0只锁CJ及ref。L后续VALIDATE核CJ尺寸/TL≤TH≤2047/布尔flags及真实capacity/identity，bind成为旧成功事实后才形成PREPARED。J在IF12真火获得READY成为旧事实后才向C0提出CJ；首CLASS不会穿透start沿。准备后取消且CJ从未提出/接纳时，J送stream_started0/CS全0的IF03收尾；若CJ已经held，就必须先兑现、随后取消并送stream_started1/真CS，不能走未启动捷径。
2. L接CLASS125时raw_pairs先加1。按自己的受限pair游标核JID、原x_even/y及SOF/EOL/EOF；检查两lane不是11、外框00。有效capture另good_pairs加1，按两lane贡献累计strong/weak，登记observed/合法EOF；坏capture记定位并置class_fault_sticky，不产生LOAD_PAIR。合法EOF仅第P组/末原坐标/规范marks。
3. 好class槽锁完整payload，后续沿建立op0；STORE request火建credit；后续完整合法RSP火才stored_pairs加1、清槽/credit，后续沿可接新CLASS。不能在valid等待时计存储，也不以RSP形成代fire。无新class插bubble，不写重复像素。
4. J唯一早接C0真实CS并锁原值，在自身校验后提出CLASS_SEAL863/stream_started1；L seal ready独立，不等P/EOF/存储data槽空。提前CS失败或本地sticky进入ABORT，不等补齐分类；L经J取消C0，J仍接真CS，不造一份正确终态替代坏真值。有效未启动证明只用于取消/启动前失败，不形成CLASS_COMPLETE。
5. 全成功需stream_started1及LC/CJ/CS全文匹配，CS reason0/mask0/合法flags/七必需口及启用grad完整P/EOF/FE OK均按C0合同合格；L自己raw/good/stored=P、合法EOF、strong/weak与CS一致且和≤N，无错误、data槽/credit空。CS证明流段，L的真实op0和CLASS_COMMIT证明CLASS存储；二者不能互代。启用GRAD的后端提交另B03，不冒称CS已证明GRAD对象持久可读。
6. 满足旧事实才提出op5 CLASS_COMMIT；S收齐全部N状态/尾padding并完成此前effects后回非0class token。L收真成功RSP后提出独立CLOSE；正确close成为旧事实后SETTLE后续沿形成LC_TERM COMPLETE。class token/完整metadata由O保留，L的终态消费不销毁对象。

### E3. R4C-OP02：选择快路径与完整强种子

1. C接CLJ后逐字段核合法尺寸/三ID/refs/初始commit，绑定S时取得真实S/Weak/P及独占资格。错ref不试读；wrong bind回复保存错误/未知binding，不从raw回复handle释放对象，按关闭/隔离处理。全成功绑定成为旧事实后SELECT。
2. S=0选NO_STRONG；Weak=0且S>0选NO_WEAK；否则GENERAL。快路径queue_ref可以0，不启动QUEUE、SEED/BFS或伪造相应commit。NO_STRONG直接全P写0；NO_WEAK在导出遍历完整N原CLASS，只允许00/10并映射10为1；遇01/11是metadata/版本错误。两条仍EDGE_COMMIT/CLOSE，不提前SUCCESS。
3. GENERAL head=tail=0、活动pop无效。种子游标从index0/x0/y0扫描全N；每次op1请求及真实合法回复后才使用读值。00/01跳过，10保存该坐标并请求op2期待10/当前tail，11报STATE_INCONSISTENCY。读值不会来自后端过期版本。
4. op2只有S能在同一逻辑提交同时CLASS=11、QUEUE[tail]=coord、tail+1。C收到完整成功claim/value/tail回复才seed_accepted++、tail推进及扫描下一点；queue满/未授权/状态不一致则明确失败，不能先标11再丢队列。state/queue内部atomic点与client响应是不同事件，但没有第二writer能看见一半提交。
5. seed_scan=N且seed_accepted=S、所有seed请求/RSP/credit结清才提出SEED_COMMIT，S确保最新state/所有seed append已提交、tail一致，后续合法token才进入BFS。未完成种子不能提前pop；10之后不能当另一合法种子补入。

### E4. R4C-OP03：活动pop与八邻域

1. 旧head<tail且无活动pop/pending时提出op3 READ_QUEUE(head)。成功真回复先核entry高10bit0、x/y范围及对应CLASS归属，再锁active_pop并head+1一次；不能在请求火时先跳过未核entry，也不依赖除W恢复坐标。
2. 固定邻居顺序NW、N、NE、W、E、SW、S、SE。由旧active坐标先扩signed13再加−1/0/+1；若不在0≤x<W、0≤y<H，登记一次neighbor_checks并进入下一项，无RAM操作。合法坐标先在宽临时中计算index=yW+x并检查<N，才窄化21发op1。
3. 合法READ_CLASS成功：00/11完成本邻居；01保存坐标发op2期待01及当前tail；10报一致性错误，不继续当强边；非法回复按协议错误不取值。op2成对成功才tail++，这份坐标以后会被pop；每次邻居完成计一次checks，request等待不重复计。
4. 完成第八项后后续沿清活动pop/邻居pending，再判断head<tail取下个entry。neighbor_id3仅0…7，另有邻居完成valid/计数，不能8窄化回0造成第二轮。单活动pop/单credit使本任务无并发CLAIM竞争；即使底层延迟，active坐标/期待tail/tx/状态保持。
5. 有新append时S的READ_QUEUE保证读受保护最新entry；不以逻辑tail增长盲读未提交后端。head=tail仍可能旧pop未检查完，不能提前结束；只有head=tail、活动pop/读/claim/请求/credit/响应slot均空才发CLOSURE_COMMIT。S把所有最新state和append提交后给真实token，再进入全图EXPORT。

数学终止：成功claim永久将一个非11候选变11并入队一次；不可能有第二次成功claim同点。tail≤N，pop≤N，每pop最多8检查，有限图及最终响应下结束。这个证明不是固定若干轮/链长，包含全图蛇链/斜链/环/多个种子。QUEUE达N仍需claim表示一致性或协议错误；不能丢候选维持运行。

### E5. R4C-OP04：全N导出、可见完成及边界

NO_STRONG按全部P顺序生成两个0；NO_WEAK按全N原state10生成1；GENERAL在CLOSURE_COMMIT后按全N最新state11生成1，00/剩余01为0，10/非法值立即失败。pair均lane0为偶列低bit、lane1高bit；导出游标是原图，不用REPLAY mode0的source/display映射。两lane都形成后锁pair，后续op4完整写入；写0也是真实操作，不能以旧清零RAM免写。

export_pixels计已核并形成的scalar数，edge_written_pairs只计合法op4真成功RSP，工作期间两者可以不同。每pair完全写后才推进下一组；EOF逻辑位置为(P−1,W−2,H−1)，并不是存储已closed。全部N/P成功、pair私有槽/credit空后发EDGE_COMMIT，S核全coverage/顺序/尾bit0及此前写effects已提交，返回edge_commit token。没有完整commit禁止E/目录把私有EDGE标完整；失败保留真实短写前缀但不发布。

GENERAL成功还要求seed_scan=N、seed_accepted=S、head=tail≤N、seed及closure token真实、全N/P和edge token；NO_STRONG/NO_WEAK不强求不存在queue/BFS计数或token。正常随后CLOSE返还S会话访问pin，父仍拥有已提交EDGE。SETTLE使用旧保存证据且无本沿新取消/错误的后续沿形成COMPLETE；terminal消费不代表完整bundle成功或旧CLASS/QUEUE已经由目录回收。

逐沿例：e0 C发CLAIM的request火，S只接纳/锁期待状态与tail；e1或更后S以旧pending取得最新state及两效果保留容量；e2或更后成对逻辑提交；e3或更后提出held成功RSP；e4或更后client真火核echo/value/tail并登记。具体backend延迟不冻结为这几个沿，最早/任意停顿都必须遵守先接受→后形成→真交付，无同沿透传。CLASS/QUEUE成对提交与cancel同沿时两效果同样完整提交并成为失败job真实前缀，不能只擦一半；该job后续不发布。

### E6. R4C-OP05：失败、取消、credit与CLOSE

1. 第一次错误/匹配cancel沿先计所有旧CLASS/STORE request/RSP及已完成原子事件；后续旧ABORT禁止新CLASS业务/new STORE操作、seed/BFS/export及新正常commit。私有未published读值/pair可丢；已held request/body保留到火，S held RSP仍实际交付，不能用取消单端撤掉。
2. STORE RSP ready按实际接收容量/活动会话，不由echo合法性组合门控。坏echo/status/reason/value/token/raw坐标只raw_response++、锁错误、不清expected credit；合格匹配失败可结credit但不作成功count。L既有seal与J真CS义务继续独立，未启动C0不等待不存在CS。
3. 自己所有held STORE_RQ已兑现后锁实际cutoff/last，提出CLOSE294，不能等待expected credit/good/P/EOF/父term消费。S CLOSE独立于data和client credit，封住新读写；旧接受操作完成或在effects真关闭后安全取消；claim一旦逻辑提交不能半回滚，held RSP不能撤。
4. S只有全部实际requests settled、read/write/pending/heldresponse闭合、会话pin确已归还才能出ACK502。正确ACK结清原credit为失败结算，不增good/seed/tail/edge数学数量，不造EOF/token。同沿末RSP照计，ACK后续形成；错误ACK与RSP并发则raw照计并判证书无效。
5. 对已启动/已binding的失败，只有合法CLOSE、local_empty和所有真J seal/已有控制义务（包括已held PREPARED）结清才形成FAILED_DRAINED或CANCELLED_DRAINED。准备后未启动路径须J明确给IF03 started0/all-zero证明；L启动前VALIDATE/BIND合法拒绝则自身尚未发READY、不会形成C0义务，不等待seal。cancel不覆盖已锁首次更早错误；持续匹配cancel回ALREADY、不延迟已有失败term。未取得binding的规范reject可无CLOSE失败drained，wrong bind不是规范reject/无pin证明。
6. 无完整关闭证书进入Q_DRAIN，继续兑现已经held的request/CLOSE与必要published义务；等本地published发出槽都已火、私有值清后可冻结Q terminal/drained0，credit不阻隔离通知。冻结后RSP/ACK ready0，可能迟到held回复留在S，当前绑定/ref保持隔离，计数/term不被晚回复改写。Q消费不解绑定、不接新start、不自动释放；恢复仅合法共同reset或以后设计的目录/epoch恢复证明，B01/B02仍OPEN。
7. S或父消费者永久不ready时可能保持PROOF_PENDING，不能承诺固定周期结束或用超时伪造closed。未来watchdog可以记录失败并请求独立CLOSE/Q，但deadline与实际backend必须B05冻结；没有证明不能复用已取得对象。

### E7. R4C-OP06：最终EDGE的逻辑source与REPLAY交接

E只有在O核完整同J/source/result且edge_ref/edge_commit与本COMPLETE一致、取得当前borrow的只读授权后才能启用。它不能接可变CLASS或仅有CS0的工作图。plane1 RQ360必须echo固定job/plan/display/borrow、合法seq/source_x_even/y/display坐标及REPLAY marks/plane_first/last；E按源坐标检查，再读取EDGE[index]及index+1构成RR.data54[49:48]，RGB/ANN位置0。mode0下半访问偶源行0,2…1078，原EDGE仍有全部1080行，不预先裁图。

E一口只有1个实际请求/读取pending及1个held RR；读应至少在RQ fire后后续沿回复。held RR不会因取消/CLOSE撤valid；读错误用匹配status1/合法非0 reason/data0。REPLAY CLOSE338独立封口，E只等待自己真实接受读取/可能效果与held RR结清，未published读可安全取消，settled只各请求一次；实际last seq/请求/raw/settled/overflow及四闭合位按原ACK437，末RR火的后续沿才提出。不能等REPLAY client的good/credit或OUT EOF，否则wrong-key形成环。

E CLOSE仅关闭本plane读取，借用仍由REPLAY的RELEASE288及O真实账本返还；不能使用R4C STORAGE_CLOSE502去释放REPLAY borrow。实际O绑定、共享后端读取公平性/端口和完整bundle proof B03/B04尚未实现。本文冻结值/握手/关闭保证，不假定一份完整图数组已经提供了可综合E。

## F. 数值、语言与三份对应契约

N/P/index/head/tail及S/Weak为unsigned21，增量先22bit；8N最大16588800，neighbor_checks用unsigned24、增量25bit。yW+x先32bit并核范围再窄化21；x+lane先12bit，邻居偏移先signed13；tx/台账64bit先65bit，饱和/overflow或exhausted保留，不回绕。初始S+Weak先22bit≤N。所有对象大小/byte长度用足够宽计算ceil，不以8bit移位截断索引。Queue高10bit以及所有unused/padding检查严格，不将bool冒充整数。CLASS/EDGE bit精确，不存在数学误差容忍。

GENERAL保守上界：种子N读+S claim；pop K≤N；邻居最多8K读；弱claim K−S；导出N读；CLASS及EDGE写各P，共≤13N个data操作，加最多四个phase commit。这是全链合计：load会话≤P+1请求，closure会话≤13N−P+3请求，各自H/台账/CLOSE cutoff独立，不能拿合计作某一term的真实数量。生产全链≤26956804个STORE请求（load≤1036801、closure≤25920003），必须使用64bit服务台账，不能用21bit像素计数充当总事务数。8N比较数16588800；整个矩形有效有向邻接上界8N−6W−6H+4=16570804。只按一检查/100MHz计算的165.888ms是理想比较，不含请求/读改写/claim/提交/seed/export或stall，不是实际时钟/吞吐证据。

可比较不带N队列的精确反复扫描：从A=S开始，完整遍历N，若初始候选p邻接A则只将A[p]0→1，最新同word更新不丢；每遍全部effects结清后开始下一遍；完整一遍changed0才固定点。每个加入点有到S路径，若任何可达点未入A则路径首缺点与A相邻矛盾，因此结果与BFS等价。最多Weak个变化遍再一确认遍，不能用H+W/固定遍数截断。可直接在2bit CLASS种子10→11后扫描01邻11，或A1bit配原candidate重放；后一方案必须真实保留/重放初始candidate，不是C0活CLASS自动可回读。这个优化候选需要另修接口/提交/容量/测试并联合审阅，当前冻结主体仍BFS。保守N²为4299816960000次pixel访问，100MHz下约11.94小时仅理想尺度，不能以省队列暗称60Hz；实际bitmap packing/共享端口/最新值forward/收敛及资源仍B01/R5。

拟采用SV2009；同域时序非阻塞、组合阻塞，命名表达load/claim/commit/close责任。C++未选，不生成指针/RAII/异常映射。未来Python标准库独立参考直接按初始候选图与强种子求可达集合（或独立连通分量），不复制S journal/cache/队列打包/phase FSM作唯一oracle；完整输入先核尺寸、长度、值域和边界，不修改输入，返回新N-bit图及集合统计。参考host数组只是数学/软件服务实现，物理映射独立证明。

| RTL A–L | 本局部合同/未知 |
|---|---|
| A 数值 | 上述21/22、24/25、64/65、signed13/32bit地址；strict CLASS编码、entry高0、padding0；无回绕/无近似闭包 |
| B 时钟 | 单core上升沿旧valid/ready/状态；输入下降沿稳定驱动、沿后稳定观察；未冻结实际backend cycle或新100MHz约束 |
| C 接受 | LC/CLJ/bind/data/seal/commit/close/term分火；capacity在提出前预留，reply/早CS资格/close独立 |
| D valid | 无效不计数/不写图；0数据合法，valid0/无对象/failed response不当0像素；EOF/空队列/empty/closed不同 |
| E 保持 | complete body/坐标/tx/期待tail、活动pop/邻居/导出pair及所有published握手保持；取消先旧火再私有清理 |
| F 延迟 | 一请求/credit串行；后续沿回复、commit后续可用；BFS复杂度有限但服务/反压可停，不证明camera/video60Hz |
| G 复位 | 共同同步高rst火0，身份有效隔离；QUEUE旧无效entry不清，CLASS/EDGE新全覆盖；单端或软件epoch不能替真排空 |
| H 配置 | CJ/CLJ完整快照，CLASS initial版本明确；新D/C颜色/阈值不改旧图；父同沿job旧C沿CONTROL，跨epoch桥B02 |
| I 存储 | CLASS2N、QUEUE32N、EDGE N逻辑bits；latest/atomic claim、phase commit及CLOSE证书；真实RAM/backend端口/同址/packing/容量B01 OPEN |
| J 身份 | JID/load/closure/tx/ref/commit分开，index与pair/queue单位分开；原图lane0偶列；REPLAY source/display/plan坐标不混 |
| K CDC | 当前局部同域无需逐bit同步大ctx；外部源/目录/视频多域需R5握手/FIFO及共同reset合同，未宣称CDC通过 |
| L 实现 | Ti60软件目标/既有工具；没有实际后端网表/RAM推断/完整资源/STA；新增本局部不冒OBS预算，不进行指定器件/PHY/IP工作 |

三份契约分别是：共同数值以完整初态集合求精确A；硬件执行以实际request/RSP/atomic可见/phase token/close及旧同沿事件证明；软件结果↔硬件以(JID,class_initial_commit,closure_id,pixel原坐标)逐bit比较完整成功EDGE，失败比较真实前缀/各自计数/token/关闭/Q，不補后缀成功。host函数执行顺序不能证明硬件时序；CRC/terminal摘要不能代完整N-bit黄金图。

## G. 未来实施与验证计划（全部NOT_RUN）

先闭合B01…05、组合CONTROL/REPLAY/R4其他局部并实际全文独立审阅，再纳入整包指定批准。未来仅在获批work生成class_object_loader、exact_hysteresis_controller、logical_state_queue_service、edge_object_export、immutable_edge_replay_source及独立参考/协议/整图测试；具体路径/共享包schema/runner另B05冻结，现在没有这些业务文件或工作副本。

| TEST | 输入/事件及REQ/IF | 期望/方法/通过边界 |
|---|---|---|
| R4C-T01 | 合法6×5/生产完整CLASS，00/01/10、外框与末byte；REQ01/IF01…04 | P真火/完整coverage/S/Weak/CS一致且CLASS commit后才complete，N30 padding4/2；独立图/台账；NOT_RUN |
| R4C-T02 | CLASS11/坏JID/坐标/早EOF/缺EOF/外框强或弱；CS提前失败或CS0但本地fault | raw保留/不写坏地址、sticky→J取消仍收真CS、失败不等P、不伪commit；NOT_RUN |
| R4C-T03 | TL=TH产生无弱、S0全弱、全部0、多个孤立10；REQ07 | 两快路径与全图可达oracle相等，QUEUE未启用不等待其commit，全P显式导出；NOT_RUN |
| R4C-T04 | 跨全部图的长蛇链、斜链、环/分支/多种子、断开远端弱块 | 全八邻域可达集合逐bit、每点≤1 claim，长度不截断；NOT_RUN |
| R4C-T05 | 角/左右边界、xW−1邻下一行x0、队列坏coord/高10bit、GENERAL残留10 | 不跨行/不取坏地址、明确一致性失败；NOT_RUN |
| R4C-T06 | claim容量不足、tail=N−1最后一次、tail=N仍需新claim | CLASS=11与QUEUE entry成对/真实tail，容量错误不丢候选、不截断；N容量证明；NOT_RUN |
| R4C-T07 | state最新值/queue append未落后端、同word两次claim、读journal与commit延迟 | 无过期读/重复入队、phase token不能早于effects可见/提交；真实backend独立台账；NOT_RUN |
| R4C-T08 | head追tail但active pop未完、最后邻居追加、READ_QUEUE/claim/RSP分别停顿 | 保持active/期待tail/tx，八项恰一次，最后新点仍处理，无假结束；NOT_RUN |
| R4C-T09 | PREPARED/CS/seal held、准备后取消未提CJ、CJ held后取消、S bind/RQ/RSP/phase/CLOSE/term held，父不消费 | 容量有界/body保持、未启动证明不造CS、held CJ须真接纳后真CS、早失败/close不等P，真实fire不同计数；NOT_RUN |
| R4C-T10 | cancel与CLASS/RQ/原子claim/RSP/末EDGE/commit/CLOSE各同沿；持续cancel | 旧火/成对效果保留，后缀invalid，真关闭后失败term或Q，不改rawCS/冻结term；NOT_RUN |
| R4C-T11 | wrong echo/op/seq/unused/status0非0reason/成功token0；bad CLOSE ledger/pins/last/closed | raw计/credit不清；独立CLOSE可按真实settled结账，不返他人ref；错误证书Q；NOT_RUN |
| R4C-T12 | CLOSE与末RSP同沿、错误ACK与RSP同沿、未published读安全取消、Q后迟到回复 | ACK后续旧闭合、证书与真实台账匹配；Q台账冻结/borrow隔离不自动恢复；NOT_RUN |
| R4C-T13 | NO_STRONG/NO_WEAK/GENERAL全N导出、末pair/尾padding、写0/写失败 | N/P与原坐标逐bit，partial EDGE不供source，不用旧清零免写；NOT_RUN |
| R4C-T14 | E mode0下半偶行/其他mode全图、独立stall/wrong-key/CLOSE | 原完整EDGE供正确bit，RQ/RR/437关闭沿REPLAY，无live CLASS tap或credit-close环；实际provider待B04；NOT_RUN |
| R4C-T15 | 共同rst各阶段/新job旧11隔离、非法单端reset/未授权epoch改变 | 火0/合法共同run丢弃，软件桥未闭合则不宣跨epoch恢复；NOT_RUN |
| R4C-T16 | 64bit首号/最大值/overflow、N/8N边界与producer重复请求 | 不回绕、不把总事务计数窄到21，旧关闭/终态继续；NOT_RUN |
| R4C-T17 | 生产1920×1080正常/密集/稀疏/长链及完整R2组合 | 全N黄金EDGE/真实logical台账与CS/loaded metadata共同成立，小图不能替代；NOT_RUN |
| R4C-T18 | 真backend容量/网表/有效扇出/资源/PNR/STA/实际吞吐；BFS与扫描候选 | 给完整映射/面积时间质量权衡，不把主机数组/203一bit平面或短FIFO当全机证明；NOT_RUN |

参考用独立连通分量/集合可达算法；事务检查器单独从实际fire造黄金ledger与期望seq/claim事件，不读当前DUT term造黄金。正常/边界/故障各含局部与R2→CLASS→闭包→EDGE→REPLAY组合。未来刺激下降沿、fire沿前、沿后稳定观察；有限stall/cycle+wall deadline由真实backend和实际套件B05冻结，永不ready只检查不伪成功/不释放。无执行测试/种子实测/工具许可或生产映射结果可继承。

## H. 双向追踪

| REQ/来源 | MOD/IF/操作/INV | 计划稳定符号/文件类别，未生成 | TEST/当前证据 |
|---|---|---|---|
| R4C-REQ01 / R2-REQ05/07/C0成功 | J/L/S，IF01…05，OP01，INV01 | class_object_loader / load_snapshot、class_hold、seal_hold、raw/good/stored、class_commit | T01/02/09/17；来源+本文设计，NOT_RUN |
| R4C-REQ02/04 / CN-01/06/07 | C/S，IF05…08，OP02/03，INV03…07 | exact_hysteresis_controller / seed_cursor、active_pop、neighbor_id、head/tail | T03…08/17；集合/有限性分析，未实现 |
| R4C-REQ03 / CN-INV04…07 | S/C，IF05/07/08，D3/OP02/03，INV02/03 | logical_state_queue_service / atomic_claim_record、latest_forward、phase_commit | T06/07/10/11/12；实际backend OPEN |
| R4C-REQ05/07 / CN-OP05/07 | C/S，IF05/10，OP02/04，INV08 | edge_object_export / export_cursor、pair_hold、edge_commit | T03/13/17；完整N/P合同，未运行 |
| R4C-REQ06 / CONTROL/C0/REPLAY失败原则 | J/L/C/S，IF03/08/09/10，OP05，INV09…11 | request_hold、expected_credit、source_close_certificate、quarantine_snapshot | T02/09…12/15/16；纯关闭设计 |
| R4C-REQ08 / REPLAY-REQ01/02/04 | O/E，IF11，OP06，INV08/11 | immutable_edge_replay_source / bound_edge_version、held_rr、source_ledger | T14/17；真实bundle/provider OPEN |
| R4C-REQ09 / BAT-REQ05/06 | 全局，D1/F/G，B01…05 | logical_capacity_contract、independent_closure_reference、resource_reports | T16…18；逻辑算术，不是片上/工具证明 |

反向：L只加载/验证初CLASS；C只遍历/导出；S独占逻辑写与latest/commit/close；E只重放已完成EDGE；O才分配/授权/回收。识别/完整bundle/物理后端不能以这些符号临时合理化。获批实际文件/源码符号/波形/退出码/报告/hash再双向登记，现在没有业务代码基线。

## I. 设计门槛与审阅

①整体集合/样例B；②模块/owner/连接C；③字段/容量/组合D；④局部状态/旧沿中文步骤E；⑤语言/数值/三映射F；⑥正常/长链/失败/关闭走查B/D/E；⑦实施/验证/追踪G/H。⑧无阻塞未满足，B01…05仍OPEN；⑨本文保存后须实际全文读回/hash及独立审阅，未预宣通过；⑩版本/纯设计范围/来源明确，整包实现基线未冻结。因此LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN，不能关闭R4/B03/B05或要求用户批准这一未成熟实施范围。

当前用户未批准本页/整包指定实现，Approval Manifest/数据库不改。等待完整后端/目录/R4其他局部/R5与本页联合成熟后统一呈现具体设计版本集合、范围和共同基线；实际数据库/工作副本/工具前置另核。

## J. 变更与恢复

相对原CANNY只保留严格分类/精确可达集合、N队列、原子接纳、快路径、全N导出、有限性；新增LC270/PREPARED277/seal863/CLJ438、typed STORE324/449、logical CLOSE294/502、776/1013终态与immutable EDGE service。旧917bit job/物理phase_key/grant/突发/fence schema及器件工作不继承。与当前C0 CJ142/CS592、REPLAY360/421/338/437保持原族，必要适配按命名字段，不改原布局。

若选择扫描代BFS、压缩/复用EDGE/CLASS、共享多个活动写者或缓存/向量CLAIM，将改变容量/原子性/终止/性能与测试边界，须先修订设计/读回/审阅，不偷偷把队列变短。真实backend能够用受保护pending实现逻辑atomic不意味着其物理write已完成；必须保留阶段提交与关闭证明。恢复读最新父/本文/来源/批准，核refs/commit、singlewriter/tx、坏echo credit及Q未结。

## K. 实录

本轮仅规则与指定来源只读、纯文字/字段/容量分析及授权创建本文。没有业务RTL、功能脚本/模型、可执行测试/TB、工程/SDC，没有仿真/综合/PNR/STA/bit；全NOT_RUN。没有网络/安装/指定外部存储器件/PHY/校准/IP调查，原HDK/其他设计/正式状态/Manifest/数据库保持。本文计划的host reference/backend与硬件模块尚未生成，逻辑9072000B不是实际内存/片上资源报告。

## L. 中文阅读与交付顺序

整包→R2分类不是最终edge→本文B可达集合→C唯一写owner→D容量/LC/CLJ/STORE/commit/CLOSE/term→OP01完整分类加载→OP02强种子与快路径→OP03固定八邻域→OP04全N导出→OP05失败关闭→OP06只读source→F/G/H→I/B01…05。普通一条路径是CJ分类→真实CS及CLASS commit→SEED成对接纳→真实SEED提交→BFS活动pop/八邻域→CLOSURE提交→全P写EDGE→EDGE提交→正确CLOSE返本会话pin→COMPLETE→父完整bundle/REPLAY另外授权；失败路径不补P/EOF。

修改连接数学看REQ02/OP02/03/T03…08；修改后端/原子可见/关闭看D3/OP05/T07/09…12；修改最终重放看IF11/OP06/T14；资源/吞吐回B01/R5/T18。获批实施后核对文档—中文注释—稳定符号—实际代码—独立参考/测试的数值、事件、配置、身份、存储和关闭一致性；当前理解验收待用户实际反馈，不把讲解或保存设计当已理解/功能通过。
