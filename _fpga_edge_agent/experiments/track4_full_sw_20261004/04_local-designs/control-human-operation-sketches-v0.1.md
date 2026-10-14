# CONTROL 人工／波形操作阅读草图 v0.1

2026-10-04；TRACK4-CONTROL-001局部附件；**LOCAL_DESIGN / NOT_APPROVED_FOR_IMPLEMENTATION / NOT_READY**。本页只有中文操作路线、候选观察项和文字场景，没有业务RTL、功能脚本、可执行测试或testbench。全部场景 **NOT_RUN**；未执行仿真、综合、CDC/STA、PNR、下载或实物按键测试。

- Goal：把四键动作追到配置期望、父提交、任务采用、实际显示和原RGB冻结／恢复；把独立复位追到AON/PL真实终态。
- Current/Gap：主稿v0.1已保存，CT-B01…08仍阻塞；FM/PL/RC/观察合同尚未共同吸收。本页的阅读或算术不代替联合验证。
- Dependencies：[CONTROL主稿v0.1](../../../planning/design-TRACK4-CONTROL-001.md)、[四键／LED／复位来源v1](../01_baseline/control-keys-and-reset-evidence-v1.md)、根v0.2/PLAN_TEMPLATE及主稿所列FE/FM/Canny/RC/CAMERA/PL/DISPLAY版本。
- Milestones：整体阅读→接口对应→局部状态走查→联合父合同闭合→READY及指定批准→以后才允许实现／测试。当前只做前三项文档。
- Completion/rollback：保存和hash只证明此附件可读回；参数、手势、字段、时钟、来源或释放改变先修订主附件，不直接生成实现。原HDK／旧稿／正式状态不改。

阅读顺序：§1整体→§2交接→§3按键→§4配置D/P/C→§5冻结／恢复→§6独立复位→§7真实证据→§8十二场景／反向入口。文中的观察名是设计概念，尚不是可在现有源码中找到的信号或端口。

本轮实际读回基线：CONTROL主稿v0.1 SHA256 `A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6`；四键来源v1 SHA256 `6FCE325A30B1B514CB6D461BD03512891A04E1B400F0957FD7FDBDFBA6F2A9DA`。这些hash只绑定所读文档，不表示源码、STA或硬件已通过。来源的实物修订／板级验证为比特流之后HARDWARE_PENDING人工闸门，预设V4的软件工作不以硬件到货为前提；当前软件设计的父合同／数值／资源阻塞另列。

## 1. 先看整个动作如何到达屏幕

普通路径：四个低有效GPIO→AON25同步／消抖／手势→有限UI槽与完整mailbox→CORE期望D→父proposal P→FM committed C→真实SOF/job快照→FE/Canny/RC→完整结果与fence→DISPLAY OFFER→真实VSYNC APPLIED。CAMERA mandatory采集沿自己的源生命周期继续，不因调阈值或冻结直接复位／停止。

冻结路径：KEY1短事件→CORE按有序事件改变desired_freeze→绝对FREEZE/RESUME意图→FM/DP实际SNAP/COMMIT或ABORT/RESUME→原SourceOrigin与引用证据。独立复位路径：KEY1长事件→AON保持的PL117→SUPERVISOR receipt/done，**不经CORE UI mailbox**。

先读主稿B2的八preset，不以名字推断算法或颜色。algorithm0=SOBEL、1=CANNY、2=CANNY_RC、3非法；render模式0上下对比、1原RGB、2原灰度、3全屏EDGE、4彩边叠加、5识别叠加。mode6是本地诊断，不接业务OFFER；7非法。preset并不限制完整SET_CONFIG的全部合法组合。

| preset | algorithm／render.mode | 人工阅读含义 |
|---|---|---|
| 0 | 0／0 | Sobel上下对比 |
| 1 | 0／4 | Sobel原RGB彩边 |
| 2 | 1／0 | 完整Canny上下对比 |
| 3 | 1／4 | 完整Canny原RGB彩边 |
| 4 | 2／5 | Canny＋圆／旋转矩形识别，须合法不可变profile |
| 5 | 0／1 | 原RGB |
| 6 | 0／2 | 原灰度，不等于median后的处理灰度 |
| 7 | 0／3 | Sobel全屏EDGE |

