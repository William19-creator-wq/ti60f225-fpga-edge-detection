# TRACK4-ALGORITHM-CONTROL-001：单core按键、配置与算法分发设计 v0.2

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本文按实际独立审阅修订为v0.2，是[R2](design-TRACK4-ALGORITHM-R2-001.md)B03的一份候选局部设计，保持[整包](design-TRACK4-ALGORITHM-BATCH-001.md)五基础、六高阶及生产1920×1080目标。它只建立单core软件合同，不继承旧物理父生命周期，不宣称B03关闭。

## 通用计划字段

- Goal：明确四键手势、完整配置、D/P/C/J/V唯一owner、有界命令/回复、真实job生效、Sobel/Canny/识别分发、取消及单core软件复位的可实施文字合同。
- Current state：纯手势/阈值/8preset/6mode已从旧CONTROL/DISPLAY整理；当前C0仅接受CJ142并独占内部FE。新配置/分发没有业务实现，R3/R4及完整结果重放交接仍OPEN。
- Target state：补齐本文OPEN交接后，控制与RGB/最终edge/ANN重放子设计共同闭合B03；纳入统一成熟设计包批准后实施及验证。
- Gap：识别profile完整实体、R4完整job/终态与结果对象交接、生产render_generation/真实APPLIED、不可暂停视频及最终四键top未闭合。
- Assumptions：软件核及控制均单core上升沿、同步高有效共同rst；外部规范源可暂停。生产1920×1080；小控制/分屏实例W偶数至少6、H偶数至少6，split=H/2。R2独立6×5流段合法性不因此改变。
- Open questions：见A；本文提出新消息族及逻辑对象handle，均不是已实现端口、物理地址或旧FM授权。
- Dependencies：唯一根v0.2、原FE/R1、当前R2/C0/OBS、纯来源整理、未来R3/R4/R5；不恢复指定器件调查。
- Milestones：纯规则→owner/有界接口→中文事件→R3/R4/重放组合→读回/审阅→整体成熟后统一批准→实施/验证/生产工程→bit登记停止。
- Detailed steps：B看可观察结果→C看唯一owner→D核字段/容量/相容→E逐沿步骤/反例→F/G/H数值、验证和追踪→A/I闭合OPEN。
- State transitions：本稿LOCAL_DESIGN；有内容不等于READY，父B03/B05及整包保持NOT_READY。
- Artifacts and hashes：A列实际来源hash；本稿hash在保存后实际读回并报告，不自引用写入自身内容。
- Validation：G均为未来文字场景NOT_RUN；设计审阅不替代RTL仿真、综合、PNR、STA及bit证据。
- Failure handling：未接纳手势可整条drop并记录；已接纳请求和held body须结账；非法完整配置拒绝；失败不等完整P/EOF，不伪造子级终态或对象归还。
- Human approval gates：本轮仅获准创建本文这一设计文档；尚无本稿/整包实现批准，不生成业务源码、脚本、参考或TB，不运行工具构建。
- Rollback：来源保持只读；只新增本文；不改正式Manifest/H0/数据库及其他设计文件。
- Completion criteria：控制合同及所有OPEN交接保存/读回/审阅并纳入整包；正式十一项目标不缩小，T4-A3仅DEFERRED，bit之后步骤不执行。

## A. 状态、来源和未闭合点

任务AC=TRACK4-ALGORITHM-CONTROL-001，关联R2-REQ08、T4-A2/A5/A6、T4-B3/B4及派生控制可观察性。本文字段/状态是新提议；B中纯规则是已读来源事实。无Git commit，不伪造。实际读取来源：

