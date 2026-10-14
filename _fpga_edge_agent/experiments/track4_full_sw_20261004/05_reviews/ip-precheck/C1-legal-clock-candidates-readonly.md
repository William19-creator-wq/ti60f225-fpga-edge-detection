# C1 合法 core／axi 时钟候选：只读证据核查

2026-10-04；v0.1；READ_ONLY_EVIDENCE。本文只保存本地来源与候选判断，不批准或实施新 C1，不改原设计、v1.3 卡／JSON、work、RTL、peri、SDC、工具或正式状态。未运行编译、展开、综合、PT、PNR、STA、功能仿真或硬件操作；本文中的既有 PT 内容是此前真实运行的产物，不是本轮新验证。v1.3 仍为 NOT_APPROVED／NOT_RUN，算法实现未获批准。

## 1. 可改变下一次设计选择的结论

**当前 C0 已经将 DDR 的 axi_clk 和 core_clk 接到同一个实际 core_clk net。该 net 由 MIPI_TX_PLL 的全局输出 #0 提供，现有 PT 表给 10ns／100MHz。** 这不是根据两个频率相同推断同源：同一个顶层输入直接连到两个实例端口，帧缓冲 AXI 和原 core 业务也使用它。DDR3_PLL #4 的 clk_100m 是另一条 regional／反馈 net；现有顶层没有 clk_100m 端口或引用。

原批准预检设计的 C1 指定“ASYN1→0＋把全部 core 业务迁到 DDR3_PLL #4＋rclk→gclk”。这是一项原设计选择，并非因为 C0 当前 axi/core 接在不同 net。现装 Ti60 资料明确 #4 固定 regional、不能作为该 fabric 全局时钟迁移方案；不能靠把 XML conn_type 改为 gclk 解决。

因此，**保留现有 MIPI_TX_PLL #0/core_clk 和全部现有业务／reset 接线，仅把 ASYN_AXI_CLK 从 1 改为 0**，可以作为下一份有限实验设计的候选，避免原 #4 迁移的确定性连接限制，也使拟比较的变量更少。本文未实施此变化，不能将它称为原 C1 已获批，不能预判桥消失、资源减少、DDR 校准或最终时序通过。

仍须区分两个关系：①AXI↔DDR core 已同 net；②DDR core100↔PHY／校准400 来自两个不同 PLL，虽然都参考 CLK_25M 且频率比为 1:4，不能据此证明跨 PLL 相位、动态校准、内部传输或复位条件全部成立。ASYN_AXI_CLK 的公开头只给数值默认及参数名；保护体中的分支、内部 reset 和 core↔PHY CDC 不能由本次只读证据确认。

## 2. 来源身份与实际阅读范围

以下 C0 路径均相对 `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_ip_precheck_20261004\C0`。除参数头实际全文 54 行、PLL 段实际全文外，本轮是指定章节／全文文字搜索，不声称重新审计完整业务或保护体。来源 SHA256 与 bytes 已实际核对。

| 来源 | bytes | SHA256 | 本轮阅读范围／用途 |
|---|---:|---|---|
| rtl/ti60f225_oob_top.v | 34765 | 0ACCF23D67A2E5360C91DDCD36563C5E90A682BE52B071B18F2B8F0F40DF5AA9 | 1–105、110–136、265–355、490–510、560–640；全文 core_clk／clk_100m／reset／axi 搜索 |
| ti60f225_oob.peri.xml | 74485 | 2FF6846870EAB4FD1CF190FA11377C7DAE891A693404E7510916AFC801AA4D23 | 全部 PLL_info，316–372；DDR DDIO 时钟属性全文检索 |
| ti60f225_oob.xml | 15074 | 5F0CF2C013F945974052FFE796D68E84815C9F5C02B9CF37EA44086221BFED3A | 器件／top／参数引用检索，无 ASYN 参数覆盖发现 |
| ti60f225_oob.sdc | 41339 | 18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E | 本轮 1–27；此前已全文审阅，其余风险不重复展开 |
| rtl/ddr3_controller/ddr3_parameter.vh | 972 | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 | 全文 1–54 |
| rtl/ddr3_controller/ddr3_top.v | 58209 | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A | 公开 1–193 与全文 clock／cal／ASYN 标记检索；不解密 |
| rtl/ddr3_controller/lb2_axi_clk.v | 16295 | 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D | 1–52、保护区边界及 clock 标记检索 |
| rtl/ddr3_controller/phy_ctl/phy_ctl.v | 44157 | 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B | 22–77、保护区边界与 PLL 选择标记检索 |
| rtl/ddr3_controller/phy_ctl/ddr_phy_if.v | 57056 | CE8DFD7600E8BE615611D353CC6B62E7CCF6411D22AC47C45F9B650AD908584B | 1–150、280–319，保护边界／clock 标记检索 |
| outflow/ti60f225_oob.pt_timing.rpt | 22033 | 7AA17294980337FBF2AD293743B9F3E6638FA38DE2BAD71EFBC5CF2CB1BEB14A | 15–42；当前 PT 的 PLL／输出周期表，不是 route STA |

