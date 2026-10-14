# STORAGE-LAYOUT v0.1：物理布局与原资料复核记录

2026-10-04；关联[布局主稿](../../../planning/design-TRACK4-STORAGE-LAYOUT-001.md)和[预算诊断](../../../planning/design-TRACK4-RESOURCE-SERVICE-BUDGET-001.md)。主稿最终SHA256 **1B2D2C5621AFAE0B13070C584DEAEDF4969F6B1B63321CC3410F1115267E5270**，35460 bytes / 20610字符。状态为LOCAL_DESIGN / NOT_READY / NOT_APPROVED；本记录不是实施或构建批准。

## 1. 实际审阅及修订范围

root实际读回相关父字段、DISPLAY附件、RAM原语、旧map相关行/报告头与DDR参数，保存后逐字符读回布局主稿；RC、DS/PL、DP三个只读方向提供交叉审查。初稿SHA256 EAAFE…FCA35157B仅是审阅时的版本标记，不充作可恢复完整哈希；最终恢复以本记录首段完整SHA为准。

最终稿的DS方向实际复核D2/D4，RC方向实际复核四处修订及91/17/207的条件；DP方向实际读回D3/D4/E1/E2/F并确认SHA1B2D…E5270，未发现此范围新实质错误。DP旧报告只有一份54bit pair，其490/539估计不能用于最终预算。最终稿明确原DISPLAY保留两份54bit holding：160＋19＋256＋108＝543bit数据容器；CORE stage控制28bit、PAIR pending112bit另列，其他身份/错误/row上下文/renderer/adapter未算完。限定复核不冒称每位审阅者全文审完最终稿，STA未运行。

本次修正四处：①192bit被开方数的floor sqrt可96bit，RNE可能到2^96，须97bit或独立进位及溢出检查；②切换VC record/class只关闭旧record临时RE/NUM/coverage义务，两类表持续保留到SELECT/best全关闭；③DS record326bit冷身份和原113bit热状态都保留；④OFFER1963bit与receipt1969bit均99个20bit word，RC_BIND4731bit为237word，6bit word_index不能通用。没有以布局省额删候选、字段、关闭义务或质量要求。

## 2. 本轮已明确的布局与证明范围

| 对象 | 新候选 | 原候选及差异 | 真实证据边界 |
|---|---|---|---|
| RC模式池 | 74 RAM，固定外围17，合91 | 原88＋17＝105，永久释放B74…87共14 | P1/P2/P3全部最大同时布局；不是综合 |
| 圆/矩形VC | 30＋40，coverage4，共74 | 两类各2048同时存在 | 压紧固定0字段；不只取较大40 |
| DISPLAY | SRC三行15＋EA两RAM＝17 | 原21，释放4 | SRC6912与EA864唯一word位置的静态枚举 |
| 自写模块小计 | 225−14−4＝207 | 外部IP和全部metadata仍另外 | 不是完整工程资源用量 |
| 若另采DS/PL串行 | 207＋7＋1＝215 | DS24、PL22尚未选定 | 只是联合方案代价，不算已采用 |
| DISPLAY明确数据容器 | 543bit | 两份54bit holding均保留 | CORE28/PAIR112及其他控制另算，不是模块总FF |

SRC native20×512，按word号模5选lane、整除5选addr，每行5RAM、三行15RAM、addr≤460，负载90%。每pair读3/4个连续word，lane互异，先word0置最低20bit、切48bit，再按原RGB bytes重排为canonical {R1,G1,B1,R0,G0,B0}。EA三行共864word映射到两RAM，addr≤431，EDGE和ANN各一RE且分属不同RAM，负载84.375%，没有RMW。n−6所有required RE→n−5旧pending preedge capture54→原固定scan链不变；MUX/移位新组合路径尚无STA证据。

