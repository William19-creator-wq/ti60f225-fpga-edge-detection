# TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001：完整计票的片上批次与 DDR 落盘候选 v0.1

## A. 状态、计划与阅读入口

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。按 [PLAN_TEMPLATE](PLAN_TEMPLATE.md) A–L 填写；阅读 B 整体→C 职责→D 交接→E 中文操作草图→F 数值/预算→G 验证→H 追踪→I 门槛。这是 PERFORMANCE OPT-D1 的有限展开及原 RA/JL 路线比较，没有替换现行来源，也没有冻结实现基线。

Goal：保留 1080p、每 POINT 全 512θ 投票及完整 count21/NMS，减少 phase7 LINE_WORK 每票完整 DDR 日志。Current state：原 RA 每 DENSE_ADD 做16个串行 DDR RMW，944次 journal native 操作；此前预算已证明该开销很大。Target state：16θ 当前批在片上精确计票，结束后完整覆盖写回同一个 packed DENSE 对象，真实关闭后供 NMS 读取。
Gap / Open questions：DN-B01 实际 O/SC 安装独占批次、POINT 持续资格及 STORE 最新视图路由；DN-B02 新内部 packed-span-overwrite 到 RA/JL/physical 的可信来源、许可与效果桥；DN-B03 同步 native RAM 包装、完整实例/保持槽/关闭/服务与时序预算。三项 OPEN，不能用候选字段或非零 token 当实际提供者。
Assumptions：板卡现有资源，板载 DDR 已获允许；完整五基础/六高阶、原目标/旋转/重叠/缺边/负样本/质量范围不变。E≤N=2073600 是既有 POINT 容量包络，不是用户接受的新图像限制；没有证明某真实 R2 输入可达到 E=N。
Dependencies / Milestones：有限数值/语义/成本比较→保存/读回/独立评审→有限联合修订 DN-B01…03→指定共同版本/范围/输入达到 READY→明确批准→独立 work 实现及必要软件验证。R1 已批准且软件交付完成，不重跑；R2 stream 和 DDR Q0 原指定问题仍待批准，不重复发问。
Artifacts / failure / rollback / completion：只新增本设计、数字附件、文档审阅记录和进度；原 HDK/参考、工具、来源卡、冻结基线、Manifest/正式 state/ledger/数据库/硬件不改。候选不满意可撤回并保留历史，没有业务副作用可回滚。本卡身份由外部检查点登记，无 Git commit。全机可实现、全部十一项及 bit 仍是后续目标。
Human gate：本卡没有获批；R1 本地审计例外不扩用。依据唯一 v0.2 §10.4，未达到并明确批准指定 READY 设计前，不生成业务源码、功能脚本、参考、可执行测试或 TB；本卡不是新的批准请求。

### 事实来源与版本

| 来源 / 本次用途 | SHA256 |
|---|---|
| [PERFORMANCE](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) OPT-D1 数值候选 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 |
| [R4R](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) phase7/512θ/投票与 NMS | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [RA](design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md) 原逐 lane/assembly/效果流程 | 33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA |
| [JL](design-TRACK4-ALGORITHM-JOURNAL-LEASE-001.md) 单 pool、ordinary1 租约/退还 | 68308B965400E50B367C7B2D73BA13F777D78501B29047D0B3F3F010E056FDB5 |
| [SM](design-TRACK4-ALGORITHM-RECOGNITION-STAGE-MAP-001.md) 禁 DENSE op1/phase 及读门 | 5DBAC492D10C6CE752B8C9AC236906A72305855F4F78803AA9BDA2630FE5EA09 |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) 真许可/旧引用关闭 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [PK](design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md) bitstream/rounded padding | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 |
| [NS](design-TRACK4-ALGORITHM-RECOGNITION-NMS-LIFECYCLE-001.md) 四行快照与批次交接 | 85B837A89412AB10D299AF1FDEA02DFCF8915A01B065F6EE525DDAA847326504 |
| [对象字典](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json) object8/9 几何 | D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
| [实例预算](../experiments/track4_algorithms_20261004/03_review/production-instance-budget-review-v0.1.md) 原开销/部分 RAM | 3F4860F3BB9698D32D17E22A125F8B29B3F89EFAB56984BED7D65E3A8B9389C5 |
| [RAW](design-TRACK4-ALGORITHM-RAW-STORE-001.md) 效果/失败/关闭 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) 唯一 pool/native/effects | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |

