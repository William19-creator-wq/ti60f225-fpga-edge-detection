# TRACK4-ALGORITHM-R4-STATS-001：点集统计与FIT交接设计 v0.1

2026-10-08；使用PLAN_TEMPLATE。状态：LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本文是实现前中文草图，只有文档；没有新增RTL、模型、功能脚本、TB、工程或EDA运行。

## 通用计划字段

- Goal：把R4已选择点集转成现有FIT所需的精确LS/TLS统计，接通点记录→统计→原FIT→结果这一段。
- Current state：FIT v1的19文件、14517数值、同源综合/布线/STA及bit已登记；统计生产端仍无代码。ANGLE v1.1尚待指定批准。
- Target state：可读的点流合同、完整统计流水线、原FIT真实组合验证及同源Ti60F225/I3软件产物。
- Gap：本稿内部草图已有，具体probe来源/独立审核、完整预算、最终基线及读回呈现仍需完成；不得将本稿当READY或实现授权。
- Assumptions：同域可暂停源，单统计上下文；来源点集已完成并按(y,x)严格递增，一次扫描条数E已知，0≤E≤W×H。筛选条件由上游固定，本文不选择候选、不改变旋转/遮挡/噪声/数量要求。
- Open questions：A2列本独立范围设计缺口；实际测试NOT_RUN是批准后的义务，不假装需要先写代码证明设计。
- Dependencies：根v0.2、模板、现行R3数值字段、R4 POINT与拟合统计定义、已登记FIT v1六份可复用RTL及独立fit_reference。
- Milestones：整体→接口→局部流水线→预算/来源/验证/追踪→保存读回→具体READY版本和基线→明确批准→代码/单测→真实组合→物理/bit登记。
- State transitions：IDLE→CHECK→RUN→DRAIN→PACK→HELD→IDLE；错误在原上下文保存首因并完成源关闭；共同冷复位作废单列。
- Artifacts and hashes：本文为新文件；冻结旧FIT/staging、旧设计与原HDK不改。最终输入manifest尚未创建。
- Validation：G为文字场景；数学边界分析、真实仿真、组合、资源/时序和硬件分别记录。
- Failure handling：错误统计不形成合法NUM请求；旧已接受点/流水线返回仍排完；未收到原上下文关闭不能伪造收尾。
- Human approval gates：需批准未来指定READY版本、范围、基线与本批本地审计例外。FIT授权不扩为本新模块；正式DB/Manifest/state/ledger不改。
- Rollback：未来独立work/active/track4_algorithms_20261004/r4_stats；当前不创建业务工作副本。旧来源保留。
- Completion criteria：完整本范围设计、实际读回及组合/预算自检后才READY；获批后所有适用软件证据和bit登记闭合。完整十一项另验，不缩成这个小包。

## A. 来源和阶段

关联A6、R4R统计/五遍圆/六遍TLS、R3 kind11/12/17/18。本模块供单次集合扫描；多候选、四边状态保存和迭代成员选择仍属R4调度。

实际来源：R3-FIT staging ALGORITHM-R3-FIT-20261008-v1（Manifest SHA0A58429E2525D667603441A309AD50782E38299723B9E2E6CD51ABB14E5C69C1）；fit_vectors.statistics/fit_reference.INPUT_FIELDS/evaluate；R3总设计D2/E4/E5；RECOGNITION-NUMERIC E4/E5；R4-RECOGNITION v0.2中的POINT row-major和FIT_STATS263/TLS217。旧目录/DDR关闭合同不自动成为本模块端口。

### A2. 本稿须闭合的设计事项

| 编号 | 下一项具体工作 |
|---|---|
| ST-B01 | 最终probe源/消费者的每个字段、递推、关闭、CRC、有限场景及独立重建方法；现在只有职责，不申请批准 |
| ST-B02 | 全部寄存器/有效位/旧FIT/真实顶层预算与形成沿；候选物理门槛尚待核对 |
| ST-B03 | 四种kind逐段成功/错误/中止走查、独立参考与完整1080p测试条数/种子/运行期限 |
| ST-B04 | 22文件范围、真实冻结输入及十项自检/读回/呈现；当前未冻结 |

生产DDR/相机/完整POINT提供者、候选质量与全机性能继续OPEN，但独立软件源可按本接口提供同样数据，不冒称真实生产链路。

