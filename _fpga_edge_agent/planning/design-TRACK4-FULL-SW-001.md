# TRACK4-FULL-SW-001：完整软件实验主计划 v0.21

> 2026-10-04 最新用户更正已生效：停止 V4 具体外部存储器件相关核查/模型申请/校准和 DDR/IP 预检审批。当前执行次序改为[算法优先路线 v1](design-TRACK4-ALGORITHM-ROUTE-001.md)与[独立 R1 v1](design-TRACK4-ALGORITHM-R1-001.md)，新入口为[算法实验目录](../experiments/track4_algorithms_20261004/README.md)。下文旧器件/平台串行依赖及待问事项留作历史，不阻塞新算法设计；新范围仍需指定批准，T4-A3暂缓而非完成。


按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)创建。2026-10-04；整体布局/交接仍为v0.1，本主计划v0.21记录FRONTEND v1、帧管理v0.1、Canny v0.4窗口/存储/父任务与writer草图及DDR服务v0.1、识别v0.1、平台v0.1与引脚/摄像头来源复核、相机v0.1的配置/RAW10/window/writer/关闭，以及显示v0.1的行预取/实际扫描/渲染/冻结详细草图，以及CONTROL v0.1四键/配置/生命周期草图和CONTROL-JOIN v0.1联合阶段，以及DATA-JOIN v0.1身份/授权/阶段/借用与物理回收联合草图，并补充RECOGNITION-NUMERIC v0.1、本地官方接口依据、RECOGNITION-ALGORITHMS v0.1与RECOGNITION-EXECUTION v0.1算法/资源候选，并补整机RESOURCE-SERVICE-BUDGET v0.1诊断及STORAGE-LAYOUT v0.2物理布局与IP-PRECHECK v1有限工具实验设计。**整机尚未READY，未获得业务实现批准。**局部范围单独绑定版本和基线。

## 通用计划字段

- Goal：按规范完成Ti60F225/V4＋SC431HAI彩色的5基础＋6高阶单一多模式软件工程，包含先行设计、中文操作草图、实现、软件仿真、综合、合理引脚/时序约束、布局布线/STA及bit/hex交付；本次不执行比特流之后的硬件步骤。
- Current state：原参考与工具存在，已有最小LED/普通RTL证据，完整11功能未实现。整体目录/布局/交接已完成；[FRONTEND v1](design-TRACK4-FRONTEND-001.md)为READY待批准；[FRAME-MANAGER v0.1](design-TRACK4-FRAME-MANAGER-001.md)、[CANNY v0.4](design-TRACK4-CANNY-001.md)、[DDR-SERVICE v0.1](design-TRACK4-DDR-SERVICE-001.md)、[RECOGNITION v0.1](design-TRACK4-RECOGNITION-001.md)、[PLATFORM v0.1](design-TRACK4-PLATFORM-001.md)、[CAMERA v0.1](design-TRACK4-CAMERA-001.md)、[DISPLAY v0.1](design-TRACK4-DISPLAY-001.md)、[CONTROL v0.1](design-TRACK4-CONTROL-001.md)、[CONTROL-JOIN v0.1](design-TRACK4-CONTROL-JOIN-001.md)、[DATA-JOIN v0.1](design-TRACK4-DATA-JOIN-001.md)、[RECOGNITION-NUMERIC v0.1](design-TRACK4-RECOGNITION-NUMERIC-001.md)、[RECOGNITION-ALGORITHMS v0.1](design-TRACK4-RECOGNITION-ALGORITHMS-001.md)、[RECOGNITION-EXECUTION v0.1](design-TRACK4-RECOGNITION-EXECUTION-001.md)及[整机预算诊断v0.1](design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)、[存储布局v0.2](design-TRACK4-STORAGE-LAYOUT-001.md)为LOCAL_DESIGN；正式H0及DB未验收。
- Target state：完整11项在一个工程中有实际源码、可重复软件测试、综合/布局/STA报告和bit/hex；需求到代码/测试和反向追踪完整。设计文档或局部单元完成不替代整机完成。
- Gap：匹配DDR器件模型/PHY兼容、时钟/IO约束、局部逐拍数值/状态、真实资源与识别范围仍需完成；见05阻塞清单。
- Assumptions：假定V4 Ti60F225 I3、SC431HAI彩色MIPI；1080p单整机、HDMI60Hz；真实相机fps/相位/板号未确认；计算预算不等于性能通过。
- Open questions：模型来源/使用条件及官方获取授权、受保护核心实际Questa兼容、合理SDC、识别质量—吞吐—资源最终范围。
- Dependencies：现行v0.2、V4 v6归档、既有工具及审批，匹配2Gb器件/PHY仿真材料。正式DB未配置不冒充已恢复。
- Milestones：M0需求/基线→M1整体图/交接→M2外部依赖与平台预检→M3分批局部设计/批准→M4对应实现与回归→M5整机综合/PNR/STA/bit交付；M1已完成，M2待模型获取授权，M3已有首批设计，最终目标仍为M5。
- Detailed steps：按[实验入口](../experiments/track4_full_sw_20261004/README.md)00→01→02→03阅读；04/05定义后续详细设计和审批；07维护验证/追踪，06/08/09为未来真实内容分类。
- State transitions：整机处于LOCAL_DESIGN；局部范围可独立达到READY并等待指定批准，不能将其提升为整机READY。尚未进入IMPLEMENTING，不写入正式PROJECT_STATE状态枚举。
- Artifacts and hashes：[baseline-manifest.json](../experiments/track4_full_sw_20261004/01_baseline/baseline-manifest.json)列24项实际输入SHA256，v6归档及60项引用；本轮文档哈希由检查记录登记。无新bit/hex。
- Validation：实际本轮文档检查与未来功能测试分开；[07验证计划](../experiments/track4_full_sw_20261004/07_verification/verification-plan-and-trace.md)全部软件测试未运行。
- Failure handling：影响正确性的未知明确BLOCKING；源/结果错误不发布，旧事务排空后回收；资料不足/未经批准的动作不执行。
- Human approval gates：本轮目录与文档由当前用户授权；未来每批完整设计达READY后批准指定版本/范围/基线，另核对工作副本与构建/模型获取审批；硬件人工闸门保留。
- Rollback：本轮全部新增在experiments/track4_full_sw_20261004及本主文档；原资料/正式状态不修改。需要撤回时先保存检查记录并只处理这些新增文档，不删除参考包或旧任务。
- Completion criteria：逐项证明11项功能、接口/身份/错误、真实仿真、整机资源/综合/布局/STA、约束及bit/hex和操作文档；所有未实现/未运行项清楚列出。不能因目录/设计齐全或局部通过就宣称本目标完成。

