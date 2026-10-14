# v1.3 候选修复卡：root 最终限定审读

2026-10-04 18:35（Asia/Shanghai）。这是纯设计及只读审查，**READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN**。不覆盖已批准 v1.2 的真实失败，也不批准算法实现。

审读对象：

- [短卡](../../../../planning/design-TRACK4-IP-PRECHECK-001-v1.3.md)：27,269B；SHA256 `071CBC949529D834053932795750091F26EB4E40EE80EE6702BA9049269E8BD5`。
- [改前候选基线](../../01_baseline/ip-precheck-inputs-v1.3.json)：82,162B；SHA256 `344ACB1E46F545812917C6820CBD9B94DBD8B01EDF6DDD0AB2DCB29882E9B2E0`。

root 已全文读取最终短卡 A–L，解析候选 JSON，并核对两个 planned_revision_changes 的完整内容。92 条文件记录与改范围前 draft 的文件记录逐字段相同、无重复；此前对当前输入及原来源的真实 bytes/hash 核对仍有效。修复后两个 hash 都为 null，不能把改前清单当成修复后的证据。

独立只读定位确认：当前 peri SHA256 `2FF6846870EAB4FD1CF190FA11377C7DAE891A693404E7510916AFC801AA4D23`；指定 namespace/XPath 唯一命中一棵 USER1 子树，13 元素、11 pin。SDC SHA256 `18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E`；活动 USER1 引用恰 13 条，即原第 25 行最后一项 group 和第 57–68 行十二条仅 USER1 的延迟约束。拟删除范围不含 USER2 或业务端口；其余 group、约束、注释与 SDC 字节保留。

中文步骤、两文件允许差异、接口 IF05/06、验证及追踪已一致。IP-REQ02 保持原 ASYN 比较矩阵含义，保留调试引用原 D 的 C0 义务与本次 REQ07。新副本按 92 个改前输入重建，不复用旧 debug/PT/PNR 产物，保留 USER2、4096 深度和原探针/时钟域，逐阶段真实失败时停止下游。

原 CLK_25M 非数值周期、旧端口别名、相机与 USER2 时钟定义缺口、waveform 和 clock_groups 质量风险已明确保留；本卡不把它们当成已解决。Questa CSI 无 key、C1 PLL #4 regional、C2 byte 时钟及 C3 依赖仍未解决。有限修复可提交审阅，不能由此声称合理完整约束、STA/PNR 或十一项功能已经通过。

复核时新目录 `C0_user1_aligned` 不存在；未实施删节点/约束、业务 RTL、脚本、模型或 TB，未运行新构建。正式 PROJECT_STATE SHA256 仍为 `87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558`。下一步仅是呈现具体候选并等待指定版本、基线和范围的实际批准；本记录不是批准证据。
