# TRACK4-CAPTURE-CANNY-AXI-001 v1（初版）→v1.1（当前）：实际写入源→真实读回→完整Canny→AXI结果

2026-10-09。持续自主授权/本地审计；按模板先保存/readback READY，再独立work/capture_canny_axi实现。不是整机R0完成，原HDK/冻结包/正式DB/硬件保持。

Goal：同一幅真实RAW10图经实际彩色源writer写入128bit AXI字节端点，再由实际reader读该源，送完整Canny/cache/queue/结果writer，全程同源。Current：RAW source/AXI桥已归档；reader小图通过并进行1080p/MAP；此前Canny使用独立FP输入。Target：生产参数1920×1080软件组合的源/分类/最终状态/FIFO/结果/梯度/CS592逐位一致，实际共享服务资源。Gap：父RTL/组合参考/TB/MAP及最终生产整机。Assumptions：同core稳定clk/已校准enable；同步RAW可反压；外层锁定完整SourceOrigin和全授权，读期间源不可变；不同grant区间真实互斥，SourceOrigin与CJ身份对应。Open questions：真实MIPI/CDC/DDR2Gb器件动态、FM六源池/显示QoS/整机引脚时序后续，不阻塞此软件组合。

Milestones：整体/身份/接口→三个client共享RPC/AXI→父逐沿/失败关闭→独立二维源+Canny+BFS参考→小图/协议→1080p→MAP/归档→FM/显示/性能。State：READY保存读回后持续自主实现，不再索取逐项批准。Artifacts：work/capture_canny_axi、runs、不可覆盖登记包。Failure：安全错误等全部已启动子终态及RX运输关闭；unknown隔离不发safe done。Human gates：无硬件操作，最终总bit后停止。Rollback：新版本/run，旧模块源码只读复用。Completion：CA-T01…05的软件组件；CA-T06整机另闭合。

## A—D 整体、身份与接口

job_valid/ready、CJ142、SourceOrigin195、job_handle64、Bayer phase2、四base32（source/class/queue/result）。Origin固定编码={capture_sequence64,frame_id32,epoch32,source_generation64,source_slot3}；生产slot0…5，gen/sequence允许0，完整字段保持。CJ低96={config32,frame32,epoch32}，须epoch=CJ[31:0]=Origin[98:67]、frame=CJ[63:32]=Origin[130:99]；config可独立。来源完整Origin、CJ配置及base同一次job_fire锁，不截Origin为96/64。外层完整DSscope623/grant/phase/lease继续保存，局部handle不是授权替代物。

外部RAW20/x_even11/y11/markers3/bad/handle64；cancel_valid/scope96。RX closure是独立valid/ready/handle64/origin195/good事件，ready只在已启动source且尚未闭合时；错误handle或完整Origin不符的事件实际运输消费但不记matching closure，之后仍等本源事件。good表示接收CRC/运输质量，不代表已经接受P像素。取消的运输关闭也要提供真实closure，不由父自己填true。

结果done保持scope96/Origin195/outcome2/reason32、source_pairs22/reader_pairs21/canny_input21/canny_class21/output_pixels22/edge_pixels22/discarded_fp22及CS592；梯度185/valid/ready沿原Canny口。诊断phase4和quarantined/source_stop用于观察，不凭诊断状态回收授权。AXI AW/W/B/AR/R公开端口同已通过桥128bit/ID4/address32；平台固定LOCK/CACHE/PROT/QOS普通访问属性，与V4端口接齐。

授权字节：SOURCE A64=64ceil(3N/64)、CLASS64ceil(N/256)、QUEUE64ceil(N/16)、RESULT64ceil(N/64)。四区base64对齐，端点扩33bit≤默认DDR容量268435456、六对区间互斥。CJ W/H与参数（偶W≥6/H≥5）一致、TL≤TH；不合法job仍真实接受后本地ERROR，不启动任何子job/AXI。生产默认1920×1080，没有尺寸/识别范围降级。

路径：raw_source_join实际行RAM→插值→双bank source writer→内层arbiter（source/reader）→外层arbiter（内层/Canny）→唯一axi_line_bridge→独立128bit bytearray端点。source结束并消费其done且matching RX closure良好后才启动reader和canny_full_top。reader从该source grant真实读取，FP74交给原R2；Canny写分类，再用实际cache/queue/HY处理并写EDGE。两个原arbiter保留owner直到真实回复消费，不更改旧公共请求；source/reader阶段互斥，PROCESS期间reader与Canny共享，每个请求有限完整容量。

