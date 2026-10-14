# 01 整体布局之前：基线、前置条件和证据

TRACK4-FULL-SW-001；v0.1；2026-10-04。结论按“文件事实 / 已有实测 / 推算 / 设计提议 / 未知”区分。原始资料保持只读。

## 1. 已完成的设计前置工作

1. 实际读取根AGENTS、控制面AGENTS及其规定的config规则→提示词→配置→state/台账→database说明，另读既有Approval Manifest、唯一v0.2和PLAN_TEMPLATE。
2. 核对现有需求矩阵与最新聊天，保留全部11项要求，明确本轮只完成整体文档；记录用户对识别参数的撤回。
3. 核对实验目录/主设计文件原先不存在；新目录只在控制面内创建。正式状态及原参考资料不修改。
4. 定位用户提供的V4资料，检查v6归档成员、实际工程引用、工具登记和历史实测边界；生成[基线清单](baseline-manifest.json)。
5. 为整体草图建立帧所有权、配置快照、DDR预算和有限资源前提；执行文字层组合走查，不把它写成仿真。

## 2. 冻结用于本轮调查的资料

V4根：`D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4`。

参考归档：`10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v6.rar`。

归档SHA256：`45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C`；长度7,358,554字节。本轮读取归档成员到stdout，没有展开成可修改工程，没有调用参考脚本。成员路径均从归档顶层 `Ti60f225_sc431hai2hdmi_v6/` 起算。

| 证据 ID | 文件/成员 | 核实事实与限制 |
|---|---|---|
| SRC-01 | 现有TRACK4_REQUIREMENTS.md/.csv | 5基础+6高阶，正式状态均未验收；来源和页码已登记 |
| SRC-02 | v6/ti60f225_oob.xml | Ti60F225/I3、Efinity2026.1.132.1.2、SV2009；引用60项源码，实际引用链作为候选基线 |
| SRC-03 | v6/rtl/csi_rx_controller.sv | XML实际引用CSI5.15，2025.2.288.4.15，4lane，HS_BYTECLK70MHz；受保护源码，仿真兼容未实测 |
| SRC-04 | v6/ip/csi_rx_controller/settings.json | 备用CSI5.16/50MHz，与实际引用链不同；不能根据settings默默升级实际源码 |
| SRC-05 | v6/rtl/ti60f225_oob_top.v及debayer | 原路径4个RAW10各截高8bit后32bit写DDR、16bit读，三帧缓存；后续Debayer；新架构不是原顶层已实现的结论 |
| SRC-06 | v6/rtl/ddr3_controller/ddr3_parameter.vh及phy_ctl | row14/col10/bank3/x16、tCK2500ps的控制器候选；含PHY/读写校准；受保护部分展开未验证 |
| SRC-07 | v6/rtl/frame_buffer_V3/lpddr4_tb.v、axi_ram.v、sim.do | AXI帧缓存行为测试材料；不含匹配DDR器件、PHY及校准验证 |
| SRC-08 | v6/ti60f225_oob.sdc与peri.xml | SDC留有未注释USER_PERIOD占位，cam时钟与实际CSI参数不一致，clock groups需重审；不能直接称合理约束 |
| SRC-09 | V4板说明已有pdf_evidence文本p7及DDR章节 | 板载MT41J128M16JT-125、2Gb/x16、最高800Mbps；实物PCB/跳线/电压未确认 |
| SRC-10 | 本地Efinity testbench/ddr3.v与4096Mb参数头 | Micron模型v1.74、硬编码4Gb/x16；有2Gb分支但2048Mb参数头缺失；不能只限制地址冒充匹配器件 |
| SRC-11 | 最小LED outflow/LED_8bit_Test.place.rpt | 目标Ti60F225；容量60,800XLR、256 Memory Blocks、160 DSP；报告未给每块有效位数 |
| SRC-12 | LOCAL_TOOL_PATHS.json、Questa实测报告 | Efinity2026.1.132/Questa2024.1及英文别名；普通RTL/波形已实测，FIFO展开仍失败；V4整体未验证 |
| SRC-13 | HANDOFF.md、PROJECT_STATE、TASK_LEDGER、database/README | 实物基线/正式H0仍未验收、DB未配置；旧VF/ModelSim字段是历史信息，不能覆盖当前V4/Questa方向 |

