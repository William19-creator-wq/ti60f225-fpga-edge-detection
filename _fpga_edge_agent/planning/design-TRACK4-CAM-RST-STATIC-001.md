# TRACK4-CAM-RST-STATIC-001：静态 RST 电平下的长时间相机身份探测

## A. 状态与阅读入口

- **任务 ID / 节点**：TRACK4-CAM-RST-STATIC-001；H2_CAMERA_STREAM 的诊断子任务。
- **设计版本 / 日期 / 阶段**：v1，2026-10-14，Claude Code 起草。**已批准（用户 2026-10-14 原话"批准 TRACK4-CAM-RST-STATIC-001 v1"），IMPLEMENTING。** 批准范围：建副本、按 C 节修改、至多 2 次编译；下载由用户操作。
- **所有权**：用户 2026-10-14 原话"交给你做"（对 Claude 关于"交给 Codex 还是交给我"的回答）。本任务由 Claude Code 在独立副本中进行，不修改 Codex 的任何目录。
- **目标**：在长时间、静态的 RST 电平下反复探测 SC431HAI 身份，同时让用户能用万用表测模组 TP1/TP2 是否跟随 RST，用来区分以下几种情况：
  - 模组 RST 极性相反；
  - 唤醒时间超过 20 ms；
  - RST 根本没有到达模组。
- **非目标**：
  - 不写相机配置，不采集图像；
  - 不改 HDMI/DDR 路径；
  - 不做慢速电平检查（那是 Codex 已批准的 TRACK4-CAM-BUS-LEVEL-001）；
  - 不改 REFINE-001。
- **基线**：Codex 的 `work/active/track4_camera_rst_compare_001_20261013`（RST-COMPARE v1）。
  - bit SHA256 `5F672543…198C`；
  - 源码已与交接包 claude_code_20261013_231816 比对，逐字节相同。
  - 拟建副本：`work/active/track4_cam_rst_static_001_20261014`，只复制源码、约束和工程文件，不复制 outflow、work_*、la*.vcd。
- **事实来源**：
  - 交接包 SUMMARY 与 evidence；
  - 复核 `handoff/claude_review_of_codex_20261013_231816.md`；
  - 观察记录 H2-I2C-PASSIVE-20261014-095931、H2-TP-VOLTAGE-*（TP1/TP2 对地约 55 kΩ；RST 低时电压约 0 V）。
- **阻塞项**：无。
- **下一项允许行动**：等待批准。

## B. 整体外部行为

| REQ | 要求 |
|---|---|
| REQ-1 | 上电并完成 PLL 锁定后，主板 RST（o_cam_rst_p，J4 第 6 脚）先保持低约 20 ms，然后进入"静态电平"。默认静态电平为**高**，此后一直保持，不自动恢复为低。 |
| REQ-2 | 进入静态电平后先等 0.5 s，然后每 1 s 进行一轮身份探测。每轮复用 Codex 的 camera_id_probe：内部再等 20 ms，然后依次读 0x30 和 0x32 的 3107/3108。轮与轮之间 I²C 两线都释放。 |
| REQ-3 | 短按 KEY3（A3，消抖约 20 ms）切换静态电平（高↔低）。切换时：两线立刻释放，当前一轮作废，"曾经应答"等记忆清零，重新从等 0.5 s 开始。 |
| REQ-4 | LED（亮 = 1）：<br>D0：DDR 校准心跳（不变）<br>D1：当前 RST 电平（亮 = 高）<br>D2：自上次切换以来 0x30 地址曾经应答过<br>D3：0x30 身份曾等于 CD6B<br>D4：0x32 地址曾经应答过<br>D5：0x32 身份曾等于 CD6B<br>D6：每完成一轮翻转一次（约 0.5 Hz 闪烁 = 探测在持续进行）<br>D7：曾出现总线故障（超时、仲裁失败、协议错误） |
| REQ-5 | 不向相机写任何寄存器。探测器只发"写寄存器地址 + 重复 START + 读 1 字节"的读事务（与 Codex 已运行的版本完全相同）。 |
| REQ-6 | SW0（KEY0，C4）沿用原工程：作为 PLL 复位。松开后整个监督逻辑重新从 REQ-1 开始。 |

**样例（正常）**：
- 上电后 D1 亮（RST 高），约 0.5 s 后 D6 开始以约 0.5 Hz 闪烁。
- 若这块模组在 RST 高时才运行，几秒内 D2 或 D4 亮，D3 或 D5 也亮。
- 此时用户测 TP1/TP2 电压，记录。

**样例（切换）**：按一次 KEY3，D1 灭（RST 低），D2–D5、D7 清零，D6 稍后继续闪。观察几秒，再测 TP1/TP2。

**样例（故障）**：
- 若 SDA 被外部一直拉低，探测器在 WAIT_FREE 阶段一直等待；10 ms 超时后 D7 亮，下一轮继续尝试。
- RST 电平始终保持在用户选定的值。

## C. 模块与连接

