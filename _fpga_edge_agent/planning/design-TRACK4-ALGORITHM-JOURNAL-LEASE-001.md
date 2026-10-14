# TRACK4-ALGORITHM-JOURNAL-LEASE-001：共享日志池的 entry 与 group 租约 v0.1

## A. 状态、来源与计划入口

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。按PLAN_TEMPLATE A–L，阅读整体B→职责C→接口D→中文草图E→预算F→场景G/追踪H。本卡是RA-B02/SM-B04的有限共同候选，没有冻结实现输入或关闭整包阻塞。
Goal：让RC的一槽ordinary/逐lane DENSE和旧BK两槽提交有唯一实际pool/native owner、完整身份及分别退entry/退group的合同。Current state：原文只列pool及局部FSM，没有RC租约端口。Target state：真实许可/来源/效果/返还桥落位后形成可实施版本。
Gap / Open questions：JL-B01 新JPOOL与实际唯一native RAM/176效果writer、BK legacy适配及prepared/state证据桥；JL-B02 RC O/SC完整rounded许可、真实group来源/POINT持续借用；JL-B03 physical可见/no-future、END、typed消费/双方控制静止/失败终态到退租的可信桥；JL-B04 完整实例/控制/冷热落位/服务与RAM/FF/DSP预算。全部OPEN，候选body不代真实提供者。
Assumptions：完整1080p、五基础/六高阶、原识别/质量要求不变；仅板卡现有资源及已允许板载DDR。保持原RQ799/RSP872/KEY287、object/op0…5及本卡只op1/op5 journal业务；INIT/READ/CLEAR/admin不借本租约自动授权。下一候选ANN64新op6必须另共同修订，当前op6仍非法。
Dependencies / Milestones / Detailed steps：真实来源→统一pool/互斥→wholegroup→entry/native→分支关闭→容量/接口组合→审阅/读回→共同接口/资源闭合→指定READY/批准→独立work实现验证。配置/R1批准不授本实现；R2/Q0原问题仍待答，不重复发问。
Human gates / Rollback / Completion criteria：只写新控制面设计/报告、文档事件与进度；原HDK、旧卡/基线、Manifest/state/DB/硬件不改。不生成源码/参考/TB/功能脚本或跑EDA。本卡身份由外部检查点登记；无Git commit。必须解决JL-B01…04才有READY，撤回候选保历史身份，无业务回滚操作。

| 当前事实来源 / 用途 | SHA256 |
|---|---|
| [RA](design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md)：单槽/wholegroup/580 assembly/费用 | 33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA |
| [SM](design-TRACK4-ALGORITHM-RECOGNITION-STAGE-MAP-001.md)：实际phase、ordinary顺序、有效集 | 5DBAC492D10C6CE752B8C9AC236906A72305855F4F78803AA9BDA2630FE5EA09 |
| [DIR](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)：生产576/native/176/effects | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [BK](design-TRACK4-ALGORITHM-CLOSURE-BACKEND-001.md)：两entry reserve/commit/END/响应/retire | 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 |
| [RAW](design-TRACK4-ALGORITHM-RAW-STORE-001.md)：失败隔离/原全部postimage流程 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| [SC](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)：616/740、真实许可/phase/quiet | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [R4R](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)：原typed identity/seq/16lane原子隔离 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [PK](design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md)：真实16B范围/邻位保护 | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 |

## B. 外部行为、要求及例子

