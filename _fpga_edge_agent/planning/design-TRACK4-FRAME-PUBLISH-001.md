# TRACK4-FRAME-PUBLISH-001 v1：结果自动发布与旧帧回收控制

## A. 入口、目标、授权与基线

Goal：补齐最终父控制器的Result管理、APPLY后引用记录、旧帧回收及单owner命令仲裁。Current state：capture_owned已自动管理Source；display_owned_a64已经连接实际owner和完整扫描，但Result分配/END/OFFER/APPLY/RETIRE仍由测试程序手动推动。Target state：接受处理请求，真实ALLOC_RESULT→生产执行→真实关闭→RESULT_END→OFFER→显示实际回执→APPLY；oldclosed匹配实际已发布引用后自动RETIRE。Gap：本批控制接口的生产端点对抗测试不代替真实Canny/ANN生成；下一父顶层接已有实际执行模块和完整native扫描。

Task v1/2026-10-10，A3/A4/A5/A6/R0；路径 `work/active/track4_algorithms_20261004/frame_publish/`。五基础六高阶、Ti60F225/I3、SC431HAI、1080p及原识别范围保持。新独立包；HDK/旧work/staging只读。复用本机工具，不安装/联网/操作硬件。

READY_FOR_REVIEW，先保存、读回、呈现和冻结，再生成代码。引用用户“当你統計完后自行进行, 无需我的批准”及本地审计例外；不冒称本v1有新的人工回复。正式数据库/H0/Manifest和硬件状态不改。本控制组件无当前阻塞；实际生产输入、完整父顶层资源优化和物理DDR/板级验证继续保留。

Baseline：当前真实owner/pkg、A64 handoff/route/mailbox、fetch/row/pkg、独立Authority/legacy数学参考，以及现有sim/MAP/XML/SDC作为脚本参考。本设计/v0.2逐份冻结原路径/副本/SHA，不伪造commit。显示HD当前已在独立既有run进行，不改它的运行源码。

## B. 外部行为

|REQ|可检查规则|
|---|---|
|FP01|request fire锁token64、Source64/Origin195、CJ142、render112。Source0选真实owner最新/冻结对象；显式Source必须带canonical Origin。仅真实ALLOC_RESULT/OK启动生产端点；拒绝回执无job/OFFER/APPLY。|
|FP02|job承载真实分配942；mode1/2不需要EDGE/ANN，采用明确空生产义务直接安全END。mode0/3/4/5必须等待匹配Result64/Origin195/scope96的真实producer DONE；正常pixels=WH、discard=0；不能用数量代替DONE。|
|FP03|正常END7、安全错误/取消END6；未知关闭END0→owner隔离无安全完成。END flags/outcome/reason提出前封存；held job/CMD/route不随取消、halt/Q撤回。已公开安全completion不因晚到无关halt重写。|
|FP04|正常真实END/OK后领取全局非零单调sequence64，真实owner OFFER绑定同一个sequence，完整942进入显示。只有匹配真实HC_OK及实际相同bundle/policy/cause/sequence后提交APPLY。APPLY/OK后先把引用事件交给回收器，再公开正常completion。|
|FP05|actor取消每job最多一次；显示取消在route request实际fire后最多一次。未发布DONE可安全DROP2；已OFFERED只有显示HC_CANCELED且candidateClosed证明才DROP10。不从取消意图、超时、回执数量推断消费者关闭。|
|FP06|回收器仅记录三个真实APPLY引用：FrameRef387、CJ142、slot2及ACTIVE/RETIRING/closed。新APPLY的previousResult必须等于本地旧ACTIVE；旧ACTIVE成为RETIRING。early oldclosed可先记事实，必须成为RETIRING且匹配完整引用才RETIRE10。旧/错身份事件消耗忽略，不释放新对象。|
|FP07|一个共享owner命令口，四个客户端：Source管理、Result管理、回收、policy。仲裁先真实接受并锁941/sequence64，之后持有至owner fire与真实回执交付；轮转公平，不让后来请求改变已公开命令。回执只回到对应已接受客户端。|
|FP08|当前真实owner/handoff组合及明确producer/row0/closed端点fixture验证因果和反压；独立对象参考审查全部公开命令/回执、sequence、生产/显示/回收先后。参数1080p只作metadata/计数范围测试，不叫全像素Canny/显示测试。MAP实测本控制组件，整机资源/PNR/STA/bit继续未完成。|

