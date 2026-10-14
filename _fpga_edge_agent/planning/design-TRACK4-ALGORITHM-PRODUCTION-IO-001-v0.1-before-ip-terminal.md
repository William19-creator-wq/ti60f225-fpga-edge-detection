# TRACK4-ALGORITHM-PRODUCTION-IO-001：板载资源生产输入输出与新算法桥适配 v0.1

2026-10-04；LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。仅纯文档；本轮授权只创建本文。最新用户边界为只用板卡现有资源、允许板载DDR3、禁止增加外接存储，PC仅仿真/黄金/观察。此前排除DDR的边界已撤销，非DDR容量/带宽诊断在本文仅作为历史比较。用户保留完整1920×1080、基础五项与高阶六项（含恢复A3设计，尚未完成）、完整八邻域Canny、圆/任意旋转矩形及原质量目标；160×120降标撤回。完整算法核心、生产摄像和1080p60显示分别追踪，不用局部top、PC算法/arena、常量stub或虚拟I/O替代整包。

## 通用计划字段

- Goal：把真实SC431HAI彩色输入与固定1080p60 HDMI输出接到现行CONTROL/REPLAY/VIEW的完整算法路径，给出板载DDR/摄像/显示的真实连接、容量、CDC/复位、逐沿及审批前缺口。
- Current state：现有CAMERA/DISPLAY/PLATFORM是旧物理scope/外存路线候选；新CONTROL/REPLAY/VIEW是逻辑对象与可暂停单slot候选。二者尚不能直接组合。
- Target state：真实源→原子CFG/job→完整算法→同源RGB/EDGE/ANN→合法固定扫描；所有旧读写/borrow/输出流水真实关闭后返还；软件全图回归和完整Ti60工程分别验证。
- Gap：板载DDR3可作为主存储，但现demo不是现行完整算法/逻辑对象服务；几何/参数/业务时钟、吞吐/最坏等待及新bulk renderer尚未共同冻结。CSI metadata/错误closure、模组电气/模式、serializer相位、完整pin/资源亦未闭合。
- Assumptions：软件目标Ti60F225/I3与V4资料、SC431HAI彩色4lane/RAW10；都是设计假定，实物尚未确认。生产W1920/H1080，不缩小验收。
- Open questions：PIO-B01…08；板载DDR3真实baseline与生产帧接纳政策、新bulk row协议/双bundle容量怎样共同冻结；不再选择外接存储或PC生产arena。
- Dependencies：唯一v0.2、PLAN_TEMPLATE、CAMERA/DISPLAY/PLATFORM来源、新CONTROL/REPLAY/VIEW、现行RC和R5架构报告。
- Milestones：真实来源/整体→适配差异/中文草图→联合冻结缺口→审阅/指定批准→获批实现与完整软件/工具验证→bit登记停止。
- Detailed steps：先A/B事实与行为→C职责→D接口/反例→E步骤→F语言/三映射→G/H验证追踪→I门槛。
- State transitions：仅本文LOCAL_DESIGN；不改正式H0/状态/Manifest/DB，不继承旧实施批准。
- Artifacts and hashes：只有本文新文档；源hash见A，本文保存后实际全文读回另报。
- Validation：只读文件与静态算术；仿真、综合、PT/PNR/STA、bit和硬件观察全部NOT_RUN。
- Failure handling：无lease/坏包/溢出/失钟不发布完整源；扫描欠载safe并真实报错，未知关闭Q；已held承诺保留。
- Human approval gates：重要架构OPEN尚未关闭，不申请泛化实施批准；成熟共同版本需明确批准及既有执行前置。
- Rollback：唯一新增本文；上游设计、原HDK/归档和工具均只读。
- Completion criteria：本稿交付可审阅的生产边界和缺口，不等于基础五项/高阶六项、生产视频或整包READY。

## A. 实际来源与采用边界

已按入口顺序读AGENTS、config规则/运行提示/配置、状态/ledger、数据库README与审批Manifest。DB NOT_CONFIGURED、正式H0 WAITING_FOR_HARDWARE_BASELINE；本轮纯文档不恢复正式执行。唯一v0.2前轮全文读取，本轮重读§8–10及模板。下表是读取时实际hash；旧身份/物理服务不继承。DDR排除边界撤销后，新增定向只读10/v7实际连接证据A2；控制器/器件模型细核由根另行汇总，不在本文复制整套调查。

相对路径以`D:/大三/FPGA_verilog/_fpga_edge_agent`为根；V4ROOT为`D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4`。

| 来源 | SHA256 | 本轮实际采用范围 |
|---|---|---|
| 根唯一v0.2 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 | 设计门槛、A–L、三映射及追踪 |
| planning/PLAN_TEMPLATE.md | 99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79 | 通用字段与A–L |
| planning/design-TRACK4-CAMERA-001.md | F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C | A–F中的输入/配置/RAW/窗口/关闭及I缺口；旧writer物理口不继承 |
| planning/design-TRACK4-DISPLAY-001.md | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 | A–F/I的扫描、行借用、模式、固定输出和未知；旧scope/ANN地址格式不继承 |
| planning/design-TRACK4-PLATFORM-001.md | 8031728AE928257E1A4E107E88CE2DA88BCC98193EE878157E405016245970C0 | 非DDR域、CDC、保持/复位与I缺口；旧4PLL全组合不作为新架构 |
| planning/design-TRACK4-ALGORITHM-CONTROL-001.md | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | C/D/E：CFG/J/V唯一owner、取消/reset/可暂停source |
| planning/design-TRACK4-ALGORITHM-REPLAY-001.md | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | D/E：PLAN616/RQ/RR/OUT404、CLOSE/RELEASE/RT、单pair约束 |
| planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md | C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C | B–D及E3/4：单slot、仅一次PLAN、两层引用/证书/真实退出；不宣称新生产接口已存在 |
| experiments/track4_algorithms_20261004/03_review/r5-implementation-architecture-options-v0.1.md | 22B7BEBAAB6B8DC2661F74DB95B3054BF72069B4A72F826949369D08A70FD7D9 | 全文实际读回；41,113,469B是现算法容器示例。旧PC raw arena建议不适用于最新生产边界 |
| planning/design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 前轮实际D2/D3/D7/D8/F：一POINT、ANN518400B/RECORD4096B、OBJ及私有退休；未全文审阅 |
| docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md | BBAB7A4F14360CD7452272ED801A21E4ECD318BFED490FAB7FF454979B73C0C9 | 全文实际读取；既有硬件/模组/工具证据分层，不当新实测 |
| docs/requirements/V4_CAMERA_SELECTION_20260927.md | 0C7FE5F9A3BC0E53EF89A158DEDA406F4CCE67669F8E4C88B5FAF9AEBD7868CB | 相机/子卡/版本来源；历史裁剪建议不采用 |
| 01_baseline/board-pin-source-evidence-v2.md | 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F | 下列01_baseline都在experiments/track4_full_sw_20261004中；本文实际全文读取，采用球号/电气来源 |
| 01_baseline/platform-clock-pin-evidence-v1.md | 358B3F6A4F3605F87D6DBFE3AF387E0FDE380AC5FB48DC8927611319D46C7ED2 | 全文读取，实际byte70/100与相关HDMI源关系；初读的DDR排除边界被A2最新路线替代 |
| 01_baseline/camera-csi-and-config-evidence-v2.md | 7FCC316A187864CB52B74C23415852F1E7F9B848CCF9F4844C57B5EEA08787CD | 活动5.15/未活动5.16、公开端口、CRC/closure与164写；输出截断处不宣称全文逐行审阅 |
| 01_baseline/display-hdmi-and-fetch-evidence-v1.md | 08A9CDA7D565AAF60AB6006A89EBE3DA6A40E4DCB7C41DB59ECE44C8CA7E1C03 | 扫描/相关PLL/PN/保护编码/欠载来源；不复查其DDR器件 |
| 01_baseline/vf-demo-supplemental-evidence-v1.md | 6E8823391907B5D9A42E7DB854E01648EC522952F3DD9E61699AC03CF9B10979 | 实际读取公开TMDS候选/serializer/复用条件；不同板C4不套当前I3 |
| C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v（17913B） | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 | 本轮实际读1–50、109–129、310–371及宽度/时钟定位：EFX_RAM10一读一写端口，独立WCLK/RCLK，20bit模式512word；未运行此模型或工具映射 |

