# 摄像头RAW10采集适配阅读说明

先读planning/design-TRACK4-CAMERA-RAW-BRIDGE-001.md的B整体、C连接、D接口，再读E两部分中文操作草图。实际实现对应camera_pixel_framer的DISARMED/WAIT_IDLE/WAIT_SOF/FRAME/WAIT_END/TERM，以及camera_raw_bridge的RUN/DRAIN/REPORT/WAIT_DISARM/QSTATE。

一组CSI有效输入有四个10位像素。组内低40位全部保留，连同handle64、x_group9、y11及三个标记写成128位FIFO记录。FIFO跨pixel_clk与core_clk，核心私有槽先给低20位两个像素，再给高20位两个像素。首拍SOF，第二拍可有EOL/EOF；每个pair都有同一个完整handle。Origin195留在核心job快照，用于done归属。

按valid且ready在核心上升沿发生真实交付。ready低时数据、坐标、标记和handle都保持。相机没有ready，FIFO满不是可无限延长的停顿；本组件明确报OVERFLOW、排空已接收前缀并隔离。cancel只停止新输入，不撤销已经停顿的输出；只有同handle的显式discard授权可退休旧输出并记丢弃计数。错误handle不生效。

相机帧的最后pair/EOF先到，VS下降可能稍后才到。shape_complete只表示行数/组数及HS/VS结束都准确；reception_verified恒为0。capture_canny_axi需要的独立rx_close必须由真实接收错误归属/closure模块提供，不能把此shape报告直接接为rx_close_good。超时未收到像素终态时groups_known=0和drained=0；计数0占位不表示接收了零组。

FIFO原样复用当前video_async_fifo，双时钟原生RAM10 READ_UNKNOWN、两FF Gray同步与两读槽。整个组件仅共同安全冷复位可清隔离；不得复位单端指针。生产板级CDC最大延迟/skew、引脚与复位来源尚待总集成，这里SDC只约束MAP目标100/50MHz。

代码顺序：像素framer组合错误优先级/记录布局→像素时序旧状态操作→FIFO接口→核心pair槽与计数→核心terminal/ack状态。修改几何需先改设计B/D/F、参数和两TB的唯一TEST_/PROBE_参数；修改identity不能截短handle。所有TB从负沿驱动，在正沿观察旧valid/ready。独立Python只读取实际pair日志并重新按坐标计算10位公式，不复制RTL FSM。

运行入口scripts/run_bridge_sim.ps1 -RunId 新名称；-FullHD完整1080p两帧，-Coupled真实官方CSI TX/lane/RX再接生产适配，组合FullHD一帧。run_bridge_map.ps1 -RunId 新名称 -SimulationRun 已通过当前源运行。每次保存源SHA、工具PID/参数/退出码/stdout/stderr和fatal出口探针。失败尝试不覆盖。具体本轮结果见设计K、runs和staging manifest；综合不是PNR/STA/bit，更不是硬件通过。
