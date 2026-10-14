# C2 时钟/net 与 Questa 无 TB 范围复核

- 报告日期：2026-10-04；版本 v0.1。
- 性质：既有输入的只读证据与批准范围核对，不是新业务设计、工具运行实录或整机验收。
- 当前结论：C2 外部 CSI byte clock 为 **CLOCK_UNRESOLVED**；有限 Questa compile/elaborate 流程有明确输入与范围。本报告不预判正在执行的编译/展开 PASS。
- 本复核者仅创建本报告；没有修改 RTL、XML、peri、SDC、IP、头文件、原资料、正式状态、数据库或测试，没有执行 Efinity/Questa 构建、仿真、设备或网络操作。
- 阅读顺序：§1批准和输入 → §2整体时钟来源 → §3局部 net/复位 → §4停止条件 → §5无 TB 工具范围 → §6 C0 输入修订 → §7结论与追踪。

## 1. 批准与实际输入绑定

已实际读取控制面入口、config/AGENTS.md、运行提示、路径配置、正式状态/任务台账、数据库说明、唯一规范 v0.2、PLAN_TEMPLATE，以及以下批准原字节记录。此报告为审阅证据，不申请新设计批准。正式硬件基线/数据库状态未改变；本次软件预检按已获批的限定本地审计例外执行。用户已允许板卡现有 DDR3；这不是业务算法实现批准。

| 对象 | SHA256 | 字节 |
|---|---|---:|
| [批准设计 v1](approved-design-v1.md) | 130481D499D68F4F2F43C6C6731D0E088E4333D4B701C22E1E37C2CCD65BD2E8 | 16977 |
| [v1 批准记录](approval-v1.md) | 251D54517620D14C54A2FF63C66B8A8E16FBFDA353AF54DEAED6C51350FA7992 | 2099 |
| [批准输入修订 v1.1](approved-design-v1.1.md) | 07EA95A4E266DF270835827800546C5B71FF305D9EA0CF3953881A59807790CC | 6425 |
| [v1.1 批准记录](approval-v1.1.md) | FD923033C873DED096809A73BB1670B7C4DD955C5D021B1D0EECE7A50DC0BB21 | 1158 |

v1 绑定 IP-PRECHECK-BL-v1 的 89 输入，manifest SHA256 `1B336732334C4453FEA720351FF45910B0D9367B1089C4A89713815CCE790DC3`。v1.1 仅补两份原 I²C 头文件，91 输入 manifest SHA256 `2333F4B42836EDC58B7F8083D0044542BFF8D2C9D375698F9A609C0C1A144AEC`。批准记录明确不包含算法、protected IP 升级/重生成、新 TB/激励、bit/hex 或硬件动作。

下表的相对路径均相对实际 C2 work 根：
`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_ip_precheck_20261004\C2`。

| 实际输入 | SHA256 | 字节 |
|---|---|---:|
| ti60f225_oob.xml | D67BFF492FDE948FDA71B8A9905218B6A5A07E7CA6BFA278CB266E0140299DE8 | 14250 |
| ti60f225_oob.peri.xml | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B | 75065 |
| ti60f225_oob.sdc | 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF | 41630 |
| rtl/ti60f225_oob_top.v | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 | 35587 |
| rtl/csi_rx_controller.sv | 685D96FD52A604434A1DA0BB404131CD4413BF76ED8EE738AC596B32CE373E5A | 508269 |
| ip/csi_rx_controller/settings.json | 21ACE23896A1D40671C9FE7C2510AB82B6A126AFF0C7BC81859EDD41D6607E1B | 1230 |
| debug_top.v（case 根，非 rtl 子目录） | 81C1402E39E460E4BF81723534176D2D0F2EFA35BA57CC9366F75155DDA4ED6C | 425643 |

XML 在 root 准备工具输入时从早读版本发生格式变化，本报告绑定表中的实际末次版本；peri/SDC/top/CSI/settings 的本次读前后 hash 保持一致。此绑定不是宣称所有未来 work 文件已冻结或正式源基线全部完成。

## 2. 整体时钟来源与可证有限纠正

