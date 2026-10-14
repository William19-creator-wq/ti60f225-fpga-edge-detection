# 并行采集与已有源帧处理：TRACK4-FRAME-ACTORS-001

## A. 入口、范围和授权

版本 v1，2026-10-10。先保存、读回、呈现本卡，再冻结输入并实施。沿用用户“当你统计完后自行进行，无需我的批准”和已批准的整批软件本地审计例外；不冒称有新的指定 v1 人工答复，不更新正式 Manifest、数据库、H0 或硬件状态。整体目标仍是 Ti60F225/I3、SC431HAI、1080p、五基础和六高阶的完整软件测试，生成最终 bit 后停止硬件步骤。

Goal：为实际帧管理整合提供可并行的两个执行模块。Current state：production_bitmap 的 capture_canny_rpc 把采集、RX close、读回和 Canny 串在一个任务中；它不能一边采集 B 一边处理 A，也不能只对已有 A 重新处理。上一轮 Efinity 展示已完成、23 份活动输入未变，GUI 查看副本 XML 自动补默认项已单独记录；这是查看工作，不是新的算法推进。最近算法进展是 v27 的权威帧读取查询，346 份业务/验证文件、35 个登记组件，已知工具运行均终止。

Target state：真实 RAW→RGB 源帧写入独立运行，真实 RGB 读回→完整 Canny 独立运行，两者与显示 span 共用真实 video_memory_hub。Gap：缺少从不可变已有 Source 开始的算法任务，以及独立的采集与算法完成端口。

本增量在新 work/active/track4_algorithms_20261004/frame_actors 自写 frame_canny_rpc、frame_actors_axi、组合 TB、独立参考和运行工程。仅复用现有 RAW/color/writer、RGB reader、完整 Canny 和公共内存服务；旧 work、staging、原 HDK 保持只读。

后续仍需唯一帧账本的写入/工作授权、自动 SOURCE_END/RESULT_END/OFFER/APPLY、RX CRC 闭合、实际 row reader/prefetch/scan 接入、复杂识别、DDR PHY 动态验证、整机资源/性能、板级 PNR/STA/bit。不能用本组件的成功代替这些要求。本组件 Source 不可变租约和不相交区域由调用控制器提供，单测按真实采集 DONE 提供条件；本批不会伪装成已实现自主发布控制器。

冻结输入为旧组件 45 份运行依赖（含 3 份旧适配依赖）、9 份适配参考（旧 RPC/top/TB/BFM/数学入口/sim/map/XML/SDC）、本卡和唯一规范 v0.2，共 56 份。精确 SHA 与复制路径写入 baseline.json。详细规范当前 SHA 为 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2，与已完整读取版一致。既有 Questa2024.1、Efinity2026.1.132、Python3.14；不开网络、安装或新工具。当前模块正确性无未决阻塞，物理 DDR 和整机指标仍为独立未完成项。

## B. 整体外部行为

|REQ|可检查规则|
|---|---|
|FA01|采集与算法是两个独立 valid/ready 任务，各有独立身份、取消和 held DONE。采集 B 能在算法 A 尚未 DONE 时接受并推进；处理已有 A 不要求再输入 RAW 或 RX close。|
|FA02|采集沿用 raw_source_join 的真实 RAW/CFA/RGB 写入、计数和两子终态；DONE 明确输出 handle64、scope96、outcome/reason/failed_stage、RAW/RGB/写行/丢弃和逻辑/物理字节。不能由算法的最终状态倒推采集成功。|
|FA03|算法任务锁定 CJ142、Origin195、handle64、四个 base32。验证几何、阈值、Origin epoch/frame 与 CJ、A64 范围和六组不交叠检查。合法任务只读已有 Source，并写 class/queue/1bit edge；没有摄像头输入、Source writer 或 RX close 等待。|
|FA04|算法 DONE 必须等真实 reader 与完整 Canny 已启动子任务均闭合，P 个 reader/input/class、N 个输出及零丢弃才成功；失败与取消有不同 outcome，UNKNOWN/Q 不伪造闭合。输出保持到真实交付。|
|FA05|相邻帧采集、算法的 reader/Canny 仲裁及显示 span 使用同一读写总线；实际 AW/W/B 和 AR/R 决定存储副作用和 closure。全局 Q/axi_enable 阻止新任务，旧请求/回执按原 hub 借用契约继续收尾。|
|FA06|已有 Source A 可在不重新 RAW 写入、不复位的条件下以新 CJ 配置再次处理，Source bytes/Origin 不变，算法 scope/config、梯度、class、滞后结果按新配置对应。|
|FA07|公共端口 holding、配置扰动、气泡、取消、错误、共享竞争和共同 cold 明确验证。安全 held DONE 不因晚到无关 display Q 被重写；global Q 后不接新任务。|
|FA08|运行当前源码仿真和独立字节/事务审计，再做 Ti60F225/I3 组件 MAP，保存原失败和快照。数学 AXI slave 不代表 DDR PHY、持续 HDMI、真实摄像头帧率或整机资源合格。|

