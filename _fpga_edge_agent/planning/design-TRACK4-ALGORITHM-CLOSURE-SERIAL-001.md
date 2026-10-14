# TRACK4-ALGORITHM-CLOSURE-SERIAL-001：单操作串行提交的内部草图 v0.1

2026-10-08；沿PLAN_TEMPLATE的短变更卡。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。只提出闭包存储内部的一种替代组织，未改原R4C/BK设计、接口、RTL、正式状态或任何已批准基线。它保留完整1080p、全N非环队列及精确八邻域，不以小图/有限轮次替代原功能。

## A. 目标、当前事实与范围

- Goal：在单操作、独占可变CLASS/QUEUE前提下，将CLAIM的逻辑可见点放在两次物理写均成功之后，研究是否可取消该操作对共享journal的58WE/58RE，而保持原RQ324/RSP449与算法结果。
- Current state：R2流段已实际交付、完整闭包尚未实现；原R4C v0.3与BK v0.1选了单S、无cache、两journal postimage。原BK明确成功回复在物理效果/许可结束之后，当前一次普通操作未结清不接下一操作。
- Target state：可读回的单操作数据/状态/语句草图、逻辑原子性与失败走查，随后与O/CH/实际DDR资格联合决定是否采纳；不是现在就改成新实现。
- Gap/Open questions：SER-B01单操作独占权是否覆盖所有可能读者；SER-B02真实IP写后读可见性/异常关闭；SER-B03END之后诊断/CH是否仍需journal内容；SER-B04完整预算、文件/验证基线和共同版本。四项未闭合不得READY。
- Assumptions：同core域、唯一S、同一H只一个普通RQ在途；CLASS与QUEUE都是私有可变对象，没有外部裸读者；服务在旧RSP消费/本地收尾前不接下一RQ。DDR保留，存储容量不变。
- Dependencies：R4C D3/E、BK E2/E3/F、原DIR/RAW的实际独占/范围及关闭合同、Q0公开DDR端口和后续静态核查。原各设计仍是各自候选，本文不自动吸收或覆盖。
- Milestones/Detailed steps：核已存在的单信用→整体可观察界限→数据/时序草图→正常与错误组合→邻接独占/END/CH读者调查→预算/完整测试→共同版本READY→指定批准→业务代码。
- State transitions：本卡只LOCAL_DESIGN；候选单操作IDLE→CHECK→AUTH→READ→PREPARE→CLASS_WRITE→QUEUE_WRITE→COMMIT→END→RESULT→RELEASE，失败按已公开事务排空或Q，不计时伪关闭。
- Artifacts/hashes：本文新建；旧文档/源码只读，真实来源hash由独立读回报告保存。拟实现仍仅在未来独立work，不创建工作目录。
- Validation/Failure handling：本文是语义/事件分析；未知物理效果不回滚成00，不发布EDGE、不返还旧范围；仿真/综合/布局/时序仍NOT_RUN。
- Human approval gates/Rollback：不是实现授权。若采纳，修订受影响共同设计并等待指定版本/范围/基线批准；不动旧软件交付，可只撤销本候选引用。
- Completion criteria：四项设计缺口消除、具体范围/预算/源清单及验证具备后才READY。完整十一项另需实际代码和整包软件证据，bit后硬件步骤不做。

## B. 整体行为和比较边界

现有公共数学行为不改：00/01/10初态，接纳点变11；全部强种子先入队，再通过八邻域接纳所有可达弱点，每点只接纳一次，head≤tail≤N，全N/P导出包括0。队列保N个32bit entry，不改环形、容量或邻域次数。CLASS2/QUEUE32/EDGE1仍需实际DDR；本卡没有把它们放进片上RAM。

| REQ | 候选内部保证 |
|---|---|
| SER01 | 维持RQ324/RSP449/op0…5的外部字段、成功结果和身份；服务单信用，无新并发读者 |
| SER02 | 接受CLAIM先预留两项授权及tail<N容量，读取完整旧CLASS/QUEUE span，形成两份完整postimage |
| SER03 | 两个写B成功并满足实际可见性后才更新逻辑tail/形成成功结果；单操作执行期间没有任何获准读者能观察第一份已写但第二份未写的中间状态 |
| SER04 | 错误/取消保持真实已发生前缀及未决事务；未完整成功的私有帧INVALID，不以回滚/超时宣称无副作用 |
| SER05 | 下一普通操作在旧结果/授权/在途物理引用收尾后才接纳；后续READ_CLASS/READ_QUEUE读取真实已可见最新后端，不能仅比地址或用旧缓存 |
| SER06 | 本候选只移除journal作为这一个CLAIM的正常数据路径；其它caller/故障记录/共享元数据不能未经调查一起删掉 |

