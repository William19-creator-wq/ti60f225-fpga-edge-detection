# 完整算法与生产链唯一资源、逐操作时间缺口审查 v0.1

2026-10-05。READ_ONLY_DESIGN_REVIEW / NOT_READY / NOT_APPROVED；本报告不创建业务代码、模型、可执行测试、脚本或工程，不执行构建。R1已有实测与全机尚未闭合分别记述。只保存本文；原planning、R1及五份已验收入口文档保持原字节。

## 1. 整体结论与阅读入口

当前可以证明R1有限工程实际使用8块RAM、0 DSP、packed XLR 3411；不能由此证明含CSI/DDR/完整Canny/BFS/识别/显示/控制的全机可装下。生产候选的167/175只是具名RAM类块小计，尚无完整唯一FF/LUT/DSP/PLL/CDC账和正常处理/连续供数时间预算。DDR父子、FE、ROW与控制RAM的重复项可以明确消除；未冻结的实例不以0填表。

最快推进点是把当前新LOAD-GRAD、STAGE-CAPABILITY纯设计候选的实际存放与权限快路径闭合，再联合一次完整正常作业的逐operation、源/显示期限和热状态预算。不能让CAPACITY拒绝、SEARCH_INCOMPLETE、SAFE、未知效果Q或超时失败成为正常服务证明；这些仍必须保留为真实失败语义。

阅读顺序：§2实际来源→§3唯一RAM→§4FF/LUT/DSP及冷热划界→§5逐操作成本→§6完整处理/生产服务→§7下一项数值设计与检查。目标保持1920×1080、完整八邻域Canny、原圆/任意旋转矩形及质量评价，只用板卡现有资源、允许板载DDR；采集fps、算法fps与HDMI 60Hz分别记，本文不增设算法60fps或降低场景。

## 2. 实际来源、SHA256与有限阅读范围

控制面入口、config规则/运行提示词/路径、state/ledger/DB README已按顺序重读。唯一规范此前全文核读，本轮重读入口及§0/1并核相同SHA `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`；只读审查适用§0.3，无实现批准申请。本轮不是所有算法原文的全文联合复审。

下表路径的planning项位于`_fpga_edge_agent/planning/`；review项位于本报告同目录；R1报告位于`work/active/track4_algorithms_20261004/r1/runs/r1_physical_005/flow/outflow/`。行号绑定当前原字节，hash不等于语义验收。

| 来源 | 本轮实际范围 | SHA256 |
|---|---|---|
| design-TRACK4-ALGORITHM-INTEGRATION-001.md，v0.8 | 1–271，分段读回 | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF |
| design-TRACK4-ALGORITHM-PERFORMANCE-001.md，v0.2 | 1–396，输出截断处150–396重新分段补读 | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 |
| design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md | 1–116及118–231的范围核查，重点94–112/127–141/172–182 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md，v0.2 | 1–235，分段读回 | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 |
| design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md，v0.2 | 48–180 | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8 |
| design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md，v0.2 | 67–192 | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 |
| design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md | 69–149、174–207 | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 |
| production-unique-resource-and-control-ram-v0.1.md | 1–100；首段截断后整份重新读回 | F3D84B4AB57CF457139C238B3F5988E73F3092BB94D7AFB6D0998BFEC2657C47 |
| production-stage-holder-review-v0.1.md | 1–101 | D8967256E44D1C2AD4190F9E217E56C3FB371BBA92E020ED25D5ADB2F4AF28B7 |
| design-TRACK4-ALGORITHM-NO-LOAN-CLOSE-001.md | 关键词命中64/72/73/75/81/96/98/104/128/139/172/175/180/182/184；采用104的+6 body、98的20状态增量，未称逐行全文 | 3E075B87350009EAF391D937C176D34070A7C6EE97157C1A5F1B0F8BEA7E653E |
| design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md | 159–196 | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 |
| design-TRACK4-ALGORITHM-R2-001.md | 58–74、159–170 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 |
| design-TRACK4-ALGORITHM-R3-001.md | 240–269 | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D |
| C2/outflow/ti60f225_oob.map.rpt，位于work/active/track4_ip_precheck_20261004 | 2358–2375、2470–2478、2501–2510、2627–2635、2786–2799 | 8E5077141AE845D9307F8518657B097EE61E2359D0E07861F6181D6267B572BB |
| R1 r1_algorithm.map.rpt | 444–504 | D2C821B2C30483D6D3C615A2C88C039774F115F06885F5F70FE8406F7B54F28F |
| R1 r1_algorithm.place.rpt | 1–42 | E249B53B316780C94CDE993B308055AEFC8F49BEC3BBCD432C4F7ECF7A04CAC0 |
| R1 r1_algorithm.hier_util.rpt | 1–26 | 64BF6ED5E837D0D7C5D6D79526796D8F77A59910C7504C48958DEED5C4A102A8 |
| r1/docs/frontend-verification.md | 本轮末18行；前一已完成任务实际全文及证据核读 | DCCB2E1545EDCA8C564AF99B96D7D3AB90D05C2C2617DAB4ED50FCA2DFDFEC73 |
| r1/sim/frontend/runs/frontend_suite_006/suite-result.json | 本轮hash；前一任务真实完整123案运行/聚合 | 72DA8D743B4B0BE4A3D50AC8A1E941A1D58C5FDA3F41BD7F8B634A95FDE039DB |

