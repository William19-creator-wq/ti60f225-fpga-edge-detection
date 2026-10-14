# 门级编译辅助检查：最终限定审读

2026-10-04。纯设计/只读审阅；NOT_APPROVED / NOT_RUN。

- [设计 v1](../../../../planning/design-TRACK4-GATE-COMPILE-001.md)：14,171B，SHA256 `979390F1DA7E2144C67257259126F79EDDE4BCD95EBDD6A55727FC6CA1ED0C20`。
- [16 份候选基线](../../01_baseline/gate-compile-inputs-v1.json)：6,907B，SHA256 `FF0474AF44F6BBF7826E8B0BDD2F94DED3201A30FE6B2DCF9E068E524579240B`；输入总量 23,556,078B。

root 已全文读回设计 A–L 和 JSON，核对 15 个模型的路径、长度、hash 与原 C0-questa-inputs 的真实 vendor 输入完全一致；完整网表匹配既有获批官方 debug 产物。16 条输入/复制路径唯一，未来工作目录未创建。root 实际读回 C1 合法时钟报告和 CSI 仿真路线报告，二者没有被改写为新工具 PASS。

协议审阅者 `/root/r2_terminal_protocol_review` 实际全文读取设计 99 行、清单及 CSI 报告 100 行，绑定同一最终 hash，报告有限审阅无新增实际反例；确认 source view、独立本地库、失败停止及新指定许可边界一致，未扩张至 v1.3 修复或 C1–C3，未把展开当成功能通过。其本轮全程只读，完成后停止。

该设计可以作为有限兼容性实验的 READY_FOR_REVIEW 候选。原 RTL 的 CSI key 失败、原 PNR 的 USER1 失败、完整十一项尚未实现，以及 PHY/时钟/功能/时序缺口仍保留。原 v1.3 审批对象未变化；新门级编译必须有自己的指定批准及本地审计许可，不能继承旧 source view 的执行许可。

本轮新增的是证据、设计和纯数据基线，没有新 work、编译库、业务代码、可执行脚本、模型修改、TB/激励或工具构建，未写正式状态/数据库或操作硬件。
