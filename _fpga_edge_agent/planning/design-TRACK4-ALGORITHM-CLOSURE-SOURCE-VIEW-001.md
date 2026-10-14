# TRACK4-ALGORITHM-CLOSURE-SOURCE-VIEW-001：源体实际存放与唯一O核验 v0.1

2026-10-05；依[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。

## A. 计划、边界、读取事实

- Goal / Target：把[SQ](design-TRACK4-ALGORITHM-CLOSURE-SOURCE-QUIESCENCE-001.md)的受保护view落到具名存放、有限内部连接及单O服务；完整1080p、原Canny/识别要求、现有板载DDR与资源边界不改。
- Current / Gap：R1软件交付已有证据；R2 v1/48仍待指定批准。SQ六位不涵盖原源体；CH冷CS可以早于RETURN，但取消后的存档准入、合法no-start不能只靠kind3 valid解决。当前没有本卡RTL或可执行验证。
- Assumptions / Dependencies：唯一父J、L、C、S、O；本段均core posedge。原SC登记/M1、S真实安装与typed close、SQ形成点/取消、PS旧债、BK许可/物理关闭及CH元数据关闭共同保持。
- Open questions：SV-B01全机实际owner/原生接线及scalar；SV-B02真实DDR效果/可见性/隔离、全资源/服务与共同实施基线。详见I；不把未来执行结果当批准前必须先跑的工作。
- Milestones / Steps：B整体→C唯一owner→D逐连接/寿命→E中文沿草图→F费用/语言→G/H验证追踪→根及独立读回；闭合共同阻塞后才指定冻结、批准与实现。
- State / Artifacts：本v0.1是显式联合delta，不覆写SQ/CH/CW/R2；来源hash是读取版本，尚非新正式实施基线。
- Validation / Failure：本轮仅来源/位宽/地址/费用/组合/链接与文档读回；执行NOT_RUN。错身份/未知借用保Q/原expected，不用超时、valid0或旧term推不存在。
- Approval gates：本卡未批准；R1及预检授权与本地审计例外不扩展。当前仅允许控制面纯文档/检查点；不生成业务RTL、模型、功能脚本、可执行测试/TB或EDA。
- Rollback / Completion：新卡与进度增量可独立审阅；旧HDK、冻结22/48输入、正式Manifest/状态/DB/硬件不动。此局部设计不等完整十一项软件通过。

根本轮按入口顺序读取控制面AGENTS→config规则/提示词/项目配置→state/ledger→database README及真实Manifest；仅既有预检/R1批准。唯一规范前轮全文919且hash未变，本轮模板实际全文154；依规范§8–10填写下面接口、草图、组合与追踪，不以“已有配置”取得新实现授权。

| 实际来源 / 根本轮阅读 | SHA256 / 采用事实 |
|---|---|
| [唯一v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)，此前全文919 | `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`；整体/局部/批准 |
| [模板](PLAN_TEMPLATE.md)，本轮全文154 | `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79` |
| [SQ](design-TRACK4-ALGORITHM-CLOSURE-SOURCE-QUIESCENCE-001.md)，全文150 | `3C1B2998003744AFA91070C0C6B625AAC142A214E56F2302FAE926148B9EC0C6`；六位/两quiet/形成点 |
| [CH](design-TRACK4-ALGORITHM-CLOSURE-HANDOFF-001.md)，本轮51–218 | `B4659BA70A766A9E6D7EE16244481E80880157FCC4F0F8407EB7D0F5FA51120D`；地址/CS/单reader/自持lease |
| [CW](design-TRACK4-ALGORITHM-CLOSURE-WIRING-001.md)，1–78、91–156；144–156截断已补读 | `13FB501DC3EB9AD2C86ABD8CD571340301EB9A54FCEC77AED49890F04B212D00`；唯一O2257/实际M1及注册/INITIAL |
| [LG](design-TRACK4-ALGORITHM-LOAD-GRAD-001.md)，133–150及原seal/owner关键词行 | `3E9354A747496EDAA780BA1FF7AF8757CC9D3A5DDE4E418CC8349D5EE8EF5171`；LG1119含LC270/父真CS |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，126–143、148–164及M1/费用关键词行 | `846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7`；M1唯一端口/旧stage header |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)，137–183 | `2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060`；S294/839、O2257已具名 |
| [R4C](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)，181–206、239–283 | `EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF`；LC/CLJ/seal/op5/终态原顺序 |
| [PS](design-TRACK4-ALGORITHM-CLOSURE-PERMISSION-SNAPSHOT-001.md)，101–113、127–141 | `0D96E90EDF0F3D6620E5DE9BAAB441ADC4508715C0D110BBBA9780CC8EAF11AF`；旧324/许可另债，source不是692 |

