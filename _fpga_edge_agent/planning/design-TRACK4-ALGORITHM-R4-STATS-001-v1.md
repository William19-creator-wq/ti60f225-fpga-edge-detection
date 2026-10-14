# TRACK4-ALGORITHM-R4-STATS-001：点集统计与FIT交接设计 v1

2026-10-08；使用PLAN_TEMPLATE。状态：READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本文是实现前中文草图，只有文档；没有新增RTL、模型、功能脚本、TB、工程或EDA运行。最终读回与呈现记录见I节。

## 通用计划字段

- Goal：把R4已选择点集转成现有FIT所需的精确LS/TLS统计，接通点记录→统计→原FIT→结果这一段。
- Current state：FIT v1的19文件、14517数值、同源综合/布线/STA及bit已登记；统计生产端仍无代码。ANGLE v1.1尚待指定批准。
- Target state：可读的点流合同、完整统计流水线、原FIT真实组合验证及同源Ti60F225/I3软件产物。
- Gap：点统计的业务代码及其验证尚未生成；本范围设计已具体补齐，最终基线、读回和呈现另登记。READY也不是实现批准。
- Assumptions：同域可暂停源，单统计上下文；来源点集已完成并按(y,x)严格递增，一次扫描条数E已知，0≤E≤W×H。筛选条件由上游固定，本文不选择候选、不改变旋转/遮挡/噪声/数量要求。
- Open questions：A2记录本范围设计事项的闭合依据；实际测试NOT_RUN是批准后的义务，不假装需要先写代码证明设计。
- Dependencies：根v0.2、模板、现行R3数值字段、R4 POINT与拟合统计定义、已登记FIT v1六份可复用RTL及独立fit_reference。
- Milestones：整体→接口→局部流水线→预算/来源/验证/追踪→保存读回→具体READY版本和基线→明确批准→代码/单测→真实组合→物理/bit登记。
- State transitions：IDLE→CHECK→RUN→DRAIN→PACK→HELD→IDLE；错误在原上下文保存首因并完成源关闭。违反有限关闭合同且超过u22计数容器时进入PROTOCOL_STUCK，不回绕、不宣称关闭；共同冷复位作废单列。
- Artifacts and hashes：基线ALGO-R4-STATS-BL-20261008-v1，拟冻结清单为experiments/track4_algorithms_20261004/01_baseline/algorithm-r4-stats-baseline-v1.json，实际SHA/条数由03_review/r4-stats-design-readback-v1.md记录；不在正文放自引用hash。旧FIT/staging、旧设计与原HDK不改。
- Validation：G为文字场景；数学边界分析、真实仿真、组合、资源/时序和硬件分别记录。
- Failure handling：错误统计不形成合法NUM请求；旧已接受点/流水线返回仍排完；未收到原上下文关闭不能伪造收尾。
- Human approval gates：当前v1已具备独立范围设计自检依据，等待批准指定版本、22文件范围、基线与本批本地审计例外。FIT授权不扩为本新模块；正式DB/Manifest/state/ledger不改。
- Rollback：未来独立work/active/track4_algorithms_20261004/r4_stats；当前不创建业务工作副本。旧来源保留。
- Completion criteria：完整本范围设计、实际读回及组合/预算自检后才READY；获批后所有适用软件证据和bit登记闭合。完整十一项另验，不缩成这个小包。

## A. 来源和阶段

关联A6、R4R统计/五遍圆/六遍TLS、R3 kind11/12/17/18。本模块供单次集合扫描；多候选、四边状态保存和迭代成员选择仍属R4调度。

实际来源：R3-FIT staging ALGORITHM-R3-FIT-20261008-v1（Manifest SHA0A58429E2525D667603441A309AD50782E38299723B9E2E6CD51ABB14E5C69C1）；fit_vectors.statistics/fit_reference.INPUT_FIELDS/evaluate；R3总设计D2/E4/E5；RECOGNITION-NUMERIC E4/E5；R4-RECOGNITION v0.2中的POINT row-major和FIT_STATS263/TLS217。旧目录/DDR关闭合同不自动成为本模块端口。

### A2. 本范围设计事项及闭合依据