## B. 整体行为

| REQ | 可观察保证 |
|---|---|
| ST01 | 一次START接受产生一个可保持的STAT_RESULT；原NUM_ID贯穿，冷复位作废分账 |
| ST02 | 圆LS：a=Gy，b=−Gx，d=ax+by；准确汇总n/A/B/C/D/F，不舍入均值、不拟半径 |
| ST03 | TLS：X2=2x−(W−1)、Y2=2y−(H−1)；准确汇总n/Sx/Sy/Sxx/Syy/Sxy |
| ST04 | POINT真实接受才推进原扫描计数；include=0仍是一条扫描记录，统计不更新；valid=0不是零点 |
| ST05 | kind11/12/17/18生成现有622位NUM请求，诊断不添加阈值或重新拟合几何；其余kind明确拒绝 |
| ST06 | 单上下文/流水线一有效点每core沿，无第二结果队列；旧valid/payload保持至fire |
| ST07 | 同ID END/ABORT关闭源token通道；旧算术排完后形成结果。错误不清在途有效性，已HELD不重写 |
| ST08 | 精确全宽加法及写前资格，原字段边界不变；原FIT六RTL/参考字节复用，不再加第二scalar |
| ST09 | 独立统计参考、真实原始token账、真实FIT组合及全N场景；工具与bit只在获批后执行 |

W偶数6…1920，H5…1080，生产1920×1080；E≤N。每点x<W/y<H，Gx/Gy∈[−1020,1020]。零梯度是一行合法零LS贡献，仍可include并计n；是否筛除由上游负责，FIT自行判退化。TLS仍接收同一合法点格式，梯度不参加其数学。

正常例：三条不平行法线→LS统计→完整622请求→原FIT求中心。空集合E=0→START/END0→成功统计n0→原FIT返回LOCAL_REJECT/COUNT；不能把空集合伪装成合法拟合。中止例：已接受点先排流水线，ABORT以后不累加，输出CANCEL_DROP；原先已有首错则保存原错误。未有END/ABORT的开放源不会因计数等于E就宣称已经关闭。

## C. 职责和交接

可暂停点源（未来R4选择器）→IF01有序token→stats_core检查/流水线/五累加器→IF02统计结果→调用适配者→原fit_core→NUM_RESP585。

stats_protocol_pkg只定义token与统计结果；stats_core拥有当前配置、计数和累加器；原FIT不读点、不选成员。stats_probe_top作为独立软件/物理源、单槽交接与真实消费者。模型直接对接受点集求整数和；TB记录真实fire，不从DUT累加器生成期望。

STAT_RESULT632与NUM_RESP585是不同语义。成功统计带的是NUM_REQ622；不能把相同kind的统计数据当原FIT几何响应。后续适配者只在统计结果VALUE时发NUM请求，失败直接形成原身份错误。是否关闭DDR/POINT对象仍由R4负责；END只关闭本token通道。

## D. 接口布局与组合检查

IF01 input token_valid/token_body262，output token_ready；IF02 output stat_valid/stat_body632，input stat_ready；共同clk/rst。另output fault_active/fault_reason8，用当前sticky首错提示源发原ID的END/ABORT；不是第二请求/应答通道，无ready或另一份缓存。

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

源必须在START之后最终提交END或ABORT，关闭fire后不再发布本次POINT。want cancel时先兑现已发布POINT，再发布ABORT；END已经fire后不再通过ABORT制造新义务，外层caller接收并丢弃尚未消费的统计/拟合结果。单源普通冷复位必须与核/适配者/消费者共同进行。

ready只依当前容量和状态，不能依消费者释放别的对象。HELD完整632位不变；RUN可接一token/沿，CHECK和关闭后的DRAIN/PACK/HELD不接新token。END后管线排尾不依stat_ready。输出fire之后下一状态才允许新START，当前上下文不与旧累加并存。

## E. 内部数据与中文语句草图

### E1. 状态与拥有者

IDLE等待START；CHECK核锁定header；RUN消费POINT或关闭；DRAIN等待四级旧有效性清空；PACK读取已最终提交的统计，形成冻结结果；HELD保持至fire。header非法仍进入错误RUN，让源兑现已发布POINT并发送END/ABORT，不能立即丢下已发布数据返回空闲。fault_active在错误记录后至该结果消费为1。