## B. 整体行为、选择和反例

| REQ | 当前候选保证 |
|---|---|
| SV01 | 源核验统一读已登记受保护M1 fullLG或CLJ，并反比原真实J/L/C；不以CH CS record缺席当无CS，也不等取消后成功存档。 |
| SV02 | 正常、规范失败真CS与严格no-start分别核；CLO不索取CS。原body、业务身份及冻结R2公共口不改。 |
| SV03 | pending等待不占O assembly/native或CH BEGIN/WORD受理；必要INITIAL/490及原op5继续，source join不等938/RETURN/502/term。 |
| SV04 | 新增三个源体保护lease及明确读回控制；真实已消费CS/seal的body仍保存，三保护位不被当成实际query未结债。 |
| SV05 | S仅在同scope旧sourcequiet_verified与自身真实effects quiet均成立后形成938及其BEGIN；旧LOAD事实不授新CLO。 |
| SV06 | 新费用/READ事件/条件最早沿分账；不重复CH1160、不免费复制宽体，不称全机fit/成功上界。 |

原本可用的正常历史路径：真CS→J592槽→CH kind3地址107…136/30词全存核→收据；CH71允许收据不等未来record，CH125把它放在938/RETURN前。可是CH135禁止取消边界新正常stored、STOP后失败CS存档未全定；no-start本无真CS。故本卡选择统一M1＋原源体，CH3保原历史/PUB用途，不成为sourcequiet必要前置，不默改其失败准入。

正常：L/C真CLOSE294已锁，O登记并等待真实源材料→读M1全文→反比原owner/生成门→后沿sourcequiet_verified→S源和效果均quiet才生成938→CH真实stored收据→RETURN→502→term；再同J合法CLO及原PUB/metadata退休。失败CS或no-start沿同一源核验路径，真实效果仍可能Q，不能授正常coverage。

反例一：SOURCE_VIEW占2257等CS/seal，而CS记录/原op5的O工作又要2257，永久等待。候选仅在材料齐备后eligible，失败等待释放短job。反例二：以LCterm/938为source前置，term又等RETURN而RETURN等source，直接环。反例三：要求三保护lease先归零才CH关闭，但保护只在CH退休解除，亦成环；D4分别定义保护与实际未结查询。

## C. 职责与整体连接

- SV-J：原父LC270/CJ held及实际fire历史、唯一真CS592和原seal fork；CJ142直接投影父同一LC，不生成第二份CS。源体保留允许原CS/STOP/close必要动态事件继续。
- SV-L：独立LC270、CLASS125、实际已接863和checked历史，原Rq/credit/关闭形成点；只它处分已接125未published后缀，不从O一位quiet制造raw/stored成功。
- SV-C：独立已接CLJ438及原pop/neighbor/export/RQ生成状态；只关闭自身生成链，不以LOAD CS免除CLO债。
- SV-O：唯一dispatcher、受保护M1 READ及2257全文核、真实安装/登记映射、三个源保留位及SQ已计verified1；不设新RAM口/外部QUERY/第二目录。
- SV-S：原839安装context、原294close与真实许可/effects账；观察匹配O旧verified再按原流程冻结938。CLASS_COMMIT的353→490不等verified。

连接：真实S294/839只读引用→IF-SV01排候选→IF-SV02 M1全文→IF-SV03 J/L/C原槽反比→SQ O verified1→IF-SV04 S938形成门→CH/RETURN原路径。源保护与实际query债各归O/原owner，最终IF05独立关闭；同J LOAD→CLO不等旧保护归零。

