# R2 OBS：完整记录、CRC与独立工程草图 v0.1

2026-10-04。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。附属于[R2 v0.2](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)，拟关闭R2-B04的独立流段工程部分；保存后须独立审閱，当前不提前关闭B04。完整十一项、摄像头/HDMI接入、全帧闭包/识别仍由完整包推进，不能由本四pin工程替代。

## 通用计划字段

- Goal：生产1920×1080 R2流段的class125、grad185及CS592都形成真实可观察record/CRC/计数/pad扇出，具备独立Efinity实现条件。
- Current state：C0终态附件已实际双路审閱，尚无本次业务代码；R1的160bit记录不能容纳新终态。
- Target state：固定608bit有类型记录、19沿32bit分组CRC、有限监督器/源、四pin25MHz工程/约束、独立黄金/协议验证及生产网表检查。
- Gap：本稿待审閱；RGB/控制/显示B03、完整基线/文件合同B05、整包/全帧集成仍缺。
- Assumptions：同core域、可暂停规范源；器件Ti60F225/I3；R1所选四pin软件资料基线，不宣称实物确认。
- Open questions：实际综合资源、32步CRC组合链40ns时序、现有许可/命令/工具结果尚待获批测量。
- Dependencies：[R1 v1](../../../planning/design-TRACK4-ALGORITHM-R1-001.md)D/E4/E5的四pin/复位/SDC边界；[C0终态附件](canny-stream-controller-sketches-v0.1.md)全部新接口。
- Milestones：本稿读回/协议及数值审閱→B04相容性→完整包批准→代码/全图/工程/工具→bit登记。
- Detailed steps：整体→记录/交接→源及监督→CRC/arbiter→复位/工程→语言/测试/追踪。
- State transitions：只在R2文档记设计状态，不动正式H0/数据库；未READY不提实施请求。
- Artifacts and hashes：后续候选基线与审阅绑定本稿实际hash；产物只进入批准work及staging。
- Validation：逐像素数学与record/CRC独立oracle、真实事件、PT/map/PNR/STA分别核查；CRC不同可检错，CRC相同不能证明图像正确。
- Failure handling：真实CS保存；功能失败进入ERROR，保留日志；设计变化回核版本，不缩小生产图。
- Human approval gates：完整软件包成熟版本/范围/基线；数据库前置或明确本地审计例外；bit后无实体步骤。
- Rollback：仅控制面新文档/批准独立work；原HDK/R1/FE/正式状态保持。
- Completion criteria：文字合同读回审閱无当前工程设计缺口；实际交付仍须OBS-T01…09执行证据，当前均未运行。

## A. 先看用途和路径

SRC规则源/J监督 → CJ142/FP74 → 真实FE+G/S/D/FK/N/C0 → CLASS125/GRAD185/CS592 → K记录/CRC → last_result快照 → LED。C0是R2内部FE唯一owner，J只提出外部CJ，不直接消费原FS或控制原FE。J将CJ真实接纳事件同时交给SRC/K初始化；C0仍按ARM/FJ/首FP分沿。

输入可反压，K忙时只降低被观察输出ready，独立处理旧record。不能等源输入全部结束才接受class/grad；否则窗口/分叉会与源互等。图样源不存整帧。生产工程参数固定1920×1080，归档所有生产map/PT/PNR/STA，不能用小测试参数代替。

OBS-REQ01：每个真实class/启用grad fire恰一record；CS真实接受也是一record，包含完整错误/原FS/计数信息。
OBS-REQ02：所有record类型、长度、位序、初末CRC与最后32bit提交确定；生成的crc不被综合成常量。
OBS-REQ03：正常/提前失败都接纳CS，不以P/EOF阻status_ready；正常完整OK与故障注入“符合预期”分开。
OBS-REQ04：真实四pin、40ns和复位例外准确，全部有效内部路径计时；0DSP/28RAM等只是预算。
OBS-REQ05：独立逐位/事件/全图/真实工具验证；bit后登记停止，不下载。

本实验输出速率由观察器限流，不是生产视频fps，也不把class当完整Canny边缘。显示至少60Hz和相机不可暂停源的容量证明仍在R5，不能从本源可暂停性推出。

## B. 有类型608bit记录与端口

