# TRACK4-RAW10-DEBAYER-KERNEL-001 v1：四相位双像素插值核

Goal：继续摄像头彩色软件部分，先实现已有CAM-OP04的数值核；真实RAW窗口/行RAM、MIPI、CDC、配置与DDR writer分别接续。
Current state：VIDEO-PARTIAL只给RAW高8bit预览，不是彩色；CAM v0.1已规定RAW10到RGB8单次舍入/四phase，数值公式明确。
Target state：两个RAW10 3×3窗口→两RGB888，所有坐标/标志/实验job_id按一次握手对应。
Gap/Open questions：本核无阻塞；实际传感器phase/窗口生成与完整scope adapter不由本单元推定。
Assumptions：低lane窗口90bit（9个10bit，行优先），高lane同；x_even偶数0…1918、y0…1079。phase0RGGB/1GRBG/2GBRG/3BGGR；窗口父端按reflect101补边并保持原图奇偶。
Dependencies：CAM-OP04、规范v0.2；保留输入SHA在baseline，不修改原大稿和已登记包。
Milestones/Detailed steps：整体行为→接口/旧状态草图→核/独立参考/TB→真实编译仿真→行窗口与摄像头整合。
State transitions/approval：读回就绪后按用户“当你统計完后自行进行, 无需我的批准”实施，沿用本地审计；不操作硬件/安装/网络/正式DB。
Artifacts：work/active/track4_algorithms_20261004/debayer_kernel，保存source-manifest/run，不覆盖旧尝试。
Validation：DK-T01…04；Rollback：只改该独立work单元；Completion：核逐位/握手证明，生产链路仍待合。

## A—D 整体、职责与接口

DK01：R/B中心本色取center，G取正交四点，异色取对角四点；G中心本色center、R/B分别水平或垂直两点。必须由当前像素原图坐标和当前phase选颜色，lane1使用x_even+1奇偶。
DK02：样本和S/d，d=1/2/4，RGB8=min(255,floor((S+2d)/(4d)))。保留RAW10到最后单次舍入，不先平均、截高8bit或加gain/黑电平假设。
DK03：一槽elastic流水，接受后最早下一沿被消费；稳态每拍一个pair；下游stall时RGB/坐标/标志/job_id保持；同时消费与接受以新item替换，无valid气泡不当0样本。
DK04：共同同步rst作废本核未交付输出；调用方承担上下游任务作废。未执行暖复位/CSI证明。

raw10_debayer_pair核唯一持有out_valid与out_body，无图像RAM，内部全部定宽加法/移位；调用方窗口负责10bit历史和边界，来源不直接RAWpair接本核。
IF-DK01：in_valid/ready、in_window_pair180、in_x_even11/in_y11、in_phase2、in_markers3={EOF,EOL,SOF}、in_job_id64；有效前提如上。phase和窗口在fire同沿取值，生产相机配置快照必须由父端保持/对应完整scope。
IF-DK02：out_valid/ready、out_rgb_pair48={R1,G1,B1,R0,G0,B0}，out_x_even11/out_y11/out_markers3/out_job_id64。无公共配置寄存器；不逐位跨时钟。
组合检查：一个输入恰一个输出pair，数量/标志/坐标不改变；phase只有两bit所有编码合法；父反压时窗口全部保持。核一槽不能替代不可反压相机FIFO，真实容量由父端算。

## E—F 内部中文操作草图和语言

先声明每lane九样本10bit、三个channel_sum13bit、每channel分母log2d两bit和13bit舍入容器，最后输出byte。从window定址切样本。用(xParity xor phase[0],yParity xor phase[1])判本色：00红、11蓝，其余绿；绿中心若yParity xor phase[1]==0，红在水平，蓝在垂直，反之交换。
完整求和先把每RAW扩13bit，再加，不在10bit内溢出。d=1加2右移2；d=2加4右移3；d=4加8右移4；移位结果9bit若>255饱和，再取8bit。最大舍入和4100，在13bit内；没有运行时除法器。
时序块：rst清valid；否则只有in_ready时out_valid<=in_valid，且in_valid时存RGB和全部sideband。组合in_ready=!rst&&(!out_valid||out_ready)，out_valid复位期间屏蔽。stall完全不写out_body，允许消费/替换同沿读旧输出。
Python参考用显式四色2×2颜色表及邻居颜色选择、整数divmod规则描述公式，不复用RTL的xor分支/移位函数。数学按真实接受顺序/job/coords逐位对应，TB沿前记握手、沿后检查保持。

## G—L 验证/追踪/状态

DK-T01→DK01/02：四phase、两lane/两行奇偶、0/1023/常量、单点和随机RAW，覆盖中心/两点/四点舍入中点及256饱和；独立RGB逐位比较。
DK-T02→DK03：输入气泡、输出随机连续停顿、同沿交付替换、最后一项drain、所有sideband保持和N输入=N输出。
DK-T03→DK04：启动reset、held输出复位作废、复位后新ID恢复；reset-aborted账独立，不将作废item计成功。
DK-T04：完整行窗口/reflect101、采集真实链路、综合/STA/整机另运行；本核TB构造窗口不能声称行RAM已实现。
文件trace：rtl/raw10_debayer_pair.sv→DK01…04；model/debayer_reference.py→颜色表/整数公式；tb/tb_debayer_pair.sv→实际fire/保持/复位；scripts/run_debayer_sim.ps1→原退出/日志/独立审核。数据与时间证据分开记录。
整体、职责、接口、局部、语言、组合、验证、追踪、范围/版本和读回十项有内容，无单元阻塞；本批持续授权有效。最终docs按实际文件结果填写；完整摄像头/HDMI不在本核交付中冒称通过。理解验收待反馈。