整体检查点：已向用户呈现“核源必须在S_FINAL/RETURN前、避免堵CS和INITIAL”，本卡进一步选M1统一路径及保存期限；尚无实际信号、工具结果或人工理解验收。

## D. 接口、存放、租借与组合检查

### D1. IF-SV01：真实绑定和候选排队（S/O内部只读）

S提供原S BINDSET839的稳定context、原实际接纳CLOSE294、close_seen及scope/encoder原状态；O核自己的真实registered M1 header、fullH160、非零stagegen64、epoch、LOAD/CLO role和installed账。839/294分别已列BK F，不能以held valid或最新UI替旧context。此口是同core内部受保护引用，无新请求body、无独立valid-ready报文；既有公共Rq/CLOSE火仍按原口。

O一份view_pending1及selector1（0LOAD/1CLO）仅在本scope旧phase=IDLE、pending0、verified0且真294已锁时建立一次；selector及保护身份保存到该候选终结。DONE/KNOWN_FAIL/Q不会因close_seen仍1重新排队，只有D4合法新scope才能初始化phase/游标/verified，不能本身份原地重装。wrong close仍归原协议故障、不置正常候选。材料未齐时只留pending，不借2257/native/CH146/28/155/1160，不授verified；pending是实际旧服务义务，不能因为没有active job就当已空。

eligible：绑定/来源保护完整且无冲突替换；LOAD原J真CS或严格no-start、L原seal已锁 checked及SQ预publication处分是真旧事实；CLO原CLJ/生成门处分是真旧事实。正常另须原CLASS/EDGE_COMMIT真实成功，不等待S_FINAL或term；失败沿原真正stop/原旧债规则。END/permit/物理不必此时全空，但938前必须独立真quiet。

### D2. IF-SV02：唯一M1原生读和O2257借用

| role / 来源 | 地址、尺寸、目的 / 精确保证 |
|---|---|
| LOAD | M1 282…337；fullLG1119=J657/LC270/source64/admission64/gradref64；56个20bit词，末低19有效/高1零；到已计O2257低1119，其余1138规范零/隔离。 |
| CLO | M1 338…359；原CLJ438，22词，末低18有效/高2零；到同O2257低438，其余1819规范零/隔离。 |

唯一native20×512、1R1W/OUTPUT_REG0/core，实际RE后下一沿capture、每沿最多一次nativeissue；REGISTER/其它目录同仲裁。先10bit计算base+issued，核issued<n及上述闭区间/<512才9bit。issued/captured各6bit范围0…n，读pending1只标实际未capture返回；无RE/无pending不取料、不拿旧RC高位比身份。此新job不读CH0，也不借CH1160。

dispatcher_job4统一具名：0NONE、1REGISTER_VERIFY、2FULL_ACQUIRE、3FULL_AUTH、4END_PREFIX、5RETURN、6COPY_LG、7COPY_CLJ、8CH_RECORD、9PUBLISH、10SOURCE_VIEW；11…15非法保诊断/隔离。这是明确联合编码候选/全dispatcher位置首次补列，原CH record kind4和local op3不改，也不声称原op3已含这个job。

完整短job非抢占；COPY/RE/check等另job仍原有界轮转。出队前旧assembly/native job空、身份保护已真实存在；当前fullbody的末capture/check完成才复用2257。OWNER_CHECK若尚不能成立，合法保pending、释短job，不在native锁内等CS/seal/旧reply；未知或身份变异Q而非循环重试掩盖。

### D3. IF-SV03：J/L/C同core受保护view，无新宽运输

