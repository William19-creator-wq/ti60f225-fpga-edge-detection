# TRACK4-IP-PRECHECK-001 v1：现有DDR/CSI/显示IP的有限工具预检

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。这是完整十一功能工程的输入证据预检，最终目标仍为完整软件/仿真/综合/合理约束/PNR/STA/bit；本实验不能替代整机交付。**APPROVED v1 / TERMINAL_WITH_FAILURES（有限预检）**。用户已明确批准v1、IP-PRECHECK-BL-v1、C0–C3及本次本地审计例外，见[实际批准记录](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approval-v1.md)。以下设计条款及矩阵保持批准时原意；原版hash与快照保留。批准前的未执行表述为历史截面，后续真实执行及终态在K关联实录中逐项记录。

## 通用计划字段

- Goal：用已有工具查明旧DDR ASYN0是否实际去桥、当前CSI实际综合资源与相关clock可布局性；为完整预算提供当前证据。
- Current state：公开源只固定外部参数/拓扑；旧map DDR39包含桥17，不能直接声称ASYN0为22；CSI protected内部RAM/PPC未知。
- Target state：四个固定参考案例的独立副本、输入/差异/命令/资源/警告/clock报告及结论，成功和失败都可定位。
- Gap / Open questions：保护IP实际结果是实验被测量，不作为已有正确性事实；工具许可、数据库和指定运行批准为执行前置。
- Assumptions：软件参考Ti60F225/I3/V4；无实体编程/相机观察。本实验不将4Gb模型当匹配2Gb。
- Dependencies：A中的输入与原审批；批准后仅用现装Efinity2026.1.132/Questa2024.1，不下载/安装/联网。
- Milestones / Detailed steps：保存读回/审阅→指定批准及正式运行前置→源hash复核/副本→C0/C1/C2/C3顺序→编译/资源/clock报告→整机设计选择。
- State transitions：只记录本实验设计/报告；不改变正式H0，不因预检通过标完整功能通过。
- Artifacts and hashes：输入manifest、四case差异、完整工具日志/报告/产物hash；实际结果待执行。
- Validation：G六文字场景，工具结果与物理功能/器件校准分别记录。
- Failure handling：输入漂移、许可/版本/blackbox/缺文件或输出不可解释时停该case、保留失败；不静默替换IP或删保护检查。
- Human approval gates：v0.2指定本v1/范围/IP-PRECHECK-BL-v1；工作副本/工程/约束/构建和artifact复制包含在所申请的具体范围，正式DB前置仍核验。
- Rollback：保留源和审计；撤销只涉及本次独立工作目录，不动原HDK/工具/正式状态，不自动清理已有任务。
- Completion criteria：四case各有真实终态及限定结论；并不意味着十一功能、PHY校准、质量或bit完成。

## A. 范围、基线与审批

基线IP-PRECHECK-BL-v1见[输入manifest](../experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.json)：v1 XML66项design引用与89份实际项目/RTL/约束/IP设置/头/初始化/debug输入，无必需引用缺失；v6 archive SHA45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C。v6实际60引用与archive成员来源沿现01证据，批准后解包时再逐项核对，不冒称本轮重新对全部archive成员运行hash。

| 关键源 | SHA256 |
|---|---|
| v1 project ti60f225_oob.xml | 571E5A03A7CCC46D2B15CF9D3DCAAA1BC1A874CB3E0908330599891457867BE8 |
| v1 peri | 9D378EFF67AC34F88F78A41341A1451E8F3B87B246434DDEDA12C7295A100CAE |
| v1 SDC | 18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E |
| v1 DDR parameter | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 |
| DDR top/bridge/PHY | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A / 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D / 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B |
| 原规则v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| LOCAL_TOOL_PATHS | 46764CF7FF64ECAACF869960527A7785327B5217F2A08FEB0203C608EC14382E |