| 编号 | 具体依据与阶段 |
|---|---|
| ST-B01 | r4-stats-source-and-budget-v1第2…4节：字段、LFSR、正常/错误、具体状态、真正585位CRC及独立重建；设计已填写，未实现 |
| ST-B02 | 同附稿第5…6节及本E/F：全体容器12552bit，POINT t0→t4，关闭后≤6形成沿，新联合物理门槛；设计分析，未测 |
| ST-B03 | r4-stats-validation-v1第1…5节及本D/E/G：1024常规、两全N及两全N稀疏、固定反例、真实FIT组合、种子/期限/三账；未运行 |
| ST-B04 | G明确22文件，I十项自检及外部readback/freeze清单；三份最终设计实际全文/变更处读回，聊天呈现整体与阅读入口；基线的最终SHA读回另记录，不从文件存在推定相容性通过 |

阅读顺序：[整体与接口、局部草图（本文）](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R4-STATS-001.md)→[具体来源、消费者与预算](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-source-and-budget-v1.md)→[独立验证与逐沿组合](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r4-stats-validation-v1.md)→[最终组合读回](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/r4-stats-design-readback-v1.md)。

生产DDR/相机/完整POINT提供者、候选质量与全机性能继续OPEN，但独立软件源可按本接口提供同样数据，不冒称真实生产链路。

## B. 整体行为

| REQ | 可观察保证 |
|---|---|
| ST01 | 有限源遵守关闭/故障进展合同的一次START接受产生一个可保持的STAT_RESULT；原NUM_ID贯穿，冷复位作废分账；无关闭或计数破坏不伪造终态 |
| ST02 | 圆LS：a=Gy，b=−Gx，d=ax+by；准确汇总n/A/B/C/D/F，不舍入均值、不拟半径 |
| ST03 | TLS：X2=2x−(W−1)、Y2=2y−(H−1)；准确汇总n/Sx/Sy/Sxx/Syy/Sxy |
| ST04 | POINT真实接受才推进原扫描计数；include=0仍是一条扫描记录，统计不更新；valid=0不是零点 |
| ST05 | kind11/12/17/18生成现有622位NUM请求，诊断不添加阈值或重新拟合几何；其余kind明确拒绝 |
| ST06 | 单上下文/流水线一有效点每core沿，无第二结果队列；旧valid/payload保持至fire |
| ST07 | 同ID END/ABORT关闭源token通道；旧算术排完后形成结果。错误不清在途有效性，已HELD不重写 |
| ST08 | 精确全宽加法及写前资格，原字段边界不变；原FIT六RTL/参考字节复用，不再加第二scalar |
| ST09 | 独立统计参考、真实原始token账、真实FIT组合及全N场景；工具与bit只在获批后执行 |

W偶数6…1920，H5…1080，生产1920×1080；E≤N。每点x<W/y<H，Gx/Gy∈[−1020,1020]。零梯度是一行合法零LS贡献，仍可include并计n；是否筛除由上游负责，FIT自行判退化。TLS仍接收同一合法点格式，梯度不参加其数学。 本局部接口允许每分量合法梯度以及零梯度，用于独立typed统计试验；实际R4 POINT还保证非零G和|Gx|+|Gy|≤1530，是更强的上游条件，不由本核重新选择点。POINT64的dir/θ用于上游筛选，不参与LS/TLS五项和；转成token时caller按已冻结成员谓词提供include及ordinal，不把token262误称POINT64原样。

正常例：三条不平行法线→LS统计→完整622请求→原FIT求中心。空集合E=0→START/END0→成功统计n0→原FIT返回LOCAL_REJECT/COUNT；不能把空集合伪装成合法拟合。中止例：已接受点先排流水线，ABORT以后不累加，输出CANCEL_DROP；原先已有首错则保存原错误。未有END/ABORT的开放源不会因计数等于E就宣称已经关闭。

可逐项读回的小例：W6/H5/E3/kind11/threshold0，顺序点(1,1)、(3,1)、(2,3)，Gx=x−2/Gy=y−2，全部include。三条贡献(a,b,d)分别(−1,1,0)、(−1,−1,−4)、(1,0,2)，n3/A3/B0/C2/D6/F4；成功STAT真实交给FIT后中心Q4=(32,32)，原质量公式4(AC−B²)/(A+C)²=24/25，RNE质量62914。同一合法统计改kind17只走原诊断，不能改成11再丢几何。TLS可读例W6/H5下点(0,1)、(2,1)、(4,1)：X2为−5/−1/3，Y2均−2，n3/Sx−3/Sy−6/Sxx35/Syy12/Sxy6，kind12/18分别交原拟合/诊断。空或少点都是STAT VALUE，仍由FIT判LOCAL_COUNT；不是统计层LOCAL_REJECT。

