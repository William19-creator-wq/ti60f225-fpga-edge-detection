# TRACK4-ALGORITHM-ANN64-OUTPUT-001：整16B ANN输出与联合静态覆盖 v0.2

## A. 状态、范围与来源

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。目标是把完整1920×1080 ANN从逐2bit事务改为每64像素一个完整16B事务；五基础/六高阶、识别质量、完整N覆盖、F0输出和64 RECORD均保留。
Current state：A来源表绑定的R4R/SM/SC/RA/JL旧独立合同仍拒绝或未吸收op6。本v0.2在D1共同选择一套静态覆盖，有限消除白名单/接口矛盾；真实O许可、INIT/END/provider/覆盖证据与完整费用仍缺。Target state：这些实际桥及预算闭合、共同实施输入冻结后才有可批准范围，不因同宽消息称原接口兼容。
权限：本轮仅修订本Markdown。原v0.1已保为[before-op6-joint](design-TRACK4-ALGORITHM-ANN64-OUTPUT-001-v0.1-before-op6-joint.md)，15958B/SHA 0B91527199B63524B7566418D2A4294C42E12583159C51C0F60822814CA66EC8；修改前现卡及快照实际相符。R1/预检审批不含本实现，R2/Q0仍待答；不改原卡、实施基线、正式状态、日志或审批，不生成业务代码/测试。真实用户指定批准尚不存在。
依赖与里程碑：真实来源→局部设计/数值→根审阅→AN-B01…03共同闭合→指定READY/基线/用户批准→独立work实现验证。恢复只保留文档历史，不执行软件/硬件回滚。

| 已读来源 / 用途 | SHA256 |
|---|---|
| [PLAN_TEMPLATE](PLAN_TEMPLATE.md)，A–L | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| [R4R](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)，D3/E8/旧沿fire | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [RA](design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md)，INIT/580assembly/59issues | 33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA |
| [SM](design-TRACK4-ALGORITHM-RECOGNITION-STAGE-MAP-001.md)，phase14/全输出/权限 | 5DBAC492D10C6CE752B8C9AC236906A72305855F4F78803AA9BDA2630FE5EA09 |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，616/740/动态真实资格 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，生产576/prefix/settled | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md) / [RAW](design-TRACK4-ALGORITHM-RAW-STORE-001.md)，普通回复保持/退休 | 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 / 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| [packed字典](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json)，ANN2bit/518400B | D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
JPOOL来源为[JL v0.1](design-TRACK4-ALGORITHM-JOURNAL-LEASE-001.md)：161行/27234B/SHA 68308B965400E50B367C7B2D73BA13F777D78501B29047D0B3F3F010E056FDB5。原BEGIN仍仅op1/op5；D1仅对共同采用本v0.2的ANN路径覆盖该限制，不声称已改JL或冻结实现输入。RAW旧PC/address26只取寿命语义，板上沿DIR32bit，不采用PC生产资源。
Open：AN-B01中的静态白名单/接口矛盾子项由D1有限设计闭合；AN-B01真实permit/INIT/END/provider及权威覆盖证据仍OPEN。AN-B02 journal普通归还、物理可见性/no-future/失败运输与AN-B03完整RAM/FF/序号/ledger/端口/QoS/时延均OPEN，不把子项闭合或局部数字当整卡READY。

## B. 整体行为

AN-REQ01：保N=2073600及完整ROW/ANN语义；00透明、01圆、10矩形、11文字/异类重叠。每行完成全部对象/glyph及ROW效果后，顺序输出30块，整个画面32400块；不跳空块/偶行/无目标。
AN-REQ02：共同采用v0.2时，新RC namespace op6 WRITE_ANN64仅object21、phase14、length64；每块64个真实2bit，完整身份/canonical/全16B资格成立才接纳/提交。保持KEY287/RQ799/RSP872体宽但改变行为版本；未采用本joint的旧op6非法路径不变。
AN-REQ03：真实全块成功/effects和正确响应镜像分别推进；已held承诺履约。known PARTIAL/FULL却失败均不变success，UNKNOWN保债/隔离，不缓存后提前答复、不回滚或编造覆盖。
AN-REQ04：独立真实INIT、全N覆盖/COMMIT_ANN、全64 RECORD/COMMIT_RECORD、POINT token及最终CLOSE/TERM仍保原链；F0也完整执行。只优化ANN提交粒度，不声明整包证明或帧率。
正常例：行0像素0…63按位打包→op6 index0→真实成功→两owner最终prefix64；下一index64。末块index2073536、end2073600后才申请ANN COMMIT。F0所有32400 payload低128为0，RECORD64也全部0，仍是实际写与提交。
失败例：第k块已published后物理写5B报告PARTIAL，保原KEY/5B/效果/未知项，输出private INVALID；prefix不加64。前k个真成功块历史不擦，不给完整ANN token。