| 原owner / 真实位置 | O读取与合法性；释放不是valid消费 |
|---|---|
| J LC270 | 唯一父LC不可变，CJ142为其投影；JID96取CJ真实三ID，H160=(JID96,LC.load_id64)，不是任意低160切片。父J657/BUILD历史、stagegen及S839由原登记/绑定全文反核。 |
| J CS592 / CJ/STOP历史 | CS槽已在CH/CW来源4684具名。真CS必须原C0→J actualfire、同CJ及规范原字段；失败reason可非0，晚L失败保原reason0 CS。不等CH3 valid；CJ held/fire、source_start_closed、cancel_pending及原seal pending取真实旧owner。 |
| L LC270 / CLASS125 / SEAL863 | 三独立原槽同时有寿命，不能借seal内LC270消去command槽。已消费seal运输valid可0，863全文及实际checked历史仍保。反比fullLC/CJ、seal.started=实际CJfire；started1时还须L.seal.CS592逐bit等于J实际接纳缓存的完整CS592，started0仅D3严格no-start/CS全0。即使同CJ/各自canonical、pair计数/FS/诊断差一bit也不授verified，保Q/旧债。CLASS/RQ held、原credit和SQ形成门/处分从原owner读取。 |
| C CLJ438 / 原生成状态 | C自己的438是父CLJ源的另一目的。M1全文反比其JID/op/refs/token/尺寸；实际pop/neighbor/scalar/pair/RQ valid、源门/处分与原成功EDGE_COMMIT事件核SQ判据，不用简单head=tail替全部局部空。 |

LOAD no-start：J实际CJ never-published、当前无held/已fireCJ、source_start_closed真；L真收同LC且started0/CS全0的规范863并核失败收尾。无真实CS所以不要求CS_seen/CH3，不生成一条假zero-CS record。已heldCJ即使尚未fire必须兑现→取消→真CS，不能进入no-start。

L正常要求真实CLASS_COMMIT成功，失败未published私有后缀合法处分、oldheld324全fire、新形成门真关闭；C同理自身EDGE_COMMIT/失败生成处分。旧324/Saccepted/599/两674/END/物理/journal/expected由PS/BK另证，view不删它们。source body、门、scope/gen及每个参考位均来自原受保护owner，外部caller不能塞一位quiet；原源码尚无这些view连接，具体局部定义须纳入SV-B01联合实现基线。

### D4. 三个保护lease、实际query债、换scope和IF-SV04

新增O `J_body_keep/L_body_keep/C_body_keep`各1：J在本LC实际建立并关联原注册scope时保护LC/CJ/CS；L在本LC真实接纳时保护自己的LC及将来真接863的历史；C在其CLJ真接纳时保护自己438。未有该owner原体不设位，不把future body当已存在。保护防的是不可变scope/配置/已锁CS或seal历史覆写、换身份或无资格暖清；允许原CS/seal写入一次以及stop/raw/credit/close等必须动态推进。CLASS125是可逐pair复用的工作槽，原合法接纳/存储/清valid及下一pair继续，不要求首125保持到CH退休；只能按SQ停止新生成和处置旧候选，不能让lease封死正常帧。接纳前的CS0/8630不变成有效证明。

保护从真实旧身份建立延续至CH原metadata退休，原valid消费不擦历史body。同J正常LOAD→CLO仍允许新Sscope及C槽接纳，旧J/L保存继续；三个保留位不当数据访问pin，也不挡原必要INIT/commit/PUB。IF05 context_refs_closed必须实证SOURCE_VIEW pending/active/native/assembly/输出/未来query形成点均关闭；**不等待O为本CH自持的三保留位或M1保护lease归零**。未完成pending必须真完成或原合法失败处分，不能只检查activejob0。两actor正确418消费及所有原运输/实际借用旧空、无本沿事件后，后沿才原CH退休并撤保留位；单端reset或Q不能自清。

未建立CH的合法absence路径不造IF05，也不能以OPEN REFUSED猜不存在S pin/938义务。只有真实无CH未结运输/native、原SC metadata retirement及相关body/query债均已合法闭合，才可撤相应保护；已S binding/294且原938义务存在仍须原真实OPEN/record收据/RETURN链，无原合法absence例外则保Q/旧债。源核验不豁免CH938收据前置，也不把永远Q当完成。

IF-SV04 O→S仅同core匹配本839/H/gen/role的只读旧verified1，不新建回复或裸caller权限。S实际效果quiet和source flag均真旧事实后，才形成S_FINAL938及该kind8/9 BEGIN；INITIAL353/490与其BEGIN绝不加此门，否则正常op5→sourcejoin→op5互等。O存938 CHECK/COMMIT再核相同来源/verified，recordvalid8/9保持相应旧source资格历史；正确收据后才原RETURN/502/term。

