# EXEC 冷来源、真实变更 fence 与旧发布请求交接：独立设计审阅 v0.1

2026-10-05。纯文档／DESIGN_INCREMENT_PROPOSED／NOT_APPROVED／NOT_IMPLEMENTED／NOT_RUN。审阅对象是 EXEC-BULK-CAPABILITY v0.1 当前原字节，不修改该卡或其任何上、下游。只写本报告；R2 待批 v1、新 48 输入、已批准 R1、HDK、Manifest、正式状态及数据库均只读。

## 1. 结论和本轮具体增量

当前 EXEC 卡的 EBC-B01/B02 仍有真实接线缺口：完整 CTX/J/创建来源与证书必须来自被真实 owner 保护的记录；权限变化必须在实际 writer 入口先 fence；“旧已发布”必须来自原 FETCH 的实际 source publication，而不是调用者自报 holder、slot、borrow、旧 revision 或 held 位。本报告不把五项 OPEN 改成已关闭，也不以未来仿真尚未 PASS 阻止成熟设计先评审。

本轮可以具体闭合的窄设计增量为 **EBSF-INC-v0.1：O 唯一元数据写入口的 trusted MUTATE_FENCE seam，与原 FETCH 发布门的旧 revision 交接规则**。它明确哪些真实变化先封新访问、旧许可如何继续保留、等待哪些本地义务、何时执行实际修改，消除“正文说所有变化都 fence，真实 writer 却没有唯一入口”的空泛承诺。源卡吸收并冻结本增量之前，它仍是待采纳设计；它不单独关闭完整冷来源搬运、PB 物理关闭、全资源／最坏服务或 warm/epoch 恢复。

保持 Ti60F225/I3、SC431HAI 彩色、1920×1080、完整 Canny、五基础六高阶、原复杂识别与质量边界、仅板卡已有资源且允许板载 DDR3。PC 只参考、仿真和观察；没有降低帧尺寸、目标数量或处理指标，也没有引入外接存储。

## 2. 实际来源、阅读范围和 hash

实际调查未找到另一本同名 PHYSICAL 或 READ 文档来替代合同：生产物理路径在 PB 的 DDR_PHYSICAL_ADAPTER、R_ROUTE/RX；生产权限在 DIR；旧短字节许可／journal／provider 在 RAW；ROW→FETCH 的真实业务请求和终态在 HANDOFF；实际冷记录端口和保存顺序在 CONTROL RAM。以下路径均相对 `_fpga_edge_agent/`。全文表示实际分段读取合并覆盖全部行，检索结果本身不冒称全文。

