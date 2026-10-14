# TRACK4-CSI-MODEL-PROBE-001 v1：官方CSI接收模型的RAW10实际输出核验

2026-10-09，READY_FOR_REVIEW；保存、呈现和读回后依用户“当你统计完后自行进行，无需我的批准”自主实施，沿本批本地审计例外。上一轮v6是真进度：新SC配置/FIFO代码、当前仿真及Ti60 MAP已登记，整目标保持ACTIVE。

## A 目标、现状与边界

Goal：把CSI公开时序/packing未知转成可检查的实际软件证据，决定下一采集适配器怎么连接；不靠原top四个10位高8截断猜测。Current：安装中存在soft_dphy官方ModelSim TX/RX模型及官方VGA源；原示例do引用的csichk等不在其相对目录，源在source_exp/ti60_loopback，直接执行该do并不是完整运行。Target：在独立work内，真实官方TX模型产生四lane LP/HS字节，真实官方RX模型解码，独立的RAW10输入/输出逐位核对与元数据/行帧边沿观测。

Scope：新tb、Python参考、仿真脚本3份业务/验证输入；原模型/官方VGA源字节不改，复制依赖并核SHA；不解密或重建保护主体。此阶段仅ModelSim探针，不生成生产RTL、不做MAP/PNR/STA/bit或硬件操作。发现安装模型与活动5.15不能等价时明确记录差异，不将另一模型通过当活动工程通过。

Assumptions：数字LP/HS lane模型与公开clock/reset端口；TX与RX均为本机2025-07-15官方模型wrapper（header Version1.00），本机IP目录5.15元数据，不能把两种版本称谓混为已证等价。RX参数明确选原活动实例：4lane、PACK_TYPE15、byte70MHz、control100MHz、pixel50MHz、FIFO1024、ASYNC2、AREGISTER8、Discontinuous、GENERIC、VCX0、termD25/settle85/prezero145/init100us。TX按同lane/时钟/pack/frameMode产生数据。Open：加密模型Questa兼容、RAW10实际PPC/上24位/DT/WC/VC/短包有效期/HSVS极性、可选pixel sideband、错误与末帧关系；这些正是有授权的探针实验对象，不在未证明时写生产成功合同。

Dependencies：CAMERA来源v1/v2、C2活动controller公开header、本机source_modelsim及软PHY示例、official vga_gen、规范v0.2/模板、现有Questa。Milestones：源/参数冻结→原模型编译与elab→小RAW10→1080p全帧→元数据/边沿审计→具体适配器设计。Artifacts：work/active/track4_algorithms_20261004/csi_model_probe/runs新目录、数字测试日志/二进制观察/参考报告/本地事件；不写原安装目录。Failure：编译/超时/位错明确FAIL、保留全部旧run，不替换保护模型为stub；安装模型失败仍可继续其他生产模块。Human gate：沿自主授权，无逐项新增批准，硬件闸门保留。Rollback：独立组件。Completion：CP01…05实际证据；若不通过，诚实列具体失败与下一实际修复，不能宣称CSI闭合。

## B/C 整体路径与验收

CPREQ01：官方VGA源（无修改）在pixel50MHz产生宽为4倍数的有效组/行/帧，TB构造4个保留全部10位的像素，官方TX→实际四laneLP/HS→官方RX。正常小W20/H8和W1920/H1080；完整图只在测试体生成源，未改变项目1080p要求。输入源前等待reset释放及init≥100us，防止把reset帧丢失当packing错。

CPREQ02：每个有效RAW10输入4像素。p(x,y,frame)=(37x+53y+7(x xor y)+101frame) mod1024，四位置从data[9:0]开始顺序每10位；输入上24位为变化哨兵，仅下40位属于RAW10。独立Python由宽/高/顺序重算期望并比实际RX低40位、完整输出数量，不沿用RX内部坐标算法。输出上24位、PPC编码和元数据先观测，不在未知时硬写期待值。

