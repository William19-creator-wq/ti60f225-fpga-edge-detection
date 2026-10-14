# FIT v1：由整体草图读到实际代码

本目录只实现A6的七类数值运算，不是整套识别器。批准记录位于 `experiments/track4_algorithms_20261004/03_review/approval-r3-fit-v1.md`；冻结设计为 `planning/design-TRACK4-ALGORITHM-R3-FIT-001.md` v1，基线45项。正文及旧scalar不改字节。当前运行状态由runs内原始证据和implementation-log记录，不能把本阅读说明当成测试通过。

## 1. 阅读次序与整体交接

先读冻结设计B整体行为、C职责和D布局，再读本页，最后按下表逐个进入文件：

外部调用方的完整622位请求 → `fit_core.held_request` → 一步步形成406位私有命令 → `scalar_bridge.accepted_command` → 原`scalar_core` → 完整585位私有响应 → 桥403位缓存 → 父单个192位工作槽 → 外部585位结果。

外部消息、私有消息、槽号是三种不同对象。桥私有64位序号只在真实child请求接受沿推进；槽号不代替序号。父持有外部ID直到结果消费或共同冷复位，桥关闭私有义务后才允许发布缓存。消费者停顿只停住外部HELD，不妨碍取消排空。

| 顺序 | 文件/关键符号 | 职责及反向要求 |
|---|---|---|
| 1 | rtl/fit_protocol_pkg.sv：check_request、extend_field、fits_return、pack_response | FT01/06；字段、首错、完整高位与复合打包；T01…08 |
| 2 | rtl/scalar_bridge.sv：SEND、WAIT_CHILD、CHILD_CLOSE、RESULT_HELD | FT01/07；私有ID、真实消费、保持和关闭；T07/08 |
| 3 | rtl/fit_core.sv：PREPARE、QUALIFY_RETURN、LOCAL_COMMIT；L/T/I/D/F步骤case | FT02…07；七运算和一槽一提交；T01…09 |
| 4 | rtl/scalar_protocol_pkg.sv、scalar_core.sv、reset_sync.sv | 原字节复制。child只导入scalar包；父/桥只导入fit包；T07/08 |
| 5 | model/fit_reference.py：evaluate、rational_distance | 独立大整数式、错误优先、完整585位期望；FT08/T01…06 |
| 6 | model/fit_vectors.py：statistics、source_request、generate、audit_core、audit_probe | 固定种子、真实点集/合成统计分账、来源/CRC审核；T09/10 |
| 7 | 四个tb/tb_*.sv | helper政策、真实/隔离bridge、core数值/取消/reset、probe真实观察；T01…10 |
| 8 | rtl/fit_probe_top.sv：SOURCE_OFFER、SOURCE_WAIT、OBSERVE_BITS | 384位动态源，实际请求/消费和585位CRC；FT08/T10 |
| 9 | scripts/run_fit_sim.ps1、run_fit_build.ps1、postroute.tcl及project三个文件 | 新attempt、原日志/非零失败、同源物理门槛；FT08/T10 |

以上7 RTL、2 model、4 TB、3运行支持、3工程合计19业务文件。docs和runs是说明与派生证据，不加入另一条算法路线。

## 2. 从接口到语句的操作草图

`fit_protocol_pkg`命名低位偏移；字段每项独立signed/unsigned。`pf(payload, low, bits, signed_field)`明确接收当前旧payload，用宽移位及掩码提取字段，再规范扩展到192位。参数显式传入，组合计划的输入变化可直接观察，不靠函数隐藏读取消息。

`PREPARE`只读已有效槽，锁完整命令及目的、宽度、signed资格、下一步号。`ISSUE`提出valid后保持。`WAIT_RETURN`看缓存有效；`QUALIFY_RETURN`真实消费一次完整403位缓存，先检查目的/矩阵/385位高位，再只写一个槽。`ADVANCE`下一沿才推进。局部移位、交换和反号经过`LOCAL_COMMIT`，也是一沿一槽。

工作槽数据不在新job全部清零；清的是16个有效标记及anis/μ字段资格。每个case通过`need(mask)`写出读取依赖，缺少资格形成INTERNAL，不把旧数据当零。最高实际数学容器171位，192槽留足范围；全商检查后才查s18几何，几何失败仍用原局部GEOM_RANGE。

圆LS的L01…21按批准表：trace、Δ、条件、两个完整Q4商、质量。kind17从L07直接到L20，不求中心。TLS的T01…61：完整协方差和PSD → anis → 两分量规范normal → rho先于μ → K/M。kind18到anis后跳T61，只打包诊断。T30负u交换、T39/40反号各分沿，w15的anis和μ独立有效。

