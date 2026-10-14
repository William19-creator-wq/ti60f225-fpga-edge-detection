# TRACK4-CAMERA-001 相机接入、完整彩色源与写入关闭设计

- Goal：在完整五项基础、六项高阶的单一1080p工程中，设计SC431HAI配置、不可反压CSI接入、RAW10双像素转色、完整RGB源写入及可选同源FE支路。
- Current state：v0.1，2026-10-04，LOCAL_DESIGN；NOT_APPROVED_FOR_IMPLEMENTATION。现有原工程只读，本任务业务文件、参考程序、testbench均未生成。
- Target state：同一有效源的1920×1080 RGB888按R/G/B字节完整写入已授权DDR对象；身份、配置、坐标及错误闭合后由FM发布；软件仿真/综合/PNR/STA最终证明，而非由本设计替代。
- Gap：真实CSI输出/错误关闭、模组电气/物理复位与phase、DDR匹配模型、相邻父端口、不可反压期限及真实资源仍未闭合。
- Assumptions：软件目标Ti60F225 DemoBoard V4/I3、SC431HAI彩色4lane；生产W1920/H1080；core100MHz、pixel50MHz、CFG5MHz是PLATFORM候选；实际相机fps单独测量。
- Open questions：CAM-B01…08；不把已撤回的识别场景边界重新设为限制，也不放宽完整整机目标。
- Dependencies：唯一v0.2、PLAN_TEMPLATE、主计划v0.10、PLATFORM v0.1、DDR-SERVICE v0.1、FRAME-MANAGER v0.1、FRONTEND v1、原v6归档及SC431HAI资料。
- Milestones：C0来源与整体；C1端口/组合；C2中文局部草图；C3依赖统一/无阻塞/读回；C4指定版本范围批准；C5获批实现和真实验证；C6整机bit/hex后停止。
- Detailed steps：先B/C整体→D交接→E及附件局部→F/G语言及验证→H追踪→I门槛。尚未执行C4…C6。
- State transitions：仅此文档LOCAL_DESIGN；不写正式H/A/R/PROJECT_STATE、数据库或审批Manifest。
- Artifacts and hashes：实际输入哈希见A；本稿及附件最终SHA256由当前文档检查记录，不用自包含哈希。
- Validation：24项文字场景全部NOT_RUN；来源只读、位数/资源算术及设计复审分别记录。
- Failure handling：坏帧整个源无效；独立错误通道；已提出DDR/消息承诺保留；未知排空QUARANTINED。
- Human approval gates：本版有正确性阻塞，不标READY；达到规范§10.3后等待指定设计版本、范围、基线批准。既有联网/模型获取及FE实施申请仍待答，本稿不新造批准。
- Rollback：只有控制面新设计文档；原HDK/归档/工具不修改。后续实施仅获批work副本，不能删除历史证据。
- Completion criteria：本稿完成不是完整实验完成；必须验证全部11项、整机接口/资源/引脚/时序/软件运行/综合/布局及本次bit/hex。

## A. 状态、来源与阅读入口

关联H2、H3输入边界、A3、A5及R0。先读[主计划](design-TRACK4-FULL-SW-001.md)、[整体布局](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)、[系统交接](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)，再读B/C/D整体与组合、E的八项操作及[窗口/writer中文附件](../experiments/track4_full_sw_20261004/04_local-designs/camera-window-and-writer-sketches-v0.1.md)，最后F/G/H/I。

事实来源是原v6、SC431HAI PDF及本地IP公开文档。来源v1保留；新增[CSI/配置证据v2](../experiments/track4_full_sw_20261004/01_baseline/camera-csi-and-config-evidence-v2.md)记录实际wrapper与未证明时序。以下为真实既有输入SHA256，不冒充Git commit：

| 输入 | 版本 / SHA256 |
|---|---|
| 根代码可理解性规范 | v0.2 / 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| 原v6 RAR | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C |
| SC431HAI PDF | V1.1 / E3187CEC241FC1FC53983BA31D27C28E2BDA4341E3C89FDF811CA8ED1FD5F8AE |
| PLATFORM | v0.1 / 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 |
| DDR-SERVICE | v0.1 / 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| FRAME-MANAGER | v0.1 / D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| FRONTEND | v1 / 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 |
| 摄像头来源 | v1 / 8E28330B6CE156012B1E282A5DF11829ECF1027659C3EB44EC316F58054FD0F0 |
| 板卡pin来源 | v2 / 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F |

本稿是基于以上输入的候选变化；它们保持不变。用户要求继续按规则完成完整软件测试，授权只读调查和设计推进；没有对本版新业务实现的指定批准。正式审批/DB健康、硬件人工闸门继续有效。

## B. 整体外部行为

| REQ | 行为与来源 |
|---|---|
| CAM-REQ01 | 配置有明确ID、164条写及公共字段读回证据；从机NACK/AL/超时不当成功。派生于T4-B1稳定采集。 |
| CAM-REQ02 | 只有有效平台/配置/接收会话及预先授予的完整源lease，才在新完整SOF开启源；无lease整帧丢弃并明确记录。派生所有权要求。 |
| CAM-REQ03 | RAW10不先截高8bit；保留精度至双线性插值最后一次舍入，四phase显式，完整W×H含边界。T4-B1/A5与新完整RGB源选择。 |
| CAM-REQ04 | 不可反压输入的有限FIFO、同沿事件、计数、首错和独立故障通道不遗失；满/坏包整个源失败。T4-B1及派生。 |
| CAM-REQ05 | RGB888连续R/G/B字节写入唯一源区域，实际响应/release/phase fence与接收错误closure闭合后才交FM。T4-A3/A5。 |
| CAM-REQ06 | 可选live FE支路恰复制源writer接受的RGB事务，整帧同源；有限队满取消算法，不制造成功缺像素结果。基础吞吐优化提议。 |
| CAM-REQ07 | 配置/取消/暖复位关闭新接纳，旧承诺及会话按完整身份结账；未知排空隔离，不清单端FIFO/held W。派生恢复要求。 |
| CAM-REQ08 | 帧/相机配置代次/SourceOrigin/phase/坐标可追踪，采集fps/overflow/等待单独观测；数值、资源、时序及原语证据分层。T4-B5/R0与派生。 |

范围是MOD-02/03和MOD-05/06/04的交接；不设计新识别算法或HDMI serializer。相机配置会读写外设，但本轮不执行。正常结果不是“彩色看起来对”：要求N=2,073,600个RAW样本、P=1,036,800个RGB pair、L=6,220,800个有效RGB字节及相符的完整身份。丢弃未arm帧是可诊断输入政策；稳定采集验收仍须证明正式工作负载无失败，不能用丢帧政策冒充T4-B1通过。

正常例：配置ID与读回、模式及phase资格成立，提前安装lease并收到像素端ARM保存ACK；下一SOF开始；合法RAW经转色、源writer和接收closure；本地关闭、源写phase fence成功；FM核相同SourceOrigin和源绑定后发布。迟到CRC例：已收足像素且Debayer吐完，但接收器相关错误watermark未闭合；源仍不可发布，后来CRC使整源失败。无lease例：SOF时没有旧状态有效ARM，整帧观察/丢弃；中途出现lease不补接本帧。

## C. 职责与整体连接

| 局部职责 | 承担 / 状态所有者 / 复用边界 |
|---|---|
| CA0 CFG | REQ01/07/08；请求、ROM进度、事务/ACK/读回、cfg_generation、终态及live arm资格；适配真实I²C底层，旧上层不直接复用。 |
| CA1 RX/ARM | REQ02/04/07；原始IP观察→规范事件、ARM、接收closure、错误保持及pixel→core会话；保护IP只依赖已证明公开合同。 |
| CA2 DECODER | REQ02/04/08；规范记录/RAW lane映射、有效数量、行帧计数、odd carry和114bit RAW pair；映射未闭合前不声称可直连IP。 |
| CA3 DEBAYER | REQ03/08；RAW10历史/四phase/reflect101/有限算术；独立新设计，旧8bit/增益/READ_FIRST模块是来源不是新实现。 |
| CA4 SOURCE-WRITER | REQ05/07；两个RGB bank、packer/carry、DDR prepare/req/W/terminal/release、最后水位和局部关闭；不拥有FM源槽。 |
| CA5 LIVE-FORK | REQ06；一个FE绑定、有限复制队列、FJ/FS/取消、同源结果有效性；不阻塞mandatory源writer。 |
| CA6 CAPTURE-LIFECYCLE | REQ02/05/07/08；最多6个capture ctx、local/closure/fence/status/绑定返还；FM拥有source，CA6借用完整lease。 |

