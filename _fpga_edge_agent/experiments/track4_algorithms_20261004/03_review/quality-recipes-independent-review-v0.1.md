# QUALITY-RECIPES v0.1 独立静态审阅

2026-10-05；审阅对象是 [QUALITY-RECIPES v0.1](../../../planning/design-TRACK4-ALGORITHM-QUALITY-RECIPES-001.md)，不是实现/输入/算法质量验收。结论：288 场景参数、整数几何、有限擦除、噪声索引及原 GT 数量在本次有限静态核查中一致；未发现需要“任选”才能展开本表原几何的参数歧义。发现并证明了未单独列为 pair 的额外同 RGB 异 GT 关系，见 R01。它是必须如实保留的可辨识性限制，不是删场景/改 GT/降要求的理由，也不能据此宣称全局 95% 必定通过或失败。主卡继续 **NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN**。

## 1. 授权、实读范围和证据边界

本轮只获准新增本审阅文件。QUALITY-RECIPES、QC、其余计划/来源、R1/五交付入口、正式状态/审批/数据库全部保持只读；未生成图像、GT、manifest、模型、业务代码、功能脚本、TB，未执行 Python、场景展开器、功能测试、build、网络或硬件步骤。静态计算只使用本文参数的整数常量/算式及文件哈希，没有运行任何 scene/raster/noise 实现。

| 实际读取/核验对象 | 范围和用途 | 真实 SHA256 / 大小 |
|---|---|---|
| QUALITY-RECIPES | 实际全文分 L1–125、L126–239、L240–362 读回；后再次核 hash | E9A01C616F7EC03880C402BB021EC5A13137FF35BDEB2F8E25A784E69AD000A0 / 44821B / 362行 |
| [QUALITY-CORPUS](../../../planning/design-TRACK4-ALGORITHM-QUALITY-CORPUS-001.md) | 本轮 L55–145 实读及匹配/输出域/统计关键搜索；没有冒称本轮全文216行重审 | C7A9A387FC7AB17FC6AE4BFFA16F8DB618973DE36A148B305AE691C657A68569 / 26196B / 216行 |
| 根 v0.2 / PLAN_TEMPLATE | 既有任务实际读过规则/模板，本轮重新 hash未变；根规则61102B、模板10341B | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 / 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| FRONTEND v1 | 本轮仅核 hash，未重新全文审阅；本审用 recipe L153 已明确的 Y公式 | 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114 |

有限并行第二读者只读核 recipe 数量/可观察/bbox/配对，禁止文件写入/生成/执行；其静态计数和全灰同图证明与主审独立复算一致。作者自查和本审查不等于实际GT/输入冻结；本审也没有替用户签理解验收或指定实现批准。

主卡 A 的五个宿主文件本轮实际读取 bytes/SHA，与卡逐一一致：

| 只读文件 | bytes / SHA256 |
|---|---|
| D:\py___\python.exe | 106208 / 03168C01B7B7491423350E82C26FEE71F35B43694D1319D3C668BDA6903A0C38 |
| D:\py___\python314.dll | 6778592 / FDE89CDB5C2D08AE65DE7EF4ABCA1876C93BA3796002F5AC0BF7E4D4F5A94DA0 |
| D:\py___\vcruntime140.dll | 120400 / 052AD6A20D375957E82AA6A3C441EA548D89BE0981516CA7EB306E063D5027F4 |
| D:\py___\vcruntime140_1.dll | 49776 / 6A99BC0128E0C7D6CBBF615FCC26909565E17D4CA3451B97F8987F9C6ACBC6C8 |
| C:\Windows\System32\ucrtbase.dll | 1377512 / 5C52E3A303BAAAC0E0AF8BD9B96134993DA34BC9D834A31EF37E1D2CDC7FE192 |

这些是静态文件一致性，不能证明 Python 实际加载了哪些模块/DLL或跨平台 math 位一致。本轮没有启动解释器；卡 L37–47/253–259 已承认这一范围，并把实际运行模块/平台指纹与真实 RGB SHA 留给批准后的 source freeze。缺少尚未生成的图SHA/仿真/STA不是要求批准前先执行的门槛。

