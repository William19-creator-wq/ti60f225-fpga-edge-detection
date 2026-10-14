# DISPLAY 取数、行bank与扫描草图 v0.1

2026-10-04；TRACK4-DISPLAY-001局部附件；**LOCAL_DESIGN / NOT_APPROVED / NOT_READY**。仅中文设计、接口候选、算术与文字场景；未生成业务RTL、功能脚本、可执行测试或TB，未运行仿真、综合、PNR、STA或硬件。原始资料只读。

- Goal：完整1920×1080@60Hz输出同源RGB、EDGE与ANN；任意DDR停顿不暂停视频扫描；冻结保护实际active绑定的原RGB。
- Current/Gap：父FM v0.1尚未定完整bundle；PL v0.1仍列PIX168 FIFO；DDR v0.1与RC v0.1尚未共同冻结ANN授予/显示生命周期。本文选择替代运输并明确差异，不把旧接口视为相容。
- Dependencies：[master v0.11](../../../planning/design-TRACK4-FULL-SW-001.md)、[FM v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)、[DDR v0.1](../../../planning/design-TRACK4-DDR-SERVICE-001.md)、[PL v0.1](../../../planning/design-TRACK4-PLATFORM-001.md)、[RC v0.1](../../../planning/design-TRACK4-RECOGNITION-001.md)、根v0.2/PLAN_TEMPLATE。
- Milestones：整体/父字段统一→局部草图→主附件实际读审→关闭阻塞→指定版本批准→以后才允许实现和测试。当前停在设计。
- Completion/rollback：本页保存、读回及hash只证明文档存在；若改变bank、位序、时钟、模式、token或释放规则，先修订父子设计，不直接实现。

阅读：§1整体与八接口→§2模式/图格式→§3DDR与展开→§4双域bank→§5扫描逐沿→§6应用/冻结/退役→§7预算→§8场景与阻塞。父DISPLAY负责完整offer/control/APPLIED事件body和父租约，本页不重建scope/grant类型。

## 1. 整体、事实和接口前提

FM/JOIN在源COMPLETE、结果成功fence后，给同一SourceOrigin195的不可变完整bundle。CORE DISPLAY取数器以client1/R逐段读所需图，将**一整行**存入三个物理row bank之一；PIX74.25只读取已经交接且与本次scan/target_y匹配的bank。相关148.5域依次消费lane0/lane1；专用半率serializer的742.5双沿发送10bit符号。安全像素、HS/VS/DE由本地固定扫描产生，DDR没有视频ready。

v6归档只读来源是`Ti60f225_sc431hai2hdmi_v6.rar`，SHA256见[clock来源](../01_baseline/platform-clock-pin-evidence-v1.md)。原top255…263给1920/1080、HFP88/HSP44/HBP148、VFP4/VSP5/VBP36，566…573将水平参数除2交74.25域。旧top735…775直接跨相关slow域交替取两lane，旧Debayer颜色排列和HDMI bypass有R/B变化；这些是来源，不能直接成为新色序/相位正确性证明。新bit位序为FE canonical RGB；板PN四路补偿恰一次，见[板来源v2](../01_baseline/board-pin-source-evidence-v2.md)。

**结构选择：3个独立双clock row bank**，保存active current、active next及candidate row0；不能用两行挤这三个角色。旧PL PIX168深512 FIFO被替代，不能又计9RAM或沿用其逐项scope/coord字段。所有row身份存入不可变descriptor，RGB/EDGE/ANN扫描项由它产生。scope上下文最多沿FM三个结果槽，RETIRING可以两槽；不能有第四个隐藏bundle。

