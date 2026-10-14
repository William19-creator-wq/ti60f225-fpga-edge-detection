# Canny存储：状态cache、工作队列与内存交接草图 v0.3

2026-10-04；TRACK4-CANNY-001局部附件，**LOCAL_DESIGN / NOT_APPROVED**。按[主稿](../../../planning/design-TRACK4-CANNY-001.md)B整体行为→C职责→D接口→E精确闭包阅读，再读本页存储细节；[窗口/流段v0.2](canny-window-sketches-v0.2.md)继续有效。本页定义候选结构与要求，未生成RTL、参考程序、功能脚本或testbench，所有业务测试未运行。

## 1. 整体边界与证据

分类fence后，状态cache是2bit状态图的唯一读写者；seed扫描、BFS邻居和最终导出均经过它。queue只保存已成对接纳的坐标，拥有head/tail/committed_tail、append银行、prefix及prefetch；C7拥有当前pop和邻居序号；C0拥有阶段/上下文/成功或作废判定。它们不能各自发布整机结果或回收源/结果槽。

本机[FRONTEND输入清单](../01_baseline/frontend-baseline-v1.json)绑定的EFX_RAM10模型SHA256为DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33。模型为1R1W，16bit×512/地址9bit，OUTPUT_REG=0也在读接受沿后更新数据、下一同步沿消费，RE=0保持；16bit写按两byte使能。本附件采用整字写和同址规避，不靠READ_FIRST碰撞语义，不清RAM数组。

[DDR实际源码笔记](../01_baseline/ddr-address-and-completion-evidence-v1.md)只证明原主设备格式及旧完成限制：外口128bit/地址32、按字节步进；旧bank_sw不检查B响应。下面内存服务契约不是受保护slave的已验证保证；真实2Gb模型/PHY、地址/lane/响应/校准和安全排空仍缺证据。

## 2. MC-M01：Canny需要的窄内存客户端合同

同core上升沿valid&ready，提出后payload保持。每个Canny读/写方向最多一个live请求，包含逻辑响应尚未消费的时间；组件在本地仲裁，分别保存read_owner/write_owner及其返回槽，不能用同一可覆写owner接两方向。组件自己的封口/结果响应不能占全局DDR锁等待queue或显示。以下字段是候选客户端格式，父完整句柄/配置端口仍在CN-B06。

| 通道/字段 | 位宽、单位与规则 |
|---|---|
| req_valid/ready | 各1bit；实际接受建立一个承诺 |
| op、region | op1：0读/1写；region3：0 CLASS、1 QUEUE、2 GRAD、3 EDGE，4…7非法；访问权限另由绑定grant检查 |
| byteaddr、nbeats | unsigned32字节地址；unsigned7实际拍数1…64，不是LEN编码；每拍16B，地址16B对齐且请求不跨4KiB |
| tag | unsigned16虚拟事务标签；绑定owner、当前job完整句柄/代次、区域、地址/拍数及阶段；不能直接接physical AXI ID4 |
| W数据 | valid/ready各1、data128、tag16、beat_index7、last1；按0…nbeats−1顺序，低地址对应低byte lane；全部16byte有效 |
| R数据 | valid/ready各1、data128、tag16、beat_index7、last1、error3；正常拍逐位有定义；错误不伪装数值0；数量/身份/last均核查 |
| completion | valid/ready、tag16、success1、drained1、error3、actual_beats7；actual_beats计该segment实际逻辑交付的W或R拍数，成功须等于nbeats；success只能在drained=1且所有规定物理响应/数量/身份正确时为1 |
| error3提议 | 0 NONE、1 ACCESS、2 RESP、3 COUNT_LAST、4 TAG、5 CALIBRATION、6 RESET_PROTOCOL、7 INTERNAL；编码待与MOD-05完整稿统一，不当作原IP返回码 |

tag占用从请求提出起保持到该segment物理终结、逻辑R/W/完成消息消费及该段pending/R暂存/W assembler借用归还；不等整个prefetch发布或queue bank回收，否则第一段会阻止后续段。整逻辑对象仍保留自己的上下文/存储至全部段结束。同tag不能同时绑定新请求，旧job未排空不能更换上下文。beat_index/last/actual_beats均为segment内，段间重新计数。地址加长度先扩33bit，权限/容量/溢出检查后才窄化。4KiB检查用足够宽的低12bit偏移+16×nbeats，≤4096才合法。整line/末拍padding须在grant内，但不增加逻辑像素或entry。

