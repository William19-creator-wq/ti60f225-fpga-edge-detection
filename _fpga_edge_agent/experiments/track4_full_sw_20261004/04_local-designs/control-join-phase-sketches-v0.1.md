# 控制联合阶段中文草图 v0.1

2026-10-04；关联[CONTROL-JOIN v0.1](../../../planning/design-TRACK4-CONTROL-JOIN-001.md)。状态LOCAL_DESIGN、未批准实现。本文补主稿D/E的阶段与边界，不新增另一套字段定义；CJ-B01…06保留。所有场景仅文字走查，功能仿真NOT_RUN。

阅读次序：主计划整体→联合稿B/C→D各消息/身份→本附件阶段表→反例→联合稿G/H与[实际评审](../05_reviews/control-join-review-v0.1.md)。旧父稿保持原字节，明确覆盖范围见联合稿J。

## 1. 容量、身份与完成点

- UI保存事件、FM生命周期接纳、DP阶段效果完成、FM终态交付是四个事件。运输保存ACK不证明阶段效果；生命周期done不证明旧DDR scope已经FREE。
- primary P605与独立R669分别有发送/接收/回复容量。R在FREEZE等待首源时也可到达；一个内部R变量不能代替独立入口。
- T接纳预留S、pF、receipt1182/done938；R接纳预留V、pR、receipt1246/done1002。R669保存父T的proposal_seq，epoch/session逐字段命中。预留不足不接纳，不到清理时临时申请新序号。
- DP最多一个正在交付的stage914/ACK920，另有持续SNAP anchor、PREP anchor及snapshot1353/ACK1359。SNAP保存成功后阶段槽可周转，anchor不能堵住后续ABORT/COMMIT。
- 提出valid后原body保持到fire；同沿操作均按沿前消息、引用和容量计算，新状态统一提交。CORE100、video pair74.25、AON25分别观察自己的posedge。
- 当前/最近关闭事务保存完整身份；更早未知旧号返回OLD且无副作用。没有无限历史表。BUSY不是已完成，不清pending身份。
- 业务C570只存现有三结果，各570+valid1，共1713bit。源六槽保留camera cfggen/Origin及绑定；同源三个结果可以拥有三个不同业务配置。

以下stage名称是非可执行设计标签；状态5bit足够表示所列冻结/恢复阶段，但具体寄存器/保持原语、枚举和总FF由CJ-B01/03/05冻结与验证。

## 2. 冻结阶段逐步执行

| 阶段 | 基于旧状态的检查和动作 | 完成/移交与保持 |
|---|---|---|
| F_ACCEPT | 合法FREEZE实际接纳，保存T、预留S/pF和全部回复；FM停止新旧策略扩展 | 提交FM pF，采集事实仍正常记账；不从core显示影子选源 |
| F_SEND_SNAP | 提出stage op0/S/p0→pF，body规范0；早到R也不能越过此阶段 | 一旦valid兑现原body，等待独立stage ACK |
| F_WAIT_SNAP_ACK | video保存anchor并安装pF/BLOCKED，形成效果ACK920 | core消费完整匹配的成功APPLIED/ALREADY效果ACK后阶段槽周转；不要求已有VSYNC、snapshot或首源 |
| F_WAIT_SNAPSHOT | 正常分支等待真实video active快照；独立1353入口始终可服务 | 有R且COMMIT未曝光转ABORT；不为取消等待首次VSYNC |
| F_SELECT_SOURCE | HAS_ACTIVE核完整ID/Origin与原结果绑定；NO_ACTIVE从完整latest或首成功COMPLETE选择 | 必须完整源；空源继续WAIT_FIRST，不用render图/safe面伪装SRC |
| F_PINNED | FM原子建立当前T所需FREEZE，原Origin/camera cfg保持 | 尚未valid COMMIT可被R选ABORT；不能清其它BIND |
| F_COMMIT_HELD | 首次提出op1/S/Origin即锁FINISH_COMMIT分支 | R只能独立保存等待；COMMIT ready0也不得撤回 |
| F_WAIT_COMMIT_EFFECT | DP核保存S的p0/pF，安装FROZEN并归还hold；等待旧通知ACK闭合后回920 | FM仍消费1353并回1359，不能等920才处理snapshot |
| F_ABORT_HELD | 无COMMIT曝光且R已接受，提出op2/V/targetS | DP封口未曝光1353；已有valid1353保持交付；实际hold可先解除 |
| F_WAIT_ABORT_EFFECT | FM收晚1353只核anchor/保存/ACK，不因其Origin新增FREEZE | DP观察1359实际消费及hold解除后回920；gate仍pF/BLOCKED |
| F_DONE | 按真实COMMIT/ABORT效果形成T done938 | 成功COMMIT为APPLIED/FROZEN；成功ABORT为ABORTED/PENDING；错误/隔离如实记录，held终态不可改写 |

