# 独立算法路线与软件实验

2026-10-04。这里是当前入口；旧 track4_full_sw_20261004 保存既有设计和来源。用户最新明确回答“允许使用板卡现有 DDR3”，撤销此前排除DDR的限制；“必须只用板卡现有资源”仍有效，不增加外接存储，PC只供仿真/参考/观察。下文旧版本中的DDR暂缓/不恢复描述保留为当时记录，当前边界以本段及最新整合稿为准。

先读[五类工作整合设计v0.8](../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md)A/B/C，再进入接口、中文草图、资源和验证。它记录DDR恢复、SC431HAI来源、实际IP预检终态、六不可变源/五独立采集ring/三结果、PROFILE与冻结联合候选及撤回的低指标提案；整包仍NOT_READY/NOT_APPROVED/业务NOT_RUN。用户所指“一次过完成”按真实全范围实现、仿真、综合、布局布线、时序及bit证据验收，不能用文档、逻辑数组或原厂历史bit替代。

最新[生产目录与共享源寿命候选v0.1](../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)在整合及下段CONTROL RAM之后读B/C→D1固定45对象/地址→D2真实创建身份/global generation→D3完整holder回链→D4逐lease与两metadata RAM→D5初始化/effects→E中文操作→F/G/H/I。明确32bit生产地址、SRC创建窗口state1而非伪注册、BIND同lease转owner、返回metadata仍占角色额度与最后base退休；新640/512/576 schema不能直接旧RAW。[实际有限审阅与本地Ti60资源证据](03_review/production-directory-review-v0.1.md)绑定最终hash与限定范围，原稿同hash快照及[本轮入口前快照](README-before-production-directory-v0.1.md)保留。目录冷存候选11 RAM，full body97244/native已用97588bit，额外列热436仍不是全部FF；167/175只是已列全机候选。资料包官方Ti60 datasheet第4页实际整页核256块10Kbit RAM/160DSP，不能据块数比例宣称fit。完整holder/64pin峰值/原子接线/冷热预算/DDR服务与CDC仍OPEN，原整合v0.8及原局部未吸收本附件，NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED；无业务源码/TB或新工具build。

最新[控制记录RAM候选v0.2](../../planning/design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md)在整合→HANDOFF/NO-LOAN之后读B/C→D1地址→D2快照→D4两短job/退休→D5旧会话→D6热资源→E中文逐沿→F/G/H/I。它选两core RAM保存16关联/7完成组702词，CMD966实际保914bit快照，运输3986/有效位23/局部热位88合4097bit候选；FILL缓存归CORE，FETCH先真实TERM/ACK后存三body，RETIRE count0仍读真实L。存储valid、业务资格、物理锁、运输和资源关闭分开；本地nativefree95/50/97沿不代全机最坏服务或STA。[实际有限审阅与45实体目录证据](03_review/control-record-ram-review-v0.2.md)绑定最终hash及各段范围：45DDR对象+8独立PROFILE计数已核，RAW旧26bit地址与当前生产不相容；完整目录/真实owner/epoch/全预算/服务/文件仍OPEN。原整合v0.8尚未吸收，NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED；[入口修订前快照](README-before-control-record-ram-v0.2.md)保留。

最新[无借用关闭联合修订候选v0.1](../../planning/design-TRACK4-ALGORITHM-NO-LOAN-CLOSE-001.md)在下段HANDOFF/SCAN之后读B/C→D原始决定分类及四状态→E中文逐沿关闭→F/G/H/I。它保持CORE_CLOSE409/417同宽，将never_opened原位改为no_loan_proved，并将GRANT459→461追加class2，明确区分原始不创建与STALE/诊断拒绝；晚成功永久保历史borrow，不伪造borrow0 CLOSE。body下界28461/并列RowCtx32786，另20bit折叠状态；原来源、整合v0.8尚未吸收，NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED。

