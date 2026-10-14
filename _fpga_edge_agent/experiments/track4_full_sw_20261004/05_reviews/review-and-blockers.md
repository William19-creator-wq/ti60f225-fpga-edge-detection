# 05 整体草图审阅、阻塞与批准边界

> 2026-10-04 当前优先范围已改为[算法路线 v1](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)和[新目录](../../track4_algorithms_20261004/README.md)。停止原具体器件/PHY模型和 DDR/IP 预检推进/审批；旧相关表/阻塞项是历史整机范围，新R1采用独立算法接口与新基线，不能以本页旧依赖拦住它，也不能将算法局部通过升级为整机完成。


任务TRACK4-FULL-SW-001；整体架构v0.1、主计划v0.21；2026-10-04。FRONTEND局部审查见第7节，FRAME-MANAGER与底层来源复核见第8节，CANNY见第9–12节，DDR-SERVICE见第13节，RECOGNITION见第14节，PLATFORM与摄像头来源见第15节，CAMERA详细设计见第16节，DISPLAY见第17节、CONTROL见第18节、控制联合见第19节、数据联合见第20节、数值/官方依据见第21节、识别算法候选见第22节，内部执行见第23节。

## 1. 本轮可交付与不能冒称的状态

整体布局阶段已完成目录、需求/基线、整体布局、系统级接口/组合走查及验证追踪。用户随后要求继续完整软件实验；当前推进到详细局部设计，尚未获准生成业务代码/功能脚本/testbench，也未执行综合、仿真或PNR、联网/下载或正式状态/DB修改。

“整体布局草图完成”是先前阶段结论。**整机未达到业务实施READY_FOR_REVIEW、用户未批准局部设计或实现。**首批FRONTEND已有详细内容，其独立局部状态见主设计；外部模型及实际约束仍阻塞整机。审批沿用原制度，文档不创建第二套授权。

## 2. 实际只读审查要点

| 审查 | 发现与处理 |
|---|---|
| 前置基线审查 | v6实际60项引用均存在；实际CSI5.15/70与备用5.16/50分开记录；SDC占位/clock矛盾明确保留 |
| V4模型重查 | 用户精确V4根4523展开文件、16落地压缩包目录共2216成员；v3.zip内嵌rtl/ddr3_controller.zip另查22成员；未发现完整2Gb器件包。存在controller/PHY/calibration，不能表述为没有DDR工程 |
| 源池审查 | 整体阶段改为6源槽预算；后续第8节发现capture须包含EOF排空，持续采集还需要期限证明，旧六角色占用估算不能单独保证下一SOF有空槽 |
| 结果审查 | 完成写响应后才发布；3结果槽/1pending，资源预留先于源领取；等待VSYNC不锁DDR |
| 带宽审查 | 全部DDR重读会额外373.248MB/s@60fps；整体提议基础同源流计算、显示即时原灰度、边缘位打包，明确仍需局部吞吐证明 |
| 资源审查 | 60800XLR/256RAM/160DSP来自实际报告；RAM10模式显示粗比特数不能证明端口/碎片；识别2.8Mbit私有预算不当作可放置承诺 |
| 范围纠正 | 用户撤回两组识别参数；全部转为开发比较轴，不是hard requirement。另行95%指标保留 |

VF与Demo精确目录的追加核查已完成，见下表；不把文件名/文本/归档检索扩展成全部PDF逐页OCR结论。

### 用户补充路径的DDR模型复核

| 用户目录 | 实际检查范围 | 结果 |
|---|---|---|
| V4完整资料包/Ti60F225_DemoBoard_v4 | 4523展开文件、16落地archives共2216成员；v3内嵌controller ZIP22成员另查 | 有controller/PHY/校准和AXI帧缓存测试，未发现匹配2Gb芯片模型/2048Mb参数头 |
| VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包/VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009 | 11672展开文件、13落地archives共1281成员，相关模型全文/字节哈希 | 24份展开模型及2份SC1336 ZIP内模型，均4Gb/x16，未找到2048Mb头 |
| Demo/Demo | 5254展开文件、2落地archives共574成员 | 展开目录无器件模型，但IMX219 HDMI ZIP内有1份4Gb/x16模型及4096Mb头，未找到2048Mb头 |

两根新增路径中27份已找到模型字节SHA256相同：`AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA`。文件第97/98行固定den4096Mb/x16，第122/123行虽有2Gb分支，但要求缺失的2048Mb_ddr3_parameters.vh。不能只修改宏或限制地址就宣称匹配2Gb器件时序。

本轮重新实际枚举两个用户根及三个相关ZIP：VF 11,672个展开文件中24份模型与24份4096Mb头，两个SC1336 ZIP各567成员且各1份模型；Demo 5,254个展开文件，IMX219 ZIP568成员含1份模型/4096Mb头，另7z6成员为Python/TFLite/H5。27份模型默认4Gb/x16，2Gb分支仍引用缺失2048Mb头。Demo另有`tinyml-main/tinyml_hello_world/Ti60F225_tinyml_helloworld/src/ddr3_controller/ddr3_parameter.vh`，ROW14/COL10/BANK3/DQ16是控制器配置，不是器件行为模型参数头。模型主体和2Gb条件分支存在，缺口要精确记为与V4 MT41J128M16JT-125匹配的2048Mb参数/时序依赖与配置，而不是“VF/Demo没有DDR模型”。

精确定位：

- VF代表展开文件：`06-FPGA_HDL_Basic-2023.2/06_MIPI_LCD_Test_1024600/ip/DdrCtrl/Testbench/ddr3.v`。
- VF：`07-FPGA_HDL_Image-2023.2/07-1_Ti60_SC1336_HDMI_1280720.zip`内`Ti60F225_SC1336_HDMI_Display/ip/DdrCtrl/Testbench/ddr3.v`；另一SC1336 LVDS ZIP同类。
- Demo：`Ti60F225_IMX219_HDMI_1080P.zip`内`Ti60F225_IMX219_HDMI_1080P/ip/DdrCtrl/Testbench/ddr3.v`；其中efx_ddr3_soft_controller_tb.v及modelsim_AXI4.do也指定4Gb。

