# TRACK4-031-REFINE-001：031 副本的低风险修正与容量优化

## A. 状态与阅读入口

- **任务 ID / 关联节点**：TRACK4-031-REFINE-001；影响 A6_SHAPE_RECOGNITION（模式 5）、H2_CAMERA_STREAM（相机配置）、H1/H5 显示（HDMI 约束、帧标签 CDC）。
- **设计版本**：v0.1（2026-10-13，Claude Code 起草）。**当前阶段：v0.1 已获批并实现，B01 编译通过；B01 实物黑屏（REWORK_REQUIRED）；v0.2 修订（J2 节）READY_FOR_REVIEW，未批准。**
- **目标范围**：在 031 的独立副本上做 5 项不依赖实物观察的修正（C1–C5），把逻辑用量从 99.6% 降到约 74%，消除模式 5 的已知停机路径，补齐时序约束。
- **非目标**：不改按键/LED 引脚、Bayer 默认相位、CSI 时钟模式、DDR 读写流水化、摄像头帧率（见 J 节 Tier B，等 031 首测 M0 的现象再定）；不做可读性重排版；不新增 testbench；不改 031 原目录；不生成 bit 以外的硬件操作。
- **在整体系统中的位置**：只动 algorithm_actor 内部的识别后处理、CSI IP 参数、相机初始化表、显示模块的一个同步器和 SDC。采集→Canny→发布→显示的主链路和全部外部接口不变。
- **来源（事实）**：2026-10-13 对 031 的只读审查（本会话）；031 报告 `outflow/track4_board.hier_util.rpt`、`timing.rpt`、`pt.sdc`；SC431HAI 数据手册 V1.1 §2.4.2（曝光上限 2×VTS−11，VTS 默认 0x05DC）；`planning/GOALS_AND_CONSTRAINTS.md` §3（A6 只做官方简易识别，用户 2026-10-12 确认）。
- **基线**：
  - 原版：`work/active/track4_board_debug_031_20261011`（只读，不修改；bit SHA256 `77216940…9951`）。
  - 副本：`work/active/track4_board_refine_from031_20261013`（2026-10-13 创建，205 个文件，与 031 源文件逐字节一致，不含 outflow/work_*/ooc）。
  - 基线清单：`reports/TRACK4-031-REFINE-001/baseline-copy.sha256`，清单本身 SHA256 `cb774e28df14e262ea90b6f323536190eb515ded2eb61da0ad0bf987e5a86598`。
  - Windows ASCII 路径等价：`C:\Users\34528\FPGAEdgeLinks\Work\active\track4_board_refine_from031_20261013`。
- **阻塞项**：无影响 C1–C5 正确性的阻塞。尚需用户决定的是批准本身、D8（源码所有权）、构建授权（见 I 节）。
- **批准状态**：未批准。副本创建依据：用户 2026-10-13 原话"你能建立一个副本, 重构优化一下代码吗?"——仅视为创建未修改副本的授权，不视为修改或编译授权。
- **其他审批**：APPROVAL_MANIFEST 中 `create_or_modify_work_copy_rtl`、`modify_constraints`、`modify_efinity_project`、`run_efinity_build`、`copy_artifact_from_efinity_output` 均需人工批准；PostgreSQL 未配置，本任务只做控制面本地记录，不写正式数据库或 PROJECT_STATE。
- **下一项允许行动**：等待用户批准 v0.1 及范围；批准前只允许只读检查和修订本文档。

## B. 整体外部行为

| REQ | 要求 | 来源 |
|---|---|---|
| REQ-001 | 模式 0–4 的可见行为（画面内容、按键响应、冻结、故障指示）与 031 相同 | 派生：本任务只做修正，不改功能 |
| REQ-002 | 模式 5 仍显示最多 4 个圆/矩形框和 C/R 字母，判别规则与 031 相同；不再运行未上屏的 POINT/统计/拟合/锚点数值链，因而不会因该链（含已知 POINT 末包缺陷）进入整机故障 | 用户确认的 A6 范围；031 已知限制 |
| REQ-003 | CSI 接收对 RAW10（4 像素/40 位）输出与 031 相同；去掉不会用到的 48/56/64 位解包器 | 派生：资源 |
| REQ-004 | 相机曝光寄存器值不超过数据手册上限（VTS=1500 时 ≤ 2989） | 数据手册；审查发现 031 为 7103 |
| REQ-005 | 显示读出每帧锁定的帧标签与视频端当前标签一致，不出现多位跨时钟采错 | 派生：审查发现 |
| REQ-006 | HDMI TMDS 输出和摄像头 MIPI 数据通道的核心↔I/O 路径纳入静态时序分析，且全部满足 | 派生：审查发现 031 漏约束 |
| REQ-007 | 编译结果：XLR ≤ 60,531（D3），建立/保持时间全部为正；同一目标最多 2 次编译尝试 | D3（用户已确认） |
| REQ-008 | 031 原目录、原 bit 不变；副本与基线的差异只限于下表 C1–C6 列出的文件 | 项目规则 |

