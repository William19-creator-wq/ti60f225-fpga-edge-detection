# 更新 HDK DDR3 证据核查 v0.1

2026-10-04。状态：READ_ONLY_EVIDENCE / NOT_RUN；本报告不是业务实现批准、完整系统 READY 或本项目新工具 PASS。

本次实际核对了更新包的控制器、工程、外围设置、约束、板说明及历史产物；原资料保持只读。用户最新明确允许使用板卡现有 DDR3，先前“排除 DDR3”边界已撤销，仍只使用板卡现有资源，不增加外接模块。本次授权是该设计边界和只读证据核查，不自动批准业务 RTL、功能脚本、TB、工程改动或工具执行。

## 1. 范围、路径与方法

下列缩写均指实际本地路径。文件行号为本次读取的文本行号；PDF 页号从文件第一页计数，同时列印刷页。RAR 成员仅通过 tar 列目录或输出成员字节读取，没有向磁盘解包或修改原文件。SHA256 对原字节计算；XML GPIO 比较另对元素属性与全部子项规范化比较，忽略排版。

- R（更新资料根）：D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包-0927更新\Ti60F225_DemoBoard_v4完整资料包-0927更新
- D（更新 v1 工程）：R\10_Ti60f225_sc431hai2hdmi_demo\Ti60f225_sc431hai2hdmi_v1
- O（原 v1 工程）：D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4\10_Ti60f225_sc431hai2hdmi_demo\Ti60f225_sc431hai2hdmi_v1
- A（RAR 所在目录）：R\10_Ti60f225_sc431hai2hdmi_demo
- v6、v7 成员根分别为 Ti60f225_sc431hai2hdmi_v6/ 与 Ti60f225_sc431hai2hdmi_v7/。

实际先读取了项目控制面、唯一详细规范 v0.2 与模板。规范 SHA256 为 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；PLAN_TEMPLATE 为 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。实际核对 planning/design-TRACK4-IP-PRECHECK-001.md，SHA256 130481D499D68F4F2F43C6C6731D0E088E4333D4B701C22E1E37C2CCD65BD2E8：第24行已记录 IP-PRECHECK-BL-v1 的89份冻结输入，第3/134行的 READY_FOR_REVIEW 仅属于有限输入预检设计；第144行明确工具阶段尚未执行。本报告不重做全部89份输入审计，不修改其批准、基线或正式状态。

只读方法限目录/哈希、公开文本/参数/报告读取、压缩成员原字节读取与 PDF 文本读取。没有运行参考工程、仿真、综合、布局布线、STA、bit 生成、驱动、网络、安装或硬件操作。

## 2. 已证实事实与历史纠偏

1. **原包与更新包均确实有 DDR3 控制器。** D 与 O 的16份控制器文件、XML/peri/SDC以及 timing.rpt/route.rpt/bit 共22份实际逐 SHA256 比较均相同。更新 v1 的这些报告日期也相同，不能称为新源码或新增验证。
2. v6、v7 RAR 中的16份控制器原字节均与 v1 相同，包含参数、AXI、PHY、校准与 FIFO 文件；改变的是工程/外围及视频时钟配置，不能称为另一版 DDR PHY。
3. 当前可证实的物理芯片资料是 MT41J128M16JT-125、2Gb/x16/256MiB、8 banks、row14/col10/bank3。它与控制器几何参数相符，但尚未执行匹配器件模型的协议/校准仿真。
4. 历史缺口应描述为“匹配该2Gb器件的模型/参数头、当前工具兼容性与完整服务验证尚缺”，不能描述为“资料包没有 DDR3 controller”。控制器的 ddr3_parameter.vh 是控制器配置头，不等于 Micron 行为模型所需的器件参数头。
5. v1 历史报告提供厂商参考工程在旧工具/旧时钟下的有限实现证据；v7 有 bit 成员和2026.1工程版本，但本轮在该 RAR 未找到配套 map/route/timing .rpt 成员。本项目新完整算法、服务、约束和生产 IO 仍 NOT_RUN。

## 3. 板上器件、容量、电气来源

