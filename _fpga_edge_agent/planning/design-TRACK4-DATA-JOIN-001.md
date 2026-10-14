# TRACK4-DATA-JOIN-001 数据与归还联合设计 v0.1

2026-10-04。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。目标仍是五项基础、六项高阶、1080p完整软件工程，直到真实bit/hex；本稿完成其中数据身份、授权、借用、终态和父级回收的联合设计，尚未交付业务实现。

先读[主计划](design-TRACK4-FULL-SW-001.md)B/C整体和[整体图](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)，再本稿B/C整体→D接口/组合→E中文操作草图→F语言/存储→G/H验证追踪→I/J边界。控制阶段按[CONTROL-JOIN](design-TRACK4-CONTROL-JOIN-001.md)；本稿J逐条列明覆盖的旧候选，未列内容继续有效。旧稿保持原字节。

- Goal：让采集、处理、识别、显示和DDR服务使用一致的身份与关闭条件，消除父子互等和旧代次误用。
- Current state：各局部候选可读，但父绑定/返还、阶段记录和供料存在交接缺口；没有实现批准。
- Target state：当前联合边界可由字段、事件和草图检查；完整算法/物理依赖解决后才允许整机READY。
- Gap / Open questions：A中的DJ-B01…06，真实数值/供应商合同与执行前置分开。
- Assumptions：V4/I3＋SC431HAI四lane、1920×1080、一个串行PROCESS、一个共享FE、六源/三结果；未确认实物，不借VF/C4约束代替。
- Dependencies：A绑定的局部稿、原始只读来源、既有模型申请和正式审批/DB。
- Milestones / Detailed steps：本稿联合与读审→关闭真实设计未知→呈现指定范围READY→批准→独立work实现→真实仿真/综合/约束/布局/STA→bit/hex。
- State transitions：只改变设计文档阶段；不修改正式H0、PROJECT_STATE或TASK_LEDGER。
- Artifacts and hashes：A及读审；本稿最终字节由当前document-checks.json绑定，避免在文件内自引用SHA。
- Validation：G全部文字场景NOT_RUN；文档读回与结构检查单列。
- Failure handling：停止新增、兑现旧承诺、真实排空或隔离；不清账制造成功。
- Human approval gates：v0.2指定版本/范围/基线及原Manifest；已有FRONTEND/模型申请未收到新答复，不重复申请。
- Rollback：仅新增本稿并更新阅读索引，旧候选及历史审计可恢复；没有业务工作副本。
- Completion criteria：联合设计分析可读回≠完整软件目标完成；所有十一项实现及真实工具证据仍必需。

## A. 基线、范围和剩余阻塞

以下局部稿是实际只读核对输入，SHA256固定。无Git提交记录，不伪造commit。