旧holding128＋tail19最多147bit、7完整nativeword；SRC最多两组WE，EA最多四组WE。末WE沿建立下一stage只用旧next holding/旧tail及旧完整word计数，不使用同沿新Rfire。900个完整WE组机会是访存计数，不是row服务期限。取消仍capture/discard旧RE，目录pin/已提出WE/物理borrow全关闭后才释放，暖reset/Q不提前复用。

DENSE高位分离保存导致单票6沿，不沿用旧4沿代价；CELL/EXT的端点须由完整submask精确恢复并检查valid/count/mask；SEG379bit×19word及圆VC294/矩形VC386必须按主稿bit表恢复逻辑值并保留非法输入检查。PROFILE1024bit从NUMERIC和RC_BIND重复统计中去一次，RC局部容器28144bit仍非真实FF总量；FIT/scalar省额未采用。

## 3. 实际IP、历史报告与时钟选择

V4 v1原map为Efinity2025.2.288.3.8、2026-03-31历史产物，本轮没有重新编译。相关层级：CSI1191FF/36RAM；DDR2790FF/39RAM/895SRL8；其中lb2_axi_clk204FF/17RAM/54SRL8已经包含于DDR39；DVI617FF/2RAM/248SRL8包含额外逻辑，不能当作纯serializer。DDR39＝PHY部分22＋异步桥17；旧帧缓存26/debug22不加到DDR内部，不能把39误写为22或把子层级17再加一次。

v1实际BANK3/ROW14/COL10/DQ16/DRAM_WIDTH8/ADDR_WIDTH30、tCK2500ps、CK_RATIO4、ASYN_AXI_CLK1。v1与v6的14份DDR、3份受保护DVI文件的规范化文本序列由只读方向核为相同；这不是原始byte哈希一致，也不是解密或新综合。v6没有对应outflow map/hierarchy，不能把v1CSI占用当新CSI资源结论：v1 CSI5.6/FIFO4096/4lane70/Continuous；v6 XML实际引用CSI5.15/70/core100/FIFO1024/Discontinuous/PACK_TYPE15；旁置settings为5.16/50/FIFO2048/Pack40/debug，三者不可混用。

ASYN0仍为未选择的联合候选：若采用，应把业务/AXI/core放在DDR_PLL固定#4的同一100MHz net，保留#1固定400与#0/#2/#3校准关系，重新核gclk及真实SDC。相同频率不等于同域，不能只删桥或沿用错误async/exclusive clock组。protected wrapper内部及ASYN0绕桥资源未公开证明；TinyML ADDR28/ASYN0旧22RAM只支持候选调查，不证明V4 ADDR30新工程资源/校准。现装DDR5.16的半速/缓存结构与旧1.1不同，不继承22/39；CSI byte70也不直接等于NORM时钟。

本地官方LVDS文档指出Ti器件有4专用TX、width10、half-rate及同PLL相位要求；这些限制用于未来选型，不代表DVI617FF能删掉或当前新serializer已验证。EFX_RAM10依据现装仿真原语为native512×20/1R1W，禁止依赖同址跨clock碰撞。

S01…07根为V4的10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1；S08…12根为C:/Users/34528/FPGAEdgeLinks/Efinity2026_1。以下12项本轮实际hash核对；完整绝对路径也保存于document-checks.json。