median是独立保存的开关，切preset不覆盖它。上电候选TS256/TL128/TH256、preset0、median0、desired_freeze0；这只是主稿的待批准默认，不是已采用、已显示或官方数值。无首个完整结果时显示安全图。颜色/render112按新完整bundle冻结，旧active不会直接读取新CSR。

## 2. 再对照八项交接，不把不同ACK混在一起

| 交接／主稿入口 | 本附件阅读时要核对的内容 |
|---|---|
| CH-IF01→CT-IF01 | 四GPIO低有效；AON25每键两级同步；启动态WAIT_RELEASE；普通按键不驱raw PLL/CSI reset |
| CH-IF02→CT-IF02 | UI133=epoch32/link32/event_seq64/op3/key2；业务reply274回原UI、status2/error5及未提出来源替代证据。四本地槽借用到业务回复结束，transport副本不增加第五个独立事件容量 |
| CH-IF03→CT-IF03 | CFG212、SOURCE_UI134、PROPOSE605及receipt1182；P不可变，expected_cfggen/policy核验，C由FM唯一写入 |
| CH-IF04→CT-IF04 | 原FE FJ110/Canny job917/DP OFFER1963不默扩；真实SOF/job用沿前完整快照，config_id32不来自cfggen64截断 |
| CH-IF05→CT-IF05 | 绝对FREEZE/RESUME和done938；ACCEPTED与实际APPLIED不同；一个已启动T＋一个已接受反向RESUME的R605＋最多一个本地未提出最新意图；T/R各预留独立终态，R ready不等旧T done，WAIT_FIRST仍允许恢复 |
| CH-IF06→CT-IF06 | AON独立reset117及receipt123/done123；独立reset_seq、不竞争UI；kind1/mask/reason依下一PL版本，不能现场猜掩码 |
| CH-IF07→CT-IF07 | 完整原子观察：D、P、C570、真实USED、APPLIED、actual_freeze、SourceOrigin、cursor和错误；最终观察packed字段仍CT-B02/06 |
| CH-IF08→CT-IF08 | LED0/1仅有限状态反馈；高有效映射和唯一driver须工具／实物核验，LED不表达精确阈值或算法质量 |

CFG212=algorithm2/median1/TS11/TL11/TH11/render112/profile_ref64。SOURCE_UI134=valid1/UI133；非UI来源valid0、UI全0。COMMITTED570是cfggen64/config_id32/policy64/rendergen64/CFG212/SOURCE_UI134。UI reply274中superseded=0时旧UI字段规范0；标1只表示那个来源的D在尚未锁入P前被新D替代，不表示丢弃已提出父消息。一个已用于P的D即使P已结账，也不重新成为“未提出”来源。同沿P锁旧D、新UI更新D时，以旧已锁标志或本沿P锁存决定的合并结果判断；旧D已经进入P，superseded=0且旧UI全0，不能只看沿前标志误报未提出替代。

valid/ready在所属域边沿前共同为1才fire；观察旧body，提交后新寄存器才稳定。运输ACK只证明完整保存，不证明D提交、C提交、job采用、FREEZE完成或APPLIED。所有held body和已经开始的阶段继续履行，不以按键、暖rst或新的D覆写。

## 3. 从真实按键电平读到一次有序事件

[来源v1](../01_baseline/control-keys-and-reset-evidence-v1.md)§2已实际读回：KEY0=C4、KEY1=P13、KEY2=N13、KEY3=A3；SW0/1/2/3及R226/R100/R101/R225各10K上拉3.3V，按下接地。来源§5说明板手册KEY1/2与LED0/1有颠倒，且旧v6 raw KEY1直连PLL/CSI/LCD/MIPI DP复位。因此将来必须检查新唯一owner；现在并没有实现解绑。CRESET_N/J5是独立配置复位，不能拿按过它证明业务排空。