本次静态整数核算使用现有PowerShell表达式，没有保存或生成可执行分析程序。LOAD-GRAD与STAGE-CAPABILITY新卡作者仅交换纯设计需求；未定稿消息不作为冻结输入并入旧schema。

## 3. 唯一RAM实例账与重复项

| 唯一实体/owner | 已知RAM类块 | 证据与去重边界 | 仍未计入 |
|---|---:|---|---|
| 既有DDR controller/PHY/异步AXI bridge | 39 | C2 map2507父层39已含2508 PHY22和桥17；禁止39+22+17 | 新byte adapter/journal权限、QoS/命令holding、改变ASYN后的真实映射 |
| 既有CSI父IP | 11 | C2 map2369父层11；不再加其子同11 | 新NORM metadata、保护IP实际功能验证、完整CDC |
| 新camera ingress/RAW历史/config ROM/source writer | 31 | PIO173–175：22+4+1+4；不同于CSI11与FE行窗口 | ARM/current/closing完整holder、capture/RX消息、Bayer算术/状态 |
| 生产ROW payload | 40 | ROW140：input18+RX7+output15；PB的25与PIO row15已被覆盖 | FULL/route/decoder/prefetch/held/ctx/CDC热状态 |
| 一份FE及Canny后级 | 28 | R2 163：FE8+Gaussian8+新Sobel4+NMS8 | 算术pipeline/C0/FK、GRAD/CLASS生产收集 |
| 独立R1 FE（保守不共享选择） | +8 | 原中值/Sobel各独立两行窗口，R1实际两窗口各4；共享需统一FE owner/模式/终态dispatcher | 不可因数学相同自动共享当前R1 top观察器/源/全部控制 |
| PROFILE完整实体 | 1 | 整合59：八份1024bit/52词；已在旧153中 | catalogue1808、完整GET/install/held/策略状态 |
| FONT | 1 | unique审查33，与R3两ROM独立 | label/raster pipeline |
| R3 θ/projection两只读ROM | 2 | R3 260，各20×512；不含FONT | 宽算术/工作区/调用控制 |
| CONTROL冷记录D0/C0 | 2 | CONTROL62–85：323+379词；共享sequencer只有一套 | 明确另有4097bit列出状态，原业务held/pending仍在 |
| SCAN冷CTX/成功摘要/两cache候选 | 1 | unique88–90：340词；pair域，不能凭容量并入core D0/C0 | Q快照/即时ARM、真实held与下级epoch/CDC |
| 生产descriptor/pin/journal/metadata | 11 | DIR175：descriptor4+pin4+journal1+metadata M0/M1两块 | 完整回读/许可/pending/allocator/更新与服务 |
| 三stage完整body落M1空段候选 | +0（条件） | stage审查40–44：149词放282…430；不另加三RAM | 新热/lookup/运输/context保持及GRAD关联尚须新卡冻结 |
| **共用FE的列出小计** | **167** | 153+CONTROL2+SCAN1+DIR11；只是候选 | 下表未知项不为0 |
| **保守独立FE的列出小计** | **175** | 167+8 | 不证明全机fit |

