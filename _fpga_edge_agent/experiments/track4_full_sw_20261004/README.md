# 赛题四完整软件实验：阅读入口

> 历史路线记录：2026-10-04 曾按用户要求暂缓具体 DDR 器件模型/PHY/校准与 IP 预检，采用[算法优先路线](../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)。随后用户明确“允许使用板卡现有 DDR3”，撤销此前 DDR 排除限制；只用板卡现有资源仍有效。当前以[算法实验入口](../track4_algorithms_20261004/README.md)及[整合设计 v0.7](../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md)为准。本页旧版本条目保留其历史范围，辅助预检不重新成为独立算法的串行前置。


- 任务：TRACK4-FULL-SW-001；主计划版本：v0.21，整体布局/交接仍为v0.1；日期：2026-10-04。
- 已有内容：结构化文档、需求/基线、整体布局/交接；FRONTEND v1及观察路线；FRAME-MANAGER v0.1/CANNY v0.4局部稿、窗口/流段、存储、父任务/方向/writer中文草图与12区地址算术；DDR-SERVICE v0.1完整段/授权/封口/恢复草图与DDR/平台/RAM来源复核；RECOGNITION v0.1四阶段/圆矩形/原图核验/ANN中文草图和地址预算；PLATFORM v0.1时钟/复位/CDC/引脚草图及原理图、摄像头来源复核；CAMERA v0.1配置/RAW10/window/writer/真实边界与关闭草图；DISPLAY v0.1行预取/固定scan/render/冻结与关闭草图；CONTROL v0.1四键/配置/生命周期/观察草图；CONTROL-JOIN v0.1独立R/阶段/配置联合草图；DATA-JOIN v0.1完整身份/阶段/借用/回收联合草图；RECOGNITION-NUMERIC v0.1数值/记录与本地官方来源依据；RECOGNITION-ALGORITHMS v0.1候选/分段/核验/去重/ANN、RECOGNITION-EXECUTION v0.1内部执行与RESOURCE-SERVICE-BUDGET v0.1整机预算诊断。
- 完整目标仍是十一项软件实现直到bit/hex。业务 RTL、功能脚本、可执行测试、testbench、综合和布局布线尚未开展。
- 主任务文档：[design-TRACK4-FULL-SW-001.md](../../planning/design-TRACK4-FULL-SW-001.md)，按现有 PLAN_TEMPLATE 建立；本目录不创建另一套项目规则或审批来源。

## 阅读与生成次序

| 次序 | 分类与入口 | 先回答的问题 | 当前内容边界 |
|---|---|---|---|
| 00 | [需求与决策](00_scope/requirements-and-decisions.md) | 为什么做、做哪些功能、哪些选择已确认或被撤回？ | 五项基础、六项高阶、用户选择和派生要求 |
| 01 | [前置条件与证据](01_baseline/preconditions-and-evidence.md) | 依据哪块板、哪份源码、哪些已验证事实？ | 原资料只读、归档 SHA256、模型和约束缺口 |
| 02 | [整体设计布局草图](02_system/overall-design-layout.md) | 整机如何工作、数据/配置/错误如何流动？ | 本轮主要交付，含纯文本图、Mermaid 图和中文整体操作草图 |
| 03 | [模块交接与组合检查](03_interfaces/handoffs-and-composition.md) | 上下游怎样交接、帧归属与所有权怎样保持？ | 系统级接口语义；最终 RTL 端口和逐拍契约留到局部设计 |
| 04 | [局部设计目录](04_local-designs/README.md) | 各模块内部状态、数值、周期与操作是什么？ | FRONTEND v1待批准；FRAME-MANAGER v0.1/CANNY v0.4/DDR-SERVICE v0.1/RECOGNITION v0.1/PLATFORM v0.1/CAMERA v0.1/DISPLAY v0.1/CONTROL v0.1/CONTROL-JOIN v0.1/DATA-JOIN v0.1/RECOGNITION-NUMERIC v0.1/RECOGNITION-ALGORITHMS v0.1含引用/数值/窗口逐沿/存储端口/FSM/父job/顺序writer/精确连接/排空草图，仍有阻塞 |
| 05 | [评审与阻塞](05_reviews/review-and-blockers.md) | 什么已检查、什么阻塞实现、在哪里等待批准？ | 整体草图检查与实施门槛分别记录 |
| 06 | [实现管理目录](06_implementation/README.md) | 获批后代码放哪里、如何追踪与恢复？ | 仅说明；真实实现只能放在独立 work 副本 |
| 07 | [验证计划与双向追踪](07_verification/verification-plan-and-trace.md) | 每项要求将如何验证、期望来自哪里？ | 文字场景、需求—模块—接口—测试追踪；测试均未运行 |
| 08 | [交付目录](08_delivery/README.md) | 如何冻结工程、报告、时序和比特流？ | 交付定义；本轮无 bit/hex |
| 09 | [人工审阅与观察目录](09_observations/README.md) | 如何记录实际审阅、波形观察和后续硬件反馈？ | 没有虚构理解验收或硬件观察 |

