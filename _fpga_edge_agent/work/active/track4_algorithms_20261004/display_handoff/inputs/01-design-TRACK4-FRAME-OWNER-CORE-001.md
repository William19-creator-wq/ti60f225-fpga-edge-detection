# 帧所有权核心：六源、三结果、冻结与发布 v1

- Goal：实现完整工程的源/结果槽唯一账本，防止在读帧被覆盖、坏帧发布和迟到归还释放新代次。
- Current state：CAMERA-RAW-BRIDGE当前源1080p/综合已登记；原FRAME-MANAGER v0.1只有候选，未实现。
- Target state：生产RTL账本、中文操作草图、独立租约集合参考、错误/压力/代次测试及Ti60F225/I3 MAP。
- Gap：源/结果角色管理尚无代码；显示实际VSYNC/预取/控制CDC后续接此账本，不虚构当前已有。
- Assumptions：一个core_clk域，命令入口已原子运输；IO/producer/consumer closed只能由真实叶客户端排空提供。
- Open questions：物理DDR动态模型/CSI CRC closure/显示读QoS仍未闭合；它们不阻塞这个独立账本，但不能据账本测试宣布整机通过。
- Dependencies：v0.2、旧FM/显示交接候选、当前capture_canny_axi及142bit CJ/195bit Origin实际口、DDR256MB地址证据。
- Milestones：保存读回→包/账本/参考/TB→仿真→MAP→登记，再做真实显示交接与整合。
- Detailed steps：B外部→C连接→D端口/组合→E中文操作→F语言→G/H测试追踪。
- State transitions：READY_FOR_REVIEW读回呈现后，按用户“自行进行, 无需我的批准”的授权实施，不伪造逐版批准。
- Artifacts and hashes：baseline.json冻结依赖和实施前设计，运行源SHA绑定；失败和旧尝试保持。
- Validation：每真实命令及回复、租约集合、状态、身份、配置、布局、代次耗尽；实际MAP资源。
- Failure handling：闭合未知隔离，不清占用；错/重复/迟到身份拒绝，返回明确状态。无资源不覆盖。
- Human approval gates：既有自主软件授权/本地审计有效；原HDK/安装/正式DB/state不动，无硬件动作。
- Rollback：只新增work/active/track4_algorithms_20261004/frame_owner独立单元。
- Completion criteria：当前单元源绑定仿真/MAP闭合，不缩小整机目标，不将未做的显示/DDR/识别/PNR/STA/bit算完成。

## A. 范围、版本与事实

TRACK4-FRAME-OWNER-CORE-001 v1，2026-10-09，关联H2/A2/A3/A5/A6。此核心承担旧FM的账本/原子事件/源引用，不承担视频路由器、物理fence提供者或业务控制器。核心事件接口是新实际实现版本，旧OFFER1963/full grant623等未实施提议不被冒充成已相容；后续统一父端口要吸收实际实现。

实际CJ142从高到低为retain_grad1、median1、high11、low11、H11、W11、config32、frame32、epoch32。Origin195为capture_seq64/frame32/epoch32/source_gen64/slot3。新唯一source_handle64同时作为capture_seq和source_gen，零无对象，64位从1起、不回绕；结果独立handle64也不回绕。申请源的frame/epoch由输入Origin对应字段给定，不允许与存活源同frame/epoch撞名。

计划自写8份：rtl/frame_owner_pkg.sv、rtl/frame_owner.sv、model/frame_owner_reference.py、tb/tb_frame_owner.sv、scripts/run_owner_sim.ps1、scripts/run_owner_map.ps1、project/frame_owner_component.xml/.sdc。文档/基线/日志单列。任何未来解耦优化先修此文档，不提前证明实时采集能力。

## B. 可观察行为

FO01：6源槽，3结果槽；所有占用只由唯一账本改变，命令与回复一对一、回复保持。无源返回NO_SPACE并不覆盖任何槽。此拒绝属于采集容量问题，不冒称普通算法跳帧。