原C2 map顶层89对应85 EFX_RAM10+4 EFX_DPRAM10（2788–2797）。39/11来自原hierarchy合并类型；167/175不能写成已经映射的167/175个EFX_RAM10。完整工具报告中两种实际原语及容量/端口必须分别核对。原demo frame_buffer28、debug2、Debayer/gain/gamma等被新链替换的部分不能再加整top89；若保留调试，应只增真实保留实例。ASYN0尚无实测，不能先减桥17。原参考DSP4不自动保留，也不自动变成新算法DSP0。

CONTROL D0/C0、DIR M0/M1和SCAN cold是三组不同记录/owner/域。不能因都称“控制RAM”合并扣数。DIR M0已447词、M1结果282词；三stage cold占149词后分别余65/81词。五RowCtx865若另选20bit冷存，各44词、共220词/4400实际词位；65+81=146词不能容纳它们。CONTROL剩余322词分处D0/C0且当前不授权RowCtx访问，SCAN余172词也无跨域共享合同。新增一RAM是一个可行容量候选，但不能无证宣布必须新增或已经可共用；仍需真正owner/端口/寿命选择。

未分配的RAM实例必须显式填：STORE/latest/原子组快照、完整production byte/raw adapter、R_ROUTE与W_CTX、宽body装配/FIFO、LOAD/GRAD packer/状态保持、SOURCE/COPY/camera holder、CONTROL/VIEW/政策/冻结/epoch/mailbox、ROW/SCAN热记录可能选冷存、R4阶段热表、R3工作区是否FF或RAM、观察/通信选择。将其全部写0会造假。64pin的4RAM是物理表容量，不证明真实holder同时上界或正常准入；尚未证明的61等pin候选不转成资源验收。

PERF302的full-radius HIST新增512KiB候选原地址[0x05440000,0x054C0000)与整合63的现camera ring起点0x05440000重叠；如选H1必须新正式布局，不能直接同时接入。PERF306的DENSE16 RAM+160 marker也是未采纳候选；不能静默加16后声称最优，也不能把160当整个DENSE热状态。

## 4. FF、LUT、DSP、XLR与冷记录分开记

### 4.1 R1实测边界

R1 map450：有限top为FF2305、SRL78、ADD575、LUT1886、RAM8、DSP0；map454的frontend core为FF1969、SRL78、ADD479、LUT1511、RAM8、DSP0。place27–39的packed全top XLR3411由LUT4 854、LUT4+FF1034、Adder174、Adder+FF401、SRL78、FF-only870构成。**3411是packed XLR，不是3411 FF**；FF bits、LUT instances、ADD及packed XLR不能相加成一个百分比。两个窗口各4RAM，厂商RAM原语真实存在。

core实测packed XLR2813（hier8），比top3411少598；这598包括源/观察/LED/复位/监督等当前有限外壳。生产替换外壳时不能直接继承3411，也不能精确从3411减598就声称新top大小。R2 Y_ONLY虽然可优化诊断扇出，真实窗口与中值及唯一owner义务仍应按新top实际映射；不能凭当前末级未被使用就预扣一窗口。