整体普通文本路径：

```text
FM/core ─CAM-IF02完整lease→ CA6 ─ARM284→ CA1/pixel50
CA0/CFG5 ←CAM-IF01请求/读回/物理授权→ PLATFORM；CA1观察→CA0
CSI原始端口 ─CAM-IF03→ CA1规范化/独立fault
CA1 ─CAM-IF04 NORM192 asyncFIFO→ CA2/core100
CA2 ─CAM-IF05 RAWPAIR114→ CA3 ─同IF RGB142→ CA4
CA4真实RGB接受 ─CAM-IF07有限同源复制→ CA5 → FE v1
CA4 ─CAM-IF06 CAPTURE client0 RGB_SOURCE region4→ DDR-SERVICE
CA1接收closure + CA3输出关闭 + CA4本地/写fence
    ─CAM-IF08不可变capture status→ CA6/FM → 原彩色源COMPLETE
PLATFORM stop/fault/PREPARE/FINAL覆盖所有旧ctx、CDC与借用
```

数据源只有一个完整RGB量化结果；live与DDR重读共享该结果。CA6先分配ctx，再mirror OPEN提交ACK、安装W grant/open phase，才授ARM；同源FE还需先有独立结果/PROCESS绑定及FJ成功，未准备则本帧仅存源。父关闭与真实返还在后台推进，不等待未来相机EOF、下一配置或下一帧。byte停钟且物理接收器不能证明旧payload消失时走平台隔离，不虚构正常结束。

整体检查点：本稿B/C先呈现整体；D指出相邻差异，E/附件再深入。主要选择是保留原164条配置次序、RAW10单次量化、四色phase/reflect101、两个源bank及有界FE复制。影响当前正确性的未知在CAM-B01…08，不以候选填空代替事实。

## D. 接口、身份和组合检查

### D1. 共用契约与八项接口

所有数值unsigned，除明确说明外无signed字段。core/CFG/pixel的消息都是本域上升沿前valid和ready同时1才fire；提出后直到消费保持整个body。物理CSI没有ready。运输保存ACK、配置业务终态、ARM保存ACK、真实SOF、局部终态、DDR fence、FM发布和最终绑定返还是不同事件。

复用DDR scope_key623、grant241、SourceOrigin195、req266、W152、terminal301、release288/ACK293，不另立简化身份。CAPTURE scope.kind=0、binding_mask只source，非适用J字段按DDR当前kind规范0；源描述符base/L/A各32。SourceOrigin是slot3/gen64/epoch32/frame_id32/capture_sequence64，与处理job/config_id区分。

| IF | 提供方→使用方及完整字段 | 保证、前提、保持和错误 |
|---|---|---|
| CAM-IF01 | core↔CA0/CFG：CFG_REQUEST186=seq64/cfg_generation64/platform_epoch32/op3/device_addr7/profile_id16；receipt192=原body+status2/error4；terminal274见D2。观察392=cfg_request_seq64/observation_seq64/cfg_generation64/epoch32/link_session32/observation_window_seq64/attempt2/W11/H11/DT6/VC2/raw_count22/error_mask16/complete1/receiver_closed1；观察控制260=cfg_request_seq64/cfggen64/epoch32/link32/attempt2/window_seq64/op2、ACK266=原body/status2/error4；物理证明210=physical_seq64/cfggen64/epoch32/link32/attempt2/action2/qual_mask8/status2/error4；实时资格GATE202=control_seq64/cfggen64/epoch32/link32/op2/eligible1/qual_mask7、ACK208=原body/status2/error4 | 配置请求/receipt/terminal、观察控制/ACK与结果、物理授权/证据、资格ENABLE/REVOKE/ACK各用独立depth1 mailbox，不让一种held输出占用其他关闭通道；同向同类至多1未结。不能把cfg terminal的arm_eligible快照当真实source ARM。观察不借源、不写DDR；缺接收closure不能累积成功帧。reset证明是新候选PL端口，尚未吸收。 |
| CAM-IF02 | FM→CA6 CAPTURE_LEASE1048=scope_key623/grant241/RGB_desc96/cfg_generation64/phase2/W11/H11；CA6→pixel ARM284=scopeH68/cfggen64/platform_epoch32/link_session32/arm_seq64/phase2/W11/H11，ACK290=原body/status2/error4 | lease先验证FM有效source写绑定、描述符与grant及phase0。最多6ctx；每次ARM只占一个未消费资格。保存ACK后仍等下一完整SOF，错身份不释放他人的借用。ARM状态不由晚到旧cfg成功重新打开。 |
| CAM-IF03 | CSI→CA1原始观察：pixel_data64/valid1/PPC4、DT6/WC16/short16/VC2/VCX2、HS0/VS0各1、irq1/debug32；CSRaddr6/data32五通道公开握手，无RESP/WSTRB | 字段所在clock/valid/对齐、RAW位序、PPC编码、HS/VS开闭与错误归属未证明；逐位跨域或把所有字段接pixel沿禁止。完整debug32保留，不沿用旧16位截断。 |
| CAM-IF04 | CA1→CA2 NORM192=RAW64/payload_valid1/SOF-SOL-EOL-EOF四flags/PPC4/DT6/VC2/VCX2/WC16/short16/error8/scopeH68/scope_valid1；depth1024 asyncFIFO，整个未清空会话固定link_session32。独立RX_CLOSURE363=seq64/cfggen64/platform_epoch32/link_session32/scopeH68/rx_closed1/error_mask16/raw_count22/fifo_committed_watermark64 | flags可组合；所有flags/payload属于同一scope/行语义，跨旧FE/新FS、旧行EOL/新行SOL，或不能共用一个metadata tuple的事件须适配器按顺序拆记录，不能else优先丢另一事件。metadata由已证明适配器对齐；不从DT变化发明短包valid。scope_valid0只用于未arm观察，scopeH固定0，不进入leased decoder。closure不等待像素队列有空位，且须覆盖所有关联错误。 |
| CAM-IF05 | CA2→CA3 RAWPAIR114=raw20/x_even11/y11/SOF1/EOL1/EOF1/bad1/scopeH68；CA3→CA4 RGB142=rgb48/x_even11/y11/SOF1/EOL1/EOF1/bad1/scopeH68 | 每次恰2lane，raw lane0低10/lane1高10。rgb={R1,G1,B1,R0,G0,B0}，每lane R高8/G中8/B低8。core ready可停顿，所有sideband共同保持。cfg_generation/phase从当前已pin完整ctx快照，scopeH匹配后再解引用。 |
| CAM-IF06 | CA4↔DDR：client0、region4 RGB_SOURCE、W权限、phase0；完整prepare头198/permit68→req266及receipt64；W152、terminal301、release288/ACK293；seal/fence复用DS-IF06 | 16B对齐、1…64拍、不跨4KiB、WSTRB全1；物理A=round_up16(L)。已提出req及借用bank保持；held逻辑W正常不能撤销，仅匹配scope/tag/seq的drained kind1/2 terminal_fire可共同终结未接受逻辑W，旧pending照常capture后DISCARD；物理AW/W/AR承诺不能借此撤销。tag16从记录分配到release ACK消费后才复用。未proposed permit归还独立于fence。 |
| CAM-IF07 | CA6→CA5 LIVE_BIND438=FE job110/PROCESS scopeH68/SourceOrigin195/lease_seq64/enable1；CA4 fire→队列FP74=RGB48/coords22/SOF-EOL-EOF3/bad1；容量512，80bit容器高6固定0；CA5→FE FJ110/FP74/cancel1及原FO/FS | 同时最多1个FE job绑定；身份只在队列ctx固定，不逐项复制。绑定验证完整父PROCESS/结果资格仍CAM-B03。FJ先fire，下一沿才FP；队满不反压源，取消整个FE结果，旧queue/FS结清前不换ctx。 |
| CAM-IF08 | CA6→FM CAPTURE_STATUS808=scope_key623/cfggen64/raw_samples22/rgb_pairs21/writer_bytes32/kind3/error_mask16/first_error_index22/writer_closed1/rx_closed1/local_closed1/success1/drained1；父独立binding_return及ACK沿用完整scope/lease | 成功要求合法数量、phase/配置、闭合接收错误、本地关闭及真实写fence。status不可变；Q的drained0不因后续恢复改写。消费status和借用返还不是同沿自动FREE；新FM端口待统一。 |

