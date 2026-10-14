# 显示组合综合策略资源实验 v1

- Goal：继续完整五基础/六高阶/1080p目标，实测显示组合的大型选择网络能否通过综合策略减少资源；不降低图像或接口要求。
- Current state：真实1080p联合仿真、独立参考均PASS；同一显示组合speed MAP为19 RAM10、23324 FF、35502 LUT4、835 ADD、1 DSP。
- Target state：相同源码、Ti60F225/I3、时钟、retiming=0/seq_opt=0，单独比较area和area2两种MAP策略；输出真实差值和副作用，性能留待真实PNR/STA。
- Gap：尚未测这两种策略。本实验不能证明所有模块已经共存或整机达到目标速度。
- Assumptions：模式只改变映射策略；不修改接口、时序RTL、存储行为、有效性或身份。若工具移除RAM/产生黑盒/不支持模式，原样记录失败。
- Open questions：当前配置实验无正确性未知；综合后动态、物理时序、全工程资源另行闭合，不能把软件源仿真扩写为新网表仿真。
- Dependencies：scan_map_001的31份实际源/工程快照及清单、scan_hd_001的PASS终态、当前规范、官方本地syn-options.html。
- Milestones：整体/局部配置草图→读回呈现→独立work/scan_area_experiment运行器→area2、area实际MAP→比较原报告/网表→登记。
- Detailed steps：见B–G。仅一个新功能运行脚本；31份原样依赖不冒称新模块。
- State transitions：READY_FOR_REVIEW v1；用户“当你统计完后自行进行，无需我的批准”覆盖软件自主，已有本地审计例外继续；未伪改正式数据库/状态/Manifest。
- Artifacts and hashes：输入清单冻结37份：31个原快照、原快照清单、HD suite-result、HD source-manifest、规范、官方模式说明、本设计。脚本每次运行源快照及真正PID/argv/退出/超时/报告原样保留。
- Validation：源和原快照全SHA相符；相同工程只改synthesis/mode；实际MAP退出0、当前资源报告/原语和警告核对；未运行PNR/STA/bit或综合网表动态。
- Failure handling：新RunId拒绝覆盖；失败/没有节省都保留，不能改源码/参数/屏蔽警告让数字变小。
- Human approval gates：本软件配置实验自行执行，不执行硬件步骤。
- Rollback：全新work单元，原HDK、display_scan源、原MAP和已登记产物只读。
- Completion criteria：真实两个策略与speed可比数字；完整FPGA目标仍ACTIVE。

## A 版本、基线与阅读

2026-10-10 v1，关联H1/A3/A5/R0。先B整体与C交接，再D中文操作、E契约和F/G追踪；只有设计保存读回呈现后生成脚本。

实际事实：scan_hd_001已完成17个完整生产1920×1080扫描及第18个前缀，六模式、帧切换、冻结/取消/旧帧关闭与真实owner联合参考PASS。scan_map_001原组件综合PASS，原业务源未改变。它不包含生产root、实际DDR或摄像头。

原snapshot-manifest.json SHA `4D079BA96E4B513A114501D63E3CA889A932CFCD9A022C07D4E3CD3694A4A40F`；HD suite-result SHA `D448131DA0BF996D0D3BE0D917F2B83836473FAA8B57916FA000C699EEBC479B`。官方本地 `C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/doc/topics/syn-options.html` SHA `BA1686F3D04278722211973A62E9545C385C6D4DEEECD3F1DE585BB712265F99`：area优化最小面积，area2优化大型选择树，均不是已执行结果。原源码31项SHA由原MAP清单引用并在本实验复制前逐项重核。无Git不伪造commit。

## B 整体行为及样例

SA01：每次先验证原终态PASS、31份原源/原快照和本实验输入SHA，然后创建独立RunId。
SA02：完整原工程复制到本次flow，只把mode从speed改为指定area/area2；全部设计文件、top、器件、时钟/约束/其他综合参数保持原值。
SA03：用当前已安装Efinity真正执行MAP，保存进程、参数、timeout、stderr/stdout及报告；源漂移/非零/超时明确FAIL。
SA04：以实际网表EFX原语及报告比较旧speed/new，不混用LUT/FF/XLR单位，不预先承诺节省。不能以area较小但速度未知宣称完整FPGA完成。

