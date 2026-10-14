# 两个实际64B写接口共享写服务：阅读入口

阅读整体inputs/design-v1.md→E1..6中文语句→rtl/axi_write_pair_service.sv→deps/axi_line_bridge.sv→tb/model→scripts/project→runs/resource-result。七自写（一个RTL、TB、Python、两脚本、XML/SDC）加一个原样bridge共8源工程，8输入冻结已核对。两producer接口来自实际RGB source及capture/Canny源码；本单元没有实例化它们，不称完整camera/algorithm链路通过。

## 数据与归属

端0camera、端1algorithm，同clk/rst/enable；有效请求完整addr32/data512，64B对齐/默认256MiB。只有bridge真的ready且服务无active/Q时，选中端ready与bridge同沿接纳，桥自己保存唯一512快照；owner/credit在同沿更新，持续双方可用机会0001循环。四W低byte至低地址、STRBffff；最后W不是成功，真实B与client回执消费才释放安全owner。正确BRESP错误可安全error/drained1但不保证回滚已写字节；wrongBID或live enable下降UNKNOWN/drained0，回执消费后active/Q保留、真实旧B仍能吸收。

globalQ只阻新申请，不屏蔽旧AW/W/B或通知；busy含unknown身份，没有allClosed/FrameRef归还捷径。无owner B阻本沿接纳并localQ2，未完成四W前B出现为localQ3（同末Wfire提前BVALID除外）；已公开回执正文不因新B重写。未知有效申请为localQ1，未接纳则无伪通知；这些X/Z资格是RTL四态仿真语义，不是现实亚稳态检测。actual桥unknown用reason4，首因与全输入/事件保存。

## 实际验证

write_pair_001真实compile/elab/fatal/vsim/independent audit全部结束；fatal exit1，其余exit0、无超时。35展开场景6674沿，252请求/248回执，差4是AW/W/B/held回执上的明确共同cold reset作废；248 AW/990完整145bit W（128 data/16 strobe/last）/249 B，246次完整512实际数学slave字节存储快照，15,840字节真实模型写副作用。物理写数与应用通知数分账；9个UNKNOWN已通知物理记录仍保留至共同reset，不能说真实暖reset排空。

独立ledger不读DUT层次，完整544请求/49 AW/145 W/6 B/owner error/drained及实际byte-memory核对。双源两个case各0001重复16、单源各24；全0/FF/首尾单bit/固定seed图案、capacity末64B及非法边界、每W位置停用、晚disable不改safe held reply、普通BRESP1/2/3、wrong/多bad BID、无owner/early B、通知先消费再真B、四态/unused payload及共同reset均检查。401 AW停顿/282 W停顿/59 B停顿/370 reply停顿；3 wrongBID事件、4旧B/4旧W/9旧回执在Q中仍实际消费。强度门槛≥200完整line/≥800W保持，实测246/990。

write_pair_map_001实际Efinity exit0/无超时，873 LUT4/562 FF/0 ADD/RAM/DSP/SRL；netlist与报告一致。网表只有512个write_bridge/write_buffer FF，service自己8 control FF，没有另一个544 holding。Ti60F225/I3、100MHz目标、speed/retiming0/seq_opt0；2 MAP warnings为X/Z检测按二态常量优化，与设计E6范围一致，不宣称硬件能检测X/Z。vopt仅+acc性能warning；vlog/vsim无error或warning。没有mapped动态/SDF/PNR/STA/物理100MHz/真实DDR/整机FPS证明。

## 范围与管理

初始输入冻结查找遇旧artifact的source/rtl前缀，与预期rtl不同；保留inputs/baseline-freeze-attempt-001.json。八输入当时已复制，RTL在设计readback呈现之后创建、baseline JSON尚未完成；修正路径并逐source/冻结/注册SHA核对后才首次运行任何tool/test。没有隐去失败或改原注册包，功能测试首轮已通过。

之后仍需真实RGB writer/算法父与read/write公共口组合、FrameRef/lookup/生产帧管理、读写QoS与最坏带宽、camera CRC/rx_close/overflow、完整复杂识别、总资源/FPS及唯一production top/引脚/时序/bit。正式DB/H0及硬件不改，按既有自主软件/local audit例外；完整五基础六高阶/1080p/原识别目标ACTIVE，bit后停止硬件操作。理解验收待用户实际回答。