JL-REQ01：一个新拟JPOOL承担唯一native RE/WE、slot分配/租约及原176bit效果更新；只有一个全局journal group owner，NONE/BK/RC/Q。空槽不许可第二组。物理/摄像/显示其他端口不因剩槽获得journal权限。
JL-REQ02：RC group绑定实际原RQ799及全tuple，持续保护其来源；entry租约仅当前完整span/真实permit，slot由owner选择。任何caller payload、非零permit、位mask或同宽H都不代真实授信。
JL-REQ03：native允许当前真实租约的0…28词，实际地址29slot+word≤463；production576+尾4zero。word27成功状态来自真实effects，不能caller改SUCCESS；RE/WE接纳与完成/捕获分开。
JL-REQ04：entry退租与group退租分开，正确ACK验证/消费后再等旧运输/metadata静止才复用；归还条件不等待它自己尚未产生的ACK。
JL-REQ05：ordinary保真实872消费后退entry；DENSE16各lane真实可见/关闭后退entry、wholegroup保持至最终872及关联关闭；失败不回滚，真实UNKNOWN/Q保原身份/效果。
正常：lane0 index276和lane1 index277共享byte727/16B unit45，lane0可见/END/退entry及metadata空后，lane1真实读新后端保邻位，两票均+1。反例：退lane0时group owner变NONE，BK插入或DENSE READ观察部分16票，均禁止。只有journal mutex仍不足，实际STORE/O需同时禁止DENSE外部READ/SEAL。
正常ordinary：RSP872反压时保持entry/group；真实matching消费及旧引用静止后才退entry，再退group。取消前同沿已fire照记，旧held继续；未开始lane后缀实际失败处分，不能全组success。最终bit仍是后续软件实现/验证目标，本卡不进行硬件动作。

## C. 职责和总体连接

MOD-JL-POOL新拟职责位于唯一shared STORE内，独占native/effects及group互斥、lease allocators、真实receipt/returnedmetadata；原BK/新RA-J只能提交受控意图，不直接驱第二组RAM端口。
MOD-JL-RC（RA-J/RA-Q）保原799/872/580及独立prefix/失败记录，group/entry/control expected不跨lane覆写；MOD-BK保原two-permit/two-entry与一次logical_commit，不借RC FSM。MOD-O/SC提供实际完整tuple/rounded许可；物理adapter提供真实可见/no-future/END来源；这些桥不是本卡已有实现。
路径：真实accepted RQ799/来源→JG_BEGIN→JPOOL group锁/STORE原子隔离→实际span许可→LREQ/LGRANT→29WE/29RE→可信prepared验证/真实logical事件→物理write/可见/effects→END/独立冻结→entry RETIRE/ACK→group FINISH/FACK→metadata空。ordinary先typed RSP消费再entry；DENSE每laneentry先退、末typed响应才group。
BK路：原S_AUTH599/receipt674、真实2槽同时reserve→两prepared→单logical_commit/tail→两writeback/END→typed449消费→原group release；新增唯一pool adapter必须保原不同namespace/H与响应，完整适配端口仍JL-B01。
不选BK0/1＋RC2静态分区，因为分区不解决group/最新视图互斥；不把余14槽当新并发额度。初始化直接有限chunk路径、ROW/CAM/IMPORT等journal client未注册；若后续需要则先具体设计，不拿group空闲自动通行。

## D. 消息和组合合同（纯声明）

同core posedge、同步高有效rst，独立valid/ready深度1；沿前旧valid&&ready&&!rst为fire，捕获后后续状态校验。新消息**字段高→低**；嵌入原KEY/RQ保持原布局，和cold journal低→高分开。所有scalar unsigned，合法0的seq不能当无expected。
RC物理source port固定namespace5/stage_index2值2；BK不是可cast的另一RC端口。下表是候选新消息，不是现有已连接端口。