正常路径：采集 A 的真实写入全部完成→采集 DONE 成功及 RX 层稍后提供真实 good close→控制器给 A 的不可变借用→算法 A 开始；同时另一 Source slot 接受采集 B，显示读取 A。B 的 DONE 与算法 A 的 DONE 各自可等待消费，互不合并。这里只在单测中承担控制器交接，正式 root 后续接入。

边界路径：算法 A 只改变 median/threshold/config 后再次运行，采集入口没有 job/RAW fire；held AR 时取消仍须等实际 R/last；错误 R response 安全 drain 后失败；RID/LAST 不明导致 Q 并保留未闭合债务；cold 明确使所有旧借用作废，不把 cold 当正常成功。

## C. 模块与连接

```text
控制器给予不同 Source 区域和不可变旧 Source 借用
   FA-IF1 capture job(base,handle,scope,Bayer)  ─→ raw_source_join
   FA-IF2 RAW10 pair/markers/handle           ─→ color → RGB source writer
   FA-IF3 true capture DONE                  ←─ 两个真实子终态
   FA-IF4 algorithm job(CJ,Origin,handle,bases)─→ frame_canny_rpc
       RGB frame reader ─→ 完整 Canny（含真实内存滞后连接）
       两客户端 line_rpc_arbiter2 ─→ algorithm RPC
   FA-IF5 true algorithm DONE                ←─ reader/Canny 两终态
   camera write RPC + algorithm read/write RPC + display span
       FA-IF6 ─→ 原 video_memory_hub ─→ FA-IF7 实际 AXI128
```

MOD1 frame_canny_rpc：负责 FA03/04/06/07，拆除旧串行 RPC 的 Source/RX 状态，只拥有当前算法上下文和子终态；不分配 Source/Result，不证明租约，不认定摄像头 CRC，也不发布显示。

MOD2 frame_actors_axi：负责 FA01/02/05/07，组合原 raw_source_join、MOD1 和原 hub，公布两个独立接口；只门控新任务与 RAW 接受，不新增帧账本、数据大缓存或假回执。capture Source stop 包含 global Q，控制器需按该通知停止/取消接收任务；UNKNOWN 的正常恢复仍为共同可信 cold。

MOD3 原 producer/memory 依赖：保持原算法、CFA、native RAM、read/write/line/span 仲裁版本，现有生产默认 RESULT_ITEM_BITS=1。MOD4 TB/BFM：驱动控制器角色，BFM 数据只由真实 W 写入改变；期望只能来自独立二维 CFA、R2 数学和 BFS，不访问 DUT 私有状态。

结构理由：拆执行责任使冻结帧重处理和帧间并行成立。保留一个算法单元和同一 class/queue 工作区，避免平行复制完整 Canny。控制器不得给两个同时活动角色相交地址；本增量不新增 shadow owner，正式唯一账本在下一步整合。

## D. 接口和组合检查