| 来源与实际输出 | peri 位置 | 当前 SDC 位置及名义周期 | 静态证据所能支持的结论 |
|---|---|---|---|
| CLK_25M 外部参考输入 | 85、320、349、363 | 86：仍为 `<USER_PERIOD>` | top:63 确有 CLK_25M；25MHz 对应 40.000ns，是有直接来源的有限更正。实际 PT 后仍须证明 constraint 对象命中。 |
| DDR3_PLL，25MHz参考，#0/#1/#2/#3，divider8 | 320–331 | 6–9：各2.500ns | 四个 DDR/校准时钟名义400MHz；#0/#2/#3有动态相位属性，不能凭名称或静态 phase0 推断实际固定相位。 |
| DDR3_PLL #4 clk_100m，divider32，rclk | 332 | 10：10.000ns | 该物理输出名义100MHz，不能据此认定现有业务 core_clk 使用了它。 |
| USER_PLL，27MHz参考，feedback fb；vid/slow/fb/fast输出 | 335–346 | 11–14：13.468/6.734/18.519/1.347ns | 名义74.25/148.5/54/742.5MHz；现有周期与源关系一致，未发现可凭本次静态读取再调低频率的依据。 |
| MIPI_TX_PLL，25MHz参考，core/txc/txd/pclk输出 | 349–360 | 15–18：10/2/2/8ns | 名义100/500/500/125MHz；core_clk 是此 PLL 的#0 gclk，和 DDR3_PLL #4 为不同输出/net。 |
| pll_inst4，25MHz参考，pixel/CLK_5M输出 | 363–372 | 19–20：20/200ns | 名义50/5MHz；仍需 PT 工具确认生成时钟和实际对象，不等于软件/实机测频完成。 |
| 摄像头 DPHY clock-lane CLKOUT | 526–544 | 23：10.000ns | 外部 CSI byte clock，不能由本地 PLL 或 CSI 参数证明实际100MHz；这是关键 CLOCK_UNRESOLVED。 |

这里的频率是静态配置及当前 SDC 的对应关系，不是本轮 PT/STA 或设备测量结果。局部 PLL 关系可定位，不能用这一表宣称完整时序覆盖通过。

CLK_27M 在 peri:88/335 有27MHz参考来源，数值周期可算为约37.037ns；fabric top 的时钟端口表:57–71没有同名 CLK_27M。因此在 PT 外围范围未确定前，不能擅加一个无法命中的 fabric `get_ports CLK_27M`。JTAG TCK 也不能仅凭内部 debug 逻辑创造外部工作频率。

## 3. 局部 net、CSI 参数和复位事实

### 3.1 同频率不等于同一个 net

top:370 为 `i_mipi_clk = core_clk`，CSI:383 的 `.clk` 使用这条 core net；DDR top:621、622 的 axi_clk 与 core_clk 也都连接 core_clk。peri:349–357 证明 core_clk 来自 MIPI_TX_PLL，而 DDR3_PLL:332 的固定#4另名 clk_100m。

因此 C2 当前的 axi/core 为同一条业务 core net，但该 net 与 DDR PLL 的100MHz固定输出不同。把名字或 SDC 频率改成相同不能完成实际时钟迁移。将业务 core 改接 DDR #4、ASYN_AXI_CLK 改为0、rclk 改为工具支持的 gclk，是批准设计:62/64/70规定的 C1/C3 组合 delta，不是 C2 单纯 clock 声明纠正。400MHz校准路径必须保留。

### 3.2 byte clock 与 core clock 分开

实际交接为：

1. 摄像头外部 clock lane 进入 peri:526–527 的 cam_ck DPHY。
2. peri:544 生成 `i_cam_ck_CLKOUT`。
3. top:385 把该信号接到 CSI 的 `clk_byte_HS`。
4. top:383 的 CSI `clk` 则由本地 core_clk 提供；top:387 的 `clk_pixel` 又是 i_mipi_rx_pclk。

真实 CSI 源头部为 IP5.15，参数:152 `HS_BYTECLK_MHZ=70`，:153 `CLOCK_FREQ_MHZ=100`，:155 FIFO1024，:148/149 settle85/prepare145。100对应core配置，不是摄像头 byte clock 的实测证书；70也是IP生成参数，不能把当前 SDC:23 的外部100MHz约束直接替换成70MHz。

旁置 settings.json:12 是5.16，:20/21为125/155，:24为HS_BYTE50，:25 core100，:27 FIFO2048。这与实际被引用源不同。当前 XML:55 引用 rtl/csi_rx_controller.sv，:85 ip_info为空。不得用旁置 settings 重生成当前 DUT 或填补外部频率未知。

### 3.3 复位只记录现状

