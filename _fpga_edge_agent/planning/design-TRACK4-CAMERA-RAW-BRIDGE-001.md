# CAMERA-RAW-BRIDGE：CSI四像素到算法两像素的生产适配 v1

- Goal：补齐1080p、RAW10、像素域到100MHz算法域的真实RTL运输。
- Current state：官方CSI模型已验证四像素低40位，算法源写入接受两像素20位；二者尚无生产连接。
- Target state：单帧带身份、坐标和标记运输，停顿不改有效输出，失败有明确终态。
- Gap：帧形状检查、命令/终态CDC、记录FIFO、两像素拆分和旧帧排空。
- Assumptions：CSI数据及HS/VS/PPC/DT/VC/WC属于pixel_clk；rx_fault由外部先归属至本像素域。
- Open questions：真实CSI CRC/尾部错误closure提供者未闭合，隔离为后续任务，本适配不声称代替它。
- Dependencies：video_async_fifo当前READ_UNKNOWN版本、EFX_RAM10、CSI模型v1.4、capture_canny_axi公开RAW口。
- Milestones：设计读回→RTL及独立测试→直接/真实CSI组合1080p→Ti60F225/I3 MAP→登记。
- Detailed steps：见E/G；不修改原HDK、安装或已冻结包。
- State transitions：设计自检→用户既有自主授权下实施→验证→按实际范围交付。
- Artifacts and hashes：baseline.json冻结上述输入；每次运行逐源哈希，失败保留，新RunId不覆盖。
- Validation：直接错误/CDC场景、独立逐像素参考、实际CSI组合及综合资源。
- Failure handling：正常前缀继续排空；溢出/丢时钟隔离，禁止新任务，需共同安全冷复位。
- Human approval gates：用户“当你統計完后自行进行, 无需我的批准”覆盖此次软件设计/实现；此前本地审计例外继续。生成最终bit后停硬件操作。
- Rollback：仅独立work新单元；旧源码/产物保持。
- Completion criteria：本单元当前源仿真和MAP证据闭合；不冒充整机或硬件通过。

## A. 状态与阅读入口

任务TRACK4-CAMERA-RAW-BRIDGE-001，关联H2/A3/A4；设计v1，2026-10-09。初始READY_FOR_REVIEW，读回及呈现后按用户明确取消逐项审批的授权转IMPLEMENTING，不伪造新批准。正式DB/state/Manifest权限不变；只用已安装工具、本地JSONL。工作目录work/active/track4_algorithms_20261004/camera_raw_bridge。

事实入口：CSI probe设计J4及其csi_raw_hd_001：PPC4、DT2B、VC0、WC2400、HSVS1；末有效像素与VS下降相隔71220ns。video_async_fifo同步RAM、Gray指针、溢出保持前缀已测。capture_canny_axi要求RAW pair20、x_even11/y11、markers{EOF,EOL,SOF}、handle64，并另需独立rx_close(handle64,Origin195,good)。本模块产生local shape/drain报告，不产生rx_close_good。

计划自写9份：rtl/camera_pixel_framer.sv、rtl/camera_raw_bridge.sv；tb/tb_camera_raw_bridge.sv、tb/tb_camera_csi_bridge.sv；model/raw_bridge_reference.py；scripts/run_bridge_sim.ps1、scripts/run_bridge_map.ps1；project/camera_raw_bridge_component.xml/.sdc。复用依赖单列，不计自写。文档、基线和运行日志也单列。

## B. 整体外部行为

RB01：只在job_valid&&job_ready采样handle64和Origin195，一个在途任务；先等相机idle，再捕获新VS上升，忽略旧半帧。

RB02：IMAGE_WIDTH默认为1920、范围4..1920且4整除；IMAGE_HEIGHT默认为1080、范围2..1080。选VC0/RAW10/PPC4/WC=W*5/4，每个有效拍的低40位按顺序拆成两拍20位；不舍弃任何10位。行列与SOF/EOL/EOF精确。

