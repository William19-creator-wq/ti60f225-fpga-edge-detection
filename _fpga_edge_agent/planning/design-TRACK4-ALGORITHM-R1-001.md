# TRACK4-ALGORITHM-R1-001：独立前端算法与 Efinity 工程 v1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。**READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN**；当前有限R1已完成设计自检、审查修正及保存读回，等待指定批准。本批位于[算法优先路线](design-TRACK4-ALGORITHM-ROUTE-001.md)R1，不是完整十一项成品。

## 通用计划字段

- Goal：不依赖具体外部存储器/CSI/HDMI，用真实全尺寸灰度/中值/Sobel核完成独立参考、协议/数值仿真与 Ti60F225/I3 的综合/PNR/STA/bit。
- Current state：[FRONTEND v1](design-TRACK4-FRONTEND-001.md)已完成数值/窗口/握手设计，未实施；本批新增可观察外壳、真实pin/SDC、构建/产物边界。
- Target state：六个前端RTL、独立参考/五个TB、外壳/外壳TB、Efinity工程/约束与运行器、真实报告和中文读码/操作记录。
- Gap：本批设计审阅与指定批准；数据库/许可为执行前置，工具能否完成是实测结果。
- Assumptions：生产1920×1080、可暂停输入，Ti60F225/I3/V4软件pin基线；硬件未到，不宣称实物确认。
- Open questions：本批执行结果未知；相机、HDMI、通用彩色对齐、完整Canny/识别不在本批正确性依赖中。
- Dependencies：ALGO-BL-20261004-v1 的22项来源；既有Efinity2026.1.132、Questa2024.1、Python3.14.6。原FE-BL中无关模型/整机材料不作为当前运行输入。
- Milestones：设计读回/复核→指定批准/执行前置→源码/测试→全尺寸仿真→外壳回归→真实工程→综合/PT/PNR/STA→bit登记。
- Detailed steps：B/C整体→D接口与组合→E局部/中文草图→F语言→G验证/H追踪→I门槛后实现。
- State transitions：仅本设计READY/批准/实现/验证；不改变正式H0或原数据库状态。
- Artifacts and hashes：新实验目录03/04/05，独立work和staging；每run记录设计/源码/输入/工具/命令/退出码/hash。
- Validation：数值、协议、工具实现、物理时序分别记录；LED/CRC不是数值oracle。
- Failure handling：任何输入/状态/工具失败停止受影响批次，保留前缀/日志，失败不形成成功bit交付。
- Human approval gates：指定本v1/范围/ALGO-BL-v1，包含work RTL/参考/TB/脚本/project/peri/SDC修改、现装仿真构建及staging登记；本地审计例外如需另外明确。
- Rollback：独立work保留已生成日志/旧版本；撤回仅本次新内容，不删除参考源、旧work/原规范。
- Completion criteria：FT-01…11和R1-T01…08实测完整，真实map/pin/PNR/STA及bit可追溯；理解/实机/整机仍分别未验收。

## A. 状态、范围与基线

当前授权是重新规划和只读调查；未批准实现。范围内：原 FRONTEND v1 六RTL与其Python参考、五TB、局部runner；新增规则图样源、结果CRC/计数/LED观察、同步reset适配、单25MHz全尺寸Efinity顶层、明确约束与有限工具运行/bit登记。不修改原FRONTEND文件。

范围外：通用原RGB伴随/彩色叠加、按键阈值交互、相机/RAW/CDC、HDMI、所有DDR/CSI/DSI protected IP、Canny与识别实现、安装/网络、DB建库/迁移、上板。此批覆盖T4-B2/B3/A1的算法证据，支持B5源码/约束交付，不声称B1/B4/A2/A3/A4/A5/A6完成。

输入见[algorithm-baseline-v1.json](../experiments/track4_algorithms_20261004/01_baseline/algorithm-baseline-v1.json)。FRONTEND SHA256：
45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114。
本批仅纳入它的B功能、C算术/窗口职责、D端口、E1…7、F/G/H算法/测试契约；其中“局部OK还需原整机存储响应才能发布”仅为历史上层集成条件。本独立实验不形成整机结果发布，也不请求旧物理任务/grant/fence。FE的正常/取消/错误/计数/保持语义不变。

唯一work为 _fpga_edge_agent/work/active/track4_algorithms_20261004/r1/，当前未创建；工具使用现有 Work/Reports ASCII别名，先确认其解析仍位于批准目录，不创建新junction或改全局环境。新构建产物不得覆盖原HDK/旧工程。

