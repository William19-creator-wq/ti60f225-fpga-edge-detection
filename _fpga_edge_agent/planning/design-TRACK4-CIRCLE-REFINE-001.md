# TRACK4-CIRCLE-REFINE-001 v1：完整圆候选五遍与冻结记录

2026-10-11，LOCAL_DESIGN 完成、保存后读回，由 root 呈现并限定独立候选实施；CR/CF 源码已按此范围生成，主包接入仍未执行。沿 PLAN_TEMPLATE 合并短卡。用户持续授权自主推进、整合优先、免额外中文长草图和独立测试、本地审计；不冒称用户批准了这个版号，不改正式数据库/状态、原 HDK、主 RTL/XML、当前编译或硬件。本卡保留全十一项及原完整 A6，未采用撤回的 96–768、长宽比、目标数、遮挡或噪声硬边界。

## A. 目标、实际基线与缺口

目标 CF01：实际 SEED 有效前缀依次锁中心，完整 HIST/RAW/SMOOTH 后逐一处理每个实际峰，A/B/C/D/E 五遍收敛并核验冻结圆，最多 1024 条去重 CIRC 完整写回、META 真正关闭后报告完成。单峰串行只改变共享方式，不删峰、不少遍、不降低 1080p。矩形、FINAL/ANN/标签、整包 RPC 接入、下载/观察不属于本卡已完成范围。

已读需求 T4-A6、R4 E2/E3、RECOGNITION-ALGORITHMS OP02/06、RECOGNITION-EXECUTION EX-OP02、HIST v1.1、PM v1.1、numeric-share v1.1及实际 STAT/FIT/ANGLE/POINT/DDR。真实 SHA256：

| 输入 | SHA256 |
|---|---|
| candidate circle_histogram_v1/board/rtl/board_circle_histogram.sv | 3A8F9A320E3D6E8B1C7D8455BF24FD2B5B63E9B060C682262F664BD39CE59A50 |
| candidate geometry_point_math_v1/board/rtl/board_geometry_point_math.sv | 83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21 |
| candidate geometry_numeric_share_v1/board/rtl/board_recognition_stats.sv | B6B8CF63BB3215E707395C5394A4C2ADE8D9E6783C45342BED20D3A0587700C2 |
| board/recognition_numeric/stats_core.sv | 93FCA025A54F7FD8DA04AF6D3E56CF6D37CA3C0584DF745BB12A7B587BCE9A5C |
| board/recognition_numeric/fit_core.sv | 875083D9835283FCABA45372A08BE2CF2B8056AA99F310F24DA15135565242F6 |
| board/recognition_numeric/angle_core.sv | EA8B6F8E0E22112BD2D51B40A2E746A966500B3AF6A00C0835B4C66BC3863730 |
| board/rtl/board_algorithm_rpc.sv | 14E8BAC5A362AE37D6091516569AAFB841AE5B1613C46340D0EBD6D6CDAE2E88 |

以上为设计当时读取的冻结来源，RPC 14E8…是 056 只读基线；主 057 已由 root 更新 RPC/scalar，协议未变，本候选未覆盖主文件。以上独立候选仅有代码/静态证据，无本卡整机运行证明。上述冻结主 RPC 的 sticky seed_started/dense_started 会永久选旧 stage；不能直接接 CF 或称三份候选已经闭合。

## B/C. 整体路径与最小模块划分

`SEED prefix → CF control → HIST → 每路完整峰/邻峰 → A/B/C/D/E POINT replay → CIRC exact compare/write → META → 完成`。

