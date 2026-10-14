# FIT共用操作数选择器与定宽槽组合 v1

- Goal：推进完整五基础/六高阶/1080p在单Ti60F225共存，针对原宽计划选择网络显式复用两个192位操作数选择器，不减少七类FIT/精度/范围。
- Current state：独立FIT局部优化实际43501 LUT/2696 ADD/8357 FF，typed_slots已生成、编译/展开通过，完整动态仍在运行。只读数出130个call_scalar调用点的两个参数共47种不同表达式。
- Target state：步骤分支只选择6位来源码和原22位命令头，最后由两个共用来源选择器形成完整A/B；同时保留定宽槽v1。外部622/585、176身份、真实子交接及周期数不变。
- Gap：源表达式在宽case中反复写，是否实际减少LUT待MAP；typed基础未动态完成，不能引用为已通过，新组合必须独立完整验证。
- Assumptions：所有130处表达式能在已读47来源表中精确对应；不引入同步ROM/新流水或预取，不改变命令形成时刻。
- Open questions：当前选择表示无未知；资源收益和typed/组合正确性是本获准软件实验实际测量对象，未完成不自证。整机/DDR/CSI/识别/PNR/STA另继续。
- Dependencies：typed当前RTL/TB及原底层/数学/旧参考、typed设计、原字节来源/资源说明、规范与现有工具；仅复制独立work，不改正在运行的typed源。
- Milestones：整体与中文局部草图→读回呈现→work/fit_operand_shared→完整旧核/数学/槽和命令对照→同设置MAP→真实预算登记。
- Detailed steps：先固定47来源码，保持所有控制分支，仅改call_scalar最后两参数为来源码；task只写头/selector，plan尾端恢复原406位命令。见E。
- State transitions：READY_FOR_REVIEW v1；用户持续“自行进行，无需批准”及local audit覆盖本软件范围；不伪造新逐版批准或正式DB/H0。
- Artifacts and hashes：6新/适配文件（RTL、TB、sim/map两个脚本、XML/SDC）+7原样依赖=13源/工程；15冻结输入，见A。来源表直接在本设计/RTL常量中，不新增隐藏ROM文件或代码生成器。
- Validation：完整原14517固定向量、每沿旧/new全公共/私有正文和握手、全有效槽/合法局部提交、原取消/reset/cache/全状态、独立数学及实际MAP。不降低测试量或用两份新实现互证。
- Failure handling：控制/时间/全值不等价则FAIL保存，不改旧数学/参考/种子/容差；收益0/负保留。若typed基础失败，同时审查影响，本组合不借其状态自动PASS。
- Human approval gates：仅自主软件和本地审计，正式数据库/状态/硬件不动。
- Rollback：新work单元，不修改fit_local_resource、fit_typed_slots、原HDK/安装或注册产物。
- Completion criteria：本完整组合实际证据，不是缩小为少数kind；完整项目仍ACTIVE。

## A 版本、基线和阅读

2026-10-10 v1，关联A6/R0。先B整体→C/D连接→E中文语句→F语言→G/H测试与追踪，后源码。typed源SHA `D84544127D5AAE45CC14620A1D50590626171AFF87A9285F0593AED4D6E17B6E`，存储设计SHA `E9523D329EB5F2BD68B6F84C10D45316A27F9E6F848E4D4937D35873A8FFA6FA`。该基础是正在动态验证的输入，不能称已完成；真正独立旧参考为R3，只改过声明名/换行，数学模型原样。

15输入：typed RTL/TB、旧参考；4底层RTL；2数学；规范；typed设计；本设计；原source-binding-note；旧resource-map-comparison；R3原字节。每项生成前冻结SHA，新的sim/map脚本及工程按设计生成，不修改运行源。47来源由原调用参数实际枚举，表在E。

## B 整体行为与样例