## C. 职责与连接

MOD-AN-PACK（RC）拥有pack_hold128/count7与正确RSP后的coverage镜像；读真实ROW、形成/保持一条原RQ，不负责赋予DDR权限。MOD-AN-STORE拥有权威覆盖、canonical/阶段检查与原子块结果，不凭RC自报quiet。
MOD-AN-ACCESS/POOL复用RA单entry/生产580容器及共享物理桥，新增full-overwrite分支；O/SC拥有stage/ref/version/grant、初始化/许可/END真实事实。各独立借用/效果/失败记录继续分别保存。
数据路径：ROW→IF-AN01 PACK→IF-AN02 RQ799→STORE→IF-AN03 SC/实际span租约→IF-AN04 JPOOL/RA→真实DDR→STORE RSP872→RC matching消费；错误→旧义务settle/END/普通退租→原RC CLOSE/TERM→O退休。
仅一条RQ在途；PACK可被暂停。fullgroup为本64像素块、一个journal entry；不是DENSE lane-retire。整体检查点B/C/D可读后才进入E，不将呈现记成人工理解验收。

## D. 接口与组合检查

IF-AN01：既有ROW真实2bit读/capture→RC pack_hold低位。j=0…63对应payload[2j+1:2j]；气泡不填0，count只实际capture加1。ROW容量480B/原glyph RMW不改，原读端口/延迟/仲裁仍AN-B03。
IF-AN02：原KEY287/H160/tx_seq64等字段及RQ799/RSP872编码保持；op6、object21、index32为像素起点、length21固定64，payload512低128为64项/高384全0；WRITE RSP.value512固定0，完整KEY及status/reason沿原族并由adapter明确定义。
前置：index%64=0、index<N、index+64≤N，index等权威coverage_prefix；真实phase14、同H/gen/revision/ref/version/grant、初始化/独占写与普通许可。非法object/op/length/高padding/次序拒新作用，不改prefix；其它表旧op1等行为保持，本joint的ANN数据输出仅op6，详D1。
IF-AN03：SC LOOKUP616用真实item_index=index/item_count22=64/typed_op6/access WRITE，从ANN record_bits2推导逻辑16B；first_bit0、byte_length16、地址base+index/4且16B对齐。范围先足宽计算，permit只真实O分配。
SC原白名单未含op6，D1选定其ANN-only覆盖。logical LOOKUP不等actual span lease；本例逻辑16B恰等rounded16B，仍需同身份排他、initialized、实际permit/借用/END桥。不能借BK599或caller spanpermit自证RC权限；许可跨journal/native/写效果一直保留。
IF-AN04：D1选择op6为JPOOL ordinary member16、spanlength16、单entry；仅本joint覆盖原BEGIN op1/op5限制。生产journal address32/length7/postimage512/state2/cause6/zero17，580尾4零；postimage低128完整块/高384零。
full-overwrite覆盖本16B所有128bit，D1明确新增RA分支，不发目的旧READ；不触邻item/guard，不借WRITE增加immutable READpin。29WE/29RE全文检查及真实状态WE不删，不能把旧RMW源码当已支持。
原请求/回复/许可/序号/body published后保持到真实fire，e0 capture不穿透；反压旧ready路径保留。同core旧沿fire，cancel同沿先结旧fire；rst隔离而不清DDR/journal/未知债。配置原RJ/profile/H快照不变，换phase/ref/version须真实fence。
组合检查：完整ROW提供64真实符号；PACK保持输入→STORE检查全块及原身份→O/SC真实fullspan→POOL校验完整lease/native→DDR真实settled→STORE结果→RC matching→普通退租。当前各桥AN-B01/02，不能用COUNT64或单B响应补齐。

