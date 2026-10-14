# R5 完整软件实施与存储架构选项 v0.1

2026-10-04。READ_ONLY_SOURCE_ANALYSIS / PURE_DOCUMENT_PROPOSAL / UNAPPROVED / NOT_READY / NOT_RUN。按 PLAN_TEMPLATE 通用字段及 A–L 编排；本次根 Agent 指定保存于本 review 路径，仅新增本文，不修改规划主稿、正式状态、Manifest、数据库或原 HDK。本页是供统一设计批准前选择结构的报告，没有实现体、功能脚本、模型、TB、工程、约束或工具运行。

## 通用计划字段

- Goal：保留完整 1920×1080、全八邻域 Canny、圆及任意旋转矩形、原 P/R 目标，找出当前逻辑对象到 Ti60 真实资源的差距，并规定可继续冻结的实施/验证路线。
- Current state：BATCH v0.3、R4-CLOSURE v0.2、R4-RECOGNITION v0.2和新 VIEW-BRIDGE v0.2均未批准；R1/R2/OBS、R3及旧识别执行稿有可采用的局部数学/协议来源，没有全包可综合后端或生产视频工程。
- Target state：先明确完整算法核心与生产视频集成的证据边界，再冻结真实存储/重算、接口/容量/时钟/pin、文件/schema及验证合同；全部当前范围设计成熟后统一批准，在批准范围连续实施到 bit 登记。
- Gap：现行 BFS 工作集不能放入 Ti60；不保留全图的替代结构会改变重要接口与生命周期，尚未冻结。生产不可暂停相机、完整 RGB/edge/ANN 显示、CDC、带宽与资源也尚未闭合。
- Assumptions：N=1920×1080=2073600，P=N/2=1036800；单次算法核事务可暂停。不得将这种软件源假设套到相机。A3 DEFERRED_BY_USER，不调查或恢复指定 V4 DDR 器件、PHY、校准、旧 IP。
- Open questions：选哪个实际输入/存储/输出架构；算法核心软件/物理范围与生产视频范围如何分别验收；全图重放资格、识别工作容量/profile、共享数值仲裁、质量集、真实 pin/CDC及服务期限如何冻结。
- Dependencies：A1 实际来源；根最新指令要求分清比赛要求、回放结构和可重复软件验证，PC若参与只能存取数据，不能代算 DUT 的算法。
- Milestones：结构选择和范围→schema/生命周期/容量→生产适配或明确隔离→独立审阅/共同基线→指定批准→实现/局部及全图回归→完整相应网表/PT/PNR/STA→bit/hash登记停止。
- Detailed steps：B 范围与对象来源→C 选项→D 交接与反例→E 中文次序→F A–L/三份映射→G 实施验证→H 追踪→I 阻塞。
- State transitions：本文保持 NOT_READY；纯文档授权不是源码、测试或构建授权，不改变正式 H0。
- Artifacts and hashes：仅本文；保存后实际读回/bytes/SHA另报。A1 来源hash绑定读取时版本，不伪造 Git commit。
- Validation：数学/逐位、真实握手/关闭、全图质量、生产资源/有效扇出、pin/时序、bit分别记证据；均 NOT_RUN。
- Failure handling：容量不足、坏身份、未取得关闭、无带宽保证均保留真实失败/OPEN，不能截前 K、补零、改期望或用超时伪造 COMPLETE。
- Human approval gates：整体设计/共同版本/实现范围/工作与工具基线明确成熟后统一批准；数据库前置或明确例外仍须满足。现在不索取未成熟方案的泛化批准。
- Rollback：唯一新增本文；现有设计、原 HDK、状态、Manifest、DB保持。未来只在已批准独立 work 副本实施。
- Completion criteria：本报告交付是选项/差距/次序可审阅；不是关闭 R5/B05或完整软件验收。I的具体选择冻结后才能评估相应范围 READY。

## A. 实际来源与阅读边界

### A1. 当前源版本

下列相对路径均以 `D:/大三/FPGA_verilog/_fpga_edge_agent` 为根；本轮实际读取规则入口及 config/state/DB，唯一 v0.2和模板；需求全文、BATCH、R4闭包全文及资源报告、旧EXECUTION相关完整执行/资源/验证章节。现行R4-RECOGNITION另实际读取D2/D3（112–156行）、D7/D8（202–236行）、F（357–383行），不宣称其余章节全文复核。VIEW读取 B/C及容量/生命周期条文，不宣称其新字段全文复核。