## B. 整体外部行为

| REQ | 明确规则 |
|---|---|
| R1-REQ01 | 按FE v1数值/全有限图复制边界/双像素/完整数量/配置快照/反压/取消契约实现；生产1920×1080 |
| R1-REQ02 | 独立二维参考逐坐标逐lane核对全部正常输出；模型不复制RAM/FSM/中值网络 |
| R1-REQ03 | 可达的规则RGB图样→真实算法→所有图像输出，以及FS选择的身份/终态码/计数字段进入CRC/计数→真实LED；避免无扇出算法被裁掉 |
| R1-REQ04 | Ti60F225/I3真实pin、25MHz/GCLK/复位/LED电气和有依据的SDC；不把仿真100MHz或虚拟IO当物理100MHz通过 |
| R1-REQ05 | 现有工具逐阶段执行/核退出和完整日志；综合/PNR/STA/bit分别验收 |
| R1-REQ06 | 生成bit后保存hash/报告/staging记录停止；不做下载/烧写/实体观察或正式状态伪更新 |

灰度 Y=floor((77R+150G+29B+128)/256)。开启中值：完整Y图复制边界取九值第五项；关闭：M=Y。Sobel在完整M图重新复制边界，L1=abs(Gx)+abs(Gy)，edge=(L1>T)；T为0…2047，Y_ONLY模式edge为0。FE实例合法尺寸仍偶数W∈[4,1920]、H∈[3,1080]；外壳生产固定1920×1080，小实例只回归。

常量图Y恒定、全edge0；每行[0,1,2,3]的4×3小图T4→edge[0,1,1,0]。Gx=Gy=765的极值L1=1530：T1529→1，T1530→0。停顿时挂起组和旧配置保持；取消末输出交付沿仍计实际旧交付，但job作废。规则外壳只用reset，不产生cancel；取消逻辑在通用核/TB另验，不将工具裁掉未接外部端口的外壳分支视为测试失败。

独立工程的算法结果只供本实验CRC/LED，不生成相机帧或HDMI画面。CRC相同不证明图像相同；仿真oracle与综合网表检查才是必要证据。

## C. 模块职责与整体连接

图样发生器S —R1-IF01/FJ+FP→ F0/F1/F2a/F3/F2b/F4前端
—R1-IF02/FO→ 结果记录/CRC接收器K
—R1-IF03/FS→ 任务监督器J → 下一job
K/J —R1-IF04→ LED单一driver。
KEY1/clock —R1-IF05→ Reset适配器R和同域所有模块。

| MOD | 状态与职责、划界依据 |
|---|---|
| F0…F4/F2R | 严格复用FE C/D/E；两个独立窗口各两行，合计8 RAM10；不拥有外部帧槽 |
| S图样 | 当前job锁定的pattern与三ID、q/r，仅输入握手推进；不存整帧RGB |
| J监督 | START/FEED/DRAIN/TERMINAL/ERROR/EXHAUSTED，累计job序号/最后status；仅空核与终态CRC完成后新任务 |
| K观察 | 一份160bit held记录、CRC32、移位计数8、数据组计数21、最后完整CRC/tag/status；串行消费导致反压 |
| R reset | KEY1异步输入两级同步；同步高有效reset供算法/观察，未断言同步输入已能消除全部物理风险 |
| LED driver | LED0完整OK标志、LED1滚动展示最后完整CRC位；一个同域clock-enable计数器，不新增分频clock |

所有职责自写，仅使用现有EFX_RAM10模型/综合原语。不复制原相机工程或保护核心。S可被反压；K的bit处理独立于FE输入valid，避免整个链被输入ready反向冻结。反馈唯一环是上一job完整结束→下一job，初始START明确，无跨任务借用。

## D. 接口与组合设计检查

R1-IF01、02、03是FE D原表，位宽/标志/锁定ID/取消规则原样生效，内部FW/FP/F2R/start/flush/empty同样按FE。job接纳沿不接首像素；status消费沿不接下一job。

外壳所有数据用core_clk上升沿，25MHz物理直接时钟；通用核仿真可10ns验证时间合同。rst=1期间所有valid/ready及写使能禁用，RAM不清零。

