# TRACK4-ALGORITHM-R3-SCALAR-001：识别用整数算术模块 v1

2026-10-06。设计评审候选；保存与完整读回之前为 LOCAL_DESIGN，读回记录决定 READY_FOR_REVIEW。**NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。本文按 PLAN_TEMPLATE 的短卡形式填写，不含实现、常数、可执行测试或脚本。

## A. 范围、基线与阅读顺序

Goal：先实现可复用的整数乘、加减、比较、除和平方根，为后续圆/旋转矩形识别提供一个可以单独验证、综合和布局布线的数值模块。Current state：R1/R2 已有独立软件交付，R3 全核 v0.2 是未批准候选。Target state：本范围获批后交付精确标识的单元代码、参考、TB、中文阅读稿及 Ti60F225/I3 独立验证工程。Gap：业务实现、仿真和物理证据均未生成。

范围继承 R3 v0.2 的 D1/D2、E1/E2/E8、F 中 scalar 数学、消息和取消规则，仅实现 kind 0–7。kind 8–31 在本模块返回 FRAME_FAIL/UNSUPPORTED；这不是完整 R3 核的实现，也不改变完整 R3 将来支持 8–18 的目标。角表、投影、LS/TLS、交点、距离及 R4 调用适配由后续模块负责。完整 1080p、完整 Canny、原识别质量、板载 DDR3 和整包生产 I/O 目标继续保留。

本卡独立核的输入是冻结消息，一个同域可暂停调用方即可使用；不需要先批准 R4 的共享 owner、候选数据库或 DDR 接口。owner 只接受 0。未来 R4 必须按完整 NUM_ID176 分配调用并消费结果，不可截断旧 key。R3-B01/B04/B05 仍是整合事项；B02 的 ROM 常数不进入这个 scalar 模块；本卡将 scalar 的具体文件、验证工程和执行预算从 B06 拆出，不宣布完整 R3 的六项缺口均已消失。

文档入口：A 范围→B 输入输出→C 交接→D 局部中文步骤→E 语言/物理工程→F 测试→G 追踪→H 审批。规则是工程根唯一 v0.2；模板、R3 原稿、R1 reset_sync、R2 三份工程配置和既有工具入口冻结到 `ALGO-R3-SCALAR-BL-20261006-v1`。基线文件位于 `experiments/track4_algorithms_20261004/01_baseline/algorithm-r3-scalar-baseline-v1.json`；设计自身 hash 放在独立读回报告，避免自引用。

拟实施根：`work/active/track4_algorithms_20261004/r3_scalar`，使用既有 ASCII Work 链接；批准前不存在、不创建。原 HDK、既有 R1/R2 和冻结输入只读。新源码、工程和功能脚本只在新根生成。日志保留到各自独立 runs/<run-id>，发布仅 staging；正式 DB、PROJECT_STATE、TASK_LEDGER 和硬件状态不改。工具继承现有安装，不下载、安装、联网、修改许可或原保护 IP。

拟请求指定 v1、基线和下文 13 文件范围，允许现有 Python/Questa/Efinity 的独立软件验证、必要检查通过后的 bit/hex 登记，以及本批本地 JSONL 审计例外。此前 R2 批准不授权本卡。目前没有向用户提交本卡实施批准问题；DDR Q0 请求独立等待答复。

## B. 可观察行为与数值消息

| REQ | 可检查要求 |
|---|---|
| S01 | 单笔在途；接受后恰好一个同身份结果，冷复位作废单列；结果保持至真实消费 |
| S02 | kind 0–7 精确整数数学，全宽运算后检查目标宽度；不饱和、截断或回绕冒充成功 |
| S03 | 最近取整采用平值取偶，负数奇对称；floor 除/根保持独立语义 |
| S04 | 格式、类型、尺寸、版本、操作及分母错误返回 FRAME_FAIL、固定 reason 和零 value |
| S05 | 匹配取消只覆盖未暴露响应；已 valid 的全部响应保持；冷复位禁止本沿 fire |
| S06 | 有限容器和有限私有计算；无 DDR、ROM、队列或多调用方仲裁的隐含依赖 |
| S07 | 软件数学参考、实际 RTL 事件和逐位比对独立记录，失败证据保留 |
| S08 | 独立四引脚默认 1080p 上下文工程保留算术数据路径，完成工具/资源/时序检查后才能生成 bit/hex |

