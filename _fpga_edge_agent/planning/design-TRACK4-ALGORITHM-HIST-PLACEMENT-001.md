# TRACK4-ALGORITHM-HIST-PLACEMENT-001：全半径表地址与授权增量 v0.1

2026-10-05；LOCAL_DESIGN / NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED。本卡纠正 PERFORMANCE E9 的 OPT-H1 地址候选与新增 camera ring 的重叠，给出保留旧布局的具体分配。H1 仍是待采用的等价提速路线，本文不生成 RTL、模型、初始化文件、脚本或 TB。阅读 B 整体→C 归属→D 地址/接口→E 中文操作→F/G/H→I 未决。

## 通用计划字段

- Goal：在板卡现有 DDR3 生产区容纳 131072 个全半径计数，不与五 camera ring、三 RECORD 或旧私有对象重叠；保存完整数学、授权和关闭边界。
- Current state：PERFORMANCE v0.2 的 H1 候选段从0x05440000开始；INTEGRATION v0.8 的五 ring 也从该处开始。原 SLOT 布局的 AUX 尾部尚有619648B未分配。
- Target state：冻结 H1 地址、独立实体/格式与同源阶段关系，随后同算法 adapter、目录/cache、性能/资源和整包批准一起采用；当前仅关闭具体地址算术冲突。
- Gap：H1 provider/微调度、实际服务、额外消息/算术资源、联合文件/schema/批准仍未闭合。
- Assumptions：1920×1080、Ti60F225/I3、仅现有板卡资源；DDR3已允许。原128MiB production arena和256MiB物理容量不扩大；不新增算法/采集fps或场景 admission。
- Open questions：I 的 HP-B01…04，不用地址可装下替代全机能运行的证据。
- Dependencies：根唯一v0.2、PLAN_TEMPLATE、PERFORMANCE E9、SLOT纯布局、DIR、R4R及新STAGE/LOAD候选。
- Milestones / Detailed steps：核原冲突→核AUX实际尾端→固定H1/guard→定义独立descriptor/pin→算法等价adapter→容量/服务/联合审阅→READY指定批准→实施/验证；bit之后停止。
- State transitions：仅设计记录，不写正式PROJECT_STATE、TASK_LEDGER或数据库。
- Artifacts and hashes：A为实际来源；本文及随后新布局数据由外部基线记最终SHA。原JSON/计划保持原字节。
- Validation：地址整数核查是静态设计证据；初始化/投票/微调度/协议/质量/工具均NOT_RUN。
- Failure handling：越界/格式错/未知效果不发布峰前缀；pin、目录实体和held旧义务不靠阶段切换或reset消除。
- Human approval gates：现R1批准仅覆盖R1；H1未READY，先闭合具体联合设计，再等待指定版本/范围/基线批准。
- Rollback：新增本卡，不移动原任何对象或改写原HDK/R1/批准输入/旧布局。
- Completion criteria：地址与角色无重叠、真实接口/关闭/资源/服务成熟，获批后完整逐位/协议/质量/物理工具及bit证据；当前并未完成整个十一项。

## A. 来源与修订界限

| 来源 | 实际SHA256 | 本轮采用范围 |
|---|---|---|
| PLAN_TEMPLATE | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 | 前序本轮全文读取，通用字段及整体/局部/语言/验证/追踪 |
| PERFORMANCE v0.2 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 | D5及E1…3/E9；全HIST524288B和旧候选地址 |
| INTEGRATION v0.8 | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF | A候选布局/ring及完整生产边界；五ring到0x07C40000 |
| SLOT-JOIN v0.1 | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | D1/AUX逐对象guard、旧私有与RECORD归属 |
| production-slot-layout-v0.1.json | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 | groups、三RECORD、HIST及AUX结尾实际数据；不声称此文件已含H1 |
| PRODUCTION-DIRECTORY v0.1 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA | D1…5，45实体/64目录及pin、独立holder与阶段 |
| R4R v0.2 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 本轮定位object5/HIST21、半径域、E2步骤4/5、PROFILE structure；原数学与关闭不偷改 |
| production-resource-gap-review-v0.1.md | 3785F7187E1F1537DBC2B3DCB9EE0A7777D43B11B8F573AEE992FF7F75CED585 | 保存后本轮191行已分段全文读回；采用地址反例、conditional resource/pin而非实测fit |
| STAGE-CAPABILITY v0.1 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 | 保存后本轮298行已分段全文读回；D3/F2的32cache与mask、原RC26槽及namespace不自动含新H1 |

