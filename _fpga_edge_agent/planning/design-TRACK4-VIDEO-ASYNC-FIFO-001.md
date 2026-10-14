# TRACK4-VIDEO-ASYNC-FIFO-001 v1：不可反压视频记录的跨时钟缓冲

2026-10-09，READY_FOR_REVIEW。保存、实际读回并呈现后，沿用户“当你统计完后自行进行，无需我的批准”自主实施；沿本批本地审计例外，不操作正式数据库、硬件或原始工程。

## A. 目标、范围、事实与计划

Goal：补齐采集链可独立实现的双时钟运输，不将保护 CSI IP 不明的 sideband 时序编造为事实。Current：SC431HAI 数字配置已实际仿真/MAP；原活动 CSI 像素输出无 ready，公开资料尚未证明 packing、sideband、错误归属/closure；RAW/source/Canny/AXI 已有单时钟组件。Target：对已经由上层明确形成的完整固定宽度记录，原样跨 wr_clk→rd_clk，包含稳态一拍一条、停顿、绕回、满时独立粘滞故障、共同冷复位；官方双时钟 RAM 模型与当前源绑定 Ti60 MAP。

Gap：新 FIFO RTL/独立参考/TB/仿真MAP脚本/工程7文件和中文说明。Assumptions：外层输入记录的位布局/帧身份已定义且在写沿稳定；实际端口不能反压，每个 wr_valid 写沿是一次新尝试，未接受不重试。共同 cold_reset_n 只在已证明旧借用安全的冷启动/恢复时使用；禁止单端/暖清 FIFO。未知 CSI 映射和真实字节端口不是本组件声明。Dependencies：规范v0.2、模板、camera-csi-and-config-evidence-v2 的无ready/closure边界、官方 EFX_RAM10(双时钟读取/写入端口)；不复用受保护主体。

Milestones：整体与接口/局部草图→实现7文件→两非相关时钟/边界参数/518400记录测试→实际MAP→登记。State transitions：仅本设计和独立软件记录；任何失败保留run。Artifacts：work/active/track4_algorithms_20261004/video_async_fifo/runs 与 staging，新RunId不可覆盖。Validation：VF01…06见G。Failure：任何运行中的有效尝试无法写入时立即粘滞loss，后续不接纳，已运输记录保持并可排出；外层按故障取消同帧，不伪造成功closure。Human gate：无需再逐项批准；硬件操作禁止，总bit后停。Rollback：独立新单元可撤，不改旧组件。Completion：本数字运输和MAP；全CSI/板级CDC时序及整项目仍后续。

## B. 外部行为、样例与约束

VFREQ01：输入WIDTH位不透明记录，一个wr_valid写沿对应一条新尝试；wr_accept=wr_valid&&wr_ready，接受记录按序、恰好一次交付，无截断/改位/重新归属。未接受显式损失，不能保持同拍再解释为重试。WIDTH默认128，允许1…320；DEPTH默认1024，允许16…4096的2次幂。外层可选实际规范化记录宽度，本组件不强制采用旧CAM-NORM候选/截短Origin。

VFREQ02：写域容量有限，物理DEPTH条加读域2个前取槽。wr_ready反映当前可接受资格/空间，未运行时为0；满时不覆盖旧记录。运行中的wr_valid&&!wr_ready令wr_overflow粘滞并禁止后续写，wr_loss_count32按未接纳尝试饱和增加。读域rd_fault由独立两级同步粘滞标志提供，不依赖满FIFO中的故障记录；不跨域直接读取多位计数。

VFREQ03：rd_valid/rd_data保持到rd_ready消费，包括故障到达期间；故障不撤已经公开的记录。rd_fault只通知上层，已接纳前缀仍按序排空。此组件没有帧成功/Done，不从空FIFO推导CSI接收closure。

VFREQ04：两时钟可任意相位/非整数比例、暂时停钟；各域冷复位异步共同拉低，同步两级释放。内存不清，指针/槽有效性归零令旧内容不可见。某钟未运行时另一域可填满并报告损失；故障到读域只在读钟恢复后同步。没有在失钟域承诺实时通知。

正常：每拍连续写、读可接受，初始跨域延迟后稳态读一拍一条；读停顿时输出首条不变，余条仅占有限空间。边界：先2条进入读槽并停读，再填DEPTH条，第DEPTH+3次尝试失败，不覆盖前缀，故障跨域仍可见；恢复ready排出此前DEPTH+2条，没有最后未接纳条。共同冷复位后旧输出/故障不可复活。

## C/D. 职责、连接与相容

一个video_async_fifo模块拥有写二进制/Gray指针、读获取二进制/Gray指针、2FF指针同步、native双时钟条带RAM、两槽读前取和故障同步。wr接口(IF01)：wr_clk/cold_reset_n、wr_valid/data[WIDTH-1:0]输入，wr_ready/wr_accept/wr_running/wr_overflow/loss_count32输出；rd接口(IF02)：rd_clk、rd_ready输入，rd_valid/data、rd_running/rd_fault输出。所有数据unsigned原样保存，记录位语义属于邻接adapter。

IF03是指针Gray跨域：源每成功写/获取推进1，源寄存后的Gray每次变化恰好1位；目的2FF读取完整指针，只用于保守empty/full。目的不能把二进制多位直接同步。IF04是EFX_RAM10：WCLK=wr_clk/RCLK=rd_clk、512×20、OUTREG0同步读、无同址跨钟并发读写；写地址在wr_accept时更新，读地址在read_issue时采样。读获取指针在读沿发出同步RE后前移；写端要经过Gray2FF才知道该格已释放，因此不会在取数据尚未完成前复用。由此物理环形RAM以外需要明确两条前取预算。

