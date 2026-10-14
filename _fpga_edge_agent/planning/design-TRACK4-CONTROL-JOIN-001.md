# TRACK4-CONTROL-JOIN-001：配置、冻结恢复与平台控制联合合同 v0.1

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)建立；2026-10-04；**LOCAL_DESIGN / NOT_APPROVED_FOR_IMPLEMENTATION**。本稿收敛CONTROL、FM、DISPLAY、CAMERA及PL之间的控制接口，明确覆盖下列旧候选差异，旧文件/hash保留历史。这里不是另一个十一功能工程，也不生成代码或可执行测试。

## 通用计划字段

- Goal：关闭控制交接中的关键歧义：独立反向恢复入口、COMMIT/ABORT承诺、持续snapshot与阶段槽、有界配置关联、策略门和历史active、AON复位唯一owner。
- Current state：主计划v0.13、49份MD文档检查通过；十一项业务实现、仿真、PHY校准、综合/PNR/STA/bit均未运行。旧CONTROL中的无条件ABORTED存在与held COMMIT相冲突的表达。
- Target state：本范围的每个控制阶段有明确接受/效果/收尾和容量；同源结果配置可追踪；不因UI慢读/停钟/等待首源死锁。
- Gap：本稿CJ-B01…06列剩余父数据路径/恢复/RC实体/工具证据/批准阻塞；只把已明确的控制合同作为联合候选，不称整机READY。
- Assumptions：预设V4 Ti60F225/I3、SC431HAI、AON25/core100/pair74.25；实物检查在bit之后，不是软件工作的前提。
- Open questions：全机真实FF/RAM/QoS/CDC/STA、受保护PHY/相机接口、识别数值实体；既有两项申请仍待答，不重复请求。
- Dependencies：A所列真实SHA、根v0.2、01来源、DDR scope及原有保持域合同。
- Milestones：J0实际读父稿→J1联合行为/接口→J2中文阶段走查→J3剩余联合合同与源依赖闭合→READY/指定批准→实现/真实验证。
- Detailed steps：B/C整体→D每接口/位布局/相容→E局部中文步骤→F语言→G/H验证追踪；[阶段附件](../experiments/track4_full_sw_20261004/04_local-designs/control-join-phase-sketches-v0.1.md)补反例。
- State transitions：本稿LOCAL_DESIGN，无实现批准，无正式状态/DB变更；未达到READY不得业务写入。
- Artifacts and hashes：本稿、阶段附件、[实际评审](../experiments/track4_full_sw_20261004/05_reviews/control-join-review-v0.1.md)及本轮审计；旧CONTROL审计另存原字节历史。
- Validation：CJ-T01…24文字场景，全部NOT_RUN。只读事实/字段算术/文档读回不是仿真。
- Failure handling：已提出消息兑现，未知排空Q；BUSY可重试、静态非法结账、旧会话不重放；没有timeout强清引用。
- Human approval gates：当前只授权文档/只读分析；全部正确性条件满足后指定版本/实现范围/基线批准。硬件人工闸门保留。
- Rollback：只处理本联合稿及附件/索引差异，保留旧父版本/来源/历史审计；不改原HDK、工具、正式状态。
- Completion criteria：控制合同与父数据/恢复合同一致、真实实现/验证；整个目标仍是五基础＋六高阶单一工程到bit/hex，本范围完成不替代目标。

## A. 范围、基线与剩余阻塞

关联MOD-04/11/12、T4-A2/A3/A5/A6、UC-05、DER-03/09。用户继续完整软件实验的授权不等于批准本新设计。旧候选的合同只在本稿明确覆盖处由联合版本替代；尚未覆盖的数据路径仍按原设计，不凭“联合”二字推定全部吸收。

| 输入 | 实际SHA256 |
|---|---|
| CONTROL v0.1 | A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6 |
| FM v0.1 | D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| DISPLAY v0.1 | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 |
| PLATFORM v0.1 | 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 |
| CAMERA v0.1 | F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C |
| 四键来源v1 | 6FCE325A30B1B514CB6D461BD03512891A04E1B400F0957FD7FDBDFBA6F2A9DA |
| 旧CONTROL审计 | FC6351DB1D5C5403FB8474E1B8C0BD3398C3F000477D71D98ECCC6BA909B26D8 |

源码/IP/source字节基线沿主计划及manifest，以上是设计输入SHA，不伪造commit。根v0.2/模板及正式状态hash本轮重核未变。

