# TRACK4-FRONTEND-001：双像素灰度、中值与 Sobel 局部设计

设计 v1；2026-10-04；状态 **READY_FOR_REVIEW / NOT_APPROVED**。按 [PLAN_TEMPLATE](PLAN_TEMPLATE.md) 编写。本文件是整机 MOD-06/07 的首批详细设计，不改变五基础、六高阶及整机 bitstream 的最终目标；当前没有生成业务实现或可执行测试。

## 通用计划字段

- Goal：完成 RGB888 → 灰度 → 可旁路 3×3 中值 → Sobel 的双像素流内核，并提供未来 Canny 所需的完整滤波灰度输出。
- Current state：整体布局 v0.1 已存在；本批数值、逐拍、缓存、生命周期和软件边界已保存读回并完成独立审查，READY_FOR_REVIEW，尚未实施。
- Target state：先达到可审阅设计，再在明确批准范围内生成 RTL、独立数值参考、协议检查与仿真记录；整机集成仍沿主任务推进。
- Gap：本批指定版本/范围/基线的实施和局部仿真批准未收到。DDR/CSI/引脚等整机缺口继续保留。
- Assumptions：本内核输入已转为同一时钟域、可反压的成对 RGB；此条件不能直接套用于相机物理流。
- Open questions：不以整机未知项替代当前内核契约；当前正确性问题须在 I 节关闭后才 READY。
- Dependencies：现行 v0.2、赛题 T4-B2/B3/A1、整体 02/03 文档、现有 Efinity 2026.1 与 Questa 2024.1、Python 3.14.6。
- Milestones：F0 本设计和复核 → F1 指定版本/范围批准 → F2 各运算和窗口模块 → F3 组合协议回归 → F4 实际报告、草图与代码对照；整机继续主任务 M2–M5。
- Detailed steps：先读 B/C 整体作用，再读 D 交接、E 内部步骤、F 语言契约、G/H 验证与追踪；不从代码文件堆开始。
- State transitions：LOCAL_DESIGN → READY_FOR_REVIEW → 指定批准后 IMPLEMENTING → VERIFYING；不修改正式 H/A/R 状态。
- Artifacts and hashes：沿用整体输入清单；本批实际依赖、设计摘要和复核记录保存到实验 05_reviews，代码路径此时均为计划。
- Validation：设计检查与未运行的功能测试分开。局部成功不能替代 DDR、直播承接、整机资源或时序验收。
- Failure handling：输入故障使整个 job 失效；已交付前缀不得发布为完整结果。控制面实施越界或契约变化先停受影响部分。
- Human approval gates：本批设计 v1 的指定范围批准；工作副本与仿真执行权限同时核对；下载申请为独立 REQ-DDR3-MODEL-20261004，不混为一项批准。
- Rollback：只撤回本批独立 work 中的新文件并保留报告，不改原 HDK、工具目录、正式状态或其他任务产物。
- Completion criteria：本批所有数值、窗口、时序和错误场景有真实证据；整机十一项、布局布线与 bitstream 仍须另有完整证据。

## A. 状态、范围与阅读入口

关联 H3/H4/A1，支持 H5/A2/A4 的后续集成。原要求来源见 [赛题清单](../docs/requirements/TRACK4_REQUIREMENTS.md)；父设计为 [整体布局 v0.1](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md) 与 [交接 v0.1](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)。其中 IF-03/07 的输入适配、IF-08 的灰度/窗口交接、IF-14 的任务结果在本批得到局部细化。

**范围内**：单时钟内核的灰度、两个两行窗口、中值、Sobel、任务配置/协议检查、复位取消；逐位参考与对应单元/组合 testbench 的设计。**范围外**：CSI/RAW/Debayer、无反压流的接纳 FIFO/CDC、DDR 写回和响应、帧槽、按键消抖、Canny 后级、几何识别、HDMI、板级工程/约束和 bitstream。本批完成不会被记成这些功能已经完成。

拟实施根路径为 `_fpga_edge_agent/work/active/track4_full_sw_20261004/`，当前尚未创建。RTL 在 `rtl/frontend/`，测试在 `sim/frontend/`，参考在 `model/`，运行入口在 `scripts/`。原 v6 或 Demo 灰度模块不直接复制为本批实现。

基线事实：Python 实际输出 `3.14.6`；Efinity RAM10 本地模型声明 1R1W、同址读写结果不确定，因此 E 节主动避开冲突。本批基线 **FE-BL-20261004-v1** 的28项实际输入SHA256见 [frontend-baseline-v1.json](../experiments/track4_full_sw_20261004/01_baseline/frontend-baseline-v1.json)，不伪造 Git commit。

批准状态为 **NOT_APPROVED**。继续完整软件实验的目标授权用于推进调查与设计；它不被解释成已批准这份刚形成的局部设计。官方模型下载申请仍为 PENDING。

## B. 整体外部行为

| REQ | 可检查行为与来源 |
|---|---|
| FE-01 | 接受一个 job 后按行优先接受 W×H 个 RGB888 像素，每次恰好两个；输出同样数量、顺序和原图坐标；派生自整体 IF-03/07/08 |
| FE-02 | Y = floor((77R + 150G + 29B + 128)/256)，移位加法实现，不使用除法器；T4-B2 的本批数值提议 |
| FE-03 | 中值开启时，对完整有限 Y 图作独立复制边界的 3×3 中值；关闭时 M(x,y)=Y(x,y)；T4-A1 |
| FE-04 | 在完整有限 M 图上重新复制边界作规定的 Sobel，L1=abs(Gx)+abs(Gy)，edge=(L1>T)；T4-B3 |
| FE-05 | 配置和三项身份只在 job 接纳时锁存；运行期间变化不影响在途像素；支持后续 T4-A2 的帧级配置语义，不包含按键实现 |
| FE-06 | ready/valid 停顿保持数据和伴随信息；无效不是零像素，气泡不推进输入坐标；派生接口要求 |
| FE-07 | 非法输入、取消、复位和终态的行为确定；局部 OK 不代表 DDR 完成或结果可发布；派生完整帧要求 |
| FE-08 | 2 像素/推进拍稳态结构；100MHz 是设计目标，资源/吞吐以实际后续工具结果验收，不声明整机已达到实时性 |

生产尺寸 W=1920、H=1080。仅为同一结构的边界和快速回归，支持编译期偶数 W∈[4,1920]、H∈[3,1080]；不是运行期缩放，也不降低生产分辨率。D=W/2，N=D×H 是一帧成对事务数。非法参数在仿真展开检查中报错，硬件交付只采用合法参数。

