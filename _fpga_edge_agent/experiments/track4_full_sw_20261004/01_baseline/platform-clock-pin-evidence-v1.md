# V4 v6时钟、复位与引脚来源复核 v1

2026-10-04；TRACK4-FULL-SW-001。只读源码与配置核查，未运行约束解析、综合、STA或实机。此页细化BL-03，不提供可直接使用的SDC补丁。

来源与SHA256使用[既有基线](baseline-manifest.json)：`Ti60f225_sc431hai2hdmi_v6.rar`，SHA256 `45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C`。以下成员省略`Ti60f225_sc431hai2hdmi_v6/`前缀，行号来自原归档流式读取。另使用已记录哈希的板说明提取文本`_fpga_edge_agent/reports/audit/environment_20260923/pdf_evidence/TI60F225I3-V4 DEMO板软硬件设计说明-260920.txt`，不是本轮重新逐页审查原理图。

## 1. 实际版本与连接

`ti60f225_oob.xml:2–10`给出Ti60F225/I3、SV2009、实际top `rtl/ti60f225_oob_top.v`；`:56`引用`rtl/csi_rx_controller.sv`，`:76–80`引用当前peri和SDC。XML版本为2026.1.132.1.2，peri第2行是2026.1.132.2.19；不能因此断言已用当前工具重新生成过一致结果。

| PLL/域 | peri来源与配置 | SDC对应/当前连线 |
|---|---|---|
| DDR3_PLL / PLL_TR0 | peri:320–332，25MHz参考，feedback clk_100m；四路DDR输出分频8、clk_100m分频32 | SDC:6–10配置四路400MHz及100MHz；校准tx_cal_clk_90edge/rx_cal_clk/tx_cal_clk动态相位、初值0，名字90edge不能作为固定90°证明 |
| USER_PLL / PLL_BL0 | peri:335–346，27MHz参考；vid/slow/fb/fast分别分频40/20/55/4 | SDC:11–14分别约74.25/148.5/54/742.5MHz，fast phase_setting2；周期数值有小数舍入 |
| MIPI_TX_PLL / PLL_TL0 | peri:349–360，25MHz参考 | SDC:15–18，core100、txc/txd500、txpclk125MHz |
| pll_inst4 / PLL_BR0 | peri:363–372，25MHz参考；reset_name及locked_name空 | SDC:19–20，rxpclk50、CLK_5M5MHz；不能因top有同名线就认定已连入lock/reset链 |
| DDR AXI/core | top:618–627，axi_clk和core_clk均接core_clk | 该100MHz来自MIPI_TX_PLL，四路400MHz来自DDR3_PLL；两个PLL不能因为同为25MHz参考就假定相位确定 |
| HDMI | top:733–775，Debayer在vid_clk_dvi2输出，slow域直接采样并交替取两个像素 | 74.25→148.5MHz依赖相关相位，不是异步FIFO隔离 |

频率是文件配置及分频推算，不是测量。当前新整机的PLL资源、生成时钟关系和合法时序例外仍要独立设计。

## 2. 相机byte clock差异未闭合

当前CSI为5.15：`rtl/csi_rx_controller.sv:3–4,150–155`定义4lane、HS_BYTECLK_MHZ70、CLOCK_FREQ_MHZ100、Discontinuous、pixel FIFO1024。top`:370,382–387`将control接core_clk，byte接i_cam_ck_CLKOUT，pixel接i_mipi_rx_pclk。

SDC`:23`把同一个i_cam_ck_CLKOUT设为10ns，即100MHz，与实际CSI参数70MHz不一致。CLOCK_FREQ_MHZ100对应另一个control端口，不能用它解释掉byte差异。CSI的FIFO_RD/FIFO_EMPTY/HS_IN延迟在SDC`:288–319`也使用这个100MHz时钟，所以不只是一个显示标签问题。

尚需确认SC431HAI实际发端模式/byte频率及IP参数的适用关系；不能仅据两份文件任选70或100作为已验证最终值，也不能借用归档另一5.16/50MHz版本替换后声称已兼容。

## 3. 复位事实与缺口

| 对象 | 原文位置 | 事实及限制 |
|---|---|---|
| w_arstn | top:338–342 | 由i_pll_locked、pll_locked、user_pll_locked组成，表达式未直接含i_arstn或pll_inst4 lock；三个PLL reset接i_arstn |
| CSI pixel reset | top:343–354；rtl/reset.v:119–149,211 | reset_ctrl CYCLE1，rxpclk域异步置位、一拍同步释放；这不是整个系统复位已安全的证明 |
| CSI control/byte | top:382–387 | 直接接i_arstn，不能称已有逐域同步释放证明 |
| DPHY data | top:372–375 | 四路reset常量0 |
| I²C/相机 | top:501–514,523 | 5MHz域延时后释放I²C；o_cam_rst_p=~w_arstn，不能仅靠命名确认模组XSHUTDN极性 |
| 视频 | top:804–805,825–837 | w_confdone常量1；vid_rst_n来自74.25MHz延时，未以cal_done控制该延时 |
| 视频跨域使用 | top:552–560,735–736,945–946,964–965 | 同一vid_rst_n进入frame buffer、Debayer、HDMI slow域，还需核对接收模块处理 |
| DDR/HDMI | top:627,890–893 | DDR rstn=w_arstn，内部受保护；HDMI四路TX_RST常量0 |