FO02：源ALLOC→WRITING→EOF/DRAIN→END。成功必须data_good、IO_closed、producer_closed三位全1，且已EOF；坏但全closed变BAD，可在无保留后回收。closed缺失变QUARANTINED，全局禁止新分配。源成功按64位采集顺序更新latest，迟完成旧源不能替换较新latest。

FO03：先找空结果，再借完整latest/freeze或明确许可的正在写源。一次原子建立BIND、锁CJ/config、原Origin和policy。成功结果DONE需IO/producer closed；pending满仍占DONE和BIND；只在源COMPLETE、结果DONE、policy当前、无别的OFFERED时OFFER。所有图与源身份作为同一回复发布。

FO04：APPLY来自显示域真实应用事件，登记新DISPLAY、旧DISPLAY转RETIRING；旧结果及其源在明确IO_closed和consumer_closed之前不释放。允许两RETIRING。OFFERED取消须显式consumer_closed，不把超时当排空。

FO05：FREEZE来自真实显示快照及其hold，必须完整source/result handle与Origin相容；允许视频已B、core尚A时B在OFFERED，先建立FREEZE再回复，调用者消费回复后才能解除hold。NO_ACTIVE时用已有完整latest，否则FREEZE_WAIT_FIRST，第一成功源与freeze保留同一原子更新。RESUME只解除FREEZE，其他BIND/latest不变。

FO06：FREEZE/RESUME/BARRIER改变policy，新旧结果不混发布；普通配置随ALLOC_RESULT采样。旧已实际APPLY的事实不能被core策略变化抹去，显示事件必须有序并由外部路由器贯彻策略屏障；本核心只管理引用和新OFFER资格，路由器后续实现。

FO07：非法/过期身份、非法字段、重复事件不修改新对象。所有handle/Origin与当前槽完整匹配。代次耗尽明确EXHAUSTED，不回绕。safe_reset_n仅允许平台确认全部旧访问关闭后的共同安全冷复位，普通cancel使用END/DROP并带真实closed。

正常例：源A结束→结果A完整→OFFER→实际APPLY A→源B/结果B发布应用→A退役未closed仍保留→合法RETIRE关闭才回收。边界例：六槽分别被BIND×3、FREEZE、latest、DRAIN占用，再申请不覆盖；源旧帧晚完成保持新latest。失败例：source END good但未收到所有写回复，隔离而非COMPLETE。

## C. 职责和整体连接

frame_owner_pkg只定义op/status/状态及结构，frame_owner拥有全部6/3表、latest/freeze/policy/序号和reply holding。业务控制器把真实capture/algorithm/display终态转换为命令；后续display_handoff负责VSYNC、snapshot hold、ACK和预取闭合，不把本core域测试当CDC验证。

```text
已闭合采集/算法/显示事件 → IF1 cmd941原子命令 → 唯一frame_owner
frame_owner → IF2 reply942（句柄/Origin/CJ/图/render/policy/槽）→ 业务控制器
frame_owner → IF3 账本状态/latest/freeze/policy/quarantine → 状态观察
源和结果byte地址 → 既有reader/writer/AXI bridge（后续真实整合）
```

单入口一次只接受一个命令，避免同时对引用覆盖式读改写；这不会暂停相机像素，捕获前须预授源/结果并经已测CDC缓冲，不依赖软件每像素发命令。单holding满只阻新控制事件，不占DDR总线。

## D. 精确接口与组合检查

IF1 cmd941从高到低：op4、flags8、source_handle64、result_handle64、Origin195、CJ142、body400、policy64。所有无用途字段忽略（不据此索引），flags未知/保留bit拒绝。IF2 reply942：op4/status4、source_handle64/result_handle64、Origin195、CJ142、body400、policy64、source_slot3/result_slot2；status0OK、1NO_SPACE、2NO_SOURCE、3STATE、4IDENTITY、5FIELD、6NOT_READY、7EXHAUSTED、8QUARANTINED、9ALREADY。

cmd_valid&&cmd_ready在core上升沿接受；reply_valid&&reply_ready交付。holding存在时cmd_ready=0，回复不被新事件/当前配置改变。safe_reset_n异步assert、两FF同步release，复位时命令/回复无效，DDR内容用资格隔离不清阵列。

