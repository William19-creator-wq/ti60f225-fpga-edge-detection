# TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001：识别记录到既有 DDR 槽位（v0.1）

## A. 状态与阅读入口

- Goal：把当前 R4 的 26 类记录逐项解释成既有固定槽位中的位、字节及 16 字节访问单元，补齐存储预算的可核对字典。
- Current state：LOCAL_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN；2026-10-05。Target state：完成 RC 对象适配的契约、预算和评审后，再提交指定版本审批；本卡仅完成其中几何字典。
- Gap / Open questions：PK-B01 初始化及权限；PK-B02 最新值、记录/分组完成与失败收敛；PK-B03 实际 DDR 可见性/无后续副作用证明；PK-B04 时钟、服务时间及 FF/RAM/DSP 实例账。均 OPEN，不能以容量足够代替实现闭合。
- Assumptions：保持 1920×1080、N=2,073,600、当前 R4 layout3/numeric1/algorithm3；仅板卡现有资源且允许板载 DDR；不采纳未经批准的尺寸/噪声边界、降分辨率或阶段别名复用。
- Dependencies：R4R、生产目录 DIR、阶段能力 SC、物理接口和真实 DDR 完成契约；旧 BK 仅供有限原理对照。原始资料、参考工程、工具安装均只读。
- Milestones / Detailed steps：核对记录清单 → 位与字节几何 → 真实槽位映射 → 局部操作草图与反例 → 未决接口闭合 → 资源/时间账 → READY 评审。当前完成前三项及草图，后面未完成。
- State transitions：NOT_READY 保持，不能转实施；只有阻塞闭合、读回与评审后才能 READY，再等待指定版本/范围/基线批准。
- 批准范围：既有 R1 v1.1 和预检授权不覆盖本卡；待答的 R2/Q0 问题不视为批准。此前本地审计例外不延伸为本卡实现、EDA 或数据库权限。
- 用户阅读顺序：本卡 B/C 整体 → D 交接 → E 局部 → F 数值/时序 → G/H 场景与追踪 → [完整静态字典](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json)各实例地址 → [当前槽位清单](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json)。下一项允许行动是只读调查及文档闭合。
- Artifacts and hashes：下面五份是实际来源 SHA256；新卡和新字典的最终哈希由独立检查报告登记，不构造自引用哈希。无 Git commit 的证据不伪造 commit。

| 来源 | SHA256 |
|---|---|
| [R4R](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md) | 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 |
| [既有槽位 JSON](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json) | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 |

## B. 整体外部行为

PK-REQ-01：当前 R4R 的逻辑接口保持单一预期事务，RQ799 / RSP872，身份 KEY287=H160/tx_seq64/op5/object5/index32/length21。记录值仍占 payload512，字段和高位保留零规则沿用 R4R；本字典不改变操作编号、返回类型、目标数量或算法。
PK-REQ-02：同一表按 item0、记录低位、字节低位顺序连续放置。表尾向 16/64 字节取整只发生在整表末尾，不能给每条记录新增 16 字节槽。每个真实实例仍使用 DIR 已分配的槽位，不能从几何数值自行造 ref/version/grant。
PK-REQ-03：读返回完整记录，写保留相邻记录和表尾规定零位；逻辑字节许可和向 16 字节对齐的物理许可分别检查。不能写入 guard、未分配空间或别的 bundle。
PK-REQ-04：单条逻辑记录最多四个 16 字节物理单元；它们完成前不交付逻辑成功。DENSE_ADD 的 16 个计数属于一个组，不把其中一个计数完成当整组成功。
PK-REQ-05：初始化、取消、复位、SEAL/COMMIT/CLOSE、物理部分效果均保持真实完成语义。未知物理状态进入隔离，不能因超时、复位或 pin 关闭便宣称对象可复用。
正常例：读取 POINT item0，逻辑 8 字节，但真实物理单元 16 字节；只提取低 64 位，剩余 payload 高位为零。边界例：DENSE item67 起始位 1,407，在单元内偏移127，跨两个单元；合法记录不能按单单元读取。

## C. 模块职责与整体连接