正常：request→ALLOC_RESULT→job（需要时）→producer DONE→END7→sequence→OFFER→handoff→实际显示OK→APPLY→applied事件登记→completion。安全错误：DONE错误/取消→END6→completion，无OFFER。候选取消：OFFER→actual canceled/closed→DROP10→completion。旧帧：applied新对象使旧对象RETIRING＋真实oldclosed→RETIRE/OK→retired事件。缺少任何真实闭合事件都保持责任，不伪造成功。

## C. 模块和连接

MOD1 `frame_result_manager`：一个Result工作，使用一个942 context寄存器先保存请求字段、再保存真实分配/END/OFFER/APPLY回执，不复制多份完整包。锁token/sequence/previousResult、取消事实和终态。管理结果生命周期，不计算图像、不自行分配handle。

MOD2 `frame_result_retire`：三个精确引用槽（387+142位各三），仅是已发布对象的消费者闭合追踪，不分配Source/Result、不替代owner账本。公开applied事件记录、oldclosed消费、RETIRE命令、retired回执；root_retire_capacity为RETIRING数量<2且非Q。

MOD3 `frame_owner_command_arbiter4`：四路941/sequence64接受队列深度1；IDLE按轮转选输入，copy接受后REQUEST→REPLY直至所选客户端真实接收owner回执。全局reset才冲刷已接受责任。

MOD4 `frame_publish_control`：连接MOD1/2/3。Source与policy两路为外部合法命令：Source仅0..2，policy仅FREEZE/RESUME/BARRIER；Result工作与回收内部接仲裁。result route接唯一实际显示控制通道，policy路由由最终父控制器在result_idle且pause_new_requests期间独占，不能并发插入PREPARE或改变global sequence。

数据生产连接：真实ALLOC_REPLY→job942→既有Canny/识别/ANN父执行模块→真实DONE。显示连接：OFFER942/seq→现有A64 handoff或完整scan→response1207；关闭→回收器。当前测试明确用端点fixture观察控制语义，真实图像执行模块随后接入同样契约。

## D. 接口、编码与组合检查

|IF|参数/接受/身份|前提和保证|
|---|---|---|
|IF01 request/completion|req valid/ready；token64,Source64,Origin195,CJ142,render112；完成valid/ready,token64,outcome2,status4,reason64,bundle942|fire一次采样；caller保持held正文。status沿用owner枚举，safe producer错误status可为OK但outcome1；seq耗尽为控制器EXHAUSTED。reason低32为producer，bit32坏计数、33取消、34协议。完成bundle是回执身份，不授予新读权限。|
|IF02 producer|job valid/ready,bundle942；DONE valid/ready,Result64/Origin195/scope96,outcome2,reason32,pixels22,discard22；cancel脉冲,Result64/scope96；producerQ|仅新ALLOC/OK的942启动。真实父执行模块DONE必须证明所有读写/子producer关闭；本管理器不通过输入数量推断该证明。错误身份消费忽略。模式5必须包含真正识别/ANN关闭，不能将其空义务化。|
|IF03 owner|cmd941/reply942 valid/ready,offerSequence64|一次一命令；Result身份/CJ/policy/slot/body严格匹配分配回执。不改变owner编码、A64、handle不回绕规则。END/DROP/RETIRE关闭bit来自真实事实或明确尚未启动的空义务。|
|IF04 sequence|输入valid/ready,value64,exhausted1|最终父顶层为所有显示OFFER/PREPARE/COMMIT/RESUME维护一个单调分配器。0无效；耗尽不能回绕。领取后直到OFFER/显示完成锁定同值。|
|IF05 route|request1137/response1207 valid/ready；cancel脉冲及seq64|only HC_OFFER，本增量不生成freeze policy命令。正常响应必须完整匹配包、policy、seq、cause0且hasActive；取消必须candidateClosed。其它意外回执隔离，不能盲目DROP。|
|IF06 applied/oldclosed|applied valid/ready,seq64,bundle942,previousResult64；oldclosed valid/ready,FrameRef387；retired valid/ready/ref387|applied来自真实APPLY/OK；保存Source/Result/CJ/Origin/policy。oldclosed来自完整scope fence或当前明确fixture。只用完整匹配引用，不用slot或Result局部字段代替。retired只在真实RETIRE/OK后。|
|IF07 arbitration|四路packed valid/ready、command941/seq64、replyvalid/ready/reply942；owner单口|copy接受即为交接承诺，upstream可变输入不改下游held包；客户端读回执前不重新接受。轮转改变只在完整回执交付后。|
|IF08 pause/halt/reset|pause_new_requests1、halt1、rst同步高有效、core_clk|pause只阻止新request，不撤回内部held义务。halt/Q锁存，已接受承诺继续到允许的安全边界；未知为Q，只有共同cold恢复。owner、actor、handoff、回收及总线必须共同cold，不能单独清账本。|

