# SC431HAI 模式、启动和 Bayer 来源证据 v1

2026-10-04；仅原PDF、原归档公开接口/源码与数学核查。无I²C硬件通信、无仿真、无业务代码或testbench。接续[平台证据v1](platform-clock-pin-evidence-v1.md)及[V4引脚来源v2](board-pin-source-evidence-v2.md)，用于后续CAMERA局部设计。

## 1. 来源与读取边界

- 工程根摄像头SC431HAI_数据手册_V1.1.pdf：42页；SHA256 E3187CEC241FC1FC53983BA31D27C28E2BDA4341E3C89FDF811CA8ED1FD5F8AE。本轮读取PDF页8/10/13/16/17/30/31/32/38文本，实际渲染并查看8/30/31页。渲染在reports/audit/platform_20261004/pdf_pages/sc431hai-page-{8,30,31}.png；Poppler返回0但提示Symbol字体，已核对关键图/表清晰。不是全册OCR。
- V4 v6归档SHA256 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C；全部成员流式只读，未写出业务文件。CSI protected主体未解密；其完整508269字节哈希与可读wrapper调查分开，不称protected算法已审阅。

| 成员（省略归档根前缀） | 原字节SHA256 |
|---|---|
| rtl/ti60f225_oob_top.v | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 |
| rtl/csi_rx_controller.sv | 685D96FD52A604434A1DA0BB404131CD4413BF76ED8EE738AC596B32CE373E5A |
| rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v | DB13D1EED22A9478FD0AFFB9AC86B8265302A474886D7FFF688447AF2470FFE3 |
| rtl/cam_i2c_ctrl/i2c/i2c_master_ctrl_top.v | 2534B3D0CD1793B9F91320FC8D5495820252D0221C38CA9DEA247E27AEA1DC7F |
| rtl/cam_i2c_ctrl/i2c/i2c_master_reg_set.v | 8BB2F5E862A606097F312BB90C2A501FC5F29E8A21737FFCD0A4AB62D90101EA |
| rtl/cam_i2c_ctrl/i2c/i2c_16addr_8data.v | 12210C511B52DCFDACA2F4CFFC0FAFB390AC87ED3B3C97DFA2C6008A339C4BB7 |
| rtl/cam_i2c_ctrl/i2c_master/i2c_master_top.v | BF5DD12F2BF30DBC46A1D4CF1D3D1ACCC05106E14CA1CECF467FD09B46CD45C8 |
| rtl/cam_i2c_ctrl/i2c_master/i2c_master_byte_ctrl.v | 442159006425FA36A946F67AFC62391F9F80142AAD379A640118A28CE67C9F80 |
| rtl/cam_i2c_ctrl/i2c_master/i2c_master_bit_ctrl.v | 2DF1F5D522725EA216385829A4DEC38FDD616E4979AAA0AEF7053AC34BF8AC8C |
| rtl/debayer/debayer_top_2to1.v | F6240A41141046CE9888CFF98A5E59FB18CE81B7E7DE46DC2DB70C8F144B6DD9 |
| rtl/debayer/line_buffer.v | B2772202F1C8A8773F23A4C62A9470D814978B462C8B8EA52B47D11745855A36 |
| rtl/debayer/raw_to_rgb.v | 8EABEA4DDE2241A8D896B132EB991C4637ABC9441D5F58A9F448E14025C0B860 |

## 2. 芯片原文与模组边界

PDF页8图1-3：EXTCLK在上电前可用；DOVDD/DVDD/AVDD与XSHUTDN上升后的T4≥4ms。图中T1/T2/T3≥0ms不能取消T4。PDF页10/38：XSHUTDN低有效，低时无I²C通信；0100[0]=0睡眠、1输出；SID低为7位30（写60/读61），高为32（64/65）；芯片SDA开漏、DOVDD1.8V。

PDF页13：3107/3108芯片ID为CD/6B，1/2/4lane MIPI，推荐不超过1.4Gbps/lane。PDF页16：RAW8 DT2A、RAW10 DT2B；3031[3:0]=A对应RAW10，3018[7:5]=3为4lane。PDF页17仅给EXTCLK6–40MHz/VCO400–1400MHz范围；页32称帧率由FAE提供，VTS与行时间关系不是完整模式PLL推导。

本次GPIO SCL/SDA/reset在TR3.3V；芯片DOVDD1.8V。真实模组是否带稳压、振荡器、电平转换、reset反相及SID取值仍未知。不能把裸芯片图直接当成彩色模组FPC接线。

## 3. 原程序的启动次序

ROM实际164条0x00…0xA3，全是写：
1. index00写0100=00。
2. index90写0100=01，先启动输出。
3. index91…9C随后改3200…320B窗口，其中3208/09=0780、320A/0B=0438（1920×1080）。
4. index9D…A0写3210/11=0144、3212/13=0005（起点324、5）。
5. indexA3写3221=66：镜像[2:1]=11、倒置[6:5]=11，均启用。

因此前几帧可能跨模式更改；新设计应先完成受支持的模式设置和确认，再stream-on，且在新完整SOF后arm。是否可以直接重排原FAE表尚未验证，须保留延时/特殊寄存器依赖；上述不是修改后的可执行ROM。

