# 显示/算法实际AXI读仲裁器 v1

- Goal：补生产DDR访问的实际读接口，维持1080p、完整算法及既有两个叶客户端的AXI正文和错误证据。
- Current state：display_span_axi的READ_ID默认2、burst最多64拍；axi_line_bridge固定ID0、四拍128位读。两者分别动态通过，尚无把两端接到一个DDR读口的实际仲裁器。
- Target state：小型可综合两个客户端仲裁器、中文语句草图、独立总线事件审核、必要仿真及Ti60F225/I3 MAP。
- Gap：本批只闭合读仲裁；摄像头/算法写仲裁、真实DDR PHY、时间服务界及根控制器另继续。不能将接口测试当真实DDR动态。
- Assumptions：两个固定生产客户端同core_clk；每客户端一个未完成burst、稳定valid/body至ready。共同安全冷复位由平台证明旧事务已排空；普通enable不清承诺。
- Open questions：本模块逻辑契约已明确；真实DDR服务延迟/总带宽、显示最坏行deadline、写通道干扰是后续整合测量，未测不写通过。
- Dependencies：实际两个叶源码、display_scan_component与capture_canny_axi的公开端口、规范、旧DDR服务候选及v17进度。原HDK/安装/登记包只读。
- Milestones：保存读回呈现→冻结8输入→RTL/独立参考/TB/scripts/XML/SDC七文件→当前源仿真→实际MAP→登记→接实际父。
- Detailed steps：B整体→C/D组合与接口→E语句→F时间/语言→G/H测试与追踪。
- State transitions：READY_FOR_REVIEW v1；沿用用户“自行进行，无需批准”与本地审计例外，不伪造逐版批准。
- Artifacts and hashes：新work/axi_read_arbiter2，七自写业务/验证文件；输入和运行源分别SHA绑定，失败run保留。
- Validation：独立事件账和全128位数据；双源持续需求、单源、长AR/R停顿、enable下降、零延迟R、错误RID/早晚RLAST/无owner返回、RRESP错误及安全冷复位；实际MAP。
- Failure handling：协议失去可信归属则Q保留占用、不复用；正常响应错误交给原叶处理，不伪造成功。
- Human approval gates：仅持续授权软件/本地审计；正式DB/H0/state与硬件不动。
- Rollback：新work独立，不改原两个叶、生产IP或正在运行的FIT源。
- Completion criteria：这一个读仲裁组件实际通过；完整十一项/生产top/PNR/STA/bit仍ACTIVE。

## A 版本、来源与阅读

2026-10-10 v1。七文件：rtl/axi_read_arbiter2.sv、tb/tb_axi_read_arbiter2.sv、model/read_arbiter_reference.py、scripts/run_read_sim.ps1及run_read_map.ps1、project/read_arbiter_component.xml/.sdc。冻结8输入：本设计、v0.2、实际axi_line_bridge.sv、display_span_axi.sv、display_scan_component.sv、capture_canny_axi.sv、DDR-SERVICE-001候选、checkpoint v17。旧DDR候选仅背景，不据旧有限存储目录冒充已实现。

实际叶接口均AR address32/ID4/LEN8/SIZE3/BURST2、R DATA128/ID4/RESP2/LAST1。display_span_axi默认ID2、INCR/16B、最多64拍且不越4KiB；axi_line_bridge读ID0/INCR/16B/4拍。端口0对应显示、端口1对应算法。它们的cancel/enable与错误/drained资格仍由各叶负责，本模块只忠实保留已提出的总线承诺。

## B 整体行为

RA01 只允许一个全局未完成读burst。相机写口独立，不在这里串行化；每拍128位并不因单在途变成每像素发命令。仲裁器不会把ARready与Rready捆成一条成功。

RA02 显示:算法按3:1机会分配：当双方持续提出有效AR，最多3个显示grant后一个算法grant。没有算法请求时显示可持续取数；显示额度耗尽保持0，有算法请求时下个可仲裁机会给算法。每次算法实际ARfire将额度恢复3。没有显示请求时立即选算法。公平是可用仲裁机会界，不是假定DDR几周期返回或宣称显示无欠载。

