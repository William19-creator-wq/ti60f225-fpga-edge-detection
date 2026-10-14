# TRACK4-IP-PRECHECK-001 v1.2：C0可见输入闭包复核与原Panel初始化文件补入短卡

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)的小修复短卡。**READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN（v1.2）**。本卡仅把C0/C1输入集合从91份修订为92份，新增原工程根目录的一份初始化文件；完整外部行为、C0–C3矩阵、保护IP限制、工具阶段和本地审计/DB例外及其条件继续采用[已批准v1设计](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approved-design-v1.md)与[已批准v1.1输入修订](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approved-design-v1.1.md)。本次没有修改work或执行工具，不能把此前批准自动扩为92输入批准。

## A. 状态、通用计划字段与阅读入口

- Goal / Target：一次复核当前C0公开源码和可见实例的输入闭包，补入已存在、被当前顶层实际选择的原Panel文件，随后在指定批准范围内重新取得C0真实工具终态。
- Current / Gap：89输入的attempt1已FAIL；获准加入两个I²C头文件后，91输入的attempt2再次真实FAIL/exit1，原因是无法打开`Panel_1080p_reg.mem`。这不是DDR保护IP不可综合的证据。
- Assumptions：原源只读，恢复原字节和相对位置，不修改Panel命令、RAM参数或业务逻辑。可见文本闭包审计不等于已通过map或已解读全部保护实现体。
- Open questions：92输入尚未获批/复制/重试；保护key、工具私有依赖、既有debugger正常生成及clock结果是原有限实验仍须实测的结果，不能以本卡预判成功。未发现阻塞本次一文件输入修订的第二个可见缺失输入。
- Dependencies / Baseline：IP-PRECHECK-BL-v1.2为原91条输入记录逐项不变＋本卡新增Panel文件，共92份，合计2,876,787B；XML仍66条design_file、两个声明IP源，语言/器件/原debug设置保持。
- Milestones / Detailed steps：完整只读调查→92候选JSON与本卡保存/全文读回→用户指定批准v1.2/92基线→仅在C0工作副本补原Panel字节并冻结delta→重新map及原获准明确阶段→每阶段保存真实终态/报告；C1只从成功C0派生。
- State transitions：仅本卡设计状态READY_FOR_REVIEW，批准状态NOT_APPROVED，v1.2执行NOT_RUN；不改变H0、正式状态或数据库。v1/v1.1已有失败继续保留。
- Artifacts and hashes：本卡、[92输入候选JSON](../experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.2.json)。候选JSON SHA256 `B0710CECE3681230CE042F9D1B74933ABE1B103011258415FD67D28D9E13F391`，41,682B。原91清单SHA256 `2333F4B42836EDC58B7F8083D0044542BFF8D2C9D375698F9A609C0C1A144AEC`；原89清单SHA256 `1B336732334C4453FEA720351FF45910B0D9367B1089C4A89713815CCE790DC3`。
- Validation：本轮只读逐文件长度/SHA复核和公开依赖/实例走查已完成；获批后的92输入副本、map/接口生成/PNR/STA另作真实验证，不预填PASS。
- Failure handling：源或副本漂移、目标冲突、新缺文件、保护key/原语/debug/clock错误均保留实际失败；不静默添文件、关debug、改profile连接或重生成现有保护IP。需要超出本卡变化时停止受影响case。
- Human approval gates：等待明确批准本卡v1.2、IP-PRECHECK-BL-v1.2/92及一文件补入与原矩阵继续；原v1已经批准的本地审计/DB例外及其条件不变，不把它说成正式DB健康或已登记。
- Rollback：保留原89/91清单、批准快照、两次失败及新候选；仅恢复本次获准work差异，不动原HDK，不自动删除日志或其它工作。
- Completion criteria：本次交付是可评审输入修订。批准后只有各阶段取得真实终态/产物/限制才可报告本有限预检结果；不表示完整十一功能、仿真行为、器件校准、bit/hex或硬件完成。

读取顺序为A当前范围→B整体行为→C/D闭包证据与组合→E中文恢复步骤→G/H验证与追踪→I指定批准边界。原批准设计v1 SHA256 `130481D499D68F4F2F43C6C6731D0E088E4333D4B701C22E1E37C2CCD65BD2E8`；原批准v1.1快照SHA256 `07EA95A4E266DF270835827800546C5B71FF305D9EA0CF3953881A59807790CC`。实际v1.1批准见[approval-v1.1](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approval-v1.1.md)；本卡没有新的用户批准来源。

## B. 被修正的整体行为与要求