新CLO安装前原LOAD kind8 stored、RETURN/502/term及原handoff真实门满足；先将当前verified0，再按新真实H/gen/role/source全核后置1，不把旧LOAD1授CLO。kind8历史不清。非法早938已held必须兑现原运输/旧账，但不能在唯一BEGIN/assembly占位等source未来变真，也不能追认正常；走原有限已知拒绝/partial close或Q。不撤旧held，不补造938或CS。

## E. 局部状态与中文操作沿草图

view phase3：0IDLE、1READ、2BODY_CHECK、3OWNER_CHECK、4COMMIT、5DONE、6KNOWN_FAIL、7Q。pending及保留位不等active；dispatcher_job10才借2257。OWNER_CHECK前提尚未真齐时待所有RE返回已capture后释放短job，phase回0且pending保持1/selector不改；重新eligible时重读全文，不能沿用被其它job覆写的assembly。DONE保本scope已完成事实；KNOWN_FAIL仅真实合法失败处分候选且所有本地native已知关闭，verified仍0、不免938/RETURN，Q保未知债。两者不自动再试。无新scope时pending0/phase0/issued-captured0/readpending0，verified按SQ0；三个保护只由D4实际身份事件建立/退休解除，暖清不当关闭。

| 相对沿 / 旧事实 | 操作及必须后续观察 |
|---|---|
| q0 原S294已锁/绑定完整 | 后续登记pending/role；原CS/seal/INITIAL/490/END仍独立推进，候选未齐不占任何engine。 |
| q1 材料真齐且O短job旧空 | 获单dispatcher SOURCE_VIEW/2257借用，核保护/身份，初始化issued/captured；无本沿外来capture直透。 |
| r0…r(n−1) READ | 每沿至多实际一个M1 RE，只有RE加issued；r1…rn分别capture旧返回，只有真pending加captured。其它native仲裁stall保原游标/body。 |
| r(n+1) BODY_CHECK | 末capture成为旧事实后核pad/完整LG或CLJ、实际注册/839映射；非法不正常推进。 |
| r(n+2) OWNER_CHECK | 反比原J/L/C body、真CS或no-start/seal、处分及生成门；旧fire先计。尚未可判真实前提时保pending释放短job，unknown/错身份Q。 |
| r(n+3) COMMIT | 再核保护/同Hgenrole、无本沿冲突新事件、无新publication，后沿注册SQ verified1；不借同沿位给S形成938。 |
| 后续DONE及S原路径 | S见旧verified且自身效果真quiet才938→真实record收据→RETURN→502→term；pending真实终结、2257归原dispatcher。 |
| 最终两个IF05 ACK消费 / 全旧债空 | 封未来view形成点并真处理pending，后续原CH退休/保护解除；不能靠已返pin/本地timer清原body。 |

正常和取消同沿均沿SQ旧125/324/449/commit fire先计；新qualified stop优先阻新324/938正常形成，旧held稳定。CS已success后L失败不改CS；CLO正确闭包与EDGE完成也不允许late cancel回滚原effects。每次只核当前一个scope，正常LOAD/CLO一次各n56/22，重复/错误query另按真实事件收费。

## F. 费用、语言及三契约

| 新具名补列 / 相对SQ48609 | bits / 去重条件 |
|---|---|
| J父LC270 | 270；可投影CJ142，保存跨held/fire/join/借用，不能扣C0独立接纳CJ142/CS源。 |
| L commandLC270 / CLASS125 / SEAL863 | 1258；独立真正目的，各原生命周期需同时存在，seal消费保值。 |
| C commandCLJ438 | 438；与CW父438 source是不同目的，不免费别名。 |
| 保留/查询/global dispatcher具名控制 | 25 = 保留3 + pending1 + selector1 + phase3 + issued6 + captured6 + readpending1 + dispatcher_job4；全局job4只计一次，不与CH kind/op混同。 |
| 本候选selected并集 | 48609+1966+25=50600；新增具名1991，不称新增硅片FF或完整FF。 |