| BLOCKING | 正确性或实施缺口/影响 | 关闭办法 |
|---|---|---|
| CJ-B01 | 完整source/result/scope、CAM live绑定、DDR stage/grant、ROW/SELECTED/CLOSED与镜像/关闭端口未最终联合，影响J01/03/05/06 | 整机联合端口版本实际吸收本稿；验证有界lookup、借用及新旧policy |
| CJ-B02 | RC profile实体/精度/默认/完整job与95%适用范围未冻结，影响J01/06 | 独立数值/识别设计与范围评审；profile_ref不能掩盖未知 |
| CJ-B03 | CORE/UI/DP阶段保持、PL PREPARE/FINAL及冷初始化原语/真实停钟恢复仍缺实现证据，影响J04/05/07 | 按具体保持表和新域mask实施验证，不以摘要或cal_done代替 |
| CJ-B04 | DP serializer/相关clock、CSI错误归属/RAW位序及真实2Gb模型/PHY兼容仍未验证，影响完整目标 | 已有工具/模型获取批准及匹配材料，真实仿真，不替换成简易存储或假校准 |
| CJ-B05 | 完整FF/RAM/行期限/采集尾期限/CDC/STA与引脚生成未运行，影响J05/07及性能 | 获批后真实工具结果；本稿容量是已列容器而非利用率 |
| CJ-B06 | 新范围尚未无阻塞/READY、无指定实现批准、正式H0/DB未验收 | 依既有规则与申请推进，不能由Agent自行授权 |

当前可独立继续控制/联合设计；硬件到货、下载与实机不属于本次软件前提。

## B. 整体行为与八项要求

| REQ | 外部规则及来源 |
|---|---|
| CJ-J01 | CT02/03：D是期望、P是held proposal、FM C是committed；三结果各自拥有业务快照。接受/预留/采用/APPLIED分别观察，不为每个配置建立永久等待 |
| CJ-J02 | CT05：FREEZE等待首源时RESUME有独立CORE→FM入口，既不等T完成，也不被held SET/P挡住；已接受反向R不可合并丢弃 |
| CJ-J03 | CT04/05与held契约：COMMIT未提出才可转ABORT；COMMIT一旦valid必须兑现，T真实成功/失败后R恢复，不无条件报ABORTED |
| CJ-J04 | DP冻结：持续anchor/snapshot/barrier与一个阶段request/ACK槽分开；SNAP接受即阻apply，ABORT可在没有snapshot/首源前封口，已exposed结果仍兑现 |
| CJ-J05 | DP/FM策略：当前gate policy与历史active J.policy分开；重复旧合法图保留RO，不能改历史J/早FREE，也不能把控制ACK当DDR排空 |
| CJ-J06 | FM/CAM：配置在结果/PROCESS预留并形成不可变job之前锁定；LIVE在首SOF前完成FJ，不能在后来SOF改参数。冻结源重处理新结果可有新C，原Origin不变 |
| CJ-J07 | PL/CT：四键唯一AON输入；长KEY1请求kind1/mask1FFE/reason0，AON保持。CORE停钟可送达，不保证缺证据的优雅复位完成 |
| CJ-J08 | 有界/身份：唯一seq分配、两lane首次visible登记、T/R与阶段独立回复、慢观察不反压APPLIED/退休/返还；跨语言与验证分别记录 |

正常N1：C更新＋旧job已held→旧job实际接受用原ctx；新result预留才锁新C；JOIN完整新结果→DP实际APPLIED→FM完整ID查三ctx原快照→观察更新。没有source6业务cfg历史表。

N2：FREEZE已经SNAP ACK但未VSYNC→R独立接受→ABORT封口尚未提出snapshot→T ABORTED→R PREP/COMMIT→LIVE资格；不等首源。N3：FREEZE_COMMIT已valid→R保存→旧COMMIT及snapshot ACK真实闭合→T APPLIED或真实错误→R恢复；旧body不改。N4：CORE时钟停止、UI/P满→AON长KEY1独立PL117送达；缺排空证据只pending/Q，不清scope/held。

## C. 职责与连接

CONTROL普通P lane→CJ-IF01 FM CONFIG/primary T；独立R lane→CJ-IF02 FM INTERRUPT；FM三result cfg ctx→CJ-IF03 FE/Canny/CAM/DP关联；FM↔CJ-IF04 DP stage914/ACK920；DP↔CJ-IF05 snapshot1353/ACK1359；CJ-IF06是stage op3/4的policy_target198；FM/DP真实事件→CJ-IF07最新观察；raw keys/PL↔CJ-IF08 AON117/123。

| MOD | 职责/拥有者与划界 |
|---|---|
| CJ-CONFIG（MOD-04/12） | CONTROL保存D/P，FM唯一分配C身份；result ctx保存不可变C570，不让source camera cfg表达三结果业务配置 |
| CJ-LIFE（MOD-04） | primary T、反向R、branch、预留S/V、FREEZE引用和真实parent done；不控制视频RAM或替代DDR证书 |
| CJ-VIDEO（MOD-11） | gate/anchor、snapshot-hold、stage/snapshot回复；实际active属于video，core影子不能冻结 |
| CJ-IDENTITY（MOD-04/12） | 首次visible登记/有限pending与完成cache、配置到现有结果完整ID关联；无无限历史表 |
| CJ-AON（MOD-12/PL） | raw key/LED唯一owner、独立reset序号/117，平台epoch/恢复由PL持有 |

整体检查点：先给B/C可见行为和分支/反馈，再D/E。新方案自写/适配现有候选；不复用raw KEY1直接reset。共享数据算法、DDR调度、CSI、TMDS仍各原模块负责。没有第四结果、额外源图或简化Canny。