本次 root 实际核读 PERFORMANCE299–312、R4R113–137/256–277、RA42–74、JL42–66、SM55–97、实例预算75–105；对象 JSON 仅选择 DENSE/NMS，首轮大输出截断不计全文。三位独立调查另核数值、语义和成本的指定来源段/全文，其范围登记在检查点，不用单人局部读段冒充整包读回。

## B. 整体外部行为与正常/边界样例

DN-REQ01：保持32批×16θ，每批扫描完整已提交 POINT 的 E 个 ordinal，每组16个合法 rho 各投一次；无角度筛除、梯度投票缩水、目标限制或计数饱和。θ/rho/profile 数值及 RNE 仍按 R4R，候选不改投影算法。
DN-REQ02：本地组的16个计数与高位标记只能一起提交；同组部分计数不得成为成功结果或被外部观察。g 表示实际提交组数，匹配响应消费前缀允许比 g 落后1。
DN-REQ03：真实完整本地 CLEAR 建立低位/marker/g 零；只允许 DENSE_ADD，禁止任意 DENSE ordinary WRITE。每θ各 bin 总票=g，是单 marker 精确表示的前提。
DN-REQ04：区分 LOCAL_CLEAR_DONE、LOCAL_VOTES_DONE、DDR_FLUSH_SETTLED、NMS_READABLE；任何局部状态都不自动产生 DDR 可见性/初始化事实。NMS 只在整批落盘与旧引用真实关闭后开放。
DN-REQ05：完整写回4432个 count21 和尾14B零；728个16B内部写入组独立核许可及关闭。现行外部 op1(object8) 仍非法，不能伪造调用去绕过 SM。
DN-REQ06：取消/复位/失败保已 fire、真实16项效果、已形成回复及部分落盘历史；无未来效果没证时保隔离/Q。停止接新工作不等旧消息/写入已经消失。
DN-REQ07：原四 NMS 快照、θ511/0 ρ 镜像、tie 与 LINE 顺序保留；写回前不偷看旧 DDR 计数，下一批不得清掉仍被需要的旧本地/快照内容。

正常：批 b 安装实际独占资格→DDR 原预清及本地清零真实结束→ordinal0…E−1 每组16项同沿提交→最后回复真实消费→完整导出/728组落盘→可见/no-future/END/租约/旧运输均真关闭→NMS/快照→旧读者关闭→再清 b+1。
边界：g=1048575，一 lane 同 bin 再投一票，低20从全1变0，marker 在同一提交沿变 valid/bin；DDR 此时仍不可读。g=2073599 再投一票，count 可达2073600=2^20+1025024，精确返回；再来 ordinal 被拒。两个不同 bin 同时各需高位，或同 bin 第二次低位回绕，为不变量失败，不覆盖旧 marker。
E=0 候选保32批零表导出/落盘及原 NMS 调度，故本卡固定成本仍成立；如果以后选择跳过空批，必须共同修订空结果/关闭与成本，本卡不暗减固定工作。

## C. 职责与整体连接

候选路径：原 RC 投影/POINT→IF-DN01 STORE dispatcher→MOD-DN-NATIVE；实际 O/SC→IF-DN02 批次资格/读门；MOD-DN-NATIVE→IF-DN03 冻结导出→MOD-DN-FLUSH→IF-DN04 新内部 whole-span adapter→原 RA/JL sole pool/physical；真实关闭→IF-DN05 STORE/NMS read gate→原 NS。
MOD-DN-NATIVE 自写候选只拥有16个 bank、marker、g及当前组 scratch；不负责 POINT 构建、投影系数、全 frame 完成或真实 DDR 关闭。MOD-DN-FLUSH 按 packed 顺序冻结读取/形成128bit chunk，不能接受 caller 自报源数据。
STORE dispatcher 必须在原 RA native/permit/journal/END/held 真空后切 backend，在旧批责任真空后才切回；原 RQ799/RSP872 的保持槽是否可复用未证明，预算先保原费用。O/SC 安装和撤销真实 read/write/POINT 资格，不能只设置 cache_active。RA/JL 保唯一 journal/native/effects writer，不增第二 pool。
原 NS 四行仍走 DDR snapshot 路线，没有免费改为四片上 RAM；Θ0/1 与滚动末两行的保留/覆盖窗口不变。只维护一批本地表，导出时停止投票，NMS 阅读期间保持批次冻结，全部旧读借用结束后才下一批。
整体检查点：当前有限比较只选择“完整片上批次＋16B独立落盘”为后续联合设计的主候选，64B仅比较。真实 backend/来源/许可/关闭/全预算仍 OPEN，尚不能进实现。

