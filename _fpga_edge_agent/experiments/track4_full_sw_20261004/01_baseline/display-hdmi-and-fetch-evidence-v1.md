# DISPLAY：HDMI、固定扫描与DDR取数来源证据 v1

2026-10-04；TRACK4完整软件实验的显示来源调查。仅流式只读原V4 v6 RAR、现行控制面文档与已保存板级来源；本文件是新增Markdown证据，不是DISPLAY实现或已闭合设计。业务RTL、功能脚本、参考程序、testbench、仿真、综合、PNR/STA、bit/hex和硬件测试均为NOT_RUN；未联网、下载、安装、解密保护主体或解压业务文件。状态为LOCAL_DESIGN来源输入，NOT_APPROVED_FOR_IMPLEMENTATION，不能据此标READY。

## 1. 实际读取范围、基线与哈希

已复核控制AGENTS和唯一详细根规范v0.2的哈希未变，沿用此前完整读取；模板本轮重新读回。现行[主计划v0.11](../../../planning/design-TRACK4-FULL-SW-001.md)、[PLATFORM v0.1](../../../planning/design-TRACK4-PLATFORM-001.md)、[FRAME-MANAGER v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)及[DDR-SERVICE v0.1](../../../planning/design-TRACK4-DDR-SERVICE-001.md)的显示合同已实际读回。本轮未修改这些文件。

| 文档输入 | 实际SHA256 |
|---|---|
| 工程根v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 |
| 控制AGENTS | 6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937 |
| PLAN_TEMPLATE | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 |
| FULL-SW v0.11 | 18EA2A722289B9E549B4441FE5A9F12541991287161C41BD26728E792B406FB2 |
| PLATFORM v0.1 | 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 |
| FRAME-MANAGER v0.1 | D4CD59B9183E3456757D35AEC7B3ADF3E0C09727EAB9070D3AEDA355FE1FC2FA |
| DDR-SERVICE v0.1 | 543D560FE9F9F4DFEB00386A7B5DBEF91F41075DB41133EF701F94068ED6AE32 |
| 板级引脚来源v2 | 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F |

原归档实际路径为`D:\大三\FPGA_verilog\Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））\Ti60F225_DemoBoard_v4\10_Ti60f225_sc431hai2hdmi_demo\Ti60f225_sc431hai2hdmi_v6.rar`，本轮重核SHA256为`45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C`。下文成员相对路径统一加前缀`Ti60f225_sc431hai2hdmi_v6/`，行号是成员原文本行号。成员哈希对tar流出的原始字节计算，不对PowerShell重新编码后的字符串计算；受保护文件的整体哈希仅标识版本，不表示已阅读或验证其主体。

