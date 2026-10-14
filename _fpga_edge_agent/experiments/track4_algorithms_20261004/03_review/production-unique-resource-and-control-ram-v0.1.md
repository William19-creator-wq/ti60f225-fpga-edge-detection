# 生产唯一实例与控制 RAM 容量核对 v0.1

2026-10-04。只读真实来源、静态容量/覆盖关系及限定独立审阅；不是完整资源预算、综合映射、服务或时序通过。完整十一项、1920×1080、板载DDR与原算法/质量目标不改变。所有新映射仍为候选，NOT_IMPLEMENTED／NOT_RUN。

## 1. 实际来源与阅读范围

| 来源 | SHA256 | 实际有限审阅范围 |
|---|---|---|
| C2实际map，work/active/track4_ip_precheck_20261004/C2/outflow/ti60f225_oob.map.rpt | 8E5077141AE845D9307F8518657B097EE61E2359D0E07861F6181D6267B572BB | L2366–2369、2476、2507–2508、2615、2631–2632、2788–2797；root再次核层级及summary |
| PERF | A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469 | 独立数值阅读L137–154，旧43RAM口径 |
| PIO | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | 独立L171–184；root再次核camera31、行15与原语段 |
| R1 | F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00 | 独立L63/175，median/Sobel两个独立两行窗口 |
| R2 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | 独立L60–70/124–140/160–166；root再次核FE8加后级20 |
| R3 | 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D | 独立L149–151/244–261，两个常数ROM |
| R4R | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 | 独立L316/376–380，FONT独立 |
| ROW | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8 | 独立D1/D2/E4；另原语审阅L54–60/136–158 |
| SCAN | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243 | 独立D1/D3/L172–187；原语审阅L74–96/120–126/172–180；root完整读回 |
| HANDOFF | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 | 数值L118–124；原语L73–90/94–104/112–144/197–205；root完整读回 |
| EFX_RAM10实际模型 | DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33 | C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/sim_models/verilog/efx_ram10.v，17913B/458行；独立L1–165/177–218/259–458，root核L1–33/177–219/309–419 |

两位独立 agent 分别为 r2_terminal_numeric_review 与 row_math_source_review，只读/文字核查，不运行模型或生成业务代码。root实际复核上述hash；模型/HANDOFF/SCAN的独立前后hash不变，PB/ROW两次核验一致。范围不是全文整包审阅，不由hash相等推导语义或性能通过。

## 2. 实例清单及覆盖关系

| 真实保留或新候选实例 | 列出的RAM类块 | 必须遵守的覆盖关系 |
|---|---:|---|
| 原DDR | 39 | 原map父层已包含PHY22及异步桥17，不再加22/17；当前未跑ASYN0，不假定省桥 |
| 原CSI | 11 | 与新camera ingress31不同职责/数据，不被其覆盖；保护IP仿真仍失败 |
| 新camera必需缓冲/历史/ROM/writer | 31 | ingress22+RAW10历史4+配置ROM1+source writer4；非灰度/median FE窗口 |
| 新ROW输入/RX/输出 | 40 | input18+RX7+output15；已覆盖PB25及PIO renderedrow15，不重复相加 |
| 一份完整FE及Canny后级 | 28 | FE8+Gaussian8+新Sobel4+NMS8；基础Sobel与Canny共用该FE需联合owner/dispatcher，尚未证明 |
| PROFILE实体 | 1 | 不包含目录/封印/消息保持成本 |
| FONT | 1 | R4R独立ROM，与R3常数不共享 |
| R3常数 | 2 | θ/projection各1，不包括完整R3算术或scratch |
| **列出合计** | **153** | 只是具名实例清单，不是全机资源报告 |

原map层级RAM列合并类型：顶层89，对应summary EFX_RAM10=85与EFX_DPRAM10=4。上表保留实例按原层级类别列数，新缓冲按RAM10候选列数；**153不能未经分型核对写成153个EFX_RAM10**。新实现还须核每种原语、实际参数和同时寿命。

R2当前内FE固定Y_ONLY，R1 FE8含median与Sobel两个独立两行窗口。若生产另实例化一套R1 FE，则另加8，不能在未定义共同dispatcher/owner前宣称共享已完成。原demo frame_buffer28、Debayer/gain/gamma/debug等按新生产链替换，不再加原top89；是否保留调试须将实际新实例另列。原map4DSP不自动成为新算法DSP预算。

PERF旧43RAM、旧RAW11、旧ROW1是历史局部口径，不是当前生产总数。STORE/journal/observer、真实plane/loan目录、所有控制、R3/R4算术、CDC/PLL、native端口及其服务均未被153覆盖。可选live fork4也未默认采用；若采用须补真实实例和源保障。

## 3. 控制逻辑body与运输保持

原HANDOFF来源的19036、加FETCH21050、加七cache28455为逻辑body下界；五RowCtx4325另列，合32780时已包含它。SCAN30306已包含D侧四CTX3360，不被CORE四registry替代。ROW本地3000、published ROW11508、adapter638、数学/缓存1219有各自范围，不能因持久记录移RAM而消失。

