# TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001：1080p Canny流段实施范围 v0.1

2026-10-05；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。本卡只把成熟流段及独立观察工程划为可独立审阅的实施范围；保存、读回、独立核查与Root冻结后，才可能形成另一个指定READY版本。本卡不是实施批准、正式baseline或审批登记。

## 通用计划字段

- Goal：保持1920×1080，以现有Ti60F225/I3及软件工具实现、验证Gaussian→新Sobel→整数方向→fork→NMS/class及启用grad，并验证完整typed608 CRC四pin工程。
- Current state：R1已经实作，FE 123/123及四个完整1080p作业通过，R1已实际生成bit/hex；R2仍只有设计，没有本卡新实现或运行证据。R1通过的范围及来源见A，不扩大为Canny或完整十一项。
- Target state：指定新版本/范围/基线获批后，在独立r2工作目录完成数值/协议/真实源错误与恢复、生产尺寸工程综合/PT/PNR/STA，必要检查通过后生成并登记bit/hex；bit后停止。
- Gap：本v0.1待独立读回、源冻结及同范围审批/审计条件核定；现装工具的未来执行结果NOT_RUN。完整闭包/识别/DDR/生产视频等隔离于本范围，见A3。
- Assumptions：同一25MHz core域、可暂停来源；静态偶W6…1920/H5…1080；生产固定W1920/H1080；只用板卡现有资源，不恢复扩展存储路线。
- Open questions：当前稿审阅项SI-B01…03；未来工程测量是批准后的通过条件，不能伪填数值，也不能把测量尚未运行变成批准前无限调查。
- Dependencies：唯一根规范v0.2、R2 v0.3/R2-FILES/C0/OBS的冻结设计、A2实际R1复用文件、原厂RAM模型及现装工具；不借用R1审批覆盖R2。
- Milestones：本卡保存/全文读回→独立范围/接口/套件审阅→Root新baseline/READY版→指定一次批准→生成→局部/组合/1080p仿真→生产工具→实录/bit登记。
- Detailed steps：B整体→C文件职责→D交接→E局部中文步骤→F语言/预算→G有限验证→H追踪→I门槛；实际源码/波形/报告在获批后对照补入交付记录。
- State transitions：本地设计状态独立记录；本卡不改PROJECT_STATE/TASK_LEDGER、hardware_nodes、数据库或现有Approval Manifest。
- Artifacts and hashes：当前只新增本Markdown。A是候选输入证据表，不声称已生成新正式baseline；未来新run记录实际源码/模型/TB/向量/project/peri/SDC/工具及before/after SHA。
- Validation：现在仅只读合同/源码/产物调查及文档自检；G全部未来测试NOT_RUN。R1历史真实证据与R2未来证据分开。
- Failure handling：基线漂移、工具/许可/比较/时序或产物缺失均保留失败及旧run，停止受影响阶段；不改期望、不force终态、不缩小生产尺寸充当通过。
- Human approval gates：Root完成新版本与新baseline后，等待用户明确批准该R2范围；PostgreSQL未配置时，本次R2若需要本地审计例外，必须包含在同一次具体批准中，R1例外不自动继承。
- Rollback：旧设计、R1、HDK、原工具/原厂模型与旧run只读；未来全部新实现/测试/工程/日志进入批准r2工作目录，不删除历史。
- Completion criteria：G所有必需数值/协议/完整尺寸/实际物理检查成功且同源hash一致，bit/hex实际非空并登记；本范围软件完成与人工硬件观察、完整A4/十一项完成各自独立。

## A. 范围、实际来源和当前事实

### A1. 阅读顺序与时态

先读B所见的整体输出，再读C的一条数据路径和owner，之后读D每次交接、E局部微时序、G怎样验证、H怎样定位文件。源码未来按同样顺序逐步落盘并补中文操作/观察记录，不能仅生成裸代码。

根规范§10.3第8项要求“没有影响当前正确性的未决阻塞项；未来范围明确隔离”。本卡提出**新范围隔离**，不修改R2旧稿的R2-B03/B05或伪称它们已关闭。R2 v0.3 L8/188、R2-FILES L8/26、R1修订卡原NOT_IMPLEMENTED是2026-10-04历史截面；当前复用的是下表实际文件。R1的成功不能替代本卡Gaussian、方向、NMS、C0或608bit OBS的验证。

### A2. 本轮实际核读的候选输入

表中均为SHA256，无Git commit伪造。路径以控制面为根；`r1/`缩写为`work/active/track4_algorithms_20261004/r1/`。全文表示本轮工具实际完整输出；限定范围不署为全文。根入口/运行规则沿前一纯设计任务已按入口顺序实际读回，保持同版本；本轮重读唯一规范§10.3 L468–485及模板全文。

| 来源 | 实际采用/阅读范围 | SHA256 |
|---|---|---|
| 根AI_Agent_代码可理解性规范_增补提案_v0.2.md | 前任务完整919行；本轮468–485，设计/实现闸门 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| planning/PLAN_TEMPLATE.md | 全文1–154，A–L及通用字段 | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 全文1–224；本卡采纯流段数学/生命周期，不采B03实现前提 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 |
| [R2-FILES](design-TRACK4-ALGORITHM-R2-FILES-001.md) | 全文1–183；31新文件职责/schema/两套件，G在本卡数值化 | E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842 |
| [C0](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md) | 全文1–259；142/120/592、21走查及旧事实 | 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844 |
| [OBS](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md) | 全文1–186；608/19chunk/公平/故障/四pin | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 |
| [窗口v0.2](../experiments/track4_full_sw_20261004/04_local-designs/canny-window-sketches-v0.2.md) | 1–116，G-W/N-W；旧父控制由C0覆盖，不继承DDR/fence | 107E2502DD403071920E3C9820F993ABE9959A493C4E5F70F66D6BC74C0EE8B2 |
| [方向v0.4](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md) | 80–102，仅P-D01；旧物理writer/租约不采 | DE6172CF4910F593BD76622E304C56808EE62813ABA52D99E3EDF167758467DC |
| [FE v1](design-TRACK4-FRONTEND-001.md) | 本轮86–127/150–250，原端口/窗口/F4时间 | 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 |
| [R1完整v1](design-TRACK4-ALGORITHM-R1-001.md) | 既有完整设计继承背景，本轮仅核hash；不署本轮全文 | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 |
| [R1 v1.1](design-TRACK4-ALGORITHM-R1-001-v1.1.md) | 全文1–49，授权历史/原例外仅R1 | DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0 |
| r1/rtl/frontend/frontend_frame_pair.sv | 全文1–149；实际FJ/FP/FO/FS及Y_ONLY实例 | 3B8022D4B6D540DB2B186D997AF710B439F704061A9BFA91BB21DF92336B9864 |
| r1/rtl/frontend/rgb_to_y_pair.sv | 全文1–84，实际三级/16bit灰度 | D98A5ADA8711B0920F7AB7CBE5CFF1DCB8B3BAA302A3A45F9407747353CE1C31 |
| r1/rtl/frontend/median9_pair.sv | 全文1–146，19/lane、九级、共同保持 | C9FB7D69F2BF286EA8AA707ECA2EC9D34A364658E9D100E338E92DE791ADDE8F |
| r1/rtl/frontend/sobel_pair.sv | 全文1–120，三22bit诊断同组六级 | 1BF1247EF68B5573DFA3E8C64191D090507B1C0ED10589EF24157E9366A740DD |
| r1/rtl/frontend/window3x3_pair.sv | 全文1–149，实际payload寻址/phase，因此需要D4适配 | 6E8B3B9D2CA22B93BFEFBE08D35CE96BB5B38530C5A1311472ECBD269AFD9321 |
| r1/rtl/frontend/line_store_pair.sv | 全文1–33，两8bit原厂RAM与实际端口 | 5C9F41A260CC9792F4900DEBB96CD8FC9AAB7F0094C2BAC3A08D8D4BCC40E65F |
| r1/rtl/r1/reset_sync.sv | 全文1–9，两级异步assert/同步release | 2E3BBDA931097E8E7FC0B67FFD87D677DB242B9D623FD6BEE6BED71637127FFE |
| r1/model/frontend_reference.py | 1–143/499–553，纯gray/median接口/实际resolve/hash，553行 | 4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A |
| r1/project/r1_algorithm.xml | 全文1–62，现装schema/器件/SV2009；新R2改自身顶层/清单 | 709F0B5E0001B66F076EAB3C7B11A2E65BD98A5AA46CBDC6EE273C96955E07FC |
| r1/project/r1_algorithm.peri.xml | 全文1–30，真实四pin电气及零实例registry | AC804C0D8032FB8134394A14A7DC903AB78A46119D9DFDE0AFE524FD7BD6A1C0 |
| r1/project/r1_algorithm.sdc | 全文1–15，40ns、两精确SR/两LED例外 | 0F06ED5E8B4023837268E237E6C743DA964712EA3580E1C262C6B8711DE5E1D5 |
| r1/docs/efinity-operation.md | 全文1–68，现装工具/成功物理/真实bit历史 | 8EB16B6A9946702F1593573D17AF058320FC53FB5E7FB8FD65FF019F5311ECE0 |
| r1/docs/frontend-verification.md | 34–80，本轮；123套件事实另由已验收gate关联 | DCCB2E1545EDCA8C564AF99B96D7D3AB90D05C2C2617DAB4ED50FCA2DFDFEC73 |
| r1/docs/r1-verification.md | 本轮关键词限定21/25/27/33/41/58/71，不署全文 | FDA57FB296FCF9A965D693EC6AC4245D7BE2871BFCC4CA2628E53C67635CF3DD |
| r1/runs/r1_physical_005/release-gate.json | 实际完整JSON读回；Root已验收，只有R1 | EB1AC16F3014146FF6B473B63C581EDA052B9EE3D41E94AA390C547FA55C9FF5 |
| r1/sim/frontend/runs/frontend_suite_006/suite-result.json | 本轮仅实际hash/大小，功能结论引用上述gate/既有实读 | 72DA8D743B4B0BE4A3D50AC8A1E941A1D58C5FDA3F41BD7F8B634A95FDE039DB |
| 原厂efx_ram10.v | 本机Efinity2026_1/sim_models/verilog/；1–100/330–416，1R1W/1024×8/同步读保持/同址未定义 | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 |
| 旧algorithm-r2-baseline-v0.3.json | 本轮1–24/字段筛选及hash；39项是历史候选，非当前运行输入完整核对 | E5F3EAE8A0BA5C33BA7179479F94DF086ED2832CAD0032B0F1527920BE68E547 |
| config/APPROVAL_MANIFEST.yaml | 本轮75–91，106行/6558B；现状态只批准R1等旧范围 | 7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D |