## 2. 288 身份、数量与原可观察审查

QR1-Qff-Vjj 中 ff=01…24、jj=00…11，四DEV/八ACCEPT，24×12=288、24×4=96、24×8=192；唯一 scene_id 与唯一 RGB 不是同一命题。D1默认→D4 family替换→明确单向量特例给出固定次序，Q23/j0,j4的 raster_key 复用 Q14明示；不用当前PROFILE/job/GT/DUT值更改seed或几何。

逐 family 原shape数如下。所有项按遮挡/低对比/前层覆盖之前的 original mask判断；Q23/Q24负primitive不是GT。

| family | DEV circle | DEV rectangle | ACCEPT circle | ACCEPT rectangle |
|---|---:|---:|---:|---:|
| Q01 | 4 | 0 | 8 | 0 |
| Q02 | 0 | 4 | 0 | 8 |
| Q03 | 0 | 4 | 0 | 8 |
| Q04 | 2 | 2 | 4 | 4 |
| Q05 | 2 | 2 | 4 | 4 |
| Q06 | 3 | 1 | 4 | 4 |
| Q07 | 10 | 0 | 38 | 0 |
| Q08 | 0 | 10 | 0 | 38 |
| Q09 | 6 | 4 | 20 | 18 |
| Q10 | 8 | 0 | 16 | 0 |
| Q11 | 0 | 8 | 0 | 16 |
| Q12 | 4 | 4 | 8 | 8 |
| Q13 | 8 | 0 | 21 | 0 |
| Q14 | 0 | 4 | 0 | 8 |
| Q15 | 0 | 4 | 0 | 8 |
| Q16 | 4 | 0 | 8 | 0 |
| Q17–Q22，每一family | 4 | 4 | 8 | 8 |
| Q23/Q24，每一family | 0 | 0 | 0 | 0 |
| 合计 | **75** | **71** | **179** | **172** |

Q07/Q08的K DEV=1+2+3+4=10、ACCEPT=6+8+2+4+6+8+3+1=38。Q09按k偶/奇分别ceil(K/2)/floor(K/2)：DEV6/4，ACCEPT20/18。Q13 DEV=2+2+2+2=8；ACCEPT=2+2+3+3+3+3+3+2=21。Q06/j0…3是C/C/C/R，应计3/1，不能按其它交替表误计2/2。总circle254/rectangle243/GT497，与 recipe L193–195相符；这是参数推导，不是已生成GT实测。

原可观察与bbox核查范围：

- Q06/j0,j1中心Q4=(160,160)，r8/r12，原像素中心(16x,16y)中(10,10)的距离0，两项均保GT。相邻index中心距离至少16>12，因此filled均只有该原中心采样；其GT bbox按extent/floor/+1是[9,9,11,11)，不把bbox面积4解释成4个paint像素。采用16x+8会让r8无采样、r12出现四点，确属不同坐标合同。
- Q05全部filled，不因缺少显著画内轮廓删除。j0圆在(0,540)、j1矩形在(1600,540)、j2圆在(960,0)、j3矩形在(960,900)、j4圆在(0,0)、j5矩形在(1919,1079)均有原采样；j6…9/j11中心或画内点可观察，j10在(0,540)到原圆心仅32像素。负/域外角点用主机全整数，clip只用于bbox，不重写原geometry。
- 正旋转outline族的角点在画内，nearest pixel center每轴Q4偏差≤8、总距离≤√128<16=h，故原有限stroke有画内采样；Q13 h8圆仍有整数像素半径的画内cardinal点，不套“旋转h16”证明。当前表所有正shape的原extent与画内相交且bbox非空；未发现实际本288表的 observable=true而bbox空反例。
- Q05/j9轴矩形W18000，角x最大9960像素→Q4=159360，超过signed18正界131071；j10半径9000像素→Q4=144000，超过r17最大131071。这是场景事实，不是可删GT理由。QC只按同类bbox IoU匹配：不能仅凭原几何超输出域，直接推出所有合法替代bbox必不匹配或该帧必FN；算法实际拒绝/失败才按原规则FN。

