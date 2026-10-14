# TRACK4-AXI-LINE-BRIDGE-001 v1：64B单事务到板卡128bit AXI软件接口

2026-10-09。按持续自主授权、v0.2先保存/readback READY；本单元是DDR服务底层适配，不替代完整DS/FM授权和实际DDR动态资格。原保护IP、模型和正式状态不改；独立work/axi_line_bridge。

Goal：把目前RAW源/Canny cache/queue使用的64B line RPC实际转换为V4 DDR3公开的128bit AXI读写。Current：实际来源已确认byte32/ID4/data128、SIZE4/BURST01，旧帧buffer未检查B/RESP；新软件组件目前止于line RPC。Target：一个完整512bit请求快照、4个全16B AXI拍、真实B或完整R后才回复、所有保持/错误/隔离可测试。Gap：RTL/独立byte memory AXI slave/TB/组件MAP/实际生产DDR组合。Assumptions：稳定同clk、真实控制器已校准且enable1；本组件所有旧事务关闭后才允许共同rst。AXI读写只一个总live，固定ID0，软件模型按AXI公开端口行为实现，不冒充匹配2Gb器件模型或PHY。

Milestones：整体/接口/内部→冻结V4公开参数/模型来源→RTL→四拍/反压/错响应/保持→源及Canny实际line接入→MAP；phase fence和生产DDR动态后续。State：READY readback后自主实现。Failure：错误日志保留；无法证明实际事务结束则drained0隔离。Human gates：无硬件操作。Rollback：全新运行，不覆盖旧软件包。Completion：AB-T01..05的软件单元证据，不是DDR整机闭合。Open questions：物理IP的B/R可见性、校准恢复、最坏服务期限、DDR匹配模型仍单独待证，不妨碍公开协议单元实现。

## A—D 整体和接口

line输入valid/ready/write/addr32/data512，输出rsp_valid/ready/rdata512/error/drained；quarantined。enable只决定IDLE新请求资格，不在held AW/AR/W或等待B/R时撤回旧承诺。若active时enable下降记uncertain，仍完成旧公开通道；终结只回error1/drained0，保留隔离owner，外层不能归还frame。enable后来恢复不擦uncertain。

AXI AW/AR：valid/ready、addr32、id4=0、len8=3、size3=4、burst2=01；W valid/ready/data128/strobe16全1/last。B valid/ready/id4/resp2；R valid/ready/data128/id4/resp2/last。各方向是单独物理channel，组合仅此单元一个live，所以新line不与旧line共ID。物理地址授予仍由外层；本单元额外检查64B对齐和端点≤ADDRESS_BYTES，默认板载2Gb容量268435456，不把内部ADDR_WIDTH30当容量。ADDRESS_BYTES范围64..2^32、64B整数。

请求真实fire锁addr/write/wdata，非法alignment/range也记录实际接纳，立即安全ERROR/drained1，不发AXI；上层grant/scope/phase/lease由当前line仲裁/父对象保留。4KiB边界因64B对齐且只64B天然不跨；地址最后64B合法。写先AW公开并保持，AWfire后4个W按index实际fire推进；第四个W仍不回成功，等待B。BID0和RESP00且uncertain0才success；正确BID但RESP错误是安全ERROR/drained1；错BID无法证明本owner响应，通知drained0并隔离。

读先AR公开并保持，ARfire后完整512bit预留容量接4个R，不依客户端rsp_ready。只有RID0、RESP00、count/LAST均正确且uncertain0时发布数据；R响应错误但四拍/LAST/ID正确则安全ERROR/drained1、rdata全零。错ID、早LAST或第四拍缺LAST均不能假排空：停止数据发布，通知error/drained0并隔离；第四拍缺LAST后仍维持物理RREADY收尾到真正LAST，保留旧borrow，不以超时清账本。未知通知不得改成后来成功。

取消由现有client处理：已提出line持续直到本服务真实回复，本服务不再增加一个会撤回AW/W的cancel输入。phase fence不能由此单元reply替代；完整DS需要所有父/客户端、授予/归还/时钟域义务另外汇合。该组件逐line串行不预称最终相机/显示带宽达标，未来coalescer及读写并存策略须用实际测量决定。

## E 中文内部语句草图

enum IDLE/AW/W/B/AR/R/REPLY/QUARANTINE，另外q_notice_valid和drain_tail；锁base、write、512bit write_buffer，独立512bit read_buffer，2bit beat_index、sticky_rsp_error、uncertain。所有公开AXI body从锁寄存器和旧index组合；W slice用4项case固定切片，读也4项case写固定128bit切片，避免动态数组部分写综合歧义。IDLE line_req_ready=enable&&!rst；req_fire检查33bitend与alignment后选AW或AR。

Q下真实旧尾回应仍须吸收：错RID即使该错RID带LAST，也继续RREADY直到真实ID0/LAST；第四拍缺LAST同样持续读尾。错BID另保存q_wait_b并维持BREADY直到真实BID0；这些收尾绝不把已经不可变的drained0通知改成安全终态。正确ID的早LAST已结束物理返回但计数不可信，保持Q，不发新AR补读。未知来源的后续数据不填用户read_buffer。

AWfire→W；旧Wfire index0/1/2各+1，index3→B；只有Bfire核响应后REPLY。ARfire→R；每个Rfire先核ID/LAST/count，正确拍写固定slice，末拍发布时rdata必须用包含本拍的next_read_buffer，不能漏末128bit。普通RESP错误sticky到最后合法LAST再安全错误回复。REPLY保持rdata/error/drained直到rsp_fire；成功或安全错误归IDLE。未知进入Q，notice保持直到消费，后续仍Q；缺LAST的drain_tail独立继续RREADY直到实际LAST，无新AR/AW/line接纳。保留旧write/addr和owner，无安全done。enable在active下降只置uncertain，不动通道状态；到实际B/合法LAST形成未知通知。安全rst由外部证明，不用局部reset偷偷清旧账。

## F—H 验证与追踪

AB-T01：独立bytearray slave逐AW/W/AR/R实际事件读写；每拍低lane为低地址，直接数学地址图案/全0/全FF/random/首尾单bit。write B之前无reply，read4拍全部之后才reply，完整64B读回。
AB-T02：AW/AR/W每拍长停顿、B延迟、R逐拍间隙与rsp held、enable下降后仍持公开body、旧proposal更改不改变当前锁；接受/物理四拍/RPC账本。
AB-T03：64B alignment拒绝、合法最后64B、超容量、4KiB相邻、正确ID BRESP/RRESP安全错误；错ID/早LAST/缺LAST及drain_tail隔离，通知消费后仍不ready，安全共同rst后新正常事务。
AB-T04：实际RAW source→bridge→bytearray AXI slave和Canny line服务读写组合，真实内存全字节/状态/FIFO一致，低地址lane与source布局相容。
AB-T05：Efinity Ti60F225/I3 MAP（预计0RAM/0DSP的两512bit保持及控制），资源读报告、必要综合后抽样；生产引脚/100MHz时序/DDR PHY/最终bit后续。

双向追踪AB01完整四拍→AW/W/B/AR/R→T01/02；AB02保持/无假排空→REPLY/Q/enable/尾drain→T02/03；AB03真实字节容量→33bitend/固定lane→T01/03/04。阅读顺序整体→通道交接→E固定case→TB和独立slave→报告。数学不涉及近似或图像降级；本单元只局部句法/协议内部设计。
