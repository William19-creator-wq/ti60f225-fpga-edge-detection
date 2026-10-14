# TRACK4-LINE-OFFSET-PEAKS-001 v1

2026-10-12，按 PLAN_TEMPLATE 的短增量设计；READY_FOR_REVIEW，实际读回呈现后依据用户持续自主推进/整合授权实施；本次没有伪造逐版human批准。沿用已批准本地审计例外，正式DB/硬件状态不改，无仿真、TB、独立测试、安装、网络和硬件操作。

## A. 目标、现状、基线

Goal / Target：落实矩形 coarse 的49 offset计票与全部radius1 NMS峰值选择，后续交给CELL/run协调器。Current / Gap：RP点数学、RW工作缓存、LR完整run已有独立候选，缺offset累积/NMS和完整coarse父；本卡只新增独立候选，不接入主包或正在编译的064。

新文件计划 work/active/track4_board_first_20261011/candidates/line_offset_peaks_v1/board/rtl/board_line_offset_peaks.sv。实际依赖：RECTANGLE-REFINE-001 v1 E2（49 offset、radius1 NMS、同票较低offset优先）SHA25242C5722176970259AF3E87FA9069590576E1BE1C792E4845AA0DBB8521EC9；已读RP端口候选6A39008486EB5ECE401690743DC6DE868E71390955BFD3157C961E0D0893DDC3，LR06D65818D7F538F4CC8A350E002C461F238C49C3DB3E60FF66A1F196DE7F28C1。没有复用旧完整逻辑池或生成新参考模型。

Assumptions / Dependencies：Ti60F225、1920×1080、E≤2073600、共同core正沿同步高有效rst，内部POINT/数学回调可暂停；父只在RP成功且真实关闭后提交对应点的offset/normal，scope/LINE/theta/R0/normal tolerance由父绑定到该次START，直到done或失败；未来父集成必须显式复核，不能凭候选有代码认为完整coarse闭合。Open：本限定计票模块无关键未知；完整父/CELL/TLS/PAIR/RECT/FINAL/性能资源属于后续未完成。

## B/C. 行为、职责与接口

OP01：接受START锁E21与minimum_support21，E可0，minimum>0且≤整幅像素；允许minimum>E，因此完整负例正常输出零峰。依次接受恰好E个POINT结果tokens，ordinal必须0…E−1。只有normal_ok且offset_valid时增加唯一offset_index0…48一票；offset_valid=0或normal_ok=0是合法非投票点，其ordinal仍推进。投票点index>48是格式失败，不收窄回绕。

OP02：全部49个u21 bin清零并真实累积完后才NMS；bin i达到minimum且严格大于左邻、≥右邻时为峰，画外邻按零。i扫描0…48，输出所有峰、顺序升序。平票左优先：相邻等票只有较左者能通过；radius1最多25峰，第26为内部错误，不截前缀成功。清表和计票不发布任何峰。

OP03：peak_valid/ready上升沿交付，index6/votes21保持到真实消费；done只在完整49扫描和最后峰消费后。error是失败，与正常零峰/未完成区分；错误前若有已交付峰，父必须将整次结果作废。只接受一个START，失败需共同冷复位，不能把局部前缀当整帧成功。quiet仅在!rst且IDLE/COMPLETE/FAILED，表示本模块没有私有RAM活动或在途输出；FAILED虽quiet仍不接受新START。

结构：`父已关闭的RP点结果 → ordinal/offset token → 本模块单RAM计票 → radius1扫描 → 峰stream → 未来CELL/run父`。本模块不调用DDR、NUM、STATS、FIT或ANGLE，不拥有它们的预约，不做offset数学/LINE合法性/成员选择，不新增CDC。

端口（文档声明，无实现体）：clk/rst/start输入，start_ready输出；point_limit/minimum_support输入u21；point_valid/point_ready握手，ordinal u21、offset_valid、offset_index u6、normal_ok输入；peak_valid/peak_ready握手，peak_index u6、peak_votes u21、peak_count u6输出；done/quiet/error输出。START只在IDLE/COMPLETE且!rst可接受，start&&start_ready采样配置；point_fire只在COLLECT且!rst，输出publish不接受点。父held回调必须随ready停顿保持，不能valid与模块ready形成组合环。

相容性：RPoffset_index6只在offset_valid真时有效，本模块还要求normal_ok；不能把RP error/drained不真仍当普通负票，父先处理失败，再提交token。ordinal来自该LINE本遍完整POINT编号，所有非投票点也提交，接收数量E与身份绑定由父控制。输出peak数量为0…25但尚未写CELL、SEG，父不得据此提交识别结果。