NORM192是明确的PLATFORM v0.1 record189变化：互斥type3改成payload_valid1+四flags+scope_valid1，增加3bit。封装200bit高8零，深1024仍20个native RAM10；不是已实现或已验证的CDC。ARM/CFG/closure/mailbox也须下一平台版本吸收；不能凭总位宽宣称原端口相容。

### D2. 配置、错误和状态编码

CFG op3：0 CONFIGURE、1 STOP、2平台授权硬复位、3…7非法。CONFIGURE新cfg_generation64由唯一core发送者递增且不回绕；STOP引用当前代次，内部attempt2=0…2保持同代次。device_addr默认profile候选7'h30，必须冻结SID映射，不自动探测两个地址。receipt status2：0ACCEPTED、1ALREADY、2BUSY、3NO_MATCH；重复seq同body幂等，错body不改记录。error4：0NONE、1BAD_FIELD、2IDENTITY、3PROOF_PENDING、4NACK、5AL、6TIMEOUT、7ID、8READBACK、9RX_MODE、10PHASE、11EXHAUSTED、12PROTOCOL，13…15非法。

CFG terminal274=原请求186、kind2/reason4/attempt2/ID16/ID_valid2/rom_committed_count8/verify_mask14/failed_reg16/failed_phase4/slave_ack_mask4/readback_value8/readback_valid1/bus_drained1/capture_ingress_quiesced1/cfg_verified1/stable_frames2/bayer_verified1/arm_eligible1。kind0 READY快照、1FAILED_DRAINED、2STOPPED_DRAINED、3QUARANTINED；kind0不等待source ARM或DDR lease，避免配置与授源互等。CONFIGURE成功才要求READY的完整配置/模式/phase门；STOP成功为kind2，arm_eligible固定0，不等停流后的观察帧/读回。平台硬复位成功仅证明匹配旧代次入口及总线已关闭，按kind2结束、arm_eligible0，不能冒充新配置READY。实际live arm资格另有可撤销状态，形成terminal后故障不改旧body。

rom count0…164、verify_mask每位对应下述14项、stable_frames0…2饱和。受支持完整重试开始清本attempt的ROM进度、ID valid、readback/verify mask及连续帧证据，terminal只报告最后attempt前缀，不混用上一尝试的成功位。ID high/low各valid；失败定位只在对应valid/phase条件有意义。failed_phase4候选0无、1DEV_W、2SUB_H、3SUB_L、4DATA、5DEV_R、6READ、7STOP、8BUS_IDLE、9ID、10VERIFY、11RESET_PROOF、12RX_OBSERVE，13…15非法；从机ACK mask只记录4个真正从机ACK，不把读结束主机NACK塞入mask。READY须cfg_verified、两连续合法且receiver_closed观察、bayer_verified及平台/link资格；它不是已经ARM完成。FAILED/STOPPED的drained须总线义务及旧入口真正终结，不能用TIP0或stream-off代替。未知总线/接收排空用Q。

实时资格由CA0/CFG→CA6/core→CA1/pixel逐级保存并回同body的业务ACK；op2=0ENABLE/1REVOKE/2CLOSE_SESSION/3非法。eligible仅ENABLE可为1；qual_mask7分别为cfg_verified/mode_observed/bayer_verified/platform_qualified/receiver_healthy/link_prepared/notification_reserved。ENABLE在空ARM或已有ARM仍匹配本代次时更新资格，REVOKE先sticky阻下一SOF并处置旧saved/held ARM与活动入口，core/pixel的返回不得等待下一配置成功；最终ACK确认匹配控制seq下没有可复活的旧ARM/leased输入，不能仅表示运输拷贝。CLOSE_SESSION另须FIFO/holding/pending/观察及fault消息全部按旧身份终结，遵循PL两端规则；未知关闭回Q，不伪造ACK成功。平台stop_new优先于live资格，迟到ENABLE/旧READY消费都不能把该门重新打开。新CONFIG/STOP/重试在动传感器前等待撤销成功及旧入口隔离；DDR尾账本仍独立继续。

观察控制op2=0START/1STOP/2身份匹配安全处置/3非法。每attempt在14项核验完成后使用新window_seq，观察端保存START/ACK后下一完整SOF才可计第一帧；旧窗口未结先STOP并排观察邮箱/held，迟到旧window或attempt的记录拒绝且不改变连续计数。每次物理assert/release使用新physical_seq及本attempt，RELEASE evidence必须匹配该token，不能重用前attempt释放事件。唯一发送者在接纳CONFIGURE前预留最多3个attempt窗口/物理token及各自停止、terminal、revoke所需预算，64位耗尽禁止新请求，旧关闭继续兑现。观察attempt与window字段补入只增观察/物理合同，不改274bit terminal。

业务ACK（ARM/GATE/OBS/物理证据）的status2为0APPLIED、1ALREADY、2BUSY、3REJECTED；error4复用上述码。错身份回REJECTED/IDENTITY，不修改目标；未知关闭进入Q并回REJECTED/PROOF_PENDING或TIMEOUT/PROTOCOL，不表示成功。物理请求保留status/error为0，证据侧填写实际结果。CFG terminal.reason复用error4；正常READY/STOPPED为0，失败保持最早已锁原因，同沿未锁时取失钟/协议未知→AL→NACK→timeout→ID/readback→模式/phase→正常STOP。未知总线/排空优先kind3，已形成terminal后只改变live状态/独立故障，不回写快照。

物理证明action2：0授权assert/release操作、1真实release证据、2旧入口关闭、3拒绝；qual_mask8：bit0电源、1EXTCLK、2电平/模组reset映射、3已assert、4实际release、5CSI隔离、6旧入口关闭、7I²C总线排空。接收保存与业务证据分别核验；字段是候选协议，不是已经取得模组证据。

CAPTURE kind3：0OK、1INPUT_BAD、2CANCELLED、3DDR_FAILED、4RESET_FAILED、5QUARANTINED、6BAD_LEASE，7非法。error_mask16：bit0格式/PPC/DT/VC、1坐标/数量、2边界、3接收CRC、4ECC、5接收FIFO/undersize、6本地FIFO、7配置代次、8phase、9DDR、10取消、11复位/时钟、12绑定、13内部、14序号耗尽、15保留0。首错index按旧已接受有效样本前缀记录，多个错误同沿取格式→数量→边界→接收→DDR→取消→复位的诊断序，实际所有握手先记账；有error_mask才解释index，未出错固定0。它是本地检测位置，不能伪称真实CRC坏像素位置。success0和drained1可同时成立；Q固定success0/drained0。

### D2a. 规范化合法值与消费侧关闭

CAM-NORM是适配器提供的明确合同：payload_valid1时PPC数字1…4、RAW低10/次10/第三10/第四10分别lane0…3，未用lane与高24位固定0。生产profile期望DT=0x2B、VC=VCX=0、WC=2400（单图像long packet/行RAW10）；该profile是候选，实际IP的PPC/packing/DT/WC对应仍B01，不把旧top取位当证据。局部W非4倍数只直接测试RAWPAIR/window/writer，不虚构其CSI包WC；可变CSI小图另须冻结合法模式。

payload_valid0要求PPC0/RAW0/DT0/WC0；VC/VCX仍profile0。short16在本profile固定0保留，原始短包字段及其真实valid另作来源诊断，不用于发明边界；SOF/SOL/EOL/EOF由经证明的适配器事件产生。SOF/SOL可和本行payload同项，EOL/EOF可和本行末payload同项，开始→payload→结束适用于同一scope同一row。跨row/frame或metadata tuple冲突必须串行拆项；全无payload/flags/error的空项不入FIFO。scope_valid1时每项绑定已保存lease，scope_valid0只观察，不建立ctx写授权。

