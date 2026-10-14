# FIT定宽物理槽存储 v1

- Goal：继续完整五基础/六高阶/1080p单Ti60F225目标，针对真实独立FIT3072槽FF采用显式定宽存储，不减少七类运算或数值范围。
- Current state：FIT局部算术优化已通过14517数学及51195951沿旧/新对照；独立MAP43501 LUT/2696 ADD/8357 FF/2 DSP，其中work_slot实际3072 FF。旧STATS父工程1791槽FF只属于其上下文。
- Target state：槽只保存原canonical必须的N低位和1个高符号，逻辑读口仍完整192位；外部622/585、ID176、数值/拒绝/取消/复位/缓存和逐沿时序不变。
- Gap：当前声明192位寄存器让本次独立MAP保留全部高位，需用明确的物理边界表达别名，不以声明或理论节省代替实际MAP。
- Assumptions：不依赖值永不越界来截窄；新展开必须与原canonical_slot对任何192位输入的位模式相同，资格仍先完整检查。
- Open questions：当前存储表示/交接无未知；总FPGA资源/速度、生产DDR/CSI/root/识别和PNR/STA/bit另继续，组件不冒称整机。
- Dependencies：当前FIT v1源/TB、原完整R3参考、scalar/pkg/bridge、独立数学、真实资源对比及源更正说明、规范v0.2、现有Questa/Efinity/Python。
- Milestones：整体/接口/中文草图→读回呈现→独立work/fit_typed_slots→完整旧/新与独立数学→实际MAP→按真实资源登记。
- Detailed steps：E规定唯一写资格及generate定宽状态；原plan/数学/外部状态保持，TB增加有效槽全192对照，不缩短原用例。
- State transitions：READY_FOR_REVIEW v1；用户“当你统计完后自行进行，无需我的批准”及本地审计例外继续覆盖软件实施，不伪造本版新批准或正式PG/状态。
- Artifacts and hashes：6新/适配业务文件（RTL、TB、sim/map运行器、XML/SDC），7复制依赖（4底层RTL、2数学、1既有旧参考声明适配）；13源/工程。14冻结输入（见A，包含本设计），源原始字节SHA绑定。
- Validation：原14517固定全部向量、取消/reset/cache/非法/全状态，旧/新public和真实子交接逐沿全位、完整有效槽对照、真实MAP与v1同设置比较。
- Failure handling：位或沿不等价即FAIL并保留；不修改旧参考/数学/期望/种子/容差。资源无收益也如实记录，变更先写卡。
- Human approval gates：仅自主软件/local audit，不执行硬件，不改正式DB/H0/ledger。
- Rollback：独立work新单元，已注册FIT v1与原HDK/工具只读，不覆盖历史run。
- Completion criteria：本存储表示的真实等价与物理差值；完整目标仍ACTIVE。

## A 版本、基线与阅读

2026-10-10 v1，关联A6/R0。先B整体→C/D交接→E语句/边沿→F映射→G/H验证与双向追踪，再看代码。当前源`fit_local_resource/rtl/fit_core.sv` SHA `1E3FC6397468700279C3A52A24E50E39B43853E31036BC22C62B424064324299`；原R3字节`inputs/original-fit_core.sv` SHA `0072A6B007B93955CFBFE932A55E258935D636C806E54A3572D153EC08034BF7`；既有旧参考SHA `1477661975C6E9AB6D9396BBCE7011477ADE4227ADEB0F11AE1A128D1D1EC10F`，声明改名和LF→CRLF，除此之外语句相同。当前v17是已检查进度，未有运行中的工具。

14输入：①当前FIT v1 RTL；②R3原始FIT字节；③既有旧参考；④当前完整对照TB；⑤–⑧scalar_core、scalar_bridge、scalar/fit protocol包；⑨–⑩原独立fit_reference/fit_vectors；⑪规范；⑫本设计；⑬source-binding-note；⑭resource-map-comparison。保存本设计后逐SHA冻结，原源不改。新SIM编译13源中的7 SV，旧参考不在生产top重复展开；旧/新数值期望与原输入均不改。

## B 整体外部行为与样例

