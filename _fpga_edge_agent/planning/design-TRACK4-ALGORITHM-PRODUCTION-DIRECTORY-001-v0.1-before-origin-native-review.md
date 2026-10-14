# TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001：生产对象目录与共享源寿命候选 v0.1

2026-10-04。LOCAL_DIRECTORY_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED。按 PLAN_TEMPLATE；先 B/C 整体，再 D1–D5 布局与身份、E 中文操作、F/G/H 契约与验证。本卡把生产地址和真实持有关系落实为有限记录，不把文档、容量算术或参考综合当成十一项已经实现。

## 通用计划字段

- Goal：将当前45个板载DDR对象与8份独立片上PROFILE明确分开，规定原始创建身份、逐份借用、初始化和回收，给实际目录存放候选。
- Current state：原RAW v0.2仍是64MiB/26bit地址候选；生产布局已为124.25MiB，SLOT/PROFILE/PB/ROW/SCAN/HANDOFF已有不同身份与关闭合同，不能直接接旧目录。
- Target state：形成可组合的32bit生产目录；与完整holder、DDR效果、端口仲裁、epoch及全机资源联合冻结后纳入整包READY及指定批准。
- Gap：DIR-B01…05见I；本卡不声称完整目录控制器、所有消息和最大pin数量已经证明。
- Assumptions：Ti60F225/I3、SC431HAI彩色、1920×1080、完整八邻域Canny及原识别质量；仅板卡已有资源，允许板载DDR3；core100仍候选。
- Open questions：原parent/base资格与访问pin必须逐项映射；COPY/ARM完整holder合同、DDR关闭可见性、完整热状态及服务待冻结。
- Dependencies：A的真实来源及根v0.2；IP预检批准只覆盖原C0–C3，不是本卡实施许可。
- Milestones：实际对象→字段与native存放→共享寿命→holder计数→真实原子更新和关闭→整包资源/组合复审→READY/指定批准→work实现/验证至bit。
- Detailed steps：固定几何核查、持久序号、实际初始化、原身份封存、逐lease/plane授权、独立归还、最后base退休；未知义务保留。
- State transitions：只改变本文设计状态，正式PROJECT_STATE、TASK_LEDGER、Manifest和数据库不变。
- Artifacts and hashes：A为当前冻结设计输入；不是可执行工程manifest。
- Validation：G是未执行的文字场景；本轮只读原文件和纯设计审阅，不运行模型/TB/综合/PNR/STA。
- Failure handling：坏身份不减引用；未知写/晚回复/旧holder仍保留记录，不以复位或缓存miss销对象。
- Human approval gates：不申请不完整卡批准；获整包指定版本、范围、基线批准前不生成RTL、功能脚本、参考模型或TB。
- Rollback：原HDK/局部来源只读，本文为增量；旧RAW的低速软件场景保留，不能替换为未经批准的生产实现。
- Completion criteria：最终必须有完整十一功能代码、仿真、综合、布局布线、时序和bit证据；本卡只是通往该目标的设计增量。

## A. 来源、版本和阅读入口

