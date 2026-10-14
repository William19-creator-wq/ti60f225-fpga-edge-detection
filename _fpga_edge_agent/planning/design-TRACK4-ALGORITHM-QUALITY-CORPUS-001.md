# TRACK4-ALGORITHM-QUALITY-CORPUS-001：独立图像、真值与质量评价候选 v0.1

2026-10-05；LOCAL_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED。本卡仅形成完整十一项软件测试所需的质量输入与评价合同，不生成图像、功能脚本、模型或 TB，不改变已经交付的 R1 及原局部设计。先读 B 整体与 C 连接，再 D 输入/真值/匹配，最后 E 中文步骤、F 语言边界、G/H 验证追踪及 I 未决项。

## 通用计划字段

- Goal：补整包 B05 的独立 fixture/GT/质量集，把算法数值自洽与实际形状误检漏检分开，保留完整 1920×1080、每类 P/R≥95%、IoU≥0.5。
- Current state：R1 已完成独立软件验证及 bit；R4R G 已规定最大基数匹配、失败帧 FN 与独立冻结 GT，但没有完整图像/GT 格式、数据分组和运行归属。PROFILE 真值模板未冻结。
- Target state：图像 recipe、版本化 GT、开发/验收分离、记录解析及匹配合同联合成熟，进入完整设计集合的指定审批，然后生成可运行实现与实际证据。
- Gap：本卡给出候选分布、整数 bbox、匹配与来源；逐 fixture 精确参数表、八模板、完整流程文件和时间/资源基线尚待联合冻结。
- Assumptions：软件目标 Ti60F225/I3、SC431HAI 彩色、生产 1920×1080；仅现有板卡资源，DDR3 已允许；实体到货前测试止于实际 bit。合成图证明软件合同，不能替代真实相机质量/硬件验收。
- Open questions：I 节 QC-B01…04 是具体待闭合工作，不恢复曾撤回的尺寸、目标数、对比、噪声或遮挡硬 admission 门。
- Dependencies：根 v0.2、PLAN_TEMPLATE、R4R/R3/PROFILE/INTEGRATION 现行来源及将来的共同批准基线；现有 R1 批准不覆盖本卡源码。
- Milestones / Detailed steps：原质量语义→recipe/GT→独立匹配反例→开发策略/模板→完整 fixture 参数→组合/资源/文件冻结→READY/批准→生成 inputs/GT 并冻结→开发评价→冻结生产选择→独立验收/RTL对应→整包工具证据。
- State transitions：仅本卡设计状态，不写正式 PROJECT_STATE/TASK_LEDGER 或数据库。
- Artifacts and hashes：A 节为实际来源；本卡以后被联合引用时由外部基线保存其最终 SHA，不能在自身内虚构自引用 hash。
- Validation：数学目标、逐位算法、协议、质量、综合/时序、bit、实物各自计状态；本卡全部代码与测试未生成、未执行。
- Failure handling：不删困难 fixture、不对失败帧使用预测前缀、不因测试不达标收紧输入范围；保留失败与原版本，按具体证据修订设计/实现。
- Human approval gates：按 v0.2 §10.3 成熟后提交具体版本集合/范围/基线；获批前仅允许文档和只读核查。
- Rollback：仅新增本卡及审阅记录，原参考、R1、旧计划与数据基线保留。
- Completion criteria：未来所有输入/GT 有真实 SHA、独立每类 P/R 与失败率、必要全生产 RTL 对应、完整代码/工具/bit 证据；本卡存在不代表目标完成。

## A. 来源与采用边界

| 实际来源 | SHA256 | 本轮实际阅读/采用范围 |
|---|---|---|
| PLAN_TEMPLATE | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 | 全文；整体/局部/语言/验证/追踪门槛 |
| R4R v0.2 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | B REQ01…09/样例；D3 表示/bbox/FINAL512；E10 PROFILE；G T20/21/独立GT/匹配与失败帧规则 |
| PROFILE-SOURCE v0.1 | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | D1 全1024bit、八实体及真实ref/seal；精确模板值仍未定 |
| R3 v0.2 | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D | E7 实际候选容器/数值核职责；GT不依赖R3返回值或DUT拟合日志 |
| INTEGRATION v0.8 | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF | A/整体范围及 I B05 定向；本卡为新附件，原稿尚未吸收 |
| 本批R1中文交付 | experiments/track4_algorithms_20261004/05_delivery/r1-software-acceptance-v1.1.md | 已有灰度/中值/Sobel的全生产证据；不据此推定完整识别已经验证 |