输入 req_body622 从低到高为 NUM_ID176、W11、H11、numeric_version8、kind5、a_signed1、b_signed1、result_bits9、payload400。NUM_ID176 低到高是 epoch32/frame32/config32/owner8/call_seq64/destination8。数字都是位宽，没有把 frame/context 当数学操作数。version=1、owner=0，W 为偶数 6…1920，H 为 5…1080；生产默认仍 W1920/H1080。调用方同一 job 的 call_seq64 不回绕；模块不缓存历史去重。

响应 rsp_body585 低到高为原 ID176、kind5、result_bits9、outcome2、reason8、value385。outcome0 VALUE/reason0；outcome2 FRAME_FAIL/reason非零；outcome3 CANCEL_DROP/reason0。非 VALUE 的 value 恒0；本 scalar 范围不会输出 LOCAL_REJECT=1。取消后已有效的 VALUE/错误按原 body 被接收方丢弃，不能强改成 DROP。

| kind | payload400（低到高）及类型 | 完整真值、结果上界/target |
|---|---|---|
| 0 MUL | A192/B192/zero16，flags 分别解释两操作数 | 384 位幅度、385 位符号域；result_bits 1…385；任一 flag 为1则结果按 signed 目标检查，否则 unsigned |
| 1 ADD | 同上 | 分别扩至 signed193，在 signed194 算和；target 1…194；任一输入 signed 则 signed 目标，否则 unsigned |
| 2 SUB | 同上 | 同域算差 signed194；target 1…194，目标恒 signed |
| 3 DIV_RNE | 同上；A 按 flag，B 必须严格正 | 幅度 floor 商192，round guard193，恢复 A 符号；target 1…193，a_signed 决定目标 signed/unsigned |
| 4 SQRT_RNE | A192/zero208，flags都0 | unsigned floor96、RNE97；target 1…97 |
| 5 COMPARE | A192/B192/zero16，flags分别解释 | sign/zero 扩 signed193 比较；target 必须2；value 低2位：相等0、小于1、大于2，高383位0 |
| 6 DIV_FLOOR_U | A192/B192/zero16，flags都0 | B>0；unsigned floor 商192，target 1…192 |
| 7 SQRT_FLOOR | A192/zero208，flags都0 | unsigned floor 根96，target 1…96 |

所有 signed scalar 成功值在385位二补码符号扩展，unsigned成功值零扩展。target 是允许容器，不是要求计算前截断输入。signed target b 的合法域为 −2^(b−1)…2^(b−1)−1；unsigned为0…2^b−1。最负 signed192 的 abs 要先扩 signed193，不在原192域直接取负。MUL unsigned result_bits385 允许额外零 guard；不把最高0位当符号解释。

CHECK 的唯一首错次序：尺寸 COORD3→version/owner/kind UNSUPPORTED12→flags/target FORMAT2→payload padding FORMAT2→操作分母。B=0 为 DIV_ZERO11；DIV_RNE 的 signed 负 B 为 FORMAT2，不能在核中悄改符号。计算后 target 不够为 ARITH_OVERFLOW8；内部算法不变量失败为 INTERNAL13。上述全部是 FRAME_FAIL。多个错误按检查阶段顺序返回首错，取消优先按 D6。reason14…255 不输出。

例：DIV_RNE(−3,2)=−2，DIV_RNE(−1,2)=0；unsigned SUB(0,1) 的 signed1目标可收−1；signed1目标不能收+1。A=2^192−1 的 floor 根为2^96−1，RNE根为2^96，后者 target96 必须报溢出、target97 才成功。输入 kind12 不会误触发除法或给出伪 TLS 值。

## C. 模块职责、端口与组合

路径：同域调用方—IF-S01→ scalar_core 接受/检查/分时计算/结果—IF-S02→同域消费者；cancel—IF-S03→同一核。独立工程的 probe_top 是调用方兼串行观察者；reset_sync 提供 core_rst。没有依赖外存、等待另一个调用或等待新点的环路。