| IF | 提供→使用；字段、前提和保持 |
|---|---|
| DF-IF01 bundle/控制 | 父→DISPLAY完整DISPLAY scope623、SourceOrigin195、source/result完整代次、offer/control/policy序号、SRC/EDGE/ANN各base/L/A及RO grant引用、render112；三图及策略相容、写可见和只读授权成立后才能接纳。父完整packed offer/control/status仍待主稿闭合 |
| DF-IF02 scan计划/实际选择/关闭 | PIX→CORE独立SCAN_PLAN522：plan_generation64/target_scan_token64/current_scopeH68/current_offer64/candidate_scopeH68/candidate_offer64/current_valid1/candidate_valid1/policy64/epoch32/link32；future_plan保存未来active/candidate两route，与current_exec_authorization独立。实际VSYNC另发SCAN_SELECTED1013/ACK1019；该scan局部结束另发SCAN_CLOSED921/ACK927，字段和容量见OP06。三个类型独立槽，future预取不等SELECT，transport ACK不替业务选择/关闭 |
| DF-IF03 DDR | CORE↔DS-IF02…06，client1、opR、phase0；SRC region4、EDGE region3、ANN region5；prepare198/permit68/req266、R155、terminal301、release288/ACK293。ANN范围必须由父/DDR真实安装，旧稿缺口不能自授 |
| DF-IF04 row准备/拥有 | CORE→PIX ROW_READY336：bank_id2/bank_gen64/scopeH68/offer_sequence64/scan_frame_token64/target_y11/source_y11/required_plane_mask3/pair_count11/mode3/link_session32/filled_plane_mask3。PIX→CORE ROW_OWNED_ACK342=原336+status2/error4；每bank独立depth1保存及业务容量。ACK编码使用父主稿，未定者不自行解释成成功 |
| DF-IF05 row归还 | PIX→CORE ROW_RELEASE343=原336+kind2/drained1/reason4；CORE→PIX ACK349=原343+status2/error4。kind0 CONSUMED、1 DISCARDED、2 QUARANTINED、3非法；Q/drained0不释放。READY已提出尚未OWNED也必须按协议结清，不撤held body |
| DF-IF06 无反压扫描 | PIX→相关slow148.5，canonical RGB48与同一slot的HS/VS/DE/坐标、scan/scope引用；固定lane0先、lane1后。没有DDR反压，相关generated-clock/phase及专用IP位序待证；不以通用异步同步器替代lane关系 |
| DF-IF07 父业务事件 | DISPLAY→父：APPLIED、RETIRE_DRAINED、candidate CANCELLED_DRAINED、FAULT、freeze SNAPSHOT与hold移交，各自有有限不可变保持资格。APPLIED先预留槽再换active，并先于该次旧对象退役；运输ACK不表示父业务槽已空。完整body/顺序以父主稿，未定仍B |
| DF-IF08 平台恢复 | 复用PL完整scope镜像、fault/recovery关联、PREPARE/QUIESCED/FINAL；stop_new只阻新访问，旧req/R/terminal/release、RAM capture及通知继续。时钟未知不靠清指针/valid造排空；重新会话须双方旧消息与借用结清 |

ROW336中的scopeH只引用当前固定完整DISPLAY scope623，不用它代替J或SourceOrigin。所有gen/seq/token递增先扩65bit检查，耗尽停止新授予/DDR计划，物理扫描仍安全输出。业务ROW/OFFER合法mode0…5、bank_id0…2；bank_id3和mode7分别非法，mode3 EDGE合法。mode6仅本地diagnostic，不接纳业务ROW/OFFER、不建立DDR bank。pair_count生产必须960。filled覆盖required，未required平面不读DDR；render112及颜色在bundle锁定，ROW mode与它一致。scope/offer/epoch/link/target/source有任一不匹配先拒绝/丢弃，不去读非法bank，也不归还别人的资源。

## 2. 模式、同源图与逐字节对应

render112=mode3/split_y11/edgeRGB24/ann_circleRGB24/ann_rectRGB24/ann_textRGB24/show_edge1/show_ann1；生产split_y540。颜色是父快照字段，不在此页猜默认颜色。mode0 SPLIT、1 RGB、2 GRAY、3 EDGE、4 OVERLAY、5 RECOGNITION、6 DIAGNOSTIC，7非法。show位只控制绘制，不收窄mode4/5的所需平面全集。

| mode | target_y到source_y；本row所需mask |
|---|---|
| 0 SPLIT | target0…539显示gray，source_y=2×target_y，SRC；target540…1079显示edge，source_y=2×(target_y−540)，EDGE。x原样；上下都覆盖源偶行0…1078，不把当前mode重新解释旧ROW |
| 1 RGB / 2 GRAY | source_y=target_y，SRC |
| 3 EDGE | source_y=target_y，EDGE；白edge/黑背景。原源仍由bundle绑定并保持，用于冻结/重处理 |
| 4 OVERLAY | source_y=target_y，SRC+EDGE；show_edge且edge1时取edgeRGB，其余原RGB |
| 5 RECOGNITION | source_y=target_y，SRC+EDGE+ANN；先原RGB，再可见edge颜色，最后可见非零ANN颜色。ANN优先于edge；code1圆、2矩形、3文字/不同类冲突 |
| 6 DIAGNOSTIC | 本地安全/诊断像素，无DDR row bank；不会成为可重处理的图源 |

plane mask位0 SRC、1 EDGE、2 ANN。SPLIT全局offer资格需SRC+EDGE，但每ROW只读它实际显示的一种平面。map不能假定source_y单调：539→540时source1078→0，必须按新target_y取行，不拼接旧上半区缓存。

