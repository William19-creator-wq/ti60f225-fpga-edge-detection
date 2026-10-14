# CAMERA：CSI 与配置链来源证据 v2

2026-10-04；仅本地原始资料、公开端口、既有明文源码和静态算术调查。本文件是来源证据附件，补充[摄像头来源v1](camera-source-and-phase-evidence-v1.md)，不覆盖v1，不修改[PLATFORM v0.1](../../../planning/design-TRACK4-PLATFORM-001.md)。事实、设计候选和未证明项分别列出；所有业务功能测试、testbench、仿真、综合、PNR/STA、I²C实物通信和硬件观察均为NOT_RUN。没有联网、下载、安装、解密CSI保护主体或生成业务实现。本文件不构成READY_FOR_REVIEW或实现授权。

## 1. 来源标识与本轮读取范围

V4根为`D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4`。下文归档成员统一指该根下`10_Ti60f225_sc431hai2hdmi_demo\Ti60f225_sc431hai2hdmi_v6.rar::Ti60f225_sc431hai2hdmi_v6/`，行号为成员原文行号，不是解压后修改文件。

本轮流式只读重读活动CSI wrapper的公开部分、项目XML、顶层CSI连接、另一套IP生成件及settings；重读ROM、reg_set、16addr_8data、ctrl_top及底层ACK/STOP/status/command片段。保护主体只识别边界，不解密或推导内部算法。原归档SHA256已重核，成员原字节SHA256沿用v1对同一归档的记录；两种哈希证据不混为“内部行为已验证”。

| 原来源 | SHA256 | 本轮证据范围 |
|---|---|---|
| v6归档 | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C | 原包重核；未写出业务成员 |
| `rtl/ti60f225_oob_top.v` | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 | CSI、CSR、debug连接及RAW取位 |
| `rtl/csi_rx_controller.sv` | 685D96FD52A604434A1DA0BB404131CD4413BF76ED8EE738AC596B32CE373E5A | 公开wrapper，完整508269字节哈希不代表保护主体审阅 |
| `rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v` | DB13D1EED22A9478FD0AFFB9AC86B8265302A474886D7FFF688447AF2470FFE3 | 有效ROM赋值及启动次序 |
| `rtl/cam_i2c_ctrl/i2c/i2c_master_reg_set.v` | 8BB2F5E862A606097F312BB90C2A501FC5F29E8A21737FFCD0A4AB62D90101EA | ROM字段和done推进 |
| `rtl/cam_i2c_ctrl/i2c/i2c_16addr_8data.v` | 12210C511B52DCFDACA2F4CFFC0FAFB390AC87ED3B3C97DFA2C6008A339C4BB7 | TIP检查、done、读数据输出和本地初始化 |
| `rtl/cam_i2c_ctrl/i2c/i2c_master_ctrl_top.v` | 2534B3D0CD1793B9F91320FC8D5495820252D0221C38CA9DEA247E27AEA1DC7F | DATA_LENGTH164、地址60、分频20、WB连接 |
| `rtl/cam_i2c_ctrl/i2c_master/i2c_master_top.v` | BF5DD12F2BF30DBC46A1D4CF1D3D1ACCC05106E14CA1CECF467FD09B46CD45C8 | command/status及仲裁丢失路径 |
| `rtl/cam_i2c_ctrl/i2c_master/i2c_master_byte_ctrl.v` | 442159006425FA36A946F67AFC62391F9F80142AAD379A640118A28CE67C9F80 | 第九位ACK和STOP完成 |
| `rtl/cam_i2c_ctrl/i2c_master/i2c_master_bit_ctrl.v` | 2DF1F5D522725EA216385829A4DEC38FDD616E4979AAA0AEF7053AC34BF8AC8C | v1所引分频及位阶段 |
| 根目录`摄像头SC431HAI_数据手册_V1.1.pdf` | E3187CEC241FC1FC53983BA31D27C28E2BDA4341E3C89FDF811CA8ED1FD5F8AE | 42页；本轮直接提取页29，其他模式/上电/相位见v1 |
| 既有PDF提取文本`_fpga_edge_agent/reports/audit/environment_20260923/pdf_evidence/摄像头SC431HAI_数据手册_V1.1.txt` | 287C42BE7DCD94A5AA709570094179DE88ECCDE27C993EA248B525D12D52F6CD | 页29标识行1196，Group Hold段1199–1215 |
| 摄像头来源v1 | 8E28330B6CE156012B1E282A5DF11829ECF1027659C3EB44EC316F58054FD0F0 | 既有页8/10/13/16/17/30/31/32/38证据及相位边界 |