R1-IF02额外观察记录160bit（低位先布局，unsigned）：
[15:0]M， [17:16]edge，
[28:18]x_even，[39:29]y，
[71:40]epoch，[103:72]frame_id，[135:104]config_id，
136 SOF，137 EOL，138 EOF，[159:139]零21。
两lane仍lane0低位、lane1高位；只有FO实际握手生成一条record。K空闲且监督器处于FEED或DRAIN时out_ready=1；两种状态均接候选输出，不能等全输入结束才消费。忙时不接下一条、held记录不被覆写。

R1-IF03终态记录160bit：
[2:0]code，[23:3]in_pairs，[44:24]out_pairs，
[76:45]epoch，[108:77]frame_id，[140:109]config_id，[159:141]零19。
K空闲、所有已经接纳的FO record已处理完且监督处于FEED或DRAIN时，status_ready允许1。正常OK应在DRAIN、源EOF已接受、计数均N时到来；这些是消费后的终态检查条件，不能拿来阻止真实错误/不合格OK终态的接纳。FE非OK可以在FEED提前形成、合法前缀不足N，不能等源走到末EOF/N。先接真实status、然后将终态record按同一CRC规则处理，不能由LED或计数伪造FE OK。 FE的status_error_x/status_error_y仍按原FS协议输出并在FT-09及错误协议比较中检查；本外壳不存储或CRC这两个诊断坐标。160bit终态record是明确的选择性摘要，不声称包含所有FS位，也不改变FE接口。

R1-IF04是LED0/1两个unsigned1输出；一个driver。LED0=last_result_valid且last_terminal_accepted_good且last_status=OK且实际in/out/count均为N；last_terminal_accepted_good还包含三ID相等、正常DRAIN/源EOF完整条件。错误/复位为0。它表示本外壳完整job及计数，不表示独立黄金比较/硬件通过。LED1每250000个25MHz沿切换到last_crc的下一bit，共32bit循环；有效结果未出现时0。LED位索引仅按本域enable推进，期间新完整CRC可以替换快照，读整帧需以完整新snapshot为准；无需读两灯才能通过软件验收。

R1-IF05真实pin（来源见基线证据）：

| 端口 | 球号/资源 | 电压/方向 |
|---|---|---|
| clk_25m | J2 / GPIOL_P_08_CLK1_P | 1A、1.8V LVCMOS输入、合法GCLK单端 |
| key1_n | P13 / GPIOR_27 | BR、3.3V LVCMOS输入、板10K上拉、按下低 |
| led0 | N14 / GPIOR_21 | BR、3.3V LVCMOS输出、NPN候选高点亮 |
| led1 | P14 / GPIOR_22 | BR、3.3V LVCMOS输出、同上 |

软件假定V4原理图/封装版本；不涉及其他pin。R13的25/50MHz冲突脚、UART方向冲突脚不使用。新PT必须实际生成同球号/方向/电气报告，不能用既有表代替合法性结果。

| 连接 | 相容检查/反例 |
|---|---|
| S→FE | held q/r和锁定job生成RGB，valid未接受时全payload保持；无气泡像素伪补 |
| F2a→median→F2b | 两次独立有限图复制；不是扩展一次后共用，顶部旧RAM由有效性隔离 |
| FE→K | 所有M/edge/中心/ID/标志同FO握手，K忙只关ready，不改变挂起值 |
| FE status→J/K | 最后输出交付不等于CRC结束；K继续shift，FS可持有，等空闲消费，不互相等空 |
| job反馈 | 上一FS已真实消费且终态CRC完成，才重置新CRC/计数/发下job；旧tag结果单独保存 |
| reset | 两级同步高reset冲刷私有流/held/CRC/结果valid；新job从第0行建历史，不清RAM |
| 电气/STA | KEY仅接复位同步级1/2的异步清零，两个端点精确列例外；一级D固定1，级1Q→级2D、级2→core_rst及算法/RAM内部路径全部计时；LED无板外同步采样时钟 |

内部同域交接R1-IF06（不新增外部pin）：J拥有k/FJ job字段与终态检查；S只拥有锁定快照/q/r。FJ实际fire时同沿向S/K发送job_start1；S锁job_snapshot112（FE三ID96+median1+kind2+T11+pattern2），下一沿起FP有效；K同事件初始化CRC/计数。source_last_fire1仅表示FP实际接受且EOF=1，J据此FEED→DRAIN，不是S提出EOF。真实FS valid是source终结事件，S撤销未接受候选并在FS消费后清有效；这不伪造FP握手。K在FS实际消费沿锁160bit终态及J的terminal_accepted_good1；最后bit产生terminal_crc_done1并提交last_good。J仅据这个真实done/good开始下一job或进入ERROR。所有事件同clk/rst，脉冲只在相应实际沿产生，payload由各自owner持有；FO与FS不同时有效是原FE保证，验证发现违反则失败，不自编优先级隐藏它。

