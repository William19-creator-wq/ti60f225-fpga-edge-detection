# TRACK4-RECOGNITION-ALGORITHMS-001 v0.1：候选生成、分段、核验与标注

2026-10-04；**LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)编写。本稿为完整十一功能中的识别/标注增补候选；没有业务实现、可执行参考/测试或testbench。确定算法选择不等于已达到95%质量或整机软件完成。

- Goal：确定圆/旋转矩形/缺边候选、稳定支撑、去重与ANN的完整操作次序，推进T4-A6/A5。
- Current state：原RC与NUMERIC已有表示/生命周期，seed、分段、去重、字形路线未定；本稿给出可审查选择。
- Target state：吸收新布局/参数/局部状态与相邻合同，达到指定范围READY后获批编码、运行质量与整机验证。
- Gap：见A2；内部模式/holding细状态、完整资源/服务界与外部合同仍需闭合。
- Assumptions：V4/I3＋SC431HAI；生产1920×1080，N≤2073600；HDMI60Hz与识别fps分开；慢模式显示最近完整结果。
- Open questions：最终支持范围依实际开发比较/独立集结果决定；没有恢复旧尺寸/数量/遮挡硬边界。
- Dependencies：RC/NUMERIC/DATA/DDR/Canny/CONTROL等真实版本，批准、匹配2Gb器件与运行前提。
- Milestones：整体→接口/组合→确定候选算法→读回/交叉审查→补内部执行/预算→指定批准→代码/仿真/综合/PNR/STA/bit。
- Detailed steps / State transitions：E八操作；父四phase不增加、不重开；内部模式切换需pending/borrow真实关闭。
- Artifacts and hashes：本稿输入A1，最终文件hash在评审/审计；没有自嵌自身hash。
- Validation：G十八场景全部NOT_RUN；本轮为设计分析/静态算术/保存读回。
- Failure handling：采样选择、退化拒绝、实际容量失败、MC隔离分别记录，成功不发布部分列表。
- Human approval gates：未批准实现；原FRONTEND与模型获取请求仍PENDING，不重复创建。
- Rollback：只撤回本稿及其索引引用，原资料/冻结父稿/正式状态/DB不改。
- Completion criteria：实际独立质量、协议/数值、真实DDR、资源/STA与整机bit/hex方能证明完整目标；本稿不是完成证据。

## A. 状态与来源

阅读B整体→C职责→D字段/组合→E中文草图→F预算→G/H验证/追踪→I/J门槛/差异。以下是Agent工程提议，用户有效要求仍是[00需求](../experiments/track4_full_sw_20261004/00_scope/requirements-and-decisions.md)。

### A1. 实际输入

| 来源 | SHA256 |
|---|---|
| RC v0.1 | D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5 |
| NUMERIC v0.1 | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A |
| DATA-JOIN v0.1 | B09B9FEAC91698E2DC482F92EEB287DB172C5D1A9229D7C9DA226B630FB69408 |
| Canny v0.4 | 224779F89206F4113CB0764617401E96ED53D7CF34DBD43FBB60A800A54C8729 |
| DDR-SERVICE v0.1 | 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| PLAN_TEMPLATE | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| 本地DSP推断文档 | 0D2E9CA1ACAE7C6A1524B3227F1F7698A2A98B7D90F7A6488105EF4480F7D8F1 |
| 本地DSP功能文档 | 1CFC0EB2AF924BEA28EE548BAB9851119C8297EAC4C70CC807040508217DBA76 |
| 本地DSP时序建议 | 1D15526710006FF0A04B2840B78F6D1E9A65BCDCA286C0CB9CDD081CE579663B |
| EFX_DSP48模型 | 551E13EFAC2D55CD532097BB28BF50063848AF637F62409890962216C1F5A581 |

root实际读三个HTML主体、DSP48前190行及hash；没有宣称完整模型全文或运行。NORMAL19×18、同clock/CE要求及纯乘法推断支持12×17候选；不证明实际32DSP映射或100MHz。256RAM/160DSP/60800XLR来自既有真实place报告。

### A2. 仍影响设计/实施的项目

| 项目 | 分类、影响及下一行动 |
|---|---|
| AG-B01 | DESIGN_BLOCKING：新32池/384段/VC/峰表切换、串行word读写/holding/统计及组合生命周期尚需完整局部执行稿，不能仅凭逻辑字段实施。 |
| AG-B02 | DESIGN_BLOCKING：225仅已列RAM，完整FF/DSP/metadata及最坏采集/显示服务界未定；公开很重的工作上界不等于可接受时限。 |
| AG-B03 | QUALITY_NOT_RUN：候选默认/抽样可能漏检、近重复及三边歧义，95%与最终范围待开发比较和独立验收；不要求批准前先运行代码来取得设计READY。 |
| AG-B04 | 外部设计/执行前提：真实2Gb/PHY可见性、CSI关闭、冷启动/serializer/SDC及原批准/DB问题沿父稿；本稿不假称已消除。 |

