# TRACK4-RESOURCE-SERVICE-BUDGET-001 v0.1：整机资源与服务预算诊断

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)填写，关联[完整软件主计划](design-TRACK4-FULL-SW-001.md)。2026-10-04。**本稿完成只读预算诊断；整机业务设计仍为LOCAL_DESIGN、NOT_READY、NOT_APPROVED。没有生成业务实现、功能脚本或testbench，没有运行本次综合、仿真、布局、STA或bit/hex。**

## 通用计划字段

- Goal：把五基础、六高阶的既有候选放到同一器件、同一时刻、同一资源单位和服务期限中核算，定位性能与资源的真实缺口。
- Current state：局部草图已列225 RAM10；识别29168bit只是局部寄存器候选。完整热状态、外部IP和最坏服务界尚未统一。
- Target state：唯一物理容器及其生存期、完整IP占用、有限仲裁/缓存与期限、数值和质量均有可复核依据，然后进入指定版本评审与实现。
- Gap：本稿D/E逐项给出，不能用局部小计、平均带宽或旧报告替代。
- Assumptions：预设Ti60F225 DemoBoard V4/I3、SC431HAI彩色4lane、生产1920×1080；core100MHz/pair74.25MHz/pixel148.5MHz是候选；相机fps及PPC须按实际选定IP配置核验。
- Open questions：匹配2Gb模型/PHY的实际合同与资源、完整热冷布局、CSI/serializer的真实时间合同。既有FRONTEND和模型申请仍待答复，本稿不重复发问。
- Dependencies：现行v0.2、冻结父稿/中文附件、本地官方工具资料；保留原HDK只读和原审批。
- Milestones：统一单位→去重RAM→逐类FF/消息/保持→服务与工作量→诊断/修订入口→获批后真实工具验证。
- Detailed steps：B/C整体结论→D唯一容器/共享条件→E中文预算及优化草图→F语言/时间→G/H验证与追踪。
- State transitions：仅增加候选设计文档；正式H0/ledger/Manifest/数据库不变；不自行把NOT_READY改成APPROVED。
- Artifacts and hashes：输入哈希及当前文档检查保存在实验05；Demo历史map/place的精确来源见A。
- Validation：只运行文档、哈希及静态算术核对；功能/品质/综合/PNR/STA均NOT_RUN。
- Failure handling：不可证明共享的槽不扣；未知外部IP不计0；无真实有限服务界不承诺期限；容量失败和漏检保留于质量统计。
- Human approval gates：本稿不新增实现批准请求；未来完整指定版本与基线仍按v0.2和原制度审批。
- Rollback：保留父稿原字节及执行阶段检查的历史副本；本稿J列的是提议与发现，不偷偷改旧契约。
- Completion criteria：预算诊断可交付；完整软件目标只在真实实现、验证和bit/hex具备后完成。

## A. 状态、范围与实际来源

本稿只汇总和诊断已有候选，不增加目标数量、尺寸、噪声、遮挡或相机帧率硬限制，也不降低精确八邻接Canny、同源冻结、圆/任意旋转矩形及独立每类P/R≥95%的验收目标。当前正确性缺口RB-B01完整热冷/唯一容器布局、RB-B02真实DDR/CSI/serializer合同与外部IP资源、RB-B03显示/采集最坏服务界、RB-B04联合版本吸收及既有实施/模型/数据库前置。未运行质量/综合属于批准后证据，不循环要求先写未批准测试才允许评审。

主要输入是FRONTEND v1、FRAME-MANAGER v0.1、CANNY v0.4及其窗口/存储/父writer附件、DDR-SERVICE/PLATFORM/CAMERA/DISPLAY/CONTROL/CONTROL-JOIN/DATA-JOIN各v0.1，以及RECOGNITION/NUMERIC/ALGORITHMS/EXECUTION各v0.1。父稿保持原SHA，详见[当前检查](../experiments/track4_full_sw_20261004/05_reviews/document-checks.json)。EXECUTION原字节SHA为F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178，最终读审SHA为8279917D7A68E0D6A5B55FB18BAB0B35EFAAF156069DE73D29BFBE0C3C0C3158。

用户指定VF/Demo目录均存在：VF展开11672文件、Demo展开5254文件；DDR controller/PHY/校准和4Gb/x16器件模型均有来源，V4另有SC431HAI v6工程。缺口是当前检查范围未发现完整匹配V4 2Gb/x16器件参数组合，具体文件见[路径补充证据](../experiments/track4_full_sw_20261004/01_baseline/vf-demo-supplemental-evidence-v1.md)，不能概括成目录无DDR资料。

