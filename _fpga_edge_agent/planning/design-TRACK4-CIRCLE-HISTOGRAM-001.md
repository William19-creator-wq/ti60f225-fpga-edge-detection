# TRACK4-CIRCLE-HISTOGRAM-001 v1.1：单种子完整半径直方图与两路线峰

2026-10-11；沿 PLAN_TEMPLATE 合并小增量字段。保留生成前契约，独立候选代码已生成，尚未集成或运行EDA。v1.1只修正raw_right/smooth_right中17'h1ffff与三元问号之间缺少空白的词法问题，记录并保留v1源码副本；数值、状态及协议不变。仅该独立模块，不把本卡称为用户明确批准过的指定版本。

## A. 目标、来源、基线和权限

- Goal / Target：一个已锁定 seed 的完整 E 条 POINT 经外部逐点评估，形成全131072项 HIST、RAW/SMOOTH各完整升序峰前缀及完成元数据；半径合法域1…131071，1Q4一bin，SMOOTH为±8bin box sum。
- Current / Gap：实际 POINTv2、SEED128、物理DDR口、共享PACK正文存在；全域hist/峰模块尚无源码。该模块不做五遍圆、FIT、候选去重、FINAL/ANN或质量承诺。
- Sources：R4-RECOGNITION E2、RECOGNITION-EXECUTION半径/平台合同；实际 board_recognition_points、board_gradient_store、board_native_rpc_arbiter2、queue_ram16_1r1w。
- Authority：用户“当你统计完后自行进行，无需我的批准”“继续完成其他内容”及“不需要再中文草图、测试”的现有自主推进/本地审计例外；不新增独立TB。根本轮只授权本卡；业务编码待根授权独立candidate，不修改052/053/054冻结输入、原HDK、031、正式数据库及硬件状态。052/053/054均已失败结束，本卡不伪称仍在运行。
- Dependencies / Open：父协调器提供本卡IF02数学评估、串行阶段选择和共享PACK/DDR连接；接口义务已明确，尚未实现该调用者。资源、吞吐和EDA结果未测，不能据3RAM估算称整机可容纳。仅模块契约可独立继续；整机集成不是本卡已完成结果。
- Baseline：work/active/track4_board_first_20261011，以下为实际读回SHA256，不伪造Git：

| 来源 | SHA256 |
|---|---|
| board/rtl/board_gradient_store.sv | 6AD8388D53348025F6CAECEFB4441F22954284A383B934F14655D7F2B5C381B9 |
| board/rtl/board_native_rpc_arbiter2.sv | 0E8A204EE18E594CDD9AC9D19283408C0BF65D160251A7998F7CCC9A02F35D7F |
| board/rtl/board_recognition_points.sv | 686C4B19D4D8216A6B8F04EA8BBA259FF74B255D3275E4C9A09C60BD2B7C03FF |
| board/rtl/board_algorithm_rpc.sv | E6D9A67BAE455477822FB2332829E76700A2FB5F3AD31AC10D56357BFDE626BF |
| algorithm/deps/work_queue/rtl/queue_ram16_1r1w.sv | E81BDE29DA5166254EFCCAF287C8FF506B55215D282D442FE990FA038D48D01D |

## B/C. 行为与连接

- REQ01全E、全半径域、不抽样/裁域；REQ02整数票latest RMW和完整clear；REQ03完整RAW/SMOOTH平台峰及各512容量；REQ04实际关闭/有限缓存；REQ05canonical记录和邻峰范围。
- 路径：父锁scope/seed→IF01 START→POINT块缓存→IF02评估→IF03 HIST读改写→同一缓存改作HIST扫描→两路线平台→IF04 PEAK/PREFIX/META→全部关闭→DONE。只有一项DDR请求和一项eval请求在途，不并发占同一物理口。
- E0仍完整清HIST/扫描131072项，峰数0成功；normal=false、radius0或大于131071是该点不投票，仍完成一次eval/点推进。评估失败、格式/溢出、第513峰或未知排空是失败，不输出有效完整结果。
- START只在冷复位后的IDLE或成功COMPLETE接纳；失败终态不接新seed，fault及UNKNOWN隔离保持到整机共同冷复位，父控制器据fault/quarantined报告失败，不以缺少DONE虚构成功。
- 两峰表只发布有效前缀；未用slot保留旧字但禁止读取，不冒称全512条已清零。每实际记录的高padding均写零。成功META匹配scope/seed才能读取此前缀，启动后旧META不属于本作业。

## D. 固定接口与相容检查

