# 当前 IP 仿真器与合法许可选型

日期：2026-09-23。选型状态：**主选产品族确定，具体发行版与许可待落实，兼容性尚未验收**。整体环境仍为 `NOT_ACCEPTED`。

## 选择

主选 **Siemens 通用 Questa 仿真器（QuestaSim；新产品渠道为 Questa One Sim）Windows x64**，通过学校已有正式授权或 Siemens 官方渠道获取。要求覆盖 SystemVerilog、受保护 Efinix 模型、批处理仿真及波形调试；不默认购买完整验证套件。许可证功能、用途、期限和可用版本必须由管理员或供应商确认。

以 **QuestaSim 2023.4** 作为与当前模型加密工具一致的首个版本核对候选；不是已验证的安装版本，也不是官方公布的最低支持版本。若供应商提供当前维护版 Questa One Sim，先核实 Windows 11 支持、旧保护密钥兼容及命令行脚本，再冻结精确版本和 build。本次公开资料未找到 Efinity 2026.1.132 / FIFO 8.1 对应的完整仿真器版本矩阵，因此不写“2023.4 及以上全部兼容”。

第二选择为 **Aldec Active-HDL / Riviera-PRO 通用版**。Aldec 的官方演示明确给出 Active-HDL 17 与 Efinity 2025.2 的 IP 仿真流程；这是具体交叉验证证据，但不等同于当前 Efinity 2026.1 已通过。可以申请官方评估许可做最小验收，评估到期后的竞赛使用需要匹配的有效授权。

## 本地证据和适用边界

- 当前 Efinity：2026.1.132；当前最小生成样本：FIFO 8.1，来自隔离副本。当前 VF 历史参考工程的所有 IP 没有因此自动升级。
- [当前 FIFO 样本](../work/active/environment_acceptance/20260923T085741Z_ip_ascii/ip/smoke_fifo/smoke_fifo.sv) 的保护头：`encrypt_agent = "QuestaSim"`，`encrypt_agent_info = "2023.4"`；含 Siemens、Mentor Graphics 和 Aldec 接收者条目。这里只读取公开保护头，没有解密模型。
- 样本 SHA256：`e972ccfc8c8dd57f54aa77b31a20a5fb78d3745f819788baa1376796204534cf`。
- 接收者条目表明供应商提供了相应保护封装，不能单独证明某发行版支持该封装、许可功能齐全或模型行为正确。
- [ModelSim 10.1c 实测](../reports/audit/environment_acceptance/20260923T090001Z_fifo_compile/fifo_vlog.log) 同时报 SystemVerilog 语法及 protected region 密钥错误；另有 [许可诊断](../reports/audit/environment_acceptance/20260923T084403Z_license/license_diagnosis.json) 和 [vsim 启动失败](../reports/audit/environment_20260923/simulation_vsim.txt)。它不作为当前 IP 的目标环境。未确认本机存在可用的 Questa 授权。
- DDR、CSI/MIPI、屏幕及 TinyML 的最终工程和 IP 组合尚未冻结。FIFO 的结果不能扩展为所有 IP 兼容，也不代表硬件通过。

## 官方依据与许可来源

