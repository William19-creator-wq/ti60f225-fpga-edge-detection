# TRACK4-DISPLAY-001：同源显示、行预取、固定扫描与冻结交接设计 v0.1

2026-10-04；LOCAL_DESIGN / NOT_APPROVED。按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)创建。本稿是完整五项基础、六项高阶工程的显示局部候选，不是已实现的软件或已验证HDMI。

## 通用计划字段

- Goal：完整1920×1080@60Hz多模式显示；原RGB、灰度、最终EDGE与识别ANN来自同一完整bundle，安全换页、真实active源冻结与旧借用关闭。
- Current state：主计划v0.11及CAMERA v0.1已保存；显示参考来源只读核对；本稿新增候选端口和中文草图，业务源码/参考/TB未生成。
- Target state：显示读取、row bank、pixel pipeline及serializer身份/数量/时间相容；真实仿真、综合/PNR/STA和bit/hex证明，不能由文档替代。
- Gap：受保护编码器/serializer、真实2Gb PHY、相关时钟采样关系、DDR服务期限、相邻父端口和完整资源尚未闭合。
- Assumptions：Ti60F225 V4/I3；完整RGB888源；core100MHz、pair74.25MHz、pixel148.5MHz、fast742.5MHz为平台候选；生产W1920/H1080。
- Open questions：DP-B01…08；不恢复已撤回的识别尺寸/噪声硬限制。
- Dependencies：唯一根v0.2、模板、MASTER v0.11、FM/DDR/PL/RC v0.1、FRONTEND v1、CAMERA v0.1和原V4 v6。
- Milestones：来源/整体→接口组合→局部中文草图→统一父端口/真实依赖→无阻塞并保存呈现→指定批准→实现/软件验证→整机bit/hex后停止。
- Detailed steps：B/C整体→D交接与反例→E及[局部附件](../experiments/track4_full_sw_20261004/04_local-designs/display-fetch-and-scan-sketches-v0.1.md)→F/G/H/I。
- State transitions：仅本稿LOCAL_DESIGN；不修改正式H/A/R、PROJECT_STATE、数据库或Approval Manifest。
- Artifacts and hashes：A列既有基线；最终本文及附件SHA由文档审查记录绑定，无自包含哈希。
- Validation：DP-T01…24是文字场景，全部NOT_RUN；来源分析/算术/文档检查与功能验证分开。
- Failure handling：不可暂停的扫描采用独立本地安全RGB；旧scope/段/pending/row/held消息保留并身份匹配关闭；排空未知QUARANTINED。
- Human approval gates：有正确性阻塞不标READY；没有本稿指定版本/范围/基线批准，禁止业务实现/测试。既有FE和模型获取申请不由本稿冒充批准。
- Rollback：只新增控制面文档；原HDK、资料、工具、归档只读。后续RTL/约束只在获批work副本。
- Completion criteria：本稿落盘不等于11功能完成；最终必须有实际代码、完整测试、真实PHY/HDMI/约束、综合/布局/STA及bit/hex。

## A. 状态、来源与阅读入口

本范围是MOD-11及MOD-04/05/10/01的显示边界，关联T4-B4/A3/A5/A6、DER-01/03/05/07/09。不改变算法数值、识别质量或采集要求。先读[主计划](design-TRACK4-FULL-SW-001.md)、[整体布局](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)、[系统交接](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)，再读本稿B/C/D/E、附件、F/G/H/I。

新增[VF/Demo补充证据](../experiments/track4_full_sw_20261004/01_baseline/vf-demo-supplemental-evidence-v1.md)实际找到DDR/PHY与公开TMDS编码器：可读编码是后续adapter候选，板C4、复用条件、复位与专用serializer仍待核查，未选择或复制。[实际显示来源](../experiments/track4_full_sw_20261004/01_baseline/display-hdmi-and-fetch-evidence-v1.md)区分原参数/接线、受保护主体未知和新提议。实际原包是RAW8→DDR→Debayer，不是RGB888源读回；末AR bank_sw、空读旧值、未接出的非sticky欠载都不能复用为新完成证明。原加密encoder只读公开声明，不解密。

| 既有输入 | 版本与SHA256 |
|---|---|
| 根规范 | v0.2 / 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| 原v6 RAR | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C |
| FM | v0.1 / D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| DDR-SERVICE | v0.1 / 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| PLATFORM | v0.1 / 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 |
| RECOGNITION | v0.1 / D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5 |
| CAMERA | v0.1 / F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C |
| FRONTEND | v1 / 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 |
| 板pin来源 | v2 / 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F |

这些父稿保持不变。本稿新增row bank/scan plan/render/控制合同，必须由下一统一FM/DDR/PL版本吸收；同名端口不是已相容。用户授权按规则继续完整目标，没有批准此新版本业务实现。正式DB尚未配置；文档推进不冒充正式运行恢复。

## B. 整体外部行为

| REQ | 可检查行为与来源 |
|---|---|
| DP-REQ01 | 视频clock合法时独立固定1080p60扫描；HS/VS/DE与像素数量正确，不等相机/算法/DDR。T4-B4/PL07。 |
| DP-REQ02 | 完整bundle提供同源SRC/EDGE/ANN与冻结render快照；只有合法COMPLETE图、RO grant及首行准备齐备才能VSYNC原子应用。B4/A5/A6。 |
| DP-REQ03 | RGB888低地址R/G/B与双lane保持；原灰度比较、原彩色、边缘、彩色叠加和识别标注有明确逐像素规则。B2/B4/A5/A6。 |
| DP-REQ04 | 三个有限row bank分别支持active current/next及candidate首行；独立身份、scan token、同步RE/holding、CDC与归还，不借隐藏第四结果。DER-03/05。 |
| DP-REQ05 | 查询显示域真实active的原始SRC，snapshot-hold→FM FREEZE→COMMIT；与offer/控制同沿有确定规则。UC-05/A3。 |
| DP-REQ06 | 欠载/错身份/DDR失败输出明确safe，迟到旧scan不进入新scan；帧质量、repeat、欠载及物理clock故障分开报告。DER-06/07。 |
| DP-REQ07 | 退休/取消只关闭新增读取，旧permit/req/R/terminal/release/carry/row/pipeline兑现；局部、fence、父返还与镜像关闭分开。DER-03/07。 |
| DP-REQ08 | 相关视频clock、编码/serializer/PN补偿、资源与QoS分别有来源/预算/真实验证；全路径可双向追踪。B5/R0。 |

冻结对象是当前显示bundle绑定的原始SRC，由真实SourceOrigin195选择。GRAY、上下比较、overlay及ANN是视图，不能合成为新的算法SRC；本稿不声称保存最终屏幕surface或已经输出的safe像素。若要另存surface需独立需求/设计/批准，不把它混入UC-05。