## E 中文内部操作草图

enum IDLE/START_SOURCE/CAPTURE/WAIT_RX/START_CANNY/START_READER/WAIT_READER_CFG/PROCESS/DRAIN/DONE/Q。锁CJ/Origin/phase/base/handle；source_started/closed、reader_started/closed、canny_started/closed、rx_seen/rx_good、stopping和不可变最终计数。IDLE job_fire锁且核所有参数；合法START_SOURCE、非法ERROR→DRAIN，无RX义务。父job接纳同沿匹配cancel可直接取消且不启动任何子job。

START_SOURCE保持job_valid直到ready，source_started=1、closed=0，CAPTURE才开放RAW。真实source done_fire保存P/源写回指标并closed=1；OK进WAIT_RX（可与已记录RX event同沿），失败置stopping，仍等已启动RX closure。RX matching good0置ERROR/停止新RAW并匹配取消source。只有source OK+matching rx_seen/good才能启动Canny CJ和reader source job；两个配置/启动各按真实fire，reader cfg拒绝为父ERROR并视reader安全关闭，不等待不存在的done。

PROCESS reader FP通常接Canny ready；如果Canny先失败且其done已实际消费，父明确discard接收reader已公开FP，独立discarded_fp计数，再广播匹配取消reader并等reader done。若reader先安全ERROR，父停止新输入、取消Canny并等真实done；旧FP不撤回，由Canny接受或Canny安全done后discard。Source/reader/Canny各已启动valid与终态独立，父取消不得撤回处于保持的子job提案。

reason32位集：bit0非法job，bit1 RX质量错误，bit2 sourceERROR，bit3 readerERROR，bit4 CannyERROR，bit5成功计数不一致；多个实际错误保留，真正ERROR优先CANCEL。受控子CANCEL不冒充ERROR。DRAIN等source/reader/Canny已启动对象实际closed，以及source_started要求的matching RX closure；成功核source=P、reader=P、Canny输入P/分类P/结果N、discard0。然后DONE保持CJscope/Origin/计数/状态快照直到消费。Q由任意子/两个arbiter/AXI桥unknown汇合，停止新RAW/任务，保留公共body与完整身份，无safe done，外部共同安全rst才恢复。

source_done只是本地写回证据，matching RX closure不是全部FM发布条件；此父的局部阶段屏障是所有单job源写公共事务已回执且无另client活跃，不能冒充跨domain的完整DSphase fence。后续FM必须连完整scope/借用/冻结/显示引用及真实运输关闭。这里不进行物理硬件操作，也不以理想端点的B推断保护DDR IP读后可见性。

## F—H 独立验证、追踪与资源

CA-T01：独立二维RAW/CFA参考→连续RGB；再原独立R2数学与BFS生成分类/最终状态/FIFO/EDGE/梯度/CS592。TB只喂RAW；Canny所有FP必须来自实际源RAM的128bit R响应及reader，禁止另喂gold FP。源写回byte、读出FP、内存状态和终态全比对；至少四phase、median/retain、零图/彩条/空间纹理/形状。
T02：source done先于RX closure、RX先闭合、迟到CRC失败、错误Origin/handle不闭合；CJ配置/Origin提案变化不改锁字段；范围/overlap/身份拒绝不发AXI；held done/grad/public请求。
T03：取消各父阶段、held源W/B/readerAR/R/FP/EDGE写；四类RAW输入错误；源BRESP、readerRRESP、Canny分类/状态/结果响应错误；Canny先fail时真实reader FP discard；unknown不发布done，外部安全共同rst后新完整同源job。
T04：完整1920×1080至少一幅同源图，全源6.22MB及完整Canny所有内存/FP/CS核验；记录各client AR/AW/4beat/R/B实际事件和处理时钟，非实物fps承诺。T05：Ti60F225/I3实际MAP，预计46RAM=source8+Canny38（reader/bridge/arbiter零RAM）；以实际报告为准，公共接口随后连生产top，组件100MHz不称时序达标。T06：真实PHY/CSI/I2C/CDC、FM源/结果发布/冻结恢复、显示/TMDS/标注、识别和总资源/PNR/STA/bit。