[生产唯一实例与控制RAM核对](03_review/production-unique-resource-and-control-ram-v0.1.md)保存实际map/模型/hash和有限阅读范围：DDR39已含PHY/桥，ROW40已含input/RX/output；列出153类块只是未覆盖全部资源的实例候选。HANDOFF持久关联及完成缓存在两RAM10容量可放；SCAN冷记录一RAM10容量可放，但宽held/热状态、目录、端口仲裁、CDC和服务另计。新GRANT461使独立body词对齐缓存378→379，整组拼接373不变。不能据153/156或静态容量宣称全机fit/时序通过；实际功能测试仍NOT_RUN。入口修订前[同hash快照](README-before-no-loan-control-ram-v0.1.md)保留。

这两份增量的[实际有限复核](03_review/no-loan-close-and-control-ram-review-v0.1.md)按真实hash记录来源、位域、class1忙类编码修正及独立限定范围。最终协议delta与数值/RAM章节分别核验，没有将中间稿审阅、容量计算或“未发现反例”当成整包通过。

最新[生产行全局交接候选v0.1](../../planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md)在整合→ROW/SCAN之后阅读：B/C整体登记与唯一owner→D七组字段及范围→E中文借用/填料/渲染/停止/独立归还→F/G/H验证追踪→I真实未决。它补真实REGISTER、整exec plane loan、ROW_ASSIGN、单burst终结、FILL、未发布out归还及source loan关闭；row_seq保持ROW_OWNER唯一分配。mode0整exec借RGB+EDGE011，而逐行上半001/下半010；[有限审阅](03_review/production-row-handoff-review-v0.1.md)保存实际原稿hash/限定范围、反例与最终delta核查。列出body28455及既有五RowCtx并列32780bit只是容量下界，完整目录/DDR/CDC/服务/全机资源仍OPEN。该附件尚未被整合v0.8及ROW/SCAN源稿吸收，不能直接接线或视作实施批准。

[本机工程与公开DDR补充证据](03_review/efinity-project-and-ddr-interface-evidence-v0.1.md)明确现有Efinity2026.1.132与Ti60F225/I3入口/引脚/时钟文件；旧参考综合通过与新生产接口资格、PnR/STA/完整算法验证分别记录。

本轮新[RAW v0.2](../../planning/design-TRACK4-ALGORITHM-RAW-STORE-001.md)与[最终协议复核](03_review/raw-store-review-v0.1.md)已关闭reset和postcommit journal的两项文字反例；完整板载后端/目录仍待冻结。[性能与资源稿v0.2](../../planning/design-TRACK4-ALGORITHM-PERFORMANCE-001.md)、[生产IO稿v0.2](../../planning/design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md)已保存读回，包含84.25MiB与生产bulk/CDC候选；现由下段SLOT-JOIN明确容量档，真实实体/schema/完整资源仍未联合冻结或完成整包独立审阅。实际更新包controller/PHY存在；v1控制器16文件与工程/约束/历史报告等22项和原v1完全同hash。此前缺项准确为匹配2Gb器件仿真依赖和新完整工程验证，不是控制器一概不存在。

新增[六源三结果联合稿v0.1](../../planning/design-TRACK4-ALGORITHM-SLOT-JOIN-001.md)按整体→owner→容量/交接→中文操作→验证/追踪组织，明确全局六SRC、三结果、单scratch以及最多两物理视频bundle引用。旧PIO两源两结果不再作为当前整合容量档；21typed私有对象与三份持久RECORD有[独立对齐/guard地址清单](01_baseline/production-slot-layout-v0.1.json)，AUX使用428928B，尚余619648B未分配。新SOURCE_OFFER182显式携epoch/source身份；信用/绑定/失败返还和AUX登记/归还为新候选合同。profile预留、实际目录、bulk/服务界与完整资源仍OPEN，联合稿NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED，不把地址算术当软件验证通过。整合v0.4已保存[同hash快照](../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.4-before-slot-join.md)，旧审阅仍绑定原版本。