SRC逻辑L=3WH；像素i=source_y×W+x，DDR字节base+3i依次R/G/B。两个像素六字节R0/G0/B0/R1/G1/B1重建canonical `{R1,G1,B1,R0,G0,B0}`，不能把48bit little-endian向量直接当canonical。灰度沿用FE：unsigned16 `(77R+150G+29B+128)>>8`，最大65408、输出≤255；三通道复制gray。无gamma、黑电平或RGB互换的暗中变化。

EDGE低地址低bit顺序，i/8及bit i%8。ANN descriptor相对4224为连续2bit map，i/4字节及低位2(i%4)是该像素code；00无、01圆、10矩形、11文字/异类冲突。1920生产每行SRC5760B、EDGE240B、ANN480B，均16B对齐；ANN头128+list4096不插入扫描图。RC字形/笔宽/格式/header完整验证尚B；不以全零map猜识别已经成功。

每row读mask来自锁定ROW，不从运行中CSR猜源坐标/平面。错误/缺平面不能用零值伪装“无边缘/无目标”；disabled平面才显式零并不置filled位。只读对象在pending/active/retiring/snapshot全部引用归还前不可写。

## 3. DF-OP01/02：单client段读取与有限展开

**DF-OP01 计划和仲裁。** 独立保存current_exec_authorization、future_plan双route及其不可变bundle快照，验证scope/offer/policy/epoch/link和图格式，分配真实FREE bank及gen。current_exec只由真实SELECTED确定并pin至本scan CLOSED业务ACK/局部关闭；新future PLAN不能无声淘汰其后续行。未来route按最新合法future_plan预取，不等SELECTED到达，绝不把预取当已选择。CORE每次仅一个client1/R record，active下一行（含下一刷新row0）先于candidate首行发新prepare；candidate只能借剩余机会。已经proposed的candidate req/R不能被新active抢断，须按DS结束当前段；其最坏阻塞计入期限。每段结束可暂停candidate，把未成行的字节/bit尾移入它的descriptor自有carry，再服务active，不能用一个client1 held record等下一段或VSYNC。

地址使用unsigned33末端检查。段头固定byteaddr/nbeats，16B对齐、1…64拍、不跨4KiB、不越grant A；当前生产逐行无行padding。SRC一行360拍，按最大合法段最多7请求；EDGE15拍最多2、ANN30拍最多2，所以满mask一行最多11请求，含4KiB拆段。不能按“一行一次请求”估延迟。三个plane可择序读但每段terminal/release独立计；任一失败使整row无READY。

**DF-OP02 接收和展开。** 客户端两个128bit R holding，valid+reserved≤2，按真实R fire仅保存一次完整data/tag/index/last/error及原scope/row/plane；ready只依旧容量，坏数据同沿仍先计真实握手再锁错误。正常R的n拍计数/index/LAST全部核验；terminal独立及时保存，不等row READY或bank FREE。段正常只在所有本地整拍已展开、旧pending/holding关闭后release；服务RELEASED ACK实际消费后下一沿才可prepare下一段。

SRC展开使用192bit暂存，真实有效最多21B：追加一个16B前旧有效carry≤5B，合计≤21B，容器高未用位零；每core沿最多取一个6B RGB pair，按命名R/G/B重排后一次WE低48、高12零。两RGB48输出holding预留具体q，停顿不重复取6B或覆写；大于等于6B的整pair必须先处理完再装下一R holding，未处理拍仍由有限槽保存。容量不足压低Rready，服务整段池继续独立物理接收。16B拍常形成2/3pair，不能声称每拍总是两个pair或一个沿写三个pair。

EDGE/ANN各用≤19bit bitcarry与147bit（可封装160bit）展开暂存，追加128bit后每core沿一次20bit WE，写入对应packed地址。SRC/EDGE/ANN读段切换前，将不足6B/20bit的尾复制为row descriptor自有值，记录流位置和valid_count，解除对旧service tag/record的借用；下一段消费副本。终结不等待下一段出现，故不会因单record自锁。生产行末5760B/1920bit/3840bit都恰整内部word，正常row carry必须0；padding/页余量不写入下一行。

全部实际req_fire计水位/receipt，全部terminal、release ACK和各plane展开word计账。ROW READY条件：SRC required时960 pair、EDGE required时96word、ANN required时192word；所有实际段正常终结/release ACK消费、core WE/展开holding/pending关闭、carry0、filled覆盖required，且它的current_exec或future_plan授权仍合法。不能以最新future plan_generation与当前执行代次不同为理由废掉正在扫描的后续行。不可“末R到达就READY”或先向PIX暴露半行再补写。

