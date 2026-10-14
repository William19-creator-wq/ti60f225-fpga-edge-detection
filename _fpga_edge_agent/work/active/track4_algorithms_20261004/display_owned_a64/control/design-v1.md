# TRACK4-DISPLAY-OWNED-A64-001 v1：生产帧账本与完整显示扫描相接

## A. 阅读入口、目标与授权

Goal：将已经实现的A64生产帧描述和真实只读权限接入完整显示扫描，去掉旧测试中的影子lookup。Current state：源帧自动管理已登记；旧display_scan使用A16 route/reader及TB模拟权限，而生产owner/Source/EDGE/ANN使用A64。Target state：同一个真实frame_owner_read_authority的OFFER与lookup驱动真实跨域handoff、prefetch、三native行银行、renderer及旧帧scope fence。Gap：全父控制器自动Result/Canny/ANN调度仍须后续接入；本批不以测试端手动SOURCE/RESULT_END替代真实相机/算法闭合。

Task v1/2026-10-10，H1/A3/A5/R0；独立路径 `work/active/track4_algorithms_20261004/display_owned_a64/`。旧工程、HDK、staging保持只读。整体五基础六高阶、1080p、Ti60F225/I3及原识别范围不变。没有物理硬件下载。

READY_FOR_REVIEW。本批继续引用用户“当你统計完后自行进行, 无需我的批准”及已批准本地审计例外；先保存、实际读回、呈现、冻结依赖，再编码，不伪造新的聊天批准。PostgreSQL/Manifest/H0不改。组件当前无阻塞；真实PHY、CSI、算法结果生产、资源/FPS和板级PNR/STA/bit仍待最终整合。

Baseline：实际旧display_scan运行脚本列出的源文件，production_bitmap的A64/bit-packed display_row_reader，frame_read_authority实际RTL/参考及其冻结legacy数学参考。本设计与v0.2。冻结清单逐文件写原路径/副本/SHA，不猜commit或输入数。工具为已存在Questa/Efinity/Python，无安装/联网。

## B. 整体行为与要求

|REQ|外部可观察规则|
|---|---|
|DA01|生产实例的Source分配为A64(3WH)、EDGE为A64(ceil(WH/8))、ANN为A64(4224+ceil(WH/4))；三处合法性判断使用相同配置，不改变真实AXI 16B beat/span。|
|DA02|跨域handoff仍传完整942 bundle与1137/1207控制；A16作为明确兼容参数保留，生产默认64。任意不合法descriptor仍拒绝，无扩大接受域的模糊范围检查。|
|DA03|唯一真实frame_owner_read_authority承担OFFER sequence绑定和每次lookup权限；测试无影子ro_bundle作权限源。只有lookup_valid&&lookup_ready的真实交接才比较bundle。|
|DA04|六种显示模式的实际AR/R/native读写/renderer输出保持原数值和身份契约；SOURCE/EDGE/ANN数学图明确是只读输入fixture，不能称作真实算法生产。|
|DA05|准备资格来自真实native row0读/owned/票据；在消隐VS、retire容量足够才切帧；没有TB伪造prepared/closed。错过VS后重做新scan，旧票据不改。|
|DA06|冻结PREPARE→实际ownerFREEZE→COMMIT与RESUME仍使用真实快照及policy；旧不可变active允许旧policy lookup。取消held AR/R必须真实drain/row返还后才candidateClosed；旧帧必须实际scope fence后才RETIRE。|
|DA07|34×20、4×2及完整1920×1080独立动态审计；小尺寸的分配差异实际触发校验，1080p按完整固定时序显示。当前组合MAP记实际资源和警告，不算整机PNR/STA/bit。|

完整路径：实际owner创建不可变租约→OFFER绑定sequence→跨域控制→真实lookup授权→A64 reader解释描述→16B AXI spans→三native行银行→视频行消费→renderer→旧FrameRef fence→实际RETIRE。数学输入fixture仅提供内存字节；现有真实RAW/Canny/ANN执行模块在后续全父顶层替换fixture并生成闭合证明。

## C. 职责和连接

MOD1 新 `display_owned_scan`：组合一个实际owner与完整scan；公开owner命令/回执和offer_sequence、显示控制/回执、视频输入/输出、旧帧闭合以及实际AXI读端口；不另存权限账本，不生成Source/Result关闭证明。