资料原要求是形状识别与屏幕标注；P/R、IoU、复杂场景和全生产范围沿现行 R4R。下面的 recipe 数字是新的待评审测试选择，不是主办方条款，也不是限定算法只需接受这些值。

## B. 整体外部行为

| REQ | 本卡可检查的保证 |
|---|---|
| QC-REQ01 | 所有主质量 fixture 使用 1920×1080 RGB24；不缩图、不把完整图裁成局部算法输入。小图仅用于字段/匹配/协议反例。 |
| QC-REQ02 | 原几何/semantic class/遮挡事实由 scene owner 在观察任何识别输出前形成；禁止从DUT候选、POINT、ANN或score反推GT。 |
| QC-REQ03 | 固定开发与独立验收集合；生产模板/选择在首次验收输出前冻结。测试/输出失败不能删除fixture、换标签或只挑成功帧。 |
| QC-REQ04 | 每类半开整数 bbox IoU≥0.5，最大基数同类一对一；用整数门判P/R，不用四舍五入百分数替门。 |
| QC-REQ05 | 零目标、重叠、重复、错类、低对比、噪声、三边及整短边缺失保留；表示域外/搜索或容量失败不成为输入过滤理由。 |
| QC-REQ06 | 每帧合法完整结果才能形成预测集合；失败/取消/SEARCH_INCOMPLETE/容量错误无合法预测前缀，所有该帧GT为FN并单列功能失败。 |
| QC-REQ07 | 同图像/profile/完整J身份分别对应软件数学结果、硬件真实事务与质量GT；三者独立，不能把GT像素送入DUT。 |
| QC-REQ08 | 保存完整distribution/manifest/source/tool/profile/输入/GT/output SHA、每帧/每类统计及分组结果；不得把无分母NA当100%。 |

正常路径：先锁 scene recipe→独立生成完整RGB和原GT→冻结manifest→从RGB计算数学Canny/识别→合法完整预测→解析记录与bbox→同类匹配→累计TP/FP/FN及失败率；RTL用相同已冻结RGB与profile检查实际记录/图/身份，单独核质量与实现等价。

范围内两条相同RGB可以有不同预先定义的场景真值，例如删一整边的矩形与本来就是U形的负样本。单凭图像无法保证把这对语义全部区分正确。保留成对反例并如实统计，不宣称任意图像/遮挡的理论95%保证，也不删除其一改善统计。95%是固定独立主集上的目标，实际是否达到须未来运行证明。

## C. 职责与连接

```text
SCENE_OWNER（recipe/原几何/语义/遮挡；唯一GT writer）
 ├─QC-IF01→ RASTER/NOISE → 完整RGB输入文件
 └─QC-IF02→ GT_CANONICAL → GT文件/成对歧义关系
              两路真实落盘后→ MANIFEST_FREEZE
冻结RGB ──→ 独立数学参考 / 合成相机输入适配→完整算法DUT
完整真实RECORD/TERM ──QC-IF03→ PRED_PARSE
GT + 合法PRED ──QC-IF04→ MAX_MATCH ──QC-IF05→ 每帧/累计报告
```

MATHEMATICAL_REFERENCE实现算法定义，不读取GT来产生预测；GT_CANONICAL不调用算法核来拟合原几何。协议scoreboard只依据实际fire及真实存储事实结账。MANIFEST_FREEZE不把COMPLETE标记当图像正确证据，须实际检查尺寸/行数/格式/来源/SHA。评估在主机进行，不占生产FPGA的XLR/RAM/DSP，也不能以主机存储替代FPGA工作区。

整体检查点：本卡的阅读入口为B/C→D1…D5→E。主集与功能注入场景的区别、像素bbox语义、失败帧统计及歧义样本已写清；逐fixture参数和PROFILE仍待联合，不声明READY。

