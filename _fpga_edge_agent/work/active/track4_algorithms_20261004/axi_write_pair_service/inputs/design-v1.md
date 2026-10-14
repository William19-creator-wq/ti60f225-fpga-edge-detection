# TRACK4-AXI-WRITE-PAIR-SERVICE-001 v1：两个实际64B写接口共享一个AXI适配器

- Goal：补摄像头RGB源写帧和算法结果/工作区写入的公共写服务，推进完整五基础六高阶/1080p/Ti60F225/I3/SC431HAI；完整识别、帧率及整机不缩减。
- Current state：read_pair实际三叶联合38场景与MAP通过；rgb_source_writer真实输出64B line_write1、完整512/addr32并保留PUBLIC直到rsp；capture_canny_axi算法有同样line写接口，但旧服务读写全部串行。原line_rpc_arbiter2另保存一份512快照；本新write-only公共服务采用直接真实接纳，写快照仍仅由实际axi_line_bridge拥有。
- Target state：七自写文件、一个实际bridge依赖、两个写接口的公平接纳及AW/W/B真实完成、独立数据/事务账与Ti60/I3 MAP。
- Gap：实际camera/algorithm producer实例化和生产root拆分读写、FrameRef权限、读写QoS、DDR动态/总资源/PNR/STA另闭合，不冒充本单元通过它们。
- Assumptions：同100MHz core域，公共同步可信cold rst；父分别授权两端地址和FrameRef，写方保持未接纳的544正文；bridge已校准的enable由父提供，失效的旧承诺仍继续。
- Open questions：本接口/时间已从源码核对，无当前阻塞；最坏DDR服务、camera不可暂停溢出策略/root和FrameRef闭合在后续范围，不能被本PASS替代。
- Dependencies：本设计、v0.2、实际axi_line_bridge源/manifest、rgb_source_writer源/manifest、capture_canny_axi源/manifest共8输入冻结。现有工具无新增安装/网络。
- Milestones：整体/接口/中文语句保存读回呈现READY→冻结8→七文件→实际bridge/两写端刺激/独立账→MAP→登记→生产writer/帧管理组合。
- Detailed steps：下方B整体→C/D接交→E语句→F语言→G/H验证/追踪。
- State transitions：READY_FOR_REVIEW v1；按用户持续“当你统计完后自行进行，无需我的批准”及本批local audit例外实施，不重复逐版申请，不冒充数据库授权更新。
- Artifacts and hashes：新work/axi_write_pair_service；RTL、TB、Python reference、sim/map脚本、XML/SDC七份+bridge原样复制一份=8运行源码/工程。版本/输入SHA于baseline记。
- Validation：全544请求/145W/6B/两端口2bit回执，地址边界、全数据图案、3:1可用机会、AW/W/B/回执背压、disable各阶段、正确BRESP错误、wrongBID/早B/无ownerB、Q通知先于旧B、四态、共同reset。
- Failure handling：记录失败、不降低门槛；UNKNOWN通知不释放服务归属，globalQ只阻新接纳，不屏蔽旧AW/W/B/回执；真实错误前已有物理写入不能说回滚。
- Human approval gates：自主软件/本地审计有效，DB仍NOT_CONFIGURED，正式H0/state不变，无硬件/bit。
- Rollback：全新独立副本，不修改原HDK、bridge注册包或任何其他已验证源。
- Completion criteria：当前公共write服务的功能及MAP证据；全部十一功能的整机证明仍ACTIVE。

## A/B 整体要求与样例

WP01：端0摄像头、端1算法两个已存在line写接口，真实接纳完整512bit与地址32；只一个实际axi_line_bridge写适配器/物理AW/W/B。单在途，同ID0串行，不另发camera ID1。ID用于响应核对，不能当FrameRef权限。

WP02：只有shared bridge真的ready且本服务无active/Q、enable1、请求为已知有效时才接纳。选中端的ready与bridge同沿fire，桥自己保存512bit；不会先对上游回ready却未建立真实桥事务，不添加544bit重复holding。双源持续时可用接纳机会camera:algorithm=3:1；单源随时可用，不宣称deadline或整机带宽满足。

WP03：AW固定64B对齐/len3/size4/INCR/ID0；四个完整128 W、WSTRBffff和正确LAST均由真实bridge形成。最后W不回复，必须真实B。正确ID的BRESP错误为error1/drained1（允许此前已有写副作用，不保证回滚）；wrongBID或live enable下降则error1/drained0与Q，后续正确旧B仍吸收，通知不改成功，不释放active。