CPREQ03：观察控制/byte/pixel实际端口，不读加密内部。valid拍保存RX data64/PPC4、原DT6/VC2/WC16/short16/HSVS；另CSV保存HSVS/原字段/debug的变化与所属采样域、时间。必要可选PIXEL_SIDEBAND由真实宏/端口独立运行核；没有端口或不兼容明确FAIL/N/A，而非静默编造。HS0/VS0边沿/valid对齐、同拍字段/最后payload后错误或短包关系以观测结果说明。

CPREQ04：源输出达到完整FRAMES数量后，在帧结束边沿停止新有效图像，仍让模型完成传输；记录末payload、HSVS、debug/irq和排空等待。探针等候安静时间仅让测试收集完，绝不据此定义生产接收closure watermark。没有注入错误实验，就不能宣称CRC/错误归属已闭合。

CPREQ05：真实编译/elab/fatal非零出口/原源SHA一致；所有新RunId拒绝覆盖。实际成功必须独立数值/数量PASS且模型日志0errors；官方示例自己的“PASSED”字串不能代替。本范围不生成FPGA配置文件，资源/物理证据N/A。

连接职责：MODSRC官方vga_gen→IF01组坐标/valid/HSVS；MODPAT TB只生成RAW10及关闭源→IF02官方TX公开pixel口；MODTX官方模型→IF03四lane数字LP/HS；MODRX官方模型→IF04 TB端口观察；MODREF Python→IF05独立结果审计。源、模型、参考各自职责，不以参考生成加密内部状态。

## D/E 接口、草图和RTL时间

三域control100MHz(10ns)、byte70MHz(14.286ns)、pixel50MHz(20ns)，reset_n/reset_byte_HS_n/reset_pixel_n依公开端口分别连接共同初始化后释放。官方TXpixel口没有ready，测试只发送本来允许的完整行及足够blank；test源停止后不撤掉已经送给模型的数据。四laneLSB为lane0，TX HS_D0…3直接接RX HS_D0…3，HS_D4…7为0，soft PHY fifo_empty按官方示例无业务反压含义处理，确定数字模型输入后记录依据。

局部TB草图：复位并开三钟→等待init→释放官方视频源→每个pixel posedge有valid且未达到目标时按其组x/y与源帧计数生成下40位、上24位哨兵，记录真正提交到TX的值；RX每个valid采样端口构成16字节little-endian记录(data8/PPC1/DT1/VC1/HSVS1/WC2/short2)，原信息不隐藏；HSVS/字段/debug变化在相应域独立记CSV。输入完整图结束后等待对应VS帧结束，不再新增payload；等RX数量或有界timeout，再保存metrics与finish。数量不足/超出/位错为FAIL。

独立参考草图：严格解16字节/目标数量，按index→frame/row/group，独立任意精度式生成四个10位并与实际低40比；统计PPC/上24位/原metadata在valid期间实际集合和异常数量，读取独立端口边沿观察形成报告。只在观测中发现确定合同后修订下一adapter设计；原metadata不重命名成pixel-aligned。SV TB数据/计数用明确64/32位，坐标14/12原源宽度，不复用旧csichk 10位y截断。Python标准库UTF8，C++ N/A。

## F/G/H 计划、追踪与门槛

CP01 模型和全部相关依赖能实际Questa编译/elab，无stub；CP02 小RAW10全部位/数量/START式行帧观察；CP03 1920×1080全部2073600像素/518400组每帧，LSB变化/row>1023保持；CP04 元数据/PPC/短包/上位/HSVS/末帧观察与可选sideband，未观测范围独立标未证明；CP05 fatal出口/新RunId/当前源hash与本地登记。

REQ01→官方源/TX/RX→CP01…03；REQ02→PAT/独立REF→CP02/03；REQ03→三个端口观察→CP04；REQ04→源关闭/等待边界→CP03/04；REQ05→runner与manifest→CP05。输出schema使观察不能被硬编码期望掩盖；反向核心代码注明CPREQ编号。

十项自检：A整体边界/来源/未知实验；B正常数量/失败/不冒充closure；C职责；D具体时钟、参数、交接和所有权；E局部操作与格式；E位宽/仿真语言/跨域观察；B源到实际接收走查；G独立场景/实施；未知仅限获准探针不影响其他冻结组件；文档保存/实际读回/阅读入口；v1/3新文件/真实源冻结可核。READY后依持续自主授权实施；变化先J记录再修改。