| 实际来源文件（R 下） | bytes | SHA256 | 本次阅读范围及可证事实 |
|---|---:|---|---|
| TI60F225I3-V4 DEMO板软硬件设计说明-260924.pdf | 10574472 | 15800EEBCA75C067DE5CD68988A011A69A2976A7AA72B3315542DF6C8B258719 | PDF7/印刷6概览列MT41J128M16JT-125/x16；PDF24/印刷23§5列2Gb/芯片1600Mbps；PDF25/印刷24列256MB及8bank；PDF26/印刷25§5.1列row14/col10/bank3、§5.2列Ti60软控制器最高800Mbps；PDF9/印刷8列DDR银行3B/4A/4B固定1.5V；PDF11/印刷10列25/27/50MHz晶振及用途。 |
| Ti60F225A_V4_SCH.pdf | 559128 | 855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F | 本轮仅实际定位并核hash，未完成页面/网络视觉核查；不把它当已核对的逐网电路证据。 |

容量按资料和几何计算：2^14行 × 2^10列 × 8bank × 16bit = 2^31bit = 268435456B = 256MiB。AXI_ADDR_WIDTH32 与控制器 ADDR_WIDTH30 不能扩大物理容量，也未证明所有AXI地址均有效；新服务必须明确地址单位、映射、可访问范围与保留区。

芯片资料的1600Mbps规格与 FPGA 参考工作800Mbps须区分。参考 tCK=2500ps/400MHz，DDR双沿800MT/s × 16bit 对应原始峰值1.6GB/s；这是不含刷新、读写切换、AXI背压、bank冲突和仲裁的算术峰值，不是实际可承诺带宽。硬件未到，未观察真实芯片丝印、校准或吞吐。

## 4. 控制器源、接口及参数

### 4.1 16份真实文件与版本一致性

下表路径相对 D/rtl/ddr3_controller；同一 hash 同时绑定 O、更新 D、v6 RAR 与 v7 RAR 对应成员。本轮实际对全部16份完成原字节比较。

| 相对路径 | bytes | SHA256 |
|---|---:|---|
| ddr3_parameter.vh | 972 | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 |
| ddr3_top.v | 58209 | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A |
| lb2_axi_clk.v | 16295 | 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D |
| axi4_bus_ctl/axi4_bus_ctl.v | 187598 | E908D8045FE2332A1740F3ACA0226B5FE0BF4D03E25B040FE0F32015D573AD5B |
| axi4_bus_ctl/axi_upsizer.v | 242096 | 03C25E7276781D9C22F4CBD7B25B76B6317ED7083874A7C94B052A0ABD1188E0 |
| common/simple_dual_port_ram.v | 3413 | 41DA4FB5D1E10B94A1F35DF8075A594071BDF154823FF4EDC87AC5F4E128D934 |
| local_bus_ctl/local_bus_ctl.v | 19528 | 822D5D0F54C7BA0EA8D66F19F1E97CDEA3A159932C64295DFE5CA86F9F814608 |
| memory_bus_ctl/memory_bus_ctl.v | 337766 | A12B886A37278BD44BC207C2DEBD11156EAB1D579E4E3AA7702B229508778882 |
| phy_ctl/ddr_calibration_ini.v | 97258 | 7A6976BCECA5E4598ED9C53C17B522E7C86E07C97F0DBDA16F8286D321035522 |
| phy_ctl/ddr_mpr_rdlvl.v | 17792 | 08446B90C5897750AE6214918981DE8262513745DA7F7D25850BA6A124B9763E |
| phy_ctl/ddr_phy_if.v | 57056 | CE8DFD7600E8BE615611D353CC6B62E7CCF6411D22AC47C45F9B650AD908584B |
| phy_ctl/ddr_phy_rdlvl_dqs.v | 24650 | BB5E2C9D76C2816164A9BFCBF51A3C2760D897C1340AE493D29867FEE601E31F |
| phy_ctl/ddr_phy_wrcal.v | 57540 | 50ACBB56F307A0FC9847981216389D41438649993908FDF96C09D823EE7E5CA9 |
| phy_ctl/ddr_phy_wrlvl.v | 27304 | AEC2C9677C03E1110C542CCC643C1EA0458F1F7FBB93DCAAD105A7623D4A8591 |
| phy_ctl/phy_ctl.v | 44157 | 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B |
| common/efx_fifo_v2.3/efx_fifo_wrapper.v | 54025 | 040558D9DAFD6D7F4C6610B8CD8040CDEDC3F95B58A6F31F32DBD7429182EB98 |