## C. 职责和交接

可暂停点源（未来R4选择器）→IF01有序token→stats_core检查/流水线/五累加器→IF02统计结果→调用适配者→原fit_core→NUM_RESP585。

stats_protocol_pkg只定义token与统计结果；stats_core拥有当前配置、计数和累加器；原FIT不读点、不选成员。stats_probe_top作为独立软件/物理源、单槽交接与真实消费者。模型直接对接受点集求整数和；TB记录真实fire，不从DUT累加器生成期望。

| MOD | 责任、状态拥有者与边界 |
|---|---|
| ST-M01 stats_protocol_pkg | 本token/STAT布局、字段资格、打包函数；无时序状态；引用原FIT消息字典，不改变原包 |
| ST-M02 stats_core | header/有序点/五槽/四级/结果、首错及关闭；覆盖ST01…08；不选择点、不持有DDR对象 |
| ST-M03 stats_probe_top | source token槽、序号/LFSR、注册交接、共享响应观察和CRC；覆盖ST06/09；只一个job，不冒充摄像机 |
| ST-M04 原fit_core及私有桥/算术 | 原字节复用，统计NUM请求→几何/诊断终态；当前已验证接口，新的联合调用仍待真实测试 |
| ST-M05 独立模型/四TB | 直接数学、原始token来源审核、真实组合及关闭账；不产生生产输出 |
| ST-M06 runner/工程 | 失败退出、快照和同源EDA/产物登记；不改变硬件节点、源算法或外部审批 |

组合检查：IF01 source能暂停并保持已公开token，CHECK/关闭阻塞不会覆盖其单槽；IF02核只持一结果，stat_ready来自适配者空闲且已有job，不受观察器循环依赖；IF03注册NUM622/原FIT622位宽、原ID/flags/target/阈值/字段完全相容；IF04原FIT585响应槽已经预约，FIT_WAIT可以接纳，即使observer暂未ready；IF05 observer先真fire再移位，源直到585位结束才复用上下文。KEY→原reset_sync→所有模块同域复位为IF06。原FIT cancel端在probe明确绑0，组合TB单独按原合同测试。无分支同时竞争另一份scalar，无第二帧缓存或无限队列；数学流水线排尾不依赖外层输出ready，因此不存在持有旧结果再等待它自己的循环释放。

STAT_RESULT632与NUM_RESP585是不同语义。成功统计带的是NUM_REQ622；不能把相同kind的统计数据当原FIT几何响应。后续适配者只在统计结果VALUE时发NUM请求，失败直接形成原身份错误。是否关闭DDR/POINT对象仍由R4负责；END只关闭本token通道。

## D. 接口布局与组合检查

IF01 input token_valid/token_body262，output token_ready；IF02 output stat_valid/stat_body632，input stat_ready；共同clk/rst。另output fault_active/fault_reason8，用当前sticky首错提示源发原ID的END/ABORT；不是第二请求/应答通道，无ready或另一份缓存。output quiet：仅!rst、IDLE、四pipeline valid全0且无stat_valid时为1；不是仅计数等于E，PROTOCOL_STUCK永不quiet。

所有位号低到高；二补码字段独立解释，unused必须0。

| token区 | 内容 |
|---|---|
| [175:0] | NUM_ID176：epoch32/frame32/config32/owner8/call_seq64/destination8；caller拥有非回绕序号 |
| [177:176] | op2：START0、POINT1、END2、ABORT3 |
| [261:178] | payload84，各op按下表解释 |

| op | payload低到高 |
|---|---|
| START | W11/H11/kind5/numeric_version8/threshold16/E21/zero12，共84 |
| POINT | ordinal21/include1/x11/y11/Gx signed11/Gy signed11/zero18，共84 |
| END | declared_seen22/zero62，共84 |
| ABORT | zero84 |

IF02低到高NUM_REQ622/outcome2/reason8，共632。VALUE时NUM_REQ包含原ID、W/H/version/kind、signed flags0、target0和原FIT payload；FRAME_FAIL或CANCEL_DROP时保持这些元数据但payload400全0。STAT不输出LOCAL_REJECT：空/少点和退化交给FIT；错误代码沿原字典。诊断START.threshold必须0。