IP-REQ01/IP-IF01要求独立副本包含本病例真实输入。候选变化只恢复原参考设计已经要求的文件读取：工具从C0工程根找到Panel文件，按原实例参数展开；不改变图像输入范围、DDR/CSI/显示行为或算法需求。IP-REQ05/06仍要求报告退出码、真实阶段、源版本和限制，失败不由历史pass或旧生成物替代。

正常样例：指定批准后，92份来源与副本长度/hash一致；顶层选择的Panel文件在同名根路径存在，map可读取它。预期是消除这一明确的缺文件条件；后续成功或其它失败由实际工具决定。边界样例：Panel源或副本hash不同，即使basename相同也停止，不接受另一HDK或另一Panel内容。错误样例：工具仍要求升级保护IP或改变debug连接，记录真实错误并停止该case，不以补一份MEM的批准扩为任意修复。

## C. 模块职责与整体交接

MOD-INPUT拥有输入路径/长度/hash/差异证据，新增且只新增原Panel记录；MOD-CASE保持同一C0逻辑和原矩阵；MOD-TOOLS在获批后运行现装工具的明确阶段；MOD-REPORT保存每attempt输入身份、handle、退出码、完整日志与产物。交接仍为原源→IP-IF01独立副本→IP-IF02本病例工具→IP-IF03报告→IP-IF04整体预算。没有新增运行期RTL接口、反馈环、C++对象或业务实现。

## D. 接口、完整可见依赖审计与组合检查

新增原文件必须复制到`C0/Panel_1080p_reg.mem`，保留basename、原字节与工程根相对位置，不移到`rtl/cam`，不编辑XML、顶层或RAM的路径/参数。

| 新增原输入（相对source_root） | 长度B | SHA256 | 91清单 / 当前C0工作副本 |
|---|---:|---|---|
| Panel_1080p_reg.mem | 4051 | 1B192B20B57BDA019D39B24126789C582AE5DA0B9DF5395152854A8C2C4576B7 | 未包含 / 不存在 |

本轮实际source_root为原`Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1`，不能暗换0927更新包或v6来源。实际逐项读取91份原源与当前`work/active/track4_ip_precheck_20261004/C0`副本，91项长度和SHA256各自与清单全部匹配，0缺失、0漂移；两份新增I²C头文件已在91中。原91合计2,872,736B；新增4051B后92合计2,876,787B。

审计范围为XML全部66条design_file、`ip_info`声明的`csi_rx_controller.sv`/`dsi_tx.sv`两个源、清单内全部77份HDL/头/模板文本的公开include/readmem/文件参数，另扫描source_root内未生成辅助源码并核对它们是否被本XML/实例选择。SDC/peri的可见外部source/read_sdc/初始化路径和三个JSON也已检查。原XML的66条引用无清单遗漏，当前`sim_info`为空。以下是本病例全部可见文件读取类别的结果：

| 类别与源位置 | 当前解析值及活动性 | 原文件/91清单/工作副本结论 |
|---|---|---|
| 顶层`rtl/ti60f225_oob_top.v:781–786`的`inst_panel_config`→`rtl/mipi_config/panel_config.v:60–70`的`inst_piv2_reg`→`rtl/true_dual_port_ram.v:47–52` | 顶层783明确`INITIAL_CODE="Panel_1080p_reg.mem"`、REG_DEPTH150；RAM收到相同字符串、DATA_WIDTH40/ADDR_WIDTH9即512深；RADIX默认HEX，非空后执行readmemh | 唯一新发现的活动可见缺项，本卡补原根文件 |
| I²C `i2c_master_bit_ctrl.v:141/144`、`byte_ctrl.v:83/86`、`top.v:87/90` | 共六条真实include，分别读timescale.v、i2c_master_defines.v；timescale位于translate_off区，但此前实际工具仍要求预处理该文件，不能据此删输入 | 两份原文件均存在且已在91/工作副本，hash匹配；头内未发现其它include链 |
| 顶层15与`rtl/ddr3_controller/ddr3_top.v:22` | 两条include均解析至`rtl/ddr3_controller/ddr3_parameter.vh` | 原文件存在且在91/工作副本，hash匹配，无额外include |
| `rtl/true_dual_port_ram.v:22`默认ram_init_file.mem；`panel_config.v:3`默认NT35596_1080p_reg.mem | Panel实例分别用传入Panel覆盖两个默认；另一个公开true-dual RAM实例为`rtl/debayer/line_buffer.v:88–96`，96明确传空字符串，不读取文件 | 不把未生效默认的basename文件从其它目录添入本病例，也不改默认值；91已有深目录MEM继续保留 |
| `rtl/simple_dual_port_ram.v:19/39–44`、`user_dual_port_ram.v:25/45–47`、`dual_clock_fifo.v:19/252/84/121/159/196/628` | simple/user/FIFO初始化默认均为空；FIFO内部仅传递此参数。公开图无wrapper/user的外部实例，无其它非空覆盖或新的文件名 | 五个公开readmem调用点已逐类核查；未发现需要补入的第二个活动初始化文件 |
| `color_bar.v:32`与顶层16的video_define.v/define.v | 均为注释include，不是活动预处理指令 | 不作为缺失输入添入 |
| `ip/dsi_tx/settings.json:48–72`、CSI settings:37–43 | settings内旧绝对路径是生成输出记录；DSI66–67为`output.external_testbench_testbench`的两份MEM。当前XML只选择已有IP综合源，未选择这些TB；既有保护IP重生成仍禁止 | 两份settings和冻结IP源已在91/副本；不导入旧TB/旧驱动器路径或模板VHDL来改变本次范围 |
| 备用Sapphire/SOC、VGA颜色转换、旧相机配置、devkit及重复RAM源码 | 虽有MEM/bin/default/include文字，但未由当前66引用/两个IP选择或公开当前实例链启用 | 不把整个HDK或其它工程依赖混入C0；原91附带初始化MEM仍逐项保留不减 |
| `debug_profile.wizard.json:395–399`的debug_top.post.vdb记录 | 本病例保留冻结profile；旧work/outflow的VDB、debug_top.v是历史生成物，不能当本次新综合证据 | 官方当前debugger正常生成按既有批准阶段记录，不能把旧VDB补入92输入或修改probe/profile连接 |

