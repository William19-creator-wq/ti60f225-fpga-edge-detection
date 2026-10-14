# TRACK4-DDR-MODEL-2048-001 v1：新2Gb模型输入选择与实际展开检查

## A. 整体目标、状态与来源

Goal：接入用户新解压的DDR3_Controller_V1.9中的原始2Gb参数，解除“缺2048参数头”的资料缺口，并实际验证选中2Gb/x16/sg125及严格检查。Current state：新包80份文件逐字节与所给ZIP一致，旧DDR控制器Q0实际编译/展开exit0；模型动态尚未验证。Target：本增量M0模型选择/展开/有限复位时钟证据。Gap：真正控制器初始化、校准、DQ/DQS读写、刷新监视和帧服务仍在后续Q1–Q3，M0不能替代。

设计v1 / 2026-10-11 / A3、A4、A6、R0；新独立work `active/track4_algorithms_20261004/ddr_model_2048/`。只读原包、旧work及工具；正式数据库/H0/Manifest、硬件不改。依据用户“当你統計完后自行进行, 无需我的批准”和已批准本地审计例外，保存/读回/呈现/冻结后自行进行软件工作。不伪造新的人工v1回复。

用户所给ZIP及根目录ZIP SHA均60760BEDB05C5045250394F64FFFD5F2CDF0884489D531D1870779A67FFD488D。新原始参数头：`DDR3_Controller_V1.9/DDR3_Controller_V1.9/example_design/sim/tc001/tb/2048Mb_ddr3_parameters.vh`，54042B，SHA1244175A23FB45222CD8509AED0B515463DF8176FBD5BF8FD87D6FEDE68C6850，注明基于2Gb DDR3 Rev.P 2/12。同包模型 `ddr3.sv` SHA4F1062AA5CDEF340A986C5395083E1ED61017C36A8B1D65F9CA3E6A37FB3E0C1，Micron BFM v1.74，已有1024/2048/4096/8192 include分支。它在分支前硬定义den1024Mb、x8；必须移除这两条默认选择，单靠命令行define2048不会覆盖先匹配的1024分支。原头不派生、不改参数值。

模型及header、此设计/v0.2逐份冻结原路径/副本/SHA，工具为现有Questa。M0无当前参数选择阻塞；原包不是Ti60板级工程，其示例Ti180/默认1Gb x8不直接使用。

## B. 外部行为与可检查要求

|REQ|规则/正常与错误样例|
|---|---|
|DM01|原始80文件与ZIP核对，源模型/header及工作依赖冻结；新模型仅移除上述两条默认define，保留所有其它字节/版权/时序逻辑。header副本与原文一致。|
|DM02|vlog明确den2048Mb、sg125、x16；实际实例参数ADDR14/ROW14/COL10/BA3/DQ16/DQS2/DM2/BL8；几何计算得到2Gb=256MiB。实际TCK_MIN1250ps、TRFC_MIN160000ps、TXPR/TXS170000ps，不能使用4Gb的260/270ns。|
|DM03|严格MR/时序检查都保持1，STOP_ON_ERROR保持1；只DEBUG设0抑制INFO，不能禁用检查。模型复位保持低，时钟周期2500ps，运行20000ps后检查真实展开实例及参数。无MRS/读写，故不声称初始化、存储读写或PHY通过。|
|DM04|MAX_MEM使用模型原有文件后端，+model_data指向当前run内ASCII路径，避免默认/tmp及MEM_BITS15的32768稀疏突发限制。M0只是验证文件后端正确开启/本地八bank文件能打开，不验证容量读写或存储性能。|
|DM05|fatal探针必须真实失败且不产生成功文件；positive vlib/vlog/vopt/vsim/audit都exit0，finished标记存在，日志没有ERROR/Fatal，snapshot/current/SHA一致才PASS_M0_SELECTION_ELAB_ONLY。检查字段逐项独立常量，不能以vsim exit0单独判DDR通过。|

正常样例：新header完整→副本移除默认宏→显式2Gb/x16/sg125→真实实例核对→有限复位时钟→M0完成。错误样例：未移除默认den1024，实例ROW/DQ不符→TB fatal；错误速度/strict开关/后端目录问题→保存失败，不生成M0通过报告。文件保持readonly源，后端只写当前run。

