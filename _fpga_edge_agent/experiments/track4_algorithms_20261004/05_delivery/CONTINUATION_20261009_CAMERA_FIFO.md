# 2026-10-09：摄像头配置与双时钟运输继续交付

已按用户自主执行授权完成新20份业务/验证输入：SC431HAI配置13份、FIFO7份，累计174份。文件数不是模块数；共享镜像、官方依赖、文档、运行向量、日志和审计辅助不重复算业务代码。

摄像头配置：真实开漏数字事务，ID/CD6B、原表164次保序写、14项公开masked读回、STOP停流、T4启动等待与故障关闭。I2C主控276用例、快速配置43用例/5次完整配置/900笔事务独立核验；生产100MHz时钟/101MHz上界另完成配置+STOP，共2用例/180笔完整配置事务。生产参数实测最短低5070ns、高5080ns、START5050ns、STOP5080ns、空闲10150ns，平台资格到首START4045075ns。MAP为1 RAM10/961 FF/1576 LUT4/82 ADD/0DSP。不会把寄存器资格直接当采集ARM或真CSI成功。

视频FIFO：两真实独立时钟，native双时钟RAM、Gray同步、2条前取信用、held数据和独立粘滞损失。当前源9组运行49场景核对659248条，104次预设丢失一致；宽1…320、深16…4096含绕回/停钟/恢复/满/共同冷复位。完整1080p四像素组数量518400条在约70MHz写/100MHz读下全部交付、零丢失。MAP为14 RAM10/387 FF/445 LUT4/31 ADD/0DSP。首MAP原语READ_FIRST不合法，保留失败，设计J1修为READ_UNKNOWN，全部002源重新仿真后登记；旧320位运行源漂移被脚本拒绝，未混入新证据。

这两批是实际独立组件综合；未对它们执行板级PNR/STA或生成整机bit。FIFO物理Gray延迟/偏斜、真实电平/SID/reset、CSI位序/PPC/sideband/错误/closure仍需生产平台闭合。不能把独立组件的资源简单相加宣布整机装得下，STATS共享算术与最重HY处理时间优化仍在后续。

中文阅读次序：planning/design-TRACK4-SC431HAI-CONFIG-001.md → sc431hai_config/docs/README.md → profile/master/父状态/独立wire trace；planning/design-TRACK4-VIDEO-ASYNC-FIFO-001.md → video_async_fifo/docs/README.md → Gray/信用/RAM/双域复位 → 外部接受/交付参考 → 各runs/MAP → artifacts/staging冻结副本。

本次重核84份既有增量工作源及20份新源，共104份；初始70份沿其既有功能与登记证据，不伪称本次重新测试全部174份。12份组件Manifest共5071条文件逐一SHA核对，漂移0，当前11组仿真及2个MAP源一致。新包SC431HAI-CONFIG-COMPONENT-20261009-v1与VIDEO-ASYNC-FIFO-COMPONENT-20261009-v1均只在staging，不升级为硬件验收。

原先已通过的1080p RAW→RGB源写→真实AXI源读回→完整Canny结果证据保留于前v5，2073600像素/1078边缘等事实未被本批重复冒充。既有观察图仍可读：capture-canny-1080p-actual-panel-20261009-v2.png，红色叠加为软件观察，不称生产RTL显示已完成。

接下来继续CSI映射/真实closure、帧管理与冻结恢复、显示预取/TMDS/标注、完整复杂识别及算术共享，再做全工程资源/处理时间/单一生产top/引脚/时钟/PNR/STA/bit。新发现本机官方CSI ModelSim示例（soft_dphy及source_modelsim），尚未运行；不能把找到文件写成兼容已通过。板载2Gb/x16匹配DDR动态模型缺口仍只影响对应控制器/PHY动态证据，其他编码继续，不恢复排除DDR或降低1080p/识别要求。

本次未改原HDK、冻结包、正式数据库/状态，未下载、安装、联网或操作硬件；仍采用已准本地审计。整目标ACTIVE，生成最终bit之后停止硬件步骤。人工理解验收仍待实际作答。