stage op0保存效果与1353快照形成是两件事。SNAP与VSYNC同沿实际fire时，先禁止candidate apply并取沿前active；更早已实际APPLIED的图则是随后快照中的真实active。1353中的snapshot_hold是捕获事实，晚ABORT解除真实hold不能改已held字段。 FM保存完整1353、核anchor及移交/丢弃用途后即回1359，不等建立FREEZE、latest或首COMPLETE；通知ACK不解除持续hold。

**早到R统一路径。** 即使R早于首次SNAP valid，已接纳T仍先兑现SNAP至pF/BLOCKED，再ABORT。这保证随后恢复PREP的expected pF与video真实gate一致。不能直接报T ABORTED却令video停在p0。

**同沿分支。** 旧COMMIT valid1优先保持原承诺；旧valid0且本沿R接受时禁止首次提出COMMIT。source COMPLETE同沿仍提交完整采集事实和LATEST，但ABORT分支不新增冻结用途。已选ABORT不能因后来首源到达改回COMMIT。

## 3. 恢复与保留冻结的算法切换

| 阶段 | 旧状态、交接及动作 | 完成条件/避免互等 |
|---|---|---|
| R_PROMOTE | 已有成功SNAP及ABORT/COMMIT封口证据，原T done已交付、旧stage/snapshot闭合 | 独立R成为执行记录并提交预留pR；FAILED/Q不能替代屏障证明 |
| R_PREPARE | op3/V，TARGET0，pF→pR；video保存PREP anchor并安装pR/BLOCKED | ACK只证明屏障，不等旧active退休、旧scan FREE或新SOF |
| R_ENGINE_SAFE | 旧shared processing task收到真实终态且其局部借用关闭 | PROCESS_SAFE只约束可复用处理资源；旧active的RO/BIND可继续 |
| R_COMMIT | op由3推进4；control_seq/epoch/expected与new policy/TARGET与保存PREP逐字段相同，video提交LIVE资格 | 核anchor，不再次要求current=pF；与VSYNC同沿不新apply |
| R_DONE | FM消费真实效果ACK，撤对应旧FREEZE，开合法新ARM/job/publish | R done1002 APPLIED/LIVE；Origin规范无效，现有BIND/scope正常结账 |

目标kind1/2用于算法policy切换：kind1保LIVE、没有FREEZE可撤；kind2保FROZEN、原FREEZE位及同一完整Origin，只开该源离线job，不开LIVE ARM。只有kind0普通RESUME撤对应FREEZE。RC profile无效不能凭64bit引用宣布可识别。普通SET已held且BUSY时独立R仍可接纳，不能复用被P占住的transport槽。

视频LIVE路由资格、新计算准入、当前屏幕退休分别记账。恢复done不等待新完整源或APPLIED；新任务仍受真实PROCESS_SAFE、空result与源资格约束。旧active等待新结果后退休的关系不能反过来堵住恢复。

若SNAP/COMMIT/ABORT拒绝、失钟或效果未知，不能猜video已安装pF。已接受T/R分别保留FAILED/QUARANTINED终态义务和原身份，引用隔离，不执行正常pF→pR；可信PL恢复另行认证。已held成功终态不因后来故障改写。

## 4. 配置采用与观察草图

**JH-OP01 预留。** 只在空结果和PROCESS/源资格成立时锁沿前C570及完整结果身份，建立不可变ctx。若同沿新C提交，当前预留仍用旧C。失败不形成半份结果ctx。

**JH-OP02 LIVE准备。** 先由ctx形成LIVE_BIND438/FJ110并完成授权，再ARM/首SOF。首SOF/FJ实际采用只报告已锁ctx，不重新读取当前C。不满足前置则capture-only，不能半帧补接FE。

