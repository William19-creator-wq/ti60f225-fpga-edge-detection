# TRACK4-ALGORITHM-QUALITY-RECIPES-001 — 288 个独立源场景的精确参数合同 v0.1

2026-10-05；纯设计候选，`NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN`。本卡完善 QC-B01 的 recipe，不修改 QUALITY-CORPUS、HIST、LOAD、既有审阅、R1 或入口，不生成任何输入图、GT、manifest、模型、源码、功能脚本、TB 或执行测试。先读 B 整体，再 C 职责、D1…D8 的共同数值及 24 family 参数，最后 E 中文展开次序、F 映射、G/H 验证追踪和 I 未决项。

## 通用计划字段

- Goal：把 QC 的 24 family×DEV4/ACCEPT8 落实为可完整展开的 288 个固定 scene；原 RGB、语义和 GT 由 scene 定义，不由识别结果反选。
- Current state：QC v0.1 已规定完整 1080p、原像素坐标、独立 GT、精确最大基数及 ACCEPT 主门；仅分布未有精确 recipe。本卡给出具体候选，不冒称已经生成或批准冻结。
- Target state：联合审读本卡与 QC/PROFILE/全机设计后批准指定版本/范围/基线，才独立实现 scene/raster/GT、生成并冻结真实输入 SHA，之后执行 DEV/ACCEPT。
- Gap：本卡参数表可以按文字展开；PROFILE、生产实现/资源/服务、输入到完整 J/结果映射及联合验证执行设计仍未闭合。实际输入 SHA 属批准后执行证据，不是审批前执行要求。
- Assumptions：W=1920、H=1080、N=2073600、RGB24；既有 Windows Python3.14.6 stdlib；本卡的噪声模型是明确测试选择，不是唯一官方噪声模型。
- Open questions：I 列真实联合依赖；不得以尺寸、目标数、长宽比、对比或遮挡筛掉已固定场景。
- Dependencies：根 v0.2、PLAN_TEMPLATE、QUALITY-CORPUS C7A9…、原 FRONTEND 灰度合同及未来共同批准基线。
- Milestones：M1 参数/数值/组合读回；M2 scene/GT/PROFILE/全机验证联合审读；M3 READY/指定版本批准；M4 才实现/生成完整输入及 SHA；M5 DEV 选择；M6 冻结生产 PROFILE 后 ACCEPT 独立统计。
- Detailed steps：B/C→D 共用表→逐 family→E 展开→独立审读→批准→生成及 freeze→算法运行；顺序不倒置。
- State transitions：本卡仅设计状态；未来每场景 PLANNED→GENERATING→INCOMPLETE→SOURCE_COMPLETE→FROZEN；生成错误保 INCOMPLETE，不以部分图像进入质量统计。
- Artifacts and hashes：A 实际读源及宿主二进制；本卡自身 SHA 在外部读回报告记录。未存在的未来输入/GT/hash 不填假值。
- Validation：本次为文字数值/区间/展开检查；所有生成、功能测试、算法质量、RTL/综合/STA 均 NOT_RUN。
- Failure handling：生成错误是 fixture/audit 失败，保原 scene 和报告；算法 CAPACITY/SEARCH/timeout 仍主集失败，不改 split/GT/recipe 重试掩盖。
- Human approval gates：仅被委托新写本纯设计卡，未获本卡实现批准；R1 批准不扩展。按原制度核工作副本/工具/构建/数据库及人工硬件门。
- Rollback：只新增本卡；源与旧证据保持只读。recipe 变化须新版本和差异，既有失败图/报告保留。
- Completion criteria：本次设计交付为参数可展开、整体/接口/草图/方法/追踪可读；生产完成仍须实际独立 GT/完整结果/质量及工具证据，不能以本卡存在代替。

## A. 状态、来源及边界

任务 ID `TRACK4-ALGORITHM-QUALITY-RECIPES-001`，关联 A6 与整包质量 QC-B01。版本 v0.1；候选参数选择是新的工程测试设计，不是主办方限定。根委托仅允许文字/表/公式和本卡保存；288 scene 全属主质量源 fixture，不属于故意协议 STRESS，也没有算法成功标签。

