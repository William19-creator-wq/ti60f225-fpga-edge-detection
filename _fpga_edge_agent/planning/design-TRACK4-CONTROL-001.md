# TRACK4-CONTROL-001：四键、配置快照与生命周期控制 v0.1

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)创建；2026-10-04。**LOCAL_DESIGN / NOT_APPROVED_FOR_IMPLEMENTATION**。本稿是 MOD-12 与 MOD-04 的候选交接，补齐整体之后的控制行为与中文操作草图；相邻 FM/PLATFORM/DISPLAY 必须吸收本稿列出的差异后重新组合评审。没有生成 RTL、功能脚本、可执行测试或 testbench。

## 通用计划字段

- Goal：以真实 V4 四键控制阈值、显示/算法组合、中值和原源帧冻结/恢复；命令、采用、显示和复位具有可观察而有界的交接。
- Current state：原工程只接 KEY1，并直接复位多个 PLL/CSI/LCD；已有 FM 配置/冻结语义和 DISPLAY render112/实际快照，但最终父端口和恢复阶段未闭合。
- Target state：普通按键不复位视频；处理快照在帧/任务边界采用，旧任务/屏幕保持一致；复位在 AON25 独立请求，CORE 停钟不堵塞复位发送。
- Gap：本稿八项 CT-B 阻塞；识别 profile、邻接版本吸收、实际 CDC/时序/资源证据仍缺。
- Assumptions：V4 Ti60F225/I3、SC431HAI、1080p60；AON25 来自既有独立25MHz参考。四键/LED是原理图及设备映射候选，未确认实物。
- Open questions：识别参数实体、生命周期父合同、暖会话安全关闭、最终电气与约束；不新增重复审批申请。
- Dependencies：[FM v0.1](design-TRACK4-FRAME-MANAGER-001.md)、[PLATFORM v0.1](design-TRACK4-PLATFORM-001.md)、[CAMERA v0.1](design-TRACK4-CAMERA-001.md)、[DISPLAY v0.1](design-TRACK4-DISPLAY-001.md)、[Canny v0.4](design-TRACK4-CANNY-001.md)、[RECOGNITION v0.1](design-TRACK4-RECOGNITION-001.md)、[FRONTEND v1](design-TRACK4-FRONTEND-001.md)。
- Milestones：CT0来源→CT1整体及交接→CT2局部草图→CT3联合吸收/闭合→READY及指定批准→CT4实现/仿真→CT5整机综合/PNR/STA。
- Detailed steps：先B/C读外部行为，再D对照消息和父差异，E读旧状态操作，F/G/H读语言、验证与追踪；[操作阅读附件](../experiments/track4_full_sw_20261004/04_local-designs/control-human-operation-sketches-v0.1.md)展开人工/波形路径。
- State transitions：本稿仍 LOCAL_DESIGN，不能用完整章节替代无阻塞或指定实现批准；不写正式 PROJECT_STATE/数据库。
- Artifacts and hashes：本稿、[键/复位来源](../experiments/track4_full_sw_20261004/01_baseline/control-keys-and-reset-evidence-v1.md)、中文附件、[读稿评审](../experiments/track4_full_sw_20261004/05_reviews/control-review-v0.1.md)；实际读回 SHA 见本轮 document-checks.json，源码尚不存在。
- Validation：CT-T01…24文字场景全部 NOT_RUN；文档检查仅检查文档，不证明按键/算法/CDC/时序。
- Failure handling：容量满丢完整未接受手势并记录；已接受命令/held body不能覆盖；非法完整配置拒绝；未知排空进入隔离，不强制成功。
- Human approval gates：设计文档处于当前授权；无正确性阻塞且 READY 后再请求指定版本/范围/基线批准；既有 FE/模型申请保持原状态。
- Rollback：保留旧冻结稿，必要时只撤本稿和新附件/索引差异；不改原 HDK、工具、正式状态。
- Completion criteria：四键、快照、冻结源重处理、恢复、AON复位及父接口真实验证；之后全十一项整机交付，本稿完成不等于目标完成。

## A. 状态、基线与阻塞

任务 CT=TRACK4-CONTROL-001，关联 T4-A2/A3/A5/A6、T4-B3/B4、UC-05、DER-03及MOD-04/12。v0.1是待组合的候选，实施路径仅计划为独立 work 副本中的 control/；当前路径不存在、实现批准为空。用户要求继续完成软件实验，不能解释成批准这份新局部版本。

真实只读基线：FM SHA D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA；PL 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0；CAM F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C；DP 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717；FE 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114。原理图 SHA 855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F，v6归档 SHA 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C。无 Git commit 可供声称。其他父基线沿用主计划和本轮审计真实 SHA。

| BLOCKING | 问题/影响 | 关闭方法与可独立继续部分 |
|---|---|---|
| CT-B01 | PL仍将KEY1作为raw逻辑复位；四键/两LED及reset_seq唯一owner未吸收，影响CT01/06、IF01/06 | 根与平台共同形成新PL候选、唯一pin owner及约束报告；现可读来源/手势分析 |
| CT-B02 | FM最终完整配置、cfggen/来源关联/有界替代、CT父receipt与观察端口未吸收，影响CT02/03/08、IF03/04/07 | FM新版本实现前明确所有字段和记录上界；不增加无界请求历史 |
| CT-B03 | FREEZE_WAIT_FIRST中RESUME须能进入，ABORT/RESUME_PREPARE/COMMIT及业务done谓词仍未联合闭合，影响CT04/05、IF05 | FM/DP联合新版本逐阶段走查；不能让RESUME等待首帧或冻结完成 |
| CT-B04 | RC配置实体/默认/单位/完整job尚RC-B02/B04，影响CT03、IF03 | 识别数值/算法设计闭合，注册不可变profile；本稿不伪造参数或场景边界 |
| CT-B05 | UI CDC关闭与故障时旧会话、独立reset/receipt/done的保持域和计数尚需PL吸收，影响CT06/07、IF02/06 | 定义两端关闭证据和恢复权限；实际停钟/暖复位验证 |
| CT-B06 | 软件观测快照与LED编码、FPGA顶层观测方式/可用端口和引脚最终报告未实现，影响CT08、IF07/08 | 先冻结完整状态读取合同；波形验证与正确封装/电气静态报告 |
| CT-B07 | 25MHz AON进入方式、同步器/稳定多位mailbox例外、CORE时序及准确FF预算未综合/STA，影响CT01/07 | 获批后真实综合、CDC/STA；无新RAM预算不代表全机资源闭合 |
| CT-B08 | 十一项联合端口、DDR真实模型/PHY校准、完整质量/吞吐和bit/hex依赖仍未验收 | 使用既有05阻塞和申请，依赖闭合后分批实现，不降验收要求 |

