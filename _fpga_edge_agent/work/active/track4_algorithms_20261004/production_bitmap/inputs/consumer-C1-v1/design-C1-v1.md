# PB-C1 v1：位图写入、A64账本与实际显示行消费的联测草图

## A. 范围、基线和前置

本卡细化TRACK4-PRODUCTION-BITMAP-001 v1的M3、PB-T2/T3/T4/T5，生产行为和原完整目标不变。当前READY_FOR_REVIEW；保存、读回和呈现后，按用户“当你统计完后自行进行，无需我的批准”及本批本地审计例外自主实施。不伪造新的指定版本聊天批准，不更改正式数据库/H0/Manifest或硬件状态。

事实：v25，实际1bit/8bit producer五次仿真及当前MAP已通过；实际HD packed259200B、1078边缘与旧2073600pixel逐位相同；owner/reader的A64参数还未做行为联测。上一goal turn分类PROGRESS。当前无活跃工具，不能重复启动旧run。

独立补充基线consumer-baseline.json冻结19项：当前sink、edge writer、owner/pkg、row pkg、reader/meta、span、write-pair、line bridge、native RAM、既有数学duplex BFM共12源；本卡、规范；已PASS HD的golden Source/packed结果、vector summary、source manifest、reference audit共5证据。主baseline67项和已验证producer52源保持不变。19项不冒称19份新增代码，存在与主基线重叠的来源。

工作仍在production_bitmap。计划新增4份：tb/axi128_bitmap_frame_memory.sv、tb/tb_bitmap_display_contract.sv、model/bitmap_display_reference.py、scripts/run_bitmap_contract.ps1。既有生产RTL不改；新TB显式实例化FRAME_ALIGNMENT=64及ITEM_BITS=1。

## B. 整体观察与边界

真实edge writer接收按index排序的1bit→实际write-pair/bridge→AW/W/B数学后端→真实owner的RESULT_END/OFFER/APPLY→真实display_row_reader/native meta RAM→公开pair54。数学Source/ANN可以明确预置，EDGE从poison字节开始，必须由实际W写成位图，不能直接把期望结果放进EDGE。

真实owner提供slot/handle/CJ/Origin/policy/三个描述；Source的SOURCE_EOF/END表示受控预置Source已完成，是测试环境声明。RESULT_END的成功证据必须来自实际writer DONE、count=N、无error/abort且drained。该路径是组合接口验证，job_permitted由受控测试给定，不是生产FrameRef/RO查询、CSI、DDR PHY或扫描授权证明。

正常：先全1，后全0，再复用原result slot写全0/棋盘/稀疏，期间不cold；完整读回所有画内pixel和末笔物理padding。模式0..5均由真实ALLOC_RESULT时锁定的render snapshot生成，不能事后伪改OFFER的mode。mode1/2只有RGB，EDGEd描述为0，不启动edge writer，不虚构edge生产完成。

HD：只做一幅完整1920×1080、mode4；输入Source/edge取先前已独立验证的golden文件，writer重新真实写全部bit，reader消费1080行。期待直接由独立golden RGB/bit构成；是消费阶段复现，不能叫作同一生产控制器已经自动整合。

## C. 连接、固定地址与数学内存

writer配置/id/index/edge→64B RPC→write-pair客户端0；客户端1无请求。reader仍使用内部实际span→同一数学后端的AR/R。一个写和一个读口互相独立，事务/held正文按现有契约。owner命令和回执941/942，row ticket543，pair54={ann4,edge2,rgb48}。

后端只映射受控帧窗口，不宣称真实DDR容量模型。令S=A64(3N)，E=A64(ceil(N/8))，A=A64(4224+ceil(N/4))，紧凑数组容量6S+3E+3A。物理Source slot s范围[s*8MiB,s*8MiB+S)，索引s*S+offset；result slot r EDGE在0x03000000+r*8MiB、长度E，索引6S+r*E+offset；ANN在相同result base+1MiB、长度A，索引6S+3E+r*A+offset。别处一律非法，不把slot间空洞别名映射成已有字节。

逐事务检查起止映射都合法、紧凑索引连续、A16/A64、长度/ID/4KiB与实际AXI规则一致。所有AW/W实际更新数组，R只从当时数组读取。Source数学公式按slot产生不同RGB，ANN有效2bit字段按Source slot公式预置；Source/ANN未用padding为0，EDGE初始0xA5。HD slot0 Source从冻结golden读入。初始化仅共同可信cold，连续正常帧保持旧EDGE字节。

## D. 内部中文操作与语法组织

数学后端：沿用已读duplex BFM的读/写状态，新增map_byte(address)函数和描述范围检查；去掉class首写捕获（本消费后端没有class算法口）。首次cold清事务并初始化受控数组，之后rst保持不重复初始化。正沿真实AW锁地址/固定4拍，W按strobe写低byte，真实末拍后延迟B；AR锁地址/长度/ID，R公开后valid与正文保持到fire。故障只来自锁定fault_kind，不从ready反推数据。

