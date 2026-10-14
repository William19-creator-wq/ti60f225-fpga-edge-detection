# TRACK4-ALGORITHM-DDR-QUALIFICATION-001：独立 DDR 资格设计 v0.1

## A. 状态、入口与批准边界

- Goal：为现有 C2 Elitestek DDR3 v1.1 建立独立、有限、可追溯的软件资格验证，回答公开接口能否承载拟议 backend，而不借原摄像工程的失败或理想 RAM 代替结论。
- Current state / Target state / Gap：只读资料调查完成；目标是未来 Q0–Q3 的限定证据包；独立展开、匹配模型、PHY 仿真及成功服务合同均未闭合。本卡 NOT_READY / NOT_APPROVED / NOT_RUN。
- 任务位置：支持 A3/A4/A6 的存储前提，属于新的资格设计；不实现 Canny/识别/生产 backend，不改变 1080p、完整 Canny、显示 60Hz、原识别要求或引入算法 FPS 门槛；不操作硬件、不生成 bit/hex。
- 入口已按控制面顺序阅读 AGENTS→config/AGENTS→AGENT_PROMPT→PROJECT_CONFIG→PROJECT_STATE/TASK_LEDGER→database/README→WORKFLOW→APPROVAL_MANIFEST→赛题及硬件证据/赛题流程。正式状态仍 WAITING_FOR_HARDWARE_BASELINE，DB 仍 NOT_CONFIGURED；本卡不写这些状态。
- 唯一规范为工程根 AI_Agent_代码可理解性规范_增补提案_v0.2.md，SHA256 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2；历史全文读 1–919，本轮有限复读 1–260、290–613、646–761，哈希未变。PLAN_TEMPLATE.md 全读 1–154，SHA256 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79。
- 已有 AP-IP-PRECHECK v1/v1.1/v1.2 仅支持原有限预检；其排除项含功能脚本/TB、模型修改、联网。本次不扩充其本地审计例外。R1 批准也排除后续 DDR 实现。Manifest 全读 1–106，SHA256 7AC43241B211A52087DD74A5306778D307DB57C732D78F104382BB42A5C8F76D。
- Human approval gates：本轮只允许保存本卡；未来必须明确冻结设计版本、Q 阶段范围、全部输入/工具及工作路径后重新指定批准。资格试验的审计方式也需明确，不预先继承旧例外；网络依赖另沿既有请求处理。
- 阅读顺序：A 来源/缺口→B 整体判定→C 连接→D 接口→E 中文操作草图→F 语言→G 套件→H 追踪→I 停止点；下一项允许行动是根 Agent 只读审阅本卡。

### A1. 真实来源账（SHA256；范围是实际读取，不是已证明功能）

以下路径前缀：C2 = _fpga_edge_agent/work/active/track4_ip_precheck_20261004/C2；PR = _fpga_edge_agent/experiments/track4_full_sw_20261004/05_reviews/ip-precheck；EI = C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/ipm/ip/efx_ddr3_soft_controller。下表是来源账，不是新的冻结基线或许可。

