# 实际采集、完整 Canny 与显示读取的公共读写链路

当前设计：TRACK4-CAPTURE-DISPLAY-HUB-001 v1.4，含 J1、K1、T3、J2 修订。58份冻结输入；45份原样运行依赖；10份自写源码/验证/工程文件；仿真52份源，MAP55份源/工程。这里的文件数不表示完成模块数或整机百分比。

## 1. 先看整体

本组件把真实 RAW10 双像素输入交给实际去马赛克/RGB源写回，再从实际内存读回，经过灰度、中值可选、高斯、Sobel/方向、非极大值抑制、双阈值、BFS滞后连接，写出完整边缘图。与此同时，显示 span 客户端读取另一份不可变、已经获准的旧 Source。两个读客户端共享一个真实 AR/R 口；camera和Canny的写请求共享一个真实 AW/W/B 口。读口和写口可以各有一笔物理事务在途。

```text
RAW20 ── 实际色彩流水线 ── RGB源writer ── camera64B写 ── write-pair ── AW/W/B
                                     ↓ 内存Source      ↑ Canny64B写
实际RGB reader ── FP74 ── 完整Canny ── algorithm RPC ── 方向锁
    ↑ Source64B读                         ↓ 算法64B读
    └──────────────────────────────── read-pair ── AR/R
不可变旧Source授权 ── display span ──────────↑    ↓
                                       display128数据/终态
```

测试中的 DDR byte slave 只提供数学内存和独立物理事务，所有R数据来自初始化字节或真实W写入。它不是真实 DDR3 PHY，也没有代替 CSI、FrameRef 授权、HDMI扫描或总发送器。

## 2. 再看接口交接

camera只写：addr32/data512，加req_valid/ready与rsp_valid/ready/error/drained。algorithm是64B混合读写：额外write1和rdata512，hub仅在真实请求接纳时锁方向。显示是16..8192B、16B对齐span：addr32/bytes14；回传data128和outcome/reason/drained终态。实际显示leaf负责每段最多64拍、4KiB边界分割。

valid与ready在同一正沿同时为1才交接。已公开请求、数据或终态在停顿时保持所有正文。全局隔离Q禁止三个新应用请求；已承诺的物理尾部和旧通知继续。真实axi_enable与另一路出错隔离分开处理，不能通过把enable关掉污染本来安全的旧回执。

error与drained分开：错误但drained=1表示本次实际事务安全收尾；drained=0表示归属不确定。UNKNOWN通知被消费后，算法方向锁仍保持，不能因物理idle或通知消费就复用。测试恢复只允许hub与数学slave共同可信cold reset。

## 3. 最后看三个局部RTL

`capture_canny_rpc.sv`：保留既有实际采集/reader/Canny父控制。RAW采集必须完成且RX close身份匹配/good才启动读回和Canny。reader与Canny进入一个实际line_rpc_arbiter2；camera独立写出。J1允许无关显示故障发生时已经公开的safe完整DONE继续保持，但下一job仍受全局Q阻止。

K1分清两级返回：hub的algorithm_rdata/error/drained进入仲裁器的line_*输入；仲裁器把真实回复保存到client_rdata/error/drained，再以锁定客户端的rsp_valid交付。两个阶段不能共接驱动线，也不能让客户端在回执停顿时追随新的物理返回。原仲裁器已有回执寄存器，此处只增加明确连线。

`video_memory_hub.sv`：只新增algorithm_active、locked_write和direction_quarantined三个FF。接纳事件锁方向，回复消费且drained=1清active，UNKNOWN保留active。camera→实际write服务端0，算法写→端1；算法读→实际read line，display→实际span。旧RSP/data/DONE及AXI信号直连，不按新请求资格撤销。

`capture_display_axi.sv`：显式连接上述两模块及所有公共端口。producer_local_quarantined仅来自采集父自身子模块和寄存状态；memory_quarantined另输入父控制，避免隔离信号的组合反馈环。

## 4. 验证顺序与独立参考