正常例：CLASS同一16B word中有两个弱点。第一次CLAIM读旧word，保邻bit，写CLASS及对应QUEUE成功后tail+1并回复；第二次只能在第一次结束后接纳，重新读到第一个11及第二个01，第二点只追加一次。

边界例：tail=N拒绝新CLAIM，不发任何写；同一个点被第二次请求时旧态11不符期待01，按原一致性规则失败，不再append。QUEUE entry1245184的地址保持32bit，不能截成SRC0；完整span仍在原授权/rounded对象范围内。

错误例：第一CLASS写已B成功，第二QUEUE写失败或UNKNOWN。既不发成功RSP，也不让内部BFS继续读这份CLASS；物理CLASS可能已有11，历史事实保留，整私有build INVALID。只有真实关闭证明建立后才能返还访问范围；下一帧重新完整LOAD，不把旧CLASS当原初态。

## C. 职责与读者界限

L/C仍只发原typed操作；S仍唯一写CLASS/QUEUE/EDGE和持当前scope；O仍负责真实授权/范围/生命周期；A仍唯一负责物理请求、ID/RESP/拍数/关闭。候选变化只在S内部保存postimage与选择COMMIT时刻，不能绕过O或另建一个AXI master。

关键数据路径：RQ→字段/阶段/身份与容量核验→两授权→两span读→postimage寄存器→CLASS物理写及真实B→QUEUE物理写及真实B→逻辑COMMIT→许可结束/原RSP→旧操作退休→下一RQ。

在两次写之间必须禁止的读者：下一typed READ/CLAIM/POP、S内部把物理CLASS11当已逻辑接纳的提前检查、O/CH从可变CLASS/QUEUE抽取成功图、共享adapter其它caller读同一可变范围。其它不重叠SRC/GRAD/显示对象可继续服务，不全局锁DDR。

“只有一个S”不足以证明独占；必须实际调查裸物理读、目录读pin、内部journal/latest旁路和CH诊断借用。SER-B01/SER-B03未消除前，本命题只有条件证明，不宣称已经替换原服务。

## D. 接口与相容检查

原RQ高到低H160/tx_seq64/op4/index21/expected_tail21/data32/coord22＝324；原RSP为echo324/status2/reason5/value32/queue_tail21/effect_ok1/commit_token64＝449。opcode2的CLAIM成功保持oldstate低2位/claimed位2、tail_old+1、effect_ok1、非commit的token0；失败字段仍按原码族，不以新错误码偷改接口。

原CLOSE294/ACK502仍独立；不能因为去掉journal而删除物理债、expected、旧held回复、授权引用或pins_released资格。错误CLOSE证明不返还范围；ACK仍晚于末RSP实际消费与本地旧义务关闭。上游取消不重写已公开RQ/响应。

A的AW/W/B/AR/R及FPI身份/32bit地址/完整span授权保持原候选。第一B0不是两项操作完成；第二B0也仅在ID/RESP/计数/校准/实际可见性合同成立时可作成功前提。cal_done、末W fire、安静一段时间不替代完成。当前2Gb模型及Q1–Q3未建立，这条前提保持SER-B02。

第一版比较保持full16B RMW/fullWSTRB，保留CLASS/QUEUE既有初始化要求；不借局部WSTRB掩盖未初始化邻字，也不自行关闭QUEUE CLEAR。按byte写是另外一个重要选择，须实际控制器mask资格与专门设计，本文不采用。

## E. 局部中文语句草图

### E1. 真实拥有者与有限容器

S保原held RQ324、当前H/阶段/授权与序号账、一结果449和独立close位置；原per-scope/permit/native/transport字段不因为本卡省略而消失。新增或复用的候选工作数据为CLASS_post128、QUEUE_post128、旧态2、old_tail21/new_tail22、两写的issued/completed/effect标记。未实施前不把这个局部列表当全S预算。

