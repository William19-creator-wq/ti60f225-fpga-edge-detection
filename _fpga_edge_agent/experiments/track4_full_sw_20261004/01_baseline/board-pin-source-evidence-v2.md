# V4 原理图、封装与活动引脚证据 v2

2026-10-04；只读资料复核，接续[旧时钟/引脚来源 v1](platform-clock-pin-evidence-v1.md)。v1保留原样。本页是所选资料的来源链，不是实物确认、当前工程引脚合法性或STA通过证明。PLATFORM候选见[主设计](../../../planning/design-TRACK4-PLATFORM-001.md)。

## 1. 实际读取范围与来源

令V4ROOT为工程根中的“Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4”。

| 来源 | SHA256 | 本轮使用范围 |
|---|---|---|
| V4ROOT/Ti60F225A_V4_SCH.pdf（14 PDF页） | 855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F | PDF页3、6–11、13–14的电源/按键/DDR/器件/HDMI/摄像头/晶振，文本及关键页像素核对 |
| 工程根/TI60F225I3-V4 DEMO板软硬件设计说明-260920.pdf | 426A577CC3A544546F2BF1AD60A1F233541B7D6361764794E48B11ADA0C2E4F2 | 板说明及既有提取文本的相应段落，不声称110页全部逐像素审阅 |
| 上述既有提取txt | E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8 | reports/audit/environment_20260923/pdf_evidence下同名文件 |
| V4ROOT/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v6.rar | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C | 原归档流式读取，未解包到磁盘或改写 |
| 当前Efinity pt/db/devicemap.csv | 1568427EBD8839D5A35F44DFCC332CD37F9831FEC3EC515610A126EA427E8AD9 | 第49行Ti60F225→下行封装 |
| 当前Efinity pt/db/package/opx_218x322_b16_d10_b225.xml | E58A269F05807655F58FC3AE9DE6F96C0E544E075436E93F5C5EC2322CE2A6BD | 第2行225-ball FBGA/Final及球号映射；只读，未运行生成器 |
| 历史v1/outflow/ti60f225_oob.pinout.csv | B1C6FC5B1AC0EC139AB02D5D7738EADC96FF1C8C368DCB896EB9F909CAACD613 | 仅独立球号佐证，不沿用旧信号绑定 |

当前Efinity根为C:/Users/34528/FPGAEdgeLinks/Efinity2026_1。v6归档内没有当前v6生成的pinout报告；工具封装表与原理图一致不等于新的peri生成通过。

## 2. 时钟、复位和电源网络

| 活动信号 | 球号／资源 | bank／板网 | 方向/候选owner与来源 |
|---|---|---|---|
| CLK_25M | J2／GPIOL_P_08_CLK1_P | 1A／1.8V | 输入；PLATFORM参考/AON25；原理图PDF页9/14、封装84、peri85–86 |
| CLK_27M | H2／GPIOL_P_10_CLK3_P | 1B／1.8V | 输入；USER_PLL；PDF页9/14、封装86、peri88–89 |
| i_arstn/KEY1 | P13／GPIOR_27 | BR／3.3V | 输入；逻辑复位请求；PDF页6/8、peri274–275、封装106 |
| CRESET_N | J5／专用配置脚 | 配置/1A供电域 | 专用配置复位；PDF页9、封装4；不冒充业务排空请求 |
| CLK_50M（本次不选） | R13／GPIOR_29_PLLIN2 | BR／3.3V | 输入不启用；PDF页14的X2值25M与板说明50MHz冲突，未来启用另核验 |

X3标25M、X4标27M，单路OUT；peri选单端LVCMOS GCLK。板说明“差分晶振”用词不能据此创造N脚。KEY1经R100=10K上拉3.3V，SW1按下接地，是低有效GPIO输入。历史v1把i_arstn绑C4/GPIOL_07（KEY0），当前v6改成P13（KEY1）；GPIOL_03/A3是KEY3。必须以选定版本核对按键。

原理图PDF页3：3B/4A/4B固定1.5V；HDMI 3A固定1.8V；BR/TR/TL/BL固定3.3V。J2/J3分别选择2A/2B：pin2为VCCIO，pin1为1.8V，pin3为1.2V；MIPI参考采用2–3连接。以上是电路与配置事实，实物跳帽/电压未确认。电压冲突不能靠I/O标准文字修复。

## 3. DDR活动引脚

PDF页7/Sheet6 U12标MT41J128M16JT-125、16M×16×8；板说明PDF页24–26确认2Gb/x16、row14/col10/bank3。CK/DQS采用Differential SSTL 1.5V，其余活动DDR信号采用SSTL 1.5V。唯一owner为MOD-05的物理DDR端点，不让平台业务FSM驱动DQ或校准相位。方向：A/BA/CK/控制/DM由PHY输出；DQ/DQS由PHY管理双向driver/OE/采样；VREF是专用参考输入，不是业务GPIO，平台FSM不驱动它。

