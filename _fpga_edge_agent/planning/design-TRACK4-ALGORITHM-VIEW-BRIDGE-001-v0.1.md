# TRACK4-ALGORITHM-VIEW-BRIDGE-001：VIEW、完成对象与PLAN逐字段桥设计 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本文是B03六类父交接的独立候选，只有文字设计。当前CONTROL与REPLAY没有本文新增接口；本文不改它们，不声称已有R4整图provider、完整算法或R5物理视频。

## 通用计划字段

- Goal：指定唯一VIEW/PLAN适配owner，区分J/V、完成bundle、父引用、OPEN借用及PLAN身份，形成真实关闭后才授权软件epoch的有界桥合同。
- Current state：CONTROL v0.2、REPLAY v0.2及B03交接报告已实际全文读取；六类交接仍OPEN，未生成业务实现。
- Target state：本文与两稿/R4逐项合并、来源与完整body schema冻结并独立审阅后，才可作为整包B03的设计证据；不是单页实施授权。
- Gap：真实R4成功/封存/读取/返还实体、完整profile、本文新增出口/授权端口、B05文件和验证套件、R5资源/吞吐/物理APPLIED均未闭合。
- Assumptions：全部局部消息同core上升沿、可暂停、共同同步高有效rst；生产1920×1080不变。保守单J、单SRC、单BUILD/COMPLETE、单VIEW、单PLAN，不隐含下一幅整图。
- Open questions：A2逐项列明。新端口必须回写相邻设计后才成为相容接口；未批准前不生成stub、常量模型、功能脚本、TB或工程。
- Dependencies：唯一根v0.2、模板、CONTROL/REPLAY/B03报告；R3数值、R4完整算法/逻辑存储及R5生产边界分别继续追踪。
- Milestones：整体行为→唯一owner→命名字段/证书/两层引用→中文旧沿操作→容量/反例/trace→跨稿合并与独立审阅→整包指定批准→获批实施验证。
- Detailed steps：B整体→C路径/容量→D字段及相容差异→E逐沿生命周期→F语言与映射→G/H验证追踪→A/I门槛。
- State transitions：本稿只处于LOCAL_DESIGN；不升级B03、整包或正式项目状态。
- Artifacts and hashes：实际来源绑定见A1；本稿自身SHA由保存后实际全文读回报告，不写入自身内容。
- Validation：文字算术/交接审查与未来仿真、完整质量验证、综合、PNR、STA、bit分别记录；全部未来TEST为NOT_RUN。
- Failure handling：非法完整消息明确拒绝；held履约；Q/未知OPEN不返还、不开始新epoch；没有provider进展时保持证明等待，不用超时伪造关闭。
- Human approval gates：当前只授权创建本纯设计文件；没有本稿或整包实现批准，原工作副本/构建/数据库/人工硬件闸门仍适用。
- Rollback：仅新增本文；旧两稿、交接报告、HDK、Manifest、状态和数据库不修改。用户指定外部存储器件相关工作不调查。
- Completion criteria：本候选保存、读回、呈现；真实依赖及跨稿差异仍OPEN。完整1080p、圆/任意旋转矩形、原P/R与IoU目标不缩小。

## A. 状态、来源和范围

### A1. 实际读取基线

任务VB=TRACK4-ALGORITHM-VIEW-BRIDGE-001；关联R2-B03、AC-B02/03、BR-B01/02/03及HB-IF02…06。没有Git commit，不伪造。开始前已按入口顺序读取控制规则、运行提示、配置、状态/ledger、数据库说明及审批Manifest；数据库仍NOT_CONFIGURED，正式数据库运行不开启。本轮纯文档不访问数据库。

