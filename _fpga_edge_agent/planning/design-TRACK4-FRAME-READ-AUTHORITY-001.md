# 帧账本的权威只读查询：TRACK4-FRAME-READ-AUTHORITY-001

## A. 状态、范围、基线和授权

版本v1，2026-10-10，READY_FOR_REVIEW；本卡先保存、实际读回并呈现，然后按用户“当你统计完后自行进行，无需我的批准”及整批本地审计例外自主实施。不冒称用户另行批准了本卡v1，不改正式Manifest、PostgreSQL、H0或硬件状态。上一goal turn为PROGRESS：v26登记生产位图组件，共34个登记组件、338份实现/验证文件；全部已知运行终止，不重启已PASS运行。

Goal：原1080p、五基础/六高阶、现有板卡资源和完整识别范围保持不变。本增量位于帧生产发布与显示取数之间。Current state：实际owner64分配和writer→reader已经验证，但lookup_permitted是测试输入。Target state：显示的完整FrameRef和行需求由唯一帧账本直接判断，并返回该记录的不可变完整描述。Gap：owner尚无sequence绑定和权威lookup端口。

范围：在新work/frame_read_authority适配一份frame_owner_read_authority.sv，保留原941/942命令/回执、六Source/三Result及生命周期；增加OFFER时的sequence64伴随输入和479位显示查询。实现独立参考、原账本兼容回归、查询测试和组件MAP。本卡不声称采集完成自动闭合、真实scan/root fence接入、CSI/DDR PHY、整机资源/FPS、PNR/STA或bit通过。

事实来源：production_bitmap的owner/pkg/row pkg；display_fetch的demand_t/frame_ref_t；display_scan的prefetch在lookup_valid&&lookup_ready沿把bundle/permitted直接交给真实reader；display_route在FREEZE/RESUME时保留原active，因此旧active的结果policy不能因全局policy递增而失去RO；原frame_owner TB和对象/租约集合参考。原工程、旧work和staging只读。

补充基线冻结15项：owner/pkg/row pkg共3，fetch pkg1，原owner TB/model/sim/map/XML/SDC共6，实际prefetch core、route、handoff共3，本卡及详细规范2。精确路径/SHA保存新work/baseline.json。新8份：RTL1、TB2、Python参考1、运行脚本2、XML/SDC2；复用3包及原对象参考1，不把复用依赖算成新写代码。实际sim清单9份，MAP绑定sim9加工程/脚本3共12份，只有4份包/生产RTL参与综合。

Assumptions：core100MHz，同safe_reset_n共同可信cold；root产生非零、全局递增OFFER sequence，并在真实旧scope closed后才DROP/RETIRE。SOURCE_END/RESULT_END闭合flags仍由生产root提供，本次单测明确是环境事件，不能冒称真实CSI/算法自动发布。当前查询正确性无未决阻塞；完整root接入和物理资料另闭合。原display_route/prefetch仍使用A16，后续小尺寸A64整合必须显式传播FRAME_ALIGNMENT；生产1080p三个分配均恰好A64整除，不能因此省略参数一致性。

Dependencies：现有Questa2024.1、Efinity2026.1.132、Python3.14，Ti60F225/I3。不开新工具/网络/安装。原APPROVAL/DB及人工硬件闸门不改；沿用软件本地审计例外。

## B. 整体外部行为