先冻结输入并复制45份实际RTL/native RAM/数学参考依赖，再生成10份自写文件。每个run先复制52份源并记录SHA，生成独立RAW/CFA/R2/BFS结果；compile/elaborate；用真正的fatal探针证明错误会使退出失败；运行33类独立hub场景；运行实际采集/Canny与两遍显示；最后两套独立审计及当前源/快照哈希检查。

`tb_capture_display_axi.sv`只通过actual reader/core的公开端口绑定观察FP/RPC；不读取DUT内部数组或私有状态作为期望。完整Source、class第一次物理写、最终class/BFS状态、队列顺序、边缘结果、FP、梯度、status、Origin和两遍display字节均核对。物理总线账核对所有AW/W/B/AR/R的身份、完整正文、范围及字节效果。

`tb_video_memory_hub_protocol`位于`tb/axi128_duplex_byte_memory.sv`，33类包括方向锁/停顿、16camera+12algorithm写压力与8192显示span、非法地址/span、取消、BRESP/RRESP、错误BID/RID/LAST、真实enable失效、跨方向Q旧safe回复、Q后旧span分段、四态负样本和共同cold。`hub-public.tsv`保存全部公开端口逐沿账；Python由accepted请求和实际物理事务独立重建内存、归属、回执和保持，不按TB的PASS字段自证。

当前验证记录：

|运行|实际图像/采集协议|独立hub|实际采集周期|状态|
|---|---:|---:|---:|---|
|capture_display_small_005，34×19|20图/18类|33类|401750|当前源仿真及两套独立审计PASS|
|capture_display_min_002，6×5|20图/18类|33类|33824|当前源仿真及两套独立审计PASS|
|capture_display_hd_001，1920×1080|1完整生产图|33类|38474363|真实仿真退出0，旧审计FAIL保留|
|capture_display_hd_reaudit_001|复用上述1图真实仿真|33类|同上|当前独立完整审计PASS，50执行/数学输入相同|
|capture_display_map_001|小图/边界同版本|不适用|不适用|组件综合退出0|
|capture_display_map_002|当前HD审计恢复52源/55工程绑定|不适用|不适用|组件综合退出0，55份当前源/快照SHA一致|

HD核对2073600像素、完整6220800字节新RGB Source及12441600字节两遍旧Source显示；138846AW/555384W/138846B、114544算法AR/13670显示AR/1235776R；真实同源1078边缘像素。完整job为38474342周期（总运行另含cold与终态停顿），这属于该数学slave调度的周期测量，不是实际DDR或整机FPS。

J2恢复明确保留原始HD执行出处：另50份RTL/TB/native RAM/六参考逐份SHA相同，模型imports和生成函数前缀逐字相同，仅独立审计与运行组织更新。新run复制完整字节/向量/公共账并核SHA，重新执行完整独立审计，原HD_001 FAIL不重写；没有将审计重放说成重新仿真。逐沿前后公开归属重建确认480211个具有记录的双归属沿前证据，6699算法/显示读竞争周期。

当前map_002真实网表与报告数目一致：27515 LUT4、21229 FF、1899 ADD、46 RAM10、166 SRL8、0 DSP，与保留的map_001资源相同。当前网表SHA256为14EF5C7DA8E4CCC3C90F18BC54009441485570F12640956D8538ED761185922E，报告SHA256为F791C6252658E9E1E71FCF0E98C0D813792911881B94AC5946F9D2129EF4DF0F。83警告包括20移除冗余信号/循环变量/写端不用的rdata，63小数组、异步元数据或固定访问数组映入逻辑；日志保留。RTL方向四态guard在两态综合中消除，hub局部方向/active保留2FF；不能把该guard声称为物理未知态检测。100MHz是分析约束，物理时序尚未验证。

6×5仅用于边界验证，生产默认仍1920×1080。小图两次都观察到真正的读写并行和算法/显示读竞争。33类公共账重建38AW/152W/40B/34AR/1077R，22camera、33algorithm和10span接纳；含3错误BID、2错误RID、3错误LAST，Q后旧span有8次后续AR，两个方向在途reset各1次。

## 5. 从软件重新运行

