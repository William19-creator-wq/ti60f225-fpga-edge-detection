# TRACK4-ALGORITHM-REPLAY-001：完整结果借用、独立重放与像素渲染设计 v0.2

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。属于[R2主稿](design-TRACK4-ALGORITHM-R2-001.md)B03的renderer/replay局部候选；本页没有完整帧存储、最终Canny实现或固定视频输出的现成证明。

## 通用计划字段

- Goal：把完整结果/render快照、三个独立可暂停plane、显示访问计划、灰度/选色及错误关闭形成可检查的有界局部合同。
- Current state：原DISPLAY纯数值、控制显示来源整理、R2/C0/OBS和逐文件合同已实际读取；本页按实际独立审阅修订为v0.2，仅设计，无业务实现。
- Target state：完整1920×1080及合法小图具有明确owner、identity、required plane、请求credit、关闭证书、held输出、终态和独立验证；相关父层冻结后再纳入整包READY。
- Gap：R4完整bundle/实际重放provider、profile实体、配置/dispatcher联合接口及R5固定视频/最终资源均OPEN；本文还须全文读回和独立审阅。
- Assumptions：单core域、所有局部输入/输出可暂停；静态W偶数6…1920、H5…1080；生产1920×1080；共同同步高rst的合法前提见F/G。
- Open questions：见A阻塞；不假定存在帧存储/重放能力，不恢复识别对象尺寸/数量/噪声限制，不调查用户指定外部存储器件。
- Dependencies：唯一根v0.2、模板、BATCH/R2、原DISPLAY纯D1/D2/OP05、control-display来源整理及R2-FILES；不继承旧物理scope/grant/3row bank/固定scan生命周期。
- Milestones：整体/owner→接口和有界汇合→中文逐沿→数值/关闭证明→完整文件/参考/测试→联合审阅→整包指定批准→获批实施/验证。
- Detailed steps：B行为→C路径→D接口/访问计划→E状态/credit/关闭→F三份契约→G/H验证追踪→I门槛。
- State transitions：仅本设计LOCAL_DESIGN；不修改正式H0/状态/Manifest/数据库，不把保存文档当新实现批准。
- Artifacts and hashes：A列实际读取的来源hash；本页hash由保存后读回报告绑定，不自包含；当前不是实施基线。
- Validation：文档/字段/来源检查与功能测试、完整算法验证、生产工具结果分开；全部TEST NOT_RUN。
- Failure handling：保留真实不同前缀；坏RR不能清期望credit；ABORT独立CLOSE可结清credit；无完整闭合证书QUARANTINED保留borrow。
- Human approval gates：完整软件设计包指定版本/范围/基线；本文NOT_READY，不请求或冒称单页实施批准；原工作副本/构建/数据库前置继续适用。
- Rollback：本轮只新增本纯设计文件；原来源、其他文档、工具、业务工作目录保持；未来只在获批work实施。
- Completion criteria：本页局部文字齐全并不关闭全部B03/B05；实际provider和跨批完成合同、真实数学/协议/工具证据及统一批准仍必需。

## A. 状态、来源与阅读入口

关联R2-REQ08、BAT-REQ04及原T4-B4/A2/A5/A6显示数学责任。整体读[整包B/C/D](design-TRACK4-ALGORITHM-BATCH-001.md)→[R2](design-TRACK4-ALGORITHM-R2-001.md)→本B/C/D→E/F/G/H。原T4-A3源冻结保持DEFERRED；本plan不是冻结源实施、摄像接入或HDMI60Hz。用户询问新设计批准的含义不是批准本文；当前没有本页业务实现授权。

| 实际来源 | SHA256及采用范围 |
|---|---|
| [唯一根v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md) | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；设计/语言/批准规则 |
| [模板](PLAN_TEMPLATE.md) | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79；通用字段及A–L |
| [BATCH v0.3](design-TRACK4-ALGORITHM-BATCH-001.md) | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7；完整目标/跨批边界 |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2；B03/原RGB与最终edge及新OBS组合 |
| [DISPLAY](design-TRACK4-DISPLAY-001.md) | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717；仅明确采用D1/D2/OP05的数值/模式/lane，旧物理生命周期不继承 |
| [来源整理](../experiments/track4_algorithms_20261004/02_design/control-display-source-contracts-v0.1.md) | 192D9DCED0F1189E6804423040BA45FDAD6DAE8F00B9D87893DE31E649DD91A0；CFG/render/preset事实与OPEN交接 |
| [R2-FILES候选](design-TRACK4-ALGORITHM-R2-FILES-001.md) | E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842；文件/独立参考/向量/前缀/运行器边界，未完整冻结 |

源码/工程当前未生成，无Git基线不伪造commit。所有下述端口、稳定符号和文件都是新提议。来源hash绑定本次读取时的内容；父稿继续修订时重新读回，不将链接视作永久冻结。

| BLOCKING | 影响/缺口/下一方法 |
|---|---|
| BR-B01 | REQ01/IF02：R4/dispatcher尚未冻结唯一completed-bundle owner、成功完成证书、SRC保存和全图最终EDGE/ANN真实provider；由父设计给实际逻辑容量、提交与借用来源 |
| BR-B02 | REQ01/03/IF01/02：配置owner、processing job、render generation、完整RC profile实体及完成结果映射联合接口OPEN；与新CTRL/dispatcher合同逐字段合并 |
| BR-B03 | REQ02/04/IF03/04/07：实际provider的坐标重放/错误接纳/独立CLOSE与真实ledger证明OPEN；要求正常和wrong-echo关闭走查，不能仅补一个ready |
| BR-B04 | REQ05：R5固定视频/CDC/相关clock/60Hz/QoS/最终生产pin与时序及完整资源OPEN；本文可暂停输出不替代它 |
| BR-B05 | REQ06：完整计划文件/精确套件/有限timeout/实际工具引用及独立审阅尚未并入B05；本文保存/读回后继续设计 |

可独立继续本文接口、数学、credit/关闭和参考/追踪审阅。存在以上阻塞，不标READY，不向用户提出空泛实现批准。

## B. 整体外部行为