## A. 状态与阅读入口

- 关联节点：H0/H1/H2/H3/H4/H5、A1…A6、R0仅作为需求引用，不修改其正式状态。
- 主计划v0.21、整体架构v0.1；实施范围当前为空；批准状态NOT_APPROVED_FOR_IMPLEMENTATION。
- 授权原意：先前获准整理目录及整体草图；随后用户要求“接下來则需要你按照規则, 通过软件去一次过完成本次的測試”。完整目标继续推进，规则规定的指定版本/范围批准仍需完成；不将总体目标解释为已批准刚生成的局部设计。
- 阅读：[入口与顺序](../experiments/track4_full_sw_20261004/README.md)→[需求](../experiments/track4_full_sw_20261004/00_scope/requirements-and-decisions.md)→[前置证据](../experiments/track4_full_sw_20261004/01_baseline/preconditions-and-evidence.md)→[整体图](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)→[交接](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)。
- 本任务与FIFO-SMOKE-001不同，不沿用或假定其批准。新资料检索/下载仍须既有规则授权。

## B. 整体外部行为

见00全部T4/UC/DER及02第1、5、9节：相机与控制输入→灰度/median/Sobel或完整Canny/识别→同源HDMI；冻结源帧可重处理，慢任务选择最新完整帧，模式随bundle完整换页。正常与边界/失败样例是S-01…S-04，不只有最终静态图。

识别两组尺寸/噪声/遮挡建议已被用户撤回固定确认，改为Agent评估轴；另行95%P/R与IoU≥0.5目标保留。官方视频提交条款本次标为硬件阶段未执行，不删要求。

## C. 模块职责与整体连接

见02文本与Mermaid图、MOD-01…12职责卡和双路径：基础直播同源流计算，源RGB独立完整入DDR；冻结/帧级任务从DDR完整源进入共享前端；Canny精确8邻接后可分时识别；原RGB与结果引用合为bundle。MOD-04拥有槽/配置/任务，MOD-05管理有限DDR请求，MOD-11拥有显示引用。

复用来源、保护IP/许可/版本证据及限制在01说明；不是根据文件名假定已能复用。系统级划分和重要选择已在本轮保存，下一阶段是局部设计及实施阻塞消除。

## D. 接口与组合设计检查

见03 IF-01…14、CC-01…11及N/B/F走查。关键规则：源/结果写响应收齐才完成；结果槽先于源领取；6源/3结果槽保守预算；pending深度1；VSYNC原子bundle；旧显示RETIRING读排空前继续占槽；配置快照；相机不能反压；旧epoch不发布。DDR失效用独立安全图案，无法排空的槽隔离至安全复位。

当前是逻辑接口。物理端口、完整signed/位宽、逐拍延迟、RAM冲突、仲裁/FIFO数值与CDC最终实现仍缺，不能将系统语义表替代局部端口契约。

