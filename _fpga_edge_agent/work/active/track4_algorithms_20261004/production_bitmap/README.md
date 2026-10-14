# 生产1位边缘帧：整体到局部的阅读与实际进度

设计入口：[TRACK4-PRODUCTION-BITMAP-001 v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-PRODUCTION-BITMAP-001.md)，局部联测草图：[PB-C1 v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-PRODUCTION-BITMAP-001-C1.md)。主基线67项、消费补充基线19项分别冻结；12份源/工程文件已适配，4份消费验证文件已生成。本组件范围的生产、消费仿真及生产组件综合已通过，登记位置为`artifacts/staging/PRODUCTION-BITMAP-COMPONENT-20261010-v1`，以其中的artifact-manifest.json为登记证据。原8bit work和已登记产物保持只读。整机目标仍未完成。

## 1. 整体行为

实际RAW10色彩流水线写回RGB Source，实际reader读回送入灰度/中值/高斯/梯度/非极大值抑制/双阈值/BFS完整Canny，再写出每像素1bit的边缘帧。低index在低byte/低bit。完整1080p边缘帧应为259200字节，像素和边缘判定不因编码改变。旧8bit编码另做兼容回归。

producer测试包含两遍不可变旧Source的并发显示span读取、实际公共读写hub及原协议审计。消费联测另行实例化实际位图writer、A64帧owner和显示行解析器，已完成写入后读回。两个实验采用受控控制面，不能把分别通过解释成生产FrameRef/RO、扫描和HDMI已自动整合。

## 2. 模块交接与语句入口

`deps/capture/deps/canny_full_sw/rtl/packed_frame_line_sink.sv`：已有512bit槽允许ITEM_BITS=1。组合过程复制旧buffer并按接受count的低位放入当前item；最后item使用next_buffer公开本笔，所以不会遗漏末位。REQUEST、WAIT期间不能接受新pixel；成功真实drained回复后清槽继续，最后一笔回复后才DONE。

`edge_frame_writer.sv`：ITEM_BITS为1/8时分别重复edge一次/八次，检查index及64bit子handle，count仍是pixel。`canny_full_top.sv`、`rtl/capture_canny_rpc.sv`、`rtl/capture_display_axi.sv`逐级传递RESULT_ITEM_BITS，物理RBYTES都为ceil(N*bits/512)*64。新生产顶层默认1，中间独立模块默认8。

`deps/production/frame_owner.sv`和`display_row_reader.sv`：新增FRAME_ALIGNMENT=16/64。owner只把descriptor allocation改为所选对齐，logical/base/CJ/Origin/policy不改；reader使用单独的frame_allocation检查描述，保留align16用于原AXI行span。消费联测明确选64，已检查实际分配、不可变回执、合法描述消费及错误描述拒绝。

34×19：646个画内位，81逻辑字节、128字节物理结果，未填位必须0；Source逻辑1938字节，物理1984字节。6×5是30个位、4逻辑字节、64物理字节，只作为边界测试，生产默认保持1080p。

## 3. 已实际运行的验证

|运行|格式|完整图/采集协议/hub场景|实际总周期|状态|
|---|---:|---:|---:|---|
|production_bitmap_small_001，34×19|1bit|20/18/33|399034|当前源真实仿真及独立审计PASS|
|production_byte8_small_001，34×19|8bit|20/18/33|401750|当前源真实仿真及独立审计PASS|
|production_bitmap_min_001，6×5|1bit|20/18/33|33824|当前源真实仿真及独立审计PASS|
|production_byte8_min_001，6×5|8bit|20/18/33|33824|当前源真实仿真及独立审计PASS|
|production_bitmap_hd_001，1920×1080|1bit|1完整生产图/33hub|38099184|真实仿真退出0及完整独立审计PASS，PID45152已终止|
|production_bitmap_map_001|1bit|绑定small_001的52源/55工程|不适用|Efinity组件综合退出0|

前四次小图都是重新生成、编译和实际仿真，没有复用旧8bit执行。小图共80完整图、27040像素检查，原18采集场景共72次、33hub场景共132次。所有Source/class/state/queue/result/FP/gradient/status/Origin/并发display及物理公共总线的旧检查保留。

另外直接比较两格式的实际结果：34×19的12920像素及6×5的600像素逐位相同，所有Source、分类、状态、队列、FP、梯度、status和Origin文件相同；两格式尾部都清0。这里使用实际输出之间的对应，不把DUT私有状态或另一个期望文件当证据。详见cross-format-proof-small.json及cross-format-proof-min.json。无需cold的连续全1/全0及复用结果槽场景，由第6节消费联测另外验证。

