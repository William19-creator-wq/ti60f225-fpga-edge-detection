# Q1仿真注错编码核查补充 v1.4

在生成新TB前，已实际全文读取冻结axi_read_byte_slave.sv。源码实际fault==1注入RRESP=2（可按正确ID/LAST排空），fault==2才在首R拍注入RID xor1。因此Q1中fault_mode=1对应wrongRID的假设不成立；原Q1及基线保持历史，未曾执行该错误测试。

本卡仅把Q1输入明确为fault_mode=2，不改RTL、协议、接收/释放判据或当前HD/MAP源码。TB成功仍须真AR/R握手且RID!=2、组合永久Q、真实OFFER/source保留、匹配cancel后无closed/response；错误响应的可恢复路径已由此前真实leaf和联合取消证明，不能当本次未知身份目标。

中文操作、SC27/IF22/25/ST24及真实owner链路沿Q1；保存读回呈现后自主生成tb_scan_faults.sv，baseline-v1.4原28+本卡共29。持续软件授权/本地审计例外有效；READY_FOR_REVIEW Q1经Q2修订，非仿真已通过。