组合检查：写方没有反压能力，wr_ready只报告接纳，满时必须故障；只有已接受序列进入RAM。读槽信用在发RE前预留，RAM回复不能被ready阻挡。故障独立同步不会被满数据队列阻塞。已公开首槽保持；RAM返回只能写另一个空槽/当沿刚消费的槽。没有反馈环等待软件；源时钟停顿只增加同步可见延迟。物理Gray bus跨域延迟/偏斜必须小于对应源指针时钟周期，源寄存器→第一级同步器约束在生产top明确；本组件MAP目标时钟不替代最终CDC/PNR约束。

## E/F. 中文内部语句草图与RTL契约

AW=clog2(DEPTH)，二进制/Gray宽AW+1含回绕。写域每wr_accept：WADDR=旧wbin低AW，条带RAM写完整记录低位在条带0，高位不足20零填；wbin+1、Gray=(next>>1)^next一起非阻塞提交。满条件：当前wgray==读获取指针同步值的最高两位反相、其余位不变。未接受不改指针/内存；粘滞loss后ready恒0至共同冷复位。loss_count==FFFFFFFF保持，否则每未接受有效尝试+1。

读域empty条件当前rgray==同步wgray。两槽slot0/1各WIDTH FF，count2=0..2表示完成数据，tail/head1只在RAM回复/消费翻转；pending1表示上一沿发RE而下一沿待保存的唯一回复。read_pop=rd_valid&&rd_ready；预留信用使用 count+pending-read_pop，若<2且!empty且rd_running，发read_issue。该沿EFX_RAM10已取旧rbin地址，rbin/Gray前移，记bank；下一沿旧pending时读取对应bank的RDATA入tail槽。count_next=count+旧pending-read_pop；pending_next=本沿read_issue。连续可读且ready1时可同沿回复、消费和新RE，达到一拍一条。停止时count+pending≤2，公开head不会被tail覆盖。

RAM分bank深512、stripe宽20，BANKS=max(1,DEPTH/512)，STRIPES=ceil(WIDTH/20)。bank=(地址>>9)，native地址取低9位；每个bank/stripe有一个EFX_RAM10，RE只给选定bank，保存read_bank供下一沿拼接。默认128×1024为14 RAM，额外2×128 FF；最终资源工具为准。更小DEPTH仅用低地址，不虚增可接受容量。

各域(*ASYNC_REG*)两级复位释放与指针/flag同步；always_ff时序非阻塞，组合信用明确3位无溢出/负值。非法WIDTH/DEPTH仿真fatal；生产只声明上述范围。input/data不跨异步裸多位线，数据经双时钟RAM与槽搬运。真实亚稳态/Gray布线偏斜不能由数字仿真证明；C++ N/A，Python仅核外部接受/交付事件与不透明位值，不复刻Gray内部算法。

## G/H/I. 验证、追踪、门槛

VF01：两个非相关时钟，外部事件scoreboard及独立Python，随机间断、读停顿、held首条、绕回、0/全1/每位变化；不丢/重复/改位。VF02：先2前取，再DEPTH填满/额外损失、故障到达时held首条保持、消费后故障仍粘滞、禁止后续写、旧全部前缀排出。VF03：不同步释放时钟/一域停钟/恢复/共同冷复位后新epoch数据，不允许单域reset。VF04：WIDTH1/20/21/110/128/192/320，DEPTH16/512/1024/2048/4096边界，容量/条带高位/深bank正确。VF05：默认128×1024、写70MHz读100MHz、连续518400条（完整1080p四像素一记录的数量），无reader停顿时全接纳全交付；只证明运输数量，不称真实CSI像素已闭合。VF06：当前源仿真先fatal退出非零，Ti60F225/I3 MAP实际14 RAM/0DSP、检查警告；生产PNR/STA/bit后续。

7份计划输入：rtl/video_async_fifo.sv；model/fifo_reference.py；tb/tb_video_async_fifo.sv；scripts/run_fifo_sim/map.ps1；project/video_async_fifo_component.xml/sdc；另docs和基线。REQ01→RAM条带/指针/槽→VF01/04/05；REQ02→full/overflow/loss_count→VF02/03；REQ03→head/held与独立flag→VF01/02；REQ04→两域复位释放/同步→VF03/06，反向模块与测试注释定位。

十项自检有实质内容：A范围/来源/现状/自主授权；B行为正常失败；C模块；D具体接口及容量/同步/所有权；E状态/保存/语句/并发交接；F位宽/沿/CDC/预算；D正常及满失败走查；G增量实施与独立证据；当前不透明FIFO范围没有关键未知，真实CSI/物理CDC明确后续；文档保存/呈现/实际读回；v1/7文件/基线可冻结。READY后继续实施；先按J记录修订再改，不新增人工批准。

## J1. 实际工具约束回查（2026-10-09）

fifo_map_001 的 EFX-0118 明确：异步读写端口仅支持 WRITE_MODE="READ_UNKNOWN"。先前原语配置 READ_FIRST 对两时钟不合法，失败保留。相应局部草图补充：双时钟 RAM 使用 READ_UNKNOWN；同址跨域读写仍被Gray保守指针和前取信用禁止，不以该模式提供冲突数据语义。修改只落实原已规定的无冲突双时钟内存，不改变接口、容量、数据、复位/损失政策。已有001仿真结果只对应旧源；全部以002当前源重新验证后才可登记。继续沿用户自主授权，不要求新的逐项批准。
