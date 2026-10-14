# PRODUCTION-BUFFER：实际来源与有限审阅 v0.1

2026-10-04。纯控制面证据；NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED。当前功能、仿真、综合/PNR/STA/bit全部NOT_RUN；本报告不扩展已终态的IP-PRECHECK v1.2。

## 1. 来源与方法

独立数值审阅者 r2_terminal_numeric_review 实际读取控制面/根v0.2和0927更新v1公开DDR/master；协议审阅者 r2_terminal_protocol_review 实际分段全文读根规范61102B/919行、PIO56290B/318行、PERF58487B/396行、PROFILE-SOURCE30415B/196行且前后hash稳定。协议子审阅的有限来源由该审阅者汇总，不冒称根全部重新读过所有原件。

PIO/PERF/PROFILE-SOURCE hash分别39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10、A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469、6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103。题目需求3CA55B70E23488B4710345CEDE908D62A0A9113D4AC8454D6746E04BC4CD5DE2实际定向L1–90：基础采集无丢帧与显示刷新为不同要求，未承诺慢完整识别处理每camera帧。

所有原文件只读，不解密protected主体、不写业务文件/TB/功能脚本、不执行构建/模型。根另外实际读C2的PLL节点、SDC首70行、top DDR连接：peri43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B，SDC7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF，top33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9。

## 2. 真实DDR公开事实及不能推出的保证

根目录为D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1；下面路径相对此目录。

| 文件 | 实际SHA256 |
|---|---|
| ti60f225_oob.xml | 571E5A03A7CCC46D2B15CF9D3DCAAA1BC1A874CB3E0908330599891457867BE8 |
| rtl/ti60f225_oob_top.v | 0ACCF23D67A2E5360C91DDCD36563C5E90A682BE52B071B18F2B8F0F40DF5AA9 |
| rtl/ddr3_controller/ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A |
| rtl/ddr3_controller/ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 |
| rtl/ddr3_controller/axi4_bus_ctl/axi4_bus_ctl.v | E908D8045FE2332A1740F3ACA0226B5FE0BF4D03E25B040FE0F32015D573AD5B |
| rtl/ddr3_controller/axi4_bus_ctl/axi_upsizer.v | 03C25E7276781D9C22F4CBD7B25B76B6317ED7083874A7C94B052A0ABD1188E0 |
| rtl/ddr3_controller/lb2_axi_clk.v | 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D |
| rtl/ddr3_controller/local_bus_ctl/local_bus_ctl.v | 822D5D0F54C7BA0EA8D66F19F1E97CDEA3A159932C64295DFE5CA86F9F814608 |
| rtl/ddr3_controller/memory_bus_ctl/memory_bus_ctl.v | A12B886A37278BD44BC207C2DEBD11156EAB1D579E4E3AA7702B229508778882 |
| rtl/ddr3_controller/phy_ctl/phy_ctl.v | 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B |
| rtl/ddr3_controller/phy_ctl/ddr_phy_if.v | CE8DFD7600E8BE615611D353CC6B62E7CCF6411D22AC47C45F9B650AD908584B |
| rtl/frame_buffer/ddr_wr_buffer.v | AF20558C13AAA72BB678BF202A74BA24BCCAA40972DD5E63D359725EB8497BEC |
| rtl/frame_buffer/ddr_rd_buffer.v | D5C5A3DEEF24A150047EA1D3799D3116688BC49F55C18B92545CB0095FE60F56 |

实际端口/原master事实：参数21–23和ddr3_top101–151为ID4/address32/data128/WSTRB16、LEN8/SIZE3/BURST2/RESP2/RLAST。top528–567、621–662直接连接framebuffer，无公开地址转换。wr57/262/483及rd55/194/231按(LEN+1)×16B增加；wr492–499、rd225–233采用SIZE4/INCR01/ID0、全WSTRB。top498的BURST_LEN127及wr155/298–302/455–471、rd112/159–171/217–220有128拍和4KiB拆分意图。

