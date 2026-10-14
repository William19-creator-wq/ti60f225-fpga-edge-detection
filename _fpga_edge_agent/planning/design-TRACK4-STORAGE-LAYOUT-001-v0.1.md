# TRACK4-STORAGE-LAYOUT-001 v0.1：识别工作池与显示行缓存的物理布局

2026-10-04；按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)，关联[完整软件主计划](design-TRACK4-FULL-SW-001.md)与[整机预算诊断](design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)。**LOCAL_DESIGN / NOT_READY / NOT_APPROVED**。本稿把两项存储优化落实到地址、端口、逐沿和关闭条件；不将设计算术写成仿真、综合或STA。五基础六高阶整体范围保持，业务源码、功能脚本、参考程序、testbench未生成。

## 通用计划字段

- Goal：在不改变图像、身份、容量、识别数学/候选集合与关闭保证的前提下，减少RC私有工作池和DISPLAY三行缓存的物理RAM占用，为整机状态/外部IP留下空间。
- Current state：现有预算225自写RAM10不含完整外部IP。RC105、DISPLAY21是父稿候选；完整热冷及服务界未闭合。
- Target state：本稿固定native20×512布局及互斥生存期，指定联合版本吸收后获批实现；实际map/PNR/STA证明完整配置。
- Gap：SL-B01联合父合同吸收/全部metadata布局；SL-B02真实DDR/CSI/编码器资源及2Gb模型；SL-B03包含新访存的期限/质量与正式运行前置。当前不申请新实现批准。
- Assumptions：Ti60F225 V4/I3、SC431HAI、生产1920×1080；CORE100/PAIR74.25是既有候选。1080p60属于扫描，不是相机/识别fps。
- Open questions：范围内具体布局由本稿确定；没有把源/结果槽、候选cap或用户撤回的尺寸/噪声/遮挡边界改小。外部IP与服务未知保留。
- Dependencies：预算v0.1、RC/NUMERIC/ALGORITHMS/EXECUTION及DISPLAY/附件现字节、DATA-JOIN/DS/PL合同，唯一v0.2。
- Milestones：全路径与不变语义→物理布局→读写/取消中文草图→局部/组合审查→联合版本→指定批准→真实工具验证。
- Detailed steps：B/C整体→D1…D4布局/组合→E中文操作→F语言/时间→G/H场景与追踪→I/J差异与闸门。
- State transitions：只更新设计/索引/文档审计；正式H0、ledger、Manifest、数据库状态不变。
- Artifacts and hashes：A所列输入及05实际审阅记录；当前检查记录最终SHA，旧预算审计留原字节历史。
- Validation：只读原文/字段/地址/容量算术和文档/哈希核对；所有业务/品质/PHY/综合/PNR/STA为NOT_RUN。
- Failure handling：非法地址/计数/格式帧失败；不得用省资源理由删未知、截断、漏计或释放未闭合旧借用。
- Human approval gates：本稿不是整体READY或实现批准。既有FRONTEND/模型申请仍待答复，不重复索取；后续指定联合版本按v0.2批准。
- Rollback：父稿和原资料保持原字节；只需退出本布局候选并保留差异证据，不覆盖历史。
- Completion criteria：布局设计/审阅可交付；整机软件只在真实代码、验证、布线时序与bit/hex全具备后完成。

## A. 范围、来源与证据边界

本稿选择RC工作池压紧和DISPLAY 17RAM布局作联合版本的内部结构候选；DS/PL串行控制及同步DDR另列待联合方案，不混算为已经采用的全机实现。原始资料/历史工具产物均只读。

| 输入 | 实际SHA256及用途 |
|---|---|
| RESOURCE-SERVICE-BUDGET v0.1 | AF2C2ADFB66AEAA6A1E872AC067C28FFC8A673D836A88B750C4E7FA17BE44D11；225与热状态缺口 |
| RECOGNITION | D9727727F28D0025E14144B70DE365C92FB505092CCD2B0408F5EA7C34FD3EE5；phase/表生命周期 |
| NUMERIC | 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A；数值/记录/ROM |
| ALGORITHMS | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB；DENSE/CELL/LINE/SEG/VC/coverage完整字段 |
| EXECUTION | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178；唯一RC_BIND/关闭 |
| DISPLAY | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717；ROW336/343/349与固定slot链 |
| DISPLAY中文附件 | 7071D79E7EB3550580C027ACD830BDDB5825CD1A16813C246446926548C08EA3；旧21RAM/1248单口展开机会 |
| EFX_RAM10原语 | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33；1R1W、native512×20、同址双clock禁用 |
| v0.2/PLAN_TEMPLATE | 当前源哈希与读回见05；只准文档/中文草图，未获准代码 |

既有ALGORITHMS/EXECUTION文字来源须按05的实际哈希恢复，不仅凭名称。新增V4旧map/hierarchy与IP分叉的来源、准确scope在05审阅记录；root只声称实际选读报告头/相关层级及完整读回本稿，不声称逐页读完所有PDF或解密protected主体。

## B. 整体行为与不变要求

