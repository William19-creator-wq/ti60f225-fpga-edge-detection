# TRACK4-DDR-SERVICE-001：共享DDR事务、授权与排空设计 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)编写。**LOCAL_DESIGN / NOT_APPROVED**；MOD-05局部候选，不是受保护IP已有保证。本文只有设计、中文操作草图及文字场景；业务源码、功能脚本、testbench与所有构建未生成/未运行。

## 通用计划字段

- Goal：让采集、显示、源帧读取、结果写入、完整Canny及识别共享真实DDR，保留身份、授权、段终结与安全归还。
- Current state：系统03逻辑交接、FM v0.1、Canny v0.4存在；实际v6主设备格式已查，匹配2Gb模型/真实PHY及protected核心未验证；本服务尚未实现。
- Target state：完整接口/有限状态/存储/仲裁设计及真实物理证据闭合后READY，获指定批准后实现并通过协议、器件/PHY和整机验证。
- Gap：真实可见性、物理并发/响应、校准/恢复、父授权端口及采集显示期限仍BLOCKING；见DS-B01…08。
- Assumptions：生产1920×1080、同core目标100MHz；物理128bit、ID4；本候选每方向最多一条物理burst，每client/方向最多一条逻辑live。物理读写并存须实际验证。
- Open questions：实际protected行为与2Gb模型、platform保持域/校准安全证明、识别工作图和时限/QoS。
- Dependencies：现行v0.2、V4实际v6、既有工具/审批、FM/Canny及MOD-01/03/09/10/11。
- Milestones：来源→整体外部行为→授权/数据/物理交接→有限缓冲与逐沿→组合审查→实际依赖闭合/READY→批准→真实验证。
- Detailed steps：B/C整体→D接口与差异→E八项中文草图→F语言/时间→G/H验证追踪→I门槛。
- State transitions：当前LOCAL_DESIGN；没有新的实施批准，不进入IMPLEMENTING。
- Artifacts and hashes：原24与FE28输入不改；v6 SHA45DEC999…6B19C、RAM模型SHA DD8DB451…1A33；完整值及路径在01基线与新增RAM来源页。
- Validation：DS-T01…16全部NOT_RUN；文档/算术只读审查另记05。
- Failure handling：可证明排空则失败归还；不可证明则冻结旧上下文/缓冲/授权，不以超时、epoch或清账本造drained。
- Human approval gates：本稿尚有阻塞，不请求实施；既有FRONTEND实现和官方模型获取申请继续待答。
- Rollback：仅新增本稿/实验说明；原HDK、FE/FM/Canny冻结文档、正式状态/数据库不改。
- Completion criteria：正确物理行为、完整权限/终结/恢复及有限服务期限闭合，获批实现并完成真实软件验证；设计文件不能替代整机bit/hex。

## A. 状态、边界与来源

关联T4-A3/A4/A6、DER-01…08，补系统IF-04/05/07/09/11/12/13。服务只负责DDR访问、授权验证、完整段缓冲、物理/逻辑账本、fence与归还证据；不分配最终源/结果所有权、不检查图像算法、不发布bundle、不操作硬件。

先读[整体02](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)及[系统03](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)，再对照[FM v0.1](design-TRACK4-FRAME-MANAGER-001.md)、[Canny v0.4](design-TRACK4-CANNY-001.md)、[MC-M01存储附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-memory-sketches-v0.3.md)及[父任务/writer](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md)。实际来源为[DDR调用链/B/R限制](../experiments/track4_full_sw_20261004/01_baseline/ddr-address-and-completion-evidence-v1.md)、[时钟/复位](../experiments/track4_full_sw_20261004/01_baseline/platform-clock-pin-evidence-v1.md)、[20bit RAM模型](../experiments/track4_full_sw_20261004/01_baseline/ddr-service-ram-evidence-v1.md)。

旧master不检查B、RID/RRESP，不能直接改名复用。WRITE success后读可见、完整AXI行为及安全复位均为本任务要求，尚非原IP已证事实。当前设计不扩展FRONTEND批准范围，也不把总目标当刚生成的版本批准。

## B. 整体外部行为

每个客户端先取得可兑现permit，再提出一段请求；req实际接受后独立返回成功、可排空失败、明确取消或隔离通知。写段收齐全部逻辑W后才能提出AW；读段AR前预留完整容量，物理整段核验成功后才输出逻辑R。物理调度拥有者与等待客户端消费的逻辑上下文分别保存。

| REQ | 行为与来源 |
|---|---|
| DS-01 | DER-01/03：每段完整scope/grant/tag/序号归属；错误句柄不解引用或释放其他对象 |
| DS-02 | IF-04：byteaddr32、128bit全16B、1…64拍、16B对齐/不跨4KiB，扩宽校验容量/授权/padding |
| DS-03 | A3：完整预收W、AW/W保持与真实B核验；末W不等于完成；成功必须满足后续读可见 |
| DS-04 | A3：AR前完整R容量，物理接收独立于客户端ready；ID/RESP/COUNT/LAST核验后有序返回 |
| DS-05 | DER-04/05：有限缓冲、逐client返回容量、eligible公平；客户端停顿不占物理锁或堵另一client返回 |
| DS-06 | DER-06/07：已提出valid不可撤销；取消/复位真实握手照记；drained0隔离至实际安全恢复 |
| DS-07 | IF-05/11/12：producer_close/银行封口→最后实际请求→服务seal→物理/逻辑/本地借用收敛→完整scope fence，之后才返授权/发布 |
| DS-08 | DER-08：记录真实延迟/事务/资源/服务曲线，验证源池/显示期限，不把RR机会或理论带宽当达标 |

正常样例：RGB源最后一个段的W收齐→AW/W/B成功→terminal及segment_release→采集封口fence→FM核验完整帧并COMPLETE→显示/处理只读grant→逐字节读取同源图。不能在末W时提前授权读取。

边界样例：地址低0xFF0/nbeats1合法，nbeats2跨4KiB非法且不发AR/AW；有效scope/phase内已授permit的非法地址请求仍有实际接受记录与失败terminal；无效scope/phase在prepare获DENIED，不伪造它的段或fence。W不能早于req_fire。零拍、错grant代次、整拍padding越权限同样拒绝。取消在AWVALID提出且READY0时仍须保持；仅“AW未握手”不够取消物理段。整段R收齐但客户端只消费m拍后取消，actual_beats=m，不能用物理拍数替代。