| 来源路径 | SHA256 | 实际范围与限定事实 |
|---|---|---|
| C2/ti60f225_oob.xml | D67BFF492FDE948FDA71B8A9905218B6A5A07E7CA6BFA278CB266E0140299DE8 | L15–28 的 13 个 DDR .v 选择；工程其余部分未作为资格闭包 |
| C2/ti60f225_oob.peri.xml | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B | L320–360 的 PLL 输出/动态相移配置 |
| C2/ti60f225_oob.sdc | 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF | L1–27 的时钟声明/例外；不证明 CDC、PHY 校准或时序通过 |
| C2/rtl/ti60f225_oob_top.v | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 | L332–366/525–636/659–718/802–838，另参数/AXI 声明定位；实际接线但非独立仿真 |
| C2/rtl/ddr3_controller/ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A | 公开 L1–192，L193 保护边界；版本 1.1、端口/默认参数 |
| C2/rtl/ddr3_controller/ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 | 全文 L1–54；ROW14/COL10/BANK3/DQ16、CK_RATIO4、ASYN1、CL6/CWL5 |
| PR/C2-questa-DUT-vlog.log | E96838F68E478EAAC83B8DB17E149FE8CAD2EC00ADCC2FA2A1F727EE6B43849B | 全文 L1–83；DDR 主模块 L12–24、FIFO 辅模块 L25–30；CSI L78–81 三错误 |
| PR/C2-questa-vendor-vlog.log | 1B22EA9AD5B8FC564130C19A69DF90D7D420FDD95975DB7B7F9CC65B14E8CE10 | 全文 L1–62；当次 15 个厂商原语编译 Errors0/Warnings0，不等于 DDR 展开/功能通过 |
| PR/C2-questa-DUT-inputs.json | ED7E4513D5D5459C5F95F0045A030829466878B0F45734005C581E7E6256F68B | L1–28 与 vlog 全量 argv；原工程输入不能原样冒称独立 DDR 闭包 |
| PR/C2-clock-and-simulation-scope-review.md | 95A634A331850436800A7314B5897B4DF67E5F6DFD75443D101583FE76544DFC | 全文 L1–168；厂商输入哈希/时钟问题的历史记录 |
| PR/RUN_REPORT.md | 0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA | L16–20/48–67 及定位扫描；原 map exit0，独立 DDR vopt/功能/修正后时钟运行未执行 |
| EI/testbench/README | 50836CCC4D4AE2BEEEEF314B28FD3CA3FD5743D49D39224896A4584FA3E541F1 | 全文 L1–5；示例环境说明 |
| EI/testbench/axi_modelsim.do；native_modelsim.do | 937EEC8785ABDD5E739D69A8485DF9011E4930FADD9A0046BA327D4CA0E84773；100BFA1A0FA747116EA09E44205BB6A885B0E90855A3FE090A25DA5D3A735447 | 全文 L1–18/L1–17；只读，未执行 |
| EI/testbench/test_list.f；ddr3_device_ID.vh | 0565661E3ABCC724C6245DE73E7D4B4F82B2757BFF023C2707ECE48D83F566F9；F67A7809293DF698CB2189A3EEB6ADD4E9284AA66C3FC37F481E294D37475578 | 全文 L1–25/L1；清单/头文件存在不证明可运行 |
| EI/testbench/ddr3.v | AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA | 公开 L1–163；Micron v1.74，L97–98 为 4096Mb/x16，L122–123 引用缺失 2048Mb 头 |
| EI/testbench/4096Mb_ddr3_parameters.vh | 39BD3B893D9BEB65EA181DFE53A83ACC6291749A05FB46BBDF77C3ACD155A349 | L1–156/536–566 及参数定位；x16 ROW15，不匹配 C2 ROW14 |
| EI/testbench/axi_ddr3_param/ddr3_controller.vh；EI/testbench/ddr3_parameters.json | 7A1961CAB0833DB684053A7ECD46771C04CFF618CFA031DEE17D4FF3901E8232；89344AF8CE5A5BEDE4AE3BC24157BABE0C54787B822576EF9B0513112255DD40 | 全文 L1–51/L1–84；ROW16/DRAM_WIDTH16 等旧示例选择不能证明 C2 |
| EI/testbench/efx_ddr3_soft_controller_tb.v | 24093D654EA1C086E6F7572186BD029A9C756531D17810D30A747259945F6339 | L1–105/239–340 及实例/终止定位；core200MHz，非 C2 ratio4 |
| EI/testbench/example_top.v | 0A72DA2E5247D9FFA20BC07DF732E036EE89600E591C7A189D8882471DBF0F9E | L1–105/118–170/190–285/301–342/375–415；ID8/合并 A 通道，BRESP 未接 |
| EI/source_exp/memory_checker_axi.v | 0A1106C3FC20A918A66A18FA6584AA3D1969086A8FE466C71D125763AB22B3CC | L1–180/217–343 及字段定位；没有 BRESP 检查输入，不能充当完整资格 checker |
| EI/testbench/efx_iddr.v；efx_oddr.v | 06E7B70585650B86C842AABEBF98C40D8899CC08E4D595044BE8B80A0B25A548；CA2C958516C9C7FD7B8ECC27EE70D43AEF3212EAF1C1DB71876025E544AEB92F | 各公开 L1–85；只是 PHY 适配调查来源，不默认可直接接 C2 |
| C2/rtl/frame_buffer_V3/sim.do；lpddr4_tb.v | A7B139455EA9A24C187A96B4A51F5BDCBD94C1B38C47DDB920B9EC0DD01244AF；05DB94C6800C7171FB407A6651B2E4136B4DFEB7DB3343278619D41DCEB63A3E | 全文 L1–33；TB L1–120/204–269，L215–260 是 axi_ram，无真实控制器/PHY |
| tools/REQUEST_DDR3_MODEL_20261004.md（控制面相对路径） | 422C7423FBFE91827CF7B9E5736DE73B2A0290CB704CA9F2CBF64BA9D0D2615B | 全文 L1–25；REQ-DDR3-MODEL-20261004 仍 PENDING；不重复提出问题，不据此联网 |

已逐项只读检查缺失：EI/testbench/modelsim/efx_ddr3_soft_controller.sv、testbench/ddr3_controller.vh、testbench/memory_checker_axi.v、testbench/efx_srl8.v、testbench/2048Mb_ddr3_parameters.vh，以及 do 所指 EI/source/efx_ddr3_soft_controller.v。别处同名文件不自动满足相对路径/版本/参数；不执行旧 do。