**样例（正常）**：上电默认模式 4，镜头前放黑线纸。期望：与 031 相同，彩色画面叠加红色 Canny 边缘；KEY0 加阈值后边缘减少。理由：模式 4 的任务中 `gradient_enabled=0`，被移除的模块在 031 中本来就不参与。

**样例（边界）**：切到模式 5，镜头前放 1 个圆、1 个矩形，停留 60 秒。031 预期：可能因 POINT 末包未补零触发格式故障，`quarantined` 置位，LED1 常亮，采集永久停止。本版本预期：持续刷新框和 C/R，不进入故障。理由：数值链不再存在，`result_commit_barrier` 恒为真，框来自 `board_shape_tracker`（未改）。

**失败场景**：新增 TMDS/MIPI 约束后 STA 在这些路径上出现负裕量。期望：不得通过放宽约束掩盖；停止并报告具体路径，这同时说明 031 也存在该隐患。

**生命周期**：复位、启动、冻结、模式切换规则全部沿用 031，不变。

## C. 模块职责与整体连接

```text
相机 ─MIPI→ [CSI RX IP]──RAW10──→ board_frame_system ──AXI──→ DDR3
              C2: PACK_TYPE           │  采集 actor（不改）
                                      │  algorithm_actor = board_algorithm_rpc
                                      │     ├ Canny / Sobel 主链（不改）
                                      │     ├ grad 流 ─IF-GRAD→ board_shape_tracker（不改，模式5的框）
                                      │     └ C1: 删除 gradient_store / points / stats / anchors / gradient_memory_port
                                      └ board_frame_display ─video→ HDMI 编码器
                                            C5: 帧请求翻转同步 2→3 级
I²C ROM（C4: 曝光）    SDC（C3: TMDS + MIPI I/O 约束）
```

| MOD | 改动 | 承担 REQ | 不负责 |
|---|---|---|---|
| MOD-C1 `board_algorithm_rpc` | 移除 4 个识别数值模块实例和 1 个仲裁器实例，Canny 访存口直连 | REQ-001/002/007 | 不改 Canny、Sobel、shape tracker |
| MOD-C1x `track4_board.xml` | 从工程列表移除 15 个只服务于数值链的文件 | REQ-007/008 | 文件留在磁盘，不删除（用户"保留不删除"） |
| MOD-C2 `rtl/csi_rx_controller.sv` | 包装层参数 `PACK_TYPE` 15→1 | REQ-003 | 不改时钟模式/字节时钟（Tier B） |
| MOD-C3 `track4_board.sdc` | 补 24 行 TMDS 与 32 行 MIPI RX I/O 延迟；`hdmi_tx_fast_clk` 用模板波形 | REQ-006 | 不改时钟分组 |
| MOD-C4 `i2c_master_reg_rom.v` | ROM 0x73–0x75 曝光恢复为 {0x00,0xBA,0xD0} | REQ-004 | 不改增益 0x3E08/09、镜像翻转 0x3221 |
| MOD-C5 `board_frame_display` | 请求翻转同步器 2→3 级，用第 3 级判定新请求 | REQ-005 | 不改显示时序和像素路径 |
| MOD-C6 文档 | README、handoff.json 更新为本版本说明 | REQ-008 | — |

复用依据：全部为 031 已编译通过的现有代码；C2 的 `PACK_TYPE=1` 映射已由同目录 `ip/csi_rx_controller`（IP 5.16，仅勾选 Pack_40）生成的包装层核实。

**C1 移除文件（工程列表，15 个）**：`board/recognition_numeric/` 下 11 个（fit_protocol_pkg、scalar_protocol_pkg、scalar_bridge、scalar_core_words、fit_core、stats_protocol_pkg、stats_core、angle_protocol_pkg、angle_math、angle_rom、angle_core），加 `board/rtl/` 下 board_recognition_stats、board_recognition_anchors、board_gradient_store、board_recognition_points。
**必须保留**：`board_native_rpc_arbiter2.sv`，它仍被 `algorithm/deps/canny_memory_join/rtl/line_rpc_arbiter2.sv` 使用（已 grep 核实）。

## D. 接口与组合设计检查

- **IF-ALG（board_algorithm_rpc 对外端口）**：端口表不变（含 `gradient_base`，改后不再使用，保留以免改动上层）。语义变化只在 `job_cj[141]=1`（模式 5）的任务：
  - `done_valid` 不再等待数值链，等于 Canny 的 `c_done_valid`；
  - `outcome`/`reason`/`quarantined`/`producer_local_quarantined` 不再并入 gradient/point/stats/anchor/rpc 五个故障；
  - 不再写 DDR 0x04000000 起（gradient）、0x05000000（POINT）、0x06000000/0x06001000（stats/anchor）。
  - 上游 `board_frame_system` 只消费 done/outcome/quarantined/grad，均保持握手协议；检查通过。