| REQ | 明确行为 |
|---|---|
| BR-REQ01 | 只接受唯一owner证明完成且同source/job/config的结果和不可变render快照；SRC metadata始终存在；最终EDGE不是R2 class |
| BR-REQ02 | source/display/plan/job身份和坐标分开；三个独立可暂停source按显式坐标请求有界汇合；不接一个live RGB tap等待最终edge |
| BR-REQ03 | 六业务mode、原灰度、canonical lane/颜色/开关/ANN优先及held输出逐位确定；snapshot不受外部当前配置影响 |
| BR-REQ04 | 每口真实fire分别计；错误/取消保留前缀、作废私有后缀；wrong-key不能清credit，CLOSE不等待credit，借用只凭正确关闭证书返还 |
| BR-REQ05 | 生产完整1920×1080不变；小图只补边界；可暂停算法、固定视频、实际资源/STA分别证明 |
| BR-REQ06 | 整体→局部→交接→中文旧状态事件→独立参考/测试/文件双向追踪；保存文档不冒称已实现或通过 |

正常：合法mode5完整结果→OPEN成功→SRC/EDGE/ANN独立读同一坐标→ANN非0覆盖彩边背景→OUT恰P个pair→全部来源关闭及borrow实际释放→SUCCESS。边界：mode0显示y539取源1078的原灰度、y540取源0的最终EDGE；完整算法仍处理全部1080行。失败：SRC坏echo实际fire后raw计数增加、原credit保留，不汇合；P进入ABORT并发正确身份CLOSE；正确source闭合证书可将这份credit以失败关闭结清，不能补零后成功。

黑色值/ANN00/空目标全零合法map是有效数据；无RR、未COMPLETE或失败RR不是黑色数据。没有provider进展或OUT消费时可以停顿，不能用安静时间宣称empty/drained。未证明关闭进入隔离并保留borrow，不释放他人对象。

## C. 职责、唯一owner与整体连接

| MOD | 责任、拥有数据及边界 |
|---|---|
| BR-MOD-O completed-bundle owner | 唯一拥有SRC/最终EDGE/ANN及完成证书、不可变processing/render snapshot、borrow目录；唯一授予/释放只读借用。是R4/dispatcher待实现父职责，不是本文提供了存储 |
| BR-MOD-P replay-plan controller | 唯一保存PLAN/borrow/访问游标、每plane请求与credit/响应slot、真实ledger、错误与终态；不计算最终Canny、不写图 |
| BR-MOD-R/E/A replay sources | 各自兑现SRC/最终EDGE/ANN请求并拥有自己的pending读取/held回复/真实ledger/closed证书；独立ready，不等待其他plane JOIN |
| BR-MOD-M pair renderer | 四级原灰度/选色、全sideband及held OUT；不拥有完成结果，不修改render快照 |

普通文本数据路径：父提交PLAN616(IF01)→P校验→O OPEN619/REPLY888(IF02)授予只读borrow→P按display坐标生成三独立RQ360(IF03)→source RR421(IF04)→P JOIN413(IF05)→M四级→OUT404(IF06)。控制关闭路径：错误/取消(IF09)→P ABORT→每source CLOSE338/ACK437(IF07)→O RELEASE288/ACK296(IF08)→TERMINAL1171(IF10)→消费/GAP→下个plan。

owner生命周期：BUILD尚不可渲染→真实完整算法及图提交后COMPLETE→OPEN授予borrow并进入BORROWED→所有旧借用真实返还后再RECLAIMABLE。具体对象容量/分配属于BR-B01，不能仅因result_id存在进入COMPLETE。SRC在处理阶段由父源拥有者维护；完成bundle owner统一持有其合法引用，不能让两个owner各自宣布SRC可以回收。

P最多一个plan。锁定PLAN和borrow一直覆盖请求/响应/算术/OUT/关闭；RELEASE_ACK后不再有图引用，但PLAN及终态值仍保存到TERMINAL实际消费。source只借当前授权plan，物理端口不得混用另一active plan的响应；共享底层存储由source适配层提供真实隔离，尚BR-B03。坏RR所填身份不被当作他人对象的有效授权。

有限容量：一个PLAN、一个OPEN事务/回复接收位置；每plane一个held RQ、一个期望credit、一个held RR；四级数学valid槽（P4就是OUT槽）；每plane一个CLOSE事务及证书位置；一个RELEASE事务；一个取消回复；一个TERMINAL。逻辑字段可引用不可变ctx，生命周期不得短于最后借用。本局部没有整帧FIFO、三row bank或隐藏第四帧。

整体检查点：本B/C/D先明确完整结果才能重放、坐标驱动独立source、有限汇合、wrong-key保留credit与独立关闭；进入E详细事件设计。R4实际provider和R5固定scan未闭合，不能把本检查点写成完整B03已完成。

## D. 身份、接口、访问计划与组合检查

### D1. 数值与命名身份

全部body字段unsigned，只有颜色通道8bit；valid/ready单独，不计入body。单core上升沿前valid与ready同为1为fire，rst高时全fire0。body从列出的最后字段占最低位向高位排列；组合字段内按后述低位布局；实际实现可用命名独立端口，但向量/适配必须同schema。

PLAN616依次为job96/source_image_id64/result_id64/render_generation64/display_id64/plan_id64/W11/H11/algorithm2/profile_ref64/render112。job96内部low-first epoch32、frame32、config32，允许0。source/result/render generation按明确owner有效性与完整相等判断，0不隐含空。plan/display由父在当前epoch内各自分配1…最大值的新序号，不回绕；相同结果重复执行使用新display和plan。它们不能用job/source ID替代。borrow_id与plane_ref为64bit非0合法handle，0保留为未借用/不存在。seq21为本plan display pair序号，不用它猜borrow。

render112低位布局为mode[2:0]、split_y[13:3]、edgeRGB[37:14]、ANN01RGB[61:38]、ANN10RGB[85:62]、ANN11RGB[109:86]、show_edge110、show_ann111。RGB24每lane R高8/G中8/B低8。algorithm0SOBEL、1CANNY、2CANNY_RC、3非法；mode0…5业务，6本地诊断不接PLAN，7非法；mode5必须algorithm2。非RC profile_ref规范0；RC要求非0且由O核完整不可变参数实体，不能只信编号。

### D2. IF完整body、前提与持有