normalized error8为候选编码：bit0格式/PPC/DT/VC/WC→capture mask bit0；bit1边界→bit2；bit2CRC→bit3；bit3ECC1/bit4ECC2→bit4；bit5undersize/bit6接收FIFO full保守失败→bit5；bit7适配协议/CDC→bit6及13。empty不置错，ECC1是否已纠正仍按候选保守失败；不能把debug低8bit直接当error8。真实错误域、帧归属与清除继续B02。

每个link维护不回绕的累计FIFO实际写提交数量64，初始0，真实record隐含ordinal从1；不增加record192位宽。scope在实际入口开始时保存该累计基线，并保存本scope最后提交值；未提交任何记录的scope closure使用入口基线，不统一置0。读RE保存本会话隐含顺序号，capture/holding/decoder按序消费或身份处置，累计连续已消费数量64只有此前所有record所有权已转移/处置才前进。RX_CLOSURE363在producer最后本scope规范记录实际写入后冻结其fifo_committed_watermark，再由独立邮箱传。它可先到core，但必须等consumer连续水位≥冻结水位，以及旧scope NORM holding/RE pending/lane holding/odd/行末RAWPAIR、CA3 pending等都已交付或安全处置，才证明消费侧关闭。以后别的scope数据不回写该快照；单看writer空、producer rx_closed或读指针空都不足。

授ARM前预留该帧最多N+2H+16条规范记录的写序号预算；payload最多N条、行/帧边界有界，非图像/空观测不进leased FIFO。超预算整源失败并关闭leased入口，预留独立fault/closure通知不靠再写满FIFO。实际事件到规范记录的上界仍B01/B06，未经证明不能以此预算宣称采集无丢帧。

### D3. 逐连接检查与必要差异

| 连接 | 当前结论 / 所需适配 |
|---|---|
| CFG→ARM | 164条全部ACK+14读回只证明内容；两帧观察不是FAE写生效/phase证明。B05未闭合前arm_eligible不得自动置1。 |
| 原CSI→NORM | 字段宽度已知，所在域/有效/对齐/closure未知；B01/B02。不能仅套入FIFO192就宣称无丢像素。 |
| NORM→RAW pair | 每条最多4样本，候选数字PPC=0只无payload、1…4对应数量；实际IP编码须显式映射。跨条odd carry只限同scope同row，EOL前必须完整W偶数。 |
| RAW pair→RGB→FE | 10bit插值后仅一次舍入/饱和；完整RGB lane定义与FE v1逐字段一致，RAW reflect101与FE灰度replicate的对象不同。 |
| RGB→源DDR | 6B/pair字节流；16B请求padding只在逻辑L以外的已授权A内，禁止每行额外pad或借未授权地址。 |
| source→live结果 | source后来失败，即使FE先报OK也作废对应结果；FE failure不反向伪造源失败，mandatory源独立验收。 |
| EOF→发布 | EOF≠rx_closed≠本地排空≠DDR release≠fence≠FM发布。固定N个安静pixel沿不是closure证据。 |
| 故障→关闭 | 保留完整ctx和实际pending/held/借用；数据满也有fault保存容量，关闭不等未来byte边沿。无物理消失证据继续Q。 |

下一整机/FM/PL版本须吸收lease1048、ARM284/ACK290、NORM192、观察392/控制260-ACK266/closure363、CFG186/192/274/物理210/资格202-ACK208、capture808及LIVE438、保持域与source配置代次绑定。旧稿未改，当前整体不能标READY。

## E. 局部数据、不变量与中文操作草图

### E1. 有限状态、存储和不变量

CA0主状态5bit：BOOT_BLOCK、WAIT_PLATFORM、RESET_HOLD、RELEASE_ACK、WAIT_T4、CORE_INIT、ID_CHECK、ROM_FETCH、ROM_TX、VERIFY_PUBLIC、OBSERVE_FRAMES、ARM_ELIGIBLE、STOP_ATTEMPT、BUS_DRAIN、RETRY_RESET_WAIT、FAILED_HELD、QUARANTINED。事务状态5bit配ISSUE/WAIT_DONE/STATUS_CAPTURE小状态；每次底层寄存器访问只有一个live，目的/配置代次锁到响应捕获。主状态/总线命令终结不等cfg terminal消费。

CA6最多6个ctx（对应六source，不能暗中开六Debayer核）。每ctx保存完整1048bit lease、arm/link/phase、计数、closure/错误、最后service_seq、不可变808bit终态及返还状态；具体FF/热冷映射仍B07。候选状态5bit：PREPARED→PREARM→RECEIVING→RAW_END→LOCAL_END→SEALING→FENCE_WAIT→FINAL_HELD→RETURNING→CLOSED，未知进Q。同一时刻只有一个CA3窗口和一个CA4 packer在扩展源字节；旧scope可在后台等待响应/控制关闭，新scope记录可排队，不能跨scope复用历史/carry。

候选新增RAM：ROM1、RAW历史4、source banks4、FE复制4共13块；原PL含camera FIFO20，不重复加。现有已列149+13=162/256=63.28125%，不是全机已综合利用率；mailbox、6ctx、算术/状态、display最终bank等另计FF/资源。ROM每记录25bit存2×20bit word，共328≤512；recent/older每960×20各两RAM；源两1024B bank共4条20×512提供64bit payload；FE512×74封装80共4条。具体同步RAM/双clock原语与100MHz仍需工具验证。

| INV | 初始化与每次操作的保持依据 |
|---|---|
| CAM-INV01 | 完整scope/gen/lease及配置/link匹配后解引用；错消息不归还他人对象。 |
| CAM-INV02 | SOF前ARM已经保存且live资格成立；没有ARM整帧不接，lease中途不补接。 |
| CAM-INV03 | 数量只在真实接纳/交付推进；invalid不是数值零，REPLAY/TAIL不增加外部RAW计数。 |
| CAM-INV04 | pending必有预留holding；valid+reserved≤capacity；同步capture不因后级stall消失。 |
| CAM-INV05 | 固定两历史行读旧值再写新值，不依READ_FIRST；窗口边界保持CFA奇偶。 |
| CAM-INV06 | RAW10到RGB8只最后一次舍入并饱和；RGB lane与DDR字节次序显式。 |
| CAM-INV07 | bank一旦sealed/borrowed只读，直到所有pending/held/DDR段及release ACK结清不重写。 |
| CAM-INV08 | FE复制只发生mandatory RGB fire一次；任意丢复制取消整个算法，不报完整OK。 |
| CAM-INV09 | source发布需要接收closure/本地数量/真实fence等相同身份；local OK不直接发布。 |
| CAM-INV10 | 停止/复位不清承诺域，Q不报drained；序号预算预留终态/关闭，耗尽不回绕。 |

### E2. 八项中文操作草图

**CAM-OP01 配置与事务成功。**