CH-OP01阅读同步与起始资格：AON25的divider15按25,000周期产生1ms enable，enable不是新clock。每AON沿第二级读旧首级；消抖仅读旧第二级。首个异样本保存candidate、age0，后续同样本经过20个完整1ms间隔才确认stable变化，共21个样本。反例打断。WAIT_RELEASE也要求21高样本／20间隔；资格提交沿旧armed仍0，不能抢接DOWN。该规则是采样级观察，不声称能发现tick之间所有模拟弹跳。

CH-OP02阅读手势：消抖形成的注册DOWN/UP交下一沿手势状态；press开始hold_elapsed0，此后tick计已经经过的间隔。KEY0/2不分短长，任意久按住后合格释放都只产生一次INC/DEC，无auto repeat。KEY3小于800ms合格UP产生NEXT；800ms边界含UP只产生MEDIAN，10bit计时。KEY1小于2000ms合格UP产生FREEZE_INTENT；2000ms边界含UP只产生独立RESET，11bit计时。LONG以后UP结束状态，不另发短事件；暖恢复按住仍须重新稳定释放。

CH-OP03阅读四键并发：每键分别形成候选，不能因同tick另一键有事件就忽略它。UI仅op0…4分配event_seq，按KEY1、KEY3、KEY0、KEY2固定rank给同tick连续序号；发送时选择旧槽中最小seq。已经运输的源槽被借用、不可再次选择，直到完整匹配业务回复和运输收尾结清才清，下一沿复用。KEY1 LONG只使用独立reset_seq，不消耗UI序号；UI序号耗尽不挡合法RESET。

旧槽满即使同沿旧回复结束也不写新手势；新手势整条丢弃并记录drop_count/overflow，不覆盖旧body、不执行一半。UI四槽最多四个独立未结事件，单运输133只是其中一个稳定副本。忙不停止消抖／release检测。最小seq保证较晚UI不越过较早UI；旧事务若一直BUSY，普通UI等待而不是偷偷重排，独立RESET仍可前进。没有由此得到墙钟延迟保证。

## 4. 读配置D/P/C，再追真正采用与显示

CH-OP04先观察D，不先看LED：KEY0/2在Sobel preset只改TS；在Canny/RC preset先用12bit饱和修改TH，再令TL=floor(newTH/2)。这是主稿明确的UI规则，不改成TL/TH平移或比例猜测；完整SET_CONFIG仍接受独立合法TL/TH，TL>TH整包拒绝。median事件只切旧median，NEXT按完整preset提交algorithm/render，其余参数保留。

例：Canny旧TH256/TL128，INC得到TH272/TL136；Sobel TS仍256。例：结构化旧TH2047/TL1，INC后TH仍2047但TL1023，完整CFG已经改变，须提交D；只有整个candidate CFG212都等于旧D才能NO_CHANGE。TS/TL/TH合法上限仍2047，不因幅值真实上界1530而缩小配置域。FE用median后未缩放Sobel L1；Canny用Gaussian后NMS Mnms，不能把TS复制到TL/TH。

NEXT同时观察独立ui_preset_cursor3/valid1。每次尝试推进cursor；profile未安装时尝试4回REJECTED、D/C不变但cursor=4，这是明示局部副作用，下一NEXT尝试5，不会永远卡在3。结构化SET按algorithm/render.mode匹配表时更新cursor；未匹配时valid0，下一NEXT尝试0。该cursor是“下一次UI尝试位置”，不能充当已经committed/active的preset。最终观察接口仍须CT-B06吸收它。

