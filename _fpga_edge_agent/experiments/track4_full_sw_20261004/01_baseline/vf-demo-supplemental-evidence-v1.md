# 用户指定VF与Demo路径补充证据 v1

2026-10-04；只读资料复核，关联TRACK4-FULL-SW-001及DISPLAY/DDR/PLATFORM。回应用户“这里也没有吗”：**两个精确目录都有工程、DDR模型和仿真资料；缺少的是当前发现材料中与预设V4的2Gb器件匹配的完整模型组合。** 不将目录存在、历史生成物或源码可读写成软件验证通过。

## 1. 目录与核查范围

- VF根：`D:\大三\FPGA_verilog\VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包\VF-Ti60F225_HDK_V2.1_20251009\VF-Ti60F225_HDK_V2.1_20251009`。本轮实际枚举11,672个展开文件，重点读板/工程XML、DDR模型、CSI/HDMI和两个SC1336 ZIP；两个ZIP各567成员。
- Demo根：`D:\大三\FPGA_verilog\Demo\Demo`。已有展开5,254文件范围记录，本轮重点重新读tinyml工程及IMX219 HDMI ZIP；ZIP实际568成员。另一个“创建和导出模型.7z”的6成员是Keras/TFLite/H5材料。
- 原V4参考仍在`Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4\10_Ti60f225_sc431hai2hdmi_demo`，已有SC431HAI v6源码/配置证据，不能说整个工作区无SC431工程。

本轮不是全部PDF逐页/OCR审查，不枚举私人目录；没有解压落盘、修改原包、解密、运行旧脚本、仿真或构建。既有宽范围记录见[评审§2](../05_reviews/review-and-blockers.md)，新增公开编码器事实以下单列。

## 2. VF中已找到什么

| 对象 | 相对VF根的实际位置 | 可用事实与边界 |
|---|---|---|
| 板资料 | `01-用户手册/VF-Ti60F225 易灵思FPGA开发板-V4.1.pdf` | 有板卡说明；不等于借用V4实物身份 |
| 引脚/原理图 | `04_原理图&PIN TCL/Ti60_F225_Core_V1.4.pdf`、`Ti60-F225_Button_Board_V1.1_20230915.pdf`、`Ti60_Board_引脚定义-20230703-V1.0.xlsx` | 是VF板的板级来源，不能直接套到V4 |
| HDMI | `06-FPGA_HDL_Basic-2023.2/07_Ti60_HDMI_1080P_Lvds_Test/` | 可读rgb2dvi/tmds_channel、扫描、XML/peri/SDC及旧outflow |
| 四lane CSI | `07-FPGA_HDL_Image-2023.2/03-1_Ti60_SC130GS_MIPIx4_HDMI_1280720/ip/csi_rx/` | wrapper、define/settings、保护主体、三种仿真器模型及Testbench；SC130GS配置不是SC431配置 |
| DDR IP与模型 | 同SC130GS工程的`ip/DdrCtrl/`；代表展开模型为`06-FPGA_HDL_Basic-2023.2/06_MIPI_LCD_Test_1024600/ip/DdrCtrl/Testbench/ddr3.v` | wrapper、保护controller、bin/vh、Micron模型、memory_checker_axi、Modelsim流程及三仿真器目录均存在 |

VF有24份展开ddr3.v，两个SC1336 HDMI/LVDS ZIP各一份，共26；均为同一默认4Gb/x16模型字节。展开文件名及此次检索HDL/XML/JSON/TXT/MD没有SC431命中；实际相机工程有SC130GS/SC2210/SC233HGS/OV5640/AR0135/MT9M001/SC1336。此范围结论不否认V4目录已有SC431HAI。

32个顶层旧XML实际均选择Ti60F225/C4。展开树有32 bit、32 hex、116 bin、533 SDC、25 timing.rpt，均是历史生成文件，本轮未重新运行。HDMI彩条lcd_para.v定义148.5MHz及2200×1125，但VIP_System.sdc第14–16行仍为40ns/6.6667ns/1.3333ns，即25/约150/750MHz；这些旧报告不能证明新V4 148.5/742.5MHz时序已闭合。

## 3. Demo中已找到什么

展开`tinyml-main/tinyml_hello_world/Ti60F225_tinyml_helloworld/Ti60F225_tinyml_helloworld.xml`第5–6行选Ti60F225/I3。`src/ddr3_controller/`有ddr3_top.v、phy_ctl/ddr_phy_if.v及读写校准模块；ddr3_parameter.vh为BANK3/ROW14/COL10/DQ16/tCK2500ps，对应2Gb地址几何。**控制器地址几何不是Micron器件仿真参数头。** ddr_phy_if.v第312行起主体受保护；sdc/ddr3.sdc列400MHz DDR/100MHz core，peri第316–338行有动态相位设置。是否匹配V4板电气/器件/工具尚待核验。

