# TRACK4-CAPTURE-OWNED-001 v1：源帧自动分配、真实接收闭合与登记

## A. 入口、范围、授权与基线

Goal：实现最终自动发布父控制器的采集管理部分，把真实RAW采集从测试手动SOURCE命令中接出来。Current state：v29有真实并行采集/Canny、权威账本及ANN writer；采集Source分配/EOF/END仍由TB调用者驱动。Target state：请求帧 →实际owner分配 →真实capture actor启动 →接收方取得grant →实际RAW EOF、capture DONE、RX close联合驱动SOURCE_END。Gap：结果调度/显示切换/冻结重算/RETIRE仍属后续父控制器部分。

整体目标保留Ti60F225/I3、SC431HAI、1080p、原五基础六高阶；DDR允许、仅板载资源、不采用未经同意的形状限制。此增量不改变任何算法或既有模块。新路径 `work/active/track4_algorithms_20261004/capture_owned/`；旧work、staging和HDK只读。Task/v1/2026-10-10；关联H2/A3/R0。

状态READY_FOR_REVIEW，保存后真实读回/呈现/冻结再生成代码。引用用户“当你统計完后自行进行, 无需我的批准”及既有本地审计授权，不冒称本版本获得新聊天批准。正式PostgreSQL/Manifest/H0及硬件状态不变。当前组件无未决阻塞；相机CRC/CSI硬件、完整显示与DDR PHY不由本批替代。

Baseline：实际14份RTL/vendor依赖（RAW/color/window/line-store/CFA/RGB writer/RAM、write service/bridge、owner/pkg/row/pkg/fetch/pkg、RAM10），2份独立二维CFA参考，加已有TB/BFM/sim/MAP/XML参考、本设计和规范；冻结清单和SHA由实际文件生成，不猜总数或commit。工具沿用现有Questa/Efinity/Python，无安装/网络。

## B. 整体外部行为

|REQ|可观察要求|
|---|---|
|CO01|frame_valid/ready接受scope96={capture配置32,frame32,epoch32}与Bayer2快照；仅真实ALLOC_SOURCE/OK可启动actor。owner拒绝时只返回grant错误，不发actor job/RAW写或安全DONE。|
|CO02|actor job承载真实Source handle/base与scope/Bayer；实际job fire之后公开grant，grant正文在反压中保持。RX close只能在grant已交付后接收，不让未交付的有效grant指向已经释放的Source。|
|CO03|实际RAW接口EOF fire才产生SOURCE_EOF；管理器接收事件并锁存，在owner往返时仍接收真实capture DONE及RX close。源帧只有实际capture全部写回完成＋RX good/no-future close＋EOF登记完成才为COMPLETE。|
|CO04|DONE计数必须为P RAW/P RGB、A64写块、3N逻辑字节、A64物理字节、零discard；只数输入不足以成功。RX bad、捕获错误或取消在IO已闭合后提交SOURCE_END flags6，正常提交flags7。|
|CO05|用户取消或RX bad最多发一次实际actor cancel脉冲；旧handle/scope/Origin事件消耗但不更新当前工作。未收到RX no-future close时，不回收当前Source。|
|CO06|物理服务/actor UNKNOWN或halt时保留已公开命令、job、grant；在安全边界向owner提交SOURCE_END flags0，隔离不产生安全frame DONE。只有共同cold恢复。已公开安全DONE不因晚到无关Q改写。|
|CO07|安全frame DONE仅在实际SOURCE_END/OK后形成，保持Source身份/scope/Origin及outcome/reason直到消费。新帧不能在上个DONE/未消费grant存在时开始。Source状态与latest由唯一owner决定，不建第二份可分配账本。|
|CO08|真实manager→owner→RAW/color/writer→AW/W/B组合，独立二维CFA比较全部成功帧的Source字节、尾零、身份与闭合因果；包含完整1080p。组件MAP只证明当前综合资源，不证明整机PNR/STA/DDR/FPS。|