1. 接纳CFG request前核验op/profile/地址/代次/旧命令和独立receipt/terminal容量。CONFIGURE预留三attempt窗口/物理与资格撤销/终态/停止token；STOP引用现有代次，不重新分配它。CA0先发送GATE REVOKE，经core转pixel取得完整业务ACK，旧saved/held ARM、观察窗口及leased入口真正关闭/隔离后才取得新的本attempt物理授权；不是仅把CFG本域eligible变量清0。已完成源上的静态显示/识别读引用由FM管理，不要求全部消失才能配置新相机。
2. 电源、EXTCLK、模组reset映射与实际release证据成立后计T4。SC431资料T4≥4ms；5MHz名义至少20,000完整周期。候选21,000仅在真实CFG上界≤5.25MHz时可证明4ms，频率公差未冻结则B05，旧4096周期不能代替。
3. 初始化底层I²C、读3107/3108；必须捕获实际RXR，旧高层dout无赋值不可复用。名义DIV0x20给SCL≈5MHz/[5×33]=30.303kHz，是来源算术；不能采4倍分频注释。
4. 原164条25bit ROM按index00…A3保序，每条两次同步RE/下一沿capture，组装完整再事务。写按DEV_W/SUB_H/SUB_L/DATA四从机ACK；读按DEV_W/SUB_H/SUB_L/DEV_R四从机ACK，然后读8bit、主机最终NACK和STOP。主机最终NACK正常，RXR须在下一命令覆盖前保存。
5. 每个字节是ISSUE→命令完成→读已稳定SR；寄存器访问ACK、cmd_done、总线空闲分别记账。SR bit7=从机RXACK（1失败）、bit5=AL；STOP-only的TIP可能一直0，必须核CR[6]清/命令完成、BUSY清与实际SCL/SDA空闲。底层read地址4是SR、地址6可读CR，不把SR当CR。 总线空闲还须符合器件/I²C要求的tBUF；候选32个完整CFG周期仅在频率上界≤5.25MHz时给至少6.095µs，公开时限/clock上界仍B05，不把此政策当已取得器件证据。
6. ROM committed_count只在四ACK及事务真实结束后增加。index90 stream-on之后仍19条窗口/增益/mirror写，保持未arm观察/丢弃。Group Hold最多10项，不能把19项包装成原子提交；不无证重排FAE表。
7. ID CD/6B有效、164完成后依次核14公共字段：0100=01/mask01；3018=60/E0；3031=0A/0F；3037=20/60；303F=00/80；3208…B=07/80/04/38各FF；3210…13=01/44/00/05各FF；3221=66/66。未公开FAE字段不臆造mask/副作用。
8. cfg_verified仅上述内容；当前attempt核验完成后，发新OBS START260并等ACK266，观察端下一完整SOF才进入本window的两连续完整合法且receiver_closed帧；模式生效/phase依据及live平台资格另判。资格ENABLE202经core/pixel保存和业务ACK208闭合后才形成READY快照，不等待source租约/ARM。READY terminal是快照，不等待source lease；终态受反压后故障立即关live门而不改body。 observation_seq须连续且每个完整帧只消费一次；重复同body幂等，不累加资格，漏号/观察邮箱overflow使连续计数清0。
9. 任意ACK/ID/读回失败禁止arm。默认attempt0…2三次完整尝试，只有受支持reset、旧入口关闭及总线处置成立才回index00；不原地跳过失败寄存器，attempt2失败即终结、禁止attempt3第四次。NACK且仍拥有总线在字节边界STOP；AL立即释放不强插STOP。卡线/停钟不伪造bus_drained，也不自动加无依据九脉冲bus-clear。128CFG周期寄存器期限、100,000周期字节/STOP期限、每次4s独立AON期限是候选失败政策，不是器件已证时限。

**CAM-OP02 授源、ARM与不可反压入口。**

1. CA6依据旧空ctx/未耗尽代次接纳完整lease，核scope.kind、source绑定、grant W/region/base/L/A及W/H/phase/cfg；非法body只回BAD_LEASE，不用其中坏句柄释放别人。完整父端口尚B03。
2. FM scope镜像OPEN实际提交ACK及DS grant/phase0成功后，预留错误/关闭通知槽、ARM mailbox及arm_seq。只有旧live cfg资格和同epoch/link会话成立，才提出ARM284。
3. pixel端保存ARM完整body再回ACK；同时到达的SOF用旧ARM状态，新保存ARM不直接采本沿帧。无ARM或配置中帧走独立观察路径。arm一次消费于随后合法SOF，不被第二SOF复用。
4. 已arm帧的payload/边界经已证明适配器形成scope_valid1 NORM；同沿独立flags全保留。数据FIFO满即本源失效，保存首错/前缀/旧scope到独立fault邮箱，关下一ARM；后续CSI丢弃，不撤回已进入FIFO/DDR的旧承诺。
5. 独立fault槽从授ARM前预留且保持到运输接收；运输ACK转移通知所有权，不表示可授下一源。只有旧源/通知/接收会话关闭及业务容量再次成立才允许重arm，避免第二错误覆盖。
6. source cfggen绑定保留到该源真正FREE，不能在capture lease返还时删除它。相机重配不改变已经存好的RGB源及其phase/显示引用。

**CAM-OP03 规范记录、计数与RAW4转RAW2。**

1. FIFO读RE先预留两个192bit holding之一并记录原link/地址，下一沿必须capture；不因CA3 ready低遗失RAM返回。scope_valid0不进leased路径；对仍有ctx的旧scope error-only项直接转CA6 sticky错误，不把它混入当前另一帧RAW历史。scope错代次/坏PPC等作废对应有效旧scope，不解引用无效槽。
2. normalized合同数字PPC1…4才有对应样本，ppc0限payload_valid0；规范RAW低40位lane次序固定，CA1实际IP→该布局的映射待B01位序表核验，旧工程取位只是来源假设。每有效样本按候选lane0…3顺序，扩宽核本行剩余量再提交，绝不计数wrap。
3. payload_valid0不新增RAW，SOF/SOL/EOL/EOF仍独立可处理；边界应用顺序固定为属于当前记录的开始→payload→结束。一个记录不能含两个scope/row；旧FE/新FS或旧EOL/新SOL若同沿，适配器有界串行拆开；单条DT/WC/short只有一个一致元组，容量/顺序仍B01/B06。
4. 最多保存一个odd样本，只有同scope同row可与下一record首样本拼pair；每个完整pair生成RAWPAIR114。四有效样本可形成两pair，已接受record在有限lane holding中保存，不能让第二pair被新record覆盖。每行最后pair（x=W−2）移入独立114bit end_pair holding，不先交CA3；等同scope真实EOL，末行再等真实EOF，才附EOL/EOF并按下游ready交付。SOF/SOL先到时也保存开始资格，SOF附该行首pair，SOL作为首pair合法性资格、不新增RAWPAIR字段。等待末边界期间CA2继续从NORM读control记录，不能让末pair占着原record阻塞其后的EOL/EOF；旧行尚未收到合法EOL时，新行payload为协议错误；合法EOL已收但end_pair因CA3反压未交付时，后续合法新行留在NORM holding等待，不报错、不越序或跨行拼接。EOL时raw_count行应W、odd carry应0；缺/多/坏边界整源失败，abort安全处置end_pair，不按计数伪造末标志。
5. x_even11/y11按完整pair的原图坐标，SOF仅(0,0)、EOL仅(W−2,y)、EOF仅(W−2,H−1)。先按实际接受更新诊断raw_count22，再验证序列；raw_count22可表示越界，不用21bit悄悄回绕。record/raw/输出pair计数分别保存。
6. end_pair真实末EOF交付后仍等CRC/接收FIFO等closure363；rx_closed必须有实际适配器全部相关payload及错误都已报告的依据。FE、总数、下一SOF或固定安静沿数均不够。

**CAM-OP04 RAW10窗口与RGB量化。**

1. 锁当前ctx/phase/W/H后，下一沿才开放RAWPAIR。local尺寸偶W≥4、2≤H≤1080、W≤1920；整机仅1920×1080，不无证裁剪。两条固定recent/older历史每D=W/2个20bit pair。
2. row0只写recent。随后eK发RE recent/older[q]并锁当前pair，RAM数据eK后稳定；eK+1使用沿前RDATA capture并写recent[q]=当前RAW、older[q]=旧recent；不是用同沿新capture寄存器。D≥2跨行RE0/WE D−1地址不同，不依赖同址返回。
3. 垂直两个60bit holding、RE reserved及水平90bit历史共同受容量控制；已RE必须capture，下游stall只阻新RE，未交付数据/坐标/phase保持。row1以(row1,row0,row1)输出row0，其后每实际行r输出r−1。
4. reflect101：−1→1、W→W−2、−1行→1、H行→H−2，保持CFA奇偶。新行q0先完成旧行尾窗口，再初始化新行左历史，尾坐标与新首坐标分开。EOF后D次内部REPLAY给末行(H−2,H−1,H−2)，最后TAIL只用旧列，均不增真实输入数量。
5. 四phase按原图奇偶解释RGGB/GRBG/GBRG/BGGR；R/B中心本色1点、G正交4点/异色对角4点，G中心水平/垂直2点分别取R/B。样本和S、d=1/2/4，RGB8=min(255,floor((S+2d)/(4d)))。数值上界1025/2050/4100需要11/12/13bit，移位后9bit至256先检查再饱和，不先平均RAW再转8bit。
6. 输出两lane与所有sideband共停顿；只在CA4实际fire增加rgb_pairs。附件详列holding、REPLAY/TAIL、数值反例和写入端口。真实模组phase、黑电平/增益策略仍B05，不把旧B/G/R变量名当证明。