R1无停顿四FT11各cycles1,038,747是已验证局部数；将其按物理25MHz换算41.54988ms仅为同样无停顿条件时间，不含源DDR供给/目录/Canny/闭包/识别/显示，也不证明100MHz生产STA。当前R1的0DSP不能传播到R3宽乘、DENSE或Bayer链。

### 4.2 当前可追踪的逻辑状态与未知项

| 区域 | 已声明容器或记录 | 存放/去重检查 |
|---|---:|---|
| CONTROL RAM engine/scheduler | 3986运输body+23valid+88局部热=4097bit | 已计源CMD目的CMD、源IMAGE/目的IMAGE；914 assembly各是其中既有实例，不能重复加或删除另一端 |
| HANDOFF基础+FETCH真实运输 | 新12800+2014=14814bit | 与6240持久关联及7407完成cache分开；两端held/private不因cold副本而消失 |
| 五RowCtx | 4325bit | 还未选择真正cold/热；不被64bit assign关联或D registry替代 |
| published ROW三bank四族 | 11508bit | 六份/族实际双端容量，与RowCtx/SCAN事件不同 |
| ROW本地读/预留/返还族 | 3000bit | out私有return等仍另列；不是整ROW控制成本 |
| ROW私有cache/decoder/math/writer payload | 1219bit | writer275已经包含，不再加一次PIO275；ctx/valid/pending/地址另计 |
| SCAN消息/记录/metadata | 30306bit | 已含CTX3360及Q444；不能再加3360或再把Q放进别组免费 |
| SCAN所提cold记录 | body6736bit，实际340词/6800词位 | 3360+264+1292+1820；即使真移冷，仍余23570bit已列body，含即时Q444和ARM group等 |
| pair adapter | 638bit | 已含六新增ref_valid；96+80+6×77，不再额外加6 |
| DIR小部分热状态 | 436bit | allocator248+journal effects176+source资格12；完整640/512/576/1879回读、lookup、更新、held未计 |
| PROFILE catalogue | 1808bit持久记录 | 真实存放/热镜像/GET回复独立，不因PROFILE RAM1而免费 |
| R3候选 | 5732bit+两ROM | 16×192 typed workspace/384级scalar等已列；实际DSP/LUT/周期未冻结 |
| stage新候选 | cold2965/实际2980bit；热278或296、快照7004或9980不同选择 | 三body冷存不等2257bit native返回/assembly免费；这些是互斥结构，不全部累加也不任意取最小后授权限 |

一个用于暴露规模的**条件逻辑容器算式**：假定采用现列SCAN cold分配，仍按原运输独立实存，则14814+11508+3000+4325+23570+638+1219+4097+20(NO-LOAN新增)=**63191bit**。此数未含DIR436/回读/held、camera/COPY、R2、R3、R4、CONTROL/VIEW/CDC；它不是“63191热FF已测得”，因为RowCtx与其它body的实际存放尚未选，且逻辑bit与packed XLR不同。它也不是全机不可能性结论；它说明不能把cold搬存后的余数自动当小FF预算。每项若改串行/RAM运输或真正共用held，必须有新的完整接口、assembly/pending、端口与期限设计，扣一次对应原实例。

PERF152的旧RAW per-client13368、CORE9516、seq520、FIRST_ERR930，以及R4R槽8771是旧逻辑声明审计；production RAW/O/DDR替换时须逐实例沿用/替代/退出，不与DIR11或上述body盲加，也不无证全部删掉。R4候选乘/统计、coverage、候选/排序工作区等LUT/FF/DSP未落位。DENSE parallel16的32个12×17逻辑乘不是已经32 DSP；R3 16×16部分积也不是已证明1 DSP。160 DSP和60800 XLR是器件容量（DIR182已绑定本地资料），不能用“DSP富余”替代实际使用配置、复用与时序。