使用已有英文Work入口，以独立RunId保留旧证据。PowerShell 7执行`scripts/run_capture_sim.ps1`：正常小图指定`-RunId <新名称> -Protocol`；边界增加`-TestWidth 6 -TestHeight 5`；生产尺寸指定`-TestWidth 1920 -TestHeight 1080 -Full`。每次自动执行独立hub T3，`-Protocol`另外选择实际采集父的18类场景。不得用全局WIDTH参数覆盖vendor RAM参数。

只有独立审计/组织修订且已有真实仿真全部正常结束时，才可另加`-ReuseSimulationRun <原run>`恢复。脚本检查9个已终止阶段/日志SHA、50份不变源、生成前缀、尺寸/协议及两个finished指标，复制原记录到新attempt，写清simulation-reuse关系，再独立审计。RTL/TB/native/数学依赖有变化、原仿真失败或仍运行、日志缺失、发生timeout时一律拒绝复用。

实际HD仿真及两套审计成功后，执行`scripts/run_capture_map.ps1 -RunId <新名称> -SimulationRun <已PASS且源码仍相同的HD名称>`。脚本使用现有Efinity，生成独立flow/snapshot及真实PID、退出、日志、SHA记录。工程`project/capture_display_axi_component.xml`设Ti60F225/I3和100MHz分析时钟；41份可综合RTL，不把数学slave/observer/vendor仿真模型加进综合源。

MAP工程没有生产板IO，所以本组件的综合通过不能证明板级引脚、CDC、布局布线、STA或最终bit。Efinity GUI不能直接使用含中文的工程路径，应使用已有`C:/Users/34528/FPGAEdgeLinks/Work/...`入口。

## 6. 追踪与失败保留

整体DH01→真实core→正常同源图/生产HD/RX及输入异常；DH02→实际span及AR/R→两遍display全部字节/8192和4KiB场景；DH03→方向FF与实际读写服务→T3方向、压力、真实duplex；DH04/05→旧通知直连/新请求资格/localQ边界→跨方向Q和既成DONE；DH06→范围/四态/共同cold→非法参数及恢复。源码职责注释及详细中文语句以v1、J1、K1、T3、J2设计卡为准。

small_001因新core回执接线双驱动失败，K1分线修复；small_003仿真均通过，但独立检查器错误地要求第一次reset正沿前FF诊断已初始化，审计失败，随后按原reset契约修正。hub_audit_recovery_001只证明对保留公共账的审计修复；当前small_004/min_001重新生成/编译/仿真/审计，不能把旧失败run改为PASS。所有旧日志、源码快照、设计版本和失败目录保留。

HD_001旧审计在B完成同沿的OVERLAP判断失败；J2用真实公共账的沿前/沿后归属检查保持严格因果。完整R/W正文、范围/身份/字节效果和所有数值核对不删。当前small_005/min_002完全重新执行，HD_reaudit_001严格复用未变的真实执行证据后重新独立审计。

复用拒绝路径也已实际运行：reuse_reject_failed_sim_001拒绝原仿真失败；reuse_reject_changed_tb_001拒绝旧RTL/TB依赖改变；reuse_reject_geometry_001拒绝尺寸不匹配。三次均在启动HDL工具前拒绝，没有产生阶段start记录；原成功/失败证据均保留，汇总见reuse-guard-validation.json。

## 7. 整包仍须完成

本组件之外：生产FrameRef/只读授权及Source/Result发布、Freeze/Offer/Apply/Retire；真实显示scan/HDMI链路接入及持续供数/QoS；CSI错误/RX close/不可暂停输入；匹配板载2Gb/x16 DDR3的动态时序验证；原完整复杂识别算法；STATS共享FIT与单Ti60资源/帧率架构；完整生产顶层、引脚/时钟/CDC、PNR/STA和最终比特流。全部目标保持ACTIVE，正式数据库/H0及硬件状态未改，未执行硬件编程或观察代签。

已记录具体下一交接缺口：frame_owner/display_row_reader使用1bit EDGE，当前实际Canny结果为8bit/pixel；Source描述A16在小图与writer物理A64也有差别。完整HD对齐恰好相同，不能据此忽略参数边界。后续需显式设计生产1bit结果sink/A64授予及真实显示读回，原登记8bit组件仍保留；本包未实现该适配，详见frame-owner-compatibility-review.json。