普通candidate取消/计划过期：停止新增prepare，未proposed permit明确返还；held req继续，真实已R照计。kind1/2 drained terminal_fire共同作废未接受held逻辑R，旧capture只DISCARD而不复活valid；kind3不释放。已提出ROW READY/OWNED/release继续交接/丢弃，不能靠清本地role解除另一域旧owner。该scope最终退休封口才fence，不按每个视频刷新close/reopen phase0。

## 4. DF-OP03：三个双clock bank的物理布局和拥有权

每row SRC960×48封装60bit，3条native20×512组成一页，q10的page=q[9]、addr=q[8:0]；一row两页6RAM，三个row18RAM，960…1023不访问、高12零。EDGE每row96×20bit，地址bank_id×96+word，三row共288word用1RAM。ANN每row192×20bit，地址g=bank_id×192+word，共576word用2RAM，page=g[9]/addr=g[8:0]；余字不访问。合21RAM。ROW改变哪个bank是current/next/candidate，不改变物理地址公式。

所有RAM RCLK=PAIR74.25、WCLK=CORE100，OUTPUT_REG=0、WE11写整20bit；双clock支持、建立保持/CDC/STA仍待真实工具。CORE写一bank，PIX只能读已交接的别bank；不同clock同址读写永远由owner禁止，不依READ_FIRST或偶然时序。EDGE一个RAM/ANN某页可能同时RE/WE不同bank地址，这是1R1W候选，不是两个读口。bank数据不用逐项Gray同步，完整行稳定通过不可变mailbox交接。

状态候选WRITE→READY_EXPOSED→PIX_OWNED→RETURN_PENDING→FREE。CORE从FREE分配并填充；提出READY前数据和ROW336已稳定，提出后至合法归还ACK运输保存确认、双方旧holding关闭均不再WE。PIX私有槽有容量才保存READY，运输ACK仅保存证明；之后核验完整body形成独立OWNED业务ACK。CORE不能因运输ACK就开新写，也不能用它假设PIX业务槽空。每bank的READY/OWNED/RELEASE/ACK各有独立保持容量，旧bank通知反压不能占掉别bank的归还通道。

PIX在全部本地RAM RE/capture、54bit pair holding、packed cache不再借该bank后，形成CONSUMED或DISCARDED/drained1 RELEASE343；CORE匹配原gen/scope/offer/token/target/source/mask/link和旧状态，再回ACK349。ACK往返仍持旧body直到运输保存和本端消费结清；下一沿才可FREE/重新分配。坏/重复ACK幂等拒绝或回已登记结果，不释放当前新gen。QUARANTINED/drained0保持旧bank，等平台身份特定安全处置，不单端清state或RAM pending。

bank本地借用与scope引用区分：完整54bit值复制到独立像素/编码FF后，不再借RAM payload，仍保留它的scope/scan引用直到流水消费。**ROW RELEASE不等待整个scope fence**；RETIRE_DRAINED另外等待旧scope的FF/DDR/消息关闭。否则3bank被退休scope长期占住，新active无next bank而不能排空，形成资源循环。

## 5. DF-OP04/05：RAM预取和永不停顿扫描

**DF-OP04 packed预取。** SRC每pair一次RE；EDGE每10pair一次20bit RE，ANN每5pair一次20bit RE。各packed plane有current/next两个20bit缓存、valid及原bank/gen/block/scan/row；已有RE分别保留pending旧page和具体缓存预留。q边界或bank切换不能从新的调度owner取旧RDATA。生产SRC q511→512跨页；ANN bank2的word127→128（q639→640）跨g511→512，capture仍用pending旧page。

EDGE缓存的第r个pair取bits[2r+1:2r]；ANN缓存第r个pair取[4r+3:4r]，低bits对应lane0。缓存位置用有限mod10/mod5计数，不在每拍做任意除法。换block使用已经捕获的next值，不能同沿把next写current后再读新current。两个54bit pair holding分别预留目标slot，valid+reserved≤2；SRC disabled时按相同slot事件置RGB0，从required packed cache取码，不读未filled平面或旧值。满时不发新RE；既有RE下一沿必capture，异常不能让pending消失。

**DF-OP05 exactslot。** 生产hpair0…1099，HS高有效[0,22)，水平DE[96,1056)；v0…1124，VS高有效[0,5)，垂直DE[41,1121)。target_y=v−41、q=hpair−96，像素x_even=2q。无DDR ready；扫描计数每PAIR沿继续，HS/VS/DE随同一个物理slot走。所有行长1100组、帧长1125行。