公开 ddr3_top.v 第10行版本1.1，第11行创建日期2023-04-23，第193–221行 protected envelope，ipecrypt20.0.8、Efinix EFX_K01 和 Mentor MGC-VERIF-SIM-RSA-1 key 元数据；第194行 protect version=1 是加密格式元数据，不是工具版本或另一个PHY版本。本轮未解密、未证明当前综合/仿真器能接受该 protected 内容。外围文件同hash也不等于内部算法、校准时序已逐RTL审计。

### 4.2 参数实读

参数文件54行；下列数值均来自同一 ddr3_parameter.vh，而非按文件夹名猜测。

| 行 | 参数 | 实际值/含义边界 |
|---|---|---|
| 3–17 | CKE/CS/CK/RANKS、BANK/ROW/COL、DM/DQS/DQ | 单rank/CS/CK，bank3、row14、col10、DM2、DQS2、DQ16；DRAM_WIDTH8 是该头内部参数，不能据此把物理器件改成x8。 |
| 19–23 | DATA_WIDTH / ADDR_WIDTH / AXI_ID / AXI_ADDR / AXI_DATA | 16 / 30 / 4 / 32 / 128。 |
| 26/28/30–37 | tCKE/tFAW/tRAS/tRCD/tREFI/tRFC/tRP/tRRD/tRTP/tWTR | 7500/35000/35000/15000/7800000/350000/15000/10000/10000/10000；本轮只是绑定既有值，不替代器件模型的时序检查。 |
| 38–43 | tZQI/tZQCS/tCK/CWL/CL/nAL | 128000000 / 64 / 2500 / 5 / 6 / 0；周期量和时间量不得一概混为同一单位。 |
| 46–49 | RTT_NOM/RTT_WR/BURST_MODE/MEM_ADDR_ORDER | 40 / 60 / 8 / BANK_ROW_COLUMN。 |
| 50–54 | RX/TX/TX90选择、CK_RATIO、ASYN_AXI_CLK | 2 / 3 / 0、4、1。 |

ddr3_top.v 第52–58行分别声明 axi_clk、core_clk、sdram_clk、rx_clk、tx_clk、tx_clk_90edge、rstn；注释给AXI/core100MHz、DDR400MHz。第66–93行为DDR hi/lo/oe等外围DDIO端口，第100–153行为AXI AW/W/B/AR/R公开接口：ID4、ADDR32、DATA128、WSTRB16、LEN8、SIZE3、BURST2、RESP2。第162行输出cal_done，公开校准控制还包含PLL shift信号。

顶层 ti60f225_oob_top.v（SHA256 0ACCF23D67A2E5360C91DDCD36563C5E90A682BE52B071B18F2B8F0F40DF5AA9，34765B）第571行起实例化控制器，axi_clk与core_clk都连接core_clk，连接四个DDR时钟/PLL shift/cal_done；第306行w_arstn由多个PLL lock组合。本轮已找到cal_done接线及LED用途，未建立新业务service的“校准成功才能接纳/超时/掉锁/取消/reset/未完成写债”的合同。ASYN1与同名/同net接线的开销和CDC选择，应沿现有IP预检设计分别验证，不在此修改成ASYN0。

既有视频帧缓冲/DMA连接是参考集成来源；它没有自动提供当前 CLASS/QUEUE/POINT/ANN/RECORD、typed_STORE事务、COMMIT、borrow/ref、CLOSE证书的语义。必须设计真实DDR服务适配，不能将vendor framebuffer同名端口视作这些逻辑合同已实现。

## 5. 工程、外围、约束及版本比较

### 5.1 工程/归档输入