写wr50–52/433–435/495–497没有BRESP输入，BID/BVALID只声明、BREADY1，末W后推进；读rd42–47/239–247/276–311/330–333没有核RID/RRESP/逐拍数量，RVALID直接进FIFO。top306/347/574–580/669/764–776里cal_done用于LED，视频reset不以cal_done为资格。因此旧完成/bank_sw不能作为新源封存，旧访问亦不证明已校准才发出。

mask边界实际可读：top118–119→AXI52/88–89→bridge44/60→local50/62→memory75–76/112–113→PHY108–109/134–135→PHY_IF86–87/119–120。主体分别保护于top193–935、AXI101–2890、bridge100–297、local81–333、memory137–5169、PHY252–754、PHY_IF315–972。无法据这些边界证明mask极性/byte排列/DM或B后可见性、drained、错误、校准ready；也不能反过来断言其被丢弃。

公开upsizer631–639/4444/4462/4487–4519确实保byte strobe、647–651和1318–1329保B/R响应，但XML18–31未列它，上层protected调用链未知；此成员事实不授实际slave窄WSTRB支持。新adapter候选只用全拍子集，RMW须覆盖rounded授权/同对象padding及所有访问者排他；任何UNKNOWN不造写前缀或关闭成功。功能资格必须后续真实验证。

## 3. 连续camera与慢选择的实际反例

协议审阅全文发现：PROFILE L111的3B/F/L/独立OBS满六；PIO L206/212的迟CRC/FIFO水位/B/CLOSE/commit/CAP_END，及PROFILE L95/121的旧LATEST closing，均可使下一ARM错过SOF，即使存在FREE。CSI无ready、scan/pixel/serializer固定推进；算法/COPY/AXI可以受控暂停，但已issued/held不得撤。

独立capture ring加IMPORT是候选方向：F/OBS/bundle只pin不可变SRC，camera ring正常复用与算法未选分别统计；copy完整6.22MB才注册SRC，camera下一reservation与服务优先。三ring可同时四角色不够；四ring也必须计提前ARM第五份reservation。根在[新卡](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001.md)选择五ring条件容量；这是根设计选择，**原协议审阅提出的四ring比较不冒称独立批准五ring或证明closing≤1**。

每copy读+写12441600B；camera60/copy60仅条件式已需1539648000B/s、η>96.228%，未计算法/刷新。COPY速率不能免费取camera速率；独立camera帧接收/存写closure仍必须完整。copy_seq、新source_id不代表新camera输入，去重签名需真实origin/camera CFG/link/算法CFG/PCTX。

## 4. 实際静态算术与新稿审阅绑定

[纯数据算术](../01_baseline/production-service-arithmetic-v0.1.json)2261B / A560EABBB60E1B2998DE06A9929A80918E603462DBFA39056E2FAB565E3AF732根全文读回：五ring总124.25MiB、四ring116.25；mode5行6480B/405拍；按128拍/4KiB拆分1080行得最多8burst，row0五burst，y34/187/750均8。这是有限地址算术，未验证IP响应或服务曲线。

新卡初稿21378B / A056148B067D371F96D1CFE585AD9EADD57998C55FB30D2C8D38DF0B09494EFF已根分段全文读回。原字节保存在[初稿快照](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001-v0.1-before-import-purpose.md)，后续结论分别绑定输入，不把旧hash审阅自动覆盖新版。

初稿数值审阅实际覆盖D1/D2/D4/F及A560算术JSON全文，实际native模型DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33的7–27、100–128、177–214、309–417行：124.25MiB/端点、283bit、12,441,600B每copy、条件流量及405拍/最多8burst一致。input每bank9RAM、双bank18与RX7合25payload RAM亦一致。建议补EDGE/ANN/RX尾地址、WE11/同宽/OUTPUT_REG0及padding；405 AXI拍还要解码为360RGB＋120EDGE＋240ANN＝720word写事件，不能凭405拍授期限。

初稿协议审阅实际全文L1–156，前后hash稳定，发现两项具体反例：

