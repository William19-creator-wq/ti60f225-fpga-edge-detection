# 局部设计：整体之后的工作

> 2026-10-04 当前优先范围已改为[算法路线 v1](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)和[新目录](../../track4_algorithms_20261004/README.md)。停止原具体器件/PHY模型和 DDR/IP 预检推进/审批；旧相关表/阻塞项是历史整机范围，新R1采用独立算法接口与新基线，不能以本页旧依赖拦住它，也不能将算法局部通过升级为整机完成。


先阅读 [整体布局](../02_system/overall-design-layout.md) 和 [系统级交接](../03_interfaces/handoffs-and-composition.md)。首批基础处理链设计v1已达到READY_FOR_REVIEW，等待指定批准；其他局部设计继续按依赖推进。

| 次序 | 任务与入口 | 作用与当前边界 |
|---|---|---|
| 1 | [TRACK4-FRONTEND-001 设计v1](../../../planning/design-TRACK4-FRONTEND-001.md) | MOD-06/07灰度、两个两行窗口、19比较器中值、Sobel及同域任务握手；READY_FOR_REVIEW，尚未批准实现 |
| 2 | [中文阅读与人工观察路线](frontend-reading-guide-v1.md) | 整体→交接→数值流水→RAM逐沿→验证/波形观察，指向主设计的OP-01…07 |
| 3 | [TRACK4-FRAME-MANAGER-001 v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md) | MOD-04/10源/结果账本、显示快照、八项操作草图与排空反例；LOCAL_DESIGN，有邻接阻塞，尚不申请实现批准 |
| 4 | [DDR证据](../01_baseline/ddr-address-and-completion-evidence-v1.md) / [平台证据](../01_baseline/platform-clock-pin-evidence-v1.md) | 实际v6字节地址/B响应限制、PLL/复位/SDC及引脚来源；只读核查，非功能或时序通过 |
| 5 | [TRACK4-CANNY-001 v0.4](../../../planning/design-TRACK4-CANNY-001.md) / [数值/存储审查v0.1](../05_reviews/canny-review-v0.1.md) | 完整高斯/梯度/方向/NMS/双阈值/精确八邻域闭包；状态cache、N容量队列和forward；LOCAL_DESIGN，有父端口/内存阻塞 |
| 6 | [Canny窗口/流段中文草图v0.2](canny-window-sketches-v0.2.md) / [窗口交接审查](../05_reviews/canny-review-v0.2.md) | 四行Gaussian→两行NMS→父任务/分叉逐沿；TAIL/外框/old-new反例修正；18文字场景全部未运行 |
| 7 | [Canny存储中文草图v0.3](canny-memory-sketches-v0.3.md) / [存储交接审查](../05_reviews/canny-review-v0.3.md) | 窄内存合同→cache映射/FSM/claim→银行/prefix/共享口→pop/prefetch→阶段；T19…22全部未运行 |
| 8 | [Canny父任务/writer中文草图v0.4](canny-parent-writer-sketches-v0.4.md) / [父任务交接审查](../05_reviews/canny-review-v0.4.md) | 完整job/地址→六级Sobel/四方向→顺序writer/local terminal→阶段/fence→终态/取消/恢复；T23…26全部未运行 |
| 9 | [TRACK4-DDR-SERVICE-001 v0.1](../../../planning/design-TRACK4-DDR-SERVICE-001.md) / [RAM来源](../01_baseline/ddr-service-ram-evidence-v1.md) / [实际读稿审查](../05_reviews/ddr-service-review-v0.1.md) | MOD-05授权/14叶请求/完整段缓冲/物理与逻辑终结/release ACK/阶段fence/恢复；8中文草图、16文字场景全部未运行，LOCAL_DESIGN有阻塞 |
| 10 | [TRACK4-RECOGNITION-001 v0.1](../../../planning/design-TRACK4-RECOGNITION-001.md) / [地址算术](../01_baseline/recognition-candidate-address-arithmetic-v0.1.json) / [实际读稿审查](../05_reviews/recognition-review-v0.1.md) | 完整grad32/32桶/四phase→圆矩形候选→原图核验→不可变ANN与跨行2bit图；8中文草图/16文字场景、119块已列小计；LOCAL_DESIGN有8阻塞，全部未运行 |
| 11 | [TRACK4-PLATFORM-001 v0.1](../../../planning/design-TRACK4-PLATFORM-001.md) / [读稿审查](../05_reviews/platform-review-v0.1.md) | 4PLL/复位保持/完整scope镜像/PREPARE→FINAL恢复/CDC与pin，8草图/16文字场景，149RAM已列候选小计；LOCAL_DESIGN，有8阻塞 |
| 12 | [V4引脚来源v2](../01_baseline/board-pin-source-evidence-v2.md) / [摄像头来源v1](../01_baseline/camera-source-and-phase-evidence-v1.md) | 原理图/当前封装至球号、电源、KEY1/NC/极性，以及SC431时序/164条ROM/ACK/Bayer条件；资料复核非实测 |
| 13 | [TRACK4-CAMERA-001 v0.1](../../../planning/design-TRACK4-CAMERA-001.md) / [窗口与writer草图](camera-window-and-writer-sketches-v0.1.md) / [来源v2](../01_baseline/camera-csi-and-config-evidence-v2.md) / [读审](../05_reviews/camera-review-v0.1.md) | 配置/资格撤销与观察window→RAW4/2/真实边界→四色phase/reflect101→6B组拍/段借用→FP74 live→closure水位/fence/返还；24主场景+12附件场景未运行，162RAM已列小计；LOCAL_DESIGN有8阻塞 |
| 14 | [TRACK4-DISPLAY-001 v0.1](../../../planning/design-TRACK4-DISPLAY-001.md) / [取数与扫描草图](display-fetch-and-scan-sketches-v0.1.md) / [读审](../05_reviews/display-review-v0.1.md) | render/上下比较→3双clock行bank→6pair逐沿→current/future与SELECTED/CLOSED→真实active冻结→bank/scan/scope关闭；24主＋15附件场景未运行，174RAM预算；LOCAL_DESIGN有8阻塞 |
| 15 | [VF/Demo补充证据](../01_baseline/vf-demo-supplemental-evidence-v1.md) / [HDMI与取数来源](../01_baseline/display-hdmi-and-fetch-evidence-v1.md) | 具体DDR/PHY模型和公开TMDS候选、4Gb/2Gb与C4/I3边界；只读来源，未运行新工程 |
| 16 | [TRACK4-CONTROL-001 v0.1](../../../planning/design-TRACK4-CONTROL-001.md) / [人工操作草图](control-human-operation-sketches-v0.1.md) / [四键/复位来源](../01_baseline/control-keys-and-reset-evidence-v1.md) / [读审](../05_reviews/control-review-v0.1.md) | 四键低有效/21样本消抖→有限槽与AON独立复位→CFG212/D-P-C及来源→T/R冻结恢复→USED/APPLIED/LED观察；24主场景未运行，新增RAM0，LOCAL_DESIGN有8阻塞 |
| 17 | [TRACK4-CONTROL-JOIN-001 v0.1](../../../planning/design-TRACK4-CONTROL-JOIN-001.md) / [阶段草图](control-join-phase-sketches-v0.1.md) / [读审](../05_reviews/control-join-review-v0.1.md) | 独立R669→SNAP成功屏障/COMMIT承诺→stage914/920与snapshot1353/1359→policy/历史active→result锁C与AON；24场景/8走查未运行，LOCAL_DESIGN有6阻塞；只覆盖明确控制差异 |
| 18 | [TRACK4-DATA-JOIN-001 v0.1](../../../planning/design-TRACK4-DATA-JOIN-001.md) / [实际读审](../05_reviews/data-join-review-v0.1.md) | B/C整体→D消息/授权与组合→E中文步骤：首SOF前身份/START关闭、reader/FE、local/phase/归还、显示与恢复；24场景全部NOT_RUN，178RAM仅预算；真实外部/RC参数/服务界仍阻塞 |
| 19 | [TRACK4-RECOGNITION-NUMERIC-001 v0.1](../../../planning/design-TRACK4-RECOGNITION-NUMERIC-001.md) / [实际读审](../05_reviews/recognition-numeric-review-v0.1.md) / [官方接口依据](../01_baseline/vendor-interface-contract-evidence-v1.md) | 整体→POINT/角度/ρ与记录交接→舍入/拟合/宽算术中文草图；8次角比较、277对称ρ与两ROM，最新180RAM仅预算；候选覆盖/分段/配置选择及质量仍阻塞，全部业务验证NOT_RUN |
| 20 | [TRACK4-RECOGNITION-ALGORITHMS-001 v0.1](../../../planning/design-TRACK4-RECOGNITION-ALGORITHMS-001.md) / [实际读审](../05_reviews/recognition-algorithms-review-v0.1.md) | B/C整体→D记录/模式→八OP：圆抽样/多半径、dense/分段/TLS/三边、量化核验/精确去重/字形；18文字场景NOT_RUN，225RAM仅预算；局部执行/全机服务与外部前提未闭合 |
| 21 | [TRACK4-RECOGNITION-EXECUTION-001 v0.1](../../../planning/design-TRACK4-RECOGNITION-EXECUTION-001.md) / [实际读审](../05_reviews/recognition-execution-review-v0.1.md) | 整体/完整job→RAM word/模式→圆五遍/矩形六遍与真实submask→coverage/VC/FINAL→row/carry/spool/关闭；15文字场景NOT_RUN，225RAM和29168bit局部估计，非READY/非批准 |
| 22 | [TRACK4-RESOURCE-SERVICE-BUDGET-001 v0.1](../../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md) / [实际审阅](../05_reviews/resource-service-budget-review-v0.1.md) | 唯一容器/RAM/FF/外部IP→服务期限→工作量与优化比较；225只是自写RAM，全宽FF直译未闭合；已有语义保留，全部业务检查NOT_RUN |
| 23 | [TRACK4-STORAGE-LAYOUT-001 v0.2](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md) / [实际审閱](../05_reviews/storage-layout-review-v0.2.md) | RC74＋17＝91、SRC15＋EA2＝17，自写225→207；位/word/端口→中文逐沿与关闭→数值→12文字场景NOT_RUN；联合metadata/IP/service未闭合，NOT_READY/NOT_APPROVED |
| 24 | [TRACK4-IP-PRECHECK-001 v1](../../../planning/design-TRACK4-IP-PRECHECK-001.md) / [输入89文件](../01_baseline/ip-precheck-inputs-v1.json) | 原v1/v6四case→ASYN/真实CSI/clock→当前工具资源/PT/PNR/STA；六文字场景NOT_RUN，READY_FOR_REVIEW/NOT_APPROVED；不代替完整NORM/器件校准/十一功能 |