| 来源 | 实际 SHA256 | 本页采用范围 |
|---|---|---|
| 工程根唯一 v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 | 设计先行、A–L/三映射、10.3/批准边界 |
| planning/PLAN_TEMPLATE.md | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 | 通用字段及 A–L |
| docs/requirements/TRACK4_REQUIREMENTS.md | 3CA55B70E23488B4710345CEDE908D62A0A9113D4AC8454D6746E04BC4CD5DE2 | 原十一项、采集/显示 fps 分开、A4非强制A3依赖 |
| docs/requirements/TRACK4_REQUIREMENTS.csv | 6DE462B532530F8C1A1FE215635EBFBE80EAC1710A028380BE0B506255E768B5 | 原需求身份；不是新运行状态 |
| planning/design-TRACK4-ALGORITHM-BATCH-001.md | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 | 完整软件/1080p/精确Canny/圆和旋转矩形、P/R≥95%及同类IoU≥0.5一对一评价；A3暂搁 |
| planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 | CLASS/QUEUE/EDGE逻辑容量、atomic/commit/CLOSE、全N、late cancel、B01…05 |
| planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257；83901B | 当前v0.2 D2/D3/D7/D8/F：一份POINT、17,526,269B容器、OBJ新schema、RTL STORE语义、私有ref与完整bundle；未全文复核 |
| experiments/track4_algorithms_20261004/03_review/r4-closure-resource-comparison-v0.1.md | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C | Ti60 256×10Kbit、nativepacking、扫描等价/最坏界；源PDF/模型来自其已核记录，本页没有重跑工具 |
| planning/design-TRACK4-RECOGNITION-EXECUTION-001.md | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178 | POINT64、多遍、105RAM、VC/FINAL/ANN、旧总225及29168bit容器、巨大访问量；旧scope/MC/DDR不继承 |
| planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | 当前v0.2单SRC/J/BUILD/VIEW、旧帧阻塞下一BUILD、父引用/借用/epoch；不用旧F312 |
| planning/design-TRACK4-ALGORITHM-R1-001.md | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 | 独立25MHz/四pin及真实PT/STA义务；未批准、未实现 |
| planning/design-TRACK4-ALGORITHM-R2-001.md | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | Gaussian/Sobel/NMS/CLASS、28RAM结构预算；class非最终edge |
| experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 | 可暂停观察源、608bit/CRC、四pin与限流，不承诺camera/60Hz |

### A2. 结论的性质

事实：当前指定容器不能按原样映射到片上RAM。推断：修改存储/重算/候选遍历结构有机会降低空间，但必须重新证明完整数学、身份、终止、质量与物理预算。提议：软件算法核心优先采用C的真实原始字节后端边界，生产视频另需D或经证明的B扩展。未知：本机/板卡尚无本报告所需的新后端、连接和生产工程实测；不是“必须先编码才能设计”，而是当前重要选择/接口尚未冻结。

## B. 整体行为与存储义务的来源

R5O-REQ01：全范围算法在FPGA执行，生产图仍1920×1080；所有强/弱链按八邻域精确可达，输出完整N含0。R5O-REQ02：圆、任意旋转矩形及P/R评价不缩小；不恢复撤回的目标尺寸、数目、噪声/遮挡硬界限。R5O-REQ03：只将相应范围的实际仿真/物理工程证据用于验收。R5O-REQ04：原RGB/最终edge/ANN按同job/坐标/CFG匹配，有限存储与真实引用关闭。R5O-REQ05：完整文件、schema、源hash、阶段产物、验证/双向trace可统一冻结；bit后停止。

| 对象/义务 | 来源与可修订性 | 不能静默省略的保证 |
|---|---|---|
| 窗口行历史 | 灰度/median/Gaussian/Sobel/NMS流算法需要；片上行RAM合理 | 多级分别补边、旧pending capture、气泡/反压与中心坐标 |
| 初始CLASS2与N条QUEUE32 | 当前R4 BFS的实现选择，不是赛题规定数组 | 替代BFS须证明精确集合及有限终止；不能短FIFO溢出丢点 |
| 最终EDGE1 | 当前全N导出/不可变重放合同；可以冻结原工作A或改成等值重算provider | 不得以class、未收敛A、缺失后缀或部分commit作完整EDGE |
| 完整SRC RGB24 | 当前VIEW/REPLAY的不可变SRC与任意重放结构；A5要求同一原彩色图，未强制这个驻留布局 | 流式基础Sobel可只延迟RGB行；完整Canny延迟/多遍后要同源资格，重采下一帧不是旧RGB |
| GRAD32N | 旧识别多遍读取方案，不是赛题必须完整存GRAD | 可以从不可变同源输入/CFG重算，必须逐位相同且不借下一帧梯度 |
| POINT及候选表 | 当前识别v0.2只一份POINT，已取消旧SORTED副本；缓存/枚举结构可另审多遍重算/分批重放 | 不改变完整支撑谓词/排序/tie/去重，不截前K成功；质量风险明确评价 |
| ANN2N与FINAL/字形 | 旧光栅图/重放选择，A5/A6要求正确覆盖/标签 | 可从冻结完整geometry逐坐标生成ANN，不意味着geometry/result容量可任意缩小 |
| 旧完整bundle+下一BUILD并存 | 持续显示/采集及冻结/回放重要结构；当前桥仅单slot且阻塞下一BUILD | 若增加第二帧必须列容量/owner；若阻塞/重复旧图必须如实说明可暂停/处理fps及显示刷新 |
| host完整数组/oracle | 可重复软件验证和独立黄金计算需要 | 不属于Ti60片上资源；oracle不能代算并回填DUT结果 |