| MOD / 计划符号 | 数据拥有者和职责 |
|---|---|
| scalar_protocol_pkg | 定义622/585/176消息宽度、kind/outcome/reason及字段位置；不含时序状态或业务常数表 |
| scalar_core | req_fire 锁唯一输入；CHECK 固定首错；排他复用私有乘/除/根工作；完整值资格检查后形成结果；控制和数学属于同一事务 |
| scalar_probe_top | 同域合成请求源、一个真实响应槽、585位串行CRC和进度LED；不能据 LED 证明数学正确，数学由TB/独立参考检查 |
| reset_sync | 按冻结 R1 源码复制；两级异步置0/同步释放，再提供同步高 core_rst；不复制旧 R1 业务处理链 |

IF-S01：clk 正沿，rst同步高；req_valid 输入、req_ready输出、req_body622输入。沿前 rst=0且valid&&ready 才接纳。ready 只在旧 QUIET、无响应时为1；取消不组合撤 ready。调用方在 held req 期间保持整个 body。没有 req_fire 就不改上下文或工作计数。

IF-S02：rsp_valid输出、rsp_ready输入、rsp_body585输出。形成结果的边沿后才valid，最早下一沿消费。结果堵塞时所有位保持，不接受新请求；rsp_fire 后提交 QUIET，下一沿才可接新请求。quiet 输出表示旧QUIET且无结果/私有工作；它不代表外部表、DDR事务或生产job已关闭。

IF-S03：cancel_valid输入/cancel_id176输入，精确全ID相等才匹配。匹配已接纳ID或同沿req_fire的新ID均可取消。调用方保持取消要求到该事务消费或共同冷复位；错ID不影响本核。取消方必须具备消费/丢弃旧held响应的能力，不能等待quiet才给ready而互锁。

IF-S04：probe clk_25m/key1_n/led0/led1 四个板外端口；KEY接reset_sync，内部无CDC。核心请求 W/H 固定1920/1080，不用小图参数通过物理检查。LED0反映每1024笔消费批次的进度翻转；LED1输出滚动CRC bit0。它们是异步观察信号，没有板外同步采样时钟。

端到端：probe 输入槽先形成完整请求→core接受快照→probe禁止覆盖→core形成held响应→probe预留槽接收→串行585位观察完成才下一请求。故有限容量是输入槽1/响应槽1/core在途1，无须FIFO。外部通用调用方可独立让rsp_ready反压；单元TB检查这种边界。

## D. 局部中文逐拍草图

### D1 接受、检查、资格

e0 沿前旧QUIET，req_fire锁622位原输入，并记同沿匹配cancel；不启动计算。e1 CHECK只读旧快照，按 B 的顺序判格式。e2 SETUP 才锁私有幅度/符号/计数，并进入对应计算状态。无效输入准备固定错误体；结果没有旁路同沿消费。所有时序寄存器非阻塞更新，组合中间值只用于本沿的新状态；不能把刚更新寄存器当已完成值。

完成后先用完整真值判类型/target，再 PACK，随后进入 HELD。HELD时仅响应消费可释放；计算寄存器不因持续valid重新启动。输入标识保存到原响应真实交付，响应ID引用输入槽，不另建历史表。accepted=consumed+live+reset_aborted，live≤1，计数只是验证不变量，不要求核保存无限历史。

### D2 共享乘法与加减/比较

MUL 保存两幅度192及符号。拆成各12个16位digit；列0…22，当前列只有 i+j=column 且 i/j均0…11的部分积有效。INIT_COLUMN用旧carry初始化acc37；PARTIAL每沿最多算一个显式unsigned16×16→uint32，并扩37加旧acc；没有第二个并行乘法。EMIT独立沿写本列低16位，carry=acc>>16。最多12项，每项≤(2^16−1)^2，旧carry保守20位，因此37位足够；高位守卫不可省。最后第23号word来自末carry，先核其高于16位全0。形成384位幅度后在385位域恢复符号。完整144项、23列初始化/发出及最后word都必须登记，不能遗漏最后16位。

