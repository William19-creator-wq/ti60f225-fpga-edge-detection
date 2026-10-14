# TRACK4-NUM-INPUT-WORD-001 v1：NUM 初始化输入提前选字

2026-10-11。按 PLAN_TEMPLATE 小修复短卡保存。当前为只读设计，尚未生成本候选源码或运行EDA。引用用户自主继续及免新增长草图/TB授权；ROOT读回呈现后限定独立candidate实施，不新增批准问题，不伪称用户批准新指定版号。

- Goal / Gap：056 MAP PASS，LUT44186/FF20036/RAM225/DSP154，packed57903、routing3294、physical61197/60800，超397，无PGM。返回字共享实际packing省333但routing增334，未解决容量。本轮只把scalar初始化输入提前选成16位，并把完整B192判零提前到owner选择之前；实际收益待下一工具运行，不能保证省397或路由成功。
- Target / REQ01：所有192位A/B共384位、padding16、sign/header、DIV_ZERO/unary格式错误及优先级、REQ622/RSP585/target/取消/quiet逐位同旧。REQ02：仅组合侧带，不新增FF/RAM/DSP、正文快照、时钟或数值核。REQ03：默认关闭及不满足有效条件时原泛用行为保留；原FSM、WE、地址、256沿初始化、停止和全部资格不变。
- Scope：独立候选只复制修改下面两份main文件，保留before与change-record；不碰056冻结输入、原资料、脚本、geometry候选、callback/HIST、返回字接口或其它算法。ROOT后续确认后才采用/冻结测量。

## 实际基线与源码事实

路径相对 work/active/track4_board_first_20261011。

| 文件 | SHA256 | 拟改职责 |
|---|---|---|
| board/recognition_numeric/scalar_core_words.sv | 1568D08773306D8F56C35E77E399502D4BEADA46D15234D537DFF30BBA7DA4E4 | 仅INITIALIZE读外部字及CHECK的B零谓词 |
| board/rtl/board_algorithm_rpc.sv | 14E8BAC5A362AE37D6091516569AAFB841AE5B1613C46340D0EBD6D6CDAE2E88 | 从两份完整请求直接固定切片选字、分别判B零再选owner |

已逐项核对scalar真实用法：:191/193初始化动态读A/B；:158/159 ADD及:312/313 COMPARE的原始宽读取只在非AREA_RAM_WORDS分支；:144 unary格式同时检查padding16+B192；:146 DIV_ZERO检查完整B192；:44/45 A/B符号继续保留。**:338 ROOT_SHIFT在AREA_RAM_WORDS=1仍从original_a动态取2位**，本次保持原样，不能宣称A192 owner mux完全删除，不增加ROOT输入侧带或扩大范围。

## IF01 端口与整体连接

scalar新增参数 BORROW_INITIALIZER_WORDS（bit，默认0），有效条件 USE_BORROWED_INITIALIZER_WORDS = BORROW_INITIALIZER_WORDS && BORROW_PAYLOAD && AREA_RAM_WORDS；当前板端三者均开启，其他组合回退原逻辑。

| scalar端口 | 方向/位宽/意义 |
|---|---|
| initializer_word_index | 输出unsigned4；原initialize_index低4位，合法字0…11 |
| initializer_operand_b | 输出1；选择原BB窗口的B操作数，A为0/B为1 |
| borrowed_initializer_word16 | 输入unsigned16；同owned请求完整A/B的指定原16位字 |
| borrowed_b_zero | 输入1；同owned请求完整B192==0，不能只检查低128/低16或截断后的值 |

RPC按现有seed_started选择实际owner，保持原req_body宽接口。用{owner,operand_b,index}提前选择固定字：2owner×2operand×12word共48个固定16位切片，可用固定mask-OR或等价常量case。每项直接从FIT或SEED请求取固定字段，不先造新的192/384位owner正文mux再动态切片。非法index12…15输出0；**index0合法，必须返回真实第0字，不能置0**。