## D. 八个接口、布局和组合检查

### D1. 共用约定与八IF

普通消息valid/ready，上升沿前共同1才fire；旧容量判断，不默认同沿空穿透。提出后body稳定到fire。transport ACK只是接收保存；下表的业务ACK在指定逻辑效果完成后返回。除有明确编号外整数unsigned，原CFG212、SOURCE_UI134、C570、SourceOrigin195、J486、ID687及scope623保持含义。

| IF | 明确字段/方向/范围 | 接受、拥有与结束 |
|---|---|---|
| CJ-IF01 | CONTROL→FM primary605及reply1182，沿CT；op0SET/1FREEZE/2稳定RESUME/3REPROCESS/4QUERY | 一个held P；SET只commit/结账、不等每cfg显示；FREEZE接纳预留T605、receipt1182/done938、S号与阶段资源。已无live T的稳定FROZEN恢复走此lane；不能凭actual LIVE忽略已提出FREEZE |
| CJ-IF02 | CONTROL→FM R669=RESUME605/parent_T_proposal_seq64；receipt1246=原669/status2/error5/C570；done1002=原669/status2/error5/actual2/origin_valid1/Origin195/policy64/cfggen64 | 独立发送/接收/receipt/done；同epoch/session且parent seq命中live FREEZE T，expected policy=T目标policy。独立ready不依赖primary P/T完成；错/已永久关闭父明确REJECT/OLD，不永久BUSY。R接受即绑定T及分支，不能后续改parent |
| CJ-IF03 | FM result ctx→job/lookup：cfg570/valid1，每物理result3份；采用引用full J486/slot2/gen64/job_seq64 | result/PROCESS预留沿锁旧C；JOB/FE实际fire只报告已锁ctx采用。LIVE_BIND438/FJ110必须首SOF前成功；无result仅capture，不保存业务cfg。ctx到result终态、所有显示/旧消息/借用关闭才释放 |
| CJ-IF04 | FM↔DP：统一stage_request914=header227/body687，stage_ACK920=原914/status2/error4 | 仅一个未结阶段request/ACK；anchor持久独立，不占入口等待COMMIT。op/body规范见D2；ACK唯一完成消息，无未定义第二control done。snapshot/channel/ROW/APPLIED/关闭各独立 |
| CJ-IF05 | DP→FM SNAPSHOT1353（沿DP原字段）；FM→DP SNAPSHOT_ACK1359=原1353/status2/error4 | 独立私有收槽/回复；FM保存完整body和anchor/hold关联后ACK，ACK不解除hold。不等FREEZE T done才消费。ABORT分支收到已exposed snapshot只保存/ACK，不新建FREEZE |
| CJ-IF06 | stage op3/4的TARGET198=kind2/origin_valid1/Origin195；原语义425=header227/TARGET198 | kind0RESUME_LIVE、1ALGORITHM_KEEP_LIVE、2ALGORITHM_KEEP_FROZEN、3非法；kind0/1要求valid0/Origin0，kind2要求valid1并等已绑定frozen Origin。PREP与COMMIT目标一致，不拿裸RESUME释放算法切换中的冻结 |
| CJ-IF07 | FM/DP→观察：最近USED1057=valid1/J486/C570；最近APPLIED1322=valid1/ID687/scan64/C570 | 最近状态值副本，不持图像租约；live更新与held读响应分开，UI/LED慢读不能反压APPLIED业务ACK/退休/返还。查询三ctx必须在旧引用关闭前完成或先复制值 |
| CJ-IF08 | CT-AON↔PL reset117/receipt123/done123；KEY0 C4/KEY1 P13/KEY2 N13/KEY3 A3，LED0 N14/LED1 P14 | key_LONG仅kind1、mask16=0x1FFE、reason3=0 USER_KEY_LONG，expected_epoch真实；AON唯一reset_seq。raw只入同步器，旧LED0心跳driver替换为单一状态owner；J5配置复位独立 |

SOURCE_UI、完整proposal/epoch/session/parent key不能由槽号、seq0或低32bit推断。R key的epoch/session来自原605，parent_T_seq另64；禁止跨会话命中。primary/R只有各一个私有槽，已接受R留到自己的done1002消费及阶段闭合；更晚UI期望只在本地尚未提出意图合并。

### D2. stage914固定包装和实际效果

header227=control_seq64/op3/expected_policy64/new_policy64/epoch32。body687从高到低存以下有效字段，剩余低bit规范0；不能用不确定值填padding。业务status2：0APPLIED/1ALREADY/2BUSY/3REJECTED；error4沿DP/PL约定，另由联合端口版本命名OLD_ANCHOR/SEQ_BODY/POLICY/TARGET，不借截断实现未列错误映射，完整最终error枚举仍CJ-B01。BUSY无逻辑效果、不存“已完成”。

