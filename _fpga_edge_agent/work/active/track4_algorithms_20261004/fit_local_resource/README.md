# 七类FIT核局部宽整数优化

阅读顺序：inputs/design-TRACK4-FIT-LOCAL-RESOURCE-001.md的B整体行为→C/D接口与相容性→E中文操作→F数值/沿契约→rtl/fit_core.sv的三个helper和原plan→tb/独立数学→实际runs。所有源码、模型和工程在本独立work，r3/r4及原HDK只读。

本次有6份自写/适配业务与验证文件：FIT RTL、TB、仿真/综合两个运行器、XML/SDC。4个scalar/pkg/bridge RTL和2份独立数学脚本按原字节复制；第7份旧FIT参考把module声明名改为fit_core_original并将LF换行为CRLF，规范化换行后其余语句完全相同，用于同一TB展开，生产MAP只选择一个top，不包含两份FIT硬件。原完整fit_core另保存在inputs中，10份输入先冻结。

## 整体与局部

req622在valid&&ready的上升沿接受，rsp585保持到真正ready，ID176不缩短。原kinds11/12/13/14/15/17/18、nearest-even数值、拒绝/退化/缓存、37取消和35复位场景全部保留；原槽写入、标志、状态、scalar调用及所有always_ff语句在规范化换行后完全相同；原始字节不同，详细更正见source-binding-note.md。

只替换有证明范围的局部组合表达式。work_slot仍逻辑192位；原canonical使每槽只有N个低位及一个高符号独立。local_negate对槽0/1/2/8/10/11分别取N=67/89/88/132/37/32，先形成signed N+2的两份高符号加N低位，再取负，最后显式符号扩为192；这是为了保留最负值取负的正幅度，不能先截窄后取负。其它槽默认保持原完整192负号。输出字段本来规定32位的负号不改。

coordinate_last用signed12承载0..2047并减1，再符号扩192；包括v0得到全ones的原位模式。TLS的两个坐标命令之外没有改变。line kind14 step24复用原line_odd_boundary(q21,upper)形成22位2q±1，资格/分支和q0覆盖次序仍原样。不移动提交沿或插入流水。

先前1791 FF来自已有STATS父工程上下文，不能推广到任何独立FIT top。本轮两个独立FIT实际网表均为3072个work_slot FF、8357总FF；原canonical语句和父级优化不能替代本次真正报告。本轮未重写存储，FF没有减少，后续需另按新实际证据设计存储优化。

## 已完成的实际验证

fit_resource_001为当前源Questa/Python完整运行，compile/elab/实际vsim/audit全部exit0，finished=true；fatal出口探针按预期exit1，正常测试没有fatal或error。独立原fit_vectors生成14517组固定完整向量，SHA FE000FEB65F8C1DD073734BE4E47994E72097686B14B0AFDF86AC8B41EF1F897；未改数学模型、期望、种子、阈值或容差。audit-core全部14517通过，max_forming=8234是所测场景最大形成周期，不能扩写为整个识别任务耗时。

旧核和新核在同一刺激下51195951个非reset沿逐一比较req_ready/rsp_valid/quiet、完整有效585返回、子请求/返回valid/ready、622/585正文、真实403桥返回，以及122639次合法局部提交的完整192值/目的/资格，全部相同。4486个额外helper角点、固定随机和全部2048个坐标值检查通过，固定seed43106025。

原协议账accepted14594=consumed14559+reset_aborted35，numeric14517、cancel_checks37、reset_checks35、cache_checks5，parent/bridge/child状态掩码分别2047/63/524287，覆盖原全部11/6/19状态。复位作废与正常结果分账，没有把未返回义务当成功结果。实际vsim 20:30:54Z至20:40:27Z，独立审计20:40:38Z完成，无超时；10份运行快照由运行器结束核SHA，原输入10份也保持不变。

## 综合和阅读边界

fit_new_map_001与fit_old_map_001实际MAP退出0，使用同一Ti60F225/I3、100MHz组件时钟、speed、retiming0/seq_opt0、相同13源快照。只选择fit_core或fit_core_original top。旧核44405 LUT4/3657 ADD/8357 FF/2 DSP48；新核43501 LUT4/2696 ADD/8357 FF/2 DSP48，RAM10/SRL8两者均0，由实际网表原语佐证。减少904 LUT（2.04%）和961 ADD（26.28%）；FF/DSP不变。这是独立完整七类FIT top，不是旧STATS父工程，不能直接用它的比例换算整个STATS或全FPGA收益。两个MAP均8项warning：5个冗余循环信号，3个异步小cache逻辑映射；err均仅工具头，完整报告/网表保留。每份13个源/快照结束SHA相符；实际netlist/rpt摘要与差值见resource-map-comparison.json。

仿真时钟25MHz仅规定采样事件；组件100MHz约束不是实际100MHz时序通过。无本组件PNR/STA/板级引脚/bit、综合网表动态或硬件证据。这不是完整复杂识别算法；原目标仍需完整轮廓/多目标识别、生产摄像头/DDR/显示/root联合，以及全机资源/速度/引脚/CDC/布局布线/最终bit。理解验收待用户实际作答；持续自主软件和本地审计例外适用，正式PG/H0/状态不改。

运行入口：既有PowerShell7执行scripts/run_resource_sim.ps1 -RunId 新名；当前源PASS后执行scripts/run_resource_map.ps1 -RunId 新名 -SimulationRun 已通过运行名 -Variant New或Original。新RunId不可覆盖，每次源/日志/真正PID/参数/退出码均保留。