### A2. Q0 候选依赖闭包（以下均 C2/rtl/ddr3_controller/ 下）

| 原 XML 选中 .v | SHA256 | 公开扫描范围；保护实现不采用 |
|---|---|---|
| ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A | L1–192；13 个文件包含 top，不是 13 个子模块 |
| axi4_bus_ctl/axi4_bus_ctl.v | E908D8045FE2332A1740F3ACA0226B5FE0BF4D03E25B040FE0F32015D573AD5B | L1–100；L101 边界 |
| local_bus_ctl/local_bus_ctl.v | 822D5D0F54C7BA0EA8D66F19F1E97CDEA3A159932C64295DFE5CA86F9F814608 | L1–80；L81 边界 |
| memory_bus_ctl/memory_bus_ctl.v | A12B886A37278BD44BC207C2DEBD11156EAB1D579E4E3AA7702B229508778882 | L1–136；L137 边界 |
| phy_ctl/ddr_phy_wrlvl.v | AEC2C9677C03E1110C542CCC643C1EA0458F1F7FBB93DCAAD105A7623D4A8591 | L1–108；L109 边界 |
| phy_ctl/ddr_phy_rdlvl_dqs.v | BB5E2C9D76C2816164A9BFCBF51A3C2760D897C1340AE493D29867FEE601E31F | L1–102；L103 边界 |
| phy_ctl/ddr_phy_wrcal.v | 50ACBB56F307A0FC9847981216389D41438649993908FDF96C09D823EE7E5CA9 | L1–62；L63 边界 |
| phy_ctl/ddr_calibration_ini.v | 7A6976BCECA5E4598ED9C53C17B522E7C86E07C97F0DBDA16F8286D321035522 | L1–114；L115 边界 |
| phy_ctl/ddr_phy_if.v | CE8DFD7600E8BE615611D353CC6B62E7CCF6411D22AC47C45F9B650AD908584B | L1–314；L315 边界 |
| phy_ctl/phy_ctl.v | 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B | L1–251；L252 边界 |
| phy_ctl/ddr_mpr_rdlvl.v | 08446B90C5897750AE6214918981DE8262513745DA7F7D25850BA6A124B9763E | L1–83；L84 边界 |
| lb2_axi_clk.v | 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D | L1–99；L100 边界 |
| common/efx_fifo_v2.3/efx_fifo_wrapper.v | 040558D9DAFD6D7F4C6610B8CD8040CDEDC3F95B58A6F31F32DBD7429182EB98 | L1–1376 模块/include/版本定位，不称全文语义审阅；含六个 FIFO 辅模块 |

另须原 params 头及真实 C2/rtl/simple_dual_port_ram.v（SHA256 01B74E74D39C4E4AE380BC7BE73329987B17FFFAEA58BC7C92A9B24E4A110C5D，公开 L1–35）。原编译 L11 选的是这一份；不能递归加入同名 common/simple_dual_port_ram.v 或未选 axi_upsizer 制造重定义。合法展开后再判断最小闭包，当前不能断言只有这 14+1 份即足够。
厂商原语候选沿 PR/vendor 日志：安装 sim_models/verilog 的 efx_add/comb4/dpram_5k/dpram10/dsp12/dsp24/dsp48/ff/gbufce/lut4/mult/ram_10k/ram_5k/ram10/srl8 共 15 .v；各实际 SHA 已在 PR/clock review 列明，未来重新冻结字节、include、合法使用条件。Questa 2024.1 仅由历史日志识别；未来 exe 路径/hash、许可、选项与库映射尚未冻结。Efinity/PT PHY 模型已见文件，不默认任何 PLL/DDR16 版本匹配本 C2。

### A3. 阻塞、前提与可独立继续项

| OPEN | 影响/责任与解决方法 |
|---|---|
| Q-B01 | Q0：根负责冻结独立工作范围、13 .v+params/SDP/真实厂商原语、合法保护展开闭包、工具及新生成文件名；无新批准不得生成/运行 |
| Q-B02 | Q1：匹配 MT41J128M16JT-125 的 2Gb/x16 模型、完整 2048Mb 参数头、速度/时序、来源和使用条件仍缺；沿已有 PENDING 请求，不静默改 4096Mb |
| Q-B03 | Q1/Q3：公开双沿/OE/相移接线还须选定合法仿真适配、PLL 相移响应与跨域复位释放；根与板卡/IP 资料逐项对照 |
| Q-B04 | Q2/Q3：未找到与 C2 Elitestek v1.1 匹配的 B→读可见性、无未来 effects、校准失效/独立排空合同；根补厂商资格依据，未知维持 Q |
| Q-B05 | Q2/Q3：可合法施加的错误/校准丢失条件、记录 schema/检测期限及 success vs UNKNOWN 判读须冻结；不可向保护体 force 或伪造 cal_done |
| Q-B06 | 审批/审计：独立工作路径、报告路径、工具基线、阶段许可及本地审计条件未批准；正式 DB/状态保持原样 |