控制面引用相对 `D:\大三\FPGA_verilog\_fpga_edge_agent`：

| 来源 | bytes | SHA256 | 范围 |
|---|---:|---|---|
| planning/design-TRACK4-IP-PRECHECK-001.md | 18398 | D819D24C98521051A02ADA5D3A18A7A2D56F708ED7670F070B7EC39641FAD104 | C1／ASYN／clock 全文检索及 D 55–77；现稿含既有运行补记，不冒充原批准快照 |
| planning/design-TRACK4-IP-PRECHECK-001-v1.3.md | 27269 | 071CBC949529D834053932795750091F26EB4E40EE80EE6702BA9049269E8BD5 | 当前身份与未批准边界核对；本轮未修改 |
| experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.3.json | 82162 | 344ACB1E46F545812917C6820CBD9B94DBD8B01EDF6DDD0AB2DCB29882E9B2E0 | 来源路径／已冻结输入身份；本轮未修改 |
| reports/audit/environment_20260923/pdf_evidence/TI60F225I3-V4 DEMO板软硬件设计说明-260920.txt | 79766 | E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8 | clock／DDR／PLL 全文检索及 2180–2305；已存在的 PDF 文本提取物 |

现装官方资料／代码：

| 完整本地路径 | bytes | SHA256 | 指定证据 |
|---|---:|---|---|
| C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\pt\doc\topics\hlp-id-clock-src-regional-global.html | 63490 | AC8E357452224DE77C40464320A8A78E3A13E449977BA2371C541398C2D123D4 | 211–234，特别 225–229 Ti35/Ti60 输出连通性 |
| C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\pt\bin\tx60_device\pll\pll_device_service.py | 43046 | C6CA6A71682BD3E3F11D533BFFF5F56C98912D351558E761AAA94C97B965261D | 1027–1060，特别 1042–1049 固定 regional 说明；只读未运行 |

## 3. 从整体到局部的连线证据

### 3.1 整体 core／AXI 路径

`CLK_25M → MIPI_TX_PLL(PLL_TL0) #0/global → 顶层 core_clk → DDR axi_clk、DDR core_clk、frame_buffer axi_clk、i_soc_clk/i_mipi_clk 别名及原 core 业务`。

逐连接证据：

1. top 第116行声明唯一实际输入 core_clk；第574／575行同一表达式分别连接 DDR 的 axi_clk／core_clk。第571行实例没有 `#(...)` 覆盖 DDR 参数。
2. top 第505行帧缓冲 AXI 接 core_clk；第353／354行 i_mipi_clk、i_soc_clk 都直接赋为 core_clk。第336行 MCU reset 释放链使用 i_soc_clk；不是另一条外部同名 100MHz 输入。
3. peri 第346／347行 MIPI_TX_PLL=PLL_TL0、CLK_25M 参考25MHz、反馈 core_clk；第354行 #0/core_clk/out_divider20/is_dyn_phase=false/phase_setting0/conn_type=gclk。当前 PT 第19行绑定这个 PLL 与实际 core_clk 反馈，第32行 core_clk 周期10ns。
4. 同一 top 的 clk_100m 全文检索为零；它不是顶层 core_clk 的别名。peri 第317／318及329行把 clk_100m 绑定 DDR3_PLL/PLL_TR0 的 #4/rclk／core feedback；PT 第20／40行再次区分它与 MIPI_TX_PLL core_clk。

这些证据可证明 AXI/core **同一 net**。现有 PT 只证明外围生成器记录的设置与连通性，尚无本 C0 route／STA 完成，不能由此承诺资源可放置或硬件正常。

### 3.2 DDR 的参数、PHY 与校准路径

`CLK_25M → DDR3_PLL(PLL_TR0) #0 tx90、#1 sdram、#2 rx、#3 tx → DDR 400MHz／DDIO；DDR pll_shift/sel/ena → 同一 DDR3_PLL 的动态相位控制`。

