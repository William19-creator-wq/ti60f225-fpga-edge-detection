# 拟合核：文件、独立参考、真实输入与验证草图 v0.1

2026-10-07；关联 FIT 主卡 v0.5。纯设计，全部 NOT_IMPLEMENTED/NOT_RUN。原 scalar 字节、ANGLE v1.1 与其34份输入保持；不生成本页所计划的19份业务文件。

## 1. 在整体中的位置与实施顺序

本批只补 A6 的七类数值运算。外部冻结统计/几何 → fit_core → 私有桥 → 原 scalar → 当前工作槽 → 585位结果；生产支撑选择、候选去重/质量、DDR、Canny滞后连接和相机/HDMI仍由后续独立设计承担。完整识别要求、1080p和现有板卡资源边界保持。

未来独立 work 为 `work/active/track4_algorithms_20261004/r3_fit`。先 pkg/独立参考 → bridge 与 helper 单测 → fit 核数值/协议 → 真实 probe 来源/结果/CRC审核 → 同源 Map/Interface/PNR/STA → 必要门槛通过后 bit/hex staging登记；其后停止硬件步骤。失败保留 attempt，不修改独立期望使结果变绿。

| 类别 | 计划19文件及职责；尚未生成 |
|---|---|
| 7 RTL | rtl/fit_protocol_pkg.sv（字段/编码及无状态资格/舍入政策）；rtl/fit_core.sv（七kind与工作槽）；rtl/scalar_bridge.sv（私有ID/关闭/缓存）；rtl/scalar_protocol_pkg.sv、rtl/scalar_core.sv、rtl/reset_sync.sv（3份原字节）；rtl/fit_probe_top.sv（真实源/结果消费/CRC） |
| 2 model | model/fit_reference.py（独立大整数/事件审核）；model/fit_vectors.py（确定与固定seed场景及期望清单） |
| 4 TB | tb/tb_fit_helpers.sv（调用pkg实际函数）；tb/tb_scalar_bridge.sv（真实child及分账隔离故障）；tb/tb_fit_core.sv（七kind/协议/槽/缓存）；tb/tb_fit_probe_top.sv（来源及585位CRC） |
| 3运行支持 | scripts/run_fit_sim.ps1；scripts/run_fit_build.ps1；scripts/postroute.tcl |
| 3工程 | project/fit_probe.xml；project/fit_probe.peri.xml；project/fit_probe.sdc |

pkg计划稳定职责：decode_fields、check_request、normalize_slot、choose_midpoint_even、qualify_distance_bounds、pack_response；这些是设计名称，没有函数体。helper不另放一套距离乘法：wide乘/比较仍通过唯一 scalar，pkg仅使用已形成比较码与候选奇偶执行局部政策。isolated helper用合成比较等号测试政策，主核不能 force N/D 或 private 响应制造半距离。

docs下中文模块阅读、逐沿操作、追踪、DELIVERY是授权范围内说明文档；runs下.do/向量/JSON/原日志/波形/快照/STA/门槛是上述runner的派生产物，不能借派生名加入新功能。3份原RTL须hash一致，不能顺便修原核。

## 2. 三份契约与独立期望

共同数值：沿主卡D/E、子运算v0.1快照/v0.2、首错/预算v0.1。软件使用Python3.14标准库整数与math.isqrt，无浮点/C++或新依赖。参考直接计算完整统计式和量化几何，不维护DUT的16槽、FSM、缓存或private序号来生成数值期望。

参考有符号RNE除法按绝对商/余数及偶数规则，再恢复符号；整数RNE根先 isqrt，再比较4A与(2k+1)²，不用两平方误差差值充当实数根中点。LS一次完整商后几何；TLS PSD在Cxy收窄前，t/normal/rho/μ按最新主卡；诊断不求新几何。

两类精确距离参考共用独立的有理边界搜索：LINE取N=f²、D=K，FINITE按端点/内部取得原N/D，用4N与(2m+1)²D的单调关系找最终q，再核上/下资格。LINE搜u21域，FINITE搜u19域。参考不先用M求q0，不运行DUT的floor除/根路线，不读取DUT K/M cache；每次重算M并比较其输出。因此可以检验两种不同实现的等价性。