FRAME-MANAGER v0.1补充三项必须吸收的组合条件：六源槽证明必须包含EOF后写租约，下一SOF空槽还依赖最坏排空期限；冻结须从显示域真实active快照移交引用；原frame_buffer的bank_sw不检查B响应，不能作为新源/结果提交。旧整体02/03作为FRONTEND冻结输入保持不变，这些缺口由局部稿显式覆盖，待整机新版本统一修订。

## E. 局部详细设计

整体中文草图S-01…S-04已存在；首批[FRONTEND v1](design-TRACK4-FRONTEND-001.md)完成MOD-06/07灰度、两级两行窗口、中值和Sobel的端口、状态、OP-01…07中文步骤、逐拍与数值、参考/向量/脚本交接、FT-01…12验证计划。其他局部设计仍需按[04目录](../experiments/track4_full_sw_20261004/04_local-designs/README.md)分批完成。

第二批[FRAME-MANAGER v0.1](design-TRACK4-FRAME-MANAGER-001.md)已写FM-01…08、8接口、8中文操作草图、10不变量和12验证场景，保持LOCAL_DESIGN。DDR地址/完成和平台时钟/引脚新增证据保存在01分类；它们定位了实际调用链及差异，没有替代仿真、器件资料或最终SDC/引脚审查。

第三批[CANNY v0.4](design-TRACK4-CANNY-001.md)提出默认5×5单次舍入高斯、新Sobel/整数方向、NMS平台政策、严格双阈值、2bit状态及精确八邻域闭包；包含8主操作草图、有限队列/cache/forward、取消burst义务与26文字验证场景。[中文窗口/流段附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-window-sketches-v0.2.md)补四行ring、有效TAIL、NMS byte平面/外框原幅值、ARM/start/FE状态/fork同沿交接；[存储附件v0.3](../experiments/track4_full_sw_20261004/04_local-designs/canny-memory-sketches-v0.3.md)补cache RAM/FSM、原子claim、滑动银行/prefix/共享口、分段承诺及早失败terminal；[父任务/writer附件v0.4](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md)补完整917bit job、六级Sobel/四方向、顺序bank/两个W槽、LOCAL_OK先于fence、23阶段和冻结status/MC复位保持；[12区地址候选](../experiments/track4_full_sw_20261004/01_baseline/canny-candidate-address-arithmetic-v0.4.json)页分配55,226,368B。实际父grant/fence/恢复与MOD-05/真实地址/六源期限/识别租约/性能仍未闭合，不扩大为READY。新增writer4块后当前小计44RAM，未修改旧整体冻结输入。

第四批[DDR-SERVICE v0.1](design-TRACK4-DDR-SERVICE-001.md)细化MOD-05的8项要求、8个交接、8项中文操作草图、10不变量和16文字场景：完整scope623/grant241、permit与实际req266、14叶请求RR、独立物理R/W owner、完整段池/逐client返回、终态与release ACK、阶段封口/fence和恢复。真实模型/物理行为、相邻端口、采集显示期限及全机资源仍有8项阻塞；D3列与现有FM/Canny/03的必要差异。原稿复审修正先seal后dirtyWB死锁、终结后pending复活、首次物理valid同沿冲突、池slot与release互等及冷记录位数。[RAM来源](../experiments/track4_full_sw_20261004/01_baseline/ddr-service-ram-evidence-v1.md)支持数据池14+metadata3共17块候选，当前Canny44+服务17=61块，仅已列小计，未综合。

第五批[RECOGNITION v0.1](design-TRACK4-RECOGNITION-001.md)细化完整grad32法向、32角桶16B尾、四不可重开phase、圆/旋转矩形/三边候选、原图核验和同源ANN预生成。五TEMP子区与ANN独立授权、九PROCESS grant、25峰预算尚待父/DDR/显示吸收；[新增地址算术](../experiments/track4_full_sw_20261004/01_baseline/recognition-candidate-address-arithmetic-v0.1.json)在原图之后追加34,856,960B，不修改旧12区。当前列出的识别58+Canny44+服务17=119/256 RAM仅容器小计；图外圆/同格多中心/三边歧义、整数拟合/阈值、真实资源/期限及95%质量仍BLOCKING，16场景全部NOT_RUN。

第六批[PLATFORM v0.1](design-TRACK4-PLATFORM-001.md)给出4PLL/各域及KEY1/NC/14地址/HDMI PN来源、8交接/8中文草图/16文字场景；暖保持、AON完整镜像、PREPARE→FINAL独立恢复、sticky stop_new与FIFO/mailbox会话形成候选。[原理图/封装证据v2](../experiments/track4_full_sw_20261004/01_baseline/board-pin-source-evidence-v2.md)闭合主要资料映射；[摄像头证据v1](../experiments/track4_full_sw_20261004/01_baseline/camera-source-and-phase-evidence-v1.md)明确启动表次序、ACK缺口与phase条件推断。所列119+平台30=149 RAM仅双FIFO候选小计；冷初始化/真实PHY、相邻端口/容量/STA仍8项BLOCKING，不扩大为READY。

