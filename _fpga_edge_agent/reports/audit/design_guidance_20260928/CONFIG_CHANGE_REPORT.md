# 设计前置与代码可理解性：配置调整报告

日期：2026-09-28。范围：指导与文档。本报告不代表业务设计批准、工程环境验收或硬件通过。

## 授权与调查

用户直接要求实施本次指导调整；先调查、呈现[具体计划](../../../planning/DESIGN_GUIDANCE_CHANGE_PLAN_20260928.md)，再写配置。原 `config/AGENTS.md` 将写入限定在控制面目录，因此先保存根入口完整候选并询问；用户明确回复 **“批准新增根入口”**，随后新增工程根 `AGENTS.md`。原 Approval Manifest 与安全策略没有改动。

- 实际工程根：`D:\大三\FPGA_verilog`；控制面：`D:\大三\FPGA_verilog\_fpga_edge_agent`。
- Windows 包 `OpenAI.Codex`：`26.924.2738.0`；实际 CLI `codex-cli 0.158.0-alpha.2.1`，来自 `C:\Users\34528\AppData\Local\OpenAI\Codex\bin\faa963e871dd422c\codex.exe`。
- 工程根与控制面均非 Git 仓库；不存在可据此确认的“干净工作区”。已保存原字节与哈希，保留现场原有内容，不使用 Git reset/clean。
- 工程根原来没有 AGENTS/override；控制面有 Bootstrap，config 有长期规则；相关祖先/默认 Codex home 未发现覆盖文件。项目未发现 `.codex` / `.agents` 目录。只读取与本次加载有关的用户配置字段，未修改全局配置。
- `APPROVAL_MANIFEST.yaml` 已授权目录内控制面写入；未发现指导文档必须逐文件再批的制度。正式节点仍受数据库、源码、编译及人工下载/观察审批约束。
- PostgreSQL 现有记录为 NOT_CONFIGURED；既有运行时非法状态拦截失败仍未修复。本次依据工作流允许的独立配置验证开展，不启动正式节点或数据库。

## 唯一现行规范与加载入口

- 详细规范：[工程根原有 v0.2](../../../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)。与 `D:\大三\ai_agent_prompt` 附件字节一致，SHA256 `4e4680716458f75bda157e6fd2e2d13d09a9e85b5a4f5f7ff0d906170c7badb2`，未复制第二份现行规范。其中历史作者调查记录不代表本次重新执行过全部外部调查。
- 根简明入口：[AGENTS.md](../../../../AGENTS.md) → [控制面入口](../../../AGENTS.md) → [长期规则](../../../config/AGENTS.md) / [Runtime Prompt](../../../config/AGENT_PROMPT.md)。详细文档必须实际读取，链接不是自动内容注入。
- 新功能、行为/接口变更、重构、错误修复、C++/RTL 映射均触发规范读取；准备硬件编译时再显式读取现有节点 Skill。
- 任务设计使用 [PLAN_TEMPLATE.md](../../../planning/PLAN_TEMPLATE.md)，保存 `D:\大三\FPGA_verilog\_fpga_edge_agent\planning\design-<task-id>.md`。设计标签只记录在任务文档中，不修改现有运行时枚举或数据库 Schema。
- 当前 `skills/` 是项目资料位置，没有安装到宿主自动发现位置；不声称 `$fpga-hardware-node-gate` 已注册。根/控制面入口与工作流负责显式读取。

## 实际文件变更

新增工程根 `D:\大三\FPGA_verilog\AGENTS.md`，与获批候选一致。以下 11 个既有文件在控制面内局部合并，未整份替换：

| 相对控制面路径 | 改变的职责 |
|---|---|
| `AGENTS.md` | 增加规范触发与读取顺序、代码生成停止点 |
| `config/AGENTS.md` | 精简长期规则，语言契约、版本批准、变更复核及最终一致性 |
| `config/AGENT_PROMPT.md` | 节点执行前增加设计批准，区分原有动作审批 |
| `docs/WORKFLOW.md` | 整体→组合检查→局部→评审→实现→硬件闭环 |
| `docs/workflows/TRACK4_WORKFLOW.md` | 替换直接修改 RTL 步骤，各节点同样适用 |
| `docs/STATE_MACHINE.md` | 文档设计标签与硬件运行时状态分离 |
| `planning/PLAN_TEMPLATE.md` | 保留旧字段，补充 A–L 设计/追踪/评审/交付和短修复卡 |
| `planning/CURRENT_PLAN.md` | 历史实施顺序不是业务实现预授权 |
| `skills/fpga-hardware-node-gate/SKILL.md` | 核对设计版本/范围/基线，保留原审批与人工闸门 |
| `skills/README.md` | 说明实际加载方式与未注册状态 |
| `README.md` | 规范、模板、计划和核查报告入口 |

本次另新增计划文档，以及本审计目录中的备份、差异、JSON 检查证据和行为演练记录。这些均为文档/审计材料，不是业务实现、可执行测试或校验器。业务源码、业务测试、构建/CI、Hook、运行脚本、安全策略、沙箱/自动批准、凭据、全局配置、数据库、状态和任务台账均未修改；未安装依赖/MCP/插件，未部署、烧录、提交或推送。

## 文件写入：已完成并读回