ADD/SUB将A/B按flags各扩signed193，再扩signed194，按16位digit串行执行。工作操作数使用208位组合符号扩展视图，不另建208位寄存器副本；13个digit的每次结果写入既有full低208位，保存旧进位，SUB先在该域对B取反并以初始carry1相加。末尾检查低194位与高14位符号关系，不能用raw低192位判断溢出。COMPARE只在扩signed193域给0/1/2，不用unsigned原码给负数排序。

乘法私有引擎还供平方根的最终全宽平方检查使用。内部请求只由同一事务controller发起；保存原payload不被破坏。引擎完成值在父状态下一沿才消费，上一full搬入响应或比较完成后才允许覆盖；不是第二外部调用。

### D3 除法

正B守卫通过后，商192/余数193置0，保存原|A|。从最高位到最低位做192次restoring：先将旧余数左移1并带入当前numerator位，在193位比较B的零扩值，大于等于则减B并将该商位置1，否则置0。每沿只处理一个位，提交后步数减1；末步后一沿核0≤remainder<B。floor_U直接取商；RNE比较完整193位的2r与B，r<B≤2^192−1故2r保留193位。小于半不增、大于半增、等号仅旧floor商奇数才增。增1用193位guard，再在385位恢复原A符号。不得先在192位舍入或用SV对负数的除法替代数学RNE。

### D4 平方根

unsigned A 的192位按最高两位一组，共96组。每步临时余数=(旧余数<<2)|当前pair，在193位形成 trial=(旧root<<2)|1；临时余数≥trial时减trial、root=(旧root<<1)|1，否则root<<1。root使用97位容器；完成后floor有效不超过96位。通过同一乘引擎检查 k²≤A<(k+1)²；k+1先97位，平方不截断。

floor模式保留k；RNE另完整比较 4A 与 (2k+1)²，均扩385位再计算。小于取k、大于取k+1、相等取偶数（整数A不产生半整数根的等号，但策略仍唯一）。4A最大194位，不能塞回192位普通COMPARE。所有根/round/guard只读上一沿已完成的值；私有平方不会改原外部操作kind或已锁输入。

### D5 有限状态与容器

大状态 QUIET→CHECK→SETUP→EXEC→QUALIFY→PACK→HELD→QUIET；EXEC内部明确 mul初始化/项/发出/末word、div位、sqrt组及平方返回状态。控制计数有明确上界：mul digit0…11/column0…22，div steps0…192，sqrt steps0…96。不存在动态分配或未限定循环。内部无输入输出反压的私有计算最长4096个core边沿形成响应；该值含三次根相关平方、控制搬运和格式检查的保守预算，获批后以每个真实接受/形成沿差验证。外部held等待不计此上界，可能无限。

| 独立核容器预算 | 位数/解释 |
|---|---|
| 原请求 | 622，直到响应消费/复位；ID不另复制 |
| 结果 | value385+kind5+target9+outcome2+reason8+valid1=410；身份引用原请求 |
| 私有算术 | A/B384+full385+remainder193+quotient192+root97+acc37+carry20=1308；非并行核副本 |
| 控制余量 | 192，FSM/循环/符号/内部目的/取消及有效标记；新增状态寄存器必须列出，不藏新数据数组 |
| 核候选FF容器小计 | 2532位，不是实际映射FF/XLR |
| probe候选 | LFSR384+held req622+held rsp585+sequence64+CRC32+bit_index10+控制128+reset2=1827位；总4359位设计预算 |

无RAM/ROM推断需求。16×16乘法是一份逻辑运算，不承诺正好一个Ti60DSP，实际 FF/LUT/XLR/DSP由Map/Pnr报告。独立装载计划资源门槛是器件硬容量内、25MHzsetup/hold通过、无内部unconstrained/no_clock/multiple_clock；不存在擅定整机剩余空间或算法FPS的结论。

### D6 取消、复位和恢复

本沿优先：①rst=1禁止所有fire，清资格/计数，调用方/消费者同域共同作废live；②沿前rsp_valid=1，全部body保持，rsp_fire记录消费，即使同沿cancel也不改body；③尚未valid且本沿匹配cancel或旧cancel_seen，私有计算终止并丢弃未暴露值/错误，下一结果为DROP/reason0/value0；④无取消才继续首错或数学出值。本范围所有私有计算是内部寄存器运算，没有ROM或外部pending，因此取消不需要等待外存回执；引擎资格与controller一起关停，不延迟发出旧乘结果。请求接受同沿匹配取消也先登记一笔调用，再交付DROP。