| IF / 方向 | body及位宽 | 条件与含义 |
|---|---|---|
| JL-G01 RC→POOL BEGIN | RQ799/stagegen64/caprev64/ref64/version64/grant64/group_seq64＝1183 | 仅实际op1(length1)或op5(object8/length16)，完整payload/phase及来源真实核；不直接授DDR访问 |
| JL-G02 POOL→RC GRANT | echo1183/group_lease64/status2/reason6/granted1＝1256 | 只有0/0、granted1且真实非零group lease才绑定；其它无新group事实不清旧绑定 |
| JL-GENV | BEGIN1183/group_lease64＝1247 | 独立完整group身份；actual group owner稳定，直到正确FINISH回执及旧metadata静止 |
| JL-G03 RC→POOL FINISH | GENV1247/outcome2/lanes_done5/proofmask8＝1262 | ordinary真实完成prefix0…1，DENSE0…16；成功分别1/16，失败按实况。mask仍须owner可信核 |
| JL-G04 POOL→RC FACK | echo1262/status2/reason6/returned1＝1271 | 0/0/returned1是真归还收据；保持元数据直到正确消费/双方旧运输静止 |
| JL-E01 RC→POOL LREQ | KEY287/stagegen64/caprev64/ref64/version64/grant64/span_permit64/request_seq64/member5/span_base32/span_length7＝779 | member16仅ordinary；DENSE0…15。base16对齐、len16/32/48/64（DENSE≤32）且全actual rounded许可 |
| JL-E02 POOL→RC LGRANT | echo779/lease_id64/slot4/status2/reason6/leased1＝856 | 0/0/leased1、nonzero lease与slot0…15；slot由owner挑，不caller指定 |
| JL-ENV | LREQ779/lease_id64/slot4＝847 | 全部后续entry原身份，存到正确归还及旧metadata静止 |
| JL-E03 RC→POOL WORD_RQ | ENV847/native_seq64/native_op1/word_index5/data20＝937 | op0RE且data0；op1WE；word0…28，不能靠高位截断纠错 |
| JL-E04 POOL→RC WORD_RSP | echo937/rdata20/status2/reason6＝965 | RE正确原20bit，WE成功rdata0；此回复只native结果，不证明DDR/END |
| JL-E05 RC→POOL RETIRE | ENV847/outcome2/proofmask8＝857 | 原entry结束门/真实evidence，mask不为授权，自己RETURN运输不作为前置 |
| JL-E06 POOL→RC ACK | echo857/status2/reason6/returned1＝866 | 0/0/returned1是真entry归还收据，held或未正确消费期间不重租 |

stagegen/caprev/ref/version/grant/真实permit/两lease均nonzero；original tx_seq、group_seq/request_seq/native_seq可0。span end先33bit加检查同对象rounded/初始化范围，后收32bit；LREQ的base/len必须由installed原799及PK/lane重新求得并逐项比对，不相信caller地址。
group_seq、request_seq、native_seq为RC各自独立64bit新publication序列；group_lease/entry lease由POOL各自独立非零64bitallocator。最后最大合法仅一次，下一EXHAUSTED；held不重分配、cancel不回收、warm/phase/H变化不reset。真正cold全旧资格隔离才初始化，耗尽不阻旧WORDS/退休/ACK履约。
internal status0OK/1REFUSED/2BLOCKED/3Q，reason沿明确SC族：0NONE/1BUSY/2IDENTITY/3LAYOUT/4RANGE/5PERMISSION/6BARRIER/7UNREGISTERED/8EXHAUSTED/9PROVIDER/10UNKNOWN，11…63非法。OK必须reason0。未授LGRANT的REFUSED/BLOCKED suffix lease/slot/leased全0；group未授同理group_lease/granted0；Q保原expected/真实分配事实，不根据新suffix0清旧租约。ACK非成功returned0，不代旧租约已返。
内部原因不cast RC/BK/RAW/cold cause；正确内部失败到RC typed失败时格式/错echo为OBJ_PROTOCOL6，合法EXHAUSTED为18，实际provider/许可失败按OBJ_FAILED7，原正常取消仍CANCEL16。BUSY/BARRIER无新授权，原业务expected继续保留，只有真实新可用/关闭事件后可新内部seq申请或明确失败，不能timer循环重复同seq。与BK、physical cause的完整原因适配仍JL-B01/03。
LREQ不携group_lease仅在真实单RC source绑定下安全：完整KEY/gen/rev/tuple等installed BEGIN，owner内部路由固定真实group_lease；换BEGIN前旧全部requests/expected/held/returnedmetadata/native真空且旧KEY不再接纳。若无法证明这条绑定/防重放，必须加nonce并修body，不以caller称单组替证（JL-B02）。
对op5，BEGIN保存原799/rhos，actual已COMMIT POINT资格/ordinal<E及持续借用由真实RA-Q/O给出；LREQ的member对应严格下一lane，item=277member+rho[member]，不能全局theta寻址。group mutex不能替实际STORE DENSE READ/SEAL gate；gate须在BEGIN获准前安装并跨所有lane至最终872/关联关闭。

## E. 局部状态、不变量与中文草图

### E1. group与entry分别持有