全机唯一账至少必须为每物理实例列：稳定实例名/owner、schema/宽深/原语类型、源held/目的private/assembly/热mirror各位置、有效期及复用屏障、时钟域、1R1W仲裁、真实FF/LUT/ADD/SRL/DSP目标、来源和是否包含子项。PLL/global/clock mux/复位同步、TMDS disparity/serializer、实际CSI/DDR保护IP、I²C与选定UART/GE均另列；不借同频输出共享PLL。

## 5. 逐operation代价与具体遗漏

### 5.1 CONTROL共享短事务（合同中的最早间隔）

令L为完整实际词数；以下从e0 CMD fire到下一CMD最早接受的**间隔**，根据CONTROL184–189。在接收/本地消费无停顿、原语前提成立时有效；不是有stall的最坏服务上界。多owner不能同时各得此服务，scheduler轮转等待另计。

| operation | native事件 | 下一CMD最早间隔 | 具体实例/边界 |
|---|---|---:|---|
| WRITE_RECORD/WRITE_CACHE | L次WE，提交valid/独立ACK | L+6 | REGISTER record46/cache92；OPEN loan23/cache44；ASSIGN assoc4/cache51 |
| READ_RECORD | L次RE+下一沿capture，IMAGE/ACK独立 | L+8 | registry46→54；loan23→31；outKEY9→17 |
| RETIRE_RECORD | L次RE/全文比，撤valid/ACK | L+7 | 不能按header count0当0访问；registry53、loan30等 |
| MATCH_REPLAY hit | 请求Lq RE/比，回复Lp RE/capture | Lq+Lp+9 | REGISTER46+46→101；FETCH16+TERM18→43，不读ACK18当上层回复 |
| REGISTER正常两job | 46+92 WE | 52+98=150 | 另有actor判定/发布与运输；原registry资格不可在两job中间泄露 |
| OPEN成功两job | 23+44 WE | 29+50=79 | grant真实created先由O保留；冷valid0不能推未创建 |
| ASSIGN成功两job | 4+51 WE | 10+57=67 | 全RowCtx/input真实占位另计 |
| FILL cache | 34 WE | 40 | 最后实际FILL/TERM/ACK先形成，不等待未存在的cache |
| FETCH completion cache | 52 WE | 58 | 必须真实TERM342交付、ACK350被正确消费后开此metadata job |
| OUT_RETURN/BULK_CLOSE cache | 56/50 WE | 62/56 | 物理返回与cache完成/记录retire不是同一事件 |

mode5一行真实burst最多8。若每个FETCH按58间隔做cache，另ASSIGN67与FILL40，每行共享引擎需要的连续短job最早占用量至多**571间隔**（67+40+8×58，按该最多burst形状；实际burst少则相应少）。该值不是所有行必须至少571、不是全行墙钟上界，也不含READ/RETIRE/out/其它owner排队。与970沿render及DDR填料怎样重叠，必须有真实单实例调度，不能给每个owner都复制一个“免费98拍”引擎。

### 5.2 DIR普通权限与stage转换

DIR151的当前串行流程为锁完整caller→descriptor32词→pin32词→真实holder全核→校验→许可；每个native RE下一沿capture，末capture后另沿使用，完整cold body不是1拍cam。只有下列读发射数是直接可数：descriptor640=32、pin512=32、SOURCE26、RING15、LEASE27、RESULT94，holder LC14/CLJ22/RJ113词是stage新cold候选。最终请求到许可的准确拍数仍缺仲裁、capture、check、assembly与held调度，不能把64读issue说成64拍完成。

按PERF208 GENERAL闭包最大请求工作量13N+4=26,956,804，将当前每请求顺序两表64词乘入为**1,725,235,456读issue沿**，在尚未STA的100MHz下17.25235456s；这是实际执行该最大请求规模、且每op采用该串行两表的条件成本尺度，未含holder/DDR/计算。不是任何图/任何优化实现的绝对帧时下界。闭包holder是CLJ，不用RC RJ；不得把每次多读113词RC的算例强加给闭包。

