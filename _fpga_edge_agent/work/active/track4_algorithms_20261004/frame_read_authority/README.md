# 唯一帧账本的显示只读授权：代码阅读与实际验证

前置设计：[TRACK4-FRAME-READ-AUTHORITY-001 v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-FRAME-READ-AUTHORITY-001.md)，内部声明修正：[RA-C0](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-FRAME-READ-AUTHORITY-001-C0.md)。15份输入冻结后才生成8份实现/验证文件，复用3个package及原对象参考。四组真实仿真/审计和当前组件MAP已通过。登记位置为`artifacts/staging/FRAME-READ-AUTHORITY-COMPONENT-20261010-v1`，以其中artifact-manifest.json为实际登记证据。原工程、旧work及已登记包保持只读，完整goal仍未完成。

## 1. 先看整体行为

生产父提供真实Source/Result闭合和OFFER命令。唯一账本在成功OFFER时为该Result绑定非零、严格递增的sequence。显示预取提供479位行需求，账本直接检查完整FrameRef387、Result/Source状态及行映射，允许时返回自己的规范OFFER回执942。caller无需传入可被篡改的bundle；拒绝查询返回0许可和0描述。Q期间可以接受一个拒绝查询，但不会授权新读取。

它并不把SOURCE_END/RESULT_END flags自动接入CSI/算法；本次验证中flags是明确的环境事件。实际生产父、持续scan和旧scope fence仍要继续接入。query fire是授予读取借用，不能当成物理读取结束；root必须等真实scope关闭才DROP/RETIRE。

## 2. 再看接口交接

`rtl/frame_owner_read_authority.sv`保留941位command、942位reply及六Source/三Result账本，新增offer_sequence64和lookup479/ready/bundle942/permitted。默认A64描述，仍支持A16。现有prefetch的lookup字段顺序完全相同，但旧route/prefetch下层reader尚需显式传播A64参数才能做小尺寸整合。

lookup479顺序为sequence、scan、result、policy各64位，Origin195位，target/source_y各11位，mode/mask各3位。FrameRef387不含scan，scan非零及其真实行运输一致性由现有scan/prefetch分别负责。Origin包含Source handle、epoch、handle和slot；既不能只比slot，也不能只比低32位。

command优先，held reply期间查询等待；权限及bundle仅在lookup_valid&&lookup_ready正沿有效。ready=0或者valid=0时二者为0，无独立response valid，因此不存在让caller在另一拍采样热变化描述的暗示。原command和reply保持约定沿用。

## 3. 最后读内部语句组织

先读原always_comb的next-state复制、OFFER分支及引用回收，再读always_ff提交，最后读命名组合块read_authority。

OFFER原检查顺序保持：身份、Result状态、Source完成/global policy/冻结源、已有OFFERED检查完成后，才检查新sequence。成功一起提交R_OFFERED、该slot ro_sequence和last_offer_sequence；失败形成原错误回执而不推进绑定。真正FREE的Result才清绑定；三绑定和last共256位设计预算，实际资源以MAP为准。

read_authority使用旧账本，先限制Result为OFFERED/DISPLAY/RETIRING及其handle/policy/sequence、Source slot，再核对Source COMPLETE和完整Origin。mode0由target_y上下半屏选择mask1/2及source_y=2*(target_y mod H/2)；硬件用常量减法和左移实现。mode1/2/3/4/5分别为mask1/1/2/3/7，source_y=target_y。只有完整条件成立才构造规范op5/status0回执；其CJ、render和三个描述来自原记录，不由查询输入拼凑。

FREEZE/RESUME/BARRIER可以改变global policy，旧Result的policy仍保持，以支持实际route保留旧active的行为。两个Result借同Source仍分别验证Result和sequence。RETIRE后旧FrameRef被拒绝；新Result复用同slot也不能恢复旧权限。查询从不更新任何账本，测试同时检查query沿前后全部公开223位状态不变。

## 4. 已运行证据