rst同步高冷复位，旧live没有响应时记录reset_aborted，不伪补零结果。释放后的首个沿处于QUIET，接下来的有效请求按普通流程接受；数据寄存器可以不功能清零，但资格必须隔离且SETUP完整初始化读写槽。KEY的异步断言/同步释放只在reset_sync实现，core不另接异步KEY。

### D7 独立观察顶层

使用384位固定递推LFSR：每次真实req_fire后左移1，新bit0为旧bit383 xor382 xor380 xor377；非零初值为低位1。这只是可复现输入源，不宣称最大周期或随机分布质量。kind按已消费调用序号低3位轮换；MUL/ADD/SUB/COMPARE的二位值{b_signed,a_signed}等于序号bits[4:3]，DIV_RNE的a_signed为序号bit3、b_signed0；其余flags0。A=旧LFSR低192，B=高192；除法B的bit0置1保证严格正unsigned，其余操作不改B。root padding规范0。target采用 B 中完整上界，COMPARE为2。epoch=1/frame=0/config=1，owner0，call_seq为初值0的非回绕64位实际序号，destination零扩kind至8位。序号达到最大值后停止新请求，消费最后结果并停机，不能回绕。

一个输入槽形成后保持至req_fire。一个响应槽在旧空闲时才rsp_ready；rsp_fire锁585位body，再串行处理bit584…0：CRC初值FFFFFFFF，每bit以旧bit31 xor当前数据决定左移及异或04C11DB7。585步后提交滚动CRC并释放槽，才形成下一请求。只在真实消费时更新调用序号，每1024笔形成批次进度翻转。core与串行CRC不并行消费同一body；没有旁路同沿形成/处理槽数据。顶层不比较固定预期CRC；TB独立计算每笔数学响应及同序观察结果。默认测试跑完1024笔，再复位并跑恢复段。

## E. 语言、时钟、实现和操作边界

RTL SV2009，时序非阻塞、组合阻塞，变量part-select明确范围，先扩位后运算，禁止 latch/隐式 signed 混算/未检查窄化。数学参考采用既有Python标准库大整数、divmod/isqrt及直接式，不复制硬件restoring/列乘FSM作为唯一oracle；C++未采用，C++对象/指针/异常条款不适用。

共同数值合同为B/D的精确整数、padding、类型、round与错误。硬件执行合同为clk正沿旧状态、真实req/rsp/cancel/reset事件和形成后valid。映射合同为每个实际req_fire的原完整body对应模型一次调用；非VALUE比outcome/reason/value0，VALUE比585位完整响应；取消/held/冷复位另按真实时序账本，不用函数返回补不存在的交付。

| RTL A–L | 本范围采用合同 |
|---|---|
| A | B/D全宽、类型、比较及收窄守卫，无浮点 |
| B | 单core正沿；TB在沿前采握手，沿后稳定读形成状态，下一沿才记消费；不与NBA竞争 |
| C/D | S01/02 valid&&ready，rst屏蔽；无fire不推进调用身份，私有计算按状态推进 |
| E | held输入/输出全body保持；输出反压禁止新接受；取消遵守D6 |
| F | 私有形成≤4096沿；取消未valid≤3沿形成DROP；外部反压不设墙钟上限 |
| G | 同域冷复位作废，KEY仅通过两级reset_sync；不证明整机CDC |
| H | W/H/version/type/target全在req_fire采样，运行中不读外部当前配置 |
| I | 全部寄存器有限，probe各槽1；无RAM读延迟/同址冲突，因为本范围没有RAM访问 |
| J | ID176不截短，不自动去重；一输入一结果，复位单列；无像素数变换 |
| K | 内部无CDC；异步调用/取消接入另需适配设计 |
| L | Ti60F225/I3，25MHz40ns，SV2009，现有Questa/Efinity；实际fit/STA未测 |