可独立推进的是纯文档评审，以及未来单独冻结/批准 Q0；Q0 不以匹配 DRAM 模型已就绪为前提，但不能越过合法展开缺口，也不能由 Q0 推导 Q1–Q3 通过。

## B. 整体行为与有限判定

| REQ | 外部可观察的资格目标 |
|---|---|
| DQ-01 / Q0 | 新独立库编译并合法展开真实 C2 DDR，逐项报告模块/参数/依赖；CSI 不进入闭包。原 CSI key failure 既不证明 DDR 失败，也不证明 DDR PASS |
| DQ-02 / Q1 | 真匹配器件模型经公开 PHY 接线完成初始化/校准；记录六类时钟、reset、相移和 DDR 引脚；未校准禁止新普通 issue |
| DQ-03 / Q2 | 在冻结有限集上，真实 AXI 握手/ID/RESP/LAST/保持/字节写读一致；从写 B 接受后发真实读对照，不把模型直接写值作为 DUT 读结果 |
| DQ-04 / Q3 | 取消、复位、校准丢失时保留旧握手和 effects 债；自身 quiet 与 IP 无未来访问分开，未证明独立关闭则 UNKNOWN，不释放旧对象/pin |
| DQ-05 / 证据 | 每个 case 有输入/工具/hash、完整事件、数值/协议错误、退出状态和限定覆盖；有限 PASS 不升级成生产 QoS/帧率/wholefit 或硬件通过 |

触发者是获批独立软件试验；输入是冻结参数、时钟/复位、合法 AXI case 与匹配模型；输出是有限资格报告和 OPEN/FAIL/UNKNOWN。仅将已覆盖阶段标 PASS_FINITE；没有结果与已观测错误分别标 NOT_RUN/BLOCKED 与 FAIL，不将所有缺口混成 DUT 失败。
正常样例：校准真成立→ID0/LEN0/SIZE4/INCR 写 16B→真实 B 交付→读同范围→真实一拍 R/LAST 比对；边界样例：从 0xFF0 起的 32B 必须拆成两个 LEN0，不能跨 4KiB 发 LEN1。未知写响应可见性仍保 Q-B04，即使该有限样例比对相同。

## C. 整体→局部→交接

MOD-QC（候选配置/范围 owner）冻结参数、case、地址 arena 与工具，承担 DQ-01/05；MOD-QS（候选 master）拥有一份保持请求，产生实际 AXI，不负责证明 IP 内部 quiet；MOD-QL（独立账本/监控 owner）逐沿记录旧接受与期望，承担 DQ-03/04；MOD-QP 是只读复用的真实 C2 DDR；MOD-QM 是待匹配的 DRAM+公开 PHY/PLL 仿真适配；MOD-QR 汇总原始证据并保留未知，承担 DQ-05。自写部分均尚未生成。
路径：QC 配置 IF-QCFG→QS 请求 IF-QAXI→QP→IF-QPHY→QM；QP 的 R/B 与状态返回 QL→IF-QLOG→QR；QL 的容量/停发反馈 QS。应用 sr/ref/zq 不作为 close 确认。时钟/复位 IF-QCLK 由选定仿真适配驱动，QP 的 pll_shift/sel/ena 必须回到真实相移模型。
边界理由：case 期望独立于控制器返回，不绕过 controller 向模型写数据；仿真适配不重生成/修改保护 IP；只有一个物理 burst 在途是本卡新候选，不是已发现 IP 限制或旧 PB 契约自动生效。
组合检查：QS 可停发，QL 接收记录保有容量；AW/W 相互独立保持，不等待对端 READY 才首次置 VALID；响应背压有限释放，避免试验自身永久阻塞。QP 内部进度/校准/关闭无公开保证是阻塞，不用 host 时序代替。

## D. 接口、宽度与相容检查