RB03：像素源没有ready。FIFO满时停止新写并报告OVERFLOW；不能把丢失帧当成功。合法前缀保留。输出ready/valid停顿时所有数据及身份保持。

RB04：只有准确W/4组×H行、每行HS结束、最终VS下降才shape_complete。错误/取消停止新记录，终态记录实际已入FIFO组数；跨域读取和私有拆分槽全部退休才drained。

RB05：cancel/discard仅接受匹配handle。cancel停止生产；discard是调用者已经安全终止旧下游后的显式授权，允许本模块丢弃旧前缀，另计discarded_pairs；不会静默冲掉停顿数据。

RB06：默认WATCHDOG_CYCLES=50500000核心周期，约0.5s@100MHz。超时隔离，done outcome3/drained0，不声称生产已停。overflow同样隔离；共同cold_reset_n是唯一清隔离方式。软件timeout是组件保护，不替代整机QoS指标。

RB07：done有效保持至ready，携带原handle/Origin、outcome2(0形状完整、1输入错误、2取消、3隔离)、reason8(0无错/1取消/2溢出/3元数据/4几何/5接收故障/6超时/7身份计数内部异常)、accepted_groups22、delivered/discarded_pairs22、shape/drained；reception_verified恒为0。

普通例：20×8，40组入FIFO→80个RAW pair→每行最后第二拍EOL，最后第二拍EOF；最后VS下降且80拍消费后才报告。边界：等待idle时相机正在旧帧，不吞旧数据；新帧短行失败。取消时已经有效且被停顿的pair继续保持；只有匹配discard才撤销这项保持义务并计明确丢弃。

## C. 模块职责与整体连接

```text
核心job稳定mailbox --IF1(req toggle + handle64)--> MOD1像素framer
CSI解码口 --IF2(低40/元数据/HSVS)--> MOD1 --IF3(记录128)--> MOD2已验证双时钟FIFO
MOD2 --IF4(valid/ready)--> MOD3核心拆分槽 --IF5(pair20/身份/坐标/标记)--> raw_source_join
MOD1 --IF6(terminal toggle +稳定快照)--> MOD3 --IF7(local done)--> 未来帧管理
核心cancel level/terminal ack --IF1反馈--> MOD1；discard仅核心退休旧前缀
```

MOD1自写camera_pixel_framer：拥有帧形状计数、首错、终态mailbox，不负责PHY/CRC综合归属。MOD2复用video_async_fifo原样独立copy，128×1024默认14RAM10，有保守Gray释放、两读槽及sticky overflow。MOD3自写camera_raw_bridge：拥有job全身份、终态同步、22位取出组数、拆分槽与计数/超时；不执行RAW转换或DDR事务。

关键选择：不以FIFO瞬时empty判断排空，而用终态“实际接受组数”与核心“实际取出组数”及槽空合取；指针同步延迟不会提前成功。overflow不自动复位，后续安全恢复设计负责共同冷复位。当前组件MAP没有板级引脚约束。

## D. 接口与组合检查

所有数值unsigned。core_clk100MHz、pixel_clk50MHz，cold_reset_n共同异步assert，两域内部两沿release。job_valid/ready、cancel_valid+handle64、discard_valid+handle64、out/done均core域；CSI及rx_fault均pixel域。Origin195布局沿用{capture_seq64,frame32,epoch32,source_generation64,slot3}，本模块opaque保持，调用者负责唯一handle与合法Origin。

IF1：req_toggle两FF同步，core的handle从job接受至pixel回DISARMED全程稳定；cancel_level两FF同步，不能跨域传单周期脉冲。终态ack_toggle两FF返回，像素只有终态已ack才解除busy；core只有ack往返及pixel_busy两FF为0后再次job_ready。不同任务不会共享槽或身份。

IF2：每pixel上升沿有效拍是新记录；HS/VS同沿可能变化。新VS上升同沿数据允许作为首组；HS下降要求已开始行且组数准确。VS下降同沿最后HS下降可完成最后行；否则FRAME中提前VS下降失败。WAIT_END禁止多余HS/valid。WC检查仅valid沿，不把short字段当帧号。