Efinity默认 top `scalar_probe_top`，reset_sync实例名reset_adapter。按冻结R2工程形式生成新xml/peri/sdc，不修改旧工程。clk_25m J2/1A 1.8V GCLK，key1_n P13/BR3.3V，led0 N14、led1 P14/BR3.3V drive4；来源是已经工具验证的独立R2配置，实板供电仍待人工。只对KEY到两级异步SR实际唯一端点、两个异步LED端口设例外；两级Q→D和第二级Q→core reset/数据资格路径保留分析，不能整域false_path或multicycle放过算术。

允许新runner按现有CLI map→interface→pnr→postroute报告/查询→release gate→pgm file generation顺序操作。需保存实际argv/cwd/起止/exit/timeout、输入快照、原日志及warnings；查询节点须实际存在，零匹配为失败。检查实际映射输入→算术→held结果→CRC→LED的数据路径，不能拿clock/CE/reset路径代替。物理顶层不改操作数位宽或只观察低位通过。若工具合法优化无用padding，保留逻辑完整消息合同并记录被优化位，不声称所有585位均是动态网线。

工具预算：reference600s、compile/vopt各600s、每sim900s；Map/Interface各3600s、Pnr7200s、postroute查询600s、Bit1800s。超时只终止本次确切进程树，保留日志；每≤30s可检查并沟通。首次失败跳过依赖阶段，不自动无穷重试。发现实现错误可在同一批准合同下先修订中文草图、保留失败、生成新attempt验证；新增输入、改变数学/消息/引脚/取消合同须修订设计重新批准。

## F. 13文件实施顺序与验证场景（全部未运行）

1. `rtl/scalar_protocol_pkg.sv`、`rtl/scalar_core.sv`：先实现C/B/D的消息、状态、共享运算和结果；`model/scalar_reference.py`、`model/scalar_vectors.py`：独立数学、有限场景及输入解析。
2. `tb/tb_scalar_core.sv`、`scripts/run_scalar_sim.ps1`：先单元完整逐位及真实事件账本；输入错误直接失败，不跳过测试。
3. `rtl/reset_sync.sv`原字节复制、`rtl/scalar_probe_top.sv`、`tb/tb_scalar_probe_top.sv`：验证真实请求→算术→585位观察→进度/复位恢复。
4. `project/scalar_probe.xml`、`.peri.xml`、`.sdc`和`scripts/run_scalar_build.ps1`：冻结本次源码清单后做物理实现/时序/门禁/bit登记。共13文件，其中4RTL、2model、2TB、2runner、3project；另中文docs和证据元数据不计业务文件数。

| TEST | 目标/明确期望/来源 |
|---|---|
| SC-01 | 八种操作基础值、0/1/−1、最负signed192和最大unsigned192；每项逐位等于B直接数学，不复制RTL状态机 |
| SC-02 | MUL四flags、全12×12digit参与、高word及完整384/385符号guard；最大值、交错digit、单bit191；全宽乘积与数学大整数一致 |
| SC-03 | ADD/SUB混合signed、193/194位进位、target1与临界宽；能容纳就精确值，超域FRAME_FAIL/OVERFLOW |
| SC-04 | DIV_RNE的±1/2、±3/2、±5/2、刚越half、B1、B最大及A最负；RNE平值取偶/奇对称；FLOOR_U同输入分开比较 |
| SC-05 | floor/RNE根0/1、perfect square±1、最高192位、2^192−1及target96/97；4A194位守卫、k/k+1平方全宽正确 |
| SC-06 | unsigned/signed比较四flags、符号边界；只返回0/1/2，target非2为FORMAT |
| SC-07 | W/H边界/奇W、version、owner、kind8…31、flags/target、payloadpadding、B0/负B，多错次序；按B首错及完整零value |
| SC-08 | 2048笔确定种子20261006的随机数学向量：八kind各256，类型/合法target按操作合同；按直接数学可成功或溢出，不预删失败样本 |
| SC-09 | 输入气泡/held及held输入同沿取消/真实fire、输出反压0…31沿；body保持，accepted/consumed/live账本无漏/重；形成不能记消费 |
| SC-10 | 错ID取消、接受同沿、CHECK/SETUP/每个私有状态的匹配取消、数学完成同沿、held结果、held消费同沿；D6优先与DROP/保持唯一 |
| SC-11 | 各大状态及私有乘/除/根状态冷rst、held未消费rst、rst与req/rsp同沿、释放后新请求；作废明确计数且无旧ID复活 |
| SC-12 | 每个有效/错误输入形成沿≤4096；未valid取消≤3；压力串联10000笔与不同ready事件序列，逐事件账本/顺序精确；这不是图像FPS验证 |
| SC-13 | 默认probe1024笔全链逐位响应/585位CRC/LED进度，二级KEY释放、复位后32笔恢复；实际source生成的body送独立模型，不能只比较预生成源 |
| SC-14 | Ti60/I3编译/Map/PT/PNR/STA及release：全部必要测试通过、源snapshot无漂移、资源不超容量、setup/hold非负、内部缺钟/未约束0、定向数据路径存在，才允许bit/hex |

