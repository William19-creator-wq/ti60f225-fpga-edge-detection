# TRACK4-RECOGNITION-NUMERIC-001 v0.1：识别数值与记录候选

2026-10-04。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)编写。本稿仅集中闭合指定数值与记录提议，不替代[RECOGNITION v0.1](design-TRACK4-RECOGNITION-001.md)的完整算法、质量与生命周期目标。业务源码、实验程序、功能脚本、可执行测试、testbench均未生成、未运行。

- Goal：为POINT、θ/ρ、CIRC/RECT/FINAL/PROFILE、LS/TLS与共享宽算术提供可读回的表示、舍入、检查和中文操作草图。
- Current state：旧RC已列GRAD32、四phase、候选容量和58RAM，精确θ/ρ、字段及拟合规则仍未冻结。
- Target state：指定数值选择经相邻稿吸收与评审，剩余算法决定明确可定位，之后才可能进入指定版本审批。
- Gap：RN-B01…06；没有以本稿消除完整RC质量/候选覆盖/分段/去重/字形缺口。
- Assumptions：core100MHz候选；W偶数6…1920、H5…1080，实例静态，生产1920×1080；N≤2073600。
- Open questions：见A2与E7；未决正确性条件仍BLOCKING，不伪装成普通测试待办。
- Dependencies：现行v0.2、RC/CONTROL/CONTROL-JOIN/DATA-JOIN及真实RAM10同步读事实。
- Milestones：整体与表示→交接→数值草图→保存读回→独立审查→相关算法/外部缺口闭合→指定审批；当前只到文档阶段。
- Detailed steps / State transitions：见E；数值单元IDLE→EXECUTE→RESULT_HELD→IDLE，未知输入及旧承诺按父合同处理。
- Artifacts and hashes：仅本新文件；输入哈希见A1，文件最终哈希由读回报告提供，不自嵌入哈希。
- Validation：RN-T01…16全NOT_RUN；本轮仅文档与手工设计算术审查。
- Failure handling：数值退化候选拒绝、输入/累加器/容量错误帧失败、未知排空Q分开；旧DDR义务仍由DATA/DS结清。
- Human approval gates：本稿不READY，未批准；设计文档写入授权不等于业务实现授权。
- Rollback：仅撤销本新设计文件的候选引用；旧稿字节保持，不执行清理或恢复命令。
- Completion criteria：本轮产物为实际保存读回的候选；完整RC目标、实现、综合和95%质量均未完成。

## A. 状态、基线与阅读入口

任务ID TRACK4-RECOGNITION-NUMERIC-001；关联MOD-09/RC-01…08及DATA-JOIN DJ-J03/J04/J07。读取顺序B整体→C职责→D表示/交接→E人工数值步骤→F A–L→G文字场景→H追踪→I/J门槛与差异。

### A1. 实际输入

| 输入 | SHA256 |
|---|---|
| 根规则v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| PLAN_TEMPLATE | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| RECOGNITION v0.1 | D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5 |
| CONTROL v0.1 | A0CE9329AA2D0F8914150A9DE350F473011F506744F79E1ADAE8207E796B50A6 |
| CONTROL-JOIN v0.1 | B8DAED20BEA99636E7667CC7E69AA62317D84D5103DCC59A476821B31EFEFF58 |
| DATA-JOIN v0.1 | B09B9FEAC91698E2DC482F92EEB287DB172C5D1A9229D7C9DA226B630FB69408 |

事实：GRAD32含signed11 Gx/Gy与dir2，高8零；C570关联不可变profile_ref64；旧RC采用π周期512θ、32散桶/16θ batch、原分辨率核验及候选1024/1024、最终64容量候选。以下字段、277ρ中心、整数舍入和共享算术都是新设计提议。

### A2. 剩余正确性阻塞

| B | 影响与需要的决定/证据 |
|---|---|
| RN-B01 | 图外圆心、同粗格多圆、多半径种子的完整候选覆盖仍RC-B01；18/17几何容器不证明覆盖用户未限定的所有几何域。需完整种子/半径路线与适用域证据，不恢复旧尺寸/数量/遮挡硬限制。 |
| RN-B02 | 支撑筛选、投影排序/分段、TLS精化次数、三边/缺整短边与U形反例的判定仍RC-B02/03；本稿定义运算，不凭数值式证明识别。 |
| RN-B03 | PROFILE阈值实值、默认、半径hist组织、稳健拟合与颜色核验路线未选；schema可审，不能安装一份含未知值的生产profile。 |
| RN-B04 | 重复去除所需的支撑重叠集合/排序、不同真实同心/相邻目标可辨识政策、数值域外候选的完整质量统计未闭合；不能截断/饱和后报完整成功。 |
| RN-B05 | 标注交点栅格化、笔宽与字形/标签完整规则及额外ROM未闭合；本稿保留精确Q4几何，不声称2bit图绘制已闭合。 |
| RN-B06 | 全机FF/DSP/真实QoS/STA及外部2Gb器件/PHY/恢复证据仍依原稿；ROM常数尚未获准生成，未做完整单调性/逐位实测。获批后仿真/综合是验证义务，不以尚未跑实现代替上述设计缺口。 |

## B. 整体外部行为

边界为MOD-09中数值与记录层。输入来自同一已锁PROCESS/C570的EDGE、GRAD、点/支撑集合及已安装完整PROFILE；输出是确定字节记录、拟合值或有分类的拒绝/失败。它不分配scope/grant，不改变FM源/结果BIND，不改MC数据/终态端口，不改四phase所有权。

| REQ | 规则/来源 |
|---|---|
| RN-01 | RC D2/OP02：EDGE1必须合法非零G；POINT64逐点无有损字段转换。 |
| RN-02 | RC OP05派生：θ量化/ρ翻号有确定整数/tie语义；跨π比较不靠额外±1暗补。 |
| RN-03 | RC IF04…06：完整CIRC/RECT/FINAL布局和零padding；几何范围/容量错误不静默clip。 |
| RN-04 | CONTROL CFG212/C570：profile_ref只命中已保存完整不可变实体；本job沿用旧快照。 |
| RN-05 | RC OP04/05/F：LS/TLS扩位、舍入、退化和溢出可检查，最终直线角不锁512θ中心。 |
| RN-06 | 派生：共享算术/RAM读采用有限holding与preedge capture，不阻DDR后台义务。 |
| RN-07 | RC G：每类P/R≥95%、同类IoU≥0.5一对一独立集目标继续有效；数值结果相等与识别质量分开。 |