- **IF-GRAD（grad 流 → shape tracker）**：`grad_valid` 由 `c_grad_valid && (!gradient_enabled || gradient_input_ready)` 变为 `c_grad_valid`，`canny_grad_ready` 变为 `grad_ready`。模式 0–4 中 031 的 `gradient_enabled` 本就为 0，表达式等值；模式 5 中去掉了"存储端满时一起停"的约束，tracker 的 valid/ready 握手不变。检查通过。
- **IF-MEM（Canny 访存 → video_memory_hub）**：原为 Canny → `board_native_rpc_arbiter2`（a 口）→ hub；改为直连。
  - 原仲裁器在单调用方时只增加一个 IDLE→OFFER 周转（每次访存多 1 拍），`a_drained` 在 REPLY 阶段等于 `drained`。
  - hub 在 valid&&ready 同拍接收、不锁存未接收的请求，对 valid 撤回无副作用。
  - 直连后功能等价，每次访存少 1 拍；去掉 rpc_fault（原来只在"无请求却来回复"或 drained=0 时置位，这两种情况由 hub/Canny 自身的检查覆盖）。检查通过。
- **IF-CSI**：`pixel_data[39:0]` 的 RAW10 打包与 `PACK_TYPE` 中 bit0 对应；031 顶层只用 `[39:0]`。只要相机数据类型为 RAW10，输出不变。相机若输出其他格式，031 本来就无法正确处理，因此不引入新的不兼容。
- **IF-DISP-CDC**：视频域在同一边沿翻转 `request_toggle` 并递增 `request_tag`。核心域原 2 级同步：看到翻转的同一时刻，`tag_sync` 可能是边沿上采到的混合值。改为 3 级后，看到翻转时 `tag_sync` 已经过至少一个"标签已稳定"的采样边沿，必为新值（逐沿推导见 E.5）。延迟增加 1 个核心周期（11 ns），而一帧提前量为 41 行，无影响。
- **整体资源（估计，来自 031 报告，非实测）**：
  - C1 约 −15,045 XLR、−29 RAM10、−10 DSP；C2 约 −599 XLR；
  - 预计总量约 44,900/60,800 ≈ 74%，满足 REQ-007；
  - 实际以新编译报告为准。
- **端到端走查（模式 5）**：采集完成 → A_JOB（job_cj[141]=1）→ Canny 产生 grad 流 → tracker 统计 → Canny done → `done_valid`（不再等数值链）→ board_frame_system 等待 `shape_finished` → save_shapes → 下一视频帧发布。各交接仍是原 valid/ready 规则，无新缓存或反馈环。

## E. 局部详细设计（中文操作草图）

**E.1 MOD-C1 board_algorithm_rpc**

- 删除寄存器 `gradient_enabled`、`point_started`、`stats_started`、`locked_gradient_base`、`locked_edge_base`。接单时只保留 `busy<=1; selected<=sobel_mode`。
- `job_ready` = `!busy && (choose_sobel ? s_job_ready : c_job_ready)`，去掉四个 `*_start_ready` 条件。
- `done_valid` = `(choose_sobel ? s_done_valid : c_done_valid)`，即 `result_commit_barrier` 恒为真。传给 Canny 的 `done_ready` 直接是 `done_ready`。
- `outcome`、`reason` 直接选 `choose_sobel ? s_* : c_*`。
- `quarantined`、`producer_local_quarantined` 去掉数值链和 rpc_fault 的五个"或"项。
- 访存直连：`algorithm_req_valid/write/addr/wdata` 取自 core_*；`core_req_ready = algorithm_req_ready`；`core_rsp_valid = algorithm_rsp_valid`；`algorithm_rsp_ready = core_rsp_ready`；`core_drained = algorithm_drained`。
- 删除实例：gradient_store、recognition_points、recognition_stats、anchors、gradient_memory_port，以及只为它们声明的连线。
- 不变量：任一时刻只有一个任务占用（busy），done 被消费后才可接下一单。与 031 相同。

**E.2 MOD-C2**：`.PACK_TYPE (15)` → `.PACK_TYPE (1)`。其余参数一字不改。

**E.3 MOD-C3**：在 SDC 末尾追加。
- 复制本次界面生成（interface designer）产出的 `outflow/track4_board.pt.sdc` 中 `tmds_tx_*` 的 24 行与 `cam_d[0-3]_*` 的 32 行；
- 把 `hdmi_tx_fast_clk` 的 create_clock 改成模板中的 `-waveform {0.337 1.010} -period 1.347`；
- 先比对新 pt.sdc 的 `-reference_pin` 名称与 031 的是否一致（外设位置未改，预期一致）。不一致时以新 pt.sdc 为准，并记录。