全部上述落地archives目录读取退出0。VF驱动ZIP内嵌7z与落地副本哈希一致且已列成员；V4相关嵌套controller ZIP已内存读取；Demo无嵌套archives。“创建和导出模型.7z”是Keras/TFLite材料，与DDR不同。未逐页OCR全部PDF、未穷尽任意二进制内嵌数据；检查范围内未发现匹配器件专用数据手册文件名/文本命中。

## 3. 阻塞清单及影响

| ID | 问题、受影响范围 | 解决方式与可独立继续部分 |
|---|---|---|
| BL-01 | 缺匹配MT41J128M16JT-125 2Gb模型、依赖与完整器件资料；A3/IF-04/13 | 已检查本地范围；官方/供应商获取需原规则授权。整体职责/文档可完成，整机实施前先补齐 |
| BL-02 | CSI/DDR/HDMI保护IP在Questa与模型/PHY相位/校准兼容未实测；MOD-01 | 完成窄预检设计、指定批准后编译展开/校准，不强制通过；本轮只有计划 |
| BL-03 | USER_PERIOD、byte clock矛盾、exclusive例外、跨PLL/复位和最终V4 pin/bank核对未完成；MOD-01/11 | PLATFORM v0.1及原理图/封装v2已核主要球号/板电源、KEY1、NC、14位地址和PN交换；真实发端模式/CDC、当前pin生成电气、冷复位/PHY与有效SDC仍待证，不直接复制旧约束 |
| BL-04 | 相机模式fps、RAW相位、Debayer数值和4输入→2计算瞬时突发未固定；MOD-02/03/06 | 冻结可模拟输入合约/四色相位、最坏突发/FIFO；真实相位/fps待实物 |
| BL-05 | 整机各局部契约尚未全部完成 | FRONTEND已细化MOD-06/07；FRAME-MANAGER/CANNY已有草图/反例/数值/有限存储，FM-B01…08及CN-B01…08未闭合；DDR/CDC/控制/显示/识别继续设计，不能扩大为整机READY |
| BL-06 | 识别范围/候选容量/累计配置/独立验收集与真实资源尚未确定；A6 | 比较质量—吞吐—资源，冻结最终范围/开发集和独立验收集，保留失败；不恢复撤回参数 |
| BL-07 | S1的DDR“硬核控制器IP”措辞与V4软DDR参考路线需要明确解释；A3官方完整提交 | 保留原文及实际路线，核对官方/供应商适用性；本次假定V4软件实验不宣称官方措辞已满足 |
| BL-08 | 正式DB/状态机环境未验收；隔离实验之外 | 本轮不依赖DB执行正式节点，不创建替代DB；正式流程需原健康/审批门槛 |

## 4. 分批设计及评审次序

整体需求/基线和布局先呈现；然后平台与DDR模型预检、显示/采集与帧管理、灰度/窗口/Sobel、median/threshold、完整Canny、overlay/recognition、整机交付按依赖形成任务设计。A3底层存储能力前置于整机，但其冻结交互仍独立追踪。

每一批完成当前范围全部v0.2要求：行为和样例、职责连接、接口/组合检查、局部数据与中文操作草图、RTL与跨语言契约、验证/追踪、无正确性阻塞、保存读回呈现、版本范围基线清楚。到READY_FOR_REVIEW再等待用户明确批准该版本/范围/基线。已有效的同范围批准不重复要求，重大契约变化另行修订。

用户先批准目录与整体草图，随后要求按规则完成完整软件测试。该总体目标继续有效；指定局部版本的实现批准及先前FIFO-SMOKE-001的批准不能由此虚构。官方资料联网/下载问题尚未收到明确答复，已保存REQ-DDR3-MODEL-20261004 v1申请。

## 5. 检查结果入口

文件读回、链接/ID/需求覆盖、前后基线一致性和本轮完成审计记录在本文件后续检查段。设计分析、文档检查、编译、仿真、综合/时序和实机分开记录；未运行不得填通过。

## 6. 整体布局v0.1阶段的实际读回与完成审计（历史）

操作标识：TRACK4-FULL-SW-001 / DOC-20261004-OVERALL / READBACK-01。来源是当前用户明确请求本地目录与整体草图；这是隔离文档记录，不冒充数据库事件、正式审批或硬件观察。

已从磁盘读回12份Markdown（含planning主任务），逐项检查章节/UTF-8文本、整体普通文本与Mermaid源码图、S-01…04、IF/CC和REQ映射。独立只读审阅发现并修正：IF-08的RGB/Y8箭头冲突、RETIRING旧显示读排空前占槽、DDR失效/无法排空时的独立安全图案与槽隔离。对图源码和文字语义已检查；没有声称做过图形渲染截屏或业务仿真。

当时的自动文档检查结果保存在[document-checks-overall-v0.1.json](document-checks-overall-v0.1.json)：10分类目录、12Markdown、11项T4要求在需求与追踪中均出现、12模块、14系统接口、4整体中文操作草图、主模板A–L均存在；相对阅读链接与代码围栏无错误；24项选定输入SHA256无漂移。它是旧版本快照，不用于证明后续修改文件仍匹配旧哈希；当前检查另见第7节。

| 本轮目标要求 | 权威证据 | 本轮结论 |
|---|---|---|
| 在控制面创建专用结构化文档目录 | experiments/track4_full_sw_20261004真实目录、README及00–09文件 | 已完成 |
| 整体图之前的目标/需求/规则/基线整理 | 00、01、24项输入清单、实际v6 XML60/60引用及三份材料搜索记录 | 已完成本地可执行调查；外部模型缺口明确 |
| 整体设计布局草图 | 02输入/双路径/模块/数据控制错误图、帧和配置协议、时钟/资源预算、S-01…04 | 已完成v0.1整体草图，未冒充局部设计 |
| 模块交接及组合考虑 | 03 IF-01…14、CC-01…11、正常/拥塞/冻结/故障走查 | 已完成系统层说明，详细物理/逐拍待后续 |
| 分类、阅读/生成顺序及后续管理 | README次序、04/05/06/07/08/09职责与主模板 | 已完成 |
| 文档保存读回、原资料和状态不改变、无越权实现 | 文档读取与哈希；工作副本不存在，实验新增类型仅md/json | 已检查本轮指定范围 |