逐operation尚必须冻结：stage BIND一次全文验证/descriptor+pin安装、partial pin失败关闭、LIVE普通grant查验、CLASS LOAD→CLOSURE、POINT WRITE→immutable READ、ANN/RECORD commit后reader、revoke/close/return与metadata退休。若新capability快照加速，ordinary仍要核全H/role/object/ref/version/grant/原generation和真实phase；STORE实时initialized/valid prefix/queue tail/latest/group不能冻结成旧常量。mutation先封新ordinary、履约旧held/pending，真实屏障后才失效/重验证，不能用cachemiss销pin。

stage审查的149词放M1只是cold容量证据。M1 RESULT/holder共享1R1W，result封存/返回/历史READ与stage绑定不能各占独立免费端口；RJ2257全文返回的assembly/pending与lookup服务必须明确。三个stage32pin只是旧候选讨论，新的完整GRAD/source授权不能由LC270单独推出。

### 5.3 ROW、R3和存储effects

ROW136最早e970 READY只从**完整input、out资格已经成立**开始；405 DDR拍、720逻辑WE、2880 laneWE、RX RE/capture/解包与global许可先后均另计。首/末JOIN e4/e963，末writer交付e967、stage e968、WE e969、旧资格READY e970不可压成同沿。输入返还、ROW472/OWNED、RELEASE/ACK及四scan关闭也不是970已包含的开销。

R3的MUL144部分积/24word、DIV192位步、SQRT96组、ANGLE≤8次三word比较、finite q≤19bit决策是**内部步骤上界**，不是完整144/192/96沿响应。符号/guard/RNE/搬运/ROMcapture/REQ/RSP与stall、typed LS/TLS子调用数量都未闭合；不能以R3表5732bit与一个乘实例自动给全识别fps。

每typed op另展开真实record packing、raw read/write、跨16B拍和journal/effects：1…64B请求未对齐可覆盖最多5拍；bitpacked CLASS/ANN/EDGE与QUEUE邻record若全WSTRB策略需合法已初始化rounded span/RMW排他。CLAIM state+queue append、DENSE16、latest forward、logical_commit、实际写/B/R/可见性、typed reply/close与O return分别计。一次logical请求既不是一个AXI拍，也不是一次RAM写；UNKNOWN/取消后的已issued效果不能在预算里删掉。

## 6. 完整处理时间、DDR流量和正常服务

### 6.1 算法工作量仍缺真实每op微调度

PERF201–232已给必要主项：R2全N/P及CLASS/GRAD封存；LOAD P+1；GENERAL闭包上界13N+4；POINT构造N EDGE读+N GRAD读+E POINT写+E kind8；圆anchor全pair/seed、hist的16C_s E遍、五遍圆5EΣb_s；DENSE32E组/512E票；coarse、6GE TLS、全部矩形候选/finite核验、Q次重验、最多64Q精确support遍；全N ANN及64 RECORD。SEAL/排序/候选上下文/关闭M_i不能默认0。

给定原路线极值E=N时，PERF293–300的radius4096遍POINT有效67,947,724,800B、圆五遍1,358,954,496,000B、TLS101,921,587,200B、精确去重2,174,327,193,600B，在**独占nominal1.6GB/s、无计算/竞争**下分别42.467328/849.34656/63.700992/1358.954496秒。它们不保证同一正常成功图同时达到；也不能靠CAPACITY先失败来替代目标质量和正常吞吐设计。全HIST可省15遍/seed重复距离，DENSE可压计数bank，但总CLEAR/读/NUM/热点latest及服务不能凭方案名消失。

完整成功预算应实际给出 `C_local + Σm_o·(metadata_o + raw_reads_o·L_read + raw_writes_o·L_write) + Σn_k·L_num(k) + 有限协议/消费者等待`，可重叠者另给单实例依赖图与max表达式。每项带实际clock、前提、服务上界和来源；未知的M_i/n_k/L不填0。只有有限backend/消费者前提能给成功上界，错误timeout只能定义失败路径。