[IMX219 HDMI归档](../../../../Demo/Demo/Ti60F225_IMX219_HDMI_1080P.zip)包含DDR IP、Modelsim保护controller、bin/vh、Testbench/ddr3.v及4096Mb头。主XML选Ti60F225/C4，摄像头为IMX219。它不能直接替代V4/I3＋SC431HAI工程或板级约束。

## 4. 可读TMDS编码器这一补充来源

同一ZIP中`src/hdmi_ip/rgb2dvi.v`与`tmds_channel.v`完整可读；Ti60_Demo.xml第33–34行实际引用两者。root通过tar读回两文件全文，未执行。以下为源码事实：

1. wrapper为单pixel接口，每PixelClk接一个RGB888，低8bit为B、中8为G、高8为R；三个tmds_channel实例，B通道带VS/HS，另外两通道control为0。
2. tmds_channel组合部分使用当前input及沿前disparity；正沿注册10bit符号并更新disparity。该沿后输出稳定，下游正沿读此符号为下一沿。wrapper直接assign输出，没有额外输出寄存器。
3. 顶层example_top第1276/1284行把PixelClk连clk_pixel_2x，顶端定义148.5MHz；74.25MHz旧旁注不能作为真实连接事实。
4. wrapper虽声明SerialClk/reset/bitflip/oe/OSERDES参数，这些未被编码主体使用；TMDS P/N端口未驱动，serializer在peri第647–686行half-rate/serial_width10组件。可读编码器不等于可读完整serializer或已经通过物理相位验证。
5. 文件头仅日期/模块名及Sameer Puri署名、GitHub链接；本ZIP无LICENSE/COPYING成员。复用条件尚需来源核查。可作为DISPLAY新adapter的候选，尚未选定、复制或批准实现。

新增来源不能证明原V4受保护encoder正确，也不能直接消除DP-B01/02。下一设计可以比较公开编码候选与现有IP；仍须冻结数值、reset、single-pixel与pair适配、相关时钟和专用serializer契约，获批后做真实验证。

## 5. DDR缺口的精确解释

VF26＋Demo ZIP1共27份找到的Micron ddr3.v原字节SHA一致：`AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA`。模型97/98行默认den4096Mb/x16；122/123行含2Gb分支但引用`2048Mb_ddr3_parameters.vh`，此次展开及相关压缩成员范围没有该头。Modelsim_AXI4.do第5行同样指定4096/x16。

V4资料给MT41J128M16JT-125、2Gb/x16；VF资料给K4B4G1646E、4Gb/x16。因此现在缺的是**匹配2Gb器件的参数/时序依赖、配置和使用条件及完整器件资料**，不是DDR controller/PHY一概不存在。仅改宏、压缩可访问地址、复制4Gb头或强制校准成功都不能补齐这项验证证据。既有模型获取申请保持PENDING，本轮没有新增申请或联网。

## 6. 绑定的实际字节

ZIP SHA256 `7AF992E1F73A5ECAC882BD374E0A2329AD44B730981E3AA8CF3E611C3C6BB030`，39,701,615字节。root用只读ZipArchive流计算以下7成员原始字节SHA，未通过文本换行归一化计算。

| ZIP内相对顶层Ti60F225_IMX219_HDMI_1080P/的成员 | 字节 | SHA256 |
|---|---:|---|
| src/hdmi_ip/rgb2dvi.v | 2692 | FC61BAEC2AAC7E28A6561FC0CBF23EBCE625B2691E917BDC13F7E8FD4FC39782 |
| src/hdmi_ip/tmds_channel.v | 4854 | AE2B47914D9CF7E313585BFA3C035E99C88E03AA8A31E7A495C677A791D62B6E |
| Ti60_Demo.xml | 12281 | C94EB8C6EB9B053613A8EBFBE26EE4A5C7DBF76980DC82B8F9D137D7D1395966 |
| Ti60_Demo.peri.xml | 123409 | 45EC41C957EFEA5AE87D746F3DDE5DE4F7DF7B210D9897FA0DE93F1C368A37F6 |
| Ti60_Demo.pt.sdc | 72850 | 618B1048BFF0197CA116F5F2B3BF2DEAD0BE7643E1CC4BB25AE5FFBC3551FEBA |
| ip/DdrCtrl/Testbench/ddr3.v | 168423 | AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA |
| ip/DdrCtrl/Testbench/4096Mb_ddr3_parameters.vh | 54733 | 39BD3B893D9BEB65EA181DFE53A83ACC6291749A05FB46BBDF77C3ACD155A349 |

展开tinyml controller参数994字节，SHA `2C4C19966ECB897A477DCD7374DACC543C8CF54C9B128FAF1A69685CB34F1D75`。上述只证明来源内容/参数，仿真、综合、PNR/STA及本次bit/hex全部NOT_RUN。