条件逐沿例：q0最终物理adapter slot为hpair96；packed block0最迟h88发RE、h89 preedge capture；SRC q0在h90发RE，RAM输出h90后稳定，h91 preedge RDATA捕获并组合旧packed缓存至预留54bit槽；h92消费旧54槽形成六个权重项并保留原RGB/edge/ANN旁带，h93部分和、h94 Y，h95锁定render RGB48及同slot同步信号，h96 adapter实际接受旧render值。不能在h91使用该沿新capture寄存器替代旧RAM RDATA，也不能在后级读取该沿才形成的新stage值。源三stripe均同一pending页；disabled SRC以相同预留事件生成该54槽。

一般最终物理slot n：packed新block最迟n−8 RE/n−7 capture；SRC n−6 RE/n−5 capture成54槽；n−4权重项/原RGB旁带，n−3部分和，n−2 Y，n−1 render RGB稳定，n adapter实际接受。权重每项unsigned16，部分R/G和及保留B项各unsigned16，Y由扩宽和+128后右移8形成unsigned8；RGB直通/EDGE/overlay/ANN也走相同固定slot延迟，不因绕过gray改变同步位置。边界需要的next cache在54槽capture之前已经有效。第一次行输出前已取得ROW并保存OWNED资格；所有READ及缓存均属完整行。持续每PAIR沿可消费一个旧54槽并为未来SRC RE预留具体空槽，valid+reserved≤2；后面的四级render寄存器另列，不占54槽或RAM借用。上表只在本地clock/RAM/related流水合同满足时成立，encoder额外延迟/相位仍B，不是实际STA证据。

q/target/token/scope/gen必须与物理期望slot精确匹配。迟到旧行/旧scan项DISCARD归还，不能平移到下一像素；未来target项保存到它的真实slot，当前缺项取安全像素。ROW在行开始前没有OWNED/完整required或任一cache/槽不匹配，即锁frame_sticky；该slot及本帧剩余active像素输出安全RGB黑，HS/VS/DE继续。故障前已经发送的前缀不可撤销，此帧记录PARTIAL/UNDERFLOW而不冒充完整安全帧或成功显示；中途迟到ROW不恢复正常画面。

下帧恢复仅在同一active SourceOrigin/固定mode的真实新scan token、row0及必要预取已经就绪，且平台及原scope/grant/策略资格仍合法时于VSYNC清sticky；已取消/隔离/授权失效对象不凭row0恢复。不能用旧token/当前CSR/收到一个迟到pair清故障。正常候选bundle切换也只能VSYNC原子发生，不能在故障帧中段换source/模式。scope phase0持续；每刷新新scan token不重新open旧phase。

148.5域以两个相关slow边沿顺次取lane0、lane1，RGB和HS/VS/DE一起移交；742.5双沿每slow pixel提供10个bit时隙。编码器/serializer固有延迟、相位、通道及控制位需实际IP验证；不能沿用旧vid_cnt或把74.25称输出单pixel频率。行bank值复制后的像素FF保留scope/token直至真实使用；未知相关域停钟通过平台隔离，不伪造最后lane已消费。

## 6. DF-OP06/07/08：换页、计划过期、冻结与退役

**DF-OP06 计划/实际选择/关闭/应用。** PIX在每VSYNC为下一刷新预告future SCAN_PLAN，offer/control路由改变分配新plan_generation；它只提供未来active/candidate两route，不替换current_exec。本次有实际image scan时，新future PLAN的业务交付须本次SELECTED已经被CORE消费并完成业务ACK；safe-only且没有既有预取义务时，不等待不存在的SELECTED。此前可本地coalesce未来计划，但已held PLAN body不改、不覆盖。它不挡当前h/v，也不挡上一PLAN已经授权的row0预取，避免新PLAN先到误取消尚在SELECT邮箱的当前scan。有预取义务的safe决定另按下段use_data0通知/ACK门槛推进。candidate完整row0 READY+OWNED、应用和真实scan通知容量已预留、控制屏障允许，才在目标VSYNC把完整bundle设active。该沿可见新READY/新offer按旧资格不抢先；APPLIED携父要求的新旧身份/应用及scan序号，不由transport ACK代替。迟到PLAN/ACK按实际route资格repeat或safe并报状态，不能推算token冒充授权。

DISPLAY_ID687=full DISPLAY scope623/offer64。实际VSYNC独立冻结SCAN_SELECTED1013=DISPLAY_ID687/scan64/plan_gen64/has_active1/use_data1/safe_reason4/policy64/epoch32/link32/rendergen64，业务ACK1019=原body+status2/error4。每次选择明确实际candidate、repeat旧active、freeze沿前active或safe；future预取可以早于SELECT，但CORE后续current执行必须按已接受SELECT对应完整身份/scan/plan/render，不把future route猜成真实active。无active的对象字段规范0且不可解引用；有active但use_data0表示本地safe，不新建image读/scan引用。