当时的阶段目标止于整体草图，完成该阶段不要求把BL-01…08写成已解决。用户随后已要求完成完整软件实验；该目标仍未完成。完整软件实现/仿真/综合/PNR/STA/bitstream仍未执行，理解与硬件验收也未执行。

文档SHA256在检查JSON列出（JSON本身不作自包含哈希），若后续文档修订则版本化并重新检查。新的独立工作副本仍需对应授权。

## 7. 当前推进：FRONTEND v1 与完整目标

[FRONTEND主设计](../../../planning/design-TRACK4-FRONTEND-001.md)细化灰度、两个两行窗口、并行中值、Sobel、单job配置/协议、独立参考与仿真入口；[复核记录](frontend-review-v1.md)记录三个审查方向及已修正问题，[中文阅读与人工观察路线](../04_local-designs/frontend-reading-guide-v1.md)给出先整体、后交接、再内部和波形的次序。

本批输入基线FE-BL-20261004-v1实际记录28项SHA256；业务文件和测试仍未生成。当前文档检查保存在[document-checks.json](document-checks.json)，独立于第6节历史快照。局部设计READY只意味着可以交给用户批准；不表示实际RTL/仿真通过，也不消除BL-01/02/03/04/06/07或其他局部工作。

本阶段原16份文档检查另保留为[document-checks-frontend-v1.json](document-checks-frontend-v1.json)历史快照；以后修订的主计划/索引不能用该旧快照证明现状。

## 8. 后续推进：帧所有权局部稿及底层证据

[FRAME-MANAGER v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)处于LOCAL_DESIGN。已形成8项要求、8个交接语义、8项中文操作草图、10条不变量、12项文字测试及双向追踪，实际业务均未生成。

| 独立审阅方向 | 发现与文档修正 |
|---|---|
| 所有权与持续采集 | 六源证明把EOF后WRITE_DRAIN纳入写租约；给出六槽全占且下一SOF无空槽反例，保留最坏排空/QoS或槽数修订条件 |
| 显示与冻结 | core DISPLAY影子可能落后真实active；设计显示快照hold、先加FREEZE后移交、pending撤销排空；RETIRING可同时两槽 |
| 同沿与启动 | 生命周期命令不能撤销已握手job，需下一ACTIVE沿取消；NO_ACTIVE分支保留策略屏障，明确已有latest/同沿完成/等待首帧；合并所有引用后统一回收源 |
| DDR实际调用链 | [来源笔记](../01_baseline/ddr-address-and-completion-evidence-v1.md)：可读master字节寻址；旧bank_sw按末W拍，不检查B响应；默认参数未转发导致实际槽间距与顶层960参数直算不同；受保护slave行为仍未证 |
| 平台时钟/引脚 | [来源笔记](../01_baseline/platform-clock-pin-evidence-v1.md)：四PLL和实际core来源、CSI70/SDC100、USER_PERIOD/exclusive、复位与资源映射已定位；不输出未经验证SDC或引脚通过结论 |

DDR笔记经独立读回，收紧“upsizer角色”及“新完成契约提议/原源码事实”的区分；帧稿经独立读回复核并修正上述同沿/启动/回收问题。邻接物理端口、bundle位宽、显示水位、DDR fence/安全复位、采集尾响应、身份回绕仍明确在FM-B01…08，不将章节齐全当READY。

本轮未修改FRONTEND v1及其28项冻结输入；未收到新的实现或官方模型获取批准，现有两项问题继续待答。当前[文档检查](document-checks.json)包含新增局部稿和来源笔记；它只验证文件/链接/ID/基线，业务功能测试、编译、综合、PNR/STA、bit与实物仍NOT_RUN。

上一轮19份文档审计另保存为[document-checks-frame-v0.1.json](document-checks-frame-v0.1.json)历史快照；本轮修改的主计划/索引由当前检查重新绑定。

## 9. 完整Canny局部设计推进

[CANNY当前v0.4](../../../planning/design-TRACK4-CANNY-001.md)及[数值/存储历史审查v0.1](canny-review-v0.1.md)已保存，状态LOCAL_DESIGN/NOT_APPROVED。数值、完整八邻域可达定义、有限队列和缓存候选已写成可读操作草图，实际实现/测试未生成。

新增设计工作明确了高斯5×5单次舍入、Gaussian后的新Sobel、424整数方向和NMS相等政策；2bit状态单引擎claim、单调N队列、提交范围和本地forward；FE状态及时消费、分叉分别一次、取消不能撤销已承诺DDR突发。独立读回修正灰度/幅值命名、C4方向提供方、尺寸组合拒绝、停顿RE/WE和取消同沿前缀语义。

资源/流量只有推算：v0.3共享FE+Canny窗口+state cache+queue小计40RAM10；v0.4新增writer4后小计44RAM10，见第12节，其余平台/显示/识别未计；64B线最坏随机miss可能比16B更费流量，需实际比较。没有借资源优化缩短弱链或采用固定迭代闭包，也没有以HDMI60Hz冒充Canny处理fps。

CN-B01/02的窗口执行输入在v0.2补齐，仍需与完整父端口及批准基线统一；CN-B03/04的具体存储候选在v0.3补齐，仍有父端口/基线统一及CN-B05…08阻塞READY，v0.4父任务/方向/writer和地址已补候选；阻塞继续涵盖实际服务、父grant/fence/恢复、六源期限/识别租约和真实资源/性能。当前检查只证明文件、链接/ID和输入基线一致；不证明完整软件实验完成。

## 10. Canny窗口/流段草图v0.2

