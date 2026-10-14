# TRACK4-ANNOTATION-WRITER-001：标注帧真实写入与授权读回

## A. 状态与阅读入口

- Goal：把既有 Mode5 标注描述映射成实际存储事务，使帧发布能够依据真实生产者完成事件。整体目标仍为原五项基础、六项高阶、1080p、Ti60F225/I3、SC431HAI、现有板载 DDR；不改变原复杂识别范围。
- Current state：frame_actors 已把并行采集和完整 Canny 接入共享 AXI；frame_owner_read_authority 已有真实账本查询；production_bitmap 的显示读取支持 ANN，但其测试 ANN 来自预装夹具，缺少真正 ANN 写入模块。
- Target state：新 writer 写完 66 个 A64 头部块和全部标签、取得真实 drained 回执后产生安全完成；测试通过真实 owner 查询，再由既有 reader 读出 Mode5 全帧。
- Gap：本批填补 ANN 写入运输环节，后续自动发布控制器、识别生成器、共享显示总线和板级顶层仍须继续。不会把夹具标签称为形状识别结果。
- Task/version/date：TRACK4-ANNOTATION-WRITER-001 / v1 / 2026-10-10。关联 A6、A3、R0。
- Stage：READY_FOR_REVIEW；保存、读回、呈现、冻结后按已有持续授权实施。
- Authority：用户原话“当你统計完后自行进行, 无需我的批准”，以及“把能完成的尽量快点完成, 把能碥码的快速完成”。引用已有软件自主执行及本地审计授权，不伪造对本版本的新答复；正式数据库、Approval Manifest、硬件状态不改。
- Work：`work/active/track4_algorithms_20261004/annotation_writer/` 新副本。原材料及先前已登记组件只读。
- Baseline：保存后以 `annotation_writer/baseline.json` 枚举和 SHA256 冻结实际使用的依赖、参考文件、本设计和 v0.2；没有 Git commit 不编造。生产依赖、参考与本批新增文件分开列出。
- Assumptions：调用者只用新鲜 ALLOC_RESULT/OK 回执启动 writer，真实 R_WORKING 权限由后续发布控制器负责。writer 检查字段合法性，不从字段相符推出账本活性。所有输入可暂停；此组件单时钟，不接原始不可暂停 CSI。
- Open questions/blockers：本批接口、布局与时序已确定，无当前阻塞。完整识别元数据内容、真实 DDR PHY 动态模型、实际 CSI 和整机资源/时序是后续任务；与本批运输验证有明确边界。
- Dependencies：既有 packed_frame_line_sink、实际 axi_write_pair_service/axi_line_bridge、frame_owner_read_authority、display_row_reader/display_meta_ram/display_span_axi 和本地 RAM10 仿真模型。
- Reading：本节范围 → B 总行为 → C 连接 → D 参数 → E 中文操作 → F 语言 → G/H 验证追踪。

## B. 整体外部行为

| REQ | 要求与可观察边界 |
|---|---|
| AW01 | 接受 Mode5、A64、当前几何、合法 Source/Result 槽及完整身份的 ALLOC_RESULT/OK bundle；拒绝格式错误的任务，只给配置错误回执，不发 IO 或 DONE。 |
| AW02 | 调用者顺序提供索引 0..65 的 512 位头部块。66 次成功、闭合的真实回执后才接受像素标签。头部 128 字节和对象列表 4096 字节在此作为不透明载荷；语义由未来识别生成器负责。 |
| AW03 | 每个输入包含连续两个像素的两个 2 位标签，低 lane 对应低像素；所有 0..3 均合法。严格检查全帧 pair index、Result handle、最后一项 last。A64 尾部补零，跨行连续打包。 |
| AW04 | 对外已公开的写请求、配置回执、完成及其身份在反压下保持；每项仅在实际 valid&&ready 上升沿推进。 |
| AW05 | 取消必须匹配 Result handle。取消后停止接收新载荷，但已公开未接收请求、已接受请求及其回执必须实际交接/闭合，才能给取消 DONE。旧身份取消无效。 |
| AW06 | drained=1 的存储错误给安全错误 DONE；drained=0 或底层 UNKNOWN 进入隔离，不给安全完成、不重用，只有共同可信冷复位恢复。错误优先于取消；安全 DONE 已公开后不被新无关异常改写。 |
| AW07 | 完成携带 Result handle、CJ 低96位 scope、Origin195、outcome(0正常/1错误/2取消)、reason8、成功头块数7、实际接受 body pair 数22及成功 body 块数22。计数不同于已持久化像素数。 |
| AW08 | 验证实际 ANN 写入 → AXI 字节存储 →真实 RESULT_END/OFFER/APPLY →账本 lookup → Mode5 reader/RAM10 → pair54。Source/EDGE 是明确夹具；ANN 绝不预装期望。 |