## D. 接口与组合合同

### D1. 图像与scene数据

QC-IF01：`scene_id`为唯一稳定字符串，`split`为DEV/ACCEPT/STRESS_PROTOCOL，W/H为1920/1080；每目标有唯一ordinal、semantic class（1圆/2矩形）、原Q4几何、前后绘制顺序、outline/filled、遮挡recipe。负例有独立primitive描述但不创建GT目标。scene参数不能由当前profile或识别结果改变。

RGB文件逐row-major、lane0低位，未来FP74每次读两个原图像素并产生同源坐标/标记；整图单像素文件采用每行6个小写hex表达R高/G中/B低，恰N行，双像素入口按顺序拼为12hex，不重采样。不得把行宽、noise的浮点数组或GT字段塞到FP数据口。本文不生成文件。

像素中心统一采用原R4 index坐标Q4=(16x,16y)，像素面积窗为[-8,16W−8]×[-8,16H−8]；scene/原几何/GT/POINT都用这一坐标系，没有隐含+8或−8变换。圆filled谓词用该像素中心的整数平方与原r²比较；outline由原外/内半径两平方门形成。矩形用scene原四Q4角点的有向叉积判断多边形/有限边距离，原theta只是recipe辅助，最终GT四角在生成RGB前量化冻结。旋转/三边样本不调用R3拟合，不能用识别的canonical角点替原角点。

候选颜色基础两套：背景灰32/前景灰220与背景220/前景44；彩色族另选固定RGB palette并按原灰度公式记录实际Y对比。低对比族专门降低真实Y对比，不把低于64/255当非法。clip到[0,255]只能发生在合成RGB噪声/颜色，原几何不clip成成功目标。

候选扰动轴：纹理幅度0/4/8/16/24/32；高斯名义σ0/1/2/4/8/12；椒盐比例0/0.001/0.0025/0.005/0.01；连续与分散遮挡0/5/10/20/30%。它们是测试取样点，含超过先前提议范围的情况，不作输入admission边界。遮挡比例按原轮廓参数/遮挡recipe报告，不能由DUT提取的可见边长度倒算GT。整短/长边缺失另是精确outline擦除族，不用“总遮挡20%”把它排除。

noise先纹理、再高斯、再椒盐；三独立seed namespace，不能把同一随机流作为RTL停顿/取消调度。主机随机数实现/版本和完整输出hash共同冻结；名义σ/比例另附实际像素统计，不假装有限样本精确等于理论值。浮点只用于合成输入的噪声采样/旋转recipe；已冻结RGB、Q4几何和后续IoU评价是精确整数数据，硬件oracle不复制这些浮点计算。

### D2. 真值与bbox

QC-IF02：GT header包含schema/version、scene_id、W/H、split、scene-source hash和全RGB hash；每目标保存class/ordinal、原geometry、遮挡/推断事实及独立bbox。原geometry可在画面外，小目标不删。只在施加遮挡、擦边和噪声之前，用原形状的原filled/outline整数谓词判断是否有至少一个画内像素中心：有则进入该frame GT，此后全部遮住、与背景同色或低对比仍不能删除；没有则只作画外/无画内采样的scene环境描述，另报告该事实，不伪造画内可识别目标。这是预先固定的scene标签规则，不能改用识别输出、噪声后可见mask或算法阈值决定是否计GT。

GT bbox严格沿R4R D3：低到高xmin/ymin/xmax/ymax，各uint11；对原Q4几何的每轴最小/最大extent，min=clip(floor(min_extent/16),0,W或H)，max=clip(floor(max_extent/16)+1,0,W或H)，半开范围0≤min<max≤W/H。圆extent为cx±r/cy±r，矩形extent取原四角min/max。max处的+1保留原FINAL语义，不能换成ceil、按噪声后可见像素tight-box或按ANN stroke扩张。坐标反例：filled cx=cy=160/r=8时，原index中心(10,10)在mask内且GT保留；误用16x+8会没有采样并错误删除GT。r=12的同中心在原index采样仅该中心一像素，误用+8会变为围绕index9.5的四像素，不能作为同几何fixture。

