# QUALITY-CORPUS / HIST-PLACEMENT 独立合同审阅 v0.1

2026-10-05。纯设计审阅；`NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN`。只写本记录，不改被审两卡、JSON、LOAD/SC、旧规划、原资料、R1、入口、状态或数据库；不生成模型/业务源码/功能脚本/TB，不构建、不网络/安装/硬件操作。

## 1. 实际阅读与结论边界

入口 `_fpga_edge_agent/AGENTS.md` 本任务重新全文读取，SHA `6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937`。其六份有序规则/运行配置/状态/ledger/数据库说明已在紧邻前任务实际依序全文读取，本任务复核hash未变；唯一根v0.2原已全文读取，复核SHA仍 `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`。本轮没有执行其中未授权的数据库或硬件操作。

| 本次修前实际读取来源 | 审阅绑定SHA256 / bytes | 范围 |
|---|---|---|
| [QUALITY-CORPUS v0.1](../../../planning/design-TRACK4-ALGORITHM-QUALITY-CORPUS-001.md) | `C22F73AF8422DC617B452728986C89832A49344DBB1A6255F365BCAE78D841A3` / 25466 | 全216行；首次合并工具输出截断的后段另读L138–216补齐 |
| [HIST-PLACEMENT v0.1](../../../planning/design-TRACK4-ALGORITHM-HIST-PLACEMENT-001.md) | `ECE49082F6249132F48C1D0E9E0236A401BAA39B88849C2A45167108CD1DEFD0` / 16647 | 全147行；L1–90重新完整读取，L91–147实际读到 |
| [新H1纯布局JSON](../01_baseline/production-hist-placement-v0.1.json) | `A4CBE7FF910852A07D7E7FE0B1C10528DAF005A2840971B0252760A58AEA30FA` / 3269 | 全文；选择PROPOSED_NOT_ADOPTED、全部范围/guard/实体/缓存增量 |
| [原slot布局JSON](../01_baseline/production-slot-layout-v0.1.json) | `9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75` / 11516 | 全文；21 private、3 RECORD、FIT_STATS末padding/guard、AUX尾 |
| [R4R v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | `AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257` / 83901 | 本轮定向L65/72/78、134–155、210、229、257/266/286、346/353；完整L390–420。没有本轮全文重审 |
| [STAGE-CAPABILITY v0.1](../../../planning/design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7` / 43441 | 紧邻LOAD任务已实读L90–151；本轮定向L146/156/172/176/178、198–218、232–245/262；仅实际范围 |
| [PERFORMANCE v0.2](../../../planning/design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | `A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469` / 58487 | 本轮定向L182/183、302/312/356；前任务已有限实读E2，不把旧H1候选称现行布局 |

上述hash绑定本记录审阅时读到的版本。其他来源hash若只出现在被审卡的引用表，未在本轮实读则不列成自己的已核来源。原来源表里INTEGRATION/DIR等详细来源核验由根代理负责，本记录不代签。

结论：H1新地址的静态算术与JSON一致，候选保留旧布局；GT独立、失败FN、精确最大基数和不恢复hard admission的主要方向与原R4R一致。发现两项QC合同需要澄清/修正，另有H1关闭顺序歧义及若干已明示OPEN的联合接口缺口。没有图像/GT/质量95%、算法等价、全机资源、周期、综合或布局布线通过证据。

## 2. QC：GT独立与质量主合同

### 2.1 原文已明确覆盖的保证

- QC L41/65/73/87/95–99：scene owner在看识别输出前固定原几何/语义/遮挡；GT不从DUT候选、POINT、ANN或score拟合；GT不送DUT；预测只由合法完整结果形成。软件与RTL分别评价，不复制软件P/R。
- QC L87：是否进入GT只在遮挡、擦边、噪声前按原filled/outline谓词检测画内像素中心；已有至少一个则完全遮住、同背景色、低对比仍保留。这个预先规则不能改成noise后轮廓、可见mask或阈值admission。原形状没有画内采样只作环境描述，不能冒作画内可识别目标。
- QC L81/121/123/128–136：96–768、比例≤3、最多4、对比≥64、纹理/噪声/20%遮挡都未恢复为硬门；取样含更小/更大/更多目标、更低对比和更强扰动；整短/长边缺失单列；自然CAPACITY/SEARCH失败仍留主集，不能事后迁STRESS。
- QC L51/131/183：同RGB的三边矩形/U负例可有不同原语义GT，保留成对歧义且如实统计；固定主集95%目标不是对任意图像的理论全正确保证。
- QC L97/111/136/148：失败/取消/Q/SEARCH/CAPACITY无合法预测前缀，GT全FN；零GT失败虽然不新增FN/FP，功能失败仍单列，不能借P/R遮盖。故意协议注入的STRESS预先分组，不混入主质量；主集自发失败必须计。

GT bbox沿原R4R L155的floor最小/floor+1最大/clip半开整数规则，而非ceil或噪声后tight-box；原geometry不被signed18域筛掉，越域候选的FN保持。对原可观察形状，非空bbox条件仍应由同一坐标基准证明，不能在parse中删除GT。

### 2.2 QC-R01：合成采样与R4坐标基准缺失

确定原文：QC L77把像素中心写成 `(16x+8,16y+8)`，原Q4中心/角点同时用于RGB生成；QC L89直接把该原geometry依R4 bbox公式作GT；没有scene-edge坐标到R4-index坐标的变换。原R4R L266逐POINT径向量使用 `16x−cx`，L286像素面积窗是 `[-8,16W−8]×[-8,16H−8]`，对应像素中心 `(16x,16y)`。

最小静态反例，filled圆 `cx=cy=160,r=12`：按QC+8中心，(x,y)各9/10的四采样点均有距离平方128≤144；图像在索引域的中心为(9.5,9.5)，原GT中心仍(10,10)。改r=8则QC+8四点平方128>64，没有任何原画内像素中心、L87会排除GT；R4 index中心(10,10)距离0却有画内采样。这个区别无需DUT输出便存在，影响小/亚像素目标、原GT可观察事实和bbox对应。

这是坐标合同尚未对齐，不是要求GT从DUT拟合。建议根作者二选一明确采用：全部scene/Q4几何遵循R4 index中心16x/16y；或保留edge-origin scene基准，但GT供预测比较的canonical几何及bbox明确各轴−8，原scene几何仍保留，并统一原可观察谓词。需同步QC D1/D2/T02/T07及manifest/schema，不能只在matcher默减半像素，也不静默改原算法。

### 2.3 QC-R02：主P/R聚合split歧义

QC L109“每类累计跨全部指定split的TP/FP/FN”未明确是各split分别累计还是混合；QC L148又核192个ACCEPT主条目。后者方向正确，但不能让runner根据前者把DEV或STRESS用于主门。

具体反例：DEV该类80TP/0FP/0FN；ACCEPT该类19TP/2FP/1FN。ACCEPT precision=19/21<95%、recall=19/20恰95%；混合为99TP/2FP/1FN，precision=99/101、recall=99/100均通过。开发数据把真实验收失败掩盖，违反QC03。

建议明确每split独立账本，主门仅完整预先冻结ACCEPT；DEV、STRESS、combined可显示但不得参与主PASS。同样每family细分、无分母NA与functional_fail独立保留，漏frame/auditfail不从汇总省略。

### 2.4 整数最大基数规则复核

QC L103–109与原R4R L415相容：候选边同类、非空bbox、`2I≥U`，IoU tie用`I1×U2`精确比较，允许增广重新指派；不能量化IoU16再门判。QC L107反例实际成立：P0对GT0/1均I70/U130，P1=GT0；贪心只能1，增广得2。整数门20TP≥19(TP+FP/FN)与19/20、18/19、分母0处理一致。

bbox面积上界W×H=2,073,600，union≤4,147,200；IoU排序交叉乘积需完整整数（主机Python无溢出，但输入类型/范围须真校验），不能按每轴11bit对面积或乘积窄化。错类保GT类FN/预测类FP，同类重复输出保FP，禁止在parser先自行去重以提高precision。

### 2.5 仍OPEN而非已完成的部分

QC L115只提出24family、每4DEV/8ACCEPT，算术96/192正确但不是冻结manifest；L205明确精确recipe、噪声PRNG/版本/seed、旋转量化/负primitive和歧义pair参数OPEN。GT来源正确不替这些参数。八PROFILE数值/开发选择、完整父证书/LOAD/GRAD/full生产RTL映射、服务/资源设计账与timeout同样OPEN；未来实际运行才有每类P/R和图像hash。

审批前须具体冻结模型职责/fixture与schema/覆盖/方法/文件基线/判据和资源服务设计，审批后才生成图像、源码、仿真和STA。若“真实处理时间/资源证据”指实际实现测量，应记NOT_RUN而非要求先执行未获批实现才能READY；不能因此跳过当前确实还未完成的设计参数。

## 3. H1：静态地址、格式和有限资源

### 3.1 与原数据的逐区间核算

实际完整原slot JSON中FIT_STATS：base87722240，logical_end87722766，physical_data_end87722816，guard_end87722880；21 private和3 RECORD仍原字段。新JSON没有覆盖旧文件，显式preserve21/3，H1取原尾后的未分配段。

| 区间/算术 | 独立静态值 |
|---|---|
| 原AUX base→末guard end | [87293952,87722880)，428928B |
| H1 base/对齐 | 87722880=0x053A8B80，mod64=0 |
| 131072×4数据段 | [87722880,88247168)，524288B |
| 新guard | [88247168,88247232)，64B |
| 原AUX剩余 | [88247232,88342528)，95296B |
| 原五ring | [88342528,130285568)，41943040B，5×8388608 |
| arena余量 | 134217728−130285568=3932160B，3.75MiB |
| H1末合法radius地址 | radius131071→88247164=0x05428B7C，4B至data_end |

因此新数据/guard不碰旧末guard或ring，包络仍124.25MiB。旧PERFORMANCE L302的H1从88342528到88866816，确实与ring0首524288B重叠；新卡仅候选修正这一地址冲突，不能把旧PERF仍未修改的地址称已被采用。新guard普通访问禁止；radius131072恰落guard，必须在宽入口拒绝，不能先窄化17bit成0。

H1真实32bit record承载21bit票、高11实际0；全表524288B，不是旧HIST8192×21bit=21504B。r0真实清零不投票，合法r1…131071；E≤2073600<2²¹−1=2097151，合格票每POINT至多一次时21bit可容纳；这不证明RMW不会丢/重复票。

16B span每拍4record，base/end都对齐，不需碰guard；有限普通READ/VOTE仍完整核ref/version/grant/phase、初始化、latest/journal与实际effects。CLEAR是131072record真实写0及settled，不能以一次旧tile CLEAR/计数器清零代它。

### 3.2 descriptor/cache/pin条件

HP L83/85和JSON候选：index45/kind10是新FULL_RADIUS_HIST，旧private HIST kind133/公开typed object5=5不授权它；原46…63保留，实体仅未来采用后45→46。原公开OBJ object26…31仍非法；新内部H1选择必须显式新映射/namespace，不能让object26自动访问新slot。

SC当前32个295bit cache行与四32bit mask；保留3LOAD/G+3CLO+26RC时新H1不能塞原32行。33行/four33mask的selected-state增量=`(33×295+4×33)−(32×295+4×32)=299bit`，HP数字正确且仅下界。内部slot32、选择/译码、mask操作/仲裁索引宽度、真实reply/permit/effect/phase状态也须计，299不是完整FF/XLR/DSP。原RJ2257及SC原RC26物体没有H1完整ref来源，须真实ALLOC/holder扩展和关闭合同；固定index/base不能补完整注册。

条件61+H1一pin=62<64是算术，不是全机已证明pin上界；前提包括原SOURCE/borrow/camera/observer/RC scopes、closing/returned metadata/Q额度和实际并发全闭合。新H1若保旧HIST及全部26RC资格，新pin和返回metadata不能免费插到“还剩两个槽”的叙述。HP已将完整资源/service写OPEN，方向正确。

旧26bit物理授权若截新base会别名到20614016，属于SRC区域，不能直接连接生产32bit地址；SC L116已明示RAW AP466旧26bit不自动升级。这是接口迁移缺口/反例，不是本新JSON已运行了错误访问。

### 3.3 PROFILE/数学采用边界

R4R L257/346的radius_bins14=8192为原16tile数学组织，完整非零Q4域1…131071；H1物理131072容量不是把131072塞入14bit字段（截断会0）。HP L93保持PROFILE结构、独立实现选择，正确。

未来H1把16遍POINT/seed改一遍全域投票，须同POINT/source/profile、RNE距离/normal门、每radius票、±8 sum、正plateau最小r、外域0、跨块边界及RAW/SMOOTH第513峰CAPACITY完全等价；原NUM/STORE实际counts要保新轨迹，不复制旧16遍日志。末域读序/halo/window/native/效果/clear/峰seal微调度仍HP-B01/B03 OPEN；地址成立不证明数学差分成立、提速或fps。

物理选择保持PROPOSED_NOT_ADOPTED，原算法/PROFILE/旧目录均没有自动采用H1。主质量GT不应从H1票/峰产生；H0/H1同RGB/profile/GT分别算完整输出并保存实际代价，不能用新优化把困难主集滤掉。

## 4. HP-R01：CLOSE请求与完成回执需区分

HP C图L62为“typed CLOSE→实际pin RETURN→实体RETIRE”，G T05 L127为“先CLOSE后RETURN”；未冻结wire body，所以不能把它断言成已存在的运行错误。但若CLOSE指成功ACK且包含common pins_closed，便会有最小环：provider不给成功CLOSE_ACK直到pinreturned，actor又按文字等CLOSE_ACK后才RETURN；双方永久等待，违反SC L132/134及I7。

建议根作者明确为“停新data/履约旧held/effects→CLOSE_REQ（可先接）→真实local access quiet→scope RETURN/ACK→CLOSE_ACK证书→该scope metadata/整体RC退休汇合”。RETURN不等CLOSE_ACK/wholeholder RETIRE；成功closeACK不能在实际return前证明pinsclosed。若H1另定义无pin的close，则必须明确独立名称/字段和后续pin-return证书，而不是借旧RC完整CLOSE的同名body。

H1单表close不是原RC全部表/NUM/parent的wholequiet；取消/unknown以及新seedclear前的oldrevision/promise、RMW/latest/journal/heldreply分别闭合。H1新provider与RC现有单业务credit、SC同RC child revision/权限phase、旧HIST仍保留的关系须在HP-B01/B02共同冻结，不能只给layout就连端口。

## 5. 审阅交付和未完成项

已向根代理报告QC-R01坐标基准、QC-R02分split聚合、HP-R01请求/回执顺序。由根作者修两卡；本记录不直接改源。本记录审阅绑定旧实际hash，若作者修订则另读差异/hash，不把已修后的结论冒称本次全新来源已全文核过。

通过的是有限静态算术/指定原合同复核，不是功能测试。三主文件保持NOT_READY；recipe/schema/PROFILE、H1 provider/阶段权限/资源/服务/算法差分和正式文件基线都还需具体联合设计。未来quality95%/实际仿真/STA/PNR/bit仍NOT_RUN，不与审批前的可审阅设计门槛混为互相等待。

本记录写后实际全文读回、完整SHA/bytes在交付消息记录。用户理解验收待真实作答；未以本审阅更新数据库、审批或正式硬件状态。旧LOAD/R1未改。

## 6. 作者修订后的限定读回

根作者收到上述三个问题后，只修自己的两卡。本记录保留C22F…/ECE4…修前全文与最小反例，不覆写成修前没有问题，也不把以下定向复核称新版本全文重审。

| 修后实际来源 | 完整SHA256 / bytes | 本次实际读回范围 |
|---|---|---|
| QUALITY-CORPUS v0.1 | `C7A9A387FC7AB17FC6AE4BFFA16F8DB618973DE36A148B305AE691C657A68569` / 26196 | 连续L73–112、L176–186；另rg定位L115/122/134/136/140/144/148/165/196/205–208 |
| HIST-PLACEMENT v0.1 | `51A7E8190378D72F84BCEAB13224A55B9BBBBAC280B13A8A7E138B5C85D66AFD` / 16750 | 连续L54–68、L94–111、L124–130 |

QC-R01在修后L77明确采用原R4 index中心16x/16y与面积窗[-8,16W−8]；L89保存r8应保中心一像素、r12应为同中心一像素而非+8四像素的反例，T02同步。原可观察GT在遮挡/噪声前确定仍见L87，并未借修坐标恢复尺寸或对比硬门。该坐标合同歧义在以上读回范围已消除；实际scene实现和fixture仍NOT_RUN。

QC-R02在修后L109明确DEV/ACCEPT/STRESS各自独立累计，完整192 ACCEPT单独主门；DEV80与ACCEPT19TP/2FP/1FN不能混成99/101，T06同步。该聚合歧义在以上读回范围已消除；尚未生成/运行主集，不能据修文宣布P/R通过。

HP-R01在修后C L62–63、T05 L128明确CLOSE_REQ→data quiet→RETURN_ACK→CLOSE_ACK→其余metadata→RETIRE，不等CLOSE_ACK才返pin。E04 L110的概括“独立CLOSE→实际RETURN”应按这两个明确段解释成请求与返回顺序，不能重解成成功ACK先行。原其余RC branch未结仍阻整体退休，H1单支不能冒作wholequiet；该顺序歧义在指定合同段已消除，provider wire、资源和服务的既有OPEN不变。

同次复核新H1 JSON仍3269B / `A4CBE7FF910852A07D7E7FE0B1C10528DAF005A2840971B0252760A58AEA30FA`，自己的LOAD仍64243B / `25AFA46EAF11F59C1F2942708E803DCEE3C84B609619B27C2FA8C10E6804B22D`。这只确认本次两个文件未变，不对未读的其它来源签全文核验。两卡和JSON继续NOT_READY/未采用、无生产实现/仿真证据。