### D1. ANN64-STATIC-JOINT-v0.2：有版本的联合覆盖选择

以下只对**共同采用本v0.2**的RC ANN输出路径生效。A中各SHA仍是未改原卡的历史基线；它们原op6禁/未选分支由本表有限覆盖，不修改原独立基线、不宣布源码已接线。其它对象/阶段、BK、DENSE及管理原语不套本表；共同实施版本/文件清单/批准尚未冻结。

| JOINT / 覆盖原位置 | v0.2完整选择与前提 | 拒绝边界 / 保留事实 | 实际责任与TEST追踪 |
|---|---|---|---|
| AN-J01 / R4R D3 L118/128/130/134、E8 L317–319 | 保KEY287=H160/tx_seq64/op5/object5/index32/length21、RQ799=KEY287/payload512、RSP872=原KEY287/status2/reason6/value512/commit_token64/effect_ok1；仅op6/object21/真实phase14/length64，index为像素起点且16B对应64像素。index%64=0、index<N、33bit先核index+64≤N、index等STORE权威prefix；payload低128按像素升序2bit、高384零。成功WRITE status0/reason0/value0/token0/effect_ok1；失败沿原合法reason/value0/token0/effect_ok0，保真实effects。 | 7…31仍非法；op6错object/phase/length/index/pad拒新效果。原op1仍只length1，不接受64；本joint的phase14 ANN数据输出只op6，不混逐item op1绕过prefix。RECORD及其它表原op0…5保原语义，ANN COMMIT仍原op4。 | RC PACK给完整799，STORE核域/canonical/prefix/真实权限及872，adapter明确原因映射；REQ02→IF02→AN-T01/02/04/07。 |
| AN-J02 / SM phase14 object21 L61/87/133、R4R E8 | 每行ROW全部对象/glyph/pending完成后，PACK依次真实capture64项；30块/row、32400块/frame，下一index只正确matching成功872后加64。STORE prefix22在真实完整write/state/pad/可见/no-future/END完成且无先锁故障后加64并冻结成功；RC镜像22只matching成功872消费后加64。事务边界两prefix一致，held期间可不同；全N及所有债闭合才原COMMIT_ANN。 | 不跳00、空图F0、偶行或任意块，不让INIT推进覆盖。错echo/失败/未冻成功时的cancel不推进；成功872已held后晚cancel不撤回复或倒扣历史，整帧取消另记。每行30块效果/回复/ROW引用闭合才clear下一行；RECORD64/最终关闭不删。 | ROW保完整行；RC保pack及镜像；STORE保权威prefix/首次失败；REQ01/03/04→IF01/02、E→AN-T01/03/04/05/07。 |
| AN-J03 / SC L110–118白名单与逻辑span | 从原799逐字段构造616：namespace4=5/stage_index2=2/typed_op5=6/access2=1、item_index32=index、item_count22=64，原H/gen/revision/ref/version/grant/tx_seq保真；SC低→高布局不cast RQ。O真实ACTIVE/phase14/ANN writer且geometry record_bits10=2，足宽2index与128bit范围推出740 first_bit3=0/byte_length7=16/address32=ANN_base+index/4，实际base16aligned且完整initialized/排他16B。 | 不把count改16/1，index不换block ordinal/byte地址；record_bits/first_bit/len/address/echo或tuple不符均不结旧credit。op6不授其它表/phase；真实非零O permit/借用/END ledger仍AN-B01 OPEN，cache或caller字段不自授，无新immutable READpin。 | O/SC核真实tuple/geometry并分配permit；STORE核动态initialized/prefix与原权利，adapter逐字段关联616/740；REQ02/03→IF03→AN-T02/03/06/07。 |
| AN-J04 / RA E3 L60、DIR生产576与JL word27 | 真实全16B资格、独立INIT和group/entry reserve后，选择FULL_OVERWRITE：完整128bit块直接组postimage512低128/高384零，填生产576/address32/length7=16/state/cause/zero17及580尾4零；不发目的旧READ。仍29WE prepare、29RE真实capture/全文身份与padding验证、一16B物理WRITE、真实effects/state word27 WE及END；不得按请求数称prepare通过。 | 不套其它record或邻位RMW，不写guard/未初始化范围；未验证、未知effects或END不闭合不答success/退槽。word27低11保当前RC完整ENV实际latch，state/cause真来源，不把full overwrite变caller SUCCESS。 | RA/POOL保580/native验证；物理adapter供真实effects/可见/no-future；O关span END，实际桥AN-B01/02 OPEN；REQ02/03→IF04→AN-T03/04/06/07。 |
| AN-J05 / JL L48/51/53/61/65/89/91/95/154 | BEGIN1183的原RQ799只增加合法op6/ANN21/64/phase14分支，原5bit op字段足够编码6；不新增mode字段或改op1/op5语义。从installed原799/真实geometry确定LREQ779，KEY仍原op6/index/length64，member16/spanlength16/base=740实际地址；全tuple、single source、真实group_lease绑定及防重放不省。op6属ordinary：成功done1，失败done0…1为真实已冻结wholeblock成功prefix。 | 拒member非16/done>1、自由caller地址/错ENV/GENV/echo/tuple；未冻成功的END失败为done0，成功872已held后晚cancel保done1历史。872正确消费/旧引用空→entry RETIRE/ACK/GAP→FINISH/FACK/metadata空→退group；不用DENSE lane提前退，不等自身FACK产生ACK。 | RC/JPOOL分别保原799/872及entry/group记录；O/物理证明源与正确消费桥仍OPEN；REQ02/03→IF04→AN-T03/04/06/07。 |