所有payload同clk上升沿，rst高屏蔽全部fire；valid/ready另算。K一次只能拥有一record；空时只允许一类输入ready，busy时全ready0。typed端口与R2对应，不增加外部pin。

record[1:0]type，payload从bit2向高位放入，高端未使用位全0。类型0 CLASS：class125→record126:2，record607:127=0（481位）；类型1 GRAD：grad185→186:2，607:187=0（421位）；类型2 STATUS：CS592→593:2，607:594=0（14位）；类型3保留不产生。数学宽度为2+592+14=608，不截断185或592以沿用160bit旧格式。

CLASS/GRAD payload采用当前R2主稿的lane/sideband逻辑布局，打包low first：
CLASS：classes3:0、x_even14:4、y25:15、epoch57:26、frame89:58、config121:90、SOF122/EOL123/EOF124。
GRAD：grad64在63:0、x_even74:64、y85:75、epoch117:86、frame149:118、config181:150、SOF182/EOL183/EOF184。每lane32沿主稿Gx11/Gy11/dir2/高8位0，lane0低32。
STATUS：原CS592低位字段完整复制，不交换或删除原FS错误坐标；layout见C0附件§2.3。零padding是明确规范，非有效算法位可被工具常量化，但有效M/gradient/class及终态计数须保留真实扇出。

| IF | 提供→使用/字段 | 接纳、保持和所有者 |
|---|---|---|
| OBS-IF01 | J→C0 CJ142；SRC→C0 FP74 | J held CJ到fire；SRC FP仅真实fire推进，C0共同valid/ready门控；来源归属按C0 |
| OBS-IF02 | R2→K CLASS125 / GRAD185 | 数据payload在等待时保持；一ready选择；实际fire计各自21bit pair/EOF |
| OBS-IF03 | C0→J/K CS592 | K空且J处于FEED/DRAIN时可接；不要求P/EOF。C0真实状态终结源，K保存完整原CS；J仅计算/锁检查flags，不存CS副本且不回写code |
| OBS-IF04 | J→SRC/K job_start与CJ142/pattern2/fault1 | 同CJ真实接受初始化；旧job的终态CRC完毕前不可再次start |
| OBS-IF05 | K→J terminal_done / fixture_match / complete_ok / crc32 | 第19处理沿用新CRC提交快照和注册done；J下一沿依据旧done推进 |
| OBS-IF06 | R/reset及LED/top | 四pin沿R1实际候选；全部同core域，只有KEY异步清零两级 |
| OBS-IF07 | K→J观测87：class/grad/strong/weak各21+EOF2+record_protocol_ok1；J→K终态检查flags2 | 87是逻辑并行字段总宽，不新增packed bus；两flags分别terminal_fixture_match/terminal_complete_ok各1。同域借用只在CS fire使用，旧K空时前缀已结账；flags在该fire锁入K，不影响CS ready，不构成计数到ready反馈 |
| OBS-IF08 | K→J observer_fault_sticky1；J→C0 cancel1 | 新data检查错误后置sticky，下一J旧事实向当前已接纳job发cancel直到CS；不清FS/CS原原因，不阻K状态接纳；共同rst或下job init清sticky |

## C. 有限源、监督与错误观察

SRC锁CJ快照、pattern2、fault1及q10/r11。J持k32和CJ held，状态START→FEED→DRAIN→TERMINAL→START，功能不符ERROR，序号耗尽EXHAUSTED。observer_fault_sticky出现时J只锁cancel_requested并向C0请求取消，保持FEED/DRAIN及终态接纳资格，不立即转ERROR；必须真实CS fire→TERMINAL→terminal_done且fixture_match0后才ERROR。只有终态CRC真实完成且fixture_match1才下一个job；k=FFFFFFFF完成后不回绕。reset清有效性和k=0，运行记录另用Run ID隔离历史。

epoch1，frame/config=k；median=k bit0，retain_grad=k bit1，pattern=k[3:2]，TL/TH由k[5:4]取(0,64)/(64,512)/(512,1530)/(1530,2047)。所有11bit配置合法且全job锁定。TL/TH上限不因幅值真实max1530缩成其他域；TH≥1530无STRONG但仍可能WEAK。fault=k bit6，因此k0…63普通完整图、k64…127对应提前源错误；其余高位只参与身份。

