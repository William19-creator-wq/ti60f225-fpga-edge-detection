# Agent 配置诊断（2026-10-12，Claude Code，只读）

用户要求：先重建对项目的理解，再审查"Agent 配置设计本身"（不是代码质量），最后给出风险优先清单。诊断期间没有修改任何文件。下文区分**事实**（读到或算出的）与**推断**。

## 1. 项目理解

**目的**：易灵思 FPGA 创新设计大赛赛题四，实时图像边缘检测。官方要求 5 项基础、6 项高阶（[TRACK4_REQUIREMENTS.md](../../docs/requirements/TRACK4_REQUIREMENTS.md)）。最早的策略（工程根 `CHATGPT_PROJECT_CONTEXT.md`）是先做简单、可验证的基础版，按"彩条 → 相机直通 → 灰度 → Sobel → 上板"推进。

**范围膨胀（事实）**：官方 A6 原文是"简易目标识别（创意拓展）：基于边缘识别圆形、矩形等"。从 `planning/design-TRACK4-RECOGNITION-001.md`（10-04）起，目标被扩为任意旋转矩形、遮挡、缺边、重叠、每类 P/R≥95%、IoU≥0.5。文件写"用户保留完整功能和质量目标"，但没有找到用户原话。用户 2026-10-12 确认这是"過程中被放大的"，并同意排除。

**实际进度**：

| 层级 | 内容 | 证据 |
|---|---|---|
| 完成（只有软件证据） | 031 整机 bit：相机/DDR/HDMI、灰度、中值、Sobel、Canny、红边叠加、按键阈值、冻结、初版候选框 | 综合、PNR、STA 通过；60,531/60,800 XLR（99.6%）；未上板 |
| 半成品 | 完整圆识别 | 064 综合通过，容量超出 9,948 |
| 半成品 | 矩形 4 个独立候选（RP/RW/LR/49 偏移投票） | 未接入整机，部分未编译 |
| 空壳 | PostgreSQL | 只有 schema；`PROJECT_STATE.json` 中 `database.health = NOT_CONFIGURED` |
| 空壳 | checkpoints、side-effect ledger、observations、artifacts/validated、canonical | 目录只有 `.gitkeep` 或为空 |
| 空壳 | Hooks、Subagent 角色、Eval/Observability/Deployment | 只有规范文件 |

**编译历史（事实）**：共 64 个 run。031 之后的 032–064 共 33 个，没有一个产生 bit：
- 045–059 多次 XLR 已低于上限仍失败：047（57,338）布线不收敛，057（57,887）"Not enough physical locations for XLR blocks"；
- 061 起接入完整圆，升到 70–72k，之后都超容量。

**目录体量（事实）**：`work/` 30 GB、103,521 个文件；`artifacts/` 8.6 GB、22,444 个文件（集中在 staging，validated/canonical 为空）；`planning/` 259 份设计文件，6.2 MB。

## 2. 配置审查（七项）

| 项目 | 现状 | 问题 |
|---|---|---|
| AGENTS.md | 三层（工程根、控制面、config）。人工硬件闸门、原始资料只读、"编译通过≠实物通过"写得清楚，且一直被遵守 | 规则要求每次改动都写中文草图并逐版批准；用户实际授权"自行进行""不要草图"，这些授权只存在于聊天转述和交接包中，规则本身没改。每个新会话都要猜按哪个执行。`PROJECT_CONFIG.yaml` 的 `host` 为 Codex；若同时用 Claude Code，还需要 CLAUDE.md |
| Workflow | [WORKFLOW.md](../../docs/WORKFLOW.md) 定义 H1→…→R0 逐节点上板 | 实际流程是一颗整合 bit 反复"改 RTL → 整机编译 → 看资源"。真正在用、而且做得好的 `build_board.ps1` / `register_board.ps1`（每个 run 冻结输入、哈希、保留日志）放在工作目录里，没有写进控制面流程。流程中也没有录影、打包、讲解文件这些交付步骤 |
| Skill | 只有 `fpga-hardware-node-gate`，文件自述"未注册为宿主可发现 Skill" | 反复执行的能力（整机编译与登记、资源/PNR 失败判读、候选模块 adoption、交接、观察记录）都靠大 prompt 和临场习惯 |
| Subagent | 只有角色清单和输出 schema，从未启用 | "不用"大体合理（同一 RTL、同一资源预算，并行写只会更乱）。真正的问题是**两个独立 AI（Codex 与 Claude Code）可能同时写同一源码**，项目没有所有权或锁机制 |
| State machine | [STATE_MACHINE.md](../../docs/STATE_MACHINE.md) 定义了合法状态和转换 | 正式状态源已失效：`PROJECT_STATE.json` 停在 09-23（`WAITING_FOR_HARDWARE_BASELINE`，硬件字段全为 null），`TASK_LEDGER.csv` 全为 `NOT_STARTED`/H0 `IN_PROGRESS`，`CURRENT_PLAN.md` 停在 10-04。真实状态散在 `integration-status.json`（约 80 个临时字段）里，并混用不同版本：顶层 `pnr_passed`/`timing_passed`/`bitstream_registered = true` 指 031，同一对象的 `current_run` 却是失败的 064；`full-goal-completion-audit.json` 中 `latest_failed_run = 063`，同文件另一处最新失败为 064。没有"编译失败/容量不足"的正式状态 |
| Plan | v0.2 规范 919 行、模板 154 行、259 份设计文件 | "先规划、等批准"变成 AI 自标 `READY_FOR_REVIEW` 后引用概括授权自行放行（10-12 最新两份设计文件原文如此）。付出了文书成本，没有得到人工审查的效果。缺少真正需要的计划：整体资源预算（031 已 99.6%，没有任何文件先算完整圆和矩形需要多少 XLR） |
| 外部工具 / MCP | 无 MCP；[MCP_REQUIREMENTS.md](../../tools/MCP_REQUIREMENTS.md) 判断不需要，正确 | 设计依赖从未存在的 PostgreSQL；规则写"没有数据库就停止"，实际每批都靠"本地审计例外"绕过。宿主 Hook 只有逻辑设计（[HOOK_DESIGN.md](../../validation/HOOK_DESIGN.md)），没有真正拦截烧写命令或原始资料写入 |