A3已暂搁，因此不把DDR帧冻结/多帧对比继续列成本次必达实现前置。A4精确闭包、A5同源覆盖、A6识别、B4标准刷新仍追踪；不能因移除某种数组而删除其行为。

### B1. 当前容量的具体冲突

Ti60全部256RAM10满容量2621440bit=327680B。1/2/4/8/16 native族通常每块8192有效bit；5/10/20族可用10240bit；下表满容量下界不能替代实际packing/端口证明。

| 指定对象 | 完整逻辑bytes | ceil(bits/10240)块下界 |
|---|---:|---:|
| CLASS2N | 518400 | 405 |
| QUEUE32N | 8294400 | 6480 |
| EDGE Nbit | 259200 | 203 |
| 三者 | 9072000 | 7088 |
| SRC24N | 6220800 | 4860 |
| GRAD32N | 8294400 | 6480 |
| ANN2N | 518400 | 405 |
| 一份POINT64，E≤N的容量上界 | 16588800 | 12960 |

当前BFS不能全片上；这不是所有精确Canny等价实现的信息论下界。Candidate1+A1至少405块，分开packing为406；单A1按512×20为203bank，最后bank256有效word。A203+R2流窗28=231只留25，尚不包含重放provider、扫描RMW/cache、控制/接口/R3、识别与显示，不能称全机可放置。

旧EXECUTION的105识别RAM和全机225是假定大SRC/EDGE/GRAD/POINT等由外部MC服务，不包含这些全图物理容量；不能将225和现行R4全N数组拼起来说仍225。VC80RAM与A203单独同时存活就达283，更不能隐含共享；复用必须真的关闭旧访问与借用。旧29168bit RC容器也只是局部候选，不是全机FF或综合结果。

现行识别v0.2 D7的17,526,269B由一份全N POINT 16,588,800B、全N ANN 518,400B和其它实列容器419,069B构成；不是赛题明示的全部驻留义务，更不是片上已兑现容量。新稿已明确不继承旧105/225RAM、第二POINT、32DSP或29168FF，本文容量示例以现行D7为准。

## C. 可审阅的架构选项

| 选项 | 能兑现的范围/真实结构 | 必须冻结的改变、代价与结论 |
|---|---|---|
| A：原BFS全部对象片上 | 按当前CLASS/QUEUE/EDGE容量直接推断 | 7088>256，确定不可作为完整Ti60实施选择；不需要先综合才承认指定布局矛盾 |
| B：不可变源多遍重算＋packed A原地扫描 | 可重复规范源或有真实同源重放服务；R2重算class，A=S，逐完整遍只0→1，无变化且effects结清才完整EDGE | 去掉N队列与CLASS驻留，需改R4 schema/phase/计数及provider；精确Canny局部有231RAM起点，完整识别/原RGB/连续视频仍无小工作集证明。N²理想100MHz约11.94小时仅检查尺度，不能固定几遍/限制链长。当前不得选择它并宣布全包闭合 |
| C：FPGA全部算法＋外部仅原始字节存储服务 | FPGA运行R1/R2/R3、完整R4闭包/识别/光栅/目录/原子性/commit/关闭；外部PC在软件验证/核心物理架构中只保存并返回请求指定的原始字节 | 推荐作为当前完整算法核心的候选工作方向，需冻结真实存储端口/transport/pin及全部FPGA资源。testbench数组仅是仿真后端；真实PC字节链路只证明外部存储辅助核心。两者都不证明生产相机无丢帧、camera/HDMI CDC或60Hz持续供图，不自动关闭生产R5 |
| D：FPGA全部算法＋实际无DDR字节存储器/独立存储板 | 与C同算法/逻辑S，实际器件仅提供读写容量；可由外部异步/同步SRAM等经证据选定，不复用被停止的DDR工作 | 具备完整生产方向的可能性，但当前没有已绑定该容量、合法板级连接/电气/pin/服务时序的来源。本页不私定器件、价格/性能或pin；须新增结构选择与真实资料，不能把“可加SRAM”写成当前板可用 |

流式基础灰度/median/Sobel/阈值及同延迟RGB覆盖可以独立采用有限行缓存，属于真实可实现方向；它不解决完整Canny后端与几何识别。R1/R2/R3局部真实四pin工程可先作为独立物理证据，但其批准/通过不能替代完整核心或整包。

### C1. C的容量候选与明确边界

为完整软件回归及将来存储辅助算法核心，提议字节后端配置上限64MiB=67108864B；这是外部服务容量候选，不是Ti60 RAM或已安装硬件。按现行R4-RECOGNITION v0.2 D7，一份POINT及所有实列表容器17,526,269B，再加SRC、GRAD、唯一finalEDGE：

