# 1080p显示联合闭合与FIT资源优化进度

本轮按“统计后自行进行，无需批准”的持续授权推进，仍先保存、读回并呈现中文草图再生成代码。软件目标继续是五项基础、六项高阶、Ti60F225/I3、SC431HAI彩色和1080p；正式数据库/H0及硬件状态不改，完整目标仍ACTIVE。

## 已完成的实际工作

display_scan的原同一HD进程已正常结束，无重启：1920×1080、17个完整扫描和第18个前缀、六种mode均有完整active帧，8次真实VS交接、70 owner事务、7次真实oldClosed/RETIRE、候选迟到、取消与视频/owner阴影不同步时冻结/恢复均通过。37324800有效像素、22231390时隙，RGB/native/fullticket与原owner/独立scan参考全部PASS；28份源快照当前SHA相符。小/边界/故障/失败历史仍保留。完整新产物DISPLAY-SCAN-COMPONENT-20261010-v1.4登记583项，与原PENDING-HD包分别保存，不重复计10个源码文件。

FIT按中文草图新增/适配6个文件，保留七类622/585接口及原全部数值和时间。14517个原独立数学向量PASS；旧/新51195951沿全值/握手时序相同，122639次局部完整192提交和4486个helper角点相同，原37取消、35复位、5缓存场景及全父/桥/子状态覆盖通过。两次实际同设置Ti60F225/I3 MAP结束：

| 独立FIT top | LUT4 | ADD | FF | DSP48 | RAM10/SRL8 |
|---|---:|---:|---:|---:|---:|
| 原核 | 44405 | 3657 | 8357 | 2 | 0/0 |
| 本轮局部优化 | 43501 | 2696 | 8357 | 2 | 0/0 |
| 减少 | 904 | 961 | 0 | 0 | 0/0 |

两个MAP各13源快照及10仿真源快照都与当前源相符；8项warning各原样保留。FIT-LOCAL-RESOURCE-COMPONENT-20261010-v1登记153项。源适配同时改module名和LF/CRLF换行，顺序逻辑仅在规范化换行后文本相同，不能称原始字节相同；更正说明和历史事件均保留。1791槽FF来自旧STATS父工程，此次独立FIT真正是3072槽FF，预算不能混用上下文。这次未减少FF，进一步存储/结构优化另继续。

另生成1个独立面积实验运行器，37输入冻结，保持显示所有RTL/SDC，仅更改mode。area真实MAP PASS：34415 LUT、23325 FF、835 ADD、19 RAM、1 DSP，较原speed减少1087 LUT、增加1 FF；32源快照匹配。area2原同一进程正常退出0/无超时，35502 LUT/23324 FF/835 ADD/19 RAM/1 DSP，与原speed资源完全相同，未获得节省，约1274秒综合墙钟；不删除零收益尝试。两个模式64份源快照相符，配置单参数差异均核验。本实验已登记DISPLAY-SCAN-AREA-EXPERIMENT-20261010-v1共200项；无新网表动态/PNR/STA证据，未决定最终生产策略。

## 阅读次序

1. planning/design-TRACK4-DISPLAY-SCAN-002.md及其J/Q卡→work/active/track4_algorithms_20261004/display_scan/README.md→三RTL→独立参考/实际runs。
2. planning/design-TRACK4-FIT-LOCAL-RESOURCE-001.md→work/active/track4_algorithms_20261004/fit_local_resource/source-binding-note.md及README.md→helper/plan→旧核对照TB→两次真实MAP比较。
3. planning/design-TRACK4-SCAN-AREA-EXPERIMENT-001.md→work/active/track4_algorithms_20261004/scan_area_experiment/README.md→运行器→实际configuration-diff和报告。
4. 01_baseline/ddr-model-adaptation-feasibility-20261010-v1.md为只读补查：模型主体已有2Gb分支，缺匹配头和完整参数依据；派生模型路线须逐参数可追溯，尚未生成或动态验证。

路径相对于控制面；真正源码只在work。269是累计自写业务/验证文件数，包含脚本/TB/工程，不是269个硬件模块或完成率。本轮7个新文件中6个FIT已完整组件验证、1个面积实验已完成area/area2真实MAP；先前192个当前增量源加本7个共199个本轮SHA核对；另70个早期基础输入未全部重新运行。

## 剩余与恢复

本轮所有启动工具均已真正结束，继续按实测报告优化结构/存储，并推进生产控制/CSI/DDR/识别组合；无需恢复或重启已经结束的area2。按真实报告决定策略，收益为零/负也保留。资源方案需继续结构共享/复用，当前独立组件相加没有证明单Ti60全系统能装下；此轮节省不能升级成全机资源/速度通过。

生产Source/result/OFFER/APPLY/FREEZE/RETIRE控制与RO lookup权威、真实AXI多client仲裁/QoS、CSI CRC/末包错误归属/rx_close与活动C2等价、原完整旋转/短边缺失/遮挡/重叠/最多4目标识别、单生产top、实际总资源/FPS、板型对应引脚/时钟/CDC、PNR/STA及最终bit仍未完成。显示输入为数学byte-slave/ANN码型，不是真摄像头或识别结果；当前源显示和FIT组件没有替代真实DDR动态。

五种正常扫描总85完整帧/90带前缀、350 owner事务、35真实关闭/RETIRE并保持最后active及三个预读bank；保留引用没有被伪称已释放。没有执行硬件下载、安装或改正式状态。软件自行继续，最终生成bit后仍停止硬件步骤。