| 编号 | 源文件（相对片段） | SHA256 |
|---|---|---|
| S01 | Ti60f225_sc431hai2hdmi_v1/outflow/ti60f225_oob_top.map.rpt | 6ACC8CEED5D04AD54983428A7617026788E338EA1C5C3A737251FEB2A9580B1E |
| S02 | Ti60f225_sc431hai2hdmi_v1/outflow/ti60f225_oob-hierarchical_stats.rpt | A675356A2E56D0D90927256F8648C4938AB41FB9F5CEB98707B1541C1C8093F0 |
| S03 | rtl/ddr3_controller/ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 |
| S04 | rtl/ddr3_controller/ddr3_top.v | 7D8D9CD8A2C69E44EBE9A143F91E6591136AA57F3BE22B2CFF76904F67D0236A |
| S05 | rtl/ddr3_controller/lb2_axi_clk.v | 9CEF7D5361E79D8C7F1DEEAB3AF981444941EA50447C6C7C8B782E381F41DC2D |
| S06 | ddr3_controller/phy_ctl/phy_ctl.v | 2B106E88FB017CBCDA86A6ACE62F81049D9725A79D4A2FFE9B44672BB4DBC08B |
| S07 | 10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1/ti60f225_oob.sdc | 18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E |
| S08 | ipm/ip/efx_ddr3_soft_controller/ipm/ip_component.xml | 9E22739D53D5E7CB540B604F0A84B44D3AAEE5306F6A5E954D7D3832378DAEBB |
| S09 | ip/efx_csi2/efx_csi2_rx/ipm/ip_component.xml | 3E6E66D131BFB30C3F6682A0D43B257080BC0D000967D2F36A96518E9EC1C56A |
| S10 | efx_ddr3_soft_controller/ipm/doc/topics/ddr3-controller-fd.html | 8F6DF6DAF9A3F462BFFFE8D4A0AD5DCA30971407ECAB390016D0EEF3F8DA332A |
| S11 | efx_csi2_rx/ipm/doc/topics/mipi-csi2-rx-core-customizing.html | 34B1AEB02FD8C683FE887DB47B381BBE813BE5D10C90674FC100A1D4AA455FA9 |
| S12 | Efinity2026_1/pt/doc/topics/hlp-id-lvds-ti.html | 40219F6DBFC6ECD4E1FE36251EEEDA35D47D61B5E543317AC9CCEB66A4F94550 |

## 4. DS/PL串行控制备选：完整保存，不计本轮省额

下面是只读方向给出的待联合布局，主稿D2/D4已明确不选择。它改变物理运输，须与DS/PL/FM/各client完整联合并按指定版本批准。REQ266/W152/R155继续原宽，控制包完整word/长度/序号/padding检查后最后commit才等价于原logical fire；半包没有授权。独立normal/error/FINAL/PREP/snapshot/reset槽不能以等下游之名持有整个RAM锁。6bit索引只适用于≤64word单类，长包须依各长度扩大。

DS14数据RAM不变、metadata10RAM替代原3，合24、净加7。保留16scope623冷＋688mutable、32grant241＋93、32phase518冷＋381live、14record326冷＋113热、14独立badprepare271及badrelease288；八R/W段容量不缩减。

| RAM | 完整地址分配（20bit word） |
|---|---|
| M0 | 16scope×32word＝512 |
| M1 | scope0…7 mutable各35word：0…279；FINAL41word：280…320 |
| M2 | scope8…15 mutable：0…279；CORE平台99word：280…378 |
| M3/M4 | grant0…15/16…31各17word：0…271 |
| M5/M6 | phase0…10/11…21各45word：0…494 |
| M7 | phase22…31各45word：0…449 |
| M8 | 14record×17word：0…237；控制274word：238…511 |
| M9 | badprepare14×14word：0…195；badrelease14×15word：196…405 |

M2平台99word分别mirror35/fault7/manifest7/entry36/resetreceipt7/resetdone7。M8控制完整分段如下，不因共享bank删独立待关闭body。

| M8地址 | 包/word |
|---|---|
| 238…269 | SCOPE_OPEN/reply32 |
| 270…282 | GRANT_OPEN/reply13 |
| 283…298 | GRANT_RETURN/ACK16 |
| 299…309 | PHASE_OPEN/ACK11 |
| 310…323 | REQ_CLOSED/ACK14 |
| 324…331 | PHASE_RELEASE/ACK8 |
| 332…366 | SCOPE_CLOSE/ACK35 |
| 367…384 | FENCE18 |
| 385…419 | CANCEL/ACK35 |
| 420…426 | FAULT7 |
| 427…467 | PREPARE/done41 |
| 468…511 | binding check44，候选J486＋4desc96＝870bit，字典仍待冻结 |