### A1. 本轮新核的非DDR连接事实（辅助与历史比较）

已有板说明提取文本`reports/audit/environment_20260923/pdf_evidence/TI60F225I3-V4 DEMO板软硬件设计说明-260920.txt`实际hash E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8；本轮定向读PDF页16–21、32–35、107–108对应文本及相关检索。原PDF hash 426A577CC3A544546F2BF1AD60A1F233541B7D6361764794E48B11ADA0C2E4F2来自已核来源，本轮没有新渲染整份PDF。

| 真实资料对象 | 本轮事实 / 能用与不能用 |
|---|---|
| Type-C / FT4232HL | 说明PDF14–15记供电、JTAG下载、UART；未找到此板连成USB高速parallel FIFO的依据。USB连接器或驱动文件存在不证明FPGA有可用USB视频/存储总线。 |
| UART | 说明PDF35：RX=R4/GPIOL_02、TX=R14/GPIOR_28；原17_UART工程peri109–113为3.3V LVCMOS。实际top设置27MHz/115200baud、无校验，STOP字段与模块编码仍需一致核验；8N1理想payload上界11520B/s仅算术，不是测量，不采用不明来源3.686KB/s为旧工程事实。 |
| 板载Flash | 说明PDF7/34：GD25LQ64，8MB/64Mbit，用于配置也可用户数据；未绑定完整读写/擦除/寿命/带宽及与配置共用合同。容量仅略大于一RGB6.22MB，不足当前41.11MB工作示例，不能当零延迟RAM或后台反复擦写的生产缓存。 |
| 板载以太网 | 说明PDF16–21记YT8531SC、UTP↔RGMII、千兆125MHz、4bit双沿及MDIO/MDC；04_GE_demo确有展开源码/配置。1Gb/s线速上界125MB/s，协议有效率和延迟更差；板存在GE不等于真实raw对象服务已实现。 |
| QSE/FPC/J6 | 板说明和SCH来源有J7 QSE（2A/2B/TR/TL）及J4/J5 MIPI，J6是1.8V配置相关pin。子卡有QSE转排针/CSI2QSE资料，不自动表示存在外部RAM、SD卡或高速USB子卡。相机已经占用的lane、控制脚、电源不能同时授另一个driver。 |
| SD/SDIO | 本轮限定V4ROOT文件名/手册及相关demo的定向检索未得到实际SD/SDIO连接/设备/匹配工程证据；不声称所有电脑资料或板上绝对不存在。当前不能以它出具生产存储方案。 |

新核源码均原HDK只读。令UARTROOT=`V4ROOT/17_Ti60F225_uart_demo/17_Ti60F225_uart_demo`，GEROOT=`V4ROOT/04_Ti60f225_GE_demo/04_Ti60F225_tse_hj_demo_v5`：

| 精确相对路径 | SHA256 | 阅读事实 |
|---|---|---|
| UARTROOT/src/top.v | 40F08864C60F6ADC208500A78B222A73817BBA3D09A3B1A60D1478AC5D42A60E | 全文；115200/27M、FIFO128及旧reset常量。旧top不是新byte service |
| UARTROOT/src/uart_v3/uart_rx_tx.v | F82D6A1EAB269B0D85C4AFA1DF517283B7FD7D98CB0F36D185153C1221BC0EE6 | 全文；STOP编码、分频与未接错误，不借此宣布可靠协议 |
| UARTROOT/top.xml | 301B3A723ADBD6283963B3DF50AFCF27CC2317BCA21103D382B14D9DCE53988D | Ti60F225/C4，不能冒充当前I3完整工程 |
| UARTROOT/top.peri.xml | C8267E62CBA2590834F21AB594115ADF40863DF46F9A27267D85E58392634936 | 定向clock/GPIO/UART映射；2025.2.288.3.8 |
| GEROOT/rtl/top.v | B9362FF9BA347ED5DB13137521293B0EF80DF7D83B64B259FD5165A4475FF535 | 全文；UDP测试、rxc/MDIO、PLL lock与旧常量reset，不是可用事务存储协议 |
| GEROOT/led_demo.xml | BF7E1BA9DBF019EA32412575F5F45ABD8D7537A7C31489199C76E684BAFBD894 | Ti60F225/I3、2025.2.288.3.8；旧last_run_state不能作为本轮PASS |
| GEROOT/led_test.peri.xml | 5D61DB101BFE6ECB388E7FEC32B6015922A835E8F78F98A02ED9EFEDFA55143A | 定向GPIO/PLL；RXC=P09、CTL=N08、RXD=N07/N06/P00/N05；TXC=P07、CTL=N00、TXD=P06/P05/N09/N10，均GPIOL的1.8V资源；MDC=N11/MDIO=P11，PHY reset=L_01/3.3V；RX PLL_TR0 ref125。最终球号/板电源/新并存合法性仍未生成 |

这些GE资源与camera top区域和HDMI right区域在已列资源名上不同，但不据此宣布完整pin无冲突；旧GE iobank配置TL/TR1.8V与所选板来源的HVIO3.3V文字需逐脚/电源网核对，不能拼贴两份peri。无新设备/安装/网络动作。

### A2. 最新允许板载DDR后的10/v7只读证据

精确归档为`D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v7.rar`，SHA256 **9822ACA49F9D41F3948C814FE7527C69F53D1C03A232A9D28FBA42018CD084F4**。仅`tar -tf/-xOf`及内存读取/hash，不解压写盘、不运行工程。下列member均相对归档内`Ti60f225_sc431hai2hdmi_v7/`；member hash按原始字节计算，不把归档hash冒充源码hash。

| member / SHA256 | 实际读取范围与事实 |
|---|---|
| ti60f225_oob.xml / 9A07E957941CE3334B92B97F27EB173A1BA293B83CDB01F70B73ECA411B741D0 | 头部器件/语言及相关源清单：Ti60F225/I3、Efinity2026.1.132.1.2、SV2009；不是仅同名generic board |
| ti60f225_oob.peri.xml / 884225E0EA6554EBA62192CA03D49F8265121E069830FA09EE41694980148605 | 定向bank、clock/PLL、camera/HDMI/DDR及控制GPIO；同份peri已经同时列这三类接口，不能称资料无现成组合 |
| rtl/ti60f225_oob_top.v / D22074352D6F895056852B66B8F2DEE77B9BC45D39D4BCFFA4BFD3876A2F0141 | 接口、1080p常量、CSI、framebuffer、Debayer、pixel/DVI及reset相关段；顶层1058行的相关范围读取，不宣称已审每个旁路和调试体 |
| rtl/frame_buffer_V4/frame_buffer.v / A22FBEDF67FD3DD6364AD215B4E1ECD2D64C60783FC2740E0B526E6C1D52CB09 | 参数/连接/输出计数、内部异步FIFO与frame start相关段；现framebuffer是RAW8而非RGB888对象服务 |
| rtl/ddr3_controller/ddr3_parameter.vh / 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 | DQ16/AXI128/ADDR32/CK_RATIO4/ASYN_AXI_CLK1、ROW14/COL10；参数不能直接当实物容量/功能证书，最终器件geometry由根冻结 |
| rtl/debayer/debayer_top_2to1.v / F6240A41141046CE9888CFF98A5E59FB18CE81B7E7DE46DC2DB70C8F144B6DD9 | 接口/8bit gain、插值输出与RGB48排列；输入RAW16是两个RAW8，低半为r/g/b低像素、高半为后一像素 |