|IF|端口、域、布局和义务|
|---|---|
|FA-IF1|cap_job_valid/ready、base32 字节地址、handle64、scope96={config32,frame32,epoch32}、Bayer2。调用者保证唯一有效 handle、owner 授权的 WRITING Source、A64 可容纳 RGB 的范围和与其它借用不交叠。全部 unsigned，正沿 fire 锁定。原 writer 的非法 base 返回真实失败。|
|FA-IF2|RAW pair20={lane1 RAW10,lane0 RAW10}，x_even/y 各11、markers3={EOF,EOL,SOF}、bad1、handle64。两像素每次，行宽偶数；接受仅有效 ready，坐标与 markers 由原 color/writer 检查。当前入口支持反压，真实非暂停 CSI 溢出处理仍在外层接收链路闭合。|
|FA-IF3|DONE valid/ready，handle64、scope96，outcome2(0成功/1失败/2取消，Q 无正常 DONE)，reason8、failed_stage2、RAW/RGB/lines/discard 各22、logical/physical bytes32。真实闭合后 held；计数不换算为算法计数，RX close 未在此端口宣称通过。|
|FA-IF4|alg_job_valid/ready，CJ142（原 R2 pkg 编码）、Origin195、handle64、source/class/queue/result base 各32。CJ的 epoch/frame 必须等 Origin，handle 是 RGB reader 当前借用标识，不要求等 Origin 的 SourceHandle（旧调用者两者语义独立）。Source 必须 COMPLETE 且 immutable，调用者承担实际账本授权。四个区域 A64，端点使用33位加法防地址回绕。|
|FA-IF5|DONE scope96/Origin195、outcome2/reason32，reader/input/class 各21、output/edge/discard 各22、R2 status592、phase4、Q。reason bit0非法配置、bit3 reader、bit4 Canny、bit5数量不符；原采集/RX bit1/2 保留为0，不把它们重用成另一含义。matching cancel 精确 scope96，错误优先于取消。|
|FA-IF6|64B RPC valid/ready、write1、addr32、data512；响应 valid/ready、data512、error1、drained1。camera 只写，算法 reader+Canny 共用原 arbiter。512 数据/地址由原 leaf 保存，不以 globalQ/enable 收回已公开请求。display addr32、bytes14（16B倍数、≤8192）、128数据和真实终态。|
|FA-IF7|旧 AXI128：AWID0/AWLEN3/AWSIZE4，完整4个W，BRESP/BID；算法ARID0固定64B，display ARID2的分段满足4KiB、≤1024B，RID/RLAST/RRESP保留旧错误语义。单一数学slave允许一个读和一个写同时活动。|

逐连接：raw_source_join camera 数据符合 hub64B写；MOD1两个 leaf 均使用原 line RPC arbiter 的不可丢债务契约；RGB reader FP74={bad,markers,y,x,RGB48}由已有 Canny 接收，坐标/数量未改变；hub 新任务 gate 仅控制接受，camera/algorithm/显示响应保持原路径。两角色 DONE 没有ready相互等待环；控制器可以独立接收各终态。显示读旧 immutable A，B写独立区域，不把并发转为同址竞态。

有限存储：不增加整帧片上 RAM，保留原 RAW两行、RGB双bank、Canny cache/queue、leaf holding。HD源 RGB=6,220,800B；class=518,400B，queue=8,294,400B，edge=259,200B，均 A64。测试第二源再分配6,220,800B，其余工作区共享；这些是外存逻辑范围，不计成片上 RAM。组件目标时钟100MHz，仿真周期仅数学slave测量，物理时序/FPS不在本组件结论中。

## E. 中文内部操作草图

### MOD1：只处理已有 Source

1. IDLE：只有 axi_enable 且无本地/内存 Q、两个子模块可接任务时公开 ready。fire 沿保存 CJ/Origin/handle/四地址，并把子 started 清0、closed置1、计数/reason/outcome清0；用当前输入判断合法性。同沿非法配置进入 DRAIN且失败，同沿准确取消进入 DRAIN且取消，否则进入 START_CANNY。历史上下文不能参与本次输入合法性判断。
2. START_CANNY：仅依旧状态送锁定 CJ/地址；即使本沿有取消，也记真实 child fire 的 started=1、closed=0，然后转 DRAIN。没接受时留在该状态，不能当未开始而丢掉已承诺 child job。
3. START_READER：Canny 已接纳后，送锁定 Source base/handle；记真实 reader job fire，转 WAIT_READER_CFG。收到错误 cfg 时 reader 无数据债务，closed=1并 DRAIN；合法 cfg 转 PROCESS，若此时已有取消则 DRAIN。
4. PROCESS：reader 公开 FP 直接交 Canny。valid=0 是气泡；ready=0 正文/身份保持。新 CJ 输入扰动不影响锁定值。任一真实子 DONE fire 保存其计数/状态并置 closed，进入 DRAIN；错误置 stopping，取消 outcome 仅在尚无错误时生效。
5. DRAIN：取消保持给仍在运行的 child。若 Canny 已关闭而 reader 仍有公开 FP，只在 stopping 时明确 discard，并按真实 FP fire 累计；不假定 child_cancel能擦掉持有数据。两个 closed 都为1、无Q且数量规则适用时，数量错误优先修正为失败，并进入 DONE。未启动 child 从初始化就是 closed=1。
6. DONE：scope/Origin/count/reason/status held至done fire，无关晚到 memoryQ不能重写安全终态。交付后回 IDLE，但 Q 使 ready继续为0。中途 Q进入 QUARANTINE，不宣告安全 DONE，保留原 child/RPC debt到共同 cold。
7. 同沿覆盖顺序：case基于旧state；随后 matching_cancel、reader/Canny真实终态、error_events、Q按现有优先级提交。错误优于取消。非法配置计数不进入完整数量验证。所有计数只采真实端口，不把 Source采集数量补成P。

