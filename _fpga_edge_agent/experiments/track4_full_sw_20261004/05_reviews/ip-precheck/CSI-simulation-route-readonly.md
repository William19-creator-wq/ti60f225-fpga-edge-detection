# CSI 仿真路线只读证据

2026-10-04；v0.1；**READONLY_EVIDENCE / NOT_AN_APPROVAL / NO_NEW_COMPILE / NO_FUNCTIONAL_SIMULATION**。本报告只为完善后续验证计划提供现有合法输入与工具产物证据。v1.3尚未批准，未修改其卡/基线、当前work、原HDK、源码、配置或正式状态，未执行vlog/vopt/vsim/TB、解密、保护体修改、下载/安装或IP重生成。报告是本轮唯一新增文件。

可以改变下一行动的结论是：**已有C0官方debug合并网表是一个不含加密包装、可见实例均有现装行为模型定义的门级编译候选；本机也已有与C2实际5.15同版本的官方ModelSim专用CSI源，但仍需参数/依赖/兼容性核对。** 这不是当前DUT编译或功能仿真PASS。C0/C2基础map仍含保护包，不能将“map成功”泛化为“网表均无密文”。

## 1. 来源与现有失败事实

以下简名定义真实已读路径：

- `W` = `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_ip_precheck_20261004`。
- `E` = `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1`，LOCAL_TOOL_PATHS记录其为现装Efinity2026.1.132的junction；没有切换或安装工具。
- `H` = `D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4\10_Ti60f225_sc431hai2hdmi_demo\Ti60f225_sc431hai2hdmi_v1`。原HDK只读。
- `R` = 本报告所在`05_reviews/ip-precheck`目录。

| 实际对象 | bytes / SHA256 | 事实位置与范围 |
|---|---|---|
| W/C0/ip/csi_rx_controller/csi_rx_controller.sv | 462418 / B1B0DFBB2CD432D580FFC09D6CA49F85854BFDF6EE89C1A96905F14FCA76BC43 | 实际C0 CSI5.6；20保护块、20个key_keyowner，全部Efinix Inc./EFX_K01；首key372、原vlog失败385。 |
| W/C2/rtl/csi_rx_controller.sv | 508269 / 685D96FD52A604434A1DA0BB404131CD4413BF76ED8EE738AC596B32CE373E5A | XML55真实引用CSI5.15，ip_info85为空；不是旁置ip目录5.16。 |
| R/C0-questa-DUT-vlog.log | 11925 / 108B6E3BAE8821121623CF1CE8AFF2C029131E37026DCE5094FF29F6D465BF74 | 88/89/91行：CSI385无key、保护区语法及后续scope错误；93行3errors。DSI未到达，vopt未运行。 |
| R/C2-questa-DUT-vlog.log | 10904 / E96838F68E478EAAC83B8DB17E149FE8CAD2EC00ADCC2FA2A1F727EE6B43849B | 78/79/81行：真正CSI459无key及保护区错误；83行3errors，vopt未运行。 |
| R/C0-questa-inputs.json | 66352 / 0CA03729F7A2C9C7CFA419E9CB91022FC9AD009BB7E0EC428116C2E606C6BB83 | 原实际15厂商行为模型清单；本轮重新读15份bytes/hash均匹配，不添加替身。 |
| R/C0-questa-vendor-vlog.log | 2956 / 5A163A1A92D5305F670DD183E40F61EA8AD85A140650DA8424BFFC5BC25D639C | 原实际15份行为模型编译exit0；末尾Errors0/Warnings0，时间18:05:56；不是本轮新compile。 |
| R/RUN_REPORT.md | 9659 / 0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA | 13/14/36/73行记录C0 map、官方debug生成/合并、PT实际成功及PNR失败；旧结果不是v1.3结果。 |

C2原实际CSI的20保护块有25个recipient标记：首块280–434的284行Efinix、294行Cadence、304行Synopsys、311行Aldec、321行Siemens `SIEMENS-VERIF-SIM-RSA-2`、331行Mentor `MGC-VERIF-SIM-RSA-2`；443起其余19块所见recipient仅Efinix。**不能说C2所有key_owner仅Efinix；实际失败459属于后续仅Efinix块。** encrypt_agent写QuestaSim2023.4只标加密生成工具，不保证每个块向Questa提供recipient。

