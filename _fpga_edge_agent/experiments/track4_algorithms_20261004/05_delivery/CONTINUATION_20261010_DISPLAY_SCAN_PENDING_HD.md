# 完整显示扫描整合进展（2026-10-10）

本轮新增3个实际RTL：三银行scan调度、跨时钟scope fence、组合顶层；配套2 TB/独立参考/脚本/工程共10份自写业务与验证文件。用户持续“统计后自行进行，无需批准”及本地审计例外继续；先中文整体→接口→逐沿内部草图，再代码/真实动态验证。正式PG/H0状态和硬件未修改。

[从草图到代码的阅读与操作入口](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_scan\README.md>)；[完整设计及逐沿草图](<D:\大三\FPGA_verilog\_fpga_edge_agent\planning\design-TRACK4-DISPLAY-SCAN-002.md>)；J1/J2/Q1/Q2在设计目录与包内保留，所有重要变化先保存读回。

组合已经连接实际owner/handoff、AXI取数核心、native三行RAM、三个真实消费者与六mode renderer。四套20×8/4×2/6×8/10×8联合仿真与独立参考PASS：共68个完整扫描（含每套启动黑屏及重复扫描）和4个末扫描前缀、32次真实切帧、280 owner事务、28次actual oldClosed/RETIRE、4次候选错过VS、8次取消、80周期通知背压。冻结在实际视频已B、核心账本仍A时正确pin B；所有像素、同步/坐标/错误、54bit原始行、完整身份与GEN、实际首行头/两credit、真实核心归还及关闭分别比较。

[实际错误RID检查](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_scan\runs\scan_fault_001\reference-result.json>)收到RID3而期望2，组合/取数Q、源/结果/运输引用保持，没有closed或取消完成；原owner独立参考另核6真实事务。未知IO未关闭是预期事实，不冒充排空。

Ti60F225/I3实际[组合综合报告](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_scan\runs\scan_map_001\flow\outflow\display_scan_component.map.rpt>)：19 RAM、23,324 FF、35,502 LUT、835 ADD、1 DSP。26 warn细分及132 post-synthesis未用端口警告完整保留，err没有实际错误。32份当前源/工程，其中22复制依赖；baseline v1.4共29输入。MAP31快照、四套112仿真快照及故障26快照均与当前源一致。没有PNR/STA/bit/板级pin/物理CDC检查；owner在TB真实实例，生产父业务控制器另接。该显示资源不能用来宣称加上Canny/复杂识别仍装得下。

1080p统一联合运行scan_hd_001已编译/展开，实际Questa PID20748在2026-10-09T19:54:43.839107+00:00核查仍live；工具会继续实际仿真及独立参考，未标HD PASS。handle=68945，保已有运行，禁止因观察超时重启。[待HD完成的不可变登记包](<D:\大三\FPGA_verilog\_fpga_edge_agent\artifacts\staging\DISPLAY-SCAN-COMPONENT-20261010-v1.4-PENDING-HD\artifact-manifest.json>)仅保存已终止的四套/故障/失败/语法/MAP证据，518项，不复制仍增长的HD日志。manifest `C126C10D38822D9CA7D90826DCEC46A148D2EAE05AFD745110A96339521A3E13`；HD完成后另登记包含全原始证据的新包，不覆盖本包。

本轮先前21包manifest摘要和182份当前增量源已核查；前次8941项artifact内容检查沿v15保留，本轮不重复全量读取，新增登记内容逐项新核。累计自写业务/验证文件252→262、当前增量源182→192；原70基础文件未本轮整体重跑，文件数量不是模块完成率。

整体仍ACTIVE：先完成HD联合及未覆盖的组合时钟停止后恢复/边界动态，再接生产Source/result/RO业务控制、DDR实际参数/服务/QoS和CSI CRC/晚错，完成原完整复杂识别及共享资源，最后统一Ti60F225生产top、总资源/FPS、真实引脚/时钟/CDC、布局布线/时序/最终bit。bit之后停止硬件动作；数学byte-slave/ANN码型不代表实际摄像头或识别产物。
