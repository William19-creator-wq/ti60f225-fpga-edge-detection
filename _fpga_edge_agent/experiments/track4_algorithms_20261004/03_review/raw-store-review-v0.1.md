# RAW-STORE 独立存储与通信审阅 v0.1

2026-10-04；纯设计审阅报告。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。

- Goal：复审完整1080p算法core的canonical-byte后端、原子组失败结算、复位关闭次序及真实UART通信边界。
- Current state：RAW-STORE为未合并候选；业务实现、模型、可执行测试、Efinity工程、SDC和工具运行均未生成或执行。
- Target state：先关闭本文两项局部协议阻塞，并冻结目录/typed适配/transport/生产I/O与性能合同；之后才可能进入整包设计评审。
- Gap：两项明确局部矛盾见D；RAW-B01…06及相关R4/VIEW/R5交接仍OPEN。
- Assumptions：保留1920×1080、十一项及原识别/质量要求；可暂停typed测试与不可暂停生产视频分别证明。
- Open questions：真实全机存储和生产通信后端、SOURCE/GRAD/profile/RECORD目录安装与归还、全部FSM和资源/时序预算尚未冻结。
- Dependencies：项目AGENTS/规则启动链、唯一根v0.2、PLAN_TEMPLATE及A中实际hash。
- Milestones：只读审阅→保存本报告/实际读回→根代理纯文档修订→指定新hash复审；不接续实施。
- Detailed steps：B看结论；C看owner/正常路径；D/E看反例和最小修订；F看容量/带宽；G/H看未来场景/追踪。
- State transitions：本报告不改变项目正式状态、Manifest或数据库；失败路径建议不是已合并接口。
- Artifacts and hashes：只创建本报告；读回SHA256另报，避免文件自引用循环。
- Validation：实际文本读取、字段/容量/报文算术、协议反例；全部功能验证NOT_RUN。
- Failure handling：未知效果保留KEY/journal/ref；Q不凭通知消费、软件reset或PC数组销毁恢复成功。
- Human approval gates：没有业务设计实施批准；报告保存授权不替代指定成熟版本/范围/基线的用户批准。
- Rollback：本报告为独立纯文档，不修改主稿或历史资料；根代理负责后续版本化修订。
- Completion criteria：本次报告真实保存/全文读回；不要求批准前先实现，也不以报告完成判整包READY。

## A. 读取范围、来源与版本

RAW主稿本轮实际全文读至末行，读前/后hash保持下表版本。R4C、R4R、VIEW在此前任务已实际全文独立审阅相同hash，本轮重新读取当前文件、核实hash并重读下列组合关键段；本报告聚焦存储/通信及关闭生命周期，不重新裁定几何算法、ROM数值或质量正确性。

