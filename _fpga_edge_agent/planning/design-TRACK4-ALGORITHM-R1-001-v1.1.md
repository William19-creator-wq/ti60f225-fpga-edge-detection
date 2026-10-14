# TRACK4-ALGORITHM-R1-001：并行验证批次及输入修订 v1.1

2026-10-04。**READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。这是同一 R1 的有限修订卡，按 [PLAN_TEMPLATE](PLAN_TEMPLATE.md) 管理；完整行为、模块、接口、中文操作草图、语言契约、验证和双向追踪继承 [R1 完整设计 v1](design-TRACK4-ALGORITHM-R1-001.md)，SHA256 `F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00`、27440 B。下面只覆盖旧卡的输入基线、并行推进方式及本次批准对象；未覆盖的 A–L 原条款逐项保持。原卡/原基线/原审批不覆盖、不改写。

## 通用计划字段

- Goal / Target state：实现并验证成熟的灰度、中值和 Sobel 前端及其独立可观察工程，同时继续未完成的完整 Canny、识别、存储/通信、摄像/HDMI、资源/性能和整包设计。
- Current state / Gap：成熟的是设计；当前没有本次新 RTL、参考模型、TB 或功能脚本。R1 v1 的 22 项输入重新实际核 hash，21 项一致，正式 Approval Manifest 因后来的三次真实 IP 预检批准发生变化。
- Assumptions / Dependencies：1920×1080、Ti60F225/I3、V4 候选四 pin、实际25MHz；独立 R1 不依赖外部存储/CSI/HDMI/保护 IP。仍只用板卡现有资源，完整后续允许板载 DDR3。
- Open questions：现装工具和许可的当前结果只能获批执行后取得；完整十一项仍未 READY，R1 不能替代全机性能或正确性。
- Milestones / Detailed steps：读整体 v1 B/C→D 交接→E 中文步骤→F 合同→G/H 验证追踪→本卡输入核对→指定批准→生成/仿真→真实综合/PT/布局布线/时序→必要检查成功后 bit/hex→登记并停止硬件步骤。后续纯设计同时继续。
- State transitions / Validation：仅本独立实验的设计、实现和实际检查状态变化；每项 PASS/FAIL/NOT_RUN 分别记录，不冒充正式硬件节点通过。
- Artifacts and hashes / Rollback：新 [ALGO-BL-20261004-v1.1](../experiments/track4_algorithms_20261004/01_baseline/algorithm-baseline-v1.1.json) 和批准前审批快照；旧文件保留，工作副本与产物路径同 v1。
- Failure handling：基线、权限、工具、数值或时序失败保留实际前缀/日志，停止受影响批次；后续不依赖该失败的设计可继续，失败不形成成功 bit。
- Human approval gates / Completion criteria：批准指定 R1 v1.1、继承 v1 A/H 的实现及验证范围、ALGO-BL-v1.1，并明确本次本地审计例外；完成标准仍为 v1 FT-01…11、R1-T01…08 的必要实测结果及交付登记，不包含完整十一项或实物验收。

## A–H. 完整设计的继承与具体范围

原 v1 的 B/C/D/E/F/G/H 均已实际全文重读，不改变以下条款：六份前端 RTL、独立 Python 参考、五份前端 TB/局部 runner；规则 RGB 图样源、监督器、逐记录 CRC/计数、LED、复位适配和顶层；三份外壳/组件 TB、外壳参考/runner；Ti60F225/I3 实际四 pin 25MHz 的 Efinity project/peri/SDC/构建 runner；真实仿真、综合、接口检查、布局布线、时序、成功后的 bit/hex、staging 与中文操作/报告/追踪记录。新增或修改业务文件全部位于 `_fpga_edge_agent/work/active/track4_algorithms_20261004/r1/`，报告/审计/产物仍在控制面。各文件和符号以 v1 H 表为准，不顺便新增后续功能。

灰度 `floor((77R+150G+29B+128)/256)`，复制边界中值/Sobel、严格幅值阈值、两像素协议、取消/错误/保持规则、160bit 观察记录/CRC 和完整尺寸检查均不改变。25MHz/40ns、J2/P13/N14/P14 四 pin、8RAM10/≤8000XLR 设计预算、外壳每记录至少161沿和低速观察边界均保持；不能据此宣称生产 HDMI60Hz 或100MHz时序通过。