START检查次序：尺寸COORD3→version/owner/kind UNSUPPORTED12→unused/诊断threshold FORMAT2→E>N COUNT7。POINT首错次序：原ID不符INTERNAL13→ordinal/超过E COUNT7→坐标COORD3→梯度域INTERNAL13→unused/非严格(y,x)顺序FORMAT2。已有首错保持；原更早点的提交资格错误先于本沿新token错误。

header真实接受锁配置；数据只能依锁定配置。IDLE真接纳非START时形成原token ID的FORMAT错误（kind/W/H/version0，不解析为START），没有开启点流。RUN真接纳重复START为FORMAT错误，不创建第二上下文。不同ID END/ABORT只记错误，不能关闭旧上下文；同ID END/ABORT真实fire是源结束承诺，其count/pad失败使结果无效，源通道仍结束。END核declared_seen=实际POINT接受数=E；异常帧已有首错不覆盖。

源必须在START之后最终提交END或ABORT，关闭fire后不再发布本次POINT。fault_active出现后，源必须兑现已经公开的单个token，再用原ID END/ABORT关闭，不继续生产无界POINT；如果已公开的是END，兑现END即可。want cancel时先兑现已发布POINT，再发布ABORT；END已经fire后不再通过ABORT制造新义务，外层caller接收并丢弃尚未消费的统计/拟合结果。单源普通冷复位必须与核/适配者/消费者共同进行。正常进展假设为：源最终给出关闭，输入/输出ready最终允许真实fire，时钟继续，所有参与者共同复位；非法无限源由测试监测判不完整而非RTL假超时关闭。

ready只依当前容量和状态，不能依消费者释放别的对象。HELD完整632位不变；RUN可接一token/沿，CHECK和关闭后的DRAIN/PACK/HELD不接新token。END后管线排尾不依stat_ready。输出fire之后下一状态才允许新START，当前上下文不与旧累加并存。

## E. 内部数据与中文语句草图

### E1. 状态与拥有者

IDLE等待START；CHECK核锁定header；RUN消费POINT或关闭；DRAIN等待四级旧有效性清空；PACK读取已最终提交的统计，形成冻结结果；HELD保持至fire。第七状态PROTOCOL_STUCK只用于破坏有限源合同后raw_seen扩23位结果不适配u22的情况；不更新成回绕值，不接受新token、输出或quiet，旧pipeline自然排完但不提交；只有共同reset可恢复。七态仍u3，无额外计数缓存。header非法仍进入错误RUN，让源兑现已发布POINT并发送END/ABORT，不能立即丢下已发布数据返回空闲。fault_active在错误记录后至该结果消费为1；无首错时fault_reason=NONE。

当前header、Raw POINT接受数u22、include统计n21、上一合法x/y各11及资格、五个逻辑56位累加槽、四级数据/valid由核拥有。没有历史点列表、全帧RAM、第二上下文。START清n/五槽/计数/资格；共同rst清有效性，旧pipeline数据可不清，因为无valid不得读取。

必要不变量：ST-I01一个已接受START仅一个上下文，关闭后的token_ready0；ST-I02 raw_seen逐真实POINT推进，n只逐合法数学commit推进，两数不能互代；ST-I03每个eligible只在S0…S3某一级或已commit/discard中，气泡不成点；ST-I04五槽/n原子提交，字段资格失败不留部分统计；ST-I05 mode/NUM_ID/threshold在旧义务关闭前不变；ST-I06 stat/NUM/rsp/公开token valid且未fire时全文保持；ST-I07错误/中止payload全0，不以剩余统计伪VALUE；ST-I08源/STAT/NUM/观察的reset作废分账。建立点分别为START清有效性、合法point分派、逐级valid移交、s57资格与一沿多写、HELD保持和真正观察完成后释放。

### E2. 每个点：接受→乘积→完整累加