IF3记录128从低到高：raw40[39:0]、handle64[103:40]、markers3[106:104]、bad1[107]、x_group9[116:108]、y11[127:117]。bad=0，错拍不入FIFO。markers[2:0]={EOF,EOL,SOF}；组内第0对只携SOF，第1对携EOL/EOF。

IF4读取在rd_valid&&rd_ready边沿发生；每取出一次组数+1。私有槽128+half1，空槽才接一组；两对消费后清槽，允许一拍装槽气泡。IF5：raw_pair20、out_x_even11=(x_group<<2)+(half?2:0)、out_y11、out_markers3、out_bad、out_handle64；out_valid在槽非空且未discard时成立，消费只在out_valid&&out_ready。

IF6 terminal稳定数据：handle64、outcome2/reason8、groups22/lines11/shape1。像素发布后保持到ack；core只在toggle新值经两FF后捕获；正常/错/取消均停止写入之后发布。终态接收不等于FIFO已可见或槽已交付。IF7报告只在前缀全部退休后发布，超时则直接隔离报告且drained=0。

相容：IF5与capture_canny_axi/raw_source_join的20/11/11/3/1/64一致；一帧518400组→1036800pair→2073600像素。颜色/Origin解释由相邻已测模块负责；CSI真实rx_close仍必须独立提供。没有上游反压，FIFO只能吸收有限停顿，无法声称任意停顿不丢帧。50MHz连续每拍一组要求100MHz每拍一对，当前槽有装载气泡，故全连续峰值可能溢出；相机1080p30实际payload稀疏，实际CSI组合测试验证所覆盖节奏，整机最坏QoS仍后续。

## E. 局部详细中文草图

### MOD1：状态、操作与不变量

DISARMED清本帧计数，等req新值且FIFO运行→锁handle，busy=1、WAIT_IDLE。WAIT_IDLE见VS=HS=0→WAIT_SOF；若同步cancel则终止。WAIT_SOF见VS上升→FRAME，首拍有效同沿可进入下述组操作。

FRAME基于旧状态先判断cancel、rx_fault、元数据/几何。只有本沿合法新valid且FIFO ready才wr_accept，groups+1、line_groups+1、line_started=1；记录x取旧line_groups，y取旧row，标记由旧坐标计算。FIFO满的本沿合法wr_valid被FIFO记overflow，但不入组数，发布outcome3。错误/取消优先禁止该沿写入，终态groups是旧已接受数。

HS下降沿：检查旧line_started和line_groups=W/4；成功row+1、清line计数。最后行转WAIT_END；若同沿VS下降可直接shape成功。FRAME中其他VS下降视为提前终止。WAIT_END只等最终VS下降；新HS或valid为多余行错误。TERM中不写，bundle不变，ack同步等于terminal_toggle后回DISARMED。

### MOD3：核心mailbox、运输与报告

IDLE在FIFO两域运行已同步、pixel_busy=0、无Q时job_ready=1；接受job锁handle/Origin、计数清零、toggle req、RUN。cancel同身份锁level，错误handle忽略；discard同身份锁discard_mode，丢弃数独立。RUN每核心沿若FIFO valid且槽空读入记录、popped_groups+1；槽有效时若discard退休一对并计丢弃，否则仅out握手退休一对并计交付。第0对→half1，第1对→槽空。所有判断用旧值，不能同沿装槽又错误消费新值。

同步终态新toggle后捕获bundle，校验handle、groups≤W*H/4，保存outcome/reason/shape，转DRAIN，取消level可撤下。DRAIN仍消费前缀，popped==groups且槽空才done报告；超过groups/错误handle隔离。overflow终态保留outcome3但排空后drained1；禁止重用。RUN/DRAIN计watchdog，只要达到限值先隔离并报告drained0，不承诺pixel停止。Q报告后依然能退休旧输出，永不job_ready，直到共同安全冷复位。

