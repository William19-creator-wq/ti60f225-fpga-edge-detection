# DDR整合候选限定组合复审 v0.1

2026-10-04。READ_ONLY_DOCUMENT_REVIEW / NOT_READY / NOT_APPROVED / NOT_RUN。只复核本报告明确列出的接口/地址/效果与两项数学压缩候选，不把本复审当全部局部文件、源码或实施基线冻结。

## 1. 实际输入、范围及最新边界

MASTER正式文件为 planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md。首次实际全文读回A–L输入 SHA256 BE685C171962C59EA0B6F3768BA1B5B691FA8D07D1EA45DD015C124964029DF1 / 32057B，读取前后hash相同。本报告只绑定该实际版本；根Agent后续来源链接/证据摘要/范围批准记录的变更不自动纳入本复审，不声称主稿已冻结。文本行号除说明外按首次BE685输入，章节定位优先。

本轮没有业务源码、功能性脚本、数值生成器、可执行测试/TB、工程、SDC或工具构建；原HDK只读，未运行设备、网络、驱动、安装、仿真、综合、PNR、STA或bit，也不修改正式状态/Manifest/数据库。

已按控制面入口读取规则、唯一根v0.2与模板；v0.2 hash4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2，模板99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。

| 实际来源 | SHA256 / bytes | 本轮实际阅读范围 |
|---|---|---|
| MASTER首次输入 | BE685C171962C59EA0B6F3768BA1B5B691FA8D07D1EA45DD015C124964029DF1 / 32057 | A–L全文，通用字段、D105–109候选DDR扩展、E129–131优化数学、I/J/K/L真实门槛。 |
| RAW主稿v0.2 | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD / 64846 | 实际取源前后hash相同；复读D2授权/RAW字段、D3地址与效果、D4关闭证书、D5目录/journal、E3/E4/E6/E7。本文不把较大工具输出截断部分称为新全文独立审阅。 |
| R4-RECOGNITION v0.2 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 / 83901 | 必要D1/D2身份与单在途、E1完整POINT/E2半径hist/E4全θ投票，E0不变量。未独立复审全部几何/NUM算法。 |
| PERFORMANCE最终必要段 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 / 58487 | 初读30A4D9364DEA20CA62217A55C231752406E19560B8BE325185A2872F3C3C1B54，最终实际前后hash一致复读D5第169–191行及E9第302–312行OPT-H1/OPT-D1/相邻采用次序；不声称全文资源或全系统服务预算已独立复审。 |
| 先前native资源比较报告 | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C | 本轮实际hash及§1–2必要native组织字段；原已安装模型EFX_RAM10的512×20、1R1W证据来自前序同hash读取。 |
| 更新DDR证据报告 | F3492D3D4E7AB0B3B9247AD2A44859F0A52DCE282BC9D7F2A8CB0B8646F3E942 / 20328 | 本代理本轮实际生成并全文读回，同hash报告已停编辑；controller/物理容量/clock/pin/历史工具和新验证边界。 |

最新用户允许使用板卡现有DDR3，外接新增模块不在范围。MASTER通用字段、A25–27、A1、I/J明确记录该边界及旧低指标WITHDRAWN；PC仅仿真/参考/观察。RAW7704第5行保存其写成时旧排除边界；本组合采用其逻辑协议，不把旧PC schema或旧用户边界自动变成生产DDR实现。MASTER明确新的联合版本尚待吸收，是诚实的未合并候选。

## 2. 审阅结论与优先级

在本限定范围内，没有发现需要推翻MASTER D/E核心的新增接口算术、未知效果处理或两项压缩数学反例。该结论依赖文中列明的权限、初始化、唯一writer、旧fire和全量投票等前提；只允许作为后续局部合同冻结的依据，不能写成本项目已可综合、功能仿真/STA/PNR通过或整包READY。

| 分类 | 结论 |
|---|---|
| 新P1/P2反例 | 本范围未发现。 |
| 已修RAW反例相容性 | 相容：fatal未知债可先raw CLOSE，postcommit失败不回滚/不凭失败响应消费释放journal；关闭证明只证明无未来effects，未知written仍0。 |
| 有界body及地址算术 | DR_KEY201、DR_RQ713、DR_RSP731、DR_AP472正确；33bit end检查、物理256MiB、≤64B未对齐最多5拍一致。 |
| HIST/DENSE数学 | 条件性证明成立；不是完整FSM、资源、吞吐或实际差分验证证明。 |
| 原OPEN交接 | 后端完整schema、所有目录/容量/接口迁移、单/多槽生命周期、全机资源/QoS、生产IO、质量与具体实施批准仍OPEN。 |

