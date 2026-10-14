# 07 验证计划与初始双向追踪

> 2026-10-04 当前优先范围已改为[算法路线 v1](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)和[新目录](../../track4_algorithms_20261004/README.md)。停止原具体器件/PHY模型和 DDR/IP 预检推进/审批；旧相关表/阻塞项是历史整机范围，新R1采用独立算法接口与新基线，不能以本页旧依赖拦住它，也不能将算法局部通过升级为整机完成。


TRACK4-FULL-SW-001；v0.1；2026-10-04。以下全部是文字验证计划，**没有生成可执行测试或testbench；软件功能测试均未运行**。

## 1. 分层及通过条件

| 层 | 目标/方法 | 通过条件与边界 |
|---|---|---|
| L0文档 | 真实路径/基线、需求覆盖、普通文本布局、接口/组合走查、阅读顺序、用户纠正 | 本轮实际检查；不能据此说软件已通过 |
| L1独立参考 | 解析数值/几何真值、边界与完整图算法期望；与RTL实现分离 | 位宽/舍入/比较契约先冻结；数学参考不代替RTL时间验证 |
| L2局部RTL | 窗口、灰度、排序、Sobel/Canny各级、状态/队列/识别几何 | 有效事务逐位/逐像素对比，气泡/停顿/复位/配置事件覆盖；有限比较+真实结束 |
| L3系统行为存储 | AXI内存行为模型、DDR随机停顿、多客户端/帧归属/模式组合 | 帧完整性、同源bundle、无撕裂的协议证据、错误/跳帧分类；不替代器件层 |
| L4器件/PHY/校准 | 匹配2Gb/x16 DDR3模型，真实受保护控制器/PHY及初始化/校准 | 不旁路校准，校准成功、无时序错误/未知冲突、跨行bank/掩码/刷新读回正确；模型平均刷新限制由额外检查补齐 |
| L5实现 | 新工程综合/接口/PNR/STA、引脚/电压/PLL/CDC/例外、bit/hex | 实际资源符合目标、全部所需时钟与IO约束、setup/hold闭合、警告有依据处理、报告及产物哈希可复现 |
| L6质量/性能 | 冻结独立合成集、同类IoU≥0.5一对一评分、全尺寸数据/事务及计时 | 圆和矩形各P/R≥95%；实际处理fps/延迟/DDR流量/跳帧；显示60Hz独立验证 |
| L7实物 | 人工下载、显示/按键/相机观察及演示视频 | 本次执行终点之外；保持未执行，不因bit生成判硬件通过 |

## 2. 文字场景

