# TRACK4-ALGORITHM-CLOSURE-NATIVE-SERVICE-001：完整1080p闭包的目录、journal与关键路径成本 v0.1

2026-10-05。按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)紧凑填写；LOCAL_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本卡审查现有单S/no-cache候选的实际操作数量与性能限制，不修改算法、图像尺寸、原识别质量、采集模式或显示1080p60，不增设算法fps门槛。

## A. 通用计划、范围与来源

- Goal：把此前只列DDR byte的工作量补成同口径full AUTH、M1 holder、journal、许可/关闭及INIT账；分别给数量、架构条件下界和待取得的有限上界。
- Current state：R1软件范围已交付；R2 v1/48未批准；BK/CH两新卡已完成局部合同和定向读回，但完整性能/资源及真实DDR资格仍OPEN。
- Target state：每个实际共享实体和阶段取得真实服务上界，选定保留原功能/身份/关闭的优化后，联合冻结实现与验证基线；本卡不能替该步骤宣称实时性能已达标。
- Gap/Open questions：NS-B01真实native/DDR/consumer/调度服务；B02优化的实际权限保护/存放/关闭与全机资源；B03完整识别、SRC/GRAD与生产显示竞争及共同基线。
- Assumptions：N=1920×1080=2073600、P=N/2=1036800；一个S、普通opcode串行；沿用BK每span全查和两journal槽。100MHz只是换算示例，没有本范围STA。
- Dependencies：下表SHA与实际读取；原HDK、R1、R2冻结对象保持只读。前轮有真实新增设计与修订/事件，为PROGRESS，本轮不是活进程wait。
- Milestones/Detailed steps：B单位与观察→C独立实体→D数量→E关键路径证明/中文次序→F优化必要条件→G/H→实际联合冻结/READY→指定批准→work代码/有限验证/工具。
- State transitions：仅本卡LOCAL_DESIGN；正式节点/数据库/Manifest/硬件状态不改。
- Artifacts and hashes：本文hash在本地检查点记，不自嵌；下列来源不是新的已批准实现基线。
- Validation：源读回、精确整数和限定独立审阅；无业务代码、功能脚本、TB或EDA。
- Failure handling：实际服务未知就不填写成功上界；失败/Q保旧债，不能timer假close、删难例或缩图来加速。
- Human approval gates：R2现有待批请求不重复；本卡及后续性能优化未成熟，不申请实现批准。
- Rollback：只新增本文；任何未来结构替换均先保存设计版本、重核身份/追踪/服务并获指定批准，不能默换BK。
- Completion criteria：本文数量与条件证明可读回；完整目标仍需十一功能实际代码、仿真、综合、PNR/STA和bit，bit后不操作硬件。

| 实际来源 | SHA256 / Root本轮读取；其他读取另记事件 |
|---|---|
| [DDR服务v0.2](design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md)，353行 | `93C1E563F692A3C7E74020B436234B0481BD086CA4E9C6817849DED31A43A8B9`；219–271补读；此前原全文/修订有效，不称本轮新全文 |
| [BK v0.1](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)，210行 | `2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060`；本轮140–177，前轮原全文/全部delta；每op全查、单S、状态WE与源位置 |
| [R4C v0.3](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)，500行 | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；沿用前轮实际D3/D4/E8，不冒称本轮新全文；独立代理本轮另核台账 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，231行 | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；86–149；pin/descriptor各32词、M1/journal不同真实RAM |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，298行 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；180–237；快照候选/部分资源与服务，未采用 |
| [cold快照候选](design-TRACK4-ALGORITHM-STAGE-CACHE-RAM-001.md) | Root本轮1–44，仅确认边界、历史来源及未采用；本卡不凭此继承旧DDR/LG hash或cold服务数 |

入口/config/prompt/config/state/ledger/DB、模板与WORKFLOW本轮实际读；唯一规范v0.2此前全文有效，本轮hash不变，并补346–512适用契约/门槛。宽输出曾截断，需求A4–A6/正式workflow/DDR E5.1…F起点另小段补读。PostgreSQL连接未配置；纯文档不扩R1审计例外。

## B. 可观察要求与单位

