# FPGA Edge Agent Control Plane

这是 VF/Ti60 FPGA 实时图像边缘检测项目的单 Agent 控制面，按配置、文档、状态、数据库、运行时和产物职责分层。

本目录保存 Agent 定义、项目状态、审批记录、事件归档、数据库 Schema、运行报告和硬件观察记录。原始 HDK、参考工程和正式 RTL 不属于本目录的可写范围。

## 当前原则

- 不包含 Verilog、C++、TinyML 或其他学习规划。
- Agent 可以在获准的独立工作副本中检查和编译。
- 每个硬件节点生成 bit/hex 后，必须停止并等待人工下载和观察。
- Agent 不自动烧写 FPGA、Flash、调试器或外部设备。
- 额外工具、插件、MCP、Skill、驱动和网络动作先登记、说明并等待批准。
- PostgreSQL 是结构化数据源；本地 JSONL 是不可变事件归档。
- 没有数据库连接时不得伪造数据库成功，也不得自动切换到 SQLite。

## 项目目录

```text
_fpga_edge_agent/
├── AGENTS.md                 # 根启动入口
├── README.md
├── config/                   # Agent 定义、权限和能力注册
├── docs/                     # 工作流、状态机、审批/观察/交接模板
├── state/                    # 项目状态、任务台账、决策和异常
├── database/                 # PostgreSQL Schema、迁移和只读查询
├── runtime/                  # 事件、检查点、报告和数据库适配代码
├── planning/                 # Goal、Plan、里程碑和命令目录
├── skills/                   # 可复用程序性方法
├── tools/                    # Tool/MCP/Plugin 注册和权限矩阵
├── agents/                   # 主 Agent/只读角色编排
├── validation/               # Validator、Guardrail、Hook 设计
├── observability/            # Trace、Metric、Alert、Eval 规范
├── security/                 # 威胁模型、Secret 和保留策略
├── operations/               # 安装、迁移、备份、回滚和预算
├── context/                  # Memory、Context 和 Compaction
├── events/                   # Event Catalog 和 Handler Registry
├── side_effects/             # 幂等和副作用账本策略
├── deployment/               # Promotion、回滚和部署阶段
├── artifacts/                # staging / validated / canonical
├── reports/                  # session / node / build / hardware / audit
├── observations/             # incoming / structured / index
├── logs/                     # agent / build / hardware / audit
└── work/                     # baseline / active / nodes 独立工作副本
```

## 入口

- [设计前置与代码可理解性规范 v0.2（唯一现行详细规范）](../AI_Agent_代码可理解性规范_增补提案_v0.2.md)：业务代码生成前必须读取。
- [任务设计模板](planning/PLAN_TEMPLATE.md)：先整体、后局部；在 READY_FOR_REVIEW 等待指定版本和范围批准。
- [2026-09-28 配置调整计划](planning/DESIGN_GUIDANCE_CHANGE_PLAN_20260928.md)：实际路径、授权边界、加载与回退方案。
- [本次核查报告](reports/audit/design_guidance_20260928/CONFIG_CHANGE_REPORT.md)：分别记录文件写入、加载核实、行为演练及限制。

- [AGENTS.md](AGENTS.md)：根启动入口。
- [config/AGENTS.md](config/AGENTS.md)：长期规则。
- [config/AGENT_PROMPT.md](config/AGENT_PROMPT.md)：任务运行提示词。
- [config/PROJECT_CONFIG.yaml](config/PROJECT_CONFIG.yaml)：项目和权限配置。
- [docs/WORKFLOW.md](docs/WORKFLOW.md)：软件—硬件节点流程。
- [docs/STATE_MACHINE.md](docs/STATE_MACHINE.md)：状态转换。
- [database/README.md](database/README.md)：PostgreSQL 迁移和健康检查。
- [runtime/agent_runtime.py](runtime/agent_runtime.py)：离线事件、哈希、检查点和 DB 健康检查工具。
- [runtime/pg_store.py](runtime/pg_store.py)：驱动可用且获准后，使用参数化 SQL 写入 PostgreSQL。
- [runtime/generate_reports.py](runtime/generate_reports.py)：本地报告生成器。
- [runtime/validate_control_plane.py](runtime/validate_control_plane.py)：控制面静态验证器。

## 目前状态

已确定赛题四；2026-09-23 用户确认实物尚未确定，先以 VF-Ti60F225 检查环境。首次硬件节点运行前仍须确认实际板卡、FPGA、相机、接口、转接板和显示输出。

- [赛题四需求与出处](docs/requirements/TRACK4_REQUIREMENTS.md)：五类基础、六项高阶。
- [完整工作流程](docs/workflows/TRACK4_WORKFLOW.md)：环境、H0–H5、A1–A6、R0 与逐节点人工验收。
- [硬件/相机/屏幕/TinyML 证据](docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md)：版本差异与未知项。
- [本机环境实测](reports/audit/environment_20260923/ENVIRONMENT_READINESS.md)：Efinity 依赖检查通过；ModelSim HDL 编译通过、仿真许可失败；完整 FPGA 构建尚未运行。
- [当前推进计划](planning/CURRENT_PLAN.md)：下一步、阻断项与完成条件。
- [最新功能验收](reports/audit/environment_acceptance/ENVIRONMENT_ACCEPTANCE.md)：最小 Efinity 构建与 FIFO 生成已通过；仿真许可/兼容性、数据库和运行时拦截仍阻断，整体未验收。

数据库、可观测性和审批恢复体系目前包含配置、Schema 和局部脚本，尚未完成真实服务部署与端到端验收。静态验证通过不代表数据库可用、审批已被程序强制拦截或硬件已经通过。