TS01：完整kinds11/12/13/14/15/17/18保留，req622在valid&&ready边沿接纳，rsp585与quiet、176 ID、舍入/首因/退化/overflow/cancel/reset/cache逐沿不变。
TS02：每次槽写入的完整192读值必须等于原canonical_slot(input,slot)。N由原slot_maximum_bits确定，并非signed N取值域：N低位和独立原bit191才是原保存表示。
TS03：rst不清物理数据，沿用slot_valid隔离；每任务/取消/错误/held/子承诺规则不变。只有旧提交事件能更新槽，同沿资格/取消优先级相同。
TS04：实际同设置MAP证明物理变化；结构存储量估计为Σ(N+1)=1791bit，不能先声称实测FF或整机面积/FPS达标。

普通例：slot11 N32，保存输入bit191和低32，再复制高符号到[191:32]，和原mask/高号结果完全相同；v=-2^31或任意原canonical正值都不被再有损截窄。边界：任意非canonical输入的高位（除191）原本就被canonical丢弃，新表示也相同；这不是把公共检查从完整385/192变小。错误返回或同沿匹配取消不写；reset作废任务后旧数据不因新valid误复活。

## C/D 职责、接口及组合检查

MOD1仍一份fit_core；新增内部定宽槽生成块，MOD2复用不变scalar/bridge，MOD3独立TB/原数学。外部IF1 req622/rsp585/cancel176/quiet没有新端口。内部IF2是每槽完整192只读wire，所有plan/helper/命令/缓存仍读它。内部IF3是两个旧写事件：QUALIFY_RETURN真正result_fire且完整资格链通过；LOCAL_COMMIT且原plan_class分支允许；每沿至多一目的，所有更新仍同一posedge。

表示的相容证明：原canonical=(value & ((1<<N)-1)) | (value[191] ? ~mask : 0)。新物理q={value[191],value[N-1:0]}，读口={重复192-N次q[N],q[N-1:0]}，逐位相同，对全192位输入成立。不使用新窄域验证返回或软件请求。

原有资格/错误逻辑及state/cache仍原。新增scalar_slot_qualified由相同有序if/else首因条件计算boolean，只给物理写使能；保留原完整资格链和错误输出，不用只比低部的条件。两条写路径同域，无RAM读延迟、新FIFO或CDC。子返回在e[n]写槽并转ADVANCE，e[n+1]更新step/subphase并转PREPARE，e[n+2]按原事件锁命令；局部在e[n]写槽并转PREPARE，e[n+1]按原事件锁下一命令。所有槽展开在提交沿NBA后更新，不延迟或提前原命令。

## E 中文局部操作与语句安排

E1 保留原slot_maximum_bits、canonical_slot供语义/既有TB；work_slot从可写192bit数组改成192bit只读wire数组，每项唯一来自生成块。

E2 以genvar row=0..15展开g_typed_slot，localparam N=slot_maximum_bits(row)常量；声明unsigned logic[N:0] stored。每行只有一个always_ff驱动stored，assign展开192读口。N分别67/89/88/104/102/133/105/165/132/106/37/32/171/170/170/104，最小32、最大171，无零宽度。不将q本身解释成signed N+1数值，它是保存表示。

E3 scalar_slot_qualified的always_comb先置0，再按旧QUALIFY_RETURN顺序判断：cmd_pending/目的回显→返回outcome/reason→全385 fits_return→unsigned负号→全192 fits_slot→comparison结果≤2；都未拒绝才置1。保持原if/else的四态选择，不用一个可能传播X而改变分支的合取替代。主FSM错误链与相同旧state/flags保留。

E4 每个stored时序块：if(rst)只保持；else if(matching_cancel && state!=IDLE)只保持；else case(state)。QUALIFY_RETURN在result_fire、scalar_slot_qualified和本行目的匹配才写{bridge_result[209],bridge_result[18+:N]}（209=18+191）。LOCAL_COMMIT沿用“if(plan_class!=1)不写，else若目的本行则写{plan_local[191],plan_local[N-1:0]}”。其它状态保持。原主always_ff只移除两处work_slot写循环；slot_valid/cache/state/所有握手账和首因均留原事件。空保持分支明确，没有复位数据/新寄存延迟。

