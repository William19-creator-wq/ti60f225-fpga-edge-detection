# Handoff and Recovery

## 2026-10-04：新聊天接续入口（当前）

用户要求新开同一项目聊天，继续未完成任务。工作目录必须是 `D:\大三\FPGA_verilog`；本地项目名称为 `FPGA_verilog_C_C++_python`。旧聊天参考 ID：`01a0c939-168b-77b0-a369-4628cfa5ffad`。本交接整理已保存的事实和停止点，不复制全部聊天，也不是实施批准。

### 首次恢复的阅读顺序

1. 工程根 [AGENTS.md](../../AGENTS.md) → 控制面 [AGENTS.md](../AGENTS.md)，按引导实际读取 config 规则/提示词/配置、state 状态/台账、database 说明和既有 Approval Manifest。
2. 读取唯一现行[设计与代码可理解性规范 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)。继承“先设计、指定版本/范围批准后实施”，不重新创建一套规范。
3. 读取 [CURRENT_PLAN.md](../planning/CURRENT_PLAN.md) 顶部最新段落及 [FIFO-SMOKE-001 v1.0](../planning/design-FIFO-SMOKE-001.md)；再查 [baseline.json](../reports/audit/fifo_design_20261003/baseline.json)、[设计复核](../reports/audit/fifo_design_20261003/DESIGN_REVIEW.md)。
4. 读取 [QUESTA_LOCAL_SETUP.md](../tools/QUESTA_LOCAL_SETUP.md)、[LOCAL_TOOL_PATHS.json](../tools/LOCAL_TOOL_PATHS.json) 和 [Questa 实测报告](../reports/audit/questa_check_20261003/QUESTA_CHECK_REPORT.md)。
5. 硬件背景以 [V4_CAMERA_SELECTION_20260927.md](requirements/V4_CAMERA_SELECTION_20260927.md)、[硬件证据顶部更新](requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md) 和 [DECISION_LOG.md](../state/DECISION_LOG.md) 的 DEC-016/017 为准。按当前任务定位资料，不从头重读全部 PDF/安装包。

### 已确认事实与限制

| 项目 | 当前有效内容 |
|---|---|
| 目标 | 赛题四实时图像边缘检测；基础及六项高阶已列计划。没有 Verilog/C++/TinyML 学习规划 |
| 板卡方向 | 用户已决定改用借用 Ti60F225，资料指向 DemoBoard V4；准确 PCB 丝印/版本、配件、相机和显示组合仍未形成实物基线。VF 仅保留为历史环境参考，不能混用引脚/DDR/电压 |
| 相机 | V4 配套 SC431HAI 彩色 MIPI 是已有资料支持的推荐，未确认购买/实机通过；不将早期 OV5640/SC2210 建议当成当前已选 SKU |
| 当前软件 | Efinity 2026.1.132、FIFO IP 8.1、QuestaSim 2024.1；历史 ModelSim10.1c 的许可/语法问题不代表当前 Questa 结论 |
| 已有实测 | 普通 RTL 编译/仿真及 WLF/VCD 已通过；FIFO 受保护源码编译通过，展开因缺少 rd_valid_o/almost_empty_o 失败，比较0次；整体环境仍未验收 |
| 桌面入口 | 用户已确认共享英文路径方案能打开；随后撤去诊断 PowerShell 窗口，最终隐藏启动器版未再次人工确认；重启未验证。恢复聊天不需要反复要求重试GUI |
| 长期路径 | `C:\Users\34528\FPGAEdgeLinks` 下 Questa2024_1、Efinity2026_1、Work、Reports 是别名，QuestaGuiWork 是真实启动目录。原程序仍在原处；旧 AppData 入口和 Q:/R: 仅属历史，不再使用 |
| 当前任务 | FIFO-SMOKE-001 v1.0 为 READY_FOR_REVIEW，未获批准、未生成新实现、未执行新测试 |
| 正式状态 | H0 尚未验收；数据库未配置；已有运行时非法状态转换拦截曾未通过。新聊天不能把文件结构齐全或GUI成功当环境全部通过 |

### 立即未完成任务和批准边界

FIFO 方案的两项拟改动：从冻结 settings.json.conf 恢复参数，只将 OPTIONAL_FLAGS 改为1并重新生成；只在新 TB 修正复位/busy等待条件。方案保留原同源时钟刺激，要求512次有效写、256次有效读和有限值数据比较、真实finish、无错误、可读波形。它不是异步FIFO完整验证。