completion只回复已req_fire接受并登记的segment；ACCESS也先登记再合法拒绝，W不得在对应req_fire前提出。取消排空不得永久关闭已提出请求的接纳或合法拒绝。请求拒绝若尚未触及物理接口，可报告ACCESS失败且drained=1；合法B错误在可证明排空后也是失败且drained=1。未知tag/拍数、无响应或校准/安全复位问题若无法证明排空，则drained=0、隔离相应上下文；消费错误通知不能释放租约或重用tag。超时与epoch变化不能制造drained。

失败且drained=1的completion还须具有明确的segment_terminal语义，避免早ACCESS拒绝后客户端一直保持W而服务不再接收的死锁。此terminal有效期间，服务对该segment的Wready=0，客户端对其Rready=0，不再新增逻辑数据握手；只暂停该segment的逻辑拍，不停止尚未排空的物理R/W。terminal valid不依赖这些ready，actual_beats包含形成terminal同沿真实旧握手，之后与错误字段固定。completion_ready独立于剩余数据交付、claim/push和阶段成功。尚未接受的逻辑W/R仍保持至terminal实际握手，两侧在该沿共同作废这些逻辑拍，已grant本地RAM读照常capture后归还；只有此前真实物理承诺全部排空才能提出该terminal。drained=0通知没有这种终结权，也不释放tag/租约；正常成功路径仍要求全部逻辑W/R及物理响应结清。此候选早失败协议须与MOD-05完整端口统一，不能用逻辑撤销伪造物理排空。

写success需要同job后续读可见，或服务已执行必要排序；最后W不是成功证据。成功R completion在全部逻辑R拍消费后才终结该segment；失败按上述terminal或隔离处理，不等待永远不会交付的后缀。阶段fence另由C0向MOD-05提出，必须覆盖最后已接受的相关请求；其token/完整scope端口仍待CN-B05/06，不借本页虚构真实fence实现。

物理边界有两项阻塞：逻辑R可反压不能证明物理R可反压；无实际证明时，MOD-05须在AR前为整个请求预留接收容量，最大64×128=1KiB，多outstanding按总承诺核算。完整W数据可保留在不可变bank/linebuf内再逐拍组装，但物理W是否允许拍间气泡尚须验证；若服务先收完整W再发AW，最多1KiB缓冲及其端口资源另计。本页的40RAM预算没有包含这些服务缓冲。

## 3. SC-M01：状态cache布局与权限

| 表示 | 定义 |
|---|---|
| i/line/set/tag | i21=y×W+x，先验证x<W/y<H/i<N；line=i[20:8]13，set=i[12:8]5，tag=i[20:13]8 |
| word/slot | word=i[7:3]5；slot=i[2:0]3；一16bit字含8状态，slot状态在bit[2slot+1:2slot] |
| 数据组织 | 64B线×128，4way×32set；每way32set×32word=1024×16，拆两块512×16；共8 RAM10 |
| 物理地址 | RAMSEL=set[4]，RAMADDR={set[3:0],word[4:0]}9bit；DDR线地址class_base+(line<<6)，先扩宽line再移位/相加，不能在13bit内截断offset |
| 线到DDR拍 | word 8b+k对应beat b的第k个16bit段，b0…3/k0…7，低段在低地址 |

class_base64B对齐，物理grant至少ceil(N/256)×64B。分类writer须把全部物理padding写成00并纳入分类fence；padding不参与seed/BFS/计数。W6/H5的N30只有8B逻辑分类，但授权/初始化完整64B线；不把后226个padding状态当节点。64B整除4096，所以一条对齐line的4拍不会跨4KiB，这是地址推导而非IP测试。

元数据128×(tag8+valid/dirty/pin/busy)=1536bit，PLRU32×3=96bit；合计1632bit只是元数据。另有512bit linebuf（WB/FILL互斥）、旧/新字各16、entry32、单操作/单RAM pending/单事务/单结果记录、最多6个pin位置共48bit加数量、WB字计数6bit及拍计数3bit。完整上下文只保留一份；不把上述元数据当全部FF。