## D. 接口、所有权与组合检查

| IF / 提供→使用 | 已知字段、条件与输出保证 | 相容性/未决 |
|---|---|---|
| DN01 RC→dispatcher→NATIVE | 原 KEY287/RQ799/RSP872，op5/object8/length16，index=batch5+ordinal21，payload低144为16×rho9，高368零；原 status/原因/held规范保留 | body可保，effect_ok1 的成功域必须共同改为“当前批真实本地16项完成”；不是现 RA 的逐lane DDR完成。R4R/SM/RA/RAW须明确吸收，未吸收前不称兼容 |
| DN02 O/SC→batch owner | H160、gen/revision/DENSE ref/version/grant/batch publication seq 各64、E21、batch5，合570bit只是最小共同上下文字段；真实 lease、POINT tuple/持续借用、epoch/来源/实际安装与ACK另需定义 | 570不是最终 wire宽度或完整保持成本。真实 grant/lease来源、防重放及起止/返还端口为 DN-B01；不能凭字段激活 |
| DN03 NATIVE→FLUSH | 冻结4432记录 lane-major、每记录count21；record i=277×lane+rho，低位在 packed bit 21i；只能g=E、最后组责任真空后借用 | 借用期间禁止WE/CLEAR/新BEGIN，导出每项核≤E及合法marker；借用真关闭后才释放，不把导出请求数当完成 |
| DN04 FLUSH→RA/JL adapter | phase7/object8；完整H/gen/rev/ref/version/grant、batch lease/epoch/immutable snapshot generation；chunk0…727、offset=16chunk、len16、actual span permit、低128postimage/高384零、独立seq/expected/cutoff | 新可信内部 packed-span-overwrite 分支；原JL BEGIN仅op1/op5，必须共同修订内部来源/mode与payload校验，不伪造799 op1。最终新消息/状态/证据宽度、真实prepared桥为 DN-B02 |
| DN05 FLUSH/O→STORE/NS | 单独本地clear/g前缀、实际chunk写回/可见前缀、真实END/no-future/响应消费/entry和group退休/控制静止，再安装批次NMS可读 | 不借initialized_prefix满或局部done冒充新批已发布；失败关闭/后续复用仍须真实provider证据 |

所有 scalar 除原投影有符号域外为 unsigned，valid=0不能解释为数值零。共同上下文锁到真正 retire，配置/phase不可中途改。原外部 op0 READ(object8) 只在当前批 g=E 且完整 flush settled 后路由 DDR；活动组、导出/半写回期间一律不开放。对非本地批次、重复 ordinal、错误身份不给 RE/WE 或新许可；原 RC 错误码映射需在联合版本冻结，本文不临时造一个可执行 adapter。
主方案每块为独立 ordinary1 group：member16、lanes_done成功1，保5bit宽度；728块不能放入一个原 group 并称 lanes_done728。若需要全批独占，由独立 batch lease/STORE读门保护，不让journal互斥充当跨728组授权。每块实际 END/FACK/GAP/旧metadata关闭后才下一块，失败不会跳过空洞后把prefix写728。
维持保守原 FIRST INIT 与32次 DDR CLEAR 费用；新批本地CLEAR另做。DDR预清不建立本地零态，也不证明本批投票已落盘。以后移除冗余DDR CLEAR需要明确joint revision、资格/初始化/失败证明，当前主候选不移除。
启动反压可暂停 RC，但真实摄像输入不可暂停的问题仍属生产 IO 全机合同；本设计的depth1不能吸收整帧。core单域 posedge；DDR域/物理接口CDC仍由原独立合同提供，不能把同域candidate状态推广到PHY。

## E. 局部中文操作草图

### E1. 安装、清零与表示

