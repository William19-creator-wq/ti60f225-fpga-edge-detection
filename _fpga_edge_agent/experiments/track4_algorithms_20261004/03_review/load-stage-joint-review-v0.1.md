# LOAD/GRAD 与阶段权限的联合读回核查 v0.1

2026-10-05；READ_ONLY_DESIGN_REVIEW / NOT_READY / NOT_APPROVED。本文只记录读回、数值和组合反例；不生成业务源码、模型、功能脚本或TB，不执行新仿真/综合/布局布线。R1实际交付保持独立，整包十一项仍未完成。

阅读先看§2完整路径与分支，再§3接口/状态/容量，最后§4问题及§5后续。原来源字节不修改；LOAD待修的审批门槛与本次已经读到的版本分别保存。

## 1. 实际来源与范围

| 来源 | SHA256 | 本轮实际范围 |
|---|---|---|
| [LOAD-GRAD v0.1 修前精确快照](../../../planning/design-TRACK4-ALGORITHM-LOAD-GRAD-001-v0.1-before-readiness-review.md) | 25AFA46EAF11F59C1F2942708E803DCEE3C84B609619B27C2FA8C10E6804B22D | 修前387行，1–109/110–207/208–330/331–387分段全文；64243B；作者修订后原字节由此快照保留 |
| [STAGE-CAPABILITY v0.1](../../../planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 | 298行，1–104/105–210/211–298分段全文；43441B |
| [资源时间缺口审查](production-resource-gap-review-v0.1.md) | 3785F7187E1F1537DBC2B3DCB9EE0A7777D43B11B8F573AEE992FF7F75CED585 | 191行，1–104/105–191全文；逻辑body不冒充FF |
| DIR v0.1 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA | 本轮D1…5实际字段、独立source创建/lease/holder/pin；沿前序审阅范围 |
| PERFORMANCE v0.2 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 | 本轮D5/E1…3/E9；原logical op口径及新HIST候选 |
| R4R v0.2 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 本轮object/格式/HIST定位及253–292原坐标/峰/TLS；未冒称本轮原算法全文复审 |

根规范v0.2与模板沿本轮入口顺序读取事实；没有重新批准未来实现，也未升级数据库/硬件/正式表。当前新PURE附件的最终hash在独立进度快照登记，不将本报告摘要自包含。

## 2. 整体交接读回

正常单作业：旧完整SOURCE311/J657及同admission/KEY/PCTX→真实BUILD_BIND→单scratch C/G ALLOC→LG1119完整注册/BINDING→SRC、CLASS、GRAD三provider各自一次真实绑定/初始化→父消费准备/ACTIVE→CJ→唯一C0/FE→实际FP/CLASS/GRAD→父独立CS槽/三seal→三支分别关闭→GRAD无writer后O publication→真实tokens/term→CLO/RC→所有原义务及metadata退休。

必须逐层区分：ALLOC建立build不是grant；REGISTER保存body/预算不是ACTIVE；READY不是CS；CS不是全图存储token；访问pin RETURN不是source base/共享lease/private对象退休；CLASS close不是wholeholder close。两个新增数据provider各depth1，真实读取/写入与其reply独立，不因上游FP/GRADready低就不能接存储回包。

失败同样有完整路径：先记触发沿旧fire→停新publication→兑现旧held与实际effects/reply→锁真实cutoff→子scope quiet→真实RETURN/ACK→该子CLOSE_ACK→保原终态/运输→metadata汇合。UNKNOWN/Q、partial分配/返回、错echo不变为canonical FREE；不以timeout/安静清债。

## 3. 具体组合检查与条件算术

| 检查点 | 两卡实际相容内容 | 仍需联合冻结的边界 |
|---|---|---|
| 身份 | 原H160含operation0合法；独立非零stagegen/revision/grant，namespace参加匹配 | 完整原provider内部桥与global allocator/epoch恢复来源 |
| 注册wire | LG1119/ACK1195经可信adapter转SC BEGIN218/WORD28/ACK291，不能cast | SC BLOCKED2与LG非法2的映射、原expected/partial ledger仍OPEN |
| pin建立 | REGISTER只cold与quota；原S CLASS BIND真实授一次，SRC/G各独立provider授一次 | O ALLOC/INIT/READY/实际ACTIVE与失败退休需具体实现设计 |
| 独立关闭 | CLASS ACK502只scope1，SRC/G别债保留；O RETURN_ACK先于依赖它的CLOSE_ACK | 可信old-held白名单、LOCAL_ACCESS_QUIET完整证书与admin资格桥 |
| GRAD publication | P写→真CS→GC CLOSE/RETURN→正确ACK消费→O COMMIT245/ACK319→GC term691 | COMMIT retained LG/真实封存ledger、全N/init/version、admin本身保持至metadata退休 |
| POINT publication | accepted原COMMIT保admin，先排数据/返writer，后immutable/token、新独立read grant | 原RC数据quiet与admin quiet分离、ANN/RECORD类似phase通知未全列 |
| ordinary权限 | 新SC仅kind3 ACTIVE有cachehit提案；STORE动态prefix/tail/latest/atomic仍真实 | 旧DIR D3全文路径并未已被实现替换，非stagekind仍全查 |
| 工作量 | retain1在旧13N+4之外添SRC P、G P+1，总29030405 logical；retain0添P总27993604 | 每logical对应raw span/lookup/NUM/初始化和M_i，不是DDR beat或周期 |
| 数据游标 | GC accepted ordinal、next input与stored prefix分离；SRC由真FPfire推进i | 两scope公平/finite service及真正RSP/FP/GRAD槽唯一位置 |
| 相邻请求 | SRC μ+4、GC μ+3仅无其它停顿的结构下界 | μ不得默认1或当成功最坏上界；不设新增算法fps |

冷体独立核：LG1119/20上取整56词，CLO438为22，RJ2257为113，共191词3820nativebit、body3814/padding6。M1原RESULT282词后LG282…337、CLO338…359、RC360…472，剩39词；保一个真实1R1W共享端口，不给每owner免费一读。目录已用101408、可address104448、nominal112640bit三种量不互换。

SC现32×295 cache=9440bit；三LOAD/GRAD+三CLO+26RC刚好32，四32bit mask=128。root新增可选H1实体若保留原所有pin，则需33cache/四33bit mask，最少新增299 selected bits，原LOOKUP中object26非法必须新内部族/来源delta；不能直接挤掉旧HIST或把新descriptor45当已可访问。该变化仍候选，未吸收入本两卡。

已列175 RAM只是partial实例账；63191是有明确存放假设的逻辑body，不是测得的FF。SC15845selected包含9440cache与assembly/lookup等部分，也不是完整总FF/XLR。共享冷体不会删除actor原held/private/expected；新窄消息与冷cache将由独立附件明确改变接口/服务后才可扣原实例一次。

## 4. 已发现问题与处理

JS-R01：LOAD A3把LG-B08“正式审批后的仿真/资源/STA证据”列当前BLOCKING，I又要求B01…08全关才READY，造成先实现再批准的循环。审批前应闭合的是独立参考职责、场景/覆盖、文件/工具基线、判据与设计审阅；实际源码/运行/STA/bit按批准后的计划取证并保持NOT_RUN。已通知作者，当前25AFA版本供完整读回保存；待其完成并行只读审阅后，通过纯文档修订、精确旧快照保留纠正。其余B01…07有具体接口/资源/恢复缺口，不因纠正这一项自动READY。

JS-R02：H1新目录位置与SC缓存容量不是同一资源。已在root H1增量D2/I明确33cache/299bit和old公开object26仍非法；32cache模型不得直接连H1。实际新内部opcode/tuple来源、stage body与pin上界共同版本仍OPEN。

JS-R03：原HIST旧候选与camera ring物理重叠。root新候选把H1放AUX未分配尾87722880…88247168并留64B guard，原21private/三RECORD/ring不移动；全128MiB arena包络不扩大。它只是静态地址解决候选，原H0算法和旧来源保持，H1是否采用/完整service和provider尚未冻结。

JS-R04：阶段cache大幅减少cold读取的同时新增较大身份快照。可新提20×512冷cache每295bit占15词，32行480词/33行495词，但需300bitassembly、真实端口/捕获/padding/最早时序；不能保原hot hit4interval或以capacity说明lookup已运行。资源owner已获新纯设计委托，原SC hash不改。

## 5. 下一步与结论

先保存B08门槛修订及完整旧快照→核metadata窄消息/冷cache实际字段与服务→核单CONTROL/ROW/RX/DDR引擎连续行、两首行/row1和camera/COPY公平→逐operation/NUM/phase完整矩阵→独立quality参数与PROFILE→联合文件/基线审阅。新H1如选择则明确全部接口/容量delta；不能只选地址。

本轮结果为**完整读回与上述局部接口候选相容性核查，仍NOT_READY**。有字段/数值和反例事实，但无新功能测试/工具PASS。实际现R1软件验收及bit登记继续有效，不重新问同一批准；完整Canny/识别/生产输入输出与全机资源/服务、最终联合实施仍未完成。

## 6. B08 作者修订后的限定读回

作者仅修验证门槛文字，当前 [LOAD-GRAD v0.1](../../../planning/design-TRACK4-ALGORITHM-LOAD-GRAD-001.md) 为67457B，SHA256 `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；本报告原全文审阅绑定修前精确快照，不将新稿称再次全文重审。根代理实际以两文件逐行 Compare-Object 读到全部新增/删除文字，并复核旧快照仍64243B/25AFA…。

修后 Gap/Completion criteria、A3 LG-B08、G验证准备、I⑦⑧及READY说明明确：审批前具体冻结独立模型职责、场景/覆盖、方法、文件/工具基线、判据和设计审读；实际源码、向量、仿真/综合/STA为正式批准后的执行，继续NOT_RUN。K保存此次问题、授权仅纯文档修订及旧快照事实。JS-R01的“先执行再批准”门槛循环在这些读回段已纠正；具体LG-B08验证设计仍OPEN，LG-B01…B07真实设计缺口没有消除，两卡和整包仍NOT_READY。

同次实际读回 [QC/H1独立审阅](quality-and-hist-contract-review-v0.1.md) 全135行，SHA256 `28BFAA2A1E51CA66AA04487F11BC844B265BA11EA3F7C4B2012E6417958E9EC6`；并定向实读QC修后L73–112/176–186、H1修后L54–68/94–111/124–130及新H1 JSON全文。QC当前C7A9…将原像素中心统一为16x/16y、主质量单独计192 ACCEPT；H1当前51A7…明确CLOSE_REQ→data quiet→实际RETURN_ACK→CLOSE_ACK，保持候选未采用。该限定核查消除三个明确文字反例，不代替未执行的软件质量、资源、服务或整机实现验证。

## 7. 冷权限与ROW引用的限定联合审查

根代理随后实际全文读 [STAGE-CACHE-RAM v0.1](../../../planning/design-TRACK4-ALGORITHM-STAGE-CACHE-RAM-001.md) 的335行（1–115/116–230/231–335），46599B、SHA256 `487576F7A4DE4B0C3CBAB21ADDF09271ABD1C1E6E1BE6C9DD2BC5146697277E2`；实际全文读 [METADATA-TRANSPORT v0.1](../../../planning/design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001.md) 的257行（1–116/117–208/209–257），34341B、SHA256 `6764FD3115B10BF63FECC289B590CFAE29A106FA7BC0640D4A0DB39A12CF339B`。两项仍未采用、未批准、未实现，原SC/ROW合同的字节没有被缩写候选改掉。

冷权限卡在单20×512 RAM里把32份295bit分别存15词，真实末高5为0；32行480词，可选33行495词。默认仅扣原9440热body一次，新增300bit assembly、32hot-valid、43sequencer，得到同一已列口径6780selected bits。它保留原四grant masks和全tuple/metadata债，并将原hot最早4请求间隔显式替换为21沿最早响应、23沿最早下一接纳；INSTALL增加15WE及15RE核读、36沿最早回复/38沿下一任务。该时间变化必须在后续实际逐operation账中承担，不能同时享受冷存节省和旧hot吞吐。单任务首fire到末response的实际窗口与连续槽间隔也已分开。

可选H1多一行时，同RAM容量可容，原四mask各加1及hot-valid加1，有限口径6785；它不是完整H1资源或授权。CR-B06是**可选H1范围**，若共同版本明确默认32、禁用H1并保原H0数学，该未来缺口无需阻默认32的READY；当前B01–05/07仍有真实接口、身份存放、级数、服务和恢复缺口，所以本卡现在仍不能READY。不得因隔离未来范围而删默认32的现存义务。

ROW候选只换四族，原472完整身份保持两RAM镜像，core/pair各一真实reader/assembly，源472稳定lease保至WRITE_ACK消费；消息sourceheld/destinationprivate继续独立。其6345selected bits代原11508body的条件算式为63191−11508+6345=58028，另增2RAM。双镜像24WE、核读24RE后COMMIT，再发布引用；query末capture后完整检查，响应最早30本域间隔、下一31；这不是首行/连续行期限的证明。data bank RETURN与metadata FREE分开，MD_QUIET不等待自己的ACK先消失，真实两域读/运输quiet后才允许重写镜像。

这些部分算式互相可能包含同一CONTROL/O/state职责，必须以真实唯一存放位置合账；不能将58028、6780和其它局部直接相加或相减作为实测FF。所列部分177RAM也未同时纳入所有新方案：若明确同时采用两项，应再为权限RAM计一次，仍只是部分178，不能据256上限宣称整机fit。完整期望/permit/admin/旧promise、原目录与DDR公平/时序和生产所有端口仍需闭合。批准前评审的是具体设计、预算和验证准备；实际新增RTL/仿真/STA在指定批准之后执行。

## 8. EXEC长READ许可候选的独立读回

根代理实际全文读 [EXEC-BULK-CAPABILITY v0.1](../../../planning/design-TRACK4-ALGORITHM-EXEC-BULK-CAPABILITY-001.md) 的299行（此前1–108、本次109–208/209–299），51018B、SHA256 `2FC82DB887BA972A45D5F39B613C42AF5892DECF53DB23E25086039F666031F1`。它只提出kind2 EXEC不可变普通READ的独立许可，仍NOT_READY/未采用/未批准/未实现；旧RAW短许可、kind3权限、单独REPLAY、COPY/camera/writer不被暗中扩大。

明确新范围是实际1…128个16B beat，即16…2048B：新REQ662/RSP1012、length12/end33，页内加法先扩13bit，不能复用旧length7或先截地址。四份完整CTX840/J657/OPEN387/borrow64共4×98词，独占新20×512 RAM；十二plane328、四header395、五行guard259及各端真实held/private的已列热量为13808 selected bits。初始化/合法来源保护、真实pin捕获、mutation fence和关闭运输仍需接线，cold稳定不自证实时授权。

普通许可最快e0接纳至e6真实回复，单permit直到实际AR/R/RX/decoder/route及PERMIT_CLOSE关闭才能再授成功。真实旧FETCH publication保旧caprevision与full grant，STOP不撤旧承诺；RETURN/正确ACK先于依赖pins_closed的旧BULK_CLOSE_ACK，最后metadata真正quiet后FREE。该路径避免“关回执等返pin、返pin又等关回执”的循环，但并未实际运行。

原每burst至少32 pin词+32 descriptor词+23 loan词=87 RE issue；最坏行八burst至少696仅为条件issue尺度。新最快八次6=48也不是服务上界，不能把190拍余量减48后便宣布1080p60通过。长许可/close、旧MR/FETCH/TERM、跨域、仲裁、真实R间隙与decoder均须计入最坏值。若未来明确同时采用冷权限1RAM、ROW双镜像2RAM和本卡cold1RAM，则在已列175部分口径上是179RAM；各局部逻辑body仍可能重叠，完整FF/LUT/DSP/时间没有由这个加法得到。
