# TRACK4-ALGORITHM-PERFORMANCE-001：完整1080p资源、访问量与生产可行性审计 v0.2

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本稿是整包的事实审计与求解路线，不是已经完成的物理架构、工具报告或实现授权。

## 通用计划字段

- Goal：保持完整1920×1080、精确八邻域Canny、圆及任意旋转矩形、三边推断、重叠/负样本和原独立P/R目标，核实当前对象容量、真实RAM模式、访问工作量、数值串行成本和1080p60显示供数。
- Current state：四份当前R4R/R4C/RAW/R3已实际全文读取；根规则、模板、需求/显示及纯资源报告已核；当前所有业务实现与工具证据未生成。
- Target state：形成真实板卡资源内的全机架构及有条件服务/周期证明，闭合所有owner、生命周期、源/显示边界和完整验证计划，再纳入整包指定版本批准。
- Gap：当前41,113,469B容器架构不能全部装入Ti60片上RAM；最新已允许板载DDR3，D5固定不alias分区可在已确认容量条件下消除纯容量障碍，但实际控制器/原子层/多slot目录与QoS未冻结；PC仍不是生产存储，完整同源RGB与FF/DSP/CDC/STA证据仍OPEN。
- Assumptions：只采用N=2073600/P=1036800的原完整范围；不新增采集或处理fps要求。100MHz、27MHz和25MHz均仅有预算/局部工程含义，不合并为已测全机时钟；DDR128bit@100MHz/DDR800和capture60均为来源参数或条件情景，不是实际效率/采集fps承诺。
- Open questions：A2。降标提案已经撤回，不使用160×120、128×96、单目标、无噪声或无遮挡测试替代原目标，不给场景重新加尺寸/数量/噪声/遮挡门。
- Dependencies：唯一根v0.2、当前R4R/R4C/R3/R2、CONTROL/VIEW/REPLAY、完整R5、板卡现有DDR资源/真实访问与文件套件；历史Flash路线仅在另选用时成为依赖。
- Milestones：整体边界→对象/生命周期→访问量→服务期限与视频→等价优化候选→物理架构冻结→独立审阅→指定整包批准→获批后实现、仿真、综合、PNR/STA及bit。
- Detailed steps / State transitions：设计审计READ_SOURCES→CAPACITY→WORKLOAD→SERVICE→COMPOSITION→OPEN_REPORT；生产架构未冻结，本文不会把审计状态写入正式运行状态。
- Artifacts and hashes：本轮只创建本文；A1绑定实际读取来源，本文最终SHA/bytes由保存后全文读回另报。
- Validation：G均NOT_RUN；静态整数核算与数学/协议/质量/网表/时序/实际存储验证分别给证据。
- Failure handling：容器溢出、主动搜索未完、数值局部拒绝、存储未知效果、视频欠载各自观察；不以慢重复帧、safe画面、CRC或host参考冒充处理成功。
- Human approval gates：纯文档授权；未READY，不请求未成熟实现批准。达到无当前设计阻塞后才指定版本/范围/共同基线呈现；原工作副本/构建/DB/人工硬件闸门继续。
- Rollback：只撤本文候选引用；不改原设计、HDK、规则、Manifest、数据库/正式状态。最新允许板卡现有DDR3，只读指定更新包证据；不新增外部存储模块，DDR业务/PHY修改/运行仍未获实现批准。
- Completion criteria：本轮保存、全文读回、独立审阅交接完成；完整业务完成另需真实全机实现和相应软件/资源/时序证据。批准前冻结架构和验证计划，获批后取工具证据，不建立“先实现才能批准”的循环。

## A. 状态、范围、实际来源与阻塞

任务ID TRACK4-ALGORITHM-PERFORMANCE-001；关联整包BAT-REQ01…06、R4/R5、A4/A5/A6及B4/B5。整体先读B/C，数值查D/E，再读F/G/H和A2/I。没有Git commit，不伪造。当前用户边界是：**允许使用板卡现有DDR3；实际生产存储只用板卡现有资源，不增加外接存储模块；PC仅仿真参考和观察，不当production工作存储。** 先前排除DDR的v0.1评估保留为历史；本文件已实际保存/读回该版SHA256 5DF6944ABA9DFA1ABE108F85214E83AAD63C99D94F50FE4B5CB63334B5D8FFE3 / 42371B，随后因最新授权同路径修为v0.2，未另建快照。用户没有批准业务实现、降低fps或改显示/识别范围。

### A1. 输入基线及采用边界

