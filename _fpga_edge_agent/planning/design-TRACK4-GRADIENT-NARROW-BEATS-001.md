# TRACK4-GRADIENT-NARROW-BEATS-001 v1

2026-10-12；按 PLAN_TEMPLATE 的小变更卡合并必要章节。当前 READY_FOR_REVIEW，根 Agent 实际读回、呈现后，在用户“当你统计完后自行进行，无需我的批准”及继续整机整合的持续授权内实施；没有新造逐版人工批准。沿用本批本地审计例外，正式数据库、硬件状态及原始资料只读。没有新增测试、仿真、安装、网络或硬件操作。

## A. 范围、基线与目的

Goal / Target：仅把板级共用 GRAD/POINT/SEED/LINE/CIRC 打包缓存及其写出改为窄 RAM 拍读取，保留全部字节和实际 AXI AW/W/B 关闭条件。Current / Gap：063综合成功，但70827/60800容量失败；GRAD缓存26 RAM10，实际资源归属2879 LUT，写服务2419 LUT，优化归属可能移动，不能预报节省10027或保证本卡使整机通过。

六份唯一拟改输入均在 work/active/track4_board_first_20261011，063冻结源不改：

| 文件 | 修改前 SHA256 |
|---|---|
| board/rtl/board_gradient_store.sv | 6AD8388D53348025F6CAECEFB4441F22954284A383B934F14655D7F2B5C381B9 |
| board/rtl/board_algorithm_rpc.sv | BBDFF528202B579C5146C215B86C0AECF7DFBD0BA7C80ACEFD713BC6C3257282 |
| board/rtl/board_frame_system.sv | CF6A1C784089256E297EE19A92BDD2B848F6940E75E4C57D1B1FB8ACB330EFC3 |
| algorithm/rtl/frame_actors_axi.sv | FA665687265594EC303FF110EA6F777D95133007753679344975657A032ED352 |
| algorithm/rtl/video_memory_hub.sv | 09BBD992D9EBADB8519B73EBE6B664CE9F4E7E1F9244E061C061FBFBC55C669E |
| algorithm/services/axi_write_pair_service.sv | 61400FC9C7ED03A10D99CDCD8F063250C40E5A046F3AE98574FB2EC9DE8B5F10 |

依赖：现桥 write_beat_index、m_axi_awvalid、m_axi_wvalid/ready/last，原唯一写源锁及 GRAD 完整八字发布契约。实际读过本机 sim_models/verilog/efx_ram10.v：合法最大读/写宽20、16等，没有32/40；采用八块16/16 RAM，不凭假设设置32/40。Ti60、90.909MHz、1920×1080、DDR范围、引脚/SDC、全部识别路线不变。完整矩形、最终标注、容量/速度证明尚未完成，均不由本卡冒称关闭。

## B/C. 整体行为与连接

NB01：八次接受的64bit顺序正文组成同一64B；低地址先原第1字，四拍分别字0/1、2/3、4/5、6/7。NB02：AW/W拍事件和背压不增加、不改变；最后W不是成功，保持来源到真实drained响应，UNKNOWN/隔离不释放。NB03：默认profile保持原实现；只有板端开启新profile，旧通用快照/多热逻辑不改变。

`各原pack生产者 → GRAD缓存八×16 RAM → 当前128bit拍 → RPC → actors → hub → write_service → 原桥/DDR`。
`原桥当前拍/真实W接受 → write_service预取拍号 → hub → actors → RPC → GRAD同步RAM读地址`。

IF01：GRAD新增 input beat_prefetch_index[1:0]，output req_data_beat[127:0]；RPC新增对应input/output，actors内连128bit/2bit，hub/service新增相同端口。NB04参数 NARROW_BEAT_PACK/GRADIENT_BEAT_WRITE 默认0，板端1；service仅当原EXCLUSIVE_PROFILE且NB04时启用，actors将“启用NB04且FLAT/BORROW/EXCLUSIVE全成立”的同一有效常量同时传RPC和hub，避免一边0一边1。原ONEHOT_EXCLUSIVE_BEATS可0/1，NB04自己的二级选择树不依赖它。GRAD新结构仅NB04且RAM_PACK/ORDERED_PACK全1。

IF02：预取地址在AW为0；W实际接受且非末拍为旧beat+1；其余为旧beat。RAM正沿同步读取该地址，OUTPUT_REG=0。AW交付沿后读出拍0、桥同沿进入W；非末W接受沿后读出下一拍、桥同沿更新beat；W停顿时地址保持当前，数据不变。ready→读地址→RAM寄存输出不形成组合ready/valid回路。摄像头或其它写源活跃时RAM可以读不同地址，GRAD未被选中，无输出副作用。源5表示GRAD，服务只对锁源5选择req_data_beat；源0…4原512正文各先选自己的128切片，再按锁源合并，不跨源取错拍。