本增量若未来明确采用，只覆盖PERFORMANCE E9中H1的旧地址/容量余量候选及DIR D1的一个保留目录位置；保留旧表、ring、guard和所有既有身份布局。未采用时DIR现行45实体仍有效。本文没有直接修改任何旧文件或正式运行表。

## B. 整体外部行为与可检结论

| REQ | 保证及观察点 |
|---|---|
| HP-REQ01 | H1只放原AUX未分配尾，旧21 private/三RECORD/五ring均不移动、不alias。 |
| REQ02 | 131072个uint32物理record承载uint21票，bits31:21恒0；radius0实际初始化0且不投票，合法r为1…131071。 |
| REQ03 | 新实体/访问族与原typed HIST5、8192项tile隔离；base/目录index/同宽ref不产生访问资格。 |
| REQ04 | 每seed完整clear→一次完整E POINT投票→全部效果settled→按r升序读/峰处理；峰数学、容量/失败及所有close不缩减。 |
| REQ05 | 同源、profile、POINT版本、R3距离RNE/normal门、SMOOTH/plateau/排序不变；真实访问/NUM次数差异另登记。 |
| REQ06 | 额外pin/lookup/holder/算术/DDR RMW计资源与周期；地址可装下不推导全机fit、fps、QoS或质量通过。 |

冲突反例：旧H1[0x05440000,0x054C0000)全部落在ring0[0x05440000,0x05C40000)内部。camera正在填帧时投票/清HIST会破坏RGB，读取被camera改过的HIST也失去计数前提；正确descriptor也不能修复同一物理地址的错误分配。新位置不需要移动camera。

正常：原私有区尾guard结束→新增H1数据→新增guard→原AUX剩余→camera独立区。错误：索引131072、bits31:21非0、越guard或错误holder均不发普通访问；已接纳旧事务和未知效果仍须真实关闭。数学优化的完整等价和资源/服务待G/I。

## C. 归属及连接

```text
O 固定布局/实际descriptor/阶段holder
  └─HP-IF01 实际H1 writer资格→ RC_H1_ADAPTER（待联合）
同一immutable POINT + PROFILE → 原R3距离/normal
  └─HP-IF02 radius17/vote21→ H1_TYPED_STORE → 原RAW/DDR/journal
真实全表settled → radius升序计数 → 原峰数学 → RAW/SMOOTH完整seal
CLOSE_REQ发起 → 本支data quiet → 实际pin RETURN_REQ/ACK → CLOSE_ACK
  → 其余真实RC/metadata闭合 → 实体RETIRE
```

O唯一创建/退休实体，RC不从固定base自己登记grant；STORE保持单writer/latest/原子和真实副作用账。H1_TYPED_STORE不是直接连AXI的无鉴权内存。数学oracle独立由原图/profile/POINT定义产生原计数和峰，不读DUT票表来回填黄金。

## D. 地址、字段与组合

### D1. 新半开区间

| 内容 | 开始 | 结束 | bytes/权限 |
|---|---|---|---|
| 原AUX已用至旧FIT_STATS guard | 0x05340000 | 0x053A8B80 | 428928；全旧记录保留 |
| 新H1数据 | 0x053A8B80 =87722880 | 0x05428B80 =88247168 | 524288；131072×4，无尾padding |
| 新H1 guard | 0x05428B80 | 0x05428BC0 =88247232 | 64；禁止普通item/整拍扩读 |
| AUX仍未分配 | 0x05428BC0 | 0x05440000 | 95296；不自授任何用途 |
| 原camera五ring | 0x05440000 | 0x07C40000 | 41943040；保持原slot/来源 |

0x053A8B80为64B对齐；524288+64≤619648，且新guard end严格小于AUX end。整个已分配包络仍130285568B=124.25MiB，当前production arena余3932160B=3.75MiB；256MiB板物理区另128MiB保留。新增H1真实逻辑524288B、guard64B；它用原包络的未分配空间，没有减少旧HIST21504B或三历史RECORD，也没有把padding/guard算成免费初始化对象。

### D2. 候选独立descriptor/访问族

本卡若联合采用：descriptor index45为新H1，46…63仍未分配；object_kind8新增10=FULL_RADIUS_HIST，与旧private HIST的kind133/typed object5不同。descriptor仍640，record_bits32/item_capacity131072/byte_capacity=rounded_capacity524288；valid_count22沿真实全表资格，origin_kind3/JID96及同source/job绑定保持。46实体在原64槽中，无新增目录RAM，但实际初始化/lookup/held状态非0成本。

