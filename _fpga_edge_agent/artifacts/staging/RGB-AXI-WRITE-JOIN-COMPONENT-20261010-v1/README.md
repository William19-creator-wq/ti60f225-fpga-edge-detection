# 实际RGB写帧与共享AXI写服务：阅读与验证入口

本包对应TRACK4-RGB-AXI-WRITE-JOIN-001 v1，沿用用户“当你统计完后自行进行，无需我的批准”及本批本地审计例外。原HDK/历史登记包只读，正式数据库/H0/硬件状态未改。

## 1. 先看整体，再看交接与局部

先读`_fpga_edge_agent/planning/design-TRACK4-RGB-AXI-WRITE-JOIN-001.md`的A/B整体、C/D端口/组合检查、E中文语句操作、F时间/数值、G/H验证/双向追踪，再看本包RTL。工程配置顺序修正另见`planning/design-TRACK4-RGB-AXI-WRITE-JOIN-001-XML1.md`，没有修改业务源码。

整体路径：公开camera job/CFG及RGB48+坐标/身份→rgb_axi_write_join授予检查/资格接线→实际rgb_source_writer→实际rgb_source_ram_word四个同步RAM10→双packet→实际axi_write_pair_service端0→唯一实际axi_line_bridge的512bit快照→AW/4×128bit W→真实B→实际writer回执/packet及bank退休→局部DONE。

另一路algorithm64B写请求进入共享服务端1，使用独立地址区；测试刺激的是其公开RPC，尚未把实际算法主体实例接到此包。公共服务3:1机会轮转已由其独立组件验证，这不是DDR最坏期限证明。这个组合只有同一core时钟，没有新增CDC。

## 2. 对照中文操作读代码

`rtl/rgb_axi_write_join.sv`是新增核心。E1/2的frame_end用33bit检查64B对齐及完整A64≤默认256MiB。一个rejected_cfg FF保存固定错误回执，未对齐、越界或RTL四态未知配置不会送child job，也没有camera DONE/AW。消费该错误只结束配置拒绝，不代表成功采集过一帧。

E3使公开in_ready和实际writer的in_valid用同一backend_enable/globalQ资格；pixel只在两端共同真fire时计数，低24为R0/G0/B0、高24为R1/G1/B1。写入内存顺序始终是R0、G0、B0、R1、G1、B1，跨行不加padding，只有整帧末尾A64补零。

E4/5把实际writer PUBLIC packet接服务端0，algorithm接端1。cancel/source_stop不用于撤回PUBLIC packet；未知回执不伪装成已排空。globalQ阻新job/pixel/request，已有AW/W/B、通知、CFG和已形成safe DONE照常推进；service enable保持原parent backend_enable，不用globalQ把旧物理承诺强制停止。source_stop提示上游停止，不是FrameRef/读取栅栏已关闭。

四个`deps/*.sv`逐字节复制已登记实际RTL；`deps/efx_ram10.v`是现有厂商原生仿真模型，SHA守卫见baseline。它不列为XML业务RTL。源writer原有carry/bank/RPC机制及4 RAM10不重写。父必须授予互不重叠的合法帧和算法区域。本层允许输入ready暂停，不能据此宣称不能暂停的真实MIPI永不丢帧。

## 3. 验证怎样观察

`model/join_reference.py`按坐标独立产生六种RGB和全帧/padding，不模拟writer内部carry/bank/packet。它还从公开job/pixel、camera RPC、算法RPC、完整AW/W/B和终态重建事务账/字节内存；每个正常帧在其实际DONE处都全量核对，后来的同名输出文件不能掩盖前一帧错误。

`tb/tb_rgb_axi_write_join.sv`每沿检查CFG/DONE/AW/W/algorithm回执保持、pixel双侧同fire、globalQ阻新事务。`bind rgb_source_writer`的observer只连接该模块公开端口，用于观察已经公开但未接纳的camera packet、真实line回复及其保持；预期不读取DUT的内部状态/数组。完整输入和实际内存文件、所有接受/交付事件保留；HD不输出数百万条idle行。

可信共同cold reset覆盖本组件、公开producer及数学AXI byte slave。保留中止及UNKNOWN账，没有暖reset/DDR残留事务排空证明。错误帧已发出的W有真实模型内存副作用，不假装取消回滚。

## 4. 已实际完成的检查