## C. 职责、接口与组合

MOD1 model：原Micron实际时序/数据模型，work仅改变默认宏选择；MOD2 tb_ddr_profile：外部差分时钟与reset输入、实际参数观测和finished；MOD3 runner：冻结复制、工具阶段/严格诊断/本地文件后端/退出信息；MOD4独立profile参考：逐字段对照已读原文常量、工具输出和后端文件，不复制model内部算法。

连接：原头→model include；runner compile defines→明确profile；TB→model rst_n/ck/ck_n、其它命令固定NOP/deselect；model参数→TB JSON→独立常量参考；runner→本地backend目录。当前没有真实ddr3_top/PLL/GPIO/AXI连接；那些不混入M0通过范围。

IF1：ps/1ps，core CK2500ps，差分互补；rst_n=0、cke=0、cs_n=1、ras/cas/we=1、DM0、bank/address0、DQ/DQS高阻、ODT0。保持reset意味着无初始化与事务；TB finished1只能表示该阶段。

IF2：den2048Mb/x16/sg125/MAX_MEM只有本run编译生效，不修改环境或工具；原headerx16 fallback、x16速度分支均实际生效。原模型MAX_MEM是按row/col/BL与bank文件定位，地址几何仍14/10/3，不以MEM_BITS推定物理密度。后端目录绝对ASCII、限制在run，失败$finish时finished仍0，由macro拒绝。

IF3：profile JSON整数/real字段，有效实例观测在20ns；独立常量表包含几何、CL/CWL范围、速度、关键输入/输出、activate/refresh/reset时序及strict开关。derived ZQ时序依赖运行周期，M0不提供ZQ功能通过证据。

## D. 局部中文操作草图与语言

先核四份冻结输入→建立新根reference/deps/control/rtl/tb/model/scripts→model原字节仅删两行默认define→真实header原字节复制→vlog指定四宏并用snapshot include→vopt实际TB/model→先fatal探针→positive固定reset与运行8个CK周期→检查参数/严格开关→输出profile与finished→独立常量/日志/文件后端核对→末尾source/snapshot/SHA→有限报告/登记。

RTL数值A：所有地址/数据宽度取真实model展开；观察只读不写内部state；B：1ps分辨率外部CK互补，profile在20ns；C/D/E：没有事务/valid/反压，固定reset，无在途义务；F：8CK为有限选择检查，无FPS声明；G：reset一直低，无复位释放/初始化通过；H：profile在编译选择，不能运行中更新；I：MAX_MEM八个bank文件，M0无数据容量证明；J：无frame身份；K：单CK，没有CDC；L：Questa现有2024.1，model为仿真体不综合。C++ N/A；Python用无符号字段、有限常量对照和文件哈希，输出不当作实际DDR物理观察。

## E. 验证、追踪与实施

计划4份业务/验证文件：适配model、TB、独立参考、runner；原header为冻结依赖。T-DM1真实编译/实例/几何→DM01/02；T-DM2strict/有限resetclock→DM03；T-DM3文件后端/默认/tmp排除→DM04；T-DM4fatal/出口/诊断/末尾hash→DM05。双向：所有新代码单元对应以上MOD/IF/REQ，后续中文README明确M0与Q1–Q3不同。

READY十项：A来源/版本/授权；B整体/错误样例；C职责/整体连接及逐接口相容；D局部步骤/语言；E验证/追踪；M0无阻塞；保存、读回、呈现和冻结后执行。失败保留原attempt，先修订卡再调整；不改旧Q0/官方原文件。rollback停用新包，源输入未变。理解验收待用户真实作答，不阻塞软件授权。

剩余工作保持完整目标：真实Ti60 DDR控制器/合法vendor I/O与PLL模型闭合、初始化/校准、实际DQ/DQS读写/掩码/跨bank-row/刷新、AXI审计和整机共享帧服务；摄像头/复杂识别/资源/板级PNR/STA/bit另行推进。M0不是整个DDR资格通过，也不把全目标缩小为M0。