旧RN-B01…05中的路线已有下述候选，不将其整体删除或把新候选自动吸收入父稿。可继续本地执行/组合设计；整个软件目标仍ACTIVE。

## B. 整体外部行为

同一锁定job/profile的EDGE/GRAD/POINTS→有限圆种子/全半径峰和密集线峰→支撑分段/细线→圆/矩形候选→最终量化几何核验/精确去重→完整ANN。图外中心和任意旋转进入算法；未被选中/被阈值拒绝的真实目标仍记FN，不改写成输入不合法。

| REQ | 规则 |
|---|---|
| AG-01 | 全部EDGE点仍进入POINTS/scatter；anchor/seed代表选择显式统计，实际表溢出失败不截K。 |
| AG-02 | 圆允许图外中心、同粗格多中心、同心多半径；有限抽样与像素alias可能漏检，公开代价。 |
| AG-03 | DENSE512不以梯度halo删初始票；分offset/run后TLS细化，三/四边都枚举，不固定长短边比。 |
| AG-04 | 最终量化几何决定统一支撑谓词、计数/覆盖/SSE；去重不依已复用segment表。 |
| AG-05 | 同类几何相同并支撑相同才精确去重；第65个distinct keeper失败，不能用bbox重叠删真实同心/重叠目标。 |
| AG-06 | 圆annulus/矩形有限边capsule与C/R序号字形预生成2bit图，越图只裁绘制坐标。 |
| AG-07 | phase/ROM/RAM模式切换前真实关闭旧pending/holding/borrow；取消不清MC义务。 |
| AG-08 | 每类P/R≥95%、IoU≥0.5一对一独立验收保持；采样、失败帧、负例、推断矩形均参与评价。 |

正常例：同心两圆＋旋转矩形→每径向模式独立拟合→完整geometry核验→C00/C01/R02标注。反例：完全同RGB的缺边矩形与U形负例必产生同一像素算法输出，kind1只说明推断；负类U照计FP，不能用flag排除它。容量失败与成功零目标是不同结果。

## C. 职责、连接与推进

POINT64 —AG-IF01→ ANCHOR/SEED/HIST或DENSE-VOTE
→ AG-IF02 SEGMENT/FINE → 几何构造 → AG-IF03 VERIFY/VC
→ AG-IF04 FINAL → AG-IF05 RASTER/ANN。
完整PROFILE —AG-IF06→ 所有步骤；模式关闭/诊断 —AG-IF07→ 父局部控制与未来观察。

ANCHOR负责代表点与seed选择；HIST负责多径向峰与固定五遍圆拟合；LINE负责dense/RMW/NMS；SEGMENT负责稳定coarse成员与三次TLS；VERIFY负责最终几何谓词/去重；RASTER只读冻结FINAL。父DATA/MC/slot保持所有权，局部不得另创physical返回规则。都是自写候选，无既有可复用识别质量证明。

新增缓存以空间换重复扫描，16票并行以RAM/DSP换步骤；不以填满资源作为优化目标。仍需真实DDR等待、全机资源与质量比较。

## D. 字段、交接与组合

继承NUMERIC的低bit先/低byte先、二补码、RNE、运算前扩位/收窄前检查。几何无饱和回绕；rank哈希专门定义mod2^21/mod2^64，这是排序置换，不能移用到几何。CORE接受在正沿valid&&ready；held body/key保持；ROM读沿后稳定、下一沿preedge capture。

### D1. 主要新记录

| 对象 | 低到高完整字段 |
|---|---|
| SEED128 | key53/rank64/valid1/reserved10；key高到低为biased_cx18、biased_cy18、r17，中心bias131072。 |
| RADIUS_PEAK64 | radius17/raw_count21/window_count21/kind2/zero3；kind0RAW/1SMOOTH。 |
| SEGMENT128 | peak_id10/θ9/rho_bin9/seed_offset signed6/coarse_tlo signed18/coarse_thi signed18/n21/occupied12/maxgap_Q4_18/flags7。 |
| FINE256 | nx signed32/ny signed32/rho signed18 Q4/tlo signed18/thi signed18/n21/Sx signed33/Sy signed33/anisotropy16/occupied12/maxgap18/flags5。 |
| VC400 | geometry144/flags4/score16/support21/eligible21/SSE53/coverage64/max_residual16/fit_support21/seed13/fit_quality16/state2/zero9。 |
| CELL32 | count21/submin4/submax4/valid1/zero2。 |
| EXT_CELL64 | count21/old_member_count21/submin4/submax4/valid1/zero13。 |