输出模式 `Y_ONLY=0` 或 `SOBEL=1`。两模式均输出完整 M，字段名 `out_y_filtered`；Y_ONLY 的 edge 固定为 0，未来 Canny 自己构造 Gaussian/梯度窗口，不把零 edge 当作 Canny 结果。SOBEL 同时输出同坐标的 edge。两模式沿同一流水路径，避免分支合流的坐标错位。

正常样例：黑、白、纯红、纯绿、纯蓝分别得到 Y=0、255、77、149、29；特别是纯绿不是 150。常量 RGB 图在两种中值配置下均为常量，T=0 时 Sobel 全零。竖阶跃的一个窗口每行 [0,0,255]，Gx=1020、Gy=0，T=1019 为边缘、T=1020 非边缘。

边界整图：W=4、H=3，每行灰度 [0,1,2,3]，中值开/关均不变，Sobel 每行 L1=[4,8,8,4]；T=4 时 edge=[0,1,1,0]。第一个有效输出仍对应 (0,0)，不能把窗口右下角当输出坐标。

状态样例：输出阻塞时切换外部阈值，挂起结果及当前 job 后续结果仍采用旧快照。最后输出交付同沿取消，该 job 为 CANCELLED。缺失末像素 EOF 即 INPUT_ERROR，不能由像素计数擅自补成成功。

## C. 模块与连接

```text
上层任务调度/未来输入适配
   │ FJ-01 job身份/配置；FP-01 成对RGB/坐标/标志，可反压
   ▼
F0 frontend_frame_pair：接纳、检查、配置、计数、取消和终态
   │ 只向流水投递合法的当前job像素
F1 rgb_to_y_pair：三级定点灰度
   │ FP-02 成对Y
F2a window3x3_pair：两行历史 → 两个相邻3×3窗口
   │ FW-01 窗口与中心坐标
F3 median9_pair：九级比较网络/等延迟中心旁路
   │ FP-02 完整M图
F2b window3x3_pair：另两行历史 → 对M再次补边的窗口
   │ FW-01
F4 sobel_pair：六级梯度/绝对值/求和/阈值，携带中心M
   │ FO-01 成对M与edge、同源身份/坐标
   ▼
未来Canny灰度接收者 或 Sobel结果写入者
   ▲ FS-01 不可变status，表示局部终态
```

F0 属于 MOD-06/07 的局部生命周期封装，不夺取 MOD-04 的帧槽/引用所有权。F1 无帧历史；F2 拥有各自两个行 RAM、一次未消费读回、水平历史和输出寄存器；F3/F4 只拥有流水寄存器，配置借用 F0 的不可变快照。两个 F2 共四行历史，每个 3×3 算子仍恰用两行，不能把完整中值+Sobel 链声称为总共两行。

全链无反馈依赖。各运算模块独立停顿，窗口的底行/尾组由内部有限事件推进，不能因为输入 valid=0 或窗口暂时不接新输入而冻结这些内部事件。下游永久不 ready 时允许等待；上层可取消。这个核没有 DDR 锁、动态申请或其他帧借用。

## D. 端口、接口与组合检查

全部端口均属 `clk` 上升沿域；`rst` 为同步高有效复位。除下表注明 signed 的梯度诊断值之外均 unsigned。`valid && ready` 在边沿前为真即发生传输；复位边沿不发生接口传输，顶层在 rst=1 时将所有 ready/valid 输出屏蔽为 0。

| IF / 端口 | 方向（相对内核）与位宽 | 含义及前置/保证 |
|---|---|---|
| FJ-01 `job_valid/job_ready` | 入/出，各1 | IDLE 接纳；同沿不接首像素，首像素最早下一沿 |
| `job_epoch/job_frame_id/job_config_id` | 入，各32 | 允许0，仅按相等识别，不作大小排序；上层保证旧任务排空前不重用身份 |
| `job_median_enable` | 入1 | 0取原Y中心；1取9点中值 |
| `job_output_kind` | 入2 | 0 Y_ONLY，1 SOBEL；2/3接纳后返回BAD_CONFIG，不接数据 |
| `job_threshold` | 入11 | 0…2047，单位为未缩放Sobel L1；严格大于 |
| FP-01 `in_valid/in_ready` | 入/出，各1 | 仅ACTIVE接纳；FLUSH/STATUS关闭；valid=0忽略其他输入 |
| `in_rgb` | 入48 | lane0在[23:0]，lane1在[47:24]；每lane按R高8、G中8、B低8；恰好两lane有效，无mask |
| `in_x_even/in_y` | 入，各11 | lane0的原图坐标；必须等于当前预期偶数x及y，lane1=x+1 |
| `in_sof/in_eol/in_eof/in_bad` | 入，各1 | SOF仅(0,0)，EOL仅x=W-2，EOF仅(W-2,H-1)；bad标当前事务源错误 |
| FO-01 `out_valid/out_ready` | 出/入，各1 | 正常停顿保持全部输出；取消/输入错误允许撤销尚未交付输出，整job作废 |
| `out_y_filtered` / `out_edge` | 出16 / 出2 | lane0低8/低1；lane1高8/高1；Y_ONLY的edge为0 |
| `out_x_even/out_y` | 出，各11 | 与M中心相同的原图坐标；由窗口中心派生，输出仍行优先完整帧 |
| `out_sof/out_eol/out_eof` | 出，各1 | 由输出坐标生成，与数据一起保持 |
| `out_epoch/out_frame_id/out_config_id` | 出，各32 | F0锁存的当前job身份；不可从当前外部job输入直接连出 |
| `cancel` | 入1 | ACTIVE/FLUSH有效；IDLE/STATUS忽略；当沿禁接新输入，旧输出若已握手仍计入交付数，整个job无效 |
| FS-01 `status_valid/status_ready` | 出/入，各1 | 内容首次形成后保持到消费；消费沿不接下一job，下一沿才可接纳 |
| `status_code` | 出3 | 0 OK，1 CANCELLED，2 INPUT_BAD，3 COORD_ERROR，4 MARKER_ERROR，5 BAD_CONFIG，6 COUNT_ERROR，7保留 |
| `status_epoch/status_frame_id/status_config_id` | 出，各32 | 被终结job的身份，STATUS期间不可变化 |
| `status_in_pairs/status_out_pairs` | 出，各21 | 实际接受/交付的成对事务数；坏输入握手计入in，取消沿已交付输出计入out；不把被撤销输出计入 |
| `status_error_x/status_error_y` | 出，各11 | 输入错误记录该坏事务的输入坐标；其他状态固定0，不伪造源相机错误定位 |

