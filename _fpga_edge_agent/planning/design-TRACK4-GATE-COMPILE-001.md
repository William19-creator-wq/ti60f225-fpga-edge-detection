# TRACK4-GATE-COMPILE-001 v1：既有 C0 合并网表的有限编译设计

2026-10-04；使用 [PLAN_TEMPLATE](PLAN_TEMPLATE.md) 的短卡安排。**LOCAL_DESIGN / READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN**。本卡是完整十一项软件验证的辅助兼容性检查，不代替算法实现、功能仿真、合理约束、PNR/STA 或比特流。当前仅保存设计及数据清单；没有新编译，没有执行待批准的 USER1 修复。

## A. 状态、基线与通用字段

- Goal / Target：检查现装 Questa 是否可以编译并展开已由获批官方流程产生的 C0 fabric 合并网表及真实行为原语，确认一条不依赖该网表之外 CSI 解密包的验证输入路线。
- Current state / Gap：C0 原 RTL 编译在 CSI 无 key 处失败；官方 debugger 合并产生的既有网表没有观察到保护包装，六类实例均有现存行为模型。静态闭合不能代替真实 compile/elaborate。
- Assumptions：完整保留已有网表及 15 个原模型字节；不解密、改保护包、裁剪逻辑、重命名顶层、加常量或用空模型补依赖。不复制旧编译库作为新结果。
- Open questions：Questa 对本次网表/参数/语言/原模型以及 vopt 许可的真实接受性是实验输出，不预判成功；物理服务、时序、像素行为和算法性能隔离在本卡之外。
- Dependencies / Baseline：[GATE-COMPILE-BL-v1](../experiments/track4_full_sw_20261004/01_baseline/gate-compile-inputs-v1.json)，16 份现存输入、23,556,078B。清单 6,907B，SHA256 `FF0474AF44F6BBF7826E8B0BDD2F94DED3201A30FE6B2DCF9E068E524579240B`。它绑定 C0 v1.2 的既有产物，与尚未批准的 v1.3 USER1 修复分开。
- Milestones / Detailed steps：只读闭合/设计→审读呈现→指定版本、基线、路径与范围批准及本地审计例外→新目录仅复制冻结输入→独立本地库→模型编译→网表编译→前序成功才展开→保存退出码/日志/hash。
- State transitions：只记录本辅助检查的 NOT_RUN、PASS、FAIL、NOT_RUN_DEPENDENCY；不改旧 RTL 编译失败，不改变正式 PROJECT_STATE/数据库/硬件状态或完整功能状态。
- Artifacts and hashes：主网表 23,360,883B，SHA256 `F18680E05E7BCA979889DE015C765CF2F61BAA2328CC1D85ED3D814260C4E3F6`。其它 15 个模型逐份 bytes/hash 在清单中。未来编译库、优化产物和结果 hash 未生成。
- Validation：当前只有来源/网表/模型的静态核查；获批后进行 G 的真实工具阶段。本卡不产生可执行测试、runner 或 TB。
- Failure handling：输入漂移、目录冲突、非冻结依赖、库映射变化、许可/语法/模型/参数错误均据实停止依赖阶段；不 suppress 错误，不自动安装或切工具。
- Human approval gates：原预检许可只包括其被引用 RTL/保护 DUT 视图，不自动包含本门级视图。执行前须明确批准本卡 v1、16 输入、下述独立目录和仅 compile/elaborate，并允许本次限定本地审计替代未配置 PostgreSQL 前置；否则不得运行。
- Rollback：原 C0、官方安装模型、原失败/日志及 v1.3 卡/清单不改；新目录/日志保留，不覆盖旧库或全局 modelsim.ini。
- Completion criteria：每项阶段都有本次真实退出码、输入身份及完整原日志，成功/失败/未运行分开；这仅完成有限兼容性检查。

唯一未来工作目录：`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_gate_compile_20261004\C0_dbg_gate`，当前不存在。只写此独立目录和控制面报告/追加审计，不操作原资料。阅读顺序 B 整体→C/D 交接→E 步骤→F/G/H 契约和检查→I 批准边界。

## B. 整体行为与可检查要求

GATE-REQ01：16 输入在复制前后均与清单匹配，来源及原获批生成过程可定位。GATE-REQ02：真实行为模型、完整网表、同一新 revision 的本地库按先后编译；不能把旧 vendor PASS 或静态实例名单当新编译 PASS。GATE-REQ03：仅在模型和网表编译真实成功后运行 vopt，保留各阶段结果及全部警告。GATE-REQ04：不生成激励/TB，不执行 vsim/run、PHY wrapper、SDF、PNR/STA 或 bit/hex，不借结果关闭旧失败和完整功能缺口。

正常样例：冻结 16 输入→建立独立库→模型编译通过→网表编译通过→真实展开终态。失败样例：模型或 DUT 编译 exit 非零则展开 NOT_RUN_DEPENDENCY；模型文件/hash 不符则尚未编译就停止。边界样例：展开成功但无任何像素/协议激励，结果仍仅为工具兼容性通过；若 vopt 许可失败，记录 FAIL，不更改安装/许可或把 compile 代为 elaborate。