SEGMENT flags低两bit端点censored、bit2 offset边界、其它0；FINE低2bit=PENDING/VALID/REJECTED，bit2/3端点censored、bit4=0。REJECTED fine数据零，coarse保留。组合384bit在20条20bit×两depth bank中，高16物理padding零。

VC global id0…1023为CIRC、1024…2047为RECT，类别/proposal由id推导；圆geometry低53bit=cx18/cy18/r17，其余91零，矩形八顶点各18；flags取FINAL有效低3bit，其余0。state0未核/1拒绝/2待选择/3已消费，状态变更不改冻结几何或指标。

CIRC的seed_cell13及圆FINAL的source_seed13在algorithm2明确改为诊断seed_id13，0…255/high5零，不再假称图内grid地址；矩形FINAL仍存parent_pair9/high4零，允许0…511，不套用圆ordinal域。位数不改。父J/grant/phase字节不改，本候选须以后显式吸收。

### D2. 接口与模式

SEG_LOOKUP_REQ147=key137/id10；RESP541=原147/outcome2/reason8/coarse128/fine256；COMMIT531=key137/id10/body384；RECT_RECORD659=key137/index10/body512。均一个有限holding；取消按旧ctx独立消费/DISCARD，不能撤回有效body。

AG-IF03核验产生固定VC400；AG-IF04只有全表核验/排序/去重结束才交FINAL512。当前best另400bit holding；读其它VC/FINAL可分时旧512bit组装slot，但P2 FORMAT copy/borrow已关且ANN未启动。AG-IF05只读不可变FINAL、使用row bank，沿父ANN128B头/list/map格式，不写未授权padding。

AG-IF07新增统计是私有按job清零的16个uint64观察寄存器，已列1024FF；逐接受/选择事件扩65bit检查后更新，溢出为内部帧失败。父status终结边界由未来TB同时采样原J与这些寄存器；不冒称原META640B或终态payload已有诊断字段，不新增未定持久化格式/DB写入。

P1：LINE8先anchor、后两个512峰表；FINE40以20word/row，row0…255 seed，256…511每row四个64bit已写CIRC精确key（其余128bit零），512…527各263bit圆LS统计，528…543各≤384bit当前几何/验证context。LS n21/A43/B44/C43/D56/F56合263；context详细word/pending分配仍AG-B01。

P2：32池先dense计票，后两个CELL32或一个EXT_CELL64；LINE8存峰、FINE40存1024段、PAIR4存512边对。P2全部RE/capture/commit/物理借用关闭后，这32+8+40+4=84RAM可排他切P3的VC80RAM（2048×20word），余4可作临时coverage。FINAL4/row2/stream4不参与复用。P3核验、去重、RASTER按顺序互斥；不可边覆盖VC边等旧读。具体模式关闭/FSM须AG-B01补齐。

### D3. PROFILE1024 layout2/algorithm2

NUMERIC D4字段位数/组顺序继承；header layout2/numeric1/algorithm2。structure原zero50=vote_mode2/offset_count6=49/step_Q4_5=8/TLS_refine_passes2=2/projection_subbits3=4/run_gap_Q4_16=48/projection_cells13=4096/zero3。verify原zero50=segment_coverage_min16/eligible_distance_Q4_16/rect_inlier_distance_Q4_16/zero2。末zero64=rect_verify_attempt_cap13=4096/TLS_direction_sin_tol16/endpoint_extension_Q4_8=8/seed_member_policy2=0/two_cell_parallel1=1/zero24。

structure固定θ512/buckets32/batch16/rho277/rho_step16；vote_mode1=DENSE16、halo0、center_pitch0（旧grid未使用）、radius_hist_pitch_Q4=1、tile bins8192/sector64，LINE/SEG/CIRC/RECT1024、PAIR512、FINAL64。mode0旧halo路线仅开发比较，不与mode1隐式等价。

| 默认参数 | 编码；是待比较候选，不是已验证性能 |
|---|---|
| circle support/det/radial/normal | 6 /16 /32Q4 /6554UNORM |
| circle coverage/score/meanSSE | 2047 /32768 /256Q8 |
| line support/anisotropy/normal | 3 /58982 /9121 |
| TLS residual/direction/run coverage | 12Q4 /4571 /32768 |
| endpoint/parallel/orthogonal | 32Q4 /2288 /3431 |
| rect eligible/inlier/visible coverage | 64Q4 /24Q4 /49151 |
| rect score/meanSSE | 49151 /256Q8 |
| missing/required sides | 1 /3；kind0仍核四观察边，kind1核三观察边 |
| dedup | mode1；三个几何tol0，support_overlap_min65535 |
| raster | stroke32Q4/label_mode1/scale1/offset0,0/map_merge0/priority0 |
| color | mode0/tol0；没有虚构额外颜色核验 |