实际组合：camera CK=GPIOT_PN09、D0=PN07、D1=PN10、D2=PN06、D3=PN11，2A/2B1.2V；SCL=GPIOR20、SDA=R18、reset=R16，3.3V，分别映前述D12/B14/C12球号来源。HDMI CLK=GPIOR_PN10、D0=PN13、D1=PN11、D2=PN12，3A1.8V；板PN反接由top四路取反补偿。DDR data在GPIOB、控制部分GPIOR，3B/4A/4B1.5V SSTL；例DQ0=B_P12、DQS0=B_P15、CK=R_P09，完整16DQ/2DQS/addr/BA均在同份peri。camera/HDMI差分资源名的09/10等数字属于不同边，不能因为数字相同判断冲突。实际球号、板电源和新完整top唯一driver仍须逐项闭合；现combo存在不等本轮PNR/STA通过。

top active HACT1920/HFP88/HSP44/HBP148、VACT1080/VFP4/VSP5/VBP36，总2200×1125；USER_PLL ref27，vid_clk_dvi2/hdmi_tx_slow/fast分频40/20/4，按其feedback55给74.25/148.5/742.5相关候选。DDR_PLL ref25输出sdram400与#4 clk100；实际top core100来自MIPI_TX_PLL，`axi_clk/core_clk`两端都接这个core，且参数ASYN1；不能把未使用的DDR_PLL#4和现core仅同频当同步。RX PLL有pixel50/CFG5候选且reset/lock属性不完整；CSI byte仍由camera clock，频率证明由共同baseline负责。

frame_buffer实例I_VID_WIDTH32/O_VID_WIDTH16、AXI128、FIFO1024/1024、BURST127、FB_NUM3、MAX_W/O_W960、H1080；vin为四个RAW10各取高8（39:32/29:22/19:12/9:2），**丢掉低2bit**。读出两个RAW8，CVO PIXEL_NUM2/H1920/V1080，再在vid74.25插值出RGB48；pixel148.5通过vid_cnt交替半字进入DVI。bank_switch旧间隔公式MAX_W×H×I_VID_WIDTH/8＋512，例4,147,712B/slot，是旧分配公式而非已核完整RGB帧大小/本算法目录。frame字节实际数由输入de计数确定，MAX_W960本身不能证明相机实际采集尺寸。旧swap/reset/FIFO清空没有新immutable bundle/borrow/CLOSE语义；新源须保留完整RAW10后最后量化，RGB封存6,220,800B，与低/高lane及R/B接线/可选gamma逐项独立校验，不能直接继承demo gain/gamma/交换得到原彩色正确结论。A3已恢复到当前设计范围且未完成，板载DDR真实封存/回读/冻结义务须联合设计。demo未用DSI/音频/debug端口不可无证按免费资源保留，也不可让完整算法扇出被优化删除。

Flash补证仅作板载辅助：LOOPROOT=`V4ROOT/11_TI60F225_MIPI_CSI_loop_demo/Ti60F225_csi_rgb_4lane_loopback_1p4Gbps`。其`embedded_sw/soc/software/standalone/spiReadFlashDemo/src/main.c`（A47B796D72D11EA3E1B80FCDBDBE47BA3C6ADDBFA50E59357F29084005B335CD）与`embedded_sw/soc/software/standalone/spiWriteFlashDemo/src/main.c`（285B17CD382D3E793CB5733293E485D6F16D58E702DCF3CBE2444F1B4F993325）两份实际全文只读。前者mode0/CPOL1/CPHA1/divider10，每字节03＋24bitaddr读0x380000起124KiB；后者06/20擦除、02写256B、05每1ms轮询/400次退出，注释400ms不是芯片官方最坏界，超时后返回亦不证明写成功。相同standalone/driver/spiFlash.h hash7A6E3CC8963B6566B608F87D0FE800314E7D8F4B1F7A69288D38B4D5027280CA含0B/3B/6B单/双/四线读且明确需硬件接全数据脚。其`embedded_sw/soc/bsp/efinix/EfxSapphireSoc/include/soc.h`声明100MHz（CEEB7CBD858F10DE224BD8A4E81DC4BCC82087CB48D7A1CACC1489A2084D4C22），实际top/peri没有SPI接线命中，故随包软件不能证明本板实时SPI clock/pin/工作分区或当前运行。没有取得GD25LQ64官方速度/擦写寿命/与bit共用的完整依据，不以8MB全容量作为可用视频RAM；本轮不安装PDF工具或运行Flash代码。

## B. 整体行为、能力边界与当前可行性

| REQ | 从生产边界可检查的保证 |
|---|---|
| PIO-REQ01 | SC431HAI彩色完整1920×1080 RAW10，经同源明确phase/边界/一次量化生成完整RGB888；不将RAW高8位截断或IMX219模式替代它。 |
| REQ02 | 基础五项与全部高阶六项：原median、阈值动态CFG、完整八邻域Canny、原彩色overlay、圆/旋转矩形/标签及原P/R目标由完整算法RTL承担；本I/O不缩小场景或代算。A3恢复设计范围，当前尚未完成。 |
| REQ03 | HDMI clock合法时固定1920×1080@60扫描；源/计算fps独立。模式0…5数值与新REPLAY一致，RGB/EDGE/ANN必须同bundle/历史CFG。 |
| REQ04 | 不可反压CSI和固定扫描都有真实有限容量与服务期限；overflow/underflow明确失败/safe，不把拒帧或safe当正常负载通过。 |
| REQ05 | 唯一CONTROL/V/O/provider分配身份；physical applied/retired为真实事件。已held消息/pending/borrow按原owner关闭，取消ACK/RT不自动释放物理显示引用。 |
| REQ06 | 板载DDR/摄像/显示实际连接/clock/pin、电气/CDC/reset和完整资源有来源、设计与获批后真实证据；PC只仿真/黄金/观察，不把其array、四pin或局部CRC升格。 |

显示总扫描2200×1125×60=148.5Mpixel/s，active=124.416Mpixel/s、62.208Mpair/s；124.416M是像素率，不是RGB字节率。SRC每帧6220800B，60Hz读373248000B/s；加EDGE259200B/帧和ANN518400B/帧，mode5每刷新原平面最低419904000B/s（还未含算法/采集/协议）。每row源平面6480B，期限14.8148148µs；只读合成RGB也要5760B/row、373.248MB/s。UART旧上界和GE125MB/s均不能直接持续为每次刷新提供原RGB全图；压缩、跨帧只传delta或缓存完整合成帧是新结构选择，不能无证宣称等值/最坏带宽足够。

当前41,113,469B是现行RC17,526,269B＋SRC/GRAD/唯一EDGE＋保守CLASS/QUEUE示例，不含目录/journal/profile/对齐/本地cache。它来自当前多遍拟合、完整bundle/回放和冻结选择，**不是赛题信息论下界，也不是所有算法必然同时驻留的最小量**。Ti60 RAM256×10240bit=327680B，当前直译数组无法全驻留。仅Flash/UART/GE而不许生产外部存储时，现资料没有支撑完整旧图RGB冻结反复回读和现多遍工作集的已冻结方案；camera行式Debayer/median/Sobel等可形成局部流路，但跨图八邻域闭包的晚传播、同旧图彩色overlay、完整识别/ANN与冻结60Hz的义务不能由几个行缓存消除。此历史差距不是简单批准即可消除，更不是已证明任何新算法必然不可能。