## B. 整体外部行为

### B1. 八项要求及非法输入

| REQ | 外部可观察行为、来源与边界 |
|---|---|
| CT01 | T4-A2：四GPIO低有效，启动/暖恢复须先连续稳定释放；20ms消抖、短/长互斥、无自动重复。普通操作不产生PLL/相机reset |
| CT02 | T4-B3/A2：Sobel T与Canny TL/TH独立保存。完整快照帧/任务级采用，配置与job同沿，job用旧快照；UI饱和与结构化非法输入拒绝分开 |
| CT03 | T4-A1/A4/A5/A6/B4：八个明示组合覆盖Sobel/Canny/识别及视图；median独立保存。render112随新完整bundle/APPLIED生效，旧active不直接读新CSR |
| CT04 | UC-05/A3：短KEY1修改期望冻结状态；实际冻结依据显示真实active原SRC及移交完成，不冻结渲染像素。参数变化同原SRC重处理 |
| CT05 | UC-05：恢复为绝对意图并串行关闭旧阶段；等待首源时也可恢复，先结清旧SNAP/ABORT，再恢复LIVE资格。不清仍有BIND/显示引用的源 |
| CT06 | DER-03：长KEY1在AON独立发优雅全业务复位；CORE停钟仍可送达SUPERVISOR。receipt非done，故障不伪称排空/FREE |
| CT07 | 派生工程要求：有限槽、CDC、单次序号、不可覆盖held、溢出可观察；忙不暂停消抖。事务/会话耗尽禁止新动作，旧收尾继续 |
| CT08 | 用户人工观察要求：分别读desired、committed、job/SOF采用、实际APPLIED和冻结实际状态。LED只表达限定状态；未采用/未显示不报成功 |

### B2. 四键与八个候选preset

原理图四键均10K上拉3.3V、按下接地；本稿选KEY0=C4、KEY1=P13、KEY2=N13、KEY3=A3，最终约束须经CT-B01。KEY0和KEY2在一次合格按下—释放周期的释放时分别+16/-16；按住任意久只一次，不自动重复。KEY3合格按住不足800ms释放时NEXT；达到800ms只一次MEDIAN_TOGGLE，随后释放不产生NEXT。KEY1不足2000ms释放时FREEZE_INTENT_TOGGLE；达到2000ms只一次AON_RESET，随后释放不冻结。到长按边界同时UP归LONG；持续低电平不能重复产生事件。没有双击菜单。

| preset | algorithm2 | render.mode3 | 含义/允许的图 |
|---|---:|---:|---|
| 0 | 0 | 0 | Sobel，上原灰度/下边缘对比 |
| 1 | 0 | 4 | Sobel原RGB彩边叠加 |
| 2 | 1 | 0 | Canny，上原灰度/下完整边缘 |
| 3 | 1 | 4 | Canny原RGB彩边叠加 |
| 4 | 2 | 5 | Canny＋圆/旋转矩形识别标注；必须有合法profile |
| 5 | 0 | 1 | 原RGB；仍在同一完整job/bundle合同中 |
| 6 | 0 | 2 | 原灰度显示；灰度不等于median后的Y |
| 7 | 0 | 3 | Sobel全屏边缘 |

algorithm0=SOBEL、1=CANNY、2=CANNY_RC、3非法；median所有preset独立保留，默认0。NEXT使用独立ui_preset_cursor3/valid1记录最近尝试，初始化cursor=0/valid1，从7回0；preset4不可用时明确REJECTED/PROFILE_NOT_INSTALLED，D/C不变但本地cursor推进到4，下一次NEXT可尝试5，不能永远卡在3。结构化SET成功后按algorithm/mode匹配本表设置cursor；无匹配则valid0，下一NEXT尝试0。该明确本地副作用不表示配置接受或显示切换。preset变更一次提交完整algo+render，其它独立参数保留。UI不是限制结构化完整SET_CONFIG的全部合法组合；完整入口允许mode0…5，mode5要求algorithm2，mode6仅DP本地诊断，7非法。无识别时不读ANN；DP所需mask沿其D1，SRC身份/授权始终存在。

候选上电TS=256、TL=128、TH=256、preset0、median0、desired_freeze=0，属于实现前可评审选择，不是传感器或赛题官方数值。RGB edge=FF0000；ANN三颜色00FF00/00A0FF/FFFF00；split_y=540。show_edge=1，show_ann由algorithm2决定。所有默认先做完整校验；RC未安装时profile_ref=0，仅允许非RC组合。首次真实源和结果完成之前仍显示DP安全图，不拿默认参数当已显示证据。

在Sobel preset，±只改TS；在Canny及RC preset，±饱和修改TH并设置TL=floor(新TH/2)，这是单个旋钮的UI选择；完整SET_CONFIG允许TL与TH独立值。Sobel与Canny幅值阶段不同，切模式不复制TS到TL/TH。TS/TL/TH均unsigned11、0…2047；外部TL>TH拒绝，不交换。Sobel严格M>T，真实最大1530不修改合法配置上限。Canny严格Mnms>TH强、TL<Mnms≤TH弱，其余NONE，完整八邻域闭包继续保留。

### B3. 使用样例与有界副作用

正常N1：当前Sobel configA已显示→短KEY0→UI接受desired B→父提交B→下一job用B（同沿旧job仍A）→源/EDGE成功/fence合取→DP OFFER及真实APPLIED→观测active B。配置接受到屏幕变化不是固定1帧延迟。

