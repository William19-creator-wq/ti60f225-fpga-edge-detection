# TRACK4-ALGORITHM-ANN64-OUTPUT-001：整16B ANN输出 v0.1

## A. 状态、范围与来源

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。目标是把完整1920×1080 ANN从逐2bit事务改为每64像素一个完整16B事务；五基础/六高阶、识别质量、完整N覆盖、F0输出和64 RECORD均保留。
Current state：R4R op1只length1、op6…31非法；RA逐record保护RMW；SM phase14逐位置输出。Target state：未来共同版本明确op6、真实整块资格/覆盖/归还与完整费用后，才形成可实施范围。不是已有接口兼容优化。
权限：本轮只允许新增本Markdown设计；R1/预检审批不含本实现。R2/Q0问题保持原待答；不新增批准问题，不改来源/基线/正式状态/日志。真实用户批准的本卡版本/实现范围/基线尚不存在。
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
JPOOL候选现已保存为[JL v0.1](design-TRACK4-ALGORITHM-JOURNAL-LEASE-001.md)：161行/27234B/SHA 68308B965400E50B367C7B2D73BA13F777D78501B29047D0B3F3F010E056FDB5；它仍未冻结实现输入，BEGIN仅原op1/op5、当前未吸收op6。采用本卡须未来共同版本明确加入op6。RAW旧PC/address26只取寿命语义，板上地址沿DIR32bit；不迁移PC作为板上资源。
Open：AN-B01 R4R/SM/SC/RA/JPOOL op6和真实许可/END/覆盖桥；AN-B02 journal普通归还、物理可见性/no-future/失败运输；AN-B03全部RAM/FF/序号/ledger/端口/QoS/时延。各项均OPEN，由共同整包设计与根审阅闭合；局部数字可独立继续，不能替代这些证据。

## B. 整体行为

AN-REQ01：保N=2073600及完整ROW/ANN语义；00透明、01圆、10矩形、11文字/异类重叠。每行完成全部对象/glyph及ROW效果后，顺序输出30块，整个画面32400块；不跳空块/偶行/无目标。
AN-REQ02：新RC namespace op6 WRITE_ANN64仅object21、phase14、length64；每块64个真实2bit，完整身份/canonical/全16B资格成立才接纳/提交。保持799/872体宽但改变行为版本，当前op6非法路径仍不能运行。
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
前置：index%64=0、index<N、index+64≤N，index等权威coverage_prefix；真实phase14、同H/gen/revision/ref/version/grant、初始化/独占写与普通许可。非法object/op/length/高padding/次序拒新作用，不改prefix；旧op1及其他表行为沿旧版本。
IF-AN03：SC LOOKUP616用真实item_index=index/item_count22=64/typed_op6/access WRITE，从ANN record_bits2推导逻辑16B；first_bit0、byte_length16、地址base+index/4且16B对齐。范围先足宽计算，permit只真实O分配。
当前SC操作白名单未含op6。logical LOOKUP不等actual rounded span lease；本候选还需同身份完整16B排他、initialized、实际permit/借用/END桥。不能借BK599或caller spanpermit自证RC权限；许可跨journal/native/写效果一直保留。
IF-AN04：新op6为JPOOL ordinary member16，spanlength16、单entry；现候选BEGIN只op1/op5，此delta未吸收。生产journal address32/length7/postimage512/state2/cause6/zero17，580尾4零；postimage低128完整块/高384零。
full-overwrite覆盖本16B所有128bit，选择不发目的旧READ；不触邻item/guard，不借WRITE增加immutable READpin。RA现E3 RMW路径须明确新增此分支，不能把现RMW自动当已支持。
原请求/回复/许可/序号/body published后保持到真实fire，e0 capture不穿透；反压旧ready路径保留。同core旧沿fire，cancel同沿先结旧fire；rst隔离而不清DDR/journal/未知债。配置原RJ/profile/H快照不变，换phase/ref/version须真实fence。
组合检查：完整ROW提供64真实符号；PACK保持输入→STORE检查全块及原身份→O/SC真实fullspan→POOL校验完整lease/native→DDR真实settled→STORE结果→RC matching→普通退租。当前各桥AN-B01/02，不能用COUNT64或单B响应补齐。

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

## H. 双向追踪

REQ01→PACK/IF01/E首行→T01/T05；REQ02→STORE/O/SC/IF02–03→T02/T06；REQ03→RA/POOL/IF04/E效果与退休→T03/T04；REQ04→OUTPUT/O/E全N/64提交→T05。反向每新增pack/proof/op6/overwrite/许可桥仅服务以上要求；实际代码均待实现，来源SHA是文档身份不是PASS证据。
## I. 设计门槛

整体B、职责C、接口D、局部中文E、RTL/跨语言F、验证G与双向H已形成候选；AN-B01…03实质OPEN，READY_FOR_REVIEW未达到。保存/读回/根审阅仅文档证据；指定版本/范围/基线批准前停止，不写Approval Manifest/数据库或用户理解PASS。
## J. 变更与恢复

相对旧op1 length1，新增op6 length64和full-overwrite，未来joint必须版本化R4R/SM/SC/RA/JL并冻结输入；799/872同宽不表示行为相容。旧源码/卡/基线保全，只撤候选文档不执行系统恢复；先核SHA与实际授权后恢复工作。
## K. 实录

仅本Markdown新增、纯只读来源与固定容量算术；业务源码/功能脚本/参考/TB均未生成，仿真/编译/综合/PNR/STA/bit未执行。全机正式状态/原R1证据/待答R2与Q0均未改；自查不作独立PASS。
## L. 交付与阅读

按A来源→B整帧→C连接→D新的接口delta→E打包/效果/镜像/归还→F费用→G/H验证追踪→I未决阅读。例：ROW64真实capture→完整799→真实许可/单槽/29WE+29RE→16B真实写→STORE prefix→END/RSP→RC prefix→普通退租；末N/64与原关闭链完整成立才提交。局部性能候选不等实现/整机fit或全部十一项完成。