初始化只有经父安全就绪后才能接纳job；数值私有valid初始0。PROFILE完整核验后锁在数值ctx，直到旧数值holding关闭。同沿更新C与预留job用旧C，held job不变。停止/取消禁止新业务数值请求，已RAM pending照capture并DISCARD；已MC承诺依DATA/DS继续，不能清数值计数冒充排空。

正常样例：G=(1,1)合法EDGE点→θ128→POINT不丢G→目标θ投影按RNE落277ρ中心→原分辨率支撑得到非退化TLS→Q4顶点写RECT→phase3核验后写FINAL。边界样例：ρ=0始终r138，翻号仍138；RNE(±0.5)=0，RNE(±1.5)=±2，因此正负tie严格镜像。错误样例：EDGE1/G=(0,0)帧失败，不以θ0继续；圆全部法线平行Δ0为该拟合候选退化，不伪造圆心。

容量1024/1024/64仍内部资源配置，溢出为完整任务失败，不能只保留前K条成功。几何数值域外的未核验候选应显式记GEOM_RANGE拒绝及统计；它是否导致整帧不可验收须RN-B01/04闭合，不据此宣称所有用户目标受支持。

## C. 职责与连接

路径：GRAD/EDGE —RN-IF01→ POINT与θ —RN-IF02→ ρ/票表；支撑点 —RN-IF03→ LS/TLS —RN-IF04→ CIRC/RECT；原分辨率核验 —RN-IF05→ FINAL —RN-IF06→ ANN。C570/profile_ref —RN-IF07→ 完整PROFILE快照；错误 —RN-IF08→ RC父终态原始诊断。

| MOD | 职责与状态拥有者 |
|---|---|
| RN-FORMAT | 检查/组装D2…D4记录；持一个512bit输出组装槽，不承担质量筛选。 |
| RN-ANGLE | 折叠梯度、同步读取只读常数、最多8次二分；拥有当前向量和ROM pending，不持DDR锁。 |
| RN-PROJECT | 恢复signed17系数、目标θ投影、RNEρ及镜像；不把coarseθ当最终TLS角。 |
| RN-FIT | 保留当前圆或当前四边217bit统计，发共享算术；支撑集合由RC算法选择，选择尚B。 |
| RN-SCALAR | 一个有限请求/结果slot，宽乘加/除/根；不会等待新点才交已承诺MC W。 |
| RN-PROFILE | 核完整1024bit实体与ref/版本，锁值；注册表生命周期沿CONTROL/CJ，不另建所有权规则。 |

全部自写候选；已有资料仅证RAM10 native20×512与同步读，未发现可直接复用且满足质量的识别核。CIRC/RECT来源ID是诊断编号，不在后phase解引用已复用片上段表。整体选择已呈现为此B/C；下文进入指定表示，不将完整算法阻塞藏入字段名。

## D. 表示、接口与相容检查

### D1. 共同数值规则

记录表按**从低bit到高bit**列，低byte位于低地址，byte内低bit在先；unused/保留全0。signed采用二补码。坐标单位原图像素中心：像素(x,y)的绝对中心就是整数x/y；Q4整数v表示v/16像素。bbox为裁到图内的半开xmin/ymin/xmax/ymax；它仅用于绘图/读取，不回写裁剪拟合几何。

RNE(num/den)：den必须正。先对num取扩位绝对值，求非负商q和余数r；2r<den取q，>取q+1，=取偶数者，再恢复符号。无负右移/截断代替RNE。RNE_sqrt(D)先非负floor根k，再比較D−k²与(k+1)²−D；取距离较近整数，等距取偶；D<0错误。运算前扩位，结果收窄前检查，无数值饱和/回绕。

UNORM16(v)=RNE(65535×v)，编码0…65535对应比例0…1；不把65535误作2^16单位。score=RNE(65535×support/eligible)，eligible0不得生成合法score；support≤eligible。均方残差门槛以SSE≤mean_limit×support直接交叉乘比较，不先舍入均值再判门槛。

normal_sin/parallel门解释为|cross(a,b)|²×65535²≤tol²×|a|²×|b|²；orthogonal_cos门用dot²代替cross²，任一零向量拒绝该支撑/拟合。比较保留平方与交叉乘全宽，不假定Q30量化法线恰好单位长；NORMAL/side具体支撑集合仍E7/B。圆coverage是popcount(sector_mask)/64，矩形coverage是明确区间并集长度/可见边长度，后者分段/可见长度路线仍B，不以点数替代。

### D2. POINT/CIRC/RECT

| 记录 | 从低bit到高bit的全部字段 |
|---|---|
| POINT64 | x11/y11/Gx signed11/Gy signed11/dir2/θ9/reserved9；即旧bit[10:0]/[21:11]/[32:22]/[43:33]/[45:44]/[54:46]/[63:55]。 |
| CIRC256=32B | seed_cell13/flags4/cx signed18 Q4/cy signed18 Q4/radius uint17 Q4/support21/eligible21/sector_mask64/radial_inlier_SSE53/score16/reserved11。 |
| RECT512=64B | hypothesis_kind2/flags4/parent_pair9/四segment_id10/present_mask4/八vertex signed18 Q4/四support21/四eligible21/score16/inlier_SSE53/四max_inlier_residual uint16 Q4/reserved8。 |

CIRC/RECT逻辑ID由记录顺序0…count−1隐含；不重复占bit。CIRC seed为粗中心cell0…8159（主图），无效cell不得生成记录。CIRC flags bit0圆心图外、bit1轮廓bbox跨图边、bit2支撑梯度相对径向两种极性均出现，bit3=0；不因极性混合自动拒绝真实圆。sector_mask由径向非零向量的完整2π1024bin量化后取bin/16（0…63）唯一置位；此统计使用明确量化角，不冒称实数角覆盖。

