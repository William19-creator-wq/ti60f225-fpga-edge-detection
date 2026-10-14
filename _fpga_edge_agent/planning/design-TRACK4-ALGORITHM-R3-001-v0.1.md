# TRACK4-ALGORITHM-R3-001：独立 typed 定点数值核 v0.1

2026-10-04。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN**。按 [PLAN_TEMPLATE](PLAN_TEMPLATE.md)；属于 [ALGORITHM-BATCH v0.3](design-TRACK4-ALGORITHM-BATCH-001.md) 的 R3。本文是纯文档候选，没有 RTL、模型、常数生成器、功能脚本、TB、工程或约束。旧数值稿的数学来源与旧物理执行来源分开引用。

## 通用计划字段

- Goal：建立圆及任意旋转矩形所需的独立定点算术、角/投影、LS/TLS、交点及距离核；对每个被接纳的 typed 调用形成一个可保持的值、拒绝、失败或取消结果。
- Current state：原 NUMERIC 的数值提议、ALGORITHMS/EXECUTION 的调用与修订已实际读取；新路线没有业务实现。旧 MC、phase_key、PROFILE 注册表及整机预算不成为本核的隐含前置。
- Target state：独立核的数值、沿事件、有限容量、取消及参考映射可审查；经来源差异/常数/调用适配冻结、独立审阅与指定范围批准后才实施。
- Gap：A2 的 R3-B01…06；共享仲裁、R4 算法/profile/质量、R5 工程与全机资源未闭合。
- Assumptions：单同步 core 域，可暂停调用方；静态 W 偶数 6…1920、H 5…1080，生产仍 1920×1080、N≤2073600。不据此重加目标尺寸、数量、噪声或遮挡验收硬界限。
- Open questions：见 A2；原 P/R≥95%、同类 IoU≥0.5 一对一评价继续由整包/R4 追踪，数值相等不替代它。
- Dependencies：唯一根 v0.2、模板、当前 BATCH/R2、NUMERIC 17C4…、ALGORITHMS D8C4…、EXECUTION F664…；指定外部存储器件相关工作已停止，不调查或恢复。
- Milestones：整体行为→职责/相容交接→typed 表示→逐沿中文步骤→三份映射/验证/追踪→读回/独立审阅→关闭当前阻塞→指定批准→实施及工具验证。
- Detailed steps：阅读 B/C/D，再按 E1…E8 的接受、计算、检查、保持、消费或取消顺序走查。
- State transitions：文档 LOCAL_DESIGN；核状态 QUIET→CHECK→EXECUTE→RESULT_HELD→QUIET。当前没有 READY 或实施批准。
- Artifacts and hashes：本轮只新建此 Markdown；输入实际 SHA 见 A1，产物 SHA/bytes 由全文读回报告给出，正文不自嵌入自身 hash。
- Validation：G 的所有场景 NOT_RUN；没有运行参考、仿真、综合、PNR、STA 或 bit 流程。
- Failure handling：退化候选 LOCAL_REJECT；格式/输入不变量或算术容器破坏 FRAME_FAIL；取消及冷复位另定义，任何失败都不以饱和/回绕伪装值。
- Human approval gates：纯文档授权不等于业务实施；先完成整包指定版本/范围/基线评审和明确批准，既有工作副本、工具及数据库闸门另核查。
- Rollback：仅撤回本稿的候选引用；原来源只读，不修改原设计、正式状态、Manifest、DB 或 HDK。
- Completion criteria：本轮为真实保存、可全文读回的独立候选。R3 运行结果、共享服务、R4/质量、生产资源/时序均未完成。

## A. 状态、来源与阅读入口

任务 TRACK4-ALGORITHM-R3-001，关联 BAT-REQ03/06、原 T4-A6 数值部分。用户要求完整 1080p、圆/任意旋转矩形及原 P/R 目标；停止具体 V4 外部存储器件工作。只授权本稿的文档创建，不批准业务实现。下一允许行动是阅读/审阅和在同一文档内修订设计；本轮结束不自动接续实现。

### A1. 实际来源与采用范围

| 来源 | 本轮读取范围及角色 | 实际 SHA256 |
|---|---|---|
| 根 v0.2 | 全文分段；唯一详细规则 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| PLAN_TEMPLATE | 全文；通用字段+A–L | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| ALGORITHM-BATCH v0.3 | 全文；R3/整包范围与未决交接 | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 |
| ALGORITHM-R2 v0.3 | 全文；signed11 梯度、grad32/双像素身份；424 dir 不改成 θ9 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 |
| RECOGNITION-NUMERIC v0.1 | 全文，D/E/F 数值与拒绝/保持来源 | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A |
| RECOGNITION-ALGORITHMS v0.1 | D/E/F；algorithm2 诊断、有限边、门比较及 font 差异 | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB |
| RECOGNITION-EXECUTION v0.1 | D2、OP02…09；平均 distance39、TLS 六遍、端点、coverage、floor 绘图根 | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178 |

已依入口实际读 AGENTS→config/AGENTS→AGENT_PROMPT→PROJECT_CONFIG→PROJECT_STATE/TASK_LEDGER→database/README，并读 APPROVAL_MANIFEST。数据库仍 NOT_CONFIGURED，正式执行不开启；当前纯文档不访问数据库。控制面规则源 SHA：AGENTS 6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937；config/AGENTS FD0214EA10C9987B6E443F6DBAE8CF006DE441E675EE36918DBD8B85E22FF0A3；AGENT_PROMPT E99F1810394092C8A9D39BEFDA55828D46712F2C49154D315B480DB703CB655C；PROJECT_CONFIG 927C928EC1942CF6BE9C7008426C044F05D6C332C4D6870635196266C2CB9263；PROJECT_STATE 87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558；TASK_LEDGER 190B9AD4718DD2681732E66F20F05EE309A18A7F72015F737D6CC6DA079C00BD；DB README 1EED39B5AAC982842A84450E22D61DF8F99A55A6F2E60D1A6CC5F34F68F1048A；Manifest A582A10DDB993DFE7058AD7EDAE4688505FA1C4F4AA161BD67E35FD59A89DF45。

### A2. 明确保留的 OPEN/BLOCKING