第七批[CAMERA v0.1](design-TRACK4-CAMERA-001.md)细化配置成功、完整lease/ARM、raw observations与NORM192分层、真实末pair边界、四phase/reflect101/RAW10单轮量化、两源bank/分段W与可选FP74 live FE。八项交接/八中文草图/24文字场景、观察392/window/attempt、资格202及closure363消费水位、独立abort与status→return→CLOSE次序均已保存；[窗口/writer附件](../experiments/track4_full_sw_20261004/04_local-designs/camera-window-and-writer-sketches-v0.1.md)补逐沿/组拍/FE与12文字场景，[CSI/配置来源v2](../experiments/track4_full_sw_20261004/01_baseline/camera-csi-and-config-evidence-v2.md)保留实际5.15/5.16区别、Group Hold上限和ACK缺口。新增13、合162RAM只是已列预算；8阻塞及所有测试NOT_RUN，未扩大为READY。

第八批[DISPLAY v0.1](design-TRACK4-DISPLAY-001.md)细化完整render112/OFFER1963、三双clock行bank、固定1080p60、6pair渲染、原SRC冻结、bank/scan/scope三级关闭。八要求/八交接/八操作/十不变量/24文字场景及[取数/扫描中文附件](../experiments/track4_full_sw_20261004/04_local-designs/display-fetch-and-scan-sketches-v0.1.md)15场景已保存；current_exec与future_plan分开，SELECTED1013/CLOSED921独立槽及safe有预取义务的未选决定闭合。旧FIFO9被21RAM替代，已列162−9+21=174仅预算；8阻塞及所有测试NOT_RUN。[VF/Demo补充证据](../experiments/track4_full_sw_20261004/01_baseline/vf-demo-supplemental-evidence-v1.md)定位已有DDR/PHY与可读TMDS编码候选，匹配2Gb参数/时序依赖仍缺，未将C4工程约束混入V4/I3。

第九批[CONTROL v0.1](design-TRACK4-CONTROL-001.md)细化四键消抖/互斥手势、独立AON复位、Sobel/Canny分开阈值与八preset、D/P/C有界快照、T/R恢复及观察。八要求/八IF/八中文OP/十不变量/24主文字场景；[人工操作附件](../experiments/track4_full_sw_20261004/04_local-designs/control-human-operation-sketches-v0.1.md)说明先整体再局部、波形/状态读回，[来源](../experiments/track4_full_sw_20261004/01_baseline/control-keys-and-reset-evidence-v1.md)确认四键/两LED及旧KEY1 raw reset冲突。回复274、SOURCE_UI134、CFG212/committed570/proposal605/receipt1182/done938仅候选；原父稿必须吸收，8阻塞仍LOCAL_DESIGN。新增RAM0，已列174仅预算。实物验证明确在本次bit之后，不把硬件到货作为软件工作前提。

第十批[CONTROL-JOIN v0.1](design-TRACK4-CONTROL-JOIN-001.md)联合配置、冻结/恢复、策略门与AON合同；[阶段中文附件](../experiments/track4_full_sw_20261004/04_local-designs/control-join-phase-sketches-v0.1.md)及[读审](../experiments/track4_full_sw_20261004/05_reviews/control-join-review-v0.1.md)先整体再阶段/反例。独立R669、阶段914/920、snapshot1353/1359；已valid COMMIT必须兑现，早到R仍先成功SNAP屏障后ABORT；失败/Q不盲用pF恢复；保冻结算法切换不撤FREEZE；result在形成job前锁C。八要求/八IF/八OP/十INV/24场景仅文字，CJ-B01…06保留，LOCAL_DESIGN，不是整机端口或实现批准。

第十一批[DATA-JOIN v0.1](design-TRACK4-DATA-JOIN-001.md)把八个联合IF和八项中文OP集中在单份A–L主稿；[实际读审](../experiments/track4_full_sw_20261004/05_reviews/data-join-review-v0.1.md)核对两方向最终版本。首SOF前锁Origin/ARM，START_CLOSURE788/794区分未启动证明；FE_BIND1628及三分支退出、独立FS/DISCARD；phase350/证书410/LOCAL231/borrow702及各ACK，算法归还不释放物理BIND；PLAN_ACK528、current/future与bank/scan/bundle三级关闭。六源/三result、scope11/grant25/phase20是有条件上界，reader双bank新增4RAM到178。24文字场景均NOT_RUN，真CSI/PHY/serializer、RC实体及最坏服务/完整资源仍DJ-B01…05，执行前置B06，LOCAL_DESIGN。主稿J明确覆盖旧候选且旧字节保留，不由本稿推出整机READY。