| 官方/历史来源 | 实际来源及SHA256 | 使用边界 |
|---|---|---|
| Ti60资源单位 | VF嵌套目录03_芯片数据手册/钛金Ti60datasheet-v2_0.pdf；0AB5A7D4143811668DB8E34C671DE30A97588846E931CD8854FA37AA6144468E；页4、6–8 | XLR62016、LE60800、SRL8可配14720、RAM10×256、DSP物理块160、F225 PLL4 |
| 原语模式 | 本机Efinity2026_1/sim_models/verilog/efx_ram10.v；DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 | native512×20合法；不能以总bit忽略端口/碎片/时钟 |
| DSP推断 | 本机doc/topics/syn-dsp-inferring.html；0D2E9CA1ACAE7C6A1524B3227F1F7698A2A98B7D90F7A6488105EF4480F7D8F1 | 官方≤19/18宽度DSP48及同clock要求；推断候选须实际packing/STA |
| 旧map | [tinyml map报告](../../Demo/Demo/tinyml-main/tinyml_hello_world/Ti60F225_tinyml_helloworld/outflow/Ti60F225_tinyml_helloworld.map.rpt)；1CEBD8153575236F2A07A994454AE290DCF4CE2F81D2A23C3ABF47267F0D1FBE | 2025-07-07，Efinity2025.1.110.1.5；不是本次构建 |
| 旧place | [tinyml place报告](../../Demo/Demo/tinyml-main/tinyml_hello_world/Ti60F225_tinyml_helloworld/outflow/Ti60F225_tinyml_helloworld.place.rpt)；F6DDD170E73AD1846AAEB2A6E4B3E74E6C99FFC61308F6451D66398B26547398 | XLR44027/60800、RAM145/256、DSP47/160；不证明新整机可放置 |

旧map全工程FF23257/LUT4 27734/ADD5622/SRL8 840/RAM145/DSP48 47；u_ddr3_top层级FF2621/LUT3030/ADD288/SRL712/RAM22/DSP0。层级资源估计可能受优化归属影响，且版本/设计不同，22 RAM只用于条件比较，不能作为新protected端点保证上界。root实际核对报告头/资源节和哈希，未运行报告中的命令；不把一次截断rg输出写成全文核读。

## B. 整体要求与结论

| REQ | 要求及判定 |
|---|---|
| RB-REQ01 | 全机统一资源单位；FF容器bit与LUT/ADD/SRL的XLR packing分别记录，DSP12/24与物理DSP块分别记录。 |
| RB-REQ02 | RAM按唯一物理bank、端口、原语宽深、同时生存期计；外部IP另计，未知不写0。 |
| RB-REQ03 | 所有不可撤销payload/身份、pending、terminal/ACK、热复位保持与恢复镜像都有有限容器；扣减共享须有实际映射与关闭证明。 |
| RB-REQ04 | 1080p60扫描不可反压，采集入口接受SOF后不可反压；平均带宽、仲裁机会和服务期限分开核算。 |
| RB-REQ05 | 识别优化依据完整工作量、资源和独立质量；保留已定数值、支撑集合、全部失败样本与用户撤回的边界选择。 |
| RB-REQ06 | 诊断/设计/工具运行/实机事实分层；当前缺口明确，既有批准不擅自扩大。 |

正常预算例：共享FE8已含在Canny44内；PL旧PIX9由DP row21替代，只计一次，得225 RAM。反例：225/256小于100%不能证明可装入；外部IP仍有内部FIFO/ROM，DS与RC已有全宽FF候选60176bit，其余模块还在。正常慢识别重复最新完整显示bundle；不把HDMI60Hz写成识别60fps。边界：已proposed段遇功能reset，照旧保留payload与引用至可信排空；预算不得把reset后的这些槽全扣为0。

## C. 所有者、连接与检查点

CAMERA/FE或reader→Canny/RC→完整结果→FM→DISPLAY；所有DDR请求经DS，PL独立维护运输/保持与恢复。预算连接不新建业务端口：

| IF | 交接/所有者 | 检查 |
|---|---|---|
| RB-IF01 | 各模块→统一容器表，字段N×bit/bank/时钟/owner/生存期/原SHA | 每一唯一物理槽一行；语义借用与物理copy分开。 |
| RB-IF02 | PL↔CAMERA/DISPLAY/CONTROL/DS，mailbox/FIFO/镜像 | 源body共享既有业务槽时只计该槽；接收私有copy仍计一次；ACK运输与业务归还不同。 |
| RB-IF03 | DS↔各MC client，R/W池/record/held/pending/terminal/release | 正常消息可由同一pinned record重建；坏body回显不能从可信对象重建；无pending第三槽。 |
| RB-IF04 | DS/DP/CAM/RC↔服务/工作量预算 | 机会数与周期分别核；无实际IP有限响应界时不形成deadline保证。 |

整体检查点已在本轮向用户说明：资料已找到，但225仅自写RAM；寄存器和扫描代价存在风险。以下给出具体数量及保留的未知；阶段仍是预算诊断与设计修订，不能称业务已经运行。
## D. 唯一物理存储与寄存器容器

### D1. RAM去重及外部IP边界