最新允许板载DDR3后，主候选改为**板载DDR3＋全部可综合RTL算法/STORE＋新bulk row renderer＋持续VIEW physical hold**。现有10/v7组合给真实接口来源，DDR业务raw字节存取不得替代可综合STORE的CLAIM_APPEND/state+enqueue/latest/phase commit或DENSE_ADD16/RMW/count/commit/ledger/close。只用板上器件，不加外接RAM/存储模块；PC不承担生产arena/预计算/存储托管。算法scratch、SRC、EDGE/ANN全部落真实DDR或已预算片上容器。此路线能消除当前工作集仅靠片上RAM的结构冲突；DDR几何/区域/服务曲线、新bulk吞吐、整机资源/时序仍需要设计和获批后证据，不能由demo名称或容量算式自证通过。GE/UART保留调试，Type-C不假称USB视频DMA。

正常样例：预授完整source build→ARM保存→下一完整SOF→接收closure和RGB写seal均真成功→S注册→旧C锁J→完整算法/私有ref退休→O注册COMPLETE→V采用/显示prefetch→真实VSYNC切换→旧读/row/adapter退休→返还。边界：最后像素后CRC到达，已数满N也不发布。失败：显示某行未按期完整，scan不暂停，自第一个缺项起本scansafe并报partial；正常验收仍须无此故障。

## C. 唯一owner、整体连接与生产差异

| MOD | 唯一职责与所有权 |
|---|---|
| PIO-P PLATFORM | AON/clock健康、跨域会话与reset隔离；不第二次写软件epoch、不代provider证明关闭。 |
| PIO-C CAMERA | CFG/资格、实际CSI adapter、capture_id、RAW/RGB历史、source write session及错误closure；不直接写J/C/V或分配result_id。 |
| SRC_PROVIDER / VB-S | 真RGB内容/封存/读取/返还属于provider；S唯一source_image_id及注册/offer86。capture_id不是source_id/job_frame。 |
| AC-CFG/J、R4/STORE | 原唯一CFG/job owner与完整算法；可综合STORE承担CLAIM_APPEND/state+enqueue/latest/commit及DENSE16/RMW/ledger/close，外部仅raw字节读写。 |
| VB-O/V | 原唯一bundle/父ref/borrow/plan owner；生产重复采用与新物理hold必须合并到同owner，不另设第二VIEW writer。 |
| PIO-F FETCH/RENDER | 只借已COMPLETE同源planes，bulk row读取/组装、同REPLAY数值的有界一pair/core流水，写三个immutable渲染RGB row bank；真实访问ledger由对应provider负责。 |
| PIO-D SCAN/ADAPTER | 固定scan、row借用、真实APPLIED/scan关闭、相关pair/pixel及serializer引用；不释放O对象、不把时序位置当内存资格。 |

整体路径：SC431HAI/D-PHY→CSI规范record/独立fault→asyncFIFO→RAW10 Debayer→板载DDR SRC write/seal→S_REGISTER/offer86→CONTROL J657→完整算法/STORE＋DDR scratch→O COMPLETE→V788/历史PLAN→板载DDR新生产bulk fetch/renderer→三row bank→pair74.25→pixel148.5→TMDS10bit→half-rate fast742.5→HDMI。DDR frontend以真实AXI R/B终结、版本化grant及效果账本封存/关闭；在途事务未关时不能重分配物理区。控制/错误/关闭邮箱独立于数据FIFO、row、观察读回。按键仍由AC-KEY同步/消抖/提交；相机I²C与算法阈值配置分别锁代次。

**必须联合改的结构**：现VIEW单SRC/J/BUILD/COMPLETE/V/borrow，每V只一个PLAN；正常RT/EXIT后RETURN并退休。持续显示须V保持同一完整父引用直到物理退役，每刷新分配新PLAN/display和独立读borrow，不能在RT后已free的原图上重新读。要旧图显示与新BUILD并存，候选source2、BUILD1、结果目录2，current/candidate/retiring合计最多2个不同bundle；旧retiring未关时禁止第三BUILD。不是已批准容量。保守DDR工作示例41113469＋旧SRC/EDGE/ANN/RECORD7002496=48115965B，不叠加第二套scratch；是否真实同活、旧profile/目录/安全复用仍逐项证明。64MiB逻辑arena可作为板载DDR内候选，目录/journal/profile/对齐上界与板上实际geometry绑定仍待冻结；它不是额外设备或已经physical fit。若坚持单slot，必须说明采集如何停/拒及重建期间显示从何处读旧源；不能同时声称任意持续采集和无断流全功能。

容量有两档未合并候选：上段是本PIO的**2source/2bundle**受限并存档；根/PERF提出的是**6source/3bundle**保守档。本稿后续两bundle、三scan metadata及相关FF/停止第三BUILD规则仅绑定PIO档，不把它们冒充PERF档，也不把48,115,965B例子用于证明6/3总容量。选择6/3时须重新统一source/结果目录、父引用/borrow槽、同活容器/DDR区域和背压规则；两档尚未共同选择或冻结。根提供的PERF最终hash A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469及DDR报告F3492D3D4E7AB0B3B9247AD2A44859F0A52DCE282BC9D7F2A8CB0B8646F3E942是上游通知，本轮未实际全文读取，不列A表为本Agent已审来源。

## D. 接口、逐连接检查与明确新schema

### D1. 摄像边界候选（全部待合并）

所有新增typed消息本域posedge沿前valid&&ready且非rst才fire，新接纳不穿透。命名字段列高到低；不是已生成端口。capture_key96=epoch32/capture_id64，捕获序号每epoch从1递增/扩65检耗尽；最终source_id由S在真实封存后另分配。相机模式cfg_generation64与CONTROL config_id32不同，必须同时保存历史，不cast。

| IF | 候选字段/位数与契约 |
|---|---|
| PIO-IF01 CAP_ARM280/ACK287 | epoch32/capture_id64/source_handle64/cfg_generation64/link_session32/W11/H11/phase2；ACK回原280/status2/reason5。provider预留完整源及写权限，fault/closure容量和seq预算先准备；pixel保存ACK不是SOF，保存同沿SOF按旧ARM不接纳。 |
| IF02 CAM_ITEM220 | RAW64/payload_valid1/flags4/PPC4/DT6/VC2/VCX2/WC16/short16/error8/capture_key96/key_valid1；key_valid0时key96规范零，仅观察而不写业务源。规范化候选沿旧NORM规则，底层实际PPC/packing/metadata对齐未证明，不能凭名称连接。 |
| IF03 RAWPAIR142/RGBPAIR170 | raw20或RGB48＋x_even11/y11＋SOF/EOL/EOF3＋bad1＋capture_key96；RAW lane0低10，RGB canonical={R1,G1,B1,R0,G0,B0}。phase/cfg/source完整280ctx pin，不逐项复制。 |
| IF04 RX_CLOSE295 | capture_key96/cfggen64/link32/rx_closed1/error16/raw_count22/fifo_committed_watermark64；独立depth1，不等满数据FIFO。consumer达到该会话连续水位且旧holding/RE/odd/窗口处置后才闭合；错误所属/最后watermark的真实CSI依据仍OPEN。 |
| IF05 CAP_END327 | capture_key96/cfggen64/raw_count22/rgb_pairs21/writer_bytes32/error16/closed_flags5/status2/reason5/commit64；五flag为receiver、consumer、local、write effects、immutable commit。正常须N/P/6220800B、无错、真实token和全closed；失败也报真实前缀，Q无drained推定。source handle从pinctx恢复，不让坏body解别人ref。 |
| IF06 SRC/O | 采用当前SRC_REGISTER156/REPLY228、source_offer86、J657/V788/完整CERT352/对象注册及返还；success flags不能由CAM_END复制自证，provider实际封存/目录必须核同源。原旧scope623/grant241/Origin195不转换为新logical ref或保留MC依赖。 |

ACK status候选0APPLIED/1ALREADY/2BUSY/3REJECTED；reason5命名错误族需与共同schema最终冻结。独立业务done与运输ACK分开。cap新字段、旧CFG186/观察/资格撤销的logical epoch映射、CSR map和producer闭合能力仍PIO-B02/04，不以本文位数声明ready。有效norm候选RAW低四个10bit、未用lane零，payload0时RAW/PPC/DT/WC零；SOF/SOL及末EOL/EOF同项按开始→payload→结束且metadata同row，否则拆项。原CSI没有ready；CRC/ECC不能只截debug32低8。

