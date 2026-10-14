# 三阶段 holder 实体与能力快照的有限纯设计审阅

2026-10-05；NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED。只保存本审阅，不改旧planning卡、不生成生产源码/脚本/TB；R1的两模型、RTL、TB、runner冻结输入不变。本次审查Root提出的三份stage holder与32个ALGO pin候选，后者是pin数，不能解释为32份完整job。

## 1. 实际来源与范围

控制入口实际重读；根v0.2与控制规则绑定本次已核22基线的实际不变hash。本次以下是有限段读回与定向命中，不冒称全文联合审核。

| 来源 | 实际范围 | SHA256 |
|---|---|---|
| R4-CLOSURE | D1 L93–99、D2 L115–122、D3 L147–155；B/C定向L78/83/85/87，D3 L134 | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 |
| R4-RECOGNITION | 前轮实际D1/D2 L102–119、D3 L130/134，本轮D4 L157–170；B/C定向L91/94/96/98 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| PRODUCTION-DIRECTORY | 前轮实际D2–D4 L94–128，本轮D3/授权/关闭定向L104–110/131/151/157 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| CONTROL | 定向L96/113/125/173/175/181 | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 |
| SLOT-JOIN | 定向L94/101/104/134 | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA |
| RAW-STORE | 定向L97/115/148/172 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| R2 | 定向L80/87，GRAD collector缺口仅沿来源，不补造接口 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 |
| PERFORMANCE | 定向E2 L208及目录/字段成本L152/189 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 |

来源原文与下面新增候选分别标明。各源末尾已重新hash，实际与本表一致；本文是下界与合同候选，不是完整资源/性能通过。

## 2. 整体可行方向与原body复用

可行候选：固定stage index0 LOAD/GRAD、index1 CLOSURE、index2 RC，各最多一份原完整上下文；同role的新session不得与旧closing、return metadata、lookup/native pending或终态运输重叠。O为每次实际stage实例独立分配非零generation64，next从1、最大值合法一次、随后exhausted。operation_id/load_id/closure_id/recognition_id保持原父J分配和0合法规则，不能cast、截位或+1成为generation。

原R4C L95明确LOAD与CLOSURE使用分端口角色，H160可能同值，S查找键必须含角色。原RC L104同样指定RECOGNITION namespace。候选lookup应使用 `(namespace/role, 全H160)`，再定位O内部 `(ALGORITHM_STAGE,index,generation,epoch)`；公共LC270、CLJ438、RJ2257、BIND、STORE/CLOSE中的H160不改。index固定不意味着访问自动合法，GRAD role不能因与LOAD同slot而取得CLASS权限。

原完整body已经在有限源中有真实保存义务：

| stage | 原body与持有人 | 候选复用前提 |
|---|---|---|
| LOAD | L保存LC270/CJ（R4C L78/97），L→S绑定同LC270（L115） | L的已锁LC可作为完整原body；若O回链借它，须新“context lease”直到O holder元数据真退役，不因LC_TERM已消费清body |
| CLOSURE | C旧IDLE接纳锁全文CLJ438、C→S同CLJ438（L120/121） | C的已锁CLJ可复用，但须保存到全部O查询/return/cache引用结束；不能复用S共用当前会话寄存器，因S可能转去RC/下一stage |
| RC | C接纳锁完整RJ2257、C→O全文保持（R4R L116/117） | 一份RC完整RJ由该唯一协调器持久保持，26 pin回链同一stage；不能省掉原BIND运输的源held/目的private或CLOSE记录 |

CONTROL L113/173/175另有唯一历史J657、完整源handle/旧C/启动与返还义务；SLOT L101/104的BUILD_BIND成功只给结果对象绑定，之后仍须LOAD/GRAD全部真实PREPARE。**LC270只有CJ、load_id、CLASS ref，不能单独认证SRC/GRAD三pin。** 源的完整注册/lease/J链和真实GRAD build/provider准备必须成为stage0关联的实际证据。若从既有O历史J/目录查询完整SRC、GRAD授权，应定义其记录locator、原generation、保持及唯一writer，不能借“单J”省成裸固定地址。GRAD185也不是一个已冻结的GRAD_BIND/CLOSE合同；该部分仍需新增。

## 3. 一个可落位的有限冷存候选

方案A：O内部只增加三份完整原body冷记录，不增加每pin的RJ副本：LC270+CLJ438+RJ2257=2,965 bit。20bit native各14/22/113词，共149词=2,980实际词位，padding15；尾词分别低10/18/17有效，高10/2/3为0。

当前DIR D4 L131的M1已用RESULT三份282词，282…511原未分配230词。候选stage0在282…295，stage1在296…317，stage2在318…430；149词可放该真实空段，431…511余81词。独立静态区间检查实际核对：每段end−start+1分别282/14/22/113/81，各下一start=旧end+1，覆盖0…511恰好512词，重叠0、越界0。不是新增RAM容量，也不是已经实现的共享端口：RESULT/holder的1R1W仲裁、短事务/一致读取、完整2257bit assembly及pending另计。当前CONTROL RAM source914/CMD966不能一次装2257bit，不能拿现有命令直接盲cast；须在目录内部新有限native事务或正式分段完整提交合同。

