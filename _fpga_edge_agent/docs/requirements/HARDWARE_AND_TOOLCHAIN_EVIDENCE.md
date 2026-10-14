# 硬件与工具链证据表

更新日期：2026-09-27。当前任务为赛题四实时图像边缘检测。

**2026-09-27 用户已决定转用借用的 Ti60F225 板，并补充 DemoBoard V4 完整资料。** 目前推荐与 V4 配套的 SC431HAI 彩色 MIPI 模组；实物 PCB 丝印、借用配件和相机 SKU 尚待确认。VF 保留为此前环境检查的参考平台，不将其工程引脚/DDR直接套入借用板。详见 [新增资料与相机选型](V4_CAMERA_SELECTION_20260927.md)。

此前“未发现 SC431HAI 完整工程”的结论仅适用于 2026-09-23 的搜索范围：新增资料已提供相应源码和 v3/v4/v5/v6 压缩包，本次已静态核对 v6 关键配置；没有执行编译或上板。下文未另行标注的表格保留 2026-09-23 的资料核对结果。

本表记录资料与本地目录证据，未运行硬件下载、Flash 烧写、传感器寄存器读写或板上测试。PDF 页码均为阅读器页码：V4 手册印刷页码比 PDF 页码小 1；EVSOC 手册正文印刷页码比 PDF 页码小 5。历史工程版本、编译记录和资料性能数字不代表当前验证结果。

## 1. VF 与 V4 必须分开建立基线

| 项目 | VF-Ti60F225 资料 | TI60F225I3-V4 / DK 资料 | 工作流约束 |
|---|---|---|---|
| FPGA / 型号 | [VF 手册][vf] PDF 16–19：Ti60F225I3 / Ti60F225，60K、160 DSP；部分图片写 Ti60F255 | [V4 手册][v4] PDF 7–8：Ti60F225I3；概述又写 Ti60F255I3-DK | 型号冲突保留，待实物丝印与 PCB 版本确认 |
| DDR3 | VF PDF 16–19：K4B4G1646E，4 Gbit，16 bit | V4 PDF 7、24–26：MT41J128M16JT-125，2 Gbit / 256 MB，16 bit，最高 800 Mbps | 控制器容量、时序、地址、引脚和校准参数不能直接复用 |
| Flash | VF PDF 16–19：W25Q64JWSSIQ，64 Mbit | V4 PDF 7：GD25LQ64，8 MB | 容量相近不表示器件参数、镜像或烧写设置相同 |
| 晶振 | VF PDF 17：24 / 25 MHz，标注 3.3 V | V4 PDF 11–12：25 / 27 / 50 MHz；50 MHz 位于 3.3 V HVIO | 参考时钟、PLL 和 SDC 必须按所选板卡检查 |
| MIPI Bank 电压 | [VF 核心板原理图][vf-core] PDF 3：Bank 3A 通过 R11=0Ω 选择 1.2 V；1A/1B/2A/2B 标默认 1.8 V 电阻选路；DDR 的 3B/4A/4B 为 1.5 V | V4 PDF 9–10：Bank 2A/2B 由 J2/J3 选择；MIPI 1.2 V，LVDS 1.8 V | 不得将 V4 的 J2/J3 操作指引用于 VF；需核对实际装配和转接板 |
| 下载与串口 | VF PDF 16–19：ZH1.25-6 JTAG；底板 CH340N 串口；PDF 24 列外接下载器 | V4 PDF 14–15：板载 FT4232HL，Type-C 支持供电、下载、UART；默认 JTAG Bridge | CH340 串口不是 FTDI JTAG。驱动、VID/PID、通道和 OpenOCD 设置需独立确认 |
| 显示 / 相机扩展 | VF PDF 18–19：HDMI、LVDS、DVP、MIPI RX/TX，MIPI 需要转接板 | V4 PDF 7、29–32：HDMI 收发、MIPI FPC / QSE 扩展 | 外形相似的连接器不能作为引脚、电压或方向兼容证据 |

V4 文档有可见的复制残留：PDF **77** 框图为 SC431HAI + DDR3，文字却写 IMX219、Ti60F100 合封 HyperRAM；PDF **97** 说 v4 去掉 DSI，PDF **98** 框图仍含 DSI。已渲染核对，后续必须以对应版本源工程及实物为准。

## 2. 相机、屏幕与初始化缺口