新[无借用关闭联合候选](../../../planning/design-TRACK4-ALGORITHM-NO-LOAN-CLOSE-001.md)将GRANT459→461、CORE_CLOSE仍409/417，并增加四exec五个折叠事实。其body口径为19040/21054/28461；并列RowCtx后32786，另20bit折叠状态。旧来源数字仍绑定其原hash，不直接当成新合同成本。

源held、目的private及相应反向回复仍须真实稳定全文。12796原基础运输body（新12800）及2014 FETCH运输body不能因为另有归档RAM而扣掉。一拍20bit输出不能直接提供906/914bit held或跨CDC总线；若改为串行装配，须计完整assembly holding、pending、保护读取和实际服务。这份报告不确定FF节省量。

## 4. 同core RAM的合法几何

模型是simple dual port，一读端口及一写端口。READ_WIDTH=WRITE_WIDTH=20合法，9bit地址/512word/10240bit。WE[0]/[1]分别写低/高10bit，完整词用两半都使能；不是两组8bit byte mask。WADDREN0仅保留旧地址，不能当禁止写；RE也须实际门控。

OUTPUT_REG0仍为同步读，RE沿后更新，消费者下一沿capture；新capture再按旧资格使用。OUTPUT_REG1增加一级，不能沿用当前ROW沿表。模型明确同址读写未定义，不由READ_FIRST/WRITE_FIRST仿真分支推导合法碰撞。RST重置输出，不清mem且不自动禁写；cold-valid/完整代次必须隔离未初始化内容，warm-reset不能清valid擦债。

### 4.1 HANDOFF四类关联记录

每份记录独立词对齐；padding写规范0，不偷偷存有效位或引用。

| 记录 | 原body bit | 每份20bit word | 总word | 每份尾padding |
|---|---:|---:|---:|---:|
| registry×4 | 906×4=3624 | 46 | 184 | 14bit |
| loan原OPEN+borrow×4 | 451×4=1804 | 23 | 92 | 9bit |
| assign_seq关联×5 | 64×5=320 | 4 | 20 | 16bit |
| out KEY关联×3 | 164×3=492 | 9 | 27 | 16bit |
| **合计** | **6240** | — | **323** | **总padding220bit** |

323word=6460bit，在一块容量可放，剩189word。451不含完整plane/version/base/容量/commit/pin目录；906不代D四CTX；五关联不代row_seq分配器、高水位或耗尽检查。

### 4.2 七组完成缓存的两种对齐

| 完成记录 | 原body bit→新候选bit | 整组拼接word | 各请求/回复独立对齐word（原→新） |
|---|---:|---:|---:|
| OPEN+GRANT | 846→848 | 43 | 43→44 |
| ASSIGN+ACK | 990 | 50 | 51 |
| FILL+ACK | 654 | 33 | 34 |
| OUT+ACK | 1098 | 55 | 56 |
| CLOSE+ACK | 990 | 50 | 50 |
| REGISTER+ACK | 1820 | 91 | 92 |
| FETCH+TERM+ACK | 1007 | 51 | 52 |
| **合计** | **7405→7407** | **373** | **378→379** |

整组拼接方式必须将跨内部字段边界的完整20bit词一次写定，不允许按body局部修改混合词。各body单独对齐方式更容易分别装配，但GRANT461跨过460bit边界，其缓存比原459增加一word。两种不可混用预算：原HANDOFF两块合696或701word；新联合候选合696或702word，分别13920或14040physical bit。均容量可放在两块，尚未选择实际端口/调度结构。

记录完整写入前不能立valid；读取/比较/复制期间不可替换。cache值不pin已退资源，但读取义务与正在运输的held必须受保护；先核epoch/session，再命中，旧成功重放不新grant。剩余物理词不是已经分配的合法记录。

### 4.3 SCAN冷记录候选

四CTX840→168word；四成功PREPARE摘要66→16word；ARMcache1292→65word；PREPAREcache1820→91word，合340word/6800physical bit，一块容量可放。Qsnapshot444须即时冻结，VSYNC旧ARM选择record198/热身份/计数/停止与Q不能默认从冷RAM及时得到；其热镜像、复制与引用另列。

将上述三个冷存候选加到153具名清单，得到**156类块**；若另设FE8则164。两者都不是fit证明：冷存端口仲裁、宽body保持、真实目录、全部FF/LUT/DSP/PLL/CDC及最坏服务未关闭。

## 5. 端口、寿命与下一步

一块只有1R/1W。即使CORE/O/ROW/RENDER同clock，也有不同真实owner；registry更新、loan归还、cache提交和KEY读取必须仲裁。registry至少46读词、loan23、out KEY9、REGISTER cache91或92词；不是一拍全文查表。四STOP持久槽/sticky不等待串行body操作，不能为省FF破坏停止响应。

下一步应冻结三个独立账本：①持久冷记录及组提交/替换保护；②即时held/private/热状态与每份真实owner；③完整plane目录、R_ROUTE/W_CTX、seq/highwater/计数/CDC及算术映射。随后联合最坏camera/显示/算法服务和真实输入manifest，才可评价全机资源与时序。

本报告减少重复计数并给出原语容量证据；没有运行新仿真/综合/布局布线/STA，没有新增业务源码或功能测试，H-B03/H-B04、SC-B01…03和整合全局阻塞仍OPEN。
