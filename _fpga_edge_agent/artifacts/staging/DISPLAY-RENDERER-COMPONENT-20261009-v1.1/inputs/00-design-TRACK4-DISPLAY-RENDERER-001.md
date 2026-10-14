# 生产六模式像素合成 v1

- Goal：将实际row pair54与不可变render112合成为RGB双像素，供后续scan/TMDS，完成B4/A5/A6显示侧的可独立编码部分。
- Current state：标准AXI行预取和三bank软件闭合已登记；旧video_compare_presenter只有四种探针模式，其左右缩放坐标与owner的六mode合同不相同。
- Target state：固定两个寄存级、无停顿的双像素视频合成；灰度/边缘分屏、RGB、GRAY、EDGE、彩色叠加、ANN优先级正确，控制与坐标同延迟。
- Gap：生产render112消费者没有代码。此叶不虚构完整scan/DDR/TMDS闭合。
- Assumptions：上游scan已经取得真实row ownership并核全文身份，将当拍pair及render一起提供，不能热改旧像素配置；HDMI时序不可回压。
- Open questions：真实scan调度与DDR QoS仍需后续设计；当前叶精确约定缺数据/错身份输出黑和诊断，无叶设计阻塞。
- Dependencies：owner render112、prefetch pair54、R1灰度公式、赛题要求、唯一v0.2，冻结真实文件SHA；工具Questa/Efinity沿用现有授权。
- Milestones：整体/接口/中文局部草图读回→RTL/独立参考/TB/runner→六mode与1080p时序→MAP→登记。
- Detailed steps：B外部→C连接→D逐信号及组合→E旧状态/新状态中文操作→F语句位宽→G/H验证/追踪。
- State transitions：READY_FOR_REVIEW，保存读回/聊天呈现后按“统计完后自行进行，无需我的批准”自主软件实施，不索取逐版批准，不更改正式审批或DB。
- Artifacts and hashes：独立work/display_renderer；计划7份：rtl/display_renderer.sv、tb/tb_display_renderer.sv、model/render_reference.py、scripts/run_renderer_sim.ps1/run_renderer_map.ps1、project/display_renderer_component.xml/.sdc。README/设计/输入/日志单列。
- Validation：逐位RGB、gray舍入、2bitANN/优先级/flags、控制坐标、连续DE与blank/复位/缺数据，source绑定/fatal非零/MAP。
- Failure handling：不暂停HDMI时序；有效区域缺像素/身份错误/配置非法输出黑和error。清流水不能冒充已归还DDR或RAM借用。
- Human approval gates：已有自主软件和本地审计例外；不网络、安装或操作硬件，最终bit之后止步。
- Rollback：只增work新包，旧presenter及原HDK保持只读。
- Completion criteria：本像素合成叶软件/MAP；整帧scan/owner/handoff/prefetch联接、TMDS和板级PNR/STA/bit仍未完成。

## A/B 整体行为与真实来源

RR01：输入row pair54沿用低→高RGB48/EDGE2/ANN4，RGB每lane24={R8,G8,B8}，lane0低；render112高→低为mode3/split_y11/edgeRGB24/ANN01RGB24/ANN10RGB24/ANN11RGB24/show_edge1/show_ann1。pair/render/坐标/控制来自同一真正借用的图；完整942/543身份检查留在上游scan，本模块接收其明确identity_good，不自行以结果相同推断资格。

RR02：mode0比较：target_y<split_y用SRC灰度，下半用EDGE白/黑；source_y缩放早已由预取按票据完成，本模块不重算坐标或水平抽样。1 RGB原色，2灰度，3EDGE白/黑，4原色上按show_edge叠edgeRGB，5按show_ann且ANN非0的颜色优先，其次show_edge且EDGE1用edgeRGB，否则原RGB。0/3的边缘展示必需，不受overlay flags关闭。ANN00透明、01圆、10矩形、11文字/异类重叠；字形位置由ANN生产者产生，本模块只消费bit码，不声称已生成识别文字。

RR03：灰度与真实R1相同，Y=(77R+150G+29B+128)>>8，八位输出，无除法器。移位加法先扩成unsigned16；最大65408不溢出，无饱和及不同色彩变换。RGB888各通道的舍入不修改原色路径。

RR04：视频每正沿不可暂停，两个寄存级；输入在E_n采样，输出在E_(n+1)形成，所有de/hs/vs/frame_start/x_even/y/error与RGB相同延迟。blank固定RGB0/error0并保留hs/vs，不把气泡变像素。复位同步正沿清所有级有效控制和RGB，解除后按这两个寄存级恢复；不处理IO归还。

RR05：in_de时，mode6/7、split_y!=H/2、x为奇数或x>=W/y>=H为CONFIG error2；字段合法但identity_good0为IDENTITY error3；字段/身份合法但pixels_valid0为MISSING error1。依上述优先级锁当拍黑色/诊断，控制时序照常，不用旧pair填充错误像素。合法数据error0。上游必须记录underrun；黑色诊断不代表满足B4无闪烁/无撕裂。

正常例：mode5低lane ANN01/show_ann1/EDGE1/show_edge1 →圆色优先；高lane ANN00/EDGE1 →edgeRGB；同一pair在后一沿输出。边界：RGB255/255/255得到255，0得到0；mode0上半黑白灰度，下半仅二值边缘；blank时即使非法mode/pair随机亦RGB0/error0，VS仍向后延迟。

来源：frame_owner的公开设计render112；已登记display_prefetch v1.3的pair54；r1/model/frontend_reference.py的公式；TRACK4_REQUIREMENTS中B2/B4/A5/A6。旧四mode presenter只作结构参考，不当生产语义。叶无摄像头、AXI、写RAM或图形识别副作用。