没有真实源/结果或无目标算法列表不是内存错误；合法全零数据照常交付。业务取消有独立原因，不冒充RESP。当前不承诺任意无限DDR/客户端停顿下仍无欠载或下一SOF必有空槽。

## C. 模块职责与整体连接

同core控制/配置，数据路径：
FM可信绑定→DS-CONTEXT(scope/grant/permit)→DS-LOGICAL请求与终态→W完整池→写scheduler→AXI AW/W/B；
读scheduler→AXI AR/R→R完整池→各client独立返回槽→terminal/release；
封口/fence与平台恢复横向核对所有账本，不占物理锁等业务。

| MOD | 职责、拥有状态与不负责事项 |
|---|---|
| DS-CONTEXT | 16scope/32grant与14固定client方向record；核验绑定/区间、permit与序号预算；不替FM确认引用 |
| DS-WPOOL | 七条20bit RAM条带、W收集/封存、物理两输出槽/pending；不以client停顿反推AW撤销 |
| DS-RPOOL | 独立七条20bit条带、AR容量/物理接收、逐client两返回槽/pending；不把错误物理拍当像素 |
| DS-AXI | 独立物理读/写owner，完整地址/数据/响应保持与校验；不截虚拟tag为ID4 |
| DS-FENCE | 最多32个(scope/client/phase)子账本；每scope同一时刻一个封口控制live，各阶段独立计账及归还；不占物理锁，不清账本造安全 |
| DS-RECOVERY | 平台安全证明匹配、错误冻结及恢复回报；不自动复位protected IP或自行假cal_done |

自写的是以上候选服务；实际protected DDR/PHY保持原接口，EFX_RAM10按已查模型模式复用，未生成新代码。整体设计检查点是本稿B/C→D/E；当前仍待实际物理与相邻端口证据，不进入代码。

## D. 接口、字段与组合检查

### D1. 类型、客户端与存储授权

所有非另注明字段unsigned，同core正沿valid&ready。payload提出后保持，字段无效/越范围先拒绝，不截断后使用。

client3：0 CAPTURE、1 DISPLAY、2 FRAME_READER、3 RESULT_WRITER、4 CANNY、5 RECOGNITION、6 DIAG；7非法。生产0…5，DIAG只在明确诊断模式及独占SCRATCH授权下用。每client/op1方向固定record_slot4={client3,op1}，合法0…13；每个record从permit到segment_release ACK消费仅一条live。

region3：0 CLASS、1 QUEUE、2 GRAD、3 EDGE、4 RGB_SOURCE、5 RECOG_AUX、6 SCRATCH、7非法。Canny client4仍只0…3；DISPLAY/FRAME_READER不得写；CAPTURE只写已授源；RECOGNITION只读完整source/edge/grad，AUX具体布局未冻结前不授；DIAG不访问生产图像。

| 类型 | 完整字段/预算及归属 |
|---|---|
| J486身份 | 三ID各32；source_slot3/gen64、result_slot2/gen64、workspace_slot1/gen64；capture_sequence/job_sequence/policy_generation各64。完全复用Canny job身份部分，不复制47bit业务配置及384bit四描述符 |
| scope_key623 | handle(scope_slot4/gen64)=68、kind2（0 CAPTURE/1 PROCESS/2 DISPLAY/3 DIAG）、binding_mask3（source/result/workspace）、J486、parent_lease_sequence64。mask仅说明当前持有的source/result/workspace租约；PROCESS/DISPLAY保留完整历史J身份，mask0不授访问；CAPTURE/DIAG确实不适用的字段按kind规范0。序列0本身可合法 |
| grant241 | grant_slot5/gen64、scope_handle68、client3/region3/perm2（R1/W2/RW3；0非法）、base32/logical_bytes32/physical_bytes32。端点先扩33，不把logical长度作为整拍权限 |
| permit_handle68 | 固定record_slot4/gen64；prepare锁完整请求头并保留req服务序号预算、数据槽或拒绝邮箱。grant/parent代次不由permit替代 |
| req_header198 | scope_handle68、grant_handle69、tag16、phase2、op1、region3、byteaddr32、nbeats7。实际req另带permit_handle68，总266bit |
| service_seq64 | 每次实际req_fire在全局单一接受仲裁器分配，1…最大值单调，0仅“无已接受请求”；不回绕，非physical AXI ID |

同源跨scope比较SourceOrigin195=source_slot3/gen64+epoch32+frame_id32+capture_sequence64；冻结重处理可改变job/config/policy，不能要求采集与处理J486全部相等。每个scope内部完整J及parent_lease_sequence仍严格不变。

16scope容量候选含最多6个源写会话、3个显示会话、1个串行处理/识别会话和1诊断会话，其他余量不自动授权并行任务。该峰值依赖FM当前角色界和处理独占，仍须整机证明。32grant暂按这些会话的分区读写需求配置；新增识别工作图/多处理核时重新核算，不隐藏扩大。

静态地址表从[1080p候选](../experiments/track4_full_sw_20261004/01_baseline/canny-candidate-address-arithmetic-v0.4.json)派生，小图独立计算。grant必须与实际FM活跃绑定、region/object slot/gen、固定映射和COMPLETE/WORKING资格对应，不接受“消息携带base便授权”。Canny CLASS/QUEUE RW只给唯一拥有者，GRAD/EDGE交给消费者前停止旧writer并关闭/归还旧写grant；source读只在写scope安全结束且FM COMPLETE后建立。多RO重叠只允许相同对象/代次；活跃写权限不与别的grant重叠。

### D2. 八个交接卡