op4：0ALLOC_SOURCE、1SOURCE_EOF、2SOURCE_END、3ALLOC_RESULT、4RESULT_END、5OFFER、6APPLY、7DROP_RESULT、8RETIRE、9FREEZE、10RESUME、11BARRIER；12..15FIELD。flags bit0GOOD、1IO_CLOSED、2PRODUCER_CLOSED、3CONSUMER_CLOSED、4LIVE。SOURCE_END/RESULT_END只许bits0..2；DROP_RESULT许1..3；RETIRE许1/3；ALLOC_RESULT只许LIVE；FREEZE只许GOOD作为HAS_ACTIVE；其他flags必须0。

SOURCE_EOF/END以source_handle和完整Origin匹配当前writer。ALLOC_SOURCE取输入Origin的frame/epoch为种子，其他Origin字段不作新句柄；ALLOCATION输出才是合法新Origin。ALLOC_RESULT显式source_handle非0时必须Origin匹配；零时选择freeze（frozen等待时无源），否则latest；LIVE只允许显式WRITING/DRAIN源，DDR帧级读者不可据LIVE读取未完成源。结果分配用输入CJ的config/参数但替换frame/epoch为所选Origin，W/H须等本组件固定几何、low≤high。RESULT_END/OFFER/APPLY/DROP/RETIRE匹配result_handle、source_handle、Origin和CJ完整快照；policy在OFFER时与所锁和当前policy均须相等。APPLY是已发生事实，不因旧policy晚通知删除真实租约；显示侧的屏障由后续模块独立证明。

固定生产布局候选，组件实际生成desc并检查范围：source槽s base=s×0x00800000；result槽r base=0x03000000+r×0x00800000。RGB L=3WH；EDGE L=ceil(WH/8)；ANN L=4224+ceil(WH/4)，ANN base=result_base+0x00100000。A=16byte上取整。body400从高到低SRCdesc96/EDGEdesc96/ANNdesc96/render112，每desc={base32,L32,A32}。SRC始终有合法desc；mode1/2不用EDGE、其desc0；仅mode5有ANN，否则0。不把allocation空隙当有效数据。该范围只占前72MiB，后续CLASS/QUEUE/GRAD/RC工作区统一设计，不声称本批完成全内存布局。

render112={mode3,split_y11,edgeRGB24,ANN01RGB24,ANN10RGB24,ANN11RGB24,show_edge1,show_ann1}，模式0比较/1RGB/2GRAY/3EDGE/4overlay/5识别；mode6/7非法，split_y=H/2。ALLOC_RESULT只接受body低112render，上288必须0；core补合法地址/长度。W1920/H1080默认，允许TB W偶数4..1920/H偶数2..1080，无缩小生产目标。

组合：SRC desc与已测RGB writer/reader的连续RGB888一致，EDGE1bit/pixel及ANN header128/list4096/map2bit沿既有图格式；当前父内存授权端口仍需实际适配，不把desc当full grant。reply有195/142完整实际字段，不截handle。每结果从WORKING至退休归还全程一个BIND；latest/freeze额外只读保留，6源容量安全不代表任意DDR停顿都能无丢帧。

## E. 局部中文操作草图与不变量

表state：源FREE0/WRITING1/DRAIN2/COMPLETE3/BAD4/Q5；结果FREE0/WORKING1/DONE2/OFFERED3/DISPLAY4/RETIRING5/Q6。源存handle/Origin；结果存handle/source_slot/source_handle/CJ/render/body/policy。序号分别source、result、policy64，默认1，最大值分配后置exhausted，不回绕。

每次命令沿：先把旧表复制为下一表，查完整句柄/Origin/快照，再按op计算一次变化，最后统一计算保留集合并提交。找空槽只看旧FREE，不做同沿回收再分配。reply按该命令的确定结果快照，holding后保持。

