# 软件交付与bit后停止

## 当前入口：2026-10-08

当前完成度读[十一项软件完成边界v3](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/05_delivery/full-scope-software-coverage-20261008-v3.md)。R1、R2流段、DDR Q0、R3整数核及R3 FIT已有各自实际软件证据；完整五基础、六高阶仍未完成。下面各日期段落保留历史状态，不把旧“待批”文字当当前事实。

最新[FIT中文交付入口](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-FIT-20261008-v1/README.md)按整体→模块交接→中文局部语句→19份代码→独立测试→Efinity工程/资源/时序→bit登记阅读。七类几何数值运算、14517数值及全部协议/来源审核通过；48329 XLR/0RAM/8DSP，25MHz setup20.721ns/hold0.035ns，bit/hex真实生成并登记。244项hash全部一致；止于比特流，无硬件操作。

完整Canny滞后、DDR动态与生产帧服务、相机/HDMI/CDC/阈值/冻结/叠加、识别统计/候选/支撑/去重及原场景质量、整包资源/性能/引脚仍须完成。已通过局部模块不替代整项完成。

下一批：[点集统计→现有FIT设计v1.1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R4-STATS-001.md)已完成整体/接口/局部中文语句草图、真实来源/消费者、完整容器预算、22文件及独立参考/1080p/真实FIT组合/物理验证计划；[最终设计读回](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/r4-stats-design-readback-v1.1.md)与[54份输入基线](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/01_baseline/algorithm-r4-stats-baseline-v1.1.json)逐项核对0漂移。状态READY_FOR_REVIEW，指定范围批准及本批本地审计例外已请求、待用户回复；没有新业务源码/工作目录、测试或EDA，不能增加到“已完成模块”。v1只是被v1.1替代的中间候选。已有FIT批准和交付继续有效，未重复构建。ANGLE和DDR联网批准也未从本请求得到授权。

并行纯设计：[Canny单操作串行提交候选v0.1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-CLOSURE-SERIAL-001.md)及[限定读回](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/closure-serial-alternative-readback-20261008-v0.1.md)核对正常单信用、CH938不含postimage和FPI/AXI分层承诺，提出移除CLAIM正常journal数据路径的条件方案。仍LOCAL_DESIGN/NOT_READY、未采纳/未实现/未运行，不改变原R4C/BK或已有批准。其事件数比较不是实际资源/fps；2Gb模型/真实IP可见性与关闭资格仍缺，既有DDR外部输入申请保持待答。

2026-10-05：已批准 R1 v1.1 批次完成软件交付，实际 123/123 FE 场景及四个完整 1080p job、外壳回归、Map/Interface/Pnr/STA、bit/hex 和 staging 均有真实证据。先读[中文验收与操作入口](r1-software-acceptance-v1.1.md)，再按其中整体→接口→局部→测试→工程报告→产物顺序阅读。完整五基础/六高阶尚未完成。

本批登记真实设计/源码与工具版本、输入/命令/日志、比较数量、3411 XLR/8 RAM10/0 DSP、四pin/40ns及 setup35.381ns/hold0.063ns。实际 bit 1,731,456B、hex 1,731,516B；[staging manifest](../../../artifacts/staging/ALGORITHM-R1-20261005-v1.1/artifact-manifest.json)绑定原输出/run/hash。Efinity 原输出和失败历史保留，不晋升 validated/canonical。首次 Bit 退出0但无产物的记录及真实成功重试分别保存。

实际代码阅读入口按整体→接口→局部稳定符号→逐沿/结果→测试→工程报告；详细中文操作补实际打开文件/工程/波形的位置和运行记录。无硬件的本轮止于bit生成/登记，不安排下载、Flash、调试器、相机观察或比赛视频，不改变正式PASSED状态。

只有R1范围真实必要检查通过才称R1软件交付完成；R2…R5/相机/HDMI/完整十一项单独保留未完成。

## 完整范围的当前阅读入口

当前完成度先读[十一项软件证据审计](full-scope-evidence-audit-20261005-v0.1.md)，再看[持续进度](software-continuation-20261005-v0.1.md)。旧整合主稿的R1未实现文字属于历史时间点；当前R1事实仍以上述真实验收为准，后续生产整包未完成。

