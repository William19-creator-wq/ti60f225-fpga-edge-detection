# 并行采集与已有源帧 Canny

本包把实际 RAW→RGB 采集与已有 RGB Source 的完整 Canny 分成两个任务，共用同一个 video_memory_hub。它为下一步唯一帧账本、生产发布控制器和真实显示行读取器整合提供执行模块。完整五基础/六高阶、1080p及原复杂识别范围仍保持，本组件结果不代表整机已完成。

## 阅读次序

1. [设计 v1](../../../../planning/design-TRACK4-FRAME-ACTORS-001.md)：先读 B/C 的整体行为和模块连接，再读 D 的接口、E 的内部中文步骤；F/G/H 说明语言、验证和追踪。
2. [已有帧处理](rtl/frame_canny_rpc.sv)：IDLE接受并锁定配置→Canny job→RGB reader job/config→FP处理→真实两子终态→held DONE。取消保留在途请求，错误优先，UNKNOWN/Q不假装完成。
3. [两个任务组合](rtl/frame_actors_axi.sv)：独立cap/alg接口→复用真实采集、算法及公共内存通道；它不分配帧或发布Result，也不认定摄像头CRC闭合。
4. [组合测试](tb/tb_frame_actors_axi.sv)、[独立数学与事务审计](model/frame_actors_reference.py)：期望来自二维CFA/R2/BFS；actual Source必须由真实W写入产生，期望不取自DUT私有数组。
5. [运行脚本](scripts/run_actors_sim.ps1)、[综合脚本](scripts/run_actors_map.ps1)以及runs中的原始日志/输入快照/实际结果。

一条正常路径：真实采集A→capture DONE明确给出Source写入闭合及计数→上层确认RX good close和不可变Source借用→算法读取A，同时采集B并显示读取A→两个DONE独立交付。当前TB承担这条控制器交接，生产root与唯一owner授权仍待连接。重处理只给已有A一个新算法job，不再输入RAW或假造Source完成事件。

## 当前实际结果

|运行|当前源码范围|实际证据|
|---|---|---|
|actors_small_002|34×19，53份当前sim源|20并行图像、1已有Source重处理、8协议场景；13566输出像素逐位一致，实际RAW并行6460pairs。|
|actors_min_001|6×5，53份当前sim源|同上21算法图像/8协议场景，630输出像素逐位一致，实际RAW并行300pairs。|
|actors_hd_001|1920×1080，53份当前sim源|实际仿真/独立审计PASS；1并行图像+1已有Source重处理，共4147200输出像素逐位一致。B是独立二维RAW图案、下一frame/handle、Bayer1及独立Source区域；实际RAW并行1036800pairs。|
|actors_map_002|当前sim源53+MAP脚本/XML/SDC3|官方Efinity MAP实际exit0；网表与报告一致：28578 LUT4、21761 FF、1899 ADD、46 RAM10、166 SRL8、0 DSP。|

小尺寸合计42个算法图像、40次帧间并行和16个协议场景，14196输出像素比较通过。实际故障包括非法重叠/Origin、held AR/R取消、RRESP失败、错误RID导致Q、held安全DONE后无关displayQ，以及共同cold后的正常恢复；每次UNKNOWN的算法债务在cold前没有伪造完成。

当前三次actual sim合计44个算法图像、41次帧间并行、3次已有源帧重处理及16个协议场景，4161396输出像素逐位一致；94个真实采集任务全部收到真实capture DONE，60个算法任务有58个真实DONE，另外2个UNKNOWN/Q任务仅在共同cold作废，未假造成功。HD运行72937339个数学slave周期，实际AW/B各220992、W883968、算法AR229088、显示AR6075、R1305152，物理读写并行1061583周期。这些周期没有包括DDR PHY、CSI、pixel时钟或连续HDMI吞吐证据，不当作硬件FPS。

首次SourceA任务的实际CAP_START到CAP_DONE是2223474周期（包含真实写入闭合）；随后一个算法任务与第二源帧采集及A显示并行。public-bus audit还逐字节重建所有正常R/W、核查真实第一轮class写入、各burst/4KiB/LAST、独立SourceB结果和冻结A重处理不改Source。实际图像、class/state、BFS queue、1bit edge、FP/grad/status分别归档；与math一致不等于DRAM器件动态合格。

actors_small_001是修正Full测试输入之前的实际PASS，独立快照保留，不计入当前源码统计；[C1订正](../../../../planning/design-TRACK4-FRAME-ACTORS-001-C1.md)解释为何Full不能复用同一帧身份。MAP第一个attempt在启动Efinity前因路径字符串误替换退出1，failed-script和实际工具输出保存于runs/actors_map_001；[C2修正](../../../../planning/design-TRACK4-FRAME-ACTORS-001-C2.md)和新attempt明确区分脚本失败与综合失败。一个只读PowerShell解析观察命令也因引号转义失败，未运行业务；实际脚本经后续真实运行正确解析，不冒称该观察检查通过。

综合保留85条实际警告：2条EFX-0011 VERI-WARNING是原复用write service的X/Z比较二值化，20条EFX-0200冗余信号、63条EFX-0657小存储映射为逻辑。完整warn.log保留；不能据四态RTL仿真宣称综合后的X/Z检测等价。当前component只有二值实际接口时序/功能证据，没有mapped动态仿真或物理未知电平证明。

相较已验证的串行production_bitmap组件，实际新增17 LUT和84 FF，RAM/DSP不增加。该组件LUT约占Ti60的60800 LUT的47.003%；这是当前组件的实际综合资源，不能通过相加/比例推断完整板级顶层已装得下或达到目标帧率。

## 运行与修改

使用已存在PowerShell7运行scripts/run_actors_sim.ps1，必填RunId；默认34×19，Protocol开关执行错误场景，TestWidth/TestHeight选择几何，Full要求1920×1080。每次使用新的RunId；脚本冻结53份实际源，执行生成、vlib/vlog/vopt、真实expected-fatal探针、实际vsim和独立audit，再核查源哈希。Full不重复所有小尺寸故障，但必须比较完整图像。

run_actors_map.ps1要求一个实际PASS的SimulationRun，核查同一批当前53份源，再冻结56份MAP输入，只运行组件综合。不执行板级布局布线、时序签收或bit，不向硬件编程。XML是组件MAP工程，宽接口尚须接入正式板级顶层才能配置最终引脚。

baseline.json冻结56份输入、48份逐字复用运行依赖；baseline-supplement-c1.json另冻结C1设计。设计卡的九份适配参考在实际清单中是旧RPC/hub/TB/BFM/数学入口/sim/map/XML/SDC，旧top没有作为新组合源码使用。8份新写/适配业务验证文件与复制依赖单独统计。

## 未完成项

真实owner的写入/算法工作授权和自动发布root、RX CRC/晚错/非暂停输入处理、实际row reader/prefetch/scan和连续HDMI、复杂识别、匹配2Gb/x16的DDR PHY动态验证、完整顶层资源/处理帧率、板级引脚/CDC/PNR/STA和最终bit尚未由此包证明。硬件和正式数据库状态未改；本包不把软件通过写成实机通过。

理解验收待用户实际反馈；已提供中文草图和代码阅读次序，不把说明本身当作用户已经理解。
