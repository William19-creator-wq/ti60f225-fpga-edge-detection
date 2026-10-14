# TRACK4-ALGORITHM-RECOGNITION-ACCESS-001：识别对象初始化及单槽访问（v0.1）

## A. 状态、范围及计划入口

Goal：沿当前1080p、完整R4字段和26对象打包字典，选择实际访问结构，补初始化/读改写/原子组/失败及实占预算。Current state：LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN；2026-10-05。Target state：接口、真实提供者和预算闭合后的可实施设计，不把局部选择当整包完成。
Gap：RA-B01真实26对象逐phase/op与rounded初始化权限、冷prefix更新及管理桥；RA-B02单槽租约/逐lane退休及typed原因翻译；RA-B03匹配DDR的写后可见性与无未来效果；RA-B04完整transport/控制实例与时间；RA-B05 R4批次复用的显式CLEAR及NMS快照顺序。均OPEN；新增选择没有消除这些接口阻塞。
Assumptions / Dependencies：仅板卡现有资源，允许板载DDR；N=2,073,600；保持所有五基础/六高阶和原识别条件。既有地址/字段不改，不采用降分辨率、噪声限制、额外存储或阶段别名。原资料、工作源、工具保持只读。
Milestones / Detailed steps：既有几何→分阶段初始化→单记录收集→journal→真实完成/最新值→DENSE组→失败关闭→完整实例/时间→组合评审。前四项的局部选择见下文，其它仍需真实接口。
State transitions / Human approval gates：保持NOT_READY；无实现授权。原R1/预检及本地审计例外不扩到此卡；R2/Q0仍待指定答复。只读/中文设计/静态元数据允许，业务源码、参考、功能脚本/TB/EDA均不生成。
Artifacts and hashes：此卡的新哈希由文档检查点登记。以下为当前真实来源，不伪造commit；旧卡/字典/原输入不修改。

