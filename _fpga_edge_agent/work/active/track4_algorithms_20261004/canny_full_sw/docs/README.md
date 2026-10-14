# 完整Canny软件链路 v1.1：RGB到可显示结果帧

阅读次序：`planning/design-TRACK4-CANNY-FULL-SW-001.md`（整体→局部→交接）→ v1.1失败旧pixel收尾 → 本文 → `rtl/canny_full_top.sv` → 两writer wrapper → `packed_frame_line_sink.sv` → 原R2和实际memory组件。按用户持续授权实施，保留所有失败尝试与冻结输入，未操作实体板卡。

## 当前实际证明

真实RTL链路：RGB888双像素 → 灰度/可选中值 → 5×5高斯 → Sobel/方向 → NMS/双阈值 → 64B分类帧writer → 实际8RAM cache、4RAM外存FIFO与八邻域滞后 → 灰度0/255结果帧writer → 所有子任务实际排空 → 固定done。

`full_canny_small_004`通过28组34×19完整图，独立逐字节比对18088个结果像素、初始分类帧、最终标记分类空间、完整BFS FIFO顺序、原梯度及原CS592状态；覆盖median/retain开关、全零/阶跃/斜线/彩色扰动/圆边界/随机、TL=TH和极限阈值。34×19故意让class的最后64B块与灰度最后块不满，padding也比对。多个任务CJ低64位相同、config高32位不同，原96bit身份完整保留。

同时通过十种取消阶段（配置、启动、RGB接入、公开class请求、result配置、HY启动、claim同沿、公开result请求、result回执等待、最终发布前），三种真实安全error（class写、HY读、result写），未知drain隔离及安全joint reset后恢复；结果writer失败且HY有旧held pixel时明确discard，实际写入count与discard不混算。非法W/H/阈值/对齐/重叠/超32bit授权在配置前拒绝；输入bad经原R2失败闭合。

`frame_writers_001`额外18个直接接口检查、8次实际64B payload比对：class错误高32bit身份/坐标/SOF/类别3，edge错误index/handle，部分累计取消、公开请求反压取消、真实error优先cancel、held done不改、unknown隔离。完全从公开端口驱动，没有force内部状态。

`full_canny_hd_001`通过一幅真实完整1920×1080阶跃图：1036800输入pair、1036800分类pair、2073600实际结果像素、1078个边缘；初始分类空间、最终分类空间、FIFO顺序、最后结果帧及原状态完整比对。实际34854652时钟、58990个64B请求，包含行为外存随机停顿。此单幅1080p证明完整链路/地址/计数，不冒称所有最重场景或生产帧率；小图数学/取消/error和早先memory组件四幅1080p证据分别保留。

`full_canny_map_001` Efinity 2026.1组件综合通过，Ti60F225/I3：38 EFX_RAM10、14475 FF、18865 LUT4、1495 ADD、166 SRL8、0 DSP。38=原R2 26 +实际cache8 +queue4。组件综合不等于完整整机资源/生产pin/PNR/STA/bit通过，SDC 100MHz是目标而非实测保证。

## 接口及内部组织

外部CJ142保存epoch/frame/config共96bit身份，以及W/H/TL/TH/median/retain；三个64B对齐且不相交的class/queue/result授权区先以33bit终点检查。内层64bit handle来自单独递增分配，原scope完整映射至held done消费，不切CJ低64位。输入FP74和梯度185沿用原R2位序，原CS592逐位保存。

class每对两像素占4bit，256像素/64B；result每像素灰度8bit，64像素/64B。最后一个data使用next_buffer发出，最后padding固定0，所有地址都在整帧授权内。两writer共享`packed_frame_line_sink`的明确REQUEST/WAIT/DONE生命周期，各wrapper只核自己的metadata；10bit摄像头插值是之前独立核，不是本模块输入。

`canny_full_top.sv`先配置class writer、启动R2，独立保存R2 status与class done，只有都成功并实际排空才切HY阶段。先配置result writer再启动HY；HY done与result done也分别保存，末像素不是提前发布依据。公开64B仲裁owner不随阶段改变；失败私有图不发布，真正的帧发布由后续frame manager完成。

取消时原R2的私有流水共同flush，source_stop通知输入生产者停止旧job；公开外存请求保持。HY持有的旧pixel必须真实交付，因此结果writer安全done之后由top明确discard，避免等待已关闭writer产生死锁。unknown没有排空证明，所有旧context保持至外部证明安全的joint reset。

## 可观察工程与复现

`project/canny_full_sw_component.xml`可在Efinity打开Ti60F225/I3开发配置，列25份实际业务RTL；deps/是冻结共享work源的GUI镜像，vendor原RAM模型只用于Questa，未作为生产RTL综合。组件输入931位/输出1568位主要是内部存储与状态总线，不能直接全部分配为板卡物理pin。

`scripts/run_full_canny_sim.ps1`默认28组与完整协议测试，FullHD运行一幅完整阶跃图；`run_frame_writers_sim.ps1`执行18项直接writer协议测试；`run_full_canny_map.ps1`冻结29份仿真输入和3份工程/MAP脚本后综合。每次必须新RunId，开始/退出/超时/源hash和日志全部保存。独立参考复用原R1/R2纯二维整数数学及独立deque BFS，不使用RTL FSM或从DUT推黄金。

失败历史：small_001拒绝mutable RGB参考输入，改成不可变tuple；small_002原EFX_RAM10没有timeunit，沿用原R2的显式编译timescale；small_003初始分类快照在新任务接纳前误读了清空内存，修正为当前scope真正进入result配置阶段才取快照。实际最终结果/梯度当时已一致，small_004全部独立审计通过。旧尝试没有覆盖。

登记包source/保存源码及模型/TB/脚本，reference-layout/保持被导入数学参考的原目录关系，可离线独立重读；inputs/保存两个基线版本。报告以实际PASS和源码hash绑定为准。原始资料、正式DB与硬件状态均未改。

## 尚未完成

RAW10行窗口/reflect101与生产摄像头、DDR AXI/PHY真实动态验证、帧所有权/发布/冻结恢复、显示预取/TMDS、候选质量与圆/旋转矩形/遮挡识别、总资源与处理时间优化、真实board top生产引脚/时钟/PNR/STA及总比特流。五项基础与六项高阶的全部目标仍有效，不能因本组件完成就宣布整机完成。