| 项 | 缺口、影响及下一动作 |
|---|---|
| R3-B01 | 本文独立 NUM_ID/接口是新提议，R4 尚未冻结调用 owner、非回绕 call_seq、结果消费/取消和旧 key 适配。影响 IF01…03，须 R4/根联合审阅；不得把旧 phase_key137 截短接入。 |
| R3-B02 | D3的精确有理区间生成、half-cell分离/终止证明、位序及独立比较规则已有候选，尚须独立设计审阅冻结。缺口是该数学/生成合同尚未冻结，不是没有运行生成器。实际常数字节/hash、单调性运行结果均属获批后验证义务，不要求批准前生成业务常量或执行生成器。 |
| R3-B03 | typed 操作/中间宽度与 LS/TLS 分步结构需独立审阅；本文容器和逐沿步骤是候选，不宣称所有调用适配已经批准。 |
| R3-B04 | R4 支撑选择、完整算法存储、profile 快照/阈值实值、候选覆盖/分段/去重/最终诊断调度尚未冻结；R3 不安装旧 PROFILE1024 默认，不证明质量。 |
| R3-B05 | 本轮只单 caller/单事务核；多客户端共享仲裁、公平性、优先级、取消回传及整机并行预算待 R4/R5。旧“共享 scalar”措辞不替代该设计。 |
| R3-B06 | 全文件/参考/TB 的未来实际基线、独立核观察工程与生产时钟/工具/器件实现预算待整包冻结。未运行工具是未来验证义务；当前阻塞是这些接口/结构选择尚未审阅冻结，不能要求先实现才设计。 |

源稿存在需显式覆盖的版本差异，未发现要求擅改 LS/TLS 数学的直接矛盾：algorithm2 的 circle seed 是 ordinal13/high5零而非旧 cell13；最终 fit_* 是冻结几何 inlier 的重算诊断而非原拟合统计；font 占旧 projection word258…355。这三项均不偷继承成 R3 字段。旧 DATA178+2=180/256、NUM6191FF、MC 与物理 key 只属旧范围，不能当新 R3 或整机资源结果。

## B. 整体外部行为

边界外只有可暂停、同域的一个调用适配器；它拥有 job/候选/点集合及阈值选择。R3 拥有一笔已接纳的完整输入、算术工作、ROM pending 和一个结果资格；无文件、外设、MC、共享表、job 注册表或可变全局 profile 副作用。

| REQ | 可检查行为 |
|---|---|
| R3-REQ01 | 每个 req_fire 恰好对应一个 rsp_fire，冷复位作废例外单列；成功、局部退化、帧失败、取消 DROP 区分，原 reason8 保留。 |
| R3-REQ02 | signed/单位/位宽明确，运算先扩位，RNE 正负奇对称；零分母、负根/非法输入及溢出不返回伪合法 0，不饱和/回绕。 |
| R3-REQ03 | 梯度 θ、径向 fullbin、Q15 投影保留原 tie/镜像及不同位宽；POINT θ 和圆周角不可混用。 |
| R3-REQ04 | 圆 LS、TLS、法线距离与交点按原全宽公式；有限量化边按 N/D 精确距离，不能借用 Q30 normal 守卫。 |
| R3-REQ05 | 一笔在途，held 请求/结果和所有 sideband 保持；cancel 不撤已经有效的结果，pending 有预约就 capture/discard；下游不接时不覆盖。 |
| R3-REQ06 | 所有容器/ROM/计数有限；没有隐藏支撑集合或消息副本，不阻止边界外独立任务收尾。 |
| R3-REQ07 | 数学值、硬件真实事件、软件↔事务比较三份独立合同；完整 1080p 与原质量目标由整包持续追踪。 |

正常例：合法三点以上非平行法线统计→LS Δ>0/条件门过→一次 Q4 舍入中心→held VALUE→消费。边界：DIV_RNE(-3,2)=-2、DIV_RNE(-1,2)=0；SQRT_FLOOR(2^192−1)=2^96−1，但 SQRT_RNE 同输入为 2^96，必须用97bit。失败：n≥3 仍可能全法线平行 Δ=0，返回 LOCAL_REJECT/DEGENERATE，不除0。取消：结果已 valid 时本沿 cancel 与 rsp_fire 同时出现，记录真实消费，接收方按旧身份 DISCARD，R3 不更改 body。

无整机 fps/延迟或识别质量成功声明。生产输入域仍 W1920/H1080；小图/少点只覆盖数值边界，不能替代完整算法验收。

## C. 职责、所有者与整体连接

路径：调用方完整 typed 请求 —IF01→ GATE/CHECK —私有启动→ SCALAR 或 ANGLE/PROJECT/FIT/DIST —私有工作→ RESULT —IF02→ 调用方。当前 owner 的 cancel —IF03→ GATE/各私有模块；quiet —IF04→ 调用方安全复用判断。ROM RE/capture —IF05→ ANGLE/PROJECT。阈值实值只从该次请求输入，无反馈读取全局当前参数。

| MOD | 职责、拥有者与非职责 |
|---|---|
| R3-GATE | 唯一接受/输入快照、op/type/padding/范围检查、当前 identity、cancel_seen 和结果资格；不发物理存储命令，不调度候选。 |
| R3-SCALAR | 192bit 操作数、385bit完整乘积/符号 guard、除/根/比较及收窄检查；一个工作单元，不自称已映射一个 DSP。 |
| R3-ANGLE | 向量规范、最多8次 β 表比较和恢复 θu；只持当前向量/ROM pending。 |
| R3-PROJECT | Q15系数恢复及当前点投影；不给 R2 的424方向换编码。 |
| R3-FIT | 当前 LS/TLS 的 frozen 统计、typed 子操作次序/退化/最终几何与诊断；不选择支撑、不重放 POINTS、不重新拟合最终 VC。 |
| R3-DIST | Q30 直线的 exact RNE 残差、交点和有限边 N/D；不把距离值当已满足 profile 门或完整 membership。 |
| R3-RESULT | 一份 held payload/outcome/reason；identity 引用同一 GATE 快照；无第二全 body 队列。 |

以上是逻辑职责，不规定每行对应一个 RTL module。候选分时一份 SCALAR/工作区；任何子运算都必须返回父 controller 再推进，不能形成等新点/外存的依赖环。自写候选，没有可直接复用且已验证的数值 RTL；旧设计只提供数学和读时序依据。

整体检查点是本稿 B/C/D：采用独立一事务核、完整结果保持和显式旧路线适配；A2 未闭合，进入 LOCAL_DESIGN 而非 READY。

## D. typed 接口、格式与组合检查

### D1. 新身份、握手与结果

新提议 NUM_ID176，从低到高：epoch32/frame32/config32/owner8/call_seq64/destination8。三 ID 表示算法 job；owner 目前仅0为独立调用方，1…255 为 UNSUPPORTED，不冒充共享 owner 已分配。call_seq 是调用方拥有的同 job 非回绕序号，不等于目的寄存器编号、候选 ordinal 或物理 service ID；destination8 只指定调用方的目的。序号用尽必须结束并换不冲突 job，不回绕。R3 不缓存历史去重，也不承诺 ALREADY。

IF01 的 NUM_REQ622，低到高：NUM_ID176/W11/H11/numeric_version8（本版1）/kind5/a_signed1/b_signed1/result_bits9/payload400。前206bit为 context；每种 payload 下文按低到高，余位必须0。调用方全部 body 在 valid=1 且 ready=0 时保持；正沿 req_fire=valid&&ready 原子接纳，核只在旧 QUIET/无pending/无结果时 ready，不同沿透传结果。