每lane图样沿R1四公式：pattern0 R=x mod256/G=y mod256/B=(x xor y) mod256；1按x<W/2黑/白；2按y<H/2黑/白；3按x bit5 xor y bit5取RGB各16/239。收窄只用于已声明图样mod256，不外推算法溢出。源地址不是RAM地址，无整帧ROM。

正常FP按q/r重建SOF/EOL/EOF，valid在FEED且未终结时展示。故障job仅在r=floor(H/2)、q=1的那个实际候选置in_bad1，其他字段照正常；坏组仍真实接受，fault坐标x=2，in_pairs期望floor(H/2)×D+2，先扩检查再保持21bit。H≥5、D≥3该位置总有效。固定fault不会被新的反压拖成多次；源停顿时bad也保持。

源最后FP真实接受使J进入DRAIN；C0 CS valid出现表示当前R2已终结，源撤未接受候选，不能等源自己到P/EOF才处理错误。CJ接受沿不提出首FP，C0更要求ARM/FJ分沿。旧源在CS消费/终态处理期间无资格发给下一job。

CS真实接受沿仅K保存完整terminalCS592；J读取当前CS和K观测字段计算“是否符合期望”，只锁检查flags/源计数及进入TERMINAL，不另存592bit副本。J检查flags同一次CS fire交给K锁定；其后不借C0已释放的ctx或外部CS端口，J只等待K真实done/flags。正常fixture_match须complete_ok；故障fixture_match须真实reason5、mask只有bit5、完整CS.CJ142等J锁定CJ；fe_started/fe_status_seen/stream_started均1、cancel_seen0；第一定位loc_valid1/stage1/lane0/x2/y=floor(H/2)。原FS code2及三ID正确，raw error坐标同上；CS.RGB=SRC实际接受=rawFS.in=floor(H/2)×D+2，CS.Msrc=rawFS.out且≤RGB−1。其余拓扑关系0≤class≤NMS_in≤Direction≤Sobel≤G8≤Msrc、0≤grad≤Direction；CS八口observed EOF全0，因为固定半帧故障未到P，这不是所有失败的通用规则。record_protocol_ok1，K独立实测的两支组数/EOF/strong/weak分别等CS对应字段、strong+weak≤2×class（扩22bit）、grad关闭支所有事实0。K只独立实测class/grad，其他口是SRC/rawFS关联和CS拓扑一致性检查，不冒称八口全部由K观测。故障不要求P/N/EOF，不伪造最终边缘，也不把它算complete_ok。

complete_ok要求真实reason0/mask0、全部启动事实/FS_seen1、cancel_seen0、规范无位置loc_valid0/stage15/lane/x/y0、锁CJ与J完全一致、原FE code0/ID/P计数及raw error_x/y0、七口P及EOF7F、启用grad时该支P/EOF1否则0、strong/weak≤N且等K记录class统计、K record_protocol_ok1，class/grad组数及EOF分别与CS同口事实相等、源完整末EOF真实接受、J旧DRAIN。正常CS若ID/计数错则fixture_match0，不改CS原码。故障检查只验证失败协议相符，逐图数学另靠参考。

## D. K仲裁、记录与CRC32操作草图

K拥有record_shift608、crc32、chunk_index5（0…18）、busy、held_type2、终态检查flags/CJ/CS快照、class/grad各21bit计数/EOF与各自q10/r11游标、record_protocol_ok1、strong/weak各21bit统计、round_robin1、terminalCS592独立影子、lastCS592完整诊断副本、last_crc32/last_complete_ok/last_fixture_match/last_result_valid及最后CJ身份。初始busy0/CRC=FFFFFFFF/计数0/lastvalid0/rr0/observer_fault_sticky0。

OBS-OP01 初始化：CJ fire且旧K空、旧终态CRC已结账时锁新job并置crc=FFFFFFFF、计数/统计/EOF及各游标0、record_protocol_ok1。last_result单独保留上一个完成快照到reset或下一终态CRC完成，不能被新job init半写。

OBS-OP02 仲裁：J旧FEED/DRAIN且K旧空时，若CS valid，则只status_ready1，其它ready0，先接受真实终态；不要求P/N/EOF或normal_good。正常C0 STATUS保证私有数据valid0；typed组件测试若CS与data valid共存，仍接CS并把fixture_match/complete_ok置0、记录协议不符，不等永远不会消失的data才接终态。否则仅record_protocol_ok1且observer_fault_sticky0时在class/grad间仲裁：只一方valid则选它，两方都valid依rr（0 class/1 grad）；只有实际数据fire后rr指向另一支。retain_grad0时grad ready/valid/计数/EOF均0且不读父grad_ready。没有data valid时不更新rr。

