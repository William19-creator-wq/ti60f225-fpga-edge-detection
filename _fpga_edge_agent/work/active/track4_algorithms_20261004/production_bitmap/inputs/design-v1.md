# 生产边缘位图与帧容量交接：TRACK4-PRODUCTION-BITMAP-001

## A. 状态、基线与授权

- 版本v1，2026-10-10；当前READY_FOR_REVIEW，先保存、读回和呈现，再实施。
- Goal：保持完整1080p算法和原识别范围，补齐Canny结果与生产显示之间的格式/容量交接。Current state：已登记公共读写hub v1.4实际RAW→RGB→完整Canny，结果为8bit/pixel；frame_owner和display_row_reader为1bit/pixel、描述分配A16。Target state：生产结果1bit/pixel、物理分配A64；实际写出的位图可按既有显示行读取器解释。Gap：格式8倍差异及末尾写回超出A16容量。
- 增量位置：采集/算法/存储到显示之间；继续使用已有实际RTL及数学AXI后端，不降低尺寸、目标数或识别要求。
- 工作路径：D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/production_bitmap。旧work、原HDK及所有已登记产物只读。
- 来源事实：capture_display_hub/frame-owner-compatibility-review.json；checkpoint v23；capture_display_hub当前55项MAP源及10项owner/reader资料。基线冻结67项：55项hub、10项邻接源码/验证资料、本卡、详细规范。逐项路径及SHA在新work/baseline.json；不伪造Git提交。
- 关键旧SHA：packed_frame_line_sink 373D70B03125E883E63616076C5BB09B3C62F5917C4F8962F31CC69F41DE40FC；edge_frame_writer 436A850B7B13CFAA0494638B911701001AF97ACB22FAE996BE2FDD46C46B1E2B；canny_full_top 47690E52B3341CCA5FF8949AF085F9EA64FA472CCA31C8103724A85490E48F9D。
- 批准来源：用户原话“当你统计完后自行进行，无需我的批准”，以及已批准整批软件实现、本地审计例外。该持久指令使本次设计读回/呈现后可自主实施；不声称用户另行批准了v1，也不修改正式Manifest、数据库或硬件状态。设计、冻结和实录仍保留。
- 本增量正确性无未决阻塞；真实DDR时序、权威RO查询、连续显示QoS、CSI及单板PNR/STA属于剩余整机工作，不能用本组件证据代替。PostgreSQL未配置，沿用本次软件本地审计例外。
- Dependencies：已有Questa2024.1、Efinity2026.1.132、Python3.14、native EFX_RAM10；不安装、联网或操作硬件。

## B. 整体行为与可判断样例

|要求|边界与观察|
|---|---|
|PB01|实际完整Canny每个pixel的edge判定保持原值，index按行优先；生产存储bit i位于base+floor(i/8)的bit(i mod8)，低像素在低位。|
|PB02|边缘逻辑字节ceil(N/8)，实际分配A64(ceil(N/8))；每512像素形成一笔64B写，末笔未使用位/字节为0。done仍等待最后真实drained回复。|
|PB03|参数1/8显式区分编码，所有受影响父的范围检查、子实例和TB/参考采用同一参数。8bit默认的既有叶/中间模块保持相容；新生产顶层默认1。原登记8bit包不改。|
|PB04|Source/EDGE/ANN描述逻辑长度不变，分配长度可选16/64，生产采用64。源/结果身份、槽基址、CJ、policy及发布生命周期不改。|
|PB05|实际display_row_reader在FRAME_ALIGNMENT=64时只按A64检查bundle分配；仍按16B span读取行范围，恢复出pair54中的edge2及原RGB48。最后字节的无效位不能成为画内pixel。|
|PB06|错误、取消、holding、UNKNOWN隔离及可信共同cold沿用实际sink/AXI服务；不因格式改变跳过回执、虚构写完成或复用不确定归属。|
|PB07|新范围实际仿真、独立数学/公共总线审计及生产组件综合；所有失败原样保留。证明层级如实区分，不宣称生产DDR、FrameRef授权、扫描、PNR/STA、bit或硬件通过。|

正常样例：1080p N=2073600；旧8bit实际2073600B，新bit逻辑及A64分配均259200B、4050笔64B结果写；pixel数和edge数相同。因读写竞争，周期由实际调度测量，不能直接除以100MHz声称整机FPS。

边界样例：34×19 N=646，逻辑81B、A64分配128B；bit645是最后画内位，646..1023清零。Source逻辑1938B，A16=1952而实际A64=1984。6×5 N=30只占4逻辑字节、64B分配。连续帧先全1再全0不得保留旧尾位。消费显示使用偶数高的6×6、10×8、34×20及1080p，现有producer仍保持5..1080高，不把显示分屏的偶数高要求静默推广为算法限制。