NS-01保持逐像素全N最终EDGE和完整八邻域可达；NS-02每实际授权、native issue、AXI通道fire、typed操作和clock interval分开；NS-03共享唯一实体与阶段寿命证明才可加成本或并行；NS-04性能优化必须保原授权/初始化/latest/原子组/取消/RETURN/metadata寿命；NS-05未来实际有限完成上界与实测分别记录。

K是成功claim/pop数，B是实际合法邻居READ_CLASS次数：K≤N、B≤8K；neighbor_checks=8K不等B。下表快路径明确采用queue_ref0：无QUEUE grant/INIT。原R4C容许曾绑定非零QUEUE的快路径；那种路径必须另加真实INIT/RETURN，不能借本表删除它。

正常样例：同word两次合法claim各保邻bit，后一次在前一次真实reply/退组后重读；成本分别计两个opcode，不偷称一次全查。边界样例：全interior一强其余弱fixture；它检验闭包存储边界，不是假称真实R2 NMS会生成同图。未知服务或取消不形成正常成功帧率样本。

## C. 实体与连接

L/C typed→单S全AUTH→唯一O pin/descriptor/M1→实际span许可→S保护read/capture。读opcode直接END→449实际消费→后续关闭→下一ordinary；写opcode再走唯一journal准备/提交/读回→FPI/共享DDR→真实写效果结束→journal stateWE→END→449实际消费→后续退组→下一个ordinary。LOAD/EDGE各一entry，CLAIM两个entry/两span许可一次成对提交。M1 holder RAM、pin/descriptor banks、journal、PB RX和外部DDR各有自己端口与仲裁，不能把不同实体总issue直接写成clock。

这里O是目录owner，可信父为J-parent，journal为JNL，二者不能因都写J而混淆。G的未来observer只记录真实接口/native事件，不替DUT执行BFS、生成token或提供始终OK的DDR资格。

## D. 当前候选的同口径事件账

| 类别 | LOAD / READ_CLASS / CLAIM / READ_QUEUE / EDGE / PHASE数量 |
|---|---|
| GENERAL | P / 2N+B / K / K / P / 4（含LOAD的CLASS） |
| NO_STRONG、queue_ref0 | P / 0 / 0 / 0 / P / 2 |
| NO_WEAK、queue_ref0 | P / N / 0 / 0 / P / 2 |

普通一次LOAD full AUTH为pin32+desc32+LG56=120 RE issue；其它一次span为32+32+CLO22=86，CLAIM有两个span，计172。一次许可跨该op的保护read/write/settle，不重复给同一次write再全查；下一opcode重新全查。

| 数量（不含INIT） | GENERAL | NO_STRONG | NO_WEAK |
|---|---:|---:|---:|
| full AUTH次数Q | 3N+3K+B | N | 2N |
| O全查readissue A | 275N+258K+86B | 103N | 189N |
| 其中M1 holder readissue H | 83N+66K+22B | 39N | 61N |
| 实际普通write entry w | N+2K | N | N |
| journal prepareWE / readbackRE / stateWE | 29w / 29w / w | 同左 | 同左 |
| journal按操作阶段相串的事件数 | 59w | 59N | 59N |

journal端口账实际是WE=30w、RE=29w；真实1R1W并不普遍意味着两口不能同时服务。59w只在E的当前S阶段相串前提下可作为关键路径计数，不能给全机所有caller强行串行。

INIT只按当前q4/64B：CLASS8100chunk、QUEUE129600、EDGE4050；GENERAL I=141750，快路径I=12150。每chunk一个AUTH及一个END；其完整req/rsp/end/ack四个真实fire另计，不是四clock固定延迟。GENERAL A_init=12465900、H_init=3393900；快路径A_init=1320300、H_init=542700。CLEAR的prefix更新、许可注册/释放、捕获/check、消费、物理响应及独立phase/CH/RETURN仍另M；没有擅加一份CLEAR journal，也不删除初始化本身。

