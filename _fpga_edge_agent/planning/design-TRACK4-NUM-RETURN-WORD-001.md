# TRACK4-NUM-RETURN-WORD-001 v1.1：共享 NUM 返回逐字选择

2026-10-11。独立 candidate 短变更卡；采用 PLAN_TEMPLATE 小修复格式。保留生成前契约；候选五份代码已采用到独立主work，055词法失败保留，v1.1修正后056正在编译，资源及路由结果未出。

- Goal / 当前缺口：054 报告物理容量 61196/60800，超出396。共享 scalar 已有唯一385位返回，但 FIT 和 SEED 各做动态逐字选择，SEED 写工作RAM另做低128位选择。本次只合并这三处选择，不改变运算、精度、FSM、握手、取消或全部资格检查。
- 需求 REQ01：同一 owner 的全部385位资格遍历、低字段、符号、比较及零值检查逐位等价。REQ02：共享一棵正文到16位选择树，新增仅组合侧带，不新增FF/RAM/DSP或数值实例。REQ03：默认关闭保持泛用旧接口行为，独立候选不混入 geometry_numeric_share。
- v1.1实测修复：055于13:49:21.8579527 UTC在词法/语法分析失败，RPC第238行的5'd25紧接问号被解析成非法十进制字面量。本修订仅在该数字前后的比较/三元运算符加入分隔空格；所有位宽、表达式值、端口、状态和周期不变。055冻结输入及错误日志保留，056采用修正后的主work和candidate一行；未出现面积/布线结果，不能沿用静态PASS声称055综合通过。
- Authority：引用用户明确自主继续、无需反复批准及免新增长草图/独立TB授权，由 ROOT 组织呈现和独立candidate实施；不伪称用户批准了新的指定版号，不修改正式数据库/硬件状态。当前主板及054冻结输入不变。

## 基线、范围与阅读顺序

以下SHA256为本轮实际主work读回，路径相对 work/active/track4_board_first_20261011。实施拟仅复制并修改前五份，scalar_core_words 只读；不改变共享 scalar 的运算或存储。

| 文件 | SHA256 | 本次职责 |
|---|---|---|
| board/rtl/board_algorithm_rpc.sv | E6D9A67BAE455477822FB2332829E76700A2FB5F3AD31AC10D56357BFDE626BF | 中央选择5位字索引和唯一16位返回，实际消费者开启侧带 |
| board/rtl/board_recognition_stats.sv | F82C3E93CB3F191E91980EE70BDF8D28784F39E85DD9380FE9E8FC2620166128 | 原两遍wrapper只透传FIT侧带，不增加ENABLE_GEOMETRY |
| board/recognition_numeric/fit_core.sv | 50FA87C0036FF838B79C89D535F521F9F6CD4E40CFF9F60358281A2DA91A25EE | return_word经bridge向上送，return_piece采用共享字 |
| board/recognition_numeric/scalar_bridge.sv | CA1392F51BAC22768B31D7599E8E729017F822DBE13DE01CA9590890DE757DC5 | 借用结果的字索引透传、非VALUE按原规则返回零 |
| board/rtl/board_circle_seeds.sv | C45B239B359388FE934DE4EA4BCD1A8EDC58CA9BFB78F544BB06C3FC122ED71D | 扫描/工作RAM写两阶段共用中央返回字 |
| board/recognition_numeric/scalar_core_words.sv（只读） | 1568D08773306D8F56C35E77E399502D4BEADA46D15234D537DFF30BBA7DA4E4 | 保留完整rsp585和结果银行生命周期 |

原址证据：FIT return_piece 在 fit_core:867，SAVE_RETURN 写字在:917；SEED result_piece 在 board_circle_seeds:152，response_write_word 在:117。原 scalar 返回正文在 scalar_core_words:77，FIT bridge BORROW_RESULT 在 scalar_bridge:21–24。

## 整体连接与接口 IF01

数据：唯一 scalar rsp585 → RPC中央385位正文到16位选择 → 广播 word16 → SEED 或 STATS wrapper → FIT → private bridge → FIT return_piece。

索引：FIT return_word → private bridge → FIT external scalar口 → STATS wrapper → RPC；或 SEED scan_word/word → RPC。RPC仍用当前实际 seed_started 锁定 owner，且不改变原 owner 切换事件。

| 接口/参数 | 方向、位宽、规则 |
|---|---|
| STATS/FIT 新参数 SHARED_RETURN_WORDS | bit，默认0；实际板端实例为1，FIT要求EXTERNAL_SCALAR=1 |
| STATS/FIT shared_rsp_word_index | 输出unsigned5；由FIT原return_word提供，无新增游标 |
| STATS/FIT shared_rsp_word16 | 输入unsigned16；同一中央选择的组合返回 |
| bridge 新参数 CHILD_RETURN_WORDS | bit，默认0；实际private bridge为1，要求BORROW_RESULT=1 |
| bridge result_word_index / result_word16 | FIT输入5 / bridge输出16；索引原样透传，非VALUE结果输出0 |
| bridge child_rsp_word_index / child_rsp_word16 | bridge输出5 / 中央返回输入16；不增加ready/valid或接受事件 |
| SEED 新参数 SHARED_RETURN_WORDS | bit，默认0 |
| SEED num_rsp_word_index / num_rsp_word16 | 输出5 / 输入16；NUM_SCAN用scan_word，REG_WRITE用零扩展word，其他状态可用0 |