17526269+6220800+8294400+259200=32300669B。

再保守加闭包CLASS518400B和QUEUE8294400B，合41113469B；finalEDGE与识别输入为同一真实object时只算一次，ANN/RECORD已在D7总量内。这个合计不作stage alias，也不证明各容器实际同时存活；各访问pin、对象ref、版本和退休须按D8及真实STORE生命周期核对。保持当前单SRC/J/BUILD/VIEW slot，不叠加旧完整frame与新BUILD，不据外部容量自动开放下一BUILD。

64MiB减上述合计为25995395B；这只是未分配容量，不能把它称为目录/journal/profile已闭合的余量。D7未含的对齐/目录/事务journal/STORE内部pending、行480B、字体、R3、本地缓存及完整profile等仍须逐字段精算，区分外部字节与片上FF/RAM。D7的有限候选表/FINAL容量不是输入场景数量上限；若共同profile/结果范围改变，必须重新选容量、分时复用或确定性多遍输出，不截断、不由外部算法补结果、不把失败帧从P/R分母排除。识别n21等位宽仍依现行数值来源，不因后端扩大而盲改R3 opcode/算术。

C主路线允许外部仅存canonical records/words及原始RGB/GRAD/EDGE字节；如果后续选择只允许外部存原RGB、不允许工作records/words，则CLASS/QUEUE/POINT及其它工作空间仍没有已闭合实体方案，不能继续把本例称可采用的完整核心路线。

D可沿用同一逻辑对象/外部字节接口，但容量、地址位数、总线宽度、周期/等待、端口与连接由具体真实资料冻结；64MiB不是当前板拥有该器件的事实。已有板载Flash也不能未经容量/擦写/耐久/带宽/关闭设计直接充作RAM后端。

## D. 接口与组合检查候选（无实现体）

### D1. 唯一owner和交接

| IF / owner | 方向、字段/单位与保证 | 当前相容性/OPEN |
|---|---|---|
| R5O-IF01 原规范源 | provider→R2，原CJ142/FP74；锁JID/尺寸/CFG，像素/标志仅真实fire推进 | 仿真可暂停源与生产不可暂停源分开；同源重放资格不能由重复坐标自证 |
| R5O-IF02 R4闭包逻辑S | LOAD与CLOSURE分角色：LOAD用LC270/PREPARED277及LC_TERM776，CLOSURE用CLJ438/BIND511及CL_TERM1013；两者各按原RQ324/RSP449、角色化H160、tx64和CLOSE294/ACK502结账 | LOAD的H160含load_id，CLOSURE含closure_id；S查找/台账必须含角色，即使同数值H也不合并。LOAD真实关闭/终态消费后才独占转CLOSURE；C/D只改变S以下字节后端，B先联合修原schema |
| R5O-IF03 原始字节后端 | S/各对象provider→backend：role、H、seq64、object_ref64、byte_offset32、length16、读/写类型、完整写data和有效字节；backend→对应owner：完整身份echo、status/reason、原始read bytes/写settled证据 | 采用最多16B单操作候选、单credit和单held请求/回复；实际packed/schema/op/transport尚未冻结。地址长度先宽加核对象区间；byte后端不执行CLAIM/邻域/NUM/拟合/排序/ANN或生成数学结果 |
| R5O-IF04 逻辑对象目录 | 当前VIEW/O为唯一ref/容量/权限/commit/bundle/父引用/OPEN借用owner；byte物理位置由其注册记录授权 | PC只是data carrier，不能由PC handle/ACK新授bundle；完整provider close与真实RT/RELEASE/parent return/epoch授权依当前桥 |
| R5O-IF05 数值/识别 | 现行RC D2/D3：H160中recognition_id；OBJ KEY287/RQ799/RSP872、独立CLOSE295/ACK504（reason6）；NUM用R3 REQ622/RESP585及完整ID176/cancel/quiet；几何核验、全支撑统计、去重及光栅在FPGA | RC的RQ/CLOSE不与LOAD/CLOSURE的324/294混用；OBJ tx_seq不是NUM call_seq。不继承旧4731scope/phase_key137/MC/FORMAT身份；旧EX只数学/局部模式来源，共同profile/仲裁及实际adapter仍需冻结 |
| R5O-IF06 可观察结果 | 全N EDGE/RGB/ANN及所有FINAL records以真实事务导出到比较器；同JID/source/CFG/profile、坐标/顺序与真实commit | CRC/LED附加，不代全图结果。新完整核心memory-link到pad须真实存在并保留有效算法扇出 |
| R5O-IF07 生产输入/输出 | 摄像domain→可接受帧存储/行FIFO→core；完整旧bundle→renderer/rowFIFO→pixel/serializer domain | 选择D或有严格证明的其他结构后冻结容量、仲裁/CDC/reset/pin。现四pin没有camera/HDMI或memory-link，不能把IF07标N/A并称整包完成 |