### 6.2 生产流量必须加入IMPORT，不只camera+display

固定显示最坏419,904,000B/s，camera RGB写为6,220,800·f_c B/s，**每次COPY读+写12,441,600B**（整合65）。必须再加12,441,600·f_i，其中f_i按单COPY实际ALG及冻结补源总接纳率计；同一copy不重复算两个目的。算法读取immutable SRC、GRAD/CLASS、BFS/QUEUE、POINT遍、RC表/journal/rounded RMW和观察流量另外计。

因此必要平均余量为 `η·1,600,000,000 − 419,904,000 − 6,220,800·f_c − 12,441,600·f_i − B_algorithm − B_other`；f_c/f_i是待冻结实际模式/政策参数，不是新增用户fps条件。单看PERF289的capture+display情景会漏COPY生产成本。

用于显示成本尺度的条件情景：若f_c=f_i=60，前三项共**1,539,648,000B/s＝nominal96.228%**，独占理想只余60,352,000B/s给全部算法/刷新/turnaround/命令。这不是要求每capture必须import，也不是断言所有合法模式不可能；说明不能在未计IMPORT时宣称“capture+display只用49.572%所以算法充裕”。选定正常政策须保证实际算法有正且有限的服务份额，不能永远被capture/display饿死。

容量方面现124.25MiB在256MiB名义容量内只是布局候选。五ring的closing≤1、提前ARM、COPY持ring期限、writer/latest/future复用仍须真实最坏关闭界；不能占满后拒捕获或长期锁旧latest来证明正常接收。

### 6.3 逐行与两首行期限

1080p60每行14.8148148µs。local ROW970沿在100MHz候选下9.7µs，尚有约5.1148148µs待填真实许可/填料/控制/CDC/调度；实际能重叠哪些步骤由两input、三out、单RX/route/renderer与CONTROL共享引擎决定。若不证明重叠而把上述最多burst的metadata571与local render970顺序相加，会是1541间隔≈15.41µs，已超过行总时间，且还没有DDR等成本。该条件算例不是现合同必然失败结论，而是要求明确正常调度、避免串行假设与免费并行混用。

SCAN158–164要求两future首行VSYNC前真正READY/OWNED；尾段59.259259µs只有三out，旧最后行+两首行占满，随后row1必须及时取得真正返还bank。双首行12960B/810拍、1440逻辑WE/5760 laneWE、两次970局部render还需共享metadata/许可/CDC及未选关闭。两input不能同时被未选路线无限占用。old_closing须真实释放后下一采用，closing容量与有限服务必须联合证明；SAFE是真失败输出，不能当正常服务方案。

## 7. 最快能闭合的下一项数值设计

建议下一份**候选数值附件**以一个正常完整作业和连续显示为边界，不提前写RTL，按以下固定顺序完成。此处是审查建议，不覆盖在写LOAD-GRAD/STAGE-CAPABILITY卡，也不替Root选择未定稿方案。