失败样例：配置基址非64对齐或33位end超过地址范围，配置回复error且无写；像素index/handle错导致已接受计数与失败，不能发布成功结果；取消在公开req停顿时，旧req保持至接纳和真实回复，drained0进入隔离；新frame不能靠消费错误通知恢复。

## C. 整体模块、连接及必要性

```text
实际RAW→RGB Source writer→真实读回→完整R2/BFS
  PB-IF1：index21/edge1/handle64，valid/ready
          ↓ edge_frame_writer(ITEM_BITS=1)
  PB-IF2：512bit累加槽→64B RPC→既有hub/write-pair→AW/W/B
          ↓ 位图字节
frame_owner(FRAME_ALIGNMENT=64)→Source/EDGE/ANN描述与完整bundle
  PB-IF3：942bit bundle+543bit row_ticket
          ↓ display_row_reader(FRAME_ALIGNMENT=64)
  PB-IF4：实际span/AR/R→meta native RAM→pair54={ann4,edge2,rgb48}
```

MOD1：适配packed_frame_line_sink、edge_frame_writer，只负责位打包、身份/顺序和写回闭合，沿用一个512bit buffer，不增加整帧片上RAM。

MOD2：适配canny_full_top、capture_canny_rpc、capture_display_axi，传播RESULT_ITEM_BITS并计算相同物理RBYTES；不改Canny算术、BFS/queue/cache、CJ或已闭合错误状态机。

MOD3：适配frame_owner和display_row_reader的FRAME_ALIGNMENT参数。owner仍负责唯一槽账本，reader仍逐行解析；只改描述物理容量，不改固定8MiB槽或行span的16B边界。默认16保持既有入口，生产实例明确64。

MOD4：独立Python pack/unpack参考、公开接口TB及现有工具运行组织。实际Canny测试观察完整Source/class/state/queue/result/FP/gradient/status/Origin/两遍旧Source及所有物理总线；消费测试另外观察真实writer写出后reader的pair和描述。公式参考不读取DUT私有数组作期望，数学slave数组仅作实际字节证据导出。

本增量还不把owner闭合flags接入生产RX/算法的自动发布控制，也不实现权威RO查询或持续扫描。消费测试可使用真实owner命令回复建立描述，但其环境闭合声明属于测试输入，不能冒充真实生产自动授权。

## D. 接口、数量及组合检查

PB-IF1：同一core_clk正沿valid&&ready接纳，unsigned index21、edge1、id64；active_id来自cfg接受，index必须等于已接受count22。无valid不推进；holding输入正文稳定。每N个pixel，输出N个edge判定，格式改变不改变counts。

PB-IF2：addr32/data512/write1和req/rsp valid/ready，error1/drained1；base必须A64；地址base+64*floor(i/512)。低byte/低bit为低index，所有未填位0。一个已公开请求占住累加buffer，REQUEST及WAIT不能接收新pixel。旧RSP实际drained后才能清buffer、继续下一组；dr0隔离。最后N个pixel的实际写回复完成才DONE。

PB-IF3：frame_owner_pkg.reply_t为942bit，descriptors各96bit={base32,logical32,allocation32}；row_ticket543含generation/sequence/scan/result_handle/policy/Origin195、target/source_y11、mode/mask3。A64容量只改变allocation字段。固定Source slot0..5*0x00800000，EDGE result0..2从0x03000000、ANN另加0x00100000；整包未改变此内存地图。

PB-IF4：span长度16..8192且A16，实际leaf最多64拍及4KiB分段。位图按source_y*W计bit偏移，reader已有128bit前缀及16bit metadata缓存逻辑；A64容量不改变其行范围或低bit解释。pair54低48是两RGB、bits49:48是edge2，lane0低位。out_valid停顿保持address10/data54/generation64。

逐连接检查：HY提供完整顺序pixel和borrowed handle，满足sink输入；sink的64B A64写满足实际AXI服务；同一RESULT_ITEM_BITS在父范围和writer避免把未分配字节当合法地址。owner64描述满足reader64精确检查，RGB存储既有R/G/B byte顺序与reader重组相同。8bit位图不得送到1bit显示；生产参数显式1。

数量/资源：分组从64pixel/line变为512pixel/line，logical byteceilN/8、physical lineceilN/512。缓存仍512bit；计数22、slot9、地址32/end33。1bit动态选择译码可能影响LUT，留给真实MAP；不得仅凭总字节下降声称资源整体达标。无新CDC，边缘writer和reader同core域；完整显示video域仍由原row mailbox/RAM承担，本增量不另加异步逻辑。