| op | body有效字段/低padding | 完成ACK920的具体谓词 |
|---|---|---|
| 0 SNAP | body全0；原语义227 | 保存S anchor和p0→pF，apply BLOCKED、gate.current_policy=pF已提交。只证明保存/阻apply，不证明snapshot或源FREEZE |
| 1 FREEZE_COMMIT | Origin195/zero492；语义422 | 匹配保存S/p0→pF及FM已建FREEZE的Origin；gate为FROZEN(pF,O)、hold解除。旧1353若已exposed，其ACK1359须实际被DP消费后才形成COMMIT ACK。NO_ACTIVE允许FM选完整源；不凭COMMIT证明输出/DDR排空 |
| 2 FREEZE_ABORT | snapshot_S64/zero623；语义291 | V→S匹配、关闭anchor、drop snapshot hold、apply仍BLOCKED、gate保留pF；未exposed snapshot永久禁止产生，已exposed1353兑现且ACK1359被消费。无需等VSYNC、首源、ROW/fence |
| 3 POLICY_PREPARE | TARGET198/zero489；语义425 | 保存V及旧policy→pN/目标；gate.current_policy=pN、BLOCKED已提交，新候选apply关闭。逻辑效果完成，不要求旧active/scope已FREE |
| 4 POLICY_COMMIT | 与PREP一致TARGET198/zero489 | 核保存PREP上下文而非再要求current=旧policy；LIVE(pN)或FROZEN(pN,O)资格已提交。与VSYNC同沿不新apply；下次合格VSYNC才可选候选 |
| 5 CANCEL_OFFER | ID687，无padding；原语义914 | 匹配candidate，取消选择资格已提交；实际读/行/scope排空另沿DP OWNERSHIP_TERMINAL/return，不把此ACK当CANCELLED_DRAINED |
| 6 STOP | 全0；原语义227 | sticky禁新offer/apply/row扩展，旧已proposed及正常收尾继续；scope是否drained另有证据 |
| 7 | 非法 | 整body拒绝，不改gate/anchor/hold |

SNAP同video沿VSYNC：基于沿前已保存控制输入的实际stage fire/旧anchor，SNAP优先于candidate apply；采沿前active，已有active保持BIND。尚未发生业务fire的运输中SNAP不是已可见控制，较早实际应用的candidate之后按真实active查询。ABORT与尚未形成snapshot的VSYNC同沿，ABORT优先，封口后不新形成1353；已有valid1353绝不撤回。

SNAPSHOT业务ACK不是FREEZE_COMMIT。COMMIT可先提交逻辑效果，ACK等待旧snapshot通知关闭；FM等待此ACK时仍独立消费/ACK1353，不能因T等ACK而停旧snapshot路径。持续anchor直到COMMIT/ABORT效果和通知关闭；阶段槽在每次ACK消费后可进入下一阶段，不等整个SNAP事务完成。

### D3. S/V、policy与可信seq登记

FM接纳T时预留S64；正常(op0,S)→(op1,S)。接纳R时预留V64及全回复容量，取消分支(op2,V,snapshot_S=S)→(op3,V)→(op4,V)，正常COMMIT已提出分支不发op2，等T真实终态后(op3,V)→(op4,V)。S/V由FM唯一DP事务分配者，预留前65bit核耗尽；收尾共用已预留号，不在ABORT/恢复时再申请。op续阶段核保存关联及完整body，不能因换op重新接纳任意旧seq。

SNAP将g:p0→pF并BLOCKED；COMMIT核anchor原p0/pF，不再次要求g==p0。ABORT不回滚到p0，仍g=pF BLOCKED；R PREP将g:pF→pR BLOCKED，COMMIT核PREP原pF/pR。FM T接纳分配/提交policy pF；R接纳预留pR、完整body条件按接纳时核验，旧T结清后启动R才提交FM policy pR。普通CFG字段可更新，不回写已接受R的expected版本或回滚参数。算法切换同类policy事务保留LIVE/FROZEN目标；PROCESS_SAFE与DP COMMIT均成立才开新计算资格。

CONTROL唯一proposal_seq allocator只在提交held valid时分配，不先领小号却延迟visible。FM保存两lane首次visible完整body（非业务接受，不建FREEZE/更改C），同沿先登记两个body再推进global_seen；旧较小P已登记可在较大R先fire后重试。未知旧号OLD；BUSY保留pending登记、不写completed；每lane current/pending/last complete有界，跨lane仍live/last同号错body拒绝。更早已忘记录不重新执行，不声称无限历史回放。该合同只接受可信唯一CORE发送者；非法sender/会话拒绝。每阶段DP同样仅当前/最近关闭事务的合法重放返回已有结果，更早OLD无副作用，不存无限完成表。

### D4. gate、旧active与有限cfg

active full_scope/J.policy是历史执行身份，不能因g改变覆写。新candidate要求J.policy等g且目标mode/Origin合法；旧active已合法者可重复，保留旧RO/BIND并按新控制gate作本次路由决定。PLAN.policy是形成计划时的gate快照，SELECTED.policy是实际决定时gate；控制跨入后两者可不同，匹配要求是target token/plan_generation/route完整ID及资格，不能无条件比较policy相等把历史current撤权。既有future预取义务必须用SELECTED未选/discard正常结清；当前exec不被未来gate更新撤权，CLOSED仍按原ctx引用关闭。