正常路径：frame请求 →ALLOC_SOURCE →actor job fire →grant fire →RAW输入 →实际EOF fire →SOURCE_EOF/OK →capture真实DONE和RX close可先后到达 →SOURCE_END7/OK →安全frame DONE。RX错误路径在子actor安全闭合后END6；未知闭合END0/QUARANTINED，无安全DONE。

## C. 模块与整体连接

MOD1 `frame_capture_manager`：可复用父控制器叶模块，独占本工作Source命令通道，保存身份/闭合证据和held输出；不做debayer、不判断真实CSI CRC、不管理Result。

MOD2 `frame_capture_owned_axi`：组合实际manager、frame_owner_read_authority、raw_source_join与write service/bridge；从真实RAW fire提取EOF事件。当前wrapper的owner只服务本采集增量；后续父顶层复用MOD1并用命令仲裁把采集/结果/显示连接到同一个owner，不能并存两份owner作为正式帧管理。

MOD3复用已有RAW/CFA/RGB与AXI依赖，不改旧源码。MOD4新TB/BFM与独立参考，Source初始A5只由实际W修改，期望由二维RAW/CFA计算。

控制：frame→MOD1→owner→MOD1→actor→grant；数据：RAW→actor→64B RPC→实际bridge→数学AXI字节内存；反馈：真实actorDONE＋RXclose＋EOFhook→MOD1→ownerEND→frameDONE。当前没有显示/算法命令，后续仲裁不允许改变held命令。

## D. 参数、接口与组合检查

全部unsigned，单clk上升沿，rst同步高有效；owner安全复位与actor/bridge共同复位。W偶数4..1920，H偶数2..1080；P=W*H/2，RGB L=3WH，A=ceil(L/64)*64；Source base=slot*8MiB，六slot，最大L6220800小于8MiB。

|IF|交接参数|约定|
|---|---|---|
|IF01 frame/grant|输入valid/ready,scope96,Bayer2；输出grant_valid/ready,status4,handle64,Origin195,scope96,Bayer2|frame fire采样；错误grant status沿用owner编码，handle/origin0，不启动子actor。正常grant仅actor job真实接受后形成，不能在halt时撤回。|
|IF02 owner|输出cmd_valid/ready,command941；输入reply_valid/ready,reply942|只ALLOC_SOURCE0、SOURCE_EOF1、SOURCE_END2；一次一命令、命令与回复相互匹配。END flags在提出时锁定，反压时不随新的RX/cancel改变。|
|IF03 actor|job valid/ready,base32,handle64,scope96,Bayer2；DONE valid/ready,id64,scope96,outcome2,reason8,RAW/RGB/lines/discard22,logical/physical32；cancel valid,id64|job公开后保持至fire；实际DONE证实两个子actor闭合，正常需全部计数；取消脉冲只一次，不持续驱动旧raw_source_join。|
|IF04 EOFhook|valid,handle64,scope96|来自RAW valid&&ready&&EOF，单周期事实事件，匹配当前身份才记录；不是从输入数量或captureDONE猜EOF。|
|IF05 RX close|valid/ready,handle64,scope96,Origin195,good1|接收方已交付grant且保证以后不再输入此身份的RAW；它可以在最后RAW后、captureDONE前或之后到达。bad包括CRC/overflow/取消收尾；本批仅运输此证明，真实CSI生成器仍未闭合。|
|IF06 cancel/halt|cancel valid/handle64；halt1、captureQ1|cancel匹配工作身份，旧身份无效；halt/Q锁存隔离，public输出仍持有。未接受的actor job若已公开，仍履行或等共同cold；不得随Q撤回。|
|IF07 frameDONE|valid/ready,handle64,Origin195,scope96,outcome2,reason8|outcome0成功/1安全错误/2安全取消；reason bit0capture错误、1count错误、2RX bad、3取消、4管理协议防御。只有实际ownerEND/OK给安全DONE；Q为独立输出，不伪装DONE。|
|IF08 AXI|实际128bit AW/W/B|A64四W完整strobe，真实B及RPCdrained；BFM核对仅当前Source固定窗口、4KiB和公共holding，参考不从DUT私有RAM取期望。|

