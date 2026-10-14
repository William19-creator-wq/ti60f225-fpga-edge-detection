# 显示span与算法line实际共享读服务 v1

- Goal：把已通过的实际display_span_axi、axi_line_bridge与新读仲裁连接起来，补生产DDR读链路，不把mock客户端测试冒充真实叶整合。
- Current state：arbiter实测199 LUT/72 FF/51 ADD、26场景独立账通过；两叶各自已测。当前生产根尚未共享一个实际读口。
- Target state：actual三模块组合RTL、独立应用/总线参考、完整请求/返回/关闭及背压故障测试、Ti60F225/I3 MAP。
- Gap：本批是实际读服务组合，不含camera/algorithm写仲裁、DDR PHY或显示deadline证明。
- Assumptions：同core100MHz域、共同安全冷rst；算法读64B对齐/4×128，显示span16B对齐16..8192B；父已授权地址和完整FrameRef，物理ID不是FrameRef权限。
- Open questions：接口/时间已读审明确；真实DDR最坏服务/写竞争/总资源与根引用后续闭合。
- Dependencies：三当前源与它们登记manifest、v0.2、本设计；仅复制独立work，不改已登记或运行源。
- Milestones：保存读回呈现→冻结8输入→七文件→真实leaf/仲裁/协议slave/独立参考→实际MAP→登记→父生产读写/lookup组合。
- Detailed steps：B整体→C/D各连接→E中文语句→F语言→G/H测试和追踪。
- State transitions：READY_FOR_REVIEW v1；沿用持续自主软件/local audit授权，无新逐版批准。
- Artifacts and hashes：七自写（RTL、TB、reference、sim/map两脚本、XML/SDC）+三原样RTL依赖=10源/工程；8输入冻结。
- Validation：应用64B及16..8192B全值、同时连续请求、跨4KiB/末容量、数据/终态停顿、取消/enable/错误RESP和wrongRID/早晚LAST/Q，新请求禁止与旧尾继续、共同reset。
- Failure handling：失去归属Q保留，不将physical_idle当应用closed；原失败和输入保留，语义变更先短卡。
- Human approval gates：仅自主软件/本地审计，无数据库/H0/硬件动作。
- Rollback：新work/axi_read_pair_service，三叶和旧产物只读。
- Completion criteria：真实三模块当前源联合证据；完整十一项/DDR/CSI/识别/PNR/STA/最终bit仍ACTIVE。

## A 输入、版本与阅读

2026-10-10 v1，A3/A4/A6/R0。冻结8：本设计、v0.2、当前axi_read_arbiter2.sv/display_span_axi.sv/axi_line_bridge.sv，以及它们三个已登记artifact-manifest。arbiter源须等其v1.2登记当前，display取DISPLAY-PREFETCH-COMPONENT-20261009-v1.3中的原span，line取AXI-LINE-BRIDGE-COMPONENT-20261009-v1，核字节一致后复制。

阅读整体→D端口→E逐连接语句→测试，后代码。现在只有三叶的独立证据，不能据此报告本组合已测。

## B 整体行为与样例

RP01 一核心时钟的实际公共服务：算法一次64B line，显示一次16..8192B span。算法reply512/error/drained、显示逐128data和done outcome/reason/drained均由原叶真实形成，不另伪造终态或全局closed。

RP02 两叶的实际AR/R接arbiter端1(ID0)与端0(ID2)，只一个物理128bit DDR读口；3:1机会和49位AR保持原样。显示原span自行按64拍与4KiB分burst，算法固定4拍。只有实际leaf端握手才应用接受/交付。

RP03 aggregateQ为三个真实Q的或：禁止新的应用请求和新的仲裁选择，已接受请求、已经公开AR/旧R、已held数据/终态继续原路径，不屏蔽错误通知。误以为“所有模块reset或enable0”代表排空是不允许的。

RP04 physical_idle/occupied仅仲裁读口物理阶段，不涵盖叶的应用请求、data holding/terminal holding或其Q。父须结合原叶终态及完整scope fence才能关闭引用。不会给一个便捷allClosed字段绕过它。

正常：两个应用都fire，显示完整span分burst与算法line公平推进；应用data_ready0使显示holding和物理R背压但不改正文，另一请求待真实机会。取消：显示已公开AR时cancel仍兑现该burst再停止后续，done CANCEL及drained由原叶给出。错误：wrongRID时目标叶与arbiterQ，禁止新申请，旧尾可按原ready流动，unknown occupancy不释放。

## C/D 模块、端口与逐连接检查

MOD1新axi_read_pair_service只接线和资格门；MOD2 actual line bridge固定line_write0，写接口不用（AWREADY/WREADY/BVALID0，WDATA5120/BID0/BRESP0，写输出未连接）；MOD3 actual span，READ_ID2；MOD4 actual arbiter，端0span端1line。

