# R2 B03：控制与显示的来源合同整理 v0.1

2026-10-04。SOURCE_RECONCILIATION_ONLY / NOT_READY / NOT_APPROVED / NOT_RUN。本页是[R2主计划](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)B03的只读来源整理与待设计交接，不是控制/显示已完成。原[CONTROL](../../../planning/design-TRACK4-CONTROL-001.md)及[DISPLAY](../../../planning/design-TRACK4-DISPLAY-001.md)只继承本页明示的纯数值/手势语义，旧物理父生命周期不继承。

## 1. 来源与整体次序

CONTROL实际SHA256 A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6；DISPLAY实际SHA256 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717。独立代理已全文读取，两份原文的B2/D1/E2与DISPLAY D1/D2是以下事实来源；本新整理稿保存后需读回，不将原来源审閱当新接口已冻结。

最终预期路径：按键/结构化配置→唯一配置owner→不可变处理job→Sobel/Canny/识别dispatcher→完整结果及render快照→RGB/最终edge/ANN独立重放计划→像素算术→后续固定视频输出。先确定这些外部行为，再设计owner/端口/容量/中文事件；不能把已有字段直接连到当前C0。

## 2. 按键、消抖与阈值：可继承的确切规则

四键低有效，原GPIO各两级同步，逻辑仅读旧第二级。采用1ms clock-enable，不产生分频clock。首次异样本保存candidate、age0，后续同candidate累计间隔；21相同样本/20完整间隔才提交stable，反向样本打断。仅保证采样级消抖，不声称监测tick间所有模拟弹跳。启动/恢复先WAIT_RELEASE，同样21高样本才armed，提交资格沿不立刻接受DOWN。

KEY0/2合格释放分别+16/−16，按住再久也一次；KEY3合格短于800ms释放NEXT，达到800ms只一次MEDIAN_TOGGLE；KEY1短于2000ms释放FREEZE_INTENT_TOGGLE，达到2000ms只一次独立RESET_REQUEST。边界UP归LONG，长按后的释放不再产生短按，无repeat/双击。时间是消抖后合格DOWN到UP的间隔，不是原始模拟按下时长。

同tick可保存普通事件按KEY1→KEY3→KEY0→KEY2分配连续event_seq，再以最小seq发送；旧full即使同沿pop也整手势drop、sticky与饱和drop_count记录。四key各depth1、一个发送held、独立回复容量，不因下游busy停消抖。长KEY1使用独立reset_seq/持久槽，不能被普通UI/其序号耗尽挡住。单core新方案若CORE停钟就无计时，不能继承旧AON独立送达承诺。

TS/TL/TH均unsigned11、0…2047，分别保存。Sobel严格M>TS；Canny严格Mnms>TH强、TL<Mnms≤TH弱、其他NONE；TL>TH结构化输入整次拒绝，不交换。手势在Sobel只改TS，Canny/RC对TH±16先扩12再饱和，并令TL=floor(新TH/2)。NO_CHANGE比较整个规范化配置：TH2047/TL1再INC，TL变1023，仍有变化。手势依据已接受D.algorithm，不能依据被拒绝的cursor尝试决定阈值。

候选默认TS256/TL128/TH256/preset0/median0，属于原设计选择，不是赛题或传感器指定。median切preset仍保留。单core测试25MHz和100MHz实例必须各自用CORE_HZ/1000产生真实1ms，不能照搬25000周期到100MHz。

## 3. 八preset不是八mode

| preset | algorithm | mode | 内容 |
|---|---|---|---|
| 0 | 0 SOBEL | 0 | 上原灰度/下Sobel边缘 |
| 1 | 0 SOBEL | 4 | 原RGB加Sobel彩边 |
| 2 | 1 CANNY | 0 | 上原灰度/下完整Canny边缘 |
| 3 | 1 CANNY | 4 | 原RGB加完整Canny彩边 |
| 4 | 2 CANNY_RC | 5 | 完整边缘及识别标注，需合法完整profile |
| 5 | 0 SOBEL | 1 | 原RGB，仍同完整job合同 |
| 6 | 0 SOBEL | 2 | 原灰度，不能用median后的M |
| 7 | 0 SOBEL | 3 | 全屏Sobel边缘 |

NEXT 7→0；独立cursor记录最近尝试。preset4因profile不合法被拒时D/C不变，cursor仍到4，使下一NEXT能尝试5。结构化SET成功按表匹配cursor，无匹配则cursor_valid0，下一NEXT尝试0。

完整SET允许表外合法组合，algorithm3非法，mode5要求algorithm2；mode0…5是业务视图，6仅本地诊断、7非法。非RC profile_ref规范0；RC要求非0且已安装的不可变完整参数实体，不能只设编号就说profile完成。preset采用show_edge1、show_ann按algorithm2派生；完整SET的显式开关不能被preset默认策略隐式改写。

CFG212候选内容=algorithm2+median1+TS/TL/TH各11+render112+profile_ref64。它是内容合同，不等于现有生产端口/新配置owner已实现。完整配置与来源、副作用、提交回复及有限队列还要新设计。

## 4. 逐像素数值、源坐标和优先级

render112=mode3+split_y11+edgeRGB24+ANN01RGB24+ANN10RGB24+ANN11RGB24+show_edge1+show_ann1。生产split_y540，其他mode也核该值以保唯一规范形。默认edge FF0000、ANN01 00FF00、ANN10 00A0FF、ANN11 FFFF00。ANN00不覆盖，11为文字或异类冲突；不做未声明alpha/gamma。