top501附近5MHz计数器在bit12保持，4096周期=819.2µs。**若从真正XSHUTDN释放算起才开始计数**，该间隔不足PDF规定T4；top523 o_cam_rst_p=~w_arstn，模组极性未知，故只能确认源码计数与条件差异，不能断言实物已经违规或直接翻转reset信号。新合同将T4明确绑到物理释放事件，5MHz需至少20000完整周期，且不把PLL等待误当成这一延时。

reg_set:80–84用rd_done/wr_done推进，未忽略完成信号。但i2c_16addr_8data.v:158–162仅等SR[1] TIP=0，:227–234产生wr_done，未检查SR[7] RXACK（1为NACK）或SR[5] AL。底层byte_ctrl:288–294/320–338确实采第九位ACK，master_top:253/284/299/301将其放入SR；上层未利用。ctrl_top:85把waitrequest接0，wb_ack_o连线未作为高层等待依据。init_done只表示分频/核心初始化，不是164次写成功的cfg_done。

CLK_DIV=0020且CFG5MHz；bit_ctrl:224–237每33输入沿发一次使能，:375–388/510–538每连续写位五次使能，名义SCL=5MHz/[5×33]约30.303kHz，不是byte_ctrl中“4x SCL”注释暗示的值。起止/字节控制与外部拉伸增加耗时。新cfg_done须另外明确全部ACK、错误、超时和模式完成；无I²C成功或波形实测。

## 4. CSI公开wrapper与旧top差异

CSI版本5.15；4lane、HS_BYTECLK70MHz、control CLOCK_FREQ100MHz、Discontinuous、ASYNC_STAGE2、pixel FIFO1024。三个域分别是byte输入、control100、pixel50；旧SDC却把byte设100MHz，不能用control参数解释掉差异。

公开输出：pixel_data64、valid1、pixel_per_clk4、datatype6、word_count16、shortpkt16、VC2/VCX2及错误/debug。旧top忽略ppc/DT/WC/短包/VC，只用valid与hs，取4个10bit样本的高8位：data[9:2]/[19:12]/[29:22]/[39:32]写32bit RAW8。debug_out为32位而旧top接16位。不能因此证明每个有效边沿恒有四像素、帧尺寸恰正确或错误被完整传播。

RAW10高8位截断是源代码事实，有损2LSB；新CAMERA要明确选择RAW10内保持/何处转换，保证四lane→两pixel计算的峰值和不可反压FIFO。4×50MHz=200Mpixel/s与2×100MHz=200Mpixel/s只是峰值相等，不能掩盖RAM/DDR停顿、包事件或FIFO满。byte70MHz对应每lane560Mb/s是频率换算，发端真实模式/停顿/帧率尚未确认。

## 5. Bayer图的读取坐标

PDF页30图2-6/2-7实际像素核对：A1位于图的左上，但“First Pixel(0,0)”及Column0画在**右上**。按读出坐标(x=0→1,y=0→1)观察，首点B，随后读出的Column1为Gb，下一行Gr/R，即正常读出BGGR；按纸面从左往右读图会误判。

PDF页31给镜像/倒置与输出起点寄存器。旧ROM裁剪起点(324,5)为偶/奇，最后同时mirror/flip。**条件推断**：若起点解释为未变换阵列坐标，并在偶数1920×1080裁剪后mirror/flip，起点奇偶变为(1,0)，得到GBRG；仅裁剪则GRBG。但PDF未充分说明裁剪与镜像坐标的组合先后，不能将GBRG当作已确定的真实输出相位。

raw_to_rgb的有效运算分支与注释存在不一致，LEGACY边界还改变首行处理；模块名raw_datax4_i实际端口16bit、P_DEPTH8，处理一组两个RAW8。旧Debayer输出pair48排列是{B1,G1,R1,B0,G0,R0}；top的HDMI旁路又交换R/B，gamma路径不同。显示正常颜色不能由这些名字推断。

后续独立相位测试：固定四种phase参数，用解析RGB纯色/彩条生成Bayer；核对首点、邻域、裁剪/镜像/翻转和边界颜色。灰度渐变测试4501[3]有原文依据，但不能用它单独验R/B或Bayer相位。实际模组相位后续由彩色输入观察确认；本次软件参考选择必须显式参数化，不静默猜一色序。

## 6. 供后续设计采用的中文顺序

先冻结模组接线/电平与SID假定；建立物理XSHUTDN映射→允许EXTCLK及电源稳定→真正释放XSHUTDN→完整等待T4→读ID并检查ACK→按有依赖依据的表配置RAW10/4lane/1920×1080及phase→确认所有写/必要读回→stream-on→各域同步释放→丢弃未arm帧→收到新的完整合法SOF后领取源/坐标→逐行核WC/DT/数量/错误→EOF与全部写结账后才允许COMPLETE。满FIFO/坏包走独立错误关闭通道，失败源不发布，不因丢EOF永久占槽。

这些是设计输入和操作建议；CAMERA完整A–L、Debayer数值/窗口/边界、具体配置表及吞吐契约还未形成。此页不构成READY或实现授权。