| IF | 方向/字段与前提 | 保证/保持/生命周期 |
|---|---|---|
| DS-IF01 | FM↔scope/grant控制：open/close及完整body/handle，binding_check携J486/四描述符，ack携scope_key/匹配/结果/错误；仅可信FM控制端口；cancel_scope携scope_key623/cancel_sequence64/origin3/cause2 | 旧槽空/代次未耗尽才建立，核验失败不动他人对象；关联permit/record/fence/return未结时不释放。实际FM证明端口仍DS-B04 |
| DS-IF02 | client↔prepare/permit/return：prepare头198、permit68/接受或拒绝准备结果、未提出归还 | 每client/op独立prepare/permit/req端口及一个record，共14叶请求；首个req_valid可见沿另记proposed，不等req_fire。未proposed且本沿req_valid0才可返permit；held请求不可返作“未启动” |
| DS-IF03 | client↔req/W/R：每client/op独立req266；W tag16/index7/last1/data128；R同字段加error3 | W最早req_fire后；数据ready依旧容量和仲裁，不依本沿错误反馈。实际逻辑握手先计；R正常数据只来自整段成功校验 |
| DS-IF04 | service→terminal及client→segment_release | terminal携完整handle引用、tag16/seq64、kind2、success/drained、error3/actual_beats7；独立不可变邮箱。release携同scope/grant/permit/tag/seq/phase及local_drained1，独立ack为RELEASED/NO_MATCH/NOT_READY/QUARANTINED；实际terminal及服务/客户端pending/held拍结清后才回RELEASED，ack消费前record不可新授 |
| DS-IF05 | service↔protected物理AW/W/B/AR/R | address32、ID4固定0、LEN8=nbeats−1、SIZE3=4、BURST2=01、WSTRB16全1；RID/BID/RESP2/LAST必须核验，BREADY/RREADY独立客户端反压；真实IP行为仍BLOCKING |
| DS-IF06 | parent/client↔seal/fence/checkpoint/close | 完整scope、phase2/token64、client_mask7/region_mask7/dir_mask2、read/write_grant_mask各32、kind2（CHECKPOINT/CLOSE_GRANTS/CLOSE_SCOPE）；先停止新增/结清permit及req，捕获最后实际接受水位，再等规定终结/release |
| DS-IF07 | platform↔safe_init/fault/recovery：安全就绪/校准、完整旧scope集及恢复序列；服务回不可变fault及独立recovery_done | stream rst不撤销物理valid或清账本。只有平台证明真实物理排空、端点/CDC旧消息终结及引用归还后恢复；原隔离通知不改成成功 |
| DS-IF08 | service→诊断/资源/期限观察：物理/逻辑计数、等待/服务周期、owner、错误/校准快照，饱和计数另有overflow | 不用诊断数值当授权/排空。精确记录采集容量失败、显示欠载、业务取消和DDR错误，实际指标获批后测 |

error3与MC-M01对齐：0 NONE、1 ACCESS、2 RESP、3 COUNT_LAST、4 TAG、5 CALIBRATION、6 RESET_PROTOCOL、7 INTERNAL；原B/R码与位置另存。terminal kind2：0 OK、1 FAILED_DRAINED、2 CANCELLED_DRAINED、3 QUARANTINED。kind0须success1/drained1/error0及逻辑数量nbeats；kind1 success0/drained1/error非0；kind2 success0/drained1/error0且匹配明确scope取消，原因在cancel_ack保存；kind3 success0/drained0且不终结段。现有Canny需新增kind解释，不能把error0取消当成功。

### D2a. 取消、终态与阶段控制的补充字段

prepare/req冻结为7client×2方向的14个叶端口；端口固有client/op必须与头和permit record_slot匹配。全局每沿最多一个req_fire，14叶RR；不在stall期间换op或payload。W和R数据仍各7端点。receipt_seq64仅在对应req_fire采样。

terminal完整旁带是scopeH68/grantH69/permitH68/tag16/seq64/phase2/kind2/success1/drained1/error3/actual_beats7，共301bit；release加local_drained1而无终态字段，共288bit，ack另带status2/error3。不可变身份字段共享原record保存，不另复制整份body；kind3通知冻结自己的actual快照，后续live计数另存。

cancel只从可信FM控制口进入，body为scope_key623/cancel_sequence64/origin3/cause2，共692bit；origin0FM、1Canny、2Capture、3Display、4Recognition、5FrameReader、6Platform，7非法；cause0用户、1模式/策略、2源失效、3父任务取消。ack回原body+status2/error3，共697bit；status0APPLIED、1ALREADY、2TOO_LATE、3NO_MATCH。完整scope/lease匹配后才置取消并停止新prepare；错消息只回错，不解引用坏scope。已接受相同cancel_sequence/body回ALREADY；seq相同但body不符视为错误且不改记录。此沿旧req/W/R/terminal/release真实握手照记，已有效terminal不改；已授permit继续兑现。功能rst的未启动段用kind1/RESET_PROTOCOL，不凭空造普通取消来源。

phase_open锁scopeH68/client3/phase2/token64/read_mask32/write_mask32及精确已安装grant集合；grant与scope由phase引用pin住。CHECKPOINT/CLOSE_GRANTS使用一个明确client/phase；CLOSE_SCOPE核验该scope全部客户/阶段已经封口及全部grant/record关闭，不用单个phase2代表所有客户。phase/scope账本的累计计数和sticky错误保留到各自归还；原阶段结果消费不擦除父scope曾失败的证据。控制消息均保持到实际接受，最终FM端口仍DS-B04，不能假装旧接口已支持。

### D3. 对现有相邻稿的必要差异

旧Canny/FM正文及FE输入本轮不改；以下是下一统一版本必须吸收的候选，不宣称现在可直接接线：

| 相邻点 | 必须补入的契约 |
|---|---|
| MC-M01 | prepare/permit/proposed、完整grant/scope、seq/kind、独立segment_release；tag仍在本地保持至本段借用返还 |
| Canny父阶段 | stage只暂停所选grant，不关闭整个PROCESS scope；OUTPUT覆盖EDGE写和CLASS导出读，GENERAL/NO_WEAK均须排这些读，NO_STRONG无需伪造读 |
| Canny writer/cache/queue | “提出段继续完成”指协议合法终结；物理AW/AR valid尚未提出可取消terminal，已提出则完整物理排空；父local terminal必须在实际release后形成且不等fence |
| FM源完成/退役 | completion消费、末W、epoch均不返租约；scope close的fence/release证据与采集/显示本地FIFO/像素流水关闭共同成立 |
| grant移交识别 | Canny旧写授权关闭/归还后才授识别只读，PROCESS scope可继续存在；最后读fence和消费者本地归还后才解除workspace |
| 系统IF-04/CC-10 | 全拍/缓冲/机会公平与真实期限分别记录；诊断范围不自动开放生产图像 |

端到端反例：若req_ready等待W收齐且W不得早于req_fire，两边永久互等；因此请求先接纳到预留record。若fence关闭整个job scope后C8继续CLASS读，则导出越权；本稿保留阶段checkpoint与最终scope close两种行为。若一个共享R输出槽被Canny停住，DISPLAY会饿死；本稿逐client独立返回槽。