边界N2：长KEY3与短KEY0同tick，按本稿event_seq顺序KEY3先、KEY0后；先median变更后TS加16，父可能只提出最新完整快照。任一已held父proposal不能改。端点满时整次手势丢失有记录，不执行一半配置。

冻结N3：KEY1短按→desired_freeze=1→FM SNAP真实active→源FREEZE引用建立→COMMIT业务完成→actual_freeze=FROZEN；后续阈值仅重算此SourceOrigin。恢复期间屏幕可重复旧合法active，直到新完整候选应用。

失败N4：没有active和源，FREEZE进入WAIT_FIRST→再次KEY1短按变为RESUME→父接纳恢复意图→先旧ABORT结清，再RESUME_PREPARE/COMMIT→LIVE等待后续真实SOF；绝不等待不存在的首源才允许恢复。CORE停钟时长KEY1只经AON/PL独立reset通道，不能保证CORE自行排空，无法证明则QUARANTINED。

## C. 职责、连接及整体检查点

普通Markdown控制路径：
KEY[3:0] → IF01 KEY_FRONT/AON → IF02 UI_TRANSPORT → DESIRED/CORE → IF03 CONFIG_ADAPTER → FM authoritative committed/SOF/job → FE/Canny/RC → JOIN → DISPLAY。
生命周期：DESIRED.absolute_freeze → IF05 FM → DP SNAP/COMMIT或ABORT/RESUME → FM实际引用/状态 → IF07观察。
复位：KEY1 LONG → IF06 AON_RESET_OWNER → PL SUPERVISOR；不经CORE mailbox。状态：FM/PL/DP真实证据 → IF07 atomic observation → IF08两LED候选。

| MOD | REQ、职责及状态owner | 不负责/划界理由 |
|---|---|---|
| CT-KEY（MOD-12） | CT01/06/07；AON两级同步、消抖/资格、手势、四本地槽/总seq；复位独立槽 | 不分配业务config_id，不直接clear PLL/RAM |
| CT-CDC（MOD-12） | CT07；单UI mailbox及独立reset/receipt/done运输、会话关闭 | 运输ACK不表示业务完成；无图像借用 |
| CT-DESIRED（MOD-12） | CT02/03/04/05；完整desired D、最新来源、冻结期望、原子UI校验 | 不覆写FM committed或任务/active快照 |
| CT-FM-ADAPTER（MOD-04边界） | CT02…05；不可变proposal P、版本条件/receipt、pending生命周期关联 | FM唯一分配cfggen/config_id/policy/rendergen及源/结果引用 |
| CT-OBS（MOD-12） | CT08；复制真实committed/采用/APPLIED/actual_freeze、LED状态 | 不根据按键或运输ACK推测图像完成 |

自写模块仅计划，复用既有PL-IF03和DP完整消息语义；旧按键直连reset不能复用为新控制。没有新增DMA/图像路径、RAM/DSP/PLL。拟以FF保存小量配置及mailbox，准确总FF与父保持记录在CT-B02/07；全机174 RAM预算不因本稿增加，但不是综合利用率。

分支独立：UI stalled不能阻塞长按reset；reset receipt/done互不占用UI响应槽；观察快照可以合并尚未提出的最新值，已经提出body保持。汇合只在FM登记真实事件，不能由多个owner各自修改FREEZE或cfggen。四key槽→一个mailbox按旧event_seq最小值选择，不以固定按键优先长期饿死某键。

整体检查点：B/C已经给出可见行为、职责和数据/控制边界；进入D/E是候选细化。新四键与AON复位及参数层次有来源支持，父端口/生命周期/RC profile仍阻塞，当前没有READY或业务实现授权。

## D. 八个接口与组合检查

### D1. 字段与公共规则

所有消息除异步GPIO/LED外为valid/ready：fire=沿前valid&&ready；valid提出后body直到fire不变。运输ACK只移交私有槽所有权；业务receipt/done另算。消息接收须预留独立回复槽，不以同沿新腾容量作默认穿透。无valid时body无意义。所有整数unsigned，字段顺序如下文从高到低，拼接算术为设计分析，未建立生产packed端口。

CFG212候选=algorithm2/median1/TS11/TL11/TH11/render112/rc_profile_ref64，合36+112+64。profile_ref引用已安装完整不可变RC参数，不代表参数实体已闭合；RC-B02仍阻塞。algorithm非2时profile_ref规范为0；algorithm2要求非0且已安装、在job/结果生命周期内不可回收。retain_grad和recognition_enable由algorithm==2唯一派生，不另存可冲突副本。Canny发送FE Y_ONLY/threshold0，同median；普通Sobel发送SOBEL/TS。FE原FJ110和Canny job917不被本稿默扩。

SOURCE_UI134=source_valid1/UI133；非UI来源source_valid0及UI133全0，不能用任意seq冒充来源。COMMITTED570=cfg_generation64/config_id32/policy64/render_generation64/CFG212/SOURCE_UI134，合436+134。FM唯一分配，cfggen64不能截低32冒充config_id；camera cfggen是SourceOrigin关联的独立源身份。rendergen只在render112改变时推进；参数不同但render相同时保持旧rendergen，业务cfggen仍推进。algorithm切换同时推进policy，普通阈值/median/render不推进policy；冻结/恢复策略遵FM生命周期，真实SourceOrigin不改。序号/代次递增先扩1bit检查，禁止回绕；旧收尾token须已有预留，不在耗尽后申请。