八块cache RAM均为READ_WIDTH=WRITE_WIDTH=16、OUTPUT_REG=0、同core正沿。本候选每沿最多发起一个RAM读或写，RE与整字WE不同时发；读时RADDREN有效，写时WADDREN/WCLKE有效、WE两个byte均使能，其余RAM使能0。“一个动作”允许捕获上沿结果并发起下一字读，因此WB可连续32字。读pending保存way/bank/address/目的及身份，在下一沿消费RDATA，捕获空间先预留；没有新读时RE=0。单操作且逐字重读，同字第二个更新必取前一个提交后的值，不预读多个旧邻居字。

## 4. SC-M02：cache状态与逐沿中文草图

操作入口为READ_STATE、CLAIM_STRONG、CLAIM_WEAK，带job/坐标/i/阶段/pop与邻居身份；同时最多一条操作及一条未交付结果。结果valid停顿保持，正常结果交付后才接下一操作。

| 状态/步骤 | 使用旧状态→提交/退出事件 |
|---|---|
| IDLE→LOOKUP | 接受并锁操作；比较set四way有效tag及busy，唯一hit取way并在业务读前pin，多重hit失败 |
| MISS_RESERVE | 选最低编号无效且未pin/busy的way，否则按树PLRU候选、受阻时循环way次序找合法victim；锁旧身份并置busy；无效/干净victim直接失效旧valid并进FILL，脏线进WB |
| WB_READ/DRAIN | 脏victim逐字读32次，下一沿捕获到linebuf；末pending未捕获不能发写请求 |
| WB_REQ/DATA/WAIT | 完整512bit快照后提4拍write；按0…3交付，停顿保持；保留linebuf/旧tag/RAM/busy到匹配完成；成功替换清dirty后继续FILL，成功FLUSH保留tag/valid、清dirty/busy并推进扫描，不进FILL；失败drained结清借用后作废释放，drained=0隔离 |
| FILL_REQ/RECV | WB成功后才失效旧valid；提4拍read，收齐并核查tag/error/index/last及completion后才安装 |
| FILL_INSTALL | 串行32沿整字写；无cancel/fatal时末字沿提交新tag/valid=1/dirty=0/busy=0并pin；cancel/fatal同末字沿则禁止valid发布，半线仍不可命中；下一沿才读业务字 |
| WORD_READ/CAPTURE | 发一次RE并记录pending；下一沿捕获旧16bit字，禁止把接受沿后新RDATA当该沿已可消费 |
| CHECK | READ只回状态；CLAIM_STRONG仅10准备claim、01不变，CLAIM_WEAK仅01准备claim、10为阶段错；00/11均不入队，操作与阶段不匹配先拒绝 |
| CLAIM_WAIT | 保持字/slot/entry/身份，等queue可靠容量；成对提交后进入REPLY；tail=N仍见新候选为一致性错 |
| REPLY/POP_RELEASE | 结果保持至交付；seed/导出释放临时借用，BFS pin保留到该pop全部邻居及claim结清后统一解除 |
| FLUSH_SCAN/FENCE | 无新业务、无活动pop/pin/未交付结果后扫128线，逐脏线WB；最后请求交付和完成后提供封口证据，再等阶段fence |
| ABORT_PRIVATE/DRAIN | job作废可撤销未握手私有操作，已提出内存请求/数据/响应继续结清；不能证明排空则QUARANTINED |

pin在hit确认或FILL完整安装时建立，首次访问本pop的新线才把set/way加到pin列表，同线不重复添加、数量≤6。seed/导出临时pin在结果交付后释放；BFS在当前pop全部邻居结果/claim/pending结清后统一解除。WB记录替换或FLUSH用途，正常完成按用途返回，不丢扫描位置。

PLRU初始化三个bit为0，每次hit或安装更新所选way路径为“另一支更旧”；pin/busy均排除victim。正常当前pop线ID跨度≤16<32，至多6线且不同线不落同set，所以单操作下没有合法victim应判元数据/阶段错误，而非等待本pop自行释放形成死锁。pin只约束本cache替换，不持全局内存锁。

