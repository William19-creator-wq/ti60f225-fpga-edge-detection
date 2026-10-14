# TRACK4-CIRCLE-PARENT-INTEGRATION-001 v1：圆候选实际父接入

2026-10-11，LOCAL_DESIGN，保存/读回后供root呈现，尚未生成本卡业务源码/XML。沿PLAN_TEMPLATE合并短卡；依据用户持续自主、本地审计、免额外长草图/TB授权，不冒称版号获批。仅计划独立 `candidates/circle_parent_integration_v1`；主058、运行构建、原HDK、正式状态、硬件不改。原1080p场景及192/385位数值精度不降，不接RECT、FINAL/ANN/标签。

## A. 目标、基线与边界

CP01：现有 Canny→GRAD→POINT→STATS/FIT→ANCHOR→SEED→DENSE/LINE 真实完成后，实际运行CF完整HIST/两路峰/圆五遍与CIRC/META；再释放所有服务并交原RPC终态。卡/候选接线完成不等于整机可运行或A6全功能完成。

| 已实际读取的来源（work/active/track4_board_first_20261011下） | SHA256 |
|---|---|
| board/rtl/board_algorithm_rpc.sv（058） | 7F4B21CE09F81FBF2236E54000748B32FD522F889AD4997860292B3E5544EE93 |
| board/rtl/board_recognition_points.sv | 686C4B19D4D8216A6B8F04EA8BBA259FF74B255D3275E4C9A09C60BD2B7C03FF |
| algorithm/rtl/frame_actors_axi.sv | C5B13D0D7DD8B0E4BFC9BBA9F77E3CD6213CAE6E610CDD53ED9419610EC0024C |
| board/rtl/board_frame_system.sv | 4A6EC6749C0E803540E2A1EA455A17AB8FBE9BCF9FB12342A33ABE903D49FF6E |
| track4_board.xml（与058 flow副本一致） | 8D3CE422C634ECB427107C52FAF49DA83444DECDD9FD5FAC3B78FB2F12B81BDD |
| scalar_core_words.sv（058，仅复用） | 6266734BEDD5CD1439355CC2153AE4B3FB0630079CADF9097433D9A0F89E4037 |
| geometry_numeric_share_merged_v1_2/board/rtl/board_recognition_stats.sv | 14228BE6277F5CDC5989D1D002D62C4590514E941BDEF5D55530D76527835A22 |
| circle_refine_radius_only_v1/board/rtl/board_circle_refine.sv | 0AC562695ECA432200EC74825D71C093F0D4753AA43A7ACFFFF765D8EFEF7EA4 |
| circle_refine_v1/board/rtl/board_circle_reduce.sv | 9785CCF94B22BC0898B32B80E36B20BD2FAAB262DEBF547FFAB7D71DEFC17D03 |
| geometry_radius_only_v1/board/rtl/board_geometry_point_math.sv | CC4BF36A1E51325948F12640379346865C48EC5F8778D3C4AAD7209504E64C05 |
| circle_histogram_v1/board/rtl/board_circle_histogram.sv | 3A8F9A320E3D6E8B1C7D8455BF24FD2B5B63E9B060C682262F664BD39CE59A50 |

实际缺口：058以sticky seed_started选NUM、dense_started选DDR/PACK，CF不能仅追加实例；POINT内私有angle_core必须借同一实体；几何quiet在未绑定时为0；默认参数0和XML增源本身不会启用功能。root已确认实际使能链见D。058布局初始physical60351/60800为已报告进度，PNR尚在跑，不是本新增圆链容量证明。

## B. 模块与真正共享接口

CP02-ANGLE：POINT追加默认0的 `ENABLE_ANGLE_LEASE`，及 input owner_request、output owner_granted、外部req_valid/ready/body622、rsp_valid/ready/body585、真实quiet。新增端口放末尾，原顺序保留。只在POINT **COMPLETE且无fault**、原angle_core quiet、无旧角度回复/请求时授予CF；IDLE不授。owned期间POINT start_ready为0，内部POINT角度valid/ready隔离，外部req/rsp握手送原 `angle_core(.BORROW_REQUEST(1))`，正文直接借用，不复制622FF、不加第二角度核。quiet原样广播给CF，不能按owned/valid门掉，否则START死锁。owner_request撤销后，必须angle quiet、无外部新req、无held rsp才清owner_granted；未知回复不强制释放。参数0时owner常量0，原POINT行为与未连接新输入相容。