IF02 的 NUM_RESP585，低到高：原NUM_ID176/kind5/result_bits9/outcome2/reason8/value385。结果形成沿后 valid，最早下一沿 rsp_fire。outcome0 VALUE、1 LOCAL_REJECT、2 FRAME_FAIL、3 CANCEL_DROP；非 VALUE 的 value385=0。kind/result_bits 和 identity 均原请求，形成后至 rsp_fire 不变。scalar符号值 sign_extend 到385、unsigned值 zero_extend；COMPARE低2bit为0相等/1小于/2大于，余0。复合结果按D2逐字段装入：每个signed子字段在自身宽度内二补码，高padding恒0，不能把整个记录sign_extend；复合result_bits=0由kind解码固定布局，不表示VALUE没有字段。

reason8沿旧数值原义：0 NONE、1 GRAD_ZERO、2 FORMAT、3 COORD、4 DEGENERATE、5 ILL_CONDITION、6 GEOM_RANGE、7 COUNT、8 ARITH_OVERFLOW、9 CAPACITY、10 PROFILE、11 DIV_ZERO、12 UNSUPPORTED、13 INTERNAL；14…255非法。退化/拟合几何域外为 LOCAL_REJECT，非法已接纳输入/不变量破坏为 FRAME_FAIL。具体候选范围是否造成 FN/整任务失败由 R4 统计，R3 不隐藏它。

IF03：当前唯一 owner 提供 cancel_valid 与 cancel_id176，并保持到目标义务实际关闭；不是“取消即完成”的ACK。只有与已持 context 或本沿 req_fire 的完整 ID 相等才取消该调用；错 ID 不改变核状态。cancel 不组合撤 req_ready，不撤已提出 held req；同沿真实 req_fire 先登记，新接纳调用可转 CANCEL_DROP。调用方停止新的业务请求，但已 valid 的请求需兑现接受或与整域冷复位共同作废。

已有效结果不改写为 DROP，取消方具有独立本地接收/DISCARD资格，不能依普通“存目的寄存器” ready 才消费。未暴露结果的私有计算可在 pending 关闭后形成 CANCEL_DROP。IF04 quiet=旧 QUIET 且无 ROM/scalar pending/结果资格；它只证明 R3 私有资源可复用，不返还 R4 表/物理租约。消费沿提交 QUIET 后，下一沿才允许新 req_fire。

### D2. 操作类别与 payload

所有 op 先检查 W/H/numeric_version、类型、保留位，再计算。复合 op 的 a_signed/b_signed/result_bits 必须0，返回下面固定布局。scalar 的 result_bits 必须1…该操作完整上界，调用适配必须按 D4 的真实用途给出目标宽度；先算完整真值再检查所请求容器，禁止为省位默截。

| kind | 操作/输入payload400低到高 | 输出 VALUE 低位/输入前提 |
|---|---|---|
| 0/1/2 | MUL/ADD/SUB：A192/B192/zero16；signed flags分别解释A/B | MUL完整384+guard385；ADD/SUB完整signed194；MUL/ADD任一signed则signed，SUB恒signed；最终按result_bits检查 |
| 3 | DIV_RNE：A192/B192/zero16 | B正，分母signed时检查>0；numerator按a_signed；完整商/舍入guard193后检查目标，不接受负分母偷改符号 |
| 4 | SQRT_RNE：A192/zero208；flags都0 | unsigned A，floor96，RNE97；不是默认96bit |
| 5 | COMPARE：A192/B192/zero16 | 分别sign/zero扩signed193后比较；result_bits=2 |
| 6 | DIV_FLOOR_U：A192/B192/zero16；flags都0 | B>0；unsigned floor商192，不与RNE合并 |
| 7 | SQRT_FLOOR：A192/zero208；flags都0 | unsigned floor根96，不与RNE97合并 |
| 8 | ANGLE_GRAD：Gx signed11/Gy signed11/zero378 | 检查每分量±1020、非零；输出θ9，其余0；EDGE合法性/坐标来自调用方 |
| 9 | ANGLE_RADIAL：dx signed19/dy signed19/zero362 | 核实际abs可收uint18、非零；输出θu10/half1/fullbin10/sector6/zero358；零径向LOCAL_REJECT，θu512不可先截θ9 |
| 10 | PROJECT_POINT：x11/y11/targetθ9/zero369 | x<W,y<H；输出q signed9/r9/zero367；r0…276 |
| 11 | CIRCLE_LS：n21/A43/B signed44/C43/D signed56/F signed56/det_min16/zero121 | n3…N、A/C≥0、Δ>0且条件门；输出cx signed18/cy signed18/n21/quality16/zero312，不在此拟半径 |
| 12 | TLS_LINE：n21/Sx signed33/Sy signed33/Sxx43/Syy43/Sxy signed44/anis_min16/zero167 | n2…N、PSD及非isotropic；输出nx signed32/ny signed32/tx signed32/ty signed32/rho signed18/μ signed18/anis16/K65/M33/zero107；有效278+padding107=385 |
| 13 | LINE_INTERSECT：两组nx signed32/ny signed32/rho signed18，共164/zero236 | 两normal先检查分量/非零及K守卫；den≠0；输出xQ4 signed18/yQ4 signed18/zero349；角门由调用方另核 |
| 14 | LINE_DISTANCE：nx signed32/ny signed32/rho signed18/x11/y11/zero296 | 合法Q30 normal及图内点；输出q uint21/K65/M33/zero266；exact RNE距离，不收16bit |
| 15 | FINITE_EDGE_DISTANCE：Ax18/Ay18/Bx18/By18均signedQ4、x11/y11/zero306 | 合法有限非零边/图内点；输出N uint78/D uint39/q uint19/zero249；exact距离平方=N/D，q是RNE sqrt(N/D) |
| 16 | COEFF_Q15：targetθ9/zero391 | 输出C signed17/S signed17/zero351，范围±32768；给算法合法缓存加载，不借R3存16组batch |
| 17 | LS_DIAGNOSTIC：n21/A43/B signed44/C43/D signed56/F signed56/zero137 | 最终冻结inlier统计；核n3…N、trace>0/Δ>0；输出n21/quality16/zero348，不计算或检查新中心 |
| 18 | TLS_DIAGNOSTIC：n21/Sx signed33/Sy signed33/Sxx43/Syy43/Sxy signed44/zero183 | 最终冻结inlier统计；核n2…N、PSD/trace>0/非isotropic；输出n21/anis16/zero348，不计算或检查新normal/rho/端点 |
| 19…31 | 未定义 | FRAME_FAIL/UNSUPPORTED，不能按旧op3的6/7解释 |

scalar negative denominator 若算法公式允许，适配器须在扩位域同时变号 numerator/denominator 后才发请求；不能在本次请求外悄悄变号。最负signed192取abs先扩signed193后形成uint192；拒绝或窄化只在完整真值已可判定之后。