- MOD-CF：`board_circle_refine.sv`，计划独立候选新文件。单圆上下文、seed/route/peak 遍历、POINT 扫描、STATS token、质量/去重/DDR 写回。无第二套拟合或帧存储。
- MOD-HIST：复用实际 HIST。它仅运行一个种子；CF 回调连接同一 PM，中心 c0、tol=13107、pass=0、minimum_peak_votes=6、scope/seed/ordinal 保持。完整 done 后 CF 验证其 META，再读取实际峰前缀。
- MOD-PM：复用实际 PM v1.1，同一个实例服务 HIST 和 A–E。它不持有 DDR；CF 不以输入低 17 位替代 radius18。
- MOD-CR：计划 `board_circle_reduce.sv`，有限 micro 子模块，借同一个 scalar 做均值、SSE/极性、score、det/quality；16×128-bit 的 128-word 工作 RAM和两份 128-bit operand，完整 25-word 资格及同一返回字侧带。不是新 scalar 或大型 FF 结果副本。每次 command/response 单预约，输入/身份保持到真实关闭。局部命令格式见下文。
- STATS/FIT：借现有 lease，A/C 只用 FIT kind11。E 的 STATS START kind17 得到相同 LS263，由 CR 计算精确 det/quality；不向 FIT 发 kind17，不开启不使用的其他 FIT kind。候选 lease 当前把 ENABLE_GEOMETRY 与全 FIT 开启耦合；正式接入前需解耦，维持 LS_TLS_ONLY=1。全 FIT 成本未测，不能据此声称资源容纳。
- ANGLE：借现有 POINT angle_core 的 kind9（实际代码支持 s19 径向量及 fullbin1024/sector64），POINT 阶段 done且 angle quiet 后才换所有者。禁止第二份 ANGLE 或用梯度 theta9 代径向 sector。

此处独立 CF/CR 实现与最后物理 owner、DDR、PACK、ANGLE、RPC、结果发布接入是两个增量；本卡不授权改主工程，也不将未来接线写成已经完成。

## D. 外部接口、所有权与物理布局

IF-START：core 正沿 start&&start_ready，scope96、points21、seeds9（0…256）、point/seed/hist/raw/smooth/hist_meta/circ/circ_meta_base 各32及冻结参数。默认复制配置或明确 BORROW_SCOPE；父从接受至完成/失败实际收尾保持 scope/配置。ready 只在 IDLE/COMPLETE 且 DDR、HIST、PM、CR、STATS/FIT、ANGLE 的真实旧借用均关闭；失败锁定不重启。输出 done、fault、quarantined、drained及 circ_count11，成功后保持到下一 start。

IF-DDR/PACK：沿现有 64B native req_valid/ready、write、addr32、rsp_valid/ready、data512、error/drained；HIST/CF 排他选 stage，地址和写正文从 OFFER 到真实 drained 回复消费保持。共享 gradient_store 必须 COMPLETE；PACK 没有 ready，按 index0…7 每沿完整写入，ORDERED_PACK 忽略 index，不能跳字。WRITE 回复消费前不发下一 PACK、不换 owner。known fail 先结清接受事务；drained0 不能授新 owner或假 DONE。

IF-PM：同 PM v1.1完整 EVAL及回显，单项请求；CF 保持 scope/seed/pass/ordinal/point/center/tolerance 到 response 消费且 PM quiet，不因 PM NUM rsp 已消费就改点。HIST 所有者期间转接其 point/ordinal；CF 先消费匹配 PM 回复，再等 PM quiet，随后仅发布该 HIST 回调回应，期间不提出新 PM。PM 的半径/标志在 IDLE 到下一接受前实际保持，可借其结果，不新增大包快照；UNKNOWN 独立发布error/drained=false并隔离，不等待不存在的quiet。HIST EVAL回应一一对应且数值/预约真实 closed 才给 eval_drained=true。

IF-STATS/FIT：复用 lease 全端口。STATS context ID=`{8'hd1,context_sequence64,8'd0,scope96}`，START 至 STAT 消费并 stats quiet 保持，序号仅真实关闭后递增、冷复位才清，MAX一次后锁容量失败。每个 A/C/E 给 START、全部 E 个 POINT（include逐点资格）、END；ordinal连续0…E−1，未选点也交 token，不能用 included_count 冒 raw_seen。A/C START kind11/detmin16，E START kind17/detmin0；头部 E21/W/H/version原布局不变。

STAT632 在借用期保持：先核原 ID/kind/零位/outcome/reason/n；A/C 以低622原样借给 FIT kind11，req/body保持到 FIT rsp消费且 fit quiet；之后才 geometry_stat_ready（同时 fit_req_valid必须0），再等 stats quiet。FIT结果中心/n/quality资格检查后才保存 c1/c2/n_expected。STAT与新 FIT 借用禁止同沿释放。E 的 STAT先借 CR算完整 det/quality，CR关闭前不能消费 STAT。PM/CR/FIT 切 scalar owner必须前任自身 quiet（FIT包括private bridge的BORROW_RESULT归还）、child quiet且无新请求；只看 shared_num_quiet不够。NUM_ID owner字节始终0。