| 路径（D或A/成员） | bytes | SHA256 | 版本/比较事实 |
|---|---:|---|---|
| D/ti60f225_oob.xml | 14781 | 571E5A03A7CCC46D2B15CF9D3DCAAA1BC1A874CB3E0908330599891457867BE8 | 第2行2025.2.288.3.8、历史last_run pass/bit元数据；第5/6行Ti60F225/I3，第8行SV09。与O相同。 |
| D/ti60f225_oob.peri.xml | 75464 | 9D378EFF67AC34F88F78A41341A1451E8F3B87B246434DDEDA12C7295A100CAE | 与O相同。 |
| D/ti60f225_oob.sdc | 41339 | 18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E | 与O相同。 |
| A/Ti60f225_sc431hai2hdmi_v6.rar | 7358554 | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C | 20260926221506同名带日期RAR亦同bytes/hash。 |
| A/Ti60f225_sc431hai2hdmi_v7.rar | 7281891 | 9822ACA49F9D41F3948C814FE7527C69F53D1C03A232A9D28FBA42018CD084F4 | 实际读取成员，未磁盘解包。 |
| v6/ti60f225_oob.xml | 13967 | 20B2CF104F8F21864831F23678326FDC491AC5BA3FB8359AD2C8CC775B2DC528 | 第2行2026.1.132.1.2，第5/6行Ti60F225/I3；不同于v1。 |
| v7/ti60f225_oob.xml | 14173 | 9A07E957941CE3334B92B97F27EB173A1BA293B83CDB01F70B73ECA411B741D0 | 第2行2026.1.132.1.2，第5/6行Ti60F225/I3，第8行SV09；不同于v1/v6。 |
| v6/ti60f225_oob.peri.xml | 75065 | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B | 与v1/v7不同。 |
| v7/ti60f225_oob.peri.xml | 76640 | 884225E0EA6554EBA62192CA03D49F8265121E069830FA09EE41694980148605 | 与v1/v6不同。 |
| v6及v7/ti60f225_oob.sdc | 41630 | 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF | 两RAR该成员同字节，均不同于v1。 |

v7工程版本更接近当前工具，仅提供版本候选证据；必须选定整体来源并冻结输入，不能从v1拼接历史报告给v7背书，不能自动替换现有89输入基线。

### 5.2 PLL和时钟差异

v7 peri第332–344行：DDR3_PLL=PLL_TR0、CLK_25M参考25MHz，反馈clk_100m；输出编号0tx90/1sdram/2rx/3tx的divider8，tx90/rx/tx动态相位true，sdramfalse；编号4clk_100m divider32。第335–337行shift/shift_sel/shift_ena。v6对应第320–332行相同DDR PLL配置，v1第317起对应配置。真实初始相位与校准后的相位不同，不能从phase_setting0推定全程相位0。

| 版本 | 原工程SDC实际时钟 | 可作的结论 |
|---|---|---|
| v1 | DDR四时钟2.5ns/400MHz；core/axi100MHz；vid约70MHz，HDMI slow约140MHz、fast约700MHz | 旧厂商报告使用这些约束；不能作为新1080p60/148.5MHz完整证据。 |
| v6/v7 | SDC第6–10行DDR400MHz/clk100；第11行vid13.468ns约74.25MHz，第12行HDMI slow6.734ns约148.5MHz，第14行fast1.347ns约742.5MHz，第15行core100MHz | 原文件提供生产视频候选时钟；此报告未验证摄像头/HDMI全链像素节拍。 |

v7 peri第347–358行USER_PLL参考27MHz、视频输出div40/HDMI slow div20/fast div4及phase2；第361–371行MIPI_TX_PLL及core100MHz设置。v6相应第343/344/346/357行输出候选。新视频时钟不改变相同DDR控制器参数或物理容量。

**明确约束风险（OPEN）：** v7 SDC第86行实际是未注释的 `create_clock -period <USER_PERIOD> [get_ports {CLK_25M}]`；本轮未执行工具，解析结果UNKNOWN，不能当已合理约束。第25–27行还包含跨core/DDR/MIPI/视频的宽泛exclusive分组，第87行起DDR output_delay使用具体reference_pin位置名。新工程需明确定义25MHz=40ns、PLL时钟关系、DDR IO delay、CDC同步与逐个例外理由，并核验生成的reference_pin仍匹配实际布局；不能原样复制为时序证明。

### 5.3 DDR GPIO与封装候选

D/peri47个名称以ddr_开头的comp_gpio完整属性及全部子项，与v6/v7对应47个元素规范化后完全一致：没有增、删或属性/DDIO子项变化。这项比较不覆盖非DDR GPIO，也不替代原理图逐网核对。

