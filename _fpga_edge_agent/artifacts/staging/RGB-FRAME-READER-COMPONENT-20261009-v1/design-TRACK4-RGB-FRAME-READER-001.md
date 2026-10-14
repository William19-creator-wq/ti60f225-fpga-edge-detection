# TRACK4-RGB-FRAME-READER-001 v1：真实连续RGB源读回及FP74交付

2026-10-09，持续自主授权和本地审计；先保存/readback READY再独立work/rgb_frame_reader实现。原HDK、已登记包、正式DB/硬件保持。

Goal：从已安全写回的RGB888源帧读取真实字节并产生原R1/R2的FP74，不再在Canny TB另造一条RGB输入。Current：RAW源与64B/128bit AXI桥已分别通过，缺源读回。Target：两512bit读holding、跨64B的6byte pair、完整FP坐标/markers/handle、取消与真实借用关闭、独立参考及1080p。Gap：RTL/TB/参考/MAP。Assumptions：同clk，可反压消费者，W偶数4…1920/H2…1080，外层授予base64B对齐/A64=64ceil(3WH/64)完整只读区，完整SourceOrigin/DSscope由父保留，64bit局部handle唯一；源在本job期间不可变。Open questions：真实DDR资格/帧授权/显示服务期限另闭合，本单元不阻塞。

Milestones：整体/接口→双slot/跨line/旧状态→实现→尺寸/padding/协议→1080p→MAP→接采集/Canny。State：READY readback后自主实现。Artifacts：work/rgb_frame_reader及runs。Failure：旧REQUEST/WAIT必须真实排空；unknown保留owner，只有外部安全共同rst恢复。Human gates：无硬件。Rollback：新RunId、保留旧证据。Completion：FR-T01…05通过，不等同生产FM发布或整机bit。

## A—D 整体和接口

job_valid/ready/base32/handle64；job_rsp_valid/ready/error；out_valid/ready/fp74/out_id64；cancel_valid/id64；done_valid/ready/id64/outcome2/reason8、prepared_pairs21/output_pairs21/read_lines22/discarded_lines22、source_stop/quarantined。memory口沿用64B line RPC，read固定write0/wdata0；所有地址扩33bit检查32bit端点，完整授权包含padding。

每个line预留一个完整512bit槽才提出请求。两个明确512bit寄存器及EMPTY/RESERVED/VALID状态，FIFO head/tail；一条公共RPC。返回成功填原预约slot，drained1的错误给ERROR并安全关闭；drained0隔离保留slot/上下文。公开请求body和公开FP一旦valid便保持到ready；不因取消、消费者失败或时钟域事件私自改body。

RGB源顺序为低地址R0/G0/B0/R1/G1/B1，canonical48还原为{R1,G1,B1,R0,G0,B0}，FP={bad0,EOF/EOL/SOF,y11,x_even11,canonical48}。源连续跨行不插额外padding。cursor按每prepared pair加6，序列0/6/…/60/2/…/62；cursor≤58只用head，60或62须两个VALID槽，跨line消费head并在下一槽保留2/4byte偏移；cursor58恰吃尽head、下槽cursor0。最后只产生P pair，授权padding不当像素。

out holding74+id64独立保存完整FP，所以创建FP后可以归还已用尽的私有line；output_pairs只实际out_fire加，prepared_pairs按创建FP加，两者不同。暂停仍可最多预取两line且保留公共返回容量。正常done须P prepared/P output、ceil(L/64)成功line、无RPC/公开FP借用；private padding槽此时可清valid归还，不清数组。取消停止新预取/新FP，已公开FP仍待消费；父消费者失败后须明确discard ready来接它，不能让两个done永久互等。旧公开read继续返回，取消后的返回只DISCARD一次，不填新job。

## E 中文内部草图

enum IDLE/CFG_REPLY/RUN/ABORT/DONE/Q和RPC_IDLE/REQUEST/WAIT；两个完整buffer0/1、slot_state、head/tail、cursor6、read_request_addr、reserved_slot、锁base/handle、next_line22，另输出FP holding、x/y及两套pair计数。同步rst只外部安全共同复位；普通job不清像素RAM，也不用当前提案更新锁字段。

RUN且!stop、tail EMPTY、next_line<A64/64及prepared<P时先预约并锁地址base+64*next_line，tail翻转，REQUEST保持→真实fire→WAIT。成功response填对应完整buffer、VALID、read_lines++；cancel/error响应按同沿事实归还或Q；memory ERROR优先cancel。FP槽空或本沿消费者ready才创建新FP，检查head VALID及必要next VALID；将head右移cursor*8，若跨line把另一buffer的低byte补入高位，取低48重排。FP用旧x/y/ordinal造markers，本沿新FP不会同沿计output。

创建时prepared++，更新x/y、cursor；跨line或恰64时旧head置EMPTY且head翻转。old out_fire独立output++、清valid；同沿新创建时再置valid1，实现每拍pair。last prepared后不新预取，最后actual out_fire以后等旧RPC关；正常丢private padding槽，DONE保持。ABORT可丢私有VALID槽，保留RESERVED公共owner和旧FP直到归还，安全done不得仍有line待答。Q保留旧buffer/addr/handle和不可变公共FP，禁止新job，不把未知改成功。

## F—H 验证和追踪

FR-T01独立Python逐像素RGB与坐标/marker造FP，不模拟cursor/FSM；完整源字节/末padding比对。T02 4×2、6×5、34×19、整64B/整1024B和跨line cursor60/62、逐行连续边界、合法32bit最后区间/非法对齐与溢出。T03读请求/回执/FP/done持有、两slot有界预取、错cancel ID、cancel CFG/REQUEST/WAIT/heldFP/末FP/held done、safe read error优先cancel、unknown无安全done、外部共同rst后新帧。T04完整1920×1080所有FP pair并核真实lines；T05 Ti60F225/I3实际MAP/零DSP与原语/时序边界、随后真实AXI/采集/Canny组合。

追踪FR01源连续RGB→两slot/cursor/逆重排→T01/02/04；FR02真实借用→预约/RPC/FP holding/ABORT/Q→T03；FR03同源及完整身份→外层pin+锁handle→后续源Canny组合。中文阅读顺序整体→接口→跨line规则→E具体语句→测试/报告。原1080p、Canny数学与五基础/六高阶目标不降级。
