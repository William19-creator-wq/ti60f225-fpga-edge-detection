# TRACK4-ALGORITHM-SCAN-RESERVATION-001：提前扫描身份与真实采用候选 v0.1

2026-10-04。LOCAL_COMPOSITION_DESIGN／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。目标是消除RP-B03的身份循环，保持完整1920×1080和VSYNC前首行READY；本卡不提供完整软件/资源/期限验收。

## 通用计划字段

- Goal：提前分配真实执行身份，明确候选与重复首行、实际物理帧、取消、关闭、冻结快照和引用的交接。
- Current state：PIO只在VSYNC分配scan，提前ROW472却含scan；当前行卡90E980记录该阻塞。原工程已综合，PNR/保护IP仿真尚有失败，十一功能尚未实现。
- Target state：以四份明确上下文替代旧三份条件预算，静态解决身份与隐藏fallback，完成独立设计审阅；待全部依赖闭合后联合批准并实现。
- Gap／Open questions：SC-B01实际bulk/父目录证据与全消息接线；SC-B02时钟/CDC/关闭和服务期限；SC-B03全机预算及实施输入基线；SC-B04指定批准及正式运行前置。均OPEN。
- Assumptions：四ctx、三输出行、两input、最多两不同physical bundle；完整旧PLAN/配置不变；core100/pair74.25候选尚未STA。
- Dependencies：被冻结的整合v0.7、行卡v0.1、PIO39EA、PROFILE6A9A、VIEW C764及唯一对象owner。
- Milestones／Detailed steps：来源和反例→选择四ctx→消息/状态/中文草图→有限审阅→资源/期限及全球接线→READY/指定批准→独立work实施/验证。
- State transitions：仅设计状态；正式PROJECT_STATE和数据库不改。
- Artifacts and hashes：A来源、旧稿同hash快照、独立审阅；当前文档不自填自身hash。
- Validation：G文字场景未运行；本次只读和静态设计核对。
- Failure handling：SAFE为真实显示故障或无图初始状态，不能计连续有效图通过；未知effect/Q保留引用。
- Human approval gates：旧IP预检批准不含本卡；当前未READY，不生成业务实现/脚本/TB。
- Rollback：原HDK只读；恢复核版本/hash/批准，未批准不创建算法work。
- Completion criteria：整包全部功能及真实仿真、综合、PNR、STA、bit满足原要求；本卡局部设计不等于完成。

## A. 阅读、来源与精确范围

阅读整体B→C职责/引用→D无实现体消息→E中文操作与沿规则→F/G/H，再回整包I。器件维持Ti60F225/I3，SC431HAI、板载DDR与十一项原目标不改变；PC只参考/仿真/观察。