```text
w_arstn ─► camera_rst_static (新，替代 camera_reset_compare)
               ├─ rst_level 寄存器 ─► o_cam_rst_p (J4-6)
               ├─ KEY3 消抖 (key_press_debouncer，复用 REFINE-001 的同名模块)
               ├─ 轮次计时 + 每轮对 camera_id_probe 施加约 1 ms 复位
               │      └─ camera_id_probe (Codex 原样) ─ i2c_register_master (Codex 原样)
               │             └─ scl/sda_drive_low ─► 顶层 OE（OUT 固定 0，不变）
               └─ 记忆标志 / D6 翻转 ─► led[1..7]
```

| MOD | 改动 |
|---|---|
| camera_rst_static.sv | 新建，约 120 行，见 E 节 |
| ti60f225_oob_top.v | 实例名由 camera_reset_compare 改为 camera_rst_static；新增输入 key_rst_sel_n；led[1..7] 改接新输出 |
| ti60f225_oob.peri.xml | 新增 key_rst_sel_n：GPIOL_03（A3），3.3 V LVCMOS，输入，弱上拉 |
| ti60f225_oob.sdc | 对 key_rst_sel_n 加 set_false_path（异步按键，已在逻辑中同步） |
| ti60f225_oob.xml | 加入 camera_rst_static.sv 与 key_press_debouncer.sv；camera_reset_compare.sv 移出工程（文件保留） |
| camera_id_probe.sv、i2c_register_master.sv、sc431hai_profile_pkg.sv | 不改 |

## D. 接口与组合检查

- **IF1：w_arstn → camera_rst_static.arst_n**
  - 与原 camera_reset_compare 相同：异步置位，两级同步释放。
  - arst_n 为低时 o_cam_rst_p 输出高。这与原模块 `(!arst_n || supervisor_rst) ? 1 : rst_level` 的语义一致；配置或复位期间为高，与原工程上电行为相同。
- **IF2：camera_rst_static → camera_id_probe.arst_n**
  - 低有效，复用 Codex 的接法：`probe_arst_n = arst_n && 本轮运行`。
  - 探测器复位时其 drive_low 输出为 0（camera_id_probe 中 `scl_drive_low = arst_n && …`），两线立即释放。
  - 每轮复位保持约 1 ms（100,000 周期），远大于探测器两级同步所需的 2 拍。
- **IF3：探测器标志 → 记忆标志**
  - 在本轮 all_done 或 bus_fault 出现的那一拍采样，按位"或"进记忆寄存器；KEY3 切换时清零。
  - 探测器的 address/id 标志在 all_done 时已提交，与原 camera_reset_compare 的锁存时机相同。
- **IF4：drive_low → 顶层 OE**
  - 外加门控：`drive_low && probe_running && !switching`，保证切换和轮间释放。
- **时间预算**：
  - 每轮 1.0 s，其中探测最多约 252.5 ms（探测器自带 ROUND_LIMIT），轮间至少 0.74 s 空闲；
  - 每轮 I²C 流量极小，不会影响模组。

## E. 局部设计（中文操作草图，core_clk = 100 MHz，计数按 101 MHz 上界）

**状态**：INIT_LOW → WAKE → PROBE → GAP → PROBE …

**状态寄存器**：
- rst_level：上电值 1 = 高；KEY3 每次有效按下取反；
- wake_count（0.5 s）、round_count（1 s）、init_count（20 ms）；
- seen[6:0]：顺序为 {fault, id32, ack32, id30, ack30, —, —}；
- heartbeat。

**操作**：
1. 同步复位期间：o_cam_rst_p = 1；state = INIT_LOW；rst_level 保持上次的值（上电为 1）；seen 清零。
2. INIT_LOW：o_cam_rst_p 输出 0，持续 20 ms（2,020,000 周期），然后进入 WAKE。o_cam_rst_p 此后输出 rst_level。
3. WAKE：计满 0.5 s（50,500,000 周期）后，进入 PROBE，并释放探测器复位。
4. PROBE：等待探测器 all_done 或 bus_fault，或本轮超过 0.3 s（防挂死）。
   - 结束的那一拍：seen |= 标志；heartbeat 取反；探测器复位置为 1；进入 GAP。
5. GAP：从本轮开始算起满 1 s 后，回到 PROBE。
6. KEY3 有效按下（消抖后单脉冲）且不在 INIT_LOW：
   - rst_level 取反；seen 清零；探测器复位置为 1；进入 WAKE，wake_count 清零；
   - o_cam_rst_p 在同一拍改为新电平。
7. 输出：
   - led[1] = o_cam_rst_p 实际输出值；
   - led[2..5] = seen 中的 ack30、id30、ack32、id32；
   - led[6] = heartbeat；
   - led[7] = seen 中的 fault。

**不变量**：
- 探测器只在 PROBE 状态被释放复位；
- 进入 WAKE、GAP 或切换时，同一拍内撤销 drive_low 门控；
- o_cam_rst_p 只在 INIT_LOW 结束和 KEY3 切换两种事件时变化。

## F. RTL 契约要点