旧39项中Approval Manifest A582A10DDB993DFE7058AD7EDAE4688505FA1C4F4AA161BD67E35FD59A89DF45/1390B是历史治理输入，不等于现在7AC432…6558B。不得改旧39JSON、假报39/39当前一致或用其证明R2获批。Root新冻结需把历史治理快照与当前实际授权各自标角色；本卡不写新baseline/审批manifest。

R1实际packed3411 XLR/8 RAM10/0 DSP、40ns setup余量35.381ns、hold0.063ns只为R1。此次实际核非空bit1731456B/SHA F55F973B54355A70B65F914448F8A6E6E4431C672312DF954D3042B0DCFFB321、hex1731516B/SHA06907FBFCD7824AA387A3A84914F46603483FD6202E18B793A004420EDF560AD（r1_physical_005/flow/outflow）。没有硬件下载或板上观察；R2不得继承这些数值为自身PASS。

### A3. 当前与未来的可执行边界

| 边界 | 本卡选择/剩余义务 |
|---|---|
| 当前SI范围 | 原FE灰度/可选中值Y_ONLY→Gaussian5×5→独立G8 3×3/Sobel→424整数方向→两支fork→NMS/class，retain时完整grad；C0真实CJ/FP/FS/CS；SRC/J/K/reset/LED四pin25MHz工程及31计划新文件 |
| 未来R2-B03 | 同源RGB/final-edge重放、8preset/6mode/live按键/config/display及overlay，**OPEN / OUT_OF_SCOPE**；不接活流一entry tap，不把class作final edge |
| 未来完整A4/R4 | 精确八邻域闭包/seed连通及final-edge全图导出、封口/发布，**OPEN / OUT_OF_SCOPE**；当前reason0仅流段成功 |
| 未来RC/生产存储 | 多目标识别、目录/capability/cache/DDR服务/LOAD-GRAD真实存储、资源/服务预算，**OPEN / OUT_OF_SCOPE**；只用片上线历史做本实验不取消后续板载DDR允许条件 |
| 未来生产R5 | SC431HAI/CSI/色彩处理、不可暂停输入、HDMI1080p60/CDC/缓冲容量和真实生产pin，**OPEN / OUT_OF_SCOPE**；本四pin可暂停fixture不证明这些 |
| 本v0.1当前SI-B01 | Root独立全文/接口/245评估记录方案审阅，核必要D4新适配及scope；影响所有SI-REQ/IF/TEST，不能自行宣READY |
| 本v0.1当前SI-B02 | Root新候选输入冻结/实际治理快照/指定READY版本，影响可追溯性及实施边界；不能用旧39或R1批准代替 |
| 本v0.1当前SI-B03 | 在上述一次批准里明确r2路径、工具运行/bit及本次审计前置或本地例外；当前仅doc可执行 |

三个SI项是本稿交付与评审/授权步骤，不把未来仿真、STA、资源测量列为必须先获结果才能申请批准。数学、接口、有限参数与判断标准在下文给出；若独立审阅发现影响当前正确性的遗漏，应在同一新卡修订，不复制未来模块免费消除。

## B. 整体外部行为与样例

| REQ | 可判断行为 |
|---|---|
| SI-REQ01 | CJ合法且空闲才启动；生产W1920/H1080，D960/P1036800 pair/N2073600 pixel，lane0偶列/低位，lane1下一列，全部中心行优先；不缩图 |
| SI-REQ02 | 保留R2-REQ02…05数学：两个轴[1,4,6,4,1]总权256，仅最终(sum+128)>>8；完整G8另补3×3边界/newSobel；整数方向；原幅值NMS/严格双阈值 |
| SI-REQ03 | C0唯一FE owner；CJ142/FJ110/FP74/原FS163/CS592，八真实口计数与不可变ctx；错误、取消的已交付各支前缀保留，不强补P |
| SI-REQ04 | 每次typed CLASS125/启用GRAD185/CS592真实fire捕获一608记录；三类型全部位/保留0、按实际仲裁序的19chunk CRC和独立flags；CRC不能代替数值比较 |
| SI-REQ05 | 同域反压/气泡/start/flush/reset/换job按旧状态；新S caller用受限游标寻址，原metadata错误不能被重建坐标掩盖 |
| SI-REQ06 | 三独立模型职责、严格向量/有限套件/真实结构化结果/失败探针，源码和黄金hash前后不变；逐阶段逐pair/两lane比较，不仅看PASS字符串 |
| SI-REQ07 | 真Ti60F225/I3、四pin25MHz/40ns、精确reset/LED例外，实际工具/资源/有效扇出/STA/产物证据；bit后无实体步骤 |
| SI-REQ08 | 本范围交付清楚列未来OPEN；完整十一项、最终Canny/识别和生产摄像HDMI不因本流段成功而完成 |

TL/TH无缩放unsigned11，0≤TL≤TH≤2047。Msrc/G8 unsigned8；Gx/Gy每lane signed11，−1020…1020，Mgrad=abs(Gx)+abs(Gy)≤1530。方向先处理Mgrad0→H00，再Y×1024≤X×424→H00，再X×1024≤Y×424→V10，否则同号NW–SE01/异号SW–NE11；负/正邻固定H d/f、NW–SE a/i、V b/h、SW–NE g/c，不随符号交换相等侧。

NMS仅中心>负邻、中心≥正邻、中心>0且非外框时保留；原Mgrad外框历史照存，仅分类中心外框抑制。Mnms0→00；Mnms>TH→10；TL<Mnms≤TH→01；其余00，从不产生11。TL=TH无WEAK；TH1530/2047无STRONG但可以WEAK，不能直接推出未实现的闭包结果。

正常走查：合法CJ真实fire→后续ARM共同start→held FJ真实fire→随后首FP→完整M/G8/newS/dir→fork各支实际fire→class/启用grad各P/EOF→原FS OK已保存且全部私有empty→后续沿形成CS0→K接CS及19chunk→新crc/完整last快照→下一J沿处理done。边界6×5 Msrc=16y+x应G8各行为6…11/17…22/32…37/47…52/58…63；幅值平台0,10,10,0沿同方向保留第一个10。

失败走查：生产r540/q1真实in_bad被FE接受，RGB计518402而该坏组不入数值路径；原FS2不改写，C0真实CS first5/mask bit5/loc(stage1,lane0,x2,y540)，私有后缀flush，class/grad已交付数量可不同。K先完成旧record再接真实CS，fixture_match1但complete_ok0；恢复job用新身份重新覆盖行历史，无reset也应完整。同步rst作废旧job/record/DERR/CS，无旧终态期待，随后新完整job逐位正确。

## C. 模块、文件职责及整体连接

SRC或合法TB CJ driver→IF01 C0/FE→IF02 Msrc→G→IF03 G8→受限S-caller→共享window/F4新实例→IF04 S→D→FK→IF05 N窗口/分类→IF06 CLASS；FK另IF05G GRAD；FS/DERR/八fire→C0→IF07 CS；CLASS/GRAD/CS→IF09 K608/CRC→J/LED。cancel/status/source-stop是独立控制路径；没有DDR、闭包、RC或视频反馈环。