历史 D/outflow/ti60f225_oob.pinout.rpt SHA256 C51810862B4181BE41FDD5811782482BEB325280A1DDD6D4BEE484EF2F83C505，47727B；第132–239行范围给DDR/参考晶振封装与bank。DDR为bank3B/4A/4B、1.5V SSTL，CK/DQS差分SSTL；CLK_25M为J2/GPIOL_P08_CLK1_P，bank1A、1.8V LVCMOS。

下面只记录已核到的参考球号，不能直接替代新top的引脚名称/位序验收：

| 信号，按bit升序 | 参考球号 |
|---|---|
| addr[0:13] | K15,L13,K12,K6,L11,K8,K10,J13,K11,J14,H10,J10,L12,J12 |
| ba[0:2] | L7,L9,K14 |
| dq[0:15] | R9,M10,R10,P9,P12,N10,P10,P11,P8,M6,R6,N8,P6,N6,R5,P5 |
| dm[0:1] | M9,R8 |
| ck正/负 | J15,H15 |
| dqs0正/负、dqs1正/负 | R12,R11,R7,P7 |
| cke,cs,odt,cas,ras,we,reset_n | L8,M8,M7,M15,M14,L15,H11 |

peri/pinout还保留addr[14]K13与addr[15]K9模板pad，而ROW_WIDTH14。必须在新物理top确认其真实连接/常值/不使用处理，不能由16个地址pad模板推断器件row16或更大容量。此报告尚未视觉复核原理图网络和真实板丝印。

## 6. 历史实现证据与边界

| D下历史产物 | bytes | SHA256 | 实际阅读事实 |
|---|---:|---|---|
| outflow/ti60f225_oob.timing.rpt | 1529104 | E7E79E5420F22AB9FE1E4116FC48FF80C775A8C916C6FF174A811331BB2EB435 | 第3/4行2025.2.288.3.8、2026-03-31 15:19:05；第10行旧E:/…v1_2401来源；第12–18行I3/-40…100°C/0.95±30mV/typical模型。 |
| outflow/ti60f225_oob.route.rpt | 1918 | 26325CD420420CFA40A5F6025ADAD326B43B6E967A9E6DEC3F2A8A5F6B7CDCB5 | 第3/4行同旧工具、2026-03-31 15:18:43；第9行Ti60F225，第11行routing16s、第43行LatestPnR1m4s。 |
| outflow/ti60f225_oob.map.rpt | 889838 | 03441C406154E35357968B91C1EF1448EF9276F57B7C4B8D2FA4650AC8B00FBF | 历史综合报告；第6083–6096行LUT4 12826、FF8586、SRL8 1143、RAM10 187、DPRAM10 4。只是该参考工程原语计数，不证明新算法可放置。 |
| outflow/ti60f225_oob.bit | 2470212 | 8E2399D808AD0C027B85ED8BEE97BA98604CEC0C8CF43C71E00E8C42128A4ABA | 存在历史bit；与O同bytes/hash。未下载、未证明与本项目新完整设计对应。 |
| outflow/ti60f225_oob.err.log | 38114 | 5114CDD8A5C898F7930CFCA50A84E8290A29855997335900AA5D6DFF459CD4B8 | 多次旧路径/缺端口或.mem记录混杂，不能据此证明最终版本全失败或全无错误。 |
| outflow/ti60f225_oob.warn.log | 9473048 | 6684117034AB2E139DC9DC88AFA8F889DDF04576079AE2D3D741C9CA2CF53E82 | 历史大日志；没有为新系统完成独立警告归属审查。 |

STA第31–44行时钟含core100MHz、DDR400MHz、vid69.999MHz、HDMI139.997/699.790MHz；第67–81行所列setup slack均正，最小为第75行tx_cal_clk→自身0.336ns，第70行tx90自身0.403ns，core自身4.638ns；第85–99行所列hold slack均正，最小第98行MIPI RX0.026ns、DDR RX第92行0.028ns。这只是已列受约束路径在历史报告中的结果，不证明未约束路径/错误例外/IO覆盖，也不能跨版本称v7或新完整系统时序PASS。

