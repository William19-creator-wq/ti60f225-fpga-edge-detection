# SCAN-002 联合测试结束观察修订 v1.2

scan_small_001实际Questa exit0，18帧/17完整、8次切换、70 owner事务、7真oldClosed/RETIRE、1候选错过VS和2取消、20个通知背压周期；RTL无error/Q/underrun。独立owner审计PASS，但scan独立参考在end要求transport=None时拒绝，整套仍FAIL。

证据：末次receipt/reserve后transport-live下降由core寄存器NBA更新，TB等待core_idle真后在下一个video negedge立即关闭日志；该真实core下降尚未在下一core posedge观察并记录，所以参考仍保上次live1。不能据已经写finished放宽关闭要求。影响ST25证据完整性/结束观察，不影响M1/M2/M3接口、RTL或核心关闭判据。

中文操作：仍先等消隐、3真prepared、core_idle、transport_live0且AXI slave_idle；停止video时钟之后继续两个core negedge，让正常core posedge观察器记录末次ACK/live下降，再关闭输出和日志/写metrics。最终三银行和active有意保留，仍不声明已释放。参考end的burst0/current无/service无/transport无要求保留，增加失败状态诊断；收集watched模式在事件流中完成，避免HD审计二次整体读大日志，不改变任何像素或协议期望。

保留001源码快照、原日志与失败原因，新RunId002；baseline-v1.2=原26+此卡共27，旧baseline保持。本地审计例外及用户自主软件授权适用；READY_FOR_REVIEW v1.2，保存读回呈现后仅改TB结束观察、参考诊断/等价流式统计和runner基线。MAP未执行，map脚本metadata top先纠正为实际XML顶层display_scan_component（最初文本替换成display_scaner，尚未使用），不影响仿真源码。

追踪：SC26/27→E2 ACK真闭合→TB结束观察→ST25完整证据；不删除失败、不改closed判据，不宣称当前综合/HD或整体完成。
