# TRACK4-ALGORITHM-R4-RECOGNITION-001：完整分辨率识别调度与逻辑对象设计 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本文只提出R4圆、任意旋转矩形识别的算法与调度合同；没有业务实现，没有真实完整存储后端或生产性能证据。

## 通用计划字段

- Goal：在完整1920×1080最终EDGE和同帧GRAD上，形成可读的POINT→候选→拟合→冻结几何核验→精确去重→完整ANN/记录→真实关闭路径，接现行独立R3数值服务。
- Current state：规则、模板、BATCH/R2/R3、CONTROL/REPLAY、最新VIEW桥及R4-CLOSURE、原识别纯算法/数值/执行章节已实际读取；旧物理消息和旧资源复用不作为本稿接口。
- Target state：算法选择、逻辑容量、唯一owner、逐口握手、数值和中文步骤可独立审阅；与真实backend、完整O目录及父组合合并后，形成整包指定版本的设计批准候选。
- Gap：实际存储与资源映射、生产profile实值及质量/性能选择、GRAD封存收集器、真实私有对象归还目录、完整bundle含结果记录、R5和完整文件套件仍OPEN。
- Assumptions：同core上升沿、同步高有效共同rst；可暂停源；单JOB、单识别调用者、单STORE在途事务、单R3在途调用。core100MHz为预算假设，不是时序结果。
- Open questions：见A2；不把未运行工具本身当批准前设计缺口，不以未解决后端为由重新限定目标尺寸、数量、噪声或遮挡。
- Dependencies：唯一根v0.2；R2实际CS/全GRAD、精确闭包EDGE；R3 v0.2；CONTROL历史J/完整profile；REPLAY及VIEW桥的实际目录/返回实体；真实backend和R5。
- Milestones：整体B→模块C→接口D→局部E→三份映射F→场景G/追踪H→保存读回/独立审阅→闭合真实依赖/联合选择→整包明确批准→获批实施验证。
- Detailed steps / State transitions：见E；设计阶段仍LOCAL_DESIGN，任务运行候选IDLE→BIND→POINT→CIRCLE→LINE→RECT→VERIFY→SELECT→DRAW→COMMIT→CLOSE→TERM_HELD→GAP，错误走ABORT/CLOSE或QUARANTINE。
- Artifacts and hashes：仅新增本文；输入实际SHA见A1，本文最终SHA和字节数由实际全文读回报告，不写入自身内容。
- Validation：G的场景全NOT_RUN；文档算术/语义审查与仿真、数学、质量、综合、PNR、STA分别记证据。
- Failure handling：候选数值退化、启发式抽选、SEARCH_INCOMPLETE、真实CAPACITY、帧级数值/协议错误和未知关闭分开；已交付的旧承诺不因取消消失。
- Human approval gates：只获本纯设计文件创建/读回授权，没有实现批准；没有READY_FOR_REVIEW，不请求用户批准尚未成熟的整包。原工作副本、工具、数据库及人工硬件闸门仍有效。
- Rollback：只撤本候选的后续引用；原HDK、规则、旧稿、Manifest、正式状态和数据库保持。停止用户指定外部存储器件/PHY/校准/IP调查。
- Completion criteria：本轮完成保存、全文读回和可复核交接；批准前应冻结真实可综合后端架构、端口/容量、完整目录/文件/验证计划及性能方案，获批后才实现并取得工具证据。不能要求先写代码/跑综合才能批准设计。

## A. 状态、来源、范围和OPEN

任务ID TRACK4-ALGORITHM-R4-RECOGNITION-001；关联BATCH R4、R2 B03/B05及MOD-09。阅读顺序B整体→C职责/连线→D字段与交接→E人工步骤→F映射→G/H验证追踪→A/I门槛。没有Git commit，不伪造commit。

### A1. 实际来源与采用边界