top:338 用 i_pll_locked、pll_locked、user_pll_locked 与合成 w_arstn；:339–342 将原 PLL reset 输出绑定 i_arstn；reset_ctrl:352–354 在 i_mipi_rx_pclk 域产生既有两份输出；CSI:382/384 使用 i_arstn，pixel:386使用既有像素域释放；DDR:627 使用 w_arstn。pll_inst4 在 peri:363 的 reset_name/locked_name为空，而 top有同名声明，不能靠声明认定实际连接已建立。

本报告不增加锁定信号、修改 reset/CDC、重写释放协议或宣称这些现状已功能验证。若未来阶段提出必要变化，按批准 delta 或新设计修订记录，不能隐含在“修 SDC”中。

## 4. CLOCK_UNRESOLVED 与依赖停止条件

批准设计 v1:76 明确禁止用 HS_BYTECLK_MHZ70直接将外部byte100改70。当前只读资料没有补足该外部频率证据，故：

- C2.original 的原样 compile/synth 和无激励 DUT 编译/展开可独立留存真实终态及输入 hash。
- C2.clock-corrected 必须重新冻结本 case 输入并重新执行所需阶段，不能混用旧 map 与新 SDC。
- 外部 byte 频率未定时，C2.clock-corrected 的 PT/PNR/STA 与依赖 C3 保持 CLOCK_UNRESOLVED、未执行/依赖停止，不伪补相邻时钟约束凑成功。
- 需要的下一份证据是与实际相机模式/寄存器配置、DPHY实现及工程版本相容的 byte clock 来源或可审查工具证明；当前硬件未到，不能写成实测值。
- SDC:25–27 的 broad `set_clock_groups -exclusive` 不能直接作为完整 CDC/时序闭合证据。真实同PLL关系、400MHz动态校准、约束对象和未约束路径必须在获准 PT/STA 记录中核对，不能通过删除路径或虚假异步例外宣称 PASS。

这不是新增审批流程；是已获批设计:66/70/72/76 的原停止条件。C0 baseline失败也使 C1不能继续推断资源差额。protected IP 必须自动升级/重生成时，按原设计停止为 AUTO_IP_REGEN_REQUIRED。

## 5. 本地 Questa compile/elaborate-only 的明确范围

### 5.1 既有输入与厂商模型

已只读确认工具位于 `C:\Users\34528\FPGAEdgeLinks\Questa2024_1\win64`，存在 vlib、vmap、vlog、vopt、vsim。批准范围只使用前四者完成独立库、编译和展开；本复核者没有调用这些工具。root 正按已批准步骤执行，其真实终态由 root 后补总报告，不能由本报告预判。

当前实际厂商行为模型根为
`C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\sim_models\verilog`，平面目录共 **15份 .v**。对明文部分已检查 module/include/import，未见另加 include/import 依赖；protected 内部最小原语集合不能通过静态读取保证，使用全部既有15份为保守覆盖，不自造替身。

| 实际模型文件 | SHA256 | 字节 |
|---|---|---:|
| efx_add.v | E38D1292EC8A93C83F9DAAC0430F223B8B9AC2FD870F3752628E9749E5C72F6D | 3791 |
| efx_comb4.v | 4B22A3FCADED5D83FE4A856277D68493BA52698E6AD2DA8C3B5EF0FF410C8575 | 5838 |
| efx_dpram_5k.v | 5C0B82680FC876C0D52E5C45879A297F4102C7CECA9DA40E1E678E1B369CBDF9 | 15659 |
| efx_dpram10.v | C7E39233DE0A437FD0D43D83CE60DCE10B3BD305C59CFCACFB5EAC2FE916BCF9 | 22727 |
| efx_dsp12.v | CD016828EB5359DC5E102B1F4B5B4AF96A44081B14D96D29A3E25D47600BC6CD | 12365 |
| efx_dsp24.v | 3594EE58D049B9FAE2C0CD54A8A7924FC1104265620C6E078C8E32EE36B7771B | 12366 |
| efx_dsp48.v | 551E13EFAC2D55CD532097BB28BF50063848AF637F62409890962216C1F5A581 | 53532 |
| efx_ff.v | AABAE51AEB95C17D8E5AF262FE5AA21AC7C4FB432C7CBD6991EDE0073F2BDEE7 | 4963 |
| efx_gbufce.v | 06140A276FB1B8449238A0D8D983E7243F5269FCE98EBC0E4B99B424FE18B6CD | 3543 |
| efx_lut4.v | 49F8494172AB8FF1BE8F9A487015451E924CFF911AB36CFCEFE2555FBB06586E | 4892 |
| efx_mult.v | 29455260F7B3627EF75C2916B0902881FF2BB49EEF833038439BE114A02D8392 | 7941 |
| efx_ram_10k.v | 603959E997F1863ED85A5A603BA87659577D585B0540D586E4662B6B123A8BE5 | 14109 |
| efx_ram_5k.v | C014F7ADB3056CE6B94C02B8AAD4E6CF19B011ABE845A5C525F7CCE4B70370F7 | 11587 |
| efx_ram10.v | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 | 17913 |
| efx_srl8.v | 9B2BC5BAC291EEB983149D95AC69E3CC3DA761758CB4F5F116DA6661CB9C3233 | 3969 |