默认参数0时FIT/SEED保留原动态切片表达式；bridge新侧带关闭，未连接的新输入不能进入旧路径。BORROW_RESULT=0的默认缓存正文仍按原完整result_body索引，不启用外借字侧带。实际开启不改变原REQ622/RSP585或ID176，原完整正文仍广播，原valid/ready/cancel/quiet保持。

## 数值和时间契约 IF02

- RPC先选择 owner 的5位index，再仅从 shared_num_rsp_body[584:200] 作一次选择。index0…23返回原连续16位；index24返回高15位0、低1位原bit384；index25…31返回0。绝不依结果signed在中央替不同消费者决定扩展。
- FIT在index24按原 return_extension 补高15位；SEED按原 result_extension 补高15位。其余字不改。SCAN_RETURN原24→0共25字、SEED原0→24共25字、SAVE_RETURN原0→11和REG_WRITE原0→7周期完全不变。
- SEED的 modulo64 且 word≥4 仍写0。低2/17/18/19/23/64位、bit384及FIT的完整385位compare/合法零值、低192位目的槽和全部typed资格检查继续使用原完整正文，不删除或代换为前缀检查。FIT local_piece 的192位选择不属于本次范围。
- bridge必须按原result_metadata[9:8]==VALUE对raw16门控，非VALUE返回0，与现有BORROW_RESULT完整正文为0的规则相同。逐项核对CMD_CHECK的abort/exhausted、WAIT_CHILD的identity/matrix INTERNAL及CHILD_CLOSE的abort：它们可能使bridge正文0而child仍保存旧成功full，不能无条件透传raw16。启用侧带仅适用于BORROW_RESULT=1路径。
- 侧带是组合观察，没有新接受/交付事件或存储。消费者改变原游标后，组合字对应新游标，下一原采样沿使用；不增加读延迟、等待状态或流水寄存器。
- 关键借用：bridge先消费child rsp，等待child quiet，之后RESULT_HELD仍借用full385。中央word16不能门控 shared_num_rsp_valid 或 shared_num_quiet；这时child valid已0，但返回字仍须可读。按原契约，结果银行保持到下一req，而父级必须在FIT/bridge真实关闭及outer quiet后才允许下一数值调用/owner切换。
- 原RST共同同步复位和所有原valid禁用不变；不新增CDC、时钟、引脚或配置事务。body、ID、低字段与字侧带始终取同一共享结果，不能另建第二正文选择或快照。

## 局部操作与组合检查

1. 原FIT需要资格/保存字时，发布原return_word，private bridge原样向中央提供索引；用元数据确定是否返回VALUE字，原FIT补index24符号后沿原周期检查/写槽。
2. SEED原NUM_SCAN逐字检查全部385位；进入REG_WRITE后仅改变索引来源为原word，保留原模64零写及低字段提交。
3. RPC对两者只选择5位索引，word16广播；未选owner的请求/响应valid仍由原控制关闭，不给它新的消费资格。原FIT完全quiet之后seed_start才改变seed_started，所以借用期索引路径不会被SEED抢走。
4. 原误响应、FRAME_FAIL、CANCEL_DROP仍由完整585位路径判断，侧带不提前关闭、删除检查或改错误优先级。full385对应的所有25字均参与原检查。

局部无未决协议阻塞；资源收益是待测问题。结构上可消除两棵385→16独立选择及一棵128→16选择之间的重复，改为中央一棵和5位索引选择。扁平综合可能已经共享部分，也可能因重布线产生开销，不能保证省396或路由成功。新增组合结构没有新增存储/算术宏，但最终工具资源以055报告为准。

## 实施、验证、追踪与回退

- Milestones：短卡读回/呈现 → ROOT指定独立候选实施前五文件 → 定向静态核对 → 055实际综合/布局布线/时序。不得改054冻结输入、主板、原资料、脚本、几何候选或scalar算法。
- Validation：仅静态走查默认关闭、index0/11/23/24/非法25、负值符号补、FIT child已quiet但bridge仍RESULT_HELD、25字全检查、模64零写及取消/错误归零；不新增TB或独立执行测试。055实际容量/路由/STA由ROOT登记，当前未运行。
- 双向追踪：REQ01→IF02全部385位/符号/低字段→FIT return_piece/SAVE_RETURN与SEED result_piece/response_write_word；REQ02→IF01中央5位索引/16位返回→RPC、wrapper、bridge透传；REQ03→三个默认关闭参数及旧表达式→独立candidate/默认路径静态读回。每项均以最终源码和055实际报告更新，不能把设计检查当工具通过。
- Rollback：仅独立候选五份副本，可放弃候选或关闭侧带参数恢复原表达式；主板基线与054产物保留。与几何候选的后续合并另做小差异核对，不在本次加入ENABLE_GEOMETRY。
- Completion：ROOT定向静态复核通过后，可以将五份候选临时采用到独立主work，以冻结055输入进行真实整机测量；保留原五份副本/哈希及回退位置。055容量、路由和最终时序通过后才登记新的可下载版本，未通过则继续返工，不能将源码采用当成交付通过。不得将其称为完整A6或实机成功。硬件下载与观察继续由用户完成。
- 阶段：短契约已保存并实际读回，供ROOT呈现后限定独立candidate实施；用户自主授权持续，不新增批准问题。仅此卡不是源码或EDA完成证据。