| 对象 | 资料证据 | 尚缺证据 / 验收要求 |
|---|---|---|
| SC431HAI 输出 | [相机手册][camera] PDF 2、6、13–17：最高 2560×1440@60fps；RAW8/RAW10；1/2/4-lane MIPI；推荐速率 ≤1.4 Gbps；EXTCLK 6–40 MHz | 芯片能力不等于模组工作模式。须确认模组、lane 数、lane 顺序/极性、外部时钟、实际 LUT 与 CSI RX 配置 |
| 相机电源 / 复位 | PDF 2、8–10、33–34：AVDD 2.8 V、DVDD 1.2 V、DOVDD 1.8 V；上电时序 T4≥4 ms；XSHUTDN 低有效 | 模组可能带稳压/电平转换，不能直接把芯片电压当作模组输入电压；需模组及转接板原理图 |
| I²C / ID | PDF 10–13：16 位地址、8 位数据；SID 低/高对应 7 位地址 0x30/0x32；0x3107/0x3108 的 ID 为 0xCD/0x6B；0x0100 控制 stream，0x0103 软复位 | 读 ID 与 ACK 是后续人工上板证据；本轮没有执行。手册不等于完整目标模式初始化序列 |
| lane / RAW / 裁剪 | PDF 16：0x3018[7:5] 控制 lane，0x3031[3:0] RAW 位宽，0x3037[6:5] PHY 位宽；RAW8/10 DT 为 0x2A/0x2B。PDF 31：0x3208–0x320B 窗口、0x3221 镜像/翻转 | 默认寄存器值不证明实物现状；Debayer 顺序还受裁剪起点、镜像、翻转影响。需完整厂商 LUT 或匹配参考工程 |
| 曝光 / 增益 | PDF 22–23：无内置 AEC/AGC，由后端实现；N 帧写入、N+2 帧生效。PDF 29：group hold 最多 10 个寄存器；PDF 32：灰度渐变测试模式 | 曝光/增益控制与边缘阈值控制分开验收；测试图可用于定位数字链路问题 |
| JJX035FHD05-V9 屏 | [屏幕手册][panel] PDF 4–9、12：3.5 英寸、1920×1080、4-lane DSI、30-pin FPC；VCC 3.3 V、VSP/VSN 典型 ±6 V；背光典型 40 mA / 24 V；RESET、STBYB、SPI 控制；像素时钟典型 143 MHz、60 Hz | 需确认背板供电电路、连接器方向与控制方式。该手册未明确提供可确认的驱动 IC 型号或完整初始化指令表 |
| 屏幕版本 | V4 PDF 75–76：驱动芯片变化，区分 3.4/3.5 版本；更换 Panel_1080p_reg.mem，示例 REG_DEPTH=180；照片显示 V9A 标签 | 不能只凭分辨率或相似型号认定初始化兼容。需实物标签和对应寄存器表 |

## 3. 工具版本与源码可用性

| 参考设计 | 文档版本证据 | 本地发现与使用边界 |
|---|---|---|
| VF HDK | HDK 目录为 2023.2 系列，具体 XML 仍需逐工程核实 | 用 VF 自带 LED / HDMI 基线检查环境；不因本机存在新 Efinity 就自动升级全部工程/IP |
| V4 HDMI 彩条 | V4 PDF 50–51：hdmi_tx_demo_v3 使用 27 MHz 参考时钟、Efinity 2026.1.132.1.2 | 根目录 hdmi_tx_demo_v3.rar 有 HDMI/彩条源文件；这是 V4 参考，不能直接用于 VF |
| SC431HAI → HDMI | V4 PDF 97：v4 用 2025.2.288.4.15；v5/v7 用 2026.1.132.2.19；v4 CSI RX 从 5.8 升到 5.15；v5 说明未继续升级 CSI RX，因为升级后 VS 解析失败 | 未发现 Ti60f225_sc431hai2hdmi_v7 的解包源码。任何 IP 升级都需独立验证 VS/HS、打包、帧缓存与接口 |
| RISC-V / 联合调试 | V4 PDF 81、92：示例使用 Efinity 与 RISC-V IDE 2025.2；PDF 91 提到 Java 8 与 IP 更新；PDF 89、91 的 FTDI 通道示例不同 | 按实际下载器/BSP 核对，不复制示例通道。联合调试属于后续获准使用的能力，不代表现在已可用 |

**源码发现范围：** 本轮搜索了工作区已解包 HDL/XML/MEM/C/C++/说明文件，以及外层 VF HDK ZIP 的 **13,767 条目录记录**；未找到 SC431HAI/csi2hdmi/TinyML/EVSOC/Sapphire 对应完整工程。根目录 RAR 名称与内容为 hdmi_tx_demo_v3。此结论不是对电脑所有目录、所有嵌套压缩包或远程资料的穷尽证明。根目录 hdmi_tx.hex、ti60f225_oob.hex 缺少可核对的构建来源，不能认定它们来自 SC431HAI v7。

## 4. EVSOC / TinyML 分支

**TinyML 是赛题四工作流中的可选扩展路径，不是基础边缘检测的先决条件。** 以[赛题四需求映射](TRACK4_REQUIREMENTS.md)确定是否采用，不因收到 TinyML 介绍材料就扩大基础任务；本项目不包含学习规划。