### D2. 生产显示与当前REPLAY的真实差异

PLAN616原job/source/result/render/display/plan/尺寸/algorithm/profile/render字段保留命名含义；scan_token64由PIO-D每实际物理VSYNC分配（非plan_id），V唯一分配新plan/display并绑定scan目标。旧PLAN提出后保持；物理apply须complete、首行ready、所有事件槽及旧扫描预算可用。不能把V_ACK104或OPEN成功当HDMI APPLIED。

现BR-P每次只一个当前未JOIN pair；最早RQ e0→RR e1→JOIN e2→下一RQ e3，因为RR及JOIN各须后续沿、JOIN不能穿透创建下个RQ。core100即使无外部等待也约≤33.33Mpair/s，低于62.208Mpair/s。**现OUT404＋行bank不能直接作为60Hz生产引擎**。OUT404仍供可暂停重放/独立等值验证；生产主候选新bulk row provider＋有界prefetch及一pair/core renderer，借同一O真实planes/历史render。不能悄改BR-P单credit；新请求/响应/分段/close/ACK的packed schema和provider内部实现是联合冻结项。

新bulk命名需求：完整H=job/plan/display/borrow、plane、source_y/target_y、row_seq、原图有效byte/bit范围、beat_seq/last、读取成功/失败与最新immutable版本；每口独立credit/held reply、截止真实接受数、read/effect/response/pin证书。原RR421/CLOSE338只适用于其既定逐pair族；不把新字节beat强塞同body。新provider须可综合RTL端点执行读地址/校验/流水/ledger/close，外部服务不能生成render/几何/commit。具体新body尚未冻结，故本稿NOT_READY。

row承载已经渲染RGB48，每row960pair。PIO_ROW472=job96/plan64/display64/render_generation64/scan64/bank_id2/bank_generation64/target_y11/pair_count11/link32；OWNED479=原472/status2/reason5；RELEASE480=原472/kind2/drained1/reason5；ACK487=原480/status2/reason5。bank3非法；三bank各自独立ready/owned/release/ACK槽，current/next/candidate不能挤入两bank。数据READY提出后只读，正确ACK及双方pending/holding结清的后续沿才FREE。kind0CONSUMED/1DISCARDED/2Q，3非法；Q不复用。

物理APPLIED/SCAN_CLOSED/RETIRE事件字段至少完整历史PLAN616/scan64/使用data与正常/partial/underflow计数/rows_closed/pixel_closed/serializer_closed及seq；event槽各depth1，具体body与新V接口PIO-B04。APPLIED只在真正切换的VSYNC；一个current_exec、一个future目标（至多两route）、一个旧closing scan metadata，引用最多两bundle。prev scan关闭ACK未結则新物理帧safe、不建立第三图执行上下文。未选candidate行合法DISCARD，不等待不存在的CLOSED。原source CLOSE、REPLAY RELEASE只关对应borrow；物理父ref直到真实retire后才RETURN，不自造第二borrow owner。

### D3. 服务期限与有限容器候选

单帧基本量及吞吐见B。每row读取6480B到渲染row5760B，应在active行期限前ready；每100MHz core一pair的960沿只是9.6µs算术下界，余5.2148148µs还需全读/请求/close/CDC/调度（读取与计算可合法重叠，但未证明）。显示active>capture>算法只是候选仲裁优先；必须给持续带宽及最坏服务曲线，不靠RR或平均值。candidate首行预留不能饿死current/next，已held事务不能抢撤。

| 真实有限容器候选 | 本地容量/寿命与计数边界 |
|---|---|
| camera ingress | CAM_ITEM220×1024封装220，22条20×512 RAM；这是新220族替换旧192/20RAM，不叠加。地址10/wrap1，读两holding＋reserved≤2；名义50MHz四像素/沿是峰值假定，不证明CSI规范记录最坏率。 |
| RAW历史/ROM | old CAMERA两RAW10 pair行各960×20共4RAM；164条25bit配置ROM两20bitword/条共328word/1RAM。旧Bayer四phase/reflect101及最后一次舍入保持，真实phase未冻结。 |
| source write buffers | 两个1024B bank采用旧候选四条RAM结构（不因总bit下界私改端口）；唯一writer/carry/写料从seal到真实AXI写/B及会话关闭不能重写。新SRC_PROVIDER写会话必须绑定真实DDR范围grant，不能拿旧MC地址/逻辑ref直接驱动AXI；接口待联合冻结。 |
| optional live fork | 512×80/4RAM，FP74高6零；只复制真正RGB fire，同源失败作废，队满取消整job。可先不采用此支路，由完整SRC重放供算法，不能同时删source保障。 |
| rendered row3 | 每row46080bit=2304个20bitword；lane=w mod5、addr=floor(w/5)，每row5RAM、三row15RAM。pair起q=floor(48p/20)、shift=(48p)mod20，3/4连续word落不同lane，一RAM一RE/沿；拼接取48后canonical，颜色不能按字节地址倒置。最后有效word2303，lane3/addr460；物理尾无访问。只有core完整写/pending关闭后跨域READY。 |
| core/PAIR data holding | 独立可暂停验证支路两OUT404=808bit若采用则另有真实容器，不能与生产row renderer自动共享；生产writer暂存160+19+两RGB48=275bit候选，PAIR两RGB48=96、读max80=80、六slot各RGB48+HS/VS/DE3+valid1+scan_ref2+x_even/y22=76bit，共456，合632bit候选。两holding的valid+reserved≤2；scan_ref仅引用已pin三ctx，3非法。此632不是旧STORAGE543的扣减/综合结果，旧54plane槽不隐含保留。 |
| ctx与消息 | capture当前+closing最多2×280；RAW2×142、RGB2×170、NORM2×220，RX_CLOSE producer/consumer2×295，CAP_END2×327；每个valid/pending/计数/序列、独立CFG/fault/control/ACK另逐项计。ROW族三bank每方向源held＋目的private均实存：6×(472+479+480+487)=11508bit，仅body下界；状态/同步器/其他事件不可计0。 |
| display context | current/future/closing最多3×(PLAN616+scan64)=2040bit候选；通过slot ref引用pinctx，不每pixel复制J。两个完整bundle与O/CTRL/provider的已有保持域不重复计或无证删除。TMDS disparity/pipeline、完整raw服务缓冲/metadata、所有producer/consumer mailbox/控制计数预算仍OPEN。 |

ROW的双时钟不是READY赋予的能力：实际EFX_RAM10模型37–39/124–125列独立WCLK/RCLK，330在posedge WCLK_i写、358在posedge RCLK_i读；20bit模式的9bit地址支持0…511。因此上表可采用core100写/pair74.25读的一读一写双clock RAM10候选，无须武断另换DPRAM10。每bank仍要完整写/pending排空后跨域immutable READY，消费RELEASE/ACK且读pending/holding关闭后的后续core沿才复用；模型26–28明确同地址读写行为未定义，不能依赖其碰撞模式。该源码事实支持原语能力/几何，**不是实际综合映射、CDC、STA或生产时序已通过**；最终实例参数/时钟连接必须与实现报告核对。

根另给双row54bit/pair高6bitpadding为60bit、每row3×512depth×2=6RAM/两row12RAM候选，以及6480B/row=405个DDR128beat的算式。本稿仅记录这一未吸收的另一布局提议，不把12RAM替换已列三row渲染RGB15RAM，也不将两者一起当同套冻结预算；所需plane处理、CDC/FIFO、deadline、控制/holding和与candidate首行并存均待联合比较。本Agent本轮未复核该布局全部逐沿合同。camera mandatory新候选22+4+1+4=31RAM，生产renderrow15另计；可选live4不默认常驻。总RAM/FF/DSP/PLL必须与新R1/R2/R3/R4/STORE统一同时寿命表，不借旧162/174/225结论。renderer若需额外未合成plane行scratch或并行cache，必须实际加入，不把15RAM当含全部fetch缓存。任何FIFO深度都不能抵无限后台阻塞；camera无法暂停时，冻结其最大突发、按Bburst＋R×Tstall＋在途/拆record计算容量，超界只能整源失败并禁止发布，正常通过须证明不超界。