命中claim无停顿示例：e0接操作，e1命中/pin，e2发RAM读，e3捕获，e4准备候选，e5原子提交，e6结果交付；下一操作最早e7。WB从e0读word0至e31读word31，e32捕获末字，最早e33提出完整写请求；FILL从f0写word0至f31写word31，f32最早业务读、f33捕获。只是条件设计推导。

## 5. SC-M03：原子claim、取消及最新版本

queue claim_ready须表示本沿已有OPEN bank、prefix已准备、端口可用、tail<N且能存完整entry。沿前claim_valid与ready及cache版本证明同时成立时，同沿写状态01/10→11（其余七状态保留）、queue写entry/tail+1、cache dirty=1并形成成功响应。不能先标11再等队列，也不能先入队再尝试写状态。

queue满时candidate字/新字/slot/坐标/阶段保持，不重复RE/WE，queue后台seal/组拍/B接收仍运行。同字下一操作重新读RAM，因此能看到最新11；重复像素不重复入队。若未来引入同字寄存器旁路或邻居批处理，应另补最新值/同沿规则并比较真实性能。

取消同沿若旧claim真实握手，cache整字WE与queue WE仍成对提交，父失败优先；不能一侧关WE、一侧tail已增加。未握手的私有claim通过两侧共同abort_private事件撤销；它只作废本job尚未承诺的内部操作，不能撤回MOD-05已提出valid或AW后的数据。正常保存状态的FLUSH与作废job的ABORT语义不同：ABORT无需主动WB所有未提出dirty，但已提出WB仍持完整linebuf至排空。

WB completion前不得复用linebuf；FILL未全部校验不写RAM，安装中取消可停止后续私有写并保持valid=0。新job仅在旧请求/逻辑响应/RAM pending/linebuf借用全部结清后，清valid/dirty/pin/busy及控制元数据，不清数据RAM；line tag没有base/代次，不能保留上job的valid。

## 6. Q-M01：queue银行、prefix与指针

append两块512×16并行成512×32，逻辑分两个256entry半bank；它们共享一读一写口。9bit RAM地址={bank1bit,slot8bit}。prefetch另两块512×16成512×32，与append独立，总计4 RAM10；32bit不是原生单块模式。

entry bit10:0=x11、bit21:11=y11、bit31:22=0，写后不可变；读后检查保留位及坐标合法再交付。head/tail/c=committed_tail各21bit，0≤head≤tail≤N、0≤c≤tail，非环形不回绕；head允许超过c。新增区间[c,tail)每项恰有一个银行owner，prefix副本不成为第二owner。地址乘4/对齐/差值先扩展，queue offset至少23bit，base相加检查32bit范围及grant。

新bank新增起点s=旧tail，物理起点b=4floor(s/4)，p=s−b为0…3。槽0…p−1保存同一旧拍prefix，新增entry占其余槽，容量256−p；真实终点e≤b+256。seal写范围[b,4ceil(e/4))至多256物理entry/1KiB/64拍。prefix和补零不增tail；不混用全局256对齐页的另一套容量公式。

至多96bit prefixcarry保存当前未完整16B拍的1…3真实entry、全局拍起点及数量，由push捕获而非DDR回读；tail进入4对齐时数量清零。partial seal后下一bank先按原值写prefix，再开放push；初始化时carry锁定且push_ready低。prefix可在旧B前移交，但后一个descriptor不能越过旧未提交区间发送。

每bank记录b/s/e、prefix-ready、OPEN/SEALED/承诺状态、descriptor及本地借用。push地址slot=旧tail−b，先检查slot<256；真实push同时更新e/tail和prefixcarry，prefix初始化不增加e/tail。满、seed结束或闭包结束触发seal；满bank最后push后的新tail作为冻结e，manual seal等当前claim结清。仅prefix而无新增项不发write。两个bank都封口而未回收时反压push，不保证无限DDR停顿下继续入队。

## 7. Q-M02：写descriptor、组拍与共享读口