本轮实际核R4R L118/128/130/134/315–331、SM L61–65/83–88/133、SC L110–118、RA L46–63、JL L48/51/53/61/65/66/82/89/91/95，身份见A；PLAN_TEMPLATE全文及v0.2规范身份复核未变。静态位宽与范围可表达不等实际来源/服务已证明，也不关闭AN-B02/03。

## E. 局部中文操作草图

PACK：本行全部绘制/ROW pending关闭→hold清为0/count0→按原行顺序实际读64项、捕获各2bit→count64且原读引用闭合后后续沿形成RQ valid→保持完整KEY/hold/count/配置→等真实RQ及matching RSP；不等下一块来形成当前成功。
STORE：捕获RQ→独立校验域/canonical/expectedprefix与原权限→真实full16B租约/单槽reserve→从完整hold造postimage→29WE prepare、29RE回读/全文身份及pad核→真实logical_commit→一16B物理WRITE→核真实effects/可见性/no-future与状态word27 WE。
权威coverage_prefix22是完整wholeblock protocol-success前缀：完整write/state/pad检查、实际可见/no-future、正确span END完成，且冻结本块成功时没有已锁first_failure，才加64；先23bit中间和核≤N再窄化，初值0，INIT不推进。物理known FULL却END/typed终态失败不加；partial/unknown原bytes/effects另保，不折算whole64成功。成功未冻结时，取消/新故障与旧fire同沿先记真实历史，后续资格判定不得穿透刚更新的完成位忽略失败。
封本entry新读/冻结physical历史→真实END及ACK闭合→按上述条件更新STORE prefix并冻结typed终态→形成/保持原RSP872；正确matching成功RSP消费后RC镜像prefix22才加64。普通published成功/失败回复消费、native/permit/borrow/效果真关闭后，后续沿才退JPOOL槽；872不等待entry/group退休，不套DENSE lane提前归还。
两prefix允许在RSP held时不同；matching成功且旧运输静止的事务边界才比较。每行全部30块的响应/效果/原ROW引用关闭后下一行clear；末镜像/权威prefix=N及所有普通/许可/运输无债后才真实COMMIT_ANN。
RECORD仍逐64item原op1：i<F复制完整FINAL512，其余全0；完整64/F/无pending后原COMMIT_RECORD。随后原CLOSE/NUM quiet/TERM/父目录关闭，不能以块完成代完整输出或父对象退休。
取消/错误：先记旧fire/commit及真实written，再停新PACK/ordinary；已held继续，保hold/RQ/槽/permit/首次原因和冻结历史。若本块真实success已冻结且872已published/held，后续cancel不改/撤该回复、不倒扣STORE真实成功prefix，matching成功消费仍照记RC；整帧取消/private INVALID另记独立终态。尚未冻结成功的END拒绝/错echo/未知/已有故障不whole推进，真实settle/END/回复消费/引用空后才退；未来效果未知保Q。跨对象rollback及自动重试均未选择。