完整512端口在NB04物理profile恒0，只保留仿真 translate_off 的顺序镜像用于原接受前known检查；镜像不承担真实W。它在reset隔离，在每次完整八字后等于原移位缓存。仿真语言X/Z检查仍用真实整块镜像，未选择来源不影响检查。生产请求前全八字已齐；不能依据半块或未接受pack发布。同步复位在途作废，旧RAM不清零，后续完整八字重建有效数据。没有新的CDC或NUM接口。

## D/E/F. 局部操作与语言契约

GRAD拥有一个3bit写槽计数，仅真实stage_write推进模8；rst及新start接受时归0。偶数槽给低64 bank，奇数槽给高64 bank；每bank四块RAM16，各存一字的固定16bit条带，RAM写地址slot[2:1]（0…3），读地址预取拍（0…3）。写使能按slot[0]分bank，8块Q固定拼接128。用实际写入次序而非point_pack_index，保持ORDERED_PACK原“按到达次序”语义。只在完整八字请求有效；原FILL/REQUEST/RESPONSE/COMPLETE、计数/地址/身份/错误判断原样保留。不能同时改同一已接受GRAD写块；原父直到真实响应归还才允许下一pack。RAM模式READ_UNKNOWN：发布前pack可能读写同址，Q未发布；AW/W阶段没有stage_write，读拍不会碰撞。

service新分支：源0…4各根据原桥beat选择固定128；精确case的非法/X/Z拍号全零；精确case锁源0…5各独占OR/选择，非法/X/Z源全零；源5只用已同步的128bit GRAD Q。原flat mask检查、selected_data仿真检查、camera额度、owner锁、真实B/error/drained、隔离保持及桥全部不改。新增预取线始终以真实桥AXI信号计算；default未连接它也不影响旧行为。

数值全部bit保留，无signed/舍入/截断；槽和拍2/3bit只在已定模范围内推进。全core正沿，组合blocking、寄存器nonblocking。RAM八×512×16物理块，仅4项/bank有效；逻辑正文512bit，Q128bit，不引入512FF物理镜像或新DSP。结构预算由26 RAM降8（18块），另3FF/小译码，LUT和packing收益未知。其他源128切片复用新树可能改善面积，也可能被mapper重归属；只能真实测量。C++/跨语言N/A，本卡纯RTL结构改动。

正常走查：字0…7接受→槽0…7写完→请求→AW等待/交付读0→W0真实接受预取1→W1/2/3→真实B→drained回复消费→下一块。边界：W1停顿N沿读址1/Q不变；最后W只进入B；B错误仍原真实关闭/错误，UNKNOWN不重填缓存。reset在半块令有效状态作废，后续完整八字覆盖全部槽，半块不成功发布。WORD7最后写和AW最早隔至少请求接受及AW沿，避免发布前READ_UNKNOWN碰撞。

## G/H/I. 实施、检查与追踪

先读回/呈现本卡→候选保存六份before→六份最小修改/实际diff→根读回改动与逐沿检查→采用主包→新064完整EDA，不reuse mapping。原031交付、063输入、工程XML/引脚/SDC/IP不改；失败保留064日志，不重复无依据配方编译。

文字检查（不新增TB/独立测试）：T01四拍字节/仿真镜像→NB01/GRAD银行拼接；T02AW长停顿、W0…3独立停顿/最后W/B错误/UNKNOWN→NB02/IF02/service旧状态；T03默认参数和NB04相容常量/所有named连接→NB03/actors/hub/RPC；T04冷复位半块后全8重填→NB01/槽归0；T05真实综合/packing/布线/最终STA/bit注册→资源与交付，仅实际运行才填PASS。反向：新RAM块、写槽、预取线为NB01/02；唯一source5分支为NB01/03；其余仅参数/端口传递，不顺带改业务。

①行为/样例②职责连接③接口相容④状态与短操作⑤位宽/采样/背压/RAM⑥正常和错误走查⑦实施/验证/追踪⑧当前限定增量无未知阻塞⑨落盘后须实际读回呈现⑩六输入hash/version范围已明确。不会把设计自检当仿真通过或指定版本human APPROVED。

## J/K/L. 恢复与记录

本卡改变内部RAM组织和新增仅内部预取端口，先修设计后实施。退回六份before即可复原063主包；保留全部历史产物/事件，不修改原资料。新bit仅全EDA/最终setup与hold通过且输入hash一致后staging登记，仍WAITING_HUMAN_PROGRAM，硬件初测未执行。K实际代码/diff/hash/EDA结果待记录；理解验收未检验。