## E. 详细中文操作草图与语法组织

MOD1：参数ITEM_BITS允许1/4/8，edge wrapper只允许1/8。localparam PER_LINE=512/ITEM_BITS、SLOT_BITS=clog2(PER_LINE)。组合always_comb从旧buffer复制next_buffer，在count低SLOT_BITS指定的可变片段放入当前item。edge_data在1bit时为edge，在8bit时重复8次；这是精确表示转换，不改边缘判定。

时序always_ff沿用非阻塞更新：cfg接受清buffer/count并锁base/id；CFG_REPLY先完成握手；ACCEPT沿只有实际pixel fire推进count。最后一个槽或frame末项时提交next_buffer与line_addr并转REQUEST，保证末项包含在本笔；REQUEST正文保持，真实req fire转WAIT；实际rsp fire检查drained/error/cancel，成功且未结束才清buffer/返回ACCEPT。DONE正文保持至消费；cold清valid和有效状态。取消和身份检查沿用原语义，任何变更另开短卡。

MOD2：三个父声明RESULT_ITEM_BITS，使用N*bits的33位常量预算：分配为ceil(N*bits/512)*64；实例逐级显式传给子模块。只修改参数表、范围常量及实例参数，不改实际控制分支。新生产capture_display_axi默认1；中间父/edge wrapper默认8，保护独立复用入口。配置检查在实际public job fire作用，不按异步全局配置改在途frame。

MOD3：owner增加FRAME_ALIGNMENT(默认16)，新增frame_allocation(bytes)函数，只在形成descriptor allocation时选择A16/A64；固定base和logical字段不动。reader保留align16函数用于span，另加frame_allocation仅用于header expected descriptors。静态检查仅允许16/64。把两个函数职责分开，避免把AXI行读取错误地变成64B跨度。

MOD4：Python从独立旧BFS的edge序列按每8pixel生成byte，bit顺序由i mod8决定；补0至A64；解码回N位与原edge逐项核对，尾部必须0。layout和TB用同一声明参数但独立公式。TB参数TEST_EDGE_BITS分别跑1、8，不用全局WIDTH覆盖native RAM参数。每次冻结快照，正常生成/编译/真实仿真，不复用旧8bit执行；审计保持全部旧检查。

不变量：count是pixel，不是byte；buffer中已有位只对应本组已接受index；未填位来自清0；公开req期间buffer不改；RBYTES四层一致；DONE成功要求Npixel和最后drained；对齐只作用allocation，不作用logical/坐标；同一ticket对应不可变bundle。

## F. 语言、时间及平台契约

RTL使用现有SystemVerilog，Questa vlog -sv、Efinity sv_09；时序<=、组合=，unsigned扩展后比较，参数N*bits最大16588800小于32位常量范围，end用33位。没有除法器：分配/bit偏移均编译期常量或二次幂移位。一次交接使用正沿旧valid/ready，输出沿后寄存，下个正沿接收；TB负沿驱动、正沿记录。

输入valid=0忽略数据；count/组地址只在fire更新。输出req、DONE及正文停顿保持。cfg只在IDLE接纳并锁存，不能与旧任务交叉。rst同域同步高有效；owner沿用safe_reset_n异步置位/本域释放，测试必须共同可信cold，不能假设只复位sink使DDR已终止。

存储512bit单累加槽，metadata沿用真实native RAM读延迟；没有新增整帧片上缓存。PIXEL→BIT是无损，参考为Python整数/bytes，C++本次N/A（无C++实现或映射）。三个跨语言契约分别是精确bit编码、真实握手/回复闭合、pixel index与物理byte/bit及显示pair的对应，数值一致不能替代后两个。

预算：生产默认1920×1080，producer可用偶数W6..1920/H5..1080；消费reader沿用偶数W4..1920/偶数H2..1080。目标器件Ti60F225/I3，组件分析clk10ns。实际吞吐、LUT/FF/RAM/DSP由本增量报告；板级时序/IO/CDC另在生产顶层闭合。

## G. 实施、验证、失败与回退

Milestones：M1冻结67输入/读回设计；M2参数/布局适配并实际Canny回归；M3真实写入位图与实际显示行消费、A64描述检查；M4当前源HD仿真与组件MAP、独立结果/资源审计；M5文档代码追踪及staging登记。M2完成不代表M3/M4已经通过。

