# R4 STATS v1：最终组合设计与输入读回

2026-10-08；DESIGN_SELF_REVIEW_COMPLETE / READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。人工理解验收待用户真实反馈。这是当前Agent对设计的读回和组合分析，没有独立审查Agent、没有仿真/EDA或用户批准。

后续说明：本v1是首次STATS批准请求之前的中间候选，已由v1.1补齐可复现的FIRST_SEQUENCE测试起点。当前应读主卡v1.1、两个v1.1附稿及r4-stats-design-readback-v1.1；本文描述的原v1冻结时54项0漂移是当时事实，canonical主卡后来修订，原v1基线不再是当前有效候选，不能拿它执行。主稿v1完整字节保存在planning/design-TRACK4-ALGORITHM-R4-STATS-001-v1.md；此中间候选未收到批准，也未生成业务代码。

## 1. 范围、版本和阅读次序

任务TRACK4-ALGORITHM-R4-STATS-001，设计v1，ALGO-R4-STATS-BL-20261008-v1，54份输入＝14份原FIT seed/经验＋10份现有工具＋30份规则/设计/已交付证据。拟生成22份业务文件全部在独立r4_stats工作副本；该目录当前不存在，代码尚未生成。

先读[整体行为、交接和局部中文草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R4-STATS-001.md)B/C→D→E，再读[来源/消费者/容器预算](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-source-and-budget-v1.md)，然后读[独立验证和逐沿组合](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-validation-v1.md)，最后回看主卡G/H的文件与测试追踪。

软件范围为kind11/12/17/18的五项精确统计→现有FIT真实调用，独立参考/TB及四pin25MHz联合数学probe。先单测，再真实FIT组合，再物理与同源发布。必要检查通过后生成/登记bit/hex并停止硬件步骤；不将本小包定义成完整十一项完成。

## 2. 实际读取的来源与组合结论

- 本v1主卡全文及修订段、两个v1附稿实际读回；根AGENTS、控制面规则/提示词/配置、state/ledger、数据库README、模板、工作流及规范§10.3/10.4/11实际读取。规范已由本会话前续读全文，现行SHA仍为4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2。
- 原fit_protocol_pkg的REQ622/RESP585/check_request/pack_response、fit_core真实端口/quiet和原fit_reference INPUT_FIELDS/数值质量公式实际读取；原reset_sync保持两级异步断言/同步释放；R3/R4统计与POINT文本实际核对。原六RTL与fit_reference复用字节由冻结输入约束，原FIT已含唯一private scalar。
- 布局逐项相加：START84、POINT84、END84、NUM_ID176+op2+payload84=262；STAT为NUM622+outcome2+reason8=632；原FIT返回585与统计终态语义不同。成功才发NUM，n不足仍交FIT判LOCAL_COUNT，统计层不伪造LOCAL结果。
- LS槽0…4是A/B/C/D/F；TLS槽0…4是Sx/Sy/Sxx/Syy/Sxy，产品选择p0/p2/p1明确，include0也推进raw_seen与合法坐标历史。原POINT的非零梯度/合模1530是更强上游条件，局部typed试验允许零/每分量1020；不把这些试验称真实Canny输出。
- 源能暂停并保持单token；同ID有效ABORT先于本沿数学提交，旧首错保持。END接纳后旧最后点t+3提交、t+4离DRAIN、t+5形成STAT；关闭后≤6沿，外部stat_ready不参与排尾。
- 新raw_seen始终先u23再核u22适配；超容器恶意源进入PROTOCOL_STUCK而非回绕或假终态。有限源fault后兑现一个已公开token再关闭，因此正常合同不会到该容量边界。隔离helper与真实主核动态覆盖分别报告。
- 注册适配独立保存NUM622与一份共享response585；真正observer_fire之后才移位。原FIT quiet/stat quiet均真实确认；新job必须等585位观察done，held期间不复用旧身份或重写原响应。取消/reset与接受/消费/commit各自计账。
- 小LS例原质量是4δ/(A+C)²，A3/B0/C2得24/25而非1，当前草图已修正为RNE62914。全N对称LS A=C/B0仍是65535。用现有源码公式核对设计例，未执行新模型或业务原型。