**E.4 MOD-C4**：ROM[0x73]={0x3e00,0x00}、ROM[0x74]={0x3e01,0xBA}、ROM[0x75]={0x3e02,0xD0}，即 031 原厂值。曝光 = {3e00[3:0],3e01,3e02[7:4]} = 0x0BAD = 2989 = 2×1500−11。`DATA_LENGTH`、写入顺序不变。

**E.5 MOD-C5 逐沿说明**

设视频沿 t0 同时改变 toggle 与 tag，k 为 t0 后第一个核心上升沿。
- 最坏情况：k 沿 toggle 已采到新值，而 tag 各位是混合值。
- k+1 沿：tag_meta 得到稳定新值（tag 在 k 之后不再变化）。k+2 沿：tag_sync 得到新值；同时 request_sync[2] 首次为新值。
- k+3 沿：IDLE 分支锁存 tag_sync，得到新值。若 toggle 晚一沿才被采到，各事件顺延，结论不变。
- 改动只有两处：把 `request_sync` 由 2 位改 3 位；`requested` 用 `request_sync[2]`，`request_seen<=request_sync[2]`。复位方式不变（与原 2 级相同的异步复位）。

## F. 语言契约（RTL，§8.2）

| 项 | 本任务契约 |
|---|---|
| A 数值 | C1/C5 不改任何数值运算；C4 只改常量 |
| B 时钟 | C1 全在 core_clk；C5 属 video_clk→core_clk 的 CDC，见 K |
| C 接受/交付 | IF-MEM 仍以 valid&&ready 同拍为接收事件；hub 不要求请求保持，但 Canny 侧在 031 中已保持 |
| D valid | 未改 |
| E 反压 | 模式 5 中 grad 流去掉存储端反压，tracker 的反压仍有效 |
| F 延迟 | IF-MEM 每次访存少 1 拍；C5 帧请求识别晚 1 个核心周期 |
| G 复位 | 未改：core 同步复位 rst，C5 同步器沿用 safe_reset_n 异步复位 |
| H 配置 | 阈值、模式、Bayer 相位的采样边界未改 |
| I 存储 | 去掉 DDR 0x04000000–0x0600xxxx 区段的写入；其余地址图不变 |
| J 身份 | 帧标签一致性由 C5 加强；坐标、帧号未改 |
| K CDC | C5：单比特翻转 3 级同步 + 多位标签只在其稳定后被采用（E.5） |
| L 实现 | Efinity 2026.1.132，Ti60F225/I3，core_clk 90.909 MHz；资源见 D |

C++/跨语言：N/A，本任务不涉及软件模型。

## G. 实施及验证计划（尚未执行）

**实施顺序**（全部只在副本中）：
1. C1：board_algorithm_rpc，并从工程 XML 移除 15 个文件。
2. C2、C4、C5。
3. C3：在首次界面生成后，比对 pt.sdc 再追加约束。
4. C6：更新文档。
5. 用基线清单比对，确认只有计划内文件变化。
6. 读取 `skills/fpga-hardware-node-gate/SKILL.md`，按 031 相同方式完整编译（综合、界面生成、布局布线、STA、bit/hex）。
7. 计算哈希，登记到 `artifacts/staging/`，状态停在 WAITING_HUMAN_PROGRAM。

停止条件：同一目标连续 2 次编译失败，或 XLR > 60,531（D3）。

| TEST | 目标 | 方法 | 通过标准 | 状态 |
|---|---|---|---|---|
| T1 | REQ-008 | 新旧 SHA256 清单比对 | 仅 C1–C6 列出的文件不同 | 未运行 |
| T2 | REQ-007 | Efinity 完整编译 | 无错误；XLR ≤ 60,531；建立/保持全部为正 | 未运行 |
| T3 | REQ-006 | 时序报告中搜索 tmds/cam_d 路径 | 路径被分析且裕量为正 | 未运行 |
| T4 | REQ-002/003 | hier_util.rpt | 不再出现 recognition_*/anchors/gradient_store、depack48/56/64；shape tracker 仍在 | 未运行 |
| T5 | 综合警告 | 与 031 warn.log 分类对比 | board_algorithm_rpc 无新增"无驱动/截断/未连接"类警告（gradient_base 未用除外） | 未运行 |
| T6 | REQ-001/002/004/005 | 用户上板（在 031 首测之后） | 模式 0–4 与 031 观察一致；模式 5 停留 60 s 不进入故障且有框；画面亮度正常、无过曝；无偶发整帧黑 | 未运行 |

不新增仿真：ModelSim 许可受阻（环境验收记录），且用户 2026-10-12 前已决定本批次不新增独立测试。因此 REQ-001 的"模式 0–4 等价"依靠 E.1 的逐项推导和 T6 实物观察，属于已知证据限制。

