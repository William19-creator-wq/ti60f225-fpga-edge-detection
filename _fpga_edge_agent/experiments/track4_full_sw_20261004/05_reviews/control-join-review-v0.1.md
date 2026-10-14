# CONTROL-JOIN v0.1 实际读稿记录

2026-10-04；主计划v0.14；只读设计审查及纯文档修改。状态LOCAL_DESIGN / NOT_APPROVED_FOR_IMPLEMENTATION，CJ-B01…06仍阻塞；不把文字审查写成仿真、整机接口闭合或READY。

## 1. 实际版本和范围

| 最终读回对象 | SHA256 |
|---|---|
| [联合主稿](../../../planning/design-TRACK4-CONTROL-JOIN-001.md) | B8DAED20BEA99636E7667CC7E69AA62317D84D5103DCC59A476821B31EFEFF58 |
| [阶段中文附件](../04_local-designs/control-join-phase-sketches-v0.1.md) | 333C1D29614A441662DFA086DDE7D5867937FA6625EF9D133A5311383D1BB2BF |
| [主计划v0.14](../../../planning/design-TRACK4-FULL-SW-001.md) | A5B76E2F2157C31BB033483B485E5D635A46FB99FFAA296ECDAC0A04EF310EF9 |

独立读稿者先完整读初稿EFCC3ADB…DF5790812，指出三处P1、一处P2；根修订后，独立读稿者读回主稿B8DAED20…31EFEFF58及附件9D76258D…771279F6，确认四项吸收并指出PREP/COMMIT header的op不同。根随后只修改该附件条件，实际全文读回最终333C1D29…D1BB2BF并逐字符与预期比较。最后一项不是已经另跑一遍独立RTL检查。

31份冻结设计/附件、28项FRONTEND输入、5补充来源、8相机辅助、2Demo文件、2封装/时序辅助及DISPLAY/CONTROL两份历史审计均本轮重新实际哈希，零差异。最终52份MD的路径、hash、链接、围栏、表格及编号检查以[当前审计](document-checks.json)记录为准。旧父稿保持原字节，只有联合稿J明示的控制差异覆盖旧候选；未声称全部数据/关闭端口完成。

## 2. 本轮修正及证据

| 发现 | 最终候选动作与检查位置 |
|---|---|
| 早到R绕过SNAP，video仍p0而PREP要求pF | 所有已接纳FREEZE均先成功SNAP效果ACK，真实安装pF/BLOCKED，再ABORT；主稿OP04/T08，附件W01 |
| COMMIT已valid后无条件ABORTED | 原COMMIT即使ready0也兑现；旧T真实终态后R执行；OP04/05、T12/14 |
| snapshot通知与选源等待混用 | 完整1353保存/核anchor即可1359，不等FREEZE/latest/首COMPLETE；ACK不解除hold，OP03/IF05，T09/13 |
| FAILED/Q后按猜测pF正常恢复 | 正常R需成功屏障及封口证据；未知隔离、T/R独立FAILED/Q终态，held成功不改；OP05/06/T23 |
| 算法KEEP_FROZEN仍撤FREEZE | kind0恢复才撤；kind1无引用可撤；kind2保位/Origin、只开冻结源离线job、不LIVE ARM；OP06/T18 |
| PREP/COMMIT完整header比较包含不同op | 仅op3→4推进，其余seq/epoch/expected/new policy/TARGET相同；附件R_COMMIT，T17/20 |
| R仅内部槽，仍被普通held SET挡住 | 独立669入口、parent_T_seq与receipt1246/done1002容量；IF02/T01/15 |
| 持久anchor堵stage，或业务ACK被当drain | stage914/920逐阶段真实效果；snapshot1353/1359独立，hold/旧scope关闭另核；IF04/05/T07…17 |
| 配置在晚SOF/FJ时改写 | 三result预留并形成job前锁旧C；后续SOF/FJ只报告已锁ctx，capture-only不保存业务C；IF03/D4/T03…06 |
| gate改写历史active，或无限seq/cfg表 | 新candidate查gate，历史合法RO/BIND保留；首次visible有界登记、三ctx/最近观察；D3/4/T01/02/19 |

字段算术：R669、receipt1246、done1002；stage914/ACK920；snapshot1353/ACK1359；TARGET198。T/R原body5642bit、primary P/reply1787bit、stage及snapshot原body4546bit/套、三result cfg1713bit。均不含运输端副本、valid/phase/缓存等；不是综合利用率。没有新增图像RAM/PLL/DSP。

主稿8要求/8IF/8OP/10不变量/24文字场景，附件6配置/AON操作及8走查；每项对应主稿H追踪，实际代码位置、数值参考、checker与波形未生成。中文阶段表按旧状态/实际fire/统一提交说明，CORE100/video74.25/AON25各自域独立。

## 3. 用户补充路径再次核查

另一只读审查者重新枚举用户指定VF与Demo根：VF11672展开文件、24份ddr3.v；Demo5254展开文件、展开ddr3.v为0。15个落地归档（VF13、Demo2）列成员全部成功；VF两SC1336 ZIP各有一份模型，Demo IMX219 ZIP有一份，共27份模型原字节SHA均AF83D644…F56F20EA。未发现2048Mb_ddr3_parameters.vh。

根本轮还实际读VF代表模型97/98默认den4096Mb/x16与122/123的den2048Mb include分支；读Demo tinyml ddr3_parameter.vh全文，BANK3/ROW14/COL10/DQ16/tCK2500ps。控制器2Gb几何不能代替器件模型参数头。完整定位与原byte绑定沿用[既有补充来源](../01_baseline/vf-demo-supplemental-evidence-v1.md)，旧文档不改。本轮未获得新的2Gb匹配材料；已有模型获取申请不重复新建。

## 4. 尚未交付

CJ-B01…06保留完整数据/关闭联合端口及PROCESS_SAFE/错误枚举、RC实体/识别指标范围、保持/冷初始化/真实停钟恢复、匹配2Gb模型和CSI/TMDS/PHY兼容、QoS/资源/引脚/STA及指定批准等缺口。旧各局部阻塞仍有效，不把依赖列到别稿就当关闭。

业务源码/功能脚本/参考程序/可执行测试/TB、功能仿真、真实PHY校准、综合、布局布线、STA、引脚生成、本次bit/hex均NOT_RUN。原资料、工具、正式H0/PROJECT_STATE/TASK_LEDGER、数据库和批准manifest没有写入；没有联网、下载、安装、解包落盘或硬件操作。理解验收待用户实际读回/作答。

本轮结论是PROGRESS：控制联合候选的关键分支和有限容量形成可审查文档，完整软件目标仍未完成。下一项允许行动为继续完整数据/关闭联合设计与依赖闭合；无READY或指定实现批准前不能生成业务代码。