系统路径仍为相机原RGB→完整源/冻结保留→五基础或完整Canny→RC圆/旋转矩形及标注→写入完整结果/ANN→DDR读整行→固定PAIR/pixel/serializer扫描。慢处理继续显示最新完整结果；参数改变重处理同一冻结原RGB。内存压紧不能改变最终每一字节、成员/支撑集合、任意旋转或独立每类P/R≥95%的评分。

| REQ | 可核查要求 |
|---|---|
| SL-REQ01 | 所有逻辑表容量/字段值保留；只删除固定0或能从保留字段精确重建的冗余表示，overflow仍完整任务失败。 |
| SL-REQ02 | 每个RAM地址、bit、port及同时生存期明确；共享只能在旧pending/holding/物理borrow闭合后。 |
| SL-REQ03 | 三row仍容纳active current/next与candidate；原RGB/EDGE/ANN色序与有效坐标逐值不变，无RMW跨clock同址。 |
| SL-REQ04 | 连续每PAIR一次输出能力、n−6 RE/n−5 capture与原render/adapter slot链明确，停顿/取消不忘旧capture。 |
| SL-REQ05 | 资源省额、访存代价、外部IP事实和未知分别记录；不以旧报告、RAM算术或平均带宽证明整机可布局。 |
| SL-REQ06 | 指定版本/范围/基线与联合修订清楚，未批准不生成可执行内容，所有未来场景保持NOT_RUN。 |

正常例：同一合法row的pair2，SRC窗口跨4个nativeword仍在4个不同物理RAM读口；EDGE/ANN各取一个word且分属不同RAM，下一沿得到原54bit像素值。边界例：切换当前VC record/class先关闭旧record的RE/capture、coverage及NUM/FORMAT临时义务；圆/矩形两表持续保留，全部SELECT/best借用关闭后才转DRAW。字段重建不能把保留位非0的非法输入当合法。失败例：取消与RE同沿，旧owner仍capture后DISCARD，不用新scope的地址/phase解释旧RDATA；未关闭不复用工作池或row。

## C. 职责与连接

| MOD | 职责、状态与界限 |
|---|---|
| SL-RC-STORE | RC控制器拥有P1/P2/P3私有工作池；数值/候选字段按D1/D2压紧，不修改外部DDR POINT/CIRC/RECT/FINAL字节。 |
| SL-ROW-FILL | CORE client1原R128双holding→有界展开/条带WE→完整ROW；负责数据/word计数和carry，父负责scope/grant。 |
| SL-ROW-READ | PAIR按当前不可变ROW/slot发SRC与EA RE，pending固定原bank/phase/offset，preedge重建54bit。 |
| SL-OWNER | RC原phase关闭与DP原READY/OWNED/RELEASE/ACK所有权，决定何时允许改表/写bank；压紧地址不改变租约。 |
| 相邻DS/PL/FM/renderer | 按原完整身份/请求/终态/配置/关闭合同工作；尚未联合的serial控制/新clock不由本布局偷换。 |

RC→SL-IF01 native20读写/关闭；DDR→SL-IF02 R128/展开；CORE→SL-IF03 ROW336/OWNED342/RELEASE343/ACK349；PAIR→SL-IF04 RGB48/EDGE2/ANN4与slot→原固定render→pixel/serializer。数据与授权分开：一个RAM字正确不证明scope/grant或scan授权。基础FE/算法功能均保留，RC可暂停内部计算，HDMI扫描不可暂停。

整体检查点：上一轮预算已呈现；本轮B/C选择压紧RC和无RMW条带row，外部IP/全热状态/真实服务界仍为阻塞。后续只能补联合设计，不把本局部省额当整机READY。

## D. 地址、接口与组合检查

### D1. RC：74块模式池，固定外围17块，合91RAM

固定FINAL4、row2、STREAM4、scatter4、目录1、ROM2共17块不动；原模式池B0…87改为B0…73。B74…87是**永久释放的14块**，任何识别phase均不再借它们；将来给metadata须另定owner/地址，不偷偷塞字段。P3两类VC同时存在，不能只取其中较大40块。

| phase/子模式 | B0…73的固定用途 | 同时RAM |
|---|---|---:|
| P1 | B0…16 hist，B17…24 anchor/两峰，B25…64 FINE/seed/ledger/LS/context | 65 |
| P2 DENSE/NMS | B0…15 DENSE，B16…19 NMS，B32…35 LINE，B36…73 SEG | 62 |
| P2 两CELL | B0…31 两CELL，B32…35 LINE，B36…73 SEG | 74 |
| P2 EXT | B0…23 EXT，B32…35 LINE，B36…73 SEG | 66 |
| P2 PAIR | B0…1 PAIR，B32…35 LINE，B36…73 SEG | 44 |
| P3 VERIFY/SELECT | B0…29圆VC，B30…69矩形VC，B70…73 coverage | 74 |
| P3 DRAW/ANN | 旧VC/best/借用关闭后B0作DRAW，其余旧模式已关闭 | 不增加 |