TB数据/控制分开：owner_exchange任务先锁完整command，在负沿置valid，正沿fire后撤销；回执holding若干沿再接收，保存真实reply。ALLOC_SOURCE→SOURCE_EOF→SOURCE_END(受控源闭合)→ALLOC_RESULT；对有EDGE的模式配置writer，cfg回复握手后逐pixel推进。一个待发送pixel遇ready0保持id/index/edge；DONE停顿保持count/error/aborted/drained。实际writer结束成功后才能RESULT_END flags7；随后OFFER保存原op5 bundle，APPLY更新真实账本。先前frame所有行/回执闭合后以真实RETIRE flags0x0A释放；不cold强制回收。

reader任务：从不可变OFFER建立row ticket，generation/sequence/scan/result/policy/Origin完整；mode0按上下半屏选择Source/EDGE且source_y为2*(target_y mod H/2)，mode1/2 mask1、mode3 mask2、mode4 mask3、mode5 mask7。job/cfg holding后逐pair接收，验证out_generation、address顺序及expected_pair，最后等待真实DONE和prepared/delivered=P。mode与header错误拒绝不得产生AR。

期望独立函数：RGB从Source byte顺序R/G/B形成lane0低24、lane1高24；edge由输入pattern或冻结golden位，不从后端数组/reader cache取期望；ANN由独立2bit公式。边缘pattern涵盖全1、全0、棋盘、稀疏。数学数组只作实际W/R效果与最终padding导出，不能作DUT期望oracle。

negative任务隔离：非法cfg基址/32位end溢出应cfg error且无AW；wrong index/handle应实际DONE error，不发布成功；取消held RPC时只把相邻测试ready关住，req正文保持，放开后必须真实写/回复闭合；error且drained1为安全失败，drained0或错误BID会隔离，cfg不可重用。UNKNOWN案例之后只允许与数学后端共同可信cold。wrong abort id不取消本job。reader测试未授权、旧A16容量（当与A64不同）、错误Origin/handle/mode/长度。所有场景记录实际事件，错误不能直接写PASS。

## E. 时间、语言与日志

SystemVerilog、core clk10ns；TB负沿驱动、正沿采样旧valid/ready。sync rst高有效，owner safe_reset_n=!rst沿用其释放管线；native RAM沿用实际模型。整数map索引只在确认物理范围后计算；positive参数W=6/10/34/1920、H=6/8/20/1080，N<=2073600。矩阵只适用于消费者旧偶数高契约，不改变producer H>=5范围。

稠密数据仅属于数学后端，不是FPGA RAM预算。核心状态资源未增加。Source fixture和ANN初始化是环境输入；在途cancel/holding、writer计数、RPC→AXI因果及row pairing是时间契约；Python只重建数值和公共事件，不能用函数末值替代实际握手。

日志使用case/cycle/event/payload文本，记所有实际cfg/pixel/RPC/DONE、owner cmd/reply、row job/reply/pair/DONE及AW/W/B/AR/R；停顿用公开正文记录并逐沿检查。HD不逐沿记录全零端口，避免几十GB无效日志；实际fire及holding事件不能省略。Python流式审计：按输入pattern/golden重建已接受pixel、512bit分组、真实W字节、R返回及pair，检查描述物理容量和闭合条件、引用身份、数量及无效尾0。

## F. 验证、追踪与完成条件

先真实fatal探针，再三种小尺寸、完整所有行/模式及局部故障；最后HD mode4的全N写入和全H行消费。脚本先验证19冻结输入、复制当前15源（11复用RTL/包/native模型+2TB+参考+脚本），再真实vlib/vlog/vopt/vsim/audit、进程及日志SHA。实际清单和SHA在运行前逐项核对，不以草图数量断言完成。

PB01/02→真实writer/W/padding→连续ones/zeros/复用slot及full HD；PB04→实际owner allocation/op回复→三尺寸Source/EDGE/ANN容量及旧A16拒绝；PB05→真实reader/span/native→全部行、mode0..5、bit/RGB/ANN独立pair；PB06→cfg错/index/handle/cancel/安全错误/UNKNOWN/cold→公开事件及holding检查；PB07→四份验证代码/快照/fatal/独立Python→真实工具和SHA。

§10.3检查：整体、职责/连接、实际接口与映射、状态/中文操作、语言/时间/存储、正常/异常走查、实施/验证/双向追踪、当前无阻塞、保存读回呈现、v1与19输入范围均有实质内容。当前尚未生成C1代码或运行其测试。READY后按持久授权实施，未来生产RO、持续显示及PHY另闭合。

生产RTL不改，遇真实实现错误先修订卡及受影响范围，保留失败。新attempt不能覆盖，故障恢复不删除旧证据。消费测试全部通过、v1producer证据仍匹配，才登记完整本增量；用户理解验收待实际作答，硬件状态不由软件PASS代签。
