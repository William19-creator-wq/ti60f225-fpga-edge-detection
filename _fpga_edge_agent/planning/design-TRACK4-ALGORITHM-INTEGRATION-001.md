# TRACK4-ALGORITHM-INTEGRATION-001：五类剩余工作的整包组合设计 v0.8

2026-10-04；GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / 整包业务NOT_RUN。本稿统筹最新五类工作，引用现行局部合同；有限IP预检已获指定批准并有A2的实际结果，但未取得整包实施批准或完成十一功能。

## 通用计划字段

- Goal：完整推进板卡现有DDR3存储/通信、性能资源、生产输入输出、整包统一，以及获批后的实现/软件验证至bit。
- Current state：R1至R4、CONTROL/REPLAY/VIEW和RAW候选已存在；SLOT-JOIN/PROFILE-SOURCE补六不可变源、三结果与完整PROFILE实体；PRODUCTION-BUFFER采用独立五ring与有界IMPORT。本v0.8接入ROW v0.2及SCAN v0.2：行解包/预取/数学/写入的有限沿表，提前exec、四完整scan ctx与真实物理采用分离；ARM/Q/DISPOSE/下级epoch ACK文字修订已有有限复核。C2原参考在当前Efinity综合PASS，仍无本次算法代码或完整构建产物。
- Target state：明确实际可实现结构、完整接口和局部草图、共同文件/质量/验证基线后统一提交指定版本批准；随后在work连续实现和真实运行。
- Gap：原不可变对象/工作区84.25MiB加五采集ring40MiB为124.25MiB容量候选；六SRC与五ring不同namespace、三结果及两物理视频bundle保持。完整目录/消息、真实DDR资格与连续服务、全部片上资源及文件/质量基线仍未闭合；旧单slot及原六SRC承担全部采集的合同不能直接接线。
- Assumptions：生产1920×1080，完整八邻域Canny，圆/任意旋转矩形及原质量评价保持；Ti60F225/I3、SC431HAI彩色为软件目标；实体未到货。
- Open questions：用户先回答“必须只用板卡现有资源”，随后明确回答“允许使用板卡现有 DDR3”；DDR排除限制已撤销，无新增模块，PC仅仿真/参考/观察。真实DDR服务、全机资源和完整局部合同仍待证明。
- Dependencies：唯一根v0.2、PLAN_TEMPLATE、A节局部候选及原控制面审批；仅IP-PRECHECK v1/v1.1/v1.2取得控制面本地审计例外及Manifest范围记录，不适用于本整包实施。
- Milestones / Detailed steps：实际资源差距→存储结构→全机同时寿命/时限→生产IO/CDC→本稿接口/文件/参考/场景统一→完整复审→READY→指定批准→work实现→仿真→综合/PT/PNR/STA→bit/登记停止。
- State transitions：只记录本稿设计状态，不改原PROJECT_STATE/TASK_LEDGER/数据库状态。
- Artifacts and hashes：当前候选来源见A；未来实际共同manifest须包含所有源/设计/工具/IP/pin/输入/schema版本和摘要。
- Validation：文档、数值/协议、功能仿真、综合网表/时序、bit、实机分别计；整包仍NOT_RUN，有限C2综合PASS/Questa编译FAIL与其PNR/STA未执行见A2。
- Failure handling：真实硬件/带宽缺口保留；wrong echo、未完成原子组、未退休引用或部分帧不伪成功；软件失败不通过缩图、限制场景或裁剪功能隐藏。
- Human approval gates：满足规范10.3后才提交成熟版本集合；本轮五类工作请求支持设计推进，尚未构成对未完成版本的批准；point5仍明确是获批后的实现。
- Rollback：仅新增本稿及本轮记录，原HDK只读、旧局部保留；降标稿仍WITHDRAWN_BY_USER。
- Completion criteria：本五类完成须有真实完整范围的代码、功能和工具证据；bit后停止。DDR A3恢复为当前设计依赖，尚未实现/通过；正式任务表和数据库尚未改写。

## A. 最新范围与候选版本

用户要求完成剩下五类。此前160×120、单目标、1处理帧/s提案已明确撤回：[历史降标稿](design-TRACK4-BRAM-FEASIBILITY-001.md)，不纳入任何当前指标、接口或实施基线。用户在设计边界询问中先明确回答“必须只用板卡现有资源”，随后指出0927更新包的ddr3_controller，并在明确询问是否撤销DDR排除限制后回答“允许使用板卡现有 DDR3”。本v0.2据此恢复板载DDR3设计工作；外接存储仍不在允许路线，PC64MiB arena仅为仿真/参考/低速观察，不能替代板上生产存储。批准设计边界不等于批准具体实施版本。

原[整包v0.3](design-TRACK4-ALGORITHM-BATCH-001.md)统筹原十一项及批准边界；本稿是最新组合附件，尚未回写其关闭状态。原A3 DEFERRED_BY_USER属于此前用户边界，已被本轮明确回复撤销；本稿记录为ACTIVE_DESIGN_DEPENDENCY，不冒充正式表/Manifest/数据库已更新。显示60Hz、采集fps、算法处理fps、外部通信耗时分别报告，不重新设1fps验收。原[本稿v0.1快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.1.md)绑定2FF14093EF8E75BA56280D95DAAEF0F6C78505920204B617A1B0356B41252B52、26235B，保存当时无DDR边界。

本轮实际核对的候选来源（均未获整包实施批准）：