## 2. 已存在的CSI simulator专用源

### 2.1 同版本C2候选是实际存在的官方文件

`E/ipm/ip/efx_csi2/efx_csi2_rx/ipm/ip_component.xml`为111911B，SHA256 `3E6E66D131BFB30C3F6682A0D43B257080BC0D000967D2F36A96518E9EC1C56A`；6行版本5.15，与C2实际源一致。1150–1151行的官方fileSet名为`external_testbench_modelsim`、显示名`Testbench/modelsim`，共28依赖项；1214/1219/1224行分别指向`../../source_modelsim/efx_csi2_rx_top.sv`、`efx_csi2_rx_csr.sv`和`efx_csi2_rx.sv`。它确实是安装包已有来源，不能声称本机没有CSI仿真专用模型。

`E/ipm/ip/efx_csi2/source_modelsim`实际有27份SV，其中25份使用legacy MTI保护格式；只有rx/tx两个wrapper未见保护标记。因此没有找到完整未加密接收IP；也不能用两个公开wrapper代替保护内部。这个目录未见key_owner/key_keyowner/Siemens/Mentor recipient文本，legacy MTI格式不能按IEEE1735 recipient标记统计，也不代表已证Questa2024.1兼容。

| 安装包实际文件 | bytes / SHA256 | 可读事实 |
|---|---|---|
| source_modelsim/efx_csi2_rx.sv | 15264 / 567AF3CA9C34CE8035D57CE97753443CB57C4AA1695D05886AA92039CB153551 | 6行module名依赖IP_MODULE_NAME宏；公开参数/端口，不能直接猜生成名或默认值等于冻结DUT。 |
| source_modelsim/efx_csi2_rx_top.sv | 11647 / 4F18126C2A47EDD3183E38C61852BA68A62E8DBA0AEFE76F660ECC618660C40F | 119行起MTI保护，205行结束；不是明文算法。 |
| source_modelsim/efx_csi2_depacketizer.sv | 12511 / A5803A8FE1ECE0E2403F8B2DD6C561B2C863FD021CBC0FE34314CBA69855F0B9 | 4行起保护；不修改或展开密文。 |

公开wrapper默认HS_BYTECLK187、DPHY Continuous、tD_TERM_EN35（14/16/10行）与冻结C2 wrapper的HS_BYTE70、Discontinuous、tD_TERM_EN25（152/154/147行）不同；C2其余NUM_DATA_LANE4、FIFO1024、core100、PACK15、settle85、prepare145等必须逐字段保持，不能借“同版本”恢复成默认配置。fileSet另含common、efx_dphy/source_modelsim、efx_fifo_2依赖，本轮只识别已声明来源，未扩大到新装配闭包或生成专用工程。

### 2.2 C0 HDK旧ModelSim文件不等于当前5.6

`H/ip/csi_rx_controller/Testbench/modelsim/csi_rx_controller.sv`实际145214B，SHA256 `DD651199571BA7CE1B083ADDEDDC20583A8BECF91CAEF64DBD6ABC1BA08EB02C`，头部IP5.0/2023.1.150，247行起legacy MTI保护；同目录modelsim.do第5行原引用该文件。它是原HDK已有simulator专用文件，但版本不是C0实际5.6或C2实际5.15，不能直接替换冻结输入。此CSI目录所见devkit、synopsys、ncsim及root版本也有保护，未找到与C0 5.6匹配的完整未加密接收模型。对安装CSI与core sim_models限定检索亦未发现独立未加密CSI原语。

## 3. 当前map网表与15行为模型的组合事实

本轮只读取原批准阶段已经生成的三个网表以及C0工作副本的同一debug产物，没有重新生成网表。实例类型/数量按工具输出的可见实例声明静态枚举并与15份行为模型的module声明比较；不是vlog/vopt展开结果，保护包内部也没有被读出。

