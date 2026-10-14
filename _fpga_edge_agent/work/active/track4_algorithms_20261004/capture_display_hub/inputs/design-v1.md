# TRACK4-CAPTURE-DISPLAY-HUB-001 v1：实际采集/Canny与显示读取的公共读写链路

- Goal：完整五基础六高阶/Ti60F225/I3/SC431HAI/1080p目标内，把实际RAW→RGB写回→读回→完整Canny与显示span并行读取接入一个公共AXI128读写口，不用合成算法请求替代实际Canny生产者。
- Current state：capture_canny_axi已完整HD/native模型与MAP；read-pair38/write-pair35/RGB write join77+HD已登记。现有capture父用两层混合line arbiter及一读写bridge，没有公共display读仲裁。
- Target state：保留真实采集/reader/Canny控制和全部数值，camera写独立端、algorithm混合读写分向锁、display读共享实际read-pair；同一数学DDR byte slave可同时有一读及一写，全HD同源结果及完整独立旧Source的显示读取验证，组件MAP。
- Gap：生产FrameRef/RO权限、Source/result发布/Freeze/Offer/Apply/Retire、真实scan/HDMI上层接入、CSI CRC/rx_close/不可暂停丢弃、DDR PHY/动态资料/最坏QoS、复杂识别/整机资源/PNR/STA/bit另闭合。
- Assumptions：同core clk/rst/axi_enable。父已经合法授予互不重叠Source/Class/Queue/Result和只读旧display Source；显示上层不得读取正在写的同帧。本批用独立预置旧Source说明并发，不冒称已实现FrameRef authority。输入RAW此层可反压，rx_close是外部已判定的公开事务，不伪造真实CSI good。
- Open questions：现有公开接口、模块和controller已核；当前组合无接口阻塞，上述未来范围不隐补。
- Dependencies：原capture工程35份RTL（含旧父作为改造依据）、7份数值参考（旧capture+六实际helper）、4份read-pair/read-arbiter/display-span/write-pair RTL、原生RAM、原capture XML、四登记manifest、规范及本设计=54冻结输入。新work独立，原资料/旧源码/登记包不改。
- Milestones：整体→交接→局部中文语句→保存读回呈现READY→54输入→三RTL/两TB文件/参考/两脚本/XML/SDC10份自写→小图20同源图及hub协议→6×5边界→全HD并发→MAP→staging。
- Detailed steps：B外部行为，C/D模块和逐连接，E局部语句，F语言，G/H验证与追踪。
- State transitions：READY_FOR_REVIEW v1；沿用用户“当你统计完后自行进行，无需我的批准”及本批本地审计例外，自主软件实施，不更新正式授权/DB/H0。
- Artifacts and hashes：work/active/track4_algorithms_20261004/capture_display_hub。10自写文件+45原样runtime依赖=55源/工程；其中sim52，MAP追加脚本/XML/SDC共55。四RTL服务与原capture leaf重复的axi_line_bridge只编译一份。
- Validation：独立RAW/CFA、R2整数和BFS共同数值、实际公共RPC/AW/W/B/AR/R字节账、全Source/class初代/终态/queue/result/FP/grad/status/origin及display旧Source完整bytes；错误/取消/不明归属/共同cold，MAP源绑定。
- Failure handling：原失败目录保留；新请求受globalQ阻塞，旧公开事务/回执及物理尾部保持。UNKNOWN不制造safe closure，reset仅可信共同cold；不把理想byte slave当真实DDR PHY。
- Human approval gates：本批软件/local audit持续授权，正式DB/state未动；无bit/硬件操作。
- Rollback：独立new work，旧capture/source/read/write各包保持原样。
- Completion criteria：本组合功能及组件MAP有真实证据；完整FPGA目标仍ACTIVE，不由组件交付替代。

## A/B 整体外部行为

DH01：新capture_display_axi保留旧capture全部公开job CJ142、origin195、handle64、四个base32、Bayer phase2、RAW20/坐标/markers/bad/handle、RX-close/取消、grad185及DONE/计数/status/phase语义。默认1920×1080，支持旧实际管线WIDTH6..1920偶数、HEIGHT5..1080。采集原生色彩处理、RGB6字节顺序/整帧A64、真实源reader→Canny高斯/梯度/NMS/双阈值/BFS/class/queue/result全部复用，CJ/base/身份仍在旧parent job fire锁存。