1. 本沿POINT fire先按旧header/旧seen/上一坐标检查。raw seen用扩23位加1，适配u22才写回；不适配时按E1进入PROTOCOL_STUCK，首错为空则COUNT。合法序号必须等旧seen；将旧seen扩到22位再与扩22位ordinal比，超过ordinal21域不会低21回绕比较。接受记录完整计账，即使include0或该帧已有首错。每条通过坐标/梯度/pad/顺序等POINT格式检查的记录都更新上一坐标资格，包括include0；格式失败不改上一合法坐标。
2. 只有合法且include1、尚无首错的点进入有效数学pipeline。输入时a=Gy先扩s12；Gx先扩s12再取负为b，不能先在s11对最小值取负。x/y作为非负s12。X2/Y2先在s13形成2x−(W−1)，核真实域再收s12。
3. S0保存a/b/x/y/X2/Y2及所需伴随；S1用五个s12×s12乘法分别形成p0/p1/p2和ax/by。p0…2由当前模式选择(a,a)/(a,b)/(b,b)或(X2,X2)/(X2,Y2)/(Y2,Y2)，完整s24注册，平方非负才作unsigned解释。
4. S2先扩s25相加ax+by形成d；S3的两个s12×s25乘积形成ad/bd完整s37，TLS时不使用它们。原p0…2及X2/Y2随相同valid移到提交。pipeline每沿推进，不受外部stat_ready影响；气泡只清valid，不新增点。
5. 在S3之后的提交沿，按模式选五个完整贡献。LS槽0…4选(p0,p1,p2,ad,bd)，分别A/B/C/D/F；TLS槽0…4选(X2,Y2,p0,p2,p1)，分别Sx/Sy/Sxx/Syy/Sxy。贡献按自身signed或非负资格完整扩s57，五槽旧值同样扩s57再相加；n先扩22位加1。逐字段核资格；任一失败整点五槽/n都不写，记录OVERFLOW8（n>N为COUNT7），不留下部分成功。资格先核n再按槽0…4，因此多项同沿失败结果确定。
6. 合法时一沿同时提交五槽与n；后一个点只读沿后新统计。五槽共享LS/TLS的实际寿命，当前mode保持，不能把两个不同候选同时混入这组槽。

四级S0…S3加提交：POINT在t0接受，t1/t2/t3进入后级，t4完整累加；RUN稳态一有效点/core沿。last POINT为te−1、END于te接受时，最后累加到te+3；DRAIN下一沿才能判断旧pipeline全空，再PACK，stat_valid在te+5沿后形成。关闭到形成要求≤6沿；te若旧pipeline已经空，可更早，stat_ready不参与排尾。该逐沿推导为设计，实测仍NOT_RUN。

### E3. END、错误、中止及输出

每沿优先级：共同reset作废→同ID且pad0的ABORT禁止本沿及未来算术提交→旧pipeline提交资格错误→当前token字段检查。所有真实fire仍独立计账。已有首错保持；有效ABORT无旧首错则最终DROP。ABORT同沿被丢弃算术不制造新的业务错误或取代取消原因。同ID但pad非0的ABORT仍关闭输入，但属于FORMAT失败而不是合法取消，按旧提交错误优先规则处理。END不丢合法旧点，要等最后提交完成。新token错误发生在旧合法点提交之后，随后禁止新分派/未来数学提交；失败payload0，不虚构部分成功。

DRAIN中不接受新输入，继续消耗所有旧pipeline项。确认旧valid全0后才PACK；PACK读上沿最终n/五槽。成功以原FIT字段逐项打包，所有unused/payload高位0；错误或DROP的payload全0。HELD期间fault/body/ID不变，普通源追加非法token不会被接纳。共同rst可作废held/pipeline，真实账按reset另列。

语句组织草图：包内按常量/位域→解码与资格→结果打包组织；core先端口与枚举→拥有者寄存器→完整组合派生值/五槽循环资格→ready/valid/quiet映射→单一时序更新块。组合循环只遍历固定五槽，写全默认值，再计算s57候选，核原typed域；不在组合块改历史寄存器。时序块按reset、实际fire和首错优先级处理，pipeline各级以旧valid移交；新状态只影响下一沿，不能拿本沿刚写的n或d代替旧寄存器。所有多位切片都按独立字段解释，message整体不作signed。include0也检查完整格式，但不进入数学valid；无法把无效点当零贡献。probe按来源、注册适配、观察三段拥有者拆开，避免同一response_word被两个always块写；以一段时序块集中写这个共享槽，所有权仅在obs_fire改变。原六RTL不做格式/命名重构。

### E4. 数值资格与范围（设计分析）

| mode | 输出n及五字段 | 点贡献 |
|---|---|---|
| 11/17 | n21/Au43/Bs44/Cu43/Ds56/Fs56 | 三s24产品（平方非负）及两s37产品 |
| 12/18 | n21/Sxs33/Sys33/Sxxu43/Syyu43/Sxys44 | X2/Y2s12，三s24产品（平方非负） |