| IF | 方向/类型/范围及交接保证 |
|---|---|
| QAXI AW/AR | QS→QP：各 VALID1、ID4、ADDR32、LEN8、SIZE3、BURST2、LOCK1/CACHE4/PROT3/QOS4；QP→QS各 READY1。本卡候选 ID0/SIZE4/INCR、LEN0 或 3；其他 sideband 固定值须冻结并核支持 |
| QAXI W | QS→QP DATA128/STRB16/LAST1/VALID1，QP→QS READY1；16B/beat，尾拍与接受计数相配；全部 unsigned |
| QAXI B/R | QP→QL BID4/BRESP2/BVALID1；RID4/RDATA128/RRESP2/RLAST1/RVALID1；QL→QP BREADY/RREADY 各1。响应编码的候选成功值 00 须核匹配支持，不能把端口存在当恒 OK |
| QCLK/状态 | QP 输入 axi/core/sdram/rx_cal/tx_cal/tx_cal_90edge/rstn；输出 pll_shift3/sel5/ena1、cal_done1、init_cur_state7/debug36；reset 低有效。公开端口无独立 health_fail/drained/fence/cancel/reset_ack/isolation_ack，状态/debug不证明复位排空 |
| QPHY | hi/lo 双沿 CK、DQ16、DQS2、DM2，DQ_OE16/DQS_OE2/OE_n2；ROW14/BA3、CS/CKE/ODT1 及命令；三态/相位/采样由合法适配实接，不只接抽象 RAM |
| QCFG/QLOG | 候选 host 记录 case_id32/op_seq64/session_generation64 非零、epoch64、方向1、addr32、LEN8/SIZE3/ID4、beat_index9、data128/strb16/resp2/last1、各握手和时间；op_seq=0 合法，不与非零 generation 混用 |

当前公开 macros：tCK2500ps/CK_RATIO4→SDRAM400MHz、core100MHz，CL6/CWL5、DRAM_WIDTH8、BL8、MEM_ADDR_ORDER BANK_ROW_COLUMN；这是输入事实，尚未核匹配实际器件时序。wrapper L43公开注释将DRAM_WIDTH解释为每DQS的DQ数，DQ16/DQS2=8，不能仅凭此8把总线改成x8；也不能从另一族示例的DRAM_WIDTH16推同义，Q-B02/03保留匹配前提。原 top 的 axi/core 接 core 时钟，ASYN_AXI_CLK=1 仍保留。C2 peri DDR3_PLL TR0 #0/#1/#2/#3 是 400MHz（#0 90°、动态0/2/3），#4 是 100MHz；core 实取 MIPI_TX_PLL TL0 #0，同频不同 PLL 不能默认同步。
候选有限 arena 为字节区间 [0,65536)，并非生产对象分配。地址 33bit 扩展后检查 end=addr+16×(LEN+1)；16B 对齐、end≤arena_tail，半开区间且不跨4KiB；非法新请求必须在 issue 前拒绝。行/bank 跨越的真实地址映射须由合法参数/模型证据冻结，不能仅凭 MEM_ADDR_ORDER 名称推算覆盖。
INIT 接口增量：DR713 length7/payload512 只能 1–64B；本卡候选分段清零取64B对齐 q4/LEN3，生成四拍全零/全STRB并具真实 exclusive BUILD/INIT 授权，逐个 B 后再下一段。生产 INIT 9,072,000B=567,000 beats=141,750 q4 bursts 是现 DDR 卡几何账，不要求本有限 arena 跑整帧；q128/q32 bulk INIT 不在此卡、不借 EXEC READ 许可写。
普通 RMW 与初始化次序沿真实原 owner：CLASS 只在 LOAD BUILD CLEAR 一次，CLO 承接完成 proof 不重清。单个 qualification 写读不替代生产 grant/rounded 范围/目录版本/journal/close 设计；D3/PB 原宽 body 和 pin 检查合同保持。
错误注入分层：DUT 真实响应始终原样监控；错 ID/RESP/LAST 的纯监控反例可未来在隔离 monitor 单测重放，不记作真实 IP 错误路径通过。cal_done 是输出，不强制其值；能否由公开 reset/时钟条件合法触发校准丢失须 Q-B05 先闭合。

## E. 中文逐沿草图、持有、取消与独立关闭