工作路径仅为控制面work/active/track4_ip_precheck_20261004/C0…C3，报告为experiments/track4_full_sw_20261004/05_reviews/ip-precheck/，来源记录01。当前目录尚未创建。没有批准业务算法实现、完整测试/TB、模型修改、下载/安装、DB迁移/写入、硬件下载/Flash/调试。现有FRONTEND与模型请求各自PENDING，不能把本批准推及它们。

## B. 外部行为与六项要求

保留现有参考实际连接的数据路径及IP输入/输出可达性，不能额外把输入常0或删除已接输出，让综合优化掉内部存储后当成省额。v6原本未接PPC/DT/WC/VC/IRQ及丢弃RAW10低2bit，本实验不补新observer/业务连接；C2/C3资源只代表当前reference连接，不能当完整NORM所需IP的上界/全部预算，未观察部分仍UNKNOWN而非0。实验输出是编译/层级资源/接口及clock证据，不是视频/算法结果。

| REQ | 可检查行为 |
|---|---|
| IP-REQ01 | 原资料只读、独立case、输入/差异/hash可恢复，版本不会混用。 |
| IP-REQ02 | C0旧ASYN1与C1同步ASYN0只按D的指定delta比较，bridge下降是否实际发生由新map决定。 |
| IP-REQ03 | C2/C3使用v6实际XML引用CSI5.15/FIFO1024/70/core100/Discontinuous/pack15，不能换旁置5.16/50设置。 |
| IP-REQ04 | PHY校准clock、同域业务net、reset及V4引脚保持可解释，错误例外/未约束路径明确报告。 |
| IP-REQ05 | 仿真编译兼容、资源、PT/PNR/STA及DDR器件行为证据分开，不由小实验称整机已通过。 |
| IP-REQ06 | 真实批准/DB/工具许可未满足时不执行；失败不自动联网/升级/改模型。 |

正常例C0新工具完整编译并给层级map，与旧39/17/36/2只作版本对照；边界例C1仍保留桥，记录实际数值而非预期减17；失败例C2 protected key不能编译或clock来源与配置冲突，保留原输入与失败，不改黑盒/时钟例外伪通过。

## C. 职责与全路径

MOD-INPUT负责源hash/只读来源及case副本；MOD-CASE保留参考top/数据路径并只实施D的delta；MOD-TOOLS使用现装工具编译/接口生成/综合与PT/PNR/STA；MOD-REPORT读取完整日志及层级，区分FF/LUT/ADD/SRL/DSP/RAM和父子包含。输入→case→工具→报告→全机设计决策，失败也沿同一身份回传。无新运行期互连/业务协议；图像通道继承所冻结参考源，不用此实验替代NORM/DS设计。

## D. 案例、接口和组合检查

| case | 冻结输入和唯一允许变化 | 输出与比较 |
|---|---|---|
| C0 | v1原Ti60F225/I3工程独立副本，保留全部被引用RTL/IP/peri/SDC与debug设置；只更新工作路径及当前工具必需格式 | 当前工具实际baseline或明确兼容失败；不得无声关闭debug/删logic |
| C1 | C0，ASYN_AXI_CLK1→0；axi/core/原core业务全部改接DDR3_PLL固定#4同一100MHz net；相应core分布rclk→工具支持的gclk候选及SDC实际同net约束 | 同DDR30/128/ID4、CK_RATIO4、tCK2500；比较DDR/bridge及全参考资源、clock可布局性 |
| C2 | v6实际XML及被引用文件/peri/SDC独立副本；使用实际CSI5.15源，不生成旁置settings版；先原样编译/综合，再按真实peri修正clock声明并保存差异 | 当前CSI层级、实际clock报告、PPC仍只按可观察/官方定义报告，不由FIFO容量推断 |
| C3 | C2加C1同样ASYN0/统一core net delta；其余版本/输入保留 | 实际合并IP开销与clock风险，不能用v1新CSI或旁置版本替代 |