ALLOC_SOURCE：先查全局Q和source序号耗尽，再查frame/epoch撞名和最低FREE；建立WRITING与新Origin后回复。EOF只WRITING→DRAIN。END先核state与身份；closed缺任何位→source Q+全局Q；good只允许DRAIN→COMPLETE；bad closed→BAD；最新64seq更新latest，冻结等待第一成功时同沿加FREEZE。迟完成旧帧若无读者最后可FREE。

ALLOC_RESULT：先找最低旧FREE；按显式或freeze/latest选源并核可读/LIVE资格；检查CJ/render，建立WORKING/BIND并锁policy、生成三desc。RESULT_END未closed则Q；closed成功→DONE，closed失败→FREE并解除BIND。OFFER不改变body，检查源完整、policy、无现有OFFERED后→OFFERED。OFFER reply消费后控制器才交显示，结果在这整个期间持续占用。

APPLY：目标必须OFFERED；以前DISPLAY转RETIRING，目标转DISPLAY。DROP：WORKING必须真实IO及producer closed；DONE可用保存producer closed，但外部仍需IO closed；OFFERED additionally consumer closed；DISPLAY/RETIRING不能用DROP绕退役。RETIRE：只RETIRING、IO+consumer closed才FREE。缺闭合隔离并保留BIND。重复过期事件返回STATE/IDENTITY，不归还新代次。

FREEZE：已经frozen返回ALREADY；HAS_ACTIVE必须source COMPLETE、Origin匹配且相应result在OFFERED/DISPLAY/RETIRING，snapshot hold由同一BIND保护；先设置freeze再回复，回复真实消费才允许外部解除hold。NO_ACTIVE锁完整latest或等待第一成功源；RESUME解除freeze；成功控制改变policy，若policy耗尽则不改控制或引用。BARRIER只改变新OFFER资格。

统一回收：将latest、freeze和所有非FREE结果source绑定视为一个保留集合；WRITING/DRAIN/Q始终保留。只有COMPLETE/BAD且不属于集合才下一表FREE。避免先清旧latest就抢槽、同沿source complete+freeze产生悬空，以及旧结果释放影响新BIND。

不变量：FREE无writer/引用；非FREE结果恰好绑定一个未FREE源；最多一个DISPLAY、一个OFFERED，RETIRING可2；全closed未知不制造FREE；已经发布body/CJ不可热改；snapshot hold移交先建立核心freeze再解除；source/result handle不会复用。

## F. 语言与参考契约

SystemVerilog sv_09：always_comb阻塞形成next，always_ff非阻塞一次提交；枚举/packed定义在pkg；数组6/3，位宽显式。A：64位身份/32bit地址/11bitW/H/3和2bit槽，整数上取整先用32bit足够N2073600；B：core100MHz正沿，TB负沿驱动、正沿后观察状态，handshake看沿前；C/D：实际事件才改变表，气泡不当成功；E：holding全942位保持；F：一事件提交后下沿可交回复，回复消费后至少一沿再接新命令；G：共同safe冷复位、内容不清；H：ALLOC锁配置，policy后改不改旧body；I：FF表无图像RAM，有限槽拒绝；J：完整Origin/CJ/handle与desc绑定；K：本单元同域，外部原子CDC接口不以仿真代证明；L：Ti60F225/I3 MAP 100MHz，PNR/STA/bit留整体。

独立Python以存活writer/读者集合及真实cmd/reply日志重建对象关系，比较每命令的身份/快照/状态/保留集合，地址按数学公式独立计算；不复制RTL组合数组遍历或内部寄存器。C++N/A（本批无C++）。参考值与实际握手一一对应，丢掉/重复事件不能算正常。

## G. 实施与测试（初始未运行）

先包/RTL→Python租约参考→TB/script→当前源仿真→MAP→登记。TB唯一TEST_W/H和TEST_*序号，不使用全局-GWIDTH。