| 实际map文件 | bytes / SHA256 | 保护与可见定义 |
|---|---|---|
| W/C0/outflow/ti60f225_oob.map.v | 23824410 / 9A5E6CF2AC5C02264FC56CD55F928D93F2A562F612FD23DE32763F5D93014EA0 | 唯一可见顶层及一个protected_cell实例，83365行实例；89088–274114一个IEEE1735包，recipient为Efinix EFX_K01及89105–89106 Mentor MGC-VERIF-SIM-RSA-1。不是无密文网表。 |
| W/C0/outflow/ti60f225_oob.dbg.map.v | 23360883 / F18680E05E7BCA979889DE015C765CF2F61BAA2328CC1D85ED3D814260C4E3F6 | 唯一顶层ti60f225_oob_top，第6行；无pragma protect、legacy protected指令、key/data包或protected_cell实例，只有下表六类可见primitive。 |
| W/C0/work_dbg/ti60f225_oob.dbg.map.v | 23360883 / F18680E05E7BCA979889DE015C765CF2F61BAA2328CC1D85ED3D814260C4E3F6 | 与outflow debug网表逐字节同一产物，无借用其它case。 |
| W/C2/outflow/ti60f225_oob.map.v | 27701758 / 25E1DA9332EB0AD1DE96DE218D8BD1BCA89316A0F3290A778E13276B1BC8131B | 143807行protected_cell；149448–308954一个IEEE1735包，149452/149453所见recipient仅Efinix EFX_K01；QuestaSim agent不是其仿真recipient。 |

C0 debug网表仍有`( protected RTL )`**注释**，例如3317/3320行保留CSI原实例层次及原源位置；这不是加密包装，更不意味着本轮做了解密。它是先前获批官方debug helper/merge产生的既有工具输出，生成身份由RUN_REPORT和原阶段记录绑定。本轮不对该输出做补丁、拆保护包、裁剪、重命名模块或替身替换。

| 网表可见实例类型 | C0 base | C0 debug | C2 base | 原15行为模型中的定义 |
|---|---:|---:|---:|---|
| EFX_ADD | 809 | 2027 | 1033 | efx_add.v |
| EFX_DPRAM10 | 4 | 4 | 4 | efx_dpram10.v |
| EFX_FF | 2968 | 8783 | 6816 | efx_ff.v |
| EFX_LUT4 | 7434 | 12858 | 15291 | efx_lut4.v |
| EFX_RAM10 | 134 | 156 | 85 | efx_ram10.v |
| EFX_SRL8 | 1134 | 1175 | 1164 | efx_srl8.v |
| EFX_DSP48 | 0 | 0 | 4 | efx_dsp48.v |
| EFX_GBUFCE | 0 | 0 | 1 | efx_gbufce.v |
| protected_cell | 1 | 0 | 1 | 不在15个公开行为模型；定义可能在各自保护包，接受性未知。 |

C0 debug可见实例共25003个，未发现其它未定义的可见类型；六类均在原实际已成功编译的15份行为模型中。本轮重新核15份文件bytes/hash未漂移。基础网表只统计包外可见实例，不能把这些数量当保护内部资源总量，也不能把无未知可见类型当真实展开成功。

C0 debug全文静态计数进一步闭合为：pragma protect指令0、legacy protected指令0、key_owner/key_keyowner0、key_block/data_block0、protected_cell实例0；`include`指令0、活动import0、$readmemh/$readmemb0、$fopen/$fread0，MEM_FILE/INIT_FILE/MEM_INIT_FILE/INITIAL_CODE/FILE_NAME/FILENAME等初始化资产参数名0。原语初始化以6400条`defparam … .INIT_<hex>`内嵌常量保留；原Panel资产不由这个网表再通过readmem读取。EFX_RAM10/DPRAM10行为模型的限定检索也未见这些外部文件读取。此静态结论只说明当前网表没有观察到额外header/MEM文件依赖，不能证明初始化内容正确或运行时行为；将来gate输入必须冻结该完整网表和15行为模型原字节，不能只挑六个名字或改INIT值。

## 4. 官方文档支持的路线与不能覆盖的内容

现装官方`E/doc/topics/efn-simulate-modelsim.html`（SHA256 `F8029FE612A65C56F133E3FC7BB1523B27F76B8208A3D2723997E034537A31E2`）181/185行描述post-synthesis simulation，208行要求post-mapping synthesis file与Efinix primitive simulation models；后续示例需要TB、vsim及run。`efn-simulating-models.html`（`AC62470D8474EE5017BAE13F9E59AB4123377F9005DB470A55353DEF5F327CDE`）173/176行指core模型目录及表，302/306行区分interface模型和支持范围。本轮实际读取正文，没有执行文档示例。