group_owner2=0NONE/1BK/2RC/3Q；group状态3=FREE/CHECK/GRANT_HOLD/ACTIVE/FINISH_CHECK/FACK_HOLD/RECLAIM_GAP/Q。entry状态4候选FREE/CHECK_LREQ/GRANT_HOLD/LEASED/WORD_CHECK/ISSUE/CAPTURE/RSP_HOLD/RETIRE_CHECK/ACK_HOLD/RECLAIM_GAP/Q，其余非法。WORD native depth1；各状态不代真实prepared/physical/借用关闭事实。
BEGIN fire只锁完整1183，后核实际accepted来源/tuple/phase/全局旧group空与持续借用，真实reserve/source protection/隔离成立才安装group_lease并保持1256。RC正确验证消费GRANT后后续沿才发entry；BK旧held继续履约，不因候选仲裁撤回。
LREQ火只capture779，后逐项等installed group/真实spanpermit及受限当前member，保真实可用slot和source lease后安装ENV847、保持856。没有槽/许可不发保护READ、不取得新physical债。grant fire不自动等消费者已核合法，坏echo保原expected及实际reserved事实。
slot/group ledger、immutable BEGIN/ENV、原RQ/rhos和失败prefix直到各自真正退休才清有效。相同slot号码无资格、旧lease id差1拒；跨namespace同H无资格。lease_active与历史receipt.leased1不同，不用历史成功字段当仍live。

### E2. 唯一native及production word27

WORD fire锁完整937，后核ENV、真实LEASED/phase及单调native_seq、word/index/payload；再发唯一nativeADDR_EN/RE或全WE。实际地址扩位29slot+word≤463、后才收9bit；464…511拒绝。ADDR_EN0保地址不能当无访问，RE/WE另控制；native20全WE11，两半10bit。
RE issue的下一真实沿从旧pending捕获20bit，不能同issue沿看新Q；WE接受沿不造完成。形成965后held全文不变，正确验证消费及实际native/运输空后才下一word。pool不从一般ready/caller mask推全entry静止。
entry数据生产576低→高address32/length7/post512/state2/cause6/zero17，physical580尾4zero。准备29WE/29RE、全身份/padding与canonical验证仍RA真实流程；POOL仅在可信同ENV的prepared/逻辑事件事实成立后允许后续物理write，消息/body或“29次请求数”不代已验证prepare（JL-B01）。
word27 bits540…559低11是postimage高11、bit11…12是state、bit13…18是physical cause、bit19必须zero。选择POOL的cold27_latch20及valid1**仅保护当前RC单entry/完整ENV**：在其真实验证READ word27时保存，直到该RC entry实际退休/GAP前不切身份。其STATE_WORD WE须low11逐bit等该实际latch、bit19零，state/cause由唯一176实际effects/物理来源计算核对，不能caller写SUCCESS；反复合法状态更新也只改变state/cause，postimage高11保持不变。BK两entry不使用这份RC latch或新WORD合同，严格沿BK113–114以当前真实完整assembly保护状态WE，实际WE完成才切另一entry；其两槽adapter/保护证据及预算仍JL-B01/04，不宣单latch护两槽至退休。RC整entry prepared及失败cause桥仍OPEN，不另偷跑未计 native READ。
原16×11效果账＝published1/settled1/effect2/written7每slot共176bit继续实际保存；RC还保每1…4单元fragment，不用176aggregate替代。physical state SUCCESS与written/prefix要真实全跨度成功，FAILED/UNKNOWN保原历史；native WORD ACK、B或cal_done不代write可见/无未来effects。

### E3. RETIRE和ACK，不等待自己