正常样例：同源完整bundleB先保存，candidate row0完整且已经安全移交；下一VSYNC没有freeze/fault，APPLIED槽可用，整体换B；旧A停止新读，独立R/row/pixel排空后返还，不能只见换页就FREE。边界：core影子仍A而video已经B，freeze选择B。失败：某行下一bank未在真实消费期限前准备，本行第一个缺项起余下扫描走safe，时序不暂停；之前已显示像素不能追溯改变。健康无闪烁/无撕裂验收仍要求证明正常负载不会欠载，safe不是B4通过证据。

生产每帧2,073,600有效pixel、1,036,800有效pair，总1,237,500个pair扫描周期。显示刷新60Hz与相机/处理fps独立，慢结果可重复相同scope但每次扫描使用新scan token。

## C. 职责与整体连接

| 逻辑单元 | REQ、状态与接口职责；划界理由 |
|---|---|
| DP0 BUNDLE-LIFECYCLE/core | REQ02/05/07；三结果范围内candidate/active-shadow/RETIRING、完整scope/grant/offer/render；FM仍是对象拥有者。 |
| DP1 FETCH/core | REQ03/04/07；client1唯一R record、段头/tag/seq、逐plane byte/bit carry、同步WE/pending；不假造DDR完成。 |
| DP2 ROW-TRANSPORT/core↔pair | REQ04；三个bank目录、不可变payload、ROW336/OWNED/release和link_session；不用逐位同步多位数据。 |
| DP3 SCAN/pair | REQ01/02/05/06；真实active、scan/plan seq、固定计数、row reader/holding、freeze hold、业务事件；永不反压物理时序。 |
| DP4 RENDER/pair | REQ03/06；固定灰度/模式/颜色/ANN优先、sideband与RGB共同流水；不用当前全局参数改在途pair。 |
| DP5 VIDEO-ADAPTER/pixel/fast | REQ01/08；相关clock pair→两个pixel→编码10bit→专用serializer；只依已证明IP合同，未证明部分B。 |
| DP6 CLOSE/JOIN/core | REQ07/08；独立局部关闭、service fence、status与返还、平台PREPARE/FINAL保持；不代FM清BIND。 |

普通文本路径：FM完整OFFER1963→DP0→DP1 client1 RO SRC/EDGE/ANN→DP2三row bank→ROW336原子移交→DP3固定scan→DP4同源render→DP5双pixel/编码/serializer→HDMI；DP3真实APPLIED/快照/row归还→DP0/FM；DP1 R终态、DP2双方借用、DP3/5旧pipeline证据→DP6→status→父binding_return→父scope/mirror CLOSE。SCAN_PLAN独立从video→core，不等数据FIFO。故障/恢复独立，不被满row或held业务事件阻塞。

3bank替代PLATFORM v0.1 DISPLAY-PIXEL168/FIFO512，不叠加旧9RAM。银行保存源像素及mask，身份在不可变row descriptor与已pin完整bundle上下文；每次ROW含scan64，解决同scope重复扫描的迟到混入。整体选择先呈现于本稿B/C/D，局部详见E/附件；真实可实现性仍DP-B01…08。

## D. 接口、模式与组合检查

### D1. 身份、数值与八项交接

全部整数unsigned；消息本域上升沿前valid与ready同为1才fire，提出后完整payload保持。RGB canonical为{R1,G1,B1,R0,G0,B0}，DDR地址顺序R0/G0/B0/R1/G1/B1。scope623/grant241、J486/SourceOrigin195、req266、terminal301、release288/ACK293直接继承DDR；不截为槽号猜租约。DISPLAY scope.kind2、client1只R、phase0。ANN region5的新RO授权须下一DDR版本吸收，不能读取TEMP页gap或ANN allocation尾。

render112=mode3/split_y11/edgeRGB24/ANN01RGB24/ANN10RGB24/ANN11RGB24/show_edge1/show_ann1。mode0上下比较、1原RGB、2原灰度、3EDGE、4彩色EDGE叠加、5识别叠加；6只属于本地诊断，不接受DDR OFFER，7非法。生产split_y540，其他模式仍校验该字段540使body有唯一规范形。颜色默认edge红FF0000、ANN01绿00FF00、ANN10蓝00A0FF、ANN11黄FFFF00，颜色可随完整render快照指定。show只控制绘制，不减少mode4/5实际验证/预取平面集合。

| IF | 方向、完整字段与前提 | 保证、保持与失败 |
|---|---|---|
| DP-IF01 OFFER | FM→DP0/core→DP3/pair，OFFER1963=scope623/offer_seq64/source_cfggen64/render_generation64/W11/H11/global_plane_mask3/三个desc96/三个full grant241/render112；receipt1969=原body+status2/error4 | 当前结果BIND、COMPLETE图及合法源/结果generation先验证；保存不是APPLIED。SRC身份/desc/grant始终存在；EDGE/ANN只在相应模式要求时存在，其余desc/grant规范0。global mask表示扫描所需平面，mode3 mask010仍保留SRC冻结绑定，不用gen0推空。预留candidate、所有终态/关闭通知容量才ACCEPTED。 |
| DP-IF02 MEMORY | DP1↔DS client1/phase0，prepare198/permit68/req266/R155/terminal301/release288/ACK293；scope/grant控制与seal/fence继承DS | 16B对齐、1…64拍、不跨4KiB、只在对应完整图L/A范围；R在实际fire取低地址byte lane。terminal/release独立，不能等下一段或整个row完成才归还本段。 |
| DP-IF03 SCAN/APPLY | DP3→DP0 SCAN_PLAN522、SCAN_SELECTED1013/ACK1019、SCAN_CLOSED921/ACK927，字段与独立容量见D3；APPLIED1503=new DISPLAY_ID687/old DISPLAY_ID687/old_valid1/scan64/render_generation64，业务ACK1509=原body+status2/error4 | DISPLAY_ID687=full_scope623/offer64；完整old/new身份，新current来自原candidate。只有实际VSYNC换入才APPLIED；业务消费ACK先于旧对应退役通知，运输ACK不代业务ACK。 |
| DP-IF04 ROW | core→pair ROW336=bank_id2/bank_gen64/scopeH68/offer64/scan64/target_y11/source_y11/required_mask3/pair_count11/mode3/link_session32/filled_mask3；OWNED_ACK342=原body+status2/error4；pair→core RELEASE343=原body/kind2/drained1/reason4，ACK349=原release+status2/error4 | 三bank各有独立depth1 ready/owned/release/ack邮箱；完整required已写且所有本段terminal/release与WE/pending结清才READY。kind0CONSUMED/1DISCARDED/2Q/3非法；Q不回收。数据从READY提出到合法release ACK运输保存确认及旧pending/holding关闭始终不变。 |
| DP-IF05 CONTROL | core↔pair，公共header227=control_seq64/op3/expected_policy64/new_policy64/epoch32；SNAP/STOP为227，FREEZE_COMMIT422加SourceOrigin195，CANCEL_OFFER914加DISPLAY_ID687；其余类型见D4；各业务ACK回原body+status2/error4 | 一次一个未结有序控制；独立于APPLIED、ROW及fault。去重键为(op,control_seq)，同键同body幂等、同键异body拒绝；SNAP与其COMMIT可使用同事务seq但不同op，续阶段还核保存的SNAP/Origin/policy，不能仅凭新op接纳任意旧事务。错身份不改变他人对象；BUSY没有应用可原body重试，已提出valid不能撤回。 |
| DP-IF06 CLOSE | DP6→FM OWNERSHIP_TERMINAL840=DISPLAY_ID687/kind2/close_success1/drained1/error16/request_closed1/fence_closed1/local_closed1/rows_closed1/serializer_closed1/cutoff64/last_scan64；独立binding_return687与ACK693 | kind0RETIRE/1CANCEL/2FAILED_DRAINED/3Q；close_success只是关闭协议成功，不代表画面质量。status消费后独立binding_return，不等父CLOSE/FREE；父核账再关grant/scope/mirror。Q快照drained0不被后续恢复改写。 |
| DP-IF07 VIDEO | pair→pixel相关域：RGB48/HS1/VS1/DE1、固定lane/slot身份；pixel→encoder RGB24/HS/VS/DE、10bit四路码字→fast专用serializer | 不可反压，每pair恰两个有序pixel；所有sideband同一固定延迟。具体相关clock采样边界、保护编码延迟/位序及serializer初始沿尚DP-B01/02，不能由2:1频率比自证。 |
| DP-IF08 PLATFORM/OBS | health147/fault136/PREPARE808/FINAL808及done814沿PL；display回域隔离/旧scope、本地borrow/会话/真实pipeline关闭证明；分类饱和计数有overflow | videoclock正常即固定扫描safe；失钟不承诺不中断。admit只禁止新授权，不撤旧req/R/held消息；scope与通知保留至匹配恢复/返还。 |