| IF | 提供方→使用方、类型/范围/身份 | 接受、保存/流控、失效与约束 |
|---|---|---|
| CT-IF01 | GPIO→CT-KEY；raw_key4低有效、AON25、PL受控资格 | 每位两级FF，消抖只读旧第二级；不能逐位同步配置总线。先WAIT_RELEASE，按住启动无动作；core reset不异步抹AON计时或held reset |
| CT-IF02 | CT-KEY↔CT-DESIRED；UI133=epoch32/link_session32/event_seq64/op3/key2；回复274=原body/status2/error5/superseded_before_proposal1/superseded_UI133 | op0INC/1DEC/2NEXT/3MEDIAN/4FREEZE_INTENT，5…7非法；key合法对应0/2/3/3/1。四键本地depth1槽加单heldmailbox，按seq有序；接收保存及完整校验后回业务回复，不能凭运输ACK报配置采用 |
| CT-IF03 | ADAPTER↔FM；PROPOSE605=epoch32/session32/proposal_seq64/expected_cfggen64/expected_policy64/op3/CFG212/SOURCE_UI134；receipt1182=原605/status2/error5/COMMITTED570 | op0SET/1FREEZE/2RESUME/3REPROCESS/4QUERY，5…7非法；非SET的CFG212全0。SET成功receipt0COMMITTED；生命周期0ACCEPTED；1ALREADY/2BUSY/3REJECTED。一个P不可变；BUSY未登记成功，重试同body/seq；错body拒绝 |
| CT-IF04 | FM→FE/Canny/RC/DP；已冻结FJ110/job917/OFFER1963和完整配置关联 | SOF预留/LIVE或DDR job时锁整快照；同沿新CFG不改变旧job。SourceOrigin/camera cfggen、业务cfggen/config_id、rendergen和policy分开，RC完整实体/关联端口仍CT-B02/04 |
| CT-IF05 | CONTROL absolute intent↔FM；FREEZE/RESUME借IF03身份；生命周期done938=原605/status2/error5/actual_freeze2/origin_valid1/SourceOrigin195/effective_policy64/effective_cfggen64 | done0APPLIED/1ABORTED/2FAILED/3QUARANTINED；actual0LIVE/1PENDING/2FROZEN/3Q；无origin时195位全0。accept非完成。容量为一个已启动T、一个已接受的反向RESUME记录R和一个本地尚未提出的最新绝对意图；R保存完整605身份及预留的receipt/done，接纳ready不依赖旧T完成，RESUME能关闭WAIT_FIRST；DP阶段消息沿既有227/422/291等，最终联合谓词CT-B03 |
| CT-IF06 | CT-KEY/AON↔PL；原reset_request117及独立receipt123/done123 | kind1优雅全业务、expected_epoch32真实、mask/reason按新PL版本冻结；AON唯一reset_seq owner，不能并存另一CORE分配者。专用held槽与独立回复，不走UI。mask具体bit及采样资格CT-B01/05，不能把CTRL收到long当reset完成 |
| CT-IF07 | FM/PL→CT-OBS；原committed570、真实SOF/J与SourceOrigin、APPLIED1503/ID687、actual_freeze、错误/丢失计数的原子观察候选 | CFG使用事件来自真实接受；APPLIED沿原DP完整身份核验后更新。只存当前/有界任务/最近实际状态，无逐命令无限等待表；完整读取字段/快照接口尚CT-B02/06，不声称已冻结packed宽度 |
| CT-IF08 | CT-OBS→LED0/LED1及未来波形审阅 | 仅N14/P14高有效；LED0有合格运行资格亮，LED1优先错误闪4Hz、控制pending闪2Hz、实际FROZEN常亮、其余灭。频率是AON tick enable产生，不创建slow clock；状态跨域完整握手。阈值/模式精确值通过IF07读取，LED不承诺数值显示 |

UI回复status0ACCEPTED_DESIRED/1NO_CHANGE/2BUSY/3REJECTED；error5候选0NONE/1BAD_FIELD/2PROFILE_NOT_INSTALLED/3VERSION/4SEQ_BODY/5EXHAUSTED/6SESSION/7LIFECYCLE/8FAULT/9CAPACITY，10…31保留非法。UI槽满属于未接受手势丢弃，由AONoverflow_sticky和饱和drop_count32记录，不伪造ACCEPTED。SOURCE/图像错误仍沿原模块返回，不重编码成一个按键错误。

独立结构化SET_CONFIG入口的payload/来源/回复容量属于CT-B02待冻结合同，不由UI133承载CFG212。本文T10等是此待冻结入口的验证场景，当前不存在可执行CSR/软件端口，不能把文档字段当实现。

去重为(epoch,session,proposal_seq,op,body)的完整关系。同seq同op不同body拒绝；当前P或最后完成单条缓存可回原receipt；更早未知seq明确OLD/REJECTED，不拿最新body答旧请求。BUSY不写入最后完成缓存，原body重试会重新检查容量；proposal_seq跨op唯一，同seq改op也拒绝，不能套用DP续阶段共seq例外。ACCEPTED生命周期的业务done须原身份回显。T结束后不得允许迟到COMMIT重建冻结；FM/DP去重/父记录容量须CT-B02/03吸收。

### D2. 有界D/P/C/T与迟到观察

D为最新UI期望CFG及来源event_seq；P为已经提出/待receipt的不可变整快照；C为FM committed570；T为已经启动的生命周期上下文，R为至多一个已经接纳、用于中断WAIT_FIRST的反向RESUME完整605记录；R不能覆盖，旧T与R各自预留独立done938。另有最多一个本地未提出absolute intent，只有此本地意图可合并。D的新接受可以替代尚未进入P的旧D；D保存其来源是否已锁入P，P结账后也不把同一旧D重新标为未提出；同沿P锁存旧D且新UI写新D时，替代判定使用“旧已锁标志或本沿P锁存该D”的合并判定，superseded_before_proposal=0且superseded_UI133全0，不能只读旧标志误报取消；成功UI回复274的superseded字段注明被替代来源；旧D只有尚未锁入P时才标1，标0时superseded_UI133全0，不承诺每个D都产生job/APPLIED。P不能因D更新改body；P结清后只提交最新D。SET事务以COMMITTED receipt结账；实际采用/屏幕是状态观察，不为每次SET开永不完结的等待项。