## 3. D节候选DR schema及寻址

### 3.1 位宽与namespace

MASTER D105列的字段按来源高到低排列：

| body | 独立位宽核算 |
|---|---|
| DR_KEY201 | S96 + raw_seq64 + op2 + byte_address32 + length7 = 201 |
| DR_RQ713 | KEY201 + payload512 = 713 |
| DR_RSP731 | KEY201 + status2 + reason6 + value512 + effect2 + written7 + settled1 = 731 |
| DR_AP472 | AR348 + permit64 + address32 + first_bit3 + byte_length7 + record_bits10 + status2 + reason6 = 472 |
| AR348保持 | clientH160 + role4 + ref64 + version64 + access2 + item_index32 + item_count22 = 348 |

新namespace/schema明确不能把旧KEY195/AP466或旧DDR-SERVICE的J486/scope623/permit266裸cast进来。同宽raw S、typed H、NUM ID、目录ref/grant也不互相授权。D105已明示全部caller/RAW/O仍未联合吸收，未把四body算术当全schema冻结。

### 3.2 地址与边界反例检查

物理半开区间为[0,268435456)；地址32加length先33bit，再核物理end与实际授权对象。32bit地址不会扩大2Gb器件容量。最后byte地址0x0FFFFFFF/len1可在物理范围内，len2必须拒绝；0xFFFFFFFF+1不能窄为0再误判合法。物理容量与当前128MiB分配策略是两层不同检查，普通caller还需ref/role/version/stage/initialized权限，不能凭落在物理区间直接访问guard/padding或其他对象。

RAW D3的item_index×record_bits42bit、首/末byte43bit前置范围检查仍需保留，最后收32bit不能代替此前全宽乘法。first_bit非0时，record_bits≤512本身不能保证span≤64B：例如first_bit1+512bit跨65B，仍必须拒绝或以另外已审分页合同拆分。MASTER没有声称全部512bit描述子自动合法，故未形成冲突。

具体迁移仍OPEN：旧OPEN256的capacity27不能编码256MiB=2^28；旧descriptor640的base26、journal576的address26不能覆盖POINT/AUX的新地址，必须明确扩位。descriptor byte_capacity27对当前最大单对象16MiB仍足够，可在新schema明示保留；不能与整arena容量混为一谈。原PC OPEN/期限/packet在新backend的适用与否，以及全部授权范围字段，须显式选择并重新绑定；生产DDR并不因此必须使用串口packet。这里只是四个新body候选，完整变更必须在联合版本明确，不能无声由适配器截位；新base0不继承旧PC raw guard=64KiB。此项是MASTER已有“尚未吸收/须新backend合同”的具体交接清单，不是新增反例或据此否决纯候选。

## 4. 128bit拍、邻byte权限与真实效果

### 4.1 5拍上界成立

128bit拍为16B。首地址offset=o∈[0,15]、长度L∈[1,64]时，覆盖拍数为ceil((o+L)/16)，最大ceil(79/16)=5。地址offset15/L64实际跨5拍；若对齐L64则恰4拍。最大5拍不是所有请求固定5拍，也不是未证明的5个请求credit。

对rounded span，先足宽计算首拍floor(addr/16)×16及末拍ceil(end/16)×16，再检查该完整范围的物理和同对象权限，不只检查原addr…end。新后台还须给真实burst/4KiB边界、AW/W/B与AR/R/ID/LAST/error台账，本文不预先补设计。

### 4.2 whole-WSTRB的具体竞争例

若对象只允许byte1写，却先读拍[0,16)、稍后全WSTRB回写，同时另writer更新byte0，则旧byte0将覆盖新byte0。仅保护requested byte1不能防止该错误。

