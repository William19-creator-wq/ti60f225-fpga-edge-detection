# 实际算法/显示共享读服务：已完成的阅读入口

阅读顺序：inputs/design-v1.md整体→verification-T1.md详细验证语句→J1/J2观察修正→rtl/axi_read_pair_service.sv接线→deps三个原样叶→tb和model→运行脚本/工程→runs及resource-result。七份自写文件含一个新RTL、一个TB、独立Python、两脚本及XML/SDC；三实际叶复制原登记源，不算新自写。冻结输入11，已逐份核对。完整五基础六高阶/1080p/原识别目标保持。

## 数据交接与语句

算法64B line ID0/4拍，显示16..8192B span ID2/最多64拍、4KiB拆分，在一个128位物理读口连接。E1 globalQ由三真实Q或成，仅阻新应用接收；E2实际line_bridge只读，AW/W/B明确无服务；E3实际span原data/done/error/drained不改；E4实际arbiter只阻新选择，公开49位AR及旧R继续；没有新RAM/CDC/Origin。physical_idle不是应用结果已消费或完整FrameRef已closed。

## 实测联合证据

pair_service_003当前源实际vlib/vlog/vopt/expected fatal/Questa/独立audit结束；实际fatal exit1，其余exit0、无超时。vlog与vsim0 error/0 warning，vopt仅+acc可见性性能warning。38场景8325沿；49算法请求/46回复、40显示请求/37终态，差各3是明确共同冷reset作废；140物理AR/4871完整128返回/4374显示字。独立应用与总线账不读DUT层次：完整512/128、合法AR归属/范围/顺序、背压正文保持、数据/通知及reset均核对。

包含274 AR停顿、1765 R停顿、75 reply停顿、1761 data停顿、49 notice停顿；6次同AR沿R提前有效（未提前consume）；6种wrongRID/早晚LAST，8旧R在Q中继续、7旧reply及6旧notice在Q中被消费；254沿physical_idle但应用仍holding。Q旧通知先消费不关闭旧物理身份。早LAST真实ready停止；wrongRID/晚LAST旧尾真实流动后bus仍Q/occupied，新申请仍被禁止。不从读完或notice被取走证明FrameRef关闭。

pair_service_map_001实测1060 LUT4/820 FF/123 ADD/0 RAM/DSP/SRL，实际网表primitive数与报告核对。四RTL组合计数，不能把独立叶相加代替这个结果。目标Ti60F225/I3、100MHz约束，mode speed、retiming0/seq_opt0；唯一MAP warning为arbiter循环变量冗余。没有PNR/STA/网表动态/SDF/物理100MHz证明。

## 原失败、范围与后续

pair_service_001/002保留为FAIL：第一audit误读首个同步冷reset沿前Q=x；第二preedge-only AR账误判沿后已公开、下一负沿取消的请求。J1保持物理身份至真实尾/冷reset且正常阶段未知仍失败；J2补沿后全49曝光及每例AR计数，没有减少38场景、改数值期望或降低覆盖门槛。生产wrapper及三deps全程不改。

数学地址slave不是实际DDR。这里无写仲裁、DDR PHY/器件参数资格、FrameRef lookup权威、warm reset drain、QoS deadline、板级pins/CDC、整机FPS或最终bit证据。接下来完成实际写服务、生产帧控制和唯一root，再补camera CRC/末包/rx_close、完整复杂识别及总资源/时序。正式数据库NOT_CONFIGURED、H0与硬件不改；本地审计按既有例外。理解验收待用户实际作答。