接受当前DONE/RX/EOF时保存事实，owner命令往返不丢事件。RXready不依赖RX当前good或身份，错误旧事件可消费后忽略；实际current事件只记一次。grant交付前不能接收RXclose，防止正常grant尚未消费而Source被回收。当前writer/camera可以反压；不可暂停MIPI的丢帧/缓冲机制仍为后续任务，不假设有限FIFO永不满。

## E. 内部中文操作草图

状态IDLE→ALLOC_REQUEST→ALLOC_REPLY→START_CAPTURE→WAIT_CLOSE；需要EOF时EOF_REQUEST→EOF_REPLY→WAIT_CLOSE；闭合后END_REQUEST→END_REPLY→FINISHED；分配拒绝REJECTED，未知闭合Q。

1. frame fire：锁scope/Bayer，清当前身份、EOF/DONE/RX/取消标志和grant交付标志；形成ALLOC_SOURCE，只填Origin的frame/epoch64，下一周期公开命令。
2. ALLOC reply：op与请求不符属管理错误隔离；正常owner拒绝形成held错误grant，不发actor job。OK保存Source handle/Origin/slot。若halt已发生，不新提出actor job，登记END0；否则公开START_CAPTURE job。
3. START_CAPTURE：job正文不随输入变化/取消/halt改变；fire后capture_started置1、held正常grant置1，进入WAIT_CLOSE。grant真实fire后grant_delivered置1；reject grant交付后回IDLE。
4. 全活动阶段每个上升沿独立监视EOF、actorDONE、RXclose。匹配时各锁存一次；actorDONE只依据公开计数形成capture_good。scope/Origin错的事件不关闭当前工作。取消原因锁存；capture已开始、尚未DONE且还没发cancel时，发一次cancel脉冲。
5. WAIT_CLOSE：halt/actorQ优先计划END0；否则先把实际EOF登记。正常成功必须EOF已登记；capture/RX安全错误或取消可在没有EOF时END6，但仍需真实captureDONE和RXclose两个证明。
6. 每次提出END前锁定flags、最终outcome/reason；END等待中不改公开flags。晚到取消在命令已提出后不追溯改变已封存Source结论；新异常仍可锁全局Q并禁止下个frame。
7. END reply：flags0预期QUARANTINED，进入Q无安全DONE；闭合flags6/7且replyOK才形成held frameDONE。安全DONE独立于新halt维持，真实消费后才可回空闲。grant未消费时也禁止新frame。
8. 同步cold清本体所有状态；必须同时复位owner、RAW/writer/bridge/BFM协议域。Source像素RAM/DDR不靠本模块整帧清零，已释放身份隔离旧字节。

不变量：capjob只由真实分配产生；RXseen蕴含grant_delivered；正常END蕴含EOFack、captureDONE正常计数、RXgood、无取消；一个工作cancel最多一次；END/publicjob/grant/frameDONE持有至真实fire；未知Source不可重新分配；身份由owner生成，不自行计数handle。

## F. 语言与映射契约

RTL A：handle64不截断，Origin195、scope96、base32、计数22、L/A32；地址固定slot且33位范围由既有bridge检查。B/C：下降沿驱动TB，上升沿观察真实fire、非阻塞更新下一周期输出。D：无valid不推进输入事实，控制状态由真实回复推进。E：公开字段使用锁存配置/结论；帧请求变化不改当前工作。F：元数据命令至少一次owner往返，采集P个实际RAW fire，后续CFA/存储等待可变，不推算FPS。G：同步reset禁接受，owner异步断言两拍释放；共同cold才作废所有在途。H：scope/Bayer只在frame fire采样，无中途配置生效。I：仅保存工作元数据/事实，frame存储由已有actor和board服务承担，不新增完整图像RAM。J：RAW双像素x/y/markers与Source handle绑定，CFA相位快照不漂移。K：组件单域，无新CDC；真实CSI/video/DDR域后续整合。L：SystemVerilog、Ti60F225/I3组件MAP目标10ns，未保证PNR/STA或物理100MHz。