阅读路径：R4R 算法发 RC 请求 → IF-PK-01 身份/操作检查 → MOD-PK-GEOM 解释 object/index → IF-PK-02 向 DIR/SC 核验真实对象和许可 → MOD-PK-ACCESS 逐个物理单元收集或更新 → IF-PK-03 真实 DDR 完成证明 → R4R 原 RSP；失败经原型化错误路径及 CLOSE/隔离回收。这里是设计草图，尚无实现模块。
MOD-PK-GEOM 只负责 PK-REQ-02 的无副作用地址解释；不授予权限，不改变记录字段。MOD-PK-ACCESS 候选负责 PK-REQ-03/04 的收集、邻位保留和整组完成；缓存/journal/状态所有权尚待 PK-B02。MOD-PK-QUALIFY 需由实际物理层提供 PK-REQ-05 的可见性及无后续副作用证明；本卡不能虚构提供者。
目录 O 拥有实际槽位、世代与退休权；算法持有借用；存储适配器不得用 RC 访问关闭代替 O 对象退休。POINT 在多遍圆/矩形/覆盖识别中仍有读者，不能在 DENSE 阶段结束便覆盖；RECORD 三实例分别为历史 bundle 持久输出。
复用依据：只复用当前槽位几何及 R4R 记录布局。BK ordinary 限 16B、CLEAR 才允许 16/32/48/64B，其 RQ324/RSP449、CLASS/QUEUE 组及两 journal 槽均不是 RC 后端。旧存储布局的紧缩字段和互斥银行不能套到当前记录。
整体检查点：26 类记录/24 个工作对象的几何及容量已明确；仍未选择完整初始化、许可桥接、原子组和真实物理完成提供者，故不进入编码。

## D. 接口与组合检查

| IF | 提供方→使用方；字段/单位/前置条件 | 保证、兼容与当前缺口 |
|---|---|---|
| IF-PK-01 | R4R→GEOM；KEY287、unsigned index32、object5、op5、length21、payload512；完整当前 H/配置身份 | 保持原单预期事务及原回声检查；op0 READ / 1 WRITE / 2 CLEAR / 3 SEAL / 4 COMMIT / 5 DENSE_ADD；6…31非法。非法身份/布局不能产生地址副作用 |
| IF-PK-02 | DIR/SC→ACCESS；真实 ref/version/grant、stage_index2值2、REGISTER的schema8值3及完整RJ2257、对象/phase权限、初始化范围及 prefix；几何地址不是能力 | schema不作为lookup616新增字段；SC lookup616/reply740 的逻辑字节范围与完整物理范围需显式桥接；SEAL/COMMIT 无数据范围走管理契约，不能伪造零长度数据许可。PK-B01 OPEN |
| IF-PK-03 | ACCESS→物理层；32bit byte address、16B 单元、身份/许可/组；end33bit先检查；共享保存的记录/最新值证明 | 单记录实际跨度16…64B不代表可原样发64B ordinary。跨4KiB分拆为合法物理请求；所有真实完成和失败回收后才交付。PK-B02/B03 OPEN |
| IF-PK-04 | ACCESS→R4R；原 RSP872 的 status2/reason6/value512/token64/effect_ok1，原 KEY 完整回声 | 不把 FPI/DR 的不同状态/原因位宽直接 cast 为 RC 原因；成功、无结果、非法请求、已发生部分物理效果和未知状态分别保留，完整翻译表待闭合 |

只读对象 EDGE/GRAD 由实际生产者提供冻结版本；POINT 和私有表按当前阶段读写/前缀许可；ANN/RECORD 由当前输出 bundle 实际授予，不用近似 slot 推断。READ 单记录长度1；WRITE 单记录长度1且规范保留位为零；CLEAR index0/全容量；SEAL index0/valid_count；COMMIT POINT 为 E、ANN 为 N、RECORD 为64（仅RECORD的payload低7位为F、高505位零；POINT/ANN payload全零）；DENSE_ADD length16、索引为 batch5 与 pointordinal21，payload 16×rho9，全部范围核验后处理，仍沿 R4R 原契约。
CLEAR/SEAL/COMMIT 的许可、完整清零、无待处理写和版本冻结均有管理前提；这些不是普通一个 record 的地址公式。E=0 的 POINT COMMIT 可以按合法管理语义完成，不能为了查询数据许可而造一次 item0 READ。
组合反例：POINT base=70,516,736=0x04340000；旧26bit地址会截成0x00340000误入 SRC，必须选真实32bit地址接口且先做33bit末端检查。typed→descriptor：0→6+bundle；1→12；2→15；3…20→16…33；21→9+bundle；22→37+bundle；23…25→34…36。bundle 必须来自真实绑定，不能由算法自行选择。