三result各C570+valid1=1713bit。source6只有camera cfggen/Origin和BIND_R0…2，不另存一个会被重处理覆写的业务cfg。LIVE在预留result/PROCESS并形成LIVE_BIND438/FJ110之前锁C，首SOF到来仅证明这个已准备绑定被采用；晚来的SOF不能改已held/已fire FJ。无result时仅存源，后来DDR重处理用新result预留时的C。DDR job也在形成不可变proposal之前锁C；实际job_fire报告采用已锁快照。同沿C提交与result预留用旧C；与旧held FJ fire同沿也不改旧字段。原“在真实SOF/FJ时重新锁当前C”的模糊表述由本段替代。

APPLIED1503的完整ID查现有三result保存的C570，OFFER.source_cfggen仍是camera配置。观察复制值后不持租约，迟到旧APPLIED不回写D/C；无法匹配完整旧ID明确协议错误，不查询无界config_id历史表。

## E. 数据、状态与八项中文操作草图

### E1. 状态与十不变量

FM持T605、R669、各自receipt/done、branch、S/V及policy预算、FREEZE位、result3 C570；CONTROL持P/D及两个发送lane；DP持anchor S、target/PREP V、一个stage槽/ACK槽、snapshot通知/ACK和hold；AON持raw键/资格、reset117/回复及seq。空槽valid0，无origin规范0；历史图像不清零充空，Q保持独立。

| INV | 规则与保持理由 |
|---|---|
| CJ-I01 | P/已accepted T/R/已valid stage body不可改；R只绑定完整父T |
| CJ-I02 | COMMIT已valid则兑现真实终态，只有未提出可选ABORT |
| CJ-I03 | R的ready/receipt/done不依赖P/T完成，容量预留才接受 |
| CJ-I04 | 持久anchor不占stage入口；snapshot与stage通知/回复独立 |
| CJ-I05 | ABORT封口未exposed通知，已exposed通知履行；无首源也可关闭 |
| CJ-I06 | FREEZE先由FM建立再COMMIT，hold最后移交；恢复只撤FREEZE，不清BIND |
| CJ-I07 | g与历史J.policy不同；旧合法RO可重复，新结果须当前资格 |
| CJ-I08 | result各C570不可变、source camera配置独立；晚SOF/FJ不改快照 |
| CJ-I09 | UI慢读不堵APPLIED/退休/返还；seq预留/注册有界无回绕 |
| CJ-I10 | rawKEY只入AON，private reset不清保持承诺；未知隔离不FREE |

**CJ-OP01 首次visible和接纳。** 以旧两lane登记/回复容量看新valid，校唯一seq/epoch/session及父key；登记仅保护重试身份，不执行业务。按实际fire分别保存primary/P或R，形成固定receipt。接纳T/R前分别预留S/V、policy预算与自己的done槽。更大R先fire不抹较小已visible P。拒绝静态非法结账，BUSY保留原pending供容量恢复重试。

**CJ-OP02 结果配置与LIVE预备。** 看旧空result及PROCESS/源资格，原子锁旧C570/来源和完整J；后续job/LIVE_BIND只引用此ctx。先授权PROCESS/FJ再ARM/首RGB，若首SOF前不合格则只存源，不半帧补接。后续UI参数只更新D/C；同源新job预留另一结果保存新C，不改原源或旧C。job实际fire记录USED，不能重新取当前C。

**CJ-OP03 SNAP接受和实际快照。** 向video发(op0,S)并保持。video真实业务fire原子阻apply、存anchor和g=pF，ACK920逻辑保存成功；若合格VSYNC已有，则优先取沿前active，否则等待后续VSYNC。形成1353时pin旧结果BIND下hold，core持续接收并保存完整通知、核anchor及移交/丢弃用途后即可回1359，不等FREEZE建立、latest或首COMPLETE。该ACK只关闭通知，DP持续hold不因此解除。正常分支随后FM根据真实Origin增FREEZE；NO_ACTIVE从旧latest或随后COMPLETE选完整源，缺源进入WAIT_FIRST而不占通知回复。候选/源完成不是snapshot本身。

**CJ-OP04 接纳R与分支。** 独立R669 fire绑定T，关闭尚未提出旧策略扩展。旧COMMIT已经valid（含未fire）则branch=FINISH_COMMIT，绝不撤回；还未valid则branch=ABORT。R与首个source COMPLETE同沿，ABORT优先禁止新FREEZE/COMMIT，COMPLETE/LATEST正常登记。已接纳FREEZE无论SNAP是否首次提出，都先兑现(op0,S)至成功保存ACK（status APPLIED/ALREADY且完整效果匹配），使video的pF/BLOCKED真实成立，再用V/S发ABORT；R早于SNAP时也不越过这一步。branch提交后不可因后来首源到达改回COMMIT。