status2候选0ACCEPTED/APPLIED、1ALREADY、2BUSY、3NO_MATCH；每种消息按其类型说明，不把receipt0当已应用。error4：0NONE、1FIELD、2IDENTITY、3PROOF_PENDING、4SEQ_BODY、5EXHAUSTED、6UNDERFLOW、7MEMORY、8CLOCK、9PROTOCOL，10…15非法。OWNED_ACK status0只证明视频端保存并取得该不可变row读权，不证明已显示；RELEASE_ACK status0证明core接受相应关闭，FREE仍至少下一沿才可分配。bank_id3、非法pair_count、wrong target/source/mode/scan不读RAM并明确DISCARDED；排空不明Q。

### D2. 图与逐像素规则

SRC主实例L=A6,220,800B；EDGE连续1bit/pixel，L=A259,200B；ANN采用RC的header128/list4096/map从+4224，完整L=A522,624B，map518,400B。不存在ANN不读假header、不造成功段；识别空列表仍有合法全零map。任何descriptor的A/base按父静态映射及授权核验，不能用allocation页余量补访问。

模式0是上下比较：显示y<540取原灰度，y≥540取白色EDGE/黑背景；source_y=2×(display_y mod540)，source_x=display_x。两半显示同一完整源范围的偶行采样，不更改1080p输入/算法输出；此视图的垂直缩放为2:1且不插值。它是本稿明确的布局提议，不能将其叫作算法只处理半图。其他模式源坐标与显示坐标1:1。GRAY来自原SRC，Y=floor((77R+150G+29B+128)/256)，与FE-02完全相同；不把median后的M冒充原灰度。

RGB显示原值；EDGE取255/0三通道；overlay在show_edge且EDGE1时替换为edgeRGB，否则原RGB。recognition先按overlay形成背景，再在show_ann且code非0时以ANN01/10/11色替换；00不覆盖，11表示RC的文字或异类冲突。ANN优先于edge，不做未声明alpha/gamma；位码lane0低位、lane1高位。原参考gamma/RB连线不是本稿映射证明，生产候选关闭gamma，保护encoder映射仍B。

global_plane_mask三位bit0SRC/1EDGE/2ANN：mode0为011、1/2为001、3为010、4为011、5为111。ROW mode0按上下分别required001/010；其他与global相同；filled_mask覆盖required，非required图不读、不解未初始化bank位。原RGB源在OFFER中始终有合法源身份/desc/grant；EDGE模式扫描不发SRC请求仍需SRC作为同源冻结对象，因此OFFER mask指扫描资格，另保留已核源metadata，不能将mask无SRC误解成没有源绑定。不存在的EDGE/ANN按mask及模式规范0；SRC永远存在，global mask bit0不等于它的存在位。

### D3. scan计划、固定时序与row所有权

视频域独占scan_frame_token64，每个真实VSYNC用新token，序号1…max，不回绕；计划生成者也在视频域。SCAN_PLAN522=plan_generation64/target_scan_token64/current_scopeH68/current_offer64/candidate_scopeH68/candidate_offer64/current_valid1/candidate_valid1/policy64/epoch32/link32。每VSYNC预告下一scan；新offer/控制改变未来路由时分配新plan_generation，已held旧PLAN保持，不能同seq换body。旧/新route不代表必应用，最终决定仍在VSYNC。PLAN独立有限mailbox满时不暂停扫描，后续计划按真实业务容量发送，迟到导致本帧repeat/safe及诊断。

core分别保存已经真实选择的current_exec授权与有限future_plan。current_exec按完整DISPLAY_ID/scan/render_generation固定，本scan后续行不因下一PLAN代次更新失去授权；future_plan只保存一个目标scan的current/candidate两条可选路由，提前填row0不等待该未来scan的SELECTED。candidate row0必须带确切未来token。已经提出READY/OWNED的body不能改token或在下一帧冒充ready。未被真实VSYNC选择的已曝光row由video逐bank发DISCARDED，不等待不存在的CLOSED；未曝光FILL也只在明确取消/未选择证据下取消，不能仅见最新future就撤当前承诺。尚未expose、无借用且读段/pending已关闭的完整payload，若仍同scope/offer/source_y且新授权成立，可重授bank_gen建立新descriptor；不得修改held body。scope相同但scan不同仍是不同身份，任何旧pending按原owner capture或DISCARD。

SCAN_SELECTED1013=DISPLAY_ID687/scan64/plan_generation64/has_active1/use_data1/safe_reason4/policy64/epoch32/link32/render_generation64；ACK1019回完整body+status2/error4。实际VSYNC按沿前row0、策略与事件容量决定新candidate/重复/冻结/安全路线，image scan一次提出SELECTED，core保存匹配current_exec后业务ACK，并关闭该target token未选route的新预取；已曝光未选row仍独立DISCARDED。DISPLAY_ID报告真实active，无active规范0；scan/plan定位已保存future_plan的两个route，use_data0明确二者本次都未作为image执行，不能把预取candidate冒充实际active。SELECTED与APPLIED不同：重复扫描也有新token及SELECTED，APPLIED只报告换bundle。use_data0表示未建立image scan，core不pin图执行上下文，不等待CLOSED；无active时ID/render规范0。有该future token的预取义务时，use_data0是必须交付的明确未选业务决定，core据此停止该token各route的新读并合法取消未曝光FILL，video逐bank DISCARDED已曝光row。SELECTED槽暂满时将这一决定保存在既有future_plan中，停止为后续token创建新预取，物理safe继续；槽空交付且业务ACK后再推进新PLAN，不增加第四scope或逐安全帧队列。没有预取义务的安全物理帧不必逐帧建图通知，诊断可合并，已held通知不能覆盖。