全部字段低到高；native word0对应逻辑低bit，补位规范0，不能把原逻辑body内非法位当可删除。

**DENSE21：32→16RAM。** 每theta一RAM；addr0…276放票数低20，addr277+floor(rho/20)的bit(rho mod20)放高1。rho0…276、高区14word，addr290仅低17有效/高3零，291…511不用。每theta291word，16theta仍并行，与现有NMS snapshot表示一致；高位不因通常票数较小而删去。
单票逐沿：e0读低word；e1 preedge capture低并读高word；e2 capture高，扩22bit+1检查≤E；e3写低；e4写整个原高word（仅改该bit）；e5下一次RE最早。point/rho/旧完整高word在过程中固定，不依同址碰撞。旧4沿机会预算不继承。

**CELL：去8 companion。** 两组4096 cell各16RAM；g0/1、s=cell>>9，native两条带B(16g+2s)及下一块，addr=cell&511。紧凑40bit低0…20=count21、21…36=完整submask16、37=valid、38…39零。逻辑CELL32的submin/submax由mask最低/最高置位索引恢复，zero2恢复0；valid/count/mask一致性先核，不由count猜端点，合法插点必须置对应Q4量化subbit。
EXT count21/old_member_count21/submask16/valid1共59bit，三20bit条带/512cell、共24RAM，末高1零；submin/max同样精确恢复。不是减少两个4096-cell组的容量或投影细度。

**LINE：8→4RAM。** 原theta9/rho9/count21/zero25仅39动态bit，每条2word、末word高1零。a=2id+w，id0…1023/w0…1，bank=B32+(a>>9)、addr=a&511。对外恢复原LINE64，原zero25必须为0，不将非法逻辑输入默默规范成合法。

**SEG：40→38RAM。** 原SEG384仅coarse logical124…127及fine logical383固定零，共5bit。紧凑0…123=logical0…123；124…378=logical128…382；379为物理padding零。每条19word，a=19id+w，bank=B36+(a>>9)、addr=a&511；1024条19456word正好38块。fine state原logical379/380→compact375/376（word18 bit15/16）。
完整record锁住，全部19WE完成后下一沿才COMMIT_DONE；不只改两个state位。LOOKUP恢复原384bit含全部5固定零，原粗/细成员与端点谓词不变。

**VC：圆30＋矩形40，同时保留2048条。** 原gid0…1023圆、1024…2047矩形，类别/proposal由gid决定。圆seed是ALGORITHMS algorithm2的seed_id0…255（不是NUMERIC旧cell13），矩形parent_pair0…511；原13bit域恢复其规定高零。保持原geometry/指标/成员/selection tie，不以变更诊断删候选。

| 字段 | 圆compact bit | 矩形compact bit |
|---|---|---|
| geometry | 0…52 | 0…143 |
| flags低3 | 53…55 | 144…146 |
| score16 | 56…71 | 147…162 |
| support21 | 72…92 | 163…183 |
| eligible21 | 93…113 | 184…204 |
| SSE53 | 114…166 | 205…257 |
| coverage64 | 167…230 | 258…321 |
| max_residual16 | 231…246 | 322…337 |
| fit_support21 | 247…267 | 338…358 |
| seed诊断 | 268…275（8bit） | 359…367（9bit） |
| fit_quality16 | 276…291 | 368…383 |
| state2 | 292…293 | 384…385 |

圆294bit/15word，id0…1023，a=15id+w，bank=B0+(a>>9)、addr=a&511，15360word=30RAM；末word高6零，state在word14 bit12/13。矩形386bit/20word，id0…1023，a=20id+w，bank=B30+(a>>9)、addr=a&511，20480word=40RAM；末高14零，state在word19 bit4/5。恢复geometry圆高91、flags原高1、seed高5/4与zero9均为0。全部word安装/改状态/CONSUME均最后WE后下一沿发布，不用旧20word VC的地址。

**SL-IF01与组合。** 原LOOKUP/COMMIT、NUM/FORMAT及外部POINT/CIRC/RECT/FINAL逻辑字节保持；只有内部地址/压紧读写及机会数改变。MODE资格只在旧RE已capture、WE/pending/响应/COMMIT_DONE/NUM_RESP/FORMAT已消费或合法DISCARD、本地/MC borrow关闭后变更；沿前必须成立，不以本沿新关闭旁路改池。下一沿先CLEAR，CLEAR真实完成后下一沿才开放。不在R/B热数据、暖reset保持或Q未恢复时清空模式池。scalar/FORMAT仍互不共享，不据不同phase名称删除同时寿命。

### D2. 确认的去重与待联合结构

RC29168原容器预算中，NUMERIC6191包含PROFILE1024，而EXECUTION RC_BIND4731已保存同一不可变PROFILE1024，D1要求全程唯一主体。唯一容器应为28144；这是设计预算纠重，非实测FF减少。对外receipt/status仍是并行held body，不能放RAM后假称所有FF都省去。