FP-02 内部像素接口为 `valid/ready`、16bit两像素、11bit偶数x/11bit y、SOF/EOL/EOF。FW-01 为同样握手/中心坐标/标志加144bit窗口：lane0占[71:0]、lane1占[143:72]；每lane按行优先 a…i 各8bit，a占最低8bit、i占最高8bit。F3输出中心 M；F4输出中心M及edge。单元 F4 另有 `out_gx_pair/out_gy_pair/out_l1_pair` 各22bit诊断输出，lane0占[10:0]、lane1占[21:11]；Gx/Gy每lane分别解释为11bit二补码signed，L1每laneunsigned，不能将整个22bit组当一个有符号数。它们同延迟、共用F4输出valid/ready用于数值测试；顶层不存这些诊断图。

没有给每个内部像素重复存三项身份：本核同时仅一个job，身份快照保持到status消费，所有历史valid清空后才允许下一job。输入适配必须在本核边界前剔除旧DDR响应/跨帧遗留数据；本核不能凭一组重复坐标判断未携带身份的像素来源。

| 组合检查 | 结论与适配责任 |
|---|---|
| RGB→灰度 | RGB量化由上层负责，本核严格8bit RGB；48bit lane/通道定义无隐式交换 |
| 灰度→窗口1→中值 | 只按真实接受推进；replicate是读取坐标映射，不插入外部零像素；中心身份原样传递 |
| M→窗口2→Sobel | 先形成完整有限M图，再独立复制M边界；不是一次扩展原Y后共用外侧值 |
| 旁路/模式 | 中值关闭仍经过窗口1并延迟中心9级；Y_ONLY仍经过窗口2及F4的6级中心通道；不存在可变延迟合流 |
| 下游停顿 | 各模块通过输出容量决定推进；灰度/中值/Sobel流水统一冻结该模块全部阶段，窗口另外允许内部补边事件；无输入不能阻止内部排空 |
| 相机直播 | 当前ready接口不能直连不可反压CSI；未来IF-03适配必须证明FIFO最坏积压、突发与帧尾余量，平均带宽比较不足以验收 |
| 任务结束→结果发布 | 局部OK仅代表本核交付完整输出；源有效、DDR写响应和同源bundle仍由MOD-03/05/10检查 |
| 未来Canny | 接收Y_ONLY的M图并建立自己的高斯/梯度窗口；本批不承诺Canny的完整闭包或识别质量 |

## E. 局部详细设计与中文操作草图

### E1. F0：接纳、检查、完成和作废

状态为IDLE、ACTIVE、FLUSH_TAIL、STATUS。锁存的三ID/配置、预期组号q(10bit)/行r(11bit)、输入/输出计数(21bit)、首次错误坐标和状态码由F0拥有。复位后IDLE、所有valid和计数为0，不要求RAM数组清零。

中文步骤 OP-01：

1. IDLE依据旧状态决定job_ready=1、in_ready=0；接受job的沿锁住全部字段并把计数置0。kind非法则形成BAD_CONFIG；合法则向内部发同域 `frame_start` 事件、清空有效历史，下一沿进入ACTIVE接首像素。
2. ACTIVE的in_ready取决于F1接收能力，cancel或rst时为0。一次输入握手先计入in_pairs，再检查bad、预期坐标、SOF/EOL/EOF；错误事务不进入F1。合法事务才推进q/r；每行D组，最后合法组之后进入FLUSH_TAIL，不再接受真实输入。
3. 每次输出握手令out_pairs加1。输出只是候选结果流，接收方必须等待最终局部OK、源有效与全部DDR写响应成功才能提交整机结果。
4. FLUSH_TAIL继续允许内部底行replay和算术流水排空。最后输出实际交付后，至少再经过一个边沿确认所有算术valid为空、两个窗口回到IDLE且输入/输出计数均为N，才锁存OK status。数量不等或输出坐标/末标志不符应在验证中失败；合成计数检查失败返回COUNT_ERROR。
5. STATUS不接新job/像素，status及其所有字段保持。status消费沿只回IDLE，下一沿可接下一job；新任务的首像素再晚一沿。

优先级为rst > cancel > 输入错误 > 正常推进/成功。取消仅作用ACTIVE/FLUSH_TAIL。输入错误同沿按bad > 坐标 > 标志选择首次原因。rst使接口传输无效并清空控制；cancel/error在当前边沿清空所有内部valid、pending及水平有效状态，并禁止该沿RAM读写，RAM数据保留。输出已在cancel/error边沿满足valid&&ready的旧组仍按真实握手计数，但该job整体作废；尚未交付的输出撤销，是明确的保持规则例外。错误状态一旦锁定进入STATUS就不可因后续cancel改写。

`in_bad`只在输入握手时观察；无像素交接时上层发现源错，以cancel通知，并在上层保存真正原因。status已经形成后才发现的源损坏由MOD-03/10拒绝发布，本核不能回写已交付的OK。缺失EOF但最后位置已到达属于标志错误；输入停在半帧且永不继续则等待上层取消，没有自设超时丢帧。valid高而ready低是等待，不是额外像素错误。参与握手的控制/状态及实际接受或交付的有效payload出现X/Z时测试失败；valid=0时未使用的payload忽略，不虚构硬件能检测四态X。

输入错误产生的flush用于本沿状态清理，不通过组合屏蔽内部ready来反向消除触发错误的输入握手；不得形成“错误→flush→ready低→错误消失”的组合环。cancel来自独立控制端口，可以提前令in_ready低。取消/错误沿旧输出交付依据沿前有效信号计数。

不变量 INV-01：同时最多一个job；INV-02：向F1投递的合法RGB组数≤输入接受数≤N；INV-03：输出计数只按握手推进、OK时恰为N；INV-04：STATUS不可变；INV-05：取消后的旧历史不参与下一job。

### E2. F1：三级灰度与数值范围

OP-02：第一个算术沿将每个RGB分量先零扩为16bit，再以移位加法形成77R、150G、29B；第二沿形成R项+G项与B项+128；第三沿将两项相加，取总和[15:8]形成Y。相应valid/坐标/标志每级一起推进。