## E. 局部状态、中文操作草图

### E1. 原前端操作读回

本批纳入FE E1…E7的完整草图/状态/不变量，不重写为另一套数值：
OP-01 F0接job→合法输入计数检查→填充/尾部排空→所有结果真实交付/全empty/计数核对→不可变status；reset>cancel>输入错>成功。
OP-02 三阶段16bit灰度加权/舍入。
OP-03 每窗口1pending读回，推进沿消费旧RAM结果/延迟写，再发下一地址读；同bank同沿rd/wr地址不同。
OP-04 水平L/C0/C1按旧历史出上一组/上一行尾，再装新组；最终REPLAY/TAIL完成底边/右边。
OP-05 逐沿表：单窗口无stall首交付e(D+3)，末e(N+D+2)；输入气泡仍消费旧pending，不能全链冻结。
OP-06 两lane各19比较器九级median，旁路中心仍九级。
OP-07 六级Sobel、符号扩展、绝对值/11bit幅值与严格阈值，同步携带中心/标志。
这里是阅读定位，实施必须按完整FE E逐项核，不以本摘要替代。

### E2. S/J：规则图样与任务推进（R1-OP01）

job序号k为unsigned32，从0开始，只在上一FS实际消费并其CRC已处理后加1；达到FFFFFFFF后进入EXHAUSTED，禁止回绕/重用。epoch固定1，frame_id=config_id=k；reset清空所有旧有效结果/身份和内部job，重新从0开始，运行报告另用Run ID区分。

START提出job，valid保持到FJ握手；锁定median=k bit0，kind=k bit1（0 Y_ONLY/1 SOBEL），pattern=k[3:2]，阈值由k[5:4]选0/64/512/1530。同一沿不提出FP首像素。FEED的q/r从0起，成对坐标为x=2q/x+1；SOF/EOL/EOF按FE D产生。in_bad=0、cancel=0；合法输入仅在FP握手更新q/r，末组后进入DRAIN。配置不随当前计数外部变化。

每lane按当前坐标生成，所有结果收窄只用于明确8bit图样：
pattern0：R=x模256，G=y模256，B=(x xor y)模256；
pattern1：x<W/2为黑，否则白；
pattern2：y<H/2为黑，否则白；
pattern3：x bit5 xor y bit5为0取RGB各16，为1各239。
不使用浮点/随机/整帧ROM。pattern0故意定义mod256用于合法图样，不外推到算法几何溢出。

FEED和DRAIN均接FE候选输出，K持续处理。任何真实FS在这两态可持有/接纳，不能等N才能拉status_ready。FS valid出现意味着FE已终结当前job，S停止新增输入，未接纳候选按这个明确job终结事件撤销；FS消费后S清有效，旧source不能进入下一job。FS接纳条件见D；保存原code/三ID/in/out，计算terminal_accepted_good：code=OK、三ID匹配、监督旧态DRAIN、源末EOF实际接受、FE in/out与K实际组数均N。非OK或这些检查任一不符只标检查失败，不重写原FE code；进入TERMINAL继续完成已接纳终态record的CRC。CRC完成且good才发下一job；失败进入ERROR、LED0=0直到reset恢复。不超时伪造成功；测试平台对有限合法场景另外有等待上界。

### E3. K：完整结果记录与CRC（R1-OP02）

每job开始时CRC=FFFFFFFF、数据组数0、K空。FO握手沿捕获D的160bit记录及完整旧payload、组数加1，标busy；不在这个沿把新record的首bit当旧寄存器值处理。
随后的160个core沿按bit159→bit0顺序：取旧CRC bit31与当前record bit异或；CRC左移1，条件异或04C11DB7，明确mod2^32；index从159递减至0。全部shift只用held record，不读变化中的FO端口。最后bit沿使用计算的新CRC提交，清busy；下一沿才可接下一record。因此一个record无其他等待的接纳间隔≥161个core沿。