| 实际文件 | SHA256 / 使用范围 |
|---|---|
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107；51859B，全文；J657/V788、CANCEL128、软件reset、唯一owner及有界槽 |
| [REPLAY v0.2](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B；46304B，全文；PLAN616/OPEN/RT1171、ledger/CLOSE/RELEASE、GAP/Q、授权epoch缺口 |
| [B03交接报告](../experiments/track4_algorithms_20261004/03_review/b03-handoffs-v0.1.md) | 58AE54EA6C1C8CA97C8B77F18D385F204BD3D0B53072720048EA9ADDEC5171A2；10595B，全文；六类父交接及已关闭局部意见 |
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；设计/语言/审批规则 |
| [模板](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79；通用字段与A–L |
| 入口/config AGENTS/runtime prompt | 6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937 / FD0214EA10C9987B6E443F6DBAE8CF006DE441E675EE36918DBD8B85E22FF0A3 / E99F1810394092C8A9D39BEFDA55828D46712F2C49154D315B480DB703CB655C |
| PROJECT_CONFIG/PROJECT_STATE/TASK_LEDGER | 927C928EC1942CF6BE9C7008426C044F05D6C332C4D6870635196266C2CB9263 / 87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558 / 190B9AD4718DD2681732E66F20F05EE309A18A7F72015F737D6CC6DA079C00BD |
| database README / APPROVAL_MANIFEST | 1EED39B5AAC982842A84450E22D61DF8F99A55A6F2E60D1A6CC5F34F68F1048A / A582A10DDB993DFE7058AD7EDAE4688505FA1C4F4AA161BD67E35FD59A89DF45 |

本稿不是R3/R4数值或整图算法的替代；不重新读取指定器件/IP工程，不把原物理MC/scope/grant/DDR/VSYNC租约移植成这里的逻辑证明。

### A2. OPEN和当前门槛

| OPEN | 具体缺口、影响及闭合责任 |
|---|---|
| VB-B01 | CONTROL原JID96、render112在packed边界的逐字段编码尚未全部明列；本桥只从命名epoch/frame/config/render恢复，不私定旧cast。D1/D6的候选新schema及上游澄清须共同合并；原body内部位序不反转。 |
| VB-B02 | R4实际SRC/最终EDGE/ANN存储、完整Canny闭包/识别terminal、逐坐标封存与真实provider读取/返还没有实现或冻结实体。D3证书是要由这些真实owner生成/核验的合同，不是填写成功位的stub；没有实体不能进入COMPLETE。 |
| VB-B03 | REPLAY现稿无PLAN_EXIT267、授权EPOCH_START/ACK、O目录事件接口；CONTROL现稿无VIEW取消入口、J_CTX pin/BUILD credit及reset授权汇合。D6列拟改条文，不在本轮改旧稿；未合并不能关闭B03。 |
| VB-B04 | 完整不可变profile实体、全部参数/默认/注册/删除合同仍由R3/R4及父配置冻结；非零profile_ref不是实体证据。 |
| VB-B05 | B05完整文件、跨稿schema、独立参考/协议账本、有限case/timeout与实施基线尚未冻结；本候选的字节产物/运行证据是获批后义务，未运行本身不构成反复设计阻塞。 |
| VB-B06 | 单图逻辑容量不证明片上可容纳或60Hz；R5实际完整资源/clock/pin/CDC/不可暂停视频/物理APPLIED、完整质量数据集仍OPEN。A3外设仅DEFERRED，完整算法与1920×1080目标继续追踪。 |

当前只继续纯设计/审阅。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN；不请求未成熟的泛化实现批准，不改变正式H0/Manifest/DB。

## B. 整体外部行为

| REQ | 可检查的桥行为 |
|---|---|
| VB-REQ01 | 只在完整处理成功、同J/source/config/profile且必需整图真实封存时注册COMPLETE；R2 class、空目标和缺ANN分别处理。 |
| VB-REQ02 | 唯一VIEW_OWNER同时承担PLAN适配；逐字段构造PLAN616，source/result/render/display/plan各有唯一分配者，不从其他ID低位截取。 |
| VB-REQ03 | VIEW父引用与OPEN借用是两层义务；正常、失败、取消都须真实CLOSE/RELEASE/RT/退出及父引用返还，Q/未知OPEN保留义务。 |
| VB-REQ04 | CANCEL128按锁定历史VIEW/J/algorithm_generation恢复旧PLAN224；接受回执不等待RT或释放，不将最新C/J/新ID拿来取消旧plan。原AC手工取消已移交后TOO_LATE规则保留。 |
| VB-REQ05 | 软件reset先quiesce、真实关旧任务/plan/引用，再授权各owner开始新epoch并收真实ACK；PLAN.epoch变化不能自授清借用。 |
| VB-REQ06 | 单J/单VIEW/单bundle/单SRC有界；旧帧未退休时阻塞下一BUILD，明确不存在免费第二幅图。完整生产尺寸及原质量目标不降级。 |
| VB-REQ07 | held body、旧沿优先、耗尽不回绕、非法/晚消息隔离、具体中文操作和三份映射可读；观察/通知不成为第二个生命周期writer。 |

正常：真实封存原SRC→锁旧C得到J→完整选定算法→O真实注册COMPLETE→VIEW采用并取得父引用→构造新PLAN→P取得OPEN借用并独立读取所需平面→真实CLOSE/RELEASE→RT消费及GAP结束→归还父引用→真实退休对象→VIEW_TERM消费→下一BUILD有资格。处理1080行不因mode0只访问偶行而减半。

边界：RC零目标必须提供完整全0 ANN且profile绑定成功；mode1/2不读取EDGE仍需处理job真实成功且最终EDGE封存；mode3不读SRC也要有完整原SRC注册。失败：wrong OPEN echo即使RT.borrow=0也可能有未知OPEN义务；Q只通知未闭合，不能释放VIEW引用或使reset成功。永久不ready保持未完成，不靠空闲时间/timeout清对象。

## C. 唯一owner、连接和保守容量

| MOD | 唯一拥有者、职责及边界 |
|---|---|
| VB-S SOURCE_REG | 分配source_image_id，保存原SRC handle/尺寸/封存记录和交给O的源引用。真正内容/读取属于SRC_PROVIDER；此注册表不创建整图。 |
| AC-J JOB_DISPATCHER | 仍唯一分配job_frame/拥有J657及raw子终态；选定完整算法和实际完成事实由R4承担。J_CTX被O/V引用后物理内容pin，JOB逻辑valid可结束但不能覆写。 |
| VB-O BUNDLE_OWNER | BR-MOD-O的唯一实现职责候选；唯一写BUILD/COMPLETE目录、result_id、父引用、borrow与plane_ref目录、真实封存/归还/退休状态。不替provider宣布内部pending空。 |
| VB-V VIEW_PLAN_OWNER | 与AC-VIEW是同一个owner，不新增第二writer。拥有typed V资格、render_generation、display_id/plan_id、锁定PLAN、VIEW取消映射、RT接收/父引用归还及VIEW_TERM。 |
| BR-P及R/E/A/M | 保持REPLAY唯一PLAN/ledger/credit/数学/RT和每source关闭事实；新增退出/epoch接口只报告或授权自身状态，不接管O生命周期。 |
| AC-RESET | 保持唯一软件epoch与reset事务owner；只有真正关闭证据汇合后才发授权，收ACK后提交父epoch；不直接改P/O/源的valid或借用计数。 |

数据路径：真实SRC seal → VB-IF01注册S → 原AC source offer86/锁J → R4完整处理 → VB-IF02注册O → 原AC V788/ACK104并原子取得VIEW父引用(VB-IF03) → VB-V逐字段PLAN616 → 原BR OPEN619/REPLY888 → 三plane RQ/RR/JOIN/OUT → 原CLOSE/RELEASE → RT1171 → 新PLAN_EXIT267 → 父引用RETURN352/ACK360 → 真实OBJECT_RETURN295/ACK307 → VIEW_TERM497。

控制路径：独立VIEW_CANCEL128/RECEIPT135 → 锁旧PLAN的BR CANCEL224/ACK231；软件QUIESCE96/QUIET111 → 授权EPOCH_START128/每owner ACK140 → 父epoch提交/receipt与done消费后解除quiesce。新消息与同宽旧消息各自namespace不同。

容量选择是一个SRC slot、一个J_CTX、一个O BUILD/COMPLETE slot、一个VIEW父引用、一个OPEN借用（最多3个plane_ref）、一个P plan。BUILD与COMPLETE是同一slot的互斥模式；COMMIT后不同时建立下一BUILD。每VIEW只自动执行一个PLAN；REPLAY允许同result使用新plan的能力不等于本桥提供自动多次重放队列。

旧J的JOB_TERM消费可先于renderer结束，但新source job资格仍被O/VIEW占用阻塞。下一BUILD必须旧provider实际返还/对象退休、VIEW_TERM与旧JOB_TERM均实际消费、P退出/GAP结束、所有ACK/请求槽空且非quiesce/Q。source producer不得在桥外偷偷保存下一整图；若它已采集并held一个新SRC handle，该存储是第二幅图，必须另列真实容量。本保守候选只承诺可暂停调度，不承诺持续摄像或60Hz。

一幅1920×1080原RGB为49,766,400bit；最终EDGE为2,073,600bit；RC ANN为4,147,200bit；三者合55,987,200bit（6,998,400byte）。这是逻辑完整图量，不是本桥已分配RAM、Ti60可容纳证据或外部存储选择；class/grad/闭包/识别工作集合另属R4真实预算，不能隐去。

整体检查点：先阅读B/C再D/E；唯一VIEW/PLAN owner、两层引用、单图阻塞和授权新epoch均为候选重要选择。实际provider与相邻端口仍OPEN，不能凭本路径图宣布闭合。

## D. 命名字段、证书、新body及组合检查

### D1. 公共编码与J/V→PLAN616

全部整数unsigned；valid/ready独立于body。fire=沿前valid且ready且非rst；新接纳不在同沿穿透。除明确嵌套旧body外，本文新body按所列字段从高到低排列，最后字段占最低位。新body中的job96采用REPLAY已明列的低位epoch32、其上frame32、最高config32；从CONTROL命名字段恢复三个值，不按未明确的CONTROL packed JID私定cast。原嵌套J657、CANCEL128及原回复内部顺序保持来源原样；其旧packed解析澄清仍VB-B01。命名字段交接本身可以讨论，原body raw向量不能因此宣称冻结。

| PLAN616命名字段 | 来自锁定历史J/V与目录 | 语义及检查 |
|---|---|---|
| job.epoch32 | J.C.epoch | 软件处理epoch，等授权epoch；不是render或source代次 |
| job.frame32 | J.job_frame | JOB唯一分配，首号0；不是display_id/plan_id |
| job.config32 | J.C.config_id | 处理CFG提交身份；不是proposal/desired revision |
| source_image_id64 | S目录精确匹配J.source_handle/W/H所得 | SRC逻辑图身份；source_handle仅provider对象引用，二者不互代 |
| result_id64 | O注册COMPLETE分配 | 一个完整处理bundle身份；不取EDGE/ANN handle或job低位 |
| render_generation64 | 本次VIEW采用时由VB-V分配 | 完整历史render采用身份；同config/同颜色再次采用也不能复用成新事务 |
| display_id64 / plan_id64 | VB-V形成本次held PLAN前分别分配 | 两个独立序列，均首号1/严格递增；不是一个序列的别名 |
| W11/H11、algorithm2、profile_ref64 | J.source尺寸/J.C.CFG历史字段 | 必须与S/O证书及静态实例相等；RC核完整实体，非RC profile=0 |
| render112 | J.C.CFG的命名mode/split/颜色/开关 | 按REPLAY D1明确bit位置重新组装；不读最新C/D，不假定未明列的CONTROL packed render可直接copy |

J657=C539+job_frame32+source_handle64+W11+H11；V788=J657+final_edge_handle64+ann_handle64+planes_ready3。V是候选结果引用与历史快照，没有result/render/display/plan分配字段，不能强转PLAN。匹配时逐个比较完整C/J字段、source handle及尺寸、E/A handle、ready mask；同宽P539/C539也不别名解读。

PLAN render低位固定mode[2:0]、split[13:3]、edgeRGB[37:14]、ANN01[61:38]、ANN10[85:62]、ANN11[109:86]、show_edge110/show_ann111；RGB24为R高8/G中8/B低8。生产W/H=1920/1080、split540；合法模式/小图范围保持REPLAY，不改变原算法尺寸或质量验收。

### D2. 唯一分配、寿命与耗尽

| 身份/唯一分配者 | 分配事件、首值、保留与释放 |
|---|---|
| source_image_id / S | 完整合法SRC注册生效时分配1；不可变原源在J/O/VIEW/borrow期间不删；真实SRC return与全部通知消费后才空slot |
| result_id / O | 完整BUNDLE_COMMIT实际成功接纳时分配1；BUILD没有result_id，字段规范0；全对象退休且旧通知结束后才空slot |
| render_generation / V | 合法新V fire与父引用grant的同一原子事件分配1；ALREADY不再分配；至VIEW_TERM消费保持 |
| display_id、plan_id / V | 创建新的held PLAN时分别预留1；提出后即消耗，不因P拒绝/取消重用；两值与完整PLAN保存至所有关闭/VIEW通知结束 |
| parent_ref_id、borrow_id、plane_ref[3] / O | 各独立64bit非0序列，首1；父grant/OPEN真实成功时分配；未启用plane ref=0。授权全体匹配才使用，零不代表未知OPEN已无义务 |
| job_frame/config等 / 原owner | 仍遵CONTROL E5；桥不第二次分配、推进或清理它们 |
| software epoch / RESET | 冷合法共同rst为1；软件reset扩33bit检查并授权当前+1；只在所有旧义务真实关闭及新授权ACK汇合后提交父epoch |

上述新64bit序列每epoch next1。分配最大值那次合法，随后exhausted置1、next保持最大值；以后拒新而旧held收尾继续，扩65bit检查，不回绕。成功授权新epoch且旧义务已全结束才能重建next1。source/result耗尽阻止新注册；render/parent-ref耗尽使合法新VIEW明确拒绝EXHAUSTED并走未采用bundle退休；plan/display耗尽发生在已采用V后，形成无PLAN的失败关闭路径，不等待不存在RT。borrow/plane-ref耗尽使OPEN明确拒绝，VIEW父引用仍需返还。身份数字相同只在各namespace内比较，不表示同一资源。

### D3. O完整证书、注册与两层引用

SRC_REGISTER156=epoch32/source_handle64/W11/H11/pixel_count22/format8/flags8。format0为canonical原RGB24，其他当前非法；flags低3依次是原源完整、不可变、支持本合同返还，其余5规范0。真实SRC_PROVIDER必须拥有相同handle/尺寸、N=W×H个连续逐坐标有效像素、正确尾标记及无未结写；注册表核真实owner封存事件/记录，不只信flags。SRC_REPLY228=原156/source_image_id64/status2/reason5/registered1，成功0/0/1，失败1/合法非0/0且id0。

COMPLETE_CERT352依次为：schema8（本版1）/job96/source_image_id64/algorithm2/stage_started3/stage_closed3/stage_success3/input_pixel22/source_pixel22/final_edge_pixel22/ann_pixel22/stream_pair21/final_edge_pair21/ann_pair21/closure_fixedpoint1/profile_bound1/ann_sealed1/evidence15/zero4。算式333+15+4=352。evidence15低位依次coordinate_complete3/immutable_mask3/pending_zero3/object_registered3/raw_terminal_checked1/stage_identity_checked1/epoch_config_checked1。

stage bit0为stream、1为完整Canny闭包、2为完整识别/ANN。Sobel三stage mask均001，Canny均011，RC均111；不曾启动的stage不等terminal。input/source/final_edge pixel均N，stream/final_edge pair均P=N/2；RC ANN计数N/P且三额外flag为closure1/profile1/ann1；Canny为1/0/0，Sobel0/0/0；非RC ANN计数0。四类plane evidence mask RC111、非RC011；末三个checked均1。计数匹配还须逐坐标全覆盖、规范值域/尾标记、无重复/缺口；光有N个写不能封存。

O的完整证书必须从真实选定raw FS/CS接纳及检查、每个已启动final子级真实terminal、完整精确闭包固定点、真实圆/任意旋转矩形识别/最终ANN、逐坐标封存和实际pending关闭派生。class不是final edge，profile_bound必须引用完整不可变实体并核同J，零目标ANN仍封存全图0。R4提供这些真实账本/实体仍VB-B02/B04；外来请求中的成功位不能创造证据，CRC/hash/一份自报certificate不能替代provider事实。

BUNDLE_COMMIT1201=原J657/source_image_id64/final_edge_handle64/ann_handle64/COMPLETE_CERT352。非RC ann_handle0、V.ready=011；RC ann_handle非0、V.ready=111；EDGE所有算法均必须真实完整，SRC始终完整。BUNDLE_REPLY232=job96/source_image_id64/result_id64/status2/reason5/committed1，成功0/0/1；失败1/非0/0且result0。对原J和新CERT内job逐个命名相等检查，不比较两个96bit原向量猜字段。

O仅一个BUILD/COMPLETE ctx。接纳成功后唯一持有真实SRC/EDGE/ANN对象引用，J不能同时把同一对象归还；若V被拒绝或尚未采用即取消，O进入未采用退休并给J真实关闭证据，J不能只用REJECTED ACK形成close_done。O本轮不提供这些内容、存储或成功terminal的stub。

VIEW父层：old COMPLETE精确同V、old VIEW空/ACK空且render/parent-ref可分配时，V fire是唯一联合grant事件。V owner写采用资格/render代次，O owner写parent_ref与引用有效性；两者基于同一旧资格，各自唯一writer。下一沿ACK104才能报告LATCHED；不先ACK再异步尝试保留父引用。ALREADY只当前V完整同body，返回原采用事实，不增加引用；stale/publish_allow0/非法者可接纳拒绝且不改旧V。正常有容量不足则ready0，符合AC原合同。

OPEN层：P保持原OPEN619/REPLY888。O核完整PLAN绑定当前parent_ref/result/source/J/render/profile及真实COMPLETE，逐项核global_required；只成功fire分配borrow及需要的plane_ref，保存原H288/plan/display关联。complete_mask/replay_mask保持REPLAY规定；display不读某plane不免除algorithm完成证书。O唯一目录记录该borrow及各source合法关闭证明，P的good/JOIN/OUT不能替代目录。O接每source唯一owner真实ACK437消费事件及其不可变关闭记录，核对应H/plane、status/reason/ledger/closed位后才记closed；这是同一原始证据的读者，不新增第二source ledger writer，也不能接P自报的closed位代替。该只读事件连接需R4/REPLAY合并，现稿没有现成端口。成功RELEASE_ACK296只在对应真实source CLOSED、读取/effect/held响应闭合、P按原本地empty前提提出合法请求后由O产生；P和V不能第二次自行宣布borrow为0。

父引用RETURN352=job96/source_image_id64/result_id64/render_generation64/parent_ref_id64；ACK360=原352/status2/reason5/released1。成功0/0/1只表示这份父引用真实返还；不自动等于图已FREE。请求须真实RT/PLAN退出关闭或从未提出PLAN，且O没有borrow/未知OPEN；引用返还后O还要真实退休对象。ACK held期间旧引用元数据保留，不能清掉用于echo的body。

OBJECT_RETURN295=job96/source_image_id64/result_id64/plane2/handle64/reason5；ACK307=原295/status2/suffix_reason5/closed_mask4/returned1。plane0SRC/1EDGE/2ANN、3非法；BUILD失败无result时result0允许，匹配本地实际准备记录，不能据输入未知handle寻址。成功0/0、四位request/read/response/effect closed全1、returned1，由真实provider在实际读写/pending/held回复和效果均关闭后形成；失败1/合法非0/returned0。三个返回口各depth1可并行，但非RC/未实际分配对象不等不存在ACK。SOURCE_REG自己的源引用只在真实SRC返还证据后释放。物理关闭/取消能力仍须R4具体provider设计，不能把本ACK定义当已有实现。

### D4. 取消、RT和退出

独立VIEW_CANCEL128使用CONTROL命名JID96/algorithm_generation32，receiver=VB-V；VIEW_RECEIPT135=原CANCEL128/status2/reason5。它是新VIEW关闭入口，不是原AC-IF07 JOB CANCEL_REPLY136的改名。0LOCKED/0表示锁定取消/关闭意图，1ALREADY/0表示已有同意图或已退出，2NO_MATCH/非0表示无此历史VIEW，3REJECTED/非0表示协议/字段非法。receipt与P的ACK231不同，接受后下一沿可形成，完全不等待RT、CLOSE或返还。

原AC manual CANCEL128仍按CONTROL E3执行：未移交取消J；已真实移交回NO_CHANGE/TOO_LATE，不自动追加VIEW cancel。RESET或以后明确的VIEW关闭调用者使用本新入口。若父要让用户manual cancel也停止已采用VIEW，那是需另修AC行为的差异，本稿未作此选择。

匹配历史V的三个JID值及J.C.algorithm_generation，锁原完整PLAN224=job96/plan_id64/display_id64后才发BR CANCEL；未形成PLAN则禁止形成，不发不存在cancel；PLAN已held未fire则兑现它，等真实fire成为旧active后再提出CANCEL224；不能与IDLE的新PLAN同沿向P发取消。BR ACK231独立接纳/逐字段检查，不能用父receipt的消费清掉其义务。映射记录不读新C或当前JOB.valid。

RT1171保持REPLAY全部原字段。V独立接纳保存一次完整RT并核完整PLAN、已验证borrow及O目录事件、status/flags/计数规范；wrong RT不能清PLAN/引用。status0/1/2只有drained1与真实来源CLOSE/RELEASE/O记录一致才是可关闭候选；status3/drained0、非法suffix、未知OPEN或不一致进入父PROOF_PENDING/Q，保持引用。RT.borrow0仅表示该消息未保存已验证handle，不能当无借用证明。P成功/失败的实际RT不由V重新生成，也不因晚cancel改写。

新PLAN_EXIT267=P→V，job96/plan_id64/display_id64/bound_epoch32/status2/facts9。status0/reason省略且facts全1才是退出证书；其他status当前非法，不生成假的失败退出。facts低位为rt_consumed/gap_done/local_empty/known_open_none/borrow_none/source_sessions_none/published_requests_none/published_responses_none/not_quarantined。P唯一根据真实RT fire、随后完整GAP、原CLOSE/RELEASE消费/本地状态派生；不以RESET要求或父flag赋值为真。Q不产生EXIT。

这是REPLAY现稿没有的新接口候选。P在真实GAP结束后的后续旧闭合状态才提出EXIT，held至消费；旧PLAN字段pin到EXIT消费。published_requests/responses_none检查旧plan业务及cancel/ACK通道，不包含正在形成的EXIT自身，不能让证书等待自己消费。新PLAN接纳须EXIT已消费；V正常本来也不发下一PLAN。EXIT不释放O borrow，也不代替原RT或CLOSE/RELEASE；它只是补齐父侧可观察的GAP/本地退出证据。P的源关闭与O grant目录始终各自唯一owner。

VIEW_TERM497=父引用key352/status2/reason5/plan_valid1/plan_id64/display_id64/rt_seen1/facts8。facts低位为parent_release_seen/bundle_reclaim_seen/plan_exit_seen/no_borrow/no_unknown_open/local_empty/quarantined/close_requested。status0为渲染成功且引用已返还/对象真实退休，1失败但安全关闭，2取消且安全关闭，3隔离/引用仍保留；成功0/reason0，失败/取消用合法非0。无PLAN失败时plan_valid0、两id0、rt_seen0、plan_exit_seen0，其他真实关闭事实仍须成立，不等不存在RT。Q必须quarantined1且不冒称前两项完成。

VIEW_TERM不是生产APPLIED，也不是第二个P RT；它汇报桥及父引用生命周期。真实JOB_TERM可在VIEW采用后独立形成/消费，不得等待VIEW_TERM；VIEW_TERM的形成也不等JOB_TERM消费者，以免父通知互等。下一BUILD和epoch QUIET同时要求两者均消费。旧ctx保留到所有通知消费，慢observer不占用这些终态槽。

### D5. QUIESCE和授权epoch握手

QUIESCE96=原RESET96，由唯一RESET_OWNER发给桥，源reset事务原96在receipt/done完成前pin。QUIET111=原96/status2/reason5/facts8。facts低位为job_terminal_consumed/view_parent_none/plan_exit_or_never_started/O_objects_retired/source_registry_empty/no_unknown_open/all_held_empty/not_quarantined。all_held_empty只检查旧业务消息；本QUIESCE/QUIET事务、父独立reset receipt/done及后续授权不在该谓词内，否则会要求reset done先消费才能形成reset关闭证书。真实所有项1才success0/reason0；明确Q/无法证明时可形成status1/非0失败通知，父进FAULT_WAIT，不能成功done。永久不ready则请求未完成，不生成success。

QUIESCE仅注册关闭意图与停止新BUILD/V/PLAN/注册。它不设置任何closed、returned或borrow_none成功位。QUIESCE接纳沿已真实发生的旧注册/job/V/PLAN/OPEN/CANCEL/RT仍先登记；下一旧quiesce周期阻止新提议，旧held请求、ACK、FS/CS、JOB_TERM/VIEW_TERM/RT继续履约。父原UI/P/回复也按CONTROL结账，不能由桥代清。

EPOCH_START128=old_epoch32/reset_seq64/new_epoch32，由RESET唯一授权，要求new=old+1且33bit无溢出。七个逻辑接收者编号3bit：0V、1O、2S、3P、4SRC_PROVIDER、5EDGE_PROVIDER、6ANN_PROVIDER；7非法。无ANN实例也须由其明确无对象的唯一边界报告真实无义务/接纳授权，不省掉责任。当前全部同core；不把本接口当多域CDC证明。

每口ACK140=原128/owner_id3/status2/reason5/closed_before1/applied1。仅status0/reason0/两位1且全文匹配表示成功。1/合法非0/applied0是明确拒绝；2/3或非规范非法。closed_before只从该owner旧已实际关闭状态取得，不因为收到START置1；applied只在授权fire后本owner确实建立新epoch状态才1。授权source body从提出一直保持到七ACK真实消费，七个ACK槽各depth1且不等新job/PLAN/OUT。

先取得真实QUIET和父全部旧控制/终态/引用关闭，再提出START；接收者ready仅在自身旧epoch匹配、无Q/unknown borrow/held/旧效果且允许关闭证明时为1。接纳后各唯一writer更新自身授权epoch和本epoch序列/高水位，下一沿形成ACK；P只在这一授权事件重建bound_epoch/authorized_epoch/seen/high-water，不凭不同PLAN.epoch清理。一个合法全域冷rst建立授权epoch1；P首次PLAN只能属于该授权epoch，不是任意首次PLAN自授session。

在全部ACK前父保持quiesce，新旧部分owner更新期间无业务接纳，不回滚已经接纳授权的owner，也不拿晚ACK旧身份当新授权。全部ACK真实消费后RESET提交父software epoch一次，原CFG/J/KEY等各自按CONTROL E5建立默认/保留reset_seq；其余父owner汇合接口仍须跨稿冻结。成功done仅在这些提交真实完成后形成；receipt/done均消费后解除quiesce，新业务最早后续旧非quiesce沿接纳。

七口有一口拒绝/未知，保持FAULT_WAIT和quiesce，不形成成功done，不单端广播reset清借用。授权已部分应用时不得恢复旧业务；恢复须另行设计或合法全参与者共同硬rst及外部效果关闭证明。共同硬rst是独立前提，不是软件Q恢复捷径；有未共同reset的外部读取/效果时，不能宣称其关闭。

### D6. 新schema及拟改相邻稿

| body | bits / hex digits / 高padding | 持有者、容量和结束 |
|---|---|---|
| SRC_REGISTER / SRC_REPLY | 156/39/0；228/57/0 | source caller held1；S record1与reply1，成功字段可共享该不可变record；reply消费前不覆盖 |
| COMPLETE_CERT / BUNDLE_COMMIT / BUNDLE_REPLY | 352/88/0；1201/301/3；232/58/0 | R4提出COMMIT held1；O一个ctx及独立reply1；1201源槽是R4真实义务，桥不复制整条作为第二ctx |
| VIEW_CANCEL / RECEIPT | 128/32/0；135/34/1 | V RX1/receipt1；receipt可借同RX全文直到消费；独立BR cancel-map224/ACK接收资格1 |
| PARENT_RETURN / ACK | 352/88/0；360/90/0 | V request1/O ACK1；锁旧VIEW/O元数据直到匹配ACK消费 |
| OBJECT_RETURN / ACK | 295/74/1；307/77/1 | O每plane request1/provider ACK1；实际provider holding须R4预算，非零handle不是capacity证明 |
| PLAN_EXIT / VIEW_TERM | 267/67/1；497/125/3 | P EXIT1/V TERM1；元数据可引用已pin旧ctx，不得在body held期间复用 |
| QUIESCE / QUIET | 96/24/0；111/28/1 | 父reset txn1pin；桥关闭txn1/quiet1，独立业务通知槽 |
| EPOCH_START / ACK | 128/32/0；140/35/0 | 父授权1、七独立ACK1；授权body保持到全部ACK消费 |
| 原J/V/PLAN/RT | 657/165/3；788/197/0；616/154/0；1171/293/1 | 原语义不改；J/V与桥PLAN通过命名字段映射；P及桥的真实独立hold分别列预算 |

本文新reason5：0NONE、1FIELD、2BINDING、3NOT_COMPLETE、4UNSUPPORTED、5VALUE_FORMAT、6KEY、7COUNT、8PROVIDER_FAILED、9CANCEL、10CLOSE、11RETURN、12OVERFLOW、13PROTOCOL、14EXHAUSTED、15EPOCH、16QUARANTINED、17PROFILE、18CAPACITY、19TOO_LATE、20UNREGISTERED、21AMBIGUOUS；22…31非法保留。原REPLAY reason0…14及CONTROL error5保持原namespace；新16等不直接写入原ACK231或AC reply136。

| 待合并差异 | 拟改文件/条文，影响与本轮边界 |
|---|---|
| Δ01 命名解析 | CONTROL D1/D2及B05 schema：明确旧JID/render packed对应命名字段，或用命名端口；本文不私定旧cast。REPLAY D1 job96及render位序已明确，原body不改。 |
| Δ02 J_CTX pin/单图credit | CONTROL C/D2 IF05/E3/E4：J状态结束不提前覆写仍被O/V/TERM引用的ctx；source offer readiness接真实S/O/VIEW空资格。其算法请求/原FS/CS/JOB_TERM body不改。 |
| Δ03 O注册/VIEW父引用 | CONTROL IF06/E3/E4、REPLAY C/D2 IF02/08、R4 provider设计：采用O唯一目录、原子V grant及真实未采用退休，不再以V.valid清0释放图。V788/ACK104、OPEN/RELEASE原body不改。 |
| Δ04 VIEW取消/终态 | CONTROL E4/IF08与B03 HB-IF05：新增独立VIEW_CANCEL/VIEW_TERM；原manual CANCEL128→136已移交TOO_LATE保持。REPLAY CANCEL224/ACK231/RT1171 body不改。 |
| Δ05 P真实退出 | REPLAY E1/E5及BR-IF10邻接：新增PLAN_EXIT267、GAP后真实证书及EXIT消费前pin旧PLAN/禁止新PLAN。不会新增第二ledger/borrow owner，也不免原CLOSE/RELEASE。 |
| Δ06 epoch授权 | CONTROL E4/E5、REPLAY E1/E6/BR-T15、O/S/provider：新增QUIET/START/ACK和授权初始epoch1；P不再从任意首PLAN自授epoch，软件reset只在旧证据闭合后重建高水位。父其他owner ACK汇合仍需合并。 |
| Δ07 schema/预算/trace | B05完整schema/文件计划与各稿F/G/H：登记新body、hex高padding、真实holding及套件；不能拿旧R2 pixel200/class125或旧物理header当新消息。 |

以上均未改原文件、未获实施批准，明确保留VB-B01/03/05。当前旧两稿只可在原范围读审，不能直接接本文不存在的端口。

## E. 局部状态、中文草图和有限容器

### E1. 状态、不变量与预算

S状态EMPTY→REGISTER_CHECK→BOUND→IN_BUILD→IN_BUNDLE→RETURN_WAIT→NOTIFY_DRAIN→EMPTY；O状态EMPTY→BUILD→CHECK_COMMIT→COMPLETE→PARENTED/BORROWED→RETURN_PARENT→RETIRE→NOTIFY_DRAIN→EMPTY，BUILD失败亦需实际RETIRE；V状态EMPTY→ADOPTED→OFFER_PLAN→WAIT_RT→WAIT_EXIT→RETURN_PARENT→WAIT_RETIRE→STATUS→GAP→EMPTY，错误Q通知后ISOLATED。状态名不授予撤held许可。

INV01：唯一J_CTX不可变内容覆盖O/V/PLAN/通知生命期，新BUILD不覆写；INV02：O唯一写对象/父引用/borrow目录，每次真实grant/return只一次；INV03：P自己的关闭来自原ledger/CLOSE/RELEASE/RT，EXIT不是另一份账本；INV04：本桥仅完整命名字段构造身份、旧PLAN取消，最新C不参与；INV05：published body保持且旧fire先结账；INV06：Q/unknown OPEN使parent_ref和epoch义务保留；INV07：单图占用时无第二BUILD；INV08：新epoch只来自RESET授权及真实各owner接纳；INV09：原始关闭证据不因QUIESCE/START被写成成功。

下表是可实现的有限寄存器候选，不是全机去重预算或综合结果。字段共享仅指同core、不可变ctx被明确pin时的物理保存选择，不能从“有handle”推理正文已存在。O与V不再各复制一份J657；唯一J_CTX657沿用JOB原容器并延长pin。REPLAY自身PLAN616/RT1171与桥副本是不同holding，不能删除原槽。

| 新容器 | 个数×位宽 / bit | owner、并行生命期和共享说明 |
|---|---|---|
| S完整record | 1×220=220 | S；SRC_REGISTER156+source_image64。reply状态在控制域，echo引用该record；错误请求也需先锁record至回复消费 |
| O完整metadata | 1×609=609 | O；source/result/E/A四64+CERT352+J_CTX索引1；BUILD/COMPLETE互斥，不含图像内容 |
| VIEW parent slot | 1×130=130 | O；parent_ref64/render64/有效1/返还pending1；引用有效清后旧metadata仍pin到ACK及VIEW_TERM结束 |
| O borrow slot | 1×489=489 | O；H288+plane_ref192+required3+known1/granted1/closed3/releasepending1；与parent slot同时活 |
| 桥PLAN shadow | 1×616=616 | V；从提出到RT/EXIT/引用通知结束保持；不删P自身PLAN槽 |
| 采用前render代次 | 1×64=64 | V；合法V采用后、PLAN形成前保存；与后来的shadow保守重复计，未假设自动复用 |
| 桥完整RT接收 | 1×1171=1171 | V；真实RT fire后保存原快照至关闭/VIEW_TERM消费；不拿它改写P终态 |
| VIEW cancel保存 | 128+224+8=360 | V；RX/回执借RX；独立锁定BR map及ACK status/reason/seen8。回复消费不清map等待义务 |
| provider ACK证据摘要 | 3×13=39 | O；每口status2/reason5/closed4/returned1/seen1，只在完整echo真fire校验后保存 |
| EXIT / parent ACK摘要 | 44+9=53 | V；EXIT status2/facts9/bound_epoch32/seen1；parent ACK status2/reason5/released1/seen1；key由pin ctx比较 |
| BUNDLE_REPLY槽 | 1×232=232 | O；独立held，可正确回显被拒的陌生job/source；不占V ACK槽 |
| epoch协议容器 | 128+7×32+7×13=443 | 父START全文1；七owner授权epoch各32，七ACK owner3/status2/reason5/两flag2/valid1合计13/口。ACK echo可引用保持中的父START；不能早撤父body |
| 十个新序列 | 10×(64+1)=650 | source/result/render/display/plan/parent/borrow及三个plane_ref各next64/exhausted1；不能合成免费同一个counter |
| O串行预检工作字 | 2×32=64 | O；输入/期望字段窗口，ctx及源COMMIT body全过程pin；不保存第二1201body |
| S/O/V控制状态 | 64+192+256=512 | 各owner唯一写state、valid/pending/资格、预检索引/错误/事务mask；明确有限上界，不把新FSM计0 |
| P EXIT新增状态 / JOB pin | 12+2=14 | P EXIT status/facts/valid；JOB给O/V两份pin资格。P原ledger/高水位/RT另属REPLAY |
| VIEW_TERM附加保持字段 | 1×17=17 | V；status2/reason5/plan_valid1/rt_seen1/facts8；其480bit身份引用已pin key/shadow，整个body仍稳定 |

合计新有限候选5,683bit。该数字含父/相邻接口扩展，不是本文一个RTL模块FF数；上游原J657、原V资格、原VIEW_ACK104、RESET txn96、P的PLAN/RT/credit/数学槽、R4源COMMIT1201及provider ACK/读取pending均不得因此删除或计0。若跨module不使用上述pin引用而复制body，应真实增加对应容器；不得将5,683当整机资源闭合。串行预检索引/状态只给有限结构，不宣称STA频率。

本桥新增图像RAM0、DSP0只是逻辑结构候选；实际O引用的全图和算法工作RAM由R4提供，provider有多少同步RE/capture/held slot须另列。没有隐形profile库、整图FIFO、父header4731副本或历史无限缓存。正式生产预算仍VB-B02/06。

### E2. 注册SRC、建立BUILD与提交完成

1. 冷合法共同rst屏蔽fire，S/O/V空、授权epoch1、next身份1、控制valid0；原JOB/CFG按CONTROL默认。没有COMPLETE不能制造V或APPLIED。
2. old S/O空且通知结束、非quiesce时接SRC_REGISTER，只锁本请求和reply资格；下一沿核epoch/尺寸/格式/N/flags及真实provider封存记录。全通过分配source_image_id并形成SRC_REPLY；拒绝不建立对象注册，echo持有至reply消费。registered reply真实消费后源offer86才能向JOB提出。
3. 原source offer fire须精确匹配old S、旧C及O真实BUILD credit；JOB分配frame并锁J，S/O进入BUILD并pin J_CTX。该沿新C提交仍不进入J。准备收集器/完整profile后原子核启动保持CONTROL/原FE/C0规则，本桥不越权发FJ/CJ。
4. R4按真实完整处理和封存证据提出COMMIT1201；O预留独立reply，在valid保持且ready0期间串行核J/body/evidence与固定可信记录，38个32bit逻辑字段窗口（末17bit，其余高pad0）。每步只用旧pin ctx/旧可信证据，不能读下一C。预检失败也需要真正接纳后形成拒绝reply，不能吞request。
5. 只有全部字段及真实COMPLETE谓词合格、身份可分配、源/对象引用完整时COMMIT fire注册result_id/CERT及对象目录。COMMIT后R4不能再写这些对象，J不另行归还已移交O的对象。回复真实消费后才能提V788；source/BUILD失败走真实provider关闭并返回，不能造成功COMMIT。
6. 完成前取消：尚未提出COMMIT可停止新提交并关闭已准备对象；已held COMMIT先履约，其fire与cancel同沿先注册真实effect，随后若不准发布走未采用RETIRE。每个曾分配对象独立关闭，未分配的不等待。O未采用退休真实完成后J才具close_done证据。

### E3. VIEW采用、PLAN提出与原重放

1. old COMPLETE/V ACK可用，核V完整body、旧epoch/algorithm_generation/publish_allow。合法V fire与O父引用grant同事件：O分配parent_ref，V分配render_generation并锁引用及历史快照；下一沿LATCHED。旧V完整重复ALREADY，不分配第二grant；同身份换body拒绝，不修改原目录。
2. ADOPTED后续沿且非关闭/取消/quiesce，分别预检两个新序列，命名构造完整PLAN并保持。序列耗尽则无PLAN失败，直接走安全父引用归还/RETIRE，不产生P RT。外部新CFG/profile不可变资格变化不改历史PLAN。
3. PLAN已经提出就不得撤；真实PLAN fire成为plan_sent旧事实之后，P自行VALIDATE/OPEN/RQ/汇合/OUT。桥仅接O真实grant/release目录事实与原RT；不从OUT EOF或P ready推理borrow关闭。
4. OPEN成功与取消同沿先保存真实grant并关闭；原OPEN拒绝无borrow可失败关闭，但已提出或异常reply造成未知OPEN不得当没有义务。O目录持有真实已取得grant，P Q不能替它FREE。
5. 正常/失败RT真实fire后保存原全文、核expected PLAN与目录。后续等P真实EXIT；RT fire同沿不能当GAP已过去。P EXIT真实接纳后才允许P相关本地退出资格；O只有原CLOSE/RELEASE消费可改变borrow目录，EXIT本身不改borrow。

### E4. VIEW取消、返还、终态及Q

1. VIEW_CANCEL fire只锁RX并预留receipt；下一沿命名匹配历史V/J的generation并设置sticky close。receipt下一沿可交付，既不等P ACK也不等RT/RETURN。无匹配NO_MATCH，不将旧body套在当沿新V或PLAN上。
2. 尚未形成PLAN则不再生成；已held PLAN兑现。只有旧plan_sent且P未退出、无旧BR cancel outstanding时发锁定CANCEL224；接其真实ACK独立结账。取消和末RT/OUT/OPEN同沿都先记录旧fire，原RT成功快照不反悔。
3. 合法drained RT＋真实EXIT＋O无borrow/unknown OPEN＋所有桥/P held义务结清后，V提出父RETURN352。没有PLAN路径用明确never_started事实替代RT/EXIT，其他引用关闭仍真实。已有RETURN保持，重复取消只ALREADY。
4. O接受RETURN只结对应parent_ref，不直接清对象；ACK360完整成功实际消费后V记录返回事实。O随后对实际拥有planes发OBJECT_RETURN295并接各provider正确ACK307；数据/请求/响应/effect关闭证据不能由O或RESET代写。原SRC源引用亦真实返还后才退休。
5. 对象真实退休后可形成VIEW_TERM497，parent_ref/id/PLAN身份仍由旧ctx保持，STATUS全文held。JOB_TERM和VIEW_TERM消费互不等待，慢观察者只复制。两份终态、全部ACK及GAP都结束后才释放ctx/空注册slot，给下一BUILD credit。
6. wrong RT/OPEN/CLOSE/RELEASE、Q或未知return进入ISOLATED/PROOF_PENDING；消费Q通知只结束通知，不结束引用/图或借用。仍履约已published消息，不用Q清引用；禁止新PLAN/BUILD/START。晚ACK不能自动将冻结Q改成功，恢复必须另设计真实恢复证明或合法共同reset前提。

### E5. 软件reset的真实关闭和新epoch

1. 父接受RESET96先预留原receipt/done并检查epoch可增。其下一旧quiesce周期向桥提出QUIESCE96，禁止新source/job/V/PLAN/注册；当接受沿已有fire先登记，held全部结账。桥不得直接reset原P/O/provider状态。
2. 父取消真实旧J并收选定raw status/final terminal/JOB_TERM；桥关闭历史VIEW与P并消费RT/EXIT、RETURN/provider ACK、VIEW_TERM。没有启动过的阶段不等不存在terminal，失败不等完整P/EOF；已经启动/已经held的承诺不能省掉。
3. QUIET success只从真实ledger、目录/退出证据和各通知消费导出。P Q、unknown OPEN、hold未消费或provider effect未证明关闭使QUIET不成功，父FAULT_WAIT；即使RT.borrow0/PLANready/本地empty也不足。
4. 父全旧控制/UI/P/reply及桥QUIET也结清后发EPOCH_START；保持授权全文及七位sent/ack资格到完成。接收者检查自己的旧已闭合状态，然后实际接纳并唯一更新新授权epoch/本epoch计数；下一沿ACK，不能先ACK再关旧义务。
5. 七ACK真匹配成功且父其他owner提交资格完成后，RESET提交software epoch、新默认状态并形成原done136；未全成功保持quiesce，不能重新开放或反向用新epoch证明旧借用不存在。receipt/done均消费后才放行新动作/BUILD。
6. 跨epoch迟到原body先核epoch/对应txn，明确拒绝或协议隔离，不更新当前expected/high-water/计数/引用。极限epochFFFFFFFF的reset先拒绝，不制造半关闭后回1。独立reset_seq/exhausted仍按CONTROL跨软件epoch保留，桥不归零它。

### E6. 具体组合反例

N01：J.frame0、source_handle7、EDGE handle9；S分配source_image1、O分配result1，V分配render1，PLAN display1/plan1。下次数字也许相同但namespace不同；用handle7填source_image会被目录拒绝。不能将C proposal64截成render1。

N02：mode1显示仅SRC但R4只产class且无final EDGE。即使SRC N、CS reason0，CERT stage/最终EDGE封存不成立，COMMIT拒绝；不能为了显示RGB缩小完整job职责。

N03：V1/PLAN11输出停顿，CFG/J2尝试变化。历史cancel命名J1/generation1只产生PLAN11的224，不能用当前J2/新plan12。单图credit使J2 BUILD尚未接受，不藏第二RGB图。原AC manual在J1已移交后仍TOO_LATE。

N04：VIEW_CANCEL与held PLAN11 fire同沿。先记PLAN真实接受，下一沿锁旧活动11再发cancel；不把cancel与IDLE新PLAN同沿送P。parent receipt可以先完成，关闭继续等真实ACK/RT。

N05：RT FAILED_DRAINED到达e0，P在e1 GAP，EXIT最早后续旧gap_done沿提出。e0不能归还parent_ref；只有EXIT与O release证据齐全才RETURN，不读一根ready自证退出。

N06：bad OPEN_REPLY使P RT status3/borrow0；O实际上已分配borrow5。消费Q后parent_ref仍在，QUIET失败，PLAN.epoch2拒绝、不清borrow5；只有真正关闭/另设计恢复才可能解除。

N07：QUIESCE与V/OPEN接纳同沿。先登记真实parent/borrow，随后关闭它们；不能根据新quiesce撤V ACK或OPEN回复，不能在reset receipt后立刻清ctx。

N08：七授权口中P已ACK新epoch2，EDGE_PROVIDER未给关闭证明。父保持quiesce，不开始epoch2业务、不回到epoch1混合运行、不以P ACK替EDGE关闭。

N09：JOB_TERM held而VIEW_TERM也held。两消费者独立ready，不得JOB_TERM等VIEW_TERM先fire且VIEW_TERM等JOB_TERM先fire；下一BUILD仍要两者均消费。这是容量阻塞，非免费图复用。

N10：plan_id只剩最大号、display_id已耗尽。先整体预检两序列，不能部分分配后形成不匹配PLAN；已采用V走无PLAN失败/RETURN/退休/VIEW_TERM，保留完整图真实关闭义务，不等不存在RT。

## F. 语言、RTL A–L与三份映射

拟采用SV2009、同域时序非阻塞/组合阻塞；当前无代码/编译证据。C++未采用，不生成指针/RAII/异常实现。未来独立参考采用明确不可变对象/离散事件模型，不能把DUT成功flags/RT当黄金所有权账本。

| RTL A–L | 本桥合同及限制 |
|---|---|
| A 数值 | unsigned命名字段；ID64先扩65、epoch32先扩33；N=W×H用22bit、pair21；计数校原值且不回绕，位宽不等于意义相同。schema/hex pad见D6。 |
| B 时钟/观察 | 同core上升沿旧valid/ready；e0接纳只存，后续沿核/提交；未来TB下降沿驱动、沿后稳定观察，不拿NBA新数据改同沿effect。 |
| C 接受/交付 | V grant唯一联合fire；PLAN/OPEN/CLOSE/RELEASE/RT/EXIT/parent RETURN/provider ACK/TERM分别真实事件。提前通知不代效果关闭。 |
| D valid/推进 | 无效不分配ID/引用，不把ANN00或borrow0当不存在；每个真实effect只登记一次，非法body也独立结request/reply义务。 |
| E 反压/保持 | 所有held全文和sideband稳定；ctx pin直到最后引用/通知；receipt与真实cancel/RT/返还槽独立；取消不撤held PLAN/COMMIT/OPEN。 |
| F 延迟/吞吐 | 接纳→校验→效果→后续ACK明确分沿；38字预检是候选串行阶段，不承诺固定端到端cycle；单图阻塞不证明60Hz。 |
| G 复位 | 同步高共同rst全fire0，只有所有参与者及外部效果合法共同重建才能撤本域valid；软件reset必须真实关闭/授权ACK，Q不走捷径。 |
| H 配置 | J锁旧C；PLAN恢复历史render/profile；算法屏障同沿旧移交优先；RESET唯一软件epoch，原计数保留/重建按CONTROL E5。 |
| I 存储 | C单图逻辑量、E1有限新容器；BODY可引用pin ctx但不能读取latest字段；实际图RAM/provider pending/吞吐由R4/R5闭合。 |
| J 身份 | source_handle/source_image/result/render/display/plan/borrow/parent namespace分开；job按命名恢复；原lane/坐标/mode0映射保持REPLAY。 |
| K CDC | 当前全部同域，无新CDC；父授权共享body只在同域及稳定pin条件成立。真实摄像/固定视频/多域reset仍R5 OPEN。 |
| L 实现 | Ti60F225目标、已有工具；本桥0整图RAM/0DSP为结构候选，5,683bit是有限寄存器候选而非网表。时钟/pin/综合/PNR/STA/bit全NOT_RUN。 |

共同行为/数值契约：独立参考以真实注册源、完整算法结果、不可变CFG及显式身份序列判断V/PLAN；逐字段无误差映射，原render数学保持REPLAY。完整识别P/R≥95%、IoU0.5及原场景范围仍整包/R4独立验证，不恢复撤回尺寸/数量/噪声界限。

硬件执行契约：独立事件账本逐口判fire/引用grant/消费/返回，先记录旧fire再取消/屏障；EXIT只派生P已有真实账本，START只授权已经闭合者；函数调用顺序不能代这些握手/holding证据。

对应契约：软件对象的原源、最终EDGE/ANN、完整J/render和每次父引用/borrow以全键对应硬件txn。取消比较真实已交付前缀及实际关闭，不伪造成功后缀；Q软件也保留对象/借用，不能因为RT通知完成就删除数组。共同reset前置成立时旧run全体作废，新epoch不重解释旧消息；物理APPLIED另属R5。

## G. 实施及未来验证（NOT_RUN）

先合并D6跨稿差异并闭合VB-B01…06，建立共同不可变实施基线/完整schema/独立审阅，再纳入整包READY；用户明确批准指定整包版本、范围和基线后，才在获批work生成source_registry、completed_bundle_owner、view_plan_bridge、epoch_authorization及真实provider适配/参考/TB。计划符号不是文件已生成；不能以空stub替代R4。

| TEST | REQ/接口/输入和事件 | 期望、方法与观察 |
|---|---|---|
| VB-T01 | REQ01/02，完整1080p algorithm0/1/2、全部业务mode | 命名J/V→PLAN、完整certificate/真实目录、正确mask/计数；独立字段与整图账本，NOT_RUN |
| VB-T02 | source handle与ID同数/异数、config/proposal/render同数、旧JID packed未明列 | 只命名相等/显式pack，不私定cast或截低位；schema pad/高位全检，NOT_RUN |
| VB-T03 | mode1仅SRC读取但class冒final EDGE、CS0无闭包、RC零目标/缺ANN/坏profile | 不完整COMMIT拒绝；零目标仍完整ANN；真实provider证据非自报flag，NOT_RUN |
| VB-T04 | 旧J/VIEW/PLAN在途，新D/C提交、新job offer | 历史快照/ctx pin，单图credit阻塞新BUILD，无隐形下一图；NOT_RUN |
| VB-T05 | V采用及algorithm屏障/QUIESCE同沿，COMPLETE/body重复/换字段 | 旧fire真实grant先记，ACK不反悔；ALREADY不增ref，错误不改旧目录；NOT_RUN |
| VB-T06 | CANCEL与PLAN提出前/held/fire/RT/EXIT各同沿，最新J已不同 | receipt不等RT/RETURN，锁旧PLAN224，IDLE不误取消当沿新plan；原manual TOO_LATE保持；NOT_RUN |
| VB-T07 | three-source wrong echo、独立CLOSE、原RELEASE_ACK/RT与O目录不一致 | 原ledger保留/关闭；坏证明不清borrow/parent_ref；不得创建第二owner，NOT_RUN |
| VB-T08 | RT fire/GAP/EXIT前后、late/wrong EXIT、无PLAN耗尽关闭 | 真实后续退出才RETURN；never_started不等不存在RT；元数据持有完整，NOT_RUN |
| VB-T09 | parent ACK held、provider return慢/坏closedmask/效果未闭合 | parent return不等于图FREE；真实三口证据后退休；请求/echo pin，NOT_RUN |
| VB-T10 | Q.borrow0但O已grant、未知OPEN、晚ACK/不同PLAN epoch | 保留两层义务与Q，QUIET不成功，晚消息不自动恢复或改终态；NOT_RUN |
| VB-T11 | UI/P/JOB_TERM/VIEW_TERM/RT/return held下软件reset | 独立reply/status消费、无父通知互等，old fire先记；所有真实关闭后才START；NOT_RUN |
| VB-T12 | 七START/ACK独立停顿/拒绝/错owner/晚旧txn，部分已应用 | quiesce持续，ACK不等新job；无第二writer/无部分回滚，done不伪成功；NOT_RUN |
| VB-T13 | 首号/最后号、plan/display联合耗尽、epoch最大、软件epoch后reset_seq保留 | 新ID首1/最大一次/不回绕，旧收尾继续，reset最大先拒；NOT_RUN |
| VB-T14 | 合法共同rst各阶段、非法单端/Q外部效果未闭合 | 合法fire0/新run隔离；无证明不声称硬rst释放外部义务；NOT_RUN |
| VB-T15 | 消费者永久不ready、有限非同步停顿、source下一图提前存在 | 不覆盖held/不超有限槽；永久等待不成功；第二整图显式容量才可接；NOT_RUN |
| VB-T16 | 真实R4/provider/完整生产工程接入 | 完整数学、质量、账本、真实资源/时序分别取证；本桥typed终态不冒APPLIED；NOT_RUN |

未来case需不可变seed/有限停顿上界及独立操作账本；permanent stall是检查保持/不伪成功的负例。精确cycle/wall timeout、完整文件及工具基线仍VB-B05/06，不能要求批准前生成可执行检查器。测试在沿前判fire、沿后稳定核状态，正文场景不是运行结果。

## H. 双向追踪

| REQ/来源 | MOD/IF/步骤/不变量 | 计划稳定符号（未生成） | TEST / 当前证据 |
|---|---|---|---|
| VB-REQ01 / HB-IF02、AC D3 | S/O/J；IF01/02；D3/E2；INV01/02 | source_registry、complete_certificate、bundle_commit | T01/03/05/16；源稿事实＋本候选，provider OPEN |
| VB-REQ02 / HB-IF03 | V；D1/D2/E3；INV04 | view_plan_bridge、named_job_fields、identity_allocators | T01/02/04/13；纯字段设计 |
| VB-REQ03 / HB-IF02/04/05 | O/P/V；原CLOSE/RELEASE/RT、新EXIT/RETURN；E4；INV02/03/06 | parent_reference、open_borrow、plan_exit、object_retirement | T07…10；当前缺新接口/真实provider |
| VB-REQ04 / HB-IF05、AC E3/E4 | V；CANCEL128→224；D4/E4；INV04/05 | historical_plan_cancel、view_cancel_receipt | T06/11；原manual规则保持，新入口候选 |
| VB-REQ05 / HB-IF06、AC E4/BR E1 | RESET/P/O/S/providers；D5/E5；INV06/08/09 | bridge_quiet、epoch_start、epoch_ack | T10…14；跨稿合并OPEN |
| VB-REQ06 / 原完整生产目标、有限容量派生 | S/O/V/J；C/E1；INV01/07 | build_credit、job_ctx_pin、one_bundle_capacity | T04/09/15/16；逻辑量与资源分层 |
| VB-REQ07 / 根v0.2 | 全模块；D6/F/G/H；INV05 | typed_schema、held_body、独立账本/中文注释 | 全TEST；只有本文设计，NOT_RUN |

反向每个计划单元只负责命名适配、真实注册/引用/关闭、有限状态或验证；不得借桥稿增设物理视频/外存驱动或完整算法stub。实际代码/基线/测试位置待批准实施后登记，日志/黄金所有权账本不得引用DUT当前RT/flags生成期望。

## I. 门槛与评审

①整体行为/样例见B/C/E6；②真实读取/职责/复用见A/C；③字段/容量/相容差异见D但VB-B01/02/03/04未闭合；④状态/不变量/中文沿见E；⑤语言/三份契约见F；⑥正常/取消/Q/reset走查见B/E6；⑦实施/验证/trace见G/H；⑧无当前阻塞不满足；⑨保存后实际全文读回/hash另报告；⑩本稿v0.1和纯文档边界明确，未冻结整包实施基线。

因此保持LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN，不关闭B03/B05、不改变两稿/整包/正式状态。不把尚未运行测试反复当设计阻塞；真正阻塞是实际provider合同和当前不存在的新接口/packed澄清尚未合并。没有用户对本指定版本实施的批准，停止在纯文档交付。

## J. 变更与恢复

本稿相对CONTROL/REPLAY新增O注册证书、两层引用具体桥、历史cancel映射、PLAN_EXIT/VIEW_TERM、QUIET/epoch授权、single-image credit/J_CTX pin和typed schema；这些都在D6列为待合并提议，旧稿没有被悄改。原J657/V788/PLAN616、原算法/渲染数学和原manual已移交TOO_LATE规则保留。旧消息内部位序不反转，命名恢复优先。

改变capacity/分配owner/证书/关闭/取消/epoch/holding/schema或资源映射时先修REQ/IF/E/TEST，再跨稿复核与整包重新评审；不能凭未来获批的旧版本继续改变行为。恢复先读规则、最新三来源/hash、本稿/OPEN及实际批准，核真实owner/pin/旧通知。当前没有实现PASS可继承。

## K. 实现与验证实录

本轮只有控制面与三个源文件实际读取、纯文字设计、本文新增及保存后实际全文读回。业务RTL/模型/功能脚本/TB/project/约束未生成；仿真、综合、PNR、STA、bit、硬件下载/观察全NOT_RUN。没有网络/安装/数据库/指定外部存储器件调查，原HDK和其他设计/报告/正式状态保持。

字段算术与候选容量是文档分析，不是网表或真实效果证明；COMPLETE/returned/closed/APPLIED只在未来相应真实owner提供直接证据时成立，本文不伪造已存在的数组/provider/接口。

## L. 阅读与交付

阅读次序：CONTROL/REPLAY当前全文与B03报告→本文B整体→C唯一owner/单图量→D1逐字段→D2分配→D3证书/两层引用→D4取消/RT/退出→D5授权→D6上游差异→E中文步骤/反例→F/G/H→A/I OPEN。

完整普通路径为真实SRC注册→旧C锁J→R4完整成功封存→O注册→V父grant→新PLAN→P OPEN借用→三plane重放→原CLOSE/RELEASE/RT→真实EXIT→parent RETURN→provider真实退休→VIEW_TERM/旧JOB_TERM消费→下一BUILD。Q停在保存旧引用和FAULT_WAIT，不以新PLAN/RESET自证关闭。

本轮完成纯文档候选，代码/功能/生产时序/质量/人工理解均待对应证据；理解验收待用户实际反馈，不把讲解当已理解。下一允许动作是按D6与父/R4联合合并审阅，不生成业务代码或执行工具构建。