### D3. 单位、常数与范围

signed均二补码，坐标为像素中心，Q4 v表示v/16px；half-pixel X2/Y2 与绝对Q4不能相加。门限UNORM16以65535表示1，非2^16；q残差平方是Q8，mean门用 SSE≤limit_Q8·support。n/支持统计uint21≤N，增加先扩22bit检查；本核接收冻结统计而不重复选点计数。

θ ROM：k0…127，β=(k+0.5)π/512，C/S=RNE(2^30 cos/sinβ)，均uint30；entry低30为C、高30为S，每entry60bit按低20先存word3k…3k+2，128×60=384有效20word。projection ROM：octant k0…128，C=RNE(32768cos(kπ/512))、S=RNE(32768sin(kπ/512))，Q15 unsigned16，各一个20word，地址2k为C/2k+1为S，高4零，共258word。两ROM各native20×512，1R、无WE。只读REQ按目的槽预约，eK RE→沿后RAM输出更新→eK+1 preedge capture。不得同沿RE即当新值读取。

本独立候选不用font；projection258…511/θ384…511规范0。这只属于R3 standalone ROM镜像，**不覆盖**旧ALGORITHMS font258…355：未来共享/合并ROM须R4/R5显式模式、pending关闭和常数hash；不能各自生成相互覆盖的镜像。当前B02未冻结实际整数表。

ROM生成合同候选（纯中文步骤，未生成程序）：把每个角的π系数作为精确有理数；π用16atan(1/5)−4atan(1/239)的恒等式，以交错有理级数上下界取得有理π区间，负系数取相反端点。先核0<π下界≤π上界≤4；所有角系数≤1/4，故外包端点在[0,1]，不假设k128的包络≤实际π/4。sin/cos在该[0,1]有理覆盖域以交错Taylor部分和与首个省略项界取得上下界；用sin单调增/cos单调减将角区间传播，所有计算为有理数/大整数，不把浮点近似当精确RNE。初轮8项，未分离时项数倍增，直到乘2^30或32768的完整区间落入同一个最近整数的half-cell；端点相等按RNE偶数定义处理，记录所得整数。零角sin0/cos1为解析精确值。随后按本节位序填有效word、检查类型上界，padding和未用word置0。

终止依据候选：这些角均为π的有理倍数。sinθ=cos(π/2−θ)，后者同为有理π角，因而两种分量都可用对应单位根ζ。若分量等于二进制half-cell所需的(2j+1)/2^(Q+1)，则两倍分量是有理数；由ζ+ζ⁻¹为代数整数可知该有理数必须整数，而(2j+1)/2^Q（Q15或30）不是整数，矛盾。因此没有half-cell等号，区间误差趋0时每个常数在有限轮分离；有限个常数全部有限终止。设计审阅须核这一证明和区间传播，不能设固定浮点精度后假定舍入正确。获批后再实际生成/hash，并由独立区间实现/解析轴对角值和表单调性核对全部常数；运行证据NOT_RUN，不能构成“先生成才能READY”的循环门槛。

### D4. 实际调用适配与宽度

| 真实来源/调用 | 保留的输入、中间、结果要求 | R3对接及尚缺点 |
|---|---|---|
| NUMERIC E2/D2 | 梯度m/M10、乘积40/cross41；径向m/M18、乘积48/cross49，θu10 | kind8/9；R2 dir2保留，不能用θ9覆盖grad32的dir字段 |
| NUMERIC E3/ALGORITHMS OP03 | X2/Y2先s13后s12，系数s17，product29/sum30，q9/r9 | kind10/16；R4拥有POINT/targetθ与batch缓存，R3没有票表 |
| NUMERIC E4/EX OP02 A/C | LS263；Δs89、Nx/Nys101、Q4分子s105 | kind11；freeze成员与n_expected由R4，不把结果出值当五遍拟合完成 |
| EX OP02 B/D | distance先uint18，sum_distance39/n21，经RNE后才查r17 | scalar MUL/ADD/SQRT_RNE/DIV_RNE；不得把根结果预收17后再检查域；radius与多峰路线属R4 |
| NUMERIC E5/EX OP05 | TLS217；D133<<32为165→根83；t85→L被开方171/根86；t<<30分子115→Q30s32 | kind12；传完整统计与阈值，不调用coarseθ取代TLS；六遍成员冻结/端点由R4 |
| EX OP05 端点恢复 | Bn=2^30ρ、Bt=2^30tQ4+8[t·(W−1,H−1)]；完整den非假定±2^60 | scalar逐式乘/加/除；Bn保守s49、Bt保守s50、den65、交点分子保守s83；参数有实际域检查，不追加复合op掩盖R4适配未冻结 |
| NUMERIC E5法线残差/交点 | f50、K65/M33、q21；f²K交叉乘≤165；交点分子81/den65 | kind13/14；nearest边比较用原f²/K而非q或M；资格/门/侧号由R4 |
| ALGORITHMS OP06/EX OP07 | d/p s19、z/c s39、K39；N78/D39，NiDj≤117 | kind15及scalar全宽比较；最终量化有限边，不沿用Q30 K≥2^58守卫 |
| EX OP07 exact coverage | Q38/A40/V40/B17/Ts77/Us59；T²154、U²K157有效位 | scalar full乘积385再高位检查收容器；R4拥有clipping/bitmap/区间并集，不用RNE根代替exact门 |
| EX OP08 ANN annulus | Q5C±Rhi s21；Ao/Ai先全宽非负，画行区间需要floor√Ao、floor√(Ai−1) | kind7直接floor；原先RNE后检查减1的路线与其数值等价需未来对照，不把RNE97名字当floor96 |
| NUMERIC D2/D3比例与SSE | support/eligible21；inlier q≤65535后q²32，总SSE53；mean_limit_Q8_32×support21为53bit，score分子65535×support为37bit | scalar全宽乘/除/比较；score才RNE收16，门用原交叉乘；eligible0拒绝，不在R3持候选统计表 |
| ALGORITHMS OP06最终fit诊断 | 同一冻结inlier遍重算LS263/四TLS217，不能重新拟合改变geometry | kind17/18独立诊断，只产n/quality，不求新中心/normal/rho；不得因未使用的新拟合几何越域而误拒冻结geometry |

旧 NUM_REQ543/RESP540 的 phase_key137、destination8/op3 与新NUM_REQ622/RESP585不相容。旧key不得只取epoch/frame/config；必须由可信旧ctx显式恢复当前算法job、已分配owner/call_seq及原destination，保存映射直到旧结果消费/取消关闭。当前没有这份映射表容量、旧key解析的完整来源和R4接收终态，故B01 OPEN，不生成转换器。旧physical req/W/terminal/release/borrow从来不属于R3。

### D5. 组合检查与端到端反例

上游给完整冻结类型/统计→R3只用快照→一结果→调用方按同ID/目的消费；一笔容量不需要全job/每模块重复206bit。反压不会改变请求快照/ROM地址；bubble不当零点。只有真实交付后释放，不把形成valid当完成。