只复用A2同一物理六FE SV与reset一次编译、多实例独立valid/历史。FE F0保持原Y_ONLY/threshold0；原FE F4 pre-Gaussian诊断不导出给Canny。newS在G8上另实例化window/F4，kind1/T0，使用F4三诊断值，其中心/edge不用；不改共享F4端口。R1外壳/runner/TB不并入新生产top。共享Python只调用gray_image/median_image纯函数，不调用其旧frontend-v1 CLI生成R2，也不修改该文件。

以下均为未来r2相对路径，root=`work/active/track4_algorithms_20261004/r2/`；现在不创建该目录或文件。本范围沿R2-FILES 21非TB+10TB=31文件，排除B03，不声称整包清单。新S-caller在canny_stream_top内部，新增G8 metadata测试在既列tb_canny_stream_top内，没有隐含第四模型或新harness文件。

| 文件/稳定职责名 | 唯一职责/不负责 | IF与TEST |
|---|---|---|
| rtl/r2/r2_protocol_pkg.sv | 位宽/布局/原因/类型命名；无state或算法 | IF01…09/schema；V/M/C/O |
| rtl/r2/canny_stream_top.sv | 单FE及G/S/D/FK/N/C0连接、newS-caller q/r；不发布final edge | IF01…07/D4；MD/HD |
| rtl/r2/canny_stream_controller.sv | 七状态、CJ/FJ/真实FS/八口账/第一原因/CS；不存图 | IF01/02/04E/07；C0-C01…21 |
| rtl/r2/gaussian5x5_pair.sv | 四行/五级/水平历史/两底行+TAIL；唯一舍入 | IF02/03；U-G |
| rtl/r2/gradient_direction_pair.sv | D1检查、四级整数方向、独立DERR；不改原FS | IF04/04E；U-D |
| rtl/r2/canny_fork_pair.sv | 一held/两pending/各支一次；不做job判断 | IF05/05G；U-F |
| rtl/r2/nms_window_pair.sv | 两行byte平面/288窗口、受限q/尾补边；不提前抑制边框 | IF05/05N；U-NW |
| rtl/r2/nms_classify_pair.sv | N1/N2/严格负正邻及TLTH/class；无闭包 | IF05N/06；U-NC |
| rtl/r2/r2_pattern_pair_source.sv | 锁四公式/fault/FP74；真实fire推进，CSvalid注册stop | IF01/08；SRC/HD-F/TOP-S |
| rtl/r2/r2_job_supervisor.sv | 外CJ/k序号/source-stop/独立flags/cancel/ERROR/EXHAUSTED；不拥有内部FE或CS副本 | IF08/09；OBS/TOP-S |
| rtl/r2/r2_result_crc_observer.sv | K三typed仲裁/608/19chunk/独立ledger/terminalCS/lastCS；无图像内存 | IF09；OBS/HD/TOP-HD |
| rtl/r2/r2_led_status.sv | last_complete_ok及CRC enable滚动两LED；无派生clk | IF10；TOP-S/TOP-HD/PHY |
| rtl/r2/r2_algorithm_top.sv | SRC/J/K/C0/reset/LED四pin；默认生产固定1920×1080 | IF01…10；TOP/PHY |
| model/canny_stream_reference.py | 直接二维25项卷积/新Sobel/整数dir/NMS/class；调用现有纯gray/median | SI-REQ02/06；U/HD |
| model/r2_observer_reference.py | 四图样、typed608逐bitCRC、fixture规则；不抄FSM/32展开 | IF08/09；OBS/HD-F |
| model/r2_vectors.py | 验域/参数/套件/manifest/I/O；不重写数学 | V/FILE schema；全部 |
| scripts/run_r2_sim.ps1 | 新run、源/黄金hash、现装编译展开/有限运行/日志JSON | G；全部及P-FATAL |
| scripts/run_r2_build.ps1 | 生产冻结/Map/PT/Pnr/STA审阅/通过后bit产物核 | SI-REQ07；PHY |
| project/r2_algorithm.xml | SV2009/Ti60F225/I3/唯一20物理SV清单及生产top | C/F；PHY |
| project/r2_algorithm.peri.xml | 四pin电气/GCLK/零实例registry | IF10；PHY |
| project/r2_algorithm.sdc | 40ns/两精确SR/两静态LED例外 | IF10；PHY |
| sim/r2/tb_gaussian5x5_pair.sv | 独立完整G数值/真实RAM/尾相位 | U-G |
| sim/r2/tb_gradient_direction_pair.sv | 合法/非法两lane、四级、DERR保持 | U-D |
| sim/r2/tb_canny_fork_pair.sv | 分支独立接纳/同沿替换/retain0 | U-F |
| sim/r2/tb_nms_window_pair.sv | 完整数学窗口/byte/实际原语碰撞及重放 | U-NW |
| sim/r2/tb_nms_classify_pair.sv | 四方向/平台/外框/threshold恰等/统计 | U-NC |
| sim/r2/tb_canny_stream_controller.sv | 合法合成子级接口fixture及C0旧事实/21走查；不是实际FE实现证明 | C0-C01…21 |
| sim/r2/tb_canny_stream_top.sv | 真FE+流链；MD rawmetadata受限注入；SRC+C0+K生产组合/合法CJ driver | MD/HD/HD-F |
| sim/r2/tb_r2_pattern_pair_source.sv | W258/H258四图样/held/bad精确一次 | SRC |
| sim/r2/tb_r2_observer_supervisor.sv | typed组件/独立flags/CRC/公平/19位置reset/k末值；不force业务终态 | OBS-B/R |
| sim/r2/tb_r2_algorithm_top.sv | 真top 6×5 k0…127及reset、真生产top k0/完整数值 | TOP-S/TOP-HD |

项目新13 RTL+共享FE6+共享reset1=20物理SV，package先编译；同文件不复制、不重复定义模块。原厂RAM仅仿真显式编译一次；Efinity使用自身primitive，不能把vendor仿真模型加入综合源码。TB内可有内部纯driver/decoder职责但只在已列TB保存，不能静默新增生产接口/模块。未来批准后中文文档可在r2/docs记录阅读、实际操作、追踪和验证，不新增业务功能；本轮只保存本卡。

## D. 接口、组合检查与明确的新适配

### D1. 外部typed和布局

所有ready/valid为1bit、同clk上升沿按沿前值fire，rst高屏蔽fire。外wrapper固定公共端口组clk/rst/cancel，`cj_valid/cj_ready/cj[141:0]`、`in_valid/in_ready/in_fp[73:0]`、`class_valid/class_ready/class_payload[124:0]`、`grad_valid/grad_ready/grad_payload[184:0]`、`status_valid/status_ready/status_payload[591:0]`。这只冻结无实现体端口，不写RTL。

| IF | 提供→使用；域/布局/意义 | 接受/保持/结束及组合保证 |
|---|---|---|
| IF01 CJ/FP | 父或J→C0 CJ142：IDs低96/W106:96/H117:107/TL128:118/TH139:129/median140/retain141；FP74低RGB48/x58:48/y69:59/SOF70/EOL71/EOF72/bad73 | 空闲CJ真实fire原子锁；实例尺寸必须相等；同沿无FP。FP无逐像素ID，来源owner负责旧job隔离，不凭坐标猜归属 |
| IF02 FJ/FO/FS | C0→原FE独立端口FJ：IDs96/median96/kind98:97=0/threshold109:99=0；FO M16/edge2/side121；FS按C0原低位163布局 | 只C0发FJ/消费FS；共同FP许可保证外/FE fire相同。去edge2成为Msrc137无图像损失；原FS只保存一次，无论OK/错误都不篡改 |
| IF03 G8 | G→newS pair16+side121=137 | G完整有限图独立补边，原G8 metadata同fire监测；共享S窗口由D4受限游标驱动，错误原位置保留 |
| IF04 S/D | 新F4诊断GX22/GY22/L122→S187→D191；每lane signed11 GX/GY/unsigned11 M，D另dir0 bits67:66/dir1 69:68 | 独立解包每22bitlane，先重组两个33bitlane；不把三个pair原封串接误作lane。F4 out_ready恰D in_ready，全部诊断共out_valid |
| IF04E DERR | D→C0：x10:0/y21:11/lane22/loc_valid23/IDs119:24=120 | 坏值实际D1 fire仍计S口，不投D2；单held不同时替换；data_flush/start不清错误，只err_fire或全域rst清 |
| IF05/05G | FK→NW N153低pair32（lane16=M11/dir2/高3零）；另GRAD185低pair64（lane32=GX11/GY11/dir2/高8零） | 一held+两pending；每支实际fire一次；retain0 grad valid/pending/count/EOF0且不依赖grad_ready |
| IF05N/06 | NW409低288窗口（lane0低144、a最低16/i最高16）→N1/N2→CLASS125低4 | 方向仅中心e，邻居只M11；外框原历史照存；两laneclass2/低lane0。贡献只class fire计，不由valid重算 |
| IF07 CS | C0→父/K CS592：CJ141:0/reason146:142/mask178:147/flags182:179/loc210:183/八counts378:211/EOF386:379/strong407:387/weak428:408/FS591:429 | 旧正常事实完整且无当沿错才CS0；失败不等P/EOF。592全部保持到fire；消费沿不可接新CJ，下一沿才空闲；ctx此前不能释放 |
| IF08 SRC/J | CJ fire→SRC/K job_start，CJ142/pattern2/fault1；K→J terminal_done/fixture_match/complete_ok/crc32；CSvalid→SRC注册source_terminated | job_start在真实CJ fire；source最后FP与CSvalid终结分开。源CSvalid注册撤未接受候选是明确保持例外；不等K忙完/CSfire才stop |
| IF09 K | R2三typed→K；K87观测（四21计数+EOF2+protocol1）→J，J flags2→K，sticky→J→cancel | 空时只一ready，CS在J FEED/DRAIN优先且无P/EOF门；flags在同CS fire独立核ledger锁，不决定ready；只有K保存完整CS |
| IF10 reset/pad | key1_n异步→共享reset两级→同域同步高rst；clk_25m/led0/led1四pin | 全域同时reset隔离旧run；reset可撤所有held、无旧CS。KEY到SR/LED静态例外具体F3，不把慢CRC作为multicycle |

