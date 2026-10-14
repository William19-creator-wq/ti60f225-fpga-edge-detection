# 六源三结果的帧所有权核心

阅读顺序：planning/design-TRACK4-FRAME-OWNER-CORE-001.md的B整体→C/D交接→E中文操作→rtl/frame_owner_pkg.sv位序→frame_owner.sv同名操作分支→model租约集合参考→TB→runs与staging。此单元8份自写源，不包含图像处理或视频时钟域。

核心只有一个账本写者。每个源有唯一64位handle和195位Origin；每个结果有独立64位handle、对应源、142位CJ、400位图地址与render快照及64位policy。身份不回绕，slot本身不能代表同一帧。W/H默认为1920×1080，像素内容在DDR，不占此表的RAM。源6槽、结果3槽、最多1个OFFERED、DISPLAY最多1、RETIRING允许2。

source EOF只是WRITING转DRAIN，尚非完整。IO_closed、producer_closed均真正证明旧访问已停并排空，才能END；good时还须已经EOF。缺闭合隔离并回QUARANTINED，不把收据OK当完整帧。latest按64位采集顺序选择最新成功源。latest、freeze及每个非FREE结果是独立保留集合；先合并事件影响，再统一回收无读者的COMPLETE/BAD。result从WORKING到DONE/OFFERED/DISPLAY/RETIRING全程绑定其源。

冻结的source必须来自显示真实snapshot及其hold。视频已显示B而核心影子A时，B可以仍OFFERED；FREEZE先为B建立保留，再给回复，外部消费回复后才能解除hold。NO_ACTIVE选择已有latest或等待第一成功源。新OFFER必须在当前policy，而且冻结期间只能发布该freeze source。普通cfg采样只在ALLOC_RESULT；在途body不因后续参数变化改变。

APPLY是视频域真实已发生事实，记录后旧DISPLAY进RETIRING；IO+consumer closed前不能FREE。两个旧结果可以同时退休。不以时间到或槽号相同归还。安全冷复位只能在平台确认所有旧访问闭合后执行；功能cancel用END/DROP和真实closed，不清表制造空槽。

command941/reply942见pkg。命令在core上升沿valid&&ready接受；单reply holding未消费时ready=0，全部942位保持。失败回复canonical零payload/槽7与3；成功回复的op决定它是分配、事实收据还是归还，DROP成功不授予读权。结果快照保持源/结果/Origin/CJ/描述符/render一致。

SRC地址s×8MiB，result地址48MiB+r×8MiB，ANN再偏移1MiB。SRC长度3WH，EDGE为ceil(WH/8)，ANN为4224+ceil(WH/4)，描述符含有效L与16byte对齐A，不读allocation间隙。只在相应模式生成EDGE/ANN。后续CLASS/QUEUE/GRAD/RC和物理授权整合另完成，此表不冒充完整DDR服务。

脚本run_owner_sim.ps1 -RunId 新名称，默认生产几何完整控制场景；-Small最低4×2，-NearMax检查source/result/policy临近2^64最大值。独立Python由每次实际握手日志重建对象和租约集合，逐一核回复及表状态。此仿真不传整帧像素，不能据它宣布1080p视频链通过；前批像素证据独立保留。run_owner_map.ps1只在当前源仿真通过后冻结源，Efinity MAP产生实际资源报告，不包含板级PNR/STA/bit。

仍待接业务控制器/实际显示VSYNC与控制CDC/预取退休、真实叶fence/CSI闭合、整机资源和总top。既有用户自主授权/本地审计沿用；原HDK和正式状态不动、无硬件动作。

内部压缩表示：source只存state/handle/frame_epoch，完整Origin由同一不可变handle及slot重建；result只存handle/source_slot/config/render/policy。BIND未释放时source槽不会重用，CJ帧字段和source身份按该受保护源重建；静态图desc由几何及slot公式生成。对外仍比较并返回完整195/142/64位身份，未截断。这样减少重复存储及读取modified-next全表的大旁路，首次MAP16773LUT/5061FF，优化MAP9624LUT/2623FF（分别减42.62%/48.17%），RAM/DSP0。当前SRC/render关系的数学参考保持独立。-PostMap -MapRun 指定已冻结MAP名称使用真实EFX_FF/LUT4模型重放生产几何协议；这不是布局后时序仿真，具体当前结果后登记。