DH02：新增公开display span(addr32/bytes14/valid/ready)、data128及valid/ready、done/outcome2/reason8/drained1、cancel1/enable1。span16..8192字节且16B对齐/容量合法；实际display_span_axi负责≤64beat/4KiB分割及所有错误/取消/保持。读取独立已关闭且获授权的旧Source，所有字节来源于共同物理slave内存，不能按坐标直接制造RDATA。

DH03：公共video_memory_hub分camera64B写、algorithm64B混合读写及display span读。camera→actual write-pair0，algorithm写→write-pair1；algorithm读→actual read-pair line，display→read-pair span。物理只有一个AW/W/B及一个AR/R，可分别各一在途并行。algorithm单一应用RPC需要active/locked_write直到实际reply消费；UNKNOWN消费保留active，不用物理idle清借用。不复制544bit请求holding，唯一写数据snapshot仍在实际write bridge。

DH04：globalQ=producer_localQ|read_serviceQ|write_serviceQ|direction_guardQ，阻新camera/algorithm/span接纳（valid/ready同资格），旧回执/AR/R/AW/W/B、display data/done不gate。read leaf enable和write bridge enable都直接真实axi_enable，不能把另一路Q当enable0而把已安全承诺污染成UNKNOWN。read arbiter新选择受各read叶原自身Q控制；已经接受的旧span属于已建立的借用，可以继续其合法AR分段。全局Q仍禁止任何新的frame发布或复用。

DH05：producer_localQ只由实际source/reader/Canny/algorithm_group隔离及parent寄存state QUARANTINE形成，不包含memoryQ组合反馈；capture总Q包含memoryQ，parent正沿进QUARANTINE。避免hubQ→parent总Q→externalQ→hubQ组合自环。core来源PUBLIC camera请求在globalQ之前未被接纳时保持公开，既不撤也不伪造回复；旧WR/RD真实物理尾部继续。完整DONE不由无在途AXI或某个component DONE推断。

DH06：invalid known地址由实际leaf返回error/drained1无物理事务；algorithm line_write四态未知在空闲且enable时触发本地隔离，不接纳/不制造reply。X/Z guard只作RTL四态仿真检查，物理两态综合不当亚稳态检测。trusted common cold同时覆盖producer/hub/slave，不能独立暖reset后重用DDR事务。

正常样例：数学slave预置授权旧RGB Source A；新Source B以真实RAW20进入，写B完成并匹配RX good；真实reader读B提供Canny FP，class/queue/result按独立BFS形成；display同时通过ID2分段读A，Canny读用ID0、所有写用ID0，每个公共交接及所有字节一致。失败样例：display malformed R使readQ，camera已公开但未被write服务接纳的packet保持，parent进QUARANTINE、不出现safe full-job DONE/new job；已经承诺的camera W/B继续，未知display借用保留直到可信cold。

## C/D 职责、连接和相容接口

MOD1 capture_canny_rpc：由旧capture_canny_axi实际父改造，除内存交接拆分外状态/配置/数值/错误/取消/计数保持。source_group和memory_group替为一个实际line_rpc_arbiter2 algorithm_group：输入0是实际rgb_frame_reader只读，输入1是actual canny_full_top混合读写。camera raw_source_join写端独立输出；source/RGB内native RAM等34leaf原样。

MOD2 video_memory_hub：三个producer公共端及实际两服务接线；只保存algorithm active/方向及sticky direction guard。地址和payload由真实child在fire保存，不重存frame或512正文。MOD3 capture_display_axi只把core和hub接合、扩展display公开端及诊断。MOD4 read/write services及其leaf原样复用，MOD5数学双向byte slave只验证AXI，不作为业务RTL/真实DDR。

IF1 camera RPC：req_valid/ready、addr32/data512；rsp_valid/ready/error1/drained1，write-only rdata由core固定0。source PUBLIC一旦提出保持至真实req fire；响应归实际writer，任何cancel/全局Q都不能私造safe response。

IF2 algorithm RPC：req_valid/ready/write1/addr32/data512；rsp_valid/ready/rdata512/error/drained。接纳时锁方向，read return来自实际read service，write return rdata0。仅锁定端rsp_ready连接parent，另一端不收到伪ready；两服务正常无same-edge request+response，新active在接纳沿后有效。safe drain reply消费清active；unsafe消费留active及globalQ。

