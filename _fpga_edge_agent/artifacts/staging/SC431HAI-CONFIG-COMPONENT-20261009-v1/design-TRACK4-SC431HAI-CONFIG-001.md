# TRACK4-SC431HAI-CONFIG-001 v1：SC431HAI 的真实开漏配置链

2026-10-09。READY_FOR_REVIEW，保存/读回后按用户“当你统计完后自行进行，无需我的批准”持续自主实施；本批本地审计例外沿用，不改正式数据库/状态/原HDK/旧组件。代码生成仍在本卡整体→接口→局部草图之后。

## A 目标、现状、范围与依赖

Goal：完成CAM-REQ01可独立编码部分，真正SCL/SDA开漏事务完成ID/164写/14读回，不把旧TIP清当ACK。Current：RAW/源写/读回/完整Canny/AXI已实际1080p通过；相机配置只有原HDK表/旧高层及候选草图。Target：新配置链数字总线仿真、Ti60F225/I3实际MAP、可读中文说明与冻结源证据。Gap：新RTL/参考/从机模型/TB/脚本/工程；真实模组电平/XSHUTDN、CSI/帧闭合、生产top/引脚/PNR/STA/bit仍全工程后续，不由本批通过替代。

Assumptions：单I2C主控；SCL/SDA外部上拉到合格电平，输入为数字0/1；power/reset/EXTCLK真实资格由platform_ok同步提供。实际core时钟≤CLK_MAX_HZ；默认100MHz目标，保守CLK_MAX_HZ=101MHz；1…200MHz范围，SCL_HZ=100kHz标准模式。真实电平/上拉rise≤1us/引脚由生产平台闭合，未确认不执行硬件操作。Open：无影响此数字组件正确性的未知；不能把数字模型当实际相机配置已成功。Dependencies：规范v0.2、模板、CAMERA候选OP01、摄像头来源v1/v2、实际原164表、PDF I2C/ID/启动/模式字段、官方EFX_RAM10模型。旧Intel/OpenCores混合许可和旧WB高层不复用业务逻辑，仅提取已经提供的寄存器数值与顺序。

Milestones：整体/位级合同→原表与public字段数据→新底层总线与ROM/父→独立从机+参考+TB→1MHz快速同真实100k总线/100MHz生产参数→MAP/登记→摄像头CSI/CDC和平台闭合。State transitions：仅本卡和本地实验；失败保存旧run、不覆盖。Artifacts：独立work/active/track4_algorithms_20261004/sc431hai_config、new runs、staging。Validation：CT01…CT08见G；未执行不标PASS。Failure：NACK/内容错停止表，真实STOP/总线释放才drained；不确定clock/所有权则Q，通知消费不清Q。Human gate：总bit后停止，不操作硬件。Rollback：新独立单元；已有冻结模块和资料不改。Completion：本数字组件CT01…08实际完成；全部五基础/六高阶仍需生产总工程证据。

## B/C 整体行为和模块连接

SC01：job一次上升沿接受，完整scope160={seq64,generation64,epoch32}、operation2、device_addr7锁定。operation0 CONFIGURE、1 STOP，2/3拒绝；地址只30/32（SID两合法源地址），不自动探测。输出一个保持终态notice；0OK/1ERROR/2CANCEL/3QUARANTINE，drained明确。未知终态是通知，绝不是安全关闭。配置/live状态和终态快照分开。

SC02：platform_ok连续有效满T4≥4ms后允许I2C。输入应已经包括电源/EXTCLK/reset真实release的资格；任意下降撤live、停止新工作，不用旧计数复活资格。等待未就绪100ms（按时钟上界计算）为本组件失败政策，不是假定芯片期限。无模拟AON失钟检测，真实停core钟的外层平台义务继续存在。

SC03：CONFIGURE先read3107/3108，实际ID CD6B；保序164次write；再read14公开字段。每事务逐从机字节ACK，主机最后读NACK是正常。只有全部回复OK/drained、内容匹配才registers_verified。原index90 stream-on后19写仍保序，不编造GroupHold/无证重排。没有自动重试；外层重新配置/复位策略后续。

SC04：STOP写0100=00再read bit0=0；不等待停止后的两帧。每个job成功数/ID/读回/failed_reg/phase/ACK可见。registers_verified不是ARM资格，真实两帧/模式/phase/CSI closure另交接。