## E. 局部状态、不变量与中文操作草图

### E1. 有限存储与寄存预算

R/W池各7块20×512，前6条连续20bit、末条8bit+12零，地址9={slot3,beat6}；每池8段/8192B载荷，两个独立1R1W池总14 RAM10。整字WE=11，OUTPUT_REG=0正沿读后下一沿capture；不清RAM数组，不依同址碰撞语义。

R每client两128bit保持槽，RAM read pending全局一个但grant预留具体client/slot；容量计valid+reserved/pending。W物理两128bit保持槽加一个read pending。至少数据寄存7×2×128+2×128=2048bit；索引/valid/预留/控制另计。Rready低只占该client槽，不占其它client返回容量。

完整scope固定字段16×623=9968bit，按每entry32个20bit字（640bit容器）线性存入1块20×512 RAM；scope gen/状态shadow另存FF。32grant×241=7712bit保留FF以支持prepare快速验证；14record各预留640bit FF，完整身份引用scope不在每段复制917bit。

最多32个(scope/client/phase)子账本，必须在阶段open前预留；冷record640bit=32个20bit字，bank=phase_slot[4]、地址={phase_slot[3:0],word5}，共2块20×512 RAM。冷记录只存scope_handle68及token/阶段/冻结结果，完整scope_key623只存在前述scope RAM，不能复制623+token64到640容器。热FF保存mask/累计计数/最后接受及首错误seq、目录/状态和引用；总容器每entry384bit、32entry为12,288bit，详细字段/冷口顺序见E1a。数据ready不经过整块scope/phase串行读。scope影子、控制邮箱、14record、pending等另核，未当实际XLR。

因此数据池14块加身份/阶段metadata3块共17 RAM10，Canny44+服务17=61 RAM10（23.828125%）；先前58只含数据池。大字段cold读需保存owner/word/index且下一沿capture，query/control完成后再开放状态，不能读半初始化记录；同址禁止。scope payload组装输出后保持到消费；待引用期间该cold记录不覆盖。平台/相机/显示/识别仍另计。

### E1a. 冷/热元数据与生命周期草图

scope RAM地址={scope_slot4,word5}；每623bit identity放640bit容器，高17位固定0。scope代次/状态/引用及累计scope证据由FF shadow保护，cold只在完整安装后可查询。phase冷字段预算518bit（含scopeH68/token64/client3/phase2/close-kind2、read/write mask64与client/region/dir mask7/7/2、两计数快照128、cutoff/首错误seq128、封口/终态flag与错误/取消/raw响应旁带），余122bit保留0。phase热核心381bit（mask64、两计数128、两seq128、scope-slot/client/phase目录9、state3/error3、flag16、kind/cause4、permit/held/live计数各4、cold借用3、terminal-error/cause-mask11），余3bit保留。16个热flag分别为valid/has_req/first_error_seq_valid/seal_requested/local_quiesced/snapshot_pending/snapshot_committed/certificate_valid/certificate_consumed/success/drained/counts_final/cancel_seen/grant_pin_held/cold_busy/parent_close_requested。所有引用计数先合并同沿增减再扩宽检查，不回绕；phase/slot代次的旧引用未尽时不得复用。

phase_open先预留cold entry与grant引用，验证scope/client/phase、bitmap与token，再逐字写冷字段；CREATE期间不接其prepare。每bank一读一写，单一有限冷控制器保存entry/word/purpose/owner/pending；写入/快照/查询统一仲裁，RE保存bank/slot/word/原scope/token与目标组装槽，下一沿capture；同址时不发RE，不靠碰撞模式。查询/输出借用期间不得覆盖cold entry。data路径使用prepare锁定的phase_slot5和热记录，scope gen核验由已pin的grant/FF shadow提供，不能逐拍扫描623bit冷对象。

terminal_count定义为已实际消费RELEASED ack的请求数，terminal_fire只置record的terminal_seen，physical_done另存；不能拿terminal_seen当归还。release最早在terminal_fire下一沿，使用旧terminal_seen。accepted/terminal/release/cancel同沿按每个phase和scope合并提交，不让后一个更新覆盖前一个。两方向同phase终态均计；first_error保存最小出错service_seq，has_req/first_error_valid分别判断0值。未结segment、未兑现permit、cold pending和输出借用都保持引用。grant mask中的每个slot在阶段期间保留原gen，不允许return后重授；证书消费、phase关闭及所有借用归还后，下一沿才放phase pin。CHECKPOINT允许下阶段重新取得仍有效的授权；最终返grant另需所有phase/record引用清零。

冷快照只在终态形成时一次冻结；先合并该沿真实握手，把全部结果原子锁入一个640bit staging，之后才串行写冷RAM，不能从持续变化的热FF逐字拼结果。单一冷控制器一次仅形成一个快照，其他phase置snapshot_pending并保留必要引用，预留本地快照资格后才形成结果；640bit staging与完整scope输出组装寄存器另计FF。kind3隔离快照不随随后live计数变化，恢复走独立事件。phase_token在open前预留，不因关闭时序号耗尽临时再申请。完整scope与phase结果组装输出后valid保持；冷RE和其他热数据事务继续。阶段控制状态候选CREATE→OPEN→SEALING→FENCE_WAIT→CERT_HELD→CLOSED/RETURN_PENDING；未知排空转QUARANTINED。记录回收还须其输出/cold借用/phase pin实际归还，下一沿才可重写同entry。精确完整FF/XLR及控制邮箱容量、服务时限仍DS-B05/06，以上不是综合结果。

| INV | 保持理由 |
|---|---|
| DS-INV01 | scope/grant完整代次与不可变身份先核验后解引用；错误消息不释放他人的槽 |
| DS-INV02 | 每client/op仅一record，permit→proposed→accepted→terminal→release顺序，不提前复用tag |
| DS-INV03 | 预留序号预算/槽能兑现所有旧permit；耗尽停止新permit，不卡死held valid |
| DS-INV04 | AW前完整W槽、AR前完整R槽；所有已提出物理valid及数据来源保持 |
| DS-INV05 | 物理owner最多每方向1；已proposed者释放依真实响应核验；未proposed预留可在pending/输出预留归还后撤销，不等不存在的响应、逻辑消费或fence |
| DS-INV06 | RAM只读sealed/写collect，pending预留返回空间；同址和槽越界被结构隔离 |
| DS-INV07 | actual_beats仅逻辑真实握手，物理count独立，错误/取消不补假数据 |
| DS-INV08 | 成功terminal/fence不等于FM发布；seal覆盖permit/held req、实际响应及本地借用 |
| DS-INV09 | stream rst不清承诺域；drained0不释放任何仍有风险的scope/grant/buffer |
| DS-INV10 | 仲裁只选eligible、指针选择时推进；机会公平不代替真实服务期限 |