第十二批[RECOGNITION-NUMERIC v0.1](design-TRACK4-RECOGNITION-NUMERIC-001.md)补齐已定义的POINT/角度/对称ρ、候选记录和共享宽算术契约，先整体交接再局部中文草图及文字验证。θ查128边界最坏8次，277有效ρbin/235保留bin、负数RNE及276−r镜像明确；两独立查表ROM增加2RAM，最新已列180/256仅预算。候选覆盖、分段/三边辨识、profile选择/完整质量与执行依赖仍保留阻塞，不由数值容器推定95%或整机READY。[本地官方依据](../experiments/track4_full_sw_20261004/01_baseline/vendor-interface-contract-evidence-v1.md)补配置后25µs复位、异步LOCKED及LVDS同PLL/相位关系；真实CSI/soft-DDR/10bit关闭合同仍缺。

第十三批[RECOGNITION-ALGORITHMS v0.1](design-TRACK4-RECOGNITION-ALGORITHMS-001.md)与[实际读审](../experiments/track4_full_sw_20261004/05_reviews/recognition-algorithms-review-v0.1.md)明确圆anchor/rank有限选择、全半径双峰与固定五遍拟合；矩形DENSE16/512角、49offset/run、SEGMENT384缓存及TLS0/1/2、三/四边构造；最终量化membership、精确集合去重、VC400互斥池及字体/ANN。PROFILE layout2/algorithm2及旧条款覆盖列于新稿D/J，原父稿字节不改。新增FINE26/NMS4/计票15后最新225/256 RAM只是已列预算；完整FF/DSP、局部word/FSM/coverage及真实服务界仍AG-B01/02，质量NOT_RUN和外部/批准前提保留，LOCAL_DESIGN，未达READY。

## F. 语言与跨语言契约

候选工具为Efinity2026.1.132/Questa2024.1；v6当前语言SV2009，新增语法必须核对工具支持。RTL A–L各项在本轮仅完成系统前提：RAW10/RGB888/Y8、身份/坐标、不可暂停采集、配置边界、复位epoch、存储角色、CDC边界和资源预算；局部数值扩展/舍入、真正接受/观察边沿、有效气泡、保持/推进、延迟、RAM同址、参数范围仍需详细内容。

本轮没有C++实现或C++↔RTL映射，故C++对象/RAII等不适用；未来如选择C++另补对应契约。FRONTEND已选择本机Python3.14.6标准库独立参考，并分别定义共同数值、RTL执行、软件结果到帧/坐标/配置的映射；其他局部范围继续补齐，参考结果不能替代时序/流控证据。

## G. 实施及验证计划（尚未执行业务）

见通用M0…M5及07 L0…L7、V-01…16。平台预检本身需要先形成窄任务设计和指定批准；获取匹配DDR模型优先于整机实施。基础显示/采集/灰度/Sobel逐增量，然后median/threshold、完整Canny、颜色叠加/识别及整机回归。并行只读调查不代表同意并发改业务代码。

## H. 双向追踪

07初始矩阵覆盖T4-B1…B5、T4-A1…A6和DER-01…09；每个MOD/IF有理由和验证场景。计划代码职责标“未实现”；真实符号/版本与实际证据在获批后填入。不能编造已存在文件/测试或Git commit。

## I. 设计门槛与评审

| v0.2门槛 | 本轮证据/缺口 |
|---|---|
| ①整体行为及样例 | 00/02已写，S-01…04 |
| ②职责连接和复用调查 | 01/02，12模块、实际v6源链 |
| ③接口/相容检查 | 03逻辑IF/CC完整；最终物理契约待局部 |
| ④局部数据/不变量/草图 | FRONTEND已详细设计；FRAME-MANAGER/CANNY/DDR-SERVICE已有草图/反例/数值与具体阻塞；RECOGNITION v0.1新增四phase/几何/ANN草图；PLATFORM v0.1新增复位/CDC/镜像恢复；CAMERA v0.1新增配置/像素/window/writer/关闭；DISPLAY v0.1新增三bank/实际scan/固定渲染/冻结及明确阻塞；CONTROL v0.1新增四键/AON独立复位、有界D/P/C/T/R、观察分层；CONTROL-JOIN v0.1明确控制阶段差异；DATA-JOIN v0.1明确内部数据/关闭合同，真实物理/RC其余数值与范围/最坏服务仍待闭合；数值/算法补充稿已形成，完整局部执行与资源/服务界仍未闭合 |
| ⑤语言/映射契约 | FRONTEND已写逐拍/数值/参考映射；整机其他部分仍待完成 |
| ⑥走查/需求覆盖 | 03/07正常与边界/错误系统走查 |
| ⑦实施/验证/追踪 | 本主文档与07 |
| ⑧无正确性阻塞 | 不满足，05 BL-01…08仍存在 |
| ⑨保存/读回/呈现 | 已保存；实际读回与呈现范围见05完成检查记录 |
| ⑩版本范围基线清楚 | 主计划v0.19、架构v0.1、FRONTEND v1/FE-BL-20261004-v1；FRAME-MANAGER v0.1/CANNY v0.4/DDR-SERVICE v0.1/RECOGNITION v0.1/PLATFORM v0.1/CAMERA v0.1/DISPLAY v0.1/CONTROL v0.1/CONTROL-JOIN v0.1尚未冻结实施基线 |