SCAN_CLOSED921=DISPLAY_ID687/scan64/plan_generation64/render_generation64/data_pairs21/frame_ok1/partial1/underflow1/pixel_refs_closed1/adapter_refs_closed1/error16；ACK927回完整body+status2/error4。该scan最后一个真实数据slot和row本地借用、pixel/adapter旧引用关闭后独立提出；不等scope fence、下一scan首行或下次SELECTED。core先消费同scan SELECTED才接受CLOSED；先到CLOSED回BUSY并保持原body，不阻独立SELECTED槽。data_pairs只数实际合格交付，frame_ok另核全数与fault，CLOSED不是结果scope归还。

SELECTED和CLOSED各有独立depth1业务槽与ACK。实际新image scan前，前一个执行scan的CLOSED业务ACK必须结清、两槽及current_exec预算可用；否则整个物理帧safe，保持真实active绑定、禁止此次candidate换入，不建立额外image上下文。物理h/v仍推进。下一future PLAN的业务交付在本次已建立image scan时等待其SELECTED已被core消费；safe无image且无预取义务时不等不存在的SELECTED，有预取义务时先结清上述use_data0决定。防PLAN先到误取消尚在邮箱的当前scan；本地未来路由可合并但held body不改，已授权future row0预取不受影响。预算为1 current_exec＋1 future_plan（至多两route）＋至多1正在关闭held scan元数据，全引用原三bundle、不新增第四scope。末DE到下VSYNC的通知/ACK与相关流水最坏期限仍DP-B05/06，不能由平均带宽或空白时间自证。

生产pair计数h0…1099、v0…1124：HS高在h[0,22)，VS高在v[0,5)，DE高在h[96,1056)且v[41,1121)。有效x_even=2(h−96)、y=v−41；active当前行960pair。每行14.8148148µs、active12.9292929µs、水平blank1.8855219µs；VS5+back36至首active607.407407µs。静态参数不在运行中更改，测试小row W偶数4…1920/H偶数2…1080仅验证bank/图映射；不能将小测试时序当生产HDMI验收。

READY_EXPOSED→PIX_OWNED后core禁止写该bank；pixel读取依据匹配descriptor的mode/target/source/scan及不可变full bundle ctx。行结束不等于bank借用已排空；该bank的RE pending、SRC/EDGE/ANN cache及54bit预渲染holding关闭后才RELEASE。已经复制到render/pixel/encoder寄存器的值不再借bank RAM，可继续持有scope/scan引用，分别在SCAN_CLOSED与scope local_closed核账，不能使bank归还等待整条编码流水或scope fence。core所有旧WE/pending与R目的地也必须结清；收到合法release后回ACK，ACK运输保存确认后且双方旧holding关闭，提交FREE，下一沿可再分配。row归还不等整个scope fence，避免active next等退休fence、fence又等row的循环。

### D4. 控制、事件容量与关闭顺序

公共op3：0FREEZE_SNAPSHOT、1FREEZE_COMMIT、2FREEZE_ABORT、3RESUME_PREPARE、4RESUME_COMMIT、5CANCEL_OFFER、6STOP、7非法。ABORT公共227加snapshot_control_seq64=291；RESUME两种用公共227，引用expected/new policy及原epoch。COMMIT带源Origin195，用于HAS_ACTIVE或NO_ACTIVE的完整源移交；实际FREEZE必须由FM先建立后发送。

FREEZE_SNAPSHOT1353=公共227/has_active1/DISPLAY_ID687/SourceOrigin195/render112/render_generation64/actual_scan64/previous_frame_ok1/view_partial1/snapshot_hold1。has_active0时无对象字段规范0，不解引用；控制屏障仍保持。snapshot-hold是原结果BIND下的移交借用，不增加第四结果或源读者。previous_frame_ok反映已结束的真实扫描，view_partial与safe/欠载记录不得被解释成已保存完整surface。

APPLIED有独立一个业务held槽及ACK，不与freeze/ROW/fault共享。换页前预留该槽、旧scope退休status与binding_return资格；旧APPLIED业务ACK未消费时不能再换页，但可重复当前帧。同一对应APPLIED先被core实际业务消费，才允许其old RETIRE通知；三结果最多两个RETIRING，各有独立终态/返还持有槽。snapshot与控制done独立depth1；通知序号和关闭token在授OFFER前预留，耗尽禁新OFFER，旧收尾有预留，不靠故障时再申请序号。

最终关闭：停止新的row业务→所有应有旧permit/req真实交付或合法未提出返permit→独立request_generation_closed/cutoff。随后phase0 seal/CLOSE_GRANTS及fence请求与本段terminal/release ACK、本地row/scan/pipeline关闭并行推进；fence证书与各local关闭合取后形成OWNERSHIP_TERMINAL固定body→FM消费status→独立binding_return/ACK→父关grant及scope→mirror CLOSE/ACK→物理结果/BIND下一沿可复用。fence等待不得阻段release或局部关闭。status/local_closed不等父CLOSE/FREE。正常关闭证据与畫面质量分开，发生欠载并安全关闭不篡改其frame_underflow统计；Q的drained0不能走普通释放。

### D5. 组合走查与显式差异

正常：FM有效结果B先建立DISPLAY scope/镜像及RO grant→OFFER保存→video送未来PLAN→core逐段prefetch candidate首行→各terminal/release结清、READY→OWNED→VSYNC实际SELECTED及必要APPLIED→core pin current_exec→当前/next读取与补行，future PLAN独立→末line bank borrow归还→该scan pixel/adapter关闭后CLOSED/业务ACK→下一scan新token重读或应用候选。旧A不再发新row，旧提出请求兑现，fence/local合取后status/返还，镜像最后关闭。

反例：用两行同时装current/next/candidate会覆盖仍读取的行；若release要求scope先fence又fence等row释放则互等；若candidate段已proposed就抢给active会撤承诺；若READY过期只改scan字段则旧像素成为新scan；若以末AR或运输ACK判RETIRE则晚R/像素仍引用已FREE对象。上述均明确禁止。