先保留旧责任/元数据，确认实际旧读写借用/DDR/END/journal全闭合；O/SC核phase7、DENSE整个11648B rounded独占、POINT已COMMIT身份/E/持续读资格，实际安装后才能标批次ACTIVE。重放旧seq不重新激活，publication seq64最大合法只用一次，warm/换batch不重置，耗尽拒新工作但继续履约旧责任。
每 bank 为一个 native512×20，合法数据地址0…276；277…511为不用地址，不能当277之外的ρ或冷端padding。依次277个清地址沿，16bank同沿WE零；marker160/g清零且清操作已真完成后才接首组。同步rst禁新RE/WE并使本地视图不可读，RAM内容没有因此清零，恢复必须重新安装资格并真实完整clear；旧DDR责任仍隔离保存直到真实drain。
每lane低20值来自 bank，count21 高位为“该lane marker.valid且marker.bin等当前rho”。g是该批权威已提交组数，接纳 ordinal 必须等 g，不能用响应发送次数或RQfire推进g。

### E2. 无流水单组边沿候选

| 沿 | 基于沿前旧状态的动作 | 沿后状态/外部保证 |
|---|---|---|
| e0 | 真正旧RQ valid&&ready&&!rst接受并锁799 | 后续不再读变化的caller payload；未产生计票效果 |
| e1 | 核实际资格、batch、ordinal=g<E、全部rho合法/高368零；通过才发16bank RE | native pending真实记录；不在RE发出同沿读新Q |
| e2 | 在已核同步RAM返回条件下捕获16×20bit | 320bit scratch；接口实际返回延迟是 DN-B03 前提 |
| e3 | 以旧marker/g恢复21bit；22bit临时加法核old≤g、next≤g+1≤E、marker合法及回绕不变量 | 全16通过才把scratch原位替换postimage，保存candidate_marker160/postvalid；任何一项坏则无WE |
| e4 | 旧COMMIT且postvalid时发16WE，同时更新16marker及g+1 | 这是组效果线性提交点；没有外部中途读者 |
| e5 | 根据真实提交/失败形成872，成功value/token/effect域按joint定义 | formed后body/身份/状态不随反压/取消重写 |
| e6 | 无stall时匹配回复真fire并正确消费 | 不等于自动借用/控制责任全空 |
| e7 | 真正本地pending/held/资格引用等关闭后的GAP | 禁同沿复用历史身份 |
| e8 | 满足全部前提才下一RQfire | 无stall最小接纳间隔8；额外核查/停顿可延长 |

e3 marker有效时bin必须≤276；同lane陌生bin再跨2^20，或同bin第二次低位回绕，均INVARIANT并保原权威内容。scratch原位换postimage只因严格单组/无观察者/后续WE之前不再需要旧值，不能承诺完整旧表rollback或diagnostic journal。本设计分开RE与WE，所以不依赖same-address read/write模式或未计 forwarding。
取消先按旧fire/旧COMMIT记真实效果：e4旧COMMIT和取消同沿，16WE/marker/g仍真实提交；未形成提交的已接受后缀可在已发RE捕获关闭后给失败且无WE。已held成功RSP保持成功；g可能比caller已确认前缀多1，批次最终abort保真实g，不能重投同ordinal。复位若阻止e4实际WE则不记提交；若此前已提交，不假装复位回滚。

### E3. 冻结导出、packed块与日志关闭

最后g=E且匹配RSP及旧本地责任真空，锁冻结快照，投票/clear都暂停。按lane0ρ0…276、lane1…lane15顺序，每记录只读对应一个bank一次，恢复/核count21；每记录低bit先进入packed流。选择新独立148bit bit reservoir及occupancy8：128bit块生成前最多127个保留bit，加新21bit至多148，不溢出。满128bit后整个reservoir冻结，低128bit作为immutable chunk源持续保留，不移位、不追加记录、不发新RE；直到该块真实效果/END、entry与group退还及旧运输/GAP全部关闭，才移走低128bit，剩余最多20bit作后续输入。本候选不隐含另一份免费128bit held槽；若新adapter仍需独立保持副本，必须补DN-B03实际实例预算。chunk held期间不推进其前缀。
第4432项结束，实际93072bit=11634B；在当前chunk剩余内容后补零至11648B，尾14B必须零。总728块每块128bit，地址按16B递增；不能按record对齐切块，21bit记录可跨byte/块边界。即使两个相邻record跨同unit，整块完整覆盖，不读旧DDR邻位、不擦掉同一新快照的其他record。
每块从真实冻结来源和actual rounded span许可派生内部写入意图；新adapter按ordinary1供原sole journal，保29WE/29RE校验+真实stateWE的59操作候选费用以及实际physical写/visible/no-future/END。没有旧DDR RMW值不等于免prepared/身份/padding/效果核验。RA580 assembly保原费用，新reservoir148不假称免费复用。
chunk成功/关闭前缀只在所有真实效果、ACK验证/消费及旧运输/GAP成立后推进；第728块不是整体flush settled，仍需冻结源借用、所有租约及控制元数据真实关闭。未知physical后缀保Q/已写prefix/未写suffix，不重放覆盖或改成全零假成功。已formed/held的oldphysical意图继续履约，禁止为取消直接撤回。
主候选在完整flush settled后才开NMS DDR read门；当前批本地表继续冻结。NS完成所需四行复制、跨batch边界和旧读借用真关闭后，才允许下一批localclear/DDRclear。最后batch还需θ511/0镜像/tie及LINE既有结束；本地最后成功不代full-job成功。