追踪CA01同源/身份→Origin/CJ锁+RX+真实reader→T01/02/04；CA02安全关闭→三个done/discard/DRAIN/Q→T03；CA03实际共享接口/资源→两个arbiter+唯一AXI→T01/03/05。数学、接口和中文局部先形成，代码/测试再生成，原算法位宽/精度/五基础六高阶范围保持。

## J1 首次启动诊断（2026-10-09，先记录再改TB）

capture_small_001 编译/elab成功，但超过10分钟仍没有 actual-0.fp，说明等待发生在第一帧公开FP文件创建之前。按已记录的进程路径、PID和完整UTC启动时间核对后，仅终止该仿真进程树，旧日志和失败结果保留。不能等待10亿拍才定位错误。

TB在启动提案前后和前64拍打印真实父phase、legal、各子ready、各子状态、rst；wait_capture_ready最多1000拍，无进展或提前DONE/Q立刻报错，并显示完整legal输入。按W×H约束总watchdog为1000N+100000（不放宽期望、RTL或接口）。诊断仅增加观察/有界失败，后续重新用新RunId执行，保持用户“统计完后自行进行，无需批准”的持续授权。

J2：_002/_003诊断显示复位后所有子ready=1、父job_ready=X。vopt明确报告Canny实例漏接quarantined；父c_q无驱动，不符合原设计任一子Q汇合。修复实例接线 .quarantined(c_q)，不改变任何接口/算法/错误契约；同步TB握手等待使用四态严格ready===1，避免X被while当成假而撤回未接受提案。原失败保留，新_004重跑全部场景。

J3：_004已完成20幅数值图像，非法Origin协议用例确实ERROR/no AXI，但TB仍用变更前Origin作done期待。按原契约非法job仍锁实际job_fire的完整输入；修正该用例在改变输入Origin后同步expected locked_origin，不改变合法图像参考或RTL。重新运行_005。

J4：_005正常图像完成，但协议阶段DRAIN未关闭。先扩展watchdog实际诊断（已启动/关闭三个子、RX、子状态、AXI状态/公共valid），并打印协议场景编号，定位具体真实依赖；当前仅诊断TB，不修改算法或放宽关闭要求。

## J5 v1.1 取消适配（READY读回后自主实施）

_006真实显示父DRAIN/source未closed、AXI已空、RX已seen；原raw_source_join的matching_cancel在DRAIN仍每拍安排DRAIN，不能把持续取消电平当外部事件使用。旧已登记子源码保持只读，不修改它或其测试期待。组合层新增source_cancel_sent位：job_fire清0；已启动且未closed的source遇到child_cancel且未sent，仅向source发一拍cancel并置sent，source自行保留stopping。在START_SOURCE被取消也等子job真实fire后下一拍才交付该事件；没有启动source不发。reader/Canny的已有电平兼容取消仍保留。

父matching_cancel只在!stopping时成为新事件；DRAIN中保持cancel电平不能覆盖已经满足all_closed的DONE推进，ERROR保持优先。source_stop及reader/canny取消仍用sticky stopping，不重新开放输入。所有旧公共请求和RX关闭要求保持。新变量对应CA02/T03，补取消信号持续到done的用例；基线修订为v1.1，沿用用户持续自主授权和本地审计。当前先重跑_007，最终T03补齐后再MAP。

## J6 T03补测的操作草图（代码前保存/readback）

_007基础20图像/14协议已经实际完成RTL运行，等待独立审计。继续同v1.1范围补测：

1. job_fire同时匹配cancel，必须CANCEL且source不启动/no AXI/no RX义务；START_SOURCE/WAIT_RX/START_CANNY/START_READER/WAIT_CFG等5父阶段分别取消，cancel保持到done；已启动源必须匹配RX closure，未启动reader或Canny不等待不存在的done。
2. 源AW/W/B三个公开阶段分别外部hold、注入取消、保持15拍，公开valid/body保持且无父done；解除hold后等待真实公共关闭和三个子终态。仅暂控slave ready/valid，不force DUT。
3. 源预备完成且RX关闭后，分别hold reader AR/R，等真实公开有效，再取消15拍，无done、旧请求保持；放开后必须CANCEL及AXI空。另等待reader已有held FP、Canny输入反压的真实状态，再取消，旧FP要由Canny实际接收或父明确discard，不撤valid。
4. Canny的CLASS写、CLASS状态读和EDGE结果写各自通过真实地址筛选事务，事务开始后给slave一次正确ID错误响应；必须父reason bit4/ERROR，停止后所有已启动子终态、旧reader FP明确discard。CLASS错误场景观察到held FP才注入，并计数至少一次discard。
5. 结果写/状态读处理中取消，旧事务必须真正回应再关闭；reader错误RID/末拍不确定各自Q且没有父done，新job不ready；仅真实公共安全共同rst后再成功完整同源任务。enable loss在真实AXI在途期间Q，恢复enable不解锁。