JCS592、S839/294、O2257/640/512、CH1160、CH0及M1均原不同实体收费/借用；本卡不加宽副本、RAM或DSP承诺。L/C两端RQ/RSP/CANCEL/PREPARED、原C0/J/L/C配置/状态/有效性/历史、O/source qualification全scalar及组合mux仍须SV-B01唯一实例并入；三个保留位不让这些体消失。50600不是60800XLR可用量比较，不推fit；综合会实际映射。

READ工作量一次LOAD56、CLO22，总78 nativeRE；不同时读取/不再加CH LG+CS86或冷三record108RE。单issue无stall、首实际RE记r0时，末capture rn、后续三个核验沿的COMMIT rn+3，条件最早interval为LOAD59/CLO25，合84只是两个局部序列；q/pending、租借/查来源/仲裁/重试、consumer及DDR效果等待另μ，没有成功上界或算法fps承诺。

| RTL A–L | 本任务契约 |
|---|---|
| A数值 / J身份 | 全unsigned原270/438/592/863/839/294及H160/gen64/role；地址先10、计数范围0…n后6；业务load_id0合法、generation0非法，各namespace不可cast。 |
| B时钟 / C接受 | 同core posedge旧fire；readonly view只有保护/真实valid历史下可用。原valid-ready火保持；RE下一capture、末capture后check，不裸跨域。 |
| D有效 / E反压 | valid0不当body0/absence；pending不推进cursor；原held/sideband/expected稳定，例外仅原C0合法private flush。保护不冻结必要源收尾。 |
| F延迟 | E条件表与实际native事件分账，μ未知；所有真实wait可停，有限失败监测不制造quiet。 |
| G复位 / H配置 | 同步rst高火0；暖隔离保身份/保护/pending/未来effects，只有原合法共同隔离及恢复门能复用；新配置不覆写旧LC/CJ/CLJ/CS。 |
| I存储 | 单M1/单2257借用/单dispatcher；原1R1W/20×512无同址冲突，每沿最多一issue；未齐资料不占CH或O缓冲，无免费新增端口。 |
| K CDC / L实现 | 本段同域内部控制，CSI/HDMI/DDR PHY另证。Ti60F225/I3/SV2009及现装工具为共同目标，真实资源/STA/时钟/引脚尚未执行。 |

C++生产控制N/A，本段硬件元数据核验；未来独立参考不借DUT诊断生成期望。三契约：①共同完整Canny/全N EDGE与原bit layout不改，no-start/失败不伪成功图；②另证实际fire、RE/capture、借用、形成点/旧债/隔离，不拿函数顺序代硬件沿；③原真实J/CJ/LC/CLJ/Hgen及事务/取消位置映射参考事件，body逐bit/pad/数量核，数值与源/效果证据各自比较。

## G. 实施与验证计划（NOT_RUN）

共同指定设计/范围/基线批准后拟在R4 work的唯一directory dispatcher、原parent/class_loader/closure_engine及S scope adapter映射此view/形成门；不生成第二O或改冻结C0公共口。计划符号source_view_job/source_body_keep/source_final_formation_guard；确切文件清单/工具/case/期限随共同基线冻结，当前无实现文件。

| TEST / REQ | 有限输入、事件与独立期望 / 方法 |
|---|---|
| SV-T01 / 01/02/06 | 6×5及1920×1080正常LOAD/CLO：原M1 n56/22完整词/pad/fullidentity、真CS/seal/原op5；独立逐fire/native/字段记录，nRE及条件沿分别核；不拿fixture代全图数值通过。 |
| SV-T02 / 01/02 | failedCS、late L失败且CS reason0、CH3未stored/STOP；原真CS仍可view，不等待CH record；同CJ但L863.CS与J真592的计数/FS/诊断差一bit必须拒qualified；合法no-start不存在CS3，heldCJ不得伪未启动。 |
| SV-T03 / 03/05 | CS/seal/pending仲裁各停8、INITIAL/490/op5各停8；待材料不占BEGIN/2257/native，必要记录正常推进；938/term永不作source前置。 |
| SV-T04 / 04 | LC/863运输valid消费、原体保留、CLASS125连续逐pair复用、三个lease/IF05/pending各stall、同Jhandoff；历史body仍可读，工作槽正常推进，保护非query debt，无退休互等；错gen/reset保Q。 |
| SV-T05 / 01/06 | M1错词/pad/末capture/地址0/511/越界、旧RC assembly高位、另一job写回；actual捕获与body域正确，不能半体复用/错身份授权。 |
| SV-T06 / 05 | LOAD verified后CLO839换scope、938形成/BEGIN/commit/RETURN各边界cancel；旧1不授CLO，非法早held938保持并拒正常，不持唯一槽等source追认。 |
| SV-T07 / 04/05 | CH无opened但有/无S绑定294/938债、partial/错OPEN、known absence/unknown；不伪IF05、不免收据/物理债；合法闭合或保Q且报告未完成。 |
| SV-T08 / 全部 | 真实完整C0→L/S→C/S→O组合，GENERAL/NO_STRONG/NO_WEAK retain0/1；独立全N EDGE与全部源/许可/native/物理/CH台账同时核。 |