硬件执行：posedge沿前valid/ready/fire、旧状态运算、沿后提交；下一posedge才消费新结果。TB在negedge设置输入、posedge前记录fire、沿后检查保持/状态资格，避免和NBA同观察区竞争。私有请求每个真实fire分别记外部fit ID与private_scalar ID、目的/操作数/target、原响应/关闭/槽提交；数值期望不由监控到的内部中间值反推。

对应关系：每笔软件输入与实际外部req_fire完整622位对应；比原ID/kind/target/outcome/reason/value385全部585位。已HELD取消比旧body并记DISCARD；未暴露取消比DROP；joint reset作废按accepted账另列。outer_fit/private_scalar命名域明确，不能因两个176位位模式相等混账。完整识别GT/质量不由本数值参考代替。

## 3. 两个合法主核修正反例（手推，未运行）

W6/H5，kind14，格式/normal/K/图内point均合法。M是RNE sqrtK；q0=RNE(absf/M)，最终q定义仍使用真实sqrtK。这两个输入不依赖随机寻找或非法替换内部响应。

### 减1

nx=715827872、ny=−1、rho_Q4=−1、P=(0,1)。令M=715827872，则K=M²+1，M>2^29、nx<2^30，RNE sqrtK=M。

f=16·(−1)−2^30·(−1)=1073741808=3M/2，所以q0=RNE(1.5)=2。真实sqrtK>M，真实距离略小于1.5，最终q=1。D18的低界为9K，而4f²=9M²<9K，必须实际选−1；修正后上下资格成立。

### 加1

nx=860054527、ny=41448、rho_Q4=−2、P=(0,4)。令M=860054528，则ny²=1717936704，K=(M−1)²+ny²=M²−2172351。0<2172351<M−1/4，故M−1/2<sqrtK<M，RNE sqrtK=M；normal域/K守卫成立。

f=16·41448·4+2^31=2150136320=5M/2，所以q0=RNE(2.5)=2。真实距离略大于2.5而小于3.5，最终q=3。D22高界25K，4f²=25M²>25K，必须实际选+1，再过最终两界。这是q0近似除法的平值；不推翻真实几何距离半整数不可达证明。

未来FT-T05逐位核q/K/M，另外记录真实q0、修正方向及最终资格，以合法主输入触发两条修正分支。手推不填写仿真PASS。

## 4. probe真实输入草图

采用一份384位非零源LFSR，reset seed=1；只在实际外部req_fire更新，feedback=383 XOR382 XOR380 XOR377，左移一位。不声明最大周期。sequence64也只在req_fire推进，MAX可接一次后exhausted置位/不回绕；必须消费/序列化最后结果后停发。

固定外部W1920/H1080/version1/owner0，NUM_ID低到高epoch1/frame0/config1/owner0/seq64/destination8=kind。sequence[2:0]按11/12/13/14/15/17/18/14轮换；[3]=0用明确成功构造，[3]=1用完整typed字段扰动。两个profile每16笔均覆盖七kind；这是数值probe模式，不是两类图像识别质量集。

SOURCE_EMPTY用旧LFSR/seq形成并锁完整622请求；SOURCE_OFFER全文保持到req_fire，再进入WAIT。真实rsp_fire锁585位shift；从bit584到0每沿一位送CRC32，poly04C11DB7/初FFFFFFFF。原响应末位已实际观察才下个请求。LED0在真实消费请求的call_seq低10位=1023时翻转；LED1是CRC低bit。不能用已增加的next_sequence代替旧request ID计算LED事件。无业务cancel端口，KEY共同reset，由TB核数值核的cancel。

