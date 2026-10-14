# Ti60F225 V4 首轮实物调试工程

在 Efinity 中用 Open Project 打开本目录 track4_board.xml，顶层 track4_board_top，124 个源码入口。代码在 rtl、algorithm、board、ip；外围与引脚在 track4_board.peri.xml，时序约束在 track4_board.sdc。本可编辑副本来自已通过的 board_compile_031：源码和约束与该次输入清单一致，工程 XML 采用已登记的编译后文件。原始 HDK 和历史运行未改。

已整合 SC431HAI 初始化/CSI 采集、板载 DDR3 和双槽帧管理、灰度/中值/Sobel、完整 Canny、阈值按键、冻结、彩色边缘叠加和初版 C/R 候选标注；完整点方向、LS/TLS/FIT 和 anchor 数值链路也已连接。当前识别显示为四组可见强轮廓包围盒及方向分布候选。原完整复杂圆、任意旋转矩形、遮挡/缺边/重叠识别和完整标注仍未闭合。

031 已通过 Efinity 2026.1.132、Ti60F225/I3 的综合、外围生成、布局布线和最终时序检查，生成 bit/hex。物理逻辑 60,531/60,800，LUT4 42,346、FF 24,885、RAM10 192、DSP48 12、DSP24 6；最差建立 +0.381ns、保持 +0.029ns。应用时钟 90.909MHz，HDMI 配置 1920×1080@60Hz；算法处理帧率未测。按用户新要求没有新增中文草图或独立模块测试。

人工首调文件：outflow/track4_board.bit。SHA256：77216940A9D01733EF93154C2C0A665F8C3FA0A9E4DE94C5D1FCB6F08FCB9951。登记：控制面 artifacts/staging/TRACK4-BOARD-FIRST-20261011-031/artifact-manifest.json；副本来源见 handoff.json。

KEY1(P13) 复位；KEY0(C4) 加阈值；KEY2(N13) 减阈值；KEY3(A3) 短按切换六种模式、长按约 0.22 秒冻结/恢复。模式依次为彩色、灰度、灰度/Sobel 分屏、Canny、红色叠加、几何候选，上电默认叠加。KEY0+KEY2 同按可切换 Bayer 相位，默认 1，实际色序需观察。

当前 WAITING_HUMAN_PROGRAM。没有操作 FPGA/Flash，没有实物画面或识别效果的通过证据，没有修改正式数据库及硬件状态。

已知限制（2026-10-11）：模式5的POINT尾块未补齐零填充可能触发格式故障，已在主工程037修复但尚未完成该版编译。031源码及比特流保持原样，首测优先模式0–4。