[本联合稿实际复核](03_review/slot-join-review-v0.1.md)保存各次输入hash和限定阅读范围；已补清成功提交后的信用结束事件、新旧KEY分离，以及当前VIEW发布/下一信用互不等待的交接。810bit仅新增KEY payload下界，目录、消息holding、状态和全机资源另计；复核没有运行协议测试或物理工具。

新增[PROFILE/源借用/冻结候选v0.1](../../planning/design-TRACK4-ALGORITHM-PROFILE-SOURCE-001.md)按整体→owner→实体/交接→中文操作→资源→验证追踪阅读；[纯数据布局](01_baseline/profile-store-layout-v0.1.json)选一RAM10保存八份完整1024bit，52word/份，8320bit含padding。O内部管理真实ref/持久seal，epoch内不可变；同SRC各lease独立返还，PCTX65跟随历史J，冻结借VIDEO实际snapshot，NO_ACTIVE可WAIT_FIRST并接受RESUME。新SOURCE311/BIND1012等显式覆盖旧联合源族，旧数字仍保留为历史版本。[实际审阅](03_review/profile-source-review-v0.1.md)按各输入hash绑定：seal目录已补1808bit，独立OBS可能占第六源并阻第七CAP/ARM，不能据条件角色式证明基础持续采集。精确门值/GT、完整目录/cache/错误、COMMIT/CDC/服务及全机预算仍OPEN，测试/实现仍NOT_RUN。整合v0.5已留[同hash快照](../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.5-before-profile-source.md)。

新增[连续采集/DDR/行预取候选v0.1](../../planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md)按整体→owner→D1五ring容量→D2单COPY目的/身份→D3真实DDR边界及R_ROUTE/W_CTX→D4行/native→D5真实clock→中文操作/验证阅读。六immutable SRC外另加五camera ring，原84.25MiB对象段加40MiB成为124.25MiB；[纯算术数据](01_baseline/production-service-arithmetic-v0.1.json)不授运行资格。F/OBS/历史bundle不长期pin采集ring；冻结补源不等已关source gate/J，旧RX残存不允许换route。[实际来源/审阅](03_review/production-buffer-review-v0.1.md)保存A056初稿全文协议和BCAA修订限定复核。行6480B/405 AXI拍、最多8burst与720word写分计；input18/RX7的25RAM payload独立于原output15。采集关闭/预ARM/reuse、COPY份额、row期限、完整消息/decoder/全预算仍OPEN，不称全部FPGA已证明可实现。整合v0.6已存[同hash快照](../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.6-before-production-buffer.md)。

独立[IP预检最终记录](../track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)按v1/v1.1/v1.2及本地审计例外执行：C0第三次综合、官方调试合并及PT通过，PNR在packer缺原USER1 TDI/TDO失败，未进入placement/route/STA；C2原样综合通过。C0/C2 Questa原语通过、CSI无解密key使DUT失败。C1跳过，且Ti60 PLL#4固定regional，PIO v0.2已标候选不可落地；新的100MHz core已有其它global来源候选，但不代新STA。C2修正/C3因外部clock未闭合停止。预检TERMINAL_WITH_FAILURES，不是算法实现批准或整包完成。后文“工具未运行/无例外”仅就整包算法及历史截面而言。

新增[生产行流水局部稿v0.2](../../planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md)，按B整体→C连接→D历史RowCtx/本地租约→E1解包/E2预取/E3数学写入/E4逐沿与容量→F/G/H阅读。[纯算术几何](01_baseline/row-packing-arithmetic-v0.1.json)明确405 AXI拍、720逻辑写事件、2880 native lane写；两RGB128/两EDGE16/两ANN16合320bit缓存，pending必须占预约槽。物理RGB色序显式重排，1920行恰2304词、末tail0无额外word；input银行归还独立于整行/scan退休。五RowCtx上界、1219bit数值payload与40RAM payload均有条件且不是全机预算。[实际有限审阅](03_review/row-pipeline-review-v0.1.md)绑定保存稿及具体范围；原首行身份循环现由下段SCAN候选明确提前exec，完整bulk/私有退还/全局接线、三bank周转与DDR最坏服务仍OPEN。本增量已接入整合v0.8，原PIO作为冻结来源由新SCAN显式覆盖，NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED，不称FPGA整包实现已证明。