outcome0 USED_SETTLED、1 UNUSED_NO_PHYSICAL、2 FAILED_CLOSED、3 PROOF_PENDING。0…2才可能归还；2允许历史内容/prefix UNKNOWN但真实无未来effects已证明；3仅报告未结，不释放，消费BLOCKED只结该次控制运输。仅新真实关闭proof到达后可另outcome0…2请求，不能重放同body或计时凑释放。
entry proofmask8按位0…7：native/WORD请求捕获及运输空；postimage/assembly数据借用空；physical route/W holding空；实际可见/no-future；latest新读门已封且结果冻结；span END真完成；独立prefix/失败历史已存；operation分支结束门成立。每位由POOL自有native/effects与可信源实际ledger计算并比request，不能只收八个1。
ordinary位7须真实872正确消费且旧数据/关联空；DENSE位7须本lane真结束/独立prefix已保存且wholegroup仍受保护。该mask不等自己RETIRE/ACK运输空，也不等父pin RETURN/O retire/typed CLOSE_ACK。
旧proof成立后只转RETURNED_METADATA语义并形成866，不直接free。ACK全文held，正确被消费者验证消费，再等双方旧GRANT/WORD/RETIRE/ACK expected/held/native/借用运输在后续旧状态真空，RECLAIM_GAP以后才租同slot，新id必不同。ACK_HOLD不接duplicate RETIRE；metadata已退或slot重租后旧RETIRE一律IDENTITY拒，不造第二减计数。
ordinary顺序：物理完成/可见→native/state检查→END/独立终态冻结→872形成/保持→正确实际消费及旧引用静止→entry RETIRE/ACK/GAP。872不能等entry或group退休先形成。DENSE顺序：每lane可见/END/独立prefix→entry RETIRE/ACK/GAP→下一lane新读latest；每次lane结束保group及原799，不发中间872 success。全部16真实结束才whole872；失败仍无成功，保真实前缀/当前partial/未published处分。

### E4. FINISH和真正group退休

ordinary success lanes_done1；DENSE success16；失败ordinary0…1/DENSE0…16是严格完成prefix，不是attempt数，未知current lane不会增加prefix。entry全正确退休/metadata空、whole872正确消费、旧NUM/typed关联/physical读取写入空、未来新lane已封、独立失败历史保存后才FINISH。
group proofmask8位0…7：新publication封闭；本group entry及native/data expected/held/metadata空；physical route/holding空；实际future效果资格闭合；STORE原子读/封存隔离结束门及冻结结果；全部span END正确完成；独立完成prefix/失败历史已保；wholetyped872正确消费及旧关联静止。未closed/Q不可报全1。
FINISH前不等待自己FINISH/FACK运输或为身份回包保留的group source lease先释放；数据未来引用与身份控制借用分开。正确事实成立后保持1271及GENV/source保护；FACK正确验证消费、双方旧控制/returnedmetadata静止后后续GAP才解除source lease及group owner，恢复别的组。当前 group保护/返回body桥仍JL-B02/03，不用FACK fire一个脉冲当双方正确消费证据。
DENSE隔离跨所有lane与末响应；失败私有INVALID不会开放成功读/SEAL。原RAW/DIR全16 prepared/一次logical_commit流程被本RC串行分支明确替换，不改BK。整体对外无半组成功、无rollback；共同版本需吸收，不称兼容原冻结内部实现。

### E5. 停顿、取消、复位

同沿先记旧请求/RE/WE/commit/回复fire和真实效果，再处理cancel/停止新publication；原held及来源租约照约兑现，未提出后缀真实失败处分。错echo/非法reason/duplicate nativeSeq保expected、slot/source/原历史，不反复执行WE。UNKNOWN未来效果/Q留slot/group，可凭真实合法关闭新proof结债但不改旧失败成功数。
warm/phase/H变化不清global allocators、owned receipt、Q或来源；rst禁fire但不把DDR/native/租约解释为零。只有真实全域冷隔离可初始化；metadata旧静止和新分配不同沿，full pop沿不同时复用。响应消费只一个事件，语义正确与来源关闭由实际ledger另证。

## F. RTL、预算及跨语言