MASTER D107实际要求rounded span处于同对象已初始化physical/padding授权、端拍保留邻byte、writer排他及整个读改写期间的group锁。该条件排除了上述竞争；本轮没有发现文中允许它发生的反例。后续完整backend必须将锁范围具体落实到所有物理拍，并将最新journal/缓存值纳入端拍postimage，而不是只锁逻辑record。尾padding授权须显式，RAW旧“无普通pad权限”不因对齐自动放开；D107的物理授权候选尚待O的新schema吸收。

选择窄WSTRB须先证明实际控制器接受性和精确lane遮罩；不能用公开WSTRB16端口存在就假定全部语义已验证。原资料只读，此复审不改WSTRB或生成新约束。

### 4.3 UNKNOWN及关闭与RAW7704相容

MASTER D107说明：AXI错误不能确定实际byte写入情况时，返回UNKNOWN/written0并保留effect debt；真实关闭仅证明无未来效果，不改成成功或猜测前缀。

这与RAW D3/D4/E4一致：UNKNOWN响应可以结响应关联，但effect_debt及postimage/latest/ref保留；已LOGICAL_COMMIT的16票或CLASS+QUEUE事实不回滚。INVALID_SETTLE区分已published项与never-published后缀，正确关闭后只登记settled，不增加success、不改UNKNOWN/written0/cause/首次证据；后缀作为INVALID失败处分，失去结果发布资格。typed失败回复消费不释放journal；本地权限/held/RAM pending真空及独立冻结台账成立后才退journal，不等待O退休或typed CLOSE_ACK消费。

MASTER B67的“raw关闭证明未知效果”应按D107上述明确含义阅读，不能解释为恢复未知写的最终bytes。E125允许未知raw债独立CLOSE先行，与RAW E7健康reset/故障reset两路相容。正确echo、真实ledger/closed证书、旧data及control槽空仍来自RAW，而不是物理reset或ALREADY receipt自动清债。完整DDR source ledger/close证明如何取得仍OPEN。

## 5. E节fullHIST数学与生命周期

原R4R E2每个seed遍历16个8192bin tile，总131072bin；r域1…131071，bin0恒0。每tile相同POINT/中心/profile重算相同RNE距离与normal门，仅符合本tile的合法r投一票。

fullHIST候选为131072×32bit=524288B=512KiB，逻辑count21、高bits31:21为0；独立非alias追加段[0x05440000,0x054C0000)。84.25MiB+0.5MiB=84.75MiB。目录/guard/元数据仍另计，不把512KiB写成片上免费RAM。

等价理由：不可变POINT、冻结center/profile与相同RNE计算使每点合法半径唯一；旧16次扫描恰一次满足所属tile，新一次扫描投同一bin，故全部bin计数相同。r0、域外拒绝、半径升序、±8平滑窗口、radius1峰/plateau最小r和跨域补0规则相同，RAW/SMOOTH峰及后续最近峰分配不会因分tile策略改变。

17bin平滑总和仍≤E：每点在fullHIST最多贡献一个bin，任意窗口的票是全部票的子集，因此uint21在E≤2073600下足够；不能按17E错误扩大统计或回绕。

前置不能省略：全131072bin CLEAR真实settled/initialized，计数forward/latest、无重复投票、投票阶段完全封存后才读取平滑/峰，峰表完整写/seal后才消费。原tileHIST保守账未偷偷减除。取消/失败前缀/NUM与phase台账可能因16遍改一遍发生结构变化，数学最终输出等价不自动证明时间合同相同；MASTER明确要求独立版本审查，故保持候选，不冒称R4R已改或测试已跑。

## 6. E节DENSE唯一high-bit证明

设某θ全部277bin的非负计数为c_r。每POINT在该θ至多投一票，故Σc_r≤E≤2073600<2097152=2^21。

若有两个bin各c≥2^20，则Σc≥2^21，矛盾；任一单bin也不可能达到2^21发生第二次low20回绕。因此同θ最多一个bin的bit20为1。每lane保存277个low20及valid1/bin9 marker，以地址相等且valid为真重建bit20，其余高位0，可完全恢复原uint21。

边界走查：

| 场景 | 正确重建 |
|---|---|
| 全0/未到2^20 | marker invalid，所有high0。 |
| 一个bin从2^20−1增1 | low变0，marker valid/地址绑定该bin，读出2^20。 |
| 同bin随后继续计票至E | marker仍同bin，low保存余数；E上界阻第二次回绕。 |
| 另一bin企图跨2^20 | 与总票上界矛盾；文中要求INVARIANT失败，不能覆盖旧marker。 |
| cancel/失败后重读 | low与marker必须按真实已交付事实及latest保持，不通过单端reset造0。 |

