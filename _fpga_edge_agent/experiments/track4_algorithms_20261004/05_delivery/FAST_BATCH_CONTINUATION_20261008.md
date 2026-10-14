# 2026-10-08 持续实施检查点：完整Canny软件链路

用户“当你统計完后自行进行, 无需我的批准”持续有效。后续按中文局部草图→源码→单独验证→组合验证→资源性能→生产工程推进，不再逐模块索取批准。当前无等待审批，整体五项基础/六项高阶目标仍ACTIVE。正式PostgreSQL未配置，本次沿用已批准本地审计；正式状态/原HDK/硬件未改。

## 实际新增和验证

| 本地work单元 | 新增业务/参考/TB/工程/脚本文件 | 实际验证 | Efinity组件MAP |
|---|---:|---|---|
| state_cache | 8 | 1080p地址域11528次操作、最低几何8464次、十类取消；最终分类外存独立比对 | 8RAM，2097FF，6665LUT，0DSP |
| work_queue | 8 | 1080p域6693条指令/2220入出队，8.29MB内存；小图768完整容量、两bank满、prefix1…15、六类取消/错误 | 4RAM，2412FF，3523LUT，0DSP |
| canny_memory_join | 9 | 实际cache+queue+HY：30小图23040像素、13255原子claim、11取消；4幅1080p8294400像素 | 12RAM，6071FF，10872LUT，0DSP |
| canny_full_sw | 12 | 原R2→分类writer→实际HY→结果writer：28小图18088像素、1幅1080p2073600像素；梯度/CS592/内存/FIFO逐位比对；十取消/三安全error；writer直接18项 | 38RAM，14475FF，18865LUT，166SRL8，0DSP |

新增37份，连此前已经登记/验证的70份，共107份业务及验证工程文件；这是文件计数，不是107个算法模块。共享依赖及GUI镜像不重复计数。独立参考、测试向量、失败尝试、源码hash、开始/退出/超时均保留。

新增四个登记包在 `_fpga_edge_agent/artifacts/staging/`：CANNY-STATE-CACHE-COMPONENT-20261008-v1.1、CANNY-WORK-QUEUE-COMPONENT-20261008-v1、CANNY-MEMORY-JOIN-COMPONENT-20261008-v1.1、CANNY-FULL-SW-COMPONENT-20261008-v1.1。前述FAST三包的仿真/综合/PNR/STA/bit登记继续有效，没有改其冻结快照。

## 人工观察的顺序

1. 从[完整Canny中文入口](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/canny_full_sw/docs/README.md)看整体数据流、三授权区、96bit身份、旧pixel错误收尾和实际证据。
2. 再读[实际内存组合](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/canny_memory_join/docs/README.md)，理解cache claim和queue append同沿、HY push只确认、FLUSH实际关闭与RPC owner。
3. 看[队列](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/work_queue/docs/README.md)和[缓存](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/state_cache/docs/README.md)，最后进入各RTL的内部语句组织。
4. 在Efinity打开[完整Canny组件工程](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/canny_full_sw/project/canny_full_sw_component.xml)，可看到Ti60F225/I3、实际25份RTL、100MHz目标与38RAM综合报告。内部存储/状态端口将由生产top连接，不能把全部931输入/1568输出直接指定板卡pin。
5. 再按runs/中的suite-result/reference-audit/source-manifest与artifact-manifest检查实际结果。登记包reference-layout保持数学参考的原导入目录关系，离线导入/6×5独立smoke已通过，未在包内写bytecode。

## 证据边界及接下来

完整Canny 1080p阶跃实际34854652拍，1078边缘；行为64B存储含随机停顿，不是实际DDR帧率。内存组合四幅1080p都是稀疏/无seed场景；最重1080p连通仍需性能优化与另run。100MHz组件SDC只是目标，未进行这些新内存组件的生产pin/PNR/STA/bit。没有把行为DDR当板载器件动态模型，也没有因为局部成功宣布全十一项完成。

下一顺序：RAW10真实行RAM/reflect101接已通过插值核 → 摄像头生产配置/接收/CDC及完整RGB源 → DDR实际AXI桥/帧服务和显示预取/TMDS/冻结恢复 → 候选质量、圆/旋转矩形/遮挡/多目标识别及标注 → 共享算术/总资源/处理时间优化 → 单一生产工程引脚/时钟/综合/PNR/STA/总bit。可软件实现的继续自主完成，原始硬件资料只读。

DDR2Gb/x16匹配动态参数/PHY证据仍有资料缺口；这不阻止算法客户端、RAW窗口、帧管理、显示和识别软件继续实现。尚未完成的也包括这些与资料缺口无关的实际编码/组合/性能工作。STATS原单包52619/60800 XLR且只证明25MHz，整机必须共享/优化，不能把各组件利用率简单相加后宣称资源适配。
