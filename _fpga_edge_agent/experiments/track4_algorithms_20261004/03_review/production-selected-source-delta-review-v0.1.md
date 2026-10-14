# 生产选定来源、全局时钟与相机配置差异审阅 v0.1

2026-10-05。READ_ONLY_SOURCE_EVIDENCE / CONDITIONAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。本报告补充 [PIO设计](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md) 的来源、连接、中文草图、验证及追踪字段；沿用 [PLAN_TEMPLATE](../../../planning/PLAN_TEMPLATE.md) 和PIO的A–L，不构成业务实现批准。

## 1. 整体结论和本轮范围

可连 fabric 的生产core候选是保留v7 `MIPI_TX_PLL / PLL_TL0 #0 / gclk / core_clk`，以及原DDR `ASYN_AXI_CLK=1`。v7 top129/560/661/662直接证明同一core表达式分别用于业务、frame_buffer AXI和DDR axi/core。DDR PLL #4固定regional的限制仍成立；本候选无需把它改成global。另一个PLL的400MHz PHY及动态校准与这个100MHz core的关系仍需核，既有连接不是功能或STA通过。

选定v7活动CSI已绑定5.15、PACK_TYPE15、HS_BYTE70、control100、FIFO1024、Discontinuous、GENERIC。70仍是生成参数，不能当实际相机byte频率。旧C0配置是161条00…A0；v7和C2同原字节的配置是164条00…A3，末条0x3221←0x66请求水平镜像和垂直倒置。模式/phase必须绑定该历史配置，不能混用旧表或猜模组基础CFA。

完整1080p、全Canny、识别及1080p60显示范围不变。R2 v1及48输入基线不包含PIO，本次保持它们原字节；未收到R2批准，不生成R2或生产业务代码，不运行新测试/EDA。

## 2. 直接读取来源与字节身份

V7ROOT为 `D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v7.rar`；本轮实际hash `9822ACA49F9D41F3948C814FE7527C69F53D1C03A232A9D28FBA42018CD084F4`。只用现有tar流式读，未解压写盘。前三个member原字节由stdout byte stream在内存直接算SHA，没有换行重编码；前缀统一 `Ti60f225_sc431hai2hdmi_v7/`。

| 来源 | bytes / SHA256 | 直接语义阅读范围 |
|---|---|---|
| v7 rtl/csi_rx_controller.sv | 508269 / `685D96FD52A604434A1DA0BB404131CD4413BF76ED8EE738AC596B32CE373E5A` | 1–176公开头的指定版本/端口/参数行；没有保护体解密或全文语义审查 |
| v7 rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v | 10450 / `DB13D1EED22A9478FD0AFFB9AC86B8265302A474886D7FFF688447AF2470FFE3` | active164赋值静态计数、214–257末段及指定mode/window/stream行；inactive注释表不计 |
| v7 rtl/ti60f225_oob_top.v | 36727 / `D22074352D6F895056852B66B8F2DEE77B9BC45D39D4BCFFA4BFD3876A2F0141` | 306–390、567–587、617–649及129/370/383/413/560/661/662实际clock连接；未全文审业务 |
| v7 ti60f225_oob.peri.xml | PIO A2既有member hash `884225E0EA6554EBA62192CA03D49F8265121E069830FA09EE41694980148605` | 本轮314–417的PLL/feedback/reset/lock/serializer；归档hash一致，本轮没有另算此member原字节hash |
| C0 ROM，同名文件在work/active/track4_ip_precheck_20261004/C0/rtl/cam_i2c_ctrl/i2c/ | `DA82D962F02D3E585C97BF81EA057A9E0E9766915449960F98EF6C903B695928` | 77–261配置、全源active赋值匹配161，未算注释表 |
| C2同路径ROM | 10450 / `DB13D1EED22A9478FD0AFFB9AC86B8265302A474886D7FFF688447AF2470FFE3` | 214–256末段及hash；同member hash不代表C2全工程等于v7 |
| reports/audit/environment_20260923/pdf_evidence/摄像头SC431HAI_数据手册_V1.1.txt | `287C42BE7DCD94A5AA709570094179DE88ECCDE27C993EA248B525D12D52F6CD` | 561–636、756–805、886–991、1253–1284及关键词；使用已有提取文本，未重提取/渲染PDF |
| [C1 clock/net核查](../../../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C1-legal-clock-candidates-readonly.md) | 16329 / `BAD69304327EB44C9C0627C39B17B9E8337797EDBE99107049CF137AEDBDFAD2` | 本轮C1报告全文读回；其C0拓扑不冒充本轮v7行号 |
| [IP预检终态](../../../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md) | 9659 / `0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA` | 本轮末50行，既有CSI Questa compile缺有效解密key；未elaborate/功能运行 |
| [PIO v0.2精确快照](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-IO-001-v0.2-before-selected-source-readback.md) | 56290 / `39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10` | Root本轮分段读回，合并输出截断处另补读；修订前CreateNew原字节快照 |

## 3. 连接、配置与中文操作草图

