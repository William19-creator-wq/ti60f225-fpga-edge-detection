# 2026-10-09 第二批：源读回与完整同源Canny

本批新增reader与capture组合各7份业务/验证文件，累计从140到154；文件数不等于模块数，文档/共享镜像/运行数据/审计脚本不重复计。已沿既有授权自行实施和验证，整项目仍ACTIVE。

reader完整1080p：1,036,800对、97,200真实读取；综合0 RAM、1384 FF、2058 LUT4、26 ADD、0 DSP。

capture组合真实RAW→源写回→实际源读回→完整R2/分类/cache/queue/八邻域连接→结果写回→唯一128bit AXI。34×19和6×109各20图像、34协议；窄图实际held-FP故障witness=1、discard=1。完整1920×1080逐位核对2,073,600像素、源6,220,800字节及分类/最终状态/队列/FP/CS592/Origin；边缘1078、discard0，作业36,811,963拍。源写/读各97,200，全部AW138,846/AR114,544、W555,384/R458,176/B138,846。

实际组合MAP：46 RAM10、21,976 FF、27,109 LUT4、1,776 ADD、166 SRL8、0 DSP。100MHz是组件目标约束；此数字不替代生产PNR/STA/帧率证据。三个当前源绑定的仿真PASS和MAP快照一致；失败attempt仍在work/runs保留，修订原因在设计卡J1…J8。

两个新增不可覆盖包：RGB-FRAME-READER-COMPONENT-20261009-v1、CAPTURE-CANNY-AXI-COMPONENT-20261009-v1.1。本次校验10份组件Manifest共4579条文件、旧70份工作文件加新14份，hash漂移0。初始70份功能文件沿此前登记证据，本轮不虚构重新逐文件检查全部154份。

阅读顺序：planning/design-TRACK4-CAPTURE-CANNY-AXI-001.md → work/active/track4_algorithms_20261004/capture_canny_axi/docs/README.md → 父端口/范围检查/子实例 → 父状态/源取消适配 → reader字节组合 → Canny实际共享服务 → runs独立审计/实际MAP → staging冻结副本。Efinity可打开capture_canny_axi/project/capture_canny_axi_component.xml；内部端口须接最终生产top，不直接成为板卡引脚。

![同源软件仿真概览](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/05_delivery/capture-canny-1080p-actual-panel-20261009.png)

图来自实际通过软件仿真的源/结果；旁边三份native PNG保留1920×1080。红色观察叠加为软件显示，尚不称RTL彩色叠加已经整合。来源SHA/图SHA由provenance.json记录。

后续五类：摄像头实际I2C/CSI及不可反压FIFO/CDC；完整存储授权/真实fence/FM冻结恢复；显示预取/TMDS/标注；复杂识别/负样本质量/候选；算术复用、总资源与时间、单一生产top/引脚/时钟/PNR/STA/总bit。DDR匹配2Gb/x16模型/PHY/校准/读后可见性缺口仍在，仅对应物理动态证据受影响，其他编码继续推进。STATS独立包资源和最重HY时钟风险仍需实改优化，不能把各独立包相加宣称整机装得下。

约束保持Ti60F225/I3、SC431HAI、1080p、板卡现有资源、DDR允许；不改变原识别要求。中文设计先读回，持续自主实施与本地审计继续。原HDK/冻结包/正式DB/state/hardware不改，总bit后停止硬件步骤。理解验收待实际作答，软件通过不冒充硬件通过。