| 原归档成员 | 字节数 | 实际SHA256 |
|---|---:|---|
| ti60f225_oob.xml | 13967 | 20B2CF104F8F21864831F23678326FDC491AC5BA3FB8359AD2C8CC775B2DC528 |
| ti60f225_oob.peri.xml | 75065 | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B |
| ti60f225_oob.sdc | 41630 | 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF |
| rtl/ti60f225_oob_top.v | 35587 | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 |
| rtl/dvi_tx/dvi_encoder.v_encrypted.v | 13383 | 2A35CA4E11DD93B3C329EEF7C9E1D94498864C80041672C01E86EC1450E60381 |
| rtl/dvi_tx/encode.v_encrypted.v | 8314 | D1A0A8139A41F13736BA97C65A9F481267C0642ACD51F2C66120E0E7F543BD3F |
| rtl/dvi_tx/tx_aux.v_encrypted.v | 19508 | 579C75FAB971980053DFC9B4FA07DE2431BDA6DD0E37515F427A5B2F869D72B5 |
| rtl/dvi_tx/efx_fifo.v | 53930 | 0F9BE5DE03C280743837B1B27011B95D9203BC0DAA414CEC45D676A76DDE0581 |
| rtl/dvi_tx/Sc_Fifo_Slr8.v | 8775 | 6DC746E307436D3B6F0881E24B654A349FCEEDA4CA76025FDC4C310C1D47C9E6 |
| rtl/frame_buffer_V3/frame_buffer.v | 10656 | E2F0691300EBB1317315EF42E582853FE1184A8CF1A5DB11044B67D077221BDC |
| rtl/frame_buffer_V3/data_tx.v | 11049 | 5DC2CF6BA15EA207B79CB31D49B51A78EE0C2C8446811E714AC8F6916E2A1AD8 |
| rtl/frame_buffer_V3/vid_par2ser.v | 4687 | ABA8E1DE73325D08A5F9620B859314E884FEBE74581E508CD42E45C3FD03B0F2 |
| rtl/frame_buffer_V3/par2ser_parse.v | 1079 | 6F89421E2D6AFAF3079B3464F899A7496D55CBF72EFB5CA5C7B4FD48543A4620 |
| rtl/frame_buffer_V3/ddr_rd_buffer.v | 11791 | 711D99275CB984B2AA84B47248C7D5B55B99A9CE852044CEFB8CE7F5388A5AB0 |
| rtl/frame_buffer_V3/ddr_buffer.v | 7417 | 770D5E55E0A81775A2980D5696AF36EAA8738A03E80BA4F0615F135EB1BDBDC4 |
| rtl/frame_buffer_V3/DC_FIFO.v | 28259 | 60120A28D8C12599CB7D2CB6D7E3E1F44479F3366156FA4055C3260E46CC05FF |
| rtl/frame_buffer_V3/bank_switch.v | 4310 | 47E886098C21EF3B0217F333EFE5573E7628DD65E8A0F02501ACA8C5B103D263 |

项目XML42–52选中dvi_tx的辅助包、FIFO及三个加密输入；57–69选中frame_buffer_V3取数链；80选择本成员SDC。存在某个FIFO源码不等于保护encoder实际按其默认参数实例化，本轮不由文件名推导保护区内连接。

## 2. 固定时序、极性及1080p60算术

事实：`rtl/ti60f225_oob_top.v:255–263`固定下表；566–573把全部横向数量除2传给frame_buffer，纵向数量不除。`frame_buffer.v:291–301`在o_clk逐沿寄存这些数量，316–343交给data_tx；o_clk在top560接vid_clk_dvi2。

| 时序区间 | 原top逐像素数量 | pair域数量 |
|---|---:|---:|
| 横有效 | 1920 | 960 |
| 横前肩 | 88 | 44 |
| 横同步 | 44 | 22 |
| 横后肩 | 148 | 74 |
| 横总计 | 2200 | 1100 |
| 纵有效/前肩/同步/后肩 | 1080/4/5/36 | 同值，单位为行 |
| 纵总计 | 1125 | 1125 |

`data_tx.v:38–45`定义水平/垂直SYNC、BACK、VALID、FRONT四状态；162/174/186/198为横区间长度减2的注册比较，206–257按旧flag换水平状态；265/277/289/301为纵区间长度减1比较，307–365在行末换纵状态。源代码据此构成目标数量来源，但此记录没有运行逐沿仿真来证明首次启动、区间边界或复位后的全部长度。

逻辑同步极性有直接源依据：`data_tx.v:395–397`把V_SYNC状态译为高，413–415把H_SYNC状态译为高；`frame_buffer.v:29–31`也标输出active high。DE由双VALID状态经383–385流水产生。极性是逻辑HS/VS，不是后述板级差分P/N补偿。

算术候选：若目标为60Hz，则逐像素时钟=2200×1125×60=148,500,000Hz；pair时钟=74,250,000Hz，每帧1,237,500个pair域扫描周期；每行1100周期。有效像素124,416,000/s、有效pair62,208,000/s，与总扫描率分开。它们由参数和目标相乘，不是测量得到的HDMI帧率。