| 相邻稿 | 下一统一版本必须吸收 |
|---|---|
| FM v0.1 | OFFER1963/render112、三scope上下文、真实APPLIED ACK、独立current_exec/future PLAN及SELECTED/CLOSED、typed控制/ABORT、ROWS与status→return次序；不能从old影子冻结 |
| DDR v0.1 | DISPLAY region5 ANN RO、SRC即使不扫描仍是源绑定、连续scan phase0、不逐帧close/reopen；174资源与显示最坏期限 |
| PLATFORM v0.1 | 明确以ROW336双clock银行替代旧168 FIFO/9RAM；scan/row/控制邮箱会话及暖保持、相关视频adapter证据 |
| RECOGNITION v0.1 | RC ANN offset/2bit规则与显示色/优先级/完整bundle吸收；无目标全零map正常 |
| 整体02/03 v0.1 | 比较映射、完整render快照、行所有权及旧R/scan迟到防混；原FE冻结输入保持不改 |

## E. 局部状态、不变量与中文操作草图

### E1. 有限数据与不变量

三个bank_id2=0…2；bank_gen64每次重授递增，无回绕。core bank状态FREE/FILL/READY_EXPOSED/PIX_OWNED/RETURN_PENDING/QUARANTINED；video保存匹配row目录和读借用，不各自凭状态猜FREE。最多三完整bundle ctx归已有三个结果，candidate≤1、active≤1、RETIRING≤2，总不同ctx≤3。目录/完整OFFER、control/PLAN/SELECTED/CLOSED事件槽、current_exec及关闭元数据、计数、RAM pending、carry/holding和关闭token另计FF。current_exec不被future更新替换，先前CLOSED ACK未结不创建下个image scan上下文。clock/rst功能域与旧承诺保持域明确分开，cold未知valid不自行当初始化已完成。

| INV | 可检查不变量 |
|---|---|
| DP-INV01 | 读访问有完整scope/grant及COMPLETE证据，同source但不同job/config仍不混bundle |
| DP-INV02 | bank从READY提出到合法关闭借用不写；bank_gen/scan/row/full ctx必须匹配后才解引用 |
| DP-INV03 | 每个成功有效slot恰一pair，lane/坐标/HS/VS/DE一起固定推进，迟到旧scan不补当前像素 |
| DP-INV04 | 已proposed permit/req/R及held消息不因mode/cancel撤销，旧pending必须capture到其原预留或DISCARD |
| DP-INV05 | candidate不覆盖active current/next，local row归还不等待scope fence |
| DP-INV06 | APPLIED只在真实VSYNC换入；其业务消费先于对应RETIRE，transport保存不等应用 |
| DP-INV07 | FREEZE来自真实active，先有snapshot hold，再FM FREEZE，再COMMIT放hold |
| DP-INV08 | 欠载不暂停扫描/移位补像素；本scan后续safe，未来新token完整首行才重新用数据 |
| DP-INV09 | source/result BIND、scope镜像与通知借用在所有R/row/pipeline关闭及返还前不释放 |
| DP-INV10 | 图数量/内存端点/序号先扩宽检查；预算、文档检查、功能测试、STA证据分层 |

### E2. 八项中文操作草图

**DP-OP01 完整offer与预取计划。**
1. 以沿前FM可信绑定/COMPLETE、scope.kind/client、W/H、模式、图L/A/static map、SourceOrigin及三ID检验offer。源metadata始终存在；处理结果/ANN必须同源、同config/epoch/result代次。
2. 检验所有真实读plane授权；先预留candidate、三ctx中的槽、通知/关闭token、跨域接收容量，再保存不可变1963body并回receipt。非法不占别人ctx/返还别人租约；BUSY没有应用。
3. 转交video保存完整candidate；future预取按已保存PLAN的确切未来scan/target/source_y；current后续行按已经pin的current_exec，不能拿最新future撤销当前行。candidate不绕过active current/next，不预写像素FIFO混入旧frame。
4. 同沿freeze/stop/fault禁止尚未提出的新授予；已经fire/held offer保留并按身份取消，不撤valid。没有候选资格继续重复active或本地safe。

**DP-OP02 逐plane只读取数与carry。**
1. 以已pin row/scan/mode求源行；生产SRC row5760B、EDGE240B、ANN480B，各请求16对齐且不跨4KiB。一般小row用33bit求有效起止、对齐向下/上，完整16B访问须落在grant可访问A内，跳过prefix和tail、不使用它们作有效pixel；EDGE从bit yW、ANN从map+2yW，不逐row补DDR padding。L表示有效payload，A须由父明确授予对齐覆盖；例如W4/H2的EDGE L1B完整读需A≥16B，ANN map L2B同理须有完整末拍授权。若A=L不足16B则拒绝，不借allocation尾补足。生产三图L=A均16B整除。
2. 每次client1仅一R record，锁完整198头/permit/seq/tag/plane/row/bank目的地。先预留本地R128 holding与处理空间才ready；真正Rfire一次记录/保存，valid低不推进。服务整段正确不等本地行已经正确。
3. SRC carry192bit低byte为最低地址，接新128bit前旧有效carry≤5B，合计≤21B；每次真实pair装入bank才消费6B并计q，最多一pair/沿。分段剩2B/4B先转为row自有carry，不保留已经解除的service record借用。EDGE/ANN分别以有限160bit bit reservoir提取20bit word，最多旧19bit+128=147，尾word高位零。
4. 已接数据、同步WE/新carry与R holding分开；terminal消费、旧R处理/pending结清及剩余carry成为row独立值后就release本段。不能等下一R来完成pair而阻同record归还。失败kind1/2 terminal_fire共同终结未接受held R，旧pending capture DISCARD；kind3只隔离不解借用。
5. 所需plane计数/末bit/pad、所有WE/本段terminal/release ACK及holding/carry结清才READY。不存在plane不初始化成假正常mask；required保证已经完整产生。源相机/算法不同配置不在行中途切换。

**DP-OP03 三bank与原子跨域。**
1. active next最高正常优先，candidate只占第三空bank并借剩余读机会；同client已proposed candidate段不抢断，它的最坏阻塞须计服务期限。
2. SRC三个bank每个960×48封装60bit，三条20×512×两页，18RAM；EDGE每row96×20bit，三row288word一RAM；ANN每row192×20，三row576word两RAM。SRC地址page=q[9]/word=q[8:0]，EDGE base=96bank_id，ANN base=192bank_id并按word[9]选页，未用地址不读。
3. 填充结束先固定ROW336和bank数据，再跨原子mailbox。运输ACK只是保存；OWNED业务ACK后确认视频取得读权。提出后不改row/scan/mode，也不因timeout撤READY。
4. 行或candidate作废时通过独立RELEASE关闭；仅身份匹配、kind0/1/drained1且双方旧RAM pending/held消失才能回ACK。ACK运输保存后FREE，下一沿再授。忙/重复/错gen不写新FREE。
5. 单端warm reset不清状态/邮箱toggle；旧link固定，双方数据/消息/holding与完整scope借用关闭才换link_session。

