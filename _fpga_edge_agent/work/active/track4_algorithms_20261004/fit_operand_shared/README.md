# FIT共用操作数选择器与定宽槽

先读`inputs/design-TRACK4-FIT-OPERAND-SHARE-001.md`整体及接口，再读E节47来源和语句草图，最后看`rtl/fit_core.sv`中的SRC_*常量、operand_source、call_scalar和计划末尾拼接。130处分支调用只选择来源码；两个192位组合选择器恢复原完整406位命令，PREPARE仍由原寄存器锁存并保持至实际交接。定宽槽及主顺序逻辑与输入typed版本在规范化换行后文本一致；不据此称原始字节一致。

最后读`tb/tb_fit_operand_shared.sv`。除原完整数学/协议/每沿子接口/局部全值/有效槽比较，增加真实PREPARE沿全406命令和计划控制字段比较。`model/fit_reference.py`、`model/fit_vectors.py`及旧R3参考原样复制，旧参考声明及换行适配记录见`inputs/source-binding-note.md`。

运行次序：`scripts/run_operand_sim.ps1 -RunId <新名字>`，完整通过后`scripts/run_operand_map.ps1 -RunId <另一新名字> -SimulationRun <仿真名字> -Variant New`。15份输入冻结、SIM10源、MAP13源，各次尝试保留；不能把新版本之间互证替代原数学和旧核。

`fit_operand_001`完整结束PASS，vsim及独立audit均退出0、无超时。14517原数学向量、51195951个逐周期原R3全接口/值/时序比较、122639次局部提交、4486 helper角点、4014455次有效槽全192比较和321333次真实PREPARE全406命令/计划控制比较通过。37取消/35复位/5缓存及父/桥/子全状态覆盖保留。10当前源与快照SHA重新核对。

`fit_operand_map_001`实际退出0/无超时，当前13源快照相符。Ti60F225/I3/speed/retiming0/seq_opt0/100MHz目标与typed的实际flow XML设置及SDC相同（工程路径/名称不同）。实测32794 LUT/2696 ADD/7076 FF/2 DSP/1 RAM/0 SRL；较typed再减少4226 LUT、增加1 RAM，其余相同；较原R3累计减少11611 LUT、961 ADD、1281 FF并增加1 RAM。6警告为3冗余信号和3小缓存异步读映射逻辑，原日志保留。

重要新增测量：Efinity自动推断了一个EFX_RAM10常量MUX，WCLK/WCLKE/WADDREN/WE固定0，RCLK=clk、RE/RADDREN=1、OUTPUT_REG=0、WRITE_MODE=READ_UNKNOWN，常量INIT字节实际存在。RTL中没有显式新增同步ROM；该推断的实际网表周期等价仍须原生模型动态验证，不能用完整RTL对照代替它，也不能提前采用为生产已验证版本。无PNR/STA/网表动态/比特流/硬件证明。完整十一项、1080p及原复杂识别目标继续，本文属于组件实现进度。