RTL A：字段高→低、uint33端点、native addr扩位、done5先扩6核0…16，written7先核真实跨度后窄化；B/C：旧沿fire/capture不穿透/真实RE下一沿；D：seq0、零ANN与invalid区别；E：body/ENV/GENV/expected及proof停顿保持；F：租约/WORD/退租增加控制服务，不承诺固定K/fps；G：共同同步高rst隔离不清旧租约；H：真实phase/tuple/来源锁到退休；I：一group/RC一entry/BK两entry/native depth1；J：KEY/member/batch/POINT/物理字节各身份分开；K：本卡core同域，DDR真实跨域仍物理合同；L：目标Ti60F225/I3，实际工具/时钟/引脚及RAM/FF/DSP/STA/PNR尚未运行或全冻结。
选择保守控制保持槽（每端分别一份，不用wire宽度当免费存储）：entry ALLOC/WORD/RETIRE请求互斥可共享一937bit请求+一965bit回复；group BEGIN/FINISH互斥一1262bit请求+一1271bit回复；**RC client与POOL provider各一套**，共2×(937+965+1262+1271)=8870bit。每端再独立ENV847＋GENV1247，合4188bit；共13058bit body部分。incoming私有capture与outgoing held/expected是两端各自真实槽，不按同域就删除；BODY转用只在旧valid/expected/借用为空的后续沿，未声明可与BK/RA已有槽免费alias。
cold27_latch20+valid1另21bit，仅RC当前单entry，已具名RC合同body/latch部分13079bit；这份latch不抵扣旧BK两entry实际assembly及保护费用。额外tag/valid/expected/allocator64+exhaust/owner/FSM/word与prepare计数/失败关闭/permit/可信source/消息桥及实际BK接线仍JL-B04，不把13079当完整FF/XLR。保守vector未选冷热实现；完整实例账可具体优化存储但须证明生命周期，不能先扣完整body。
pool仍16×29=464个20bit词9280bit，一20×512 RAM候选；原176效果bit保留，无新第二pool。RA799/872/580部分及fragment、BK独立body/两674和176sole writer归属统一后按实际实例去重；新消息七种6107、group五种6219仅格式之和，不等实际13079保持预算。
租约接口不改变RA普通每entry59native issues，DENSE16＝944；新增control/callback/state判定另收费。STATE_WORD latch无另加READ选择；若实际prepared验证无法保该latch/来源桥，则须补真实READ/状态及预算，不能隐藏成本。处理速度/DDR资格/QoS/最大等待仍未知，显示60Hz不代算法fps。
跨语言：共同整数/身份/bitpack沿R4R/PK不变；独立参考不借DUT lease日志造数值黄金。硬件执行按真实publication/RE捕获/WE/效果/返回与旧GAP，软件数组free不代native借用关闭。对应契约逐fullENV/GENV和原799/872关联，cancel比实际prefix/未知历史/终态，不只看success位。C++未选工具标准，本卡无模型/可执行实现。

## G. 实施与验证计划（未生成/未运行）

先真实pool/旧BK native适配→RC O/SC/POINT来源和全span桥→prepared/effect/END/正确消费返回→完整实例/冷热/服务→共同freeze及READY指定批准→独立work RTL/参考/TB/EDA。拟JL-POOL/JL-RC/JL-BK-adapter/JL-proof-adapter单元，文件/符号清单依共同freeze，当前未有业务源码。

| TEST | REQ/IF | 输入/事件 | 期望及来源 |
|---|---|---|---|
| JL-T01 | 01/G01 | BK两槽live、RC BEGINheld，余14slot空 | 不发RC保护read，不并行组；BK原held不撤回 |
| JL-T02 | 02/E01 | 同slot/lease差1、同H跨namespace、错tuple/rounded端点 | 拒/保旧expected，地址不自授；SC/PK |
| JL-T03 | 03/E03 | RE issue/capture分沿、nativeRSP反压、WE seq replay | 不早捕获/重复WE；旧元数据保持 |
| JL-T04 | 03/E2 | RC word27改post高11/自称SUCCESS、重复状态WE、word29/addr464；BK两entry交错 | 拒非法，RC完整ENV/latch不切；BK按其真实assembly及WE完再切，不借单RC latch |
| JL-T05 | 04/E05 | entry ACK长期held、ACK fire同沿新LREQ、旧RETIRE重放 | 保租约，后续GAP再新id；不重复减计数 |
| JL-T06 | 05/DENSE | 276/277共享unit45、lane1后BK插组/外部READ | 第二票读latest不擦旧票；group/typed读隔离均持续 |
| JL-T07 | 05/ordinary | 872held、END完成但响应未正确消费 | 不先退entry/group，MAKE_RSP不等退休 |
| JL-T08 | 04/G03 | FACK held、来源借用live、FINISH自身输送槽非空 | 不等自身ACK先产生；保身份至正确消费/双方metadata空 |
| JL-T09 | 05失败 | lane5未知partial、cancel和old WE同沿、FAILED_CLOSED | 真实prefix/partial/never-published保留；future没证保持Q |
| JL-T10 | 02/seq | MAX合法最后一次、warm reset、wrong ack及late oldKEY | 不回绕/旧义务继续、不换绑定误认 |
| JL-T11 | 03/prepare | 29请求但某RE未capture/非法padding/可信prepared证据缺 | 不logical提交/不物理写，不能request数代verified |
| JL-T12 | 01/BK | 两postimage prepared/取消同commit沿及失败回复held | 原tail/双效果/真实settle/449消费后退休，不套RC逐lane |