| TEST | 目标REQ/IF | 输入、事件和期望 | 方法/状态 |
|---|---|---|---|
| V-01 | B1、IF-01/02/03/05 | 固定1920×1080帧、四色/所有Bayer相位、行/帧边界和连续序号；正确像素数/身份，错误帧不提交 | 独立图案及包参考，RTL接受时刻比较；未运行 |
| V-02 | B2、IF-08 | 黑白、RGB主色、边界值；固定点逐位期望及舍入，DSP/移位加法资源 | 参考表达式冻结后局部RTL/综合；未运行 |
| V-03 | B3、IF-08 | 常量、水平/垂直/斜边、边界、气泡/停顿；3×3中心/符号/绝对值和/阈值相等条件正确 | 两行窗口和每像素Sobel参考；未运行 |
| V-04 | B4/A5、IF-11/12 | 运动源、带frame/config像素标记、pending拥塞；VSYNC完整换页、原灰度/边缘/颜色/标注同源 | 事务及显示时序监视；未运行 |
| V-05 | A1、IF-08 | 9值排列/重复、全0/255、椒盐；并行网络结果等于独立排序，中值旁路身份/边界正确 | 局部及组合参考；未运行 |
| V-06 | A2、IF-06/07 | 抖动、长按/单次、阈值上下限、SOF同沿更新；单次事件、饱和、在途保持配置快照 | 局部周期契约冻结后仿真；未运行 |
| V-07 | A3/DER-02/03、IF-04/05/07/11/12 | 六个不同源角色、三结果槽与RETIRING旧读确认、DDR随机延迟/错误；禁止覆盖，响应收齐后提交，不锁总线等待显示 | AXI层及器件层分别执行；未运行 |
| V-08 | A3/UC-05、IF-06/07/12 | 冻结当前显示源、改median/阈值/Sobel→Canny→识别、恢复；frame保持、config更新、完整结果换入、引用归还正确 | 整机事务/像素比较；未运行 |
| V-09 | A4、IF-09 | Gaussian/方向/NMS/双阈值每级；全弱无强、全强、长蛇形弱链、斜连/环/交叉/边界；精确结果等于强边8邻接可达闭包 | 独立图算法及逐级参考；未运行 |
| V-10 | A4/DER-05、IF-04/09 | 最坏N队列、每像素至多一次、缓存冲突/停顿、取消/复位；闭包终止，旧响应不发布新epoch | 有限工作计数和任务轨迹；未运行 |
| V-11 | A6、IF-10 | 开发比较轴：尺度/角度/数量/纹理/噪声/对比/遮挡/重叠/裁边/负样本；最终范围独立冻结 | 一对一标签评分，全部失败保留；未运行 |
| V-12 | A6/UC-06 | 同类框IoU≥0.5匹配；重复检测计FP、漏检FN、错类别影响两类；四个P/R指标各≥95% | 解析几何真值评分与RTL结果，不只报参考模型；未运行 |
| V-13 | DER-06/07、IF-13/14 | 坏包/错行/FIFO溢出、器件响应错/校准失效、无法排空的槽隔离、输出超限、欠载、复位；错误种类分开，独立安全图案和安全复位恢复 | 局部/整机异常注入；未运行 |
| V-14 | B1/A3、IF-04/13 | 匹配器件初始化、校准、掩码、跨行/Bank、刷新、DQ/DQS；无违规/冲突、读回一致 | 真器件模型/PHY仿真为硬门槛；未运行，模型缺口 |
| V-15 | B4/B5、MOD-01/11 | 实际V4 pins/bank电压、时钟/PLL/CDC/约束例外、未约束端点及setup/hold | 新综合/PNR/STA/bit报告；未运行 |
| V-16 | UC-03/07、DER-08 | 同输入比较2/4像素、缓存/分块/共享结构；分模式有效fps、最坏延迟、DDR交易、实际块和时序 | 性能测试计划，真实结果后选择；未运行 |

## 3. 需求→模块→接口→设计→计划实现→验证

“计划实现”是职责位置，不表示已有符号或文件；后续获批后再登记真实工作副本路径/符号/哈希与实际证据。

| REQ | MOD | IF/整体草图步骤 | 计划实现职责 | TEST/期望来源 | 实际代码/证据 |
|---|---|---|---|---|---|
| T4-B1 | 01/02/03/05/12 | 01–05、13/14；S-01/04 | CSI/RAW/Debayer/采集完整性 | V-01/07/13/14，输入模式与独立像素计数 | 未实现/未运行 |
| T4-B2 | 06/10 | 08/12；S-01/02 | 灰度数值/显示原灰度 | V-02，冻结定点表达式 | 未实现/未运行 |
| T4-B3 | 06/07 | 08/11；S-01 | 两行窗口/Sobel/阈值 | V-03，赛题核和独立参考 | 未实现/未运行 |
| T4-B4 | 04/10/11 | 06/11/12；S-01/03 | HDMI扫描/对比/原子换页 | V-04/15，标准扫描及身份标记 | 未实现/未运行 |
| T4-B5 | 全部 | 全部；交付目录 | 完整工程/约束/可复现清单 | V-15、实际构建与哈希；视频L7 | 未实现/硬件视频未执行 |
| T4-A1 | 06 | 08；S-01/02 | 中值排序网络/旁路 | V-05，独立排序 | 未实现/未运行 |
| T4-A2 | 04/12 | 06/07/14；S-03 | 同步消抖/配置快照 | V-06，真实事件与帧生效契约 | 未实现/未运行 |
| T4-A3 | 01/03/04/05 | 04–07/11–13；S-02/03/04 | DDR/源帧池/冻结/任务所有权 | V-07/08/14，匹配器件及不可变源 | 未实现/未运行 |
| T4-A4 | 06/08 | 08/09；S-02 | 完整Canny/精确连接/缓存队列 | V-09/10，数学和图闭包参考 | 未实现/未运行 |
| T4-A5 | 04/10/11 | 11/12；S-01/03 | 同源RGB叠加 | V-04，标记帧和逐像素颜色 | 未实现/未运行 |
| T4-A6 | 08/09/10 | 10/11/12；S-02 | 几何候选/原图核验/标注 | V-11/12，独立解析几何标签 | 未实现/未运行 |
| DER-01…07 | 01/03/04/05/10/11/12 | 03–07/11–14；S-01…04 | 身份/所有权/错误/取消/复位 | V-04/06…10/13，交接契约 | 未实现/未运行 |
| DER-08 | 05/06/08/09/11 | 全局预算 | 有效资源利用/比较记录 | V-16，相同输入与真实报告 | 仅推算/未运行 |
| DER-09 | 全部及文档管理 | 主设计/00–09入口 | 设计/代码/测试一致性 | 本轮L0；未来交付逐项审计 | 设计文件实际存在，代码未生成 |

