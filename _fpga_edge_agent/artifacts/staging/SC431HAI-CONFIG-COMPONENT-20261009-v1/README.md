# SC431HAI 配置链：先读设计，再读总线，再读组合

2026-10-09，TRACK4-SC431HAI-CONFIG-001 v1。本单元为独立软件组件，沿用“当你统计完后自行进行，无需我的批准”和本批本地审计例外。原 HDK、数据库、正式硬件状态没有改动。

## 1. 从整体现象开始

系统接受一个配置任务，等待平台给出的电源、EXTCLK、reset 已就绪信号连续有效至少 4 ms，然后读取芯片 ID，按原表顺序写 164 个寄存器，再读回 14 个公开字段。只有每次实际总线事务关闭、内容全部正确，才给出 `OK / drained / registers_verified`。这个标志代表寄存器配置资格；真实 CSI 帧、颜色相位和采集授权由后续链路验证。

阅读顺序：控制面 `planning/design-TRACK4-SC431HAI-CONFIG-001.md` → 本说明 → `rtl/sc431hai_profile_pkg.sv` 的值/原因编码 → `rtl/i2c_register_master.sv` 的总线 → `rtl/sc431hai_profile_rom.sv` 的表 → `rtl/sc431hai_config.sv` 的组合 → model/TB → runs 实际日志。

数据方向：父配置状态机提供锁定的寄存器事务 → 主控在 SCL/SDA 外部数字线上执行 → 从机实际返回 ACK/数据 → 主控等待 STOP/总线释放 → 父提交写/读计数与核验。独立从机按外部线的边沿解码，不通过读取 DUT 内部状态伪造成功。

## 2. 交接与参数

统一在 `clk` 上升沿以 `valid && ready` 接纳。父任务身份为 160 位 `{sequence64, generation64, epoch32}`，地址只允许 SID 对应的 0x30/0x32；操作 0 完整配置，1 stream-off。每个底层请求带完整 64 位 tag，父提前核查 180/2 条预算，禁止回绕。公开请求保持到实际接纳，终态全部字段保持到消费。外部提案随后改变不改变旧任务。

默认 `CLK_MAX_HZ=101000000`，正式组件综合约束目标 100 MHz；实际时钟须小于等于该上界。SCL 固定标准模式 100 kHz，半周期向上取整为 505 个周期。数字线上低、高、START、STOP、tBUF 计时均从实际同步后的线水平开始。时钟延展等待期间不计入有效高电平时间。单状态无法推进超过默认 10 ms 就进入隔离；等待平台期限默认 100 ms。数值乘法先扩为 64 位，计数位宽用 `$clog2(limit+1)`。

`scl_drive_low/sda_drive_low` 只能交给外层的 0/Z 开漏输出。两个输入各用两级同步寄存器。实际电平、上拉、上升沿、SID、XSHUTDN 及生产引脚/CDC 约束仍需平台闭合。

## 3. 局部语句草图与实际位置

主控 `always_ff`：IDLE 锁 body → WAIT_FREE 确认双方高 → START_HOLD 拉 SDA → LOW_FALL 先拉 SCL、看到低后才改变 SDA → BIT_LOW 保持数据 → BIT_RISE 等真实高 → BIT_HIGH 在末沿采样。TX 发八位后在第九位采样从机 ACK；读请求按 devW/regH/regL/repeated START/devR/八位数据/主机 NACK 执行。主机读末 NACK 是正常结束。`move` 清当前状态计时器，`error_cause` 保留首因，`stop_owned` 进入 STOP 过程。

STOP_LOW 确认实际低后拉 SDA，STOP_RISE 等实际高，STOP_HIGH 保持后释放 SDA，WAIT_RELEASE 连续双方高满足 tBUF 后才输出安全回复。发送逻辑 1 却看到 SDA=0 时释放两线，等待另一所有者释放，不插入 STOP。总线卡住或拥有事务时平台失效给 `QUARANTINE / drained=0`，消费通知和平台恢复都不解锁；只有共同安全复位可清隔离。