本地CSI帮助根为`C:\Users\34528\FPGAEdgeLinks\Efinity2026_1\ipm\ip\efx_csi2\efx_csi2_rx\ipm\`，以下物理文件SHA256本轮重核：

| 相对路径 | SHA256 |
|---|---|
| `ip_component.xml` | 3E6E66D131BFB30C3F6682A0D43B257080BC0D000967D2F36A96518E9EC1C56A |
| `doc/topics/hlp-mipi-csi2-rx.html` | DD0EA6315A492AC87DA86E7D6F48492F1F2F315FC1B9B1DAAB7D9D5CA1DF6C15 |
| `doc/topics/mipi-csi2-rx-core-features.html` | 9ABEA2CD621F85ED2A8FCCA44D97A5D7FCF86E7A7FCA836D4B11DE9727316FAB |
| `doc/topics/mipi-csi2-rx-core-fd.html` | 59DF4FC68799A943B588F84E72FD1A7FD29B90443032A1DF253712C80FD1E9D2 |
| `doc/topics/mipi-csi2-rx-core-customizing.html` | 34B1AEB02FD8C683FE887DB47B381BBE813BE5D10C90674FC100A1D4AA455FA9 |

公开安装源`...\ipm\ip\efx_csi2\source_efinity\efx_csi2_rx.sv`的SHA256为567AF3CA9C34CE8035D57CE97753443CB57C4AA1695D05886AA92039CB153551；`efx_csi2_rx_top.sv`为AAC896FDFD6BCE3C109F5718489CBC884EE188C080BE46A09B489C5702AE9390。仅读公开声明/连接；top从117行进入保护区，其受保护内部时序未审阅。

## 2. 活动CSI 5.15与未活动5.16生成件

事实：`ti60f225_oob.xml:56`选中`rtl/csi_rx_controller.sv`，不是`ip/csi_rx_controller/csi_rx_controller.sv`。活动wrapper第3/4行分别标Efinity2025.2.288.4.15、IP5.15。其143–159行为PACK_TYPE15、四lane、ASYNC_STAGE2、HS_BYTECLK70MHz、control100MHz、Discontinuous、FIFO1024、AREGISTER8、GENERIC、VCX禁用；settle85ns/prezero145ns。

同归档`ip/csi_rx_controller/settings.json:12,20–37,43`及该目录生成wrapper另标5.16、settle125ns/prezero155ns、byte50MHz、FIFO2048、PACK_TYPE1（仅Pack40）、SIDEBAND0、工具2026.1.132.2.19。它们是不同配置，不能用其参数替代活动5.15，不能仅因同名模块而宣称迁移已完成。安装`ip_component.xml:6`标5.15；本地HTML版权2026并不足以证明它与v6保护主体的每个行为完全相同。

活动顶层`rtl/ti60f225_oob_top.v:369–387`分别把control接core钟、byte接相机CLKOUT、pixel接pixel钟。pixel50MHz及旧SDC byte100MHz与活动参数70MHz的差异见v1及[时钟引脚证据](platform-clock-pin-evidence-v1.md)。参数频率是生成配置，不是实际发端频率、模式、帧率或STA结果。

## 3. 公开端口事实与对齐边界

活动wrapper53–58有control、byte、pixel三组clock/reset；92–102/110有VS0、HS0、pixel_data64、pixel_data_valid1、pixel_per_clk4、datatype6、word_count16、shortpkt_data_field16、vc2、vcx2。像素侧没有消费者ready；不能将D-PHY fifo_rd_enable解释为业务像素ready。119–139有CSR地址6、数据32、独立AW/W/B/AR/R握手和debug输入/输出32；没有BRESP/RRESP/WSTRB端口。

顶层413–429把CSR axi_clk/axi_reset_n绑0，未运行CSR访问；431–446仅接HS0/VS0/data/valid，弃用VC/WC/short/DT/PPC/irq。377/447把32位debug输出接到16位线。555–558采用valid与HS共同门控，取data[9:2]、[19:12]、[29:22]、[39:32]写入32位RAW8。这证明旧接收端采用四个10位位置的高8位截断假设，损失2LSB；不证明IP每个valid均为四像素、完整/尾拍PPC编码、输出位序或上24位值。

安装公开端口另外提供可选pixel_line_num16、pixel_frame_num16、pixel_datatype6、pixel_wordcount16、pixel_vc2、pixel_vcx2（`ip_component.xml:888–959`；安装公开`efx_csi2_rx.sv:123–129`）。活动wrapper没有这些端口。同名原datatype/WC/VC/short字段只是原始观测，尚无其时钟、有效期及与pixel_data_valid相联系的公开时序依据；不能把它们改名后当作已经证明的pixel-aligned sideband。即使未来启用可选端口，也需与批准选定IP版本核对。

本地`hlp-mipi-csi2-rx.html:181–184`明确帮助只是overview，详细用户指南指向外部下载。当前没有下载。features174–196说明lane、8位HS、RAW10、null/blank/embedded非图像包、PHY错误及CSR功能；fd172–174仅列ECC/CRC/depacketizer/byte-to-pixel组成，不给输出时序。customizing209–223说明FIFO与GENERIC/ACCURATE：GENERIC没有通过Line Start/Line End提供准确行同步。270–273说明Pack40支持RAW10，不给位级排列。以上不能推出短包独立valid、blank valid、DT/WC对齐或HS/VS边沿含义。

## 4. 错误来源及接收闭合缺口

顶层469–477的参考命名为debug[0]pixel FIFO full、[1]empty、[2]CRC、[3]/[4]ECC1/ECC2、[5]undersize、[6]VC0 line、[10]VC0 frame、[14]receive。这是明文连接及命名事实，不是完整版本化错误合同：所属时钟、脉冲或sticky、清除方法、归属帧/VC、丢包政策与相对末像素延迟均未证明。empty不是错误；full未被证明等于overflow；ECC1是否完成纠正也未证明。新设计可保守把full或ECC1观察作为失败政策，但不能写成IP已经定义的致命错误事实。

CRC位存在不等于某个pixel有效拍带有与它对应的CRC结果。现有源码和overview未给出“该帧全部payload已输出，相关接收错误也已全部上报”的closure watermark。收到EOF和计到W×H只能构成候选shape证据；还不能排除末像素后上报的CRC、内部FIFO排队或错误跨域滞后。任意固定数量的安静pixel沿不能代替watermark，尤其byte可Discontinuous停钟。最终成功需接收closure和capture writer真实fence分别满足；缺接收证明就不能声称成功。

## 5. I²C配置链实际164写与Group Hold上限

ctrl_top2–6默认DATA_LENGTH164、16位地址、8位数据、device地址60、CLK_DIV0020；reg_set45–48把ROM[24:9]/[8:1]/[0]分别作为地址/数据/读写标志，70–73选择读或写，80–84按rd_done或wr_done推进。

ROM81–246有效赋值共164条，索引00…A3；本轮只读匹配有效赋值行，164条读写标志全部0，没有3812写。旧注释中的IMX219表不计入有效SC431表。

| 原ROM位置与行 | 原事实 |
|---|---|
| index00，83行 | 写0100=00，关闭输出 |
| index90，227行 | 写0100=01，启动输出 |
| index91…9C，228–239行 | 后续12条写3200…320B窗口，输出尺寸寄存器为0780/0438（1920×1080） |
| index9D…A0，240–243行 | 后续4条写3210…3213，起点0144/0005（324、5） |
| indexA1/A2，244–245行 | 后续2条写3E08=80、3E09=2A |
| indexA3，246行 | 后续1条写3221=66，mirror/flip配置 |

所以stream-on之后还有19条写，不是只有窗口的12条，也不是完整配置成功后最后stream-on。表有潜在跨模式输出窗口；没有I²C波形或帧观测证明跨了哪些实际帧。顺序重排、延时、特殊寄存器依赖及所用FAE模式表须另外确认，不能把排序建议写成已验证配置。

原PDF页29（本轮直接读回，既有提取文本1199–1215）：Group Hold最多支持10个寄存器打包；3812写00开始、写30释放；3802[1:0]控制在第N个帧内生效时刻生效，N=0为当前帧。不能把上述19条写当作一次合法Group Hold；拆成两个组也不自动证明19条在同一帧原子生效，更不能假定所有窗口/PLL/stream寄存器都受同一hold机制支持。原有效164条表没有使用3812。

## 6. ACK、仲裁丢失、STOP及读数据缺口

`i2c_16addr_8data.v:158–162,292–302`只检查i2c_readdata[1] TIP=0；该模块全文未检查SR[7]RXACK、SR[5]AL或SR[6]busy，也没有事务超时/有限重试错误输出。227–234/369–378产生wr_done/rd_done，init_done96–102只跟本地初始化状态INIT_OVER相关，不能当作164次外部写ACK全部成功或模式有效的cfg_done。

底层byte_ctrl288–294完成八数据位后读第九位，320–338把core_rxd写ack_out；master_top253接irxack，284更新rxack，299–304将rxack/busy/al/tip/irq放入SR[7]/[6]/[5]/[1]/[0]。这表明ACK/status在底层确有来源，上层未使用；不能写成“底层没有ACK”。AL来源见master_top256/283，done或i2c_al都会清command[7:4]（219–221），TIP为rd|wr（285）。因此TIP回0也可能包含仲裁丢失，不能单独证明成功。

写命令在16addr_8data184–191分别使用98/18/18/51，最后命令含STOP；master_top228–233给START/STOP/READ/WRITE/ACK位定义。byte_ctrl323–326转STOP，345–353等core_ack后才产生cmd_ack。故不能反向声称底层正常done必定早于STOP。实际不足是高层仅看TIP，不检查AL/NACK、命令接受关联、STOP完成与总线释放身份；独立STOP命令本身也不能用rd|wr的TIP表示全部生命周期。ctrl_top85把waitrequest绑0，96把wb_ack_o接到未参与高层等待的线，未形成每次WB接受/响应检查。

读数据方面，16addr_8data16行声明输出dout，351–355仅选择RX寄存器读取地址，全文没有dout赋值或读数据capture；378行只把dout_valid接rd_done。ctrl_top78–79把其接get_data/get_valid但未作为可靠读回消费链。这里的dout与reg_set47行有赋值的配置写数据dout属于不同模块，不能混淆。原表实际全写，所以这一缺口不证明原写表读回曾经失败，但它阻止把旧模块直接当成可靠ID/模式读回实现。

分频及5MHz启动/T4推算沿用v1：名义连续写SCL约5MHz/[5×33]=30.303kHz，额外拉伸/起止增加耗时；819.2µs等待与裸芯片物理释放后T4≥4ms之间存在条件差异。模组电平、reset反相和SID仍未知；不是实物违例判定。

## 7. 供CAMERA主稿引用的候选与PLATFORM差异

以下只是中文设计输入，不是原IP输出端口已存在或映射已闭合：新提议CAM-NORM192包含RAW64、payloadValid1、SOF/SOL/EOL/EOF独立4 flags、ppc4、DT6、VC2、VCX2、WC16、short16、error8、scopeH68、scopeValid1，合计192 bit。字段列举表示意义，不是连接顺序或RTL实现。独立flags允许payload和边界同沿保留；不能采用互斥type优先分支丢另一事件。短包/长包同沿时具体先后、字段归属及事件产生方式仍依赖下面B。

现PLATFORM v0.1第112行仍是CAMERA-PIXEL189=RAW64/type3/ppc4/DT6/VC2/VCX2/WC16/short16/error8/scopeH68。189→192是新提议，必须由下一PLATFORM版本明确吸收；本文件不改它。按候选20×512条带映射，192封装200 bit、高8位零、深1024仍为10条带×2深度=20 RAM10，与旧189高11零的数量相同。原生dual-clock及实际推断仍待工具证据；这里只核数，不是综合利用率或无损吞吐证明。

候选配置成功条件需另外包含命令实际接受、逐字节ACK/AL检查、有限超时/错误关闭、正常STOP及总线释放、必要ID/模式读回与真实物理T4等待；transport ACK不能替代这些业务成功条件。不能直接重用旧wr_done、rd_done或init_done充当cfg_done。

候选捕获顺序为：模式与物理释放依据确认→配置成功→丢弃未arm/不完整帧→新完整合法SOF且有效lease后接收→按已证明packet/行边界核DT/WC/数量→接收closure与writer fence均满足才发布。valid低不能自动结束行；GENERIC不要求LS/LE短包。错误保留旧scope/首错/已写前缀，停止追加业务payload；旧已承诺DDR写和授权关闭继续完成，实时CSI余流丢弃，独立fault通道不等待满像素FIFO。warm reset保持域/单端FIFO不清规则沿用PLATFORM，不能用清计数伪造新帧。

## 8. 尚未证明项及必要后续证据

| 证据阻塞 | 精确范围 | 关闭所需资料/验证，当前NOT_RUN |
|---|---|---|
| EV-B01 | 活动5.15、未活动5.16及实际模式频率差异 | 批准选定版本/参数，公开版本化时序/迁移依据及适用工具验证；不能混用两个wrapper |
| EV-B02 | RAW10位序、PPC编码、尾拍、上24位、blank/null/embedded valid | 对应版本公开packing/波形合同；实际protected IP验证；旧top四位置截断不是证明 |
| EV-B03 | 原DT/WC/VC/VCX/short字段所属时钟与有效关联 | 版本化端口时序，必要pixel sideband选择及CDC核验；不静默重命名 |
| EV-B04 | 短包valid、重复同值短包、同沿短/长事件、HS/VS极性/边沿与行帧末条件 | 独立事件有效性和顺序依据；GENERIC真实输出时序；规范化map逐项证明 |
| EV-B05 | debug/irq/CSR时钟、sticky/clear、错误归属和接收closure watermark | 完整CSR/error文档及末包/末像素/CRC/跨域FIFO排空关系验证；安静沿数不替代 |
| EV-B06 | 164写表重排/FAE依赖、19条更新、Group Hold支持范围及cfg成功 | 合法模式表/更新依据、ACK/AL/STOP/timeout及可靠读回链；原表和最大10上限均保留 |
| EV-B07 | 真模组SID、电平、EXTCLK/reset映射、T4、彩色Bayer相位 | 真实模组来源及人工硬件闸门；页29或BGGR阵列图不证明板上相位 |
| EV-B08 | CAM-NORM192→PLATFORM吸收、无背压FIFO及峰值/停顿预算 | 下一版本完整接口/组合检查和批准后验证；20 RAM算术不证明无丢像素 |

真实CSI接收、保护IP输出映射、完整2Gb DDR/PHY、板上模式和11功能整机均未由本文件闭合；正式状态、审批、数据库和运行时未改写。