## 4. 反向检查与测试集政策

MOD-06/07的本批细化见[TRACK4-FRONTEND-001 v1](../../../planning/design-TRACK4-FRONTEND-001.md)G/H：FE-01…08→OP/INV→六个计划RTL模块→FT-01…12及独立Python参考。该局部追踪补充T4-B2/B3/A1，不把A2按键、A4完整Canny或其他整机条目记成已实现；所有业务测试仍未运行。

MOD-04/10的后续细化见[FRAME-MANAGER v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)G/H：FM-01…08→8接口/8操作草图/10不变量→三个候选RTL职责→FM-T01…12。新增重点为写响应跨下一SOF、D+R+R占用、显示真实active与core影子不同、NO_ACTIVE冻结启动、job接纳同沿策略命令，以及旧DDR写跨逻辑复位。它补充V-07/08/13，尚未闭合相邻物理接口，所有场景未运行。

MOD-08细化见[CANNY v0.4](../../../planning/design-TRACK4-CANNY-001.md)G/H：CN-01…10→8接口/8主操作草图/10不变量→候选RTL及三个顺序writer职责→CN-T01…26。覆盖高斯单次舍入、424整数方向、NMS平台、严格双阈值、长弱链/环、全强/无强快路径、cache/queue提交与forward、分叉每支一次、取消AW后补齐突发、梯度最后读租约及完整1080p。[窗口/流段附件](../04_local-designs/canny-window-sketches-v0.2.md)增加G-W01…04/N-W01/02/C-W01/02、有效TAIL、NMS外框原幅值/byte平面、ARM/start/FS收集及fork old/new顺序，T15…18逐项追踪。[存储附件v0.3](../04_local-designs/canny-memory-sketches-v0.3.md)补MC-M01/02、SC-M01…03及Q-M01…03，T19…22覆盖RAM最新值/pin/WB用途、prefix容量/共享口、段内退休/早失败terminal及取消原子claim。[父任务/writer附件v0.4](../04_local-designs/canny-parent-writer-sketches-v0.4.md)补P-J01/P-A01/P-D01/P-W01…03/P-F01/P-C01/02，T23…26覆盖job/绑定返还/23阶段、writer封口与fence、12区物理范围/识别租约、四方向/分叉及MC复位保持/冻结status。它补充V-09/10/13/16，不将数学闭包或局部沿号推导当RTL/DDR实际通过；全部未运行。

MOD-05细化见[DDR-SERVICE v0.1](../../../planning/design-TRACK4-DDR-SERVICE-001.md)G/H：DS-01…08→8接口/8中文草图/10不变量→四候选RTL职责→DS-T01…16。新增授权623/241、req266与permit/proposed/receipt、完整128bit/20bit条带、物理B/R/COUNT/LAST、14叶请求与7路方向RR、perclient双返回槽、终态和release ACK、末WB先于seal、OUTPUT CLASS读及GRAD移交、rst保持域与独立恢复、六源/显示最坏期限。它补充V-07/08/10/13/14/16；测试全部NOT_RUN，真实2Gb器件/PHY与整机资源不能由行为模型替代。