C中host memory模型/实际字节服务只raw读写canonical records/words，不能执行算法STORE op。CLOSURE的CLAIM_APPEND、state11＋enqueue原子可见、latest/forward、phase commit、ledger与CLOSE，以及RECOGNITION的DENSE_ADD16、串行RMW、count、完整record组commit、ledger与CLOSE，全部由可综合RTL STORE控制器执行。RC每组16票实际更新完才成功，不能让host由一条DENSE_ADD请求代算票数。S在FPGA受保护journal/排他串行机制里发布effects，实际字节写均settled后才phase/table commit；读最新值须forward未落后端journal，单credit不豁免。host不发数学commit/token、不决定目录资格，不计算候选或ANN。host存储协议与传输解析属于未来获批软件，实现体本轮不生成。

### D2. 时序、有限容量、取消反例

新backend候选一份请求、一份expected credit、一份held reply及一个原子journal；读/写16B data缓冲各1份，完整key固定引用其owner ctx到close。最终字节数/packedbody/FF须随IF03冻结精算，不把它记0或在每个模块复制完整J。数据与CLOSE/控制回执/terminal独立，不能共享唯一槽让close等data成功。

1. e0旧req valid/ready真fire才建credit，后续沿才形成response；e0不得用刚接纳body产生同沿回执。停顿全body/身份/写料保持。
2. cancel与CLAIM原子点同沿，旧成对effect照计；后续不新发数学业务，held请求/回复、已承诺完整写料兑现，独立CLOSE证明真settled。NORMAL CLOSE/SETTLE未冻结term时late cancel仍阻COMPLETE，即使控制回ALREADY。
3. 错echo/raw_reply不能结credit或用坏offset读图；close可独立推进。无证明保持Q/pin，term消费和epoch变化不清借用。已valid STATUS/Q不被新cancel重写，但GAP/reset等所有旧控制回执真消费。
4. B候选若只扫描H+W遍，逆序蛇链可能未收敛；若A更新WE仍pending时结changed0，产生假固定点。两者不合法。
5. 重放梯度换了阈值/median或源帧，几何成员不一致；不以相同x/y弥补。独立目录证书和CFG快照全遍不变。
6. 旧FINAL第65 distinct失败与目标数场景上限不同：可以保留明确资源失败语义，但不将它称覆盖全部识别目标，更不能排除这类图使95%成立。新输出/排序容量须作为profile结构审阅。
7. PC计算edge/LS/TLS/候选再回填，将验证对象换成外部算法；即使FPGA CRC正确也不通过REQ01。offline oracle可独立计算预期，只进比较端，不进入DUT结果服务。
8. 单SRC/VIEW正在读旧图时新相机仍不停写；有限槽终会溢出。只能证明后端带宽/容量足够、选择可控采集/明示拒帧政策（需范围审阅）或保持该生产路径OPEN，不能凭旧图可重复60Hz声称无丢帧。

## E. 中文操作草图与阶段生存期

### R5O-OP01：先选择范围及结构

先读B原行为与对象来源→选择A/B/C/D并写下软件算法核心、核心物理工程、生产视频各验收边界→将不再驻留的SRC/GRAD/ANN或变更BFS的差异列给BATCH/R4/VIEW/REPLAY共同修订→按真实对象生命周期形成一张同时存活表→再冻结细节。A淘汰；B仍是待证明的减空间分支；C是当前可继续设计的完整算法核心方向，D是生产视频的实际存储方向候选，均未获选择批准。

### R5O-OP02：C/D完整算法核心

O先核不可变完整源资格及容量，注册唯一J/CFG/source→准备R2 loader和必要GRAD接收槽→真实CJ/FP输入→完整CLASS及真CS、后端CLASS commit→SEED/BFS或经批准的等价结构→全N EDGE及commit/CLOSE→完整POINT/梯度支撑进入识别→圆/矩形候选与数值核→最终冻结geometry全支撑核验/排序/去重→全结果/ANN逐坐标或整图封存→真实各phase close及对象bundle注册→VIEW/REPLAY按真实证书读取→真RT/CLOSE/RELEASE与父引用返还后才退役。

CLASS/QUEUE在闭包access pin真关闭且无外部借用后可归还物理分区，不能只在head=tail时借给识别。GRAD不保留时，provider须绑定同源重算证书及每遍真实终态；ANN改逐坐标生成时，geometry/标签/position必须完整冻结并持有到最后reader关闭。任一旧pending/capture/NUM/held/borrow未闭合不改池模式。

### R5O-OP03：B完整遍的必要序列

冻结可重复源/CFG→重算完整分类并把STRONG初始化A→新完整遍从坐标0读同初始candidate→串行取得A最新八邻域→只候选且邻接A时0→1→全N扫描以及每个RMW/pending结清→判断changed→有变化再完整遍；完整无变化遍才冻结A作为最终EDGE。接受平面203bank的bit更新须真实20bit读改写/latest，不以singlebit写20bit口。B若进入识别，必须另有不与A冲突的完整工作集/重算计划；本页没有把旧105RAM直接塞进剩余25。