## F. 数值、语言与部分费用

| RTL A–L | 本卡契约/未知 |
|---|---|
| A 数值 | unsigned ANN2/count7=0…64；两prefix22=0…N，中间+64先23bit；index+length及byte末端先33/足宽核域，高padding0，无饱和/回绕。 |
| B 时钟/观察 | 原core posedge沿前fire；捕获→后续旧状态使用，拟TB沿后稳定观察，不新增时钟速度承诺。 |
| C 接受/交付 | 一个RQ；物理完成/权威更新/RSP创建/消费/归还分别计，64项不等64个原请求被接纳。 |
| D valid/推进 | valid0不是ANN00；气泡不加packcount/prefix；00须真实capture/写及coverage。 |
| E 反压/保持 | pack128/count/全KEY/配置及pool/permit各保存至自己的真实关闭，普通RSP held不早退entry。 |
| F 延迟/吞吐 | 列次数而非cycles；ROW capture/授权/native/readback/DDR/END/RSP/归还等待上界未知。 |
| G 复位 | 原同步高有效，!rst fire；未知effects/旧lease不得cold清空伪归还，warm隔离原身份。 |
| H 配置 | 原RJ/profile once snapshot；phase14/op6权限来自O/SC joint版本，不采caller phase。 |
| I 存储 | 保守新增pack128+count7+STORE/RC两prefix22=179bit部分字段；完整state/seq/RQ/lease/ledger/端口未计，不自动报179FF。 |
| J 身份 | 64像素顺序对应一个16B，30块/row、32400/frame；ROW/F0/完整N与RECORD64仍实际覆盖。 |
| K CDC | 此路径同core；原DDR/video/camera/reset CDC及隔离仍整体合同，不新增认证。 |
| L 实现 | Ti60F225/原工具路线；无RTL、模型、TB、综合/STA/PNR或fit证据，无fps目标。 |
固定算术：N/64=32400块；journal每WRITE 29WE+29RE+1stateWE=59 issues，总1911600（原59N=122342400，降为1/64）；数据只32400 W×16=518400B（原N R+N W=66355200B）。这些不含INIT/metadata/ROW/O/auth/END/等待。
真实ANN首次round64 INIT仍32400个16B零写及独立授权/prefix更新，不与本输出WRITE免费合并；ROW1080×480=518400B本地clear不减。RECORD64原WRITE仍3776 journalissues、256R+256W=512单元/8192B；两类输出journal合1915376，仅该条件费用。
原ROW480B、RQ799/expected/RSP872、RA580、共享pool1RAM/176effects及PB holding等独立寿命继续另账；不扣任一旧体，不假设pack128免费复用RQ512。完整RAM/FF/DSP/QoS、DDR资格与stage新桥AN-B01…03未闭合。
共同数学契约：分组前后全部N个ANN2bit/64个RECORD512逐位相等；不变几何/标签/覆盖规则。硬件契约按真实fire/效果/镜像/关闭观察。未来独立软件参考从image/profile生成ANN，再独立分组；不从DUT日志生成黄金。C++/Python角色/版本与文件尚未选，不生成模型。

## G. 实施与验证计划（全部NOT_RUN）

未来获共同指定批准后拟改RC output pack、STORE op6 guard、SC白名单/span、RA overwrite与pool adapter、coverage/admin桥；具体文件/符号待共同freeze，当前没有实现清单或可执行体。