| 所有者/容器 | RAM10 | 同时存活与计算依据 |
|---|---:|---|
| 共享FRONTEND+Canny | 44 | FE8已在44内，Canny增量36；精确八邻接cache/队列/writer按原附件，不另加一套FE |
| DS | 17 | R段池7+W段池7+scope冷1+phase冷2；热grant/record/phase等FF没有藏入17 |
| RC | 105 | EXECUTION B0…102私有103+两ROM2；phase互斥复用已有池，VC/coverage/FINAL/row/STREAM/scatter各有明确锁 |
| 当前PL | 21 | 原30减被DISPLAY替代的PIX FIFO9；保留NORM FIFO20+AON mirror冷1 |
| CAMERA新增 | 13 | ROM1+RAW历史4+source banks4+FE副本队列4；PL FIFO20不重复加 |
| DISPLAY row | 21 | SRC18+EDGE1+ANN2，三row有效所有者；替代旧PIX9 |
| reader | 4 | DATA-JOIN独立DDR源输入bank；不借正在被camera写或显示读的bank |
| 已列自写小计 | **225** | 225/256=87.890625%，仅以上原语候选 |

器件剩31 RAM不是全部可花的空间。完整条件是225+新增控制存储+实际DDR/PHY/CSI/其它IP内部RAM≤256，且各端口/时钟/布局成立。旧DDR22仅条件比较：若本次相容端点恰需22，则247，剩9；CSI/serializer等仍非0/未知。未设置任意20%reserve，也未宣布31或9块已授权分配。

CAM两source bank各1024B/128个64bit word，共2048B有效payload；四条20×512物理容量40960bit=5120B，旧布局只使用各bank128word及64bit payload。物理空白/高16位零不能自动变成更多bank或延长服务期限。DP21物理215040bit，三完整mode5 row有效19440B；独立row权限/地址/pending仍按原稿。

### D2. DS可复核的容器表

| 原稿列明的FF容器 | bit算式 | 容器bit |
|---|---|---:|
| grant主体 | 32×241 | 7712 |
| 14方向record | 14×640 | 8960 |
| phase热记录 | 32×384 | 12288 |
| R/W纯数据holding | 14×128+2×128 | 2048 |
| 小计 | 上列相加 | **31008** |

这些是原稿容器分配，不是综合FF数，固定零/别名仍可能被实际实现消除。正常terminal301/release288/ACK293的共同身份由同一pinned record保存，不逐份相加。439有效bit内部候选按326身份+8 phase/pool slot+36五项live数量+11准备/state+14原RESP定位+16冻结terminal+9release/ACK+13承诺/引用flags+6局部borrow/pending构成；640中201固定零不宣称实体FF。冻结terminal actual与后续live actual必须分开，Q通知不可回写。

| DS尚未实分配的有限候选 | 容器bit | 为什么不能漏计 |
|---|---:|---|
| scope shadow16×688 | 11008 | generation、closed-phase28、grant/phase mask、refs、四64计数、cancel、Q及close seq；不能丢失暖复位承诺 |
| grant热状态32×93 | 2976 | refs、return seq、valid/stop/Q/ACK |
| R/W holding旁带 | 202 | index/last/error/valid/预约，不把pending当第三槽 |
| 池目录16×16 | 256 | state/owner/length/borrow |
| 两RAM pending | 64 | RE已经预约就必须capture |
| R/W物理owner | 64 | owner结束与client record回收不同 |
| cold staging/查询各640 | 1280 | 全快照后串行访问，held query保持 |
| phase证书 | 410 | 独立于普通数据/fence，pin不能形成自等 |
| 普通控制reply | 704 | 最大697回显+type/source/valid |
| 14坏prepare回显271 | 3794 | 无法从可信record重建来件，合法消息可共享原record |
| 14非匹配release原body288 | 4032 | 不靠坏身份释放别人的record；有限错误回复仍须保存 |
| 明确有限控制 | 256 | seq/预算69+RR22+扫描23+范围99+cold目的19+flag24 |

按原640/384容器上界计，上两表合56054bit。若另选择每record六项64bit饱和等待计数及overflow、八项全局计数，另14×6×65+8×65=5980，候选62034bit；这项诊断选择尚未冻结，不能悄悄算成已实现或随意删掉质量/错误记录。DS-IF08的具体观察项须在联合版本选定。DATA条件峰值scope11/grant25/phase20不改变原固定容量16/32/32及generation保存义务。

### D3. PL自身容器和边界去重

| PL有限候选 | bit | 所有权/保留条件 |
|---|---:|---|
| 12远端health双端快照24×147 | 3528 | 每域独立ACK；失钟旧消息不覆盖 |
| reset AON接纳及receipt/done双端 | 609 | CONTROL源117由CONTROL计；CORE接收reply只计一个实际槽 |
| mirror安装/回复2×694 | 1388 | AON原body/reply共槽、CORE接收另槽；FM不再加另一相同接收copy |
| fault/manifest/entry双端 | 1962 | entry引用稳定cold，不改held body |
| live fault | 136 | 不回写旧通知 |
| PREPARE/FINAL及done双端 | 6488 | 4×808+4×814；DS借同一接收body则不再复制计 |
| 16镜像shadow256 | 4096 | generation/token、mask、evidence、cold borrow、结果；scope623 cold仍在mirror RAM |
| SUP有限控制 | 414 | epoch/seq、资格/同步、计时/游标/mask |
| mirror读pending/capture | 112 | 旧RE必捕获与归还 |
| CAMERA FIFO运输附加，当前NORM192 | 619 | 旧189两holding382→当前388，加6；已核为CAM CA2同一capture槽，只计一次 |
| 24条PL自有mailbox运输控制80 | 1920 | session64+toggle/同步8+valid2+close6，不重复业务body |
| 当前候选小计 | **21272** | 原PL候选21266因NORM192增加6；未证明全路由目录最终完整 |