1. **先冻结唯一热实例表。** 将§4每项标为真实cold/held/private/assembly/热mirror并逐个命名。优先决定SCAN transport与五RowCtx的实际位置；63191逻辑bit不能直接全放FF。若串行body/FIFO或RAM运输节省宽副本，完整目的接纳、组提交、Q/STOP即时槽、pending与CDC闭合都必须成为新合同，不能只把payload移RAM后扣FF。
2. **冻结stage能力快路径与LOAD-GRAD完整生产记录。** 接受一次BIND全文验证，普通read/write/claim等有明确有限metadata路径；选择“冷全文逐op读”或“稳定能力快照＋实时STORE边界”之一并给实际hit/miss、phase切换、revoke/return等待。用实际pin/ref/gen和唯一writer保旧事务；GRAD/SRC三个pin来源与收集32bit/N全覆盖/COMMIT/close先满足，不由LC270凭空授权。
3. **给一份操作矩阵。** 每op列 caller/完整消息、descriptor/pin/holder读词、已有热查验、数据raw读/写/AXI拍、NUM kind次数、native锁持有、最早与最坏服务、真实close成本。至少覆盖LOAD/class pair、GRAD pair、READ_CLASS/CLAIM/READ_QUEUE/EDGE export、POINT+kind8、HIST/DENSE/CELL/EXT、LS/TLS/finite/coverage、ANN/RECORD，以及REGISTER/OPEN/ASSIGN/FETCH/FILL/ROW/RETURN。不能只给operation总数不列r/w/NUM。
4. **先算可复核样例，再算上界。** 对E=0、强弱混合长链、正常圆/矩形及高E纹理输入使用提前冻结完整PROFILE/GT参数和实际循环计数，给全部N处理、错误统计及两类P/R评价的保持；以PERF上界覆盖未知困难负载。样例快不证明最坏成功，容量/预算拒绝记入失败，不用它保证正常fps。
5. **给同一时钟/同一实例的服务表。** CORE100仍候选；明确camera、display、COPY、算法与metadata真实固定/保留份额及最大不可服务间隔，计算所有FIFO/holding累计入出、两首行/row1/稳态期限。正平均余量和最大服务间隔二者都成立，才能选择实际并行/共享及CLOCK配置。
6. **最后合资源与批准对象。** 每一个未知实例由上述具体结构落位，汇总RAM分型、FF/LUT/ADD/SRL/DSP/PLL/GBUF及端口；只扣真实同一实例一次。新卡成熟hash/range形成联合baseline后由Root审阅，才按规范提交指定设计批准。现R1批准与实测仍有效，不重复询问同一范围；新完整链保持NOT_READY。

最快的数值闭合成果应包括：一张不重不漏的物理实例表、一张真实逐op成本表、一个完整job参数化处理式，以及一个满足camera/显示/COPY/算法份额与逐行期限的正常服务情景。它们都不能由“175<256”“0DSP”“DDR容量够”“metadata只几千bit”四个局部数字替代。

### 7.1 并行纯设计需求交换（非冻结输入）

LOAD-GRAD作者本轮消息提出LG1119＝J657＋LC270＋source_id64＋admission_ref64＋grad_build_ref64；其cold56词替旧LC14词，与CLJ22/RC113共191词/3820native bit（body3814），拟M1 RESULT0…281/LG282…337/CLO338…359/RC360…472，余39词；比原stage审查149词多42词/840native bit，仍可容量上不另RAM。原§3/4的149词/余81仅绑定已读旧审查hash。新卡尚待保存hash/原文读回，本报告不据消息改旧目录或宣布新共享仲裁已成立。

同消息提出SOURCE reader与GRAD collector各独立typed depth1：正常SOURCE P次读取，retain_grad1再GRAD P次pair写＋1commit；相对PERF E2已计的CLASS＋GENERAL闭包13N+4，新候选主项增2P+1，联立29,030,405 logical requests；retain0增P为27,993,604。该数只是候选操作层导出，prepare/目录/close的M_i另计；不是DDR burst数或实际cycle，RGB6B可能跨两个16B span，GRAD8B/CLASS4bit仍要真实packing/init/RMW/journal。新增hot/transport/服务OPEN，不以独立depth1等于免费并行。后续由Root确认保存后的卡与STAGE-CAPABILITY联合版本才允许纳入冻结输入。

## 8. 本轮交付与限制

已保存本文并实际读回、核来源hash；未改旧卡/业务源/五份入口文档，未生成可执行测试/script，未执行仿真/综合/布局布线/STA/PGM，未网络、安装、修改许可、数据库或硬件操作。R1实际验证归原独立证据；本文只做资源/时间审查与下一项设计建议。全机fit、正常处理速度、生产连续供数及剩余算法/后端实现仍未证明。
