# TRACK4-RAW10-COLOR-STREAM-001 v1：真实行RAM、reflect101和整帧彩色

2026-10-08。沿用用户“当你统計完后自行进行, 无需我的批准”和本地审计例外；旧CAM v0.1只是设计来源，不把其尚未验证的CSI/时钟/源发布内容当成已完成。本单元保存读回READY后自主生成独立work/raw10_color_stream，原HDK/登记包/正式DB/硬件不改。

Goal：把真实RAW10双行历史与已验证插值核连接，保留首末行列和四色phase，形成完整RGB888双像素流。Current：DK数值核通过25152窗口pair，尚无实际RAW行窗口；完整Canny软件已登记。Target：全尺寸可参数化RAW pair→真实4RAM reflect101窗口→原DK→RGB，输入错误、取消、反压和任务终结正确。Gap：行RAM/窗口/局部生命周期RTL及独立图参考/TB/MAP；CSI、CDC、配置和RGB源DDR writer继续随后实现。Assumptions：偶数W4…1920/H2…1080，固定W/H；同core clk，64bit本地handle由外层完整scope映射并保存，不截断生产身份。Open questions：本软件单元无资料阻塞；真实模组phase不猜测，作为job配置显式输入。

Milestones/Detailed steps：整体→接口→旧状态中文草图→RTL→独立整图/协议→1080p→组件资源→生产采集及源writer。State transitions：保存读回READY→持续授权实施→实际证据登记。Artifacts：work/active/track4_algorithms_20261004/raw10_color_stream。Validation：RC-T01…08。Failure handling：坏帧失败，停止新RAW；窗口私有槽共同处置，公开RGB仍交付后关闭；joint rst只按外部安全共同复位证明使用。Human gates：无硬件读写。Rollback：旧失败run/快照保留。Completion：实际整图RGB与独立CFA/reflect101参考一致、四RAM映射；不据此宣称真实CSI稳定采集或整机完成。

## A—C 整体与职责

job接受handle64和phase2后ARM一沿清私有窗口/核历史，再RUN接RAW20及x_even/y/markers/bad/handle。合法pair进入真实recent/older两行RAM；延迟一沿用旧RAM读回形成垂直列，再用水平三列形成两个90bit窗口，原raw10_debayer_pair产生canonical {R1,G1,B1,R0,G0,B0}。输入EOF后停止RAW，重读最后两行并TAIL形成末pair；只有P输入/P窗口/P输出且末RGB EOF实际交付、内部empty才OK done。

raw10_line_store_pair：每行两条1024×10 lane RAM，recent+older共4 EFX_RAM10；EFX原语READ_WIDTH10/WRITE_WIDTH10/OUTPUT_REG0由已安装官方模型明确支持。本v1改用两lane原生10bit，旧CW-W01的packed20/page512候选不直接照搬；物理4RAM/40960bit、有效38400bit不变，取消page选择mux。地址511/512及959/1023仍测试。

raw10_window_pair：沿用已验证R1单pending/水平历史/末行REPLAY调度方式，但全部样本10bit，180bit输出，RAW边界按reflect101而非灰度clamp。原R1源码保持不改。raw10_color_stream：拥有输入协议、锁定phase/handle、真实计数、独立取消和held终态；复用原DK文件，不加gain/黑电平假设。

RC01：每lane的窗口a…i行优先低a高i，输出中心坐标生成markers。top首行(top,mid,bot)=(row1,row0,row1)，末行=(H−2,H−1,H−2)；左虚拟x−1取x1，右xW取W−2，保留CFA奇偶。插值仍RGB8=min255,floor((S+2d)/(4d))，只最后一次舍入，d1/2/4。

RC02：一个old read_pending，一个窗口输出slot、一个DK公开RGBslot；整体advance=窗口slot空或本沿被DK实际消费。stall停止新RE/WE，旧RAM Q与pending保持；恢复的沿用旧Q capture/延迟写后再发新RE，不重吃pending。与旧CAM双垂直holding候选不同，本v1采用暂停本地同步RAM返回消费，Q在无RE时保持，没有外部deadline；行为/数量不变。正常稳态每拍一个RAW pair，真实不可反压CSI必须通过之后有界CDC/FIFO，不能直接接本ready。

RC03：非法输入握手仍算accepted，bad tuple不进入窗口；first reason=bad→ID→coords→markers，粘住失败不等待未来EOF。cancel只同handle，不能错误ID关别帧。原窗口/DK旧合法事件同沿计入账；停止新输入后内部窗口共同flush，旧RE到返回沿作DISCARD并归还预约，不做新的RAM WE，不复活窗口。DK已经接受的旧窗口/公开RGB保持到实际消费，ABORT不能反向撤掉它。

## D 端口及组合检查

