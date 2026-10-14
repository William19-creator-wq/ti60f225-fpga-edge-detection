# TRACK4-ALGORITHM-ROW-PIPELINE-001：生产行解包、预取、渲染与写入候选 v0.1

2026-10-04。LOCAL_DETAIL_DESIGN／NOT_READY_FOR_REVIEW／NOT_APPROVED／NOT_IMPLEMENTED。本卡推进 PRODUCTION-BUFFER 的 PB-B04，不能替代整包批准、服务证明或 Efinity 实测。

## 通用计划字段

- Goal：为完整1920×1080生产显示规定真实native行缓存→有界预取→四级数学→五lane输出行的局部合同。
- Current state：现有Efinity工程可打开，原参考综合已通过；十一项算法未实现。旧逐pair REPLAY不可直接承担60Hz固定扫描。PB已有input18／RX7，PIO已有output15，decoder与逐沿生命周期待细化。
- Target state：完整消息、身份、资源、最坏服务和scan绑定联合冻结后，形成可审阅批准基线；获批后才生成RTL、参考与TB并验证。
- Gap／Open questions：RP-B01…05见A；尤其首行提前准备与scan_token分配时点冲突，当前不得实施。
- Assumptions：1920像素一行、960pair、100MHz core候选；native RE下一沿捕获且新捕获不供同沿JOIN。以上是待工程验证的设计前提。
- Dependencies：整合v0.7、PB v0.1、PIO v0.2、REPLAY当前稿、DISPLAY和共同真实对象owner。
- Milestones／Detailed steps：来源核查→数值几何→身份与银行生命周期→有限独立审阅→全局消息/期限联合冻结→READY与指定批准→实施和实际工具验证。
- State transitions：本卡只变设计状态；正式PROJECT_STATE、数据库及人工硬件闸门不变。
- Artifacts and hashes：A表、纯算术JSON、独立审阅报告；不把文档hash当实现基线。
- Validation：G为尚未执行的场景；本次只有静态算术、来源阅读与设计审阅。
- Failure handling：保留真实前缀与旧义务；不能证明关闭则Q，不伪造FREE或READY。
- Human approval gates：本卡未达到READY，没有算法实现批准；原v1/v1.1/v1.2预检不覆盖本卡。
- Rollback：原资料只读；以后实现只能在指定独立work。恢复先核hash/批准/差异，不改原工程。
- Completion criteria：全局阻塞关闭、可读回设计获指定批准、真实仿真/综合/PNR/STA/bit证据满足整包目标；当前未完成。

## A. 状态、来源、边界及阅读入口

整体位置：板载DDR已封存的真实SRC/EDGE/ANN→bulk provider→本卡→PIO固定扫描。PC只做独立参考、仿真和观察，不承担生产渲染或存储。本卡不改变五基础、六高阶、完整Canny、生产分辨率或识别质量目标。

