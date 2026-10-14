# FIT共享版原生MAP网表等价检查 v1

- Goal：确认自动推断的RAM/DSP/FF/LUT实际功能节拍，推进同Ti60F225完整项目，不把RTL完整通过替代真实网表证据。
- Current state：共享FIT完整14517数学向量/51195951沿旧核对照PASS，实际MAP32794 LUT/7076 FF/2696 ADD/2 DSP/1 RAM。新增常量MUX RAM还未动态验证。
- Target state：已测完整网表加原生Efinity模型与当前RTL共刺激，每core沿公开valid/ready/quiet/full585一致，独立数学/协议账通过。
- Gap：这是附加网表功能检查，原完整RTL测试不变；无SDF/PNR/STA或整机生产证明。
- Assumptions：MAP网表和17源/模型按真实SHA冻结，原生仿真模型支持本实际所有原语，若不支持则保留真实失败而不替换为理想模型。
- Open questions：本原生检查的实际正确性/运行时间待测试，协议和数值前提已明确；生产top/DDR/CSI/识别另外继续。
- Dependencies：当前共享RTL、原R3/底层、完整独立数学及原全部输入、MAP netlist/report/source snapshot、原生FF/LUT4/ADD/DSP48/RAM10及v0.2。
- Milestones：保存读回呈现→冻结23输入→新fit_native_mapped副本→225数字用例及原全协议→原生compile/elab/fatal/full公开检查→独立数学audit→登记。
- Detailed steps：B整体→C/D绑定→E中文语句→F语言/时间→G/H验证追踪。
- State transitions：READY_FOR_REVIEW v1，用户持续自主软件/本地审计授权，不再逐版请求批准，不修改正式状态。
- Artifacts and hashes：三新增/适配文件：TB、prepare_gate_vectors.py、run_fit_native.ps1；原RTL/数学/模型/网表为原样或明确文本适配依赖，不重复计自写模块。
- Validation：原225选法固定、全定向181+11大(kind,label)各4=225、kinds11/12/13/14/15/17/18为48/44/20/37/30/23/23；完整37取消、35reset、5cache、所有状态/4486helper和真正公开全值/时间。
- Failure handling：原生不等价/模型编译失败/超时即FAIL，保存不降精度、不换原生模型、不丢失败例、不改既有14517原测试；后续修正先短卡。
- Human approval gates：持续授权的软件实验，无正式DB/H0/硬件操作，无新安装下载。
- Rollback：新work/fit_native_mapped，共享版/已注册包保持只读。
- Completion criteria：附加原生MAP功能真实通过，不声称225=14517全量网表，也不声称PNR/STA通过。

## A 范围、基线和阅读

2026-10-10 v1，A6/R0组件证据。23输入：当前FIT RTL/TB两份；5底层及旧参考；2数学；实际MAP netlist、resource-map-comparison与snapshot-manifest三份；五官方原生模型；规范、共享设计及本设计三份；原full numeric.tsv/cache-directed.tsv/manifest.json三份。总2+5+2+3+5+3+3=23。原网表SHA 1CD3E8D9A207CE9E962BFA099E545E93BF50FD0ACEFC7099C7E8811F7CA354B3，资源/rpt记录对应原run，不能凭历史PASS替代字节核验。

五模型均来自当前Efinity2026.1/sim_models/verilog，不能换新版本或关RAM读未知语义。DSP48文件包含全部float/int/pipe/helper定义，没有外部include；FF/LUT4/ADD/RAM10亦无include。实际只有这五类原语，先核计数后编译。

## B 整体及样例

NM01 原full14517源码/向量/参考完全保留。附加网表取全部group<100的原定向181条；对每个>=100的(kind,label)组选索引first、floor((n-1)/3)、floor(2(n-1)/3)、last四条，11组44条，总225。原顺序排序，保留原622 ID及完整585，不重新编号、缩小几何/精度或改异常条件。源full manifest/hash及225索引必须保存。

NM02 当前RTL dut、独立旧R3 original、原生网表 mapped吃同一622/176/ready/rst/clock。保留旧TB真正接受/数学/取消/reset/cache/全状态/private/interface/helper检查，只加原生公开侧比较：每posedge后1ns（40ns周期且无SDF）比较req_ready/rsp_valid/quiet，rsp_valid时完整585严格相同。不把RTL helper/私有槽检查误报为映射私有网表验证。

NM03 原生EFX_RAM10/DSP48/FF/LUT4/ADD直接执行实际defparam及INIT；不得强制内部完成、删除时钟级、忽略X或更改READ_UNKNOWN。新RAM WCLK等0、RCLK clk、RE/RADDREN1、OUTPUT_REG0是实测连接，节拍由整个网表公开检查验证。