范围外保持：相机/RAW/跨域采集、HDMI、通用 RGB 对齐、实时按键调阈值、保护 DDR/CSI/DSI IP、完整 Canny/识别业务实现、软件/驱动安装或联网、正式 DB 建库/迁移/写入、硬件编程与观察。并行设计不授权这些范围外的代码实现。本批提供 T4-B2/B3/A1 的算法证据，并支持 B5 源码/约束交付，不能标成十一项完成。

## I. 基线修订与批准对象

实际差异只有旧基线中正式 `APPROVAL_MANIFEST.yaml`：原1390 B / `A582A10DDB993DFE7058AD7EDAE4688505FA1C4F4AA161BD67E35FD59A89DF45`，现5099 B / `A2CB08F30903D9324CBCEB59631AA30D5001B4EE8745222B3A76DC5A12AA1E75`。现文保存你真实批准的 IP-PRECHECK v1、v1.1、v1.2，仍没有 R1 算法批准。

修订基线保持22份：其余21份路径、内容、hash不变；仅把该项改为 [当前审批清单的冻结快照](../experiments/track4_algorithms_20261004/01_baseline/approval-manifest-before-r1-v1.1.yaml)，角色明确为“本次批准前治理证据”，不是 RTL/工具运行输入。冻结快照永不随未来批准改写。执行时必须另读正式 Manifest 的当前有效授权并记录 hash；真正的本次批准写入正式审批记录是预期治理变化，不伪造授权，也不自动改变这21份业务设计/工具来源。其他依赖变化仍按规范核查。

本次一次性批准对象：**TRACK4-ALGORITHM-R1-001 v1.1 + 所继承的完整 v1 A/H 范围 + ALGO-BL-20261004-v1.1**；包括上述源码/参考/TB/脚本/工程/约束的工作副本修改、现装工具仿真/综合/PT/布局布线/时序/成功后的 bit/hex，以及控制面 staging/报告/hash 登记。

同时需明确：仅本次独立 R1 软件实验允许本地 JSONL、报告和 Side-effect ledger 审计，PostgreSQL 未配置时不执行正式数据库或正式硬件状态转换；PROJECT_STATE/TASK_LEDGER/hardware_nodes 不改。获批后可把本次真实批准添加到现有 Manifest 的 scoped_approvals，不能扩张旧 IP-PRECHECK 批准。bit 登记后本地标记软件批次完成/等待人工硬件阶段并停止，无实体操作。

用户“可以一边验证……一边继续”确定并行方式；本卡尚未收到指定版本/范围/基线及本地审计例外的批准，不将该句话伪记录成已经批准。

## J. 变更、检查与恢复

此次只有治理证据输入冻结和并行推进说明，没有算法、外壳、接口、电气、数值、时间、存储或资源边界变化。原 R1 v1 SHA、原基线和三个原 IP 预检批准保留。恢复时读取本卡/完整 v1/新基线/真实批准与当前 Manifest，获批范围未变时不重复索取批准。

## K. 实际状态与验证

当前实际完成：完整 v1 和旧基线/审阅全文重读；22项逐个实际 hash/大小检查并定位上述唯一差异；修订治理快照/22份新基线与本卡保存读回。设计审阅依赖原 [R1审阅 v1](../experiments/track4_algorithms_20261004/03_review/review-v1.md) 所记录的真实版本/范围，本次不冒称他人全文重审本卡。

所有 FT/R1-T 功能/工具检查仍 **NOT_RUN**，没有本次业务源码、TB、功能脚本、新 work 或 bit。完整后续目标仍未完成，纯文档核对不是软件功能验证。

## L. 人工阅读与并行操作顺序

先读 [完整 R1 v1](design-TRACK4-ALGORITHM-R1-001.md) B/C/D→E 中文草图→F/G/H，再读本卡 I 的唯一输入修订与批准范围；获批后按原 L 补实际命令、GUI/波形阅读、稳定源码符号、Run ID、资源/pin/时序/bit路径及hash。后续全机设计由另一工作线继续，成熟批次验证与全机整合分别标状态。人工观察只指波形/报告阅读，不代签实体结果。