**CAM-OP05 源RGB bank、段承诺和写关闭。**

1. CA4用已pin当前ctx处理连续RGB，字节只按R0/G0/B0/R1/G1/B1；无每行padding。carry最多7B，加6B至13B，用112bit容器，高未用字节0；每pair至多写一个64bit RAM word，实际WE分支剩余≤5B；未满8B的无WE分支可留6B、上界≤7B，均保存在当前scope carry。
2. 两bank各1024B/128个64bit word，4条20×512并联，bank0地址0…127、bank1地址128…255，高16bit物理容器固定0。state FREE/COLLECT/SEALED/BORROWED/RETURN_PENDING/Q，角色代次固定。整字WE；仅COLLECT可写。
3. bank满或EOF时扩宽核descriptor剩余/A/4KiB，封1…64个128bit beat。若1024B边界分割6B pair，剩余字节属于当前ctx的独立carry，不属于已借old bank；无新bank时保存carry并关闭下一RGB ready，不溢出也不塞进旧bank。
4. source L=3WH，A=ceil(L/16)×16；EOF不足64bit word先零补当前word，不足128bit beat再补一个64bit零word，仅写L之外且<A的已授权pad。1920×1080 L恰16对齐，但小图计划仍验证pad。bank seal使用实际accepted byte数，不用看EOF猜最后word已经写完。 一个已seal bank若跨4KiB，最多拆成两个16B对齐子段，按顺序借同bank；子段RAM起址含segment_byte_offset/8，不都从word0重读。正常全部子段实际release ACK消费、pending/held归还后才返bank；失败/取消的未proposed后段可按独立失败策略作废，不等不存在的terminal，已提出段仍按DS结账。不能第一正常子段结束就重写后半bank。
5. 对old SEALED bank先prepare，保存permit后提出完整req；不能为凑req撤回held。W最早req_fire下一沿。按RE/capture读取两个64word形成128W，两个holding计valid+reserved；已读pending必须capture。地址/owner固定至真实W fire与后续终态，held W不受功能rst清除；只有上述匹配drained terminal_fire才可作废剩余未接受逻辑W，隔离kind3不许可。
6. MC整段terminal按scope/grant/permit/tag/seq/phase核验；失败不改已接受RGB前缀，整源失败。段release在已消费terminal且本地pending/held/借用处置后提出；每段RELEASED ACK消费下一沿才可复用该tag；bank还需正常所有子段完成，或失败路径未提出后段明确作废，及全部实际本地借用归还后下一沿才可重写。Q始终占旧bank直至身份匹配PREPARE/FINAL，不等未来新像素。
7. 合法EOF是正常输入封尾起点；STOP/cancel/rst/早错另由CA6对active ctx发独立local_abort（完整scope、原因与唯一token），不等待RAW/RGB EOF。同沿旧fire先记账，sticky失败，未proposed COLLECT/carry可明确丢弃；已提出段/permit及pending按DS结清，不在逻辑L内补假像素或假EOF。先完成已授权有限tail/pad、所有已提出段和未提出permit返还，产生“不再扩展请求”的local闭合/最后实际req水位；不能先seal phase再请求dirty尾bank。保持所有后台响应及releaseready推进。
8. 请求封口（全部应有prepare/req交付、未提出permit归还、水位固定）与local_closed是独立保持证据；父可先据封口seal/fence，同时W/B继续结清。最后本地 pending/holding/bank借用与MC release ACK结束才能local_closed，它不等待该fence。CA6仍保留完整ctx及父loan，不以本地空或末W当source COMPLETE。

**CAM-OP06 有限live FE复制与取消。**

1. CA5仅接纳已验证父PROCESS/结果绑定的LIVE438；FE空、旧FS/复制队列全部结清才保存新ctx。先FJ110 fire，下一沿最早FP；首SOF前未完成FJ则本帧不启动live算法，可之后用完整DDR源处理。
2. mandatory CA4 rgb fire在旧容量上确定，恰复制一次FP74入当前队列；scope/SourceOrigin/配置匹配后去除外部scope，FE只见固定job。旧queued_count=512即使同沿RE也不WE同址，仍按该候选支路overflow关闭；count=0不发RE，1…511同沿RE/WE地址不同。队列512×80高6零，完整in_bad仍保存，不接0掩盖错误。
3. queue RE预留holding、下一沿capture，所有RGB/coords/markers/bad同停顿。满、绑定错或源失败立即关闭新复制并cancel整个FE；源writer继续。算法输出即使已写前缀也由父保持结果无效，结清相应旧DDR承诺。
4. cancel沿旧FO若已fire仍计，不能撤销已承诺result W；FE FS无论OK/failed均及时独立消费，不等source fence才读FS。源后续失败时旧FE OK不可发布，父通过同SourceOrigin失效结果。
5. 若FJ已held而首SOF/overflow/停止关闭支路，继续保持FJ至实际接受，下一ACTIVE沿再cancel；不能在IDLE或FJ接受沿只打一拍cancel使任务悬挂。queue/holding/FE task/FS和父借用均结清才归还LIVE绑定；单job语义不从坐标0推断新身份。队容量只设计有限失效行为，不能据512项宣称live吞吐已达标。

**CAM-OP07 接收、局部、fence与最终源交接。**

1. CA6分别保存真实RAW EOF/数量、Debayer输出数及末标志、rx_closed363与消费水位、CA2/CA3旧scope消费侧关闭、sourcewriter请求封口/local_closed、水位/phase token和真实fence。各自可能不同沿；迟到/重复消息先核scope完整代次/cfggen/link，再幂等记账。
2. rx错误/配置失效等使该ctx sticky失败，不能因已输出P个RGB或FE OK转回成功。无EOF早失败关闭新增输入并按旧身份排FIFO/pending/borrowed写，不等不存在的末像素。
3. 正常source状态形成需N/P/L一致、marker合法、phase/配置资格、rx_closed且error_mask0、consumer达到closure水位且旧scope FIFO/holding/pending/odd/end_pair/CA3全部关闭、writer/local关闭和源写phase成功fence。早失败也须相同消费侧身份排空谓词才drained1；closure先到只保存等待，不能释放ctx。phase/grant关闭仍按DS/FM父协议，不能凭任意B响应证明全源安全。
4. CAPTURE_STATUS808首次形成后保持不变。success1/drained1是本地+MC源写已闭合快照，仍持父lease/状态运输。固定因果顺序是status_fire→独立binding_return_fire/ACK→DS写grant/scope关闭证据→mirror CLOSE/ACK→后续发布/复用。return ACK不等待scope/mirror CLOSE或source FREE；后台关闭可先提出，但不得阻塞return消费。旧记录需相关通知/pin也结束才回收，source COMPLETE仍由FM核所有写关闭证据。
5. FM不得等待capture状态运输/绑定返还结束才消费该状态；CA6不得等scope/mirror CLOSE才提出状态或return，FM也不得等待CLOSE才ACK return；反向通知的容量在授源前预留。sourceCOMPLETE与sourceFREE不同：前者之后可有latest/display/freeze/process引用，后者须所有引用及旧会话都尽。
6. Q终态仅报告未知，drained0；后来平台恢复使用独立recovery done，旧status不改为OK/drained1。冻结静态RGB不受相机新cfg代次影响。

**CAM-OP08 停止、复位与恢复。**