ROM 用一个官方 `EFX_RAM10` 的 512×20 布局；每项 24 位 `{reg16, data8}` 拆成两个字，地址 2i 为低 20 位，2i+1 为高 4 位，其余初始化为 0。父 ROM_LO/WAIT/ROM_HI/WAIT 四步取得同步读结果，再组成寄存器命令。写使能恒为 0。原表索引 0x90 的 stream-on 后还有 19 次写，全部保序，没有人为重排或编造 group hold。

父 `always_ff`：IDLE 锁任务并清本次结果 → WAIT_POWER 取得连续资格 → PREPARE 选 ID/ROM/VERIFY/STOP 阶段 → ISSUE 保持命令 → WAIT_REPLY 核完整 tag、真实 outcome/drained → 提交成功前缀或错误 → DONE 保持快照。`live_verified` 是独立的当前资格，平台失效可撤销它而不改已形成的终态快照。同沿取消与成功回复仍保留已经发生的传输计数，但不授予新资格。

## 4. 已实际执行的验证

`camera_fast_001`：主控 276 个用例，含 256 笔随机完整写/读的独立线事件核对，12 个错误、2 个取消、3 个隔离通知；配置层 43 个用例，5 次完整配置、28 个错误、5 个取消、3 个隔离。5 次完整配置共 900 笔事务逐笔与原表和公开字段核对。覆盖每个从机字节 NACK、延展、卡 SCL/SDA、仲裁、ID 错误、14 个读回字段逐项错误、SID=0x32、无关位变化、STOP、取消、平台反复变化、终态保持、tag 预算耗尽和安全复位后的恢复。

`camera_fullclock_001`：TB 实际时钟 100 MHz，参数上界 101 MHz；完整配置和 STOP 均通过。实际最短 SCL 低 5070 ns、高 5080 ns、START hold 5050 ns、STOP setup 5080 ns、总线空闲 10150 ns；电源资格到第一个 START 为 4045075 ns。独立参考核对 180 笔完整配置事务。两种运行均先证明 `$fatal` 以非零退出，检查全部源 SHA，并保存原始日志和外部总线 CSV。

`camera_map_001`：Efinity 2026.1 对 Ti60F225 / I3 实际综合成功，报告 1 RAM10、961 FF、1576 LUT4、82 ADD、0 DSP。没有综合警告。此组件没有执行板级布局布线、STA 或生成 bit；100 MHz 是综合目标，不是已经证明的板级 Fmax。

参考 `model/config_reference.py` 首先核对原表 SHA、连续 164 项、每个 RAM INIT 的物理位映射，再核对实际 S/A/W/R/M/P 线事件、全部地址/值/ACK、重复 START、主机 NACK、STOP 和公开字段 mask。测试参数减小计数并不代替生产参数测试，两个运行都保留真实标准模式最低时间。

## 5. 文件与追踪

13 份自写业务/验证输入：4 RTL、1 独立参考、1 表数据、3 TB/从机、2 脚本、2 Efinity 工程/约束。官方 RAM 模型单列为依赖，不算自写模块。运行向量、镜像、日志和审计辅助不重复计入源码数量。

SC01 身份/保持 → config 的 scope/command_tag/DONE → CT02/05/06；SC02 T4 → power_age/WAIT_POWER → CT05/07；SC03 原表/ACK/内容 → ROM/master/stage → CT01…04/07；SC04 停流 → STREAM_OFF_WRITE/READ → CT04…06；SC05 取消/未知 → STOP/WAIT_RELEASE/Q → CT03/05/06。由 RTL 顶部的 SC/CT 编号可反向回到设计卡与上述证据。

复现先用脚本新的 RunId 运行快速仿真、FullClock 仿真，再将通过且源摘要一致的运行名交给 MAP 脚本。脚本拒绝覆盖旧运行。此组件不自动下载或操作摄像头。

后续继续接入实际 CSI 解码输出、CDC/容量管理、帧闭合与生产平台；全工程仍需共享资源优化、显示/识别整合和一套生产 top 的引脚、布局布线、时序与 bit。没有实物观察，硬件结果和人工理解验收均未完成。