W偶数4..1920/H偶数2..1080，N=WH≤2073600；所有字段unsigned、同域core上升沿。mode1/2无EDGE/ANN故空producer义务可END7；mode0/3/4/5的计数相同N，实际生产契约各自不同但必须由对应最终父执行模块证明。来源Canny只有Scope/Origin DONE时，适配器必须保存当前真实Result身份到真正job关闭，不能借当前请求字段伪造旧DONE归属。

每个Result输入仅用COMPLETE Source，ALLOC_RESULT flags0；不会趁WRITING读不完整帧。旧active的early closed仍可记录，但只有新APPLY后成为RETIRING才释放；槽不能在retired通知持有期间覆盖。policy改变必须等result_idle，维持现有冻结两阶段和global sequence一致。

## E. 逐状态中文草图

### MOD1 结果工作

IDLE→ALLOC_REQUEST→ALLOC_REPLY→START_JOB/WAIT_JOB（或空义务）→END_REQUEST→END_REPLY→SEQUENCE→OFFER_REQUEST→OFFER_REPLY→ROUTE_REQUEST→ROUTE_REPLY→APPLY_REQUEST→APPLY_REPLY→APPLIED→FINISHED；安全drop另有DROP_REQUEST/REPLY；未知Q。

1. request fire：把请求Source/Origin/CJ/render存入context对应字段，清本job事实、cancel_sent、route_sent、旧结果、terminal；下一周期公开ALLOC_RESULT。输入之后变化不影响本工作。
2. 实际ALLOC reply：op不是3即Q；status非OK给held错误completion无job；OK保存全部真实942。halt已发生登记END0；尚未公开job且用户取消，可用未启动空义务END6。mode1/2直接END7；其它进入START_JOB。
3. START_JOB已公开就保持至fire；fire后actor_started，后续最多一次cancel。等待匹配DONE；错身份事件忽略。DONE真实正常且N/零discard才可good；安全错误/取消使用END6；producerQ/未知或halt在未安全闭合时END0。不计时猜关闭。
4. 提出END前封存flags/outcome/reason；held END不受晚到cancel改变。END/OK保存真实回执；END6直接完成。good END后若取消尚未公开OFFER则DROP2；若seq耗尽也DROP2并记录EXHAUSTED；否则领取并锁seq。
5. OFFER cmd只有真实R_DONE；OFFER/OK保存原包。未公开route的halt隔离并保留对象；已公开route必须继续持有，不随Q撤回。取消只在route fire之后发一次cancel脉冲。
6. 实际route response：正常完整匹配才APPLY；已取消且closed才DROP10；其它回执Q，无伪造关闭。正常提交胜过晚到取消，不能把已经显示的对象按取消释放。
7. APPLY/OK保存回执与实际previousResult；先held applied事件交给MOD2，再held completion。晚到halt仍保持已公开安全applied/completion字段；下一job禁止。

### MOD2 回收

IDLE：可接收完整oldclosed，匹配ACTIVE或RETIRING槽就置closed事实。接applied前校验opAPPLY/statusOK、slot<3、该槽空、seq非零、previousResult等于旧ACTIVE；旧ACTIVE→RETIRING，新槽→ACTIVE，保存ref/CJ。发现不相容即Q，不凭输入释放。

只有RETIRING且closed的槽才选作RETIRE；本次选中slot锁定，REQUEST→REPLY→EVENT期间不接applied、不能覆盖该槽。oldclosed可继续记录其它槽事实。RETIRE命令从保存ref和CJ还原Source/Result/Origin/policy，flags10；body不作为身份检查输入，owner以保存的结果生成真实body回执。实际op/status/身份/CJ/policy/slot匹配OK才清槽并发held retired事件。缺少closed则永不释放；两槽RETIRING时root容量不足。