### D4. 时钟、pin与约束候选（无SDC实现）

| 真实边界/来源 | 新方案与仍需冻结项 |
|---|---|
| 25MHz J2/1A1.8V、27MHz H2/1B1.8V | AON直接25。优先候选为DDR_PLL#4 clk100同一net作为core/AXI业务域并同步ASYN0，CSI pixel50/CFG5由一独立PLL提供；新方案须联合批准，不把现v7的MIPI_TX_PLL core100/ASYN1直接称同步。GPIO业务I²C可用core100的20周期enable表达5MHz逻辑节奏，但若底层要求独立5MHz则另列真实输出。DDR冷初始化/校准/cal_done、PHY相位和真实输出reset/lock须保留，不能沿用排除DDR阶段的删除建议。真实VCO/divider/SDC变化与内部握手由根共同baseline冻结，不编造配置。 |
| HDMI USER_PLL | 保留ref27的pair74.25/pixel148.5/fast742.5相关关系；fast phase_setting2仅旧参数，不当采样裕量。每pair低24 lane0、高24 lane1，全部HS/VS/DE固定同延迟；实际首pixel相位、word load/10bit首位/双沿和reset须冻结。未证明前B07。 |
| CSI clocks | control core100、pixel50候选；byte由相机CK输出/可停钟。A表旧v6活动5.15 HS_BYTECLK70与旧SDC100冲突，不能任选；其另一5.16/FIFO2048/50不是同配置。A2 v7的实际IP版本/参数由本轮protocol来源核定，未核前不继承5.15为v7冻结事实。EXTCLK6–40MHz是芯片能力，不自动表示模组由当前FPGA某pin提供。 |
| camera pin | CK E8/D8；D0 B8/A8、D1 C8/C9、D2 B7/A7、D3 B9/A9；2A/2B候选1.2V。SCL D12/SDA B14开漏，仅驱低/释放；reset C12候选3.3V。模组FPC顺序/排线/电平转换/XSHUTDN极性仍OPEN，不从裸芯片DOVDD1.8V判断板3.3V可直连。 |
| HDMI pin | 板CLK P/N=H12/H13，D0 F15/G15、D1 G14/H14、D2 F13/G13，bank3A1.8V；板P接FPGA N，补偿只在serializer码字边界一次。专用TX唯一driver；common-mode/TMDS电气生成仍OPEN。TX HPD/DDC/CEC在SCH页13为NC，固定模式不假造EDID。 |
| UART/GE | A1列实际资源，仅调试/观察/控制，不托管生产arena；各自RX与core用真正CDC。GE125MHz/RGMII DDR/pin-skew/PHYdelay/时钟方向若采用则重新设计，旧RX PLL_TR0不能无证与已使用TR0的DDR PLL拼用；默认GE不进入生产必需top，调试选择也需全机pin/PLL预算。 |
| reset/key | KEY1 P13/GPIOR27、CRESET_N J5来自SCH/封装证据；板说明旧KEY/LED表有错名与旧binding，不直接采用。说明只记4LED和2按键，现资料不能默补四个物理KEY；四逻辑操作到现有按键/长短按的适配须共同设计并明确影响，完整实际全表需逐板SCH/pin追踪后冻结。reset长按由AC-KEY请求RESET，不能直清FIFO/PLL。 |

约束未来建立真实25/27参考及实际generated clock，不把相关HDMI域exclusive；CSI byte频率按真实发端模式，不凭HS70改100。只对已识别同步器/Gray总线合理限定路径与skew；多位body走稳定mailbox，不逐bit同步或false path掩盖。clock-to-pad/pad-to-clock、专用serializer设置、输入外设时序/输出RGMII相位都需实际源和报告；source pin来源不等合法peri生成/STA。

## E. 中文逐沿草图与关键不变量

### PIO-OP01 配置、ARM和capture

先确认平台clock/电气/模组模式与旧入口关闭→配置请求锁cfggen→按原164条次序访问并逐ACK/AL/读回（旧高层未捕获dout不能复用）→公共ID CD/6B/格式/窗口核验→新观察窗口完整两帧及receiver closure→资格ENABLE。原ROMstream-on后仍19写，不能把Group Hold10上限忽略或无依据重排。

SRC_PROVIDER先预留真实完整源写对象→capture owner预留slot/fault/closure/seq→CAP_ARM held跨pixel邮箱→pixel保存ACK→后续完整SOF才使用一次ARM。没有旧ARM的SOF观察/丢弃不借对象，中途lease不接半图；正式无丢帧证明仍依容量/速率。入FIFO实际WE递增commit水位；同项所有flags按同metadata处理，跨row拆项；满时sticky失败、独立fault/closure不等EOF或数据空槽。

### PIO-OP02 解包、Debayer与source seal

读RE前在两holding之一预留，下一沿capture旧RDATA；即使后级stall也保留原ctx/顺序。RAW最多4样本拆2pair，odd只同row/同key；行/帧末数量核验。row0保存recent；之后先RE旧recent/older、下一沿用旧RDATA计算并WE新历史，不依同址READ_FIRST。四phase/reflect101完整补边，RAW10到RGB8只最后一次舍入/饱和，原彩色完整P。

RGB真实fire写canonical R0/G0/B0/R1/G1/B1字节，记录实际写prefix；sealed bank已借/held写料不撤。全部字节/尾pad在真实DDR授权内完成，AW/W held不随cancel撤，B响应真消费/错误归属和独立write CLOSE/commit与rx closure、水位及本地pending汇合；末RGB/EOF不是成功。读写B/R没有可证明等待界时，超时仅停止新业务并Q在途对象，不能制造drained。CAP_END冻结后持有到消费，provider实际封存后才SRC_REGISTER，坏源不得发布，也不得由FE先OK反证源正确。更换相机cfg不修改已immutable SRC及旧J。

### PIO-OP03 完整算法到生产VIEW

S注册完整SRC→source_offer86，J锁沿前旧C/J/尺寸，先准备所有收集器后发FJ/CJ→stream真status及完整闭包/识别/ANN/私有对象退休证据→O完整bundle证书→V命名采用。新source并存须本文C容量联合修订已获批准；未修改的单slot没有免费下一整图。构建失败关闭实际对象，不能将缺ANN当零目标成功。

### PIO-OP04 bulk预取、row移交与固定scan

V保持历史父ref，独立给下一真实scan分配新PLAN/display；先授真实planes/borrow再读，active current/next优先于candidate。bulk读全部required原plane、检查范围/身份/CRC或协议码/beat及实际pending→一pair/core renderer按原灰度/overlay/ANN优先计算→row writer以旧48bit RGB holding＋旧tail19形成下一stage。单次最多67bit，只写2/3个连续完整20bitword，三lane互异；每bank一WE/沿，WR data来自旧stage，不用同沿新Rfire/新renderer fire。160bit是候选展开stage容器上界，未用bit规范零，不把128bit DDR beat的7/8word直接同沿写进五bank；读beat拆pair和required-plane scratch另计。末尾真实pad word仅写合法地址，末WE旧holding/tail和全部held/backend效果关闭后才PIO_ROW472。READY与OWNED只保存/授读，不当显示。