IF-CR：单预约 command_valid/ready，op3、context_id176、data[319:0]（低字段布局如下，未用高位必须零）；response_valid/ready、相同 context/op、value[95:0]、error/local_reject/drained、quiet。最多一份 borrowed command，父保持至response消费且 CR quiet。op0 MEAN：sum39/n21；op1 POINT_METRIC：dx s19/dy s19/gx s11/gy s11/residual18；value=residual_square36/polarity2/zero58，polarity0=dot零/1正/2负/3非法；op2 SCORE：support21/eligible21；op3 QUALITY：LS n21/A43/B s44/C43/D s56/F s56/zero57，value=n21/quality16/condition_ok1/zero58。op4 FINAL_GATES：support21/eligible21/SSE53/popcount7、support_min21/score_min16/coverage_min16/meanSSE_max16，其余149零；value低bit为门通过，其余零。所有全宽乘法/除法/舍入用唯一 scalar，CR scalar ID=`{8'hc2,closed_sequence64,8'd0,scope96}`，关闭/耗尽/UNKNOWN与 PM 同合同。op1 的 dot只影响极性诊断；不反向筛掉支撑。

CR编码前收束：MEAN value低17为非零合法r、其余79零；SCORE低16为score、其余80零。零均值/均值超17位、n0、eligible0及QUALITY退化/条件门失败为local_reject，非错误数值；格式、高padding、真实计数/资格越界为error。FINAL_GATES不满足时value0、error/local_reject均0，由CF按正常候选门拒绝。QUALITY的detmin固定16，与A/C冻结常量一致。CR始终先关闭真实scalar，再发布这些回复，UNKNOWN独立error/drained=false隔离。

IF-ANGLE：kind9 REQ622低payload dx s19/dy s19，其余362零，原 header/owner/version，target0；采用独立调用者标签 C3及冷复位64关闭序号。回应全 ID/kind/target/outcome/reason及高358零核验，θu10/half1/fullbin10/sector6原布局保留；真实回应消费且 angle quiet才改输入，零径不发角度请求。只借同一现有实例。

默认 DDR：POINT05000000、SEED06003000（4096B全部表）、HIST07000000（524288B）、RAW07080000（32768B）、SMOOTH07088000（32768B）、CIRC07090000（65536B）、HIST_META070A0000（64B）、CIRC_META070A0040（64B）。33-bit尾端/对齐/两两不重叠检查，≤ADDRESS_BYTES，遵守原板载资源。每峰64B低PEAK64高零；CIRC stride64低256原CIRC、随后64为 fit_support21/fit_quality16/maxres16/zero11，高192零。不读峰前缀外旧槽，不以未清的圆表旧slot当有效条目。

## E. 五遍成员、数值与质量

完整两峰表同路 radius 严格升序；当前 r0和相邻真实峰一次读齐，prev+r0/ r0+next 以u18保存；无邻关闭该侧比较。初始 P(q0)=(!prev或2q0>prev+r0)&&(!next或2q0≤r0+next)，q0保留18、2q0用19，tie小半径。只有HIST投票用17位合法半径；A–D不擅自再加q0≤131071的成员限制。

| pass | 每点资格与实际提交 | 整遍关闭后的结果 |
|---|---|---|
| A | PM(c0,13107) 得q0/normal0；P且abs(q0−r0)≤64且normal0，交 LS include | nA≥6及FIT原全宽det门，kind11→冻结c1/nA |
| B | 严格重放A原c0/r0/P/normal0；选中后再PM(c1)，只取q1，sum39/n21 | 必须n==nA，否则整帧INTERNAL；CR MEAN RNE(sum/n)→r1 |
| C | 先PM(c0)只取q0/P，再PM(c1,13107) 得q1/normal1；P且abs(q1−r1)≤64且normal1，交LS | nC≥6及FIT原det门→冻结c2/nC |
| D | 严格重放C的旧c0/P、c1/r1/normal1；选中后再PM(c2)只取q2，sum39/n21 | 必须n==nC；CR MEAN→r2 |
| E | 全E点不再P；PM(c2,6554)，eligible为abs(q2−r2)≤64；support另需≤32、normal2及q2非零 | 同一最终support累加LS、真实残差平方SSE53、maxres16、径向sector64、极性flags；geometry永不回写 |