| 内容 | 精确证据 | 工作流要求 |
|---|---|---|
| EVSOC 参考硬件 | [EVSOC 用户手册][evsoc] PDF 7–9、14：Raspberry Pi v2 相机、HyperRAM、Mini-DSI；RAW10 1920×1080 输入，裁剪 1080×1080 后缩放为 540×540 | 不是 VF DDR3 + SC431HAI 的即用工程。PDF 8 又写 256 位 DDR DRAM 接口，与上下文 HyperRAM 不一致，保留冲突 |
| Sobel 参考 | EVSOC PDF 9–10：Hardware Accelerator 提供 Sobel、腐蚀、膨胀，示例软件负责灰度转换 | 应说“VF 已解包 RTL 未发现对应 Sobel”；不能说“全部资料都没有 Sobel”。EVSOC 描述的完整源工程尚未发现 |
| 环境前置 | EVSOC PDF 14：Efinity ≥2023.2.307.2.307，安装路径无中文/空格；RISC-V SDK、64 位 JRE/JDK。PDF 17–19：tinyml_generator 依赖 Efinity setup.bat | 这些是历史文档要求。实际依赖随选定工程核对；缺少软件时先声明并获准，不能直接执行文档安装命令 |
| 软硬件一致性 | EVSOC PDF 11–13、22、27–28：define.v 与 define.h/define.cc 同步；生成 Sapphire runtime/BSP；DMA/FIFO/地址及传输长度一致；示例 TensorArena 默认 10 MB | 建立模型、软件、RTL、BSP、存储布局及参数哈希的联合版本；验证缓冲区与 DMA 边界 |
| 模型流程 | [TinyML 介绍][tiny-intro] PDF 4–10：INT8、卷积/算术/FC/激活算子；模型→量化→导出→部署。[框架介绍][tiny-framework] PDF 2–9：baremetal、BSP、驱动、TFLite、输入 tensor→Invoke→输出→后处理、profiler | 验收算子覆盖、预处理/量化一致性、输出正确性、资源与实际耗时；材料中的加速比不是本项目实测 |
| 自定义指令 | [RISC-V CI][ci] PDF 4–7：cmd/rsp valid-ready、10 位 function ID、两个 32 位输入/一个 32 位输出，C 侧 opcode_R | CI 扩展需要握手、ID 映射、软硬件数值一致性与性能对照验证 |
| DSP 原语 | [DSP 介绍][dsp] PDF 2–8：DSP48/24/12、整数多通道、DSP48 BF16、符号、级联、寄存器参数 | 用于后续资源/时序优化；“FMax 可达 1 GHz”不作为本设计时钟保证 |

## 5. 尚待确认与阅读边界

| 未确定项 | 所需证据 | 阻止的动作 |
|---|---|---|
| 实际板卡、FPGA、PCB 版本 | 人工确认丝印/型号，匹配原理图 | 确定最终 pin/电压、下载镜像 |
| 相机、转接板、lane/极性/时钟 | 实物型号、连接表、目标模式 LUT | 摄像头集成与上板通过判定 |
| 屏/背板/驱动版本 | 标签、供电设计、对应初始化表 | DSI 初始化和接线指导定版 |
| 匹配源码与 IP | 可追溯完整参考工程、版本、约束、LUT | 将文档结构当成可编译实现 |
| 当前软件可用性 | 本机安装、版本、授权、启动/编译检查报告 | 声称当前环境或构建已经通过 |
| 是否选 TinyML 扩展 | 基础功能验收后，映射高阶挑战并确定实现路径 | 自动安装 SDK、训练框架或扩大任务 |

本轮复核覆盖：EVSOC 36 页可提取文本；TinyML 介绍 11 页、框架 11 页、CI 8 页、DSP 9 页可提取文本；框架 2–3 页与 CI 4–7 页另做渲染检查。SC431HAI 详细阅读技术正文 6–41 页、参数/目录 2–3 页，渲染 Bayer 图第 30 页。屏幕详细阅读 4–12 页，渲染 6–9 页；后半部分仅检索定位，未逐页视觉审查。V4 全文检索，重点复核 7–15、24–26、50–51、75–100 页，渲染 76–78、97–98 页。VF 手册 30 页可提取文本，另渲染核心板原理图第 3 页。**未声称每份 PDF 的所有截图都已逐页视觉审查。**

[vf]: ../../../VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包/VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009/01-用户手册/VF-Ti60F225%20易灵思FPGA开发板-V4.1.pdf
[vf-core]: ../../../VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包/VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009/04_原理图&PIN%20TCL/Ti60_F225_Core_V1.4.pdf
[v4]: ../../../TI60F225I3-V4%20DEMO板软硬件设计说明-260920.pdf
[camera]: ../../../摄像头SC431HAI_数据手册_V1.1.pdf
[panel]: ../../../mipi显示屏手册JJX035FHD05-V9_19201080_30P_MIPI_4S2P_900_2.75_51MM直排_V00_20221125.pdf
[evsoc]: ../../../1_3_EVSOC_tinyml用户手册_0416.pdf
[tiny-intro]: ../../../1、TinyML介绍.pdf
[tiny-framework]: ../../../4、TinyML%20框架介绍.pdf
[ci]: ../../../2、RISCV%20Custom%20Instruction.pdf
[dsp]: ../../../3、%20钛金FPGA%20DSP原语介绍.pdf