目录ref64/version64、grant64与holder_link160仍由实际O独立分配；本卡不提供这些运行值。RC holder的真实注册/phase/作用域通过STAGE增量接入，必须显式获H1独占writer，原HIST grant不能用在H1。与其余RC pin同时保留时，先前条件61-pin上界至少须增计一份到62，只有旧上界全部前提成立才有此算术；closing/returned metadata仍占quota，完整联合上界与状态另核。已保存STAGE-CAPABILITY v0.1当前32cache恰覆盖3 LOAD/GRAD、3 CLOSURE和26 RC，不能容纳新增一份H1：保守新候选须33cache和四个33bit mask，至少另增295+4=299 selected-state bits，不是完整FF/XLR成本。SC当前RC object26非法，未来新H1内部选择/完整tuple来源必须显式修改该映射；原公开OBJ的object26仍非法，不能静默转成H1。

H1内部请求字段至少完整H1 ref/version/grant/真实RC scope、独立seq64、op CLEAR/VOTE/READ/SEAL、radius17/vote21；radius17足以表示0…131071，越域在高位检查/未窄化的adapter入口拒绝。0只作clear/读取的全域零位，不接受VOTE。实际wire body/purpose/echo/terminal schema须与provider一起冻结（HP-B01），不能拿原OBJ799 index/old5无声明cast。这一最小字段列表不是已可连端口。

地址base+4×radius先33bit，正常末record为[0x05428B7C,0x05428B80)。byte序为原canonical little-endian：低byte承载低8票，bit20最高计数，高11位显式0。若窄WSTRB/整拍RMW，真实DDR adapter另授同对象拍范围和排他、保留其它三个record；每16B拍恰4计数，数据段本身16B对齐，不需读guard。单RMW不是单21bit DDR更新；已issue未知拍不伪造logical计数成功。

### D3. 算法、初始化及关闭屏障

原PROFILE structure中radius_bins14=8192保留为原逻辑分块宽度；16×8192=131072是新物理全表容量。H1没有将14bit字段窄化写131072，也没有直接改旧layout/algorithm值。未来必须在共同物理存储/实现选择manifest中声明H1，并证明原PROFILE数学与所有结果相同；若adapter实际改变数学/schema则需具体新PROFILE版本，不可假称等价。

H1全表CLEAR是新明确服务义务，原单tile CLEAR不能代表524288B完成。初始化前READ/VOTE禁止；全部131072计数实际写0并结副作用后才开启该seed投票。原r0距离定义仍由R4R E2/R3：每个完整POINT按同一中心、距离RNE、normal门和合法非零radius恰投一次，票总≤E≤2073600，21bit不能绕回。

所有投票效果结清后按r升取同值，使用原±8 box sum、外域0、radius1邻居、正plateau最小radius。可以保留原tile读/27×21跨界holding，让峰adapter仍以逻辑tile组织；也可顺序全表窗口，但必须明示窗口/延迟/尾关闭并作全序列逐位比较。原RAW/SMOOTH各512，第513 CAPACITY；结果/诊断/去重及无峰路径仍完整。NUM call_seq/STORE count是实际新轨迹，不把16遍计数复制到1遍，也不声称原TERM字段删掉了。

H1进入新seed或复用资格前，旧READ/RMW、held reply、latest/journal/DDR pending均结清；旧phase权限capture不被新clear抹掉。取消同沿先结旧fire，unknown保真实prefix/Q并独立CLOSE；CLOSE成功且pin RETURN实际完成后O才退休，整个RC/stage holder仍汇合其它子scope，不用H1一支成功代整体quiet。

## E. 中文操作草图

E01 布局：读原AUX尾和ring范围→先判旧H1重叠→从原尾87722880保留524288+64→核AUX剩余及全arena→只在新候选记录中登记，原JSON不覆盖。有限纯数据另存[production-hist-placement-v0.1.json](../experiments/track4_algorithms_20261004/01_baseline/production-hist-placement-v0.1.json)，没有runtime权限或可执行fixture。

E02 创建：确认本次共同版本实际采用H1且结果/RC scope已存在→O核45槽和整物理区→分配非零新ref/version与真实holder/pin→保存全部descriptor/phase，最后发布资格；失败保已分配身份与返还义务，不能用kind10/base存在猜created。

E03 每中心：锁旧POINT/profile/center→完整CLEAR及settled→E条真实POINT、距离与normal gate→每合法r唯一VOTE并核票数/echo→全部效果完成→r升序原峰判定→RAW/SMOOTH真seal；没有全遍结束不得发布完整峰表。