OBS-OP03 捕获：选中真实fire沿按B打包608bit并置busy/chunk_index0，class/grad对应pair数与EOF/strong/weak贡献增加；有效payload完整保持在record_shift。该沿不处理新record首32bit，不从仍变化的R2端口直接算CRC。每个data fire同时用该支独立旧q/r核三ID/中心/SOF/EOL/EOF、合法payload及不多于P，更新该支游标；错误只清record_protocol_ok，不伪造CS原因。CLASS每lane须非11；GRAD每lane高8位0、Gx/Gy分别signed11且−1020…1020。计数/统计用22bit临时检查；首次多余组P+1仍作为真实fire计入并使record_protocol_ok0，至多2(P+1)统计，可由21bit表示。任一data协议错误后置observer_fault_sticky且停止接受新data（K不取消当前recordCRC），保持有限错误账本；下一J沿据旧sticky发C0 cancel，使真实CS仍能结束，不等待已停止的data。CS接纳始终独立于record_protocol_ok。非法class11 lane不计strong/weak，不依赖持续异常源也会自行停来保证不回绕。status fire锁检查flags与原CS，不先改last_result；每record只计一次。

OBS-OP04 分组CRC：随后19个core沿，每沿取旧record_shift[607:576]的32bit，按bit31→0依次做非反射CRC32：临时c始于旧crc，每bit取c最高位xor输入bit，左移1（明确mod2^32），若xor1则再异或04C11DB7。32步是有限组合运算，第32步结果才在该沿寄存到crc；record_shift左移32补0。index0…17只递增；index18使用计算的新crc，不取旧crc漏最后chunk。

每条record输入顺序是bit607→0；whole-job CRC覆盖真实接纳的所有CLASS/GRAD按仲裁实际顺序，最后STATUS record。初值FFFFFFFF，最终xor FFFFFFFF。CRC随数据仲裁顺序可能不同，黄金预期必须使用真实record顺序，不能以class全图在grad前的静态串联代替。全图逐像素结果则独立按job/x/y比较，不依赖CRC序。

OBS-OP05 结束：index18沿清busy；普通data record无final xor、不重置CRC。若held_type STATUS，同沿将新crc xor FFFFFFFF提交last_crc，原CS及flags一起锁last_result_valid，并产生terminal_done注册脉冲；J下一沿处理，不能在这一沿用新done启动下个CJ。下一record最早在旧busy已0的下一沿接纳，接受间隔≥20沿，不在最后处理沿同时换record。

CRC结构固定608bit移位寄存器和32步组合网络，避免按巨大可变index读取608bit导致宽mux。不是把608bit每沿全展开，也不是32bit“字节反射”CRC。接口可综合SV2009合同，不在批准前写循环实现。32步组合40ns能否通过须真实STA；不能仅由clock-enable/低接受率新增multicycle。

## E. 走查、吞吐与资源预算

| CASE | 事件与预期 |
|---|---|
| OBS-C01 | class held且K busy：ready0，payload保持；CRC仍19沿独立推进，输入FP可以被反压但不会冻结CRC |
| OBS-C02 | class/grad持续valid：每次真实接纳后rr切换，至多隔一个其它data record服务；阶段仅一方valid可连续收 |
| OBS-C03 | 最后class/grad接受后C0真实CS出现、K仍busy：CS held；最后data chunk完成后下一沿接CS，不等第二次P检查 |
| OBS-C04 | fault在半帧in_bad：原FS2/CS5，前缀record先CRC完，再接STATUS；完成失败CRC，LED0熄但fixture_match1可以继续 |
| OBS-C05 | CSR code0但wrong CJ/计数或typed共存data valid：原CS保存、good0/ERROR；不改为假source错误或空成功 |
| OBS-C06 | reset在捕获/首chunk/第19chunk/heldCS：全部fire0，旧record/CRC/done/lastvalid清；新job全图从新历史开始 |
| OBS-C07 | 最后chunk输入非0：新crc提交与独立逐bit608参考相等；用旧crc必须测试失败 |
| OBS-C08 | grad关闭：不输出/接伪grad，不等它的EOF；只P个CLASS和一STATUS |
| OBS-C09 | k最后值：真实终态CRC完成后EXHAUSTED；不wrap到0，不重用尚有ctx的身份 |
| OBS-C10 | e0坏data真实接受/record捕获/sticky1；e1 J据旧sticky请求cancel并仍FEED/DRAIN，K处理chunk1；C0依真实条件flush/收FS并形成CS；K到e19完成坏record，随后空时接受真实CS→TERMINAL；再19chunk及下一J沿done后才ERROR。不能在e1关status_ready |