| IF | 无实现体端口/交接合同 |
|---|---|
| IF01 START | core clk上升沿，rst同步高有效；start/start_ready；scope96、seed_ordinal8、points21≤W×H、point/hist/raw_peak/smooth_peak/meta_base各32、minimum_peak_votes21∈[1,W×H]。W1920/H1080，允许共同小实例但不缩小生产域。父从start接受到DONE/失败真实收尾保持scope/seed和配置；默认复制配置，板端可显式BORROW_SCOPE，不能逐点换seed。 |
| IF02 EVAL | eval_req_valid/ready、point64、ordinal21；eval_rsp_valid/ready、radius18 uintQ4、normal_ok1、error1、drained1。恰一条已接受请求对应一回复；父同seed计算RNE全宽距离和normal13107精确门，半径不能预收17位。请求正文从提出到回复消费保持；drained证明该评估的数值/预约已真实关闭，error时忽略值，drained0进入隔离。无需echo字段的前提是单项、同seed、严格一一对应，不接无请求回复。 |
| IF03 DDR | 沿用req_valid/ready、req_write、req_addr32；rsp_valid/ready、rsp_data512、rsp_error、rsp_drained。64B、地址对齐；一次请求真实回复消费且drained后才下一请求；所有已提出请求到accept保持，scope/地址/body到真实关闭保持。read reply由原service持有，模块不复制512FF。 |
| IF04 PACK/OUT | pack_valid、pack_index3、pack_data64连接共享gradient_store的point_pack；父阶段所有者独占且store处COMPLETE。无ready的PACK意味着每个pack_valid沿必被接受，按index0…7完整八次；ORDERED_PACK实际上忽略index，严禁跳字或随机局部更新。done仅成功COMPLETE；fault sticky，quarantined表示未知闭合；raw/smooth_count10、首末radius17及votes21保持到下一次start。 |

物理布局：HIST131072×4B=524288B；每峰stride64B、低64为PEAK、高448零，各512条=32768B；META64B。默认hist07000000/raw07080000/smooth07088000/meta070A0000，均在当前活动区外，meta前留圆表空间。START以33bit核对所有对齐、尾端≤ADDRESS_BYTES和相互不重叠；POINT物理读长度为ceil(E/8)×64，E0不读POINT。没有无界地址或外部扩展内存。

PEAK64从低到高：radius17/raw_count21/window_count21/kind2/zero3；RAW kind0、SMOOTH kind1。两个count均取平台canonical最小radius那个位置的真实值，不取平台结束位置。kind2/3及高padding非法。

META512低到高：scope96/seed8/E21/votes21/raw_count10/smooth_count10/raw_first17/raw_last17/smooth_first17/smooth_last17/feed_count18/hist_bins18/W11/H11/layout8=1/complete1/zero211。成功feed_count131081、hist_bins131072；空路线first/last0。邻峰按同路线index0…count−1读，严格radius升序；j>0才有prev、j+1<count才有next，边界无邻，不以0半径伪造邻峰。拟合侧全宽lower_sum/upper_sum18由这些真实相邻记录形成，本模块不提前写尚未存在的next字段。

## E. 中文操作顺序与存储边界

1. **接受/清零**：锁配置，计数和资格清0；HIST全部8192块，每块PACK八个零→提出WRITE→消费成功drained回复才推进clear索引。实际全部clear完成才允许POINT，bin0不投票。
2. **POINT缓存**：一块queue_ram16_1r1w存32×16bit=64B。READ→等回复→按word0…31写缓存，最后COPY沿消费reply；rsp_data在COPY期间借用且保持。尾块超E的整条POINT必须全零。随后每点四次RE→下一沿CAPTURE→固定移位组装POINT64；POINTv2为Gx11/Gy11/dir2/zero8/x11/y11/theta9/zero1，核坐标、梯度范围±1020、L1≤1530、非零及rowmajor。
3. **评估/投票**：实际eval请求接受→等唯一回复→合法值/drained才应用。normal=false或radius域外不写HIST。合格r的地址为hist_base+64×floor(r/16)，读完整块，核16个uint32高11零/≤E；目标票先扩22bit加1并核≤E，不回绕。保持此read reply，依次PACK八个64位word，只改目标uint32；第8PACK沿后整块已完整装入旧26RAM正文，可以同沿消费read reply，下一状态才提出WRITE。WRITE至真实成功drained消费期间PACK=0、点/地址/owner保持，之后votes++和ordinal++。
4. **切换缓存**：所有E点及eval/读写实际关闭后，同一32×16 RAM改为HIST扫描行缓存。每64B HIST read同样先COPY32并消费reply，再读取16个uint32喂环窗；若不先释放，判峰WRITE会被本模块held HIST read挡住，这是明确禁止路径。扫描所有高零、bin0=0、单项≤E，ΣHIST最终须等votes。峰写暂停不会覆盖该行缓存。
5. **19项环窗**：两块16bit同步1R1W RAM分存low16和high5（高11写0），有效地址0…18。每seed进入扫描时feed_n/write_ptr、prev/prevprev、两平台和pending归零；切换64B扫描行不清这些历史。feed_n18从0递增到131080；真实0…131071来自HIST，随后九个0。write_ptr5按18→0回绕；针对offset17/10/9/8依次RE、下一沿CAPTURE，n<offset直接取0不读未初始化RAM，地址为(write_ptr+19−offset)mod19。四项读完才写当前raw[n]，不依赖同址读写结果；两RAM不全清，n<offset屏蔽及本seed真实覆写建立读资格。
6. **平滑/观察**：oldSmooth=S(n−9)，newSmooth=S(n−8)=oldSmooth+raw[n]−raw[n−17]；先用23bit临时值核无下溢/≤E再收21。目标r=n−9；RAW左/中/右来自n−10/n−9/n−8；SMOOTH左/中/右为prevprev/prev/new。合法目标仅r1…131071，r0不进入平台FSM；在r1左邻、r131071右邻将两路线邻值显式置0。目标window_count仍取真实±8和，不把数学S(0)/S(131072)的非零值拿来作域内邻峰。
7. **平台/同时峰**：对每路线，cur>left建立新的正平台，冻结height、最小radius和该处两count；cur==left沿用旧平台；cur<left或cur0失去平台资格。cur==height且right<cur、平台左邻严格更小、height≥minimum_peak_votes时立即生成峰；如果本位置刚建平台，用当前值，否则用冻结start值。同沿RAW/SMOOTH分别写入独立64bit pending槽。任一路旧count已512而再产生峰，整作业CAPACITY；不删另一峰冒充成功。
8. **写峰/继续**：feed/window/行缓存/平台记录在峰backpressure期间保持。优先RAW后SMOOTH，分别PACK低PEAK+七零字→WRITE→真实成功drained回复才count++/首末更新/清对应pending；两pending全关闭后才推进下一feed。feed131080的目标是最后r131071，域外右邻0可当场结束平台；不需要第十padding。不能在同一位置重复喂ring或漏第二路线。
9. **封存/失败**：全部131072真实bin、9padding、两pending、PACK/DDR/eval都关闭，后续状态写完整META并等回复，下一旧quiet状态才DONE。已知失败先消费/关闭旧held回复，不造新请求，保持真实前缀并锁fault；drained0锁Q，不宣称drained、不授新seed。取消只由父停止新start，已接受作业按旧上下文结清；模块无暖复位/取消接口，rst仅沿整机共同冷复位，不用局部reset掩盖DDR在途。