召回门槛复算：圆20TP≥19×179=3401，TP170时3400不足、TP171时3420够；矩形20TP≥19×172=3268，TP163时3260不足、TP164时3280够。因此圆至少171/179、矩形至少164/172，各最多8FN。**这只是recall整数门，不是算法达到95%证据，也不自动满足precision。** 同类precision还需TP≥19FP；例如171TP/10FP、164TP/9FP仍失败。没有实测TP/FP/FN/P/R/fps。

## 3. 几何、有限擦除和配对逐项审查

### 3.1 16x、Q30与RNE

D2对a/正b取绝对值q/余数后恰半取偶并恢复符号，负数不是向0/向−∞偷换。Q30归一化中q=isqrt(floor(A²/L))等于floor(A/√L)；midpoint比较4A²与L(2q+1)²正好判q和q+1距离/恰半，避免用浮点角度驱动正矩形。C30/S30各有精确整数选择，(1,0)给(Q,0)，负方向对称；各角dx/dy再各RNE，从四原角直接定义GT和filled/finite-outline。

顺序(-a,-b),(a,-b),(a,b),(-a,b)为正有向，rotation矩阵det=C30²+S30²>0；当前表尺寸和角不会形成退化边。filled用四叉积≥0，outline用有限capsule而非无限直线；t≤0/t≥L的端帽、内部cross²≤h²L各含等号，整数域全宽，无距离sqrt或R3拟合反馈。bbox使用原extent负floor、max的floor+1、clip，不加stroke/erase。h8与h16、像素→Q4乘16、直径→r8d、矩形半宽8W/8H和Q06显式Q4参数没有二次乘16歧义。

### 3.2 整边与局部缺口

Q14/Q15都axis且W=2H，e0/e2为长边、e1/e3为短边；整边erase是原有限边含端点、半径h+g=16+32=48 Q4的closed capsule。原该边所有stroke满足dist≤h，也满足≤h+g，故整边与顶点周边短段确实全去；不是留两个角点再把完整短边识别为“缺中段”。局部缺口端点先RNE((B−A)n/16)，Q17 g8、Q22 g16固定，各layer erase只透明当前层，低层仍显示，不误涂整图背景。z修改RGB覆盖但不修改原GT ordinal/geometry。

Q14/j0原像素角为(320,190),(640,190),(640,350),(320,350)；Q14/j4为(448,624),(832,624),(832,816),(448,816)。两项都擦e1、outline/h16/g32。Q23/j0,j4明确复用完全相同raster参数和raster_key，负U不登记GT。前景、背景、paint/erase以及当前0noise相同，必然逐像素同RGB；DEV和ACCEPT各一对，GT分别一矩形/空。semantic不同不准进入seed或noise owner分支变图。

### 3.3 全擦与重叠仍在主集

circle sector0不擦、4096全擦；其它l≤2048 AND/l>2048 OR的两叉积门定义有限量化sector，周期/start/端点含等号明确，名义l/4096不是有限采样的精确erase百分比。Q16/j7 l4096让圆paint完全空但原可观察GT仍在；Q22/j11 l4096同样全去圆，δ0重叠不使circle GT消失，原rect也仍在。Q22噪声从合成后RGB加，不把噪声生成的轮廓反向作为原circle证据。

Q13/j4两项r96、j9三项r96都是各自独立语义原目标。默认相同颜色、同中心、outline/h8、noise0，重复paint不增加像素信息，但原ordinal/bbox不能去重：ACCEPT这两帧分别计2/3个circleGT；只输出一个同bbox圆则分别最多匹配一个、留下1/2FN。算法可以多预测以换取匹配，但RGB本身不能普遍证明隐藏原目标重数，不能据此声称任意同心场景保证95%。

## 4. R01：额外确定同 RGB / 异 GT 关系

### 4.1 ACCEPT三帧全灰220，GT bbox不相容

不执行raster或SHA，仅按整数predicate即可证明：