| IF | 方向与body位宽/字段 | 前提、保持、失败及副作用 |
|---|---|---|
| BR-IF01 PLAN | 父→P，PLAN616 | 仅IDLE且旧终态已消费/旧借用结束可ready；接纳沿不发RQ；完整输入即使非法也保存并在无借用情况下形成明确失败，不猜别人handle |
| BR-IF02 OPEN/REPLY | P→O OPEN619=PLAN616/global_required3；O→P REPLY888=原OPEN619/status2/reason5/borrow64/三个plane_ref64/complete_mask3/replay_mask3 | status0/reason0成功、status1/合法非0 reason拒绝，2/3或原因不规范非法；held OPEN不得取消撤销；回复独立ready，不等OUT或P。成功保证完整证书/同源/快照绑定、完整只读借用和source服务资格；失败borrow/ref/mask全0 |
| BR-IF03 RQ | P→三source独立RQ360=job96/plan64/display64/borrow64/seq21/source_x11/source_y11/display_x11/display_y11/display SOF/EOL/EOF3/plane_first1/plane_last1/plane2 | plane0SRC/1EDGE/2ANN，3非法；来源绑定由OPEN ctx解引用，不按未核payload寻址；每口最多一个期望credit和一个held RQ |
| BR-IF04 RR | 三source→P RR421=原RQ360/status2/reason5/data54 | status0成功值、1明确失败，2/3非法；至少在RQ fire后后续沿返回；必须回显完整RQ。每source独立保存回复，不能等另一plane/JOIN |
| BR-IF05 JOIN | P→M JOIN413=RQ去plane2及plane_first/last2后的356bit/data54/joined_mask3 | required每口正确匹配且数值/规范合格才fire，至少在最后RR fire后的后续沿；不透传或补缺平面0 |
| BR-IF06 OUT | M→后续可暂停接收方 OUT404=job96/plan64/display64/render_generation64/seq21/source_xy22/display_xy22/SOF-EOL-EOF3/RGB48 | P4完整保持到fire；接收方不能凭帧序猜source；OUT真实fire才计输出和合法EOF，不能由形成代替 |
| BR-IF07 CLOSE/ACK | P→source CLOSE338=H288/plane2/request_cutoff21/reason5/last_req_seq_valid1/last_req_seq21；source→P ACK437=原CLOSE338/actual_request21/actual_raw_response21/settled_request21/overflow3/actual_last_seq_valid1/actual_last_seq21/request_closed1/read_closed1/response_closed1/closed1/status2/reason5 | H288=job96/plan64/display64/borrow64。suffix status0/reason0且正确身份/截止/最终真实ledger/四闭合位及无overflow才是证书；不等待P的good数、JOIN、client credit。详见E4；suffix status0/reason0证书成功、status1/合法非0 reason明确不能证明，2/3或原因不规范非法；echo中的原CLOSE.reason可以为取消/错误非0，不与suffix混读 |
| BR-IF08 RELEASE/ACK | P→O RELEASE288=H288；O→P ACK296=原RELEASE288/status2/reason5/released1 | 全required source有效证书＋本地引用空之后；实际完整匹配status0/reason0/released1才返还，status1/合法非0 reason/released0明确失败，2/3非法；不使用坏RR借用身份 |
| BR-IF09 CANCEL/ACK | 父→P CANCEL224=job96/plan64/display64；P→父 ACK231=原CANCEL224/status2/reason5 | 独立depth1回复，0APPLIED/1ALREADY/2NO_MATCH、3非法；只对沿前活动身份，IDLE同沿新PLAN不能被旧取消套用。取消回复不代终态 |
| BR-IF10 TERMINAL | P→父 RT1171，D5完整字段 | 正常/失败排空后或明示隔离快照形成；全文held，消费沿不接下一PLAN；Q消费也不解除borrow |

data54 low-first RGB[47:0]/EDGE[49:48]/ANN[53:50]。SRC回复只RGB可以非0，EDGE回复只EDGE，ANN回复只ANN，其余0；失败回复status1/data全0、reason为合法非0；成功回复status0/reason0。status/原因不规范、保留原因或非required数据非0都按坏RR计raw并失败，不因status0独自清credit。EDGE bit0/1分别lane0/1；ANN低2bit lane0、高2bit lane1。JOIN将不required数值位置规范0，但joined_mask仅等于本行真实required，不能把规范0当已完成平面。SRC/EDGE/ANN实际值无alpha/gamma。

OPEN成功时SRC ref始终非0；需要的EDGE/ANN ref非0，不需要的EDGE/ANN ref规范0。global_required bit0SRC/1EDGE/2ANN；complete_mask=global_required OR 001，replay_mask=global_required。mode3没有SRC读取仍须完整原源metadata。mask由唯一O的真实证书保证，不是调用方填位即可成功。模式1/2不读取edge不免除父processing job成功完成要求。RC即使show_ann0也须合法profile；mode5不因开关0免除ANN完整资格。

### D3. 坐标访问、数量及plane last

构建静态W偶数6…1920、H5…1080，PLAN须等于实例；生产W1920/H1080、D960、P1036800 pair、N2073600 pixel。所有mode split_y=floor(H/2)，生产540；mode0要求偶H，因此集成小图mode0最小6×6。6×5可以其他mode，不能上下2:1比较；小图范围是流段测试实例，不限定生产识别目标。

display pair行优先，q0…D−1，x=2q，y0…H−1，seq=yD+q。mode1…5 source/display坐标相同。mode0上半sy=2dy，下半sy=2(dy−split_y)，sx=dx；上半row_required001，下半010。生产y539/540/1079分别sy1078/0/1078。逻辑偶行访问序列为0,2…1078再0,2…1078；实际SRC上半一次、EDGE下半一次，不误写成每个plane都读取两遍。

| mode | global mask / row mask | 每plane正常期望E[p] |
|---|---|---|
| 0 | 011，上001/下010 | SRC=P/2、EDGE=P/2、ANN0，生产各518400 |
| 1/2 | 001 / 001 | SRC=P，其他0 |
| 3 | 010 / 010 | EDGE=P，其他0，SRCmetadata仍在 |
| 4 | 011 / 011 | SRC/EDGE各P，ANN0 |
| 5 | 111 / 111 | 三plane各P |

display SOF只seq0、EOL只q=D−1、EOF只seq=P−1。plane_first/last按该plane在本plan访问集合计算：mode0 SRC最后在上半末pair，plane_last1且display EOF0；EDGE首在下半首pair，plane_first1且display SOF0。其他启用plane first/last与全图首末相同。无需等待未访问源奇数末行的图EOF；完整源图资格在OPEN前已经证明，和重放plane_last/OUT EOF是不同事实。