CH-OP05观察P：合法UI在CORE基于旧D一次提交完整candidate和来源，回ACCEPTED_DESIRED。P空且父版本／回复容量合格时，从旧D形成PROPOSE605；同沿新UI只写新D，不混入已形成的P。提出后body、SOURCE_UI、expected版本和proposal_seq都保持。后续D可更新／合并，不改P。BUSY同body重试；VERSION拒绝先取得实际新C，结清旧P后才重建新P，不能原seq改body。静态字段／profile拒绝记该D版本失败，等待新D或明确资格改变，不因D仍不同于C无限自动重提。

CH-OP06观察C和USED：SET成功receipt1182中的COMMITTED570才是FM真实C，不由CONTROL本地预加cfggen。若同CORE沿SET与job/SOF实际握手，先登记旧job/SOF并锁旧整快照，再提交新C。下一合格任务才可能采用新C；FE status OK、Canny local OK、父输出fence分别也不直接证明已显示。algorithm变化按policy屏障，普通阈值/median/render不冒充camera重新配置。

CH-OP07观察APPLIED：源与所需图成功、合法RO grant和完整首行准备后，DP在真实VSYNC应用完整bundle，并回APPLIED1503。看完整DISPLAY_ID及cfggen/config_id/rendergen/SourceOrigin关联，不仅看mode或一个frame_id。旧APPLIED迟到不能把D/C回滚；旧合法active可重复等待新完整结果，不覆写其历史full_scope/J.policy。D被合并、C未被job采用或job失败都不必产生对应APPLIED，不能为每个按键开无限等待表。

## 5. 读冻结／恢复的绝对意图与原源身份

CH-OP08冻结路线：KEY1短事件在CORE按seq消费，以旧desired_freeze取反并立即保存绝对目标，不延后读actual_freeze来toggle。desired1只表示期望。FM接纳FREEZE形成T，DP在请求可见后的VSYNC选沿前真实active原SRC并建立snapshot-hold；FM先建立原源FREEZE引用再COMMIT。最终匹配done938 status0/APPLIED、actual FROZEN和origin_valid1/SourceOrigin195才证明冻结完成。

冻结的是完整不可变原RGB，overlay/gray/EDGE/ANN渲染表面不是重处理输入。冻结后调阈值或median，比较新旧结果的业务cfggen与同一SourceOrigin/camera cfggen：处理配置可变，原源身份不变。屏幕安全／欠载要同时读DP fault/partial状态，不能把黑色图案当作已保存RGB。CAMERA仍可采其他源槽；FREEZE、PROCESS、BIND、显示引用各自有真实owner。

CH-OP09恢复路线：另一次KEY1短事件保存desired0并形成绝对RESUME。已经启动的T和held SNAP/COMMIT不能删除；只有本地尚未提出的多个意图最多合并为最新值。若FREEZE在NO_ACTIVE/WAIT_FIRST，RESUME接纳到独立R605：ready不等旧T done，R保存完整已接受身份并预留独立receipt1182/done938，旧T也保留自己的done938。R不得因再来的意图被覆盖或合并，不能共用尚未空出的T终态槽。先禁止新冻结候选，结清旧SNAP/ABORT及hold并终结旧T，再把R移入新T、执行RESUME_PREPARE/COMMIT；真实done才能观测LIVE。恢复只撤FREEZE，不清其他BIND。直播等后续真实SOF，慢路径按FM选最新完整源。

以上是主稿候选路线；FM/DP阶段接纳、ABORT/COMMIT竞态和done谓词仍CT-B03。操作阅读不能把“应该能够恢复”写成已经无死锁或已运行通过。

## 6. 读独立复位，不把长按和清账等同

CH-OP10复位路线：KEY1 LONG在AON独立形成PL117 kind1，使用真实expected_epoch与独立reset_seq；mask/reason由下一PL版本固定，不能本附件另建值。旧UI、旧KEY1短槽、CORE停钟都不是提出前提。旧reset未结时保留旧body、记录ALREADY/BUSY，不覆盖、不直接拉PLL/CSI reset。