新设计需明确每域停止接纳、异步置位/同步释放、lock丢失、校准未完成和跨域握手冲刷。不能只替换一个reset信号就宣称所有域安全。

## 4. 不能照抄的SDC项

- SDC第86行未注释的create_clock仍含`<USER_PERIOD>`，必须在设计中确定；当前未运行解析器，不声称已观察某个具体报错。
- JTAG占位第40/56/61/77行已注释，但关联第41–54/62–75行input/output delay仍有效；是否工具另建JTAG时钟须查实际约束报告。
- 第26行将core_clk、tx_cal_clk、i_mipi_tx_pclk、vid_clk_dvi2、CLK_5M、i_mipi_rx_pclk、sdram_clk、rx_cal_clk各置独立exclusive组。DDR几路同PLL且同时工作，core/txpclk同PLL，rxpclk/5M同PLL；当前top没有证明它们是互斥启用模式。第25行排除rxpclk与JTAG，第27行重复txpclk与rxpclk子集。
- frame buffer实际跨core/rxpclk/vid，DDR实际跨core与DDR时钟（top:552–560,621–627）。exclusive不能代替CDC证明，也不能直接改名asynchronous就宣称解决动态相位与跨PLL问题。
- DDR/HDMI/CSI约束有带坐标的`~CLKOUT~` reference pins，见第87–150/260–283/288–319行；peri、器件布局或工具版本变化后必须核对生成对象。

## 5. 引脚资源来源

以下为当前peri的器件资源名，**不是最终逐脚核准的封装球号清单**。

| 接口 | 当前映射 | peri行号/独立线索 |
|---|---|---|
| 25/27MHz输入 | GPIOL_P_08 / GPIOL_P_10，1.8V LVCMOS GCLK | 85–89；板说明txt:196–210给出J2/H2，另有50MHz R13/3.3V但当前peri未选它 |
| 外部复位 | GPIOR_27，3.3V，weak pullup | 274–275 |
| Camera I²C/reset | SCL R_20、SDA R_18、reset R_16，3.3V | 277–285,299–300 |
| Camera MIPI | CK T_PN_09；D0/D1/D2/D3 T_PN_07/10/06/11 | 526/548/570/592/614；data lane FIFO、静态delay17，不反向；CK无FIFO |
| HDMI | CLK R_PN_10；D0/D1/D2 R_PN_13/11/12；10bit serializer、half-rate | 378–418，fast/slow共USER_PLL |
| DDR CK/DQS | CK R_P_09；DQS0/1 B_P_15/B_P_02，1.5V Differential SSTL | 157–158,252–260 |
| DDR DM | DM0/1 B_P_10/B_P_07，输出tx_cal_clk_90edge | 166–170 |
| DDR DQ0…15 | GPIOB的P12,N13,P14,N12,N17,P13,N14,P17,N07,N03,P01,P08,N01,P03,P00,N00 | 172–250；输入rx_cal_clk，输出/OE tx_cal_clk_90edge，1.5V SSTL |
| DDR地址 | peri有ddr_addr[15:0]各bit资源，含A14/A15 | 97–143,309；不能因此改变实际控制器row14参数 |
| DDR控制 | BA0/1/2=B_N06/B_N10/R_P07；CAS=R_N02；CKE=B_N09；CS=B_N08；ODT=B_P06；RAS=R_P02；RESET=R_N08；WE=R_P05 | 145–164,262–272 |

板说明txt:158–159记DDR banks3B/4A/4B为1.5V、HDMI bank3A为1.8V，与peri:9–12相符。txt:1716–1725的camera表与peri相符但有IMX219参考上下文，不能凭此确认SC431HAI实物线序。

HDMI极性需保留来源：板说明txt:427,432–439记录板网P/N与FPGA差分P/N对调，CLK H12/H13，D0 F15/G15，D1 G14/H14，D2 F13/G13；top:988–991对四路TMDS按位取反相呼应。后续“整理极性”不能无依据删掉该处理。

板说明txt:128,445–479记MT41J128M16JT-125、2Gb/x16、row14/col10，与当前DDR参数相符，仍不证明匹配器件模型或PHY校准已通过。

## 6. 当前结论

BL-03已细化为三项：真实相机byte clock/发端模式；跨PLL/动态相位/逐域复位契约；原理图→球号→bank实际电压→peri→顶层端口的逐项闭合。已有来源足以定位设计工作，尚不能出具合理SDC/引脚或时序通过结论。

本页由独立只读平台调查整理，未重生成IP、未修改peri/SDC/RTL。原始资料、FRONTEND v1及其冻结输入不变；实际构建、时序报告、软件/硬件验收均未执行。
