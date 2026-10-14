# R4-RECOGNITION v0.2设计审阅实录 v0.1

2026-10-04。DOCUMENT_REVIEW；LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本文记录作者自查与根Agent实际审查，协议独立修订复核已完成；真实后端与整体义务仍未关闭，不声称完整识别、质量或物理实现通过。

## 1. 当前对象及读取范围

当前主稿：[完整分辨率识别设计v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)，SHA256 `AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257`，83901 bytes。原v0.1按作者最终全文保留[不可变快照](../../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001-v0.1.md)，SHA256 `86E8E5D96114EABC34BB30E5410FD07DB956AF0AFB1CABB08D6CFDB98F28EF8B`，81759 bytes/461行（含末空行）。

作者 `/root/r2_terminal_numeric_review` 已停止编辑并实际全文读回，报告读前后hash相同；这是作者自查，不能称独立评审。初稿D87F…DDDC/80149 bytes已被作者收尾修订替代，不作为当前主稿的最终审阅基线。

根Agent实际读取初稿1–296行，随后实际全文读回86E8并比对全部变化，读取其297–461行与所有修订段，因此覆盖当前全部正文。另实际查R3、旧NUMERIC/ALGORITHMS/EXECUTION的对应公式/角度/NMS/端点/峰/五遍和六遍来源，并核字段、容量及有限数值界。协议独立审查者 `/root/r2_terminal_protocol_review` 实际全文读取86E8及D87F→86E8差异，提出三项具体反例；根Agent保留快照并修订AA05全文读回逐字一致，实际复读全部改动。审查者再实际核86E8→AA05完整逐行差异并复读D2/D4/D6/E0/E9/G/H/I/J，读前后两文件hash一致；报告三项原协议问题已关闭、修订范围内未发现新的具体矛盾。该协议复核未独立证明拟合/覆盖/去重数值、生产资源或质量。

## 2. 作者收尾修订与根Agent核对

| 项目 | 实际设计与根复核边界 |
| --- | --- |
| 半径hist有限容量 | 一8192项HIST按16tile真实clear/投票/读回复用，跨tile27×21 holding及两路plateau状态明确；无需同时保存16份hist。旧末9等待新首9以覆盖平滑±8及左右邻。全部tile与延迟峰完成才seal，513峰为CAPACITY |
| 五遍圆及重复 | A/B重放同原A成员相对新c1估r1，C/D重放同C成员相对c2估r2；E全POINT冻结geometry。最终kind17仅诊断，不求新中心。相同cx/cy/r精确CIRC不二写且最终统计须同值 |
| 四NMS与跨π | 原ALGORITHMS/EXECUTION说明四快照为first0/1和rolling末两行，边界θ511及延迟θ0最后处理；主稿E4引用相同路线。ρ镜像276−r，padding不参与。实施前的局部逐拍设计仍需显式落实该四槽角色，不得凭四数组名宣称时序已验证 |
| 端点与censor | R3 TLS的rho为绝对Q4法线截距，μ/t投影为相对图中心；因此Bn不重复加normal中心项，Bt保留tangent中心项。第6遍真实M2端点tie成员接触guard须OR到对应censored，不能任意选一个成员或用旧CELL重猜 |
| 有限边距离 | 最近侧使用N_iD_j全宽分数比较；support门明确为R3 exact RNE q而非未舍入连续距离。四侧唯一分配、required侧统计及SSE同冻结geometry；kind18只诊断，不重拟合 |
| coverage与dedup | 可见长度、1px占用bitmap与部分首末长度分开；精确T²/U²K门与展示RNE比例分开。几何tol全宽平方门后重扫真实support交并集，阈值65535时I<U不能因RNE展示相等而合并 |
| VC/FONT/holding | VC flags按FINAL低3位重映射，不直接copy CIRC圆心图外位；FONT为独立私有ROM，不覆盖R3未用零word。列出跨tile、DENSE、当前记录及接口holding，未假定其为0或报假全机FF |

根Agent未在以上已读修订中发现新增数值/算法文字矛盾；这不是全部数学定理证明或仿真证据。真实可综合映射、完整逐拍后端、生产profile与质量依然未确定。

## 3. 实际字段与容量算术