FIT/scalar进一步候选**本稿未选择**：scalar MUL的385 workspace可在DIV_RUN明确分为Q192低位＋remainder193高位，A/B192与符号/key另保留；末位RNE与检查后才废弃R形成VALUE385，RESULT_HELD到真实消费后的下一沿才改用途。NUM_REQ A192全域的floor root最多96bit；SQRT_RNE对A=2^192−1可舍入为2^96，候选需97bit或独立carry，目标typed宽度不足按原overflow处理，不能截进位，也不能把部分调用点86bit当全API上界。该候选payload可减193，但新控制/MUX及时序须另列。
四侧TLS868可以用B70…73 coverage空区各272…282存217bit，圆在B70 272…285存263bit，再一263 cache顺序运算；payload差605，完整RMW/统计锁/pending代价未冻结，不直接计为本稿FF省额。FORMAT512与scalar385存在同时寿命，本稿不共享，也不把A/B覆盖为仍需多次运算的统计。

DS/PL方向给出**待联合候选**：原DS数据14RAM不动；scope16、grant32、phase32、14record的326bit身份冷存＋原113bit非身份热状态保留、各14坏prepare/坏release完整入10metadata RAM，DS24；PL NORM20+镜像1+aux1=22。scope mutable688、grant241+93、phase冷518+live381全部保留，原不同字段集不取最低值。正常ACK引用pinned canonical record，错误body仍独立保存。
这要求原wide prepare/permit/terminal/release/DATA_CONTROL/PL control改为20bit完整封包提交；req266/W152/R155数据路径仍wide。半包不产生授权或归还效果，RE先预留word holding、stall不占bank全局锁，真实ACK消费有每record journal到scope/phase提交后才回收。不能保留wide接口同时省掉wide assembler；消息长度/类型/路由字典仍需固定，DS小消息6bit word_index不能直接套到DP OFFER1963/receipt1969（均99word）或RC_BIND4731（237word）。不同独立关闭路由有独立槽，PREPARE/FINAL、snapshot/mirror及坏body回显不共享一个全局assembler。完整候选地址和热FF范围见05审阅记录，不算已选定全机布局。

### D3. DISPLAY 17RAM：SRC条带和EA交错

全部native512×20，WE写整20bit，RCLK=PAIR候选74.25MHz、WCLK=CORE候选100MHz，OUTPUT_REG=0。原语是**一个读口和一个写口**；不同域同址读写由ROW owner禁止，不能靠READ_FIRST。三逻辑bank b=0…2仍独立，同一bank仅在FILL阶段写、合法释放后下一沿重用。

**SRC：15RAM。** 每row字节流为DDR低地址顺序R0/G0/B0/R1/G1/B1，byte内低bit先入native位流。每row46080bit=2304个20bitword。word w的物理RAM是5b+(w mod5)，addr=floor(w/5)，最大460，未用461…511不作为额外row或metadata。每row5块、三row15块，payload138240/physical153600bit=90%。

PAIR p0…959的bit起点48p，q=floor(48p/20)，s=(48p)mod20；读q起的ceil((s+48)/20)个连续word，数量3或4。最多4个不同lane，一RAM仅一次RE。word按原q顺序拼，取从s开始48bit；不直接把此little-endian值当canonical：
raw低8=R0、其后G0/B0/R1/G1/B1；重排为输出高至低R1/G1/B1/R0/G0/B0。q/s更新可用5态周期，s依0/8/16/4/12循环，q增2/3，不把通用除法塞进74.25MHz路径。

| p | q / s | 各读(lane,addr) |
|---|---|---|
| 0 | 0 / 0 | (0,0)(1,0)(2,0) |
| 1 | 2 / 8 | (2,0)(3,0)(4,0) |
| 2 | 4 / 16 | (4,0)(0,1)(1,1)(2,1) |
| 3 | 7 / 4 | (2,1)(3,1)(4,1) |
| 4 | 9 / 12 | (4,1)(0,2)(1,2) |

**EDGE+ANN：2RAM。** 保留独立bit流，不做读改写。EDGE96word/row，每word20像素；ANN192word/row，每word10像素。以20pair（40pixel）为组g0…47，共用144word/row/物理RAM。两个RAM中的同addr属于不同存储，允许各自独立RE/WE。

| 地址a=144b+3g | EA_RAM0 | EA_RAM1 |
|---|---|---|
| a+0 | EDGE word2g | ANN word4g |
| a+1 | ANN word4g+2 | ANN word4g+1 |
| a+2 | ANN word4g+3 | EDGE word2g+1 |

三row每RAM432word，maxaddr431，合864word=17280payloadbit，占20480physicalbit的84.375%。不写/读432…511，也不把余字擅自借给CORE metadata（读口仍属PAIR）。

给定p，e=floor(p/10)、u=e mod2、g=floor(e/2)、t=floor((p mod10)/5)：
EDGE来自RAM u、地址144b+3g+(u为0则0、否则2)，取offset=2(p mod10)的2bit；
ANN来自RAM 1−u、地址144b+3g+(u为0则t、否则1+t)，取offset=4(p mod5)的4bit。
两个read总在不同RAM，bit均不跨20bit边界。生产p9→10/p19→20切组只改pending地址/offset，不交换旧RDATA的归属。

