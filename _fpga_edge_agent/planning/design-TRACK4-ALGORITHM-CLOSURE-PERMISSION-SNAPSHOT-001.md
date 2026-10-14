# TRACK4-ALGORITHM-CLOSURE-PERMISSION-SNAPSHOT-001：单S稳定权限/几何与真实旧请求边界 v0.1

2026-10-05；依[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。只新增本卡；这是对BK ordinary逐次冷全文查验的明确候选替换，不修改原公共Canny、BK四个完整body或旧卡。

## A. 通用计划、范围与来源

- Goal / Target：保持完整1080p精确八邻域闭包，在真实独占单S作用域内减少重复ordinary cold查验；权限、INIT、latest、原子组、失败和关闭仍真实成立。
- Current / Gap：R1软件范围完成；R2 v1/48未获批；BK/CW无cache路径可核，但大量每次32pin+32descriptor+holder读取形成NS条件下界；快照资格/动态通知和source封口尚未实现。
- Assumptions：Ti60F225/I3、现有板载DDR、一个S/O/native dispatcher/JNL/shared physical adapter；100MHz仍候选，无新算法fps要求，显示1080p60独立。
- Dependencies / Open：PS-B01真实IP无未来效果/可见性；PS-B02真实L/C/S/O动态与停止桥、完整borrow；PS-B03全机实例/服务/共同file/case基线，见I；现有cold correctness fallback保留。
- Milestones / Steps：B整体→C唯一owner→D字段/连接→E建立/ordinary/fence旧沿→F替换与成本→G/H→根独立读回，解决当前阻塞后才共同READY/指定批准。
- State / Artifacts：仅本文LOCAL_DESIGN；来源hash是实际读取版本，非新正式基线；本卡hash另报，不自嵌。
- Validation / Failure：文档、位宽/整数/链接静态核查；执行NOT_RUN。旧held履约，已accepted而未published后缀按真实失败处分；UNKNOWN保原pin/permit/效果，不计时伪quiet。
- Approval / Rollback：只写新卡，R1/预检授权不覆盖本设计；不提新审批问题，不改Manifest/DB/正式状态/R2/R1/原资料；未获指定批准不生成实现/模型/脚本/TB/EDA。
- Completion：有限候选可读回，不等完整十一项完成、full fit/真实时序或硬件通过；理解验收待真实用户反馈。

本轮入口全文AGENTS15→config规则49/提示词34/配置98→state62/ledger14→DB README30→真实Manifest106，Manifest SHA `7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D`，仍仅预检/R1批准；DB NOT_CONFIGURED不调用。规范前轮全文919，本轮补读251–323/344–435/468–503，模板全文154。

| 实际来源/范围 | SHA256及采用边界 |
|---|---|
| [唯一v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)，919/61102B | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2` |
| [模板](PLAN_TEMPLATE.md)，154/10341B | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)，全文1–210，输出截断132–170实际补读，35416B | `2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060`；599/674/676/684、双claim、physical/关闭 |
| [CH](design-TRACK4-ALGORITHM-CLOSURE-HANDOFF-001.md)，本轮53–174，143–145截断补读，218/34283B | `B4659BA70A766A9E6D7EE16244481E80880157FCC4F0F8407EB7D0F5FA51120D`；353/938/RETURN与metadata寿命 |
| [CW](design-TRACK4-ALGORITHM-CLOSURE-WIRING-001.md)，本轮54–158，197/31288B | `13FB501DC3EB9AD2C86ABD8CD571340301EB9A54FCEC77AED49890F04B212D00`；唯一O、安装/INIT、prefix96事件及费用42677 |
| [NS](design-TRACK4-ALGORITHM-CLOSURE-NATIVE-SERVICE-001.md)，本轮全文1–134，15932B | `96636AD3E8ED891880355EF4D3040ACF30EFE901662C657E9649C9EEB8423942`；Q、相串journal、条件floor及未选cache |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，本轮90–216，298/43441B | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；只取完整holder/旧promise/metadata反例，不采用616/740、32行或revision |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，本轮67–181，231/34598B | `201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA`；640/512/fullrounded/唯一mutator/native |
| [R4C](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)，本轮133–143/157–181/234–246/265–282/331–344，500/100929B | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；125→324/phase/latest/取消/关闭；关键词宽输出截断不当全文 |

## B. 整体行为、要求和正常/反例

| REQ | 当前候选保证 |
|---|---|
| PS01 | 最多3份实际object快照，只服务唯一当前S：LOAD CLASS1；CLO CLASS/QUEUE/EDGE最多3，真实queue absence时2。旧LOAD returned pin/353/CH历史另保，不多开live pin。 |
| PS02 | 原599/674/676/684与两674位置保持；INIT一律原fullAUTH，满prefix真实写读核及无未来INIT债后，O逐row完整核验、valid-last建立权限/rounded几何。 |
| PS03 | ordinary不逐次冷读，但核全H/gen/epoch/role/tuple/borrow回链/真实livepin及合法op/span；动态initialized/latest/tail/组/phase/错误仍来自O/S/JNL真实writer，非caller标志。 |
| PS04 | fence覆盖上游已published未fire324、S已accepted未AUTH324以及原599/674/676/684/物理/native/borrow；区分同沿已fire及两个不同旧身份，保旧白名单实际义务。 |
| PS05 | 先禁止新publication，履约或真实失败处分旧集合，access quiet后才撤保留快照并真RETURN；RETURN不等502/父退休，metadata/353/938不因cache撤权消失。 |
| PS06 | 一个O mutator/dispatcher及收费热快照/有限桥；没有免费cache、复制engine、0clock AUTH、名义DDR fps或完整资源通过。 |

正常：LOAD实际INIT→capture CLASS→BIND/原ACTIVE旧真→完整CLASS→353/490→本scope938/RETURN/502→CLO真exclusive及其INIT→capture最多3row→SEED/BFS/EXPORT→938/RETURN→O immutable PUB。快照不改变全N/P、CLASS邻bit、两postimage或队列N容量。

反例：S已接纳324，正VALIDATE，599尚未valid、permit为空；若fence只看599空就invalidate/RETURN，未来AUTH会越过撤权。另一反例是旧449刚fire而S仍RELEASE，上游可已有新held324，两者真实并存。D/E明确保存完整两身份和边界，不能用S ready0消掉旧held。

## C. 唯一职责和整体连接

- PS-O：原O唯一mutator拥有snapshot header/3row、proof私有槽/旧预算、真实pin及两permit台账；与CW完整native job仲裁，不复制O。所有影响静态资格的O写者先通过fence门。
- PS-S：原S单sequencer拥有实际private324/phase/oldtail/latest/group/journal/FPI/INIT/permit事件，保持原599/两receipt/END及typed/CLOSE；新增STORE_FREEZE源和快照ready/动态判据，不从当前caller填写权限。
- PS-L/C：当前唯一可信LOAD或CLO请求publisher，拥有原held324、原cutoff/last及CLOSE294；新增FENCE目的/完整SOURCE_FREEZE源。parent真实STOP/取消入口及该publisher门接线仍PS-B02，不臆造外部控制口。
- PS-JNL/A/CH：原实际效果/借用/元数据owner，不写权限快照；仍提供原物理/native证明、353/938收据及returnedmetadata保护。

整体：原fullAUTH/INIT→O CAPTURE→header/row→原599快路径检查→原674两许可→S/JNL/A→原676/684；fence独立控制→L/C与S冻结完整旧集合→O join→旧AUTH/END履约→源真CLOSE294与S真实access quiet/938→原RETURN→cache复用。原完整holder在M1/CH lease保护下保留，快照不是它的退休替代品。

## D. 精确存放、接口与逐连接

### D1. 三row及一个header：有限热寄存器候选

每row **410bit**，高→低：`ref64/version64/grant64/borrow_id64/descriptor_index6/pin_index6/object_kind8/base32/byte_capacity29/rounded_capacity29/record_bits10/item_capacity22/pin_access2/immutable1/backend2/typed_op_mask6/initialized_full1`。3×410=1230。object_kind仅CLASS5/QUEUE6/EDGE2，record_bits分别2/32/1；logical/rounded、pin索引不可从caller地址猜。mask低bit0…5对应原op，LOAD CLASS=000001；CLO CLASS=000110、QUEUE=001100、EDGE=010000，op5仅原admin，不发data permit。

共用header **358bit**：`H160/stage_generation64/epoch32/role4/stage_index2/JID96`；角色2LOAD/stage0或3CLOSURE/stage1。完整holder_link160由kind**4位值3**/index6（stage index零扩且核0/1）/真实stagegen64/epoch32/zero54精确形成，非宽3、非切H；H=JID96/原operation64逐字段一致。JID保存的是该job创建身份，不替SRC origin。

row_valid3是已全capture静态体的保留资格；`ordinary_valid = row_valid && scope_access_gate && !fenced && !unknown`。fence先撤ordinary gate，row body/row_valid仍保旧白名单；只有access quiet且旧native/permit/借用真空后清row_valid。initialized_full只由O实际满rounded prefix/初始化来源核建立；不缓存动态valid_count/latest/tail/dirty/组可见/physical_settled/phase。任何prefix回退或新INIT也须先fence，不能保持该证书继续ordinary。

不盲接SC295/616/740：本卡保borrow_id64、rounded29和BK span，不新增caprevision wire、不新增LOOKUP接口。由原fullholder/cold身份及保护lease建立一次静态资格；fullLG/CLJ不可在保护期间换代，但其真实动态state仍单独核。相同H/gen/grant也不得局部reset重装。

### D2. 保持BK完整授权，分别核稳定与动态

AUTH599高→低仍`H160/stagegen64/role4/ref64/version64/grant64/auth_seq64/op4/index21/count22/span_base32/span_end33/init1/access2`；AUTH_RSP674、END676/ACK684全文/两许可及原因族沿BK73–88，绝不用短echo或snapshot pointer代它们。init1仅内部CLEAR6/count1…4，永远原full查；ordinary0…4/init0，op5走原phase/admin，7…15非法。

O先以真实当前scope/header及row核H/gen/epoch/role/完整tuple与原O installed/returned/livepin状态；borrow_id与完整holder回链是capture真实值及仍保护的O原pin，不能只比ref。再用33bit重算item、byte、full16B span，核logical item界和rounded末拍，不碰guard：CLASS pair/item、QUEUE entry、EDGE pair按BK98；count与index必须和原opcode对象单位匹配。caller span必须等重算结果，access3非法/READ0只排他writer保护读、WRITE1/RMW2必须原pin能力覆盖。

S先按原RQ324核坐标/unused/tx/expected_tail/当前真实phase；O查可信S实际private324/839/validated/oldtail/phase的受保护内部读路径，确认599由这个真实S当前opcode产生，不接受普通输入自报phase/initialized。内部动态tap无新复制body：借原S private324、839和已有phase/old21；新增validated位收费，稳定到该op真实结束。tap完整映射/跨owner通知仍PS-B02，缺它不能开启快路径。

| 动态真相/写者 | 实际事件与快照处理 |
|---|---|
| O pin/descriptor/holder静态字段 | 唯一ACQUIRE/RETURN/RETIRE/几何或version/grant/access/immutable/lifecycle权限变更，先mutation_request→fence；未access quiet不执行冲突写，不能旁路native RMW。动态非权限valid_count另由真实effect/phase写。 |
| O initialized prefix/证书 | CW END_PREFIX原674/op6来源，32初RE+32WE+32读回RE/真检查后commit；最后真实满prefix、INIT permits/借用全闭合后才capture。失败/UNKNOWN不设initialized_full。 |
| S phase及INVALID/Q | 原成功op5 token/效果全结束成为旧事实才LOAD→封存、SEED→BFS、CLOSURE→EXPORT；快路径据353/真实SELECT。postcommit取消/失败立即INVALID禁新正常数据/phase，不延迟到quiet；旧held及已issued效果继续结。 |
| S tail/latest/JNL | actual old/new tail、两prepared postimage、group_visible、176biteffect台账按原真实commit/WE/RE/物理事件；claim两个许可同时预留，最新读保邻bit。cache不返回数据、不替dirty/visible或tail判据。 |
| S/O permit及A/native/borrow | 原两674、676/684、FPI/route/RX/W/posted native/pending/父来源lease真实计数与关闭；回执fire不自证未来effects。缺真实proof则Q/ordinary gate0，仍保身份和账。 |

### D3. 一个联合fence边界和完整旧集合桥（新提议，不是已有端口）

**FENCE235**=`H160/stagegen64/role4/reason6/unknown1`：O一个held源→当前L或C目的235及S目的235。同core联合fire只在这两个独立control槽旧空时成立，不依赖data/permit quiet；两端同时捕获同scope。3份705bit；源反压不撤。触发的实际parent/故障/静态mutator通知源仍PS-B02。每scope最多一次，重复必须同体/旧终结履约，不创建第二预算。

联合边界eF先记当沿旧324/449/599/FPI/native/commit真实fire，再封新publication。L/C固定捕获边界旧held全324，含本沿已fire的一份；S固定捕获边界真实accepted private324（若本沿新324 fire取该新体），并保尚RELEASE的旧metadata。单credit/旧full不pop-push保证至多一个currentaccepted和一个upstreamheld；不能以此删原674/末reply/旧native metadata。两份相同完整H/tx_seq/body且boundaryfire1才是同一op，differentbody即协议故障，不按tx一字段去重。

**SOURCE_FREEZE692**=`echoFENCE235/upstream_valid1/upstream_RQ324/fire_at_boundary1/source_fenced1/actual_cutoff_at_boundary64/last_valid1/last_seq64/overflow1`：可信L/C源→O私有各692。无upstream时RQ324/边界fire规范0；cutoff/last来自publisher真实旧火，不是计划数，overflow真实sticky。fence后源只兑现捕获的oldheld，禁止新生成324；之后原CLOSE294只在它真fire后锁最终cutoff，可在S credit尚1时发送。

**STORE_FREEZE720**=`echoFENCE235/current_accepted_RQ324/current_valid1/validated1/auth_published_mask2/auth_accepted_mask2/new_op_fenced1/actual_request_at_boundary64/last_valid1/last_seq64/overflow1/phase3/op_tail21`：可信S源→O私有各720。phase3编码0UNBOUND/1LOAD/2SEED/3BFS/4EXPORT/5INVALID/6CLOSING/7Q；是边界原permission phase，非caller选择。op_tail取本op已锁oldtail；未VALIDATE时取真实S边界tail，后续验证以同全324和真实动态tap核，不以冻结validated0阻旧合法VALIDATE。无current时324/validated/authmask/op_tail规范0，phase仍保真实scope phase，scope关闭史另保。

两个proof源保存新独立完整copy，不覆写原L/C324/S324/599，形成valid后稳定；O两个目的也保存全体至访问债真闭合。auth mask bit0为该op第一CLASS/QUEUE/EDGE span，bit1仅CLAIM的QUEUE第二span；mask是边界真实publication/fire历史，不是caller自授“还有两预算”。O联核原private599、两674 source/原permit ledger及两份全324，同边界fire去重并冻结每旧op至多2个attempt槽，已终结/已尝试的slot不得再授。

新旧预算逐项合并：已经created的674由原permit台账占其对应slot；599已captured而尚未形成674也占slot；S已held599而尚未fire则固定这个slot及原auth_seq，不再给另一份；只有真实accepted324尚未formed的剩余span才由同原op后续形成。CLAIM全生命周期最多CLASS/QUEUE各一许可，不因freeze另加第三许可；本scope/header只capture一次，fence后永不重新ACTIVE/原地重装，SEED/BFS/EXPORT仅S动态phase推进，不触发同身份cache更新。

**FROZEN_ACK246**=`echoFENCE235/status2/reason6/source_seen1/store_seen1/installed1`：O一个held源→S和当前L/C各私有246，独立pending/fire，共738bit。0/reason0/三位1仅真实两proof联核、旧资格/attempt账建立；1合法reason/installed0不表示旧义务为空；2progress不清proof/expected；3Q保原债。原因沿BK80内部族，不castSC/LG；全echo及合法位核，错回复不正常释放。成功ACK消费仅承认边界已安装，其它status不作安装证明；任何ACK消费均不销毁两个proof/history。

progress2真消费仅清对应ACK private transport valid，proof/expected继续保留；O两个pending真清零后才可形成同echo终结ACK，不另开FENCE或新增预算。progress消费及后继ACK形成/消费均不等data quiet；真实两proof锁定后才可形成installed成功ACK，控制槽寿命和旧集合寿命分别核。

这个ACK不等待旧permit/effect/access quiet，否则S若等ACK才能履约旧599就成环；原已经held599处理不被proof安装门撤回。成功ACK仅认证完整旧集合已锁及预算一致，旧数据及原permit随后才实际履约/关闭，最后quiet仍另外证明。

普通fence先关新generation publication；S不得ready0拦captured upstream oldheld。O快路径在ordinary_valid0时仍可用保留row核白名单AUTH：必须来自同实际S当前324且匹配两proof之一、对应尚未尝试span、与scope/fulltuple/原auth_seq一致；上游尚未fire的旧324只有真实S接纳后才可走AUTH。原已经held599/accepted599/created674/END始终按原集合履约，不能重分许可。new AUTH的分配先64seq/exhaust及真实permit容量检查。

取消/故障与纯permission-change分开：取消立即撤新正常业务；已held AUTH/FPI/END/回复兑现。已accepted但未published后缀可以按原known-no-effect失败处分，而非强迫新增正常claim；已published/已commit的两效果和future debt不能这样删除。S必须给原accepted324真实失败/关闭账，Oattempt未授也保对应失败身份；无可判别proof则Q。

**RQ324以前的源链不由692自动证明停止**：LOAD还有C0已held CLASS125/L ready0、或L已接受125尚未形成324；CLO还可能已接受job/锁坐标而尚未publication。已formed324必须上述兑现；未formed后缀只在真实匹配取消使该job失败、原L/C合法终态/close与C0真CS/旧held处分成立时取消，不伪成功coverage。C0的oldheld125须按它原合同实际交付/合法取消关闭，不能因本fence撤valid；L已接受125仍真实计raw/前缀，未published324不造STORE cutoff。纯静态mutator请求正常窗口内延期到原scope正常关闭，不借692丢弃125以换字段；故障/取消立即封新正常业务，原parent→C0/L取消/源封口、CLO本地生成状态及实际终态桥仍PS-B02具体OPEN。新接口字段齐全不证明这些源债已闭合。

## E. 中文正常、捕获、取消沿与复用

| 无stall/无仲裁等待的相对沿 | 真实动作/不能提前成立 |
|---|---|
| INIT旧完成→CAPTURE请求 | 所需674/END684正确消费、满rounded prefix真实commit、全部INIT native/effects/permit借用旧空；assembly原已复用，重新查验，不拿ACQUIRE曾读过当免费capture。 |
| CAPTURE每row：FULL_READ→CAPTURE→CHECK | 选择独立per-row pin32+descriptor32+LG56或CLO22；唯一O consistent microjob从第一RE到末capture/来源核/复制期间保护同body及pin/descriptor。每row全复制410与共用358，不在末capture沿使用末词。 |
| 全row检查→后沿valid-last→下一沿可用 | 校验零pad/livepin/全部几何与initialized、真实exclusive writer/holder/旧847，失败不发布任何正常row；row_valid最后置真实mask，scope gate还等原LOAD ACTIVE/CLO合法BIND与真实S phase，不先发ordinary。 |
| ordinary a0 599 fire→a1身份→a2范围/动态→a3reserve→a4formed674→最早a5fire | 深度1旧槽；0cold RE只表示无逐次全文查，至少5interval条件最早，并非1/cycle。reserve创建permit及真实借用；第二claim许可仍独立重复路径，两674齐备才保护read。 |
| fence f0联合边界→后沿两个proof形成→O分别接纳/联核→后沿ACK形成 | 源与S boundary同时fire先记旧事实；当前typed在VALIDATE而AUTH尚无时也入完整proof。proof接收先capture、后沿检查，不把同沿新ACK当旧安装。等待不占native长锁。 |
| 最后旧op/effect/响应火→后续access quiet核 | 真CLOSE294最终cutoff/last与S台账核；两个proof旧op、599/674/676/684、typed/FPI/native/JNL/borrow全部实际履约或合法失败处分，封后续新访问。938不等RETURN/502。 |
| 后续撤保留row_valid→真实RETURN→ACK→原502/term | 不清原installed/returned ledger；原fullpin/holder全查RETURN，原metadata body/ACK/M1/CH仍保。新scope只按CW旧502已消费、490/938及旧LOAD控制/encoderquiet后复用快照，不等wholeLG/CH退休。 |

最早ordinary表只对已建好scope且动态tap可用、permit capacity真空的正常请求；错误另合法diagnostic，μ_arb/μ_dyn/consumer另加。保原单credit，旧674/684 valid或expected未结不得借新空槽；permit END不等typed449消费，cache access quiet仍必须结真实旧typed/borrow债后才RETURN。

静态mutator与CAPTURE共用O一个scheduler：新mutation先置fencepending；正在一致读取的job继续至完整末capture/check，若fence已发生只保存候选不valid-last；已formed674/permit不撤。变更只能在数据quiet后执行，若涉及gen/ref/grant/几何权限则新真实pin/完整全查后另scope，不原地更新cache一字段。valid_count/tail/latest等真实动态更新不触发每像素recapture。

取消沿：旧599或第二claim674/末JNL WE/commit与cancel同沿都照记；立即INVALID/gate0，未published后缀作真实失败处分；已经形成的两postimage、tail与permit/history不回滚。END若future proof不足保Q，禁新正常授权。warm不清proof、seq/permit/pin/row body，gate0/隔离；只有原共同cold隔离和旧全部运输/效果关闭才重建。不能靠新epoch、cachemiss或REFUSED当已RETURN。

原INITIAL353、CH457/353/两938及四returned pin继续原寿命；cache可先无访问资格而CH仍保存LOAD来源，CLO重用row0并不覆盖它们。typed op5/已retained COMMIT/CLOSE admin完整expected独立办理，不能因row_valid0挡依赖RETURN的末级admin，否则构成环。

## F. 替换/增量、服务与语言契约

| 具名费用 | bits/替换界限 |
|---|---|
| O snapshot body | 共用358+3×410=1588，热寄存器候选；LOAD未用两row与fast无QUEUE row值隔离，无历史第四row，不从旧pin RAM扣。 |
| 新独立FENCE两目的/源 | 3×235=705；当前L/C目的只一实际槽、角色路由，SOURCE/S STORE proof另有槽。 |
| SOURCE_FREEZE / STORE_FREEZE双端 | 2×692+2×720=2824；其中全324两来源copy/两O目的各收费，非借原RQ值当新保存免费。 |
| FROZEN_ACK三个位置 | 3×246=738，O一source/S及当前L/C两private，不能与674/684/449复用。 |
| selected新控制 | 71：row_valid3、scopevalid/accessgate/fenced/unknown/warmblocked/headervalid各1=6；buildstate4/objsel2/issued6/captured6/pending1/check1=20；10transportvalid+ACKpending2=12；两旧op attemptmask4/proofjoinstate3/sourceclosed1/currentclosed1/opselector1/borrowflag4/firstreason6/sticky1=21；S ready/validated、client sourcegate、S acceptedgate、jointcollision各1及prefixmask3/mutationblocked1=9。 |
| 本卡selected增量/联合下界 | 1588+705+2824+738+71=5926；CW42677+5926=48603bit；全机若已有实际同实体/寿命才扣一次。不是fullFF、完整LUT/DSP或fit。 |

不减BK完整S/O599、两674、676/684、2257/640/512 assembly、physical/JNL/CH/353/938；不加RAM或DSP实现承诺，存储选FF但未来综合可能映射须真实登记。原SC32×295/9440、616/740及冷cache均未采用，不能从未计入的15845扣hot9440抵本费用。新native capture复用CW dispatcher/assembly，其控制与仲裁全机仍OPEN；本selected71不是完整SCALAR。

建立明确采用**独立per-row全查**：LOAD1×120 + CLO3×86=378RE issues，holder H=56+3×22=122；queue真实absence为120+2×86=292/H100。均为INIT之后另增的一次capture，不复用早已被覆写的ACQUIRE assembly；不同时又扣一次共享holder。每row也含末capture/check/lease/复制；REGISTER/RETURN/PUB/CLOSE仍原full查。

ordinary Q及typed/JNL/AXI/INIT数量全不变；dense Q=28964444，每Q仍真实AUTH判断/permit/674/END/684，不当0clock；INIT141750chunk/567000beats/9072000B及原prefixjob仍存在。旧NS ordinary H冷读取被替换，较弱新条件floor `H_init+59w`：GENERAL369713572、两queue_ref0快路径122885100 intervals；若保持CW每INIT串行等待684且96I prefix事件与S journal阶段相串，再条件加96I得383321572/124051500。这些排除capture、hot AUTH/END、物理/消费者/其它owner，不是实测秒、算法fps或完成上界。

完成式仍`C≤M_bind/init/capture/fence/phase/return/CH/pub + Σ n_op(s_hotAUTH+s_JNL+s_FPI+s_END+s_reply+δ)`，各真实μ与ROW/CAM/显示争用另且只计一次；当前不得把floor或0RE当承诺。no-cache完整AUTH是正确fallback：未建立/不支持scope时仍原full核，fenced/UNKNOWN/错身份绝不借fallback绕过；它的正确性不代表性能最优。快照模式与fallback选定前不可混报NS floor。

RTL A–L：A全unsigned/410与358精确，地址先33/item×bits先足宽、gen/seq计数先65不wrap；B/C coreposedge旧fire，末capture后另沿；D invalid不计新效果、nativepending仍真推进；E全body/identity/quiet证明held保持；F上述interval/RE/握手各分；G同步rst火0/暖隔离保UNKNOWN；H新scope/config不改旧header/proof/permit；I FF有限3row+有限槽、原native1R1W同址禁；J H、holder_link、gen、grant、borrow、tx/auth/FPI/raw分核；K此core桥不证明外部CSI/HDMI/PHY CDC；L Ti60F225/I3/SV2009/现装Efinity/Questa只读来源，全实例/STA未执行。

C++生产控制N/A；共同数值仍完整Canny/全N EDGE，软件参考独立集合gold；硬件执行另核所有truefire、native、attempt/permit/effects/关闭；对应原JID/H/ref/version/typed全324与fullspan，不从DUT term/CRC生成期望。host黄金不授权限/quiet/token。

## G. 有限实施与验证计划（全部NOT_RUN）

未来获共同指定批准才在work/r4_closure的原directory_span_lease_adapter、logical_state_queue_service、L/C控制及scope_install适配；新增候选符号permission_snapshot_bank/fence_boundary_join，不另复制S/O/A。原来源hash/完整filelist/基线与工具参数由PS-B03联合冻结；此时不生成功能脚本、参考、TB或vectors。

| TEST | 场景/独立可判断期望及追踪 |
|---|---|
| PS-T01 | LOAD1/CLO3/真实queue absence2、全部410/358、borrow/gen/H/epoch/role坏、padding/holder kind宽；完整cold oracle逐字段核，valid-last与真livepin，不授错span；PS01/02。 |
| PS-T02 | INIT末684/满prefix未readback/UNKNOWN/capture末RE同沿fence，CLASS CLO不重清；capture378/H122或292/H100真实数，0RE ordinary不能代INIT；PS02。 |
| PS-T03 | CLASS/QUEUE/EDGE末item/full16B rounded/guard、QUEUE0x04000000、错误caller span/access/op；冷fallback与hot逐请求结果/674全echo一致；PS03。 |
| PS-T04 | SEED/BFS/EXPORT/phase失败、tail=N/旧tail错、同word连续claim/latest、两个permit第二拒绝；真实S/JNL oracle，立即INVALID无新正常后缀、旧effects/held不删；PS03/05。 |
| PS-T05 | fence前accepted324未VALIDATE/未599/第一或第二AUTH未published，upstream324被S stall；f0同时324fire、449fire但RELEASE、同body去重/异body冲突；C0 held125/L已接125未324/CLO已锁坐标未324及真实匹配取消/正常延期；两完整proof/真实cutoff/至多两预算独立核，缺源终结不quiet；PS04。 |
| PS-T06 | FENCE控制oldfull、SOURCE/STORE proof/ACK各stall8/错echo/非法位、一个client停止门未兑现；held稳定、ACK不代CLOSE/accessquiet，不clearpermit；PS04/05。 |
| PS-T07 | ordinary_valid撤后旧白名单599仍fire/两claim预算，未知新request试图old_held绕过；S actualprivate匹配、每slot一次/64seq耗尽，不重授或挡旧promise；PS04。 |
| PS-T08 | END/RETURN/502/938/353/CH及COMMIT admin分别stall、cancel/warm、same H/ref企图复装；无RETURN↔502/父RETIRE环，metadata/INITIAL继续旧寿命，UNKNOWN不装新scope；PS05。 |
| PS-T09 | 6×5三路径/retain0与1全连接、完整1920×1080 GENERAL密集/蛇链/斜链及两快路径；全N gold/真实AUTH/JNL/FPI/INIT/count/close，不缩图/删困难目标；PS01…06。 |
| PS-T10 | 相机/显示/识别与native/permitted origin共享、具体full实例及正常服务长界/实际map/PNR/STA/bit；不将48603/条件floor作整机fit或实时成功；PS06。 |

有限局部验证计划25MHz、seeds0x431/0x1060、每source/consumer连续stall≤8；小图失败监测200000cycle/wall120s；完整图cycle/wall随真实μ与现装工具共同冻结，不套小图阈值。X/Z/EOF/hex/finite finish与actual compared/fire/RE/WE/permit/borrow必检。测试/工具全部NOT_RUN，未来测量不是审批前必须先执行的步骤。

## H. 双向追踪

PS01→O三row/header→D1/E CAPTURE→permission_snapshot_bank→T01/09；PS02→O/S INIT/valid-last→D2/E→capture_fullrow/prefix_gate→T02；PS03→O/S/JNL→D2完整span/动态tap→auth_snapshot_check/dynamic_guard→T03/04；PS04→L/C/S/O→D3完整两proof/旧attempt→fence_boundary_join→T05/06/07；PS05→全部owner→E quiet/RETURN/metadata→scope_access_retire→T04/08；PS06→原O scheduler/费用服务→F→instance/service账→T02/09/10。反向每新增位置/符号只承担权限捕获或真实旧集合，不新增图像算法/生产host；实际代码与证据NOT_IMPLEMENTED/NOT_RUN。

## I. 当前阻塞、评审门槛

| 具名OPEN/实际证据缺口 | 下一项有限处理 |
|---|---|
| PS-B01 BK138真实IP no_future_effects/写后可见性/共同reset，非B0/cal_done | 保原BK物理资格设计与匹配IP公开合同；无该资格不能INIT证书、RETURN/PUB正常成功，本cache不补造。 |
| PS-B02 原parent/C0→L的125/seal/CS/取消源链、CLO尚未324生成状态、L/C source门、联合FENCE235、可信S动态tap/完整proof/真实O permit/borrow及所有静态mutator写入口尚无实际联合接线 | 根联合把125/原终态、held324/accepted324/当前private/599/两674/END/native/lease位置与握手、已formed兑现/未formed合法失败终结逐项落到真实owner；有任一绕过或无限新source，快照不可启用。692不证明125/未324债为空；有限新桥为明确提议，非已存在信号。 |
| PS-B03 完整scalar/LUT/FF/RAM/DSP/ROW QoS、μ/正常上界与共同files/cases/tool baseline | 将71以外实际控制/校验/借用计入唯一全机实例账，冻结capture/两proof与完整算法共同验证；不从未STA的clock或新floor直接READY。 |

§10.3①B、②C、③D候选组合、④E、⑤F、⑥B/E/T05、⑦G/H、⑨保存读回/根审、⑩版本/范围具名；⑧三个当前OPEN未闭合，③/⑥的真实桥仍需联合核。保持NOT_READY；未把执行/STA的未来结果作为批准前运行要求，也未把缺桥当已有实现。

## J. 变更与恢复

此卡明选3个O热快照+联合边界/两完整旧proof，覆盖BK65/NS101的ordinary逐次全文读取候选；原599/674/676/684、full INIT/RETURN/PUB不变。旧SC cache只是语义来源，旧卡字节不改，未经共同指定批准不可执行。恢复先核scope/body来源、原source停止证据、各真实债与新版费用/服务，不能续用旧floor或复位清grant。

## K. 实录与L. 阅读入口

本轮仅控制面与来源只读、新卡及静态核算/读回；未实现业务RTL/模型/脚本/TB/可执行测试、仿真/EDA/bit/网络/安装/硬件/DB/正式状态。功能/工具/硬件及人工理解验收均未执行或待实际反馈；保存卡不代结果。

阅读B完整行为→C唯一owner→D1几何/身份→D2稳定与动态交接→D3两个完整旧集合→E正常/取消沿→F费用/条件成本→G/H→I当前缺口。改字段查T01/03，改INIT/capture查T02，改旧source/fence查T05…08；完整五基础/六高阶与生产链仍需实际获批实现/软件工具证据，bit后人工步骤不执行。