- 参数头第40行 tCK2500ps、第50–53行 RX/TX/TX90选择2／3／0和 CK_RATIO4；第54行 ASYN_AXI_CLK1。top 第15／21行以及 ddr3_top 第22／27行都沿该头。公开 ASYN 参数后面的注释仍是泛用的“memory CKs per fabric CLK”，不能把这条注释当成 ASYN 的完整行为定义。
- ddr3_top 第52–57行声明 AXI/core100MHz、sdram/rx/tx/tx90 400MHz；第188–190行输出选择为 onehot 编号。top 第574–583行保持四个 400MHz net 与三个 PLL shift net 逐一连接。
- peri 第325–329行：DDR #0 tx90、#1 sdram、#2 rx、#3 tx均divider8/gclk，#0/#2/#3动态相位开启，#1关闭；#4/divider32/rclk/非动态。第320–322行三个 shift 端口仍在；PT 第36–40行四路400MHz与regional100MHz一致。
- DDR DDIO 的公开外围属性使用 rx_cal_clk 采样 DQ/DQS、tx_cal_clk_90edge 驱动 DQ/DM、tx_cal_clk 驱动 DQS（例如 peri 第170–172、250–252行）。不能移走或修改这些输出只为了腾出 global #0–3。
- phy_ctl 第41–44行公开选择与 CK_RATIO4、第56–69行公开 core／400MHz／shift 接口；ddr_phy_if 第28及41–50行公开 ratio与各域 clock/reset，第129行有 FIFO_DEPTH16 等内部声明。但 phy_ctl 252–754、ddr_phy_if 315–972、ddr3_top 193行起及 lb2_axi_clk 100–297均处于保护区，声明和名称不能证明内部 CDC、同步／异步分支、读写／校准握手或 reset 实现。

必要保留条件：四路 DDR 时钟及其动态选择、CK_RATIO4／tCK2500和原物理端口必须共同保留；不能把 phase_setting0 当作校准后仍恒定相位0；不能用相同参考晶振、整数频率比或 PLL lock 替代实际相位／jitter／跨域与复位契约。当前公开来源既没有给出“core 必須同 DDR_PLL”明文，也没有提供足够信息证明“任意另一 PLL 的100MHz都受支持”。两种过度结论均不成立。

### 3.3 现有 reset／校准观察边界

top 第306行 w_arstn 是 MIPI i_pll_locked、DDR pll_locked、USER user_pll_locked 的合取，第307／308／310行三个 PLL reset 均沿 i_arstn。第335–338行原 MCU 释放链用现有 core 别名；第580行 DDR rstn 直接用 w_arstn。保持现有 core 候选不需要迁移这些连接；不把它写成已知的 ASYN0 内部同步释放协议。

top 第343–347行 core 计数器通过 cal_done 门控 LED0。已有板手册文本第2237–2238行（标记 PDF101／印刷100）说明 LED0闪烁表示 cal_done高，不闪表示校准有问题。它是未来人工观察入口，不是本轮硬件结果，也不能只凭它证明所有 AXI、存储、错误和复位场景正确。全文指定 clock／DDR 检索没有找到这版 legacy 控制器的 core↔PHY 相位容限／跨 PLL 契约；不将“未找到”扩大成全资料均不存在。

## 4. 全部已配置 PLL 输出与可用性限制

下表来自 peri 全部 PLL_info，频率来自当前 PT 第26–40行。是已配置输出清单，不是时序预算，也不以“没有 RTL 消费”推断可以任意重分配反馈或外围资源。

| PLL／资源 | #0 | #1 | #2 | #3 | #4 | 范围证据 |
|---|---|---|---|---|---|---|
| DDR3_PLL／TR0 | tx_cal_clk_90edge 400M，动态 | sdram_clk 400M | rx_cal_clk 400M，动态 | tx_cal_clk 400M，动态 | clk_100m 100M，regional／反馈 | peri317–331 |
| USER_PLL／BL0 | vid_clk_dvi2约70M | hdmi_tx_slow约140M | i_mipi_rx_pclk50M／反馈 | hdmi_tx_fast约700M／phase2 | 未配置 | peri332–345 |
| MIPI_TX_PLL／TL0 | core_clk100M／反馈 | i_mipi_txc_sclk500M／phase4 | i_mipi_txd_sclk500M／phase2 | i_mipi_tx_pclk125M | 未配置 | peri346–359 |
| pll_inst4／BR0 | pll_inst4_CLKOUT0 100M／local feedback | CLK_5M5M | 未配置 | 未配置 | 未配置 | peri360–371 |

共配置14个 #0–3 global 输出，另有 DDR #4 regional。官方连通性文档225–229行明确 Ti35/Ti60：#0–3连接 global；#4只连接相应顶部／底部界面区域的 regional，只能驱动该区域 interface blocks。工具源码1042–1049行也明确 Ti60 output4 固定 regional。频率可设与物理连通性不同，不可假称 #4 选 gclk 即可实现。

DDR PLL 的 #0–3 已由四个必要的 400MHz／动态校准输出占用。若要同一个 DDR PLL 另出100MHz global，需要重新安排必要输出或另立结构；这是新的设计选择，本文没有给出可实施替换，也没有把 BR0现有100MHz或未配置槽直接代作等价 net。当前 MIPI #0 已能提供实际 core global；无需为了让 AXI/core同源先引入这些变化。