## E. 局部详细设计与中文操作草图

GEOM 的当前输入是已接受 KEY 和实际描述符快照；中间值为起始/末端位数、第一字节和对齐跨度；不保存历史算法值。先扩展 index32 和 record_bits 后在 unsigned 42bit 范围内计算 s=index×bits、e=s+bits；先核对 op 对应的容量/valid_count/phase，再窄化到实际地址。
地址草图：用 s 除8取得字节偏移，s余8取得 first_bit；logical_len=向上取整((first_bit+bits)/8)。物理第一单元=base+16×向下取整(s/128)，单元数=向上取整((s余128+bits)/128)。表基址当前均64字节对齐；任何基址或布局变化均重新验证，不能继续引用“四单元”结论。
读草图：取得完整逻辑及对齐权限和冻结/最新值读视图 → 按地址顺序收集全部单元 → 去掉前面的邻位，只提取 bits 位 → 检查记录字段保留零并将 payload 高位补零 → 在真实读完成及身份仍有效后形成原 RSP。气泡/停顿不推进下一单元，不更新记录完成计数。
写草图：在可写世代取得完整跨度的排他权 → 确认每个将读改写的物理单元已有可靠初始化/最新值 → 收集旧值，替换目标位，保留所有邻位，检查表尾规范零 → 记录待完成 postimage 后逐单元提交 → 真实完成全部收敛后才公布逻辑完成并更新前缀。第一条 POINT 写不能等下一条请求凑满16B，否则单预期 credit 会死锁；独立第一写必须拥有已知邻位或选定的首次触达初始化机制。
同拍纪律：当前边沿只基于旧 busy/credit/计数接受或提交；接受新物理请求不等于它已完成。同沿取消、返回、配置更新的优先级、响应稳定规则、组门和 journal 写顺序由 PK-B02 进一步冻结，不用软件段落顺序代替 RTL 周期。
初始化候选量：对本次 job 当前工作对象2…25的全部 round64 数据区清零共17,526,400B=1,095,400个16B单元；若合法64B分段则273,850段，仍需实际 CLEAR 许可与完成。只包括当前一份 RECORD，不清 EDGE/GRAD、不清其余两个历史 RECORD、不越 guard。这是保守候选及成本，尚未选定；按实际前缀/首次触达初始化的替代方案也必须逐对象证明后再减少成本。
DENSE_ADD 草图：保持 R4R 一条组请求身份 → 验证16个 theta/rho 的真实计数及 committed POINT → 对当前组所有重合物理跨度维持同一最新视图 → 各计数只增加一次，保邻计数 → 全部16个结果真实收敛后才结束组。16个计数不同仍可能共享物理单元，不能用每次的旧 DDR 副本覆盖前一个更新；journal 不能等价为16份独立记录响应。
取消/故障草图：封住尚未发布的新组；旧held RQ799/NUM622/RSP872保持原内容并按原ready握手兑现，同沿先记旧fire再进入关闭核验 → 已发请求保留身份与捕获 → 按实际 completed/failed/unknown 归集各单元 → 可证明无后续效果才交付相应失败关闭，否则保持隔离等待真正物理证明。组已部分写入不能假装回滚；原 CLOSE295/ACK504、NUM622/585 和 O 退休各自闭合，不能互相充当证明。复位不清外部 DDR，也不自动解除隔离。
局部算例：HIST item658 起始13,818bit，实际首字节87,318,527（4KiB末字节），shift2/logical_len3，对齐范围[87,318,512,87,318,544)；两16B请求分别在页两侧。VC item7 offset112、400bit→4单元；FIT_STATS item15 offset105、263bit→3单元，不能套无限重复周期中不存在的 item18 而多算为4单元。NMS末项1107起始23,247bit、offset79、21bit→1单元；逻辑表最后字节高4bit及对齐填充保持规定零，16B末端不超过physical_data_end。

## F. 语言、时序与资源契约

本阶段仅静态 JSON 和中文设计；不选择 C++ 实现，不生成参考/RTL/TB。未来独立逐位参考须解释相同记录低位顺序、真容量与零保留位；数学正确不等于物理原子可见。