|REQ|外部行为和判据|
|---|---|
|RA01|唯一账本维持六Source、三Result，原分配/闭合/冻结/回收语义和941/942编码保持。新模块默认FRAME_ALIGNMENT=64，仍支持16。|
|RA02|仅成功OFFER把offer_sequence64绑定到该Result；必须非零且大于上次成功OFFER的sequence，零/重复/回退返回IDENTITY且无状态或绑定更新。原FIELD/IDENTITY/STATE/NOT_READY/NO_SPACE检查优先。达到MAX后只禁止新的有效OFFER，不回绕，不妨碍APPLY/关闭/回收。|
|RA03|lookup479={sequence64,scan64,result64,policy64,Origin195,target_y11,source_y11,mode3,mask3}。仅匹配原记录的sequence/result/policy/完整Origin、Source COMPLETE、Result OFFERED/DISPLAY/RETIRING及合法行需求时允许。WORKING/DONE/FREE/Q不得被查询授权。|
|RA04|合法查询返回规范OFFER回执942：op5/status0、完整Source/result/Origin/CJ/body/policy/slot来自旧真实账本，而不是caller提交的bundle。拒绝时permitted=0且bundle=0。|
|RA05|mode0上下半屏mask1/2，source_y=2*(target_y mod H/2)；mode1/2 mask1，3 mask2，4 mask3，5 mask7且source_y=target_y。target_y<H、scan/sequence非零。任何身份、行、mode或mask差异都拒绝。|
|RA06|原cmd优先；lookup仅running、无cmd_valid且无held reply时ready。查询无状态副作用；busy期间不公开许可。成功query不自动减少引用，物理读取结束/无future仍是外部fence义务。|
|RA07|旧active/retiring按Result自己的policy获得RO；FREEZE/RESUME/BARRIER改变全局policy不会撤掉旧scope。DROP/RETIRE成功释放Result时清sequence，复用同slot的新handle不得承认旧FrameRef。全局Q阻止新lookup；cold清所有绑定与last sequence。|
|RA08|当前源码实际兼容/查询仿真、独立事件审计和MAP；错误、holding、复位/近MAX及失败原样留证，不把查询PASS当整机授权或物理fence证明。|

正常：源帧真实账本已COMPLETE、结果DONE；OFFER sequence10成功形成OFFERED，显示用sequence10/该Result/policy/Origin查询首行，返回真实描述；APPLY后和后续scan继续合法；新结果sequence20切换后，旧Result RETIRING仍可完成既有scope，直到真实RETIRE后拒绝旧查询。

边界：全局policy由1递增到2，旧active仍携policy1查询；新Result必须绑定新policy。两个Result引用同Source也必须分别匹配sequence/result。sequence=MAX一次可以成功，后续0/小值不会回绕；错误OFFER不消费合法sequence。取消后DROP要求原flags所规定真实closure，本模块不替root伪造。

## C. 职责与整体连接

```text
生产root的真实分配/完成/发布事件
  RA-IF1：cmd941 + OFFER sequence64，正沿valid/ready
      ↓ 唯一frame_owner_read_authority
  原Source/Result账本 + 每Result sequence64 + last_offer_sequence64
      ↑ RA-IF2：真实prefetch lookup479
      ↓ 同一fire沿permitted1 + 规范OFFER bundle942
  实际reader/span/native RAM/扫描（下次整合）
      ↓ 旧scope真实closed → root RETIRE/DROP（原命令）
```

MOD1适配原owner：仍负责唯一槽账本，直接查询自己的旧存储；不另建942×3影子表，不代替生产完成或DDR服务。MOD2验证：原对象/租约集合参考独立推导所有命令，补sequence和数学行映射；兼容TB保留原场景，新增查询TB覆盖正反例/停顿/复位。MOD3脚本/工程：复制冻结快照、真实工具、stage结果与SHA，只MAP。划界是现有单时钟账本和lookup边界，不添加无关调度框架。

## D. 接口与组合检查

RA-IF1原core_clk/safe_reset_n、cmd_valid/cmd_ready、command941、reply_valid/reply_ready/reply942和公开state/latest/freeze/policy/Q/exhaust端口保持；新增unsigned offer_sequence64，只在OFFER真实cmd fire采样，其他op忽略。root必须把它和cmd保持到fire。OFFER后返回原规范reply，不添加sequence到既有942字段；root已经持有所发sequence。原Source/Result身份不缩短。

RA-IF2：lookup_valid输入、lookup_ready输出、lookup_demand479输入、lookup_bundle942及lookup_permitted输出。提供方root/prefetch持有需求；本module返回权限/描述。响应与请求在同一个core正沿fire采样，ready=0时结果字段没有保持承诺，必须为0；需求必须保持。没有独立response valid，也不锁第二份942。command与lookup不能同沿接受，command优先，held reply期间lookup等待。无valid时输出0，不把数值0当合法帧。

FrameRef387={sequence64,result64,policy64,Origin195}，不含scan；scan只要求非零，实际scan token与scope/行票据的在途一致性由现有prefetch/scan核对。Origin完整来自source_origin(handle,epoch,handle,slot)，cj也来自Result config_snapshot及Source frame_epoch。query检查Result state后再检查Source slot/state，避免从坏slot索引。bundle body使用原result_body，Source/EDGE/ANN allocation遵循FRAME_ALIGNMENT。