C++ N/A，本批Python独立二维RAW/reflect101/CFA参考；公共W重建Source字节，期望不用RTL RAM状态。数值逐位、硬件握手与身份/闭合另审计；参考循环不能代替RX/owner实际事件先后证据。

## G. 实施与验证计划

计划9份新文件：2 RTL（manager/owned_axi）、2 TB（平台/数学内存）、1独立参考、2脚本、XML/SDC。先草图读回冻结；再实现；当前小尺寸/最小边界/完整1080p仿真与独立总线审计；随后当前组件MAP；登记只读staging和新全目标检查点。

|TEST|输入/期望/追踪|
|---|---|
|T01|各Bayer/二维图、相邻帧无reset、frame输入配置扰动、实际全部Source字节/尾零；CO01..04/07/08。|
|T02|grant/owner/actor/DONE反压，RXclose早于/晚于actorDONE，EOF命令往返不漏事实；完整成功只有最后真实证明后；CO02..04。|
|T03|旧handle/scope/Origin RX与旧取消、重复scope frame/epochowner拒绝，不污染当前Source；CO01/05。|
|T04|RX bad/部分输入取消、child安全错误，Root只一次cancel、END6且latest不改；没有RXclose时不结束；CO04/05/07。|
|T05|held RPC/W/B阶段取消、BRESP错误、wrongBID UNKNOWN、halt未接收job/owner请求、共同cold恢复、held安全DONE后的无关Q；CO05/06。|
|T06|owner分配拒绝（池满/重复身份/耗尽适用环境），只有错误grant，无childstart或DONE；CO01/07。|
|T07|实际vlib/vlog/vopt/vsim及expected fatal非零、独立audit、current/snapshot末尾hash；1920×1080全像素而不是缩图；MAP读实际资源/警告；CO08。|

验证计划不是已运行结果；具体场景数量以实际独立输入列表冻结并核对，不默默删除失败场景。Source物理字节只由实际W改变；RAW期望是独立二维公式和既有冻结CFA数学，真实RX生成器仍未实现，不把fixture close叫作CRC测试。

## H. 追踪与评审

CO01/02→manager.frame/ALLOC/START及owned连接→T01/02/03/06；CO03/04→EOFhook/事实寄存器/end_flags→T01/02/04；CO05/06→cancel_sent/held事务/Q→T03..05；CO07→ownerEND真实回复/FINISHED→T02/04..06；CO08→实际owned_AXI/TB/model/scripts/project→T01/T07。每个新代码单元均在这些职责内，后续实现实录指向具体symbol与日志。

READY门槛：整体行为/例子B，职责与复用C，接口相容D，内部状态/中文草图E，A–L/数值/事务映射F，走查与验证/追踪G/H；无本组件阻塞；版本、授权、路径A。文件保存后读回/呈现再冻结满足最后检查，不新增重复批准等待。

## I. 失败、变更、交付与实录

尚未实施/运行本批。失败保留旧run/snapshot，定位后先写适用修订卡、读回再改；用户持续授权仍有效。回滚只停止使用本新组件，旧模块不动。Artifacts为设计/冻结baseline→README→代码/参考/TB→真实runs→完成核对/资源→staging manifest。完成标准是CO01..08当前组件证据成立，不能以此标记全工程完成；理解验收待用户实际作答，不阻塞已授权实现。下一增量接结果/显示发布、冻结回调与旧帧回收；前述A16/A64显示校验差异必须修订，不能直接接上并声称整包闭合。