### E2. 八项操作草图

**DS-OP01 可信绑定与grant。** 只在已证明安全初始化后的旧HEALTHY状态接受FM open；scope槽与gen预算预留，核验kind/mask/J/lease及实际FM绑定后写不可变key并响应。grant检查scope代次、对象状态、static map、base/L/A、权限与重叠，再建立。字段缺席不解引用；错误拒绝不使用坏句柄释放已有binding。源COMPLETE必须来自采集/fence证据，不能由服务读回一字节猜出。scope/grant回收至少下一沿才可重授。

**DS-OP02 permit与实际接纳。** prepare先核验端口固有client/op、有效scope和已open phase；这些归属无效则DENIED response终结prepare，不授permit、不分配service_seq，也不解引用其坏句柄。有效scope/phase内的非法grant/范围/nbeats则可授ERROR_ONLY permit，预留拒绝邮箱而非数据槽，实际req_fire后形成ACCESS terminal。正常GRANTED permit先占固定record/序号预算和整段池槽，锁198bit头；所有已授permit保持有效scope/phase引用，正常grant也被引用pin住。prepare response独立保持到消费；DENIED不等价segment terminal。每沿独立登记首个req_valid可见的proposed，payload必须等于已锁头及permit。未proposed才可归还；实际req_fire由单一14叶接受仲裁器每沿最多一个，先分配单调service_seq并计账，再按快照合法性及phase/grant mask决定入W COLLECT/R RESERVED或ACCESS terminal。每实际req同时返回仅在req_fire采样的receipt_seq64，不参与ready生成；prepare保存phase，不读取后续可变当前phase。坏配置不永远ready0。序号上限检查扩65bit，已预留预算优先兑现，停止新prepare；slot/gen及phase计数增量预算耗尽同理，不让旧permit无可兑现计数位。普通cancel关闭新增prepare，但已提出req仍可接受并合法终结，不能丢失它。

**DS-OP03 逻辑W收集与封口。** 按7client有数据/容量的eligible逐拍RR，一个池写口每沿一次；record独占slot，W最早req_fire下一沿。先计真实accepted_W，再检查tag/index/LAST，合法拍整条带WE；首次格式错误先计入actual_W，再因AW从未提出形成kind1/TAG或COUNT_LAST/drained1终态，停止该段新增W，不等剩余拍补齐；不组合反馈本沿ready。nbeats全部收齐且每拍合法才SEALED，最后拍沿不立即发同址RE。部分COLLECT不占物理owner；取消且AW从未提出时可停止收集，用显式取消terminal共同作废held逻辑拍，pending仍捕获。

**DS-OP04 物理写。** 写RR只选SEALED段，选择时保存owner并前移轮指针；先预取min(2,nbeats)完整拍，grant预留两W槽/pending，valid+pending预留≤2（pending不是第三槽），同沿真实W消费可释放下一RE credit，下一沿capture。首min(2,nbeats)拍均capture完成后才提出AW并保持所有字段；AW实际接受后才WVALID，按index送完整段，credit计旧valid/reserved和本沿真实消费，新填充覆盖旧清位。W stall保持data/last，已有pending照capture；条件无停顿时可每沿一拍，不靠新client W。WAIT_B核验BID0、RESP和B不早于规定W完成；只有真实匹配B及计数正确才physical_done，随即释放write_owner，不等terminal/release。旧参考bank_sw/末W不替代。写成功后读可见尚需DS-B02的实际证明或排序方案。

**DS-OP05 物理读与独立返回。** 读RR选已预留槽的合法record，保存owner后提出AR；valid一经提出不能撤。RREADY由物理承接策略保证，整段≤64拍写独占槽，不依任何client Rready。核验RID0/RRESP/计数/RLAST；物理count8可识别第65拍，超界只进固定sink和sticky故障，不写出槽边界。正确COUNT/ID/LAST但RESP错可drained1失败、逻辑actual_R=0；错ID/早晚缺LAST/无owner或多余拍不能证明排空，停止新物理承诺并隔离。COUNT/ID/LAST正确即physical_done并释放read_owner，不等terminal/release；RESP成功才SEALED，RESP失败进入drained1终态。返回读口逐client有具体slot容量RR，保存tag/index/目标槽pending，下一沿capture；两槽FIFO有序，各自valid停顿保持，同沿旧消费/新预留按净占用提交。所有逻辑R消费后才正常terminal。

**DS-OP06 terminal、segment_release与取消。** 物理排空后终态由独立邮箱形成一次，计入形成沿旧真实W/R握手，之后payload固定；physical owner已在真实响应核验后释放，不等待本邮箱。新terminal同沿按“排空未知→kind3隔离；确定错误→kind1失败；匹配明确取消→kind2；否则kind0成功”形成，含末B/R与cancel同沿；已经valid的terminal保持旧快照，晚取消只走独立ack。kind1/2有效期间服务Wready=0、客户端Rready=0，已held的Rvalid/payload保持到terminal_fire；停止新RE/新数据，不提前清掉held valid。terminal不依这些ready，握手共同作废未接受的held拍；已有RAM grant仍按原record/tag capture并归还预留。terminal_fire同沿或之后的旧capture标记DISCARD，禁止重新置数据槽valid；终结/失效优先于正常填充覆盖旧清位规则。kind3只通知，不具有终结权。客户端terminal消费后，待自己的本段assembler/返回暂存/pending/借用结清即发segment_release。服务核验原record冻结头/permit代次/seq、旧terminal_seen及自己的输出FIFO/pending/held拍已排空。ERROR_ONLY不重新要求坏grant有效，scope/phase引用仍来自实际取得记录；grant_ref_valid/pool_slot_valid分别注明实际持有者，仅这些valid的资源可递减/回收，错误头不得解引用。池slot仍由record持有，不要求它先FREE。提出独立RELEASED ack后继续保留record、池与grant引用，到ack实际消费才归还，下一沿可复用；坏release只回NO_MATCH/NOT_READY/QUARANTINED，不释放别人。各record保存独立ack容量，不用一个可被他人stall堵住的全局ack；不等整个多段descriptor成功。cancel_ack保存scope/来源及APPLIED/ALREADY/TOO_LATE/NO_MATCH，不改已提出terminal。选中owner但旧AW/AR valid尚未可见且未proposed时，这只是调度预留：cancel/rst/fault停止新预取，旧pending capture并DISCARD，输出预留归还后释放owner，不等不存在的B/R或terminal/release消费。池slot仍按独立release流程归还。旧AW/AR valid已经可见的段即使未握手也继续物理排空；旧valid0且尚未proposed时，同沿匹配cancel/rst/fault禁止首次新valid形成，不能同时发取消安全终态和新物理承诺；时钟丢失只能等平台恢复证据。