正常一次只选一个最早逻辑descriptor，要求s=旧c。把物理16B拍范围按MC-M01的≤64拍及4KiB边界拆成最多2个请求；client自己提出各segment并保存tag/拍offset。只有全部segment的success/drained完成后才一次c=e，末W或第一段B不推进。

本页选择“每segment是一个MOD-05承诺”：取消后已提出valid或已接受segment继续完成，尚未提出的后续segment不再提出；整个逻辑descriptor作废且c不推进。这样不能把只完成第一segment称成整个descriptor成功。bank仍保留全部数据直到已承诺segment及本地借用结清；完整逻辑提交与安全失败排空分别记录。

完整burst数据保存在不可变bank/prefix中；W assembler以128bit寄存器每次收4个entry，尾部无效lane直接填零，不读未初始化槽。满拍valid停顿时data/tag/index/last保持，不再申请下一拍读。无需重复复制整个1KiB，但取消后assembler必须继续有独立读口并供应已承诺W。

append读口请求者为assembler和forward，轮转仲裁；持续同时可服务时各自在至多2个grant机会内获得一次。grant先预留返回寄存器空间并保存purpose/bank/global_index/assembler_lane，下一沿capture。占用含未capture的预留，不能只看pop_valid或已捕获lane数；四lane都已捕获/预留后，等当前W拍实际交付才再读。assembler输出满且W停顿时停止新读让forward进展；forward响应满则不申请新读，assembler继续。已有grant必须capture；取消forward可capture后丢弃，W用途继续组拍。

append写口供prefix初始化或push，二者互斥，prefix至多3次写后开放push。读仅对已存在entry，push写tail对应新槽；同bank同址读写禁止。RE=0保持RAM输出，停顿不保持上拍RE=1。cache claim停顿不能统一冻结queue writer、读capture及B接收。

bank成功回收须全部B成功、forward/assembler读均capture并归还、必要prefix已移交、没有仍引用其W的数据源。B不是本地借用ACK，head增长也不是回收证明。回收同沿不旁路重新分配，新bank写最早下一沿；失败时只在drained及本地借用结清后丢弃，无法证明则隔离。

## 8. Q-M03：pop、prefetch和旧提交范围

消费者无活动pop才领取下一entry。按旧head/c选择：head<c且命中prefetch有效范围则读其RAM；head<c未命中则prefetch；c≤head<tail则从唯一append owner forward。保存source/index，不因B推进c而改源。RAMcapture后形成稳定pop响应，只有消费者实际接受才head+1；请求发出或capture不增加head。head=tail且同沿push仍按旧状态判空，下一沿才能读取新entry。取消同沿真实pop握手仍登记；未握手pop通过queue/C7共同abort_private终结，已grant读仍capture归还。作废后禁止新pop/claim，head/tail/c仅诊断，不再以正常[c,tail)不变量授权读取；承诺/借用结清后才丢弃未承诺数据。

prefetch物理起点a=4floor(head/4)，一次至多512物理entry/2KiB；锁c_snapshot，有效区间[该次head,min(c_snapshot,a+512))，末拍padding不有效。按≤64拍及4KiB分成最多3个MC-M01请求，所有segment共用被冻结范围，总物理拍进度用8bit表示0…128。本段completion消费且本段序列化/pending清空后即可终结段live/tag并提出下一段，整个cache保持valid=0至全部完成。后来c增长不扩展旧valid_end，旧末拍新位置需重读或按当前来源forward，不能用旧零padding。

填充先失效cache并禁止读；单128bit R暂存接受一拍后用4次32bit RAM写序列化，未释放前不给下一逻辑R容量。beat_index/last在每个segment内从0重置；segment_offset以entry为单位，prefetch按segment_offset+4×beat_index+lane定位本次cache槽，slot9bit0…511，安装进度计数另用10bit表示0…512。所有segment success=1/drained=1/actual_beats=nbeats，全部R数据消费且最后本地写/pending清空后才发布valid范围，RLAST不能代替RAM安装。这个反压接口需要MOD-05物理R适配，不能直接接受保护controller。R错误/取消后消费并丢弃已承诺R，或按已证明排空的失败terminal终结；不等待缺失后缀、不停R后反等只在消费后才出现的成功completion；已grant本地读仍结清。