两postimage寄存器保存到相关AW/W/B/END引用真实结束；不能用PB单W holding覆盖另一份仍活数据。逻辑tail21只在COMMIT改一次；new_tail先扩22检查≤N。读数据或postimage的高位不会因低位有效就默认全0，须保原邻bit与正确padding。

### E2. 接受、准备、写与提交

1. RQ真实fire只锁原字段并记录接受，不同沿发读或成功结果。下一CHECK先核完整H/seq/op/阶段/coord/index/unused/tail；任何失败不得由坏字段寻址。
2. 先取得并保存CLASS与QUEUE完整span许可，确认当前tail<N和两个postimage容器可用。读取旧CLASS，核01或10与当前SEED/BFS期待相符；读取旧QUEUE span用于full16B RMW保其它entry。
3. PREPARE以旧读回形成两份完整postimage：CLASS仅目标2bit改11；QUEUE仅tail所指32bit entry写合法x/y/高10zero。当前逻辑tail仍old_tail；组合块完整赋默认再修改字段，不在组合块写历史寄存器。
4. 发布CLASS写，AW/W独立保持直到各自fire；真实B匹配后保class_written事实。此时不能把class_written当逻辑claim，下一typed请求仍禁，不能读取这份中间CLASS做BFS。
5. 发布QUEUE写并等待完整真实B/可见性；保queue_written。它是当前已接受CLAIM的后半部分，不是假设已公开的事务。取消/停止的发布边界见E3，不能同时说已停止全部新物理publication又继续提出后半写。
6. 两项成功、授权/旧身份不变且没有使本build失效的错误才进入COMMIT。COMMIT以旧成功位为前提，在一个沿更新逻辑tail与这份操作的success事实；随后按原END/冻结结果/回复/退休规则继续。不能在第二B同沿误读刚置的完成位就重复提交。
7. 旧RSP held及引用关闭后进入IDLE；下一请求重新读取后端最新值，不用未证明寿命的“last address”缓存。取消/错误的build不恢复成普通IDLE继续BFS。

### E3. 中止与复位边界必须明确

接受RQ是逻辑承诺；S→A首次FPI valid可见是另一层publication，A→IP首次AW/AR valid可见才是物理publication，三层不能合并。S不窥测或猜测A内部状态来撤FPI。预写取消可在旧read实际排空后停止尚未公开的写FPI并返回失败/关闭；已经公开的FPI全文保持到真fire与合法回应，物理边界由A按原契约处理。

若第一写FPI已公开，S必须兑现它并保存真实effects；第二写FPI尚未公开时默认停止本build并走失败关闭，不为了凑“原子”自行提出新写。中间CLASS可能已改，但读者门保持关闭、整体INVALID，因此不把这种失败包装成正常原子成功。若第二写FPI也已经公开，就继续兑现其旧请求/回应，不以cancel擦除它；A独立记录实际AW/W/B和未提出事务的合法失败处分，S只能依据匹配回应/关闭证明更新账，不能因没看到AW就声称该写不存在。

普通取消不回滚已发生事实，最终build仍不发布。功能rst也不能冲刷承诺域的held/expected/未知效果；共同安全隔离或合法关闭之前保留当前范围。缺响应/错ID/校准丢失只诊断Q/UNKNOWN，不用timer或一次读回制造closed。

这与原BK“提交后journal保postimage以排空”的安排不同，须在采用前明确映射取消的真实前缀及END/CH证据；当前未改原设计期待值。

### E4. 条件原子性读回

有外部可观察逻辑读的时间点只在S空闲/取得完整响应后。执行第一写到第二写的区间被single-credit及独占读者门覆盖，故正常情况下读者不能观察只有CLASS或只有QUEUE更新；COMMIT后两项物理可见，逻辑tail对应新entry，后续读与原算法相同。错误时不存在成功输出，私有build无效且范围仍受保护，允许实际不完整副作用保留。

证明依赖不是“写了两次所以原子”，而是明确读者集合、禁止区间、两真实完成和下一操作准入。任何相邻模块能在该区间读mutable对象，就必须拒绝该候选或补真实的保护方案，不能删掉原journal后才发现旁路。

## F. 语言、时间与成本

RTL SV2009，整数/地址先扩再核；同core上升沿旧值采样/非阻塞提交。无C++，后续独立参考仍对完整初始CLASS求八邻域集合，不复制本写次序。A数值：原2bit/21bit/32bit地址/33bit末端；B/C真实fire；D气泡不形成操作；E held与引用；F两写完成后的后续COMMIT；G取消与共同安全复位分开；H原H/配置/权限冻结；I两128工作槽、全N DDR队列；J原typed/FPI/raw身份独立；K本S同域、PHY/CDC沿后续资格；L实际预算/工具NOT_RUN。