| 生产具体整数 | GENERAL dense K=2067604、B=16540832 | NO_STRONG | NO_WEAK |
|---|---:|---:|---:|
| 全LOAD+closure typed（含phase） | 26896844 | 2073602 | 4147202 |
| 普通Q / 含INIT AUTH、END各自次数 | 28964444 / 29106194 | 2073600 / 2085750 | 4147200 / 4159350 |
| A普通 / 含INIT | 2526193384 / 2538659284 | 213580800 / 214901100 | 391910400 / 393230700 |
| H普通 / 含INIT | 672468968 / 675862868 | 80870400 / 81413100 | 126489600 / 127032300 |
| journal prepareWE / readbackRE | 180055432 / 180055432 | 60134400 / 60134400 | 60134400 / 60134400 |
| stateWE / 相串59w | 6208808 / 366319672 | 2073600 / 122342400 | 2073600 / 122342400 |
| 数据bytes含INIT | 571844032 | 67132800 | 100310400 |
| AXI五通道fire含INIT | 77405812 | 10440900 | 14588100 |

全域几何上界ordinary A≤1221N=2531865600；它不代实际dense或成功处理时间。最坏几何w≤3N=6220800、journal事件≤367027200。API事务量、native事件、bytes和不同AXI通道握手可以有重叠，均不是同一个吞吐单位。

## E. 关键路径证明与中文草图

写opcode按旧事实经过：①O完整AUTH及许可全部正确→②S保护read并capture→③PREPARE该op全部entry全WE完成（LOAD/EDGE各一，CLAIM两个）→④单logical_commit→⑤当前entry全RE/capture/check→⑥物理写/真实效果结束→⑦该entry stateWE完成才换下一entry（如有）→⑧END前封postimage新读/冻结→⑨typed RSP实际消费/后续退组→⑩下一ordinary。读opcode仅走①②及真实END/typed回复关闭，不走journal或物理写；INIT独立chunk串行推进真实O prefix。不能在①完成前启动③，也不能把⑦写回与下一entry覆写assembly重叠。

在当前BK阶段串行、M1单20bit读口和每个journal阶段每沿最多一个本S issue的条件下，M1读取与本S journal的这些事件属于前后阶段，可给 `C_floor = H普通 + H_init + 59w`。不把所有banks都强行串行；仅M1本身即可给这项条件下界。末capture/check、permit/END/运输、物理、其他owner与消费者等待没有加进去，因此实际完成不能由该下界得到保证。

| 当前架构条件下界 | GENERAL dense | NO_STRONG | NO_WEAK |
|---|---:|---:|---:|
| M1与相串journal关键路径floor | 1042182540 intervals | 203755500 | 249374700 |
| 再限定O全native一次只issue一个时的更强floor A含INIT+59w | 2904978956 | 337243500 | 515573100 |
| 第一行/假设100MHz的纯尺度 | ≥10.4218254秒 | ≥2.037555秒 | ≥2.493747秒 |

这不是实测帧时间、不是有限完成上界，也不是用户接受的算法fps。若将O改为多bank并行，第二行不能沿用；若改授权复用/journal结构/普通并发，第一行也需按新真实依赖重推。它只证当前可核正确基线不能靠名义DDR带宽宣称性能最佳，不证明完整FPGA算法不可能或允许降标。

真正有限上界待取：`C_G≤M_G+P(s_LOAD+s_EDGE)+(2N+B)s_CLASS+K(s_CLAIM+s_QUEUE)`；两快路径分别去掉BFS项并保0/N CLASS项。各s包含真实μ/本地δ/有限consumer；M包括4/2 phase、BIND/INIT/CH/RETURN/CLOSE/PUB。M_INIT分别按三/两对象chunk×真实t_CLEAR，t包含AUTH/FPI写/effects/O prefix更新/END，不重复加已在s或M里的等待。没有冻结μ/M就不填写正常case成功cycle上限；错误timeout只诊断失败/Q。

## F. 优化选择与语言/资源契约

下一项性能选择必须先减少真实重复工作，而不是改N/K/B或提高一个未STA的clock。候选一是稳定scope权限/geometry的真实受保护快照：O完整核来源后建立、mutation/revoke先封新published并兑现旧held、dynamic initialized/latest/tail/原子组仍由真实S/O核、permit/RETURN与metadata退休独立。SC hot/cold只是未采用来源；不能把快照当省掉O、无future effect或无成本lookup。

候选二是本S小postimage的有限热存/更短受保护journal访问：仍保两完整postimage、身份、group/tail及known/UNKNOWN，不能删失败保留或原共享16×576的其它caller。须先给具体位置/端口/借用/替代扣数及全机预算；本卡没有选择新cache/压缩布局或修改BK29词合同。两候选的组合、直接命中比例和时序不可按愿望宣称提高多少倍。