| 来源 | 本次实际阅读 | bytes／lines | SHA256 |
|---|---|---|---|
| planning/design-TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001.md | 全文 L1–299；重读 L115–191 | 51018／299 | `2FC82DB887BA972A45D5F39B613C42AF5892DECF53DB23E25086039F666031F1` |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md | 全文 L1–231 | 34598／231 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA` |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md | 全文 L1–162 | 26058／162 | `0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40` |
| planning/design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md | 全文 L1–235 | 35734／235 | `4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662` |
| planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md | 全文 L1–223；长输出中段另重读 L69–146 | 34042／223 | `F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67` |
| planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md | L67–132 及身份字段检索 | 43548／245 | `3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243` |
| planning/design-TRACK4-ALGORITHM-RAW-STORE-001.md | L111–141、L168–177、L230–275；相关定位检索 | 64846／367 | `7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD` |
| planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md | L97–152 及 J/CERT 来源检索 | 64477／非全文计数 | `C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C` |
| planning/design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md | L75–95 及 SOURCE/BIND 检索 | 30415／非全文计数 | `6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103` |
| planning/design-TRACK4-ALGORITHM-REPLAY-001.md | L87–107 及 PLAN 字段检索 | 46304／非全文计数 | `7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B` |

项目入口 AGENTS 当前 SHA `6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937`；唯一编码规范 v0.2 SHA `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`。入口及控制面顺序此前实际读取，本轮核当前 metadata 与批准前边界；不重写长期规则。独立有限复核还实际核 DIR L69–189、RAW L154–179/L230–274、HANDOFF L67–116，给出的 owner/phase 与事件分类与本报告一致；它没有写文件或运行功能。

## 3. 三个阻塞的来源与确定缺口

**冷来源：** DIR L104–110 要求 pin512 全文、实际完整 holder、当前真实 phase/pending/permission 回链；kind2 的 holder 是 O 的原 OPEN387＋真实 borrow64＝loan451，CONTROL L68–69 给真实 D0 loan 23 词。它不包含 CTX840/J657、plane descriptor 或证书。CORE 的 registry906 46 词在另一个真实 owner 端口，CONTROL L58/L131 要求固定 CORE 权限和两次短事务提交后才 registered，不能让 O 自报 owner=CORE 去读。EXEC L136–138 要求 clone 期间完整来源受保护，但尚未给相应 source lease/实际请求和回执接线。

DIR L118–127 还给 SOURCE_ORIGIN512、SRC_LEASE522、RESULT_ASSOC1879 和真实 state。必须核实际 registered 创建源、同 source_id/SRC ref-version、完整历史 J/结果/PCTX/credit/CERT；PLAN.job96 或 EB_CTX1948 的稳定不替代这些来源。VIEW L99/L113/L139/L147 仍明确历史命名字段恢复、完整证书真实 provider 事实及 parent/borrow/source 关闭接线，不能把尚未明列的旧 J packed 解析或父池接口偷偷当作冻结。反例是多个 native 短读之间原 owner 未持续 pin 来源记录：复制 CTX 后再读另一个历史 J/CERT，只能得到各自稳定的值，不能证明组合来自同一实际授权事务；原合同的业务 pin 正是防止这种复用，clone 必须实际取得它。

**真实变化 fence：** DIR L106/L108/L151/L157/L159、RAW L240/L242 要求唯一 owner 真更新并保留关闭证据。EXEC L186 写“所有影响本 grant 合法性的 DIR 更新必须进入 EB_FENCE”，但没有把每条实际修改分支与 writer 之前的唯一 hook 连起来。只在 lookup 端拉低 cachevalid 会留下已形成 held FETCH／REQ／RSP／AR 与原 pin RETURN 的交接窗口。原合同不允许趁 active READ pin 修改 immutable 几何；此处不是断言旧设计已实现这种错误，而是新快照没有证明原排他前提和所有真实撤权事件均受保护。

**旧 published 桥：** HANDOFF L80/L102/L120/L132 是原 FETCH315、真实 row/borrow 和原完成窗口；EXEC L126/L170 提出 380bit 白名单，却仍把唯一真实 source publication 事件列为 B02。valid 为 1 但尚未 fire 已是需要履约的旧承诺；若只在接纳 fire 才登记 revision，STOP 同时 ready=0 时会漏掉它。相反，caller 自报 old_revision/held=1 绝不能生成白名单或恢复旧权限。

## 4. EBSF-INC 的整体职责与字段

唯一 O 的受保护 metadata 更新路径新增内部 **MUTATE_FENCE seam**，只从 O 已真实接纳并完整判定的原命令／beforeimage／RMW pending 触发，固定连接实际 CORE/O/ROW/FETCH/health 的 owner 事实；它不是新外部 caller API。内部字段不携带自行可选的授权 holder_id。

| 字段／已有容器 | 选择与唯一 writer | 来源和边界 |
|---|---|---|
| pending1／target_plane_mask12／cause4 | 共 17bit 新 selected hot state，O seam 唯一写 | 单全局在途变更；mask 从实际完整旧记录关联四真实 loan×三 plane，bit=3×exec_cache_slot+plane，slot 不授权限；不凭 caller 的 mask |
| cause4 | 0 NONE；1 PIN_RETURN；2 HOLDER_STOP_CLOSE；3 DESCRIPTOR_QUAL；4 SOURCE_PARENT_REVOKE；5 HEALTH_FAULT；6 EPOCH_ISOLATION；7 REBIND；8 RETIRE；9…15 保留拒绝 | 内部事件分类，非 reason6/reason5 cast；first error 仍在原 owner 真实错误账中冻结 |
| 原实际命令与 beforeimage | 保留于 O 原 expected/RMW/原 holder 记录及它们真实业务 pending | 完整 pin512、descriptor640、loan451 等按原真实来源核；17bit 没有包含这些宽 body，原卡尚未完整预算它们，不能称“全部新增成本只有 17bit” |
| 原 EB header/plane/masks | 仍按 EXEC L144–150，tuple/revision 冻结 | 门关闭先 state=FENCING/stopped；不通过更新 ref、版本或清 installed 来伪造 RETURN |
| 原旧发布白名单 | 保留原 FETCH315＋old_caprevision64＋valid1＝380bit | 固定实际 FETCH 源发布门写入；不加每 exec 四个队列，不以本报告暗省原 held/private |
| 发布阶段关联 | 明确选择额外 pub_phase3，0 EMPTY、1 SOURCE_HELD、2 TRANSFERRED、3 SETTLING、4 TERMINAL_METADATA、5 Q，6/7非法 | 共一份全局 bridge 状态，记录白名单向实际 expected 的交接；不授第二个 outstanding permit；selected 新字段小计 20bit，宽 pending/租约/全成本另计 |

若真实 native beforeimage 正在读，原请求已进入 owner pending，资格核完成前仍不得 mutation。确定受影响 mask 后应结束本次 native capture／短锁，再等待 scope drain；不能占 descriptor、pin 或 CONTROL RAM 的全局物理端口锁等待 DDR/外部 ready。等待期间原命令只持受保护 identity/关闭请求，不授新普通 READ。独立 IF05、RETURN 和旧 metadata 完成必须能通过原有限 dispatcher 服务；其实际最坏服务仍属 B04，不设 W=0。

mask 的比较依据必须是完整真实旧 ref/version/grant/access/borrow/epoch、holder kind/index/generation/epoch 和它实际 loan full OPEN 回链；descriptor 或 source 变化按真实旧 ref/version/source origin/result/parent 关联取所有受影响 loan。snapshot_valid0 但 installed1 的 BINDING 部分 grant 也不能漏掉。没有匹配 live EB scope 的已核合法修改保持原路径；缺 holder／未知 beforeimage／同 slot 错代不推导 mask=0，而进入原隔离/Q。父池完整回链和 source protector 接线仍是 B01 的实际依赖，不能以此规则代造父授权。

## 5. 必须进入 seam 与无需全 scope fence 的变化

| 真实事件 | 权限相关处理 |
|---|---|
| 本 pin 的 active、RETURN、tuple、READ role/access、borrow/epoch 或 holder 回链变化 | 先 fence 所属真实 plane/loan，再按旧工作真实关闭执行实际变更；full RETURN 只减本份账 |
| 本 holder STOP、closing、Q、retire/reuse，或 phase 不再允许新 READ | 固定 owner 事件立即封新提议；已 published body 保旧 identity/revision，不因 phase 变了就撤承诺 |
| descriptor ref/version/JID/origin/backend/base/capacity/record/item/valid_count/init/immutable/commit/lifecycle/physical_settled/write 资格变化 | 正常 immutable 且 active READ 的几何/版本修改首先被原排他/RETIRE 前置禁止；不能“fence 后悄改几何”绕过原规则。合法撤权／失效走 seam，保旧 tuple 和 effects |
| 绑定 source/parent/result/CERT 注册或授权撤销、代次隔离／rebind | 由真实 owner 原完整身份求影响范围；禁止拿新 source/J/epoch 覆旧快照；恢复需重新 fullqual＋独立新 revision |
| 同源另一个 reader ACQUIRE/RETURN，只改变 read_pin_count，本 grant 仍 live | 不撤本份 immutable READ；真实计数仍由 O 更新，不全表失效或假 RETURN 本 pin |
| 下一 policy/config/latest，或合法同 lease JOB→BUNDLE 的 owner/JID/slot 转移 | 固定原 REQ/hold_ref/grant/role/创建来源不变时不因旧 SRC_LEASE522 全快照不等误拒；若同时真实撤 provider/holder 读阶段，仍 fence |
| 本 row FULL/输入／输出退休 | 只关闭对应 RGR 的新 FETCH 门和银行寿命；旧 published FETCH 留 row lease。不得自动 RETURN whole loan、等 whole out FREE 或改 immutable plane |

正常撤权可等旧工作 settled 后提交修改；物理失健康、unknown、原 permission 已实际失效不能被包装成“继续成功读”。trusted health 事实立即 sticky/gate/Q，并保旧成功 held 回复原文、实际 AR/R/effects/未知前缀；Q/INVALID 诊断状态可以记录真实故障，但不得清 ref/version/grant、复用记录或声称 quiet/returned。unknown 未来效果未关闭时 drain 不完成、原修改不进入可复用新身份。本 seam 不制造 protected DDR drained/fence 证据。

## 6. 原 FETCH 真实发布、旧/新 revision 交接

bridge 必须放在真实 ROW/FETCH 源 valid 的形成处，而非只在目的接纳处扫描 caller 参数。旧公开 FETCH315 body 不变：ROW_KEY164/borrow64/fetch_seq64/plane2/offset13/count8。固定 source owner 先由实际 RowCtx865／ASSIGN 成功、实际 RGR/full KEY 和旧 loan 生成候选；KEY、source_y、target_y、row mask、O loan slot 从受保护原记录恢复，地址/ref/grant 不来自 FETCH payload。

1. **候选尚未发布：** 原 source valid0，单全局白名单／source/expected 空且目标 ACTIVE、RGR ASSIGNED/FILLING、非 stopped、原运输和服务容量允许时，按完整旧资格形成 FETCH 候选。原完成窗口先由 FETCH owner 核：活动同请求或完成 cache 命中只履约／重放原 TERM，不重新请求 EBP permit；同 seq 异 body 拒绝，STALE 不复生。另一个 exec 未被选中的候选继续在原真实 owner 中，不新增隐藏 FIFO。
2. **PUB_COMMIT：** 在同一提交沿将完整原 FETCH315 与实际沿前 caprevision64 写入白名单、置 SOURCE_HELD，并使 source valid 沿后可见。两者原子可观察；不能先 valid 再下一沿补 whitelist，也不能从外部的 valid 位自行推授权。此沿如新 STOP/fence/row FULL 已观察，尚未 published 的候选不提交；旧已 published／本沿旧 fire 的工作先如实结账。
3. **source 反压：** SOURCE_HELD 时白名单和原源 body 保持。STOP 只禁新 PUB_COMMIT，不撤 valid、不改 old revision、不以 ready0 推 never-issued。借用实际 header、RGR 与原 RowCtx 来源保护仍保留。
4. **实际原 FETCH fire／后续 EB_REQ：** FETCH 目的保存原完整315 expected，再从可信 bound 记录构造 EB_REQ662；原 FETCH fire、新 REQ 形成、新 REQ fire 各独立。REQ 每字段应逐项等白名单315＋受保护 ROW/KEY/borrow/coords/mask＋old revision。明确匹配后进入 TRANSFERRED；白名单身份不得在唯一 expected 尚未受保护时消失。FENCING 可兑现该确证旧请求；caller 伪旧 revision 没有来源注册不通过。
5. **普通查验到许可：** 仍按 EXEC e0–e6 完整检查与范围，成功 EB_RSP1012→PB 独立 route/private→真实 RX/route 预留→AR。白名单不跳过 plane、logical/init、4KiB 和真实 health 条件，且不授权 WRITE/RMW。旧资格变得不可信时形成真实失败/Q，既有 held 回复保持原文；不补 len0 的“成功”。
6. **物理与元数据分别退出：** IF05 真关闭/正确 ACK及本地 close 运输空后，EBP 许可物理 scope 可退出，不等整行 FULL。原 BURST_TERM342/ACK350 及 CONTROL 的52词 cache job随后按原次序真实完成；保原 expected/metadata 到其真实生命周期结束，不能由 IF05 closed1直接把原 FETCH 槽复用。pub_phase=TERMINAL_METADATA 的保留值不再授新 AR。所有对应原运输和引用都空且实际 owner 准许替换才 EMPTY；若保留完成 cache，它仅是复制值，不 pin已退资源、不复活许可。

pub_phase 的精确推进是 EMPTY→PUB_COMMIT→SOURCE_HELD→实际原FETCH/REQ受保护交接后TRANSFERRED→实际许可建立后SETTLING→IF05真实退出后TERMINAL_METADATA→原运输/metadata退出后EMPTY。明确未创建许可的合法拒绝，只能在原request/reply/expected均实际关闭且真实没有AR/route/effect债后进入TERMINAL_METADATA，不虚构IF05许可；BUSY而仍待真实重试时保留TRANSFERRED/原身份，不造新白名单或同时第二permit。未知身份或futureeffects进入Q并保原tuple/phase证据；不能消费Q后回EMPTY。pub_phase不是实际AR/R关闭证据的替代。

这不是新增端口的实现；它是 fixed source owner 的设计交接规则。实际 wrapper 的全 source/目的 held-private、原高水位/完成窗口与 EBP singleton 资源需在 B02/B04 联合清单显式吸收。全局深度一及额外关闭顺序的服务成本不能用“最快六拍”抵扣。

## 7. 中文操作草图、冲突与失败次序

阅读次序是整体真实 source/holder→实际 cold 搬运→ordinary ROW/FETCH 发布→O 变更入口→旧 scope drain→真实 RETURN/终态→metadata 退休。

**建立：** CORE 的真实 registry906 两短事务提交且身份受保护；O 依实际 parent/source/result/J/CERT 和原 OPEN387 判定整 exec mask，创建唯一 borrow及必要实际 READ pins。只给 kind2 显式映射 RAW role7 REPLAY/access0 READ，holder generation取实际 borrow、index取实际 O loan slot，不取 D registry slot。持续保护全来源，完整 EB_CTX1948 进入唯一1960bit assembly，98次 WE后98次RE/capture比较并核末词高12zero；全部 source/descriptor/pin/fullqual和热表真齐才最后 context_valid/ACTIVE，再原公开 GRANT成功。部分 pin失败先保 installed，按真实 cleanup RETURN；未知保Q，不能用 clone失败或 cachevalid0断言未创建。

**访问：** 真 ASSIGN→RGR镜像→PUB_COMMIT冻结旧FETCH/revision→原FETCH fire→独立REQ/查验/许可→PB真route/RX→AR/R/native解码→IF05→原TERM/ACK350→原FILL/INPUT/OUT各自推进。同一 row的后续 burst不等整行FULL；output、parent图整体FREE不在本 burst的关闭前置。

**变更：** O真实已核命令产生mask/cause/pending→先记本沿旧fire/AR/R/RETURN/commit和已有published身份→目标header FENCING/stopped、拒新PUB_COMMIT/新ordinary→结束native短锁→原SRC/ROW/plane lease保持、旧expected/RSP/AR/R/RX/decoder/route真实收尾→LOCAL_ACCESS_QUIET→实际原fulltuple RETURN/ACK和合法metadata修改→原pins_closed等事实真齐才loan CLOSE_ACK499→后来原loan/CTRL/运输/metadata全空才slot复用。RETURN不等待依赖pins_closed的loanACK，IF05不等待依赖routeclosed的TERM，最后metadata退休不倒过来要求holder先FREE。

| 冲突／失败 | 明确沿前事实与后续动作 |
|---|---|
| STOP与已 published FETCH／REQ fire同沿 | 旧fire计一次并保原revision；下一状态禁新候选，旧工作或真实失败继续履约 |
| STOP与尚未 published候选 PUB_COMMIT同沿 | 禁此新发布，不产生白名单或permit；不是撤销既有held |
| RGR FULL/closing与旧 FETCH反压 | 新行门关；旧白名单继续借原row记录到自身关闭，RGR miss不RETURN pin |
| RETURN命令到达而旧AR held、raw_R0 | 不能判neverissued，先fence并保持AR和旧scope；no_future_AR与actual route/close缺失不返pin |
| RETURN用于本次已FENCING且LOCAL_ACCESS_QUIET的原pin | 属于原pending的清理步骤，不能递归新开fence或等待自己RETURN_ACK先空；全tuple一次实际归还，错误echo不减账 |
| 同沿重复mutation／其它holder新reader | 单pending不被新body覆盖；非目标合法独立reader计数按O真实串行事务推进，不能改本tuple；dispatcher服务界仍待证明 |
| source lease/真实source身份变化、wrongCTX/J/CERT或copy未registered | ordinary门不开／拒来源；部分真实pins保存清理，unknown Q。不能从非零sourceid／job0/absence补grant |
| badRID/RESP/LAST、extraR、close错echo／overflow | 实际合法前缀、额外响应与first error分记；禁止成功FULL/closed；unknown未来效果保Q，不饱和计成128或靠timeout释放 |
| 冷clone中 STOP／native异常／源保护丢失 | 不形成ACTIVE与新成功GRANT；已真实创建pin按原owner清理或Q，不清RAM/valid推absence；已published成功reply仍保持 |
| 新epoch/warm reset与旧Q/held同时存在 | 本增量不授权新会话，不reset清名单/pin/seq；原七owner恢复与真正CDC quiet仍B05 |

本地首次失败按具名语义固定为：原 identity/permission/range/source资格错误→真实 native/协议错误→实际 backend/health错误→关闭证据错误→cancel；各来源在同沿真实fire仍先独立结账，first reason冻结，后来原因追加原mask。该顺序是本候选需要联合吸收的局部选择，不blindcast任一旧reason数值。已经published的回复或终态不可因后来错误改体；不可逆真实RETURN后的晚健康错误归独立恢复，不给旧借用新效果。

## 8. 有限设计走查与追踪，全部 NOT_RUN

| 检查需求 | 原合同／本文步骤 | 将来独立观察，不是当前PASS |
|---|---|---|
| 完整source一致与部分创建 | DIR L118–139、CONTROL L131–143；§3/§7建立 | 独立actual owner ledger比CTX/J/source/result/CERT/全pin；不同历史body混合拒绝、源lease连续、partial grant真RETURN；EBT01/02/10 |
| 权限变更唯一入口 | DIR L106–110/L151–159；§4–5/§7变更 | 每一真实writer分支覆盖mask；不是“cache失效一次”自证完整fence；普通illegal geometry不commit；EBT06/09/10 |
| 旧published与新revision分离 | HANDOFF L80/L118–120、EXEC L126/L170；§6/§7冲突 | original source valid首次形成、原fire、新REQ/oldrev与真实expected分别记；伪caller held拒绝；EBT05/06/08 |
| 真实physical与TERM顺序 | PB L74–88、HANDOFF L108、CONTROL L139；§6退出/§7变更 | 长度/count/AR/R/Xfer/RX/decoder/route真实ledger、IF05先于依赖routeclosed的TERM、52词cache不伪造ACK；EBT07/08 |
| 独立RETURN与metadata复用 | DIR L157、CONTROL L143–155、EXEC L190–192；§7 | 本grant返还一次，ACK/body仍held时不reuse，wrong echo/Q不减账；loanACK不成为RETURN前置；EBT09/11 |
| 完整服务／资源 | EXEC L214–222、PB L142–146；§4/§6 | 新20selected bit不是总FF；完整beforeimage/保护端口/widebody/仲裁、100MHz及1080p60最坏service需联合核；EBT10/12 |

静态检查确认语义闭环：source owner授权限→可信发布登记旧revision→真实writer先fence→旧scope继续受保护→permitclose/原TERM/RETURN独立推进→metadata最后退役。没有以用户批准前先跑RTL验证为条件。另一方面，真实protected DDR旧effect闭合接口、完整source/parent guard协议、相应width/private budget和owner接线还没有由本报告变成实现或实际输入基线。

## 9. OPEN保留边界、实录与交付

EBC-B01：本报告给真实source字段和保护位置，不替代尚缺的CORE registry→O读取／保护回执、完整parent/source资格接线与旧J packed共同澄清。EBC-B02：真实mutation入口和source PUB_COMMIT/旧request交接的设计规则可由本报告吸收；actual RGR/ASSIGN/FILL、singleton transport和原完成窗口仍需联合版本。EBC-B03：完整1012许可→PB route/private、physical facts8与protectedDDR关闭不是本文可声称已证的实现。EBC-B04/B05：资源／服务／时钟与warm恢复继续OPEN。它们不阻止隔离且已批准的现有成熟范围，但本报告本身不授新业务或EDA权限。

本次实际只读取文档、检索真实合同路径、核文件metadata/hash和做有限字段/事件推理；只新增本报告。未生成或执行业务源码、模型、功能脚本、TB、向量、仿真、综合、布局布线、STA、bit/hex、网络、安装、数据库或硬件动作。所有功能/工具结果为NOT_RUN；静态20bit/98词/完整接口分析不是utilization、时序或FPGA全机可实现性证明。原卡和各来源hash交付前复核，报告全文保存后实际读回，最终hash由交接消息报告；报告自己的hash不自嵌形成循环。

允许本轮下一步：Root实际读本报告并把选定窄增量吸收为明确文档修订、保存旧原字节、冻结来源和重新评审；不得把报告签收、caller holder_id、原R1/IP预检成功或待批R2 v1当作EXEC实施批准。源码／模型／TB／EDA仍等待对应指定成熟设计版本、范围和基线的明确批准。