|当前run|尺寸/范围|结果|
|---|---|---|
|join_small_001|34×19，6颜色及26协议场景，共32场景|compile/elab/fatal拒绝/RTL/独立审计通过|
|join_min_001|4×2，同32场景|同上通过|
|join_bank_001|512×2，6帧，恰好整bank边界|同上通过|
|join_tail_001|510×2，6帧，末尾12字节补零|同上通过|
|join_hd_001|1920×1080空间RGB完整帧，4096算法并发写|同上通过|
|join_map_001|工程XML验证阶段|失败，未进入RTL综合；完整原始记录保留|
|join_map_002|修正XML顺序，关联HD当前9源，12源/工程快照|实际Efinity MAP exit0、网表/资源报告及源hash核对通过|

HD实际1036800pairs、6220800 RGB bytes、97200camera RPC及4096algorithm RPC全部一致；总101296 AW、405184 W、101296 B，实际物理模型写6482944字节。包括AW/W长停顿、延迟B、输入气泡、CFG/DONE和算法回执停顿；该运行2937927 core cycles。这个数学slave调度下的周期数不是实际DDR、CSI、显示期限或整机FPS证据。

两个32场景包含PUBLIC/等B/发W时取消、终态形成后取消、错handle取消、四种pixel tuple错误、真实BRESP错误覆盖同沿cancel、错BID通知先到/正确旧B后到、live backend停用/恢复、算法Q下camera PUBLIC借用保持、整帧越容量及最后合法A64、四态job拒绝、held CFG/DONE停用、live/UNKNOWN可信共同cold及safe DONE遇到另一算法Q后继续消费。详见case-results.jsonl、join-audit.json和公开事件。

MAP默认生产1920×1080/Ti60F225/I3/100MHz目标、speed、retiming0、seq_opt0：2600 LUT4、2075 FF、55 ADD、4 RAM10、0 DSP/SRL。真实网表中新增wrapper仅1个rejected_cfg~FF，唯一write_bridge保留512 snapshot FF。报告与全部EFX实例计数相符，resource-result.json记录hash。14警告：3个X/Z guard在两态综合中折为常量、6个无用write-only rdata/loop变量删除、5个小descriptor数组转逻辑；payload仍真实4 RAM10。X/Z拒绝是RTL仿真检查，不能当物理亚稳态检测或替代CDC有效性。

## 5. 工程打开与复现

Efinity打开`project/rgb_axi_write_join_component.xml`可看组合及依赖。该工程是组件综合，公开RPC/AXI会在最终父工程内部连接，尚无板上IO/PNR/STA/bit。不要把组件的上千个接口bit直接当成板卡引脚。

脚本使用现有Questa/Efinity与ASCII work别名，不安装任何软件。新RunId防覆盖旧记录。软件仿真脚本run_join_sim.ps1可指定TestWidth/TestHeight/Full/Protocol；TB使用TEST_WIDTH/TEST_HEIGHT/TEST_PROTOCOL，不以全局WIDTH覆盖厂商RAM。run_join_map.ps1要求当前PASS仿真及所有9源hash相同。正仿真前真实fatal_probe必须非零退出且不得生成成功指标；所有PID、argv、timeout/exit及日志hash保留。

## 6. 追踪、边界与后续

RJ01→wrapper E3/实际writer→T1数值/全bytes；RJ02→frame_end/rejected_cfg→T4拒绝/最后合法地址；RJ03→实际四RTL连接→T1/2/3完整RPC/AW/W/B与两个byte grant；RJ04/05→new_source_allowed/公共请求与旧回执接线→T2/3 Q与cancel保持；RJ-T5→脚本/工程/源manifest→五正仿真及join_map_002。核心实现、公开观察和模型中的事件分类可反向返回这组要求。

本包证明当前组合RTL/原生RAM功能及组件综合。未验证综合后组合动态、真实DDR/PHY、物理CDC、不可暂停CSI吞吐、生产FrameRef权限/发布/栅栏、最坏读写/display QoS、实际算法主体并发、整机资源、板上引脚/PNR/STA/最终bit及硬件。下一步公共读写hub和生产帧控制会实例化实际camera/algorithm/display。完整五基础六高阶目标继续ACTIVE；复杂识别、DDR动态资料、整机时序等没有被此包替代。用户理解验收待实际作答。