## D/E/F. 内部次序与RTL契约

一块EFX_RAM10 READ/WRITE_WIDTH16、OUTPUT_REG0，49bin各两字；地址2i低16，2i+1低5为高5，余11必须0。只有地址0…97有效，START后CLEAR连续98沿写零；不复位RAM整块、不借上次值。VOTE接受锁6bit bin；依次READ_LO/CAPTURE_LO/READ_HI/CAPTURE_HI，正沿读Q下一沿采样，合成u21旧count；上11非零或旧count≥E拒绝；先u22加1检查再提交u21，WRITE_LO/WRITE_HI真实各写一字后才接受下一点或扫描。

COLLECT接受正常token时先核ordinal==seen且seen<E、有效投票index≤48，然后seen+1；不投票且seen旧值E−1直接扫描，投票的最后token必须等待两字写完才扫描。E=0在CLEAR末沿直接扫描。无point_valid不推进seen。计票期间RAM/Q临时碰撞不用于发布；完整WRITE后新READ会重新取得Q。

NMS按每candidate0…48，依次读left/center/right的两字并核高padding、count≤E；左越界或右越界直接置0，不用回绕地址当邻居。三个u21邻值寄存器只在相应CAPTURE或边界置零沿更新；下一QUALIFY沿才基于更新值判断OP02。合格进入PUBLISH，输出保持至peak_fire，peak_count消费时+1；不合格或真实消费后NEXT，candidate48→COMPLETE，其余candidate+1并重新读三个邻居。QUALIFY在peak_count已经25且仍遇合格峰时先FAILED，不提前发26峰。任何格式/数值错误error置1→FAILED、无done，无其它资源待排空。

START配置E/min一次锁存；不受之后输入配置变化影响。所有计数/地址/比较unsigned，22bit加法在宽域检查，bin索引合法后才使用9bitRAM地址；冷rst清控制/seen/peak_count/error、取消本次输出，RAM有效性由下次完整CLEAR重建。valid=0正文忽略，stall保持点/峰契约。latency不是固定：清98沿，每投票6沿RMW加接受沿，每候选至多12沿读邻居加资格/下一沿，峰背压增加等待；没有截止时间或自动暖取消端口，父应完成本次或共同冷复位。

资源预算：1RAM10、0DSP、约200FF（另编码优化未知），LUT/packing未测；不增加另一数值核/全帧存储/引脚。纯RTL，C++和跨语言N/A。参数WIDTH/HEIGHT本项目支持1920×1080且乘积≤2073600，实际构建前不自称任意参数全部通过。

正常走查：E=3，min=2，两个normal合法点投bin24、一个非normal→49bin全部清零→seen=3且bin24=2→NMS只发index24/votes2→真实消费→扫完48→done。边界：E=0或min>E只扫空表/不足票表并done零峰；bin0/1同票≥min只发0；WIP点或峰停顿计数不重加；ordinal重复/有效index49→FAILED，父整次作废；最后投票没有在WRITE_HI前NMS。

## G/H/I. 实施、验证、追踪

实际读回/呈现本卡→只生成一份候选→根完整源码与RAM沿/宽度/边界静态读回→保存source/hash/change-record；不改主包/XML/064冻结输入，编译将在未来完整coarse接入批次进行。不新增仿真或可执行测试。文本验证：T01 E0/min>E零峰；T02边0/48、平票plateau、交替25峰；T03最後投票/98清表/低16进位到高5；T04背压/ordinal重复/有效index49/rst重入；T05未来整包综合/STA真实报告，当前NOT_RUN。

正向OP01→RAM/ordinal/CLEAR/RMW→候选同名模块→T01/03/04；OP02→邻居读取/QUALIFY/PUBLISH→T02/04；OP03→COLLECT/PUBLISH/COMPLETE/FAILED→T01/04；反向所有新增数据/状态属于计票、完整NMS或失败/保持，不添加未列算法。设计分析/静态读回/编译/仿真/实物分别记录；没有测试数量或文件存在自证正确。

十项门槛已有整体/样例、职责/连接、接口相容、详细状态、数值/时钟/接受/气泡/背压/复位/配置/RAM/身份/CDC/预算、端到端走查、计划/追踪、当前无阻塞、落盘读回呈现待实际完成、版本路径/基线清楚；不把READY写成新human APPROVED。Rollback仅保留独立候选，不动历史源码/原资料。Completion仅本计票模块候选，完整矩形识别/实物可用/性能未闭合。K实际实现/检查/hash待记录；理解验收未检验。