pair固定h0…1099/v0…1124；HS h[0,22)，VS v[0,5)，DE h[96,1056)、v[41,1121)；x_even=2(h−96)、y=v−41。新candidate仅真实VSYNC且首row与事件容量成立才APPLIED，否则重复已持有完整active或safe。scan不等待core；RE在目标slot前6个pair沿发，下一沿capture合并48bit，后续固定slot流水（六级候选）携带HS/VS/DE/scan ref/coords；具体总adapter延迟在B07冻结后沿表同步修，不凭此候选声称闭合。每pair读3/4互异lane，lane0/1颜色显式恢复。

ROW release只等该bank自己的读pending/holding关闭，复制出值仍持scan/adapter引用，不等scope整体fence造成环。release/ACK真消费后后续沿才能写新bank。错token/target/oldbankgen丢弃原owner值，不补当前slot；超前holding保持但当前safe。欠载令本scan余下safe并真实报partial，绝不暂停h/v或把迟到pair横移。

### PIO-OP05 pair/pixel、重复刷新与物理退休

相关clock采样契约取得前，adapter资格BLOCKED；合法后每pair恰两个pixel：lane0后lane1，HS/VS/DE两次同值且与RGB同延迟，纯色/交替序列独立核色序。TMDS encoder每pixel更新三通道disparity/符号；serializer只消费已对齐10bitword，PN补偿一次。编码/control/首bit/blank/reset的精确规范与复用条件仍OPEN，不以受保护encoder或Demo源码外观自证。

重复相同bundle仍分配新scan/plan/display、取得对应读borrow、关闭该次provider/RT；V保持parent physical hold不随一次RT清掉。切candidate后旧active停止新scan读，已held读/row/像素/码字履约。真正rows_closed＋pixel_closed＋serializer_closed＋实际source close/borrow释放才RETIRE事件；V之后RETURN父引用，O真实对象返还退休。不能等父free才归还row，也不能按最后AR/OUT EOF直接free。

### PIO-OP06 取消、software reset、失钟

同沿先记真实旧data/消息fire，再sticky stop；取消只锁历史J/PLAN，新V同沿不能被旧cancel套用。receipt/ACK独立，不等RT/row；已published请求/回复保持，未exposed私有计算可按旧身份discard。没有EOF的早失败独立close。

software RESET先停止新ARM/job/BUILD/PLAN，保留旧写料、读credit、row和通知→真实source/STORE/NUM/CLOSE/RELEASE/RT/physical RETIRE/parent及对象返还汇合→现VB的QUIET/授权EPOCH_START握手→父commit epoch→重建会话；不因PLAN变化自动清borrow。冷共同rst的合法全体作废另有前提，不能软件reset冒用它。

各异步域async assert/sync release，正常功能rst与旧承诺保持域分开。clock/lock或DDR健康掉落立即阻新业务，仍合法clock下继续旧账；未知像素/serializer/CSI/DDR物理旧效果进入Q，消费Q不释放对象。DDR失去内容可信度后，不用重校准成功恢复旧immutable证书；所有受影响对象按真实失效路径终结。byte LP可停钟，不能用固定安静像素周期作接收closure。两端会话及pending/holding/messages真的关闭后才重置Gray/toggle；单端清FIFO造成假空明确禁止。

不变量：1 key/版本核验后才解引用；2 invalid不加样本、0像素有效；3 valid+reserved≤holding容量；4 已READY bank不写；5 IRQ/closure不依赖满数据FIFO；6 配置/phase锁到历史源；7 parentref和borrow分开；8 当前/未来scan分开；9 两bundle/三scan metadata有限；10 overflow/欠载/Q不发布完整成功；11 DDR明确是板载真实服务且健康/事务/内容资格分开；12 全部算法与STORE在FPGA，PC仅仿真/独立oracle/观察，不托管生产raw存取。

## F. 语言、RTL A–L与三份映射

| RTL项 | 当前合同/未知 |
|---|---|
| A 数值 | RAW10/RGB8、pair48、coords11；RAW count22/pair21/bytes32；端点加33；capture/plan/display/scan/bankgen/cfggen等64bit身份加65、epoch/link32加33先检耗尽，拒绝新分配并关闭旧账，不回绕。phase/RNE沿原CAM数学，真实CFA仍未知。 |
| B 时钟 | 本域posedge沿前fire；RE下一沿preedge capture；pair/pixel/fast由真实相关PLL沿表，不把2:1频率当相容证明。 |
| C 接受 | CSI无ready，SRC/算法/byte服务可按合同暂停，扫描永不等待；运输ACK/业务应用/封存/physical retire分别记录。 |
| D valid | payload0不造黑样本；HS/VS/DE与RGB一起流水；scan计数固定推进，图计数只真实接受推进。 |
| E 保持 | 完整ctx/sideband、held读写料/oldtail/pending不受新CFG/取消覆写；source/row封存保持到真实归还。 |
| F 时间 | 1080p60/行期限明确；现REPLAY3沿下界不能达core100生产，bulk并行是新设计，service/serializer实际延迟仍未冻结。 |
| G 复位 | 暖止新＋保持旧，双端close后初始化；未知Q；冷safe初始化/PLL lock/reset实际规则需要证据。 |
| H 配置 | cfggen与算法CFG ID不同；ARM采样历史phase，J旧C锁定，render来自历史PLAN；同沿新的提交不改旧capture/slot。 |
| I 存储 | 本稿RAM/holding逐组有限，板载DDR实际geometry/工作分区与row scratch/事务journal仍待freeze；Flash不是RAM、hostarray不是生产存储。 |
| J 身份 | capture/source/job/result/render/display/plan/scan/bankgen/link各独立；low lane先，mode0两半sy按REPLAY，不缩算法范围。 |
| K CDC | 稳定body mailbox/业务槽、asyncFIFO Gray、三个只读bank与归还；related video时序单独核。不逐位同步大型record。 |
| L 实现 | Ti60F225/I3、SV2009、Efinity2026.1/Questa现有来源；当前完整project/peri/SDC/PNR/STA/bit不存在通过结论；资源/pin合法性仍OPEN。 |

C++当前不采用；未来参考为获批后独立Python标准库整数/图/事务oracle，不运行或生成。共同数值：独立RAW/CFA插值/量化、RGB低地址字节、灰度/overlay/ANN等值；硬件执行：actual fire/RE/WE/seq/CDC/closure及物理scan沿账本；对应：每capture_key/source_id/JID/CFG/PLAN/scan/坐标记录逐项映全图原RGB/EDGE/ANN和输出符号。软件算法结果相同不能替代CDC/时序/物理retire，oracle不能回填DUT服务。

## G. 实施与验证编排（全部未执行）

先关闭PIO-B01…08及上游生产差异，指定共同版本/范围/基线批准后，在work独立副本实施。顺序：绑定板载DDR实际参数/公开接口/clock/pin及真实raw byte服务＋SRC/工作对象provider/完整typed包→相机配置/CSI规范化及完整RAW10 Debayer→完整算法/STORE→新bulk row renderer/O/V生产扩展→pixel/serializer/真实clock/pin→完整1080p端到端软件验证/综合/PT/PNR/STA/bit登记；bit后停止，不下载/硬件观察。独立四pin/R1/R2/NUM tops只是辅助检查，不能代替全包有效扇出；PC DDR模型在测试中只答raw读写/延迟/错误，不能代算DUT STORE/闭包/识别。

用户对有限IP预检的批准不包含本PIO稿、生产renderer、摄像适配、完整算法/STORE或完整top的实施授权；本文仍NOT_APPROVED，不能据该批准生成上述业务源码/TB/工程/约束或运行整包构建。