## 3. 三个相关视频clock、serializer及旧SDC

事实：`ti60f225_oob.peri.xml:335–346`的USER_PLL位于PLL_BL0，参考CLK_27M/27MHz，multiplier2、pre/post divider1、core反馈fb；pair/slow/fb/fast输出divider分别40/20/55/4，pair/slow相位设置0、fast相位设置2。这里只报告配置与相对分频；不把PLL相位字段2直接解释成已验证的物理采样角度或STA裕量。

旧SDC11/12/14分别为vid_clk_dvi2、hdmi_tx_slow_clk、hdmi_tx_fast_clk建立13.468/6.734/1.347ns输入clock；fast waveform为0.337/1.010ns。对应现PLATFORM的名义74.25/148.5/742.5MHz候选，SDC值有小数舍入，不是实物频率。peri379/390/401/412四个serializer都指定fast/slow这两个clock、is_half_rate=true、is_serial=true、serial_width10、diff_type=lvds；各路gen_pin没有clock invert。频率比例的候选解释为每pixel一个10bit码字、742.5MHz双沿共1.485Gbit/s，每个fast周期两位；输出先哪一位、起始沿、word装载/延迟、复位对齐仍须真实专用IP合同和验证，不能从serial_width推断LSB-first。

旧SDC26将core_clk、tx_cal_clk、i_mipi_tx_pclk、vid_clk_dvi2、CLK_5M、i_mipi_rx_pclk、sdram_clk、rx_cal_clk分成exclusive组。当前源链这些域并发运行的连接并没有证明它们互斥，因此不可照抄这种例外。它没有把三个HDMI域都放进此行独立组，本文件也不将其误写成“三HDMI clock全互斥”。新约束仍需保留真实相关关系和新层次。

SDC260–283给四路TX_DATA/OE/RST设置基于hdmi_tx_slow_clk的输出delay，reference_pin含旧坐标节点`~CLKOUT~218~175/215/187/200`，DATA/OE max0.435/min−0.140ns、RST max0.483/min−0.175ns。它们只是旧约束文本；新生成报告/节点、合法clock关系、全部路径覆盖与STA均NOT_RUN，不把这些数值当新实现通过。

## 4. 旧双pixel拆分、颜色连接与保护encoder边界

事实：top733–750的Debayer在vid_clk_dvi2产生RGB48/HS/VS/DE；753–780直接在hdmi_tx_slow_clk采样这些信号。vid_cnt在VS上升置1，在RGB DE高时交替；沿前vid_cnt=1选择RGB48低24，0选择高24，分别赋给`{hdmi_tx_bdata,hdmi_tx_gdata,hdmi_tx_rdata}`。此路径没有ready、异步FIFO或完整pair的独立valid接受；两个相关clock的相位和数据稳定窗是隐含前提，源码本身不能证明每pair恰被按正确顺序消费两次。新DISPLAY不能只凭时钟比2写成配对已闭合。

top938–960连接gamma；962–986调用dvi_encoder，其中966/968的bypass分别把i_bdata接hdmi_tx_rdata、i_rdata接hdmi_tx_bdata，gamma分支接同名gamma输出；969–971同时选择对应DE/HS/VS。这里只记真实接线，与旧Debayer的实际位布局另行核对，不能以R/B变量名或注释证明最终颜色。974把VIC接0，978/979把audio_N/CTS接6144/148500；这不是显示器接受该模式或完整音视频协议正确的证据，也不是新任务必须照用的配置。

`dvi_encoder.v_encrypted.v:1–27`只有公开模块/端口：pixelclk、rst_p、三个8bit颜色、HS/VS/DE、video_format2/VIC7和audio字段，输出三路10bit数据及10bitclock。30行开始保护区；`encode.v_encrypted.v`18、`tx_aux.v_encrypted.v`31开始保护区。本轮在这些边界停止公开正文阅读，未解密。没有消费者ready端口只表明外层接口不可反压；不能据此证明内部编码状态、控制符号、DE/HS/VS延迟、blanking/guard-band/data-island处理、channel颜色分配或TMDS位序。