608/32=19处理沿，capture另1，服务间隔20沿。生产retain_grad1为2P+1=2,073,601条record，服务预算约41,472,020沿/25MHz=1.6588808秒；关闭grad为P+1，约0.8294408秒。逐bit608方案间隔609，grad开启约50.51292036秒，因此本稿选择32bit组优化观察开销。以上是连续服务预算，源/窗口首填充/停顿/监督额外沿另算，不是实测fps，更不能表示60Hz或核Fmax。

核保持2像素/局部推进拍结构，CRC观察限流与核本身吞吐分开。物理25MHz同域；10ns TB可检查协议但不能证明100MHzSTA。后续完整视频通过缓存/重放/输出适配进行资源与性能优化，不把低速fixture当最终实时成品。

预算：FE8+Gaussian8+新S窗口4+NMS8=28块RAM10，不含完整闭包/识别/RGB帧；本OBS无需额外RAM/DSP。必须区分物理保存：C0自己的CS592、K的移位record608、终态不可变CS影子592是三个职责不同的副本（1792bit预算）；STATUS接受后C0可以释放旧ctx，K在第19chunk只用独立保存的CS/flags/tag提交，不能从已移空record取字段。最终lastCS可由这份不变影子作为完整快照持有到下一终态接受，但新job期间不会覆盖lastCS；若提前捕获下一终态，旧last必须另备592bit或只保留明示摘要。本版选择另设lastCS592，故C0/shift/terminalCS/lastCS共2384bit，纳对应C0/OBS预算。

全独立流段目标≤22000XLR，其中原FE≤6000、R2流段及sideband≤7000、C0监测/状态≤2500、SRC/J/K/reset/LED≤6000（四项合计21500，另留500余量）；总是提议预算，非实测。32CRC展开所需LUT/FF及608移位寄存器纳最后一项；不能将bitrecord数作为RAM片估算。

防裁剪检查：真实生产map层级、各必需行历史的有效容量、Gaussian权重/新Sobel/方向/NMS/class比较和FK支路；28 RAM是未优化结构上限预算，FE固定Y_ONLY/T0的原Sobel边缘/未用邻居及相关RAM可以合法优化，不能要求精确保留原R1全部FE结构；全部有效class/grad数值/坐标字段到CRC再到真实LED路径可达，完整CS计数/错误/ID按fixture可达分支和typed协议测试分别覆盖；typed测试不能阻止物理tie-off造成的合法优化。允许无用padding/常量epoch/被明确tie-off的未用外部控制分支被优化；不能用keep属性、RAM数目或非零CRC单独证明算法保留。独立逐阶段/整图仿真必须同时成立。

## F. reset、四pin工程与STA

本独立工程沿R1 D/E4/E5的实际软件pin基线：clk_25m J2/GPIOL_P_08_CLK1_P，1A 1.8V LVCMOS单端合法GCLK；key1_n P13/GPIOR_27，BR 3.3V低有效输入/板上拉；led0 N14/GPIOR_21、led1 P14/GPIOR_22，BR 3.3V输出，高亮候选。只四pin，无新增PLL、UART或外设时钟。实物未到不宣称确认。

KEY只驱reset_release_stage1/2异步清零，stage1 D=1，stage2 D=stage1 Q；core_rst=反stage2 Q，同域各业务模块只用同步高有效rst。启动前key低保持至少四core沿，之后同步释放，不能假定FF上电初值。两级在实际网表保留并核，RAM不整片reset。

LED0=last_result_valid且last_complete_ok，表示完整正常fixture合同通过，不代表黄金/实机通过；故障符合预期仍LED0=0。LED1滚动展示last_crc bit，每250000个25MHz沿推进5bit索引，使用18bit enable计数，不产生分频clock；reset或无lastvalid时0。全部状态一个driver。

