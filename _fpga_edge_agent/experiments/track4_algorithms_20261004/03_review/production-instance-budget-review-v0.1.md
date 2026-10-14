# 整机唯一实例与处理开销审查 v0.1

2026-10-05。LOCAL_DESIGN_REVIEW / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本报告是既有设计的有限预算审查，不新增业务接口或选择未经证明的共享，不生成源码、功能脚本、参考程序、TB或运行EDA。原目标保持五基础/六高阶、1920×1080、完整八邻域Canny及原识别/质量要求；现有板卡资源、允许DDR，bit后停止硬件步骤。

## 1. 先看整体结论，再看局部账

R1已按批准范围交付，证据仍在[验收及中文操作](../05_delivery/r1-software-acceptance-v1.1.md)。本报告不重跑已通过实验，也不把四pin25MHz结果推广为整包完成。

本轮完成具名RAM分支、控制冷存子集、不能相加的热容器集合及识别日志工作量核算。**完整整机预算仍未闭合，尚不能证明装入或速度达标。** 新发现的主要处理瓶颈是LINE_WORK逐票执行完整journal；ANN64只优化输出。下一项优化应直接针对该路径，保持原数值、最新值、组隔离与失败/关闭要求，不能靠降分辨率、丢难例或把失败算成功。

阅读顺序：§2唯一数据/常量RAM → §3冷记录与剩余空间 → §4热状态去重 → §5操作工作量 → §6有限缺口与下一动作 → §7来源及审阅。精确数据见[预算数据附件](production-instance-budget-numbers-v0.1.json)，它是文档数据，不是执行程序或测试结果。十一项状态见[完整范围证据审计](../05_delivery/full-scope-evidence-audit-20261005-v0.1.md)。

## 2. 唯一RAM分支：不重加父子或替代项

以下数值是候选RAM类块；20/16/8模式的native可寻址位与10240bit标称块容量分别计。实际原语、布局、所有FF/LUT/DSP及未知IP几何须实际工具验证。

| 唯一实体 | 已列块数 | 实际几何及端口边界 |
|---|---:|---|
| 原DDR controller/PHY/async bridge | 39 | C2父39已含PHY22/bridge17；本轮未展开所有内部几何，保ASYN1，不能再加22/17或预减17 |
| 原CSI父IP | 11 | 父11已含子11；保护体内部几何未全部展开；新NORM/ingress另计 |
| camera ingress / RAW / config / writer | 22+4+1+4=31 | ITEM220×1024；两RAW行各960×20/两RAM；ROM164×25以328个20bit词存；writer两bank各128×64，共4RAM，高16零 |
| 一份FE / Gaussian / newS / NMS | 8+8+4+8=28 | FE中值/Sobel窗口独立；Gaussian四行pair16；newS两行pair16；NMS两行pair32。1R1W/下一沿capture，停顿不预支访问 |
| ROW input / shared RX / output | 18+7+15=40 | 两input各RGB7/EDGE1/ANN1；RX128×135/7RAM；三output各2304×20/5RAM，core写/pair读。完整FULL/真实归还前不覆写 |
| PROFILE / FONT / NUM两个ROM | 1+1+2=4 | PROFILE八份52词；FONT98×20私有；NUM θ384词、projection258词各独立1R ROM |
| CONTROL / SCAN cold / DIR | 2+1+11=14 | 分属不同owner/域，具体冷存见§3，不能合并为同一“控制RAM” |
| **共享FE的已列基础小计** | **167** | 50+31+28+40+4+14；共享须统一FE owner/mode/终态dispatcher |
| **另保独立FE的已列基础小计** | **175** | 167+8；代码复用本身不能扣除物理窗口 |
| 新阶段权限cold cache（CR） | +1条件 | 32×295 → 480个20bit词，唯一300bit assembly与单序列器；替原hotcache |
| 新ROW metadata双域镜像（RMT） | +2条件 | 两域各3×472 → 每镜像72个20bit词，独立reader/writer及CDC，替原四族宽运输 |

明确分支：基础167/175；只额外采用CR为168/176；若再共同采用RMT为**170/178**。它们均未联合冻结为整机输入，也不是完整总数或fit结论。不能把176与177两个旧分支再相加。

原demo top89、旧framebuffer28/debug2、旧FULL_SW识别105/225RAM均不再无证加进此ALGORITHM路线。原DDR39/CSI11的保护IP只来自有限旧工程映射，不证明生产整包资格。JPOOL是DIR既有一RAM，RA/JL/ANN的pool增量为0。

167分支中117条新候选native容器合1124352bit，另50条原IP内部几何未展开；CR新增10240可寻址bit、独立FE8新增65536bit。这不是逻辑有效bit或综合网表利用率。RC ROW480B（3840bit）尚未选择native布局/端口，不能填0或擅加一块称完成。R3 NUM的16×192 scratch已明确为5732bit候选FF账中的3072bit，不另加四套核或未经选择的RAM。

## 3. 局部冷记录：真实词数和空位

共同采用现SC的LG/CLO/RJ 191词M1布局时：