终态record走相同160沿；最后bit沿锁存final_crc=新CRC xor FFFFFFFF和最后三ID/status/计数、随FS消费锁住的terminal_accepted_good，置last_result_valid，不取旧CRC少算一bit。之后才重置下个job的CRC。status不同与EOF/N不符不更写成OK。

CRC仅是观察结构；未接纳record不会加组数，零M/零edge仍必须进入record。算术核心和输出跟踪在综合网表中应存在；检查map层级和RAM/比较/加法及从core到CRC到pad的扇出，不靠keep字符串自证。

不变量：同时仅一record；busy期间payload/tag/index身份一致；只有真实FO接纳计数据组；FS在所有实际接纳前缀record处理完才接纳，正常与提前失败都可终结；完整tag/CRC/good快照不受下一job变化影响；code=OK但身份错仍good=0，失败不伪装成功零边缘。

### E4. R/LED：复位与输出（R1-OP03）

KEY1低有效GPIO先经两级同clk同步。同步级1/2异步置0、释放只在本域上升沿传递1，core_rst取第二级的反值，FE仅观察同步高有效复位。KEY只连接两级的异步清零控制，级1D固定1、级2D取级1Q；不存在KEY→级1D的数据路径。两级分别命名reset_release_stage1/2，实际网表确认两级未被合并；级1Q→级2D及级2到算法复位的同步路径保留。没有多域数据/PLL失锁问题。

软件测试在开始前将key1_n置0并保持至少四个core沿，再置1；cold start不假定所有寄存器自动为0。未来实物须按此初始化条件提供reset，本次不作实体动作。复位只冲刷有效性/指针/held和LED快照；全部行RAM由FE首两行重新建立有效历史。

LED clock-enable计数18bit表示0…249999，到249999后置0并推进5bit的CRC显示索引，禁止产生分频clock；极性按候选高亮输出。板外看灯不是本次通过门槛。

### E5. 工程与约束（R1-OP04）

先确认新work/ASCII路径及来源hash→只引用本批RTL/EFX原语，独立Ti60F225/I3/SV2009工程→PT配置J2 GCLK/P13/两LED和bank标准→保存source/project/peri/SDC/hash→按明确阶段执行。

SDC：J2创建40ns输入clock，工具生成/识别的GCLK使用相同真实关系；不用假10ns物理输入clock。KEY异步例外精确列reset_release_stage1与stage2两个异步清零端点，不能全reset或整个同步链false_path；一级D为常1，不制造KEY→D1路径。报告这些外部异步assert/释放例外，并继续检查级1Q→级2D、级2→core_rst及算法同步复位/数据路径。核心/窗口RAM/CRC/计数及同步级2到FE全部setup/hold检查，无因valid/slowCRC而添加无依据multicycle。

LED是异步静态观察端，无板外采样clock，input/output delay对此N/A。登记到pad的路径/负载和静态端点的明确例外，不用随意0ns虚拟外设保证时序。PT引脚、电气、GCLK合法性及所有内部clock/path覆盖必须实际报告；若工具无法识别clock或出现有效内部unconstrained路径则失败。

顺序为Questa编译/展开/仿真→Efinity接口生成/综合→PNR/STA→审阅告警/资源/引脚/时序→成功后bit/hex（工具支持的实际格式）→staging/日志/hash登记停止。实际合法命令待获批后从现装CLI确定；不在文档假造已跑命令。仿真需合法许可证，失败保留，不绕过许可或换工具。

### E6. 预算与边界（R1-OP05）

FE设计8RAM10、0DSP、≤6000XLR，额外S/J/K/reset/LED有限寄存器/比较逻辑目标≤2000XLR、总≤8000XLR；这些是预算，实际未知。K固定160bit记录+32CRC+32最后CRC/三ID/计数/flag等，不分配整帧存储，无新RAM/DSP设计需求。

25MHz物理core，通用FE无stall结构2像素/推进拍、50M像素/s结构上限；既有100MHz仿真10ns只是协议调度，不是物理Fmax。CRC外壳161沿/组及终态使其明显低速，1080p一帧仅data消费至少166924800个沿，25MHz约6.677秒；不能拿外壳fps当核吞吐或60Hz显示。本批100MHz时序提升留R5或后续明确版本，不降低1080p验收。

## F. 语言和共同契约

SV2009可综合子集/FE F，时序非阻塞/组合阻塞并完整赋值，数值运算前扩位。Python3.14.6标准库纯数值/独立CRC实现、严格范围/长度/文件路径、固定种子，不引入C++/安装包。

