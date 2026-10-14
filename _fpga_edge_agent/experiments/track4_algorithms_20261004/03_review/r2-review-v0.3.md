# R2 v0.3 / OBS组合设计审阅记录

2026-10-04；DESIGN_REVIEW_ONLY / NOT_APPROVED / NOT_RUN。B01/B02/B04仅设计关闭；B03/B05与R2及整包均仍NOT_READY。

## 1. 阅读次序、版本和实际绑定

先读[整包v0.3](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)B/C/D，再读[R2主稿v0.3](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)、[C0最终附件](../02_design/canny-stream-controller-sketches-v0.1.md)、[OBS最终附件](../02_design/canny-observer-project-sketches-v0.1.md)及[OBS实际审阅](observer-review-v0.1.md)。附件原文保留其写入时“待审阅/合并”措辞，当前审阅事实以实际hash记录为准，不改旧附件制造新hash。

| 文件 | 实际SHA256 | 实际证据范围 |
|---|---|---|
| R2主稿v0.3最终稿 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 | 29268B；全文保存读回预期一致；两路最终全文复核 |
| BATCH主稿v0.3 | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 | 13615B；全文读回及两路实际全文复核 |
| 候选来源基线v0.3 | E5F3EAE8A0BA5C33BA7179479F94DF086ED2832CAD0032B0F1527920BE68E547 | 11601B；39条实际路径/hash/bytes核对；不是整包批准基线 |
| OBS最终附件v0.1 | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 | 两路全文审阅及本次组合对应，26753B |
| C0最终附件v0.1 | 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844 | 历史两路全文审閱及本次组合对应，32502B |
| R2 v0.2实际快照 | 71F741C609F3DC5A045C7510AEB846EA9899F8965E7AE98CDDD2101321082B2B | 24287B；与修改前主稿同hash/bytes，未改内容 |
| BATCH v0.2实际快照 | 43CB8666E3F47EEF3C5A41D76842A87AFA73063B670E8733FA204762D630AD9E | 13290B；与修改前主稿同hash/bytes |

[历史R2 v0.2](../../../planning/design-TRACK4-ALGORITHM-R2-001-v0.2.md)和[整包v0.2](../../../planning/design-TRACK4-ALGORITHM-BATCH-001-v0.2.md)供旧审计核对。新39清单以不可变R2 v0.2快照取代35清单中的可变主稿来源，追加整包v0.2、OBS实际审阅及历史候选清单；不把当前主稿hash放入自己的来源清单形成自引用。

## 2. 本次组合修订与实际审阅

本v0.3将OBS的REQ09、IF09…11、OP07、T11及实际工程/预算/验证追踪合并回主稿。R1设计hash/160bit格式、原FE、C0/OBS附件不修改；RGB/控制B03及完整业务清单B05不自动关闭。

第一份合并草稿实际hash为FE4ACAB86AB71C8E69E282F7498F016766A2705A5356395384C3961C7C3FDD14。数值审閱代理r2_terminal_numeric_review实际全文读前/后核同hash，核BATCH/39来源/附件，未发现字段/数值/预算矛盾。协议审閱代理r2_terminal_protocol_review实际全文发现一处源终结事件被写晚：

| 草稿问题 | 最终精确修订 | 对应交接 |
|---|---|---|
| IF09/OP07将源停于CS fire；OBS §C要求C0 CS valid出现即终结旧源 | SRC在观察旧C0 CS valid的沿注册source_terminated并撤未接纳候选；真实CS fire才K保存完整CS/J锁flags及进入TERMINAL。CRCbusy时这些事件可隔多沿，不能混成一个 | R2-IF09/OP07；OBS-IF01/03及§C |
| 将上述源例外推广成任意held撤销会破坏保持 | 只对当前已终结源候选采用明示例外；CJ/CS及K record保持不变，新job仍等真实终态CRC完成 | OBS-IF04/05及R2-IF10 |

