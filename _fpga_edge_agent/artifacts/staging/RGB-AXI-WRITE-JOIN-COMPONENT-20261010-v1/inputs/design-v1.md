# TRACK4-RGB-AXI-WRITE-JOIN-001 v1：实际RGB写帧与共享AXI写服务

- Goal：把实际rgb_source_writer及原生RAM和实际axi_write_pair_service/axi_line_bridge接成彩色帧到AW/W/B的公共写链路，推进完整五基础六高阶/1080p/Ti60F225/I3/SC431HAI，不将这个组合当整机完成。
- Current state：writer已有全1080p/综合后字节证据，write服务35场景/MAP873 LUT/562FF通过；实际producer尚未接这个公共write口。
- Target state：实际四RTL组合、原生RAM、全1080p颜色/padding/真实B闭合、算法并发64B写、取消与错误联合验证及组件MAP。
- Gap：CSI RAW/CRC/rx_close、实际算法主体、public read/write hub、FrameRef authority/生产帧发布、DDR PHY/最坏QoS、整机资源/时序仍另闭合。
- Assumptions：同core clk/rst/enable，parent授予camera full frame及algorithm非重叠地址；camera输入此层允许ready暂停，不能据此宣称不可暂停MIPI达标。可信共同cold rst覆盖writer/RAM/slave/公共服务，不证明暖reset。
- Open questions：四实际源码/公开接口已审、当前组合无接口阻塞；真实DDR/CSI期限和生产frame authority明确在后续。
- Dependencies：设计、v0.2、四RTL(writer/ram/write-service/bridge)、原生EFX_RAM10、两个组件manifest(writer/write-service)、原bridge manifest、独立source_reference.py共11输入冻结；原HDK/登记包不改。
- Milestones：整体→逐连接→中文语句/验证→保存读回呈现READY→冻结11→七自写文件及五依赖→small/min/padding/HD→MAP→staging→实际生产hub/帧控制。
- Detailed steps：B外部行为，C/D交接，E语句，F时间，G/H测试/追踪。
- State transitions：READY_FOR_REVIEW v1，沿用用户持续“当你统计完后自行进行，无需我的批准”和本批local audit例外，不重复请求逐版批准。
- Artifacts and hashes：work/rgb_axi_write_join；七自写RTL/TB/Python/sim/map/XML/SDC；四RTL原样依赖+原生RAM模型=12源/工程，source_reference作为冻结数学生成依据，不另用可变原文件运行。
- Validation：source全frame输入/全RGB/padding与算法全512并发写，实际AW/W/B/应答/配置/终态保持及grant/handle/count，正常/取消/错误/未知/停止和共同复位。
- Failure handling：错误原日志保留；globalQ只挡新接收，不屏蔽旧通知/物理AW/W/B；UNKNOWN禁止归还帧，不改为safe done，不为未接纳事务造B或line回复。
- Human approval gates：自主软件/local审计，正式DB/H0/state不改，无bit/硬件操作。
- Rollback：独立新work，只复制核hash依赖，不改旧已登记源。
- Completion criteria：真实组合当前源功能及MAP证据；全部十一项/DDR/整机目标仍ACTIVE。

## A/B 整体与要求

RJ01：外部camera job_base32/handle64、RGB48及x_even11/y11/markers3/bad1/handle64按实际旧writer接口进入，低24为R0G0B0、高24为R1G1B1；连续DDR byte为R0/G0/B0/R1/G1/B1，跨行无额外padding，仅整帧A64补零。WIDTH4..1920偶数/HEIGHT2..1080，生产默认1920×1080，不缩图。

RJ02：整帧授予先核64B对齐与33bit base+A64<=ADDRESS_BYTES(default256MiB)。非法known/四态未定job被外层真实接纳、保存一个local rejected_cfg回执(error1)，保持至job_rsp_ready，不传child、不接受pixel、不写AW、不产生camera done；旧writer检查2^32与新板容量检查相容。新合法job在公开job_fire同沿交给child，锁同一base/handle。child config/done各自原样保持，不能因后来的job提案或globalQ改旧正文。

RJ03：actual writer→write服务端0，外部algorithm写RPC→端1，single actual bridge保存512快照/4W并等真实B；只写服务的实际回复回writer，不用理想line立即完成。另一个algorithm父不在本批实例化，但其公开64B接口按已验证write服务刺激。所有地址/512和error/drained真实交接，无FrameRef权限替代。

