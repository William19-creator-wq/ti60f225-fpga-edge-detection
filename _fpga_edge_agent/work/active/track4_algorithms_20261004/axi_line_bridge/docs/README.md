# 64B line 到四拍128bit AXI的软件桥 v1

基线 `AXI-LINE-BRIDGE-BL-20261009-v1`，5份输入；用户持续自主授权、本地审计。先读planning设计整体，再读rtl/axi_line_bridge.sv中的通道和固定case，之后读独立bytearray slave、TB、参考和报告。实际公开宽度来自V4 DDR控制器参数及已有只读来源证据；不改保护IP。

中文草图：真实line_fire锁完整512bit、byte地址和方向；64B对齐/完整端点检查错误时安全回复且不发AXI。写方向AW→4次真实W→真实B；地址/data/last在stall期间不变，第4W不能等于写成功。读方向AR→4次真实R，先保留完整512bit容量，独立客户端ready接收；末拍用含本拍的next_read_buffer，核ID/RESP/LAST/数量再回复。回复保持到消费者实际接纳。

正确ID的响应错误且完整结束给error1/drained1；错ID、早LAST、缺LAST给不可变error1/drained0通知并隔离。未知通知消费后仍不接纳新line；真实旧ID0/LAST或ID0/B回执继续吸收，也不把未知通知改成安全。enable只控制新请求资格，活动期间下降会保留不可信事实，继续旧公开AW/W/AR/B/R，最终给未知通知；恢复enable不会擦除旧债。共同rst仅由外层安全证明使用。

`axi_line_001`通过1297个事务/场景：512正常写、768正常读、256行完整域扫描、零/全FF/单bit/空间图案、实际64B低地址lane；1297实际接纳、519 AW、776 AR、2076 W拍、3104 R拍、520 B回执；7个unknown错误/enable-loss场景均隔离。另有对齐/容量拒绝、最后64B、4KiB相邻、AW/AR/W长stall、末W后B延迟、普通BRESP/RRESP错误、held回复及安全共同复位。独立Python按实际请求日志重放完整byte写，与端点16KB最终内存一致。

`axi_line_map_001`在Ti60F225/I3组件MAP通过：1068 FF、1362 LUT4、0 RAM、0 ADD、0 DSP。工具资源summary省略零项，实际映射网表没有任何RAM/DPRAM/ADD原语，MemoryPorts=0；零项以实际网表SHA登记，不能凭缺报告填写0。100MHz SDC是组件目标，尚非生产PNR/STA。

复跑scripts/run_axi_sim.ps1指定新RunId；run_axi_map.ps1引用通过且source hash相同的SimulationRun。project/axi_line_bridge_component.xml可在Efinity打开。生产DDR连接时AW/AR的LOCK/CACHE/PROT/QOS由平台固定普通访问值并完整接齐，不可遗漏控制器公开引脚。

后续AB-T04还要接入实际RAW source与Canny client，逐字节/状态/FIFO验收；本包尚未把它们整合。完整DS scope/grant/phase/fence、FM源发布、真实DDR2Gb器件/PHY/校准/读后可见性、服务带宽/QoS和整机pin/clock/PNR/STA/bit仍分别验证。这是软件AXI端点协议证据，不把bytearray当板载DRAM动态模型。