|TEST|输入/事件及实际观察|期望依据与判据|
|---|---|---|
|PB-T1|新producer34×19，20同源RAW图、18旧采集协议、33hub场景；bits1和8各重新仿真|独立旧CFA/R2/BFS，完整结果/所有中间文件/物理公共账相同严格检查；格式byte和tail逐项核对。|
|PB-T2|6×5最小producer、两个格式；34×20等消费者可用参数|512bit末组、非8/16/64位整除、无边缘/全边缘/连续帧；尾0、地址/字节数和计数准确。|
|PB-T3|实际bit writer→write-pair→AW/W/B后端；owner64分配/OFFER描述；实际reader读取6×6、10×8、34×20全部行|由原pixel序列独立比较RGB/edge pair、公开AR/R/W完整字节和范围；source/edge容量A64，旧16描述在需要不同时拒绝。|
|PB-T4|writer非法base、index/handle错、取消req停顿、回复error/drained0、共同cold；reader拒绝错误长度/身份/模式|旧控制契约错误分类/保持/隔离与无成功发布；真实fatal探针证明测试退出可失败。|
|PB-T5|生产1080p真实RAW/Canny、bit结果、完整两遍旧Source；实际消费者完整HD位图读回|2073600pixel、259200B packed edge、6220800B source及完整身份，真实执行退出0、独立审计PASS，未经真实执行不算。|
|PB-T6|当前真实源/快照绑定后Efinity组件MAP|实际网表计数与报告一致，警告逐类记录；无物理时序结论不冒称PNR/STA或bit完成。|

Detailed steps：先在新work复制不变依赖，适配注明的文件；生成完整独立参考/TB及运行组织；小图1/8及最小边界先验证；消费接口单测；实际HD与当前MAP；修复先记录证据/草图，保留旧失败attempt。State transitions：READY→按持久授权IMPLEMENTING→VERIFYING；仅所有当前范围测试通过后DELIVERED_COMPONENT。Artifacts and hashes：baseline、源码/工具阶段快照、suite、字节结果、公共账、MAP及资源、最终manifest。本卡不把存在这些文件当作通过。

Failure handling：实际失败保留源码/日志/工具退出；不删除期望、不把位数不符结果重标为PASS；丢失观察先恢复同一PID/结果，不能因轮询超时重启。Human gates：生成最终生产bit后停止硬件步骤；本增量MAP无bit。Rollback：旧work和staging未改，弃用本新work的发布引用即可，无删除旧证据。

## H. 双向追踪与修改入口

|要求|职责/接口/局部步骤|计划源码|验证|
|---|---|---|---|
|PB01/02/06|MOD1，IF1/2，next_buffer/512组/真实drain|新work/deps/capture/deps/canny_full_sw/rtl/packed_frame_line_sink.sv、edge_frame_writer.sv|T1/T2/T4/T5|
|PB03|MOD2，RBYTES与子实例传播|同目录canny_full_top.sv；新work/rtl/capture_canny_rpc.sv、capture_display_axi.sv|T1两格式/T2/T5/T6|
|PB04|MOD3，allocation函数/CJ身份不变|新work/deps/production/frame_owner.sv|T3/T4|
|PB05|MOD3，header allocation/原16B span/低bit pair|新work/deps/production/display_row_reader.sv|T3/T4/T5消费者|
|PB07|MOD4，冻结/独立审计/真实工具|新work/model、tb、scripts、project；运行实录|T1..T6|

计划符号尚未生成、测试未运行。反向要求：每个参数/分配函数对应PB01..05，脚本快照/fatal及公共账对应PB06/07；不添加无关框架。

## I. 设计自检及呈现

§10.3十项：①B定义边界及正常/失败；②C已读真实职责与复用；③D位宽/身份/数量/时序检查；④E寄存器、操作和不变量；⑤F语言/RTL A–L及跨语言契约；⑥D正常/末组/取消路径及资源；⑦G/H实施验证与双向关联；⑧A当前无阻塞、整机缺口隔离；⑨本卡落盘后实际读回并向用户给入口，完成前不生成；⑩v1、67冻结输入、新work范围明确。此为设计分析，不是运行结果或用户理解证据。

READY后的下一项允许行动：按用户持久自主软件指令，在本卡范围内复制独立work/适配/真实验证。尚未收到新的指定v1聊天批准；不伪造该记录，也不因此重复索取用户已取消的逐批批准。

## J/K/L. 实施实录及最终阅读（待填写）

当前业务实现尚未开始。完成后按实际模块符号/源码SHA补齐变更、实际命令/日志、测试通过/失败/未执行和一致性核查；读卡B整体→C职责→D交接→E语句→H代码与测试→README实录。M3/M4未运行前保留未完成，不登记成完整交付。用户理解验收待实际作答；不以此阻塞授权软件工作。