## F. 语言、数值、实现与成本契约

共同数值证明：完整clear后，每θ恰每已提交POINT一票，故各bin计数之和=g≤2073600<2^21。两个bin都≥2^20或一个bin两次低20回绕都需总票≥2^21，矛盾；所以每lane仅一份high marker精确。只检查每项≤E不够：任意WRITE把两个bin各设2^20会破坏证明。160marker为状态字段，不是完整FF。
C++仅后续独立逐位/流式参考，当前未生成；无动态对象所有权/异常实现可检查，非声称已N/A完成。后续采用明确整数宽度/22bit扩展/合法移位，参考维护独立完整21bit表并从真实事务比较，不能复制RTL marker作唯一oracle。软件与硬件以H/batch/ordinal/ρ、g提交与实际回复/发布事件对齐，不用函数执行顺序替代硬件沿。
RTL A数值：低20、count21、临时22、rho9合法0…276；B观察：core posedge，沿后稳定/后续沿采样；C接受：旧valid&&ready&&!rst；D气泡不推进；E所有held完整保持；F II8是条件最早；G复位隔离并重新clear；H真实batch配置锁到retire；I16bank512×20同步读包装/地址合法且严格不同时同址RE/WE；J batch/ordinal/全16rho与marker同组；K仅core同域，PHY另有CDC；L Ti60F225/I3目标，当前未综合/PNR/STA、RAM推断/频率/引脚不声称通过。

### F1. 资源、持有字段与仍缺预算

16bank有88640个有效低位bit、163840个可寻址bit，候选16 RAM10；另160marker。原170/178分支因此暂列186/194，仍是部分清单、不是全机fit，不扣原journal RAM或NS DDR对象。原32个12×17投影乘法是现RC候选，不自动新加32DSP或宣称可共享成功。
明确新工作字段小计927bit：marker160、单组捕获/待写scratch320、candidate_marker160、reservoir148、occupancy8、record_index13、chunk_index10、settled_chunk_prefix10、g21、local_state候选5、read_pending1、postvalid1、failure_reason6、publication seq allocator64。只是所列fieldset；控制编码/额外valid/取消/dirty/publication/借用/运输均仍需完整定稿，不是总FF或已综合寄存器数。
最小共同上下文570bit、BEGIN/ACK/retire两端held/private/expected、真实lease/POINT tuple等尚无最终body，必须按独立实例补预算，不能放进927后宣称完整。scratch在组后供导出低位捕获可候选复用，但要冻结lifetimes；原RQ799/RSP872/RA580/JL13079/其他hot成本保留，未证明alias不免费相减。

### F2. 主方案16B与仅比较64B

| LINE工作量，完整32批 | 旧逐票journal | 16B独立flush主候选 | 64B未采纳比较 |
|---|---:|---:|---:|
| journal entry | 512E | 23296 | 5824 |
| journal native issues | 30208E | 1374464 | 343616 |
| JL单向control fire | 62592E | 2935296 | 733824 |
| DENSE落盘data，无INIT/CLEAR | 16384E…32768E B | 372736 B | 372736 B |

