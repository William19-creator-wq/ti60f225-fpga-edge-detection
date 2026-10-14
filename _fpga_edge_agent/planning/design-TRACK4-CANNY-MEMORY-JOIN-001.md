# TRACK4-CANNY-MEMORY-JOIN-001 v1：实际cache/queue/滞后核心组合

2026-10-08。按用户“当你统計完后自行进行, 无需我的批准”持续实现；原资料、已登记包、正式数据库及硬件状态保持。此卡读回后先冻结输入再编码，不再次索取批准。

Goal：由真正的片上RAM分类缓存和完整外存队列支持精确八邻域滞后连接，并排空后报告任务终结。Current：cache v1.1的8RAM仿真/MAP通过，queue v1的FIFO仿真通过/MAP进行中，HY v1在行为服务上通过。Target：把三者接成可综合组件，独立BFS核实际边缘和外存分类结果，取消不拆原子claim、错误不伪装成功。Gap：RTL组合/真实64B仲裁/取消诊断交接/组合测试；物理DDR和R2生产者及输出帧另闭合。Assumptions：同clk/rst，几何不变，独占两个不重叠外存授权区；joint reset仅由安全物理复位证明支撑。Open questions：本软件单元合同明确，DDR动态模型缺口不妨碍客户端仿真。

Milestones/Detailed steps：整体数据流→端口及旧状态检查→仲裁/关闭草图→RTL→独立参考/TB→组件综合→接R2和帧服务。State transitions：保存读回READY，按持续授权实现，实际结果单独登记。Artifacts：work/active/track4_algorithms_20261004/canny_memory_join。Validation：MJ-T01…08。Failure handling：安全错误作废任务，已公开槽交付后关闭；drained未知则隔离至真实安全joint reset，不重配置。Human gates：本地审计例外，无硬件操作。Rollback：不覆盖旧尝试。Completion：组合参考逐像素相同、关闭后外存结果一致；组件通过不等同生产整机通过。

## A—C 先看整体及局部职责

job接受state_base/queue_base/job_id后，控制器依次配置cache、queue，再启动HY。HY扫全N强像素，然后FIFO八邻域扩张，再顺序导出N边缘位。cache claim WE与queue append WE同沿；HY push只确认。两个64B客户端经line_rpc_arbiter2连唯一外部口，不把请求/回复交给错误client。HY结束只表示计算结束；控制器还需cache FLUSH、queue end seal，安全排空后才公开done。pixel在之前可以传到私有输出帧，帧服务必须等待成功done才发布。

局部：line_rpc_arbiter2拥有一个已接受请求/一个回复，保存owner、addr、512bit data；canny_memory_top负责配置、取消、关闭、外存区合法性与终结；hysteresis_core_memory为HY v1的最小诊断扩展副本，增加state_rsp_aborted/queue_rsp_aborted，其正常数学/邻域/计数完全沿用；原HY文件保持字节不变。cache/queue直接使用已验证文件，不复制修改。

MJ01：两个区64B对齐，state大小ceil(N/256)×64B，queue大小ceil(N/16)×64B，各33bit终点≤2^32且不相交。配置前统一检查，错误直接稳定done，不产生访问。64bit实验job_id由本组件完整保存；生产更大的scope在外adapter持有，不截断。

MJ02：仲裁IDLE只给一个client ready，轮转；接受后REQ公开保存payload直至外口接受，WAIT等待真实response，REPLY把保存response固定交付给原owner。REPLY消费后才能换owner。drained0回复仍交付原client，随后QUARANTINE；另一个client不获新ready，不伪造全局排空。ready/valid无组合环。

MJ03：共同取消广播匹配job_id至cache/queue；HY旧STATE/QUEUE请求和回复仍真实终结。cache/queue aborted=1/error=1是私有预约取消；HY只有已记录同job取消才接受这个诊断，直接CANCEL、不计入成功enqueue/pop，不把它伪装成普通状态0或索引0。aborted但没有匹配cancel作协议失败。真实服务error且aborted=0保持ERROR优先。

