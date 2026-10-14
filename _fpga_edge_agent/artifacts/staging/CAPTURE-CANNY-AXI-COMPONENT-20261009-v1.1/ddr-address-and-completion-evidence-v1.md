# DDR地址与完成事件：实际v6源码证据 v1

2026-10-04；TRACK4-FULL-SW-001。只读调查，不是DDR功能测试或已批准的实现。补充原基线，不修改已冻结的FRONTEND输入。读取方式为Windows tar流式读取RAR成员；未向原目录展开或写入。

## 1. 来源与可证明范围

归档：`D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v6.rar`。

SHA256：`45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C`，由既有[基线清单](baseline-manifest.json)绑定。本页成员均省略前缀`Ti60f225_sc431hai2hdmi_v6/`；行号为归档原文行号。

实际`ti60f225_oob.xml:16–29`引用DDR各层及参数头，`:57–69`引用frame_buffer_V3。可读的现有帧缓存主设备按字节地址生成事务；受保护DDR从设备内部的地址映射和完整AXI行为仍待验证。`axi_upsizer.v`存在，但未在actual XML的design_file清单显式引用；加密上层使本轮不能断言它完全未用，也不能用其明文行为替代实际实例链证据。

## 2. 地址、位宽与时钟

| 项目 | 成员及行号 | 事实与边界 |
|---|---|---|
| 控制器参数 | `rtl/ddr3_controller/ddr3_parameter.vh:19–23` | DATA_WIDTH16、内部ADDR_WIDTH30；外部AXI ID4/address32/data128。内部地址宽度不是可用容量证明 |
| 外部接口 | `rtl/ddr3_controller/ddr3_top.v:101–151` | AW/AR含8位LEN、3位SIZE、2位BURST；W128/WSTRB16；B/R有2位RESP，R有LAST |
| 调用链 | `rtl/ti60f225_oob_top.v:575–614,669–709` | 帧缓存AXI线直接连接ddr3_top，可读顶层无额外地址换算 |
| 时钟连接 | 同一top`:552,555,560,621–627` | AXI及DDR core接core_clk；采集i_mipi_rx_pclk，输出vid_clk_dvi2；DDR另有SDRAM/校准时钟 |
| 声明频率 | `ddr3_top.v:52–57`；`ddr3_parameter.vh:40,53–54` | 注释AXI/core100MHz、SDRAM400MHz；tCK2500ps、CK_RATIO4、ASYN_AXI_CLK1。不是本次实测或STA |
| 写地址步进 | `rtl/frame_buffer_V3/ddr_wr_buffer.v:61,64,252` | shift由每拍字节数计算，地址增加(AWLEN+1)×每拍字节数；当前128位对应16字节 |
| 读地址步进 | `rtl/frame_buffer_V3/ddr_rd_buffer.v:51,53,192` | 同为按每拍字节数移位的增量 |
| SIZE/BURST/ID | `ddr_wr_buffer.v:420–423`；`ddr_rd_buffer.v:225–229` | BURST=01，SIZE=log2(每拍字节数)，ID=0；当前SIZE4，WSTRB全1 |
| 常规突发 | `rtl/ti60f225_oob_top.v:545`；`ddr_wr_buffer.v:288–291,396–409` | BURST_LEN127；按接受的数据拍计数，常规128拍=2048字节，首尾可变 |
| 4KiB边界 | `ddr_wr_buffer.v:160–161,207–212`；`ddr_rd_buffer.v:110–111,157–162` | 有按地址低12位计算首尾突发的设计意图；未验证所有短帧/非对齐组合 |

新MOD-05服务应自行明确字节地址、byte lane、合法容量、对齐、突发和响应契约；以上事实只能证明原主设备的请求格式。不得把内部ADDR_WIDTH或归档中的明文upsizer成员当作受保护slave的保证。

## 3. 原帧缓存的“完成”不能作为新方案提交