外部clk/rst、arbiter_enable、algorithm_enable、display_enable、display_cancel；算法line_req_valid/ready/address32，line_rsp_valid/ready/data512/error/drained；显示span_req_valid/ready/address32/bytes14，display_data_valid/ready/data128，display_done_valid/ready/outcome2/reason8/drained；一个m_axi_AR/R32/4/8/3/2、128/4/2/1；三个leaf/busQ、globalQ、arbiter fault_reason3、physical_idle/occupied。ADDRESS_BYTES33默认256MiB。

算法/显示应用new valid各与!globalQ相与，对外ready各与同!globalQ相与，避免假fire；不用globalQ屏蔽既有reply/data/done/ready。两叶enable仍独立由父给，unknown停用语义不能被wrapper改为普通取消。arbiter.enable=arbiter_enable&&!globalQ，只影响新选择，已pending不撤。

两个完整packed AR/R arrays：[1:0]valid/ready，addr32/id4/len8/size3/burst2，data128/id4/resp2/last。全部通道位逐一连接同named字段，无ID重编码/截断、无“默认data0成功”。clk/rst直接同域，未新增CDC或pipeline。unused algorithm写响应恒无效，与line_write0合成可裁掉写路径。

实际源码已读证：span AR仅物理ready进入R，cancel/enable只stop_new影响后续burst；line AR也仅ready推进，enable不撤AR。R进入Q后仍按各自drain_tail保持旧尾，data/done/notice反压仍由叶处理。新增Q gating只堵尚未接受的新应用和新物理选择，不能解除已有state/holding。

端到端：应用请求fire→叶锁地址/长度→AR提出→arbiter锁完整49→真实physicalAR→原RID/data/RESP/LAST路由→原叶组装或holding→应用data/terminal真正fire。仲裁的末Rfire可以早于显示holding/done消费，故physical_idle不可当frame closed。

## E 中文语句草图

E1 定义两套标准AR/R wires及三个Q、leaf_ready和bus_idle；组合globalQ=busQ|lineQ|spanQ。新模块不存另一个完整图像字或Origin，只复用原叶。

E2 line_bridge实例clk/rst/algorithm_enable、固定read；new request valid和对外ready按D共同gate，reply完整原样。所有写口明确恒无响应，未连接输出不为父提供写服务。

E3 span实例clk/rst/display_enable/cancel、REQ参数及DATA/DONE握手原样；同样new request共gate，data/terminal不gate。ID默认明示2，容量参数与仲裁一致。

E4 arbiter实例clk/rst/enable、全部端0/1 AR/R标准口、唯一DDR口及物理状态/Q/首因。其Q不能在这里自动复位，且globalQ的组合环只影响新reqValid/arb.enable；三个Q均来自保存state或sticky FF，不由newReqValid组合产生，所以不形成组合自反馈。

E5 观察physical_idle和leaf terminal分别记；停止后保留所有held应用通知，不发伪DROP/RETIRE。复位只能共同安全冷rst，不能用一种业务操作清三表。

## F 语言和时间

SV2009、同core正沿、组合gate/wire不加一级；旧AR/R fire沿和叶内部持有原样。所有数值/预算/首因见三个冻源，ADD/FF/LUT通过组合MAP测量，不能把三个独立值相加作为组合结果。TB负沿驱动、preedge事件日志、NBA后观察，独立Python用应用与物理事务集合/全128/512地址byte图及真实terminal重建，不抄DUT状态或从internalcounter取期望。

纯逻辑部件无新RAM/PLL/CDC；原native网表/PNR/100MHz/DDR服务另验证。不启用写通道、不改变原256MiB/1080p目标；algorithm64B与display8192B是已存在接口范围，不是削减图幅。

## G/H 测试与追踪

RPT1 正常单/双源，算法完整64B和显示16/1024/8192B；RPT2 跨4KiB/末256MiB合法与非法应用边界，原叶拒绝不发物理AR；RPT3 两源持续、AR/R/data/reply/done长停顿与气泡；RPT4 display取消在PLAN/AR未ready/R/holding、stop和enable失效语义分开；RPT5 RRESP错误正确drained，wrongRID/早晚LAST Q以及后续新应用ready=0、旧尾/通知继续，绝不physical_idle→closed；RPT6 共同reset和新几何/旧应用作废；RPT7 当前源独立参考/真实工具/MAP。

RP01/02→E2/3/4及标准口→T1/2/3；RP03→E1/Q门及叶保存→T4/5；RP04→物理/应用层区分→T3/5/6；runner/工程/模型→T7。各实例和新增符号反向对应上述要求。

## I/J/K/L 门槛与恢复

整体/例、职责及实际相邻源码、精确端口和所有保持/错误/终态连接、中文逐语句、语言/旧沿及端到端、测试/追踪齐全；当前接口正确性无未知，真实DDR期限与生产top明确范围外。保存读回呈现，READY v1/8输入/7自写，按持续自主软件/local audit实施，不另问批准。

差异先短卡，失败保留，三原叶/登记产物不改。源码出现一个组合服务不等于摄像头/算法/显示整机已联通；后续必须实例化真实三叶的联合TB和独立应用账、MAP，再接生产root/实际DDR/lookup。理解验收待用户作答，正式DB/H0/硬件保持；完整目标及最终bit继续。