| 实际文件 | SHA256 / 使用范围 |
|---|---|
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；设计/可理解性/批准边界 |
| [模板](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79；通用字段和A–L |
| [BATCH v0.3](design-TRACK4-ALGORITHM-BATCH-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7；整包五基础六高阶、完整分辨率与分批责任 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2；29268B，CS592/CLASS125/GRAD185、错误/源停止 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D；51448B，全文；622/585、single caller、kind0…18、独立最终诊断 |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107；51859B，全文；J657/历史配置/epoch与唯一分配者 |
| [REPLAY v0.2](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B；46304B，全文；SRC/finalEDGE/ANN完整资格、borrow/CLOSE/RELEASE |
| [VIEW-BRIDGE v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C；64477B，实际读回最新稿及逐项修订；CERT352 schema2、真实private_refs_retired、prejob屏障/返源、父引用/完整O和授权epoch候选 |
| [R4-CLOSURE v0.2](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11；63263B，实际读回最终稿；精确8邻域/完整EDGE/角色限定STORE与真实关闭 |
| [原NUMERIC](design-TRACK4-RECOGNITION-NUMERIC-001.md) | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A；纯POINT/CIRC/RECT/FINAL/PROFILE及LS/TLS表示；旧数值不一致处以R3为准 |
| [原ALGORITHMS](design-TRACK4-RECOGNITION-ALGORITHMS-001.md) | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB；32760B；anchors/rank、五遍/六遍、最终成员、排序、字形与独立质量目标 |
| [原EXECUTION](design-TRACK4-RECOGNITION-EXECUTION-001.md) | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178；45738B；纯分段/拟合/覆盖/栅格事件；不继承旧job4731/physical key/phase/grant/MC端口 |
| [闭包资源比较](../experiments/track4_algorithms_20261004/03_review/r4-closure-resource-comparison-v0.1.md) | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C；逻辑容量与实际片上资源分层，主机数组不是RAM |

控制面已按入口顺序实际读取AGENTS、运行提示、配置、状态/ledger、database说明、根v0.2、模板及审批Manifest。数据库NOT_CONFIGURED；本文不启用数据库、不登记审批。来源既有NOT_READY仍是候选，不把旧设计当实现事实。

### A2. 真实未决项

| OPEN | 缺口、影响与闭合责任 |
|---|---|
| R4R-B01 | 真实全N POINT/GRAD/ANN及工作表backend、端口/延迟/原子组/容量/packing/恢复未冻结；影响全部OBJ与生产资源。STORE/O设计者须给实际完整架构与资源映射，不能拿host数组、小图或Ti60 stub替代。 |
| R4R-B02 | 生产profile全部实值/默认与启发式、并行/串行DENSE、半径路线和可接受延迟的最终选择未冻结；需性能/资源/独立GT联合权衡，当前不承诺95%或fps。 |
| R4R-B03 | R2 fullGRAD收集/commit、POINT/O目录、实际全部私有refs返还、RECORD辅助结果登记及完整CERT1201/VIEW桥组合尚无实体；本文关闭会话pin不等对象退休。 |
| R4R-B04 | CONTROL旧packed JID/render命名澄清、recognition_id/call_seq生命周期、跨软件epoch授权及父取消/状态适配须合并；不从新job.epoch自授清旧credit。 |
| R4R-B05 | 完整文件/schema/独立数学和协议参考/GT manifest/runner/case/timeout与生产工程验证基线尚未形成；本页不关闭B05。 |
| R4R-B06 | R5生产源/固定视频、CDC/clock/pin/时序/全机资源/吞吐及真实bit工作仍OPEN；仅逻辑可暂停处理不证明连续摄像/视频速率。 |

每项均有设计证据缺口；只有获批后应执行的测试NOT_RUN不重复列作设计阻塞。当前允许纯设计完善/独立审阅，不改B03/B05/整包和正式状态。

## B. 整体外部行为

| REQ | 规则、来源及可观察结果 |
|---|---|
| R4R-REQ01 | 生产1920×1080，N2073600、P1036800；静态小图W偶数6…1920/H5…1080仅独立验证实例。POINT来自完整finalEDGE与同JID/尺寸/CFG的完整GRAD，class不能代finalEDGE，不缩图。 |
| R4R-REQ02 | 任意旋转圆/矩形、三边推断、重叠、负样本保留原要求；撤回的直径/短边/长宽比/数量/噪声/遮挡硬边界不恢复。候选表示域与启发式造成的FN须进入质量统计。 |
| R4R-REQ03 | 完整执行明确的anchor/rank/peak选择与每个入选候选的五遍圆/六遍TLS；主动选择是算法，有遗漏风险；容器溢出失败，预算未完SEARCH_INCOMPLETE失败。不能把前缀当完成全部搜索。 |
| R4R-REQ04 | 最终量化几何冻结后，以同一POINT谓词重算eligible/support/SSE/coverage、独立kind17/18诊断，不再次改变几何；比例/距离/覆盖门用全宽精确比较。 |
| R4R-REQ05 | 所有实际候选核验完、稳定排序/精确去重完才冻结FINAL；最多64是逻辑输出容器容量，第65独立keeper使整帧CAPACITY，不能限制测试为64目标或截断成功。 |
| R4R-REQ06 | 生成全N ANN2，包括零目标全0；64条RECORD512中前F有效、其余0。POINT/ANN/RECORD提交须真实完整，终态held；ANN00透明/01圆/10矩形/11文字或异类相交。 |
| R4R-REQ07 | 唯一coordinator、独立OBJ和R3事务/关闭、真实ledger及cancel；wrong echo不释放他人对象/credit，held原结果仍消费，未知关闭保留引用且QUARANTINE。 |
| R4R-REQ08 | RC_COMPLETE只证明本局部；完整bundle还需真实原SRC、R2及精确闭包EDGE、完整profile、全部子终态/封存/目录返还和O资格。REF/TOKEN/flag不创造已有存储或权限。 |
| R4R-REQ09 | 独立每类P/R≥95%，同类半开bbox IoU≥0.5最大基数一对一；失败帧GT记FN，负样本FP、重复、错类保留，不能从观察结果删难例。 |

输入触发是父J实际拥有的一次合法RJ fire。输出是只读完整POINT中间对象、本次最终ANN与结果记录、独立RC_TERM；中间表均私有。局部成功只表示该确定算法选择完成，不是数学穷举全部潜在目标，也不是95%质量已通过。数值LOCAL_REJECT或几何域外候选是局部拒绝，继续实际循环；缺对象、协议/溢出、表满是整帧失败。SEARCH_INCOMPLETE显示预算未评估候选而不发布ANN。

正常：锁完整J/profile→核finalEDGE/GRAD真实commit→N扫描建立E条POINT→完成全部anchors/rank选256→五遍圆→全部512θ直线→全部coarse/fine/PAIR及预算内矩形循环→冻结几何核验→排序/去重→全ANN/64记录→实际commit→OBJ真CLOSE与R3 quiet→RC_TERM COMPLETE→父O核完整bundle。没有目标：E0仍各阶段空循环完成、ANN全0与64零记录提交、F0可成功，不返回NULL图。

边界：整条短边缺失按三边路线推断，不新设形状尺度或遮挡门；同像素U形和三边矩形可能不可区分，U形误识别计FP，不声称理论保证。任意重叠保留独立几何/支撑，异类不互删。永久不ready只能保持未完成；合法可暂停生产边界、真实有限时延计划和质量分布仍A2。

## C. 模块、唯一owner与完整连接

| MOD | 职责 / owner / 边界 |
|---|---|
| R4R-J 父JOB | 唯一J657/history、recognition_id分配、RC_TERM接收及与CS/CL_TERM/SRC/目录汇合；不第二次写内部POINT或R3状态。 |
| R4R-O 真实对象目录 | 唯一分配/注册/借用/返回/退休全部ref与版本、授RECOGNITION角色访问pin；实际全图及表backend OPEN，不用裸数字冒权限。 |
| R4R-C 协调器 | 唯一状态推进、锁RJ、OBJ tx_seq、NUM call_seq、候选/诊断/错误/终态；普通算法与取消收尾分开，不能代STORE/O闭合效果。 |
| R4R-P POINT构造/扫描 | 顺序读全N EDGE/GRAD，写E条POINT与真实commit；所有后续点遍只读该不可变POINT；不借初始CLASS。 |
| R4R-S 支撑/种子/拟合 | anchors/rank/半径峰、DENSE/分段、五遍圆/六遍TLS/矩形组合；coordinator调用唯一R3，不存在其它数值owner。 |
| R4R-V 核验/选择 | 冻结几何POINT遍、覆盖、kind17/18最终诊断、VC稳定排序/精确去重与FINAL；不重拟合后改geometry。 |
| R4R-A ANN/记录 | 只读冻结FINAL、行内栅格/字体合并、全N显式ANN和64完整记录；不借live RGB tap，不发布部分图。 |
| R4R-STORE | 有界、可暂停逻辑对象读取/完整写/组RMW/封存/commit/独立CLOSE；只结本角色会话pin，不拥有O最终图生命周期。 |
| R3 唯一数值实例 | 复用实际v0.2设计622/585及ROM/宽运算/quiet；owner0单caller，不继承旧543/540、font ROM或shared phase。 |

数据：父J→IF01 RJ→IF02 BIND→IF03 EDGE/GRAD/POINT与表→P/S→IF05 NUM→S/V→IF06 FINAL→A→IF03 ANN/RECORD commits→IF04 CLOSE→IF08 TERM→父J→IF09 O/private returns/fullbundle→VIEW/REPLAY。配置只有RJ所锁J/profile；错误由各真实接口fire→C首次原因/mask→ABORT→独立收尾，不从最新C重新造身份。

所有逻辑对象保守分开分配，D7列容量，没有旧phase池切换或免费别名。workspace_ref只是当前H绑定的真实子表集合授权索引，其对象编码各有独立容量/版本；不隐含一块无限memory。POINT构造封存后不可写，FINAL冻结后不可写；其它scratch只有本协调器且stage允许读写。全组读/写/封存效果明确完成才推进下一成员/阶段，不以request fire当write_done。

所有正常rq/NUM只各一个在途；真实source response能暂停，接收槽独立于新业务ready。ABORT停止尚未提出的新算法请求，但旧held rq/NUM及已发表response履约；CLOSE不等待未知semantic credit先清，避免错echo造成环。接口实体和组合未合并仍A2，整体检查点为B/C/D可读后才看E细节。

## D. 接口、表示与组合检查

### D1. 公共身份、fire和序号

新消息字段按本文列出的**高到低**排列；嵌套CONTROL J657和R3原消息内部位序保持来源。新JID96采用命名epoch32/frame32/config32恢复并按REPLAY编码（epoch低32/config高32）；CONTROL packed澄清仍B04，禁止裸cast。H160=JID96/recognition_id64，namespace固定RECOGNITION；不能据同宽H160关闭LOAD/CLOSURE或REPLAY borrow。

recognition_id由父J唯一每授权epoch next0分配，最大号合法一次、随后exhausted、扩65bit不回绕；同JID只允许一次RC invocation，重复/换body不重启。C保存当前JID及父已退役高水位，接受新J须父真实授权/目录pin，不能凭输入epoch变化清旧事务。OBJ tx_seq64从0逐提议消耗；NUM call_seq64由单caller对当前JID从0分配、purpose destination8显式保存，accepted/cancel/LOCAL_REJECT均不重用。同JID重试不能复位call_seq；下一J/软件epoch资格来自真实父退休/授权，跨软件epoch具体桥须合并B04。

计数每次实际事件先扩1bit检查。最后合法最大值可使用，下一分配明确EXHAUSTED，不回绕、不饱和继续成功；已held收尾独立进行。冷合法全参与者共同rst fire0并隔离旧run；软件reset不能直接清内存、credit、NUM private pending或O refs。

每口fire=沿前valid且ready且非rst。新capture沿不穿透形成下游fire；data/身份/sideband一旦published保持至真实fire。取消/新错误与旧fire同沿，先结旧fire，再注册sticky；下一旧ABORT周期停新提议。无效valid0既不推进计数也不当零值。状态源和慢观察器无第二writer。

### D2. 外部端口及body

| IF | body、方向 | 前置、保证、保持与失败 |
|---|---|---|
| IF01 RC_JOB | J→C；RJ2257=J657/recognition_id64/edge_ref64/edge_commit64/grad_ref64/grad_commit64/point_build_ref64/workspace_ref64/ann_build_ref64/record_build_ref64/PROFILE1024 | 单槽IDLE、term空、父真实授权/对象容量可预检；accept锁完整body，不创造read/write权限，随后真实BIND。合法接受与cancel同沿先登记，后续ABORT。无ready则父保持；没有复用旧917/4731 job。 |
| IF02 RC_BIND | C→O，全文RJ2257保持；O→C RB184=H160/status2/reason6/bound_mask16 | success0/reason0且低十位全1/高6零；依次source元数据、EDGE、GRAD、POINTbuild、workspace、ANNbuild、RECORDbuild、profile、角色排他、身份/commit核实。failure1/合法非0/mask0且真实无pin。其它组合非法；错echo不能根据陌生ref返还。 |
| IF03 OBJ | C↔STORE；KEY287=H160/tx_seq64/op5/object5/index32/length21；RQ799=KEY287/payload512；RSP872=原KEY287/status2/reason6/value512/commit_token64/effect_ok1 | 单expected credit、独立rq/rsp槽；逐对象/操作范围与stage权限在寻址前校验，完整record或组效果结束才success。错echo计raw并帧失败，不结expected；fields/reserved检见D3。 |
| IF04 OBJ_CLOSE | C→STORE CLOSE295=H160/request_cutoff64/last_valid1/last_seq64/first_reason6；ACK504=原295/request64/raw_response64/source_settled64/overflow3/closed6/status2/reason6 | 独立于IF03新rq credit，H/截止/实际ledger/真实读写/held响应/pins证书见D4；不误用闭包294/502的reason5，也不释放O对象。 |
| IF05 NUM | C↔R3；原REQ622/RESP585、matching cancel/quiet | 精确采用R3 v0.2，owner0单caller；ID176完整匹配，不将NUM call_seq等OBJ seq/geometry id；held旧结果照常消费，应用与discard分开，见D5。 |
| IF06 FINAL | V→A私有sealed通知；H160/F7/final_version64=231 | 仅全部实际VC核验/选择/去重与FINAL真实SEAL完成后提出，F0合法；geometry/指标从此不可写。通知held且A读取的version逐项相等，错身份失败无图发布。 |
| IF07 CANCEL | J→C H160；ACK168=原H160/status2/reason6 | status0APPLIED/1ALREADY reason0，2NO_MATCH reason2，3REJECTED合法非0；receipt不等TERM/CLOSE，独立槽。只能锁当前已接JOB，IDLE新JOB同沿不被旧cancel误取消。 |
| IF08 RC_TERM | C→J TERM2606，见D6 | 完整终态slot held；J只消费/检查一次真实原body，不自造success。成功/失败drained/Q矩阵、真实前缀和pins保存见D6。 |
| IF09 O退休/bundle | 父J/O/STORE/provider目录；当前文字合同，不宣称有已冻结消息body | 真实私有refs清单、immutable结果与完整证书见D8；现行VIEW CERT352/COMMIT1201不能由本页flags自填。实际目录返还与RECORD辅助结果消息/容量仍B03。 |

### D3. OBJ操作、值域和私有表

status只0成功/1失败；失败reason1…20合法非0，2/3非法。success reason0/effect_ok1，失败value512/token64/effect_ok全0；failure不证明此前内部效果未发生，恢复依据真实STORE关闭。READ返回canonical record低位有效、高位零，WRITE/CLEAR/DENSE_ADD返回value0；只有SEAL/COMMIT返回真实非0token，其它token0。

op0 READ_ITEM：length1、payload0，index在该表真实有效前缀或全图范围，不能读未初始化洞。op1 WRITE_ITEM：length1、完整canonical record低位及高padding0、index在容量/当前stage授权；原子可见后响应。op2 CLEAR_TABLE：index0/length=全表容量/payload0，逐真实位置归零并关闭pending后success；取消不能冒称CLEAR完成。op3 SEAL_TABLE：index0/length=真实valid_count/payload0，核所有完整写/zero padding/无pending并冻结该stage version，valid_count0允许；不是不可变全帧提交。op4 COMMIT_RESULT：只POINT lengthE、ANN lengthN、RECORD length64，index0；RECORD payload低7为F、高505零，其它payload0；真实全前缀及未用记录零/全N坐标覆盖成立后给immutable commit token。op5 DENSE_ADD：index=(batch5左移21)加point_ordinal21、length16，payload低144位按θlane0…15各r9、高368零；STORE核batch0…31、已commitPOINT ordinal<E、每r合法0…276及一次性组接纳，16个同point的计数latest更新全部结束才success。op6…31非法。

STORE的DENSE_ADD可串行完成16次实际RMW，逻辑原子组在处理期间排除其他读/封存；内部做了一部分后失败/取消也须真实effects settle才CLOSE，不承诺rollback。latest/forward或排他串行保护同地址连续票，计数上限E21；1R1W不能凭逻辑16lane当16物理读口。原点已accepted事务的cutoff按KEY/真实rq，不靠payload坐标寻址。

object5编码固定0EDGE、1GRAD、2POINT、3ANCHOR、4SEED、5HIST、6RAW_PEAK、7SMOOTH_PEAK、8DENSE、9NMS、10LINE、11CELL、12EXT、13SEG、14PAIR、15CIRC、16RECT、17VC、18COVER、19FINAL、20DRAW、21ANN、22RECORD、23COVER_META、24CIRCLE_CTX、25FIT_STATS；26…31非法。全图0/1只读；2构造期写/commit后只读；21/22末期写/commit后只读；其它各stage权限C/O保存，不由caller自称。index是该表item序号，非物理byte/RAM地址；例如COVER 0…16383、NMS0…1107、SEG0…1023各自不同，不用统一xy谓词错误拒绝合法后半表。

POINT64低到高x11/y11/Gx s11/Gy s11/dir2/θ9/zero9；x<W,y<H，G范围±1020、|Gx|+|Gy|≤1530，高GRAD8/POINT9零，EDGE1且非零G才构造；finalEDGE1但零G是输入不一致帧失败，不静默删除。θ由kind8完整梯度量化，dir2继续保留R2语义，不能当θ高位。

其余记录按下表**低到高**；该表是payload内部schema，和外部高到低消息规则区分。

| record | 全部字段、编码及单位 |
|---|---|
| ANCHOR64 / SEED128 | ANCHOR为完整POINT64；SEED key53/rank64/valid1/zero10，key高到低biased_cx18/biased_cy18/r17，bias131072。 |
| HIST/DENSE/NMS21；PEAK64；LINE64 | 票数uint21；PEAK radius17/raw_count21/window_count21/kind2/zero3，kind0RAW/1SMOOTH；LINE θ9/rho_bin9/votes21/flags2/zero23，flags当前0。 |
| CELL48 / EXT80 | CELL原count21/submin4/submax4/valid1/zero2加submask16；EXT原count21/old_count21/submin4/submax4/valid1/zero13加submask16。mask为本格16个实际Q4投影子位置；min/max与mask非零一致。不是只存极值假设中间占满。 |
| SEG384 | 低128 coarse=peak_id10/θ9/rho9/offset s6/tlo s18/thi s18/n21/occupied12/maxgap18/flags7；高256 fine=nx s32/ny s32/rho s18/tlo s18/thi s18/n21/Sx s33/Sy s33/anis16/occupied12/maxgap18/flags5。coarse flags端点censored bit0/1、offset边界bit2，余0；fine state低2（0PENDING/1VALID/2REJECTED，3非法），censored bit2/3、bit4零。REJECTED fine数值字段零、coarse保留。 |
| PAIR64 | s0_id10/s1_id10/diagnosticθ9/zero35；s0<s1，不重复段；θ较强support、同票低id，仅诊断。 |
| CIRC256 | seed_id13/flags4/cx s18/cy s18/r17/support21/eligible21/sector64/SSE53/score16/zero11；seed0…255高5零。flags0圆心图外/1bbox跨图/2混合梯度极性/3零，不因极性混合自动拒绝。 |
| RECT512 | kind2/flags4/parent_pair9/四segment_id10/present4/八vertex s18/四support21/四eligible21/score16/SSE53/四maxres16/zero8；kind0四边/present1111、kind1三边/popcount3，缺段id0但仍四顶点；kind2/3非法。flags0跨图/1推断与kind1一致/其余0。 |
| VC400 | geometry144/flags4/score16/support21/eligible21/SSE53/coverage64/maxres16/fit_support21/seed13/fit_quality16/state2/zero9；圆geometry低cx18/cy18/r17余91零，矩形八vertex18；flags采用FINAL低3位的跨图/推断/圆混合极性规范，高1零，不直接copy含圆心图外位的CIRC flags。state0未核/1拒绝/2待选择/3已消费。global gid圆0…1023、矩形1024…2047。 |
| FINAL512 / RECORD512 | common96=class2（1圆2矩形）/flags6/proposal10/score16/support21/eligible21/zero20；geometry192=bbox44/union148（圆cx18/cy18/r17/zero95，矩形vertex144/zero4）；metrics224=coverage64/SSE53/maxres16/fit_support21/source_seed13/fit_quality16/zero41。RECORD为FINAL完整copy，未用entry全0，class0仅未用。 |
| DRAW80 | bbox44（四uint11半开）/label_x11/label_y11/charlen3/clip1/zero10；仅图内绘制范围，geometry不clip。 |
| COVER_META320 | Ax s18/Ay s18/dx s19/dy s19/K39/lo_n19/lo_d19/hi_n19/hi_d19/j_base15/j_last15/span13/O13/b0_1/b1_1/coverage16/visible1/required1/zero55；正den，λ∈[0,1]。 |
| CIRCLE_CTX384 / FIT_STATS263 | ctx=c0x18/c0y18/r0_17/c1x18/c1y18/r1_17/c2x18/c2y18/r2_17/nA21/nC21/seed8/peak9/route1/pass3/valid1/zero161；x/y signedQ4，半径uintQ4，route0RAW/1SMOOTH。FIT由锁定stage解释：LS263；TLS217+zero46；radius sum39/n21+zero203。未初始化不读，不隐含另存无限成员列表。 |

所有中心/角点signed18 Q4格式域[-8192,8191.9375]px、r uint17 Q4正域1…131071；是表示域，不是场景 admission边界，域外候选局部拒绝并诊断/FN，不饱和/裁几何成功。bbox低到高xmin11/ymin11/xmax11/ymax11；min=clip(floor(extent/16),0,W/H)，max=clip(floor(extent/16)+1,0,W/H)，0≤min<max≤W/H，空bbox拒绝。FINAL flags bit0跨图/bit1三边推断/bit2圆混合极性、其余0；source_seed圆seed ordinal0…255高5零/矩形pair0…511高4零，不能套同域。

### D4. 真实CLOSE与bad echo

OBJ request_count只在真实RQ fire增加；raw_response只在真实RSP fire增加，包括坏body；success_response只完整合法成功fire增加；source_settled仅正确CLOSE_ACK中真实STORE事件证书得到，不等good/received。正确reply结semantic credit并存独立rspslot；只有旧slot空才创建下一rq，同一seq不重提。

bad RR/RSP不能据错echo判属他人并释放。它计raw、锁OBJ_PROTOCOL；保留expected credit/key、不应用value/token。ABORT即使credit仍1也允许提出独立CLOSE295（兑现old held rq后锁cutoff，last_valid=count>0，last_seq为最后真实accepted seq而非最后good）。STORE CLOSE只等本H已accepted请求、实际read/write/RMW/held回复效果排空及本角色访问pin收尾；不等C消费者把坏echo猜成匹配后先清credit。已held RSP真实fire必须先于后续CLOSE_ACK，ACK不与末response同沿凭新empty形成。

正确完整ACK必须全文echo H/cutoff/last_valid/lastseq/firstreason，request=cutoff、raw_response等C实测raw、source_settled=request、overflow3全0、closed6全1（request/read/write/response/access_pins/closed），status0/reason0仅会话真实无错误，status1/合法非0为实际失败但相同closed证书仍可结clear原credit。证书只结束该H会话义务，不把坏response变成功，不给ANN发布资格，不返他人borrow/O对象。错ACK、raw count矛盾、effects未知或closed位缺失均Q：保留pin/ref与expected元数据，不能timeout置closed。CLOSE.first_reason是请求snapshot，ACK suffix reason是实际来源结果，两个reason独立。

### D5. 唯一R3调用者与取消/quiet

NUM_ID176原低位顺序epoch32/frame32/config32/owner8/call_seq64/destination8；REQ622=ID176/WH22/numeric_version8/kind5/signed_flags2/result_bits9/payload400（内部仍R3低位顺序）；RESP585=ID176/kind5/result_bits9/outcome2/reason8/value385。numeric_version1、owner0、purpose destination完整保存；R3当前只有一个caller，C在系数、角度、拟合、距离/coverage/栅格之间串行仲裁，不让16θ或4侧各自冒充一个R3 owner。

call purpose分组：0构POINT角；1圆seed；2圆LS；3半径；4径向角；5DENSE系数；6TLS；7矩形交点；8有限边/距离；9圆最终diagnostic；10矩形最终diagnostic；11coverage宽乘/比较；12raster floorroot。purpose固定在同JID调用内并核resp，不据当前state重建expected。

kind8梯度θ9、kind9径向量θu10/half/fullbin10/sector6，retain512进位；kind10投影；kind11 LS值只中心，不半径；kind12 TLS effective278+zero107；kind13交点、14归一化线距、15有限边分数、16Q15系数；kind17从最终LS263只n/quality、kind18从最终TLS217只n/anis，无新几何。宽MUL/ADD/SUB/DIV/SQRT/COMPARE依kind0…7调用，result_bits/signed flags/高zero逐种类核，不伪造定点误差允许。

RESP VALUE outcome0/reason0，LOCAL_REJECT1/FRAME_FAIL2各合法1…13且value0，CANCEL_DROP3/reason0/value0。LOCAL_REJECT只拒当前几何候选，local_reject计数；FRAME_FAIL整帧错误；cancel后VALUE已published不可改DROP，C照常fire保存原body但独立DISCARD不应用。首次帧级NUM失败保存raw outcome/reason/kind/seq，不被后续cancel覆盖。

每次held请求沿前snapshot直到NUM reqfire；reqfire后R3最早后续执行/结果，C真实rspfire完整校验并存槽，下一旧VALIDATE_RESULT沿才应用；rspfire同沿不能发下一NUM。匹配cancel不能撤held NUMREQ：先兑现，旧call_active后发matching cancel，消费原heldVALUE或DROP，随后等R3旧QUIET=1且无private scalar/ROM/resultpending。本地响应槽/应用槽也空才numeric_quiet真；quiet不返OBJ/O pin。

wrong NUMRESP独立raw++/NUM_PROTOCOL、不清expected或使用值；继续履约published responses并取消expected。R3 quiet只证明私有执行关闭，不证明错ID响应属于当前caller；缺真实关联证明不能自行结semantic expected，进入NUM_QUARANTINE/drained0。当前R3没有可冒用的CLOSE证书，恢复/隔离关联适配仍B04；不能靠reset、相同低call_seq或discard所有body自动闭合。

### D6. TERM2606与终态规范

TERM高到低：H160/status2/first_reason6/error_mask64/first_loc191/flags16/counts122/diagnostics1024/IO256/NUM384/tokens192/overflow36/first_NUM80/first_IO73=2606bit。

loc191=kind3/stage4/lane1/point_ordinal21/raw_xy22/proposal12/call_seq64/io_seq64。kind0全0；kind1点（ordinal/xy/lane有效）、kind2候选（proposal有效）、kind3NUM（callseq有效）、kind4OBJ（ioseq有效），stage0…9分别BIND/POINT/SEED/CIRCLE/LINE/SEG/RECT/VERIFY/DRAW/CLOSE；其余非法，未适用字段0。rawxy只是证据，不能形成地址。first_loc与first_reason首次错误沿锁定，mask后续真实错误继续OR；同沿新故障优先非法CANCEL协议、OBJ、NUM、输入格式、内部不变量，正常匹配cancel仅在该沿无故障且无旧first_reason时锁reason16，旧fire已经记录的效果不抹掉。

reason6新namespace：0NONE、1DESCRIPTOR、2BINDING、3PROFILE、4INPUT、5POINT_PROTOCOL、6OBJ_PROTOCOL、7OBJ_FAILED、8NUM_PROTOCOL、9NUM_FAILED、10INVARIANT、11CAPACITY、12SEARCH_INCOMPLETE、13OUTPUT_FORMAT、14COMMIT、15CLOSE、16CANCEL、17OVERFLOW、18EXHAUSTED、19UNSUPPORTED、20CONTROLLER；21…63非法。mask bit j对应原因j、bit0/21…63规范0，不把reason写入R3 reason8或VIEW reason5。

counts低位依次E21/line11/segment11/pair10/circ11/rect11/VC12/FINAL7/ANN_pixel21/RECORD_entry7，合122。诊断16×uint64：anchor_kept、anchor_pruned、anchor_pairs_visited、legal_seed_occurrences、seed_selected、seed_duplicate_occurrences、seed_rank_pruned、seed_rank_replaced、circle_fit_attempts、rect_verify_attempts、local_rejects、geom_domain_rejects、budget_limit、budget_used、unassessed_min、point_passes。选种子的事件不冒充distinct被漏目标数；unassessed_min在预算触顶仍有下一个合法组装候选时至少1，其它真实未评估剩余只给下界，不凭估计伪精确总量。

IO四个uint64=request/raw_response/success_response/source_settled；NUM六个=request/raw_response/VALUE/LOCAL_REJECT/FRAME_FAIL/CANCEL_DISCARD。CANCEL_DISCARD记录原VALUE/LOCAL/FRAME/DROP中实际因旧cancel不应用的raw响应，和VALUE/LOCAL/FRAME互斥分桶：取消后的已heldVALUE计DISCARD，不同时再计VALUE。tokens低到高POINT/ANN/RECORD各64。overflow36低位依次10counts、16diagnostics、4IO、6NUM；每位仅该累加器临时超域事件，保留最后真实可表示值，整帧失败而不回绕。first_NUM80=valid1/outcome2/reason8/kind5/callseq64；first_IO73=valid1/status2/reason6/txseq64，不适用全部0；只存首次帧级失败/协议原证据，不把正常LOCAL_REJECT当整帧first_reason。first_NUM/IO的raw字段可保留对方非法编码作证据，不能据该raw reason解释成本稿first_reason或解除credit。

flags bit0…15依次bound、point_committed、circle_selected_done、line_done、rect_selected_done、verify_done、final_frozen、ann_committed、records_committed、io_closed、numeric_quiet、access_pins_closed、local_empty、drained、search_exhausted、cancel_seen。

| status | 必须的规范与真实证据 |
|---|---|
| 0 COMPLETE | first_reason/mask/loc/overflow全0，flags0…13全1/14…15零；所有选择定义循环真的完成、没有未评估预算候选；E≤N/F≤64、ANN=N/RECORD=64，三token真实非0；IO request=raw=success=settled、NUM request=raw=VALUE+LOCAL_REJECT，FRAME_FAIL/DISCARD0；每口semantic credit/held/应用/pending空且正确CLOSE和旧quiet证据。point/ANN/record及FINAL版本完整，不是仅status0。 |
| 1 FAILED_DRAINED | reason合法非0/mask包含其位，原counts/ledger/diag/tokens各自真实前缀，不强令相等；flags9…13真及实际close/quiet/localempty，已commit事实保留但没有发布资格；SEARCH_INCOMPLETE时flag14真、unassessed_min≥1、所有已产生前缀仍不发布。 |
| 2 CANCELLED_DRAINED | 首次仅cancel时reason16/mask16/flags15真；若已先真实失败则保留更早reason并报FAILED；旧fire/合法token不能擦去；真实CLOSE、NUM结果消费/quiet及本地空、访问pins关闭成立。无完整图义务，不伪N/EOF成功。 |
| 3 QUARANTINE | reason合法、flags13=0，未知credit/close/NUM关联/O pin不清；仅履约完已经published本地请求/响应/通知后才能形成冻结Q通知，没有新的业务提议。Q通知消费不退refs、不允许新JOB/epoch；晚消息不自动改终态/释放对象，恢复另设计。 |

尚未获BIND且真实明确拒绝无pin，FAILED可drained1/IO0/NUM0/token0，io_closed/access_pins_closed/numeric_quiet由真实never_started/no-grant事实，不等待不存在CLOSE。错BIND echo不能当no-grant，走未知绑定证明/Q。LOCAL_REJECT继续算法，若最后全部候选拒绝可F0 COMPLETE，但质量FP/FN另检查。

### D7. 逻辑容量、padding及资源界限

下列是完整逻辑容器，按每表ceil(bits/8)分别计。有效前缀以实际count/version限定，不读未用洞；仅ANN全N和RECORD全64要求全部显式canonical写。服务item以record为单位，物理bank/word/address/byte packing须B01，不把index32当内存地址。

| object | items×bit / byte | owner/生命周期 |
|---|---|---|
| POINT | N×64 /16588800 | O分配build，P写E并commit后全局只读；本RC所有遍直到CLOSE，private退休前真实返还 |
| ANCHOR / SEED | 768×64/6144；256×128/4096 | C/STORE；完整anchors→入选seed frozen，圆阶段结束后才可目录返还 |
| HIST / RAW+SMOOTH | 8192×21/21504；2×512×64/8192 | 当前中心/全部tile与峰构造期间pin；RAW或SMOOTH第513峰CAPACITY |
| DENSE / NMS / LINE | 4432×21/11634；1108×21/2909；1024×64/8192 | 16θ×277票，4×277快照；全512θ完成、全部peak/段引用结束才可返 |
| CELL / EXT / SEG / PAIR | 8192×48/49152；4096×80/40960；1024×384/49152；512×64/4096 | 两独立CELL、一个EXT；全coarse→六遍fine→全部矩形引用结束，不免费互覆盖 |
| CIRC / RECT / VC | 1024×256/32768；1024×512/65536；2048×400/102400 | 真表容量，不是场景目标数上限；最后一个完整写后count++，第1025/2049失败 |
| COVER / COVER_META | 4×4096×1/2048；4×320/160 | 一候选四侧，可清完/全部旧读写settle后下一候选复用；非真实长度的点数proxy |
| FINAL / DRAW | 64×512/4096；64×80/640 | private最终keeper；全部选择完成才freeze；DRAW必须完整F记录后才能画 |
| CIRCLE_CTX / FIT_STATS | 16×384/768；16×263/526 | 圆16lane状态/统计表，stage类型明确；矩形四TLS217临时寄存器另计 |
| ANN / RECORD | N×2/518400；64×512/4096 | 真输出对象，全N/64写/commit，无目标亦全0；完成后O接immutable所有权 |

总17,526,269byte，不含对齐/目录/事务journal/STORE内部pending、当前行W×2（最大3840bit=480B）、字体ROM、R3或SRC/GRAD/EDGE。保守不作stage alias；NMS23,268bit末byte高4零、其它各表末byte按本schema高padding0。读/写512payload的记录高位零和物理packed末byte零分别验证，不据hex数字数忽略高pad。

额外完整GRAD32N=8,294,400B、原SRC24N=6,220,800B、finalEDGE1N=259,200B；闭包CLASS/QUEUE/EDGE逻辑9,072,000B另列，EDGE共用同一真实object时只算一次且必须明确生命周期。主机标准库数组提供软件reference空间不表示Ti60片上可容纳。没有继承旧105/225RAM、旧物理散桶SORTED第二POINT、旧32DSP或29168FF已兑现承诺。

外部body hex高padding：RJ2257为565digit/3bit；RB184为46/0；KEY287为72/1；RQ799为200/1；RSP872为218/0；CLOSE295为74/1；ACK504为126/0；FINAL_NOTICE231为58/1；CANCEL160为40/0、ACK168为42/0；TERM2606为652/2；R3 REQ622为156/2、RESP585为147/3；所有高padding必须0，schema版本分开。

### D8. 与CS/闭包、私有refs及完整O的组合

POINT的EDGE只可来源完整精确闭包CL_TERM COMPLETE及有效EDGE_COMMIT/CLOSE；CS592 reason0或class强弱统计不能代此证据。R2 fullGRAD185流两lane各32与sideband121必须真实逐坐标收集并封存N，CS是parent唯一消费，RC不接第二份CS改写parent状态。GENERAL闭包会把原CLASS01/10改11，识别不能借initial CLASS或假设有副本。GRAD仍有dir2/高8zero，C0 ARM stream_started和raw CS字段的不同语义由原parent适配，不再冒写SEAL863。

O唯一拥有注册及对象销毁目录。真实分配清单分三族：①输出保留族SRC/EDGE/ANN及仍被历史CFG引用的完整immutable profile；②本稿辅助结果RECORD及其token/F（供人工观察/软件记录），须新增O auxiliary-result注册/读取/返还合同，现行VIEW COMMIT1201没有该字段，不默认涵盖，B03 OPEN；③私有族CLASS/QUEUE/GRAD/POINT、workspace下3…20/23…25全部实际scratch对象（ANCHOR/SEED/HIST/RAW/SMOOTH/DENSE/NMS/LINE/CELL/EXT/SEG/PAIR/CIRC/RECT/VC/COVER/FINAL/DRAW/COVER_META/CIRCLE_CTX/FIT_STATS）及真实STORE可能另分配的journal/pending backing。每个实际ref/版本/角色/目录owner均列真实allocation ledger，未分配只用真实absence，不用输入0猜没有。

RC_CLOSE只结束RECOGNITION access pin；CL_TERM backend_closed/drained只结束CLOSURE access pin；都不代表这些私有对象已经回收。父J不第二次free，O核所有所有者的真实读/写/NUM/copy/held effects关闭和refs/借用归还，执行目录退休并保留证据。POINT commit也不自动转成永久输出，RC消费结束后仍须实际私有目录返还。RECORD为aux输出的最终选择/保留容量与返还实体未冻结，不能偷偷把它当私有删除又声称完整详细结果可观察；其责任明确B03。

完整RC bundle资格：同JID/source尺寸/CFG/profile，完整原RGB SRC封存，R2 raw CS经唯一parent核规范，精确闭包finalEDGE全N/固定点/真term/close，真实fullGRAD到POINT和RC COMPLETE，全N ANN token、完整记录及实际辅助结果登记，所有私有refs真归还退休。VIEW最新CERT352 schema2的private_refs_retired必须由O实际目录证据得到；不能根据RC flag11 access_pins_closed自填1。实际O接口/RECORD辅助结果和各provider返回未合并时，只能候选合同，不生成COMMIT或假READY。

source_handle/source_image_id/result_id/render_generation/display_id/plan_id/borrow/parent-ref各owner/namespace按VIEW/REPLAY；裸ref/token不blindcast。REPLAY required SRC/finalEDGE/ANN同图同J/result/实际immutable资格才OPEN，即使当前display mode不读EDGE也不能弱化处理完整性；零目标ANN仍全N0。liveRGBtap不是可暂停replay源，没有隐藏免费帧存储。

## E. 局部中文操作草图与不变量

### E0. 状态、初值及共同逐沿规则

初始无H/currentjob/expectedcredit，所有published valid0，表有效性由本run版本隔离而非整阵功能reset；计数/diag0，seq next0且独立exhausted0。C为状态、所有ledger、context唯一writer；STORE为实际effects与source ledger唯一writer；O为生命周期唯一writer。重要不变量：INV01完整J/profile/objects pin；INV02每遍每点至多一次、support≤eligible≤E≤N；INV03所有扩位/高zero检查先于收窄；INV04先旧fire再cancel/错误，held不抹；INV05同key rq只一次且rsp槽消费后才下一rq；INV06固定geometry确定membership/coverage/diagnostic/dedup；INV07所有已selected循环完成或失败，不发布prefix；INV08只有真实commit/close/quiet/退休证据赋资格。

e0旧IDLE接受RJ只存body→e1检查完整历史J/schema/profile与O实际准备→建立RB访问pin后后续POINT；旧rsp在e2 fire存槽、e3按旧expected校验/选择应用或discard、e4后才下一rq。CLOSE/TERM不在末write/NUMrsp同沿用新empty提前形成；末ACK fire记录真实关闭，后续旧all_closed/localempty才freeze term。CANCEL同沿末ANN commit fire时保留实际token，但随后失去publish资格。表中真实旧count先判满再新增，count只有完整效果success之后推进。

### E1. 读取全N与POINT提交

1. 接BIND成功后遍历本地linear q0…N−1，按本地W受限游标生成x/y；顺序读EDGE[q]、GRAD[q]，每个response完整核KEY/schema；payload xy不是地址来源。所有N位置至少各一次，不先用strong_count跳过。
2. EDGE0只检查canonical GRAD并推进q；EDGE1要求非零G且R2域合法，调用kind8取得θ、保存POINT64。POINT index=旧E，先核E<N；真实完整写成功才E++。同沿cancel照常记已fire/效果，下一旧ABORT不创建新点。
3. N完成且全部读/写/NUM义务空，COMMIT_POINT index0/lengthE/payload0；真实token锁point_committed。未用POINT capacity不读取，valid前缀0…E−1不可变；E0合法仍真实COMMIT，不造token。
4. 每个后续POINT遍从ordinal0到E−1，不依scatter/sorted表、不借live输入；严格rowmajor原x/y递增，重复/乱序/错G/高zero错误是POINT_PROTOCOL，不能重复计票。pass结束包括末读slot/NUM/表写完成才point_passes++。

### E2. 启发式anchor/rank与完整被选中心路线

1. 扫全E POINT。空间桶floor(8x/W)、floor(6y/H)，角桶θ右移6，共384桶，每桶保留rank最小两点，总≤768。i=yW+x：xor右移11，乘109加37取低21，xor右移7；奇乘/xor为21bit置换，rank相同仅相同i。真实读旧桶记录、比较、完整写后推进，不假定原SORTED第二N×64副本。E−anchor_kept为明确算法抽选数，不是丢事务。
2. 按桶/slot顺序压紧anchors，遍历全部a<b，最多294528对。梯度法线交点：D=cross(G1,G2)、T=cross(P2−P1,G2)，P为Q4；D非0且D²×65535²≥1024²×|G1|²|G2|²。中心各坐标RNE((P1D+G1T)/D)一次；先正den/全宽再s18。两个距离各RNE sqrt得到r17，半径差≤128Q4、平均一次RNE；超格式域局部geom_domain_reject，不裁中心/半径。只入合法非零半径key。
3. key53的rank64：xor右移23、乘4296015875取低64、xor右移29、乘140737488355333取低64、xor右移31。保留256个distinct最小rank；同key合并，满时比较当前最大rank并替换/拒选，继续全部anchor pairs，最后sort rank/key冻结。duplicate/replaced/pruned是事件诊断，不虚报distinct漏目标。256选择是算法采样，可能FN；真实SEED授权容量不足是CAPACITY，不同于正常rank选择。
4. 每个被选中心对半径Q4域1…131071完整hist（16个8192bin tile，tile0的r0规范0）。每tile先真实clear8192项，再全POINT距离RNE一次、hist normal门13107，只有本tile合法非零r投票；其它半径不回绕。该tile全效果完成后按r升读回直方图，RAW为本bin票、SMOOTH为±8bin box sum；正峰按左右radius1邻居，两侧外域0，连续同值正plateau待两侧真实比较完成后仅发最小r。跨tile保存旧末18raw和下一首9（27×21=567bit有限holding），旧末9延迟到新首9真实读齐才判SMOOTH峰；RAW/SMOOTH各自plateau起点/高度/左邻资格持续保存，空tile仍提供真实0，不需同时保存16个hist。当前tile读/延迟/快照关闭后再clear复用HIST，末域补零只用于邻居/halo。峰逐tile产生并完整写入RAW/SMOOTH，全部16tile及末延迟峰关闭才seal两完整峰表；min支持取profile circle_min_support。各512峰真实容器，513直接CAPACITY；峰表全seal后才构造候选批，不把阈值以上未存峰丢弃成功。
5. RAW/SMOOTH各按radius顺序、batch16中心/峰上下文；每路线POINT分配给该路线最近peak，tie小radius。这是固定拟合初始成员政策，RAW与SMOOTH可以形成相近后续候选，由最终精确dedup处理。无峰为空合法。所有选中心/各实际峰批完成才circle_selected_done，缓存同center只在真实version/全部hist同值证据下可复用；本版不预算隐形缓存。

### E3. 圆固定五遍与最终冻结统计

A遍：对同一入选peak/c0/r0，POINT先满足最近峰分区、宽门64Q4、normal门；统计LS n21/A43/B s44/C43/D s56/F s56。完成该lane真实全遍后kind11（n≥circle_min_support、detmin/全宽条件）得到c1并保留nA，不在同沿把新c1用于A成员。

B遍：严格重算原A的完整成员谓词（仍旧c0/r0/peak/route），距离相对已冻结c1，uint18整数Q4距离→sum39，成员数必须等nA。kind3一次RNE sum/nA得r1，r17正域；不是在A顺便平均旧center距离。C遍：同分区，改用已冻结c1/r1的门，LS→c2/nC。D遍：严格重算C成员，距离相对c2，成员nC一致→r2。E遍：冻结c2/r2，对完整所有POINT重新核验，不再受最近原峰分区约束，统计最终eligible/support/SSE/sectors/最终LS263；geometry不再变。

最终eligible是abs(RNEsqrt((16x−cx)²+(16y−cy)²)−r)≤profile eligible_distance；support另需circle_radial_tol、更紧normal平行径向门及非零G/radial。normal门全宽cross²65535²≤tol²norm1²norm2²，混合极性只flags诊断。径向dx/dy s19、abs18；kind9保留θu512进位，fullbin1024再sector=fullbin/16置bit。SSE累加真实support Q4残差平方uint53，support0 maxres0；零eligible拒绝，不除零。

圆coverage门65535×popcount64≥circle_coverage_min×64，score RNE(65535support/eligible)仅排序，score门65535support≥circle_score_min·eligible，meanSSE门SSE≤circle_mean_SSE_max_Q8·support；都是精确交叉乘。最终冻结inlier LS263单独kind17获得n/quality，不用kind11再造c3；raw stats的det/trace/条件门按R3全宽比较，舍入quality不替门。radius/center/domain/condition不合法LOCAL_REJECT计入local/geometry诊断。完整CIRC形成后先扫描既存CIRC精确cx/cy/r key，重复保留先到seed诊断不二写（其最终完整POINT统计必须相同，否则INVARIANT）；distinct完整CIRC成功写后count++，第1025 CAPACITY。CIRC valid原值与VC最终再次核验不能漂移。

### E4. 全512θ DENSE与真实分段

1. θ0…511分32batch，每batch16系数kind16依次R3调用并锁17bit C/S（Q15）。按全E POINT rowmajor扫描，X2=2x−(W−1)、Y2=2y−(H−1)先s13计算/查域后s12，16lane局部X2/Y2 s12乘s17产生29bit，P=X2C+Y2S sum30；q=RNE(P/2^19) s9、q+138先s10检查q∈[-138,138]/r∈[0,276]再收rho_bin9。277合法中心ρ2=16q（半像素单位、8px间距），范围/高zero核后发DENSE_ADD16一次；真实组success才下一POINT。逻辑parallel16的32个12×17乘容器是性能候选，是否DSP/串行、S原子16RMW实际延迟须B01/B02，不能占同一R3同时16caller。
2. 不用gradient halo丢原θ votes。每batch全部票actualdone后只读NMS；四快照行跨batch和theta0/511镜像，wrap(theta,r)的rho镜像276−r，边界outside票0但中心padding235等不是合法图数据。radius1二维NMS，平票保canonical(theta,r)最小者；门line_min_support；全峰完整LINE64，1025 CAPACITY。
3. 每个line峰49个half-pixel offset（−24…24、step8Q4），最近offset ties-even，使用line_normal gate。radius1 offset NMS，平票取较小offset，最多25活跃种子；此offset选择是算法，会有FN，不当完整形状保证。两个独立CELL4096容器分别装两offset，不能当存两free数组。
4. tangent投影tQ4 s18；j=floor(tQ4/16)+2048，sub=tQ4−16floor(tQ4/16)，负值用数学floor。valid范围0…4095，每点RMW count/min/max/submask，真实已占子位置可恢复gap。跨格及格内按真实submask扫描，相邻实际Q4点差>profile run_gap才分段；不是global min/max拼接。不占子bit不当支撑。
5. 每run明确tlo/thi/count/occupied/maxgap/censored，support/coverage达到门才SEG coarse128完整写，fine初始化PENDING数值0。全部LINE/offset真实遍完成才seal coarse与进入fine；全1024SEG容量，1025失败，既有oldwrites/rsp不能抹。segment_coverage门用实际1px投影单元与首/末部分，不冒点数；这里同投影轴一维长度按完整submask构造局部区间并集，逐Q4子位置所属1px cell占位，最短/最长真实端点限制首末。

### E5. 固定六遍TLS、端点与缺边资格

每coarse段旧成员M0由peak/offset/原区间及line正常门重算。六遍：①M0 LS形式TLS217→kind12 TLS0/μ0，成员数=coarse n；②全POINT按TLS0残差/normal门写EXT80，old_count来自M0，按真实run gap形成run1，择old_count降/total降/tlo升，要求old share>0、μ0至区间距离≤endpoint_alignment；③严格M1（TLS0/选run1）统计→TLS1；④TLS1 EXT并标M1重算→run2同择法；⑤严格M2（TLS1/选run2）统计→TLS2；⑥仍M2点投影到TLS2，只求最终端点/occupied/gap/验证，**不第三次扩展**。每隔遍先结完整表/NUM/effects，不在新TLS同沿改变原成员。

TLS2 canonical ny>0或ny0且nx≥0，t=(ny,−nx)；法线翻转时tlo/thi与censored交换为(−thi,−tlo)。方向变化全宽sin门、required n/anis门、真实run coverage及maxgap通过才fine VALID；REJECTED fine数值0/coarse保留，全部384bit一次逻辑commit，不只改state word自称atomic。

完整端点恢复：Bn=2^30 rho，Bt=2^30 tQ4+8[tx(W−1)+ty(H−1)]，den=nx ty−ny tx；x=RNE((Bn ty−ny Bt)/den)、y=RNE((nx Bt−Bn tx)/den)，完整宽乘/除后检查s18。Q30法线实际K不假定恰等2^60；endpoint恢复和三边远端不能省中心项。

本版明确保守censor策略：像素面积窗Q4闭[-8,16W−8]×[-8,16H−8]，端点图外或距任一窗边≤profile endpoint_censor_guard_Q4_16，置该端censored；第6遍TLS2投影t等于最终tlo/thi的真实M2成员中，只要任一原像素中心触guard带，必OR置对应低/高端censored，tie成员不任意择一。guard实值待质量选择，不假填0。它仅限制三边推断资格、可能FN，不是拒绝测试中的图外/小尺寸目标。三边远端只允许两个原fine uncensored端，相关fine bits冻结，不能从已复用CELL重猜。

### E6. 矩形候选、预算与最终核验

1. 全VALID SEG pair a<b最多523776对，fine方向parallel gate、共同轴截距非零分离后写PAIR64；512实际容量，第513 CAPACITY。全部pairs结束才组合，不边写边只处理前缀。
2. 四边候选遍PAIR a<b最多130816组，四distinct SEG；三边遍每PAIR×第三SEG最多524288组，third不属于pair，profile missing_side_allowed1/required_visible_sides3才启用。先原fine方向orthogonal gate、原交点投影在各自[tlo−endpoint_alignment,thi+endpoint_alignment]；再以强support fine方向（同票低id）统一轴，其它轴90°，fullstats重算rho，各角kind13一次RNE。
3. 四Q4角点检查非零边/面积/不自交，CCW并以(y,x)词典最小角为起点，present和段号随之旋转。三边远端由完整E5恢复，两个uncensored端对齐容差及endpoint_extension产生推断第四边；缺长边/短边用同路线，不添加短边完整可见规则。几何域外局部拒绝，不clip几何；U形混淆纳GT FP。
4. 每完整合法组装几何进入实际验证前budget_used++，rect_verify_attempts同事件；已有kind0/1顺序固定四边循环后再三边循环。profile rect_verify_attempt_cap是主动搜索预算（原4096只待比较提议）；等预算且仍存在下一合法未评估候选时，unassessed_min至少1/search_exhausted1/SEARCH_INCOMPLETE，停止新算法并失败关闭，既有RECT/ANN前缀不发布。若后续只剩被前置几何门拒绝的组，可继续前置扫描证明无未评估候选，确实结束才成功。budget不是容器容量，真实PAIR/RECT表满另CAPACITY。
5. 最终四边对每POINT，kind15精确有限边距离分数N78/D39，端点d/p s19，K39，z/c s39；不套Q30 line-distance的K≥2^58门给短有限边。四侧选NiDj117最小、tie低side，每点至多一次，present不改变eligible/support分配；选中侧R3 exact RNE距离q19≤eligible_distance，support另需q≤rect_inlier_distance并gradient法向门。门比较本算法明确的RNE q，与无舍入连续距离门分开；R3通过完整4N与半整数界比较实现q，合格inlier再收q16、SSE=Σq²/maxres从同一冻结量化边得到。inferred side也统计支持，但wholecandidate required仅kind0四侧/kind1三present侧；required无正可见长度拒绝。
6. 针对同一次冻结inlier遍，累计四TLS217分别kind18诊断；required fit_support=Σn_i≤E，fit_quality=min(required anis)，不kind12重新拟合线/角/端点。required各侧n≥line_min_support、精确各向异性/可见coverage门分别核；全目标score用Σsupport/Σeligible、门65535Σsupport≥rect_score_min·Σeligible，SSE≤rect_mean_SSE_max_Q8·Σsupport，roundedquality/score不替门。完整RECT512写成功再count++，1025 CAPACITY；进入VC时再次冻结谓词/geometry校验，所有实际Q≤2048核验结束才select。

### E7. 精确可见覆盖、冻结VC与去重

每量化矩形边A→B，d=B−A、K39，窗Q4闭[-8,16W−8]×[-8,16H−8]。λlo0/1、hi1/1；d>0用(L−A)/d与(U−A)/d，d<0用(A−U)/(−d)与(A−L)/(−d)，d0且A窗外不可见；正den、signed40交叉乘取maxlo/minhi。hi≤lo无正长度，required拒绝，其它coverage诊断0不除零。保存实际四个n/d19，不改geometry。

j_base=floor(λlo√K/16)、j_last=ceil(λhi√K/16)−1，span≤2204（完整主图对角线）<4096；absolute j15、span13。inlier z=p·d clamp至[0,K]仅用于finite投影，j=floor(z/(16√K))由15次二分compare256j²K与z²，不先RNE projection；j在base…last才置bitmap。bitmap是实际1px占用，不给半开末端邻位。COVER四4096bit真实clear/pending完成再用，point/side/bin保持至置位效果结束。

读回bitmap统计O/b0/b1，并核span外零。Q=dlo dhi，A=b1 nhi dlo−b0 nlo dhi，V=nhi dlo−nlo dhi，B=O+b0 j_base−b1(j_last+1)。Lcov=B+A√K/(16Q)，Lvis=V√K/(16Q)。门化T+U√K≥0，T=65535·16BQ、U=65535A−threshold V；同号直接/异号比较T²与U²K并依正项确定方向，相等恰好过门。Q38/A s40/V40/B s17/T s77/U s59，square154/157bit；调用R3 scalar保完整384/385guard高zero检查后比较，不以integer root近似可见长度。RNE coverage16二分floor比例再以2·65535对2q+1半界compare，相等取偶，先核0≤Lcov≤Lvis不饱和掩错误。

全部实际CIRC/RECT写VC：圆gid=ordinal0…C−1、矩形gid1024+ordinal0…R−1，不读取无效洞。VC拒绝state1/其余0，成功state2且完整geometry/指标，最后state与body真实原子可见；state0仍实际candidate时select视INVARIANT。最终诊断来自本冻结POINT遍，不读取旧拟合表或R3 hiddenhistory。

排序所有state2：class升、score降、meanSSE精确SSE_a×support_b比较较小（零support已拒绝）、proposal id升。best400独立slot，读另一VC不能覆best。逐keeper同类geometry门：圆两center差平方和≤circle_center_tol²且|r差|≤circle_radius_tol，矩形canonical对应四角每角差平方和≤rect_corner_tol²，全部全宽、不先RNE norm；默认tol0是待比profile。不能按bbox重叠删除重叠真目标。命中geometry后重扫POINT按两冻结support谓词求I/U，65535I≥support_overlap_min·U，U0非法。roundedratio65535但I<U在门65535时不能merge。不同class/geometry/支撑保留，近重复可能FP纳GT；第65 keeper整帧CAPACITY。

keeper完整FINAL真实写后才count++/该VCstate3；重复也state3。所有state2消耗且全部NUM/OBJ/effects关闭才sealFINAL与IF06，geometry/metrics从此冻结。score排序不决定GT标签，support/SSE/coverage/fit_quality是一致诊断，不能排序后重新改它以改善结果。

### E8. ANN、标签、记录和输出提交

1. 读取全部冻结FINAL，生成DRAW80。circle annulus pixel中心Q4：D=dx²+dy²、Rlo=max(0,2r−stroke)、Rhi=2r+stroke，Rlo²≤4D≤Rhi²；矩形有限边圆头capsule用4N≤stroke²D，四边union。不画无限线替有限边。
2. circle Q5 extent=C5±Rhi先s21（最大524539越s20）；draw min=ceil(extent_min/32)、max=floor(extent_max/32)+1再clip到图内，geometry不clip。矩形保守端点bbox扩半stroke后逐像素精确finite predicate。需要floor root时kind7 SQRT_FLOOR，不能用kind4 RNE root冒floor（尤其内圈边界使用Ai−1）。
3. label为Ckk/Rkk，三边Rkk?，kk为FINAL slot00…63；label_mode0不画/1画，其它非法。7×5、scale1…15、bit4左/row0上，advance6scale，宽(6L−1)scale/高7scale，透明背景。anchor geometry bbox顶左加offset，y在bbox上方height+1，能容纳时clamp，小图从0逐像素clip；DRAW的charlen0（label off）或3/4、clip说明原label/geometry绘制被裁，未用DRAW不读。
4. 字体为独立私有FONT ROM，14glyph×7row=98word，每20bit低5有效/高15零，word98…511零；不借R3 projection word258…355（R3已要求unused0）。glyph id0C/1R/2…11数字/12?/13space。字形内容见下表，常量文件获批后才生成。
5. 每行一个W×2bit真实ROW先逐址clear，再对F FINAL/draw/label合并：00透明、01圆、10矩形、11文字或异类重叠；同类幂等/异类11/11保持，顺序无关。ROW RMW latest保护同pixel，画完全部对象和glyph/pending关闭才顺序写ANN该行所有W位置，response/effect全部完成后下一行clear。全H/N，不只含物体bbox或显示mode访问的偶行；单row480B与fullANN518400B均实列，不假设replay存储由row产生。
6. RECORD全64item逐个写：i<F完整FINAL512，其余全0；没有头128B旧物理布局或hiddenMETA640B假承诺。父完整J/profile/F/token在O辅助结果目录，实际schema仍B03；raw条目canonical完整可人工观察，生成器/hex/log未生成。ANN全N覆盖/无pending→COMMIT_ANN；RECORD完整64+F语义→COMMIT_RECORD；POINT token保留，三token都真实。
7. 然后停新业务、IF04真实CLOSE并NUM quiet/本地slot空，后续TERM freeze；J/O依据D8核完整成功/私有ref真退休/辅助记录真实登记后才bundle。cancel/失败可停止未开始后续行/记录，但旧held继续，不能说全图complete或恢复prefix资格。

| glyph | row0…6（每组5bit） |
|---|---|
| C / R | 01110/10001/10000/10000/10000/10001/01110；11110/10001/10001/11110/10100/10010/10001 |
| 0 / 1 | 01110/10001/10011/10101/11001/10001/01110；00100/01100/00100/00100/00100/00100/01110 |
| 2 / 3 | 01110/10001/00001/00010/00100/01000/11111；11110/00001/00001/01110/00001/00001/11110 |
| 4 / 5 | 00010/00110/01010/10010/11111/00010/00010；11111/10000/10000/11110/00001/00001/11110 |
| 6 / 7 | 01110/10000/10000/11110/10001/10001/01110；11111/00001/00010/00100/01000/01000/01000 |
| 8 / 9 | 01110/10001/10001/01110/10001/10001/01110；01110/10001/10001/01111/00001/00001/01110 |
| ? / space | 01110/10001/00001/00010/00100/00000/00100；00000/00000/00000/00000/00000/00000/00000 |

### E9. 错误、停止、真正终结与恢复

输入非法未获对象pin只给真实拒绝终态，不能按陌生handles寻址/free。已BIND后的第一故障锁reason/loc且mask累计，ABORT停新普通请求/未开始循环，不新填ANN成功；已经held请求/response/NUMREQ/NUMRESP/FINAL通知/TERM全部履约。CANCEL receipt独立，不等关闭或被term慢观察器阻塞。

最后heldrq必须真实fire，锁cutoff再发CLOSE；wrongrsp semanticcredit保留却不禁止CLOSE。来源真实failed-close证书可结IF03关联义务，不掩原错误。NUM独立处理publishedVALUE/DROP、应用DISCARD，matchingexpected实际结果消费并旧quiet才闭合；unknownNUM关联不借OBJclose代替。CLOSE/R3/PARENT依赖只单向：本地停止不等O私有退还，O私有退还等实际会话关闭；COMPLETEbundle又等真实私有退还。TERM形成不等父消费TERM或目录回收才报告自己的会话关闭，避免父/子互等。

Q只在本地published义务已履约后可输出冻结通知，未知STORE/NUMref状态不自清；late ACK保留由另行恢复处理，不回写已交付终态。parent消费Q后不可开始新H、reuse workspace/GRAD/POINT、授权新epoch或private_refs_retired。共同硬rst须所有实际参与者及外部effects合法关闭/共同重建，不能单端reset掩未知读写；软件reset按CONTROL/VIEW真实QUIET/授权，不自动复位callseq/目录。

### E10. PROFILE1024候选schema与值的边界

按原NUMERIC六组和tail布局，但新layout3/numeric1/algorithm3，表示本版取消prefix预算成功、CELLsubmask、censor及逻辑接口变化；不能把原layout2实体原样blindcast。下表每组内部低到高，保留全0；body内profile_ref64必须与J.C.CFG引用及真实immutable实体完全同一。完整实体安装/删除/历史pin及精确值B02/B03。

| 组 | 全部字段 / 位数 |
|---|---|
| header128 | layout8=3/numeric8=1/algorithm16=3/profile_ref64/flags16=0/zero16 |
| structure192 | theta10=512/buckets6=32/batch5=16/rho9=277/rho_step6=16/center_pitch6=0/halo2=0/sector7=64/radius_pitch16=1/radius_bins14=8192/line_cap11=1024/segment_cap11=1024/pair_cap10=512/circ_cap11=1024/rect_cap11=1024/final_cap7=64/vote_mode2=1/offset_count6=49/step_Q4_5=8/TLS_refine_passes2=2/projection_subbits3=4/run_gap_Q4_16/projection_cells13=4096/zero3 |
| fit192 | circle_min_support21/line_min_support21/circle_det_min16/line_anis_min16/circle_radial_tol16/circle_normal_sin16/line_residual_tol16/line_normal_sin16/endpoint_alignment16/parallel_sin16/orthogonal_cos16/zero6 |
| verify192 | circle_coverage_min16/rect_visible_coverage_min16/circle_score_min16/rect_score_min16/circle_mean_SSE_max_Q8_32/rect_mean_SSE_max_Q8_32/missing_side_allowed1/required_visible_sides3/color_mode2=0/color_tol8=0/segment_coverage_min16/eligible_distance16/rect_inlier_distance16/zero2 |
| dedup128 | circle_center_tol16/circle_radius_tol16/rect_corner_tol16/support_overlap_min16/dedup_mode2=1/zero62 |
| raster128 | stroke_Q4_8/label_mode2/label_scale4/label_offset_x s8/label_offset_y s8/map_merge2=0/priority2=0/zero94 |
| tail64 | rect_verify_attempt_cap13/TLS_direction_sin16/endpoint_extension_Q4_8/seed_member_policy2=0/two_cell_parallel1=1/endpoint_censor_guard_Q4_16/zero8 |

非Q4/Q8/计数的比例门16bit为UNORM16；circle_min_support≥3、line_min_support≥2且≤N为代数条件，非目标尺寸限制。eligible_distance必须≥各support距离，normal/parallel/orthogonal/domain检查在计算前；stroke非0、label on scale1…15/off scale规范1，rect budget1…8191；missing0/required4或missing1/required3，kind0仍四侧；没有虚构颜色核验。其它门精确值不由0占位当安装成功。

算法固定提议anchors8×6×8×2、seed256、pair角下界1024/差r128Q4、圆宽门64Q4/histnormal13107、RAW/SMOOTH512/平滑±8；这些是算法定义且可造成FN，变更需版本/GT比较。原阈值和budget4096/run_gap48/censor新guard实值都只是待联合选择，本文不生成默认实体或强承诺生产采用此昂贵分支。R3数值版本与PROFILE algorithm版本不同namespace，不改R3 numeric1。

## F. 语言、数值、执行与资源映射

C++当前不采用；若后续选C++模型须先核工具/标准并明确大整数，不能把native64溢出当参考。拟参考可采用经核实Python标准库任意宽整数/有理数与独立数据结构，当前不生成。软件数组初始化有效前缀/完整ANN和记录、借用对象不可alias覆盖、迭代范围先核容量、错误携真实前缀/无部分成功发布；异常不删除已有effects ledger。所有signed除/右移/floor/RNE精确定义，不使用host默认截零替负floor。

共同数值：R3所有宽算术/fullguard/近半界root规范为主；LS263、TLS217、有限边N78/D39、coverage154/157和SSE53保持。LS中心RNE一次、radius各distanceRNE再均值RNE；TLS本稿不重推不同eig公式。gradθ9与radialθu10进位分开，MUL/ADD/SUB的A192/B192/result_bits检查明确；输出收窄前检查高sign/zero及值域，不饱和成功、不隐含浮点容差。

| RTL A–L | 合同与限制 |
|---|---|
| A 数值 | D/E完整位宽/有符号/格式/比例门；W×H22再查N≤2073600、pair21；计数/seq临时扩位；score/quality仅排序/展示，不替精确门。 |
| B 时钟/观察 | 同core上升沿沿前判fire，e0capture、后续旧state校验/提交；未来TB下降沿驱动/沿后稳定观察，不用NBA新值反改同沿事件。 |
| C 接受/交付 | JOB/BIND/RQ/RSP/NUM/CLOSE/TERM独立；request接纳≠effect完成，真实response/commit/close分别定义；point源可暂停。 |
| D valid/推进 | invalid不投票/计数；EDGE0/ANN00为真实值不能当bubble；zeroE全ANN有效，count只真实完整效果推进。 |
| E 反压/保持 | 每口一held、完整KEY/data/configsideband保持；同seqissued只一次；ABORT不撤published；localerror通知/TERM独立。 |
| F 延迟/吞吐 | DENSE组实际16RMW和R3串行延迟、STORE读取/写/close真实计划待B01/B02；没有函数循环=1cycle或fps保证。 |
| G 复位 | 同步高共同rst fire0/version隔离；不清大阵当物理0；软件reset真实cancel/quiet/目录返还/epoch授权，Q不捷径。 |
| H 配置 | 完整旧J/profile只RJ接纳锁一次，动态提交/UI按CONTROL旧C，不能改当前geometry/门；profile_ref非零非存在证据。 |
| I 存储 | D7全N逻辑量/每record原子/forward与同址latest；所有对象容量实列，1R1W/对齐/银行映射真实backend OPEN，无免费SORTED或alias。 |
| J 身份 | H角色与JID/tx/call/candidate/point/side/lane分开；POINTrowmajor原幅，顶点CCW/bbox半开；geometry图外不裁、ANN绘制裁图。 |
| K CDC | 本稿同域，无新增CDC；真实摄像/provider/video/reset多域仍R5，不能据一core合同宣称安全。 |
| L 实现 | 目标Ti60F225/SV2009候选，本页纯文档；ROM字体独立1nativeRAM候选、R3自己的2ROM/5732bit容器不删；总XLR/DSP/RAM/clock/pin/STA/PNR都未冻结或未运行。 |

三份映射独立：①数学/逐位参考从immutablePOINT与完整profile生成相同确定算法选择/几何/统计，不借DUT候选日志造黄金；独立GT质量评估不等算法自洽。②硬件执行参考按各IF真实fire/held/效果/credit/close/quiet与current-vs-next事件账本，不以数学函数返回代事务完成；STORE可变延迟、取消/错echo单独覆盖。③软件完整原图/POINT ordinal/profile/H/各NUM_ID/OBJ_KEY与硬件事务逐项对应，数值逐位，取消比较真实已交付前缀与终态原值；Q软件保留引用，主机释放数组不能当片上效果关闭。合法共同run reset旧事务隔离，不将旧epoch数据解释新J。

有限寄存器预算候选需真实组合合并后定案：RJ2257、NUM held622/resp585、OBJ held799/resp872、CLOSE295/ACK504、FINAL_NOTICE231、TERM2606等各口slot可能同时活；echo可引用已pin不可变ctx时必须明示，不能默认删槽。fit四TLS868、best400、记录512、当前POINT64/SEG384、DENSE coefficients544/products928/sums480/bins144/三POINT192、radius跨tile rawholding567bit与两路plateau高度21/起点17/左邻/valid控制、游标等局部容器另列，R3自身5732bit/2ROM另有owner。O/STORE目录/journal/accesspin/返回ACK、ROW480B及FONT1RAM、实际scalar/RMW流水/控制都不计0；本稿不假报一个全机FF总值。

性能尺度：DENSE32E组，E=N时66,355,200组，若1R1W串行每group16票，至少1,061,683,200票更新（每票真实读/写延迟另计），100MHz理想单更新沿已10.62s，不能宣称实时。原circle完整radius16tile/halo/五遍峰最坏重复POINT巨大；RECT fullvalidgeometry预算≤8191、Q≤2048最终/去重也可多次全E。算法选种降低后续拟合并有FN，完整半径昂贵分支、梯度halo/缓存/更快候选方案可作联合比较，最终B02 OPEN；不把显示重复旧完整帧当识别fps，不把full N²/allradii理想穷举替生产方案。

## G. 实施与验证计划（尚未执行）

先解决A2真实设计/跨稿组合，冻结独立source/schema/GT与文件计划，纳入整包指定READY及明确批准；批准后按POINT/provider→anchor/circle→DENSE/SEG/TLS/RECT→冻结核验/coverage/dedup→ANN/record→真实CLOSE/private归还/fullbundle顺序实施。计划稳定职责recognition_coordinator/point_builder/support_seed/circle_five_pass/line_segment_tls/rect_assembler/frozen_verify/exact_coverage/select_dedup/ann_record_writer/recognition_store_adapter/recognition_numeric_caller均未生成，不在本轮写脚本/模型/TB或工程。

| TEST | REQ/IF/输入与事件 | 期望/独立方法及观察；全部NOT_RUN |
|---|---|---|
| R4R-T01 | REQ01/08；IF01/02/09；全1080p同源EDGE/GRAD，class冒EDGE、错profile/ref/版本/尺寸/commit | 仅真实全图目录准入；非法不寻址/返陌生ref；独立可信对象账本，不以flags造存在。 |
| T02 | REQ01/06；E0/N、EDGE1零G、错rowmajor/dir/highzero、取消POINT末write | 全N两源检查/POINT E≤N与真实token，零E仍输出N0 ANN/64零记录，坏输入整帧错误/旧fire保留。 |
| T03 | REQ03；每anchor桶0/1/2/3点、rank置换/全pair、多于256seed重复/替换 | 算法抽選diag与事务无损分开；全anchor pairs完成后最小256distinct正确，不声称全目标穷举。 |
| T04 | REQ02/03；图外中心/同心/重叠/格式域极值、RAW/SMOOTH plateau/tile halo/513峰 | 几何不clip、超域候选局部拒绝纳FN；真实513峰CAPACITY不截断，完整radius/tie由独立math。 |
| T05 | REQ03/04；五遍成员nA/nC、中心移动、半界radius、最终种子分区外inlier | B/D replay原成员而相对新center算距离；E全POINT冻结geometry，kind17不改center，逐位独立大整数。 |
| T06 | REQ03/07；DENSE16同rho连续、batch θ0/511/wrap、四NMS、STORE16RMW中停顿/取消 | latest不丢票/组success只全效果settled，全部512θ与canonical tie，无ready穿透/第1025LINE失败。 |
| T07 | REQ03；负floor、同cell不连子位置、run gap、49offset ties、两个CELL、SEG1025 | submask实证同格gap/occupied，不能min/max填洞，活峰抽选明确算法FN，容量失败wholejob。 |
| T08 | REQ03/04；TLS0/1/2、M0/M1/M2、normal翻转、三边端点恢复/小norm | 六遍准确、不第三扩展，完整center项/den，canon后端点censored交换，kind18只最终诊断。 |
| T09 | REQ02；任意旋转、缺整短/长边、U负例、端点guard/重叠、不加新尺寸门 | 同三边route/真实censored资格；U的FP纳GT，图外/小目标不拒测试，未通过算法门纳FN。 |
| T10 | REQ03/05；PAIR513、CIRC/RECT1025、budget达到后仍有合法未评估 vs仅前门拒绝 | 容量CAPACITY/未完成SEARCH_INCOMPLETE分开；diag/min剩余真实，prefix无ANN资格；恰无剩余才允许成功。 |
| T11 | REQ04；短finiteedge K<2^58、角点等距、inferred side有点、各required为空 | 有限分数全宽tie低side、每点一次，present不改分配；required无正visible拒，kind17/18对应冻结inlier。 |
| T12 | REQ04；窗口clip负den规范、同cell首末partial、λ正长度/0、精确coverage临界 | bitmap真长度，T²/U²K方向与RNE展示独立；不integerroot近似门；全部元数据/padding核验。 |
| T13 | REQ04/05；同score/meanSSE、proposal tie、I<U但rounded65535、同心/异类/相交/65keeper | 确定排序/精确集合门/不bbox删overlap；第65 wholeCAPACITY，无prefix；best不被别项读取覆盖。 |
| T14 | REQ06；s21圆外界、SQRT_FLOOR半界、capsule端点、98字体字/小图clip/冲突 | ANN规则完整N含0，独立FONT不改R3zeroROM，透明/异类11幂等；ROW全clear/held效果不丢。 |
| T15 | REQ06/08；全64记录unused0/highpad、ANN/RECORD两commit异步、取消末commit | 正确F/完整token独立事实，cancel不抹真实token但不发布；仅真实allN+Oaux资格可bundle。 |
| T16 | REQ07；R3每kind结果held/cancel同沿/LOCAL/FRAME/badID/callseq最大 | raw/exposedVALUE不改DROP，独立DISCARD+matching expected+旧quiet；错关联Q保留credit，不用quiet伪结。 |
| T17 | REQ07；OBJ wrongkey/heldRSP、badCLOSE_ACK、末read与CLOSE、count/seq溢出 | raw/good/settled分别真实、credit不强等；CLOSE独立无环，真实匹配证书才结；Q不free他人。 |
| T18 | REQ08；RC flags全1但private refs仍在、CLclosed冒回收、RECORD未注册/源没SRC | O真实私有清单/返还及schema2证据；会话pin关闭不等退休；无aux合同不能冒完整人工结果。 |
| T19 | REQ07/08；TERM/CANCELACK慢，父QUIESCE/软件epoch/新H同沿、合法共同rst | 独立通知、不父子互等，旧fire先记；未知义务阻止新epoch，不把新inputepoch当授权。 |
| T20 | REQ09；独立GT两类/负样本/错类/重复/重叠/失败帧，greedy少匹配反例 | 最大基数同类IoU0.5一对一；整数P/R门、无分母NA/失败GT FN和失败率，不删难例或prefixscore。 |
| T21 | REQ01/03/09；实际production W1920/H1080、真实backend/所有passes峰值/GT | 逻辑容器与实际mapping/吞吐/资源/STA/PNR/质量独立取证；小图通过不代fullproduction。 |
| T22 | 根可理解性；全新body/schema/hexpad/IF/OP/文件/参考方向、预算分支及OPEN | 无业务代码前先独立设计审阅，获批后manifest/checker/runner记录完整case；当前只是场景文字。 |

独立数学参考从image/profile/GT或自造POINT数学输入推导canonical集合/拟合/coverage，不重演DUT状态/事件日志造期望。协议参考只实测沿前各真实fire与真实STORE/Numeric事实，独立前缀账本不令所有口相等。GT在看最终识别输出前冻结完整distribution/manifest/hash；开发比较范围涵任意旋转/三边/低对比/噪声/重叠/负样本，不设置已撤销硬admission参数。

质量同类半开bbox边2·intersection≥union（IoU0.5），采用确定性最大基数二分图匹配，固定GT/pred索引和IoU降序遍历增广，不能用greedy少配。每类整数门20TP≥19(TP+FP)且20TP≥19(TP+FN)；分母0标NA不说100%，最终独立主集两类须有GT，所有负样本FP计入。失败/取消/SEARCH_INCOMPLETE/容量错误帧没有合法预测prefix，GT记FN，单列failure_rate/功能失败；质量达标不能掩功能失败或不完整搜索。

未来随机停顿/cancel/错误注入须有限seed/次数/最大时延和wall/cycle timeout，永久stall只检查保持/不伪成功。精确值和完整文件B05待冻结，未生成runner/TB/可执行模型。生产综合资源/时序/布线bit在获批实施后执行，下载和比特流后硬件步骤本测试暂不处理。

## H. 双向追踪

| REQ/来源 | MOD / IF / OP / 不变量 | 计划文件/稳定职责（未生成） | TEST/期望 | 实际代码/基线/证据 |
|---|---|---|---|---|
| REQ01 / 全1080p、R2/CLOSURE | J/O/P；IF01/02/03/09；E1；INV01/02/08 | point_builder、source_snapshot、grad_collector_adapter | T01/02/21；真实逐坐标/provider | 未实现；候选来源A1/NOT_RUN |
| REQ02/03 / 原ALG/用户场景与性能权衡 | S/C；IF03/05；E2…6；INV02/03/07 | anchor_seed、radius_hist、circle_five_pass、dense_segment、tls_six_pass、rect_assembler | T03…10/21；独立数学/GT | 未实现/NOT_RUN；profile性能OPEN |
| REQ04 / NUMERIC/R3 | V/C；IF05/06；E3/6/7；INV03/06 | frozen_membership、final_diagnostics、visible_coverage | T05/08/11/12；精确R3公式 | 未实现/NOT_RUN |
| REQ05 / 完整结果与容量 | V；IF03/06；E7；INV06/07 | vc_sort、support_dedup、final_freeze | T10/13；独立集合与稳定比较 | 未实现/NOT_RUN |
| REQ06 / ANN/人工观察 | A；IF03/06/08/09；E8；INV04/08 | annotation_row、font_rom、record_commit、aux_result_registry | T02/14/15/18；完整像素/record | 未生成常量/代码；Oaux OPEN |
| REQ07 / 根工程合同、R3/闭包原则 | C/STORE；IF03/04/05/07/08；D4…6/E9；INV04/05/08 | obj_ledger、numeric_caller、cancel_close、terminal | T16/17/19；独立真fire账本 | 未实现/NOT_RUN |
| REQ08 / VIEWschema2/REPLAY | J/O；IF09；D8/E9；INV01/08 | private_allocation_ledger、object_return、bundle_certificate | T01/15/18/19；目录实体/真实返还 | 实体/跨稿OPEN，无伪证书 |
| REQ09 / P/R95与IoU0.5 | 独立验证；G | independent_gt_matcher、quality_manifest | T09/20/21；GT非DUT期望 | 未生成/NOT_RUN |

反向核每个计划职责仅服务对应输入、算法、数值、有限对象、真关闭或独立验收；不由本稿引入指定外存驱动/PHY/视频输出。代码/注释/TB实际映射获批后登记，不能将计划路径称为已有文件。新profile、censor/预算/算法筛选改变必须同步REQ/IF/OP/TEST/基线，不用空泛资源优化理由跳过行为审阅。

## I. 设计门槛与评审

①整体行为/样例B；②职责/来源C/A；③完整候选body/对象/组合D，但真实provider/O/aux及epoch需A2；④局部中文步骤/不变量E；⑤语言/三份映射F；⑥正常/零目标/错echo/取消/预算走查B/D/E；⑦验证/双向trace G/H；⑧无当前阻塞不满足；⑨保存实际全文读回/hash/呈现另报告；⑩v0.1/来源/纯文档授权清楚。

保持LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。不关闭R4完整backend、B03/B05/R3/R5或整包。本文作者自查不是独立审阅、静态算术不是仿真/综合。允许下一行动是纯设计独立审阅与联合profile/performance/backend/目录组合；没有用户明确指定成熟设计版本/范围/基线实施批准，停止在文档交付。原Approval Manifest/数据库未写入，不宣称审批已登记。

## J. 相对旧约定与恢复

新稿采用旧anchors/rank、五遍圆/六遍TLS、有限边/覆盖/全表去重数学，但以当前R3替旧NUM543/540、共享font/调用取消；以逻辑H160/OBJ和实际O替旧4731job/physical key/scope/grant/MC/phase及225RAM假预算。全部POINT扫描rowmajor替SORTED散桶（全E整数DENSE票顺序不改变整数结果，真实逐票latest原子）；不隐含第二POINT空间。CELL/EXT新增submask保证格内真实gap；censor explicit策略/profile3；预算耗尽显式SEARCH_INCOMPLETE，不容许前缀成功。

最终diagnostic固定kind17/18从冻结inlier，不新拟合geometry；RECORD作为需实际Oaux保留的结果，私有目录返回不是会话close。真实入选支撑抽选风险/预算/容量/质量/吞吐分层，完整主路径不替全N²理想穷举。原场景与P/R/IoU目标不缩小。

改变上述算法/端口/owner/容量/profile/geometry/数值/关闭/epoch/资源选择时先修本文与父组合并复核独立GT/TEST/来源；不能凭旧版批准继续重要行为改变。恢复先读唯一规则、现行来源/hash/OPEN及实际批准，核所有refs/credit/term未知状态，未形成真实义务关闭不重新开始。

## K. 实现与验证实录

本轮仅实际来源读取、纯文字与静态字段/容量分析、本文创建与保存后全文读回。业务RTL/C++/Python模型/功能脚本/常量生成器/可执行测试/TB/工程/约束均未生成；仿真、综合、PNR、STA、bit/hex、下载/人工硬件观察全NOT_RUN。没有网络、安装、指定器件/PHY/IP调查，原资料/其它文件/正式状态/审批/数据库未改。

字段和逻辑容量分析不是网表或provider已存在证据；COMPLETE/token/closed/private_refs_retired只有未来真实对应owner和可信账本可给。完整全图软件可运行/综合/布局/合理pin/时序与质量最终目标尚未完成，本稿不冒称完成业务。

## L. 交付与阅读说明

先A1现行来源→B整体→C模块→D1身份/fire→D2端口→D3schema→D4/5两种真关闭→D6终态→D7容量→D8私有目录/完整bundle，再E1…9一帧中文步骤、E10完整profile、F数值/执行/资源、G/H验收、I停止点。术语“完整搜索”仅指本文明确选择政策全部循环完成；“完整图”指N个真实坐标；“关闭”必须区分会话pin与目录对象退休。

普通完整路径：真实finalEDGE/GRAD→POINTcommit→被选anchors/seed全部完成→五遍圆/全θ与六遍TLS/预算内矩形全部完成→冻结几何核验/独立诊断/全表去重→FINALsealed→完整N ANN/64记录→三真实tokens→OBJclose+R3quiet→TERM→真实私有refs退休/aux登记/全SRC-EDGE-ANN bundle→VIEW/REPLAY。错误从同一路径进入真实收尾或Q，不能在pipeline empty后假补对象退还。

目前只交付候选文档；理解验收待用户实际反馈，不把讲解当已理解。批准前阅读可按REQ→IF→OP→TEST正向、从ANN/record→冻结geometry→members→POINT/source/J/profile逆向追；获批后源码/注释/TB/产物仍须逐项对照这些合同。