center均s18 Q4，dx/dy s19、radius18先全宽，平均sum39/count21先扩40/22检查；r1/r2最后核1…131071再收17，域外LOCAL_REJECT计入诊断/FN，不裁剪或改变输入场景。support/eligible21先扩22，SSE53先扩54，支持残差≤32但计算平方先保u36；normal沿PM精确cross²式，等号通过。

E support≥6、eligible>0、65535support≥32768eligible、65535popcount(mask)≥2047×64、SSE≤256support。CR QUALITY由冻结support的LS计算T=A+C u44、Δ=AC−B²全宽signed89先核>0，再4Δ规范u88、T²u88，精确门 `65535·4Δ≥16·T²`（最多104位）；quality=RNE(65535·4Δ/T²)先完整资格再收u16，n必须等support。零trace/退化局部拒绝，不造质量0成功。这里与kind17原诊断数学等价，不使用舍入quality代原条件门，不再拟合c3。

score=RNE(65535support/eligible)仅排序/显示，与精确门分开。sector使用s19径向的原kind9量化，fullbin=(θu+512half) mod1024后sector=fullbin>>4，保留θu512的进位。混合正/负dot只flags，不删圆。中心图外按s18中心与[0,16(W−1)]/[0,16(H−1)]判；bbox跨图用先扩s20的cx±r/cy±r，不饱和坐标。

## F. 扫描、记录和异常闭合

1. START核输入/区间，circle_count和有效前缀清0；SEED每64B含四128记录，读真实有效前缀，valid/zero/domain/rank顺序核验，解除bias后锁c0。每selected seed都跑完整HIST；同中心可重复计算，不靠未经实现的隐形缓存省掉候选。
2. HIST done且PM/NUM/DDR真实closed后核匹配scope/seed/E/counts/META，再依RAW后SMOOTH、各index升序读取当前/前/后峰。同位置高padding零、相邻升序/count合法；保存固定P边界，五遍内不改峰表。
3. 每遍读ceil(E/8)个POINT块。借原512位reply，以lane0…7的64位点交PM/STATS/ANGLE/CR；这些步骤不发DDR，因此无等待第二DDR请求的环。该点全部借用已归还才能推进lane，最后点关闭后核尾padding全零并消费Rreply；不复制512FF，不在持POINT读回复时读峰/seed/旧CIRC或写记录。每遍重置raw ordinal/rowmajor资格。
4. A/C/E逐点TOKEN接受与对应PM资格一致；最后真实POINT回复关闭后END。B/D全部sum/n完成后CR均值。中心或半径结果关闭的下一状态才换pass，不用同沿新geometry改变旧成员。LOCAL_REJECT仅当前峰，结清STAT/FIT/CR/PM及DDR后继续下一峰。
5. E完整冻结指标通过后，逐读已写CIRC[0…count−1]，比较精确(cx,cy,r)。重复几何的support/eligible/SSE/sector/score/fit_support/fit_quality/maxres/极性必须相同，否则INVARIANT整帧失败；重复保留先到seed诊断，不二写。新key在count==1024时报CAPACITY，不能丢弃成功；否则按八字PACK完整CIRC64B，成功drained WRITE回复消费后才count++。
6. 全seed、两路所有实际峰与旧回复/数值/角度关闭后，PACK完整CIRC_META并等写回复，释放geometry lease的真实握手及全部quiet后才DONE。META低到高scope96/E21/seeds9/count11/raw_visited19/smooth_visited19/local_reject32/duplicates32/PM_calls64/complete1/layout8=2/zero200；记录是有效前缀，不发布半成品。
7. 已知失败停新业务；若STATS在RUN，保持context发送ABORT_SCAN，等旧点运算token_ready再关闭STAT；不得用局部reset清借用。真实已接受NUM/FIT/ANGLE/DDR先收回并等quiet/drained，随后才known-fail/drained=true。异ID/非法排空锁quarantine、drained=false，不消费他人回复或强清owner；父cold reset之前所有借用来源保持，不能假失败已排空。无本地暖取消或超时伪关闭。

## G. 性能/资源代价与必须公开的限制

令S≤256、各seed两路总峰P_s≤1024、E≤2073600、V_s≤E为HIST票。每seed HIST 131072 bin clear+scan，对应8192次64B clear写、8192次scan读、E次PM、V_s次HIST读+写，另峰和META写。每实际未提前reject峰最多5ceil(E/8)次POINT块读，A/B/C/D/E最多(1+2+2+3+1)E=9E次PM；E支持点另角度/metric，整遍STATS/FIT/CR与dedup≤1024旧圆读另计。总PM上界 `Σ_s E·(1+9P_s)`；每PM普通非零径最大18条scalar指令，不是18个core沿。