| 测试 | 目标与事件 | 期望 |
|---|---|---|
| OT1 | 正常6源3结果、直播/完整源、各种mode | 正确句柄/CJ/Origin/desc，整包源结果一致 |
| OT2 | latest晚完成、替换与旧freeze/BIND | 保留集合精确，旧帧不覆盖新latest |
| OT3 | D+R+R、OFFERED满、六槽全占 | 不提前回收，不隐增第4结果，明确容量失败 |
| OT4 | 真实视频B/core A snapshot B，FREEZE无active/无latest/恢复 | freeze先于hold ACK，首次成功源原子保留 |
| OT5 | 源/算法/显示缺IO/producer/consumer closed | Q占用保留，新分配禁止，冷安全reset才能清 |
| OT6 | wrong/repeat/stale handle/Origin/CJ、policy barrier、坏输入 | 不修改新代次；拒绝旧OFFER、保持旧body |
| OT7 | 回复长停顿、cmd气泡、随机事件、近64bitmax | 稳定、守恒、无回绕/无状态撕裂 |
| OT8 | 当前源Ti60F225/I3 MAP | 实际资源/无锁存/黑盒，记录警告，不称整机PNR |

## H. 双向追踪与门槛

FO01/02/07→源表/统一回收/seq→IF1/3→OT1/2/3/5/6/7；FO03→结果分配/end/offer/body→IF1/2→OT1/3/6；FO04→APPLY/RETIRE→OT3/5/6；FO05/06→FREEZE/RESUME/policy→OT2/4/6。pkg为这些位序和编码；model/TB/runner/工程承担独立证据/源绑定派生要求。实际代码与测试初始未生成。

门槛十项证据：B外部及例、C职责/已读相邻来源、D精确位序和接法、E状态/旧值/草图、F语言、D/E端到端和容量反例、G/H计划追踪、A明确隔离未来缺口、保存后实际读回/呈现、v1与冻结基线。按用户自主软件授权实施；不把旧v0.1无阻塞判断或“未逐版批准”冒充新用户批准。

## J/K/L. 修订、实录与阅读

代码前补充reply规范：失败字段全0，仅op/status/current policy及槽哨兵source7/result3；成功源操作返回其源身份、其他payload0，成功结果操作返回该结果的全快照及原result policy，FREEZE返回观察的源/结果快照但policy是新控制policy。控制RESUME/BARRIER只返回新policy。回复握手是事件收据，读写资格仍由op和对应租约决定，不可把DROP成功回复当新读授权。near-max测试用INIT_SOURCE_HANDLE/INIT_RESULT_HANDLE/INIT_POLICY参数，生产默认1、非0；发出max后exhausted，不回绕。SOURCE_END先检查closure，closure全有时才检查good与DRAIN相容。

J1（首轮测试前收据语义修正）：closure缺失时确实接受隔离事件，但reply必须返回QUARANTINED8和失败规范字段，不能用OK让调用者误当完整源/结果。Q状态及BIND占用仍提交，其他字段/身份错误不修改新对象。相应SOURCE_END/RESULT_END/DROP/RETIRE分支先修设计再改代码；T5及参考核对reply与实际Q状态两层。

J2（首轮852命令已通过后的组合回查）：冻结期间显式其他source允许后台持有/计算，但新OFFER还必须绑定freeze_handle；仅policy相等不够。FO03/OFFER与FO05新增该条件，冻结等待无source时也无OFFER。APPLY仍记录屏障之前已经真实发生的事实，不倒改历史。T4增加其他源同policy结果不能发布；T3增加一个OFFERED占满但另一个DONE保持；T5增加LIVE坏源/失败结果以及WORKING正常drop；先读回此卡再变更RTL/参考/TB，旧001保留，最终当前源重跑。六角色反例另由保留集合与逐命令状态核对，不把六WRITING压力测试说成全角色组合已实跑。