新增[提前扫描身份与真实采用v0.2](../../planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md)，按整体→四ctx/父引用→PREPARE/ARM_SET/独立STOP/EVENT→中文采用、退休、snapshot/reset→验证追踪阅读。exec提前真实授予，physical frame只真边界观察；双未来首行各独立，三out/两input不增加。ARM结果实际转交后解membership，异常kind3保留真实前缀而不授关闭；DISPOSE临时refs与成功ACK消费后的持久pin分开，V owner0须汇合下级实际epoch ACK。[原稿审阅](03_review/scan-reservation-review-v0.1.md)与[修订及接入有限复核](03_review/scan-reservation-review-v0.2.md)分别绑定具体hash；body29598/摘要快照708合30306与adapter638均是下界，完整接口、资源和最坏服务仍OPEN。整合v0.8及行卡v0.2已明确接入，原PIO/PROFILE/VIEW源hash保持，不能据局部设计复核宣称十一项已经实现或通过工具。

先读[完整软件设计包 v0.3](../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)B/C/D，再按[阶段路线 v1](../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)进入局部：[R1 v1](../../planning/design-TRACK4-ALGORITHM-R1-001.md) READY且未批准；[R2 v0.3](../../planning/design-TRACK4-ALGORITHM-R2-001.md) LOCAL_DESIGN且未READY。整包NOT_READY/NOT_APPROVED，完整算法/十一项/硬件均未完成。

按“一次过”的目标继续补齐全部必需设计和交接，再以明确版本集合、范围和基线统一提交审批，获批后连续实施和软件验证。已有R1单批请求保留，但只能覆盖其范围。先前整体受阻判断已[更正](03_review/design-continuation-note-v1.md)：实施有审批门槛，后续设计仍可继续；不是新的实现授权。

| 次序/目录 | 保存内容与阅读目的 |
|---|---|
| 00_scope | [十一项映射](00_scope/requirements-map.md)，确认当前做什么及后续位置 |
| 01_baseline | [R1 ALGO-BL-v1](01_baseline/algorithm-baseline-v1.json)22份来源；[R2候选基线v0.3](01_baseline/algorithm-r2-baseline-v0.3.json)39份来源，尚非整包冻结；旧30/35来源清单按其历史版本核对 |
| 02_design | [R1中文阅读/步骤](02_design/reading-and-operation-sketches.md)及[R2流段v0.1阅读](02_design/canny-stream-reading-and-operation-v0.1.md)、[C0任务/错误/终态新草图](02_design/canny-stream-controller-sketches-v0.1.md)及[OBS记录/工程草图](02_design/canny-observer-project-sketches-v0.1.md)，先整体→接口→局部→逐沿 |
| 03_review | [R1设计审阅](03_review/review-v1.md)、[R2 v0.3/OBS组合审阅](03_review/r2-review-v0.3.md)、[历史R2 v0.2/C0审阅](03_review/r2-review-v0.2.md)、[历史R2 v0.1审阅](03_review/r2-review-v0.1.md)、[继续设计说明](03_review/design-continuation-note-v1.md)；审查/读回按版本保留，历史hash不替代更新文件核对 |
| 04_validation | [验证路线](04_validation/verification-plan.md)及各局部G/H，模型/协议/综合/PNR/STA/bit分别记状态 |
| 05_delivery | [交付边界](05_delivery/README.md)，未来真实日志/产物/中文操作与bit后停止 |

