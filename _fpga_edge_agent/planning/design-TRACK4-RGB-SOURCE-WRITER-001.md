# TRACK4-RGB-SOURCE-WRITER-001 v1：彩色源连续字节、双bank和真实写回

2026-10-08。按用户持续自主授权及本地审计推进；先此可读回设计，再独立work/rgb_source_writer实现。原CAM/CW草图作为来源，原HDK/已登记包/正式DB/硬件只读保持。

Goal：将RAW10彩色流的canonical RGB48实际保存为完整、行优先、连续R/G/B字节源帧，双1KB bank支持读写复用，安全写回后给局部终态。Current：实际4RAM RAW窗口/插值小图及Efinity MAP已通过，1080p四phase进行中；缺完整RGB源writer。Target：P RGB pair、L=3WH真实字节、完整物理授权区、两bank/有界组拍/64B请求/错误取消关闭，独立字节内存比对。Gap：RTL/参考/TB/组合资源；真实DDR AXI/phase fence与FM源发布仍随后。Assumptions：W偶数4…1920/H2…1080，同clk，独占base64B对齐和A64=64ceil(L/64)的完整授权区；64bit本地handle由外层完整scope映射保留。Open questions：本软件单元无阻塞；真实CSI不可反压期限、DDR器件模型和最终带宽尚须证明。

Milestones/Detailed steps：整体→端口→packer/两bank/双holding/RPC旧状态→RTL→独立字节/协议→1080p→与RAW链路及AXI/FM组合。State transitions：设计保存读回READY后持续授权实现，不再请求逐单元批准。Artifacts：work/active/track4_algorithms_20261004/rgb_source_writer。Validation：SW-T01…08。Failure：安全错误先结旧请求再失败，未提出私有槽可丢；未知drain隔离。Human gates：无硬件操作。Rollback：保留各run和冻结输入。Completion：实际字节/计数/排空正确、实际RAM资源；不是整个源COMPLETE或整机完成。

## A—C 整体与职责

writer job锁base/handle，接RGB pair及中心坐标/markers/bad/handle。canonical48={R1,G1,B1,R0,G0,B0}明确重排为DDR顺序R0,G0,B0,R1,G1,B1。carry≤7byte与新6byte组成112bit临时容器，每个实际正常pair最多写一次64bit RAM word；余数carry仍同帧。两bank各128×64有效payload=1024B，四条512×20 RAM10并行80bit，高16固定零；bank0地址0…127、bank1=128…255，256…511不访问。

bank满后不可变SEALED，另一FREE bank继续append。后台assembler对SEALED bank逐64B读取8个64bit word，两个512bit组拍holding预留返回空间；同步RE一沿/下一沿capture，可旧capture和新RE同沿，每拍一个word，没有数据气泡依赖。准备好的64B按顺序走唯一line RPC，owner/body从提出到回执保持。bank直到所有线真实成功且pending/holding/public借用全部归还才FREE，不凭末RAM read/末data fire回收。

最后pair/EOF先真实append，之后carry尾word补零和授权A64范围内零word补齐，最后partial bank再seal；没有空bank/零长请求。L实际字节和A64授权物理字节分别计数。production1080p的L=A64=6220800B；小图A64与旧CAM A16候选不同，必须由外层显式授予A64，不能擅用页分配余量。本软件口采用与现有cache/Canny共用的64B原子line RPC；后续AXI服务可聚合相邻line成大burst，不以当前拆分预称最终带宽达标。

模块：rgb_source_ram_word管理4×20bit RAM及不同读写地址；rgb_source_writer拥有job/输入校验/byte carry/bank/assembler/两个packet槽/RPC/不可变终态。父capture lifecycle拥有完整SourceOrigin、scope/grant/phase及接收closure和FM源发布；本地done只证明已经接受及写回的源字节，不等同迟到CRC清白或整体源COMPLETE。

## D 端口和组合

job_valid/ready/base32/handle64、job_rsp_valid/ready/error。in_valid/ready/rgb48/x_even11/y11/markers3={EOF,EOL,SOF}/bad/handle64。cancel_valid/id64。done_valid/ready/id64/outcome2(0OK/1ERROR/2CANCEL)/reason8/accepted_pairs22/logical_bytes32/physical_bytes32/written_lines22；source_stop及quarantined。memory口沿用64B line_req_valid/ready/write/addr32/data512，line_rsp_valid/ready/rdata512/error/drained。普通held body不改，job只能旧终态消费且所有借用结清之后接纳。

所有输入错误仍以旧ready真实fire计accepted，坏tuple不append。reason优先bad→ID→coords→markers；真内存error优先cancel。独立matching cancel可关闭新输入；不因本拍bad反向撤掉旧ready。输入EOF、local seal、最后RPC回执、local done、外层phase fence、RX closure、FM发布分别是不同事件。