| 证据 | 影响 |
|---|---|
| `ddr_wr_buffer.v:49–51`仅有BID/BVALID/BREADY，无BRESP；全文BID/BVALID未参与完成控制；`:425` BREADY恒1 | 原写链没有验证写响应成功，不能据其完成发布新源帧 |
| `ddr_wr_buffer.v:358–360,409`按WVALID&WREADY&WLAST推进结束；`:295–302`根据数据突发计数产生burst_last/bank_sw | bank_sw表示该实现的数据发送进度，不是全部B响应成功的证据 |
| top`:687–690`接出了DDR BRESP，但`frame_buffer.v:78–87`无BRESP接口 | 新MOD-05需接入并检查响应，不能直接透传旧完成信号 |
| `ddr_rd_buffer.v:40–45`虽有RID/RRESP端口，全文未核验；`:304`按RVALID&RLAST结束 | 新读服务要校验响应、ID、LAST与拍数 |
| `ddr_rd_buffer.v:235,237–245,274–315,319–336`正常运行RREADY恒1，延迟RVALID直接驱动入FIFO | 该参考模块没有证明任意R反压支持，不能当通用反压服务复用 |
| `frame_buffer.v:44,59,78,85`为6位ID；top`:274,292,296,308`与DDR参数为4位 | 原master恒ID0使当前截断不改变请求ID；新多客户端服务必须统一宽度 |

**本任务派生设计契约（提议）**：IF-05/11的“完成”必须定义为像素数量/标记正确、客户端停止增加该帧写入、已接受请求的全部写响应收齐且成功、没有仍能改写该槽的在途事务。接受最后一个W数据拍不满足此定义。普通取消也必须等旧请求排空；无法排空时隔离槽，不能只清计数。B响应与后续读取可见性的实际关系仍须在受保护控制器上验证，不能把此提议写成原IP已有证明。

## 4. 槽间距不是顶层所见参数直接相乘

top`:537–548`配置输入32位、输出16位、START_ADDR0、FB_NUM3、MAX_VID_WIDTH960、MAX_VID_HIGHT1080。但`rtl/frame_buffer_V3/frame_buffer.v:186–194`实例化ddr_buffer时没有转发FB_NUM/MAX_VID_WIDTH/MAX_VID_HIGHT。

`ddr_buffer.v:9–14`的默认3/1920/1080仍生效，输入宽度32由上层传入；`:215–221`再传给bank_switch。`bank_switch.v:31–37`按宽×高×输入位宽/8+512计算槽间距。**静态推算**当前间距为8,294,912字节（0x007E9200），三基址为0、0x007E9200、0x00FD2400。这是参数传播分析，未用仿真验证；不能当作新RGB帧池布局。

`frame_info_det.v:26–27,63–79,146–169`另根据实际有效输入次数×每输入字节数，向上取整到AXI拍，`frame_buffer.v:202–203`将拍数交给读写。槽容量与动态传输长度不同，需分别说明。

`bank_switch.v:119–150`复位写0/读1/备用2，写请求分支优先于读请求分支；它不提供本次6源/3结果/冻结/退役读者的引用协议。

## 5. 像素打包和受保护实现的限制

top`:558`输入DDR的是四个RAW10各取高8位拼为32位，非RGB888。`ser2par_v1.v:49–50,170–198`将较早输入向高位移动后输出整组。新软件字节服务若规定低地址对应低byte lane，必须显式适配并用逐字节图案验证，不能默认相容。

ddr3_top`:193–935`、axi4_bus_ctl`:101–2890`、local_bus_ctl`:81–333`、memory_bus_ctl`:137–5169`为protected区域，有Mentor/Efinix key标记。标记存在不证明Questa成功展开。local_bus_ctl`:36–37,45,69–75`只显露地址公式、BANK_ROW_COLUMN和端口；memory_bus_ctl`:66–77,125–131`只显露命令/accept/PHY/cal_done端口。以下尚未证明：地址到bank/row/col的位映射、容量/别名、窄传输/非对齐/WSTRB、允许突发、outstanding上限、B/R响应语义、R停顿保持、校准前请求流控及复位冲刷。

归档中的明文`axi_upsizer.v:220–223,647–651,87–91`有字节宽度转换、B响应透传和单线程注释；这些属于该成员自身，不提升为当前控制器保证。top`:827–837`的vid_rst_n来自相机配置后的延迟，表达式未包含cal_done，不能据参考顶层宣称新访问一定在DDR就绪之后。

## 6. 下一步与验收边界

此调查细化BL-02/03/05，没有关闭BL-01匹配2Gb模型缺口。匹配模型、真实PHY/校准、跨行/bank/边界/掩码读回及响应行为仍须获批后的实际仿真。新帧管理设计引用本页，原FRONTEND v1及其28项输入不变。

本页来源经独立只读Agent核查；主Agent另读回ddr_wr_buffer:54–65、235–258、400–428，确认地址移位、突发结束和BREADY事实。当前记录只支持设计决策，功能测试状态NOT_RUN。