已用于SOF/job的配置保存在原FM有界源/任务/三结果上下文，与结果/显示引用同生命周期。当前C更新不能修改这些旧记录。观察显示某旧cfg仅说明仍显示那份完整结果，不把旧APPLIED回写C或D；任务失败不会使当前期望参数回滚。未被采用的替代只针对未proposed D，已committed但未job采用可从下一job实录辨认，无需承诺每个旧代次的APPLIED。

FREEZE_INTENT事件在CORE按seq消费、基于旧desired_freeze取反，随即保存为绝对目标；不在迟到执行时读取actual_freeze再toggle。已发T按阶段兑现，后来的RESUME可用R独立容量接纳，ready不等旧T完成；先使旧T生成并交付ABORTED done，旧T已held终态不可覆盖，后移交R为新T完成恢复。R已接受即有独立终态义务，更晚本地目标只能等待/合并，不能覆盖R。未提出多个意图可合并到最后值；已经held/已接受消息不能删除。RESUME专门容量不能被“等待首源的FREEZE完成”锁住，CT-B03关闭之前不能READY。

### D3. 父合同必要差异

1. PLATFORM新版本将KEY0…3 raw唯一owner改CT-KEY/AON，KEY1不再直接i_arstn；CT长按只发PL117。CRESET_N/J5是单独配置复位，不能替代优雅业务reset。
2. FM新版本吸收CFG212/committed570、来源关联、D/P界线、render-only也走新完整job/bundle、有界绝对生命周期意图及恢复可抢占WAIT_FIRST；保留同沿旧快照。
3. DP控制gate/policy版本须表示当前控制资格，旧active的full_scope/J.policy历史身份保持。新policy下允许重复历史合法active等待新候选，不能覆写J或撤旧RO；不能要求PLAN所有历史J.policy都等于当前gate版本。
4. CAMERA不因阈值/median/render更新重配或STOP；冻结不停止mandatory采集。旧camera cfggen保留到源真正FREE，不能用新的业务cfggen覆盖。
5. RC profile_ref仅引用，不能绕过实体数值/单位/默认/完整job闭合；原95%及独立数据验收仍保留，不恢复撤回的目标尺寸/噪声限制。

正常走查：IF01→02旧槽/seq→DESIRED校验→IF03 P/receipt→IF04真实job旧状态→JOIN→DP OFFER/APPLIED→IF07→08。失败走查：IF03旧P等待时D继续合并→slot满新手势整条drop→RESET另由IF06→PL禁止新授权但兑现旧scope/held→不确定Q→done不宣称FREE；IF02会话关闭另判，不与图像排空互证。

## E. 局部状态、不变量与中文操作草图

### E1. 数据、初值与十个不变量

AON保存key_sync两级×4、1ms divider15、每键stable/candidate/age5/armed、KEY1 hold11及KEY3 hold10、四UI133槽valid、一个正在运输133及回复274保持、总event_seq64、reset117/receipt/done各独立保持、drop_count32/overflow。CORE保存D/P/C的值副本与来源、D来源已锁入P/dirty/拒绝标志、ui_preset_cursor3/valid1、desired_freeze、pending intent/T/R关联及各自独立终态容量、观察状态；这些不持有图像读写租约，FM拥有真实FREEZE/BIND。初始槽空、armed=0、stable=高、unknown观察无效；原始RAM/图像不清零来证明空。

| INV | 不变量及建立/保持理由 |
|---|---|
| CT-I01 | raw仅同步入口，普通事件不能同时作用PLL reset；唯一pin/seq owner |
| CT-I02 | 未完成稳定释放资格不产生任何short/long，启动低电平不会触发reset |
| CT-I03 | 同手势最多一种事件；LONG之后UP被吞，持续低电平不重复 |
| CT-I04 | 四key槽/mailbox/receipt held不覆盖；满只丢未接受整条手势，忙仍继续检测release |
| CT-I05 | D可合并、P不可变、C唯一FM writer、旧SOF/job/active快照不改 |
| CT-I06 | TS/TL/TH阶段分开、TL≤TH，RC启用必有不可变有效profile及retain_grad |
| CT-I07 | ACCEPTED_DESIRED/COMMITTED/USED/APPLIED/actual freeze不同证据，不相互冒充 |
| CT-I08 | 原SourceOrigin冻结，引用移交完成前pending；恢复不清其它BIND或历史active |
| CT-I09 | UI停顿/CORE停钟不挡AON独立reset；receipt/done容量分开，seq不回绕 |
| CT-I10 | 暖恢复不得单端清旧mailbox/held承诺；错会话/代次不改变他人状态，不确定保持Q |

### E2. 八项操作草图

**CT-OP01 同步、消抖与起始资格。** 每AON正沿仅读旧第二级；1ms enable由25,000周期divider产生，禁止把enable当新clock。每tick若同步样本等于旧stable，取消相反candidate/age；否则首次异样本保存candidate且age=0，后续同candidate每间隔1ms age加1，到20时提交stable，产生注册DOWN/UP给下一沿手势机。因此为21个相同样本、20个完整tick间隔，不能把20样本说成至少20ms。任一反向样本打断；这是采样级消抖，不声称对tick之间全部模拟弹跳连续监测。WAIT_RELEASE同样观察21个高样本/20间隔才armed；旧armed=0的该沿即使提交资格也不接DOWN，下一沿才允许新手势。

**CT-OP02 手势与并发分配。** 合格DOWN建立press_active，hold_elapsed=0，后续tick累计经过间隔。KEY0/2合格UP只形成一次±；KEY3达到800或边界UP形成MEDIAN；KEY1达到2000或边界UP形成RESET。长事件后进入LONG_WAIT_RELEASE，UP只结束状态。事件形成与本地槽写入使用旧valid：旧full即使同沿发送/pop也丢本事件并计数。一个tick只给实际可保存的UI op0…4按KEY1、KEY3、KEY0、KEY2分配连续event_seq；之后按seq最小值发送，固定顺序仅用于同tick仲裁。KEY1 LONG不占UI槽也不申请UI event_seq，只使用独立reset_seq；UI序号耗尽不得挡仍有资格的reset请求。耗尽前65bit预查本tick可保存UI事件所需数量；无法分配则整批拒新UI并记录EXHAUSTED，已held及reset收尾继续，不能部分发后回绕。

