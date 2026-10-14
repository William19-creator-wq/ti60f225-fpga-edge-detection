# TRACK4-LIVE-THRESHOLD-UNIT-001 v1：按键消抖和帧级 Sobel 阈值

## 通用计划字段与授权

Goal：快速完成 T4-A2 的独立可复用单元；不等待 DDR、CSI 或完整生命周期控制器。
Current state：R1 前端已经在 job_fire 锁定阈值；原 CONTROL v0.1 包含尚未闭合的整机冻结/配置/复位合同，不能声称本单元实现全部控制器。
Target state：两个低有效 GPIO → 同步/消抖/一次按下事件 → pending_threshold → job_fire 时锁定的活动阈值。
Gap：本单元生成 RTL、独立逐拍参考和 TB；生产 CDC、四键手势、Canny 阈值及帧管理随后整合。
Assumptions：默认 25MHz、20ms、阈值256、步长16、域0…2047；生产按键候选 KEY0=C4/KEY2=N13，独立验证先不增加引脚工程。
Open questions：本单元无影响正确性的未知；整机接口不由它改写。
Dependencies：现行代码规范v0.2、CONTROL v0.1 的低有效/无自动重复政策、R1 frontend_frame_pair 的 job_fire 快照合同。
Milestones/Detailed steps：整体行为→交接→旧状态草图→参考/TB→编译仿真→生产 join。
State transitions：设计自检/读回后 READY_FOR_REVIEW；按用户2026-10-08“当你统計完后自行进行, 无需我的批准”直接 IMPLEMENTING，保留原规范，不新设逐项批准。
Artifacts and hashes：本稿和 work/active/track4_algorithms_20261004/live_threshold 的源码/实际 run；输入 SHA 另记 baseline.json。无 Git commit。
Validation：LT-T01…05；实际未运行时不写 PASS；软件复位测试不替代真实亚稳态证明。
Failure handling：复位清计数并等待合格释放；上下边界饱和；双键同沿事件抵消。
Human approval gates：沿用连续软件实现及本批本地审计例外；不操作硬件、不改正式数据库/状态/Manifest、不网络下载。
Rollback：保留历史稿/运行；只修改 work 中独立新增单元，不触碰 HDK 和已登记包。
Completion criteria：单元逐拍及阈值/Sobel比较组合通过；完整高阶项仍需整机/生产时序验证。

## A—C 整体与职责

LT01：异步 GPIO 经两个 FF，逻辑只读旧第二级；稳定高/低连续达到 DEBOUNCE_CYCLES 才承认状态。低于门槛的抖动不计一次按下。
LT02：上电/同步 rst 后必须先连续合格高电平释放；启动按住不触发。稳定低首次产生单拍 press，再次触发必须先合格释放。没有长按自动重复。
LT03：INC +16、DEC −16，0/2047 饱和；同沿两事件抵消；pending 可在活动任务期间改变，活动任务阈值保持。
LT04：job_fire 沿锁定旧 pending_threshold。与按键事件同沿时当前 job 用旧值，更新只供以后 job；与 R1 前端同沿快照一致。
LT05：仿真观测完整同步/消抖/事件/pending/active，不以 LED 代替数值结果。

模块：key_press_debouncer 保存两个同步位、stable_level、armed 和一个计数；live_threshold_control 复用两个按键实例并唯一拥有 pending/active；TB 对照与 RTL不同组织的 Python 逐拍参考。
连接：raw_inc_n/raw_dec_n → IF-LT01 → 两个 debouncer → IF-LT02 单拍事件 → threshold_control → IF-LT03 阈值快照/前端配置；本单元没有 RAM、除法、DSP 或新时钟。

## D 接口与组合检查

所有逻辑同一 clk 上升沿，rst 高有效同步、禁止触发；异步引脚只允许进入两个同步 FF。
IF-LT01：input raw_key_n 1bit；参数 DEBOUNCE_CYCLES unsigned integer≥2，默认500000。output press 1bit、stable_pressed 1bit（仅armed后），无 ready，因为每合格按下只一个事件，控制器每拍可接收。
IF-LT02：两个已寄存 press，控制器读旧 press；脉冲出现后的下一个上升沿更新 pending；无任何反馈阻塞消抖。
IF-LT03：input job_fire 1bit、output pending_threshold/active_threshold unsigned11。参数 INITIAL_THRESHOLD 0…2047、STEP 1…2047。job_fire 可以连续，但调用方须实际代表接受边界；活动阈值只有 job_fire 或 rst 能改变。
生产 join 必须把 pending_threshold 交给 R1 的 job_threshold，R1在实际 job_fire 同沿自行锁定；不能用本单元同沿刚更新的 active_threshold供 R1（会迟一任务）。active_threshold 是独立观察/后续算法锁定接口，并非强制改 R1 端口。
同一时钟数据直连无丢失；未来跨域必须用完整配置握手，不逐位同步11bit。本稿不自动接入多时钟生产系统。
样例：初始256，合格INC→pending272，旧job仍256；新job接受272。INC和job同沿→job旧pending，下一job新pending。启动按住→保持256，释放合格再按→一次272。

