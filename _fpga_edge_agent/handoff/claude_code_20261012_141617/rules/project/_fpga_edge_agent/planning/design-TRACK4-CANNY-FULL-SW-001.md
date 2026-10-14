# TRACK4-CANNY-FULL-SW-001 v1：RGB到完整Canny外存结果

2026-10-08。沿用用户“当你统計完后自行进行, 无需我的批准”及本地审计例外；代码在新work/canny_full_sw副本。已登记包/原HDK/正式DB/硬件不改。按整体→局部→交接→内部旧状态草图读回READY后自主实现。

Goal：把R1/R2真实灰度/中值/高斯/Sobel/方向/NMS/双阈值流与实际cache+queue滞后组合，逐像素完成完整Canny，写入可显示的8bit私有结果帧。Current：R2流段和滞后内存组件分别已验证，真实RAM组合小图已通过，1080p组合进行中。Target：RGB双像素入口，完整96bit任务scope，授权三外存区，全部计算/写回/排空后固定done；独立完整二维数学+BFS比对。Gap：分类帧packer/结果packer/外层生命周期/组合TB/资源物理；摄像头CSI、帧发布及显示另闭合。Assumptions：W/H固定完整1080p上限，无质量/目标数降级；两个内部64bit子任务handle与96bit完整scope一对一，原ID不截断；外存提供64B原子RPC。Open questions：单元软件边界明确，真实DDR仍需物理桥及器件模型验证。

Milestones/Detailed steps：设计→packer→生命周期及仲裁→独立数学参考→小图正常/错误→1080p→组件综合→帧服务/实际物理。State transitions：设计保存读回READY→持续授权实现→实际日志登记。Artifacts：work/active/track4_algorithms_20261004/canny_full_sw。Validation：FC-T01…08。Failure：安全error作废私有输出，已公开RPC不撤；未知drain隔离，不发布帧。Human gates：无硬件操作。Rollback：保留所有尝试和输入版本。Completion：完整数学/内存结果一致、取消/错误闭合、实测资源时间；生产整机验证另项。

## A—C 整体路线及模块

接受CJ142和class_base/queue_base/result_base后，锁完整CJ和96bit scope，给分类writer配置，再启动原R2。输入仍原FP74（RGB48/x11/y11/SOF/EOL/EOF/bad）。R2 class125输出直接给class_frame_writer；若保留梯度，原grad185仍提供外口，所有保留梯度也须真实交付才完成R2。class writer用512bit私有累加槽每256像素封存64B，末块padding补零；最后块真实RPC完成才writer done。

同时保存R2完整CS592，核CJ/原因/FE状态/八段真实计数。仅R2成功、分类writer成功且排空才启动canny_memory_top。实际cache和queue进行强点scan/八邻域滞后并导出N边缘。edge_frame_writer把edge=0/1分别写成灰度0/255，每64像素64B；cache/queue关闭且结果writer最后写回排空之后才外done。result_base始终是私有结果，帧服务必须收到成功done再发布，不能凭最后像素到达发布。

模块职责：class_frame_writer检查scope/坐标/marker/类别并pack2bits；edge_frame_writer检查64bit子handle/index并pack灰度8bit；canny_full_top保存生命周期、96bit身份映射、三授权区检查、取消与错误；复用line_rpc_arbiter2将当前阶段的writer口与memory_top口共用唯一外存口；不更改R2/cache/queue原数学。

局部复用：两writer共同的512bit累计/RPC/关闭语句放在packed_frame_line_sink，参数ITEM_BITS=4或8、ITEMS=N/2或N、ID_BITS=96或64；两个wrapper只负责各自metadata及输入data映射。每次实例只有一份实际持有的累加槽，语义同下方writer草图，避免重复维护两个相同生命周期。

## D 接口和交接

外部cj_valid/ready/cj142、三base32，in_valid/ready/in_fp74，grad_valid/ready/grad185，cancel_valid/cancel_scope96，done_valid/ready/done_scope96/outcome2/reason32/input_pairs21/class_pairs21/output_pixels22/edge_pixels22、line RPC512及quarantined。握手锁住所有配置；held done不改变。子handle是计数分配的完整64bit（不是切CJ低64位），只用于同一active scope的内层cache/queue；映射直到终结消费才释放，计数不绕回复用。

三授权大小：class ceil(N/256)×64B、queue ceil(N/16)×64B、result ceil(N/64)×64B，各64B对齐/33bit终点≤2^32且互不重叠。CJ W/H必须等固定W/H，0≤TL≤TH≤2047；不合法配置直接稳定error done、零访存。结果像素格式为连续8bit行优先灰度，不改变边缘数学精度。外部grad分支保持完整原96bit元信息。

