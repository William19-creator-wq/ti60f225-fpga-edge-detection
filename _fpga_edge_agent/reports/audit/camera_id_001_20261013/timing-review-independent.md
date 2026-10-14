# TRACK4-CAM-ID-001 v1 独立时序审查

日期：2026-10-13；审查者：board_connector_readonly。只读取已生成报告、约束及综合网表，未运行 STA/仿真/构建，未修改任何设计或配置。结论：最终报告已完成；在已分析约束范围内 setup/hold 无负裕量。未发现本次探针增量的时序阻塞；不把此结论扩展为全板所有异步/未约束路径签核。

## 报告完成证据

- `outflow/ti60f225_oob.timing.rpt`：报告日期 2026-10-13 18:23:54，文件修改时间 18:23:55，长度 1,683,006 字节；开始及结束两次读取长度/时间不变，尾部包含 `Path Details for Min Critical Paths (end)`。
- `outflow/ti60f225_oob.route.out`：明确包含 `Ending stage final timing analysis`，随后完成 LBF 写入并给出整个 EFX_PNR 的耗时。
- 本批 `06-pnr.log` 明确记录 `pnr : PASS`。未以历史 proj_state.ini 的 pass 字样替代本次日志。
- timing.rpt SHA256：`43E74AEC598C899E736174D5A9302E7814320B84D104B7270FC0F22E6BADF5BA`。

## 裕量

| 项目 | 结果 |
|---|---|
| 全报告最差 setup | +0.123 ns，tx_cal_clk → tx_cal_clk，DDR PHY ctl FIFO 的 raddr[0] CLK→CE 路径 |
| 全报告最差 hold | +0.012 ns，core_clk → core_clk，checker0/u_axi_rst_pip/dff_4/i1_2 CLK → n2498~FF_rt_0 D |
| core_clk 目标 | 10.000 ns / 100 MHz |
| core_clk 域最差 setup / hold | +4.802 ns / +0.012 ns |
| 已打印路径明细 | setup 151 条、hold 151 条；分别扫描 Slack 字段，负值均 0 |

报告时钟关系汇总同样未见负裕量。上述是工具已分析路径的结果；不是电气波形或相机成功通信的证明。

## 新探针与同步器覆盖

- `outflow/ti60f225_oob.dbg.map.v` 中识别到 189 个名称位于 `u_camera_id_probe/` 下的 EFX_FF，全部连接 `.CLK(core_clk)`；映射到顶层 led[1]–led[7] 名称的结果寄存器同样接 core_clk。
- 83046 行 scl_sync 的 D 接 scl_meta；83056 行 sda_meta 的 D 接 io_cam_sda_IN；83066 行 sda_sync 的 D 接 sda_meta；83265 行 scl_meta 的 D 接 io_cam_scl_IN。四个寄存器均保留 ASYNC_REG，均接 core_clk。
- 82974、84822 行 reset_release[0]/[1] 两级保留，异步低有效复位、core_clk 同步释放的映射与源码一致。
- 原 SDC 第15行对 core_clk 给出10ns约束。不存在 false_path、disable_timing、multicycle_path 对新模块/同步器进行豁免；同域 meta→sync 不属于不同组时钟之间的排除。
- 因此已有“综合网表同域连线 + 100MHz时钟约束 + 无相关豁免”的覆盖依据。现成 timing.rpt 只打印各关系最关键若干路径，没有新探针或这两条 meta→sync 的具体名字，故不能填造其逐路径数值裕量。本次未为此重跑定向 STA。
- `ti60f225_oob.cdc.rpt` 记录 No Synchronizer warnings to report；这是工具报告事实，不能替代异步输入到首级的电气或亚稳态完整证明。外部 SDA/SCL 无源同步 input-delay 契约，此限制在已批准设计中明确保留。

## 新增与继承告警

将本版和 CAM-DIAG v1 的 route.out 逐条读取并归一化工作目录后比较：

- 原版共548条 WARNING，本版553条；两版 CombinationalLoopDetected 均444条。重复计数不等于444个不同环。本批未修复既有切环，不能称全路径无例外。
- 非环去重告警原版100种、本版105种；原版100种均保留，没有其他新增种类。
- 唯一新增5种均由旧相机5MHz控制实例移除、CLK_5M输入闲置而来：No ports matched CLK_5M；SDC20 create_clock 无有效pin及无法执行；SDC26 CLK_5M组无匹配clock及该组无有效clock。新探针实际使用并约束于core_clk，不以这些闲置时钟告警宣称新增业务路径失约束。按设计保持SDC不改。
- 既有 JTAG/未使用DDR地址端口的未匹配约束和组合环警告继续存在，不归为本次新增。
- PT报告910行仍有 tmds_tx_clk 与 GPIOR_P_09/ddr_ck 邻近噪声警告。peri哈希未变，是继承的引脚布局限制。
- 未在本次告警日志发现 cam_id_probe 源的 latch/multiple-driver 告警。warn.log 的 audio_packet.sv:188 latch 来自未修改的旧 HDMI 音频源，不应写为本项目完全无 latch。

根任务继续负责最终资源预算、产物登记、下载授权核对与实物读灯。此报告不宣称摄像头图像或整机功能已经通过。
