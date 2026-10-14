# RGB/EDGE/ANN行预取与实际AXI关闭 v1

- Goal：把已实现的三行缓存连接到实际128bit AXI读取，生成完整54bit行数据和可信的写入方/IO闭合资格。
- Current state：display_rows三bank及handoff组合已验证；现有axi_line_bridge固定64B请求，rgb_frame_reader整帧RGB，不支持任意行、紧凑bit平面及不足64B的合法allocation。
- Target state：16B边界、可变INCR burst、一在途事务；RGB/EDGE/ANN按原owner布局读取，写真实三bank，成功发布/失败关闭/取消/未知隔离分别有实际动态证据。
- Gap：实际预取/解析/协调没有源码，prepared/io_closed仍由上一批TB提供。
- Assumptions：core100MHz/video pair约74.25MHz，父在job_permitted下持有完整结果及所需原图RO权，安全共同复位前停止全部旧DDR访问。真实DDR/PHY动态模型仍待证。
- Open questions：真实DDR QoS/刷新/仲裁延迟、scan/TMDS/最终时序仍整机待验证；不阻塞可直接输出标准AXI的本单元。
- Dependencies：冻结当前rows RTL/pkg、atomic_mailbox、frame_owner_pkg、原生RAM模型及v0.2；原样复制。
- Milestones：整体/接口/局部草图保存读回→RTL/参考/TB→实际AXI byte slave/三bank/取消错误/HD→MAP→登记。
- Detailed steps：B外部→C连接→D接口与相容→E局部中文操作→F语言→G/H测试/追踪。
- State transitions：READY_FOR_REVIEW保存读回/呈现后依用户“统计完后自行进行，无需我的批准”自主实施；本地审计例外有效，正式状态不改。
- Artifacts and hashes：独立work/display_prefetch；输入/源/run SHA、fatal非零探针、失败保留。
- Validation：真正AR/R fire、burst/ID/RESP/LAST/端点、逐字节/bit/lane、实际WR/publish/abort/return及端到端关闭。
- Failure handling：错误但完整R结束可安全失败；未知ID/last/enable-loss隔离且drained0，不造成功或归还。取消不撤已提出AR、stream/out holding。
- Human approval gates：沿用自主软件授权及本地审计，无安装/网络/硬件动作；最终bit之后停止。
- Rollback：只新增work/active/track4_algorithms_20261004/display_prefetch，原HDK/安装/旧组件不动。
- Completion criteria：本实际预取单元软件/MAP交付；整个五基础六高阶仍需生产仲裁/scan/renderer/TMDS/识别/总top/PNR/STA/bit，不缩小目标。

## A. 版本、范围、基线

TRACK4-DISPLAY-PREFETCH-001 v1，关联B4/A3/A5/A6、DR03/06/07。计划11份自写：rtl/display_span_axi.sv、display_meta_ram.sv、display_row_reader.sv、display_prefetch_rows.sv；tb/axi_read_byte_slave.sv、tb/tb_prefetch_rows.sv；model/prefetch_reference.py；scripts/run_prefetch_sim.ps1/run_prefetch_map.ps1；project/display_prefetch_component.xml/.sdc。原样rows四RTL、atomic、owner pkg及RAM共7源依赖；设计/规范/实际AXI资料另冻输入。

原owner bundle942/row543/return545仍完整保留。固定64B bridge不能读取A16/A32的小平面而不超出授权，新的span以16B beat及准确A端点工作；不修改旧bridge或reader。图仍1920×1080；小偶数几何只是边界测试。

## B. 整体外部行为与样例

PF01：一个core job在途，锁bank2/ticket543/bundle942/permitted1，验证完整SourceOrigin/CJ/desc/render、行与mask。拒绝字段/授权/忙/代次不发AR、不制造写权限；回复holding直到真实消费。
PF02：按ticket.source_y读取该行所需平面。mode0按上下半屏选SRC或EDGE，mode1/2 SRC，mode3 EDGE，mode4 SRC+EDGE，mode5全部；不存在平面输出规范0。低地址byte RGB为R0/G0/B0/R1/G1/B1；EDGE1bit/pixel、ANN2bit/pixel，ANN map起点+4224。无越界64B尾读。
PF03：标准AXI128bit/16B beat、INCR、ID4=参数READ_ID默认2，max64拍、不跨4KiB；先保留输出容量再R fire，全部真实ID/RESP/LAST核对；AR/data/last在停顿保持。一在途，旧响应结束且holding消费后才发下一burst。
PF04：真实54bit/地址/gen stream写到已授FILL bank，所有960条实际WR且所有IO/私有producer/pending/holding关闭才publish；success表示core已接纳完整行发布，不等同视频已接纳或显示成功。视频仍以真实row ticket建立资格。
PF05：匹配bank/ticket全包取消停止新预取；已提出AR、R、stream holding及已形成WR holding全部兑现。安全取消/RESP失败先结束实际IO、关闭私有流水，再abort未发布bank并消费真实本地return，最后终态才row_returned1。不能只见取消或末R提出就归还。
PF06：wrong ID/早或缺LAST/enable-loss给不可变QUARANTINED、drained0、row_returned0；旧请求/holding/借用保留，不开放新job。匹配旧R/LAST继续吸收不把通知改安全；共同safe复位由平台实际证明后才清。
PF07：metadata私有暂存1KB、RGB reservoir32B、4个16bit metadata cache和一个54bit holding；仍3个完整row bank，单job，不新增第四行/结果。正常ideal AXI时按实际测量评估每行≤14.814815us的预算，真实QoS尚未证明。