| RTL规范 §8.2 项 | 当前已知契约或仍缺的依据 |
|---|---|
| A 数值 | index及地址 unsigned；s/e至少42bit，地址和末端先33bit核验再32bit；最大bits512，不有损窄化/回绕；记录内部 signed 字段沿 R4R解释，不对整个payload作signed运算 |
| B 时钟/观察 | 随真正 RC 核心域接受/交付；具体core/FPI域和观察事件未冻结。未来TB在该边沿更新稳定后观察，不在同一活跃区竞态采样 |
| C 接受/交付 | 原一条预期事务，只有真实ready接受；第一条写不能等待下一条请求；完整组及身份核验后交付 |
| D valid/推进 | valid=0不是数值0，不推进记录/单元计数；初始化靠真实范围/世代标志 |
| E 反压/保持 | 停顿保KEY、地址、postimage及sideband；不能重新采样配置；物理不可暂停区需实际容量，尚待预算 |
| F 延迟/吞吐 | 几何证明单record 1…4单元，无实测周期/吞吐承诺；读改写、许可、页分拆和失败收敛增加等待；显示1080p60不充当算法fps |
| G 复位 | 接受禁用、在途身份保留/隔离；外部RAM不因复位清零；实际极性/各域释放机制待接口闭合 |
| H 配置 | 当前已接受H/RJ/布局快照一直保持；更新不能改在途地址或权限；同沿优先级待冻结 |
| I 存储 | 26类服务对象，24个D7工作对象，21个private；真前缀、端口/同址碰撞、最新读视图和有限journal待闭合；不宣称0新增FF/RAM |
| J 身份 | N=2,073,600不变；POINT按E、ANN全N、RECORD全64（F=0仍写规范输出）；实际bundle/ref/version完整传递 |
| K CDC | 本几何解释不新增CDC；真实core↔FPI/DDR若跨域须已有可验证握手/FIFO和复位契约，未用多位直接同步代替 |
| L 实现 | 目标Ti60F225/I3与既有Efinity路线；本卡未选可综合语言/时钟、不启EDA；FF/RAM/DSP、时序和真实物理契约均未闭合 |

共同数值契约：字典字段、上述整数公式及当前26表布局。硬件执行契约：单预期事务、物理多单元/最新视图/管理操作是另外一层，并未实现。跨语言比较：将真实完成后的RC响应值逐位与独立打包参考比对；错误、取消及复位作废事务不能与正常记录比较后假判通过。

## G. 实施与验证计划（均未执行）

未来先闭合 PK-B01…04 → 重审 READY → 指定批准 → 在独立工作副本实现 GEOM/ACCESS/QUALIFY 的批准范围及独立参考/TB → 仿真 → 获准后的综合/布局布线/时序/比特流。具体源码路径、模块符号及可执行命令在 READY 卡中冻结；此卡不创建任何功能性文件。物理接口或授权不匹配即停止该实现，不自动扩范围。
Validation：当前只能做静态字段、整数、哈希/链接核对，不能登记为功能仿真或资源收敛。

| TEST | 目标/输入与事件 | 期望及依据 | 执行前状态 |
|---|---|---|---|
| PK-T01 | REQ02/IF02；POINT首末合法index及index=N | 前者取对应8B并保邻8B；后者无物理请求，依R4R/DIR | 场景，NOT_RUN |
| PK-T02 | REQ03/04；DENSE67、VC7、FIT15、NMS1107 | 单元数2/4/3/1；NMS末字节高4bit和对齐填充为零；邻位保留，越guard禁止 | 场景，NOT_RUN |
| PK-T03 | REQ03；HIST658跨4KiB，物理ready停顿 | 两合法16B子请求，身份/数据稳定，禁止跨页单次burst | 场景，NOT_RUN |
| PK-T04 | REQ04/05；DENSE_ADD跨度相交、任一子写部分失败 | 16计数同最新视图；失败不公布整组成功，未知保隔离 | 场景，NOT_RUN |
| PK-T05 | REQ05；第一POINT写、初始化缺失、E=0管理提交 | 第一写不能死锁/造邻值；缺初始化拒绝副作用；E=0合法管理路径 | 场景，NOT_RUN |
| PK-T06 | REQ01/05；错误KEY、取消/复位遇物理在途、旧配置到达 | 原因类型不cast，身份不串帧，未知物理副作用不伪装关闭 | 场景，NOT_RUN |
| PK-T07 | REQ01/02/05；F=0、三历史bundle仍被显示读取 | 当前ANN全N与RECORD全64规范输出；历史输出不被重清/退休 | 场景，NOT_RUN |
| PK-T08 | REQ02；全部26表、各实例、所有实际余128偏移 | 地址、有效容量、最大单元数、字段零位及预算与独立来源一致 | 仅静态账可检查，功能NOT_RUN |