| RTL项 | 本批合同 |
|---|---|
| A 数值 | FE E2/E5/E6位宽；S图样mod256、CRC mod2^32明确；状态/计数不回绕 |
| B 时钟/观察 | 上升沿采样，TB下降沿驱动、沿前判握手、NBA后观察；真实25MHz40ns |
| C 接受/交付 | FJ/FP/FO/FS valid&&ready，首次数据/下一job分沿，CRC捕获与首次shift分沿 |
| D valid/推进 | 无效不是0；K busy独立推进，FE旧pending可在输入气泡时推进 |
| E 反压/保持 | FE全伴随保持；K忙held保持；reset/取消撤销例外沿FE |
| F 延迟/吞吐 | FE E4/E7；K161沿/record；外壳低速与核2ppc分开 |
| G 复位 | KEY异步置位/两级同步释放到同步高FE reset；冷启动外部reset前提；RAM有效性隔离 |
| H 配置 | FJ锁定k派生原子配置，整个job不变；同沿下一job不复用旧数据 |
| I 存储 | 8RAM10/同址禁止/1pending沿FE，无整帧数组综合到片上 |
| J 身份 | 成对原图中心和锁定三ID；records/CRC/最后tag保持相对应 |
| K CDC | 算法单clock；仅异步KEY到同步适配，不套相机CDC保证 |
| L 实现 | Ti60F225/I3，25MHz当前PNR/STA，真实四pin，≤8000XLR预算未实测 |

软件数学到RTL结果以三ID/x/y/两lane逐位比较；CRC oracle与硬件160bit布局/bit顺序/初末值独立核对，不能仅比较最后hash。复位前旧job结果作废、新job重新开始。外壳TB小参数可快跑，但生产core四个1080p正常job的FT-11必须全部比较。

## G. 实施/验证计划（NOT_RUN）

实施：原FE六RTL及模型/TB/runner→FT数值/窗口/流控/全尺寸→S/J/K/R/LED及外壳TB→project/peri/SDC/构建runner→工具/bit/交付回核。已有FE的FT-01…11逐项保留；FE FT-12“后续板级”由本批以下真实工程检查承担，不自动PASS。

| TEST | 输入/方法、期望与失败条件 | 状态 |
|---|---|---|
| R1-T01 | FT-01…11全部：数值/512二值median/边界/反压/取消/配置/复位；每个生产job全部2073600像素比较 | NOT_RUN |
| R1-T02 | S的4图样/4阈值/两kind/median在至少64个4×3job组合；S单元另以W258/H258四图样完整输出，实际命中x/y31→32、255→256及半幅128→129；held输入/配置/身份核对，全尺寸独立core覆盖另记 | NOT_RUN |
| R1-T03 | 独立CRC对每160bit record和FS布局、首bit分沿/最后新CRC；J/K组件用typed端口驱动前缀未到N的FEED提前失败、OK错ID/错计数、FO/FS停顿，不force真实FE status/done；均实际消费并闭合，失败good=0/LED0=0 | NOT_RUN |
| R1-T04 | KEY起始reset/释放/处理中reset/旧RAM残留，重新完整job；EXHAUSTED边界TB允许初始化计数到末两值但不伪造done | NOT_RUN |
| R1-T05 | Questa编译/展开/正常结束、计数/比较数/超时/退出码；许可或模型失败明确失败，无未执行case冒PASS | NOT_RUN |
| R1-T06 | 生产参数实际map/PT/PNR：核/8RAM/算术/CRC扇出存在、四pin正确、无意外latch/blackbox/多驱动，读取完整告警 | NOT_RUN |
| R1-T07 | 40ns实际clock、setup/hold/recovery路径及例外审阅，所有有效内部路径计时，无无依据multicycle/全局false_path | NOT_RUN |
| R1-T08 | R1-T01…07必要结果成功才bit，完整命令/日志/版本/source/pin/SDC/bit SHA和staging登记，随后无硬件步骤 | NOT_RUN |

FE固定种子与向量manifest/路径/退出码契约沿FE F1/G；外壳测试用手算/纯公式，不复制S状态机。外壳整体正常测试用W4/H3及W8/H5完整job，包含k0…63全部组合；CRC每record实际比，不只最后摘要。有限timeout按真实接纳组数×161、FE窗口尾部、固定reset/注入停顿与终态预算计算；禁止无限等待或强制done。R1-T06/07始终生产1920×1080参数，不能以小参数综合替代。