16B每批728entry/42952native/91728fire；64B每批182entry/10738native/22932fire，物理仍各批728个16B fragment。64B需新whole-span四fragment effects/END来源及共同mode，不是现授权，也不省四倍DDR bytes；本卡不采用，不扩原done5为728。
本地RAM操作另计：每批clear4432WE+vote16E RE/16E WE+export4432RE=32E+8864；32批1024E+283648。不同bank可并行，不能把该数当journal单port时钟；marker清除另为状态更新。本地clear277个地址沿/批，完整导出一次的bank RE总数4432/批，packer/协议会增加间隔而不凭空减少操作。
只替原预算LINE，保POINT/ANN64/RECORD：journal小计由30267E+1915376变59E+3289840；再加本地bank操作为1083E+3573488，仍是不同owner操作数。JL小计由62718E+4090464变126E+7025760；未包括新内部BEGIN/owner/flush adapter控制。原OBJ请求/响应另保32E组，不能混进JL计数。
无POINT/EDGE/GRAD cache的数据小计变32N+544E+899328 B；主候选保32次DDR CLEAR，再加372736B。FIRST INIT、NMS读写/其journal、NUM、其他phase、管理/效果/关闭/仲裁均另计；POINT32遍仍512E B，未免费pair-read缓存。
E=10000时旧LINE journal302080000次，候选flush1374464次另加本地vote10240000次bank操作及clear/export283648；这些是事件数量，不是实测加速比。II8时32批本地投票256E间隔；E=N为530841600间隔，在未经STA的假设100MHz下是5.308416s的局部理想尺度，不能宣称完整帧上界或fps。完整服务上界/时间目标尚缺，不以显示1080p60代处理fps。
原NS仍有66行复制/141824中心/至多1273344逻辑计数读及snapshot WRITE journal；POINT、NUM、圆拟合等尚可能主导。本候选有限消除逐票DDR日志，未证明十一项可放下/跑完。

## G. 后续实施与验证计划（全部未运行）

拟在指定共同版本获批后，于独立work新增 dense_batch_native、dense_batch_flush 与实际STORE/O/SC/RA/JL适配；本卡文件名为计划名，不创建源码。独立参考保持完整21bit表和原packed字节oracle；仿真先局部再整phase/1080p，综合/PNR/STA及bit须在必要检查真实通过后进行，bit后停硬件。
停止条件：真实授权/可见性/初始化/退租桥缺失；任意count/byte/prefix不符；资源/时序不满足共同指标；未知物理写不能关闭。不得用参考通过代综合/布线，或无硬件观察代hardware PASSED。

| TEST | REQ/IF | 场景与期望 | 方法/观察；状态 |
|---|---|---|---|
| DN-T01 | 01/02/DN01 | 完整32批、E0/1/真实1080p边缘集合，独立表逐票/每批逐项一致，512票/POINT | 后续reference+RTL；e4效果/匹配响应/发布分开；未运行 |
| DN-T02 | 03/E1 | dirtyRAM后reset、marker旧valid、本地clear少一地址 | 不开首组/read gate；真正277地址/marker/g归零才启动；未运行 |
| DN-T03 | 01/03/E2 | 单bin跨2^20至2073600、陌生bin二次跨/同bin二次回绕 | 精确21bit，破不变量无任何组WE且保旧权威；未运行 |
| DN-T04 | 02/DN01 | lane0…14合法lane15越界/错误高payload/重复ordinal | RE前能判的零RE；迟发数值失败也零WE；不部分16项成功；未运行 |
| DN-T05 | 02/06/E2 | RSP长期反压、气泡、取消分别e3/e4/e5/rst | held不变，旧commit真记g，未commit无WE，reset隔离；未运行 |
| DN-T06 | 04/DN02/05 | 活动组或g=E但flush半途时READ/op1/clear/换batch | 最新读门不开放/op1非法、不清旧表；未运行 |
| DN-T07 | 05/DN03/04 | 21bit记录跨byte/16B，尾14B非零注入 | independent packed逐byte一致/728块无缝，padding坏拒；未运行 |
| DN-T08 | 05/06/DN04 | chunk127旧held/seq重放/假permit/错epoch、prefix孔洞 | 不能重复写/跳孔success，真实身份不卸；未运行 |
| DN-T09 | 06/E3 | chunk中actual write与cancel同沿、visible/END未知 | oldfire履约，真实prefix/未知历史保Q，不发布整批；未运行 |
| DN-T10 | 07/DN05 | θ511/0邻居镜像、rho0/276、相等峰tie、跨batch边界 | 完整21bit/276−rho/原canonical与LINE顺序，旧reader关闭才clear；未运行 |
| DN-T11 | 04/06/DN02 | lease/seq最大、warm reset与old ACK迟到 | 非复用allocator，旧responsibility完成前不新BEGIN；未运行 |
| DN-T12 | 01…07/F | 编译/推断/整实例资源/独立实际服务/STA/PNR | Ti60实际16bank/位宽/时钟指标/引脚及bit前门槛全部有证据才通过；未运行 |

## H. 双向追踪