**CT-OP03 UI运输和回复。** 从旧四槽选最小seq，在单UI发送槽空时复制完整UI133、再提valid/toggle；不把新入槽当同沿可发送。发送body直到运输交付保持；原选中key槽作为借用保留，收到匹配业务回复274及运输收尾后才清，不能transport ACK后立即复用或重新发送同一事件。接收私有槽无容量不ACK。CORE接收时校epoch/session/op/key组合并预留回复274；重复当前事务回相同结果，错body拒绝。业务回复交付后才记此手势已结；mailbox本身只证明transport。暖故障停止新检测动作的资格，维持release检测，旧会话依PL授权关闭；无图像借用不意味着可以擅自单端清toggle。

**CT-OP04 原子期望配置。** CORE消费INC/DEC/NEXT/MEDIAN，以旧D复制完整candidate，扩12bit做TS/TH±16并饱和，Canny的TL由新TH整除2；比较整个规范化candidate CFG212；仅全字段不变才NO_CHANGE不推进代次。例如TH=2047/TL=1再加，TH不变但TL变1023，仍是新配置。NEXT先记录尝试cursor再按表组合，median及独立阈值/颜色保留、show按B2规范化；RC profile无资格回REJECTED且D/C不变，cursor已明确推进，下一次可继续。未来结构化SET入口输入逐字段校验，不给非法TL>TH自动修正。校验成功同沿提交D和来源，再形成ACCEPTED_DESIRED；已held P不改。KEY1普通事件只切desired_freeze/最新绝对意图，不改CFG212或active。

**CT-OP05 父提交、配置采用和实际屏幕。** P空且独立receipt容量、FM旧C版本可用时，从旧D形成P605和expected版本，并标此D来源已锁入P；同沿新UI输入只写新D，不混入P。当前D版本被拒绝时记拒绝状态，不无条件无限重发；后续新D仍可推进。提出后不随后续D变化。FM fire先登记真实旧job/SOF握手，再原子校验/分配并保存新C；同沿任务用旧完整快照。receipt1182返回真实C而非本地推算值；BUSY保留P原body重试，VERSION拒绝先获取新C后才重建P；静态字段/profile拒绝记此D版本失败，等待新D或明确资格改变，不因D不同于C无限自动重提。不能改held旧P。P结账后最新D不同才再提出。参数/颜色变化不取消所有旧任务；algorithm切换走policy屏障，旧同沿job登记后在后续ACTIVE合法取消。结果/DP实际APPLIED后IF07更新，旧active仍完整重复。

**CT-OP06 冻结、恢复与等待首源。** desired冻结≠actual；FM以独立T接纳绝对命令并保存expected/current新policy。FREEZE SNAP选择请求可见后VSYNC前旧真实active并hold；FM先建立原SRC FREEZE再COMMIT，业务done完成才actual FROZEN。NO_ACTIVE可待首完整SRC，保存pending但不凭空设origin_valid。期间RESUME接纳到独立R605容量，ready不依赖旧FREEZE done，预留R的receipt1182/done938及旧T的独立done938；先终结旧T，再把R移入新T，不覆盖或共用未预留终态槽：禁止新冻结候选，结清已heldSNAP及ABORT旧事务/hold，再RESUME_PREPARE/COMMIT；完成才LIVE，采集等待后续SOF。已产生的源/结果/fence/RO不以恢复命令清除。精确FM/DP done和取消资格待CT-B03，不在本稿伪装已闭合。

**CT-OP07 独立AON复位与故障。** KEY1 long只向独立PL117槽申请kind1；若旧reset未结，重复意图记ALREADY/BUSY并继续release，不覆盖body或另清PLL。AON统一reset_seq，receipt123和done123各有独立槽；CORE或UI未回复不能成为发送前提。SUPERVISOR按既有优雅排空/故障恢复处理，真实done才更新观测；等待过久报PROOF_PENDING，不能清在途地址/镜像。暖恢复依旧PL PREPARE/FINAL和会话关闭认证，重新armed要稳定释放；一直按住不会立刻再reset。

**CT-OP08 观察、LED与收尾。** 把FM真实C、任务采用和DP完整APPLIED身份保存为各自最近观察，空/无结果保持valid=0；迟到旧APPLIED不回写D/C。live观察和held读响应各一份；atomic read复制当时live并锁定held直到响应消费，live仍更新，未提出telemetry可合并。UI慢读不得反压FM→DISPLAY的APPLIED业务ACK、RETIRE、fence或返租约链；held观察响应不变。AON从完整状态mailbox得到资格、pending、actual_freeze和错误；按IF08明确优先级译LED。不用两LED宣称具体阈值或识别95%。停止新动作时继续接旧receipt/done与release；seq耗尽仍有已预留收尾身份。IF07最终字段/运输CT-B06，当前只写观察草图。

### E3. 边沿次序与反馈复核

每沿先用旧状态判fire/容量/快照，再登记实际传输和失败，再计算各owner下一状态，最后一次提交。输入同步FF、消抖UP注册、手势入槽、mailbox、CORE译码、P形成分别隔至少一所属域边沿，不用软件叙述假定同沿穿透。尚未提出D可合并；已heldP/PL reset/DP阶段必须兑现。暖reset不能先清T再等待别人done。上述发现反向反馈D3，需要相邻新版本，不修改当前冻结父文档。

## F. 语言与跨语言契约

RTL/SV2009候选，Efinity2026.1.132/Questa2024.1按现有证据；尚未编译。无C++实际控制软件或参考，C++所有权/RAII/异常不适用；未来采用Python事件参考须另获批，数值相同不能证明CDC/模拟电气。