- [修改前清单与备份路径](before_manifest.json)：11 个文件逐字节备份；根入口原来不存在。
- [逐文件差异](changes.diff)：根入口新增和 11 个局部修改；原规则保留，旧直接实现步骤已替换。
- [读回/哈希/链接检查](file_checks.json)：UTF-8 解码、实际内容读取、修改前后哈希和相对链接。
- [范围检查](scope_check.json)：修改前覆盖 1,084 个文件，包含全部控制面文件与工作副本以及 3 个根 Markdown 原文件；新增根入口后 1,085 个。除列明指导/计划变更外没有变化；审计输出单独排除。未把未全量哈希的外部 HDK/工具目录宣称为全盘验证。
- 独立协作者 `audit_guidance` 逐行对照全部备份与获批根入口候选，未发现阻塞缺陷；确认空白模板不是默认 READY/批准，原安全与硬件规则仍在。

原检查的实际运行：

| 检查 | 结果和覆盖限制 |
|---|---|
| 现有 `runtime/validate_control_plane.py`，使用已有 Python `-B` | `CONTROL_PLANE_STATIC_VALID`；`files_checked=72`；只覆盖已有结构、字段和部分引用，不验证真实审批或数据库 |
| 现有 Skill Creator `quick_validate.py` | 最初两个已安装 Python 均缺 yaml，记录为依赖失败；随后当前进程临时引用 Efinity 自带 PyYAML `6.0.3`，输出 `Skill is valid!`；未安装包、未修改全局路径或脚本，仅验证元数据/格式 |
| 独立差异审查 | 无阻塞缺陷；最初 README 的报告链接等待本文件生成，最终链接检查再核实 |

## 加载核实：CLI 实际注入已证实，桌面热刷新未验证

使用同一个已安装 CLI 的 `codex debug prompt-input`，不调用模型、不传权限覆盖或自动批准参数、不修改配置。写入前分别从工程根/控制面执行：根目录无项目指令，控制面出现原 Bootstrap。

写入后证据：

- [工程根实际模型输入](load_probe_root.json)：出现根 `AGENTS.md instructions`、完整入口正文和设计批准门槛。
- [控制面实际模型输入](load_probe_control_plane.json)：出现 Bootstrap、规范路径和 READY_FOR_REVIEW 规则。

这证明 CLI 在对应启动目录的发现和注入；不证明引用的长文档全部自动加载。当前桌面聊天通过本轮工具实际读到了文件，但**未验证其自动热刷新**，也未自动创建新的用户聊天。CLI 诊断显示其默认 managed 权限上下文，而当前桌面会话权限上下文不同；没有将两者视作同一个已验证的运行会话。建议下次从工程根启动新会话，再查看实际入口读取情况；非 Git 项目若从更深无入口的目录启动，不保证继承根文件。

[官方 AGENTS 发现说明](https://learn.chatgpt.com/docs/agent-configuration/agents-md)和[Skill 发现说明](https://learn.chatgpt.com/docs/build-skills)仅支持机制解释；上述实际 JSON 才是本机发现证据。没有新增 Hook、校验器或文件系统强制门控。

## 行为演练：十个只读场景已执行，覆盖有限

无历史上下文启动的 `design_gate_exercises` 显式读取真实入口后，逐一处理 CASE-01～10 的具体输入。输入、原答摘录、观察与限制已保存到 [BEHAVIOR_EXERCISES.md](BEHAVIOR_EXERCISES.md)。没有生成业务代码、可执行测试或 testbench，模拟批准不构成业务授权。

观察到的具体结果包括：等值/越界缺失时阻断；区分输入像素坐标与窗口中心；像素150在阈值100→200变化时指出软件255/硬件可能0的差异；复位语义改变需新版本评审；小修复采用短卡；实际读取流水灯源码并发现“每拍旋转”描述错误；不把委托子 Agent 当作绕过路径。

CASE-01因真实资料未确认C++标准/工具/源码落点而保留BLOCKING，没有为了满足预设演练终点伪标READY。CASE-09仅验证条件判断，没有实际业务实现。演练另有只读边界，不能据此证明文档是不可绕过的强制控制，也不能代替桌面新会话加载与后续真实表现。未观察到与本次规则冲突的响应；不表述为“业务测试全通过”。

剩余问题：当前桌面自动热刷新、新桌面会话加载、真实完整获批后的业务路径及用户理解均未验证。硬件状态JSON与较新证据文档的日期/决定存在历史差异，后续调查需重核；本次不更新状态服务、数据库、仿真许可或运行时失败项。

## 回退办法

1. 先看 `before_manifest.json`、`file_checks.json` 与 `changes.diff`，只针对本次列明路径。
2. 文件仍与修改后 SHA256 一致，才可用对应 `.before` 恢复；若已有用户或后续工作修改，按差异反向合并本次内容，不能覆盖整份新文件。
3. 根 `AGENTS.md` 是本次新建，只有仍与本次候选/修改后哈希一致时才移除；不改其他根文件和用户提供的规范。不存在自动回退脚本，本次未执行回退。
4. 计划与审计记录保留作历史依据；如需归档/清理，沿用原人工批准要求，不自动删除。

## 下一次业务任务的停止位置

先调查并完成从整体到局部的设计、接口/组合检查、中文草图、语言契约、验证计划与双向追踪，在 `planning/design-<task-id>.md` 的 **I. 设计门槛与评审** 记录 `READY_FOR_REVIEW` 后等待用户批准指定版本和范围。有当前关键未知则更早停在 BLOCKED，不能伪装就绪。收到有效批准后仍须满足原工作副本、构建、数据库及硬件审批；生成 bit/hex 后继续由用户人工下载与观察。

本次配置任务结束后停止，不自动接续赛题功能开发。