class metadata125由低到高是pair4、x11、y11、ID96、SOF/EOL/EOF3。接受时与writer旧q/row/fullscope比对；每类只允许0/1/2。class=3是协议错误，不能当已认领状态输入。writer累加位偏移采用本块pair号×4，整块128对/末对时封512；最后端点只补零，无随机旧RAM读。edge用index21直接核旧count，ID核子handle；本块slot×8置0/255，64项/末项封存。

两writer均：配置握手/回执，stream valid/ready，独立64B RPC，结束valid/ready/error/aborted/drained/count。共同私有abort只清尚未公开的累加槽；公开RPC REQUEST/WAIT保持到终结。正常done只在最后RPC安全完成时发布；未知drain进入隔离而不伪造done。held done不能被后来abort重写。

R2取消属于整体私有流水线共同关闭；class/grad未消费的私有槽由原R2 data_flush处理，已消费前缀已记录。外层通知source_stop，输入生产者停止该私有job并按帧服务终结，不能把下一帧塞入旧job；公开外存RPC仍不可撤。原R2独立协议测试保持。内层HY增加的aborted诊断已匹配cancel才接受，不以假数值stub隐藏取消。

## E 中文内部草图及旧状态

writer状态IDLE/CFG_REPLY/ACCEPT/REQUEST/WAIT/DONE/QUARANTINE。配置保存base/ID并清count/buffer，ACCEPT每个实际stream fire核旧expected，合法后写旧slot并count增；整块/末项把本拍更新后的buffer冻结公开REQUEST。REQUEST外口接受后WAIT，真实response drained1且error0继续下一块或终结；drained0隔离；真实error优先cancel。取消ACCEPT可直接aborted done，取消REQUEST/WAIT必须先排空。done固定直到consume，配置ready只在旧done消费后的IDLE。所有地址先33bit、与已核范围一致；最后像素同沿累加要使用显式next_buffer，不发送少一个末项的旧buffer。

top状态IDLE/CFG_CLASS/WAIT/START_R2/RUN_R2/WAIT_CLASS/START_RESULT/WAIT_RESULT/START_HY/RUN_HY/FINAL/DONE。保存full CJ/handle/bases/cancel/error/各子终结槽。R2 status与class writer done独立接收并保存，不能假定先后；两个都成功才启动HY。先配result writer、再启动HY，确保第一pixel有接收者。HY done与result writer done也分别保存，两个都安全终结后形成固定外done。cancel在R2阶段广播R2/classwriter，在HY阶段广播HY/edgewriter；还没启动的模块不生成空job假完成。过渡时已有配置请求保持；已配置但cancel未启动流也让writer用abort关闭。error使其它私有兄弟共同取消，但自己的真实error保留优先级；unknown阻止新job及成功done。

RPC口选择仅在前一阶段writer done已实际消费且drained、R2槽关闭之后切到HY/result阶段；两个writer不会同时拥有口。line_rpc_arbiter2保存请求owner，外层不在live期间换角色；阶段结束必查全局arbiter回IDLE。数学组件端口不改，源码加入前冻结hash。

## F—H 验证与追踪

FC-T01：小图二维独立RGB→gray/median→高斯→Sobel/方向→NMS/双阈值→BFS；比较实际写回分类、最终3状态、queue BFS顺序、最终灰度帧和保留梯度。T02：全零/阶跃/斜线/圆矩形边界/随机、median开关、retain开关、TL=TH/0/2047，连续scope不能交叉。T03：writer256/64/末项padding及配置非法/marker错误/类别3/index错/错ID/请求反压/取消各阶段/真实error/unknown。T04：完整1080p参考和耗时，不预称FPS。T05：R2和HYstatus先后、末data/B等价回执不提前发布、held done。T06：实际组件RAM/FF/LUT/DSP预算及后续生产PNR/时序。T07：帧服务/冻结/恢复/生产显示集成。T08：真实DDR/摄像头/HDMI/全部十一项最终验证。

追踪FC01整体→top生命周期→T01/04/05；FC02数据布局→两writer→T01/02/03；FC03完整scope/三授权→top/payload校验→T02/03；FC04取消及真实关闭→writer/top/原memory组件→T03/05。正常/边界/错误路径已经按上述旧状态走查；实现及实际测试结果单独记录，功能与中文可读性验收分开。用户质量要求不变，后续吞吐和资源优化依据实际值。