MOD2 适配 `display_scan_component`：只新增FRAME_ALIGNMENT生产默认64，把参数分别传handoff和prefetch。MOD3 适配 `display_handoff`：只传参数到route，mailbox宽度/CDC/holding不变。MOD4 适配 `display_route`：descriptor容量用frame_allocation，根据明确16/64算完全相等；状态机与控制语义不变。MOD5 适配 `display_scan_prefetch_core`：参数传给已验证生产reader；其余银行和fence流程不变。生产reader直接复用，不改位打包/行边界规则。

复用：原atomic_mailbox、row_ram54、display_row_bank/rows3、display_span_axi、display_meta_ram、display_fetch_link、display_row_streamer、display_renderer、display_scan_video、display_scope_fence与video timing；实际owner来自frame_read_authority。它们的SHA和适用当前参数在baseline列出。

测试适配：既有完整扫描TB使用MOD1；移除TB模拟lookup，owner OFFER的sequence取下一真实显示请求sequence；所有lookup日志改成真实fire。原独立scan数学核对继续，加真实Authority对象的OFFER绑定/每次query比较。旧TB private事件只作实际native/fence观察，像素期望由公开数学公式生成，不从DUT RAM取值。

## D. 接口与组合检查

|IF|参数/身份/接受|提供保证→使用前提|
|---|---|---|
|IF01 owner|core_clk/safe_reset_n；CMD941/REP942 valid/ready；offer_sequence64|source/Result唯一owner真实生成；生产A64；sequence在OFFER cmd fire被owner绑定，后来CORE/VIDEO request必须同值。非OFFER不借sequence产生副作用。|
|IF02 lookup|demand479/permission1/bundle942，valid/ready|scan持有需求至实际ready；owner命令及held回复优先，权限只在真实fire有效。拒绝bundle为0，不能用TB保存的旧OFFER绕过。完整seq/scan/Result/policy/Origin/坐标/mode/mask均验证。|
|IF03 control|request1137/response1207、cancel sequence64|原handoff完整传输和持有；PREPARE/COMMIT/RESUME两域状态不改。route和reader接受同样A64描述。|
|IF04 video|双像素RGB48；x_even11/y11、DE/HS/VS/start、error2|完整1920×1080时序仍为既有1080p timing；小尺寸缩小仅用于边界验证。固定视频时隙不反压，欠载按既有错误色并记underrun。|
|IF05 row/native/fence|原ticket543、pair54、returned545、FrameRef387|代际/完整引用/真实返还保持；旧帧closed仍需IO、运输、native消费都安静。root_retire_capacity真实有限，两旧引用不超限。|
|IF06 AXI|AR32/ID4/len8/size3/burst2，R128/ID4/RESP2/LAST|A64是frame allocation，不改变16B beat、最小行byte span、4KiB分割和真实R holding。数学输入slave与实际DDR PHY分开。|

所有宽度unsigned。core/video两个域复用原mailbox和同步位，异步safe_reset_n共同断言、各域两拍释放；不新增宽bus直接异步采样。参数W偶数4..1920/H偶数2..1080。FRAME_ALIGNMENT只能16或64，非法仿真fatal。生产实例owner、route、reader全部强制64；兼容16参数仅用于复用旧组件，不能混接A64 owner。

## E. 中文局部操作草图

1. 参数配置在实例化时固定：顶层64→scan.component→handoff.route及prefetch.reader。调用方不在帧中切换alignment。
2. route CHECK根据旧current.bundle的Source/Result slot和显示mode形成三份期望描述：逻辑字节不改，allocation按(n+63)&~63或(n+15)&~15；与整个descriptor逐位相等。当前参数最大帧不溢出32位。
3. 通过CHECK后沿用原WAIT_OFFER；只有真实row0准备、VS消隐与容量条件成立才锁active并发回实际回执。其他状态、取消/holding/快照完全复用，避免改动时间语义。
4. prefetch LOOKUP输出锁定请求的demand；owner没ready时不计一次query。actual fire的同沿把真实owner bundle/permission送reader，reader内部锁存942；下一阶段验证A64容量、位打包长度、完整坐标与身份，失败无native发布。
5. reader按每行开始bit定位EDGE/ANN，按16B spans读取实际R并装入native；RGB carry和尾行数学规则复用production版本。不能把frame allocation64误写为R beat64。
6. wrapper owner命令和lookup同域直连；scan Q与owner Q合并为顶层Q。新enable可以禁止新的显示取数，已经公开的下游承诺仍按既有模块持有。wrapper不制造EOF、算法DONE、RXclose、oldclosed或prepared。
7. 测试的manual owner命令仅建立数学内存fixture的不可变租约；真实core/video流程、OFFER绑定与逐行查询照常执行；审计逐事件调用独立Authority。对结果生产没有本批动态证明。