径向向量是dxQ4=16x−cxQ4、dyQ4=16y−cyQ4，先signed19求差并查实际域，abs收unsigned18；它不是[-1020,1020]梯度域。保存原dy<0或dy=0且dx<0的半平面位，再整体规范到y≥0。复用β边界ROM时m/M为uint18、乘积uint48、cross signed49；不能用梯度的uint10/40/41声明此路线。按E2折叠/恢复未wrap的θu unsigned10∈[0,512]，保留512这一进位；fullbin=(θu+512×half_plane) mod1024。加法先unsigned11以容1024，再取合法mod1024的unsigned10结果；不能先把θu的512压成POINT θ0。径向零向量排除角/法向支撑，不分配sector。

RECT kind0四边/present1111；kind1三边/popcount3，缺一边的segment_id为0，几何仍含四顶点；kind2/3非法。顶点按逆时针，起点为(yQ4,xQ4)词典序最小者；反向/循环等价先规范化。flags bit0至少一顶点图外，bit1存在推断边且等于kind1，bit2/3=0。四support/eligible对应四条几何边，推断边也可在最终核验中找到支持，不要求其完全无点。角点附近点仅分配给距离最小的一边，等距取小边号；同一遍每点至多一次，Σeligible≤E≤N、support_i≤eligible_i。具体距离门与可见支撑范围仍RN-B02/03。

SSE仅累加所选inlier的整数Q4残差平方；profile残差门限uint16，单项≤65535²，总数≤N，所以53bit足够。4边SSE是唯一分配inlier的总和；support_i0时max_residual_i0。统计溢出违反域/唯一性，帧失败。signed18中心/顶点域[-8192,8191.9375]px，radius uint17正值域[1/16,8191.9375]px；这是格式域，**不是已批准的目标尺寸或图外域限制**，超域不截断。完整覆盖仍RN-B01。

### D3. FINAL512=64B

每条三段，合512bit；四RAM的640bit容器仍26个有效20bit word（末word高8零）及6个零word，不改变旧4RAM布局。

| 段 | 从低到高字段/单位 |
|---|---|
| common96 | class2（1圆/2矩形，0/3非法）/flags6/proposal_id10/score16/support21/eligible21/reserved20。 |
| geometry192 | bbox四uint11共44bit/geometry_union148。圆union=cx18/cy18/r17/zero95；矩形union=八vertex18/zero4。 |
| metrics224 | coverage64/inlier_SSE53/max_inlier_residual_Q4_16/fit_support21/source_seed13/fit_quality16/zero41。 |

FINAL flags bit0几何跨图边、bit1三边矩形推断（圆为0）、bit2圆支撑混合极性（矩形为0），bit3…5=0。proposal_id选对应CIRC或RECT表0…1023；full job/profile身份在父ctx/ANN头，不在每条重复。coverage圆为sector_mask64，矩形为四侧UNORM16支撑长度比例；后者的区间合并/支撑长度算法仍RN-B02，不能仅以点数冒充覆盖。fit_support圆为实际LS的n，矩形为唯一侧分配后的可见边Σn_i≤N；source_seed圆cell13、矩形pair9高4零。fit_quality圆为RNE(65535×4Δ/(A+C)²)，矩形为所需四/三可见边中的最小TLS各向异性UNORM；零分母/不适用非法，不生成伪0合法质量。

bbox按圆cx±r/cy±r或矩形四顶点的几何极值算：min=clip(floor(extent_min_Q4/16),0,W/H)，max=clip(floor(extent_max_Q4/16)+1,0,W/H)，负值floor不当截向0。bbox只包几何，笔宽/标签额外选行范围仍RN-B05；不是图内crop几何或GT评分替代。规范0≤min<max≤W/H，空bbox/无图内支持不能形成合法最终目标。未用FINAL清单条目全零，但class0仅表示未用entry，不是有效对象。

### D4. PROFILE1024=128B实体

下表全部字段按低到高；每组保留全0，末尾另zero64，总1024bit。ref非0命中不可变完整body；layout=1/numeric=1，algorithm版本须在完整RC路线评审后明确登记。schema完整不代表已有生产默认。阈值实值必须由开发比较决定并保存，不能以0或名称替代未知。

| 组/bit | 全字段 |
|---|---|
| header128 | layout8/numeric8/algorithm16/profile_ref64/flags16/zero16；当前flags16=0，未知algorithm不安装。 |
| structure192 | theta_bins10=512/buckets6=32/batch_theta5=16/rho_bins9=277/rho_step_halfpixel6=16/center_pitch6=16/halo2（0…2）/sector_bins7=64/radius_hist_pitch_Q4_16/radius_hist_bins14/line_cap11=1024/segment_cap11=1024/pair_cap10=512/circ_cap11=1024/rect_cap11=1024/final_cap7=64/zero50。 |
| fit192 | circle_min_support21/line_min_support21/circle_det_min16/line_anisotropy_min16/circle_radial_tol_Q4_16/circle_normal_sin_tol16/line_residual_tol_Q4_16/line_normal_sin_tol16/endpoint_alignment_tol_Q4_16/parallel_sin_tol16/orthogonal_cos_tol16/zero6。 |
| verify192 | circle_coverage_min16/rect_visible_coverage_min16/circle_score_min16/rect_score_min16/circle_mean_SSE_max_Q8_32/rect_mean_SSE_max_Q8_32/missing_side_allowed1/required_visible_sides3/color_verify_mode2/color_tol8/zero50。 |
| dedup128 | circle_center_tol_Q4_16/circle_radius_tol_Q4_16/rect_corner_tol_Q4_16/support_overlap_min16/dedup_mode2/zero62。 |
| raster128 | stroke_Q4_8/label_mode2/label_scale4/label_offset_x signed8/label_offset_y signed8/map_merge2/priority2/zero94。 |