### MOD3 仲裁

空闲从上次完成客户端之后扫描四路，选第一valid并仅对该路ready。接受沿copy完整941/seq64和client index；下游owner cmd从copy输出，后来出现更优先请求不改它。实际owner cmd fire后等待reply，只向保存client输出valid/正文；对应reply fire才清busy、更新轮转。共同reset清，halt不撤回已经接受包。

不变量：job只由真实分配产生；good END必须真正DONE或合法空义务；OFFER以真实END/OK为前提；APPLY以实际显示OK为前提；旧帧RETIRE需实际APPLY后的RETIRING及完整closed；所有held义务直至真实fire；unknown没有安全completion；命令回执不串客户端。

## F. RTL及跨语言契约

A数字：941/942/1137/1207/387/142及64身份不截断，N22范围足够，无帧数据算术；B上升沿接受、非阻塞更新，TB下降沿驱动，沿前public fire记录；C每路valid/ready，cancel是匹配脉冲；D仅fire推进，无valid不充当零；E锁context/token/seq/end与仲裁copy，所有sideband持有；F控制往返可变且有限，无像素吞吐/FPS声明；G同步rst清本控制，所有拥有者共同cold；Hrequest快照、policy串行修改，暂停不撤回；I三引用槽529bit各及一命令copy，不增加完整帧RAM；J保留全Origin/CJ/scope/seq/Result/policy；K本控制单core域，跨域仍由复用handoff完成；LSystemVerilog、Ti60F225/I3、MAP10ns，PNR/STA/bit待整机。

C++ N/A。Python独立集合Authority比较owner命令与回执、真实OFFERsequence和结果状态；公开输入/输出事件验证因果。producer/row0/closed当前是明确端点fixture，不据fixture计数声称图像生产。数值、硬件握手、身份/关闭分别检查；源码、测试、run snapshot均按SHA绑定。

## G. 实施、验证、追踪和门槛

计划10份文件：4RTL、1TB、1独立参考、2脚本、XML/SDC。依赖复制后冻结。正常/错误测试全部保留，参数34×20、4×2、1920×1080仅验证控制字段范围，不重复独立扫描全像素证据；实际owner/handoff始终实例化，端点fixture单独标记。

|TEST|输入与期望|追踪|
|---|---|---|
|T01|六mode真实分配、上下文变化、holder反压、mode1/2无job，其余匹配DONE后自动OFFER/APPLY；无手动Result生命周期命令|FP01..04/07|
|T02|连续三对象及early/late/错误oldclosed，真实自动RETIRE、slot重用、无closed时池满拒绝无job|FP04/06/07|
|T03|cancel在未发布job、held job、等待DONE、held route、候选等待；最多一次各cancel，真实closed后DROP，未closed不完成|FP03/05|
|T04|producer错误、坏计数、旧Result/Scope/Origin DONE、UNKNOWN/halt/共同cold、held安全completion晚到halt|FP02/03/05|
|T05|Source及policy外部合法命令与Result/回收竞争，owner/客户端回执反压，已公开owner命令不被后来请求改写|FP06/07|
|T06|seq非零/耗尽、actual opcode/identity回应；sim/fatal/audit出口与末尾current/snapshot SHA；真实组件MAP|FP04/08|

追踪：FP01/02→manager.context/START/WAIT→T01/04；FP03/05→封存END/cancel/drop/Q→T03/04；FP04→sequence/OFFER/route/APPLY/applied→T01/02/06；FP06→retire槽/closed/RETIRE/EVENT→T02/05；FP07→arbcopy/turn/REPLY与wrapper→T05；FP08→TB/model/scripts/project→T06。每个新代码单元有职责依据。

READY十项：A范围/版本/授权，B行为/样例，C模块连接和复用，D接口与组合检查，E状态/中文草图，F语言，G验证与追踪；无控制组件阻塞；保存读回及呈现后才冻结，实现持续授权有效。失败先记录适用修订卡和依赖影响，不覆盖旧run。回滚停止使用新包，旧模块不改。完成后更新README/实际证据/staging；全Goal仍需真实生产父顶层、复杂识别、资源优化、DDR及板级闭合。理解验收待真实用户作答，不阻塞已授权软件实现。