## H. 双向追踪

计划路径均相对本次独立work，未生成。原FE H六核心文件/五TB/参考/runner与FT对应纳入本批，不新增空泛功能。

| REQ | MOD/IF/OP | 计划文件/核心符号 | TEST/实际 |
|---|---|---|---|
| R1-REQ01/02 | FE F0…F4/F2R，FE D/E/F/G/H | rtl/frontend六文件；model/frontend_reference.py；sim/frontend五TB；scripts/run_frontend_sim.ps1 | T01/05，待实现 |
| R1-REQ03 | S/J、IF01/03、OP01 | rtl/r1/pattern_pair_source.sv、r1_job_supervisor.sv；job_pattern、accepted_coordinates | T02/04，待实现 |
| R1-REQ03 | K/LED、IF02/03/04、OP02/03 | rtl/r1/result_crc_observer.sv、r1_led_status.sv；record_hold、crc_bit_update、last_result | T03/04/06，待实现 |
| R1-REQ04 | R/top、IF05、OP03/04 | rtl/r1/r1_algorithm_top.sv、reset_sync.sv；project/r1_algorithm.xml/.peri.xml/.sdc | T04/06/07，待实现 |
| R1-REQ02/03/05 | 纯参考/协议验证、F/G | model/r1_pattern_crc_reference.py；sim/r1/tb_r1_algorithm_top.sv、tb_pattern_pair_source.sv、tb_r1_observer_supervisor.sv；scripts/run_r1_sim.ps1 | T02…05，未运行 |
| R1-REQ05/06 | 工具/登记、OP04/05 | scripts/run_r1_build.ps1；run目录/报告及staging artifact manifest | T06…08，未运行 |

每个新核心须返回上述具体要求，不顺便生成其他批次、相机/外存或新包。实际代码/行号/hash只有生成后填。

## I. 设计门槛、批准与运行前置

①B行为/正常边界反例；②C职责/可观察整体连接与原FE调查；③D逐接口组合/pin；④E1…6完整旧核定位及五新增OP；⑤F三份数值/执行/对应合同；⑥D/E端到端正常/错误/停顿走查；⑦G/H实施/测试/追踪；⑧两方向审查发现的复位约束、提前错误终态、LED身份门控与图样边界验证问题已关闭，当前有限范围无剩余设计阻塞；⑨保存读回/呈现与实际审阅范围见新03；⑩本v1/A/H范围/ALGO-BL-v1明确。

批准对象是本完整R1 v1及A/H范围/新基线，不能借旧FRONTEND请求自动推及本外壳/构建，也不重复请求无关模型/IP预检。未收到明确批准前不生成工作副本、代码/TB/功能脚本或跑新构建。

数据库连接当前未配置。原规则要求停数据库支持的正式运行；可另明确申请“本次R1独立软件实验允许本地JSONL/报告/Side-effect ledger审计，正式DB/Manifest/H0保持原状”。该例外尚未批准，不假定现有用户路线更正自动授权。若不批准例外，待原数据库运行前置满足才执行。许可/源hash/目标冲突仍在运行前核查。

## J. 变更与恢复

原FE算法与端口不变；新的A范围排除其历史物理依赖，加入四pin/25MHz独立工程与观察外壳。旧器件/IP预检停止当前推进并保持历史；后续100MHz、通用RGB保存、按键配置或全帧接口需对应设计修订。恢复先核有效批准及新设计/hash/源码差异/实际run；同边界批准不重复索取。

## K. 实录

仅设计、来源/22hash核对与文档检查；无本次业务RTL/参考/TB/runner/project/SDC，所有功能仿真/综合/PNR/STA/bit均NOT_RUN。原源/数据库/Manifest/正式状态不变。工具可执行/许可/bit结果未测，本设计不是已运行工程。

## L. 阅读和中文操作交付

[新入口](../experiments/track4_algorithms_20261004/README.md)→路线B/C→本B/C/D→E1原核细节→E2图样/任务→E3完整结果→E4复位/LED→E5实际工具→G/H验证/定位。
获批后补真实命令、GUI打开工程/波形与逐沿观察、源码稳定符号、Run ID、pin/时序/bit位置及hash。人工观察指仿真波形/报告的阅读记录，本次不安排实体下载。功能/物理实现/理解验收分别记录，未作答不称已理解。
