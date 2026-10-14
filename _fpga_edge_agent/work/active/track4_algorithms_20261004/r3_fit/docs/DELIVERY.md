# FIT v1 软件交付与中文操作入口

2026-10-08。用户批准的FIT v1批次已完成：19份源码/测试/运行支持/工程文件，七类几何数值运算，独立仿真、综合、接口、布局布线、独立已布线时序及bit/hex生成登记。**完整五基础、六高阶仍未完成。** 本批止于生成并登记比特流，没有下载、硬件观察或正式数据库/状态更新。

## 先整体，再局部，再证据

1. 整体与接口：[冻结设计v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R3-FIT-001.md)。B讲可见行为，C讲职责，D讲交接，E讲局部步骤与旧值/提交。
2. 中文语句与模块阅读：[module-code-reading](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/docs/module-code-reading.md)，再看qualification/placement操作草图。先请求→桥→原算术→返回→槽→外部结果，再看各case的参数、位宽和资格检查。
3. 实际代码：[fit_core](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/source/rtl/fit_core.sv:117)、[scalar_bridge](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/source/rtl/scalar_bridge.sv)、[完整结果资格](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/source/rtl/fit_protocol_pkg.sv:28)。source里保存与实际构建一致的全部19份文件。
4. 独立参考、测试及追踪：[最终一致性核对](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/docs/final-consistency-review.md)→[验证报告](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/docs/VERIFICATION.md)→evidence/simulation中的audit、原日志及完整事件。
5. 工程和物理证据：[Ti60F225/I3工程](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/source/project/fit_probe.xml)、peri及SDC→evidence/physical中的实际报告→[发布核查](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/evidence/physical/physical-evidence-review.json)。
6. 最后看[产物登记](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/artifact-manifest.json)与registration-readback：244项全数hash一致，包含2产物、19源、223份证据。额外交付说明由documentation-manifest单独登记，原产物Manifest保持冻结。

## 已实际完成什么

| 范围 | 实际结果 |
|---|---|
| 七类运算 | 圆LS、TLS直线、交点、点到直线距离、点到有限线段距离、LS诊断、TLS诊断；kind11/12/13/14/15/17/18 |
| 独立数值及事务 | 14517完整结果，321307真实私有返回逐笔审核；37取消/35在途复位/5缓存/34桥检查 |
| 输入/消费者 | 1056真实来源、结果及585位CRC；28804次局部提交与原192位表达式逐位一致 |
| 形成时间 | 最大8234 core沿，25MHz为329.36µs，仅一笔数值运算；不能当帧FPS |
| 最终物理结果 | fit_physical_004，48329/60800 XLR（79.49%），RAM0/DSP8；Map为7990FF/33221LUT/3718ADD |
| 时序和约束 | 25MHz，setup20.721ns/hold0.035ns；内部未约束/无时钟/多时钟均0，12段真实数据Q→D及复位共28份非空报告 |
| 引脚 | J2时钟1A/1.8V/GCLK；P13 KEY、N14/P14 LED为BR/3.3V；LED4mA。仅四pin数值probe |
| 发布 | 必要检查及49份hash绑定发布证据通过后，真实生成bit/hex并复制staging；没有晋升validated/canonical |

## 如何在软件上打开和复现

打开Efinity，选择打开工程，选source/project/fit_probe.xml；可检查器件Ti60F225、时序模型I3、顶层fit_probe_top、七个RTL、peri及40ns约束。这个工程能在现有软件工具上打开，其独立probe已实际完成综合和布局布线。生产相机/DDR/HDMI顶层另有工作，不能用这四pin工程替代。

阅读源码时，从fit_core的need/call_scalar/local_write参数开始，再沿PREPARE→ISSUE→WAIT_RETURN→QUALIFY_RETURN→ADVANCE或LOCAL_COMMIT阅读。每个子结果先检查完整385位、类型和目标，再提交唯一逻辑槽；后续状态才读新值。桥的锁命令、真实私有序号、等待quiet和保持缓存决定交接寿命。中文注释解释这些边界，外部字段偏移集中在协议包。

在Questa中查看tb_fit_core；测试驱动在negedge，真实接受/返回记于posedge。可观察dut.state、step/subphase、held_request、published_command、child请求/响应、bridge_result、slot_valid及response。数值期望来自model独立整数公式；波形辅助理解，最终判定以完整比对及真实事件审核为准。临时开图不覆盖已登记attempt。

复现使用现有独立work/r3_fit中的run_fit_sim.ps1，指定新的RunId和Suite All；成功后用run_fit_build.ps1指定新的物理RunId及该已通过SimulationRun，依次Map→Interface→Pnr→Sta。所有新运行保留旧失败；Bit还须新的真实报告/源码/路由绑定发布核查。staging是冻结审阅副本；运行支持中现有路径指向获准work，不能直接把它当可任意改写的运行目录。本批最终运行分别fit_suite_012和fit_physical_004。

## 实际产物

| 文件 | 字节 | SHA256 |
|---|---:|---|
| [fit_probe.bit](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/fit_probe.bit) | 2486478 | 0D141A7F491B18016184C4CC8E6D8533E10AE7DFE3788FEA9954D89B9AD4BA3D |
| [fit_probe.hex](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/fit_probe.hex) | 2486538 | F460CDF1449CBF2C2D5865A5071124E53BFDABBE95E32AF553E1B84E8CB736A6 |

原工具输出、失败历史、完整私有/外部事件均保留。原三份scalar/reset RTL字节和45项输入没有漂移；工具改写的工程XML只重排格式，逐节点/属性/文本/顺序比较完全相等，两个实际文件均有hash。

## 还剩什么

本批七个数学操作已闭合。仍需角度/投影、识别统计/候选/支撑/去重及原场景质量验证；完整Canny八邻域滞后连接；DDR动态校准/读写/帧调度；SC431HAI、HDMI、CDC、阈值控制、冻结恢复和彩色叠加；最后整包资源、处理/显示性能、引脚时序和最终比特流。

本批资源已经包含自己的原scalar实例，整机预算不能再简单加一份独立scalar。此处的资源/时序只证明本次独立配置，不能证明整个十一项共存或原复杂识别场景质量。理解验收待用户实际反馈；本批完成不以额外考试阻塞交付。