源码、参考、TB、功能脚本、project/peri/SDC只在 _fpga_edge_agent/work/active/track4_algorithms_20261004/ 的独立副本。当前R2的B01/B02/B04仅在设计层面关闭，B03/B05仍在推进；所有功能/工具验证仍未运行。历史[R2主稿v0.1](../../planning/design-TRACK4-ALGORITHM-R2-001-v0.1.md)与[整包主稿v0.1](../../planning/design-TRACK4-ALGORITHM-BATCH-001-v0.1.md)可与旧审计hash对应。

当前工作目录尚未创建；文档目录不混入可执行业务代码。

生产1920×1080保持。R1图样/CRC外壳可暂停且低速，用于保留算法/约束/工具证据，不是HDMI60Hz或相机fps。真实4pin工程先用25MHz；100MHz性能后续须有真实STA。

数据库尚未配置，独立本地审计如需采用须明确例外；正式状态/Manifest/数据库不伪造修改。当前无本次业务源码和工具实现结果。

## 已合并的OBS与待完成的控制/显示

[Canny OBS工程草图v0.1](02_design/canny-observer-project-sketches-v0.1.md)补608bit记录、32bit分组CRC、公平仲裁、早错误终态、源故障/恢复、独立四pin/40ns工程及预算；[控制/显示来源整理v0.1](02_design/control-display-source-contracts-v0.1.md)明确8 preset/6业务mode、精确手势/阈值及mode0重复偶行访问计划。候选[35来源清单](01_baseline/observer-design-inputs-v0.1.json)仅供这些设计输入，不是完整软件批准基线。

OBS最终附件已完成两路全文设计审阅，见[OBS审阅v0.1](03_review/observer-review-v0.1.md)；R2 v0.3纳入IF09…11/OP07及其行为、CRC、终态、pin/时序预算。当前组合审阅与[本版文档检查](03_review/document-checks-r2-v0.3.json)绑定v0.3实际文件。B03/B05仍OPEN，整包NOT_READY/NOT_APPROVED；控制/显示来源整理尚不是新接口冻结。新[核心流段与OBS逐文件合同v0.1](../../planning/design-TRACK4-ALGORITHM-R2-FILES-001.md)补共享FE复用、21份RTL/模型/脚本/工程计划文件与10份TB、阶段schema/向量/退出和验证归属；这是已完成最终数值合同审阅、仍待完整组合与套件冻结的B05候选，未合并为完整文件基线。OBS不能替代完整视频/闭包/识别。旧审阅/检查绑定旧版本及旧README hash，不套到更新入口。

## 新控制与图像重放候选

按整体→局部→交接顺序，读[单core控制设计v0.2](../../planning/design-TRACK4-ALGORITHM-CONTROL-001.md)B/C/D，再读[完整结果重放与像素渲染v0.2](../../planning/design-TRACK4-ALGORITHM-REPLAY-001.md)B/C/D/E。两稿原v0.1已同hash保留快照，v0.2按独立审阅修订并实际全文读回；[B03交接审阅](03_review/b03-handoffs-v0.1.md)记录重复RQ、高水位/epoch、回复原因和序号分配问题与修订，最终修订复核以该记录为准。两稿均LOCAL_DESIGN/NOT_READY/NOT_APPROVED/NOT_RUN；它们不是已合并的B03接口或整包实施基线。

控制J657/V788与重放PLAN616属于不同消息。完整结果owner、source/result/render/display/plan身份分配、真平面完成证书、借用/关闭与返还必须由R4/适配层联合冻结；不得按相同字段宽度直接相接。配置已采用、图像已借用、像素已交付和生产显示已生效各有实际事件。正常关闭与错误隔离都须保留真实已交付前缀，不能用终态存在或empty代替资源已经归还。R3/profile、R4实际provider、R5固定视频/生产资源及B05共同文件/测试/基线仍OPEN。

## R3数值与R4闭包设计入口