详细[中文窗口附件](../04_local-designs/canny-window-sketches-v0.2.md)按边界→四行Gaussian→水平/算术→两行NMS/分类→C0/分叉阅读；三项独立只读复核及修订见[审查v0.2](canny-review-v0.2.md)。新文字T15…18补TAIL、byte平面/外框、启动/FS及时保存和fork旧新提交，所有业务场景仍NOT_RUN。

已落实的设计修订包括有效TAIL而非数值气泡、真实输入r与输出中心y分开、NMS历史保留外框原Mgrad、RAM8bit平面与288bit窗口、共同start分沿、EOF/empty/封口/fence不同证据、fork新pending覆盖旧清位。局部首末沿是条件推导，不能替代仿真或整条固定延迟证明。

VF代表展开模型及Demo IMX219 ZIP本轮再次读回，默认4Gb/x16与缺失2Gb参数头结论不变；没有联网/下载。前轮21份文档检查保存在[历史快照](document-checks-canny-v0.1.json)，当前文档重新审计；FE v1/28项输入、FM v0.1和正式状态不变，既有两项待答申请不重复创建。

## 11. Canny存储/队列草图v0.3

[存储附件](../04_local-designs/canny-memory-sketches-v0.3.md)按窄内存合同→cache映射/FSM/原子claim→滑动银行/prefix/共享口→pop/prefetch→阶段阅读；三方向独立只读复审及实质修正见[审查v0.3](canny-review-v0.3.md)。新T19…22覆盖真实RAM组织、WB用途/失败、cancel安装与claim、256−p容量、分段/早失败terminal、局部tag退休和旧cache padding；全部22场景NOT_RUN。

本稿采用每segment承诺；取消后结清已提出段、未提出后段可丢弃，逻辑descriptor失败时c不推进。失败drained terminal明确终结未接受逻辑W/R，物理承诺必须先已排空；未知排空继续隔离。cache/queue等待不能停止后台writer/响应或已grant读capture。

用户补充的两个目录再次只读核对：VF展开11672文件中的24份ddr3.v哈希相同，另两个SC1336 ZIP各1份，Demo展开5254文件及IMX219 ZIP1份；共27模型默认den4096Mb/x16，den2048Mb分支均引用未找到的2048Mb_ddr3_parameters.vh。原文件/ZIP没有改写、解压落盘或执行。

前轮23份文档审计保存为[历史快照v0.2](document-checks-canny-v0.2.json)，[当前检查](document-checks.json)重新绑定修订后文件。FE v1/28项输入、FM v0.1及窗口v0.2不改；CANNY保持LOCAL_DESIGN，真实MOD-05/2Gb PHY、完整父端口/地址/性能未闭合，既有两项申请仍待答。

## 12. Canny父任务/方向/writer草图v0.4

[父任务附件](../04_local-designs/canny-parent-writer-sketches-v0.4.md)按完整job/地址→新Sobel/四方向→顺序writer→local terminal/fence→23阶段/快路径→冻结status/复位保持/安全恢复阅读；三方向只读审阅及修正见[审查v0.4](canny-review-v0.4.md)。新增T23…26，全部26业务场景NOT_RUN。

[12区地址算术](../01_baseline/canny-candidate-address-arithmetic-v0.4.json)按最小物理A与4KiB槽分配区分，紧凑55,209,600B、页分配55,226,368B，加低4KiB保留后终点0x034AC000。六源持续接纳依赖最坏排空期限，数学非重叠不代替真实DDR映射/grant。

新writer4 RAM10使已列共享FE/Canny窗口/cache/queue/writer小计44，未包括MOD-05物理缓冲、平台/显示/识别；方向/ctx/银行元数据也只是候选预算。LOCAL_OK在stage fence前独立保存，复位保持域继续承诺valid/payload/pending/实际握手记账，隔离status一经提出不随live排空更改。

本轮只读重查用户指定VF/Demo展开目录，确认24个VF模型/24个4096Mb头和默认4Gb/x16，仍无独立2048Mb头；先前含三个压缩包的27项记录范围保持明确。原参考未改。

前轮25份文档检查保存为[历史快照v0.3](document-checks-canny-v0.3.json)，当前检查绑定新文件。FE v1/28项输入、FM v0.1、窗口v0.2和存储v0.3保持不变；CANNY仍LOCAL_DESIGN，既有两项申请未获新答复，不重复发起。

## 13. 共享DDR服务局部稿v0.1

[DDR主设计](../../../planning/design-TRACK4-DDR-SERVICE-001.md)及[三方向实际读稿审查](ddr-service-review-v0.1.md)保存8要求/8接口/8中文操作草图/10不变量/16文字场景，状态LOCAL_DESIGN/NOT_APPROVED。授权与事务分层，整体R/W完整段缓冲、物理owner与逻辑消费独立，阶段fence覆盖OUTPUT真实CLASS导出读。原FE/FM/Canny/窗口/存储/父writer/地址文档未修改，新相邻差异在DDR稿D3公开保留。

复审已修正producer封尾/dirtyWB与seal互等、terminal后pending复活、取消与首次物理valid同沿冲突、首min(2,n)预取条件、release等待池FREE的循环、14叶请求公平、每scope/client的28bit阶段关闭图、历史J/mask及冷scope引用/原子快照。真实protected/2Gb模型、父/显示/采集端口、Q恢复及QoS仍DS-B01…08，不声称READY。

[RAM来源](../01_baseline/ddr-service-ram-evidence-v1.md)给数据池各7块20×512与metadata3块映射：服务17块，Canny44+服务17=61/256=23.828125%；先前58仅含数据池。大元数据FF、平台/相机/显示/识别及实际时序另计，模式/算术不能作为放置结果。

前轮27份MD审计保存在[历史v0.4](document-checks-canny-v0.4.json)；当前检查重新绑定新增设计和索引。24原输入/FE28冻结输入与正式状态不变；现有官方模型获取和FRONTEND实施两项申请继续待答，不重复发起。业务RTL、测试、仿真、综合、PNR/STA、bit/hex均未生成/未运行。

## 14. 圆／矩形识别与同源标注局部稿v0.1

