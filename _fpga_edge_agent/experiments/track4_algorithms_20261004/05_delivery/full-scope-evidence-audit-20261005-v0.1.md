# 完整十一项软件目标：当前证据审计 v0.1

2026-10-05。原目标保持完整1080p、五基础/六高阶、完整八邻域Canny及原圆/任意旋转矩形识别与质量要求；只用板卡现有资源，允许板载DDR3。软件交付须有真实代码、独立参考/测试、综合/布局布线/时序/约束和最终产物；按用户要求止于bit之后，实体下载、观察与视频暂不计本轮必需完成项。
先读本表辨完成范围，再读各设计整体→连接→局部中文草图→验证追踪。正式硬件需求矩阵仍是2026-09-23 PLANNED基线，不覆盖独立软件记录，也不能据此将已交付R1抹为零。

## 1. 十一项与能证明完成的证据

R1实际入口为[验收/中文操作](r1-software-acceptance-v1.1.md)；其独立灰度/中值/Sobel实现、123/123场景、四完整1080p job、物理005/STA/bit已交付。3411XLR/8RAM10/0DSP、setup35.381ns/hold0.063ns属于四pin25MHz实验，不能证明生产视频、后续模块或整包fit。

| 要求 | 当前有证据的部分 | 完整软件完成仍缺 |
|---|---|---|
| B1 采集/缓存 | 原参考及有限IP综合、R1可暂停图样/行窗口 | SC431HAI/CSI生产接线、像素/帧身份、CDC/缓冲及完整功能/物理验证 |
| B2 灰度 | R1算法核实现/1080p仿真/综合/PNR/STA/bit | 生产输入输出接入和整包对齐/验证 |
| B3 Sobel | R1两行窗口、梯度L1、参数阈值同等通过 | 生产交接/显示及组合验证 |
| B4 HDMI/对比 | 生产显示/ROW/SCAN设计 | 1080p60真实时序/serializer/同帧对比/供数、pin/SDC和工具结果 |
| B5 完整交付 | R1可复现包及中文顺序/代码/约束/产物 | 十一项统一文件/工程/生产约束/参考/测试/最终bit；实体视频暂不要求 |
| A1 中值 | R1九值网络、独立两次复制边界及同等工具证据 | 生产与完整链路交接/验证 |
| A2 实时阈值 | 控制/消抖/配置快照设计；R1只有静态job配置 | 真正按键消抖/饱和/原子实时更新RTL与显示；R1 KEY仅复位 |
| A3 DDR帧缓存 | 现有2Gb/x16来源、有限综合及目录/存储设计 | 匹配模型/PHY资格、真实读写/冻结恢复、可见/无未来效果、仲裁/服务及实现 |
| A4 完整Canny | 流段READY；精确八邻域闭包设计 | 流段及闭包实现/独立黄金/组合/1080p/综合PNR STA；class不是final edge |
| A5 彩色叠加 | 同源RGB/EDGE/ANN重放、渲染设计 | 原彩色/最终edge同帧同坐标的RTL/功能/工具验证 |
| A6 识别/标注 | 数值、候选/拟合、packed/NMS/质量及ANN设计 | 实际算法RTL/独立参考/质量集/P-R结果、完整预算/生产整合/工具验证 |

原要求与软件分工见[范围映射](../00_scope/requirements-map.md)及[整合设计](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md)。整合v0.8的“仍无本次算法代码/仅IP例外”属于旧时间点，当前R1事实以上述交付和真实Manifest为准；本报告校准阅读导航，不使旧整合READY或全部来源变为现行共同基线。

## 2. 有效授权与实际可执行边界