当前header、Raw POINT接受数u22、include统计n21、上一合法x/y各11及资格、五个逻辑56位累加槽、四级数据/valid由核拥有。没有历史点列表、全帧RAM、第二上下文。START清n/五槽/计数/资格；共同rst清有效性，旧pipeline数据可不清，因为无valid不得读取。

### E2. 每个点：接受→乘积→完整累加

1. 本沿POINT fire先按旧header/旧seen/上一坐标检查。raw seen用扩23位加1，不回绕；合法序号必须等旧seen。接受记录完整计账，即使include0或该帧已有首错。
2. 只有合法且include1、尚无首错的点进入有效数学pipeline。输入时a=Gy先扩s12；Gx先扩s12再取负为b，不能先在s11对最小值取负。x/y作为非负s12。X2/Y2先在s13形成2x−(W−1)，核真实域再收s12。
3. S0保存a/b/x/y/X2/Y2及所需伴随；S1用五个s12×s12乘法分别形成p0/p1/p2和ax/by。p0…2由当前模式选择(a,a)/(a,b)/(b,b)或(X2,X2)/(X2,Y2)/(Y2,Y2)，完整s24注册，平方非负才作unsigned解释。
4. S2先扩s25相加ax+by形成d；S3的两个s12×s25乘积形成ad/bd完整s37，TLS时不使用它们。原p0…2及X2/Y2随相同valid移到提交。pipeline每沿推进，不受外部stat_ready影响；气泡只清valid，不新增点。
5. 在S3之后的提交沿，按模式选五个完整贡献。LS选(a²,ab,b²,ad,bd)；TLS选(X2,Y2,X2²,Y2²,X2Y2)。五槽旧值及贡献先扩s57再相加；n先扩22位加1。逐字段核资格；任一失败整点五槽/n都不写，记录OVERFLOW8（n>N为COUNT7），不留下部分成功。
6. 合法时一沿同时提交五槽与n；后一个点只读沿后新统计。五槽共享LS/TLS的实际寿命，当前mode保持，不能把两个不同候选同时混入这组槽。

四级S0…S3加提交：POINT在t0接受，t1/t2/t3进入后级，t4完整累加；RUN稳态一有效点/core沿。last POINT为te−1、END于te接受时，最后累加到te+3；DRAIN下一沿才能判断旧pipeline全空，再PACK，stat_valid候选在te+5形成。精确逐沿/参数上界须ST-B02再核，不把候选当已测。

### E3. END、错误、中止及输出

先记本沿旧token fire/旧pipeline提交；更早的提交错误先于新token错误。有效同ID ABORT沿停止后续提交，旧DSP有效性仍自然排尾；已有首错保留，否则最终DROP。ABORT同沿的被丢弃算术不制造新的业务结果或取代取消原因。END不丢合法旧点，要等最后提交完成。

DRAIN中不接受新输入，继续消耗所有旧pipeline项。确认旧valid全0后才PACK；PACK读上沿最终n/五槽。成功以原FIT字段逐项打包，所有unused/payload高位0；错误或DROP的payload全0。HELD期间fault/body/ID不变，普通源追加非法token不会被接纳。共同rst可作废held/pipeline，真实账按reset另列。

### E4. 数值资格与范围（设计分析）

| mode | 输出n及五字段 | 点贡献 |
|---|---|---|
| 11/17 | n21/Au43/Bs44/Cu43/Ds56/Fs56 | 三s24产品（平方非负）及两s37产品 |
| 12/18 | n21/Sxs33/Sys33/Sxxu43/Syyu43/Sxys44 | X2/Y2s12，三s24产品（平方非负） |

N2073600/G1020时：|d|≤3057960；A/C≤2157373440000；|D/F|≤6467805573120000；|Sx|≤3979238400、|Sy|≤2237414400；Sxx≤7636158489600、Syy≤2414170137600、|Sxy|≤4293598233600。分别落在原字段范围。此为保守上界，不证明实际FPGA资源或帧FPS。无除法、平均、RNE、饱和、截断；只在资格通过后收原字段。

## F. 语言、存储和预算候选