DS hot候选10438bit的分项为192/384/896/1582/322/2250/448/256/620/360/28/2170/806/124；可选完整诊断5980另加为16418。不能把这些叫物理唯一FF闭合：mutable688、phase冷518、record热113的逐bit字典和路由仍未冻结。实际ACK消费之后必须把record accepted/released义务移入pending journal，直到phase/scope计数提交后才free；计数包含journal，CERT先排空journal。冻结518身份不冻结live381，后续R/B和错误必须继续合法更新。

PL22＝NORM20＋mirror1＋aux1，相比现候选净加1。aux布局如下：

| aux地址 | 内容 |
|---|---|
| 0…207 | 16mirror mutable256bit，各13word |
| 208…303 | 12health各8word |
| 304…338 | mirrorbody/reply35 |
| 339…345 | reset7 |
| 346…352 | frozenfault7 |
| 353…359 | livefault7 |
| 360…369 | PREPprefix10 |
| 370…379 | FINALprefix10 |
| 380…420 | preparedone41 |
| 421…461 | finaldone41 |
| 462…511 | 未分配，不能提前借用 |

12×(health assemble147＋committed147)＝3528FF继续保留；独立inhibit的新接口尚未闭合。hot候选7769＝3528＋24×80＋619NORM＋414SUP＋112pending＋192mirror目录＋744word holding＋192rx＋48inhibit。24route字典未冻结；以上代价不等价于可布局结论。

## 5. 用户指定VF/Demo目录的复核

两个目录实际存在。本轮重新枚举VF 11672、Demo 5254个展开文件；VF 24份ddr3.v及24份4096Mb头分别只有一个byte hash（模型AF83D644…56F20EA，头39BD3B89…155A349）。Demo展开目录没有同名器件模型，但[既有追加证据](../01_baseline/vf-demo-supplemental-evidence-v1.md)已记录IMX219 HDMI ZIP568成员内的模型及4096Mb头、TinyML的DDR控制器/PHY/校准及SDC。当前两个根展开文件与既有相关归档证据仍未找到2048Mb器件参数头；文件名全根搜索也为0，不把这个范围扩写成所有压缩嵌套/PDF的绝对不存在。

VF两个SC1336 ZIP及Demo IMX219 ZIP加上24展开共27份模型的既有字节证据都是默认4Gb/x16。模型含den2048Mb条件分支，但其include需要2048Mb_ddr3_parameters.vh；不能只改宏或限制地址就称匹配V4 2Gb器件。**这里有DDR工程、模型、引脚/时序参考；缺的是匹配当前基线的完整2Gb仿真条件，而非整份DDR资料。** VF引脚不能与V4混用，IMX219配置也不能替代SC431HAI。

## 6. 当前闸门和交付边界

本轮12个SL文字场景全NOT_RUN。静态地址/位数/哈希、Markdown链接/表格/追踪检查只属于文档设计验证，不能称颜色仿真、器件校准、综合、PNR/STA通过。原225预算稿及审计按原字节保留在[历史审计](document-checks-resource-service-budget-v0.1.json)；新的联合版本须吸收地址、DENSE代价和两份holding预算，再闭合全部metadata/IP/真实service。

SL-B01联合父版本与全部热冷/路由布局；SL-B02实际CSI/DDR/clock/2Gb模型；SL-B03最坏服务和原批准/数据库前置仍未关闭。既有FRONTEND/模型申请PENDING，不重复提问，不冒充Manifest/DB已批准。业务源码/测试/功能脚本及IP生成/综合/PNR/STA/bit/hex均未生成或运行，原HDK/正式state/ledger/Manifest/DB未改；硬件编程与观察仍由人完成，本次软件终点在其之前。