WP04：globalQ=local_fault_Q|bridge_Q，新请求ready=0；旧AW/W/B/回执不gate。busy=active|Q属于服务占用，不提供伪physical_idle/allClosed；parent仍需完整引用/fence证明。取消由producer停止新事务并兑现PUBLIC line，服务不加取消口。共同cold rst才作废全部本地/物理slave账；不支持局部暖reset证明。

WP05（派生协议防护）：未拥有事务却BVALID为1拒绝本沿新请求并localQ(reason2)；active但未结束4W、未形成回执就出现BVALID且不是同沿最后Wfire，localQ(reason3)。旧AW/W继续，bridge照实际B消费后发布强制error1/drained0，保持unknown归属。已公开回执不因新的外部异常改变正文；迟到的无owner B在旧回执消费后再隔离。选路时四态valid或被选中544正文未知则localQ(reason1)，没有接纳就不伪造回执。bridgeQ首因用reason4表示实际桥UNKNOWN，精确响应/enable证据保留在日志。

正常例：两端持续请求，3次camera后1次算法，接纳→bridge AW→四W→B→选中回执；另一端不能消费这个回执。边界：最后64B地址0x0fffffc0合法，未对齐或越256MiB已知请求被真正接纳并由桥安全拒绝，无AW/W。错误例：wrongBID7先通知UNKNOWN被消费，后真实BID0仍从BREADY吸收，busy/Q保留；不能让下一帧复用。停用例：AW已经公开后enable下降，不撤AW或四W，真实B之后UNKNOWN。

## C/D 职责、端口与组合走查

MOD1新axi_write_pair_service：选路、3:1额度、owner/active保持、派生协议Q，没有写payload RAM；MOD2复用实际axi_line_bridge原样，固定line_write1，负责唯一512快照、AW/W/B/回执，读口明确ARREADY/RVALID=0/RDATA0/RID0/RESP0/LAST0、读输出不用。两producer本批按真实接口刺激，不实例化camera/algorithm主体，不将接口验证叫完整采集验证。

IF1 c_req_valid/ready[1:0]、c_addr[0:1]32、c_data[0:1]512（0字节低8位）；c_rsp_valid/ready[1:0]、c_error/drained[1:0]广播正文但valid只owner。输入请求稳定至实际fire，fire后数据可以变，bridge已保存；本帧/地址权限仍由父负责。对write-only旧producer的line_rdata由parent接0，不为客户端增加读成功。

IF2同域clk/rst/enable；输出busy/quarantined/local_quarantined/bridge_quarantined/fault_reason3。IF3标准AW32/ID4/LEN8/SIZE3/BURST2，W128/STRB16/LAST1，BID4/RESP2。全部unsigned，低byte先写低地址；ADDRESS_BYTES33默认256MiB，范围64..2^32/64倍数沿用bridge。

组合：bridge req_ready由其已保存state、enable和rst产生，不依本服务req_valid；选择门依此ready，内部req_valid仅同沿能fire时为1，所以没有内部valid-held数据需要另快照。producer valid必须独立ready（真实RGB PUBLIC来源已核），ready仅选中且真接纳时为1，没有循环或假接纳。owner在该同沿与bridge快照建立；回执只old owner，从bridge rsp_valid和owner ready建立实际fire，不由globalQ屏蔽。只有drained1且非Q才clear active；UNKNOWN消费仍active。

local fault在bridge回执公开前才允许影响该回执error/drained；到已公开时不再检测“early B”来改其正文。无owner B拒绝本沿new fire；开启的旧桥动作不因localQ停止。桥的BREADY只在真实B期/错BID旧尾吸收，不能提前假响应。安全输入非法地址由桥保持error1/drained1回执，无物理写，公开后同样稳定。

## E 中文逐语句草图

E1 定义active(初0)、owner(0)、camera_credit(初3)、localQ(0)、首因reason(0)、write_complete(0)，桥ready/valid/error/drained/Q。没有自写512 FF；c_addr/c_data选中组合正文只在本沿真fire被实际桥保存。

E2 从两个valid和旧credit选camera或algorithm：双方可用且credit0才选algorithm；camera-only仍选camera，algorithm-only选algorithm。enable/空闲/无Q/桥ready构成可选资格。unknown valid/body或本沿unowned/earlyB故障不回req_ready，不发bridge req_valid。

E3 全c_req_ready先置0，仅资格成立置选中1；bridge req_valid为真实onehot申请fire条件，bridge addr/data为选中正文。正沿发生接纳锁owner、active1、write_complete0；camera grant credit非0时减1，algorithm grant恢复3，普通等待不改额度。

E4 连接actual桥的line_write1和全部标准AW/W/B。桥enable直接来自父，不因localQ强制停用旧物理事务。第四个实际Wfire置write_complete1；未完成但B提前出现依WP05记localQ，first reason仅空时保存。