生成顺序是 **需求/基线 → 整体行为与布局 → 模块交接和组合检查 → 局部详细设计与中文草图 → 指定版本/范围评审批准 → 对应实现 → 实际验证 → 最终一致性检查与交付**。实现遇到影响契约的变化时，先回到对应设计层修订。

最新只读证据：[DDR地址/写响应/旧帧缓存限制](01_baseline/ddr-address-and-completion-evidence-v1.md)、[PLL/复位/SDC/引脚来源](01_baseline/platform-clock-pin-evidence-v1.md)。00需求页中“本轮止于整体”属于整体v0.1历史阶段；当前目标以本入口及主计划为准，仍是完整11项到bit/hex。00/02/03作为已冻结FRONTEND输入保留，最新组合缺口明确记录在FRAME-MANAGER稿和05，不将旧草图当作已闭合证明。

## 边界与状态

这是隔离的软件工程实验文档，采用 V4 Ti60F225 与 SC431HAI 彩色 MIPI 的假定基线；尚未确认实物。正式 PROJECT_STATE、TASK_LEDGER、数据库及其他任务批准保持原有事实。

识别尺寸、数量、遮挡、对比度和噪声的两组先前建议，已被用户纠正为由 Agent 根据整机性能与资源权衡的候选参数。它们不是硬验收范围。1080p、完整功能、完整 Canny 和另行选择的识别质量目标继续保留。

整体草图完成不等于整机 READY_FOR_REVIEW，也不等于用户批准业务实现。FRONTEND局部状态以其[主设计](../../planning/design-TRACK4-FRONTEND-001.md)为准；DDR匹配模型、受保护IP仿真兼容、合理约束及其他局部设计仍需完成。[官方DDR模型获取申请](../../tools/REQUEST_DDR3_MODEL_20261004.md)为PENDING，尚未联网或下载。继续从05阻塞和04各批设计推进，不能以局部完成替代整机。

最新共享存储设计：[DDR-SERVICE v0.1](../../planning/design-TRACK4-DDR-SERVICE-001.md)与[实际读稿审查](05_reviews/ddr-service-review-v0.1.md)。先看B/C整体，再D授权/permit/终结与相邻差异，E逐段/封口中文草图，F时间与期限，G/H验证追踪；LOCAL_DESIGN，有阻塞。Canny44+服务17=61 RAM10仅已列候选小计，其他模块和真实综合/STA仍待补齐。

最新识别设计：[RECOGNITION v0.1](../../planning/design-TRACK4-RECOGNITION-001.md)→[实际读稿审查](05_reviews/recognition-review-v0.1.md)。先读B/C整体，D交接/工作区与ANN，E八项中文草图，F数值/58块容器预算，G/H验证追踪；LOCAL_DESIGN，有8项阻塞。全部已列119/256 RAM和约90MB地址算术均未综合／仿真，不能作为识别95%或处理fps证明。

最新平台设计：[PLATFORM v0.1](../../planning/design-TRACK4-PLATFORM-001.md)→[实际读稿审查](05_reviews/platform-review-v0.1.md)。先B/C整体，再D时钟/pin/8交接/CDC，E暖保持、scope镜像与两阶段恢复8草图，G/H的16文字场景；LOCAL_DESIGN，8项阻塞。[引脚证据v2](01_baseline/board-pin-source-evidence-v2.md)与[摄像头来源v1](01_baseline/camera-source-and-phase-evidence-v1.md)区分原文、源码、条件推断和未知。149RAM仅已列候选小计，不是全机综合或性能证明。

最新相机设计：[CAMERA v0.1](../../planning/design-TRACK4-CAMERA-001.md)→[窗口/writer中文附件](04_local-designs/camera-window-and-writer-sketches-v0.1.md)→[来源v2](01_baseline/camera-csi-and-config-evidence-v2.md)→[实际读审](05_reviews/camera-review-v0.1.md)。先B/C整体，再D资格/ARM/NORM/closure/父差异，E配置→接收→转色→写入→live→fence/返还→恢复，G/H的24主场景与12附件场景；LOCAL_DESIGN，有8阻塞。162RAM仅已列小计。下一步完成显示/控制与联合端口吸收；业务实现与真实软件验证仍须对应批准和依赖闭合。

