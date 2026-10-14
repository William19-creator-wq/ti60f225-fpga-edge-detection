# TRACK4-ALGORITHM-PROFILE-SOURCE-001：真实PROFILE与原图借用/冻结联合稿 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED。先整体B/C，再D交接、E中文步骤、F预算、G/H验证追踪。本稿补SLOT-JOIN的SJ-B02；部分选择已明确，精确参数、完整目录与生产事件仍未闭合。1080p、完整Canny、任意旋转识别、原质量和板卡现有资源边界保持。

## A. 目标、来源、允许行动

- Goal：将完整识别profile映射到有限片上实体，明确epoch不可变；给同一SRC的最新源、冻结、新J、旧bundle与观察分配独立借用身份，避免返一个引用就销整图。
- Current state / Gap：CONTROL提供profile_ref但没有真实实体，op4仍DEFERRED；SLOT-JOIN统一6/3但SOURCE182未携独立admission，单源S_ONLY不能直接用于共享源。DDR恢复后A3是当前范围。
- Target：候选实体、字段、准入、冻结/恢复、关闭和预算可以相互核对，再纳入整体指定版本批准；不能以引用编号或文档存在自证运行。
- Assumptions：单执行J/单scratch、六SRC/三结果、最多两不同bundle物理扫描；实际源必须完整immutable；新增普通业务均同core，VIDEO交接按PIO真实稳定mailbox/CDC。
- Dependencies：下表实际hash；原HDK只读。v1.2预检范围不扩张，待批准v1.3/Gate不修改。正式数据库NOT_CONFIGURED，状态和Manifest不改。
- Open questions：PS-B01…04；数值0不是未知参数的安装占位。最新帧策略只适用于慢完整帧后端，不免除基础流水/采集无丢帧要求。
- Milestones / Detailed steps：真实schema/原需求→native布局→独立lease/策略身份→冻结关闭走查→限定独立复核→主稿吸收→实际参数/目录/CDC/全预算冻结→整包READY/批准→work实现/验证至bit。
- State transitions：仅设计、纯数据、审阅、入口与追加本地事件；不改正式业务状态。下一允许行动是有限审阅和未决设计，禁止业务源码/功能脚本/模型/TB。
- Artifacts：[PROFILE片上布局纯数据](../experiments/track4_algorithms_20261004/01_baseline/profile-store-layout-v0.1.json)，4254B，SHA256 `4FE6BF462E97C30D8F421E9D30FDA96D4D9DFC7AC397024B4320159702B0B810`；无运行授权/真实参数。
- Validation / Failure handling：实际来源与算术分层记录；G均NOT_RUN。陌生ref、迟到旧回执、Q、未知读写和不完整关闭不授FREE。
- Human approval gates / Rollback / Completion：旧版本保留，本稿只显式覆盖J差异；整包不满足§10.3且未获实施批准。完整完成仍须十一项真实代码/仿真/综合/PNR/STA/bit，bit后停止。

