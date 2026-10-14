# TRACK4-ALGORITHM-R4-CLOSURE-001：精确Canny闭包、单S物理桥与对象交接设计 v0.3

2026-10-05；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本文是[整包R4](design-TRACK4-ALGORITHM-BATCH-001.md)的精确闭包局部候选。v0.3将已核的单S、32bit/16B物理桥及CLASS→CLO→EDGE发布增量吸收入本主卡；具体后端资格、完整资源与服务上界仍OPEN，没有存储服务或完整bundle实现。修订前v0.2原始字节见[精确快照](design-TRACK4-ALGORITHM-R4-CLOSURE-001-v0.2-before-physical-bridge.md)，63263B / SHA256 `5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11`。

## 通用计划字段

- Goal：从完整R2分类对象得到精确八邻域强种子可达集合，规定CLASS/QUEUE/EDGE完整容量、单真实S/sequencer、32bit地址桥、两16B成对postimage、真实初始化/提交/关闭、全N导出及独立不可变发布。
- Current state：本次实际全文读回v0.2主卡和闭包缺口审阅，重读入口/唯一规范/模板及A2所列交接边界；旧BATCH/R2/CONTROL/REPLAY来源作为历史设计引用。R1已有实作交付只属R1证据；本闭包没有业务实现，R2 v1/48输入保持只读，不由本版决定其批准状态。
- Target state：完整1920×1080分类加载→提交证书→强种子→精确闭包→全部N边缘→独立关闭证书→不可变EDGE交接有可检查合同；后端及父层闭合后纳入整包指定批准。
- Gap：B01真实DDR资格/两entry journal/后端微服务，B02完整holder与353/1013/1150新内部交接，B05文件/schema/有限测试/全部存放和共同基线尚未冻结；B03识别/完整bundle和B04生产IO保持未来范围，不用未来功能掩盖当前必需的S/O交接。
- Assumptions：单core域、typed接口可暂停、单J/单scratch、一个已绑定S写会话；静态W为偶数6…1920、H5…1080，生产1920×1080；只使用板卡已有DDR，不新增外接存储/PC生产计算。不作环形像素/短工作队列，不新增算法fps门；成功时间须有限后端服务与消费前提。
- Open questions：见A。主机数组只是独立软件验证后端候选，不能当Ti60片上RAM；不使用小图、空stub或分类图代替全1080p最终边缘。
- Dependencies：唯一根v0.2、模板、历史BATCH/R2/C0/CONTROL/REPLAY规则，以及A2当前LG/DIR/RAW/PB/INTEGRATION/PERF限定边界和不可变审阅；不继承旧917bit job、phase_key、旧26bit/PC生产存储或未联合采纳的能力cache。
- Milestones：整体集合→owner/容量→接口/提交与组合→局部旧沿/关闭→参考/验证/追踪→真实后端及父组合→独立审阅→整包批准→获批实现/工具。
- Detailed steps：B最终行为→C唯一owner和共享实例→D原typed/新物理与发布IF→E加载/初始化/原子提交/种子/BFS/导出/关闭/目录接力→F逐操作数据/服务/语言账→G/H独立验证与追踪→A/I具体阻塞。
- State transitions：只在本文记录LOCAL_DESIGN；不改正式H0、Manifest、数据库或任务状态；保存候选不等于READY或实施批准。
- Artifacts and hashes：A列实际来源hash；本文保存后全文读回hash另报，不自引用；当前没有实施源码/Git提交或全包冻结基线。
- Validation：集合数学、实际握手/原子可见性、全图软件结果、资源/综合/PNR/STA各自验证；G全部NOT_RUN。
- Failure handling：先计旧真实fire，保留各自不同前缀；坏回复不能清credit；独立CLOSE不等credit；无真实关闭/返还证据保持隔离，不发布EDGE或复用他人对象。
- Human approval gates：完整设计版本/实现范围/共同基线指定批准；本页NOT_READY，无业务实现授权。工作副本、构建、数据库与人工硬件闸门仍适用。
- Rollback：本轮只允许修订本主卡和创建其v0.2精确快照；其它设计、资料/HDK、业务目录、R2 v1/48输入、R1交付、正式状态/Manifest/数据库保持只读。快照使用拒覆盖复制并核前后同hash；未来受影响实现只在获批work中进行。
- Completion criteria：本局部文字/读回/审阅齐全还不能关闭R4/B03/B05；批准前须冻结可综合的真实全N后端架构、容量/端口/可见提交、对象目录/组合及验证计划，再统一批准；获批后实际实现并取得软件、网表/资源/时序等工具证据才算任务完成，不要求先实现才能READY。

## A. 状态、实际来源和阅读入口

任务R4C=TRACK4-ALGORITHM-R4-CLOSURE-001，关联BAT-REQ02/04/05/06、T4-A4及后续A6最终EDGE输入。阅读本文A2当前差异→B/C整体→D组合→E/F局部与代价→G/H/I。历史“排除DDR”已由用户后续“允许使用板卡现有DDR3”撤销；仅用现有资源及完整1080p/Canny要求仍保留。Root本轮委托只修订指定两份文档，不批准生成代码/参考/脚本/TB/工程或执行EDA。既有R1批准不覆盖本R4增量，R2审批对象由Root单独管理。

| v0.2继承的历史来源（非本轮全部重读） | 读取时SHA256及采用范围 |
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

上表保留v0.2作者的历史阅读事实，不把本轮有限核查写成这些来源的全文新审。来源可以变化，引用不是共同冻结基线；下表才是本轮实际阅读/hash。本文拟实现符号均属计划；已有R1/R2流段或public DDR端口不证明S/O适配已经存在。未解密protected内部、未重新运行IP/工具。

### A2. v0.3实际采用来源与读回范围

实际依入口读取AGENTS、config规则/运行提示词/路径、state/ledger、DB README及Manifest；DB记录仍NOT_CONFIGURED，未执行数据库动作。唯一规范全文1–919、模板全文154行；本次读回源均区分全文与限定段，SHA为实际文件计算。