algorithm2编译固定：8×6×8×2 anchors、256 rank seeds、pair角门1024/半径差128Q4、拟合宽门64Q4/hist normal13107、RAW/SMOOTH各512/平滑±8bin。这些常量与版本一起冻结；改变需改版本/评审，不偷偷读可变全局值。全部未安装；layout1不能按layout2解析，C570/ref/body仍按旧job完整锁定。

比例阈值统一全宽交叉乘（65535·支持≥门·eligible等），RNE score仅排序/显示。去重门尤其不能以舍入UNORM达到65535代替精确集合相等：union2073600/both2073599会舍入65535，实际集合不同。此处明确覆盖NUMERIC E7未定路线的门政策。

## E. 八项中文操作草图与不变量

AG-INV01锁旧job/profile/phase；AG-INV02每候选每遍每点至多一次、计数≤E；AG-INV03采样与真实容量失败分开；AG-INV04完整记录后valid/body保持；AG-INV05所有RE预约/capture/borrow真实关闭才改模式；AG-INV06最终geometry/谓词/指标一致；AG-INV07同类精确去重、不同类不删；AG-INV08 ANN成功仅完整写/fence/返还，停止新业务不清旧MC。

### AG-OP01：anchor与seed

POINT进入8×6空间格（floor(8x/W)、floor(6y/H)）及θ>>6角组，每桶选两条最小rank。i=yW+x；依次xor右移11、乘109加37取低21、xor右移7，得到可逆21bit优先级。完整读/capture旧两POINT后由FF形成一次或两次WE，两个分支anchor/scatter独立done，皆完成才推进point。

按桶/slot向前压紧≤768 anchors，全枚举a<b≤294528。两anchor的Q4位置P1/P2和整数梯度G1/G2，D=cross(G1,G2)、T=cross(P2−P1,G2)；D≠0且cross²·65535²≥1024²·|G1|²·|G2|²才过角下界。中心每坐标分别RNE((P1·D＋G1·T)/D)，先规范分母为正、全宽算完再核signed18域；不是先量化t。对该量化中心两Q4距离分别exact RNE_sqrt得d1/d2，再取r=RNE((d1+d2)/2)；|d1−d2|≤128且r在1…131071才生成key，距离及均值先全宽，最后才收17bit。退化/超域局部拒绝。rank64依次xor右移23、乘4296015875取低64、xor右移29、乘140737488355333取低64、xor右移31。奇乘与右xor都是置换，不凭hash相等猜geometry相等。

遍历全部pair，保存最小rank的256 distinct key，相同key合并，满时比较并替换最大rank；最终按rank升序赋seed_id。公开anchor_pruned=E−anchor_count、合法pair occurrences、rank拒绝/替换/selected等uint64统计。选择事件次数不是distinct几何数或漏圆数。此处显式规定算法采样；旧INV08对CIRC/RECT/峰表/FINAL存储满失败继续有效，不得把这些满表改叫采样来规避。

### AG-OP02：多半径与固定圆拟合

相同精确seed中心可共享全半径扫描，不按pair半径截域。先POINTS遍历得到16个非空tile；每点径向距离先全宽exact RNE_sqrt，d=0或d>131071均不置bitmap、不投票，分别记zero/out_of_radius_domain，禁止收17bit后回绕。其余tile=floor(d/8192)、bin=d mod8192；编译记录域只限制该假设可表达半径，不将对应输入帧排除质量。每tile覆盖8192个1/16px bin，最大16遍。17条native20条带合340bit，按row存16个count21，余4零；同row更新串行RE/capture/WE，每点只给其唯一RNE半径bin投一次。

RAW与±8bin box窗口SMOOTH各保留完整正峰列表（window支持≥3），正平台最低半径；每路512，第513失败。跨tile保留末18raw和下一首9，旧末9有右halo才判峰；空tile是真零。两路独立最近峰归属，tie较小半径，不能互相抢支撑。

每组≤16峰固定五遍：宽门LS得c1→按固定成员求c1平均距离得r1→c1/r1收LS得c2→按第3遍固定资格求c2平均距离得r2→完整扫描核c2/r2。NUMERIC Δ/条件/RNE/范围继续适用。最后扫描eligible为4px环带所有EDGE，support逐点另满足2px残差/法向；完整support后形成64sector mask，再判整体coverage门，sector不能反向决定某点是否support。混合极性不自动删圆。完整CIRC形成后精确key比较，重复不二写；第1025条失败；本phase不读新CIRC。