写EDGE word e：偶e→RAM0/144b+3floor(e/2)，奇e→RAM1同基址+2。写ANN word a：a mod4为0/1→RAM1/144b+3floor(a/4)+(a mod4)；2/3→RAM0同基址+(a mod4−1)。SRC/EDGE/ANN页不互相覆盖；先写哪一plane不需要另一plane旧数据或RMW。只有required plane填满并闭合全部WE/holding/pending才READY，disabled plane不读旧值。

**SL-IF02/03仍为原合同。** 两个R128槽保留各data/tag/index/last/error与row/plane owner；valid+reserved≤2。ROW336/OWNED342/RELEASE343/ACK349、full scope/offer/scan/mode/坐标、filled/required及三个row容量不改。压紧改变物理地址、展开和局部读缓存，不能把旧18/1/2布局混用本17RAM公式。

**SL-IF04新内部读结构。** 所有required plane在n−6同一PAIR沿发RE到同一预留54bit槽，原bank/gen/scan/slot/offset/issued-mask在pending冻结；n−5用该沿前原RAM RDATA组装RGB48/EDGE2/ANN4。n−4权重/旁带、n−3部分和、n−2Y、n−1render、n adapter消费旧值，沿原fixed slot链。各E/ANN改为按pair读取，而非沿原block current/next缓存；新布局不再把旧四个20bit cache无条件加算。two54 holding仍valid+reserved≤2。
灰度直通、EDGE和overlay均走相同链，不能因为少读plane改变HS/VS/DE或lane先后。未required的SRC/EDGE/ANN在54槽显式置0且不RE，不能把缺少required当disabled。

每PAIR最多SRC4＋EA2个RE，各落独立物理RAM，无第三读口；下一slot可以同时预留另一个54槽，旧pending在n−5先归其原槽。RGB重排/多word选择/shift是新的组合路径，要经获批后的STA决定是否需要修订流水；当前不宣称100/74.25MHz已收敛。若需要额外pipeline，须更新整个slot契约并重新联合评审，不偷偷延一拍。

### D4. 资源与端到端能力边界

RC105→91和DISPLAY21→17合计释放18 RAM10：原225→207，**仅改变这两项布局时的自写候选**；外部IP及新增metadata另计。即使继续采用DS24/PL22串行候选，DS净增7、PL净增1，合215，不把未布局的FM/CONTROL/CAMERA状态写0，不将215称全机utilization。

旧1248是SRC960+EDGE96+ANN192的单口WE机会下限，不含全部R接纳/段/fence/CDC。新SRC每R128最多形成7个nativeword，条带5路最多2个WE组沿；EDGE/ANN最多7word，交错2路每RAM最多4字，最多4个WE组沿。生产满mask360/15/30拍，按每拍上界最多720+60+120=900个group-WE机会；这只是展开的静态机会预算，不是900cycle行期限证明。首装载、段边界、carry、末字、MC握手/terminal/release、ROW CDC及DDR竞争另计。可以在末WE组沿追加**旧已held**下一拍减少额外空沿，仍须按E1核旧态，不能用同沿新Rfire数据。

全mask仍6480B/row、405 R拍、≤11段、平均419.904MB/s，真实Trow与14.8148µs期限需联合有限DDR服务/非抢断candidate段、ROW归还和SCAN通知期限。压紧RC增加同步RAM访存，不能用新的900机会声称识别加速或整机帧率提升。

V4 v1历史DDR父子资源为39RAM/2790FF，其中PHY22与桥17已包含；CSI36/1191FF、DVI2/617FF来自旧具体配置。v6 CSI正式XML源5.15/FIFO1024/byte70与旁settings5.16/FIFO2048/50不同，byte参数不自动等于normalizer输出时钟。当前配置内部资源未知。DDR_PLL#4同网CORE/AXI/core100＋ASYN0可作新的clock选择，但17桥省额/同步22不属现成上界；DDR5.16本地IP与legacy1.1架构也不同。全部详见05来源审阅；未生成IP或重编。

## E. 中文操作草图、旧态与关闭

### E1. SL-OP01：接R、形成nativeword组、提交WE

1. 原DS R fire只捕获到两个独立128槽之一，原tag/index/last/error/row/plane同时保存；ready仅看沿前容量。当前stage未空且未到末WE组时不装下一拍，R可反压，非暂停扫描由整行bank隔离。
2. 开始stage时取**旧已held**R128与当前plane的旧tail，合至最多147有效bit，用160bit容器/高未用零。保存完整word数量0…7、批次first_word、未完成word游标与不足20bit的tail副本（≤19bit）；tail在此时就固定，不等末沿重新猜。
3. 对SRC取最多5个连续word，每个lane本沿最多一次WE；对EDGE/ANN按交错位置选择每物理RAM至多一个待写word。没有同bank双WE，WDATA只来自旧stage。WE提交后推进已写数，不能因Rvalid持续重复写。
4. 末组WE沿，若旧next Rholding有效且合法、当前段/plane允许继续，下一stage的first为旧batch_first＋旧完整word总数，data由旧tail＋旧nextR形成；不使用同沿新Rfire/新capture/沿后游标。没有旧next则空沿等待，不承诺无气泡。
5. 段切换前，余尾及流位置复制到该row/plane自己的descriptor，解除旧service record借用；旧terminal/release与ACK仍独立结清。candidate转active不改held旧stage owner，不让共享展开槽等待下一段而持旧段。
6. 最后完整row要求SRC2304、EDGE96、ANN192个实际word（按required），生产tail0、原405拍/计数/terminal/release全部核对，旧WE/holding/pending闭合及父授权合法才filled/READY。部分/错误/取消不能先READY再补写。