| 范围 | 当前权威状态 | 下一动作的实际条件 |
|---|---|---|
| IP-PRECHECK v1/v1.1/v1.2 | 有明确批准，已TERMINAL_WITH_FAILURES | C0 PNR pack失败，C1/C3依赖跳过、CSI合法编译失败；原停止条件禁继续下游，删USER1/换clock/新DDR试验需新范围 |
| R1 v1.1 /22输入 | 已批准且DONE_STOP_AFTER_BIT | 原批准范围无新的必需未完成项；不为重复查看重跑，硬件动作暂不做 |
| [R2流段 v1](../../../planning/design-TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001.md) /48输入 | READY_FOR_REVIEW / NOT_APPROVED / work不存在 | 原指定问题仍待答，实施/本地审计例外不能借R1；成功也只覆盖流段，不包含live/overlay/闭包/识别/DDR/CSI-HDMI |
| [DDR Q0 v1](../../../planning/design-TRACK4-DDR-Q0-001.md) /44输入 | READY_FOR_REVIEW / NOT_APPROVED / work不存在 | 待指定批准，只vlog/vopt；不vsim/TB/PHY/综合PNR/bit，不能由Q0推导校准或DDR资格 |
| [匹配模型申请](../../../tools/REQUEST_DDR3_MODEL_20261004.md) | PENDING | 2Gb/x16 2048Mb头/时序及合法来源未齐；原4Gb参数不能替代，联网/下载尚未批准 |
| [DDR资格Q1–Q3](../../../planning/design-TRACK4-ALGORITHM-DDR-QUALIFICATION-001.md) | NOT_READY / NOT_RUN | 真实PHY/相移复位、B可见/no-future/校准丢失排空合同及合法故障条件须补真实依据 |

规范[§10.3/10.4](../../../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)要求当前范围无设计阻塞并明确批准版本/范围。自动续目标不是新增业务授权。本轮不重复待答问题，不以无限设计调查替代已READY范围的批准，也不先跑工具反求批准。

## 3. 本轮可消除的静态缺口与尚需的证据

现有[ANN草图](../../../planning/design-TRACK4-ALGORITHM-ANN64-OUTPUT-001.md)选完整64像素/16B写；联合静态v0.2在同一份卡内统一R4R、SM、SC、RA、JL的op6/phase14/完整span/ordinary group解释，采用D1五行覆盖表而保原来源不改；最终124行/22514B/SHAADA5D8E6962026EC95A08FB81009EB058ADD62275FE855D802147EEEEF7CDEDB。只有共同采用该版本才允许新op；旧独立基线仍op6非法。真实permit/END/DDR/关闭及全账不能由静态表关闭。
下一项纯设计工作是选择唯一实例结构后，补全所有tag/valid/allocators/returnedmetadata/失败和close保持槽、native RAM/端口及逐op费用；不得将13079/6780/63191等有重叠的部分数直接加成整机预算。Q0不决定这些静态整数，因此这项仍可推进；实际LUT/XLR/DSP/STA及成功服务曲线须获批运行证据。
整包CSI/显示电气、模组CFA/副band/真实byteclock/serializer与1080p60服务的证据仍缺。已经找到板载DDR及正确名义容量；缺的是资格、成功服务和整包实现证明，不是“资料包没有DDR”。

## 4. 来源记录修正、历史与实际审阅

发现ANN旧L12模板SHA少两个hex字符。已改为99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79，其他数学/接口当时未变；修正后v0.1 snapshot109行/15958B/SHA0B91527199B63524B7566418D2A4294C42E12583159C51C0F60822814CA66EC8保存于before-op6-joint。
旧检查点的ANN15956B/SHAB2F3F63CDE4CA254DA2851AB7D164110554C8EF3B6E68D5107724E1A43CFB694可从此快照仅还原该两字符差异后逐字节证明；本轮初检另外三项相符；进度后续只追加，须核原44661B前缀仍为0F66CAC3BA837B83D2A43F08A166A3B1667E45A90D873C0683FB290470E4B510。保旧报告/事件，不把旧“最终”文字伪改成今天新版本。上轮分类为ACTUAL_PROGRESS，不是工具等待。
Root按入口实际读取规则/Manifest/state/ledger/database、模板全文及需求分段；只对具体设计必要行作阅读，不把截断组合输出记全文。三位子审分别覆盖十一项/审批界限/R1证据；实际范围和最终ANN联合审阅由本轮事件记录。本轮枚举的EDA进程为空，没有本轮确认存活的工具句柄，不伪称verified wait。
本轮R1 22/R2 48/Q0 44输入bytes/hash均匹配；正式状态/Manifest/TASK_LEDGER、原HDK、R1批准源码/报告/bit/hex、DB和硬件不改。只改未批准设计文档、追加交付导航/进度及文档检查点，无业务源码/参考/功能脚本/TB、EDA/bit或网络操作。完整目标未证明完成，继续上述有限设计和已READY审批依赖。