原角点/中心越R4表示域只是场景事实，不以此筛掉GT；未来算法域外候选的拒绝会产生FN。GT保存的几何使用主机整数，不窄化成signed18；只有输出解析按真实RECORD union的signed18/Q4及r17检查。

### D3. 预测资格与输入身份

QC-IF03：输入为同scene/profile/JID的完整RECORD512×64、F、RC_TERM2606和父整包结果证据；PRED_PARSE只使用前F有效项，检查未用项全0、padding、class1/2、bbox合法、geometry与bbox一致及记录身份。GT不参与预测合法性判定。同bbox但不同class仍是不同类，不自动去重输出或删低score项。

RC局部COMPLETE不替代整包SRC/EDGE/GRAD/profile/ANN/RECORD真实commit、CLOSE/private返还及父完整资格。未有合法完整终态、timeout、Q、取消、容量/搜索失败或字段/身份错的帧形成`functional_fail`：其合法预测集合为空，原GT全FN，原非法/前缀输出另作诊断保存。软件参考与RTL输出需各自解析与评价，不能复制软件P/R给DUT。

正常统计入口仅在完整结果实际取得后执行，无ready/valid反压到生产算法；评价速度不能作为FPGA处理fps。故意cancel/错误注入的STRESS_PROTOCOL单独报告预期功能结果与GT FN，不混入未注入的主质量集，也不以此丢掉主集中自发失败。

### D4. 精确匹配及统计

QC-IF04：每类独立GT/预测列表按原ordinal/真实FINAL slot升序。候选边当且仅当同class、两个非空bbox，I=max(0,min(xmax)-max(xmin))×对应y长度，U=areaGT+areaPred−I且2I≥U。整数全宽，先作非负宽度检查；不要把IoU先量化到16bit再比较。

使用确定性增广求最大基数二分图匹配。每预测按其合法slot升序访问；其相邻GT按精确IoU降序（I1×U2比较I2×U1）再GT ordinal升序；每次增广有本次visited标记，允许将已匹配预测转到另一GT。最终一对一集合可改变早期贪心选择，TP=匹配数、FP=预测数−TP、FN=GT数−TP。

明确反例：GT0=[0,0,10,10)，GT1=[6,0,16,10)；P0=[3,0,13,10)，P1=GT0。P0对两GT均IoU7/13≥0.5；P1只匹配GT0。greedy先P0→GT0只得到1，增广把P0移GT1后P1→GT0得TP2/FP0/FN0。该例是小数据匹配合同，不是完整识别通过证据。

QC-IF05：DEV、ACCEPT、STRESS_PROTOCOL各自独立累计每类TP/FP/FN，禁止合并split改善门槛；主验收只用完整192个ACCEPT帧，分别判`20TP≥19(TP+FP)`和`20TP≥19(TP+FN)`。任何分母0记NA，ACCEPT两类都须有GT和可检查分母。TP19/FP1或FN1恰95%通过；TP18/FP1为18/19<95%失败。例DEV80TP与ACCEPT19TP/2FP/1FN，主precision19/21失败，不能混成99/101通过。匹配IoU门的2I=U通过，2I=U−1失败。

错误class产生该GT类FN与预测类FP；同类重复预测保留未匹配FP。失败帧不会借prefix增加TP；其功能失败计数/failure_rate、SEARCH_INCOMPLETE/CAPACITY/Q原因、源完整性及每group P/R并列输出。主P/R达到目标也不能抹掉必要功能检查失败。

### D5. 候选数据分布与冻结顺序

本v0.1提出24个固定family，每family DEV四帧、ACCEPT八帧，共96开发帧/192独立验收帧；全部完整生产图。下表每family覆盖点在完整参数表里逐项展开，当前没有生成参数/图像/GT/manifest。不能据24×8算术说集合已冻结。