REPORT：done稳定，ready握手后若已知非Q终态则ack=其toggle、WAIT_DISARM；等同步pixel_busy=0再IDLE。Q终态可ack但留Q；timeout未获终态时不虚构ack。独立接收端CRC closure与本模块报告不能混用。

不变量：已输出+已丢弃≤2*popped≤2*accepted(terminal后)；一组内部低pair先于高pair；身份不跨job改变；任何未显式discard的held输出稳定；终态先停止生产再发布；FIFO RAM数据不需清零，有效指针隔离。

## F. 语言/映射契约

SystemVerilog sv_09；时序nonblocking、组合wire/always_comb完整赋值。22位计数最大1036800对不溢出；line_groups10位容480、x_group9位容479；坐标11位容1918/1079。计时宽度$clog2(WATCHDOG_CYCLES+1)，合法参数≥64。计算窄化显式，移位先扩展坐标。Python标准库逐像素公式((37*x+53*y+7*(x xor y)+101*frame)&1023)，不复制FSM；C++不适用（本批无C++生成）。

RTL A数值见IF布局；B两域上升沿，TB负沿驱动、正沿观察旧valid握手；C接受/交付见IF；D气泡只推进同步/计时不推进坐标；E停顿全伴随保持；F初始CDC+同步RAM+装槽后交付，槽三周期/组极限；G共同assert、两沿release、有效性隔离；H固定几何+job原子mailbox；I14RAM+128bit槽、FIFO满显式失败；J完整身份与组到对数量变换；K稳定bundle+toggle两FF，Gray FIFO；L Ti60F225/I3组件MAP，100/50MHz SDC。生产Gray路径延迟/skew/CDC/PNR/STA留总集成，不能用全异步false_path掩盖。软件参考按真实握手日志的pair/坐标/标记/handle对照；reset或明确discard取消的记录单列。

## G. 实施与验证计划（初始均未运行）

先冻结依赖/读取设计，再RTL→直接TB/独立参考→实际CSI组合TB→MAP→SHA登记。两个TB仅使用唯一TEST_WIDTH/TEST_HEIGHT/PROBE_*参数，避免-GWIDTH污染原厂递归。

| TEST | 要求与输入事件 | 期望/观察 |
|---|---|---|
| T1 | 20×8及1080p新帧、随机ready、两个job | 每10位/坐标/身份/标记/数量精确，VS结束前无done |
| T2 | arm时旧VS高、HS低再新VS | 旧帧不入FIFO，只有新帧 |
| T3 | PPC/DT/VC/WC错误、短长行、提前VS/多余行、rx_fault | 首错、实际前缀计数，非shape成功 |
| T4 | 首/中/末取消，错误handle，held pair+cancel/discard | 停止新记录，held保持；仅正确discard允许退休 |
| T5 | depth16、ready长停、像素钟停止、共同reset恢复 | overflow/timeout隔离，无假drained；冷复位可新job |
| T6 | 真实官方CSI TX→lane→RX→本模块，小帧和1080p | low40到pair逐位一致，元数据/正常VS尾部实际可兼容 |
| T7 | Ti60F225/I3 MAP当前仿真源 | 原生14RAM10、不黑盒/锁存/悬空；记录实际FF/LUT/ADD/DSP |

## H. 双向追踪

RB01/RB04/RB06/RB07→MOD1命令/终态与MOD3状态→IF1/6/7→两RTL→T1/2/4/5。RB02→MOD1坐标与MOD3拆分→IF2/3/5→两RTL与Python参考→T1/3/6。RB03/RB05→FIFO及MOD3退休→IF3/4/5→复用RTL/核心槽→T1/4/5。runner/工程承担源绑定、错误退出、Ti60实现派生要求→T7。所有实际证据初始未运行，后写K；反向按这些稳定符号核对。

## I. 设计门槛

十项：①B正常/错误行为与例；②C职责和已核查FIFO；③D接口布局及与生产RAW口相容；④E状态与旧值操作；⑤F A–L及独立Python角色；⑥D数量/有限buffer与失败走查；⑦G/H实施/测试/追踪；⑧当前适配无阻塞，CRC闭合隔离为未来范围；⑨保存后必须实际读回并提供聊天入口；⑩A路径、版本和基线。按用户后续“无需我的批准”自主执行，本文件不谎称用户逐版批准，软件授权来源明确。