组合：prefetch已有479顺序完全一致，在lookup fire才读取结果并交给reader；caller不能用自行改过的bundle骗权限。OFFERED允许候选预取，DISPLAY允许当前帧，RETIRING保留旧scope；只有真实closed后允许父RETIRE，不把查询次数当物理债计数。全局policy与Result policy区分，符合route在冻结期间保留active的实际行为。新模块与旧unit分别存放，后续生产父只换实例/接端口并传播A64，不修改已登记旧工程。

预算：绑定增加3×64+64=256FF，状态不增加帧缓存；查询比较/三个候选mux可能增LUT，实际MAP决定，不能把原9624 LUT加理论量说成整机达标。100MHz只是组件约束，不是STA/FPS证据。command临时941、reply942沿用原结构。

## E. 内部中文操作和语法组织

1. 声明3个ro_sequence寄存器及next_ro_sequence、last_offer_sequence/n_last。原always_comb复制Source/Result旧状态时也复制绑定，不改原操作顺序。OFFER原所有校验通过后再检查sequence非零且严格递增，成功提交R_OFFERED、该slot绑定及n_last；错误仅形成原错误回执，其他账本不动。
2. 原所有引用合并/回收之后，凡next_results[r].state==R_FREE就把该slot next绑定清0。RO_Q保留数值但全局Q禁止新lookup；不能因查询拒绝释放引用。时序always_ff与原账本一起非阻塞提交；safe_reset_n清绑定和last，INIT_LAST_OFFER_SEQUENCE仅用于近MAX测试，默认0。
3. 单独的命名组合块read_authority从旧账本读值，默认bundle/permitted0。仅lookup_valid&&lookup_ready且!quarantined时走查三个Result；先检查R_OFFERED/DISPLAY/RETIRING、完整handle/policy/sequence和有效Source slot，再检查Source COMPLETE/完整Origin及合法非零scan/行/mode/mask。所有条件成立才构建op5/status0规范reply。索引用有边界的整数，不和原command临时索引共享驱动。
4. mode0用编译期H/2取上下半屏，source_y由target_y减常量/左移1计算，不生成可变除法；其他mode直接target_y。source_y比较11位，静态H最大1080映射最大H-2。mask是3bit集合，不能只检查subset而接受多读。
5. lookup不写任何状态。old flags仍由实际叶/client提供。query已接受之后父必须保留borrowed FrameRef到真实scope结束，不能让DROP/RETIRE先发生；当前模块用原command closure契约管理此边界，不新增“query已返回等于读已结束”的错误推断。

不变量：有效绑定只对应成功OFFER之后同一个未FREE Result；last从不回退；所有Result使用slot保存Source借用代次，不能从同slot新Source生成旧Origin；规范bundle始终来自账本；query拒绝、valid0和busy均无状态副作用；旧scope的policy不被新全局值替换。

## F. 语言、时间和平台契约

SystemVerilog sv_09，Questa -sv；时序<=、组合=、默认赋值完整。unsigned sequence64直接比较，无加1回绕；row11、mode/mask3，N/描述32，固定slot3/2。core100MHz正沿采样旧valid/ready，沿后cmd状态/回执更新；相邻同步lookup consumer在该fire沿取得旧规范结果。TB负沿驱动/正沿采样，持有回执时不得接受另一cmd/lookup。

safe_reset_n沿用异步断言、本core两沿释放；cold使cmd/reply/query无效并清FF，无RAM需要整帧清零。无新CDC，后续video→core需求沿用既有atomic mailbox；不能把本单时钟测试说成physical CDC验证。配置只由ALLOC_RESULT锁存，query/全局policy变化不能修改Result的CJ/render。输入无效忽略，busy结果0。四态unknown在RTL仿真中不满足完整允许条件；二态综合不证明物理X检测。

C++ N/A（本增量不实现C++）；Python原模型为对象/租约集合参考，另按数学A64组描述、独立sequence绑定和行规则。三份跨语言契约：数值是941/942/479精确packed字段及A64；执行是cmd/lookup真fire、优先级/holding/cold；对应是每条公开cmd及lookup事件匹配同一Source/Result/sequence/config，不用DUT私有数组作期望。

## G. 实施与验证计划

