# TRACK4-CANNY-STATE-CACHE-001 v1：实际2bit分类缓存

2026-10-08。模板PLAN_TEMPLATE；承接CAM/Canny存储草图，按用户“当你统計完后自行进行, 无需我的批准”持续软件实现授权。旧大稿保持历史状态。本任务不等待DDR器件模型，但物理DDR验证不因软件模型通过而完成。

## 通用计划

Goal：把八邻域核心所需状态服务实现为真实可综合缓存；Current：核心完整1080p/协议仿真通过，状态服务仍TB行为；Target：4way×32set×64B，8块512×16同步RAM，原子claim和实际line写回/填充/关闭；Gap：外存queue/共享DDR/帧管理及生产闭合分批接续。
Assumptions：W/H静态（偶W6…1920、H5…1080），N=W×H；分类区64B对齐、长度ceil(N/256)×64B，caller先完成全图/padding初始化及fence；Open questions：本缓存合同无未知，实际DDR bridge由后续单元供给。
Dependencies：hysteresis-core v1、canny-memory v0.3、规范v0.2，真实来源SHA见baseline.json；Milestones/Detailed steps：整体→接口→局部草图→RTL/RAM/TB/独立字节图→实际仿真→queue join→物理。
State transitions：保存读回READY后按持续授权进入实施；Artifacts：work/active/track4_algorithms_20261004/state_cache；Validation：SC-T01…08；Failure：已提出line请求不撤回，失败排空后返回错误，未知排空隔离；Human gates：本地审计、原资料/正式DB/硬件状态不改，无网络安装或硬件操作；Rollback：保留失败run；Completion：真实RAM/cache正确，实际DDR另验，不冒称整机完成。

## A—C 整体行为

SC01：逻辑i21<N，word=i[7:3]（每字8个2bit状态），slot=i[2:0]，set=i[12:8]，tag=i[20:13]。状态00无/01弱/10强/11已接纳，保留同字其他7个状态。
SC02：唯一旧job/分类区，4way/32set；命中从实际同步RAM读取最新16bit字；miss写回脏victim并等可见成功，然后读新64B线/核完毕/串行安装32字，最后才发布tag/valid。无脏写丢失、无半线命中。
SC03：READ不改，STRONG只旧2、WEAK只旧1请求成对claim；cache输出claim_valid/index，queue已有容量时claim_ready，**该沿cache整字WE、queue entry WE/tail推进同时提交**，然后才回复claimed1。没有候选claimed0直接回复。
SC04：FLUSH关闭新业务，逐脏线真实写回，最后成功才失效元数据/关闭配置并回复；全RAM不清零，新job不复用旧valid。
SC05：请求/回复/claim/line数据停顿保持；未知drained0隔离不返回“已终结错误”；共同reset仅在caller已证明后端承诺消失时允许。

模块：state_cache_ram16负责512×16读写（RE沿后Q，下一沿capture）；canny_state_cache拥有128线元数据、PLRU、512bit linebuf、一个操作/返回和一个line RPC。queue adapter接原子claim；外存line bridge接真实64B读/写，可后续转4×128bit。无全帧BRAM。

## D 端口与组合合同

同clk上升沿、rst高同步；fire=valid&&ready，提出后body保持。cfg_valid/ready、cfg_base32、cfg_job_id64、cfg_rsp_valid/ready/error用于初始化；只有未配置且空闲才接新cfg，64bit为独立实验身份，生产完整身份由外adapter保留；base低6bit0，33bitend=base+ALLOC≤2^32。
req_valid/ready、req_op2（0READ/1STRONG/2WEAK/3FLUSH）、req_index21。配置回复消费以后才接业务；FLUSH的index规范0。rsp_valid/ready、rsp_old2、rsp_claimed1、rsp_error1，只在操作真实完成或已排空失败时公开；held后保持，下一req最早消费后下一沿。
claim_valid/ready、claim_index21。必须queue与cache共同取消/关闭；本单元不私自撤销held claim。单一worker串行且当前job独占图，故不需要对其他读者长期pin；原草图6线pin作为性能选择，当前直接写回替换仍保持最新值与精确性，后续优化不改变状态合同。
line_req_valid/ready、line_write1、line_addr32、line_wdata512；line_rsp_valid/ready、line_rdata512、line_error1、line_drained1。每次正好64B/对齐，不跨4KiB，一条live（含未消费回复）。写回应在数据全写且后续读可见后成功；读回应为完整512bit。error1/drained1可安全失败；drained0永久隔离等待caller物理安全恢复，不能当epoch自动失效。
quarantined1通知caller未知后端终结，不释放旧job/linebuf；未请求回复不接受。cfg/req/line均同clock，不直接跨域。

与核心接法：req/rsp对应IF-HY02；cache在响应以前已与queue原子入队。HY随后发送queue push是**成对提交的确认**，queue adapter仅核index并回复，不重复写第二entry；cache/queue在确认前拒绝下一claim/pop。取消在回复沿可使HY不发确认，但整任务作废，物理pair仍保留至安全关闭。该adapter将在queue join独立实现/测试，不把当前TB queue模型自动当此硬件接口。
正常例：i7与i8在两字，claim i7只变其两bit，重复claim回旧3/claimed0；i0与8192/16384/24576同set不同tag填四way，第五miss若dirty先WB再FILL。新job base变更必须旧FLUSH成功。