明确有限数据容器为stage160、tail19、两个R128、两个54预渲染槽，共543bit；不是489（489只算一个54）。共用stage因client1及当前展开plane串行，paused各row的plane tail仍独立descriptor，不据共用stage删它们。另给CORE stage状态28bit（plane2/first_word12/words_remaining3/tail_count5/commit_mask5/valid1）与PAIR pending112bit（SRC q12/shift5/first_lane3/word_count3/issued_mask7/Eoffset5/Aoffset5/E_lane1/bank2/gen64/target_slot1/SRC-EDGE-ANN资格各1/valid1）的保守容器。原ROW pinned owner/坐标/scan仍真实存在，不能仅以bank id代替完整身份。其余tag/error/计数、renderer386、adapter/encoder、暖reset保持及全控制另计；543或543+140不是完整DISPLAY FF或物理利用率。

### E2. SL-OP02：一个PAIR槽的同步RE与54bit重建

沿前确认原ROW已OWNED、bank/gen/scan/target/source/mode及required完整、目标54槽有预留资格；把p/地址/shift/plane-mask/slot和原owner放pending。n−6对SRC3/4 lane及EA实际required各端发RE。n−5 preedge取**旧pending指定**RDATA：word0放低20、依q排序/移位取raw48，再明确R/G/B重排；EA按旧offset取低lane0的2/4bit。
同沿当前scan计数已前进，也不能用沿后新p/descriptor/role解释旧数据。未required值明确0；任一required没有真实结果、身份错误或late，按旧sticky规则输出safe并保留PARTIAL/UNDERFLOW，不用零当成功无边缘。capture到完整54槽后解除RAM payload借用，scope/scan引用仍随原render/adapter流水关闭。下一slot RE可同时预留另一54槽，valid+reserved≤2。

### E3. SL-OP03：RC压紧记录的完整读改写

CLEAR只在旧模式资格闭合后启动，逐word清本模式真正会访问的范围/必要state；不清外部图像或稳定metadata。LOOKUP预留原key/row/record与目标槽，逐wordRE→下一沿capture，恢复逻辑原字段/固定零并核规范。
CELL插点同时更新count、完整submask、valid，保持端点重建一致；EXT同样保存old_member_count。DENSE高bit的同word其他19rho不能覆盖。SEG/VC COMMIT先锁完整record和输入，依compact字典逐wordWE，末WE后下一沿才DONE/state可见；地址跨512边界仍原record owner，不用下一record的bank。
RC点/候选内部允许停顿；不能反压非暂停摄像头像素，也不能阻R/B及独立physical关闭。DENSE6沿新增访问、compact逐word和状态还原的机会数纳入未来工作量，原frame-cost不是新布局实测。

### E4. SL-OP04：模式切换、取消、Q与归还

先停止未提出的新业务；已经valid的响应/NUM/FORMAT不撤回，已经RE预约照capture或按匹配旧ctx DISCARD，已承诺W兑现sealed来源。确认旧表响应、WE/pending、统计/标注临时holding、本地及physical borrow全部闭合；下一沿才进入新模式CLEAR，CLEAR关闭后再开放。不把超时、warm reset或epoch变化当排空。
ROW从READY曝光起数据不变，直到原RE/capture/54槽RAM借用关闭、匹配RELEASE与ACK运输/业务全部结清，下一沿FREE。pair端可读OWNED row同时core写不同FILL row，因为地址范围不同；同row冲突永远禁止。值复制到render FF不再借RAM，但其scope引用仍要真实消费。未知关闭Q继续占用，不因RAM省额或有空地址提前重授。

### E5. SL-OP05：整机预算与联合版本登记

先按D1/D3固定物理bank及最大同时模式计；RC91+DP17保留完整图表容量。去重PROFILE只保留原RC_BIND的1024主体和typed引用，不删非法reply原body。另登记DS24/PL22候选、新metadata、实际IP和clock选择，不把“有剩RAM”当其已安装。
联合版本必须明确覆盖旧地址、DENSE机会、CELL端点、VC诊断和display cache/slot；旧225与当前207是不同布局，不能交替使用表格。未知IP、全热状态、CSI分叉与DDR时钟架构仍单列；完整优化后的性能按独立质量/工具证据选择，不恢复制定过的尺寸/数量/噪声硬界。

## F. RTL与参考契约