SV2009/整数Python；无C++。组合阻塞且完整赋值，时序非阻塞；多项统计同沿原子写入，不能套用FIT的单工作槽写规则。五个逻辑56槽共280bit、n21；header/seen/row/状态、四级完整伴随与632结果另算。六份原FIT RTL、原一份private scalar、复位及source/消费者全部纳入联合预算，不能简单再加一份旧scalar。

候选独立联合物理门槛：Ti60F225/I3、25MHz，XLR≤56000、RAM0、DSP≤32；具体全体容器须ST-B02核清再冻结。DSP候选五个12×12、两个12×25及header W×H；实际映射由工具报告判断。无需DDR或外部模块支持本次点流试验；完整生产存储需求不被撤销。

RTL A：上表及先扩后算；B：同上升沿、TB负沿驱动/正沿计火；C：token/out fire独立；D：include与valid分开；E：保持body与排尾；F：四级+提交/END后形成候选；G：共同同步高有效rst、单端复位不合法；H：START快照、换配置不影响旧点；I：五槽/四级/一结果，无全帧存储；J：NUM_ID/ordinal/(y,x)/E/n分别计；K：本核同域，生产CDC属于后续适配；L：上述候选预算，真实工具NOT_RUN。

三份跨语言契约：数学模型直接对相同include集合求五项整数和；硬件模型另核真实接受、旧沿、pending、END/ABORT/held/reset；对应关系以原NUM_ID和ordinal/源坐标绑定，而非仅比较最后CRC。STAT632与NUM585分账，成功统计真正交给原FIT以后才比较几何结果。

## G. 拟实施文件与验证（未运行）

候选22份：9 RTL（原FIT六份scalar_protocol_pkg/fit_protocol_pkg/scalar_core/scalar_bridge/fit_core/reset_sync原字节；新stats_protocol_pkg/stats_core/stats_probe_top），3 model（原fit_reference原字节、新stats_reference/stats_vectors），4 TB（helpers/core/真实stats_fit组合/probe），3运行支持（sim/build/postroute），3工程（xml/peri/sdc）。独立work，原源码不改；主机工具沿用已装Questa2024.1/Efinity2026.1.132/Python3.14.6/pwsh，无联网安装。

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
| ST-T11 | probe来源/完整统计/原FIT结果/真正585位CRC；具体生成和数量仍ST-B01 |
| ST-T12 | 真fatal非零/finished未置位、同源hash、综合/布线/STA真实D端/合理4pin，必要检查通过才bit |

手算全N TLS：Sx=Sy=Sxy=0，Sxx=N(W²−1)/3=2548038988800，Syy=N(H²−1)/3=806214988800。全N LS令Gx随y奇偶为±1020、Gy随x奇偶为±1020，W/H均偶：A=C=2157373440000、B0，原FIT中心Q4=(15352,8632)、quality65535。这是typed数学fixture，不声称实际Canny必产生全图边缘或该梯度。

## H. 双向追踪

ST01/06/07→核状态与token/STAT接口D/E1/E3→core/probe/T05…08；ST02/03/08→流水线及五槽E2/E4→core/参考/T01/02/09/10；ST04/05→资格/include/pack D/E→pkg/core/参考/T01/03/04/05/09；ST09→原FIT复用/模型/runner/工程G→T09…12。实际符号/证据仍待批准实现，不用空实现行号填表。

## I–L. 当前门槛、恢复与交付

已有整体、接口布局、局部中文语句、数值边界和候选实施顺序；ST-B01…04仍未闭合，保持NOT_READY。下一允许动作是纯设计补齐来源/消费者、预算/有限验证和输入基线，实际读回/组合检查后呈现具体版本。当前没有本模块实现批准，不创建业务文件，不运行EDA。

恢复读本稿、FIT冻结来源、现行规范与真实批准；影响接口、流水级数、模式并行/共享或预算门槛的变化先修订设计。获批后按pkg/helpers→点统计单测→原FIT组合→真实probe→物理/时序→bit登记完成，再核文档/代码/测试一致性。理解验收仍待真实用户反馈，不拿讲解代替通过。

本稿不改完整十一项目标；角/投影、候选/支撑/去重、精确Canny滞后、实际DDR帧服务、相机/HDMI/CDC/阈值/冻结/叠加以及整包性能/资源/引脚仍须各自完整实现和验证。