### D4. 有界汇合和组合走查

RUN各required口先按E2.3的issued/旧held/credit/RRslot谓词保存RQ，RQ fire后保存完整expected_rq和credit1，并预留自己的RR slot。RR ready由本slot容量/当前source session决定，不能由echo匹配组合反馈抹掉坏fire。收到正确完整RR、status/规范合法才结清该credit；成功值另记good并保存待JOIN，合法匹配失败回复结清credit但不记good，触发失败。wrong-key/坐标/标志/pad/非法status的坏RR只记raw及错误，保留原credit，不解引用其borrow。

required RR全部属于当前seq、borrow、job和source坐标且合格，M可advance才JOIN；各支一次。JOIN fire后推进独立join游标并清已消费RRslot/下一组issued；该沿不穿透创建新RQ，后续旧RUN沿才按新游标及E2.3全部条件建立RQ，不从OUT fire反推source游标。最多一个当前未汇合pair和四个数学pair，源可以不同步返回但不建立无界缓存。OUT反压可冻结数学；既有RQ仍允许兑现到预留slot。SRC不会等待未来edge产生，provider从已经完成的不可变结果供给；一个活流RGB tap等待edge会反压FE窗填充，本设计不连接该拓扑。

模式5普通路径：完整同源OPEN→三个RQ各实际fire→RR先后进入各slot→完整JOIN→原灰度/选色→OUT held/fire→P组完毕→三个独立CLOSE正确证书→借用释放→SUCCESS。错误路径：坏SRC RR fire→raw增加/credit保留→下一ABORT不JOIN→held其他RQ继续兑现→正确SRC CLOSE不用等待该credit→证书settled/cutoff/closed证明原请求结束→credit以失败关闭结清→其他来源/OUT结清→FAILED_DRAINED。

每source必须在已开启plan中保证held RQ最终接纳，并能在服务失败后以合法匹配失败RR或独立关闭证书兑现；不能因backend故障永久拒绝早已提出请求又声称关闭。该有限进展合同及底层读取关闭机制仍BR-B03，不以文档承诺代实际provider证据。

### D5. 错误与完整终态布局

reason5：0NONE、1PLAN_FIELD、2BINDING、3NOT_COMPLETE、4REPLAY_UNSUPPORTED、5VALUE_FORMAT、6KEY_COORD、7COUNT_MARK、8SOURCE_FAILED、9CANCEL、10SOURCE_CLOSE、11BUNDLE_RELEASE、12OVERFLOW、13PROTOCOL、14EXHAUSTED，15…31保留非法。mask32按非0reason相应bit置1。首次错误的reason/位置锁定，后续只OR mask；同沿priority为plan/open检查→SRC→EDGE→ANN→各close SRC/EDGE/ANN→release→cancel，同来源依先key/规范再count/值/失败码检查。

RT1171依次为原PLAN616/borrow64/status2/first_reason5/error_mask32/loc69/flags26/每plane四类计数252/join_count21/out_count21/source_settled_count三项63。loc69=loc_valid1/lane1/plane2/seq21/source_xy22/display_xy22；无定位valid0、plane3、其他0；非法原坐标只记证据不用于读地址。flags26=open_seen/bundle_release_seen/local_empty/cancel_seen/output_eof_seen/drained各1、source_closed3/plane_last_seen3/counter_overflow14。四类计数为request/raw_response/good_response/joined_contribution，每类三个21bit；末63为已收到有效source证书中的settled count，未有证书字段0不能表示成功。

status2：0SUCCESS、1FAILED_DRAINED、2CANCELLED_DRAINED、3QUARANTINED。合法SOURCE_FAILED回复是失败，不是成功黑值。drained1表示本地及全部已取得义务结清；open_seen0的非法PLAN没有取得borrow可合法failed_drained，不能强求不存在release ACK。Q必须drained0且保留borrow/未结事实，不因后续安静改为成功。

成功在SETTLE的后续沿根据旧已保存事实形成：OPEN真实成功；每required plane request/raw/good/joined贡献均等自身E[p]；join/out各P；正确OUT EOF实际fire和所需plane_last实际观察；无错误/取消/overflow；每required source有效证书的source_settled_count亦等E[p]（request=cutoff=actual_request=settled，未启用口为0）；全部来源有效证书、本地empty、borrow真实释放。各口工作中及失败时计数可以不同，不能强制相等。empty在开始前也能为真，不单独触发成功。

## E. 局部状态、数据及中文操作草图

### E1. P的保存数据与不变量

P拥有immutable PLAN、borrow/plane_refs/masks、join q10/y11/seq21、每planeRQ held/expected_rq/credit/RR held/issued_current_seq1、14项21bit ledger及overflow、plane_first/last观察、source关闭证书、first_reason/loc/mask、cancel事实、RT held；另保存bound_epoch32/valid及本epoch的last_admitted_plan/display各64bit及seen资格。合法共同reset清bound_valid和seen；父必须保证首次PLAN属于授权session。首次完整合法VALIDATE成功准入才锁bound_epoch并同时推进两高水位；随后job.epoch必须等bound_epoch，两新序号均非0且分别严格大于已有高水位。PLAN接纳只锁输入/旧检查事实，不改高水位；VALIDATE任一项失败均不更新seen/epoch/高水位，更不能下调；后续OPEN拒绝仍消耗已准入序号，不重用。不同PLAN.epoch明确拒绝，不授权清任何旧借用或高水位。跨优雅软件reset需唯一RESET_OWNER授权epoch更新，且旧plan真实关闭/终态消费/GAP结束、无borrow/未知OPEN义务或held事务、非Q；具体消息/真实接纳证据及与O/sources同步仍BR-B02，未冻结前不能声称跨软件epoch重放已完成。M拥有P1…P4各自valid/数据/sideband；O和sources拥有自己的存储/borrow/请求/读取/响应账本。

INV01：源对象/build完成由O独占，P只有只读借用；INV02：每口credit只在RQ fire建立，合格匹配RR或正确CLOSE证书结清，坏echo不清；INV03：JOIN恰收required，source/display/plan/job不混；INV04：所有published held body稳定，私有flush不抹旧fire；INV05：CLOSE独立于client credit/JOIN/OUT数量；INV06：借用只按锁定OPEN handle和完整证书返还；INV07：OUT前缀按seq连续、成功恰P；INV08：Q保留borrow且不自动恢复；INV09：每个正常计数基于本口真实fire，EOF/empty/证书不是同一个事实。