统一side121/schema按R2-FILES L124：对payload B bit，随后x11/y11/epoch32/frame32/config32/SOF/EOL/EOF，分别偏移B、B+11、B+22、B+54、B+86、B+118/119/120。B16/66/70/32/288/4/64对应M/G、S、D、N、NW、CLASS、GRAD。CLASS和GRAD还原位号须与OBS L45/46相同。CS reason1…18/mask/位置/同沿优先级完全C0§6，不创建第二套错误码。

### D2. 新模块的无实现体端口约定

G、D、FK、NW、N均接clk/rst/frame_start/data_flush1、坐标11/11及SOF/EOL/EOF1、in/out valid/ready1、empty1；类型payload依D1，不另含多套物理IDs。每job只一不可变CJ ctx，三ID在内部逻辑监测/外输出由ctx关联，ctx生命周期到CS真实消费。G pair16→pair16；D 66→70并独立err_valid/err_ready/err_payload120（另输入job三ID用于错误通知）；FK70→N32与grad64双输出；NW32→288；N288→class4，输入TL/TH各11来自ctx。所有实际坐标/marker随有效数据保持；借ctx不许可跨新job覆盖。

C0端口除CJ/CS/cancel外，固定FJ110、FS163各独立valid/ready，fe_cancel1、fp_allow1、stream_start1/data_flush1、ctx_live1/ctx_cj142、derr120独立valid/ready；观察端为event_fire8、event_metadata8×121、event_classes4、event_grad64、private_empty5（G/S/D/FK/N）。metadata按D1同一schema组成，RGB口三ID只是所属ctx引用、不宣称FP有ID；RGB真坐标/marker取FP，原合法性由FE检查。组合观测不另注册8份121bit，C0仅保存必要计数/游标/错误/原FS/CS；控制单元TB用这份端口合成子级事件，不冒充真wrapper数值证据。

SRC端口clk/rst/job_start/cj142/pattern2/fault1、source_stop1、out_fp74/valid/ready/source_last_fire1；J端口clk/rst、CJ valid/ready/payload、source_last_fire/source_input_fire1、CS valid/payload及真实K status_fire、K87/terminal_done/flags/crc/sticky、job_start/pattern/fault/source_stop/cancel及terminal flags输出。J据真实source_input_fire拥有source_accepted_pairs21，SRC不另存第二份相同计数；TB外CJ driver在相同fire独立计，不抄C0 count。K端口三typed组及clk/rst/job_start/CJ142/retain1、J的terminal flags2、输出K87/sticky/terminal_done/lastCS592/lastCRC32/lastvalid/两lastflags；CRC内部字段不能充当三typed握手。LED仅读lastvalid/complete/CRC，同一clk/rst，两输出；top只有四真实pad端口。实际实现读回再核命名和连接，任何字段/位序/owner行为变更回本卡，不能私自新增IO。

### D3. flush/保持组合检查

共享FE算术及window实际只有rst组合mask ready/valid；flush/start在采样沿清有效位。原F0自身FP错误当沿flush仍保持旧out真实fire计数。新R2私有流外围按**旧C0 ABORT_DRAIN寄存状态**门控两端data valid/ready及共享newS窗口/F4，assert data_flush；不是新错误组合反馈ready。转abort的错误沿各旧fire先计入；随后私有后缀作废，RAM使能0。DERR和原FS不接入data gate；不能等empty后才接DERR/FS，否则自锁。C0 held FJ即便取消仍须真实接纳后对已ACTIVE FE取消，只有共同rst允许撤held FJ。

### D4. 实际R1源码揭示的newS caller必要delta

window3x3_pair实际L35/L117/L118/L119使用输入x_even/2、y、eof寻址/切phase；R2旧C0所称“坏metadata接受沿RAM只用本地q”不能靠复用模块名称自然成立。**本新scope显式新增调用方canonical cursor，不修改共享window或旧卡。**

wrapper拥有s_input_q unsigned10(0…D−1)、s_input_row unsigned11(0…H−1)、s_input_done1，合22bit逻辑热状态。合法共同start时置q/r0、done0；rst/旧abort data_flush时置q/r0、done1以隔离。当前G8 valid/ready与共享window输入是同一个fire；window收到数据pair不改变，寻址/phase只接x=2q、y=r、SOF=(q0且r0)、EOL=q=D−1、EOF=(q=D−1且r=H−1)。q/r只在实际G8 fire推进，末组置done1且保持末q/r不回绕；共享窗口进入REPLAY后本来无新in_ready，done另限制REAL输入许可。

e0前若raw x奇数/2047或raw y2047、提前EOF/EOL或wrong ID，但q/r合法：同e0 G8真实fire与C0监测仍成立，C0检查**未改的raw整metadata/三ID**并记录原位置/原因/mask，window只读合法q，不按raw地址；e0后cursor按旧fire提交下一q/r，C0转ABORT；e1旧ABORT门控data并flush/window使能0/clear cursor。e0旧下游输出照计实际前缀；绝不因重建出的合法S坐标删掉原G8错误或将CS变OK。

若G8受反压，cursor不推进，canonical与raw held字段均保持；独立cancel直接禁外FP而本沿G8若已有旧fire照C0合同计，随后abort清后缀。raw错误与cancel同沿，first1且metadata原因进mask；rst同沿全fire0/no CS。正常raw=canonical，数值/数量/补边/ID完全不变；没有新增pair队列、raw影子或假握手。原raw G8的held由G拥有，C0既有第一位置寄存器保留错误；新22bit不重复算八口游标。本delta增加地址/marker选择组合逻辑，实际FF/LUT/STA必须进R2真实账，不能称0成本。

## E. 局部数据、中文操作草图与微时序

### E1. C0/原FE：旧事实结算

唯一CJ ctx142、FJ held110、原FS163、first reason5/mask32/位置28、启动/取消事实、8组21计数/各q10/r11与观测/合法EOF、strong/weak21及CS592由C0拥有。初始IDLE/valid0；合法CJ握手清本job诊断，非法尺寸/阈值直接ABORT且不发start/FJ/FP。旧IDLE cancel无效；旧ARM cancel有效且不start；正常ARM只私有共同start及准备FJ，WAIT_FE接受FJ后随后RUN才首FP；末输入转DRAIN。原FS ready只依本job已启动/缓存空，错误也原样保存；FS前缀比较用旧计数+当沿真实fire，正常成功仍等后沿旧事实。

成功必须所有必需口P/合法EOF、retain支正确、原FS0三ID/计数匹配、G/S/D/FK/N实empty且DERR空、无错/cancel。真实OK+全空却缺数量/EOF→15，不永久等补尾。first是C0最先观察沿，cancel>FEprotocol>FS非OK>DERR>ID>coord>marker>class>grad>count>stats；其余mask都保存。持续cancel只首次加入原因但持续禁新FP/取消FE，可正常结算失败。失败不等P/EOF；须held FJ义务完、已启动FE真实FS、私有empty及DERR已消费，后续结算沿锁CS。STATUS全部保持，fire仅回IDLE；原ctx/FS下一job前释放，不占免费第二job。

### E2. Gaussian：四行、五级和边界

4个bank各D pair16=8 RAM10，q受限10/r11；phase IDLE/REAL/BOTTOM0/BOTTOM1/TAIL/WAIT_EOF与pending NONE/REAL/BOTTOM0/BOTTOM1/TAIL分开。start清valid/历史、进入REAL，不清RAM也不接首像素。每次本地advance先消费旧pending/旧RAM、最多提交旧REAL一次延迟写，再按旧phase发读；连续同bank读q+1/写q，跨行读0/写D−1，D≥3不碰撞。气泡消费旧pending一次但不生新黑像素；stall RE/WE/WCLKE0，pending/读回/算术保持。

