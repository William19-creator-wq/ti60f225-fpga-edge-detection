# 设计前置与代码可理解性：配置调整计划

日期：2026-09-28。范围：项目指导和文档；不实施业务功能。状态：目录内调整已获本轮授权；用户随后明确回复“批准新增根入口”，仅授权下述准确路径的一次性新增，不修改原审批清单或安全配置。

## 调查事实

- 工程工作目录：`D:\大三\FPGA_verilog`；控制面：`_fpga_edge_agent`。两处均非 Git 仓库，不能判断“未提交改动为空”。
- 宿主包：Codex Desktop `26.924.2738.0`；实际命令 `codex-cli 0.158.0-alpha.2.1`。Windows / PowerShell。
- 未发现工程根或祖先目录 AGENTS/override、用户 Codex home AGENTS/override；未发现项目 `.codex` / `.agents`。用户配置已登记当前项目 trusted；本次不改变任何权限或全局配置。
- 两次实际 `codex debug prompt-input`：工程根无 FPGA Bootstrap，控制面目录有 Bootstrap；后者要求显式读取 config 指导。不能把显式引用等同自动注入。
- 现有 `skills/fpga-hardware-node-gate` 不在本会话技能目录中，也不在官方 `.agents/skills` 发现位置；保留原位、通过流程显式读取，不安装。
- `config/APPROVAL_MANIFEST.yaml` 允许目录内控制面写入；没有对这些指导文档逐项审批的规定。`config/AGENTS.md` 第 15 行限制写入控制面目录，根入口作为单独例外请求。
- PostgreSQL 在现有状态中为 NOT_CONFIGURED；本次不连接或写数据库。`docs/WORKFLOW.md` 明确允许独立配置验证。
- 已审阅 `runtime/validate_control_plane.py`：只读结构/字段检查，不能证明设计门槛或运行时安全；现有非法状态拦截失败不在本轮修复范围。
- 工程根已存在与附件哈希相同的 v0.2 规范及启动提示词。规范 SHA256：`4e4680716458f75bda157e6fd2e2d13d09a9e85b5a4f5f7ff0d906170c7badb2`。

## 变更与文件职责

以下相对路径以 `_fpga_edge_agent` 为基准：

| 路径 | 最小调整 |
|---|---|
| `AGENTS.md` | 增加设计门槛、规范入口及明确读取顺序 |
| `config/AGENTS.md` | 合并精简长期规则；保留已有授权和安全边界 |
| `config/AGENT_PROMPT.md` | 把业务设计批准放在业务源码及测试生成之前 |
| `docs/WORKFLOW.md` | 在硬件闭环前插入设计流程与文档检查点 |
| `docs/workflows/TRACK4_WORKFLOW.md` | 替换可能直接修改 RTL 的步骤；各节点统一门槛 |
| `docs/STATE_MACHINE.md` | 说明设计标签与原运行时状态相互独立，不修改运行时枚举 |
| `planning/PLAN_TEMPLATE.md` | 保留原字段，扩展为任务设计、追踪、批准及交付模板 |
| `planning/CURRENT_PLAN.md` | 增补继续业务工作前的设计批准入口，不改历史验收结论 |
| `skills/fpga-hardware-node-gate/SKILL.md` | 核验指定设计及实现范围，保留各项原审批 |
| `skills/README.md` | 说明现有 Skill 的实际加载限制和显式读取方式 |
| `README.md` | 增加规范、模板与核查报告的阅读入口 |

唯一现行详细规范直接采用工程根 `AI_Agent_代码可理解性规范_增补提案_v0.2.md`，不复制另一份。启动提示词只属于本次迁移授权，不作为常驻提示词。任务文档复用 `planning/`，未来保存为 `planning/design-<task-id>.md`。

## 行为与冲突解决

业务任务依次完成：整体外部行为 → 模块职责/连接/相容接口 → 组合设计检查 → 局部数据、状态、不变量和中文操作草图 → C++/RTL/跨语言契约 → 验证计划与双向追踪 → READY_FOR_REVIEW → 用户批准指定版本、范围及基线 → 实现。

旧步骤的“批准”补足对象；SOURCE_APPROVED 仍是原硬件节点状态，不替代设计批准。适用但未知的关键条件阻塞相关设计。批准前不能生成业务实现、可执行测试或 testbench，也不能由子 Agent、代码块或原型绕过。交付必须对照实际文档、注释、代码和测试，理解验收独立记录。

保持原工具、数据库、硬件人工闸门。仅文档/人工审批，不声称安装了程序强制控制。历史板型及验收记录不在本次重写；业务恢复时必须重新核验相关基线。

## 根入口候选：已取得一次性路径授权

目标：`D:\大三\FPGA_verilog\AGENTS.md`，原来不存在。候选完整内容：

```markdown
# FPGA_verilog 项目入口

本项目的控制面位于 `_fpga_edge_agent/`。开始项目工作前，必须读取 `_fpga_edge_agent/AGENTS.md`，并按其中顺序读取项目规则和运行提示词。原始 HDK、资料及参考工程保持只读，沿用控制面的审批和人工硬件闸门。

新功能、行为/接口变更、重构、错误修复及 C++/RTL 映射，必须读取本目录 `AI_Agent_代码可理解性规范_增补提案_v0.2.md`。先形成可读回的整体/局部设计、接口与组合检查、中文操作草图、验证计划和双向追踪；达到 READY_FOR_REVIEW 后等待用户明确批准指定设计版本、范围和基线。

批准前不生成业务源码、功能性脚本、可执行测试或 testbench；回复代码块、子 Agent、原型同样受限。配置调整授权不是业务实现授权。任务文档使用 `_fpga_edge_agent/planning/PLAN_TEMPLATE.md`，保存到 `_fpga_edge_agent/planning/design-<task-id>.md`。

详细规范只有上述 v0.2 一份；启动提示词不是长期规则。本文件只负责引导读取，不改变权限、审批设置、数据库或运行时状态。
```

授权取得前未在工程根创建文件；用户批准后按候选新增。是否实际加载仍以修改后的宿主探测为准，不以文件存在推定。

## 验证、备份与回退

修改前逐字节保存 `.before` 备份和 SHA256，记录不存在的新路径；写入前再次比较哈希，发现并发变化则停止相关合并。备份、差异、加载证据及报告保存在 `reports/audit/design_guidance_20260928/`。

修改后读回所有文件、核对差异与链接；运行原只读控制面验证及现成 Skill 元数据检查，不改校验器。使用现有 CLI 的 `debug prompt-input` 比较实际注入内容，不改沙箱/自动批准，不把 CLI 结果冒充当前桌面聊天已热刷新。独立只读协作者执行规范 CASE-01～10，记录输入/输出/边界；不生成业务代码或测试。不能执行的验证如实标注。

回退前对照修改后哈希：一致才可恢复对应 `.before`；有后来修改时只反向合并本次差异。新入口仅在仍为本次内容时移除；保留原始规范、资料和历史审计记录。不运行 Git reset/clean，不批量清理。

## 本次明确不变

业务源码/测试、构建/CI、Hook/校验器/运行脚本、安全策略、沙箱/自动批准、凭据/全局设置、数据库与迁移、运行状态和任务台账、其他仓库均不修改。不安装依赖/MCP/插件，不部署/烧录/提交/推送，不自动继续业务开发。

依据：[Codex 指令发现](https://learn.chatgpt.com/docs/agent-configuration/agents-md)、[Skill 发现位置](https://learn.chatgpt.com/docs/build-skills)，结合本机 CLI 实际输出；官方规则不代替现场加载证据。