IF3 display：直接实际read-pair span/data/done/cancel/enable，公开ready与进child valid同!globalQ/真实enable；data/done不受globalQ。SPAN许可和不可变旧FrameRef由上层承担，不以地址范围检查代替授权。

IF4 AXI：AWaddr32/ID4/len8/size3/burst2，W128/strb16/LAST1，BID4/RESP2；AR同49bits，RID4/DATA128/RESP2/LAST1。write-pair固定4×16B写且ID0；read line固定4×16B/ID0，display实际分割16..8192B/ID2。共同slave允许WR和RD分别在途，不改变同接口顺序，parent保证不同Source区域不读写竞态；应用direction active不是物理AXI总占用。

IF5 Q/enable：core输出producer_localQ，hub返memory_quarantined，core总Q与parent FF关系按DH05。所有leaf enable是真实axi_enable（display另真实display_enable），不可用globalQ代替校准状态。IF6 job/base/CJ及原DONE与真实source/reader/Canny契约逐字保留旧父；旧slot借用失败时保持，source_stop通知RAW停止。

公开hub诊断：algorithm_live/read_occupied/read_physical_idle/write_busy各1bit，read_quarantined/write_quarantined/direction_quarantined各1bit，read_fault_reason/write_fault_reason各3bit，quarantined1bit。诊断不作为FrameRef closure。top保留原capture总quarantined，扩展memory_quarantined及上述物理/应用占用；核心状态/计数/数值的详细原始设计沿用已登记capture父，当前只改变E4/5的明确交接。

覆盖/走查：DH01由core34实际leaf；DH02实际display span；DH03由两个服务及方向FF；DH04/05由new资格/旧通知直连和localQ边界；DH06 guard及共同cold。两个方向可共享物理内存，但都不生成FrameRef authority。仅已有未完成的真实CSI/PHY/整机时序不影响当前AXI组合功能检查。预算原capture约46RAM，加服务0 RAM；new FF和组合预算待真实MAP，不从component数相加判定整机可装下。

## E 详细中文操作草图

E1 hub定义read-pair/write-pair线，algorithm active、locked_write、direction_guard FF复位0；没有新的512 holding。由真实known方向和idle/enable/!globalQ决定各端request valid；对外ready选相同资格下的实际child ready。相同正沿fire写active/方向；没有fire时输入proposal变化不影响old response。

E2 组合response仅来自active锁定读或写端，write rdata常0；selected leaf rsp_ready=active方向匹配&&parent_ready，未选择端0。consume safe drained1清active；drained0保持方向/active并依实际leafQ隔离。backend停用及错误按actual leaf，不由另一服务Q改旧正文。camera两信号同!globalQ门；旧camera回执直连。

E3 read-pair算法/显示enable、arbiter enable接真实输入，不因writeQ掉enable。new span req/ready资格一致，old data/done/AR/R直接。write-pair enable真实axi_enable、camera与算法写入原两个端；W/B直接。local guard仅空闲有效未知方向触发，不重写已有效reply。

E4 core从旧parent源码逐段保留CJ/配置、状态、事件优先级和所有child实例。raw_source_join公开write接camera RPC；rgb_frame_reader与canny_full_top进actual algorithm_group。去掉两个旧mixed groups和旧physical bridge，只加入一实际algorithm_group和公开端接线。writer line_rdata=0，reader/Canny从公共algo_rdata收；camera error/drained与算法error/drained不再错误广播到另一组。

E5 core总quarantined=producer_localQ|memory_quarantined；producer_localQ无memoryQ组合项。父保持原正沿if(Q)最后优先进入QUARANTINE/stopping。旧的START_SOURCE/CAPTURE/WAIT_RX/START_CANNY/START_READER/WAIT_CFG/PROCESS/DRAIN/DONE不重新定义；取消仍是一次source事件及算法停止状态。

E6 top显式core↔hub公共连线，保留旧所有用户端，添加display三接口及memory诊断。没有新controller/帧发布捷径，不以display done清capture job。controller期望仍是正确scope/origin且真实三个child/匹配RX都关闭。

## F 语言、数值、时间和资源