图内point合法化：旧LFSR bits10:0为xraw，≥1920减1920；bits21:11为yraw，≥1080减1080，均原u11扩u12比较/减法后核域。normal扰动用30位幅值及独立符号，允许0但不静默增加K，格式合法而不变量错误由核返回。raw统计n21若>N减N，低于本kind最低支持则置最低值，阈值/其余字段按payload原宽；这是明确source映射，不修改DUT守卫。

| kind | profile0：从旧源构造的正常输入 | profile1：扰动输入 |
|---|---|---|
| 11/17 | n3；g=1+bits4:0，xc=1+bits14:5，yc=1+bits23:15；A=C=2g²、B=g²、D=g²(2xc+yc)、F=g²(xc+2yc)，11 det_min0 | 按主卡payload有效宽取旧LFSR低位，覆盖A/C43、B44、D/F56，n合法化；11阈值16仍动态，padding0 |
| 12/18 | n2、Sx=Sy=0；a=2·bits5:0+1、b_abs=2·bits11:6+1，bit12选b符号；Sxx=2a²、Syy=2b²、Sxy=2ab，12 anis_min0 | 同主卡TLS字段截取有效位后n合法化，Sx/Sy33、Sxx/Syy43、Sxy44与阈值16全部动态，padding0；未保证PSD，独立参考应分类 |
| 13 | (nx0,ny0)=(2^30,0)，rho0=16x；(nx1,ny1)=(0,2^30)，rho1=16y | 两法线分别30位幅值/独立符号与rho18；零/小K保留，按原错误规则；normal不要求canonical |
| 14两slot | (nx,ny)=(2^30,0)，rho=16·bits31:22（0…1023），图内P=(x,y)；slot3/7同key保证第一组miss后hit | 两30位幅值/符号、rho18动态，图内point合法化，保留零/K不足反例 |
| 15 | A=(16ax,16y)，B=(16(ax+1),16y)，ax=x但x1919时取1918；P来自另两u11源段并同样合法化。边非零且端点合法 | 四signed18端点取旧源不同段，图内P同合法化；端点图外允许、K0由核分类 |

profile0 LS可视为三个非零法线支撑：(xc,0)、(0,yc)、(xc,yc)，法线(g,0)/(0,g)/(g,g)，全部图内；其中心=(16xc,16yc)、quality49151。TLS对应中心坐标X2/Y2为(a,b)、(−a,−b)的两图内点，a/b奇数使绝对x/y为整数，rank-one PSD且anis65535，完整rho/μ需参考重算。probe不是摄像头帧，也不证明目标识别性能。

source构造乘法先按实际正数域扩位：g6/g²u12；2xc+yc及xc+2yc先u13，D/F完整u25再扩s56；a/b_abs u8，b符号s9，平方/2倍先u17，Sxy先s19再扩s44。不对原字段组使用整个400位signed cast。组合构造由旧LFSR到request_slot写入，本批预算probe DSP≤额外15，整独立工程DSP≤16（此前≤8只含尚未具体化source的候选，未批准）；不藏新参数寄存器/大数组。FF容器总10782不变，实际工具仍测。

profile1具体位段默认按各payload从bit0累积取同位置LFSR位，n覆盖后余字段不挪；13/14的nx/ny对应字段低30位为幅值、字段最高bit选符号，未用位不作随机隐式数据；rho/point/finite保持主卡段位置。P另源11位段是bits42:32与53:43。所有映射在reference独立audit中按文字核真实request，不用DUT生成器生成期望请求。

至少正常1024+joint reset后32，共1056笔source/request/response/CRC逐位审核。应覆盖全部七kind/profile、正常VALUE/原原因及真实cache miss/hit；如seed实际未到某错误分支，计NOT_OBSERVED并由定向core TB补齐，不能把1056等于任意全域覆盖。STA要确认真实source→request、typed各工作槽、桥缓存、child运算、cache→距离→响应→CRC路径，不以LED翻转代替数值证据。

## 5. 文字测试计划与确定种子

所有测试只计划，实际清单计数/重复/覆盖在获批生成manifest后核，不预填PASS。定向样例先执行，再固定seed；失败保留同输入，不改seed隐藏。