| 项目 | 契约/未知 |
|---|---|
| A 数值 | D1全部unsigned，UI133/reply274/SOURCE_UI134/CFG212/COMMITTED570/PROPOSE605/receipt1182/done938；阈值先12bit、seq65、cfggen65/id33检查；UI饱和不回绕；profile参数未知CT-B04 |
| B 时钟/观察 | AON25/core100分域posedge；读旧sync/旧容量，提交后稳定；TB未来NBA后采样，clock比例和相位多组验证 |
| C 接受/交付 | raw不可反压；UI/FM/PL消息valid&&ready；transport ACK、UI接受、FM committed、生命周期done、APPLIED分开 |
| D valid/推进 | 无事件不改D/T；press释放/计时不因下游busy停止；invalid观察不是零阈值或空成功 |
| E 反压/保持 | per-key槽/发送槽/P/receipt/done保持；满drop整条未接受手势；忙不能改body或终止长按reset |
| F 延迟/吞吐 | 1ms采样、20完整interval消抖、800/2000长阈值；跨域往返/配置显示无固定帧延迟；没有auto repeat或按键吞吐承诺 |
| G 复位 | raw KEY1不直接reset；PL统一async assert/sync release与保持域；WAIT_RELEASE防启动按住，旧会话关闭再清 |
| H 配置 | D/P/C及SOF/job/active分开，完整原子更新；同沿job旧值；camera cfggen独立；生命周期屏障与历史active分开 |
| I 存储 | 四UI槽+单transport/P/receipt、一个T+反向RESUME R+最新未提出意图，有界；无新图像RAM；全机/精确FF尚CT-B02/07 |
| J 身份 | epoch/session/event/proposal/reset序号不同；cfggen64/config_id32/rendergen64/camera cfggen64不互替；SourceOrigin/完整APPLIED核验 |
| K CDC | key单bit两级FF；完整body保持型mailbox，两端session闭合；reset为AON同域独立通道，不能逐位sync212bit |
| L 实现 | 既有25/100MHz，无第五PLL、无新业务DSP/RAM；最终四键/两LED电压、pin唯一性/同步器约束/资源/STA未运行 |

共同参考合同：离散采样/旧状态事件/序号/完整配置/结果身份，不模拟亚稳态；硬件执行合同：sync、tick、valid/ready、容量、停钟和暖保持；软件↔硬件比较：按(epoch/session/seq)及真实fire逐项比配置、结果与拒绝，观察LED/完成不能代替采用/APPLIED。这三份契约角色分别保留。

约束候选：KEY仅到首级同步FF为异步输入；只为已识别同步器/稳定mailbox建立有依据例外，多位数据保持时间与同步往返须验证。不能把全部CTRL跨域路径false_path以隐藏错误；1ms为clock enable、不声明为新generated clock。具体SDC与真实时钟/引脚报告待联合新PL范围。

## G. 实施与验证计划（未执行）

实施次序：CT-B01/02/03/04/05/06闭合并修订父合同→全部文本/身份/容量复审→READY/指定批准→work中key_front、ui_transport、desired_config、fm_control_adapter、control_observer及独立参考→局部与父组合仿真→真实综合/CDC/约束/PNR/STA→全十一项回归。上述文件/符号只是计划，不创建。

| TEST | 目标/输入与初始事件 | 期望及方法/通过界限 | 状态 |
|---|---|---|---|
| CT-T01 | CT01/IF01；启动高、低及复位期间按住 | 资格前零动作，21高样本/20间隔才armed；逐AON沿观察 | NOT_RUN |
| CT-T02 | CT01/OP01；交替弹跳、20样本及21样本 | 首异age0、20样本不提前转稳，反样本清候选；采样参考 | NOT_RUN |
| CT-T03 | CT01/OP02；KEY3 799/800ms及边界UP | SHORT与LONG互斥；800归LONG；释放不NEXT | NOT_RUN |
| CT-T04 | CT01/06；KEY1 1999/2000ms及长按一直低 | 2000仅独立reset，release不freeze，无repeat | NOT_RUN |
| CT-T05 | CT01/07；±按住10s、多次短按 | 一次释放一动作、无auto repeat、顺序不变 | NOT_RUN |
| CT-T06 | CT07/IF02；四键同tick产生事件 | 分配确定连续seq，之后最小seq发送，不饿死 | NOT_RUN |
| CT-T07 | CT07/I04；旧槽full且同沿pop | 新完整手势drop/sticky/count，不覆盖旧body | NOT_RUN |
| CT-T08 | CT06/I09；旧KEY1 short槽满、新LONG、CORE停钟 | PL117独立送达，UI反压不挡reset | NOT_RUN |
| CT-T09 | CT02；TS0/2047、TH0/2047、±16 | UI扩12bit饱和、无回绕；TL=新TH/2，无变化不增代次 | NOT_RUN |
| CT-T10 | CT02/I06；外部TL>TH、非法algo/mode/profile | 整包拒绝，D/C不变；不能交换/静默修正 | NOT_RUN |
| CT-T11 | CT02/IF04；SET和job/SOF同沿 | 旧job/SOF锁旧整快照，新值下一可接事务；NBA观察 | NOT_RUN |
| CT-T12 | CT02/I05；P held后D连改10次 | P body不变，未proposed D合并；无无限等待记录 | NOT_RUN |
| CT-T13 | CT03；所有preset/median，preset4无profile | 表匹配；无profile整次拒绝，不自动跳过 | NOT_RUN |
| CT-T14 | CT03/IF04/07；颜色或mode更新、旧active循环 | 新完整bundle/APPLIED前旧画面及render不变 | NOT_RUN |
| CT-T15 | CT04；freeze与新offer同VSYNC | SNAP旧真实active原SRC，引用先增再COMMIT | NOT_RUN |
| CT-T16 | CT04/02；冻结后改阈值/median/算法 | SourceOrigin/camera cfggen不变，新完整结果替换 | NOT_RUN |
| CT-T17 | CT05/IF05；NO_ACTIVE/WAIT_FIRST→RESUME | 能接恢复，不等首源；先ABORT旧SNAP再两阶段恢复 | NOT_RUN |
| CT-T18 | CT05；快速freeze/resume/freeze且阶段held | 未提出可合并，已held兑现；无T覆盖/hold遗失 | NOT_RUN |
| CT-T19 | CT03/05；policy切换后旧active及迟到旧结果 | 历史RO可重复，旧策略新发布禁；不覆写full_scope | NOT_RUN |
| CT-T20 | CT06；reset receipt及时而done迟到/Q | receipt不报完成，scope/held保留，Q不清FREE | NOT_RUN |
| CT-T21 | CT07；mailbox快慢/停钟、单端暖reset | body一致、旧session不重放，认证关闭再重建 | NOT_RUN |
| CT-T22 | CT07；重复seq同/错body、版本错、耗尽 | 幂等或拒绝明确，旧收尾继续，新seq不回绕 | NOT_RUN |
| CT-T23 | CT08；UI接受、C提交、USED、旧/新APPLIED乱到 | 四层观察分开；迟到旧APPLIED不回写C/D | NOT_RUN |
| CT-T24 | CT08/IF08；pending/冻结/错误/clock资格组合 | LED优先规则/频率及完整快照，精确参数从读口读取 | NOT_RUN |