方案B：O借原L/C/RC完整body，新增独立lookup/context-lease接口而不再复制body。其“新增冷body=0”只在实际owner保完整原body至O元数据退休、旧lookup全闭合且同role新接纳被挡住时成立；原源held/目的private、真实关闭台账仍在原预算，不能重复省。当前稿没有这些接口，不能直接扣2,965 bit。方案A更容易说明唯一存放和保持；方案B须证明多owner读取/变化/时钟及完整返回，暂不选择最终方案。

二者都只复用body。LC270/CJ不能取代原CLASS_SEAL863/CS592，CLJ不能取代queue tail/latest账本，RJ不能取代PROFILE原pin、各对象descriptor/pin、STORE frozen close或R3 pending。

## 4. 初始化与关闭不能互等

```text
真实start/BIND接纳并锁原body
 → O预留空stage和generation、记录BINDING原context（普通读写禁止）
 → 原对象/创建身份/独占/容量/全mask核查，内部授pin并写定
 → 真实BIND成功及回执消费后LIVE，随后才ordinary操作
 → 停新ordinary，兑现旧typed/raw/journal/native/held/effects
 → 独立内部pin RETURN并冻结一次减计数/关闭事实
 → STORE形成包含pins_released/access_pins_closed的真实CLOSE_ACK
 → 旧ACK/TERM/context查询/返回元数据全部闭合
 → 后续才FREE/复用该role slot
```

反例A：lookup要求stage.bound1才允许ACQUIRE，而bound1要所有pin已创建才置位，首次BIND永久等待。必须区分BINDING的内部授pin资格与LIVE ordinary资格；BINDING并非允许caller普通读写。

反例B：O等STORE CLOSE_ACK先消费才允许pin RETURN，STORE又等pins_released才形成ACK。原R4C L149/151/153与RC L161/163明确后一条件；应由STORE独立本地read/write/RMW/response/journal无未来effects事实触发O RETURN，而CLOSE_ACK形成前只退访问资格，**不清stage原context和返回metadata**。holder metadata真实退休在ACK运输结束后，避免同一个“closed”位同时代表效果关闭、pin返回及记录复用。

反例C：复用单S当前H/phase寄存器给旧LOAD metadata，LOAD close后切CLOSURE时H可能同值但CLASS权限不同。原context应保持在唯一LOAD holder或独立冷copy中，公共STORE lookup必须含namespace/role；旧RETURN按原generation匹配，不能查当前全机H。

拒绝BIND的“未建立pin”必须是真的。若已部分授予，取消/写中/回执错误不得回无pin拒绝后遗失权限，应保存partial原mask/grants并独立关闭或Q。wrong echo/lookup miss不清holder、不减引用。共同软件epoch不能清旧generation或未知effect。

## 5. 冷lookup性能风险和新能力快照候选

原DIR OP04 L151及D3 L108要求完整descriptor/pin/holder校验；未许可省略。pin512用16bit native需32词，descriptor640用20bit需32词，完整RJ2257还需113个20bit词。若每个ordinary OBJ操作都按当前串行思路重读两表及完整holder，数十拍成本必须入总预算。

PERFORMANCE E2 L208给load+GENERAL闭包全链保守请求上界13N+4=26,956,804。把该工作量代入逐请求32+32实际native读取，即1,725,235,456 read issue cycles，按**尚未STA的100MHz候选**为17.25235456秒；用96拍示例为25.87853184秒；若再逐次完整读取113词RC body，相同请求规模示例177拍为47.71354308秒。后两个只是架构成本尺度，闭包并不读取RC RJ；它们不能当实际算法时间、所有job下界或测得帧率。最终capture/校验/仲裁、DDR与算法计算另外计。即使独立RAM以后能并行，也须新实际端口/lookup合同和预算证明，不能从当前串行合同里无证删周期。

候选新快照：BIND一次全文核完整namespace/H、原context、refs/version/grants、创建/初始化/commit资格及固定geometry；随后建立有generation绑定、唯一O writer的stage能力记录。ordinary typed操作仍核稳定active_H、真实role/object/phase、权限mask和cached原grant，再以足宽index/record_bits/base/capacity限定范围。STORE继续核自己的实时valid prefix、queue tail、latest/journal、原atomic group和tx序号；不能把BIND时valid_count0冻结成永远0，也不能以静态capacity放行未初始化洞或绕过最新值读取。