每类需细分可识别子样本与实际状态覆盖，输出期望数/实际接受/形成/消费/取消/复位及全body保持计数、时钟沿号、seed和source SHA，不能一个PASS遮蔽未到达状态。SC-10/11未到达的子状态为缺覆盖，不是默认通过。数学输入解析必须拒绝缺字段/宽度越界/坏hex/多余尾记录；TB或模型错误须非零退出，至少保留一次有明确预期的致错退出探针，探针不修改生产源码。

## G. 双向追踪及失败/交付

| REQ | MOD/IF/草图 | 计划文件/TEST | 当前证据 |
|---|---|---|---|
| S01/S05 | core/IF01…03/D1,D6 | core+TB；09…12 | 未实现/未运行 |
| S02/S03/S04 | pkg/core/B,D2…4 | pkg/core/reference/vectors；01…08 | 未实现/未运行 |
| S06 | core/probe/D5,D7 | core/probe；09…14 | 仅设计容量/步骤上界 |
| S07 | reference/TB/runner/E,F | 两model/两TB/sim runner；01…13及致错探针 | 未运行 |
| S08 | probe/reset/IF04/E | probe/reset/三project/build runner；13/14 | 未运行 |

反向：pkg字段为S01/02/04；每个算术状态为S02/03/06；资格/cancel/reset为S01/05；probe源及CRC为S07/08的数据可观察性，不替代用户图像功能；project约束为S08；所有runner只落实S07/08的冻结、真实退出和失败保留，不写正式DB或硬件状态。出现无对应需求的核心逻辑先补必要性解释，不直接扩范围。

Completion criteria：13文件和中文操作/代码阅读文档一致；SC01…14及适用子覆盖有真实结果，必要物理检查通过；staging记录源码/工具/约束/证据/bithex SHA；停止硬件步骤。若任一失败，保留状态、报告未完成，不能仍生成登记为可用bit。局部成功不宣布完整识别或整板性能达标。

Rollback是停止使用该attempt并保留证据，后续修订新版本/目录；不删除或覆盖旧源码/日志/基线。理解验收以用户实际答复为依据，尚未作答标待检验，不把文档呈现当已理解。

## H. 门槛、批准和实录

十项：①B完整行为/例；②C必要模块/复用；③C接口/组合；④D状态/存储/中文草图；⑤E语言/三份映射；⑥B/C/F正常及故障走查；⑦F/G文件/测试/双向追踪；⑧本scalar独立范围无DDR/ROM/R4前置未知，实际工具结果是批准后验证义务；⑨保存/全文读回/呈现待检查报告；⑩v1/13文件/独立work/基线明确。第⑨完成且基线逐项一致后才记 READY_FOR_REVIEW，不能以该状态代替批准。

目前业务源码、参考、runner、TB、工程、sim、Map/PT/PNR/STA及bit全部 NOT_RUN/NOT_IMPLEMENTED。新work不存在。PostgreSQL仍未配置；需要指定本批本地审计例外，不自动继承R2。正式审批/硬件闸门保持现状。本卡批准、实际实施与最终文档一致性另记审批伴随文档和runs，本文不伪写正式Manifest已更新。

停止点：READY后等用户明确批准本v1、ALGO-R3-SCALAR-BL-20261006-v1和本范围及本批本地审计。新用户指令可改变或批准范围；没有指定批准不得生成业务源码。DDR Q0是另一项已经呈现的预检，不能将其批准视为本算术模块批准。