修订保存后主稿最终hash4162…A5A2全文读回与预期一致。协议代理再次实际全文复核该hash，确认意见关闭、与OBS/C0相容，没有新增OBS组合技术阻塞。数值代理亦实际全文读前后核4162…A5A2，确认旧CS valid终结SRC和CS fire保存/J→TERMINAL正确分开。两路均实际全文复核BATCH3703…35A7；来源基线E5F3…E547实际39条路径/hash/bytes全部相符，0缺失/0不符。

审阅覆盖125/185/592完整置入608、capture不shift/19次CRC/第20沿再capture、早CS不P门控、C10真CS/CRC后ERROR、20+FE8=28RAM结构预算、≤22000XLR/0DSP目标、实际四pin与40ns/reset例外的设计组合。上述是只读走查与算术/元数据证据，不是仿真、综合、PNR、STA或形式证明。

## 3. B05候选的发现和保留

另保存[核心流段与OBS逐文件合同v0.1](../../../planning/design-TRACK4-ALGORITHM-R2-FILES-001.md)，属于B05候选，未并入当前39来源或完整软件冻结清单。它明确21份核心RTL/模型/脚本/工程计划文件及10份TB、共享FE/F4诊断适配、NMS byte平面和阶段schema、向量/CLI/失败/报告边界；全部业务文件仍未生成。

该候选初稿3D274F56B97E6C9FC039496F697FD54F1870653E103AC60E9002F42C21BD1F62经数值代理实际全文读取原FE D/F1/H复核：F4各22bit重排、side121、D dir69:66、N153/NW409及hex高padding正确，指出两项具体缺口。根代理修订后当前hashE782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842（24178B）全文读回：

- job故障expected_pairs=null只免除完整硬件交付量；每个oracle文件另有kind/bits/digits/rows/hash/schema/path，严格非空行数/EOF独立检查。真实fault的完整数学oracle仍P行，按实际坐标比较前缀，不能将文件行数当实际交付数。
- 同一独立参考新增nms_windows_image纯数学合同，直接clamp九个原幅值/方向容器；vectors只打包，不复制RAM或从DUT导出期望。
- 动态故障CS由预声明terminal_policy及独立真实口账本核关系；固定CS hex只用于typed组件fixture，不从DUT CS自身造期望。

数值代理随后实际全文读回E782…2842最终候选，确认独立oracle文件rows和nms_windows_image入口两项初稿意见已关闭，未发现新的阶段字段/hex padding矛盾。该事实是最终稿的数值/文件合同设计审阅，不是实现批准。精确套件/timeout/工具引用、协议与全包组合、B03文件及跨批集成仍未冻结，NOT_READY/B05 OPEN。

## 4. 文档检查与未执行边界

[本版文档检查](document-checks-r2-v0.3.json)记录最终链接/表格/围栏、全文读回、来源/历史快照及字段/hex/预算算术。新增[CONTROL v0.2](../../../planning/design-TRACK4-ALGORITHM-CONTROL-001.md)和[REPLAY v0.2](../../../planning/design-TRACK4-ALGORITHM-REPLAY-001.md)已实际保存、全文读回并完成两路最终修订复核；[B03交接审阅](b03-handoffs-v0.1.md)绑定当前hash、四项本地修订及仍OPEN的父交接。它们仅为未合并B03候选，不能自动升级主稿/B03。README更新使用本次最终检查，旧检查仍绑定旧README和旧主稿。

业务源码/参考模型/TB/功能脚本/project/peri/SDC未生成；工作目录不存在。仿真、综合、PNR、STA、bit均NOT_RUN。原HDK、正式Manifest/H0/任务账本/数据库不修改；数据库未配置，不启动正式数据库流程或降级SQLite，无新安装/网络/硬件操作。

继续完整B03/B05和R3/R4/R5设计，整包成熟后统一指定版本集合、范围和基线供批准。当前不发起未成熟设计的实施批准。