## E 中文操作草图与旧状态组织

声明RAM的4way×2bank q/re/we/address/data，所有默认使能0；word地址={set[3:0],word5}，bank=set[4]。控制FSM只选一个RAM动作，不同址RE/WE同时发生不依赖碰撞行为。
IDLE：cfg只在configured0接，清valid/dirty和PLRU（不清RAM），核base/end后形成cfg回复；业务锁op/index，越界/非法FLUSH返回error。LOOKUP比较四tag/valid，唯一hit→选way/touch PLRU/WORD_READ；miss优先最低空way，否则树PLRU旧候选→选择victim。
脏victim：WB_READ发word0…31，每次下一沿capture到linebuf；最后capture后MEM_REQUEST才公开64B写。MEM_WAIT核drained/error，成功dirty清0；替换用途失效旧valid并转新FILL读，flush用途继续扫描。没有WB响应不能覆linebuf/旧RAM/tag。
FILL：新地址base+(tag/set组成的line<<6)，扩33bit核范围；MEM_REQUEST/WAIТ收完整line，32沿整字安装，末字沿tag/valid/dirty发布；下一沿WORD_READ，再下一沿CAPTURE，不能同沿读新Q。
CHECK：旧状态从旧word取2bit；READ或无匹配候选直接rsp；匹配候选形成new_word，仅该slot改3，CLAIM保持index/word/way；claim fire同沿RAM WE、dirty=1并形成claimed回复。返回stall时无新操作/WE。
FLUSH_SCAN逐set/way128线；脏→上述WB；干净推进。最后线完成后整体valid/dirty清、configured0，形成flush成功；cfg_ready须等flush回复消费后IDLE，避免同沿穿透复用。
失败drained1置faulted，rsp_error1，后续普通业务只错误、FLUSH在已知无live时失效全部dirty/关闭job并error返回（作废图不发布成功）；caller据错误关闭整个任务。未知drained0进QUARANTINE，所有旧buf/上下文保持、无新cfg/req/rsp；物理安全共同reset后重新配置。
PLRU三bit：root选更旧半组，左右bit选该半组更旧way；touch所选路径置另一支更旧。cache每次hit/安装更新，有效线不重复tag。

## F 语言/数值/时间

SV实际可综合512×16同步RAM，不清数组；单端口操作规避碰撞。meta用FF，8 RAM10为待综合确认预算；linebuf512/meta128×10/PLRU96/控制等FF实际资源后填。上限N2073600、i21、base/alloc33bit，最大line8099，shift先扩33再移6，不能tag13内截断。
操作延迟与hit/miss/WB/外部ready有关；不预称每邻居一拍或FPS达标。一个ready/holding，无吞吐重排；所有副作用按真实fire。复位数据RAM仍未知，valid隔离避免读取；后端物理drain需caller证明。
参考使用Python bytearray/每index2bit读改写和独立请求序列，TB后端为完整字节存储及随机line延迟/停顿；对真实RAM响应及最终外存全图/padding逐字节比较。TB存储不代替真实DDR资格。

## G—H 验证/追踪

SC-T01：0/7/8/255/256/4095/4096/N−1与越界，READ/重复claim/同字两更新，对独立模型和atomic queue事件。
SC-T02：四way同set满/PLRU命中更新/脏替换；先真实WB再FILL，内存最新3、其他字不变。
SC-T03：req/rsp/claim/line请求/回复任意停顿；RAM pending/capture和body保持，不双claim。
SC-T04：FLUSH全128线、无dirty、末dirty、配置切换；最终DDR字节图一致、padding保持初始化0。
SC-T05：读/写安全失败、drained0隔离、半线安装共同reset；不假drain/不发布半线、不许旧job命中。
SC-T06：完整1080p随机/长链接HY与queue hardware adapter，随后独立BFS；本单元首先定址覆盖与fullN访问，组合另执行。
SC-T07：综合8RAM映射、读/写/保持实际STA/资源；SC-T08：真实DDR接口/AXI/PHY及整机另闭合。
SC01/02→布局/LOOKUP/RAM/WB/FILL→rtl/canny_state_cache.sv+state_cache_ram16.sv→T01/02/04；SC03→CLAIM/共同WE→T01/03/06；SC04/05→close/fault/quarantine→T03…05；独立模型/TB/runner→上述实际证据。反向每核心符号只承担这些要求。

## I—L 门槛/恢复/交付

整体、职责、端口、局部草图、语言、组合、验证追踪、范围隔离、保存读回和指定v1基线均就绪；新模块按持续授权实施，不修改旧批准记录冒称新数据库批准。真实queue确认adapter/line-to128bit bridge/DDR/全机在清晰边界外继续实现。最终docs核对实际源码、参数、更新沿、运行证据与未执行项；用户理解待反馈。
验证补充：先单独执行Ti60F225/I3组件综合，top保留内部line512接口，未分配这些内部端口到板卡引脚；该MAP用于核对8块RAM与逻辑资源，不能称板卡布局/时序/bit通过。生产顶层将端口内部连接后再做实际pin/PNR/STA。另补配置上端33bit边界及FLUSH非法index，保留原suite_001通过证据，新RunId重新验证。