**DS-OP07 阶段封口与fence。** 父scope是租约容器，每个(scope/client/phase)有独立子账本；Canny client4按phase0/1/2/3显式open，capture/display/frame-reader当前各自phase0。关闭phase不得重开或用旧phase接下阶段；scope按client保存7×4=28bit closed_phase bitmap至最终归还，Canny快速路径可0→3，一般0→1→2→3。各scope/client独立，不锁DDR。先producer_close停新增业务，但继续完成tail/padding/cache dirty flush所需的全部prepare和req；不能提前禁止这些末段prepare。最后所需请求均实际交付、确认不再产生新请求后，client才发带scope/phase/token的seal和request_generation_closed证明；服务此时关闭selected新prepare。同沿旧真实prepare/req/W/R照记，已预留permit仍兑现，未提出permit由client明确归还。seal后仍处理已接受段的数据/响应和pending，不把“不会产生新请求”冒充local_borrow_closed。stage mask是精确read/write grant slot集合且与原grant代次绑定，权限只是上限；服务等selected无permit/held req遗漏，交叉核验accepted_count/terminal_count、无live及sticky error，捕获最后实际req接受水位cutoff64；不能在最后req未接受时先截水位。接着等所选seq≤cutoff的真实physical_done、logical terminal消费及segment_release、本地封口证据。CHECKPOINT成功响应保持到消费，旧phase关闭；后续显式next_phase_open才放开允许的新阶段，不能将phase2继续用于EXPORT；CLOSE_GRANTS/最终CLOSE_SCOPE则保持关闭，等待独立授权返还。读写可并发，但同scope的先写后读必须先完成规定写可见性/fence；不能凭客户端请求顺序或单ID自证。失败且安全排空可回失败fence，drained0隔离；绝不造success。Canny OUTPUT mask必须包含EDGE写与实际CLASS导出读，NO_STRONG免除无读；阶段fence不关闭整个PROCESS使后续读越权。

**DS-OP08 功能复位、故障与安全恢复。** 功能rst/取消关闭新业务和发布资格；旧物理valid已经可见时必须继续，未提出AW/AR的新段在rst时可形成kind1/RESET_PROTOCOL安全终态，不能永等被冲刷的逻辑W。旧permit仍兑现至合法拒绝/终结。承诺域继续AW/AR/W valid/payload、B/R接收、req兑现、计数、池元数据/pending/terminal/release账本；不能将RAM输出接会丢pending的stream rst。scope/grant/key在旧物理风险和旧消息未清前保留。未知物理响应或不能证明排空，平台fault保持域冻结旧范围，发不可变隔离通知并允许安全sink，不能只见一个LAST就重开。首次safe_init需平台冷启动/无残留端点/校准/锁定证据，不能凭未知FF或scope_valid0自选。热恢复需逐个完整旧scope匹配及全服务物理排空、所有client/CDC旧承诺终结证明，清本地valid后独立recovery_done；旧drained0通知不改写。默认DDR重校准后旧图失效，FM重新建立源，保留内容须另有实证。实际平台端口、复位域与cal_done采样仍DS-B03/07。

## F. 语言、逐沿与资源契约

SystemVerilog2009候选，实际Efinity2026.1.132/Questa2024.1；本批无C++实现或C++↔RTL，相关RAII/异常不适用。独立字节存储参考与协议监视拟用已安装Python3.14.6/既有仿真工具，但尚无可执行模型/runner。

| RTL A–L | 契约/限制 |
|---|---|
| A 数值 | unsigned32地址/33bit末端，16B×nbeats先扩；seq预算65bit；nbeats7/index7/逻辑count7，物理异常count8饱和另报overflow；20bit RAM高12位固定0 |
| B 时钟/观察 | 同core正沿，更新后稳定、下一沿采样；TB稳定后观察。真实PLL/cal_done域及保持域须平台证据 |
| C 接受 | prepare/permit/req/W/R/terminal/release/control各实际握手；proposed另在首valid可见沿记账，不等req_fire |
| D valid | invalid无数据事务，空/气泡不充当零拍；pending/后台独立于输入valid推进 |
| E 反压 | 各client返回槽独立保持；physical R不依logical ready；已提出AXI valid/payload保持；旧valid0且尚未proposed时，同沿cancel/rst/fault优先禁止新物理valid，物理能力仍实际验证 |
| F 时间 | req e0→W最早e1；末W collect eL→sealed旧状态最早eL+1选；RAM RE eK→capture eK+1，消费最早eK+2；W首min(2,n)备齐才AW，两个W槽valid+pending预留≤2，pending不是第三个容量；同沿真实消费可提供下一RE credit。AW接受后最早下一沿W。R整段物理校验后才预取/交付，首拍不是AR+1 |
| G 复位 | 承诺域在stream rst下继续，私有业务冲刷；冷安全初始化/热恢复不同，RAM数组不清，超时不返租约 |
| H 配置 | 绑定/权限/地址及完整request快照在prepare锁定；grant返还/重授跨代次，已live事务不读取新的全局配置 |
| I 存储 | 两池各7 RAM10/8槽，逐client双返回槽与W双槽，pending预留；同址规避，槽实际回收后下一沿授新 |
| J 身份 | scope623→grant241→permit→tag16/seq64→physical ID0；每beat_index/last段内重启，低byte lane为低地址逻辑格式，真实映射待验 |
| K CDC | 本服务同core；相机/显示需适配独立FIFO/邮箱，cal_done/复位/安全证明不能直接跨位取样，具体MOD-01/03/11仍阻塞 |
| L 实现 | 数据池14加metadata3 RAM10模式候选及大字段分级查询；XLR/DSP/频率/完整平台容量/STA未测，不把61块小计当整机可放置 |