两bank共享一个同步RE口和一个WE口，RE仅读SEALED/DRAIN不可变bank，WE只写FILL/padding bank，不同bank/地址，断言无同址依赖。packet slot先reserve，再八个RE/capture填齐后valid；两个slot的valid/reserved计数≤2，REQ/public slot直到回执消费才释放，不能把尚未完成的slot当DDR数据。FIFO packet顺序与global byte位置一致。

取消/错误停止新append、新未提出packet和RE，旧RE在返回沿DISCARD并归还预约；已公开line REQUEST/WAIT继续直到真实drain。其它私有packet/bank可在旧公共借用结清后丢弃，不发不存在的未来请求。drained0保留旧owner/context/bank，不能输出安全done或cfg-ready。

RAW producer已经公开的RGB在writer失败后仍需交付。后续capture wrapper同完整Canny v1.1方式：先等writer旧RPC安全done，然后给RAW color旧held RGB一个明确discard接收出口，广播匹配cancel至RAW color；两个局部done都实际消费及RX closure/DDR fence成立才归还源。不能让RAW等待一个已经关闭的writer ready，也不能提前发布失败帧。

## E 中文内部操作草图

先声明IDLE/CFG_REPLY/RUN/TAIL_PAD/DRAIN/ABORT/DONE/QUARANTINE；两bank FREE/FILL/SEALED/DRAIN及base_byte/word_count/组拍游标/成功line_count；carry56/count3、112bit append_temp；全局actual logical/physical字节计数；两个packet512/addr32/bank/valid/reserved、head/tail槽指针；一个RE pending含slot/lane/bank/word地址；一个公开RPC owner。

组合append：stream_bytes={B1,G1,R1,B0,G0,R0}，其低byte就是R0；temp=(零扩carry) OR (零扩stream_bytes << carry_count×8)。sum_count先扩4bit加6。sum<8只保存temp低56及count；sum≥8写temp低64到当前FILL word，余数temp右移64存carry，unused高位必须零。WE目的地先由ready保证，最后word127真实WE后SEALED，carry仍保存跨bank余数。

没有FILL时从FREE分配，base_byte=旧physical_bytes，word_count=0，RAM不清。EOF完成该pair真实append后TAIL_PAD：carry非空在后续沿写一64word、余高位0并清carry；再写零word直到physical_bytes==A64。每次WE physical_bytes+=8，word_count+=1；128满仍正常seal，必要时下一bank继续padding。A64==physical且当前FILL有字则seal，空FILL直接FREE，不创建空请求；没有FILL的满bank EOF不新开空bank。

后台writer按最早base_byte SEALED选择bank。每个64B packet slot reserve后逐word RE，下一沿capture到该slot指定64bit lane，同时下一word可RE；第八次capture后slot才valid，保存base+bank_offset+64×line_index，指针只按真实reserve/capture/回执推进。最多一个RE pending，握手请求固定head packet；地址33bit检查且64B对齐，不跨4KiB。全部descriptor line都成功才bank退休；退休检查RE pending/packet slot/public owner都不借该bank后才FREE，回收供下一沿分配。

正常DRAIN等待所有应有bank全部写完、无RE/packet/RPC借用，核accepted=P/logical=L/physical=A64/written_lines=A64/64才OK。ABORT实际旧RPC成功/错误回执排空后清私有bank/槽，done保持原first error或CANCEL；实际error优先。unknown在任何状态直接隔离，旧ctx不清；同步rst只能以外部安全共同复位证明使用。

## F—H 验证、追踪、性能边界

SW-T01：canonical示例445566112233→DDR连续112233445566；独立Python字节串比对全L和A64 padding，不模拟carry/RAM FSM。T02：4×2、6×5、34×19、跨1024B、整bank EOF、carry0/2/4/6/EOF零padding、4KiB段边界、合法32bit端点及对齐/范围拒绝。T03：两bank满、RQ/回执持续反压、双packet预留、RE后stall/旧capture、新line同沿、不依同址RAM、bank最后回执不能早free。
T04：错误ID/坐标/marker/bad、cancel部分carry/FILL/SEALED/READ_PENDING/packet/public请求/等待回执/held done，安全error优先cancel与unknown隔离。T05：四phase RAW color→本writer、公开RGB故障discard及两个done不同先后，完整1080p的全部源字节。T06：真实4RAM/FF/LUT/DSP综合及单元持续无停顿吞吐记录；实际DDR/CSI期限另证明。T07：真实AXI/phase fence/RX closure/FM发布/显示同源。T08：整机资源/时序/PNR/总bit及全十一项。

追踪SW01字节布局→carry/RAM→T01/02；SW02双bank/组拍/借用→T03/06；SW03真实关闭→RPC/终态/父wrapper→T04/05/07；独立参考/TB/runner→实际源hash和日志。数学及旧状态走查如上，本单元不以候选吞吐代替实际目标。中文理解验收待用户阅读反馈，代码前保存并读回。