job_valid/ready/job_id64/phase2；in_valid/ready/raw_pair20/x_even11/y11/markers3={EOF,EOL,SOF}/in_bad/handle64；out_valid/ready/rgb_pair48/x_even11/y11/markers3/handle64；cancel_valid/id64；source_stop；done_valid/ready/id64/outcome2(0OK/1ERROR/2CANCEL)/reason8/accepted_pairs22/window_pairs22/output_pairs22/discarded_reads22。旧done与RGB body保持，新job只在旧done消费且window/DK都空时接纳。阶段ARM与首RAW分沿。

top组合ready只由旧状态、window容量及独立matching_cancel决定，不能由本拍bad字段撤销真实fire；数据valid单独过滤坏tuple。window输入只有合法行优先数据；top expected_q/y独立跟踪原始实际接纳坐标，marker末行只接受准确EOF。生产完整identity由外adapter持有，相机现有frame_id32不直接替代本handle64或完整scope。

window→DK是私有共同关闭点；top ABORT时window flush，阻止新的DK接受，DK不因ABORT复位公开RGB。只有ARM在双方已空后重置DK，或外部共同rst才清它。公开RGB没有额外跨时钟。done只在window_empty && !DK.out_valid后形成；不能依source_stop、输入EOF或P计数单独成功。

## E 中文语句组织和逐沿草图

行存储：每lane一EFX_RAM10，RE q10、WE pending_q10独立地址；wr RAW当前pending低/高10，older写旧recent Q。OUTPUT_REG0；eK发RE，eK+1前Q可用。父控制关RE时Q保持，不能把它当新输入。无同地址RE/WE：流内RE q+1/WE q，跨行RE0/WE D−1，D≥2。

窗口先声明REAL/REPLAY/TAIL/WAIT_EOF/IDLE、pending_kind/q/row/raw20、水平L/C0/C1三列30bit、输出窗口slot。组合计算RAM控制和旧垂直列；顺序always_ff在advance沿先处理旧pending、再nextRE。row0只填recent不输出；row1取current/recent/current，其后older/recent/current；REPLAY取older/recent/older，不新写，但同沿旧REAL末pending延迟写仍完成。

首q0初始化C0/C1和L=C1（左reflect）；同一行q≥1用旧L/C0/C1生成lane0、旧C0/C1+新首列生成lane1，然后移历史。新输出行q0到达时先形成旧行末pair，lane1右列=旧C0（右reflect），再建立新行首历史。TAIL同样右列=旧C0；markers依据旧中心。最终窗口EOF被DK接纳并历史清空后窗口才回IDLE。

flush沿禁止新RE/WE；旧pending REAL/REPLAY已经到同步RAM返回时刻，记录discarded_read_pulse并归还该预约，数据不发布；清私有水平/窗口/phase有效性，下一任务重新逐行填入，不清RAM数组。top ABORT继续等待旧DK RGB实际交付，并检查window empty；flush level不能反复计同一旧pending。

top先声明IDLE/ARM/RUN/DRAIN/ABORT/DONE、locked ID/phase、q/y、计数/firstreason。job接受后ARM；RUN真正input fire先accepted++，合法才进入window且更新q/y，准确最后EOF后DRAIN。每window→DK fire和RGB→外fire独立加计数；同沿非法输入/匹配cancel时旧合法输出仍计入。失败先锁原因、ABORT；ABORT先私有flush、等待公开RGB结清；DRAIN仅数量及EOF消费和全empty一致才OK。done寄存器一旦公开不再变，消费后IDLE。

## F—H 验证及追踪

RC-T01：四色phase的纯R/G/B、常量0/2/1023、彩条/随机/单点，独立按二维reflect101坐标和显式2×2CFA颜色表计算；逐窗口180bit和逐RGB48核验，不模拟RAM FSM。T02：4×2、6×5、34×19、1040×3（地址511/512）、1920×1080完整帧，P输入/P窗口/P输出和边界不裁。
T03：输入气泡、RE后下游stall、连续停顿、跨行、末REAL写/REPLAY同沿、最后TAIL无新RAW；同步RAM同址碰撞断言、q地址界限、pending只返回一次。T04：配置phase/ID活动中变化、错误取消ID、连续任务/held done与RGB、同沿旧window/坏RAW计数。
T05：in_bad/错ID/coords/markers、取消REAL/REPLAY/TAIL/held窗口/held RGB，done前实际drain；共同rst后新ID不混历史。T06：真实4RAM/DSP/资源MAP；目标100MHz不是生产STA保证。T07：摄像头配置/CSI规范/CDC不可反压/源writer/完整scope适配。T08：整体资源时间/生产引脚/PNR/STA/总bit及全部十一项。

追踪：RC01→窗口/原DK→T01/02；RC02→同步行RAM/pending/advance→T02/03/06；RC03→top协议/ABORT/public保持→T04/05；独立图参考/TB/runner→实际结果和hash。局部数学/旧状态走查完成，原CAM资料缺口保留为生产边界而不阻止本单元。中文理解验收待阅读反馈，功能以实际测试记录为准。
