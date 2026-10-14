# 2026-10-10 软件推进：显示取数核心和跨时钟运输

本次新增并完成 **2个RTL模块 + 1个协议包**：display_scan_prefetch_core、display_fetch_link、display_fetch_pkg；连同2个TB、独立参考、2个运行脚本、2个工程XML和1个SDC，共 **11份自写业务/验证文件**。先形成整体/局部/接口/中文草图再实施，按用户“统计后自行进行，无需批准”和本地审计例外推进。

## 阅读入口与真实产物

- 最终中文阅读说明：[display_fetch/README.md](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/display_fetch/README.md)，整体路径、接口、语句组织、局部逐沿、真实测试及修改入口都在此文件。
- 前置设计：[核心服务 v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-DISPLAY-SCAN-CORE-001.md)、[验证 J1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-DISPLAY-SCAN-CORE-001-J1.md)、[测试刺激修正 J2](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-DISPLAY-SCAN-CORE-001-J2.md)。生成前全文已保存/读回/呈现，18项最新冻结输入保留旧版本。
- 代码：[核心行服务](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/display_fetch/rtl/display_scan_prefetch_core.sv)、[运输](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/display_fetch/rtl/display_fetch_link.sv)、[协议包](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/display_fetch/rtl/display_fetch_pkg.sv)。11份复制依赖单列，源码/工程合计22份。
- 冻结登记：`artifacts/staging/DISPLAY-FETCH-COMPONENT-20261010-v1.2`，**793个登记条目**，清单SHA256 **8F406600E219962390E1355DC88AF78C88141AC96AA38E588516184FB22C75C1**。这是软件组件登记，没有人工硬件PASSED。

## 本次做到了什么

实际视频481位需求经原子运输到核心，核心使用真正银行代次/父lookup，调用原reader、真实AXI字节slave和native三行RAM；实际WR、publish或安全abort/真正内部return，形成615位不可变回执，再等真实video消费ACK。正常行真正core return消费后才GEN推进和引用清除；错ID/LAST/活动enableloss保Q和占用。原prefetch、rows、owner/handoff、renderer及HDK未改。

最新六个核心运行全部独立参考PASS，共 **1418个场景、1048504次54bit WR、1048330次54bit读取、6608次AR、311715次R、1282次scope查询**。覆盖20×8、4×2、6×8、10×8、1920×1080宽行和近代次上限。五个几何运行均包含200核心沿的视频停钟及真正同沿return/claim；后一场景严格用旧busy/GEN拒绝，下一请求才用新GEN。另有6个运输主动注错场景PASS，五种错误包保永久Q和原身份。

两次真实Ti60F225/I3 MAP分别PASS：核心 **19 RAM10 / 9452 FF / 17066 LUT4 / 439 ADD / 1 DSP**；运输 **0 RAM10 / 1623 FF / 384 LUT4**。核心top没有包含运输top，资源必须分别理解，不能相加声称总工程已经装得下。综合warn/error日志完整保留，core的post-synthesis 132 warnings及逻辑cache映射见README，两个err.log无实际ERROR。

HD是1080个基础独立宽行加故障/交接场景，包含不同结果身份；**尚未构成同一bundle经owner/handoff/scan/renderer的连续整帧**。小/最小 `_002` 因测试在claim前关enable并错误期待拒绝回执而停止，原退出码-1/FAIL、完整源码与日志保留；J2改在真实claim后关enable，预期未放宽，生产RTL未变。最新同一验证源的 `_003` / HD `_002` 等全部PASS，不计旧重复尝试。

每个最新仿真源/初始快照/最终源一致。两个MAP的生产源码、依赖、工程和约束与当前一致，后续差异只有TB、参考和运行脚本；原MAP及原仿真完整快照保留，不拿新测试冒充旧源码。Questa编译/展开零错误、真实fatal非零、实际仿真退出0及finished=true，独立参考逐位/逐事务审计。

## 累积完成与剩余工作

累积自写业务/验证文件由 **234增加到245**；这个计数是文件，不是模块或需求完成率。此前164份当前增量源码和本次11份，共175份当前增量源码做哈希核对；最初70份基础文件没有在本次全部重跑，仍按原证据分层。此前基础灰度/中值/Sobel/阈值、完整Canny软件链、采集到Source/EDGE的AXI软件链、摄像头配置/RAW传输组件、frame owner、handoff、三行RAM、预取和六模式renderer证据仍有效，各自边界见此前登记。

本次移除了“核心视频需求运输与真正GEN账本尚无代码”这一缺口；以下仍继续：

1. **完整视频扫描**：三银行行仲裁、真实前两个native响应首行准备、连续DE消费/缺行错误、renderer最后两沿、VS错过/候选取消/旧图repeat以及完整scope关闭运输；在真实owner/handoff上做同一bundle连续帧联合，不能由TB直接伪造prepared/closed。
2. **生产统一帧控制和权限/QoS**：实际Source/处理结果/OFFER/DISPLAY/RETIRING生命周期、lookup RO来源、DDR共用仲裁、真正AXI关闭后再复用，采集/处理/显示三种帧率分别测量。
3. **摄像头生产证明**：CSI CRC/晚错/rx_close与实际C2接口等价、overflow/丢帧资格，接到真实帧发布。配置I²C和受保护模型RAW10传输通过，不能由此推定物理链完整通过。
4. **原复杂识别与整体资源**：原旋转/遮挡/缺边/重叠/多目标质量仍需完整实现验证；旧STATS资源86.54%不能与现有链直接并放，需共享复用与整包资源优化，保持原要求。
5. **DDR器件动态**：板载MT41J128M16JT-125:K的2048Mb/row14参数仍缺；不得拿4096Mb/row15文件重命名冒充。byte-slave软件动态不代替真实DDR/refresh/QoS。
6. **最终生产工程**：整包Ti60F225/I3 top、正确板型/IP/时钟/CDC/引脚约束、总资源、综合/布局布线/STA和最终bit；本次两个组件无板级pin，没有执行PNR/STA/bit。

下一步先完成真实native行消费对连续DE和renderer的交接，再收敛完整scan的三银行仲裁/关闭；已有核心服务可直接复用，不继续等待逐版用户批准。目标仍为原五项基础、六项高阶、1080p、板卡现有资源/现有DDR与SC431HAI；未降低到小尺寸验收。全部后续软件按中文前置草图→代码→单独/整合真实验证推进。

本地审计以新检查点及追加事件关联，正式PostgreSQL、PROJECT_STATE/TASK_LEDGER/硬件状态未改，原始资料只读，无网络/安装/硬件操作。**整体目标仍ACTIVE，当前分类PROGRESS，未完成最终比特流。**