共同数值契约是受授权字节范围、顺序、128bit映射及成功读回逐字节一致；硬件执行契约另核valid/pending/取消/响应与终结；对应关系由scope/grant/permit/tag/seq/index定位，不用帧号大小或函数完成代替物理完成。软件参考不复制RAM条带/仲裁FSM，预期地址内容独立构造；错误/取消比较各端实际前缀，后缀无合法图。

### F1. 公平与期限的可检查边界

prepare/req采用单一14叶eligible RR，7client各两个独立方向；每沿至多一个实际req接受，持续eligible的叶≤14次本层接受机会（至多13个其他）。W入池、physical read/write选择及逻辑R返回RE分别7角色RR，持续eligible者≤7次对应机会（至多6个其他）。各层选择时推进指针，当前owner独立保存。等待client数据/返回容量者不占全局输入/物理锁。Canny内部5写/2读RR在资格持续、终结与借用有界条件下，保守乘积≤35/14次全局方向机会，不能称固定周期。

定义T_turn,d包含一次方向选择后的准备、AW/AR等待、W/R、B/核验、refresh和另一方向干扰。仅在真实有限界成立时，等待≤T_residual+6T_turn，物理结束≤T_residual+7T_turn。端到端另加prepare、W收集/逻辑R交付、terminal/release/fence及CDC；未约束client ready时这些也无有限时限。

六源须证明EOF→FREE的尾封口、剩余段链、terminal/release/fence、CDC与FM提交在下一SOF分配前结束，并至少提前一个分配边沿；显示预取lead/FIFO须满足实际像素需求和保证服务曲线。平均1.6GB/s或7路RR不能证明它们。DS-B05保留FM六槽全占反例，证明失败必须修订资源/服务方案，不能静默降低采集要求。

## G. 实施与文字验证计划（全部未运行）

次序：相邻授权/seal/恢复统一及protected预检条件→完整本稿/READY/指定批准→context/permit→池/逻辑协议→真实AXI/terminal→fence/恢复→器件/PHY→整机QoS。计划职责为ddr_service_context、ddr_segment_buffers、ddr_axi_adapter、ddr_fence_recovery，均未生成；独立测试/runner也待批准。

| TEST | REQ/输入与事件 | 期望/方法/通过条件 | 状态 |
|---|---|---|---|
| DS-T01 | DS01/02：base/L/A、padding、小图与1080p、32/33bit溢出、错slot/gen/client/region | 静态映射和范围参考；非法不发物理、不解引用别人；稳定后观察握手 | NOT_RUN |
| DS-T02 | DS01：scope/kind/mask/J486、623/241/冷640/热384字段、RO重叠/phase pin代次/写移交、源未COMPLETE | 正确权限生命周期，错误不返别人的绑定，完整身份相等 | NOT_RUN |
| DS-T03 | DS01/06：permit归还、首次req_valid/held、耗尽近上限、同沿cancel/prepare/req | 已预留兑现、已提出不能当未启动；seq不回绕/无漏记 | NOT_RUN |
| DS-T04 | DS02/03：n1/64、全128bit花样、槽0/7、条带交界bit19/20/119/120/127 | 20bit模式重组逐位正确、高12零、整字WE/无越界 | NOT_RUN |
| DS-T05 | DS03：W先于req、错tag/index/LAST、收集停顿、最后W与seal/RE | 不形成循环；实际prefix计数，坏段不AW；held字段保持 | NOT_RUN |
| DS-T06 | DS03/06：AW未提出/valid held/AW接受/末W/B各时取消和rst | 严格物理proposal边界，完整W/B，取消原因独立；无提前drained | NOT_RUN |
| DS-T07 | DS03：BID/RESP/早B/重复B、后续同地址读 | 合法RESP错可安全失败；未知ID/早重复隔离；成功读回可见性必须真实IP证明 | NOT_RUN |
| DS-T08 | DS04：Rready任意stall、物理连续64R、多个client、读写同时活跃 | AR完整容量、物理接收不依client，逐client返回有序且相互隔离 | NOT_RUN |
| DS-T09 | DS04/06：RID/RESP/早晚缺LAST、第65拍/无owner | 不越RAM；合法RESP错actual_R0/drained1，未知长度/ID不假排空 | NOT_RUN |
| DS-T10 | DS05：8槽/两返回槽、RAM grant→capture停顿/取消/terminal_fire同沿及后沿、同沿消费替换 | pending具体预留，终结后capture丢弃不复活valid；slot在release ack消费后归还、两池同址规避，真实前缀无丢重 | NOT_RUN |
| DS-T11 | DS06：四kind、早ACCESS/cancel terminal、terminal停顿/release早到或错seq | terminal固定且独立ready；joint终结只在drained1，借用归还后返tag/slot | NOT_RUN |
| DS-T12 | DS07：未prepare的脏WB/封尾、末writeback尚未req_fire、未归还permit、same-edge新prep/req/terminal、阶段checkpoint/next-phase-open | producer先完成末段prepare/req再seal，cutoff覆盖最后实际接受，同沿多方向计账合并；不漏段/闭死后续Canny阶段 | NOT_RUN |
| DS-T13 | DS07：CLASS→seed→closure→EXPORT CLASS读→EDGE写、GRAD关闭/识别handoff | OUTPUT真实读写mask，关闭写授权后授只读，最后读租约归还才重用 | NOT_RUN |
| DS-T14 | DS06/07：held AW/AR/W、R/B、pending与rst同沿、错scope恢复、冷safe_init | 保持域照记；drained0不改写、不返授权；真实平台证明后独立恢复事件 | NOT_RUN |
| DS-T15 | DS05/08：14请求叶/7方向数据eligible与停顿、Canny内5写2读、显示与capture争用/refresh | 机会界/物理周期/服务曲线分别计；保留六源/欠载反例，不拿平均率判PASS | NOT_RUN |
| DS-T16 | DS03/04/08：匹配2Gb/x16/真实controller/PHY校准、跨row/bank/4KiB边界/刷新及整机 | 真器件读回、并发、校准/时序与资源/STA；行为模型不能替代 | NOT_RUN |