P状态：IDLE→VALIDATE→OPEN_WAIT→RUN→DRAIN→CLOSE_SOURCES→RELEASE_BUNDLE→SETTLE→STATUS→GAP→IDLE；错误/取消走ABORT_DRAIN，闭合证明明确无效走QUARANTINE_DRAIN→Q_STATUS→QUARANTINE。各状态同时允许的旧RQ/RR/OUT/control履约按E3/E4执行，不把状态名当撤valid许可。

### E2. BR-OP01 接纳、OPEN和请求/JOIN

1. IDLE沿接PLAN，锁全文及供校验的旧epoch/高水位；rst沿fire0。VALIDATE下一沿核静态尺寸/规范split/algorithm-mode/profile、bound_epoch及两新plan/display序号；只有全通过才原子推进两高水位并准入（首次同时锁授权session的bound_epoch）。非法不改高水位、不发OPEN/RQ，锁PLAN_FIELD或epoch不符的BINDING失败；同沿取消只核旧active。
2. 合法后建立held OPEN并预留回复位置。OPEN提出未fire时取消仍保持；若取消发生在尚未提出OPEN之前，不再创建新OPEN。成功回复须逐字段匹配原OPEN、status0/reason0、非0borrow/required ref及D2规范mask，再保存资格，成为旧事实后才RUN。合法匹配拒绝须borrow/ref/mask0，可无借用失败结算。wrong/非法OPEN回复不当成未取得借用的证明，不使用其raw handle读取或返还；保留原OPEN可能已经授予的未知义务并进入Q，RT借用字段只报告已验证handle，0不能被解释成O已无借用。实际O的异常OPEN回复处置/恢复仍须BR-B01/B03父合同闭合。
3. RUN按当前join游标计算display/source坐标和required，建立每口held RQ。RQ实际fire才request_count增加/credit置1，不在valid等待时累计。每口最多一个未结及一个响应slot。建立held RQ的沿即设issued_current_seq[p]=1，不等RQ fire才置位。新RQ只在该plane本行required、旧issued为0、旧held RQ空、旧credit=0及旧RRslot空时创建。正确RR清credit后issued仍1；RRslot满或JOIN/数学停顿均不能再次请求同seq。仅该seq真实JOIN fire、进入下一seq时统一清下一组issued标记；未启用plane始终不发RQ。ABORT不清标记以重提，合法新plan/共同reset才重新初始化。
4. RR实际fire先raw++并核完整expected_rq。正确完整匹配status0/reason0且数值/unused字段规范时存RR，good++、credit清；正确完整匹配status1/合法非0 reason且data全0时失败清credit、good不增，锁SOURCE_FAILED。坏echo/规范只raw++、保留credit并锁错误；不得按坏body释放handle。无期望credit的RR也是协议错误，不当成新像素。
5. 最后一required RR保存后至少下一沿JOIN；JOIN fire分别增加required joined_contribution和总join_count，推进q/y/seq、清该组RRslot及下一组issued；同沿不穿透创建新RQ，后续旧RUN沿才按新坐标建立。没有新输入就插bubble，不将valid0解释为0。
6. join_count=P后不创建新RQ，进入DRAIN；数学/OUT/source关闭继续。收到cancel/错误的真实边沿先计所有旧fire，下一旧ABORT周期开始私有清理。

### E3. BR-OP02 四级灰度/选色和held输出

P1保存每lane77R/150G/29B共六个unsigned16乘积，并延迟原RGB/EDGE/ANN/render引用和共同sideband。P2基于旧P1求每lane16bit sum+128；P3取旧sum[15:8]形成两Y8；P4按旧P3与该pair冻结render形成RGB48及OUT404。p级接受e0后末级在e(p−1)后形成，最早e(p)交付；本四级JOIN e0、OUT最早e4 fire。真实provider/汇合等待不计成固定延迟。

统一advance为旧P4空或该沿OUT能fire；每级仅由旧级形成新级，没有输入插valid0。P4不被接收则所有P1…4及sideband保持；source现有响应仍可进入预留slot，但JOIN停。外部颜色/mode/阈值变化不读取。

mode0上原灰度/下EDGE白黑；mode1原RGB；mode2原灰度；mode3 EDGE白黑；mode4 show_edge且EDGE1以edgeRGB替换；mode5先mode4再show_ann且ANN非0用相应ANN色替换。ANN00不覆盖，11为文字/异类冲突且仍优先EDGE。mode0/3忽略edgeRGB和show_edge；开关不免除plane验证。默认edge FF0000、ANN01 00FF00、ANN10 00A0FF、ANN11 FFFF00。

ABORT下一旧状态清P1…3且禁止再向P4装入；旧P4已published仍保持到OUT fire，不能把它算作私有槽撤掉。错误观察沿若旧RUN仍有旧P3推进进入P4，它成为已提出的合法前缀值，后续同样保持；所有旧实际OUT fire照计。

### E4. BR-OP03 ABORT、wrong-key信用与独立CLOSE

