# 快速实现批次：交付与后续入口

2026-10-08。用户批准FAST-BATCH v1及本地审计例外，并授权“当你统計完后自行进行, 无需我的批准”。当前批次57份计划业务文件全部生成且独立物理闭合；连续实现又增加阈值、八邻域连接和RAW10转色三个单元13份文件，总计70份业务/验证/工程文件（含原模块按字节复用，不把文件数等同模块数）。完整五项基础/六项高阶尚未整机闭合，目标继续有效。

## 按这个顺序阅读

1. 整体：[先模块→组合→性能的策略](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-MODULE-FIRST-001.md)，再看下表当前成果和未完成范围。
2. 局部：每包docs/README先整体行为/模块连接，再协议字段、中文语句草图和实际RTL；基线设计仍保存原审阅记录，实际结果以最终run为准。
3. 模块交接：统计token→STAT→原FIT NUM→RESP；角度NUM→ROM/乘法→RESP；相机解码RAW→规范化，扫描请求→呈现；新增单元的pending→job、RAW窗口→RGB、class/queue→八邻域→pixel各在对应设计D/E说明。
4. 人工查看：Questa先fire/ID/坐标，再状态与中间数学；Efinity先器件/I3/源码与初始化路径，再引脚/资源/布局/时序；软件图像不能替代实物显示。没有硬件操作，也没有要求人下载。

## 已完成并登记的三包

| 包/阅读入口 | 实际软件证据 | 独立物理证据（Ti60F225/I3，25MHz） | 登记入口 |
|---|---|---|---|
| [STATS→FIT](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r4_stats/docs/README.md) | stats_suite_005：1084集合/8337408点/1046实际FIT调用；关闭≤5沿；真实probe/复位/取消/尾序号 | 52619 XLR/0 RAM/12 DSP；setup20.917/hold0.089ns；40份真实路径；Map/PT/PNR/STA/bit成功 | [manifest](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R4-STATS-20261008-v1/artifact-manifest.json)，215份文件 |
| [角度/投影](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_angle/docs/README.md) | angle_suite_003：32851数值/26取消/24复位/1056probe；514常数独立审核 | 3087 XLR/2 RAM/2 DSP；setup34.210/hold0.035ns；44份路径，两ROM映射1024word精确；各阶段成功 | [manifest](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-ANGLE-20261008-v1/artifact-manifest.json)，206份文件 |
| [摄像头整理/画面呈现](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/video_partial/docs/README.md) | video_suite_002：2073600实际RAW样本/26小检查；4模式8294400像素/4950000扫描拍；4probe帧 | 853 XLR/0 RAM/0 DSP；setup35.894/hold0.098ns；14份路径；各阶段成功 | [manifest](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/VIDEO-PARTIAL-20261008-v1/artifact-manifest.json)，213份文件 |

上述三包634份登记文件已全部读回核对大小和SHA，漂移0，原Efinity输出保留。失败尝试和脚本适配过程保留：[物理脚本变更草图](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/sta-script-change-v1.md)。独立工程用实验时钟/复位/LED引脚；不是相机/DDR/HDMI生产顶层。

实际RTL画面：[灰度/边缘分屏](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/video_partial/runs/video_suite_002/actual-mode2.png)、[合成RGB红边叠加](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/video_partial/runs/video_suite_002/actual-mode3.png)。灰度来自实际capture输出；RGB和edge为呈现fixture，未称真实Bayer彩色或完整Canny结果。

## 新增且已仿真通过的三个单元

| 单元/阅读入口 | 已生成 | 实际验证 | 仍需整合 |
|---|---:|---|---|
| [按键消抖/任务阈值](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/live_threshold/docs/README.md) | 5文件 | 41771拍/3参数实例/751878字段；2178次事件与job同拍，启动按住/饱和/复位通过 | 真实R1 join、生产按键/CDC、完整四键/双阈值/冻结控制、综合时序 |
| [八邻域连接核心](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/hysteresis_core/docs/README.md) | 4文件 | 147小图/协议；4幅1080p共8294400像素逐位BFS一致；最重全图弱连通唯一2073600入队/弹出 | 实际class cache/外存queue、完整job adapter、R2整合、性能优化及物理 |
| [RAW10四相位转色核](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/debayer_kernel/docs/README.md) | 4文件 | 25152pair，25102交付/50reset作废；四phase/常量域/脉冲/随机/停顿/身份逐项 | RAW10行缓存/reflect101、真实CSI/phase/CDC、源writer及物理 |

这些单元的数学/协议验证不依赖缺失的DDR3器件模型，但不会替代实际存储、MIPI、TMDS、资源和时序证明。

## 完整工程接下来做什么

按依赖继续：①分类cache与实际queue服务，接R2+八邻域与输出writer；②RAW10行窗口、相机配置/CSI公开接口、CDC/FIFO、源RGB写入；③帧服务/冻结恢复、显示预取与TMDS；④候选/质量/圆与旋转矩形决策、字体标注；⑤总工程、共享拟合/宽运算、性能/资源/完整引脚/生产时钟、综合/PNR/STA和总bit。新增源码仍先给局部中文草图，按持续授权自行实施。

DDR3缺口：选定2Gb/x16器件的动态模型参数/真实PHY验证仍缺，不用4096Mb参数假冒匹配。它影响真实DDR控制器/服务动态证据与整机采集显示链路，不能解释所有尚未实现模块。上述可独立算法继续推进。

性能当前明确问题：STATS独立工程已用86.54% XLR，拟合核心和192bit共享算术及组合调度是全机资源/时序重点；不能把不同独立工程资源简单相加当全机结果。八邻域当前逐点接口基线在随机行为服务下最重270466255拍，尚需cache批处理/邻居合并等优化，不宣称达到最终FPS。25MHz实验不能替代生产100MHz/HDMI74.25MHz。

## 时间记录

首批授权记录UTC09:03:52，三包最后登记UTC12:18:32，墙钟约3小时15分（不是纯EDA耗时）。三个新增单元与物理收尾并行推进；最后一包登记至本汇总又约10分钟。以当前实际记录为准。原16–30小时首批估计高于本次实际，不能当剩余工期。剩余工作仍按32–66小时主动工作粗估，算法/缓存/相机显示/整包通常分别数小时至十余小时；DDR动态资料与IP接口未知可能改变整包日期，当前没有可保证的截止时间。

事件归档session-FAST-BATCH-20261008.jsonl及side-effects.jsonl只追加；正式DB/PROJECT_STATE/TASK_LEDGER/硬件状态保持。理解验收待用户实际反馈；全文交付仍需最终十一项组合与生产物理证据。