普通例：area2退出0且LUT减少，记录减少量，但时序标NOT_RUN。反例：area退出0但增加资源，记录负收益，不能删掉这个尝试。边界：输入一个不存在/重复RunId、源SHA不符或不支持模式，启动MAP前拒绝并保留可审查记录。

## C 职责、接口与组合

唯一新增MOD1 `scripts/run_scan_area.ps1`管理配置实验，不新增任何生产RTL。输入IF1为RunId安全字符串、Mode枚举area/area2；固定只使用本scope的display_scan原MAP及已完成HD来源，不接受任意目录/命令。输出IF2为本work/runs/RunId的source-snapshot、flow和结果。MOD2原Efinity映射，输入相同XML/RTL/SDC，输出实际报告/网表，不把脚本写的PASS当工具结果。

源身份关系：原MAP的31源→SHA核验→新快照→原flow XML复制→单参数更改→实际Efinity MAP→实际原语比较。HD28源清单与当前输入全核验；它与原MAP共源，XML/SDC/MAP脚本另外核验。源正文仍由原设计的valid/ready、ROW/full FrameRef、GEN/关闭规则负责；没有新的数据/控制连接或CDC。

## D 中文局部草图与语句组织

1. 用PowerShell参数声明约束RunId和Mode；固定taskRoot/originalRoot/toolRoot，不能把用户文字当命令运行。
2. 读baseline及原MAP/HD JSON；原PASS/finished及31/28数量确认，foreach对当前源和冻结副本逐SHA比较，文件失败直接抛错，绝不修改原文件。
3. 拒绝已存在RunId；创建本work目录。原31份按relative复制到source-snapshot；源码/工程/deps再复制到flow保持相对布局，不复制编译库或运行中的目录。
4. 解析独立flow XML，定位唯一synthesis param mode，要求原值speed，然后仅SetAttribute(value,Mode)。保留源XML及变更后flow XML各自SHA；比较移除mode值后两棵XML语义相同，不能追加或删除别的配置。
5. 创建ProcessStartInfo启动原Efinity python/efx_run.py，仅flow map；固定user ini和已用环境，不安装/联网。CreateNoWindow，stdout/stderr异步接收，实际PID/argv/工作目录/开始时间先保存；有界3600秒、30秒进度。超时终止本次进程树并保存结果。
6. 实际结束后保存真实退出/哈希；非零/超时抛错；当前源/快照再次核SHA，外部进程结束并不自动宣称资源和行为正确。由实际rpt和综合网表读取资源后更新报告。

## E 语言与验证契约

PowerShell7既有环境；结构化ArgumentList，不拼接shell命令，UTF8文本，文件路径固定工作副本。原SystemVerilog/双域74.25及100MHz不变；没有新数值/采样/握手/valid/停顿/延迟/复位/配置行为/存储/身份/CDC。唯一变化是实现策略，完整源仿真证据仅沿原源，当前新网表动态与物理CDC仍NOT_RUN。C++/新数学参考不适用，因为没有业务行为变更。

FT01 SHA/实际PASS输入与单项XML差异→SA01/02。FT02 两实际MAP退出和完整报告警告→SA03。FT03 同单位原语差值，包括RAM/FF/LUT/ADD/DSP/SRL，不把零缺行未经网表核对解释为零→SA04。停止条件是实验结果可查，不是整机完成。

## F/G 双向追踪、自检和交付

SA01/02→MOD1 IF1/D1–4→baseline/脚本→FT01；SA03→MOD1 IF2/D5–6→真实工具→FT02；SA04→实际资源报告→FT03。新增脚本每处只负责上述派生工程要求，无隐藏业务算法。

十项：B整体/例；C职责/真实复用；C明确参数/输入前提；D中文语句和文件生命周期；E语言/边界；B/C端到端走查；E/F验证/追踪；当前实验无阻塞；本文件保存读回呈现；A版本/一个脚本/37输入范围明确。READY后依持续自主软件授权执行，不要求新批准。正式PG/H0/硬件状态不变。最终README按真实两份资源数字填写，收益为零或负也如实交付，理解验收待用户实际作答。