REQ字段：A为[413:222]、B为[605:414]、padding为[621:606]；字w分别是222+16w及414+16w起的16位。RPC分别对FIT B[605:414]、SEED B[605:414]作完整==0，再按同一个owner选择borrowed_b_zero，避免先合并B192再OR。

## IF02 时间、错误和借用合同

- 初始化仍写原memory_left/right：地址0…11用A字，16…27用B字，其余12…15及28…255保持原零写。仅这两个窗口替换write_data来源；write_enable、write_address、原initialize_index、每次递增及结束255沿完全不变。无新增valid/ready、读取延迟、写事务或状态。
- CHECK只把原unary的B192非零部分替为!borrowed_b_zero，padding16仍从原held_payload检查；binary padding16检查保持。kind3/6 DIV_ZERO用同一完整B零谓词。默认/无效参数保留原表达式，原kind3 b_negative、AS/BS格式、其它全部检查及错误优先级不改。
- AS/BS和original_a/b最高符号位仍取原req_body/held_header/payload；ROOT_SHIFT原2位读、非AREA分支及全部算术保持。不能删高位格式检查或用初始化RAM内容替代接受时的格式检查。
- 所有侧带均来自当前同一owned请求正文，从真实req接受到reply消费及scalar quiet保持，**不能按req_valid门控**；接受后req_valid会下降，但INITIALIZE仍需要全文。FIT私有bridge与SEED现有pending请求正文借用约束继续成立，owner只在原FIT完整关闭后切换。
- 侧带是组合信号；原游标提交后组合字随新游标更新，下一原写沿使用。停顿、取消、复位及HELD写禁用沿用原规则，不从无效侧带推进。无CDC或新时钟；C++及跨语言新增逻辑N/A，仅保持原RTL整数表示。

## 局部操作、验证及追踪

1. CHECK先按原顺序核WH/version/kind/target/AS/BS/padding，再用对应owned正文的完整B零做unary/DIV判断；失败沿原路径，不触发初始化。
2. INITIALIZE先按原地址窗口确认A/B；向RPC提供原索引，RPC常量切片选择真实16位；原同沿WE/地址将该字写入两个原存储副本。窗口外仍零写，不把低4位循环当成合法数据。
3. 完成原256地址后进入原ABS/运算/结果资格/HELD关闭；不触碰返回字共享、完整385位检查或scalar结果银行。ROOT_SHIFT遗留A宽路径如实保留。

- Validation：定向静态走查默认参数0、参数1但BORROW_PAYLOAD/AREA条件不足、A/B第0/11字、地址12/15/16/27/28/255、非法字12…15、完整B仅高位非零、unary padding非零、DIV零与kind3负B优先级、req_valid下降后继续初始化、取消/RST禁写。无新TB/独立执行测试，工具容量/路由/STA由ROOT实际测量并登记。
- 双向追踪：REQ01→IF01完整固定字段+B零→scalar CHECK/INITIALIZE与RPC输入侧带；REQ02→组合case/maskOR与zero前选→仅新增wire/默认参数；REQ03→effective条件/原地址WE和256沿→原FSM及借用关闭。实际代码、before/hash、静态差异及工具报告随后补入change-record，不以设计或源码生成当工具通过。
- Open：局部接口无未决语义；资源收益未知，ROOT_SHIFT仍读A，且固定片段选择/判零的工具映射可能增加路由。不得承诺397余量或重跑相同PNR recipe会改善。
- Rollback / Completion：保留两份原文及SHA；ROOT定向静态通过后可临时采用到独立主work冻结下一run，仅实际容量、路由、最终STA通过才登记下载版本。失败继续返工，不改056记录，不称完整A6或实机通过；硬件由用户下载观察。
- 当前阶段：短卡已保存，供实际读回/ROOT呈现；本轮不生成实现，不修改两份main。