根Agent实际求和RJ2257、KEY287、RSP872、CLOSE295、ACK504、TERM2606、RECT512、VC400、COVER_META320、CIRCLE_CTX384及PROFILE.structure192，全部相等。字段算术不检查动态流控、closed证书真实性或结果正确性。

| 设计量 | 核对结果 |
| --- | --- |
| D7全部逻辑容器 | 17,526,269 bytes，与逐项表相等；不含SRC/GRAD/EDGE、目录、journal、真实pending、ROW/ROM/R3等 |
| NMS四行 | 1108×21=23268bit，ceil字节2909，末byte高4bit为0 |
| 最大anchors768的全pair | 294528 |
| 最大SEG1024的全pair | 523776 |
| PAIR512四边组合 / 三边组合 | 130816 / 524288 |
| E=N时DENSE32组及16票更新 | 66,355,200组 / 1,061,683,200更新 |
| q16的N项SSE上界 | 8,905,772,396,160,000，小于2^53=9,007,199,254,740,992 |
| uint18距离的N项总和上界 | 543,579,724,800，小于2^39=549,755,813,888 |

DENSE即便理想100MHz每沿完成一次更新也至少10.616832s，实际read/write、数值与其它阶段延迟另计。该分支尚非生产实时方案；不能以“资源优化”或较少seed宣布吞吐/95%通过。17.5MB是当前保守逻辑分表选择，需要真实架构重划或完整存储服务，不能变成Ti60片上RAM结果。

## 4. 保留的质量与失败边界

保持完整1920×1080、任意旋转、三边/整条边缺失、重叠与负样本；撤回的尺寸/数量/对比/噪声/遮挡硬边界未恢复。anchors/seed/offset抽选明确是算法启发式；遗漏进入独立GT的FN，不伪装输入非法。

真实表满是CAPACITY；主动验证预算达到且仍有合法未评估候选是SEARCH_INCOMPLETE，两者均不发布前缀。64 keeper是内部容器容量，65真实独立keeper造成失败，不能把质量数据集限定为64目标规避。独立每类P/R95%、同类IoU0.5最大基数一对一和失败帧GT FN仍未运行。

## 5. 独立协议修订与待闭合义务

三项独立协议反例已按v0.2修订并实际复核：

| 编号 | 86E8原问题 | AA05修订及复核 |
| --- | --- | --- |
| R4R-RF01 | 全数据响应成功，但CLOSE_ACK首次status1/closed全1时可能遗漏新增失败 | 真证书结credit，同时新增CLOSE reason15/mask；首次原因/定位真实锁定，旧错误保留，阻COMPLETE；first_IO仍只RSP，完整ACK独立记录 |
| R4R-RF02 | IF01取消新RJ与IF07只匹配旧active相冲突 | IDLE同沿新RJ不参与CANCEL匹配，返回NO_MATCH；父必须在新H成为旧active后取消，不把NO_MATCH当已取消 |
| R4R-RF03 | TERM held/fire/GAP晚取消及残存ACK未明确阻下一任务 | 未published时控制fire/新错误/ACK形成阻TERM；published后只ALREADY、不改冻结body；CANCEL/RX/check/ACK都真排空且后续旧槽空后才新RJ/epoch |

实际完整diff仅第1/116/122/163/243/333/406/408/436/444行变化；T17/T19同步，H追踪仍覆盖，消息位宽/算法/容量不变。以上只是对应局部文档反例关闭，以下整体义务仍OPEN：
- R4R-B01/B02：真实完整backend、物理bank/word/端口/延迟/atomic组/资源与最终profile、性能分支。须区分比赛算法需求、重放/冻结选择和软件验证存储义务后决定重要架构。
- R4R-B03/B04：全GRAD实际收集封存、目录私有refs真实返还、RECORD辅助结果目录及完整bundle、唯一分配/软件epoch桥；RC_CLOSE不是对象退休。
- R4R-B05/B06：完整文件/schema/独立参考/GT/runner/timeout与生产摄像头、显示、CDC、pin/clock/STA/吞吐仍OPEN。
- 后端/父组合及最终算法选择冻结并独立复核后，才纳入整套READY_FOR_REVIEW的指定版本/范围/基线。当前不请求提前批准或生成实现。

本轮审阅仅文字、只读来源和文档算术；无业务代码、脚本、TB、模型、工程、约束或仿真/综合/PNR/STA/bit结果。正式状态、审批、数据库、runtime及原HDK未修改。
