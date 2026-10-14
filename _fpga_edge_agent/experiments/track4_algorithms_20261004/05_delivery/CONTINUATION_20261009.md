# 2026-10-09 继续实施：实际彩色源链路及AXI软件桥

本轮是 progress，五项基础/六项高阶的完整目标仍 ACTIVE。用户持续自主授权，不再逐模块询问批准；中文整体/接口/局部语句草图保存读回后继续实现。正式DB、原HDK、旧登记包和硬件不改，沿用本地审计。

## 已落地且有工具证据的新增部分

| 单元 | 新增自有源码/参考/TB/runner/工程数 | 实际证据 | Ti60F225/I3组件MAP |
|---|---:|---|---|
| raw10_color_stream | 9 | 四相位×10模式、4×2/6×5/34×19/1040×3；4幅完整1080p逐窗口和RGB一致，8,294,400像素 | 4 RAM、640 FF、1044 LUT4、200 ADD、0 DSP |
| rgb_source_writer | 9 | 6模式/最小/整bankEOF/partial padding/两bank满/7取消；RTL全1080p及**实际.map.v全1080p**各6,220,800B全部一致 | 4 RAM、1512 FF、2006 LUT4、55 ADD、0 DSP |
| raw_source_join | 7 | 实际RAW行RAM→四相位插值→连续RGB→真实软件line写回；4幅1080p，24,883,200B一致；4尺寸×40场景、错误discard与两终态关闭 | 8 RAM、2487 FF、3009 LUT4、255 ADD、0 DSP |
| axi_line_bridge | 8 | 64B→4×128bit AXI；1297事务，512正常写/768正常读、7unknown场景、held AW/AR/W/回复、真实B/完整R关闭 | 0 RAM、1068 FF、1362 LUT4、0 ADD、0 DSP |

本条连续实验的文件统计从此前107增加33，共140；不是140个算法模块，也不宣称统计了原HDK或整个项目的所有文件。共享子模块、GUI镜像、文档、audit工具及run向量不重复计。此前Canny/R1/R2/ANGLE/STATS/FIT等冻结结果继续有效。

source_map_001出现动态数组部分写的非驱动接地警告，未登记通过；先写v1.1修订草图，再改两个明确512bit寄存器/8项固定case，source_map_002警告消除，并直接对其实际.map.v验证全部1080p字节。两次测试端修订前的中断记录保留。单元RTL通过不能替代综合电路；综合电路没有SDF，也不能替代生产静态时序。

四个新增不可覆盖登记包：RAW10-COLOR-STREAM-COMPONENT-20261009-v1、RGB-SOURCE-WRITER-COMPONENT-20261009-v1.1、RAW-SOURCE-JOIN-COMPONENT-20261009-v1、AXI-LINE-BRIDGE-COMPONENT-20261009-v1。目录在 `_fpga_edge_agent/artifacts/staging/`。AXI工具summary省略RAM/ADD零项，登记另保存实际无原语的网表SHA证据；没有把缺行直接当零。

## 人工观察顺序

1. 先看[采集整体草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-RAW-SOURCE-JOIN-001.md)，再看[父组合中文入口](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/raw_source_join/docs/README.md)：RAW先配置/启动、正常字节交接、writer失败后明确discard、两个真正终态。
2. 局部先读[RAW窗口/插值](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/raw10_color_stream/docs/README.md)，然后读[RGB连续字节/双bank/组拍](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/rgb_source_writer/docs/README.md)，最后进入各RTL固定切片/旧状态事件。
3. 观察[实际1080p仿真源图](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/05_delivery/raw-source-1080p-actual-20261009.png)：从已通过实际RGB内存逐字节导出，未改像素；这是软件仿真彩条，不是硬件拍摄截图。旁边provenance.json保存源和图像hash。
4. 在Efinity打开[采集组件工程](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/raw_source_join/project/raw_source_join_component.xml)及[AXI桥工程](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/axi_line_bridge/project/axi_line_bridge_component.xml)。内部总线将由生产top连接，不能把几百条内部端口直接指定板卡引脚。
5. 读[AXI桥内部草图和验证](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/axi_line_bridge/docs/README.md)，再查runs的suite-result/reference-audit/actual-results/source-manifest、map报告与artifact-manifest。局部96位job_scope完整保留；它不是尚待整合的DS完整623位授权scope或SourceOrigin195的替代物，完整权限仍由外层保存和核验。

## 尚未完成及下一步

下一步把实际RAW源和Canny line接口接入该AXI桥，运行真正四拍读写的组合仿真；随后完成FM/源发布、完整grant/phase fence、冻结恢复与显示预取。现有source/bridge是分别验证过的组件，这条实际组合还未跑，不把它写成已接通板载DDR。

真实摄像头SC431HAI I2C、MIPI/CSI、不可反压FIFO/CDC及RX closure仍待实现/组合；HDMI已有局部扫描/并行呈现，TMDS、真实74.25MHz、显示同源预取与标注尚待。复杂圆/旋转矩形/遮挡/多目标/负样本质量识别与候选逻辑、算术复用和总资源/帧时间优化、单一生产top/引脚/时钟/PNR/STA/总bit仍待完成，不改变1080p和原识别要求。

DDR匹配2Gb/x16参数模型与PHY/校准/读后可见性仍有资料缺口；它只影响对应物理动态证据，不阻止其它软件编码。新组件MAP及软件bytearray模型没有关闭这项缺口。STATS独立包52619/60800 XLR及旧最重HY周期风险继续存在，不能简单累加上述资源后宣称整机装得下或达原目标帧率。全部五基础/六高阶的总工程尚未闭合；总bit后仍停止硬件步骤。