OS01 七类kinds11/12/13/14/15/17/18完整保留，req622/rsp585/ID176/quiet/取消/复位/缓存/首因/数值/每沿事件等同原R3。OS02 每次call_scalar参数A/B和命令头22必须与原406命令全位相同；可见子请求/返回不延迟、不提前、不改变全正文。OS03 typed存储/原资格/全192值维持其v1契约，不依赖typed尚未完成的检查来宣布通过。OS04 真正MAP确认共享收益，与原v1独立top同设置核算，不用语句变短自证面积/Fmax。

正常例：kind12 step41原A为slot10、B为payload[21+:33]有符号扩192，新分支写两码，尾端两个选择器返回同一全值和同22头，PREPARE仍原沿锁命令。边界：kind15的payload11移4先保持原192上下文，无新增窄化；W/H=0的coordinate_last仍完整all-ones，之后原公共资格不改。call_scalar后被reject覆盖时，原plan_class仍拒绝，未发布私有命令；新共享仍按原旧头/两来源保留该组合值，不让选择器热改已经锁住的published_command。

## C/D 模块与组合契约

MOD1仍fit_core，内部两个组合operand_source(selector6)值选择器；MOD2原scalar_bridge/scalar_core不改；MOD3旧R3对照及独立数学。IF1 public原622/585/176不变；IF2来源码只内部always_comb计划使用，不跨域/保持周期；IF3头22+两192恢复原plan_command406，随后PREPARE的原published_command寄存器保持完整406直到真正cmd_fire；原调用时刻/ready/反压/取消和完整目的资格保持。

相容证明：来源表按表达式唯一标识，原call=a,b，新select=表中对应两个常量，函数逐一返回原表达式，同一held_request/旧work_slot下完全同位。task保存原bits9/sb/sa/op3/零4/destination4拼成22头，plan尾端分别放A[22+:192]、B[214+:192]，总406及字段顺序相同。不是由当前全局payload重构已经published命令；共享只参与下一条组合计划。

130个调用点控制/need/reject/next_step/next_phase/local_write及cache分支原样；仅最后两个实参改码。每一种来源必须覆盖至少一个原位置，未知表达式/数量变更在生成前报错。不存在同步ROM延迟或选择器状态反馈。所有局部值仍读取旧完整192 wire，typed提交与主状态相同posedge，不产生新存储旁路。

## E 中文操作及47来源表

E1 来源码固定0=ZERO，1..16=slot0..15；17..46按下面30项顺序分配，不按每次运行随机顺序。每项以职责命名localparam logic[5:0]，不把裸数字塞进130调用点；47..63为未使用编码，函数返回0，本模块不生成这些码。无selector从外部来。

30项非槽（第一项固定65535；其余29含payload/坐标/移位）：

1 CONST65535；2 P21_U43；3 P108_U43；4 P64_S44；5 P263_U16；6 P151_S56；7 P207_S56；8 P0_U21；9 P87_U43；10 P21_S33；11 P130_U43；12 P54_S33；13 P173_S44；14 P217_U16；15 WIDTH_LAST；16 HEIGHT_LAST；17 P0_S32；18 P32_S32；19 P82_S32；20 P114_S32；21 P64_S18；22 P146_S18；23 P82_U11；24 P93_U11；25 P72_U11_SHIFT4；26 P0_S18；27 P83_U11_SHIFT4；28 P18_S18；29 P36_S18；30 P54_S18。

名称P<low>_<S/U><width>明确pf(payload,low,width,signed)。WIDTH/HEIGHT_LAST读取原held W/H11后coordinate_last；两个SHIFT4是原pf(...,11,0)<<4，其结果仍192。slot均原192展开值，不在选择器再canonical或截低部分。

E2 在现有function区定义operand_source(selector)，case每项直接返回原192表达式；default=192'd0。组合函数自动、无历史/副作用/延迟。保留原pf和数值helper，只加两个计划selector变量。