top885–893把四路serializer OE恒1、RST恒0；encoder reset则为top965的~vid_rst_n。988–991对三路数据和clock全部10bit码字取反。这些是原接线，不能当作新设计的失钟/复位/安全隔离证明。

## 5. 旧取数FIFO、扫描欠载与配对不足

实际旧链是DDR里的RAW8→frame_buffer输出每组16bit→Debayer输出RGB48→双pixel拆分；不是新方案DDR中的RGB888读回。top537–548设I_VID_WIDTH32、O_VID_WIDTH16、AXI128（宽度来源见既有DDR证据）、WR/RD FIFO1024、BURST_LEN127、FB_NUM3、START_ADDR0。top558采集四个RAW10位置的高8位，564将输出16bit接{ch0_g,ch0_b}，742反向接{ch0_b,ch0_g}给Debayer。原frame_buffer186–194没有转发FB_NUM/MAX_VID_WIDTH/MAX_VID_HIGHT，旧容量/槽计算问题沿用[DDR地址与完成证据](ddr-address-and-completion-evidence-v1.md)，不把top的MAX_VID_WIDTH960直接当真实DDR槽容量。

`frame_buffer.v:268–284`在o_clk用par2ser_parse转换AXI宽数据；`par2ser_parse.v:23–38`只是向vid_par2ser转交数据/empty/full，其ddr_frame_len输入声明在14行但没有被消费。`vid_par2ser.v:51–65`自行把rd_fifo_rden延一沿后capture，不使用声明于11行的rd_fifo_rdvalid输入；98用empty抑制RE。100–148把宽数据存入data_buffer1后逐次左移，并从最高O_VID_WIDTH位取输出。原活动128→16是高片先出，不是新RGB DDR合同的低地址字节先读保证；6B RGB pair跨16B拍/段的carry、末pad、两个lane和坐标要由新合同显式处理。源注释“任意位宽”也不能代替这些证明。

`frame_buffer.v:316–343`实际data_tx FIFO为1024项、almost_full门槛960，不是data_tx默认512/240；316–319有实际参数。`data_tx.v:115–136`采用Normal模式，读写同o_clk，WrFull未连接、RdEmpty有线；83–89按wrusedw注册almost_full。原`DC_FIFO.v:192/406`内部以full/empty抑制实际写/读，250–258同步读后保持旧RdData，82注释Normal为下一周期出数据；因此不能把空读时的旧RdData当新像素。

扫描读使能在`data_tx.v:367–374`只看H/V VALID，不看empty；378只按de_r2在FIFO数据和0间选择，空FIFO且DE高没有独立safe选择。138–148的underflow只在当沿empty&&rd_en置1，下一非欠载沿又清0，属于非sticky逐沿指示；`frame_buffer.v:322–343`没有接出该端口，top因此也没有这条完整欠载上报链。本轮没有功能波形证明实际发生了欠载，事实是原明文路径缺少本任务所需的持续诊断和安全替换合同。

data_tx92–113由frame_en形成frame_ena，206–257/307–365在未使能时把计数/状态停在SYNC；frame_buffer303–313把frame_stable两级寄存后作为frame_en。故原扫描依赖capture稳定资格，不是PLATFORM要求的“视频clock合法时固定扫描独立继续”。data_tx104/431–432及frame_buffer213还用帧/period事件清FIFO；这些清指针不能替代新旧scope借用排空或跨域两端会话关闭。

## 6. DDR读接受、错误和真正完成的缺口

以下均为`rtl/frame_buffer_V3/ddr_rd_buffer.v`原文事实，不把它们记成真实保护DDR/PHY的行为：

