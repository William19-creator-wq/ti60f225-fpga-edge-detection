# TRACK4-VIDEO-PARTIAL-001：摄像头采集后端与HDMI呈现单元 v1

2026-10-08。按 PLAN_TEMPLATE 的必要内容收束。设计阶段：READY_FOR_REVIEW；实现批准待确认；代码、测试和工程尚未生成。关联 B1/B4、A5 的部分功能，不替代完整生产链路。

## A. 目标、范围与基线

- Goal：先交付可编码、可仿真的采集整理和显示呈现模块，给后续真实CSI/DDR/TMDS接入留下明确接口。
- Current state：R1/R2计算核已交付；旧CAMERA/DISPLAY有草图但整机交接未闭合。本增量只做下列单域单元，隔离未来物理接入。
- Target state：15份文件、完整1080p输入/扫描测试、软件画面、Ti60F225/I3独立综合/布局布线/时序及必要检查通过后的实验bit登记。
- Gap：当前没有本增量业务源码。真实MIPI接收IP、CSI多像素格式到本输入的适配、去马赛克、DDR帧读取、跨时钟域和TMDS发送器是明确后续工作，不伪称本轮实现。
- Assumptions：采集输入已被上游解包成同拍两个RAW10像素及SOF/EOL/上游错误标志，宽度为偶数；没有反压。本规范仅定义此接口，不声称实际CSI当前已经输出这个格式。显示数据由调用方按下述坐标及时提供。
- Open questions：本单元没有影响所定义接口正确性的未定选择；真实物理接入的未知保留在上位生产IO设计。
- Dependencies：根规范、PLAN_TEMPLATE、MODULE-FIRST策略、现有相机/显示来源记录、原reset_sync和已验证四pin工程模板。
- Milestones：中文局部草图→指定批准→采集/时序/渲染代码与单测→软件接口组合→物理检查→实验bit及文档。
- State transitions：采集IDLE/CAPTURE/DISCARD/HALT；显示固定循环扫描；详见E。
- Artifacts and hashes：由FAST-BL-20261008-v1保存本稿、来源、种子工程和现有两个算法基线的实际摘要；本稿不写自身摘要。
- Validation：见G；设计分析、仿真、独立物理检查和实际板卡分别记录。
- Failure handling：坏帧明确结束并丢弃到下一个合规SOF；不发布成功帧，不静默回绕序号；工具失败保留运行，不覆盖旧结果。
- Human approval gates：本v1/15文件及FAST批次本地审计须指定批准；原算法批准不自行扩大。正式数据库、原HDK和硬件状态不改。
- Rollback：未来仅写work/active/track4_algorithms_20261004/video_partial；当前不创建业务工作目录。
- Completion criteria：代码/必要单测/接口组合/实际物理结果及软件画面均有记录；结论限于所定义采集后端、并行RGB呈现与独立实验工程。

## B/C. 外部行为、职责和路径

VP01：采集整理器接收RAW10双像素，输出原RAW、8bit亮度预览、坐标、帧号和标志；有效像素数及行长度正确才产生成功帧终态。

VP02：时序单元产生1920×1080的双像素扫描坐标、DE、正极性HS/VS和帧起点。

VP03：呈现单元输出彩条、亮度、灰度/边缘分屏、彩色边缘叠加四种画面，模式只在帧起点生效。

VP04：使用模拟已解码输入和明确的软件存储fixture观察画面；采集数据和呈现数据的帧/坐标要能逐项追踪。这不是实际DDR资格验证。

路径：已解包RAW10双像素→capture_normalizer→原RAW/亮度/帧终态。另一条路径为timing→请求源坐标→调用方像素/边缘→presenter→并行RGB双像素/DE/HS/VS。接口组合TB可保存采集实际输出到软件帧数组后供呈现读取；软件数组不进入综合，也不冒充板载缓存。

四个新增RTL职责：camera_capture_normalizer保存采集计数及帧资格；video_timing_1080p_pair只管扫描；video_compare_presenter只管映射/模式/颜色及一拍对齐；video_partial_probe_top用于自主图案和四pin实验观察。复用reset_sync原字节。

## D. 接口与参数

所有业务单元均为单时钟posedge、同步高有效rst，SV2009。valid=0不代表零像素。