RA03 选择后完整49位AR锁存，物理ARvalid/body持续至真正ARfire；上游ARready仅在这个物理fire沿给获选客户端，不把内部锁存称物理接受。若enable下降，已经锁定AR及旧R必须继续兑现；只禁止新选择。获选上游必须维持valid/body，违约Q，已经对DDR公开的正文不撤销。

RA04 成功AR后登记唯一owner/原ID/预计拍数。Rvalid、128位数据、原RID/RESP/LAST只给owner，Rready来自owner；停顿不消耗拍数。正确数量/最后拍才正常解除owner。RRESP非OK原样交叶，物理尾正常可以排空，不自动把服务错误升级成未知归属。

RA05 wrongRID、早/晚LAST或没有owner却出现Rvalid均永久Q，不分配新AR。已有owner保持可见，继续按owner真实ready转交旧尾，但占用不因为错误LAST清掉，不能声称closed或重用身份。没有owner时不猜客户端、不消费未知R。没有收到返回则持续等待，不伪造超时成功。

正常例：双方请求→显示AR全正文锁定并长停→一次physicalfire→所有R实际交显示→正确末拍→继续机会；3次显示后算法。边界：AR锁定后disable仍兑现，完成尾后idle且不选新；零延迟R与AR同沿时本沿不消费R，DDR必须保持，下一沿owner已登记后再转交。错误例：算法四拍第三拍LAST即Q，后来尾到达不解除保留占用。

## C/D 连接及精确契约

MOD1 arbiter持49位ARholding、1bit选路、1bitowner/active、4bit原RID、9bitremaining、2bit显示额度和Q/原因；不复制图像或完整帧身份。MOD2 TB的总线slave只做可控协议刺激；MOD3 Python从真实事件审核来源、49/128全值、仲裁机会、拍数和Q。没有新增CDC、RAM或DSP要求，实际FF/LUT待MAP。

接口：clk/rst/enable；客户端二维packed数组[1:0] c_arvalid/c_arready、c_araddr[31:0]/c_arid[3:0]/c_arlen[7:0]/c_arsize[2:0]/c_arburst[1:0]；c_rvalid/c_rready/data128/id4/resp2/last；一个m_axi_同宽口；输出idle、occupied、quarantined、fault_reason3。生产默认ADDRESS_BYTES33=0x10000000。rst是平台可信共同冷复位的同步core信号，不能把未closed暖reset接它。

AR49={addr32,id4,len8,size3,burst2}。被选AR须ID2(端0)/ID0(端1)、SIZE4、BURST1、16B对齐、端0LEN<=63/端1LEN=3。先将LEN+1扩9，再左移4形成13位bytes；addr+bytes扩33检查<=ADDRESS_BYTES，低12+bytes扩13检查<=4096。不先窄化加法。非法选择Q，不对DDR提出它或给上游ready。双方都valid时先按额度选路，再检查字段；不可悄悄跳过坏请求伪称全系统正常。

AR保持需比较获选上游valid及完整49体；内部pending在physicalfire前的占用输出有效，active从ARfire至合法末Rfire。idle=!pending&&!active&&!Q，occupied=pending||active||Q，Q不能被写成闲。复位期间所有valid/ready无效。

固定顺序和相容：捕获选择→原正文保持→真正ARfire→owner/R路由→逐拍检查→正确尾释放。没有更改叶ID/长度、重新标记RID或吞RRESP。上游仍以自己的实际ARfire和Rfire账保留line/burst，本模块额外跟踪49位公开承诺而不宣称能关闭叶的业务引用。完整Origin/FrameRef授权在父lookup/fence，不能以ID2/0替代它。

## E 中文语句草图

E1 定义pending/selected/ar_hold、active/owner/expected_id/remaining、display_credit初值3、Q及首因。字段默认0；always_ff非阻塞，组合默认所有ready/valid0。

E2 当无pending/active/Q且enable、任一c_arvalid，按RA02计算choose；组合计算49体及33位end/13位page_end。该沿检查合格后存pending/selected/ar_hold，尚未给上游ready。不合格设置Q原因FIELD1。