正常：取得新 R_WORKING → 配置回执 → 66 头块各实际写回 → N/2 pair → 最后块回执 → 正常 DONE → caller 发送 RESULT_END(flags7) → OFFER/APPLY → 每行查权限、读回。错误任务不产生额外 DONE；载荷身份错误属于已启动工作失败，可给安全 DONE。隔离时不能用软件超时伪造 drained。

## C. 模块与整体连接

`真实 owner ALLOC_RESULT回执 → IF01 annotation_frame_writer → IF04 write_pair_service → actual axi_line_bridge → IF05 数学AXI字节存储`

`caller观察 IF06安全完成 →真实owner RESULT_END/OFFER/APPLY → IF07 lookup(demand479) → display_row_reader → actual span/RAM10 → IF08 pair54`

- MOD1 新 `annotation_frame_writer`：管理配置、头部、子 sink、取消与完成；不管理账本、不分类图形、不修改 Source/EDGE。
- MOD2 复用 `packed_frame_line_sink`：ITEM_BITS=4、ITEMS=N/2、ID_BITS=64，一个512位私有缓冲；已有错误、取消、真实闭合契约。本批不改旧源。
- MOD3 复用写服务与四拍桥：只有 bridge 保存物理事务；writer 不把 ready 当完成。
- MOD4 复用真实账本、reader、native RAM10：查询决定权限；不以测试常量 permitted=1 代替查询。
- MOD5 新独立 TB/BFM/参考审计：Source/EDGE 明示固定公式；ANN 初始 A5，仅实际 W 修改。独立 Python 从公开事件重建事务和字节，并核对所有头部、标签、尾零、行输出、因果顺序。
- 组合检查：头部与 sink 对 IF04 时间复用，一次仅一个请求；头部闭合后才配置 body；body DONE 才释放 sink 并登记父 DONE。没有两个响应接收者竞争、没有 ready 等待尚未启动的生产者。

## D. 接口及逐连接检查

全部信号 unsigned，单 clk 上升沿，rst 同步高有效。valid正文连同身份保持至 fire，复位例外。接口表是设计签名，无实现体。

| IF | 方向/参数/事件 | 前提与保证 |
|---|---|---|
| IF01 job | 输入 job_valid/bundle942；输出 job_ready | bundle 是 frame_owner_pkg.reply_t，op=ALLOC_RESULT3,status=OK0；slot<6/3、handle及policy非零；Origin={SourceHandle64,frame32,epoch32,SourceHandle64,slot3}；CJ W/H/lo<=hi/frame_epoch；Source/EDGE/ANN canonical A64描述；mode5,split_y=H/2。有效任务才写存储。 |
| IF02 ack | 输出 job_reply_valid/error，输入 ready | 配置判断只在 job fire 采样；错误 ack后直接空闲，没有未启动工作的伪完成。cancel可在 ack等待期间锁存。 |
| IF03 header | 输入 valid,data512,index7,handle64；输出 ready | index=成功头部块数、handle=本任务；只有头部接收态可接受。错误被接受后无新请求，安全错误结束；正常块私有保存后发请求。 |
| IF03b body | 输入 valid,pair4,index21,handle64,last1；输出 ready | P=N/2最大1036800；index与 sink count吻合，last仅 index=P-1。只有66头块已成功闭合且子cfg ack后可接受。与子sink in_bad一起真实采样。 |
| IF04 RPC | 输出 req_valid/write1/addr32/data512；输入 ready；输入 rsp_valid/error/drained，输出 rsp_ready | 固定64B、A64地址；头部addr=ANNbase+64*i；bodybase=ANNbase+4224；drained=0不得关闭。取消不能撤销已公开req。无外部memoryQ输入以免撤销请求；全局Q由父控制器禁止下一工作。 |
| IF05 AXI | 复用128bit实际桥 | AW A64/len3/size4、4个W、全strobe、LAST真实、对应B；AR由实际reader，A16且不越4KiB。BFM检查地址授权与正文。 |
| IF06 done/cancel | cancel valid/handle64；DONE valid/ready,handle64,scope96,Origin195,outcome2,reason8,headers7,pairs22,lines22,drained1；Q独立 | reason bit0配置防御、1头部格式、2body格式、3存储、4子cfg；只有真实闭合时 drained=1。Q没有DONE；done正文冻结至fire，取消输入在DONE无效。 |
| IF07 owner | command941/reply942；offer_sequence64；lookup479/ready/permitted/bundle942 | TB使用真实owner。Source_EOF/END与既有EDGE闭合为环境夹具，明确不证明新执行RAW/Canny；ANN完成实际。R_WORKING/DONE 查询应拒绝；OFFERED/DISPLAY查询精确身份后许可。 |
| IF08 pair | 真实reader out_valid/ready,data54,address10,generation64 | data={ann4,edge2,rgb48}；核对每像素ANN、既有Source/EDGE公式与公开AR/R字节。每行数量 W/2，顺序索引严格连续。 |