[R3独立typed数值核v0.2](../../planning/design-TRACK4-ALGORITHM-R3-001.md)已保存，并保留不可变原版快照。[首次设计审阅](03_review/r3-initial-review-v0.1.md)记录TLS字段padding、独立final诊断与精确ROM合同；[响应与取消修订审阅](03_review/r3-canonical-review-v0.1.md)绑定当前v0.2，明确成功/错误/DROP原因码和同沿取消优先，已获独立修订复核。R4调用/共享/完整算法/文件与工程交接仍OPEN，保持LOCAL_DESIGN/NOT_READY/NOT_APPROVED/NOT_RUN。

[R4精确闭包设计v0.2](../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)定义完整CLASS加载、精确八邻域BFS、claim/enqueue原子可见、全N EDGE导出与真实关闭；[局部审阅](03_review/r4-closure-review-v0.1.md)记录寻址单位、成功/失败/取消终态、真CS/SEAL与取消回执修订，当前稿已获独立复核。真实backend/目录/provider/完整bundle及R5资源仍OPEN。

[R4精确闭包资源比较](03_review/r4-closure-resource-comparison-v0.1.md)核完整N队列工作集与扫描等价证明、Ti60 native RAM几何、packing和同时存活代价。扫描省队列并不免除class/SRC/GRAD/ANN来源和吞吐义务；逻辑工作集不能当片上资源结果。全部生产分辨率及质量目标保持。

[VIEW/PLAN逐字段桥v0.2](../../planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md)补唯一owner、完整结果证书、两层引用、历史取消、真实退出及关闭后epoch授权；新增prejob源revoke/返还，覆盖有原图而尚无J的关闭窗口，不虚造job0。[独立修订审阅](03_review/view-bridge-review-v0.1.md)绑定当前C764稿，已复核临时接纳屏障、真实转移优先、撤offer授权、revoke_idle及PLAN_EXIT边界。它尚未合并到CONTROL/REPLAY，完整私有refs目录退休/provider/profile/R5/B05仍OPEN。阅读顺序为整包→CONTROL/REPLAY→桥B/C/D→局部E/F/G/H与审阅，再核真实R4交接；不能把桥证书当算法或存储已实现。

## 识别设计与软件实现架构

[完整分辨率识别设计v0.2](../../planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)按POINT→启发式种子/支撑→五遍圆/六遍TLS矩形→冻结核验/精确覆盖与去重→完整ANN/记录→真实关闭组织中文草图；[根审阅实录](03_review/r4-recognition-review-v0.1.md)记录实际完整读取、字段/容量与数值界核对。原v0.1已按86E8保存快照；v0.2修订失败CLOSE_ACK、IDLE同沿取消、冻结TERM及控制回执排空规则，当前独立修订复核已完成，三项局部反例已关闭；实际目录、后端与整包仍OPEN。

当前保守逻辑容器17,526,269B，另有SRC/GRAD/EDGE、目录、pending、ROW/ROM及R3；这些没有映射成Ti60片上资源。启发式遗漏纳独立GT；搜索预算未完成为SEARCH_INCOMPLETE，真实表满为CAPACITY，均不发布前缀。生产profile、完整可综合后端与性能架构、GRAD收集、实际私有返还和RECORD辅助目录/完整bundle、epoch/B05/R5尚未冻结。完整分辨率、精确Canny及P/R95%目标保持，不能以局部top或主机数组证明整包实现。

[本机工具与引脚证据](03_review/r5-tool-pin-evidence-v0.1.md)区分当前Ti60F225/I3封装/时序模型、四pin/40ns观察候选、Questa近期LED仿真实录和旧VF工程。当前工具文件存在且历史普通仿真成功，不代表新算法仿真、综合、PNR、STA或bit已运行。此前该段要求冻结无DDR架构；最新用户回复已撤销该限制，当前继续核板載DDR生产适配、全机资源/QoS和实际工具证据，不将历史调查当已验证的新实现。