SC05：scope匹配取消是采样事件；已公开子请求不撤回，子接纳后持有取消，旧总线安全STOP/释放后结束；错误优先取消。不同scope取消忽略。总线仲裁碰撞立即释放线，禁止插STOP去破坏另一所有者；观察双方高且tBUF满足后可ERROR/drained，超时Q。无九脉冲bus-clear。平台失效在已拥有总线时Q，输出释放、旧身份不回收，恢复platform_ok不自动解锁。

连接：job→sc431hai_config（上电等待/完整任务/顺序/核验/live）→sc431hai_profile_rom（独立真实原语）及profile_pkg（14静态公开字段）→i2c_register_master（完整寄存器事务）→SCL/SDA开漏pad→独立从机模型。父不直接创造ACK/数据；ROM只提供数值，不判断事务成功；从机TB按外部线边沿解析，不读DUT内部状态生成数据。

正常样例：platform_ok满4ms、scopeA/config30，ID正确，164真实STOP关闭，14字段匹配，writes164/reads16/mask3fff/IDvalid3，OK/drained/registers_verified；后续改变外部提案不影响A。失败：第j写DATA NACK，已安全提交的writes=j，错误字段定位该原表项，停止后续，STOP真实关闭给ERROR。边界：最后验证回复与取消同沿，记录实际read/匹配前缀但终态CANCEL、live不置真。Q：SCL卡低超过timeout，不发假drained，新任务禁入。

## D 接口与组合检查

共同clk posedge、rst同步高有效，冷共同安全reset才清隔离；任何运行中暖reset须外层先停止、证明总线/运输安全，本组件不制造该证据。

父inputs：job_valid/ready、job_scope160、job_operation2、job_device_addr7，platform_ok，cancel_valid/scope160；outputs done_valid/ready、done_scope160/op2/address7、outcome2/reason8、failed_reg16/failed_phase4/readback_value8、writes_committed8/reads_completed8、verify_mask14/readback_values112、chip_id16/chip_valid2/ack_mask4/drained、registers_verified snapshot、live_verified/verified_scope160、quarantined。所有终态body保持到消费；platform下降立即关live而不改已形成旧body。live仅寄存器内容资格，未接任何ARM。

底层req：valid/ready、read1/dev7/reg16/wdata8/tag64；rsp：valid/ready、tag64/rdata8/outcome2/reason8/phase4/ack_mask4/drained；cancel_valid/tag64、enable=platform_ok；pads为scl_i/sda_i、scl_drive_low/sda_drive_low。外层只能`drive_low?0:Z`，绝不推挽驱动1。输入各2FF同步；input timing/CDC到正式平台再约束。

底层只一事务和一回复槽：IDLE接纳锁body；读wdata忽略；device合法08…77；无enable的新req仍能接纳为本地ERROR/drained1/no START，避免已公开父提案因enable撤回互等。已有总线enable失效则Q/drained0。tag完整保留。req_fire与匹配cancel同沿→CANCEL/drained/no START。held rsp忽略新cancel，Q通知消费后仍Q。bus idle不是TIP。

父每job预留tag预算CONFIG180=2+164+14、STOP2，全局next_tag64不回绕；max保留不分配，扩65bit核next_tag+budget≤2^64−1，非法预算不触总线。ISSUE前锁cmd_tag/body，ISSUE valid到fire不可撤，WAIT按实际rsp_tag核验后提交。无第二父job/额外队列。配置取消/master失败全部旧请求/响应先消费；no bus started的本地错误drained只表示本模块无总线借用，不表示另一个master已经空闲。

14读回：0100 expected01 mask01；3018 60/E0；3031 0A/0F；3037 20/60；303F 00/80；3208/09/0A/0B 07/80/04/38 maskFF；3210/11/12/13 01/44/00/05 maskFF；3221 66/66。masked无关位不拒绝。公开字段来源为旧CAMERA D2/OP01和原PDF，未公开FAE位不臆造验证。

## E 中文局部语句与状态草图

### E1 底层总线

状态enum IDLE/WAIT_FREE/START_HOLD/LOW_FALL/BIT_LOW/BIT_RISE/BIT_HIGH/BYTE_NEXT/RESTART_LOW/RESTART_RISE/RESTART_HIGH/STOP_LOW/STOP_RISE/STOP_HIGH/WAIT_RELEASE/RESPONSE/Q。bit_kind2=TX/SLAVE_ACK/RX/MASTER_NACK；bit_index3 7…0，byte_index2 0devW/1regH/2regL/3data或devR，锁tag/dev/reg/value/read。sda/scl驱动寄存器只0拉低或释放。