若实际选择safe时，该future token已经存在FILL、READY或OWNED预取义务，**必须交付use_data0的SCAN_SELECTED业务通知**作为明确未选证据，不能因不建image上下文而省略。CORE消费该证据后取消该token未exposed FILL的后续prepare，既有permit/held req/R/terminal/release按OP02结清；PIX逐bank对exposed ROW作DISCARDED/release，不能等待不存在的CLOSED。该use_data0通知不pin current_exec、不生成CLOSED；has_active及DISPLAY_ID仍报告本次真实active，无active则规范0，不能把预取candidate冒充实际active。scan/plan定位已保存future_plan的active/candidate两个route，use_data0证明它们本次均未作为image执行，据此识别各自完整预取义务。SELECT槽暂满时，把一次真实safe决定及对应token/route保存在本来的future_plan元数据内，暂停为后续token创建新future预取；物理safe继续，不创建第四scope或逐safe帧队列、不覆盖held SELECT。槽空后交付原决定，业务ACK结清后才交付新future PLAN。safe期间没有预取义务的新物理token仅本地coalesce诊断，不为它等待SELECT或CLOSED。

已SELECT且use_data1的image scan最后数据及pixel/adapter/row局部引用结清后，独立冻结SCAN_CLOSED921=DISPLAY_ID687/scan64/plan_gen64/rendergen64/data_pairs21/frame_ok1/partial1/underflow1/pixel_refs_closed1/adapter_refs_closed1/error16，业务ACK927=原body+status2/error4。它只等该scan局部关闭，不等scope fence/未来scan/整个bundle退役；数据FF副本仍pin本scan/scope直至真实消费。正常末DE后front blank尽早推进CLOSED/ACK，实际最坏通知期限仍B。CORE必须先登记同一SELECT再成功处理CLOSED；CLOSED先到立即回BUSY、不做闭合，保留同body后重试，不能占掉或阻止独立SELECT槽。safe-only不建图exec或CLOSED，不为没有image上下文的物理帧伪造data_pairs/关闭证据；安全诊断可本地coalesce，旧held通知不可覆盖。

SELECTED/CLOSED各自独立有限私有槽与业务ACK槽。新的image scan必须前一image CLOSED业务ACK已经结清、两个通知槽及该scan关闭资格预算可用；否则整物理帧safe、use_data0，不创建新image上下文/借用、不覆盖旧通知，物理h/v/token继续。safe仍须按前段结清已存在的future预取义务；通知槽不足不能抹该义务。保持1个current_exec、1个future_plan双route、至多1个closing held元数据；全部引用原三个bundle ctx，不新增scope或第四结果。新future代次不宣布当前行过期；只有真实选中/关闭、明确路由取消或未来计划到期才判具体owner关闭。

已经exposed READY或OWNED的具体token真正过期，ROW body绝不改成新token再用；PIX按真实VSYNC选择/未选证据发DISCARDED RELEASE/ACK。未被SELECT的future token没有image上下文，它的过期/取消ROW直接discard回收，不能等待不存在的CLOSED。未exposed FILL只有明确未SELECT/取消证据后才作废，不单看最新future代次就撤当前事务或丢旧R。尚在CORE、未提出READY/未借用的完成payload，仅在同scope/offer/source映射仍合法时，按父新future计划建立新descriptor/gen；不能改held数据或当前PIX owner。active每刷新也重新按新token读row0。三个bank可能为旧末行、旧下次row0、candidate row0；应用后旧预备行明确discard，candidate变新current，释放出的bank供新next。candidate不占active next的读调度资格，已提出candidate段的延迟计入期限。

**DF-OP07 冻结原源。** freeze请求在PIX可见后VSYNC优先于候选应用，选择沿前真实active SourceOrigin195，建立snapshot-hold并回父；不得用core APPLIED影子。保护的是不可变原RGB源及其代次，不是overlay/gray/ANN的render surface。父先建立FREEZE再COMMIT，PIX之后解除移交hold。active处于故障安全输出时也明确报告display_fault/sticky；不宣称安全图案是可重处理RGB。无active走FM NO_ACTIVE屏障/等待首完整源规则，不虚构图案源。已提出candidate的取消/预取归还继续闭合，恢复命令不能抹未ACK冻结事务。