### R5O-OP04：生产视频与旧帧并存

先按实际camera模式/LUT/RAW解包定义最大到达率及不可暂停段，按真实后端最坏服务延迟计算缓冲与帧接纳；锁源结束/坏帧策略。core成功bundle与pixel域在帧边界原子采用；旧bundle持续引用到最后row/pipeline/serializer真退休。若下一BUILD同时存在，逐个计第二SRC、工作/最终对象/父与plane借用，修订当前单slot桥；若不并存则必须说明采集如何停止和显示从哪里继续取得原图。跨域完整多位descriptor握手/FIFO、reset释放、取消/carry/pending排空独立设计。当前未提供该生产保证。

## F. 语言、数值与三份映射

| RTL A–L | 本选项报告的合同/待冻结项 |
|---|---|
| A 数值 | 采用实际R1/R2/R3/R4的位宽/扩展/RNE/floor/拒绝规则；N/P/index21，byte offset32、end加法33候选；算法结果不由host替代、不改为近似闭包 |
| B 时钟 | 核按沿前fire/旧状态计算/沿后提交；25MHz真实四pin观察基线仅候选核心；core100或生产pixel/fastclock需独立clock/SDC依据，不能按同频称同步 |
| C 接受 | 空槽/预约容量才ready，source可暂停性按具体范围；prepared/CJ/首pixel分沿，response后续沿，CLOSE/term独立 |
| D valid | bubble不补0、不增游标/计数；0RGB/0EDGE是合法数据；无对象/部分图/Q不等空成功 |
| E 保持 | 完整body、byte写料、key/CFG/坐标/用途以及已published请求回复保持；取消不撤旧承诺 |
| F 时间 | BFS≤26956804个STORE请求为现行逻辑全链上界，不是cycles；B最坏N²，不固定遍数；识别旧巨大多遍字节数保留，真实延迟由backend/NUM/仲裁决定 |
| G 复位 | 共同冷rst的合法作废与软件优雅reset分开；软件epoch需全部close/RT/return/control ACK证据，不功能清RAM假关闭 |
| H 配置 | CJ/profile/源快照按job原子锁；重算及显示使用同历史配置；按键提案与当沿job用旧/新规则由CONTROL明确，不热读全局 |
| I 存储 | 当前7088块矛盾、B的203/231、C/D外部字节容量与本地cache/识别pool分别计；native读延迟/端口/同址/RMW/模式排他不可省 |
| J 身份 | job/source/CFG/profile/closure/NUM/byte seq/ref/commit/plan各有明确角色；命名字段转换，不把旧scope/phase_key或source/display坐标混用 |
| K CDC | 软件后端模型同域只验证逻辑协议；实际memory-link/camera/pixel/resetCDC另冻结，四pin无这些路径不能说CDC通过 |
| L 实现 | Ti60F225/I3/SV2009、实际Efinity/Questa来源；全部算法必须在相应完整core网表；RAM/FF/DSP与关键路径未知，旧225/OBS预算不是全机结果 |

共同数值契约：独立Python标准库黄金直接整图卷积/梯度/NMS/class；闭包采用独立集合/连通分量；圆/矩形几何/支撑/标注与IoU匹配按实际typed定点合同，不能复制cache/journal/ring作为唯一oracle。C++目前未选，不生成映射。

硬件执行契约：真实req/response/capture/write/commit/CLOSE/terminal/引用返还决定推进；PC字节服务不拥有算法循环/状态提交。参考用host内存不规定硬件周期或真实可综合数组。

对应契约：每个结果按完整JID/source/CFG/profile/原图坐标/候选ID与NUM call匹配；全N逐bit/逐word和所有结果记录比较，失败独立检查真实前缀与close/Q，不能补后缀成功。质量oracle/预期与DUT byte service分开，不能回流。

## G. 完整软件实施与验证编排候选（未执行）

### G1. 批准前必需冻结；获批后连续实施

1. 先选择C/D或为B补完整证明；冻结软件核心与生产视频的范围、文件/接口/资源/真实pin基线。设计无当前阻塞且实际读回/联合审阅后才统一指定批准，不要求先跑功能生成器/综合才可READY。
2. 在批准work内生成共享typed packages/schema和独立参考/数据读取/协议检查；再按R1→R2→R3→逻辑存储S/O→R4闭包→识别→ANN/VIEW/REPLAY联接实现。R3数值/ROM验证独立，不能拿旧NUM物理job接口直接cast。
3. 每个增量检查数学及协议；随后同一完整1920×1080端到端RTL回归，全部算法在DUT。C的host字节backend仅提供读写；先故障/延迟可控的仿真后端，实际memory-link需其已冻结接口实现与独立回归。
4. 形成完整算法core工程（外部字节端口/真实transport＋结果观察），选真实device/package/I3与clock/pin/PT；完整对应网表map/PNR/STA，检查有效扇出、所有必需算法与本地RAM。常量stub、virtual I/O或只有局部CRC的无完整算法扇出工程不能证明fullcore保留。R1/R2/R3独立工程作为辅助证据，不替它。
5. 若范围含生产视频，继续实际camera输入适配、mem/provider仲裁、完整旧/新bundle、renderer/rowFIFO/serializer/CDC工程和全链软件回归；不得把C核心通过写成生产视频通过。
6. 相应全部检查通过后实际bit/hash/staging/日志与中文操作/双向trace登记；停止，不下载/烧写/硬件观察。失败在既定范围修复，重要结构/行为改变先更新设计。