| TEST | 输入与观察 | 判定 |
|---|---|---|
| FT-T01 LS | n0/1/2/3/N/N+1；Δ负/0/正、条件等号/两侧、cx/cy s18边界；512独立图内唯一点集seed20261011，n3…64/G±1020非零；512宽typed统计seed20261014，A/C top42置1、B幅≤2^41、D/F s56、det_min0 | 全585逐位与首错、完整商后几何、17调用上界；源点集与synthetic分账 |
| FT-T02 TLS | 水平/竖直/斜线/u正负、PSD负/边界、trace/D0、规范反号、rho/μ完整商后域、anis门等号；512图内唯一点集seed20261012，n2…64；512宽PSD rank-one合成seed20261015：Sx/Sy0，Sxx=a²/Syy=b²/Sxy=±ab，a/b unsigned21，合法n≤N | 全normal/tangent/rho/μ/anis/K/M逐位；46调用、诊断20；不拿coarse角代TLS |
| FT-T03 诊断 | 两既有synthetic几何越域统计；17/18的padding和n/退化；各种D/F合法值而quality相同 | 只n/质量37bit有效，未调用新几何、无旧槽读取；完整拟合局部GEOM而诊断VALUE |
| FT-T04 交点 | 两normal±2^30/0/零向量、K下界两侧、den0/负/近平行、x先于y几何；2048seed20261016合法normal/rho，6×5/1080p交替 | full-width/一次RNE、原reason、两K六调用+11交点调用；17上界 |
| FT-T05 LINE | 本页两明确q0−1/+1主核输入；0/最大point、±rho、normal/K域、真实q0 RNE平值；4096seed20261017合法K法线；独立exact有理参考 | 两修正真实发生，最终资格成立；q21/K65/M33全值；miss22/hit18上界 |
| FT-T06 FINITE | Ax/Bx及Ay/By s18最负/最大；P角点、z0/K端点边界、K1短边、两N1/D2与N1/D5、零边；4096seed20261018非零随机量化边+图内点 | 原N78/D39/q19；独立19bit搜索与floor路线逐位同；B26/A24/内部25调用上界 |
| FT-T07 bridge/helper | 原child真实op0…7的0/最大/最负/混合符号/target域；REQ/RESULT stall1/7/31/257；静态MAX−1种子三次调用；isolated fake-child错ID/kind/target/矩阵/非零错误payload；helper cmp0/1/2/非法3、even/odd/q0 | 真实child与隔离故障账分离；body稳定、独立关闭、MAX不回绕第三CAPACITY；等号政策不能伪称主几何half |
| FT-T08 协议 | 11父/6桥/19child各可达状态cancel/reset，错ID、同外req/私有cmd/child req/rsp/result fire、CHECK失败同cancel、旧HELD三类结果及DROP、reset后新ID；req/rsp stall1/7/31/257 | 旧fire记账、未暴露DROP≤8、旧HELD不改、DRAIN不依外部ready；accepted=consumed+live+reset_aborted，各域单列 |
| FT-T09 cache/槽/预算 | cold miss/hit、4key/第五替换、反向normal、不同rho/x/y/W/H/job；TLS安装后LINE命中；cancel同install抑制、旧pure entry可复用、reset清valid；真实slot有效/一写及w15 anis/μ保持 | 参考不读cache；真实每槽读取均有当前资格，385高位检查后收192；逐笔调用/形成≤16384，不含HELD等待 |
| FT-T10 probe/EDA | 1056笔真实source/response/CRC；fatal退出探针；19文件同hash快照的Map/Interface/PNR/STA、实际data D路径和例外；门槛后Bit | 原日志exit0且finished/PASS及完整manifest相符；致错exit非0/无成功JSON；合理pins/25MHz/setup/hold/内部未约束0；bit/hex校验/登记后停止 |

宽随机数据集不证明所有用户复杂识别场景；原要求负样本/重叠/旋转/遮挡等完整质量集仍在整包识别验证，不能混为本数值单测。小图用于穷举/确定边界，不将生产1080p降低。