1. QC 先核全量字节/hash、保护使用条件和参数相容；候选状态 DISCOVER→FROZEN。Q0 在独立库 COMPILE→ELAB，失败保留日志并 BLOCKED，不能带 CSI 失败继续宣 DDR PASS。
2. Q1 进入 WAIT_CAL：真实 clocks/reset/phase 适配先工作，记录初始化状态与引脚；按各域已冻结的复位释放合同禁新普通请求。cal_done 真稳定条件未冻结前不进入 RUN；不直接写高 cal_done。
3. RUN 选一个合法 case，QS 先保存完整 AW/AR/W 及 sideband，QL 先保期望/容量。每采样沿以沿前 VALID&&READY 记接受；保持槽未接受不得换 payload。AW 与 W 可前后握手，QL 分别记账，不用单一“写已发”覆盖它们。
4. 写入期间 QL 对每个 W fire 递增实际计数；只末个已接受拍携 WLAST。B 无论是否当前要求 cancel/reset，都先按旧握手记录 BID/BRESP、旧 effects 状态；错 BID/重复或过早 B 为协议FAIL，正常期望case收到非成功RESP为case FAIL，不自动等价IP协议违约；写effects未明仍保Q，不能宣布已写可见或回滚成功。
5. B 真交付后才形成该 case 的读地址；读按实际 R fire 逐拍检查 RID/RESP/LAST/数据。stall 时 R/B 全 sideband 必须保持；尾拍零到达、早/晚/重复 LAST、额外 R、X/Z 都留错误。自身账本分开记录“接受”“返回”“比对”。
6. cancel 同沿先结算旧 AW/W/AR/R/B fire，再停止未发布新 case；已发布 VALID 保持/已接受 effects 继续履约，不能通过取消降低 READY 反向抹去旧 fire。若 reset 对真实端口的保持规则未定义，此路径为 UNKNOWN，不伪造完成。
7. 校准丢失/clock 故障/reset 进入 Q：停止新普通 issue，记录正在 held/部分写/等 B/等 R；独立 host 账本不因 DUT reset 清空。旧 generation、expecteds、已接受字节及未决响应保留；新校准成功也不自动释放旧债。
8. DRAIN 只证明 QS/QL 自身：没有待接受 held、已发地址均有相配终端响应、没有剩余拍/接收缓存、日志已封存且没有引用。app_ref_ack/sr_active/zq_ack、cal_done、一次读相同或观察窗口沉默，均不能证明 IP 绝无未来访问。
9. 若确有匹配的独立 no-future-effects/隔离确认合同，再冻结其观察和覆盖范围，才准把对应作用域 CLOSE→RETIRED；目前无该证据，Q3 close_result=UNKNOWN，依赖 pin/对象/epoch 不能归还复用。RETURN 及 STORE CLOSE_ACK 的生产先后仍由原 owner 保持，不由试验代签。
10. 有限正常集全部完成只输出 PASS_FINITE+覆盖清单；缺 case/模型/合法 fault stimulus 为 BLOCKED/NOT_COVERED，观测错误为 FAIL，未决 effects 为 UNKNOWN。与“生产成功服务上界已成立”是不同字段。

候选失败检测期限（待版本冻结）：校准10ms、单 burst1ms、单 case20ms、停止后观察10µs，均为仿真实验 watchdog，不是厂商保证、有效 QoS、无未来访问证明或算法帧时限。超时停止新发/保债/Q，不释放；有限期限未过只说明本次没有检测到该失败，不能推出未来最长服务时间。物理 CK/core 各记时间与沿号，host 截止不靠被停的 DUT 时钟计数。
不变量：一份 QS 保持槽/一个全局 issued burst/独立期望记录；范围检查先于地址 fire；B 不能单独删除未知 effects；完整 R 数量及 LAST 对齐；reset 后不复用旧身份。QL/QS 的记录成本是未来仿真 host/TB 状态，不据此声称生产 FPGA FF/RAM/DSP 或时序满足；存储格式、日志容量和最终文件路径尚待冻结。

## F. RTL A–L、软件与跨语言

| §8.2 | 本卡契约或明确未知 |
|---|---|
| A 数值 | unsigned端口见D；33bit地址末端、9bit拍号；禁止LEN加一在8bit内回绕；无定点/浮点数值算法 |
| B 时钟/观察 | AXI采样沿与PHY双沿分开；观察于采样提交后稳定阶段；相位、TCQ及模型分辨率必须冻结 |
| C 接受/交付 | 五通道各 VALID&&READY；B/R对应完整旧账；QS可暂停，QL必须先留记录容量 |
| D valid/推进 | valid0不记拍也不当零数据；onlyfire推进；冷数据/日志存在不等于普通授权 |
| E 反压/保持 | QS持有到握手，QP响应停顿需保持；预定有限反压释放，不制造自锁后误判IP |
| F 延迟/吞吐 | 只记录真实沿间距/等待；暂无最大合法服务/校准上界，watchdog不是成功延迟承诺 |
| G 复位 | rstn低；各域释放和旧响应合同OPEN，独立账不被DUTreset抹掉 |
| H 配置 | 全配置先冻结、case期间稳定；相移更新是真PLL反馈，不静态替代；保ASYN1 |
| I 存储 | 匹配2Gb/x16几何要求ROW14/COL10/BANK3；4096Mb模型不换标签；访问arena及尾部边界独立核 |
| J 身份 | case/op/session/epoch与ID完整；ID0合法，generation非零；无图像坐标/frame变换 |
| K CDC | 不同PLL同频不视同步；PHY/DUT/host边界与复位分别核；不把SDC例外作功能证据 |
| L 实现 | 未来Questa合法展开和公开模型仿真；无本轮RTL/工程/约束/EDA，资源及生产STA不在资格判定 |