新格式小图总线AW/W/B为1028/4112/1028，旧格式为1235/4940/1235；包含正常图和协议异常，不能把这个总量当成单帧指标。

HD实际完整job为38099163周期，总运行38099184；写事务110496AW/441984W/110496B，读事务114544算法AR/13670显示AR/1235776R，6694读竞争周期。完整259200字节packed边缘有1078边缘像素，与旧HD真实8bit输出2073600个像素逐位相同；Source/class/state/queue/FP/gradient/status/Origin实际文件也相同。新HD全程重新生成、编译、实际仿真和独立审计，见cross-format-proof-hd.json。数学后端周期不等于真实DDR或整机FPS。

合计五次实际执行81图、2100640像素检查、165次hub场景；直接跨格式比较2087120像素。上述四次小图数据保留为各自证据，不把前后累计重复相加。

## 4. 综合、资源与警告

真实1bit组件网表与报告一致：28561 LUT4、21677 FF、1899 ADD、46 RAM10、166 SRL8、0 DSP。网表SHA为1CED84AB41D82FB6CABA07FD353AD3815EAD410838092E9435C60A8B166EA912，报告SHA为7BC04E378A0F54743D5AB1A6162ED53CD81BE7B5763866FB365C81566D27C93F。52仿真源与55MAP源/工程均绑定实际当前SHA及快照。

相对原8bit组件，实测增加1046 LUT和448 FF，RAM相同。1bit累加槽的每个位独立保存，后续整体资源设计需要考虑其选择逻辑；减少外存容量不能当成整体资源已经达标的证明。当前还没有实现该槽的结构优化。

完整警告日志有85项：EFX-0011 VERI-WARNING两项、EFX-0200二十项、EFX-0657六十三项。两项VERI警告是四态X/Z比较在二态综合中的常量化，不证明物理未知态检测；其余为冗余信号删除及小数组/异步元数据映入逻辑。初次统计正则误漏severity字段，已按原日志更正并保留初次解析记录。补查旧hub日志也为83普通WARNING加2 VERI-WARNING，共85；旧登记内容未改，补充事实见warning-review.json。

clk10ns只是组件分析约束。尚无本增量的映射后动态仿真、板级IO、物理时序、布局布线或bit；MAP通过不代替这些证据。

## 5. 运行与追踪

通过已有英文Work入口运行`scripts/run_capture_sim.ps1`，指定新的RunId，`-ResultItemBits 1`或`8`；正常小图另加`-Protocol`，边界使用`-TestWidth 6 -TestHeight 5`，生产使用`-TestWidth 1920 -TestHeight 1080 -Full`。本增量改变编码，运行脚本要求真实重新仿真，不提供旧执行复用选项。

`scripts/run_capture_map.ps1`要求实际PASS的1bit仿真和当前源码SHA；只允许MAP。本次先用小图同源证据运行组件综合，随后完成实际HD与实际写后显示消费；最终52份HD源和55份MAP源/工程仍逐份匹配。没有为先后次序重复综合；消费验证没有修改这些生产源码。

PB01/02→sink/edge writer→实际packed bytes/尾0/跨格式及连续复用；PB03→三个父参数/RBYTES→两格式完整回归；PB04/05→owner/reader allocation→实际A64分配、六模式及HD行消费；PB06→旧控制保持/真实回复→原18/33协议回归及消费端取消/错误/隔离；PB07→参考/快照/工具/fatal→五次生产与四次消费真实执行、MAP及日志。implementation-changes.json保存16份新增或适配文件的真实SHA，producer-progress.json和consumer-progress.json分别保存实际证据。复用依赖不重复计为新写业务代码。

## 6. 消费联测：先读整体，再看内部操作

四份代码的阅读次序是`tb/tb_bitmap_display_contract.sv`的整体实例和frame_case，再读writer/read_row/owner_exchange等局部任务，然后读`tb/axi128_bitmap_frame_memory.sv`的地址映射和时序，最后读`model/bitmap_display_reference.py`的公开事件审计与`scripts/run_bitmap_contract.ps1`的工具流程。