**DF-OP08 退役/失败。** 换入后旧active进RETIRING，不再产生旧scope新读；停止旧循环取数，已proposed req兑现、已R与本地展开/carry/RAM pending关闭，各old row本地归还继续。最终producer封口保存真实req水位，才seal/fence/只读grant及父binding归还；不每刷新close/reopen，不让bank local RELEASE等scope fence。RETIRE_DRAINED须所有旧service record/terminal/release ACK、descriptor carry、row拥有权/消息、像素/编码scope引用及父所需fence关闭；snapshot-hold仍在时不能返其引用。APPLIED先于对应退役事件，事件槽各自独立，慢旧DDR可保留两RETIRING元数据但不能隐含第四个槽。

取消/早错不等不存在的EOF/完整1080行；未提出后续读可作废，真实段排空/终态与local return先做。ROW借用只在合法释放或平台PREPARE实际安全处置后归还；旧Q通知drained0不改写。平台时钟/物理效果未知继续Q，功能rst不清req/R/pending/row owner/事件/会话。恢复默认旧图失效按FM重新授予，新epoch不能证明旧物理已消失。

## 7. 有限预算与期限推导（非实测）

| 已选择资源 | 数量/解释 |
|---|---|
| SRC row | 3row×6 native20×512=18RAM，高12零，每row960/1024项有效 |
| EDGE row | 3×96个20bit字=288/512，用1RAM |
| ANN row | 3×192个20bit字=576/1024，用2RAM |
| DISPLAY小计 | 21RAM；旧PL PIX168 FIFO9被替代，没有同时保留 |
| 已列整机 | 162−9+21=174/256=67.96875%；camera CDC20及AON mirror已在旧数中，不重计 |
| 比较替代 | 4row需要SRC24+EDGE1+ANN2=27RAM，总180；每结果槽两row共6个54bit合并bank为36RAM，另须packed scratch/FF预算。均未选择，不计入174 |

已列取数数据FF：CORE R两个128槽256、SRC append192/两个RGB holding96、EDGE/ANN各160暂存候选320；PIX两个54槽108、EDGE/ANN current+next共80，合1052bit。SRC真实有效≤21B不因192容器扩大。新增render数据另列：权重六个U16共96、部分R/G和与保留B两lane共64、Y两lane共16，三个算术级各带原RGB/edge/ANN54共162，最终render RGB48，共386bit候选数据FF；adapter/slow/encoder缓存及全部stage身份/同步另计。故不能将1052或1052+386当完整FF。row descriptor、三个plane自有carry（SRC≤40bit、EDGE/ANN各≤19bit）、pending与控制/ctx、两域邮箱、APPLIED/FAULT/snapshot、current/future/closing及SELECT/CLOSED、相关域RGB流水另计。灰度乘常数可用移位加法，未声称实际DSP/时序；旧TMDS受保护IP计数待证。

固定时间：1100/74.25MHz=2200/148.5MHz=14.8148148µs/line；960pair active=12.9292929µs，140pair blank=1.8855219µs；1125行=16.6666667ms。VSYNC5+VBP36=41line，从VSYNC开头到首active行约607.407407µs。不能把双pixel重复乘二得到29.63µs/line或1.215ms。

最坏满mask6480B/row=405 R拍，6,998,400B/frame；60Hz=419,904,000B/s逻辑图载荷，不含DDR协议/竞争。单口串行展开最低SRC960+EDGE96+ANN192=1248core沿=12.48µs，行周期仅余约2.334815µs用于无法完全重叠的请求/响应/terminal/release/CDC，故尚不能保证行next准备期限。SPLIT每半帧只读SRC或EDGE，实际载荷3,240,000B/frame，但完整功能仍要证明recognition/overlay最坏模式。

可检查期限式：Trow=Σ各段(prepare/req等待+物理读等待/突发+逻辑返回/展开+terminal/release/ACK)+owner CDC/局部pipeline，按实际允许的重叠取路径最大值；候选在active urgent前已经提出的一段额外阻塞必须加入。稳态next在target行h88所需packed预取前OWNED，首行在目标VSYNC及row0提前RE前满足；ROW本地归还+重新分配、SELECT/CLOSED业务ACK容量及末DE后关闭期限也计入。DDR14叶请求最多13个其他eligible req_fire机会；物理R七client最多6个其他eligible burst启动机会，不等于时间上界。R池共享返回与每client两个槽、真实PHY最坏响应、QoS与其他客户端读竞争均未冻结；RR不是实时带宽证明。

## 8. 文字场景、追踪与阻塞