PL的这两个NORM192捕获槽与CAM CA2明确是同一pixel→core FIFO读端预约/capture，归PL619，不再在CAM增加384bit；独立end_pair114、oddRAW10、RAWPAIR输出114和pixel侧normalizer staging不能因此合并。CAMERA/DISPLAY/CONTROL的typed业务消息由各自模块计，PL只补运输状态与自有接收槽。来源held body若借同一稳定业务对象到运输保存确认，不能再加一次同宽源副本；接收私有完整body仍必须计。AON mirror冷只保存scope623封装640，open/close token在shadow；不能错把完整688安装消息×16再塞入一个512×20 RAM。当前新增候选量不是实际综合结果。
### D4. FE/Canny/CAMERA/DISPLAY有限候选

以下来自实际父稿/附件和明确的有限结构提议。候选填补旧稿未实分配字段，不把它写成现有源码资源报告或不可避免的最小值。

| 容器组 | 候选bit | 依据/边界 |
|---|---:|---|
| FE共享核 | 2978 | F0控制200+F1 254+两个F2各328+median1130+Sobel738 |
| Canny增量流路径 | 3051 | Gaussian485+Sobel窗口328/算术640+direction812+fork98+NMS560/比较128 |
| Canny SC | 2468 | metadata/共用512 linebuf/word等2268+op137+result30+pending21+FSM12 |
| Canny queue | 1103 | 数据447+双bank254+carry/meta23+prefetch115+局部264 |
| Canny C0 | 3984 | ctx1362+FS/feed416+五producer475+phase544+计数281+控制197+abort101+Q512+恢复96 |
| Canny seed/closure/export | 197 | scanner及partial pair gather |
| Canny顺序writer | 1375 | 两W128共256+六bank metadata540+三阶段计数315+局部264 |
| Canny集中MC | 784 | R/W各392，固定身份330+62结果/进度/owner/借用/ACK |
| Canny增量/含FE | **12962/15940** | 不再把FE2978叠加于15940 |

C0 job917一次，scope中已在job的J486引用原ctx，另存额外137；四grant共同scope/descriptor引用ctx，另308，因此1362。Q512是可容纳344bit冻结计数（8×22+5×21+3×21）及168bit诊断/标志的预算候选，当前最终Canny status未完全冻结，不能写成已接受编码。SC WB/FILL分时用同一512 linebuf；queue的独立W128不能与顺序writer两W128合并，SC/queue各自R接纳与DS两R128亦是不同端点。CLASS/GRAD/EDGE、queue、SC使用同一集中W record，queue/SC用同一R record；实际借用未关不可换owner。

| CAMERA容器组 | 候选bit | 依据/边界 |
|---|---:|---|
| CA0配置/事务/观察/计时 | 1444 | 本地有限控制候选，实际I2C IP内部另计 |
| CA1 ARM/GATE/观察/入口/关闭 | 2645 | 四NORM192 staging为适配候选；实际IP同沿事件数量仍需证据 |
| CA2 parser/endpair/odd/pending | 763 | 不再加PL共用两NORM192；独立RAWPAIR/end114/odd10仍留 |
| CA3数据/window/流水/控制 | 972 | 数据632+sideband/pending控制 |
| CA4双bank/W/append/MC | 1450 | append112、W2×128在此；含一个392 MC |
| CA5 LIVE/FJ/FS/FP/queue控制 | 955 | RAM queue不再复制；两个FP74独立holding |
| CA6六ctx及分配/abort | 10676 | 6×1751+170；lease1048、live121/Q121、token/水位416、状态/ACK45 |
| 小计 | **18905** | 实际CSI/I2C内部、完整联合映射仍非0/未知 |

status808可引用lease中的scope623/config64及冻结121诊断，不再六份808；六ctx不是六套Debayer。CA1四staging不能先验承诺承接真实受保护CSI同时发生的payload/错误/边界，实际合同仍RB-B02。

DISPLAY候选22513：CORE三(OFFER1963+热/冻结472)=7305；PIX三(投影952+热64)及一full-OFFER接收槽1963=5011；双端三ROW目录/状态2454；数据/渲染1438；取数metadata/MC641；sideband/adapter422；双端current_exec1013/future_plan522及一个pending intent262=3332；closing318/APPLIED固定引用282；policy/anchor640、诊断384、pending110、fault80、恢复96。
PIX952投影保存scope623/offer64/cfg64/rendergen64/W-H22/mask3/render112，属于内部预算选择；APPLIED固定旧/新ctx引用及scan/render133每端、pin到ACK消费。三ctx已包含最多两个RETIRING，不另加“两退休ctx”。共同CJ stage/SNAPSHOT body不在本小计重复加；最终encoder/serializer内部仍未知。