| 唯一冷存子集 | 块数 | body bit | native已用 bit |
|---|---:|---:|---:|
| CONTROL D0/C0 | 2 | 13647 | 14040（323+379词） |
| DIR descriptor/pin/journal/M0/M1及stage | 11 | 101058 | 101408 |
| SCAN cold | 1 | 6736 | 6800（340词） |
| **上述子集** | **14** | **121441** | **122248** |
| CR cache增量 | 1 | 9440 | 9600（480词） |
| RMT双域镜像增量 | 2 | 2832 | 2880（合144词） |
| **共同候选控制cold子集** | **17** | **133713** | **134728** |

17块是控制子集，已经包含在170/178分支中，不能再加17。其padding1015bit，可寻址165888bit（13块20bit模式+4块16bit pin模式）、标称174080bit。空词不自动授权给别的owner，不从容量推共享端口。

DIR M0用447词余65；M1 RESULT282+stage191=473词（末地址472），余39。两metadata合**104词**，五RowCtx各ceil(865/20)=44词、共**220词**，不能直接容纳。旧149词stage剩81的例子已不适用于该分支；未选其它存放，不据此宣布必需或已经新增一RAM。

journal仍16×29=464词/9280nativebit，已含在DIR101408内；原176bit effects只有一个实际writer，不增加第二pool或第二台账。BK两entry、RC一entry及ANN64都引用此唯一池，但其holding/assembly/许可和关闭体另计。

## 4. 热状态：先辨集合，再谈全机FF

| 可核集合 | logical bit | 包含关系及不能删除的部分 |
|---|---:|---|
| 旧生产条件body | 63191 | 含CONTROL4097及五RowCtx4325等，不是全部FF |
| RMT替四族后的同口径生产集合 | 58028 | 63191−11508+6345；只替明确ROW四族，其他原项保持 |
| CONTROL scheduler/transport | 4097 | 已在上两集合中；3986双端body+23valid+88唯一sequencer，不再加一次 |
| CR阶段cold分支selected | 6780 | 15845−9440+300+32+43；含O窗口3409及余3371，完整admin/arbiter未含 |
| RA自有request/response/assembly及具名控制 | 2352 | 799/872/580与算法端不同，101具名控制；580串行复用但不能借BK两entry |
| JL双方holding及RC latch | 13079 | 每端6529、两端13058+21；allocator/expected/tag/valid等仍缺 |
| SM双owner证明/计数 | 1719 | count_maps1536及其余资格，不能用DIR initialized/valid_count替代 |
| ANN64新增字段 | 179 | pack128+count7+两prefix22；不扩原RQ/RSP，不代表179FF实测 |
| DIR少量hot | 436 | allocator248+唯一effects176+origin_state12，不含所有回读/更新体 |

这些集合不能直接相加为“整机FF”。例如CR内O窗口2257+descriptor640+pin512=3409也被BK列为候选窗口，须先确认真实同一实例/同时生存期/端口；CONTROL4097已经包含于58028。JL与原raw/O/BK的替代关系也没有共同freeze。

有限具名字段子集可写CONTROL4097+DIR436+RA2352+JL13079+SM1719+ANN179=21862；再列SC非O3371为25233，若O窗口确实唯一收费则28642。**这是字段审查子集，不与58028相加，不称全机下界、完整FF或XLR。** LUT、ADD、FF、SRL、DSP、packed XLR分别取证。

## 5. 从局部operation合到处理工作量

采用RA单entry串行、JL唯一native owner及ANN64 joint v0.2的正常成功分支，每entry为29WE+29RE+1stateWE=59 native issues。ordinary的59 WORD往返加四管理往返为126个单向control fire；DENSE16为944 native、978往返/1956单向fire。fire数是事件数量，不能直接当时钟周期、DDR byte或寄存器容量。

| 当前阶段及工作 | journal entries | native issues | JL单向control fire | data，不含INIT |
|---|---:|---:|---:|---:|
| phase1 POINT_BUILD，E条POINT64 append | E | 59E | 126E | 32E B |
| phase7 LINE_WORK，32E组DENSE16 | 512E | 30208E | 62592E | 16384E…32768E B |
| phase14 ANN64完整输出 | 32400 | 1911600 | 4082400 | 518400 B |
| phase14 RECORD512×64 | 64 | 3776 | 8064 | 8192 B |
| **上述小计** | **513E+32464** | **30267E+1915376** | **62718E+4090464** | 不是完整job总量 |

LINE_WORK的32batch×E，每组16个真实lane，不能当512E个并行调用。JL WORD depth1与RA阶段串行限制此RC流每core沿至多一native issue，故在假设100MHz下，J/f_core仅给理想单issue尺度：

| E条已构造POINT | J native issues | J/100MHz |
|---:|---:|---:|
| 1000 | 32182376 | 0.32182376s |
| 10000 | 304585376 | 3.04585376s |
| 100000 | 3028615376 | 30.28615376s |
| N=2073600 | 62763566576 | 627.63566576s |