反例1：ANGLE_RADIAL(-10000,16)得到θu512/half0/full512/sector32，提前θ9=0会错半圆；(10000,-16)raw1024应full0/sector0。反例2：有限边很短，K<2^58仍完全合法，套Q30守卫会漏目标。反例3：UNORM overlap舍入65535不能判集合相等，union2073600/both2073599须保留；这是R4 exact交叉门，R3的RNE除法不是dedup谓词。反例4：等待普通目的ready才处理取消held结果，会使旧caller等待quiet而核等待caller互等；IF03独立DISCARD打破此环。

## E. 局部状态与中文逐沿操作

### E1. 通用接受、旧状态与结果保持

QUIET时只观察沿前请求。e0 req_fire锁context206、kind/类型/target、payload400，尚不启动ROM/计算；同沿匹配cancel记cancel_seen。e1 CHECK核尺寸/版本/padding/类型及专用前提；错误准备非VALUE，合法则把旧快照送私有工作并进入EXECUTE。没有req_fire不改identity或计数。

EXECUTE每沿只消费旧算术/旧capture完成事实，再决定下一子操作；新capture/新乘积不会同沿被当已提交值使用。子操作不接受第二外部请求。完成先核完整真值/域/target_width，形成385bit结果；进入RESULT_HELD后的沿才可rsp_fire。结果stall只保持结果/identity，不重复运算或计数。rsp_fire后的下一沿可复用，不能同沿换新context影响旧输出。

INV01：live调用数≤1；INV02：result valid至fire body不变；INV03：accepted=consumed+live，冷复位作废单列；INV04：所有窄化前检查；INV05：ROM pending总数≤1，capture目的已预约；INV06：取消不改变已有效结果；INV07：无R3“完成”信号替代外部资源关闭。

### E2. 乘、加减、除、根与比较

MUL先将signed输入扩位取绝对值，保留结果符号；12个16bit digit/operand。逐列0…22，每沿最多登记一个16×16部分积及旧carry：一列至多12项，累加uint37、carry20。列完检查并写一个16bit结果word；第24个word来自末carry，先查carry高于16bit零再写入，不能只出23word。形成unsigned384后在385bit域恢复符号，再检查目标。144部分积、24word和符号/检查是步骤预算，非144沿固定延迟或一DSP声明。

ADD/SUB先各自sign/zero扩signed193，在signed194算完整和/差；serial16bit digit先保存旧进位，末guard检查。COMPARE只比较分别扩到signed193的两输入，返回固定编码，不能按raw unsigned bit排序负数。

DIV检查正B；192次restoring位步骤，用uint193 remainder、uint192 floor quotient。每沿消费旧shift/余数与当前原numerator bit，比较减法后提交新余数/商；末步后一沿确认0≤r<B。DIV_FLOOR_U直接出floor；DIV_RNE比较2r与B，等号取q的偶数，加一在193bit guard后恢复numerator符号。B0为DIV_ZERO，绝不返回0商；有符号最负值abs使用扩位。负分母规范动作必须在算法适配式里可见。

SQRT对unsigned A以两bit/restoring步骤，最多96步，余数保守193、floor root96存于97bit根容器。完成核k²≤A<(k+1)²，分别比较完整平方，不以截断试探根判断。SQRT_FLOOR出k；SQRT_RNE精确比较4A与(2k+1)²，前者小取k、大取k+1，等号取偶。整数A下半整数根tie不发生，但仍明定tie政策。4A可到194bit，**不能送仅A192/B192的普通COMPARE后截断**：内部保留385bit平方，另一侧由保存A显式zero_extend到385再左移2比较；root+1先97bit。原NUMERIC最大171被开方所需86步不能当新A192上界。

所有私有round/check基于旧已完成根/商；完成沿与RESULT_HELD可见沿分开。平方/乘法通过同一SCALAR，目标较窄只在高位资格检查后写typed目的。

### E3. ROM、折叠角与投影

ANGLE先规范到y≥0（原半平面另存）；M>0、m≤M。以[0,128]的129个fold结果找首个未越过β：cross=mC−MS，cross>0才越界，cross≤0选较小fold q；最多8次，不声称7次能判129bins。每次先锁k/预约三word，再每RE下一沿capture；最后word capture后一沿才cross/更新二分边界。cancel/stall仍接预约读，capture后可DISCARD。

恢复θu：x≥0且|x|≥y→q；x≥0且|x|<y→256−q；x<0且|x|<y→256+q；其余512−q。gradient的θ=θu mod512；radial的fullbin=(θu+512half) mod1024，加法先uint11容1024。sector=fullbin>>4。cross tie是较小fold，不承诺全θ较小。

PROJECT先读两完整20word并检查高4零，恢复signed17 C/S：θ0…128取k=θ的(C,S)；129…256取k=256−θ的(S,C)；257…384取k=θ−256的(−S,C)；385…511取k=512−θ的(−C,S)。交换/取负在signed17域进行，cos0=32768不收signed16。X2=2x−(W−1)、Y2同式先s13后检查收s12；prod s29、sum s30；q=RNE(P/2^19) s9，q+138先s10核[-138,138]/[0,276]后收r9。ρ半像素中心16q，镜像276−r、r138自镜；stride512余235不投票由R4保证。COEFF只输出恢复系数，不保留batch历史。

### E4. 圆 LS

输入冻结n/A/B/C/D/F；统计来源a=Gy、b=−Gx、d=ax+by s24，A/C43、B44、D/F56，n21。核n≤N、n≥3、A/C不负；CIRCLE_LS本核不重新访问点。

按子操作顺序形成Δ=AC−B² s89、Nx=DC−BF及Ny=AF−BD s101。Δ≤0局部退化；T=A+C>0，完整比较4Δ·65535≥det_min·T²；未过ILL_CONDITION。Nx/Ny先扩s105再<<4，分母正，分别RNE除法；中心收s18前查域。quality=RNE(65535·4Δ/T²) uint16并核0…65535。返回中心/n/quality；不会替调用方估半径或改变支撑。

LS_DIAGNOSTIC采用同一冻结LS统计的T/Δ/quality式，n/trace/Δ守卫后直接形成诊断；D/F保持输入事实但不用于新中心求解，没有det_min输入或新中心域门。R4若要按未舍入condition另作接受门，须独立用原统计全宽式，不把舍入quality当相同门。此分支不调用CIRCLE_LS后随便丢几何字段。

调用方平均半径使用实际原成员、相对新中心的距离uint18，总和39、n21，只一次RNE sum/n后查1…131071；重放n不符为R4 INTERNAL。必须传完整距离给求和，不能在此核内默收17bit。

### E5. TLS、规范方向、rho及交点