范围：W为4..1920偶数、H为2..1080偶数、N=W*H。Source base=s*8MiB，RGB逻辑3N；Result base=0x03000000+r*8MiB，EDGE逻辑ceil(N/8)；ANN base=Result+1MiB，逻辑4224+ceil(N/4)，各物理长度向64B上取整。33位地址末端检查不超过256MiB。既有结果与 source不重叠。

## E. 局部状态、中文操作草图

MOD1 状态：IDLE → JOB_REPLY → HEADER_ACCEPT → HEADER_REQUEST → HEADER_RESPONSE（重复66次）→ BODY_CONFIG → BODY_ACK → BODY_RUN → DONE；未知闭合进入 Q。

保存：Result handle64、scope96、Origin195是本任务身份；ANNbase32用于地址计算；头部缓冲512保存已接受输入；header_count7只记error0/drained1的回执；body_count22由子sink实际接受量；body_lines22只记成功子RPC回执。取消sticky仅本任务匹配，reset和新job初始化清零；reason/outcome DONE前登记，DONE期间不更新。

1. IDLE：旧状态空闲且非reset才ready。job fire沿用当前bundle算canonical合法性，采样最少身份与ANNbase、清计数/取消；下一拍JOB_REPLY公开ack，不保存942位完整影子账本。
2. JOB_REPLY：ack保持。合法ack交付后，若取消已锁存则安全取消完成，否则进入HEADER_ACCEPT；非法ack交付回IDLE，不启动body。
3. HEADER_ACCEPT：取消优先，不接受新头；否则真实header fire检查index/handle。合法数据保存到private header buffer，地址根据旧header_count形成，下一状态HEADER_REQUEST。非法数据登记格式reason，安全错误DONE。
4. HEADER_REQUEST：valid与地址、data保持。取消只锁存停止意图，不撤请求。直到真实req fire才进入HEADER_RESPONSE。
5. HEADER_RESPONSE：只有rsp fire改变状态。drained=0进入Q；闭合error登记存储错误；闭合成功header_count加1。错误优先取消，随后停止；否则未满66回HEADER_ACCEPT，满66进入BODY_CONFIG。
6. BODY_CONFIG/BODY_ACK：子cfg有效保持到接受；子cfg ack错误则父安全错误DONE，正常开始BODY_RUN。期间匹配取消锁存并传给已经配置的子sink，不伪造其完成。
7. BODY_RUN：body valid/ready同子sink一一对应，验证index/last/handle作为in_bad；成功RPC回执body_lines加1；子sink Q导致父Q；只有子done fire才锁定父outcome/reason、保留最终count并进入DONE。丢弃未公开的private尾缓冲由子sink真实取消流程处理。
8. DONE：drained=1且正文冻结；消费后回IDLE。Q：ready/正常DONE皆为0，保留归属直到共同冷复位。复位不声称旧事务闭合；系统复位必须同时覆盖本模块、服务与存储协议状态。