v6 bit成员outflow/ti60f225_oob.bit：2624673B，SHA256 3796BA1556B2F3B5382308D554461F28457205D5CD83284B3B0D0EEC1F68989A。
v7同名bit成员：2654763B，SHA256 1D5FF29001DA2064A9A3C5EF7044933B5A01EFECF77D92707A3B1679ACEBEF6A。
本轮实际完整列v6/v7成员并检查outflow .rpt，未找到配套map/route/timing报告。bit存在和XML版本记录不等于已获取对应时序证据。

## 7. 器件模型搜索边界

D/rtl/ddr3_controller.zip：726672B，SHA256 CAC8F9BBD296D712D407FDF5FF943BF8305E7DC142D9D62E511491121C0B9D56。实际列22个成员，其中6个目录、16份控制器文件；没有匹配MT41J128M16JT-125的Micron行为模型或器件模型参数头成员。

对v6/v7完整成员列表实际检查Micron/MT41/model/ddr3.v/器件参数等命名，并读取上述16份控制器成员，未找到匹配2Gb模型。此结论仅覆盖本次三个控制器ZIP/RAR及已列目录，不宣称全部资料包中每个别的压缩包都已展开审查。已找到控制器配置参数，不因配置头存在就声称Micron模型已找到；也不能用另一容量模型模拟成功替代匹配2Gb校准验证。

## 8. 当前可关闭项、仍OPEN与后续交接

| 项目 | 当前结论 | 可审查关闭方向 |
|---|---|---|
| 控制器是否存在 | 已实际定位，原包已存在；更新包v1为同字节副本，v6/v7同控制器。 | 用本报告源hash纠正“没有IP”的说法，不重置已冻结旧预检输入。 |
| 物理型号/几何/容量 | 资料已有；MT41J128M16JT-125、2Gb/x16、row14/col10/bank3、256MiB。 | 新地址计划遵守该容量；实体丝印仍等待硬件人工观察。 |
| 当前工具protected源码/原语兼容 | UNKNOWN/NOT_RUN。 | 指定并冻结整体版本后，按批准的IP预检范围获取真实编译/层级/资源证据，不删blackbox/key错误、不无声再生IP。 |
| 匹配2Gb模型、校准时序 | 本次所查归档未找到匹配模型；NOT_RUN。 | 明确合法来源/模型版本/器件参数与仿真接口后形成受批准验证；模型仍缺时真实报告UNKNOWN。 |
| 新生产DDR服务 | OPEN。 | 冻结ADDR/AXI字节单位、128bit beat/对齐/突发/WSTRB、区域/目录、ownership/ref/borrow、原子typed结果、错误/取消/真实close与复位隔离。 |
| 同时camera、HDMI、Canny/识别吞吐 | OPEN。 | 基于实际访问数量/refresh/切换/仲裁/非暂停视频峰值与FIFO容量，给实时读写保障及最坏上界；1.6GB/s仅峰值。 |
| 新时钟、引脚、CDC与STA覆盖 | OPEN。 | 填实25MHz周期、逐例外审查、验证DDR reference_pin/PLL/动态校准及新top位序，最终获取同一输入基线的PNR/STA/覆盖和警告归属。 |
| 本项目全十一项软件/bit完成 | NOT_READY / NOT_RUN。 | 基础/高阶业务设计与完整组成检查、中文草图、双向追踪收敛到指定READY版本后由用户明确批准实施；随后执行真实测试/综合/PNR/STA/bit。该批准前次序不要求提前生成业务或运行未批准功能验证。 |

允许板载DDR恢复了可用的生产存储候选，使多帧/多对象容量设计有真实板上介质；它没有自动证明当前算法架构、延迟、存储效率或全机资源能满足目标。PC raw arena/UART仍只能作为低速debug/仿真与观察来源，不能代替生产实际DDR/camera/HDMI数据通路；识别与数值计算必须由FPGA实际算法实现，不能迁移PC后称RTL完成。

本轮唯一新增文件为本报告，保存后完整读回并绑定报告hash；没有修改源工程、约束、控制器、业务文档、原资料或正式状态。最终目标保持原完整范围，未降指标。未来bit之后的实体操作仍遵守原人工硬件闸门，不在本轮执行。