C++ N/A：本卡无 C++ 模型或 RTL 算法映射；未来 host/TB 实现语言/工具先冻结，不能借 N/A 隐藏日志/期望检查。共同数值契约为 AXI 字节/拍/地址及模式期望，WSTRB lane 与DATA byte 的实际映射需冻结验证。硬件执行契约为 D/E 的真实握手及PHY双沿；软件结果只与真实返回 R 比对，reset 作废记录和未决 effects 不混同。纯监控反例的结果单独归类，不参与真实控制器功能 PASS。

## G. 未来实施与有限验证计划（全部 NOT_RUN）

实施先选阶段并重新冻结/批准：Q0 的独立库/展开入口→Q1 匹配模型/PHY/clockreset 适配→Q2 master/独立expected/日志→Q3异常和关闭资格。新源码/TB/功能脚本/参数适配/报告路径及工具完整清单待 Q-B01/Q-B06 填定，不在本轮生成；任何 protected key/缺include/参数不匹配即停止对应阶段。

| TEST | 目标/输入与事件 | 期望、观察和覆盖限制 |
|---|---|---|
| QQ-01 | Q0 13 .v+params+SDP+原语独立编译 | 每个模块/依赖真实记录；不包含CSI；失败保原日志 |
| QQ-02 | Q0 合法展开真实ddr3_top | 精确参数/层级/未解引用；编译成功不代替展开，禁解密/重生成 |
| QQ-03 | Q1 器件/模型/时序逐项对照 | 2Gb/x16/速度等级/include全部匹配；缺2048Mb头BLOCKED |
| QQ-04 | Q1 公开PHY/OE/动态phase/CKratio4初始化 | 400/100MHz和复位接线、真cal_done、模型违例全记录；不能force成功 |
| QQ-05 | Q2 LEN0/LEN3，地址0/16/4032/4096 | 各写后B→读，16/64B逐byte相等；walking bit/非零模式及全STRB固定向量待冻结 |
| QQ-06 | Q2 4KiB/arena尾：0xFF0的32B、0xFFF0的16B、越界 | 32B拆两LEN0；尾16B合法；越界/不对齐新请求issue前拒绝，未对DUT发非法burst |
| QQ-07 | Q2 AW/W先后、W/R/B各0/1/7/31拍背压 | 全sideband稳定、数量/ID/LAST正确；QP自然READY停顿也记录；预定释放后才能判超时 |
| QQ-08 | Q2 分段INIT：已授权64B×有限arena | 每段q4四拍0/STRB全1/B后读；不变更DR上限、不替代整帧初始化性能 |
| QQ-09 | Q2 错ID/RESP/LAST/重复/X/Z反例 | 隔离monitor单测检测FAIL；真实DUT输出仍原样核，不宣IP错误返回路径已覆盖 |
| QQ-10 | Q3 cancel沿同时W/R/B fire及各部分写状态 | 先旧fire后停新发；完整旧expected/effects保留，held不悄然消失 |
| QQ-11 | Q3 公开reset/合法clock条件、在途与空闲 | 旧债不清、未决Q；不能合法触发的cal-loss标NOT_COVERED，monitor回放不冒充DUT |
| QQ-12 | Q3 自身quiet、观察期后额外响应/访问、未知close | 自身quiet条件逐项实查；无独立nofuture合同则UNKNOWN，无pin/对象释放证书 |
| QQ-13 | Q0–Q3 hash漂移/超时/缺结果与报告复核 | 原日志和旧失败保留；NOT_RUN/BLOCKED/FAIL/UNKNOWN/PASS_FINITE不混写 |

有限case顺序/实际数量、向量内容、所有byte mask模式、bank/row映射、反压作用对象、时间单位/种子（确定集无随机种子）、预期状态、watchdog最终值及合法fault输入，必须在新冻结基线明列。任一缺失不满足READY；不要求未批准前先跑图/TB/EDA获得PASS。

## H. 双向追踪（计划文件/符号尚未生成）

| REQ/来源 | MOD / IF / 草图 | 计划单元与 TEST | 实际代码/证据 |
|---|---|---|---|
| DQ-01；A1/A2 C2与编译日志 | QC/QP；QCFG；E1 | independent_compile/elaborate候选；QQ01–02 | 只读原文件；新单元无，NOT_RUN |
| DQ-02；wrapper/macros/peri、匹配请求 | QM/QP；QCLK/QPHY；E2 | phy_clock_model_adapter候选；QQ03–04/11 | 匹配模型及合法适配缺，NOT_RUN |
| DQ-03；公开五通道与DDR/DR边界 | QS/QL；QAXI；E3–5 | bounded_master/byte_expected/axi_monitor候选；QQ05–09 | 旧axi_ram例子不充当证据，新单元无 |
| DQ-04；B04未知与原owner终端要求 | QL；QLOG/QCLK；E6–9 | effect_ledger/quiet_audit候选；QQ10–12 | 真实独立close合同缺；UNKNOWN设计分支，非已执行 |
| DQ-05；规范/审批/本卡 | QR/QC；QLOG/QCFG；E10 | qualification_report候选；QQ13 | 只有本卡，未冻结/未实现/未运行 |