J3（真实资源优化）：当前HD873/小几何873/near-max17命令均通过，owner_map_001真实16773LUT/5061FF/0RAM/DSP，过重。接口941/942、外部身份/地址/生命周期和提交时间不变；内部source只存state3/handle64/frame_epoch64，Origin用{handle,frame_epoch,handle,slot}重建；result只存state3/handle64/source_slot3/config78/render112/policy64，完整CJ从锁定config与源frame_epoch重建，body三个desc由静态几何和源/结果slot推导。非FREE结果的slot借用阻止源槽重用，所以不另复制source_handle；命令比较仍核完整64bit key/195Origin/142CJ，绝不对外截短。统一GC由结果slot集合保留source，等价于原唯一key绑定。源/结果成功回复从旧不可变对象或ALLOC的显式新对象构造，不再动态读取已修改的全next表造成大旁路。E/F的“存全Origin/CJ/body”视为逻辑信息，以上为实际压缩表示；pkg私有source_t/result_t随之修订，公开command/reply不变。增加TB OWNER_POST_MAP实例分支与runner -PostMap/-MapRun，在默认生产几何用原生EFX_FF/LUT4模型验证真实网表；模型依赖冻结单列，文件自写仍8份。近max及小几何只作RTL。旧图/源/日志保持，优化后重跑全部当前源与MAP及映射后协议。

## K. 当前实现与验证实录

8份业务/验证源已生成；输入修订FRAME-OWNER-BL-20261009-v1.2有9份冻结输入（J3实施前设计、6份原上下文、2个官方EFX模型）。J1/J2/J3均在受影响代码前保存并读回，用户自主授权沿用。

当前RTL owner_hd_004默认1920×1080几何873命令/14次safe冷复位/5129停顿周期，owner_small_002为4×2同873命令，owner_max_002为64bit source/result/policy近最大值17命令；编译/展开/仿真/独立租约审计均0errors/0warnings，fatal探针正确非零退出。该core不传像素，HD名称表示描述符几何，不能称本批又跑了1080p像素链。

owner_map_002 Ti60F225/I3 MAP exit0，真实9624 LUT4/2623 FF，RAM/ADD/SRL/DSP0；相对owner_map_001（16773 LUT/5061 FF）分别减少42.62%/48.17%。两份警告按实际保留，移除冗余next信号不是省略日志；无latch/undriven/blackbox/error警告。此组件内部宽控制口不作板级IO、PNR/STA/bit证明。

owner_postmap_002使用优化后的真实map.v和官方EFX_FF/LUT4，默认生产几何同873命令/14次安全冷复位，全部reply941/942对应、Origin/CJ/body、状态、保留集合及holding逐一独立审计通过，0errors/0warnings。没有替换逻辑或把原RTL作为DUT。当前三RTL加一真实映射仿真共2636条命令；旧001/002/003和旧映射/旧postmap保留，不混作当前源码证据。

场景覆盖D+R+R、满结果池和单OFFERED拥塞、六WRITING占满、乱序/迟到归还、LIVE坏源、缺IO/producer/consumer闭合隔离、late source完成不能倒退latest、冻结等待第一成功/NO_ACTIVE、快照B但核心影子A的合同驱动事件、冻结不同source同policy拒绝、新body快照不热改、六mode及非法字段、近max不回绕。快照事件由TB按显示合同提供，没有实际视频域/VSYNC/CDC/预取器参与；六不同角色同时满池未在此TB重建，集合安全规则逐命令核对。NO_SOURCE和ALREADY收据分支本批未单独触发，不宣称全部分支穷举。

按最终代码核对压缩source/result表示、source_origin/result_body函数、lookup完整身份、各op分支、统一GC、942位回复holding与独立事件映射。实际摄像头/DDR/算法/显示fence、业务控制器、跨域消息/实际VSYNC、冻结恢复整合、显示预取/TMDS、复杂识别、总资源及单一top/PNR/STA/bit均仍需继续；正式DB/H0/state不改、无硬件操作。理解验收待用户实际作答。

## L. 阅读与继续入口

若发现契约不足，先追加短卡读回再改实现，仍按自主授权；历史失败保留。阅读顺序本稿B整体→C/D交接→E操作→J3实际压缩表示→pkg位序→frame_owner相应分支→独立集合参考→TB/run/MAP/登记。下一步实际显示原子跨域路由/VSYNC/snapshot hold/旧读退役与本核心联接，不把当前core模拟快照当真实显示闭合。