整体交接：真实edge_frame_writer(ITEM_BITS=1)→真实write-pair/line bridge→数学后端的AW/W/B写入；真实frame_owner(FRAME_ALIGNMENT=64)产生结果描述→真实display_row_reader(FRAME_ALIGNMENT=64)、span及native RAM→公开54位pair。EDGE从0xA5开始，必须由实际W覆盖；Source/ANN明确是测试预置。HD把已冻结、独立验证的Source和边缘位重新输入实际writer，再消费完整1080行；这不是同一个生产控制器自动运行的证明。

内部操作顺序：cold清控制和数学环境；owner_exchange锁住command到真实fire，再停顿并接收回执；frame_case执行Source分配及受控SOURCE_EOF/END，再分配结果。configure_writer检查真实配置回复，send_pixels在负沿驱动id/index/bit并在正沿接受事件后推进；ready=0时正文保持。take_writer_done检查实际计数、错误、取消及drained；正常闭合后才允许RESULT_END flags7、OFFER和APPLY。read_row用不可变OFFER生成ticket，按mode决定Source行与mask，逐pair检查generation、地址、RGB/EDGE/ANN，最后接收真实DONE。前一帧所有行完成后才RETIRE，连续正常帧不cold，覆盖同一结果槽再次写全0的旧数据清除。

数学后端map_byte只承认6个Source和3组EDGE/ANN窗口；64B写RPC变成4拍128bit W，strobe、LAST及B闭合都来自真实接口。读AR/R独立停顿。错误BID造成隔离，该场景不能发布成功，只有显式共同cold才继续后续场景。Python从公开输入重建512bit包、所有W/R字节和54位输出，同时核对owner身份/不可变描述、holding正文、数量、错误闭合。当前独立AR检查是描述范围、16B对齐、1024B上限及4KiB边界；不要扩写成已逐笔证明所有精确行span最小性或真实DDR期限。

|运行|尺寸|场景/完整帧/完整行/输出像素|实际周期|AW/W/B；AR/R|
|---|---|---|---:|---|
|bitmap_consumer_small_002|34×20|25/9/180/6120|27228|19/76/20；300/1279|
|bitmap_consumer_min_001|6×6|25/9/54/324|4138|11/44/12；90/135|
|bitmap_consumer_width10_001|10×8|25/9/72/720|6286|11/44/12；120/226|
|bitmap_consumer_hd_001|1920×1080|1/1/1080/2073600|6000045|4050/16200/4050；8159/405000|

四次均是真实重新编译、仿真退出0及独立审计退出0；fatal探针有真实预期失败，随后正常测试另行执行。合计28完整帧、1386完整行、2080764输出像素；三个小尺寸共75次场景执行，HD另1次，不能称76种不同场景。9正常帧覆盖mode0..5，全1/全0/复用全0/棋盘/稀疏/斜线；6种错误header和1种同沿取消、9种writer异常分别记录。B次数多1来自故意错误BID后真实B，不能当成正常事务计数错误。小尺寸是边界验证，生产默认仍是1080p。

首次bitmap_consumer_small_001因TB局部变量名edge是SystemVerilog保留字而编译失败；只把3处局部名改为edge_pair，保留失败快照/日志，small_002及其后三次均使用同一当前15源。真实生产RTL没有因此改动。控制面收尾核查首次误要求hub_fatal_probe退出0，另一次只读查看猜错MAP清单文件名；均保留原因，不重启已经PASS的运行，实际MAP清单为snapshot-manifest.json。

重新运行需新RunId；正常消费者用run_bitmap_contract.ps1默认34×20，边界显式6×6或10×8，HD显式1920×1080和-HD。每次核对19冻结输入，复制15实际执行源，执行vlib/vlog/vopt/fatal/真实vsim/audit并核对末尾SHA。生产52源、消费15源及55MAP输入是不同用途的清单，不能相加为新编写文件数。

## 7. 下一步与证据边界

本组件位图编码、A64帧描述、实际写后显示行消费已闭合。接下来整合权威FrameRef/RO、Source/Result生产发布与扫描控制，再闭合真实CSI、DDR PHY、HDMI持续供数及QoS、完整复杂识别、共享FIT及整机资源/帧率、生产顶层/引脚/时钟/CDC/PNR/STA/最终bit。当前综合只覆盖producer组件，不能把28561 LUT解释成含owner、reader、扫描和完整识别的整机资源。消费job_permitted仍是受控环境值；Source/ANN预置、数学后端和共同cold都不是实物链路证据。全部目标保持ACTIVE，无硬件操作，无正式数据库或H0状态改动。生成最终bit之后停止硬件步骤；用户理解验收待实际作答。