FE/Canny含共享FE、CAMERA与DISPLAY三个执行候选小计57358bit；**不将它与DS/PL/控制的候选总数无条件相加成全机实用FF。** 尚有共同ctx、消息双端槽、输入编码/constant trimming、跨phase共享和真实DSP/外围FF归属需要唯一容器映射。当前容量压力已被明确发现，但完整FF/XLR预算尚未闭合。

### D5. FM/CONTROL/JOIN与共同消息

FRAME-MANAGER仍是六source/三result/一个PROCESS workspace，CONTROL有限UI请求与R操作，CONTROL-JOIN固定阶段/配置锚，DATA-JOIN固定身份、借用和三级关闭。该组没有已明确新增RAM分配，不能把宽消息/计数藏在RC/DS或PL剩余空间；同core共享ctx与跨域接收副本须逐一落到唯一容器。

一组按全宽消息容器直接使用FF的诊断示例：DS31008+RC29168=60176；再CJ result C1713、FM T/R原body组5642、普通P/reply1787、stage/snapshot原body每侧4546（FM/DP两侧9092）得78410；再UI四body532、发送/CORE私有接收266、reply双端548、event_seq64、AON reset三body363、六SourceOrigin1170、camera cfg384，得81737bit。**这不是81737的不可避免FF下界，也不是全机已去重总数。** ACK前缀、stage发送/persistent anchor及PL reset接收槽可能是同一物理容器；跨stage/相同source的重复身份可能引用pinned canonical对象，必须证明生存期及回显正确才扣。这里不再与D3/D4候选总数相加。

| 该方向提出的有限内部候选 | bit | 共享/未知边界 |
|---|---:|---|
| FM六source记录6×1337 | 8022 | scope623含J可投影Origin；另camera cfg/ARM/link/grant/phase/非scope状态和关闭token；不是新复制六Origin |
| FM三result记录3×2037 | 6111 | J486、C570+valid、header/offer/grantH及状态/诊断/token；render/Origin从稳定记录投影 |
| PROCESS/workspace/五borrow | 268+89+420 | 身份及持久allocator独立；五role各84保持自身归还义务，role0只用FE RETURN |
| last-complete比较缓存与控制 | 3094+28 | T/R旧body各一次，receipt/done借前缀；不从当前C重建旧reply、不复制第二4731 |
| 生命周期控制 | 512 | 两组256，包括序号/策略/分支/引用/flags |
| reader FF | 2325 | 两bank metadata/384 Rrecord/301终态/155 R/carry/FP/pending/有限控制；不复制DS段池 |
| CONTROL基础/AON与D | 1617+359 | 真实四UI槽与reset独立；与PL同一reply接收槽须去重 |
| 观察live/held候选 | 4061/6327 | live投影和atomic held真正复制分开，32种计数等尚待最终字段冻结 |

以上候选还不是一致的物理分配。该方向的DS scope-shadow16×256与grant-shadow32×128，和D2完整DS owner方案688/93不是同一字段集合；本稿保留D2方案作完整项检查，不取两者最小值，也不把两组相加。DATA_CONTROL原body展开5591bit/端点组及DP ROW原消息4110bit/侧也只作消息宽度清单，不再叠加于已分配的record/ctx/目录。Canny最终packed终态和观察位表未冻结；给512或2048bit容器余量不能替代字段和所有权证明。

尚须映射的实体是：每source/result当前与冻结错误状态、完整scope/C/Origin/lease实体与短引用、RETIRING/PROCESS/冻结hold、UI各独立seq及ACK/accepted/application阶段、控制锚/比较缓存、START/LOCAL/phase/fence/return关闭证据、同沿握手计账、Q通知与后续live恢复、AON mirror引用。未知字段不是0，也不按一个未定义百分比补齐。当前父稿中消息宽度和容量本身不能证明这些组合能直接译成FF；RB-B01必须在联合物理布局中关闭。

## E. 中文预算、服务与优化操作草图

### E1. RB-OP01：从整体入口确认唯一容器

先按CAM/reader→共享FE/Canny/RC→FM/DP列实际同时存活的对象；逐项读取原文数量、宽度、原语及关闭事件，再分成实际来源事实、候选上界、尚未分配的字段。RAM按物理bank ID合并；FF按真正存放body的槽合并，不能仅因两个消息值相同就相减。同一时刻有旧terminal快照和继续变化的计数，要留下两份不同事实。失钟/Q/功能reset期间的承诺继续占容量。记录输入SHA及推导，然后更新本稿/索引；不写正式硬件或数据库状态。

### E2. RB-OP02：审查共享与热冷映射