## F. RTL/数值与有限预算

- 单core正沿，valid无效不当数据零；只有明确域外padding才喂零。无CDC/C++/新软件参考，沿用现有工具及父时钟约束。RAM读预约/下一沿capture，配置/地址/正文不能按组合最新输入换归属。
- E/votes/HIST/window21，计数增量22；peak_count10可表示512、feed/index18覆盖padding；radius18输入先全宽查域后收17。clear块索引14、cache word5、ring地址5先检查0…18再接9位RAM地址。所有加减先显式扩展，任何异常失败，禁止饱和或回绕。
- 结构预算：共享块缓存1RAM、ring2RAM，共3块新增RAM；缓存POINT64、四raw读值84、平滑历史42、两平台记录约164、两pending128及控制/配置为有限寄存器。共享512正文原26RAM与物理reply只借用，不新增512FF；计数/latency不是EDA结果。DDR至少8192次clear写、每实际投票一读一写、8192次scan读及各实际峰一写；复制/环读/评估停顿另计，不宣称实时。
- 根实际阶段mux必须在前一seed/dense/数值quiet且物理drained后选hist owner，直到本模块终态保持；当前永久seed_started/dense_started优先级不能直接沿用。NUM计算属于后续协调器，本模块只靠IF02，不假设PC代算。

## G/H. 实施、必要检查和追踪

- Milestones：根呈现本卡→授权独立candidate的board/rtl/board_circle_histogram.sv→定向静态读回→后续协调器/父mux→用户要求的整机EDA；不生成独立TB、不运行本轮EDA，不改main/052/053。
- Validation文字：V01 E0/末块不足8点及全部高零；V02同bin连续票和第E票；V03 r1/131071、九padding、跨64B smooth；V04正平台与两route同拍，起点另一count不同于末端；V05第513峰、PACK停顿及UNKNOWN；均按真实沿和本卡数学期望静态走查，尚非仿真结果。
- 双向追踪：REQ01→IF01/02与E1…4→V01/02；REQ02→HIST_CLEAR/RMW→V02/05；REQ03→E5…8与IF04→V03/04/05；REQ04→COPY/RSP/PACK/QUIET→V01/05；REQ05→PEAK/META/升序前缀→V03/04。拟文件各状态只服务这五项，不加入FIT/圆结果/绘图。
- Failure handling / Rollback：candidate单文件失败不采用；保留本卡/基线和真实错误前缀，不能放宽domain/容量或伪造drain。Completion：仅当实际完整域/两峰前缀/元数据协议实现且必要整机工具通过，才登记该局部软件结果；独立卡不是整包、质量或硬件完成证据。
- Review：保存后必须读回、核该路径及hash并报告；接口/数学关键选择已收束，未实现的父callback/整机接线属于明确后续增量，本卡不宣称所有依赖已实现或整机READY。