除Q4/Q8及计数外的16bit门均UNORM16。circle_min_support≥3、line_min_support≥2且≤N只是代数最低资格，不承诺这能辨识小目标。hist pitch非0；hist范围/峰选择和组织RN-B01/03，不默认可安装任意bin值。结构固定字段须等硬件实例；资源cap不可作为对象大小/数量硬验收范围，超cap失败。required_visible_sides只能3或4，missing_side_allowed1必须支持三边候选，值选择不凭20%旧假设。颜色mode0为无额外颜色过滤，1…3在路线闭合前UNSUPPORTED；相应color_tol须0，不能用未定义颜色核验提高声称质量。dedup_mode0不去重（开发比较）、1几何＋支撑重叠、2仅几何（开发比较）、3非法；1的实际支撑比较仍RN-B04。label_mode0无标签、1ASCII类别/序号候选、2文字字形待定/UNSUPPORTED、3非法；不能将“不支持”替代用户完整标注需求。stroke>0，启用label时scale1…15；关闭label时scale/offset规范0。map_merge0=原规则（0透明、同非零不变、异非零11、11保持），priority0=交换次序无关的合并；其它编码UNSUPPORTED。具体字体/栅格路线RN-B05；未知字段值拒绝安装。

实体选择随C570锁入当前job；PROFILE工作快照1024bit。profile注册表/引用容量仍沿父配置合同，本稿不增加或改变注册/返还规则，也不把尚未预算的表存储算入两ROM。

### D5. 八项交接与有限流控

| IF | 表示、前提与保证 |
|---|---|
| RN-IF01 | RC点提取→数值：x/y11、Gx/Gy11、dir2及父phase_key137，合法EDGE1/坐标/保留位；逐点point64，零G帧失败。 |
| RN-IF02 | θ/投影：当前向量/targetθ9/静态W/H；最多8次ROM比较→θ9，目标系数→q signed9/r uint9；不直接访问DDR。 |
| RN-IF03 | RC支撑→FIT：点坐标/梯度/明确本候选支撑判定；统计只在实际支撑接纳更新；无当前点不推进。 |
| RN-IF04 | FIT→FORMAT：原分辨率细几何、数量、SSE/覆盖/来源；检查D2…3，再占有限组装槽；不能用DDA/coarse峰即合法对象。 |
| RN-IF05 | 核验/去重→FINAL：最多64、类别与规范几何；容量/去重路线按B，不以压前K条替代。 |
| RN-IF06 | FORMAT→原RC W assembler：CIRC256/RECT512/FINAL512字节及实际record index；输出slot保持到复制/接受。正常为完整copy后接收，不将尚未接收的FORMAT body借作物理W源；MC req/W来源须独立备齐。匹配旧ctx取消时有独立本地接收/DISCARD资格，不等普通assembler空位且不发新MC；已复制的RAM pending和旧物理借用照父合同关闭。 |
| RN-IF07 | 可信C570/profile lookup→PROFILE：ref64＋body1024＋已安装/匹配证据；job前核验锁值，途中不查可变当前C。 |
| RN-IF08 | 数值结果/拒绝/失败→RC父：outcome2、reason8及完整父key；独立保存原原因，不截到MC error3；本稿不扩旧MC/LOCAL_TERMINAL/父终态字节。 |

内部NUM_REQ543=phase_key137/destination8/op3/a_signed1/b_signed1/result_bits9/A192/B192；destination是当前ctx的目的寄存器编号，不是可回绕的事务序号。op0MUL、1ADD、2SUB、3DIV_RNE、4SQRT_RNE、5COMPARE，6/7非法；宽度/符号按调用点typed规则核验。NUM_RESP540=原key137/destination8/outcome2/reason8/value385。outcome0VALUE/1LOCAL_REJECT/2FRAME_FAIL/3CANCEL_DROP；合法非VALUE的value规范0。reason8：0NONE、1GRAD_ZERO、2FORMAT、3COORD、4DEGENERATE、5ILL_CONDITION、6GEOM_RANGE、7COUNT、8ARITH_OVERFLOW、9CAPACITY、10PROFILE、11DIV_ZERO、12UNSUPPORTED、13INTERNAL，14…255非法。父保留原reason8；DATA error4命名分类不替代此原始原因。

MUL/ADD任一signed输入则结果为signed，全部unsigned时为unsigned；SUB结果恒signed。DIV只接受正分母，结果符号沿numerator，负分母须调用方先同时变号；SQRT只接受非负unsigned域。COMPARE先分别扩到signed193（unsigned输入高位补0），VALUE低2bit为0相等/1小于/2大于、其余0。其它VALUE按result_bits检查后sign/zero扩到385；请求的目标宽度0或不合调用点规范为FORMAT。非COMPARE收窄前检查完整真值可表达，不能借返回高位零掩盖溢出。

core正沿valid&&ready接纳；ready只依旧空闲/预留容量。只有一个scalar请求和一个结果资格，同一工作寄存器形成RESULT_HELD，不再收下一请求；body保持至实际消费后下一沿复用。上游可暂停点/候选计算；DDR terminal/release/capture通路不等待scalar或profile观察。返回key必须匹配旧已pin ctx，异常不释放物理scope。输入、段、local_terminal、fence和borrow归还继续完整DATA-JOIN契约。

## E. 中文数值操作草图

| INV | 必须保持及建立/更新原因 |
|---|---|
| RN-INV01 | job接受前完整C570/ref/PROFILE核验，旧ctx valid才计算；held期间不查当前配置，不混旧新body。 |
| RN-INV02 | 同(point,targetθ)只一票，同一候选支撑遍每点至多一次；Σeligible≤E、support≤eligible、n≤N，初始化0且只真实接纳增加。 |
| RN-INV03 | POINT/record保留零、几何先查域再收窄；完整body形成后输出保持，未用list项零与有效class0不同。 |
| RN-INV04 | ROM RE必须旧已预约k/key/目的word槽；pending下一沿必capture或DISCARD，不能被stall/reset抹掉。 |
| RN-INV05 | scalar只一live，请求key/目的与结果匹配；RESULT_HELD不改且不接受下一工作，消费后下一沿复用。 |
| RN-INV06 | RNE正负奇对称、den正、零分母/负根拒绝；运算先扩位，溢出/容量失败无饱和/回绕。 |
| RN-INV07 | 277rho的r138自镜、mirror276−r、padding235不投票；π normal与2π覆盖分开，G与径向采用不同位宽。 |
| RN-INV08 | local数值关闭不替代MC/fence/物理BIND；算术忙/输出stall不阻已备齐MC承诺继续结账。已valid FORMAT有匹配旧ctx的独立取消消费，body不改；所有私有copy/pending实际关闭后才报local关闭。 |
| RN-INV09 | 数值域外/退化有原原因与拒绝计数，质量未闭合不宣称完整成功；第K+1条容量失败不截K。 |