| 来源 | 实际SHA256 | 读取/依赖位置 |
|---|---|---|
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | D/P/C/J、profile、op4和旧同沿规则 |
| [VIEW v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | 源登记/返还、prejob、七owner/真实epoch |
| [R4R v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | E10完整1024、RJ2257真实绑定、算法质量未知 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D | 距离/UNORM/定点守卫，不复制旧默认 |
| [SLOT-JOIN v0.1](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | 6/3/单scratch、真实信用/历史J、两物理引用 |
| [DDR布局 v0.1](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json) | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 | 84.25MiB及未分配源128B，本文不改此布局 |
| 现装Efinity sim_models/verilog/efx_ram10.v | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33，17913B | 实际L7–27/100–122/177–213/330–417；20×512、WE、同步读、同址未定义 |

根定向读取上述来源并全文读回本稿/纯数据；两名审阅者实际读取范围另存，不能把部分阅读冒充全文。旧FRAME_MANAGER/CONTROL只用于来源事实，旧FM字段/epoch/SourceOrigin和当前逻辑对象不cast。

## B. 整体外部行为与要求

PS-REQ01：最多八份完整PROFILE1024、独立非零profile_ref64；一块native RAM10保存实体，八个UI preset不是八个识别profile。只有真实安装/封存、版本/字段/当前epoch匹配才有RC资格。

REQ02：安装后的body在整个软件epoch不可改/删。D/P/C/J/V保留历史引用；软件QUIET不要求先清installed或旧D/C引用，START真实应用才隔离旧资格，避免与epoch更新互等。

REQ03：stable source_image_id和source_handle标识图，admission_ref标识一次真实借用。LATEST、FREEZE、每J/对应bundle、观察分别持独立lease；返还一份不销其他引用或注册base。

REQ04：慢完整帧后端LIVE选择最新成功完整源，FROZEN选择实际冻结源。sourcefire原子保存旧source_policy_generation64/kind、J、信用与admission；不借algorithm_generation32充策略屏障。

REQ05：KEY1短冻结意图不再作为DEFERRED完成项。冻结必须先取得当前实际显示对应源的真实FREEZE借用，再释放snapshot hold；无显示可WAIT_FIRST，RESUME可以进入并终止等待。冻结不STOP相机，不把不ARM整帧未接纳说成无丢帧。

REQ06：六源容量不得藏第七种源。信用可在J忙时预收，但带源的admission只能在旧J IDLE/终态消费/scratch空/信用及BIND预算齐全时创建；禁止带原图的lookahead。

REQ07：旧published offer/request履约；旧源转移和同沿真实fire先登记。软件reset遍历profile主动读取、全部源leases/策略/snapshot/通知；Q与未知不清空成成功。

正常例：A/B已绑定、第三结果槽RESERVED；F冻结源、L最新源、C捕获生命周期、U待sourcefire admission，最多六种不同源。U sourcefire/BIND后只是成为第三bundle的源，未增加第七种。多个bundle同SRC时，仍各有一份独立admission lease。

反例：三bundle各占不同源，加F/L/C已六；若J忙时提前借旧latest U，latest又更新，会出现第七种不同源。本稿禁止该准入。另：返回B0的SRC lease后，B1/FREEZE仍引用同源，物理SRC不可写。

范围：原赛题基础采集稳定无丢帧、行缓存/同时流水、HDMI连续无撕裂仍独立必验；资料未承诺所有慢识别模式每摄像帧处理。latest策略是完整帧后端候选，不缩分辨率/质量，也不提供采集或处理fps达标证据。

## C. 唯一owner与连接

PROFILE_MANAGER是O(owner1)内部职责，维护有限目录/安装/GET/epoch关闭；不新增第八START ACK。SOURCE_POLICY维护latest/desired_freeze/actual_freeze、策略代次与选择；SRC_LEASE_OWNER归O，唯一分配lease request序号/ref和真实归还事实。SOURCE_REG仍唯一分配source_image_id/提出源offer。JOB保存一份当前J及PCTX65，O保存三个历史PCTX。VIDEO唯一报告实际扫描/snapshot，UI只提交意图，不代报冻结完成。

路径：BOOT模板→真实PROFILE安装/SEAL→CFG完整检查→JOB按旧C取PROFILE→RJ2257；camera真实SRC seal/register→LATEST lease→按FREEZE/LIVE选择→admission grant→SOURCE311→JOB→BIND同lease转O→完整bundle→VIEW/VIDEO→各lease实际return→最后注册base/源退休。冻结支路：UI绝对意图→VIDEO当前实际PLAN snapshot hold→O查真实SRC→FREEZE grant→释放snapshot→封旧offer/提交新策略→同SRC重算。恢复先实际返回FREEZE，再提交LIVE；其它旧bundle/J leases继续各自关闭。

## D. 共同字段、存储与组合检查

### D1. PROFILE实体及接口

七组从body低位到高位依次header128、structure192、fit192、verify192、dedup128、raster128、tail64，总1024。各组内字段顺序/固定值以R4R E10为权威，layout3/numeric1/algorithm3；header profile_ref必须与实际实体/CFG/J/RJ完全相等。旧layout1/2不blindcast。1024bit是完整body，不是只存被用门值。

8槽wordbase为0/52/104/156/208/260/312/364；word0…50每份20bit，word51低4bit为body末4bit、高16零，最后合法word415。8192logical＋128padding＝8320physical bit，416words；416…511共96words不得普通访问。READ/WRITE_WIDTH20、addr9、OUTPUT_REG0、完整写WE11；BOOT写与GET完全互斥，同址读写禁止，不以READ_FIRST名字当证明。SRC128B预留不使用，DDR84.25MiB不变。

| PR接口（同core、独立namespace） | body及真实成功依据 |
|---|---|
| PR_INSTALL1121 / ACK1257 | epoch32/install_seq64/template1024/preferred1；ACK原1121/status2/reason5/installed1/ref64/seal64。仅BOOT，template header ref0是未安装模板；O分配非零ref填入后逐52字完整写，真实末写/资格检查后installed。模板不是可引用PROFILE。 |
| PR_BOOT_SEAL100 / ACK108 | epoch32/boot_seq64/expected_count4；ACK原100/status2/reason5/sealed1。核实际count1…8、全部已封存、恰一preferred和实际输入版本，随后禁新安装，才开放运行GET/RC。未冻结真值模板不能通过BOOT。 |
| PR_GET184 / REPLY1215 | epoch32/client2/query_seq64/profile_ref64/W11/H11；reply原184/status2/reason5/body1024。client0CFG/1JOB，2/3拒绝；各RX/reply depth1，按完成轮转；正确目录/epoch/尺寸/52字实际捕获及全schema核后success body。 |

PR status0成功、1明确拒绝、2已接纳失败、3Q；reason5另建PROFILE族，0仅success。完整错误矩阵及重复窗口须PS-B02，不能用RAW/RC同宽枚举。安装/GET已提出全文held不撤；同请求身份不同body拒绝。每client最后完成cache保存原request及原reply，重复只回原事实、不再分配ref；更早未知序号拒绝，序号扩65检测、不回绕。BOOT_SEAL同样独立receipt缓存，不复用UIseq。

ACK seal64是O在真实全52字安装封存时赋予的独立持久token，目录明确保存；不是ref或install_seq的数值别名。接纳安装前预检/预留ref、seal身份及回执容量，均独立64bit非零序列、扩65检查，预留不复用；只有实际封存才授seal有效。BOOT producer的install_seq是请求身份，不能代真实seal。GET/R4绑定由O核对应epoch/ref/已安装/seal真实记录，非零字段不造完成事实。

circle support3…N、line support2…N；比例门UNORM16/65535，距离及三个geometry dedup tol为Q4 u16，SSE门Q8 u32，label offset为s8整数像素。eligible≥circle_radial_tol且≥rect_inlier_distance；TLS前级line残差不暗加无依据关系。stroke1…255，label_mode仅0/1；off scale1且offset x/y0，on scale1…15。budget1…8191，missing/required仅0/4或1/3；所有固定结构/保留位及末字padding核全。旧关闭标签scale0被本候选显式覆盖。tol0可有精确语义，未知门不得填0安装；新censor guard及全部精确门值仍PS-B01。物理full-HIST不能把逻辑radius_bins8192变131072。

### D2. 源lease与策略身份

PCTX65＝source_policy_generation64/selected_kind1；LIVE0、FROZEN1。策略序列独立非零64、唯一SOURCE_POLICY分配，扩65耗尽，不借config/algo/camera代次。冷epoch默认LIVE/gen1、next2。T/R各自在接纳前预检并预留自己的future_generation64和收尾槽；预留即消耗、ABORT不重用，可跳号，不在FREEZE已经加ref或COMMIT held后才申请身份。真正冻结pin+旧offer封口，或恢复FREEZE真返还后，才将current代次提交为该预留值。desired_intent接纳与实际应用分开，held旧body不读新策略。过渡接纳时先登记同沿旧真实fire，之后独立registered admission_gate/publication_gate置0，不能等末尾current代次推进才阻旧未移交发布。

| 新候选族 | 完整字段/成功边界 |
|---|---|
| SRC_HOLD_REQ291 / GRANT363 | epoch32/hold_request_seq64/original_role3/role_key64/source_id64/source_handle64；grant原291/ref64/status2/reason5/granted1。O仲裁器唯一request_seq owner，role不是另一序号namespace。真实合法注册/角色授权、空lease/回复预算后原子加ref，才success。 |
| SRC_HOLD_RETURN355 / ACK363 | 原291/hold_ref64；ACK原355/status2/reason5/released1。只返这份真实lease，核本份全部read/pending/response/effects/pin关闭和匹配身份；其他bundle存在不阻本份合法归还，也不因此销图。 |
| SOURCE_OFFER311 | 原182＋admission_ref64＋PCTX65；SOURCE_REG唯一held1，由真实grant记录构造，不把ref当地址。只有旧完整J准入窗口可创建admission，首次提出即pin全body。 |
| BUILD_BIND1012 / ACK1212 | 原KEY162/source_id64/J657/admission_ref64/PCTX65；ACK原1012/status2/reason5/bound1/E64/A64/RECORD64。成功原子将同lease当前所有者J→O；失败无转移，J仍归还自身hold。原grant role/role_key/request_seq不变。 |
| BUILD_ABORT456 / ACK466 | KEY162/job96/source_id64/admission_ref64/PCTX65/first_reason5；ACK原456/status2/reason5/effects_closed1/objects_retired1/reservation_released1。不等JOB_TERM消费，只有真实对应O义务关闭才success；尚属J的lease由J另返。 |
| PREJOB_REVOKE224 / ACK232 | epoch32/source_id64/source_handle64/admission_ref64；ACK原224/status2/reason5/accept_suppressed1，namespace区别BUNDLE_REPLY232。核pin中完整SOURCE311和真实转移，沿前旧sourcefire优先、revoke_idle真实观察和撤offer窄例外保持。 |
| JOB_TERM734 | 原669＋PCTX65；父历史策略跟随完整旧J。R4数值请求不改；COMMIT1201由O匹配真实BIND历史PCTX，不从最新策略或同宽body推断。 |

grant正常role0LATEST/1FREEZE/2ADMISSION/4OBS；3/5…7当前非法。BIND current_owner/current_phase改为BUNDLE，**不改原grant role、不再申请role3、不增加第二ref**。SOURCE311 fire将admission转J；BIND失败不属于S_ONLY源无J。prejob仅判断这份admission是否曾转移，不能用整个SRC曾启动过任意job判S_ONLY。撤销后走HOLD_RETURN，不直接执行旧PREJOB_SOURCE_RETURN160销共享图。

LATEST可有current1＋替换closing1；FREEZE1；ADMISSION与BUNDLE合计≤3；OBS1，成功lease同时≤7，候选pool8含一份预检保留容量。每SRC count4至少容纳0…8，实际数由逐lease事件取得。role key对admission为epoch内唯一credit_seq；freeze为原UI.event_seq；LATEST/OBS为各实际仲裁记录的完整映射。迟到旧return/revoke不改变新ref或新代次。

最后销注册base须全部lease0、无writer/未转移offer/pending/通知、真实provider整体退休，和真实目录事实。REGISTER仅提供stable source_id/handle，不给每job自动复制借用。一个bundle的SRC退休转换为返它的admission lease；旧plane0 OBJECT_RETURN295不能据此销仍共享SRC。EDGE/ANN/RECORD各自退休按SLOT/VIEW原合同，不被源lease代替。

### D3. 冻结交接与六槽边界

UI执行器在KEY1 op4/key1时，把旧desired_freeze取反形成绝对F_SET102＝原UI101/desired1，独立held1；FREEZE_OWNER是该desired的唯一writer，UI每次等真实receipt后才形成下一toggle，重复完整body不二次取反。F_RECEIPT110＝原102/status2/reason5/accepted1只报告接纳；F_DONE368＝原102/status2/reason5/actual2/origin_valid1/source_id64/source_handle64/freeze_ref64/policy_generation64，分别报告实际LIVE0/WAIT_FIRST1/FROZEN2/Q3。具体完整status/reason/重复与UI277映射尚PS-B02；不能把receipt或UI回复当已冻结。

有界容量为current lifecycle T1、已接受反向RESUME R1，各自receipt/done独立；R ready不等T得到首图或done消费。已经published的T done不覆盖，后续R保持独立。KEY1长按仍独立RESET96，不经普通freeze槽。freeze不写CFG212/P/C、不分配config_id；source策略单独推进，普通阈值/颜色变化只影响同冻结SRC的后续完整J。

VIDEO_SNAPSHOT_REQ96＝epoch32/freeze_seq64（来自原UI事件）；VIDEO于请求真实可见后的帧边界锁沿前当前实际APPLIED的PLAN616及snapshot_hold64，避免core影子尚A而真实已B。REPLY784＝原96/status2/reason5/origin_valid1/PLAN616/snapshot_hold64；正常origin1、真PLAN/hold，O从仍pin的真实bundle记录查source_id→source_handle。该snapshot保留旧物理/父metadata，防源在核心取得FREEZE之前退休；它不凭空增加第三物理bundle资格。真实无active可报告NO_ACTIVE：origin0、PLAN/hold全0是该producer记录的真实absence，不凭输入0猜没有引用。通知接纳/ACK不等待FREEZE grant。

VIDEO_SNAPSHOT_RELEASE160＝原96/hold64，ACK168＝原160/status2/reason5/released1；只有实际FREEZE grant成功或明确不采用且相应义务闭合后，CORE才提出release。NO_ACTIVE时选择旧完整latest，若也没有则WAIT_FIRST，首成功源的保留/借用必须真实原子建立；这不是已经冻结屏幕的证据。RESUME有独立SNAP_CANCEL96/ACK104（原96/status2/reason5/cancelled1）可结束尚未形成origin的等待。已held REPLY或策略COMMIT不可撤，cancel到来仍消费真实结果/hold，再归还实际建立的FREEZE lease和snapshot；从未创建的ref凭真实absence，不等不存在RETURN。跨域请求/回执槽、cancel与reply同沿优先、策略COMMIT实际消息/阶段及物理close事件须PIO联合冻结，PS-B03未关闭。

策略变化先禁止新admission，已held旧SOURCE311走真实REVOKE224/ACK232/撤offer/revoke_idle/lease-return；任何同沿旧sourcefire先形成真实J，按旧PCTX保留cancel/终态。新策略资格后，未移交旧policy J置publish_allow0并真实取消，已移交结果按O/VIEW退休；当前屏幕继续重复旧合法图直到新完整结果，不改历史PCTX。新sourcefire只锁沿前旧策略，不能同沿穿透新freeze应用。

CAP生命周期含writer、seal/register、LATEST替换等待；这一生命周期实际结束才新ARM，不藏多份sealed候选队列。六SRC槽的准入必须数完整真实注册目录及CAP reservation，包含独立存活的OBS源；仅有实际FREE槽、上一CAP与独立旧LATEST closing真实结束时才ARM。无额外原图lookahead且OBS与B/F/L/U重合时，三bundle阶段没有新admission，distinct≤3B＋F＋L＋C＝6；预fire阶段distinct≤2B＋U＋F＋L＋C＝6。OBS虽不产生新图，仍可延长已失去B/F/L的旧源寿命：3B＋F＋L占5，独立OBS占第6，下一CAP会提出第7份需求，必须拒绝ARM并记录阻塞，不能覆盖任一源或把上述条件式当穷尽证明。snapshot选择已有B，未有B时等待而不造新源。借用计数≤7与distinct SRC≤6是不同容量；本候选只保证显式准入边界，持续有FREE槽、基础采集无丢帧和DDR服务仍PS-B03未闭合。

慢后端记录最近实际已启动签名{source_id64/config_id32/PCTX65}＝161bit；没有新源/新CFG/新策略或明确重算命令，不自动无限重复同一次工作。失败同样保留已启动签名并独立计数，不无限自动重试。FROZEN调参生成新job_frame/结果但保持原source/camera origin；算法切换不撤FREEZE，不走RESUME。未提出配置可合并，普通参数变化不反复取消当前J；算法/源策略真正屏障仍按原真实取消义务推进。明确重算命令入口/去重须PS-B02；源base必须保持真实capture/camera原身份，不能用新J覆盖。

## E. 中文操作草图

PS-OP01 初始化PROFILE：冷rst仅清目录有效资格→BOOT核完整真实模板/版本/尺寸/门关系→预留安装RX/ACK和真实slot/ref/seal→逐52字完整写→真实末写后封存→ACK held→所有安装结束且preferred唯一→BOOT_SEAL→运行GET。没有真实完整值模板就保持未READY，不用0填未知。

OP02 取PROFILE：接纳原GET只保存RX→下一旧资格选择client和真实installed记录→e0发word0读，e1捕word0并读word1…e51捕word50/读51，e52捕word51→后续沿全1024/schema/同ref/实际N核验→形成完整REPLY held。C/J只能在真回复匹配后采用，不从preferred_ref非0猜实体。

OP03 选源：接真实capture seal/register→先取得新LATEST lease再改latest，旧LATEST通过独立closing返还→后续旧J准入/信用/scratch齐全才选FREEZE或旧latest→真实admission grant→SOURCE311→sourcefire锁旧C/J/PCTX与ref→BIND转O→真实PREPARE/算法。

OP04 冻结：保存绝对意图/预留策略身份与独立receipt→真实VIDEO snapshot；NO_ACTIVE选择旧完整latest，无源才WAIT_FIRST且可接受RESUME→O核完整旧PLAN或真实注册源→取得FREEZE lease→释放实际存在的snapshot→封旧源offer并收真实义务→推进策略/actual FROZEN→独立done→后续同SRC新参数完整重算。UI运输接纳不授freeze引用；首源同沿RESUME已锁ABORT时先记源完成，但不重开FREEZE分支。

OP05 恢复：反向R可以进WAIT_FIRST→兑现旧held snapshot/reply/grant/cancel与旧T终态；COMMIT未提出可ABORT，已经valid则FINISH_COMMIT后按真结果恢复→返真正建立的FREEZE lease/snapshot，从未建立的不等不存在return→提交预留LIVE新策略并形成R done；其它BUNDLE/正在关闭的J leases不撤。新capture按真实ARM/SOF，旧屏幕按物理退休，不借恢复clear refs。

OP06 归还：核完整请求与原lease→关闭本lease全部访问→真实ACK→后续释放该lease record；最后所有真实持有者结束才退注册base/物理槽。unknown/Q保留实际引用，错echo不解债。RETURN/ABORT和成功COMMIT后的信用结束沿仍按SLOT-JOIN，只更新到本文新body/PCTX，不把信用结束当SRC已FREE。

OP07 epoch：停新安装/GET/admission/freeze/VIEW，旧held先履约→逐主动安装/读取/consumer pin/源lease/snapshot/通知真实排空→catalogue QUIESCED保留旧body/旧D/C历史值，禁新读取→O(owner1) closed_before真成立→授权START后才隔离旧installed，七ACK及父提交之后BOOT重装。不能要求先删除epoch profile或清旧D/C ref再成功QUIET；不能用frame OBJECT_RETURN销PROFILE。

不变量：实体资格源于真实完整写/读；一个epoch内PROFILE不可变；REF不是地址；同lease原grant身份不改；不同lease独立返还；没有带源lookahead；gen命名空间独立；有active时FREEZE来源真实APPLIED，NO_ACTIVE时来源真实旧latest/首成功源，均非CFG/V_LATCHED；published不随UI/reset撤；Q不授复用。

## F. 语言、资源与三份对应

候选SV2009，所有普通握手同core posedge沿前valid&&ready且非rst为fire，新接纳不穿透；同步RAM读按上文逐沿捕获。序号/ref先65bit、source index3拒6/7、bundle index2拒3、native addr9且授权范围<416。profile参数的signed/Q4/Q8/UNORM、label s8和运算前扩位分别按R4R/R3，不用同宽cast。VIDEO多域由具体CDC/mailbox解决，非逐位同步PLAN。

新增RAM候选1 RAM10，只覆盖8320bit实体加1920未使用位；不把它当整个PROFILE_MANAGER预算。有限目录保守8×{state2/epoch32/ref64/install_seq64/seal64}＝1808bit；ref及seal各next/exhausted65、preferred ref/valid65另计。INSTALL RX1121/ACK1257、两GET RX184/REPLY1215、GET assemble1024、各完整最后cache、BOOT_SEAL100/ACK108及cache都各自持有，不默删echo副本。当前源lease pool8每项完整原REQ291/ref64＋current_owner/phase/访问计数/valid/关闭事实另计，count4/每SRC目录和独立return/回复/pending也另计。至少REQ/ref payload 8×355＝2840bit；PCTX当前J65＋O三历史195＝260bit、最近启动签名161bit，不能复用algorithm_generation寄存器。所有FSM/有效位/索引、VIDEO snapshot/CDC/策略T/R/通知都须在全机预算实列，当前未宣称完整FF/RAM/DSP或STA通过。

共同数值：PROFILE完整v3字段与原图/GT从冻结的真值manifest提供；保存实体不证明识别质量。硬件执行：真实52字捕获、lease transfer/return、策略旧沿、snapshot/APPLIED和epoch关闭分别检查。对应：以epoch/ref/完整PROFILE、J/PCTX/source/admission/credit/result/PLAN及真实events对齐模型，不能由目录valid/DUT候选日志生成GT；固定值/schema算术不替代RTL时间/动态配置验证。

## G. 实施与验证计划（未生成/未运行）

先关闭I并合并共同schema/版本/文件与整包批准，再work实现profile_manager/profile_RAM/native wrapper、source_policy/src_lease/source_reg/J/O、freeze/VIDEO桥/参考/TB；不得把当前接口文档写成生产头文件。

| TEST | 场景与要求 | 期望与依据 | 状态 |
|---|---|---|---|
| PS-T01 | REQ01；8slot首/末word、最后4bit/高16、非法416/511、完整WE | 与独立整数布局/官方模型一致，无普通越界/同址读写 | NOT_RUN |
| T02 | REQ01/02；layout2/错ref/reserved/门关系/label off/第9模板 | 全字段拒绝，无凭空installed/ref；tol0合法语义与未知值不同 | NOT_RUN |
| T03 | REQ01/02；双GET、52读气泡/held、duplicate错body、BOOT/GET冲突 | 后续完整捕获才reply；独立client容量，epoch内实体不变 | NOT_RUN |
| T04 | REQ03；B0/B1/FREEZE同源、返一份、迟到return/ref错 | 仅对应lease退休，注册base仍保留；BIND不加第二ref | NOT_RUN |
| T05 | REQ04/06；3B/F/L/C占6，旧latest变化、禁止带源lookahead；OBS独占已失去其他角色的旧源 | 准入核真实distinct/保留槽；3B/F/L/独立OBS满6时拒第7CAP，不覆盖；阻ARM与采集/慢模式统计分别报告，不预称连续无丢帧 | NOT_RUN |
| T06 | REQ04/07；policy应用/sourcefire同沿、held source/revoke/cancel | 锁旧PCTX并记真实J，旧未转移lease才prejob返还；无同沿穿透 | NOT_RUN |
| T07 | REQ05；无active WAIT_FIRST/RESUME、snapshot held遇cancel、grant后原active退役 | RESUME独立接纳，真实snapshot/FREEZE pin交接，无陌生源/第三物理路由 | NOT_RUN |
| T08 | REQ05；冻结调参/颜色/algorithm、resume旧结果仍显示 | 后续完整J同freeze SRC、历史J不变、真实LIVE应用与运输receipt分开 | NOT_RUN |
| T09 | REQ02/07；旧installed非0/D/C ref非0、主动GET/leases排空、七START部分失败 | QUIET无删除环；O授权后隔离旧体，部分失败保持quiesce/Q | NOT_RUN |
| T10 | 全；真实值profile/GT、全1080p+基础流水、资源/CDC/DDR期限/PT/PNR/STA/bit | 全范围独立证据，不能靠本布局或最新帧政策冒称完成 | NOT_RUN |

## H. 双向追踪

| REQ | owner/IF/OP | 计划文件责任（未生成） | TEST |
|---|---|---|---|
| 01/02 | O PROFILE/D1/OP01/02/07 | profile_manager/profile_ram/profile_schema/native wrapper | T01/02/03/09 |
| 03 | O/SRC_PROVIDER/D2/OP03/06 | src_lease/source_registry/共享SRC目录返还 | T04/05/06 |
| 04/06 | SOURCE_POLICY/J/O/D2/3/OP03/04 | source_policy/job_dispatcher/per-bundle PCTX | T05/06/08 |
| 05 | UI/FREEZE/VIDEO/D3/OP04/05 | freeze intent/snapshot CDC/actual应用记录 | T07/08 |
| 07 | 全owner/D1–3/OP06/07 | QUIET/START/真实旧义务/错误隔离 | T03/04/06/09 |
| 全 | F/G/交付 | 独立参考/协议scoreboard/全机预算与中文说明 | T10 |

反向：每新增ref/策略位/profile RAM只承担真实不可变/共享/冻结义务；不引入外接存储、缩图、单目标或PC预计算。

## I. 门槛和实际缺口

| ID | 本稿之后仍需完成 |
|---|---|
| PS-B01 | 真值v3 profile全部门值/新censor guard及manifest、独立GT/参数性能选择；旧未验证阈值不自动安装为达标默认 |
| B02 | O/provider完整lease/目录/访问关闭/错误矩阵/去重、UI277/F消息联合状态与字段；具体descriptor/pin端口尚未实现/冻结 |
| B03 | 实际APPLIED/snapshot/cancel同沿、跨域mailbox/释放证明、基本全流水/采集无丢帧、DDR服务/固定VIDEO期限 |
| B04 | 每容器全机RAM10/FF/DSP/PLL预算、完整共同文件/schema/局部吸收、独立整包复审与指定批准/治理前置 |

一块RAM几何、独立源lease和旧策略身份形成明确候选；不能把它们称SJ-B02全部关闭。§10.3⑧仍不满足，NOT_READY，不申请未成熟整包实施批准。

## J. 显式覆盖与版本吸收

当前候选覆盖：CONTROL op4 DEFERRED→独立冻结意图/实际完成、profile空provider→真实有限实体；SOURCE86/182→311；BIND883/1083→1012/1212、ABORT327/337→456/466、REVOKE160/168→224/232、JOB_TERM669→734；O history额外PCTX；共享SRC的S_ONLY/返图改为逐admission、最后注册base另退。原数字同namespace已不兼容，旧局部尚未吸收；共同schema必须显式选本候选。数学/RJ2257/COMPLETE_CERT352/COMMIT1201及信用162/RETURN167/ACK175、AUX族保持，不能据宽度相同借用消息。

旧BODY/hash与审阅保留；新变化都未获业务批准。整包批准之后若改变门值/缓存/准入/策略/关闭/CDC等重要选择，仍按唯一v0.2§11.2重开受影响设计，不当内部格式调整。

## K. 本轮实际记录

原来源定向读回、20×512模型/字位算术实际核对，纯数据保存全文读回；独立数值审阅确认native几何并指出label/censor/QUIET免环，协议审阅找到第七源lookahead和grant原role不能改的反例。E68F草稿的实际限定数值审阅与全文协议审阅还指出seal未计目录、独立OBS会延长旧源寿命：已补持久seal/独立预留和1808bit目录；六槽以真实占用准入，OBS不重合时可拒ARM，基础持续服务仍OPEN。FC7EE草稿限定读回确认新seal数值，并将OP01同步补上seal预留；精确输入与后续读回范围在实际审阅记录中分别绑定，不预称整包通过。

没有生成算法work、业务源码/模型/runner/TB/工程/约束或执行新编译/仿真/PNR/STA/bit。原资料、待批准v1.3/Gate、Manifest、正式状态和数据库不改。静态设计与原有限v1.2预检终态分开，完整目标未实现。

## L. 阅读与交付

先B理解实体/源/策略→C唯一owner→D1 profile真实安装/取回→D2一次借用与历史身份→D3冻结和六槽反例→E逐步正常/失败关闭→F预算/映射→G/H验证/追踪→I/J未闭合及覆盖关系。当前交付是源/profile联合候选，不是软件实现成功证据；完整十一项软件测试目标保持。
