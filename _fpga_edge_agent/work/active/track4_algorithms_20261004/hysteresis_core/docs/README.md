# 八邻域滞后连接核心：实际代码入口

2026-10-08，HYSTERESIS-CORE v1，按持续软件实现授权。已生成核心、独立参考、TB及脚本四份文件；小图和完整1080p均已实际通过。本包的图和queue是仿真行为服务，实际cache/DDR服务尚未实现，完整Canny生产链路不据此判通过。

先读[整体/服务/中文状态草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-CANNY-HYSTERESIS-CORE-001.md)，再读rtl/hysteresis_core.sv、model/hysteresis_reference.py、tb/tb_hysteresis_core.sv、scripts/run_hysteresis_sim.ps1。

实际执行顺序：全部CLAIM_STRONG扫描并入queue→FIFO pop→21拍移位除法还原x/y→八邻居画面内检查/CLAIM_WEAK→原子claim完成后push→queue空→按原坐标READ_STATE并输出edge→最后像素实际消费后才done。分类状态3在响应前可见，故每点最多入队一次，容量N。接口外部图/queue资源不会因本核无RAM而消失。

小图hysteresis_core_002：147场景，包括固定/128随机、无种子、全强、长弱链、对角、孤立弱、跨行伪邻居，以及服务错误、非法状态、错claim/queue返回、取消/错ID、held结果和共同复位恢复。最慢13,265拍；每成功图逐像素对独立deque BFS，所有claim/queue/held/范围守卫通过。core_001因fixture文件补宽不同失败并保留，最终使用不补宽名称且显式打开检查。

完整hysteresis_full_001：4幅1920×1080、共8,294,400输出像素逐位一致。无种子39,929,375拍；单强种子连接全图弱边270,466,255拍、2,073,600唯一enqueue/pop；对角连通40,036,305拍/1,080边缘；跨行反例39,936,912拍/1边缘。随机服务响应/反压均包含在周期内，这些是行为服务下的仿真周期，不是实测DDR帧率；当前基线仍需缓存批处理/邻居合并/坐标换算优化。

复现脚本用新RunId，Full1080p开关选择生产尺寸；vopt实际-GWIDTH=1920/-GHEIGHT=1080已生效。Questa先看job/cancel/state，再看两个请求fire和heldbody、state_rsp_old/claimed/error、queue push/pop、enqueue/pop/output_count、pixel_index/edge。服务响应必须真实完成/排空；共同复位测试不证明暖单端复位或物理DDR已安全。

HY01/02→seed/queue/neighbor→T01/02/07；HY03/04→请求保持/像素/done/取消→T03…06；HY05→独立BFS、实际事件和审计→两份audit-result/suite-result。实际source SHA见两个run清单。后续需分类cache、实际外存queue、完整job adapter、R2/输出writer合流及物理/性能验证。