| TEST（全部NOT_RUN） | 期望/对应 |
|---|---|
| DF-T01 完整1080p60/全行帧计数 | 1100组×1125行；HS/VS/DE范围；有效2073600pixel，无反压计数 |
| DF-T02 RGB命名字节/纯R/G/B/gray极值 | DDR重排到canonical、65535内加法、gray与FE一致；无旧R/B交换 |
| DF-T03 SRC16B形成2/3pair，1024B段末carry4B | pair仅一次WE，独立carry使旧record可release；无单record自锁 |
| DF-T04 EDGE/ANN 20bit跨128拍及SRC页511/512/ANN g511/512 | 低地址低bit、保存pending旧page/owner，无偷读新capture |
| DF-T05 0xFF0、完整行各plane跨4KiB | 16align/1…64/no4K，各tag terminal/release ACK逐段，不越A |
| DF-T06 active current/next+candidate首行均占 | 3bank不覆写，next优先；candidate只在段边界让出，旧proposed仍结账 |
| DF-T07 READY/OWNED/RELEASE/ACK反压/重复/错gen/单端rst | 私有容量不覆盖；transport ACK不替业务；合法完整归还后下一沿复用 |
| DF-T08 q0/block5/10/cache同时边界与两个slot | packed88/89、SRC90/91、terms92/partial93/Y94/render95/adapter96；reserved≤2、四级render旁带/同步与最终slot一致 |
| DF-T09 row迟到/超前/缺plane、frame中段DDR错误 | exactslot不横移；sticky安全后缀，迟到不恢复，下一token+同源row0才复位 |
| DF-T10 新future PLAN与current后续行、SELECT/CLOSED乱序/ACK反压、safe含预取义务、未SELECT过期token | current授权独立pin，有image的新PLAN交付先等本次SELECT ACK而旧PLAN预取不停；CLOSED先到BUSY且不挡SELECT；前CLOSED ACK/两槽预算未结整帧safe且不造CLOSED；已有future FILL/READY须use_data0通知提供未选证据，槽满保留原future决定且停止后续token预取，通知ACK后才新PLAN；无预取义务safe不等不存在SELECT；未选择行真实证据discard，不改held token |
| DF-T11 split 539→540及source1078→0 | target/source独立，gray/edge同范围偶行，旧cache不按新mode解释 |
| DF-T12 freeze与应用同VSYNC、core影子落后/NO_ACTIVE | 真实沿前active原SRC，hold移交先加FREEZE；图案非输入源 |
| DF-T13 两RETIRING+新active、scope fence长期等 | row先本地归还，scope引用最后排空，不借第四槽/不锁新next |
| DF-T14 cancel candidate半行、terminal与pending capture同沿 | 未提出后段作废；kind1/2共同作废held，capture DISCARD；Q不回收 |
| DF-T15 related74.25/148.5/742.5相位/失钟/PN | lane0/lane1、RGB/控制、10bit双沿及单次PN补偿；实际IP待验证 |

追踪：DF-IF01/02→OP01/06→T06/10/11；IF03→OP01/02→T03/05/14；IF04/05→OP03→T04/07/13；IF06→OP04/05→T01/02/08/09/15；IF07→OP06/07/08→T10/12/13；IF08→全部保持/恢复→T07/14/15。计划实现/测试符号由以后获批父稿指定，当前均未生成。

- DF-B01：父完整bundle/control/APPLIED/retire/freeze事件、ROW ACK编码、三RO grant/ANN header格式及新SCAN_PLAN/SELECTED/CLOSED/ROW通道须在FM/DDR/RC/PL统一吸收；旧PIX168不能直连。本页字段是同轮候选，不是父接口已相容。
- DF-B02：三类native20 dual-clock映射、mailbox保持、各域释放/同步、local row借用与related像素引用证据及Gray/时序约束需实际工具/组合验证。
- DF-B03：单client1每段终态/release节奏、所有负载/候选阻塞及行/首帧/退休最坏期限缺失；174只是容器小计、419.904MB/s只是载荷。
- DF-B04：真实PLL相位、编码/serializer延迟/位序/差分补偿、相关74.25/148.5/742.5 STA/IP软件验证尚未运行；安全输出在失钟时的物理行为归平台。
- DF-B05：frame_sticky安全前缀/后缀状态、冻结故障active的状态body、current_exec/future_plan/closing及SELECT/CLOSED独立预算/ACK顺序、完整FF/邮箱/ctx容量与所有平台恢复字段需父组合读审；不将1052bit取数/386bit render候选数据视为最终FF。

本页达到保存/可读回，不达到READY_FOR_REVIEW。恢复先读现行父/DDR/FM/PL/RC及批准记录；借用、分段、模式、token、颜色、延迟、资源改变均先修设计。所有测试与吞吐/STA/实机/理解验收分别保持未执行或待检验。