### E1. 检查与RNE原语

先核旧ctx/PROFILE安装、W/H、N及目标typed宽度。坐标越图/保留非零/EDGE1零G为输入帧失败，缓存无效不是0点。将合法当前点保存后才发数值操作。所有加减先在目标再多1bit或下述保守宽度计算，检查后提交；统计n先扩22bit检查≤N。DIV分母0及SQRT负数拒绝本运算并向父分类，不能以0商继续。

退化候选（Δ0/isotropic/无有效支持）计LOCAL_REJECT，继续算法允许的下一候选；域或唯一计数证明被破坏/累加器溢出则FRAME_FAIL。数值范围外候选GEOM_RANGE有显式计数，完整质量语义仍RN-B01/04。数值模块停止后关闭自己的ROM/scalar/组装pending，不据此返回父物理租约。

### E2. θ：Q30边界cross与最多8次二分

先检查G≠0。若Gy<0或Gy=0且Gx<0，整体取负，得到y≥0的π周期代表；已检查[-1020,1020]，取绝对值不存在最负值。M=max(|Gx|,|Gy|)>0、m=min，均uint10。折叠角q在0…128。

边界βk=(k+0.5)π/512，k0…127；ROM Ck=RNE(2^30 cosβk)、Sk=RNE(2^30 sinβk)，两unsigned30，合60bit。cross=mCk−MSk，两乘积unsigned40，差signed41。cross>0才越过此边界，cross=0与<0取较小fold q。寻找首个未越过边界；全越过返回128。129个结果最多需**8次**比较；不能以7次/轴与对角旁路自证全部域。

若代表Gx≥0且|Gx|≥Gy，θu=q；Gx≥0且|Gx|<Gy，θu=256−q；Gx<0且|Gx|<Gy，θu=256+q；其余θu=512−q。先保持θu unsigned10∈[0,512]；POINT的π周期输出单独θ=θu mod512收unsigned9，径向覆盖必须保留θu的512进位再按D2形成fullbin。G=(1,0)/(0,1)/(1,1)/(-1,1)分别0/256/128/384；G与−G同θ。径向完整2π统计另外保留原半平面，得到fullbin0…1023，不能直接拿POINT π周期θ作圆周覆盖。

ROM128×60=384 native20word，地址3k…3k+2，1RAM10；读word eK RE→eK后输出稳定→eK+1 preedge capture。可以流水读取不同word，但完整三个word均capture且原k/key一致后才cross。没有预留目的槽不RE；后来stall/cancel仍capture，不用同沿新capture值替代旧寄存器。单调常数的完整生成/审查尚未运行。Q30常数每分量误差≤2^-31，边界角扰动可保守界≤10^-9rad；最近角误差≤π/1024加该项。位精确oracle必须冻结此整数S/C表及cross>0/tie政策；未经有限输入分离证明，不宣称逐点分类等于无限精度β。较小fold q也不等于全θ较小tie。

### E3. ρ：277对称中心与wrap

投影ROM存θoctant0…128的cos/sin Q15，两unsigned16（cos0=32768合法），每C/S各占一个20bit word、高4零，因此129×2=258word；不是紧凑32bit位流，另1RAM10。两wordcapture后恢复对称/符号到signed17，范围[-32768,32768]；不能将32bit逻辑记录误解为两signed16。角511↔0比较在扩展θ+512时精确变号系数与ρ，不直接比较同r。

X2=2x−(W−1)、Y2=2y−(H−1)先在signed13计算，查域后收signed12，单位半像素；不能先以signed12形成2x的超域临时值。乘积signed29，P=X2cosQ15+Y2sinQ15 signed30。q=RNE(P/2^19)，signed9；q+138先扩signed10，检查q∈[-138,138]/和∈[0,276]后才转r unsigned9。其它512stride中的235地址不投票。中心ρ2=16q（8px步长），量化误差≤8半像素=4px。主图|ρ2|≤sqrt(1919²+1079²)≈2201.545；Q15系数附加误差≤2998/65536≈0.04575半像素，仍落277中心域。

RNE奇对称保证q(-P)=−q(P)，因此mirror(r)=276−r；r138自镜，±0.5→0、±1.5→±2、±2.5→±2，正负半cell tie同样精确，不再用旧275−r或额外±1补丁。比邻不同θ仍有相应投影角差，此精确镜像不证明跨batch NMS已实现；比较顺序/平票峰归属仍完整算法RN-B02。每(point,targetθ)只投一次，扩22bit更新vote21≤E；三个散桶读取/halo和单次目标batch不改变旧计账。

### E4. 圆法线LS

实际支撑点由RC路线给出，a=Gy、b=−Gx、d=ax+by。d signed24；A=Σa²、C=Σb² unsigned43；B=Σab signed44；D=Σad、F=Σbd signed56；n uint21。沿旧统计扩位相加，实际点只更新一次。d真实界≤1020×2998=3057960；A/C真实界<N×2^20<2^41，所选容器有保守余量。

Δ=AC−B²在signed89计算；Nx=DC−BF、Ny=AF−BD在signed101计算。Q4分子先signed105左移4；cxQ4=RNE((Nx<<4)/Δ)、cy同式。Δ≤0拒绝；T=A+C>0、4Δ×65535≥circle_det_min×T²才过条件门。条件门用完整交叉乘，不先除成低精度比。收中心signed18前范围检查，不饱和。半径拟合/多峰/稳健权重仍RN-B01/03；半径Q4非0且≤131071。每次径向平方距离先用足够signed差再全宽平方/相加，RNE_sqrt生成Q4距离，最后才残差/支撑/角覆盖/SSE。

三个不同点但全部法线平行也可Δ0，不能只以n≥3判断可拟合。条件差候选拒绝不是一份成功空圆；记录拒绝并保留质量统计。

### E5. TLS细线、端点与交点

统计用centered X2/Y2：n21，Sx/Sy signed33，Sxx/Syy uint43，Sxy signed44，共217bit。当前四边至少868bit独立统计，CIRC/TLS不同时工作可分时此统计区，不能存进128bitSEGMENT。

