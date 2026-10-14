# 生产目录 v0.1：实际有限设计复核与Ti60资源证据

2026-10-04。本轮是纯控制面设计、原始资料只读、有限审阅和读回；不是业务代码、功能仿真、综合、布局布线、STA或bit验证。完整五基础/六高阶、1080p、完整Canny、原识别质量与板载DDR目标保持。

入口为[生产目录候选](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，先B/C→D字段/存放→E中文操作→F成本→G/H/I。原[整合v0.8](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md)仍未吸收本附件，不能以旧端口直接实施。

## 1. 实际版本与审阅范围

| 版本/来源 | 真实hash和读取范围 |
|---|---|
| 新卡原稿 / 30667B、229行 | 7907CC3E1889AB0FA1CDA993FA511B7328CE04AFBA07643ECFE370EB555ED187；两agent实际全文阅读后分别限定D1–D5/F数值和B/C/D2–5/E协议；[原字节快照](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001-v0.1-before-origin-native-review.md) |
| 修订中间稿 / 34170B、231行 | 43FDE2AE977C49449D72E89062BDF0CFB4CC7EED0AAB5F2C0CF01E41DE3806D8；协议实际L54–65、94–110、118–141、145–159、194–203；数值实际L100、123、129–137、167–182、194–196、213–227 |
| 最终稿 / 34598B、231行 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA；root原稿L1–89读回，修订L89–231及最后L123/171/219读回；协议及数值两agent最后L123/171/219实际限定复核，前后hash一致 |
| 生产JSON / 395行 | 9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75；numeric实际全文；root此前全文、本轮实际结构及逐private几何读取 |
| PROFILE JSON / 125行 | 4FE6BF462E97C30D8F421E9D30FDA96D4D9DFC7AC397024B4320159702B0B810；numeric实际全文；root依据当前原字节及已读布局 |

上表的原稿全文＋修订限定范围不能冒称最终整包全文审阅或状态空间证明。所有TEST均NOT_RUN。

## 2. 已具体化的设计与修订

1. 45DDR实体、19未分配descriptor槽和八独立PROFILE分开；RC_AUX/结果关联/CELL half不重复加对象。SRC0地址合法，旧64KiB guard与26bit地址不能迁入当前生产。
2. 新descriptor保640bit但字段597＋zero43；base32/cap29/rounded29/initprefix29、原创建JID/epoch/origin明确。新增global refgen58＋exhausted1与独立pingeneration、version/commit，共248bit，不声称原RAW已定义global。
3. pin512用新的holder_link160回查真实完整holder，不能截断SCAN_KEY256或凭link认证。固定原请求/identity与可变current_owner/JID/state分开，关闭原稿“整个holder immutable”与BIND转移的文字冲突。
4. 未注册SRC使用真实ORIGIN_STATE1、完整CAPTURE_CTX、目的ref/version和COPY holder；source_id0是该producer已知创建阶段，不能从任意0推absence。原记录写完后最后state2/解屏障才授SOURCE311，非多RAM一沿写完。新增12bit热资格已列。
5. 八SRC lease槽明确七业务角色额度包含reserved、closing、RETURNED_METADATA与Q；旧state4占槽/原closing额度，值cache复制不借记录。第八槽仅唯一预检，不能暗多一成功lease；此为新增候选政策，正常服务仍须证明。
6. SOURCE512/RING283/LEASE522在M0共447词，RESULT1879含唯一历史PCTX在M1共282词；两块metadata RAM必要。末词低有效12/3/2/19，高零8/17/18/1；native WE11，20bit与16bit半字mask分开。
7. journal address32/zero17保持576，176bit效果记录不删。prefix只表示连续真实初始化；全WSTRB小写须整个16B邻区已初始化，CLEAR流量必须计入，不拿写计数/COMMITTED代覆盖。
8. 全body97244bit、native已用97588bit；native可寻址104448bit、11块标称112640bit是不同口径。新增已列热436bit不是全部FF；完整mirror/held/RMW/allocator/lookup仲裁仍待预算。

有限审阅没有推翻这些字段与局部顺序；原创建窗口、state/identity冲突及隐藏返回metadata容量已按具体反例修订。这不是完整目录或算法正确性结论。

## 3. holder分类与可证边界

协议agent实际来源：SLOT L29–43/99–130（6BC159…）、PROFILE L59–99/125–141（6A9AD8…）、PB L34–80（0C0EE0…）、R4R L200–240（AA0586…）、RAW L159–175/231–247（7704C5…）；HANDOFF/VIEW/SCAN真实字段定向阅读，hash见卡A。这些范围不是本轮全部源全文。

| 类别 | 原来源实际支持 | 不能据此推出什么 |
|---|---|---|
| SOURCE | 七成功lease＋一预检容量，BIND转同lease不增ref | 每lease是否另外ACQUIRE多少access pin仍须共同adapter |
| CAMERA/RING | 一writer，closing/latest/COPY/future reservation在五ring候选中分别存在 | closing≤1依服务，latest/reservation不自动是访问pin |
| COPY | 单COPY涉及一个ring源和一个SRC目的 | 两侧pin/完整holder的实际producer接口仍待冻结 |
| LOAD/GRAD | CLASS写、GRAD collector写、SRC读分别有owner | 不能合成一个无身份writer或忽略collector存活 |
| CLOSURE | 单会话CLASS/QUEUE/EDGE，CLASS须LOAD实际关闭后转移 | 三授权对象不自动证明三个实际access记录 |
| RC | object5 0…25为26对象授权集合，含21private/EDGE/GRAD/POINT/ANN/RECORD | 不是已证26同时pin，也不含SRC/PROFILE |
| Result/base | 三历史J/PCTX/result关联；最多两不同物理bundle base | owner/base/parent不是访问grant，不能直接相加 |
| Exec loan | 四loan，每份1…3plane，上界12 | loan451只保OPEN/borrow；实际plane/version/pin映射及全机pin上界未证 |
| FETCH/ROW/R_ROUTE | 单物理burst，五RowCtx、两input、三out分别有义务 | child route不能免费新ACQUIRE，也不能在旧loan退后继续借它 |
| 观察 | SRC OBS至多一lease；RECORD独立观察读须关闭 | RECORD读口/并发额度尚未定义，不能用OBS1代其上界 |
| PROFILE | 八片上实体、两个GET client、实际串行读取 | 旧RAW role8/DDR PROFILE_PAGE不自动进入生产pin池 |

当前真实可证的是45对象、七成功source lease、四exec loan/至多12planes、两个物理bundle base等各自范围；不能相加成全局64pin上界。下一步须声明每个实际grant的actor额度、子引用规则和unknown占用，再证明正常路径不因CAPACITY停机。

真实关闭顺序保持：COPY读写/effects关闭及返ring pin→注册SRC→各独立lease→算法/结果→停止FETCH及R_ROUTE/RX/decoder/fill源义务→独立loan close→物理RETIRE/DISPOSE正确ACK消费后execution pin关闭→parent整体RETURN→各bundle返自身admission lease→最后SRC base退休。journal自身关闭不等O退休；source loan close不等out FREE；PROFILE不以frame return删除。

## 4. 21 private实际几何核对

root实际读取R4R当前hash AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 的L140–155、204–217，并读生产JSON逐private base/capacity。下表是来源核对，不是新增执行输入或测试。

| object5 / 名称 | items × bits | logical bytes |
|---|---|---:|
| 3 ANCHOR | 768×64 | 6144 |
| 4 SEED | 256×128 | 4096 |
| 5 HIST | 8192×21 | 21504 |
| 6 RAW_PEAK / 7 SMOOTH_PEAK | 各512×64 | 各4096 |
| 8 DENSE | 4432×21 | 11634 |
| 9 NMS | 1108×21 | 2909 |
| 10 LINE | 1024×64 | 8192 |
| 11 CELL | 8192×48；两half不增对象 | 49152 |
| 12 EXT | 4096×80 | 40960 |
| 13 SEG | 1024×384 | 49152 |
| 14 PAIR | 512×64 | 4096 |
| 15 CIRC | 1024×256 | 32768 |
| 16 RECT | 1024×512 | 65536 |
| 17 VC | 2048×400 | 102400 |
| 18 COVER | 16384×1 | 2048 |
| 19 FINAL | 64×512 | 4096 |
| 20 DRAW | 64×80 | 640 |
| 23 COVER_META | 4×320 | 160 |
| 24 CIRCLE_CTX | 16×384 | 768 |
| 25 FIT_STATS | 16×263 | 526 |

各表按ceil(items×bits/8)，合414973B，与JSON一致；physical rounded415104B、private guard1344B、三RECORD含guard12480B，AUX合428928B。NMS总表23268bit末byte高4bit为padding；FIT_STATS总16×263＝4208bit恰526B，没有总表末byte高padding，单record仍有跨byte及READ响应高zero规则。完整record canonical/末拍RMW仍须具体adapter；此几何证据不关闭所有stage/版本/权限及共同schema。

## 5. Ti60官方本地PDF资源证据

原文件：[Ti60 Data Sheet DSTi60-v2.0](../../../../VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包/VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009/03_芯片数据手册/钛金Ti60datasheet-v2_0.pdf)，2022-04，70页，1053902B，SHA0AB5A7D4143811668DB8E34C671DE30A97588846E931CD8854FA37AA6144468E。root依已读PDF skill只读提取前六页，并实际查看完整第4页PNG；numeric agent也实际看该整页。原文件未编辑/re-export/下载。

[实际第4页图](ti60-datasheet-resource-page4-v0.1.png)143131B，SHA E9EC95B0D1D13FDD0351973E560CD65D4DBF1A1231A8B20513D3041CFE8FD91E。

| 第4页表 | 实际列名/值 |
|---|---|
| Table1资源 | LE62016；XLR total60800；SRL8 14720；global/control最多32；嵌入memory2.6Mbits/256块10Kbits；DSP160 |
| Table2封装 | F225 PLL4；其余I/O不能以最大数推具体板卡可用引脚 |

PDF文字提取会把LE/XLR列序弄反，结论按实际整页列头确认；未猜162等旧未证数字。167/256＝65.234375%、175/256＝68.359375%，只是已列候选与标称块数比较，尚缺完整FF/LUT/DSP/held/端口及实际map/PT/PNR/STA，不称整包利用率或fit。文件第3页仍标preliminary；本证据不是新器件characterization或现装工具容量导出。

只读工具情况：现有Poppler pdfinfo/pdftoppm可用，pdftotext.exe不在该路径，首次文本尝试未执行成功；改用现有pypdf，首次stdout GBK编码失败，随后UTF-8输出成功。没有安装/网络；只新增登记的一页PNG阅读派生产物。此前numeric检查本地device map与不透明core XDB未获得容量，现PDF直接证据补此缺口，不声称XDB已经解析。

## 6. 状态、限制与下一项

本卡及整包仍NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED；DIR-B01完整生产schema/阶段、B02真实holder、B03全pin峰值、B04完整冷热资源/仲裁/服务、B05 DDR/CDC/epoch仍OPEN。完整目标没有缩小，正常服务须有真实依据。

原整合 C7179A…、原SOURCE/PB/ROW/SCAN/HANDOFF/CONTROL RAM输入未修改；只有本卡、审阅报告、README及原字节快照和PDF页图发生控制面副作用。未创建算法work、业务RTL/功能脚本/参考/TB/project/peri/SDC，未新跑功能仿真/综合/PNR/STA/bit，也没有硬件/安装/数据库动作。正式state SHA87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558、Manifest SHAA2CB08F30903D9324CBCEB59631AA30D5001B4EE8745222B3A76DC5A12AA1E75保持。

上一目标轮只是状态核对，分类NO_PROGRESS_STATUS_ONLY；本轮实际新增生产地址/记录/身份与真实资源来源，分类PROGRESS_OBJECTIVE_INCOMPLETE。下一项是将实际actor→access grant映射和额度冻结，然后联合全机资源/服务及整包基线，而不是把本卡当最终软件完成。