E04 结账：按独立实际op/NUM轨迹与原数学对照→成功或错误都停止新issue、结held/effects→独立CLOSE→实际RETURN→O核全RC别支及父资格→RETIRE。本表返回不自动返回POINT/其它RC表/三RECORD。

E05 验证：原H0与候选H1由同原图/profile独立计算每r票、RAW/SMOOTH峰及最终记录→另用真实hardware fire/关闭检查trace差异→量出单seedCLEAR/随机RMW/读峰服务及资源；不能以地址检查替代这些结果。

## F. 语言与RTL A–L

C++ N/A，本轮只做文档与PowerShell有限整数算术，无业务模型/脚本。未来模型用显式无溢出整数，H1 uint32存21bit前核高11零；RTL A 数值/D2宽度，B 时钟沿原真实生产clock，C/D 接受/valid按真实op，E held/旧phase与反压，F 服务/吞吐待新预算，G reset/unknown隔离，H 旧PROFILE及显式实现选择，I descriptor/pin/数据/guard，J 同源/seq/namespace，K DDR/core真实CDC另合同，L 全机综合/PNR/STA/bit必须实取。未获得实现批准，不生成候选端口代码。

数学契约：同每POINT/中心、r、normal、票及峰；硬件契约：唯一writer/RMW/latest/真实初始化/完整effects/close；对应契约：原POINT/ref/profile/seq、逐bin/峰/终态完整映射，访问量减少可记录但不能省关闭或伪造旧计数。

## G/H. 验证计划与双向追踪（仅文字，NOT_RUN）

| TEST | REQ/IF/局部 | 独立检查/未来文件职责 |
|---|---|---|
| HP-T01 | 01；D1/E01 | 原末guard、新首/末/guard/ring不重叠；H1 layout与descriptor review |
| T02 | 02/03；D2/IF01/02 | kind10与old133隔离；radius0/131071/131072、高11非0、错holder/phase不越权 |
| T03 | 02/04；D3/E03 | CLEAR未settled拒vote/read、samebin连续RMW、最大E、高位拒绕回；store protocol |
| T04 | 04/05；峰adapter | 跨8191/8192等16块边界、r0/131071、±8/plateau/空tile、513峰；独立全r oracle |
| T05 | 03/06；D3/E04 | cancel/held同沿、旧reply、未知DDR；CLOSE_REQ→data quiet→RETURN_ACK→CLOSE_ACK，不能等CLOSE_ACK才返pin；其它RC branch未结阻整体退休 |
| T06 | 05/06；E05 | H0/H1同完整1080p的逐bin/峰/完整RECORD与独立GT，真实访问/NUM差异及服务/资源另记 |

每个未来模块职责只对应创建/鉴权、票RMW、峰adapter或独立比较；layout不是runtime grant，原数学GT不会从DUT表生成。反向文件/源/端口/实际TEST结果将在共同实施基线冻结，现在无业务文件hash/通过率。

## I. 当前未决与READY边界

| OPEN | 下一项闭合 |
|---|---|
| HP-B01 | 完整H1请求/echo/CLEAR/SEAL/终态及RC provider实际接线；原OBJ与新内部服务如何组合必须具名，不能借最小字段列表直接写代码 |
| HP-B02 | STAGE/目录新增index45（实体总数46）的boot/register、H1 pin/冷热body/权限phase与全机quota共同版本；SC32→33cache/四mask和新内部H1选择须显式兼容，不挤掉旧26 RC，候选62不替完整proof |
| HP-B03 | CLEAR/投票RMW/latest/流水窗口、峰reader及真实RAM/FF/DSP/服务/计时；2.654208s只为E=N/C_s=256下POINT字节nominal理想尺度，非帧延迟 |
| HP-B04 | 是否选择H1、完整文件/profile/实现选择/质量与必要RTL case/基线仍未联合成熟；目前不是R1批准的一部分 |

§10.3①…⑦有本局部整体、接口候选、中文/语言、反例及验证追踪；⑧四个真实缺口尚在，⑨保存后实际读回并从B/C呈现，⑩实施集合未冻结。NOT_READY；地址冲突有候选解，不等整机可综合运行已证明。

## J/K/L. 实录与阅读入口

实际有限整数核算：base87722880、data_end88247168、guard_end88247232、AUX余95296、arena余3932160；未运行协议/数学/质量/综合。这一候选修正不删除旧H1失败地址事实，不覆盖旧布局，也不升级任何正式审批/硬件状态。

阅读B/C→D1地址→D2实体与授权→D3数学/关闭→E操作→G/H反例→I未决。人工理解须用户真实作答，Agent未代签；未来生成bit后本次停止硬件步骤。