EFX_RAM10原几何支持512×20：每lane一个RAM10保存low20，marker10FF；16lane为16RAM10+160FF。bin9可以表示0…276，但277…511仍非法padding，访问前查域。此计数只包括low存储和marker，未包含read latency、旧/新值、journal、响应、总票/游标、NMS四行快照或控制，不能当全机RAM/FF总值。

协议前提仍待完整局部冻结：CLEAR277有效low及marker全部真实完成；切换batch前全部θ邻居/NMS reader和跨batch快照真结清；同bin读后写/连续组同时forward low和marker；16lane组同一提交屏障/旁观reader禁止读取半组；旧fire先结后cancel、未知债不假close。MASTER E131及PERF OPT-D1明确这些前提，没有把16bank宣称16票/沿或在旧单RQ/RSP合同上无声流水多组。因此未发现当前数学证明反例，也不声称实际推断/PNR或吞吐成立。

## 7. 后续独立验证追踪（计划，NOT_RUN）

| 检查点 | 来源/未来TEST | 可关闭的直接观察 |
|---|---|---|
| DR schema全族与capacity迁移 | MASTER IF06/D105、INT-T05/T06/T08 | 全caller/目录/OPEN/journal/packet明示位宽及身份，无高位截断；不是只四body算术。 |
| addr/rounded permissions | D107、T05/T06 | offset0/15、L1/64、物理末byte、不同对象边界、padding/未初始化拒绝；原请求和完整物理拍权限都成立。 |
| RMW排他与WSTRB | D107、T05 | 同拍两client竞争、旧读后更新邻byte、同址forward，真实锁/遮罩效果不覆盖邻值。 |
| UNKNOWN和postcommit取消 | RAW E4/E7、MASTER OP07/T06 | 效果事实和logical_commit保留；关闭不把未知改FULL；先raw proof再typed quiet可完成，无环。 |
| HIST等值 | OP09、T04/T09及新增局部差分计划 | 131072逐bin、tile边界/±8/plateau/域首末/RNE平局、全RAW/SMOOTH峰和失败/取消诊断独立比对。 |
| DENSE压缩 | OP09、T05及新增局部差分计划 | 2^20−1→2^20、最高E、单/连续samebin、第二高位异常、低位/marker的组可见及清batch/NMS生命周期。 |
| 实际资源/服务 | INT-T08/T10 | native端口/clock/全部控制计数、DDR刷新/仲裁/capture与HDMI期限、同基线PNR/STA覆盖，不用候选算术替实测。 |

以上只设计未来观察，不是生成或运行测试。未跑工具不是批准前必须先写业务的循环；成熟完整局部/组合可审查后才提交指定READY版本，获明确批准后执行。

## 8. 最终绑定及交接

按根Agent最新指令，本报告先绑定实际MASTER BE685C171962C59EA0B6F3768BA1B5B691FA8D07D1EA45DD015C124964029DF1 / 32057B保存并结束，未等待或冒称后续主稿冻结；不是对未来元数据/新增工具结果的审核。复审后再次只读确认当前MASTER仍为同hash，未修改它。

根Agent本轮转交了用户最新明确批准：TRACK4-IP-PRECHECK-001 v1、IP-PRECHECK-BL-v1（89输入）、C0–C3有限范围及本地审计例外；根Agent将开始独立副本预检。该批准不含算法实现，也不等于预检已经运行成功。本代理没有执行该实验、修改基线/副本或代写批准状态；后续真实日志/新主稿证据由相应任务另核。

本限定review不关闭MASTER INT-B01…06，RAW全部B01…06、R4R资源/性能、生产IO、profile/fixtures/GT、共同文件/状态与实施批准；不将完整范围降为160×120/单目标/1fps，不用PC计算代FPGA，也不把core-only PNR或历史bit计为五基础全部完成。最新允许板载DDR的用户边界已明确；成熟同范围批准持续有效，当前尚未READY/批准具体整包版本。

本轮仅新增本审阅报告；全文读回并回报真实hash后停止编辑，不修改业务/原工程/原资料/其他文档或正式状态。