**CJ-OP05 COMMIT与ABORT终结。** 正常FM已真实FREEZE后发COMMIT，video核anchor/Origin并转FROZEN、释放hold；业务ACK须旧snapshot通知已ACK关闭，FM仍消费其独立通道。成功T done938 APPLIED；错误按真实FAILED/Q。ABORT则封口：尚未提出1353永不再生成；已经valid者持续交付，core按ABORT状态保存/ACK不加FREEZE，video等该ACK且hold归还才发成功stage ACK。ABORT保持BLOCKED/g=pF、不等首源/VSYNC/DDR全部空；FM撤仅属于取消T的临时FREEZE（若已建且无COMMIT承诺）并形成ABORTED done，保留所有BIND。 若SNAP/COMMIT/ABORT被拒绝、失钟或效果不明，不能假定video已到pF/BLOCKED；T按真实FAILED/QUARANTINED结账，已接受R也保留独立FAILED/QUARANTINED done义务与原身份，未知引用隔离，不执行猜测的pF→pR恢复。已held旧成功终态不改；后来故障用独立live故障及R结果记录，恢复只经PL可信证据流程。

**CJ-OP06 policy恢复/算法切换。** 只有成功SNAP屏障以及成功ABORT或正常COMMIT封口的真实效果证据成立、T真实done交付且旧stage/snapshot闭合，才将R移交为正常执行记录；不能把FAILED/Q done当此证明。用V发PREP(TARGET0 LIVE)，g=pR/BLOCKED；shared processing engine的旧任务实际terminal/local borrow归还形成PROCESS_SAFE，不等历史active图scope全FREE。发同V/同target COMMIT，video提交LIVE，VSYNC同沿仍不新apply。FM消费成功ACK后按target分支：kind0撤对应旧FREEZE，开合法LIVE新ARM/job/publish并形成R done1002 APPLIED；kind1保持LIVE且没有FREEZE可撤；kind2保持原FREEZE位及完整Origin，只开该冻结源的离线新job/publish，不开LIVE ARM。旧BIND保护历史screen。RC profile无效则不启动该新策略。PREP/COMMIT拒绝或失钟转明确FAILED/Q独立终态与隔离，不伪称LIVE；PROCESS_SAFE完整端口尚CJ-B01。

**CJ-OP07 观察与迟到。** 实际job/APPLIED按完整结果ID取原C570，复制最近USED/APPLIED；释放局部metadata借用后不再阻结果回收。UI读取held快照停顿，live仍更新；不反压父业务ACK。迟到旧消息只命中有限current/last登记或明确OLD，不用当前C答旧APPLIED，不改历史policy。阶段失败/Q固定终态不被恢复改为成功。

**CJ-OP08 AON reset与暖保持。** raw四键只进AON同步/消抖，KEY1 LONG形成kind1/mask1FFE/reason0/真实epoch，独立117不用CORE/UI空槽。PL receipt只是保存；停新业务但旧tail/held/fence/借用继续，无法证明排空保持pending/Q。mask bit1…12覆盖业务域，bit0 AON和13…15排除；CSIcontrol12与core1同clock为逻辑隔离位，不虚构第十三新clock。保持D/P/T/R/阶段/回复/seq与引用账本，PL身份PREPARE/FINAL及旧会话闭合后才清，private reset不抹held；新的手势重新WAIT_RELEASE。旧LED0 driver替换，LED1唯一观测owner，不把灯当drain证据。

## F. RTL与跨语言合同

RTL/SV2009候选、既有Efinity2026.1.132/Questa2024.1。没有C++实现，RAII/异常N/A；未来独立事件参考需批准后生成。共同参考合同是离散消息/身份/容量/逻辑效果；硬件执行单独定义fire、旧状态、CDC、warm保持；软件结果对应真实(epoch/session/seq/op/full ID)事件，不能以参考函数返回代替实际ACK或PHY校准。

| 项目 | 约定/限制 |
|---|---|
| A 数值 | unsigned全宽，R669/1246/1002、stage914/920、snapshot1353/1359、target198；seq65/policy65/id33预查，padding0不截断身份 |
| B 时钟 | core100 FM、pair74.25 stage/snapshot、AON25 reset；不同域在各自posedge，未来TB NBA后观察 |
| C 接受 | 首次visible登记不是业务fire；每lane valid&&ready才保存/执行，transport ACK与业务效果分开 |
| D 推进 | 无valid不执行；持续anchor和UI/状态无数据气泡仍可推进关闭；无法clock不能自证 |
| E 反压 | 各held body保持；独立R、snapshot及回复避免互等；已valid COMMIT不能取消 |
| F 延迟 | SNAP保存不等VSYNC，snapshot等合格VSYNC或ABORT封口；跨域/DDR/PROCESS_SAFE无固定1帧延迟 |
| G 复位 | PL控制私有rst，持久seq/held/引用为保持域；旧session两端关闭，Q不自动FREE |
| H 配置 | 预留result/形成job前锁C；scope历史与gate资格分开；同沿用旧C、不能改held FJ |
| I 存储 | 三result配置1713bit；T/R数据5642bit（605+669+1182+1246+938+1002），普通P/reply1787bit；stage914+920+1353+1359=4546bit每套原body容器，运输端副本/valid/phase/缓存另计；不是全机FF利用率 |
| J 身份 | full J486/ID687/Origin195/SourceUI134及S/V/parent key，不能只靠config_id/slot查历史 |
| K CDC | 多位完整稳定mailbox/独立回复，保留session/pending；异步raw只同步首级；相关video clocks不被全局false path |
| L 实现 | 无新PLL/DSP/图像RAM；容器可共享稳定ctx但需生命周期证明，不能重复/漏算；真实FF/RAM/CDC/pin/STA仍CJ-B05 |