E3 pending时m_AR来自ar_hold恒定；c_arready[selected]=m_arready，其他0。按沿前pending时刻检查上游valid/body（用case不等，X也违约），失败记Q原因STABILITY2且保留ar_hold承诺继续。physicalfire将pending清、active置1、owner=selected、expected_id=hold ID、remaining={0,LEN}+1；额度仅此沿更新，不按组合valid重复扣。

E4 active时只owner的c_Rvalid=m_Rvalid，两个数据/ID/RESP/LAST线可公共直连但valid隔离；m_Rready=c_Rready[owner]。每Rfire检查RID和LAST==(remaining==1)。首因RID3优先LAST4。合法非尾remaining减1；合法尾且原Q未置才active清。错误或已经Q保持active/remaining（错误尾不解除），继续转交后续旧尾；不会把RRESP错误改写数据或归属。

E5 无active而m_Rvalid出现记Q原因UNOWNED5，不消费。ARfire同沿可能出现尚未可消费的R，此时属于已锁AR的物理接受，不判无owner；只有无active且不存在pending&&m_ARready才是未知。不把master未握手AR期间的R当已授权。

E6 Q优先阻新选择，不能撤销pending AR或清active。enable只管新捕获；无反压时至少捕获沿、AR沿、R尾沿后再选下一条，低延迟投机不纳本版。safe冷rst清表是外部前置，不在业务disable中自动执行。

## F 语言、时间及资源

SV2009；49/128全值无隐式signed，9拍数可表达256而不把255+1回0；33地址、13页面算术；新状态单core100MHz正沿，无图像存储/CDC。时序初始纯同步rst；所有hold只blocking组合、nonblocking提交。给Questa负沿驱动、preedge记录fire、NBA后观察状态。Python用事件集合及独立整数检查，不复制内部寄存器更新函数。语句精简不作为面积/速度通过依据。

R数据不注册新级，所以AXI外部稳定性直接传递；实际双客户端与DDR的ready链须生产STA检查。MAP100MHz目标、Ti60F225/I3/speed/retiming0/seq_opt0，组件没有板引脚/PNR/STA/bit。机会公平不保证时钟暂停或DDR永不返回时仍满足期限。

## G/H 测试及双向追踪

T1 单源/双源正常，显示1..64拍、算法4拍、全49/full128和原ID/RESP；T2 双方连续及单源回切，3:1机会精确且无饥饿；T3 长AR停顿/长R停顿、气泡、零延迟R及valid/body保持；T4 disable在选前/AR停顿/R中/末拍，承诺继续、新选择停止；T5 16B/4KiB/256MiB边界及非法字段不physicalfire；T6 wrongRID/早LAST/晚LAST/UNOWNED/Q不释放和合法RRESP错误可正常尾闭合；T7 不同冷rst及每阶段恢复（仅可信共同排空测试）；T8 当前源compile/elab/fatal退出探针、独立事件audit、实际MAP并记录警告。

正常日志每沿记录enable、两源valid/ready/full49、physicalAR/R全部、两客户端R全部、Q/occupied/idle。Python独立选路和burst集合核对真正事件，数据期望按地址与beat数学byte图产生，错误刺激专账；不把被测RTL的计数写作唯一期望。故障测试不生成伪closed，冷reset明示场景编号及清账前提。

RA01/03→E1/2/3及AR49→T1/3/4/5；RA02→额度/choose→T2；RA04→owner/R/remaining→T1/3/6；RA05→Q/首因/占用→T5/6/7。每一新增符号反向对应这里，scripts/model/TB/工程承担T8源绑定、真实工具证据。

## I/J/K/L 门槛、恢复与范围

整体行为和边界、单仲裁职责、实际相邻端口与字段、完整语句/时间/错误占用、端到端走查、公平与外部时间界分别解释、计划和追踪齐全；本模块不依赖未定义DDR模型或理想closed来实现。保存读回呈现，v1冻结8输入，READY；按持续授权自行实施。理解验收待用户实际作答，不据文档假定理解。

修改资格/首因/输出保持/拍数或Q恢复须先短卡，失败尝试和原参考保留。组件通过后再接真实leaf/root和读写总仲裁，才能报告生产运行。单在途不是整机性能达标承诺，也不降低1080p、五基础六高阶、完整识别质量；实际期限不够则继续优化结构和调度。数据库/H0/硬件保持，最终bit之后停止硬件步骤。