| scene | 参数事实与全图paint | 原GT |
|---|---|---|
| QR1-Q05-V08 | filled C(960,540,r1200)，p0 F220；全frame最远原pixel center在(0,0)，dist²=960²+540²=1213200<1200²=1440000，所有点在圆内 | circle1，bbox[0,0,1920,1080) |
| QR1-Q05-V10 | filled C(-32,540,r9000)，p0 F220；最远原pixel center为(1919,0)，dist²=1951²+540²=4098001<9000²=81000000，所有点在圆内 | circle1，bbox[0,0,1920,1080) |
| QR1-Q16-V07 | p1 B220，outline圆c=(480,810),r=160+8×3=184，l4096全erase，所有pixel无paint；A/σ/n=0 | circle1，原点(664,810)可观察，bbox[296,626,665,995) |

三帧全部ACCEPT，RGB均每个像素(220,220,220)；raster_key/seed不同不改变0noise结果，所以未来真实RGB字节及SHA也应相同。前两GT bbox面积A=2073600，第三面积B=369²=136161；若一个prediction与A的IoU≥0.5，其面积至少A/2=1036800；若同一个prediction与B的IoU≥0.5，其面积至多2B=272322。这两个必要条件相矛盾，**没有单个bbox可同时匹配这两种GT**。

这不等于整集95%必不可能。对于只用同RGB/同PROFILE、不利用scene/GT或ID作答案的固定算法，三帧的预测集合相同；输出两种bbox可三帧都得TP但会产生FP，或选一种产生部分FN。实际集上其它TP/FP预算和全部功能结果仍需未来运行。不能从这三帧直接算出整类最优上界，更不能以场景ID查表“识别”。主卡 QR03说至少两组Q14/Q23配对，没有声称RGB只允许那两组相等；此发现不使参数展开不唯一，但额外相等关系应在联合source审计/解释中保留。

### 4.2 DEV全灰32与其它无信息场景

QR1-Q18-V00 Δ0、p0 B=F32、noise0；其circle/rectangle原可观察、GT两项，合成后全灰32。QR1-Q24-V00无primitive/空B32、noise0、GT空，RGB同。此为DEV额外同图异GT，不混入ACCEPT主统计。Q05/V11 filled轴R(960,540,W3000,H2400)覆盖全图，p1 F44，原rectangleGT仍在但画内没有形状轮廓。Q16全擦/Q22全擦、Q13真实重数及上述全图均是已固定测试事实，不作为恢复对比64/遮挡20%/≤4目标/尺寸门或删主样本的依据。

R01建议：保持全部recipe/GT/split原样，在未来共同schema/manifest审计允许并记录所有确实同RGB关系，防止错误地要求288个RGB SHA都唯一；清楚区分固定集合质量目标与任意像素输入下的语义可辨识性。当前报告不修改主卡、不输出新的GT或pairmanifest，也没有追加对用户批准前生成输入的要求。

## 5. seed、精确索引、noise0与binary64核查

### 5.1 序列化和索引闭合

四行ASCII preimage含末LF，无CR/BOM/NUL；seed32明确是SHA256的原32字节，不是32bit整数。block seedbytes||BE64 counter再SHA，顺序八BE32 word，无Python random/hash/time或DUT反馈。namespace texture/gaussian/salt/curve独立，raster_key默认scene且Q23两对复用Q14；即使noise0或paint分支跳计算，逻辑word索引仍固定。

N=2073600：texture对应word0…2073599；gaussian pair b=0…1036799用word2b/2b+1共word0…2073599，z0→pixel2b、z1→pixel2b+1；salt pixeli用word2i/2i+1共word0…4147199。curve每vertex两个word、每条12vertex24word，Q24/j10两条连续48word。流控随机调度不能挪用这些word，counter不能回绕。无需实测firstblock便可核索引定义；firstblock真实摘要属于批准后执行测试。

### 5.2 纹理→高斯→椒盐及恒等零参数

纹理只给最后owner=BACKGROUND，含erase透出的背景，前景/negative皆不施；δtex=floor(w(2A+1)/2³²)−A固定。A0时所有合法w<M=2³²，floor(w/M)=0，故δtex0。σ0时u1/u2严格(0,1)、z有限，R64(0·z)为±0，RNE整数得到δgaussQ16=0；因此不会把纹理后的值改成未纹理的原base，也不重抽word。rawQ16=(base+δtex)65536+0，整数RNE等于base+δtex再clip；本表BG32/220和A≤32使纹理本身范围0…252。n0时dw<0永假，盐不替换。这分别证明全noise0恒等及“已施texture、后高斯σ0不撤销/修改它”。