先在signed67中计算Cxx=nSxx−Sx²、Cyy、Cxy=nSxy−SxSy；检查n≥2、Cxx/Cyy≥0及CxxCyy−Cxy²≥0，PSD失败为内部/计数错误。经真实域检查收Cxx/Cyy unsigned64、Cxy signed65。u=Cxx−Cyy signed65，v=2Cxy signed66，D=u²+v² unsigned133；D0为isotropic，拒绝方向不定义的候选。

为保留根的小数，Rq16=RNE_sqrt(D<<32)，输入≤165bit、结果uint83。u≥0时t=(Rq16+(u<<16),v<<16)，否则t=(v<<16,Rq16−(u<<16))，统一signed85。L=RNE_sqrt(tx²+ty²)，输入≤171bit、根uint86，L>0。tQ30=RNE((t<<30)/L)，分子≤115bit、结果signed32范围±2^30。法线nQ30=(-tyQ30,txQ30)，规范到ny>0或ny=0且nx≥0；rho同号变换。最终方向由TLS，不以θ9替代。

各向异性门以Rq16×65535≥line_anisotropy_min×((Cxx+Cyy)<<16)判；full宽比较。以上R的Q16量化误差≤2^-17统计单位，非零D整数给真实R≥1，可界方向扰动；质量门和支撑选择仍不能由此数值误差替代。

绝对rho_Q4只舍入一次：RNE[8×(nxSx+nySy+n×(nx(W−1)+ny(H−1)))/(n×2^30)]，nx/ny是Q30法线。不能先把均值取整再求rho。点的沿线投影t_Q4=RNE[8×(txX2+tyY2)/2^30]；支撑端点tlo/thi从实际有效集合取得，不从整候选所有共线纹理的全局min/max冒充同一段。投影按(tQ4,y,x)稳定顺序可定义，排序/分段/缺边支撑形成仍RN-B02。

直线残差统一使用上述已量化细线：f=16×(nx×x+ny×y)−2^30×rhoQ4在signed50计算，K=nx²+ny²为uint65。先核分量∈[-2^30,2^30]及K≥2^58；坏normal是INTERNAL帧失败，不输出伪距离。合法TLS的t主要分量≥65536、L为其范数最近整数，因此Q30向量长度大于2^29，满足该守卫。K/M作为四细线各自不变缓存，M=RNE_sqrt(K) uint33。残差定义为**精确实数距离的最近偶舍入** q=RNE(|f|/sqrt(K))，不是先把近似M当真实norm后直接定inlier。

数值步骤先q0=RNE(|f|/M)，用uint21容器。|f|≤2^49、M和sqrt(K)≥2^29，故两未舍入距离差≤2^-10 Q4单位，q0与精确q至多差1。令F4=4f²；q0>0时若F4<(2q0−1)²K，或相等且q0为奇数，减1；否则若F4>(2q0+1)²K，或相等且q0为奇数，加1；其余不改。修正后再次核同一上下边界资格，不满足为INTERNAL，不进入无界迭代。q先完整保留uint21，与profile uint16残差门比较，只有inlier才收uint16/写max/SSE；不能将大残差截成小inlier。比较最大约109bit及F4的102bit均在192bit操作数域内，不新增NUM opcode。

角点的唯一侧分配在算法已给的合格边集合内比较f_i²×K_j与f_j²×K_i，按精确距离平方排序，等值取小边号；这些交叉乘最多165bit。资格窗口/端点/可见区间的生成仍RN-B02/03；此处只消除归一化、整数残差和tie歧义。每inlier的q²是Q8单位，SSE和mean_limit×support同单位。

两细线(nx,ny,rhoQ4)交点：den=nx0ny1−ny0nx1 signed65；xQ4=RNE[(rho0ny1−rho1ny0)×2^30/den]，yQ4=RNE[(nx0rho1−nx1rho0)×2^30/den]，负den先整体变号。分子≤signed81；den0拒绝，邻边平行/正交门须过profile交叉乘检查；最终signed18范围、相邻顶点不等、面积非零、四边不自交/逆时针再形成几何。不能把截后相等当合法零宽矩形。

端点/间隙单位统一Q4；完整范围差应uint18，不沿旧maxgap14默截。若占用统计定义为1px沿线cell，可用uint12（全主图投影跨度至多约2203cell）；若用Q4 cell则需更大字段，不能混称。SEGMENT128详细重排及真实cell统计尚RN-B02，本稿不擅改旧段表。整短边缺失候选可以kind1/三侧支持，但两个远端如何推出缺边、U形负例与颜色/纹理区分仍B，不要求四边封闭才生成候选。

### E6. 记录形成与共同判定

先核字段域与数量，按D2…D4形成完整body，保留全0；不是逐word从持续变化统计拼快照。一个512bit组装槽在输出/复制完成前不可改。CIRC/RECT由各phase先写，后phase依旧fence才读；FINAL不可边绘制边更改。FINAL第65条/CIRC或RECT第1025条为容量帧失败，不截前K。

计数/格式/算术域破坏FRAME_FAIL；纯拟合退化LOCAL_REJECT。对同一个实际支撑点不可二次加SSE或支持数。取消同沿旧真实NUM接受/输出/ROM capture仍登记；已提出的NUM_RESP保持原body，接收方按取消的旧ctx消费后DISCARD，不能改held VALUE为CANCEL_DROP。仅尚未形成有效NUM_RESP的私有结果可形成CANCEL_DROP。停止新业务不清旧MC/pending/tag，独立local关闭证据仍按DATA汇合。FORMAT已valid记录同样保持旧key/body；匹配取消的旧ctx通过独立本地接受资格消费后DISCARD，不依赖普通assembler ready、不申请新MC。正常copy已接收的记录转由assembler持有，已借物理段的数据继续真实排空；未完整copy且未接收的FORMAT不能构成物理W承诺。任何提前私有RAM复制/pending仍需真实完成或关闭，不能仅丢valid就报local关闭。

### E7. 去重与核验能确定/仍未确定的边界

可确定候选规范排序：同类按score降序、均方SSE升序（交叉乘比较）、proposal_id升序；异类不互相去重。矩形对应角可比较四种循环及反向排列；circle中心/半径距离门与rect最大对应角距离门用全宽平方比较，不先整数sqrt截断。exact score/tie保留低proposal_id，稳定且可复现。