RGB pair为R1/G1/B1/R0/G0/B0，lane0低24，每lane R高8/G中8/B低8。原灰度=floor((77R+150G+29B+128)/256)，所有项16bit先扩、总加128最大65408；来自原RGB，纯绿149，非median后M。

| mode | 像素规则 | required planes |
|---|---|---|
| 0 | y<540取原灰度，y≥540取白EDGE/黑背景；source_y=2×(display_y mod540) | 全图SRC+EDGE，每行实际只用相应plane |
| 1 | 原RGB | SRC |
| 2 | 原灰度 | SRC |
| 3 | EDGE1白、0黑 | EDGE |
| 4 | show_edge且EDGE1替换edgeRGB，否则原RGB | SRC+EDGE |
| 5 | 先按mode4，再show_ann且ANN非0时替换对应ANN色 | SRC+EDGE+ANN |

mode0/3黑白EDGE不由show_edge或edgeRGB开关改写。mode4/5的show开关不能减少所需平面完整性核验。ANN优先于EDGE。源/显示坐标在mode1…5为1:1；mode0 display y539→source1078，y540→source0，y1079→source1078，上下都显示原完整范围的偶行采样，不插值、不减少1080p算法输入。

## 5. 新路线必须另冻结的交接

| B03子项 | 事实与必须完成的决定 |
|---|---|
| CFG owner / dispatcher | 当前CJ142无algorithm/TS且C0唯一发Y_ONLY原FJ；外层必须映射R1/R2/R4任务并分配统一config_id，不能同时另发内部FE FJ。共享FE若改变owner须修订，不能直接连字段 |
| D/P/C/J/V | D最新desired可合并，P已提出不可变，C唯一提交，J实际job锁完整处理快照，V完整结果锁render；同沿commit+job用旧C。各观察事件/回复容量和有界来源关联需冻结 |
| retain/profile | 正式配置retain_grad由algorithm2派生，独立R2诊断可0/1；层次须明确。完整profile实体及不可回收期间仍由R3/R4完成 |
| KEY1边界 | A3源冻结已按用户暂缓；只形成抽象意图/明确DEFERRED响应，不能冒称FREEZE实现。长按请求也不是reset完成。独立四pin工程KEY1用作reset，与最终四键手势top不能双owner |
| source replay / RGB对齐 | 一个活流RGB tap等待edge会堵FE窗口，禁止。独立可暂停同序来源的两个held仅负责汇合，不提供整帧存储。mode0实际访问行序0,2…1078再0,2…1078，需要重放计划 |
| renderer scope | 必须用完整最终edge，不以R2 class125代替；source与display坐标/plan/job分开。小图分屏须偶H并split=H/2，R2合法6×5不是合法上下2:1实例 |
| 单core reset/session | 共同rst取消本软件域所有held与身份；旧外部事务隔离及seq耗尽不能静默wrap。抽象长按reset接收方如何兑现旧终态另写合同 |
| fixed video | 可暂停渲染算法接口不代表HDMI扫描/serializer/CDC/60Hz；真实输出容量与时序由R5完成 |

候选普通事件去旧CDC link_session后为epoch32/event_seq64/op3/key2=101bit；回复必须有独立容量并回显完整原身份。op/inc、dec、next、median、freeze意图的合法key组合及拒绝/耗尽/替代语义需要新版本逐项写。本候选不是最终接口，不先生成CSR/runner。

候选像素输入可以有三ID96、source坐标22、display坐标22、RGB48/最终edge2/ANN4、display标志3、plane_valid3，合200bit；render由完整job快照借用。输出pairRGB48+display坐标22+三ID96+标志3=169bit。这些位宽仅帮助发现差异；plan身份、输入平面合法性、配置快照的拥有/释放及错误终态仍未闭合，不能按这份草稿实施。

## 6. 中文草图与未来验证（文字，NOT_RUN）

先接受可核验的完整结果和render快照→形成mode对应source/display访问计划→RGB/最终EDGE/ANN独立重放按同job/source坐标汇合→核required planes和身份/坐标→计算原灰度→按mode及ANN优先规则选色→形成held输出pair→真实fire推进display游标。停顿保持数据/标志/快照；缺平面或错身份明确失败，不能补0后成功。mode0的重放回到源首行必须由计划提供，普通一次行优先源无法自己完成。

未来测试：20/21消抖样本和启动按住、KEY3 799/800及KEY1 1999/2000边界UP、同tick事件顺序/旧full+pop、阈值端点/全candidate比较/非法拒绝、8preset与profile拒绝cursor、commit/job同沿旧快照、原色/灰阶/双lane、split边界、mode0…5及开关/ANN优先、独立重放反压/错ID/缺失、held像素时持续改变外部颜色/mode。每项需在正式局部设计中给TEST编号、期望、方法/观察沿及双向追踪，当前没有可执行测试。

## 7. 本轮结论与下一阅读入口

原纯规则/数学/模式已明确；B03仍OPEN，新配置/dispatcher/重放/终态/真实视频交接尚未设计完。来源调查是有效进度，不是READY或软件运行证明。按整包→R2→本1整体→2手势→3组合→4像素→5新交接→6步骤/验证阅读。后续把子项写入主设计与详细中文草图、语言/对应/验证/追踪，保存读回并独立审閱。当前无新业务源码/模型/TB/功能脚本/工程，无功能仿真/综合/PNR/STA/bit。