## C/D 连接、职责、接口与组合

单模块display_renderer；一个组合灰度/输入检查段、一个寄存快照、一个颜色选择段、一个输出寄存。灰度参数和每像素metadata归本流水持有；没有额外row或frame buffer，也没有回馈/死锁路径。时序、RAM借用与frame切换归scan。

```text
实际scan同一owned row：pair54 / render112 / pixels_valid / identity_good
时序：de hs vs frame_start x_even y
 → 检查、宽位移位加法 → S0不可变当拍快照
 → 两lane各按mode/ANN/edge优先级选颜色 → S1 RGB48/控制/坐标/error
 → 后续TMDS或并行发送
```

IF-RR01 inputs：clk/rst1，in_de/in_hs/in_vs/in_frame_start各1，in_x_even/in_y各11，in_pair54，in_render112，in_pixels_valid/in_identity_good各1；W/H静态偶数4..1920/2..1080，默认1920/1080。无ready/valid回压，in_de=1定义有效显示时隙，pixels_valid是RAM数据可用资格，不能互换。

IF-RR02 outputs：out_rgb_pair48、out_de/out_hs/out_vs/out_frame_start各1、out_x_even/out_y各11、out_error2；每沿形成一个时隙，数目不增减，lane0仍低。没有公开frame_handle端口，因此实际scan必须在整帧切换前关闭旧流水或按固定延迟把借用延长至S1消费；不能在最后RAM读结束时立即声明无旧显示引用。

逐连接：prefetch输出的SRC每pair正好两连续RGB888，RGB/EDGE/ANN与票据source_y一同锁定；mode0缩放已在reader中确定。上游scan在请求RAM前按预留数据能力推进，native响应延迟与本叶延迟分别核算，不能把in_de驱动成response_valid。render来自原子active bundle的同一帧配置，在S0复制必须使用旧active那份。S1固定吞吐一pair/周期，无外部stall；TMDS必须接受每视频周期两像素并具有真实发送倍率/时钟。此最后接口尚待生产适配，当前只验证并行RGB时隙。

组合边界：缺行时仍传本时隙HS/VS/DE并黑色，错误可计数，不伪造有效旧帧；冻结时上游重复不可变result，本叶按真实同frame render反复产生像素；热更新只能影响之后被接受的快照，旧S0按原值输出。

## E/F 局部中文操作与语言合同

每正沿基于旧S0计算S1：若旧S0.de0，RGB0/error0；若旧S0.error非0，RGB0/保诊断；否则循环两个lane，仅用旧S0 RGB/gray/edge/ann/mode/colors/flags/topHalf选择颜色，两个lane一起提交。控制和坐标总从同一旧S0复制。

同时形成新S0：组合读取当前in_de/render/坐标/两个RGB，对字段/身份/数据资格按RR05先后核对；每lane用16bit移位加法计算带128舍入的灰度，取[15:8]；复制原RGB、边缘位、ANN码、mode/颜色/flags、topHalf判定及控制/坐标/error。当前输入后续变化不能修改已复制的旧S0。复位优先于两项提交，清S0和S1。blank不借像素值，保持无效RGB0即可。

语句：SV_09的logic/function自动无状态、always_comb全路径赋值、always_ff非阻塞；所有像素/颜色/坐标unsigned。77R=(R<<6)+(R<<3)+(R<<2)+R，150G=(G<<7)+(G<<4)+(G<<2)+(G<<1)，29B=(B<<4)+(B<<3)+(B<<2)+B，移位前各值显式16bit；三项和+128不超过65408。无乘除、动态数组、BRAM/DSP依赖。粗预算≤600FF/≤1000LUT/0RAM/0DSP，实际MAP为准，生产74.25MHz时序由后续PNR核。

不变量：每有效时隙输出正好两像素；错误当拍RGB黑；blank error0；灰度不超255；每S0只使用其锁定render；控制/坐标与RGB不分离。与R1仅共有数学合同，独立参考自己计算RGB/metadata/优先级，不能拿RTL内部sum作黄金。

## G/H 验证与双向追踪

RT1：所有mode与mode6/7、所有ANN00..11/EDGE0/1、四种flags、两lane不同码、颜色非默认、mode0上下边界，逐24bit比较。RT2：黑白/原色/灰度舍入边界及大量RGB组合/确定性随机，无溢出。RT3：连续DE、blank/HS/VS/frame_start、寄存延迟、输入render每拍变化及输入错误并行，复位流水作废单列。RT4：实际1080p pair timing各六帧的时隙、每帧2073600像素，独立图像参考与整帧输出摘要；fixture只提供数学pair，不声称连接真实prefetch/DDR。RT5：源绑定/fatal非零/Questa以及Ti60F225/I3 MAP、真实RAM/DSP与警告报告，不宣布组件PNR/bit。

RR01→端口快照/两lane→RT1/3；RR02→颜色分支→RT1/4；RR03→16bit灰度→RT2/4；RR04→S0/S1控制→RT3/4；RR05→错误优先→RT1/3。RTL注释、TB情景、独立参考、日志反向关联上述编号。

## I/J/K/L 实施与边界

已给整体行为、职责、精确接口、组合检查、局部中文语句、语言与宽位数学、预算、验证、双向追踪、输入来源/未知范围十项。达到READY_FOR_REVIEW后按用户自主指令保存全文读回再实施；不使用已取消的逐版批准门槛阻塞授权软件工作。完整系统总目标ACTIVE，本设计不是总FPGA闭合。

初始本批代码/动态/MAP未生成未运行。交付时用实际7份文件、最新尝试与资源补K，不冒充用户理解或人工硬件观察。若接口/优先级/延迟/存储需改变，先短卡记录证据并读回后依自主授权更新；原资料及旧尝试保留。