## J1 四态端口观察细化

在生成探针前补充：有效RAW10低40位未知即FAIL；其他公开字段即使出现X/Z也应如实记录，不在二进制导出时偷偷写0当已知值。每条16字节观察旁另有1字节unknown-mask，bit0…7分别为上24位/PPC/DT/VC/WC/short/HS/VS，二进制未知字段只作占位且Python必须忽略其占位值并报告未知数量。原source/TX数据另存8字节记录，实际lane输出可另保存活动HS四lane/LP状态，以便后续独立字节检查；此批不据TX/RX共同codec宣称SC431HAI物理MIPI兼容。两个独立模块的数字loopback与真实板PHY分别记录。

## J2 首次实际编译/展开

csi_raw_small_001：vlog exit0（3 warning），vopt exit2；两个官方加密wrapper分别出现vopt-2137潜在无界递归，尚未进入动态仿真。先按官方do的分文件编译方式，把TX、RX、TB各自编译，避免IP_UUID宏在同一vlog调用中的相互影响；采用工具建议的svinputport=compat复查var/wire默认解释。此处只是消除实际编译歧义的尝试，不断言这是递归原因；不改官方依赖，不变已声明参数/测试目标。新002保存全部真实结果；如仍失败，再核当前ModelSim source链和公开接口，禁止stub。

## J3 官方ModelSim完整fileSet路线

002分编译仍在相同两个protected位置vopt-2137失败，没有动态输出。实际原IP元数据external_testbench_modelsim明确列出source_modelsim的CSI/D-PHY链，以及common/source同步器、efx_fifo_2/source FIFO；并不是旧csi2_filelist.f的efx_fifo_wrapper路线。新v1.3基线加入RX/TX这两个实际XML的ModelSim并集文件及必要同目录头文件，逐字节冻结，不修改原厂源码/保护段。

TB以相同公开端口和原参数直接实例官方完整源的efx_csi2_tx/rx；TB只提供IP_MODULE_NAME(name)=name的命名宏，用单一mfcu编译单元传给各原文件，属于构建命名组合，不实现/替换编解码器。原两个打包wrapper仍保留作失败输入，当前003不再编译它们。三份自写输入数量保持，schema/目标/公式/时钟/关闭边界不变。全部必要依赖由真实XML定位，缺文件/解密密钥/展开错误明确报错，不选另IP冒充匹配。003先小图，真实通过后才1080p。

J3执行实录纠正：准备程序将单个源resolve到真实D盘路径，却用尚未resolve的ASCII junction根做relative_to，复制前就失败；同一调用的PowerShell随后仍运行了旧脚本，003实际仍是旧打包wrapper的相同展开失败，不属于完整fileSet证据。下一准备操作统一解析源与根，检查Python非零立即停止；完整source链首次实际运行改为004。未复制/修改原厂主体，也没有将003登记PASS。

## J4 实际根因及工具合同修正

004完整源码链vlog0，vopt错误定位到公开efx_fifo_gray2bin.v:40的WIDTH-1递归；原文WIDTH=2结束，逻辑本来有界。实际vopt -help All明确“-G overrides all matching generics and parameters”，runner未限定的-GWIDTH=20同时覆盖每层FIFO/同步器WIDTH，递减被覆盖，错误来自测试脚本而非原厂递归设计。004新parameter-diagnostic-vopt.log移除全部-G后，同一已编译库实际展开71设计单元、307实例、exit0/0errors，证明此诊断方向。

先修草图：TB几何参数改唯一PROBE_WIDTH/PROBE_HEIGHT/PROBE_FRAMES，runner只覆盖这些实验专用名，原模型/库所有数据与地址位宽保持其真实参数连接。005重新全流程/fatal/动态/独立审计；不改原厂文件、降参、禁用递归检查或抹去旧错误。v1.4基线只更新本卡SHA，其他55输入不变，结果记录明确这个脚本错误及修复。已有其他组件的-G范围另做只读核对，冻结包不随意改写。