**不能用空maplib补齐行为。** `E/sim_models/maplib/efinix_maplib.v`为41675B、SHA256 `70529D062DA73013F651CCCA4DE83351C0195D3197CD13968D8BD1BB1AD1A715`，1–3行标synthesis cell library，早期EFX_ADD模块仅端口/参数及空实现。它不能替代上述15真实行为模型，也不能代替protected_cell或CSI功能。

| 路线 | 当前事实 / 下一份必要证据 | 状态与禁止推论 |
|---|---|---|
| A：既有C0官方debug map＋原15行为模型 | 最有直接输入证据的门级编译/展开候选；若未来获批采用此输入，需单独冻结网表/15模型身份，先取得真实compile，再依成功条件elaborate。 | 本轮NOT_RUN；不是原RTL输入compile PASS，更不是未批准v1.3结果。不得静默用它改旧失败记录。 |
| B：C0基础map＋公开原语＋其原保护包 | 已有Mentor recipient的官方post-map包，可作为另一合法工具产物兼容候选。 | 真实Questa接受性未测，不能保证RSA1被现装工具接受；保留包原字节，不解密/重包装。 |
| C：C2同版本官方ModelSim源 | 先审fileSet全依赖、模块宏、每个真实参数/端口和独立输入基线；取得指定许可范围后才能装配/编译。 | 不是替换当前冻结DUT的授权；本轮不生成模型/工程，不用默认187/Continuous替代70/Discontinuous。 |
| C2基础map | 仍有仅Efinix的所见保护包。 | 未获得另一个可直接展开的当前C2全门级明文产物；没有证据可以保证免key兼容。 |

原v1指定的Questa阶段是编译被引用public/protected RTL DUT与原语来测语言/key兼容，并未指定这个post-map gate视图。因此本报告及旧compile批准不授权新gate compile；下一项应是root单独形成并呈现具体gate编译设计/输入，取得指定范围后才执行。本轮维持NO_COMPILE，不自动调用官方mapsim流程或已有TB。

compile/elaborate即使未来成功，也只回答语言/依赖/合法模型接受性。功能仿真必须另有获批的TB、clock/reset、有效CSI包/错误包、像素期望、初始化/存储服务和可复核scoreboard。本轮没有这些新资产，不能将vendor编译或map作为算法、帧buffer、错误/CDC、P/R、帧率、DDR校准、PHY电气、相机或HDMI整机的功能证据。

目前网表是fabric core，PLL/DPHY/外部DDR及其他外围信号作为端口交接；门级原语不自动补足外部物理服务、正确SC431HAI配置或2Gb器件模型。没有route后SDF/STA绑定，零延迟/功能门级行为不能替代实际布线时序。加入物理wrapper需实际官方产物、对应被支持interface模型、完整端口/时钟与独立批准范围；不能手造空wrapper或借现有TB版本推断物理已验证。原C2 CLOCK_UNRESOLVED、C1固定#4及原依赖停止条件均未因此关闭。

## 5. 审计范围与交接

读取范围限当前C0/C2实际CSI、原HDK该CSI目录、安装`ipm/ip/efx_csi2`和core sim_models、既有map输出、相关官方仿真文档及现有审计记录。安装工具目录最初仅做文件名定位以确定文档/CSI入口，发现路径后立即收窄；没有读取无关第三方包内容、全盘检索或网络查询。独立只读子审阅核CSI recipient/专用源，本报告作者核实际map/原语/官方正文，二者不是工具运行证据。

IP-REQ05/IF03–04映射为“原compile失败→本报告合法候选/未知→未来指定输入的真实终态”；原D的C0 debug保留义务保持，REQ02仍是ASYN比较矩阵。此报告不修改批准设计、候选baseline或RUN_REPORT，不将计划写入正式状态/DB。到已能决定下一行动的证据即结束：优先评审A的有限门级兼容性试验；需C2 RTL级验证时再冻结C的真实模型装配设计；功能TB与所有业务实现仍遵循独立批准闸门。保存读回后停止编辑。