RJ04：globalQ=writer_Q|write_service_Q，新job/pixel/algorithm request ready和valid同门防假fire；writer已公开line及旧reply/done/CFG保持实际逻辑，旧W/B不因Q屏蔽。write服务enable仍直接parent backend_enable，不能用globalQ把旧物理承诺当已停止。backend_enable0只挡newjob/pixel并提出source_stop，已公开writer line随旧服务ready兑现；live下降由actual桥UNKNOWN路径保留。

RJ05：source_stop=writer_stop|globalQ|!backend_enable。普通cancel只传实际writer matching handle，已有PUBLIC line仍继续，cancel/bad及memory error优先按旧writer，不挡PUBLIC。UNKNOWN返回actual writer进入隔离，无安全camera done/job ready；若算法未知而camera line尚未被公共服务接纳，它保持PUBLIC、globalQ阻新行为，没有假通知或假frame closure。已经形成的camera safe done可以消费，globalQ仍禁止新job，父不能仅凭camera done发布Source。

正常：独立空间RGB1080p→两bank/carry→packet512→共享服务→AW/4W/B→实际packet/bank退休，完成1036800pairs/6220800B/97200lines；算法另区域并发全512写与其回执数量守恒。取消：AW不ready时cancel，PUBLIC line不撤，真实B后safe CANCEL128。错误：camera BRESP非OK→writerERROR16，之前物理写保持副作用；wrongBID→writer/write/globalQ、no safe done，旧正确B仍接但不复用。

## C/D 实际连接与端口

MOD1新rgb_axi_write_join仅local CFG admission及资格接线；MOD2实际rgb_source_writer/carry/bank/packet；MOD3 actual rgb_source_ram_word(4×EFX_RAM10同步RE/WE，OUTPUT_REG0 READ_FIRST)；MOD4 actual axi_write_pair_service；MOD5 actual axi_line_bridge，四RTL全原样复制。原生RAM10用于仿真，综合由Efinity原语推断，模型不作为可综合业务RTL列进XML。

外部source writer原job/CFG、pixel、cancel和DONE(outcome2/reason8、handle64、accepted22/written22/logical32/physical32)；外部algo_req_valid/ready/addr32/data512、algo_rsp_valid/ready/error/drained；一个AW/W/B32/4/8/3/2、128/16/1、B4/2；clk/rst/backend_enable、source_stop、source_quarantined、write_quarantined、quarantined、write_busy/fault_reason3。

IF1 job_ready=!rst&&!rejected_cfg&&backend_enable&&!globalQ&&child_job_ready。job_fire合法则child valid同沿真fire；非法则只rejected_cfg置1，job_rsp_valid为child或local，job_rsp_error local1否则child；reject与合法child CFG不可能并存。消费local CFG只清flag，不形成DONE或child上下文。IMAGE A64用编译期整数，运行33bitend显式加不溢出；有效参数和容量由static guards确认。

IF2 camera pixel_valid及对外ready同backend_enable&&!globalQ门；有效坐标/mark/handle身份由原writer在实际fire核对。cancel原样传，不替换为enable。IF3 writer line_req_valid仅globalQ新接纳门，端0req_ready同门；其512正文及error/drained接公共服务真实端0，不将source_stop误用成撤PUBLIC的门。line_rdata固定0(write-only)。IF4 algo req/ready同globalQ门，回执不gate；IF5公共AW/W/B全部直接连，shared enable原样。WR_Q已成后禁止新事，但actual桥旧W/B与通知仍推进。

注意：writer在REQUEST公开但未接纳时算其PUBLIC借用；globalQ另一事务导致阻接，wrapper不私造safe error来清借用。父必须retain此帧到可信恢复。source DONE仅局部写完成，不代表RX good、readers/fence关闭、display可Apply或global frame released。

## E 中文详细语句草图

E1 定义actual两端line wires、writer job/CFG/in-ready/Q/stop；一个rejected_cfg FF初0，33bit frame_end=zeroextend(job_base)+A64，legal按对齐/容量/已知job fields；WIDTH/HEIGHT和ADDRESS_BYTES范围与两child都核对。不存新的frame像素或512数据。

E2 CFG组合ready由IF1建立，合法public jobfire才送child_valid；非法fire只在同步正沿保存rejected_cfg=1，child不动，job_rsp_error1/valid1直到消费。local held CFG期间proposal变化和backend停用不能改回执。child CFG/DONE仍直接输出，所有gate都共享同一资格，不出现外部fire但child没fire。

E3 writer实例所有像素/meta/cancel/DONE/counters原样接，pixel同门valid/ready，source_stop输出与globalQ/backend汇合。actual source RAM为依赖，不新建fake byte FIFO。