先观察独立receipt123，再观察独立done123。receipt ACCEPTED仅证明SUPERVISOR保存请求；它仍需stop_new、旧业务尾部／dirtyWB、真实terminal/release/fence、借用与会话关闭，然后才可私有reset。CORE停钟时可以送达请求，但可能无法取得排空证据，PROOF_PENDING或QUARANTINED不能写成完成／FREE。原物理DDR/显示恢复由PL负责；没有reset引脚变化能够替代真实证明。

暖恢复后，旧UI/父proposal/T/R/reset/receipt/done及会话保持义务先按PL授权结清；不单端清toggle或改变held epoch/body。新的手势资格重新WAIT_RELEASE，一直按住不再立刻RESET。AON自身无clock时不能由AON证明恢复，此限制也不以core同步器消除。

## 7. 最后读实际证据与有限状态灯

人工或以后波形检查按以下顺序抄录同一事务，记录无valid／未完成，不用零值补齐：

1. 来源：真实所选球号、低有效与唯一owner；原理图／封装是资料事实，新peri/pinout、CDC/STA和实物电气是另外证据。
2. 手势：同步第二级、tick、candidate/age、armed、DOWN/UP、hold_elapsed、UI/reset分类；尚不存在这些真实RTL信号，本页只是计划观察列表。
3. 交付：原UI133、槽valid/借用、最小seq选择、实际fire与reply274；drop不计为接受，重复body不重复动作。
4. 配置：D212/SOURCE_UI与cursor、P605、C570、真实SOF/job adopted身份；SOURCE_UI的valid0不伪造UI来源。
5. 屏幕／冻结：真实APPLIED1503、DISPLAY_ID、scan、Origin、actual_freeze及匹配done；C更新不代表屏幕更新，active历史状态不回写D/C。
6. 复位：独立reset117/receipt123/done123及平台证据；未知时保持pending/Q，不填“已排空”。

CT-OBS的live观察与held读响应分开；atomic read复制当时live并保持到响应消费，live继续更新。慢读不能反压APPLIED业务ACK、RETIRE、fence或返租约；当前没有可执行读取软件、UART或已经实现的观察端口，最终字段和方法CT-B06。

LED0合格运行亮。LED1优先错误4Hz闪、控制pending2Hz闪、实际FROZEN常亮、其余灭；频率从AON tick enable产生，不增slow clock。两灯只表达这些有限状态，不能分辨TS/TL/TH精确值、哪个配置已job采用、哪个ANN已显示或识别P/R达标。N14/P14候选高有效和旧driver替换均须实际工具／实物核验。ACCEPTED、COMMITTED、USED、APPLIED、actual freeze、reset done分别保留来源。

资源与时间阅读：无新增图像RAM/DSP/PLL，整机174RAM仍只是候选容器小计；UI四槽＋运输副本、reply274、P/receipt1182、C570、SOURCE_UI、cursor、T/R605及各自独立done938、观察live/held及reset保持都须列入最终FF。不存在固定“一次按键后一帧生效”期限；AON采样合同、CDC往返、父版本/资源等待、处理/fence和DP行准备分别预算，CT-B07/08未实证。

## 8. 十二个文字场景与反向阅读入口

