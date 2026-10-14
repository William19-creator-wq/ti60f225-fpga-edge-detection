# TRACK4-ALGORITHM-SLOT-JOIN-001：六源三结果的容量与生命周期联合稿 v0.1

2026-10-04；按 [PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED。本文处理整包性能、生产 IO 和对象目录之间的一处真实差异，不提供算法实施批准。1080p、完整八邻域 Canny、原识别质量及板卡现有资源边界保持。

## A. 整体位置、基线与通用字段

- Goal：将六 SRC、三结果槽、单算法工作区作为当前共同容量候选，规定准入、历史上下文、持久 RECORD、返还和复用义务。
- Current state / Gap：PERFORMANCE D5 是 6SRC/3EDGE/3ANN；PIO C 是 2source/2bundle，VIEW 是单 SRC/单 BUILD/单历史 J。容量有余量，但这些接口和状态不能直接接线。
- Target state：容量、owner、身份、正常/失败关闭有共同可审查规则；真实目录实现、生产 bulk 协议、profile 和资源预算再按本稿明确缺口补齐，最终纳入整包指定版本批准。
- Assumptions：只一套 GRAD/CLASS/QUEUE/POINT/RC private 工作区和一个执行中的算法 J；最多一个相机 writer；软件目标 Ti60F225/I3、SC431HAI、1920×1080。
- Open questions：SJ-B01…05。槽数不能代替相机到达率、DDR 最坏服务、视频期限或全机资源证据。
- Dependencies：唯一根 v0.2；当前 PERF/PIO/CONTROL/VIEW/R4R/整合版本及下表 hash。原 HDK 只读。原 v1.3/Gate 仍是独立待批准对象，不由本文运行或修改。
- Milestones / Detailed steps：容量差异核对→固定区/子对象清单→owner/信用/历史引用→真实关闭走查→独立审阅→主稿吸收与缺口关闭→整包评审→批准后实现和实际工具验证。
- State transitions：只改本设计/纯数据/审阅记录；正式 PROJECT_STATE、TASK_LEDGER、数据库和审批 Manifest 不变。
- Artifacts and hashes：[布局纯数据 v0.1](../experiments/track4_algorithms_20261004/01_baseline/production-slot-layout-v0.1.json)，11,516B，SHA256 `9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75`。它不授予运行期访问权限，也不是整包实现基线。
- Validation / Failure handling：实际静态算术已核；G 中的协议/RTL/工具场景均未执行。错误 echo、不完整退休、未知效果及非法槽不得解引用或改成 FREE。
- Human approval gates：整包尚未满足 §10.3；本轮不申请未成熟整包批准，不生成源码、功能脚本、模型、TB 或约束。已有有限预检批准不覆盖本文的新业务。
- Rollback / Completion criteria：旧稿保留；本文只显式覆盖 J 表列出的候选条款。完成本联合设计还须关闭 I，完整目标仍须有全部十一项源码及软件验证至 bit。

| 实际输入 | SHA256 | 本文使用位置 |
|---|---|---|
| [PERFORMANCE v0.2](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 | D4/D5/E5，六源三结果、容量/持续读数 |
| [PIO v0.2](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | C/D/E，真实相机/固定视频、两路扫描/旧关闭 |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | J657、旧 C 锁定、source_offer86、单 J 与 reset |
| [VIEW v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | CERT2、S/O/父/borrow、prejob、真实返还与授权 |
| [R4R v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | object5、21 private、全64 RECORD/真 commit、私有退休 |
| [整合 v0.4 精确快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.4-before-slot-join.md) | 9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3 | 五类/十一项及未合并差异，不代完整 READY |

根定向核原文/字段并实际全文读回本文与布局；两名独立审阅者已全文分段读取 PERF/PIO/整合，数值审阅另核 R4R 编码/容量，协议审阅另核 CONTROL/VIEW 交接。本稿后续审阅的真实终态另记，不用旧稿审阅冒充本文通过。

## B. 外部行为和可检查要求

SJ-REQ01：全局采用六 SRC、三结果槽、单 scratch 的候选。结果槽 i 独占 EDGE_i、ANN_i、RECORD_i；不同结果槽不 alias，不因 stage 更名覆写旧结果。

SJ-REQ02：接纳生产 SOURCE_OFFER182 时已有独占结果预留、可用 scratch、合法不可变 SRC 和完整旧 C/J/终态容量。信用、源、BUILD 绑定分阶段接受；新接纳的信用不能同沿穿透启动 J。

SJ-REQ03：每个结果槽保留自己的历史 J/CFG/profile 和真实 refs；一个新 J 不覆写旧显示/取消/迟到通知所引用的上下文。物理扫描仍最多两个不同 bundle，第三结果可 BUILD 或冻结等待。

SJ-REQ04：RECORD 是独立持久输出，RC 真实完成 64 条 canonical 写及 commit 后由 O 登记。它不在 private_refs_retired 中，AUX 私有归还不得释放三份历史 RECORD。

SJ-REQ05：所有 SRC、结果、scratch、信用、父引用、borrow、控制回执及通知实际结束后才按各自条件复用；软件 QUIET 遍历六源/三结果/视频关闭，不只看当前 J/PLAN。

SJ-REQ06：物理槽索引仅做内部路由，不能代 epoch、handle、source_image_id、result_id、完整 J、版本或 grant。地址先扩宽核权限；保护间隔不成为普通访存权限。

SJ-REQ07：相机无槽/未 ARM、关闭未知、帧失败、处理完成、显示重复/欠载分别观察。有限槽不能证明持续不丢帧；不把降低分辨率、单目标或恢复 1fps 提案作为解决办法。

正常例：A 显示、B 退休、C BUILD，可同时持三个结果槽；D capture writer、E/F 已完整封存等待，加上三个不同结果对应源，可占满六源。C 完成后等待 B 真退休，再进入物理候选资格；不能先让 A/B/C 三者都取得物理扫描引用。

失败例：C 的 AUX_REGISTER 已 fire，随后 COMMIT 失败；C 没有 result_id，但确有 RECORD 引用和已发生效果。O 必须返还该实际记录及 SRC/E/A，不能等不存在的 result 退休事件。

边界例：D 封存使六源都非 FREE；下一 SOF 若没有新 ARM，整帧只作观察/丢弃计数，不能借 E/F 或旧显示源写半图。正常持续接纳仍须由未来服务/到达率证明；此失败边界不是性能验收已通过。

## C. owner 和连接

| owner | 唯一职责、容量与交接 |
|---|---|
| CAP/SRC_PROVIDER | 一名 writer，实际 RGB 写/封存/读取/效果关闭；持 PIO 当前/closing capture，不分配 source/result/J 身份 |
| SOURCE_REG（原 VB-S） | 六注册记录、唯一 source_image_id 和一条稳定生产 SOURCE_OFFER182/prejob revoke/return 通道；不与执行 typed 原子的 STORE 混称 S |
| JOB | 一个执行中 J657、旧 C 快照、信用/绑定/子终态/总 JOB_TERM；不写已转移的历史 bundle ctx |
| BUNDLE_OWNER（O） | 三结果记录、唯一结果/引用/对象目录、预留与真实退休；每槽独立 immutable J，不能用 SLOT FREE 清掉未知效果 |
| STORE/NUM | 仅一套算法工作区和原单 caller NUM；工作区复用须全部 private refs/effects/通知真实关闭 |
| VIEW/VIDEO | VIEW 仍唯一分配 render/plan/display 并申请父引用；VIDEO 按真实 VSYNC/流水/serializer 产生物理事件，最多两不同 bundle 路由＋一份旧 closing metadata |

顺序：SRC 完整 seal→SOURCE_REG→结果预留信用→JOB 接源/锁 J→BUILD_BIND 真成功→完整算法→私有对象真退休＋RC AUX 登记→原 COMMIT1201→独立完整结果→候选 VIEW→受两路上界约束的物理采用→扫描借用关闭/真实 RETIRE→父返还→各实体返还/通知消费→槽复用。控制/失败通道独立于满数据 FIFO。

## D. 固定布局、接口和组合检查

### D1. 容量及子对象

大区保留 PERF D5 的八组：[0,0x05440000)，88,342,528B＝84.25MiB。六 SRC 各8MiB，三 EDGE 各256KiB，三 ANN 各512KiB，GRAD8MiB、CLASS1MiB、QUEUE8MiB、POINT16MiB、AUX1MiB。生产授权上界仍0x08000000，DDR物理上界仍0x10000000；目录/journal/控制/CDC未包含在此数据预算。

总 logical 容量73,781,629B沿 PERF 保守口径含六份128B PROFILE预留。**预留不是已经存在的 C.profile_ref 实体**：CONTROL要求 profile 在所属软件 epoch 内不可删除；不能随源退休销毁它，也不能用 camera cfg_generation 当 recognition profile。真实 profile 安装、全 epoch 生命周期和独立区/目录仍 SJ-B02。本稿不授这六块预留读写/资格。

R4R 的 private object5 为3…20及23…25，共 **21个**、414,973B；CELL11内两个 half 不增加 object 编码。PERF旧“23个私有表”在本联合候选中更正。RECORD object22另有三个持久实例。

AUX首部三个 RECORD 区分别是[0x05340000,0x05341000)、[0x05341040,0x05342040)、[0x05342080,0x05343080)，每份后64B guard。随后按 object 编码顺序放21 private，每份 logical 长度向64B上取整再留64B guard。private rounded415,104B＋guard1,344B＝416,448B；三RECORD含guard12,480B；共428,928B，到0x053A8B80，AUX余619,648B仍未分配。各条base/端点/object/life详见布局JSON，不能退休整个AUX代表逐对象已返回。

尾部 padding 不是 logical item。真实全拍/RMW若需要扩展访问，须另授同对象已初始化的物理尾区、核排他与邻 byte 保留；guard不授普通访问。body地址32bit、加length先33bit，arena capacity至少29bit；64B未对齐请求最多五个16B拍，不把布局范围当AXI服务证明。

PIO旧两源两结果48,115,965B例子两部分均未计PROFILE；若用两源各128B预留的同口径，则为48,116,221B。该历史例不再作为本6/3容量依据，亦不据这256B更正称完整metadata已预算。

### D2. 信用、绑定和三种互斥结束路径

本段均为新增共同候选，同core上升沿沿前valid&&ready且非rst才fire；字段按列出顺序高到低排列，所有整数unsigned。原 J/JID 从命名字段恢复，旧packed澄清仍須 SJ-B01；本文不按同宽cast。

信用KEY162＝epoch32/credit_seq64/bundle_slot2/bundle_generation64。slot仅0…2；seq/gen非零不回绕，以65bit检测耗尽，软件epoch授权前不得重置。O确认槽/回复预算后先标 RESERVED 再提出 CREDIT162；held稳定。J信用槽1可独立消费此前已published信用，在后续旧资格沿才接源。quiesce时只履约旧信用并返还，不创建新信用/J。O最多一份未结束信用。

“未结束信用”是当前预留事务，**不是仍被显示引用的全部结果**。J真消费CREDIT后先放独立未花费KEY槽；sourcefire将该KEY转存当前J的BUILD pin，不能在BIND成功时丢掉后续ABORT所需KEY。O在对应结果记录保存历史KEY；J的当前BUILD pin与后续新信用的未花费槽不得混用。

三条互斥结束路径逐一规定：①从未sourcefire的RETURN真实成功，原ACK175被J消费；②已sourcefire的ABORT真实成功，原ACK337被J消费；③真实COMMIT成功且原R4接收方真实消费匹配的BUNDLE_REPLY232（原job/source/result、0/0/committed1）。O记录对应回执消费后，只有**后续沿的旧事务结束事实及原信用/请求/回执槽可用资格**齐全，才可给另一个FREE结果槽提出新信用。BIND_ACK消费只完成绑定，不结束信用；COMMIT拒绝也不结束信用，仍按真实失败/ABORT路径收尾。Q、错echo、未知关闭或失败通知被消费，均不能冒充事务成功结束。

第三条结束后，已COMPLETE的bundle继续占用自己的结果槽、对象、历史KEY/J及父/borrow引用直到真实退休；它不会阻挡O为别的FREE槽分配信用，也不会因新信用而重新获得BUILD_ABORT资格。旧J的BUILD KEY pin保存到自身JOB_TERM/通知及既有关闭规则结束；下一信用可以先进入J独立未花费槽，但接新SOURCE仍须后续旧IDLE、终态已消费、scratch真实可用等全部条件。任一路结束都不等于源/结果/scratch/整个槽已FREE。

生产 SOURCE_OFFER182＝epoch32/source_image_id64/source_handle64/W11/H11，由SOURCE_REG从已pin真实注册record构造，held1；它显式补齐旧offer86没有的epoch/source身份，不无声添加sideband。JOB核完整注册绑定，接纳时保存source_image_id和原J657所需handle/尺寸；旧可暂停实验offer86仍按其原稿，不能直接接生产端。prejob revoke160沿前旧offer真实fire优先、正确ACK与后续revoke_idle规则保持，按完整182身份匹配所选record。

| IF | 新候选body / 容量 / 成功依据 |
|---|---|
| SJ-IF00 SOURCE_OFFER | SOURCE_REG→J SOURCE_OFFER182，源held1；完整epoch/id/handle/尺寸均来自真实注册绑定，六记录不提供第七幅图 |
| SJ-IF01 CREDIT | O→J KEY162，held1/J接收1；不是 J/result/对象封存证书 |
| IF02 CREDIT_RETURN | J→O KEY162/reason5＝167；ACK175＝原167/status2/reason5/released1。只适用于从未sourcefire的信用；成功0/0/1且真实无BUILD/效果，ACK消费后的后续沿才FREE |
| IF03 BUILD_BIND | J→O KEY162/source_image_id64/J657＝883；ACK1083＝原883/status2/reason5/bound1/edge_ref64/ann_ref64/record_ref64。真实目录、SRC绑定、对象和排他均成立才0/0/1；非RC A/RECORD规范0。result_id此时不存在，不提前分配 |
| IF04 BUILD_ABORT | J→O KEY162/job96/source_image_id64/first_reason5＝327；ACK337＝原327/status2/reason5/effects_closed1/objects_retired1/reservation_released1。只针对已sourcefire的真实J；全部相应效果/对象关闭及回执容量成立才成功，Q保留槽，不能从CREDIT_RETURN解债 |

sourcefire只在旧J可接纳、旧信用有效、同epoch、合法immutable源、单scratch可用、终态与绑定请求槽预算均可用时发生。该沿锁完整旧C/J及源转移事实；后续提出BIND，成功ACK真消费后仍须LOAD/GRAD、真实provider与选定子级的全部旧PREPARE资格；不能用BIND_ACK代这些准备，首CJ/FJ不穿透。BIND held遇cancel仍兑现；cancel只阻新子业务并收真实BIND结果。

BIND失败已有真实J，不能走S_ONLY返源。成功BIND后SRC/结果refs按真实目录转移给O；失败未转移的SRC仍由JOB按真实job归还。BUILD_ABORT只证明其KEY对应reservation/实际O对象，ACK不能等待JOB_TERM消费；JOB随后汇合自己仍拥有的SRC/private/子终态/通知，才能形成JOB_TERM，避免二者互等。RETURN_PENDING期间source ready必须0，同沿先登记旧真实sourcefire，已有转移不走未用RETURN。成功COMMIT后不再走BUILD_ABORT；已经移交的结果按VIEW/O关闭路径退休。请求/ACK各depth1，旧空才接纳，全文echo核对，非法/错echo不释放别人的槽。status/reason按新VIEW namespace构造，不能借原RAW或RC同位宽枚举；全部错误矩阵和重复缓存仍须SJ-B01冻结。

### D3. RECORD辅助结果

SJ-IF05 AUX_REGISTER295＝job96/source_image_id64/record_handle64/record_commit64/F7；ACK303＝原295/status2/reason5/registered1。RC真实64条RECORD完整写、unused全0、F∈0…64、canonical高padding0、真实非零commit与同J/source/目录均核实后，O原子取得并保存ref/token/F。重复完整同body只回既有登记事实，不加ref；错body拒绝。非RC不发送/不等待AUX。

原COMMIT1201 body不暗加RECORD字段；O在真实RC COMMIT成功时，将本J已登记的辅助记录绑定新result_id，再报告原REPLY232。COMPLETE_CERT schema2/private_refs_retired保持，RECORD不在private集合内。F不是“只写F条”的证明。

SJ-IF06 AUX_RETURN293＝job96/source_image_id64/result_id64/record_handle64/reason5；ACK305＝原293/status2/suffix_reason5/closed_mask4/returned1，独立于plane0…2的OBJECT_RETURN295族。COMMIT前失败result0只因本地真实absence合法，不能凭输入0推断没有结果；record token尚未形成也仍须返实际分配ref。真实read/write/pending/held response/effects及所有观察读pin结束后才0/0/closed1111/returned1。没有未知关闭证明不释放实体/槽；各request/ACK独立depth1，ACK held期保留原记录。

此定义不制造已有RECORD provider或观察读取端口；provider/F/全部读pin和错误矩阵仍SJ-B01。本次关闭了“RECORD随private AUX销毁”的候选政策，未关闭真实backend实现。

### D4. 历史上下文、物理引用和复用

O有三个独立历史J记录，唯一JOB逻辑valid可结束，但被旧bundle/held通知引用的J数据不能更新。每槽source/result/EDGE/ANN/RECORD/profile/commit、CERT、真实parent/borrow及通知消费状态独立匹配；DIR的physical slot不能充当handle。ALREADY不加第二引用或重分配render/result；完整相等、可采用状态及重复窗口须共同schema明确。

视频保留PIO“current/future两路＋旧closing metadata”的上界，**同时被物理扫描引用的不同bundle最多两个**；三结果容量不等于第三物理路由。A current/B retiring时，C COMPLETE可以保持完整等待，但不得先授C物理hold。只有B的rows/pixels/serializer、borrow/父返还及相关通知真实结束，才有新物理引用资格。candidate首行预取的pin也算物理引用，不能说未APPLIED就免费。

源释放核全部结果/当前J/offer/观察读pin，不只核其中一个bundle。SRC允许仍被其他合法引用时保持；RETURN某parent不等SRC可写。具体共享SRC策略和自动选源/冻结重算政策仍SJ-B02，本稿不临时改变CONTROL手势；生产offer只显式补齐身份，不改变原接纳/撤销义务。源注册reply、prejob revoke/return及revoke_idle遵VIEW，held offer不能因换新source或超时撤掉。

物理E/A/RECORD在其真实对象返回后才复用；整个结果槽还须所有所属JOB_TERM/VIEW_TERM/ACK/历史body消费。scratch只有所有实际private refs、NUM、raw/typed effect/pending、返还和通知闭合才给下一J；CL/RC会话CLOSE不是整个workspace已经返回。

## E. 局部中文操作草图

SJ-OP01 分区：先读B整体，再JSON八大区/每个AUX对象；核实际完整身份和授权，不以base或槽号寻址未知对象。仅一个scratch授写者，不同结果对应独立输出区。

OP02 采集：provider预留FREE源/唯一writer、故障/关闭容量→保存CAP_ARM→后续完整SOF才开始→真实RGB/末写/B响应及各层关闭汇合→immutable seal→真实注册。无ARM或无FREE时不写他人源，记录整帧未接纳；FIFO满走实际失败/效果关闭，不能封存部分图。

OP03 准备J：O先发布RESERVED信用→J真消费保存→后续旧空/完整SOURCE_OFFER182/预算检查→sourcefire锁旧C/J→下一阶段BUILD_BIND→真ACK→LOAD/GRAD及全部真实PREPARE→算法子级。取消在各自真实旧事件之后生效，不能撤已published请求。

OP04 完整结果：真实全算法及完整覆盖→private逐对象返回→RC完整RECORD/AUX登记→O核所有证据后COMMIT分配result→原R4接收方消费匹配成功REPLY232→后续旧资格结束信用事务。此后两条独立分支：当前结果按VIEW条件取得同一原子父grant；另一个FREE结果槽存在且消息槽/旧资格可用时，O可独立提出下一信用。两者互不等待，发下一信用不是当前结果发布前置；三个槽全占用时，C COMPLETE仍可按两路物理引用和VIEW条件推进。COMPLETE旧结果及历史KEY仍保留，J未结束时只能先存下一未花费信用，不提前接源。nonRC不造ANN/RECORD；RC零目标仍全N ANN0、64 RECORD0且F0。

OP05 显示等待：第三结果只有冻结资格；current/retiring两图仍在时不提第三物理读borrow或candidate READY。旧图真实退役后，按照VSYNC/首行/事件容量取得新资格；每刷新读borrow/RT/EXIT真实关闭，persistent父hold不随单次RT清零。

OP06 失败返还：未花费信用走RETURN；已sourcefire走真实J+BIND/ABORT；已COMMIT走O/VIEW退休。AUX在任何已登记/已分配路径都由真实ref返还，不等不存在result。Q保留所有未知refs，通知消费不能改成FREE。

OP07 软件reset：停止新ARM/注册/信用/J/VIEW/PLAN提议，已fire和旧held先登记并履约；遍历六源/三结果、单scratch、两路视频/旧metadata和所有独立通知。全部真实关闭才七owner授权epoch；本reset自身回执不计入旧业务空谓词，部分授权失败仍quiesce。

OP08 交付：将本稿J的差异吸收到共同接口/状态/预算/测试版本，再读回并审阅整个包；没有指定批准前不生成实现。之后按完整G验证至bit，bit后停止，不替人下载或观察。

不变量：每物理区至多一个writer；每源/输出按完整身份持有；信用新接纳不穿透；3结果不创造3物理路由；private退休不销RECORD/profile；已held不任意撤；真实对象可退与整个槽可复用分开；Q不成功返还；新epoch不能来自首PLAN或清valid。

## F. 语言、资源与三份映射

本稿没有C++/数值算法变更。RTL候选SV2009，posedge沿前判断fire/旧资格，沿后提交；状态与计数先扩位，无效数据不推进。source索引3bit仅0…5、结果索引2bit仅0…2，非法拒绝；序列/代次64bit不回绕。新增信用/AUX均同core；真实camera/video域仍由PIO多域合同和稳定mailbox承担。

资源变化至少包含六源注册ctx、三历史J/CERT/输出refs、每bundle独立通知/parent/borrow、信用/绑定/取消/返回槽、AUX实体及观察pin。只保存3×J657已有1,971bit历史payload；不能仍按单J657计，也不能不证明pin生命期就删除独立held副本。KEY容器至少分别列J未花费KEY162、当前J BUILD pin162、三个O历史KEY486，合810bit payload，不能用同一valid/寄存器装并存的新旧KEY；O发信用held body、全部请求/回执held、状态与消费事实仍另计。若希望从既有固定记录pin读某KEY而省副本，须证明完整存活与并发读取，不预先减去这项。PIO当前/未来/closing的3×(PLAN616+scan64)=2,040bit仅其原候选ctx；ROW双端body11,508bit、同步器、台账和完整O/RAW目录仍逐容器计。全机FF/XLR/RAM/DSP未完成，不把这些下界当综合利用率。

共同数值与逐位参考保持R1…R4及REPLAY；本稿只补事务→真实物理区/旧历史引用/返还身份。软件oracle不从slot状态或DUT token生成GT，协议scoreboard独立核CREDIT/源转移/BIND/AUX/COMMIT/borrow/RETURN真事件；最终像素相等不能代关闭/寿命正确。

## G. 实施与验证计划（未生成/未运行）

先关闭I、吸收J、共同文件/schema/输入版本及整包批准，再在独立work实现目录/credit/aux/provider/视频桥。以下都是文字场景，不是TB或runner。

| TEST | REQ/输入与边界 | 期望来源与通过条件 | 状态 |
|---|---|---|---|
| SJ-T01 | REQ01/06；八大区、21private、3RECORD首/末/guard/未对齐64B；source槽6/7、结果槽3 | 与独立整数布局一致、不alias；非法槽及错误权限不发物理请求；padding不泄露邻对象 | NOT_RUN |
| T02 | REQ02；信用fire与源同沿、quiesce旧信用、信用RETURN；A成功COMMIT但REPLY held、随后真消费且A继续显示/B FREE | 后续旧信用才sourcefire；未花费信用不造J/result；REPLY未消费不结束事务，消费后仍须后续旧槽资格才向B发信用，A不退休；J未终态时独立KEY槽可收信用但不接新源 | NOT_RUN |
| T03 | REQ02/05；sourcefire后BIND拒绝、held BIND遇cancel/失败；BIND_ACK消费、COMMIT拒绝/错echo/Q、ABORT成功ACK held | 已真实J不能S_ONLY；BIND_ACK不结束信用，失败/未知通知不释放；ABORT真成功且ACK消费后后续旧资格才可发下一信用；旧held履约，无子核越过真绑定，全部实际ref返还 | NOT_RUN |
| T04 | REQ03/05；A显示/B退休/C完整，第三candidate首行借用 | 两个不同bundle物理引用上界，C等待；B真实退役后才可用资格 | NOT_RUN |
| T05 | REQ03；新J覆盖/迟到旧ACK/颜色/profile切换 | 三历史ctx独立，旧J/result/ref不受当前C影响，完整echo才能结账 | NOT_RUN |
| T06 | REQ04；F0/64/65、只写F条、AUX重复/错token/COMMIT失败 | canonical64及真token；F65失败；重复不加ref；无result也返实际RECORD | NOT_RUN |
| T07 | REQ05；CLASS/POINT/private close但引用未退休、RECORD仍有读pin | 不复用scratch/AUX或持久记录；独立真实return与通知消耗 | NOT_RUN |
| T08 | REQ05/07；六源占满、FIFO满、无限等待/未知效果 | 不覆盖旧源；完整未接纳/失败/Q分别计，不能自填丢帧率/成功fps | NOT_RUN |
| T09 | REQ05/06；六源/三结果/旧closing跨reset、部分授权 | 完整遍历真实义务，无未知不授权；seq/gen/epoch不回绕 | NOT_RUN |
| T10 | 全REQ；完整1080p/全算法、实际多域/最坏服务及资源/STA | 数值、协议、性能/资源、物理工具分别有全范围证据 | NOT_RUN |

## H. 双向追踪

| REQ | MOD/IF/OP | 计划代码责任（未生成） | TEST |
|---|---|---|---|
| 01/06 | O/布局/D1/OP01 | object_directory/address-authorizer/AUX分配 | T01/T09 |
| 02 | O/J/IF01…04/OP03/06 | build_credit/job_dispatcher/bind-abort | T02/T03 |
| 03 | O/V/VIDEO/D4/OP05 | per-bundle历史ctx/view物理hold与退休 | T04/T05 |
| 04 | RECORD/O/IF05/06/OP04/06 | auxiliary_result_registry/record_provider | T06/T07 |
| 05/07 | 全owner/OP02/06/07 | source return/QUIET/单scratch/故障账本 | T07/T08/T09 |
| 全 | 全组/F/G/OP08 | 独立scoreboard/全包验证/中文说明 | T10 |

反向：新增信用只防无结果容量时接纳J；三J ctx只保存三个合法历史；AUX登记/返还只保障真实RECORD；guard只是分配保护，不能作为已初始化的业务对象。没有新增算法、缩图、主机生产计算或stub。

## I. 门槛和尚待闭合

容量档差异和private计数已按本文形成明确候选；静态地址算术已核。不将设计选择写成当前实现事实，整体仍NOT_READY。

| ID | 本文后仍需实际完成 |
|---|---|
| SJ-B01 | O/S/provider实际descriptor/原子分配/信用错误矩阵与重复窗口，BUILD/AUX全部实体/消息及旧packed澄清，真通知回读/pin目录。接口建议不等实际目录闭合 |
| B02 | 真实epoch不可删profile实体、容量/安装与源/CFG关联；自动选源、共享SRC/冻结重算及返还政策与CONTROL联合，不用128B预留推定权限 |
| B03 | bulk row/provider、最多两物理bundle的实际调度/事件字段、相机rate/CSI资格和DDR最坏服务/关闭界，连续接纳/显示期限证明 |
| B04 | 六源/三J/引用/credit/AUX/CDC与全部算法/DDR IP同时存活的RAM10/FF/XLR/DSP/PLL容器及真实clock/pin/约束预算 |
| B05 | 全包实际版本/文件/profile/GT/schema/test/期限冻结及独立复审；指定完整实施批准和治理前置 |

§10.3的整体/职责/中文步骤/候选接口/验证/追踪已可阅读，真实联合实体和上述阻塞未关闭；⑧仍不满足。不以本文申请部分码去绕过未成熟整包。

## J. 显式覆盖与待吸收的差异

本文v0.1仅在候选设计层覆盖：PERF D5的“23 private”→21及AUX子对象地址；PIO C1的全局2/2容量→6/3（其两物理路由上界保留），旧48MB例的profile口径；VIEW单SRC/单BUILD/单历史J容量条款→有界六源三结果；生产SOURCE_OFFER86→182显式携完整epoch/source身份，CONTROL IF05新增旧信用/绑定资格；RECORD从未定辅助族改为独立登记/返还候选。数学、原COMPLETE_CERT352/COMMIT1201、J/CFG命名语义及旧每次scan关闭仍保持来源。

这些变化需在SJ-B01…05关闭后形成新的共同版本；本稿不能冒充旧局部已吸收新字段，原审閱/批准仍仅覆盖其原对象。ROOT整合IF08/09/12、OP06/09、B03/B04及验证需引用本稿候选，并保留未实现/未运行状态。

## K. 本轮实际记录

已核当前六份设计hash、直接检查容量/对象编码，保存并全文读回纯数据布局；三RECORD/21private独立对齐及guard的地址算术实际相等、无重叠。两名只读审阅者給出容量/槽寿命/信用/AUX反例建议。对修订前26386B、SHA256 `7711DF9929780113E927856C950BEF631E92CF8DB52DF2E2E916BC468D1E997F`全文复核：数值审阅未找到新的限定数值矛盾，协议审阅发现成功COMMIT后信用事务没有结束事件，会让显示A阻挡FREE槽B的新信用。已保留[修订前精确快照](design-TRACK4-ALGORITHM-SLOT-JOIN-001-v0.1-before-credit-close.md)，在D2/E/F/T02/T03补清实际REPLY消费、KEY并存容器与后续旧资格；修订后审读另记，不能用旧hash审读冒称覆盖新正文，也不宣称未执行的协议测试通过。

没有创建算法work、生成业务源码/功能脚本/模型/TB/工程或运行新工具阶段；没有改变待批准v1.3/Gate、正式状态/Manifest/数据库或原资料。上述静态算术不代全机资源、功能仿真、PNR/STA或bit。

## L. 阅读与交付

先B看六源三结果外部行为→C看唯一owner→D1核固定区/子对象→D2/3看信用与RECORD交接→D4/E正常及失败关闭→F/G/H预算、文字验证与追踪→I/J未闭合和版本吸收。当前交付是整包联合候选及可核对地址清单，完整十一项软件测试目标保持，尚未证明完成。