[识别主稿](../../../planning/design-TRACK4-RECOGNITION-001.md)按整体→职责→8交接→四phase→8中文草图/10不变量→数值资源→16文字场景/追踪保存，[实际读稿审查](recognition-review-v0.1.md)记录三方向只读核对。完整grad32而非旧幅值/dir2用于法向；32散桶各16B对齐/尾half补零，POINTS与SORTED数量/范围分开；工作TEMP与结果ANN所有权不同。

[追加地址算术](../01_baseline/recognition-candidate-address-arithmetic-v0.1.json)保持原12区不变，新增34,856,960B；五TEMP分别按精确A授grant，META/SORTED/ANN页gap不授。9 PROCESS/25总grant仅条件峰预算。圆累加/矩形Hough分时17块，段/峰/对/终表/row/流buffer独立，识别58加已有61为119/256，仅已列容器小计，算术/DSP/平台/完整控制与STA未验证。

RC-B01…08保留候选覆盖（图外中心/同格多圆/法线误差）、半径多峰/数值细状态、三边歧义/端点分段、父AUX/ANN/phase/status、真实PHY/恢复/期限及独立95%质量。所有RC测试NOT_RUN；不恢复先前最多4等撤回范围。实际读稿修正零梯度政策（CN-04/05证明合法EDGE必非零）、θwrap rho翻号、TLS宽统计/容器区分、独立返还ACK先于完整status冻结。

前轮30份Markdown DDR审计保存为[历史v0.1](document-checks-ddr-v0.1.json)，[当前检查](document-checks.json)绑定本轮32份文档。FE28/原输入24与FM/Canny/DDR/既有附件/地址保持不变；未收到业务或模型获取新批准，不重复提问。完整目标仍未达成，正式状态/DB未改，软件功能仿真、综合、PNR/STA和bit/hex均未运行。

## 15. PLATFORM v0.1与SC431来源复核

[主平台稿](../../../planning/design-TRACK4-PLATFORM-001.md)→[读稿审查](platform-review-v0.1.md)，8要求/8交接/8中文草图/10不变量/16文字场景，A–L已保存；仍LOCAL_DESIGN，PL-B01…08。scope镜像ACK前不授物理承诺，故障保存完整旧集合；PREPARE先身份授权处置已被真实物理恢复取消的旧数据/借用，FINAL收0x3F证明，旧Q不改成功。新PHY不得重吃旧exposed valid，warm reset不清保持域。

[原理图/封装v2](../01_baseline/board-pin-source-evidence-v2.md)核KEY1/P13、25/27MHz、DDR主要球号/板电源与14地址、HDMI四路PN交换及HPD/DDC NC；[摄像头v1](../01_baseline/camera-source-and-phase-evidence-v1.md)核原ROM先stream-on后crop/mirror、条件T4差异、高层不验NACK/AL、Bayer原始读出坐标与裁剪/flip条件推断。不能把BGGR阵列或条件GBRG推导当真实模组输出相位。

平台双FIFO容器20+9及镜像1=30RAM；既有119已含FE/Canny44，合149/256仅已列小计；显示14行bank若替换9FIFO为154、同时保留为163，尚非全机预算。时钟/复位原语、器件/PHY、相邻编码/容量/QoS、STA及实际工具检查仍BLOCKING，16场景全部NOT_RUN。无业务代码、功能脚本/TB、联网下载、正式DB/状态变更；已有两项申请保持PENDING，无新批准问题。

## 16. CAMERA v0.1与完整RGB源关闭

[相机主稿](../../../planning/design-TRACK4-CAMERA-001.md)→[窗口/writer附件](../04_local-designs/camera-window-and-writer-sketches-v0.1.md)→[实际读审](camera-review-v0.1.md)，8要求/8交接/8操作/10不变量/24文字场景及附件12场景，A–L已保存。来源[CSI/配置v2](../01_baseline/camera-csi-and-config-evidence-v2.md)核实际5.15/raw字段域未知、Group Hold最多10而stream-on后19写、旧读输出和ACK/STOP缺口，保留v1。

实际读审修正GATE资格跨域撤销ACK、观察attempt/window及新物理token、terminal reason/STOP门、行末114bit pair等待真实EOL/EOF、跨scope/row/metadata拆NORM、closure363的累计consumer水位与空scope基线、return/CLOSE及PREPARE/FINAL互等、6B carry和bank子段offset/取消、heldW失败终结、丢EOF local_abort、完整FP74/满队同址与heldFJ取消。NORM192是PL189下一版本候选，不改旧PL；新端口仍须FM/DS/平台联合吸收。

新增ROM1+window4+writer4+FE4=13，既有149包含CDC20，合162/256只已列预算；真实CSI时序/CRC终结、2Gb模型/PHY、真实phase/电气/FAE生效、父绑定/六源期限/资源/STA及批准仍CAM-B01…08。全部业务未生成/未运行，不标READY。上一轮36MD平台审计字节相同保存为[历史快照](document-checks-platform-v0.1.json)，当前[检查](document-checks.json)重新绑定本稿与入口。主计划v0.11，原局部/来源/正式状态与DB不改，既有两项请求仍待答。

## 17. DISPLAY v0.1及用户补充路径复核

[显示主稿](../../../planning/design-TRACK4-DISPLAY-001.md)→[取数/扫描附件](../04_local-designs/display-fetch-and-scan-sketches-v0.1.md)→[读审](display-review-v0.1.md)：8要求/8交接/8操作/10不变量/24主文字场景、15附件场景。采用三双clock行bank替代旧PIX168 FIFO，已列162−9+21=174/256；SRC192bit与取数1052bit、render386bit仅候选数据预算，完整FF/性能未证明。

实际读审修正current_exec不被future更新撤权；真实SELECTED/CLOSED独立槽、旧CLOSED业务ACK后才建下image scan；有预取义务的safe通过use_data0明确未选并独立discard，不等待不存在CLOSED；无义务safe不等消息。统一6pair逐沿、SRC存在与扫描mask、bank借用与scope流水引用、(op,seq)控制去重、fence与段release并行、小图授权A末拍和六分池41RAM/194与六合并36/189差别。仍DP-B01…08，无READY/实现批准。