### MOD2：两个执行模块及同一总线

1. 定义new_allowed=!rst&&axi_enable&&!memoryQ&&!producer_localQ。capture/algorithm job valid和ready双向一致门控，使外部fire与childfire相同。capjob的base/handle/scope/Bayer由原rawSource在其fire锁定。
2. RAW有效输入只在无globalQ时进入原capture；in_ready同样门控。cap_stop=原stop||globalQ，外层接收控制器需处理该停止通知。已有camera请求与响应绝不以这个输入门控撤销。
3. 分别连接cap_cancel(id64)和alg_cancel(scope96)，分别公布真实DONE。原capture取消为单次事件，调用者每任务最多发送一次匹配事件；可忽略其它任务id。没有跨角色共用停止标志。
4. producer_localQ=capQ||algLocalQ；此信号交hub禁止新事务。algLocalQ不包含hub memoryQ，避免组合自依赖。公开unionQ可以包含memoryQ；hub和两个任务仍保有已接受的债务。
5. display span和所有AXI逐端口透传原hub。两个角色使用不交叠物理区域是控制器的必要租约前提，不能仅凭 Source身份不同推导地址安全。

## F. 语言和映射契约

|RTL项|约定|
|---|---|
|A 数值|端口unsigned；WIDTH偶数6..1920、HEIGHT5..1080，N≤2073600、P≤1036800；21/22位计数足够。A64大小由整数常量计算后转33位；端点先扩展再加，不窄化前检查丢失。1bit edge只改变存储打包，判边数学不变。|
|B 时钟|一个core域posedge提交，rst高同步cold；TB在negedge驱动，posedge先记录旧态fire，negedge观察提交结果，无其它域。|
|C 接受|每任务/data/RPC/DONE仅valid&&ready；原不可停CSI不在此流式边界，外层需有适当FIFO/overflow失败。|
|D valid|无valid不推进、无数值零含义，DONE只在真实闭合后；count来自真实子结果。|
|E 保持|任务在接受前保持，FP/grad/RPC/AXI/DONE在stall时保持；配置采用锁定快照。|
|F 延迟|合法alg job→Canny job→reader job→cfg→PROCESS至少四次后继推进；全部数量/延迟包含真实仲裁和memory stall，不能宣称固定帧时长。|
|G 复位|同步高cold共同重置全部角色/hub/slave，用有效性隔离native RAM；cold后旧事务作废，不作为正常drain。|
|H 配置|job fire原子采样CJ/Origin/base，局部输入扰动不生效；重处理必须新job fire，不能在PROCESS修改门限。|
|I 存储|沿用native RAM/双bank/cache，单个算法使用class/queue；Source只读租约和跨角色地址不交叠由root提供。|
|J 身份|Source handle64、Origin195、CJ scope96分别按既有语义保持；RAW/FP双像素坐标与markers由原模块校验，梯度保留CJ身份。|
|K CDC|本组件同core域无跨域；真实CSI/core/pixel/ui_clk复位和CDC另接，不能以本sim证明。|
|L 实现|SystemVerilog sv_09、Efinity2026.1.132 Ti60F225/I3，clk10ns用于组件MAP；无板级pins/PNR/STA/bit结论。面积由真实MAP报告读取，不能简单求旧组件之和。|

C++本批无新C++，N/A。Python3.14只读数学参考和公开事务日志，任意精度整数用于编码之前显式位范围核查；不模拟DUT私有控制FSM。共同数值：沿用独立二维CFA→R2数学→BFS及1bit LSB-first打包；硬件执行：RTL valid/ready、stall、复位/取消/内存闭合不能由函数返回替代；映射：每case及重处理scope单独命名RAW/FP/grad/class/state/queue/result/status，逐位比较。AXI日志独立重建W/R字节、范围、burst、LAST、真实B/R闭合；从公用BFM导出的最终bytes仅是actual，期望由数学生成。

## G. 实施和验证计划

新增/适配8份：rtl/frame_canny_rpc.sv、rtl/frame_actors_axi.sv、tb/tb_frame_actors_axi.sv、model/frame_actors_reference.py、scripts/run_actors_sim.ps1、scripts/run_actors_map.ps1、project/frame_actors_component.xml/.sdc。另逐字复用hub、BFM、旧数学入口和45运行依赖，不计为新业务代码。每次执行独立RunId、输入快照、实际fatal探针、日志与最终哈希复核；旧失败不覆盖。