所以当前不标READY_FOR_REVIEW。本轮文档完成后可继续允许的调查和局部设计；在指定实现范围达到全部条件之前不生成业务源码、功能性脚本或可执行测试。

## J. 变更与恢复

本轮已记录两类重要设计修订：撤回识别固定范围；源槽预算由可能不足的5提高到6，并为基础吞吐提出同源流分支。都是批准前提议，未实施。恢复先读取本主文档、00最新用户决策、01基线、05阻塞和真实批准；不得仅凭聊天摘要写代码。

## K. 实现与验证实录

业务实现、编译、RTL仿真、综合、PNR/STA、比特流、实机均未执行。只读来源检查、文档新增/读回及完成审计见05；文档检查不能作为功能验证。无数据库登记或正式状态写入。

## L. 交付与阅读说明

已交付experiment的00–09分类、需求/基线、整体布局/中文步骤、系统级交接和初始验证追踪；本次增加FRONTEND详细局部设计、中文阅读/观察路线与独立评审。没有交付业务源码或完整整机验证。先读整体输入→双路径→帧/配置所有权→结果发布→显示，再读IF/CC；局部从04进入FRONTEND，再继续其余模块。

本轮再交付FRAME-MANAGER局部稿与两份只读来源笔记。原FRONTEND v1待批准版本和28项输入未更改；已有实现/模型获取两项申请未收到新答复，不重复创建批准请求。

后续交付CANNY局部稿及三方向只读审查；任务目标继续为全部十一项和真实bit/hex。局部稿完成不替代其接口闭合、获批实现或整机验证。

本轮再补CANNY v0.2窗口与流段详细中文草图，独立设计分析修正TAIL有效控制事件、外框历史原幅值及fork新pending覆盖旧清位；18场景均未运行。新局部草图和审阅保存在04/05，主计划索引同步，原FE/FM与正式状态不改。

前轮补CANNY v0.3存储草图及三方向只读复审：prefix纳入256槽、WB替换/FLUSH与失败出口分开、pin/安装取消、segment早失败终结和局部tag退休。22场景均未运行，当前文档审计重新绑定；原窗口v0.2/FE/FM保持不变。

本轮补CANNY v0.4父任务/方向/writer草图和12区地址算术，三方向只读复审修正非法job绑定返还、LOCAL_OK/fence互等、EOF恰满、EXPORT start/gather、复位时MC valid/pending/账本保持及隔离status快照。26场景全部NOT_RUN，当前审计重新绑定，原FE/FM/窗口/存储附件不改。

本轮再补DDR-SERVICE v0.1、20bit RAM来源和三方向实际读稿审查；共享服务的授权/事务/返回/封口/恢复已形成候选草图，16场景均NOT_RUN。主计划与索引升v0.8，FE/FM/Canny及原附件保持不变；官方模型与FRONTEND两项既有申请仍待答。

本轮再补RECOGNITION v0.1、地址候选及三方向实际读稿；scatter页gap/半拍、θwrap/rho、LS宽数值与status返还快照已校正。主计划/入口升v0.9；先前30份DDR阶段审计另存历史，当前文档重新绑定；业务实现与软件仿真/综合/PNR/bit仍未运行。新稿为LOCAL_DESIGN，无新增批准请求。

本轮补PLATFORM v0.1及原理图/封装v2、摄像头来源v1和实际读稿审查；修正OPEN/fault原子、冻结CLOSE、停钟后旧admit、两阶段恢复/新PHY隔离、消息容量、序号收尾预留和显示欠载坐标。主计划/入口升v0.10，先前32份识别阶段审计另存历史；既有FE/FM/Canny/DDR/识别稿与源基线保持，未新增批准问题。全部业务实施/仿真/综合/布局/bit仍未运行。

本轮补CAMERA v0.1、CSI/配置来源v2、窗口/writer中文附件与实际读审；修正跨域资格撤销、旧attempt/window隔离、末pair真实边界、closure消费水位、bank子段/heldW终结、缺EOF独立abort与FE满队/FJ取消。主计划/入口升v0.11，先前36份平台审计另存历史；既有各局部稿与24/FE28输入保持，全部业务实现/仿真/综合/PNR/bit仍NOT_RUN。