| 场景（全部NOT_RUN） | 操作／初始条件与应读证据 | 期望及反向入口 |
|---|---|---|
| CH-T01 起始按住／弹跳 | 四键分别初始高/低；第20与第21同样本；暖恢复一直低 | 资格前零动作，20完整间隔才稳态／armed，不重复；CT01、IF01、OP01、CT-T01/02 |
| CH-T02 完整按住释放／长边界 | KEY0/2按住10s后UP；KEY3 799/800ms；KEY1 1999/2000ms及门槛UP | ±各一次，800只MEDIAN、2000只独立RESET、release无第二动作；CT01/06、OP02、CT-T03…05 |
| CH-T03 同tick四键／忙／满 | KEY3与±同时完成，KEY1 UI或LONG分别加入；旧full同沿业务回复 | UI连续seq及最小seq有序，KEY3先于±；drop全手势、不覆盖；LONG独立，UI耗尽不挡RESET；CT07、IF02/06、CT-T06…08/22 |
| CH-T04 UI阈值与结构化端点 | TS0/2047；Canny TH256/TL128 INC；结构化TH2047/TL1 INC；外部TL>TH | 饱和且完整CFG比较，272/136与2047/1023；非法整包拒绝；CT02、D1、OP04、CT-T09/10 |
| CH-T05 preset与cursor | NEXT到缺profile的4，再NEXT；结构化合法但不匹配表；长KEY3 | 拒绝4时D/C不变而cursor4，下一尝试5；unmatched下次0，median独立；CT03、B2、OP04、CT-T13 |
| CH-T06 D替代／P保持／同沿采用 | P held后连改D；D来源已锁P再结账；同沿P锁旧D+UI写新D；SET与job/SOF同沿 | 未提出才superseded，P原body不变；合并本沿P锁决定，旧D不误报替代；已锁P不重标未提出；旧job快照，后job新C；CT02、D2、OP05、CT-T11/12 |
| CH-T07 接受到真实显示 | 接受新mode/颜色，旧active重复；旧APPLIED迟到；当前job失败 | D/C/USED/APPLIED分开，旧render保持，新完整结果才应用，迟到不回写；CT03/08、IF04/07、CT-T14/19/23 |
| CH-T08 真实冻结与重处理 | freeze与候选同VSYNC；冻结后阈值/median/算法改变；DP欠载 | 沿前真实active原SRC，FREEZE先增再COMMIT；SourceOrigin不变，新结果身份另记；CT04、IF05、OP06、CT-T15/16 |
| CH-T09 等待首源／快速反向意图 | NO_ACTIVE FREEZE_WAIT_FIRST→RESUME；freeze/resume/freeze遇held阶段 | R605 ready不等旧T done、T/R各留done938；旧SNAP/ABORT/hold结清，已接受R不可合并／覆盖，只有本地未提出可合并；CT05、CT-B03、CT-T17/18 |
| CH-T10 CORE停钟复位／done迟到 | UI旧短槽满、CORE停钟时KEY1 LONG；PL receipt先到、done迟到/Q | 独立PL117送达，不以receipt报完成；旧scope/消息保持，不确定不FREE；CT06、IF06、OP07、CT-T08/20 |
| CH-T11 CDC／重复／恢复 | 不同比例/停钟，旧seq同/错body，单端暖reset，旧epoch及序号耗尽 | 完整body保持、幂等/拒绝明确；双端认证关闭，旧收尾继续；CT07、I04/09/10、CT-T21/22 |
| CH-T12 观察与LED慢读 | held atomic响应不ready时live收到新C/APPLIED；pending/FROZEN/error组合 | held不变而live更新，慢读不锁父业务；LED优先正确但非APPLIED证据；CT08、IF07/08、OP08、CT-T23/24 |

反向修改入口：按键极性／计数／边界回主稿CT01、IF01/02、OP01/02和来源§2/5；参数／preset回CT02/03、CFG212、D2、OP04/05及CH-T04…07；冻结／恢复回CT04/05、IF05、OP06、FM/DP实际阶段及CH-T08/09；复位回CT06、IF06、OP07、PL typed恢复及CH-T10/11；观察回CT08、IF07/08、OP08及CH-T12。获批实施后才在这些入口补真实文件、符号、hash和波形，不用计划位置当源码已经存在。

当前仍有CT-B01…08：唯一raw key/reset/LED owner、FM完整字段／来源／有界关联、冻结恢复父谓词、RC profile实体、暖CDC与保持、真实观察字段／方法、AON/CORE资源和CDC/STA、十一项/DDR/质量/吞吐。本文采用主稿选择，不创建第二套scope/grant、preset或阈值算法。未达到READY_FOR_REVIEW，未请求此版实现批准；理解验收尚待用户实际读回／作答，不把本页解释当作已经理解或工程通过。