MJ04：START同沿cancel由HY直接CANCEL；配置期间cancel也粘住并继续完成已有配置槽，之后关闭。RUN期间已有held pixel保持到交付；done保持到消费。关闭时FLUSH aborted被记为已取消的安全关闭，不把真实外存错误吞掉；控制器同时保存外部error事件，error优先于cancel。drained0无done成功，输出quarantined，保持旧context。

## D 接口和组合检查

job_valid/ready、job_id64、state_base32、queue_base32。pixel_valid/ready、index21、edge1、job_id64。done_valid/ready、job_id64、outcome2(0成功/1失败/2取消)、reason8、enqueue/pop/output_count22；结果计数由HY保存，不推算。cancel_valid/id64只影响相同active job。memory接口沿用64B line_req_valid/ready/write/addr/wdata512、line_rsp_valid/ready/rdata512/error/drained。quarantined禁止接受新job；同步rst需要外部安全复位证明。

控制器req mux：RUN由HY发cache req和queue req，FLUSH阶段只发op3/index0，SEAL阶段只发end_job。已accept的HY操作必须先到HY done，关闭才切mux；不能中途把旧回复给控制器。cfg_reply只给当前配置状态；cache claim→queue直连，queue ready仅由自身旧state决定。两client RPC分别接仲裁器，ID保存至真实回复消费。组合检查：唯一live每client/仲裁/控制器；各held路径都有消费或隔离出口；RAM借用由原模块capture；cancel同沿旧claim保持成对；失败图不公开发布。

## E 中文操作草图和语法组织

先声明控制器IDLE/CFG_CACHE_REQ/WAIT/CFG_QUEUE_REQ/WAIT/START/RUN/FLUSH_REQ/WAIT/SEAL_REQ/WAIT/DONE状态、activeID/base、cancel_sticky/memory_error_sticky及结果寄存器。always_comb仅组valid/ready/mux和33bit区范围，always_ff按旧state/真实fire推进，held结果不重写。

接受job先保存所有字段/清计数及sticky，检查几何授权区；合法按顺序给cache和queue配置。配置请求一旦公开保持；等待rsp时记错误，按已成功配置的实际资源决定是否需要关闭。START只一次HY job fire。RUN转接数据/服务，matching_cancel粘住；HY done fire保存结果进入FLUSH。FLUSH真实rsp后转SEAL；SEAL只有drained1才到DONE，error与cancel按上述优先级形成固定结果。所有过程中全局unknown将状态冻结到隔离，不再提出新的私有步骤；已经公开槽仍由服务合同处理。

仲裁器组合按turn选eligible client；顺序fire保存owner和payload。外部rsp先保存到独立reply槽，再owner消费，不在收到同沿换owner。将error/drained全体原样传递；不加模拟timeout假排空。

HY诊断扩展只在STATE_WAIT/QUEUE_WAIT增加“aborted+已取消→finish CANCEL；aborted未取消→协议ERROR”分支，位于普通数值/索引校验前；真实错误无aborted仍走原错误路径。其它旧语句不变，独立参考继续用纯deque/BFS。

## F—H 验证、追踪及边界

MJ-T01：32×24密集/随机/无seed/孤立/对角/跨行反例，逐像素独立BFS、actual flush后全分类word比对，高位padding保持。T02：两个区不对齐/超32bit/重叠拒绝；合法端点；旧done反压/重新配置。T03：实际cache claim WE与queue WE/tail同沿、确认无重复，两个RPC争用/持久反压/owner保持。T04：完整1080p稀疏/随机无seed/对角测试及最重连接场景独立记录用时，不能预称FPS达标。T05：配置/claim阻塞/forward/prefetch/held pixel/FLUSH/SEAL取消，正常和安全错误优先及unknown隔离。T06：组件真实12RAM/资源综合，生产pin/PNR/STA/bit留到实际top。T07：R2直接作为分类生产者，图写入/封存/运行/结果闭合。T08：真实DDR/摄像头/HDMI/全十一项最终工程。

追踪：MJ01→top范围/配置→T02；MJ02→arbiter→T03/05；MJ03→HY诊断扩展及广播→T03/05；MJ04→top关闭/终结→T01/02/04/05。所有数值及对比只取实际输出，行为DDR不冒称器件验证，组件综合不冒称生产PNR。代码前保存并读回此设计；功能验收靠日志，理解验收等用户阅读反馈。整体目标继续有效。