r0/r1仅建历史；r2的纵样本0/0/0/1/2，r3为0/0/1/2/3，之后r−4…r中心r−2。V1外/近9bit及中心×6的11bit，V2先扩12得到0…4080；共享四列12bit水平历史48bit，q0建立v0/v0/v0/v1，q≥1形成旧中心两lane，跨新行q0同时给旧行右补边并建立新历史。H1外/近13bit/中心×6的15bit，H2扩16总和≤65280，H3只在这里+128后取高8≤255。各级用旧值，没有提前纵轴除16。

真实末组延迟写可以与BOTTOM0首读同沿；BOTTOM0/1只读最终四行构成H−2/H−1，TAIL为有效控制事件，没Msrc/没RAM操作/不增输入计数，经V1/V2到水平形成最终右pair。WAIT_EOF只等最后输出/空。无气泡/ready常1/start已完且首Msrc fire e0时，首交付e(2D+7)、末e(P+2D+6)；6×5为e13…e27，生产e1927/e1038726。只是局部设计推导，不能当整链固定延迟或实测。

### E3. newS/D/fork：同组值与错误槽

newS caller按D4提交q/r，共享window独立夹紧G8图，window首/末局部D+3/P+D+2；共享F4六级是角/中项→侧和→signed差→abs及梯度延迟→扩位L1→诊断同组输出。窗口在e[k]接纳，F4末级e[k+5]后有效，D1最早e[k+6]接纳。Sobel pair低lane0、每11bit独立signed，不将22bit整体解释为signed。

D1把GX/GY先sign_extend12取abs，核≤1020/M≤1530/扩12双abs和等M；失败组真实fire计S口，但D2不置valid，形成DERR120。两lane同时坏选0，x_even+lane先扩12；可表示11bit才loc1，不夹紧画面；否则loc0/lane/x/y0。错误槽有效时D1停止新输入，即使err_ready高也不当沿替换。data_flush清四级valid不清DERR，start不丢DERR；只有err_fire或rst清，empty须data和error均空。

合法D1保存X/Y10，D2先扩20形成384/40/1024乘积，D3合424并延迟原GX/GY/M，D4依B优先判方向。各级统一advance来自D4容量，bubble排尾，不由in_valid或Msrc0冻结。D4 e[k+9]后有效，fork e[k+10]接受，分支最早e[k+11]。fork旧held70+中心25/valid/两pending：各支fire只清自己pending，旧空或本沿所有旧pending会释放才in_ready；同沿新组覆盖新pending、无透明透传。关闭grad不等它ready/EOF。任何flush沿之前成立的旧分支fire各自照计，剩余后缀作废。

### E4. NMS/class：原幅值与byte平面

两行各4 RAM10（low/high byte×两lane），共8；每平面1024×8，只q<D、同使能/地址/事件。16容器低byte M7:0、高byte=M10:8/dir2/高3零，重组无损。本模块自己受限q/r/phase，不用raw坐标寻址；recent/older与旧pending延迟写、底行REPLAY和TAIL同E2/原FE规则，但只有一底行。水平历史三48bit列共144bit；pair窗口288，行优先a最低16/i最高16、lane0低144。外框原M历史不置零。

N1实际接窗口锁中心/dir/邻居/外框/TL/TH/坐标，N2读旧N1比较/分类；两级advance来自N2容量，全payload停顿。每lane contribution仅已交付class00/01/10贡献，非法11仍计class pair但该lane不计strong/weak。N窗口无停顿首/末D+3/P+D+2，分类再2沿D+5/P+D+4；输出EOF后实际窗口与N1/N2皆空才N.empty。并非class暂时valid0就已完成。

### E5. SRC/J/K：真实错误、记录和恢复

J reset k0；epoch1/frame=config=k；median bit0/retain bit1/pattern[3:2]/阈值[5:4]四对(0,64)/(64,512)/(512,1530)/(1530,2047)/fault bit6。pattern0 RGB=(x mod256,y mod256,(x xor y) mod256)，1按x<W/2黑白，2按y<H/2黑白，3按xbit5 xor ybit5取RGB各16/239。SRC锁配置/q/r，held FP稳定至真实fire；fault仅r=floor(H/2),q1的候选bad1，停顿不重复消费。后续观察旧CSvalid注册source-stop撤未接纳候选；stop不是CS真实接纳。

J START→FEED→DRAIN→TERMINAL→START；CSvalid后源终结，CSfire由K保存完整592，J仅读当次CS及自己/独立K账计算两flags，随后不借C0已释放ctx。正常fixture_match=complete_ok；源fault按B及OBS原关系fixture1/complete0，可继续下一job；observer坏data后sticky→下一J沿请求cancel但保持FEED/DRAIN/CS接纳，真CS/CRC结束后才ERROR。kFFFFFFFF完成后EXHAUSTED不回绕；rst全域撤旧job，k回0，RunId隔离历史。

K一次record608、crc32、index5(0…18)、type2/busy、独立class/grad游标与计数/EOF/统计/协议、rr/sticky、terminalCS592及lastCS592/lastCRC/flags/lastvalid。last在新job init保持旧完整快照；只有新STATUS最后chunk整体提交新快照。J不另存592。record低2 type0CLASS/1GRAD/2STATUS/3非法；payload从bit2起，高padding分别481/421/14位零。

K旧空且J FEED/DRAIN：CS优先（包括早失败），否则两data valid用rr，只一次ready；实际fire后rr指另一支，不随valid更新。data非法仍真实捕获/记账，不因检查错误抹fire；置sticky/停止新data，继续CRC/真CS。capture e0不CRC；e1…e19取旧shift[607:576]按bit31→0做32步非反射CRC/poly04C11DB7，初FFFFFFFF、每步mod2^32。e19须用新CRC，普通record继续jobCRC，STATUS xorFFFFFFFF/提交last/registered done；下一J沿看旧done，下一capture最早e20。双持续data至多隔一个对方record获服务；CS可优先终结，异常CS+data共存照接CS但flags0/协议错，不挂起。

K期望CRC按**实际record接受次序**逐bit独立算，不能把class整图和grad整图静态串接。typed错误只豁免声明故意改变字段，其余仍核；normal complete需要真实CS0/CJ/FS/八口P/EOF/启动facts和独立SRC/K事实一致。sourcefault的CS前缀由真实各口账和独立terminal_policy计算，不能复制DUTCS当黄金。生产false-positive CRC或LED变化不证明逐像素数学。

## F. 语言、映射、时间和资源

### F1. 三份独立合同

共同数值：Python3.14.6标准库、无C++（本范围不做C++/RTL映射，C++条款有依据N/A）。RGB为完整不可变tuple三int0…255（拒bool），width/height静态合法，median/retain严格bool，TLTH严格int域及顺序；先核全输入再返回新结果，不改输入。调用现有gray_image/median_image纯函数；Gaussian直接25项各自clamp、整数累加/一次舍入；newS直接完整G8二维式；direction整数比较；NMS直接原Mgrad图。另nms_windows_image直接9坐标clamp返回新tuple窗口，不抄RAM ring或DUT读回。Python任意精度用于推导，导出窄化前显式检查理论界限，signed11二补码单独编码；不使用atan/浮点容差。

硬件执行：SV2009可综合子集，所有数据/valid/坐标与可引用ctx生命周期分清；沿前fire、NBA后新状态，算术先扩位，signed lane每段独立解释。G sum+128 unsigned16≤65408；方向乘积20bit最大1044480；计数21增加/和先扩22，x+lane先扩12，首次多余组转abort不回绕。配置只CJ采样，全job固定；无新隐含动态cfg或CDC。各级局部capacity推进与独立tail不同于纯函数循环次序。

对应：完整图以job三ID/中心坐标逐lane逐位比所有真实阶段；M/G8/S/D/Ninput/NW/class/启用grad均有明确schema、期望rows=P，完整正常各必需口计数P。retain0 grad为NOT_REQUIRED/valid/count/EOF0。失败仍用完整数学oracle比真实已交付合法前缀，错误导致未交付后缀作废，不将其补零或称完整；同步rst旧job无CS/完整数目期待、恢复重新从0。主动typed故障有独立fixture oracle/豁免字段而非伪图像PASS。

### F2. 独立结构和有限成本