本次无C++/Python业务参考实现；对象/异常/容器API N/A（只做RTL结构设计）。未来独立参考仍按完整逻辑表、原字节与原几何谓词，不照抄物理地址优化来互相自证。

| RTL项目 | 本稿具体合同 |
|---|---|
| A 数值 | native20、D1动态/补零位；word/地址/计数先扩检查；RGB byte顺序、EDGE低bit/ANN低2bit不变。 |
| B 时钟/观察 | CORE WE与PAIR RE候选正沿；RE后RDATA稳定，下沿preedge按原pending capture；测试观察更新后稳定，不把同沿新值用作旧结果。 |
| C 接受/交付 | R/NUM/FORMAT/ROW原fire；SL内部预约先有固定槽，WE按旧stage有效且原owner。RAM没有外部ready不等于可越owner访问。 |
| D valid | 无有效R不追加、不加word/point；RE预约不能因后来valid低消失；未required显式0与required失败分开。 |
| E 保持 | stage、tail、p/key、body和取消前已held响应稳定；paused row各carry属其descriptor。 |
| F 延迟/吞吐 | DENSE6沿；PAIR n−6/n−5和原render槽链；900是WE组机会，不是期限/FPS。 |
| G 复位 | 原保持域/安全关闭；不复位清RAM证明新模式就绪；Q不复用、暖reset不丢pending。 |
| H 配置 | 原C570/profile/ROW/render快照和同沿用旧配置不变；无动态W/H/地址模式切换。 |
| I 存储 | RC74私有池+17固定；DP15+2；1R1W、512×20、明确padding/越界/同址禁用；两R/54槽和分组WE容量。 |
| J 身份 | 原source/result/J/scope/grant/ROW/scan/slot；新物理地址不改变坐标、proposal、候选数或lane颜色。 |
| K CDC | 不新增业务clock域；整行稳定/ROW mailbox保留。不同bank WE/RE可并发，同row禁止；新DDR clock是另一个待评审选择。 |
| L 实现 | SV2009/Efinity2026.1/Questa2024.1现行候选；实际推断/布局/STA未运行，barrel/mux及新增冷访问须真实验证。 |

共同数值：完整logical CELL/LINE/SEG/VC和raw RGB↔canonical逐bit一致。硬件执行：D/E事件/预约/停顿/关闭不由软件循环替代。对应关系：未来oracle只比较相同原ctx/record/gid/row/slot/config的完整逻辑值，复位作废按既定分类；地址压紧后的无效/padding不能当额外业务记录。

## G. 实施与验证计划（全部NOT_RUN）

获批后的统一实现：先native读写封装与旧owner预约→RC compact pack/unpack/CLEAR/DENSE/COMMIT→DP CORE条带写与PAIR slot读→组合cancel/CDC→完整十一功能及匹配PHY→综合/PNR/STA/pins/bit/hex。若需要探索工具实验，同样先取得指定实验设计与批准；本稿不生成探索代码或运行IP生成。

| TEST | 要求/对象 | 场景、期望及观察 | 状态 |
|---|---|---|---|
| SL-T01 | REQ01/02 RC池 | 所有P1/P2/P3最大同时容器≤74；两类VC同时2048，稳定14块不被识别借用 | NOT_RUN |
| SL-T02 | REQ01 DENSE | rho0/19/20/276、高位0/1、同高word不同rho、E边界；6沿完整RMW保留其他bit | NOT_RUN |
| SL-T03 | REQ01 CELL/EXT | 0/15/submask多bit、valid/count不一致、cell511/512/4095；端点与原逻辑值一致/非法拒绝 | NOT_RUN |
| SL-T04 | REQ01 SEG/VC | 全动态bit与固定零、最后record、跨native页、state最后WE、circle/rectangle同时存在 | NOT_RUN |
| SL-T05 | REQ03 SRC | distinct R/G/B、p0…4/959、q跨条带、disabled/缺required；不换色或借错bank | NOT_RUN |
| SL-T06 | REQ03 EA | p4→5/9→10/19→20/959，b0/1/2，两个plane同时/单独；无同RAM双RE，无RMW | NOT_RUN |
| SL-T07 | REQ02/04 stage | R气泡/ready0、旧next在/不在、同沿新Rfire、7word、段尾/plane切换；WE不重不漏，旧tail/owner保持 | NOT_RUN |
| SL-T08 | REQ02/04 slot/reset | 同沿RE/cancel/ROW归还、暖reset/失钟/Q、current与next并发；旧capture合法关闭/无提前复用 | NOT_RUN |
| SL-T09 | REQ04 固定链 | n−6/n−5到n adapter、HS/VS/DE/coords/两lane、UNDERFLOW旧sticky；无迟到平移/半row暴露 | NOT_RUN |
| SL-T10 | REQ05 资源服务 | 原配置/新布局完整map、external IP分项、clock/pin/STA与真实最坏service；不能用207替代全机 | NOT_RUN |
| SL-T11 | REQ01/05 全任务 | 完整五基础六高阶位精确与圆/旋转矩形独立P/R；全部负类/失败样本，不恢复旧硬边界 | NOT_RUN |
| SL-T12 | REQ06 审批恢复 | 指定版本/基线/工作副本/数据库/工具许可/2Gb模型及历史hash；批准前无业务生成 | NOT_RUN |