每个拟扣的副本先说明谁保存唯一canonical body、读者如何pin、外部held payload如何稳定、RAM读pending如何预约、何时可以释放/改代次。正常ACK共前缀可引用已pin原对象；错body回显须保存来件，不能引用它没有权限改变的对象。phase切换、功能reset、旧ACK迟到及AON失钟都纳入寿命交集。

一个可计算的比较是grant32×241每条13个native20 word，共416word，可装1 RAM；phase热32×384每条20word，共640word，需2 RAM；scope16×623每条32word，共512word，已由DS scope冷RAM承载。**这是映射比较，尚未选定替代结构。** grant/phase热若独立移入新增RAM，表面省20000bit寄存器但新增3RAM及lookup/cache/pending，已有scope冷1不再加一次，已有phase冷2与新phase热2也不能假称同一表。合并cold/hot还须比较重叠字段与live更新，不直接用逻辑bit总数除10240。

RAM同步RE后下一沿capture，输出完整body可能需多word组装；这个等待会影响prepare资格、DP行填充和关闭响应。不能为节省FF引入无界等待、payload中途变化或fence自等。全机唯一容器ID、完整路由和热冷布局尚RB-B01；本稿不凭此比较宣称全机装得下。

### E3. RB-OP03：核算采集与显示的期限

先固定实际相机PPC/包模式/clock、RGB有效pair速率及DDR段链，再算非暂停入口的最大backlog。camera源bank只提供2×1024B有效源payload；NORM FIFO1024个record还含控制/错误事件，不能全算4096个有效RAW样本。50MHz名义payload时，PPC1/2/4的RAW峰为50/100/200Msamples/s，对应RGB等效150/300/600MB/s；单1024B等效间隔6.8267/3.4133/1.7067µs，两bank容量对应13.6533/6.8267/3.4133µs。**这些是条件峰值比较，不是实际相机fps或可吸收服务空窗的保证。** RAW/encoder流水、carry、FIFO控制记录和关闭延迟要实际一起计。

显示生产每row14.8148148µs，mode5 SRC5760+EDGE240+ANN480=6480B/405个128bit R拍；每秒419.904MB。原顺序基本组装RGB960+EDGE96+ANN192=1248core机会，即100MHz理想12.48µs，只有2.3348148µs名义余量供额外等待。三row提供预取lead，不能弥补长期产出低于扫描需求；row bank归还必须包含旧RE/pending/holding而不等整scope fence。607.407µs首active前空白只能预算，不能当已测保障。

若相机恰60fps，完整RGB源平均373.248MB/s，加mode5显示为793.152MB/s，尚未含FE结果、Canny、RC或其它DDR访问。128bit×100MHz=1.6GB/s只是无stall理想峰；未知refresh/turnaround/AR/AW/R/B等待、client终态/归还及CDC下，平均占比不能证明deadline。

DS prepare/req14叶及各7角色RR保证的是持续eligible的接受/选择机会。实际服务还需T_residual及每turn有限界；七角色物理结束条件界T_residual+7T_turn不涵盖无界client ready、W收集、逻辑R消费、terminal/release、fence及CDC。先为相机bank/FIFO、DP next/current/candidate和六source EOF→FREE分别列服务曲线与最迟释放事件，再核新SOF分配前至少一个沿已有FREE。没有真实IP有限界，RB-B02/03保持；不能以增加bank、降fps或safe图案悄悄通过原需求。

### E4. RB-OP04：核算识别工作量并排序优化

生产N=2073600，E≤N。以下来自已经冻结的候选循环界，不是实测，也不是整机所有操作的完整界；多项最大条件不必在同一输入同时达到。

| 候选工作 | POINT访问/组 | 数据byte或core机会 |
|---|---:|---:|
| 圆P1 86272E | 178893619200次 | 1431148953600B |
| 矩形P2 32E+14LE+6SE+VE，L/S1024、V4096 | 51027148800次 | 408217190400B |
| P3核验/精确去重2QE，Q2048 | 8493465600次 | 67947724800B |
| DENSE三沿，32E组 | 66355200组 | 199065600core机会 |

把三项byte界相加得1907313868800B；除1.6GB/s为1192.071168s，只表示这些上界对应的理想传输成本尺度，**不是实际单帧时长、实测最坏值或可达fps**。单DENSE按原三沿和100MHz理想为1.990656s，还未加清零、等待、拟合、核验和输出；不能称现算法实时。

优化顺序：先解决完整热状态与消息存储，再使显示plane填充与源非暂停链有可靠服务预算，然后减少识别重复搬运/重复计算。可比较多个已经冻结membership的候选共享一次POINT流、缓存不可变θ/投影或tile内数据、独立plane准备与写入重叠；但冻结成员的A/B/C/D/E及TLS多遍依赖顺序保持，不能用新几何重新选择旧遍成员。完整POINTS最大16588800B，远大于全部片上RAM的327680B，因此不能提出“全部点留片上”而漏算存储。