正常：OFFER B已完整→bank可用、job许可→reader字段OK→row fill成功→父消费OK→EDGE/ANN原始byte进入私有RAM→RGB burst/byte流与metadata cache组合→960次真实WR→所有R/流水关闭→publish真实fire→SUCCESS holding→视频row资格与原handoff结合。
边界：4×2图EDGE L1/A16、RGB L24/A32，读取16B合法allocation，不按64B扩张；W偶数非8倍、行bit起点不对齐，仍精确2bit/4bit双像素。失败：最后WR holding时取消，不能撤valid；先WR消费→旧R drain→实际row abort/return→CANCELED。错ID则Q永不发闭合成功。

## C. 职责、状态与整体连接

M0 display_span_axi：一个完整byte span，拆≤64拍及4KiB边界，持有一个128bit输出register，拥有AR/R在途和done holding、stop/error/uncertain；不认识图像，不写AXI。
M1 display_meta_ram：native16×512的1KB私有暂存，EDGE raw区0..255B、ANN raw区256..767B；core同域W/R同步，无同时同址依赖。完成全部meta写后才读取。
M2 display_row_reader：锁完整bundle/ticket/bank、字段验证、计算16B对齐span、metadata beat8个16bit序列写、RGB32B carry、4缓存/pending以及54bit输出/计数/终态；拥有一个job直到done实际消费。
M3 display_prefetch_rows：reader与既有rows3联接，先真实fill/ACK再读、真实WR、success publish或safe abort/return、隔离；对外暴露视频row/read/release与正常core return。终态中内部abort的return已消费，其他已发布row的归还继续独立外部通道。

```text
父job/OFFER/RO许可 → M3/M2锁包与holding ACK → rows3 fill/ACK
父消费OK → M2 → M0 AR/R → meta私有RAM / RGB32B → 54bit stream → rows3真实WR
M2真正done/IO与producer关闭 → M3真实publish 或 abort→actual return → 父done
rows3 原子ticket/同步读/真实release/return → 后续scan/handoff/render
```

不把源reader成功终态当视频借用已归还。内部abort return由M3直接消费，避免父等done而done又等父return ready的环；published row的独立return不等此reader job完成。

## D. 精确接口与相容交接

M0 req_valid/ready、addr32、bytes14（16..8192、16倍数），data_valid/ready/data128、done_valid/ready/outcome2/reason8/drained1、cancel/enable/rst；AXI AR addr32/id4/len8/size3/burst2，R data128/id4/resp2/last1。READ_ID默认2，可由最终仲裁分配；额外LOCK/CACHE/PROT/QOS在生产top固定普通访问/显示优先并接齐公开IP，当前组件不假称已接板。req_end33不溢出、ADDRESS_BYTES默认256MiB、≤4GiB。outcome0OK/1FAILED_DRAINED/2CANCELED_DRAINED/3Q；reason1FIELD/2RESP/3PROTOCOL/4CLOCK/128CANCEL。data holding保持即使取消，旧stream必须真实消费或由reader明确吸收；不以drop valid清借用。

M2 job_valid/ready、bank2/ticket543/bundle942/permitted1，job_reply_valid/ready/status3，saved bank/ticket用于读回；out_valid/ready/data54/address10/gen64（完整ticket在job期间稳定）；cancel_valid/bank2/ticket543全包匹配；done_valid/ready/outcome2/reason8/drained1/prepared11/delivered11/read_beats32、quarantined。拒绝header回复后没有started done；合法header在回复消费后RUN，CFG_REPLY取消可在消费后直接安全done。构建/交付最大差1，任何out_valid保持。