| 来源 | 已核实内容 | 本项目用途 |
|---|---|---|
| [Efinity 安装指南 v4.1，第6页](https://www.efinixinc.com/docs/efinity-installation-v4.1.pdf) | 列出 QuestaSim、Active-HDL、Riviera-PRO、Xcelium、Icarus 的网表仿真支持；库路径为 `sim_models/verilog` | 厂商支持产品族；没有给出 FIFO 8.1 的最低版本 |
| [Siemens 学生版状态与学校授权渠道](https://www.siemens.com/en-gb/products/ic/questa-one/modelsim-student-edition-unavailable/) | 独立 ModelSim Student Edition 暂不可用；建议学校项目管理员联系 `eda_academic.sisw@siemens.com` 获取 ModelSim/Questa 使用渠道 | 首选学校已有授权；由学校核实本竞赛、个人电脑/远程访问的授权范围 |
| [Siemens Questa 产品入口](https://eda.sw.siemens.com/en-US/ic/questa/) | 官方 Questa 产品渠道 | 无学校授权时，从官方销售/支持渠道确认发行版、授权和可否评估；未承诺个人免费许可或固定试用天数 |
| [Aldec：Efinix IP 仿真演示](https://support.aldec.com/en/support/resources/multimedia/presentations/2303) | Active-HDL 17 与 Efinity 2025.2 的流程和库支持 | 第二选择的兼容性依据，2026.1 另测 |
| [Aldec 官方评估许可入口](https://support.aldec.com/en/downloads/license_request) | 注册/登录后可以申请免费评估许可和访问产品构建 | 备用合法评估渠道；具体版本、资格、功能和期限以签发为准 |
| [Efinix 官方支持中心](https://www.efinixinc.com/support/) | 提供 Efinity 免费许可证 | 不能替代 Questa/Aldec 的许可；可请 Efinix 确认当前 IP 的仿真器版本 |

本次只查阅资料，未注册账号、提交申请、发送邮件、购买、下载或安装软件。

## 免费工具的边界

- **Icarus**：保留为普通 RTL 的可选工具，不作为这批受保护 IP 的主仿真器。旧[申请](REQUEST_SIMULATOR_20260923.md)未获批准。
- **Questa–Altera FPGA Starter Edition**：[官方页面](https://www.altera.com/products/development-tools/quartus-prime/questa)确认有免费的一年期、可续期许可；[许可中心](https://www.altera.com/support/support-resources/licensing/support-center)提供 SSLC 获取步骤。但本轮未取得允许本 Efinix 工程用途的明确条款和当前 IP 的兼容验证。不能仅凭“免费”或产品名称相近认定适用，也不据此断言其用于 Efinix 必然违法。暂不作为主选。
- 本轮未找到并验证“长期免费、已获许可、支持当前全部加密 IP”的完整方案。

## 获取前需要确认的信息

交给学校管理员或厂商核对：Windows 11 x64；Efinity 2026.1.132；FIFO 8.1；模型保护工具 QuestaSim 2023.4；需要 SystemVerilog 和 Efinix 受保护模型仿真。请其给出可供授权的精确版本/build、系统支持、许可功能、期限、并发席位、竞赛使用范围以及官方下载入口。后续加入 DDR/CSI 时另附准确 IP 版本。

管理员提供的许可证文件、服务器地址和身份资料在本机安全配置，不写到 Agent 文档或聊天。仅记录“来源/版本/期限已核对”和诊断是否通过。按该版本官方安装说明选择许可变量；不把 ModelSim 10.1c 的变量要求直接套给新版 Questa。

## 验收闸门

1. 冻结合法来源、精确版本/build、许可适用范围、安装包签名/哈希及安装位置；额外下载/安装按用户要求另行声明并获得批准。
2. 在独立工作副本以进程级环境完成许可签出和归还，保存脱敏结果。
3. 普通 RTL 测试：复位、时钟和输出断言通过；故意失败断言必须返回失败；实际生成并打开波形。
4. 用当前 Efinity 原语库及当前生成的 FIFO/BRAM 模型完成编译、展开、运行；不得跳过保护区或用空模块代替。FIFO 检查读写顺序、满空、复位、异步时钟和位宽转换；BRAM 检查读写与配置的读延迟。
5. 对原语/LED 最小网表执行行为检查；需要时再验证 SDF 标注。库缺失、黑盒、保护错误、断言错误或超时均不计通过。
6. 最终选定 DDR/CSI/MIPI IP 后，逐一使用匹配版本模型和测试台回归；模型缺失则保留阻断，不以普通 RTL 测试替代。

只有上述对应范围的实际日志、结果与波形通过，才能把该范围的仿真环境标为 PASS。数据库、控制面状态闸门和人工硬件验收仍是独立条件。