|实际运行|参数|兼容命令回执|查询总数|许可/拒绝|查询实际周期|
|---|---|---:|---:|---|---:|
|authority_small_002|34×20|873|2664|180/2484|7451|
|authority_min_001|6×6|873|2580|96/2484|7283|
|authority_hd_geometry_001|1920×1080|873|9024|6540/2484|20171|
|authority_max_001|34×20，handle/policy和sequence nearMAX|17|4|3/1|159|

每组是真实vlib/vlog、两套vopt、两个预期fatal、两套正常vsim和独立Python审计。正常工具退出0；fatal有真实marker且退出1。共2636兼容回执、查询套件626笔实际command输入/608笔回执，另外18笔输入在明确共同cold时丢弃未交付回执；共14272查询、6819许可、7453拒绝。HD这里证明全1080行的六模式控制几何和身份，并未重新处理HD图像像素。

每个普通参数运行逐位翻转387位FrameRef，覆盖六mode、wrong source_y/mode/mask、零scan及越界行；另外覆盖WORKING/DONE拒绝、候选/当前/退休RO、同Source多Result、slot重用、旧policy、Q拒绝、held query/held reply/同沿优先和pending cold。Python从被冻结原对象/租约集合参考独立推导命令，按数学A64配置描述函数，再由对象身份/状态和独立行规则推导查询；不读取DUT私有数组。

authority_small_001实际vlog失败：lookup_ready赋值先引用running、后声明。RA-C0先保存读回，只移动连续赋值至原wire声明之后；原失败快照/日志保留。small_002及其后三组使用同一修正后9源。15冻结输入未改，没有为已PASS运行重复仿真。

## 5. 实际综合资源与范围

authority_map_001真实退出0，完整12份源/工程/脚本与当前SHA及快照一致。实际网表与报告一致：13541 LUT4、2879 FF、0 RAM、0 DSP；网表SHA为D0AA349259D519C2C7267C0BFCCF28727CEB54BBA18AE5DEDF9BA6BD120E272A，报告SHA为F40738D06C98F70BF39D64314E02B5E365BE069CB6A29774E962772FD6B979E3。

相对v26保留的原owner报告9624 LUT/2623 FF，增加3917 LUT和256 FF；绑定FF与预算相符，组合查询的LUT代价需要纳入整机优化。此处比较依据是SHA绑定的v26原资源记录，不声称重新运行原owner。21项警告为EFX-0200二十项及EFX-0657一项，完整警告原文和SHA见resource-result.json。10ns组件约束、MAP通过都不代替物理STA或整机FPS。

收尾进程检查一度把Get-Process时间字符串与ConvertFrom-Json的DateTime直接比较，得到false；实际PID24480、UTC start完全一致，按Ticks核对为true并恢复同38749句柄直到退出0。历史资源文件名首次只读猜测不存在，随后使用现有v26字段；没有重启综合或修改原产物，记录见control-observation-recovery.json。

## 6. 复现、定位和后续

已有英文Work入口下运行`scripts/run_authority_sim.ps1`，必须新RunId，显式TestWidth/TestHeight；编号边界加NearHandleMax/NearSequenceMax。脚本先查15冻结来源、复制9执行源，再真实执行和末尾核对SHA。`scripts/run_authority_map.ps1`要求当前同源的正常1920×1080 PASS作为前提，绑定12源/工程/脚本，仅综合4个包/RTL，不含板级IO或bit。

RA01/02/07→唯一账本/OFFER绑定/回收；RA03..06→read_authority和479→942交接；RA08→独立参考、两个TB、快照/工具/工程。修改权限条件同时看设计D/E、RTL read_authority、新TB bad_fields/lookup和Python Authority.query；修改命令优先或回收同时检查原compat回归及Authority.event。实现与测试都由implementation-changes.json定位实际SHA。

下一步把真实采集/完整Canny的DONE接入生产发布，再把本查询接入实际reader/scan、A64传播和旧scope关闭。真实DDR/CSI、HDMI期限、完整复杂识别、共享FIT与整机资源/FPS、一个板级top/引脚/时钟/CDC/PNR/STA/最终bit仍未闭合。软件证据不能代签硬件通过；正式数据库/H0未改，用户理解验收待实际作答。