所有新增错误/取消/隔离用例先记录目标/真实触发，再接受终态；不得把时间超时当成功。固定随机stall种子保持，10亿拍watchdog不恢复；全suite每job≤1000N+100000无进展拍（计总拍的基线仍足够20正常图像）。总体测试不降低1920×1080生产默认。

J7：_008已过24协议，正常内存供给比R2慢，不能凭等待自然held FP假定会触发；该等待最终得到成功DONE而不是held条件。TB改从生产公开grad_ready暂时施加反压来形成真实held FP；取消后交付旧GR，再等待关闭。prepare_source明确等待source_done与matching RX事件，防止提前hold_B卡住尚未关闭的源写。CLASS错误不以故障前自然held FP作为前置；真实错误使Canny停止接收之后观察reader旧FP由明确discard关闭，并独立断言discard>0。正常图像期待保持。

J8：_009错误已正确传播/关闭，但34×19在该CLASS故障时没有held reader FP，不能要求无旧FP也产生discard。补专门6×109（偶宽最小、行流水私有容量小、仍多于一条CLASS）同源组合故障场景；不是生产尺寸降级。runner增加明确W/H参数，参考和TB同参数，默认生产仍1920×1080。CLASS公开AW出现后才hold_B，避免hold_B挡住更早非目标事务；保持GR反压最多100拍，观察实际reader held FP，再给真实BRESP错误；6宽场景必须观察到held旧FP且discard>0，默认宽场景如有held旧FP同样要求discard，允许没有旧FP时discard=0。记录failed_fp_discards/held_fp_failure_witness指标，6宽专项PASS作为T03不可替代的额外前提。EDGE故障也仅目标AW出现后hold_B，不阻塞更早CLASS成功事务。

## K/L 本批实际结果与交付（2026-10-09）

源码为独立work/capture_canny_axi，共7份本单元RTL/模型/TB/脚本/工程文件；旧共享子源码未修改。34×19 small_010：20图像12,920像素和34协议PASS，14取消/14错误、错误BID/RID/末拍/enable丢失及安全共同reset。6×109 narrow_001：20图像13,080像素与同34协议PASS；真实held FP故障witness1、明确discard1。所有源/分类/最终state/queue/result/FP/梯度/CS592/Origin逐位对照通过。

capture_hd_001：完整1920×1080 PASS，2,073,600像素、1,036,800真实RAW/reader/Canny/class对、6,220,800源字节、source AW/AR各97,200，所有共享事务AW138,846/AR114,544、W555,384/R458,176/B138,846，edge1078、discard0，36,811,963作业处理拍。Questa结束exit0、独立审计PASS；固定软件AXI端点事件拍数不声称实际板卡fps。

capture_map_001：Ti60F225/I3实际综合exit0，46 RAM10、21,976 FF、27,109 LUT4、1,776 ADD、166 SRL8、0DSP。警告仅EFX0200冗余删除20条、EFX0657常量reader/writer小数组映射逻辑63条；未见未驱动接地/锁存警告。47模拟输入+3工程/脚本=50份MAP快照；三个通过run源码与MAP快照一致。旧失败attempt保留在work/runs，不抹历史。

基线v1.1仍54份，只有本设计卡经J1…J8修订后刷新，另53份保持原hash。登记包将保留本卡/原v1基线/新v1.1/全部通过输出及实际网表，执行前读回。阅读顺序与逐步操作位于work/capture_canny_axi/docs/README.md。新增组件未运行生产PNR/STA/bit、实际DDR/CSI/FM发布/显示/识别未完成；整目标ACTIVE，理解验收待用户实际作答，正式DB/state及硬件不改。