采集：parameter WIDTH默认1920、合法偶数4…1920；HEIGHT默认1080、合法2…1080；FIRST_FRAME_ID为u32，默认0。输入in_valid、raw_pair[19:0]（较早像素低10bit）、in_sof、in_eol、in_bad。输出pixel_valid、raw_pair_out[19:0]、gray_pair[15:0]（较早像素低8bit）、x_even[10:0]、y[10:0]、frame_id[31:0]、sof/eol/eof；另有frame_end_valid、frame_end_id、frame_end_good、frame_end_reason[2:0]、error_valid/error_reason[2:0]。不设ready；下游必须接收每个有效输出，否则以后在边界添加FIFO。

预览定义：每个RAW10取bit9…2，复制到RGB通道时形成单色预览；它不是已完成去马赛克的彩色图像，也不是替代R1的RGB转灰度。

采集原因：0成功、1有效输入缺SOF、2活动帧出现提前SOF、3行结束标志与位置不符、4上游错误、5序号耗尽。已分配最后序号的当前帧仍处理；此后拒绝新帧，不回绕。SOF只在in_valid时解释。

时序：每沿表示两个相邻像素，水平总1100拍：有效960拍、前肩44、HS22、后肩74；垂直总1125行：有效1080、前肩4、VS5、后肩36。HS在h=1004…1025为1，VS在v=1084…1088为1；DE为h<960且v<1080。frame_start在h=v=0；有效区x_even=2h、y=v，空白区坐标输出0。74.25MHz双像素时钟对应60Hz，这是生产时钟要求，独立25MHzprobe不宣称达到生产刷新率。

呈现输入：时序DE/HS/VS/frame_start/x_even/y、cfg_mode[1:0]、rgb_pair[47:0]、gray_pair[15:0]、edge_pair[1:0]。RGB较早像素低24bit，每像素[23:16]R/[15:8]G/[7:0]B。输出RGB双像素/DE/HS/VS/frame_start统一寄存一拍。

mode0彩条、mode1灰度、mode2左右分屏、mode3红色边缘叠加。彩条按显示x的八个240像素区间依次白、黄、青、绿、品红、红、蓝、黑；分屏左侧复制灰度，右侧edge=1为白色、0为黑色。非分屏请求源坐标为x_even及x_even+1；分屏每侧宽960，水平压缩2倍，请求2*(x_even%960)及该值+2，源y不变。调用方须为当前请求提供两个相应像素；真实同步RAM将由未来预取适配负责。本单元不隐含零延迟物理RAM。

组合检查：输入是双像素偶宽，与时序有效区960拍一致；分屏两侧边界960为偶数，没有一组跨两侧；最后分屏源坐标为1916/1918，未越界。空白RGB置0，输出控制与数据同一拍。提供者缺数据时只能由未来调用方明确报告，不能声称本单元证明显示无欠载。

## E. 中文内部操作草图与语句组织

采集采用always_ff保存state、x、y、当前ID、下一ID及耗尽位；组合部分只计算本拍合法条件及preview。每沿先默认清输出valid/终态脉冲，其余payload保持；rst清资格与计数。

IDLE/DISCARD遇合规valid SOF时分配ID，从x=y=0开始接收首组；首组要求in_bad=0且in_eol=0（WIDTH至少4）。下一ID在未到最大时加1，到最大设置耗尽。IDLE中有效输入缺SOF时报原因1并进入DISCARD；DISCARD的非SOF输入直接忽略，不重复报告。待起帧状态遇SOF时错误优先级为上游错误4→序号耗尽5→首组EOL错误3，均不分配ID；无错误才接收首组。in_valid=0时忽略其他输入标志。

CAPTURE按上游错误4→提前SOF2→EOL位置错误3的优先级检查；不合规则终结旧帧为失败，抑制该组输出，进入DISCARD。提前SOF这组用于终结旧帧，不同时创建新帧，以下一个SOF恢复。合法组形成RAW/preview/坐标/标志，所有字段同时寄存；最后一组形成成功终态并回IDLE。每行最后x归0、y加1，其余x加2。没有valid时计数保持。成功/失败终态与相应ID同沿寄存，禁止把不完整帧当成功。ID耗尽后下一次起帧报原因5并HALT，HALT仅在valid SOF时再次报告原因5，冷复位恢复。

时序使用两个11bit无符号计数器；h到1099归0并推进v，v到1124归0；复位为0。组合译码HS/VS/DE/坐标/帧头，计数仅按每沿推进，不受像素数据valid暂停。