**JH-OP03 同源重处理。** 原源Origin及camera cfg不变，另一空结果预留时锁新的业务C；三个结果可以不同配置。源表不保存一个会覆写旧结果参数的“当前业务cfg”。

**JH-OP04 实际观察。** 用完整J/ID查现有三ctx，复制USED1057/APPLIED1322后归还metadata借用；UI held读取使用自己的固定值，live继续更新。APPLIED业务ACK、退休、返还不等待UI消费。迟到APPLIED不修改D/C，不从当前参数拼造历史配置。

**JH-OP05 两lane序号。** 唯一CONTROL allocator在held valid提交时分配；较小P首次visible不晚于较大R。FM同沿先登记两lane完整body，再推进global_seen。较大R先fire后，已登记较小P可重试；未知旧号不重新执行业务。

**JH-OP06 AON与暖保持。** 四raw键只进AON同步/消抖；KEY1 LONG独立PL117 kind1/mask0x1FFE/reason0。UI/P满或CORE停钟不堵AON请求。旧T/R/seq/held/引用保持至PL认证旧会话关闭；失钟或期限不证明drain，保持pending/Q。LED只显示分层状态，不代替关闭证书。

## 5. 八组反例与文字走查

| WALK | 输入/顺序 | 期望、错误做法及关联 |
|---|---|---|
| JH-W01 | FREEZE接纳→R接纳，尚未提出SNAP | 必兑现SNAP至pF，再ABORT→R PREP；直接跳过SNAP会使合法expected pF失配。CJ-T08/17 |
| JH-W02 | SNAP ACK已将g改为pF→COMMIT仍带p0/pF | 核保存anchor，不能再次比较g==p0；否则合法冻结永久被拒绝。CJ-T16 |
| JH-W03 | COMMIT valid1、ready0→R接纳 | 保持并兑现COMMIT，T真实终态后R；不能撤回原body或无条件写ABORTED。CJ-T12/14 |
| JH-W04 | 1353 valid未交付→ABORT、FM等待920 | FM仍收1353并回1359，DP通知闭合后920；互等1353/920构成死锁。CJ-T09/13 |
| JH-W05 | NO_ACTIVE/WAIT_FIRST，primary SET已held/BUSY→R | 独立669入口接纳；取消不等首源/VSYNC，已接受R不可被后UI覆盖。CJ-T01/08/11 |
| JH-W06 | POLICY_COMMIT与VSYNC同沿，旧active仍有RO | 本沿不新apply，下次合格VSYNC才用新资格；历史J不覆写，旧RO合法重复。CJ-T19/20 |
| JH-W07 | result预留同沿C更新→FJ held→再改参数/SOF | ctx锁旧C且FJ保持，首SOF不重新锁；同源新result才用新C。CJ-T03/04/05 |
| JH-W08 | UI observation ready0、APPLIED/return到达，随后warm fault | 独立业务链继续；held观察/终态保持，fault不能改写旧成功或伪造FREE。CJ-T06/22/23 |

逐接口字段/ padding、seq耗尽、错误parent和无匹配旧包见主稿CJ-T15/21/24。本文没有可执行checker或testbench，没有运行上述场景；后续独立参考和真实RTL/CDC/器件PHY验证各保存证据。

## 6. 预算、追踪与剩余范围

R669/receipt1246/done1002；T/R原body保持量5642bit；primary P/reply1787bit；stage914+ACK920+snapshot1353+ACK1359=4546bit每套；三结果cfg1713bit。运输端副本、有效位、状态、seq、去重缓存及观察值另计，不声称全机FF利用率。无新增图像RAM、PLL或DSP；已列174RAM仍为整体候选预算。

JH-OP01…04→CJ-J01/06/08、IF03/07、I08/09、T03…06；JH-OP05→J02/08、IF01/02、I01/03/09、T01/02/15/21；JH-OP06→J07、IF08、I10、T22/23。冻结/恢复阶段→J02…05、IF02/04/05/06、I01…07、T07…20。对应计划符号在主稿H；真实代码/验证证据尚未生成。

完整数据/关闭联合端口、PROCESS_SAFE/错误枚举、冷初始化/保持实现、RC实体、真实2Gb模型/IP/serializer、QoS/资源/STA和指定范围批准仍阻塞。文档写入、算术或走查不能替代READY、功能通过或本次bit/hex交付。