## H. 双向追踪

| REQ | MOD | IF/草图 | 计划文件 | TEST | 实际代码 | 证据 |
|---|---|---|---|---|---|---|
| REQ-001 | C1 | IF-ALG/IF-MEM，E.1 | board/rtl/board_algorithm_rpc.sv | T2,T5,T6 | 待实现 | 未运行 |
| REQ-002 | C1, C1x | IF-ALG/IF-GRAD，E.1 | 同上；track4_board.xml | T4,T6 | 待实现 | 未运行 |
| REQ-003 | C2 | IF-CSI，E.2 | rtl/csi_rx_controller.sv | T4 | 待实现 | 未运行 |
| REQ-004 | C4 | E.4 | rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v | T6 | 待实现 | 未运行 |
| REQ-005 | C5 | IF-DISP-CDC，E.5 | board/rtl/board_frame_display.sv | T6 | 待实现 | 未运行 |
| REQ-006 | C3 | E.3 | track4_board.sdc | T2,T3 | 待实现 | 未运行 |
| REQ-007 | 全部 | D 资源 | — | T2 | 待实现 | 未运行 |
| REQ-008 | C6 | — | README.md、handoff.json | T1 | 待实现 | 未运行 |

## I. 设计门槛与评审

1. 整体行为及样例：B 节。
2. 职责与连接、复用调查：C 节。
3. 接口与相容检查：D 节。
4. 局部状态与草图：E 节。
5. 语言契约：F 节。
6. 走查与覆盖：D 末、H 节。
7. 计划、验证与追踪：G、H 节。
8. 无当前阻塞：Tier B 已隔离到 J 节。
9. 已保存并读回：本文件。
10. 版本、范围、基线：A 节。

**READY_FOR_REVIEW v0.1，2026-10-13。停止点：等待用户批准本版本、范围（C1–C6）和基线（cb774e28…），以及至多 2 次 Efinity 编译。没有批准不改副本代码。**

需要用户回答：
1. 是否批准 v0.1 的 C1–C6（可删减某一项）。
2. D8：确认本副本只由 Claude Code 修改，Codex 不碰此目录。
3. 是否授权运行编译并登记产物（APPROVAL_MANIFEST 的 run_efinity_build / copy_artifact_from_efinity_output）。
4. D2：本版本在实物通过前不取代 031 作为交付基准（建议保持）。

批准记录：

- 2026-10-13，用户聊天原话："批准 TRACK4-031-REFINE-001 v0.1，范围 C1–C6，允许编译至多6次"。
- 批准对象：设计 v0.1（文件 SHA256 `8df579c2…59fa`），范围 C1–C6，基线 `cb774e28…a86598`。
- 编译上限：至多 6 次。这是用户对本任务的明确授权，替代 D3 中"连续 2 次失败即停"的默认值；"XLR ≤ 60,531"的门槛不变。
- 未答复事项：
  - D8：按默认处理，即本副本只由 Claude Code 修改；该目录是新建的，不是 Codex 的开发目录。
  - D2：按默认处理，即实物通过前 031 仍是交付基准。
- 状态：APPROVED_FOR_IMPLEMENTATION → IMPLEMENTING。正式数据库和 APPROVAL_MANIFEST 未写入（PostgreSQL 未配置），本记录为控制面本地记录。

## J. 变更与恢复：Tier B（本版不做，等 M0 现象）

| ID | 内容 | 触发证据 |
|---|---|---|
| B-1 | KEY1/KEY2 ↔ LED0/LED1 引脚对调 | 首测时 D0、D1 常亮不闪（说明书一派正确） |
| B-2 | Bayer 默认相位 | 颜色或棋盘格异常，且 KEY0+KEY2 试出正确相位 |
| B-3 | CSI 时钟模式改回 Continuous / 字节时钟参数 | 有 HDMI 信号但从无画面，且 DDR 校准正常 |
| B-4 | 写通道不等待 B 响应、允许多笔在途 | 采集溢出导致故障（LED1 常亮且从未出图） |
| B-5 | 显示读出预取下一行 / 允许两笔读在途 | 下半屏发黑或闪烁 |
| B-6 | 降低相机帧率（VTS） | 实测相机帧率过高、采集跟不上 |
| R-1 | 板级胶合模块（board_frame_system/display）可读性重排与注释，供讲解 | C1 编译成功、容量降到约 74% 之后，另立设计 |

## J2. 设计修订 v0.2（2026-10-13，READY_FOR_REVIEW，未批准）

**触发证据**（观察记录 `observations/structured/REFINE001-B01-20261013-164307.json`）：