C0 baseline兼容失败时C1不继续推断桥省额；C2修正基线编译失败时C3不继续推断CSI资源。C2.original保留原样编译/综合终态及输入hash；C2.clock-corrected按实际peri/net记录有限SDC修正后重新冻结输入，重新编译/接口生成/综合和下游PT/PNR/STA，不能让旧综合与新SDC报告混用。C3仅从已冻结C2.clock-corrected派生。只允许记录失败，不擅自改变此矩阵。格式适配不得影响逻辑/参数；需要其它改变先修订本设计。

IP-IF01源→副本为原字节文件/manifest，hash匹配才进入；IP-IF02 case→工具为同一case project/peri/SDC/RTL及输出目录，禁止outflow交叉覆盖；IP-IF03工具→报告为退出码/完整日志/层级/clock与资源，缺项是UNKNOWN；IP-IF04报告→整机为case/版本/delta/证据/限制，仅提供输入证据，不自动选择新架构。

core正沿/DDR100与400MHz校准路径沿真实源；C1/C3同100MHz频率并不等价于同net，必须实际改接#4。不得删除400MHz校准派生或把它false-async于真实core；v1/v6旧SDC的错误同名/例外先报告，修正范围限实际net关系/生成时钟而非降低所需频率。器件/BankIO只V4，不引入VF引脚。reset改接只做原同步释放链迁移到新core；不创造新warm-reset协议，也不宣称ASYN0内部reset已经知道。

本稿所有“接口生成”仅指PT外围接口产物生成；禁止按settings重生成/升级既有CSI/DSI/DDR protected IP。v1 XML的ip_info与5.6 settings保留冻结源；若现装工具必须自动再生成该IP，停止相应case为AUTO_IP_REGEN_REQUIRED，不用旁置/新版本替代。每个phase结束检查冻结RTL/IP hash仍符合允许delta。

原XML虽配置generate_bit=on/generate_hex=on，本实验只选择编译/展开、PT外围、综合、PNR/STA的明确阶段命令，禁止完整bitstream flow；保存真实阶段命令/终态，不进入bit/hex生成。若工具不能只执行这些阶段则停止，不扩大批准范围。

不得依据HS_BYTECLK_MHZ70直接把外部byte约束100改成70。只按可证明的实际peri/PLL/net关系修正；外部实际频率仍未知时标CLOCK_UNRESOLVED，相关约束不伪补，C2.clock-corrected/PT/PNR/STA或依赖C3标未执行/依赖失败；原样编译/综合证据仍保留。C1/C3比较是ASYN参数与统一clock迁移的组合差异，不能把全部变化单独归因于ASYN。

Questa只编译/展开被引用公开及protected DUT/厂商原语，检查当前语言/key兼容，不生成激励/TB、不用4Gb器件包运行2Gb校准。PPC/错误归属或有限service若仍不可见，结果仍UNKNOWN并指出所需下一实验；本次范围不偷偷扩到协议仿真。PT/PNR只用于参考case，不生成bit/hex、不操作硬件。

## E. 中文操作草图

IP-OP01：先核指定批准及DB/工具运行前置→重hash输入/检查目标无冲突→逐case独立副本/解包→核引用与来源→保存差异。原源及旧outflow不写入；已有目标不覆盖。

IP-OP02：C0编译/接口生成→综合→PT/PNR/STA→保存完整层级及各阶段终态；C0终态成功才建立C1 delta，同net#4/原400MHz/对应reset和约束逐连接检查→执行同样编译/接口生成/综合/PT/PNR/STA阶段→比较层级与父子包含。bridge不减或报错也如实报告，不把设定ASYN0当测量结果。

IP-OP03：按v6实际XML保留CSI引用/参数→C2.original编译/综合与完整终态→读实际clock/net，SDC与真实源冲突先列出→C2.clock-corrected保存有限修正/冻结新输入hash→重新编译/接口生成/综合/PT/PNR/STA→C3从此冻结基线实施同步delta并跑同样全阶段。不开未授权后续测试，未知吞吐留原阻塞。