例：普通kind14同时进入两个实现，发出和保持所有公开结果必须同沿、full585相同；任何RAM header错一沿都失败。边界：已经HELD反压时cancel不改结果，reset同旧时刻作废；通过原协议刺激验证真实效果。错误：原生模型产生X不是容差；公开valid为1时任何full585 X不同即失败。

## C/D 实际绑定和适配

MOD1 original/current RTL保持原B–H参考；MOD2整个实际MAP网表；MOD3五官方原生模型；MOD4原数学/协议audit；MOD5选择准备器与派生TB。只有软件测试增量，不新增生产逻辑/CDC/接口。

原MAP网表原字节GB18030/CRCRLF；为避免与fit_core重名，只在新deps副本把唯一module fit_core声明改fit_core_mapped并把文本编码/换行归一UTF8/LF。所有端口、instance、net、defparam、INIT/attribute正文不改；反改声明后与原规范化文本完全相同，rawSHA另记，不能称只改module名的字节副本。正式注册网表原件保持。

原生公开接口clk/rst、req_valid/body622/ready、rsp_valid/body585/ready、cancel_valid/id176、quiet，逐连接全部同源输入。监视器不驱动DUT，不反馈ready；公开侧两实现稳定后比较，所有实际握手仍旧TB preedge账。纳入R3 independent old核，不以两份新RTL互证；数学依原evaluate而非读取映射内部。

共17运行文件：5底层+currentRTL+TB+mapped网表+5 native+2math+prepare脚本+runner。输入原full三份在冻结inputs；运行器准备225vectors/manifest及原cache副本；原audit-core读取225 count且按原evaluate逐req独立重算。原full manifest保留来源字段，不把225结果回写旧14517 manifest。

## E 中文局部草图

E1 准备器读full三份字节，核manifest count14517/numeric SHA/行数及完整索引；按NM01选225、按原序保存numeric.tsv，cache-directed原字节复制。新manifest count225/cases及SHA，另selection记录原count/fullSHA/索引/每kind和scope。

E2 复制原shared TB到新top tb_fit_native_mapped，原dut仍当前RTL、original仍R3；加fit_core_mapped例及独立wire输出，只在posedge后1ns做NM02公开比较并计mapped_public_edges。原时钟25MHz、源negedge驱动/原accept/collect/preedge账完全不改；原225 numeric与全部37/35/5协议流程及helper/private检查继续。

E3 原fwrite resource-compare追加mapped_public_edges和mapped_public_equal字段，final要求该计数>0；原日志/原公平计数不改。finished只有全流程完成才1，fatal退出探针仍必须非零且无成功metrics。独立audit-core原样消费该225manifest，不修改其数学/预算/日志账代码。

E4 runner冻结23、快照17、准备225、原input-probes、vlib/vlog/vopt、fatal、真正原生sim、原audit、源/快照SHA，终态PASS/FAIL分账。vopt+acc为原刺激访问currentRTL私有状态保留，原生公开比较不访问不存在的helper层级。实际vsim timeout7200秒，父进程/真实argv/开始/结束/退出/超时记录；观察工具超时不自动重启。

## F 语言与时间

原生产RTL sv_09，TB SystemVerilog、Python3.14标准库、PowerShell现有版本。新无C++。622/585/176全位比较0容差，软件用原任意整数模型和对应完整req重新算，不把元数据当原生输出。

native零延迟功能网表没有SDF；1ns后观察只避原语/RTLdelta，不修改数据/取消/ready采样时刻或添加生产级。组合/寄存器/RAM/DSP实际模型定义照原；PNR/STA/CDC/100MHz速度另外证明。声称功能同沿不自动证明100MHz或物理引脚。

## G/H 检查与追踪

NMT1 full来源及225选法/各kind/定向完整；NMT2 每公开沿three valid/ready/quiet及全585；NMT3 数学evaluate/真实握手账；NMT4 原37cancel/35reset/5cache/所有状态/helpers（这些私有检查只指RTL sides）；NMT5 native全部实际原语/参数/INIT、rename反向文本及实际tool；NMT6 终态/timeout/source hash，不弱化失败。225样本没有替代旧14517，整机质量/DDR/CSI/总资源另继续。

NM01→E1/selection→T1；NM02→E2/监视器/public IF→T2/3/4；NM03→C/D/原生复制与网表→T5；runner/metric/来源→T6。三个新增文件承担这些要求，所有符号返回相应条目。

## I/J/K/L 门槛与恢复

整体/例、职责及实际来源、接口/组合、语句/时间/语言、端到端public/数学、测试及追踪有内容；原生模型和选法已只读核查无当前接口未知；保存读回呈现，v1/23输入/3新增明确，READY，按持续自主授权继续。理解验收待用户实际作答。

实际不等价先保存证据和短卡，旧网表/版本不改；native不支持不改理想模型自证。登记时明确仅附加225+完整协议原生公开功能，不是全量网表/板级时序。完成后继续真实生产仲裁/控制/相机/识别、最终bit；本检查不生成bit、不操作硬件。