不变量：HEADER阶段body未启动；header_count<=66；正常完成header_count=66且body_count=P且body_lines=ceil(P/128)；外部不可能同时看到header和body两份请求；每个公开请求后只接一个实际rsp；last输入以全帧index定义，不按行重启。数据从0xFF变0无复位时尾部必须清零。

## F. 语言与映射契约

| RTL项 | 实际约定 |
|---|---|
| A数值 | descriptor32，地址加法33位防溢出；index21可容P-1，count22可容P；头块7可容66；每字节低像素标签占低2位；A64尾零无舍入。 |
| B观察 | TB下降沿驱动、上升沿观察公开fire；RTL非阻塞提交，跨状态输出下一周期可见。 |
| C接受 | 每个流按posedge valid&&ready；cancel是本任务匹配事件，可持续锁存。 |
| D有效 | 无valid不推进载荷/count；中间状态可根据实际闭合响应推进。 |
| E保持 | 输入上游可暂停；512位私有槽与sink私有槽有界；公开req/ack/done反压不改正文。 |
| F吞吐 | 正常头部66个64B事务，body每128pair一事务，尾不足也64B；P个pair至少P次接受，存储等待额外增加时间；不能推算物理FPS。 |
| G复位 | 同步高reset、禁接受、invalid所有输出；所有客户端/服务共同冷复位才隔离恢复。ANN内容不由RTL清全帧，只由真实W覆盖。 |
| H配置 | bundle在job fire一次原子采样；之后输入config变化不影响当前任务；不引入跨域更新。 |
| I存储 | 本体头512bit+复用sink512bit，另有身份/计数寄存器；没有新增帧RAM。实际RAM资源待MAP统计，不凭逻辑位数认定综合结果。 |
| J身份 | 严格Result handle与Origin/CJ保留；全帧连续pair，不按行pad，body字段3也合法。 |
| K CDC | 本组件单域，N/A有依据；真实DDR/CSI/pixel域跨域整合仍需后续验证。 |
| L实现 | SystemVerilog sv_09、Questa2024.1、Efinity2026.1.132、Ti60F225/I3；component MAP目标10ns仅资源预检，不声称布局布线/STA/bit完成。 |

C++ N/A：本批不实现C++；独立Python使用精确非负整数生成标签与头部公式，读取公开事件重建内存，比较逐位。硬件执行由独立TB检查接受、反压、取消、闭合、隔离；Python数值相符不代替时序。pair(i)对应pixel2i/2i+1，header(i)对应字节64i..64i+63；scope/Origin来自真实owner回复，cold后旧任务作废。

## G. 实施与验证计划

- Milestones/steps：保存读回本设计 → 冻结实际依赖/参考 → 新RTL → 新BFM/TB及独立参考 → 当前小尺寸及最小参数/跨字节尾部 → fullHD → 当前源组件MAP → 记录证据/登记只读产物 → 后续publisher继续。
- 计划新增8份：rtl/annotation_frame_writer.sv；tb/axi128_annotation_memory.sv、tb/tb_annotation_writer.sv；model/annotation_reference.py；scripts/run_annotation_sim.ps1、run_annotation_map.ps1；project/annotation_writer_component.xml、sdc。

| TEST | 覆盖 | 场景与通过标准 |
|---|---|---|
| T01正常 | AW01..04/07/08 | 多帧所有标签3→0无reset、位置公式、稀疏标签；逐个66header+Ppair实际写入并全行授权读回，尾零、slot重用、身份及计数完全相同。 |
| T02配置 | AW01 | 非Mode5、错误ANN长度/地址、CJ、Origin、op/status、slot，ack错误且无IO/DONE；恢复后正常任务可运行。 |
| T03载荷 | AW02/03 | header index/handle、body index/handle/last错误均真实采样，安全错误DONE，无未经接纳的写。标签3正常。 |
| T04取消 | AW04/05 | 旧handle取消无效；header未接受RPC、已AW/W、等B、body公开RPC等阶段匹配取消，原请求保持且最后真实回执后才完成；同沿data/cancel取消不接受data。 |
| T05错误 | AW06 | header/body BRESP错误给安全DONE；错误与取消同存在优先错误；wrongBID UNKNOWN进入Q无DONE、不得再启动；共同cold后恢复。 |
| T06反压 | AW04 | random停顿/header/body气泡/ack及done延迟消费，公开body、请求、AXI、pair保持；输出不重复不丢失。 |
| T07授权 | AW08 | R_WORKING/DONE查拒绝；实际OFFER/APPLY后精确lookup许可；错误sequence/Origin被拒；每行AR范围与R实际字节对应，ANN不读取头部。 |
| T08尺寸 | 全 | W34/H20与W6/H2或W4/H2、小尺寸跨字节尾零；1920×1080全部头/像素/行，不以缩图替代生产几何。 |
| T09工具 | L | fatal probe必须非零且特定标记，无伪success；实际vlib/vlog/vopt/vsim/independent audit退出0且末尾current/snapshot hashes一致；随后MAP读真实资源报告。 |