## C. 模块职责和整体连接

MOD-INPUT 拥有来源/复制身份与清单，承担 REQ01；MOD-TOOLS 只调用现装 vmap/vlib/vlog/vopt 并拥有新本地映射、库和阶段 handle，承担 REQ02/03；MOD-REPORT 关联输入→实际工具参数→退出码/日志/hash，承担 REQ03/04。原官方网表和模型→IF01 输入冻结→IF02 新库/编译/展开→IF03 真实结果→完整工程后续验证设计。没有新增运行期数据/控制/配置路径、反馈或队列。

## D. 接口、出入参数与组合检查

IF01：提供方是现有 C0/outflow/ti60f225_oob.dbg.map.v 和安装 `sim_models/verilog` 的 15 个真实 .v；使用方为新独立目录。合同为清单中的 role/path/copy_relative_path/bytes/sha256，复制不修改任何源内容。当前网表唯一顶层为 `ti60f225_oob_top`，六类可见原语 EFX_ADD/DPRAM10/FF/LUT4/RAM10/SRL8 共 25,003 实例，都在模型中定义；原库曾实际编译成功，但本次仍重新编译冻结源。

静态全文核查得到 protect 包/实例、include、活动 import、readmem、文件读取和初始化资产参数均未观察到；6,400 条 INIT 常量留在网表。来源见[CSI 仿真路线证据](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/CSI-simulation-route-readonly.md)，SHA256 `65C379FA33DC6D0A62D0D6043AB46DFD2927E28EAC318BC280B57FE0F4122562`。如果工具报额外依赖则记录实际失败，不能补未经批准的源。

IF02：提供方为上述完整 Verilog/SV 源与现装 Questa2024.1；使用方为该 case 独立本地库。先由官方工具创建 local modelsim.ini 并映射新 work/efinix，不写用户全局配置；15 模型进 efinix，网表进 work。使用已在原预检采用的 SV 编译选项，顶层展开以 efinix 查找真实原语，优化设计使用本 case 独立名字，不添加宏、-mfcu、替身、模型修改或 error suppress。具体 argv 在获批后按真实本机工具核对并保存，不在卡中生成 runner。

IF03：工具退出后提供 exit_code/stdout/stderr/起止时间/命令/工作目录/模型与 DUT 输入 hash 给报告。exit0 及日志 Errors0 才可标该阶段 PASS；warnings 完整保留且另判影响。超时只表示尚未观察到终态，继续同 handle 或查真实进程，不能重启制造第二次结果。真实失败、取消、许可错误和未运行不能混同。

组合走查：IF01 字节一致保证 IF02 编译的是同一个既有 netlist；模型源定义保证有可检查依赖，但语法/参数/许可是否接受仍由真实阶段决定。IF03 不把源级失败改为成功，也不跨 case/revision 借报告。没有 TB/外部服务，顶层未驱动时不产生运行期结果，此限制使功能验收保持未完成。

## E. 局部中文操作草图

获批前只读来源及保存卡/清单。获批后：①核指定版本、16 基线、目录归属、编译范围及本地审计例外；②逐份复核源 bytes/hash、确认新目录无冲突；③仅复制 16 原字节到新 input/gate、input/models，再核副本 hash，旧库/网表派生物不带入；④用现装工具建立本地映射和新空库，记录真实退出码，失败就停；⑤按冻结模型清单编译 15 份行为源，成功才编译完整网表，分别保存日志；⑥两项 compile 都成功后，仅以既定顶层及真实模型库进行 vopt，记录真实许可/展开终态；⑦保存每项命令、时间、退出、警告、结果 hash 和 scope 检查；⑧取消不启新阶段，已启阶段通过实际 handle 确认终态；恢复先读本次输入/批准/handle/日志，不复制旧 PASS。

不变量：无源码差异、模型字节不变、全局配置不变、本 case 库不与旧库混合；不生成 TB/激励/脚本，不调用 vsim/run，不运行 v1.3 修复或其它工具 flow。没有业务状态转移；工具库和日志只有当前进程写，真实退出后才登记该阶段终态。

## F. 语言、硬件及跨语言契约

C++/共同数学模型 N/A：没有实现或数值映射。既有网表按原 Verilog/SV 表示，所有端口、位宽、INIT、极性、reset、clock、valid/反压和存储逻辑保持，不由本卡改动；编译/展开仅检查接受性。RTL A/J 的数值与身份、B–H 的边沿/时间/复位/配置、I 的存储、K 的 CDC 都沿既有源且没有动态证据，本卡不据此判正确。L 只检查现装 Questa2024.1 对冻结 Efinity2026.1 官方产物/模型的有限支持。

对应关系是原获批 C0 v1.2 输入→官方 map/debug 产物→固定 hash 的门级输入→本次编译/展开结果，不是 C++ 结果↔像素事务。外部 PLL/DPHY/2Gb DDR、相机模式、PHY 电气、SDF/route 和数据期望没有加入，不能用 fabric 门级接受性替代它们。

## G. 尚未执行的实施与验证计划