MOD-09/10识别细化见[RECOGNITION v0.1](../../../planning/design-TRACK4-RECOGNITION-001.md)G/H：RC-01…08→8交接/8草图/10不变量→六个候选职责→RC-T01…16。覆盖完整grad32、零幅值非法输入、32桶16B尾、薄DDA去重/图外中心/同格多圆、512θ/ρ半像素/halo/符号环绕、三边与U形负样本、候选/终表溢出、跨行2bitANN、四phase写读fence、MC互等/取消/隔离、25grant与结果租约及独立P/R质量。它补充V-11/12/13/16，全部NOT_RUN，未冻结supported domain或恢复撤回场景约束。

MOD-01平台细化见[PLATFORM v0.1](../../../planning/design-TRACK4-PLATFORM-001.md)G/H：PL-01…08→8交接/8草图/10不变量→clock/reset supervisor/domain bridge/mailbox/FIFO及pin约束候选职责→PL-T01…16。覆盖4PLL/无byte启动、旧valid掉锁、client5 RAM借用rst、mailbox容量/单端会话、OPEN/fault原子、冻结CLOSE、PREPARE→FINAL及新PHY epoch隔离、序号收尾预算、显示欠载迟到坐标、真实pin/CDC/SDC/PHY/STA。它补充V-01/02/04/13/14/16；全部NOT_RUN，来源/位宽/149小计的设计分析不代表功能通过。

MOD-02/03与采集父边界细化见[CAMERA v0.1](../../../planning/design-TRACK4-CAMERA-001.md)G/H及[窗口/writer附件](../04_local-designs/camera-window-and-writer-sketches-v0.1.md)：CAM-REQ01…08→8接口/8操作/10不变量→CFG/RX/decoder/window/writer/live/生命周期候选→CAM-T01…24及CW-T01…12。覆盖T4-B1/A3/A5、资格跨域撤销、attempt/window观察隔离、164写/ACK/真实STOP、control-only末边界114bit保持、NORM192合法值/错误映射、closure363消费水位、四phase/单轮量化、6B组拍/4KiB子段/借用、local_abort/heldW失败终结、封口与fence分离、FP74/FJ取消及status→return→CLOSE。补V-01/07/13/14/16；全部NOT_RUN，162RAM/508与632bit只是已列容器算术，不替代无丢帧或真实IP/PHY证据。

MOD-11显示细化见[DISPLAY v0.1](../../../planning/design-TRACK4-DISPLAY-001.md)G/H与[取数/扫描附件](../04_local-designs/display-fetch-and-scan-sketches-v0.1.md)：DP-REQ01…08→8接口/8操作/10不变量→fetch/row/scan/render/adapter/close候选→DP-T01…24及DF-T01…15。覆盖T4-B4/A3/A5/A6及V-02/04/07/08/13/15/16：同源render、比较偶行、SRC永存/扫描mask、3bank跨页/carry、current_exec/future隔离、SELECTED/CLOSED及safe未选预取、bank/scan/scope关闭、真实原SRC冻结、6pair逐沿与related clock。全部NOT_RUN；174RAM及419.904MB/s只是已列容器/载荷算术，不能替代行期限、PHY或STA。

MOD-04/12控制细化见[CONTROL v0.1](../../../planning/design-TRACK4-CONTROL-001.md)G/H及[人工操作附件](../04_local-designs/control-human-operation-sketches-v0.1.md)：CT01…08→8交接/8OP/10不变量→key_front/ui_transport/desired_config/fm_control_adapter/control_observer候选→CT-T01…24。覆盖T4-A2/A3/A5/A6与V-06/08/13：21样本消抖、长短互斥/四键并发、满槽完整drop、UI独立AON复位、Sobel/Canny阈值阶段、完整CFG端点、八preset/cursor与RC拒绝、D/P/C/来源与同沿旧快照、T/R WAIT_FIRST恢复、policy历史active、原SRC冻结、seq/暖会话、观察不反压与LED分层。全部NOT_RUN，原父稿需新版本吸收；来源合法/0新增RAM不等于新工程验证。