## E 局部中文语句草图

消抖先声明同步器、稳定电平、资格和 count，COUNTER_WIDTH=ceil(log2(DEBOUNCE_CYCLES))，至少1。复位同步级/稳定电平设高，armed=0、count=0、press=0。
每非复位沿：同步第一/第二级非阻塞赋值；press默认清0。未armed时，只计旧第二级连续高，低清count；第N个高使armed=1、stable高、count清0，不发press。
已armed且旧第二级等于stable时清count；不同则计连续样本，第N个提交stable，若提交低则press=1；否则release只恢复资格，不发事件。一个count表示当前连续差异长度，没有独立候选值（输入是二值）。COUNTER最大N−1，提交后归0，不回绕。
阈值模块先实例化两个同步/消抖单元，再用12bit expanded_sum 判饱和。时序块复位两个阈值；非复位沿根据旧两个press，INC独有加/DEC独有减，否则保持pending；独立 job_fire 用旧pending写active。非阻塞赋值明确定义同沿规则。

## F 语言/时间/存储契约

SystemVerilog always_ff，所有状态一个时钟；两个同步器用 ASYNC_REG 属性作工具提示，实际物理 CDC/约束另验证。无仿真 delay 的功能源，无生成门控时钟。
样本在沿前稳定；输出在沿后改变，TB在#1观察。GPIO→第二级两沿，再连续N个样本认定，控制器再读注册press；参考逐拍包括这些旧状态延迟。
12bit 加法先扩展，减法先比较，禁止11bit回绕。同步复位使活动/pending恢复 INITIAL，press清0。参数非法静态fatal；合法编译路径可综合。
无 ready、缓存或在途帧；只保持2×计数和少量 FF，不处理图像数量/身份。job身份由父端拥有；本单元只提供确定快照数值。
Python参考为无限精度逐拍模型，重构为独立历史长度/输入流水列表；输出按实际 GPIO/边沿编号逐项比较 press、stable、pending、active。不是复制 RTL 语句测试。

## G—H 验证及双向追踪

LT-T01/LT01/02：启动按住、门槛N−1/N、交替抖动、合格释放、长按一次；Python和实际沿后press/状态相等。
LT-T02/LT03：默认值、所有饱和上/下边界、双键同时、交错按键；pending完全相等。
LT-T03/LT04：事件与job同沿、连续job、任务中按键和保持；active相等且job用旧pending。
LT-T04/LT01…04：同步复位在按住/部分计数/press/活动job期间，随后释放重按；固定种子长随机场景逐拍比较，两个N配置（2与7），参数初值/步长边界（2047/2047与0/1）。
LT-T05/LT04/05：阈值送严格 Sobel M>T比较的组合样例，增加后边缘数不增、降低后不减、门槛等号无边缘；后续实际 R1 join 另跑，不在单元TB冒称整机。
代码计划：rtl/key_press_debouncer.sv→LT01/02；rtl/live_threshold_control.sv→LT03/04；model/live_threshold_reference.py→T01…04；tb/tb_live_threshold.sv→实际逐拍输出；scripts/run_live_threshold_sim.ps1→编译/运行/审计/哈希、fatal退出检查；docs/README.md→操作/trace/真实限制。反向每项代码只承担表中要求。

## I—L 自检、恢复和交付

自检：整体/例子、职责、接口、局部中文草图、语言、组合、验证追踪、范围隔离、保存读回、授权基线十项已具实际内容；不存在单元当前阻塞。整机冻结/CDC/生产引脚不借本单元声称完成。理解验收待用户实际阅读/反馈，不阻止软件实现。
后续修改语义先更新草图，按持续授权自行推进；最终交付更新实际代码位置/输入SHA/run结果。原 CONTROL 大稿保持历史状态，本单元按独立范围实现，整机配置由 FM 唯一owner继续闭合。
实现前补充启动交接：复位把同步器置高会产生两拍占位样本，N=2 时不能用它们误认“已释放”。同步器另带两级 sample_valid，只有第二级来自真实非复位采样时才允许计数。复位清资格，未满两级时清计数；资格只作本地同步流水标记，不把它作为外部 GPIO 可靠性证明。Python参考用初始空的两样本队列描述相同合同。