不变量：三个allocation配置同一64；无lookup fire不检查无效bundle；真实查询的942由唯一owner产生；active切换仅真实row0/VS；旧closed只能fence产生；取消不撤回held AR；fixture范围和硬件结论不混淆。

## F. RTL与跨语言契约

RTL A–L：A地址/长度32，中间端点33，packed位数沿用原；最大A64不溢出，逻辑长度不改；B core上升沿10ns/video上升沿13.468ns，TB下降沿驱动，沿前fire沿后状态分开；C每个valid/ready真实fire；D无valid不推进；E既有mailbox/actor holding复用；F不改级数，owner命令往返会正常暂停lookup，固定video不等待；G共同cold，各域两拍释放，无整帧RAM清零；H配置快照与policy通过942/控制，alignment为静态参数；I三native银行/有限旧引用/carry，不增加帧缓存；J完整Origin/seq/scan/Result/policy与坐标全部保留；K原mailbox/scope fence CDC，不新增异步多位线；LSystemVerilog/Ti60F225/I3，组件MAP10ns/13.468ns，只测资源不声称物理时序。

C++ N/A。Python数值参考按公开二维输入公式产生RGB/EDGE/ANN54位pair及渲染颜色；Authority集合模型验证租约/sequence/query；旧A16数学参考被冻结，其desc函数只在新适配参考中显式设A64。同一源码快照运行，像素、协议、复位/取消/身份逐项比，不把函数先后当作硬件时钟证明。

## G. 实施和验证计划

计划11份新/明确适配文件：5RTL（route/handoff/prefetch/component/owned wrapper）、TB、独立审计、2脚本、XML/SDC。unchanged依赖复制后冻结，不重复计为新业务文件。先小尺寸34×20，再最小4×2和完整1080p，当前实际组合MAP；保留全部失败/当前snapshot。

|TEST|输入及标准/追踪|
|---|---|
|T01|34×20与4×2真实A64描述，六mode，全部实际native pair与renderer输出逐位；DA01..05。|
|T02|同一次无reset连续切六帧，真实OFFERsequence/lookup身份，旧closed holding/实际RETIRE与slot重用；DA03/05/06。|
|T03|候选AR暂停错过VS，新scan重做；heldAR时取消必须真实accept/drain/native返还才closed；DA05/06。|
|T04|B已显示owner仍A时PREPARE冻结实际B，再真实ownerFREEZE/COMMIT；新阈值/显示配置重算同Source；RESUME保留不可变active；DA06。|
|T05|完整1920×1080六mode及原事件场景，实际AR/R/row/native/renderer/fence证据；独立参考不读取私有RAM作为期望；DA04/07。|
|T06|各阶段exit0、fatal探针非零且含标记、末尾current/snapshot SHA不变；MAP实际net/rpt/warn核对；DA07。|

未执行本批；原反压/故障测试继承不默删。TB手动SOURCE/RESULT_END仅fixture，整机真实RAW/算法生产要后续闭合；Mapped/PNR/STA/bit/物理DDR均未由本批证明。

## H. 双向追踪、门槛和恢复

DA01/02→route.frame_allocation/handoff参数/component传参/prefetch传参→T01/T05；DA03→owned.owner及TB真实fire、独立Authority→T02/T05；DA04/05→既有reader/native/video/renderer→T01..03/T05；DA06→既有handoff/fence＋真实owner→T02..04；DA07→脚本/XML/SDC/审计→T06。所有新单元均对应这些已有目标的整合，不另扩任务。

READY十项：B行为/样例，C职责/复用，D接口/相容，E草图/不变量，F语言，G端到端走查/验证，H追踪，无本批阻塞，A版本/范围/授权；保存读回和呈现后才冻结/实现。回滚仅停止使用新独立包；旧工件不改。失败先写适用变更卡、同步草图，保留旧run；持续授权不重复索取。完成后补README/完成核对/真实日志/staging，不判全目标完成。理解验收待用户实际回答。