| 来源 | 实际SHA256 | 本稿采用范围 |
|---|---|---|
| [R1 v1](design-TRACK4-ALGORITHM-R1-001.md) | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 | 固定点灰度/中值/Sobel与原FE计划；局部READY不等整包READY |
| [R2 v0.3](design-TRACK4-ALGORITHM-R2-001.md) | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | C0唯一FE owner、Gaussian/梯度/NMS/class/GRAD、CS592 |
| [R2 FILES v0.1](design-TRACK4-ALGORITHM-R2-FILES-001.md) | E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842 | 21计划文件/10TB与独立数值/向量职责；不是全包清单 |
| [R3 v0.2](design-TRACK4-ALGORITHM-R3-001.md) | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D | NUM_ID176、REQ622/RESP585、全部typed数值/ROM |
| [闭包 v0.2](design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 | 完整BFS、LOAD/CLOSURE角色化身份及全N EDGE |
| [识别 v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md) | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 全POINT/LS/TLS/核验/去重/ANN/RECORD和真close |
| [CONTROL v0.2](design-TRACK4-ALGORITHM-CONTROL-001.md) | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | CFG/P/C/J/V/手势/RESET唯一owner；新桥扩展尚未合并 |
| [REPLAY v0.2](design-TRACK4-ALGORITHM-REPLAY-001.md) | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | PLAN/三provider/真实JOIN/OUT/RT/CLOSE/RELEASE |
| [VIEW桥 v0.2](design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md) | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | CERT schema2、prejob revoke/return、PLAN_EXIT/QUIET/epoch授权 |
| [RAW v0.2](design-TRACK4-ALGORITHM-RAW-STORE-001.md) | 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD | 原v0.1全文读取并按94F0327B快照保留；v0.2修订reset/journal反例并经独立最终复核；PC实现候选只供仿真/观察，迁移板载DDR须新backend合同 |
| [R5结构选项](../experiments/track4_algorithms_20261004/03_review/r5-implementation-architecture-options-v0.1.md) | 22B7BEBAAB6B8DC2661F74DB95B3054BF72069B4A72F826949369D08A70FD7D9 | 根本轮实际1–257全文读取；C仅core候选、D生产硬件未知，不把外部数组当片上RAM |
| [PERFORMANCE v0.2](design-TRACK4-ALGORITHM-PERFORMANCE-001.md) | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 | 作者396行全文读回停止；根定向核D2–D5/E1/E2/E9及同hash协议复核，84.25MiB/HIST/DENSE条件候选，不称完整预算已冻结 |
| [PRODUCTION-IO v0.2](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | 冻结来源及PLL#4物理阻塞；源/结果容量由联合候选选择6/3，physical bundle上界2保留；scan身份/ctx/adapter预算由下行SCAN显式覆盖，完整生产实体未冻结 |
| [SLOT-JOIN v0.1](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | 六SRC/三结果/单scratch；21typed私有与三RECORD独立布局；SOURCE_OFFER182、信用/绑定/返还、AUX登记/返回及历史J候选；本文静态核查不代实现或整包READY |
| [PROFILE-SOURCE v0.1](design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md) | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | 一RAM10的八份完整PROFILE/真实安装与GET；逐lease源借用、独立PCTX65及冻结意图/实际应用；新SOURCE311/BIND1012等显式覆盖上行旧源族；精确门值、目录、COMMIT/CDC/采集服务仍OPEN |
| [PRODUCTION-BUFFER v0.1](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md) | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 | 六immutable SRC加五独立camera ring；单COPY分ALG/冻结补源目的；历史R_ROUTE/W_CTX；128beat/4KiB全拍候选；input18＋RX7独立于output15；服务/完整消息/全预算仍OPEN |
| [ROW-PIPELINE v0.2](design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md) | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8 | 两input/有界预取/四级数学/五lane写入，405拍/720逻辑写/2880 lane WE、960pair/2304word；局部条件最早e970 READY，40payload RAM非全机预算；接入提前exec而非未来物理frame |
| [SCAN-RESERVATION v0.2](design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | 四真实ctx/两future含closing、一次ARM_SET/独立STOP通知、exec与physical_seq分离；membership/持久pin/Q/epoch ACK修订有限复核，body/metadata30306与adapter638均下界；真实接线/期限/全预算OPEN |
| [更新HDK DDR证据](../experiments/track4_algorithms_20261004/03_review/ddr3-updated-hdk-evidence-v0.1.md) | F3492D3D4E7AB0B3B9247AD2A44859F0A52DCE282BC9D7F2A8CB0B8646F3E942 | 作者/根实际全文读回；原v1/更新v1/v6/v7控制器、256MiB几何、版本/报告/引脚及2Gb模型缺项范围 |

共享schema和计划文件不能只按以上摘要自动生成；各body字段仍以对应局部D/F为依据，增加桥扩展必须形成具体联合版本，不把旧主稿当已接受新端口。新增[RAW最终复核](../experiments/track4_algorithms_20261004/03_review/raw-store-review-v0.1.md)绑定7D08D9BB39393F6CD36975E7C64FF1BA9E7B7FCBB595BA7A1D7949FBF875FEE1、27364B，只关闭两项明确文字协议反例，不升级生产存储或整包READY。

SLOT-JOIN是新的候选组合入口：全局6SRC/3结果与单scratch已选定，PIO仅两物理bundle路由不扩大；三个历史J分别pin，RECORD不随private退休。其SJ-B01…05明确保留真实目录、profile、生产服务、完整资源与文件/schema冻结缺口。源槽128B PROFILE预留不自动成为CONTROL要求epoch内不可删的profile实体。旧v0.4精确快照保存在[before-slot-join](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.4-before-slot-join.md)，SHA256 9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3、36816B。

联合稿D2另补清预留事务结束与结果退休的不同事件：RETURN/ABORT真实成功且原ACK被J消费，或真实COMMIT成功且原R4接收方消费匹配REPLY232后，后续旧消息槽资格才允许给另一FREE结果槽提出信用。原COMPLETE结果仍占用自身实体/历史KEY；BIND_ACK不结束信用。J未花费KEY、当前BUILD KEY和O三份历史KEY分别保存，至少810bit payload另加held与状态；新信用可等旧J终态，但不能提前接新源。这是候选设计补充，实际目录与错误矩阵仍OPEN。

PROFILE-SOURCE是v0.6纳入的增量候选，原SRC内128B预留仍未授权为实体：完整PROFILE由O(owner1)内PROFILE_MANAGER管理，一个native20×512 RAM10存八份1024bit，每份52word，末word只有低4bit合法，其余高16为0；416word占8320bit，其余96word不授普通访问。安装完整封存后才分配真实资格，epoch内不可变，BOOT/GET互斥；GET e0读首字、e52捕获末字之后再核验形成完整回复。目录含独立持久seal64为1808bit，ref/seal及消息/cache另计，不是全机FF预算。旧catalogue排空后QUIESCED保留，授权START隔离旧实体后再BOOT，不能要求删旧profile/ref才能QUIET。

源借用以完整grant身份独立归还，BIND把同admission lease当前owner由J转O，不改原role或再加ref；一个bundle返SRC不销仍被其它持有者借用的注册base。PCTX65独立策略代次跟随当前J及三个O历史，T/R接纳前预留future generation，真实应用前独立阻新admission/发布。冻结取得VIDEO实际APPLIED snapshot；NO_ACTIVE/WAIT_FIRST若需从camera补源，按下述独立FREEZE_FALLBACK_IMPORT目的处理，RESUME独立收尾。OBS可单独延长旧源寿命；原3B/F/L/OBS满6拒第7CAP/ARM是改采集结构的实际反例，本v0.7不继续让camera依赖六SRC空槽。完整策略COMMIT、目录/cache、CDC及连续服务仍OPEN。

PRODUCTION-BUFFER是本v0.7增量。camera→独立五ring→按目的单IMPORT→六immutable SRC→原SOURCE311/算法或匹配FREEZE lease；长F/OBS/历史bundle只借immutable SRC，不长期pin循环ring。新ring追加[0x05440000,0x07C40000)，累计130285568B＝124.25MiB，128MiB arena尚余3.75MiB；原84.25MiB分区和PROFILE实体原字节保持。五ring容纳writer/closing/latest/COPY/future ARM五种条件角色，closing≤1、提前ARM及复用期限没有因此获得证明。真实capture origin/camera CFG/link必须进入工作签名，新source_id/copy_seq不代表新输入；原161bit签名需联合修订。

[纯数据算术](../experiments/track4_algorithms_20261004/01_baseline/production-service-arithmetic-v0.1.json)A560EABBB60E1B2998DE06A9929A80918E603462DBFA39056E2FAB565E3AF732/2261B与[实际来源/审阅](../experiments/track4_algorithms_20261004/03_review/production-buffer-review-v0.1.md)只提供静态地址/流量和有限反例证据。COPY每次读写合12441600B；mode5每行6480B＝405个16B拍，按128beat/4KiB拆分最多8burst，实际容器要720word写。新input两bank18RAM10、RX7RAM10共25payload块，原output三bank15独立，holding/目录/完整decoder另计。它们不是服务或全机资源通过。

### A1. 0927更新包核查与DDR恢复边界

实际来源根为D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新。10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1/rtl/ddr3_controller确有16份控制器/bridge/PHY/校准/RAM/FIFO文件；不是只存在名称或空目录。DDR参数头688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80、972B，给出bank3/row14/col10/DQ16、AXI ID4/address32/data128、tCK2500ps/CK_RATIO4/BL8。top 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A、58209B。参数几何推算2Gb=268,435,456B=256MiB；100MHz×16B AXI和400MHz DDR×双沿×2B均是1.6GB/s理论上限，不是持续有效带宽承诺。

更新v1与原赛题1~3包v1的controller16、XML/peri/SDC及历史STA/route/bit共22项hash相同。因此此前未知项应准确称匹配板上2Gb器件的仿真依赖、当前工具展开/功能/完整新增工程验证，不得再称控制器/PHY一概没有。该v1历史报告是2026-03-31、100MHz core/400MHz DDR，HDMI目标约140/700MHz；历史报告及bit存在不是新增十一功能或148.5MHz视频验证。更新包v7.rar的实际archive摘要9822ACA49F9D41F3948C814FE7527C69F53D1C03A232A9D28FBA42018CD084F4，项目为Ti60F225/I3/Efinity2026.1.132.1.2，实际74.25/148.5MHz与camera/HDMI/DDR组合由新生产稿核对。v7与旧v6设计来源差异必须逐项保存，不把另一IMX219 v7旁支混入SC431HAI。

单帧保守41,113,469B约39.21MiB，小于板载256MiB容量；这关闭的是原方案无法放入320KiB片上RAM的容量方向障碍，尚不证明多槽布局、片上缓存/FF/DSP、全工作集访问服务、帧期限或时序。DDR恢复还不自动消除旧REPLAY每pair至少3core沿的吞吐瓶颈；生产bulk预取与逐沿render、真实连续DISPLAY hold仍需新合同。板载DDR是当前生产候选，不使用PC内存或历史bit替代完整实现证据。

### A2. 当前工具的有限IP预检实测

用户已明确批准IP-PRECHECK v1/89输入/C0–C3及仅本次本地审计例外，随后批准v1.1/91补两个原I²C头文件、v1.2/92补原Panel初始化MEM。既有Manifest已追加三项范围记录，正式数据库/H0不变。批准快照和精确问答见[预检最终报告](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)。有限预检现为TERMINAL_WITH_FAILURES，各失败/停止可恢复；本批准不包含算法或bit/hex。

C2.original使用v6实际60引用、135输入；Efinity2026.1.132 map实际退出0。整参考资源为RAM10 85、DPRAM10 4、FF10840、LUT18363、ADD1591、SRL1164、DSP48 4。DDR父39RAM已含桥17，CSI父11，frame_buffer28、debug2；不能重复加父子，也不能把当前未观察/被优化metadata的CSI参考当完整生产NORM上界。没有C1/C3实测，不预判ASYN0节约。Questa15真实行为模型vlog退出0；C2实际DUT在CSI459保护区无解密key而退出2，vopt及功能仿真未执行。C2后134输入字节不变，只有case XML根工具元数据/格式更新；所有子元素语义相同，未升级保护IP。

C0初89/91两次遗漏保留真实失败；获批92的第三次map exit0，基础RAM10/DPRAM10为134/4，FF7414/LUT10773/ADD1698/SRL1134；官方保留USER2/4096/同探针合并后为156/4、FF8783/LUT12858/ADD2027/SRL1175。PT exit0有LVDS间距警告，PNR exit1在packer缺原USER1 TDI/TDO，placement未到达、route/STA未运行。原top与peri本来不匹配，不是此次格式迁移新造；当前不补空端口、删USER1或关debug。C0 Questa15真实厂商模型通过，67项DUT命令在CSI385保护区无key而失败，末项DSI未到达、vopt未执行。C1依赖C0跳过，另由现装官方资料确认Ti60 PLL#4固定regional，原固定#4→fabric gclk候选无效；换输出/分频/core来源须具体重设计，不暗换另PLL同频网。

C2外部byte频率不能由HS_BYTE70/core100证明，clock-corrected/PT/PNR/STA和C3仍按批准停止条件未执行。C0官方project/peri格式迁移经逐元素与生成pin审计，不改变90个其余输入或92个原源，protected IP未升级。有限预检work内bit/hex为0，正式状态/数据库不改；完整十一项仍未实现。PIO v0.2显式撤去无法落地的#4候选，新的物理core/时序/生产结构尚OPEN。

## B. 整体外部行为和五类关闭标准

| REQ | 可观察行为 | 完成所需直接证据 |
|---|---|---|
| INT-01 实际存储 | FPGA产生全部算法/原子组/目录/commit，板载DDR后端保存原始bytes；容量、权限、初始化、读写完成及关闭明确 | 实际可用接口/pin/资源/带宽合同、完整有限控制器设计、真实byte读回/故障/close验证 |
| INT-02 性能资源 | 全机同时存活的RAM10/FF/DSP/PLL、缓存和后端容量逐项计；每阶段真实等待和处理周期分开 | 闭合分配与最坏服务预算，获批后实际资源与STA/处理报告；不以资源填满当优化成功 |
| INT-03 生产IO | 实际SC431HAI配置/RAW/CSI→缓存→core→同帧完整RGB/EDGE/ANN→HDMI1920×1080@60Hz | 正确模式/LUT、pin电气/相关clock、CDC/reset、不可暂停到达与固定扫描容量/服务证明、完整软件工程 |
| INT-04 整包 | 明确各身份/数值族/owner与文件职责；独立oracle、文字场景、中文草图和双向关联统一 | 每个必需连接字段和生命周期相容，无重复writer/暗藏数组/未审lookup，具体基线及复审 |
| INT-05 实施 | 获完整设计批准后，在work生成真实代码/模型/TB/runner/工程/约束，运行至bit | 实际源码hash、命令/日志、功能/网表/PT/PNR/STA/bit；bit后不下载 |

正常算法路径：camera提前ARM→独立ring完整封存→ALG_IMPORT真实读写/返pin→注册immutable源→原SOURCE311/JOB锁完整CFG/PCTX→R2/LOAD先准备→全CLASS/GRAD真实commit→CLOSURE精确集合/全EDGE→RC全候选核验/ANN/RECORD→私有refs实际退休→CERT2完整bundle→VIEW联合父引用→完整行预取/渲染→固定视频采用→各层真实退休→下一帧或epoch。NO_ACTIVE冻结补源走独立目的并取得匹配F lease，不等待已关source gate/J信用/scratch、不造J；camera接收与算法未选分别统计。

失败路径：例如DENSE logical_commit后第二raw写失败，真实已提交事实和副作用保存，后续不发布成功图；独立raw关闭证明未知效果、typed局部close及目录退还，错误终态不等同取消收条。未知不回收引用，不靠reset消债。

## C. 唯一职责与完整数据/控制连接

| 组合组 | owner和保证 | 当前限制 |
|---|---|---|
| SOURCE/BOOTSTRAP | IMPORT后不可变RGB初始化覆盖/登记、逐lease及SOURCE311；PROFILE_MANAGER属O内部真实实体 | 六SRC不含独立五camera ring；完整目录、origin签名与联合冻结仍INT-B02/03 |
| CAMERA_RING/IMPORT | 正常camera独立采集封存/下一ARM reservation；单COPY分ALG与FREEZE_FALLBACK目的 | camera服务优先，冻结补源不等J/gate；完整packet/cache/关闭与复用期限仍PB-B02/03 |
| CFG/JOB | KEY/CFG/RESET和JOB各唯一writer，J锁旧C，FE只由选定stream owner驱动 | 新桥prejob撤offer和QUIET汇合须联合吸收 |
| R2/LOAD/GRAD | C0计算，LOAD只收CLASS，GRAD collector独立收完整typed梯度；计数/终态不混用 | FK两支独立stall，提前错误状态必须有容量 |
| S/O/RAW | S执行claim、DENSE/RMW、journal/latest；O独占descriptor/pin/ref/版本/权限/退休；raw只读写bytes | PC64MiB仅为仿真/观察；生产RAW↔板载DDR的权限/burst/effects/reset适配须冻结 |
| R3/R4 | NUM单caller0保持精确ID；闭包、识别及ANN全在FPGA，typed组效果真实结束才成功 | 不能把RAW seq当NUM或同宽H跨角色cast |
| VIEW/REPLAY | O/V联合grant，P OPEN获plane借用，M产生OUT；各层真close/return，PLAN_EXIT后才父RETURN | V_LATCHED、VIEW_TERM、OUT EOF都不是生产APPLIED或显示退休 |
| CAMERA/VIDEO | 不可暂停camera到达、独立ring/基础line FE与bulk/input/render/output固定扫描；实际采用/退休 | input18/RX7/output15独立，旧单pair重放不能代生产吞吐；真实服务未闭合 |
| 参考/检查 | 黄金从原image/profile生成；协议检查按真实events；host byte service不执行数学 | 从DUT候选日志构造GT或回填结果均不允许 |

数据路径和控制路径分别前进；CLOSE/RESET/错误通知独立容量，不因满数据队列无法收尾。子quiet不等待父term已经消费，父term的形成也不反向阻止source效果关闭。

## D. 共同接口目录与必须吸收的差异

| IF / 消息族 | 位宽、来源和转换 | 合并规则 |
|---|---|---|
| INT-IF01 控制源 | CFG212/P539/C539/J657/V788；CONTROL D1/D2 | P/C同宽不同意义；JID96=epoch/job_frame/config，逐命名字段转子核 |
| IF02 流段 | CJ142、原FP、CS592/CLASS/GRAD；R2 D/C0/FK | 先准备LOAD/GRAD才启动；真实CS不等全EDGE或几何成功 |
| IF03 LOAD/CLOSURE | LC270/PREPARED277/LC_TERM776，CLJ438/BIND511/CL_TERM1013，RQ324/RSP449/CLOSE294/ACK502 | H160按role包含不同load/closure id；两role独立台账，真实LOAD关闭后才移交CLASS |
| IF04 RC | RJ2257/RB184，KEY287/RQ799/RSP872，CLOSE295/ACK504，TERM2606 | reason6族与闭包reason5不同；RC成功ACK/TERM规则采用v0.2，不拿错echo结债 |
| IF05 NUM | ID176/REQ622/RESP585与R3 cancel/quiet | NUM call_seq独立；owner0单caller，应用/丢弃旧held响应分开，不凭OBJclose清NUM |
| IF06 byte授权/RAW | AR348/AP466、KEY195/RQ707/RSP725、C231/ACK442/T469 | 高到低消息fields与低地址byte packing分开；raw关闭只证明raw债，不代typed close或O退休 |
| IF07 bundle | CERT352 schema2，COMMIT1201/REPLY232，VIEW父RETURN352/ACK360；新AUX_REGISTER295/ACK303及AUX_RETURN293/ACK305见SLOT-JOIN D3 | COMPLETE_CERT含private_refs_retired1，旧schema1拒绝；RC真64RECORD辅助登记后同J绑定result，持久RECORD不进private集合；真实实体仍OPEN |
| IF08 prejob源 | PROFILE-SOURCE D2：SOURCE_OFFER311、PCTX65、BUILD_BIND1012/ACK1212、ABORT456/ACK466、REVOKE224/ACK232、JOB_TERM734；SRC_HOLD_REQ291/GRANT363、RETURN355/ACK363；信用162/RETURN167/ACK175保持 | 显式覆盖旧offer86/182、BIND883/1083、ABORT327/337、REVOKE160/168、JOB_TERM669；同宽ACK独立namespace。同沿旧sourcefire优先；BIND同lease转owner，原role不改，逐份return不直接销共享SRC。目录/错误矩阵仍未冻结 |
| IF09 图像重放 | PLAN616、OPEN619/REPLY888、RQ360/RR421、JOIN413/OUT404、原CLOSE/RELEASE/RT1171 | SOURCE/EDGE/ANN各独立provider/credit；OUT404为可暂停重放及独立像素语义验证出口，须实际观察有效像素/防裁剪，不以LED摘要代输出。生产同源planes/borrow的bulk/input/renderer由IF12/14另冻结，不把旧单pair握手路径当1080p60搬运 |
| IF10 plan/view关闭 | PLAN_EXIT267、VIEW_TERM497、VIEW_CANCEL128/RECEIPT135；生产exec另用SCAN CORE_CLOSE/DISPOSE | 原单PLAN顺序仍仅其原scope；生产长期physical parent hold须所有exec/keeper/snapshot/unknown真闭合才父RETURN，不以一次RT/EXIT结束base；published体保持 |
| IF11 reset授权 | QUIESCE96/QUIET111、START128/七ACK140，再原RESET receipt/done | 本reset事务不计入旧业务allheldempty；P不得从首PLAN授权新epoch；owner0 V须汇合D/pool/snapshot实际匹配closed_before/applied，下级消息/CDC仍未冻结，不增第八owner |
| IF12 生产IO | 新camera ring/capture、bulk/input/render/output与video采用/退休/CDC；六immutable SRC、五ring、三结果、最多两physical bundle；SCAN PREPARE841/ACK979、ARM642/650、STOP262/270、EVENT1021、CORE409/417、DISPOSE322/330 | 新input18/RX7不覆盖原output15；四scan ctx且current≤1/future含closing≤2/old_closing≤1，ROW472的scan为提前exec；首行VSYNC前ready与真采用分离，完整接线/clock/服务仍OPEN |
| IF13 PROFILE/冻结 | PROFILE-SOURCE D1/D3：PR_INSTALL1121/ACK1257、BOOT_SEAL100/ACK108、GET184/REPLY1215；F_SET102/RECEIPT110/DONE368；SNAP_REQ96/REPLY784、RELEASE160/ACK168、CANCEL96/ACK104 | O内owner不增第八START ACK；八实体不等八UI preset。冻结receipt不等actual，真实snapshot/lease交接，NO_ACTIVE/WAIT_FIRST可恢复；完整status/cache/UI277、策略COMMIT与CDC仍OPEN |
| IF14 ring/IMPORT/物理读路由 | RING_CTX283与COPY purpose2（0 ALG、1冻结补源、2/3拒绝）；AR/RX/R_ROUTE与独立W_CTX见PRODUCTION-BUFFER D1…4 | 现CAP_ARM280及161bit去重签名不能直接接新body；全部新packet/held/cache字段与预算未冻结。末R/空位不结束历史route，释放不等整行/COPY commit；全部纳入QUIET |

本整合稿要求CONTROL/REPLAY吸收VIEW D6 Δ01…08，形成联合版本后才称接口统一。具体必改：SOURCE登记/撤销/返还、J_CTX pin到全部term消费、O父引用、VIEW取消入口、P退出、七owner授权ACK、真实raw/O quiet及私有work退休。旧manual CANCEL128仍对已经移交的J返回TOO_LATE；新增VIEW_CANCEL不改变其含义。

旧R5选项中的16B raw提议不优先于RAW实际8client/64B候选：新整合采用RAW D2/D6字段；若生产backend增并发、改block或clock，必须重审journal、台账、缓冲和CLOSE语义，不能称内部小优化。

生产DDR扩展须使用独立schema而非把旧64MiB/26bit地址合同视为已适配。可审阅的候选DR_KEY201=S96/seq64/op2/byte_address32/length7、DR_RQ713=KEY201/payload512、DR_RSP731=KEY201/status2/reason6/value512/effect2/written7/settled1；权限返回由AP466的address26扩为address32，成为DR_AP472，AR348不变。实际DDR范围为[0,268435456)，端点扩33bit核验；128MiB生产区只是分配策略，不能由AXI_ADDR_WIDTH32扩大物理容量。这些候选尚未吸收进RAW/O/全部caller版本，不是已冻结新端口。

相同迁移还需区分arena与单对象：arena OPEN原capacity27无法表示2^28字节，256MiB容量字段至少29bit；原base26和journal地址26须扩到新32bit字节地址。单descriptor的capacity27若最大单对象仍≤16MiB，可以保留，不能笼统说所有27bit容量都不足。各端点/地址运算先扩宽检查，完整schema/目录/journal版本仍待联合冻结。

byte地址未必16B对齐，长度1…64的合法请求可能覆盖最多5个128bit拍，不能统称4拍。若复用旧服务的全WSTRB策略，adapter必须对端拍保留邻byte；rounded span须在同一对象已初始化的physical/padding授权中，active writer排他与本地group锁覆盖完整读改写。选择窄WSTRB则先证明真实IP支持，不能默放开。AXI错误无法证明哪些byte已写时，返回UNKNOWN/written0并保留effect debt；真实关闭只证明无未来效果，不把未知变成成功或任意前缀。每个physical请求的ready/held/B/R/ID/LAST/计数、校准前禁入、reset/隔离和camera/display/算法QoS须由完整DDR backend局部合同冻结。旧DDR-SERVICE的J486/scope623/permit266与当前R族并不相同，仅作为响应/权限/排空义务来源，不直接接线。

组合反例走查：CLASS成对提交与cancel同沿保留已提交事实；两个ANN像素在同byte RMW不得覆盖邻位；RC_CLOSE_ACK合法failedclose可结债但阻COMPLETE；PLAN_EXIT前父不得返图；prejob revoke接受沿已真转移不能再S_ONLY返源；epoch授权不能通过先清held或O.valid凑QUIET。

## E. 整包中文操作草图与资源生命周期

INT-OP01 看完整范围。先读B五类行为，再C owner与D消息族，确认板载DDR已重新允许、低指标撤回和高指标保持。

INT-OP02 选真实后端。核容量/地址/端口/电气/有效带宽与最坏等待。当前41,113,469B保守对象总量远超Ti60片上327680B，但小于板載DDR256MiB；用显式分区和授权映射全部对象，多源/结果槽另计。PC服务只验证逻辑。真实protected接口、校准、B后读可见、关闭/隔离和QoS分别证明，不以容量或理论带宽替代。

INT-OP03 建源。先安装完整PROFILE；camera提前取得独立ring reservation/ARM，完整RAW/RGB/CRC与真实写关闭后sealed/latest，不等慢J或六SRC空位。ALG_IMPORT核J/信用/scratch、目的SRC及camera服务；NO_ACTIVE冻结补源按FREEZE_FALLBACK目的只核真实冻结意图、目的SRC与camera/运输资格，不等已关source gate或造J。单COPY锁完整capture origin/目的/旧CFG/PCTX，完整RGB读写、真实可见性/commit、读CLOSE/返ring pin后注册immutable SRC，再交SOURCE311或匹配F lease/实际应用。sourcefire锁旧CFG/PCTX，BIND同lease转O；RESUME独立取消补源并履行已held。fixture/PC不私改原图；准备LOAD/GRAD之后才CJ。采集损失与算法未选分别报告，连续服务仍未证明。

INT-OP04 全算法。R2计算CLASS/GRAD，FK每支真消费；LOAD/GRAD末写和pending关闭才commit。闭包种子/八邻域/claim+queue真正结束后完整EDGE。RC按POINT/候选/拟合/冻结核验/精确去重/ANN与RECORD执行；NUM和raw独立台账。

INT-OP05 减空间但不改结果。闭包结束后CLASS/QUEUE须真实typed close、pin和private引用退休才可复用；GRAD/POINT只有最后核验/ANN读取及NUM义务结束才能退休。ANN程序生成、POINT改重算或BFS改扫描都是重要结构变更，需独立证明等值与周期，不在此擅自生效。

INT-OP06 发布与显示。建立完整CERT2、先实际退还private refs并登记RC真实RECORD，再O/V唯一联合采用；bulk锁历史同源planes/row、按128beat/4KiB搬完整input RGB/EDGE/ANN，renderer按ROW原数学输出三output row。R_ROUTE锁至旧RX/pending/holding/decoder真移交后才下一AR，不能等整行或COPY commit；COPY写的W_CTX独立。六源三结果各存历史J，新BUILD须旧结果信用、单scratch空与PREPARE；第三完整结果冻结等待，不增第三physical bundle。生产显示先在真实parent pin下PREPARE提前授exec，独立candidate/repeat首行在VSYNC前真READY/OWNED，一次ARM_SET绑定同target集合，固定边界只用沿前资格真采用/APPLIED并绑定physical_frame。四scan与五RowCtx独立，三out/两input不增；ARM决定转交后membership关闭，落选自动STOP不等不存在APPLIED；Q真实快照不授闭合，DISPOSE临时refs先结束、持久execution pin等成功ACK消费，父整体hold仍独立。全部真实clock/资源/服务OPEN，旧单pair至少三core沿路径不是1080p60实现。

INT-OP07 停止与失败。旧fire、logical_commit与物理effects先真实结账，再停止新业务。未知raw债允许独立raw CLOSE先推进；只有正确完整证明才结效果债并关闭typed服务，私有对象仍需O逐份退还。没有Q证据闭合就不开放下一epoch。

INT-OP08 统一实施。成熟版本及全部源/输入/工具/schema清单保存读回并独立复审后统一申请指定批准；获批后只在work创建真实文件，按G执行，成功到bit登记即停止。

INT-OP09 在不改变数学结果前提下优化。固定不alias的6SRC/3EDGE/3ANN/单GRAD/CLASS/QUEUE/POINT/AUX旧对象段为84.25MiB，另加五camera ring后当前候选124.25MiB；SLOT-JOIN的21typed私有＋3持久RECORD，各round64及64B guard合428928B，尚不含完整目录/journal/新ring控制metadata。全半径HIST32额外512KiB未默认纳入本容量；须另核布局与同时寿命。每seed原16tile导致16次POINT距离扫描，fullHIST可一次扫描构造全域，再以原半径顺序/halo/plateau规则读回；仍逐bin21bit、r0及域外规范、真实CLEAR和封存、连续同binforward，重要结构变化须单独版本等值审查。

DENSE每θ总票≤E≤2073600<2^21，故最多一个bin有第21位；两个bin各≥2^20将令总票≥2^21，矛盾。可用16个native20×512 RAM存低20bit，每lane另用valid1/bin9记唯一高位，共160FF仅为marker。完整21bit由读地址是否命中marker重建，全部277bin合法；单bin不能第二次低20回绕。CLEAR、连续samebin最新低位/marker、16票组原子可见、重复接纳拒绝与失败effects仍需逐沿合同；遇第二高位或计数超E为真实INVARIANT。它比逐票外存更新有提速潜力，但16bank不是16票/沿证据，旧逐组req→rsp的停顿与NUM/POINT吞吐仍必须计入。当前R4R数学/端口不默改，完整设计选择由新性能稿与后续联合版本决定。

## F. 语言、独立参考与数值/时间对应

SV2009候选。RTL保持沿前真实fire、旧状态计算/沿后提交，时序非阻塞、组合完整阻塞、明确signed/扩位/RNE/floor/饱和；每局部F仍是具体数值权威，不以本总述代替。

独立数学参考职责：直接整图RGB灰度、普通九值排序、每级各自复制边界的卷积、明确方向/NMS/双阈值；独立集合BFS从强种子得到全N边缘。几何参考从原image/profile和独立GT测量候选/支撑/量化误差，不能把DUT日志当真实目标。

协议参考独立记录req、rsp、read capture、logical_commit、raw effects、phase、close、typed terminal和pin return，按完整身份匹配；最终数值相同不能代时序正确。PC bytes服务只storage，不计算candidate、CLASS、DENSE、TLS、ANN或token。

质量评价按每类P/R≥95%、同类IoU≥0.5的最大基数一对一匹配，失败或容量图保留在分母/失败统计；数据开发与独立验收划分、种子/原图/GT摘要先冻结，旋转、重叠、缺边、噪声、负样本均为测量轴，不能重置已撤回的场景硬界限。完整fixtures/GT算法/样本数仍INT-B05。

时钟不混用25MHz局部观察、RAW27MHz候选与100MHz预算。PRODUCTION-BUFFER D5找到C2的MIPI_TX_PLL/PLL_TL0 core_clk全局100MHz候选及DDR axi/core同net，另DDR_PLL供400MHz PHY；不再硬改固定#4 regional为fabric gclk。实际gear/phase/CDC/generated clock及HDMI相关clock仍须明确验证，不把同频、全clock组false_path或旧STA当新工程通过。

## G. 文件职责、实施顺序及验证矩阵（未生成/未运行）

工作根仍为 _fpga_edge_agent/work/active/track4_algorithms_20261004/，当前不存在。以下为整包候选文件组，不是假称已经完成的源码/精确冻结清单；现R1/FE/R2 FILES的逐文件合同原样引用，其余具体模块内部由对应新局部冻结。

| 文件组/候选核心路径 | 责任及阅读次序 | 要求/接口和测试 |
|---|---|---|
| rtl/common/track4_types_pkg.sv、ram10_bank.sv、reset_sync.sv | 共同schema、真native端口、复位；先读每个type命名字段，再读owner | 全D/F，T01/T02/T08 |
| rtl/frontend/原六文件；rtl/r1/现五文件 | 单FE、中值/灰度/原Sobel及局部观察；原R1/FRONTEND清单展开后不新增第二核 | INT-04，IF02，T01/T02 |
| rtl/r2/现13文件 | C0/Gaussian/gradient/fork/NMS/class、R2局部观察；R2 FILES准确路径为来源 | IF02，T01/T02/T03 |
| rtl/r3/numeric_core.sv、numeric_rom.sv | typed算术/乘除根/LS/TLS/ROM、cancel/quiet；内部职责须进一步映射 | IF05，T04 |
| rtl/storage/object_directory.sv、byte_authorizer.sv、atomic_journal.sv、typed_store.sv、raw_adapter.sv | descriptor/pin/权限、bytes/RMW/latest、所有原子组/phase/close | IF03/04/06/07，T05/T06 |
| rtl/storage/source_bootstrap.sv、src_lease.sv、source_registry.sv、grad_collector.sv、plane_provider.sv | 实际SRC/GRAD全覆盖、原grant身份与逐lease return、最后base退役 | IF02/08/09，T02/T05/T07；具体pin/cache仍PS-B02 |
| rtl/io/camera_ring.sv、capture_reservation.sv、rtl/storage/source_import.sv、capture_origin | 独立连续采集与单COPY；ALG/冻结补源目的、历史origin及独立取消 | IF12/14，PB-T01/02/03/08；消息/FSM/服务未冻结、文件未生成 |
| rtl/storage/ddr_physical_adapter.sv、rx_burst_fifo.sv、rtl/replay/bulk_input_row.sv、row_decoder.sv、row_renderer | 真B/R及独立R_ROUTE/W_CTX、完整row填料与同源逐pair输出 | IF06/12/14，PB-T04…09；25新增payload RAM和原output15分计，全部holding另计 |
| rtl/storage/profile_manager.sv、profile_ram.sv、profile_schema、native wrapper | O内部完整52word安装/GET、独立ref/seal、epoch不可变与真实排空 | IF13，PS-T01/02/03/09；一RAM几何不代精确门值/全预算 |
| rtl/closure/class_loader.sv、hysteresis_controller.sv | LC→精确BFS→全EDGE→真实close | IF03，T03/T05/T06 |
| rtl/recognition/recognition_controller.sv、point_builder.sv、circle_engine.sv、rectangle_engine.sv、verify_dedup.sv、annotation_engine.sv | 全RC阶段/核验/排序/去重/光栅/records；不是PC计算 | IF04/05，T04/T07/T09 |
| rtl/control/config_owner.sv、key_events.sv、job_dispatcher.sv、source_policy.sv、freeze_intent、epoch_reset.sv | D/P/C、手势、单J/PCTX、独立T/R、QUIET与授权；冻结VIDEO桥仍需具体CDC联合版 | IF01/08/11/13，T02/T06及PS-T06/07/08/09 |
| rtl/replay/view_bridge.sv、plane_replay.sv、pixel_renderer.sv | O/V父引用、P borrow/EXIT、同源像素与叠加 | IF07/09/10，T07 |
| rtl/io/通信组、camera组、video组、production_top.sv | 真实后端/pin、CSI、固定视频和完整防裁剪；未选定结构不填假文件/IP | IF12，T08/T10 |
| model/frontend_reference.py、canny_stream_reference.py、numeric_reference.py、closure_reference.py、recognition_reference.py、render_reference.py | 独立数值模型按阶段分开，不共用RTL FSM/journal实现 | T01/T03/T04/T07/T09 |
| model/protocol_scoreboard.py、byte_service.py、quality_evaluator.py、fixture_manifest | 事件检查、raw-only后端、独立GT匹配及来源身份 | T02/T05/T06/T09 |
| sim/frontend、sim/r2现10TB及sim/r3/storage/closure/recognition/control/replay/io/integration | 单元/组合/full1080p、错误/时序与容量；具体TB列表须逐接口补齐 | T01…T10 |
| scripts/run_package_sim.ps1、run_package_build.ps1、project/full_package.xml/.peri.xml/.sdc | 真实已安装工具、日志/期限/失败、PT/PNR/STA/bit；不生成stub工程 | T08/T10 |
| reports/design-source-test-trace、中文操作说明、实际产物manifest | 从行为到接口、局部步骤、符号与真实报告双向索引 | T11 |

| TEST | 输入/事件 | 期望来源与通过标准 | 当前 |
|---|---|---|---|
| INT-T01 数值阶段 | 黑/白/极值、全部边界、方向平局、阈值相等、median重复 | 独立整数参考逐像素/逐typed结果；全1080p，数值规范先冻结 | NOT_RUN |
| T02 时间配置 | valid0、气泡、每口stall、末像素/状态同沿、变更CFG | 真实数量/身份/历史快照，无穿透/撤held/错frame | NOT_RUN |
| T03 全闭包 | 逆序长蛇链、斜连、环、孤立弱边、无强/无弱、全N队列 | 等独立可达集合，完整N含0，真实最后写闭合 | NOT_RUN |
| T04 NUM与geometry | 所有NUM合法/拒绝/溢出/RNE；圆/任意旋转矩形拟合与冻结诊断 | NUM_ID/定点与geometry稳定，局部误差契约与独立GT | NOT_RUN |
| T05 原子目录 | samebyte/RMW、claim与queue尾N、DENSE16、第17journal槽、padding/权限/版本错 | 成对可见/latest、未授权无效果、正确REF/pin返还，不变成主机算法 | NOT_RUN |
| T06 失败关闭 | known/partial/full/unknown、wrong echo、postcommit reset、迟到ACK/term | 保存真前缀/commit、独立close无环、未知不解Q、所有控制回执实际消费 | NOT_RUN |
| T07 VIEW/render | mode0重复偶行、全部6mode/颜色/开关、prejob撤offer、EXIT/RETURN | 同RGB/EDGE/ANN/JID，O/V唯一grant、真实退休后复用；非RC缺ANN合法/RC零目标全0ANN | NOT_RUN |
| T08 物理core | 动态输入/profile、全core实例、实际native RAM/速度级/pin/clock/PT/PNR/STA | 完整有效扇出、资源符合预算、目标时序/约束覆盖，无黑盒/虚拟宽IO/小top替全包 | NOT_RUN |
| T09 质量 | 独立开发/验收GT，negative/overlap/noise/遮挡/rotation完整图 | 每类P/R95%+IoU0.5最大基数一对一；所有错误计入，不改期望掩失败 | NOT_RUN |
| T10 生产连续IO | 实际模式到达、最坏backend等待、不同clock相位/复位、HDMI帧边界 | 缓冲/QoS/CDC/采用/退休成立，采集/算法fps/显示Hz分别实测 | NOT_RUN |
| T11 交付一致性 | 指定设计/source/input/schema/tool/project/log/bit/trace | 读回真实文件和稳定符号，正反可定位；bit后停止 | NOT_RUN |

实施按依赖连续进行，不因每个局部文件再申请一次批准；成熟同范围批准持续有效。当前局部FSM、全部文件/确切端口和运行期限未闭合，不能把这张职责表标为已完整冻结。

## H. 双向追踪

| 用户五类 / 原要求 | MOD/IF/OP | 计划文件组 | TEST | 当前直接证据 |
|---|---|---|---|---|
| 1 / A3/A4/A6 | S/O/RAW/DDR/provider，IF03…08，OP02/03/04/07 | storage/closure/recognition/DDR适配 | T03/05/06/08 | 控制器及板载容量来源已找到；新backend适配未冻结/实现 |
| 2 / 所有算法 | 全core，OP05/F | 完整performance/resource、cache/clock/NUM | T01/04/08/10 | 候选预算，完整预算仍OPEN |
| 3 / B1/B4/A5 | SOURCE/CAMERA/VIDEO，IF12，OP03/06 | io/production_top | T07/10 | 更新v7参考组合来源；DDR生产结构及服务期限仍OPEN |
| 4 / B5/规范 | 全D/G/F，OP01/08 | schemas/models/sim/trace/中文说明 | T01…11 | 本整合候选和原局部；未冻结/未实现 |
| 5 / 软件至bit | 全组，OP08/G | work、实际工程/runner/产物日志 | T08/11 | NOT_RUN；无指定整包实施批准 |

反向每个文件必须承担上表的算法、实际协议/IO、独立验证或可复现证据责任。PC只储存bytes的仿真服务与黄金模型隔离；不把黄金结果送入DUT。A3虽恢复仍未完成；实机下载/观察不作为本软件阶段已完成项。

## I. 门槛与真实阻塞

| ID | 当前缺口 | 允许继续的工作与证据 |
|---|---|---|
| INT-B01 | 板载DDR3存在、C0/C2参考综合PASS；C0 PNR因原USER1接口不匹配失败，C1固定PLL#4候选不可驱动fabric；匹配模型/真实服务/生产映射未验证，CSI key和外部byte频率受阻 | A2保留实际阶段/资源/失败；重规划真实调试连接与合规core时钟，继续生产mapping/校准/可见性/QoS；不选外接模块或PC生产arena |
| B02 | typed原子/目录/SOURCE/GRAD/cache/错误矩阵仍未闭合；新ring/import目的与origin签名、R_ROUTE/W_CTX完整字段/关闭未冻结 | 新BCAA稿的冻结补源互等与旧routing覆盖两反例限定关闭；继续完整联合FSM/目录/消息，不以反例复核代生产验证 |
| B03 | CAMERA/VIDEO多域与最坏服务、五ring提前ARM/closing/reuse、COPY份额、snapshot/COMMIT/CDC及pin/约束尚缺 | 六immutable＋五ring及四scan解除限定结构循环；三out尾段须真实返还才容两首行，随后row1/closing/持续行与14.8148µs期限必须统一证明，e970局部沿表不代服务 |
| B04 | 全机native RAM10/FF/DSP/PLL、全部holding/FSM及后端周期未冻结 | input18/RX7/output15合40只是payload；ROW1219、五ctx4325、局部消息3000、ROW11508及SCAN30306/adapter638有各自范围，不重复3360或把下界当总FF；完整预算与映射仍OPEN |
| B05 | 所有接口完整字段、Δ01…08联合版本、profile/fixture/GT/确切文件与期限未冻结 | 本稿D/G接入ROW/SCAN；bulk/ROW_ASSIGN、父目录、下级epoch ACK、健康/恢复及共享registry仍须冻结和复核，不能以新增消息表关闭 |
| B06 | 指定版本整包实施批准、work/构建审批、正式DB前置仍未满足 | 设计成熟后一次提交具体范围/基线和必要治理条件；不预写代码或更改权限 |

规范10.3整体范围/职责/候选接口、操作/验证/追踪已有内容；真实依赖/完整局部/资源/文件基线仍未闭合，⑧无阻塞不满足。保持NOT_READY，不申请批准未成熟整包。

## J. 变更与恢复

本稿v0.2纳入用户最新明确允许板载DDR3的回复，保持只用板卡现有资源、高指标和低指标撤回。旧无DDR边界保存在v0.1快照；旧VIEW扩展集中映射到CONTROL/REPLAY，未默改其旧接口。DDR后端、clock、并发、双bundle、程序ANN或GRAD重算均影响设计边界，先修订相应REQ/IF/OP/TEST并复审，批准后的变化按规范处理。

v0.3补已保存PERF/PIO/HDK证据、实际有限工具结果和arena/descriptor不同容量迁移；旧v0.2 BE685C171962C59EA0B6F3768BA1B5B691FA8D07D1EA45DD015C124964029DF1/32057B保存在`design-TRACK4-ALGORITHM-INTEGRATION-001-v0.2-before-ip-precheck.md`。限定组合审阅C7A63AABC9B53CA8673F5FA06AAA08942480B78AD7EBE72715134087FFFC1E7D绑定旧BE685，不说已审完v0.3；本次来源/实测追加不将整包升级READY。

## K. 本轮实录

v0.8接入ROW v0.2 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8／29116B及SCAN v0.2 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243／43548B。旧v0.7 5FA0450D69FFFEA32F74EEC7A95173030FCDCDA701FFA1AAD170F6698027B4C6／49136B保存在before-scan-reservation快照，ROW旧90E980／27684B亦保存。SCAN原BE543B稿的实际反例报告与05CBA3修订的限定数值/协议/生命周期复核分开，最终L85只明确容量role而不声称全文重审。来源PIO/PROFILE/VIEW原hash保持，通过本稿IF10/11/12与SCAN J显式覆盖生产语义；具体接线/最坏服务/完整资源/基线/批准仍OPEN，没有算法实现或新增构建通过。

v0.7纳入PRODUCTION-BUFFER v0.1及2261B纯算术A560；当前PB为0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40/26058B，BCAA/25896B的[目的澄清前快照](design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001-v0.1-before-purpose-wording.md)保存实际审阅输入。旧v0.6 F0D020BEF6B969F0120086B3E931EED9EC4265EC4EB69ECB132147D20E6697DA/44194B保存在[before-production-buffer快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.6-before-production-buffer.md)。[实际来源/审阅](../experiments/track4_algorithms_20261004/03_review/production-buffer-review-v0.1.md)分别绑定A056初稿全文协议、BCAA修订限定复核及最后目的措辞核对，不冒称整包全文通过。整合D578047B65430B1CF60D90E4ECBD7B97BCC5D0F2B216A243DFA26683E8BADD95/48530B的[IF09澄清前快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.7-before-replay-wording.md)保存增量审阅输入；据实际交接检查明确旧OUT与生产bulk路径。根分段全文读回BCAA/整合D578，并定向核最后文字差异。五ring、行bulk/25payload RAM和真实global core来源为设计进展，服务/全部schema/资源/实现仍未完成。

v0.6纳入PROFILE-SOURCE v0.1及4254B纯数据布局4FE6BF462E97C30D8F421E9D30FDA96D4D9DFC7AC397024B4320159702B0B810；持久seal计入目录、独立OBS反例计入准入，所有文字验证仍NOT_RUN。旧v0.5的40026B/DB1DD10FCF4190036993D7C7AF95C04C03B3307377D1FDDCEE56D2D42256272D保存于[before-profile-source快照](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.5-before-profile-source.md)。[实际来源和限定审阅](../experiments/track4_algorithms_20261004/03_review/profile-source-review-v0.1.md)按旧E68F、seal增量FC7EE及最终容量修改分别绑定，不冒称完整整包独立通过或SJ-B02全部关闭。真实本机Efinity2026.1及Ti60F225/I3项目配置再次只读确认；工具存在、参考综合通过与新增完整功能的仿真/PNR/STA/bit证据分开。

v0.5纳入SLOT-JOIN v0.1与11,516B纯数据布局9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75：容量选择、21private计数、AUX子对象/guard、显式SOURCE_OFFER182、信用及辅助记录候选已写明；真正接口/实体/全机资源仍OPEN。v0.4的9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3/36816B保留于before-slot-join快照；旧审閱不冒称覆盖本版或联合稿全部变化。

[SLOT-JOIN实际限定复核](../experiments/track4_algorithms_20261004/03_review/slot-join-review-v0.1.md)分别绑定7711全文/9B4布局、E9新增数值及协议全文、6BC最后OP04分支修订。数值计数/地址相等；实际信用结束遗漏与VIEW串行文字歧义已补清、限定读回未发现新矛盾。没有协议仿真或物理工具新证据，未关闭B01…06。

v0.4仅同步v1.2实际终态及PIO时钟物理阻塞；v0.3精确快照D2E0CF383B2D8EEA790A4F9D2DD0BADC6837244781F78AD7AD822759CCDAF0D5/35665B保存在design-TRACK4-ALGORITHM-INTEGRATION-001-v0.3-before-ip-terminal.md。旧独立审查不冒称覆盖本版全部新增段落。

整包仍纯设计，无新增算法实现/功能runner/模型/TB或整包工程/SDC。获批有限预检实际map/debug/PT/PNR/vlog终态见A2，PNR失败、无STA/bit；没有设备/网络/安装。Manifest只追加实际批准的有限预检记录，原HDK、正式状态和数据库未改。整包仍NOT_READY/NOT_APPROVED，不能把有限实验终态当完整实现完成。

## L. 中文阅读与交付边界

先看B五类关闭条件→C谁拥有何数据→D接口目录与差异→E正常/失败及生命周期→F参考角色→G文件/验证→H追踪→I具体缺口。文档完成度、业务实现度、软件验证和实机验证分别陈述。当前交付为整合候选；不足之处已定位，不声称五类全部完成或已证明整机可实现。
