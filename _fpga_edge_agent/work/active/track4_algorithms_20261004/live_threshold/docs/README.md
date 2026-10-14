# 按键阈值单元：代码与操作入口

2026-10-08，TRACK4-LIVE-THRESHOLD-UNIT-001 v1，依据用户连续实现授权。本单元已生成五份业务/验证文件；live_threshold_suite_001 完整编译仿真与独立逐拍审核通过。尚未执行生产引脚/CDC、综合布线或实际R1前端组合，不据本单元报告整机高阶A2通过。

阅读：[先整体与接口](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-LIVE-THRESHOLD-UNIT-001.md) → rtl/key_press_debouncer.sv（同步、资格、稳定样本计数）→ rtl/live_threshold_control.sv（饱和/快照）→ model/live_threshold_reference.py（独立样本队列/逐拍值）→ tb/tb_live_threshold.sv（实际沿后输出）。

默认DEBOUNCE_CYCLES=500000，即25MHz下20ms；INITIAL_THRESHOLD=256，STEP=16，阈值11bit域0…2047。两级同步占位值不参与上电释放证明，启动按住无事件。连续合格低只发一次press；长按不重复；再次合格高释放以后允许下次press。两注册事件同时到来抵消。

pending在事件消费沿改变；active只在job_fire读取旧pending。接R1时，应把pending接job_threshold，让现有前端在同沿锁值；不能在该沿把刚更新active再给另一寄存器，希望它读到新值。复位恢复阈值和启动资格，不复位相机/PLL。

实际证据：runs/live_threshold_suite_001，41,771拍×3个参数实例×6个数值/状态=751,878字段对照相等。N=7/default、N=2/初值0步长1、N=2/初值2047步长2047；包含2,178次事件与job同沿。覆盖启动按住、N−1/N抖动、重复长按、上下饱和、双键、随机复位恢复。实际fatal退出1，正常仿真及独立审核退出0。比较M>T的边界也审核，但尚未运行真实Sobel组合核，报告中明确NOT_RUN。

复现：运行scripts/run_live_threshold_sim.ps1并选新的RunId，旧记录不会被覆盖。Questa优先看raw_inc_n/raw_dec_n、increment_key.key_sync_second/sample_valid_second/count/armed、inc_press/dec_press、pending/active与job_fire。波形先找真实释放，再找N个稳定样本，最后查事件与job同拍旧值规则。

生产按键候选C4/N13，来自原控制草图；本包未生成这些引脚的新物理配置。多时钟生产版需完整配置握手，不能把11bit逐位同步。四键模式、中值、冻结/恢复和Canny双阈值仍由完整控制/帧管理接续。

LT01/02→debouncer→LT-T01/04；LT03/04→threshold_control→LT-T02/03/04；LT05→逐拍输出/审核→suite-result与audit-result；实际源码SHA见source-manifest.json，输入见baseline.json。理解验收待用户阅读反馈。