候选批处理会增加统计/geometry状态、算术并行与端口需求；须同一预算表比较增加量、DDR减少量、100MHz可达性和独立质量，再选择。未形成该结构的逐沿/生存期证据前，不自行修改旧算法或产生代码。性能最大化不能由资源百分比单独决定；资源有效用于缩短已识别瓶颈，保留诊断与严格失败计账。

### E5. RB-OP05：保留数值/质量和关闭的验收路径

优化比较先固定原profile/源/geometry/point顺序与类别匹配规则，所有capacity/算术/协议失败及代表抽样漏检都纳入评分。圆/矩形分别同类IoU≥0.5一对一，P/R各≥95%；开发分布与最终独立分布分开冻结，不能删坏帧达标。用户撤回的尺寸96–768、长宽比3、最多4目标、20%遮挡及噪声/对比界仍只是比较轴。

取消/功能reset时，已提出段保持并关闭，旧RAM pending必capture到预留目的或可信DISCARD，terminal快照不变；只有ACK消费、physical/local/semantic borrow全关才回收。优化热冷共享不能以清valid代替这些义务。数值模型、协议模型、器件PHY及真实布局分别验证；正常零目标与失败无结果分开。

## F. 语言、映射和RTL A–L

本稿没有C++/Python/RTL实现。未来独立参考只在指定范围获批后生成；既有Python/Questa/Efinity候选环境不等于本次已运行。软件整数模型显式模拟位宽/RNE/floor，独立GT评分另做；预算只读算术使用的整数量均在精确整数范围内。

| RTL项目 | 本稿检查/保留契约 |
|---|---|
| A 数值 | 完整field/signed/高位零与原宽乘法保留；bit容器、native word和物理块不混单位。 |
| B 时钟 | 各domain独立容量；core100MHz为候选；RE沿后更新、下沿capture；工具STA未执行。 |
| C 接受 | valid/ready按旧资格fire；pending先预约；CSI/scan无ready不能借下游stall停住。 |
| D valid | invalid body不推进数据量；合法零/无目标不是无效或失败；热域不因气泡释放ctx。 |
| E 保持 | 旧payload/身份/terminal/ACK和借用照合同保留；源共享和接收copy分别算。 |
| F 时间 | 机会/理论峰/条件周期/实测四层分开；无IP最坏界不写固定deadline。 |
| G 复位 | 功能停止不清承诺账本；Q、AON镜像和恢复旧代次占容量直到真实关闭。 |
| H 配置 | accepted C/profile/Origin固定；不按可变当前配置重构旧消息。 |
| I 存储 | 固定bank/端口/宽深；原始RAM空白不自动扩大容量；同址/双clock合同仍需验证。 |
| J 身份 | 完整外部key与内部短引用可分开存，但generation/ctx pin/fullbody相等条件不能删。 |
| K CDC | 原子mailbox/Gray/session/运输关闭与业务关闭都计；不逐位同步拼多bit包。 |
| L 实现 | Ti60F225/I3候选、256RAM10/160物理DSP/4PLL；FF/LUT/ADD/SRL packing待实际报告。 |

DENSE32个12×17乘法是32个DSP48推断候选；共享scalar的144个16×16部分积是串行步骤，不能当144物理DSP。scalar具体原语/寄存器、其它模块DSP及clock/enable/reset相容性须核；不能报全机33/160。FFbit与LUT/ADD/SRL可能共XLR，不能相加形成利用率，也不以62016代替工具60800逻辑预算。输出寄存器/专用外围或DSP内寄存器须依实际归属记录，禁止把每个概念bit都强行映射XLR。

共同数值契约是冻结原算法及整数门；硬件执行契约是fire/RE/pending/commit/关闭与时钟域；软件结果对应同job/C/Origin/record/像素事务和完整失败计账。统计性能与资源时同时保存有效输出、拒绝、跳帧和QoS空窗；只比较幸存输出不能证明优化满足原目标。

## G. 实施及验证计划（全部NOT_RUN）

本稿不会生成可执行资源统计脚本、参考或TB。获批后的实现按统一版本推进，先核生成IP与canonical热冷布局，再基础处理/MC/控制/显示，最后完整Canny/识别及系统验证；工具许可、真实模型与工作副本审批按原制度。为预算新增的探索实现也需对应指定批准。

| TEST | 目标 | 场景与期望 | 执行状态 |
|---|---|---|---|
| RB-T01 | REQ01/02、IF01 | 共享FE与旧PIX替换只计一次，RAM表225；外部IP单列 | NOT_RUN |
| RB-T02 | REQ03、IF02/03 | 合法ACK复用pinned前缀，坏prepare/release独立保存回显；无重写/非法释放 | NOT_RUN |
| RB-T03 | REQ03、OP02 | 热冷lookup停顿/phase切换/ACK迟到；body稳定，旧pin保留，RE有预留 | NOT_RUN |
| RB-T04 | REQ03、IF02 | NORM192与PL transport同一/分离槽按实际拓扑核对；24link目录完整 | NOT_RUN |
| RB-T05 | REQ04、OP03 | mode5每row及next/candidate竞争、refresh/方向切换/坏响应；所选服务界内无欠载 | NOT_RUN |
| RB-T06 | REQ04、OP03 | 非暂停相机PPC/packet峰、两bank/FIFO满、六槽EOF尾→下SOF；无隐丢/提前回收 | NOT_RUN |
| RB-T07 | REQ03/04、OP05 | 功能reset/失钟/Q/恢复时全旧holding和镜像占容量，只有可信关闭后复用 | NOT_RUN |
| RB-T08 | REQ05、OP04/05 | 同一开发输入比较批处理/缓存；冻结成员和记录逐bit一致，独立质量包含全部失败 | NOT_RUN |
| RB-T09 | REQ01/02/06、F | 实际map/place/PNR/STA的FF/LUT/ADD/SRL/RAM/DSP、时钟/pin/例外及bit哈希均有证据 | NOT_RUN |