1. 私有/优雅stop先sticky关闭新CFG扩展/ARM/新source/SOF，保留已有有限tail/pad/segment/release、held终态/closure及control通道。新cfg request不覆盖旧活跃事务。
2. byte当前命令在可判定边界结束；NACK按拥有总线STOP，AL释放后等BUS_IDLE，未知卡线Q。capture入口关闭由core/pixel有限消费/身份处置及平台接收隔离证据推进，不等待stream-off后的byte边沿。
3. 功能rst可作废CA3尚未承诺输出及FE候选，但旧已fire RGB银行、packer/carry、RAM pending、MC req/W/terminal/release、6ctx和父借用都属于保持域；rst同时触发OP05/OP07的独立local_abort使失去EOF的writer仍能关闭，不依赖被丢弃的CA3末标志。最终清除点必须有身份匹配安全证据，不统一rst数组或FIFO指针。
4. 失钟/PHY故障遵循PL PREPARE808→FINAL808：先真实旧物理效果消失及clock资格、身份特定处置held/queued/pending；旧exposed valid与新PHY隔离，不能重新触发旧写。PREPARE期间实际安全处置并归还局部payload/RAM pending/bank借用、返回QUIESCED，旧完整身份和通知pin仍保留；不能把这些借用归还全拖到FINAL，造成FINAL evidence bit3互等。FINAL齐客户端/CDC/本地借用/clock/cal证据后结束父生命周期，不以cal_done单独FREE。
5. CFG/ARM/观察window/物理/资格control/closure序号64、link_session/epoch32递增前扩位检查，耗尽关闭新授予；在CFG/ARM/lease授予时预留失败/关闭/终态token及邮箱，不在失败后再申请可能耗尽的序号。整个未清空FIFO固定旧link，不单端换会话。
6. 后续恢复未取得任何真实证据的对象仍Q。本轮没有把reset证明端口或CSI错误消失策略视为已存在，B01/02/04必须先关闭。

## F. RTL与参考映射契约

| 规范A–L | 本任务内容 |
|---|---|
| A 数值 | RAW10/样本和U11/12/13、量化U9→饱和U8；scope/header unsigned；计数RAW22/pair21/bytes32，端点33、seq65/epoch33检查；无整数除法器，常数2/4/8/16只移位。 |
| B 边沿 | pixel50/CFG5/core100各posedge；sync RE沿后RDATA稳定，下一沿capture；WE用沿前值。软件/RTL比较在沿后稳定区，不在NBA前采新输出；实际CSI域仍B01。 |
| C 交付 | 消费valid&&ready，CSI无ready；已接受record可形成两RAW pair，emit以独立holding计；新job/ARM同沿无首数据。 |
| D valid | payload_valid0只无RAW，不抹边界；REPLAY/TAIL为内部有效控制事件，不加外部计数；空历史不读未初始化RAM。 |
| E 停顿 | pending+reserved不丢capture、完整sideband/ctx保持；功能失败可撤未承诺CA3/FE输出，不能撤MC已提出req/物理承诺或借用；未接受逻辑W仅按匹配drained终态共同作废。 |
| F 延迟 | 需等row1首/相邻组才能首RGB，尾需D次REPLAY；每源另加写响应/fence/closure等待，不能把固定算术级数当整机延迟。条件逐沿示例在附件。 |
| G 复位 | PL同步释放/隔离；入口sticky止新授予、I²C/CDC/MC保持域，未知Q；不单端清指针、不同代次不复用。 |
| H 配置 | cfggen64与business config_id32独立，phase在lease固定；读回/两帧观察/真实模式生效分开；同沿最后读回+SOF使用旧资格。 |
| I 存储 | ROM1/RAW4/source4/FE4；借用只读；1R1W同步延迟及跨地址安排；20bit WE是两组10bit非字节WSTRB；20RAM CDC在PL已计。 |
| J 身份 | SourceOrigin195跨capture/process判同源；scopeH外传、完整key pinned；原图双lane/reflect101不裁剪，末数量及颜色与sideband共同停顿。 |
| K CDC | mailboxes固定body/独立业务done、Gray FIFO及两端关闭；full不能堵fault；多bit字段域未知不逐位同步拼成假包。 |
| L 实现 | Ti60F225/I3，原工程SV2009、Efinity2026.1.132/Questa2024.1候选；162RAM只是已列预算，STA/CDC/native映射/QoS未运行。 |

C++标准/对象所有权为N/A：未选择C++；未来如更改语言需另补。候选本机Python3.14.6标准库独立数值参考只在批准后生成，不依赖旧Debayer作为黄金答案。三份映射分开：

1. 共同数值：四phase和reflect101、bilinear同一单次舍入/饱和、RGB/DDR byte定义；RAW输入纯色/极值及S=3,d=2差异反例作为手工期望。
2. 硬件执行：规范记录与actual IP adapter分别测；stall/RE/capture/跨页/借用/取消/复位使用事件驱动观测，纯函数不能证明闭合。
3. 对应：输入SourceOrigin/cfggen/phase/像素坐标映到硬件RGB pair、DDR byte offset=3(yW+x)+channel；比较全部有效L字节、末端A−L pad、数量/身份和最终status。坏帧只核失败前缀/承诺及无发布，不拿部分图当完整参考。

## G. 实施与验证计划（未执行）

候选work路径为work/active/track4_full_sw_20261004；未创建。计划RTL职责：camera_cfg、camera_rx_adapter、camera_pair_decoder、camera_debayer、camera_source_writer、camera_live_fork、camera_capture_lifecycle；独立参考、CFG/RX/window/writer/组合TB与runner均未生成，不在本稿放实现体。

先C0…C3文档/资料闭合，再指定批准；获批增量先CFG及规范化接口、RAW/window数值和时间，后真实CSI+DDR/PHY、capture/live组合；最后整机资源/STA/引脚、bit/hex。没有匹配2Gb模型与保护IP/校准证据不能记录DDR PASS。相机原语/网络资料获取另循已有制度。

| TEST | 目标/条件 | 期望与观察方法 | 执行前状态 |
|---|---|---|---|
| CAM-T01 | REQ01；实际release前/T4不足/EXTCLK不合格 | 不启动I²C/ARM；独立AON与CFG事件核真实期限 | NOT_RUN |
| CAM-T02 | 四写ACK任一NACK、AL | ROM count不推进、旧字节按拥有权关闭、不跳过重试 | NOT_RUN |
| CAM-T03 | 读ID、DEV_R NACK、主机最终NACK、RXR覆盖 | 主机最后NACK正常；真实RXR/valid及ID mismatch明确 | NOT_RUN |
| CAM-T04 | STOP-only TIP0、BUSY1、CR6未清/卡线/CFG停钟 | 不报bus_drained，AON超时/Q；held终态不改 | NOT_RUN |
| CAM-T05 | index90后19写、读回14项、同沿SOF | 期间未arm丢弃，不虚构GroupHold；新资格下一帧 | NOT_RUN |
| CAM-T06 | 两连续观察第二帧错误/重复/seq gap/错cfggen | 连续资格清0；不同观察不累计成功；错身份拒绝 | NOT_RUN |
| CAM-T07 | 先lease/ARM、同沿ARMACK+SOF、无lease半帧 | 仅旧有效ARM后的新SOF采集，中途lease不补接 | NOT_RUN |
| CAM-T08 | actual CSI PPC/RAW位序/metadata/HSVS/非图像包 | 对照官方合同与真实IP仿真；不能只测理想NORM | NOT_RUN |
| CAM-T09 | payload与边界同沿、旧FE/新FS、odd组 | 每事件一次/顺序正确，scope不混，EOL carry0 | NOT_RUN |
| CAM-T10 | FIFO满、fault邮箱反压、byte停钟 | 整源无效、首错保持/不覆盖，旧scope关闭/Q准确 | NOT_RUN |
| CAM-T11 | raw过多/不足/缺EOF/坐标错/PPC非法 | 扩宽检查、真实前缀计数、错误不等不存在EOF | NOT_RUN |
| CAM-T12 | 四phase纯R/G/B、角点/首末行列 | reflect101保奇偶，完整W×H数值对照 | NOT_RUN |
| CAM-T13 | RAW极值1023、S=3/d2、饱和256 | 单舍入结果0及最大255，中间U宽正确 | NOT_RUN |
| CAM-T14 | RAW历史q511/512、跨行RE0/WE D−1 | pending页号不被新RE覆盖，无同址依赖 | NOT_RUN |
| CAM-T15 | vertical/window/RGB stall、EOF REPLAY/TAIL | capture不丢、全sideband保持、P输出不虚构输入 | NOT_RUN |
| CAM-T16 | 6B pair跨64bit/1024B/4KiB、小图末pad | 正确连续R/G/B，A内零pad，借用bank不覆写 | NOT_RUN |
| CAM-T17 | W stall/末拍/DDR RESP/terminal/releaseACK | held128bit/identity稳定，失败整源，无早复用tag | NOT_RUN |
| CAM-T18 | EOF bank恰满/尾字、prepare已授但req未提出 | 不多一段、不漏tail，未proposed归还不等fence | NOT_RUN |
| CAM-T19 | local closed与fence/control/关闭相互反压 | local不等fence，父消费status再返loan，不互等 | NOT_RUN |
| CAM-T20 | FE FJ/FP/FS时序、队满/取消/源迟到CRC | 复制恰一次/整个算法无效，源独立；FE OK不早发布 | NOT_RUN |
| CAM-T21 | source COMPLETE/FREE/newcfg/静态冻结 | 旧RGB/cfggen身份保留，全部引用尽后才FREE | NOT_RUN |
| CAM-T22 | warm reset/失钟/旧W exposed/新PHY/两阶段恢复 | old保持、identity-specific处置、Q不可假drained | NOT_RUN |
| CAM-T23 | 多capture ctx、六槽全占、突发与DDR共享竞争 | 实测积压/QoS/写期限及无丢帧条件，不用平均速率自证 | NOT_RUN |
| CAM-T24 | 全机综合/PNR/STA/pin/CDC以及采集诊断 | 原语/资源与实际约束报告、无未约束关键路径；未跑不PASS | NOT_RUN |