| 原行 | 明文行为与新任务不能据此得出的结论 |
|---|---|
| 51/53、192、225–229 | 每拍字节数计算SIZE及地址增量，ID恒6'h00；当前AXI128对应16B。不能由此授权访问新scope/grant或把旧6bitID当现服务ID4 |
| 40/45 | RID/RRESP只在端口声明，本文件其余正文没有检查；不能把收到任意数据当成功 |
| 237–245、328–331 | ddr_rd_valid取rvalid，下一沿把缓存数据写FIFO，不以rvalid&&rready作为唯一记账；不能在所有reset/异常条件下证明拍数和所有权 |
| 267–270 | 以FIFO已用量+BURST_LEN+5与深度比较决定新rd_req；这是一项空间启发式，不是全机公平/最坏停顿/显示期限证明 |
| 274–315 | 正常rready置1；rd_fifo_rst_p可清state/arvalid/rready，2'd3仅见rvalid&&rlast继续/停，不核nbeats/RID/RESP，也不由完整scope身份关闭 |
| 258–261 | bank_sw=ddr_read_stop，stop在末次AR实际接受时置位；它不是末R响应校验、逻辑数据消费、FIFO/pixel排空或租约归还证明 |
| 319–337 | AXI写侧与o_clk读侧的Normal DC FIFO共用reset事件；没有本任务的完整会话/身份恢复合同 |
| 339–341 | rd_fifo_rdvalid在axi_clk域延迟rd_fifo_rden，而rden来自o_clk取数链；不能作为已经证明的pixel域valid。下游vid_par2ser实际另作本域延迟，不能据此宣称CDC闭合 |

新服务已经提出每client/方向固定record、完整≤64拍逻辑段、整段R物理容量预留、真实ID/RESP/COUNT/LAST核验后再输出逻辑R、独立terminal及release ACK。旧BURST_LEN127代表至多128拍，不能直接替代新客户端1…64拍。DISPLAY必须在每段本地holding/pending/assembler借用结清后归还，不把整个图描述符视为一次物理承诺；晚到旧R必须保持旧身份，不能写入新active预取池。真实受保护IP/2Gb器件和物理排空仍BLOCKING。

## 7. HDMI引脚与板级P/N来源

本轮实际读回[板级引脚来源v2](board-pin-source-evidence-v2.md)§4，沿用其中已经核对的原理图/封装证据：`Ti60F225A_V4_SCH.pdf` SHA256为855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F，PDF页10/Sheet9及页13/Sheet12；板说明/封装与该来源记录一起保留，本轮没有重新渲染PDF或运行pin生成。

| 通道 | 板P连接FPGA球/资源 | 板N连接FPGA球/资源 | 实际peri资源 |
|---|---|---|---|
| CLK | H12 / GPIOR_N_10 | H13 / GPIOR_P_10 | GPIOR_PN_10，378–388 |
| D0 | F15 / GPIOR_N_13 | G15 / GPIOR_P_13 | GPIOR_PN_13，389–399 |
| D1 | G14 / GPIOR_N_11 | H14 / GPIOR_P_11 | GPIOR_PN_11，400–410 |
| D2 | F13 / GPIOR_N_12 | G13 / GPIOR_P_12 | GPIOR_PN_12，411–421 |

四路bank均3A/板电源1.8V，板P接FPGA N、板N接FPGA P。原top四路码字取反与此来源一致；新候选只在serializer输入码字唯一边界补偿一次，不能另在资源映射或输出再交换一次。唯一driver是MOD-11专用serializer；PLATFORM绑定资源和电气，不同时以业务FSM驱动同一球。peri事实含lvds、vod和pre_emphasis设置，但不证明HDMI TMDS电气合规、Common Mode Driver生成合法或板上波形质量。

原理图PDF页13的HDMI TX U17，CEC13/HPD19/SCL15/SDA16均NC；现PL合同把HPD/DDC/EDID/CEC列有来源的N/A，固定模式不依赖不存在的反馈。没有HPD不能理解成接收显示器已支持模式；真实显示器兼容仍需要人工硬件观察。