RTL A–L：A所有计数非负、预算用足宽整数，未来硬件计数先65bit检查；B/C单core posedge旧fire，native/typed不同观察；D无效/错回复不增成功；E旧held与payload保持；F事件/interval/秒/clock前提显式；G warm不清seq/UNKNOWN、cold须共同隔离；H旧scope/config仍绑定；I实际1R1W/同址禁止/capture尾/短锁不等物理lease；J授权、物理、原typed namespace不互cast；K本卡单域不证明camera/PHY/video CDC；L Ti60F225/I3/现装SV2009工具，完整资源/STA未知。

本卡新增设计文档与整数账，无RAM/FF/DSP实现增量。BK21606与CH15792 selected不能直接当全机FF，也不能从器件剩余资源推出候选快照能装下。跨语言共同数值保持原全图集合gold；执行核真实native/事务/关闭，结果对应原JID/H/ref/version及完整N像素，host不由DUT摘要/计数生成期望。

## G. 有限实施与验证计划（全部NOT_RUN）

未来仅在联合指定批准后给真实S/O/JNL/FPI observer与独立scoreboard，原业务实现与工程按同基线构建；当前不生成计数脚本、TB或模型。确切文件/符号、rawtrace格式、seed、normal cycle/wall与mu前提须与BK/DDR/整包冻结，不先运行原tool去测未批新架构。

| TEST | 输入/独立预期与边界 |
|---|---|
| NS-T01 | 6×5和完整N/P，GENERAL及queue_ref0两快路径；从外部真实typed trace派生K/B/phase，逐op AUTH/JNL/AXI台账核D，不从term复制期望。 |
| NS-T02 | dense/斜链/断链/同word两claim；完整N gold与真实Q/A/H/w，同一claim两许可/两postimage不漏或重计。 |
| NS-T03 | M1、pin/descriptor、journal独立stall与捕获尾；核旧FSM相串的实际依赖，不能把同时不同bank事件强写为多个clock。 |
| NS-T04 | INIT每对象真实prefix/授权/END/更新；快路径若实际有非零QUEUE必须重计，不删除它。 |
| NS-T05 | held回复/END/CLOSE/cancel与known/UNKNOWN；失败不进入正常性能统计，但真实台账/保留和有限诊断仍检查。 |
| NS-T06 | 全camera/显示/识别并发、有限native/data/admin调度与完整实例；正常逐行期限与全job上界分别证明，最后真实map/PNR/STA/bit，不借R1局部结果。 |

## H–I. 追踪与门槛

NS01→原R4C/BK/独立全N oracle→T01/02/06；NS02→D单位/未来外部event observer→T01…04；NS03→C/E真实实体及旧沿→T03/06；NS04→F候选变化/BK关闭→T02/04/05；NS05→E有限μ/M与DDR R5→T03/06。反向未来counter/observer只承担以上真实事件检查，不能增加主机生产算法职责。

规范10.3的行为、实体、数量/局部草图、契约、计划/追踪有上述具体内容；NS-B01…03未闭合，无当前READY。文档保存/实际全文读回、整数/条件证明独立核及SHA检查点是设计证据，不是执行。R2 v1批准待回复不作为这些OPEN已解决的证据。

## J–L. 恢复、实录与中文阅读次序

本卡补充DDR/BK原数据预算之外的native metadata，并未改旧卡或冻结R2/R1。源版本/身份/结构/服务变化先修订，不能沿用本lower floor或旧授权。凡帧时间声称必须说明实际架构、被计实体、重叠与所有等待，不能把单S相串换成匿名并行或把rawfire数量换成core周期。

本轮仅当前资料读取、精确静态整数/代数、限定代理审阅和本卡；无业务RTL/模型/功能脚本/TB/EDA/bit/网络/硬件/DB或正式状态动作。用户理解验收待真实反馈。

阅读B单位与样例→C实体→D全部数量→E中文相串/条件floor与未知上界→F优化必要条件→G/H→I剩余。完整目标保持五项基础/六项高阶，当前不能以一项性能下界或局部资料发现宣布完成。