HALF_CYCLES=ceil(CLK_MAX_HZ/(2*SCL_HZ))，默认505；HIGH/LOW/START/RESTART/STOP/tBUF至少该计数，从已同步实际SCL水平开始计，不把等待clock stretch当高时间。标准模式SCL≤100k、low≥5us≥4.7、high/START hold/STOP setup≥5us≥4.0、restart setup/tBUF≥5us≥4.7。输入rise≤1us/电平/实际频率上界仍由物理平台保证。每次可推进状态清watchdog；某状态无进展超过TIMEOUT_US默认10000→Q，保留首因，drained0。

IDLE锁req；WAIT_FREE连续SCL/SDA高至少HALF，输出仍释放，才拉SDA低形成START。START_HOLD保持SCL高SDA低≥HALF；LOW_FALL先仅拉SCL低，等待同步实际低，下一沿才变SDA，避免SCL下降/数据变化传播差形成伪STOP。BIT_LOW设置TX当前位（0拉低/1释放），ACK/RX/NACK均释放，保持至少HALF，再释放SCL；BIT_RISE等真实sync高；BIT_HIGH保持并末沿取样。

TX的逻辑1若观察SDA低即碰撞，release两线→WAIT_RELEASE，不插STOP；高阶段非预期SCL下降同样失败释放。TX8位后ACK：只第九位SDA=0才记对应ack_mask位，1为NACK→STOP。ACK正确按devW→regH→regL→data或restart/devR推进。重复START先SCL低SDA释放≥HALF，releaseSCL等实际高，再高≥HALF且SDA高时拉SDA低START，发送devR。

RX连续八位末沿拼完整8bit，之后主机NACK释放SDA第九位；不把它记从机NACK。STOP先SCL低，观察低后拉SDA低并保持≥HALF，释放SCL等高，再高≥HALF后releaseSDA产生STOP；WAIT_RELEASE连续双方高tBUF才rsp/drained。取消已记sticky，只在安全低阶段/字节边界转STOP，已经公开bit/pad状态不通过清rst消失。NACK/AL错误优先CANCEL；所有正常/失败rsp保持。

### E2 ROM

原表只提取实际活动ROM[00…A3]赋值，忽略注释旧IMX219/flag0。24bit={reg16,value8}存一个512×20 RAM10：index i低20在2i，高4零扩在2i+1；328词，其余0。官方INIT_0…27每256bit按物理连续bit填，官方model核映射。WE永0。父RE_LO沿e0发同步RE，e1保存RDATA；RE_HI e2发，e3保存高4并组成完整command，随后ISSUE。未读过RAM不能当地址/值，无同址写语义。预计1 RAM；最终工具报告为准。

### E3 父顺序、提交及终态

enum IDLE/WAIT_POWER/PREPARE/ROM_LO/ROM_LO_WAIT/ROM_HI/ROM_HI_WAIT/ISSUE/WAIT_REPLY/DONE/Q。power_age按platform_ok连续周期饱和到ceil(CLK_MAX_HZ*4000/1e6)；任何下降清age/live。job_fire锁scope/op/addr并清本任务结果/live，核op/地址/tag预算；合法WAIT_POWER，非法DONE ERROR/no I2C。持续取消先清live、记sticky，已有ISSUE保持到master fire，其他无承诺边界可终结CANCEL/drained。

CONFIG段stage ID_HIGH/ID_LOW/ROM_WRITE/VERIFY；STOP段STREAM_OFF_WRITE/STREAM_OFF_READ。PREPARE依据阶段选择静态reg/data/tag或ROM双读；m_req_fire推进next_tag，WAIT_REPLY保存实际读/ACK。rsp错误按实际outcome/drained保存首因/failing reg/phase并DONE；Q notice消费后父留Q，不能新job。ID匹配才进ROM；每write只有OK且drained才writes++。14verify `(read&mask)==expected` 才置对应bit和保存原8bit；全部后writes164/reads16/IDvalid3/mask3fff才registers_verified及live，取消/平台错优先阻live。STOP只有写和读bit0=0才OK，registers_verified/live固定0。

每条已有子请求必须先真实rsp消费；同沿cancel及成功rsp仍记实际传输前缀，再以CANCEL结束，不撤公开body。platform_ok下降无在途时本地ERROR、在途交master Q；已形成terminal保持旧值，live另撤销。scope/cmd_tag/output数量不混旧job，所有新决定读旧状态，非阻塞提交；形成最后mask/终态时使用本次实际read，不错用旧寄存器。无自动重试或新reset/XSHUTDN驱动。