1. 用户烧录 B01 后黑屏，显示器无分辨率提示，也无无信号/待机提示。031 此前的表现是：先识别分辨率，之后无信号、待机，全程无画面。官方 HDMI 彩条正常。
2. 官方 v7 工程只驱动 `led[0]=GPIOR_27 (P13)`，逻辑为 cal_done 后闪烁；用户实见 D0 持续闪烁。结论：P13 物理上是 D0 指示灯。说明书 p.32–33 表格正确，原理图文字层配对不适用于实板。
3. B01 与 031 的 peri.cdo 逐字节相同，HDMI 相关硬件配置一致，因此问题不是 C1–C5 引入的。

**根因推断**（未经实物验证）：031 和 B01 的 `i_arstn` 接在 P13。P13 实际连 D0 三极管基极（100 kΩ），输入只靠内部弱上拉，电平落在阈值附近。四个 PLL 的 RSTN 都等于 `i_arstn`，读成 0 或抖动时，HDMI 时钟及全部逻辑都被复位。

**v0.2 改动（B-1，仅 track4_board.peri.xml）**：

| 信号 | 031/B01 | v0.2 | 依据 |
|---|---|---|---|
| i_arstn（复位键） | GPIOR_27 (P13) | **GPIOR_22 (P14) = KEY1** | 说明书表格；01 key demo |
| key_dec_n | GPIOR_24 (N13) | **GPIOR_21 (N14) = KEY2** | 同上 |
| led[0]（cal_done 闪烁） | GPIOR_21 (N14) | **GPIOR_27 (P13) = D0** | v7 实测 |
| led[1]（冻结/故障） | GPIOR_22 (P14) | **GPIOR_24 (N13) = D1** | 说明书表格 |

- 四个引脚都在 BR bank、3.3 V LVCMOS，电压与 bank 不变；输入保留弱上拉，输出驱动强度 4 不变。
- RTL、SDC 不变（SDC 已对这四个端口设 false_path，或它们本就无时序约束）。
- 按键物理位置不变：KEY0 加阈值、KEY1 复位、KEY2 减阈值、KEY3 模式/冻结。

**可选 B-7（默认不做，需用户另外勾选）**：在第一帧发布之前，显示灰色或彩条测试图，而不是全黑。用来区分"HDMI 正常但摄像头无帧"和"HDMI 失效"。需改 board_frame_display，并增加 1 个跨时钟电平同步。

**验证计划**：
- V2-T1：pinout.csv 中仅这 4 行与 B01 不同；
- V2-T2：编译通过，XLR ≤ 60,531，时序全部为正；
- V2-T3（用户上板）：
  - 显示器识别 1920×1080@60，保持 ≥5 分钟不掉成无信号；
  - D0 在 DDR 校准后闪烁，D1 熄灭；
  - 短按 KEY1 后 HDMI 短暂断开再恢复。
  - 摄像头链路另行判定：官方 v7 也未取景成功，因此 v0.2 预期可能是"有信号、黑画面"。

**编译**：+1 次，累计 2/6。

**停止点**：等待用户批准 v0.2 的范围（B-1，是否加 B-7）。

**批准记录**：2026-10-13，用户原话"批准 v0.2 B-1"。
- 范围：只做 B-1（peri.xml 中 4 个引脚对调），不做 B-7。
- 基线：B01 源码清单 `after-refine-sources.sha256`（a226ae29…dbb7）。
- 编译额度沿用 v0.1 的 6 次授权，本次为第 2 次。
- 状态：APPROVED_FOR_IMPLEMENTATION → IMPLEMENTING。

## J3. 设计修订 v0.3：PLL/复位状态诊断灯（2026-10-13，READY_FOR_REVIEW，未批准）

**触发证据**：用户烧录 B02 后，D0、D1 都不亮，显示器无分辨率提示。

**推断**（未证实）：
- D0 = `cal_done ? cnt[24] : 0` 不亮，且 HDMI 无同步。两者共同的上游是 `w_arstn = i_pll_locked & pll_locked & user_pll_locked & pll_inst4_LOCKED`，以及 `i_arstn`。
- 与可用的官方 v7 相比，031 新增了三处：pll_inst4 的复位/锁定脚（锁定信号并入 w_arstn）、pll_inst4 的 clk_100m 输出（作 DDR 核心时钟）、MIPI_TX_PLL 改用独立反馈时钟并把 core_clk 改为 90.9 MHz。
- 静态无法判定是哪个 PLL 未锁定，或是否根本没有配置成功。

**v0.3 改动（仅诊断，不改任何现有功能）**：

1. track4_board.peri.xml：新增 led[2]–led[7] 六个输出，均为 1.8 V LVCMOS、驱动强度 4、无寄存器，引脚沿用官方 01 key demo 与 v7 的 LED 引脚。led 总线由 [1:0] 改为 [7:0]。
2. ti60f225_oob_top.v：`output [1:0] led` 改为 `[7:0]`，新增 6 条组合赋值（直接输出，不经任何时钟）：

