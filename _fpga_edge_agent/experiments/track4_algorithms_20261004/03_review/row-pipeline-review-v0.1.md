# 生产行流水 v0.1：来源、数值及协议的实际有限审阅

2026-10-04。纯控制面设计工作；整包目标仍未完成。本报告记录实际阅读及有限文字/算术核对，不是业务测试、全机协议证明或实现批准。

## 1. 已保存输入与根读回

| 输入 | 字节／SHA256 | 核对范围 |
|---|---|---|
| [初稿同字节快照](../../../planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001-v0.1-before-last-prefetch.md) | 27561／831FB8715C9BD58321B388A19862D06A42BA456D7DEFACF23D382015F5FBC18C | 根分两段实际全文读回216行；独立协议agent实际全文读前后hash相同 |
| [当前行卡](../../../planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md) | SHA90E98056A72E049EACEADC1885B89CCB5266EC947B4A97F6FDA09341CA8FBFC4 | 仅L122末预取措辞修订；根实际读回120…122，不能将旧全文审阅冒作当前全文 |
| [纯算术JSON](../01_baseline/row-packing-arithmetic-v0.1.json) | SHAB2282C8486E9CEB831012E2A4FC1F6CF710D1EEFD08FDC82ECA5AB0F2430B5EC | 根实际全文读回；405/720/2880、writer与reader周期、尾地址、通道重排 |

此前1998B纯数据E539EF1FEC85F4B91D0A0EFB82DE980A9103A2AE14F2D5B0E8857A77C7CDDA8C只存在于本轮早期，后增加2880及reader周期两字段；它不是执行模型或测试证据。文档修改始终在控制面，原HDK/源码只读。入口README首次patch因匹配不到完整段落而失败，没有文件变更；随后按实际读到段落插入新阅读入口。

## 2. 数学来源审阅的实际绑定

`row_math_source_review`只读来源，不是新行卡审阅者。实际报告的稳定输入及范围：

| 来源 | SHA256 | 实际范围 |
|---|---|---|
| 根v0.2规范 | 4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2 | 全1…919 |
| REPLAY | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | 全1…293；另88…93/109…128/168…177/205…227带前后hash重读 |
| PB | 0C0EE05D40DA9F80A2C1AF509B9D3DD79AFE281EE0A71FB9124486DCFFC63E40 | 定向82…96/110…117及相关检索；未称全文 |
| DISPLAY | 914A0DEFB89ACB1C453A78BFE8704920C0E4B6618F4BE8F0836CF9E606C9B717 | 81…109/198…203及定向检索 |
| control-display-source-contracts | 192D9DCED0F1189E6804423040BA45FDAD6DAE8F00B9D87893DE31E649DD91A0 | 全1…85 |
| ALGORITHM-CONTROL | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 | 90…128/162…186/210…222及检索 |
| PIO | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 | 156…203及定向检索 |
| PROFILE-SOURCE | 6A9AD826C5D801100853A4BAD9E0704228E706B591C73C25B8031DAC931A3103 | 61…79/174…179及检索 |

已核共同规则：gray使用原RGB、unsigned16扩展后一次舍入，最大bias sum65408；黑0/白255/红77/绿149/蓝29。mode0/3白黑不使用edgeRGB；mode5的非零ANN后覆EDGE，关闭show不免完整平面资格。默认颜色不能覆盖历史render112。mode0 y539/540/1079→sy1078/0/1078，上SRC与下EDGE各518400pair，不减少算法完整1080行。

实际DDR低地址是R0/G0/B0/R1/G1/B1，canonical低byte是B0/G0/R0/B1/G1/R1；两个表示需要显式R/B重排。RGB128容器高12及RX高5都是padding，不能跨拍拼进像素。该核查没有推断camera Bayer phase/gamma已经正确，也没有验证TMDS采样相位或serializer。

## 3. 数值／native几何及保守沿表的实际有限核对

`r2_terminal_numeric_review`实际读PIO155…184/218…224、REPLAY86…92/109…127/168…176/207、PB与整合相关段、DISPLAY83；其报告的native模型SHA256为DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33，核7…27/100…128/309…417。这里只引用它的来源阅读，不冒作新native仿真实验。

初步有限结论和后续根选定沿表确认：

