# TRACK4-CANNY-WORK-QUEUE-001 v1：外存工作队列与原子claim确认

2026-10-08；先整体再局部，按PLAN_TEMPLATE创建。整体依赖cache v1.1及HY v1；按用户“当你统計完后自行进行, 无需我的批准”持续实现，原资料/正式DB/硬件不改。当前仅该任务设计，未冒称RTL或测试通过。

Goal：实现N容量外存FIFO，两256entry追加bank与512entry读缓存，共4块512×16 RAM，并接cache原子claim/HY确认；Current：实际cache已编码/仿真/MAP，queue仍行为服务；Target：真实append/forward/prefetch/内存写回，正确FIFO及取消关闭；Gap：RTL/TB/line backend/组合/生产DDR；Assumptions：W/H同HY，N≤2073600，queue_base64B对齐，授权ceil(N/16)×64B，初始逻辑空；Open questions：本单元合同可执行，真实DDR另验。
Milestones/Detailed steps：整体→接口→bank/共享RAM/指针草图→RTL/独立FIFO→cache+HY→R2→资源性能；State transitions：保存读回后READY，在持续授权下实现；Artifacts：work/active/track4_algorithms_20261004/work_queue；Validation：WQ-T01…09；Failure：已提出请求保持，安全失败作废job、未知隔离；Human gates：本地审计、无网络/安装/硬件操作；Rollback：保留失败run；Completion：完整N队列和组合正确、真实物理另验。

## A—C 整体及职责

WQ01：FIFO索引entry32={11零,index21}，每点最多一次由cache的唯一claim保证；queue核容量/确认/FIFO。tail/head/committed_tail22，0≤head≤tail≤N、0≤committed_tail≤tail；forward允许head超过committed_tail。入队从cache与queue同沿claim fire开始，HY随后的push仅确认，不重复entry。
WQ02：两个追加bank物理各256entry，512×32通过两512×16 RAM实现；读缓存512×32另两RAM，容量是片上暂存，外部N条目仍完整保留。满不丢，后台writer继续。
WQ03：64B/16entry事务，partial seal保留最新1…15entry prefix，以保证下一次覆盖同64B拍时旧真实entry不被0替代。原v0.3四entry/16B prefix在此扩至16entry/64B，最多512bit carry；存储数值/FIFO/N容量不变，利于与cache共用64Bline backend，后续可聚合连续事务提高吞吐。
WQ04：head<c从已提交DDR读缓存取，c≤head<tail从唯一append owner forward；选择按接受沿旧c固定，写完成同沿不得改来源。pop响应实际fire才head++。
WQ05：seal禁新claim，尾bank写完且c=tail、旧RPC和本地读都归还才回复；normal seal仍同job继续，end_job要求head=tail后关闭；job取消可以作废未承诺剩余entry而关闭，已提出RPC仍排空。未知drained0隔离，不能伪造成功。
模块：queue_ram16_1r1w保存两个append条带和两个prefetch条带；canny_work_queue拥有bank/claim确认/pop/预取/写回/仲裁/关闭；queue服务不发布图，也不承担物理DDR校准。

接口澄清（首次仿真发现并修正）：错误ID或非空normal end是“拒绝seal”，error=1/drained=0，并不声称当前job资源排空。真正接受的seal只有实际排空后才error=0或1/drained=1。seal_valid所在沿不给新claim ready，避免封存旧e与同沿新tail互相覆盖；共同取消仍保留其前已可交付claim的成对提交。

## D 端口和组合

所有同clk上升沿valid/ready，普通held body保持；共同abort_private只作废未承诺内部槽，已公开给HY的回复保持到真实消费/共同关闭事件，线RPC不可撤。cfg_valid/ready/base32/job_id64、cfg_rsp_valid/ready/error，旧job关闭才能换配置。生产完整scope由外adapter持有，64bit实验ID不作截断。
claim_valid/ready/index21：来自cache，ready保证当前OPEN bank/prefix-ready/写口可用/无未确认claim/tail<N/未关闭；fire同沿RAM entry WE、tail++与cache RAM状态WE成对。保存confirm_pending/index，直到HY push确认回复消费前不接下一claim/pop。
queue_req_valid/ready、push1/index21；queue_rsp_valid/ready/index21/error1/aborted1。push必须对应旧claim index，正常不写第二entry；pop必须非空且无confirm，返回最早索引，error/aborted对应同job关闭。不以held响应被abort而重写。
seal_valid/ready、end_job1、job_id64；seal_rsp_valid/ready/error1/drained1、head/tail/c22快照。错误ID拒绝不关闭他job。正常manual seal只提交已有entry，不清FIFO；end_job正常须逻辑空，异常job则安全丢私有剩余。
abort_private_valid/id64与cache同job同沿，cache/queue先记录真实旧claim fire（成对不能拆）；未确认私有claim/POP预约可以共同作废，RAM旧RE仍capture。服务真实错误优先，未知隔离。
line_req_valid/ready、write1/addr32/data512；line_rsp_valid/ready/data512/error1/drained1，与cache同64B原子事务。queue内部writer/prefetch共用该口一live，优先/轮转保存owner，回复不能套给另一方向。最终全局仲裁和AXI bridge随后实现。
forward/pop、assembler共享append RE，write口给prefix init或claim；地址分开，不同址碰撞。每持续requester最多2个grant机会获得一个RE；grant先留返回空间，下一沿capture。有held512bit W即停止新assembler RE，forward可继续。bank回收必须最后写成功/没有未capture读/没有held数据借用，不能只看c推进。