三个乘积上界分别19635、38250、7395，总和上界65280，加128后为65408；所有算术用16bit unsigned，不溢出。不是先在8bit内移位后再扩展。除以256是固定取位，无除法器；无饱和、无回绕。RGB三通道同为q时精确输出q。

每个固定级数算术模块的本地推进条件为“末级为空，或该沿末级会被接收”。推进时各级基于旧级数据形成新寄存器，输入无事务就在首级插入valid=0气泡；不推进时整个本模块所有数据、valid、中心与坐标保持。`frame_start/flush/rst`能独立于停顿清除valid。F3/F4采用同一规则；不存在由整个链路in_ready反推一个全局冻结的依赖环。

### E3. F2：每级两行存储的所有权、端口和中文步骤

**物理职责F2R `line_store_pair`**：一行D×16bit，两个lane分别放入一块EFX_RAM10；每块READ_WIDTH=WRITE_WIDTH=8、深度1024、OUTPUT_REG=0、WRITE_MODE=READ_FIRST，读写同clk且为上升沿。WCLK/RCLK接clk，RADDREN/WADDREN固定1，RE为读使能，WCLKE为写使能，WE[0]为写使能（WE[1]固定0，8bit模式不使用）；极性参数显式采用高有效。RST固定0，读输出的残留由pending有效位隔离。地址10bit，任何有效访问必须q<D，生产时960…1023不访问。提供 `rd_en/rd_addr→rd_pair`、`wr_en/wr_addr/wr_pair`；使能各1，地址各10，数据各16。读请求在一个边沿后更新读输出，下一推进沿消费；RE=0保持读输出。两个lane读写完全同步，不能各自停顿。

每个F2实例拥有recent与older两个F2R，共4块RAM10。REAL第r行的读请求看到recent[q]=第r−1行、older[q]=第r−2行，适用前提是这些历史行有效。第0行的历史读值忽略；第1行不使用older。

内部端口补充：F1/F2/F3/F4流模块接1bit `frame_start`、1bit `flush`；F0在job接纳沿发start、取消/错误沿发flush。这些流模块各提供1bit `empty`，运算块表示全部valid空；窗口表示phase=IDLE且pending/horizontal/output均无效。F2R不额外提供start/flush/empty，它的读回有效性由F2 pending管理。优先rst/flush再start再正常推进。start令窗口phase=REAL；rst/flush令phase=IDLE、pending=NONE，清horizontal/output有效位，不清RAM内容。

F2状态分为发起阶段phase=IDLE/REAL/REPLAY/TAIL/WAIT_EOF，和一次待消费的pending_kind=NONE/REAL/REPLAY/TAIL。另有pending的q/r/真实输入pair、两个读回值、一个输出窗口寄存器；水平历史详见下一小节。发起阶段和pending不可用同一个状态变量混淆：同一沿可能消费旧REAL并发起新REPLAY。

OP-03：

1. 输出寄存器为空或将被接收时，窗口允许推进；否则禁止读写、禁止接受新输入并保持全部状态，RAM读回也保持。窗口的in_ready只在REAL且允许推进时为1。
2. 每次推进先基于旧pending消费前次读回，最多提交一次延迟写；再依据旧发起阶段决定是否发新读/内部事件。没有新事件时pending变NONE，不能重复消费旧读回。
3. 真实输入组q在e[k]接受并读两行RAM；e[k+1]消费旧读回时把当前pair写recent[q]。r≥1时还把旧recent写older[q]；r=0不写older。同沿最多读后一个组地址。持续流下读q+1、写q；跨行读0、写D−1，因D≥2不相同。
4. r=0只填行存储，不建立可输出水平历史。r=1形成垂直列“recent、recent、当前pair”；r≥2形成“older、recent、当前pair”。这些都是本沿更新前的RAM读回。
5. 接受真实末组后，发起阶段转REPLAY；下一可推进沿发底行q0读，同时可以消费并提交真实末组的延迟写。REPLAY自身不写RAM，其垂直列为“older、recent、recent”。因此“在REPLAY阶段绝不写RAM”并不准确，应按被消费pending的类型决定写使能。
6. REPLAY发D个读请求后安排一个TAIL事件。消费最后REPLAY后再消费TAIL，形成最终右边界组。WAIT_EOF不接输入也不发读；最后窗口实际交付且pending为空后回IDLE。

INV-06：同沿同一bank读写都使能时地址必不等；输入气泡时可以只提交旧写、不发新读。INV-07：pending最多一个，old读回在被新读覆盖前已消费，反压时读输出与metadata一起保持。INV-08：没有RAM全清零依赖，下一job第0行覆盖recent，第1行顶部复制忽略旧older，之后才使用已更新older。

### E4. F2：水平历史、行交接和帧尾

每个读回组形成列2q、2q+1两个三元素垂直列，各24bit。水平历史只有：左邻列L、当前组列C0/C1（共72bit）、所属输出行/组号、有效位。它不是第三条行缓存。

OP-04：

1. 首个可输出行的q0到达时，保存C0=列0、C1=列1、L=列0，实现左边复制，此时不产生窗口。
2. 同一行q≥1到达时，lane0窗口取旧(L,C0,C1)，lane1窗口取旧(C0,C1)和新组首列。窗口中心分别为2q−2、2q−1；然后提交L=旧C1，C0/C1=新组两列。
3. 下一输出行q0到达时，用旧历史生成上一行最后一组：lane0=(L,C0,C1)，lane1=(C0,C1,C1)，右列复制；同一沿用新行两列初始化新的L/C0/C1。输出属于旧行，新历史属于新行，不能将二者坐标混用。
4. 最终TAIL没有新读数据，只按步骤3的旧历史右边复制生成最后一组，随后清horizontal有效位。SOF/EOL/EOF由窗口中心坐标生成，窗口lane的三列转成FW-01规定的行优先9字节布局。

该安排每行没有固定气泡。无输入气泡/反压时，首窗口形成后连续产生N组；底部复制额外读取D组、最终多一个TAIL事件，但对外仍仅N组。

OP-05单窗口边沿表（e0接受首个Y pair）：