任一目录mutation/revoke/权限转换先封新ordinary准入；保旧快照/原pending使已held/accepted操作真实履约，独立关闭所有query/native/transport/child/journal/effects；再使旧快照无效并执行真正RETURN/新grant/phase或version更新，完整重验证后发布新快照。permission更新不能覆盖旧WRITE grant记录并把其closing债隐藏；POINT WRITE→immutable READ、CLASS LOAD→CLOSURE、ANN/RECORD commit后的reader必须有明确屏障。CLOSE/RETURN仍查原完整记录和实际ledger，缓存miss或invalid不是释放证据。

这要求新的内部ready/phase-barrier接口：例如COMMIT的旧RSP已真实交付后，新READ提议可以在原held槽等待新capability可用，但不能默认为当前D3允许更快查表、组合穿透新版本或把暂缺权限当算法成功。快照只加速权限核查，DDR effects、typed stage数学、journal原子组和所有关闭成本不减少。

## 6. 新增状态的透明下界

不含快照的方案A：新冷body2,965bit/native2,980bit。若各holder新增generation64、lifecycle3（FREE/BINDING/LIVE/CLOSING/RETURNED_METADATA/Q）和phase4，加全局next_stage_generation64/exhausted1，列出192+9+12+65=**278 bit**；不另重复保存H160，可从原完整body按正确字段映射读回。权限表若固定role/object/phase派生，ROM/LUT和实际phase事实仍有成本。若再列每stage六个冻结关闭事实，则另18bit，下界296bit；这不含native assembly、bind/return held、真实effect/计数与allocator在途预留、索引/仲裁、cache或GRAD新增关联，不是完整热FF。

一个明确的快照选择（不作为最优/已选）：3×active_H160=480；3×holder generation64=192；allocator65；3×lifecycle3=9；3×phase4=12；各stage snapshot_valid/no_new_ordinary各1=6；32个pin的ref64/version64/grant64=6,144；32个对象各READ/WRITE/RMW权限3位=96，合**7,004 bit热记录下界**。若同时缓存每pin base32/byte_capacity29/record_bits10/item_capacity22，另32×93=2,976，合**9,980 bit**。固定role/namespace/index可由实际表派生，其逻辑不为0成本；闭包/RC实时valid_count、initialized/commit、borrow、返回mask、native pending、cached-data组提交、query/回应/transport、完整计数、mask变化/耗尽仍未列，不得以9,980当全机FF验收。

从278到7,004/9,980是不同实体选择，不能全部相加后又扣原同一实例。若复用现有原holder热H或借原pin表行作cache，须逐实例说明现有寿命/端口和已经计入的容器，方可扣一次。32是pin数，不要求32份RJ2257，也不代表所有32个geometry完全不同。可研究常量geometry/部分字段按固定对象派生，但必须先保持完整grant与真实phase权限。

## 7. 必须由联合稿新增的内部合同

1. **STAGE_REGISTER/CTX lease：** 唯一source owner、完整原body/关联J/SRC/GRAD、index与独立非零generation、BINDING资格、真实partial grant及拒绝/Q分类；O每次保留只消费一次generation。
2. **STAGE_LOOKUP：** 固定namespace/role+全H与请求object/op/ref/version/grant全核；完整body或安全snapshot服务、源/目的保持、旧lookup pending、wrong echo/Q，不用当前phase组合值重建旧callback。
3. **STAGE_ACTIVE/phase barrier：** 正确BIND回执及所有先决prepare真完成后才ordinary；phase推进必须有原STORE真实commit/close facts，caller自行报phase不授权限。
4. **CAPABILITY_CAPTURE/REVOKE/UPDATE：** 全绑定核查、缓存实际字段和维持者、no_newordinary与旧held履约、invalidate/rebuild时点、native端口/时钟/同址规则，实时bounds/latest仍由真实STORE负责。
5. **LOCAL_ACCESS_QUIET→PIN_RETURN：** 不等自己的typed CLOSE_ACK消失；O按原身份冻结每pin一次减计数，错误/Q保存记录；STORE据这些事实形成原ACK502/504，不改公共body。
6. **STAGE_METADATA_RETIRE/CTX_RELEASE：** 原关闭回复及所有查询/运输/pending退出后释放原context；同role新session不能占旧槽，值cache与原记录脱钩必须完成实际复制与引用关闭。
7. **LOAD/GRAD共同关联：** 三pin的SRC真实ref/version/源创建、CLASS build、GRAD完整provider prepare/close及可能重叠的两typed来源，role明确；LC270不能单独替代该合同。
8. **服务与资源：** 冷/热唯一实例、M1存放/lookup调度、正常每op真实成本、阶段转换最坏等待、五ring/提前ARM/no-loss服务共同预算；禁止靠CAPACITY拒绝或超时假闭合填正常证明。

结论：三单实体共同回链可以避免26份RJ复制，原公共H160无需改；方向具备有限落位候选。初始化/返回顺序、同role旧metadata屏障、完整GRAD关联与快照寿命是必须新增的内部合同，现有D3及原BIND未冻结这些改变。本记录推进实体与预算选择，仍NOT_READY。