| REQ / 来源 | MOD / IF / 不变量 | 仅计划单元 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| 01 / R4R/用户完整范围 | NATIVE/DN01/全部512θ | local_accept/projection_binding | T01/04/12 | 无本候选源码；来源与有限设计审阅 |
| 02 / 原typed整体隔离 | NATIVE/E2/g与16项同沿 | whole_group_commit/held_response | T01/04/05 | 未实现 |
| 03 / OPT-D1/SM禁op1 | NATIVE/E1/总票证明 | clear/marker_guard | T02/03/06 | 数学候选已审阅；未运行 |
| 04 / SC/RAW真实效果 | O/STORE/DN02/05/分开四状态 | batch_install/latest_gate/settle | T06/09/11 | 实际桥OPEN |
| 05 / PK/RA/JL | FLUSH/DN03/04/完整span | pack128/flush_intent_adapter | T07/08/09 | 实际来源/新mode OPEN |
| 06 / 原取消/失败规则 | 全连接/旧fire先记/无假rollback | cutoff/retire/Q | T05/08/09/11 | 未实现/未运行 |
| 07 / R4R/NS | NS/DN05/冻结旧读者 | snapshot_handoff/wrap | T01/10 | 只保原契约，未实现 |

反向每个bank/marker/scratch/packer/资格/adapter/hold/关闭单元必须映射上述REQ；未定义的控制费用保OPEN，不以“性能优化”空泛需求掩盖。

## I. 设计门槛与评审

①整体/样例、②职责/复用调查、③局部接口差异、④中文草图/数值不变量、⑤适用语言/映射、⑥有限走查、⑦文字验证/追踪已具体形成；这些不是实现验证通过。③最终实际端口/可信提供者及⑧无阻塞未满足；⑨保存/真实读回/呈现和⑩版本/范围/来源身份由检查点登记，未冻结实现输入。
状态 NOT_READY，不询问用户批准本卡，不改Approval Manifest或数据库。DN-B01…03闭合后必须形成共同指定版本/范围/基线达到READY并等待明确批准。R1/配置/IP预检授权均不覆盖本候选，R2/Q0既有待批问题保留。

## J. 变更、候选选择与恢复

原路线：每DENSE组16 DDR RMW和944 journal native；只把WORD消息bulk化保59native/lane与逐laneDDR/END，不解决主要斜率。主候选：精确本地组提交，整批16B覆盖落盘；改变backend/latest/effect成功域和源operation，属于重要结构/行为接口变更，不能称无须重审的内部细调。
原来源保持不改；新joint版本必须同步R4R/SM/SC/RA/JL/RAW/NS/预算的成功域、安装资格、动态读门、whole-span来源、clear/flush/退还与失败对照。64B仅比较未采纳；移除DDRclear/借用RA保持槽也未采纳，不偷偷进入现账。
恢复先核本卡/来源SHA、真实审批、旧在途/隔离责任、共同差异与所有有限检查；没有具体批准只做文档/只读核查，不能恢复实现。

## K. 实现与验证实录

本轮仅有限设计/数学与事件数量比较、文件身份和真实读回/独立审阅；没有生成本候选业务源码、功能脚本、参考、可执行测试/TB或运行仿真/综合/PNR/STA/bit。没有数据库/硬件/网络下载/安装动作或保护IP体读取。
R1既有123/123软件与PNR/STA/bit交付证据仍只覆盖原批准R1；本候选及完整十一项未交付。正式项目状态WAITING_FOR_HARDWARE_BASELINE保持，文档事件不伪造正式PASSED。

## L. 交付与人工阅读

先对B/C画面和数据拥有者读回：旧票为何昂贵、哪一批在片上、何时DDR才新；再对D看新来源/成功域差异；最后按E逐沿看marker/g同时提交及728块实际关闭，再核F事件/字节/未知预算。数字附件只供检查固定算术，不是参考程序、testbench、测试结果或全机性能证明。
完整路径：真实POINT/批次资格→本地完整clear→每POINT16项同沿提交→最后回复与本地责任关闭→冻结完整21bit packed导出→每16B真实许可/日志/physical/END/退还→全批关闭→NMS四快照与旧reader关闭→下一批；任何中途UNKNOWN保原身份隔离。
本轮交付的是有限候选及成本差异，下一步只需把DN-B01…03吸收进有限共同版本并完成真实预算；不把新文档数量当实现进度。用户理解验收仍待实际读回，不把已讲述记为已理解。