时钟路径为25MHz→TL0 #0/global→同core net→业务/DDR axi/core；另一25MHz→TR0四路400MHz→DDR PHY/动态校准。同参考不等于跨PLL相位已证明。保留ASYN1，ASYN0留作独立未采用实验，不能预扣桥17RAM。

CSI control接core、byte接外部DPHY CLKOUT、pixel接BR0输出。v7 top413的CSR axi_clk实际接0，因此这个来源不能直接提供工作中的CSR错误审计/接收closure通道；启用CSR及其真实时钟/reset/错误时序是未来设计，不写成已具备。

先按164条真实次序处理写入ACK/error和末端readback，再形成camera模式代次，准备ARM历史phase/W/H，保存ARM后接下一完整SOF。索引0x90（十进制144、第145条）stream-on后仍有19写且没有group hold，stream-on ACK或观察两帧不能自动证明所有窗口/翻转寄存器已原子生效。同沿新CFG不能改变旧capture。真实receiver closure、RAW消费和RGB write seal分别结清；最后RGB或数量N不代表完成。

末端**请求值**为W1920/H1080、列起始0x0144=324、行起始0x0005=5、mirror/flip均on。手册31页定义0x3221[2:1]/[6:5]的11分别为on。还未取得本模组基础CFA及crop/flip内部作用次序的相容来源；请求寄存器值不能直接当生效capture相位或几何。

若局部裁剪后、翻转前phase已知，且某个已证明的局部W×H坐标适配仅做x→W−1−x、y→H−1−y，则相位奇偶分别XOR `(W−1) mod2`、`(H−1) mod2`；未翻转轴XOR0。对1920×1080双翻转，两轴都翻转奇偶：RGGB↔BGGR、GRBG↔GBRG。这是**条件数学变换**，不是SC431HAI实际坐标映射的证明。四base phase均保留；来源缺失时保持BLOCKING，不猜phase、不用RGB外观自证。

语言/RTL合同承接PIO F：只有数学式和中文草图，无C++/RTL实现。future端点先扩展再比较，采样以本域旧fire为准，历史cfggen/phase随原ctx保持。相位变换不代替RAW packing、色增益、边界插值、最后一次量化、metadata归属或CDC证明。

## 4. 验证计划与双向追踪

| 场景 | REQ/IF/草图 | 独立期望或失败反例 | 状态 |
|---|---|---|---|
| PS-T01 来源 | PIO01/06、A3、IF01/02 | v7 164/A3与C0 161/A0分开；旁置5.16不当活动源、省末19写不得PASS | NOT_RUN |
| PS-T02 配置/相位 | PIO01、IF01/03、OP01/02 | 四base phase×四mirror/flip组合，条件映射按§3；新CFG同沿旧capture仍用历史值，实sensor映射缺来源不得发布完整源 | NOT_RUN |
| PS-T03 clock/net | PIO06、D4/F-B/K/L | 实际同TL0 #0及ASYN1；#4不许fabricglobal，byte或跨PLL/约束对象未明不得PASS | NOT_RUN |
| PS-T04 closure | PIO01/04/05、IF04/05、OP01/02/06 | 末pixel后CRC、晚生效、CSR不工作或停byte不得假seal；已held/effects真结清，Q不释放 | NOT_RUN |

反向：A3承担来源身份；D4避免不可连接#4；历史ARM/phase承担OP01/02；未来验证T10/T11引用PS-T01…04。所有代码位置待实现。实际source hash和文档检查不算功能验证。

## 5. 门槛、恢复与实录

已补足v7活动CSI版本/参数、配置表身份，提出保留实际global core/ASYN1的具体候选。仍OPEN：相机实际byte频率/完整模式、protected IP功能及metadata/错误closure、模组SKU/CFA/电气、core↔PHY契约/reset、相关视频serializer、服务与唯一资源和共同baseline。PIO继续NOT_READY，不申请未成熟整包批准。

独立代理实际读报告原61行全文、PIO相对v0.2的完整差异及指定段落，限定结论为来源/功能边界与TL0 #0保ASYN1描述一致，四phase×四翻转条件数学相容；不宣称PIO所有337行逐句全文独立审阅。三条反馈已修订并由Root实际读回：v0.2历史core说明与v0.3候选区分；索引0x90明确144/第145条，其后19写；寄存器0x3221←0x66明确十六进制。补明局部裁剪后、翻转前phase及独立mirror/flip，不因此确定实模组CFA或升级READY。

R2 v1 SHA `1728A3163F600CE7F85075BB5704154827FC3B7A0698E0EA6CC0CADA98CDFB27`，48输入JSON SHA `F7CF4DF2F8CE8A5874C33E7B9DEA997A6A09BCF0C417282D7D6DD4DAE8A93E7E`；本轮直接核48项路径无PIO或本报告，保持pending审批对象。PIO快照先保存才修订v0.3，不改原HDK、C0/C2、工具/IP、正式DB、PROJECT_STATE、TASK_LEDGER或原Manifest/hardware_nodes。

本文保存后实际读回与最终hash/本地纯文档checkpoint另记。无新编译/仿真/PNR/STA/bit/硬件步骤；R1既有结果仍限定原范围。软件实现待对应成熟版本指定批准，真实bit生成登记后仍停止硬件步骤。
