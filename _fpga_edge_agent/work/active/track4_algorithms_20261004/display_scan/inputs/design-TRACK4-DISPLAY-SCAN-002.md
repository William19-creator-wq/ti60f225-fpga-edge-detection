# 完整三银行显示扫描、真实切帧及引用关闭设计 v1

- Goal：保持五基础、六高阶、Ti60F225/I3、SC431HAI、1080p与板上DDR的原整体目标，本增量补上实际显示scan调度及owner/handoff联合。
- Current state：行取数/core/native三银行、行消费、renderer、owner及handoff已经分包动态/MAP；上一批六mode同bundle完整HD帧通过，但其父仍是固定fixture。
- Target state：真实handoff只接受实际首行prepared；三银行同时用于正常行、候选首行、旧图repeat首行，实际VS改变后旧scope真正排空并经core证明才通知RETIRE。
- Gap：原SCAN-001 v0.1未确定的银行分配、VS错过、回执/发布先后、trueReturn与闭合，本v1给出全部当前边界。
- Assumptions：生产输入时隙标准连续不可回压；core lookup提供实际保留的不可变942 bundle和授权。联合TB用真实owner命令/回复建立这些保留，但生产业务控制器、DDR PHY/QoS、CSI晚错及识别产物另继续，不能把TB parent当整包完成。
- Open questions：当前软件模块无待决行为；实际DDR动态模型/整包带宽是后续整机缺口，不阻塞独立标准AXI服务的软件验证。
- Dependencies：下面逐SHA源码22份；既有工具Questa2024.1、Efinity2026.1、Ti60F225/I3和Python标准库；不安装、不联网。
- Milestones：整体/接口/逐沿中文草图→READY保存读回呈现→自主独立源码→必要联合仿真及独立参考→MAP→冻结登记；不自动进入硬件。
- Detailed steps：模块边界固定，先scope_fence/scan_video，再scan_component及真实owner TB、独立模型和工具入口。
- State transitions：READY_FOR_REVIEW v1；用户“当你统計完后自行进行, 无需我的批准”持续授权覆盖本软件实现，不等待逐版批准。未伪造用户对指定版本再次答复、正式Manifest或DB状态。
- Artifacts and hashes：新work/display_scan，拟9份自写：3 RTL、1 TB、1 Python参考、2运行脚本、XML/SDC各1；22份原样依赖（21RTL/仿真文件+独立owner参考）。输入/README/结果/日志另计。
- Validation：真实owner/OFFER/APPLY/RETIRE、actual准备/return/closed、标准AXI至六mode连续帧、错过VS/取消/repeat/冻结/保持与延迟、独立逐字段/像素比较，真实MAP；PNR/STA/bit尚不在组件输出中。
- Failure handling：DE不暂停，缺行黑整行，中途错保前缀并黑余行；已承诺请求不可撤，未知IO/身份永久Q，不伪造closed/return。时钟停止只保持，不用时间制造释放。
- Human approval gates：持续软件授权、本地审计例外；正式PG/H0状态保持。最终生产bit之后停止硬件动作。
- Rollback：新独立work包；旧work输入、原HDK和staging不改。
- Completion criteria：当前完整scan控制和联合证据；完整原项目继续，非DDR、识别、总资源、PNR/STA已经完成。

## A 阅读、来源及基线

依次读B外部行为→C模块→D接口/组合→E中文内部草图→F语法/时间→G验证/H追踪→实际RTL。唯一规范v0.2 SHA 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；模板沿用PLAN_TEMPLATE。以下是真实源码输入，不含已登记netlist或编译库：

- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\atomic_mailbox.sv`：`F9C6530E4313236DDDF23BEC7044FA02AC4B4A01816C9A9A30A938333298ACA5`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\axi_read_byte_slave.sv`：`71960276C1C04F1A72981FB5EEF009ADEF209664ACAF505F0C7550A608066CC0`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_fetch_link.sv`：`B20CBE815C4DB342D143B4AEF1AD3ED2FCD36E38D672554539181EBA26E2EE04`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_fetch_pkg.sv`：`ECD0EDB3DF0B7376E8C7099E748D27C1D7809BAD33F9D3FA199125BC1CB6222C`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_meta_ram.sv`：`372131E5C179575AA13D6907962CD32AF03A99DDBAE7417CC3EB2A78996303DA`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_renderer.sv`：`6DF94BC88964CE7D8C0C3948AC15D019FD5473AB893DFBDDCC4AEEF3B85441C7`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_row_bank.sv`：`6B5B40592A4A8ED0A12627D8CAF117A2E28ECE585F09E5C192429492FC7BEE6D`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_row_pkg.sv`：`AF23F6F1733B9B5C41DBE30508AB03C64952A6362CAB63398CB4BBFB761AA61A`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_row_reader.sv`：`F5D963C52119473175311FBF131A5F4BE5358FF30ED6537194DED97FECE3BCFA`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_rows3.sv`：`3BB560AC1989455CFA250B2B8A5A5DDE1BA3975728BB3E8479848B4D2DC722C4`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_scan_prefetch_core.sv`：`F74E1ECAE604BD0DE3F5E357F3DE74155418798800715618A92FB0FABCFF3908`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\display_span_axi.sv`：`7B69679E32AD77650FB80234E7304A235E1F7FCCD9795BD7CD920B302AD00BAC`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\efx_ram10.v`：`DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\frame_owner_pkg.sv`：`C035DA64312F9DB9557E688E6968A984A4B6589FB678B5A51A43DD767C77E7FB`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\row_ram54.sv`：`57808C0C438FD26182ED75AEA57E88F1317FDE1EFC76E9665111F2416E9932CD`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\deps\video_timing_1080p_pair.sv`：`4F90437661D181C827ED22A0A93F6634B599E6A5E6A349DC8CF02250BE10F533`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_row_stream\rtl\display_row_streamer.sv`：`605ADCCE2416971F3796FCABC92A108ECF1C660A435DF64CFAC812FAC638CBEE`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_handoff\rtl\display_handoff_pkg.sv`：`3B55702BC1711412179EAC1802C963F406F0229B2B30009BB7019EAC81E5D983`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_handoff\rtl\display_route.sv`：`DC88C87BDE491F9FAD5272909140A7CF55EBD6BEC103C52ADCD0E3A22FF02A63`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_handoff\rtl\display_handoff.sv`：`0BDBA8985E4F12B1047D9C2F8D726AB350BF6267D12ED4AD72639B835E9E13DA`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\frame_owner\rtl\frame_owner.sv`：`08EDC64D60DB28F99CAB6C9BF0069ABBF24E346EE8136A8DA949D9FD14D74E2D`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\frame_owner\model\frame_owner_reference.py`：`1252644F2B55BBDFA2C9F2789886021894017427CD8E60F820A61F23E1CB7045`

原SCAN-001 v0.1及本v1和规范将复制冻结，实际baseline含25项输入（22依赖+3文档），不把复制依赖多计自写。原rowstream J1–J4最终SHA作为本次真实依赖，不修改已通过组件。

## B 整体外部行为与样例

SC21：每个视频时隙按DE/HS/VS/start/x/y走原renderer，不可回压。参数偶数W4..1920/H2..1080，HD使用既有1100×1125双像素时序，约74.25MHz/60Hz显示。处理FPS不冒充60。无active时合法mode1配置输出黑和missing1，blank error0。

SC22：唯一当前fetch事务以寄存器保存481请求，从提出至真实receipt消费完整保持；选中FREE银行时即建立义务。receipt成功与同ticket native publication同时reserve，任一先到都等另一方，不合成prepared。消费者实际两credit首响应构成候选资格；只有真实handoff VS切换。

SC23：正常行以cursor递增申请一次，以完整demand479检索三个银行，首DE锁物理bank或无银行3，逐对真实pop送renderer。late首行不得移到另一坐标；floor在首DE提升至y+1，过期非正在显示的行discard。尾部已有消费者两沿保护。同银行新需求只在真实core return经545原子通知到video消费之后申请。

SC24：每VS的当前scan取真实handoff.scan_token；当前active.sequence保原OFFER sequence，重复扫描不变result/policy/Origin。每个scan正常row1..H-1，在上一扫描结尾另准备下次scan row0。正常cursor到H才允许尾部首行：先旧active repeat0，再候选0；无active时直接候选0。任何FREE银行均可分配，最多三个，无第四行/帧缓存。

SC25：候选tuple每个sequence/target_scan最多申请一次；错过VS后原ticket不改，未接受481承诺照样交付并cancel，发布/读响应排空并真归还，下一target_scan重新申请。候选选中时actual active_changed脉冲使用仍稳定的candidate_sequence锁active.sequence，新active row0保留，旧repeat/旧scope行discard。候选取消停止该ref所有未来申请。

SC26：切换时最多两条旧scope关闭槽保存全387 FrameRef并加两视频沿guard；与candidate cancel关闭共享一个fence事务。仅本scope没有request/银行/读信用/尾部/未来任务，才能提交388={old1,ref387}。core查询真实prefetch.local_scope_live、同scope fetch transport，以及同scope trueReturn ACK运输；三者全0才形成闭合。old通知到core父valid/ready真接受后再回video；candidate直接回video真实闭合到handoff。不是猜延迟、不是owned0、不是video_release提出。

SC27：root可用core old_closed.ref通知推进真正owner RETIRE；candidate closed只有完整sequence/result/policy/Origin吻合才handoff取消回复closed1。backend未闭合/parent背压/停止video时钟都保所有holding。未知AXI/错误545/388回执/消费者Q使调度永久Q、闭合保持0；不撤已valid请求，可兑现原promise，合格共同冷复位才作废。

普通走查：owner真实SOURCE_END/DONE/OFFER授权→handoff candidate→scan申请row0→AXI/WR/publication与receipt→消费者真实RE0/1首头→prepared→真实VS selected→active.seq锁定→row1/2预取→连续DE六mode渲染→最后pair/两沿tail→release→实际coreReturn→545通知→银行FREE。旧active在切换后停止申请并drain，fence真实core查询0及parent接受通知才允许RETIRE。

边界：B row0未到首次VS，handoff保A；A下次row0同独立ticket继续显示。B旧target_scan的请求/银行以旧身份排空，重新申请B新scan。取消发生在request_ready0时valid和481保持，video_cancel持续该包；若已发布则reserve_discard，已承诺RE继续读并drain，trueReturn与运输ACK真正结束后candidate closed。不是把B frame_ref改成A。

## C 模块与整体连接

M1 display_scan_video：video域三银行职责和扫描cursor，真实资格/旧scope/no-future/首DE选择；不维护core GEN、不创造源授权、不做数学像素。
M2 display_scope_fence：video388请求→原子邮箱→core查询并等待真实债0→old通知父387握手→388回执原子邮箱→video；不自行清core债、不给无no-future对象查询许可。
M3 display_scan_component：实例已冻结handoff/link/prefetch/三consumer/renderer，3条545trueReturn邮箱，实际RO lookup/AXI/关闭通知和root控制端口。连接适配、不复制像素。
M4父业务控制器（联合TB真实owner刺激，生产另接）：六源三结果实际pin与RO lookup、retire_capacity、OFFER/APPLY/FREEZE/RETIRE；不得因字段相等给已经free的对象读权。

数据：root942 lookup→prefetch.reader→AXI→native3×54→streamer3→scan选择→renderer48。
控制：root1137→handoff→candidate/active；scan481→fetch_link→core；615→scan reserve；core实际545Return→三mailbox→scan FREE；scan388→fence(core live查询+真实parent oldClosed)→388→scan/handoff。
无死锁：真实成功615和publication同时reserve，consumer能自发RE0/1；失败615可独立消费，无不存在的publication等待。return通知独立于fetch481和fence388通道，oldfence仅quiet后发，不与自己等待的return相互依赖；父oldClosed背压会占close槽并压retire_capacity，但不压正常DE。

## D 精确接口及组合检查

IF21 scan_video↔handoff（video上升沿）：candidate_valid/bundle942/sequence64/target_scan64/cancel，active_valid/bundle942/active_changed/prepare_selected/scan_token64；scan输出prepared_valid+sequence/scan/result/policy各64及Origin195，closed_valid+seq/result/policy/Origin。active_changed在真实VS提交后下一沿可观察，此时candidate字段仍由SEND/WAITACK保持；effective_active_sequence=active_changed时candidate_sequence，否则保存active_sequence，防止提交后的第一沿错误discard新row0。

IF22 scan↔fetch_link：request valid/ready/481，cancel保持level，receipt valid/ready/615；均video域，原FC字典全位序不变。request_register保持、request_live从创建到receipt实际消费。成功receipt条件status0/outcome0/granted1/drained1/returned0/prepared=delivered=P；必须native row543等于receipt.ticket、reserve_ready1才receipt_ready1，reservation与receipt同沿。安全拒绝无publication且无unknown时可消费并FREE，正常cursor不倒退，该deadline缺行；未知留Q。

IF23 scan↔三consumer/native：reserve_valid/ready/ticket543/discard；prepared/local_live/ref387/Q及pixel54/valid/identity；consumer display_start/de/x11/demand479/discard；已有真实native RE10/GEN64/响应/error/release同绑定。scan只复制当前481请求、active.sequence64和2条oldRef387，不复制三个native543或pixel RAM；BORROWED银行借native稳定票据直到545通知消费，native publication holding在再申请前保持。

IF24 trueReturn core→video：每银行独立atomic_mailbox宽545，源data={ticket543,kind2}，源valid/ready就是实际prefetch public return消费，GEN在这个core沿真正推进。video dst消费条件银行BORROWED、consumer local_live0/owned0，全文545 ticket须等于原row_ticket且kind0/1；错包Q且不consume。不存在publicreturn的internal abort，只由真实615 returned1关闭请求。core查询把未ACK同scope return源运输计为live。

IF25 video388 fence valid/ready、done valid/ready388；388高位old标识，低387完整FrameRef。video_ready仅此前fence无在途且request mailbox source ready。video父请求接受前无future、局部义务全0，接受后维持no-future；DONE必须全388等于inflight。core scope_query_valid/ref387→实际live；core old_closed_valid/ref387→父ready；root接受旧通知后fence回执，候选无root旧通知。unknown core输入阻止closed。无纯宽CDC直连。

IF26时隙：component输入raw_de/hs/vs/frame_start/x_even/y，raw_vs上升译码为vsync_tick；全video域，DE首时隙x0。oldClosed/core请求/lookup/AXI均core域。root_retire_capacity在core，经两FF至video，再与两个old-close槽至少一空相与；它是容量许可level，不用pulse跨域。renderer原S0/S1同步与像素保持相同两沿语义。

逐连接核查：需求479的seq/scan/result/policy/Origin/target_y/source_y/mode/mask同既有ticket低479；fullRef抽字段，非连续cast。mode0 sy=2*(y%(H/2)), mask上RGB下EDGE；mode1/2 RGB，3EDGE，4RGB|EDGE，5RGB|EDGE|ANN。frame_ref用于整帧关闭不含scan，一候选错过VS只是丢旧行并可创建新scan，并不关闭整个FrameRef。两个old关闭槽只在active真正改变时占用，root容量及槽容量同时允许切换。

## E 中文内部操作草图

### E1 scan_video 状态/表示

video_reset两FF，running后才接受。bank_state[3]为FREE/REQUESTED/BORROWED/Q；FREE只由冷复位、确认无grant/已内部真returned的615、匹配545真正通知消费建立。pending银行与request_register.bank绑定；BORROWED借native.row_ticket。当前request481寄存器、request_live、request_pending（提出未接受）、request_accepted；成功/终态615才清live。不能在valid停顿时改payload。

active_sequence64在active_changed锁candidate_sequence；normal_cursor11为1..H，VS上升重置1；floor11为0..H，VS清0，首DE更新y+1；repeat_sent bool随VS/active_changed清0；candidate_last_seq/scan各64保存已创建候选请求。当前显示选择bank2和valid在首DE保存，首DE组合选全文wanted，随后用保存选择，不在中途换行；raw_de0时不给像素。old_close[2]={valid,ref387,guard2}；fence_inflight388单holding；cancel_closed_ref/valid保存实际DONE直至candidate退出或变sequence。

E1.1 同沿优先级：reset→永久Q记录（不清义务）→实际active_changed捕旧ref/锁新seq→VS重置cursor/floor/repeat→真正545/receipt/请求接受→已有fence DONE→调度创建新的481。创建禁止active_changed或VS该沿，以用更新后的真实scan/seq。各计数只一个真实事件写；银行同沿不会同时完成return并新建，下一沿再用FREE。

E1.2 逐银行分类：REQUESTED用唯一request_register.demand；BORROWED用原native ticket。合法在途目标为当前active当前scan尚未过floor的行、当前真正选中DE行、active下一scan row0、或未cancel candidate的target_scan row0；其余为stale。当前selected正常行即使floor已y+1也保留直至DE完；若中途protocol错误则消费者自行DRAIN。stale pending让cancel保持到该receipt，stale borrowed给discard。成功receipt若已经stale仍同沿reserve但reserve_discard1，不等待不存在的后续显示。

E1.3 完成615：全文bank/demand须匹配current；成功核全部正常count/关闭位后，与nativepublication/ticket共握手，银行转BORROWED。拒绝须drained1、outcome!=3，若grant1则returned1，不借未归还银行；清request_live且可释放PENDING槽。不可从status BUSY猜旧银行归还；若FREE来源与BUSY冲突，记录Q。未知收到就Q。

E1.4 正常排程：若无当前request/fence限制且存在FREE，active有效且normal_cursor<H时创建该active/currentscan/y=cursor的481，cursor+1。不等待DE产生新数据；正常三银行lookahead。cursor=H才排下次scan row0，先repeat（置repeat_sent），再本candidate尚未在seq/target_scan创建过的row0（记录两个64）。无active可直接候选0。scope正在closing/cancel时不创建其future。scan最大时不加1；handoff也永久Q，绝不回绕。

E1.5 首DE搜索三个BORROWED全文demand479等于wanted的银行；取一个，若两个匹配则Q（重复identity非法）。prepared决定consumer首DE是否正常；行迟到不ready时只黑。renderer render来自当前不可变active.body112，无active用合法mode1/H/2；selected不存在时pixels_valid0/identity_good1得到missing1。currentbank identity坏由原consumer得到3，保此前正确前缀。首DE后choice保持，不能用未来行顶替。

E1.6 candidate prepared仅真consumer prepared、BORROWED/fulltuple/mode/mask/row0/target_scan匹配；没有直接生成RE资格。cancel candidate闭合槽只在真实fence DONE设置，match ref后给handoffclosed。两old槽输入来自旧active真实ref，guard两位11逐沿右移0；从未由rootcore影子推断video active。

E1.7 closure仲裁：candidatecancel且未closed优先，随后old_close低编号。当前ref不得仍active/candidate可继续future（cancel候选允许）；无request_live同ref、所有银行对应ref为空、所有consumer local_live/ref不匹配、oldguard0，才388发出。accepted后锁inflight，保持旧槽/候选cancel条件不重新申请。done全包吻合才清old槽或设置candidate_closed；错done永久Q。

### E2 scope_fence 双域

两个388原子mailbox。video保存busy、inflight388；request在video真正接受后busy1，done回执消费才busy0，并核全文。request source holding在core处理全程保持；core query由request目的holding低387连续驱动，无复制/窄化。

core IDLE目的valid→PROVE。PROVE只有scope_live0且fault0；old=1同时输出old_closed_valid/ref给父，在父ready真正沿才SEND；old=0直接SEND。SEND把原388送回应mailbox，仅真实src_fire时request.dst_ready1并进WAIT_ACK；WAIT_ACK等响应mailbox src_ready再IDLE。因此请求ACK/返回ACK各真正结束，不把一个接纳沿当全部排空。fault置Q保388和闭合valid0。video停止时core回应holding保持，下一查询不得覆盖。

### E3 component/return通知

按全端口命名连接原模块。三个Return邮箱的src_valid是实际publicReturn；prefetch return_ready为邮箱src_ready（允许coldreset资格），truefire时同数据被邮箱保存，native/core GEN同步真实推进。src_ready0而holding.ticket.ref等于fence查询时额外计scope_live，不以nativebusy0代替运输ACK。video src全包错/非法bankphase永久Q，dst_ready0。

fence core_scope_live=实际prefetch query-live OR (fetch transport_live AND ref同) OR 任一未ACK trueReturn同ref；unknown engine/link Q→fence fault。root oldClosed是握手，root能晚消费、不会丢pulse。renderer只由真实consumer54/pixelvalid输入；scope guard/return保证末像素之后，生产no-future义务由scan当前活动和旧队列确保。不得把fence视为source生产者或算法writer的整体闭合。

## F 语言与对应契约

RTL SystemVerilog，packed定义全位宽无signed混用。3银行索引先<3；seq/scan/policy/result/GEN64均不回绕；y11、x11、地址10，P≤960；+1显式64或11，loop固定3/2可综合，comb先全默认，FF非阻塞。既有不变数学颜色由renderer/byte-slave证明；新Python为事件/身份/像素独立参考，不是生产C++，C++所有权N/A。

A数值上述；B video/core上升沿，TB negedge刺激/posedge真握手及NBA后单独观测；C valid&&ready真fire，无DEready；D气泡推进renderer同步，不推进请求cursor或返回代次；E481/388/545在停顿保持，取消不撤valid；F预读两accepted加第三promise，连续双像素/clk，core服务延迟可变，line约14.8148us仅ideal预算非实际DDR保证；G共safe_reset_n异步拉低、各域两FF释放，旧访问平台已关闭才允许冷复位，RAM只有效性隔离；H bundle112/942 immutable，active只真实VS，freeze新globalpolicy不改active.policy；I仅既有19RAM（18行+1meta）无新增像素RAM，所有通知holding固定小表，最终MAP待测；J完整387/479/543/615/942，不裁身份；K控制两FF，宽数据全部atomic，rootcapacitylevel两FF；L Ti60F225/I3组件100MHz/74.25MHz，MAP是资源证据，不是板pin/PNR/STA或最终bit。

对应：独立model从owner实际command/reply重建租约，handoff命令/真实VS/prepared/closed重建active与scan，依输入source slot与数学图计算54和RGB48；以真实DE/x/y/active full bundle/scan匹配每输出时隙，二沿后观察，逐位无容差。原owner独立参考原样输入不能替代新scan调度/关闭比较。qualified reset明确作废，不把作废算归还。

## G 实施与验证计划（尚未运行）

9自写计划文件rtl/display_scan_video.sv、rtl/display_scope_fence.sv、rtl/display_scan_component.sv；tb/tb_display_scan.sv；model/scan_reference.py；scripts/run_scan_sim.ps1、run_scan_map.ps1；project/display_scan_component.xml/.sdc。依赖副本仅原样复制。读回呈现后按持续软件授权生成；错误重要边界先短变更卡，保持旧attempt。

ST21 六mode各真实owner结果/OFFER→首行prepared→VS切换→至少一完整active帧，small/min/W6/W10与HD（不以小尺寸替代HD）；所有RGB/DE/HS/VS/start/x/y/error、native54/GEN、615/545/388及owner942全部独立比较。
ST22 candidate AR/R延迟到错过VS，完整repeat A；旧scan票据真discard/return后新scan B才切，不改旧ticket。cancel分别请求未接受/AR held/行已prepared，并验证实际old/candidatefence不能早closed。
ST23 正常A→B在owner尚OFFERED的视频真实切换，root延迟APPLY，freeze snapshot必须实际B，COMMIT建立真实source保留；旧policy的B repeat保持。closed parent背压、oldRetire capacity满不得再切，正常DE继续。
ST24 return通知/receipt/关闭ACK停顿、core/video停钟，持包并恢复；wrongID/未知IO不闭合与Q；coldreset资格另列。NearMax不回绕用现成handoff/rows单元与本组件传播，原叶有限覆盖不冒称整包全参数都动态测试。
ST25 当前SHA冻结→actualQuesta fatal非零→实仿真finished/独立model→Ti60F225/I3 MAP→最终文档与源码核对；记录未跑项，不自动打绿。

## H 双向追踪

SC21/23→M1+renderer IF23/26→E1.2/5→display_scan_video行选择→ST21/22；SC22→M1 IF22/23→E1.1/3→request/receipt/reserve→ST21/24；SC24/25→M1+handoff IF21→E1.4/6→cursor/repeat/candidate stamp→ST21/22/23；SC26/27→M1/M2/M3 IF24/25→E1.7/E2/E3→closure queues/atomic/query/oldClosed→ST22/23/24。TB/runner/reference只支撑这些真实要求的可追溯验证；工程约束是组件MAP范围。实际源码和结果待生成后填写。

## I 十项门槛与授权

①B行为/样例明确；②C职责及22真实依赖已核；③D全位序、事件及组合；④E中文逐沿/状态/保持/Q/释放；⑤F RTL A–L及Python对应；⑥B/D正常与错过VS/取消反例；⑦G/H实施/验证/双向；⑧当前标准AXI软件无关键待决，生产DDR及root未来范围明示；⑨本文件将实际读回并呈现入口再生成；⑩v1/9份范围/22SHA清楚。READY_FOR_REVIEW是设计自检，不是测试通过。持续用户自主软件授权直接覆盖本增量和必要修订，本地审计例外继续，正式制度状态不伪改。

## J/K/L 恢复、实际记录与交付

原SCAN-001仅DRAFT，M1 fetch/pkg/core及行stream已实际交付，故本v1复用冻结模块而只补scan/fence/组合。实际仿真/MAP/交付待执行填写README/最终登记及checkpoint；错误先设计卡，再修复，不放宽独立期望。用户理解验收待实际作答，不阻塞软件。完整识别、生产DDR/CSI/root与总top/pins/PNR/STA/bit继续原目标。
