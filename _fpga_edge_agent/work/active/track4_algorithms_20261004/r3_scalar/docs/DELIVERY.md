# R3整数算术 v1 软件交付

2026-10-06。**本批13份代码/工程文件已生成并验证，bit/hex已登记，硬件步骤停止。** 这份交付是kind0–7整数算术；完整五项基础、六项高阶仍未全部完成。

## 已完成的具体工作

| 项目 | 实际证据 |
|---|---|
| 文件 | 4RTL、2Python参考/向量、2TB、2PowerShell运行器、3Efinity工程/约束，共13份；另有中文草图、操作追踪和交付文档 |
| 算术 | 192位操作数；乘/加减/比较、DIV_RNE/DIV_FLOOR_U、SQRT_RNE/SQRT_FLOOR，完整385位值及目标位宽资格检查；622/585位输入输出合同 |
| 数值测试 | scalar_suite_004：13,287笔逐位响应检查。SC01 48、SC02 152、SC03 720、SC04 88、SC05 76、SC06 102、SC07 53、SC08 2048、SC12 10000 |
| 协议测试 | 24取消场景、22复位场景、1重叠提供请求场景；19个实际状态全部到达；13356接纳=13335交付+21复位作废；形成13336，包含1个形成后被复位作废的响应 |
| 保持/计算 | 请求保持检查228、响应保持检查205969；已测最大形成677沿，设计界4096。外部反压等待不计此私有形成界 |
| 真实顶层 | 默认W1920/H1080上下文，实际源生成1024笔、复位后32笔；1056笔真实响应/串行585位CRC由独立Python复核，源LFSR/完整消息亦独立核对 |
| 退出保护 | 故意fatal探针实际exit1、无成功JSON；正常core/probe及独立audit exit0。旧001/002退出处理失败保留 |
| 物理 | scalar_physical_002：Map/Interface/PNR、同已布线数据库的独立STA、Bit实际exit0 |
| 资源 | 16190 XLR/60800（26.63%），RAM0/256，DSP1/160；map FF3733、LUT4 11554、ADD1913 |
| 时序 | Ti60F225/I3，单25MHz40ns；setup余量22.554ns、hold余量0.090ns；内部未约束/缺钟/多钟均0 |
| 约束/路径 | KEY只到两级异步SR例外，LED仅板外异步观察例外；Q1→D2/Q2→core实际setup/hold检查；源→接收→算术→响应→观察→CRC→LED九组Q到D数据路径检查 |
| 产物 | staging ALGORITHM-R3-SCALAR-20261006-v1；bit 1901502B、hex 1901562B，复制与原输出hash一致；未下载或观察实物 |

实际数据入口：[core独立审计](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/runs/scalar_suite_004/audit-core.json)、[真实顶层审计](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/runs/scalar_suite_004/audit-probe.json)、[最终门禁](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/runs/scalar_physical_002/release-gate.json)、[产物登记](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-SCALAR-20261006-v1/artifact-manifest.json)。

## 先看草图，再看代码和波形

1. [整体连接、局部逐沿草图与修订理由](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/docs/module-code-reading.md)。先理解旧沿输入、状态提交、完成值何时可读，再看语句。
2. [中文操作与代码追踪](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/docs/中文操作与代码追踪.md)。包含模块职责、文件次序、接口手算、软件操作和需求—代码—测试关系。
3. [scalar_core.sv](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/rtl/scalar_core.sv)。先端口/pkg，随后CHECK/SETUP，各算术状态，最后QUALIFY/PACK/HELD与reset/cancel优先。
4. [scalar_probe_top.sv](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/rtl/scalar_probe_top.sv)。源与core同域，真实握手决定LFSR/序号推进，响应槽先预留，CRC完成才下一请求。
5. 软件波形是 `runs/scalar_suite_004/probe.wlf`；关注KEY、core_rst、source_state、request_slot、req/rsp握手、arithmetic/state、response_shift、bit_index、rolling_crc和LED。没有代签用户阅读理解或实机现象。

Efinity直接打开[scalar_probe.xml](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_scalar/project/scalar_probe.xml)。预设Titanium/Ti60F225/I3、SV2009、scalar_probe_top。四pin：J2 clk_25m（pinout工具显示clk_25m.P）/1A1.8V GCLK；P13 KEY、N14/P14 LED/BR3.3V drive4。板外LED异步观察，不要求输出延迟；KEY异步仅到两个实际唯一SR，核心同步路径仍受约束。

现有运行器绑定本机既有ASCII junction、Questa2024.1、Efinity2026.1.132和Python。复现时RunId必须全新，Suite=All；build默认绑定scalar_suite_004，改SimulationRun时仍检查其完整PASS与当前源码SHA。源码快照与staging/source13份逐字节一致，跨机器便携适配尚未做。

## 保留的失败与边界

仿真001/002故意fatal被inline工具命令错误地返回0，运行器拒绝通过；改为真实.do宏和TB finished资格后，003/004实际fatal退出1。物理001的独立查询前三次缺primplace/netlist/routingtrace数据库，日志保留；补全同一已布线输入后成功。物理001还报告合法5→4位隐式缩窄，按规范改为5位计算/范围检查/显式取位，完整004仿真与物理002重新验证。最终map只剩工具去除冗余循环变量提示，wrapper仍提示底层中文路径；既有ASCII入口实际完成所有阶段。

独立观察顶层固定上下文、padding和cancel0，工具有合法常量优化：原response_value寄存器映射为rsp_body寄存器名字；部分身份/配置源不是动态位。最终时序查询采用实际map名字和D端点，不以clock/CE/SR路径代替数据通路。整机接入后仍需重新检查通用调用输入、共享调度、资源共存与时序。

677沿是本次有限测试集的最大私有形成时间；1056笔顶层串行CRC观察也有额外周期，不能换算为图像处理fps。分析器的57.320MHz数值只描述该已布线路径估计；本工程验证/产物使用25MHz，未据此宣称其他频率或整板性能。

bit SHA256 `81E0543007BE142295ED26A9072E9745210566A53F416E65FD779AC42DB3D95A`；hex SHA256 `81BDF68B417820A816C9D1EA3FA5204A96BB358E9503E1B00ADC04FB2C4F4627`。本批用户批准及本地审计例外只覆盖指定算术范围；正式数据库、PROJECT_STATE、TASK_LEDGER、hardware_nodes及原HDK均不改。

## 与DDR Q0及完整目标的关系

本次另一已批准范围[DDR Q0实录](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/04_validation/ddr_q0_v1/RUN_REPORT.md)也已完成有限编译/展开，真实优化单元存在。它保留43条警告：42条FIFO端口数量/连接、1条+acc观察优化提示；未进行动态校准/读写，因此没有帧缓存或DDR性能通过结论。

完整八邻域Canny滞后连接、角/投影/LS-TLS/距离和圆/任意旋转矩形识别、SC431HAI生产输入、DDR动态读写/存储通信、HDMI/CDC、阈值/冻结/彩色叠加及整包资源/引脚/时序仍需后续实现与验证。五项基础、六项高阶及原1080p/识别目标保留；当前软件批次交付不将完整目标判定完成。