| 对象 | 当前结构/条件预算；不得当实测 |
|---|---|
| RAM唯一实例 | 原FE8 + Gaussian8 + newS window4 + NMS8 =28 RAM10结构上界；同FE源码多实例≠同RAM。原FE固定Y_ONLY可合法裁剪无用F4/历史，必需M路径/新S不可删；K无全帧RAM，无DDR |
| 逻辑历史 | G 4×960×16=61440bit；newS 2×960×16=30720；NMS 2×960×32=61440容器bit；FE两窗口61440bit为独立结构，不将有效bit等同28块名义286720bit |
| DSP/LUT/FF | DSP0设计目标；总≤22000XLR候选（FE6000/R2流段7000/C02500/SRC-J-K-reset-LED6000/余500）。D4的22逻辑hotbit及marker/address mux纳R2项，不免费；实际FF/LUT/ADD/SRL/packed XLR各报，不把R1的3411与本预算相加重复计FE |
| 副本/held | C0 CS592+K shift608+terminalCS592+lastCS592=2384bit职责不同；另ctx142/FS163/FJ110/DERR120/统计/游标/flags/流水/pending等按真正实例合账，2384不是全FF预算；不能扣掉已借用ctx或用cold正文当FF已省 |
| CRC服务 | 正常retain1 R=2P+1=2073601，连续20R=41472020沿=1.6588808s@25MHz；retain0 R=P+1=1036801，20R=20736020沿=0.8294408s。仅连续record服务，首填/尾/监督/额外停顿另计，不新增algorithm fps要求/不证明1080p60 |
| fault成本 | 生产bad输入接受518402，Msrc≤518401；后续口拓扑前缀受调度，R≤2(P+1)+1作超时保守候选，不能假固定CS或强交付P |
| 黄金I/O候选 | fp/msrc/g8/s/d/ninput/nwindow/class/grad每pair(含LF)20+36+36+48+49+40+104+33+48=514B；每HD完整9文件≤532915200B；8不同HD job≤4263321600B，retain0可免grad但不依此省预算；真实TOP-HD复用k0黄金，不重复生成 |

源可暂停、当前无生产frame缓存/transport服务承诺。模型逐job生成/写出/释放，不一次保留8图；TB文件流式逐stage读取，不把8M完整图放SV RAM。计划vectors总预算6GB、所有run日志/WLF/冻结与工具产物另预留10GB，启动前记录磁盘可用空间是否满足16GB；不足则明确环境失败，不删旧run凑空间、不悄缩图。Python内存真实峰值未来记录，单job完整tuple/新阶段结果不得无证宣低内存；缺内存/I/O失败保留INCOMPLETE。

### F3. 工具、四pin及约束

现装Questa2024.1 win64 alias=`C:/Users/34528/FPGAEdgeLinks/Questa2024_1/win64`，Efinity2026.1.132 alias=`C:/Users/34528/FPGAEdgeLinks/Efinity2026_1`，Python现装D:/py___/python.exe。这里只读既有R1路径/报告，不启动工具探针；获批每run保存实际版本输出/命令/退出，版本漂移回基线。仿真vlog采用SV/原模型默认1ns/1ps（不改vendor源），局部功能10ns、真实外壳40ns，仿真10ns不证明100MHz实现。

生产project Ti60F225/I3/SV2009/top r2_algorithm_top/W1920/H1080，单clk25MHz，无PLL/CSI/DDR/UART/HDMI/额外pin。J2 GPIOL_P_08_CLK1_P，bank1A/1.8V/GCLK；P13 GPIOR_27 BR3.3V/key低有效/板上拉，peri pull none；N14 GPIOR_21/P14 GPIOR_22 BR3.3V/输出drive4。沿实际R1 schema包含零实例pll/osc/lvds/jtag/mipi registry，不复制其业务实例或旧外壳。

KEY最初低≥4core沿，shared reset stage1/2异步清0、同clk两沿释放，各业务仅同步高rst；不依赖FF上电值、不整片reset RAM。新top保持reset实例名reset_adapter，SDC建立clk_25m40ns；post-map逐查stage1/2 `~FF|SR`各恰一且连接key，只有KEY→两SR false_path，stage1 Q→stage2 D、stage2→core所有正常计时。LED静态无外部采样clk，只有led0/1两个pad端例外，正常内部到LED逻辑仍核扇出；无全reset/core例外、无虚拟0ns IO、无CRC multicycle。LED0=lastvalid&&complete_ok；LED1每250000沿enable推进CRC bit，18bit计数/5bit索引，不造派生clock。实际post-map名字不匹配必须失败/查回，不能空collection宣布PASS。

## G. 有限实施与验证计划（全部NOT_RUN）

### G1. 权威套件、参数、身份及场景数量

未来manifest schema1、状态最后COMPLETE、suite仅r2-stream-v1/r2-observer-v1；下面186+44=230必需仿真case，加12输入校验/3故意fatal探针=245评估记录。每case_id唯一，区间/笛卡尔表展开顺序就是固定清单，runner必须读取并核完整manifest的required IDs，不硬编码仅少数成功case/仅筛选后称全套件。诊断筛选明确PARTIAL；子场景/恢复job另记真实计数，不当一条PASS掩盖。

除OBS/HD按k身份外，其余case按下表顺序n从1递增，epoch=2、frame=n、config=0x10000000+n；恢复epoch2/frame=n+0x10000/config原+1。OBS-B/R默认锁k3（epoch1/frame=config3，median1/retain1/TL0/TH64），关闭grad的子事件用k0；耗尽案另锁FFFFFFFF，其余字段仍依k规则，恢复k0且新Run历史隔离；HD/TOP/SRC的k由表明确。n范围<4096，身份不回绕不重用；单位无需CJ的测试仍用这份逻辑sideband/ctx。数值随机源Python random.Random(0x431)，有限椒盐位置Random(0x1060)，协议LFSR初0x431、taps31/21/1/0，每下降沿更新；重复run固定种子与生成器hash。输入bit0/data sink bit1/另一支bit2/status bit3控制，任一路连续人为停顿最多8沿，已有held valid/payload不得因随机位撤销。额外指定phase/stall事件优先并记录hit；阶段未命中即超时失败，不用case名称代替实际phase覆盖。