静态地址集/算术只属于设计核对，不是上述可执行场景运行。未来随机/边界输入与生产1080p60分开；小图不代替生产STA/QoS，RAW/颜色每通道用不同值，MC/scan按真实clock事件观察。

## H. 双向追踪

| REQ/来源 | MOD | IF/步骤 | 计划符号（未生成） | TEST | 实际代码/证据 |
|---|---|---|---|---|---|
| SL-REQ01 原RC数学/容量 | RC-STORE | IF01/D1/E3 | recognition_compact_store | T01…04/T11 | 未生成/NOT_RUN |
| SL-REQ02 DATA/owner派生 | OWNER/RC/ROW | IF01…03/E1/E4 | storage_owner_close | T01/T07/T08 | 未生成/NOT_RUN |
| SL-REQ03 原显示色序/三bank | ROW-FILL/READ | IF02…04/D3 | display_striped_row_store | T05/T06 | 未生成/NOT_RUN |
| SL-REQ04 原不可反压scan | ROW-READ/renderer | IF04/E1/E2 | display_pair_prefetch | T07…09 | 未生成/NOT_RUN |
| SL-REQ05 整机预算 | 全机 | D4/E5/F | 统一工程/IP/报告清单 | T10/T11 | 未运行 |
| SL-REQ06 v0.2/原审批 | 控制面 | A/I/J | 指定批准后work副本 | T12 | 未批准 |

反向：任何未来紧凑字段/地址/访问优化必须回到原逻辑字节、owner、数值及上述要求；不能临时创造“资源更低”理由删body、缩候选或降低quality。父代码未生成，未把计划符号写成实际路径/接口存在事实。

## I. 门槛与当前阻塞

①整体行为/样例B；②职责/连接C和实际源A；③接口/地址/组合D；④操作/不变量E；⑤语言/跨语言F；⑥局部走查D/E及独立报告05；⑦实施/验证G和追踪H；⑨保存/读回/呈现的实际结果见05；⑩版本/范围/A。
**⑧整机无阻塞尚不成立，因此保持NOT_READY。**
SL-B01：联合父版本需吸收本RC/DP映射与DENSE时序、PROFILE唯一实体，完整热冷/路由/packed状态仍待闭合。
SL-B02：当前CSI实际来源/版本分叉、protected内部资源、V4同步DDR配置、2Gb器件模型及编码/clock分布尚未具备完整证据。
SL-B03：新RC访存代价、真实显示/采集/通知/关闭有限服务界及原指定批准/数据库运行前置仍待解决。
没有把尚未获准的测试/综合先运行作为设计READY的循环条件；这些是以后验证义务。也不把本稿局部合理映射当全机READY。

## J. 差异、恢复与不选择项

本候选覆盖RC的DENSE/CELL/EXT/LINE/SEG/VC物理布局及pool105→91，DISPLAY旧SRC18/EDGE1/ANN2→SRC15/EA2与旧packed cache/展开；原native地址、旧机会数不能继续并用。logical记录/外部DDR字节、成员/排序/质量、ROW消息与原ownership、fixed scan输出保持。
永久释放14RC加4DP才是本轮已定义布局省额18。进一步DS/PL串行、FIT/scalar、metadata分配及ASYN0尚非本稿已采用结构，不能无声修改父文档/constraints/工程。需要改变slot latency、消息物理运输或core clock时，统一新版本明确差异并按v0.2批准。
恢复先核当前05审计与历史预算审计、原父SHA及指定批准；未批准只继续设计。原HDK、正式状态/Manifest/DB不变。

## K. 本轮实录

三个只读方向实际核DS/PL canonical、RC池/字段及IP历史资源/clock；root实际读回相关父字段/原语/附件，并作地址cardinality及算术核对。本稿/审阅/五索引保存、实际读回、源hash与文档检查的最终结果登记05。
SRC6912个唯一word位置、EA864个唯一word位置，全部范围正确；这证明本地址分配的静态范围/冲突核查，不证明颜色值仿真、clock原语推断或STA。未写业务/测试/功能脚本，未运行仿真、IP生成、综合、PNR、STA或bit/hex，未联网/安装/DB写入或硬件操作。上一轮真实进展是预算稿与审计，本轮真实进展是确定的18RAM布局省额及历史IP误读纠正。

## L. 阅读与交付

先B/C全路径→D1 RC位/word→D3 RGB与EA条带→E读写、逐沿/取消→F数值/时间→G/H验证/追踪→I/J联合阻塞和差异；IP来源与串行候选细节在05。从逻辑record或最终slot可反向找到其物理bank、旧pending与关闭条件。
本轮交付存储布局设计和实际审閱，不是全部软件。功能/品质/工具/bit均待后续获批实现和真实验证；理解验收无用户作答，仍待检验。