| 实际来源 | SHA256 / bytes | 本轮真实阅读范围 |
|---|---|---|
| 控制 AGENTS | `6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937` /1855 | 全文；再按序全文读六规则/提示/配置/状态/ledger/数据库说明，不执行状态或数据库操作 |
| [唯一根 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2` /61102 | 前任务已全文读，本轮核 hash 未变；先设计、审批和十项门槛 |
| [PLAN_TEMPLATE](PLAN_TEMPLATE.md) | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` /10341 | 本轮全文 |
| [QUALITY-CORPUS v0.1](design-TRACK4-ALGORITHM-QUALITY-CORPUS-001.md) | `C7A9A387FC7AB17FC6AE4BFFA16F8DB618973DE36A148B305AE691C657A68569` /26196 | 本轮全文216行；D1 中心16x、D2 原GT、D4 独立split、D5 family/I QC-B01…04 |
| [FRONTEND v1](design-TRACK4-FRONTEND-001.md) | `45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114` | 本轮定向L41/53；Y公式/极色，未本轮全文重审 |
| 已冻结 R1 frontend_reference.py | `4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A` | 本轮只读L54–58，核其独立灰度公式；不复制识别/GT实现，不改文件 |

宿主 baseline 只读文件 hash，并未执行 Python 或验证实际已加载模块。现有解释器路径来自既有 R1 runner 的已配置路径，文件版本真实为3.14.6；binary64 math 本卡只指定这个 Windows 宿主候选，**不宣称跨平台 math 位一致**。

| 宿主文件 | bytes / SHA256 |
|---|---|
| `D:\py___\python.exe`，3.14.6 | 106208 / `03168C01B7B7491423350E82C26FEE71F35B43694D1319D3C668BDA6903A0C38` |
| `D:\py___\python314.dll`，3.14.6 | 6778592 / `FDE89CDB5C2D08AE65DE7EF4ABCA1876C93BA3796002F5AC0BF7E4D4F5A94DA0` |
| `D:\py___\vcruntime140.dll`，14.42.34438.0 | 120400 / `052AD6A20D375957E82AA6A3C441EA548D89BE0981516CA7EB306E063D5027F4` |
| `D:\py___\vcruntime140_1.dll`，14.42.34438.0 | 49776 / `6A99BC0128E0C7D6CBBF615FCC26909565E17D4CA3451B97F8987F9C6ACBC6C8` |
| `C:\Windows\System32\ucrtbase.dll`，10.0.26100.9444 | 1377512 / `5C52E3A303BAAAC0E0AF8BD9B96134993DA34BC9D834A31EF37E1D2CDC7FE192` |

只读清单未发现独立 math*.pyd，不能仅据此断言所有实际 math 依赖已证明。批准后首次 source 生成记录解释器/stdlib实际来源与运行平台完整指纹、math 基本值/真实 RGB SHA；差异须留旧结果、核影响并另版本，不把另宿主的输出当原输入。现有 stdlib 方法/精度选择在 D7 已明确，不留“任选库/任选高斯”。

## B. 整体外部行为

| REQ | 稳定合同 |
|---|---|
| QR01 | family f=1…24、vector j=0…11 唯一展开288 scene；j0…3 DEV、j4…11 ACCEPT，96/192，不因算法失败删除或改组 |
| QR02 | 全图1920×1080 RGB24、像素中心(16x,16y)、所有原几何先于遮挡/噪声；GT唯一来自原scene |
| QR03 | filled/outline/旋转/重叠/整边及局部擦除精确；Q14/Q23至少DEV与ACCEPT各一组同RGB不同先验GT |
| QR04 | PRNG/seed/各noise顺序和量化固定；完整RGB与图像SHA批准后生成，调度随机流不能共用输入噪声流 |
| QR05 | 小/域外/多目标/低对比/完全遮住仍依原可观察规则保GT；不恢复96–768/≤4/比例≤3/对比64/遮挡20%的硬门 |
| QR06 | 主集只ACCEPT完整192份，每类独立整数P/R、失败GT全FN；scene可观察/环境/负primitive和算法失败分别保存 |
| QR07 | 纯源fixture、GT、数学预测、RTL事务各自职责；GT不驱动DUT、不从DUT bbox/POINT/score产生 |
| QR08 | 输入格式/身份/基线、生成失败、冻结、恢复和双向追踪可核；设计审阅不伪造运行/理解验收 |

正常例：Q01/j4 使用下表唯一中心/直径/颜色/filled，生成前先形成原GT，然后RGB；Q14/j4原矩形outline擦掉整短边，GT仍原四角；Q23/j4是原U负primitive，RGB须与Q14/j4逐字节相同，GT空。两者不能同时靠图像必然正确，保持该困难主集事实。Q18/j0对比0但两原目标可观察，GT两项仍计；Q05域外原形状不窄化。以上是设计期望，未生成/检验图。

## C. 职责与连接

```text
本卡固定表/公式 → EXPAND_SCENE（scene_id/原shape/negative/seed key）
  ├─QR-IF01 原scene → ORIGINAL_MASK/GT_OWNER → QR-IF02 原GT与bbox
  └─QR-IF03 layer/erase/z → RASTER → QR-IF04 独立noise → 完整RGB
scene + 全RGB实际SHA + GT实际SHA → SOURCE_FREEZER → QC-IF01/02
仅冻结RGB + 未来已冻结PROFILE → 数学参考 / 正式DUT
合法完整RECORD/TERM + GT → 原QC解析/最大基数/独立split统计
```

EXPAND 仅展开测试选择；MASK/RASTER 不调用 Canny/识别；GT_OWNER只读 original shape，忽略 visible mask/noise及算法输出；SOURCE_FREEZER检查实际N记录/格式/hash，不能以COMPLETE字符串代正确；噪声模块只变RGB，不改GT；数学参考从RGB+PROFILE求预测，不能读取GT作答案。协议runner/硬件适配属于未来共同设计，不由本卡新增。

整体检查点：上方整体保证/连接已呈现；局部选择为固定288、两组歧义、精确整数轮廓/擦除、独立SHA流、限定现有binary64宿主。进入D逐表前仍NOT_READY；PROFILE与全机依赖不在本卡假补。

## D. 参数、接口和组合合同

### D1. 场景身份、共同12向量和默认值

QR-IF01 为纯主机结构数据。`scene_id=QR1-Qff-Vjj`，ff为f的两位十进制、jj为j的两位十进制；ASCII，版本`v0.1`。W/H/N固定，不允许bool充当整数。正shape class为circle1/rectangle2，ordinal按family列举次序从0开始（两类混合先列圆即圆0/矩形1，grid则k次序，半径列表则列表次序）；negative另有primitive ordinal按列举次序，不转GT ordinal。原geometry主机整数，不窄化signed18/r17。参数覆盖顺序：本节默认→D4 family明确替换→该family单向量特例；未写替换就是此处固定默认，绝不是任选。所有取模非负，索引环绕仅用于文中显式`mod`。

| j | split | C=(cx,cy)，像素 | p | (u,v)方向 | mode |
|---|---|---|---|---|---|
| 0 | DEV | (480,270) | 0 | (1,0) | filled |
| 1 | DEV | (1440,810) | 1 | (1024,1) | filled |
| 2 | DEV | (960,540) | 0 | (13,3) | outline |
| 3 | DEV | (1280,360) | 1 | (4,1) | outline |
| 4 | ACCEPT | (640,720) | 0 | (2,1) | filled |
| 5 | ACCEPT | (960,360) | 1 | (1025,1024) | filled |
| 6 | ACCEPT | (1280,720) | 0 | (1,1) | outline |
| 7 | ACCEPT | (480,810) | 1 | (1,2) | outline |
| 8 | ACCEPT | (1440,270) | 0 | (1,1024) | filled |
| 9 | ACCEPT | (320,540) | 1 | (-1,4) | filled |
| 10 | ACCEPT | (1600,540) | 0 | (-1,1) | outline |
| 11 | ACCEPT | (960,900) | 1 | (-1024,1) | outline |

默认背景B=(32,32,32)、前景F=(220,220,220)当p0；当p1则B=(220,220,220)、F=(44,44,44)。默认半笔宽h=16 Q4（轮廓总宽2像素）；无擦除，无纹理A=0/高斯σ=0/椒盐n=0,d=1；默认z按ordinal升序。默认矩形axis方向(1,0)，默认中心是16C；圆d像素→r=8d Q4；矩形W/H像素→局部半宽a=8W、半高b=8H Q4。family写r/c/half-Q4时不再乘16。

### D2. RNE、原几何及原mask

QR-IF02：所有整数分数RNE均最近值/恰半取偶，负数按符号对称；不使用floor代RNE。对(a/正b)，先按绝对值取q=floor(|a|/b)、余r，2r<b取q、>取q+1、=取偶，再恢复符号。bbox仍依QC：原Q4 extent的xmin=clip(floor(minX/16),0,W)、xmax=clip(floor(maxX/16)+1,0,W)，y同理用H；顺序xmin/ymin/xmax/ymax、半开且非空，负数floor向−∞。圆extent=c±r、矩形取原四角min/max，不加笔宽/擦除/ANN stroke，不借RNE改bbox。

12矩形方向来自D1固定(u,v)，不是浮点theta任选。令L=u²+v²、Q=2³⁰，C30=RNE(uQ/√L)、S30=RNE(vQ/√L)。这两个值以精确整数可判：对A=|u|Q或|v|Q，q=isqrt(floor(A²/L))；比较4A²与L(2q+1)²，决定q/q+1，恰等取偶，再恢复符号。角度仅报告atan2方向的说明，不驱动几何。局部角点按(-a,-b),(a,-b),(a,b),(-a,b)排序，(sx,sy)依次(-1,-1)/(1,-1)/(1,1)/(-1,1)；各dx=RNE((sx·a·C30−sy·b·S30)/Q)、dy=RNE((sx·a·S30+sy·b·C30)/Q)，加已锁Q4中心。量化后四角就是原GT，不能从识别拟合重写。

filled圆：P=(16x,16y)，|P-c|²≤r²，含等号。outline圆：max(0,r−h)²≤|P-c|²≤(r+h)²，含两界。矩形filled：按四原角的每条有向边叉积均≥0（上述顺序正有向），含边界；本表正a/b且方向非零，不接受退化四边形。矩形outline为四条有限线段圆端帽距离≤h的并集。原shape mask指这些谓词，不含后续擦除；circle bbox仍cx±r/cy±r，rect bbox四原角min/max，不加笔宽。

有限线段[A,B]：V=B−A、L=V·V>0、t=(P−A)·V；t≤0用|P−A|²≤h²，t≥L用|P−B|²≤h²，中间用cross(V,P−A)²≤h²L。端点含等号。所有比较先用主机完整整数；不对距离开方，不借浮点有限边。负primitive也复用这个raster谓词，但不成为GT。

原可观察事实：施加任何erase、z覆盖、低对比/纹理/噪声前，每个**正语义原shape**在W×H像素中心中若有至少一个original mask点，则进入GT；随后全部遮住、与B同色或被前层覆盖仍保留。没有原采样仅记录环境对象，不能在结果中当画内GT；负primitive始终无GT。bbox空且原可观察为真是fixture合同错误，停止SOURCE_COMPLETE而非删GT。原geometry/ordinal/bbox和该事实由scene独立计算，不读取DUT。所有形状有完整原geometry，失边不是把矩形GT换为三点/U。

### D3. 层、擦除及z-order

QR-IF03：每target/negative有独立original mask和erase mask；当前层paint mask=original AND NOT erase。背景先画，按指定z升序，当前paint=true的像素用其RGB覆盖旧颜色；被擦除仅让当前层透明，显露较低层，不把整图强制涂B。未被任何层paint的owner=BACKGROUND。z-order不改变原GT ordinal。全部层合成后执行D7噪声；高层覆盖及erase不返回GT反馈。

矩形边e0=corner0→1（上长边）、e1=1→2（右短边）、e2=2→3（下长边）、e3=3→0（左短边）。Q14/15均W=2H、axis，不含方形/长度判别歧义。整边擦除是距该**完整有限边含端点**≤h+g的闭capsule，g=32 Q4（2px端点guard）；该mask擦掉所选边的全部原stroke及顶点周围相邻边短片，不能只擦开区间、保角点连线。原几何不变。局部擦除端点=边A+RNE((B−A)·n/16)；所指分数含两端，capsule半径h+g，D4明确g。

圆弧擦除使用angular unit k=0…4095，周期4096、正方向随画面y增大。U(k)=(RNE整数(R64(Q·math.cos(θk))),RNE整数(R64(Q·math.sin(θk))))，θk=R64(tau·(k/4096))，tau和R64见D7，计算属于raster，不用DUT或atan2反馈。start=s/span=l：l0不擦、l4096全擦；其它A=U(s)、B=U((s+l)mod4096)，d=P−c。l≤2048用cross(A,d)≥0且cross(d,B)≥0；l>2048用两者的OR。该闭sector与原mask交集为erase。d0定为sector内（正半径outline通常不含中心）。metadata保存名义s/l/4096及实际被擦original像素数；不能把名义20%说有限采样刚好20%。

### D4. 24 family 的12个固定向量

下列每个有序列表第j项唯一对应D1的j；共享表/公式都是固定向量的压缩表达。`C(r)`指原圆，`R(W,H)`原矩形；除另注均用D1中心/mode/F/h/noise。每行明确数量/中心/方向等，不留可选值。

| family / fixture_kind | 精确12向量与替换 |
|---|---|
| Q01 POS_SINGLE | 一圆；d=[96,128,192,256,384,512,640,384,80,512,320,256]像素 |
| Q02 POS_SINGLE | 一axis矩形；(W,H)=[(192,96),(256,128),(384,192),(448,224),(512,256),(640,320),(768,384),(896,448),(160,80),(512,128),(320,160),(576,288)] |
| Q03 POS_ROTATED | 一R(640,320)，中心(960,540)像素，方向D1第j项；mode/p仍第j项；覆盖轴附近、斜角、跨象限，样本方向不限制算法允许旋转 |
| Q04 POS_SMALL_THIN | [C(d4),R(96,2),C(d8),R(128,4),C(d16),R(160,8),C(d24),R(256,12),C(d32),R(512,16),C(d48),R(768,24)]；矩形axis，其他默认 |
| Q05 POS_LARGE_CROSS | 12个(kind,cx,cy,r或W,H)见下表；全部filled，其它默认；含域外原geometry和全画面无显著轮廓的困难图 |
| Q06 POS_Q4_BOUNDARY | 12个原Q4中心/r或a,b/方向见下表；全部filled、h=8（仅原mask选outline时才用）；不先把亚像素几何round成整数像素 |
| Q07 POS_MULTI_CIRCLE | 数量K=[1,2,3,4,6,8,2,4,6,8,3,1]；第k圆r=16(40+8((j+k)mod4))，k0…K−1；中心见grid规则，mode第j项 |
| Q08 POS_MULTI_RECT | 同K/grid；第k矩形W=120+16((j+k)mod4)、H=60+8((j+2k)mod4)，方向索引(j+k)mod12，mode第j项 |
| Q09 POS_MULTI_MIXED | 同K/grid；k偶圆r=16(48+8((j+k)mod4))；k奇R(144,72)方向(j+k)mod12，mode第j项 |
| Q10 POS_OVERLAP_CIRCLE | 两圆同r=16(96+8j)，中心(960−δ/2,540)、(960+δ/2,540)像素；δ=[32,64,96,128,160,192,224,256,16,80,144,208]；ordinal0后景F，ordinal1前景F2，z0→1；mode第j项 |
| Q11 POS_OVERLAP_RECT | 两矩形中心(960−δ/2,540−δ/4)、(960+δ/2,540+δ/4)像素；δ同Q10；R0(360,180)方向j，R1(320,160)方向(j+3)mod12；z0→1，F/F2，mode第j项 |
| Q12 POS_OVERLAP_MIXED | C0 r160像素与R1(360,180)，中心(960−δ/2,540)、(960+δ/2,540)像素，δ同Q10；R方向j，mode第j项；固定彩色palette下文；j偶z C→R，j奇R→C |
| Q13 POS_CONCENTRIC_DUPLICATE | 一共同中心、全部outline/h8；原圆半径像素列表=[(96,144),(96,112),(96,100),(96,97),(96,96),(128,129),(96,144,192),(96,104,112),(160,161,162),(96,96,96),(48,49,50),(320,321)]，按列表ordinal/z；每项是真实独立原目标，不bbox去重 |
| Q14 POS_WHOLE_SHORT_EDGE | 一axis R(W=320+16j,H=160+8j)，中心D1、outline/h16；擦e1当j偶、e3当j奇，整边g32；其余噪声0；原矩形GT保留 |
| Q15 POS_WHOLE_LONG_EDGE | 与Q14全部参数相同，仅擦e0当j偶、e2当j奇；g32；各自scene_id/seedkey不同 |
| Q16 POS_CONTIGUOUS_ARC | 一outline圆，r=16(160+8(j mod4))，中心D1/h16；s=(257j+97)mod4096；l=[0,205,410,819,1229,2048,3072,4096,205,819,1229,2048]，按D3闭sector擦除 |
| Q17 POS_DISTRIBUTED_GAPS | 每scene两个outline/h16：圆中心(640,540)、r144像素；矩形中心(1280,540)、R(384,192)、方向j；圆K/L表与两矩形局部边段见下文；z圆0→矩形1；其他默认 |
| Q18 POS_LOW_CONTRAST | 每scene圆中心(640,540)、r128像素；矩形中心(1280,540)、R(256,128)、方向j；mode第j项。Δ=[0,1,4,8,16,32,48,63,64,65,96,128]，p0 B32/F32+Δ，p1 B220/F220−Δ（三通道同）；包括Δ0，GT不删 |
| Q19 POS_TEXTURE | 两shape几何/mode同Q18但B/F恢复D1默认；A=[0,4,8,16,24,32,0,4,8,16,24,32]；σ/椒盐0 |
| Q20 POS_GAUSSIAN | 同Q19 geometry/默认B/F；A0；σ=[0,1,2,4,8,12,0,1,2,4,8,12]；椒盐0 |
| Q21 POS_SALT_PEPPER | 同Q19 geometry/默认B/F；A/σ0；n/d=[0/1,1/1000,1/400,1/200,1/100,1/50,0/1,1/1000,1/400,1/200,1/100,1/50] |
| Q22 POS_COMBINED | 两shape/颜色/z同Q12但r160像素、R(360,180)固定；δ及A/σ/n/d/圆弧l见下表；全部outline/h16；圆s=(137j)mod4096，矩形擦e=jmod4的[4/16,12/16]，g16 |
| Q23 NEGATIVE_SOURCE | 0 GT；j0/j4分别与Q14同j的raster完全相同但先验为U；其余逐项negative primitive见D5；不以recognition output决定负标签 |
| Q24 NEGATIVE_BACKGROUND_DIGIT_CURVE | 0 GT；12个background/digit/curve及扰动见D5；此处无任何正target或强制成功/失败预言 |

grid按k0…7固定像素中心[(240,240),(720,240),(1200,240),(1680,240),(240,810),(720,810),(1200,810),(1680,810)]，再统一dx=16((j mod3)−1)、dy=16(((j div3)mod3)−1)像素。r式中的16是像素→Q4，grid坐标也乘16；K最多8是本组取样，不是算法上限。F2=p0时(160,160,160)、p1时(96,96,96)。Q12/Q22 circle palette按jmod3依次(240,80,40)/(40,200,240)/(200,240,40)，rect依次(80,240,64)/(240,64,192)/(64,96,240)；p1各通道改255−原值，背景仍D1。Y对比按原FE公式(77R+150G+29B+128)div256保存实际值，不按颜色名称宣称高对比。

| j | Q05：(kind,cx,cy,参数)，全部像素 | Q06：原Q4 geometry，全部filled |
|---|---|---|
| 0 | C(-64,540,r400) | C(cx160,cy160,r8) |
| 1 | R(1984,540,W960,H600) | C(cx160,cy160,r12) |
| 2 | C(960,-64,r600) | C(c=16C+(7,8),r1537) |
| 3 | R(960,1144,W1600,H800) | R(c=16C+(8,7),a769,b383,方向3) |
| 4 | C(0,0,r1024) | C(c=16C+(15,1),r2047) |
| 5 | R(1920,1080,W4096,H2048) | R(c=16C+(1,15),a1025,b511,方向5) |
| 6 | C(960,540,r500) | C(c=16C+(8,8),r3073) |
| 7 | R(960,540,W1400,H900) | R(c=16C+(7,9),a1537,b769,方向7) |
| 8 | C(960,540,r1200) | C(c=16C+(9,7),r4095) |
| 9 | R(960,540,W18000,H400) | R(c=16C+(0,8),a2047,b1023,方向9) |
| 10 | C(-32,540,r9000) | C(c=16C+(8,0),r6145) |
| 11 | R(960,540,W3000,H2400) | R(c=16C+(15,15),a3073,b1535,方向11) |

Q05矩形全部axis。Q06 C是该行D1像素中心，不是circle缩写时的C(r)；表中cx/cy/r/a/b已注明Q4，不能二次乘16。Q06/j0与j1是原16x中心r8/r12反例，GT均含中心(10,10)，不能采用+8删前者或使后者变四像素。Q05/j9 corners、j10 radius超原输出表示域是原场景事实，GT仍主机整数；算法拒绝则FN。

Q17圆gap K=[2,3,4,5,6,8,2,3,4,6,8,12]，每段L=[64,96,128,128,160,128,205,256,205,256,256,128]；第k段s=(97j+floor(4096k/K))mod4096，k0…K−1，erase为这些闭sector的并集。矩形第一个局部缺口e=jmod4，端分数[(2+jmod5)/16,(4+jmod5)/16]；第二个e=(j+1)mod4，端分数[(8+jmod3)/16,(10+jmod3)/16]；两段g8。报告每原参数区间/名义比例及实际erase像素，未借DUT轮廓倒推。形状之间不重叠，擦除皆各自layer。

| j | Q22：(A,σ,n,d,l,δ)，δ像素/l角度unit |
|---|---|
| 0 | (4,1,1,1000,205,64) |
| 1 | (8,2,1,400,410,96) |
| 2 | (16,4,1,200,819,128) |
| 3 | (24,8,1,100,1229,160) |
| 4 | (32,12,1,50,2048,32) |
| 5 | (16,8,1,200,819,64) |
| 6 | (8,4,1,1000,410,96) |
| 7 | (24,12,1,100,1229,128) |
| 8 | (32,8,1,50,2048,160) |
| 9 | (16,2,1,200,819,192) |
| 10 | (4,12,1,400,410,224) |
| 11 | (32,12,1,100,4096,0) |

参数推导的源账本如下，不是已生成 GT 的实测计数。本表正shape全部有原画内采样：filled 小圆中心/大形状交集在画内；axis outline有画内整数边点；旋转outline的原角位于画内且最近index中心距离≤√128 Q4<h16；GT可观察判断先于任何完整擦除/覆盖。半径Q4的Q06全部filled，j0/1另有显式中心点。未来GT实现若少了任何应保项须报fixture/audit错误，不按输出重定义此账本。

| split | scene数 | 原circle GT数 | 原rectangle GT数 | 总GT数 |
|---|---|---|---|---|
| DEV j0…3 | 96 | 75 | 71 | 146 |
| ACCEPT j4…11 | 192 | 179 | 172 | 351 |
| 合计（仅源分布，不作主质量门） | 288 | 254 | 243 | 497 |

Q23/Q24各split的GT恒0但其FP/functional_fail仍统计；其它多target数按原ordinal全部保留，包括Q13同几何重复。主recall目标的整数含义为ACCEPT圆TP至少171/179、矩形至少164/172；这只是门槛算术，不是能达95%的证据。完全擦掉、同图异GT、域外等困难例不因未来不达标而删除。

### D5. Q23/24 的负primitive与语义配对

Q23所有negative的中心D1、F/p/h16、背景D1；原negative支持区只是RGB来源，不入GT。局部点坐标为像素offset，乘16后加中心，不做矩形旋转，除列明方向/圆弧外均axis。closed polygon primitive只沿全部边stroke，open polyline只沿相邻点stroke、不自动末尾连首。负几何与正GT用途分开，不能把轮廓恰闭合升级正GT。

| Q23 j | 唯一negative recipe |
|---|---|
| 0 | 与Q14/j0相同四角/outline/h16/整短边g32 erase、中心/F/B/z/noise，原semantic=U；raster_key=QR1-Q14-V00；paired_scene=QR1-Q14-V00 |
| 1 | L polyline [(-160,-80),(-160,80),(160,80)] |
| 2 | 闭梯形 [(-160,-80),(160,-80),(112,80),(-112,80)] |
| 3 | 闭五边形 [(0,-120),(114,-37),(71,97),(-71,97),(-114,-37)] |
| 4 | 与Q14/j4所有raster参数完全相同，原semantic=U；raster_key=QR1-Q14-V04；paired_scene=QR1-Q14-V04 |
| 5 | 闭六边形 [(-160,0),(-80,-100),(80,-100),(160,0),(80,100),(-80,100)] |
| 6 | 原negative圆弧：centerD1/r160像素/outline/h16，擦s0/l1024；语义OPEN_CURVE，非被遮圆target |
| 7 | open polyline [(-180,80),(-120,-60),(-40,20),(40,-90),(120,40),(180,-20)] |
| 8 | 两条cross线段 [(-160,0),(160,0)]与[(0,-120),(0,120)]，同F，线段按表顺序z，无target |
| 9 | 闭ellipse polyline 128点，第k点Q4offset=(RNE整数(R64(2560·math.cos(θ[32k]))),RNE整数(R64(1280·math.sin(θ[32k]))))，k0…127，θ[32k]沿D3的angular index=32k；宿主与量化规则D3/D7，末点连首 |
| 10 | 闭star十点 [(0,-140),(33,-45),(133,-43),(54,17),(82,113),(0,56),(-82,113),(-54,17),(-133,-43),(-33,-45)] |
| 11 | open zigzag [(-180,-100),(-120,100),(-60,-100),(0,100),(60,-100),(120,100),(180,-100)] |

Q14/j0与Q23/j0属DEV配对、j4属ACCEPT配对，RGB逐字节同、original semantic与GT不同：Q14有一原rectangle GT，Q23无GT。Q23引用Q14只是负primitive的raster来源，不读取其算法结果，GT owner不把该支持模板误登记rectangle；source metadata保pair同图关系。相同raster_key的seed域也相同，禁止加scene_id噪声使配对悄变不同RGB。两组都保主集，不能因歧义删一方。

Q24固定如下。无正target，全为SOURCE_ONLY_NEGATIVE；背景/p仍D1，数字/curve用F、stroke h16；表未另列noise时A/σ/椒盐均0。

| Q24 j | 唯一原primitive / noise |
|---|---|
| 0 | 空背景B32 |
| 1 | 空背景B220 |
| 2 | 无primitive；texture A8 |
| 3 | 无primitive；texture A16 |
| 4 | 无primitive；texture A32 |
| 5 | bitmap digit2，cell s20像素 |
| 6 | bitmap digit7，cell s12 |
| 7 | bitmap digit3，cell s16 |
| 8 | bitmap digit8，cell s20 |
| 9 | 一条12vertex随机open polyline，curve PRNG域；无其它noise |
| 10 | 两条各12vertex随机open polyline，curve域连续消费，先curve0后1；同F |
| 11 | 一条12vertex随机open polyline；A16/σ4/椒盐1/400 |

数字是固定5列×7行bitmap，1-cell整个像素索引半开方块用F，0透明；top-left=(Cx−5s/2,Cy−7s/2)整数像素（s都偶数）。row-major，不引入字体/抗锯齿库。七行字串：digit2=`01110,10001,00001,00010,00100,01000,11111`；digit7=`11111,00001,00010,00100,01000,01000,01000`；digit3=`11110,00001,00001,01110,00001,00001,11110`；digit8=`01110,10001,10001,01110,10001,10001,01110`。这些是原数字负primitive，局部块似矩形仍GT0，FP必须计。

随机curve用D6的`curve`域；每vertex依次消费两个uint32 wX/wY，像素x=32+floor(wX(1920−64)/2³²)、y=32+floor(wY(1080−64)/2³²)，再乘16。每条顶点0…11，仅11个有限线段、不末尾连首；前后curve z升序。邻点相同则该segment以半径h点disk raster，不除0；该特例只负curve，不改变D2正矩形非退化要求。随机是固定SHA流驱动，不能从算法错误挑seed。

### D6. PRNG与seed唯一序列化

QR-IF04中的raster_key默认=scene_id，唯Q23/j0/j4按D5共享Q14 key；不包含GT、PROFILE、job、运行时间、host hash或DUT值。seed preimage为ASCII四行：`FPGA-QUALITY-RECIPES`、`v0.1`、raster_key、namespace，每行后一个字节LF，包括末行；无BOM/CR/空格/NUL。namespace只取`texture`/`gaussian`/`salt`/`curve`，区分大小写。seed32=SHA256(preimage)。文档版本另在来源freeze记录，seed不自含本卡SHA，避免循环初始化；改变recipe必须新版本，不保v0.1冒充同基线。

流block c=0…，payload=seed32原32字节||c的无符号64bit big-endian八字节，block=SHA256(payload)。每32byte按顺序拆八个uint32 big-endian；先block0的word0…7再block1。只用整数SHA定义，不用Python random/进程hash/系统熵；counter耗尽时fixture失败，不能回绕。输出像素i=yW+x严格row-major；texture用word i，gaussian第pair b用word2b/2b+1产生像素2b/2b+1（b与D1极性p不同），salt用word2i/2i+1；curve按D5。各域独立，不能借未使用noise域作流控调度。

即使A/σ/n为0，各域逻辑索引仍上述固定映射；实现可跳无效数学计算但不能改变非零像素的索引或其它域。PRNG消费不因shape paint/背景/GT数分支改变，texture在非背景不施加仍对应word i。生成不需要同时保存所有随机数，可按索引/流块保持有限cache；cache miss不能换seed或次数。

### D7. 纹理/高斯/椒盐与RGB舍入

选择的纹理是**仅合成后owner=BACKGROUND像素**的逐像素标量扰动，包括因layer erase透出的背景；目标/negative前景不施纹理。word w对应δtex=floor(w(2A+1)/2³²)−A，取值[-A,A]。它是此固定映射分布，不宣称有限图恰零均值或完全均匀。高斯与椒盐施于所有最终像素；同一像素RGB三通道用共同scalar扰动，避免把本测试选择冒称唯一相机噪声。

标准Box–Muller变换的固定宿主binary64实现：w0/w1为pair两word；u1=(2w0+1)·2⁻³³、u2=(2w1+1)·2⁻³³，严格在(0,1)，均二进制精确表示。tau固定binary64十六进制`0x1.921fb54442d18p+2`。R64表示每个所列中间算子各自存回binary64 round-to-nearest-even，禁止FMA/扩展精度合并；L=现有stdlib math.log(u1)，a=math.sqrt(R64((-2)·L))，theta=R64(tau·u2)，z0=R64(a·math.cos(theta))、z1=R64(a·math.sin(theta))。先z0给像素2b，再z1给2b+1；没有重抽尾样本、reject/clip z、缓存跨scene或与noise0共用另一算法。

每像素δgaussQ16=RNE整数(R64(R64(σ·z)·65536))；σ是D4整数字段，不在raster中估计/调整。base RGB为D3最后颜色；texture先相加，随后rawQ16=(base+δtex)·65536+δgaussQ16，RGB=clip(RNE(rawQ16/65536),0,255)。三通道分别clip，但共享两δ；不能先clip纹理再加高斯或把负值直接截断。math函数是具体宿主stdlib结果，非理论高斯无限精度oracle；有限PRNG/量化和有限样本真实均值/标准差另记录，不宣称实际恰σ。

最后椒盐：word2i=w、word2i+1=v；当d·w<n·2³²时该pixel被选择（严格<，n0总不选），v最高bit0→全RGB0、bit1→全RGB255，否则保上一步RGB。概率n/d为精确有理阈值，不把百分数字符串转float，不要求随机选择像素数恰nN/d。sigma/noise比例只定义合成输入，不改变GT/算法admission。

圆弧/ellipse raster使用同宿主math.sin/cos、同tau与R64；k/4096二进制精确；Q30/ellipse-Q4整数量化均RNE。它只为独立输入primitive建立mask，不是R3数值黄金。当前不证明不同math实现/平台得到同字节；实际SOURCE生成须保存该运行stdlib/module指纹、seed首块检查及完整RGB SHA，复现时全图比较。迁移差异保旧图，核设计影响，不能只因视觉接近称相同。

### D8. 输出/GT/冻结接口与组合检查

QC-IF01/02仍原schema方向，不直接修改旧卡。拟scene记录包含schema=`QR-SCENE-1`/recipe_version/scene_id/family/j/split/W/H/raster_key/完整原shape及negative/颜色/z/mode/h/erase/noise rational/pair引用；原geometry只有整数，noise字段σ/A/n/d整数。GT沿QC：同scene/尺寸/scene-source hash/full RGB SHA，每原可观察正shape保存class/ordinal/original geometry/bbox及原可观察/擦除事实；negative/不可观察环境单列、不作为预测。JSON未来规范为UTF-8无BOM、ASCII转义、键按Unicode码点升序、无空白分隔、整数十进制无前导0、末LF；拒重复key/非整数几何/NaN/Inf，不能读回float窄化GT。

输入RGB每行6小写hex `rrggbb`、LF、恰N行无空白/前后缀；字节数N×7=14515200/scene。转FP时按原lane0低位，把连续两RGB24作为lane0/lane1双48，并由同scene产生坐标/markers；GT不连接FP。完整主质量288图、GT、scene参数分别冻结真实SHA；288个scene_id唯一，但两个歧义pair RGB SHA应相等不是重复scene。表/recipe输入不存在GT输出的反馈，避免初始化环。

逐连接检查：EXPAND只需f/j及本卡表即可给全原参数；RASTER得到原layer/erase不需算法结果；GT能从相同原shape独立给bbox，不看noise可见度；noise只读raster_key及固定参数；freeze待全RGB/GT落盘真实校验，不等识别结果；算法只读冻结RGB/PROFILE；QC统计只用合法完整终态。假成功/部分图/改recipe/错pair/hash或漏一个scene使audit失败，不能把错误scene跳过缩192。全图自然SEARCH/CAPACITY保ACCEPT原GT全FN；故意协议注入属于另STRESS，不向本288场景添加动态调度标签。

## E. 局部中文操作草图及可展开次序

E01 EXPAND：按f升序1…24、j升序0…11读共同向量→锁固定split/p/C/mode→先套默认→按family替换数量/全部shape原geometry/z/colors/noise→应用明确单向量特例/paired raster_key→检整数域/ordinal/边非退化/表索引→保存原scene候选；不读取算法/PROFILE/系统时间选参数。任何缺字段/不相容是设计/fixture错误，不任选补值。

E02 ORIGINAL_MASK/GT：逐shape在画内所有index中心用D2原谓词检查原可观察事实→不改变scene geometry→按QC整数bbox形成GT→negative只记录支持primitive→gtordinal保持原shapeordinal（不可观察环境不重排原ordinal）→包含pair链接及原擦除参数。绘制后的全遮/低对比不参与此判断。GT完成不代表识别正确。

E03 RASTER：逐row-major像素先B/ownerBACKGROUND→按z扫描原layer→用整数filled/finite outline/原circle判断→与该层erase取反→paint则覆盖RGB/owner，否则保低层→得到无noise RGB。整边含端点guard，圆sector先按固定宿主unit方向量化；相邻层原mask保存为只读，不被painting改为GT。

E04 NOISE：由raster_key分别建四SHA域→按i索引读texture/高斯pair/salt→texture只在BACKGROUND施加→标准Box–Muller标量Q16→整数总和RNE/clip→椒盐最后全RGB替换→输出6hex/LF。全scene结束检查恰N、seedkey/stream计数/实际扰动统计；取消或生成错误留INCOMPLETE，不能输出伪COMPLETE/hash。

E05 FREEZE：先检查288 unique scene、96DEV/192ACCEPT、每family4/8、pair引用和同RGB、全部尺寸/格式/原GT/来源/schema→记录真实输入/GT/scene及工具/生成器SHA→源完整才freeze。生成器源码/实际输入不存在时只保本设计，不写假manifest。未来DEV仅调已批准PROFILE候选；在首次ACCEPT识别输出前冻结生产模板，GT或scene不能据输出改标。

E06 RECOVERY：原run/hash/失败不覆盖；从相同冻结scene重新生成是另run并全字节比较，产生差异先停源freeze并查宿主/版本/公式/stream错；算法恢复成功是另job，不消除原FN/functional_fail。数据生成不强制执行生产rst/下载；温reset和真实DDR/IO关闭由各自合同。

## F. 语言、资源和软件到硬件对应

Python3.14.6标准库方案：几何/GT/IoU/PRNG阈值使用任意精度整数，显式拒bool、负尺寸、非法索引/class、重复ordinal、非finite数；新scene为独立不可变值，raster/noise cursor不能修改GT原对象。无C++/新ABI/安装依赖；高斯/圆弧仅独立源raster/noise使用现有binary64 math，整数RNE/clip不借隐式窄化。输出副作用只在未来批准路径，新run目录，旧文件不能覆盖。并发scene若未来采用须各自独立流/输出/owner，不共共享随机状态；本卡固定输出顺序f/j。

主机空间允许逐行/逐像素stream；无须288帧同时驻内存。每RGB原字节3N=6220800，文本14,515,200B；288文本合计4,180,377,600B，仅输入，不含GT/scene/算法中间/日志。四流只需有限32B block/word cursor与一高斯pair，circle/rect等layer数最多本表8，GT最多本表8但不是生产keeper限制。disk/wall预算与算法/完整套件时间仍需共同设计；这些是静态量，不宣称生成已执行或资源服务通过，不把主机容量填FPGA RAM。

| RTL A–L | 本卡边界 |
|---|---|
| A 数值 | RGB8/24、双48与原FP；原geometry主机全整数，GT不窄化为输出signed18/r17；noise/raster浮点不做R3黄金 |
| B 时钟/观察 | 本卡不新增clock；真实驱动/采样/观察沿由全机TB合同，生成图无FPGA时钟 |
| C 接受/交付 | 原FP真实fire才消耗pair，输入不能按主机生成速度假fire；GT非DUT端口 |
| D valid | 气泡不消耗图像record；非法/失败输出prefix不作合法预测 |
| E 反压 | 冻结RGB/GT不随stall改变，held pair及sideband由正式适配保持 |
| F 吞吐 | 源生成wall、模型wall、DUTcycle/服务独立；不把Box–Muller或主机stream速率当fps |
| G 复位 | scene freeze跨run有效，job reset影响真实旧事务/失败报告，不改源GT；全机epoch另设计 |
| H 配置 | recipe不依PROFILE；DEV选择/首ACCEPT前冻结profile，完整原J使用其快照 |
| I 存储 | 主机文本/GT不代生产DDR，真实SRC/GRAD/CLO/RECORD容量/端口/关闭仍原联合合同 |
| J 身份 | scene/raster_key/pair与真实RGB SHA、PROFILE/J/term逐项关联；GTordinal不同FINAL slot |
| K CDC | 本卡无新CDC；CSI/DDR/HDMI适配仍全机多域，主机图片不能替CDC证明 |
| L 实现 | 只拟独立work质量目录，旧R1只读；本卡无RTL/RAM综合或bit产物 |

三份对应分别为：①scene生成独立原RGB/GT，数学算法仅从RGB+PROFILE生成预测；②硬件按原FP/OBJ/NUM/TERM及实际关闭履约，不能以函数返回冒作fire；③两路用同冻结输入/配置/完整身份比较全部记录/ANN和质量，质量统计与数值/协议等价分开。未来计划目录 `_fpga_edge_agent/work/active/track4_algorithms_20261004/quality/`，拟符号 `scene_recipe_expander`、`source_rasterizer`、`source_noise_sampler`、`original_ground_truth`、`quality_source_freezer`；全部未生成，具体执行文件/runner共同基线仍I项。

## G. 实施与验证计划（全部NOT_RUN）

审批前先联合审读可展开表、field/schema/seed/舍入、独立方法/覆盖、工具和计划文件基线；不要求先生成输入或运行未获批模型以取得READY。正式批准后按scene结构→独立原mask/GT→raster/noise→source freezer→原QC评价/整包RTL映射实施，任何数值/scene/schema改变先回设计和相应批准。

| TEST | REQ/IF/条件 | 独立期望与方法，未来实际判据 |
|---|---|---|
| QR-T01 | 01/08；全部f/j | 展开288，96/192，每family4/8，身份唯一，无缺/额外/随机任选字段；分别核原参数与表 |
| T02 | 02；Q06 j0/1、Q05域外 | 16x中心r8/r12均有(10,10)；bbox沿floor/+1；域外GT不窄化/删，可见度变化不改原GT |
| T03 | 03；全部12旋转/finite边 | 精确整数Q30归一化及RNE tie正/负；角点/边界/端帽、filled/outline mask与独立直接几何检查相同 |
| T04 | 03；Q14/15/17 | 完整所选短/长边stroke及端点guard均被擦，邻边局部guard明示；局部gap端点/圆sector0/半周/全周无反向或开端错误 |
| T05 | 03/07；Q14与Q23 j0/j4 | 两对全N RGB及真实SHA相同，scene_id/split各固定，GT分别一矩形/零；不得把负支持模板当GT |
| T06 | 04；seed各域/首末block | preimage ASCII/LF/大小写/BE64/BE32与手工可核摘要；no-noise与shape branch不变索引，盐阈值等号不选 |
| T07 | 04；σ0/最大word/round-half/clip | u严格(0,1)，Box–Muller宿主/每中间量/顺序与全SHA；noise0恒等；Q16负数RNE/clip及salt最后优先 |
| T08 | 05；Q18Δ0/Q16全擦/overlap | 原可观察GT仍在，未把噪声后mask或前层可见度作为筛选；一/多/六/八目标和domainfail均不删 |
| T09 | 06；Q24及算法失败 | GT0背景/数字/curve仍计FP及functional_fail；自发SEARCH/CAPACITY全FN保主集，DEV不可混主门 |
| T10 | 01/08；文件/宿主改动/中断 | N行及精确文本bytes、complete前全hash、改变seed/平台/source或漏scene使audit失败；新run留旧输入失败 |
| T11 | 07；冻结源到正式DUT | 同RGB/profile/完整J对应，FP顺序坐标/markers、真实TERM/RECORD全合法再质量评价；原全机协议覆盖另执行 |

所有运行均未执行；未来保存实际输入/参数/hash/数值/匹配/计数/错误日志，不只有PASS字符串。测试方法成熟与实际执行分别登记；不把实测STA或实际图SHA缺失当审批前必须执行门，也不把目前仍未确定的全机执行设计忽略。

## H. 双向追踪

| REQ/原来源 | MOD/IF/草图 | 计划符号（未生成） | TEST/独立期望 | 当前证据 |
|---|---|---|---|---|
| QR01；QC D5/QC-B01 | EXPAND/IF01，D1/D4/E01 | scene_recipe_expander | T01/10；288及固定表 | 纯文字候选 |
| QR02/05；QC D1/D2 | MASK/GT/IF02，D2/E02 | original_ground_truth | T02/03/08；原16x/可观察/整数bbox | 来源实读，未生成GT |
| QR03；QC Q14…17/Q23 | RASTER/IF03，D3/4/5/E03 | source_rasterizer | T04/05；完整边/两组同RGB异GT | 几何推演，未生成图 |
| QR04；QC D1noise | NOISE/IF04，D6/7/E04 | source_noise_sampler | T06/07；独立SHA流/舍入/宿主 | 只读宿主hash，未执行 |
| QR06；QC D3/D4/IF05 | FREEZE→原QC，D8/E05/06 | quality_source_freezer/原质量parser/matcher | T09/10；192主集/真实失败 | 原合同，不填P/R |
| QR07/08；QC F/G/根v0.2 | 正式算法/runner边界，C/F/G/I | 后续共同quality_job_mapping | T11；合法完整身份/真实fire/结果 | 全机联合OPEN |

反向：五拟源模块只服务固定原scene/RGB/GT/来源freeze，不承担形状识别、NUM/OBJ、生产DDR或GT到DUT捷径；所有family/negative/PRNG/erase均可回QR01…08与原QC分布。无实现代码/参数更新点可核，未来逐真实符号和日志完成双向映射。

## I. 门槛、实际OPEN及审批边界

QC-B01的几何/24×12/配对/PRNG/舍入具体选择已在本卡给出完整候选，没有“任选/TBD参数”来形成不同RGB；**尚待独立全文审读和QC联合采用**，不是已生成/冻结manifest，也不直接把旧QC-B01状态改已闭合。若审读发现某元素不能按表唯一展开，列真实设计缺口并修新版本，不以实际生成替代未定合同。

| OPEN | 审批前仍需具体完成的工作 |
|---|---|
| QR-B01 联合schema/方法 | QC v0.1与本卡需共同采用版本、scene/GT完整键/错误/环境项schema、source工具与拟实际文件基线/独立review方法及全部数值/源测试覆盖；本卡是新附件，未自动修改QC |
| QR-B02 PROFILE | QC-B02八精确PROFILE与DEV选择/生产冻结规则、资源/质量/时间目标仍原OPEN；本卡不以默认值或GT内容设置阈值 |
| QR-B03 全机映射 | QC-B03完整参考、R4/LOAD/GRAD/父结果/record parser、J/输入身份映射、对应生产RTL及协议case/许可/停止条件未共同冻结 |
| QR-B04 资源服务 | QC-B04生成/套件disk与wall、主机/RTLcycle timeout、production最坏服务/资源设计仍联合OPEN；实际图SHA/仿真/synth/STA批准后才取，当前NOT_RUN |

十项门槛：①B有正常/边界/歧义例；②C职责连接；③D完整候选参数和接口组合；④E局部中文草图；⑤F语言/三份对应；⑥D8/G局部及组合走查覆盖；⑦G/H计划追踪；⑧无阻塞仍不满足，上述联合设计/独立审读未完；⑨写后实际全文读回/hash/入口报告，不预写已通过；⑩来源和本卡范围清楚，完整实施基线尚未联合批准。总体NOT_READY、READY时间N/A；不请求现在批准未成熟整包。实际源码/图/GT/仿真/综合/STA/bit均NOT_RUN，不构成要求先执行再获批的循环。

## J. 变更与恢复

本卡是QC-B01候选具体化：保QC中心16x/原GT/ACCEPT主门，新增288精确参数、层/finite erase、纯negative与SHA/Box–Muller规则。旋转样本、scalar灰度高斯/background-only纹理是明确工程选择，不等同官方限制；往后修改任一fixture/seed/noise/GT要新版本、差异与原失败保留，不能以内部优化悄变图。宿主迁移不保证math位一致，先核完整运行指纹/全图SHA再定相容；不得给DUT修改GT/scene反馈通路。

## K. 实现与验证实录

本次实际行为只有按入口有序阅读、QC/template全文、FE及既有模型有限只读、宿主二进制静态hash、文字候选和本卡保存读回。无Python执行、图像/GT/manifest生成、业务实现、功能脚本/TB、测试、工具构建、网络安装、硬件或正式状态/审批/数据库变化。旧QC C7A9…、HP、review、LOAD3E935…及其25AFA…快照、R1入口均保持只读。最终本卡完整SHA/bytes/行数以读回报告记录，不在本卡自包含自身hash。

## L. 交付阅读路径

先B/C理解整体，再D1共同12表和D2原几何，再D3 layer/erase及D4全部family，最后D5负例/配对、D6/7确定随机与量化、D8 freeze；E给展开和运行职责次序，F/G/H/I说明依赖和检验。完成的是可审读recipe候选；全输入/GT/实际质量/完整软件及工具目标尚未完成。理解验收待用户实际作答，不以本说明代签。