| family / suite / 数量 | 确切参数与输入/事件 | 真正期望与比较职责 |
|---|---|---|
| U-G001…044 / stream /44 | 6×5常量0/255两案；背景0、9位置(0,0),(5,0),(0,4),(5,4),(1,1),(4,1),(1,3),(4,3),(2,2)×幅值30/31/32/33=36案；ramp16y+x一案；1920×5 ramp(x+16y) mod256一案；另4案分别在REAL末写/BOTTOM0首读/BOTTOM1首读/TAIL真实phase暂停8沿并恢复，前三用6×5 ramp，第四用0x431依行优先randrange(256)30值，再以独立0x1060生成器sample(range(30),2)所选两位置依序改0/255的有限扰动图 | 每组G8/坐标/marker/P比较，25项独立oracle；必须真实检查同bank读写/禁使能/旧pending一次。背景0脉冲(1,1)对中心(3,2)权重4×1，使sum120/124/128/132→G0/0/1/1作为舍入反例，不由角点clamp冒称同权；扰动图是单元数值覆盖，不宣全HD噪声统计/识别测试 |
| U-D001…049 / stream /49 | 8×5；10(X,Y)=(0,0),(1020,0),(0,1020),(128,53),(128,54),(53,128),(54,128),(300,300),(424,1020),(765,765)×GX/GY四符号组合=40案，每pair lane1取下一tuple/符号，M=absGX+absGY；另9案在第5pair分别GX−1024/GX1021/GY−1024/GY1021/M1531/abs和不符/lane1坏/两lane坏/DERR held8沿叠flush，其余pair用合法(128,53,M181) | 每案20pair/两lane方向、原梯度/M/中心对齐；9错误必须实际坏fire/不投D2/DERR定位与持有，错误消费前无新D1，flush不丢错误；每案后新合法job恢复 |
| U-F001…006 / stream /6 | 8×5，70bit非零两lane不同；六schedule：双ready/仅N先收/仅G先收/每支8沿停顿/同沿旧全部释放+新接受/retain0 Gready永久0；非正常flush在最后held期间另作为第4案子事件 | 各支实count与前缀exact、held不重复/不透传、新pending覆盖旧clear，关闭支0；真实flush旧fire照计、恢复完整 |
| U-NW001…012 / stream /12 | 8×6；图M循环0/255/256/1023/1024/1530及dir=(x+y) mod4，矩形外框200/内圈100两图×正常/随机stall/REAL末→REPLAY/REPLAY末→TAIL/EOF held/flush后无reset恢复六schedule | 24窗口pair/288低payload+side121 exact，高/低byte所有原语地址/同使能/无collision，外框原幅值未提前抑制；各phase真实hit |
| U-NC001…024 / stream /24 | 8×6窗口fixture，四方向×6profile：M0邻0 TL0/TH0；M10负0正10 TL9/TH10；M10负10正0 TL0/TH9；M100负200正0 TL99/TH100；M256负255正256 TL255/TH256；M1530负1023正1024 TL1530/TH2047；每案含外框坐标和内圈，两lane分别用当前/下一循环profile数值，但两lane都使用该case的同一TL/TH快照，EOFlast阻8沿 | 每对class exact、中心>N−且≥N+、threshold恰等/平台/边框抑制，strong/weak只fire；包含none/weak/strong和TL=TH无weak；高字节不被截断；N1/N2持有/EOF后empty |
| C0-C01…C0-C21 / stream /21 | 原C0§8逐个完整保持：4×3+TL>TH；ARM cancel；heldFJ cancel；FJfire cancel；bad；missingEOF；早FS/尾held；cancel+FS0+class；retain0；D1bad+旧fire；empty缺count；wrongFS；先DERR后FS1；CS held+cancel；换job旧源；rst；多错；FS同末FO；heldFS1+首次cancel；持续cancel；rawcoords越界 | 合成子级端口fixture可精准排程；CS592/FS163/优先级/mask/位置/真实八口count/旧fe_cancel_sent按独立ledger；每案正确恢复。并不把合成FE信号当实际FE工具/数值证据 |
| MD001…024 / stream /24 | 8×5真wrapper；raw G8第5pair分别odd x1/x2047/y2047/提前EOF/提前EOL/wrong epoch xor1六变异×普通/ready停8沿/同fire cancel/同fire rst四schedule | D4真实cursor及原语地址仍合法；普通/停顿以原raw位置报13/14/12；cancel同沿first1且原错入mask，旧真实fire保留；rst无fire/no CS；所有案后同DUT完整新job恢复，不能canonical后丢原错 |
| HD001…004 / stream /4 | 固定1920×1080，k0/5/10/15，均fault0，median×retain分别00/10/01/11；四OBS公式ramp/vertical/horizontal/checker，TL/TH均0/64；另外协议固定0x431与有限停顿 | 实际SRC+C0+FE+G/S/D/FK/N+K，TB合法CJ driver替代外J；每stage两laneP full比较/三ID/marker/EOF，class/启用grad真record/独立CRC及CS0/flags1；4×2073600像素不是小图代替 |
| HD-F001…002 / stream /2（各2job） | 同生产尺寸，实际SRC k64/66 fault1（median0/retain0或1），真正bad r540/q1；真实CS/CRC结束后不reset，由合法外CJ driver分别k128/130 fault0新job恢复 | fault精确RGB518402、原FS2/真实CS5/mask32/loc/八口拓扑/EOF0/独立K统计/fixture1 complete0及短前缀数值；后续恢复完整P/CS0/数值/CRC。不得只用typedfixture代替真FE in_bad/FS/C0结束 |
| OBS-B001…014 / observer /14 | 6×5 typed fixture：CLASS11/GRAD高pad非0/GX1021/wrongID/oddx/wrongmarker/P+1/CS wrongCJ/CS wrongcounts/CS+data并存/末CRC chunk非0/双持续data公平/早失败CS/CSheld8沿 | 故意错仅声明字段豁免，其他payload/608/CRC/实count照比；sticky发取消仍接真fixture CS，原码保留/flags0，20沿capture间隔/rr-fire/CS优先；P+1第一多余组计真实且停止新data |
| OBS-R001…024 / observer /24 | 6×5：capture reset1案、19个chunk各reset1案、CSheld reset1案、terminal_done reset1案、KEY初始≥4沿及两级释放1案、kFFFFFFFF耗尽1案 | rst所有fire0、旧record/last/err/job撤销、新完整job正确；19chunk确切phase hit，无漏末新CRC；k末值用J单元合法初始化fixture检查耗尽，不改生产reset k0、不force业务FS/CS/done |
| SRC001…004 / observer /4 | W258/H258实际SRC四pattern，用k0/4/8/12配置；运行中外cfg变化、ready随机及奇半幅129 | 全33282pair/48RGB/坐标/flags比较，x31/32/128/129/255/256及相应y全部覆盖、held不变，不把模256规则外推算法溢出 |
| TOP-S001 / observer /1（128job） | 真r2_algorithm_top静态6×5，从k0连续完整到127；另在首次k5 CRC忙期间KEY low≥4沿后重启k0，重新计完整128job | 真J/SRC/K/FE/C0生命周期及全部k配置/64正常+64fault/错误后继续、独立flags/每条CRC/原FS/CS及新历史；被reset的旧job另标ABORTED_RESET不充数 |
| TOP-HD001 / observer /1（1job） | 真未改默认1920×1080/40ns生产r2_algorithm_top，从reset k0完整；数值oracle复用HD001输入/期望 | 真实J+SRC+K全路径P/CS0/CRC/LED/终态后续J沿；不以TB外CJ driver替代这项。生产k64未在真J序列中跑，覆盖边界明示，由真top小图J与生产真sourcefault组合证明 |

MD只在TB既列top测试内部对**真实G8 candidate的raw metadata指定字段**作受限测试注入：下降沿在第5候选形成前锁变异，等待期间保持，实际fire后NBA观察完成再释放。不得force clock/ready/valid/C0state/计数/FS/CS/done；不添加生产test端口/改DUT算法源。其余内部错误用C0单元端口fixture，真整图math不得靠内部force通过。OBS-R耗尽是J组件入口状态初始化的专用单元fixture，必须标范围；真top k0reset规则不改变。

两套件另共用V001…012输入/I/O校验：bool整数、oddW、4×3、TL>TH、通道256、signed超域、短file、长file、uppercase/非法hex、X/Z、非零高padding、path绝对/..或已有目录（最后案逐子事件分别拒绝）；P-FATAL001…003分别三个代表TB（G、wrapper、observer）故意fatal，预期工具非零/无finished成功JSON。它们是故意失败监测探针，不记为算法230case普通PASS，也不能未运行便放过退出码判断。

### G2. 向量/结果、timeout和wall政策

严格UTF-8无BOM、ASCII小写hex、无0x/空白、每行一pair/精确digits/行数/EOF，高padding0；kind/digits为CJ142/36、FP74/19、M/G137/35、S187/47、D191/48、N153/39、NW409/103、CLASS125/32、GRAD185/47、DERR120/30、CS592/148、record608/152。每file{schema,bits,digits,rows,sha256,path}；rows明确正整数，optional NOT_REQUIRED不写空文件。向量限新run/vectors，安全RunId/relative path拒..、绝对或越界，manifest最后才COMPLETE。先完整严格审文件再仿真；审了P行不等实际比较P。

成功expected_pairs=P；fault预声明terminal_policy/注入/允许前缀0…P+1、expected_pairs=null仅指不强求完整硬件输出，所有已声明完整oracle rows仍P。真实bad停止前合法输出逐stage独立按坐标比完整oracle；故障CS用沿前fire独立账算规则而非固定hex抄DUT。组件CS/record fixture才有固定逐位hex期望；reset旧job单列不要求CS，恢复黄金新身份不改旧文件。

每case结果至少schema/case/suite/W/H/三ID/config、各口accepted/delivered/compared/EOF、class/grad及strong/weak、实际FS/CS/原因/mask/loc、numeric_errors/protocol_errors、required_event_hits/phase_hits、stall/hold检查数、实际RAM read/write/范围/collision、record/CRC checks、reset/cancel/source_stop/restore实际次数、cycles/finished/tool_exit。通过必须所有必要比较量达到声明、errors0、所有事件命中、real terminal与正常/预期失败关系正确、source/黄金before=after；没有字段/null/缺日志/短前缀不足/仅PASS字符串都FAIL。错误case故意注入字段只按其明确oracle判预期，并非允许其他协议错误。

有限cycle失败监测政策（不是RTL自动超时、不是已证明最坏延迟或algorithm fps）：

| case类 | 从首活动/驱动开始的模拟上限与wall deadline |
|---|---|
| 单元/G/D/F/N、MD/C0 | C=8192+128D+128T，T为manifest实际输入fixture组数含恢复；外ready拒绝最多8沿/事件，必须满足；每case wall15min |
| 不经过K的wrapper诊断 | C=16384+256D+128P×job_count；每case wall30min；生产不作为最终OBS证明替代 |
| K/SRC/J/top完整或fault | C=32768+128D+48R_limit+16P×job_count；R_limit对正常每job=P(1+retain)+1，fault保守2(P+1)+1；128小job逐job相加，warmup/reset候选另按同式加已计划7job成本；每小case wall30min，每HD或HD-F（2job）wall4h |
| 模型/编译/物理 | 每套件模型wall60min、vlib/vlog/vopt各15min、Map/Interface各60min、Pnr/STA各120min、Bit30min；超时保留真实handle/终态及已形成产物，未启动依赖标SKIPPED_DEPENDENCY |

连续retain1记录20R约41.47M沿，所选K正常C约116.3M沿（4.65s模拟时间）有启动/尾/监督/有限停顿余量；选48而非20是明确失败监测余量，不能宣数学上界。故障不等P/EOF，fault C虽保守仍有限。临时工具慢或环境不足超wall按TIMEOUT/NOT_COMPLETED报告，不能偷偷加大/缩图到PASS；确需改变政策回本卡范围与审阅，不要求批准前跑完未来measurement。

### G3. 获批后的推进与真实判断

