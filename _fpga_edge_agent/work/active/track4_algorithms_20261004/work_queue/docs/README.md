# Canny 外存工作队列 v1：阅读和运行入口

先读整体卡 `_fpga_edge_agent/planning/design-TRACK4-CANNY-WORK-QUEUE-001.md`，再读本文接口交接，最后看RTL的bank/consumer/writer/prefetch/RPC五段。用户已授权自行继续，不再逐单元索取批准；实际板卡操作仍未执行。

## 目前实际完成

两块256项追加缓冲和一块512项预取缓存，实际用四块512×16同步RAM。cache claim与队列append在同一沿提交；后续push只确认。完整队列容量为WIDTH×HEIGHT，外存每项32位、64B事务；片上暂存容量不会缩减图尺寸或目标数。

`work_queue_hd_001`：1920×1080参数和完整地址域，6693次指令、2220次实际追加/出队，最终8294400字节外存逐字节独立比对；22次seal包括所有1…15项未满64B前缀。另测两bank同时满、第513项等待、非法读回entry、真实读/写安全错误、未知drain隔离、六类取消、所有公开请求/回复反压保持。这里没有宣称每个1080p队列项都实际入队。

`work_queue_small_003`：32×24的768项完整容量实际填满/全部出队，同版本RTL及新增故障/满bank检查通过。小尺寸是验证边界用途，生产参数保持1920×1080。

`work_queue_map_001`：Efinity 2026.1、Ti60F225/I3组件综合成功；4 EFX_RAM10、2412 FF、3523 LUT4、126 ADD、0 DSP。组件的64B内部总线不是板卡引脚，尚未做生产引脚/布局布线/时序/比特流，也没有用真实DDR器件模型动态验证。

## 接口及代码读法

`rtl/queue_ram16_1r1w.sv`：独立RE/WE地址，RE后一拍父模块capture，不清RAM数组。`rtl/canny_work_queue.sv`：先声明metadata和状态，再组合选择OPEN/FREE/owner、RAM控制、共享读口仲裁，最后按旧状态处理真实fire。普通held回复不被cancel重写。

追加bank保存三种位置：b是64B对齐的物理起点，s是该bank的新逻辑条目起点，e是尾端；[b,s)只是覆盖写需要保留的prefix，不属于新入队。writer把整个描述符实际写完才一次推进committed，不以首块完成代表全部完成。head≥committed从唯一[s,e) owner forward；head<committed从外存prefetch读。prefetch范围固定为接受时的committed快照，后续增长不会把旧padding变成合法条目。

队列seal回复：真正接受并实际排空是drained=1；错误ID或非空normal end被拒绝是error=1/drained=0，旧任务继续存在。共同cancel只处置私有槽；已经公开的64B请求必须接受并真实终结。drained未知则隔离，只能在外部证明安全的共同复位后恢复。

## 独立验证和运行

`model/work_queue_reference.py` 用Python deque核FIFO，直接构造最终字节外存；不复制bank FSM。`tb/tb_work_queue.sv` 驱动随机请求/回执停顿，核同步RAM碰撞、指针不变量、公开payload保持、边界和错误，并输出真实memory供Python比对。

`scripts/run_work_queue_sim.ps1` 采用已安装Questa，必须使用新的RunId以保留历史；默认1080p地址测试，Small开关运行768项完整容量。`scripts/run_work_queue_map.ps1` 必须给已通过且源码未漂移的SimulationRun；冻结8份源码/工程快照再综合。运行记录在runs/，FAIL与旧尝试保持。

在Efinity打开 `project/work_queue_component.xml` 可查看Ti60F225/I3和源码；这是内部组件工程，尚不适合直接指定所有内部端口为物理引脚。SDC保留100MHz目标供后续组合检查；MAP通过不证明100MHz布局布线时序达标。

## 追踪和后续

WQ01/02对应claim/confirm/pointer和四RAM；WQ03对应carry/partial seal/writer；WQ04对应forward/prefetch；WQ05对应关闭/cancel/unknown。整体卡T01…06已进行上述单元检查；T07真实cache+HY、T08生产物理、T09真实DDR/全系统继续。下一步是 `canny_memory_join` 三者组合及独立BFS，再接R2分类生产者与帧发布服务。