| family | 目的/必须包含的变化 |
|---|---|
| Q01/Q02 | 单圆/单轴对齐矩形；两种极性与位置 |
| Q03 | 矩形任意旋转；轴附近、斜角及跨象限；角度为样本，不是只接受这些旋转 |
| Q04/Q05 | 小/细目标及大型/跨图目标；不恢复96–768或长宽比≤3限制 |
| Q06 | Q4亚像素中心/半径/角点、边界floor/+1反例 |
| Q07/Q08/Q09 | 多圆、多矩形、两类混合；数量1/2/3/4/6/8等取样，不作为目标数上限 |
| Q10/Q11/Q12 | 同类圆、同类矩形、异类目标重叠；z-order及不同支撑/极性 |
| Q13 | 同心/近重复且是真实多个目标；不能bbox去重吞掉GT |
| Q14/Q15 | 完整短边、完整长边缺失；已知原四角GT，outline擦除与端点guard |
| Q16/Q17 | 圆弧连续遮挡、分散遮挡；矩形局部多边缺口 |
| Q18 | 低对比、反极性；真实Y对比低于64仍保留 |
| Q19/Q20/Q21 | 纹理、高斯、椒盐各自分层；包含±16/σ8/0.5%及其外取样 |
| Q22 | 噪声+纹理+遮挡+重叠的组合，保持完整GT |
| Q23 | U/L形、梯形、多边形、开口曲线等负例；至少一对与Q14相同RGB不同原语义，显式标歧义pair |
| Q24 | 空背景/纹理/数字或随机曲线负例；零GT也统计FP |

开发可比较多个已获批候选PROFILE及处理成本，但只用DEV决定生产选择。原1024bit模板及prefer/reference、阈值和生产选择必须在首个ACCEPT算法输出前保存hash。ACCEPT输入/GT在此之前已由独立scene流程完整冻结，查看输出后不能重生成、重标或从其结论选模板。接受失败后的修订必须留原报告，声明新设计/配置/基线；原失败难例继续保留到后续评价。

STRESS_PROTOCOL另含：>64 keeper容量、同输入不同协议调度、取消、reset、坏身份/存储失败、永久背压等原R4R G场景；其全部GT/输出/失败统计也保存，但预先声明的注入目的和主质量验收分别判定。自然图像复杂度造成的CAPACITY/SEARCH_INCOMPLETE属于主集真实失败，不能事后改split。

## E. 详细中文操作草图

E01 SCENE：先读已冻结family/参数/seed→建立原目标与负primitive→独立检查几何及GT ordinal唯一→生成原mask/擦除/纹理/noise→按像素中心写完整RGB；原几何、semantic标签和遮挡recipe不随噪声后轮廓改变。先写INCOMPLETE，完整N行与源hash核查后才允许scene输入freeze。

E02 GT：只读SCENE原几何/语义及其显式可观察事实→按D2算原bbox→保留遮挡/小/跨图目标与歧义pair→写固定schema/精确整数GT；独立检查与RGB同scene尺寸/hash，不读算法/POINT/ANN。GT写完成不表示算法识别通过。

E03 DEV/FREEZE：算法从DEV RGB/profile生成完整结果→独立解析/匹配/质量与真实成本比较→选择已批准候选之一→冻结完整生产模板/选择及版本→才开放ACCEPT结果运行。未达到DEV质量或时间目标则保留差距并修方案，不能提前把ACCEPT用于调参。

E04 FRAME：锁scene/输入/profile/真实job映射→执行相同完整算法→保存actual TERM/records/ANN及input/output/command/source hash→失败走无合法预测/GT全FN→成功按slot解析所有F→每类增广匹配→生成每帧报告。软件与RTL两份来源独立对应，旧frame未完整结束不复用映射。

E05 TOTAL：核主manifest所有192个唯一ACCEPT条目均有报告，失败/缺失也必须有记录→按每类整数累计与逐family细分→确认双类分母、负例FP、歧义pair、错误类别及failure_rate→独立签本次软件质量结论；GT字段变化、少frame、非法来源或错split使审计失败，不只打印已完成样本平均值。

E06 RECOVERY：故意取消/冷reset/错echo的协议场景按其原关闭/恢复合同核真实前缀；重新正常处理同图是另独立run/frame，不能用恢复成功改写原失败。所有主集自发失败必须计本次统计。参数/模型改动先按真实影响修设计和对应批准，旧输入与报告保留。

## F. 语言与映射