- RGB偏移八周期0/48/96/16/64/112/32/80，跨拍仅余数2/5；每8pair消耗三128bit拍，末pair359/offset80不读360。
- 两RGB128/两EDGE16/两ANN16合320bit；pending预留真实槽，每plane至多一个pending，valid＋reserved≤2。Stall不退休cache，已issued返回仍捕获。
- 两135bit decoder holding合270；mode5的720逻辑写事件对应2880native laneWE，不是405AXI拍，也不等于统一20bit写次数。
- P1=150、P2=86、P3=70、P4=48，数值合354；配cache/decoder/writer275为1219bit下界，身份/控制/状态另计。
- writer完整词数周期2/2/3/2/3，reader需3/3/4/3/3；全行2304词无pad，p959只2301…2303，最后lane3/addr460。
- 根选择旧JOIN退休后下一旧资格沿发RE：首RE e1/首次JOIN e4；p2 e6→RE2 e7→capture e8→p5 e9。p5 e9→RE3 e10→capture e11→p8 e12；p7 e11→RE4 e12→capture e13→p10 e14。
- 无停顿末JOIN e963、四级交付e967、末stage e968、末WE e969、最早READY e970，与原同沿候选启动差一沿。该确认是文字沿表推导，未包含DDR、CDC、全close、仲裁或服务等待，任意stall不保留无停顿时长。

物理BGR的早期猜测已由实际DISPLAY83撤销；本稿只采用真实R/G/B源序。完整DDR服务、全机资源和固定扫描期限不由这些有限结论关闭。新保存行卡的数值审阅回报单独附后，不能把此前文字沿表确认当新卡全文审阅。

## 4. 协议来源及实际新卡全文审阅

`r2_terminal_protocol_review`来源读取前后hash稳定：PB26058B（72…116）、整合49136B（123…160）、PIO56290B（151…185/218…240及148/212）、REPLAY46304B（65…135/137…203），hash均与行卡A相同。

来源核查得出：input FULL、render完成及ROW_READY必须分开；先真实out grant再input read；INPUT_RETURN只等该银行未来RE/pending/holding引用闭合，复制值另pin ctx，不等整行/scan scope fence。五RowCtx只在单行renderer、三out/两input以及复制像素改持独立scan_parent条件下成立。KEY164只访问已经真实绑定唯一ctx，不能按外部slot自造权限；out预留预计960不当完成证书。

新保存稿831FB871…的216行被该agent实际全文读回、前后hash一致。发现具体反例：旧L122“p954可预取RGB359”与L121下一沿RE规定冲突。p954 JOIN前cache357/358均占用，只有JOIN真实退休357后，下个旧资格沿（连续时p955）才能RE359，p956capture，p957首次使用；不能在p954同沿另造空槽。根已保存原831F快照并仅改L122，当前90E980…，根实际定向读回。

该全文审阅在有限scope未见其他新增反例：私有单owner流水与对外held区分清楚；五ctx上界有条件；银行返还独立于整体fence；预算排除完整控制/全机资源。它明确保留RP-B03以及kind/status/reason、out私退还、ROW_ASSIGN/bulk绑定等OPEN，当前不可实施，不是全球协议通过。

## 5. 真实首行身份阻塞与验收边界

PIO L157只在实际VSYNC分配scan_token，但L163的提前ROW472已经包含scan，L222又要求candidate首行VSYNC前ready；这是现存设计冲突，不能从后续真实事件倒造token。新行卡只记录预留执行token／prepare_id两阶段绑定候选，未选定或修改PIO；并发旧current/closing、candidate与fallback不得隐藏第四ctx/第四out。

三out周转、camera/DDR最坏服务、完整packed/目录/close/return族、scan事件/CDC及全机RAM/FF/LUT/DSP/STA仍OPEN。原预检v1/v1.1/v1.2不能扩成本卡实施授权。新v1.3及Gate待批输入未变，独立work仍不存在。本轮没有业务实现/可执行测试/TB、新工具构建、仿真、PNR、STA、bit/hex、安装、网络、硬件或数据库写入；正式PROJECT_STATE hash87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558保持。

当前目标回合判定为PROGRESS_OBJECTIVE_INCOMPLETE：新增实际局部设计、纯几何数据、来源审阅与一个已修的末预取文字反例；完整十一项工程未完成。本报告不标READY、不请求未闭合卡批准。

## 6. 收到的最终数值及修订确认

数值agent实际全文读取原卡216行/27561B、831FB871…，纯算术JSON53行/2099B、B2282C84…，以及上述native模型指定范围。最终有限结论无新增算术反例：405/720/2880、input18+RX7+output15=40、跨拍及末地址、writer/reader周期、1219bit数值payload、RowCtx865/KEY164和4325/3000/11508body均条件一致；下一沿预约和e963→e969→e970沿表一致，但不证明全行期限或资源fit。

随后数值agent仅实际定向读回当前稿L118…123，27684B，SHA90E98056A72E049EACEADC1885B89CCB5266EC947B4A97F6FDA09341CA8FBFC4；确认L122已消除同沿预取歧义。协议agent仅实际读回L120…122，前后同SHA90E980…；确认p954退休357→p955 RE359→p956capture→p957使用与下一沿规则相容。两者都没有将这个定向确认扩成当前全文或整包通过，没有写文件/实施/构建。