| 边沿 | 发起 | 消费旧状态、输出变化 |
|---|---|---|
| e0 | 真实r0/q0读 | 无旧pending |
| e1 | 真实r0/q1读 | 写r0/q0，无输出 |
| eD | 真实r1/q0读 | 消费r0末组，无输出 |
| e(D+1) | 真实r1/q1读 | 消费r1/q0，建立水平历史 |
| e(D+2) | 后续读 | 消费r1/q1，沿后首窗口(0,0)有效 |
| e(D+3) | 后续读 | 下游最早交付首窗口 |
| eN | REPLAY q0读 | 消费真实末组，仍有最后一次真实延迟写 |
| e(N+D−1) | REPLAY末组读 | 消费前一REPLAY |
| e(N+D) | TAIL事件入pending | 消费末REPLAY |
| e(N+D+1) | 无 | 消费TAIL，沿后EOF组有效 |
| e(N+D+2) | 无 | 下游最早交付EOF |

W8/H3时D4/N12，首组e7交付、末组e18交付。若e6后首组已valid，e7/e8下游不ready，这两沿所有历史/pending/读写冻结，e9交付原组并继续消费旧读回。若r1/q0在e4接受、e5输入无效，e5仍消费q0并提交其延迟写；q1到e6才来，首组e7后形成。不能把e5当黑像素或再次推进列计数。

### E5. F3：19比较器中值与九级中心旁路

OP-06：每lane独立处理9个unsigned8。三行分别排序成Lr≤Mr≤Hr；令A=max(L0,L1,L2)，B=median(M0,M1,M2)，C=min(H0,H1,H2)，结果取median(A,B,C)。所有比较保持重复值的数值，不需要人为增加序号打破相等。

| 级 | 每lane基于前级寄存器的操作 | 比较器数 |
|---|---|---:|
| M1 | 各行前两项比较交换，第三项同行传递 | 3 |
| M2 | 各行前级较大值与第三项比较交换 | 3 |
| M3 | 各行余下两较小值比较，得到行L/M，H传递 | 3 |
| M4 | L0/L1取max，H0/H1取min，M0/M1取min与max | 3 |
| M5 | 前两分支与L2/H2比较形成A/C；中间分支取min(max(M0,M1),M2) | 3 |
| M6 | B=max(min(M0,M1),前级中间值)，A/C传递 | 1 |
| M7 | A/B取min与max，C传递 | 1 |
| M8 | 前级max与C取min，前级min传递 | 1 |
| M9 | 两剩余值取max，形成中值 | 1 |

共19/lane、38个8bit比较器，这是结构计数而非综合报告。原中心Y沿9级传递；median_enable=0时取这个中心，不能直接组合旁路。每一级实际需要的值、中心与坐标同时停顿。

正确性理由：对任意阈值二值化，令每行低值数为k0/k1/k2。A低当且仅当三行都至少1个低值；B低当且仅当至少两行各至少2个；C低当且仅当至少一行有3个。三个条件至少两个成立，等价于总低值数≥5，故结果为九值第五顺序统计量。获批后用512种二值窗口及独立排序参考核验该网络。

### E6. F4：六级Sobel、符号与严格阈值

窗口a…i按行优先。Gx=(c+2f+i)−(a+2d+g)，Gy=(g+2h+i)−(a+2b+c)。

OP-07：S1形成四组角点相加（9bit）与四个中间像素×2（9bit）；S2相加形成右、左、下、上四侧和（10bit unsigned，0…1020）；S3各侧先零扩展成11bit signed，再相减得到Gx/Gy；S4取绝对值（10bit unsigned）；S5先零扩展为11bit再求L1和；S6比较L1>T形成edge，并同时交付延迟6级的中心M、Gx/Gy/L1诊断和坐标。

Gx/Gy范围−1020…1020，合法输入不出现−1024；绝对值没有最负数陷阱。L1真实联合上界是1530：abs(Gx)+abs(Gy)=max(±Gx±Gy)，四个合并核正系数和均为6，故最大6×255。11bit承载幅值和0…2047阈值。T≥1530均无边缘；加阈值使边缘集合不增加，不保证每次加1都恰好少一个像素。

Gx/Gy在S3产生后随S4/S5/S6继续寄存；L1在S5产生后于S6再寄存。诊断、edge、中心M及坐标共用同一输出握手和保持条件，不得把S3/S5实时寄存器直接连到S6诊断端口。

极值窗口 [0,0,0;0,任意,255;0,255,255] 得Gx=Gy=765、L1=1530，T1529为1、T1530为0。Y_ONLY仍按6级传中心和标志，edge=0；本版保留同一路径，不引入另一套短延迟旁路。

### E7. 时间与资源预算、端到端走查

在没有气泡/停顿的条件下，p级算术模块于e[k]接受，末级在e[k+p−1]后更新，下游e[k+p]接受。本链F1=3级、F3=9级、F4=6级；两个窗口各首次交付等待D+3沿。首RGB在e0接纳，首输出在e(2D+24)交付，末输出在e(N+2D+23)交付。接纳job、status形成/消费及下一job的空隙另计；有停顿时按实际推进事件与窗口填充计算，不许宣称固定物理延迟。

1080p的D=960/N=1,036,800，100MHz无停顿首结果约19.44μs，末结果约10.38743ms。设计稳态2像素/推进拍，即200M像素/s；这不是相机fps、HDMI刷新率或整机有效处理fps实测。

每窗口逻辑存储2×960×16=30,720bit，两窗口61,440bit；显式共8个RAM10，约占256块的3.125%。逻辑有效位数与物理分配量分开，8块物理容量81,920bit。DSP设计目标0，MOD-06/07预留上限6,000 XLR；后续真实综合若超预算或100MHz不满足，须记录失败并分析，不能把结构估计写成综合通过。所有RAM与数据路径均同域，本批没有CDC。

端到端正常走查：job锁定→首RGB按预期坐标接受→F1量化→F2a按原Y复制边界→F3生成完整有限M→F2b对M重新复制边界→F4形成同坐标M/edge→输出逐组交付→两个窗口EOF排空→下一个边沿核对全空和N计数→不可变OK。边界走查采用B的4×3图；失败走查在第二行错EOL，坏组握手被计数但不入流水，旧前缀作废，flush不受背压阻止，status消费后下一job从新第0行重新建立历史。

## F. 语言与跨语言契约

本批RTL使用SystemVerilog 2009可综合子集；时序非阻塞、组合阻塞并完整赋默认值。计划参考为Python 3.14.6标准库逐位模型，不引入C++，因此C++对象/RAII条款不适用。参考以有限二维整图和直接邻域索引计算，禁止复制RTL行缓存或比较网络来“自证”。