基线清单绑定整个v6归档与本轮选用文件；不声称冻结了全部88,000余文件。没有Git基线，不伪造commit。归档内历史bit/hex不登记为本次产物。

## 3. DDR模型查找范围与缺口

本次重新针对用户指定的V4根进行只读文件和压缩成员检索；精确范围与嵌套复核结果见[评审记录](../05_reviews/review-and-blockers.md)。展开文件和落地压缩包未发现匹配2Gb/x16完整器件仿真包。能找到DDR控制器、PHY/校准源码，与能找到DDR芯片BUS Functional模型是两类材料。

用户补充的VF及Demo也已重新检查：VF展开24份及压缩包内2份，Demo的IMX219 HDMI ZIP内1份器件模型，均与本地Efinity的4Gb/x16模型字节相同；没有找到匹配2Gb参数头。准确结论是“有DDR器件模型，但当前找到的模型不匹配V4容量”，不能写成这两份资料没有模型。范围、精确路径及限制见05。

目前必须补齐：官方或板卡供应商明确覆盖MT41J128M16JT-125的2Gb Verilog模型主体、2048Mb参数头和依赖、版本与使用条件，以及完整器件数据手册；如Questa不支持现有受保护核心，再获取与该核心匹配的仿真库/PHY相位及校准说明。不能先认定需要安装或购买IP。

官方资料检索/下载的明确授权尚未收到，本轮没有联网或下载。现有规则要求先登记capability request并获批。本轮可以形成布局，因为此缺口不改变相机→帧池→算法→显示的职责边界；整机实现与DDR层PASS仍受阻塞。用户此前“先补齐模型再推进”继续作用于整机实施。

## 4. 原路径与新提议的区别

原v6先存截断RAW再读出去马赛克。新整体提议以“完整RGB源帧”为冻结/处理/显示共同来源，并评估采集域Debayer与基础模式同源流计算，以减少DDR重复读取。这是有明确动机的架构变更，需局部数值/并行度/CDC设计及批准，不能说复制v6即可得到新行为。

RAW10的保留精度、Debayer位宽、最终RGB888的舍入/截断和Bayer相位均须在局部设计冻结。参考GB/RG图示、crop和mirror/flip寄存器只能作为仿真假定来源；不能断言真实相机相位正确。相机fps不能由已有配置静态推出，完整仿真至少测试合约中明确的不同帧间隔和突发，不承诺相机实际60fps。

## 5. 分阶段前置门槛

| 门槛 | 何时必须满足 | 本轮状态 |
|---|---|---|
| P0规则/目标/目录/来源 | 整体草图前 | 已调查并落盘；结果需读回审查 |
| P1整机布局/交接/预算/走查 | 局部设计前 | 本轮交付，预算为推算而非实测 |
| P2器件模型/使用条件/受保护IP/PHY校准预检 | 整机实施前 | 未完成、阻塞；没有强制校准通过的替代方案 |
| P3局部状态/逐拍/数值/CDC/端口/引脚SDC | 相应业务源码前 | 尚未开展完整设计，不标READY |
| P4指定版本/范围/基线批准及工作副本/构建授权 | 修改/执行前 | 未获实现批准；文档授权独立 |
| P5实际回归/综合/PNR/STA/bit | 完整软件实验交付前 | 未执行 |
| P6实物/人工下载与观察 | 硬件验收前 | 本次软件范围外，正式节点维持未验收 |

数据库未配置不阻止用户已授权的隔离文档整理，但不能启动依赖数据库的正式流程，不建立替代数据库。本目录的基线JSON只是一份资料清单。