## 5. 原 C1 与新候选应怎样区分

| 方案 | 本轮能证明的事实 | 当前结论／下一步 |
|---|---|---|
| 原 C0：ASYN1、当前 MIPI #0同 core/AXI | 既有实际连接与参数；当前 map／PT已由既有报告记录，PNR仍停在USER1 pack失败 | 保持历史基线，不能称 route／STA／校准通过 |
| 原已批准 C1：ASYN0并迁移全部 core 到 DDR #4/gclk | 原设计62／70／76行明确绑定两种变化；Ti60 #4连通性不支持指定迁移 | 原设计独立BLOCKING仍成立，不无声替换输出／net；保留失败与依赖停止 |
| 新有限候选：ASYN0，保留当前 MIPI #0全部接线／reset／PHY | 现有AXI/core确为同net，global路径不依#4迁移；若只改该静态参数可避免组合改变归因 | 只作后续设计候选，NOT_APPROVED／NOT_RUN；必须记录与原C1不同的范围／新基线和批准，再实测保护分支／资源与接口／约束。是否能作为功能有效的生产路线仍受下面未知项限制 |
| 另立同 DDR_PLL global100MHz结构 | 原 DDR0–3均有必要输出；#4不可直接fabricglobal | 无已冻结方案；需要新PLL分配／接口／校准设计，不能用本文替代 |

原设计第70行把“同频不等于同net”用于要求迁移#4，其原则正确；现有证据已经直接证明 C0 axi/core同net，因此不能继续把“迁移#4”描述成满足这一原则的唯一选择。保留新候选不会自动更改原设计；需要 root在下一版本正式提出。v1.3只包含USER1 peri／SDC修复，不能夹带ASYN或 clock 改动。

仍未解决、影响新候选正确性的项目：

1. legacy ASYN0的实际分支、AXI↔core reset／时序前提、桥是否移除及层级资源；不能从参数0预减RAM或将优化消失记为测得0。
2. legacy core100与400MHz PHY／校准之间的内部传输与容許相位／频率漂移／锁定／动态调整条件。C0原工程确有跨PLL拓扑是参考事实，不是全部条件已满足的证明；ASYN参数面向哪层关系也不能仅从名称推定。
3. 同一新输入下正确的 clock关系和时序覆盖。现有 SDC第5–12行多次定义端口／别名时钟，第26行又将core/axi及PHY等分开 exclusive；不能把这些旧例外视为真实互斥或用falsepath掩盖路径。CLK_25M活动非数值占位及其它既有风险沿v1.3保持，本文不修正。
4. 校准、读写、掉锁／reset与存储义务的功能证据和实际硬件观察仍缺。硬件未到；本轮不执行工具，保护key失败与原停止条件不解除。

## 6. 补充检索的排除说明与收束

为查是否有明文时钟关系，实际只读现装 `efx_ddr3_soft_controller` 的部分说明、example与Ti60 engboard外围／约束。它使用 clk/core_clk/tac/twd/tdqss另一套接口；Ti60 engboard约束第15／18行为应用100MHz、DDR core200MHz，外围302–316行 DDR相应输出400／200／400／400MHz。这不是当前 legacy CK_RATIO4的100／400MHz控制器配置，不能借它证明本候选或换掉冻结IP。本文不沿该新IP展开实现或重生成。

补充输入身份（只用于防止错用版本）：

- `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\ipm\ip\efx_ddr3_soft_controller\source_exp\example_top.v`：9952B，SHA256 `2AE356C3087FC5B635E506754FBD3700D702E6448B1E0FE2FC61F84E03D9E90F`；本轮只检索clock／接口行。
- `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\ipm\ip\efx_ddr3_soft_controller\fpga\constraint\Ti60F225_engboard\constraint.sdc`：28978B，SHA256 `FBD2D03C11D70FE959D02F7D312234CD29CEC6E9A3BEDBA63C1CC5FF0D4059ED`；只检索clock相关行，未审其全部约束。
- `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\ipm\ip\efx_ddr3_soft_controller\fpga\Ti60F225_engboard\ti60f225_ddr3_controller.peri.xml`：45128B，SHA256 `7E56739C788779A331A46DA765DA5960D371FD693A265F6500DD377CAB3E65FF`；只读取PLL及输出设置。

本轮读取了项目入口、持久规则、运行提示、配置、状态、ledger、数据库说明、唯一规范v0.2及模板入口。报告是只读调查的唯一新增文件，不是新业务设计卡；没有改动审批／DB或假装正式状态改变。收束时 `C0_user1_aligned` 仍不存在；保留v1.3卡／JSON原hash。证据已足以说明“当前同net”和原#4选择的关系，到此停止调查和编辑，不重复全文件审阅、不扩算法或硬件。