设计读取的056 scalar_core_words每条先INITIALIZE全部256word，sqrt另有96位根循环、mul/div及内部读/资格/assembly循环；PM再需操作数同步读、25字资格、8字提交、借用关闭。因此该旧基线只18×256初始化就≥4608沿/非零点；在E=N和一个候选确实执行五全遍时，仅每遍至少一次PM的初始化预算约525.5秒，最多9次PM对应约946.0秒，按90.909MHz计算，尚未含真正算术、DDR和额外服务。此为旧基线恶劣全EDGE计算预算，非主057优化后的实测典型延迟；提前拒绝/稀疏E会少很多，但当前共享路线不能宣称流畅或实时。用户曾否决160×120/1FPS，本卡不通过降低图像或隐瞒数分钟代价绕过原意。后续性能优化必须保留数学/候选范围，且需实际编译/资源证据。

结构估计：复用HIST的3 RAM和PM的1 RAM、CR增加1 RAM及2×128 operand，CF借物理reply不加POINT块RAM或512FF；单圆上下文/指标/控制为有限FF。ANGLE/FIT/STATS实体复用，保留LS_TLS_ONLY=1。主包056 physical61197已超Ti60容量397的已知事实，新增逻辑不能承诺装下；这不是设计/资源闭合通过，不能用同一scalar数量掩盖新增mux/FSM/FF成本。

## H/I. 最小可编码边界、追踪与下一步

实施顺序：CR四类数学及GATES固定micro/借用接口 → CF完整单峰A–E/错误关闭 → 完整seed/HIST/峰和去重CIRC/META，以上独立候选源码已生成并定向静态读回；父owner与整机接入尚未执行。最小边界是两份独立candidate CF/CR，不在本轮临时启用主geometry或全FIT。HIST/PM使用已列实际接口；STAT/FIT/ANGLE物理接入仍是后续增量，不能只写stub就称完整。

文字走查（非测试、未执行）：E0完整HIST/零峰/空CIRC META；单峰A/C中心改变，B/D重放成员数必须原值；最邻峰中点tie、q0大于17位域不回绕；E脱离P并冻结geometry；RAW/SMOOTH形成同圆精确合并、指标不等触发INVARIANT；第1025圆容量、背压、TOKEN/FIT和STAT同沿禁止释放、PM耗尽/UNKNOWN、末块padding。

CF01全范围→HIST/峰遍历；CF02五遍冻结→PM/STATS/FIT/CR；CF03精确质量/sector→CR/ANGLE；CF04真实写回与去重→DDR/PACK/META；CF05借用/失败关闭→stage/数值/STAT quiet。反向每个计划模块和状态只承担这些要求。没有新质量测试、TB或EDA；静态设计不是运行证明、质量达标或实物效果。

局部歧义已作最小决定：单峰串行替代旧16峰并行但遍历集合相同；原HIST最新DDR全域替代旧tile临时池；最终诊断由同scalar的CR等价实现以保留最小FIT；CIRC采用64B物理stride和显式附加诊断，不冒旧32B解析相容；新META与HIST META分开。需root核读这些边界，保存/readback后呈现，再限定candidate编码。整包引脚/时序、FPGA容量/速度、最终识别质量、矩形/标注和实物观察仍未完成。

实现记录：仅 candidates/circle_refine_v1/board/rtl 下 CR/CF 两文件。CR 五op、全宽RNE与比较、25-word资格、C2冷复位关闭序号及UNKNOWN；root已全文定向读回通过。CF 完整seed/HIST/两路邻峰/五遍/质量与径向ANGLE/精确去重/CIRC及META，保留旧 PM v1接口；NUM/ANGLE/geometry 三种真实owner输出与 quiet 收尾，STAT/FIT借用不提前消费，失败STAT也完整匹配ID。几何quiet在lease未绑定时为0，因此START使用现有 geometry_bind_ready 的真实旧服务闭合条件。已知STATS故障不等待失效token_ready，转ABORT或既有STAT关闭；无新测试、TB、EDA或硬件步骤。源/依赖hash及待接项保存在本候选 change-record.md，不将这份源码称为整机 A6 完成。