| 输入 | SHA256 |
|---|---|
| [FM v0.1](design-TRACK4-FRAME-MANAGER-001.md) | D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| [DDR v0.1](design-TRACK4-DDR-SERVICE-001.md) | 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| [Canny v0.4](design-TRACK4-CANNY-001.md) | 224779F89206F4113CB0764617401E96ED53D7CF34DBD43FBB60A800A54C8729 |
| [Canny父/writer附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md) | DE6172CF4910F593BD76622E304C56808EE62813ABA52D99E3EDF167758467DC |
| [Recognition v0.1](design-TRACK4-RECOGNITION-001.md) | D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5 |
| [Platform v0.1](design-TRACK4-PLATFORM-001.md) | 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 |
| [Camera v0.1](design-TRACK4-CAMERA-001.md) | F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C |
| [Display v0.1](design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 |
| [Control-Join v0.1](design-TRACK4-CONTROL-JOIN-001.md) | B8DAED20BEA99636E7667CC7E69AA62317D84D5103DCC59A476821B31EFEFF58 |
| [FrontEnd v1](design-TRACK4-FRONTEND-001.md) | 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 |

规则v0.2 SHA为4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；[PLAN_TEMPLATE](PLAN_TEMPLATE.md)为99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。其他既有输入/附件哈希继续由审计绑定。

| ID | 分类、影响与缺口 | 可继续部分及消除证据 |
|---|---|---|
| DJ-B01 | 真实外部合同：2Gb器件参数/时序依赖、受保护DDR的地址映射、B后读可见、完整响应/旧物理效果关闭未知；影响IF01/04/08 | 联合授权及计数可定；既有模型申请仍PENDING，需匹配器件材料和获批真实PHY/校准预检，不以简易存储代替 |
| DJ-B02 | 真实外部合同：CSI5.15 RAW/PPC/metadata/错误归属/closure、SC431模式配置生效及发端界未知；影响IF02/03 | 锁身份和NORM消费水位可定；需版本匹配资料/真实IP观察，安静周期不能证明末错误已不可能 |
| DJ-B03 | 真实外部合同：AON冷初始化、停钟/恢复与相关HDMI clock、serializer旧引用关闭依据未知；影响IF06/08 | 保持域和显式关闭义务可定；需器件原语/相关clock依据及获批窄预检，cal_done不证明安全 |
| DJ-B04 | 算法设计未决：RC整数拟合/角表/阈值/候选与final字段/profile实体、无固定尺寸限制下的可辨识范围及独立质量集未冻结；影响IF04/07 | 本稿只关闭内存角色/租约；profile_ref64不是已定义参数。不能把撤回的96–768/比例/噪声组重新设成硬边界 |
| DJ-B05 | 设计预算未闭合：采集EOF尾期限、行预取最坏服务上界、非反压突发、宽算术及完整FF/DSP预算未知；影响所有IF及吞吐 | 有界容器与供料结构可定；需真实发端界、服务曲线和完整资源分配。平均带宽、6槽或178RAM不证明持续无丢帧 |
| DJ-B06 | 执行前置：指定版本实现/工作副本/构建授权、匹配工具/模型、正式PostgreSQL运行条件未满足 | 允许本稿设计/读审；批准后的仿真/综合等验收义务独立NOT_RUN。实物编程/观察在bit之后，不作为本次软件前提 |

“尚未运行仿真/综合”本身不是设计永远无法READY的条件。v0.2 §6.3允许有依据的预算，§10.3要求当前正确性合同已经明确及验证计划实际存在。上表中的未知外部行为、算法参数和最坏输入界不能通过改标NOT_RUN来消失；其余已定义合同的实际检查移入G，获批后执行。

## B. 整体外部行为

从相机到源图写入、从源图到结果、从完整结果到真实scan，所有事件关联同一来源和不可变任务配置。局部“归还”结束一个借用；父FM仍保留物理图引用直到真实生命周期完成。

| REQ | 可检查要求及来源 |
|---|---|
| DJ-J01 | 派生：首SOF前预留Origin、capture scope及配置；SOF报告采用旧ARM，不重新造身份 |
| DJ-J02 | 派生：字段/权限不能自授权；短句柄只查仍被pin的完整记录，拒绝不归还他人的对象 |
| DJ-J03 | 基础/高阶共同：LIVE及DDR重处理共享FE独占绑定；完整输入/FE借用归还不解除源结果BIND |
| DJ-J04 | 完整Canny/识别：局部终态、phase证书、输入归还和最终status独立收集；不能互等父FREE |
| DJ-J05 | 显示/冻结：OFFER保存、真实SELECTED/APPLIED、scan关闭和结果退休分别有完成点；冻结仍来自真实active SRC |
| DJ-J06 | 派生：六源/三结果/单PROCESS/有限scope/grant/phase容量及关闭token先预留，回收下一沿复用 |
| DJ-J07 | 动态阈值/模式：source camera配置、result业务C和render分别锁快照；旧事务不读当前全局C |
| DJ-J08 | 派生：取消/故障不撤已提出valid、不清旧账；Q通知不改写，安全恢复使用完整旧scope证据 |

正常样例：预留源S/ARM→真实SOF→直播FE→源及结果各自排空→PROCESS结果完整→OFFER→首行预取→真实VSYNC/APPLIED→旧结果独立退休。源最早提交仍需真实CSI关闭和成功写fence。

边界样例：无SOF取消只结束RESERVED会话；不伪造CAPTURING。结果完成而pending满保留WORKING及BIND，释放已关闭的处理阶段资源；后续pending有空间才发布。错误样例：已held W及旧R未排空时平台故障，原scope/借用保持Q，不授权同地址新代次。

## C. 职责与连接

| MOD | 本次职责/拥有数据 | 边界与依赖 |
|---|---|---|
| MOD-03 Camera | ARM/START/NORM/closure及源writer旧会话 | 不分配FM引用，不借错误通知清DDR账 |
| MOD-04/10 FM/JOIN | 完整source/result/J/C、可信绑定登记、独立终态/归还证据合并 | 不制造CSI/PHY排空；唯一提交保留位和物理FREE |
| MOD-05 DDR | scope/grant/permit/阶段/段证书及实际服务水位 | 不以父status代替记录关闭；真实物理合同DJ-B01 |
| MOD-06/07 FE管理及reader | 独占FE_BIND、FJ/FS、两bank输入适配与feed关闭 | 不解除result BIND；原FE数值合同不变 |
| MOD-08/09 Canny/RC | 四阶段各自不可重开、局部writer证据/GRAD消费者移交 | 不等父FREE形成local终态；RC数值DJ-B04 |
| MOD-11 Display | 完整OFFER、未来PLAN与当前scan、三row bank/退休借用 | 不把运输ACK当应用；物理serializer合同DJ-B03 |
| MOD-01/12 Platform/Control | 镜像/恢复保持、配置/策略和观察 | UI复制快照不保留图；不反压关键关闭链 |

数据路径：Camera—DJ-IF02→SRC；LIVE或SRC reader—DJ-IF03→FE—DJ-IF04→Sobel/Canny→可选RC→EDGE/ANN；FM—DJ-IF05→Display—DJ-IF06→FM。授权路径DJ-IF01贯穿所有DDR客户，配置路径DJ-IF07锁定各快照，故障路径DJ-IF08独立收尾。

先定整体行为、再定D交接与端到端反例、最后E细节。新结构选择是可信父登记＋完整锁定上下文，避免每pair复制大消息；短引用的生命周期不能超出父pin。算法核仍按旧局部稿自写，保护IP不因为接口同名就视作可替代。

## D. 接口、字段与组合检查

### D1. 公共表示和接纳规则

除明确signed梯度外全部unsigned；斜线字段按从高到低布局，保留位为0。所有新同域控制为core正沿valid&&ready；接收ready只依旧容量，不能由本沿新错误反馈撤去已真实握手。所有ACK包含原body或明确回显的完整身份。新DATA_CONTROL status2为0APPLIED/ACCEPTED、1ALREADY、2BUSY、3REJECTED/NO_MATCH；含义以消息类型为准。BUSY不产生效果，不存“完成”。

新error4统一为0NONE、1FIELD、2IDENTITY、3PROOF_PENDING、4SEQ_BODY、5EXHAUSTED、6UNDERFLOW、7MEMORY、8CLOCK、9PROTOCOL、10OLD_ANCHOR、11POLICY、12TARGET、13SESSION、14CAPACITY、15UNSUPPORTED。15仅用于明确能力不支持，非法op/padding为1；原MC error3、feed error3、算法reason及camera/DP error16保持各自类型，不截断混用，原始诊断另存。此枚举也补全CONTROL-JOIN stage914/920。

J486沿DDR：三ID96/source67/result66/workspace65/capture64/job64/policy64。scope623=H68/kind2/mask3/J486/parent_lease64；mask位0SOURCE、1RESULT、2WORKSPACE。PROCESS/DISPLAY保留完整历史J，即使mask已不授workspace访问也不重写历史；CAPTURE/DIAG不适用字段按原kind规范0。Origin195=source_slot3/gen64/epoch32/frame32/capture64；跨scope比较同源使用Origin，不要求CAPTURE与PROCESS的J全等。

grant241=grantH69/scopeH68/client3/region3/perm2/base32/L32/A32。desc96=base32/L32/A32，地址半开范围先扩33bit；源RGB的L=3N/A=16ceil(3N/16)。N=W×H≤2073600，pair数P=N/2≤1036800，宽度偶数6…1920、高5…1080且等静态实例。各序列/代次不回绕，递增前扩位检查；外三ID及登记的lease代次允许0，service_seq/scan_token从1开始，0专指尚无相应事件。

### D2. 八项交接

| IF | 方向、完整字段或有效引用 | 接纳/输出与所有权 |
|---|---|---|
| DJ-IF01 | FM↔DS可信scope/grant/phase控制；详D3，旧req266/W152/R155/terminal301/release288/ACK293不改 | DS唯一分配scope/grant槽与generation；父真实登记、mirror OPEN及对象资格验证后才授；短handle从已pin完整表核对 |
| DJ-IF02 | FM→CAM CAPTURE_LEASE1048/receipt1054、ARM284/290；CAM→FM START783/789、START_CLOSURE788/794、STATUS808、RETURN623/629 | 首SOF前锁身份；START由真实旧ARM的SOF形成；status消费后独立return，不等父CLOSE |
| DJ-IF03 | FM→FE manager FE_BIND1628/1634；LIVE_BIND438或DDR reader；FS163/feed_terminal253；FE_RETURN1628/1634 | 一个独占FE绑定；完整供料/holding/FS关闭后返还，不解除物理BIND |
| DJ-IF04 | Canny/RC/localwriter→JOIN local_terminal及finalstatus；各子→FM独立绑定归还；PROCESS_SAFE645/651 | 局部证据不等父fence/FREE；归还的接纳不等最终status，父持有结果/工作区物理引用另算 |
| DJ-IF05 | FM→DP OFFER1963/1969；DP↔core PLAN522/528；ROW336/OWNED342/RELEASE343/349 | OFFER保存及未来路线业务保存先于预取；首行不等SELECTED；ROW短引用只能命中已pin OFFER |
| DJ-IF06 | DP→FM SELECTED1013/1019、CLOSED921/927、APPLIED1503/1509、terminal840、return687/693 | 独立各depth1；真实scan/apply/退休各有完成点，status→return，不等父scope CLOSE |
| DJ-IF07 | C570、source_camera_cfggen64、render112/代次；CONTROL-JOIN stage914/920/snapshot1353/1359 | 业务C在result预留/形成job前锁；camera cfg来自source，render来自同result，不以camera cfg替config_id |
| DJ-IF08 | FM/DS/client↔PL mirror688/reply694、PREPARE808/FINAL808/done814及旧端点保持 | OPEN ACK前无物理承诺，CLOSE在真实借用/段关闭之后；恢复mask与完整旧scope匹配 |

CAPTURE_LEASE=scope623/grant241/RGBdesc96/camera_cfggen64/cfa_phase2/W11/H11；ARM=scopeH68/cfggen64/epoch32/link32/arm_seq64/cfa_phase2/W11/H11。旧CAM这里phase2明确改名cfa_phase2，不与DDR服务阶段phase2混用；capture服务阶段固定0。START783=full_capture_scope623/arm_seq64/camera_cfggen64/link32，ACK789回原body+2/4；独立depth1预留。STATUS808沿CAM完整字段，return623回原可信scope，ACK629加2/4。每ARM保存start_evidence2：0START_REQUIRED_PENDING、1NO_START_PROVEN、2START_SEEN，3非法；ARM提出时为0。新增START_CLOSURE788=原START783/resolution2/arm_closed1/start_notice_closed1/rx_entry_closed1，ACK794回原body+2/4，按六个capture ctx预留待发资格和独立depth1通道。resolution0NO_START_PROVEN仅在旧ARM真实撤销、latched_started0、无held START且匹配RX入口关闭后允许；resolution1START_SEEN须真实启动锁存、原START业务ACK已消费且该ARM/RX入口关闭；resolution2Q不产生普通关闭权，3非法。迟到START/status/closure分别保存；正常等START_SEEN及其通知闭合，无SOF取消等NO_START_PROVEN而不等START。计数0/安静周期不能证明NO_START，迟到消息不使源状态倒退。

FE_BIND1628=PROCESSscope623/C570/Origin195/source_camera_cfggen64/FElease64/route2/FJ110；route0LIVE、1DDR，2/3非法。完整J/C/source/result/lease核验后保存。LIVE438=FJ110/PROCESSH68/Origin195/FElease64/enable1只是投影，不替代完整绑定。FS163=status3/三ID96/in_pairs21/out_pairs21/error_xy22；feed253=三ID96/job64/source67/success1/drained1/actual_pairs21/error3。FE_RETURN回原1628，ACK1634；可信FE记录close_branch2为0未闭合、1FJ从未提出的no-session、2真实FS已消费、3匹配完整旧FE_BIND的可信reset-applied。分支1须FJ从未valid/fire且无输入义务，held FJ不属于no-session；分支2核真实FS/旧独占绑定；分支3核平台授权和真实reset关闭，不能用reset意图/epoch代替。各分支均结旧feed/队列/holding/pending借用后才提出；分支1/3不制造FS或完整pair数。真实FS/reset终结后，旧FE不再接的未fire FP/queue按旧owner显式DISCARD，已fire计数保留；FS独立接纳不等这些项先排空。保持此完整上下文到ACK消费，不能用当前槽表解码迟到FS。

PROCESS_SAFE645=scope623/required_engine4/closed_engine4/required_client7/closed_client7；ACK651。engine位0输入适配、1FE、2Sobel/Canny输出支路、3RC；client位对应0…6。PROCESS required_client仅由本scope实际opened C2…5产生，C0/C1/C6位规范0；closed只由已保存真实终态、必要phase fence、段release/本地borrow关闭证据置位，未启动支用可信no-session证明；Q不能置drained闭合位。它不等DISPLAY历史scope已FREE，也不替代最终算法成功status。

### D3. DS新控制与阶段生命周期

客户端0CAPTURE/1DISPLAY/2READER/3RESULT_WRITER/4CANNY/5RC/6DIAG，7非法；region0CLASS/1QUEUE/2GRAD/3EDGE/4SRC/5AUX/6SCRATCH，7非法。旧MC数据与终态编码保持DDR原稿：物理ID固定0不替代逻辑service_seq；每沿全局req_fire最多1，14叶RR；每client/op仅一live段直到release ACK消费。

| 新DATA_CONTROL消息 | 字段预算及完成条件 |
|---|---|
| SCOPE_OPEN555→reply629 | kind2/mask3/J486/parent_lease64；DS分配H68形成scope623，reply=scope623/status2/error4；可信父租约是授权来源 |
| GRANT_OPEN172→reply247 | scopeH68/client3/region3/perm2/base32/L32/A32；安装真实FM对象范围后reply=grant241/status2/error4 |
| GRANT_RETURN306→ACK312 | grant241/return_seq64/local_borrow_closed1；无permit/record/phase/pending/holding引用后关闭；ACK消费、下一沿才可重授该slot |
| PHASE_KEY137 | scopeH68/client3/phase2/token64；phase是client各自0…3，token非回绕 |
| PHASE_OPEN201→ACK207 | key137/read_grant_mask32/write_grant_mask32；锁精确已安装grant集合，保存后ACK，不能用裸region mask代替实际grant |
| REQUEST_CLOSED268 | key137/has_req1/last_accepted_seq64/accepted_count64/held_req_closed1/unproposed_permits_closed1；所有已proposed req兑现，未proposed permit明确归还，旧watermark固定；无req时seq/count=0 |
| PHASE_RELEASE137→ACK143 | 原key；fence证书消费及phase的record/permit/cold查询/holding外借为0后ACK；phase自身grant_pin在合法RELEASE ACK消费后下降，不作为ACK前提。slot5仅物理索引，ACK消费下一沿复用；scope closed bitmap/累计错误保留 |
| SCOPE_CLOSE687→ACK693 | fullscope623/close_seq64；全部grant/phase/record/端点归还后关闭，AON mirror另行CLOSE，不能反过来等mirror先关闭 |

REQUEST_CLOSED响应274=原268/status2/error4，实际保存生成封口和固定watermark后才成功。业务停止后仍允许旧授权有限tail/padding/dirtyWB准备和req；这些请求全部兑现或合法归还之后才REQUEST_CLOSED。随后seal锁最后实际service_seq；fence等全部目标段terminal/release及借用关闭，不据裸done或cold slot5判成功。

PHASE_FENCE_REQ350=key137/kind2/client_mask7/region_mask7/dir_mask2/read_mask32/write_mask32/has_req1/cutoff64/accepted_count64/request_closed1/local_closed1。kind0CHECKPOINT、1CLOSE_GRANTS，2/3非法，CLOSE_SCOPE另走687通道；client_mask仅含key.client，read/write mask必须等于该key完整已登记集合，region/dir由集合导出，不能用子集证书关闭整个phase。每phase在CHECKPOINT/CLOSE_GRANTS中二择一发一次，成功封口后不再prepare或发另一种关闭。CLOSE_GRANTS只额外登记授权停止新访问的意图，证书不等GRANT_RETURN ACK/PHASE_RELEASE；实际释放按下文执行，避免循环。

PHASE_CERT410=key137/kind2/request_closed1/local_closed1/has_req1/last_accepted_seq64/accepted_count64/released_count64/terminal_kind2/success1/drained1/error4/first_error_seq_valid1/first_error_seq64/raw_resp2/counts_final1。kind回请求的CHECKPOINT/CLOSE_GRANTS；terminal_kind沿MC四种0OK/1FAILED_DRAINED/2CANCELLED_DRAINED/3Q。released_count仅数真实消费的RELEASED segment ACK；生成封口、无held req/未兑现permit、released=accepted、目标业务本地/pending/cold查询借用关闭（不包括本证书/phase登记自身的输出pin）、无错误/取消且规定读后可见条件成立才success1/drained1。若has_req0，则last_seq/counts均0；first_error_seq_valid0时first_error_seq/raw_resp规范0。服务scope累计failure另外保存首原MC error3/RESP2/seq，直到scope关闭，CERT的error4不截断原MC错误。

取消有匹配scope取消记录才允许terminal_kind2/success0/drained1/error0；Q必须drained0、不产生普通释放权。证书吸收形成沿旧真实握手后一次冻结，后续live计数不改body。证书输出独立depth1；父消费后才允许phase release；REQ350与CERT410的slot/key/grant集合都被pin到关闭，结果不依最终算法status。

LOCAL_TERMINAL231=key137/producer3/region3/kind2/actual_pairs21/legal_pixels21/physical_done_bytes32/leaf_request_closed1/local_closed1/counts_final1/drained1/error4/raw_mc_valid1/raw_mc_error3。leaf_request_closed只证明leaf已停生成、held req/未提出permit已本地结清，不是DS REQUEST_CLOSED ACK；REQ350/CERT410的request_closed则是DS已保存REQUEST_CLOSED/ACK274事实，防止LOCAL_OK与父ACK互等。producer0CLASS writer、1GRAD writer、2Canny EDGE writer、3QUEUE、4STATE_CACHE、5FRAME_FEED、6RC_STAGE、7Sobel EDGE writer；各producer用对应client/phase/region。kind0LOCAL_OK、1REJECTED_NOT_STARTED、2FAILED_DRAINED、3Q；失败kind2且error0仅在可信匹配取消时合法。三个顺序writer分别核P/N/A；非像素producer不把BFS操作数塞pair21，未适用计数字段规范0，完整算法计数另留原status。raw_mc_valid0时raw_mc_error0。LOCAL_OK要求本leaf的段release/local借用结清，**不含phase fence**；每required producer独立证据槽，C0先保存再fence。

PROCESS_BORROW_RETURN702=scope623/borrow_kind3/borrow_seq64/local_closed1/drained1/kind2/error8，ACK708=原body/status2/error4。FM在形成job前登记最多五个role：0FE独占、1输入route、2Canny执行、3RC执行、4普通result writer，5…7非法；未用role不登记。借用seq预授时锁定，return只能命中完整scope/kind/seq及已有登记，拒绝坏job不归还别人的对象。

borrow kind0仅由丰富FE_RETURN1628接口返回，FM从其已保存完整FE绑定查role0/FElease；通用702只接受role1…4，防止同一FE借用两个独立归还消息。两种格式进入同一有限role账本，rich FE ACK1634与普通ACK708各自独立，不等最终status。归还kind2编码0CLOSED_OK、1CANCELLED_DRAINED、2FAILED_DRAINED、3Q；local_closed1/drained1的前三种才可归还，Q不释放。error8是本联合归还原因枚举：0NONE、1REJECTED、2FE、3FEED、4ALGORITHM、5MEMORY、6CANCELLED、7RESET、8COUNT、9IDENTITY、10INTERNAL，11…255非法。它分类原因，原FS/feed/Canny/RC/MC完整错误与数量必须另存，不由error8截断复制。CLOSED_OK要求error0，普通取消kind1/error6或明确未启动kind1/error0须匹配可信取消/no-session记录；失败kind2非0。

Canny client4阶段0分类、1seed、2closure、3EDGE；RC client5阶段0提点、1scatter/圆、2矩形、3核验/ANN。二者phase编号不冲突，client属于key。六CAPTURE C0/p0、三DISPLAY C1/p0、一个PROCESS中C2/p0＋C3/p0＋C4四阶段＋C5四阶段、DIAG C6/p0，保守总20≤32。Canny的23个局部FSM状态不等于23条phase记录。

每scope保留7×4 opened/closed bitmap与累计failure到scope close；phase释放前证书已被父消费并合并，失败不因cold记录复用丢失。DISPLAY重复扫描用新scan_token64，不重开同scope/client/phase；关闭token在首次open预留。grant返回只释放授权端点，不使SRC/EDGE/GRAD/ANN数据自动无主。

PROCESS grant切换：旧Canny CLASS/QUEUE/GRAD/EDGE四grant和FRAME_READER的SRC grant全部完成读写关闭、证书消费、段与phase pin归还、GRANT_RETURN ACK消费后，下一沿才授RC九grant（SRC/EDGE/GRAD/META/POINTS/SORTED/CIRC/RECT/ANN）；workspace数据租约不断开。ANN为result-owned AUX5只由RC写，Display RO；五TEMP子区workspace-owned AUX5，按地址范围分别授权，不授整个workspace写权给显示。数据图沿两个既有地址算术清单，不扩大A到页分配尾。

### D4. 显示保存、执行和关闭

DISPLAY_ID687=scope623/offer64。OFFER1963=scope623/offer64/source_cfggen64/rendergen64/W11/H11/mask3/三desc96/三grant241/render112；各图顺序SRC/EDGE/ANN，receipt1969。SRC始终存在且BIND保持；扫描mask按旧DP模式，mode3=010不撤SRC。不存在EDGE/ANN时对应字段规范0。

PLAN522=plangen64/targetscan64/currentH68/currentOffer64/candidateH68/candidateOffer64/currentValid1/candidateValid1/policy64/epoch32/link32；新增业务ACK528=原body/status2/error4。core先保存一个future_plan的最多两条完整OFFER路线、pin及收尾资格才ACK；CDC运输ACK只证明复制。视频在ACK成功消费后认为预取路线已授权；core保存沿之后即可按已保存路线预取，不等待未来SELECTED。

ROW336=bank2/bankgen64/scopeH68/offer64/scan64/target_y11/source_y11/required3/pairs11/mode3/link32/filled3；OWNED342加2/4，release343加kind2/drained1/reason4，ACK349再加2/4。三个bank各独立depth1；完整required写齐、段terminal/release与WE/pending关闭才提出。身份/坐标/模式/scan/link均从pin住的完整路线核验，不能改scan重发旧数据。release安全ACK运输已保存、两端旧引用关闭后提交FREE，下一沿复用。

SELECTED1013=ID687/scan64/plangen64/hasActive1/useData1/safeReason4/policy64/epoch32/link32/rendergen64；ACK1019。CLOSED921=ID687/scan64/plangen64/rendergen64/dataPairs21/frameOK1/partial1/underflow1/pixelClosed1/adapterClosed1/error16；ACK927。APPLIED1503=newID687/oldID687/oldValid1/scan64/rendergen64；ACK1509。每种消息独立depth1及业务ACK；先到CLOSED可BUSY，但不能阻独立SELECTED保存。

useData0没有image执行上下文、不产生或等待CLOSED；若future token已预取，仍必须明确未选决定，未选已exposed ROW独立DISCARDED。current_exec资格不因later future_plan失效；下一PLAN业务交付等本次SELECTED消费，SELECTED不等下一PLAN。实际bundle切换才APPLIED，父业务消费后对应old才RETIRE。

ownership terminal840=ID687/kind2/closeSuccess1/drained1/error16/requestClosed1/fenceClosed1/localClosed1/rowsClosed1/serializerClosed1/cutoff64/lastScan64；DP原kind编码继续有效。status消费后独立return687回ID，ACK693。没有实际image scan时lastScan=0，不能使用未来预取token；没有真实req时cutoff=0。terminal不等父grant/scope/mirror CLOSE或FREE；真实serializerClosed依据仍DJ-B03。

### D5. 有界容量与端到端相容检查

| 容器 | 上界/容量与允许条件 |
|---|---|
| FM source/result | 6/3；一个源最多LATEST/FREEZE/三BIND五位；result从预留到最终FREE保持同源 |
| PROCESS/FE/workspace | 1/1/1；输入、FE借用可结束，物理result/workspace数据继续由父保留 |
| DS scopes/grants | 峰11/16、峰25/32：6CAPTURE＋3DISPLAY＋1PROCESS＋1DIAG；grant6＋9＋9＋1；Canny旧grant先返还才授RC |
| DS phases | 保守20/32；不靠提前释放历史记录降低预算，opened/closed bitmap留至scope关闭 |
| DP bundles/rows | 总bundle≤3，不把candidate1/active1/retiring2相加成4；3row bank；current1/future1/closing scan1只引用已有bundle |
| 控制/关闭邮箱 | START/START_CLOSURE、status、return、FS/feed、PROCESS_SAFE、PLAN ACK、SELECTED/CLOSED/APPLIED各独立实际depth1通道，按有限对象预留待发资格；两个RETIRING各保留terminal/return上下文及待发资格，可从稳定bundle拼body，不能覆盖另一退休记录；不会增设无限历史队列 |

采集身份已保存后ARM，满足下游旧上下文；直播首像素晚于FJ fire，源DDR成功不阻直播，但发布仍等完整源成功。输入归还独立ACK满足RC先return ACK后status；CAM/DP仍status后return。LOCAL terminal先收再fence满足writer收尾；父scope CLOSE仅在所有义务关闭之后，不能成为它们的前提。

关闭等待图：子local终态不等parent fence；借用return ACK不等parent FREE；段release不等phase fence；ROW release/CLOSED不等scope fence；首行不等SELECTED；SELECTED不等next PLAN。各独立收证槽在授予前保留，既有义务被后续BUSY/容量耗尽阻断属于失败，不能以“慢任务允许”接受死锁。

六源仍不证明持续采集：3个不同BIND源＋FREEZE1＋LATEST1＋capturing1已用6；若旧WRITE_DRAIN尚在，下一SOF可能无槽。必须证明尾租约期限或明确重新预算，不丢弃唯一latest遮蔽容量问题。

## E. 局部状态、不变量与中文操作草图

source_state3固定0FREE/1RESERVED/2CAPTURING/3WRITE_DRAIN/4COMPLETE/5QUARANTINED，6/7非法。result_state3固定0FREE/1WORKING/2PENDING/3DISPLAY/4RETIRING/5QUARANTINED，6/7非法。只有被证明cold safe初始化后才FREE；RAM旧字节不整阵复位，以记录valid/代次隔离。源保存camera cfg、三result各保存J/C570/render。结果完整但pending满仍WORKING+complete。

| INV | 建立、更新及保持理由 |
|---|---|
| DJ-INV01 | 起始真实SOF采用已锁Origin/ARM；任何后续消息都回同完整scope，避免源身份分裂 |
| DJ-INV02 | 所有短引用只访问已pin完整记录；归还ACK和pending关闭前不能换代次 |
| DJ-INV03 | 物理result BIND由FM唯一管理，不因input/FE/算法return而减少 |
| DJ-INV04 | req实际握手先计；错误/取消只影响后来新增及发布，不能消除当前事实 |
| DJ-INV05 | local_terminal、输入return、finalstatus及fence各有独立保存/接纳条件，不能反向等父FREE |
| DJ-INV06 | 同(scope,client,phase)open一次；phase token、opened/closed和失败摘要不因cold slot复用丢失 |
| DJ-INV07 | 数据写授权关闭后才给下游RO；GRAD数据租约持续到RC最后实际读取与归还 |
| DJ-INV08 | future计划不撤current执行；safe未选只结已有预取，不等待不存在的CLOSED |
| DJ-INV09 | 新引用和旧减引用先原子合并再判FREE；FREE提交沿不重新分配 |
| DJ-INV10 | Q/drained0有效通知不可改写；恢复另走完整旧scope两阶段证据，不以新epoch作排空 |

### DJ-OP01：首SOF前预留并启动

检查旧FREE源、generation/序号及CAM/DS/PL收尾资格；分配完整Origin/capture scope、cfggen及cfa。若需要LIVE，另原子预留result/BIND、业务C/FE_BIND；无处理容量只采集。先完成可信scope/mirror OPEN/grant/phase与CAPTURE_LEASE保存，再提出ARM。所有held body在stall不变；ARM保存沿的SOF仍用旧ARM，不启动新身份。

真实完整SOF采用旧有效ARM，pixel提出START，RAW数据照常前进；独立START槽不能反压NORM/closure。FM匹配START只置start_seen并单调合并阶段；仅旧RESERVED且无EOF/失败/Q时进入CAPTURING，不将WRITE_DRAIN/失败/Q倒退。无SOF取消保持RESERVED直到START_CLOSURE的真实NO_START_PROVEN及旧ARM/RX/授权义务关闭，不合成START。status先到先存；START_PENDING仍不回收，NO_START_PROVEN不等待不会发生的START。

### DJ-OP02：采集完成、归还和latest

真实EOF后进入WRITE_DRAIN；CAM继续收late error/NORM pending，等待closure累计committed水位被连续消费、RAW窗口/RGB及writer实际关闭，段成功和fence齐全才形成不可变STATUS808。FM及时消费并保存，CAM随后return623；ACK仅登记借用关闭，不等parent CLOSE。

FM合并START及START_CLOSURE、status、return、写fence/真实RX闭合；再等CAP phase RELEASE ACK、CAP写grant RETURN ACK、CAP scope CLOSE ACK及mirror CLOSE ACK实际保存之后撤writer，全部成功才COMPLETE/latest并允许SRC RO。这些父关闭不反向阻CAM return的独立接纳。按capture_sequence选更晚成功者，旧帧晚完成不替换较新latest。先合并本沿FREEZE/BIND新增与LATEST/旧BIND撤销，再判无写者/保留位/借用/消息/Q才FREE。失败不进入latest，仍须真实排空；下一沿才重授。

### DJ-OP03：完整供料与共享FE归还

旧空闲管理器先核1628，保存完整PROCESS/C/Origin/route/lease；按这份FJ提出任务，eF fire后最早下一ACTIVE沿送第一FP74。LIVE若首SOF前未完成合法绑定，本帧不半途补接；已held FJ仍兑现，随后ACTIVE沿cancel，不能只在FJ接纳同沿打一拍取消。

DDR route仅COMPLETE源。reader用两个1024B bank、四条20×512并行成64bit word，高16规范0，bank地址0…127/128…255。R128先锁holding，再两次64bit整字WE；保存本段真实/physical长度，全部接收且terminal/release ACK后SEALED，独立bank交替。同步RE先预约，下一沿capture；未capture的pending先结清，不用不确定同址碰撞。

RGB carry最多5B，加下一64bit word最多13B，容器112bit；按6B一pair分离RGB48。formed_pair_index21在pair装入预约FP槽时推进，delivered_pairs21仅FP fire推进；坐标/标志取formed旧索引，0≤delivered≤formed≤P。RE按旧carry及本word真实字节数m0…8（越L的padding不入carry）求g=floor((carry+m)/6)≤2，须g个FP槽全部预约且无另一改carry的pending才发；下一沿capture形成g槽、remain≤5，预约capture不受后来stall撤销。两槽按顺序交付、held坐标/payload保持；行末/beat末不flush，全图EOF carry应为0，padding不计pair。匹配FE终结后DISCARD旧未fire项，旧DDR段/pending先关。bank除MC terminal/release外，还需自身全部64word读/capture及本地借用关闭才回收；复制到FP的数据继续pin PROCESS/FE，不占旧bank也不等整scope fence。

FS163与feed253各独立保存，FS ready不等源fence、Canny finalstatus或FE_RETURN。真实FS与真实reset-applied证明分开。按D2三分支独立保存真实FS或可信reset/no-session，不等旧FP先清空；匹配终结后DISCARD未fire FP并关feed/queue/holding/FE借用，才提出FE_RETURN；FM ACK不解除BIND，也不等结果发布。输入无法证明排空保留Q，不让迟到FS解释成新job。

### DJ-OP04：局部输出证据、fence及RC移交

各writer冻结合法pair/pixel/物理写量，尾carry/padding和已授权dirtyWB继续有限收尾。LOCAL_OK只含该writer和本地段关闭，不含父stage fence；JOIN先独立收证，之后再形成REQUEST_CLOSED、seal/fence。未启动writer用required0或可信no-session，不造完整成功数量。

算法输入借用return通道独立于finalstatus，FM核已登记借用后ACK，不等结果FREE/发布。Canny/RC最终status汇合local_result、必需证书和对应return ACK；原RC的return ACK→status次序保持。真实数量/错误完整保存，不用一个drained布尔代替未查明的证据。

识别启用时，在旧Canny/reader证书消费、phase/段pin及Canny四grant和reader SRC grant全部RETURN ACK消费之后，下一沿安装RC九grant；workspace数据仍属于此J，GRAD不可被下一Canny覆盖。RC四phase最后真实读闭合/归还后才解除workspace物理租约。RC packed数值job/profile仍DJ-B04，不能将本步骤写成已完成所有识别设计。

### DJ-OP05：阶段/permit/授权关闭

停止新业务与停全部prepare分开：旧授权的有限tail/WB仍可prepare；已proposed req保持并兑现，未proposed permit在req_valid0且无本沿req曝光时明确归还。全部请求生成结束、held req/permit已闭合后提交REQUEST_CLOSED，锁真实count/last_seq，不以缓存empty猜末水位。

seal后不再接新prepare，旧段terminal/release、本地capture与证书输出继续；证书只证明其固定key/masks/cutoff覆盖范围。父消费证书并合并scope sticky error后申请phase release；cold lookup/holding/段/permit引用为0才ACK。phase物理slot回收不清scope bitmap。grant return在最后所有phase借用关闭后完成，scope close最后；AON mirror CLOSE更后，绝不作为先前return的等待条件。

### DJ-OP06：发布、预取和实际scan

JOIN逐项比对源COMPLETE、完整J/C、算法成功及输出fence/策略；合法空识别表可以成功，溢出不能成功。complete结果pending满保留WORKING；有空间形成不可变OFFER，先预留所有scan/关闭序号及事件槽。DP保存receipt不改变实际active。

PLAN业务ACK后按已pin路线预取首行，ROW数据写齐并本段/local借用关闭才READY。VSYNC按旧row0/策略/容量选择candidate、重复或safe；SELECTED真实保存，core建current_exec并停止未选路线新读。future不能撤current；safe仍为已有预取交付未选决定。真换bundle才APPLIED，FM消费完整new/old后登记退休，UI复制快照不反压此链。

### DJ-OP07：行、scan、bundle三层关闭

row最后实际使用后关本地RAM/holding/pending，独立release，不能等scope fence。scan最后真实数据slot且pixel/adapter引用关闭后形成CLOSED；不等next PLAN或下一首行。先到CLOSED回BUSY仍让SELECTED独立前进；useData0不等CLOSED。

停止旧bundle新row，兑现旧授权有限请求，REQUEST_CLOSED/fence与旧row/scan/serializer关闭并行。840消费后DP独立return687，FM ACK只登记端点借用关闭。本result所属端点风险、段/phase/grant/scope关闭及mirror CLOSE ACK齐全才解除其BIND并回收result；同源其他BIND/LATEST/FREEZE只阻source FREE，不反向阻已退休result归还。源全部引用原子合并后才判source FREE，下一沿复用。

### DJ-OP08：取消、同沿事件和故障恢复

同沿先登记旧真实req/W/R/FP/FS/ACK及当前valid曝光，再合并取消/失败、策略和引用。禁止失败发布，但不撤真实握手；已经valid的body/终态保持。新增容量不足只拒新会话，已有关闭资格仍可用。

暖reset保留scope/permit、已held req/W/R、bank/pending、关闭消息与CDC会话，停新授权；私有未承诺流可隔离。物理效果未知进Q，旧drained0通知不改。镜像OPEN已ACK的旧scope，先匹配PREPARE808及0x11，实际处置旧borrow/消息回QUIESCED；FINAL808/0x3F与done814实际消费后才解除旧保持/mirror pin。新PHY epoch不能接旧exposed valid，也不能代替排空证明。

## F. RTL、参考与资源契约

本稿不选择C++，其对象/RAII不适用。未来Python独立参考和RTL协议检查均在批准后生成；数字图结果与服务/时间验证分开。

| RTL项 | 当前合同/来源与边界 |
|---|---|
| A数值 | D明确字段/枚举；先扩位检查再窄化；bitmask固定语义，原MC/feed/raw错误各自保存 |
| B时钟 | core正沿fire；新寄存输出沿后稳定，下游下一正沿采；像素域SOF用旧ARM，跨域按PL mailbox而非逐位同步 |
| C接受 | 控制valid&&ready；无ready相机只能预授权并保证容量，缺容量是采集失败不当算法跳帧 |
| D推进 | valid0不计数；服务count只实际req fire、pair只实际FP fire；预约RAM读必须capture即使停止新业务 |
| E保持 | 所有held body/valid及旁带保持；可变C不改变在途；后续BUSY不夺既有关闭槽 |
| F时间 | FJ接纳与首FP分沿；FREE提交下一沿复用；MC/CSI/serializer/仲裁最坏时限尚DJ-B01/02/03/05 |
| G复位 | 暖保持表E08；冷safe依据DJ-B03；RAM不整阵清零，记录valid隔离旧字节 |
| H配置 | source camera cfg、result C570/render分离；同沿CFG更新/job接纳用旧快照；profile实体DJ-B04 |
| I存储 | reader四RAM双bank，同步RE预约/下一沿capture；SEALED只读/OPEN只写，输出holding承接pending；DS和DP按原有限容器 |
| J身份 | 完整scope/J/Origin＋pin引用；FP row-major N/2，RGB888字节R0G0B0R1G1B1，padding不增加像素 |
| K CDC | START/ARM/closure、DP各事件及mirror独立mailbox，先预留收尾；运输保存≠业务生效，相关HDMI clock不是任意异步false path |
| L实现 | Ti60F225/I3、Efinity2026.1.132/Questa2024.1候选；SV支持及受保护IP需既有获批真实检查；不由旧outflow称新工程通过 |

已列RAM10：Canny44＋DS17＋RC58＋PL30＋CAM13−旧DP FIFO9＋DP row21=174；FRAME_READER本地双bank另加4，**178/256=69.53125%仅容器预算**，非综合利用率。DS client2服务段槽不是本地reader bank；CAM源写bank、RC池没有与其复用合同，不能抵扣。宽body副本、ACK/valid、完整scope/J/C、scalar算术、字体/ROM和全部FF/DSP另计，仍DJ-B04/05。

数值参考按原各局部合同比较灰度/边缘/几何，协议参考按完整scope、坐标、配置及实际fire日志比较；不能用静态数学结果替代PHY/CDC/STA。软件原始真值及分类P/R、IoU验收不随优化改变。

## G. 实施及验证计划（全部NOT_RUN）

实现前须取得无当前阻塞的指定设计和相关范围批准。计划职责位于独立work内fm_binding_registry/frame_reader/fe_session_join/ddr_control/phase_certificate/display_join/top-level holding及验证，当前均未生成。按可信绑定→采集/供料→阶段/归还→显示执行→恢复→整机逐增量，不复制原HDK覆盖。工具/模型与正式DB前置沿原制度。

所有下表为文字场景：获批后在匹配Questa/真实IP中做波形与协议对照，core在正沿握手前值计事件、NBA后观察新状态；涉及跨域覆盖不同相位/反压/暖故障。每项成功须身份、数量、效果/引用、保持和终结均符合D/E；出现任何错对象访问、重复/漏交、提前FREE或无法解释的等待即失败。设计走查不能把其执行状态自动改PASS。

| TEST | 目标/输入与事件 | 期望及依据 | 执行状态 |
|---|---|---|---|
| DJ-T01 | J01/IF02：ARM保存与SOF同沿 | 使用旧ARM，新Origin不被本沿SOF采用，E01 | NOT_RUN |
| DJ-T02 | J01：正常START，status先到 | 独立保存、阶段不倒退；START_CLOSURE SEEN及相应义务关闭才回收 | NOT_RUN |
| DJ-T03 | J01：RESERVED无SOF取消 | 不造START/CAPTURING；仅真实NO_START_PROVEN和ARM/RX/授权关闭后回收 | NOT_RUN |
| DJ-T04 | J02/IF01：伪造scope/grant body | 拒绝、不读写、不归还其他对象 | NOT_RUN |
| DJ-T05 | J02：旧短H与新gen同slot | 旧pin/代次不匹配拒绝，不能重建当前scope | NOT_RUN |
| DJ-T06 | J03：LIVE在首SOF前未绑定 | 本帧仅采集；held FJ兑现后ACTIVE取消，不半帧补接 | NOT_RUN |
| DJ-T07 | J03：DDR RGB跨beat/行/尾 | 6B pair与row-major一致；末padding不算pair | NOT_RUN |
| DJ-T08 | J03：carry5B/word8B、只空1个FP槽且有pending | g2未全预约不新RE，旧pending仍capture；formed/delivered/holding不覆盖 | NOT_RUN |
| DJ-T09 | J03：FS早于fence且INPUT_BAD尚有held FP；另测no-session/reset | 独立收FS；终结后DISCARD未fire项，return不等fence/BIND且不造FS计数 | NOT_RUN |
| DJ-T10 | J04：RC先return ACK后status | FM独立ACK，不等status/发布/父FREE | NOT_RUN |
| DJ-T11 | J04：writer LOCAL_OK早于fence | JOIN先收证，再request_closed/seal，不互等 | NOT_RUN |
| DJ-T12 | J04：旧Canny grant移交RC | 全部证书/pin/return ACK结清后下一沿授权；GRAD仍保留 | NOT_RUN |
| DJ-T13 | J06：C0/4/5不同phase0 | client纳入key，phase records≤20，旧bitmap保留 | NOT_RUN |
| DJ-T14 | J06：DISPLAY重复scan | 新scan_token、不重开phase0、不生成无界cold历史 | NOT_RUN |
| DJ-T15 | J06：关闭后cold slot5复用 | 原证书/ACK已消费且无借用，下一沿才复用，失败摘要保留 | NOT_RUN |
| DJ-T16 | J05：future首行与SELECTED | 首行无需SELECTED；PLAN业务ACK不同运输ACK | NOT_RUN |
| DJ-T17 | J05：CLOSED先到且BUSY | SELECTED独立可接，后续CLOSED重试不丢scan身份 | NOT_RUN |
| DJ-T18 | J05：safe未选且已有ROW | useData0不等CLOSED；明确未选及ROW DISCARDED | NOT_RUN |
| DJ-T19 | J05：future更新/当前scan未结束 | current_exec保持旧授权，future不撤current | NOT_RUN |
| DJ-T20 | J05：两RETIRING＋active | bundle总3，无第4上下文，旧return不等父close | NOT_RUN |
| DJ-T21 | J07：CFG更新与result/job同沿 | C取旧快照；source cfg不变；render与同result关联 | NOT_RUN |
| DJ-T22 | J06/J08：新增FREEZE与旧BIND归零同沿 | 引用合并后仍保留源，不在中间判FREE | NOT_RUN |
| DJ-T23 | J08：末req/取消/fault同沿 | 真实握手及曝光照计；旧valid/Q终态不改写 | NOT_RUN |
| DJ-T24 | J08：暖reset、PREP/FINAL恢复 | 完整旧scope证据闭合前无重授；不靠epoch/cal_done假排空 | NOT_RUN |

后续真实资源/时序/引脚/bit验收仍按主计划和07，不把本表代替十一项质量/综合证据。实际物理型号/配置结果由真实模型、PHY校准、地址边界和恢复测试证明，不能换成行为存储仅让表中协议通过。

## H. 双向追踪

| REQ | MOD/IF/草图/INV | 计划核心职责（尚未生成） | TEST及期望 | 实际代码/证据 |
|---|---|---|---|---|
| DJ-J01 | MOD03/04；IF02；OP01/02；INV01 | capture reservation/start join | T01…03，旧ARM采用与来源完整 | 未实现/NOT_RUN |
| DJ-J02 | MOD04/05；IF01；OP01/05；INV02 | trusted scope/grant registry | T04/05，拒绝错对象 | 未实现/NOT_RUN |
| DJ-J03 | MOD06/07；IF03；OP03；INV03 | frame reader/FE binding manager | T06…09，实际pair/FS/feed | 未实现/NOT_RUN |
| DJ-J04 | MOD08/09/10；IF04；OP04/05；INV04/05/07 | child local/status/return join | T10…12，独立证据与移交 | 未实现/NOT_RUN |
| DJ-J05 | MOD11/04；IF05/06；OP06/07；INV08 | display plan/scan/retire join | T16…20，真实应用与关闭 | 未实现/NOT_RUN |
| DJ-J06 | MOD04/05；IF01/05；OP05/07；INV06/09 | capacity/phase history/ledger | T13…15/20/22，有界与下一沿复用 | 未实现/NOT_RUN |
| DJ-J07 | MOD12/04；IF07；OP01/06；INV01/03 | immutable C/source/render binding | T21，旧快照及同源 | 未实现/NOT_RUN |
| DJ-J08 | MOD01/05及各client；IF08；OP08；INV10 | promise holding/recovery | T23/24，真实旧义务关闭 | 未实现/NOT_RUN |

任何拟核心单元先返回此表REQ/IF，不以追加空泛需求解释无关结构。获批后才填真实文件/符号与哈希、实际TEST结果；正文中的接口名目前是设计，不冒称已存在RTL。

## I. 门槛与评审

①整体/样例B；②职责/连接/来源A/C；③明确联合字段及相容D，外部事实仍B01…03；④状态/十INV/八草图E；⑤语言/映射F，RC实体与完整预算B04/05；⑥端到端/互等反例B/D/E；⑦实施/24场景/双向G/H；⑧无正确性阻塞**不满足**；⑨保存/读回/审查由05记录绑定；⑩v0.1范围/旧基线A/J明确。故保持LOCAL_DESIGN，尚非READY，不创建业务工作副本或可执行测试。

本稿可闭合明确内部交接，不自行扩大为整机无阻塞。批准需真实用户指定版本/范围/基线；通用继续目标和配置调整授权不等于本稿实施批准。理解验收待用户实际作答，不阻塞允许的设计工作，也不作为获批后交付考试。

## J. 明确覆盖、阻塞分类和恢复

| 旧候选/阻塞 | 本稿实际覆盖 | 仍保留的缺口 |
|---|---|---|
| FM-OP01在首SOF分配身份，CAM-B03 | OP01/D2改为先RESERVED/完整lease/ARM，SOF只采用；cfa命名及status/return固定 | CSI真实错误/发端界和持续采集期限B02/05 |
| DS-B04/B08、Canny父P-J01/P-F01 | D3可信scope/grant/phase控制、完整pin、独立local/return与闭合顺序 | 实际MC行为B01；RC完整数值jobB04 |
| RC-B04/05中的内存角色/父归还 | 五TEMP/ANN归属、九grant与workspace持续、FM独立ACK | 参数/记录/算术/算法本体没有由opaque引用闭合，B04 |
| DP-B03、FM-B03/04端口部分 | OFFER/PLAN_ACK/ROW/SELECTED/CLOSED/APPLIED/terminal/return完整保存语义及有界容量 | adapter/serializer真实关闭B03、最坏行服务B05 |
| CJ-B01中的stage error与data引用 | D1 error4扩展10…15、有界原body注册与pin；控制阶段原语义保持 | 真实外部合同、RC实体、全预算/权限未关闭 |
| “综合/仿真未运行”混作设计未知 | 已定合同检查移到G及验收NOT_RUN；不要求先写未批准代码证明READY | 尚未定义/缺外部事实的B01…05不能挪成普通测试 |

ALREADY只在有限活跃登记内完整原body及已完成效果匹配时返回；已忘旧seq回REJECTED/OLD_ANCHOR，不假装完成。BUSY/CAPACITY无效果、不登记完成；同V的PREP→COMMIT是有守卫续阶段。SNAPSHOT NO_ACTIVE规范零Origin合法，完整保存及anchor核验后ACK可成功，不等FREEZE建立，也不报TARGET。raw error retain named mapping，不能截断塞error4。

恢复先读本稿/Control-Join、旧基线哈希、真实批准、相关依赖及工作副本差异。任何新工具/模型/接口变化先判断影响；本轮旧稿、模型请求、正式DB/Manifest不改。新接口/body是批准前候选，未取得新范围批准。

## K. 实现与验证实录

本轮业务源码、功能脚本、可执行测试、testbench、真实PHY/校准、综合/引脚生成/PNR/STA及bit/hex全部**NOT_RUN / 未生成**。只读审查/文档读回见对应05记录，既有52MD审计以原字节保存在document-checks-control-join-v0.1.json；当前审计须重新绑定本稿和索引。

本稿没有重写原HDK、写数据库或正式H0状态，没有网络/下载/安装、没有硬件编程或观察；历史参考bit/hex不属于本次交付。软件目标仍不满足，目标保持active。

## L. 阅读与交付说明

这份文件把整体路径、局部之间的交接及局部内部中文步骤按B/C→D→E顺序集中，避免另造许多合同副本。草图先看OP01采集身份，再OP03供料、OP04/05阶段、OP06/07显示、OP08故障；从H按一条REQ找未来实现与实际测试。

最终实现后仍需按真实符号/参数/状态/时钟/数值逐项复核文档—注释—代码—测试一致性；当前无代码，不能声称一致性已经验收。十一项软件、真实工具运行、质量/资源/时序及bit/hex仍待完成，本稿只交付联合设计分析。