各批局部候选已按上述次序形成，控制差异先按17、数据/关闭差异按18联合稿J的明确覆盖，识别数值按19、算法选择/布局按20、执行/私有布局按21新稿J的明确覆盖；整机容量/服务诊断按22核对，22没有自行采用热冷/批处理替代布局；23选定RC/DP的物理布局作为未来联合版本候选，具体省18及DENSE访存代价按其J覆盖；DS/PL串行、FIT/scalar/ASYN0不算已选。下一步闭合联合热冷/路由、真实外部IP及最坏服务预算，并完成指定范围评审。旧候选与历史字节保留，不能继续以同类文档替代缺口证据。每批仍使用控制面 planning/PLAN_TEMPLATE.md，在 planning/design-<task-id>.md 保存正式任务设计；本目录保存阅读入口，避免复制一套相互冲突的契约。先完成不依赖DDR模型的处理核设计，不代表整机实施顺序或DDR验收门槛被取消。

每个模块必须明确：承担的 REQ；相邻 IF；数据和状态拥有者；位宽/signed/舍入；接受和交付事件；无效、气泡、反压、满空；逐拍旧状态计算和新状态提交；复位/取消；配置快照；数量、身份、坐标；RAM端口与读延迟；CDC；实现预算；正常/边界/错误走查；验证计划与双向追踪。

只有内容完整、保存读回、无当前正确性阻塞并达到 READY_FOR_REVIEW 后，才能等待用户批准明确设计版本、实施范围和基线。整体图不能替代这些内容。本轮不生成任何业务代码、脚本或 testbench。