1. 首次坏RR/取消沿先记录真实request/raw/JOIN/OUT fire及首次位置；坏RR不投JOIN，不清expected credit。下一ABORT停新RQ/JOIN，丢私有未汇合值和P1…3；旧held RQ和P4兑现。
2. ABORT每个已opened source的RR ready只依预留接收容量，独立于credit是否仍在或echo是否匹配。实际RR均记raw；合法匹配RR可结credit，坏RR只记错误。数据值不再JOIN。不能因wrong-key credit仍1而关RR或禁止CLOSE。
3. 每口等自己的held RQ真实fire/不再有未曝光RQ提议即可建立CLOSE；不等credit、good、RR slot、JOIN、P/EOF或OUT。cutoff锁该口真实request_count及last_req_seq_valid/值。P从此不给该source新RQ；其已接受请求与本地私有RR数值不阻独立CLOSE。
4. source CLOSE ready及ACK通道独立于data/JOIN。CLOSE fire封住该plan新增读取；旧已接受读取必须真实完成或安全取消，已published held RR必须实际交付，不能撤valid。未形成回复的请求可在真实旧读取/effect关闭后以取消结算，而不是伪造RR。
5. source的settled_request_count记录每份已接受请求已实际回复fire或已在CLOSE后安全取消且读取/effect结清；不是good-response数，也不是简单复制raw-response数。source只等自己实际接受请求、旧读取、私有pending、held RR结束，不等P的匹配credit消失。
6. source须在末RR真实fire后的后续旧全闭合状态形成ACK437：回显正确CLOSE全文；actual_request等cutoff且last_seq与截止一致；cutoff0时两份last_seq_valid0/last_seq0，非0时valid1/值等最后真实请求的全局display seq；settled_request等actual_request；actual_raw_response等该物理source口真实RR fire ledger；三overflow0；request/read/response_closed和closed全1。没有RR的零请求/安全取消路径按旧全闭合状态形成，不等待不存在的末RR。ACK valid期间该口RQ ready0、RR valid0，不能同时再发旧读结果。
7. P始终可接期望source的ACK，不以credit或输出empty门控。先核suffix status0/reason0，再核正确锁定H/plane/cutoff/last_seq、真实request/raw两端ledger、settled和四闭合位、无overflow后记source_closed1，并将原credit以失败关闭结清；不伪造good/JOIN/EOF。这允许坏echo已经物理交付而source无剩余读取时完成失败关闭。
8. 不把坏RR的borrow当他人授权，也不假定错echo就是他人对象而释放。绑定和返还仅用OPEN所得期望borrow；source物理端口须是当前唯一plan的专用适配边界，底层复用隔离仍须BR-B03实际证明。wrong、suffix非status0/reason0、closed0、overflow或ledger不符ACK不能成为证书，进入隔离，不能清borrow。

同沿规则：CLOSE request fire可与末RR fire同沿，两笔真实ledger均记，ACK只能在后续旧闭合状态形成；正常ACK fire不能与RQ/RR fire同沿。故障注入若ACK与RR同时提出/交付，记录实际RR并判证书不成立，不以新count修补旧held ACK。取消与RQ/OUT/EOF同沿旧交付照计；取消与成功OPEN_REPLY同沿须保存实际borrow再关闭；close ACK与OUT fire可以同沿，返还仍等后续旧本地empty事实。

### E5. BR-OP04 RELEASE、终态与隔离

全部required source有效证书且本地P1…P4/RR私有值空、无held RQ/OPEN后，P提出held RELEASE；不等待父对象FREE。匹配真实status0/reason0/released1成为旧事实后进入SETTLE；suffix reason非0即使status0/released1也不是返还证据，进入既定隔离，不清borrow。至少后续沿检查最终计数/EOF/错误；同沿新匹配取消/错误先记并推迟终态形成，不能拿旧reason0形成成功。首次reason按既定优先冻结。

STATUS保存RT1171到实际消费；之后GAP一沿再IDLE。STATUS期间不再接受data或新PLAN，不更新冻结终态。持续取消回ALREADY，不延迟已形成失败终态，也不改写成功快照。

明确不能证明关闭时QUARANTINE_DRAIN停止新提议，仍兑现已经held的OPEN/RQ/CLOSE/RELEASE及P4。credit不作为隔离通知等待条件。待本地published请求槽无待fire、P4空且私有数学已清，可以冻结RT status3/drained0，记录当前真实前缀/已有证书，进入Q_STATUS；此后关闭RR/ACK接纳，旧source仍可能held的回复保持在source中，borrow留存，因此冻结ledger不被晚回复改写。Q_STATUS通知消费后QUARANTINE，不接新PLAN、不自动RELEASE；Q_STATUS/QUARANTINE中匹配取消仅回ALREADY，不改冻结RT或解除borrow；恢复须合法共同reset或以后单独设计的恢复证明，不能仅见晚ACK/empty自动FREE。

合规source/控制和OUT必须最终兑现已经提出消息，这是终止条件而非固定cycle保证。永久不ready时保持未完成及borrow，不假造drained或强行撤held。没有实际外部事务隔离证明不能使用单端reset解除Q；R5恢复合同仍OPEN。

### E6. BR-OP05 复位与下一plan

共同rst同步高屏蔽所有本域fire，清PLAN有效、credit/data/math/terminal/源服务valid和borrow有效性；不要求清整个图RAM，旧有效身份必须隔离。该取消合法的前提是O/R/E/A/M/P全部参与同一reset且父生命周期合同允许撤所有本软件域borrow；实际外部读取未共同reset或未关闭时不得执行此捷径。新epoch/序号重建在父层处理，不凭seq=0证明旧响应消失。复位撤旧job无RT要求，新完整plan从新OPEN开始。

## F. 语言、数值与三份对应合同

共同灰度为floor((77R+150G+29B+128)/256)，各项先扩unsigned16、最大sum65280/bias65408；纯绿149、黑0、白255。常量77=64+8+4+1、150=128+16+4+2、29=16+8+4+1，移位前扩16bit，部分和不截8bit。颜色24、EDGE2、ANN4无精度损失。mode0 sy倍乘、x+1、W×H先用足够临时位宽，检查坐标范围后才窄化11；q10≤959。P/各pair计数21，increment22检查；合法P+1可表示，任何溢出饱和并记录对应overflow，不回绕。14计数依次为各plane request/raw/good/joined共12，再join/out；实际source证书另有三overflow。

| RTL A–L | 本局部合同/未知 |
|---|---|
| A | D字段、unsigned16灰度单次half-up、显式先扩位、编码/颜色/21+22计数；无未声明alpha/gamma |
| B | 同core上升沿旧valid/ready判fire；TB下降沿驱动、沿后稳定观察；不将NBA后新值用于同沿旧事务 |
| C | IF01…10真实握手；所有源/接收方可暂停；OPEN/最后RR/JOIN/OUT/close/释放分事件 |
| D | valid0无数值；无输入插bubble；三个required缺任一不能JOIN；plane_last/OUT EOF/empty不同 |
| E | 全body、expected_rq和render引用保持；私有ABORT清理不撤published P4/RQ/control；共同rst是明示例外 |
| F | M四级JOIN e0→形成P4 e3后→最早OUT fire e4；provider/汇合等待另计；受source延迟和反压限制，不证明60Hz |
| G | 同步高rst全fire0；清valid/身份不是清图RAM；仅合法共同reset可撤全部borrow，单端外部效果未知不得伪排空 |
| H | PLAN/render原子锁，O核processing/render绑定；外部新颜色/mode不改变旧pair；同沿父commit/job旧C在父合同实现 |
| I | 一个plan、三组depth1 request/credit/response、四算术槽和独立控制/terminal容量；本局部0整帧RAM，实际SRC/EDGE/ANN存储仍R4 OPEN |
| J | 三ID/source/result/render/display/plan/borrow分开；lane0偶列；mode0两遍偶行显示映射；每planeE[p]不同 |
| K | 本局部全部同域，CDC N/A仅对本边界；后续摄像/固定video/session/rst跨域仍R5 OPEN |
| L | SV2009/Ti60F225软件目标；新局部时钟/工程/完整资源未冻结；0新增整帧RAM和常量运算0DSP仅结构候选，非实际综合报告 |