反向核对：每个候选单元只承担表中REQ；不引入算法、生产接口变化、免费复制引擎或资源结论。后续为每个真实新文件/稳定符号回填所属REQ/IF/TEST/hash后才能冻结批准。

## I. §10.3 门槛与停止点

①整体行为/正常边界已在B；②职责/复用调查C/A1；③接口/组合D但B03–05未闭合；④状态/中文草图E；⑤语言F；⑥走查B/D/E/G仍缺真实fault/close保证；⑦未来实施/验证/追踪G/H尚缺冻结文件/套件；⑧存在B01–06，不能通过；⑨仅本卡保存/全文读回及根审阅交接，读回hash外置交接；⑩版本v0.1明确但实施范围/工具/输入基线尚未冻结。结论 NOT_READY，不能写READY_FOR_REVIEW。
本卡未获用户批准、未登记新的 Approval Manifest/DB审批。停止点是根只读审阅、补齐上述资格依赖并形成可冻结版本；未来指定批准后才准生成相应源码/TB/功能脚本及执行。现在不提出重复模型申请或用户批准问题。

## J. 变更、恢复与来源边界

新增资格设计，不修改旧C2/算法/生产卡/R1/交付入口。恢复须核本卡、源hash、合法保护展开、匹配模型、审批与审计；任一输入漂移使用新基线/run，保留旧失败，禁止将当前资料当历史冻结一致。未证明成功服务上界前DDR服务μ/M/β及全机deadline保持OPEN。
关联算法来源（均控制面相对路径）：planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md SHA EE8BB3CDD9D33699ED85CF1A0E7433439993D1F07C21714650BAC64B17F9E4EF，读L40–66及336/340/391/393；PRODUCTION-BUFFER-001.md SHA 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40，读L70–83及历史68–122；DDR-SERVICE-BUDGET-001.md SHA 93C1E563F692A3C7E74020B436234B0481BD086CA4E9C6817849DED31A43A8B9，读L228–246及历史226–256；INTEGRATION-001.md SHA C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF，读L59–67及历史119–143。除首项外均同planning/design-TRACK4-ALGORITHM-前缀；是候选合同来源，不是批准的真实DDR行为。
experiments/track4_algorithms_20261004/03_review/canny-closure-implementation-gap-review-v0.1.md SHA 8A90E72661E94821CEFB8D77B0F3D1FB70D3468223092E5486D58A9BC7E48CAA，历史全读L1–174、本轮有限L39–48；旧L45 wrapper范围只到155，新调查公开到192补状态，不修改该历史报告。

## K. 实录与保护边界诊断

本轮操作只读调查/静态接口核对及保存本设计卡；实际修改仅此文件。没有新独立编译/展开/DDR仿真/EDA/功能脚本执行/模型修改/下载/硬件/DB；Q0–Q3均NOT_RUN。历史vlog DDR模块列表是来源事实，整个C2命令终止于CSI错误，不能改写为DDR功能PASS或DDR失败。
一次诊断事实：先前只识别begin_protected的头扫描漏掉旧式 protected 边界，EI/source_modelsim/efx_ddr3_axi.v（SHA256 6808E855960ADBF62AFD37F66410B3A06E911D8E145C5C11041471BBD072187B）L2–4为pragma/legacy保护标记，首156行读取意外输出L6–156密文字节。未解密、未解释、未采用该保护实现；已停止，不再次输出密文。后续边界检查同时识别两类保护标记；本卡不声称从未读过保护行。

## L. 交付与剩余限制

完成的是Q0–Q3的有限设计、来源/缺口、中文操作次序及追踪。真实可执行套件、匹配模型/PHY适配、资格成功合同和阶段审批未完成；软件资格也不代签人工下载/观察。按A→B/C→D/E→F/G/H→I阅读，任何需求变更回到相应REQ/IF/TEST再冻结；源注释、代码、测试一致性待实际实现后复核，用户理解验收待实际作答。
本卡由根Agent独立读回/评审；保存后的实际行数/字节/SHA256在交接中报告，不把自身hash循环嵌入正文。没有满足wholefit、吞吐、时序、稳定显示或复杂识别准确率的新增证据。