| 灯 | 引脚 | 信号 | 正常应 |
|---|---|---|---|
| D2 | G3 / GPIOL_P_12 | i_arstn（KEY1 原始电平） | 亮；按住 KEY1 时灭 |
| D3 | N2 / GPIOL_P_02 | user_pll_locked（HDMI PLL） | 亮 |
| D4 | G4 / GPIOL_N_12 | i_pll_locked（MIPI_TX_PLL，产生 core_clk） | 亮 |
| D5 | E1 / GPIOL_P_15 | pll_locked（DDR3_PLL） | 亮 |
| D6 | E2 / GPIOL_N_15 | pll_inst4_LOCKED | 亮 |
| D7 | M2 / GPIOL_N_02 | w_arstn（四个锁定的"与"） | 亮 |

3. D0/D1 含义不变。
4. 用途：根据亮灭直接看出卡在哪一级。D2 灭表示复位键电平问题；D3–D6 中哪颗灭就是哪个 PLL 没锁；全部不亮表示 FPGA 没有配置成功。
5. 不改 SDC：这 6 个输出无时钟，不进入时序分析。

**验证计划**：
- V3-T1：pinout 与 B02 相比只多 6 行 led[2..7]；
- V3-T2：编译通过，XLR ≤ 60,531，时序全部为正；
- V3-T3：用户上板，报告 D0–D7 各自的状态。

**编译**：+1 次，累计 3/6。

**后续**：根据 V3-T3 的读数，另行提出修复方案（v0.4），届时再请批准。

### J3 修订：v0.3（第 2 稿，2026-10-13，取代上面仅诊断的第 1 稿，READY_FOR_REVIEW，未批准）

**新增证据**（Codex 交接包 claude_code_20261013_231816 及其复核 `handoff/claude_review_of_codex_20261013_231816.md`）：

- 官方 v1/v6/v7 的 pll_inst4 都没有复位/锁定脚。031 的 pll_inst4 锁定并入 w_arstn、clk_100m 作 DDR 核心时钟、MIPI_TX_PLL 改用独立反馈，这三处都是 031 自加，没有任何实测依据。
- 031 的复位/LED 引脚与官方 v6 相同，v7 已改正（B-1 已改）。
- 相机 I²C 首地址无 ACK，相机链路短期内不会出帧。本设计只在第一帧发布后才输出图像，所以就算 HDMI 好了也是黑屏，无法单独验收 HDMI。

**v0.3 第 2 稿范围**：

1. **(a) 时钟结构恢复为官方 v7 的实测可用形式**
   - peri.xml：pll_inst4 去掉 reset_name/locked_name，删除 clk_100m 输出（保留 i_mipi_rx_pclk、CLK_5M）；MIPI_TX_PLL 删除 mipi_feedback_100m，反馈改为 core_clk，core_clk 分频 22→20（100 MHz）。DDR3_PLL、USER_PLL 不变。
   - 顶层：`w_arstn = i_pll_locked & pll_locked & user_pll_locked`；删除 pll_inst4_RSTN、pll_inst4_LOCKED、clk_100m 端口；ddr3_top.core_clk 改接 core_clk（与官方相同）。
   - SDC：core_clk 周期 11→10 ns；删除 clk_100m；core_clk 与 DDR 400 MHz 时钟设为异步组（同官方 SDC）。
   - 时序依据：B02 的 core_clk 在 11 ns 下裕量 +1.854 ns，路径约 9.15 ns，估计 10 ns 下仍为正（以实际编译为准）。
   - 板级常数：消抖 5 ms、长按 0.2 s，随时钟变化可接受。
2. **(b) 诊断灯**：沿用第 1 稿的 D2–D7，只有 D6 改为 vid_rst_n（亮 = HDMI 编码器已解除复位），因为 pll_inst4 不再有锁定信号可显示。
3. **(c) 无帧测试图（原 B-7）**
   - board_frame_display 的视频端：在第一帧发布之前，或 has_frame 为 0 时，输出 8 色竖条，代替黑色。
   - has_frame 由核心域经两级同步传到视频域。它是单比特电平，只在启动和故障时变化。
   - 有帧之后的行为与现在完全一致。

**验证计划**：
- 编译通过，XLR ≤ 60,531，时序全部为正，引脚表只有预期变化。
- 用户上板：
  - 显示器识别 1080p60，并出现竖条测试图；
  - D0 闪烁，D2–D5 和 D7 亮；
  - 观察 5 分钟不掉线。
- 相机链路不在本版验收范围内。

**编译**：+1 次，累计 3/6。

**停止点**：等待用户批准 v0.3 第 2 稿（可删去 (b) 或 (c)）。

## K. 实现与验证实录

2026-10-13，Claude Code。

**实际修改**（副本 `work/active/track4_board_refine_from031_20261013`）：