C++未选用，不生成C++映射。未来参考使用Python标准库的独立整图纯函数，输入为不可变原RGB/最终EDGE/ANN、W/H和render snapshot，先核全部长度/值域/required/identity语义再返回新RGB图及source/display访问表；不复制P状态/RQ/credit/流水或使用RTL结果造期望。bool只用于明确开关，拒绝bool冒充尺寸/坐标/颜色整数；失败不返回部分成功图。

共同数值契约：按每display像素直接求source坐标、原灰度和mode/ANN优先，无误差容忍；完整算法edge/ANN来源另由R4独立证明。硬件执行契约：按E实际fire/旧状态/posted held/关闭证书核ledger，函数循环不代表时钟。对应契约：以(job,source,result,plan,display,seq,source_xy,display_xy)逐lane比对合法OUT；失败只核真实前缀和drained/Q事实，不补缺后缀为成功；source关闭证书可结credit但不增加数学good。

向量、manifest与运行器沿R2-FILES的不可变文件条目/独立rows/hash/真实ledger原则，本文新body另需schema版本与bit/hex高padding表并入B05；不能直接使用原候选pixel200/output169或R2 class125格式。实际CLI/精确case表/cycle和wall deadline未冻结，保持BR-B05。

## G. 实施与验证计划（全部未执行）

只有整包指定批准且BR-B01…05闭合后，才在获批work新增replay_plan_controller、three_plane_join、pair_renderer、对应独立reference/TB及source适配。下面只是计划符号类别，具体路径/唯一源复用/包schema须并入B05，不建立工作树，不创建功能脚本或TB。owner及provider不得以空stub冒充实际整图成功。

| TEST | 覆盖/输入与事件 | 期望/方法/观察；状态 |
|---|---|---|
| BR-T01 | REQ01/02/05，生产1920×1080全部六mode完整同源结果 | 每plane各E[p]，OUT恰P/合法EOF，实际ledger及独立整图逐位；NOT_RUN |
| BR-T02 | 6×6 mode0，6×5 mode4及拒绝mode0，生产539/540/1079边界 | 源偶行0/2/4两遍与生产1078/0/1078，合法split，输入完整图不变；NOT_RUN |
| BR-T03 | 黑白/纯RGB/灰阶、lane不同、极值255 | 纯绿149、sum65408、canonical RGB和lane顺序，M四级真实advance；NOT_RUN |
| BR-T04 | EDGE1+ANN00/01/10/11同位置及show四组合/外参扰动 | ANN优先、快照色保持、mode0/3白黑不受彩边开关；NOT_RUN |
| BR-T05 | mode5 show_ann0缺ANN、mode3缺SRCmetadata、class冒充EDGE/坏profile | OPEN明确拒绝，未取得借用不误返还；NOT_RUN |
| BR-T06 | 三source独立有限停顿与OUT停顿、held EOL/EOF；RR成功清credit后RRslot满且JOIN停 | 容量不超界/不互等/全部body保持，issued使同seq每required plane仅一份RQ，旧pending能排空；NOT_RUN |
| BR-T07 | 同坐标wrong job/plan/display/borrow/seq、错坐标/marks/pad/多余RR | raw真实计、credit保留、无JOIN、只用锁定handle，首次定位/后续mask；NOT_RUN |
| BR-T08 | 首/中/末source失败，其他口未结/P4 held，wrong-echo后source没有匹配RR | ABORT独立CLOSE不等credit，正确证书以失败关闭结credit；raw/good不同，不等P/EOF；NOT_RUN |
| BR-T09 | cancel与RQ/RR/JOIN/OUT/末EOF/OPEN成功各同沿 | 旧fire照计；实际取得borrow必须关闭；成功结算不吞同沿取消；NOT_RUN |
| BR-T10 | OPEN/RQ/CLOSE/RELEASE/terminal分别held取消，外mode/颜色持续改 | published body不撤/不改；STATUS ALREADY不改终态；NOT_RUN |
| BR-T11 | CLOSE与末RR同沿、错误ACK与RR同沿、wrong cutoff/ledger/closed0/overflow/release ACK及成功status配非0 suffix reason | 正常ACK后续旧闭合形成，错误证书不能释放；Q保留borrow/credit；NOT_RUN |
| BR-T12 | 全局共同rst各阶段、新plan恢复及非法单端reset反例 | 全fire0、旧身份隔离，新OPEN完整；无外部关闭证明不声称恢复；NOT_RUN |
| BR-T13 | 完整数学与独立事务账本、真实R4最终EDGE/ANN接入 | 数学逐位与真实关闭分别达标，不以数学图/CRC代协议；NOT_RUN |
| BR-T15 | 两高水位初始/递增、非法PLAN后退、OPEN拒绝后重用、错epoch及未授权epoch变化 | VALIDATE合法准入才原子更新；拒旧不退回；PLAN变化不授权清义务；跨软件epoch接口保持BR-B02；NOT_RUN |
| BR-T14 | 实际独立/整包工程、mapper/有效扇出/资源/时序/吞吐 | 新局部及真实provider完整预算、PNR/STA报告，固定视频R5另证明；NOT_RUN |

TB在下降沿驱动、上升沿前判fire、沿后稳定观察；有限停顿采用不可变case/seed和明确上界，不能使source无限随机停顿或撤held。小图可用10ns功能时钟，不能推100MHz实现证据；真实局部/整包core时钟须在R5与新工程冻结。timeout按实际expected请求/响应/数学/关闭及注入停顿数量预算，Q期待其明示隔离完成而非SUCCESS；精确数值尚BR-B05。所有日志/退出码/实际数量/first_reason/RT/close证书及来源hash保留；无工具运行。