| 项 | 契约 |
|---|---|
| B 时钟 | 全部在 core_clk 域；KEY3 原始电平经 key_press_debouncer 两级同步 + 计数消抖（DEBOUNCE_CYCLES = 2,020,000，约 20 ms） |
| G 复位 | arst_n 为异步置位、同步释放 |
| E 门控 | drive_low 为组合门控，切换同拍生效，与 Codex 原模块做法相同 |
| I | 无存储 |
| K | 按键为唯一的异步输入，已同步 |
| L 资源 | 增加约 200 XLR，相对 v7 基线可忽略 |

## G. 实施与验证计划（未执行）

**实施步骤**：
1. 复制基线副本（不含产物），记录 SHA256 清单；
2. 新建 camera_rst_static.sv，从 REFINE-001 副本复制 key_press_debouncer.sv；
3. 改顶层、peri、sdc、xml；
4. 比对：只有计划内的文件变化；
5. 完整编译，至多 2 次；
6. 登记产物到 staging，状态停在 WAITING_HUMAN_PROGRAM。

**验证**：

| TEST | 内容 | 标准 |
|---|---|---|
| T1 | 文件差异 | 只有 C 节列出的文件变化 |
| T2 | 编译 | 综合、布局布线、bit 全部通过；时序全为正；pinout 相对基线只多 A3 一行 |
| T3 | 层次报告 | 有 camera_rst_static、camera_id_probe、i2c_register_master；无 camera_reset_compare |
| T4 | 用户上板，RST 高 | 观察 ≥10 s，记录 D1–D7；测 TP1/TP2 对 HDMI 外壳的电压 |
| T5 | 用户上板，RST 低（按一次 KEY3） | 同 T4 |

- 不新增仿真（沿用项目先前决定；ModelSim 许可受限）。新模块只在用户上板的 T4/T5 中验证，属于已知的证据限制。
- 判读按 J 节。

## H. 双向追踪

| REQ | MOD / 步骤 | TEST |
|---|---|---|
| REQ-1、REQ-6 | camera_rst_static：步骤 1–2 | T4 |
| REQ-2、REQ-5 | 步骤 3–5；camera_id_probe 原样 | T3、T4 |
| REQ-3 | 步骤 6；key_press_debouncer；peri 中的 A3 | T2、T5 |
| REQ-4 | 步骤 7；顶层 led | T4、T5 |

## I. 门槛

各项依据见 A–H。

**需要用户批准的内容**：
- 设计 v1；
- 创建副本 `track4_cam_rst_static_001_20261014`；
- 修改上列文件；
- 至多 2 次编译。

**下载由用户操作。**

## K. 实现与验证实录（2026-10-14）

- **副本**：`track4_cam_rst_static_001_20261014`，基线清单 `reports/TRACK4-CAM-RST-STATIC-001/baseline-copy.sha256`（152 个文件，与 Codex 源码一致）。
- **改动**：
  - 新增 `rtl/cam_id_probe/camera_rst_static.sv`；
  - 复制 `key_press_debouncer.sv`（来自 REFINE-001 副本）；
  - 修改顶层（端口 key_rst_sel_n、LED 接线、实例）、peri（A3）、sdc（false_path）、xml（入/出工程列表）。
  - T1 通过。
- **第 1 次编译失败**：综合 PASS；调试核插入时报 `No such file: work_compile\debug_top.v`。原因是调试核由 GUI 向导预生成并放在 work_dbg，而命令行用 --work_dir 改了位置。属于编译环境问题，与设计无关。
- **第 2 次编译通过**：
  - 修正方式：只改编译环境，复制 Codex work_dbg 中的 debug_top.v、stub 和 generated.json（探针配置相同），并按工程默认目录编译。
  - 结果：map/debugger/interface/pnr/pgm 全部 PASS；XLR 33,396；建立最差 +0.402 ns，保持最差 +0.012 ns，无负裕量。
  - T2 通过：pinout 相对基线只多 A3 一行。
  - T3 通过：层次中有 u_camera_rst_static、u_key、u_probe、u_i2c_master，没有 camera_reset_compare。
- **产物**：`artifacts/staging/TRACK4-CAM-RST-STATIC-001-B02`，bit SHA256 `6b964dcd…91fc`。
- **状态**：WAITING_HUMAN_PROGRAM；T4/T5 未运行。编译额度 2/2 已用完。

## J. 结果判读（供上板后使用）

| D1 = RST 高时 | D1 = RST 低时 | TP1/TP2 | 结论方向 |
|---|---|---|---|
| D2 或 D4 亮 | 不亮 | 高时约 1.8 V，低时 0 V | 本模组 RST 高才运行（与官方 v7 相反），或需要更长唤醒时间。可修正整机的 RST 逻辑 |
| 不亮 | D2 或 D4 亮 | — | 低才运行，但需要比 20 ms 更长的唤醒时间 |
| 都不亮 | 都不亮 | 随 RST 变化 | RST 送达了模组，问题在 I²C 线或传感器本体，转向慢速电平检查 |
| 都不亮 | 都不亮 | 始终 0 V | TP 与 RST 无关，或 RST 未送达；需要进一步查 RST 与 I²C 两条线 |
| D7 亮 | — | — | 总线时序异常（例如 SDA 被一直拉低），优先排查 |