用户指定两个精确目录确有资料，新增[VF/Demo补充证据](../01_baseline/vf-demo-supplemental-evidence-v1.md)记录VF11,672展开文件、24展开DDR模型＋两SC1336 ZIP模型、Demo IMX219 ZIP模型，27份默认4Gb/x16且缺2048Mb参数头。Demo tinyml I3有2Gb地址几何的controller/保护PHY/校准；IMX219 C4 ZIP还有可读rgb2dvi/tmds_channel，作为adapter候选，serializer/复用条件/相关clock尚待核验。不能再笼统写“VF/Demo没有模型”，也不把C4约束直接用于V4/I3。

主计划/入口v0.12，前40份CAMERA审计原字节保存在[历史快照](document-checks-camera-v0.1.json)，当前文档检查含45份MD。业务仿真/真实PHY/综合/PNR/STA/bit全部NOT_RUN，原资料与正式状态未改。下一步控制和FM/DDR/PL/算法/采集/显示联合吸收；既有两待答申请不重复创建。

## 18. CONTROL v0.1及四键/配置/恢复交接

[控制主稿](../../../planning/design-TRACK4-CONTROL-001.md)→[人工中文附件](../04_local-designs/control-human-operation-sketches-v0.1.md)→[读审](control-review-v0.1.md)：8要求/8IF/8OP/10不变量/24主文字场景。四键/两LED[实际来源](../01_baseline/control-keys-and-reset-evidence-v1.md)核原理图及I3/封装库，无新camera/DDR/HDMI球号重叠；旧KEY1 raw PLL/CSI/reset和LED0心跳owner必须在新PL联合版本吸收，不能直接套用旧source。

候选区分UI desired、FM committed、真实SOF/job采用及DP APPLIED；P已提出不改，D未提出可合并，D来源已锁入P标志防错误替代。UI274带替代来源、SOURCE_UI134保留完整关联，CFG212/committed570/proposal605/receipt1182/done938算术明确，RC profile实体仍阻塞。WAIT_FIRST中R独立ready/身份/receipt/done容量不能依旧T完成；UI观察慢读不反压APPLIED/退役/返租约；LONG reset独立AON/PL且不受UI序号耗尽挡住。

实际读审修正21样本/20完整tick、±按下释放不重复、全CFG端点比较、独立preset尝试cursor避免profile缺时卡住、BUSY不缓存完成/seq跨op唯一、静态非法不无限重提、结构化入口标待冻结。新增RAM0、已列174仅预算。CT-B01…08仍存在，本稿非READY，未新增批准问题。硬件到货/实物核对属于bit之后HARDWARE_PENDING，不作为本次预设资料软件工作的前提。

主计划/入口v0.13；前45MD DISPLAY审计字节相同保存为[历史快照](document-checks-display-v0.1.json)，当前49MD检查重新绑定。仿真、真实PHY、综合/PNR/STA/pin/bit全部NOT_RUN；原资料/正式状态/数据库未改，既有申请待答。下一步FM/DS/PL/RC/CAM/DP联合版本吸收及缺口闭合。

## 19. CONTROL-JOIN v0.1：阶段、反向入口和有界配置

[联合主稿](../../../planning/design-TRACK4-CONTROL-JOIN-001.md)→[阶段中文附件](../04_local-designs/control-join-phase-sketches-v0.1.md)→[实际评审](control-join-review-v0.1.md)。当前只在主稿J明确覆盖旧控制差异，旧FM/DP/PL/CAM/CT字节保留；不宣称完整整机接口都已吸收。

修正早到R不能跳过成功SNAP至pF/BLOCKED、已valid COMMIT不能撤回、独立R669及1246/1002回复不被primary SET堵住、持续anchor不占stage入口、1353/1359独立通知不等首源、失败/Q不能盲用pF启动恢复、TARGET2保持FREEZE与Origin且只开冻结源job、C在LIVE_BIND/FJ形成前锁。历史active J与新gate分开，有限首次visible登记/三result快照/最近观察不创造无限历史或第四结果。stage914/920统一封装/真实效果完成，完整最终error枚举和PROCESS_SAFE等仍CJ-B01。

8要求/8IF/8OP/10INV/24文字场景与8附件走查全部NOT_RUN。CJ-B01…06及各旧数据/关闭/RC/模型/时序阻塞保留，LOCAL_DESIGN，未新增批准请求。T/R5642bit、阶段4546bit/套、三cfg1713bit只是已列原body预算；0新增图像RAM/PLL/DSP不等于综合利用率。

主计划/入口v0.14；前49MD CONTROL审计[原字节历史](document-checks-control-v0.1.json)保持，当前52MD重新检查。用户指定VF/Demo重新只读核对，27份模型仍4Gb/x16、2048Mb参数头仍缺；具体路径见[来源](../01_baseline/vf-demo-supplemental-evidence-v1.md)，不能写两个目录无模型。全部仿真/PHY/综合/PNR/STA/pin/bit未执行，原资料/正式状态/DB未改。

## 20. DATA-JOIN v0.1：数据身份、阶段、借用与物理回收

[联合主稿](../../../planning/design-TRACK4-DATA-JOIN-001.md)→[实际读审](data-join-review-v0.1.md)。八要求/八IF/八OP/十INV/24文字场景和A–L集中于一份主稿，未新增附件副本。两方向实际读回最终SHA，修正START/no-session/FS、leaf封口、五旧grant移交、CAP全部关闭后COMPLETE、完整phase集合/一次关闭/自身pin例外、reader formed/delivered与g槽预约、双退休和本result释放范围。旧各局部字节不改，差异仅按主稿J生效。

新合同包括START_CLOSURE788/794、FE_BIND1628及独立归还、REQUEST_CLOSED268/274、PHASE_FENCE350/CERT410、LOCAL231/borrow702/708、PLAN_ACK528。source camera cfg、result C570及render分开。scope11/16、grant25/32、phase20/32是单PROCESS且五旧grant先返还的结构上界；Canny23是FSM状态。reader4RAM未包含于旧174，合178/256=69.53125%仅容器预算，完整FF/DSP/时序待定。

