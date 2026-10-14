# 行消费与连续1080p显示软件结果（2026-10-10）

本轮完成1个实际RTL行消费模块及配套独立参考、TB、脚本和Efinity工程，共7份自写业务/验证文件。继续采用用户“统计后自行进行，无需批准”的持续软件授权，按先中文草图、再源码、单独验证、再组合验证顺序完成；本地审计例外有效。整体任务仍在进行，不宣称完整五基础/六高阶或板级硬件完成。

实现入口：[代码与中文逐沿操作说明](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\README.md>)；[完整设计](<D:\大三\FPGA_verilog\_fpga_edge_agent\planning\design-TRACK4-DISPLAY-ROW-STREAM-001.md>)及J1–J4修订均先形成并读回。模块从真实native行RAM接受票据，预读并持续每时钟输出两个像素；早到/缺数据/取消时保正确前缀并黑余行，兑现已承诺读请求，等响应和显示流水尾部排空后归还。异常占用永久隔离，不伪造归还。

五套实际Questa与独立参考全部PASS：20×8、4×2、6×8、10×8用于参数边界；1920×1080用于原生产分辨率。每套六mode完整连续帧及16故障/边界行。1080p每种模式固定同一bundle/scan跨1080行，真实取数核心→三行native RAM→三实例消费者→已有renderer，参考逐条比较54bit原始行、RGB48、同步/x/y/error、完整身份/GEN及真正core归还。

六帧1080p正常有效像素12,441,600，正常时隙7,425,000；五套总计30正常完整帧、80故障/边界行、7,620,008时隙、12,474,726有效像素、6,228,142真实native pop、6,696真正归还。15条异常隔离行由qualified共同冷复位作废，5条末次隔离仍保留，不能当归还；5次视频钟暂停保身份并恢复。

[1080p独立参考原始结果](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\runs\stream_hd_001\reference-result.json>)明确标出真实DDR、owner/handoff联合、物理CDC均未证明。输入为数学byte-slave/理想调度、固定合法bundle与ANN码型；并非真实摄像头、识别产物或DDR refresh/QoS。

实际Ti60F225/I3组件综合通过：47个FF、894个LUT，无RAM/DSP；[实际综合报告](<D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\runs\stream_map_001\flow\outflow\display_row_stream_component.map.rpt>)只覆盖单消费者top。完整三银行/取数/renderer资源与整包时序尚需同一top验证。本轮无PNR、STA、SDF、bit或硬件操作。

冻结输入24份；7份自写和16份原样复制依赖共23份源码/工程。11次仿真尝试（包括6次旧失败）和实际MAP证据已完整保存，省略可重建编译库。登记包[DISPLAY-ROW-STREAM-COMPONENT-20261010-v1.4](<D:\大三\FPGA_verilog\_fpga_edge_agent\artifacts\staging\DISPLAY-ROW-STREAM-COMPONENT-20261010-v1.4\artifact-manifest.json>)，1105项文件，manifest SHA256 `224234743A60CAD38A8AAED21830891E2321596BD0211AAD23DD693452DD9FC1`。五套100份仿真快照和23份MAP快照均匹配当前源；先前20包7,836项登记文件、175份当前新增源检查零漂移。累计自写业务/验证文件245→252份，当前新增源175→182；原70份基础文件未在本轮整体重跑，数量不是模块数或完成比例。

接下来先闭合完整scan三银行分配、实际owner/handoff候选与旧图repeat、VS切换及旧帧所有引用关闭；然后生产Source/结果/RO权限、摄像头CRC/晚错、DDR服务与动态参数、原复杂识别及共享资源。最后统一Ti60F225/I3生产top、总资源/FPS、实际板引脚/时钟/CDC、布局布线、时序与最终bit，生成后停止硬件步骤。