冻结217bit统计。先s67算Cxx=nSxx−Sx²、Cyy、Cxy=nSxy−SxSy；n≥2，核Cxx/Cyy≥0及CxxCyy−Cxy²≥0，失败INTERNAL。经域检查收Cxx/Cyy u64、Cxy s65；u=Cxx−Cyy s65、v=2Cxy s66、D=u²+v² u133，D0局部isotropic退化。

Rq16=RNE_sqrt(D<<32)，输入165、根83。u≥0取t=(Rq16+(u<<16),v<<16)，否则t=(v<<16,Rq16−(u<<16))，两s85；L=RNE_sqrt(tx²+ty²)，输入171/根86，L>0。各t<<30在s115分子后RNE除L，收s32且每分量±2^30。n=(-ty,tx)，规范ny>0或ny=0且nx≥0；然后唯一切向t=(ny,−nx)。normal反号时切向/rho/μ也按相应规范重算，R4的端点区间(-thi,-tlo)与censored交换不能省略。

anis门完整比较Rq16·65535≥anis_min·((Cxx+Cyy)<<16)，anis=RNE(65535Rq16/((Cxx+Cyy)<<16))。rho_Q4只一次RNE：8[nxSx+nySy+n(nx(W−1)+ny(H−1))]/(n2^30)。μ_Q4=RNE(8(txSx+tySy)/(n2^30))；不先舍入均值。保守rho/μ分子s69、den u52足够；s18域检查后返回。K=nx²+ny² u65、M=RNE_sqrtK u33，核分量与K≥2^58；合法TLS主要t分量≥65536、L近整数范数，归一向量长度>2^29，满足守卫。

TLS_DIAGNOSTIC只执行协方差/PSD/trace/D/Rq16/anis的相同全宽式；trace0或D0局部拒绝，PSD破坏失败；此后直接输出n/anis，不计算t/L/normal/rho/μ，不施加新几何域门或anis_min。最终required侧/可见侧和阈值的整体判定由R4冻结，不重新拟合geometry。

交点两normal/rho快照：den=nx0ny1−ny0nx1 s65；分子分别(rho0ny1−rho1ny0)·2^30、(nx0rho1−nx1rho0)·2^30，保守s81。den0局部退化，负den先在扩位域同时变号；一次RNE后查x/y s18，不clip。正交/平行门、四点CCW/非自交/面积及三边语义由R4；单个交点VALUE不证明矩形成立。

### E6. 两种 exact 距离必须分开

LINE_DISTANCE：f=16(nx x+ny y)−2^30rho_Q4 s50，K65≥2^58、M33。q0=RNE(absf/M) u21；|f|≤2^49、sqrtK/M≥2^29，近似norm使未舍入距离差≤2^-10，q0距真RNE最多1。令F4=4f²：低边界(2q0−1)²K（q0>0）、高边界(2q0+1)²K，比较全宽≤109。若低于低边界或等且q0奇减1；若高于高边界或等且q0奇加1；否则不变。修正后再次核边界，不满足INTERNAL，不无界迭代。出q21，R4门前不能收16。nearest直线用fi²Kj/fj²Ki exact比较，tie低边号，不比较q或近似f/M。

FINITE_EDGE_DISTANCE：p=16P−A、d=B−A s19，K=d·d u39、z=p·d/c=p×d s39；K0局部退化。z≤0取N=|p|²、D=1；z≥K取N=|16P−B|²、D=1；内部N=c² u78、D=K39。端点平方不因signed乘法变负，先完整扩位后检查。无Q30/K≥2^58限制。RNE sqrt(N/D)以单调整数边界4N vs (2k+1)²D二分，q合法上界<2^19；最多19个bit决策及最终上下界核验，ties-even。返回N/D和q19；R4 nearest有限边比较NiDj/NjDi≤117、tie低侧号。

法向、eligible/inlier、capsule均用全宽平方门：finite法向(G·d)²·65535²≤tol²·|G|²·K；stroke full宽 s 时capsule 4N≤s²D。circle annulus Rlo²≤4D≤Rhi²；不得先RNE距离再替代这些边界门。R3只给数值，不加入隐藏present/支撑/颜色过滤。

### E7. 工作区、资源及模式寿命

以下是本候选的保守有限容器，非综合XLR、旧6191FF扣减或整机总数。

| 容器 | 个数×位宽/bit | 唯一owner、同时寿命/复用 |
|---|---|---|
| 输入context | 1×206=206 | GATE；req_fire至rsp_fire，结果identity引用，不另复制176 |
| 输入kind/type/target及payload | 1×416=416 | GATE；保持原完整输入，执行寄存器可破坏性移位但不改快照 |
| 结果payload/metadata/valid | 385+5+9+2+8+1=410 | RESULT；不另存完整585bit输出body |
| typed工作区 | 16×192=3072 | FIT/ANGLE/DIST排他；每slot按阶段标有效/类型，不能靠未初始化高位 |
| scalar数据 | A/B384+full385+remainder193+root97+MAC37+carry20=1116 | SCALAR；所有完整乘积保留384/385，第24word不省；root/quot可排他使用full低位 |
| scalar控制 | 1×256=256 | 列/部分积/digit/除根步/符号/round/typed收窄状态，有限候选上界，不当0FF |
| 常数capture | 60+40=100 | ANGLE/PROJECT排他；projection两完整word先查padding |
| ROM pending元数据 | 1×28=28 | purpose2/address9/entry8/word2/capture_mask3/dest2/valid1/reserved1；同一context，不再加全key |
| 外层控制 | 1×128=128 | FSM、cancel_seen、子操作busy/valid/dest/统计域guard、有限比较循环计数；不得拿此抽象余量藏新队列 |
| FF容器已列小计 | **5732bit** | standalone候选，无独立job/profile/多owner注册表及R4数据库 |
| 两只读ROM | 2×20×512=20480bit，2RAM10 | θ384word、projection258word；无font、无支撑表 |

TLS工作槽候选：w0/1/2协方差、w3/4 u/v、w5 D、w6 Rq16、w7/8 t、w9 L、w10/11 normal、w12 K、w13 M、w14 rho、w15 μ/anis两不重叠字段。trace/PSD及临时乘积利用原stats快照/SCALAR full寄存器；每个结果真正写入目标后才改用途。LS用同一16槽保存T/Δ/Nx/Ny/两分子/中心/quality，不与TLS并活。LINE/FINITE distance也排他，R4四边缓存由R4另计；没有四份R3核或四份context。

full乘积须在下一子乘前完成检查/窄化/搬入typed工作槽；保留值超过192bit时只能在SCALAR full存活，不得另发覆盖它的乘法。SQRT的194bit round比较按E2从原A快照展开，不新建194bit隐藏存储。R4 coverage乘积有效≤157时检查完整高零后收typed槽；此可用性不推广到任意385bit外部调用链。