## H. 双向追踪

| REQ/来源 | MOD/IF/操作/INV | 计划文件或稳定符号；未生成 | TEST | 当前证据 |
|---|---|---|---|---|
| BR-REQ01 / R2-REQ08/BAT-REQ04 | O/P，IF01/02/07/08，OP01/03/04，INV01/06 | completed_bundle_owner/locked_plan/borrow_snapshot | T01/05/11/13 | 完整来源文字，owner/provider OPEN |
| BR-REQ02 / 原DISPLAY D2 | P/R/E/A，IF03…05，OP01/03，INV02/03/05 | replay_plan_controller/expected_rq/credit/three_plane_join | T02/06/07/08/15 | 新有界接口/credit/epoch高水位草图，未验证 |
| BR-REQ03 / 原DISPLAY OP05 | M，IF05/06，OP02，INV04/07 | pair_renderer/P1…P4/render_snapshot | T03/04/10 | 独立数学来源/四级草图 |
| BR-REQ04 / 派生错误关闭责任 | P/O/sources，IF07…10，OP03/04/05，INV04/06/08/09 | source_close_certificate/failed_credit_settle/terminal_snapshot | T07…12 | 独立ledger/证书候选，未验证 |
| BR-REQ05 / 完整生产目标 | 全局/P/M及R4/R5，D3/F | production_parameters/resource_report/video_adapter | T01/02/13/14 | 生产保持，实际provider/视频/工具OPEN |
| BR-REQ06 / 根v0.2 | 本A–L/B05 | reference/vector_schema/中文注释/操作记录 | 全TEST及一致性核对 | 本页设计，0源码/运行 |

反向每个计划单元只承担上述真实数学、接口/所有权、关闭或验证责任；不新增无关CSR/驱动/显示surface。实际文件/hash/源码符号/波形/报告获批实现后登记。source_settled_count不能引用DUT当前RT生成黄金ledger；包解码、数学图和真实事件三个检查各自独立。

## I. 门槛与评审

①整体/样例见B；②职责/连接/来源见A/C；③接口/适配/容量见D；④局部状态/中文旧事件/失败关闭见E；⑤RTL A–L及三份契约见F；⑥普通/mode0/wrong-key/取消/隔离端到端走查见D/E；⑦实施/验证/追踪见G/H。⑧无阻塞未满足，A五项仍OPEN；⑨保存/实际全文读回/hash和独立审阅由本轮报告另绑定；⑩版本和局部范围明确但整包实施基线未冻结。因此保持LOCAL_DESIGN / NOT_READY / NOT_APPROVED，不把本文作为指定实施版本请求。

原Manifest/正式状态/数据库未写入。当前授权只覆盖设计文档创建及读回；不产生业务RTL、reference、功能脚本、TB/project/peri/SDC，也不运行仿真/综合/PNR/STA。待全部相关设计成熟后由父整包统一呈现具体版本、范围、基线和条件，等待用户明确批准。

## J. 变更与恢复

相对来源候选pixel200/output169，本页新增独立source/result/render/display/plan身份、真实OPEN只读borrow、RQ/RR/required JOIN、plane first/last、四级可暂停OUT、错误前缀/CLOSE证书/RELEASE及RT1171；不改变R1/FE、C0、OBS已冻结schema。原DISPLAY的scope/grant、固定scan、3bank、VSYNC/freeze和serializer不继承。

v0.1实际内容已同hash保存在[原稿快照](design-TRACK4-ALGORITHM-REPLAY-001-v0.1.md)。v0.2按独立数值/协议审阅补issued与RRslot创建条件、VALIDATE双高水位单调更新/epoch授权边界、成功reply suffix reason0门槛及T06/T11/T15；新稿须全文读回和修订复核，不将旧hash审阅当新稿通过。

相对首次文字候选，wrong RR不再含糊地取消期望credit：保留到合格匹配RR或正确source闭合证书；ABORT CLOSE不等credit，ACK增加settled_request/last_seq/三ledger overflow及独立闭合证据，消除client等待回应而source等待client认领的环。此为批准前重要行为选择，须独立审阅及父provider吸收。

改变坐标/mask/灰度/开关/identity/容量/held例外/credit/证书/复位/资源时先回REQ/IF/OP/TEST修订，不沿旧批准悄改。恢复重新读原规则、最新主稿/本文/完整来源和真实批准，核相邻source关闭与R4/R5状态；没有运行PASS可供继承。

## K. 实现与验证实录

本轮只有指定纯设计文件创建、实际来源读取、字段算术和全文读回；业务源码/模型/TB/功能脚本/工程/peri/SDC均未生成。功能仿真、综合、PNR、STA、bit、实体输入/视频/下载全部NOT_RUN。无网络/安装/器件相关调查；原HDK、其他计划、正式状态/Manifest/数据库保持。

本文0整帧RAM/常量数学0DSP只是局部结构候选。它不含实际RGB帧/最终EDGE/ANN provider，不并入OBS≤22000XLR/28RAM预算，也不以字段bit数推算实际XLR。最终完整源存储、实例/逻辑裁剪、吞吐和时序由R4/R5提供实际证据。

## L. 中文阅读和交付说明

整包→R2 B03来源→本B最终结果→C owner路径→D PLAN/OPEN/RQ/RR/JOIN/OUT/CLOSE/RT→E1保存数据→OP01接纳汇合→OP02灰度选色→OP03错echo及独立关闭→OP04返还/终态/Q→OP05复位→F/G/H。完整普通路径为合法完成结果→真实OPEN→每plane独立请求/响应→required JOIN→四级OUT→各source闭合证书→borrow返还→RT消费；错误路径不要求完整输出P。

修改mode/颜色看D1/D3/E3/T02…04；修改source/信用看D2/D4/E4/T06…11；修改owner/释放/复位看C/E5/E6/T05/11/12；固定视频/真实资源必须回R4/R5 OPEN。未来文件首部中文注释只解释真实IF/旧输入/推进/保持/结束及稳定符号，文档—注释—代码—参考—测试实施后再核。当前完成纯设计候选，未实现验收/人工理解均待检验，不能以讲解当用户已经理解或功能通过。