CP03-GEOMETRY：使用merged_v1_2唯一STATS/FIT，显式 `ENABLE_GEOMETRY=1,GEOMETRY_FULL_FIT=0`，因此LS_TLS_ONLY保持1；A/C只提交FIT11，E的STATS17由CR等价计算。CF全套bind/release、TOKEN262/STAT632、FIT622/585、cancel及quiet/fault接真实端口。START先看 **geometry_bind_ready/旧stats_start_ready** 的实际旧STATS/FIT/shared闭合，不能等未绑定的geometry_quiet。STAT/TOKEN ID保持到借FIT/CR真关闭和STAT消费后quiet；不同时接受新FIT与关闭STAT。

CP04-NUM：一个scalar_core_words，物理owner寄存器为NONE/FIT/SEED/CF_PM/CF_CR，与NUM_ID内部owner8=0分开。旧STATS和CF/FIT均接原fit_num_body；仅CF/PM、CF/CR走第三direct CF正文，不能circle_started后把所有FIT请求误送CF。CF的role0/1/2/3请求映射到NONE/CF_PM/CF_CR/FIT，granted回显实际owner，不能只回显请求。CF自身在PM/CR quiet后才改变role，FIT还必须自身quiet（含private bridge BORROW_RESULT归还），父只在shared scalar quiet、旧source无请求且FIT实际关闭后换owner。未绑定时用旧stats_start_ready/bind_ready证明FIT关闭，绑定时用geometry_fit_quiet；不拿unbound geometry_quiet=0阻塞handoff。

NUM顺序：job接受后FIT → 完整stats/anchor关闭后SEED（先实际owner到位，再发seed_start） → seed_done且scalar quiet退NONE；DENSE不占scalar → CF所请求PM/CR/FIT单项分时 → NONE。CF source正文、initializer字和B零侧带都按**实际owner**选择，并保持到真实旧borrow归还；不能按req_valid/rsp_valid或scalarquiet临时清零。058的固定16bit输入选择扩成FIT/SEED/CF三源72个合法字位置，index12…15仍零，避免先选384bit再动态切片。返回index5按FIT/SEED/CF实际owner选，FIT num_rsp_valid消失后BORROW_RESULT期间仍保留；同一16bit返回侧带广播，idx24保留bit384，高15位按各消费者原符号扩展，完整585/385/25字资格不变。REQ/RESP的valid/ready/cancel只送实际owner；CF direct无暖取消。

CP05-DDR/PACK：新增最高优先的circle_started阶段，**CF start接受沿之后**直到本job终态消费只选CF（它内部已复用HIST）。梯度存储必须COMPLETE且gradient_drained真；stage切换时不存在旧native OFFER/REPLY、未消费回复或PACK写事务。req/ready、rsp/ready、write/addr和pack_valid/index/data成套选CF，旧dense/seed sticky不再抢CF。原64B physical reply继续借用，数据广播，无512FF新快照。ORDERED_PACK按0…7每沿八字，最后字写完的下一状态才发write，真实drained WRITE回复消费前不换stage、不重写PACK；原flat写源路径和arbiter仍唯一。

## C. 启动、关闭与失败顺序

1. 旧job_fire锁模式/scope/config，新增circle_started清0；所有默认0路径保留058原选择与完成条件。启用仅 `!sobel && job_cj[141]` 的原识别作业，Sobel/其它显示作业不等待CF。
2. POINT完整表及全部尾padding/写reply完成；完整stats/FIT与anchor导出关闭；SEED全表/META完成且scalar quiet；DENSE全512角/NMS/LINE/META真正完成且gradient_drained、无旧req/rsp。NUM退NONE，POINT angle未被借且quiet，geometry_bind_ready证明旧服务closed；此时且仅此时提出CF start。scope=c_done_scope、points=point_count、seeds=seed_count，八base沿CF原卡固定区域与地址33bit边界，不增加scene admission限制。
3. CF设置 `BORROW_SCOPE=1,SHARED_RETURN_WORDS=1,ENABLE_RADIUS_ONLY=1`，依赖CC4…新版PM。CF接受后先借geometry，再请求POINT angle owner，得到实际ack才开始；根NUM响应CF role。整个Canny原done保持，不消费、不换scope，直到CF真实终态收尾。
4. 正常CF done只在CIRC_META写回、几何lease释放、NUM实际NONE和ANGLE实际未借用后成立。父完成barrier另核CF drained、gradient_drained/shared scalar quiet以及实际owner都已归还，才允许原done_valid/done_ready和busy释放；count0/seed0也是完整META成功，不跳过关闭。
5. CF known fault不要求cf_done（FAILED态不会done）：仅 `fault && drained && !quarantined`、DDR真closed、NUM NONE、ANGLE未借、geometry归还后提交outcome1/reason `32'h80000040`。不能因fault立即交失败，也不因known fault伪称UNKNOWN；其它058原错误原因顺序保留。CF失败锁定，下一作业不能绕ready重新启动，需共同冷复位。
6. CF UNKNOWN、memory/RPC隔离或异ID不能生成终态、DONE或释放borrow；生产者local_quarantine传播并阻止新job，保持原scope/正文/owner至共同冷复位。没有超时假drain。CF启动之后没有新局部取消接口：外cancel仍遵循原Canny DONE冻结规则，本批后处理会真实关闭后交终态，不承诺即时停止。复位只用现有同步core rst；不新增CDC或硬件步骤。