M3同job/ACK/done，done另含row_returned1；视频和正常core return通道完全沿用rows3三个独立通道。job_ready仅整个engine空闲/enable/非Q；bank忙可通过明确BUSY holding拒绝，不保留第四job。拒绝不授租约。合法reader CFG_REPLY先保留，到row fill结果后形成用户ACK；若row拒绝，匹配取消reader并消费其无IO安全done，再给拒绝ACK。已发布用户ACK不因迟取消改写。

字段验证：bundle op5/status0；source/result非0，slot<6/<3；Origin capSeq/gen等于source_handle且slot匹配，CJ frame/epoch=Origin，W/H静态相等、low≤high、mode0..5/split=H/2。SRC desc={slot×8MiB,3N,align16(3N)}；EDGE在mode1/2为0，其余{48MiB+resultslot×8MiB,ceil(N/8),align16}；ANN仅mode5为{resultBase+1MiB,4224+ceil(N/4),align16}。所有base/A端点33bit在ADDRESS_BYTES内、16B对齐。ticket与bundle result/Origin/policy/mode完全一致，sequence/scan/gen非0；source_y/mask沿既有rows规则。policy比较result自己的不可变policy，冻结后重复旧active可保留旧policy，不能热读全局video政策替换它。

每plane用row bit/byte范围算logical start/end，再向外16B对齐，边界仍在该完整L/A内。SRC logical字节start=source_y×W×3，end=start+W×3；EDGE bit start=source_y×W，end+W；ANN map bit start=source_y×W×2，end+2W，地址加4224。EDGE对齐span≤256B，ANN≤512B，RGB≤5776B。buffer只提取row真实bit，allocation padding无像素意义；不跨desc、不读取ANN header/list来造map。

权限是父实际RO授权前提，字段验证不是授权本身。TB用明确许可和byte slave，不把它称DDR器件/PHY动态证明。core正沿fire、TB负沿驱动、完整holding稳定；video只在rows的原子ticket下读。共同safe_reset_n各域两沿释放，span/reader core rst由同域release管理；不得清旧IO伪造关闭。

## E. 局部中文操作草图

### E0 span

IDLE实际req fire锁addr/总beats、核字段→计划min(剩余,64,距4KiB)拍→AR保持到真实accept→R计数。R前保留一个128bit holding容量，old holding pop允许本沿接下一R；合法Good R锁data/valid；错误RESP不交数据，锁失败并继续当前burst实际结束；错误ID/LAST锁Q/d0，旧正确ID/LAST继续drain。

当前burst正确LAST后等待data holding真实消费，再发下一burst或DONE。cancel锁stop不造新AR，已提出AR不撤、旧R吸收、old holding保持；error优先于cancel，Q优先于安全结果。活动期间enable失效锁uncertain，之后恢复不清；Q notice可在holding本地生产义务结束后提出，消费notice仍Q。DONE普通结果holding到消费才IDLE。

### E1 metadata与RGB行reader

IDLE锁bundle/ticket→CHECK逐字段验证→CFG_REPLY holding；合法ACK消费后EDGE(需要才读)→ANN(需要才读)→RGB/EMIT。各phase启动一span，metadata先预留128bit序列寄存器；每个真实beat分8次16bit native WE，最后WE与下一beat接纳可同沿，保持旧值写完再锁新beat；phase span done且序列holding空才进入下一phase。

全部meta写结束后初始化四cache EMPTY（EDGE两个、ANN两个）和一个native RE pending。当前/下一word按prefixbit+pairIndex×2/4的地址计算，当前缺项优先，其次预取下一项；slot RESERVED先于RE，下一沿旧pending捕获word/tag成VALID。地址/tag精确匹配才用；cache旧word在相应pair构建后离开时释放，out holding已经复制其值，不再借RAM。只有required plane发RE，其他canonical0。

RGB32B reservoir接受真实128bit stream低地址byte，先从旧buffer构建pair并消费prefix+6，再在剩余byte后附加同沿新beat；完整6byte和所有meta当前word资格具备且out holding空/被消费才构建。RGB转{R1,G1,B1,R0,G0,B0}，metadata shift选2/4bit，锁{ann,edge,rgb}/地址，prepared++；真实out fire delivered++。无SRC时RGB0且不要求reservoir。停顿不得改out payload/gen/ticket。

取消/错误停止新构建/新span/新meta RE，但old out holding保留并交付；old span及128bit stream通过ready继续吸收，私有未曝光buffer可明确丢弃，不再写metadata。已有native RE pending至少经过实际下一沿关闭。安全done须span完整done+d1、out无holding、SER无holding、pending0；成功还须prepared=delivered=W/2、计划读取全结束。余allocation padding在私有域丢弃，不算像素。Q始终drained0，输出末旧holding可消费但不归还。