ANN输出的最新[联合草图v0.2](../../../planning/design-TRACK4-ALGORITHM-ANN64-OUTPUT-001.md)在D1统一R4R/SM/SC/RA/JL的静态操作选择；原来源保持，真实许可/DDR/关闭及完整资源服务仍OPEN/NOT_READY。它是设计进展，不是代码、测试或实现授权。

R2流段与DDR Q0已有READY版本及指定基线，实施仍待此前具体批准；Q0只编译/展开，不等DDR校准和实际读写资格。完整Canny、识别、生产摄像/HDMI和全机预算继续按各自范围推进，不复用R1小包通过结论。

## 2026-10-05：唯一实例与处理开销审查

先读[整机预算审查](../03_review/production-instance-budget-review-v0.1.md)的整体→RAM→冷/热状态→逐操作成本，再读[精确数据附件](../03_review/production-instance-budget-numbers-v0.1.json)。已列RAM分支170/178仍不是完整fit；投票日志工作量已量化，完整资源和成功服务仍OPEN。本轮仅修正RMT预算文字矛盾，R1批准交付与R2/Q0待批基线不改。

## 2026-10-05：完整投票的片上批次候选

从[有限设计与中文草图](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)读整体→接口→局部边沿→落盘/NMS→预算，再查[数字附件](../03_review/dense-batch-native-numbers-v0.1.json)。候选保全部512θ与21bit计票，每批16bank后完整728个16B落盘；新增16RAM，186/194仍是部分预算。真实batch许可/内部overwrite来源/服务和完整fit仍OPEN，NOT_READY/NOT_APPROVED/未实现未运行，不能把事件数量当fps。

## 2026-10-05：片上批次联合草图v0.2

当前[设计v0.2](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)已明确管理/内部来源/许可/JL交接、20bit双WE、三沿导出与无环NMS退休；[数字v0.2](../03_review/dense-batch-native-numbers-v0.2.json)和[限定审阅](../03_review/dense-batch-native-joint-review-v0.2.md)记录三处修正及剩余实际桥。上节v0.1为历史入口，其原字节见[精确快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.1.md)。仍NOT_READY/未批准/未实现/未运行，完整资源与DDR完成信号未闭合。


## 2026-10-05：片上批次提供者与保持字段修订v0.3

当前[设计v0.3](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)补DATA先关闭/CONTROL后退、固定owner管理CMD借用和独立绑定、639bit持久原KEY/lease；[数字v0.3](../03_review/dense-batch-native-numbers-v0.3.json)与[限定审阅](../03_review/dense-batch-native-provider-and-holding-review-v0.3.md)按实际范围记录三项复核。上节v0.2为历史入口，原设计字节见[v0.2快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.2.md)。

所列管理字段减少1572bit并补持久639，8520+JL78=8598仍非全机FF；186/194仍非完整RAM/fit。实际安装/receipt/view/partial迁移/physical关闭及完整资源服务未冻，NOT_READY/未批准/未实现/未运行。R1交付及R2/Q0待批边界保持，完整十一项仍未完成。


## 2026-10-05：批次安装与上下文借用草图v0.4

当前[整体至局部设计v0.4](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)在D5/E0.1补固定POINT/DENSE/RELEASE核查、真实BEGIN所属及同CTX partial保存、原WQ426绑定view/撤销；先结DATA并形成回执，继续保护stage直到末管理ACK及全部旧metadata/GAP闭合。看[有限审阅](../03_review/dense-batch-native-installation-review-v0.4.md)和[数字v0.4](../03_review/dense-batch-native-numbers-v0.4.json)；[v0.3快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.3.md)保存上一节历史设计。

新增安装具名字段2861bit，所列11381+JL78=11459仍不是完整FF/fit；32批两项核查至少12288 RE事件，新口93568fire均不等处理时间。匹配DDR完成/读写排序、实际holder/fence/回调及完整资源服务仍OPEN；NOT_READY/未批准/未实现/未运行。R1实际交付有效，完整十一项仍未完成。