| TEST | 输入/事件与期望 | 当前 |
|---|---|---|
| PIO-T01 完整源 | 全1920×1080 RAW10四phase、极值/色块/边界/LSB、独立bilinear等值；全部RGB6220800B，不先截8bit | NOT_RUN |
| T02 CSI协议 | PPC/RAW排列/元数据所属域、尾包/边界同沿、迟CRC/ECC、停byte、满FIFO；有错误不得seal成功 | NOT_RUN |
| T03 配置 | 164ACK、ID/读回、AL/NACK/STOP、stream-on后19写、GroupHold限制、失资格/旧ARM；快照与live资格不同 | NOT_RUN |
| T04 服务期限 | 实际最大服务曲线/突发/延迟、active/next/candidate、capture与算法同时流量；全部row按期且无正常overflow/欠载才通过 | NOT_RUN |
| T05 生产像素 | mode0…5、samebundle/CFG/低lane先、GPIO/clock不同相位、RGB/HS/VS/DE/10bitcontrol/串行首位；固定1080p60 | NOT_RUN |
| T06 生命周期 | apply/cancel/末row/RT同沿、wrong key、旧scan晚reply、独立close、Q与warm reset；借用/parentref到真retire才返还 | NOT_RUN |
| T07 全功能 | 完整N的median/阈值/Canny/原彩色叠加/圆旋转矩形ANN及原P/R/IoU评价，不恢复尺寸/数量噪声硬边界、不排失败帧 | NOT_RUN |
| T08 全包工具 | 真实source/transport/camera/HDMI到pad、所有算法/STORE有效扇出、当前I3配置/许可、generated clock/pin、map/PNR/STA与bit | NOT_RUN |
| T09 反例 | 仅UART/1GbE反复送全RGB、当前单pair BR100直供60Hz、V RT立刻free但仍扫描、单端FIFO清空、把safe当正常通过必须被拒绝 | NOT_RUN |

未来测试下降沿驱动同步输入、posedge后稳定区观测；多域调度/种子/期限要绑定实际服务与时钟规格。完整1080p是验收，小图仅局部补边；不能先跑未批准IP/功能生成器再“反证可设计”。模型/代码生成和工具运行分别遵原批准门槛。

## H. 双向追踪

| REQ/来源 | MOD/IF/OP | 未来文件/职责（未生成） | TEST |
|---|---|---|---|
| PIO01 / SC431/CAM | P/C/SRC，IF01…06，OP01/02 | camera_config/csi_adapter/raw_window/src_provider | T01…03 |
| PIO02 / 当前BATCH/RC | AC-J/R1/R2/R3/R4/STORE，OP03 | 全算法/定点/完整对象服务 | T07/T08 |
| PIO03/04 / B4/DISPLAY/REPLAY | V/O/F/D，D2…4/OP04/05 | production_row_fetch/render/scan/adapter/serializer | T04/05/09 |
| PIO05 / CONTROL/VB/BR | 原owner＋生产适配，OP06 | lifecycle/cdc/quiet/epoch/bank return | T06 |
| PIO06 / 源pin/工具/v0.2 | P及完整top，F/G | 实际project/peri/SDC/trace/bit登记 | T08 |

反向：新row缓存只承担不可暂停扫描的已渲染值保持；SRC与scratch由真实板载DDR及已列片上容器承载。GE/UART只有声明的调试/control职责；PC只在软件验证中提供raw存储模型/黄金/观察，不是生产byte server，也不承担DUT Canny/NUM/识别/ANN/STORE原子性。每个物理driver/RTL单位必须能返回上述requirement与真实来源，不用无扇出stub满足文件清单。

## I. 门槛与最小真实OPEN

| BLOCKING | 精确待冻结项及下一允许证据 |
|---|---|
| PIO-B01 | 板载DDR实际型号/geometry/时序/工作区域、选定controller版本/公开AXI128接口及内部等待/refresh/cal对deadline的影响。现v7 ROW14/COL10、ASYN1及旧FB不能自动继承到新完整对象服务；根共同DDR来源/baseline审查与服务设计需闭合。Flash/UART/GE不足的历史诊断不再挡允许DDR的主路线，但也不能用批准本身当已有性能结果。 |
| B02 | 模组SKU/FPC/电平/EXTCLK/SID/XSHUTDN、完整1080p RAW10模式生效/CFA、选定v7真实CSI版本/参数及metadata/PPC/错误归属/最终closure。旧v6活动5.15证据不能直接替代新baseline；公开overview未给完整行为，必须版本化官方依据/获批后真实IP检查，不用理想record测试替代。 |
| B03 | 新PLL/core/pixel/byte频率、各域冷FF/lock/停钟/reset初始化和双端会话关闭；真实相关clock生成及复位输出隔离。 |
| B04 | 与现CONTROL/VB/BR/O/STORE共同冻结capture/source、生产physical hold/重复PLAN、bulk row协议、APPLIED/retire事件、目录双slot/两bundle、关闭/epoch及全部有限状态字段；本文新增schema尚未合并。 |
| B05 | 不可暂停camera的到达率/最大burst/帧接纳、采集与算法fps、显示严格row deadline、old/new并存服务曲线及完整本地cache/资源预算。未支持的政策如拒帧须明确范围，不当稳定采集通过。 |
| B06 | 当前I3器件/封装、原理图→板电源/实际跳帽→球号→新peri/driver全表，四key表、DDR与camera/HDMI并存电气/资源。GE若选作调试另核TR0冲突/CDC；禁止外接模块/PC arena。v7已有组合来源，存在旧参考仍不等新完整top合法。 |
| B07 | TMDS编码/复用条件、single/pair固定延迟、pixel/fast half-rate相位/word load/首bit、PN只补一次、common-mode与reset旧pipeline排空；需要精确设计和获批后的软件/STA证据。 |
| B08 | 完整工具/源schema/profile/设计共同baseline、全图独立oracle/协议/quality/限时/trace、正式执行条件及指定实施批准；本轮没有源码或运行。 |

规范§10.3：整体B、职责C、接口/反例D、中文E、A–L/三映射F、验证/追踪G/H已有内容；无当前阻塞不满足，接口和实施基线未冻结。保存读回不关闭这些OPEN。状态LOCAL_DESIGN/NOT_READY/NOT_APPROVED/NOT_RUN，不能轻率升为生产或整包READY。

## J. 相对上游的差异与恢复

仅新增本文，不改旧CAMERA/PLATFORM/DISPLAY或新CTRL/REPLAY/VB。最新范围恢复允许板载DDR但不恢复旧scope/MC与新logical source/STORE的等号；必须显式地址grant/物理session映射。旧NORM192拟换220，旧row336/plane54改新472/renderedRGB48，新clock/control与DDR健康需要联合修订。当前BR可暂停单pair和VB单PLAN/单slot明确保留为原合同；生产bulk/hold/双slot是重要新提议，不能把本文当原稿已具备。恢复重核A源hash和真实用户范围，READY/实施批准绑定统一版本而非单份候选。旧仅非DDR/PC raw服务路线已被最新用户资源边界替代，不并列为生产选项。

## K. 实录

只有既有文件/metadata/hash/定向目录/原源码/归档member只读与授权新增本文；没有业务RTL/模型/功能脚本/TB/project/约束、工具功能运行/仿真/构建、网络/安装、硬件/外设操作或正式状态/DB写入。所有验证NOT_RUN。用户恢复允许板载DDR后只定向核10/v7公开top/peri/参数/帧缓冲连接；无执行PHY/校准、IP生成或器件激励。PDF技能用于只读定位合同，没有新PDF/图片/中间文件或安装。

## L. 阅读与下一动作

先A1看非DDR辅助与历史诊断、A2看最新允许板载DDR的真实10/v7来源→B算完整范围能力→C看唯一owner与生产结构差异→D/E核字段、期限、CDC/关闭→F/G/H→I。下一动作是根整合板载DDR/STORE、生产bulk桥/目录/physical hold、clock/pin及原完整范围作统一纯设计审阅；具体OPEN继续补证/联合冻结。无需再次选择是否外接存储，用户已明确不允许。没有把现demo/容量算式、UART/GE/PC存储、小top或慢速软件核心宣布为相机＋1080p60整包完成；达到共同设计门槛并获指定批准后才进入实施。