N2073600/G1020时：|d|≤3057960；A/C≤2157373440000；|D/F|≤6467805573120000；|Sx|≤3979238400、|Sy|≤2237414400；Sxx≤7636158489600、Syy≤2414170137600、|Sxy|≤4293598233600。分别落在原字段范围。此为保守上界，不证明实际FPGA资源或帧FPS。无除法、平均、RNE、饱和、截断；只在资格通过后收原字段。

## F. 语言、存储和预算候选

SV2009/整数Python；无C++。组合阻塞且完整赋值，时序非阻塞；多项统计同沿原子写入，不能套用FIT的单工作槽写规则。五个逻辑56槽共280bit、n21；完整stats容器1810bit、新probe1787bit、原FIT冻结候选全核上界8955bit，合计12552bit，逐项见来源预算附稿。原FIT已含唯一private scalar/bridge/cache；reset在probe计一次，不能又加一份旧scalar。组合乘法结果明确全宽，再注册；每个完整扩展/资格函数都有确定输出，禁止latch、多驱动、隐式signed混算。

本新范围拟批准联合物理门槛：Ti60F225/I3、25MHz，XLR≤56000、RAM0、DSP≤32，setup/hold≥0，内部未约束/无clock/多clock0；这不是修改旧FIT已获批50k门槛。DSP计划为五个12×12、两个12×25及CHECK中的W×H；实际映射由工具报告判断。联合资源装下是实施验收目标，当前不作已通过保证。无需DDR或外部模块支持本次点流试验；完整生产存储需求不被撤销。

RTL A：上表及先扩后算；B：同上升沿、TB负沿驱动/正沿旧值计火，沿后只看新状态；C：token/out fire独立；D：include与valid分开；E：保持body与排尾；F：四级+提交/关闭≤6形成沿；G：核心共同同步高有效rst，probe P13异步输入沿用原两级reset_sync异步断言/同步释放，不使用单端复位；H：START快照、换配置不影响旧点；I：五槽/四级/一结果，无全帧存储；J：NUM_ID/ordinal/(y,x)/E/n分别计；K：核同域，KEY只经原reset_sync，生产多位CDC属于后续适配；L：上述明确预算，真实工具NOT_RUN。stats包只导入原fit包或用全限定名；原scalar仅导入原scalar包，不能双wildcard重名常量。

三份跨语言契约：数学模型直接对相同include集合求五项整数和；硬件模型另核真实接受、旧沿、pending、END/ABORT/held/reset；对应关系以原NUM_ID和ordinal/源坐标绑定，而非仅比较最后CRC。STAT632与NUM585分账，成功统计真正交给原FIT以后才比较几何结果。

## G. 拟实施文件与验证（未运行）

拟批准22份文件全部在独立work/active/track4_algorithms_20261004/r4_stats；下表只是计划，没有生成或复制业务文件。原源码不改；主机工具沿用已装Questa2024.1/Efinity2026.1.132/Python3.14.6/pwsh，无联网安装。

| 分类/数量 | 具体相对路径、符号和生成次序 |
|---|---|
| RTL9 | rtl/scalar_protocol_pkg.sv、rtl/fit_protocol_pkg.sv、rtl/scalar_core.sv、rtl/scalar_bridge.sv、rtl/fit_core.sv、rtl/reset_sync.sv六原字节；rtl/stats_protocol_pkg.sv字段/检查/打包；rtl/stats_core.sv状态、S0…S3、五槽；rtl/stats_probe_top.sv来源/适配/观察。先pkg/reset，再core，最后probe |
| model3 | model/fit_reference.py原字节；model/stats_reference.py独立解码/整数和/STAT；model/stats_vectors.py输入集、probe独立来源重建及三账。各math结果从源点计算 |
| TB4 | tb/tb_stats_helpers.sv资格切边；tb/tb_stats_core.sv逐点与收尾；tb/tb_stats_fit.sv实例真实原FIT；tb/tb_stats_probe.sv真实来源/CRC及序号尾域。单测→组合→probe |
| 运行3 | scripts/run_stats_sim.ps1、scripts/run_stats_build.ps1、scripts/postroute.tcl；旧FIT经验只作为输入，不原字节复制运行逻辑。每次运行新目录、所有退出/finished/hash/时序端点可审核 |
| 工程3 | project/stats_probe.xml、project/stats_probe.peri.xml、project/stats_probe.sdc；从FIT已验证seed改顶层/源清单/输出位置，保留Ti60F225/I3、4pin25MHz实际配置；综合/PT/PNR/独立STA全部通过后才生成bit/hex |