本轮补DISPLAY v0.1、取数/扫描中文附件、实际HDMI来源与VF/Demo补充来源和读审；修正SRC存在/扫描mask、current/future授权、safe未选义务、bank与scope流水借用、六pair逐沿、同op事务去重及fence并行关闭。主计划/入口升v0.12，前轮40份CAMERA审计保留历史；当前45份文档重新绑定，既有局部与输入不改。全部业务实现/仿真/综合/PNR/STA/bit仍NOT_RUN，下一步控制及联合端口吸收、依赖闭合。

本轮补CONTROL v0.1、四键/复位来源、中文人工操作附件及读稿审查；修正消抖21样本/20间隔、独立reset不受UI序号/停钟阻塞、同tick序号次序、完整CFG端点比较、拒绝识别preset仍可继续循环、来源/替代回执字段、有界D已提出标志、WAIT_FIRST独立R及终态容量、观察不反压业务链。主计划/入口升v0.13，前45MD DISPLAY审计保留原字节历史；当前49MD重新绑定，旧各局部/24及FE28输入不改。所有业务实现、功能测试、真实PHY、综合/PNR/STA/bit仍NOT_RUN；下一步联合接口吸收和正确性阻塞闭合。

本轮补CONTROL-JOIN v0.1与阶段附件、实际读审；修正独立R入口/父key、COMMIT曝光承诺、成功SNAP屏障、snapshot独立ACK、FAILED/Q隔离、目标分支及配置锁边界。主计划/入口升v0.14；前49MD CONTROL审计保存原字节历史，当前52MD重新绑定。仅控制范围明确覆盖旧候选差异，完整数据/关闭联合端口、RC实体、工具/模型和资源/时序依赖仍未闭合；全部业务实现/仿真/真实PHY/综合/PNR/STA/pin/bit仍NOT_RUN。

本轮补DATA-JOIN v0.1及实际读审，修正无SOF/迟到START、FE结束held FP、leaf封口与父ACK、所有旧grant移交、CAP写scope关闭后COMPLETE、phase一次完整集合/自身pin、reader组装与交付索引/g槽预约、双退休及本result释放范围。主计划/入口v0.15；前52MD CONTROL-JOIN审计保留原字节历史，当前54MD重新绑定。设计未知与获批后测试义务分开，不要求先写未批准代码证明READY；真实外部/RC数值/服务界仍未闭合。没有业务实现/可执行测试/真实PHY/综合/pin/PNR/STA/bit，正式状态/DB/原源不改。

本轮补RECOGNITION-NUMERIC v0.1、来源证据和实际读审，明确θ最坏比较、ρ对称/舍入、记录与宽算术容器；旧RC/DATA与源字节保留，差异仅按新稿J覆盖。主计划/入口v0.16；前54MD DATA审计保存原字节历史，当前文档按实际枚举重新绑定。全部业务实现/可执行测试/真实PHY/综合/pin/PNR/STA/bit仍NOT_RUN，正式状态/DB不改；未缩减十一项完整目标。

本轮补RECOGNITION-ALGORITHMS v0.1与实际交叉审查，修正phase2公式漏32E项、舍入重合率误去重、冻结geometry的fit诊断断链、原细线构造前置、seed半径/超域分支和绘图元数据；全部18文字场景NOT_RUN。主计划/入口v0.17；前57MD数值审计保存[原字节历史](../experiments/track4_full_sw_20261004/05_reviews/document-checks-recognition-numeric-v0.1.json)，当前文档按实际枚举重新绑定。全十一功能目标继续，未生成业务实现/可执行测试、未运行真实PHY/综合/pin/PNR/STA/bit，原资料/正式状态/DB不改。

本轮补[RECOGNITION-EXECUTION v0.1](design-TRACK4-RECOGNITION-EXECUTION-001.md)，集中固定105块识别RAM的bank/word/互斥用途、圆五遍和矩形六遍成员、submask真实间隙、覆盖率首尾裁切、VC/FINAL完整提交、row/carry/sealed spool与4731/693/965候选job合同；15文字场景全NOT_RUN。最新局部29168bit仅已列容器、225RAM仍预算，全机资源/真实服务/质量与外部联合仍未闭合，LOCAL_DESIGN/NOT_READY/NOT_APPROVED。前59MD算法审计保存[原字节历史](../experiments/track4_full_sw_20261004/05_reviews/document-checks-recognition-algorithms-v0.1.json)，本轮实际读审和当前检查重新绑定；完整软件目标仍ACTIVE，原资料/正式状态/Manifest/DB不改。

改变一条需求时先在00找到REQ/UC，再沿07到MOD/IF和02对应S步骤；修订03组合前提及局部设计，之后才修改获批代码和验证。用户尚未对本轮落盘文档作实际理解作答，理解验收待检验，不阻塞本轮设计文档交付。