### E2 rows协调

用reader saved context借用直到用户done消费，reader不会接新job，不重复复制大包。合法header→rows fill实际fire/完整ACK→用户ACK holding→用户消费ACK同时消费reader CFG_REPLY启动实际读取。先取消的有效ACK保持不改；消费后走reader取消并安全abort。

RUN把out真实fire直接作为rows WR fire。reader success done才io_closed/producer_closed=1，提publish；实际publish接纳后消费reader done，再用户SUCCESS holding（row仍由rows银行持有）。safe failure/cancel提abort、等待真正RETURN_LOCAL并内部消费完整同ticket/kind1，才消费reader done/用户done.row_returned1。Q给用户Q/d0/row_returned0、保留FILL与借用，永久不接新job。published其他bank的core return始终由外部父独立消费。

不变量：任何读在descriptor A内；一AR在途；hold容量在R fire前已留；错误数据不成正常pair；prepared−delivered≤1；未知IO不publish/abort/归还；没有未计的第四row或未曝光引用；完整ticket/Origin与元数据一起保持。

## F. RTL/跨语言合同

SV_09/always_ff非阻塞/组合全赋值，unsigned：AXI数据128/addr32/end33/bytes14/remaining beats10/burst7/beat index7，metadata16/地址9，RGB256/count6（0..32），pair54/地址10/计数11（0..960），完整942/543/545/64bit身份不回绕。乘/移位先扩展到32/33，取pixel下标不窄化未检查值。A数值如上；B两域正沿；C实际握手；D气泡不计数；Ehold不撤；F一core拍可一pair、首元数据/AXI延迟与stall实测；G共同safe reset/资格不清RAM；Haccept时锁完整配置；I private1KB+32B+四word+onepair、3rowbank；J全身份/坐标/lane；Kcore读侧同域，rows双域原子运输；L Ti60F225/I3 MAP，预计新meta1RAM加旧rows18RAM，真实资源/时序以后核。

无C++；独立Python检查byte-addressed memory函数、帧平面/位码、所有真实AR/R范围及完整span、各54bit WR/读输出、holding和终态因果；不读RTL state当期望。数值逐bit，I/O关闭通过实际R/LAST及实际row abort/return证明，不能用纯算法相同替代。

## G/H. 实施、验证、双向追踪

T1 PF01/02：mode0..5/split/y、字段/Origin/CJ/policy/desc/permission/bank busy/gen拒绝，invalid不AR；4×2/20×8/非8倍偶数宽，各行bit prefix及RGB跨16B。
T2 PF03：AXI variable1..64/4KiB/最后allocation16B；AR/R/data长stall、最后beat处理；RESP错误完整失败、错ID/早/缺LAST及enable-loss Q/d0/保持不可变；safe reset只在TB实际停旧访问后。
T3 PF04/05：rows真实完整写/发布/read/return，cancel before ACK/AR held/R held/last out holding/done holding/wrong full ticket；晚cancel不改published通知，关闭必须有实际return。
T4 PF02/04/07：至少1080个1920宽行、全部模式与所有54bit，另生产mode5 worst ideal行周期测量；两个时钟、3bank占用/正常return与新job并行。
T5：当前源Ti60F225/I3 MAP，resource/原语/警告及无board PNR/STA的限制公开。

PF01→M2 CHECK/M3填充→T1；PF02→M2 span/meta/RGB→T1/4；PF03→M0 R/holding→T2；PF04→M3真实WR/publish→T3/4；PF05/06→M0/M2 drain/M3 abort return/Q→T2/3；PF07→所有有限预算→T4/5。实施依序M0/M1→M2→M3→独立TB/参考/runner/project→仿真→MAP→登记。

## I/J/K/L. 门槛、修订、交付

B/C/D/E/F/G/H/A提供十项实质内容；当前无叶设计阻塞，父RO授权/真实DDR性能/生产仲裁及最终图像链明确未闭合。保存全文读回并给聊天入口后，按已授权自主软件工作生成。未改变原DB/Manifest/硬件设置，不冒充逐版用户批准。发现接口/时间/资源变化先短卡读回，不覆盖旧尝试。

初始无本批代码/测试，验证均未运行。阅读整体→交接→中文语句→RTL→独立参考/TB→runs/真实MAP；按实际文件/计数/位序/取消与关闭填写K。理解验收待实际作答；整目标ACTIVE，硬件步骤止于最终bit之后。