MOD-04/11/12控制联合见[CONTROL-JOIN v0.1](../../../planning/design-TRACK4-CONTROL-JOIN-001.md)G/H及[阶段附件](../04_local-designs/control-join-phase-sketches-v0.1.md)：CJ-J01…08→8IF/8OP/10INV→cfg_result_registry/fm_lifecycle_join/video_control_stage/proposal_registry/aon_reset_adapter计划职责→CJ-T01…24、JH-W01…08。覆盖T4-A2/A3/A5/A6及V-06/08/13：独立R669/父key、成功SNAP屏障、COMMIT曝光不可撤、snapshot通知独立ACK、FAILED/Q保持、保冻结算法切换、历史J与gate、三result在job形成前锁C、最近观察不反压和AON mask1FFE。所有实际代码/功能证据未生成；仅明确旧控制差异，完整数据/关闭端口与依赖仍阻塞。

MOD-03/04/05/06/07/08/09/10/11/01/12数据联合见[DATA-JOIN v0.1](../../../planning/design-TRACK4-DATA-JOIN-001.md)G/H：DJ-J01…08→8IF/8OP/10INV→capture reservation、trusted registry、reader/FE、phase/local/borrow、display join、capacity及recovery八类计划职责→DJ-T01…24。覆盖T4-B1…B5/A1…A6及V-07/08/10/13/14/16：首SOF旧ARM/NO_START/迟到单调、短引用pin、LIVE/DDR、FE终结后DISCARD、LOCAL与父fence分层、旧grant完整移交、COMPLETE前CAP关闭、20phase/25grant、有界bitmap、PLAN业务ACK/首行/SELECTED/CLOSED、safe未选/双退休、本result归还与源FREE分开、同沿旧握手与Q恢复。全部实际代码/功能证据未生成；178RAM只是容器预算，不代替质量/时限/综合。真实合同/RC实体/服务界仍阻塞，已定协议的执行检查列NOT_RUN。

MOD-09数值增补见[RECOGNITION-NUMERIC v0.1](../../../planning/design-TRACK4-RECOGNITION-NUMERIC-001.md)G/H及[读审](../05_reviews/recognition-numeric-review-v0.1.md)：POINT完整梯度、π周期角度/8次边界比较、277ρ/负RNE/镜像、候选/终记录、profile实体与LS/TLS宽算术按新稿J覆盖旧数值项；其余候选覆盖/分段/配置选择与完整质量仍按原RC要求。补V-11/12/13/16，共同数值参考与RTL时间/握手检查分别计划，全部NOT_RUN。最新180RAM仅已列预算；[官方来源](../01_baseline/vendor-interface-contract-evidence-v1.md)补V-01/13/14/15所需复位/时钟事实，未消除匹配IP行为缺口。

MOD-09/10算法增补见[RECOGNITION-ALGORITHMS v0.1](../../../planning/design-TRACK4-RECOGNITION-ALGORITHMS-001.md)G/H及[实际读审](../05_reviews/recognition-algorithms-review-v0.1.md)：AG-01…08→7IF/8OP/8INV→anchor/seed/hist/line/segment/refine/verify/VC/raster计划职责→AG-T01…18，补T4-A6/A5及V-11/12/13/16。全pair有限代表选择、图外/同心/双峰/tile halo、dense/NMS反转/串行RMW、offset/run/TLS、三/四边及同像素U负例、最终几何重核/精确集合去重、字体/笔宽/clip/池切换、完整失败纳入质量均有计划；无实际符号、程序或运行。PROFILE layout2/algorithm2及旧条款覆盖只列新稿D/J；225RAM和14778bit局部FF不替代全机综合/STA/服务证据。

评分器计划采用同类IoU整数门2I≥U、最大基数一对一匹配、每类20TP≥19(TP+FP)且20TP≥19(TP+FN)；空分母N/A，独立主集两类均有GT，负样本/重复/采样遗漏/失败帧不可删除。DEV/QUAL种子及更广开发轴是提案，不是新硬边界；独立分布在开发后、查看其输出前冻结。AG-T01…18全部NOT_RUN。