CF的最终记录仍是64B CIRC有效前缀与META原卡布局。此批没有把这些记录送最终ANN/HDMI；board_shape_tracker现有显示仍是其原近似框，不能把它的实物画面冒称新完整圆识别结果。

## D. 独立候选、XML与使能入口

计划九份RTL：新增父适配RPC、POINT lease、frame_actors_axi传参、board_frame_system使能四份，及复制已冻结STATS/HIST/PM/CR/CF五份；六个业务依赖为POINT/STATS/HIST/PM/CR/CF，另RPC/actors/system三份。before保留四个实际058适配输入，复制依赖保持原hash，禁止重复同名module。

- RPC和frame_actors_axi均追加 `ENABLE_CIRCLE_REFINE=0`；actors把它显式传RPC。候选board_frame_system唯一actors实例显式1，与现有FLAT/BORROW/EXCLUSIVE参数同一实例，其冻结/写源代码逐字保留；其它工程默认0仍是旧流程。
- 候选XML保留058原127个design_file，替换RPC/POINT/STATS/actors/system五项路径并新增HIST/PM/CR/CF四项，计131项；packages、唯一scalar/FIT/STATS/ANGLE、队列RAM、原初始化mem全部沿冻结输入清单。主XML、top、Ti60F225/I3、peri、SDC/引脚和时钟不变。独立project/flow保持原相对资产布局，不能只复制XML造成mem/include失联。源码/输入清单与before/after hash另保存本地change-record，正式DB状态不改。
- 尚未主采用的display_append_v1对system仅显示实例FIXED_APPEND=1，和本卡actors参数是两个局部，未来显式合并不覆盖其新display源码；scalar_root_narrow_v1对RPC唯一scalar追加ROOT_NARROW_WORDS=1并配新core，未来同样只合并指定局部。当前卡仍以058实际为基线，不能冒未采用候选已构成059或覆盖正在编译的058。

## E. 读回计划、追踪与停止点

只计划非执行文字走查：default0全旧流程；首个NUM FIT→SEED、CF PM→CR→FIT→NONE及FIT借回结果期间rsp_valid0；POINT角度回复背压/CF角度借用/下一job；dense最后写回复与CF start不能同沿偷owner；最后CIRC/META write及known失败真关闭；UNKNOWN持body；E0/seed0；各子阶段半径-only四位不影响原成员。实施后先实际完整源/差异读回，再由root限定独立整机EDA，不新增TB/测试脚本。

CP01→RPC/barrier；CP02→POINT单ANGLE lease；CP03→STATS/FIT lease；CP04→实际NUM owner和双word侧带；CP05→唯一DDR/PACK切stage；实际使能→actors/system/XML。反向九源都只承担这些接线或原完整圆算法。card保存/读回/呈现后再限定实现，不提前生成源码/XML。

资源/速度仍未知：沿一scalar/一ANGLE/一FIT/STATS，但新CF/CR/HIST/PM与mux/FSM会增面积，058初始449余量不能保证容纳。本卡不开全FIT，不删峰/五遍或降分辨率换资源；先闭合源码接线后仍需真实综合、布局布线/时序和实物效果。完整A6还缺矩形、最终分类/标签/annotation/发布及对应质量，不能将本父接入称全部完成。