**DP-OP04 固定扫描与同步RAM读。**
1. video h/v按D3每个合法pair钟推进，图未ready也不停止。VSYNC以沿前完整candidate或repeat row0、策略/健康/完整ctx、前scan CLOSED业务ACK和SELECTED/CLOSED容量判断图扫描与换页；freeze同沿先快照旧active。不能新建image scan时整帧safe且不应用candidate。实际SELECTED固定路线并交core，future预取授权不需要等未来SELECTED。
2. 使用匹配target_y/scan的完整row bank；SRC每pair最多一RE，EDGE每10pair、ANN每5pair预取packed word并保留FF；页跨511/512的capture取旧pending页/owner。所有已RE目标预留，下一沿preedge capture，不从刚提交新寄存器取同沿数据。
3. 固定读与render候选：eL发RE；eL+1 capture/取mask并固定slot；+2权重项；+3部分和；+4 Y；+5模式/颜色后形成RGB48及同步；+6视频adapter最早接受。实际mask预取先建立cache资格；新cache与SRC不能误用更新沿。
4. launch按未来6pair扫描slot的h/v/DE规划，不把延迟后的颜色配当前HS/VS；跨line/frame提前规划的blank不借图。应用决策仍在实际VSYNC，首active在41行之后；不得提前用未决定candidate读业务pixel。
5. 行末等待该bank RE/pending/cache及预渲染54bit holding借用结清才release；已复制的render/pixel/encoder持有独立scope/scan引用，不让bank等它们。跨bank只换完整目录，不把最后pipeline像素贴成下一行；本scan最终流水关闭另报CLOSED。所有输出槽为不可暂停的计划slot，不使用软件循环顺序代替逐沿契约。

**DP-OP05 灰度、比较、叠加与两个pixel。**
1. 每个slot固定原RGB/edge2/ANN4、mode/render generation和坐标；无效/不required平面不解其RAM。灰度乘积先扩16bit再移位加法，和+128上限65408，不窄化溢出。
2. 按D2布局与优先级形成两个RGB，所有sideband一起延迟；旧held/在途pair不读新的外部阈值、mode或颜色。识别ANN非0才替换，code00保留背景。
3. pair→pixel适配必须规定相关clock的相位装载窗、first lane、第二lane及HS/VS/DE重复两次的采样边沿；此真实公开/IP合同当前B，不用原vid_cnt或名字推断已满足。
4. encoder RGB顺序、control symbol与10bit输出延迟待真实证据，专用serializer half-rate/双沿按选定版本验证。四PN交换仅在码字唯一边界取反一次，不额外交换/再次取反。
5. 本地诊断和safe绕过DDR，safe自身HS/VS/DE也服从固定scan；失clock不宣称无中断。无gamma/audio业务验收需要则不复制未验证辅助控制，外部公开编码器配置仍必须正确冻结。

**DP-OP06 真实active冻结与有序恢复。**
1. 接纳SNAP后置apply屏障；请求可见后的VSYNC先取沿前真实active/scan/SourceOrigin，建立原BIND下snapshot hold和不可变1353结果。候选同沿不能抢先应用。
2. FM先加源FREEZE，再以同SNAP事务seq、op1和匹配Origin/policy发COMMIT；去重核(op,control_seq)，与op0的body不同是合法续阶段，同op重复异body仍拒绝；video业务接受后解除hold，转仅允许新冻结源/策略bundle。旧candidate显式cancel，预取段/READY/借用排空后CANCEL终态。
3. NO_ACTIVE仍保持禁止候选apply屏障；FM可选旧完整latest或等待首个COMPLETE再COMMIT。若等待时RESUME且没有首源，先FREEZE_ABORT291和业务done结清原SNAP，不等永不存在的首帧，然后RESUME_PREPARE/COMMIT。
4. 已更早VSYNC应用的candidate按真实active处理，不把它当未应用pending释放。APPLIED业务ACK与snapshot消息即使不同步到core，也按完整身份保护；core shadow不是快照来源。
5. 更新阈值不改已active render，重处理结果仍绑定冻结原SRC、config/job可变。恢复解除FREEZE位不解除其他BIND；直播/慢任务选源仍由FM策略，video不自行写源账本。

**DP-OP07 欠载、迟到与下一scan恢复。**
1. 缺row/缓存/pending、错identity或DDR故障时锁本scan sticky_underflow/first_bad_slot、frame_ok0；从首个缺slot起后续安全输出，不暂停h/v，不把迟到像素平移补进当前位置。
2. 之前已经输出的像素不能追溯改成safe，所以此frame记录partial。安全图案仅报告容错，不能判健康无撕裂通过。late READY按原scan DISCARDED；未来row保持到其真实slot但不借它填当前。
3. 下一VSYNC只有新scan token、前scan CLOSED业务ACK已结、SELECTED/CLOSED与current_exec容量可用、合法同active或新candidate的完整row0/策略/服务健康成立才重新用图；否则safe整scan，保留active身份用于关闭但不报告成功显示。
4. FRAME_OK只在本scan全部1,036,800个有效pair实际合格输出、相关adapter证据正确且无fault后形成；重复成功帧记repeat，画面无目标不记失败，clock丢失/underflow/DDRRESP分别计。
5. 诊断饱和计数先扩宽检查、overflow独立；每slot递增scan位置不能用新frame号大小替代完整Origin。

**DP-OP08 退休、取消、复位与父返还。**
1. 不再active或candidate取消后停新row业务和prepare，旧已经提出的permit/req/R以及已接holding/WE/pending按原bank/ctx继续合法结账；raw计数/消息不因私有rst丢失。
2. 所有应有请求实际交付/未提出permit返还后保存独立request_closed/cutoff；父seal/fence不阻本地R处理、RELEASE或row关闭。局部终态不等待父FREE/CLOSE。
3. video旧row reader、cache/holding/render/pair→pixel/encoder流水都不再引用scope，再出local_closed；编码流水具体消失证明目前B，不能只见DE0/固定安静沿数猜安全。
4. service phase0 CLOSE_GRANTS证书与local关闭合取后一次固定840status；FM消费后独立binding_return/ACK。父scope/grant和mirror CLOSE才最后回收对象，旧APPLIED先于对应退休通知。
5. 无法证明旧效果消失时Q及不可变drained0；平台PREPARE完整身份授权才安全处置旧pending/held并回QUIESCED，FINAL全部证据及done实际消费后才能解除保持。新PHY不能重吃旧valid；不单端清银行/CDC/session伪造新帧。

## F. RTL、参考与实现预算

C++本批不使用；未来独立Python参考只定义图/模式/事件期望，不复制RAM/FSM作oracle，获批后才写。三份契约分别是D2数值、D/E硬件执行、软件像素对应DISPLAY_ID/scan/target/source/slot/render generation；正确数学图不能代替CDC/DDR/serializer证据。