| 当前来源 | 实际读取范围 / 总行数、bytes | SHA256与采用边界 |
|---|---|---|
| [v0.2精确快照](design-TRACK4-ALGORITHM-R4-CLOSURE-001-v0.2-before-physical-bridge.md) | 修订前主卡全文1–346 / 346、63263 | `5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11`；原集合/公共typed/关闭全部保留 |
| [闭包缺口审阅](../experiments/track4_algorithms_20261004/03_review/canny-closure-implementation-gap-review-v0.1.md) | 全文1–174 / 174、31929 | `8A90E72661E94821CEFB8D77B0F3D1FB70D3468223092E5486D58A9BC7E48CAA`；ΔCLOSE-01、地址反例、postimage/初始化/发布与数据账 |
| [LOAD/GRAD](design-TRACK4-ALGORITHM-LOAD-GRAD-001.md) | 97–174、279–324 / 393、67457 | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；LG1119/fullJ、唯一BIND、三scope/191词及独立SRC/GC，不改原body |
| [production-directory](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | 69–158 / 231、34598 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；32bit、descriptor/pin/fullholder、journal、初始化及无writer发布 |
| [RAW v0.2](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 104–180、228–276 / 367、64846 | `7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD`；latest/原子组/INVALID_SETTLE/关闭采用，旧26bit/PC生产后端不采用 |
| [PB](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | 全文1–162；134–158补读截断 / 162、26058 | `0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40`；单issued burst/16B/fullWSTRB/route/W_CTX及UNKNOWN边界 |
| [STAGE-CAPABILITY](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | 90–178 / 298、43441 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；仅核唯一grant/RETURN/admin/CLASS→CLO边界，未采用hotcache |
| [INTEGRATION v0.8](design-TRACK4-ALGORITHM-INTEGRATION-001.md) | 119–143 / 271、51540 | `C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF`；DR201/713/731/AP472迁移与typed/raw分层 |
| [PERFORMANCE v0.2](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | 169–221 / 396、58487 | `A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469`；固定地址/N容量、logical工作量和未计M_i |
| [DDR服务预算读取版本v0.2](design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md) | 全文1–307 / 307、46443 | `2B867BD40D53E834F36C0CC6E1FD68AC8B30FAA46AB43692B1D7A9D11470AD7C`；单实例、条件服务/eligible backlog、非fps；Root可并行修订，本hash不是其未来版冻结 |
| [当前Manifest](../config/APPROVAL_MANIFEST.yaml) | 全文1–106 / 106、6558 | `7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D`；仅既有预检/R1授权，不登记本版审批 |

审阅中实际C2 public wrapper/parameter证据只经不可变审阅A2引用，本次没有将旧读取范围署成新全文，也不把axi_ram常量OK视为DDR事实。最终保存后重核本表路径/hash；若DDR服务预算并行变化，保留这里的实际读取版本并明确差异，不自动吸收新内容。

| OPEN | 影响、缺口与后续责任 |
|---|---|
| R4C-B01 | 已选择单S无cache、32bit/16B桥及两journal postimage，但实际IP接纳/响应/可见性/无未来effects资格、完整RX/holding/原子记录端口与微调度、UNKNOWN实际关闭、每操作lookup次数和服务上界未冻结；不是“尚未选后端”也不是后端已完成。审批前闭合这些设计与有限验证方法，真实运行/网表/STA属获批后义务 |
| R4C-B02 | 保留原LC/CLJ/body，明确fullLG/holder独占及RETURN→CLOSE_ACK→term接力；新353初态证书和1013/1150 O发布只在本版提议。其完整运输/回执/replay/原因映射、证书真实存放/寿命、admin授权/父历史与跨epoch桥未共同冻结，裸ref/token不授权 |
| R4C-B03 | 原RGB、可选GRAD提交、识别候选/拟合/核验/去重/ANN及完整bundle注册目录另设计；本文成功只证明最终EDGE，不证明CANNY_RC整体成功或真实APPLIED |
| R4C-B04 | REPLAY的实际EDGE source绑定/底层独立读取、borrow/完整bundle资格，以及R5固定视频/CDC/源不可暂停性/生产pin/完整资源仍OPEN |
| R4C-B05 | G新增有限故障/地址/密集图/种子与timeout方法，但确切文件/compile顺序/schema/manifest/case ID/周期墙钟数值、完整实例RAM/FF/LUT/DSP及共同输入基线仍缺；不能以175/176局部RAM或573091200B数据账当full fit/服务证明 |

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
| R4C-REQ10（派生） | 合法全图地址使用32bit/端点33bit，所有full16B读改写处在同对象已初始化rounded授权内；不能将旧26bit零扩当迁移，也不能越guard/其他slot |
| R4C-REQ11（派生） | CLASS initial保持mutable；S durable phase token与O immutable version/publication_token不同。scope真实RETURN先于typed CLOSE_ACK；EDGE完整close/CLterm及O成功发布才授新读者，不等wholeholder先RETIRE |
| R4C-REQ12（派生） | 一份真实S/物理adapter/RX/journal/native目录计全部操作、INIT及admin；读次数、逻辑effects、AXI五通道事件和物理data beats分账，有限服务/完整资源未知保持OPEN |

正常：一个10强点与长01弱链含斜连接/环/分支→所有同候选连通分量被保留。断开链后远端没有强种子的弱分量全0。边界：S=0→全0，Weak=0→仅原10为1；S=Weak=0优先no-strong；两条均不运行QUEUE。一般路径输入10必须全部经种子扫描接纳为11，BFS后来读取10表示一致性错误。任何邻居先检查x/y再计算地址，右边界不能连到下一行最左像素。

成功是完整CLASS证书、精确闭包及全N EDGE提交、真实storage关闭和无错误/取消/溢出共同成立；不是CS0、初始空队列或某个末pair。完整CANNY_RC、bundle和显示另有R4/R5责任。COMMON rst只在全参与者共享reset且外部旧run被合法隔离时可撤事务；软件reset仍须真实关闭，不能仅改变epoch。

## C. 唯一owner、模块与整体路径

| MOD | 唯一责任及数据owner |
|---|---|
| R4C-MOD-J 父JOB_DISPATCHER | 锁CONTROL J及CJ、唯一消费C0真实CS592并保存；分配本epoch load_id/closure_id，准备collector后才启动CJ，转交不可变CS副本/资格；本文没有第二个C0 status消费者或内部FE owner |
| R4C-MOD-O 逻辑目录/交接adapter | 唯一分配/登记refs/完整holder、保353初态证书、独占转换、RETURN台账及新EDGE发布/version/token；具体运输/存放尚B02，完整bundle尚B03，数字非0不是自授权 |
| R4C-MOD-L class loader | 保存LC270/CJ、CLASS125单槽、独立seal槽、五项计数/EOF、错误与加载终态；只发LOAD_PAIR/CLASS提交，不能直接写状态RAM或消费raw CS |
| R4C-MOD-C closure engine | 保存CLJ438、head/tail、扫描/活动pop/邻居游标、导出pair、backend单credit、阶段token及终态；只发typed操作，不能绕过状态服务或回收目录对象 |
| R4C-MOD-S logical storage service | CLASS/QUEUE/EDGE唯一逻辑writer与一份真实sequencer；串行AUTH/INIT/read/RMW/两postimage/commit/write/effect/RSP/close；拥有最新值/tail/阶段/台账。无cache基线已选，实际holding/native/后端资格保持B01 |
| R4C-MOD-P 共享DDR byte adapter | 按真实permit/grant/旧route发32bit地址、16B子集与独立AW/W/B/AR/R并核effects；与camera/import/ROW/SRC/GC/RC共用单物理引擎/RX/journal，不能免费复制。它不运行BFS、不生成S/O token，完整共享调度仍B01/R5 |
| R4C-MOD-E immutable EDGE source | 经O/REPLAY授权绑定已提交EDGE版本，兑现plane1 RQ/RR/CLOSE；不改CLASS/EDGE，不宣布整个bundle完成；实际adapter尚B04 |

普通路径：父保完整LG1119/原J与CLASS build→原LC270/BIND277/PREPARED277→O核真实CLASS INIT/各必需scope ACTIVE后才CJ→真实CLASS125/父唯一CS592→S LOAD_PAIR/CLASS_COMMIT及新INITIAL_CERT353(IF13)→本CLASS access quiet/RETURN→ACK502→LC_TERM776→父保初态证书/原term并交CLJ438/fullCLO exclusive BIND511→SEED/BFS或快路径→全P EDGE→S EDGE_COMMIT durabletoken→CLO access quiet/RETURN→ACK502→CL_TERM1013→父新EDGE_PUBLISH1013/O ACK1150(IF14)→O immutable版本→未来完整bundle/REPLAY授权→E plane1。取消走独立IF09/CLOSE；publication不是term的一位副本。

CLASS生命周期是BUILD_LOADING→INITIAL_COMPLETE且仍mutable→LOAD scope真实RETURN/close→EXCLUSIVE_CLOSURE→CLOSURE_COMPLETE或INVALID；不能把initial token设O COMMITTED。QUEUE从已初始化EMPTY_BUILD→私有append/read→CLOSED，不循环覆写旧entry。EDGE从PRIVATE_BUILD→S_DURABLE_SEALED→writer RETURN/close→O_IMMUTABLE_PUBLISHED；只有最后一步才DIR COMMITTED/immutable。O始终拥有对象，L/C/S只有明确会话职责/pin；term消费不删除对象。一般闭包改CLASS，初态token只证明起点，不许识别/显示同时借可变CLASS；原分类副本需另提容量和owner。

S在同一时刻只服务一个已绑定load或closure写会话；CLASS scope自己的旧数据/effects→RETURN→正确ACK502→LCterm消费及单S会话结清后才CLO exclusive BIND，不要求SRC/GRAD scope或wholeLOAD holder先FREE。三scope父历史/returnedmetadata继续保存；GC独立close→parent O GRAD publication，不塞进原RQ324信用或阻真CS。当前最保守单J先汇合SRC/L/G相关义务再普通闭包；以后重叠须另证共享实例/身份与公平性，不能直接当并行预算。

整体设计检查点：先明确完整分类和最终EDGE的界限、逻辑容量/唯一写owner、原子接纳/提交/关闭及全N输出，再进入D/E。本文不提供已有帧存储，也不把旧物理授权和phase消息带入新路线。

## D. 身份、容量、端口与组合检查

### D1. 身份/字段和逻辑容量

所有body unsigned；同core沿前valid且ready且非rst为fire，valid/ready不计body。字段表列高到低，组合内部按注明layout；JID96按命名epoch/frame/config字段适配CJ/CONTROL，不能整段盲cast。H160=JID96/operation_id64，load口operation_id是load_id，closure口是closure_id；角色端口分开，S会话/关闭查找键必须含端口角色，不能仅用同数值H跨族查表。若实际adapter合并两族须另携带角色/隔离证据，不能去掉这一前提。父J是这些新增序号唯一分配者，next0/最大值一次/不回绕；与CONTROL新增计数及软件epoch重建桥须B02联合修订。S每会话tx_seq64从0，单信用；新RQ提出前须同时检查tx可分配及真实request台账可增，达到耗尽只关闭已得义务；已held火导致overflow仍照计并隔离，不回滚旧effects。commit_token64由S唯一分配非0版本，须在op5提交前有可分配资格，耗尽不得伪造token或复用旧版本；不能用tx_seq或raw handle冒充。

LC270=CJ142/load_id64/class_build_ref64。CLASS_SEAL863=原LC270/stream_started1/原CS592；stream_started1时CS来自J已真实接纳并锁定的副本，L不能再接C0 raw端口。stream_started0仅允许J证明从未真实启动且没有held CJ义务，CS592必须全0而不解释成原CS成功；它用于准备后取消而未启动C0的源关闭证据，不能伪造一个未发生的status。CLJ438=JID96/closure_id64/class_ref64/class_initial_commit64/queue_ref64/edge_build_ref64/W11/H11。class/edge ref及class_initial_commit非0，并由目录/真实S绑定记录核验；queue_ref允许0仅限S元数据证明S=0或Weak=0的快路径，一般分支必须实际N容量非0ref。闭包W/H须等静态实例及已提交CLASS元数据。

| 逻辑对象 | 容量/布局/生命周期与生产数量 |
|---|---|
| CLASS | N个2bit状态，index=yW+x；bit[2index+1:2index]，00/01/10初态、11接纳；ceil(2N/8)B，生产518400B；新load必须覆盖全部N，末byte padding显式0 |
| QUEUE | 非环N个32bit entry；x[10:0]、y[21:11]、高10bit0，entry index0…N−1；4N B，生产8294400B；只有index<tail逻辑有效。v0.3 full16B RMW前仍须真实rounded CLEAR，不能据逻辑无效免物理初始化；tail=N后不能append |
| EDGE | N个1bit，bit[index]，ceil(N/8)B，生产259200B；所有N均显式写入，末byte padding0；S EDGE_COMMIT后还须RETURN/close及O immutable发布才授外部只读 |

生产N2073600、P1036800，合计9072000B约8.652MiB；不含RGB、GRAD、ANN、识别工作区/目录/pending/对齐及任何多副本。6×5的N30/P15分别8B/120B/4B，CLASS末byte高4bit0、EDGE末byte高2bit0。字节内最低编号像素在低bit，跨byte依编号递增。逻辑byte数不是物理授权/实际RAM组织；真实后端对齐/写粒度/尾部读改写不得越界，相邻对象保护仍B01/B02。

CLASS/QUEUE/EDGE数量显著大于流窗；主机数组可验证数学/逻辑接口，不能声明这些对象装入片上RAM。本版采用已有DDR的固定候选：CLASS base `0x03A40000` / QUEUE `0x03B40000`、EDGE当前真实build slot；不改PERF/DIR地址或额外分配。合法QUEUE entry `1,245,184` 的byte地址=`62,128,128+4×1,245,184=67,108,864=0x04000000`；26bit截断成0会落SRC0，直接证明旧64MiB合同不相容。base不是权限，全机映射/服务/资源仍须联合，不借OBS或R1局部预算证明全机。

资源比较报告明确指出，指定CLASS2/QUEUE32/EDGE1容器满容量下界为405/6480/203个10Kbit块（合7088），不是Ti60可容纳的布局；原生模式有效容量/读写兼容族及同址/端口进一步限制推断。203bank只覆盖一份Nbit平面，还需要原candidate重放及真实读改写，不能自动覆盖CLASS、原RGB、GRAD或ANN；Candidate1+A1紧凑下界405，独立两个203bank平面至少406。此处只沿用历史比较；本版已选DDR桥候选，但比较不证明其完整资源/服务，B01/R5保持OPEN。

### D2. 端口与有限容量

| IF | body、方向 | 前置与结果 |
|---|---|---|
| R4C-IF01 LOAD_START/BIND | J→L LC270；L→S同LC270 bind、S→L echo270/status2/reason5共277 | L旧IDLE/终态空、独立bind回复槽；e0只锁输入，下一沿校验；S核真实class build容量/独占记录。成功status0/reason0；合法拒绝status1/合法非0reason且未建立pin；2/3及非规范回复非法 |
| R4C-IF02 CLASS | C0→L原CLASS125，低class4，其余sideband121 | 单held接纳槽，旧槽空、本job已ARM且PREPARED已真火、无旧错误/cancel才ready；原lane0低2bit，x/y/IDs/标志layout沿R2；先记真实raw fire，再核身份/坐标/00/01/10/外框/末组标志；不能以当前数据合法性组合撤ready |
| R4C-IF03 CLASS_SEAL | J→L CLASS_SEAL863 | 独立depth1槽，早失败也可接；成功必须stream_started1且CS和LC全文匹配/C0正常谓词与自身CLASS事实合格。未启动路径按D1的0/all-zero证明收尾，不等待不存在CS。L本地故障经sticky反馈J，J继续收真CS并传取消，不立即关status |
| R4C-IF04 LOAD_TERM | L→J LC_TERM776，见D4 | 单held至fire；成功证明CLASS完整与token，失败仅不同真实前缀/关闭；消费沿不接新load |
| R4C-IF05 STORE_RQ/RSP | L或C→S RQ324；S→唯一当前client RSP449，D3 | 一份held request、一份expected credit、独立回复接收位置及S held回复；请求提出后保持；成功/失败回复至少request fire后的后续沿，完整echo；L/C不能同时拥有service |
| R4C-IF06 CLOSURE_START | J→C CLJ438 | 旧IDLE/旧terminal已消费且无旧binding/事务；e0锁全文，后续核字段与S绑定，不在接纳沿读图；非法且无义务可failed_drained，不能清陌生ref |
| R4C-IF07 CLOSURE_BIND | C→S CLJ438；S→C BIND511=echo438/status2/reason5/strong21/weak21/stored_pairs21/flags3 | flags为class_bound/queue_bound/edge_bound；status0/reason0且CLASS完整同initial token、S+Weak≤N、stored_pairs=P、class/edge资格有效、general队列N容量empty才能成功。快路径queue0则queue_bound0；拒绝status1/合法非0reason、counts/flags0且无新binding。wrong echo/不规范回复不能证明未取得pin |
| R4C-IF08 STORAGE_CLOSE/ACK | client→S CLOSE294、S→client ACK502，D3/E6 | 与data独立，不等credit/像素EOF/P/父termready；正确截止/真实台账/settled/全部关闭/pins释放才结本会话，不能把它与REPLAY的CLOSE338混用 |
| R4C-IF09 CANCEL/ACK/FAULT | J→L或C H160；回复167=echo160/status2/reason5；L→J class_fault_sticky1 | cancel0APPLIED/1ALREADY均reason0，2NO_MATCH/reason2，3非法；仅核旧活动H，同沿新start不套旧取消；reply1独立。沿前旧IDLE无匹配活动H回NO_MATCH，不把同沿新start套旧cancel；旧活动H在正常工作首次cancel回APPLIED、已stop/closing/STATUS/GAP/Q回ALREADY。ALREADY只表示停止新业务已生效，不证明drained、pin返还或epoch可推进；终态尚未valid时仍按D4记录新增cancel原因。终态valid后全文冻结，匹配cancel仅回ALREADY不改诊断；错H始终NO_MATCH。ACK槽按旧空接纳，held至真fire；J独立接收，GAP/新start/软件epoch推进必须等现存cancel ACK空，不越过旧回复。sticky首次坏CLASS或storage故障后保持到本load终态，下一J沿注册取消；真CS始终独立 |
| R4C-IF10 CLOSURE_TERM | C→J CL_TERM1013，见D4 | 真实提交/关闭后的后续结算或明示Q快照；完整held，终态消费沿不接新job；不等完整bundle已发布 |
| R4C-IF11 EDGE_REPLAY | 已授权E→REPLAY，沿原plane1 RQ360/RR421及CLOSE338/ACK437 | 只读O已immutable发布的EDGE，同J/source/result/edge版本及borrow由O核；每口1request/read/heldRR，实际绑定/底层读取仍B04，外部字段不变 |
| R4C-IF12 PREPARED | L→J PREPARED277=原LC270/status2/reason5 | 独立held1；status0/reason0只在真实S bind成功成为旧事实后形成，status1/合法非0reason表示启动前未准备；2/3非法。J真实接纳READY成为旧事实后才可提出CJ。取消不能撤已经held的READY，J仍接纳并可选择不启动，随后给IF03未启动证明 |
| R4C-IF13 INITIAL_CLASS_CERT（本版新提议） | S→O受保护内部353bit封存记录，D5 | 真实CLASS_COMMIT数据证书；只在完整coverage/padding/effects可读且当前S/LC/完整LG相符时形成。不能推immutable；transport/回执/存放尚B02，不冒称旧来源已有353端口 |
| R4C-IF14 EDGE_PUBLISH/ACK（本版新提议） | trusted父→O 1013，O→父1150，D5/E9 | 父已消费原完整成功CLterm、本CLO真实RETURN/无writer与effects settled、完整旧holder来源才提发布；与原IF10不同口/namespace。held与返回metadata不等待wholeholder RETIRE；拒绝/UNKNOWN不推absence |
| R4C-IF15 DR_BYTE/AUTH（本版采用迁移候选） | S/共享adapter DR_KEY201/RQ713/RSP731/AP472，D5/E8 | public RQ324不能直接wire RAW707或AXI；32bit/端点33、完整rounded16B授权。原DR候选完整资格/握手/健康/关闭仍B01/B02 |

普通data容量看旧槽；旧full当沿释放不自动再用，避免新数据透传。L/C内只有一个业务request/credit，S逻辑串行；无需无限FIFO。PREPARED、CLASS_SEAL、cancel回复、STORE_RSP、CLOSE_ACK、终态各独立位置，不能互占导致真CS/关闭等数据P/EOF。

### D3. STORE事务、提交与关闭schema

RQ324高到低为H160/tx_seq64/op4/index21/expected_tail21/data32/coord22；coord低x11高y11。以下未用字段必须0，S先核全context/seq，再按opcode分派检查单位/范围/coord，合格后才寻址。op0/4以pair index核x_even/y对应原图两像素；op1/2以pixel index核原图x/y对应；op3的index是QUEUE entry/head，coord必须0，不以原图坐标等于entry号作为条件；op5的index/coord都必须0。不能用raw payload先访问RAM。opcode6…15保留非法。

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

终态规范（不改变776/1013位宽）：

- 各flags与overflow向量中，bit j对应上述列表第j项，从bit0起；LC五计数溢出为bit0…4、三STORE台账为bit5…7；CL七算法计数溢出为bit0…6、三STORE台账为bit7…9。mask bit0及15…31必须0，原因1…14各对应同号bit。loc按D1高到低列出的字段装入，无位置时全文0。
- LC flags.stream_started只取实际接纳的SEAL.stream_started：表示CJ事务是否真实接纳。它不同于CS592内部共同ARM是否发生stream_start；CJ fire后ARM取消可有SEAL=1而CS内部stream_started=0。正常COMPLETE要求两者均按各自合同成功，失败保留不同事实。
- 两类COMPLETE必须first_reason=0/mask=0/loc=0/overflow=0；request/raw_response/success_response/source_settled相等，source_settled取当前合法ACK事实。token、对象目录绑定、关闭证明及局部空同时成立，不能仅核status0。无绑定、无STORE请求的规范输入拒绝可source_settled=0而无ACK；其他有会话的drained终态须真实ACK，未取得合法ACK时该字段规范0，不从good/raw复制settled。
- LC COMPLETE：class_commit非0，六flags全部1；class_raw_pairs=good_pairs=stored_pairs=P、strong+weak≤N且与真实CS及封存CLASS元数据相等；STORE request=P+1（P个LOAD_PAIR及一个CLASS_COMMIT）。
- CL COMPLETE GENERAL：八flags全部1、edge_commit非0、真实seed/closure提交资格；seed_scan_pixels=N、seed_accepted=S、head=tail=K≤N、neighbor_checks=8K（包含越界检查）、export_pixels=N、edge_written_pairs=P。queue_started只在旧SELECT选择GENERAL的提交事件置1；BIND取得queue pin不是启动，第一claim尚未发生也不推迟该标志。
- CL COMPLETE两快路径：class_bound/edge_committed/backend_closed/local_empty/drained=1，queue_started/seed_committed/closure_committed=0；seed_scan/seed_accepted/head/tail/neighbor_checks全部0、全N/P导出且edge_commit非0。NO_STRONG的STORE request=P+1；NO_WEAK为N+P+1。快路径可能曾绑定非0queue_ref的访问pin，BIND.queue_bound与queue_started不同，该pin仍须真实关闭。
- GENERAL的独立STORE事件台账检查式为request=2N+2K+B+P+3，其中B是实际合法邻居READ_CLASS次数，不是neighbor_checks；由未来独立request-fire记录派生，不增隐藏硬件计数或term字段，也不拿公式替代真实ACK。三phase为SEED/CLOSURE/EDGE，load另属不同H的P+1。
- FAILED_DRAINED/CANCELLED_DRAINED均drained=1、合法非0first_reason且mask含首因bit，各计数/flags/token保留真实前缀，不强制raw/good/stored或数学数量相等。首次原因10CANCEL且无更早错误、义务真实closed时选择status2；有更早非取消原因则status1，后续cancel不改首因。source_settled只取合法ACK（或上面的无义务0特例）。
- QUARANTINED优先status3/drained=0，保留未知pin/credit和各自真实事实；已取得token不被抹掉，但失败/Q token不得授权发布完整对象。只有已经终态valid时才冻结所有诊断/计数；正常CLOSE/SETTLE尚未冻结term时，首次匹配cancel仍记reason10/mask并阻止COMPLETE，不因接口回ALREADY而跳过。

两term status2：0COMPLETE、1FAILED_DRAINED、2CANCELLED_DRAINED、3QUARANTINED。term形成后全文保持，不收新data/不更新冻结计数，消费沿不接下一start。非法未绑定输入可以drained1且无close/token；Q必须drained0并保留可能义务/目录隔离，token字段不能被解释成完整bundle发布证书。drained只证明本子任务取得的义务结清，不代表父目录或未启动识别已结束。

### D5. v0.3物理桥、初态证书和不可变发布的明确差异

**IF15**采用迁移候选，高到低：`DR_KEY201=S96/seq64/op2/address32/length7`，`DR_RQ713=KEY201/payload512`，`DR_RSP731=KEY201/status2/reason6/value512/effect2/written7/settled1`；原AR348不加字段，`DR_AP472=AR348/permit64/address32/first_bit3/byte_length7/record_bits10/status2/reason6`。地址/length先33bit核物理[0,0x10000000)、当前已分配生产区、logical/rounded同对象实际范围；旧OPEN256容量27无法表示整个256MiB，不把它当本新桥的有效arena建立。DR seq、typed tx、O ref/grant、stagegen、S phase token与O publication_token分别有真实分配owner/expected，不互cast。DR状态沿RAW的effect/known/UNKNOWN保证明确适配RSP449，未知前缀不猜；原typed成功effect_ok1只在本操作全部真实效果结清，phase/admin不制造0byte DR请求。

物理基线：16B对齐、SIZE4、INCR、ID0、全WSTRB；普通小随机LEN0。logical1…64B一般可跨最多5拍，拆分/端拍保护不省。每组核同对象rounded/initialized/排他权限后才读改写，不跨guard/其他slot，不以caller raw地址授权。PB的唯一issued burst、最大128拍/4KiB、R_ROUTE/RX128/holding与独立W_CTX均为同一实际实例；本S不是第二DDR桥。直接32bit zero-extend旧26bit地址会丢掉此前截断信息，必须从真实base/宽index重新计算。

**IF13 INITIAL_CLASS_CERT353**新提议高到低为`JID96/class_ref64/class_version64/class_initial_token64/stored_pairs21/strong21/weak21/coverage_ok1/physical_settled1`，合353bit。S依据真实op0 coverage/S/Weak及已完成op5产生，O是该初态封存记录唯一持久owner；trusted S/父适配按原LC270、fullLG1119及真实scope封存台账核来源，353本身没有load_id/source_id/grant，不能脱离这些原历史授权。它保持CLASS mutable/INITIALIZED，禁止O COMMITTED/immutable；后续CLASS变11也不能改初态统计/initial token。保存至该CLASS/CLO/父旧引用及终态/transport真正结束后才可退休。证书body可以冷存18×20=360bit/末高7零；当前M1的191词候选不包含它，余39词也不等已授权放入。真实写入/回执、parent借用、副本/valid/generation及端口位置尚B02/B05，不把body存在当证书已经存好。

**IF14 EDGE_PUBLISH1013/ACK1150**是本版新增内部协议提议：请求body恰为已真实消费的原完整成功CL_TERM1013；回复高到低为`echo1013/edge_version64/publication_token64/status2/reason6/immutable1`，合1150bit。提供方只允许trusted父/O adapter，O逐字段核原CLJ/fullCLO holder、同源J/edge_build_ref/edge_commit、全N/P/合法COMPLETE、自己真实S封存/RETURN/无writer/effects结清及序列可分配；不是相信caller自报flags。成功0/reason0/immutable1且version/token各非零，实际O descriptor完整写定后才响应/授读；S.edge_commit与O.publication_token不同namespace。其它状态不得授读，回应的零token/immutable0不表示原对象/旧effect不存在。

本提议内部status为0PUBLISHED、1REFUSED、2BLOCKED、3QUARANTINED；reason6为0NONE、1IDENTITY、2INITIAL_PROOF、3EDGE_PROOF、4WRITER_ACTIVE、5EFFECT_PENDING、6TRANSPORT、7EXHAUSTED、8CANCEL、9UNKNOWN、10PROTOCOL，11…63非法。REFUSED仅拒本次publication；BLOCKED/UNKNOWN保完整expected、原holder与真实义务，不生成第二对象或误返pin；不得盲cast原R4 reason5/SC reason6。重复完整发布键应返回同一既有version/token，不重做O commit；确切重放cache/保存期限、BLOCKED后终结/再次请求和跨epoch隔离须B02冻结，本版未把这些OPEN称相容完成。

所有IF13/14都独立于旧data信用/terminal ready；held全文保持，capture沿不透传。O publication不等CLO holder先RETIRE：RETURN结束访问权限，returnedmetadata保原CLJ/S台账和本发布运输，等真实ACK与所有旧admin/引用空后才METADATA_RETIRE。若O需RETURN才能发布而RETURN又等发布ACK，会成环；本卡规定data quiet/RETURN先行，完整retained admin随后履约。父收到ACK1150也只证明本EDGE，不代完整bundle/CERT/ANN/RECORD或REPLAY borrow。

组合检查：原REGISTER仅quota reservation，CLASS grant由原S BIND唯一建立；O ACTIVE还核真实INIT，不由PREPARED277猜完成。初态证书不等immutable，L CLASS scope关闭不等wholeLG FREE；GC有自己的原COMMIT245/ACK319和691终态，不套新EDGE body。原LC/CLJ/776/1013/RQ324/RSP449/CLOSE294/ACK502/CANCEL167、C0及REPLAY字段保持，适配只在明确新内部职责，尚缺部分运输/授权时仍NOT_READY。

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
| R4C-INV12 | 两16B postimage/tail及实际journal容量/完整权限齐备才一次logical_commit；两个物理写/effects未结清不能typed成功 |
| R4C-INV13 | full16B RMW之前真实rounded INIT；logical无效QUEUE entry不免邻byte初始化；prefix只按连续真settled推进 |
| R4C-INV14 | S阶段token/353初态证书不置O immutable；RETURN先关闭writer，原term/fullholder与effects再授权O publication |
| R4C-INV15 | 单S/单物理引擎/共享journal与native端口计一次；同一实例操作不靠复制免费重叠，µ未知不当1 |

共同rst同步高时所有fire0，只有外部旧effects已共同隔离/真实无未来读写时才能清本run有效身份；不能单端rst清pin后收旧payload。reset不自动清DDR也不制造settled。v0.3新mutable BUILD首次实际CLEARrounded再普通RMW，CLO接手保已有CLASS/不重清；CLASS全coverage/QUEUE tail0/EDGE重写token另建立逻辑有效性。软件epoch由CONTROL唯一RESET_OWNER授权，须本task/E/borrow、IF13/14/旧returnedmetadata/控制槽真实关闭并消费/GAP；桥仍B02/B04，输入新epoch不授权重建。

### E2. R4C-OP01：CLASS加载、早失败与提交

1. J先通过O预留N状态build和L/CS终态容量；LC接纳e0只锁CJ及ref。L后续VALIDATE核CJ尺寸/TL≤TH≤2047/布尔flags及真实capacity/identity，bind成为旧成功事实后才形成PREPARED。J取得IF12 READY及LG各必需scope真实INIT/ACTIVE都为旧成功事实后才向C0提出CJ，不凭277猜CLEAR完成；首CLASS不会穿透start沿。准备后取消且CJ从未提出/接纳时，J送stream_started0/CS全0的IF03收尾；若CJ已经held，就必须先兑现、随后取消并送stream_started1/真CS，不能走未启动捷径。
2. L接CLASS125时raw_pairs先加1。按自己的受限pair游标核JID、原x_even/y及SOF/EOL/EOF；检查两lane不是11、外框00。有效capture另good_pairs加1，按两lane贡献累计strong/weak，登记observed/合法EOF；坏capture记定位并置class_fault_sticky，不产生LOAD_PAIR。合法EOF仅第P组/末原坐标/规范marks。
3. 好class槽锁完整payload，后续沿建立op0；STORE request火建credit；后续完整合法RSP火才stored_pairs加1、清槽/credit，后续沿可接新CLASS。不能在valid等待时计存储，也不以RSP形成代fire。无新class插bubble，不写重复像素。
4. J唯一早接C0真实CS并锁原值，在自身校验后提出CLASS_SEAL863/stream_started1；L seal ready独立，不等P/EOF/存储data槽空。提前CS失败或本地sticky进入ABORT，不等补齐分类；L经J取消C0，J仍接真CS，不造一份正确终态替代坏真值。有效未启动证明只用于取消/启动前失败，不形成CLASS_COMPLETE。
5. 全成功需stream_started1及LC/CJ/CS全文匹配，CS reason0/mask0/合法flags/七必需口及启用grad完整P/EOF/FE OK均按C0合同合格；L自己raw/good/stored=P、合法EOF、strong/weak与CS一致且和≤N，无错误、data槽/credit空。CS证明流段，L的真实op0和CLASS_COMMIT证明CLASS存储；二者不能互代。启用GRAD的后端提交另B03，不冒称CS已证明GRAD对象持久可读。
6. 满足旧事实才提出op5 CLASS_COMMIT；S收齐全部N状态/尾padding/此前effects后生成非零S initial token及IF13初态封存记录，真实O内部保存/完成路径尚B02，不将单held353当已存好。L收真成功RSP后独立CLOSE；S scope data/effects/oldpromise quiet→本CLASS真实RETURN→正确ACK502→后续LC_TERM COMPLETE。O保初态metadata/完整LG及原term；mutable token不发布CLASS，L终态消费不销毁对象/wholeLG。

### E3. R4C-OP02：选择快路径与完整强种子

1. C接CLJ后逐字段核合法尺寸/三ID/refs/初始commit，绑定S时取得真实S/Weak/P及独占资格。错ref不试读；wrong bind回复保存错误/未知binding，不从raw回复handle释放对象，按关闭/隔离处理。全成功绑定成为旧事实后SELECT。
2. S=0选NO_STRONG；Weak=0且S>0选NO_WEAK；否则GENERAL。旧SELECT提交GENERAL时同步置queue_started=1；两快路径保持0，不由BIND.queue_bound或第一CLAIM决定。快路径queue_ref可以0，不启动QUEUE、SEED/BFS或伪造相应commit。NO_STRONG直接全P写0；NO_WEAK在导出遍历完整N原CLASS，只允许00/10并映射10为1；遇01/11是metadata/版本错误。两条仍EDGE_COMMIT/CLOSE，不提前SUCCESS。
3. GENERAL head=tail=0、活动pop无效。种子游标从index0/x0/y0扫描全N；每次op1请求及真实合法回复后才使用读值。00/01跳过，10保存该坐标并请求op2期待10/当前tail，11报STATE_INCONSISTENCY。读值不会来自后端过期版本。
4. op2只有S能在同一逻辑提交同时CLASS=11、QUEUE[tail]=coord、tail+1。C收到完整成功claim/value/tail回复才seed_accepted++、tail推进及扫描下一点；queue满/未授权/状态不一致则明确失败，不能先标11再丢队列。state/queue内部atomic点与client响应是不同事件，但没有第二writer能看见一半提交。
5. seed_scan=N且seed_accepted=S、所有seed请求/RSP/credit结清才提出SEED_COMMIT，S确保最新state/所有seed append已提交、tail一致，后续合法token才进入BFS。未完成种子不能提前pop；10之后不能当另一合法种子补入。

### E4. R4C-OP03：活动pop与八邻域

1. 旧head<tail且无活动pop/pending时提出op3 READ_QUEUE(head)。成功真回复先核entry高10bit0、x/y范围及当前S绑定/已原子append的不可变provenance归属，再锁active_pop并head+1一次；这里不新增READ_CLASS：S保证当前QUEUE entry只来自同绑定CLASS已成对提交的claim，C校验当前RQ/RSP身份和坐标，由该保证证明归属；不能在请求火时先跳过未核entry，也不依赖除W恢复坐标。
2. 固定邻居顺序NW、N、NE、W、E、SW、S、SE。由旧active坐标先扩signed13再加−1/0/+1；若不在0≤x<W、0≤y<H，登记一次neighbor_checks并进入下一项，无RAM操作。合法坐标先在宽临时中计算index=yW+x并检查<N，才窄化21发op1。
3. 合法READ_CLASS成功：00/11完成本邻居；01保存坐标发op2期待01及当前tail；10报一致性错误，不继续当强边；非法回复按协议错误不取值。op2成对成功才tail++，这份坐标以后会被pop；每次邻居完成计一次checks，request等待不重复计。
4. 完成第八项后后续沿清活动pop/邻居pending，再判断head<tail取下个entry。neighbor_id3仅0…7，另有邻居完成valid/计数，不能8窄化回0造成第二轮。单活动pop/单credit使本任务无并发CLAIM竞争；即使底层延迟，active坐标/期待tail/tx/状态保持。
5. 有新append时S的READ_QUEUE保证读受保护最新entry；不以逻辑tail增长盲读未提交后端。head=tail仍可能旧pop未检查完，不能提前结束；只有head=tail、活动pop/读/claim/请求/credit/响应slot均空才发CLOSURE_COMMIT。S把所有最新state和append提交后给真实token，再进入全图EXPORT。

数学终止：成功claim永久将一个非11候选变11并入队一次；不可能有第二次成功claim同点。tail≤N，pop≤N，每pop最多8检查，有限图及最终响应下结束。这个证明不是固定若干轮/链长，包含全图蛇链/斜链/环/多个种子。QUEUE达N仍需claim表示一致性或协议错误；不能丢候选维持运行。

### E5. R4C-OP04：全N导出、可见完成及边界

NO_STRONG按全部P顺序生成两个0；NO_WEAK按全N原state10生成1；GENERAL在CLOSURE_COMMIT后按全N最新state11生成1，00/剩余01为0，10/非法值立即失败。pair均lane0为偶列低bit、lane1高bit；导出游标是原图，不用REPLAY mode0的source/display映射。两lane都形成后锁pair，后续op4完整写入；写0也是真实操作，不能以旧清零RAM免写。

export_pixels计已核并形成的scalar数，edge_written_pairs只计合法op4真成功RSP，两者可不同。每pair完全写后推进下一组；EOF位置(P−1,W−2,H−1)不是storage closed。全部N/P、pair槽/credit空后EDGE_COMMIT，S核coverage/顺序/尾bit0/此前effects给durable edge_commit。该token只使S封存，writer RETURN/ACK502/CLterm及IF14 O publication之前，E/目录不能置immutable或供读；失败保真实短写前缀。

GENERAL成功还要求seed_scan=N、seed_accepted=S、head=tail≤N、seed/closure token、全N/P及edge token；快路径不强求不存在token。正常CLOSE经本scope RETURN返S访问pin，SETTLE使用旧证据且无本沿新cancel/error后续形成原CL_COMPLETE；父随后IF14发布EDGE。terminal消费不代表O publication已完成、完整bundle成功或CLASS/QUEUE已回收。

逐沿例：e0 C发CLAIM的request火，S只接纳/锁期待状态与tail；e1或更后S以旧pending取得最新state及两效果保留容量；e2或更后成对逻辑提交；e3或更后提出held成功RSP；e4或更后client真火核echo/value/tail并登记。具体backend延迟不冻结为这几个沿，最早/任意停顿都必须遵守先接受→后形成→真交付，无同沿透传。CLASS/QUEUE成对提交与cancel同沿时两效果同样完整提交并成为失败job真实前缀，不能只擦一半；该job后续不发布。

### E6. R4C-OP05：失败、取消、credit与CLOSE

1. 第一次错误/匹配cancel沿先计所有旧CLASS/STORE request/RSP及已完成原子事件；后续旧ABORT禁止新CLASS业务/new STORE操作、seed/BFS/export及新正常commit。私有未published读值/pair可丢；已held request/body保留到火，S held RSP仍实际交付，不能用取消单端撤掉。
2. STORE RSP ready按实际接收容量/活动会话，不由echo合法性组合门控。坏echo/status/reason/value/token/raw坐标只raw_response++、锁错误、不清expected credit；合格匹配失败可结credit但不作成功count。L既有seal与J真CS义务继续独立，未启动C0不等待不存在CS。
3. 自己所有held STORE_RQ已兑现后锁实际cutoff/last，提出CLOSE294，不等待credit/good/P/EOF/父term。S独立封新读写，继续履约oldpromise、已接受操作及held RSP；logical_commit不半回滚。data quiet不等尚需RETURN才能产生的CLOSE_ACK或O publication结果，原完整admin expected仍retained。
4. S全部requests settled/read/write/native/journal/permit/heldRSP真正闭合后，按全旧tuple向O RETURN本scope pin；正确RETURN回链及actual pinsclosed成为旧事实才出ACK502。RETURN不等ACK502先交付或wholeholder先RETIRE。正确ACK结credit不增good/数学量，末RSP旧火照计/ACK后续形成；错ACK或并发RSP照计并隔离。returnedmetadata/ACK运输仍占槽/额度，不能提前覆写旧身份。
5. 对已启动/已binding的失败，只有合法CLOSE、local_empty和所有真J seal/已有控制义务（包括已held PREPARED）结清才形成FAILED_DRAINED或CANCELLED_DRAINED。准备后未启动路径须J明确给IF03 started0/all-zero证明；L启动前VALIDATE/BIND合法拒绝则自身尚未发READY、不会形成C0义务，不等待seal。cancel不覆盖已锁首次更早错误；持续匹配cancel回ALREADY、不延迟已有失败term。未取得binding的规范reject可无CLOSE失败drained，wrong bind不是规范reject/无pin证明。
6. 无完整关闭证书进入Q_DRAIN，继续兑现已经held的request/CLOSE与必要published义务；等本地published发出槽都已火、私有值清后可冻结Q terminal/drained0，credit不阻隔离通知。冻结后RSP/ACK ready0，可能迟到held回复留在S，当前绑定/ref保持隔离，计数/term不被晚回复改写。Q消费不解绑定、不接新start、不自动释放；恢复仅合法共同reset或以后设计的目录/epoch恢复证明，B01/B02仍OPEN。
7. S或父消费者永久不ready时可能保持PROOF_PENDING，不能承诺固定周期结束或用超时伪造closed。已有STATUS/Q终态valid后新增cancel控制回执不重新打开对象/数据义务，仍由J独立接收；形成term之前及GAP复用之前的已有回执必须兑现，软件RESET/epoch桥需包含这些控制槽而不能只看drained。未来watchdog可以记录失败并请求独立CLOSE/Q，但deadline与实际backend必须B05冻结；没有证明不能复用已取得对象。

### E7. R4C-OP06：最终EDGE的逻辑source与REPLAY交接

E只有在O核完整同J/source/result、原edge_ref/S.edge_commit与本COMPLETE一致、IF14实际immutable版本/publication_token正确并取得当前borrow只读授权后启用。它不能接可变CLASS或仅CS0/S阶段token的工作图。plane1 RQ360必须echo固定job/plan/display/borrow、合法seq/source_x_even/y/display坐标及REPLAY marks/plane_first/last；E按源坐标检查，再读EDGE[index]/index+1构成RR.data54[49:48]，RGB/ANN位置0。mode0下半访问偶源行0,2…1078，原EDGE仍全1080行，不预先裁图。

E一口只有1个实际请求/读取pending及1个held RR；读应至少在RQ fire后后续沿回复。held RR不会因取消/CLOSE撤valid；读错误用匹配status1/合法非0 reason/data0。REPLAY CLOSE338独立封口，E只等待自己真实接受读取/可能效果与held RR结清，未published读可安全取消，settled只各请求一次；实际last seq/请求/raw/settled/overflow及四闭合位按原ACK437，末RR火的后续沿才提出。不能等REPLAY client的good/credit或OUT EOF，否则wrong-key形成环。

E CLOSE仅关闭本plane读取，借用仍由REPLAY的RELEASE288及O真实账本返还；不能使用R4C STORAGE_CLOSE502去释放REPLAY borrow。实际O绑定、共享后端读取公平性/端口和完整bundle proof B03/B04尚未实现。本文冻结值/握手/关闭保证，不假定一份完整图数组已经提供了可综合E。

### E8. R4C-OP07：单真实S与32bit/16B无cache后端

本版明确选择一个真实sequencer，候选状态为CAPTURE→VALIDATE→AUTH→RESERVE→READ_WAIT/CAPTURE→PREPARE→LOGICAL_COMMIT（需要时）→WRITE_WAIT→EFFECT_SETTLE→RSP_HOLD→RELEASE；INIT/PHASE/CLOSE走独立admin分支，错误走INVALID_SETTLE/Q。没有第二load/closure/S副本，不启旧8KiB CLASS cache/append cache/prefetch，也未采用SC hotcache或另冷cache；后者若以后替代DIR全查须修版本/预算。nocache不等没有必要的128bit R/W holding、完整许可或journal assembly。

普通typed请求只在旧空槽/旧会话与阶段可接受时fire，e0仅锁RQ324和expected，不同时发raw/访问图。后续校验H/role/seq/op/index/coord/unused；受限local index宽算地址，O按真实descriptor640/pin512/fullholder及当前phase/initialized/latest核资格，失败不提物理RQ。RMW的保护读来自同一明确RMW/WRITE保护权限，不偷增immutable readpin。完整原typed expected保持至合法RSP或正确关闭结账；raw expected/effect债另分账。

| op | 正常匹配数据动作/唯一服务次序 | read16 r / write16 w | logical效果与额外工作 |
|---|---|---:|---|
| LOAD_PAIR | 核同CLASS nibble→读旧16B→保邻bit/生成fullspan→受保护journal→写16B/结effects→RSP | 1 / 1 | 两初态pixel/coverage/S/Weak一次；29词entry/native/目录另计 |
| READ_CLASS | 完整授权→读最新16B→capture提取2bit/high30zero→RSP | 1 / 0 | 无写effects；命中受保护latest时必须核原完整身份，不能裸读旧后端 |
| CLAIM_APPEND | 核期望10或01/tail<N→核CLASS与QUEUE两span→预留两个journal位置→读两旧16B/准备两postimage→一次logical_commit→串行写两16B/结effects→RSP | 2 / 2 | CLASS11、QUEUE[tail]coord32、tail+1是同一可见组，成功claim只一次 |
| READ_QUEUE | 核head<tail/coord0→读QUEUE16B→capture完整entry32/provenance→RSP | 1 / 0 | 不删除entry、不在raw fire提前head++；C核合法成功才推进 |
| EDGE_WRITE_PAIR | 核两bits/row-major/unused→读旧EDGE16B→保邻bit/尾padding→journal/write/settle→RSP | 1 / 1 | 显式两pixel含0；不能借CLEAR免普通全P写 |
| PHASE_COMMIT | 核真实阶段、coverage/tail、全部effects/native/dirty/padding旧真→S独立分配token/封存→RSP | 0 / 0 | 无像素拍不等免费；metadata/证书/admin/token及回链实际M_phase另计 |

CLAIM两entry使用生产DIR共享16×576 journal池中的两个真实预留槽，既有单20×512 RAM/464词与16×11=176bit效果台账不删、不另加一套免费RAM。每entry保address32/length7/postimage512/physical_state2/cause6/zero17；full16B postimage低128有效、其余384为0，length16。group另保原typed H/tx/ref/version/grant/permit、两index、tail_old/tail_new、logical_commit与published/settled/effect/written原事实；这些hot/transport字段尚须完整实例账。其它全机组不能同时占用这两个槽；共享原子组仲裁/最长等待仍B01/R5，不能仅“池还有14”断言并行安全。

中文微操作：先锁两span/实际capacity/组slot；读class旧span并核期待，准备CLASS新11保所有邻bit→串行完整写第一journal entry；读queue旧span，覆盖目标coord32/高10zero并保邻entry→完整写第二entry；两个postimage/tail_new和全部许可已是旧PREPARED事实后一个LOGICAL_COMMIT沿同时公开CLASS/QUEUE/tail。该沿与cancel同沿时三效果仍真实提交，job随后失败、不发布。之后逐entry经同一native读回至独立write holding，AW/W held、匹配B与全部W/LAST/可见性/无未来effect成立才登记entry settled；两entry均真实成功及旧raw/local空之后才形成typed成功，RSP实际消费后再后续退休journal。不透传RSP pop沿接新ordinary覆盖组。

| 相对沿/事件 | 本实例可做的事情 | 保持/不得省略 |
|---|---|---|
| e0 typedRQ fire | 只捕获全文及真实request台账 | 不同沿raw请求/commit/新RSP |
| e1及以后 VALIDATE/AUTH | 旧完整上下文、全DIR查验/动态S资格；各实际许可完成后RESERVE | fullpin/descriptor/holder逐词读+末capture后独立校验；不能填固定1clk |
| read fire→真实R/capture | 单adapter/R_ROUTE/RX按旧身份收料，再取旧holding | AR/R/RX RE与typed RSP分别计；旧route引用真空才下一AR |
| journal WE序列 | 每完整576bit entry29个20bit词，最后词高padding实际零 | 完整写完成为旧事实才PREPARED；两个entry至少58次WE，端口/FSM等待另计 |
| j[0…28] RE、j[29]末capture、后续check（条件原语节拍） | 若无端口stall连续读一entry29词，RE下一沿capture；check/使用在末capture后沿 | 29readissues不是29clk完整服务上界。单assembly/1R1W仲裁与真实模型时序未仿真 |
| eK LOGICAL_COMMIT | 两prepared postimage/tail一次成对可见 | 无原子容量则不能先标11/先append；外部consumer没有裸读半组权限 |
| eK以后两physical写 | 当前entry holding→AW/W→匹配B/effect→下一entry | 一个实际issued burst、独立W_CTX/holding，不复制桥免费重叠 |
| eS旧all_settled→后续RSP_HOLD→真实RSP fire | 原full echo/value/tail/台账 | 末W/单B/读回一次不能冒后端资格，µ未知仍OPEN |
| 后续RELEASE/RETURN/CLOSE | 旧journal借用真空才退槽；单scope return后typedACK | 不等父O先FREE；returnedmetadata/末admin仍保原身份 |

latest规则：凡S查询本组地址先取受保护journal原版本/逻辑值，不能读后端过期01或未完成QUEUE。当前单ordinary未settled不接下一普通操作；latest仍覆盖内部phase/close/失败检查和未来共享接口的旧承诺。无授权的外部reader不得趁journal存在裸读mutable对象。同word连续claim需完整保邻bit，已写entry与旧CLASS任何顺序都不能导致重复入队。

初始化不是reset动作：新CLASS BUILD在LOAD首次grant后、普通op0前真实CLEAR rounded区；CLO接手只核已有CLASS initialized/初态证书，绝不再清CLASS。新QUEUE/EDGE BUILD在CLO真实绑定/普通scatter前CLEAR；若fastpath queue_ref0则无queue grant/INIT，非零已授queue仍按其真实初始化义务处理。S/O bind和LG ACTIVE gate保存INIT pending/effects/prefix，不把PREPARED277当CLEAR完成；ordinary只在旧完整INIT资格成立后开门。

CLEAR已初始化前缀只按连续地址chunk全部真实settled推进，重复/乱序/失败不把byte累计当prefix。生产CLASS/QUEUE/EDGE均16B整除：32400/518400/16200 writebeats，合567000/9072000B；同一job CLASS只清一次。6×5需合法rounded16/128/16B，高padding/guard保护；logical队列未用entry无效也不免16B保护读初始化。其effects不计P个STORE_RQ，但必须进backend实际INIT/close/physical ledger与M_init。

INIT分段要区分接口：DR1…64B/payload512可表达零WRITE chunks≤64B，生产分别8100/129600/4050个64B请求，物理4beat/burst共141750；q128的physical零生成bulk-INIT若另有完整内部授权/holding/expected合同，可条件得254+4050+127=4431burst；q32则17720。后两项只是物理几何预算，不表示当前DR713能装2048B或512B，也不证明已有bulk-INIT接口；选择/完整transport仍B01/B02。每个方案writebeats仍567000，不删除其初始化服务成本。

precommit失败无新logical组；postcommit取消/known/UNKNOWN物理失败立即INVALID/禁新普通读写与成功phase，不半回滚11/QUEUE/tail。已held AW/W/rawRQ/RSP履约，未published后缀明示never-published失败处分；原UNKNOWN/written0永不改成猜的prefix。独立physical CLOSE/INVALID_SETTLE取得无未来effects证据、raw expected/holding/native/transport及typed失败回复真空后，后续退journal，冻结真实组历史供typed CLOSE/O；不等父private先RETIRE。无正确proof则Q保两postimage/KEY/ref/pin，不用timer/reset伪close。

### E9. R4C-OP08：初态→exclusive CLO→RETURN→O immutable发布

1. trusted父保存fullLG1119/原J/source/admission、LC270、唯一原CS592及三scope真实prepare/seal/term。REGISTER只是quota reservation；CLASS一次grant仍原S BIND。retain0由真实algorithm分支得到，不能从Gref0猜absence；retain1 SRC/GC各有独立typed信用/close/token。
2. LOAD op5在CLASS完整实际数据与metadata核对后生成S初态token/353；O逐原tuple/fullholder与自身封存事实保存mutable初态资格。L独立CLOSE，旧data/permit/journal quiet后先RETURN本CLASSpin；真实RETURN ACK/旧pinsclosed再ACK502，L后续LCterm。CLASS close不等SRC/G/wholeLG退休，不形成GC seal互等。
3. 父原LCterm消费/单S会话结清后才CLJ438/fullCLO register/exclusive BIND；O核同CLASS ref/version/initial token/353 P/S/Weak与真实旧load来源，新的grant不是旧writegrant改个role。S SELECT/SEED/BFS/全N export沿前面的真实阶段、data信用与init规则，不另读一份主机图找连通点。
4. EDGE_COMMIT只给S durabletoken，保全部N/P/coverage/尾pad；封新ordinary、兑现oldpromises，CLO各真实access RETURN/ACK502、CLterm。returnedmetadata保原CLJ/S封存/actualclose，不因pinsclosed或term消费清身份；CLASS/QUEUE可按其真正私有退休另处理，不牵连EDGE父owner。
5. 父旧完整CL_COMPLETE已消费且未有取消/错误禁发布才提IF14。接纳沿O仅锁1013/expected；后续全查原CLJ/holder/353和S edge封存、无writer/dirty/effects/native/returned facts。序列可分配后独占更新descriptor版本/commit/immutable；整个记录及真实授权提交完成后的后续沿形成ACK1150。末native写不穿透形成新读grant，E不能用S token预读。
6. 成功ACK完整echo/状态/两非零64及O实际事实都合格才父登记EDGE publication；原完整bundle另有ANN/RECORD/source/CERT及借用，不由本项代替。取消同沿旧真实O commit仍照记但不能作为本失败job发布bundle资格；保持原token/诊断，不抹O effect。拒绝/错echo/BLOCKED/Q保不同真实事实，不清expected或错ref。
7. publication与RETURN不等wholeCLO RETIRE；O的old完整admin/expected和S frozen台账已独立retained。ACK1150实际消费、其它原control/terminal/native/borrow/transport真空后才该scope/holder metadata退休。若其真实存放/借用/ACK终结未冻，保B02；不说“只需接ready”即可实施。

正常走查：完整CLASS/真CS→S init seal353→本CLASS RETURN/LCterm→同初态exclusive CLO→全部strong先claim/SEEDtoken→八邻居含新增末点→CLOSUREtoken→全N EDGE/edge durabletoken→CLO RETURN/CLterm→父新Opublication→immutable EDGE资格。反例走查：claim首span物理写成但第二span未知→保logical组/准确已知首effect和UNKNOWN第二，不pub；独立物理close可推进而不等O FREE，失败/返回后仍不授O publication。两个走查不补P/EOF也不降低全图要求。

## F. 数值、语言与三份对应契约

N/P/index/head/tail及S/Weak为unsigned21，增量先22bit；8N最大16588800，neighbor_checks用unsigned24、增量25bit。yW+x先32bit并核范围再窄化21；x+lane先12bit，邻居偏移先signed13；tx/台账64bit先65bit，饱和/overflow或exhausted保留，不回绕。初始S+Weak先22bit≤N。所有对象大小/byte长度用足够宽计算ceil，不以8bit移位截断索引。Queue高10bit以及所有unused/padding检查严格，不将bool冒充整数。CLASS/EDGE bit精确，不存在数学误差容忍。

GENERAL保守上界：种子N读+S claim；pop K≤N；邻居最多8K读；弱claim K−S；导出N读；CLASS及EDGE写各P，共≤13N个data操作，加最多四个phase commit。这是全链合计：load会话≤P+1请求，closure会话≤13N−P+3请求，各自H/台账/CLOSE cutoff独立，不能拿合计作某一term的真实数量。生产全链≤26956804个STORE请求（load≤1036801、closure≤25920003），必须使用64bit服务台账，不能用21bit像素计数充当总事务数。8N比较数16588800；整个矩形有效有向邻接上界8N−6W−6H+4=16570804。只按一检查/100MHz计算的165.888ms是理想比较，不含请求/读改写/claim/提交/seed/export或stall，不是实际时钟/吞吐证据。

可比较不带N队列的精确反复扫描：从A=S开始，完整遍历N，若初始候选p邻接A则只将A[p]0→1，最新同word更新不丢；每遍全部effects结清后开始下一遍；完整一遍changed0才固定点。每个加入点有到S路径，若任何可达点未入A则路径首缺点与A相邻矛盾，因此结果与BFS等价。最多Weak个变化遍再一确认遍，不能用H+W/固定遍数截断。可直接在2bit CLASS种子10→11后扫描01邻11，或A1bit配原candidate重放；后一方案必须真实保留/重放初始candidate，不是C0活CLASS自动可回读。这个优化候选需要另修接口/提交/容量/测试并联合审阅，当前冻结主体仍BFS。保守N²为4299816960000次pixel访问，100MHz下约11.94小时仅理想尺度，不能以省队列暗称60Hz；实际bitmap packing/共享端口/最新值forward/收敛及资源仍B01/R5。

拟采用SV2009；同域时序非阻塞、组合阻塞，命名表达load/claim/commit/close责任。C++未选，不生成指针/RAII/异常映射。未来Python标准库独立参考直接按初始候选图与强种子求可达集合（或独立连通分量），不复制S journal/cache/队列打包/phase FSM作唯一oracle；完整输入先核尺寸、长度、值域和边界，不修改输入，返回新N-bit图及集合统计。参考host数组只是数学/软件服务实现，物理映射独立证明。

| RTL A–L | 本局部合同/未知 |
|---|---|
| A 数值 | 上述21/22、24/25、64/65、signed13；DDR body地址32/end33，bitoffset乘加先足宽并核logical/rounded再窄化；strict CLASS/entry/padding，无回绕或近似闭包 |
| B 时钟 | 单core上升沿旧valid/ready/状态；输入下降沿稳定驱动、沿后稳定观察；未冻结实际backend cycle或新100MHz约束 |
| C 接受 | LC/CLJ/bind/data/seal/commit/close/term分火；capacity在提出前预留，reply/早CS资格/close独立 |
| D valid | 无效不计数/不写图；0数据合法，valid0/无对象/failed response不当0像素；EOF/空队列/empty/closed不同 |
| E 保持 | complete body/坐标/tx/期待tail、活动pop/邻居/导出pair及所有published握手保持；取消先旧火再私有清理 |
| F 延迟 | 单S/单credit/单sequencer与真实native/physical等待，E8沿表/F2条件式；后续沿回复、commit后续可用；有限BFS不等固定帧时间，不证明camera/video60Hz |
| G 复位 | 共同同步高rst火0、须旧effects合法隔离；reset不清DDR假造settled。新mutable BUILD真实rounded INIT，CLO接手保CLASS初态不重清；单端/软件epoch不替真排空 |
| H 配置 | CJ/CLJ完整快照，CLASS initial版本明确；新D/C颜色/阈值不改旧图；父同沿job旧C沿CONTROL，跨epoch桥B02 |
| I 存储 | CLASS2N、QUEUE32N、EDGE N/完整队列；full16B roundedRMW与两journal postimage/latest/INIT/phase/RETURN/CLOSE；真实端口/同址/完整预算B01/B05 OPEN |
| J 身份 | JID/load/closure/typed tx/rawseq/ref/grant/stagegen/S token/O token分别核；353联系fullLC/LG、1013/1150联系fullCLJ/S冻账；pair/queue与source/display坐标不混 |
| K CDC | 当前局部同域无需逐bit同步大ctx；外部源/目录/视频多域需R5握手/FIFO及共同reset合同，未宣称CDC通过 |
| L 实现 | Ti60F225/I3/SV2009/现装工具目标；R4尚无后端网表/RAM推断/full资源/STA；旧R1/OBS局部不代全机。protected资格/真实clock/pin/CDC待后端与生产共同设计验证，无新EDA |

v0.3覆盖本表G/I/L中历史“旧无效entry不清/未选backend”的表达：共同reset只隔离资格，实际新packed BUILD必须按E8真CLEAR；本版已选单S/现有DDR无cache候选但未获准实现/工具。F/H/J增加S token/O token/353原历史及新IF14全body保持；K仍由真实ASYN1/物理域与camera/video多域合同承担，不能用本单域测试宣称CDC通过。

### F2. 读次数、effects、AXI事件、物理beats与单实例时间

GENERAL正常typed数量：LOAD P、READ_CLASS 2N+B（种子N/邻居B/导出N）、CLAIM K（S强＋K−S弱）、READ_QUEUE K、EDGE_WRITE P、PHASE4（不同H的CLASS1+CLO3）。closure=`2N+2K+B+P+3`，load=`P+1`，合`3N+2K+B+4≤13N+4=26956804`。B为合法邻居READ次数，checks=8K含越界；合法外框00时K≤(W−2)(H−2)，N上界只是保守账，不将K=N当合法密集生产fixture。

按E8无cache表，read16=`2P+2N+3K+B=3N+3K+B`，write16=`2P+2K=N+2K`，data=`4N+5K+B≤17N=35251200 beats/564019200B`。加一次生产三表INIT 567000writebeats/9072000B，条件data总573091200B。claim一次logical效果组含两物理writeeffects，group提交/tail更新不是新增AXI data beat；PHASE/RETURN/close/native/publication没有像素beat也不免费。上述不含SRC/GRAD、目录/journal、命令/响应、refresh/turnaround/健康/stall，不能称最小必要带宽或实测吞吐。

普通随机LEN0时五AXI通道真实fire分别AR=r、R=r、AW=w、W=w、B=w；总handshake=`2r+3w≤37N=76723200`。read16/write16是数据拍，AR/AW是burst地址事件；W每拍/B每burst分别计。INIT q128/q32/q4的burst计数不同但W拍相同；B与typed RSP/token/CLOSE也各不同台账。坏ID/RESP/LAST/拍数/超额响应保raw事实，不让这些数学式替代actual fire。

原DIR full lookup保留：每次实际span访问完整pin32词＋descriptor32词＋真实holder正文及动态S检查，末RE下一沿capture/再独立validate。若新桥明确一份受保护RMW许可覆盖同对象read/write至settle，则每opcode最少span授权q={1,1,2,1,1}；总Q候选=`3N+3K+B`，LOAD fullLG56词→120 readissues/span，CLO fullCLJ22词→86。对应仅native读issue尺度`120P+86(2N+3K+B+P)≤1221N=2531865600`，不是完整服务上界或已实现预算。若实际规则每raw read/write重查，或两pin/holder/INIT/admin有额外查询，则Q更大；须B01/B02逐request/permission lease终结冻结，不能静默把per-access义务删为0。SC hot4/cold21/23等均未采用，不能混入本基线当快服务。

journal完整entry29词/native尾pad与176bit效果台账真实保留；如果按E8完整entry prepare和writeback读回，则正常w个postimage各29WE＋29RE/capture，状态更新/native仲裁/最新值查询另计。claim两entry至少58WE＋58RE；完整record几何不等一沿RAM写或实际最坏时间。PREPARE/INIT/phase/RETURN/父pub/Q返还及S的旧控制运输记M_i；init债不混进R4 RQ cutoff，但pinsclosed/physical_settled必须覆盖它。

令每op真实服务上界`s_op=µ_auth(op)+µ_native(op)+r_op·s_READ16+w_op·s_WRITE16+µ_effect(op)+µ_reply(op)`；δ_op为client捕获/验证/形成下个held/真fire等尚未计入的本地沿。单S条件完成界：`C_S≤M_init/bind/phase/RETURN/close/pub + P(s_LOAD+δ_LOAD)+(2N+B)(s_READ+δ_READ)+K(s_CLAIM+δ_CLAIM)+K(s_QUEUE+δ_QUEUE)+P(s_EDGE+δ_EDGE)`；M含四个真实phase，不能再重复加4个已计phase。每s须已含同一DDR/native/journal的争用和有限消费者等待，未含者另列一次；不能把所有µ填1或拿名义1.6GB/s除data造fps。

如果使用服务包络β_A(t)=r_A max(0,t−ℓ_A)，每次backlog清空/受限caller重新形成eligible请求可能开始新busy period；573091200/r_A只加一次ℓ_A不能自动成为单S成功上界。可冻结逐事务s_READ16/s_WRITE16/µ_AUTH与INIT/close/admin最大等待，或逐实际busy period算ℓ_A；服务为零/消费者永久notready只有限失败监测，不伪成功关闭。只固定显示1080p60；f_capture/f_algorithm_import/f_algorithm_complete分开，由完整设计决定，不新增算法fps要求。

### F3. 完整实例账的当前缺口与必须保存的状态

| 唯一实际实体/状态 | 当前可核的候选尺度 | 未闭合资源/服务（不能漏计或重复扣） |
|---|---|---|
| CLASS/QUEUE/EDGE DDR数据 | 518400/8294400/259200B及真实rounded INIT；CLASS跨LOAD/CLO保同对象 | 不是BRAM；与其它SRC/GRAD/POINT/ANN/私有/guard同一arena，地址不新增/alias |
| O descriptor/pin/M0/M1/journal | DIR四＋四＋M0＋M1＋journal共11RAM候选；M1 LG/CLO/RC191词仅已有body方案 | 冷正文不算hot FF；fullpin/descriptor/holder assembly、native req/resp/保持、所有旧admin未知 |
| 本S claim两entry | 共享16entry池两个保留槽、576/entry、29native词，效果台账176bit不删 | 两postimage/tail/groupKEY/许可/seq/valid/latest及partial未知真实位置；不能免费复制journal |
| O INITIAL_CERT353 | 单CLASS候选封存body353、cold18词360/末高7zero | transport/回执/valid/generation/parent lease/fullLC来源、具体位置尚B02/B05；191词不包括该记录 |
| 父/O EDGE发布 | 新1013请求/1150回执及full expected/原CLJ/S冻台账 | 源held/目的private/响应/重放/returnedmetadata或可信借用须寿命证明后扣一次，不能当两字符串免费 |
| L/C/S控制与诊断 | 原LC/CLJ、CLASS125/CS592/seal863、term776/1013、RQ324/expected、RSP449、CLOSE294/ACK502/cancel167及游标/activepop/计数 | 位宽仅body下界，已存cold可否共享、同沿保持/terminal冻结/控制独立槽/fullFF/LUT/DSP都须实际账 |
| 共享physical adapter/RX/holding | PB RX7RAM/route/W_CTX/128bit收写料；与ROW/IMPORT/camera/SRC/GC/RC共享 | 不复制DDR PHY/桥/FE中值窗/ROW bank；全机公平/最大等待/health/UNKNOWN关闭及warm跨域未完成 |

R1实际局部资源/物理bit是其独立scope证据，不能填本表未知。既有167/175或coldcache后176是部分具名RAM假设，不是全机fit；完整RAM/FF/DSP/LUT/ADD/SRL/PLL/CDC/时钟/引脚/STA需按唯一实例联合。可信借用immutable body只在全oldheld/native/RETURN/publication/晚callback的寿命和端口已证明后可少存一份，不把冷几千bit当热FF，也不靠拒绝正常目标保证服务。

三份契约分别是：共同数值以完整初态集合求精确A；硬件执行以实际request/RSP/atomic可见/phase token/close及旧同沿事件证明；软件结果↔硬件以(JID,class_initial_commit,closure_id,pixel原坐标)逐bit比较完整成功EDGE，失败比较真实前缀/各自计数/token/关闭/Q，不補后缀成功。host函数执行顺序不能证明硬件时序；CRC/terminal摘要不能代完整N-bit黄金图。

## G. 未来实施与验证计划（全部NOT_RUN）

先闭合本范围B01/B02/B05，B03识别/完整bundle与B04生产camera/HDMI明确未来；若先隔离完整闭包核获取实现验证，当前真实S/O/LG/INIT/RETURN/publication仍须完整，不能拿抽象stub代FPGA实现。根独立审阅后形成具体版本/范围/共同基线等待用户批准，再生成和运行；真实仿真/STA不倒置为批准前先做的要求。本轮不另问审批。

拟工作根仅未来`work/active/track4_algorithms_20261004/r4_closure/`：`rtl/closure/class_object_loader.sv`、`exact_hysteresis_controller.sv`、`logical_state_queue_service.sv`、`edge_object_export.sv`、`closure_directory_handoff.sv`及共享`ddr_byte_adapter`；独立`model/closure_reference.py`/`closure_protocol_scoreboard.py`、`sim/`有限TB与`script/`runner为计划。immutable_edge_replay_source/完整R5另范围，不能假称已在当前文件中。确切全文件数/共享schema/compile顺序/现装vendor与工具/hash、hex位宽padding/manifest/case ID、误执行路径仍B05，未创建这些目录/业务文件。

| TEST | 输入/事件及REQ/IF | 期望/方法/通过边界 |
|---|---|---|
| R4C-T01 | 合法6×5/生产完整CLASS，00/01/10、外框与末byte；REQ01/IF01…04 | P真火/完整coverage/S/Weak/CS一致且CLASS commit后才complete，N30 padding4/2；独立图/台账；NOT_RUN |
| R4C-T02 | CLASS11/坏JID/坐标/早EOF/缺EOF/外框强或弱；CS提前失败或CS0但本地fault、CJ fire后旧ARM取消使SEAL.started1而CS.started0 | raw保留/不写坏地址、sticky→J取消仍收真CS、两started事实不混、失败不等P、不伪commit；NOT_RUN |
| R4C-T03 | TL=TH产生无弱、S0全弱、全部0、多个孤立10；REQ07 | 两快路径与全图可达oracle相等，QUEUE未启用不等待其commit，全P显式导出；NOT_RUN |
| R4C-T04 | 跨全部图的长蛇链、斜链、环/分支/多种子、断开远端弱块 | 全八邻域可达集合逐bit、每点≤1 claim，长度不截断；NOT_RUN |
| R4C-T05 | 角/左右边界、xW−1邻下一行x0、队列head>0且RQ.coord0、坏entry coord/高10bit、GENERAL残留10 | READ_QUEUE按entry单位接受合法head>0、不跨行/不取坏地址、明确一致性失败；NOT_RUN |
| R4C-T06 | claim容量不足、tail=N−1最后一次、tail=N仍需新claim | CLASS=11与QUEUE entry成对/真实tail，容量错误不丢候选、不截断；N容量证明；NOT_RUN |
| R4C-T07 | state最新值/queue append未落后端、同word两次claim、读journal与commit延迟 | 无过期读/重复入队、phase token不能早于effects可见/提交；真实backend独立台账；NOT_RUN |
| R4C-T08 | head追tail但active pop未完、最后邻居追加、READ_QUEUE/claim/RSP分别停顿 | 保持active/期待tail/tx，八项恰一次，最后新点仍处理，无假结束；NOT_RUN |
| R4C-T09 | PREPARED/CS/seal held、准备后取消未提CJ、CJ held后取消、S bind/RQ/RSP/phase/CLOSE/term held，父不消费，以及GENERAL刚选择尚无首claim就失败 | 容量有界/body保持、未启动证明不造CS、held CJ须真接纳后真CS；SELECT已选GENERAL则queue_started1、仅BIND或快路径为0；早失败/close不等P，真实fire不同计数；NOT_RUN |
| R4C-T10 | cancel与CLASS/RQ/原子claim/RSP/末EDGE/commit/CLOSE各同沿；持续cancel及CLOSE/SETTLE/已valid STATUS/Q/GAP新cancel | 旧火/成对效果保留，未冻结term时cancel阻止COMPLETE，已valid term全文保持；ALREADY不冒称closed，回执独立兑现/GAP不越过；后缀invalid，真关闭后失败term或Q，不改rawCS；NOT_RUN |
| R4C-T11 | wrong echo/op/seq/unused/status0非0reason/成功token0；bad CLOSE ledger/pins/last/closed | raw计/credit不清；独立CLOSE可按真实settled结账，不返他人ref；错误证书Q；NOT_RUN |
| R4C-T12 | CLOSE与末RSP同沿、错误ACK与RSP同沿、未published读安全取消、Q后迟到回复 | ACK后续旧闭合、证书与真实台账匹配；Q台账冻结/borrow隔离不自动恢复；NOT_RUN |
| R4C-T13 | NO_STRONG/NO_WEAK/GENERAL全N导出、末pair/尾padding、写0/写失败 | N/P与原坐标逐bit，partial EDGE不供source，不用旧清零免写；NOT_RUN |
| R4C-T14 | E mode0下半偶行/其他mode全图、独立stall/wrong-key/CLOSE | 原完整EDGE供正确bit，RQ/RR/437关闭沿REPLAY，无live CLASS tap或credit-close环；实际provider待B04；NOT_RUN |
| R4C-T15 | 共同rst各阶段/新job旧11隔离、非法单端reset/未授权epoch改变 | 火0/合法共同run丢弃，软件桥未闭合则不宣跨epoch恢复；NOT_RUN |
| R4C-T16 | 64bit首号/最大值/overflow、N/8N边界与producer重复请求 | 不回绕、不把总事务计数窄到21，旧关闭/终态继续；NOT_RUN |
| R4C-T17 | 生产1920×1080正常/密集/稀疏/长链及完整R2组合 | 全N黄金EDGE/真实logical台账与CS/loaded metadata共同成立，小图不能替代；NOT_RUN |
| R4C-T18 | 真backend容量/网表/有效扇出/资源/PNR/STA/实际吞吐；BFS与扫描候选 | 给完整映射/面积时间质量权衡，不把主机数组/203一bit平面或短FIFO当全机证明；NOT_RUN |
| R4C-T19 / CG-T02 | 生产1920×1080 typedCLASS密集interior，一点10其余interior01、外框00；另全图蛇链/斜链/环/分支/断开岛 | 密集K=1918×1078=2067604、checks=B=16540832；closure RQ25860043/含load26896844，全N可达oracle与独立fire台账。typed fixture不宣称R2 NMS必能产生密集图；NOT_RUN |
| R4C-T20 / CG-T03 | 获批后的真实R2完整1080p source→实际C0 CLASS125/CS592，retain0/1各一；父唯一CS/实际LG三term/GRAD publication | 真实L→CLASS token→CLO→全N EDGE→O publication，不force term/复制CS造gold；typed fixture不替真实组合。R2现审批/实现由其独立scope管理；NOT_RUN |
| R4C-T21 / CG-T04 | QUEUE entry0/1245183/1245184/N−1，CLASS同nibble/16B重复claim，N30尾pad/guard/非法rounded；故障注入tail=N | 合法0x04000000不截成SRC0；邻byte/entry完整保持，越guard拒绝。K=N仅generic错误/容量测试，非合法外框00生产图；NOT_RUN |
| R4C-T22 / CG-T05 | CLASS INIT/353/RETURN/ACK502/LCterm→CLJ/BIND511，GC close/原commit，EDGE phase/RETURN/CLterm/1013/1150逐处held8 | 一次CLASS grant、CLO不重清CLASS、S/O token分层、无writer才immutable；wholeLG/CLO退休不阻scope RETURN或publication，原body全echo；NOT_RUN |
| R4C-T23 / CG-T06 | claim precommit、第一AWheld/W/B、第二AW/W/B，badID/RESP/LAST/拍数/健康、wrongRSP/close分开 | 旧logical组与two postimages/准确knownprefix/UNKNOWN保留；独立INVALID_SETTLE、RETURN/Q，typed failure不自动清journal，不以常量OK模型代IP；NOT_RUN |
| R4C-T24 / CG-T07 | SEED末项、pop第7邻居追加、EXPORT末pair、phase/close/RETURN/publication/term形成各同沿cancel；每held8、共同及非法单端reset | oldfire全计、八项恰一次、termvalid冻结，晚ALREADY不称closed；共同隔离后新job、warm未知不复用ref/token；NOT_RUN |
| R4C-T25 / CG-T08 | seeds0x431/0x1060；SOURCE/GC/CLASS与camera/ROW/IMPORT/native持续合法backlog，独立有限停顿和close | 后续冻结每种实际调度/最大连续stall8/服务机会/每µ界，原shared单实例不饿死；每known失败正确关闭后真实新job恢复，永久notready仅有限失败监测不伪成功；NOT_RUN |
| R4C-T26 / CG-T09 | strict fullhex/EOF/缺项/多项/X/Z/unused/pad、partialfilter、intentionalfatal三例，真实关键WLF沿 | 独立runner记录真实compared=N及每scope ledger，partial不fullPASS/fatal不PASS；未来normalS→AXI/INIT/native/RETURN/O分别观察，不能自报PASS字串；NOT_RUN |
| R4C-T27 | INIT q4真实DR、未来bulk q32/128仅若获批其完整新内部合同；每对象CLEAR中断/乱序/重复/健康失效，CLO保CLASS初态 | 567000beats/9072000B各对象一次，q4 burst141750；q1284431/q3217720只是合法几何候选，不能把2048B装DR713。INIT债不混typed cutoff、prefix按真连续settled、未完成不ACTIVE/ordinary；NOT_RUN |

参考用独立连通分量/集合可达，不复制S FSM/cache/journal造gold；physical模型只copy字节/注入协议错误，不运行BFS/生成token。事务检查器从真fire独立造typed/raw/native/AXI/RETURN/pub黄金ledger，不读DUT term作期望。共同数值逐Nbit，CRC/term不替全图。正常6×5/8×7/1920×1080与边界/故障组合互补；typedCLASS stress和真实R2组合各自有证据范围，未来完整REPLAY另B04不把它假称已检查。

有限运行政策（设计，NOT_RUN）：每normal case cycle限由F2真实m_op×已选µ/δ、INIT/admin/M与实际最大stall算得，再固定明确余量；wall限按完整向量/现装工具确定每case具体值，两种均须B05审阅冻结。seeds0x431/0x1060只指定可复现身份，不冒称已生成随机场景，具体有限schedule/注入沿须manifest清楚。永不ready/健康资格违反时TB有限监测判失败/PROOF_PENDING/Q，不让模型无限跑、不让RTL timer伪closed。获批后实际波形/源码hash/退出码/数值counter/全机网表、PNR/STA/bit各实录，未运行不继承R1/预检的工具通过。

## H. 双向追踪

| REQ/来源 | MOD/IF/操作/INV | 计划稳定符号/文件类别，未生成 | TEST/当前证据 |
|---|---|---|---|
| R4C-REQ01 / R2-REQ05/07/C0成功 | J/L/S/O，IF01…05/13，OP01/08，INV01/13/14 | class_object_loader / load_snapshot、class_hold、seal_hold、initial_certificate | T01/02/09/17/20/22/27；来源+本文设计，NOT_RUN |
| R4C-REQ02/04 / CN-01/06/07 | C/S，IF05…08，OP02/03，INV03…07 | exact_hysteresis_controller / seed_cursor、active_pop、neighbor_id、head/tail | T03…08/17；集合/有限性分析，未实现 |
| R4C-REQ03 / CN-INV04…07 | S/C，IF05/07/08，D3/OP02/03，INV02/03 | logical_state_queue_service / atomic_claim_record、latest_forward、phase_commit | T06/07/10/11/12；实际backend OPEN |
| R4C-REQ05/07 / CN-OP05/07 | C/S，IF05/10，OP02/04，INV08 | edge_object_export / export_cursor、pair_hold、edge_commit | T03/13/17；完整N/P合同，未运行 |
| R4C-REQ06 / CONTROL/C0/REPLAY失败原则 | J/L/C/S，IF03/08/09/10，OP05，INV09…11 | request_hold、expected_credit、source_close_certificate、quarantine_snapshot | T02/09…12/15/16；纯关闭设计 |
| R4C-REQ08 / REPLAY-REQ01/02/04 | O/E，IF11/14，OP06/08，INV08/11/14 | closure_directory_handoff / edge_publication；未来immutable_edge_replay_source | T14/17/20/22；真实bundle/provider OPEN，publication只新提议 |
| R4C-REQ09 / BAT-REQ05/06 | 全局，D1/F/G，B01…05 | logical_capacity_contract、independent_closure_reference、resource_reports | T16…18；逻辑算术，不是片上/工具证明 |
| R4C-REQ10 / PERF189/DIR88/PB78派生 | S/O/P，IF15，OP07/D5，INV12/13 | ddr_byte_adapter / address_range、rounded_permission、initialization_ledger | T21/23/27；32bit反例/16B数据账，NOT_RUN |
| R4C-REQ11 / SC134/138/172及DIR139派生 | J/O/L/C/S，IF13/14/08，OP08，INV14 | closure_directory_handoff / class_initial_record、scope_return、edge_publish_expected | T20/22/24；353/1013/1150属本v0.3候选，未实现 |
| R4C-REQ12 / 单实例服务与资源派生 | S/P/O/shared native，OP07/F2/F3，INV15 | resource_service_contract、closure_protocol_scoreboard、finite_runner | T18/23/25…27；r/w/AXI/M/µ分账，完整资源/服务OPEN |

反向：L只完整加载/验证，C只精确遍历/导出；S唯一logical writer/sequencer，P只有真实字节/物理effects，O才真实grant/353保存/RETURN/immutable publication/回收，未来E只读已发布EDGE。353保来源/初态，32bit桥防合法地址截断，两postimage保atomic，1013/1150弥合无writer发布，不新增别的识别或IO业务。共享体/冷存优化须真寿命后扣一次；获批实际文件/符号/hash/波形/结果再登记，当前实际代码全部待实现/NOT_RUN。

## I. 设计门槛与审阅

①B完整集合/正常边界；②C单S/共享P/O与实际来源；③D原typed及新32bit/353/1013/1150相容检查，但B01/B02运输未闭；④E原操作及新增OP07/08/旧沿/RETURN草图；⑤F数值/A–L/三份契约与native/data/AXI分账；⑥B/D/E正常/未知/无writer走查；⑦G有限增量/场景/timeout方法及H双向追踪，但B05确切文件/数值仍未冻。⑧不满足：B01/B02/B05当前必需仍OPEN；B03/B04是未来整包范围，不能由此跳过S/O。⑨保存后实际全文读回/差异/hash/link核查、Root独立审阅；⑩v0.3两路径纯设计及A2实际读取版明确，未建立本范围共同批准基线。保持LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN，不申请成熟前的泛化批准。

当前用户没有批准本R4 v0.3实施，Manifest/DB/正式state不改。下一允许动作是Root独立读回本具体增量、在同卡闭合真实后端/交接/全部实例/有限验证，选择完整闭包核或整包范围后形成具体READY版本及共同基线；未来真实仿真/STA不作为未批先实现的前置。R2 v1/48对象和R1既有有效批准不改、不重复索取，本作者不另向用户问批准。

## J. 变更与恢复

v0.2修订前将4B7F70C4…FFF87482、57485B原字节保存为[不可变v0.1快照](design-TRACK4-ALGORITHM-R4-CLOSURE-001-v0.1.md)。根独立全文审阅、作者交接自查及协议审阅发现op单位校验、QUEUE归属文字、表格列数、批准次序及终态/取消/queue_started规范需明确；本版修订D2/D3/D4/E4/E6及T02/05/10，不改消息位宽、BFS数学、完整N容量或物理后端OPEN。需按新hash复核，旧版审阅不自动绑定当前版。

v0.3在实际全文读取v0.2的346行/hash5B147019…185B11后，以拒覆盖File.Copy(false)保存63263B精确快照并核src前后/副本同SHA；本轮只改本主卡。吸收不可变8A90…审阅ΔCLOSE-01：B新增REQ10…12；C单S/P/O与真实接力；D5新32bit桥/353/1013/1150；E8/9两16B postimage、INIT及RETURN/O发布；F2/3单实例数据/native/服务/全部状态账；G T19…27/H/I。BFS/全部强种子/N非环QUEUE/全N EDGE、原LC/CLJ/typed/终态位宽及R2数值不变，新增接口是真新提议，不说旧版已有。

原v0.2“图无效entry不需清”只属logical有效性；本版fullWSTRB RMW需真实rounded INIT。CLASS在LOAD新build清一次，CLO接手不重清；q128/q32物理CLEAR几何需另bulk-INIT合同，DR64B路径q4明确可表达。S阶段token不改O immutable，scope RETURN不等wholeholder先退休。重要后端/运输/资源/时间选择仍须实际联合设计/独立审阅和指定批准，未把这些改动当已有R1配置授权可实施。

DDR服务主卡由Root并行修订；A2保留本作者实际读取307行/2B867…版本，后续变动不自动吸收，也不因追hash循环改来源。其他A2输入按最终核查记录；R2 v1/48输入、R1工作/验收文件、原资料及正式治理均只读。

相对原CANNY只保留严格分类/精确可达集合、N队列、原子接纳、快路径、全N导出、有限性；新增LC270/PREPARED277/seal863/CLJ438、typed STORE324/449、logical CLOSE294/502、776/1013终态与immutable EDGE service。旧917bit job/物理phase_key/grant/突发/fence schema及器件工作不继承。与当前C0 CJ142/CS592、REPLAY360/421/338/437保持原族，必要适配按命名字段，不改原布局。

若选择扫描代BFS、压缩/复用EDGE/CLASS、共享多个活动写者或缓存/向量CLAIM，将改变容量/原子性/终止/性能与测试边界，须先修订设计/读回/审阅，不偷偷把队列变短。真实backend能够用受保护pending实现逻辑atomic不意味着其物理write已完成；必须保留阶段提交与关闭证明。恢复读最新父/本文/来源/批准，核refs/commit、singlewriter/tx、坏echo credit及Q未结。

## K. 实录

本轮实际读取入口/唯一规范全文/模板、v0.2主卡与174行审阅全文、A2限定交接来源；纯文字/位宽/地址/整数服务式分析、精确快照及本主卡修订。没有业务RTL/功能脚本/参考/可执行测试/TB/工程/SDC，没有仿真/综合/PNR/STA/bit/网络/安装/硬件/DB；全部NOT_RUN。没有解密protected或改原资料；R2 v1/48、R1交付、其它源/正式state/Manifest保持只读。353、1013/1150及DR是候选，不是实际端口，9072000B容量/573091200B条件数据账不是full资源或实测速度。最终全文/差异/链接/位宽/输入hash实际核查后另报Root，不自嵌本文件SHA。

## L. 中文阅读与交付顺序

本文B精确集合→C单S/共享P/O→D原公共typed与新桥/353/1013/1150→OP01加载→OP02种子/快路径→OP03八邻居→OP04全N导出→OP05独立失败关闭→OP07实际span/journal/INIT→OP08初态/独占/RETURN/O发布→F真实单位/条件服务/唯一实例→G/H→I具体OPEN。完整普通路径：新CLASS真INIT→C0分类/父真CS→S353初态资格→CLASS RETURN/LCterm→CLO保已有CLASS独占→SEED→BFS→CLOSUREtoken→全N/P EDGE→Sedge token→CLO RETURN/CLterm→Opublication→未来bundle/REPLAY。失败不补P/EOF、不以epoch或超时清未知effects。

修改集合看REQ02/OP02/03/T03…08/19；物理span/地址/atomic/INIT看REQ10/12/D5/OP07/F2/T21/23/27；移交/发布看REQ11/IF13/14/OP08/T20/22/24；最终重放看未来IF11/OP06/T14/B04。资源/时间回F2/3/B01/B05及R5。获批后实际核文档—中文注释—稳定符号—源码—独立gold/波形/工具；当前交付仅具体设计修订，功能/EDA未运行，用户理解验收待真实反馈，不将保存/讲解当通过。