## F/G 语言、验证与实施

SV2009可综合，不复用旧WB逻辑；时序非阻塞/组合阻塞，静态位宽/clog2边界1…200MHz、SCL_HZ=100k、TIMEOUT_US≥100、timeout≥HALF。64bit常量扩展后乘时间，timer宽clog2(CYCLES+1)，计数0…164/16/14不回绕。Python参考用任意精度整数，严格UTF-8/实际原表SHA；SDA从机模型仅验证数字事务，analog/真实模组/CSI不声称验证。ROM官方模型timescale1ns/1ps，clk100MHz实际约束；C++为N/A。

计划本单元13文件：rtl/profile_pkg、profile_rom、i2c_register_master、sc431hai_config；model/config_reference.py；data/sc431hai_profile.json；tb/i2c_sensor_model、tb_i2c_register_master、tb_sc431hai_config；scripts/run_camera_config_sim/map；project/sc431hai_config_component.xml/sdc。另中文docs和baseline，源文件计数排除镜像/数据向量/运行证据/审计helper。原语INIT由提取后的实际数值生成，不事先假定工具把大case当RAM。

| TEST | 观察、期望和范围 |
|---|---|
| CT01 | 原ROM164活动条数/索引连续/flag0/每条24bit与JSON及实际RAM双读逐一一致；全表顺序、stream90及末19不改 |
| CT02 | 独立线边沿从机，随机寄存器write/read、真实重复START/主机末NACK/STOP/tBUF；8bit值00/FF/80/01/极端地址，held req/rsp/错误tag cancel、同沿cancel、无多事务 |
| CT03 | 四write ACK及四read ACK逐个NACK，事务不推进；clock stretch/卡SCL/卡SDA/碰撞释放/enable loss、恢复enable不解除Q；实际安全reset后新job |
| CT04 | 完整profile180事务，原164表逐条比；ID/CD6B、14public readback/body、masked无关位变化可通过，masked位错误明确ERROR，无后续写/verify |
| CT05 | platform_ok不足T4无START、连续资格重新计时；100ms无就绪失败；配置/STOP、scope变化/错误取消/持续取消/末rsp同沿取消/held终态后平台下降live撤销而body保持；tag预算耗尽no START |
| CT06 | cfg的ID/NACK/原ROM任意索引/读回/STOP失败定位、取消各段、未知总线Q、之后共同安全reset完整配置恢复；数字从机的真实wire trace与独立Python期望对照 |
| CT07 | 默认100MHz实际clk/CLK_MAX101MHz/SCL100k完整配置、全180事务时间/SCL low/high/STA/STOP/BUF与T4检查；快速1MHz测试仍保留真实时间最小值，不改变生产参数 |
| CT08 | Ti60F225/I3当前源绑定MAP，实际RAM=1/DSP0预计、读取警告；组件不是板级PNR/STA/bit，后者生产top继续 |

独立参考直接由源表与公开readback字段构造事务列表，TB只驱动SCL/SDA模型ACK/data，不从DUT状态复制其位FSM。真实线采样数量/顺序及从机ACK、读末NACK、start/restart/stop和minimum timing从trace独立核。仿真fatal出口必须非零，RunId新建保留失败，source摘要与MAP一致后登记。

## H/I/J 追踪、自检、授权

SC01身份/保持→父锁scope与子tag→CT02/05/06；SC02真实T4→power_age/WAIT_POWER→CT05/07；SC03源保序/ACK/内容→ROM/父stage/master真实pad→CT01…04/07；SC04 STOP→父STOP段→CT04…06；SC05取消/错误/未知关闭→master STOP/WAIT_RELEASE/Q及父ISSUE保持/通知→CT03/05/06。每个新文件对这些REQ/TEST均有职责，未引入无关功能。

十项自检：整体行为/正常边界B；职责C；具体接口D和tag/已公开请求失资格相容；E各寄存器、单资源/状态、操作/出入、counter及公开保持；F数值/时钟/CDC/pad/语言；B/E失败走查；G增量顺序/独立场景；数字范围没有关键未知，物理范围明确后续；本卡保存/实际读回/聊天入口；本版本/13文件/基线清楚。达到READY后沿既有自主授权实施，不新增逐项批准或修改长期规则。

恢复先读本卡/原table hash/当前run，变化先记J再改，不用通过小图宣称真CSI或板卡通过。K/L实施结果、实际资源与阅读路径完成后另补，只读原始基线与已登记包。