直接可见原语例如 C2 debug_top.v:51 的 EFX_GBUFCE；行为模型 efx_gbufce.v:17 为模块声明，:45/48有行为/输出。不能使用 `sim_models/maplib/efinix_maplib.v` 代替行为模型：该文件 SHA256 `70529D062DA73013F651CCCA4DE83351C0195D3197CD13968D8BD1BB1AD1A715`，41675B；:1–3明确称 synthesis cell library，:8–14的 EFX_ADD 只有端口/参数与空 endmodule。这类空声明可能使“无未知模块”看似成功，却未证明真实行为模型展开。

### 5.2 中文操作顺序（流程说明，不是新脚本或运行结果）

1. 使用本 case 的 ASCII Work别名目录、独立 Questa输出库和本地 modelsim.ini；不沿用其他case的编译库。vmap -c或等效官方本地复制只形成该case局部映射，不修改用户全局 modelsim.ini。
2. 用 vlib创建 work/efinix 两库，并把本地映射指向实际库。先以 vlog编译表中15份行为模型到 efinix，保留完整退出码/日志。
3. 按实际 XML design_file 顺序编译 .v/.sv；.vh为预处理 include，不作为有独立实现体的 DUT 编译。C2当前 XML共60项，其中:53引用case根 debug_top.v、:55引用实际 CSI。不递归编译整棵 rtl，从而避免混入旧 TB、soc_oob、旁置DSI、重复debayer RAM或不同版本模块。
4. C0 XML共66项，并另有 IP_INFO:86–90 的 ip/csi_rx_controller/csi_rx_controller.sv与ip/dsi_tx/dsi_tx.sv；保留两份实际IP源。C0 XML hash为 `571E5A03A7CCC46D2B15CF9D3DCAAA1BC1A874CB3E0908330599891457867BE8`。C2的ip_info为空，不添加旁置IP重定义。
5. vlog使用既有 SystemVerilog编译选项、独立work库与真实 include目录，至少 case/rtl、rtl/ddr3_controller、rtl/cam_i2c_ctrl/i2c_master；C0另加两个active IP目录。保留源码编译单元边界，不添加未经批准的 -mfcu、宏替代、protect解密、module stub或error suppress，也不删除debug。语言/key兼容有错误便保留错误，不改源码强行通过。
6. DUT编译成功后，用独立 vopt 对 work.ti60f225_oob_top 展开，并以 -L efinix 查找厂商行为模型，保存case专属输出名。将 vlog与vopt的结果分别登记；一个成功不能替代另一个。
7. 本范围不调用 vsim、不执行 run、不建立TB、不提供clock/reset/图像/协议激励，不使用4Gb器件模型运行2Gb校准。其结果只能是现有 DUT编译/展开兼容证据，不能称 Canny/识别、DDR读写、复位、帧率、时序或实机已验证。

root 可按批准工具阶段使用现有命令；这里不是可执行功能性runner的创建，也没有将命令执行结果写成通过。源码中的 $readmemh/$readmemb及其原资产应保留输入证据；compile/elaborate没有进行 time-step激励，不足以证明初始化或器件功能正确。

### 5.3 C0 PT 生成依赖与物理模拟边界

本次检查 C0已有 outflow err/info/log/map.out/warn，没有已生成可引用的 PT物理 interface/simulation wrapper；原 efx_fifo_wrapper.v 是冻结RTL本身，不是本轮PT产物。C2已有 root产生的map/elab文件也不能被改名当PT物理wrapper。

现有 fabric top把PLL输出、DPHY和其他外围信号作为端口接入，因此其RTL DUT编译/展开不要求凭空创建一个 physical wrapper。当前流程覆盖实际fabric DUT及其厂商行为原语。若将来必须展开PT物理wrapper，只能先按批准正常官方PT阶段生成，再实际核其实例及版本，选用安装目录 `pt/sim_models/verilog` 中对应的 PLL_V1/V2/V3、MIPI_RX_CLK_LN/MIPI_RX_LN、GPIO/JTAG等模型；不能凭名称猜版本、将空perilib声明代替真实行为模型、手造wrapper或把此项写成已完成。