统计为8条真实include、3个唯一被include文件、5个readmem调用点；77份文本的其余文件参数/条件没有发现第二个活动非空文件覆盖。源与C0根均不存在可被CLI额外默认读取的`efx_map_settings.ini`或`.config/efx.ini`；本次不创建它们。父审计与独立只读复核得到相同Panel/参数链及排除结论。该结论是**当前公开文本与可见实例链闭合**，保护实现体/工具二进制不可完全静态解读；下一map才是工具运行验证，不称“92保证任意工具不再报依赖错误”。

## E. 局部中文恢复草图与不变量

批准前仅保存本卡和候选JSON，C0工作副本不补入MEM。指定批准后：①核批准对象为v1.2/92与原矩阵；②核原89/91输入、两次失败、批准快照仍可恢复；③再次读取92原源长度/hash，发现漂移立即停止；④检查C0根目标不存在或已经是同份获准内容，冲突不覆盖；⑤仅将原Panel字节复制至同名根位置；⑥核92副本与来源逐项长度/hash，记录attempt3输入/delta；⑦执行原显式map阶段，保留真实handle直到终态；⑧按原设计保留auto-instantiation/profile、正常官方debugger及接口生成，逐阶段检查保护源/settings没有超允许delta；⑨保存本attempt完整日志/产物再进入下一阶段，任何失败停止相应case；⑩C0成功才派生C1。C2/C3按原批准矩阵独立推进，不把本92输入集合并入它们。

不变量是旧91项源记录/字节保持、唯一新增原Panel、每个工具报告绑定本attempt与真实输入、旧失败不被覆盖。不得通过补文件填造Panel数据、修改REG_DEPTH150、换HEX/BIN、关闭Panel或debug逻辑、减资源或降低clock来获得成功。

## F. 语言与映射契约

本修订是静态输入字节复制，C++/数学模型/跨语言结果映射N/A，原因是未生成或改变这些实现。RTL数值/边沿/接受交付/valid/反压/延迟/复位/配置/存储/身份/CDC/目标约束沿原v1源码保持；唯一变化是工具终于能读取原40bit/512深RAM实例的初始化文本。文件选择为原parameter在展开时生效，不新增运行期配置事务。原初始化文件内容、数量及未填地址的工具行为不在此卡修订，不补零、不扩填；功能行为仍未验证。语言仍原SV_09/VHDL2008工程；没有新业务源码、功能脚本、可执行测试或TB。

## G. 验证与实施计划