共同数值契约见B/E；硬件执行由D/E的握手、逐沿和取消定义；对应关系以(job三ID,x,y)定位，两个lane分别比较，不靠模拟时间猜坐标。只有成功job要求W×H逐像素相等；取消/失败job仅核查实际交付前缀与作废状态，不冒称完整结果。

Python参考输入是不可修改的RGB行优先序列和显式尺寸/配置，先检查值域/长度/尺寸，再分配并返回新的Y/M/Gx/Gy/L1/edge数组；输入输出不共享可写别名。整数为任意精度，按本契约有界结果显式检查后导出，不依赖截断偶然一致。纯计算无文件/网络副作用；验证向量I/O在单独调用层，限定本批sim输出目录，错误立即停止，不能覆盖已有成功日志。单线程、固定种子；不设计并发共享数组或后台服务。

### F1. 软件参考、向量与测试平台交接

| 接口/计划签名（无实现体） | 输入表示、输出与错误契约 |
|---|---|
| `gray_image(rgb, width, height)` | rgb为长度W×H的不可变序列，元素为三元整数tuple(R,G,B)，各0…255；返回新建行优先Y整数list，索引y×W+x |
| `median_image(gray, width, height, enabled)` | gray为同长度0…255整数序列，enabled为bool；返回新M list，即使旁路也不返回输入可写别名；邻域坐标各自夹紧 |
| `sobel_image(filtered, width, height, threshold)` | filtered为M，threshold0…2047；返回字典键gx/gy/l1/edge，各为长度W×H的新list；gx/gy有符号整数，edge只0/1；计算不依赖job模式 |
| `generate_vectors(output_directory, suite_name)` | suite_name仅`frontend-v1`；目录必须不存在，创建后生成本表定义的case文件与manifest；参数错抛ValueError，I/O错误向调用层传播，保留未完成目录并标INCOMPLETE |
| 参考CLI | 仅`--out-dir`绝对目录及`--suite frontend-v1`，使用G表固定种子；成功退出0且manifest完整，参数/范围错退出2，I/O或内部校验错退出1；无下载/安装 |
| 仿真入口CLI | `-RunId`必需，只接受字母/数字/下划线/短横线；输出目录固定work根下`sim/frontend/runs/<RunId>/`，已存在即拒绝；runner仅先创建run根，再令参考CLI创建尚不存在的`run/vectors/`子目录；无覆盖/自动清理开关 |

所有图像接口先验证尺寸与完整长度，元素必须是整数（拒绝bool冒充数值）、值域合法；输入不能并发改变。格式验证完毕再返回计算结果，失败不返回部分图。单元向量可由纯标量/窗口运算生成，采用同样数值规则，窗口本身恰好9项；不把任意单元case计数误当图像尺寸。

`manifest.json`为schema_version=1，保存design_version、用到的设计/RTL/参考模型/厂商模型SHA256、suite、固定种子与cases数组。每case含唯一case_id、kind、W/H（图像case适用）、三ID、median_enable、output_kind、threshold、stimulus_pairs、expected_pairs、scenario、输入/期望相对文件路径及SHA256。路径只允许该新run目录内文件，拒绝绝对路径、`..`和同名重复。生成完所有文件且核对数量/哈希后最后标为COMPLETE；runner只接受完整manifest。case_id亦只接受字母/数字/下划线/短横线。

向量文件为UTF-8无BOM的ASCII十六进制纯文本，一行一个成对事务、小写、无`0x`、无注释；不足高位补0，多余高位必须为0，行数严格等于manifest声明，不以短文件余留RAM值补齐。case类型固定如下：

| kind | stimulus每行 | expected每行 |
|---|---|---|
| gray | 48bit RGB，12个hex字符 | 16bit Y，4个hex字符 |
| median | 144bit两窗口，36个hex字符 | 16bit M，4个hex字符 |
| sobel | 144bit两窗口，36个hex字符 | 84bit，21个hex字符；[15:0]中心M、[17:16]edge、[39:18]Gx pair、[61:40]Gy pair、[83:62]L1 pair |
| window | 16bit成对Y，4个hex字符 | 144bit窗口，36个hex字符 |
| frontend | 48bit RGB，12个hex字符 | 18bit，5个hex字符；[15:0]M、[17:16]edge，其余两高位0；Y_ONLY edge固定0 |

每个signed梯度lane按11bit二补码编码；导出前检查−1020…1020，负值加2048后编码，读回若bit10为1则减2048。不能把负十进制字符串交给hex读入器。图像case第j行向量对应y=floor(j/D)、x_even=2×(j mod D)，坐标/标志由TB独立生成和核对；单位窗口case坐标按既定序列传递，TB验证只变延迟不变标志。

TB从runner传入case_id、输入/期望路径及manifest中已验证的尺寸/配置/身份/scenario；runner将每项作为独立进程参数传入，不用字符串拼接执行命令。W/H以编译/展开参数覆写一致传给DUT和检查器。TB严格读声明条数并检查EOF，禁止忽略额外条目。完整图有效结果按同坐标逐lane比对；scenario用于在指定输入/输出位置插入气泡、停顿、协议错、配置扰动、取消/复位，由独立协议检查记录而非改变数值期望。

runner固定调度G的全部必要case；FT-11四个全尺寸job明确覆盖(median关闭,Y_ONLY)、(开启,Y_ONLY)、(关闭,SOBEL)、(开启,SOBEL)。正常frontend case期待N对输入/N对输出/OK；gray/median/sobel/window单元按manifest声明的stimulus_pairs/expected_pairs核对，status=N/A，以末输出、该流模块empty及有限测试结束判断完成，不等待不存在的F0 status。正常case必须compared_pairs=expected_pairs且numeric_errors=protocol_errors=0。

错误与取消case的status/注入位置/允许交付前缀由scenario预先声明，实际握手计数独立记录，不能在失败后重写manifest；期望协议违规只在指定注入位置豁免，其他协议错误仍计失败。同步reset会撤销旧job，旧job不要求返回status；检查旧valid/状态清空及下一job正常恢复。每case报告case_id、status、accepted_pairs、delivered_pairs、compared_pairs、numeric_errors、protocol_errors、finished。runner核对异常case完成预定注入、实际交付前缀均已比较且没有错误结果当OK，复位case的新job恢复成功，以及所有case都finished；不能只查PASS字符串。