| 来源及阅读用途 | SHA256 |
|---|---|
| [PK v0.1整体及几何](design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md) | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 |
| [打包字典26对象](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json) | D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
| [R4R行为/阶段](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [DIR实际对象/journal](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md) | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [SC阶段与许可](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md) | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [RAW旧全组方法，仅比较](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| [BK有限16B物理模板，仅比较](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md) | 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 |

阅读顺序：B整体及选择→C连接→D交接→E操作草图→F预算/时序→G/H场景及追踪。下一项允许行动是逐phase权限及真实物理接口文档闭合，不是代码。

## B. 整体行为及关键选择

RA-REQ-01：保R4R RQ799/RSP872/KEY287和op0…5；只有一条预期事务。旧held请求/响应按原握手履约；接受请求不等于效果完成。
RA-REQ-02：选择**按对象首次合法可写/prepare阶段，全round64数据区顺序16B清零**。未取得真实权限便等待/明确拒绝，不因RJ接纳自动清24表。相同ref/version的合法mutable复用CLEAR仍执行；已immutable COMMIT或仍被引用的sealed版本不得重清。阶段SEAL不等于永久immutable，只有旧引用/效果全闭合且真实新可写版本/phase资格成立才允许下一次CLEAR。只读EDGE/GRAD、两个历史RECORD、guard/spare禁止清。
RA-REQ-03：选择一个pack sequencer；普通记录用一个真实journal槽存完整连续16…64B跨度，DENSE每lane16…32B。一个580bit assembly中的postimage512字段按不重叠阶段复用为4×128bit收集区，不另分四个bank或同时存第二份512。
RA-REQ-04：选择**一槽逐lane串行＋全DENSE组排他门**；此门跨END、退槽及下一lane一直保持。全部16计数真实更新才组success。它是R4R132允许的串行分支，明确提议替换RAW176/250及DIR OP05 L153对RC DENSE的“全postimage先prepare→一次LOGICAL_COMMIT→整组退槽”内部流程；仅此RC分支，其他actor和ordinary的原合同不改。该共同来源差异尚须RA-B02联合吸收，旧DIR未修改。
RA-REQ-05：上一lane的写已证明可见且所有引用/permit关闭后才退槽；下一lane重新读真正最新后端。不选择免费的forward缓存；单B不足则保持槽/等真实资格，不能推进。失败无rollback，unknown未来效果保隔离和旧身份。
RA-REQ-06：记录全部已发单元事实、完成前缀及组失败；它们不随槽复用消失。服务数量、时间和预算分开，不能用减少槽数假报减少16次RMW。

正常例：DENSE theta0/r276和theta1/r0分别index276/277，共享16B单元45与byte727。前lane写/引用真闭合及可见后，下一lane读新值保邻bit，两计数都增加一次。反例：两个postimage都从旧DDR制作后依次覆盖，后一写会擦掉前一计数，禁止。

## C. 职责、连接及所有权

路径：算法RC→RA-Q受理保RQ799→RA-G按PK字典解范围→O/SC真实对象/phase/逻辑及rounded许可→RA-INIT或RA-PACK→唯一pool owner授一槽→RA-J准备/读回→物理16B子请求→真实资格/END/本地引用关闭→RA-J退当前槽→DENSE下一lane或RA-Q原RSP872。数据和错误沿同一完整KEY保留，不跨namespace共享数值身份。
RA-Q只管单逻辑事务及持续group门；RA-PACK只管一record跨度和邻位；RA-INIT只管连续零写和前缀证据；RA-J只管真实leased槽及本lane退休。O唯一更新descriptor、授权和退休；物理层唯一提供可见性/no-future。均为拟议职责，无实现模块。
完整RQ799是组KEY和rhos的唯一选定存放，锁至整组响应及必要失败冻结结束，不引用算法端已交付的外部RQ；RSP872另有独立held。assembly580由RA独占，既有BK assembly不用于RC，也不从原预算扣除。pool仍DIR现有候选16×29词/1RAM及176bit效果账，不能因RC只租1槽删RAM或其它writer台账。
RC须获得唯一pool owner的实际租约才能读/写该29词；slot由owner选择，算法不指定。租约body、分配/回执/关闭和并存规则尚RA-B02；本卡不声称旧BK两槽FSM已经支持RC。无槽时不发保护读，不取得新未结物理债。

## D. 交接与组合检查

| IF | 形式/数值/前置条件与保证 | 未决接口 |
|---|---|---|
| RA-IF01 RC | 原KEY287/RQ799/RSP872；index32/length21/object5/op5；输入沿前valid&&ready&&!rst为fire；输出body稳定至原握手 | RC status仅0成功/1失败，reason沿R4R，不cast SC/FPI原因；失败effect_ok/value/token为0但不抹真实历史 |
| RA-IF02 INIT/admin | 真实fullH、namespace4值5（RECOGNITION）、stage_index2值2、gen/revision、ref/version/grant/phase、rounded范围及CLEAR来源；连续cursor29 byte offset | SC BINDING只准真实provider prepare已授权的内部INIT；当前完整24对象权限/消息body/prefix更新证据未冻结，RA-B01 |
| RA-IF03 LOOKUP/span | SC原616/740逻辑检查；普通记录真正index/count，unsigned42位数→33bit末端→32bit地址；整个16B保护范围须另核 | 不能把WRITE的保护读变新immutable READpin；普通旧BK只16B，不按599字段宽度推多单元；完整rounded lease仍缺 |
| RA-IF04 JNL | DIR生产576低位到高位：address32/length7/postimage512/state2/cause6/zero17，物理580尾4zero；单槽29词20bit，native RE捕获在实际后续沿 | 不沿RAW旧address26/zero23；word27是postimage高11/state/cause/zero，状态更新保其它位；lane-retire是新RC合同 |
| RA-IF05 physical/END | 每次16B READ/WRITE，KEY/H/permit/local_seq完整；跨4KiB逐16B拆分；原written7先核0…16再存局部written5，不有损截断；每单元effect2/settled及持有者事实 | 可见性、no-future及原因翻译/实际FPI/DR桥未冻结；oldheld、已issued等全部引用结束才END |
| RA-IF06 close/publication | 原RC CLOSE295/ACK504、NUM622/585、POINT/ANN/RECORD真实admin和O退休分开；E=0 POINT合法 | access quiet不等自己RETURN/最终admin结果，不用访问关闭代完整对象退休；retained admin无writer顺序仍待接线 |

SEAL/COMMIT不套单record数据地址公式，不造0byte permit。POINT只commit E前缀，E=0的COMMIT管理路径不额外生成数据READ/CLEAR；按本卡POINT构造前全rounded初始化策略已经发生的CLEAR仍真实记账，不能倒扣，也不选择首写才清的另一路线。ANN全N及RECORD全64仍显式canonical写（F=0也如此）。初始化满不代全图覆盖、格式验证、无writer或immutable token。

## E. 局部中文操作草图

E1 初始化：保持当前完整对象/阶段快照→核实际exclusive writer和prepare/CLEAR rounded权限→cursor从0开始→一次发布16B零写并兑现旧held→核匹配实际响应/写效果/可见性/借用关闭→向唯一O办理端点连续的prefix更新及真实回执/必要读回→后续沿cursor加16；gap/重复/乱序不增prefix。全rounded完成且所有义务空才开放普通RMW。取消先记旧fire，已发布继续，未发布后缀失败处分，不能把部分prefix升为全initialized。
阶段选择：POINT构造前；ANCHOR/SEED/HIST/RAW/SMOOTH/CIRC/上下文按真实circle首次可写阶段；DENSE/NMS/LINE/CELL等按真实line阶段；EXT/SEG按真实segment阶段；PAIR/RECT按矩形阶段；VC/COVER/COVER_META/FINAL按实际核验阶段；DRAW/ANN/当前RECORD按实际输出writer阶段。这是首次使用顺序提议，非完整phase/op权限表；已grant且ACTIVE不自动允许任意表CLEAR。
E2 READ：核真实valid前缀/initialized/phase和冻结或排他最新视图→逐16B收集到assembly.postimage→去前邻位、提取record_bits→检查canonical/高零→原RSP。每次捕获依据旧pending与身份，气泡不推进；READ不访问未初始化洞。
E3 WRITE：保RQ799和原payload→取得完整跨度排他许可/租约→把metadata位置保持独立、按单元填assembly.postimage→替换目标位保邻位/尾零→填生产journal576及尾4zero→29WE准备→29RE读回/身份/pad核→逐16B物理写→每单元真实状态和prefix锁入fragment账→真完成后1WE更新word27→封本entry新引用、END/真实回执及native/route/holding关闭→退槽。最后才能普通WRITE success；不等下一条POINT凑满16B。
E4 DENSE：先锁group_gate和全RQ799→lane_done=0→令本地lane t=lane_done（0…15）、全局theta=16batch+t，而物理item_index=277t+rho[t]，不得用全局theta乘277越出本批4432表；原KEY的index仍为(batch左移21)+point_ordinal→走E3→这一lane全部真实完成/可见/END/引用关闭后，后续沿退槽、lane_done加1→下一lane仍排他地重新读最新后端。lane_done=16且组全部证据成立后才形成原成功RSP；RSP反压时仍持组门，响应fire和旧运输清空后后续沿才撤门。没有中途logical group success，也不宣称一次全16 postimage发布。
E5 失败：同沿先记录旧fire→锁first_reason/failed及私有build INVALID→停新lane/ordinary publication，已held按原约兑现→保当前assembly、槽、permits及per-unit实际effects→真正settle/END或Q。完成lane的历史由独立lane_done/RQ及终态ledger保留；其已退槽不可再读。未知未来效果时保槽、权限及Q；即使未来被合法关闭，旧UNKNOWN内容/prefix仍未知，不改成功计数。冻结完整失败/close证据的存放尚RA-B04，不能因此清IDLE。
E6 算法复用：HIST每中心每个8192bin tile仍真CLEAR；COVER每候选/侧的四4096位仍真CLEAR；CELL/EXT旧读者/NUM/效果空才换run/pass。FINAL冻结后不清，POINT commit后不清，历史输出不清。
E7 新发现：当前R4R272未写明每个新DENSE batch在投票前归零。本卡选择每batch真CLEAR DENSE的全部4432计数及round64尾，32批均如此；但只有旧batch读/NMS快照运输/引用全部结束后才允许清。NMS四行跨batch及theta511/0边界的copy/valid/version顺序须同步修订R4R（RA-B05），本卡不能只加CLEAR便假称完整NMS正确，旧R4R保持未改。

## F. RTL、资源与服务

RTL A数值沿PK42/33/32bit且signed字段按R4R；init_cursor29加16先用30bit核rounded_capacity再提交，不回绕；written7先核范围再窄化5；B/C同core posedge旧状态fire、捕获不穿透发下游；D无效不是零；E反压保持body/许可/assembly；F只列传输数不保证cycle；G同步rst禁fire不清DDR/Q或旧租约；H完整H/gen/revision快照不变；I一RQ/一RSP/一assembly/一leased槽及持续组门；J完整N/E/F/bundle规则；K真实core↔物理域沿联合CDC，不为几何新造CDC；L Ti60F225/I3目标，真实clock/时序及完整FF/RAM/DSP尚RA-B04，未启EDA。
拟议状态state5：IDLE/CHECK/INIT_PERMISSION/INIT_WRITE/INIT_WAIT/INIT_PREFIX/RANGE/PERMIT/GATHER_SEND/GATHER_WAIT/PATCH/JOURNAL_WRITE/JOURNAL_READ/JOURNAL_CHECK/WRITE_SEND/WRITE_WAIT/STATE_WORD/END_SEND/END_WAIT/RETIRE_ENTRY/NEXT_LANE/MAKE_RSP/RSP_HOLD/CLEAR_NEXT/ADMIN/FREEZE_FAILURE/SETTLE/Q（28种）；28…31非法。send/wait的真实expected及ready条件仍由接口闭合，不把状态名当实现。
选定热体：RC自有RQ799＋RSP872＋assembly580＝2251bit。assembly的512postimage字段收集完才patch/prepare，准备和读回不能并发覆盖，物理/END/状态更新引用空后才用于下一lane；否则必须另计512，不能同时声称共享且并发。
选定可具名控制101bit：state5、init_cursor29、span_units3、unit_done3、published4、settled4、effect8、written_prefix20（4×5，0…16）、lane_done5（0…16）、group_gate1、group_failed1、first_reason6、assembly_valid1、slot_owned1、slot_index4、native_word_index5、native_pending1。共**2352bit部分热状态**；不是全部FF/XLR。per-unit新fragment账不能用原176bit aggregate效果账免费替代。
pool仍464word/9280bit/候选1RAM；RC拟占29word/580bit，只有取得owner真实租约才能使用，不声称已存在RC租约，不叠加或扣除旧pool RAM。租约接口、full tuple/lookup/permit/FPI/DR各held、seq/exhaust/cutoff/计数、初始化冷descriptor变更、完整失败冻结、关闭消息及组合控制均尚待实际owner落位收费。DSP与全机fit未证明。
一次完整预清容量比较：21private round64 415104B/25944单元；POINT16588800B/1036800；ANN518400B/32400；当前RECORD4096B/256；共17526400B/1095400个16B写。这不是RJ接纳即全清的权限，也不包含算法重复CLEAR。
DENSE每batch清11648B/728写，32批共372736B/23296写；若一次容量比较已经含第一批清，则其余31批另增361088B/22568写。HIST/COVER/CELL/EXT等重复清另按真实循环，不能用此数字当整帧全部清零量。
按当前29WE准备+29RE读回+1状态WE，一次走E3 journal的普通WRITE或DENSE RMW lane为59个native issues（30WE/29RE），E2 READ、INIT和admin不因此计59；DENSE16共944（480WE/464RE）。普通WRITE最大4R+4W=8次16B data传输/128B；DENSE接口几何上界32个distinct16B单元，所以最多32R+32W=64传输/1024B，不能把“32单元”写成“32合计传输”。
达到32单元的合法接口rho例为[67,46,25,4,111,90,69,48,27,6,113,92,71,50,29,8]，本地t=0…15、item_index=277t+rho[t]都模128为67，起始bit模128为127；每lane两单元且相互分离。这仅是STORE接口几何上界见证，不声称来自真实同一POINT三角投影。
服务表达：一lane实际时间包含许可/租约、收集read、native59issues、物理write、可见性、END及退休；16lane相加并加组管理/反压。INIT是实际逐unit时间之和。没有测得各上界则成功墙钟无上界；native issue数不等时钟数，不承诺算法fps，不把显示60Hz当处理fps。
跨语言三份契约：数值沿PK/R4R；硬件沿本卡逐事务/租约/退休；未来独立参考仅比较真正成功响应、完整零位/邻位及错误历史对应，不用软件数组更新次序冒充物理可见性。C++/RTL/参考/TB未生成。

## G. 验证计划（纯文字，NOT_RUN）

| TEST | 输入/事件与目标 | 期望及来源 |
|---|---|---|
| RA-T01 | 全24对象初次权限不齐，错generation/phase或guard范围 | 不因RJ接纳清零；仅真实授权的连续16B写推进prefix，DIR/SC |
| RA-T02 | 第一个POINT写、E=0提交、ANN/RECORD F=0 | 不等下一item凑beat；E=0管理不额外数据访问、已选INIT成本照记；输出仍全N/64，R4R |
| RA-T03 | DENSE theta0/r276→theta1/r0，前写B已到但可见性未证 | 保槽/组门，不退槽读旧值；证据成立后两个计数都保留 |
| RA-T04 | DENSE结构最坏32单元，任意lane各单元停顿 | 1槽反复租用、组门持续；944native/至多64数据传输为数量账，不能提前组success |
| RA-T05 | 取消遇held或部分效果/UNKNOWN | 旧fire先记、held兑现、未published后缀失败处分、unknown保Q；不回滚或假清 |
| RA-T06 | 连续两batch，HIST tile复用、COVER候选切换、NMS跨511/0 | 真CLEAR先于新票；旧快照/引用关闭才清，halo有效/version正确；RA-B05闭合后才可执行 |
| RA-T07 | journal word27 state/cause更新及下一laneassembly复用 | postimage高11/pad保留；全引用空才复用，不读已退槽 |
| RA-T08 | SEAL/COMMIT/CLOSE/RETURN交错，NUM仍有旧义务 | 管理路径各自兑现；不造0byte许可，不用access close代O退休 |

Validation：本轮仅资料/整数/文档静态审阅，不运行上述场景。实施增量：先闭合RA-B01…05→读回/READY→指定批准及审计范围→独立work实现/参考/TB→仿真→获准综合/P&R/STA/bit，具体文件/符号和冻结执行基线将在READY卡中写清。

## H. 双向追踪

| REQ与来源 | MOD/IF/局部步骤 | 拟议单元（未生成） | TEST / 证据 |
|---|---|---|---|
| 01，R4R接口/取消 | Q/IF01，单预期/held | RC事务槽及错误映射 | T02/T05/T08；未运行 |
| 02，DIR137/SC104 | INIT/IF02，E1/E6/E7 | 分阶段16B清零/原O前缀更新 | T01/T06；仅预算 |
| 03，PK几何/DIR135 | PACK/J/IF03/04，E2/E3 | 单assembly/单leased entry | T02/T07；仅2352部分账 |
| 04，R4R132 | Q/J，E4持续组门 | 串行16RMW/lane-retire | T03/T04；未运行 |
| 05，DIR139/真实DDR资格 | 物理层/IF05，E3/E5 | latest/END/失败隔离 | T03/T05；提供者OPEN |
| 06，R4R真实效果及关闭 | Q/IF06，E5独立历史 | fragment账及冻结台账 | T04/T05/T08；未实现 |

反向核对：每个槽/状态/lease和局部步骤都回指REQ，未来代码/TB回指IF/TEST；新增串行选择不改圆/矩形数值字段或目标条件，不把旧RAW的实现合同当本RC已具备。

## I–L. 评审、变更、实录及交付

门槛①整体/样例、②职责/复用、④中文草图、⑦验证/追踪及⑩范围/来源已有；③接口/⑤完整时序资源/⑥组合及⑧无阻塞尚未满足RA-B01…05。⑨保存后需真实读回/独立审阅。NOT_READY，不申请批准未闭合版本；[规范§10.4](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)要求指定版本与范围批准才实现。
Change：当前选择按首次合法阶段清全rounded、1槽串行、同owner580字段复用；这是明确提议，未改PK/JSON/R4R/DIR/SC/BK/RAW。对DIR OP05 L153只提议RC DENSE内部分支差异，联合来源/权限仍RA-B02，其他actor不改。后续若改16槽全准备、加forwardcache、统一INIT阶段或省清零，必须同步合同/费用/追踪并重审，不能内部偷偷换。
Failure handling / Rollback：只读与文档不改变正式状态；静态错误修卡。实施失败时先保真实原义务/隔离再修改设计，不能clear-to-IDLE。当前没有工作副本或实现可回滚，旧文档/输入原样保留。
K实录：无新增业务代码、功能参考/脚本/可执行测试/TB/EDA/bit或硬件动作；独立有限审阅与文档元数据由检查点登记，未写数据库/Manifest/state/ledger。完整十一项未完成。
Completion criteria / L交付：RA-B01…05具真实owner/精确body/沿顺序/预算并组合无阻塞→文档/代码/测试追踪一致→真实READY批准后才实施验证；目前完成局部结构选择、操作草图和实占部分账。人工理解验收待实际检验，不把解释或局部容量当软件/硬件验收。