最新显示设计：[DISPLAY v0.1](../../planning/design-TRACK4-DISPLAY-001.md)→[取数/扫描中文附件](04_local-designs/display-fetch-and-scan-sketches-v0.1.md)→[来源](01_baseline/display-hdmi-and-fetch-evidence-v1.md)→[读审](05_reviews/display-review-v0.1.md)。先B/C整体，再D视图/ROW/实际SELECTED/CLOSED/控制，E八操作、附件逐沿与F/G/H；24主场景＋15附件场景全部NOT_RUN。三行bank替代旧FIFO后174RAM仅预算，保持LOCAL_DESIGN及8阻塞。用户指定[VF/Demo补充证据](01_baseline/vf-demo-supplemental-evidence-v1.md)确认已有DDR模型/PHY和可读TMDS，2Gb参数依赖仍缺。下一步控制与全机联合吸收。

最新控制设计：[CONTROL v0.1](../../planning/design-TRACK4-CONTROL-001.md)→[人工操作草图](04_local-designs/control-human-operation-sketches-v0.1.md)→[四键/复位来源](01_baseline/control-keys-and-reset-evidence-v1.md)→[读审](05_reviews/control-review-v0.1.md)。先B/C整体、D配置/来源/版本与父差异、E消抖/有界D/P/C/T/R/AON复位、G/H验证追踪。8要求/8IF/8OP/10INV/24主场景均NOT_RUN，8阻塞保持LOCAL_DESIGN。旧KEY1直接复位必须解绑，四键/两LED来源不等于新引脚工程通过；0新增RAM、已列174只是预算。DISPLAY阶段45MD审计保存在[历史快照](05_reviews/document-checks-display-v0.1.json)，该阶段49MD检查仅文档；下一步联合接口吸收。实物步骤仍在本次bit之后。

最新控制联合设计：[CONTROL-JOIN v0.1](../../planning/design-TRACK4-CONTROL-JOIN-001.md)→[阶段草图](04_local-designs/control-join-phase-sketches-v0.1.md)→[读审](05_reviews/control-join-review-v0.1.md)。只在主稿J列的控制差异中覆盖旧候选，旧父稿/hash保留；独立R669、stage914/ACK920与snapshot1353/1359；成功屏障、COMMIT承诺、失败隔离、保冻结算法切换和result配置锁明确。24主场景＋8附件走查全部NOT_RUN，6阻塞保持LOCAL_DESIGN。前49MD CONTROL检查存为[历史审计](05_reviews/document-checks-control-v0.1.json)，当前52MD仅文档审计；完整数据/关闭联合端口及依赖继续推进。

最新数据联合设计：[DATA-JOIN v0.1](../../planning/design-TRACK4-DATA-JOIN-001.md)→[实际读审](05_reviews/data-join-review-v0.1.md)。B/C整体→D完整消息/有界合同→E八中文草图→F预算→G/H24文字场景及追踪。首SOF前锁身份、START_CLOSURE788、FE三分支、LOCAL231/phase350/证书410/borrow702、PLAN_ACK528和三级关闭已明确；仅主稿J列的差异覆盖旧候选。scope11/grant25/phase20有条件上界，reader新增4RAM到178/256仅容器预算，未综合。真实外部/RC参数/最坏服务DJ-B01…05仍未闭合，B06执行前置；非READY/非批准。前52MD审计保存在[CONTROL-JOIN历史](05_reviews/document-checks-control-join-v0.1.json)，当前54MD仅文档检查，全部业务验证NOT_RUN。

最新识别数值补充：[RECOGNITION-NUMERIC v0.1](../../planning/design-TRACK4-RECOGNITION-NUMERIC-001.md)→[实际读审](05_reviews/recognition-numeric-review-v0.1.md)。B/C整体→D记录/交接→E角度/ρ/舍入/拟合中文草图→F预算→G/H文字测试与追踪。128角边界最坏8次比较、277对称ρbin及负RNE明确，两ROM使最新已列预算178→180RAM；尚有候选覆盖/分段/配置选择与质量缺口，LOCAL_DESIGN，未批准。[本地官方接口依据](01_baseline/vendor-interface-contract-evidence-v1.md)说明25µs配置后复位、异步LOCKED和LVDS时钟限制，未关闭真实IP合同。前54MD检查保存在[DATA历史](05_reviews/document-checks-data-join-v0.1.json)，当前仍仅文档检查；全部业务验证NOT_RUN。