100MHz在此范围未获STA；E=N只是接口容量包络，未证明真实R2图可达到；这些不是实际微沿服务、完整帧成功上界或用户接受的fps。旧“512E每票一沿≈10.62s”只有票数尺度，不能带入当前59-event日志架构当处理预算。这个核算改变下一行动：应先比较能减少每lane完整日志/控制往返的结构，再联合预算；本轮不假定bulk/cache已经采用，不删任何现合同成本。

若另按没有POINT/EDGE/GRAD读cache的分支，POINT_BUILD的N次EDGE+N次GRAD为32N B、LINE_WORK的32E POINT读为512E B；与上表合为32N+16928E+526592…32N+33312E+526592 B的小计。FIRST INIT及32次CLEAR、NUM、其他识别phase、权限/O/MR、可见性/END/关闭/仲裁均另计。JL宽depth1消息不是MR CMD966，不可自动乘MR98/613或转成串行字节带宽。

生产显示仍按[单实例服务设计](../../../planning/design-TRACK4-ALGORITHM-DDR-SERVICE-BUDGET-001.md)：1080p60=64800 active行/s；已知MR最早613间隔/行，即39722400间隔/s，只是无stall局部尺度。ROW970、cold hit23/更新38、RMT查询31等均需按真实依赖和独立engine组合，不能相加全部微值或把平均带宽充当deadline证明。

## 6. 完整预算仍缺的有限信息及下一动作

1. O唯一读回窗口/修改副本、RESULT1879/journal576 assembly、pending/tag/valid和各native端口仲裁；同宽表不等同一个实例。
2. stage admin双方held/private/expected、partial tuple、revision pending与旧publication集合；POOL/BK可信prepared/END/退租、two-entry assembly与唯一176writer的实际存放。
3. 生产五RowCtx、剩余HANDOFF/SCAN运输、camera/COPY/ARM holder、route/W/RX decoder、初始化/发布/回执、first-failure及CDC/reset的真实位置/并发寿命。RMT只替四族，未覆盖所有控制。
4. RC ROW480B的native端口及latest/RMW；R3实际DSP/LUT/时序；原CSI/DDR内部及选定生产整包真实资源。
5. 每operation完整II/最坏消费者和native/DDR/admin有限公平服务，实际camera模式包络、显示逐行时限、匹配DDR模型/PHY/可见no-future与完整质量验证。

下一项可独立纯设计工作是围绕已量化的LINE_WORK瓶颈做有限结构比较，明确哪些原journal/权限/关闭义务保持，怎样减少重复投票开销和相应存储。实际实现仍需要指定成熟设计及批准；R2/Q0原问题保持待答，不重复申请。没有把“预算难”写成硬件容量不足或资料中没有DDR。

本轮只做预算、来源澄清和下述文字勘误，全部业务源码/功能脚本/参考/TB/仿真/综合/布局/STA/新bit均未运行。formal state、Manifest、TASK_LEDGER、DB、原HDK及R1批准产物不改。

## 7. 来源、文字勘误与审阅证据

Root本轮按入口读取config/运行提示词/路径/state/ledger/database、Manifest/WORKFLOW；唯一v0.2前次完整读、本轮核同hash并读§10.1–11.2；模板全文。需求MD106行/CSV11项实际读；当前服务卡353行分四段全文。其余采用下表实际范围，不冒称全部设计全文联合验收。

| 来源 | 本轮采用与实际核读 | 当前身份 |
|---|---|---|
| DDR-SERVICE-BUDGET v0.2 | Root全文1–353 | SHA93C1E563…A43A8B9 |
| PIO v0.3 | data审查1–35/79–129/143–192 | SHAD3474B12…D0F835；旧39EA引用只属历史 |
| DIR / MR / CR | 三位子审表与Root DIR124–183/CR230–277/MR1–18 | SHA完整值在数据附件；DIR/MR/CR源本轮未改 |
| RA / JL / R4R / SM / ANN | service审查RA1–114、JL1–161、R4R189–319、SM23–96、ANN33–96；control/data其它有限段 | 同附件来源SHA；ANN保持joint v0.2 |
| RMT原v0.1 | Root99–112/158–197；control68–83/99–112/158–197 | 原257行34341B/SHA6764FD31…12CF339B，保存字节快照 |
| RMT v0.1.1文字勘误 | Root与control独立核差异1/3/180；其他原行对齐未变 | 当前259行34662B/SHA620052B9…C9B08BA |

[RMT原字节快照](../../../planning/design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001-v0.1-before-count-clarification.md)保存原SHA。原F2末句误称CONTROL4097不在63191，和同句公式/保留项矛盾；[现行RMT v0.1.1](../../../planning/design-TRACK4-ALGORITHM-METADATA-TRANSPORT-001.md)仅澄清已计入并保留，另插文字勘误说明/标题修订。接口、数值、布局、时序、批准状态不变；RMT不在R1/R2/Q0三份冻结输入中，旧报告/事件不回填。没有把元数据摘要替代协议验证。

三项并行只读审查分别承担data RAM、控制body/去重、逐op开销，实际范围在本轮JSONL记录。预算整数与合式使用现有PowerShell/JS临时metadata计算，没有保存可执行分析程序。最终文件读回/链接/源hash前后检查另登记；用户理解验收待真实反馈，完整目标继续ACTIVE。