支撑交并计数若从同一完整POINTS遍历得到，可定义overlap=RNE(65535×both/union)，每点一次、union0不允许合并；门为≥profile值。仅几何近似不证明同一真实目标，不能因bbox重叠删同心/相邻圆。获取两个候选真实支撑集合、动态final选择/合并重拟合和工作量尚RN-B04；因此不能宣称dedup_mode1闭合或安装生产profile。IoU≥0.5是一对一质量评估规则，不自动等于去重门。

## F. 语言、逐沿、有限算术与预算

无C++实现；未来独立数学/逐位参考沿既有软件路线另获批准。无限精度参考必须显式模拟下述类型/舍入，不能掩盖RTL截断；数学识别真值/逐位数值/硬件协议三份契约分开。

共享scalar一份：A/B各192bit、完整无符号乘积384bit及signed/overflow guard385bit。加减先将两输入各自sign/zero扩至signed193，再在signed194计算，覆盖signed/unsigned混合最坏值；不能只留193bit和而丢符号/进位。除法最多192bit被除数/正分母、余数193bit，sqrt本稿最大171bit被开方/86bit根。所有最大宽度和typed结果收窄先检查。16×16逻辑乘法/MAC按12×12 digit学校乘法最多144部分积；有部分积的列为0…22共23列，但完整384bit必须输出**24个16bit word**。第24word来自末carry，先检查carry高于16bit的部分为0再写入，不能漏最高word或默截carry。每列最多12项，unsigned36累加外加1guard，carry20。可串行16bit加减、restore DIV最多192位步骤、两bit/restoring SQRT最多86步骤；结果按RNE处理。逻辑乘法单元不宣称已映射一块物理DSP；实际原语/流水/100MHz STA未证。

| 已列数值FF容器 | bit |
|---|---:|
| 当前4边217统计 | 868 |
| 四细线normal两signed32/rho18/support21/端点两18 | 556 |
| 四细线norm缓存：K65/M33 | 392 |
| derived临时，包括D165/根/比较等 | 1280 |
| scalar：A/B384＋product385＋remainder193＋MAC37＋carry20＋control256 | 1275 |
| PROFILE当前快照 | 1024 |
| 一个记录组装/输出槽 | 512 |
| 当前POINT保持 | 64 |
| θ边界60＋projection32 capture | 92 |
| 外层有限计数/valid/预约预算 | 128 |
| 此处已列小计 | 6191 |

6191只是寄存器容器预算，未含完整job/scope/C570副本、PROFILE注册表、RC MC holding/目录/所有metadata/字形与全机FF；后续具体状态增加须显式补，不当XLR综合值。数据RAM仍旧RC58；新增两native20 ROM共2RAM。**DATA现178＋2=180/256=70.3125%仅已列RAM预算**；半径hist/字形若不可明确复用仍另计，不能隐藏在17或58内。

| RTL A–L | 契约 |
|---|---|
| A数值 | D/E全宽、signed与RNE；无clip/回绕；阈值交叉乘、negative divisor归正。 |
| B时钟 | core正沿；RE eK后RAM值更新，eK+1 preedge capture；输出更新后下一沿最早接受。 |
| C接受 | 输入NUM/记录valid&&ready，旧容量；scalar仅一live，点计算可停，DDR后台不等它。 |
| D推进 | 支撑接纳才更新n/统计；NUM结果交付与POINT/记录交付各自计；valid0不当0点。 |
| E反压 | held body/key/profile不变，pending有预约照capture；一个记录slot满暂停新候选。 |
| F延迟 | 最多8次θ比较，各次3word capture及两乘/一减；通用MUL144部分积＋24word输出为步骤预算，DIV192、SQRT86步骤；未测周期、算法fps及全机deadline，不将步骤数直接承诺时钟。 |
| G复位 | 私有无承诺结果可DISCARD；完整MC/父引用和旧pending按DATA保持；Q不靠数值reset释放。 |
| H配置 | C570/ref/body完整校验锁定；同沿新CFG/job取旧已锁C；途中不回读当前参数。 |
| I存储 | 两只读ROM各20×512，384/258有效word，其余0；RE预约目的/k/key、下一沿capture，无未预留读。 |
| J身份 | 全原幅坐标；Q4中心/顶点不因绘图bbox剪裁改值；πnormal和2π覆盖不同；padding不当点。 |
| K CDC | 数值核不新增CDC；父配置/输入/终态由原合同一致保存，不以本同域审查证明外部CDC。 |
| L实现 | SV2009/Efinity2026.1.132/Questa2024.1候选、Ti60F225；物理DSP/RAM推断/PNR/STA未运行，原审批条件继续。 |

共同数值：对相同锁定profile/输入集合逐bit比较POINT、整数θ/ρ、全部统计和记录；质量另比独立GT。硬件执行：真实handshake/pending/配置/取消计账，不用函数调用返回代替MC排空。对应关系：软件record i对应同job同类表第i条/坐标来源，输出顺序规范稳定，取消后未发布前缀整体无合法图，不允许仅比较幸存目标。

## G. 未来实施/文字验证计划

必须先闭合当前B并指定版本/范围批准。允许的未来增量为常数/typed数值→θ/ρ→记录→LS/TLS→scalar/holding→完整RC组合；拟职责recognition_numeric_format/angle/project/fit/scalar/profile，全部未生成。常数表生成器、参考程序、场景/runner/TB同受批准门槛，不先产探究程序。

