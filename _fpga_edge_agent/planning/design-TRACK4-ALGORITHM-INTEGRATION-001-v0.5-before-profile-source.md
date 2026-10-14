# TRACK4-ALGORITHM-INTEGRATION-001：五类剩余工作的整包组合设计 v0.5

2026-10-04；GLOBAL_DESIGN / NOT_READY / NOT_APPROVED / 整包业务NOT_RUN。本稿统筹最新五类工作，引用现行局部合同；有限IP预检已获指定批准并有A2的实际结果，但未取得整包实施批准或完成十一功能。

## 通用计划字段

- Goal：完整推进板卡现有DDR3存储/通信、性能资源、生产输入输出、整包统一，以及获批后的实现/软件验证至bit。
- Current state：R1至R4、CONTROL/REPLAY/VIEW和RAW候选已存在；性能/生产IO候选已保存读回，RAW两文字反例已复核；SLOT-JOIN v0.1明确六源三结果与独立RECORD候选，静态分区已核；C2原参考在当前Efinity综合PASS，仍无本次算法代码或完整构建产物。
- Target state：明确实际可实现结构、完整接口和局部草图、共同文件/质量/验证基线后统一提交指定版本批准；随后在work连续实现和真实运行。
- Gap：生产DDR容量有84.25MiB无别名候选，槽数差异已在联合候选中明确选择6/3；真实目录/物理连接、全片上预算、profile及服务期限仍未闭合；旧单slot稿不能直接接生产多槽接口。
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
| [PRODUCTION-IO v0.2](design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | 同步预检PLL#4物理阻塞；旧v0.1精确快照保留。原两源两bundle条款由下行联合候选显式选择6/3；两物理视频路由上界保留，完整生产实体仍未冻结 |
| [SLOT-JOIN v0.1](design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | 6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | 六SRC/三结果/单scratch；21typed私有与三RECORD独立布局；SOURCE_OFFER182、信用/绑定/返还、AUX登记/返回及历史J候选；本文静态核查不代实现或整包READY |
| [更新HDK DDR证据](../experiments/track4_algorithms_20261004/03_review/ddr3-updated-hdk-evidence-v0.1.md) | F3492D3D4E7AB0B3B9247AD2A44859F0A52DCE282BC9D7F2A8CB0B8646F3E942 | 作者/根实际全文读回；原v1/更新v1/v6/v7控制器、256MiB几何、版本/报告/引脚及2Gb模型缺项范围 |

共享schema和计划文件不能只按以上摘要自动生成；各body字段仍以对应局部D/F为依据，增加桥扩展必须形成具体联合版本，不把旧主稿当已接受新端口。新增[RAW最终复核](../experiments/track4_algorithms_20261004/03_review/raw-store-review-v0.1.md)绑定7D08D9BB39393F6CD36975E7C64FF1BA9E7B7FCBB595BA7A1D7949FBF875FEE1、27364B，只关闭两项明确文字协议反例，不升级生产存储或整包READY。

SLOT-JOIN是新的候选组合入口：全局6SRC/3结果与单scratch已选定，PIO仅两物理bundle路由不扩大；三个历史J分别pin，RECORD不随private退休。其SJ-B01…05明确保留真实目录、profile、生产服务、完整资源与文件/schema冻结缺口。源槽128B PROFILE预留不自动成为CONTROL要求epoch内不可删的profile实体。旧v0.4精确快照保存在[before-slot-join](design-TRACK4-ALGORITHM-INTEGRATION-001-v0.4-before-slot-join.md)，SHA256 9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3、36816B。

联合稿D2另补清预留事务结束与结果退休的不同事件：RETURN/ABORT真实成功且原ACK被J消费，或真实COMMIT成功且原R4接收方消费匹配REPLY232后，后续旧消息槽资格才允许给另一FREE结果槽提出信用。原COMPLETE结果仍占用自身实体/历史KEY；BIND_ACK不结束信用。J未花费KEY、当前BUILD KEY和O三份历史KEY分别保存，至少810bit payload另加held与状态；新信用可等旧J终态，但不能提前接新源。这是候选设计补充，实际目录与错误矩阵仍OPEN。

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

正常路径：SOURCE完整封存→注册源→原JOB锁完整CFG→R2/LOAD先准备→全CLASS/GRAD真实commit→CLOSURE精确集合/全EDGE→RC全候选核验/ANN/RECORD→私有refs实际退休→CERT2完整bundle→VIEW联合父引用→REPLAY借用/像素→固定视频采用→各层真实退休→下一帧或epoch。

失败路径：例如DENSE logical_commit后第二raw写失败，真实已提交事实和副作用保存，后续不发布成功图；独立raw关闭证明未知效果、typed局部close及目录退还，错误终态不等同取消收条。未知不回收引用，不靠reset消债。

## C. 唯一职责与完整数据/控制连接

| 组合组 | owner和保证 | 当前限制 |
|---|---|---|
| SOURCE/BOOTSTRAP | 新源接纳、原RGB/profile bytes初始化覆盖和源登记；不代算class/GT | 原族端口与生产capture尚需INT-B02/03 |
| CFG/JOB | KEY/CFG/RESET和JOB各唯一writer，J锁旧C，FE只由选定stream owner驱动 | 新桥prejob撤offer和QUIET汇合须联合吸收 |
| R2/LOAD/GRAD | C0计算，LOAD只收CLASS，GRAD collector独立收完整typed梯度；计数/终态不混用 | FK两支独立stall，提前错误状态必须有容量 |
| S/O/RAW | S执行claim、DENSE/RMW、journal/latest；O独占descriptor/pin/ref/版本/权限/退休；raw只读写bytes | PC64MiB仅为仿真/观察；生产RAW↔板载DDR的权限/burst/effects/reset适配须冻结 |
| R3/R4 | NUM单caller0保持精确ID；闭包、识别及ANN全在FPGA，typed组效果真实结束才成功 | 不能把RAW seq当NUM或同宽H跨角色cast |
| VIEW/REPLAY | O/V联合grant，P OPEN获plane借用，M产生OUT；各层真close/return，PLAN_EXIT后才父RETURN | V_LATCHED、VIEW_TERM、OUT EOF都不是生产APPLIED或显示退休 |
| CAMERA/VIDEO | 连续source到达、域缓冲与固定扫描；生产采用和退休自己产生证据 | 实际后端、连续新BUILD/旧VIEW并存与带宽未闭合 |
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
| IF08 prejob源 | 新生产SOURCE_OFFER182；原REVOKE160/ACK168、SOURCE_RETURN160/ACK172；信用162/RETURN167/ACK175、BIND883/ACK1083、ABORT327/ACK337见SLOT-JOIN D2 | 旧实验offer86不直连新生产；各独立namespace及完整source身份；同沿旧offer真fire优先，撤offer须正确ACK与真实revoke_idle；已sourcefire不能未用RETURN/S_ONLY |
| IF09 图像重放 | PLAN616、OPEN619/REPLY888、RQ360/RR421、JOIN413/OUT404、原CLOSE/RELEASE/RT1171 | SOURCE/EDGE/ANN各独立provider/credit；OUT404真正输入生产适配，不只LED摘要 |
| IF10 plan/view关闭 | PLAN_EXIT267、VIEW_TERM497、VIEW_CANCEL128/RECEIPT135 | RT消费→后续GAP/全部旧债空→EXIT→父RETURN→对象退休→VIEW_TERM；published EXIT/TERM按原保持规则 |
| IF11 reset授权 | QUIESCE96/QUIET111、START128/七ACK140，再原RESET receipt/done | 本reset事务不计入旧业务allheldempty；P不得从首PLAN自行授权新epoch |
| IF12 生产IO | 新camera/capture、存储仲裁、video采用/退休、CDC消息，六源三结果目录及最多两物理bundle引用 | 固定两扫描路由及第三结果冻结等待；完整bulk字段/clock/服务期限仍须生产稿固定；不编造pin或已有通过证据 |

本整合稿要求CONTROL/REPLAY吸收VIEW D6 Δ01…08，形成联合版本后才称接口统一。具体必改：SOURCE登记/撤销/返还、J_CTX pin到全部term消费、O父引用、VIEW取消入口、P退出、七owner授权ACK、真实raw/O quiet及私有work退休。旧manual CANCEL128仍对已经移交的J返回TOO_LATE；新增VIEW_CANCEL不改变其含义。

旧R5选项中的16B raw提议不优先于RAW实际8client/64B候选：新整合采用RAW D2/D6字段；若生产backend增并发、改block或clock，必须重审journal、台账、缓冲和CLOSE语义，不能称内部小优化。

生产DDR扩展须使用独立schema而非把旧64MiB/26bit地址合同视为已适配。可审阅的候选DR_KEY201=S96/seq64/op2/byte_address32/length7、DR_RQ713=KEY201/payload512、DR_RSP731=KEY201/status2/reason6/value512/effect2/written7/settled1；权限返回由AP466的address26扩为address32，成为DR_AP472，AR348不变。实际DDR范围为[0,268435456)，端点扩33bit核验；128MiB生产区只是分配策略，不能由AXI_ADDR_WIDTH32扩大物理容量。这些候选尚未吸收进RAW/O/全部caller版本，不是已冻结新端口。

相同迁移还需区分arena与单对象：arena OPEN原capacity27无法表示2^28字节，256MiB容量字段至少29bit；原base26和journal地址26须扩到新32bit字节地址。单descriptor的capacity27若最大单对象仍≤16MiB，可以保留，不能笼统说所有27bit容量都不足。各端点/地址运算先扩宽检查，完整schema/目录/journal版本仍待联合冻结。

byte地址未必16B对齐，长度1…64的合法请求可能覆盖最多5个128bit拍，不能统称4拍。若复用旧服务的全WSTRB策略，adapter必须对端拍保留邻byte；rounded span须在同一对象已初始化的physical/padding授权中，active writer排他与本地group锁覆盖完整读改写。选择窄WSTRB则先证明真实IP支持，不能默放开。AXI错误无法证明哪些byte已写时，返回UNKNOWN/written0并保留effect debt；真实关闭只证明无未来效果，不把未知变成成功或任意前缀。每个physical请求的ready/held/B/R/ID/LAST/计数、校准前禁入、reset/隔离和camera/display/算法QoS须由完整DDR backend局部合同冻结。旧DDR-SERVICE的J486/scope623/permit266与当前R族并不相同，仅作为响应/权限/排空义务来源，不直接接线。

组合反例走查：CLASS成对提交与cancel同沿保留已提交事实；两个ANN像素在同byte RMW不得覆盖邻位；RC_CLOSE_ACK合法failedclose可结债但阻COMPLETE；PLAN_EXIT前父不得返图；prejob revoke接受沿已真转移不能再S_ONLY返源；epoch授权不能通过先清held或O.valid凑QUIET。

## E. 整包中文操作草图与资源生命周期

INT-OP01 看完整范围。先读B五类行为，再C owner与D消息族，确认板载DDR已重新允许、低指标撤回和高指标保持。

INT-OP02 选真实后端。核容量/地址/端口/电气/有效带宽与最坏等待。当前41,113,469B保守对象总量远超Ti60片上327680B，但小于板載DDR256MiB；用显式分区和授权映射全部对象，多源/结果槽另计。PC服务只验证逻辑。真实protected接口、校准、B后读可见、关闭/隔离和QoS分别证明，不以容量或理论带宽替代。

INT-OP03 建源。SOURCE取得独占writer、初始化实际RGB/profile全覆盖、核全图canonical后commit并注册S；此后fixture或PC不能私自改原图。准备LOAD和GRAD全角色资格，之后才能CJ启动；不可暂停相机要求缓冲和后端服务保证。

INT-OP04 全算法。R2计算CLASS/GRAD，FK每支真消费；LOAD/GRAD末写和pending关闭才commit。闭包种子/八邻域/claim+queue真正结束后完整EDGE。RC按POINT/候选/拟合/冻结核验/精确去重/ANN与RECORD执行；NUM和raw独立台账。

INT-OP05 减空间但不改结果。闭包结束后CLASS/QUEUE须真实typed close、pin和private引用退休才可复用；GRAD/POINT只有最后核验/ANN读取及NUM义务结束才能退休。ANN程序生成、POINT改重算或BFS改扫描都是重要结构变更，需独立证明等值与周期，不在此擅自生效。

INT-OP06 发布与显示。建立完整CERT2、先实际退还private refs并登记RC真实RECORD，再O/V唯一联合采用；P借用后按同源坐标读三plane，OUT交生产视频适配。六源三结果各存历史J，新BUILD须旧结果信用、单scratch空与真实PREPARE；第三完整结果可冻结等待，不增第三物理引用。视频仅在真实帧边界有完整预取资格时采用，旧像素流水/行缓存/serializer及对应borrow真退休后归还旧引用；旧单slot稿本身不具该新容量。

INT-OP07 停止与失败。旧fire、logical_commit与物理effects先真实结账，再停止新业务。未知raw债允许独立raw CLOSE先推进；只有正确完整证明才结效果债并关闭typed服务，私有对象仍需O逐份退还。没有Q证据闭合就不开放下一epoch。

INT-OP08 统一实施。成熟版本及全部源/输入/工具/schema清单保存读回并独立复审后统一申请指定批准；获批后只在work创建真实文件，按G执行，成功到bit登记即停止。

INT-OP09 在不改变数学结果前提下优化。固定不alias的6SRC/3EDGE/3ANN/单GRAD/CLASS/QUEUE/POINT/AUX候选为84.25MiB；SLOT-JOIN将AUX明确为21typed私有＋3持久RECORD，各round64及64B guard合428928B，未覆盖完整目录/journal/动态metadata。增加全半径HIST32的512KiB段后为84.75MiB，仍是容量候选。每seed原16tile导致16次POINT距离扫描，fullHIST可一次扫描构造全域，再以原半径顺序/halo/plateau规则读回；仍逐bin21bit、r0及域外规范、真实CLEAR和封存、连续同binforward，重要结构变化须单独版本等值审查。

DENSE每θ总票≤E≤2073600<2^21，故最多一个bin有第21位；两个bin各≥2^20将令总票≥2^21，矛盾。可用16个native20×512 RAM存低20bit，每lane另用valid1/bin9记唯一高位，共160FF仅为marker。完整21bit由读地址是否命中marker重建，全部277bin合法；单bin不能第二次低20回绕。CLEAR、连续samebin最新低位/marker、16票组原子可见、重复接纳拒绝与失败effects仍需逐沿合同；遇第二高位或计数超E为真实INVARIANT。它比逐票外存更新有提速潜力，但16bank不是16票/沿证据，旧逐组req→rsp的停顿与NUM/POINT吞吐仍必须计入。当前R4R数学/端口不默改，完整设计选择由新性能稿与后续联合版本决定。

## F. 语言、独立参考与数值/时间对应

SV2009候选。RTL保持沿前真实fire、旧状态计算/沿后提交，时序非阻塞、组合完整阻塞、明确signed/扩位/RNE/floor/饱和；每局部F仍是具体数值权威，不以本总述代替。

独立数学参考职责：直接整图RGB灰度、普通九值排序、每级各自复制边界的卷积、明确方向/NMS/双阈值；独立集合BFS从强种子得到全N边缘。几何参考从原image/profile和独立GT测量候选/支撑/量化误差，不能把DUT日志当真实目标。

协议参考独立记录req、rsp、read capture、logical_commit、raw effects、phase、close、typed terminal和pin return，按完整身份匹配；最终数值相同不能代时序正确。PC bytes服务只storage，不计算candidate、CLASS、DENSE、TLS、ANN或token。

质量评价按每类P/R≥95%、同类IoU≥0.5的最大基数一对一匹配，失败或容量图保留在分母/失败统计；数据开发与独立验收划分、种子/原图/GT摘要先冻结，旋转、重叠、缺边、噪声、负样本均为测量轴，不能重置已撤回的场景硬界限。完整fixtures/GT算法/样本数仍INT-B05。

时钟暂不混用25MHz局部观察、RAW27MHz候选与100MHz预算；共同core及生产多个相关clock由真实资源/IO设计确定。同步器窄例外、真实generated clock和CDC保持按具体层级约束，不把全端口/全clock组false_path当通过。

## G. 文件职责、实施顺序及验证矩阵（未生成/未运行）

工作根仍为 _fpga_edge_agent/work/active/track4_algorithms_20261004/，当前不存在。以下为整包候选文件组，不是假称已经完成的源码/精确冻结清单；现R1/FE/R2 FILES的逐文件合同原样引用，其余具体模块内部由对应新局部冻结。

| 文件组/候选核心路径 | 责任及阅读次序 | 要求/接口和测试 |
|---|---|---|
| rtl/common/track4_types_pkg.sv、ram10_bank.sv、reset_sync.sv | 共同schema、真native端口、复位；先读每个type命名字段，再读owner | 全D/F，T01/T02/T08 |
| rtl/frontend/原六文件；rtl/r1/现五文件 | 单FE、中值/灰度/原Sobel及局部观察；原R1/FRONTEND清单展开后不新增第二核 | INT-04，IF02，T01/T02 |
| rtl/r2/现13文件 | C0/Gaussian/gradient/fork/NMS/class、R2局部观察；R2 FILES准确路径为来源 | IF02，T01/T02/T03 |
| rtl/r3/numeric_core.sv、numeric_rom.sv | typed算术/乘除根/LS/TLS/ROM、cancel/quiet；内部职责须进一步映射 | IF05，T04 |
| rtl/storage/object_directory.sv、byte_authorizer.sv、atomic_journal.sv、typed_store.sv、raw_adapter.sv | descriptor/pin/权限、bytes/RMW/latest、所有原子组/phase/close | IF03/04/06/07，T05/T06 |
| rtl/storage/source_bootstrap.sv、grad_collector.sv、plane_provider.sv | 实际SRC/GRAD全覆盖、immutable读回和真实return | IF02/08/09，T02/T05/T07 |
| rtl/closure/class_loader.sv、hysteresis_controller.sv | LC→精确BFS→全EDGE→真实close | IF03，T03/T05/T06 |
| rtl/recognition/recognition_controller.sv、point_builder.sv、circle_engine.sv、rectangle_engine.sv、verify_dedup.sv、annotation_engine.sv | 全RC阶段/核验/排序/去重/光栅/records；不是PC计算 | IF04/05，T04/T07/T09 |
| rtl/control/config_owner.sv、key_events.sv、job_dispatcher.sv、epoch_reset.sv | D/P/C、手势、单J、QUIET与授权，增量桥端口需联合版本 | IF01/08/11，T02/T06 |
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
| B02 | RAW两处reset/postcommit journal文字反例已独立复核关闭；typed原子/目录/SOURCE/GRAD完整内部仍未闭合 | 引用最终7704稿及7D08审阅；继续完整FSM/OP/目录退休冻结，不能以两反例关闭覆盖生产 |
| B03 | CAMERA/VIDEO多域、最坏服务、三结果/两物理bundle路由的实际实体、真实pin/完整约束尚缺 | SLOT-JOIN明确6/3候选与两物理引用界；继续核SC431HAI v7、板载DDR、完整RGB/bulk事件和期限，不把RAW8参考直接当RGB888 |
| B04 | 共享/复用真实生命周期、全部native RAM10/FF/DSP/PLL与后端周期未冻结 | 新性能稿、地址/packing/RMW/仲裁/时间表，不用旧局部225RAM/100MHz数字当实测 |
| B05 | 所有接口完整字段、Δ01…08联合版本、profile/fixture/GT/确切文件与期限未冻结 | 本稿D/G作为组合入口，完成共享registry与独立复审；不以标题齐全关闭 |
| B06 | 指定版本整包实施批准、work/构建审批、正式DB前置仍未满足 | 设计成熟后一次提交具体范围/基线和必要治理条件；不预写代码或更改权限 |

规范10.3整体范围/职责/候选接口、操作/验证/追踪已有内容；真实依赖/完整局部/资源/文件基线仍未闭合，⑧无阻塞不满足。保持NOT_READY，不申请批准未成熟整包。

## J. 变更与恢复

本稿v0.2纳入用户最新明确允许板载DDR3的回复，保持只用板卡现有资源、高指标和低指标撤回。旧无DDR边界保存在v0.1快照；旧VIEW扩展集中映射到CONTROL/REPLAY，未默改其旧接口。DDR后端、clock、并发、双bundle、程序ANN或GRAD重算均影响设计边界，先修订相应REQ/IF/OP/TEST并复审，批准后的变化按规范处理。

v0.3补已保存PERF/PIO/HDK证据、实际有限工具结果和arena/descriptor不同容量迁移；旧v0.2 BE685C171962C59EA0B6F3768BA1B5B691FA8D07D1EA45DD015C124964029DF1/32057B保存在`design-TRACK4-ALGORITHM-INTEGRATION-001-v0.2-before-ip-precheck.md`。限定组合审阅C7A63AABC9B53CA8673F5FA06AAA08942480B78AD7EBE72715134087FFFC1E7D绑定旧BE685，不说已审完v0.3；本次来源/实测追加不将整包升级READY。

## K. 本轮实录

v0.5纳入SLOT-JOIN v0.1与11,516B纯数据布局9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75：容量选择、21private计数、AUX子对象/guard、显式SOURCE_OFFER182、信用及辅助记录候选已写明；真正接口/实体/全机资源仍OPEN。v0.4的9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3/36816B保留于before-slot-join快照；旧审閱不冒称覆盖本版或联合稿全部变化。

[SLOT-JOIN实际限定复核](../experiments/track4_algorithms_20261004/03_review/slot-join-review-v0.1.md)分别绑定7711全文/9B4布局、E9新增数值及协议全文、6BC最后OP04分支修订。数值计数/地址相等；实际信用结束遗漏与VIEW串行文字歧义已补清、限定读回未发现新矛盾。没有协议仿真或物理工具新证据，未关闭B01…06。

v0.4仅同步v1.2实际终态及PIO时钟物理阻塞；v0.3精确快照D2E0CF383B2D8EEA790A4F9D2DD0BADC6837244781F78AD7AD822759CCDAF0D5/35665B保存在design-TRACK4-ALGORITHM-INTEGRATION-001-v0.3-before-ip-terminal.md。旧独立审查不冒称覆盖本版全部新增段落。

整包仍纯设计，无新增算法实现/功能runner/模型/TB或整包工程/SDC。获批有限预检实际map/debug/PT/PNR/vlog终态见A2，PNR失败、无STA/bit；没有设备/网络/安装。Manifest只追加实际批准的有限预检记录，原HDK、正式状态和数据库未改。整包仍NOT_READY/NOT_APPROVED，不能把有限实验终态当完整实现完成。

## L. 中文阅读与交付边界

先看B五类关闭条件→C谁拥有何数据→D接口目录与差异→E正常/失败及生命周期→F参考角色→G文件/验证→H追踪→I具体缺口。文档完成度、业务实现度、软件验证和实机验证分别陈述。当前交付为整合候选；不足之处已定位，不声称五类全部完成或已证明整机可实现。