E5 c_rsp_valid只active owner且桥valid；line_rsp_ready=active&&c_rsp_ready[owner]；c_error=bridge_error||localQ，c_drained=bridge_drained&&!localQ。UNKNOWN实际消费不清active，安全消费且无Q清active；Q门不碰旧ready/valid。bridgeQ与localQ或成globalQ；busy=active|Q，没有frame closed字段。

E6 同步rst清E1所有身份/额度，桥共同rst；parent只在可信共同冷reset使用。normal/unsafe enable恢复不清Q或active。不因超时生成成功或clear owner。SV四态检测是仿真语义，不当现实CDC或亚稳态检测证据。

## F 语言、时钟及资源契约

SV2009；组合blocking，FF nonblocking；所有事件正沿前采样、FF沿后更新；TB负沿驱动、正沿前完整事件账。fire同沿owner与桥512寄存器更新，下一沿AW可见；AWfire后四W，末W后的真实B才能回执，回执held延长active，所以不能把四拍当固定总延迟。无C++，Python只独立全字/地址/事务账，不能读DUT内部或抄state机作为期望。

param范围沿用桥，4KiB因64B对齐天然不跨；非法known申请由桥ERROR/drained1拒绝，unknown申请当前无接纳并Q。无新RAM/DSP/CDC、共享写512快照且W固定4slice；资源预算由actual组合MAP测量，目标100MHz不等于物理达标。camera流能否持续取决于上游容量与DDR/QoS，后续要检实际live溢出帧有效性，不能从数学producer可暂停推断camera达标。

## G/H 测试语句与追踪

TB按公开c请求与AW/W/B/回执记录全周期，不记录hierarchy。slave实际AW接受建立地址/4拍，逐W真实fire写完整16B、last/STRB核对，延迟/非OK/wrongID B由场景产生，停顿所有正文保持。独立Python从c_req fire的完整544与owner建账，核每AW/4W/真实B和响应全2bit，识别已写副作用/确认成功/未知三层，不从BVALID或最后W猜closed；旧notice消费后的lateB仍保留原物理记录。首个cold沿前FF未知不解析，rst门控握手必须0，正常期间未知只在明确负样例四态字段。

WT1 双源48:16持续、停顿双源48:16、单源各24，逐次选路pattern0001重复16、所有512字与低地址byte、相邻/容量末64B和非法；WT2全0/全FF/首尾单bit与固定随机seed全payload、AW/W逐拍停顿、B长延迟、回执held、申请后proposal变化不影响快照；WT3正确BRESP1/2/3安全错误可后续新申请；WT4 enable在新选择前/AW/W/B/公开回执各阶段，旧AW/W保持、invalid安全回执held不改；WT5 wrongBID/多badB/通知先消费后真B、无ownerB、earlyB及同末W提前B、Q新禁止/旧继续；WT6明确共同cold在AW/W/B/held回应及X/Z申请，分开作废账、不冒充暖reset；WT7当前源/真实工具/fatal失败守卫/独立audit/实际MAP。

计划24基本场景并把0..3每W停顿和各复位位置展开成子case，最终固定完整列表、coverage计数与独立预期；不将工具exit0或TB自称finished当PASS。初始pressure门槛≥200完整写line/≥800 W、AW/W/回执stall均非0、wrongBID和early/unownedB及四态均观测、至少4个明确reset作废。若代码与既定场景偏离，先短卡，不改测试冒充源正确。

WP01/02→E1..3/IF1/实际桥→WT1/2；WP03→E4/IF3/桥B路径→WT3/4/5；WP04→E5/6服务占用及通知→WT4/5/6；WP05→E2/4首因→WT5/6。runner/工程→WT7。每个新增核心单元从上述REQ返回接口/草图；最终README核实际符号与结果。

## I/J/K/L 门槛与交付

整体/正常/失败样例、实际复用调查、精确端口与同沿接纳组合、局部FF/语句、语言A–L适用项、端到端路径、测试/双向追踪、无当前接口阻塞、保存读回呈现与8输入范围明确：READY v1。沿用持续自主软件及local审计，不修改正式Manifest/数据库状态。新功能使用work副本，scope变化先短卡及读回呈现。

获准软件顺序RTL→TB/独立参考→运行脚本/XML/SDC→实际sim/fatal/audit→当前源MAP→登记staging/报告；理解验收待用户实际作答。当前测试尚未运行。交付仍列未实例化实际producer、无QoS/FrameRef authority/真实DDR/PNR/STA/bit，不能称完成整个FPGA。
