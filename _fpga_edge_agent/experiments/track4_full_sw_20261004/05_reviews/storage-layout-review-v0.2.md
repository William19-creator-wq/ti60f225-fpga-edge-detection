# STORAGE-LAYOUT v0.2：联合覆盖、DENSE发起间隔与剩余输入缺口

2026-10-04；[当前主稿](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)最终SHA256 **C68D9657CE43D10F986AD975ED9A79EC7A18AA6893868FBFAE6BE9F8F1315FDB**，38689 bytes。LOCAL_DESIGN / NOT_READY / NOT_APPROVED；[v0.1原字节](../../../planning/design-TRACK4-STORAGE-LAYOUT-001-v0.1.md)及[原审计](document-checks-storage-layout-v0.1.json)已保存，分别SHA1B2D2C5621AFAE0B13070C584DEAEDF4969F6B1B63321CC3410F1115267E5270、6FAA3792A8CAD9747EFBF4FADA5799B2F41E9D3234652CB2530A0498C628493B。[v0.1审阅](storage-layout-review-v0.1.md)保留其真实读稿范围，不冒称审过本新稿。

## 1. 本轮实际闭合

RC方向实际重读RC/NUMERIC/ALGORITHMS/EXECUTION/DS/DATA-JOIN/DISPLAY/预算及v0.1，root查对应原文并实际读回v0.2；DS/PL方向重读部分账本字段和计账协议；IP方向重查公开wrapper、clock连接/官方参数与源。所有都是只读设计分析，未生成业务代码、脚本、参考/TB或运行构建。

DENSE e0…e5为六命名沿、相邻RE最早间隔5 CORE周期。32E组不变；E=N时5×32E＝331776000周期机会，100MHz名义3.31776秒，只是条件工作量，不是帧时间/FPS。旧四命名沿对应II3、199065600不可用于新布局；不能误按6×32E。

capture336/writehold336保持各16×21位lane，低20bit存nativeword、bit20零，不改为连续320切片，也不扣富余32位。e1低capture；e2沿前low capture＋高RAM Q扩22检查，new low进writehold/new full high进capture；e3低WE/e4高WE/e5下一RE。bins/valid/point/ctx保持。低WE未发生的取消capture/DISCARD旧RE即可；低WE已发生则保留low_WE_committed事实与旧holding/owner，必须完成配对高WE，之后才闭合当前RMW。取消与WE同沿按实际事件判定；Q/失钟未证实高WE完成则不闭合，不推进下一point或成功发布。

上述容器复用及取消细节经RC方向明确限定核对相容于E3/E4；其读取的旧主稿仍是1B2D版，修订草图判断和新稿全文读回分开。RC28144局部预算不继续扣：receipt693可回显坏件、STATUS965可能Q冻结、best400/FORMAT512/FINE400/WORK384及R_RECORD384/terminal301/Rholding139/双bank160均有不同同时寿命。

主稿J新增精确父覆盖表：RC模式池88→74及105→91；EXECUTION P1…P3/native布局；SEG COMMIT20WE→19WE且末WE下一沿DONE；DENSE II；DISPLAY旧cache/1248机会改条带/双54槽；PROFILE1024只RC_BIND一份。未列父语义保持，RC91/DP17/自写207、省18不变。DS/PL串行仍未选择。

## 2. DS/PL备选逐bit调查：没有把未知填零

下面是可并入下一联合版的内部低位先排候选，外部消息位序不改，未采用完整串行架构或声称10438/7769已闭合。完整源及旧地址表沿[v0.1审阅](storage-layout-review-v0.1.md)与当前审计hash。

| 容器 | 能定位的字段 | 最小真实缺口 |
|---|---|---|
| scope mutable688 | generation0…63；opened64…91/closed92…119；grantmask120…151/phasemask152…183；四64计数184…439；cancel_seq440…503/close_seq504…567 | 四计数名称/事件256bit和568…687的120bit未定义；原origin/cause/cancel_seen/首error/RESP/seq有效是否已含未证实 |
| phase cold518 | scope_handle0…67/token68…131/client132…134/phase135…136/kind137…138；RWmask139…202；client/region/dir203…218；accepted219…282/released283…346/cutoff347…410/first_error_seq411…474 | 尾43bit未完整；CERT可固定475…489的15bit，490…517的28bit不可当padding |
| phase live381 | RWmask0…63；accepted64…127/released128…191/last_seq192…255/first_error_seq256…319；scope/client/phase320…328；state329…331/error332…334；16flags335…350；kind/cause351…354；permit/held/live_count355…366；borrow367…369；error/cause370…380 | kind/cause4及尾11bit语义/编码未闭合，计数/borrow增减事件须补表 |
| record hot113 | phase_slot0…4/pool_slot5…7；live数量8…43；prepare/state44…54；RESP定位55…68；terminal69…84；release/ACK85…93；promise/ref94…106；borrow/pending107…112 | 各分组不能仅凭加总自行命名；terminal16可固定，其他子字段仍未完整 |
| PL route80 | sender/receiver session0…63；toggle64/65；两组三同步66…71；sender/receiver_owned72/73 | close6的74…79未定义，24条具体sender/receiver/typed body/槽与独立endpoint-ready/恢复扇出未完整 |