### G2. B05应冻结的完整清单字段

未来共同baseline逐文件保存path/role/bytes/SHA、设计版本与schema/profile、生产参数W/H、工具版本/CLI、project/peri/SDC和已批准工作路径；不自引用可变主稿hash。文件组至少R1/FE、R2/C0、R3/ROM规范、S/O与选定backend/transport、R4闭包、识别/ANN、CONTROL/VIEW/REPLAY、生产适配（若在范围）、独立reference/fixture/协议检查、unit/integration/fullframe/quality/Ti60工具编排与结果登记。具体每个文件名/稳定符号、端口布局/packed bit序、取消/terminal、finite deadline及来源必须在选择后填满；现在不生成空工程或stub假关闭B05。

运行期限按冻结的最大backend服务cycles、允许stall和各算法循环界计算：core周期deadline和wall deadline分开。永不ready仅验证held/Q与不伪成功，不能作为有限完成场景。不能凭旧吞吐估计编造完整识别deadline。ROM实际字节/hash/单调性与参考比较属于获批后验证，ROM生成/精度/舍入/终止合同属于批准前设计。

### G3. 验证场景矩阵

| TEST | 输入/事件和目标 | 期望/方法及范围 | 当前 |
|---|---|---|---|
| R5O-T01 数值 | 全范围RGB/滤波/方向/阈值边界，所有typed NUM/LS/TLS/ROM拒绝与RNE | 各阶段独立逐位oracle，n/坐标/配置范围不因换backend窄化 | NOT_RUN |
| T02 精确闭包 | 完整1080p长逆序蛇链、斜连/环/分支/无强、无弱、断链；B按最后无变化遍 | 全N等独立可达集合，旧假H+W遍/changed早结必须失败 | NOT_RUN |
| T03 存储与容量 | 同word相邻更新、跨byte/word/bank、N队列、最新journal、原子cancel、commit延迟 | 同一个像素只claim一次，无半state/queue，真实phase/CLOSE；大对象不推断成片上隐形数组 | NOT_RUN |
| T04 识别质量 | 完整1080p圆/任意旋转矩形、同心/相邻/重叠/边界/缺边/负样本/噪声，独立标注集 | 保留原P/R≥95%及IoU≥0.5同类一对一；失败帧与容量问题如实计入，冻结实际集/种子/指标，不能恢复场景硬边界 | NOT_RUN |
| T05 交接控制 | bubble/多支不同stall、早CS、heldCJ、cancel与末写/close/term同沿、wrong key、耗尽/软件reset | 真前缀/回执/RT/Q/引用返还，不靠status消费清borrow；晚消息不进入新job | NOT_RUN |
| T06 RGB/ANN | 同源多遍/CFG更换反例、mode0偶行重放、完整overlay/字体/越图/碰撞与旧帧读取 | 每坐标RGB与finalEDGE/ANN来自同bundle，显式0完整；proceduralANN须等值，不能用class代edge | NOT_RUN |
| T07 外部仅数据 | 后端延迟/坏echo/断链/过期ref；offline oracle与byte服务完全分离 | FPGA产生全部数学与目录证据；PC仅返回原始字节，真实transport副作用/关闭独立 | NOT_RUN |
| T08 完整Ti60 core | 生产参数实际project/PT/map/PNR/STA/bit，真实pin/clock/无非法例外 | 必需算法/状态/RAM到结果/字节link/pad真实扇出，许可/告警/资源/路径覆盖逐项记录；四pin局部不能替代 | NOT_RUN |
| T09 生产视频 | 实际到达/等待界、多域不同相位/复位、输出帧采用/退休、并存引用/缓冲边界 | 无丢帧/撕裂保证由容量/带宽/CDC和真实软件事件证明；显示60Hz不替计算fps，实体观察不执行 | NOT_RUN |
| T10 全包交付 | source/schema/design/test/project/日志/bit/hash/中文操作相互核对 | 需求→符号→事件→结果及反向，失败/未运行/范围限制不涂改 | NOT_RUN |