- **C1**：board_algorithm_rpc.sv 从 467 行减到 390 行。
  - 删除寄存器 gradient_enabled/point_started/stats_started/locked_*；
  - 删除 gradient_store/recognition_points/recognition_stats/anchors/gradient_memory_port 五个实例；
  - job_ready/done_valid/outcome/reason/quarantined/producer_local_quarantined 按 E.1 简化；
  - Canny/Sobel 实例的 done_ready、grad_ready 直接接上层；
  - 访存口按 E.1 直连。
  - track4_board.xml 的源码入口从 124 减到 109（移除 15 个文件，board_native_rpc_arbiter2.sv 保留）。
- **C2**：csi_rx_controller.sv 第 143 行 `.PACK_TYPE (1)`。
- **C3**：SDC 的 hdmi_tx_fast_clk 改用 `-waveform {0.337 1.010} -period 1.347`；末尾追加 24 行 tmds_tx_* 和 32 行 cam_d[0-3]_*，均来自 031 的 pt.sdc。
- **C4**：ROM 0x73–0x75 改为 {00,BA,D0}。
- **C5**：request_sync 改为 3 位，requested 和 request_seen 改用 [2]。
- **C6**：README.md、handoff.json 重写，在编译之后完成，不影响 bit。
- 所有文件保持 CRLF。修改后的源文件清单：`reports/TRACK4-031-REFINE-001/after-refine-sources.sha256`（SHA256 `a226ae29…dbb7`）。

**检查结果**：

| TEST | 结果 | 证据 |
|---|---|---|
| T1 | 通过。相对基线只有 8 个计划内文件不同（C1–C5 涉及 6 个，C6 涉及 2 个） | baseline-copy.sha256 与 after-refine-sources.sha256 对比 |
| T2 | 通过（第 1 次编译）。map/interface/pnr/pgm 全部 PASS；XLR 44,177/60,800（72.66%）；RAM 163，DSP 8；建立最差 +0.408 ns（DDR PHY），core_clk +2.056 ns（Fmax 111.8 MHz）；保持最差 +0.028 ns | reports/build-01；artifacts/staging/TRACK4-031-REFINE-001-B01 |
| T3 | 通过。新 pt.sdc 中 tmds/cam 行与 031 完全相同，SDC 解析无警告；efx_sta 查询结果：tmds_tx_data0 建立裕量 +5.231 ns，cam_d0/cam_d2 HS_IN +8.445/+8.397 ns；check_timing 未约束内部终点为 0 | reports/refine001_sta_q3.out |
| T4 | 通过。层次报告中不再出现 recognition/anchors/gradient_store/fitting/statistics；CSI 只剩 depack40bit；shapes 仍在 | track4_board.hier_util.rpt |
| T5 | 通过。归一化后的综合警告集合没有新增项；减少的项全部来自被移除的数值链，其中包括 fit_core 的 cache_k/cache_key/cache_m 无驱动 | warn.log 对比 |
| T6 | 未运行，等用户上板 | — |

**附带核查**：
- pinout.csv 与 031 逐行相同，peri.xml 字节相同。
- "同步链首级由组合逻辑驱动"告警为 130 条，与 031 完全相同，是原有的 FIFO 复位门控造成的，不是本次引入。

**未执行**：仿真；实物下载与观察；正式数据库和 APPROVAL_MANIFEST 写入（PostgreSQL 未配置）。

**编译次数**：已用 1 次，上限 6 次。

**状态**：WAITING_HUMAN_PROGRAM。本版不取代 031 作为交付基准（D2）。

**v0.2 实录（2026-10-13）**：

- 改动：peri.xml 第 268/281/284/299 行，共 4 个 gpio_def 对调，其余未动（与 031 比对仅这 4 行不同）。
- 编译：第 2 次编译，map/interface/pnr/pgm 全部 PASS。
- 资源：XLR 44,177。
- 时序：建立最差 +0.253 ns（sdram_clk），core_clk +1.854 ns，保持最差 +0.023 ns，无负裕量。
- V2-T1 通过：pinout 与 031 相比仅 N13/N14/P13/P14 四行对调。
- 产物：`artifacts/staging/TRACK4-031-REFINE-001-B02`，bit SHA256 `63906ed2…71a2`。
- 状态：WAITING_HUMAN_PROGRAM；V2-T3 未运行。
- 编译次数累计 2/6。
- README 与 handoff.json 已同步。
- B01 实物结果：黑屏、显示器无提示（REWORK_REQUIRED）。

**过程附注**：efx_sta 需要在 outflow 下有 work_pnr 目录，因此把 work_compile 中的布局数据和 troutingtraces 复制到了 `outflow/work_pnr/`。这只是供查询用的编译产物副本，不影响 bit。

## L. 交付与阅读说明

（实现后填写）