## 6. 工具、运行失败与物理检查

复用已装Python D:/py___/python.exe、现有pwsh、Questa2024.1 vlib/vmap/vlog/vopt/vsim、Efinity2026.1.132的python311/scripts/efx_run.py/bin/efx_sta.exe。未来冻结精确10个entry hash，Efinity/Questa库依赖由既有安装提供，不遍历/打印保护源码。原3RTL、原scalar工程/runner仅只读参考。

sim runner每次新RunId：reference/向量→vlib/vmap/vlog/vopt→4TB/独立audit；输出记录argv/cwd/PID/start/end/timeout/stdout/stderr/exit与hash。reference/向量900s、compile/优化各600s、helpers/bridge/core/probe每项3600s。超时仅终止本次确切进程树、不重用旧成功JSON。Questa.do设置致错/断点按finished资格真正非0，致错探针不可PASS；TB普通完成还须完整观察清单与账本闭合。

build runner先核同19文件+仿真result+vectors/source hash；顺序Map/Interface/Pnr/Sta/review gate/Bit，超时3600/3600/7200/600/1800s；STA阶段保存完整outflow/work_pnr、相关trouting与work_sta输入，不能只复制摘要导致查询缺数据库。每阶段新日志，前项失败跳过依赖；即使exit0，缺关键报告/空路径/负slack/约束错误仍FAIL。每≤30s可返回进度；不安装/下载/联网。

Ti60F225/I3、SV2009、25MHz/40ns、同4pin板卡资料：J2 clk25m=1A1.8V GCLK，P13 KEY=BR3.3V，N14/P14 LED=BR3.3V drive4。只false KEY到reset两级的各实际异步置位输入、LED板外输出；级间Q1→D2及Q2→core同步复位实际计时。无相机/DDR/HDMI pin混入本独立工程。

postroute查实际map/route数据库，按实际层次定位source_lfsr→request_slot、request_slot→parent held、held/slot→父命令→bridge→child、child full/response→bridge缓存→父slot、cache→K/M槽→距离、父结果→response_shift→CRC，以及关键子状态/control D路径。collection非空、端点为实际data D，CE/CLK/SR不能代签；每组记录真实路径/slack/例外。需要全部内部unconstrained/no_clock/multiple_clock为0，setup/hold≥0、无非法宽度/驱动/锁存；XLR≤50000、RAM0、DSP≤16且硬容量内。若综合优化某动态组到常量/空路径，审查实际来源/可达覆盖而不是扩大false_path；重新设计重要来源结构须修订批准。

若19文件与纯FF/cache路线不能满足这些独立门槛，报告实际资源/路径，先在原功能/数学范围内按规范调整或修订设计，不降1080p/完整功能/质量。不从独立核25MHz通过宣称生产视频或整机性能达标。

## 7. 双向追踪与当前缺口

FT01/07 → core/bridge/reset、IF01…06、共同旧fire/保持与本页协议 → pkg/core/bridge/原scalar/reset及两协议TB → FT-T07/08/09。

FT02/03 → LS/TLS/诊断草图与首错 → fit_core/fit_reference/fit_vectors/core TB → T01/02/03；FT04 → 交点/normal/K → 同核及独立参考 → T04；FT05/06 → 两精确距离/typed槽 → pkg/core/reference/helpers TB → T05/06/09；FT08 → 来源/消费/工具/追踪 → probe、4TB、两model、两runner、STA与三工程 → T10。

反向每份19文件均由这些数值/事务/观察/工程要求承担，无候选支撑、共享R4仲裁、字体、票表或生产存储源码。实际符号/行号、测试结果和时序证据未来实施后回填，不能由本计划提前填成实现。

本页完成F-B03的文件/来源/参考/场景/物理候选。仍需主卡/各附稿的最终数值、局部步数/宽度/取消组合审阅，以及精确输入和工具hash冻结，之后才能READY并呈现指定批准。当前不启动EDA/功能实验，不把原本地审计例外自动延伸到本批。