最新识别算法候选：[RECOGNITION-ALGORITHMS v0.1](../../planning/design-TRACK4-RECOGNITION-ALGORITHMS-001.md)→[实际读审](05_reviews/recognition-algorithms-review-v0.1.md)。B/C整体→D接口/PROFILE/互斥池→E八中文操作→F工作上界→G/H18文字场景/追踪。圆有限anchor/rank采样、多半径双峰、矩形密集票/offset/run/TLS、三边歧义、量化membership/精确去重及字形明确；漏检/负例/失败全部参与质量，不恢复旧硬边界。最新225RAM仅已列预算，AG-B01局部执行和B02全机预算/真实服务界未闭合，LOCAL_DESIGN；测试、综合、布局与bit均NOT_RUN。前57MD数值审计保存为[原字节历史](05_reviews/document-checks-recognition-numeric-v0.1.json)。

最新识别执行设计：[RECOGNITION-EXECUTION v0.1](../../planning/design-TRACK4-RECOGNITION-EXECUTION-001.md)→[实际读审](05_reviews/recognition-execution-review-v0.1.md)。B/C整体→D job/表/池→E预约/P1五遍/P2六遍/精确coverage/VC与FINAL/连续ANN→F预算→G/H15文字场景/追踪。105识别RAM合全机已列225，29168bit仅局部容器；新增submask借旧NMS/PAIR，无RAM增长。原AG-B01内部执行由本稿细化，B02全机预算/真实服务、B03质量NOT_RUN及B04外部/联合/批准仍待解决；保持LOCAL_DESIGN。前59MD算法检查存[原字节历史](05_reviews/document-checks-recognition-algorithms-v0.1.json)，全部业务验证仍NOT_RUN。

整机预算诊断：[RESOURCE-SERVICE-BUDGET v0.1](../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)→[实际审阅](05_reviews/resource-service-budget-review-v0.1.md)。先B/C看容量与服务结论→D查唯一RAM/FF/消息→E读期限/优化中文草图→F单位/时钟→G/H文字验证和追踪。225RAM只包括自写模块；全宽FF直译和显示/识别工作量存在明确风险，当前热冷布局、实际IP及服务界仍未闭合；不是综合/仿真通过或新实现批准。前61MD执行检查保存为[原字节历史](05_reviews/document-checks-recognition-execution-v0.1.json)。

新增物理布局入口：[STORAGE-LAYOUT v0.1](../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)→[实际审閱](05_reviews/storage-layout-review-v0.1.md)。整体→RC/DP地址→读写/固定slot/取消中文草图→数值→验证追踪。RC91＋DISPLAY17使自写225→207，保留各2048两类候选、三row/两份pair holding及完整关闭语义。当前未选择的DS/PL串行另加8，不能混为已实现。V4旧DDR39含桥17；VF/Demo有4Gb模型/工程/约束，缺匹配2Gb参数头。12新增文字场景NOT_RUN，整机资源/IP/service与指定批准仍待闭合。上一轮预算审计存[历史](05_reviews/document-checks-resource-service-budget-v0.1.json)；软件/综合/STA/bit均未完成。

当前精确布局版本[STORAGE v0.2](../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)→[审閱](05_reviews/storage-layout-review-v0.2.md)：六命名沿≠II6，新DENSE最早II5；原两336保持及低WE后配对高WE保留；父覆盖按J。[上一布局审计](05_reviews/document-checks-storage-layout-v0.1.json)保持原字节。

既有 [IP 预检实录](05_reviews/ip-precheck/RUN_REPORT.md)已按 v1/v1.1/v1.2 及限定本地审计例外执行，C0 最终采用获批 92 输入，终态为 TERMINAL_WITH_FAILURES：综合、官方调试合并及 PT 通过，PNR 在 USER1 缺端口的 packer 阶段失败，route/STA 未运行；C0/C2 原 RTL 编译在 CSI 保护区失败，展开及功能仿真未运行。上述结果不是完整 NORM 或全机实现证明。

后续候选：[v1.3 USER1 修复卡](../../planning/design-TRACK4-IP-PRECHECK-001-v1.3.md)与[Gate 编译检查 v1](../../planning/design-TRACK4-GATE-COMPILE-001.md)均已保存、审读，仍 NOT_APPROVED/NOT_RUN。Gate 只检查既有完整官方合并网表与 15 份真实原语模型的编译/条件展开；[来源证据](05_reviews/ip-precheck/CSI-simulation-route-readonly.md)和[限定审读](05_reviews/ip-precheck/gate-compile-design-review-v1.md)可定位其范围。这两项辅助候选不重新设为当前算法路线前置；完整十一项算法仍未批准、未实现。