### AG-OP03：DENSE16与NMS

32 batch各完整读32 SORTED桶，不把padding当point。缓存16组signed17 C/S；三段product29→sum30→RNE/r9保留旧POINT与valid。已登记16bin才e0同步RE低20/high1，e1 capture/扩22加1检查，e2写；e3最早下一组RE，e2无同址RE。每(point,θ)一票，高word余19零。

θ/ρ radius1 NMS，theta越0/511对整个rho邻居坐标镜像276−r；padding235不参与。大票优先，平票按规范化(θ,r)小者；不宣称消除所有连通平台。四独立row保存first0/1与rolling last2，每row277 lowword＋14 packed highword=291word。末θ511/延迟θ0及所有pending处理完才复用；LINE峰≤1024，否则失败。

### AG-OP04：offset、run与TLS

每峰ρ恢复absolute Q4：
R0=RNE((128q·32768＋8[C(W−1)+S(H−1)])/32768)，q=r−138。
49个半像素offsetδ=-24…24；点按精确归一化有符号距离归最近offset，RNE tie偶；8°梯度门。1D radius1筛峰（相等低δ），全部≤25种子，筛弱峰造成漏检照FN。

32池改两个4096 CELL32组，每峰最多13遍两种子处理；cell=floor(tQ4/16)+2048。图内合法投影越4096为内部错误；submin/max保留原Q4端点。按cell升序，下一min−旧max>48Q4断run，保留真实occupied/maxgap，不取全线global min/max。

coarse成员由旧peak/offset/gradient/闭区间唯一确定。TLS0要求n≥3、occupied≥2、run覆盖门、anisotropy门及4°方向门。两次extension用旧细线0.75px/8°门扫描，单4096 EXT_CELL64保存新count/旧成员count；合格run须含旧成员且距旧投影均值≤2px，按shared降/total降/tlo升选。固定TLS1/TLS2，不迭代到收敛；最后重放TLS1/run成员，将端点投影到TLS2，完整提交FINE。每段至多六遍POINTS，REJECTED数据零，不让未完成fine参与pair。

tQ4沿NUMERIC的centered tangent；恢复absolute端点时解两个量化向量的完整交点方程，不假设Q30范数精确2^30。相关内部数据读/commit/旧成员谓词快照仍需AG-B01细化。

### AG-OP05：三/四边构造

有效segment对≤523776，经2°平行门形成PAIR≤512（第513失败）。四边枚举不同parallel pair对≤130816，要求四个segment互不相同、两组原细线方向先过3°正交门；三边枚举pair×第三边≤524288，第三段与pair两段不同且其原方向先过同一正交门。观察侧相邻细线交点的投影须落入各自原fine支撑闭区间[tlo−32,thi＋32]；不由后续强制共同轴替代此检查。无长短边/比例硬门。

最强可见边方向（支持相等低id）定共同轴，另一轴旋转90°；用n/Sx/Sy重算截距、求角。无限精度是正交矩形，各角RNE Q4后是量化矩形，不保证精确正交；再核非零边/面积/不自交/CCW，保存量化顶点。三边另一端须两个远端uncensored、对齐≤2px，外延0.5px后平均得推断边；不把图像裁切端当真实物体终点。第4097次完整核验尝试、第1025 RECT均失败，不提前截成功。

### AG-OP06：冻结geometry的统一核验

矩形每有限边A/B Q4、点16P；p=16P−A、d=B−A均signed19，K=d·d uint39、z=p·d/c=p×d signed39。K0非法；z≤0距离分数=|p|²/1，z≥K用到B距离²/1，内部c²/K。N最多78bit、D39；最近侧用NiDj/NjDi≤117bit比较，tie小边号。法向门用(G·d)²·65535²≤tol²·|G|²·K，不冒用Q30 K≥2^58守卫。

用4N与(2k+1)²D单调边界求RNE距离；先全宽核门，inlier才收uint16。eligible4px/support1.5px与8°，同点最多一侧；coverage是1px投影占用区间与可见边区间的交集长度比例，不是点数。kind/present只决定整体required-side接受门；四条最终量化边均参与唯一最近侧、eligible/support谓词，推断侧同样统计真实support，不能让同geometry因present不同有不同支撑集合。四边required为四观察侧，三边required为三观察侧；无图内可见长度的required侧按未满足拒绝，不伪造coverage。完整visible clipping/区间并集算法仍需局部执行稿，不把bitmap容量当长度正确证明。