局部core25MHz验证钟、seeds0x431/0x1060、连续stall≤8、控制case失败监测200000cycle/wall120s；完整图上限由实际μ/全机资源另冻，不套局部限值删正常路径。未来TB非采样沿驱动、更新后观察，strict EOF/unused/XZ/finish；不预生成TB/向量/runner，不以timeout授成功。

## H. 双向追踪

SV01→O/M1/S原839294→D1/2/E→source_view_job→T01/02/05；SV02→J/L/C→D3及SQ原生成规则→source_owner_check→T01/02/08；SV03→O/J/S/CH→D1/2/4/E→source_view_eligible→T03/08；SV04→J/L/C/O→D4/E退休→source_body_keep→T04/07；SV05→S/O→D4/原938与换scope→source_final_formation_guard→T03/06/07；SV06→O/native/全机实例→F→source_view_cursor/dispatcher_job→T01/05。反向每新增位/计划符号只服务这些要求，实际代码/结果NOT_IMPLEMENTED/NOT_RUN。

## I. 门槛、实际未决

SV-B01：本卡已选M1＋owner的有限路径/保存/门控/25位及nRE；实际全机实例端口、原L/C/J必要scalar/各形成点、S839保护与真实注册绑定映射、dispatcher所有类μ及pending失败处分仍须联合代码前的设计闭合。不会以3bit租借位或宽线口头声明原槽已实际存在。

SV-B02：BK/PS真实DDR no_future_effects/写可见性/共同reset、生产摄像/HDMI/CDC/缓冲/引脚、完整RAM/FF/DSP/服务、全部十一项整包/reference/cases/files/tool基线仍OPEN。本卡不把未测当已测，也不以永远拒绝/降级代目标。

§10.3①B、②C、③D、④E、⑤F、⑥B/D/G、⑦G/H、⑨保存/读回/呈现、⑩A范围/来源具名；⑧完整组合及物理阻塞未闭合，**NOT_READY**。无新批准问题，R2既有指定问题仍待答，R1本地审计例外不扩大。

## J. 变更恢复

这是SQ-B01的有限联合选择：读取从未定view变为唯一M1直读＋原owner保留，宽体/控制补列、S938形成点明确。旧SQ/CH/CW/R2字节不变，未批准实现不启动。恢复按实际hash/审批→整体源合同→D1/2/3→D4借用/旧债→E/F/G，不能只读取verified1恢复scope。

## K. 实录

本轮仅只读资料/规则、纯设计与静态数值/组合审阅、控制面文档/checkpoint；根保存后实际读回/独立审阅结果另在进度及事件登记。无新业务RTL/模型/功能脚本/TB、仿真/综合/PNR/STA/bit、下载/安装/网络/正式DB或硬件操作。未登记正式审批，不以此段预写实现PASS。

## L. 中文阅读与交付

读B整体及三个反例→C owner/交接→D1资格/D2真实地址/D3原槽/D4保留与938形成→E逐沿→F具名费用→G/H有限证明→I剩余。一次最终路径是“真实294→源材料齐→M1全读→原owner核→旧verified→真实938收据→RETURN→502→term→最终metadata退休”。人工理解验收待用户实际反馈，完整五基础/六高阶软件交付仍未完成。