交点前分别核两条normal的K，再求分母和两个宽商；负分母通过保存的反号标记同时变换，x几何通过后才求y。LINE的D步骤先K/M或完整命中缓存、f/q0，最多一次±1修正，再重做上下精确资格。FINITE的F步骤保留原N/D，floor商和floor根只提供候选，最终用完整中点比较及两边资格，K=1的小边合法。

局部奇数边界也显式表达位宽：`line_odd_boundary(q:u21, upper)`先扩u22形成2q±1，`line_neighbor(q:u21, increment)`先扩u22保留进位；`finite_odd_boundary(q:u19, upper)`先扩u20形成2q±1。三个纯函数返回完整192位，原资格检查仍负责越界分类。零的下边界按原D15/F21分支跳过。先草图后代码的理由和不变量在placement-operation-sketch；TB按原192位表达式核每次真实局部提交，并检查最大值进位。

四项缓存仅存normal64/K65/M33/valid；无frame、point、结果ID。命中不跳格式/point检查；同沿取消抑制安装；已有效纯数学缓存可跨job保留，冷复位清valid。重复key不新增分配。

## 3. 保持、取消和复位

匹配取消只影响父尚未HELD的事务。先记已经发生的cmd/result fire，再进入DRAIN；已提出命令不撤回。DRAIN具备返回接收能力，和外部rsp_ready无关；只有published=0、pending=0且真实bridge quiet才PACK DROP。内部错误同样关闭义务，但保留原首错，不冒充外部取消。

桥的child响应真实消费后再等child quiet；缓存发布后完整body保持至消费。外部父HELD也保持，取消同消费不改旧body。共同cold reset清有效性、作废在途账，不制造假响应。KEY通过复制的两级reset_adapter进入共同同步core_rst；实际级间Q→D及同步复位路径须进行物理时序检查。

## 4. 参考、测试与工具操作

参考的LS/TLS使用直接完整式；两类距离用有理中点二分，既不读DUT工作槽，也不使用DUT的M/q0或floor尾段来求最终距离。向量包括固定七种子、图内点集、宽typed统计、两个诊断反例、±1修正、N1/D2和N1/D5、缓存顺序、格式首错。小图只是确定边界的测试，生产1080p要求保持。

TB在negedge驱动，posedge记真实fire和域内账。主核观察输出585位，额外记录真实private_scalar请求/响应及局部提交；取消/reset单列。`finished`未置位的致错必须非零退出，不能只靠工具进程exit0。

现有本地pwsh可运行 `scripts/run_fit_sim.ps1 -RunId 新编号 -Suite All`。每个编号是新目录，保留旧失败；通过后同19文件哈希绑定到 `run_fit_build.ps1 -RunId 新物理编号 -SimulationRun 已通过编号 -Stage Map`，继而Interface、Pnr、Sta。Bit只在真实报告和资源/引脚/数据D路径release-gate核通过后允许。生成后登记staging并停止硬件操作。

物理工程是Ti60F225/I3、25MHz，J2时钟、P13 KEY、N14/P14 LED；不是相机/DDR/HDMI整机引脚证明。只有KEY到两个异步SR及LED输出例外，不切核心、整个reset或算法路径。

独立STA将同一次PNR的原路由trace从outflow复制到work_sta供工具读取；不重新路由、不替换网表。Q→D查询的单个正则分别解析后合并，保留非空门槛；工具把报告保存到STA的outflow。过程/创建时刻/参数及结果均在新attempt保留，不能用修复后的报告覆写旧失败。

逻辑名称与物理名称以实际map.v为准：桥accepted_command→arithmetic/child_req_body（其中还有私有序号寄存器），child的response_value→arithmetic/child_rsp_body，桥cached_result→arithmetic/bridge_result，父response_value→顶层rsp_body。完整结果查询仅取child_rsp_body的值域200…584和原full；K/M仅取cache_k/cache_m数组，不把cache_key查找算作K/M数据。缓存数组前缀由工具生成，查询保留职责和Q/D端点约束。

实际阅读入口：[私有命令与局部操作参数](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_fit/rtl/fit_core.sv:117)、[PREPARE及真实返回提交](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_fit/rtl/fit_core.sv:552)、[完整385位资格](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_fit/rtl/fit_protocol_pkg.sv:28)、[独立整数公式](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_fit/model/fit_reference.py:87)、[两类事务原始事件审核](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r3_fit/model/fit_vectors.py:180)。源位置已按第二轮实际代码核对。

## 5. 当前理解和完成边界

代码、编译、仿真、布局布线/时序、bit登记分别记事实。用户理解验收待实际反馈，不阻塞已批准实现。完整Canny滞后连接、识别候选/支撑/去重、DDR动态资格、生产视频及整包资源/FPS/质量仍需要后续工作。
