# FIT v1：最终位宽、工作槽、关闭与组合审阅

2026-10-07，root作者及静态审阅，非独立Agent复核；设计分析，不是RTL/仿真/综合PASS。审阅输入：主卡v0.5、子运算v0.1快照及v0.2、首错/预算v0.1、验证/probe v0.1、原scalar协议/状态。对应F-B01…04与规范十项门槛，供最终v1引用。

## 1. 全宽与signed逐组核查

标记sN是N位二补码，uN是无符号。所有私有operand在发406命令前规范扩至192；原scalar先形成385真值并核target。父从旧403缓存核矩阵及完整高位，再按typed目的收192；平方由signed输入乘出后先核非负，才按unsigned使用。MUL/ADD任一signed使child结果signed、SUB恒signed，COMPARE两输入分别扩域，根及floor除flags0且根B0。

| 路径 | 实际界与表内target | 组合结论/不能省的守卫 |
|---|---|---|
| LS T/Δ/门 | A/C u43使T u44、AC u86；B s44平方由完整s88非负化；SUB s89；Δ>0后4Δ u88，质量分子与det门 u104 | 不能把B²低位当signed负数；Δ≤0先局部拒绝。T²−4Δ=(A−C)²+4B²保证quality≤65535，但完整除法与17位资格仍执行 |
| LS中心 | DC s99、BF s100、Nx s101（Ny同）；宽移4为s105，正Δ u89除得s106 | 完整商后才s18几何；cx资格通过后才cy；不借target18制造ARITH_OVERFLOW |
| TLS协方差/PSD | n≤2073600<2^21；nSxx<2^64，Sx²≤2^64，Cxx/Cyy/Cxy s67；Cxx/Cyy非负后u64，PSD左u128、原Cxy²完整134 | Cxy先s67做PSD，PSD成立使abs(Cxy)<2^64，才可收s65；负Cxx/Cyy及PSD破坏为INTERNAL，不因窄化丢掉符号 |
| TLS根/方向 | u s65/v s66；D u133、D<<32 u165→根u83；t s85、平方170/和171→根86；t<<30 s115/商116 | 移位前扩，不在u/s旧容器内先溢出。L≥max(abs整数t分量)，使Q30商在±2^30；完整商、域和K下界仍核 |
| TLS rho/μ | 先规范normal。nx/ny≤2^30，Sx/Sy≤2^32幅，n<2^21，W−1+H−1≤2998；统计项加origin项的幅小于2^64，×8小于2^67，s69有余量 | 表中s68先宽扩再×8检查s69有实际界依据；den=n<<30 u52。rho商70先s18资格，成功后μ商70；一次RNE，无平均值先舍入 |
| 交点 | 两s32normal平方各target64、和u65守卫；den s65，两个分子s51宽移30为s81 | den负扩位取负并规范正u65，分子暂收s82，商s83再几何。两线K各核，不用单K或取根替代 |
| LINE | f s50、abs取s51后u50，f²完整100→4f²u102；q0/最终q u21，odd u22、square44、乘K65得u109 | K≥2^58/M>0；最多±1修正后两界再核。q0不能直接决定inlier；q0=0无负odd |
| FINITE | 16x/y u15；p/d s19，乘38、z/c s39、K u39；端点N规范u78/D1，内部c²完整78非负/D=K | z扩s40、K扩u40再比较，不能把u39直接当s39；K1合法，仅K0退化，不施加Q30门 |
| FINITE新尾段 | 真距离不大于某端点距离，p量级小于2^18，使N/D<2^37；floor商37→floor根19；odd20、square40、乘D39得u79，与4N u80比 | floor(sqrt(floor(N/D)))与真实向下根等价；精确中点/最终资格仍保留，原N/D不约分或改表示 |

最高工作typed值是u171，低于192；不存在为了凑16槽而隐藏额外大整数数组。PRIVATE target0、不正分母或根signed flag不应由合法调度产生；真实child若返回合法帧错误保留reason，否则协议破坏INTERNAL，并记录原响应。

## 2. 逐组工作槽寿命与一写规则