恢复后的allocator不能因private reset回绕；冷初始化及epoch变化的具体原语/保持实现仍CJ-B03。mask1FFE按PL已读bit表，不改camera/DDR电压或物理频率。stage envelope是否用ctx稳定值拼接而减少FF属于以后实现选择，必须保证同原914/920逐位一致与保持。

## G. 实施与验证计划（NOT_RUN）

先CJ-B01…06相应依赖/接口闭合、与旧差异表共同冻结→READY/指定批准→独立work实现cfg_result_registry、fm_lifecycle_join、video_control_stage、proposal_registry、aon_reset_adapter及独立参考/TB→局部/父/完整回归→真实工具/bit。只有计划名，无源码。

| TEST | 输入/初始/事件及目标 | 期望与观察/通过标准 | 状态 |
|---|---|---|---|
| CJ-T01 | primary P较小seq BUSY、R较大先fire | 登记P仍可重试，不按最后fire大号拒绝；CJ-J02/08 | NOT_RUN |
| CJ-T02 | 两lane同沿首次visible、seq冲突/错body | 先全登记后水位，冲突整包拒绝，不业务接受 | NOT_RUN |
| CJ-T03 | source同Origin连续三result不同C | 三快照不变，source camera cfg不被替代 | NOT_RUN |
| CJ-T04 | 新C与result预留同沿、旧held FJ同沿fire | result锁旧C，held FJ不改；逐CORE沿观察 | NOT_RUN |
| CJ-T05 | LIVE FJ已准备/未准备、随后SOF/参数更新 | 采用已锁ctx；未准备仅capture，不半帧补接 | NOT_RUN |
| CJ-T06 | APPLIED旧ID/C、UI held读取不ready | 正确三ctx关联，迟到不回写C，返还链继续 | NOT_RUN |
| CJ-T07 | SNAP fire与VSYNC/candidate同沿 | 阻apply、快照沿前active，较早apply者按真实active | NOT_RUN |
| CJ-T08 | R早于首次SNAP，或SNAP保存ACK后未VSYNC就R | 均先兑现SNAP至pF/BLOCKED，再ABORT封口未exposed1353；不等首源/VSYNC，T ABORTED | NOT_RUN |
| CJ-T09 | snapshot1353已valid未交付、ABORT | body兑现/ACK1359闭合后ABORT ACK；hold无遗失 | NOT_RUN |
| CJ-T10 | snapshot已交付、FM未建FREEZE时R | ABORT不新建FREEZE，旧Origin保护/通知闭合 | NOT_RUN |
| CJ-T11 | NO_ACTIVE＋首COMPLETE＋R同沿 | R禁止新COMMIT/FREEZE，COMPLETE/LATEST正常记录 | NOT_RUN |
| CJ-T12 | FREEZE_COMMIT valid但ready0时R | COMMIT不撤，真实T终态后R恢复，不无条件ABORTED | NOT_RUN |
| CJ-T13 | COMMIT效果完成但snapshot ACK1359迟到 | 完成ACK920等待通知闭合；FM持续消费snapshot | NOT_RUN |
| CJ-T14 | 已held T done，R及后来freeze意图 | 独立R保存，done不覆盖，只有未提出意图合并 | NOT_RUN |
| CJ-T15 | 错parent_T/epoch/session、已关闭父R | 明确OLD/REJECT无副作用，不永久BUSY | NOT_RUN |
| CJ-T16 | SNAP g已pF，重复COMMIT原p0/pF | 核anchor成功，不因g!=p0错误拒绝，不双移交 | NOT_RUN |
| CJ-T17 | ABORT→PREP g:pF→pR→COMMIT | V/S关联/target保存，ACK不等旧scope FREE | NOT_RUN |
| CJ-T18 | FROZEN中algo切换target2/非法target0误用 | target2保Origin，普通algo切换不能解除冻结 | NOT_RUN |
| CJ-T19 | policy g改变、旧active J旧p、PLAN旧g | 合法repeat RO不撤，新candidate过滤；未选义务关闭 | NOT_RUN |
| CJ-T20 | POLICY_COMMIT与VSYNC同沿 | 本沿不新apply，后续完整合格VSYNC才切 | NOT_RUN |
| CJ-T21 | seq/policy耗尽、收尾S/V已预留 | 禁新业务，旧ABORT/COMMIT/ACK/done仍可完成 | NOT_RUN |
| CJ-T22 | CORE停钟/P/UI满、KEY1 LONG | AON117送达，mask1FFE；receipt不报drain，缺证据Q | NOT_RUN |
| CJ-T23 | 私有rst/旧stage/两个回复/旧会话，SNAP或恢复阶段拒绝/失钟 | 保持身份；无pF效果证据不正常PREP，T/R独立FAILED/Q义务；旧held终态不改，旧消息不重放新epoch | NOT_RUN |
| CJ-T24 | 错padding/op/Origin、CANCEL ACK而R仍在途 | 拒绝错包；逻辑取消不冒充scope排空/FREE | NOT_RUN |