逐沿例：e0 claim写新entry k、tail=k+1，当沿不能pop新k；e1 forward grant、e2 capture、e3消费者接受才head+1。若e0按旧head=c选forward且同沿B把c提高，pending仍本地来源，银行等e1捕获再评估回收，最早e2重新分配。c_snapshot=1的cache只含index0有效；后来c=2时index1仍不能命中该旧拍。

## 9. MC-M02：阶段、终止与资源/性能反馈

分类先完整写N逻辑状态及物理padding、必需grad，再封口/fence；seed扫描全部强边逐次成对claim，银行满时后台writer运行。seed结束seal尾bank、flush脏状态、实际请求交付/响应完成再fence，要求c=tail才进入BFS。BFS仅claim01，残留10为错；当前pop所有合法八邻居结清才解除pin并接下一pop。

闭包终止须head=tail、无活动pop/邻居/claim/miss/pending；然后尾seal、dirty WB及全部请求排空/fence，才导出N边缘含0，再执行输出fence及必需grad租约汇合。初始empty、暂时queue空、最后W或count0不能单独触发成功。每点最多接纳一次、最多N pop/8N邻居检查，物理永久停顿属于隔离而非算法成功。

claim等queue时，queue writer/组拍/B/forward/prefetch及取消排空独立推进；pin不持总线锁，RD/FILL必须有预留捕获容量。源/结果正式回收仍经FM/JOIN，失败drained与未知隔离不能混用。后台最终服务、采集下一SOF期限及HDMI预取水位仍待MOD-05/11证明。

共享FE/Canny窗口/cache/queue候选仍40 RAM10；另明确cache linebuf512、元数据1632、pin列表/操作记录，queue carry96、W128、R128、pop32及范围/仲裁/pending。MOD-05 read/write缓冲和平台/显示/识别另计，未综合。

逐字直读、单操作cache是本批明确的候选基线，hit claim到结果为e0…e6，下一请求最早e7，不能沿用“每邻居一拍”的165.888ms作为实际延迟。后续需比较同字最新值旁路、按行/word归组邻居、连续seed/导出扫描、16B/64B缓存、queue forward及后台服务；保持精确闭包，不以截断链或固定迭代换速度。性能最大化仍在CN-B08，当前未声称此串行结构最优或处理fps达标。

## 10. 验证、追踪和未完成项

| 新文字TEST | 要求/步骤与预期，全部未运行 |
|---|---|
| CN-T19 | CN-06/07；SC-M01/02/03：i7/8、255/256、4095/4096、N−1/N；同字更新、WB/FILL/安装反压、pin/victim、半线取消、class padding00；映射/最新11/整线权限正确 |
| CN-T20 | CN-07；Q-M01/02/03：prefix0…3、256−p容量、4KiB拆段、B与forward同沿、旧cache padding、两bank满与writer读仲裁；c连续前缀、借用归还后回收 |
| CN-T21 | CN-07/08/09；MC-M01：16B对齐/1…64拍/4KiB/地址溢出，虚拟tag/physical ID、R/W保持、completion及早fence；真实MOD-05/2Gb PHY另作整机门槛，不用行为服务代替 |
| CN-T22 | CN-06/08/09；全部步骤：queue满时cache等候、cancel与claim同沿、取消在各segment提出前后、forward后B错、旧job未排空；成对提交，失效job不发布，drained/隔离和新job元数据隔离正确 |

CN-06/07→state_cache/work_queue/hysteresis→IF05/06→SC-M/Q-M→INV04…07→T09/10/19/20/22；CN-08/09→IF07/08→MC-M及flush/abort→INV08…10→T12/13/21/22。核心符号均为计划，实际实现/测试待批准；修改端口、partial、claim、fence或取消必须同步本页/主稿及这些文字场景。

CN-B03/04获得具体RAM/FSM/组合输入，仍需完整父端口及基线统一。CN-B05真实服务/PHY及可见性、CN-B06 job/status/阶段/原因优先级、CN-B07地址/租约、CN-B08真实性能/资源与质量仍BLOCKING。本稿不能因有限状态表齐全而READY；原FRONTEND v1/28项输入、FM v0.1、窗口v0.2和原资料保持不变。