圆使用最终cx/cy/r，不再受原seed最近峰分区限制；完整POINT谓词同OP02最终核验。写VC前必须重算最终量化geometry的eligible/support/SSE/coverage/score；排序、去重后不再改它。algorithm2的fit_support/fit_quality定义为最终冻结geometry核验统计，明确覆盖NUMERIC旧“原拟合统计”语义；不是从已复用的FINE/PAIR或未保存的旧拟合数读取：同一次最终POINT核验按冻结geometry的inlier重新累计圆263bit LS或四侧217bit TLS统计，仅导出诊断，不回写中心/顶点。圆fit_support=n、fit_quality=RNE(65535·4Δ/(A+C)²)；矩形fit_support为required且图内可见侧Σn_i，fit_quality为这些侧TLS各向异性最小值，沿NUMERIC E4/E5全宽/RNE公式。每个inlier的G非零；零trace/退化required统计局部拒绝；不生成伪0合法quality。四侧统一分配使Σn_i≤E；stats在原NUM工作容器分时计算，完整holding/收窄检查与FF复用仍需AG-B01/02。完全没有图内可见边/有效eligible不能造合法score。

### AG-OP07：全表排序与精确去重

先核完Q≤2048候选，按class升/score降/均方SSE精确升/proposal升选择，拒绝/已消费state跳过。best400单独保持，读旁项不覆盖它。比较同类已留keeper的量化geometry（矩形规范对应），默认tol0；不按bbox重叠删对象。

命中相同geometry后同遍POINT重算两个冻结谓词的I/U；门用65535I≥threshold·U。默认threshold65535时只有I=U可合并，union0非法。不同半径同心、不同几何/支撑、异类保留。近拟合重复仍可能FP，初始精确路线须质量比较，不声称95已证。第65 distinct keeper失败、整ANN不发布前缀。

默认exact下每候选最多64个几何比较、至多一个相同geometry keeper作全支撑遍；不是64QE。最终核验＋dedup局部最多2QE，另计其它pass与排序读。排序全部结束后冻结FINAL，才能开RASTER。

### AG-OP08：ANN栅格、字形与关闭

像素中心用Q4 (16x,16y)。圆画annulus：D=dx²+dy²，Rlo=max(0,2r−s)、Rhi=2r+s，命中Rlo²≤4D≤Rhi²；s为full stroke_Q4。矩形圆头capsule用OP06距离分数，4N≤s²D；四边union，端点/角圆头由距离定义，不用细线无限延长。

计算drawbbox包含stroke及label；圆Q5外界C5±Rhi先signed21（极值524539超signed20）。按像素中心向外取整/clip绘制范围，geometry不clip；raw drawbbox/label元数据64×80可在VC结束后复用其1RAM，不能在VC仍被读取时占用。绘图元数据80bit低到高为draw_bbox44（四uint11半开坐标）、label_x/y各uint11合22、charlen3、clip1、zero10；20bit×4word，64条共256word。圆外界min=ceil(extent_min_Q5/32)、max=floor(extent_max_Q5/32)+1，采用数学floor/ceil后裁至图内，再与标签范围并集。矩形有限capsule先以端点min/max向外扩半笔宽得到保守私有drawbbox，再逐像素按OP06精确谓词；私有bbox可多扫描，不漏命中。逐word串行模式/capture/pending及完整row执行仍AG-B01。

label Ckk/Rkk，kind1为Rkk?，kk=FINAL slot00…63。14字形C/R/0…9/?/space，7×5、bit4左/row0上，scale1默认；透明背景、字符advance6s、宽(6L−1)s/高7s。优先geometry bbox顶左＋offset，y在bbox上方height+1；能容纳时clamp至W−width/H−height，小图从0逐像素clip。字形如下：
C:01110/10001/10000/10000/10000/10001/01110；
R:11110/10001/10001/11110/10100/10010/10001；
0:01110/10001/10011/10101/11001/10001/01110；
1:00100/01100/00100/00100/00100/00100/01110；
2:01110/10001/00001/00010/00100/01000/11111；
3:11110/00001/00001/01110/00001/00001/11110；
4:00010/00110/01010/10010/11111/00010/00010；
5:11111/10000/10000/11110/00001/00001/11110；
6:01110/10000/10000/11110/10001/10001/01110；
7:11111/00001/00010/00100/01000/01000/01000；
8:01110/10001/10001/01110/10001/10001/01110；
9:01110/10001/10001/01111/00001/00001/01110；
?:01110/10001/00001/00010/00100/00000/00100；
space:00000/00000/00000/00000/00000/00000/00000。