每步产物/停止：包/helpers先核布局和边界，失败不做后续数学；core完整scope及四全N扫描通过再联合FIT/probe；完整同源suite通过才build；容量/布线/STA/引脚/hash任一不符不得生成发布bit。工具失败保留旧attempt，有限期限由测试监测而非改变RTL行为；同范围无边界变化的内部修正同步草图再复验，改变重要契约则修订并等待指定批准。

| TEST | 场景、期望和覆盖 |
|---|---|
| ST-T01 | 全include/全exclude/交替mask、正负最大梯度、边界坐标；独立整数和及原字段逐bit |
| ST-T02 | 完整1920×1080全N LS和TLS，计数/末点/END；不拿小点集替完整1080p |
| ST-T03 | E0/n0、少点、平行法线/isotropic；成功统计转原FIT真实LOCAL_COUNT/DEGENERATE，禁止伪VALUE |
| ST-T04 | ordinal重复/缺项/倒序、坐标/梯度/unused/版本/owner/kind/诊断threshold非法；冻结首错和全零失败payload |
| ST-T05 | include0仍推进扫描、valid0不推进；邻接一point/沿及长气泡；原始token来源独立审核 |
| ST-T06 | 末POINT紧邻END、管线每级有效/气泡组合、输出held；最后点准确一次，END不替代排尾 |
| ST-T07 | ABORT各级、与接受/提交同沿、错误后ABORT、不同ID关闭、END后外层取消；关闭/保持规则按D/E |
| ST-T08 | cold reset各阶段/held/新job、换header但旧配置保持；真实义务作废分账，单端复位反例不判成功 |
| ST-T09 | 原FIT真实组合kind11/12/17/18，门阈值/诊断；统计632/NUM622/RESP585各自原身份和真实fire |
| ST-T10 | s57加法与字段资格的隔离边界；合法全N上界分析证明主overflow守卫不靠force伪覆盖 |
| ST-T11 | probe来源/完整统计/原FIT结果/真正585位CRC；按source-and-budget-v1的64+reset后4job及独立尾域两job核对 |
| ST-T12 | 真fatal非零/finished未置位、同源hash、综合/布线/STA真实D端/合理4pin，必要检查通过才bit |

手算全N TLS：Sx=Sy=Sxy=0，Sxx=N(W²−1)/3=2548038988800，Syy=N(H²−1)/3=806214988800。全N LS令Gx随y奇偶为±1020、Gy随x奇偶为±1020，W/H均偶：A=C=2157373440000、B0，原FIT中心Q4=(15352,8632)、quality65535。这是typed数学fixture，不声称实际Canny必产生全图边缘或该梯度。

## H. 双向追踪

| REQ/来源 | MOD与IF/局部/不变量 | 计划文件核心 | TEST与期望 | 实际定位/证据 |
|---|---|---|---|---|
| ST01/06/07，当前有限事务合同 | M02/M03、IF01/02/05、E1/E3、I01/03/06/08 | stats_core状态/排尾/held；probe来源/适配/观察 | T05…08/11，真实fire与reset三账 | 待实现/NOT_RUN |
| ST02/08，R3 LS字段及R4统计 | M01/02/05、IF01…03、E2/E4、I02/04/05 | stats_pkg资格；core LS五槽；stats_reference直接整数和；tb helpers/core/fit | T01/02/09/10，原INPUT_FIELDS及全N手算 | 待实现/NOT_RUN |
| ST03/08，R3 TLS字段及R4统计 | M01/02/05、IF01…03、E2/E4、I02/04/05 | 同上TLS五槽和中心坐标完整扩展 | T01/02/09/10，全N对称和、真实FIT逐位 | 待实现/NOT_RUN |
| ST04/05，POINT/include/四kind契约 | M01/02/03/05、IF01…04、D/E、I02/05/07 | pkg解码/STAT打包；core检查/row；vectors三账 | T03/04/05/09，来源与非法字段显式期望 | 待实现/NOT_RUN |
| ST09，独立软件证明范围 | M03…06、IF03…06、F/G | 六原RTL与原fit_reference字节复用；probe/vectors/四TB/两runner/Tcl/三工程 | T09…12，实际同源仿真、Q→D/资源/引脚/产物hash | 待实现/NOT_RUN |