| TEST | 要求/检查与期望 | 停止或通过条件 | 当前 |
|---|---|---|---|
| G-T01 | REQ01；复制前后 16 bytes/hash、路径/重复/输入数量 | 任一不符停止；同字节才继续 | NOT_RUN |
| G-T02 | REQ02；官方工具建立独立映射/库及编译真实模型 | 每步骤真实 exit0；失败后 DUT/展开不运行 | NOT_RUN |
| G-T03 | REQ02/03；完整冻结网表编译，核参数/原语/保护/依赖错误 | exit0 且 Errors0；warnings 原样登记 | NOT_RUN |
| G-T04 | REQ03；前两 compile 成功才展开 top，以真实 efinix 模型解析 | 真实 vopt 结果单列；许可/模型错误保留，不借 compile 代填 | NOT_RUN |
| G-T05 | REQ04；漂移/失败/取消/恢复与阶段依赖走查 | 相应下游 NOT_RUN，旧源级失败仍保留 | NOT_RUN |
| G-T06 | REQ04；结果覆盖与副作用检查 | 没有脚本/TB/激励/vsim/run/新源改动/PHY/SDF/bit/硬件/网络/正式状态变化 | NOT_RUN |

场景是文字，不是可执行测试。没有输入时钟或随机种子、pixel scoreboard、DDR 校准或识别指标，这些因无功能仿真为明确 N/A，而不是已通过。新 compatibility 结果只有当前 16 输入/顶层范围；未来 v1.3 或算法工程须绑定自己的实际产物再验证。

## H. 双向追踪

| REQ | MOD/IF/步骤 | 未来文件/产物 | TEST/依据 |
|---|---|---|---|
| GATE-REQ01 | INPUT/IF01/①–③ | input/gate、input/models、输入核对记录 | G-T01；16 清单/原官方产物身份 |
| GATE-REQ02 | TOOLS/IF02/④–⑤ | 独立 modelsim.ini、efinix/work、模型/DUT 编译日志 | G-T02/03；现装真实行为模型及完整网表 |
| GATE-REQ03 | TOOLS/REPORT/IF03/⑥–⑧ | 优化设计（仅条件成功）、阶段时间/退出记录 | G-T04/05；工具真实终态 |
| GATE-REQ04 | REPORT/IF03/⑦–⑧ | 覆盖/副作用报告、追加审计 | G-T05/06；本卡禁止项/原失败 |

反向：每个 copied 源只对应冻结输入；每个库/工具产物只用于上述兼容性检查；没有算法或生产接口源码位置。结果回到本次 hash 和阶段，不回填原 RTL compile 为 PASS。

## I. 设计自检、呈现与批准

规范 §10.3：①整体及正常/失败/边界 B；②职责与合法复用 C；③输入/库/退出接口与组合 D；④具体步骤、不变量 E；⑤语言及硬件限制 F；⑥端到端走查 D/G；⑦实施/验证/追踪 G/H；⑧当前有限实验输入闭合，真实工具接受性是待测结果，不要求先假定成功；⑨卡/清单保存读回，用户阅读入口为本文；⑩v1/16 基线/唯一目录/compile-elaborate 范围 A。仅此辅助实验 READY_FOR_REVIEW；审批仍 NOT_APPROVED，执行仍 NOT_RUN。

本卡没有新增当前待批准 v1.3 请求，也没有把“继续目标”解释为该实验获批。原 v1 的 RTL/protected 视图与本次门级视图不同，依[唯一规范 v0.2 §11.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)保存具体范围后等待指定批准。运行前必须核对人类真实回复及既有 Manifest；正式数据库未配置，只有明确同意本限定本地审计例外才可执行。

## J. 变更与恢复

原 RTL CSI 缺 key 与基础 map 含 protected_cell 均保留。本次仅从合法既有官方 debug 合并产物寻找另一种可审查输入，不修源码，不把不同 source view 的成功包装为原视图通过。v1.3 USER1 repair 的卡/JSON与等待对象不改；原 C1/C2 时钟缺口和 C3 停止条件保持。

若未来输入/模型/参数/顶层/阶段/输出范围或许可机制需变，先修订该对象和追踪再批准；不能补库、加 stub、换 CSI 默认参数或扩至功能激励。恢复核真实来源与旧失败，不仅凭存在优化库判断本次成功。

## K. 当前实际记录

已读静态来源报告、冻结 16 份现存输入、保存卡与纯数据清单；没有创建未来 work、复制源码、建立仿真库、运行 vmap/vlib/vlog/vopt/vsim 或生成 TB/runner。既有生成及 vendor PASS 均来自原已批准预检，不能写成本轮运行。用户批准/新执行/新结果仍缺失，future 输出 hash 未生成。

## L. 交付和阅读说明

当前只交付本卡和候选基线。先读 B/D 了解为何原 RTL 失败不等于所有合法验证输入都不可用，再读 E/G 看有限编译步骤和停止条件，最后读 I 看审批对象。即使将来 compile/elaborate 成功，完整十一项算法、源级验证、外部物理服务、功能与时序证明仍须按各自设计完成。理解验收待实际反馈，不作学习任务或硬件观察代签。