glyph id0=C,1=R,2…11=0…9,12=?,13=space。每行一20word低5有效，其余15零；projection ROM word0…257保留，字体放258…355，356…511零。P3 ANN前projection旧RE/pending关闭；正常RASTER不再用Q15投影，才共享这同一ROM。明确覆盖NUMERIC“其它word零”，不是隐藏新增RAM。

row清零→画object/label→送出互斥；01圆/10矩形/11文字或异类叠加，00透明/11保持，交换顺序无关。同字形碰撞不保证可读，完整类别/坐标仍有FINAL。父row latest/pending/跨行carry/物理W保持及失败关闭沿旧合同；全N图/list/header/末padding和fence完成才发布。

## F. 数值、语言与资源预算

无C++实现；未来Python3.14标准库逐位参考与解析GT评分分开。RTL SV2009、core100MHz候选，物理clock/STA未证。A数值见D/E；B观察preedge；C fire才接纳；D气泡不推进；E held/bank不变；F投票三沿只是已就绪组；G取消保留父承诺；H旧C570完整锁定；I模式容量/串行RMW；J原幅坐标和规范geometry；K不新增CDC且不据同域证明外部；L预算不代替推断/PNR。

225/256 RAM=87.890625%：180＋26（FINE14→40）＋4NMS＋15计票17→32。圆hist/anchor/seed/VC80/font均按D/E互斥复用，无新外部地址/grant；未指定结构不得偷藏在剩31RAM。局部列明NUM FF6191、DENSE FF3304、圆FF4883、VC best400小计14778，未含全机/新FSM/metadata/row所有FF。

DENSE额外FF：coeff544、products928、sums480、bins144、三POINT192、RMW capture336/address144/writehold336、valid48/control152。它是容器预算，后续实际结构可减少但须同步草图。32个12×17纯乘候选DSP48，scalar乘/其它全机DSP另计；当前不是真实33/160利用率。

最坏E=N：dense32E=66355200组，RMW199065600个core沿机会（不含其它等待）；圆每中心≤337遍、256中心≤86272遍POINTS，约1.431TB；phase2≤32E+14LE+6SE+VE、L/S1024/V4096给51027148800点检查（约408.2GB）；P3最终核验/去重局部2QE≤8493465600点、67947724800B。重复桶padding/峰搜索/统计scalar/coverage其它pass另计，不能把此数当整机完整上界或实时性能。

收益是减少重复pair拟合和角票串行等待；反例是dense背景及大量radius峰仍代价巨大。真实QoS与可接受模式延迟仍AG-B02，HDMI重复完整图不能被拿来宣称识别fps达标。

## G. 实施/文字验证计划

先补当前设计阻塞并指定批准，之后才按point/seed→hist/fit→dense/segments→verify/VC→raster→父整机次序生成代码/参考/TB。计划职责recognition_anchor/seed/hist/segment/refine/verify/raster全部未生成。

| TEST | 场景与期望；均NOT_RUN |
|---|---|
| AG-T01 | 零G/错key/保留位/不同profile拒绝，旧C快照不混。 |
| AG-T02 | 每anchor桶0/1/2/3点、同rank不可能、scatter stall不重复；E−anchors统计正确。 |
| AG-T03 | 全pair超过256 seed、替换/拒绝/同key；继续全遍，选择事件非distinct漏圆数。 |
| AG-T04 | 图外中心/同格多个/同心/条件差/超记录域；拒绝与FN不混，geometry不clip。 |
| AG-T05 | RAW分峰/SMOOTH合峰、tile边/空tile/plateau，513峰明确失败。 |
| AG-T06 | 五遍LS半径成员快照、c1/c2变化及16组；不用旧中心均值冒充新半径。 |
| AG-T07 | 连续同ρ、16不同ρ、读/写/模式切换；e2无RE，旧capture不丢。 |
| AG-T08 | θ0/511＋277镜像、四NMS行延迟、平票及padding，不清旧峰表。 |
| AG-T09 | 49offset/相邻弱峰、两个cell组、t负floor、真实gap/run端点，不拼global。 |
| AG-T10 | TLS0/1/2、重复旧成员/分支run/censored/anisotropy、完整384快照。 |
| AG-T11 | 三边/缺长或短边/图外远端/旋转量化矩形；同像素U负例仍计FP。 |
| AG-T12 | 最终顶点改membership、capsule端点/角点唯一侧、coverage区间不冒点数。 |
| AG-T13 | overlap舍入65535但I<U；exact不合并，同心/重叠保留，近重复照FP。 |
| AG-T14 | 第65 keeper/1025记录/513pair/4097核验及MC失败，完整失败不发布前缀。 |
| AG-T15 | 字形98word/ROM旧pending、s21圆外界、stroke/标签clip/冲突/N30跨行carry。 |
| AG-T16 | 84pool→VC→draw模式、旧borrow/holding/cancel，真实排空不清账。 |
| AG-T17 | 独立GT一对一/空分母/失败帧/重复/错类/推断，P/R整数门。 |
| AG-T18 | 完整1080p、实际DDR、总RAM/FF/DSP/计算fps与HDMI、综合PNR/STA；预算不当通过。 |