| 输入 | 当前SHA256 | 实际用途及证据限度 |
|---|---|---|
| [整合v0.7](design-TRACK4-ALGORITHM-INTEGRATION-001.md) | 5FA0450D69FFFEA32F74EEC7A95173030FCDCDA701FFA1AAD170F6698027B4C6 | 完整目标、IF09/12/14、六immutable SRC与五ring；非完整实现证明 |
| [PRODUCTION-BUFFER](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 | D3/D4历史R_ROUTE、input/RX native几何、720写事件；服务仍OPEN |
| [PRODUCTION-IO](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | D2/D3、OP04…06的ROW472、五lane、固定扫描及关闭 |
| [REPLAY](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | D1/D3/E3数值、坐标、历史render、四级；旧RQ/RR/OUT不能改名冒作本生产族 |
| [DISPLAY](design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 | 物理RGB低地址色序和模式规则 |
| [来源合同](../experiments/track4_algorithms_20261004/02_design/control-display-source-contracts-v0.1.md) | 192D9DCED0F1189E6804423040BA45FDAD6DAE8F00B9D87893DE31E649DD91A0 | 冻结颜色与mode0偶行访问，原文与候选区分 |

上述来源保持原版本；本卡只提出局部增量，未默改其接口。v0.2规范SHA256为4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2。阅读顺序为本B整体→C责任与连接→D交接→E中文操作→F/G/H；随后回整合I核未闭合范围。

| 阻塞 | 影响 | 缺口、处理责任与可继续范围 |
|---|---|---|
| RP-B01实际native/DDR/时钟 | IF01/02、全部期限 | 最终IP可用性、响应/屏障/CDC/STA未验证；工具/IP适配设计负责。静态几何可继续。 |
| RP-B02完整消息与owner | IF01/02/03、REQ02/05 | ROW_ASSIGN、bulk借用/close、out私有退还、错回复/Q/epoch及全目录未冻结；整合owner负责。KEY164只是已绑定本地索引。 |
| RP-B03首行scan身份 | IF03/06、REQ05 | PIO L157仅实际VSYNC分配scan；L163的提前ROW已含scan；L222要求首行提前ready。不能按未来VSYNC自造token。两候选见J。 |
| RP-B04最坏服务及全资源 | REQ04/06、IF01/06 | 三out全部占用时周转、首行/candidate不饿死current、DDR/decoder/CDC/scan期限和总FF/LUT/RAM未证明；PERF/PIO联合负责。 |
| RP-B05完整实施基线 | 全部 | 全文件/配置/测试/独立参考与工具语言合同、批准未冻结；整包负责。当前不生成业务代码。 |

## B. 整体外部行为

REQ01：合法完整输入行保持原物理RGB、EDGE与ANN数值，显式转换色序，每pair依历史PLAN/render输出两个RGB24，行内顺序p0…959；一行恰46080有效bit，不生成第2305个word。

REQ02：FULL、input读取资格、output预留、ROW_READY、OWNED和物理APPLIED是独立事件。FULL不授显示；预计960不冒充实际960；READY不冒充VSYNC采用。

REQ03：mode和数学复用REPLAY原定义；gray为原RGB的floor((77R+150G+29B+128)/256)，不是median结果。mode0上gray/下EDGE白黑；1原RGB；2gray；3EDGE白黑；4按show_edge覆edgeRGB；5先mode4再按show_ann覆非零ANN色，ANN11同样优先EDGE。show开关不减完整平面资格。

REQ04：缓存、decoder与数学有限；在完整输入已封存、out预留成功、无停顿及native前提成立时，稳态可一pair/core。固定扫描不能暂停，这个局部稳态结论不证明全机期限。

REQ05：历史RowCtx、bank_generation、borrow、source/target坐标和scan身份必须一致；取消、换配置、错误echo不能释放另一银行或套新配置。公开消息保持到fire。

REQ06：输入银行返还只等自身真实读义务，不等ROW/整个scan退休；复制值另pin上下文。out返还沿用PIO各bank自己的读取关闭，Q不复用。初始化无有效上下文，旧RAM内容不可见；warm reset先停止新事务并关闭旧义务，冷共同reset须有全体作废授权。

正常样例：mode5同一真实bundle的RGB/EDGE/ANN全部FULL，取得out reservation及input lease，960次JOIN和2304词实际WE后形成ROW；scan另核身份/目标/期限再接收。颜色例：物理byte[1,2,3,4,5,6]对应raw48=060504030201，canonical=040506010203。

边界样例：p2、p5跨RGB128边界；p959只用RGB359/offset80、EDGE119/offset14、ANN239/offset12，输出word2301…2303，不能预读360或写2304。mode0 dy539/540/1079的sy分别1078/0/1078，各行mask分别001/010/010。失败行只记录真实前缀，不补成功输出；持续反压为未完成，不用超时伪造关闭。

## C. 职责、连接与整体检查点

普通文字路径：历史bulk grant／R_ROUTE→IF01 RX decoder→两input bank→IF02读取租约／IF04三plane预取→IF05同一owner四级数学与writer→三out bank→IF06 PIO_ROW／固定扫描。历史PLAN/render与RowCtx贯穿路径；错误回银行owner与父，不向当前UI查颜色。

| MOD | 职责与拥有状态 | 划界、来源与不负责项 |
|---|---|---|
| ROW_OWNER | 唯一分配/绑定RowCtx、input gen和lease，核FULL/RETURN | 依真实bulk借用；不按外部slot自造权限；完整全球消息RP-B02 |
| RX_DEC | 用历史route拆实际RX记录并写完整input word | 两135bit holding含预约；不因末R或RX空提前释放route |
| ROW_RENDER_WRITE | out先预留；三plane cache、P1…4、pair holding/tail/stage单一私有owner | 复用数学规则并新写生产适配；不复制旧逐pairRQ节拍或OUT404 transport |
| OUT_OWNER/PIO | 唯一选择FREE out bank，发布完整ROW并按OWNED/RELEASE/ACK退休 | 五lane native结构沿用PIO候选；固定scan/serializer精确相位仍RP-B01/04 |

不采用live RGB等待尚未产生edge的反馈；所有required输入来自完成对象。填下一input可与读当前input并行，绝不能写已授读/未RETURN银行。single renderer先结束旧P/holding/tail/stage再接下一行，避免跨行隐藏容量。candidate只能取得不会侵占current/next承诺的资格；三out满不能假称第四槽。整体设计检查点：B/C已明确局部边界，RP-B01…05仍阻实施，进入D/E只做细化。

## D. 接口与组合设计检查

所有数值unsigned；core上升沿前valid/ready均1且非rst为fire，body held期间不变。以下是无实现体合同，不是可编译端口或业务源码。

### D1. 历史上下文与本地键

候选RowCtx865依次为PLAN616／scan64／bulk_borrow64／row_seq64／source_y11／target_y11／required_mask3／link32；PLAN字段及render112沿用REPLAY D1。scan尚有RP-B03，不填0冒合法值。required由合法mode/source证书确定，不来自未经核验的调用方位。source/target y各0…1079，mask只允许该mode访问集合。

本地KEY164为epoch32／row_ctx_slot3／row_seq64／input_bank1／input_gen64；slot仅0…4，5…7拒绝。row_seq在真实epoch内唯一、不回绕；gen不得重用。KEY必须完整查到已绑定RowCtx并核全身份，不能按slot或seq独自寻址。角色current/next/candidate另存，不能修改已发布ctx。

最多五RowCtx来自三out与两input，body4325bit；renderer必须先占真实out才能读，不存在第六renderer ctx。input返还后copy/P仍借原ctx，out保持接力；pixel从out复制后只持独立scan_parent与坐标，不继续借RowCtx，否则五个上界不成立。父current/future/closing三scan ctx、两bundle限额独立于此；引用计数、状态及消息另计。

### D2. 本地租约候选与尚缺全球族

| IF | 方向、body及生命周期 |
|---|---|
| IF01 bulk→RX→input | 真实已授权对象范围/plane/row/beat/last/status沿历史R_ROUTE传递；完整packed body/close RP-B02。每次input合法实际WE才计覆盖；padding不作为图像。 |
| IF02 ROW_READ | RENDER→ROW_OWNER REQ164=KEY；ACK172=原164/status2/reason5/granted1。只有旧成功grant且完整out reservation/RowCtx匹配才可RE；拒绝不授读。 |
| IF03 OUT_RESERVE | RENDER→OUT_OWNER REQ164；ACK644=原164/ROW_TARGET472/status2/reason5/granted1。唯一out owner选择FREE bank并分配gen；target中的960是预计目标，成功不是READY。必须先成为旧成功事实再请求IF02。 |
| IF04 native读／INPUT_RETURN | RETURN174=KEY164/kind2/no_future_RE1/native_pending_closed1/bank_refs_closed1/reason5；ACK182=原174/status2/reason5/returned1。正确成功ACK消费后，后续旧资格沿才填input。复制cache/P独立持ctx而不持银行。kind/status/reason精确枚举及out私有退还族仍RP-B02，未冻结不实现。 |
| IF05 JOIN／数学／writer | 单owner私有pair=RGB48/EDGE2/ANN4和ctx_ref、p/坐标/last；required缓存同一JOIN推进。不采用公开OUT404；若以后改独立valid/ready边界须另改设计，P4稳定义务不能删除。 |
| IF06 published ROW | 沿PIO_ROW472／OWNED479／RELEASE480／ACK487原族；完整历史ROW不因cancel/currentUI变化改写，scan绑定RP-B03。 |

ACK成功候选须正确完整echo、status0/reason0、granted或returned1；失败、非法、wrong-key不赋予权限，不能按坏body返还他人bank。完整原因/重复/忙/Q恢复全球规则未冻结，所以这些位数不是已相容的最终协议。valid/ready另计。

三out每方向held/目的private body预算仍为6×(472+479+480+487)=11508bit，不能用RowCtx ref无证删除。新本地族若各端各一份，body下界2×(164+644+164+172+174+182)=3000bit，另有out私有退还、ROW_ASSIGN、valid、状态、同步和ledger；不称完整预算。

逐连接检查：实际RX记录必须归历史route并经范围/序列/状态验证才写；FULL必须核全部required覆盖、末写、padding/无未来写；out预留保证位置但不保证scan身份/期限；RE返回保证旧预约槽可捕获，后续沿才能JOIN；JOIN保持同ctx和mask；最后WE真正完成及所有私有引用关闭才READY；PIO接收/应用另有独立资格。任一前提缺失不得用后端完成位倒推。

## E. 详细中文操作草图与不变量

### E1. RX解码及FULL

1. 接纳前检查历史route与目标input写权限、合法plane/范围及响应状态；为下一native RX RE在两holding中预留槽，valid＋reserved≤2。读返回下一沿真实capture，禁止同沿直接写新值。
2. RGB记录低128bit分七个20bitlane、最后lane高12bit写规范0，一次逻辑entry的七WE同沿。EDGE/ANN记录依低16bit先行、八词拆分，每core沿只写当前旧holding的一词；旧词写完才退休holding，下一记录必须占真实槽。
3. required mode5：RGB360、EDGE120、ANN240逻辑word写，共720事件；RGB每事件七native lane，故native lane WE合计2880。405 AXI数据拍、720逻辑写事件、2880 native写入不同，不能互代。
4. 每次实际合法WE更新对应覆盖计数/前缀；RGB高12和RX高5不是图像，ANN/EDGE取低位，不把padding拼进像素。遇错停新提议，已issued RE捕获、已published消息履约，再关闭/隔离。
5. 全required正确完成、无旧/未来写、输入自身pending/holding已结清且正确源证书后才能FULL。末R不等于FULL或R_ROUTE结束；历史route依PB真实解包引用关闭，不等整行渲染。

### E2. 预留、预取及同一次JOIN

1. 接真实已绑定行，只以旧成功OUT_RESERVE取得目标；下一资格沿取得input READ。未取得input时取消只退out reservation，不等待不存在的INPUT_RETURN。
2. RGB两128bit、EDGE两16bit、ANN两16bit；每plane至多一个RE pending，pending预留槽，valid＋reserved≤2。未required平面不读取，数值位置规范0且mask不假报完成；关闭show开关不减少mode4/5 required。
3. 首RE读各required word0，下一沿capture并在另一槽读word1，再下一沿capture。JOIN只看沿前valid缓存；最后一返回不穿透使用。
4. p递增仅在真实JOIN fire；RGB起bit48p，word=floor(48p/128)，偏移周期0/48/96/16/64/112/32/80，p模8为2或5时跨拍。使用八种固定切片候选，避免把整RAM构成变量索引mux。EDGE每词八pair，ANN每词四pair。
5. JOIN真正退休旧word后，**后续旧资格沿**才能将空槽预留并发下一RE，不依同沿新空位。p2退休RGB0→下一沿RE2→再下一沿capture→p5需要；p5→RE3→capture→p8需要；p7→RE4→capture→p10需要。EDGE/ANN有更长word复用期，同样遵守后续沿。
6. Stall不推进p、退休缓存或P级；既issued RE仍必须写入已预约槽。恢复只使用旧valid。p954 JOIN真正退休357后，后续旧资格沿（连续时p955对应沿）才能预取RGB359，p956对应沿capture，p957才首次使用359；p957退休358后禁止读360。末pair全部数据已复制且无未来RE/旧pending/银行holding后，可以提出INPUT_RETURN，复制数值保留独立ctx引用。

### E3. 数学、色序与output writer

1. 物理SRC低地址R0/G0/B0/R1/G1/B1，显式转换为canonical {R1,G1,B1,R0,G0,B0}。EDGE低bit为lane0，ANN低2bit为lane0。lane0对应偶x、lane1为下一pixel；无alpha/gamma。
2. P1每lane保存77R/150G/29B的16bit乘积；P2旧乘积求和加128，最大65408；P3旧sum取高8形成Y；P4按旧P3和历史render112选色。每级只看旧级，统一advance受旧下游容量控制；无输入插气泡，valid0不当黑像素。
3. 两RGB48 holding加tail19；从旧pair与旧tail组成最多67bit，抽2或3个完整20bit词形成160bit stage候选，其未用位零。stage形成的沿不能同时按新stage写RAM，后续沿实际WE。每个stage最多三个连续word，落互异lane；lane=w模5、addr=floor(w/5)，候选固定轮转状态可避免运行时除法。
4. 旧tail周期0/8/16/4/12；完整词数2/2/3/2/3。960pair恰2304词且末tail0，本1920行**无额外padding word**。lane0…3 addr0…460，lane4只0…459；预核所有地址再写，不能部分越界写后算成功。
5. 分别记真实JOIN、writer接收、native WE与完成条件。最后p959写2301…2303，末word lane3/addr460。960JOIN、2304实际完整词、所有P/holding/stage/tail/pending关闭且全行合法，后续旧资格沿才形成PIO_ROW；不能只见last或FIFO空形成READY。
6. 此owner不跨两行保留流水。当前私有流水、stage及引用结清后再接受下一行；发布ROW后该bank只读，FREE仍需原PIO正确关闭/ACK及后续沿。

### E4. 有限沿表、资源与失败

无停顿、完整input/out资格已经成立的候选沿表：e0锁行／资格；e1首RE；e2capture0并RE1；e3capture1；e4首JOIN p0。p2在e6、RE2在e7、capture2在e8、p5在e9；p5退休后e10 RE3/e11 capture3/p8 e12；p7 e11退休后e12 RE4/e13 capture4/p10 e14。960连续JOIN末p959在e963；按四级e967交付给私有writer，e968末stage，e969末WE，最早e970依据旧完整状态形成READY。此表不包含DDR填料、globalgrant、CDC、scan相位或仲裁，不能拿970沿当全行期限证据。

局部payload候选下界：cache320＋decoder两135=270＋P1(96+54)=150/P2(32+54)=86/P3(16+54)=70/P4RGB48，共数学354＋writer275＝1219bit。ctx_ref、sideband、valid、预约、计数、地址、render引用、状态、消息另计；phase/tag不得隐藏在payload的零padding。五RowCtx body4325、新本地族候选3000、原ROW族11508、PIO scan侧632与scan_parent2040各有不同用途，不能相互删减或宣称总FF。

input18、RX7、output15为独立40 RAM10 payload候选；并非全机RAM预算或已综合映射。Native逻辑尾：RGB360…511、EDGE120…511、ANN240…511、RX128…511禁止访问；RX7bit逻辑索引必须零扩展到9bitnative地址，occupancy128是计数不是地址。所有WE只写完整word，不能同址native读写。

取消/错误边沿先记真实旧fire/WE及issued RE；后续停新JOIN/RE/写提议。本卡math/writer同一owner，未曝光私有值可真实清理；若旧stage已经发出native WE必须真实结清。所有对外held请求、回复、ROW、RETURN保持并履约；已published ROW按原472身份DISCARD/RELEASE/ACK，不撤valid。错误echo不释放bank；无法证明read/write effect结束或DDR失信则Q，通知消费不解除引用。warm reset独立推进收尾控制，不能单端清FIFO造empty；合法冷共同reset仍需全域/外部效果作废合同RP-B01/02。

## F. 语言及跨语言合同

本卡尚无C++/RTL实现。计划RTL沿用工程支持的Verilog/SystemVerilog子集，最终语言参数与编译基线RP-B05；不能因文档能写表达式便声称工具支持。C++参考拟采用逐bit整数数学，标准/实际编译器及测试协议尚未冻结，不写功能程序。值域、无别名持有、错误结果不得部分成功、整数先扩展/后窄化、静态有限容器及取消/副作用均须在该实施基线落实；本候选不使用生产主机对象或指针。

| RTL项目 | 契约 |
|---|---|
| A数值 | RGB通道8、gray乘积/sum16 unsigned，最大65408；RGB48/EDGE2/ANN4；索引/计数各按真实范围，截断/回绕禁用，非required数值规范0但valid区别保留。 |
| B时钟/观察 | core100候选；沿前fire、沿后提交；native RE下一沿capture、新值后续沿可用；TB以后只在规定提交后观察，当前未运行。 |
| C接受/交付 | input FULL和out旧grant先于RE；真实JOIN/WE/ROW fire分别记；固定scan不可反压，服务不足真实underflow。 |
| Dvalid/推进 | 无效不推进p/计数；全部required旧cache才JOIN；有空泡保持sideband一致。 |
| E反压 | 私有流水按真实后端容量统一advance；已issued返回有预约槽；held体保持；当前UI不影响旧行。 |
| F延迟/吞吐 | E4条件沿表、一pair/core稳态是局部候选；填料/仲裁/CDC/scan服务未包括。 |
| G复位 | 本域屏蔽fire；异步assert/sync release具体工程合同RP-B01；warm reset不撤旧义务/Q，RAM用有效身份隔离而非必须全清。 |
| H配置 | 历史PLAN/render冻结；同沿新配置不修改旧ctx，真正scan采用另待RP-B03冻结。 |
| I存储 | 两input/两decoder holding/六cache/单数学writer/三out；预约计容量、逻辑尾禁读写、native延迟与无同址碰撞。 |
| J身份 | source/target y不同、p0…959、偶x=2p、lane0/1；mode0重复偶行访问；实际源借用与完整gen核验。 |
| K CDC | 本卡解包/数学在core；out→pair跨域沿原ROW handshake，不能多位直采；完整同步/复位/serializer相位RP-B01/04。 |
| L实现 | Ti60F225/I3、Efinity2026.1.132已有项目事实；native payload40RAM为候选；全FF/LUT/DSP/STA未闭合。 |

三份映射分别为：共同数值仅逐bit色序/gray/mode；硬件执行另核旧状态、RE/JOIN/WE/关闭和stall；参考结果对应真实epoch/RowCtx/源target坐标/p/历史render，只有合法实际输出交付后比较。静态整数样例不能替代执行/CDC证明。

## G. 实施及验证计划（全部未执行）

获批后拟在独立work生成 row_rx_decoder、row_prefetch、row_render_write、row_context_owner和适配文件；名称仅职责计划，未生成。先关闭RP-B01…05及整包基线，后逐步实现/独立参考/真实厂商RAM仿真→集成→Efinity综合/PNR/STA/bit；缺key、packer或资格失败停止相应阶段，不用stub冒成功。

| TEST | 覆盖 | 场景和期望／来源 | 方法及通过界限 | 状态 |
|---|---|---|---|---|
| RP-T01 | REQ01/03 IF05 | RGB六byte1…6、红/蓝交替、黑白及三纯色；canonical和gray与B/E3相等 | 独立数学与RTL实际输出逐bit/逐坐标比 | 未运行 |
| RP-T02 | REQ01/04 IF04 | p模8全部、p2/5及末p959，noRE360/EDGE120/ANN240 | 真实native模型、沿后核预约和访问；无越界 | 未运行 |
| RP-T03 | REQ04/05 | 随机stall与pending返回同沿；cache valid+reserved≤2，p仅JOIN推进 | future TB预定种子/时钟，不能取消issuedRE | 未运行 |
| RP-T04 | REQ01/02 IF01/06 | mode5 405拍、720事件、2880 laneWE，960pair/2304词/末tail0 | 核独立ledger及首次FULL/READY沿，不能用总数补缺覆盖 | 未运行 |
| RP-T05 | REQ03/05 | mode0 dy539/540/1079及所有mode；开关关仍核required，ANN覆EDGE | 逐source/target坐标与历史render比，不读取currentUI | 未运行 |
| RP-T06 | REQ05/06 IF02/03/04 | out grant后input未grant取消、wrong-key/oldgen、published ROW取消 | 独立关闭/退还/真实前缀，无假RETURN/FREE | 未运行 |
| RP-T07 | REQ06 | 末RE已复制但P/WE未完先返input，下一行填料并行 | 银行无未来RE/无引用，ctx仍pin，ACK后后续沿才重写 | 未运行 |
| RP-T08 | REQ04/05 | 三out满且candidate准备、首行VSYNC绑定、repeat/fallback并发 | 先解决RP-B03；不隐藏第4scan或第4out；真实期限/事件 | 未运行 |
| RP-T09 | REQ05/06 | warm reset、失钟/DDR失信、未知effect/Q | 旧held及效果保留，Q消费不FREE，无假QUIET | 未运行 |
| RP-T10 | 全部 | 实际工具全工程资源、route后时序、持续输入显示及完整算法 | 仅真实整包日志/报告计通过；局部稳态不代替 | 未运行 |

正常/末边界/错误/取消场景互补；本轮没有TB、激励、仿真、资源映射或功能性脚本。没有以静态JSON执行测试。

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 拟文件（未生成） | TEST | 实际实现/证据 |
|---|---|---|---|---|
| 01原色序/数量PB/PIO | RX_DEC IF01，RENDER IF05，E1/E3 | row_rx_decoder／row_render_write | T01/02/04 | 未实现；静态几何及来源阅读 |
| 02真实完成事件PIO | ROW_OWNER/OUT_OWNER IF02/03/06 | row_context_owner／row adapter | T04/06/08 | 未实现；协议设计，scan阻塞 |
| 03原REPLAY数学/模式 | RENDER IF05 E3 | row_render_write／独立参考 | T01/05 | 未实现；数学来源事实 |
| 04局部吞吐/全期限 | RX_DEC/prefetch IF01/04 E2/E4 | row_prefetch／生产调度 | T02/03/08/10 | 局部条件推导；全服务OPEN |
| 05身份/held历史PIO | 全部IF D1/D2/E4 | ctx owner／适配 | T05/06/08/09 | 未实现；候选局部KEY，完整全球族OPEN |
| 06银行引用/关闭PIO | ROW_OWNER/PIO IF04/06 | owner／adapter | T06/07/09 | 未实现；五ctx上界有明确条件 |

反向：每个拟单元只为上述真实要求；无新增业务要求替未知接口合理化。实际代码/工具证据栏不能填设计审阅为实现通过。

## I. 门槛及评审

①B行为及边界存在；②C责任/复用存在；③D接口候选/相容与缺口存在；④E状态/容量/中文逐沿草图存在；⑤F语言/映射存在但实际语言基线未冻结；⑥B/D/E/G走查有有限范围；⑦G/H实施/测试/双向追踪存在；⑧**不满足，RP-B01…05仍OPEN**；⑨保存后实际读回与独立有限审阅须绑定hash，见独立报告；⑩v0.1/局部范围明确，最终实现输入基线尚无。

NOT_READY_FOR_REVIEW，不请求用户批准这张未闭合卡，不生成业务实现。当前权限只包括只读/控制面文档与追加本地事件；原IP预检本地例外不扩成算法执行。数据库NOT_CONFIGURED及正式state不改。未记录实际聊天批准，不伪称Manifest已授本卡权限。

## J. 差异、反馈及恢复

本卡澄清720逻辑写事件与2880native laneWE、writer每pair2/3词与reader每pair3/4词、物理R/G/B与canonical排列，以及input引用早于整行退休的独立返回。采用JOIN退休后下一沿RE，相较同沿free→reserve候选多一个启动沿，并保留缓存约束。

RP-B03两候选：①提前预留唯一执行scan token，实际VSYNC仅在真首行/事件/资源资格成立时绑定并APPLIED；取消必须真close，预留与当前/closing/fallback不能隐藏第4ctx。②使用prepare_id提前准备，真实VSYNC后两阶段绑定实际scan，需要完整ROW/held协议修订。当前没有选定、没有改PIO L157/163/222，也不在ROW体填未来真实事件。candidate未选时如何合法重复旧active、firstrow期限与pending预约归还均须联合证明。

若改公开P4边界、双行流水、银行数、scan分配、packed族/原因枚举或资源模型，属于重要结构/行为变化，须新版本与独立审阅/指定批准。恢复核A源hash及审阅精确输入；旧来源和审阅不自动覆盖新hash。

## K. 实录

本卡只有来源阅读、静态几何/算术文件和有限设计审阅；没有RTL/C++/功能脚本/TB、工作工程修改、IP重生成、仿真、综合、PNR、STA、bit/hex或硬件动作。来源Efinity实际参考综合通过属于原预检报告，不是本卡通过。审阅范围/输入hash/修订与限制保存到独立报告；未作用户理解验收。

## L. 交付阅读

先整合A/B/C，再本B/C、D完整身份/交接、E1填料→E2预取→E3数学写入→E4收尾及预算，最后F/G/H与未闭合I。术语FULL是输入封存、READY是输出行完成、APPLIED是物理扫描真采用，RETURN是独立银行租约结束；不能互换。实际代码、文档注释一致性和功能验收均待实现/运行，理解验收待用户实际作答。完整软件测试目标仍未完成。