## 整机资源与服务预算诊断 v0.1

[预算主稿](design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)→[实际审阅](../experiments/track4_full_sw_20261004/05_reviews/resource-service-budget-review-v0.1.md)。统一225自写RAM与未知外部IP边界，区分FF容器/XLR packing/DSP物理块；DS列明31008与RC局部29168合60176bit，尚有全宽消息/控制/相机/显示；全宽FF直译不能声称容量闭合。NORM192两capture为同一槽去重，旧PIX9由row21替换。热冷映射与批处理只是明确优化比较，未选定新布局/改算法，完整热冷/真实IP/服务界及既有执行前置仍阻塞；整机NOT_READY/NOT_APPROVED。

显示mode5每row6480B，基本组装1248core机会/名义12.48µs，对14.8148µs行期只留2.3348µs，其余等待未证明。识别三个byte工作界合1907313868800B，只表示预算尺度，不是实测帧时；不恢复用户撤回的尺寸/目标数边界。旧Demo报告/DDR22仅历史参照，本次仿真/综合/PNR/STA/pin/bit/hex全部NOT_RUN。[执行历史审计](../experiments/track4_full_sw_20261004/05_reviews/document-checks-recognition-execution-v0.1.json)保留8BC7140A…8DA7A953，当前检查按实际文件重新绑定。原资料、正式H0/ledger/Manifest/数据库不改。

## v0.20追加：物理布局及真实资料边界

[STORAGE-LAYOUT v0.1](design-TRACK4-STORAGE-LAYOUT-001.md)→[实际审閱](../experiments/track4_full_sw_20261004/05_reviews/storage-layout-review-v0.1.md)。先全路径B/C→D1 RC/D3 DISPLAY地址与端口→E逐沿/关闭→F语言/数值→G/H验证追踪。RC105→91、DISPLAY21→17，自写候选225→207；18块是具体布局省额，不含完整metadata和外部IP。未选择DS/PL串行方案若随后联合采用会净加8到215；FIT/scalar/ASYN0均未计省额。

RNE sqrt192可能97bit、圆矩形VC同时保留、两份54bit pair holding共543bit数据及长控制包word_index均已修正。V4旧DDR39RAM包含桥17，PHY22不得当作当前完整DDR占用；旧CSI版本/FIFO与v6当前分开。用户指定VF/Demo有4Gb器件模型、controller/PHY/约束参考；当前匹配2Gb模型仍缺2048Mb参数头，不能写成没有DDR资料。

布局主稿与审閱保存读回、文档/原源hash和静态地址算术已登记05；新增12文字场景NOT_RUN。联合packed/状态/真实IP及最坏服务仍SL-B01…03，整机NOT_READY/NOT_APPROVED，无业务实现/仿真/综合/PNR/STA/bit。预算阶段审计169F4E5C62B42EB48A2549F808D35D40D7B36975A94380790C424E8DBD61FE68存[原字节历史](../experiments/track4_full_sw_20261004/05_reviews/document-checks-resource-service-budget-v0.1.json)，当前检查重新绑定。既有待批准问题不重复索取；正式状态/原资料/DB不变。

## v0.21追加：联合覆盖与有限IP预检

[STORAGE v0.2](design-TRACK4-STORAGE-LAYOUT-001.md)J精确覆盖RC/DP父地址、SEG19WE/DONE下一沿、PROFILE唯一实体和固定scan差异；[本轮审閱](../experiments/track4_full_sw_20261004/05_reviews/storage-layout-review-v0.2.md)记录DENSE六命名沿/II≥5、条件331776000周期机会及两336保持复用/取消低WE后配对高WE。RC91/DP17/自写207不变。DS/PL已定位字典缺口和journal两目的分步提交的双计反例，未选择串行架构、不把未知位填0。

[IP-PRECHECK v1](design-TRACK4-IP-PRECHECK-001.md)给出四个参考case及[89输入manifest](../experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.json)，限定原v1/v6实际连接的编译/综合/PT/PNR/STA证据；C2原样/修正SDC分别冻结并重跑，C3只派生修正基线，ASYN内部事务时序不宣称等价。其有限设计当前READY_FOR_REVIEW/NOT_APPROVED，已完成限定审查修正/保存读回，等待本v1/范围/基线批准；完整NORM/PPC、2Gb校准、最坏service和十一功能仍原目标。

主计划A旧v0.19已修正为当前v0.21；整体架构v0.1保持。原STORAGE v0.1及6FAA3792A8CAD9747EFBF4FADA5799B2F41E9D3234652CB2530A0498C628493B审计留原字节历史，当前检查重新绑定。全部业务/工具实验未执行，既有FE/模型PENDING不重复索取，正式状态/原源/DB不变。