| 冻结输入 | SHA256 | 本卡实际依据 |
|---|---|---|
| [整合v0.7快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.7-before-scan-reservation.md) | 5FA0450D69FFFEA32F74EEC7A95173030FCDCDA701FFA1AAD170F6698027B4C6 | IF12/14、两physical bundle、生产全范围 |
| [行卡v0.1快照](design-TRACK4-ALGORITHM-ROW-PIPELINE-001-v0.1-before-scan-reservation.md) | 90E98056A72E049EACEADC1885B89CCB5266EC947B4A97F6FDA09341CA8FBFC4 | RP-B03、RowCtx865、三out、真实银行返回 |
| [PIO v0.2](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | L157/163/165/180/222/230的旧scan语义与预算；本卡显式覆盖见J |
| [PROFILE-SOURCE](design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | L105快照、独立FREEZE lease、L129 epoch真实关闭 |
| [VIEW-BRIDGE](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | parent/borrow分离、高水位/epoch/held；生产父引用须覆盖单PLAN退出即返还 |

v0.2规范4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2和PLAN_TEMPLATE仍适用。本卡是未批准的重要结构/接口修订，不称内部格式修正。阻塞SC-B01含真实父grant注册及bulk close来源，SC-B02含首行/row1/closing周转；没有这些直接证据不能进入实现。

## B. 整体行为与边界

SC-REQ01：exec_scan_token64由VIDEO执行预留owner在合法PREPARE成功事件提前分配。它标识一份不可变PLAN执行；ROW在准备阶段使用这个已授token，之后不retag。实际物理frame_seq64只在固定h0/v0的真实frame_start推进，包括SAFE帧，二者不是同一个序列。

SC-REQ02：最多四份完整ctx，角色current≤1、future≤2、old_closing≤1。future包括未选/取消而仍closing的预留。可提前准备primary candidate与fallback repeat，每份有独立PLAN/display/exec/读borrow和首行。不能共享旧row0、借用或token冒两条路线。优先选择合格primary，否则合格fallback；都不合格输出SAFE并记录未采用/失败，不伪APPLIED。

SC-REQ03：双未来通过一次ARM_SET原子登记同一目标帧的选择集合，只有VSYNC沿前已ARM、首行在视频域真实READY/OWNED、完整父/源资格、事件槽及current→closing空间成立才实际采用；同沿新grant/ROW/ARM/closing ACK不穿透。每个采用输出真实APPLIED，绑定历史PLAN/exec和观察到的物理frame_seq。首行期限保持VSYNC前，不使用607µs放宽旧合同。

SC-REQ04：三out、两input不变；candidate与repeat两首行只能在旧银行真实返还后占槽。max两不同physical bundle集合包括keeper、四ctx、snapshot、未选closing及unknown grant。目录三结果不授第三physical引用。正常连续图服务必须证明所有期限，容量不是证明。

SC-REQ05：STOP receipt不代关闭；未选future先真停新读、兑现held、DISCARD/RETURN/读borrow闭合后退休，不等待不存在APPLIED。current的旧行/pixel/serializer/消息结清、父真实core证据及通知消费后才dispose。Q通知不free。高水位仅限制新准入，旧匹配close/return继续结账。

SC-REQ06：执行借用逐次归还，physical bundle长期parent hold独立。重复刷新用新执行，父hold不能第一次RT/EXIT就返还。冻结在请求可见后的帧边界锁沿前实际图像身份；SAFE帧NO_ACTIVE，keeper仅可用于以后prepare，不能冒充当前safe帧图。快照与新采用同沿取旧帧/旧PLAN，snapshot_ref真实建立后旧parent才能退休。

SC-REQ07：warm reset先结算旧真实fire/采用，再停新业务并逐份关闭全部ctx/bank/snapshot/borrow/parent/通知；真实QUIET及授权START才重建软件epoch exec高水位。physical frame_seq在同video link内跨软件epoch保持；新视频会话建立才重建其序列，不单端清计数解除Q。

普通例：显示A，准备A的新repeat及B的candidate，两个独立首行在VSYNC前ready。边界实际选B，APPLIED绑定B/tokenB/真实frameF；A-repeat未执行，独立discard/close；旧A-current移old_closing。冻结同沿锁旧A，并把A计入两bundle集合直至实际snapshot release。若B首行迟到而A-repeat合格则采用新A-repeat，不修改B的held体。若old_closing尚未free，不采用任何future，物理SAFE，各旧ctx按原身份收尾；这是故障/未完成，不能计正常60Hz有效图通过。

## C. 职责、连接与引用

控制：V/physical pool→PREPARE/ACK→core按token给真实bulk/RowCtx→ROW472→VIDEO→CTRL ARM→真frame_start选择→EVENT→core证据/独立ROW返还→DISPOSE。数据仍DDR→行流水→三out→pair/pixel/serializer，不增加生产主机。

| MOD | 唯一职责与状态 | 不负责/复用限制 |
|---|---|---|
| PHYSICAL_POOL/V | 最多两真实parent base记录；keeper与pending PREPARE pin；新PLAN/display/prepare_seq/ctrl_seq分配 | base grant来自O真实联合事件；不复制第二borrow owner，不从current UI改旧PLAN |
| VIDEO_SCAN_OWNER/D | 四ctx、exec序列、physical frame_seq、旧状态采用、事件/槽退休 | 提前token并非APPLIED；不自证源完整或假造core借用释放 |
| ROW/CORE_OWNER | 每ctx独立bulk/行读、停新提议与真实core关闭报告；row pipeline不跨两行隐藏容量 | 借用目录与backend真实ledger；旧逐pairOUT404关闭不代生产bulk |
| PIXEL/SERIAL_OWNER | 旧scan_ref/pixel/码字引用与真正关闭证据 | 相关clock相位/IP能力SC-B02，频率比不等于闭合 |

physical parent池按完整(epoch,parent_ref)查已登记的J/source/result/profile实体；不同ref不能按数字猜同bundle。候选第三bundle必须在O grant前被pool拒绝，不能先grant后请D拒。PREPARE在途即保留parent的可能grant义务，坏/未知回复不解除pin。成功exec只是该base下的执行引用，四个parent_ref字段保存身份，不等于四次真实加ref。

`keeper`是一个已有合法physical base引用的选择记录，供下一帧repeat准备；它没有当帧use_data资格。它与所有ctx/snapshot/pending计同两base池，不增加第三张图。base只有所有exec、row、adapter/serializer、snapshot、unknown grant及通知关闭后才能O RETURN，长hold与单次borrow分开。一个ctx dispose不等于图已FREE；消除“等待父图free才能还银行”的环。

## D. 身份、无实现体消息与组合检查

本域posedge沿前valid&&ready且非rst为fire；高到低字段顺序；全unsigned。ready只看真实接收槽，不能组合按echo好坏拒绝已发生坏fire。发出body保持到fire。

### D1. 记录与序列

SCAN_CTX840＝PLAN616/parent_ref64/link32/exec64/target_frame64。PLAN沿原REPLAY完整字段/历史render；parent_ref、exec、目标frame非0；ctx本地slot2为0…3，四个都合法。KEY256＝epoch32/plan64/display64/exec64/link32，必须查完整840及真实parent登记后才有权。不得按role或slot猜身份。四body3360bit替代旧2040，增加1320bit，不隐含计数/状态或完整FF。

V拥有prepare_seq64和ctrl_seq64，D拥有exec64，均本授权software epoch首1、扩65检耗尽不回绕；失败不分配exec，成功取消也不重用。D每真实frame_start将同link的physical frame_seq推进，冷合法link建会话首观察为1；target只是预期下一边界，不是假“已观察”。frame_seq不因软件epoch清零；耗尽阻新prepare/采用并报告FAULT，旧义务继续，固定h/v不停止。新link必须旧物理/消息/引用真关闭或正式隔离流程，不凭新link擦债。

每ctx记角色/状态、stop、adopted、actual_frame_valid/actual_frame64、first ROW pin、独立真实row/pair账本与关闭事实、每ctxevt_seq2、core证据及控制摘要；不从共享current猜历史。exec高水位不应用于已登记旧ctx的选择/RETURN/CLOSE（primary100、fallback101同时存在时仍可选择100）。PREPARE独立高水位只在成功新准入更新；重复完整请求对仍存在原ctx重放原回复，不再分配；同seq异body拒绝，退休后的旧PREPARE不复活。scan_ref2已无非法编码，所有slot引用另带独立scan_ref_valid；SAFE/blank/noexec必须valid0，不能继续以3当空哨兵。

### D2. 新接口族（候选，未接线）

| IF/方向 | body及明确含义 |
|---|---|
| SC-IF01 V→D PREPARE841 | PLAN616/parent_ref64/link32/prepare_seq64/route_kind1/target_hint64。route0PRIMARY、1FALLBACK；hint0由D选沿前frame_seq+1，非0只能等该下一边界。V先真实parent pool pin，再提请求；frame_start同沿不授新prepare。 |
| IF01 D→V ACK979 | 原841/exec64/target_frame64/slot2/status2/reason5/prepared1。合法成功0/0/1并真实分配四槽之一及事件容量；失败exec/target/slot规范0/prepared0，V仍须结原parent pin；slot0是合法成功槽，不用slot0判失败。 |
| SC-IF02 V→D CTRL327 / ACK335 | KEY256/op2/ctrl_seq64/request_reason5；ACK原327/status2/reason5/accepted1。op1STOP用合法原因，0/2/3保留拒绝；ARM由下述独立ARM_SET。STOP receipt独立，不等data、CLOSED或RETIRE。 |
| SC-IF08 V→D ARM_SET642 / ACK650 | target_frame64/arm_seq64/primary_valid1/primary_KEY256/fallback_valid1/fallback_KEY256；ACK原642/status2/reason5/armed1。至少一个valid1，未启用KEY全0；各启用KEY必须分别查到已真实首行OWNED的旧PREPARED ctx、正确role、同授权epoch/link/目标帧且两个不同exec/银行。固定primary优先。全部成立才原子安装，失败不装半组。 |
| SC-IF09 D→CORE STOP_NOTICE262 / ACK270 | KEY256/first_reason5/adopted1；ACK原262/status2/reason5/stopped1。每ctx独立单槽、一生只形成一次sticky stop通知；正常完整结束reason0，取消/落选/过期/故障用命名原因。CORE正确接纳即阻本ctx新读/写提议，旧held继续；通知和ACK不等EVENT/CORE_CLOSE/ROW满，避免自动落选等待终态才能停producer的环。 |
| SC-IF03 D→V EVENT1021 | CTX840/actual_frame64/physical_valid1/kind2/evt_seq2/status2/reason5/adopted1/facts8/emitted_pairs21/data_pairs21/safe_pairs21/rows_received11/rows_read11/rows_returned11。每ctx一独立held槽和目的private槽；kind0APPLIED/1SCAN_CLOSED/2RETIRED，3非法。 |
| SC-IF04 CORE→D CORE_CLOSE409 / ACK417 | KEY256/borrow64/borrow_known1/never_opened1/producer_rows11/producer_messages_closed1/renderer_closed1/read_effects_closed1/loan_closed1/no_unknown1/status2/reason5/report_seq64；ACK原409/status2/reason5/stored1。唯一core owner从真实目录/账本形成，D不得拿数值相等代effects。 |
| SC-IF05 V→D DISPOSE322 / ACK330 | KEY256/retire_evt_seq2/dispose_seq64；ACK原322/status2/reason5/disposed1。V仅在真正RETIRE消费、其private event/control/pin义务结束后提出；D还要核自身关闭/事件及真实相等，不等parent图整体FREE。 |
| SC-IF06 ROW472/OWNED479/RELEASE480/ACK487 | 原body不改宽；scan64现在是提前授予exec。完整job/plan/display/render/exec/link/target_y/bankgen相等，首行960且y0。未选行不等待不存在APPLIED；各bank按自身真pending/holding/ACK归还。 |
| SC-IF07 snapshot/parent | 原PS_REQ96/REPLY784/RELEASE160/ACK168 body暂不改；源选择按E5沿前frame/use_data。真实snapshot hold和parent pool pin/lease返回，完整跨域消息/原子接线SC-B01/02。 |

status2用于接纳ACK：0APPLIED、1ALREADY（已stop同ctx的新完整请求）、2BUSY、3REJECTED；accepted/prepared/disposed成功须相应真实事实且reason0。精确同body重复回原结果，不修改原ACK成新身份。失败accepted等0；BAD_ECHO/未知grant不能成为释放证据。EVENT及CORE终态status：0成功、1明确失败、2取消且可关闭、3Q；成功reason0，失败/取消/Q非0。原因5：0NONE、1FIELD、2STALE、3BUSY、4EXHAUSTED、5CANCELLED、6DEADLINE、7CLOSING_BUSY、8ROW_FAULT、9SOURCE_FAULT、10UNDERFLOW、11CLOCK_FAULT、12UNKNOWN_EFFECT、13RESET、14BAD_CERT、15THIRD_BUNDLE、16SESSION、17BAD_ECHO、18CAPACITY、19STICKY_FAULT、20LINK_INIT、21NOT_FOUND、22FUTURE_FULL；23…31保留拒绝。这是本scan族命名空间，不能套到未联合冻结的bulk/其它status族。

### D3. EVENT、关闭及槽容量

APPLIED只于真采用，evt_seq0/physical_valid1/adopted1/actual_frame为本沿真实frame，历史CTX.target也须相等；当时pair计数0并冻结事件，不以后用前缀改它。已采用CLOSED序1、RETIRED序2；未采用无APPLIED，CLOSED序0、RETIRED序1，physical_valid0/actual_frame0/adopted0，target仍保留原预测值。不能等待未存在事件。

emitted=data+safe，每帧≤1036800，真实DE槽每沿推进；正确data只有身份/坐标/期限定都合格的旧复制值，其余SAFE单独计。未采用全部数据计0；无ctx的SAFE物理帧只在独立物理故障/帧计数记录，不借别的ctx伪造数据。ctx内row计数0…1080且只完整匹配本ctx的真实ROW事件计入；wrong-key不归他人。facts低到高：image_admission_closed、row_reads_closed、row_messages_closed、pair_pipeline_closed、pixel_closed、serializer_closed、core_closed、loan_closed。

SCAN_CLOSED需要全八事实、真CORE_CLOSE、STOP_NOTICE真实接纳/ACK及本ctx全部bank/消息引用关闭；RETIRED在CLOSED已真实交付后的旧资格沿，还须current已离开当帧使用资格及无本地新增引用。core关闭不能等SCAN_CLOSED、bank整体FREE或parent图FREE；CORE source借用可在producer停止/原读effects结清后独立归还，银行引用另由D/ROW真实关闭。因此本卡选择较晚的SCAN_CLOSED，不产生“D等borrow返还而CORE等D通知才返”的环。kind/seq/eventbody由旧闭合事实形成后保持；慢consumer只延迟通知/复用，不覆盖槽，不阻独立native/backend关闭。

CORE_CLOSE正常已借用须borrow_known1/borrow非0/never_opened0、真实released或安全已结loan、全部closed/no_unknown；真实从未OPEN才known0/borrow0/never_opened1/producer_rows0，不能凭borrow0自证不存在未知grant。D核producer_rows与实际收到完整本ctxROW数量、所有对应bank归还；不匹配/Q保留ctx。该报告只有实际bulk owner及目录实现后才有直接证据，SC-B01不关闭。

每ctx独立EVENT槽使新APPLIED与旧CLOSED/RETIRE同时存在而不覆写；一ctx只按事件顺序发一个held体，关闭事实另存。DISPOSE仅在RETIRED真实消费且两端旧event/private/control/pending关闭、D正确接受后回ACK；ACK实际消费后**后续旧资格沿**才FREE。Q即使通知被消费也不能disposed1。CTRL/CLOSE/DISPOSE运输与数据通道分离，不让满ROW或未完成JOIN阻止STOP/close。

ARM_SET仅有一个未来选择集合，record198＝epoch32/link32/target64/arm_seq64/两个slot2/两个valid1；全部KEY从pin的四ctx查验，不把slot当权限。安装后membership/目标不可改，新候选若未纳入只能后续新prepare；ARM_SET精确重复在原group/ctx仍真实存在时回复原结果，不重复安装，过期/退休后STALE不复活。新group仅在旧group退出/控制槽关闭后成立；旧执行关闭不等新group。选择只从这个旧集合查，未纳入的准备不能在VSYNC临时补入。

body预算：四ctx3360；八EVENT体8168；PREPARE两端2×(841+979)=3640；CTRL1324；CORE_CLOSE1652；DISPOSE1304，原列出19448bit；另ARM_SET两端2×(642+650)=2584及group198，四ctx STOP_NOTICE两端8×(262+270)=4256，当前列出合26486bit。各端真实held/private各一，事件/stop各ctx一。valid、allocator、高水位、角色/计数、firstROW副本/引用、core report摘要、CDC/复位同步、parent池/keeper/snapshot及完整全机另计。旧PIO event无完整预算，不能无证扣掉；ROW11508及行pipeline payload/RAM也独立。四scan_ref2编码全部合法，不增加位宽，不将旧3非法规则留在实现。

逐连接：V真实parent保障满足D预留前提；D成功ACK可为RowCtx/ROW提供已授exec，但不是源/显示证书；真实firstROW满足ARM只是采用一项资格；旧ARM满足VSYNC仍须closing/事件/parent/clock；真实EVENT绑定physical而非token预测；CORE报告与D本地ledger互核，DISPOSE不能越过任何未知义务。各前提有真实来源，缺接线的依赖保持SC-B01/02。

## E. 中文局部操作草图

### E1. 预备与首行

1. V选择已完整候选，先核两physical pool及旧keeper/ctx/snapshot/未知grant；无第三base空间则只可用已有A准备repeat，不先grant B。真实父pin及所有请求/回复容量成立后，唯一V分配新PLAN/display和prepare_seq形成held841。
2. D先接收请求，下一旧资格核完整PLAN/授权epoch/link/parent登记、hint、future≤2/总ctx<4、旧frame非耗尽、非frame_start。成功原子分配exec与slot，锁CTX及原request、reserve本ctxevent容量，下一沿ACK；失败不分配token/ctx，返回明确拒绝。
3. V保存正确完整成功ACK后才按该exec建立bulk借用和RowCtx/生产首行；unknown ACK不使用其rawtoken寻址，也不取消真正可能已grant的义务。三个out必须真实FREE才reserve，不能以v1121/DE低猜空。
4. 首行真实末WE/私有流水闭合后ROW472跨域。D完整核本future及bankgen/960/y0，OWNED按独立槽履约并pin首行；V/调度形成一次ARM_SET，仅纳入自己决定采用集合的真正已准备角色，D独立核所有所含首行的旧资格。两份启用则全部成功才装，不装半组；只有repeat已ready时可以只纳入fallback。ARM_SET消费同VSYNC不能穿透采用，过期请求明确拒DEADLINE但held运输继续，不永远关ready造成死锁。
5. fallback A-repeat与candidate B各独立做上述过程。若第一ACK给target F，第二hint必须F，否则两份准备属于不同物理帧，不能互为本F备用。F错过后不改held target，而独立STOP/close再新prepare。

### E2. 真边界与两条未来

1. 真实frame_start先按旧physical序列观察本F；只查沿前原子ARM_SET/首行已知/targetF/非sticky stop/health/事件槽以及old_closing旧FREE。各独立token及role由旧group查验，不能临时引入未纳入路线。当前可转closing的资格必须已真实存在，不用同沿DISPOSE ACK新空位。
2. 选合格PRIMARY，否则合格FALLBACK；若只有一条准备，则只核该条。旧current移closing，选中future变current，锁actual_frame=F/valid/use_data并形成APPLIED；未选future在自己的原slot标STOP，独立discard/close，不塞进old_closing或自造APPLIED。总ctx仍≤4，future额度包含它的closing。
3. 旧closing非FREE或无合格future则本F SAFE，不接新image。旧current若仍收尾继续原身份，不重解释为F；预期F但未采用future进入独立STOP收尾。固定h/v继续，状态不能等待core来暂停扫描。
4. 同沿新STOP/reset对沿前合格future到达，先记录真实采用/APPLIED，再置stop并按该锁定KEY收尾。若stop是沿前sticky则禁止采用。新prepare/firstROW/ARM不能被同沿旧STOP猜role取消。
5. 每ctx读行/pixel均用历史scan_ref和坐标；未选行不读为本F图，迟到行原身份discard。data欠载则余下safe并报partial，不能将迟到pair横移。event不得被后续计数重写。

### E3. 独立收尾、重复与父hold

1. 正常末行或STOP后，D关闭新增本ctx图读，并由下一旧stop状态形成独立STOP_NOTICE，自动未选/过期也必须通知CORE，不等终态。已issued RE必须capture，已复制pair/pixel/码字仍pin独立ctx，行bank只按自身pending/holding释放；CORE接真notice后停止新bulk/写提议并继续旧held/R_ROUTE/effect/ROW控制，不等event被消费才关闭。同沿采用后STOP的notice在后续沿按已经真实adopted1形成，不伪从未执行。
2. CORE产生真实409；D按锁KEY借用、producer截止/收到ROW、每bankreturned以及自身物理闭合核，不把正常数量相等当效果证明。未借用走真实never_opened，unknown/Q保留义务。
3. 本ctx真正physical关闭后形成CLOSED。全部core/loan关闭且当前已离开真实当帧image资格后形成RETIRED；按每ctxevent序列/槽独立履约。V最终消RETIRE并结束该exec的私有refs后DISPOSE；正确ACK消费后后续沿FREE，才容许新预留复用该slot。
4. 当未选future或oldclosing仍存活时，下一轮newfuture只能使用真实剩余额度。例如current1＋oldclosing1＋未选future closing1，仅可再建一个future；不能直接建立新的两条使总数5。
5. 单exec bulk RELEASE/RT结束只还该borrow。keeper/其它exec/snapshot仍借base，base parent继续；最终池中该base所有子引用、unknown及实际provider旧effects/通知结清后才真实parent RETURN和对象退休。不能让parent整体FREE成为DISPOSE或ROW返还前提。

### E4. 时点、银行与正常服务条件

固定pair h0…1099/v0…1124，DE h[96,1056)/v[41,1121)。v1121h0至下一v0h0为4行59.259259µs；v0至首DE v41h96为608.700337µs、六pair提前RE候选v41h90为608.619529µs；row1 RE v42h90为623.434343µs。这些是纯几何，六级adapter延迟仍需实际冻结，非服务保证。

当前采用合同仍要求首行**VSYNC前在视频域ready**。一般current+next占两out，再同时candidate0+repeat0是四bank，禁止；只在尾段旧bank真RETURN/ACK/后续FREE后，才能组成old最后行+两未来首行三bank。两个input同理不能抢占当前最后行资格。

采用后selected0+unselected0 closing+oldlast closing可能占满三out；必须至少一真实返还，随后完成row1并在真实RE deadline前交接。旧closing必须在下次采用前释放，未选路线不能阻死selected服务。SC-B02须给旧银行/ctx及通知最坏关闭、两首行DDR/解包/render/CDC、未选close及row1/稳态所有服务上界，并核camera/算法份额，不用平均419.904MB/s或nominal1.6GB/s自证。

mode5双首行12960B/810AXI拍、1440逻辑写事件/5760native lane WE、两次970沿局部render候选。没有完整service证明，不能声称59.259µs足够。发生SAFE不是降低成功指标，而是实际故障输出；正常验收仍要求完整持续图与原帧处理目标。

### E5. 冻结、reset与初始无图

视频域另记沿前physical_frame_image_valid及所用current历史KEY；每实际frame_start，若真采用新exec则更新有效及记录，否则新physical帧valid0。keeper可仍pin旧base供repeat，但不改变该valid。旧currentctx在当帧身份需要及边界snapshot机会结束前不得FREE；相关parent pin必须保护旧PLAN。snapshot_hold真实目录额外保存所观physical frame/exec/PLAN/parent/link及pin，不只保存PLAN文本；其预算/联合接线SC-B01/03。D新建立的snapshot pin必须阻ctx/base退休，直到正确RELEASE真ACK，不能等核心影子才补pin。

snapshot请求实际可见后的frame boundary，先按沿前frame valid/历史PLAN锁快照并原子保留真实snapshot hold，再执行本边界新采用/SAFE更新。若沿前是SAFE则NO_ACTIVE且旧keeper不能冒充；若同边界新F SAFE但沿前F−1为图，则返回F−1的实际旧PLAN，清楚区分取样边界与新帧。旧hold建立/释放仍按PS真实FREEZE grant，不用reply替effects。新选future不得影响旧snapshot颜色/source/profile。这个语义覆盖PS105的缺省safe歧义，不改REQ96/REPLY784字段宽。

warm reset同沿先记旧PREPARE/ROW/ARM/APPLIED/snapshot/fire，再阻新业务。分别STOP两future/current/closing，旧bank/backend/像素/serializer/控制及每ctx通知真实关闭，keeper和snapshot真归还，全部无Q/unknown/held后才QUIET；授权START后重建software epoch相关next/highwater。原PROFILE catalogue可QUIESCED保持历史，不能删profile自证QUIET。physical frame_seq在同link不清零，cold全域rst/新link须真实授权并隔离外部effects。失钟/失信未知effects进Q，不以safe输出或安静若干周期判closed。

## F. 语言、执行与跨语言合同

C++业务实现N/A：本卡规定RTL控制/CDC和实际引用，不生成软件功能；以后独立事件参考的标准/编译器/容器生命周期/整数/错误和取消须在SC-B03真实基线冻结，不用函数返回模拟物理采用。本次纯静态字段算术允许，不是可执行测试。

| RTL A–L | 本卡合同 |
|---|---|
| A数值 | 消息body位数/unsigned D；计数21/11、seq64扩65耗尽；valid0与数值0区分。 |
| B时钟 | D/pair域采用；V/CORE在core域；真实frame_start只一次/h0v0，跨域先原子mailbox，无多位直采。 |
| C事件 | PREPARE成功提前exec、ARM确认、VSYNC真APPLIED、ROW/CORE close、RETIRE与DISPOSE分别成立。 |
| Dvalid | 无效不推进ledger；同沿新资格不穿透旧采用；固定scan独立继续。 |
| E保持 | 每ctxevent及所有ctrl/reply全文held；stop不撤它们，未知grant保留parent。 |
| F时序 | E2旧状态仲裁与E4deadline；实际CDC/所有服务OPEN，不承诺常量关闭cycle。 |
| G复位 | cold合法共同作废与warm真实排空分离；各域assert/release及运输保持SC-B02；Q不自动FREE。 |
| H配置 | PLAN616/render112历史不变；snapshot取旧physical帧，keeper不等当帧valid。 |
| I存储 | 四ctx/三out/两input/每ctxevent单槽；count容量和pending真实预留；没有第五scan或第四row。 |
| J身份 | KEY256完整核；exec/physical/frame/PLAN各namespace；未选无APPLIED，旧close不因新高水位拒绝。 |
| K CDC | 全body保持+双向握手及会话代次；event端private清/ACK闭合才slot复用，不能單端清FIFO。 |
| L实现 | Efinity2026.1.132/Ti60F225/I3，3360与19448只列出body候选，完整FF/LUT/STA/原语映射SC-B03。 |

共同数值：PLAN/颜色/row原值不改，事件字段按上述整数域。硬件执行：真实边沿/held/旧事实/close独立，不由软件调用顺序替代。映射：软件oracle只对合法实际EVENT/ROW fire的全KEY、physical frame、坐标和真实前缀比；无事件不等于未执行，Q未知要保留，不把模拟结果回灌生产。

## G. 实施及验证计划（未执行）

获批后拟scan_reservation_owner、scan_event_mailbox、physical_parent_pool_adapter、scan_core_close_adapter和PIO/RowCtx连接；文件/语言工具输入SC-B03未冻结。先联合SC-B01/02/03→READY与具体指定批准→独立work实现→真实厂商仿真→全工程综合/PNR/STA/bit。当前不生成这些文件或TB。

| TEST | REQ/场景 | 期望及方法 | 状态 |
|---|---|---|---|
| SC-T01 | 01/03提前prepare/首ROW，真边界 | token在ROW前真实grant；首ROW/ARM同VSYNC不穿透；APPLIED只真frame_start逐事件核 | 未运行 |
| T02 | 02/04 candidate与repeat两首行，三bank尾段 | 一般active四bank需求拒；尾部真FREE后三份成立；selected0/unselected0/oldlast满时row1必须真返还 | 未运行 |
| T03 | 02/05未选future挂AR/RX/ROW，下一prepare | 独立旧KEY关闭不等无APPLIED，总四ctx/future含closing≤2，不能直接再建两变5 | 未运行 |
| T04 | 03/05oldclosing跨VSYNC/ACK同沿 | 不用新FREE穿透；物理SAFE/失败、旧ctx收尾不改新frame，不能算持续图通过 | 未运行 |
| T05 | 04第三base/keeper/snapshot/unknowngrant | pool在parent grant前拒第三；四字段不四次加ref；真实旧子引用结束后base才返 | 未运行 |
| T06 | 05错echo/数量相等但effects未闭合/Q | 不disposed、不抹borrow；STOP receipt独立，事件慢不覆槽且关闭继续 | 未运行 |
| T07 | 03/05STOP/reset与VSYNC真采用同沿 | 真APPLIED和历史snapshot优先记录，随后sticky stop；沿前stop才阻采用 | 未运行 |
| T08 | 06SAFE无当前image但keeper存在；snapshot+新采用 | SAFE NO_ACTIVE；取沿前frame图PLAN及真实hold，future不冒snapshot；parent仍不free | 未运行 |
| T09 | 07warmepoch/物理序列/耗尽/迟旧close | 旧义务真QUIET后授权；同link物理seq不软件清；旧匹配close继续，64耗尽不回绕 | 未运行 |
| T10 | 全部真实CDC/parent/bulk/服务/工具 | 首行VSYNC前、row1/持续行/closing最坏期限；全资源及route后STA真实日志，不靠算术 | 未运行 |

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 拟符号/文件（未生成） | TEST/证据 |
|---|---|---|---|
| 01原PIO身份反例 | D IF01/D1/E1 | scan_reservation_owner | T01/09，静态字段/序列 |
| 02/04原fallback/银行反例 | V/D IF01/03/06/E2/E4 | parent_pool／scan owner | T02/03/05/10，未证明期限 |
| 03PIO真采用 | D/PIXEL IF02/03/E2 | scan adoption/event mailbox | T01/04/07，未运行 |
| 05held/真实关闭VIEW/ROW | CORE/D IF04/05/E3 | core_close_adapter | T03/06/09，目录接线OPEN |
| 06PS snapshot/父hold | V/POOL IF07/E5 | physical parent/snapshot adapter | T05/08，原子接线OPEN |
| 07真实epochVIEW/PS | RESET/D/POOL IF01…07/E5 | reset/scan contract adapter | T07/09，未实现 |

反向每个拟模块仅负责上述要求，四ctx增量为实际fallback所需而非无关重构。无代码/注释/测试一致性实录，不能填已实现。

## I. 门槛

①B整体和反例；②C职责/复用/父hold；③D明确新接口及连接前提；④E旧状态/中文操作/四ctx不变量；⑤F语言/执行映射；⑥E组合走查；⑦G/H计划追踪；⑧不满足SC-B01…04；⑨保存读回/独立有限审阅须见报告；⑩v0.1与显式覆盖清楚，实际实施基线未冻结。故NOT_READY，不请求这张未闭合卡批准，不生成业务代码。

## J. 版本覆盖与恢复

本卡明确覆盖：PIO157 scan仅VSYNC分配→PREPARE授exec/VSYNC绑physical；PIO165/180三scan/2040body→四真实ctx/3360body；PIO178 scan_ref3非法→四slot皆合法；PIO222“否则repeat或safe”→只有独立已准备repeat合格才repeat；PIO230父hold与执行read borrow分离的实际规则；ROW RP-B03由本候选结构解除但接线/期限仍OPEN；PS105 safe图和同沿旧帧采样口径；VIEW单PLAN EXIT即父RETURN不能直接用于长期physical池。原稿作为冻结来源保留，整合增量必须引用本卡，不静默把旧hash当新合同。

没有降低首行采用资格、目标分辨率/完整算法/质量，也没有把SAFE改成成功。四ctx是实际资源选择变更，必须在完整FF/CDC输入和独立复核后指定版本批准。若后续改共享token双route、首行采用后才ready、增加rowbank或通知压缩，须新设计版本/组合检查，不能仅说内部优化。

## K. 实录与L. 阅读交付

本轮只读真实来源、静态协议/容量推导、保存稿及审阅。没有算法work/RTL/C++/功能脚本/TB、IP重生成、sim/map/PNR/STA/bit/hex、联网/安装、硬件、数据库或正式state修改。完整十一项目标保持未完成。按A→B/C→D→E1预留/E2采用/E3退休/E4期限/E5冻结reset→F/G/H/I阅读；实际实现/功能验收/理解验收待证据，用户未作答不记已理解。