SDC在J2建40ns clock；PT实际生成/核对应GCLK、四pin、方向/电气。KEY异步例外只到两级异步清零端点，禁止全reset/整个同步链false_path；stage1 Q→stage2 D、stage2→core_rst及所有算法/RAM/CRC/监测路径正常setup/hold。LED没有外部同步采样clock，output delay N/A要说明静态观察性质和到pad路径；不能靠随意虚拟IO/0ns掩盖内部未约束路径。CRC busy/enable不构成multicycle理由。

工程按SV2009、Ti60F225/I3、固定生产参数，唯一批准work内新project/peri/SDC。先仿真编译/展开/真实执行→PT/综合→PNR/STA→实际告警/扇出/资源/时序/pin审阅→通过后bit/支持格式→staging/hash/日志登记停止。不生成或下载额外IP，不访问原HDK写入；现有工具命令/许可在批准后核，不假造当前执行结果。

## G. RTL A–L及三份映射

| 项 | 本稿合同 |
|---|---|
| A | payload608/type2/CRC32/index5，计数21/统计和22；CRC明确mod2^32，其它计数/身份不回绕 |
| B | 单core上升沿沿前fire/沿后提交；捕获沿不shift，19次旧数据/新CRC，TB下降沿稳定驱动/NBA后观察 |
| C | 仅一ready；CJ/FP/CS沿C0；K busy独立推进，job反馈需真实terminal_done |
| D | bubble不record，不因valid0补零；零padding与无效输出有区别 |
| E | 一held record/类型/flags一致；输出ready0保持；reset撤旧任务，source终态撤未接受候选为明示例外 |
| F | 19处理+1capture间隔20；normal/failure status接纳不依赖P；物理40ns目标未测 |
| G | KEY异步assert两级同步释放，同域同步rst；全域fire屏蔽/valid隔离，RAM内容保留 |
| H | CJ锁k派生配置/源图样/fault，整个job不变；last快照只在终态CRC最后处理沿整体更新 |
| I | 单record608、独立terminalCS592和lastCS592、有界前缀计数；核28RAM，OBS不存整帧/无新RAM |
| J | lane低位/坐标/三ID明确；仲裁actual record order决定CRC；全图数学仍坐标匹配 |
| K | 无数据CDC，仅KEY异步适配；不能用于真实相机无ready接入保证 |
| L | SV2009/Ti60F225/I3、25MHz/PT/PNR/STA；≤22000XLR/28RAM/0DSP预算与实际分开 |

共同数值参考：Python标准库直接图样/整图R2数学，CRC黄金采用独立逐bit608算法而非复制32bit展开；返回新结果，非法范围/类型/长度拒绝，不补失败帧。C++未选用，N/A。
硬件执行：K、C0、源各拥有旧状态；真实record捕获/19次处理/终态提交/job反馈不同事件；有限反压/取消/reset和source终结按上述。
对应：完整job所有class/启用grad逐坐标逐lane核数学；任意故障单独比较CS/各前缀和真实CRC记录顺序，不以同一个最终CRC替代图像比较或错误位置。rst作废旧job无终态期待。

## H. 实施和验证计划（尚未执行）

拟独立r2路径的新增SRC、监督、观察器、LED、reset/top与工程，精确全文件清单由B05统一冻结。先 typed组件record/错误测试，再R2真实小图/全图，再生产工程；不 force实际C0 FS/done冒充完成。