小图窗口/组合/取消case保留可读WLF（输入、握手、q/r、pending/phase、RAM使能地址、输出、status）；全尺寸记录计数/控制与失败附近信息，避免无目的展开全部RAM生成巨大波形。终端失败、超时、缺失结果或未执行case均返回非零，保留日志和完整运行目录。局部报告不能把FT-12未来综合/STA栏自动写PASS。

| RTL项 | 本批具体约定 |
|---|---|
| A 数值 | D端口宽度、E2/E5/E6整数界限及舍入；无隐式8bit移位/有符号比较 |
| B 时钟/观察 | 一个clk，上升沿；验证在下降沿驱动、下个上升沿前值判握手，边沿后稳定阶段观察新寄存器，避免NBA竞争 |
| C 接受/交付 | D的valid&&ready；job与首像素分沿，最后输出形成不等于交付 |
| D valid/推进 | E2本地流水气泡；E3旧pending可在输入气泡时消费；不把无效当0 |
| E 反压 | 每模块末级容量决定推进；全部数据/标志保持；rst/flush为撤销例外 |
| F 延迟/吞吐 | E4逐沿与E7无stall推导；测试分别核验事件次序和周期 |
| G 复位 | 高同步、禁传输；RAM不清零；有效历史隔离及新任务前两行建立 |
| H 配置 | FJ-01整job原子锁存，活动值变化与同沿未来配置不影响已接纳job |
| I 存储 | E3显式1R1W、1024×8、地址q<D、同址禁止、每窗口有限在途容量 |
| J 身份 | F0单job三ID保持；两lane/中心坐标/两次独立replicate，完整数量 |
| K CDC | 本核N/A：全部同clk；上层CSI/DDR/HDMI CDC仍须单独设计和验证 |
| L 实现 | SV2009、Ti60F225、100MHz目标、8RAM10/0DSP/≤6000XLR预算；报告未生成 |

## G. 实施与验证计划（未运行）

所有拟新增RTL、模型、脚本和testbench均须在指定批准之后生成。实施次序为F2R端口适配及窗口→F1/F3/F4各自数值→F0组合生命周期→全1080p回归→实际代码/草图/接口一致性核对。先写获准测试再写实现也遵守相同范围。若工具模型接口、延迟或资源与设计冲突，先记录和修订受影响契约。

仿真拟用现有Questa 2024.1，10ns主时钟，现有EFX_RAM10模型只读参与编译；不调用原参考工程含删除命令的脚本。计划运行器 `scripts/run_frontend_sim.ps1` 仅定位已有工具、检查前提、建立带运行ID的新输出目录、按依赖编译/展开/运行、检查明确结束/比较计数、收集退出码/日志/WLF/hash；任一步失败非零返回，不安装、不下载、不更改全局许可/环境、不触碰原工程、不删除前次输出。进程级许可沿用现有本机设置，不记录凭据。脚本只允许操作本批work与报告目录，不能代跑整机综合。

参考 `model/frontend_reference.py` 负责纯数值及固定种子输入生成，导出成对输入和按坐标期望；testbench只使用导出期望/手算窗口与独立协议计数。TB不得通过强制done、屏蔽错误或修改期望绕过失败。每项必须正常终止、实际比较量达到计划、无数值/协议/RAM地址错误；退出码0或单条PASS不够。

| TEST | 目标 | 输入/事件和期望依据 | 通过条件；当前状态 |
|---|---|---|---|
| FT-01 灰度 | FE-02/F1 | 黑白/原色、全部256等通道灰阶、通道集合0/1/127/128/254/255的组合、固定种子4096组；直接整数式 | 两lane逐位及舍入一致；未运行 |
| FT-02 中值 | FE-03/F3 | 512二值窗口、重复值/全0/255、127/128、4096固定种子随机；独立普通排序取第5项 | 9级延迟/停顿及开关中心旁路一致；未运行 |
| FT-03 Sobel | FE-04/F4 | 常量、水平/垂直/斜边、1530极值、镜像符号、每例T=L1−1/L1/L1+1合法边界，T0/2047 | Gx/Gy/L1/edge逐位、6级和中心对齐；未运行 |
| FT-04 窗口 | FE-01/06、INV-06/07/08 | W4/H3、W8/H3、W10/H5，像素16y+x；直接坐标夹紧邻域 | 所有9值/坐标正确、N组；W8无stall首e7末e18；未运行 |
| FT-05 RAM端口 | F2R/INV-06 | 连续、q=D−1→0、气泡、反压、真实末组→replay首组，实际EFX模型 | 每沿rd&&wr⇒地址不同，addr<D；无有效数据X，读延迟和保持正确；未运行 |
| FT-06 双补边 | FE-01/03/04 | B中4×3横斜坡；另Y=[0,1,2,3]/[10,11,12,13]/[20,21,22,23] | median为[1,2,3,3]/[10,11,12,13]/[20,20,21,22]，再次补边后四角L1=40；旁路四角44；未运行 |
| FT-07 流控 | FE-06 | 小图每位置单独插气泡或停顿；种子0x431、0x1060随机组合；窗口首输出/行交接/replay/TAIL重点停顿 | 挂起数据/标志稳定，全部输出数值/顺序不变，无重复读写；未运行 |
| FT-08 配置 | FE-05 | 连续job切换median/kind/T/三ID；当前job运行/停顿时外部字段不断变化 | 当前结果只用旧快照，下一job用新值；status背压稳定；未运行 |
| FT-09 非法输入 | FE-07/F0 | bad、奇数/跳跃/重复坐标、错SOF/EOL、提前/缺失EOF，及同沿多错；kind2/3 | 指定优先码、坏输入计数、不投递、无OK、下job正常；未运行 |
| FT-10 取消/复位 | FE-07/INV-05 | 每流水阶段、两窗口填充/底行、输出阻塞、末输出交付沿取消；STATUS迟到cancel；同步rst | 取消沿实际旧输出计数、前缀作废、valid清空、旧RAM无泄漏；STATUS不改写；未运行 |
| FT-11 全尺寸 | FE-01…08 | 1920×1080常量、竖/斜边、固定种子椒盐图；median开关、两kind分配覆盖；至少4完整job | 每job2,073,600像素逐位，N组，末行/角点与标签正确；无stall时E7沿号吻合；未运行 |
| FT-12 工程检查 | FE-08、完整任务资源 | 本批RTL静态/编译告警审阅，后续整机综合读取RAM/XLR/DSP与STA报告 | 编译/数值检查和实际综合/布局分开报告；本批不生成板级工程；未运行 |