正常与边界、错误与reset文字互补，独立行为存储模型只验证服务协议。匹配器件/PHY及protected实际展开为单独硬门槛；向量、种子、工具许可/实际命令尚待冻结，不伪造运行记录。

## H. 双向追踪

| REQ | MOD/IF/OP/INV | 计划职责（未生成） | TEST | 实际证据 |
|---|---|---|---|---|
| DS-01 | CONTEXT；IF01/02；OP01/02；INV01…03 | context/permit/身份记录 | T01/02/03 | 待实现/NOT_RUN |
| DS-02 | CONTEXT/POOLS；IF03/05；OP02/03/05；INV04/06 | 范围与全拍打包 | T01/04/05 | 待实现/NOT_RUN |
| DS-03 | WPOOL/AXI；IF03/05；OP03/04；INV04/05/07 | 完整写/B/可见性 | T04…07/16 | 待实现/NOT_RUN |
| DS-04 | RPOOL/AXI；IF03/05；OP05；INV04…07 | 完整读/逐client返回 | T08…10/16 | 待实现/NOT_RUN |
| DS-05 | 全部数据scheduler；IF03/08；OP03…06；INV05/06/10 | RR及有限容量 | T08/10/15 | 预算/未测 |
| DS-06 | AXI/RECOVERY；IF04/07；OP06/08；INV02/04/09 | terminal/保持/恢复 | T03/06/09/11/14 | 待实现/NOT_RUN |
| DS-07 | FENCE/CONTEXT；IF01/04/06；OP07；INV01/08/09 | seal/fence/close/归还 | T02/11…14 | 待实现/NOT_RUN |
| DS-08 | 全部；IF08；F1/INV10 | 期限/资源/服务测量 | T15/16 | 仅推算/未测 |

反向每个候选核心均对应权限、完整事务、有限缓冲、错误或服务要求；无业务算法藏入服务。改动字段/物理并发/取消/授权/阶段或期限，须同步D/E/F/G，下一相邻版本再统一，不能改测试期望掩盖失败。

## I. 门槛、阻塞与待统一版本

| ID | 当前正确性缺口 | 解决方法/可独立工作 |
|---|---|---|
| DS-B01 | 匹配MT41J128M16JT-125 2Gb模型/2048Mb头和实际PHY/校准缺口 | 官方获取申请待答；不联网，设计可继续，器件验收不可替代 |
| DS-B02 | byte/row/bank/容量、B后读可见、真实RESP/LAST/单ID/完整burst未知 | 获批真实protected预检；如需排序先修设计，不靠旧master通过推断 |
| DS-B03 | 每方向1physical并存、R承接/W连续、cal_done域与复位控制未证 | 同输入验证并发/串行比较与平台CDC/保持域，不静默退成较小工程 |
| DS-B04 | FM真实绑定/grant/permit/发布端口与scope623控制未统一 | 本稿D字段候选，下一FM/Canny/显示/采集统一版本及完整baseline |
| DS-B05 | 六源EOF→FREE、显示lead/FIFO及实际公平周期期限未证 | F1公式和实际需求/服务曲线；保留反例，必要时重算槽/资源 |
| DS-B06 | 识别AUX/其grant峰值、全机RAM/XLR/时序分配未冻结 | MOD-09设计与真实综合/PNR，不把16scope/32grant/61RAM小计当证明 |
| DS-B07 | 冷safe_init、hot recovery、旧client/CDC消息归还和内存保留未知 | 实际MOD-01/11安全证明与恢复任务设计，不清计数假排空 |
| DS-B08 | 相邻MC-M01/Canny阶段及permit/release取消kind差异未吸收 | D3差异表→新统一设计版本/独立复审；旧FE/FM/Canny本轮保留 |

规范§10.3①行为/样例、②职责/来源、③候选接口/组合反例、④局部状态/草图、⑤语言/映射、⑥走查、⑦验证追踪已有候选内容；⑧无正确性阻塞不满足，⑨保存读回/呈现由05本轮记录，⑩范围明确但完整实施基线未冻结。保持LOCAL_DESIGN，无READY、无指定实施批准。只读调查/设计/审阅仍允许，业务代码和可执行测试停止在批准之前。

## J. 变更与恢复

本稿实际读回复审修正seal/flush死锁、终结后pending DISCARD、首次物理valid同沿优先级、首两拍预取条件、release ACK引用寿命、14叶请求机会界及冷/热字段容量；这些修正只在本候选稿内。

本稿从原系统逻辑DDR箭头细化permit、scope623/grant241、物理/逻辑双账本、完整段14RAM/逐client双返回槽、取消kind/segment_release、阶段checkpoint与最终close、OUTPUT导出读、安全恢复及真实期限公式。均为批准前提议。

前轮27份文档审计在[历史Canny v0.4](../experiments/track4_full_sw_20261004/05_reviews/document-checks-canny-v0.4.json)；原FE v1/28输入、FM v0.1、Canny v0.4及附件不改。整体02/03仍为FE冻结输入，D3明确候选差异，不能宣称其旧端口已升级。恢复先核最新设计/真实批准/输入hash及实际结果，不能从摘要假定可实现。

## K. 实现及验证实录

已执行的是只读来源核对、设计文档写入/读回和独立审查；其结果在实验05。没有新业务RTL/功能脚本/参考程序/testbench、编译、仿真、综合、PNR/STA、bit/hex、正式DB/状态更新或人工观察。全部DS测试NOT_RUN；整机十一项目标未完成。

## L. 阅读、人工观察与交付边界

阅读顺序：整体输入/帧引用→B行为→C职责→D身份/授权/数据/终结与相邻差异→E许可、W收集、物理写、物理读、终态/release、阶段fence、恢复→F逐沿/服务界→G/H测试追踪→I缺口。人工审阅先画一条正常源提交/读回链，再画held AW取消、Rready停顿、最后writeback未接受便fence及OUTPUT漏CLASS读的反例。

permit是可兑现的提议资格；req_fire才建立实际段；physical_done只是物理结束；terminal_fire消费逻辑结果；segment_release证明本地借用返还；fence是选定scope阶段收敛；FM发布仍是额外合取。六者不可互换。

最终源码/注释/测试一致性在获批实现后以真实文件与符号核对。当前只交付设计，理解验收没有用户实际作答仍待检验；不据讲解宣称已经掌握或硬件通过。