## J. 变更与恢复

初版。代码生成前补充：超时未获像素终态时，done_groups_known=0，done_accepted_groups=0只是占位，不代表实际零输入；done中的计数是发布瞬间锁存，不随隔离后的继续排空改变。正常及已知overflow终态groups_known=1。E报告步骤包含锁存这些字段，T5检查未知与稳定性。

J1（验证补充，生产RTL未变）：初轮18场景及实际CSI小帧/HD、直接HD均通过。T1增加首valid与VS上升同拍、最后HS与VS下降同拍；T4增加全payload后/VS下降前取消；T5增加持有旧pair时共同冷复位、随后新job无污染；T1另检查4×2最低几何及多个FIFO深度。runner添加几何/深度/像素钟/核心钟参数，仅TB驱动；最终源码重新仿真/综合，旧尝试保留。此卡在测试代码变更前保存/读回，仍按同一自主授权执行。

发现行为或CDC不足，先在本节追加修订卡、同步E/F/H并读回，按同一自主授权执行；失败日志留存。不可直接降低1080p、忽略错误或伪造rx_close。

## K. 实现与验证实录

自写9份已按草图生成；复用50份依赖（FIFO、原生RAM模型、原VGA和官方CSI库47份）单列。当前v1+J1冻结输入53份，baseline-v1.1.json保存实施前设计快照，原baseline.json历史保留。生产RTL从初轮到最终未变。

当前源实测：bridge_small_002完成21终态场景并另有1次持有旧pair的共同冷复位作废、交付726对；控制/元数据/几何/故障/正确和错误身份取消或discard/溢出/时钟停止/首valid同VS/末HS同VS/全payload后取消均通过。日志最后case编号22包含那次作废job，protocol-metrics.cases=21是实际终态数，不将作废当成功。

bridge_min_001为4×2、FIFO512、像素half7ns/核心half3.5ns的两次正常任务，8对；这是数字CDC调度测试，不声称142.857MHz硬件时序通过。bridge_hd_002是1920×1080两帧、FIFO1024、核心100/像素50MHz、随机ready：2073600对/4147200像素精确，6246898核心总周期。bridge_csi_small_002是实际官方TX/lane/RX→适配20×8一帧80对；bridge_csi_hd_002是实际官方TX/lane/RX→适配1080p一帧1036800对/2073600像素，518400组进/出CSI口，首RX372290ns、末RX33053970ns、总核心3312546周期。五个当前源run共27终态、3111214对/6222428像素逐位独立参考通过。各run编译/展开/仿真0errors/0warnings，fatal探针正确非零退出；模拟库保护体未改。

bridge_map_002绑定bridge_small_002当前源，Ti60F225/I3 MAP exit0，14 EFX_RAM10、1439 FF、1394 LUT4，ADD/DSP/SRL为0（缺行由实际网表无对应原语和No DSP报告佐证）。上24位非RAW10数据被剪掉，24个unused输入位有工具警告；没有隐藏这些警告。组件顶层宽接口不作板级IO/布局布线证明。旧001运行和旧map完整保留，最终登记仅绑定002/min当前源。

源码—设计—测试按两状态机、128bit布局、half拆分、终态计数/稳定性、显式discard及FIFO依赖逐一核对；中文README实读回。实际CRC错误归属、active C2完整等价、真实传感器/模拟PHY、生产CDC物理约束、完整摄像头→DDR→Canny同一个top、PNR/STA/bit/硬件未检查。局部shape/drain均不推广为rx_close或整机完成，理解验收待用户作答。

## L. 阅读与交付

顺序B整体→C/D交接→E像素操作→E核心操作→RTL同名状态/拆分槽→TB/参考→运行日志/登记。理解验收待用户实际作答，不阻塞自主软件实施。