E5 TB仍同时驱动原R3与新DUT，保留所有原完整public/子/局部全值逐沿比较。增加每沿slot_valid全16相同；在一次可能提交后的下一观察沿，逐一比较所有valid槽全192（不是仅本次目的）。检查用上沿旧已稳定值，pending检查旗不是业务反馈；遇reset不读取已作废槽。原helper角点4486、14517用例、全部状态、取消/复位/缓存及数学审计原样。

E6 复用既有进程运行器到新work，替换固定根/文件名/top，fatal探针同时拒绝core-result与resource-compare成功文件（原运行器重复查同一文件的说明修正，仅构建验证守卫，不改原运行/模型）。每次新RunId，源快照编译审计、结束SHA核验。MAP保持Ti60/I3、speed、retiming0/seq_opt0、100MHz，比较此前真实v1报告与当前新MAP，同一外部top端口/数值不变，不把不同父上下文相加成实测。

## F 语言、时间和映射

SystemVerilog sv_09，generate常量边界/宽度，存储非阻塞、组合资格阻塞完整赋值；工作值位模式无signed隐式转换。core单posedge；原req/rsp/fire、valid/气泡、反压稳定、周期延迟、复位/动态配置/cache、ID无变化。数据复位不必要由原valid隔离；新存储不申请RAM/DSP，寄存器实际面积看工具。无新CDC。仿真25MHz，MAP100MHz仅目标约束，不称实际Fmax通过。C++不适用，原Python任意精度参考独立于寄存器结构。

软件结果按原接受事务映射，数值位精确0容差；另有旧核逐沿与全槽对应，不能以同一公式测试独自自证。所有合法槽读值应与原canonical完全同位，失效槽X无需比较，未valid不能当数值0。

## G/H 实施、测试与双向追踪

六文件：rtl/fit_core.sv、tb/tb_fit_slot_resource.sv、scripts/run_slot_sim.ps1、scripts/run_slot_map.ps1、project/fit_slot_component.xml/.sdc。7复制依赖字节原样；当前旧参考已经记录其声明/换行来源，不二次改名。10个SIM源含7SV+2数学+sim运行器；MAP另XML/SDC/map运行器共13快照。14 baseline输入保存设计时原字节。

T1 原14517完整固定数值/非法/首因，全独立数学audit-core，原accepted=consumed+reset_aborted账。T2 旧/新外部/子握手与正文、真实local完整192逐沿同。T3 提交后的全部valid槽全192及每沿slot_valid相同，覆盖取消/复位/错误返回不写、多个不同目的历史保持。T4 原全部parent/bridge/child状态、取消/reset/cache/helper角点，既有种子/期望不变。T5 当前实际MAP原语、FF槽分布、LUT/ADD/RAM/DSP/SRL及全部warning/err核对；未执行PNR/STA/bit。每项当前NOT_RUN，不把设计证明写成实测。

TS01/03→原FSM/IF1/IF3/E3–4→主状态及资格、生成写口→T1/2/4；TS02→IF2/E1–2/4→生成stored/assign→T2/3/4；TS04→工程/运行器→T5。反向新唯一stored/资格/guard都对应明确要求，不添加其它识别功能。

## I/J/K/L 门槛及真实实施记录

十项有据：B整体/普通边界；C职责和真实复用；D明确端口/数学组合；E内部数据、旧状态、语句；F RTL A–L/参考角色；D/E提交/错误/取消端到端；G/H实施/测试/追踪；当前存储优化无阻塞；本文件保存读回呈现；A版本/14输入/6输出清楚。READY v1后依持续自主软件授权实施，仍不伪造正式批准/DB/H0。发现当前存储/资格行为不同先短卡修订，不改旧数学或覆盖失败run。

最终README按当前实现/实际T1–5填写；明确输入14与源码13、字节/换行、FF逻辑估计与实际原语、源码仿真和综合网表/物理证据分别记录。当前理解验收待用户实际作答，不阻塞已授权软件。完整生产识别/DDR/CSI/root以及全芯片综合/布局/时序/最终bit仍继续。