| RTL项 | 当前明确契约及剩余依据 |
|---|---|
| A 数值 | unsigned字段/合法码；RGB/灰度16bit界、bit reservoir/byte端点33、mask/ANN编码、源/显示y分开；不窄化后检错 |
| B 时钟/观察 | core/pair正沿各自旧状态计算；RE下一沿preedge capture，观察在更新稳定后；pixel/fast专用关系待实际证据 |
| C 接受 | offer/row/control/DDR各真实fire；scan无ready；保存/OWNED/APPLIED/归还不同事件 |
| D valid | 无data valid不推进图计数；scan每沿推进；无效plane不读取，合法零值不是无结果 |
| E 保持 | held READY/OFFER/req/R/终态全部payload保持，cancel不得撤；旧pending有预留身份 |
| F 延迟 | OP04候选6pair到adapter，blank同延迟；mask预取与DDR等待另计；不声称真实编码固定延迟已证明 |
| G 复位 | 功能rst停止新接纳，旧DDR/row/控制/通知保持；双方关闭才清CDC/换session；clock未知Q |
| H 配置 | render随OFFER冻结，row引用它；每scan实际路线由video VSYNC/SELECTED固定，current_exec与future PLAN分开；mode/阈值不改旧slot |
| I 存储 | row21RAM替代旧FIFO9，1R1W/dual-clock/跨页待工具；三个bank独立owner，不写已曝光或借用bank |
| J 身份 | DISPLAY_ID/fullscope/Origin、bankgen、scan、target/source_y、mode与lease共同；零值不作隐式无效 |
| K CDC | 原子mailbox、数据稳定银行与独立归还；related视频clock不误作异步逐位同步或全局exclusive |
| L 实现 | V4 Ti60F225 I3/SV2009/Efinity2026.1/Questa2024.1候选；专用HDMI/DDR/2Gb真实兼容、pin/时序/资源尚NOT_RUN |

已列RAM：前轮162包含旧display FIFO9；本版减9加SRC18/EDGE1/ANN2=174/256=67.96875%。4bank沿用分池布局为SRC24+EDGE1+ANN2=27、新总180；六行若仍用本版分池布局则SRC36+EDGE2+ANN3=41、新总194。附件的“六个54bit合并row bank”是另一布局、36RAM/新总189，还需独立packed解包与scratch预算；两者不能混称本版六bank。均不与3bank同时计。3bank是本版候选，替代的原语dual-clock/端口、全部FF/XLR/DSP/PLL及STA尚未实际报告。

最坏mode5每row5760+240+480=6480B=405个16B R拍；1080p60平均419.904MB/s。健康core顺序基本组装至少RGB960+EDGE96+ANN192=1248沿=12.48µs，只余2.3348148µs容纳额外R等待、请求/terminal/release、分段/CDC和调度；它是乐观下界，不是可达周期或期限证明。主动next先于candidate，但已proposed段不可抢断；必须测真实最坏服务曲线，平均带宽和RR机会不能证明所有行ready或六源下一SOF空槽。候选首行到首DE有607.407µs但还须预算全旧bank/R/控制归还，不把空白时间当实测保障。

## G. 实施与验证计划（全部未执行）

先闭合DP-B/统一父版本→独立审查/基线→READY及指定批准→仅获批work中rtl/display的bundle_lifecycle、display_fetch、display_row_store、display_scan、display_render、video_pair_adapter及未来sim/model接口。以上为计划文件/符号，均未生成。真实保护IP/器件校准与最终pin/SDC另核原批准。

| TEST | 目标、输入与事件 | 期望、方法与依据 | 状态 |
|---|---|---|---|
| DP-T01 | REQ01固定2200×1125/60，启动/无图 | HS/VS高区间、DE与N/总周期；独立计数及真实IP观察 | NOT_RUN |
| DP-T02 | REQ03黑白原色/256灰阶，两lane | FE公式灰度及canonical低地址RGB，无R/B互换 | NOT_RUN |
| DP-T03 | REQ03上下比较y539/540/1079、W1920 | 相同源偶行映射，target/source分开，不跨mode旧bank | NOT_RUN |
| DP-T04 | REQ03overlay/ANN00/01/10/11和开关 | 原图保持、ANN优先、snapshot色不被外参污染 | NOT_RUN |
| DP-T05 | REQ02OFFER非法scope/grant/COMPLETE/图mask | 拒绝且不释放别人的绑定，SRC存在与扫描mask区别 | NOT_RUN |
| DP-T06 | REQ02candidate首行未齐/过期、事件满 | 不应用，保持old或safe，held消息不撤 | NOT_RUN |
| DP-T07 | REQ04current/next/candidate同时存活 | 不写借用bank，3bank无隐藏第四结果 | NOT_RUN |
| DP-T08 | REQ04SRC page511/512、ANN word511/512 | preedge取旧页/owner，cache持有正确，未初始化地址不读 | NOT_RUN |
| DP-T09 | REQ03/04SRC跨128bit/1024B/4KiB、2/4B carry | byte序/配对正确，carry移交后本段及时release，无互等 | NOT_RUN |
| DP-T10 | REQ03EDGE/ANN小W4,H2/H6与bit prefix/tail | 连续map不逐row补DDR，越L/A或allocation尾拒绝 | NOT_RUN |
| DP-T11 | REQ04ROW运输/OWNED/release/ACK反压 | 数据不变、重复幂等，Q不FREE，下一沿再授 | NOT_RUN |
| DP-T12 | REQ04旧scan迟到/同scope重复/下一PLAN先到、PLAN更新满 | current_exec不被future撤权；SELECTED先消费再新future交付，未选row独立DISCARD | NOT_RUN |
| DP-T13 | REQ02/07APPLIED/SELECTED/CLOSED ACK迟到或CLOSED先到，D+R+R | 独立槽不互挡；先SELECT后CLOSED、新图scan前旧CLOSED结清；先apply后retire，三ctx上界 | NOT_RUN |
| DP-T14 | REQ05core影子A/videoB、freeze同VSYNC offer | 取沿前B原始SRC，snapshot hold先于移交 | NOT_RUN |
| DP-T15 | REQ05NO_ACTIVE有/无latest、等首源时resume | 屏障保持，FREEZE_ABORT先结旧SNAP，不等不存在首帧 | NOT_RUN |
| DP-T16 | REQ05COMMIT重复/错body、快freeze/resume | 先FM FREEZE才放hold，无双归还/晚旧策略应用 | NOT_RUN |
| DP-T17 | REQ06首/中/末行欠载、迟到后续row | 首缺slot起safe、scan不停、partial/first_bad正确 | NOT_RUN |
| DP-T18 | REQ06下一scanrow0仍缺、新token齐但CLOSED ACK满、未选future | 不用旧scan补新；容量及新首行齐才恢复，无CLOSED的未选row也可DISCARD | NOT_RUN |
| DP-T19 | REQ07candidate取消与R/末WE/READY同沿 | 真实旧fire计账，承诺保持，row关闭独立fence | NOT_RUN |
| DP-T20 | REQ07terminal1/2/3、held R/pending及release stall | kind1/2共同终结，capture DISCARD不复活，Q隔离 | NOT_RUN |
| DP-T21 | REQ07status/return/父close/冻结镜像故障 | status先消费再独立返还，未证不FREE，Q不改写 | NOT_RUN |
| DP-T22 | REQ08pair/pixel相位、双lane、10bit/PN | 真实encoder/serializer位序与控制匹配，补偿一次 | NOT_RUN |
| DP-T23 | REQ07/08功能rst、单端CDC、失clock/新PHY | 保持旧身份，PREPARE/FINAL处置，无epoch伪排空 | NOT_RUN |
| DP-T24 | REQ08全部算法/采集/display争用与工具报告 | 实际行期限/六源/174原语与FF/STA/约束覆盖，不能用均值PASS | NOT_RUN |