Questa当前key可接受性由真实工具决定。保护包中的Mentor key标记或历史局部IP日志不等于本轮所有现有DUT均展开成功；未知/缺依赖/工具拒绝按原预检范围报告。

## 6. C0 attempt1、v1.1 与 attempt2 的正确区分

早期只读反馈曾报告C0两头文件缺失；这仅适用于原89输入的 **attempt1**。目前已获 v1.1批准并补入原字节，实际只读核对如下，不能继续称“当前两头文件缺失”：

| 当前 C0 已存在的原头文件 | SHA256 | 字节 |
|---|---|---:|
| rtl/cam_i2c_ctrl/i2c_master/timescale.v | D98DD66323E809EE4BC88896063327802CA13241B5742A5E25DB17DB17A40A4C | 813 |
| rtl/cam_i2c_ctrl/i2c_master/i2c_master_defines.v | B6DCF92C66C3DC80192206621E732F0474709579662EE09943E48DB0077F302E | 4071 |

三个既有公开I²C源活动 include位置分别为 byte_ctrl:83/86、top:87/90、bit_ctrl:141/144。attempt1日志已保存在 C0-attempt1-logs；后续新增两个原文件的批准、91输入hash检查见approval-v1.1及C0-attempt2-input-check.json。这里不改原源码或宏值。

**attempt2** 的独立控制台 [C0-attempt2-map-console.log](C0-attempt2-map-console.log) SHA256 `97CF4AD80C97D928E990961EB74C8752D33BE3B9F3C6A1CD432F0855304D6294`，947B，实际末尾 map:FAIL。当前 C0/outflow/ti60f225_oob.err.log为追加记录：早先17:33段仍有两头文件错误，17:39:04的新段仅出现 `Panel_1080p_reg.mem` 无法打开和top展开失败，位置为 true_dual_port_ram.v:52（当前完整err.log:36–37）。不能把旧段错误当作头文件仍未恢复。

此次新增阻塞应记为 attempt2 的原初始化资产缺口，不是 protected DDR controller/PHY不可综合的证据。Panel恢复是否纳入新的批准输入修订由root按既有流程处理，本报告没有复制、补造或修改它。C0失败不能直接运行C1去承诺资源节省。后续成功也不得覆盖attempt1/attempt2失败实录。

## 7. 有限结论、未完成项与追踪

| 审阅问题 | 实际证据位置 | 结论/后续边界 |
|---|---|---|
| IP-REQ01/IF01：可恢复输入闭包 | §1、§6；批准v1.1；C0头文件与attempt2资产错误 | 当前两header已补；Panel仍阻塞attempt2，不能伪称C0已成功。 |
| IP-REQ02/CASE：C2实际源版本 | §1、§3.2；XML:55/85，CSI:152/155，settings:12/24/27 | 实际5.15与旁置5.16不同，保持实际源，不重生成IP。 |
| IP-REQ03/clock：net/频率证据 | §2–4；top:370/385/621–627，peri:320–372/544，SDC:23/86 | 25MHz占位可证有限纠正；外部byte仍CLOCK_UNRESOLVED；原停止条件有效。 |
| IP-REQ04/工具兼容：现有DUT编译/展开 | §5；批准设计:78；真实15个行为模型 | 流程明确，无TB/激励；root实际工具结果另补，不预判PASS。 |
| IP-REQ05/06：失败与范围诚实记录 | §4、§6，批准设计:66/72/74/76 | 失败分attempt保留，不以旧map/新SDC、空原语、旁置IP或未运行分支补缺。 |
| 整机映射/算法/生产IO/硬件验收 | 本报告范围之外；唯一规范与原批准边界 | 未因局部审阅而关闭，不宣布十一项、全生产系统或整包READY。 |

已完成的是源/版本/hash及现有时钟关系的只读复核、无TB工具范围的文字整理，以及本报告保存读回。未完成的是root正在执行阶段的最终归档、外部byte频率证明、clock-corrected/PT/PNR/STA和依赖C3的合法继续条件、C0 Panel闭包、所有算法功能仿真/资源/时序及实机验收。本报告保存后停止编辑，由root把真实工具终态补入独立总报告，不将本报告不断改写为运行日志。

