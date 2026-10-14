# 当前实际读服务组合已通过功能及综合

完整目标仍是五基础、六高阶、1080p、Ti60F225/I3、SC431HAI及原完整识别要求，ACTIVE。用户持续自主软件/local audit授权生效；正式数据库NOT_CONFIGURED、H0及硬件保持。此轮没有bit或硬件操作。

## 完成增量

按已保存/readback/present v1/T1与J1/J2，补齐axi_read_pair_service剩余六计划文件（TB、独立Python、sim/map脚本、XML/SDC），加上一份已有wrapper及三实际依赖共七自写/十源工程。原wrapper与三依赖均未改，实际两客户端不换mock。输入11冻结核对，sim7/map10当前源快照对应。

pair_service_003的真实vlib/vlog/vopt/fatal/vsim/audit完整结束。fatal exit1，其余exit0、无超时。38场景/8325沿，49line接受/46回复、40span接受/37notice，差额是各3明确共同冷reset作废；140物理AR/4871完整128字/4374显示字；6场景wrongRID/早晚LAST及6同AR沿R提前有效；完整512/128与应用/总线账、AR范围拆分、保持、取消、enable、Q、reset均通过。254沿physical_idle而应用仍holding，7旧reply/6旧notice在Q里取走，8旧R在Q里仍流动；通知消费不释放unknown物理身份。6个应用与7个物理unknown/active因明确共同cold reset作废，不说真实暖reset排空。

pair_service_map_001真正Efinity退出0、无超时，Ti60F225/I3/100MHz目标/speed/retiming0/seq_opt0，组合1060 LUT4/820 FF/123 ADD/0 RAM/DSP/SRL；actual netlist primitive数与报告核对。唯一MAP warning是原arbiter循环变量冗余。vopt另有+acc性能warning，vlog/vsim0 warning。没有PNR/STA/网表动态/SDF/物理100MHz证据。

pair_service_001与002 audit FAIL原样保留。J1修正首个同步reset沿前Q=x的观察及物理账身份，正常阶段未知仍失败；J2补公开AR的NBA后曝光，避免误判已经公开后才取消的请求，并添加每例AR数量检查。38场景与数值/覆盖门槛未减少，生产RTL没有为过测试而改。

已登记AXI-READ-PAIR-SERVICE-COMPONENT-20261010-v1.3，195内容文件/26861463字节fresh核对。之前用户要求的GUI已真实加载读仲裁工程和源码；GUI自动扩展work XML的版本存于arbiter inputs/gui-open-normalized-20261010.xml，并从已登记原快照恢复工作XML，所以先前源码绑定不漂移。HDK/安装包/旧登记产物没有修改。

## 仍剩下的整机工作

1. 实际AXI写服务、写读竞争/QoS；生产Source/result/OFFER/APPLY/FREEZE/RETIRE和权威RO lookup。
2. 摄像头CRC、末包错误归属、rx_close、活动C2与溢出帧有效性。
3. 原完整圆/任意旋转矩形、整条短边缺失、遮挡、重叠和最多4目标识别及质量。
4. 匹配2Gb/x16 DDR动态参数/model/PHY资格；数学slave不能替代。
5. 优化FIT带入父STATS及单片总资源/性能架构；当前各组件的独立计数不能证明全部同时装下。
6. 唯一生产top、板型pins/clocks/CDC、PNR/STA和最终bit；bit之后不进行硬件步骤。

下一步实际写服务和生产帧控制设计/代码，继续先中文草图，不重复逐版请求批准。这里未核对真实DDR、FrameRef authority、QoS deadline、暖reset、整机FPS。完整目标没有完成。

## 阅读与计数

planning/design-TRACK4-AXI-READ-PAIR-SERVICE-001.md→T1/J1/J2→work/active/track4_algorithms_20261004/axi_read_pair_service/README.md→RTL连接/三实际叶→TB/独立账→scripts/project→runs。路径相对于控制面。

累计298自写业务/验证文件（含TB/脚本/工程）不是模块数或完成率。228当前增量主文件SHA fresh，70早期基础未全重跑；30登记manifest SHA fresh，195本轮新内容fresh，旧10872内容继承v19及它的明确混合核查范围，没有说这轮全量重读11067项。所有本轮启动工具terminal，没有待恢复工具。理解验收待用户实际作答。