小图仅补边界，不能代T02/T04/T08完整尺寸。不同后端/结构若改变运算成员、tie、舍入或输出排序，需修数值设计并独立质量比较，不能把它叫无行为优化。

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 未来文件组/稳定职责（未生成） | TEST/证据 |
|---|---|---|---|
| REQ01 / BAT01/02、A4 | R1/R2、C/S、IF01…03、OP02/03 | frontend/canny/numeric/exact closure/storage | T01…03/T08；来源容量及集合分析 |
| REQ02 / BAT03、A6 | 新R4识别/R3、IF05/OP02 | candidate/fit/verify/dedup/annotation/profile | T01/T04/T06；旧EX仅局部数学/预算，不是新实现 |
| REQ03 / BAT05、B5 | backend/transport/完整core/生产top、IF03/06/07 | projects/peri/SDC/tool stages/resource/observable results | T07…10；未来直接报告，当前NOT_RUN |
| REQ04 / BAT04、A2/A5/B4 | O/CONTROL/VIEW/REPLAY/provider、IF04/07/OP04 | job/CFG/refs/epoch/renderer/source adapters | T05/06/09；当前C764单slot事实/差异OPEN |
| REQ05 / BAT06、v0.2 | 全部、G1/G2 | shared schemas/baselines/oracles/protocol/quality/trace | T10；本文纯文档 |

反向：host字节服务只承担数据保持/传输，不承担算法；oracle只承担预期比较，不回填DUT；四pin核只承担其范围物理观察；完整core/生产top必须各有真实需求与所有必需实例。未实现/未运行不填成证据PASS。

## I. 最小架构冻结项与当前门槛

| OPEN | 必须冻结的具体选择与影响 |
|---|---|
| R5O-B01 | 选择C的存储辅助算法核心、D的生产存储或B的完整小工作集证明；明确各验收范围。当前资料不能承诺“现板纯片上、无外设、完整1080p全部视频与识别”实现 |
| B02 | 若去掉SRC/GRAD/ANN驻留/改BFS，联合修BATCH/R4-CLOSURE/识别/VIEW/REPLAY的provider/phase/term/commit/容量与身份；不能将候选数组需求当比赛硬要求，也不能悄删行为 |
| B03 | 真实byte后端/transport的packed schema、canonical records/words存取范围、存储大小/端口、RTL STORE的latest/atomic journal/DENSE16 RMW/commit/ledger/close、合法连接与pin/IO/clock/reset；C的仿真array不关闭该物理接口项，若只许外存RGB则工作空间未解 |
| B04 | 完整识别profile/候选输出/多遍空间与FF/DSP/RAM同时寿命、所有最终集合与排序去重、质量集/指标。旧1024/64失败语义不能自动成为输入场景限制 |
| B05 | 生产camera不可暂停到达/源保持、连续显示/双bundle或单slot阻塞政策、真实CDC/pipeline退休与带宽/吞吐。无生产证据不能用软件core通过关闭它 |
| B06 | 完整文件/schema/设计版本/工具/许可/参数/真实pin共同baseline、独立测试场景/deadline/双向trace、统一实施批准及正式执行前置 |

已经能确定A不成立，也能确定哪些旧驻留义务可审阅修订；尚不能从现有资料唯一选择完整可布局结构。①整体范围、②职责、③接口候选、④中文步骤、⑤A–L/三映射、⑥反例、⑦编排/验证/追踪有本文内容；⑧仍有上述重要架构OPEN，⑨保存后实际读回，⑩只读来源版本清楚而实施共同baseline未冻。因此UNAPPROVED / NOT_READY / NOT_RUN，不宣布R5/B05或整包READY，不以未运行测试造成设计循环。

## J. 变更影响与恢复

本文不改任何上游。未来选择B需修R4-CLOSURE的BFS容量/STORE op与term数学计数和边界；选择重算GRAD/程序ANN需修识别与provider证书；C/D需新增实际S backend/transport和R5core；增加旧frame/新BUILD并存需修当前VIEW/O容量/引用及CONTROL调度。原十一项/A3暂搁、生产1080p、圆/旋转矩形和质量要求保持。

恢复时重读本页及这些父稿实际hash；特别VIEW为C764当前稿，不能沿用F312。旧EX的scope/phase_key/MC/DDR结果不是新路线批准或共享资源基线；其量化数值可按命名契约适配，身份必须新版本明确。

## K. 本轮实录

本轮仅指定源只读、metadata/hash、容量/数学/交接分析和授权新增本文；没有业务源码、功能模型/脚本、可执行测试/TB、project/peri/SDC、仿真/综合/PNR/STA/bit、安装/网络/硬件操作。DB仍未配置，正式运行未开启；未改正式状态/Manifest/DB。所有容量是算术/候选，所有工具与质量执行NOT_RUN。

## L. 阅读与下一允许动作

先B区分行为与驻留选择→B1实际冲突→C选项及容量→D owner/接口/具体反例→E中文次序→F/G/H→I最小OPEN。下一允许动作是根按真实用户范围形成结构选择及上游差异的纯设计联合审阅；不是生成实现或运行工具。等共同成熟版本明确批准后，按G连续实施完整相应范围并如实记录软件core、物理core、生产视频各自证据，不能将局部通过升格。