初始化seed及正常输入期望公式来自测试环境，不读取DUT私有数组作为期望。独立审计对真实W/AR/R、请求响应因果、header/body输入、frame/done/read输出做完整闭环；允许只dump实际内存作额外校验，不能预装ANN期望。错误场景日志保留，不以重跑覆盖失败。

## H. 双向追踪

| 要求 | MOD/IF/操作 | 代码符号（计划） | TEST |
|---|---|---|---|
| AW01 | MOD1/IF01/步骤1..2 | canonical_job,IDLE,JOB_REPLY | T02/T08 |
| AW02 | MOD1/IF03/步骤3..5 | header_count,header_buffer,HEADER_* | T01/T03/T04 |
| AW03 | MOD1+MOD2/IF03b/步骤6..7 | body_sink,body_bad,BODY_* | T01/T03/T08 |
| AW04 | IF02/04/06/08 | state-derived公开valid,寄存payload | T04/T06 |
| AW05/06 | MOD1/IF06/步骤4..8 | cancel_sticky,finish_job,Q | T04/T05 |
| AW07 | IF06 | done_*输出,header_count,body_count,body_lines | T01/T03..05 |
| AW08 | MOD3..5/IF05/07/08 | BFM实际字节、TB真实owner及reader、独立audit | T01/T07/T09 |

本批测试反向仅证明上表要求；复杂识别、RAW/Canny新执行、物理DDR、HDMI TMDS、全工程PNR/STA不可从本批证据推导。

## I. 设计门槛与评审

①整体行为/正常错误样例在B；②职责复用在C及实际源码调查；③接口布局/相容检查在D；④局部状态/中文操作/不变量在E；⑤语言三份契约在F；⑥正常/取消/未知闭合路径在B/D/E；⑦实施验证追踪在G/H；⑧本组件无当前阻塞、后续缺口明确；⑨文件保存后必须真实读回并向用户呈现入口、随后冻结；⑩版本/范围/工作路径/基线在A/G。依持续授权执行，不额外索取重复批准；本地审计例外仅独立软件工作。

## J. 变更与恢复

冻结v1后发现接口/关键结构变化先更新具体变更卡、读回及当前源追踪，再按已有持续授权实施；保留旧输入和失败尝试。此前只读调查一次误写服务路径production而实际在services，未修改源或启动工具，已从实际runtime_sources恢复。

## K. 实现与验证实录

尚未生成本批新业务代码，尚未执行本批仿真/MAP；后续填写实际输入哈希、源码路径、命令、结果和限制。已有v28证据不能当成本批通过。正式PostgreSQL未配置，使用已授权的本地追加审计；H0硬件状态保留。

## L. 交付、失败处理与恢复

Artifacts：本设计及baseline → README阅读顺序 → RTL/参考/TB → 不可覆盖的runs与末尾源哈希 → completion-review/resource-result → staging manifest。失败立即保留真实日志，定位真实代码/设计，不跳过检查或改期望凑通过。Rollback只停止使用本独立组件，旧产物保持。

Completion criteria：本批AW01..08在实际当前源码上通过相应仿真/独立审计并完成真实component MAP和登记；整体目标继续，不能以本批完成标记全工程完成。理解验收尚无用户实际作答，待检验但不阻塞已授权软件实现。人工硬件下载、观察和正式状态转换均不在本批。