Milestones：M1冻结15输入/读回呈现；M2适配唯一owner与独立参考/兼容TB；M3新增查询TB/实际sim；M4当前同源MAP与资源警告核查；M5文档、追踪、staging登记。Detailed steps按M依赖执行，实际场景未运行前不得自动填PASS。State transitions：READY→依持久授权IMPLEMENTING→VERIFYING→DELIVERED_COMPONENT；完整goal仍ACTIVE。

|TEST|公开输入和观察|独立期望/判据|
|---|---|---|
|RA-T1|原owner全部命令/身份/借用/错误/holding/cold场景；每次OFFER伴随递增sequence，A64描述|原对象Ledger参考加数学A64及成功OFFER绑定，逐942/公开states/latest/freeze/policy/Q比对。|
|RA-T2|查询WORKING/DONE/OFFERED/DISPLAY/RETIRING/FREE，全部mode/上下半屏，W/H=6×6、34×20及1920×1080|数值行映射及完整FrameRef，允许bundle必须来自旧账本，拒绝bundle0；HD只证明控制几何，不冒称HD像素处理。|
|RA-T3|逐项翻转sequence/result/policy/Origin、scan0、行越界、wrong mode/mask/source_y；同Source两个Result/slot复用|任何差异拒绝且账本无副作用；旧FrameRef在RETIRE后以及同slot新handle重用后仍拒绝。|
|RA-T4|OFFER sequence0/重复/倒退、原错误优先、最后MAX合法与后续回绕拒绝；Source/result/policy nearMAX|错误不推进last/不改变原状态，last仅成功OFFER提交。|
|RA-T5|FREEZE/RESUME/BARRIER后旧active和retiring仍读原policy；Q禁止lookup，cold清所有绑定|独立旧scope租约；不把globalPolicy与Result policy混淆。|
|RA-T6|cmd与query同沿、held reply下held query、query气泡、命令和回复holding、reset在pending边界|cmd优先且query仅真实fire，需求正文稳定；公开命令/状态/lookup事件和周期分别审计。|
|RA-T7|真实fatal探针、真实vlog/vopt/vsim/audit及当前同源Efinity MAP|预期fatal必须非零有marker，正常全部退出0；9源/15冻结及12MAP输入末尾SHA匹配，资源从实际网表/报告核对。|

Failure handling：保存原attempt/源码/日志；实现偏离先短卡修订，再按持久范围继续，不改期望掩盖错误。观察丢失恢复同一实际进程/结果，不因等待超时重启。Rollback：停用新work实例引用，旧work/产物未改，无破坏删除。

Artifacts/hashes：baseline15、source snapshots、公开cmd/query事件、suite/reference audit、实际MAP/资源警告、manifest。Human approval gates：软件持久自主授权和本地审计例外有效；不操作硬件、不改数据库，本批无bit；完整最终bit之后停止在人工硬件闸门。

## H. 双向追踪

RA01/02/07→MOD1原command/OFFER绑定/回收→frame_owner_read_authority.sv→T1/T4/T5；RA03..06→MOD1 read_authority/IF2/规范bundle→同RTL及新查询TB→T2/T3/T6；RA08→MOD2独立参考、两个TB和MOD3快照/工具→T1..T7。拟写8文件仅计划，未生成/未测试。每个新增寄存器对应RA02/07，每条query检查对应RA03/05，脚本及工程只支撑RA08，不增加额外业务。

## I. 门槛与阅读

§10.3：B整体/正反例；C职责与实际复用；D端口、packed格式及组合；E状态/内部语句组织/不变量；F语言/时间/存储/CDC；D/E正常、旧scope和失败走查；G/H计划/独立期望/追踪；A当前正确性无未决阻塞；本卡落盘后读回并给用户入口；v1/15项/独立work/8拟写文件明确。以上是设计分析，不是功能PASS或用户理解证据。

先读B整体→C连接→D接口→E语句组织→G/H测试与代码定位。当前READY_FOR_REVIEW，按用户持久自主软件指令，读回/呈现和冻结后进入实现，不重复索取用户已取消的逐批批准。

## J/K/L. 变更、实录与交付（待实现后填写）

目前尚无本增量业务代码。未来最终README必须对照实际符号/参数/状态/测试，注明生产自动闭合、真实fence/scan/PHY、整机resource/PNR/STA/bit仍未完成；用户理解验收待实际作答。Completion criteria是本组件全部T1..T7当前范围证据和staging登记，不是把全goal缩成只读查询。
