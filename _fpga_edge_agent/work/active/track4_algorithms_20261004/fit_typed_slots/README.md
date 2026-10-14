# FIT定宽物理槽：阅读与运行

完整七类FIT及原622位请求/585位回复、176位取消身份不变。本单元依次阅读：整体中文设计→公开接口→槽写资格及存储→计划/顺序交接→对照TB和独立数学→真实工具报告。

1. `inputs/design-TRACK4-FIT-TYPED-SLOTS-001.md`：整体、接口和每条语句的中文草图；该输入已冻结，原始HDK及正式状态没有修改。
2. `rtl/fit_core.sv`：TS02逻辑192位只读槽；TS03完整385/192位返回资格；TS04每槽分别保存N低位及独立原bit191。16槽合计1791个声明存储bit，实际FF/LUT由下面MAP测量，不能以声明代替实测。
3. `deps/fit_core_original.sv`：原R3旧参考，改过module名及LF/CRLF换行；`inputs/source-binding-note.md`说明原字节来源。其余底层和两个数学模型原样复制。
4. `tb/tb_fit_slot_resource.sv`：每沿公共及真实子接口、局部完整192提交、每次提交后全部有效槽，以及原取消/reset/cache/状态/helper检查。
5. `scripts/run_slot_sim.ps1`：独立新RunId，冻结14输入，快照10个运行源，真实compile/elab/非零fatal探针/完整仿真/独立audit，源漂移或非零退出即失败。
6. `scripts/run_slot_map.ps1`：必须当前完整sim PASS；快照13输入，同一Ti60F225/I3、speed、retiming0、seq_opt0、100MHz约束。组件综合没有板级IO/布局布线/时序达标/比特流证明。

## 当前已完成

`runs/fit_typed_001`正常结束，vsim及audit退出0、无超时。14517个原独立数学向量、14594接受/14559消费/35复位中断守恒，37取消/35复位/5缓存及父11/桥6/子19全部状态覆盖。51195951个沿与原R3公共/私有全值和时序相同；122639次局部提交、4486个helper角点、4014455次有效槽完整192比较通过。10个当前源及快照SHA重新核对，不是仅比较两个新实现。

`runs/fit_typed_map_001`真实退出0、无超时，资源报告和网表逐原语计数相符：37020 LUT/2696 ADD/7076 FF/2 DSP/0 RAM/0 SRL；1791槽FF来自锚定原语实例名计数（不能把cell属性行重复计为实例）。相比局部v1减少6481 LUT、1281 FF，ADD/DSP不变；相比原R3减少7385 LUT、961 ADD、1281 FF。13当前源/快照及两份原比较MAP字节SHA重新核对；6项warning为3冗余信号和3异步小缓存映射到逻辑，原始日志保留。组件PNR/STA/网表动态未运行。原独立FIT局部v1实测43501 LUT/2696 ADD/8357 FF/2 DSP/0 RAM；其中3072槽FF是该独立top上下文，不能与旧STATS上下文的1791槽FF混写。详见`resource-map-comparison.json`和实际run；原旧参考两次MAP的上下文作为已测基准，不虚构本轮重跑。

## 操作

在现有PowerShell中运行`run_slot_sim.ps1 -RunId <新的名字>`，通过后运行`run_slot_map.ps1 -RunId <另一新名字> -SimulationRun <仿真名字> -Variant New`。工具路径是已安装的Questa2024.1和Efinity2026.1 ASCII链接，没有新下载或安装。保留旧run，仿真和MAP运行期间不编辑被快照的源。

接口、数值、取消、复位、缓存、提交时刻、有效资格和原数据范围均没有降低。完整十一项/生产camera-DDR-display/识别/全芯片资源和时序/最终bit仍继续；这里的数学向量不等于真实视频复杂识别质量通过。生成bit后的硬件操作不在范围内。