指定版本与基线：设计 v1.0；设计 SHA256 `BB8FD301354223DE63DF85637B57B4F4DC4D07A19E089A2CE0182E02CAEB5D13`；13项输入基线清单 SHA256 `7A000B21A7BDB59F084B9B714C24A923D9D220F68C9550BAEBC6081B4EAD4B93`。核对漂移，不因存在旧文件就自行重建或覆盖。

拟执行范围是控制面 `work/active/fifo_smoke_20261003_v1/` 和 `reports/audit/fifo_smoke_20261003_v1/`；交接时二者均不存在。复制/生成脚本/TB修正/编译/仿真须等用户明确批准本版本、基线、范围及“数据库未配置期间的一次隔离本地诊断”。迁移到新聊天、要求接着做、曾批准根AGENTS入口或长期英文路径，都不等同于该实施批准。

新聊天第一轮只恢复和核实上下文，简要告知用户已接续、剩余待批事项，然后停在审批点。若用户之后明确批准，在任务设计中记录真实批准来源与原意，核验旧审批/依赖条件后按方案执行；不重复索取仍有效的同范围批准。任何超出设计的行为/时序/参数/通过标准变化仍需设计复核。

### 持续遵守与后续任务

- 原始 HDK、参考工程、安装目录只读；修改只在获批的独立工作副本。硬件下载/Flash/观察由用户完成，未观察不得判节点通过。
- 额外下载、安装、升级、Skill/MCP/插件或驱动先登记并等待批准。此交接不携带或修改许可文件、密码、Token；既有许可配置仅按路径文档在进程内使用，不输出其值。
- PostgreSQL/审批/副作用/状态机的正式运行要求保留。数据库缺失时不自动安装、不切换数据源、不启动正式节点；文档恢复和只读核查不冒称数据库恢复成功。
- `PROJECT_STATE.json`、`TASK_LEDGER.csv` 及下方旧段落尚保留9月23日信息。它们不表示用户仍计划购买VF板，也不表示当前Questa仍被旧ModelSim问题阻断；同时，正式节点尚未通过的状态仍有效。硬件选择方向与实物验收状态分别处理。
- FIFO之后仍需按授权逐项完成所需工具功能的最小实测、治理运行时/数据库验收、实物基线、基础与高阶业务节点；不可据此交接自动展开这些工作。
- 工作流/需求入口为 [TRACK4_WORKFLOW.md](workflows/TRACK4_WORKFLOW.md)、[TRACK4_REQUIREMENTS.md](requirements/TRACK4_REQUIREMENTS.md)、[WORKFLOW.md](WORKFLOW.md)。它们与其他Skill/工具文档均是磁盘资产，需显式读取；不声称某个文档已被宿主自动注册成Skill/MCP或运行服务。

交接文档已落在项目中，旧聊天保留供必要时追溯；临时截图、未写入文档的细节及当前进程会话不保证在新聊天自动出现。不要把“同一项目”理解为新聊天已经阅读所有文件。

## 正式运行的 Resume order（先满足上述授权/环境条件）

1. Read `state/PROJECT_STATE.json`.
2. Read the latest checkpoint under `runtime/checkpoints/`.
3. Check `FPGA_AGENT_DATABASE_URL` without printing its value.
4. Verify database migration version and local event archive integrity.
5. Check Side-effect Ledger before retrying any external action.
6. Confirm the work-copy hash and latest artifact hash.
7. Resume only from the last safe state in `STATE_MACHINE.md`.

## Safe pause states

- `WAITING_FOR_HARDWARE_BASELINE`
- `WAITING_HUMAN_PROGRAM`
- `WAITING_HUMAN_OBSERVATION`
- `SUSPENDED_FOR_APPROVAL`
- `BLOCKED`

No tool call is retried solely because a process exited. First inspect its event and side-effect record.

## 2026-09-23 continuation

Superseding functional-test update: read `reports/audit/environment_acceptance/ENVIRONMENT_ACCEPTANCE.md`. Minimum LED compile/PNR/STA/bit/hex and FIFO generation passed using a temporary ASCII alias. Original debug profile failed; ModelSim10.1c has both license and current FIFO compatibility blockers. Local runtime negative test failed illegal-transition rejection. Overall NOT_ACCEPTED, no installation or hardware programming. The paragraph below preserves earlier inspection history.

Track 4 confirmed. Actual hardware is undecided; user requests VF-Ti60F225 as an environment inspection example only. Read `planning/CURRENT_PLAN.md`, the track 4 requirements/workflow and `reports/audit/environment_20260923/ENVIRONMENT_READINESS.md` before continuing. Efinity imports/parser and ModelSim HDL compilation passed, but simulation failed with invalid license environment; no full Efinity build or hardware test occurred. Preserve H0 waiting for physical baseline. PostgreSQL and runtime enforcement remain unaccepted. No new tools were installed.