G表反向逐文件组都落在上述行；不临时用空泛需求合理化辅助文件。获得实现后在独立work/docs补实际符号/当前源码hash/证据路径，不改已冻结设计或用空行号伪定位。

## I. 十项设计自检与评审

| §10.3项目 | 当前证据；均为设计证据，不是执行PASS |
|---|---|
| ①行为/边界/样例 | B九项REQ、正常/空集合/中止，D非法入口与E1容量破坏 |
| ②职责/连接/复用 | C六MOD/IF01…06，原六RTL与原FIT参考实际端口/字段读回；唯一scalar |
| ③接口相容 | D262/632/622/585位布局及快照、当前NUM字典，C逐连接，来源附稿第4矩阵/所有权 |
| ④局部草图 | E七态、四级、五槽、原子资格、首错、保持与语句组织；来源附稿五源/六适配态 |
| ⑤语言/映射 | F RTL A…L、三份模型/硬件/事务契约；无C++有理由；真实工具输入冻结 |
| ⑥端到端走查 | C/D/E及validation-v1第4正常/零点/错header/错ID/中止/观察逐沿 |
| ⑦实施/验证/追踪 | G22文件/各阶段、T01…12及1024常规/四全N扫描、H双向表 |
| ⑧无当前设计阻塞 | B01…03具体填写；当前模块不依DDR动态模型、ANGLE或生产摄像显示，后续原范围OPEN明确隔离；真实执行未运行不冒当设计事实 |
| ⑨保存/呈现/读回 | 本文及两个v1附稿保存并实际读取；聊天已呈现整体→接口→局部→测试阅读入口与22文件范围；最终哈希与呈现依据由r4-stats-design-readback-v1登记；UI打开返回queued不冒称已显示 |
| ⑩版本/范围/基线 | v1、独立r4_stats22份、kind11/12/17/18、ALGO-R4-STATS-BL-20261008-v1，具体冻结清单读回 |

设计自检与阅读入口呈现已完成，当前READY_FOR_REVIEW v1（2026-10-08；最终时间见readback）。停止点：等待用户明确批准本v1、22文件范围和相关基线及本批本地审计例外。用户尚未批准本模块。FIT v1批准已用于已交付FIT，不扩为STATS/ANGLE/DDR联网批准。Approval Manifest正式字段、数据库、PROJECT_STATE/TASK_LEDGER未改。

## J. 修订与恢复

v0.1原18465B/SHA4AB1A8C0C4BECAD1E698CCD333CDF4E5CCED235FF6B104D199A6EC665E90E1FB保存为design-TRACK4-ALGORITHM-R4-STATS-001-v0.1.md；两个v0.1附稿保持历史字节。v1补明确源/消费者、完整预算、三层独立验证及22文件，并补quiet、故障最终关闭、raw_seen完整资格/PROTOCOL_STUCK、TLS槽映射/include0坐标历史、取消与首错优先、真实观察后共享槽。没有生成业务文件。

恢复读本稿/两个v1附稿/基线和最终readback、真实批准与源码差异。影响接口、流水级数、模式并行/共享、取消/错误/时序、资源门槛或重要结构先修订设计并重新获准；批准版本/范围/依赖不变时不机械重复确认。旧FIT来源和历史失败/成功保持完整。

## K. 实现与验证实录（当前空）

NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。无新RTL/模型/TB/功能脚本、无新EDA、无新bit/hex。当前仅本设计的数学上界和组合人工走查；原FIT实际证据只证明原FIT，本模块执行和软件产物待获准后登记。没有硬件操作、网络、数据库或正式节点转换。

## L. 交付与人工阅读

获批后按pkg/helpers→点统计单测→原FIT组合→真实probe→物理/时序→bit登记完成，再核文档/代码/测试一致性。阅读先本文B/C整体→D交接→E语句/旧沿与提交→来源附稿→验证附稿→未来work/docs实际代码符号与证据。成功路径就是源原点→四级→五项和→STAT632→NUM622→原FIT585→真观察→585次CRC，任何失配都要能回到源ID/ordinal而非只看LED。理解验收仍待真实用户反馈，不拿讲解代替通过；不以理解考试阻塞获批实施。

本稿不改完整十一项目标；角/投影、候选/支撑/去重、精确Canny滞后、实际DDR帧服务、相机/HDMI/CDC/阈值/冻结/叠加以及整包性能/资源/引脚仍须各自完整实现和验证。
