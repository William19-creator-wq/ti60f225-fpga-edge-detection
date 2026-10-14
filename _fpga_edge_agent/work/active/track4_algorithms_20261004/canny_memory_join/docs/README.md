# 实际cache/queue/滞后组合 v1.1

阅读次序：整体卡 `planning/design-TRACK4-CANNY-MEMORY-JOIN-001.md` → v1.1 FLUSH关闭澄清 → 本文 → `rtl/canny_memory_top.sv` → `line_rpc_arbiter2.sv` → HY诊断扩展 → 复用cache/queue内部代码。代码保存在本work副本；旧HDK与已登记包没有改动。

## 实际结果

`memory_join_small_002`通过30组32×24完整图，独立BFS逐像素比对23040个结果；13255次实际claim同时检查cache RAM WE和queue RAM WE，独立比对最终分类外存、FIFO的完整BFS顺序和边缘位。包括全强、全连接弱、随机图、孤立弱、对角和跨行反例。

同一RTL的11种取消阶段通过：两个配置回复、启动、claim同沿、queue请求、forward返回、prefetch安装、held pixel、cache FLUSH、queue SEAL、公开外存请求反压。错误ID不影响正常任务；安全外存错误优先于cancel；drained未知不返回done/不重用任务，安全joint reset后恢复。

`memory_join_hd_001`通过4组完整1920×1080：随机无seed、孤立弱、1080点对角连接、跨行反例，共8294400像素。每组还比对518400字节分类空间和实际FIFO索引序列。每组实际32379129～32611478时钟，含行为外存随机停顿；这些是稀疏场景，不冒称最重连接吞吐或生产FPS。小图已经实际包含密集场景；完整1080p最重连接仍需另run与优化。

`memory_join_map_001` Efinity组件综合成功：12 EFX_RAM10、6071 FF、10872 LUT4、240 ADD、0 DSP，Ti60F225/I3。真实RAM来自cache8块+queue4块。MAP工程目标100MHz；未进行生产board pin/PNR/STA/bit。行为64B存储服务不替代真实DDR器件验证。

## 整体数据及交接

job接受两个64B对齐且不重叠的完整授权区。控制器依次配置cache/queue、启动HY；cache唯一claim与queue追加同沿，HY随后push只确认。两个客户端由保存owner的64B仲裁器复用外存。HY先全图扫强点，再八邻域扩张，最后顺序导出全部N边缘位。

计算done之后还须cache FLUSH和queue end seal。取消中的第一FLUSH错误回复可能只终结旧请求，控制器下一拍检查公开cfg_ready/req_ready：已经关闭则继续；仍配置则再发一次故障私有清理FLUSH。代码不以内部configured推进生产逻辑。真实终结后才公开done，私有输出帧也只能由外层在成功done后发布。

`hysteresis_core_memory.sv`是旧HY的最小诊断扩展副本：aborted只能在匹配取消时直接终结CANCEL，不以假状态0/假索引0套入正常数学，也不把该预约计成功enqueue/pop；真实error无aborted保持ERROR。旧HY源码保持原hash。

`line_rpc_arbiter2.sv`接受一个client请求后固定owner和512bit payload，直到外口接受、实际回执及原client消费。轮转选择只在IDLE，不能同沿把回复给新owner；unknown原样交付后隔离，不把另一个client放行。

## 工程、脚本和边界

`project/canny_memory_join_component.xml`可在Efinity打开；deps/提供与冻结输入逐字节相同的GUI阅读镜像，运行脚本从真实共享work源冻结副本。内部64B总线不是板卡物理pin。`scripts/run_memory_join_sim.ps1`默认小图完整协议集，FullHD运行4组全地址稀疏图；`run_memory_join_map.ps1`需要已PASS且源码hash未漂移的SimulationRun，冻结13份实际源码/模型/TB/脚本/工程，其中4份RTL复用cache/queue。

runs/保留开始/退出/超时/哈希/实际结果/参考审计。新尝试用新RunId；故障不覆盖旧记录。同步rst只是软件实验的安全共同复位条件，生产必须由物理服务确认旧事务不再活动。

后续入口是 `canny_full_sw`：原R2直接写分类帧、实际滞后计算、灰度结果帧写回、三授权区和96bit完整scope。然后继续帧发布/摄像头/显示、识别器及生产引脚/时钟/资源/布局布线整合。此组件通过不表示五项基础与六项高阶已经全部闭合。