同步ROM one pending，申请/捕获不随结果stall重新发。停止后capture/discard才清pending；仅冷复位可以共同作废。2RAM/5732bit是设计容器预算，DSP目标未冻结，16×16逻辑乘不能冒称一个Ti60硬DSP；实际RAM推断、100MHz/25MHz选择、PNR/STA及全机共存均OPEN。旧180/225RAM及全机利用率不引用为本核结果。

### E8. cancel、冷复位与关闭

每沿先登记旧req_fire/rsp_fire/ROM capture及已完成子操作，再观察匹配cancel。已有valid响应必须原body消费；未valid且无pending可形成CANCEL_DROP；有pending时次沿按原purpose capture后DISCARD，关闭所有私有工作再形成DROP。不得等新的点、外存或普通destination ready才能DROP消费。cancel_seen不因取消电平拉低提前恢复当前调用。

rst为本core同步高有效冷复位：屏蔽全部fire、清有效状态/计数/pending/context资格，不功能清零ROM。调用方及结果消费者同域共同作废在途ID；这是唯一允许不产生rsp_fire的例外，必须单独记录被作废调用。没有外部承诺，因此不继承旧暖rst/MC保留规则；若未来接入有独立外部义务的共享控制器，需要R4/R5重新设计边界，不能把cold reset当普通cancel。释放后第一沿仅QUIET，下一真实req再开始。rst不证明外部CDC/复位同步。

## F. 语言、RTL A–L与三份映射

候选RTL为SV2009；时序非阻塞、组合阻塞、显式signed/扩位，无锁存/隐式窄化。未来参考沿整包选择现有Python标准库；本轮不生成模型，不引入C++，C++对象/别名/异常为N/A，因为没有选用C++实现。

| RTL项 | 本核契约 |
|---|---|
| A数值 | D/E的每个型、单位和guard；unsigned192 floor根96/RNE根97，整数除/RNE分开；full乘积384+385符号guard |
| B时钟/观察 | 单core正沿，沿前握手/旧状态计算/沿后提交；TB在更新稳定后观察形成值，下一沿preedge消费；未冻结生产时钟 |
| C接受/交付 | IF01/02各valid&&ready，一live；ready只旧空闲；没有旁路或输出形成同沿消费 |
| D有效/推进 | req无fire不改输入；ROM/子操作完成可排尾；valid0不是0数；统计输入是冻结body |
| E反压/保持 | 请求与结果全部payload/identity/type不变；output堵塞不再接受；pending有预约照capture |
| F延迟/吞吐 | θ≤8比较、DIV≤192位/根≤96组、MUL144部分积/24word是步骤界；控制/搬运/ROM另计，最早输出至少晚于接受；stall使等待无有限墙钟上界 |
| G复位 | E8同步冷复位共同作废；ordinary cancel保持有效结果/关闭pending；ROM仅valid隔离 |
| H配置 | version/W/H/阈值都在请求fire快照，运行中不看全局profile；同时外部更新不改变已接纳body |
| I存储 | 2ROM只读20×512、预约目的、1pending、次沿capture；16×192工作区排他，所有FF上界E7，无动态分配或支撑数据库 |
| J身份 | 新NUM_ID176/完整job三ID，call_seq64非回绕，原图x/y，θu/half与θ9分开；fixed typed一输入一结果 |
| K CDC | 本核无CDC；调用方必须同域，外部异步cancel/结果不能直接连接；未来CDC另冻结 |
| L实现 | 独立Ti60F225软件目标/SV2009；具体top/pin/时钟/资源与工具基线待整包，5732bit/2RAM不是综合网表，DSP/STA未测 |

共同数值合同：独立整数参考直接数学式、大整数除/平方比较，显式RNE/保留位/收窄/拒绝，冻结整数ROM后逐位比较；理想实数θ与Q30表分类可能不同，误差目标与逐位分类分开。Q30分量误差≤2^-31，角扰动保守≤10^-9rad，最近角误差≤π/1024加该项；未经输入分离证明不声称与无限精度β全域同分桶。

硬件执行合同：真实req/rsp/capture事件、旧值与形成沿、stall/cancel/reset资格独立检查；不能用Python函数返回或循环次序替代E的时间状态。

对应合同：软件每个typed调用对应同NUM_ID/kind的一笔硬件req_fire；VALUE逐位比完整385表示，拒绝比outcome/reason/零payload。取消已valid结果按原值比较后标DISCARD，未暴露结果比DROP；冷复位作废调用单列，不补成0结果。算法点/候选/最终record的对应、顺序及profile由R4适配，不凭destination8猜其来源；完整P/R由独立GT质量证据另判。

## G. 实施与未来验证计划（均NOT_RUN）

实施顺序候选：先冻结op/identity/常数镜像→独立scalar/typed门→ANGLE/PROJECT→LS/TLS/距离→取消/held组合→R4调用适配→独立观察与工具工程。未来文件位置拟在work/active/track4_algorithms_20261004/r3/，职责名numeric_gate/scalar/angle/project/fit/distance/result及独立reference/协议TB；仅为计划，本轮不创建工作树或业务文件。遇来源hash变化、相邻接口未冻结、重要宽度/舍入/取消变化先修订；指定批准前停止。

| TEST | 覆盖与输入/事件 | 期望/方法与通过标准 |
|---|---|---|
| R3-T01 | signed192最负、unsigned192最大、混合ADD、SUB、target0/过窄、padding非0 | 大整数直接运算；full guard/原reason，收窄前报错不回绕 |
| R3-T02 | DIV0、负分母、±1/2、±3/2、±5/2、余数刚跨半 | RNE偶及奇对称；floor与RNE各自逐位，negative divisor不静默接纳 |
| R3-T03 | square及其±1、A0/1、2^192−1、floor96/RNE97、最后根步 | 比4A与奇平方；最大值floor2^96−1、RNE2^96；194bit比较高位不丢 |
| R3-T04 | gradient四轴/对角/G与−G、β cross正负0、两端bins | θ0/128/256/384，129结果≤8比较；独立冻结ROM oracle |
| R3-T05 | 两径向跨π反例、径向0、幅度不属gradient域 | θu512/half/fullbin保持；0 LOCAL_REJECT，绝不先截θ9 |
| R3-T06 | projection cos0=32768、θ511/0、ρ半cell ties/极端图内坐标 | signed17系数，r138自镜、276−r；P s30/RNE逐位 |
| R3-T07 | LS平行/近退化/条件恰等/n>N/中心域外 | Δ/条件全宽及一次Q4舍入；退化拒绝，计数/容器错误失败 |
| R3-T08 | TLS水平/竖直/斜线/isotropic/PSD破坏、规范方向与均值半值 | 非退化细方向、217→165/171根与rho单次舍入；不锁θ9 |
| R3-T09 | den0/负den/近平行交点，归一normal长度非精确1、q0±1和边界tie | 一次交点RNE；LINE exact距离/K守卫/门前q21，nearest不比q |
| R3-T10 | finite短边/端点/投影0或K、极短K、四边等距 | N/D及exact平方边界；小K合法，tie由R4低边号，不错借Q30守卫 |
| R3-T11 | ROM三个word分沿、stall/取消晚到/下一调用不同ID | 次沿capture，预约槽/原context不混，pending≤1 |
| R3-T12 | req/rsp长stall、cancel同req/同rsp/已valid、错cancelID、reset各状态 | 一req一结果/明确cold作废、held不变、独立DISCARD到quiet，无互等 |
| R3-T13 | EX五遍圆/六遍TLS/final诊断/coverage与ANNfloor的真实调用适配；synthetic合法stats使完整LS/TLS的新几何越域，但trace/PSD/Δ/D诊断资格成立 | kind17/18按固定37bit诊断出值、不运行新几何域门，不把完整拟合的GEOM_RANGE当诊断失败；同原quality式/原identity，不回写geometry；R4适配未定前仅计划 |
| R3-T14 | 全1080p坐标域、真实R4圆/任意旋转矩形/P-R质量集 | 数值与算法质量分开；小输入不代替全图，原P/R95%与IoU0.5不放宽 |
| R3-T15 | standalone实际编译/综合、防裁剪有效扇出、RAM/DSP/FF/PNR/STA/bit | 工程基线冻结/批准后取得真实报告；E7预算不当PASS，无本轮执行 |

