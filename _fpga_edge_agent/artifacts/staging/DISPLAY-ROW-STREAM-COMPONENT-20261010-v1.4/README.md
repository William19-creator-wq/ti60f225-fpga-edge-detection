# native行消费与连续画面（v1.4，软件联合仿真与组件综合通过）

本包是完整scan的真实视频行消费模块：已生成 `display_row_streamer`，三实例可同时借当前行、候选首行和旧图repeat首行，共享已有renderer。当前TB已真正连接取数核心/运输、native三行RAM和renderer，父是明确固定bundle/byte-slave fixture；生产owner/handoff、候选/repeat仲裁及全scope关闭仍继续。

## 阅读和管理顺序

先读 `inputs/00-design-TRACK4-DISPLAY-ROW-STREAM-001.md` 的外部RS01–06和整体连接，再读接口、中文局部草图、验证/追踪；J1补寄存器保持的读承诺，J2修测试查询动态绑定，J3/J4修证据文件命名和字节表示。`rtl/`为消费者；`deps/`为16份原样复制依赖；`tb/`为真实联合输入环境；`model/`为独立数学/事件/原始像素比较；`scripts/`为现有工具的运行入口；`project/`为Ti60F225/I3组件XML和单video时钟SDC；`runs/`保全部原始尝试及源码快照。

7份自写业务/验证文件、1个新RTL模块；16份复制依赖，共23份源码/工程文件。最新baseline-v1.4为24项冻结输入；`inputs/rtl-before-J1.sv`是另列的变更前版本证据，不多计业务实现。原设计/旧baseline和失败attempt都保留。用户持续自主软件授权和本地审计例外适用，无逐版批准等待、无正式DB或硬件状态改变。

## 中文逐沿操作与源码对应

真正615好回执与native publication都到达后，父给543 reserve；reserve/native row同沿接受，核全文及非0GEN后只借native稳定票据。IDLE→PRIME，创建RE0承诺；真正RE0接受后创建RE1，RE1接受后保持RE2的未接受承诺（P2除外）。native两个真实credit满时压住RE2，首响应地址0真实存在且issued2才prepared。

首DE必须x0、完整479需求/owned/prepared正确；同沿pop0/RE2，然后每DE pop一对并接受下一RE，原pending+两响应槽保证持续双像素。pixel_valid只对应真实native pop，54bit保持RGB48/EDGE2/ANN4；配置render112属于父固定同帧bundle，已有renderer把RGB和同步一起过S0/S1。

早到DE/缺响应/坏身份/间断/取消保已有前缀并黑余行，DRAIN仅兑现已承诺RE和消费真实response，不能撤valid。issued/popped/shown三计数只在真实事件推进；pending用寄存器保持，地址来自只在fire更新的issued，GEN借原native票据。最后正确pair E_n进入S0，S1在E_n+1更新、下游E_n+2消费；tail两位覆盖末尾，信用/承诺/尾部都空才固定kind进入RELEASE。

真正release后VERIFY_RELEASE在下一视频沿核owned0/error0再IDLE。wrong reserve、坏release、多余response、owned意外丢失永久Q保占用和scope；共同qualified冷复位才作废。late discard不会倒改已经固定的CONSUMED。line_error绑定borrow，display_error绑定正在显示的失败行，下一提前reserve不会把旧失败行的剩余黑屏变成有效像素。

local_live/ref仅消费者局部事实；真正core return/GEN推进、transport ACK及父no-future/active/其它银行/renderer全局状态还须分别闭合，不能把此信号直接用作owner RETIRE。

## 当前真实验证事实

最新小/最小/宽6/宽10/1080p五次均通过实际Questa仿真与独立参考；每次六mode连续完整帧及16故障/边界行。五次合计30个正常完整帧、80条故障/边界行。每帧固定同一bundle/scan跨全部行，真实AXI/native，不由TB构造prepared或数据。独立参考读取每条native54、每个RGB/DE/HS/VS/start/x/y/error、完整票据/GEN/真正归还及AXI ID/范围/LAST。

`stream_hd_001`保持生产1920×1080、1100×1125双像素时隙，实际仿真与独立审计均exit0/PASS。六种模式各一帧共7,425,000正常时隙、12,441,600正常有效像素；另16注错行一起共7,440,360时隙、12,472,318有效像素、6,227,061真实native pop、6,492真正core归还。五套合计7,620,008时隙、12,474,726有效像素、6,228,142真实pop、6,696真正归还；15条隔离行经共同qualified复位作废、末个隔离行每套保留共5条，不能把隔离冒称归还。使用数学byte-slave的ideal调度，不代表实际DDR refresh/QoS；生产RO owner/handoff权限未由fixture证明。ANN为数学码型，不是复杂识别产物。每个native二进制记录14字节：bank8/visible8/y16/address16/data64；输出每槽12字节：RGB48/x16/y16/flags16。参考字节/像素/身份要求无容差。

`stream_map_001`实际Ti60F225/I3 MAP exit0：**EFX_FF47、EFX_LUT4 894、RAM/DSP/ADD/SRL0**，warn/err只有工具头。单bank消费者top没有取数核心/行RAM/renderer，不能据此声称完整三bank总top资源或时序通过；本包无板级pin、没有PNR/STA/SDF/bit或硬件动作。

失败保留：`small/min_001`查询frame0含X，J2明确动态组合读集且参考检查全文；`_002`实际22帧仿真exit0但SV空格填充名与Python零填充定位不同，J3统一无填充文件名；`_003`实际22帧仿真exit0但1bit visible写入单字节记录为0，J4明确8bit表示后严格比较通过。均保原日志/二进制/20源快照，不覆盖、不算绿；生产RTL只在J1对齐原读承诺/吞吐契约，J2–4不改生产RTL。

## 运行与追踪

现有PowerShell7运行 `scripts/run_stream_sim.ps1 -RunId 新名字`，几何为默认20×8，`-Minimum`为4×2，`-Width 6/10/20`为对应宽×8，`-HD`为1920×1080。每次新RunId保旧尝试；从开始保存的20源副本编译和审计，前后SHA校验、fatal非零、actual finished和实际exit均保留。MAP入口 `run_stream_map.ps1 -RunId 新名字 -SimulationRun 已通过运行`，先校验成功和当前源再快照，仅执行map。

RS01→reserve/full543/借用→真实receipt/reserve；RS02→PRIME/pending/两credit→prepared/真实RE；RS03/04→DE/full479/54/错误前缀→连续帧与16注错；RS05→三计数/pending/tail/固定release→真实native二进制与release/return；RS06→VERIFY/Q/local_ref→全文scope事件/四Q/三reset作废及末个保留Q。代码、TB及独立数学都按这些稳定符号追踪；修改行为先改中文设计，随后代码和独立期望分别检查。用户理解验收待实际作答，不阻塞软件继续。

完整scan候选/repeat/VS/旧帧关闭、生产Source/结果控制与lookup权利、C2 CRC/晚错、真实DDR模型/QoS、原复杂识别与共享资源、整包top/pins/PNR/STA/最终bit继续原完整目标；不以此叶或小尺寸试验替代原五基础/六高阶/1080p。
