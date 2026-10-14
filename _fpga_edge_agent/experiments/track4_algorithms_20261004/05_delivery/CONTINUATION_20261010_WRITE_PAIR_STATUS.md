# 共享写服务已完成代码、功能仿真与综合

完整目标保持五基础六高阶、1080p、Ti60F225/I3、SC431HAI及原完整识别要求，ACTIVE。持续自主软件/本地审计有效，PostgreSQL未配置、正式H0/state及硬件不改，本轮无bit/硬件步骤。

## 本轮真实增量

axi_write_pair_service七自写文件（RTL/TB/独立Python/sim/map/XML/SDC）加一份原样实际axi_line_bridge。实际RGB source和capture/Canny源码均采用64B写RPC，因此新模块两个此接口共用一个512快照桥，camera:algorithm可用接纳机会3:1，owner直到实际B/回执安全消费。UNKNOWN通知先取走、后真B仍继续，Q/busy保留，新申请禁止。producer主体本批未实例化，不能说camera/Canny完整生产链已通过。

write_pair_001实际compile/elab/fatal/vsim/audit完成，fatal退出1，其他退出0、无超时。35展开场景6674沿，252请求/248回执，差4是明确AW/W/B/held回执共同cold复位作废；248AW/990完整W/249B，246全512数学slave真实byte-memory快照一致；15,840字节实际模型写副作用，普通BRESP错误不伪称回滚。双源两个压力case各0001重复16、单源各24；全0/FF/首尾单bit/固定seed、边界、每W停用、晚停用held回执保持、错误/早/无ownerB、四态及共同reset均核对。≥200完整写line/≥800W门槛保持，实际246/990。

401 AW/282 W/59 B/370回执停顿，3 wrongBID、4旧B/4旧W/9旧回执在Q里真正消费。未知通知不释放物理身份；9已通知UNKNOWN记录仍留到可信共同reset。独立账不读DUT层次，从完整544/49/145/6公开字段建立归属/字节/应答和作废集合。设计8输入、sim5/map8当前源快照及输入SHA相符。

write_pair_map_001 Efinity Ti60F225/I3/100MHz目标/speed/retiming0/seq_opt0实际退出0，无超时：873 LUT4/562 FF/0 ADD/RAM/DSP/SRL，实际网表primitive与报告相同，write_buffer正好512FF，service自己8 control FF。2 warnings是X/Z比较在综合成为二态常量；设计E6只声明RTL仿真guard，不冒充硬件亚稳态/CDC检测。没有PNR/STA/网表动态/SDF/物理100MHz/真实DDR/整机性能证明。

登记AXI-WRITE-PAIR-SERVICE-COMPONENT-20261010-v1：88项10705207字节fresh核对。初次baseline lookup遇旧manifest source/rtl前缀而不是rtl，导致行政冻结未完成；保留inputs/baseline-freeze-attempt-001.json。RTL在设计已保存/readback/present后生成，八输入已复制但baseline JSON当时未完成；修正实际prefix并逐注册/source/copy SHA核对、冻结后才运行工具，没有把失败藏成PASS，功能首轮通过。原HDK/注册包和实际bridge不改。

## 仍剩下的实际整机

1. 实际RGB source/算法父实例与公共read/write hub组合、生产FrameRef/权威RO lookup、Source/result/OFFER/APPLY/FREEZE/RETIRE及读写QoS。
2. CSI CRC、末包错误/rx_close/活动C2及溢出帧有效性。
3. 原完整圆/任意旋转矩形、缺短边/遮挡/重叠/最多4目标识别及质量。
4. 匹配板载2Gb/x16 DDR动态参数/model/PHY资格，数学slave不替代。
5. 共享FIT带入父STATS及单片总资源/FPS架构；当前组件计数不能证明全部同时装下。
6. 唯一production top、板型pins/clocks/CDC、PNR/STA和最终bit；bit后不执行硬件动作。

下一步实际camera writer→写服务及生产read/write hub/帧控制的设计/代码，按持续自主授权无重复逐版批准。DDR资料缺口不挡其它实现。此前read_pair三叶38联合及MAP仍通过，没有重跑已结束工具。

## 阅读入口和核查范围

planning/design-TRACK4-AXI-WRITE-PAIR-SERVICE-001.md整体/接口→E逐语句→work/active/track4_algorithms_20261004/axi_write_pair_service/README.md→RTL/actual bridge→TB/独立参考→scripts/project→runs/resource-result。理解验收待用户实际作答。

累计305自写业务/验证文件不是模块数或完成率；235当前增量主文件SHA fresh，70早期基础未全重跑；31登记manifest SHA fresh，本轮88新内容字节fresh，旧11067继承v20及明确混合范围，不说这轮全量重读11155项。所有本轮工具terminal，无待恢复工具。完整目标尚未完成。