本轮将“接口已定义后的实际仿真/综合未运行”列为获批后验收NOT_RUN，不循环要求先生成未批准代码才能READY。但真实2Gb/PHY/可见性、CSI错误/closure与发端界、cold safe/serializer、RC数值/记录/profile和质量范围、最坏行/尾服务及完整资源预算仍DJ-B01…05。指定范围/构建授权与正式DB等是B06执行前置；LOCAL_DESIGN，未新增批准问题。已部分覆盖CAM-B03/DP-B03/DS-B04/08/RC父内存和CJ数据部分，不把整个旧B项一概关闭。

主计划/入口v0.15；前52MD审计[原字节历史](document-checks-control-join-v0.1.json)SHA仍03A091C90A704958F9D99147E5591ACCCA1994FB8DE49A67EFFCA0A69FA97877，当前[检查](document-checks.json)重新绑定54MD。上一goal轮只读模型/控制器证据改变后续动作，分类PROGRESS；本轮实际联合设计/修订/读审和预算更新也为PROGRESS。全部业务代码/可执行测试/真实PHY/综合/pin/PNR/STA/bit仍未生成/未运行；原资料/正式状态/DB不改，完整软件目标仍未达到。

## 21. RECOGNITION-NUMERIC v0.1及本地官方依据

[数值主稿](../../../planning/design-TRACK4-RECOGNITION-NUMERIC-001.md)→[实际读审](recognition-numeric-review-v0.1.md)。范围为已定义的POINT/θ/ρ、记录与共享宽算术合同；不替代完整圆/旋转矩形/三边/负样本/重叠/独立95%质量要求。128边界有129结果，独立审查修正原7次为最坏8次；cross=0取较小fold bin，上支严格cross>0。旧276 floorρ方案改为RNE后的277对称bin、276−r镜像，235个stride padding，q加偏置先扩位；表各占独立RAM，最新已列180/256仅容器预算。

候选覆盖、支撑分段、profile选择、去重/标签及95%质量仍有明确缺口，LOCAL_DESIGN/NOT_APPROVED/NOT_READY；不因字段位数齐全或设计检查通过关闭整个RC-B02/DJ-B04。[本地官方来源](../01_baseline/vendor-interface-contract-evidence-v1.md)实际定位CSI/DDR overview，以及25µs配置后复位、异步LOCKED和half-rate/同PLL/相位约束；仍不能证明真实CSI尾拍/错误关闭、soft-DDR B后可见/旧效果关闭或10bit serializer关闭，DJ-B01…03继续BLOCKING。

主计划/入口v0.16；前54MD DATA检查[原字节历史](document-checks-data-join-v0.1.json)保持4BB7D71EC697A02E17DAE817A4B099F9C241923C8298EE3F9D616E0788D80F2D，当前[审计](document-checks.json)按实际枚举更新。上一轮路径/模型复核给出具体来源证据，分类PROGRESS；本轮数值设计修订、独立反例及官方依据为PROGRESS。全部实现/功能测试/真实PHY/综合/pin/PNR/STA/bit仍未生成/未运行，DB和正式状态不改，既有批准请求不重复。

## 22. RECOGNITION-ALGORITHMS v0.1：候选、支撑、去重与ANN

[算法主稿](../../../planning/design-TRACK4-RECOGNITION-ALGORITHMS-001.md)→[实际交叉审查](recognition-algorithms-review-v0.1.md)。8要求/7IF/8中文OP/8INV/18文字场景/7追踪行。圆全POINT保留但anchor和256 seed是明确算法代表选择；全pair遍历、RAW/SMOOTH各512峰及五遍LS/半径；矩形DENSE16、offset/run、不合并共线断段、SEGMENT384及三次TLS；三边U歧义和近重复照FP。最终量化geometry单一四边membership与同遍LS/TLS fit诊断重算、sector完整mask后的整体门及65535I≥threshold·U门，避免I<U仍舍入满分的误合并；独立最大基数匹配、失败帧及容量失败均参与质量。

225/256 RAM=87.890625%仅已列互斥容器，VC80用关闭后的84池，字体98word复用ROM spare；局部FF列14778bit未含全机，32个12×17乘只有DSP48位宽依据。phase2公式补回32E，最坏51,027,148,800点/408,217,190,400B，圆约1.431TB，P3核验/精确去重局部约67.948GB；不能承诺实时或服务期限。AG-B01局部word/FSM/coverage、B02完整预算/真实服务界、B03质量NOT_RUN与B04外部/执行前提明确区分，未标READY，不循环要求未批准实现先通过。

主计划/入口v0.17；前57MD数值审计[原字节历史](document-checks-recognition-numeric-v0.1.json)保持AAFCBADE9028F88B2F0D76B12D8E2064058641671D4643830365A814C81AE3B1，当前[检查](document-checks.json)重新绑定。实际候选设计/反例修正/来源核对是PROGRESS，完整软件目标仍ACTIVE；全部业务代码/可执行测试/真实PHY/综合/pin/PNR/STA/bit仍未生成/未运行，原资料、正式状态、Manifest与数据库未改。

## 23. RECOGNITION-EXECUTION v0.1：内部存储、成员与关闭

[执行主稿](../../../planning/design-TRACK4-RECOGNITION-EXECUTION-001.md)→[实际交叉读审](recognition-execution-review-v0.1.md)。七REQ/四IF/九中文OP/八INV/15文字场景/七追踪行；完整A–L集中一份文档，原算法/数值/数据/RC字节保留。固定105块识别池和互斥用途，P1 context384/19raw/五遍准确重放，P2同cell submask/六遍TLS/跨word state完整提交，P3 pixel-area可见窗/相对bitmap/精确根式覆盖门、VC线性跨bank与FINAL冻结，ANN独立sealed spool/跨row carry、原role3 borrow702/708及候选job4731/receipt693/status965。