C++ N/A：本卡拟用现有Python3.14.6标准库做合成数据与主机独立评价；不引入C++ ABI/新库。实际将来的可执行版本与使用库须在获批实现和manifest中记录，现在无实现。Python整数无机器溢出，所有输入显式拒bool充当int、非法class/重复ordinal/空bbox/错尺寸/格式；浮点noise仅影响未来冻结RGB，不能作为RC数值oracle或IoU门。

| RTL A–L | 本卡对应合同/边界 |
|---|---|
| A 数值 | RGB8/单像素24、FP双48、GT主机整数与真实RECORD signed18 Q4/r17/bbox44分开；同类匹配用精确整数 |
| B 时钟/观察 | DUT域沿已冻结生产方案，TB下降沿驱动/上升沿沿前真实fire；主机质量评价发生在完整结果取得后 |
| C 接受/交付 | FP74按源job锁定后真实valid/ready；GT不连接DUT；结果未真实取得不能评价为成功 |
| D valid/推进 | 无效/气泡不消耗图像记录；失效prefix不转预测；不把无目标与失败混淆 |
| E 反压/保持 | 输入/RAM/NUM/OBJ实际暂停按原合同；黄金图/GT不随调度改变，pending与身份同时保持 |
| F 延迟/吞吐 | 噪声生成/评估速度与FPGA处理时间分开；主集与协议调度真实运行时间另记，未规定虚假fps |
| G 复位 | 原硬件/软件epoch合同；取消/复位作废帧保留报告和GT FN，恢复不覆盖旧记录 |
| H 配置 | DEV选择与ACCEPT冻结；完整1024bit PROFILE/ref/seal/J对应，不能读当前全局配置代原快照 |
| I 存储 | 主机输入/GT由文件完整保存，不代生产存储；未来FP/结果/scoreboard容量与全机资源需要对应批准 |
| J 身份 | scene_id↔RGB hash↔PROFILE/完整J↔records/TERM，图坐标row-major/lane0低，GT ordinal不同于FINAL slot |
| K CDC | 本卡不新增CDC；合成相机适配依正式IO，不能以单域普通TB替CSI/DDR/HDMI多域验证 |
| L 实现 | 将来文件位于新获批work子目录；不改R1；无额外安装/网络；完整工具/资源及bit另取真实证据 |

三份对应：①数学算法参考从RGB+PROFILE形成完整预测，GT从原scene生成，互不偷取；②硬件执行以真实FJ/CJ、FP/CLASS/GRAD/OBJ/NUM/TERM及关闭账本比较，不用函数返回伪造fire；③同scene原输入与输出逐项对应软件/RTL，质量匹配仅对合法完整结果、身份/次数/坐标和数值等价独立检查。

## G. 实施与验证计划（仅文字，全部NOT_RUN）

| TEST | REQ/IF与事件 | 独立期望/通过条件 |
|---|---|---|
| QC-T01 | 01/02；固定RGB24/双lane/完整生产/GT源 | N行、逐pair顺序、原mask/几何及GT由scene产生，不含DUT预测信息 |
| T02 | 02/04；bbox负extent、整数界/半界、跨图、小目标、cx=cy160/r8或12 | 原16x像素中心、floor/min、floor+1/max、clip及uint11合法；不换+8/ceil/噪声tight-box或删真实小GT |
| T03 | 04；D4 greedy少配反例、IoU等/差1边界 | 最大基数2；整数门边界正确，确定性重复结果相同 |
| T04 | 04/08；TP19+FP/FN1、TP18+FP1、无分母 | 精确95%/18÷19，NA非100%；双类主集不可缺分母 |
| T05 | 05/06；重复/错类/重叠/失败/SEARCH/CAPACITY | 重复FP、错类FP+FN、失败GT全FN且不能应用prefix；记录功能失败 |
| T06 | 03；更换split/GT/模板、漏一帧、同scene重复、DEV80TP/ACCEPT19TP2FP1FN | 审计失败或主precision19/21失败；固定192份验收全部有结果，DEV不得混入，失败不得悄然移至STRESS |
| T07 | 05；三边矩形与U同RGB不同GT、整短/长边缺失 | 歧义关系及错误原样统计，无理论全正确宣称；GT不能看输出更改 |
| T08 | 01/07；全生产相同RGB/profile的数学/RTL结果 | 完整ANN/records/真实TERM/关闭及数值逐位对应，GT评价各自运行；范围由共同验证计划冻结 |
| T09 | 01/05/08；24family、96DEV/192ACCEPT与负例 | 完整分布/源/输入/GT/profile/output hash、逐frame/逐class/逐family，P/R与failure_rate并列 |
| T10 | 07；气泡/反压/reset/旧job/配置更换 | 原事务合同成功或真实取消错误，输入不重采样；原失败与恢复分开，不仅末CRC比对 |