## E 中文旧状态草图

先声明两bank的FREE/INIT/OPEN/SEALED/WRITING、b/s/e22、当前open bank、head/tail/c、carry512/有效count4、一个confirm、一个pop、writer/prefetch FSM与RPC owner。
分配空bank：b=16floor(tail/16)、s=e=tail，p=tail mod16；prefix逐word从旧carry复制0…p−1，不增tail，全部完成才OPEN。claim沿写slot=旧tail−b<256，entry高11零，e/tail增1；更新carry对应全局slot，跨16边界count清0。末物理slot255用新tail冻结e转SEALED，另一空bank可后台INIT。
seal接受后禁止新claim，OPEN若e>s则封；仅prefix且无新entry则直接空。writer只选s==旧c的最早SEALED，按64B块逐16entry读/组512，global index≥e尾lane填0且不读未知RAM。请求提出后512保持，成功且drained回执后下一块；全部块成功才一次c=e。不拿第一块/末data当逻辑descriptor提交。
pop接受沿保存head及来源。若head<c且prefetch范围命中，发该RAM RE；未命中锁a=16floor(head/16)/c_snapshot/end=min(c_snapshot,a+512)，按64B读并16次32bit写安装。所有块成功、末安装完才valid，c后来增长不扩旧end。head≥c时保存唯一append owner/bank/local slot，共享RE仲裁后capture，银行此借用结束以后才能回收。形成held响应，真实交付才head++。
取消关闭：不发新的未提出块/读预约，旧RPC held/响应及RAM pending继续capture；安全已排空后丢私有bank/cache/confirm/未公开pop，通知aborted；若外部未知则QUARANTINE保留旧context。seal/end回复一旦公开不改，新的cfg在其消费后且所有旧借用结束才接。

## F 数值/时间/实现

N21索引、N22计数，base/end33扩展；entry32高11固定0，读回高位或index≥N失败。地址base+4×b/offset先33bit，64B对齐、每事务不跨4KiB。RAM同步RE/下一沿capture，不清数组；metadata有效性隔离。每读/写连续事务的吞吐/随机停顿实测后优化，不能据candidate结构声称FPS。
参考使用独立Python deque及完整字节外存，按真实claim/confirm/pop/seal事件核FIFO与DDR [0,c) 前缀；prefix/padding和末word均有实际比对。行为DDR仅验证客户端合同。

## G—H 验证与追踪

WQ-T01：空/一个/边界15/16、255/256、N−1/N；确认不重复、错误确认、非法entry。T02：partial prefix1…15、多次seal/继续，旧实际entry保留/零padding不被当节点。T03：两bank满、writer停顿、forward与assembler争读、B等价回执与forward同沿、银行借用未归还不复用。T04：prefetch末valid_end、c增长旧padding不得命中；全部物理安装后才发布。T05：head/tail/c、FIFO去重、反压held。T06：各阶段共同取消/未知排空/共同reset恢复/旧claim fire。T07：cache原子WE与HY确认组合、完整1080p及独立BFS。T08：4块RAM映射/资源/生产物理。T09：真实DDR及全Canny/整机验证。
WQ01/02→append/confirm/tail→rtl/canny_work_queue.sv、queue_ram16_1r1w.sv→T01/05/07；WQ03→carry/seal/writer→T02/03；WQ04→forward/prefetch/pop→T03/04/05；WQ05→close/abort/RPC owner→T06；独立参考/TB/runner→实际日志。正常/边界/错误走查如上，无单元当前未知；保存读回后实现。理解验收待用户反馈，全部十一项目标保持。