- LS：w13/14的AC/B²在L04消费后才能换DC/BF；DC/BF被L12消费后才换AF/BD。w1Δ/w2T²/w3质量分子保留至中心/最终质量；w11条件code/w15门右侧在L09后死亡。17跳中心，PACK不读w8/9；每个SHIFT和几何规范独立提交。
- TLS协方差：T03后w0保持，T06后w1保持，T09的w2在原s67 PSD完成前不缩；w13/14只在旧乘积消费后复用。T15的trace<<16在w14保持到T26；Rq16留w6直到构造t。T26只写w15的anis资格，μ虽填0但未有效。
- TLS t：u<0时ty先w3暂存，w8旧v→w7、w3→w8分两沿，不能同沿交换丢ty。T36覆盖w7时w8原ty仍活；T38后两归一分量才可写w10/11。反号flag由旧两个normal一次锁定，各NEG独立沿；最终t=(ny,−nx)，不用之后已复用的w7/8。
- TLS rho/μ：T43消费产品后可覆盖w13/w7；w14最终rho在T51后保持至PACK。T56把μ写w15低18、保持已有效anis16及高158零；w9旧L此时已死可放μ宽商。T57/58只覆过期产品，K w12与M w13独立保留；T60安装cache需合法旧normal、旧K与当前已消费M，取消同沿禁安装。
- 交点两K：先normal0的平方→w13/14、和→w12并核K，再normal1同三步；前一个K已获资格后不需保存数值，使用父控制两个normal已查标志。两个K都过才开始I01；旧乘积/w12不再活，den w0在整个两商期间保持。负号flag在den改变前锁定，den与两个分子分别NEG，不能第二次由已正den重选分支。
- LINE：w0/1 K/M直到PACK不改；w2 f在D13平方前仍活、w4 F4到最终资格不改。每个边界使用w5/6/7/15，旧compare消费后才启动下一个；D23至多一修正，最终重新执行资格，最多四边界组。cache hit用两个局部MOVE写K/M，不追加算术调用，不跳错误检查。
- FINITE：p/d在分支前保持，分支B在z判定后才覆p；c在形成N后死亡可覆odd。w7N/w8D/w9F4保持完整尾段；新w10=floor商、w11=floor根、w12最终q；w13在第二乘返回时可覆旧odd平方，因为它已经锁入父命令并被桥接纳。原二分lo/hi不再是本RTL槽角色。

所有私有返值在QUALIFY_RETURN一次真实fire写一个工作槽，下一ADVANCE才使用；LOCAL_COMMIT一次一槽。w15双字段分别有效，一次整槽写只更新指定字段。cache entry是独立所有者、163位一次原子安装，不冒充第二次工作槽写。新外部请求清本次槽资格，reset清cache valid；正常取消可保留已完成纯K/M缓存，却不复用旧父结果。

## 3. 有限推进、形成沿与取消沿走查

每个真实原child无外仲裁/反压：从父PREPARE沿p0锁406，到p1 cmd_fire、p2桥CHECK、p3 child_req_fire；原child首次valid在p3+C沿后；p4+C桥实际收返回，p5+C查quiet并形成桥valid，p6+C父WAIT选QUALIFY，p7+C真实result_fire写槽，p8+C ADVANCE读完成事实。该链附加8沿，预算每调用16沿容纳资格/模式选择余量。不得在parent WAIT或bridge WAIT引入依外部rsp_ready的等待。

除原child内部有限算术循环外，父步骤是无重复LS/TLS/交点序列或LINE最多4边界组/FINITE最多3边界组。最大编号61，局部交换/规范/选择/cache每编号最多16个非等待控制沿，入/出不超过16沿，总61×16+16=992≤1024；实际实现必须按此有限设计核对，不能以余量允许新增1024轮业务循环。旧FINITE19轮仅独立参考，不进入RTL。原child静态196/18/5/198/677/485沿及调用17/46/17/22或18/26/7/20据此前逐步表，TLS加权+控制预算9533、整体检验16384；外HELD等待无限，超预算测试FAIL并保留live，不合成强制删除。

取消匹配当前外ID或同沿新req ID；错ID不作用。最深SEND路径，在c0父收到匹配取消并assert abort，旧child req_fire先记；c1原child未暴露计算转HELD DROP，c2桥真实rsp_fire并关闭child，c3桥quiet确认转RESULT_HELD，c4父DRAIN真实result_fire，c5桥quiet使父PACK，c6父HELD DROP。≤8沿预算保留2沿余量。若原child已HELD，其body保持，c0/1起真实消费/DISCARD，路径更短；若只有父已发布但未被桥接纳的命令，DRAIN保持valid/body至cmd_fire，桥CHECK本地DROP后真实消费/quiet。未发布请求和无private pending取消也必须经真实quiet/父PACK，不自动等同已交付。

