# V4 匹配 DDR3 器件模型与资料获取申请

日期：2026-10-04。Request 版本：v1。关联任务：`TRACK4-FULL-SW-001`；对应阻塞：`BL-01`。

本申请服务于 Ti60F225 DemoBoard V4 + SC431HAI 的隔离软件实验。用户追加指定的 VF 资料包和 Demo 目录中确有 DDR3 仿真模型；当前找到的是配置为 4Gb/x16 的模型及 4096Mb 参数头。V4 板卡资料记载 MT41J128M16JT-125、2Gb/x16，所需 2048Mb 参数头仍未找到。[本地检索证据](../experiments/track4_full_sw_20261004/05_reviews/review-and-blockers.md)保留实际搜索范围。

- Request ID: `REQ-DDR3-MODEL-20261004`
- Tool / plugin / MCP / Skill / driver: 使用已有网页检索/阅读能力及已有下载能力，查阅公开厂商资料并取得模型文件；无需新增工具、插件、驱动或服务。
- Version: 目标为明确覆盖 MT41J128M16JT-125 的 2Gb/x16 DDR3 模型、配套参数和数据手册。具体模型版本在取得厂商资料后记录；不预设最新版本一定兼容现有控制器。
- Source URL or package path: 从 Micron 与 Efinix 官方网站检索。已知的 Efinix DDR3 控制器文档入口为 `https://www.efinixinc.com/support/docsdl.php?s=ef&pn=UG-CORE-DDR3-CONTROLLER`，仅是本地帮助引用的入口，尚未联网验证，不能视为匹配器件模型的下载地址。实际下载 URL 与跳转来源须记录。
- Reason it is required: 完成用户要求的匹配 DDR 器件、真实控制器/PHY 与初始化/校准路径的软件验证，补齐完整器件模型及其依赖和时序依据。
- Why current capabilities are insufficient: 本地已有 Micron v1.74 模型源码，其第 97–98 行固定 4Gb/x16，第 122–123 行的 2Gb 分支引用缺失的 `2048Mb_ddr3_parameters.vh`。现有 4Gb 参数头不能直接作为 V4 的 2Gb 参数依据；模型存在也不等于它已通过当前 Questa/PHY 校准验证。
- Files and permissions it needs: 原始 V4、VF、Demo 和工具安装目录保持只读。下载输入仅写入 `_fpga_edge_agent/work/dependencies/track4_ddr3_model_20261004/`；来源、版本、使用条件、SHA256、依赖与器件匹配检查记录写入 `_fpga_edge_agent/experiments/track4_full_sw_20261004/01_baseline/`。首次写入前检查目标不存在同名已有文件，避免覆盖。本申请不修改模型或项目 RTL。
- Network destinations: 搜索服务仅接收公开器件型号和文档名称；实际资料阅读和下载限 `micron.com`、`efinixinc.com` 及其子域，以及从上述官网明确链接的资料 CDN。记录实际目标；身份不明或与资料无关的跳转不继续。没有授权上传项目、源码、凭据或本地文件，也没有授权向厂商发信、提交工单或代替用户接受额外合同。
- Expected side effects: 产生上述范围内的网络请求、下载文件、浏览/下载缓存及本地来源检查记录。不会执行下载的脚本、安装包或二进制，不新增软件，不变更全局配置，不操作硬件。
- Rollback / uninstall plan: 本申请不安装软件。取消时停止后续网络与下载；保留来源检查记录。只清理本次清单可定位的临时下载，且仅在核实绝对路径位于专用依赖目录后操作；原资料和其他任务产物不受影响。
- Validation after use: 核对官方来源与使用条件；记录文件 SHA256、模型版本、全部 include 依赖和目标容量/位宽；逐项比对行/列/bank、速度等级、时序参数及现有控制器配置。若只能获得其他容量、缺少参数头、来源不清或使用条件不允许，明确保留缺口。该检查只确认输入资料适用性，不记录仿真、综合、布局布线或校准通过。
- Approval status: `PENDING`
- Human decision: 尚未收到对本申请 v1 的明确批准。本地查找请求及当前整体工作目标没有被登记为联网/下载批准。

## 批准边界

批准本申请 v1，即批准上述公开官方资料检索、文件下载及只读适用性检查。业务 RTL、功能脚本、testbench、模型修改、独立工程修改以及编译/仿真仍按原有设计和运行审批执行；本申请不替代这些批准，也不更新正式数据库或硬件节点状态。

审批依据：[config/AGENTS.md](../config/AGENTS.md)“任何下载、安装、升级、驱动写入、网络访问、插件/MCP/Skill 启用或外部服务写入都必须先登记并等待批准。”