| 来源 | SHA256 | 使用范围 |
|---|---|---|
| [CONTROL](design-TRACK4-CONTROL-001.md) | A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6 | B2/D1/D2/E2/E3的纯手势、阈值、preset、旧快照原则；旧AON/FM/PL生命周期不继承 |
| [DISPLAY](design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 | 已全文读来源的D1/D2及像素规则；生产授权/租约/扫描父合同不继承 |
| [来源整理](../experiments/track4_algorithms_20261004/02_design/control-display-source-contracts-v0.1.md) | 192D9DCED0F1189E6804423040BA45FDAD6DAE8F00B9D87893DE31E649DD91A0 | 本轮实际全文读回；1…6的纯合同和新交接缺口 |
| [FE v1](design-TRACK4-FRONTEND-001.md) | 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 | 原FJ/FP/FO/FS生命周期和Sobel数值 |
| [R1](design-TRACK4-ALGORITHM-R1-001.md) | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 | FE核复用及原Sobel；不把其自运行监督top作为分发器内部核 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | 本轮实际全文读回；C0 owner/CJ142/CS592及B03 OPEN |
| [C0附件](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md) | 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844 | 已实际全文审閱的唯一FE owner、held FJ、取消/早FS/失败终态 |
| [OBS附件](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md) | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 | 已实际全文审閱；独立四pinreset及CSvalid source-stop/CSfire终态；不借用其J作为正式控制owner |
| [BATCH v0.3](design-TRACK4-ALGORITHM-BATCH-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 | 本轮实际全文读回；完整十一项、1080p、统一批准及NOT_READY |
| [候选39来源](../experiments/track4_algorithms_20261004/01_baseline/algorithm-r2-baseline-v0.3.json) | E5F3EAE8A0BA5C33BA7179479F94DF086ED2832CAD0032B0F1527920BE68E547 | 实际读回；不是本文冻结基线或整包批准 |

| OPEN | 具体问题、影响与闭合责任 |
|---|---|
| AC-B01 | profile_ref64只引用完整不可变实体；参数类型/单位/默认/数值范围及注册实体尚由R3/R4闭合。影响REQ03、IF04/05及正式algorithm2启动；不能靠非零编号关闭。 |
| AC-B02 | R4精确闭包/RC完整job、收集器准备、子级取消/terminal、对象归还证据未冻结。本文J状态和终态提出公共要求，但具体R4消息/容量/成功谓词仍OPEN；影响IF05…08和优雅reset done。 |
| AC-B03 | 原RGB、最终edge及ANN的不可变对象handle、独立可暂停重放/返还/plan、正式render_generation及实际APPLIED需与重放/渲染子设计共同冻结。本文V只表示typed软件采用，不代表HDMI已显示；影响IF06/08/09。 |
| AC-B04 | 最终四键top、电气pin/时钟/CDC/不可暂停源和视频扫描由R5完成；当前单core不能承诺CORE停钟后长按仍送达。独立OBS四pinKEY1reset保持原设计，不能同时作为本四键手势入口。 |
| AC-B05 | 新局部文件/参考/协议测试/语言映射及共同基线须随相邻版本闭合；本文尚未经完整组合审阅，父B03/B05不能关闭。 |

当前允许继续设计和审閱；本文不能请求泛化实现批准。其实施范围/路径/版本/基线尚未获批，正式审批状态不改。其他工作副本/数据库/工具条件沿整体治理，本文不提供例外。

## B. 整体外部行为

| REQ | 可观察规则 |
|---|---|
| AC-REQ01 | 四低有效键仅读旧同步第二级；1ms enable、21同样本/20完整间隔、启动释放资格、短长互斥且无repeat。忙不暂停计时/释放检测。 |
| AC-REQ02 | 阈值单位、默认、饱和和完整配置拒绝保持来源；D可合并，P held不改，C唯一提交，真实job锁旧C，V锁完整历史结果/render。 |
| AC-REQ03 | 8preset与6mode分开；cursor记录尝试，profile拒绝不改D/C；正式retain只由algorithm2派生。 |
| AC-REQ04 | 每个已接受事件预留独立回复；命令/来源/序号/代次有界、耗尽不回绕；ACCEPTED_DESIRED/COMMITTED/J_USED/V_LATCHED/真实APPLIED分别观察。 |
| AC-REQ05 | 唯一分发器按J选择Sobel FE或C0+完整闭包/RC；原RGB与最终edge通过独立重放对齐，class不是final edge。 |
| AC-REQ06 | 参数/颜色/median改变不一律取消旧任务；algorithm屏障在旧握手后作用未移交旧任务。取消和软件reset兑现held与真实终态，不等待失败任务的完整P/EOF。 |
| AC-REQ07 | A3短KEY1仅返回DEFERRED，不建立freeze/resume业务状态；长KEY1使用独立软件reset请求/receipt/done。四键top与OBS四pinreset top分开。 |

纯手势保持：KEY0/2合格释放+16/−16；KEY3短于800ms释放NEXT、达到800ms只一次MEDIAN；KEY1短于2000ms释放op4冻结意图、达到2000ms只一次独立RESET。边界UP归LONG，LONG后的UP只结束手势，持续按住不重复。计时从消抖后合格DOWN到UP；模拟tick间弹跳不作连续电气保证。

同tick普通事件按KEY1→KEY3→KEY0→KEY2保存和分配连续event_seq，随后最小seq先发送。四key各depth1；旧full即使同沿pop也整手势drop。可保存的整批UI序号先65bit预检，若无法全部分配则整批拒新，不部分回绕。LONG reset有独立seq/槽，不受UI满或UI序号耗尽影响。

TS/TL/TH均unsigned11、0…2047。默认TS256/TL128/TH256、median0、preset0；默认是既有设计选择。Sobel严格M>TS；Canny严格Mnms>TH强、TL<Mnms≤TH弱，其余NONE。结构化TL>TH整次拒绝，不交换。UI根据旧已接受D.algorithm：Sobel只改TS；Canny/RC以unsigned12计算TH±16再饱和，TL=新TH整除2。NO_CHANGE比较整个CFG：TH2047/TL1再INC仍改变TL到1023。切preset保存median、独立阈值及颜色。

| preset | algorithm | mode | 含义 |
|---|---:|---:|---|
| 0 | 0 SOBEL | 0 | 上原灰度/下Sobel边缘 |
| 1 | 0 | 4 | 原RGB加Sobel彩边 |
| 2 | 1 CANNY | 0 | 上原灰度/下完整Canny边缘 |
| 3 | 1 | 4 | 原RGB加完整Canny彩边 |
| 4 | 2 CANNY_RC | 5 | 完整Canny与圆/旋转矩形标注；必须有完整profile |
| 5 | 0 | 1 | 原RGB，仍走完整job |
| 6 | 0 | 2 | 原灰度，不能用median后的M |
| 7 | 0 | 3 | 全屏Sobel边缘 |

NEXT从cursor尝试下一项，7→0；初始化cursor0/valid1。profile缺失时preset4明确拒绝，D/C不变、cursor仍4，下一NEXT尝试5。结构化SET成功后按algorithm/mode匹配表；不匹配则cursor_valid0，下一NEXT尝试0。NEXT按最近尝试推进，但±根据D.algorithm，拒绝RC不能把Sobel阈值误当Canny阈值。完整SET允许表外合法组合，algorithm3、mode7非法；mode6仅渲染局部诊断，不能写业务CFG；mode5必须algorithm2。非RC profile_ref规范0，外部SET给非RC非零引用整次拒绝；RC必须完整已安装且生命周期内不可变。preset规范show_edge1、show_ann按algorithm2派生；SET保留合法显式开关。

render112保留mode3/split11/edgeRGB24/ANN01/10/11各24/show_edge1/show_ann1；生产split540，其他mode也核540。默认FF0000、00FF00、00A0FF、FFFF00。原灰度只来自原RGB：floor((77R+150G+29B+128)/256)，所有项先扩16bit、最大65408、纯绿149。mode0上下两遍源偶行0,2…1078；mode1原RGB、2原灰度、3白EDGE黑底、4彩EDGE覆RGB、5在mode4后ANN覆盖。mode0/3不因show_edge关而改变黑白；mode4/5开关不减少平面完整性要求；ANN优先EDGE。像素实现/plan仍见AC-B03，不在本稿写算法代码。

正常观察：KEY0短按→终端回复ACCEPTED_DESIRED→C真实提交→某次job实际锁C→完整选定算法及结果→V真实锁render。这些不是固定一帧延迟。边界：P held期间D连改，P仍原内容；commit与job同沿，job旧C。失败：非法SET拒绝；profile缺失只推进尝试cursor；A3回复DEFERRED；子级失败真实收状态、交付失败终态，不补缺失结果为成功。

## C. 唯一owner、整体连接与复用

KEY4 → AC-IF01 KEY_OWNER → AC-IF02 UI → CFG_OWNER(D/P/C) ← AC-IF03 SET；CFG_OWNER旧C → AC-IF05 JOB_DISPATCHER(J) → Sobel FE或C0/R4 → AC-IF06 VIEW_OWNER(V) → 独立重放/像素算术 → 后续固定视频。取消走AC-IF07；长按走独立AC-IF08；真实观察走AC-IF09。

| MOD/状态 | 唯一writer/职责与边界 |
|---|---|
| AC-KEY | KEY_OWNER唯一写同步/消抖/资格/手势、UI event_seq64、reset_seq64/exhausted、四key槽和选中发送快照。不能分配config/frame/epoch或直接reset PLL。 |
| AC-CFG/D | CFG_OWNER唯一写最新CFG212、desired_revision64、来源103、dirty/已proposed、cursor3/valid1；未proposed D可合并，不持图像租约。 |
| AC-CFG/P | 同一CFG_OWNER拥有一个不可变P539、proposal_seq64；只从旧D形成、直到提交/明确拒绝，不随D更新。一个进程/owner负责D/P/C计算，避免多个模块各写C。 |
| AC-CFG/C | CFG_OWNER唯一写C539、config_id32和algorithm_generation32；软件epoch32由RESET_OWNER提供，不自行推进。C更新不改历史J/V。 |
| AC-JOB/J | JOB_DISPATCHER唯一分配job_frame32、锁J657、选择子核、请求取消、接子级真实终态、持有结果offer/作废及归还义务。不能另发C0内部FE FJ或改rawFS/rawCS。 |
| AC-VIEW/V | VIEW_OWNER唯一写typed V788及当前typed访问资格；锁完整J/render/对象引用。不是旧物理DP，不声称真实APPLIED/HDMI输出。render_generation联接OPEN。 |
| AC-RESET | RESET_OWNER唯一写软件epoch32、quiesce阶段、receipt/done；最终四键top的reset_seq唯一由KEY_OWNER预分配。typed测试可替换该唯一请求producer，不能同时接入第二个独立分配seq的调用者；RESET_OWNER不再分配另一reset_seq。 |
| AC-OBSERVE | OBSERVE_OWNER仅复制真实D/P/C/J_USED/V_LATCHED/term/reset事实，live与held读取各1份；慢读不反压业务回复/终态/对象归还。 |

复用条件：Sobel路径复用原FE核及FJ/FP/FO/FS；不复用R1自运行pattern监督top。Canny路径复用新C0 wrapper，外部只CJ142/FP74/class/grad/CS592，C0仍唯一内部FJ/FS owner；不复用OBS自动递增J监督器作为正式分发器。默认设计为两个独立核实例、单J只启动一个；若要共享FE节省资源，必须另修owner、切换与状态合同，不能暗接两位owner。全机面积/吞吐由R5评估，不把本结构声明为最优资源实测。

整体检查点：先呈现B/C的配置与最终结果路径，再进入字段和旧状态草图。原RGB必须可独立同序暂停重放；一个活流RGB entry等edge会堵窗口，禁止。R4收集器需在子流启动前准备；失败状态接纳不能等待P/EOF，观察不能占用业务终态容量。AC-B01…05仍限制完整实现和整包READY。

## D. 新消息族、容量与相容检查

### D1. 公共事件、内容与身份

除raw GPIO外均同core；fire为沿前valid且ready，rst屏蔽fire；新接纳数据不在该沿穿透到下一模块。held请求/回复/结果body从提出到fire不变；取消不能擅自撤held子请求。容量看旧valid，旧full即使同沿消费也不默认新腾容量。所有下列整数unsigned；数字是逻辑字段宽度，不是已经生成packed端口。

CFG212=algorithm2+median1+TS/TL/TH各11+render112+profile_ref64。来源SOURCE103=valid1+kind1+identity101：kind0保存完整UI101；kind1保存epoch32/request_seq64/zero5；valid0时全部其余102bit为0。禁止拿SET序号伪装UI。P539高到低为epoch32/proposal_seq64/desired_revision64/expected_config_id32/expected_algorithm_generation32/CFG212/SOURCE103。C539高到低为epoch32/config_id32/algorithm_generation32/proposal_seq64/desired_revision64/CFG212/SOURCE103。P/C同位宽但字段意义不同，不能按同一body别名解读。

JID96=epoch32/job_frame32/config_id32。J657=C539+job_frame32/source_handle64/W11/H11；完整历史CFG与来源随J，不随后来C变化。V788=J657/final_edge_handle64/ann_handle64/planes_ready3。source_handle是逻辑不可变原RGB对象引用，绝非DDR地址；planes_ready用SRC/EDGE/ANN bit0/1/2。缺ANN的非RC结果ANN ready0及handle规范0；RC零目标仍必须有完整合法全0 ANN对象，不能缺平面冒充无目标。handle宽度是候选交接，实际对象provider/返还及render_generation待AC-B02/03。

新control reply status3保留0ACCEPTED_DESIRED/1NO_CHANGE/2BUSY/3REJECTED，增加4DEFERRED，5…7非法。error5保留0NONE/1BAD_FIELD/2PROFILE_NOT_INSTALLED/3VERSION/4SEQ_BODY/5EXHAUSTED；本新族6EPOCH/7DEFERRED_A3/8SUBTASK/9CAPACITY/10SEQ_ORDER/11RESET_CANCEL/12STALE_POLICY/13PROTOCOL/14TOO_LATE，15…31保留。它不是旧UI274接口，不能将旧SESSION含义接入；FE/C0原错误码保持原族、不重编码覆盖。

### D2. 接口与有界容量

| IF | 新合同、前置与真实事件 | 有界容量、结束与组合 |
|---|---|---|
| AC-IF01 | raw4→KEY_OWNER；每位twoFF，只读旧second；CORE_HZ整除1000，1ms enable；共同rst后WAIT_RELEASE | 四depth1 UI槽；发送held1借用原key槽直至匹配终端回复。独立reset request1，非UI容量。GPIO无法反压，旧full新手势整条drop。 |
| AC-IF02 | UI101=epoch32/event_seq64/op3/key2。op0INC/key0、1DEC/key2、2NEXT/key3、3MEDIAN/key3、4FREEZE意图/key1；5…7或错key拒绝。回复277=原UI101/status3/error5/superseded1/SOURCE103/desired_revision64 | 接收RX1与独立回复1，接受先预留回复；一个执行器下一沿使用旧D。BUSY不结账/不进完成缓存，同body可重试；0/1/3/4为终端回复，选中key槽收到完全匹配终端后释放。A3 op4回4/7，D/P/C/J/V不变。 |
| AC-IF03 | SET404=epoch32/request_seq64/expected_config_id32/expected_desired_revision64/CFG212。回复272=原身份epoch32/seq64共96/status3/error5/superseded1/SOURCE103/desired_revision64 | 独立RX1/回复1，不能塞入UI101。UI与SET都旧RX有效时按执行完成轮转，每沿最多执行1项；新接纳该沿不执行。全字段及版本/完整profile检查后一次写D或整包拒绝。 |
| AC-IF04 | CFG_OWNER内部D→P539→C539；P从旧D形成，下一沿或更后依据旧P提交；真实commit单独注册 | P1，C1，D1。C无外部可争抢writer；没有旧FM605/1182端口。UI/SET回复只表示D接受，P/C最新事实经IF09观察；不为每个被合并D创建永久APPLIED等待项。 |
| AC-IF05 | source offer86=source_handle64/W11/H11→JOB_DISPATCHER；oldIDLE、源provider真实借用及终态容量可用时fire锁J657；子级请求按D3映射 | 单J；选定stream rawstatus1、每个已启动final子级terminal各1、总jobterm1预留。provider有效性/完整源借用及R4消息尚OPEN。整个job不再读D/P或新C参数。 |
| AC-IF06 | J→VIEW_OWNER V788候选及独立publish_allow1；VIEW_ACK104=JID96/status3/error5，status0LATCHED/1ALREADY/3REJECTED；2与4…7非法 | offer1/ACK1/typedV1。正常无容量只ready0，不返回BUSY。ALREADY仅当前V完整同body匹配；错body拒绝。publish_allow是独立旧注册资格，不属于held body；取消后它可变0以拒绝held旧offer。合法新候选需oldV有容量；旧policy/不允许发布者可被接受并拒绝，不等oldV释放。生产rendergen/归还OPEN。 |
| AC-IF07 | manual CANCEL128=JID96/algorithm_generation32；回复136=原128/status3/error5。接收沿只存RX/预留reply，下一沿执行精确匹配旧J才设sticky cancel | requestRX1/reply1，独立stream CS/FS和jobterm。已完成/STATUS或已真实结果移交回NO_CHANGE/TOO_LATE，错身份REJECTED不取消别人。held stream请求必须接纳后后续ACTIVE取消。 |
| AC-IF08 | RESET96=expected_epoch32/reset_seq64；独立receipt104=原96/status3/error5；done136=原96/status3/error5/effective_epoch32 | request1/receipt1/done1，接受预留两回复。receipt0只接纳，done0只有旧义务/对象归还真实结清并切epoch才形成；done3失败/证明未闭合不得清旧业务。两个回复各自held，不能因UI阻塞挪用。 |
| AC-IF09 | 原子读取live快照：D及来源、P valid/body、C、J valid/body/state/started/cancel、V valid/body、最近jobterm、reset阶段、cursor、drop/错误/耗尽 | live1与held读响应1；读请求只在旧held空接受，复制当时完整live，慢读期间live继续更新。最终全包读取位宽须随AC-B02/03新增字段冻结，不能以本文局部字段宣布完整生产CSR。 |

UI和SET各只保留当前RX/回复与最后完成1条完整request+reply缓存；同epoch/seq/body重复返回原终端回复，不再写D/cursor；同seq换body/op拒绝SEQ_BODY，原缓存不覆盖；更早未缓存seq拒绝SEQ_ORDER，不能拿最新reply回答旧body。合法新请求seq从0开始按终端完成推进，BUSY不推进；错误epoch、SEQ_BODY及SEQ_ORDER不推进本epoch期望seq，不覆盖原完成缓存。旧完成缓存重放需另有旧回复容量，不能覆盖正在held回复。外部SET逐字段检查并比较expected C/D版本；UI手势不带版本，执行时依据旧D。

独立reset发送槽在原请求匹配receipt及done均消费后才释放；接受RESET96一律预留两回复，启动前拒绝则形成拒绝receipt和拒绝done/effective_epoch=current，未启动quiesce。RESET_OWNER保存当前事务及最后完成1条96/104/136缓存，缓存跨本次软件epoch切换保留：同完整RESET96重复返回原receipt/done，不二次推进epoch；未知旧epoch拒绝。RESET96全体是expected_epoch/seq身份，没有另一个可变参数body；不同epoch同数值seq不误判为UI的SEQ_BODY。旧缓存重放仍需两回复槽，不能覆盖held。复位等待期间ready可0，不能借用UI空间。各packet的status0/1解释以IF表为准，VIEW/RESET数值编码不别名为UI的ACCEPTED_DESIRED。

superseded只有新CFG确实替代尚未进入P的旧D来源时为1并回旧SOURCE103；否则0且来源全0。判定合并“旧D已经proposed”或“本沿从旧D形成P”，不能同沿P锁旧D/UI写新D却误报旧来源被取消。NO_CHANGE、拒绝、DEFERRED均不报superseded。已proposed/已committed/已用于job的历史保持，只观察最近有界事实。

### D3. 精确映射与结果边界

| J.algorithm | 请求owner/字段与流输出 | 正式完成条件 |
|---|---|---|
| 0 SOBEL | 外层Sobel adapter唯一向独立FE发FJ110：JID96/median1/kind2=1/TS11；送原FP74；adapter只消费此FE的FO与FS163 | 原FE真实OK、FS三ID/输入输出计数P、实际FO逐坐标P/合法EOF一致、输出对象完整及adapter empty；使用真实Sobel edge。无RC，retain不存在。 |
| 1 CANNY | 外层只向C0发CJ142：JID96/W/H各11/TL/TH各11/median1/retain0；原FP74输入，接class125及CS592 | 按C0原合同核完整CJ快照/成功flags/计数/EOF与实际输出前缀；CS reason0只是流段成功，还需精确八邻域完整闭包与完整final edge导出/对象完整。未闭合R4不可宣称整体成功。 |
| 2 CANNY_RC | 同CJ142但retain1；收class125/grad185/CS592，并以完整J/profile_ref启动后续识别 | Canny完整边缘及识别候选/拟合/核验/去重/ANN完整均需真实terminal与数量/身份检查；R3/R4实体/端口OPEN。 |

C0内部FJ始终Y_ONLY/kind0/threshold0、median来自CJ；外层不能同时另发内部FJ或消费其FS。CJ142没有algorithm/TS/profile/render，外层J保留它们而不是改CJ。正式retain=algorithm2唯一派生；独立OBS诊断CJ允许retain0/1，不能套正式CFG逻辑删掉其四组合覆盖。模式1/2虽然仅显示RGB/灰度仍按选定algorithm走完整job，不能为显示捷径跳过测试责任。单J不表示完整60Hz吞吐已证明。

流收集器在PREPARE必须准备好容量/身份，然后才能提出FJ/CJ；否则class首组可能无处保存。rawFS/rawCS独立早接、先保存真值再校身份/计数/flags，不以全输入EOF/P或显示ready门控；错身份/非法终态仍记实际fire并使外层失败，不等另一个“正确status”重发。已启用grad必须真实逐组接受；关闭grad不等其ready/EOF。原RGB provider按同J源独立重放；mode0须两遍偶行，不假装普通一次行优先流支持回到源首行。

结果成功须选定算法完整终态/完整必需平面、同J/source身份及未作废。V接纳检查旧epoch、旧algorithm_generation、旧publish_allow、完整J/planes和自身容量。same-edge C algorithm commit及V offer fire时仍依据旧资格；已实际接受的旧V是历史完整结果，不能翌沿覆写身份或反悔。offer真实fire后WAIT_VIEW_ACK先收真实ACK，不被后来的屏障改成失败；此前未移交的旧offer body不撤，屏障/取消只令后续旧publish_allow0，由消费者接纳并明确拒绝。REF归还/renderer取消具体消息及render_generation仍AC-B02/03，不能复制旧DP租约规则填空。

## E. 局部状态、中文操作草图与组合案例

### E1. KEY_OWNER与控制执行器

各键twoFF、stable/candidate1、debounce_age5、release_age5、armed1；KEY3 hold10可表示0…800，KEY1 hold11可表示0…2000，达到门槛后饱和。手势state3候选0WAIT_RELEASE/1ARMED_UP/2DOWN/3LONG_WAIT_RELEASE，其他非法进入资格隔离并报错；KEY0/2只需DOWN/UP，不自动重复。divider位宽为能表示CORE_HZ/1000−1的最小正整数；25MHz需15bit，100MHz需17bit。首次异常样本candidate/age0，后20完整间隔才stable；21高样本才从WAIT_RELEASE获得资格，旧armed0的资格提交沿不能接DOWN。消抖DOWN/UP注册后下一core沿进入手势，阈值计数包含UP资格产生的那次tick间隔；799/800和1999/2000边界按B核验，不以NBA前后差一沿偷改毫秒。

手势完成→检查旧对应key槽→可保存UI整批序号预查→复制UI101；新槽下一沿才能选最小seq。发送state2为0EMPTY/1HELD_REQUEST/2WAIT_REPLY/3RETRY_HOLD；body提出后保持，request fire后WAIT_REPLY，BUSY保留同body再提，匹配终端回复才释放借用key槽。旧full的新手势drop，不覆盖held；drop_count32用扩33bit加整批drop后饱和，overflow_sticky保持。独立reset槽满时新LONG明确记录reset_busy/drop，不覆盖旧请求；release检测仍继续。

CFG执行器UI/SET各RX1/回复1，仲裁依据旧RX与预留回复，每沿最多执行一条；两个都有则按上次服务者轮转。接纳沿只存RX，下一沿按旧D形成完整candidate、验证、比较、写D及回复；未valid不改D。KEY1普通op4始终DEFERRED/error7并回显，不toggle持久freeze状态，不形成P、不触发重算或取消。长KEY1不经过UI执行器。

### E2. D/P/C、cursor和profile

冷共同rst建立epoch1、C/D合法默认CFG、config_id0、algorithm_generation0、proposal序号/desired_revision0、来源无效、P空、cursor0/valid1。默认C只是合法初值，J/V初始valid0；没有真实结果不能报V/APPLIED。D_revision仅在完整CFG变化时推进；NO_CHANGE不推进，成功SET即使内容相同仍按algorithm/mode校cursor。NEXT先记录真实尝试，再核profile；拒绝只保留明确cursor副作用。

profile provider提供preferred_profile_ref64及实体资格；preset4用它形成candidate。非RC切换将profile_ref置0；RC要求非0并能核完整已安装实体。新路线候选要求一个软件epoch内profile实体不可变且不删除；被D/P/C/J/V引用时更不能回收，只有全部旧义务关闭后可建立新epoch注册集合。该约束不补造RC单位/数值默认，AC-B01仍OPEN。

P旧空、旧D与旧C不同、该D_revision未记永久拒绝、proposal/提交计数可分配且非quiesce时，从旧D复制P539并标该来源已proposed。P形成与新UI同沿，P仍旧D，UI只写下一D，superseded按D2合并判定。旧P valid才有提交资格；P成功时一次写C539及真实commit事件，再清P。旧P full的消费沿不同时再填新P，允许一个空泡以免版本混用。P静态非法/版本不符明确记拒绝D_revision及来源，不无限重发；单C writer正常流程不会发生外部抢改版本。相同完整CFG不分配新config_id；D回到C的同内容也不要求每个中间desired都产生job。同沿P分配最后身份而新D被接受时，两者仍按旧事实办理；后续若该D已无可分配proposal/config，记录其BLOCKED_EXHAUSTED而不回滚C/P/J，ACCEPTED_DESIRED没有承诺未来一定COMMITTED。

commit分配config_id32，algorithm改变才推进algorithm_generation32；阈值/median/render/profile内容改变但algorithm相同不推进该屏障。proposal_seq64不是旧cfg_generation，algorithm_generation32不是旧policy64，禁止截取旧字段低位直接相接；正式render_generation仍OPEN。参数变化不改旧J/V，也不停止camera或改source_handle。

### E3. JOB_DISPATCHER及取消

state4候选0IDLE/1PREPARE/2OFFER_STREAM/3RUN_STREAM/4RUN_FINAL/5OFFER_VIEW/6WAIT_VIEW_ACK/7ABORT_DRAIN/8RELEASE/9STATUS；其余非法状态报PROTOCOL并隔离，不能伪装IDLE。单J657/总term1；保存stream_request_held、stream_started、closure_started、rc_started、stream_status_seen、各final_status_seen、cancel_pending、publish_allow和对象移交/返还证据，初始全0。rawstream status按选定核保存完整FS163或CS592，不从最新端口拼后来副本。

job source实际fire时锁旧C、source_handle/W/H、分配job_frame，进入PREPARE；同沿commit的新C不混进J，首子请求/像素不穿透。PREPARE先绑定不可变profile/源及选定收集器，准备成功后下一沿提出FJ/CJ。进入OFFER_STREAM的请求保持到真实fire；接纳后stream_started才成为旧事实。cancel到来但请求已held不能撤，接纳后的后续ACTIVE沿才传cancel；若尚未提出/启动子级则只关闭已建立准备义务，不等待不存在的FS/CS。

RUN_STREAM持续接规范FP和全部必需输出，独立接真实FS/CS；观察旧CSvalid/FSvalid的沿注册source-stop并撤未接纳FP候选，真实status fire才保存原终态。正常源尾也只是DRAIN事实，不代替算法终态；metadata/输出故障先计本沿真实fire再作废后缀。Sobel成功转完整结果；Canny流段成功转RUN_FINAL等待精确闭包/识别。任何失败走ABORT_DRAIN：停止产生新输入候选，已有外部held FP保留到真实fire、上述明确source-stop例外或共同硬rst；兑现held子请求，取消已经启动子级，收它们各自真实terminal，清私有pending；不等失败流的P/EOF，也不把尚未启动子级列入等待。

配置algorithm commit后，新algorithm_generation作为下一沿旧事实与J比较；旧未移交任务置cancel_pending/publish_allow0，向已启动子级按其合法ACTIVE规则取消。同沿刚接纳旧C job先登记，后续PREPARE可在未提出子请求前取消。普通参数/颜色变化只影响后续job；旧完整结果可以采用它自己的render。manual CANCEL128精确匹配J，设同一sticky cancel；持续cancel是同一个原因，不每沿产生新义务。结果offer已held不可撤，消费者在publish_allow0或stale条件下真实接受并回拒绝；offer fire与当沿新cancel同时，依据旧资格已移交者优先结真实ACK，cancel回复TOO_LATE，不反悔。WAIT_VIEW_ACK、RELEASE、STATUS不覆写已经形成的term。

总JOB_TERM669候选=J657/outcome3/reason5/flags4，flags依次为result_transferred、stream_status_seen、final_status_seen、close_done；final_status_seen仅实际启动过final子级且所有其terminal均接受才1，Sobel未启用final为0且不等待它。outcome0完整结果已移交/1取消/2启动前拒绝/3失败/4策略过期未发布/5软件reset取消，6…7非法；reason0NONE/1CANCEL/2BAD_CONFIG/3BAD_SOURCE/4STREAM_FAIL/5FINAL_FAIL/6VIEW_REJECT/7EPOCH/8POLICY/9OBJECT_RETURN/10PROTOCOL，11…31保留。首次失败原因锁定后不改；同沿先记真实子状态/传输，再按PROTOCOL、真实子失败、reset、manual cancel、policy的固定优先锁适用首因，已真实offer fire进入移交收尾者不再受后来的cancel/policy改写。它是外层失败解释，不改变rawFS/rawCS。总term只在所有已启动子级真实结束、私有pending清空、对象已移交或真实返还后的结算沿形成，保持到fire；STATUS消费沿不接下一job。R4具体terminal/对象close_done谓词仍AC-B02/03，不以本候选位宽宣称它们已闭合。

### E4. VIEW_OWNER和软件reset

typed V与当前访问plan保持完整历史J/render，不读新D/C颜色。offer实际fire时依据旧epoch/policy/publish_allow及完整平面判断，合法且有容量复制V，生成下一沿可见ACK；stale/不允许发布则只保存拒绝ACK，不覆盖旧V。ACK独立held到消费；已有typed V结束/取消需真实renderer终态及返还，不能用当前模式或reset请求直接清valid。具体plan/对象ref/ref返还与render_generation必须由AC-B03闭合；当前V_LATCHED不是生产APPLIED。

软件RESET_OWNER state3候选0IDLE/1QUIESCE/2CANCEL_JOB/3DRAIN_CONTROL/4DRAIN_RESULTS/5COMMIT_EPOCH/6REPORT/7FAULT_WAIT。RESET96被接纳先预留receipt/done，核epoch和可推进性；epoch已FFFFFFFF时直接REJECTED/EXHAUSTED，不先取消业务。receipt只报告接纳。下一旧QUIESCE周期禁止新source job、外部SET接受、新手势保存及新P形成；继续同步/消抖/release，四旧key槽/旧RX/held回复继续结账，旧P保持并提交或明确拒绝。quiesce接受沿同一沿已真实接纳的旧job/UI/SET仍有义务，不能清掉。

对旧J发sticky cancel并按E3收真实终态；已有V请求renderer关闭并收真实terminal/返还；已经held结果offer/请求/FS/CS/reply不能单端抹除。旧UI有限队列继续按序以旧epoch执行和回复，接受desired不承诺显示；quiesce期间不再把新D形成P，最后未proposed desired明确作为reset作废记录，不能称全部已APPLIED。外部尚未fire的SET/CANCEL不属于已接纳义务，不要求外国producer撤valid才结束；新epoch后若迟到则核epoch拒绝。reset接纳后手势资格停止新动作但release计时继续，不能让一直按住在恢复后立刻再次long。

只有旧已接纳控制回复/held子请求/真terminal/jobterm/viewACK及对象返还全部结清，才在COMMIT_EPOCH扩33bit检查并推进epoch一次；RESET_OWNER只发一次reset_commit/新epoch事件，各唯一owner各自建立合法默认D/C、清P/J/V有效性、重置E5表规定的本epoch UI/SET/proposal/frame/config/desired/algorithm计数及cursor，但保留KEY_OWNER的独立reset_seq/exhausted与RESET_OWNER的最后reset缓存、重新WAIT_RELEASE，RESET_OWNER不是这些记录的第二writer。独立reset request/receipt/done及last-reset缓存保留，不被业务清理覆盖；旧已heldreceipt也不抹除。REPORT形成done136回旧请求身份及新effective_epoch，held到真实消费；需receipt/done均消费后下一沿才重新开放动作。若R4/renderer终态或返还证明未知，留FAULT_WAIT/PROOF_PENDING，可报告失败但不生成成功done、不重新开放业务，不假设超时可以清对象。AC-B02/03未闭合前本优雅reset结束不能宣称READY。

共同硬rst与上述优雅reset分开：同步高有效rst屏蔽所有fire，取消本软件域全部held/有效身份并重新epoch1；前提是所有本域producer/consumer共同reset且外部测试驱动丢弃旧run在途事务。不能仅reset单端后以epoch1接受外部旧run body。物理断电/PLL/多域暖保持不在此单core合同，最终四键长按不直接接raw逻辑reset。独立四pinOBS KEY1仍按自己的同步释放设计，不连接本手势软件reset owner。

### E5. 耗尽和具体逐沿案例

event/proposal/reset/request/desired_revision为64bit，epoch/frame/config/algorithm_generation为32bit，各唯一owner；分配/增量前分别扩65/33bit。先按下表区分当前已使用值与next待分配值，不把默认0当全部身份已经消耗。

| 计数及唯一owner | 冷共同rst / 首次分配 | 软件epoch成功切换 |
|---|---|---|
| C.config_id / CFG | 当前合法默认快照0；首次新CFG commit为1，此后按当前+1 | 当前默认0、exhausted0；下一新commit为1 |
| D.desired_revision / CFG | 当前默认D revision0；首次完整CFG变化为1 | 当前默认0、exhausted0；下一变化为1 |
| algorithm_generation / CFG | 当前0；首次algorithm改变的commit为1；同algorithm不分配 | 当前0、exhausted0 |
| proposal_seq / CFG | next0；首次P形成使用0，然后next推进 | next0、exhausted0 |
| job_frame / JOB | next0；首次job使用0，然后next推进 | next0、exhausted0 |
| event_seq / KEY | next0；首次保存UI使用0；整批按B预查/一次推进 | next0、exhausted0；仅旧队列/回复全部真实结束后重建 |
| SET request_seq / 外部producer；UI/SET expected_seq / CFG | producer从0连续提交；两receiver expected0，仅终端完成推进，BUSY/epoch或seq协议拒绝不推进 | 两receiver expected0、seen/cache重建；外部旧epoch迟到拒绝，不当新seq0 |
| reset_seq / KEY | next0；首次独立RESET使用0，然后next推进 | **保留next和exhausted**，不因软件epoch切换回0；独立槽/当前事务与last-reset缓存保留 |
| software epoch / RESET | 当前1；首次成功软件reset为2；最大值不再推进 | 每次真实旧义务关闭后仅当前+1，33bit检查无回绕 |

next类分配最大值那一次合法，随后exhausted置1，next寄存器保持最大值而不回绕；全部held收尾继续。当前值类只有当前未达最大值才可+1，分配最大值后拒下一次增量。receiver在最大seq的终端完成后置exhausted，仍允许完整last-cache同body重放，不能再接新同号body；seq协议拒绝不能毁旧缓存。next reset耗尽跨软件epoch保持，只有合法共同硬rst及旧外部run丢弃才能重建0。最大值可使用一次，再设exhausted；不通过回绕假装新身份。UI整批按B全数预查；UI exhausted不挡有资格的独立reset，reset_seq自身耗尽则只拒新reset。proposal/config/drev耗尽拒新改变CFG的命令但已有D/P/回复/终态继续；algorithm_generation耗尽仅拒需改algorithm的配置，普通同algorithm可在其余计数有空间时提交。frame耗尽禁止新job但不禁已有结果/归还。epoch耗尽禁止软件reset成功建立新epoch。所有旧收尾身份在接受时已预留，不在耗尽后再申请。

N01正常：e0 UI fire只存RX；e1执行旧D成B并形成ACCEPTED_DESIRED；e2原P空，旧D B复制P；e3旧P提交C B，若同时source job fire则锁旧C A；e4该J在PREPARE用A启动条件，新job才能用B。没有同沿新UI直接穿透到FE。

N02 P held/新D竞争：旧D A尚未proposed，e0同时P形成A和UI执行B；P永久A，D变B，回复superseded0；若无P形成，B才可superseded1/A来源。旧full key槽e0 pop仍drop当沿新手势，不把它当第五个合法缓存。

N03 profile/cursor：D Sobel/cursor3→NEXT尝试4无profile，回复REJECTED/PROFILE，D/C仍Sobel、cursor4；下一INC改TS；再NEXT尝试5并保持median/阈值/颜色，不能根据被拒cursor4改TH。STRUCT SET TL>TH整包拒绝。

N04 saturation：D Canny TH2047/TL1→INC：TH2047/TL1023，ACCEPTED_DESIRED；TH2047/TL1023再INC才NO_CHANGE。D Sobel TS0→DEC：NO_CHANGE。不得按TH单字段判断。

N05 algorithm barrier：e0 C变Sobel→Canny且旧C job fire锁Sobel；e1 PREPARE见旧policy已改变，在未提FJ前取消并返还已借源，不等FS。若FJ早已held，先真实接纳，后续ACTIVE传cancel，独立FS真实消费。若结果offer e0已真实fire，先结其真实ACK，保留历史V，不翌沿改写C/J/V身份。

N06早失败：FP中途in_bad、源未EOF，真实FS或CS提前出现；注册source-stop、停止未接纳候选，status容量独立保存真值，失败路径只等已启动子级和pending清空。已交付class/grad前缀不同合法，不补到P，不将C0分类CS0当Canny闭包成功。

N07独立reset：UI回复held下LONG2000产生独立RESET96；接纳和receipt可推进，不因UI槽满堵发；done仍必须等既有UI回复/真子terminal及返还结清。消费者永久不给ready则明确证明等待，不能称优雅reset已完成。单core停钟无计时，不能承诺旧AON行为。

N08重复/耗尽：相同UI101/body重放最后完成reply，D/cursor无第二次变化；同seq换op/key拒绝。event剩两个号但该tick可保存三UI则整批拒新，已有held继续；reset独立号有空间仍能发。epoch最大的新reset先拒绝，不制造一半cancel后悄悄回1。

## F. 语言、RTL A–L和三份映射

拟采用SV2009，同域时序非阻塞/组合阻塞，显式位宽/符号；当前无源码或编译。C++未采用，不生成指针/RAII/异常或C++映射；未来参考用独立Python离散事件/整图数值，不能复制RTL FIFO/pending实现作为唯一oracle。

| RTL项目 | 本局部契约、未知与理由 |
|---|---|
| A 数值 | D字段unsigned；阈值先12bit，drop33bit、seq65bit、代次33bit检查。UI饱和，身份不回绕；原灰度16bit单舍入，R3 profile数值OPEN。 |
| B 时钟/观察 | 单core posedge，读取旧sync/旧槽/旧C；GPIO twoFF；TB未来在更新稳定后观察，1ms enable不造新clock。 |
| C 接受/交付 | RX接受先预留独立reply，次沿执行；P形成/commit/job_used/V_latched真实事件分开，CS/FS早接独立。 |
| D valid/推进 | 无效不改D/身份/数量；GPIO手势计时不因业务busy冻结；case EOF不当成功、valid0不当0平面。 |
| E 反压/保持 | key借用槽、P、request/reply、V offer、jobterm及rawstatus各held不覆盖；取消只控制合法后续资格，不擅自撤held请求。 |
| F 延迟/吞吐 | UI接收→执行→P形成→提交/子启动分沿，例N01；无固定配置到显示帧延迟。单J/有空泡是正确性候选，生产吞吐须R5优化并验证。 |
| G 复位 | 同步高有效共同rst屏蔽fire/清有效性；软件reset先quiesce/真终态/返还再epoch，CORE停钟无独立送达承诺；图像RAM不靠清零证明释放。 |
| H 配置 | 完整CFG212/C539；job同commit沿旧C；算法屏障32独立；历史J/V全快照，正式render_generation衔接OPEN。 |
| I 存储 | 四key1、sender1、UI/SET RX/reply各1、各last-cache1、D/P/C1、J1、各子status1、jobterm1、V/offer/ACK1、reset各1及last-reset-cache1、live/read1。有界FF候选，实际总FF/图像对象容量/RAM端口由后续冻结。 |
| J 身份 | JID96映射原FJ/CJ，source_handle独立源身份；lane0低、原FP共同x_even/y及标志保持；render source/display坐标与mode0两遍访问不混。 |
| K CDC | 只有raw key单bittwoFF；配置/任务当前同域，不逐位同步CFG212。最终多域/GPIO电气/reset释放/HDMI FIFO尚AC-B04。 |
| L 实现 | Ti60F225/I3及既有工具是目标，不新增安装/网络；四键top与OBS四pinreset top分别设计。实际时钟/pin/资源/PNR/STA及完整60Hz全NOT_RUN，不继承独立OBS预算为全机预算。 |

共同数值/行为契约：独立参考依据完整CFG和离散合格手势算出变化/拒绝/DEFERRED；数学参考独立计算灰度/Sobel/Canny/识别，原P/R≥95%目标和场景分布依整包，不恢复撤回尺寸/噪声硬界限。

硬件执行契约：沿前fire、旧容量/旧C、held不变、注册消抖/长按边界、首请求/首像素分沿、子终态/对象返还证据；软件函数调用顺序不能当这些沿的证明。

对应契约：按完整epoch/seq/body比UI/SET终端回复；按JID/source_handle/全CFG及真实job_used/V_latched对齐图像和配置；被取消job比较真实已交付前缀/真实status/作废后缀，复位后旧epoch不得重解释。逐位配置和像素比较，无隐含误差；最终识别质量需独立完整数据集，typed V/CRC不能代替。

## G. 未来验证与实施计划（全部NOT_RUN）

先闭合AC-B01…05并与重放/R4/R5新版本组合、实际保存读回/审阅，纳入统一批准；后在整体已指定work范围生成key_front、config_owner、algorithm_dispatcher、selected stream adapters、software_reset_owner、control_observer及独立参考/协议/整图测试。本文未创建这些业务文件。实施后局部→R1/C0组合→R4/重放→生产集成/工具，bit后停止。

| TEST | 目标/输入与事件 | 期望、方法及通过边界 |
|---|---|---|
| AC-T01 | REQ01/IF01；20与21同样本、反向采样、启动一直低/恢复按住 | 20完整间隔才stable/armed，资格提交沿不接DOWN；25/100MHz参数均真实1ms，逐沿参考；NOT_RUN |
| AC-T02 | REQ01/07；KEY3 799/800、KEY1 1999/2000及边界UP/一直低 | short/long互斥，仅一次、释放不再短；LONG独立reset，op4仅DEFERRED且D/P/C/J/V不变；NOT_RUN |
| AC-T03 | REQ04/IF02；同tick四键/旧full+pop/UI reply held/LONG | 顺序KEY1/3/0/2、最小seq发送、整drop/sticky/饱和，reset有独立容量；BUSY同body保持；NOT_RUN |
| AC-T04 | REQ02/IF02/03；TS/TH端点、TH2047/TL1、TL>TH/algo3/mode6/7 | 12bit饱和/全CFG NO_CHANGE，非法整包拒绝不改D/C，错版本拒绝；NOT_RUN |
| AC-T05 | REQ03；8preset/median两态、RCprofile缺失/完整SET表外模式 | cursor4拒绝后5可达、±基于D；合法SET匹配/失配cursor规则，preset与SET show策略不同；NOT_RUN |
| AC-T06 | REQ02/04；P形成与新D同沿、P held连改、commit+job | P旧内容/合并superseded正确、同沿J旧C、来源不覆盖；逐沿body/身份比较；NOT_RUN |
| AC-T07 | REQ05/IF05；algorithm0/1/2及独立OBS retain四组合 | FJ110=Sobel/TS；CJ142=Y_ONLY由C0内部唯一发FJ，正式retain0/1派生；诊断不误削；class不是final edge；NOT_RUN |
| AC-T08 | REQ06；algorithm commit+job、held FJ/CJ cancel、提前FS/CS、持续cancel | 后续旧ACTIVE取消、真实rawstatus不改、已启动才等terminal，失败不等P/EOF，无第二owner；NOT_RUN |
| AC-T09 | REQ06/IF06；result offer held/同沿policy或manual cancel/迟到ACK/旧V | heldbody不撤，旧资格移交者历史保持；之后publish_allow0/stale明确拒绝，ACK真值不反悔；返还细节待AC-B03；NOT_RUN |
| AC-T10 | REQ04；同seq重复/换body/早旧seq/wrongepoch/UI和SET轮转 | 当前/last重复同结果无副作用、换body拒绝不毁缓存、BUSY不完成；有限公平及回复容量；NOT_RUN |
| AC-T11 | REQ04；各64/32计数首号/最大值、UI批所需超过剩余、epoch最大reset及软件reset后独立reset_seq保留 | config/drev/algorithm首增1、next类首号0；最大一次/no wrap/整批拒新，旧收尾继续、reset独立且其next/exhausted跨软件epoch保留；epoch耗尽先拒无半取消；NOT_RUN |
| AC-T12 | REQ06/07；reset receipt快/旧UI/P/FS/CS/jobterm/V归还慢，reset接纳沿旧jobfire、启动前拒绝与同body重复reset | 旧承诺保留、done只真关闭后新epoch、重复只重放两回复不二次推进、拒绝无quiesce；无ready报告等待不成功、CORE停钟不冒AON；R4/renderer实际谓词OPEN；NOT_RUN |
| AC-T13 | REQ05/IF06；RGB/finaledge/ANN错ID、缺平面、原色/灰阶、mode0双遍/held像素变外部CFG | V锁历史render，原gray/ANN优先/requiredmask正确；独立暂停重放，无一entry活流tap；重放完整合同OPEN；NOT_RUN |
| AC-T14 | REQ04/IF09；live变化但read held，迟到旧V/jobterm/resetdone | 原子held不变/live更新、观察不阻业务，ACCEPTED/COMMITTED/USED/LATCHED不冒真实APPLIED；NOT_RUN |

测试将来NBA后观察真实fire/字段；每项局部与组合互补。环境消费者最终给ready是有界队列的活性前提，故意永久不消费用来检查等待/不伪成功。无可执行TB/脚本、种子实测、功能/工具结果。

## H. 双向追踪

| REQ/来源 | MOD/IF/中文步骤 | 计划稳定符号/文件类别（未生成） | TEST与当前证据 |
|---|---|---|---|
| AC-REQ01/CONTROL B2/E2 | KEY，IF01/02，E1 | key_front / sync2、candidate_age、armed、hold_elapsed | T01…03；纯来源+本文设计，NOT_RUN |
| AC-REQ02/CONTROL D2/E2 | CFG/J/V，IF02…06，E2/E3/N01/N02/N04 | config_owner / desired_snapshot、proposal_hold、committed_snapshot、job_snapshot | T04/T06；未实现 |
| AC-REQ03/CONTROL B2/D1 | CFG，IF02…05，E2/N03 | preset_cursor、profile_ref、formal_retain | T05/T07；profile实体OPEN |
| AC-REQ04/有限状态派生 | KEY/CFG/RESET/OBSERVE，IF02/03/08/09，E1/E5/N08 | request_hold、reply_hold、last_request、counter_exhausted、atomic_observation | T03/T06/T10/T11/T14；未实现 |
| AC-REQ05/R2-REQ08/BATCH | JOB/V，IF05/06，D3/E3 | algorithm_dispatcher、sobel_adapter、c0外部adapter、complete_result_offer | T07/T13；R4/重放/完整结果OPEN |
| AC-REQ06/原FE/C0与CONTROL E2 | JOB/RESET，IF05…08，E3/E4/N05/N06/N07 | cancel_pending、publish_allow、raw_stream_status、close_done | T08/T09/T12；R4取消/terminal/归还OPEN |
| AC-REQ07/用户A3边界 | KEY/CFG/RESET，IF02/08，E1/E4 | deferred_reply、software_reset_phase；独立top划界 | T02/T03/T12；DEFERRED不是FREEZE通过 |

反向：key_front只实现采样/手势/容量；config_owner只实现完整desired/proposal/commit和来源；dispatcher只选择/拥有job与真终态；reset_owner只协调本软件域关闭及epoch；observer只复制事实。像素/对象/RC模块只能在对应重放/R4设计闭合后纳入，不能借本控制草图合理化额外器件或无观察算法。

## I. 门槛及评审

①整体行为/样例见B/E5；②职责/复用见C；③字段/容量/相容见D但AC-B01…04仍OPEN；④状态/旧沿中文草图见E；⑤语言和三份映射见F；⑥正常/竞争/失败走查见D3/E5；⑦验证/追踪见G/H；⑧无当前阻塞不满足；⑨本稿保存后由实际全文读回/hash报告登记，尚无独立新稿全组合审阅；⑩v0.2纯设计范围/来源明确，但不是冻结整包。

因此NOT_READY，父R2-B03/B05及整包不能关闭。无需在未READY时询问用户泛化批准。当前无用户对本版本实现范围/基线的明确批准，无正式Manifest/数据库登记；正文场景不是已跑测试。

## J. 变更和恢复

旧纯手势/数值/preset/full snapshot规则保留；旧UI133去CDC session形成新UI101，新增独立SET404与status3 DEFERRED，不兼容直接接旧UI274。旧FM cfggen/policy/rendergen及旧物理source/授权/lifecycle不继承；新C539/J657/V788的逻辑身份和source_handle须与相邻新设计组合，不截低位冒用旧字段。

v0.1实际内容已同hash保存为[原稿快照](design-TRACK4-ALGORITHM-CONTROL-001-v0.1.md)。v0.2根据独立数值审阅补E5当前值/next分配表、首号/最大值及软件epoch重建/保留范围；E4按该表明确reset_seq/exhausted保留，T11扩展对应场景。旧hash的审阅不能自动当本修订已通过，新稿须实际全文读回及修订复核。

本稿提出单core唯一CFG owner与外层dispatcher；C0内部owner不改，独立OBS/R1 top不改。R3/R4/renderer终态及render_generation闭合后需修订本文相关字段/状态/TEST并再次全文审阅，不能依据本v0.2直接实施。恢复读A实际来源/最新相邻版本/当前OPEN/授权，核同沿oldC、held及reset不能单端清承诺。

## K. 实录

本轮只读来源、文字设计和按明确授权新增本文。未生成业务RTL、功能脚本、参考模型、可执行测试/TB/工程/SDC；功能仿真、综合、PNR、STA及bit全NOT_RUN。无安装、网络、器件调查；原HDK、其他设计、正式状态/Manifest/数据库不改。本文字段、状态、案例与资源结构均是设计分析，不是软件运行或硬件证明。

## L. 阅读与下一步

整包B/C/D→R2 B03/OP06→本文B外部规则→C唯一owner→D字段/容量/映射→E1手势→E2 D/P/C→E3 job/cancel→E4 VIEW/reset→E5具体沿→F/G/H→A/I OPEN。改变按键看T01…03；阈值/preset看T04/05；配置快照看T06；子核映射/取消看T07…09；耗尽/reset看T10…12；显示重放看T13/AC-B03。

下一允许行动是与R3/R4及RGB重放/typed renderer新稿组合，冻结完整terminal/对象归还/render_generation及四键生产边界，再补共同基线与独立审阅。用户理解验收待实际反馈，不把讲解当已理解，也不据此阻塞当前已授权设计工作。