| TEST | 输入/事件与期望；全部NOT_RUN |
|---|---|
| RN-T01 | POINT x/y/G字段边界、高保留非0、EDGE1零G；非法帧失败不造角。 |
| RN-T02 | 四轴/对角及G与−G；θ0/128/256/384正确，q0与q128两端都存在，最多8比较。 |
| RN-T03 | cross正/负/0，m1/M1020与m1019/M1020；首/尾bin可达，等号低fold q，不能7比较漏叶。径向dxQ4=-10000/dyQ4=16应θu512/half0/full512/sector32；dxQ4=10000/dyQ4=-16应θu512/half1/raw1024/full0/sector0，POINT才mod512，不能提前丢进位。 |
| RN-T04 | RE/capture、第三word晚到、stall/cancel；k/key保持，旧pending照capture，无同沿新值误读。 |
| RN-T05 | ρ0、±0.5/±1.5 cell与极端坐标；r138/镜像276−r严格，no±1补。 |
| RN-T06 | cos0=32768及θ511/0重建；unsigned16 ROM→signed17无符号误判，正负投影RNE。 |
| RN-T07 | 圆平行法线Δ0/条件边界与近退化；拒绝不除0；Q4中心单轮舍入，完整LS宽度不截断。 |
| RN-T08 | TLS水平/垂直/斜线、isotropic点集；D0拒绝，非退化Q16根/细方向，不锁coarseθ。 |
| RN-T09 | PSD破坏、n>N、重复点/累加器溢出；明确失败，不让container包裹成成功。 |
| RN-T10 | 交点den0/负den、极近平行、相邻顶点相等与超Q4域；拒绝/错误分类，无clip。量化normal非恰好单位时按精确f²/K距离及RNE边界判断残差/侧分配，门前不截uint16；K小于2^58为坏normal，q0最多±1修正且再次核资格。 |
| RN-T11 | CIRC/RECT/FINAL各字段、SSE53、三边mask/absent ID、unused全0；固定长度逐byte一致。 |
| RN-T12 | PROFILE badref/版本/保留/阈值域、同时C更新及job、held旧profile；完整拒绝或旧快照不混合。 |
| RN-T13 | scalar/record两类输出stall与取消、MC W已备齐在scalar忙时；已valid NUM/FORMAT保持body，匹配旧ctx本地消费DISCARD且不发新MC，已copy/物理借用仍排空；独立后台终结不死锁。 |
| RN-T14 | capacity K+1、score/SSE tie、同心与相邻目标；失败不截K，去重B未闭合不报通过。 |
| RN-T15 | 完整1080p/图外中心/整短边缺失/U形/纹理；质量与数值分开，每类P/R95%及IoU0.5评估沿RC独立集，所有失败保留。 |
| RN-T16 | ROM生成/hash/单调边界、RAM/DSP/FF和STA/真实DDR组合；只在获批后运行，预算不当通过。 |

参考观察数值输出在形成沿后稳定、接收方下一沿preedge采样；波形事务另按fire记日志。手工例说明期望不代替实际场景运行。

## H. 双向追踪

| 要求/来源 | MOD/IF/E | 拟职责（未生成） | 场景 | 实际代码/证据 |
|---|---|---|---|---|
| RN-01 RC GRAD/POINT | FORMAT/ANGLE；IF01/E1…2 | numeric_format/angle | T01…04 | 待实现/NOT_RUN |
| RN-02 π/rho | PROJECT；IF02/E2…3 | project | T02…06 | 待实现/NOT_RUN |
| RN-03记录/容量 | FORMAT；IF04…06/D2…3/E6 | numeric_format | T10…11/14 | 待实现/NOT_RUN |
| RN-04 C570 | PROFILE；IF07/D4 | profile | T12 | 待实现/NOT_RUN |
| RN-05拟合 | FIT/SCALAR；IF03/E4…5 | fit/scalar | T07…10 | 待实现/NOT_RUN |
| RN-06有限执行 | 全部；IF08/F | numeric holding | T04/13/16 | 待实现/NOT_RUN |
| RN-07质量 | 完整RC；B/E7 | 原RC识别/评分 | T14…16 | 未实现/NOT_RUN，当前B |

反向：每个拟数值单元只服务上表表示/拟合/有限交付；不新增模型下载、所有权或控制命令职责。当前没有业务符号可声称与设计已一致。

## I. 门槛

规范10.3①整体与样例、②职责/来源、③候选表示和相容检查、④中文数值步骤、⑤A–L与独立映射、⑥手工走查、⑦计划追踪均有候选内容；⑧无当前阻塞不满足，⑨本稿保存读回由报告给证据，⑩范围与输入hash明确。没有READY_FOR_REVIEW记录、没有指定实现批准、没有写Approval Manifest/数据库。允许下一步是读审与闭合RN-B，不生成实现/实验/测试。

## J. 与旧稿的指定差异和恢复

本稿J只覆盖旧RECOGNITION v0.1 D2/IF03…06/OP04…06/F中的指定**数值字段与舍入提议**：POINT不改；θ整数边界/8次二分；旧276 floorρ改277对称RNE；CIRC32B/RECT64B/FINAL64B详细字段；PROFILE实体候选；LS保守宽度保持并补守卫，TLS最终细方向；两个ROM及有限scalar预算。

旧RC/CONTROL/CJ/DATA文件字节均不改；父文件即使引用本候选也须显式吸收差异，不能认为保存本稿自动升级其合同。四phase、scope/grant/permit/req/terminal/release/fence/borrow、输入/结果绑定、配置身份/历史和用户质量目标沿父稿，不另立所有权版本。旧23 Canny本地状态不变；本稿不是整个RC READY的替代物。

恢复先核本稿/输入hash、父稿是否已吸收277/完整record/profile、当前算法B及指定审批。常数/结构/阈值改变须改对应D/E/T与版本，再评审；不能借配置授权生成ROM源码或运行参考。

## K. 实录

本轮只读RC/CONTROL/CJ/DATA、实际读v0.2/模板、手工设计算术及保存这一新Markdown；最终全文读回/hash另报告。未生成RTL/C++/Python业务实现、常数生成器、功能脚本、测试/TB；未编译/仿真/综合/STA/下载/烧录/观察实物；未改旧资料或正式状态。所有T NOT_RUN。

## L. 交付与反向阅读

从B输入/输出区别→C连接→D完整字节→E2一个G=(1,1)和ρ0例→E4/5实际支撑的拟合→E6完整record保持→F预算与G验证。反向由FINAL geometry/metrics回D3，再查形成其支撑、条件门和原父job/profile；不能由一条漂亮几何记录推断完整识别或质量成功。变更角/舍入查RN-02/E2…3/T02…06，变更几何域/threshold查RN-B01…04/D2…4/T07…15。理解验收未收到用户作答，标待检验；实现和功能验收未执行。