①核指定R2批准/新baseline/审计条件/当前Manifest、所有来源hash与目录→建新r2/sim/r2/runs/RunId或build/runs/RunId；不覆盖旧。②先独立数学自检/向量严格预审，再vendor+共享FE/reset仅一次编译、包/局部RTL/TB展开。③U/C0/MD小组合先暴露功能错误；随后两套件230case、V/P探针和四生产全图/真sourcefault恢复/真top生产全部必要数值证据。④每run保存实际.do宏，onerror非零；-onfinish stop配onbreak读取本TB finished，仅明确1且JSON已关闭才正常quit，fatal探针确认，不把$finish/$fatal都当0。⑤生产Map→Interface/PT→Pnr/STA，与仿真同冻结源码核；必要仿真完整才能开Bit gate。

进程级许可仅沿用已有本机配置：Process MGLS_LICENSE_FILE空时可临时继承已存在User设置，不读/打印许可文件或值、不改User/Machine，finally还原Process；工具环境按现装setup对子进程，不安装/联网/换key。每工具argv逐项传，不拼字符串交第二shell；具体未来CLI意图是run_r2_sim的RunId/Suite/可选诊断筛选和run_r2_build的RunId/Prepare/Map/Interface/Pnr/Bit阶段，本文没有生成执行脚本或声称命令已运行。

物理PHY-T01核20源码/生产参数/无blackbox/latch/multidriver、map分层RAM/FF/LUT/ADD/SRL/DSP；PHY-T02读PT/pinout四球/bank/GCLK/电气；PHY-T03有效算法→CRC→真实LED扇出、必要行历史与合法优化说明（28结构不能强keep/不能由CRC非零推功能）；PHY-T04真40ns setup/hold、all_clocks/no_clock/unconstrained_internal/multiple_clock和两SR集合/同步链定向核；PHY-T05全部必需结果/gate hash复核后pgm，明确同run真实work_pnr .lbf及periphery输入hash，不给空work_pgm导致exit0但跳过。bit/hex均须实际存在/非空/hash，原日志包括警告均保存，登记后停止硬件动作。

人工软件观察在获批后一步步记录：Questa先开一个G REAL末写/BOTTOM首读小图WLF，看phase/pending/RE/WE/address/first-last；再MD坏raw→canonical合法地址→C0mask→次沿flush，检查旧fire；再fork两支held与K capture/e1/e19/newcrc/last/done；Efinity打开新project确认Ti60F225/I3、Production1920×1080、四pin→层级算法/真实原语→STA例外与内部路径→产物。WLF仅小图关键沿，fullHD不log全RAM阵列；原文件只读、新查询日志独立保存。实际工具采样/Root读回与用户理解验收各记，未回答不能声称用户已理解/板上观察通过。

## H. 初始双向追踪

| REQ/来源 | MOD与IF/局部不变量 | 计划文件/稳定责任 | 必需TEST及期望来源 | 现实际代码/证据 |
|---|---|---|---|---|
| SI01/R2-REQ01 | C0/FE/G，全中心P/原始身份，IF01…03/E1/2 | top/controller/gaussian；job_snapshot/pair_counts/phase | U-G/C0/HD/TOP；二维oracle/C0旧事实 | R1六SV只读实际hash；新R2待实现/NOT_RUN |
| SI02/R2-REQ02 | G单舍入/四行/无collision | gaussian/stream_reference/vectors/tb_G | U-G44/HD；25项/120…132反例 | 候选G-W结构，NOT_RUN |
| SI02/R2-REQ03 | newS/F4诊断同组/D1检查/424方向 | top newS +sharedwindow/F4/direction/tb_D | U-D49/HD；signed二维式/边界 | A2真实F4能力已核，不是R2功能PASS |
| SI02/R2-REQ04/05 | 原幅值NW/N1N2/严格TLTH | nms_window/classify/reference/tb_NW/NC | U-NW12/U-NC24/HD；直接邻居oracle | NOT_RUN |
| SI03/05/C0 | 唯一FE owner/真实FS/DERR/八口/firstmask/CSheld | controller/top/pkg/tb_C0 | C0-C01…21/MD/HD-F；原C0§2…8 | 新scope明确适配；NOT_RUN |
| SI05/源码deltaD4 | raw观察不抹错/canonical寻址/22hotbit/fire同事件 | top s_input_q/row/done；tb_top metadata fixture | MD24及C0-C21，odd/2047/EOF/EOL/ID、stall/cancel/rst | 实际windowL35/117…119只读依据；未改共享源 |
| SI03/05/R2fork | 一held/两pending/retain0/沿前旧fire | fork/top/tb_fork | U-F6/HD/HD-F；独立分支ledger | NOT_RUN |
| SI04/OBS01…03 | 三typed/608/19chunk/CS优先/rr/sticky/flags/last | source/J/K/pkg/observer_reference/tb_observer | OBS-B14/R24/SRC4/TOP-S/TOP-HD/HD-F；逐bit真实序CRC/独立终态规则 | NOT_RUN；R1160bit不可复用替代 |
| SI06/FILES01…03 | 严格manifest/行数/hash/有限cases/实际comparison | 三model/十TB/run_sim | 全230+V12+P3；FILE schema/真实账 | 31新文件仅计划，无新业务文件 |
| SI07/OBS04/05 | 四pin/reset/40ns/内部计时/真正产物 | top/LED/sharedreset/三个project/run_build | PHY01…05/OBS-R/TOP-HD；当前实际R1schema只作来源 | R1物理bit是真事实，R2 PHY全部NOT_RUN |
| SI08/规范10.3(8) | 未来scope隔离/不冒称闭包、RC、生产fps | 本A3/I/J/交付范围 | 独立设计审阅及最终范围核对 | R2-B03/R4/R5等仍OPEN |

反向C表31文件及七共享RTL均对应上述责任：包只schema、三model互不替代、两runner各对应工具/失败规则、project各电气/语言/约束、每TB有局部真实事件或端到端职责；没有无关新增模块。实际symbol/源码hash/JSON/WLF/report/bit路径只在获批真实落盘/读回后回填交付实录，初始追踪不能伪造行号或测试PASS。

## I. 门槛与独立评审入口

①B整体/具体正常与真fault；②C全职责/现有FE实际调查；③D位宽/保持/接口/新安全适配；④E整体→局部中文步骤/旧沿微时序；⑤F语言三合同/A–L已由D/E/F对应；⑥B/E及G各成功/失败走查；⑦G有限实施/245评估与H初始双向追踪；⑧A3未来隔离但SI-B01…03待审阅/冻结/授权；⑨本卡保存后需实际全文读回并向Root呈现；⑩A2/C当前版本/范围/实际候选输入。

本v0.1为**NOT_READY**独立审阅输入，不能自签十项全通过。Root审阅可在同一卡后续指定版本修正当前设计遗漏/形成READY并冻结新baseline；此处不以未来measurement当批准前置，也不自行写审批manifest或提权限问题。原R1/旧R2卡、控制面正式状态与数据库保持。

## J. 变更、恢复与差异说明

相对旧R2/R2-FILES：仅新scope隔离B03与完整包、纠正当前R1时态、绑定8实际复用文件、D4 caller安全delta、闭合当前31文件/端口、230+15有限套件及timeout/物理方法。数学/142/120/592/608布局/20沿CRC/四pin25MHz保留原合同；D4新增22bit状态和选择逻辑明确计，不把旧window假定为本地寻址。没有修改旧sources/hash/实际R1。

恢复先读本卡最新获批版本/新baseline/真实范围与当前Manifest，再核共享源/模型/工具/schema、真实run结果与未执行依赖。数学/位序/owner/来源隔离/cursor/取消/时间/生产pin或新文件范围变化回REQ/IF/E/G/H修订审阅，不凭内部优化默改接口。合法参数实现细节若不改合同，仍更新中文草图/实际追踪并记录真实最小差异。

## K. 本轮实录

本轮仅只读文档、实际6 FE SV+reset全文、frontend_reference限定纯接口、R1工程/已存在非空产物hash及候选来源核查；新写本卡。没有业务源码、模型、功能脚本、TB、可执行向量、仿真/build/bit、网络/硬件/数据库或正式状态改变。R2全部功能/工具测试NOT_RUN。最终本文全文读回与SHA/bytes由交付消息报告；不在正文自引用自己的hash造成循环。

## L. 交付与阅读说明

本卡交给Root的具体审阅对象是当前流段/OBS实施设计，不是完整十一项已经完成的答案。用户可从B理解每次输入/输出，再C定位文件，D理解交接和D4原始/安全坐标区别，E逐级看旧状态→新提交，G知道何时比较及失败处理，H回查需求。批准后按此顺序逐模块生成/人工软件观察记录/数值与协议验证/物理审阅，并以同一冻结证据取得真实产物；未完成范围和测量失败如实并列。bit后的实物步骤仍由人工节点，不越过硬件闸门。
