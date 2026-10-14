# 当前软件进度：读仲裁、原生FIT与实际双客户端组合

完整目标仍为五基础、六高阶、1080p、Ti60F225/I3、SC431HAI及原完整识别要求，ACTIVE。按用户持续“统计后自行进行，无需批准”与local audit例外实施。正式DB/H0/state保持，环境本轮确认FPGA_AGENT_DATABASE_URL不存在。没有硬件操作或新bit。

## 新完成的真实工作

AXI读仲裁七份业务/验证文件全部生成（上一轮只有RTL，本轮补六份）。原场景因2457字未到2500测试量下界导致audit FAIL，保留read_arbiter_001；J2增加双源压力且不降低门槛、删例或改RTL。J1在测试前补四态资格检测，原初始RTL及冻结卡保持。

read_arbiter_002完整26场景5792沿的全49/135总线与独立事件账PASS：181物理AR、2933完整128位字、248 AR停顿/1479 R停顿、同AR沿早到R、非OK RESP、四态违约、地址边界、wrongRID/早晚LAST/无owner及Q保留均经过实际检查。两个双源压力各0001重复8次；display1..64拍和algorithm32个4拍burst。模型是数学协议slave，不是真实DDR。共同cold reset作废不冒充真实暖reset排空。

read_arbiter_map_001实际Efinity退出0、无超时，报告/网表199 LUT4、72 FF、51 ADD、0 RAM/DSP/SRL，各7源/工程快照相符。Ti60F225/I3/speed/retiming0/seq_opt0/100MHz目标，唯一warning循环变量冗余；无PNR/STA/bit或组合deadline证明。已登记AXI-READ-ARBITER-COMPONENT-20261010-v1.2，120项字节重新核对。J2 runner输入守卫9→10的行政变化在README明确更正，旧冻结文档/失败不覆盖。

FIT-NATIVE-MAP-CHECK-20261010-v1已登记107项，三新增/适配验证文件、14复制或明确适配依赖，23输入/17运行源相符。真正使用共享版整份MAP netlist及官方FF/LUT4/ADD/DSP48/RAM10；没有用理想模型替换、强制内部完成、关闭READ_UNKNOWN或改生产逻辑。副本网表只唯一module重名适配、GB18030/CRCRLF→UTF8/LF，反改声明规范化文本一致；原始网表/所有ports/instances/defparam/INIT/登记包不改。

fit_native_001真实compile/elab/fatal/native_vsim/audit完整结束，native及audit退出0、无超时，vsim0 error/0 warning。全部181定向加11大(kind,label)各4固定分布位置共225数值，原顺序/完整622身份保持。原full14517 RTL向量和结果原样保留，不将225说成全量网表验证。597564个公开core沿req_ready/rsp_valid/quiet及valid完整585与当前RTL严格一致；原37取消/35reset/5cache、302接受/267消费/35作废、所有父/桥/子状态、独立数学和事务账PASS。4486helpers/45074有效槽/1357局部192/3691计划406是currentRTL vs oldR3检查，原生侧只公开口，范围不混用。

自动推断的常量MUX RAM在实际网表与上述协议中功能节拍通过，没有发现新增公开延迟；这个结论是225+原全协议/原生零延迟模型，没有SDF/100MHz物理速度/PNR/STA/全14517网表/板级DDR或整机证明。此前共享实测32794 LUT/7076 FF/2696 ADD/2 DSP/1 RAM没有更改；父STATS资源和时序仍另闭合。

## 实际生产读服务的新代码

按已保存读回呈现v1，新axi_read_pair_service RTL及三实际叶副本、8冻结输入已生成；叶字节与各注册包相同。真实算法64B line、显示16..8192B span和仲裁共用128bit读口；globalQ只堵新应用及新仲裁选择，已有AR/R/data/终态不屏蔽。原error/outcome/reason/drained保留，physical_idle不等于应用或FrameRef closed。

pair_compile_001真实vlib/vlog/vopt退出0，4当前源/快照相符，证明语法和命名端口可展开。这个组合还没有联合功能TB/独立应用账/MAP，后六计划文件未生成，不能称生产链路已经通过。下一步直接按v1补它们，不需要再次逐版批准。

## 整体已经有什么与剩下什么

已有灰度/中值/Sobel/阈值/Canny的代码与独立验证，已有RAW10/彩色转换/I2C及部分原IP仿真、1080p显示六模式/帧交接测试、点统计/FIT/角度数学核心和帧所有权核心。它们是模块或特定组合证据；尚无把全部十一功能、实际camera/DDR/display/识别接成同一生产工程并满足总资源/时序/质量的证据。

剩余：实际line/span/arbiter联合闭合，AXI写仲裁和QoS；生产Source/result/OFFER/APPLY/FREEZE/RETIRE业务控制与RO lookup权威；CSI CRC/末包错误归属/rx_close/活动C2及溢出帧有效性；匹配2Gb DDR参数/model及PHY动态资格；原完整圆/任意旋转矩形、短边缺失/遮挡/重叠/最多4目标识别和质量；把获实测优化带入父STATS及统一资源/性能方案；唯一生产top、板型pins/clocks/CDC、PNR/STA和最终bit。DDR资料缺口只影响相关动态资格，不作为不写其它代码的理由。

本轮所有启动工具已真正结束，没有待恢复工具。292是累计自写业务/验证文件（含TB、脚本、工程），不是292个模块或完成率。222个当前增量主文件SHA重新核对；另70早期基础源没有全重跑。29份登记manifest SHA重核，本轮227新内容字节fresh；旧10645项继承v18证据及其明确分层检查范围，没有声称这轮全量重新读完。

## 阅读入口与次序

1. planning/design-TRACK4-AXI-READ-ARBITER-001.md及J1/J2→work/active/track4_algorithms_20261004/axi_read_arbiter2/README.md→RTL→TB/model→runs和resource-result。
2. planning/design-TRACK4-FIT-NATIVE-MAP-001.md→fit_native_mapped/README.md→source-binding-note及selection→监视器→原生完整工具日志/数学audit。
3. planning/design-TRACK4-AXI-READ-PAIR-SERVICE-001.md→axi_read_pair_service/README.md→实际三叶连接→pair_compile_001；未来联合场景按G/H继续。

路径相对于控制面。理解验收待用户实际作答；真实软件验证不等于硬件验收，最后bit之后停止硬件步骤。