|TEST|REQ/IF|场景与期望|方式|当前|
|---|---|---|---|---|
|FA-T1|01/02/03/05|各Bayer和原20图案配置，真实采集A后处理A，同时真实采集不同B并显示A。A/B Source全部字节、FP/grad、class/state/BFS queue/edge/status逐位匹配；两个DONE计数独立；捕获/物理读写必须实际重叠。|34×19及6×5 actual Questa/独立math+公开AXI审计|未运行|
|FA-T2|01/02/03/05|1920×1080真实RAW A与并行RAW B，完整Canny和A显示，不能以参数几何测试代替像素；全帧逐位比较。|1920×1080 actual simulation|未运行|
|FA-T3|06/07|不cold、不重新RAW写SourceA，用新median/threshold/config再处理A，Source不变且算法结果对应新CJ；任务输入接受后扰动不影响当前处理。|同一actual memory/独立数学新配置|未运行|
|FA-T4|04/07|非法重叠和Origin不匹配；取消heldAR/heldR；安全RRESP错误、未知RID/Q；无关晚到displayQ不破坏heldsafeDONE；共同cold后正常再运行。|小尺寸实际错误注入、公开保持/闭合|未运行|
|FA-T5|08|当前sim源绑定组件MAP，核实resource/警告/RAM，原失败保留。|Efinity map实际exit/网表报告|未运行|

Full run不为每个协议故障重复HD像素，T4用小尺寸互补；HD覆盖真实并行正常和已有帧重处理。不是缩小整机目标：识别/CSI/DDR/扫描/板级要求仍待各自闭合。

## H. 双向追踪

|REQ|MOD/IF/草图|代码符号|TEST/来源|实际证据|
|---|---|---|---|---|
|FA01/02|MOD2 IF1..3 E2|frame_actors_axi.capture_actor与cap_*|T1/2 public capture DONE及真实W|待实现/运行|
|FA03/04|MOD1 IF4/5 E1|frame_canny_rpc.legal/state/all_closed/error_events|T1/2/4原reader/Canny+math|待实现/运行|
|FA05|MOD2 IF6/7 E2|frame_actors_axi.memory_hub|T1/2 bus reconstruction/overlap|待实现/运行|
|FA06|MOD1 E1锁定配置|cj/origin/bases/reader/Canny|T3原二维math+BFS新CJ|待实现/运行|
|FA07|MOD1/2 IF1..7 E1优先级/E2 gate|DONE/Q/cancel/ready|T3/4实际stall/fault|待实现/运行|
|FA08|运行工程与参考|run_actors_sim/map、TB/reference/XML/SDC|T1..5 actual工具与哈希|待实现/运行|

反向：两个新生产模块分别对应执行拆分和实际组合，TB/ref/脚本/工程只服务上述可检查要求；冻结的旧模块保持原职责，未引入无要求的大缓存或影子账本。

## I. 门槛、恢复与交付

十项有实质内容：整体行为/样例在B；模块/复用事实在C和真实源码；接口/相容在D；局部状态/中文草图在E；语言契约在F；端到端/有限存储在B/D；实施/验证/双向追踪在G/H；当前未知仅是明确外层义务，无本组件正确性阻塞；本卡保存后实际读回并向用户呈现；版本v1/8份新增文件/56冻结输入及独立work范围清楚。状态 READY_FOR_REVIEW，按已经生效的用户自主执行指令继续，不额外索要批准；正式Manifest/数据库没有被此文本更新。

Milestones：M1文档读回/冻结→M2两个RTL及TB/ref/工程→M3小尺寸actual sim→M4全HD actual sim→M5当前源MAP/登记→继续owner授权和真实发布root。Failure handling：先保存每次原log/快照，确认具体错误再短卡修订；源漂移停止原run，不用修改后源码冒充旧run。恢复按实际process handle及result判断，观察超时不擅自重启。Rollback：新work与新staging隔离，旧组件不覆盖；不删原失败，禁硬件操作。

Completion criteria：FA01..08有对应当前源码的实际证据且局限说清，组件完成不等于总目标完成。实施实录、SHA/真实结果、最终文档—代码—测试一致性放新work README和registration报告，本冻结设计不事后改写。阅读顺序：本卡B/C整体→D接口→E中文步骤→两个生产RTL→TB/reference→run及资源报告。用户理解验收待实际反馈，不把已讲述冒充已理解。