| 来源 | SHA256 | 本卡使用范围 |
|---|---|---|
| [整合v0.8](design-TRACK4-ALGORITHM-INTEGRATION-001.md) | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF | 完整目标、32bit生产迁移、五类缺口 |
| [RAW v0.2](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD | D2持久ref、D5目录/journal、E3/E4真实退休；不是生产地址许可 |
| [SLOT](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | 六SRC/三结果/单scratch及21私有/三RECORD |
| [PROFILE/SOURCE](design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | 完整PROFILE、七成功lease/八容量、BIND转owner、最后base退休 |
| [PB](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 | 五ring、CAPTURE_CTX283、单COPY两目的、读写关闭 |
| [HANDOFF](design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md) | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 | 四exec借用/至多三plane，原OPEN387/borrow64 |
| [CONTROL RAM v0.2](design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md) | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 | loan451实际记录、短事务、显式RETIRE和原owner义务 |
| [SCAN](design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | 完整KEY256、四ctx、实际七owner关闭 |
| [VIEW](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | 父资格、完整CERT、私有退休与真实对象返回 |
| [生产布局数据](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json) | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 | 固定base、logical/rounded/guard及21私有表 |
| [PROFILE布局数据](../experiments/track4_algorithms_20261004/01_baseline/profile-store-layout-v0.1.json) | 4FE6BF462E97C30D8F421E9D30FDA96D4D9DFC7AC397024B4320159702B0B810 | 八份1024bit、52词/份、独立目录 |

规则与模板hash分别为4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2、99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。原RAW只说明generation持久分配，未选择global/per-slot；本卡明确选择global，属于新增具体设计。

## B. 整体外部行为

DIR-REQ01：每次实际存储访问来自当前合法对象、版本、holder和阶段；固定地址表不是权限。DDR物理[0,268435456)，当前生产arena[0,134217728)，已分配到130285568；剩余空间不自动成为匿名对象。

REQ02：同原图可供多个结果、冻结、latest及观察同时借用。原图创建身份不随当前J改写；每份成功借用独立归还，最后base退休才销物理图。

REQ03：初始化、逻辑提交、物理写结束、immutable封存、结果发布和对象退休是不同事实。未知effects不能被status、空FIFO或reset消除。

REQ04：45个DDR实体使用有限目录；8份PROFILE使用独立片上目录。完整记录、held副本、访问pin、journal、仲裁和关闭台账全部有成本，不隐含免费大数组。

正常例：B0与B1均借SRC X，F也借X；B0归还自身admission lease后，其EDGE/ANN/RECORD可独立退休，X仍被B1/F保护。F恢复LIVE只返F自己的lease，不销X或改B1历史J。边界例：旧return与新借用同沿，先记真实旧fire，受单元串行更新保护，后续沿才公布新资格；不以count瞬时0提前回收。

## C. 职责和连接

| MOD | 唯一职责/真实保存 | 连接与边界 |
|---|---|---|
| PROD_OBJECT_DIRECTORY（O内部） | 固定45对象的descriptor、ref/version/commit、pin及访问权限唯一writer | caller→完整身份/阶段核查→许可→STORE/DDR；不计算图像算法，不由caller自己传裸地址授权 |
| SOURCE_ORIGIN（O内部） | 六原图创建来源，注册base和逐份SRC lease | COPY真实封存→SOURCE_REG→原图目录；J/BUNDLE只借用，不改创建来源 |
| BUNDLE_ASSOC（O内部） | 三完整历史J/PCTX/信用及四对象ref-version、result/CERT | CREDIT/BIND/COMMIT/VIEW/RETURN；信用结束不等物理槽FREE |
| RING_ASSOC（CAMERA owner、O读） | 五完整CAPTURE_CTX，物理槽代次与实际actor资格 | CAMERA/COPY→DDR；非本core信息先按完整CDC合同交接，O不越权写camera事实 |
| HOLDER_RECORD owner | 源lease、exec loan、算法stage、COPY和camera的完整原始body/关闭 | pin只指向仍固定的实际记录；不凭摘要、同宽数值或地址代真实身份 |
| STORE journal | 原子组latest与物理写事实 | 使用原pin，不为每postimage暗增owner；自身借用及effects结束后独立退休，不等父O退休 |

路径：CAMERA ring→单COPY→immutable SRC创建/登记→逐lease SOURCE/J/BIND→整图算法→真实私有对象/效果退休→完整bundle→四exec loan/行读取→独立loan关闭→父返还→各SRC lease返还→最后base退休。异常在原actor真实关闭或Q，不新增第八epoch owner。

整体检查点：本轮已向用户说明45实体、32bit迁移与逐份共享借用；以下进入实际存放和局部顺序。完整执行接口/资源/服务尚未成熟，不提前接线。

## D. 接口与组合设计

### D1. 固定对象编号与地址边界

descriptor index6为0…63；本候选固定使用0…44，不将余19槽作为自动分配空间。index与object_kind、typed object5、camera ring_index、bundle_slot各有namespace。

| descriptor index | 实体/数量 | base、步长与普通字节容量 |
|---|---|---|
| 0…5 | SRC6 | base0、步长8388608；每份6220800 RGB字节；128B旧PROFILE预留不授权限 |
| 6…8 | EDGE3 | base50331648、步长262144；每份259200 |
| 9…11 | ANN3 | base51118080、步长524288；每份518400 |
| 12 / 13 / 14 / 15 | GRAD / CLASS / QUEUE / POINT | base52690944/61079552/62128128/70516736；capacity8294400/518400/8294400/16588800 |
| 16…36 | 21 private | 按JSON顺序ANCHOR…DRAW、COVER_META/CIRCLE_CTX/FIT_STATS；逐个真实base/capacity/rounded/guard，不能把整个AUX授权为workspace |
| 37…39 | RECORD3 | base87293952/87298112/87302272；各4096，随后64B guard |
| 40…44 | CAMERA_RING5 | base88342528、步长8388608；普通RGB每份6220800，最终slot end130285568 |
| 45…63 | 未分配 | 无ALLOC、访问或未来复用资格；不能从canonical FREE推断有物理范围 |

共有40原DDR实体＋5ring＝45；RC_AUX是包络、CELL两half是内部布局、result是关联，不重复加对象。object_kind8本卡编码1SRC/2EDGE/3ANN/4GRAD/5CLASS/6QUEUE/7POINT/8RECORD/9RING；private编码128+原typed object5，即131…148及151…153。其余保留/非法。typed0EDGE等必须显式映射，不能按同数值直连。

所有byte地址32、length加法33，logical capacity与rounded capacity29；先核base+logical/rounded不越各固定slot，再核actual end不超过arena及物理端点。普通item范围只至logical end；padding只能由专用初始化/末拍RMW资格访问，guard及spare slot禁止。跨末byte、record_bits/item_count的乘加先扩宽，窄化前核实际范围。

SRC/RING record_bits24、N2073600；EDGE1/N、ANN2/N、GRAD32/N、CLASS2/N、QUEUE32/N、POINT64/N，RECORD512/64。21 private沿原R4R具体record/capacity而非统一xy谓词；完整映射冻结为DIR-B01的一部分，不以capacity byte数自行创造格式。valid_count22可表示0…N，表示实际item数，不是byte数或写请求数量。

### D2. descriptor640及持久身份

低到高：ref64/version64/JID96/object_kind8/base32/byte_capacity29/record_bits10/item_capacity22/valid_count22/lifecycle3/immutable1/owner_role4/read_pin_count16/write_pin1/commit64/backend2/rounded_capacity29/initialized_prefix29/physical_settled1/alloc_job_valid1/object_epoch32/origin_kind3/origin_binding_ref64/zero43＝640。实际字段597bit；zero43必须0，非FREE全部字段实际初始化。

lifecycle沿RAW：0FREE/1BUILD/2INITIALIZED/3COMMITTED/4RETIRING/5INVALID/6Q，7非法；全零FREE没有有效ref。backend0仅板载DDR，1…3不在此目录授权。origin_kind0NONE/1SRC_CREATE/2CAPTURE/3JOB_PRIVATE，4…7保留；SRC指SOURCE_ORIGIN的source_image_id，RING指完整RING_CTX的capture_id，JOB_PRIVATE以完整JID96与原source_id共同定位。JOB_PRIVATE包括GRAD/CLASS/QUEUE/POINT/private/结果EDGE/ANN/RECORD；后续共享/发布不重写创建JID。SRC/RING alloc_job_valid0且JID全0；不从其后来被某J借用推定创建JID。SRC_CREATE可保留copy来源，不能写入后来的JID掩盖它。

新增具体选择：O分别持有global next_object_generation58＋exhausted1、next_pin_generation58＋exhausted1，初值1；ref=(generation58,index6)，pin grant独立同表示。每个已经保留的身份只消费一次，预留后失败也不重用；最大值合法一次，后续exhausted。两个namespace不互换。version/commit另各64＋exhausted1，先65bit预检；四序列共248bit存储候选，不软件复位。canonical FREE全部0无需保存旧per-slot generation，global allocator保不复用。真正冷run重建仍需原整体旧线/DDR/各actor隔离，不由本地rst清未知效果。

descriptor四20×512 RAM10：每条32词、global word address11＝index6×32+word_index5；bank2选择四块，native address9低位。读回实际640bit、完整校验和RMW副本另计；不是一次20bit读便得到完整descriptor。元数据命令执行期间短锁保护一个一致descriptor/pin变化；外部DDR等待留实际pending，不能长持RAM端口锁。

### D3. pin512与完整holder回链

低到高：ref64/version64/holder_link160/role4/grant64/access2/borrow_id64/epoch32/active1/zero57＝512。替换旧clientH160，是新的生产schema；不能直接接旧AR348。holder_link160低到高＝holder_kind4/holder_index6/holder_generation64/holder_epoch32/zero54。

holder_kind1SRC_LEASE、2EXEC_PLANE_LOAN、3ALGORITHM_STAGE、4COPY、5CAMERA_CAPTURE、6RING_LATEST、7独立REPLAY；0NONE、8…15保留。generation来自该实际holder的独立非零原身份（hold_ref、borrow_id、stage实际序号、copy_seq、capture_id等），不截取SCAN_KEY256或J657凑160bit。holder完整原记录必须存在、同generation/epoch、immutable保持且未复用；物理槽相同不授权限。

先lookup pin全文，再lookup并校验实际holder全文及真实phase/pending/权限，最后形成访问许可。若holder缺失/换代/未知，保留旧pin并隔离，不把lookup miss解释成已return。holder记录只能在它所有pin、typed held/response、native pending、DDR/journal effects与原独立关闭完成后复用。SOURCE完整REQ291/所有者在D4；EXEC完整OPEN387/borrow64已由CONTROL RAM loan451保存；算法完整H160、COPY/ARM完整原body的实际位置与仲裁仍DIR-B02，不把回链当免费认证目录。

role4沿原RAW角色语义，但必须以holder_kind和真实阶段做显式映射；SOURCE原grant角色在BIND后不改。access0READ/1WRITE/2RMW、3非法；write_pin1表示每对象排他写资格，不是全机只能一writer。read_pin_count16只是查验计数，真正返还匹配ref/version/grant/holder/borrow/epoch，并取实际关闭证据。owner/base、父引用、信用、版本和访问pin不是同一计数。

64条pin四16×512 RAM10，每条32词/global11/bank2/native9；pin512读回及改写副本另计。64只是候选物理容量，完整同时存活上界仍DIR-B03；满表保旧义务、拒新准入，不得在正常目标场景依靠该拒绝掩盖未证明的容量。

### D4. 原图、lease、ring和结果记录

| 记录（按列出顺序高到低） | 实际body/保存理由 | 状态与替换前提 |
|---|---|---|
| SOURCE_ORIGIN512 | src_slot3/epoch32/source_id64/src_ref64/src_version64/CAPTURE_CTX283/copy_purpose2 | 六份完整创建来源。成功COPY、注册后不可改；最后base退休及旧通知消费后才清资格；purpose0ALG/1FREEZE_FALLBACK、2/3非法 |
| RING_ORIGIN283 | PB的完整CAPTURE_CTX283 | 五份；capture相位/代次由camera实际owner产生，O接真实稳定副本；这不含完整ARM/write/closing FSM |
| SRC_LEASE522 | 原REQ291/hold_ref64/current_owner2/current_JID96/current_bundle_slot2/pin_grant64/state3 | 八份。owner0POLICY/1OFFER/2JOB/3BUNDLE；非JOB/BUNDLE JID0，非BUNDLE slot0；BUNDLE slot仅0…2。state0FREE/1RESERVED/2LIVE/3CLOSING/4RETURNED_METADATA/5Q，6/7非法 |
| RESULT_ASSOC1879 | J657/source_id64/四组ref64+version64（SRC、EDGE、ANN、RECORD，512）/result_id64/CREDIT_KEY162/CERT352/PCTX65/state3 | 三份；J/PCTX/信用不随下一J变化。已有O历史PCTX65移入本唯一记录，不重复增存。state0FREE/1RESERVED/2BUILD/3COMPLETE/4RETIRING/5Q，6/7非法 |

只有本actor真实存在才置各valid/lifecycle；未使用RECORD的非RC模式ref/version及未有result/CERT规范0，但需真实phase/absence，不能由0反推未创建。完整J657中的冻结配置不代SOURCE_ORIGIN，CREDIT162不代result_id，CERT352不代物理效果与base退还。

SRC_LEASE成功同时≤7：LATEST current1＋closing1、FREEZE1、ADMISSION/BUNDLE合计≤3、OBS1；八槽另含一份预检保留。BIND从JOB→BUNDLE转移同lease，不增pin、hold_ref或原request_seq，不改原role/role_key。单份RETURN先闭合它自己的读取/held/pending/effects；其它bundle/F仍借同SRC不阻本份返回。state4保真实已返回事实直至原ACK/cache运输闭合，不能重用后使旧重试误判。

M0一20×512 RAM：SOURCE6×26词在0…155；RING5×15词在156…230；LEASE8×27词在231…446；447…511未分配。body8663bit，物理447词8940bit，padding277bit。

M1一20×512 RAM：RESULT3×94词在0…281；282…511未分配。body5637bit，物理5640bit，padding3bit。含PCTX后，SOURCE156＋RING75＋RESULT282＝513词，不能声称这些记录一块RAM装得下；本卡加lease后明确两块metadata RAM。每类base由固定index和record词长求得，扩至少10bit检查<512后才9bit；最后词高padding实际写0。

### D5. journal、初始化和回收相容检查

生产journal576低到高＝address32/length7/postimage512/physical_state2/cause6/zero17；16×29词464、9280bit，一20×512 RAM候选。原16×11＝176bit效果台账不删；实际typed KEY、frozen终态、group/tail/dirty/pending和镜像另计。完整postimage只经合法pin/阶段，物理DDR adapter不能从非零address自授对象权限。

initialized_prefix29只证明从base起连续真实完成的字节区间，不能用累计write_count代替覆盖：顺序CLEAR/初始化chunk只有匹配当前端点且实际写结束才推进；gap、重复、乱序不推进。mutable packed表必须先完整逻辑区及授权tail初始化，再允许scatter/RMW；若原算法选择不用CLEAR的逐item构造，须额外真实item前缀/全覆盖证明，不由本字段推导。SRC/RING完整帧另核坐标、canonical与CRC/error/receiver/write关闭，不以prefix满代封存。

physical_settled只由全部实际已issued效果、B/R响应、后端可见性和本地pending结清建立；单B、cal_done或raw TERM不能代它。COMMITTED须完整格式/初始化/valid_count、实际版本/commit及无writer/脏journal；合法mutable自身latest由STORE forward，不裸读旧DDR。

组合检查：原RAW AP466/address26明确不相容，整合候选DR_AP472仍待共同迁移；本卡pin holder_link亦需新的显式adapter。SOURCE311/BIND1012保持原业务body，额外资格在真实目录中查，不能静默加packed字段。CONTROL RAM两短job仍需原owner把完整资源/pending保住，本目录不把存储valid当业务grant。PROFILE1024不进record_bits10的DDR表，原八份52词/份及catalog1808、ref/seal/preferred序号保持独立。

## E. 详细中文操作草图

OP01 冷建立：禁止普通访问→验证软件目标/固定几何/真实DDR初始化→为native内容建立有效性隔离→在原全部域隔离条件下初始化global序列→逐对象FREE。只清资格不假清DDR/RAM。真正START由原七owner闭合/授权，不由epoch输入值自封。

OP02 创建源：预留真实目的SRC槽、descriptor/原图/回执/两个COPY pin预算→锁完整CAPTURE_CTX、目的和请求→逐真实RGB复制并记effects→完整写结束/可见性、读关闭及ring pin返还→注册stable source_id/handle→提交SOURCE_ORIGIN和descriptor immutable。未完成时不发SOURCE311；取消先记旧fire，unknown保ref和真实origin，不改成后来J。

OP03 新lease与绑定：旧请求fire只锁原REQ291和空lease/pin/回复资格→后续完整目录核查、串行一致写pin与计数/lease→实际提交后才形成GRANT363。SOURCE311真实转移后记录完整JID；BIND仅转同lease当前owner、保持原REQ/hold_ref/pin和历史PCTX。新credit或shadow配置不改变旧源。

OP04 授读/写：锁完整caller/body→串行读取descriptor和pin、各自capture末词→独立校验旧完整记录与实际holder→核阶段/全范围/初始化/latest规则→预留permit/实际pending→后续才提DDR。e0请求fire、e1及以后RE、RE下一沿capture；末capture同沿不穿透形成真实许可。任何外部stall保持body和权限，不长锁RAM等DDR。

OP05 原子修改/封存：STORE在旧pin资格下准备journal→全部postimage及队列/计数空间齐全→一个真实logical_commit事件→逐物理写/响应→所有effects真实结束后才typed success/phase seal。失败保原commit/未知前缀，局部journal在自身权限/运输/pending和未来effects真空后独立退休；frozen关闭记录继续给typed/O，不等待父对象先FREE。

OP06 结果与plane：三结果各保存完整历史J/PCTX/credit；真实私有退休、RECORD登记和完整CERT后COMMIT。四exec loan分别保存完整OPEN/borrow，至多12plane pin是这些借用的局部上界，不是全机pin上界。FETCH/RX/input复制后按各自真实关闭释放原plane资格；output row退休不替代source借用关闭，source归还也不等output FREE。

OP07 返回和最后base：锁原return→全文核pin/holder/版本/borrow及本份effects/pending/held关闭→原子减该份真实计数并置返回事实→发原ACK→消费及旧运输闭合后才复用该pin/lease槽。bundle的SRC只返其admission lease；EDGE/ANN/RECORD按自身父/plane/效果真实退休。最终SRC base另须lease全部0、无COPY/writer/provider/未转移offer/旧通知，才能RETIRING→INVALID→FREE；global身份不倒退。

OP08 停止/复位：当沿先登记旧grant/fire/commit/返回事实，再封新普通准入→独立关闭已published actor和DDR效果→分离真实返回与保留的终态/ACK→汇合原七owner实际quiet。错echo/UNKNOWN保Q，不能以ACK被接纳或表空证明已释放。元数据短锁解开不等总运输槽空，软件epoch不能跨旧holder复用。

## F. 语言、映射及实现预算

不新增C++生产控制程序；独立参考语言与scoreboard随整包冻结，当前不生成模型。共同数值为原R1/R2/R3/R4位规则，本目录只处理身份、整数地址和字节权限，不改变精度/场景。

| RTL项 | 本卡合同/限制 |
|---|---|
| A 数值 | D1–D5全部unsigned；地址端点33，native地址算术先扩宽；ref/gen58＋index6，序号预检后分配、不回绕 |
| B 时钟/观察 | core上升沿；native同步RE后下一沿capture、OUTPUT_REG0；camera记录先完整CDC，不直接采异步283bit |
| C 接受/交付 | 非rst且沿前valid&&ready才fire；所有原请求/回执独立held；查验使用完整已capture旧body |
| D valid/推进 | invalid不更新引用/地址；nativepending仍按真实RE推进；FREE0不代表45…63有存储 |
| E 保持 | 源body、完整holder和原callback身份保持到真实闭合；不能在等待中用新J/新配置替换 |
| F 延迟/吞吐 | descriptor/pin每条32词，来源/lease/结果26/15/27/94词；e0fire与末capture后另沿校验，完整仲裁/lookup链/热副本和服务DIR-B04未冻结 |
| G 复位 | core同步资格隔离；warm stop保global序列、原refs和effects；不能同步清整个RAM内容来伪造归还 |
| H 配置 | 原历史J/PCTX与origin不变；新policy只影响后续准入，旧实际fire先记 |
| I 存储 | 单RAM1R1W、同域20或16native、同址R/W禁止；四descriptor＋四pin＋一journal＋两metadata＝11 RAM候选 |
| J 身份 | 固定slot、对象ref、版本、source_id、JID、capture、credit、borrow与holder_link分别核；无同宽blindcast |
| K CDC | 本目录core内部；CAMERA/VIDEO原多域合同仍须完整稳定mailbox/FIFO/释放证明，不以本卡代CDC |
| L 实现 | SV2009候选，实际Ti60器件/工具来源沿原证据；新增11RAM不含完整hot/LUT/FF或未冻结holder；不声称fit/STA |

列出body：descriptor40960、pin32768、journal9216、metadata14300＝97244bit；native物理descriptor40960/pin32768/journal9280/metadata14580＝97588bit。额外序列248＋journal效果176＝424bit只是一小部分热状态；完整读回640/512/576/1879、RMW、请求/回复/重试缓存、allocator保留资格、lookup状态和pin count更新都另计，不能套CONTROL RAM的4097作为本目录总量。

原唯一实例候选153（含独立PROFILE、未证共享FE）＋CONTROL RAM2＋SCAN cold1＋本卡11＝167类块计数；不共享FE的161＋3＋11＝175。只是缺完整热状态的不同native类型候选，尚须官方器件容量/映射及复用证据；不能据此宣称装得下或认定算法无法实现。原参考DDR父39已含桥，不能再加桥17；实际PROFILE一RAM已在153中，不重复加。若需减RAM，必须以真实并发寿命/端口证明改设计，不能删旧义务。

对应核对：独立参考从完整原图/PROFILE生成结果，目录scoreboard独立记录每次grant/真实effects/return/reuse，并核DUT旧原图身份、历史J和完整bytes；DUT自己的目录摘要不能充当oracle。实际comparison需在完整回执及真实捕获后，不能拿单函数输出代RTL关闭。

## G. 实施与验证计划（全部NOT_RUN）

获整包批准后依次实现固定geometry/序号→目录native访问→完整holder及pin adapter→初始化/journal/DDR真实效果→SRC lease/三结果→七owner关闭，再接整包参考/TB/工具至bit；计划文件production_object_directory/source_origin_store/source_lease_store/bundle_association_store/directory_holder_adapter/directory_native_port及对应独立scoreboard，当前未生成。

| TEST | 条件与观察 | 期望/追踪 |
|---|---|---|
| DIR-T01 | 逐45实体、19未分配、旧26bit地址、logical尾/pad/guard、33bit端点 | REQ01/04、D1；仅实际合法范围授权，guard/越界不issueDDR |
| T02 | FREE清0、同slot多次创建、warm epoch、gen/version/commit最大一次与耗尽 | D2；ref不重用，不软件复位序列；耗尽保旧义务 |
| T03 | 同SRC不同J/两个bundle/F/OBS，返回一份、晚旧return与新SRC | REQ02、D4/E03/07；创建origin不改，逐lease关闭，最后base才FREE |
| T04 | 同index错holder_generation、SCAN_KEY256后96bit不同、原SOURCE角色与BIND转owner | D3；核完整原record，不能link相等即成功或回链miss即释放 |
| T05 | CLEAR gap/重写/乱序、完整末chunk、scatter前未初始化、尾pad RMW | D5；prefix只按真实连续完成推进，不由write_count满授权 |
| T06 | logical_commit后部分写/UNKNOWN/取消、journal先退与O后退 | REQ03、D5/E05；保效果，独立关闭不互等，无半图成功 |
| T07 | CREDIT事务结束但旧COMPLETE仍被显示、第三结果、共享历史PCTX | D4/E06；新信用不清旧bundle，不增第三物理bundle |
| T08 | 四exec/12plane叠加算法、source leases、COPY/camera及旧closing | DIR-B03；记录实际峰值与全holder列表，不能按对象数推出64pin足够 |
| T09 | M0/M1末词、各padding、同步RE最后债、读写冲突/停顿 | D2–4/F；完整capture、zero正确、无同址未定行为 |
| T10 | STOP和grant/return/commit同沿、旧callback晚到、Q与START | E08；旧事实先记，七owner真实quiet，未知不重用 |
| T11 | PROFILE1024 GET/SEAL与SRC旧128B预留、独立ref/token | D5；PROFILE独立目录，不截入10bit record_bits或借SRC退休销PROFILE |
| T12 | 全11项功能/质量/生产连续帧及综合/PT/PNR/STA/bit | 原整合；完整软件证据，局部容量/原参考map不代验收 |

## H. 双向追踪

REQ01→O/D1/D2/D5/OP04→geometry、native_port、adapter计划→T01/04/05/09；REQ02→SOURCE/LEASE/BUNDLE/D4/OP02/03/07→origin、lease、assoc计划→T03/07；REQ03→O/STORE/D5/OP05/08→journal/close/epoch adapter计划→T06/10；REQ04→各实际目录/D1–4/F/OP01→固定容器与独立budget计划→T02/08/09/11/12。所有计划文件均未生成，实际代码/基线/测试结果均无；反向每个新增record只承担真实身份、权限、完整结果或归还义务。

## I. 门槛与未闭合项

| ID | 影响与缺口 | 下一项具体证据 |
|---|---|---|
| DIR-B01 | 21 private完整geometry/阶段、32bit byte permit/journal/各caller共同schema与错误矩阵尚未合并 | 逐object5→kind/record/容量对照、完整adapter与依赖版本 |
| B02 | pin回链所需算法/COPY/camera完整holder原body、真实保存/返回/cache/复用合同和唯一writer未冻结 | 实际完整holder表、索引/代次来源、callback及消息接线，不只160bit link |
| B03 | 64pin容量和ring/source/结果/exec/观察/关闭同时峰值未证明，owner/base与访问pin不能混算 | 完整同时存活矩阵及normal路径可达性/角色界，normal不依靠CAPACITY拒绝 |
| B04 | 全native端口仲裁、热mirror/RMW、独立held/闭合证据、序号预留和服务仍未预算 | 单实例RAM/FF/LUT/DSP/DDR服务表、lookup逐沿、官方容量和实际后续工具 |
| B05 | DDR效果可见性/真实关闭、camera多域及原七owner授权尚未联合冻结 | 真实physical adapter语义、完整CDC/epoch/producer关闭与连续IO期限 |

规范10.3①②④⑤⑦⑩有上述候选；③⑥仍需DIR-B01/02逐连接和完整走查，⑧尚有B01…05，⑨待保存读回与有限审阅实录。保持NOT_READY_FOR_REVIEW，不把候选指针、11RAM或167计数当实施许可。

## J. 变更与恢复

新增明确global序号、32bit生产descriptor、独立原创建identity、holder_link回链和两metadata RAM；原RAW640/512/576总宽保留但字段schema改变，属于行为/接口/重要存储选择，必须整包联合评审和指定批准。原RAW/SLOT/PROFILE/PB/HANDOFF/CONTROL/SCAN/VIEW及整合v0.8源hash保持，原审阅不冒称已涵盖本卡。

## K. 本轮实录

本轮由上一仅状态核对继续安全纯设计；实际入口/config/prompt/state/ledger/DB及Manifest已读取，规则hash不变并重新读§8.2/10.3–11.4与模板。当前原工具预检终态有失败、无活跃build句柄；未生成业务源码/功能脚本/参考/TB/work或新工程/约束，未运行功能仿真/综合/PNR/STA/bit，未更改原HDK、正式状态/批准/数据库，未网络安装或操作硬件。独立有限审阅与最终hash另登记于本轮报告，不在此冒造未完成审阅。

## L. 阅读与交付边界

整合B/C→本卡B/C→D1地址与D2创建身份→D3完整holder→D4逐份共享→D5效果→E中文操作→F成本→G/H验证追踪→I缺口。人工观察需未来完整源码、原图/结果、资源及工具日志；当前只能审阅设计。完整十一项至bit目标仍未完成，bit后不下载/烧写。