随机种子/实际工作负载与IP许可/编译参数在获批执行前冻结并记录；局部小图W偶≥4/H≥2与FE/Canny域交集检查，不扩展整机图尺寸。

## H. 双向追踪

| REQ/来源 | MOD | IF/操作/不变量 | 计划职责（未生成） | TEST | 实际代码/证据 |
|---|---|---|---|---|---|
| CAM-REQ01 / T4-B1 | CA0 | IF01/OP01/INV01,10 | camera_cfg | T01…06 | 未实现/NOT_RUN |
| CAM-REQ02 / 派生lease | CA1/2/6 | IF02,04,08/OP02,03,07/INV01,02,09 | camera_capture_lifecycle/rx_adapter | T07,09,21 | 未实现/NOT_RUN |
| CAM-REQ03 / B1,A5 | CA3 | IF05/OP04/INV03…06 | camera_debayer/参考 | T12…15 | 未实现/NOT_RUN |
| CAM-REQ04 / B1 | CA1/2 | IF03,04,05/OP02,03/INV03,04 | camera_rx_adapter/pair_decoder | T08…11,23 | 未实现/NOT_RUN |
| CAM-REQ05 / A3,A5 | CA4/6 | IF06,08/OP05,07/INV07,09 | camera_source_writer | T16…19 | 未实现/NOT_RUN |
| CAM-REQ06 / 基础吞吐提议 | CA5 | IF07/OP06/INV08 | camera_live_fork | T20,23 | 未实现/NOT_RUN |
| CAM-REQ07 / 恢复派生 | CA0/1/4/6 | IF01,02,06,08/OP08/INV01,07,10 | 上述保持域封装 | T02,04,10,22 | 未实现/NOT_RUN |
| CAM-REQ08 / B5,R0 | 全CA | IF全部/OP03,04,07,08/INV全部 | 诊断/参考/组合入口 | T11,13,21,23,24 | 未实现/NOT_RUN |

反向每个候选职责都有上述REQ/IF/草图/测试；没有为增加无关功能另编空泛需求。全部11项总追踪仍在07，CAM只覆盖其本次边界，不代替显示/识别/控制/交付。

## I. 设计门槛、阻塞与批准

| BLOCKING | 影响 / 需要的证据 / 可独立继续 |
|---|---|
| CAM-B01 | IF03/04真实CSI5.15 metadata域/valid/短包/RAW/PPC/HSVS；需要版本匹配官方UG和真实IP仿真。可继续规范化接口草图，不能把理想事件证明成真实接收。 |
| CAM-B02 | CRC/ECC/debug/内部FIFO及closure、CSR map/清错误/PHY隔离；需要完整错误归属和终结依据。可设计保持/通知，不能用安静周期放行。 |
| CAM-B03 | FM/DS/PL完整lease/ARM/CFG/status/return/live binding端口与六ctx峰值统一；下一联合版本吸收本稿D3，旧稿保持。 |
| CAM-B04 | 真实DDR2Gb模型/受保护PHY校准/响应/恢复；既有REQ-DDR3申请未答。可继续writer候选，不能仿造PHY PASS。 |
| CAM-B05 | 模组电气/EXTCLK/GPIO→XSHUTDN、SID、模式FAE/窗口写生效、实际phase、黑电平/增益和clock上界；需要模组/厂商资料及软件可观察依据，实机仍单列。 |
| CAM-B06 | 不可反压最坏突发/blanking、1024FIFO/两bank/FE512积压与DDR QoS及六源尾期限；实际仿真/期限比较后冻结，无丢帧验收不允许仅失效策略。 |
| CAM-B07 | 6ctx/大mailbox全部FF、native RAM双clock/端口/算术流水/100MHz、整机162外剩余资源及布局；待完整容器/STA/工具报告。 |
| CAM-B08 | 既有指定范围实施/构建/模型获取未批准，正式DB未配置；不将文档状态当审批。可继续显示/控制和联合设计，批准后才实现。 |

十项门槛：①B行为/正常及迟到CRC/无lease样例已写；②C职责/来源已写；③D字段/相邻差异具体但尚未闭合；④E/附件数据、10不变量与8草图；⑤F A–L与三映射；⑥D逐连接、B和E走查；⑦G24场景/H追踪；⑧无当前阻塞不满足；⑨保存实际读回/呈现与独立复审记录在05；⑩版本范围与输入哈希清楚但实施基线未冻结。因此保持LOCAL_DESIGN，不标READY_FOR_REVIEW，不请求把本稿直接批准为实施。

## J. 变更与恢复

与旧源路线的行为变化：RAW10保留到插值后、完整RGB源先入DDR；四色phase显式与reflect101；规范FIFO189→192；配置成功核ACK/读回/模式，源关闭与fence及lease分开；FP队完整74bit。所有均为批准前候选，影响接口/数值/存储/复位，不能在已有FE/PL输入下直接实现。

恢复读取本稿、源证据/附件、05实际复审、current document-checks与现行批准；核依赖hash/版本差异。若以后修改phase数值、失效策略、RAM同址、writer段/lease或CDC，需要更新D/E/F/G/H和相关父版本后再评审。

## K. 实现与验证实录

只读资料、字段/资源算术及文档读审可以记录DOCUMENT_CHECKS；业务源码/功能脚本/参考/TB/仿真/综合/PNR/STA/bit/hex/硬件均NOT_RUN。没有数据库写入、正式节点状态修改或原资料变更。实际保存、读回、独立发现与修正在[相机复审记录](../experiments/track4_full_sw_20261004/05_reviews/camera-review-v0.1.md)与当前检查JSON记录，不伪造编译产物。

## L. 交付与阅读说明

阅读顺序：整体B/C→D接口与差异→OP01配置→OP02/03授源及接收→OP04与附件窗口→OP05 writer→OP06同源FE→OP07提交→OP08恢复→F/G/H/I。每个中文步骤解释旧值、实际fire、pending/holding、闭合和借用；最终获批代码须逐项核这些步骤及真实符号，当前还没有代码可验。

修改颜色/phase先改REQ03/D5/OP04/F/参考/T12…15；修改源关闭先改REQ05/IF06,08/OP05,07/DS/FM父端口/T16…22；修改CSI版本先补来源与B01/02，再改IF03/04及真实IP验证。理解验收尚无用户实际作答，标待检验；不能将本文讲解当理解通过或阻塞已经获批的未来交付。
