# 时序检查脚本修订草图 v1（2026-10-08）

授权：FAST 批次批准及用户“当你统計完后自行进行, 无需我的批准”。只调整工作副本内检查脚本，不改变 RTL、端口、数值、时钟及约束。

先整体：继续检查源事务→运算→结果→观察器的真实寄存器路径，不能把非空集合误当作有路径；生成 bit 前逐份读取报告，要求实际路径和非负 setup/hold。

再局部：普通 FF 使用 Q/D；被 Efinity 2026.1 合并进 DSP 的乘法寄存器按映射 DSP cell 查询。统计 S1、S3 使用实际 mult_199…203、n3232/n3270 组；子运算返回使用网表中的 fitting/child_rsp_body Q，不能错误地从 full 中间结果越过 response_value 寄存器。角度乘法使用 arithmetic/multiply/n5_pp_*；两块 ROM 分别检查地址→RAM 与 RAM→constant_words，随后常数→乘法/系数寄存器。

交接：这些集合只描述同一网表的实际实现名称。仍检查唯一 25MHz 时钟、复位级间/复位到核心、内部无未约束端点、四引脚及电压。不新增假路径或多周期例外。

实现/验证次序：保留原失败/缺报告尝试→修改 Tcl→新的完整仿真快照→新的物理运行→检查实际报告→bit/hex→立即登记。Tcl 改动需要新的来源绑定；RTL 不变，不声称此前失败记录通过。

追踪：ST-T12/AN-T physical → scripts/postroute.tcl → 新的 Sta/stdout + setup/hold 报告 → release-gate.json。未找到路径即阻止产物发布。
角度物理读回细化：cross_positive 选择 lo/hi 的使能，lo/hi 的 D 数据来自 mid（或mid+1），所以 first_product→lo/hi D 本来没有真实路径。改为分别读取 mid→lo/hi D（数据）及 first/second_product→lo/hi CE（比较控制）；不能把不存在路径删掉后冒称原检查通过。另补 signed_product→projection_sum，验证完整投影乘积到加法交接。检查报告须逐项非空；控制CE路径单独标识。
产物审核/登记辅助脚本草图：先读当前源码快照与各阶段退出证据；从本次 Tcl 取得明确命名路径列表，逐份核对 setup/hold 存在、有实际 Path End 和非负 slack，CE 组单列；从全局 timing/resource/pinout/PT 核目标、预算、25MHz、四pin、电压和4mA；角度两 RAM 还逐word核对 mapped INIT 与实际 .mem。成功才输出 release-gate，并对全部证据/路由计算 SHA。登记只在 Bit 退出0且 gate 不漂移后复制 bit/hex、快照、实际运行日志和报告，保留原输出，计算整个 staging manifest，立即追加事件，不操作硬件/正式DB。失败不创建PASS gate；登记目标已存在则拒绝覆盖。本辅助脚本在 work 下，不替代实际物理工具。