1. D2将全部COPY依赖J可接受/结果信用，而E06的NO_ACTIVE冻结先import；PROFILE-SOURCE冻结过渡提前关source admission_gate，实际F pin后才应用。若J资格含gate，冻结补源与策略应用互等。
2. 末R后仍有旧RGB decoder/RX残存16拍，新短EDGE burst空位足够也不能覆盖唯一route；RID0/RX135和一已issued物理burst不保存历史归属。R_ROUTE必须锁到全部旧引用真实移交，不能扩大到整行READY或COPY commit，否则后续burst自锁。COPY目的写须有独立W context/holding，可在旧读物理响应结束后推进。

根据此修改COPY目的为ALG与FREEZE_FALLBACK，明确后一目的不依赖已关source gate/J/scratch/结果信用、不造J，RESUME独立退役；同时分R_ROUTE/W_CTX、补native尾地址/WE/padding及720word计数。该次修订25896B / BCAA00A5BB3E5B88B74ECD5075EF1E06FF752B7281850FB8D3DACE85E1844649，根再次分段全文读回；原字节保存于[目的措辞澄清前快照](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-BUFFER-001-v0.1-before-purpose-wording.md)。

新版有限数值复核实际仅D4 L82–92、F L112–116、T07 L130，绑定BCAA：所有尾地址/索引与occupancy、WE半字宽、OUTPUT_REG0/padding及405/720口径落实，未发现该范围新数值冲突。25RAM仍只列payload，未审新版其余内容或宣称全机fit。

新版有限协议复核实际比较A056快照与新版全部文本差异，读新版L44–96、L98–162，前后BCAA稳定；没有重新读新版A/B。L64/66/104/110关闭冻结补源互等，L76/88/106关闭旧routing覆盖且不引入读写互等；T03/T07/J同步。该限定范围未发现新增具体反例，**不是新版全文审阅或完整FSM/服务/整包通过**。两位复核者均未写文件、实施或运行功能工具。

## 5. 整合增量及最后措辞核对

协议审阅者实际比较整合v0.6 F0D020BEF6B969F0120086B3E931EED9EC4265EC4EB69ECB132147D20E6697DA/44194B至v0.7 D578047B65430B1CF60D90E4ECBD7B97BCC5D0F2B216A243DFA26683E8BADD95/48530B的全部文本差异，定向读C/D、F/G、I及命中段，前后hash稳定；不是整包全文复审。六immutable＋五ring/两目的COPY/历史R_ROUTE及独立W_CTX/25payload与15output分计/OPEN相容，旧六SRC捕获门控已替换。发现旧IF09仍泛称OUT404输入生产适配，与新bulk及旧单pair不够1080p60的条款不一致，需限定旧可暂停重放/独立像素语义观察出口；同源plane/borrow的生产bulk/input/renderer另冻结，仍须实际有效像素观察和防裁剪，不能换成LED摘要。另建议PB REQ03及正常走查明确ALG与fallback各自目的，以与既有D2一致。

D578原字节保存于[整合IF09澄清前快照](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.7-before-replay-wording.md)，F0D0原v0.6在[本轮之前快照](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001-v0.6-before-production-buffer.md)。最后只修改PB的两个整体目的段，以及整合的来源hash/IF09/K审阅绑定。

最终PB为26058B / 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40；最终整合49136B / 5FA0450D69FFFEA32F74EEC7A95173030FCDCDA701FFA1AAD170F6698027B4C6。最后有限协议核对实际比较这两份完整diff，读PB L30–40、62–68及整合L47–48、123–130、251–255，前后hash稳定；BCAA/D578快照核原hash一致。目的与D2相容，IF09保有效像素观察并将生产bulk/borrow交IF12/14另冻结，该范围无新反例。根也实际比对相同2/3段差异并读回；未冒称最终全文重新审过或整包成熟，未写业务文件/执行功能工具。

## 6. 边界

五ring的条件角色峰值、全拍单物理burst、input18/RX7的25RAM payload、global100MHz来源均非完整服务/全机资源/STA结论。基础行FE、COPY/冻结/原来源签名、完整packet/cache/关闭、各种期限和全部schema/文件/批准仍OPEN。没有算法源码或新的工具阶段；主目标仍未完成。