| TEST | 目标/输入/事件 | 直接期望和通过/失败观察 | 状态 |
|---|---|---|---|
| OBS-T01 | 四图样/median/retain/TLTH组合，至少k0…127完整小job；SRC另W258/H258覆盖31/32、255/256、半幅 | 每实际FP payload/id/bad/held都比，fault接受只一次、期望in精确；不以小图代1080p | NOT_RUN |
| OBS-T02 | 三类型记录/非0高低边界/zero padding；独立逐bitCRC及真实乱序仲裁 | 每条608bit/每chunk与CRC最终新值匹配；错误类型/窄化/反射/漏末chunk失败 | NOT_RUN |
| OBS-T03 | CLASS/GRAD双持续valid、交替/单方bubble、最后处理沿准备下一条 | rr只fire更新、公平及一ready/≥20沿间隔、无同沿捕获/新旧混读 | NOT_RUN |
| OBS-T04 | typed CS早错误、wrong完整CJ/位置/flags、wrongID/code0/统计错、CS+data共存及data超P/坏payload | 接真实CS无需P gate；坏data停止新data/请求cancel但照收CS，good0/原码保留、ERROR，有限账本/真实前缀CRC结束无死锁 | NOT_RUN |
| OBS-T05 | 小真实R2+fault及retain两态，C0早FS/各支尾堵 | 全class/grad及CS592逐位；正常complete_ok1，faultfixture_match1但complete_ok0，source终结隔离 | NOT_RUN |
| OBS-T06 | KEY初始低/释放/各CRC沿reset、旧RAM/job、k耗尽 | fire屏蔽、新旧快照不混、两同步级/无旧done/EXHAUSTED不wrap | NOT_RUN |
| OBS-T07 | 生产1920×1080真实R2数学、median×retain的00/01/10/11四个交叉组合，并单列半帧fault至少retain两态及故障后完整下一job恢复 | 正常全2073600像素逐阶段与class/grad比较；生产fault逐真实前缀/CS精确关系/EOF0及后续新历史恢复，真实CS/record计数，有限timeout按实际数量×20+尾/停顿预算 | NOT_RUN |
| OBS-T08 | 生产map/PT/PNR/STA | 实际必要行历史容量及合法优化记录/全部R2真实算法/CRC-pad扇出、pin电气/GCLK、无latch/blackbox/多驱动/有效内部未约束；40ns setup/hold及精确例外报告 | NOT_RUN |
| OBS-T09 | 必需功能/工具检查通过后bit/日志/hash/staging | 可追溯source/工具命令/退出/产物，bit后停止；不把软件/物理结果变硬件通过 | NOT_RUN |

## I. 双向追踪与门槛

| REQ | MOD/IF/OP | 计划文件/符号（未生成） | TEST/必要性 |
|---|---|---|---|
| OBS-REQ01 / R2-REQ06 | SRC/J/K，IF01…04/07，OP01…03 | r2_pattern_pair_source/r2_job_supervisor/r2_result_crc_observer；held_record/rr/counts | T01…05/07，每真实交接一条 |
| OBS-REQ02 | K/LED，IF05/06，OP04/05 | record_shift/crc_word_update/last_result/LED driver | T02/03/06/08，真实算法结果到pad |
| OBS-REQ03 / R2-REQ07 | J/K/C0，IF03/07/08，C0合同 | K raw_terminal/fixture_match/complete_ok/source_terminated/observer_fault_sticky/registered cancel反馈 | T04/05/07，错误不等不存在的尾 |
| OBS-REQ04 | reset/top/工程，IF06/F | reset_sync/r2_algorithm_top/project/peri/SDC | T06/08，真实时钟/电气/覆盖 |
| OBS-REQ05 / B5 | 独立参考/typed组件/全图/工具登记 | planned model/TB/runner及staging报告 | T01…09，CRC不能替代oracle |

整体行为/职责、记录接口/布局、局部状态/中文OP、语言/对应、场景/测试/追踪已给具体内容；独立审阅、来源hash/主稿回写和B03/B05仍缺。因此本稿NOT_READY，不生成业务实现或请求本稿审批。

## J. 变更与恢复

R1设计/160bit格式不改；新R2用608bit和32bit分组CRC，typed错误终态完整保留；保留fault观察与正常OK不同flags。CRC处理间隔、record布局、错误/身份/源终结/pin/复位或预算重大结构变化，先修订并审閱；不依赖旧R1授权扩范围。恢复核最新hash、基线、有效批准、许可及真实工具结果，不从历史PASS推断。

## K. 实录与L. 中文阅读路径

当前仅本稿/来源调查、手算服务预算和字段布局，0新业务源码/模型/TB/工程，所有功能仿真/综合/PNR/STA/bit NOT_RUN。正式Manifest/H0/数据库保持，无新安装/网络/硬件操作。读整包→R2/C0→本A整体→B接口→C源/终态→D每沿OP→E预算→F工程/约束→G语言→H/I验证/追踪；获批准后补实际GUI打开工程/波形、source符号、报告路径及人工阅读记录。