原BK普通CLAIM为两保护读、两full16B写，journal prepare58WE/readback58RE/state2WE，以及O的两span授权检查。候选保持相同DDR数据访问与原授权，若条件满足，仅这一个CLAIM正常路径可消除上述116条journal数据WE/RE及两state更新，不假称省下116个总clock，也不删除其它caller的共享journal/RAM。

若K≤N为实际接纳点数，移除的正常CLAIM journal数据事件为116K；最大K=N=2073600时240537600条事件，另原state更新2K=4147200。更少native事件是条件比较，不等于帧率；O/物理等待/INIT/其它op及共享仲裁仍有成本。完整FF/RAM/XLR变化必须按旧唯一实例、工作槽/元数据寿命和实际网表计算。

## G/H. 验证与追踪（尚未执行）

| TEST | 条件、期望与对应要求 |
|---|---|
| SER-T01 | 同word两个claim/同队列span四entry/重复点/tail=N；邻bit不改、只append一次，完整RQ/RSP逐位；SER01/02/03/05 |
| SER-T02 | 第一写前/第一AW held/末W/第一B/第二写尚未公开/第二AW held/第二B/COMMIT/heldRSP分别取消；真实prefix、INVALID/关闭，无假rollback；SER03/04 |
| SER-T03 | 合法其它对象读并发、同mutable范围裸读/目录读pin/CH诊断尝试；前者可服务，后者必须被真实保护门阻止，不能只有文字假设；SER03/06 |
| SER-T04 | B错误/错ID/缺B、校准失效、功能reset；已public事务兑现、UNKNOWN不返范围，failed build不进入下一BFS；SER04 |
| SER-T05 | 完整1080p长蛇/斜链/环/密集/无strong/无weak，独立全N可达集合与全N/P导出；算法/数量/快路径不降级；SER01/05 |
| SER-T06 | 原END/CH/RETURN/close及其它journal caller；不留下隐含postimage读者/删错共享RAM，统一预算/真实资源/时序证据；SER06 |

反向：两postimage/写状态只对应SER02/03；保护门及INVALID对应SER03/04；held RQ/RSP与接口对应SER01/05；现有授权/END/CH对应SER06。实际计划文件可落唯一logical_state_queue_service.sv局部状态，不新增业务模块实例；具体文件/脚本/TB/基线与有限case/timeout仍SER-B04，批准前不生成。

## I–L. 自检、缺口与下一步

整体、局部语句/旧沿、正常与失败样例、条件证明和成本比较已有可检查内容；SER-B01…04仍当前正确性/交接缺口，保持NOT_READY。下一步是限定调查O/CH/其它S内部读者，明确哪些引用以原journal为真实来源，再选择维持旧方案或形成完整替代共同版本。当前不请求用户批准这个未成熟候选，不与待批STATS/ANGLE或DDR网络请求混同。

### 本轮限定来源调查反馈

实际读取DIR的descriptor640/read_pin_count/write_pin/初始化/COMMITTED规则及CH的S_FINAL938、封存/RETURN/PUB运输：CH938没有postimage字段，正常外部封存值来自S台账/原初态353，不靠之后裸读CLASS/QUEUE内容。但quiet9明确含journal/native/permit/borrow；它不能在移除CLAIM journal数据路径后被直接常量置1，也不能因此删除其它caller共享journal。SER-B03的“外部postimage payload是否需要”已有否定文本证据；真实S内部诊断、其它caller及统一quiet来源仍OPEN。SER-B01仍需实际逐路径确认，不从write_pin1自推全部读者被关。

调查还确认FPI841与AXI是两层公开承诺，E3已明确二者，避免让S在取消时根据不可见的AW猜测是否可撤旧FPI。该补充只在本候选，不偷偷迁移原BK或共享A。

恢复核本文/来源/hash及真实批准，不能从本候选直接改原期待值。未来重要改变须同时同步父/服务/END/CH/预算/测试。交付须按整体→接口→局部语句→实际代码→独立集合/事务证据→同源物理/bit顺序读回，当前无实际实现/工具/硬件结果，也没有用户理解验收。