| 输入 | SHA256 / bytes | 本轮重点 |
|---|---|---|
| [RAW-STORE v0.1快照](../../../planning/design-TRACK4-ALGORITHM-RAW-STORE-001-v0.1.md) | 94F0327B10081903D4C034B136A46DD1B8962337C71F59FC357C9DACADD4D799 / 61325B | 全文；D3/D4/D5/D7、E4/E6/E7及G/H |
| [R4-CLOSURE v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 / 63263B | D3/D4、E6及provider：实际claim/phase/CLOSE/会话pin与目录对象区分 |
| [R4-RECOGNITION v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 / 83901B | D2/D3/D4/D5/D8、E9：单在途、失败effects、真正关闭及ALL私有refs |
| [VIEW-BRIDGE v0.2](../../../planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C / 64477B | C单图容量、D3证书/两层引用、D5 QUIET/epoch授权 |
| [REPLAY v0.2](../../../planning/design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | 当前hash所绑定的可暂停合同；本轮只重核生产边界相关文本，不重做其全文评审 |
| [ROUTE](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md) | 2D082374D56754CE4D38654B4945D3D736FABD9C5F36FE8E47759CEBCF90E9AE | 行60/64/66的不可暂停适配、逻辑工作集与实际后端边界 |
| [BATCH](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 | BAT-REQ01/04/OP04：完整尺寸与真实源/显示责任 |
| [旧DISPLAY纯视频目标](../../../planning/design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 | 行7/11/48/61/122/247：仅作为1080p60目标、时钟/扫描和数据需求来源；不继承旧物理存储机制 |

已按入口顺序读取控制面规则、运行提示词、配置/状态/台账、数据库说明和工作流；另读Approval Manifest。唯一根v0.2 SHA256=4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2，模板SHA256=99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。正式状态仍为WAITING_FOR_HARDWARE_BASELINE，未更改。

RAW行号以下绑定94F原稿，仅辅助定位；稳定引用以章节/IF/REQ为准。未调查用户排除的外部存储器件、PHY或IP，也未联网。

## B. v0.1输入的结论与优先级（当前修订状态见M）

| 编号 | 优先级 | 结论 |
|---|---|---|
| RS-F01 | P1：当前局部设计阻塞 | E7的software reset次序与C/E6的真实raw债关闭依赖相冲突，可使unknown故障恢复互等。 |
| RS-F02 | P1：当前局部设计阻塞 | E4无条件按typed响应消费释放journal，不能覆盖post-LOGICAL_COMMIT的unknown/partial失败；缺实际债/未发suffix/INVALID退休分支。 |
| RS-O01 | P1：架构OPEN，非新增局部错误 | 64MiB PC byte service加115200 UART可作为极慢全尺寸算法验证候选；没有生产camera/HDMI backend的容量、最坏服务曲线和真实I/O合同。 |
| RS-O02 | P2：实现前必须冻结 | journal必须逐byte/重叠区间forward与合并，不能仅以postimage起始地址相等识别重叠；D5/E4已要求保邻位，但RAW-B01尚缺实际局部实现合同。 |

主稿对PC仅copy bytes、算法在FPGA、失败不发布半图、Q不自动恢复、原始资料只读及硬件闸门的表述诚实。两项局部修订即使关闭，也不能关闭RAW-B01…06、R4真实provider/目录、VIEW跨稿、R5生产视频或整包NOT_READY。

## C. 当前合同可保留的部分

RAW-O负责目录/授权/refs；RAW-S负责typed操作、逻辑原子提交、latest与phase；RAW-A负责有限仲裁及raw关联；RAW-L负责UART packet/CRC/期限；RAW-P只做实际有限byte读写和PC侧真实ledger；RAW-K镜像真实父消费的状态或真实REPLAY OUT，不增加第二CS消费者。主稿行83…97已作这一分工。

IF03 raw RQ707/RSP725、IF07 CLOSE231/ACK442及IF08 TERM469的字段算术一致；RAW原码族不应blindcast为R4C reason5、RC reason6或R3 reason8。正确ACK的source_accepted/cutoff、created/settled、closed位、overflow以及冻结echo分别承担真实证明，CRC不替代这些证明。错误raw回复不解除陌生credit；正确失败关闭可以结实际债，但原错误仍阻结果发布。

正常组可以沿用：授权/完整保留postimage→一个LOGICAL_COMMIT→全部raw write真实成功并无pending→typed success→phase/immutable COMMIT。正常局部S close只结束访问会话；目录O对象/immutable结果/borrow生命周期另行结束。R4C行145…153、R4R行128…132/159…163及VIEW行135…149与这一区分一致。

## D. 具体问题、证据和最小修订

### RS-F01：fatal raw debt与software reset互等

**证据。** RAW C行93/97及E6行264规定raw CLOSE可在expected/effect_debt仍存在时提出，证明后S才结束自身typed债、父才得到TERM/返还；D4行148…154也如此。E7行270却把software reset写成“cancel→子quiet→borrow/private退还→rawclose→CONTROL授权→新S”。R4R E9行335明确本地停止不等O私有退还，O退还等真实会话关闭；VIEW D5行184要求QUIET包含真实对象退休/unknown消失。

**反例。** 旧CLAIM/OBJ write已提交或发出，得到settled0 UNKNOWN。父发software reset。S要真实raw CLOSE_ACK才可清effect_debt/完成typed CLOSE，子级因此不能quiet；RESET若按E7先等子quiet/private返还才发rawclose，双方都无可推进事件。PC自己的writer即使已经安静，也不会自行产生FPGA尚未提出的完整CLOSE echo。这不是增加期限即可消除的环。

**最小修订。** 区分“登记停止意图/封新业务”与“已真实quiet”：
1. 先记录同沿旧fire/commit，登记cancel/quiesce，停止新普通组和新source/build/view；继续兑现旧published typed/raw/packet/NUM/通知。
2. fatal/whole-arena reset路径独立推进raw CLOSE：旧held raw RQ已履约后锁cutoff，即使credit/effect_debt仍在也提出；typed CLOSE可同时锁截止/等待其自身实际证据，不反向阻rawclose。
3. 正确raw证明及旧data本地排空后，才让各S结债/结束effects、形成typed CLOSE证书及子TERM；错误/缺失证明为PROOF_PENDING/Q。
4. 父真实消费子终态、完成O私有/最终对象与borrow返还、K旧通知发送及控制回执排空后，才形成arena TERM/全域QUIET，授权新epoch/session。
5. 正常非fatal局部LOAD→CLOSURE→RC→VIEW不关闭整个arena；这是另一个路径，不能把whole-arena次序套成每次typed close都要global close。

修订C、E6、E7、T11/T17/T18及H的同一依赖顺序；终态本身及其最终发送通知不能纳入形成自身的empty谓词。未知义务仍不保证固定周期成功结束。

### RS-F02：post-commit失败时journal过早释放

**证据。** D3行138…140要求unknown响应即使关联已结，仍保留effect_debt KEY/journal/ref。D5行174保留已逻辑提交的完整双效果/latest，无rollback，失败全private build无效。E4行246/248要求postcommit失败保留journal/事实；但行252无分支地写“typedfire后后续旧槽空才释放journal”。typed失败响应消费只证明通知交付，不证明底层unknown效果已闭合，也不能自动把尚未发出的同组suffix记作物理成功。

**反例。** CLAIM预留CLASS-byte与QUEUE-word，并在eK一次LOGICAL_COMMIT写入受保护两postimage/tail。CLASS raw WRITE成功；QUEUE raw WRITE得到UNKNOWN，实际可能发生部分或全部效果。typed failure被client真实消费、rsp槽后续为空。若依据行252释放journal，其两postimage/逻辑tail/未知KEY归属可被下一组覆盖，而raw CLOSE证明仍未取得。甚至known NONE/第二write失败时，“clean release”也必须与INVALID private build的失败退休区别，不能让partial后端再次成为合法latest或phase输入。

**最小修订。** 逐分支明确结算：
- precommit拒绝：未创建任何可见logical效果；仍需已经提出的读/响应/授权义务实际结束后退未用reserve。
- success：全部已保护postimage物理SUCCESS、raw expected/effect_debt/dirty均0、typed success已消费及旧槽空后，允许clean journal释放，随后phase核自身完整屏障。
- postcommit已知失败/取消：锁组INVALID和已发生效果；不回滚CLASS/QUEUE/tail任一半。禁止新读者/phase/immutable发布；列出已发与未发suffix。未发suffix只能在停止门真正保证以后不再提出时注销未来执行资格，不能增“成功write/settled”计数。
- unknown/坏echo：KEY、postimages、logical_commit/tail和effect_debt保持；typed失败已消费仍不足以释放。真实raw关闭证明及本地旧published义务排空后，才能按失败关闭结真实效果债。
- 安全失败退休：必须证明组已经INVALID、无可再执行的suffix/旧published读写、全部真实raw债已关闭、无可再读取forward的访问者、typed响应/关闭及证据保存义务完成；再释放受保护journal。失败退休不要求假造所有postimage物理SUCCESS，也不把dirty0重新解释为正常COMMIT资格。
- 缺证明/Q：继续隔离/保留，不接受下一组覆写，不借软件reset清日志。不得让journal退休等待O先回收、而O又等待尚不能形成的typed关闭；会话pin关闭与失败证据保留需分别列事件。

以group metadata的logical_commit、entry_count、dirty/completed、每entry physical_state/cause及raw effect_debt共同定义谓词；没有必要为了该修订新增另一整图。完整FSM/关联表及不同typed族的settled/pin证书仍RAW-B01/B02，不以文字候选当已经实现。

### RS-O02：重叠packed spans的附加冻结要求

D5行174称“凡查同addr先forward”，E4行248要求跨相同byte合并。实际bitpacked 21bit相邻item的起始地址可能不同却共享末/首byte，例如item276从byte724 bit4开始、item277从byte727 bit1开始，span重叠byte727。该例仅说明通用packing合法地址，不假设它一定是某幅图生成的rho组合。局部合同须以每个受保护byte或区间交叠及最新顺序合并，不能只比较两个RQ起始address。未来T02/T06含非相同base的partial overlap canary；这是对已有保邻位要求的实际冻结条件，目前不把它认定为主稿明确允许覆盖的新增错误。

## E. 修订后的中文失败路径走查（提议）

e0旧typed RQ fire锁ctx，之后授权/RESERVE；eK旧allprepared才LOGICAL_COMMIT。eK+1以后实际raw WRITE。发生failure/UNKNOWN或cancel的沿先登记旧WRITE/RSP/commit事实，再注册停止原因，冻结已发生/未发生效果分类。下一旧STOPPING不新创建组或suffix，但所有已经published请求、packet和响应继续交付。

RESET只提出关闭意图，不赋值closed/returned。raw CLOSE独立真实fire，PC真实结束自己已接纳效果并发送旧data后形成ACK；FPGA先消费旧data，后续旧empty校验证书。证书合格后S才结效果债并给typed关闭证书；失败build无发布资格。父收到实际子终态后O按真实清单返还私有refs和borrow，journal按失败退休谓词结束；末通知/K/control实际发送/消费后才有全域QUIET和新epoch资格。

lost请求导致accepted≠cutoff、缺ACK、wrong echo、未知NUM或provider借用均留在PROOF_PENDING/Q；消费失败通知仍不复用单图slot。此走查为设计修订建议，未运行时序仿真。

## F. 容量、通信、资源与生产边界

### F1. 能证明的容量

RAW D5行164：17,526,269B识别工作量＋8,294,400B GRAD＋6,220,800B SRC＋259,200B EDGE＋518,400B CLASS＋8,294,400B QUEUE＝41,113,469B；EDGE只计一次。加guard、64项最坏对齐及PROFILE128B为41,183,165B，64MiB余25,925,699B。这是候选PC数组可容纳的逻辑算术，不证明FPGA整机资源、实际分配成功或已有真实生产backend。

目录64×640/pin64×512/journal16×576及packet容器候选合11个RAM10，字段算术无新增矛盾；本数字只含本层，不含全部算法ROM/window/控制器/FF/CRC/实际packing端口。RAW-B01/B04继续要求完整实际映射。64pin/descriptor满须显式失败，不能隐藏第二帧或无限host队列。

### F2. UART理想下界与真实能力

RAW D7行194…210的新协议为8N1，nominal115200→11,520wire B/s。固定RQ89B+10B framing、RSP91B+10B framing，每个raw读写事务至少200wire B，单信用stop-and-wait：

| 分析项 | 理想下界/上界 | 限制 |
|---|---|---|
| 每次最大64B READ | 有效吞吐最多3,686.4B/s | 尚未计PC/USB/CRC/算法/反压；小record/RMW更慢 |
| 仅读完整SRC 6,220,800B | 至少1,687.5s＝28.125min | 不含初始化、算法多遍、写回、ANN或输出 |
| 一遍最大POINT 16,588,800B | 至少4,500s＝75min | 不是完整识别时间或实际测量 |
| 全P个OUT404观察 | 每pair一个CORE699 packet：88B body+10B framing；共101,606,400wire B，至少8,820s＝147min | P=1,036,800；尚未计共享链路raw/终态；当前真实输出串口候选本身也会反压renderer |

每条raw读写实际body固定，所以“64MiB容量足够”不能转化为快速试验或可连续摄像。full1080p fast raw仿真可以计划验证全部RTL算法，但不会提高物理UART吞吐。现有参考UART只是pin/clock来源；新RX/TX、parser、重同步、错误窗口/COM参数、当前I3新约束与实际串行均未实现/验证。

### F3. 为什么不能作为生产camera/HDMI backend

VIEW C行87…91明确只一个BUILD/COMPLETE slot，旧VIEW/borrow未结束不能载入下一整图；只承诺可暂停调度。ROUTE行60规定可暂停算法不能直连不可暂停相机。真实相机的接受/丢弃/选帧及正在输入的整图容量、frame cadence、CDC和回压不可性必须由R5冻结；不能把PC fixture逐字节暂停当相机能够暂停。

旧DISPLAY的纯视频目标是1920×1080@60Hz，pixel148.5MHz、pair74.25MHz候选，2200×1125总时序；刷新率与相机/处理fps独立，不要求从该条款推定每幅算法也必须60fps。mode5若从SRC/EDGE/ANN逐帧读取，三plane共6,998,400B/图、60Hz有效平均419,904,000B/s；原色本身也需373,248,000B/s。该算术只作原目标数据需求，旧物理服务/显示bank机制不继承。

RAW27MHz单域可暂停OUT/串口输出没有固定148.5MHz视频、HDMI pin/serializer、实时row供应/欠载策略及多域reset证明。若未来用独立视频域重复已处理图，仍须实际高速保留/重放整图与逐行最坏服务保证；仅增加一个时钟或safe图并不能把UART当供数backend。没有这份真实后端，不能关闭五项基础的摄像/HDMI显示，也不能把core P&R/bit当完整生产系统完成。

### F4. 本候选可以支持什么

它可以作为待冻结/待批准的完整算法core软件验证和极低速实体串行实验边界：PC仅canonical bytes，FPGA实际做灰度/中值/Sobel/Canny精确闭包、数值/识别/ANN/render，动态输入与完整输出防综合裁剪；完整core合理真实pin的P&R/STA/bit证据可证明相应core工程。所有这些现在仍NOT_RUN/未实现。它不能据此证明SC431HAI持续摄像、无闪烁1080p60、全部五基础/六高阶生产系统或硬件人工验收。

## G. 后续纯文字场景（全部NOT_RUN）

| REVIEW-TEST | 场景 | 必须观察的期望 |
|---|---|---|
| RS-T01 | UNKNOWN effect_debt存在时software reset；typed CLOSE与raw CLOSE任意停顿 | raw关闭提议不等子quiet/目录返回；正确proof后才子TERM/refs/QUIET；缺proof留Q |
| RS-T02 | CLAIM逻辑commit，CLASS成功、QUEUE unknown；typed failure先被消费、raw ACK迟到/丢失 | 双postimage/tail/KEY保持，不能按rsp空释放；正确关闭才失败退休，Q禁止新组覆盖 |
| RS-T03 | 同上改为known NONE/PARTIAL/FULL，或cancel在LOGICAL_COMMIT同沿 | 记录真实前缀；未发suffix明确不再发、不计成功；完整组从不半回滚/假phase |
| RS-T04 | DENSE16最后或中间write失败、重叠但不同base spans | 所有logical票值成组可见；latest保邻位；物理失败仍阻COMMIT；真实close/evidence后退休 |
| RS-T05 | raw/typed close错echo、ACK先到末data fire、lost RQ cutoff不等PC accepted | 错body不清credit；后续旧empty校验；不补accepted/不伪source_settled |
| RS-T06 | K旧OUT/child TERM held、raw CLOSE已完成、cancel ACK仍在途 | CORE通知仍兑现；arena TERM形成不等其自身发送；新epoch不越过旧观察/wire/control |
| RS-T07 | 旧VIEW借用、RECORD辅助引用、全部私有CLASS/QUEUE/GRAD/POINT等返回 | 全部真实O记录闭合；CL/RC drained/raw closed不替private_refs_retired |
| RS-T08 | 全1080p数学/协议/质量GT与实际串行输出分别执行 | core计算在RTL，PC memory无算法；分别报告fast仿真和115200wall时间，不拿小图/低指标替原范围 |
| RS-T09 | fixed视频行服务、不可暂停源、单slot正被VIEW占用 | 另由R5冻结实际资源/丢帧语义/最坏期限；UART只读事实不足以判生产通过 |

测试只为未来获批后实施计划；没有生成检查器、Python业务/参考模型、TB、functional runner或工程。协议oracle须从实际各层fire与效果独立派生，不能从DUT TERM flags抄黄金；数学/质量GT和PC原始byte服务独立。

## H. 双向追踪

| 发现/要求 | 受影响职责/接口/操作 | 未来场景与修订入口 |
|---|---|---|
| RS-F01 / RAW-REQ05/07 | A/S/L/父RESET；IF07/09；C关闭图、E6/E7；R4R E9、VIEW D5 | RS-T01/05/06；同步RAW-T11/T17/T18/H，不改变原原因/身份码族 |
| RS-F02 / RAW-REQ04/05/06 | S/O/journal；IF01/03/07；D3/D5、E4/E6；typed settled/pin/phase | RS-T02/03/04/07；同步RAW-T05…08/T10/T18/H与RAW-B01/B02 |
| RS-O02 / RAW-REQ03/04 | byte packing/latest合并；AR/AP span；D5/E4 | RS-T04；RAW-T02/T06；实际局部FSM/原生RAM端口仍OPEN |
| RS-O01 / RAW-REQ01/02/08、BAT-REQ01/04 | 本域PC容量与串口、完整core、生产R5/视频/源 | RS-T08/09；RAW-B03…06/R4/VIEW/R5，不能以core工程证据闭生产责任 |

目前所有实际源码/基线/波形/退出码/综合网表/resource/STA/bit/串口证据均“未实施/未运行”。报告中候选修订名称不是已有业务单元。

## I. 门槛与批准

以下为94F原稿门槛；最终v0.2的两项修订复核见M。两个P1局部问题未修订并读回复审前，RAW局部合同有阻塞。即使修订完成，完整目录/typed服务、源码语言/全FSM、PROFILE/source/RECORD安装、真实transport/工程、full1080p独立GT及生产性能还未冻结，不能把READ_ONLY_REVIEW结论改写为READY_FOR_REVIEW或用户已批准。不要求先跑尚未获准的业务构建来补设计成熟度；批准后的实际证据仍是另一阶段。

人工硬件闸门保持，bit之后的下载/观察当前不执行；终态消费不等硬件验收。原十一项/质量标准、完整尺寸及任意旋转/遮挡等原要求未降标，A3既有DEFERRED处理不在本报告隐式变更。

## J. 变更与恢复

只提出主稿纯文档修订：明确fatal/reset的单向关闭次序和journal成功/安全失败/unknown三类退休谓词。根代理应保留94F输入版本、改指定主稿版本/trace并实际读回新hash，再请求只读复审。不得在缺失后端/性能条件下将64MiB+UART提议默认为生产架构批准；不重新启用已排除的器件路线。

## K. 本次实际记录

实际执行仅本地文本读取、hash/bytes核对、静态字段/容量/带宽算术及创建本报告。未改任何主稿、业务源码、业务脚本、参考模型、可执行测试/TB、原资料、工程或SDC；未运行仿真/综合/PNR/STA/bit、串口/设备、网络/安装或外部存储器件调查；未写Manifest、正式状态或数据库。本报告创建后实际全文读回和最终hash在任务回复中报告，随后停止编辑。

## L. 阅读与交付

先B的两个局部阻塞，再D的反例/最小修订和E的关闭路径，接着F的容量与生产边界，最后G/H的未来场景和追踪。允许继续的是版本化纯设计修订与独立复审；完整软件/RTL/Efinity工程、仿真/综合/布局布线/引脚/时序/bit目标尚未完成。人工理解验收待用户实际反馈；没有作答不声称已理解。

## M. 最终v0.2修订复核（同轮补记）

根代理保留[94F原v0.1不可变快照](../../../planning/design-TRACK4-ALGORITHM-RAW-STORE-001-v0.1.md)，并最终停编辑后提供当前[RAW-STORE v0.2](../../../planning/design-TRACK4-ALGORITHM-RAW-STORE-001.md)。实际完整读取与完整差异核对输入：

- 原v0.1：94F0327B10081903D4C034B136A46DD1B8962337C71F59FC357C9DACADD4D799 / 61325B。
- 最终v0.2：7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD / 64846B；同一次读取前后SHA256完全一致。
- 已实际核对原快照→最终主稿的全部差异，并复读D5/E4/E6/E7和T17邻文；未改变的段落沿原全文审阅绑定。中间3EC3/98DB被最终稿替代，不作为本报告最终结论输入。

### M1. 两项原局部反例的关闭

RS-F01在**文字设计层面关闭**：当前E7行274/T17行323区分健康正常关闭和raw故障/unknown/子quiet依赖raw proof的路径，后一条独立先推进raw CLOSE，与typed close并行；不等子quiet/父O退休才提出真实证明。该次序和C/E6、R4R E9及VIEW实际QUIET义务相容。永不ready或缺proof仍停留/Q，未承诺实测活性或固定周期完成。

RS-F02在**文字设计层面关闭**：当前D5行174新增每entry published1/settled1/effect2/written7＝11bit，16项共176bit FF；不新增16路raw credit/KEY，原journal576/外部body未变。E4行254正常成功要求全部SUCCESS/settled、raw债与pending/引用空、typed RSP真实消费后的旧空沿才释放。行256新增INVALID_SETTLE，postcommit失败保持完整logical_commit/postimages/tail；未published suffix停发并作为INVALID失败处分，不能标SUCCESS；failed typed RSP消费不释放journal。

行256又明确：正确raw CLOSE只证明已published操作没有未来effects，不提供unknown写入的最终前缀；effect=UNKNOWN、written0、cause和first evidence继续保留，独立entry.settled不改旧RSP、不增success。这样允许安全失败结债/退休，却不把未知物理效果伪造成确定字节结果。S内部postimage权限/held/RAM pending/引用真实结束后才退休日志；本地借用空不等待父O退休或本组typed CLOSE_ACK消费，该ACK只读独立冻结台账/终态，不再借journal，避免新的回收/通知循环。缺proof/Q继续保留。

这些结论仅关闭本报告给出的两项局部反例，完整RAW-S/A/O/L状态机、逐typed映射、保存证据的实际容器及组合仍RAW-B01/B02。RS-O02的重叠span冻结要求、RS-O01生产架构缺口继续OPEN；未发现本次修订新增明确协议矛盾，不据此判全稿或全系统ready。

### M2. 最新用户边界：板卡现有资源，PC不作生产存储

用户最新限定只用板卡现有资源；DDR继续排除，不增加存储模块。最终v0.2行5已明确PC64MiB/串口仅为逻辑仿真与低速观察候选，不属于允许的板上生产工作存储，不关闭生产容量/带宽/camera/HDMI门槛。本报告F1/F2对PC容量与速度的算术只说明该debug候选；不能拿64MiB当板上已有资源，也不能把PC byte service改称生产runtime。

现41,113,469B是当前这套完整CLASS/QUEUE/GRAD/POINT/识别工作容器同时保留架构的逻辑需求，不是对所有可能精确算法改写的不可减下界。后续可纯设计比较现有板载资源、分期寿命/重算/packing及完全等价的算法，但必须逐项证明容量、端口、有限终止、全部结果和最坏服务；不能暗中缩图、截候选、固定闭包轮次、增加外部存储或降低既有指标。当前硬件资源架构尚未冻结，本轮也没有新的板载存储来源调查。

### M3. 最终交付状态

B/D/I保留94F原稿的历史发现与修订建议；当前两项发现状态以M1为准。RAW-B01…06、R4C/R4R真实后端与目录、VIEW跨稿组合、生产R5以及完整软件/Efinity工程/pin/STA/PNR/bit证据仍OPEN/NOT_RUN，整包仍NOT_READY/未批准。根代理负责把新后端与五类剩余合同合并成成熟版本后再进入指定评审，不能用本次局部关闭替代它们。

本报告只在授权的唯一报告路径追加这一复核记录，未改主稿或任何实现/正式状态。最终文件实际全文读回/逐字一致和SHA256由回复绑定，完成后停止编辑。