上述关闭仅私有纯算术同域范围。fault child若不返回或不quiet，不能靠8沿强行释放，测试记录未关闭失败。冷reset才共同作废父/桥/child/source/consumer，普通cancel不重置private序号、不退回MAX或改已HELDbody。内部首错关闭private时assert abort不等于外部cancel，父保留原错误；外cancel若在父未HELD则优先DROP。

## 4. 错误次序和独立期望相容

核对R3 D1/E1：尺寸→version/owner/kind→flags/target→padding→本操作输入域；EXECUTE仅核已形成的步骤。n>N帧COUNT、n不足局部COUNT是本设计明确提议；PSD/坏normal/K帧INTERNAL，Δ/D/零有限边/den0局部DEGENERATE，门左<右局部ILL，宽cx/cy/rho/μ/交点商后局部GEOM；未VALUE全零。诊断只n/quality，不以完整拟合的新几何拒绝替代诊断。

独立参考采用相同首错次序和数学定义，改变的是运算安排：直接整数LS/TLS式；LINE/FINITE有理平方阈值搜索，不采用DUT q0/M或floor尾段/cache/工作槽。值比较全部585位；错误、取消、复位作废分别判断。两合法q0=2→1/3反例明确刺激真实±1修正；其M与threshold方向手推成立，尚待未来运行，不用非法normal或force private结果覆盖主路径。

原scalar pkg没有LOCAL_REJECT等拟合码。FIT/bridge/probe只wildcard导入fit_protocol_pkg；原scalar_core继续只导入scalar_protocol_pkg。需要scalar既有函数/常量时显式包限定，不能双wildcard制造重名常量歧义；编译先原scalar pkg再fit pkg、各模块。SV2009同步过程非阻塞、组合过程阻塞且每条分支默认全赋值，不引入latch/驱动冲突/隐式signed窄化。

## 5. source、物理与文件追踪

LS正常源由3图内点及非零法线推得A/C/B/D/F，中心16xc/16yc且quality49151；TLS两中心奇坐标反点统计rank-one PSD、anis65535、rho几何合法/μ0。其法线两分量都非零，不等于LINE的(2^30,0) key；首次profile0第3slot必miss，第7slot之前无其它normal安装故必hit。raw profile动完整typed字段及明确合法化，不伪称均为真实图像统计。

source/request/response三种槽各1，384LFSR和seq只随真实req_fire推进，LED翻转读被消费旧请求ID；585位CRC消费完才新请求。新core仍10782bit候选容器、DSP16含source小乘法、RAM0/XLR50000候选；资源和setup/hold/真实data D路径均未来实测。约束/四pin只沿原scalar同一资料参考，不证明尚未到货硬件或生产video时钟；旧stage SR与LED例外外不复制false_path。

19文件均有双向关联：原2算术RTL与桥FT01/06/07→T07/08；fit pkg/core FT01…07→T01…09；reset/probe FT08→T08/10；独立2model和4TB FT08及对应数学/协议→T01…10；sim/build/STA/三工程 FT08→T10。没有R4候选/字体/DDR/相机等越范围文件。19文件、seed/hash与tool entry要在批准后每attempt快照，原3RTL严格不变。

## 6. 本轮结论与冻结条件

F-B01交接、F-B02位宽/槽/有限推进/取消、F-B04首错和F-B03文件/来源/参考/语言/测试/物理计划，在当前独立七kind范围均有具体内容；未发现仍影响本核定义正确性的未决决定。原完整识别/DDR/生产接口缺口明确在本范围外，不能以本结论称整包完成。

下一步将这些最终选择并入主卡v1、保存旧v0.5，读回最终主卡，再冻结指定基线（含本审阅）并核每个真实输入。只有这些实际完成且呈现用户后，才记READY_FOR_REVIEW；仍需指定批准与本批本地审计例外。当前没有生成业务源码/TB/参考/功能脚本、启动EDA或访问网络，正式DB/状态/硬件未变。