场景为纯文字；未选bench seed/实际物理时延，不称测试覆盖通过。拟局部native、group/entry/typed端到端、反压/复位/取消相互覆盖；实际camera/DDR/全包EDA仍整个工程范围。

## H. 双向追踪

| REQ/来源 | MOD/IF/草图 | 计划单元（未生成） | TEST | 真实代码/证据 |
|---|---|---|---|---|
| JL-REQ01 / DIR135/BK109/118 | POOL/G01–04/E1 | sole native/group arbiter、BK adapter | T01/T12 | 仅来源与有限设计审阅 |
| JL-REQ02 / SC110–118/RA40/SM | RC/O/G01/E01/ENV/E1 | source lease/permit binding | T02/T10 | 实际桥OPEN，未实现 |
| JL-REQ03 / DIR131/BK113–120 | POOL/E03–04/E2 | native sequencer/word27 guard | T03–04/T11 | 未实现/未运行 |
| JL-REQ04 / SC132/RAW256 | POOL/RC/E05–06/G03–04/E3–4 | entry/group retirement | T05/T08/T10 | 真实消费/关闭桥OPEN |
| JL-REQ05 / RA29/SM133/BK115–128 | RC/BK/E3–5 | branch settlement/prefix freeze | T06–07/T09/T12 | 未实现/未运行 |

反向每个新增control/body/latch对应真实范围、借用或效果要求；失败冻结/完整预算缺项不加空泛需求包装完成。原RC/J/O别的模块及数学值不被本卡替代。

## I. 门槛与评审

整体/样例B、职责C、接口候选D、中文草图E、语言/部分预算F、场景G及追踪H已有实际内容；真实桥/无阻塞/完整资源服务未满足JL-B01…04。保存/读回/独立审阅以外部检查点记实际版本。READY_FOR_REVIEW未达到，NOT_APPROVED；不请求批准这个仍有实质缺口的版本。理解验收待用户实际作答，无测试/实现通过声明。

## J. 变更、恢复与范围

将“唯一pool owner”落为明确拟JPOOL职责，新增RC entry/group两套消息及正反向租约寿命；RC串行DENSE是对RAW/DIR all-postimage一次提交内部路线的明确joint delta，原typed整体隔离/真实success不减，BK保持原两槽逻辑事件。
旧RA E3普通先退槽后success与旧RAW/BK冲突，采用SM统一ordinary真实RSP消费后退休；未来共同版本吸收，不改当前来源。ANN64未来newop6不能自动落入本卡op1/op5 BEGIN；必须同步新group mode/SC白名单/coverage/预算再READY，仍保持完全N输出。
恢复复核来源SHA、本卡范围、真实权限/allocator/returnedmetadata及审批；没有当前实现可回滚。只撤候选保文档历史，不能归零slot作为恢复。

## K–L. 实录、交付与人工阅读

当前只有限设计/固定位宽算术/文档审阅及身份核验；没有生成业务源码/模型/可执行测试/TB/功能脚本、仿真/综合/PNR/STA/bit或硬件操作。R1已交付证据保持原范围，正式state仍WAITING_FOR_HARDWARE_BASELINE，Manifest/DB/硬件不改，本地R1审计例外不扩用。
人工路径：wholeRQ来源→BEGIN真实锁组→entry真实span lease→29native准备/验证→真实physical效果/END→按ordinary或DENSE门分别退entry→whole872正确消费/旧关联关闭→FINISH→正确FACK/metadata空→退group。操作者可按D逐字段核对，再按E观察“当时谁仍持有”；不能以软件读过字段证明理解/硬件成功。
完成的是本卡具体合同与有限设计，不是pool已实例化/DDR已验证/完整11项fit。JL-B01…04、性能优化、全实现/仿真/综合/布局布线/合理引脚时序及bit尚未交付，继续原完整目标。