SV2009，组合blocking/FF nonblocking；同core正沿前valid&&ready为fire，沿后FF提交；TB负沿驱动。所有端位宽按D，CJ/origin/base原锁存无损，32地址相加使用旧33bit范围checks；图像+class(2bit)/queue32/result byte参数范围不改。原native RAM同步RE/WE、极性/OUTPUT_REG保持，禁止全局-GWIDTH覆盖vendor，TB用TEST_WIDTH/TEST_HEIGHT/TEST_PROTOCOL。

反压不定延迟，ready不能伪造fire，所有PUBLIC数据/sideband/CFG/终态保持至消费。common rst同域同步高，清FF有效性/身份并使公开fire0；payloadRAM不靠整帧清零保证。没有新CDC；真实core/video/CSI/DDR reset域另设计。X/Z guard属于RTL测试，STA/硬件未知检测N/A。

Python六旧参考helper原样复制，只改新model可追踪import路径和生成/审计组织；二维RAW/reflect101/CFA、独立R2及BFS共享数值，状态/总线观察独立。class初代snapshot以其公开完整class line第一次物理写生成，不探DUT私有HY phase；最终source/state/queue/result来自实际数学slave byte memory。actual FP经public rgb_frame_reader端口observer核对，不读private数组。

## G/H 实施、验证与双向追踪

T1：34×19共20个Bayer/RAW pattern/median/retain同源图，display从独立授权旧RGB区域并发读取整个A64，input/grad/display/AW/W/AR/R/终态各停顿与气泡；核全部source/class初代/class终态/queue/result/FP/grad/status/origin和总线byte effects。正常值来自六独立数学helper，流控来自公开fire。小6×5边界同20图。

T2：生产1920×1080完整RAW图→实际sourcewriter/reader/Canny完整2MP result，旧display完整6.22MB真实AR/R读出；确认至少一个时刻read与write物理在途并行、display与algo读都得到服务，量化cycles/stalls/实际AR/W/R数，不当最坏deadline或整机FPS证明。

T3：独立hub公共客户端验证read/write方向锁、回执停顿/未fire提案改变、两个物理方向重叠、camera/algorithm write压力、display多burst/4KiB split/停顿及cancel；known非法addr/bytes安全reject、early/late error/unknown BID/RID、enable live停用、跨read/write Q旧安全reply不被污染、新各端禁止、camera PUBLIC保持、UNKNOWN active保留和可信common cold。正向scope与老read38/write35互补，旧pass不代替new组合。

T4：actual capture parent PUBLIC AW等B/W取消、RX good/坏/错身份、输入bad/handle/coord/marker、地址重叠/容量reject、CFG/Grad/DONE停顿与共同cold恢复；display malformed read同时camera未接纳PUBLIC以及旧已发AW/W/B继续，parent不得safe DONE/复用。依靠phase和子module公开端观察，不强制内部状态或内存强制完成。

T5：当前compile/elab/真正fatal拒绝/功能/独立audit完成后，MAP关联最新HD52源，再加MAP脚本/XML/SDC=55全snapshot。读取真实map网表/资源/警告与rpt核对，未运行不填PASS。component工程没有板IO，PNR/STA/bit、实际DDR/CSI不在此组件通过声称中。

DH01→E4/5+IF1/2/6→T1/T2/T4；DH02→E3/6+IF3/4→T1/T2/T3；DH03→E1/2+IF2/4→T1/T2/T3；DH04/05→E2/3/5+IF5→T3/T4；DH06→guard/cold→T3/T4；工程/runner→T5。实际实现后README定位稳定符号及输入/输出/端口→场景→证据，不仅列文件。

## I/J/K/L 评审及交付

第10.3十项：整体/正常失败样例已写；实际35RTL及services/参考已查；逐交接含方向/并发/Q反馈相容；FF/父保留及中文草图明确；数值/时间/配置/存储/复位/CDC边界明确；走查及要求归属齐全；T1..5与追踪；当前接口无BLOCKING；保存后实际读回并给用户入口；v1/54输入/10自写/独立new work范围清楚。READY v1，按用户持续自主软件执行，不伪造正式DB批准。

有实际偏差时先修订短卡并读回/呈现，原失败证据保留。交付按整体→接口→core/hub局部→公开observer与数学参考→实际runs/MAP→限制/后续，理解验收待真实作答。本组件之外仍推进生产frame authority/scan/CSI/复杂识别/DDR/资源及最终FPGA，完整目标保持ACTIVE。