u=(2w+1)2^-33的分子≤2^33−1，在binary64精确表示且上下界开放，log/sqrt没有u=0/1重抽歧义。tau固定0x1.921fb54442d18p+2；log→-2L R64→sqrt→theta R64→cos/sin→z R64，随后σz和Q16各R64、RNE、通道整数总和/clip、盐最后。禁止FMA/extendedprecision、先cliptexture或负数截断，三通道共享scalar但分别clip。它是已指定具体Windows宿主的fixture选择，不是FPGA数值oracle或跨平台正确舍入math保证；有限图的真实均值/σ须以后报告，不能现在称实测恰名义σ。

### 5.3 椒盐阈值的离散语义

选择谓词dw<n·2³²（严格<）及v最高bit0→全黑/1→全白唯一，maxuint32/边界没有float概率转换。n/d是精确**阈值参数**；即使把uint32视为均匀分布，实际格点选择数是ceil(n·2³²/d)，不应额外声称分布概率恰等n/d。例n/d=1/200选择w0…21474836，共21474837个；1/400选择10737419个。有限SHA场景实际选择pixel数更不保证nN/d。卡 L257已经规定不要求精确pixel比例，本审将此作为术语澄清，不视为需要更换映射的构造歧义，不重写n/d或GT。

## 6. 输出、联合OPEN和静态结论

源文本N×7=14515200B/scene、288份合4180377600B，3N原RGB6220800B；计算与recipe L265/287一致。每行6hex rrggbb/LF、两像素lane0低位、几何整数不窄化/JSON拒NaN/重复key的方向清楚；GT不连接DUT，不从识别结果拟合，功能失败GT全FN，SEARCH/CAPACITY自然失败仍主集，matched same-class最大基数与独立DEV/ACCEPT原QC合同保留。

本审没有发现必须临时选择中心/旋转角/擦除端点/随机流/noise顺序才能展开这288个参数的真实未定义项，故没有造一个“不唯一”反例。**完整scene/GT JSON键与错误/环境schema、正式PROFILE、完整J/输出/全机参考映射、真实套件资源/时间/关闭仍是QR-B01…04**，不能把“参数表可展开”标成联合READY。宿主静态hash也不能替运行模块指纹/真实输入核查；这些实际生成/仿真/综合/STA结果只在获批实施后采集，不成为审批前必须运行未批准代码的前置。

| 复核项 | 本轮结论 | 限定证据/未来检查 |
|---|---|---|
| 288身份/96DEV192ACCEPT/原GT counts | 静态一致 | 第2节；实际GT生成后独立再核，不删困难例 |
| 16x/整数Q30-RNE/finiteerase | 静态一致 | 第3节；未执行逐像素raster/GT/T03/T04 |
| Q14/Q23两组同图、Q13重数、Q16/Q22全擦 | 原语义一致且有不可辨识性限制 | 第3/4节；GT保留，不能由性能优化消除语义困难 |
| 额外同RGB关系 R01 | 确定整数证明 | 三ACCEPT全220与DEV全32；联合source审计记录，不据此断全局95% |
| seed/texture/σ0/盐/当前宿主 | 参数与索引唯一、五静态宿主hash相同 | 第1/5节；实际loaded modules/全RGB SHA仍NOT_RUN |
| 95%质量、实现等价、资源/吞吐/STA | 未验证 | 171/179与164/172只是召回门；主precision/功能失败/时间另核 |
| 完整schema/PROFILE/fulljob/service | OPEN | 保原QR-B01…04，不假闭合，不运行新实现 |

本文件是有限独立审阅证据，不是Approval Manifest、正式状态更新或业务设计批准。完成新增审阅文档后实际全文读回/hash交接；原源hash再次核对不变。之后停止其它设计，等待Root在明确隔离/成熟范围内继续。