文字正常/边界走查已在B/E完成；上表是未来工具场景，不把它写成已执行测试。旧各父稿场景保留，测试资源小计不代替整机质量/时序。

## H. 双向追踪

| 要求 | 所有者 | IF/操作 | 未来实现位置（未生成） | 验证 |
|---|---|---|---|---|
| RB-REQ01 | PL/全部模块 | IF01、D/A/F | 统一工程/IP原语及报告登记 | T01/T09 |
| RB-REQ02 | Canny/RC/DS/PL/CAM/DP/reader | IF01、D1、OP01/02 | 各实际唯一bank与热冷布局 | T01/T03/T09 |
| RB-REQ03 | DS/PL/FM/CAM/DP/CONTROL | IF02/03、D2…D5、OP02/05 | canonical ctx、消息/pending/恢复保持 | T02/T03/T04/T07 |
| RB-REQ04 | DS/CAM/FM/DP | IF04、OP03 | 仲裁、bank/row/FIFO与监视 | T05/T06/T07 |
| RB-REQ05 | RC/DP | OP04/05、F | 批处理/数值/独立评分与计时 | T08/T09 |
| RB-REQ06 | 全机控制面 | A/I/J/K | 指定批准后工作副本与证据 | T09 |

反向要求：每个未来资源优化的符号须返回上述原要求、父接口与关闭保证；不能用临时空泛“省资源”合理化删身份/错误/质量。实际代码栏当前全为未生成。

## I. 设计门槛

B/C整体结论、D唯一容器和有限候选、E中文草图、F契约、G/H计划与追踪已提供；保存读回和文档检查另记录。**RB-B01…04仍阻塞整机业务READY；本稿不是实现批准对象。**完整预算不能以未知IP=0或未证明共享扣减假闭合，也不把未获批准的测试/综合要求作先生成代码的循环门槛。既有FRONTEND v1/FE-BL-v1和DDR模型申请仍PENDING，本稿不重复索取。

## J. 发现、差异和恢复

原225只是自写RAM；本稿明确外部IP遗漏风险、31008 DS列明FF候选、29168 RC局部候选、PL全宽消息候选与控制/相机/显示未闭合。原热状态和全宽消息直接翻译成FF会产生明显容量压力；需要canonical引用及热冷结构选择，不据此宣称器件必然无法实现全部需求。

PL旧NORM189的两holding按CAM192多6bit；这项相邻稿已有明确变化在本稿统一计，不改原文件。冷scope/grant/phase RAM映射只是比较；显示plane重叠/识别批处理只是优化入口，尚未选定新行为或重要结构版本。外部消息位序/错误码、固定容量、用户边界与精确数学保证继续保留。未来若采用这些结构，须在同一联合版本说明原J覆盖、逐沿/所有权/接口差异与复核，然后取得指定批准；不继续堆同类文档冒充工具证据。

[执行阶段历史审计](../experiments/track4_full_sw_20261004/05_reviews/document-checks-recognition-execution-v0.1.json)保留实际8BC7140AF4295A7F898304F2DDDAAA3C15FEC503C6AAB0EEBC4B9BCA8DA7A953原字节（124995B），含最终F664执行主稿和8279917D读审。当前文档审计更新，原始资料及正式状态不变。

## K. 实录

本轮实际读取/哈希原稿、官方本地资料与Demo历史报告；三个只读方向分别核FE/Canny/CAM/DP、DS/PL、FM/CONTROL/JOIN，root合并数量、别名边界及服务/工作量。静态算术和文档检查记录在当前05，实际保存读回另外核验。旧报告只是历史source，当前仿真/综合/PNR/STA/pin/bit/hex一律NOT_RUN；未联网、下载、安装、数据库写入或硬件操作。

## L. 阅读与交付边界

先B/C看结论→D查RAM/FF/唯一槽及未知→E读容量、期限、优化和取消中文草图→F看单位/数值/时间→G/H看验证及双向追踪→I/J看阻塞和候选差异；再回各父稿局部细节。本稿交付整机预算诊断，完整软件尚未交付，人工理解未验收。实际代码、工具资源/时序和质量证据要在批准后分别补齐，不能用设计文件数量替代它们。