| 实际来源 | SHA256 / bytes / 本文用途 |
|---|---|
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；前序实际全文读取、本轮复核相同hash；设计/批准规范 |
| [模板](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79；本轮全文 |
| [R4R v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 / 83901；本轮全文，D7容量、E2…8循环、F资源/尺度 |
| [R4C v0.2](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 / 63263；本轮全文，D4真实台账及F全链上界 |
| [RAW v0.1](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 94F0327B10081903D4C034B136A46DD1B8962337C71F59FC357C9DACADD4D799 / 61325；本轮全文；历史PC arena/串口合同只用于软件/观察成本审计，最新用户边界禁止作为生产后端 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D / 51448；本轮全文，E2/E3/E6步骤界和E7容器 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 / 29268；前序全文、本轮定位；2ppc/28RAM/22000XLR均局部候选 |
| [R2 OBS](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md) | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 / 26753；前序全文、本轮实际hash与B/D定位；旧可暂停四pin观察器608bit/捕获+19处理沿，不是生产视频fps |
| [纯资源比较](../experiments/track4_algorithms_20261004/03_review/r4-closure-resource-comparison-v0.1.md) | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C / 7206；本轮全文，256RAM10及实际native模式 |
| [既有DISPLAY](design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 / 50145；本轮B、视频参数/带宽定位；只采用固定时序/数量，不继承原物理后端/旧162/174/225RAM预算 |
| [原赛题需求](../docs/requirements/TRACK4_REQUIREMENTS.md) | 3CA55B70E23488B4710345CEDE908D62A0A9113D4AC8454D6746E04BC4CD5DE2 / 11613；B1/B4/A1及解释边界2；采集/处理fps没有被规定为60 |
| 板说明txt | E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8 / 79766；reports/audit/environment_20260923/pdf_evidence/TI60F225I3-V4 DEMO板软硬件设计说明-260920.txt，第129–130、672–673行说明GD25LQ64、8MB、配置镜像及用户数据 |
| 更新板说明PDF（R_DDR/TI60F225I3-V4 DEMO板软硬件设计说明-260924.pdf） | 15800EEBCA75C067DE5CD68988A011A69A2976A7AA72B3315542DF6C8B258719 / 10574472；本代理核实际hash/bytes；独立协议代理实际阅读PDF24…26页（印刷23…25）：MT41J128M16JT-125、x16/2Gb、256MB/8bank、row14/col10/bank3、控制器最高800Mbps，不冒称本代理另读PDF全页 |
| R_DDR/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1/rtl/ddr3_controller/ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 / 972；本代理实际全文54行：bank3/row14/col10/DQ16、AXI_ID4/ADDR32/DATA128、tCK2500ps、CK_RATIO4/ASYN1 |
| 同目录ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A / 58209；本代理实际读1…155行public wrapper，52/53 axi/core100MHz、54sdram400MHz、AW/W/B/AR/R公开口，后续protected IP未解读/运行，不凭wrapper证明QoS/仿真/校准成功 |

R_DDR是D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新；全部只读。参数中的ADDR_WIDTH30/AXI_ADDR32不是额外物理容量，DRAM_WIDTH8也不能推翻实际DQ16及器件x16。bank3+row14+col10=27个word地址位，×2byte/word=268,435,456B=256MiB。tCK2500ps为400MHz CK、双沿800Mb/s×16=1.6GB/s nominal；ASYN_AXI_CLK1须真实CDC，公开端口未证明任意byte/窄burst均可或W/B完整效果已结清。

RAM模型DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33已前序实际读取；本轮采用同hash资源报告的几何证据，未运行原模型。Ti60 datasheet容量由资源报告及根/独立代理核实，不冒称本文另作PDF全页验证。控制面按入口读取，DB仍NOT_CONFIGURED；本文不登记审批或正式状态。新用户范围优先于旧RAW的PC存储提议，旧文件保持原字节。

### A2. 必须闭合的真实设计缺口

| OPEN | 影响 / 求解责任 |
|---|---|
| PERF-B01 | 板载DDR实际可用分区/访问/恢复合同及全机资源未冻结；A1已经确认名义几何容量，D5给固定容量候选。R5/存储设计者继续冻结AXI地址单位/clock/校准/刷新/服务和现有pin/约束；历史Flash型号/用户区/读写未成熟，但不选此路线时不构成当前DDR架构门槛。 |
| PERF-B02 | D5 DDR容量候选尚未接通当前逻辑S/O/provider、多slot/epoch/borrow及claim/DENSE原子控制；R4/R2/目录联合给实际容量、单writer、版本、终止与关闭。 |
| PERF-B03 | 完整同源RGB/EDGE/ANN的1080p60供数与不可暂停相机入口尚未闭合；R5必须给逐行最坏服务曲线/CDC，不以平均带宽或旧帧重复填补。 |
| PERF-B04 | 候选生成、radius路线、热表/cache/计算优化的实际profile与吞吐需冻结；派生POINT/程序ANN等非必要替代若采用须重证明bit/质量/错误/接口相容，原P/R95%/IoU0.5与场景不缩。 |
| PERF-B05 | 全机native bank/FF/XLR/DSP/PLL/同步器/packet/目录/观察副本与实际clock组合未分配；不继承旧225RAM或局部0DSP。 |
| PERF-B06 | 生产profile实值、每op微调度、NUM调用数、独立GT/文件/CASE/deadline/runner及完整验证基线未成熟；不自填fps/timeout当已通过。 |

当前确定结论是“BRAM-only现容器不fit；允许板载DDR后，D5候选物理84.25MiB可在256MiB名义容量内容纳，但原子/目录/资源/生产服务尚未证明”。不是“所有等价算法都必需41MB”，也不是对所有可能板卡资源内算法给出了不可能性定理。未解决以上设计缺口不能标READY或承诺原整包完成。

## B. 整体行为和比较边界

| REQ | 规则 / 可检查结果 |
|---|---|
| PERF-REQ01 | 原完整N/P、五基础/六高阶总映射保留，板载DDR资料调查许可已恢复，A3与整包真实设计/实现仍须冻结和指定批准；算法/显示目标不以撤回的低指标稿替代。 |
| REQ02 | 指定容器的逻辑bytes、物理native bank、元数据FF和生命周期分别记，不把host数组、压缩猜测或旧资源总数当片上证据。 |
| REQ03 | FP/CLASS/GRAD、logical S/OBJ、raw byte访问、NUM、实际wire分别计真实事件；request接受不等效果完成，各失败前缀不强相等。 |
| REQ04 | 无新增场景门；启发式预算/容器容量/质量目标/处理延迟分开。SEARCH_INCOMPLETE不能发布前缀，负样本/重叠和失败FN继续计。 |
| REQ05 | f_capture、f_algorithm、f_display独立；只固定现行显示1080p60，不自设算法1fps、60fps或采集下限。 |
| REQ06 | 只用板卡已有资源，包括最新允许的DDR3；PC仅参考/观察，不新增外接存储。DDR/Flash任何路线须真实容量、访问、保护/恢复和吞吐证明。 |
| REQ07 | 等价共享/重算/程序ANN须保留全部N、身份/精确数学/同帧关系/真实提交与关闭；引用归还前不覆盖旧图。 |
| REQ08 | 实际全core、防裁剪、仿真/数学/质量/PNR/STA/bit分别取证；原参考/正式状态不变，bit之后步骤不在本次执行范围。 |

系统输出必须能区分完整结果、失败、未完成、重复旧完整图、视频欠载和未知关闭。HDMI60Hz允许慢结果重复，同一重复扫描仍须及时读取相同完整SRC及对应EDGE/ANN；重复帧不能消除存储读带宽。显示mode0偶行两遍是视图，不减少算法1080行。

正常审计样例：一帧全量源→完整Canny→识别→精确去重→完整结果，分别填各层工作量和每个真实对象持有区间。边界：E0不意味着没有N个输入检查、全N输出或固定视频扫描；K=N容器仍要真实队列结束；任意慢观察器可反压逻辑试验，但生产HDMI不得因此暂停时序。失败：容量错误/预算未完/Flash未知效果不能被零图或safe视频记为成功。

## C. 职责、路径与owner

| MOD | 审计职责 / 真正数据owner / 未负责内容 |
|---|---|
| PERF-O | 对象/生命周期账本设计；真正分配与退休仍O，本文不创建对象或许可。 |
| PERF-W | 各stage计数/工作量审计；实际游标和计数仍R4C/R4R/C0，不从结果字段反造期望。 |
| PERF-S | 服务延迟/带宽需求与原子代价；真正effect/commit/close仍存储控制器，DDR物理接口也须新的原子/授权层；Flash不是自动满足旧raw WRITE的RAM。 |
| PERF-N | R3微步骤/宽算术成本；R3唯一caller和held/quiet保持，不新增隐藏并行owner。 |
| PERF-V | 固定视频和源/plane实时边界；实际ROW/CDC/serializer/R5负责，不复用旧物理消息。 |
| PERF-Q | 独立数学/协议/质量/资源验证计划；PC可以生成黄金和观察，不能替FPGA计算或生产存储。 |

数据/配置路径：完整SRC/CFG→R2分类/GRAD→精确闭包→识别provider→候选/拟合/最终诊断→精确去重→ANN/record或经审阅的程序视图→同帧bundle→固定显示。错误与cancel独立汇入真实关闭；对象退休只在真实全部reader/pending/held义务结清后发生，不能靠性能阶段名清引用。

本稿没有新增业务module或端口实现；D的IF是跨设计审计交接，不能被当成已连通RTL。整体检查点是现全容器不能放BRAM、D5板载DDR容量候选成立但真实后端/原子/目录/视频仍OPEN；不能先写一个常量小top当全机证明。

## D. 接口、容量和组合检查

### D1. 五个审计交接

| IF | 提供方→使用方 / 内容、单位和来源 | 前提、保证及未知 |
|---|---|---|
| PERF-IF01 OBJECT_LIFETIME | R4/O→审计：object/ref/version/owner、items/record_bits、valid_count、birth/last-use/commit/真实return；ref/version为各原64bit族，数量用原21/22等类型 | 不由裸同宽ref或阶段切换推授权；alias提议必须真实last-use和返回，不与旧borrow重叠。 |
| IF02 WORK_TRACE | C0/LC/CL/RC/NUM/STORE→审计：原接口fire、op/purpose/seq、实际effects、独立prefix；序号/总台账64bit，像素计数沿原族 | expected identity在发布前冻结；坏echo raw计但不结credit，不能从term status0推导真实访问次数。B等派生值只从独立trace算，不加隐藏硬件term字段。 |
| IF03 SERVICE_CURVE | backend/R5→审计：读/写/提交/close的最大服务间隔、持续有效B/s、首项延迟、burst/竞争和CDC条件 | 当前DDR/Flash/全机曲线未知；nominal wire rate或平均值不能满足逐行deadline。永久notready只检查保持，成功墙钟上界须有限服务及消费前提。 |
| IF04 RESOURCE_MAP | 各实现职责→审计：native RAM宽深/数量/端口、FF容器、DSP操作配置、clock/pin/CDC和hierarchy | 当前仅设计容量；实际工具结果获批后填。XLR预算、FF bits和逻辑bytes不同单位，不直接相加成利用率。 |
| IF05 BOARD_DDR_SERVICE | 新typed原子层/O/R5→审计：256MiB物理range、D5固定分区、AXI32byte地址/128data/4ID的适配、真实AW/W/B与AR/R/effect/close、有限QoS | 公开wrapper不创建typed原子性/对象权限；多slot来源/授权/borrow真实合并、WSTRB/完整写与未知债务、校准/refresh/ASYN1/取消须独立局部冻结。 |

软件分析中的乘法/总工作量使用精确非负整数；RTL计数沿原接口64/65bit或21/22bit，不把N次访存总量窄为像素21bit。IF03秒/拍/Bps互换须带真实clock和服务前提。配置/profile只在原job接纳快照生效，审计不能修改正在运行的scene或budget。

### D2. 当前完整逻辑容量

R4R D7各表按ceil(items×bits/8)分别计；分组复核如下，任何未证明别名都仍单独分配：

| 容器组 | byte |
|---|---:|
| POINT N×64 | 16,588,800 |
| ANCHOR/SEED | 6,144 + 4,096 |
| HIST/RAW+SMOOTH | 21,504 + 8,192 |
| DENSE/NMS/LINE | 11,634 + 2,909 + 8,192 |
| 两CELL/EXT/SEG/PAIR | 49,152 + 40,960 + 49,152 + 4,096 |
| CIRC/RECT/VC | 32,768 + 65,536 + 102,400 |
| COVER/COVER_META/FINAL/DRAW | 2,048 + 160 + 4,096 + 640 |
| CIRCLE_CTX/FIT_STATS | 768 + 526 |
| ANN/RECORD | 518,400 + 4,096 |
| R4R合计 | **17,526,269** |
| 加GRAD/SRC/finalEDGE | 8,294,400 + 6,220,800 + 259,200 |
| 上述识别及源/结果合计 | **32,300,669** |
| 再加闭包CLASS/QUEUE（EDGE共用一次） | 518,400 + 8,294,400 |
| 保守单slot数据合计 | **41,113,469** |

这些不含对齐、配置/历史profile、目录/pin/journal、local pending、480B ROW、字体ROM、R3或多副本。RAW旧64MiB实例再加guard/64对象最坏对齐/一个profile为41,183,165B，只是旧软件arena候选的算术；用户现已禁止PC承担生产工作存储，不能沿用这个余额解决PERF-B01。

Ti60名义320KiB=327680B；41,113,469B是其125.46835倍。即使按全部10Kbit满容量无端口限制排入，现整组至少32120个RAM10；只R4R表至少13693个。这里是**指定容器布局**的容量下界，不是任意等价识别/Canny算法的信息论下界。

### D3. 原生BRAM模式与资源未分配处

实际EFX_RAM10一读一写；1/2/4/8/16族每块8192有效bit，5/10/20族10240bit。跨族读写宽度不兼容，同址读写行为未定义；20bit读不能直接以1bit写，packed bit更新须RMW/latest/仲裁。

| 大对象 | 满10Kbit容量块数下界 | 常规native组织 / 块数 |
|---|---:|---|
| 原SRC24N | 4860 | R/G/B各1024×8平面，6075 |
| GRAD32N | 6480 | 两512×16银行，8100 |
| POINT64N | 12960 | 四512×16银行，16200 |
| CLASS2N | 405 | 4096×2，507 |
| QUEUE32N | 6480 | 两512×16，8100 |
| EDGE N | 203 | 8192×1，254 |
| ANN2N | 405 | 4096×2，507 |
| 七大对象合计 | 31793 | 39743，尚未含其余表/控制 |

FRAME数据不能因为下界大而放进FF；目前也没有把任何全N数组分配为Ti60 FF的合法预算。现有局部候选：R2窗口28RAM/≤22000XLR/0DSP目标；R3为2ROM RAM/5732bit容器、DSP未冻结；RAW历史metadata/journal/packet11RAM；FONT1RAM。ROW若采用独立4096×2可提议1RAM，组合为43RAM只是这些小单元的候选，不含任何全图存储，且新生产架构不必继承RAW全部观察复制。

RAW声明的per-client13368bit、CORE镜像9516bit、nextseq520bit、FIRST_ERR930bit，加R3 5732bit容器为30066bit；R4R列出的RJ/NUM/OBJ/CLOSE/FINAL_NOTICE/TERM独立slot另8771bit。以上是已声明容器容量审计，不是综合网表FF总数；还有RAW单口3422bit级slot/ledger、目录回读640+512、old bytes、group metadata、R4局部宽乘/统计/游标、C0/CONTROL/VIEW/CDC等。echo可引用已pin快照时须先证明生命周期，不能悄悄删副本以宣称fit。

DENSE的parallel16只是32个12×17逻辑乘容器、16票组；没有冻结为32个硬DSP或16物理读口。R3的16×16部分积也没有证明占一个DSP。全机FF/XLR/DSP/PLL及实际I3/C4、core25/27/100MHz组合仍PERF-B05；不继承旧225RAM、32DSP或29168FF值。

### D4. 同时存活与合法复用

保守41MB是来源D7/RAW的无alias审计，不说明所有对象在算法上必须从头同时存活。可审阅的释放点：

- CLASS/QUEUE：CL_TERM完整成功、真实storage close、活动pop/held/read/latest全部关闭，并由O核最后reader/独占pin真实返还后，可在识别前退休；不以CL_TERM消费等于free。
- GRAD：POINT已经完整commit，POINT64实际保存全部后续所需Gx/Gy/dir/θ/x/y，确认无未来GRAD reader且真实归还后，可退休。POINT改为派生provider时这条释放点随之失效。
- ANCHOR/SEED/HIST/峰/圆ctx：全部被选圆路线结束、NUM/OBJ关闭且CIRC不再引用可变表后可返回；DENSE/NMS→CELL→EXT的精确last-use可提议复用热表bank。
- POINT：冻结核验、coverage、精确support去重全部结束才最后读取；FINAL sealed后ANN/RECORD仅靠几何绘制，可在真实return后退休POINT。
- CIRC/RECT/VC/SEG/PAIR等：所有最终选择和diagnostic完成且FINAL已完整copy后再退休；不把中途prefix当最终集合。
- 原SRC/finalEDGE/ANN/RECORD/profile：完整bundle及历史/显示borrow仍持有时不可覆盖；单slot不能借“开始下一stage”隐开第二帧。

只提前退休CLASS/QUEUE可把当前识别阶段保守量降为32,300,669B；再按上述真实证据退休GRAD为24,006,269B，仍远超BRAM。源与输出SRC/EDGE/ANN/64RECORD/一个PROFILE本身约7,002,624B，说明lifetime小优化不能关闭BRAM-only源/显示缺口；DDR容量候选另见D5。后者也仅是当前持久平面选择，不否定程序ANN等新等价结构。

### D5. 最新允许板载DDR后的固定不alias容量候选

本稿采用下表作为可审阅的**保守容量候选**，不是已经吸收多slot的CONTROL/VIEW/RC端口。数据对象仍使用当前canonical bytes，不把PC arena或旧物理job/key消息继承为生产接口。板载256MiB/2Gb容量、bank3/row14/col10/DQ16及128bit@100MHz/DDR800已由A1新实际参数/公开口/独立PDF页证据绑定；这些是名义几何/clock，未运行控制器验证。生产半开分区拟[0,0x08000000)，另[0x08000000,0x10000000)128MiB暂不授权普通对象，不能据“留有余量”匿名使用。

| 对象 / 数量 | 每槽logical B | 每槽physical B / pad B | 全组physical半开地址 | 授权与寿命 |
|---|---:|---:|---|---|
| SRC×6 | RGB6,220,800+PROFILE128=6,220,928 | 8,388,608 / 2,167,680 | [0x00000000,0x03000000)，slot i base=i×0x00800000 | capture仅独占BUILD槽，完整帧/配置真实提交后immutable；SRC/profile不因显示或处理启动覆写。 |
| EDGE×3 | 259,200 | 262,144 / 2,944 | [0x03000000,0x030C0000)，slot i base=0x03000000+i×0x00040000 | 仅本closure writer，全N显式0/1、commit与close齐全后bundle/replay reader。 |
| ANN×3 | 518,400 | 524,288 / 5,888 | [0x030C0000,0x03240000)，slot i base=0x030C0000+i×0x00080000 | 仅本RC writer，全N提交后同source/result/render借用；不能裸ref当ANN资格。 |
| GRAD×1 | 8,294,400 | 8,388,608 / 94,208 | [0x03240000,0x03A40000) | 全N收集/封存，POINT最后读及真实return后才能重建。 |
| CLASS×1 | 518,400 | 1,048,576 / 530,176 | [0x03A40000,0x03B40000) | LOAD→精确闭包可变CLASS单writer/latest；未settled/close/return不重建。 |
| QUEUE×1 | 8,294,400 | 8,388,608 / 94,208 | [0x03B40000,0x04340000) | N完整容器，claim+append与tail提交原子，不用小FIFO替代；同CLASS私有life。 |
| POINT×1 | 16,588,800 | 16,777,216 / 188,416 | [0x04340000,0x05340000) | 完整E前缀/COMMIT后immutable，最终coverage/dedup最后读前不回收。 |
| RC_AUX×1 | 私有414,973+3×RECORD4096=427,261 | 1,048,576 / 621,315 | [0x05340000,0x05440000) | 23个私有表按原typed schema；三RECORD各有独立bundle owner，私有阶段归还不能清历史RECORD。 |
| 合计 | **73,781,629** | **88,342,528=84.25MiB / 14,560,899** | [0,0x05440000) | 只一套GRAD/CLASS/QUEUE/POINT和RC私有build，不隐开第二处理job。 |

128MiB生产区余45,875,200B=43.75MiB，名义256MiB板容量另有128MiB保留。这里没有alias或动态压缩。地址之间没有重叠，但对象访问只允许logical长度/有效record；padding不是任意访存区，不能外部改写相邻槽。base0仅为经过新O验证的候选地址，不继承旧PC raw guard=64KiB或addr26语义。slot count6/3来自根容量提议，不是当前接口已经支持，需显式合并source/result/display/borrow身份、忙槽丢帧政策、epoch/highwater以及真实返回。

RC419,069精确等于17,526,269−POINT16,588,800−ANN518,400：含一份RECORD4096，所以原单份AUX逻辑是419,069，三bundle增加8192后为427,261；其中其余414,973为R4R现23表，含COVER_META160、DRAW640、CIRCLE_CTX768、FIT_STATS526等**算法容器**。它不包含真实O目录/borrow/pin/journal/控制snapshot、ECC/CRC/CDC/FIFO、源/结果证书等通用metadata。三RECORD须在AUX内另分不覆盖的三4096B段、与各bundle独立关联；真实private_refs_retired不得退休这三persistent RECORD。逐对象64B对齐、guard、控制保留区及版本表仍须独立layout/容量，不能把未分配pad自动说成已容纳。

新总线body地址建议32bit，实际物理规范值限定高4bit零/低28bit；half-open物理末端至少29bit、32bit body加length先33bit计算，不先窄到28bit。对128MiB当前授权区额外核end≤0x08000000，对整256MiB地址end≤0x10000000。向AXI32适配须按实际byte/beat单位证明，不盲cast旧26bit；index×record_bits及base+offset+len先足宽、检查对象/role/version/initialized/commit再发物理请求。真实AW/W/B、AR/R、burst边界、WSTRB、write完整效果、wrong-ID和取消/独立close/unknown债务另由新原子层冻结，本稿不制造已有服务。64B逻辑请求若首byte不16B对齐最多覆盖5个16B beat，不能固定成4beat；typed/raw caller只授权真实logical请求bytes，物理整beat扩展读须另核保护范围，不能外泄相邻对象或尾padding。若采用窄WSTRB，须有真实IP支持证据且只置合法请求byte的strobe；若采用全WSTRB读改写，adapter必须另取得覆盖rounded 16B拍、且已初始化的同对象physical/padding权限及整组排他，保留所有非请求byte，不跨另一个子对象/槽或越immutable权限。该物理策略另版冻结，当前不声称IP已支持或adapter已有这项权限；物理不可读尾部不能偷读。源bytes与真实副作用范围分别精确记账，整拍已发不等整拍效果已结清，UNKNOWN不得伪造logical字节前缀或源内容保持证明。槽/子对象各有独立ref/version与logical授权：SRC的RGB及PROFILE两个实体、AUX各23私有表与三RECORD分别登记，不能把退休整个AUX当返回三历史RECORD。

无条件“容量障碍已彻底消失”也不正确：这是当前对象与保守多槽的DDR容量可行性，不是BRAM/FF/DSP、持续供数、calibration/刷新/恢复、生产camera/HDMI/QoS或算法质量已通过。先不alias便可将容量问题转为可审阅的owner/物理适配与吞吐问题，无须为了容量而删POINT/GRAD/完整ANN。

## E. 工作量、服务合同与中文求解草图

### E1. 计数符号、层次与固定/启发式边界

N/P固定；E为实际POINT数≤N；S为强种子；K为成功claim/pop数≤N；B为真实合法邻居READ_CLASS次数≤8K。B从未来独立trace派生，不新增term字段。A≤768 anchors；C_s≤256入选圆中心；L≤1024LINE；G≤1024SEG；P_r≤512PAIR；Q≤2048VC；F≤64FINAL。

圆每中心RAW/SMOOTH各≤512；b_s=ceil(raw_s/16)+ceil(smooth_s/16)≤64。容量达到后产生下一实际条目即CAPACITY；这些不是输入目标数量限制。rect_verify_attempt_cap合法1…8191，具体生产值未冻结；还有合法未评估候选就SEARCH_INCOMPLETE，不将截断预算写成成功速度优化。anchors/rank/peak筛选是算法启发式，会产生FN，质量仍由独立GT两类P/R95%和同类IoU0.5最大基数一对一验证。

### E2. 各阶段对logical backend与NUM的工作量

下表不把一logical op、一次raw访问、一次算法比较或一时钟沿互称。表内主项之外的canonical检查/SEAL/上下文读写/排序/目录/close另记M_i；M_i的具体op级展开仍须局部文件冻结，不能默认0。

| stage | logical数据/效果数量或保守表达式 | 尚须明确的访问/计算成本 |
|---|---|---|
| 输入/R2/收集 | 完整N RGB，P CLASS/必要P GRADpair；CLASS LOAD为P操作加一个COMMIT；GRAD32N需8,294,400B真实封存 | SOURCE bootstrap及GRAD collector body/packing/生产服务未闭合；C0真实CS不能代存储commit。 |
| GENERAL闭包 | closure request=2N+2K+B+P+3；load另P+1；全链≤13N+4=26,956,804 | N种子读、K总claim、K队列读、B邻居读、N导出读、P EDGE写与真实三commit；CLAIM state+queue原子不计成一个物理RAM写。 |
| 两快路径 | NO_STRONG closure=P+1；NO_WEAK closure=N+P+1；load仍P+1 | 仍全N/P导出及真close；无BFS不表示整job无存储。 |
| POINT构造 | N EDGE读+N GRAD读、E POINT写+1POINTcommit；E次kind8；后续每遍E条immutable POINT | 所有N GRADcanonical仍检查；EDGE0不允许读洞/少检查，θ及真实record写/NUM成本另计。 |
| anchor/seed | E个输入点；anchor pair≤A(A−1)/2=294528；选最小256distinct | 全pair都处理；若线性扫描SEED，最多256项/pair访问只是一个可实现候选，排序/去重调度未冻结，不假设一个cycle查全表。 |
| radius hist | 16C_s全E POINT遍、16C_s个CLEAR；16C_s×8192 bin读；hist投票≤C_sE | CLEAR一个typed op须实际逐byte/bin效果；当前按16tile重复算同center距离，最多4096次全POINT遍；峰写/halo/SEAL另计。 |
| 圆五遍 | POINT主项≤5EΣb_s≤81920E；lane判定≤5EΣ(raw_s+smooth_s) | 同批16lane可以共享POINT读取，但不是免费16算术；最近peak查询/LS/距离/径向角/最终kind17和ctx访问M_circle另列。 |
| DENSE | 32E POINT读、32E个DENSE_ADD16组、512E个21bit票更新；32CLEAR，512系数kind16 | 每组16真实RMW；NMS及θwrap/四快照/LINE效果另计；没有gradient halo省掉原全θ票。 |
| coarse段 | 49offset投票/活峰筛选、两CELL/run读写 | 若每LINE先1遍offset计数、再每2活offset一遍POINT，a_l≤25，则候选主项EΣ[1+ceil(a_l/2)]≤14336E；这不是已冻结微调度，CELL/submask/排序访问仍M_coarse。 |
| 六遍TLS | POINT主项≤6GE≤6144E；每有效段三次kind12 | EXT真实clear/RMW/run选择、各成员谓词/距离/端点恢复另计；第6遍不第三次扩展。 |
| 矩形组装/核验 | SEG pairs≤523776；PAIR pairs≤130816，PAIR×SEG三边≤524288；实际核验D≤8191，各D完整E遍 | 门前扫描仍须证明无剩余合法未评估候选；每点四finite N/D/q及exact nearest/normal，最终四kind18/coverage另计。 |
| VC再核验/排序/去重 | Q次冻结POINT遍；直接选择扫描可≤Q²记录读；同类geometry后exact support比较至多64Q个POINT遍 | 最坏131072E条POINT读只是保守工作量；不能按bbox重叠删真目标，实际通过geometry的对数单列。 |
| ANN/RECORD | H次ROW clear、N ANN写+COMMIT、64 RECORD写+COMMIT；几何/label合并局部ROW RMW | 粗略四侧逐bbox遍历上界4FN+35×4×scale²F绘制检查/事件，scale≤15；精确行区间路线可少得多，但需逐式调度/容量证明。 |
| 全机终结 | 各角色独立CLOSE/实际台账、NUM quiet、O returns/private retire、VIEW/borrow归还 | 不因计数公式满足就假造close；错echo保留credit，失败/Q不要求补完整N。 |

最坏尺度不是常用图像预测：E=N时圆五遍主项169,869,312,000条POINT读；六遍TLS12,740,198,400条；去重保守主项271,790,899,200条。它们是当前有限循环政策的上界表达式，可能因早局部拒绝/容量错误少执行；不把理论极值当已观察到的production行为，也不把少测难例当优化。

### E3. 硬件周期表达式与未闭合部分

给每种logical操作实际raw读写次数r_o/w_o、每个raw服务上界L_raw(op,length,竞争)、每个NUM种类上界L_num(k)、本地控制/搬运拍数C_local及观察阻塞C_obs。仅当服务/消费都有限且局部FSM已经冻结时，可建立保守串行上界：

C_success ≤ C_local + Σ_o m_o[r_o L_read + w_o L_write + L_meta,o] + Σ_k n_k L_num(k) + C_obs + C_bounded_stall。

m_o来自E2或真实trace；n_k不是“点数”等于“NUM次数”，须每个谓词逐式数清。允许重叠时这仍可作保守求和预算，不能把各项重复计成实测。没有有限backend/消费者ready前提时成功墙钟无上界；10s raw期限只会生成失败/unknown，不能保证完整算法在某期限成功。

R3当前MUL有144个16×16部分积及24word；DIV最多192位步骤，SQRT最多96组；ANGLE最多8次比较，每次三word预约/次沿capture；finite exact q最多19个bit决策。还要符号、检查、round、搬运、ROM/pending、发布/消费沿。它们不是144/192/96沿的完整调用延迟；结果stall和single caller真实计入。复合LS/TLS/finite的scalar子操作数/微周期未冻结，不能写一个伪精确全帧fps。

旧R2 OBS可暂停四pin路径单K每record捕获1+CRC19=20沿；CLASS=P且retain_grad1/GRAD=P时仅数据记录至少40P=41,472,000沿，100MHz0.41472s、25MHz1.65888s，另有STATUS/控制/源bubble；retain_grad0仍20P=20,736,000沿。它是该调试观察合同的条件成本，不是任何等价FPGA算法的必然下界。DDR完整SRC与capture解耦可保留实时入口/显示，但沿用该K会限制处理速率；生产非阻塞observer候选须另冻完整terminal/error独立槽、按帧身份CRC/schema/GE记录或可观察FIFOoverrun、诊断不改effects及防裁剪，不能静默删原K或强称新旧schema相同。

DENSE E=N时有66,355,200组、1,061,683,200票。若单1R1W池串行，每票即使理想仅占一个更新沿，100MHz下也10.616832s，27MHz下39.3216s；同步读/RMW/NUM/POINT/接口会增加。并行16也不是省掉32E遍或全部服务；此数字说明当前昂贵主路径不能据“显示60Hz”宣称识别60fps，用户又未提出算法必须60fps，所以应报告实际延迟/处理速率并继续优化，不擅降目标。

### E4. 历史串口的证据边界

RAW94F使用新8N1提议/115200、固定RQ99wireB+RSP101wireB、单credit。nominal11520wireB/s；即使每访问用满64B payload，理想有效至多3686.4B/s，未计host/CRC/停顿。SRC一次至少1687.5s=28.125min；POINT一次至少4500s=75min。

逐POINT8B/小21bitRMW会更慢。条件性无cache DENSE实现每组16READ+16WRITE，32E组即1024E raw请求，E=N理想已36,864,000s约426.67天；这是明确无cache、固定packet、单credit基线的算例，不是任何缓存实现的不可突破下界。CORE OUT404每pair一98wireB packet，仅P个观察输出理想8820s=147min；算法/raw共享另加。

最新用户已禁止PC作为production工作存储；这些数只用于参考/观察链路的可执行性/deadline计划，不再列为解决R4/R5实际存储的方案。fast本域仿真可验证协议/数学，不能冒充真实串口或真实板内存储性能。

### E5. 1080p60固定视频的必要供数

采用既有DISPLAY纯时序：2200×1125、pixel148.5MHz/pair74.25MHz；每帧N有效pixel/P有效pair，总1,237,500pair周期。每行总14.8148148µs，有效段12.9292929µs。

RGB888每frame6,220,800B，60次扫描为373,248,000B/s=373.248MB/s；最坏SRC+EDGE1+ANN2共27bit/pixel，行6480B，平均419,904,000B/s=419.904MB/s。旧DISPLAY候选100MHz基本组装已1248沿=12.48µs，只余约2.3348148µs容纳其它服务；本稿不继承该物理实现或拿乐观下界证明deadline。

419.904MB/s相对旧UART理想raw payload为113906.25倍。慢算法结果可以重复，却仍每60Hz扫描重读原图；没有完整原RGB resident/压缩最坏上界/合法新显示架构时不能解决供数。程序ANN可省2bit plane读，原RGB alone仍373.248MB/s。

相机不可暂停入口另需真实服务/CDC/FIFO证明。任一FIFO必须满足sup_t(累计入−累计出)≤真实容量及明确完整帧接纳/丢弃政策；不能用可暂停仿真源的ready反压外部相机，也不能在未授权中把采集调到某低fps以假定满足。

### E6. 历史noDDR评估：板载GD25LQ64候选的容量与瓶颈

以下保留v0.1排除DDR时的事实审计；最新生产候选优先D5板载DDR，本文不要求改为Flash。板说明明确8MB/GD25LQ64/FPGA镜像及用户数据。将64Mbit按8MiB=8,388,608B核算只作待核型号容量候选，不把板说明“8MB”当全部空闲用户区。原SRC6,220,800B后剩2,167,808B；当前SRC/EDGE/ANN/RECORD/一PROFILE7,002,624B后剩1,385,984B，均未扣配置镜像、保护/对齐/恢复元数据。POINT64N单独16,588,800B已大于整Flash。BRAM+全Flash也小于现41MB容器；不能用二者相加证明旧方案fit。

本地没有找到独立GD25LQ64 datasheet，本文不伪造实际最大SCK、读dummy、地址/QE模式、page/sector大小、program/erase期限、耐久或已接通用户接口。Flash不能直接被当成旧RAM byte WRITE任意覆盖服务；需核具体program/erase语义、配置保护、掉电/复位/部分效果、持续写入与相机接纳、真实CLOSE。本稿不授权擦写或给现有Flash拍板为生产后端。

若数据阶段只4bit/SCK的quad SDR连续读，原RGB1080p60的必要SCK至少746.496MHz，27bit/pixel路线至少839.808MHz；若假设每沿双倍数据，分别仍需373.248/419.904MHz，且模式是否存在/接线/时序未证。数字未计command/address/dummy/间隙/随机读/争用，**没有本地资料、PHY或STA证据支持这条必要供数路径**。因此“8MB能装源”不等于“Flash能供当前同帧原RGB HDMI重放”。

Flash作为非实时、可重复immutable原源的候选，可降低外部数组依赖，但须先核合法空闲用户区、真实读回及重复同值/身份；写入一次后重复读不等于已经满足相机采集/完整视频。输入不可无损保证压缩到某固定小容量，不把自然图像压缩率假设成场景允许边界。

### E7. 不改变输入场景/质量的优化方向与代价

下列是候选求解路线，不是已批准替代主稿；每项须同步原接口/错误/trace及独立逐bit/GT验证。

1. **真实lifetime复用。** 按D4实际return后共享bank/arena；先给birth/last-use/pending/borrow的表和无重叠证明。关闭会话pin不等目录退休，未消费held终态/响应可能仍引用旧数据。
2. **精确扫描替N队列。** A从strong初始化，重算/重放同immutableSRC+CFG的完整候选class；每完整遍只作0→1、最新值不丢，完整changed0才固定点，结果与八邻域BFS相等。可用一Nbit接受图，满20bitpacking至少203bank；仍需真实class重放/重算、RMW/close与全部N导出。最坏N²=4,299,816,960,000pixel访问，100MHz理想约11.94小时，不能固定若干轮。A203+旧R2窗口28已经231，控制/数值/显示/识别仍要空间；它不是完整全机fit。
3. **GRAD/POINT派生流。** 从同SRC/profile完整滤波重新生成G及finalEDGE选择，按原rowmajor重新建立ordinal和相同θ；取消、完整遍计数/EOF/版本/零G错误不变。可不保留全GRAD或POINT数组，但每个识别遍从E条变为N输入重算，SRC持有更久、Flash读回/算术次数增加；immutable POINT_COMMIT/provider合同必须重设计，不能直接把live tap叫重放。
4. **阶段热表放BRAM。** 当前HIST21若存32bit容器需32native块；DENSE按全4432项32bit串行存共18native块，但不含16独立lane读口（每lane保守32bit时另需32块）；NMS6、两CELL48共48、EXT80共40。可在真实阶段返回后研究热池复用，circle峰两512×64另8块、ctx/stats另计；不是总和全放，也不是已分配48bank pool。SEG/VC/候选表仍要真实存储或确定性再生选择，不能截断成功。
5. **复算替全候选持久表。** 重现同固定anchor/rank/loop/profile，重复生成候选来做全局确定排序/精确dedup，可研究只留FINAL/一个best。必须保持proposal顺序/tie、原预算/capacity/SEARCH_INCOMPLETE、最终kind17/18及全部候选评估，不能把topK局部前缀当原算法完成。多遍/NUM成本可能更高，设计未冻。
6. **程序ANN。** 冻结geometry/FONT/render快照后按每显示坐标计算原ANN分类，可研究移除全N ANN存储。须与现annulus/capsule/label/冲突规则逐pixel相同、同版本/held输出，并重设计VIEW的完整ANN资格/commit与逐行服务；不能用geometry ref自填原ANN token。固定视频deadline和原SRC读瓶颈仍存在。
7. **精确计算/访问优化。** 同center距离复用、sorted peak二分/缓存、同POINT多lane共享、DENSE各θ真bank/latest、fullword合并写、按有证明的typed宽度缩短scalar高零digit、常量K/clip复用，可保持数学结果；NUM owner/guard/取消仍唯一。finite nearest先比较四个N/D，仅对选中侧求exact q，可能省三次根；需新增明确数值接口及与kind15原结果逐式等价，不擅改旧kind19非法编码。
8. **视频路径重设计。** 只有原RGB replay服务、完整同源身份和相机/显示时间关系被重新证明后才替旧平面结构。live新帧RGB叠旧几何、只看safe/彩条、缩图、固定合成SRC或降低HDMI刷新均不是当前原目标的等价完成。

### E8. 中文逐步求解与最终停止点

先在旧量表上划出生/最后读/实际return，画一条完整一帧路径→选单一生产架构（板内、允许现有DDR、无PC存储/外接存储）→逐个对象给真实物理位置或可证明派生provider→给bitpacking/端口/同址/atomic/commit/close和非法/取消分支→给每stage的m_o/n_k、微调度/有限服务前提→给视频逐行deadline及相机不可暂停容量证明→与R3/R2/CONTROL/VIEW重新组合→独立审阅/完整GT与文件验证计划→无当前阻塞时再呈现指定版本批准。

一条合法优化事件：旧CL真正closed且无后续reader→O实际退休CLASS/QUEUE→下一stage才重用相同bank；同沿旧replyfire/cancel先登记，不能用新“free”抹旧交付。派生POINT最后读未完成或已有borrow时保持源，重算不同profile/版本拒绝。Flash错误/unknown不得返回旧RAM的成功commit；独立收尾无证明就Q，不凭安静/timeout解除引用。

现停止在设计审计交付。没有实际资源/服务闭合，不能从“某小缓存能装下”跳到全机实现，也不能借旧RAW将PC重新引入生产范围。

### E9. 允许DDR后的非串口服务与具体数学不变提速候选

**DDR工作模型。** AXI128bit@100MHz与物理x16 DDR800都仅给nominal1.6GB/s。设实际总持续有效效率η、capture fps=f_c、其它后台B_other，固定显示最坏B_disp=419,904,000B/s；必要平均算法余量β=η×1,600,000,000−6,220,800f_c−B_disp−B_other>0。f_c=60仅一个条件情景：capture+display=793,152,000B/s，必要η>49.572%，未计算法/refresh/rowmiss/turnaround/校准空窗。不能从这个平均数推出逐行deadline或用户新增60fps采集指标；必须给高优先视频/采集与有限算法份额的最大服务间隔，不让算法饿死。

POINT8B两个record可合一16B beat；每完整遍有效8E字节，实际至少ceil(E/2)个16B数据beat，加burst/检查/pending；random CLASS/队列/DENSE小record一次logical访问可能付一整16B读及16B写，需cache/packing/latest，不能按logical2bit宣称DDR只搬2bit。R4C真实台账沿E2，不计成恰好13N个AXIbeat。typical周期不自填E比例或候选平均数：以冻结profile和独立GT的实际E、C_s、raw_s/smooth_s、L、G、D、Q及NUM/typed/physical trace带入E2/E3，另分别报告中位/尾部/最大值；目前只有表达式，没有实测分布。

| 当前原路线的条件极值 E=N | POINT有效byte量 | 独占nominal1.6GB/s的理想byte时间 |
|---|---:|---:|
| 16tile radius histogram：4096遍 | 67,947,724,800 | 42.467328s |
| 圆五遍：81920遍 | 1,358,954,496,000 | 849.34656s |
| TLS六遍：6144遍 | 101,921,587,200 | 63.700992s |
| 精确support去重：131072遍 | 2,174,327,193,600 | 1358.954496s |

这是给定访问量的无竞争/无计算理想尺度，下界只对实际执行该访问量者有效；不表示这些极值在同一成功图上必同时出现，也不是已测latency。真实NUM/随机表/协议/缓存/视频竞争只会改变更完整预算。DDR容量可行不意味着原当前串行微架构速度已合理，须继续联合优化，但不擅自新增fps上限/低指标。

**OPT-H1：full-radius HIST。** 当前16tile使每seed16遍POINT，可候选增加131072×32=524,288B的full-radius HIST，明确每bin逻辑uint21、bits31:21全0；同seed一次完整POINT距离/normal gate后直接投同原r0全域bin，再按radius升序生成RAW/SMOOTH/plateau。若采纳另给不alias的[0x05440000,0x054C0000)512KiB段，固定物理合84.75MiB，128MiB区余43.25MiB；原tileHIST仍在未变D5/AUX保守账中，不暗减旧布局，生产替换/退休另审。

它省每seed15遍POINT及对应重复距离/normal计算：C_s≤256时POINT histogram主项由16C_sE降C_sE，上界4096E降256E；HIST全131072bin清空/读顺序总数并未凭空消失，随机DDR RMW可能增加服务成本。严格保持原r0算式、合法半径域、域外拒绝、halo/边界/SMOOTH窗口、plateau首/末/ties、全RAW/SMOOTH排序与计数21bit、不重投halo、不减CAPACITY/失败/关闭义务。每bin latest/read-write forwarding和N点前缀/R3held/commit仍真实，full-table CLEAR未settled不能投票或假initialized；独立逐bin/逐peak比较通过前不修改R4R冻结算法。

**OPT-D1：DENSE低20bit加唯一high marker。** 一个θ的总票≤E≤2,073,600<2^21。若两个bin各≥2^20，总票≥2^21矛盾；一个bin也不可能第二次low20回绕。所以每lane一个native512×20 RAM保低20bit，加overflow_valid1+overflow_bin9共10FF，可恢复277个逻辑21bit计数：地址与有效marker相等时high=1，否则0。16lane共16RAM10+160marker FF；160仅marker，不含控制/旧新值/journal/21bit响应/NUM/计数器。未采纳此证明时可保守每lane20bit+1bit平面=32RAM10，仍须真实端口/packing。

CLEAR必须清277实际low计数及marker，bin0…276检查在任何bank访问前完成，277…511不作合法bin；全部零/phase切换和θwrap/NMS四快照仍按旧数学。遇low=2^20−1将进high时，若有效marker指向另一bin应拒绝INVARIANT/整帧失败，不能覆盖旧marker；高位/总票/canonical均不得绕回。连续同binforward须同时覆盖low和marker的旧/新值、1R1W读延迟和已写未回应组；每point最多给该θ一票且真实accepted计数不超过E是证明前提，异常路径不能伪造此前完整效果。

logical16group仍原子：内局部无旁观reader、latest/journal或等价提交屏障在全部lane效果真实完成后才group成功；取消先旧fire，已交付效果不抹掉、未结/unknown不假close。清batch之前θ邻居/NMS及其真实快照reader必须结清。16banks不等16votes/沿，原逐组req→rsp至少多个沿；若要流水多组须新burst/stream、NUM feed、per-lane samebin hazard/credit/echo/close和资源合同，当前R4R不默改。

**采用次序。** 先D5 fixed DDR对象与typed原子层/视频QoS，再冻结OPT-H1和OPT-D1的独立局部/接口/byte/数学差分计划，最后根据实值profile和完整GT/trace选择并行度、clock及cache。这两项提供具体无新场景门的提速方向，不保证完成所有cycle/资源目标；圆拟合/finite/精确dedup数值调用仍可能主导。

## F. 语言与三份映射

C++实现未选，纯审计算术使用精确非负整数/有理数量，无host native64溢出/浮点压缩率假设；未来模型语言按整包另冻。数学循环/数组存在不意味着硬件容量、端口或1cycle。

| RTL A–L | 本任务合同 / 未知 |
|---|---|
| A 数值 | N/P、层级计数和宽运算按原R3/R4；总byte/work用足够宽精确整数；MB与MiB明确，缩位前检高位。 |
| B 时钟 | core候选25/27/100与视频148.5/74.25分开；旧沿判fire/沿后观察；未证明related/async或实际fmax。 |
| C 接受 | 原逐口真实fire、typed接纳/raw接纳/effect/NUM结果/commit/close不混；相机与视频无ready前提另冻。 |
| D valid | 0像素/0EDGE/0ANN是数据；invalid不访问/计数；E0仍完整N源/输出义务。 |
| E 保持 | held原body/identity/pending保持；cancel先旧fire，资源复用不擦旧义务。 |
| F 延迟 | E2/E3给主项/条件表达式，NUM/服务微周期OPEN；无bounded ready不报成功墙钟上界或fps。 |
| G 复位 | O refs/版本/未知效果不单端清零；Flash配置区/外部效果及CDC重建必须真实证明。 |
| H 配置 | 同job固定SRC/profile/geometry/render版本；优化重算使用原快照，不能用最新UI阈值替旧job。 |
| I 存储 | D的真实native/端口/packing/生命周期及D5 DDR容量/授权候选；DDR真实服务/校准/恢复及Flash用户区未冻；PC无生产对象。 |
| J 身份 | source/J/result/render/display/scan/borrow和typed seq分族；派生ordinal/N图/ANN程序坐标保持。 |
| K CDC | core/相机/视频/reset跨域仍R5；一域仿真或UART同步器不等全机CDC通过。 |
| L 实现 | Ti60F225/原软件工具候选；当前无全机bank/FF/DSP/PLL/pin/STA/PNR证据，旧资源预算不继承。 |

共同数值契约：优化的完整CLASS/EDGE、POINT排序/θ、几何/最终统计、exact coverage/dedup及ANN须与原确定算法逐bit比较；独立GT质量另外判定。硬件执行契约：单writer/latest/atomic、真实fire/不同prefix/commit/close/return、current-vs-next及video deadline单独验证。对应契约：同源原image/profile/JID/原坐标/ordinal/NUM_ID/对象版本逐项映射；软件host内存只给reference，不能映射成板卡真实工作容量。

## G. 实施与验证计划（全部NOT_RUN）

实施前先闭合A2的架构/基线/端口/文件/验证计划，独立审阅后纳入指定整包批准；当前不生成业务实现、模型、常数、脚本、TB或工程/SDC。获批后才按真实增量取得软件结果、完整网表/fanout、资源/时序/PNR/bit。bit后硬件步骤本次不执行。

| TEST | REQ/IF / 输入与事件 | 期望、方法与界限 |
|---|---|---|
| PERF-T01 | REQ01/02；D2全N各表/EDGE共享、padding/guard/descriptor | 独立精确容量和来源hash核对；无隐藏副本/第二帧，逻辑表不冒BRAM。 |
| T02 | REQ02/07；native1/2/8/16/20、跨bank/同址/RMW | 实际模式/port/读延迟/latest与对象保护；预算不当网表，获批后推断报告。 |
| T03 | REQ03；GENERAL/快路径、末claim/lastneighbor/取消/错echo | 独立trace派生B与各H真实台账，13N界不替close/term规范；不同prefix不强等。 |
| T04 | REQ03/04；radius tile/峰/五遍、512θ/六遍、预算触顶/容量错误 | 实际point_passes/NUM calls/typed effects计数；不假完整搜索或丢难例提速。 |
| T05 | REQ05；同冻结图重复、mode0偶行、mode5最坏行 | 固定2200×1125/1080p60、原坐标/版本、逐行服务/CDC/无欠载；慢算法不假60fps。 |
| T06 | REQ06；历史可选Flash路线的用户区/配置保留、last byte、未知读写/复位 | 仅选此路线才需独立型号/容量/访问与恢复资料先冻；未证明区域不使用，未知不commit/返还，不要求当前DDR主路径为Flash先补实现。 |
| T07 | REQ03/06；真实UART观察/fullN/packet竞争 | 参考/观察带宽与生产分开；PC不作工作存储/计算，串口结果不冒视频供数。 |
| T08 | REQ07；CLASS/QUEUE/GRAD/POINT最后读及旧borrow迟返 | 真return后再复用、旧fire保留；geometry/profile/source同值，未返不覆写。 |
| T09 | REQ01/04/07；长链/斜连/环/多种子、精确扫描重算 | 全N EDGE对独立可达集合；changed0须完整遍/effectssettled，无固定轮近似。 |
| T10 | REQ04/07；派生POINT/热点bank/finite分数先选q/程序ANN | 原全部pixel/ordinal/θ/geometry/统计/ANN逐bit；优化不偷偷改变LOCAL/FRAME/Q/held行为。 |
| T11 | REQ04；圆/任意旋转矩形/三边、重叠/负样本/失败帧 | 原两类P/R95%、IoU0.5最大基数匹配；失败记FN/负样本FP，GT提前独立冻结。 |
| T12 | REQ08；实际全core/动态source/profile与生产clock | 完整hierarchy/有效扇出/FF/XLR/DSP/BRAM/PLL/CDC/pin/PNR/STA/bit；小top或常量stub不能替代。 |
| T13 | REQ05/06；不可暂停源与最坏服务停止 | 累计入出/FIFO/完整帧政策与真实mode一致；不靠新fps假设或无限FIFO。 |
| T14 | REQ02/06/07/IF05；D5每槽first/last/logical末/physical末、多slot占用/旧borrow | 84.25MiB及AUX三RECORD精确核，padding无普通权限；32bitbody/33bitend/物理高4零及实际byte单位/不越物理容量；6S/3bundle接口未吸收不可自填资格。 |
| T15 | REQ03/05/06/IF05；AXI stall/wrongID/错last/写失败/refresh/校准丢失/独立close | 完整effects/unknown债务、typed原子屏障/最新值/真实关闭与逐行deadline；no alias/无PC生产fallback；非串口服务必须实际全core验证。 |
| T16 | REQ03/04/07；OPT-H1全radius/halo/plateau与OPT-D1连续samebin/首次high/异常第二high/cancel | 原逐bin/peak/票/NMS及FRAME协议差分；COUNT总票证明与16group原子，160marker不假全FF；新burst/stream只在另冻结合同后验证。 |

未来每项需明确有限seed/调度/CASE/cycle和wall timeout、许可/工具基线、实际报告hash；它们现在OPEN，不运行功能工具。永久stall仅查保持/不假成功，实际服务/错误deadline另有明确责任。

## H. 双向追踪

| REQ / 来源 | MOD / IF / 中文步骤 | 计划职责（未生成） | TEST / 实际证据 |
|---|---|---|---|
| REQ01/02 / R4R D7、R4C D1/F、Ti60报告 | O/W；IF01/04；D2/3 | capacity_lifetime_contract、native_resource_map | T01/02；静态数值，未实现/NOT_RUN |
| REQ03 / 原C0/R4C/R4R/RAW真实事件 | W/S/N；IF02/03；E1…4 | layered_work_trace、service_cycle_contract | T03/04/07；当前只有合同，不是波形 |
| REQ04 / 原ALG/R4R/profile/GT | W/Q；E1/2/7；F三映射 | heuristic_budget_audit、exact_optimization_comparison | T04/10/11；质量未运行 |
| REQ05 / DISPLAY/赛题解释边界2 | V/S；IF03；E5 | video_service_deadline、source_admission_contract | T05/13；视频供数仍OPEN |
| REQ06 / 用户最新板内资源/允许DDR边界 | O/S/V；IF05/D5/E6/E9 | board_resource_only、board_ddr_feasibility、historical_flash_source_feasibility | T06/07/14/15；板载DDR允许/真实服务OPEN，Flash未拍板，PC生产禁用 |
| REQ07 / 原owner/return/commit与数学 | O/W/N/V；D4/5/E7…9 | exact_replay_stream、hot_pool、program_ann、full_radius_hist、dense_unique_high | T08…10/14/16；都是未冻结候选 |
| REQ08 / 根v0.2及原软件目标 | 全局/Q；F/G/I | full_core_validation_contract | T12；业务/工具NOT_RUN |

反向：所有审计/候选只服务原要求、真实资源、协议与生产可行性；只使用已允许的板载DDR，不新增外接模块或场景降标。计划职责不代表已有源码；获批后逐文件/符号/源码/测试/产物再补实际映射。

## I. 设计门槛与审阅

①B整体/例；②C职责和真实来源；③D跨稿容量/接口；④E中文步骤与条件表达式；⑤F A–L/三份映射；⑥正常/边界/错误及fullN路径；⑦G/H；⑧无当前阻塞不满足A2；⑨本稿保存、实际全文读回/hash另报告；⑩版本/范围/输入hash明确但生产架构未冻结。保持GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN，不关闭R4/R5/B03/B05或整包。

当前可继续纯设计求解和独立审阅；成熟全机版本/范围/共同基线明确后才等待指定批准。本文没有修改Approval Manifest/DB或正式状态；不从文档保存推导审批或工具PASS。

## J. 变更与恢复

用户撤回降标，先限定仅板卡已有资源/无DDR/无新增存储/PC仅参考观察，后又明确允许板卡现有DDR3；后者撤销无DDR约束。本稿据此把RAW94F/64MiB软件arena移出production可行性路线，只保留其容量/观察成本来源；不改旧RAW或其他文档，不让旧假设继续自授范围。

任何新的DDR适配/多slot/原子控制、fullHIST/DENSE压缩，以及可选Flash许可/源重算/热池/候选再生/程序ANN/显示关系/NUM接口选择须同步R2/R3/R4/CONTROL/VIEW/REPLAY/R5的owner、数值、关闭、版本、G/H/基线。恢复先核实际当前用户边界、来源hash、未知effects/refs/borrow及真实批准；不重新引用WITHDRAWN降低指标方案或旧225RAM“可行”结论。

## K. 实现与验证实录

本轮实际只读控制面/模板、四份当前来源全文及相关资源/需求/显示/Flash板说明；作静态容量/工作量核算；仅创建本文。未生成业务RTL/C++/Python、模型、功能脚本、生成器、TB/可执行测试、工程/SDC；没有构建、仿真、综合、PNR、STA、bit、设备操作、Flash/DDR写入、网络/安装；最新允许DDR后仅只读指定更新包源并绑定参数证据，没有运行PHY/校准。原资料/设计/正式状态/Manifest/DB保持。

这些数值是条件预算或访问界，非实测。作者审计不是全机资源/性能成功证明，理解验收待用户真实反馈。

## L. 交付与阅读说明

读B整体原目标/最新边界→C责任→D当前容量/native/lifetime及D5板载DDR不alias分区→E各层访问量与NUM/观察周期→E4历史串口边界→E5固定视频→E6历史Flash审计→E7可选等价改写→E8中文求解→E9非串口服务/fullHIST/DENSE具体提速→F/G/H→A2/I真实停止点。

一帧必须穿过真实SOURCE、完整算法、精确集合/几何/结果、同源重放、fixed-video服务以及真实对象关闭/返还。现全容器BRAM-only路径确定不fit；允许板载DDR后，D5保守84.25MiB固定分区在名义256MiB容量内可放下，仍须真实原子层/目录/全机资源/QoS/计算与质量证据，尚未证明原整包完成。不能交付“已经能综合/仿真/PNR/合理pin/STA”的结果，也不能断言任何等价架构都绝对不可能。下一动作是闭合A2后把实际可复核架构纳入统一设计审阅；本稿保存后停编辑，交根独立复核。