E4 writer公开512/address接write-service端0，算法外部接端1，两ready门与valid门相同。source/write Q或成global，旧reply不门控，writer response_failure由真实error/drained触发，unsafe没有安全DONE。source已held safe done/CFG不被globalQ屏蔽。

E5 actual write-service实例enable=backend_enable，同clk/rst及AW/W/B/占用首因直接接；rst仅可信共同cold，无独立clearQ。实例循环由保存Q及state构成，没有newvalid→Q组合自反馈。

## F 语言与观察

SV2009，组合blocking/FF nonblocking；正沿前fire，FF沿后输出，TB负沿驱动。WIDTH等编译常量，A64=64ceil(3WH/64)，unsigned32地址/33end；payload/markers与旧源码同位宽/布局/顺序。RGB输入未fire不推进carry，4W已发不等于B完成；所有等待允许不定延迟。没有新增CDC/DSP/RAM（仅真实writer原4 RAM）及重复payload存储；组件100MHz目标/MAP不能当物理时序证明。

Python参考只按坐标的R/G/B函数生成expected连续bytes和padding；另从公开事件重建job/pixel、算法req、AW/W/B、notice/done数量与地址、字节内存、失效/Q/冷reset，不复制carry/bank/packet内部。全帧数值在.dat/.rgb完整比对；每周期held protocol由TB公开字段逐位检查，不用hierarchy。大HD不打印每个idle周期，而保存所有接受/交付事件及完整输入frame/actual memory；内部hold断言真实fatal，不从idle猜closure。

## G/H 验证和追踪

RJ-T1 small34×19六独立RGB模式与算法并发、最小4×2、512×2整bank及510×2尾padding、生产1920×1080空间RGB全frame；camera与algo不同授权区，全AW/W/byte-memory/回执与RGB6bytes序列一致。真正AW/B完成才writer退出，已有source-ref不能代替本组合仿真。

RJ-T2 AW/W/延B/CFG/DONE/algorithm reply长停顿和输入气泡，PUBLIC cancel在AW待接/等待B/已held终态、错handle cancel、marker/coord/handle/bad四类输入错误；正常6B跨bank/carry及A64零尾精确比较。源bank满时真实in_ready停顿，不假设不可暂停camera能永远等。

RJ-T3 camera非OK BRESP和错BID（notice先消费后真B）、算法UNKNOWN对camera PUBLIC借用的影响、backend在live停用/恢复、safe held DONE与CFG不改；globalQ阻新job/input/algo且旧物理及通知继续，无safe done/no reuse。matching cancel与真实内存错误同沿ERROR优先按实际writer。

RJ-T4 job未对齐/全帧越256MiB/合法最后A64，reject held与提案变化、cancel/enable变更，拒绝不得child接受或任何AW；共同cold在live/heldQ建立新身份，不冒充暖reset；N/A实物/PHY/CDC/FrameRefauthority/整机deadline。

RJ-T5 真实当前compile/elab/fatal/sim/independent audit、MAP源快照，失败原样保存。sim9(runtime wrapper+4deps+vendor/TB/model/runner)，MAP加XML/SDC/map=12；守卫11冻结输入及厂商模型SHA DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33；原生RAM在各自512×20支持参数，无全局-GWIDTH污染它。TB参数TEST_WIDTH/TEST_HEIGHT/TEST_PROTOCOL映射到业务WIDTH/HEIGHT。

RJ01→E3/IF2→T1/T2全bytes；RJ02→E1/2/IF1→T4 config无副作用；RJ03→E4/5实际child→T1/T2/T3 AW/W/B及算法账；RJ04/05→资格门/旧通知/unsafe→T2/T3/T4。runner工程→T5。变更从任一符号可回到上述REQ/接口/语句，后续README按实际代码核对。

## I/J/K/L 门槛及交付

整体样例、职责/实际复用、端口语义/同门及组合检查、rejected_CFG/其他state归child及中文操作、数值/时间/流控/冷复位/配置/存储/CDC N/A、测试与追踪、无当前接口阻塞、11基线范围及保存readback呈现齐全：READY v1，按持续自主软件/local audit例外生成，不更新正式授权状态。

实施七文件与五依赖，只在新work；必要scope变化先短卡/readback呈现。交付分compile/功能/RAM model/综合/STA/实机，未跑不记PASS；bit/硬件不在本批。理解验收待用户实际回答。完全实现整个FPGA仍需fullCSI/DDR动态、publichub/FM/识别/总资源/时序/最终bit。
