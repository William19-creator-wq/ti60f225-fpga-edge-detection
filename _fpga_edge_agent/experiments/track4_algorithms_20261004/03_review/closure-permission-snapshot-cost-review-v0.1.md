# Canny闭包稳定权限快照：费用与条件工作量读回 v0.1

2026-10-05；LOCAL_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。纯文档核算，不是RTL、仿真或性能结果。

结论：三行稳定权限/几何快照能替换普通访问的逐次冷目录全文读取；完整INIT、动态检查、599/674双许可、676/684关闭及实际日志提交仍保留。当前候选仍NOT_READY，不能由减少读取次数推导整机装得下、达到某算法帧率或已完成完整Canny。

## 1. 阅读顺序与输入

先读[整体与接口候选PS](../../../planning/design-TRACK4-ALGORITHM-CLOSURE-PERMISSION-SNAPSHOT-001.md) B/C，再读D/E了解稳定资格、动态状态和两份真实旧请求如何交接；本报告复核F的费用与工作量，最后返回I查看尚未解决的源封口和实际IP资格。

| 输入 | 本次读回版本/采用范围 |
|---|---|
| PS，193行/31594字节，根原全文1–191及ACK修订97–103 | `0D96E90EDF0F3D6620E5DE9BAAB441ADC4508715C0D110BBBA9780CC8EAF11AF`；D1–D3、E/F，不代正式基线 |
| [NS](../../../planning/design-TRACK4-ALGORITHM-CLOSURE-NATIVE-SERVICE-001.md) | `96636AD3E8ED891880355EF4D3040ACF30EFE901662C657E9649C9EEB8423942`；原逐次冷查验和journal事件式 |
| [CW](../../../planning/design-TRACK4-ALGORITHM-CLOSURE-WIRING-001.md) | `13FB501DC3EB9AD2C86ABD8CD571340301EB9A54FCEC77AED49890F04B212D00`；42677bit选定账、INIT每chunk prefix 96事件 |
| [BK](../../../planning/design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)，根本轮66–136 | `2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060`；完整body、INIT、两许可、JNL、真实quiet |
| [DIR](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，根本轮81–131 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；640/512、holder及rounded几何 |

作者及两位独立读者的具体实际读取范围和最终意见另入本轮checkpoint；不把根本轮分段读取写成旧卡全文读取。本报告没有新增功能输入、执行脚本、模型、向量或工具调用授权。

## 2. 位宽和资源位置

| 实体及有限位置 | 算式/bit |
|---|---:|
| O三行稳定body，各含完整borrow_id和rounded容量 | 3×410 = 1230 |
| O共用H、generation、epoch、role、stage_index、JID | 358 |
| FENCE源、当前L/C目的、S目的 | 3×235 = 705 |
| SOURCE_FREEZE源和O目的；STORE_FREEZE源和O目的 | 2×692 + 2×720 = 2824 |
| FROZEN_ACK源、S目的、当前L/C目的 | 3×246 = 738 |
| PS逐项选定控制 | 71 |
| 本候选新增合计 | 5926 |
| 与CW选定位置合计 | 42677 + 5926 = 48603 |

410 = 4×64 + 2×6 + 8 + 32 + 2×29 + 10 + 22 + 2 + 1 + 2 + 6 + 1。
358 = 160 + 64 + 32 + 4 + 2 + 96；holder_link160 = 4 + 6 + 64 + 32 + 54，kind的位宽是4、值是3。
692 = 235 + 1 + 324 + 1 + 1 + 64 + 1 + 64 + 1；720 = 235 + 324 + 1 + 1 + 2 + 2 + 1 + 64 + 1 + 64 + 1 + 3 + 21；246 = 235 + 2 + 6 + 1 + 1 + 1。
71 = (3+6) + 20 + 12 + 21 + 9；10个transport valid分别对应FENCE3、SOURCE2、STORE2、ACK3，另有两个ACK消费pending。

这些是有限body及具名控制的费用下界。保留BK/S/O原完整599/674/676/684、assembly、JNL、physical adapter、CH/M1及returned metadata；未纳入全机所有控制、组合检查LUT和借用台账，不能称完整FF/RAM/DSP预算或fit。未来综合可能重映射，必须用实际实例账与map报告更新；未从没有计入CW的SC热cache扣费用。

## 3. 同口径事件数量

N=1920×1080=2073600；P=N/2=1036800。GENERAL密集场景K=2067604、B=16540832。普通AUTH次数Q=3N+3K+B=28964444；实际journal entry数w=N+2K=6208808。两条快路径明确限queue_ref=0：NO_STRONG的Q=N，NO_WEAK的Q=2N；二者w=N。

| 数量 | GENERAL密集 | 两条queue_ref=0快路径 |
|---|---:|---:|
| INIT chunk I，每chunk最多4拍 | 141750 | 12150 |
| INIT beats/bytes | 567000 / 9072000 | 48600 / 777600 |
| INIT holder读事件 H_init | 3393900 | 542700 |
| INIT全查事件 A_init | 12465900 | 1320300 |
| 独立建立快照另增RE | 378 | 292 |
| 其中另增holder RE | 122 | 100 |
| A_init + 已选独立capture | 12466278 | 1320592 |
| H_init + 已选独立capture中的holder | 3394022 | 542800 |
| journal WE=30w | 186264240 | 62208000 |
| journal RE=29w | 180055432 | 60134400 |
| 原相串journal阶段=59w | 366319672 | 122342400 |

已选capture为INIT之后独立per-row全文查验：LOAD 120RE + CLO 3×86RE =378，其中56+3×22=122为holder；queue真缺席时292/100。不能把之前ACQUIRE曾读过的、已经复用的assembly算免费捕获，也不能同时又减掉共享holder。REGISTER、RETURN、PUB和行政关闭费用未由此消失。

ordinary的0cold RE只表示不重复全文冷查，仍有逐字段热检查、S/O真实动态状态、permit借用及原AUTH/END握手。PS的最早a0到a5仅是已建立scope、动态tap可用及无等待情况下的至少5个interval；不是每拍一请求，不是完成上界。CLASS最新值、QUEUE tail/head、INIT prefix、phase、原子group_visible及物理effects均不由row提供。

## 4. 条件下界和未知上界

| 保留条件 | GENERAL | 两快路径 |
|---|---:|---:|
| 串行INIT holder查验与原S journal阶段相串：H_init+59w | 369713572 | 122885100 |
| 再保持每INIT等待684及CW prefix 96I事件与journal相串 | 383321572 | 124051500 |
| 另假定单native issue口与相同串行阶段：A_init+96I+59w | 392393572 | 124829100 |

以上是相应条件下的事件/interval下界，排除hot AUTH/END、capture、其它native工作、物理等待、source/consumer与显示争用；不能当实际cycle总数、秒数、算法fps或成功证据。新版不再沿用NS包含ordinary cold holder的旧floor。这里没有修改完整1080p、完整闭包、原识别困难场景或增加算法fps验收门槛。

完成上界仍须将一次性M（bind/INIT/capture/fence/phase/RETURN/CH/PUB）与每类真实操作数量乘以其完整服务时间逐项相加；每项包含真实热授权、journal、FPI、END、reply及公平仲裁等待。各μ、输入节拍/缓冲与共同实例仍未冻结；降低冷读取次数不能填补这些未知数。

## 5. 语义反例和当前结论

已把两个不同旧身份分开：上游已published而S未accepted的全324；S已accepted却尚未形成599的全324。联合fence先记旧fire，快照ordinary gate关闭后仍保白名单旧许可；旧CLAIM第一/第二span与既有599/两674合并，每span至多一次，不凭新proof增第三许可。成功ACK只表示两proof已经锁定，不等effect quiet，避免旧AUTH等待ACK而ACK等待旧AUTH的循环。

根提出的C0已held CLASS125、L已接125而未formed324、CLO已锁生成状态而未publication，已在PS D3/T05/I的PS-B02具名保留OPEN。SOURCE_FREEZE692仅捕获324边界，不能证明这些上游债为空；纯静态权限变化可延期到原scope正常关闭，故障/取消必须有真实parent/C0/L/C终结接线并兑现已held。没有这些证明时不得启用快路径或称access quiet。

独立语义读者建议已加入PS ACK修订：progress真消费只清ACK运输槽，proof/expected继续保留；O两个pending真清后才形成同echo终结ACK，不另开FENCE/预算且不等data quiet。仅成功ACK表示边界安装；进行中或失败ACK的消费不能作成功证明。字段/费用没有变化，真实控制接线仍属于PS-B02。

PS-B01真实DDR IP no_future_effects/可见性/共同reset、PS-B02完整source与动态接线、PS-B03全机资源及正常服务上界仍未解决。维持NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED/NOT_RUN；下一步优先闭合实际owner及源终结路径，再决定有限快照是否能共同冻结。当前R2的既有明确审批问题保持待答，R1批准及本地审计例外未扩展至本设计。