文字正常/边界/失败场景与将来独立事件参考、RTL局部、FM/DP/PL组合互补。无可执行TB、无种子/波形实测。同步电气/MTBF及PHY校准不能由离散参考代替。

## H. 双向追踪

| REQ/来源 | MOD | IF/操作/不变量 | 计划位置/符号 | TEST | 实际代码/证据 |
|---|---|---|---|---|---|
| CT01/T4-A2 | CT-KEY | IF01/02、OP01/02、I01…04 | control/key_front | T01…07 | 未实现/NOT_RUN |
| CT02/T4-B3/A2 | CT-DESIRED/ADAPTER | IF03/04、OP04/05、I05/06 | control/desired_config、fm_control_adapter | T09…12/16 | 未实现/NOT_RUN |
| CT03/A1/A4/A5/A6/B4 | CT-DESIRED/ADAPTER | IF03/04/07、OP04/05、I05…07 | 同上，既有render字段适配 | T10/13/14/19 | 未实现/NOT_RUN |
| CT04/UC-05/A3 | CT-DESIRED/ADAPTER | IF05、OP06、I07/08 | FM冻结父边界 | T15/16/18 | 未实现/NOT_RUN |
| CT05/UC-05 | CT-ADAPTER | IF05、OP06、I08/10 | FM恢复父边界 | T17…19 | 未实现/NOT_RUN |
| CT06/DER-03 | CT-KEY/CDC | IF06、OP07、I09/10 | AON reset owner适配 | T04/08/20 | 未实现/NOT_RUN |
| CT07/派生有限性 | CT-KEY/CDC/ADAPTER | IF02/03/06、OP02/03/07、I04/09/10 | ui_transport、保持槽 | T06…08/12/21/22 | 未实现/NOT_RUN |
| CT08/人工观察 | CT-OBS | IF07/08、OP08、I07 | control_observer/阅读附件 | T23/24 | 未实现/NOT_RUN |

反向：key_front只承担采样/手势，ui_transport只承担稳定交付，desired_config只保存期望与校验，fm_control_adapter将父身份/版本对应，observer保存真实观测；每个计划单元能回到以上REQ，未引入无要求的菜单/OSD/远程软件。代码生成后须补真实符号、SHA/版本和实测，当前不填不存在行号。

## I. 设计门槛、评审与停止点

| 门槛 | 当前证据/缺口 |
|---|---|
| ①整体行为/样例 | B八要求、四键/八preset、四走查 |
| ②职责/连接/复用 | C五职责；PL/DP已有接口和原工程冲突 |
| ③接口/相容 | D八IF及D3差异；FM/PL/RC/观察最终合同仍B |
| ④局部状态/草图 | E十不变量/八OP、独立AON/有界D/P/C/T |
| ⑤语言/映射 | F A–L及三个参考/执行/映射角色 |
| ⑥组合走查 | D正常/失败、B边界；跨父恢复未闭合 |
| ⑦实施/验证/追踪 | G24文字场景、H双向表 |
| ⑧无当前阻塞 | 不满足，CT-B01…08 |
| ⑨保存/读回/呈现 | 以05真实审计和最终呈现记录为准 |
| ⑩版本/范围/基线 | v0.1/LOCAL_DESIGN，A实际SHA；无实现批准 |

**本稿不是READY_FOR_REVIEW，不提出当前版本实现批准。** 下一允许动作是来源/接口闭合与联合新设计；达到READY后再等待用户指定版本、范围和基线批准。审批manifest、数据库及正式状态未写，不声称登记。

## J. 变更与恢复

旧整体只说板载按键/阈值，旧PL把KEY1复位；来源确认四键，故提出四键而非复杂单键菜单。长按reset改AON独立通道、采样21样本明确20interval；普通render也走新完整job/bundle；明确期望/提交/采用/显示及历史policy身份。这些改变尚未进入源码/旧冻结稿，下一联合版本须列范围和重新检查。

恢复先读本稿/来源/中文附件/实际评审以及最新父版本；核对D/P/T界线、参数实体、seq owner、暖会话和批准真实性，不依靠聊天摘要自动继续实现。

## K. 实现与验证实录

只有只读资料、PDF相关完整页和放大核对、文档新增/读回/静态检查。业务源码/功能脚本/可执行测试/TB、编译/仿真、综合/PNR/STA、pin生成及bit/hex全部NOT_RUN；没有执行下载/安装/联网、数据库或正式状态写入。源码引用和资源量均不是运行结果。

## L. 交付及阅读说明

整体入口→B/C外部行为/连接→D八接口与父差异→E中文旧状态草图→F/G/H→中文人工阅读附件→05评审。修改按键去CT01/OP01/02及T01…08；修改阈值去CT02/D1/OP04/05及T09…12；修改冻结恢复去CT04/05/IF05/OP06及T15…19；再同步父稿/测试追踪，而不是直接改active寄存器。

本稿交付的是可读候选控制设计，完整软件、真实资源/时序/质量、bit/hex仍未交付。用户理解验收尚待实际读回/作答，不把解释等同已理解；不据此阻塞当前允许的文档设计。