## 8. 给DISPLAY新设计的候选输入与尚未闭合项

以下是既有设计要求或新增候选输入，不是旧HDK保证：

- FM-IF05/OP05要求完整bundle先预取，仅在VSYNC且满足条件时原子换active；APPLIED和RETIRE_DRAINED分开、有序并预留事件容量。旧请求、返回、缓存、像素及编码流水没有引用旧对象前不得归还，不能把AR尾或读指针相等当排空。FM-IF06/OP06冻结查询显示域真实active，以snapshot-hold→core FREEZE→COMMIT移交，不用core影子替代。
- PL-IF08要求视频clock合法时继续固定扫描，欠载/DDR失败用独立本地safe像素；失钟时遵循恢复合同，不承诺显示不中断。PL DISPLAY-PIXEL当前候选168bit包含同scope/pair的RGB48/EDGE2/ANN4/markers3/coords22/scopeH68/pair_index21，512项asyncFIFO；具体组装、丢迟到/保超前、重同步边界和RETIRE排空在DISPLAY稿冻结。
- DS client1 DISPLAY只读已授范围，phase0；每方向至多一live record。完整段的逻辑消费、terminal、segment_release/ACK和阶段fence独立推进；服务的逐client返回槽不替代DISPLAY自己的不可反压容量。RR只给接受机会，真实最坏服务曲线、prefetch lead及FIFO容量仍须证明。
- 新RGB源每帧6,220,800B，60Hz有效读取至少373,248,000B/s，仅这一图；旧RAW8每帧2,073,600B的取数链没有证明新RGB/EDGE/ANN合成流量可达标。1920一行RGB为5760B=360个128bit完整拍=960个6B pair；6B与16B的最小共同分组为48B（3拍/8pair），≤64拍段边界仍可能留下2B/4B carry。上述只为手算边界，不是新assembler实现或仿真。

| 证据阻塞 | 精确缺口与后续依据 |
|---|---|
| DISP-EV-B01 | 保护dvi_encoder/encode/tx_aux的TMDS通道/控制/编码延迟、blanking/aux、复位和10bit顺序；需批准基线的真实公开合同及IP验证，不解密 |
| DISP-EV-B02 | 74.25→148.5 pair装载/首lane与742.5双沿序列、phase2具体采样关系、所有sideband对齐；需逐沿设计和实际专用IP/时序证据 |
| DISP-EV-B03 | RGB888低地址字节、EDGE/ANN同bundle/pair融合及pad/carry、错误归属；旧RAW8及MSB-first解析不能直接替代 |
| DISP-EV-B04 | 新完整DISPLAY offer/控制/事件、冻结移交与取消/APPLIED/RETIRE排序、scope/grant和保持域联合版本；FM/PL已有语义不是最终端口 |
| DISP-EV-B05 | 不可反压扫描、欠载安全像素、迟到/超前匹配、FIFO/line bank容量、候选prefetch可显示条件及DDR最坏期限；平均带宽/旧almost_full不证明 |
| DISP-EV-B06 | 真2Gb/受保护DDR、ID/RESP/LAST/count/取消与物理排空、复位后旧返回隔离；当前服务草图不等于真实PHY已通过 |
| DISP-EV-B07 | 唯一P/N补偿、10bit位序、电气/Common Mode Driver、最终pin/generated clocks/SDC覆盖、RAM/FF/STA资源；旧peri/SDC不能冒充新报告 |
| DISP-EV-B08 | 指定版本/范围/基线实施批准及人工硬件观察；全部功能验证NOT_RUN，原包与正式状态/审批/数据库不变 |

本文件保存的是事实来源、手算与候选前提。DISPLAY最终合同、真实HDMI/DDR/CDC软件验证及完整十一项工程均未由这份来源证据完成。