| 信号 | 球号（按位顺序） | bank |
|---|---|---|
| A0…A13 | K15,L13,K12,K6,L11,K8,K10,J13,K11,J14,H10,J10,L12,J12 | A3为4B，A5为4A，其余3B |
| BA0…BA2 | L7,L9,K14 | 4B,4A,3B |
| CK P/N | J15/H15 | 3B |
| RAS_N/CAS_N/WE_N/RESET_N | M14/M15/L15/H11 | 3B |
| CKE/CS_N/ODT | L8/M8/M7 | 4A/4B/4B |
| DQ0…DQ7 | R9,M10,R10,P9,P12,N10,P10,P11 | 4A |
| DQ8…DQ15 | P8,M6,R6,N8,P6,N6,R5,P5 | 4B |
| DQS0 P/N、DM0 | R12/R11、M9 | 4A |
| DQS1 P/N、DM1 | R7/P7、R8 | 4B |
| VREF0/VREF1 | K7/L6（GPIOB_P_09/P_04） | 4A/4B |

来源：v6 peri97–272/302–306、封装表16–47/109–138及原理图。VREF_DDR3为1.5V分压网络，名义0.75V是电路推算，未测量。地址输出14位；peri仍含A14=K13、A15=K9和16位bus，而top/ROW_WIDTH实际14。新设计候选从活动地址bus排除A14/A15；最终闲置/安全停放必须结合匹配2Gb器件引脚定义及板连线依据（PL-B02/07）；工具仅核对封装/配置合法性，不能证明器件允许的电平或连接，不解释成row16。器件速率等级与FPGA软控制器800MT/s候选不是同一性能指标。

## 4. HDMI输出与极性

| 板网通道 | 板P所接球号／资源 | 板N所接球号／资源 | 电压 |
|---|---|---|---|
| CLK | H12／GPIOR_N_10 | H13／GPIOR_P_10 | 3A/1.8V |
| D0 | F15／GPIOR_N_13 | G15／GPIOR_P_13 | 3A/1.8V |
| D1 | G14／GPIOR_N_11 | H14／GPIOR_P_11 | 3A/1.8V |
| D2 | F13／GPIOR_N_12 | G13／GPIOR_P_12 | 3A/1.8V |

原理图PDF页10/Sheet9、板说明txt427–439、封装表相符：四路板P接FPGA N、板N接FPGA P。四通道均为差分输出，唯一driver为MOD-11的专用serializer；PLATFORM只绑定资源/电气，业务FSM不并行驱动或动态改OE。v6 top988–991四路码字取反与此呼应。新设计约定在serializer输入码字的唯一边界补偿一次，实际生成属性不得再交换一次；位序/电气仍须工具和仿真确认。Enable Common Mode Driver来自板说明txt441，未获得当前生成电气报告。

PDF页13/Sheet12的HDMI TX U17：CEC13、HPD19、SCL15、SDA16全部NC。本次按固定1080p60候选输出，HPD/DDC/EDID/CEC为有原理图依据的N/A；不设计不存在的反馈脚。

## 5. 摄像头接入

| 信号 | FPGA P/N球号或GPIO | bank／配置电压 | 来源 |
|---|---|---|---|
| CK PN09 | E8/D8 | 2B/1.2V | PDF页11/Sheet10、peri及封装 |
| D0 PN07 | B8/A8 | 2A/1.2V | 同上 |
| D1 PN10 | C8/C9 | 2B/1.2V | 同上 |
| D2 PN06 | B7/A7 | 2A/1.2V | 同上 |
| D3 PN11 | B9/A9 | 2B/1.2V | 同上 |
| SCL R20 | D12 | TR/3.3V | 同上；双向开漏约束由CAMERA稿负责 |
| SDA R18 | B14 | TR/3.3V | 同上 |
| camera reset R16 | C12 | TR/3.3V | 同上；模组到XSHUTDN是否反相尚未知 |

方向/唯一owner：CK/D0…D3作为D-PHY RX输入，由PHY/CSI接收端采样及管理终端；SCL/SDA由CAMERA配置模块分别管理开漏driver/OE和读回，只驱低或释放，禁止业务模块驱高；GPIO reset由CAMERA启动FSM唯一输出，闲置电平待模组XSHUTDN映射确认，不能仅凭端口名认极性。

J7 QSE与J4/J5 FPC在同页；上述器件球号不能单独推导SC431HAI模组FPC序号、朝向或转接板电平变换。传感器芯片DOVDD1.8V与GPIO3.3V是两个层级，须核对实际模组/转接板。相关来源差异见[摄像头证据](camera-source-and-phase-evidence-v1.md)。

## 6. 本轮结论与后续检查

已闭合所选原理图、当前封装表、v6配置间的主要球号和板电源网络来源；KEY1、PN交换和HDMI NC有直接依据。原始文件未修改，未运行IP生成、综合、布局、STA或器件仿真。

待核验：真实板版号与跳帽、电压；当前peri的合法性及14地址位裁减；Common Mode Driver/serializer位序和极性只补一次；DDR真实2Gb/PHY校准；CSI模组接线、电平、复位极性和发端模式。软件假定基线可以继续设计，不能把这些记录为硬件通过。