| TEST / 目标 | 输入/观察与期望来源 | 当前证据或执行前状态 |
|---|---|---|
| IP-T01 / REQ01 / INPUT–IF01 | 原91逐项不变；新增Panel只取本source_root原字节与同名根位置；92各自hash匹配 | 原91 source/work全部匹配；新增原源hash完成；92副本补入NOT_RUN |
| IP-T01-CLOSURE / IF01/02 | 从XML/公开include/readmem/实例/default/JSON逐类走查，区分活动与覆盖/注释/未引用项 | 本文D完成只读审计和独立复核；仅可见静态证据，不是运行通过 |
| IP-T02 / REQ02 / CASE–TOOLS | attempt3 map绑定92身份；消除Panel缺失条件，真实退出码/层级决定结果 | 89 attempt1 FAIL、91 attempt2 FAIL；92 attempt3 NOT_RUN |
| IP-T05/T06 / REQ05/06 / REPORT | 保存旧两次失败和每阶段证据；key/debug/IP升级/clock未知不绕过，不生成bit/hex | 旧日志保留；v1.2下游工具阶段NOT_RUN |
| IP-T01-DRIFT / IF01 | 新MEM或旧91任何字节不同/目标冲突时停，不接受同名异源 | 文字边界场景；没有生成或执行测试代码 |

下一实施入口只在获批后向C0根补一份原文件及记录本attempt，既有矩阵、许可/本地审计例外和保护IP停止条件不变。

## H. 双向追踪

IP-REQ01→MOD-INPUT→IF01→E③–⑥→原`Panel_1080p_reg.mem`复制计划→IP-T01/IP-T01-CLOSURE；反向Panel输入来自顶层783/Panel68/RAM52的实际参数链。IP-REQ05/06→MOD-TOOLS/REPORT→IF02/03→E⑦–⑩→IP-T02/T05/T06；反向每个报告必须能返回case/attempt/输入版本及真实阶段，不使用旧生成物补证。所有新增文档/JSON条目只服务输入修订；没有其它业务改动入口。

## I. 设计门槛与批准边界

十项自查依据为①B外部行为与样例；②C职责与复用边界；③D源→副本/参数链组合；④E可检查步骤/不变量；⑤F适用RTL契约不变及N/A理由；⑥D/G正常/覆盖/失败走查；⑦G/H顺序、验证、追踪；⑧唯一可见缺项已找到原源，工具内部未知是原实验结果，不隐补；⑨两文件实际保存/全文读回后呈现；⑩v1.2/92、只一文件delta及原矩阵明确。仅本次输入修订READY_FOR_REVIEW，批准状态NOT_APPROVED；整机不据此READY或通过。

原批准绑定89后修订为91；本卡将指定输入集合再变为92，依据唯一规范§11.2的批准范围变化要求，等待明确指定本版本与基线批准后才补work或重试。有效独立C2原范围无需重复批准。已有本地审计/DB例外继续按原条件，不申请新运行环境或改变正式配置。

## J. 变更与恢复

v1遗漏两个原I²C头文件已在v1.1获批恢复；v1.1未纳入顶层选择的根Panel初始化文件，本次通过全部可见依赖类别走查补唯一原MEM。92候选JSON保留原91的path/relative_path/bytes/sha256字段逐项相等，不覆盖旧清单。恢复先核批准/本卡/92清单/原失败/当前work差异；任何另一输入或行为变化另行记录和修订，不扩大本卡一文件范围。

## K. 实际记录与证据限制

本轮实际完成：按入口读规则、唯一v0.2与模板；读取原XML、91清单、公开依赖与参数/实例；逐份复核91原源/当前C0副本；核原Panel4051B/hash；分类默认/未引用/TB/旧生成物；取得独立只读审计；仅创建本卡和候选JSON并读回。实际业务修改、92副本、v1.2工具运行均NOT_RUN。

91 attempt2实际console见[C0-attempt2-map-console.log](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C0-attempt2-map-console.log)，SHA256 `97CF4AD80C97D928E990961EB74C8752D33BE3B9F3C6A1CD432F0855304D6294`，947B；其中5明确map FAIL。Panel缺文件见[C0-attempt2归档err.log](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C0-attempt2-logs/ti60f225_oob.err.log)及原RAM52定位；该err.log保留此前条目，不能把旧include错误误说成当前91副本仍缺两头文件。父Agent提供此attempt真实exit1；本子任务没有执行或重启该工具，也不改正式状态/DB。

## L. 交付与阅读说明

交付只为v1.2输入修订短卡及92纯数据清单；整体外部行为与算法/硬件要求继续按原设计，不降低完整十一项范围。读A/B理解为何补文件，读D定位顶层→Panel配置→RAM读取的选择链，读E/G了解批准后顺序和失败保留，再读I核审批对象。改变Panel内容、文件参数、IP/debug/clock或其它输入时需回到D/J记录影响并按指定版本审阅；本卡不能提供这些改变的预授权。理解验收待用户实际反馈；本文讲解不表示用户已理解或硬件已观察。