Failure handling：静态不一致先修本卡/字典；无法证明接口闭合保持NOT_READY。真实物理失败沿E隔离。Rollback：当前只有新文档，恢复/删除需保留已登记历史；不修改批准输入、原始工程或运行状态。

## H. 双向追踪

| REQ与来源 | MOD/IF/局部步骤 | 计划单元 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| PK-REQ-01，R4R D | GEOM/IF01/04、原身份/错误 | RC类型适配（待冻结符号） | T06/T07 | 未实现/未运行 |
| PK-REQ-02，R4R D7 + DIR D | GEOM/IF02、位→字节→单元 | 静态26对象字典；未来几何单元 | T01/T02/T08 | 仅JSON/整数账 |
| PK-REQ-03，DIR/SC权限及R4R写语义 | ACCESS/IF02/03、邻位保留 | 实际span许可/收集更新（待选） | T02/T03/T05 | 未实现/未运行 |
| PK-REQ-04，R4R DENSE_ADD/逻辑成功 | ACCESS/IF03/04、整组最新值 | 分组journal/组门（待选） | T04 | 未实现/未运行 |
| PK-REQ-05，R4R取消/CLOSE + DIR退休 | QUALIFY/IF03/04、隔离及管理 | 物理证明/关闭桥（待选） | T05/T06/T07 | 未实现/未运行 |

反向核对：字典每条object对应R4R一种真实记录和DIR实例；派生对齐不能改变业务记录、凭空增表或造权限。未来每个核心单元须回指上述REQ/IF/TEST，不能为孤立代码临时发明需求。

## I. 门槛与评审

①整体行为/样例、②职责/调查、③接口相容反例、④局部状态/中文草图、⑤语言/映射、⑥边界走查、⑦场景/追踪已有文档；③/④/⑤的物理接口与时序细节仍待闭合。⑧无阻塞未满足（PK-B01…04），⑨本卡与字典保存后须读回/独立检查，⑩范围/来源哈希明确，但不等于获批实施基线。
READY_FOR_REVIEW：否；不向用户请求批准这个尚未闭合的版本。Human approval gates：[唯一v0.2 §10.4](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)要求指定版本与范围明确批准，本阶段不能提前生成业务源码、模型、功能脚本或TB。Manifest/数据库没有新批准，不改正式状态。

## J. 变更与恢复

澄清旧描述“17.5MB尚未映射”：已有生产槽位几何；本卡新增的是当前记录到这些槽位的逐条位/字节解释，并非完成真实硬件映射。当前private清单21项；旧性能草案“23private”不能用作多分两表的依据。保持完整场景，不因容量账降低用户要求。
与旧SL的紧缩字段/互斥复用划清适用版本；本卡不改R4R/DIR/SC/BK，也不扩Q0/R2/R1授权。任何改变记录宽度、基址、初始化策略、并发/组门或物理权限都更新本卡/字典及追踪，再重审批准边界。

## K. 实录

当前只有静态设计/JSON元数据，无RTL、C++、功能脚本、可执行测试、TB、EDA或硬件操作。整数/地址/来源检查及真实文件哈希由独立检查报告登记。编译、仿真、综合、布局布线、时序、bit及实机均NOT_RUN；不会用新字典替代这些结果。

## L. 交付及完成标准

Completed：当前26类/24工作对象的候选打包字典，17,526,269B逻辑、17,526,288B整表round16、17,526,400B当前round64；每record字节补齐为19,100,956B，每record128bit对齐为67,380,480B，后二者只是比较方案，不能沿用现有POINT/ANN槽位。
Completion criteria：PK-B01…04有实际提供者、状态、数值和时间预算；整体/局部/组合草图及全部双向追踪一致；无阻塞并读回独立评审后才可READY。Remaining：访问适配、真实初始化/权限、journal、物理证明与片上资源尚未完成；十一项完整软件实验未完成。人工理解验收待用户实际检验，不把本次解释登记成已理解或硬件通过。