IP-OP04：每case及C2两个revision分别读取退出码/完整日志；C0/C1/C2.clock-corrected/C3目标是完整map/层级/clock/约束/PT/PNR/STA，C2.original仅原样编译/综合。失败阶段后的报告标NOT_RUN、依赖失败跳过标SKIPPED_DEPENDENCY，不能拿先前revision补缺；不将层级子RAM重复加父、不把缺失protected/优化消失记0、不由compile或旧pass标新功能通过。保存输入/差异/工具版本/产物hash，返回整体预算与选择点。取消停止新阶段，已启动工具以真实handle确认终态，保留输出，不仅凭超时重启。

## F. 语言、时间和实现合同

不新增C++/算法参考/测试；复用SV_09/VHDL2008工程和现有Verilog/SV protected源，Questa接受与否是实测结果。没有新数值/尺寸/像素变换。RAW10/DDR及serializer外部端口由冻结case源码定义，不能凭同名换版本；接口类型/宽度变更超本范围。

| RTL项 | 本实验合同/适用性 |
|---|---|
| A数值 | DDR30/128/ID4、ROW14/COL10/BANK3/DQ16、CK_RATIO4保持；没有新算术或像素截断 |
| B观察/C事件 | 不新增RTL激励，编译/展开不提供握手行为证据；工具阶段退出及日志才是本实验观察 |
| D/E/F推进 | 参考显式算法流水/协议不主动改动；C1/C3改时钟net及ASYN参数，IP内部缓冲/握手/延迟差异未测，不宣称事务等价；STA通过只支持该case实现 |
| G/H复位配置 | 原reset同步释放迁移；参数按case静态冻结，不引入运行时ASYN切换 |
| I/J存储身份 | 全参考真实可达输入/输出保留，资源由层级归属读取；case名称标全部文件/报告 |
| K CDC | 同net/真实派生关系检查，不用频率相等猜CDC或削除约束 |
| L实现 | 现装Ti60F225/I3工具；保护版本/key/原语/clock可布局性是本实验结果，不能预测PASS |

跨语言共同数学/硬件逐事务映射N/A：没有生成数学模型或比较事务；RTL工具输出→case/source hash/delta精确对应。处理fps、P/R、2Gb校准和整机服务全部留原任务，不宣称完成。

## G. 设计时实施与验证计划（历史截面；实际见K）

批准后按OP01→C0/C1→C2/C3→OP04，仅独立副本内项目/参数/clock/约束有限修改及现有工具运行。不得生成业务算法、功能脚本或可执行测试/TB。运行命令在批准后依现装CLI与原工程实际检查记录，不在设计内编造已经执行的命令。

| TEST | 对象/场景 | 期望/方法 | 状态 |
|---|---|---|---|
| IP-T01 | 输入漂移/目标冲突/源只读 | hash不同或已有非同源内容停止，原源不变 | NOT_RUN |
| IP-T02 | C0/C1保护编译与资源 | actual map分别列DDR父/桥子、SRL/RAM/FF，不预判省17 | NOT_RUN |
| IP-T03 | C2/C3实际CSI引用 | 5.15/1024/70参数及源保持，旁置5.16未混入，actual层级 | NOT_RUN |
| IP-T04 | core#4、400校准、rclk/gclk/reset及SDC | 真实net/派生/可布局路径及所有警告报告，不用错误例外通过 | NOT_RUN |
| IP-T05 | 缺key/原语/debug/许可/DB | 真实失败/未执行，不删除检查或自动下载；无器件校准PASS | NOT_RUN |
| IP-T06 | 层级/报告/取消恢复 | case/source/delta/handle/退出码/hash对应，父子不重复，未终态不误重启 | NOT_RUN |

## H. 设计时双向追踪（历史截面；实际见K）

