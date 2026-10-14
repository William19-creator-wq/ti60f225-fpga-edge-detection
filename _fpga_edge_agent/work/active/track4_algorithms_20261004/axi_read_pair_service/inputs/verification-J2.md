# J2：公开AR出现时刻的补充观察

2026-10-10，READY_FOR_REVIEW，持续自主软件/local audit授权。pair_service_002真实TB38场景完成、vsim退出0，独立audit在case19/cycle7253失败：前一正沿NBA后AR已经公开，TB在随后的负沿取消；preedge-only账首次看见AR和cancel同时为1，错误地认为这是取消后新提AR。生产RTL及既有“已公开AR取消后保持”契约不变，失败保留。

局部草图：TB在每个正沿后1ns追加公开AR valid/完整49/rst/cycle的 exposure 记录，仍在下一负沿改变刺激。独立检查器从前一沿后曝光判断本次AR是否已经公开；只有与完整49一致的已曝光/已pending AR能在stop之后继续。正常期全部未知仍拒绝，不使用DUT层次、state或内部客户端信号。

保留所有原数值/保持/边界/38场景与门槛，额外逐场景检验物理AR数：非法/PLAN取消与PLAN停用0，AR取消/R取消与AR/R停用都只能完成原一个burst，RESP错误不得追加burst。此补充旨在恢复时间观察一致性，不减少验证标准。RP02/03→公开AR前后沿→TB exposure及reference→RPT4/5。

先保存读回呈现后修改，原10输入+本J2=11，runner guard10→11；wrapper及三deps不改。后续新运行、当前源快照，失败原日志不覆盖。整机DDR/PNR/STA/bit仍未证明。