MOD-09/10执行增补见[RECOGNITION-EXECUTION v0.1](../../../planning/design-TRACK4-RECOGNITION-EXECUTION-001.md)G/H及[实际读审](../05_reviews/recognition-execution-review-v0.1.md)：EX-REQ01…07→四IF/九OP/八INV→job/table/circle/rectangle/verify/annotation六计划职责→EX-T01…15，补T4-A6/A5及V-11/12/13/16。覆盖坏job无释放权、RE取消仍capture、跨word提交、固定成员重放、t符号/端点flags、submask真实gap、跨theta快照、精确coverage/图外远端相对索引、VC空洞/跨bank、FINAL全表冻结、严格内洞/有限capsule、W6/H5连续carry、1024B spool与旧MC排空。全部无实现/NOT_RUN；29168bit局部和225RAM不能代替全机资源/服务/STA，旧算法18场景及质量标准保持。

MOD-01至12分别在上表有需求；平台/状态等支撑模块对应DER，不为无关代码临时编造需求。IF-01至14在03说明前提、拥有者、错误与生命周期；未来每个真实核心符号反向定位到对应REQ/IF/草图与TEST。行号仅辅助，稳定符号和文件版本优先。

识别开发集用于选择参数，最终独立集的种子/生成分布/标签/评分器在评审后冻结并哈希。不能一边看最终集一边调参，也不能删失败样例或改标签使指标通过。数值参考模型与识别真值评分分离；粗候选漏检算漏检。未得到最终范围和测试结果前，不声称复杂真实场景95%。

先小尺寸场景验证边界和事务，再完整1080p覆盖数据/数量/性能；小图通过不代表1080p通过。DDR AXI层、匹配器件层和实际整机结果分别记录。每个运行保存输入、配置/身份、工具版本、期望来源、实际命令/日志/波形、结束和比较次数以及覆盖限制。

整机资源与期限追踪见[RESOURCE-SERVICE-BUDGET v0.1](../../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)G/H及[审阅](../05_reviews/resource-service-budget-review-v0.1.md)：RB-REQ01…06→四IF/五OP→各唯一bank/canonical ctx/消息/保持/服务预算→RB-T01…09。新增九项均为NOT_RUN文字场景，补V-13…16；实际IP占用、XLR/DSP packing、非暂停入口/backlog、row期限、热冷/错body回显/Q恢复及优化等价/独立质量分别核验。已有225RAM/60176局部合计和工作量不替代真实工具证据，不添加用户撤回的硬边界。全部业务实现/测试/综合/布局/STA/bit仍未生成/未执行。

存储布局追踪见[STORAGE-LAYOUT v0.1](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)G/H及[实际审閱](../05_reviews/storage-layout-review-v0.1.md)：SL-REQ01…06→四IF/五OP→RC逻辑字段/native word/两类VC与DISPLAY条带/PAIR slot/owner→SL-T01…12。覆盖全部最大同时布局、DENSE高位RMW与rho边界、CELL/EXT精确submask端点、SEG/VC零位重建、RGB色序、EA不同读口、7word stage与旧holding/tail、cancel/reset旧capture/borrow、n−6至adapter身份、实际IP/map/服务及全任务质量/审批恢复。所有场景NOT_RUN；SRC6912/EA864静态唯一地址与543数据容器预算只属设计核对。91/17/207不代替全机综合，DS/PL/FIT/scalar/ASYN0备选未采用；用户撤回的旧尺寸/噪声等仅比较轴，P/R各≥95%的独立评分保持。

STORAGE v0.2新增覆盖不另增SL测试数：SL-T02须分清六命名沿/II≥5，覆盖low WE未发生与已发生取消、沿前RAM Q/两336lane字典；SEG实际19WE下一沿DONE，父地址/PROFILE按J。[IP-PRECHECK v1](../../../planning/design-TRACK4-IP-PRECHECK-001.md)六文字IP-T01…06→六REQ/四IF/四OP/四case，分别验证输入漂移、真实参考层级/包含、实际CSI5.15、clock/net/SDC/input一致、许可/DB失败、终态报告与恢复。89输入静态hash不能代替运行；C2两个revision分开，C3从修正基线派生，ASYN事务延迟/完整NORM/PPC/2Gb校准不由本预检证明。全部NOT_RUN。