| REQ | MOD/IF/OP | 计划修改职责 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| IP-REQ01 | INPUT/IF01/OP01 | 参考副本输入与manifest | T01/T06 | 未创建/未运行 |
| IP-REQ02 | CASE/IF02/OP02 | C1/C3参数与同net迁移 | T02/T04 | 未修改 |
| IP-REQ03 | CASE/IF02/OP03 | C2/C3实际引用保持 | T03 | 未修改 |
| IP-REQ04 | CASE/TOOLS/IF02/OP02/03 | 有限clock/reset/SDC delta | T04 | 未运行 |
| IP-REQ05 | REPORT/IF03/04/OP04 | 当前工具资源/限制 | T02…06 | NOT_RUN |
| IP-REQ06 | INPUT/TOOLS/OP01/04 | 指定批准与正式前置 | T05/T06 | NOT_APPROVED |

反向：任何新增修改须落在case delta和上述REQ；不能临时引入算法/TB/更换IP来凑成功。

## I. 门槛、批准与执行前置

①外部行为/样例B；②职责/来源A/C；③四case/四IF与差异D；④四OP E；⑤语言/时间F；⑥设计反例B/D；⑦实施/六文字场景/追踪G/H；⑧测量未知明确作为实验输出，不声称已解决全机；⑨实际保存读回/呈现与两方向限定审阅及其修正由05登记；⑩v1/IP-PRECHECK-BL-v1与具体路径A。本有限范围达到READY_FOR_REVIEW，等待指定v1、IP-PRECHECK-BL-v1及A/D范围批准；root最终全文读回与原版限定审查区分，不能称所有审阅者审完最终稿。

正式数据库未配置、现有工具许可和本范围指定批准仍为执行前置。批准设计不自动建立DB、不更新Manifest；执行时按既有制度核验和记录。未批准前不复制/改RTL/IP/project/constraints或运行工具。此实验READY不升级整机READY，尚未运行的六验证场景是批准后义务。

## J. 差异与恢复

仅C1/C3的ASYN参数、core统一net/分布/reset同步链和相应SDC，C2实际source明确及真实clock约束纠正，C0必需格式/工作路径。任何不同源/宽度/位序/功能变更先停该case并修订。恢复读批准、manifest、已保存delta和真实工具handle；同版本有效批准不重复索取。

## K. 实录

2026-10-04：实际批准原文“批准上述预检和本地审计例外”，批准ID AP-IP-PRECHECK-20261004-v1；源问题明确v1/IP-PRECHECK-BL-v1/89输入/C0–C3。批准设计hash `130481D499D68F4F2F43C6C6731D0E088E4333D4B701C22E1E37C2CCD65BD2E8`，基线manifesthash `1B336732334C4453FEA720351FF45910B0D9367B1089C4A89713815CCE790DC3`。89/89源文件重新hash匹配。已将范围批准及仅本预检的数据库前置例外追加既有Manifest；未改正式DB、PROJECT_STATE和硬件节点。后续运行以同目录 `05_reviews/ip-precheck/` 日志与实录为准；此记录不批准整机算法实现。

后续用户明确批准v1.1/91输入及v1.2/92输入，原字节快照和问答均保存。实际终态为：C0 attempt3 map、官方debug生成/合并及PT通过，PNR在packer因原USER1 TDI/TDO缺失失败，placement未到达、route/STA未运行；C0/C2 Questa厂商模型编译通过、CSI无解密key导致DUT编译失败。C2.original map通过；C1因C0未成功跳过，另有Ti60 PLL#4固定regional的独立设计阻塞；C2.clock-corrected仍CLOCK_UNRESOLVED，C3依赖跳过。详见[最终运行记录](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)及case-status。有限预检已按停止条件收束为TERMINAL_WITH_FAILURES，不是整机或硬件通过。bit/hex数量0、正式状态/DB不改；本实验不满足完整十一项软件目标。

## L. 阅读与交付

先B/C理解测什么→D四case和允许delta→E操作次序→F证据边界→G/H验证/追踪→I原审批。完整工具报告回到整体资源/时钟设计，不能把实验简化成最终工程。实际阅读/理解验收待用户反馈，不把讲解当用户已批准。