拟实施顺序与文件职责：scene_recipe/schema→image_generator→ground_truth_canonical→quality_manifest_freezer→final_record_parser→exact_iou_matcher→quality_reporter→full_algorithm_reference与protocol/RTL运行整合。这些是计划符号，没有生成源码/功能脚本/TB。必要全部生产RTL case集合、独立模型来源和超时/资源预算见I，不把192个主机评价当192个RTL已通过。

## H. 双向追踪

| 来源/REQ | MOD/IF/步骤 | 计划符号（未生成） | TEST/状态 |
|---|---|---|---|
| R4R REQ01/02；QC01/02/05 | SCENE/RASTER/GT；IF01/02，E01/02 | scene_recipe/image_generator/ground_truth_canonical | T01/02/07/09；NOT_RUN |
| R4R G T20/21；QC03/08 | MANIFEST/FREEZE；IF05/D5，E03/05 | quality_manifest_freezer/profile_selection/quality_reporter | T04/06/09；NOT_RUN |
| R4R FINAL/D3/G；QC04/06 | PARSE/MAX_MATCH；IF03/04，E04 | final_record_parser/exact_iou_matcher | T02…05；NOT_RUN |
| PROFILE实际实体/完整J；QC07 | INPUT/DUT/reference；F，E04/06 | full_algorithm_reference/quality_job_mapping | T08/10；NOT_RUN |

反向每个计划文件仅承担独立输入、真值、匹配/统计、可追溯运行或相应映射；没有生产算法职责的GT/评估器不能部署成硬件捷径。当前业务代码为空，无实现hash或测试通过证据。

## I. 门槛及具体未决

| OPEN | 影响/下一项具体工作 |
|---|---|
| QC-B01 | 逐family的4/8个精确recipe、PRNG/noise/旋转量化、负primitive、GT可观察规则和歧义pair实际参数须完整定稿；本卡只提分布，不伪造冻结manifest |
| QC-B02 | 八PROFILE精确模板及DEV选择规则、资源/时间目标未定；不得用0占位安装，须与R4R/PROFILE/性能一起确定 |
| QC-B03 | 完整算法引用、RECORD/父结果证书及存储/LOAD/GRAD接线、对应RTL全生产case与必要协议覆盖尚待共同文件/基线冻结 |
| QC-B04 | 全生产算法真实处理时间、backend最坏服务、主机/RTL套件wall/cycle timeout与完整存储资源账尚OPEN；不能以模型内存或R1局部bit代全机证据 |

§10.3①整体、②职责、③接口候选、④局部草图、⑤语言/对应、⑥反例走查、⑦计划/追踪已有本卡内容；⑧上述当前未决尚在；⑨保存后须实际读回与用户阅读入口呈现；⑩来源范围有hash但完整实施基线未冻结。结论NOT_READY；无新实现批准，不请求现在批准未成熟整包。

## J/K/L. 变更、实录与交付

这是新增质量附件，不直接改原R4R G/PROFILE/INTEGRATION。明确refinement为D2沿原整数bbox、D4最大基数与失败统计、D5分布/冻结及歧义公开；未来接入须列出对应联合版本与schema，先完成复核再生成代码。本卡没有业务实现、图像、GT文件、实际测试或新构建。

阅读从B/C→D1图像→D2原GT→D3合法预测→D4匹配→D5冻结→E中文操作→F/G/H/I。理解验收须用户实际作答，Agent没有代签；本卡进度不是完整十一项完成或真实相机识别达标。