| TEST | 来源/事件 | 明确期望与观察 |
|---|---|---|
| AN-T01 | REQ01/02，pattern00/01/10/11交替、每row首末块/末frame块 | 独立逐像素golden等值，32400事务及index步64，完整padding与KEY；沿后观察。 |
| AN-T02 | REQ02，length1/63/65、index非64倍数/越N、错object/phase/revision | 拒新效果，无prefix推进；当前旧版本op6仍非法，不假兼容。 |
| AN-T03 | REQ03，ROW capture/RQ/RSP/END/退休分别反压、同沿cancel/错echo | 气泡非0；oldheld稳定履约，matching前镜像不动，普通槽无早退。 |
| AN-T04 | REQ03，write known NONE/PARTIAL5/FULL却失败、UNKNOWN、warm rst | private INVALID，无whole64 success；真实bytes/debt/原KEY保留，no-future未证Q。 |
| AN-T05 | REQ04，F0、INIT与输出分别执行、COMMIT前末块未结束 | ANN全N=00及RECORD64=0仍实际写，INIT不代覆盖，无早token；随后原关闭链。 |
| AN-T06 | IF03/04/费用，完整许可/native响应错序、pool并存/nativepad | 真实owner/完整span/lease核，word27保其它位；59按WRITE而非INIT/READ/admin计，实测工具仍待批。 |
| AN-T07 | AN-J01…05联合版本：旧基线拒op6、joint合法首末块、错namespace/stage/count/recordbits/member/done、op1 length64及其它phase/table | 只有共同v0.2与完整真实前提才选ANN-only overwrite/ordinary路径；逐字段而非body cast，无新增mode位；旧独立版本保持拒绝，所有錯配不自授/不结旧expected。各owner/prefix/退租顺序按D1/E核，未来NOT_RUN。 |

## H. 双向追踪

REQ01→PACK/IF01/E首行→T01/T05；REQ02→STORE/O/SC/IF02–03→T02/T06；REQ03→RA/POOL/IF04/E效果与退休→T03/T04；REQ04→OUTPUT/O/E全N/64提交→T05；AN-J01…05逐行反向对应原来源、实际owner、IF、REQ及T07。实际代码均待实现，来源SHA与静态子项设计闭合不是PASS或业务授权。
## I. 设计门槛

整体B、职责C、接口D/D1、局部中文E、RTL/跨语言F、验证G与双向H已形成候选；D1仅有限关闭AN-B01静态白名单/接口矛盾，真实permit/END/provider/覆盖及AN-B02/03实质OPEN，READY_FOR_REVIEW未达到。保存/读回/根审阅仅文档证据；不冻结实施输入、不写Approval Manifest/数据库或用户理解PASS。
## J. 变更与恢复

v0.2相对before-op6-joint快照：D1共同选择op6 length64/ANN phase14、616字段及完整16B、RA overwrite与JL ordinary路径；原卡op6禁仅在共同采用本v0.2时被有限覆盖，原卡文件和独立基线未改。真实桥及共同实施输入以后另冻结/获批；799/872同宽不代行为兼容，只撤候选保历史，恢复先核来源/范围/实际授权。
## K. 实录

本轮仅修订本Markdown及实际读回、只读关键来源/身份与固定位宽算术；未改原卡/快照/实施基线、正式状态/日志/审批、R1证据或待答R2/Q0，未生成业务源码/功能脚本/参考/TB，未执行仿真/编译/综合/PNR/STA/bit。自查不作独立PASS，最终身份与读回范围由外部审阅记录。
## L. 交付与阅读

按A来源/旧快照→B整帧→C连接→D接口/D1联合覆盖→E打包/效果/镜像/归还→F费用→G/H验证追踪→I未决阅读。例：ROW64真实capture→完整799→真实许可/单槽/29WE+29RE→16B真实写/state核→真实END→STORE prefix/冻结872→RC matching prefix→普通entry/group退租；末N/64与原关闭链成立才提交。理解验收待用户实际反馈；局部静态闭合不等实现/整机fit或十一项完成。