E3 改call_scalar签名最后A/B参数为logic[5:0] a_source,b_source；前六参数/op/返回资格/plan_class与宽度/目的原样。task不再写两份192值，而保存两selector，并给plan_command低22写{bits[8:0],sb,sa,op,4'd0,destination[3:0]}。

E4 在原计划always_comb起始保留plan_command=0，增加两个selector=ZERO；全部case分支按原顺序执行；最后在required_slots及局部资格检查之前/之后（都不改变selector或头）统一赋plan_command[22+:192]=operand_source(a_source)、[214+:192]=operand_source(b_source)。不对整个plan_command自反馈，不建立组合环。没有call_scalar时原零头+两个ZERO与原全0相同；call后reject/local覆盖也保留原此前命令内容。

E5 只把130处call_scalar的最后2参数按47表替换；采用成对括号读取参数的准备操作，遇不属于表/不是8参数或130数量不同立即停止，不猜表达式。其它源码包括typed存储、资格链、顺序逻辑所有文本保持（记录LF/CRLF，不能不经核对称字节相同）。新代码是明确常量和case，交付不要求用户依赖准备程序读懂逻辑。

E6 TB继承typed完整旧R3比较；额外在state PREPARE且非取消、plan_class0时比旧/新完整plan_command406和必要控制字段，覆盖真正计划形成沿，在真实子交接处仍原622全值对照；原有效槽/局部全192比较和独立数学不改。未valid值不当零，reset作废照原账。

## F 语言与时间契约

sv_09，constant选择码6位、完整192无signed隐式重解释，bits9/目的4等原头明示。组合blocking完整默认+part-select覆盖，寄存器nonblocking原样；IF2纯同域组合无ready/持有意义，IF1/3依原完整valid/ready。正常/气泡/反压、输入锁存、取消/复位/cache、ID同，未产生RAM/CDC/额外流水。typed物理状态按其设计，模拟与真实资源待新运行。仿真25MHz、MAP100MHz目标约束、Ti60F225/I3/speed/retiming0/seq_opt0；无PNR/STA/bit/硬件。C++无生产新增，Python仍原大整数数学。

共同数值与事件映射按旧实际接受事务；完整622/585及406/192对比0容差。数学终态和每沿计划/保持分别检查，不把最终数值一致替代时间。源未知值不因内部selector默认0当已验证输出；有效/合法场景由原资格控制。

## G/H 验证、实施与双向追踪

先冻结→生成6文件→真实compile/elab/fatal→全原14517、取消/复位/cache/全状态/4486helper角点、有效槽与所有公共/私有/局部交接→原独立audit→当前MAP→预算对比。源码13/SIM10/MAP13结构同typed，runner固定新根/new top，不改当前运行。

T1 原全向量/独立数学及协议账；T2 每沿public/子full622/585/真实桥403/合法local192相同；T3 PREPARE真正计划完整406和class/destination/width/signed/return_signed/required_slots/next_step/next_phase同，未形成计划不硬比X；T4 全valid槽/取消/reset/cache/所有状态/helper原覆盖；T5 实际同设置MAP原语和所有日志，比较局部v1与typed/共享组合，来源上下文注明。

OS01/03→原state/typed/IF1→T1/2/4；OS02→来源表/E2–5/IF2–3/plan→T2/3；OS04→运行器/工程→T5。新selector定义、函数、130调用、partselect和TB计划监视逐一返回OS02；其余不夹带新识别行为。

## I/J/K/L 十项门槛与恢复

B整体/普通边界；C职责和真实47来源；D完整参数、字段和时序相容；E状态/语句/来源码；F RTL A–L及软件数学分层；D/E一条计划→锁存→真实桥→返回→槽走查；G/H实施测试追踪；当前实验无正确性未知，typed待测为显式待测输入；本文件保存读回呈现；A版本/15输入/6输出明确。READY v1后按持续自主软件/local audit实施，不逐项问批准、不修改正式状态。

变更先短卡，失败run保存；若来源码分配或组合形成不符草图不能静默补数。交付README填写真实结果、未测PNR/网表动态/速度与完整生产缺口，理解验收待用户实际作答。选择器减少并非整机完成；生产识别/DDR/CSI/root资源及最终bit继续全目标。