数值参考按完整图与D2直接公式，协议期望按租约事件集合独立计算；seed/精确工具/IP观察点/真实服务上界在无阻塞版本冻结。core/pair异步相位及related视频采样分别覆盖；小row测试不能替代1080p60/受保护IP/2Gb PHY整机验证。

## H. 双向追踪

| REQ/来源 | MOD | IF/操作/不变量 | 计划符号；未生成 | TEST与真实证据 |
|---|---|---|---|---|
| DP-REQ01 / B4 | DP3/5 | IF03/07/08、OP04/05、INV03 | display_scan/video_pair_adapter | T01/22/23；NOT_RUN |
| DP-REQ02 / B4,A5,A6 | DP0/3 | IF01/03、OP01/04、INV01/06 | bundle_lifecycle | T05/06/13；NOT_RUN |
| DP-REQ03 / B2,B4,A5,A6 | DP1/4 | IF02/04/07、OP02/05、INV03 | display_fetch/render | T02/03/04/09/10；NOT_RUN |
| DP-REQ04 / DER03/05 | DP1/2/3 | IF02/03/04、OP02/03/04、INV02/04/05 | display_row_store | T07/08/09/11/12；NOT_RUN |
| DP-REQ05 / UC05,A3 | DP0/3 | IF03/05、OP06、INV06/07 | display_control/active_snapshot | T14/15/16；NOT_RUN |
| DP-REQ06 / DER06/07 | DP3/4 | IF03/07/08、OP07、INV03/08 | display_scan_fault | T17/18；NOT_RUN |
| DP-REQ07 / DER03/07 | DP0/6 | IF02/04/05/06/08、OP08、INV04/09 | display_close_join | T19/20/21/23；NOT_RUN |
| DP-REQ08 / B5,R0 | DP全 | IF07/08、OP05/08、INV10 | video/pin/clock integration | T22/23/24；NOT_RUN |

反向核对每个拟新增职责均承担上述要求；24场景全部覆盖，每个IF/OP/INV有路径。实际代码/稳定符号/基线、文档—注释—代码—测试一致性只能在获批实现后登记，不用计划名冒充存在文件。

## I. 门槛、阻塞与批准

| BLOCKING | 当前正确性缺口及下一证据 |
|---|---|
| DP-B01 | 现用encoder/encode/aux时序、控制/通道/无gamma配置、TMDS合法输出、保护Questa兼容；新增Demo可读TMDS编码候选尚需复用条件/reset/数值与adapter选定，不能由可读源码推定整条serializer已验证 |
| DP-B02 | pair→pixel两个采样沿与fast half-rate相位/首位/编码延迟/旧流水关闭；完整相关clock契约和真实仿真/STA |
| DP-B03 | FM/DDR/PL的OFFER1963、ROW336、PLAN522与SELECTED1013/CLOSED921独立交接、typed冻结/ABORT、ANN授权及status→return联合端口尚未吸收 |
| DP-B04 | 真2Gb器件/DDR PHY/校准及响应/复位安全；既有模型请求待答，行为存储不替代 |
| DP-B05 | 三bank/1248沿乐观下界、active与candidate不可抢断段、所有模式真实最坏服务和六源期限；需资源/调度优化及真实证据 |
| DP-B06 | native双clock1R1W、SRC/EDGE/ANN跨页cache预取、6pair流水控制与全部FF/XLR/STA，当前只有候选 |
| DP-B07 | 实际HDMI电气/PN补偿/common-mode、最终pin/clock/SDC生成与覆盖、真实显示观察；软件与实物证据分层 |
| DP-B08 | 控制/全机统一设计、指定版本范围基线实施及原工作副本/构建/DB审批未完成，全部业务测试NOT_RUN |

规范§10.3①整体/样例、②职责/来源、③候选接口/组合、④数据/中文草图、⑤语言数值时间、⑥走查、⑦验证追踪已有设计内容；⑧无正确性阻塞不满足，⑨保存/实际读回/呈现及独立复审由审查记录绑定，⑩版本范围清楚但实施基线未冻结。保持LOCAL_DESIGN，不标READY，不声称用户批准。可以继续只读来源、相邻设计与文档复审，不生成业务源码/可执行测试。

## J. 变更与恢复

相对旧PL/FM候选：用3双clock row bank替代512×168 FIFO；新增scan64、current_exec/future PLAN及SELECTED/CLOSED、完整render/layout/OFFER、ROW所有权、typed冻结ABORT与真实业务ACK；ANN色/优先级及上下比较映射明确；status/独立返还/父scope/mirror分开。它们都是批准前候选，不改旧稿或FE冻结输入。

恢复先读最新主计划/本稿/附件/来源与真实批准，再核父版本、hash和实际验证。改变bank数、色/缩放、延迟、token/流控、复位或重要资源取舍先修订设计和追踪。此前CAMERA审计保留历史，不覆盖原参考资料。

## K. 实现与验证实录

本轮只读来源、设计文档、算术和读回/复审。业务RTL、功能脚本、参考模型、可执行tests/TB、仿真、综合、PNR/STA、bit/hex、I²C/下载/实机全部NOT_RUN；原资料、正式状态、数据库和审批Manifest未修改。文档结构检查不能支持功能或STA通过。

## L. 交付与阅读说明

读B/C整体→D接口/模式/scan/冻结/组合→OP01 offer/计划→OP02 DDR carry→OP03 row银行→OP04固定扫描→OP05双pixel/颜色→OP06冻结→OP07欠载→OP08关闭→F/G/H/I与中文附件。完整路径是合法同源OFFER→未来scan首行→实际terminal/release→READY/OWNED→VSYNC SELECTED及必要APPLIED→current_exec逐行render→本scan CLOSED/ACK→旧R/row/serializer关闭→status消费→binding_return→父scope/mirror关闭。

修改视图先改D2/render与OP05/T02…04；修改bank或deadline先改IF02/04、OP02…04、F/T07…12/24；修改冻结先改IF05/D4/OP06/T14…16；修改encoder先关闭B01/02再改IF07/OP05/T22。所有图/字段/步骤须在最终获批源码真实存在后再次核对。理解验收无用户作答，待检验，不把阅读材料当用户理解或完整工程验收。