固定随机源：FT-01/FT-02数值向量用Python Random(0x431)，FT-11椒盐像素选择用Random(0x1060)；图像为灰度128背景、逐像素均匀随机u∈[0,1)，u<0.0025置0、0.0025≤u<0.005置255，否则保持128。这里是中值功能测试输入，不恢复已撤回的识别噪声验收范围。FT-07协议用TB独立32bit LFSR，非零初值0x431/0x1060，更新定义为左移1且最低位接旧bit31 xor bit21 xor bit1 xor bit0；每物理下降沿更新一次。输入气泡选bit0=1，输出停顿选bit1=1，但任一连续停顿最多8沿后强制一次可推进机会，避免随机无限停顿。声明使用LFSR只是可复现激励契约，不用它作图像数值oracle。

LFSR仅决定何时开始提出下一输入事务；已经拉高in_valid而尚未被接受时，valid和整个payload保持，不能因新的随机位改变。强制机会只使测试源提出合法valid、测试接收方提出ready，不伪造DUT握手，也不绕过窗口自身的in_ready。取消/复位时驱动器按场景撤销旧job的未接受事务。

测试输出保留种子/尺寸/配置/身份/比较数/首次失败坐标。不以内核无自设超时为理由让TB无限等：每场景给有限激励/停顿，按N、D、流水和已注入停顿给等待上界；超限即失败。输入永久中断场景用明确cancel恢复。通过后不无故重复扩大同类测试。

## H. 双向追踪

以下文件均相对拟实施work根，仅计划、尚未生成。反向每个核心单元都有具体需求，不增加无关框架。

| REQ | MOD/IF/步骤 | 计划文件/核心符号 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| FE-01/06/07 | F0、FJ/FP/FO/FS、OP-01/INV-01…05 | rtl/frontend/frontend_frame_pair.sv；job_state、input_expected、frame_status | FT-06…11 | 待实现/未运行 |
| FE-02 | F1/FP-02、OP-02 | rtl/frontend/rgb_to_y_pair.sv；rgb_weighted_terms、gray_round | FT-01/06/11 | 待实现/未运行 |
| FE-01/03/04/06/08 | F2/F2R/FW-01、OP-03…05、INV-06…08 | rtl/frontend/line_store_pair.sv；两lane EFX_RAM10；rtl/frontend/window3x3_pair.sv；read_pending、horizontal_columns、replay_phase | FT-04…07/10/11/12 | 待实现/未运行 |
| FE-03/05/06 | F3/FW-01/FP-02、OP-06 | rtl/frontend/median9_pair.sv；row_order、median_candidates、center_bypass | FT-02/06/07/08/11 | 待实现/未运行 |
| FE-04/05/06 | F4/FO-01、OP-07 | rtl/frontend/sobel_pair.sv；side_sums、signed_gradient、l1_magnitude、threshold_compare | FT-03/06/07/08/11 | 待实现/未运行 |
| FE-01…08的独立期望 | 数值/硬件对应契约 | model/frontend_reference.py；gray_image、median_image、sobel_image、generate_vectors | FT-01…11 | 待实现/未运行 |
| 协议/数值验证派生要求 | 测试按D/E检查 | sim/frontend/tb_rgb_to_y_pair.sv、tb_median9_pair.sv、tb_sobel_pair.sv、tb_window3x3_pair.sv、tb_frontend_frame_pair.sv | FT-01…11 | 待实现/未运行 |
| 可复现执行与失败留存 | G执行边界 | scripts/run_frontend_sim.ps1 | 编译/展开/运行及明确比较计数 | 待实现/未运行 |

## I. 设计门槛与评审

本批v1于2026-10-04完成保存读回、用户阅读入口呈现和三方向独立审查，状态READY_FOR_REVIEW，等待批准。审查及修正见[frontend-review-v1.md](../experiments/track4_full_sw_20261004/05_reviews/frontend-review-v1.md)；本状态不代表用户已批准、理解或功能测试通过。

| 门槛 | 本批证据及状态 |
|---|---|
| ①整体行为/样例 | B中FE-01…08、正常/边界/取消样例 |
| ②职责/连接/复用 | C图、F0…F4，E3 RAM10真实接口；参考灰度不照搬 |
| ③接口/组合 | D端口表、内部FP/FW/F2R/start/flush/empty、逐连接相容检查 |
| ④状态/不变量/草图 | E1…E7，OP-01…07、INV-01…08 |
| ⑤语言/映射 | F和E数值/逐沿、Python独立整图参考 |
| ⑥走查/覆盖 | E7正常/坏EOL走查，D未来集成条件不冒称已满足 |
| ⑦实施/验证/追踪 | G/H，所有实际代码和测试仍未产生 |
| ⑧无当前阻塞 | 三方向审查及主Agent复核完成；本批内核无剩余设计正确性阻塞，整机缺口保持独立可见 |
| ⑨保存/读回/呈现 | 文件已实际读回；本轮已向用户提供主设计及中文阅读入口；链接检查无缺失 |
| ⑩版本/范围/基线 | v1、A范围、H计划路径、FE-BL-20261004-v1的28项SHA256；最终文档hash另记document-checks |

拟申请批准对象为本批v1、A/H定义的六个RTL文件、独立参考、五个TB与本地仿真入口；批准后仅在指定独立work路径生成及运行该局部测试。板级约束/综合/布局、联网下载、其他功能实现不由此自动获得批准。必须明确绑定已保存基线；尚未收到批准，不登记为APPROVED。

## J. 变更与恢复

首次v1候选细化整体MOD-06/07，不改变原十一项任务。明确两个算子共四行、每算子两行；选择半值向上灰度、复制边界、严格阈值比较、九级中值、统一路径。后续任何数值、端口、周期、模式、缓存或错误语义改变，先修订设计并核对批准边界。

## K. 实现与验证实录

未生成实现、可执行测试或testbench；未执行功能仿真、综合、布局布线、STA或bitstream生成。现有工具版本/文件内容检查仅属设计依据。正式数据库、H/A/R状态未修改。

## L. 交付与阅读说明

阅读顺序为父整体布局→本文件B/C→D交接→E中文步骤→G/H验证追踪。修改阈值语义先查FE-04与F4，修改边界先查F2及两次有限图补边，修改取消先查F0与全部模块flush；每项都需同步参考与对应测试。当前交付为可审阅设计v1，完整工程交付仍未完成。