独立参考与RTL/CDC/真实PHY各验证自己的范围；当前只有场景文字，没有可执行模型、种子、波形、仿真或工具报告。

## H. 双向追踪

| REQ/来源 | MOD | IF/OP/INV | 计划位置 | TEST/实际 |
|---|---|---|---|---|
| CJ-J01 CT配置 | CONFIG/IDENTITY | IF01/03/07、OP01/02/07、I08/09 | cfg_result_registry | T01…06，未实现 |
| CJ-J02 CT恢复 | LIFE | IF02、OP04/06、I01/03 | fm_lifecycle_join | T01/08/11/14/15，未运行 |
| CJ-J03 held承诺 | LIFE/VIDEO | IF04/05、OP04/05、I01/02 | 同上/video_control_stage | T09…14，未运行 |
| CJ-J04 DP冻结 | VIDEO | IF04/05、OP03/05、I04/05/06 | video_control_stage | T07…13/16/24，未运行 |
| CJ-J05 policy历史 | LIFE/VIDEO | IF04/06、OP06、I07 | 同上 | T16…20，未运行 |
| CJ-J06 FM/CAM快照 | CONFIG | IF03、OP02、I08 | cfg_result_registry/父绑定 | T03…05/18，未运行 |
| CJ-J07 PL/AON | AON | IF08、OP08、I10 | aon_reset_adapter | T22/23，未运行 |
| CJ-J08 有界身份 | IDENTITY | IF01/02/05/07、OP01/07、I01/03/09 | proposal_registry | T01/02/06/15/21/24，未运行 |

每个计划符号承担表中要求，不把命名当已生成实现。后续实际代码版本/符号/证据按本表填入，反向能找到REQ/契约/场景。

## I. 门槛与评审

整体行为/样例、职责、接口/布局、中文旧状态草图、A–L、场景及追踪已按本文组织；具体保存/读回/评审以05真实记录为准。CJ-B01…06仍影响实现，⑧无当前阻塞不满足；当前不标READY、不请求该版实现批准。旧父稿与本文联合差异尚未成为生产端口或代码，批准manifest/DB无新增登记。

## J. 明确覆盖的旧约定与恢复

| 旧候选位置 | 本联合版本的纠正 |
|---|---|
| CT D2/OP06无条件T ABORTED后R | 已valid COMMIT必须兑现真实T结果；未提出才ABORT |
| CT R605/公共P | 独立R669带parent key、receipt1246/done1002，不被SET held堵住 |
| DP一次未结有序控制/control done未知 | 持久anchor独立；每阶段914/920真实效果ACK即唯一done；snapshot1353/1359独立 |
| DP裸RESUME op3/4 | 带TARGET198的POLICY_PREP/COMMIT，可保冻结算法切换 |
| FM/CT在真实SOF/FJ重新选C的歧义 | result/PROCESS形成不可变job前锁C；真实SOF/FJ只报告已有绑定采用 |
| 原PL raw KEY1/旧LED0 owner | 四键归AON、reset117 type1/mask1FFE/reason0，LED唯一状态owner |
| 全局最后fire水位/无限cfg历史暗示 | 首次visible有限登记；三result快照lookup、最新观察，无无限表 |
| g与active历史policy相等假设 | 新candidate查g，历史current RO可重复；PLAN形成/SELECT决定gate可不同 |

若接口、target、序号、暖保持、相邻数据/关闭改变，先更新本联合范围和受影响父设计再评审批准，不直接实现。恢复读本稿/阶段附件/旧基线hash/最新审计/实际授权，不能凭聊天摘要误把候选当已批准。

## K. 实现和验证实录

只有只读父稿/来源复核、候选字段/容量算术、文档写入/读回/评审。业务实现/TB/功能脚本、仿真、真实PHY、综合、pin生成、PNR/STA、bit/hex、网络下载/安装、数据库/正式状态写入均NOT_RUN/未执行。文档检查不能支撑整机或功能通过。

## L. 阅读与交付

主计划整体→B/C本范围→D每lane/字段/policy→E八操作→[阶段附件](../experiments/track4_full_sw_20261004/04_local-designs/control-join-phase-sketches-v0.1.md)→G/H及05实际评审。改恢复先CJ-J02/03/04与T08…17，改配置去J01/06和T03…06，改平台去J07/T22/23；随后联合父接口，不先修改active/C或旧scope。

本轮交付联合控制候选与明确旧差异，完整十一项、模型/工具依赖、资源/时序/质量、真实bit/hex仍未交付。用户理解验收待真实读回/作答；设计解释不等于已理解或运行通过。