上面是语义/边界/旧沿的设计分析，并不等于工具实际证明；字段存在和hash一致也不能自动证明算法正确。1024常规、固定非法与取消/复位、两全N及两全N稀疏扫描（每场2073600真实POINT）、真实原FIT返回、68probe观察及独立尾域两job全部是待执行义务。

## 3. 数量、容器和工程边界

stats逻辑容器1810bit、新probe1787bit、原FIT设计上界8955bit，联合12552bit。七stats态3bit、五source态3bit、六适配态声明4bit；quiet/fault/done/LED为已有状态组合，不暗加另一个上下文或结果队列。这是逻辑容器预算，不是综合FF或XLR。

联合验收拟定Ti60F225/I3、25MHz、XLR≤56000/RAM0/DSP≤32，正setup/hold、内部未约束/无clock/多clock0、实际非空Q→D报告及J2/P13/N14/P14引脚/PT电压/GCLK/驱动核对。该新范围预算不是调整旧FIT已批准50k预算，不证明全机资源/帧率。原六RTL保持字节，实际映射不足时须在相同边界内优化或重新呈现重大变更。

## 4. 冻结字节及实际核对

| 当前文件 | bytes / SHA256 |
|---|---|
| 主设计v1 | 32052 / CC6EE01BC6A4041A0D90C614F340C61C3695B1B2BF907402A646E0C50214ABC8 |
| 基线54份 | 见清单 / 76AB87E6045D4A829BFDD062A9B2302CDC114C5BC5A920488D71DCE4D9D43760 |

[冻结输入清单](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/01_baseline/algorithm-r4-stats-baseline-v1.json)于2026-10-08T05:51:44.108864Z保存，54项逐个实际bytes/SHA核对0漂移；14份已登记seed与当前原FIT工作文件也一致。旧FIT的244项artifacts/source/evidence逐个读回hash及bytes全一致，未重跑已通过且未改动的旧FIT仿真/EDA。

历史v0.1主稿18465B/SHA4AB1A8C0C4BECAD1E698CCD333CDF4E5CCED235FF6B104D199A6EC665E90E1FB独立保存，两个v0.1附稿保持。最终54项和本读回文件再核结果保存为r4-stats-design-readback-v1.json；本读回不放入自己的输入基线，避免循环hash。不能因为主卡早期文字写“拟冻结”而另创同名基线替代这里的实际54份。

## 5. 呈现、授权和停止点

本聊天已呈现本模块整体路径、局部/接口/语句阅读次序、22文件及实施验证范围。open_in_codex返回queued，只记录请求已排队，不冒称用户已看到侧栏。

最近用户“批准”与既有真实批准记录对应FIT v1，该批已实际交付；当前STATS没有指定批准。独立ANGLE v1.1和DDR模型联网批准也未由此得到授权。规范§10.4明确“默认需要用户明确批准指定版本与范围”，故当前只到READY，下一步需本v1及54输入/22文件/本批本地审计批准。

正式数据库仍NOT_CONFIGURED，FPGA_AGENT_DATABASE_URL未提供，H0/WAITING_FOR_HARDWARE_BASELINE未改；Approval Manifest及TASK_LEDGER未改。控制面设计写入/报告/追加档案沿现有许可，新的业务软件执行本地审计例外仍是REQUESTED。无业务目录、新RTL/TB/功能脚本、EDA、bit或硬件/网络/安装动作。

完整十一项余量继续包含ANGLE/投影、R4候选/支撑/去重与原场景质量、完整Canny精确滞后、DDR动态/帧服务、生产相机/HDMI/CDC/实时阈值/冻结/叠加、整包性能/资源/引脚与最终产物；本READINESS不冒当整包完成。