呈现mode寄存器只在frame_start采用cfg_mode；该帧首组渲染直接使用cfg_mode，其余组使用已锁mode，避免首组旧模式。always_comb确定源坐标、两个像素颜色；mode0用固定区间比较选择彩条，mode1复制灰度，mode2左灰右二值边缘，mode3边缘像素置FF0000且其他像素保持输入RGB。always_ff将颜色与所有控制统一寄存一拍，rst输出无效。

probe实例化原reset_sync和上述单元，自主产生合规图案/RAW组与模式。用帧计数和有效数据校验累加驱动两LED，仅作逻辑可综合观察；不用串行CRC大幅降低数据吞吐。它不连接实际摄像头或HDMI物理端口。

## F. 必要语言、时序与资源契约

所有计数/坐标/RAW/RGB无符号，递增前明确比较终点，x加2前使用足够位宽；不得用有符号常量引入隐式扩展。采集输出固定一拍；呈现输出固定一拍；时序组合输出是当前计数。TB在negedge驱动、posedge后观察寄存结果。

不跨域、不推断整帧RAM；当前约3000 XLR以内、RAM/DSP预计0作为粗预算，最终以工具报告为准。物理试验仅25MHz，J2时钟、P13 KEY、N14/P14 LED及电气设置复用已验证模板；同步复位数据路径继续计时，异步例外只到复用reset_sync的实际两级SR端点。生产PLL、74.25MHz和真正HDMI引脚不属于本实验约束。

独立参考按二维RAW图直接截位、按固定扫描区间形成控制、按坐标映射计算颜色；不复制RTL状态机。模型输出与硬件真实事务/坐标和模式关联；原RAW预览与完整彩色恢复分开标注。

## G/H. 文件、必要检查与追踪

未来15文件：rtl的camera_capture_normalizer.sv、video_timing_1080p_pair.sv、video_compare_presenter.sv、video_partial_probe_top.sv及原reset_sync.sv；model的video_io_reference.py、video_io_vectors.py；tb的tb_camera_capture_normalizer.sv、tb_video_compare_presenter.sv；scripts的run_video_io_sim.ps1、run_video_io_build.ps1、video_io_postroute.tcl；project的video_partial.xml、video_partial.peri.xml、video_partial.sdc。

VI-T01：完整1080p一帧1,036,800组，核RAW/preview/坐标/标志、首尾及成功终态；小参数边界与气泡保持另测。

VI-T02：缺SOF、提前SOF、EOL早/迟、上游错误、活动帧复位、NEXT_ID最大边界，确认失败不发布成功且下一合规帧恢复。

VI-T03：完整扫描每帧1,237,500拍、DE1,036,800拍；HS每行22拍、VS每帧5500拍，输出延迟和首尾一致。

VI-T04：四种模式完整1080p，逐像素独立对照；帧中改变cfg不得立即生效；分屏边界958/960、最后1918/1919、非边缘原RGB及边缘红色准确。保存软件画面供人工查看。

VI-T05：真实采集输出经明确的软件帧fixture供呈现，追踪同一帧与坐标；fixture不参与综合，报告标明模拟上游/软件存储边界。

VI-T06：编译/综合无新增意外latch、多驱动或缺源；同源Map/PT/PNR/已布线STA有效，内部无未约束时钟且setup/hold非负，实际四pin与约束合理后才生成实验bit/hex并登记。

追踪：VP01→capture/E采集→VI-T01/02；VP02→timing/E计数→VI-T03；VP03→presenter/E映射→VI-T04；VP04→fixture/两TB→VI-T05；可综合与产物→probe/工程/runner→VI-T06。实现后在work/docs填写实际符号和运行路径，不用计划数量冒充结果。

## I/J/K/L. 门槛、变更和交付

当前范围的行为、参数、接口、局部步骤、数值/时间/资源、正常与错误样例、15文件和验证追踪均已定义；未来物理提供者明确隔离，未以未知物理RAM语义支撑本单元正确性。保存/读回和基线绑定由FAST批次记录后保持READY_FOR_REVIEW，等待一次指定范围批准。

重要字段/同步/错误/采样/模式或存储策略修改先修订受影响设计；内部命名、相同语义表达及普通实现修正记录后继续，不逐变量提问。获批后按整体→接口→局部代码→实际测试→软件画面→物理结果交付。当前NOT_IMPLEMENTED/NOT_RUN，不记录实际MIPI/DDR/TMDS或硬件通过。