其他事实：
- `operations/RESOURCE_BUDGET.yaml` 写 `max_retries_per_node: 2`，实际 64 个 run，从未执行这条限制。
- `runtime/validate_control_plane.py` 做静态结构与交叉引用检查：文件存在、字段格式、节点/需求编号一致、Schema 表名、提示词关键句。它**不检查状态内容是否最新或真实**，输出自注 `scope=files_and_references_only_not_runtime_or_database_acceptance`。因此 09-23 的旧状态仍能通过。
- `PROJECT_STATE.json` 的环境检查记录 `runtime_illegal_transition_guard: FAIL`。
- `runtime/events/2026/10/session-FAST-BATCH-20261008.jsonl` 共 256 条，其中 152 条没有 `event_type`、`type`、`operation_id` 任一字段，难以机器回溯。

## 3. 配置与用户目的的差距

用户目的（10-12 确认）：两周内、一个人、交付源码加影片，并且自己能看懂并讲解。

| 用户需要 | 配置实际优化的 | 后果 |
|---|---|---|
| 有期限的比赛作品 | 可审计、可回溯、零违规 | 全项目没有截止日期或里程碑；64 个 run、259 份设计文件，0 次上板 |
| 一个人的项目 | 多人/生产级治理（PostgreSQL、side-effect ledger、幂等、promotion、threat model） | 这些从未启用，只造成每次开"例外"的摩擦，并让人误以为已有这些能力 |
| AI 自主推进，用户只做关键决定 | 每个改动都要中文草图并逐版批准 | 闸门空转；真正该问用户的事（资源爆了砍什么、范围要不要缩）没有触发点 |
| 在有限的晶片资源内完成 | "硬件"只被理解成人工下载闸门 | 没有资源预算和止损；031 达 99.6% 后连续失败 33 次 |
| 先做出能动的，再加功能 | 节点有顺序，但下一步不以上一步实物通过为前提 | 板子晚到后变成纯软件堆叠，相机/DDR/HDMI 至今未在实物上验证 |
| 官方"简易识别" | 规则禁止 AI 给问题设界限（"不能重新加已撤回的尺寸/数量/遮挡硬界限"） | 规格没有边界，资源需求没有上限，推断为容量问题的根源 |
| 自己看懂并讲解 | v0.2 中文草图机制本为可理解性设计，但颗粒度是"每改动一份" | 259 份，用户读不完，之后被叫停；需要的是一份对应交付版本的设计说明 |

用户自己设计的分层模型见 `user_layered_model.png`：设计时定 State machine 与 Workflow，约束每次的 Plan；执行时 Plan → Skill → MCP → API。现有配置只有"名称"能对上，层与层之间的连接（尤其"约束 Plan"那条箭头）断开，内容也与当前任务脱节。另外，模型缺少最上层"目标与约束"。按两周任务逐层校准的结果见 drafts/AGENT_MODEL_CALIBRATED.md。

## 4. 风险优先清单

**P0（会导致误判进度或实际损失）**
1. 没有单一可信的状态来源；正式状态冻结，真实状态语义混杂。
2. 没有资源预算和失败止损（用户已确认 D3 门槛）。
3. 实物验证被跳过：板子已到，031 未下载，软件仍在往上堆。
4. 规则与用户实际授权冲突，只靠聊天转述调和。
5. 多个 AI 并行写同一源码，没有所有权机制。
6. A6 范围来源不明而膨胀（用户已确认收回）。

**P1（影响效率和可恢复性）**
7. Workflow 与实际流程不符；好用的编译脚本未纳入控制面。
8. 重复能力未拆成 Skill。
9. PostgreSQL 依赖：要么真正配置，要么正式改为本地文件。
10. 事件日志格式不一致。
11. Plan 文件过量，缺少"当前有效"索引。

**P2（可以晚点）**
12. 若同时使用 Claude Code，补 CLAUDE.md。
13. 安装真正的宿主 Hook 拦截烧写命令与原始资料写入。
14. 只读 build_reviewer，自动比较各 run 资源走势。
15. 精简或标注 Observability/Eval/Deployment/Security 等空壳文件为"未启用"。

**值得保留**：人工硬件闸门一直被严格遵守；每次编译冻结输入、保留哈希和日志；"编译通过≠实物通过"的区分一致；交接包质量好。
