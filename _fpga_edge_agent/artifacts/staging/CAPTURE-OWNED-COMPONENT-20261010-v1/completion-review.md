# 采集管理增量核对

本批实现了Source自动分配、RAW真实EOF登记、producer/RX双闭合、SOURCE_END实际回执后的完成，以及错误/取消/隔离路径。正式Result发布和显示冻结/回收仍须继续。

|实际当前运行|成功完整图像|像素比较|其他场景|结果|
|---|---:|---:|---|---|
|capture_owned_small_001，34×20|11|7480|6主路径协议、4独立manager端口模型|仿真＋独立审计PASS|
|capture_owned_min_001，4×2|11|88|同一21场景列表|仿真＋独立审计PASS|
|capture_owned_hd_001，1920×1080|1|2073600|完整RAW/CFA/Source写入与自动登记|仿真＋独立审计PASS|
|capture_owned_map_001|组件综合|不算动态像素验证|默认1080p组合|实际MAP退出0|

合计43场景，其中35场景为实际owner/RAW/CFA/writer/AXI组合，8场景是明确的manager公开端口对抗模型；23个成功完整帧，2081168比较像素。主路径33次真实capture job、29次实际capture DONE、29次安全frame DONE，2次重复身份分配拒绝、2次UNKNOWN无安全完成、2次已结束RX但producer缺少完整输入的未完成工作。后四个未完成工作仅由共同cold作废，没有伪造关闭。

CO01/02：真实owner ALLOC_SOURCE身份/base/scope启动实际actor，再交付grant；四Bayer、两种二维RAW、相邻帧无复位与scope/Bayer当前输入扰动均按接受时快照执行；grant持有期间RAW/RX不接受。重复frame/epoch拒绝没有job/AW/DONE。当前单writer/无Result借用的组合最多保留最新加正在采集的Source，不能实际触发六slot池满；owner池满/耗尽的其他枚举传播是同一非OK转发分支的代码核对，尚未在本组合分别动态注入，后续共享owner压力验证仍保留。

CO03/04：每个SOURCE_EOF前都有公开RAW EOF fire；owner命令往返仍采集真实capture DONE和RXclose。正常SOURCE_END7前必须具备实际全部W/B/RPC闭合、producer DONE正常计数、RX good/no-future与EOF登记。完整Source字节和A64尾零由独立二维CFA及公开AXI重建比较，未预装Source期望。仅有RX close或仅有完整计数但无EOFhook时不推断完成。

CO05/06：旧handle/scope/Origin close及旧取消不污染当前；真实RX bad/取消最多一次actor cancel，缺少RXclose不释放；BRESP安全错误和wrongBID隔离均真实执行。manager端口模型独立覆盖held job后的halt、held owner命令后的halt、坏计数、完整计数但缺少EOF；模型中的producer/EOF输入明确是fixture，只有主组合用于物理像素/总线证明。held安全DONE不因随后无关halt重写；UNKNOWN不产生安全frame DONE，Source在实际owner为S_Q且不可复用。

CO07：所有主路径安全完成均在实际SOURCE_END/OK回执后，公开身份与正文反压保持。正常最新Source指针与COMPLETE状态由唯一owner生成；无效Source不替换旧latest。当前wrapper是采集组合验证入口，正式父顶层必须将manager命令接入与Result/显示共用的单owner，不能各自实例化owner后称为全局账本。

CO08：实际vlib/vlog/vopt/vsim退出0，fatal探针必须退出1且包含预期标记，独立audit退出0。运行末尾全部current/snapshot hash检查通过。当前组合无失败运行；所有输入/源码/测试及工具日志保留。

完整1080p实际97200 AW、388800 W、97200 B，6220800字节Source写入；2155161个数学后端时钟周期。此周期数没有真实DDR或不可暂停CSI延迟，不换算成物理摄像头FPS。

MAP网表逐实例计数与rpt一致：6597 LUT4、4280 FF、235 ADD、8 RAM10、0 DSP。Source专用连接裁剪了owner未使用的Result/lookup路径，因此不能代替完整共享owner资源；没有Mapped动态、PNR、STA或比特流。本批warn.log包含EFX-0011 VERI-WARNING 2条、EFX-0200 20条、EFX-0657 6条；原X/Z模拟检查二值化、未使用端口/数组及小数组逻辑映射均保留记录，无零警告声明。

剩余：真实CSI CRC/晚到错误生成器和不可暂停输入缓冲；Result/Canny/ANN自动调度与发布；显示A64相容校验、实际显示回调/冻结重算/RETIRE；原范围复杂识别与资源优化；匹配DDR模型/PHY；最终共享资源/FPS、板级引脚/时钟/CDC/PNR/STA/bit。理解验收待用户实际作答，软件工作继续。正式数据库/Manifest/H0、硬件下载和观察没有改变。