独立参考不复制digit/restoring/二分FSM作为唯一oracle；可直接整数除、整数平方根与有理数平方门验证数学，再单独检查硬件调度。未来每项登记时钟/随机种子/调度/许可和实际证据，观察形成与消费分开。未跑测试不单独阻塞纯设计，当前A2来源/交接/结构尚需冻结。

## H. 双向追踪

| REQ与来源 | MOD/IF/步骤 | 计划稳定职责（未生成） | TEST | 实际代码/证据 |
|---|---|---|---|---|
| REQ01/05，新独立事务派生 | GATE/RESULT，IF01…04/E1/E8 | numeric_gate/result/identity/held/cancel_seen | T11/12 | 待实现/NOT_RUN |
| REQ02，NUMERIC D1/F | SCALAR，D2/E2/E7 | full_product/div_round/sqrt_round/check_narrow | T01…03 | 待实现/NOT_RUN |
| REQ03，NUMERIC E2/E3、R2 grad | ANGLE/PROJECT，IF05/E3 | folded_angle/theta_u/q15/project | T04…06 | 待实现/NOT_RUN |
| REQ04，NUMERIC E4/E5 | FIT/DIST，E4…6 | circle_ls/tls_line/intersect/line_distance | T07…10 | 待实现/NOT_RUN |
| REQ04，ALGORITHMS OP06冻结fit诊断 | FIT，kind17/18，D2/D4/E4/E5 | ls_diagnostic/tls_diagnostic，不产生新几何 | T07/08/13 | 待实现/NOT_RUN |
| REQ04，ALGORITHMS/EX有限边/coverage | DIST/SCALAR，D4/E6 | finite_edge_distance/full_square_compare | T10/13 | 待实现/NOT_RUN，R4适配OPEN |
| REQ06，有限所有权派生 | 全部，E7/IF04 | scratch_owner/rom_pending/scalar_live | T11/12/15 | 容器候选，非综合网表 |
| REQ07，BAT-REQ03/06及原T4-A6 | F三份映射/G/H | reference/协议与质量观察职责 | T13…15 | 待实现/NOT_RUN，质量未闭合 |

反向：所有计划算术、ROM和控制单元只服务上表；没有R3新增物理存储、profile数据库、采样/排序/去重/renderer职责。实现后每个核心符号按批准版本回填并核实际数据/状态/测试，不以目录名冒充存在源码。

## I. 门槛与审阅

v0.2 §10.3：①B行为/例、②C职责/真实来源、③D候选接口/相容、④E状态/中文步骤、⑤F A–L/三份映射、⑥D5组合走查、⑦G/H计划追踪均有可审候选；⑧无当前阻塞不满足（A2），⑨本稿保存/全文读回以本轮实际报告证明，⑩版本/范围/输入hash明确但整包适配/工程基线未冻。因此**NOT_READY**，无READY时间，无用户实施批准，不修改正式Manifest/DB状态。

根Agent可将本稿加入整包审阅；只读独立审阅关闭A2后才能决定相应有限范围READY，不能从“文件已写/手工计算”推导整包或实现通过。批准停止点是指定本稿版本、完整实现范围/路径及相关基线；当前不索取未成熟实现批准。

## J. 变更与恢复

v0.1首次新建，原NUMERIC/ALGORITHMS/EXECUTION/R2/BATCH字节不修改。显式差异：新622/585独立消息/NUM_ID176；去掉旧physical key/MC/PROFILE依赖；scalar增加unsigned floor除/floor根，A192根round guard97；复合LS/TLS/距离 typed 输出；kind17/18独立final诊断，不求新几何，避免无用几何域门影响诊断；旧font共享模式不偷复制。opcode/固定payload、终态与H追踪随此区别同步，未修改原LS/TLS数学式。

恢复先读当前文档/来源hash/整包适配/有效批准，再核差异。常数、宽度、round/tie、拒绝分类、owner/call_seq、cancel/reset或重要存储改变须更新D/E/G/H并重审；已有同范围有效批准才可沿用。撤回设计不执行删除参考文件或状态回滚。

## K. 实录

本轮动作仅按顺序读控制面、根规则/模板、BATCH/R2和指定数值来源，手工设计审查，创建此一Markdown并实际全文读回。R3 RTL/模型/常数生成器/功能脚本/TB/project/SDC均未生成；编译/功能仿真/综合/PT/PNR/STA/bit/硬件/网络/安装/DB执行均NOT_RUN。来源实读不等于业务功能测试或测得资源。

## L. 阅读与交付

阅读顺序：B整体输入/结果→C唯一owner/连接→D新身份/typed op/旧调用适配→E1旧沿事件→E2 scalar→E3 ROM→E4/E5拟合→E6距离→E7容器→E8取消→F/G/H映射/验证/追踪。术语：held是已有效且尚未消费；RNE是最近且平值取偶；LOCAL_REJECT是当前候选退化，不是成功空对象。

一条事务路径：调用方锁LS279有效字段及context→e0接受→e1检查→逐子运算登记全宽Δ/条件/分子→检查中心/quality→沿后提出原ID的VALUE→stall保持→未来rsp_fire消费→下一沿复用。若途中cancel且无有效结果，先关闭旧ROM/算术pending后形成DROP；若已valid，原VALUE消费后DISCARD。修改数值查D/E及T01…10；修改owner/取消查D1/E1/E8/T11/12；修改算法membership/质量先改R4，不在R3另塞过滤。

当前交付仅设计候选；文档—注释—代码—测试一致性需获批实施后按实际符号再核。功能验收/生产时序/质量未运行，理解验收待用户真实反馈，不把阅读问答当实施额外闸门。