质量评分：同类半开bbox，合法IoU边以2·intersection≥union，不以浮点近似跨门。用最大基数二分图匹配，增广按固定GT/pred索引及IoU降序遍历，确定性tie；不使用会少匹配的greedy。每类TP/FP/FN，门20TP≥19(TP+FP)且20TP≥19(TP+FN)。分母0标N/A，不能报100%；独立主集两类都须有GT，负样本FP计入。失败帧不取非法前缀，GT均记FN，并单列失败率/功能失败；不能丢失败帧使指标变好。

开发轴扩大包含8…2048px圆、8…1024短边、ratio1…16、目标0…65、遮挡0…50%、对比16…192、纹理0…32、σ0…16、椒盐0…2%、任意旋转/裁边/重叠/负样本。这些是比较点，不是承诺范围/硬上限；不恢复旧参数。DEV seed0x4445565F5434、QUAL seed0x5155414C5434是提案，未生成数据。最终分布/GT/种子在开发结束、查看独立输出前冻结hash；最终范围依真实结果评审，不按失败样例临时改标签/排除。

## H. 双向追踪

| 要求 | MOD/IF/OP | 拟职责 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| AG-01/02 | ANCHOR/HIST；IF01；OP01/02 | seed/circle | T02…06 | 未实现/NOT_RUN |
| AG-03 | LINE/SEG；IF02；OP03…05 | line/segment/refine | T07…11 | 未实现/NOT_RUN |
| AG-04 | VERIFY；IF03；OP06 | final_membership | T10/12 | 未实现/NOT_RUN |
| AG-05 | VC；IF04；OP07 | dedup/select | T13/14/17 | 未实现/NOT_RUN |
| AG-06 | RASTER；IF05；OP08 | raster/font | T15 | 未实现/NOT_RUN |
| AG-07 | 父/全部；IF07；OP01…08 | pool/lifecycle | T01/07/16 | 未实现/NOT_RUN |
| AG-08 | VERIFY/观察；IF06；G | quality/metrics | T04/11/17/18 | 未实现/NOT_RUN |

## I. 门槛与批准

§10.3①整体/反例、②职责/来源、③表示/主要交接、④候选中文步骤、⑤语言/数值、⑥走查、⑦计划追踪有实质候选；③④仍需AG-B01的完整执行/内部交接，⑧无阻塞不满足；⑨保存读回由评审给证据，⑩版本/输入可定位。未标READY，未批准任何业务实现/ROM生成/功能脚本。允许下一步是独立读审和补局部执行、真实服务界，不重复询问已PENDING批准。

## J. 相对旧稿及恢复

只在本候选中明确覆盖：旧圆格DDA→anchors/rank seed；旧halo→DENSE16；17池→32、段128→384、NMS4；PROFILE layout2；圆seed13诊断语义（矩形pair9保留）；最终量化几何统一membership与fit诊断新语义；比例全宽门；VC池复用；projection ROM spare字体98word。旧RC/NUMERIC/DATA/CONTROL/CJ字节保持，本稿不自动升级它们。

后续若改变采样/rank/阈值/记录/池/phase/配置/几何及成员谓词，修订本稿D/E/G/H与父端口基线并重新评审；不能称为不影响行为的内部优化。恢复先核所有输入hash、当前批准范围、池生存期及资料前提。

## K. 实录

只读真实文件、本地DSP来源、静态算术、作者提案与root集成；实际保存/全文读回/独立审查另报告。业务代码、功能性脚本、常数表、测试/TB未生成；仿真/真实PHY/综合/引脚/PNR/STA/bit/hex未运行。原资料/正式状态/Manifest/数据库未改。无网络/下载/安装/设备动作。

## L. 阅读与交付

先B/C整体，再D完整对象与互斥池，按OP01…08追一帧到ANN；查看F的大代价和G质量反例，最后I/J确认不是实现批准。反向由FINAL或label查冻结geometry/VC/membership，再查seed/run与原POINT/J/profile。目标仍是完整十一功能可运行/仿真/综合/布局/合理约束和bit/hex；本轮只是推进设计，未完成软件。理解验收无用户作答，为待检验。