最新已列225/256RAM不增加；局部保守FF29168，仍不是全机FF/DSP/综合或性能证据。AG-B01内部word/FSM/coverage已具体化，父packed/格式差异须联合吸收；AG-B02全机预算/真实最坏服务与优化仍BLOCKING，AG-B03质量未运行，AG-B04外部/批准/DB仍保留。不会用未获批准的测试反过来阻塞设计READY；当前真实缺口不消失。主计划/入口v0.19；前59MD算法[原字节审计](document-checks-recognition-algorithms-v0.1.json)保存A46564AB028EB93E3E897446AD5EA076FA1F9A3DDCDD2EB95869ED44E717CDD4，当前检查重新绑定。

用户本轮VF/Demo追问再次实查：VF的24展开+两ZIP、Demo IMX219 ZIP有4Gb/x16模型及4096Mb头；Demo另有I3、2Gb地址几何控制器/PHY/校准模块；当前范围仍未找到2048Mb器件参数头，不能说两目录无DDR资料。SC431HAI在V4另目录。只读复核及新增执行设计/读审为PROGRESS；完整软件目标仍ACTIVE，未生成业务代码/功能脚本/TB、未仿真/综合/pin/PNR/STA/bit，原资料和正式state/Manifest/DB不改。

## 24. RESOURCE-SERVICE-BUDGET v0.1：整机容量与服务诊断

[预算主稿](../../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)→[实际审阅](resource-service-budget-review-v0.1.md)。六REQ/四预算IF/五中文OP/九文字场景/六追踪；三个只读方向与root合并源事实、候选容器和未分配项。共享FE8含于Canny44、PL30减旧PIX9、CAM13/DP21/reader4及RC105和DS17合225；外部protected IP不按0。DS31008与RC29168已有60176bit，更多typed消息/保持需完整唯一容器与热冷映射；不能把每个概念bit直接相加成XLR，也不据当前直译宣称器件必然不能实现全部要求。PL/CAM NORM192两capture同一槽，只计一次。

显示mode5行期与1248core组装机会揭示服务余量，识别三项byte工作界揭示重复扫描；热冷RAM、plane重叠和批候选只是有代价的比较，未形成或批准新实现。完整容量/RAM端口/真实IP/最坏服务与联合版本仍BLOCKING，质量及真实工具验证NOT_RUN属于批准后证据，不循环作为先写未批准代码的条件。既有FE与模型申请PENDING不重问。执行审计以8BC7140AF4295A7F898304F2DDDAAA3C15FEC503C6AAB0EEBC4B9BCA8DA7A953存[历史](document-checks-recognition-execution-v0.1.json)，当前检查重新绑定；原资料/正式状态/DB不改。

## 25. STORAGE-LAYOUT v0.1：具体布局与原资料误读纠正

[布局主稿](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)→[实际审閱](storage-layout-review-v0.1.md)。六REQ/四IF/五中文OP/十二文字场景/六追踪；三个只读方向交叉核对，最终限定复核范围以当前审计记录为准。RC工作池74＋外围17＝91，两类VC30＋40及coverage4同时生存；DISPLAY SRC15＋EA2＝17，三row/颜色/原slot链/owner保持；明确省18使自写225→207。DS/PL备选净加8至215，完整10 metadata bank/PL aux地址与pending journal记录于审閱，尚未选定。RNE进位97bit、两类VC持续、DS326冷＋113热、长控制包索引和两份pair holding543已明确；543之外CORE28/PAIR112及其余控制不是0。

旧V4 map的DDR39含异步桥17，PHY22不能当整块39；CSI/DVI参数与资源分开，ASYN0及新CSI尚未真实生成验证。VF/Demo精确根本轮重新枚举仍有4Gb模型、controller/PHY/校准和SDC参考，缺当前匹配2Gb的2048Mb参数头；不再泛称资料不存在。布局地址算术和文档/hash通过不等于业务测试。SL-B01联合版本/metadata、B02真实IP/clock/模型、B03最坏服务及批准/DB仍保留，整体未READY/未批准。

预算阶段[原字节审计](document-checks-resource-service-budget-v0.1.json)为169F4E5C62B42EB48A2549F808D35D40D7B36975A94380790C424E8DBD61FE68；当前检查重新绑定新增主稿/审閱与v0.20索引，不从更早执行审计回滚。12文字场景NOT_RUN，源码/功能脚本/TB、PHY仿真/综合/PNR/STA/pin/bit均未生成或运行，原资料/正式状态/Manifest/DB不改。

## 26. STORAGE v0.2联合覆盖及有限IP实验设计

[当前布局](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)→[本轮审閱](storage-layout-review-v0.2.md)。DENSE e0…e5六命名沿/II最早5，条件32E为331776000CORE周期机会；两336按16×21lane复用，取消据真实低WE提交有限完成高WE，不新增16×20缓存或扣富余。J覆盖SEG19WE及各父布局，207预算不变。DS/PL字典与journal计数分步写双计问题仍未闭合，旧inhibit“新接口”修正为既有sticky stop_new映射；未选串行实现。

[IP-PRECHECK v1](../../../planning/design-TRACK4-IP-PRECHECK-001.md)当前READY_FOR_REVIEW，89源hash真实读取与两方向限定审查；两项时序/阶段和reference-only资源边界已修。C2.original和clock-corrected分开hash/重新综合下游，C3派生后者；四case目标阶段明确，失败后NOT_RUN/SKIPPED_DEPENDENCY。protected兼容/资源/clock可作为实验输出未知，DB/许可/指定批准为运行前置；有限READY依据保存读回及限定审查修正，不升级整机READY。

[旧布局主稿](../../../planning/design-TRACK4-STORAGE-LAYOUT-001-v0.1.md)与[原字节审计](document-checks-storage-layout-v0.1.json)SHA1B2D…E5270/6FAA…493B已保存。新18 SL/IP文字场景全部NOT_RUN；不生成业务算法/TB，不联网/安装/正式状态/DB写入。完整软件目标继续保持全部十一项，尚未完成。