live16flags依父次序为valid/has_req/first_error_seq_valid/seal_requested/local_quiesced/snapshot_pending/snapshot_committed/certificate_valid/certificate_consumed/success/drained/counts_final/cancel_seen/grant_pin_held/cold_busy/parent_close_requested。terminal16可固定kind69…70/success71/drained72/error73…75/actual_beats76…82/terminal_valid83/terminal_seen84；冻结body不被后来live数量覆盖。phase grant_pin须在实际RELEASE ACK消费后下降，不能先要求下降才ACK。

PL24候选只由12health＋3reset＋4mirror/manifest/entry＋1fault＋4recovery算得，不证明覆盖全部关闭路径。PL C已经规定sticky stop_new（异步置位/合法本域同步释放），旧审阅称inhibit为新接口不准确；其物理域/原语映射仍待证实。

## 3. journal共同计账的反例与必须补的合同

旧两pending位不足以自动说明两目的RAM计账：req_fire置accepted_pending→phase计数先WE→scope尚未WE→查询若读phase RAM＋全部pending，会双计。release事件相同。联合版本须明确选择“两对象锁到共同提交再开放查询/清pending”，或“保存各目的已应用状态、查询只加该目的未应用事件”；不能把所需状态藏进未定义flags自证容量。本轮未选择实现，DS24/PL22仍备选，不把语义问题改标普通未运行测试。

snapshot排journal期间，旧held ACK仍可稍后真实消费；冻结必须包含它们已计账的真实证据，或明确后续进live/不改冻结body的cutoff。禁止新ACK形成不撤旧held，不阻物理R/B/关闭；reset/Q保持journal及原record/phase/scope身份到提交完成。PREP安全处置Q不等于普通RELEASED ACK，不能伪加released或将冻结Q改成功。上述反例影响共同计数、CERT及可回收条件，先补语义再完整逐bit/资源。

## 4. 真实IP边界与可执行下一步

v6公开顶层虽然连接CSI .clk(i_mipi_clk)，但assign i_mipi_clk=core_clk，实际core由MIPI_TX_PLL#0的100MHz输出；CLOCK_FREQ_MHZ100单独不能证明接线，别名已沿源码追到。v6 DDR axi/core也接此core_clk且ASYN1；DDR3_PLL#4的clk_100m是另一PLL net，目前rclk。同步候选须真正迁移统一业务域到#4并验证分布/SDC，不能称现v6已如此接线或保护内部已去桥。

FIFO1024满足本地官方RAW10/1920的>300最小深度规则；这不证明PPC/burst/error归属或真实RAM数量。公开资料没有ASYN0内部桥/reset完整行为，不能预扣17RAM；DDR等待也无已证最大界。当前SDC的CSI byte声明100与参数70分叉仍须用实际peri/net检查。新CSI/旧DDR/编码器资源和有限服务仍影响整机READY。

[IP-PRECHECK v1](../../../planning/design-TRACK4-IP-PRECHECK-001.md)提供四个有限参考case、输入manifest89文件、具体delta及六文字场景，以当前工具编译/综合/clock/PT/PNR/STA形成真实输入证据。它不做2Gb器件校准/TB/bit、不改算法范围、不用4Gb模型替代2Gb；源/工具/许可/DB/指定批准按原制度。此实验若READY也不提升整机READY。

## 5. 本轮证据与下一闸门

本轮保存读回v0.2、字节历史、实际差异审阅与IP预检设计/manifest，修正主计划A的旧版本号。文档hash/链接/表格/追踪和静态算术与未来12 SL/6 IP文字场景分开。完整十一功能代码、真实仿真、综合/PNR/STA/约束/bit仍未生成或运行。

SL-B01已精确覆盖RC/DP父差异，但全热冷/路由/计账仍缺；SL-B02真实IP/模型/clock和B03有限service/原指定批准/DB仍保留。现有FE/模型申请不重复索取；只在IP有限设计完整保存读回并通过实际限定审阅后申请其指定批准。当前整体目标未完成，不以设计/有限实验重新定义成功。
