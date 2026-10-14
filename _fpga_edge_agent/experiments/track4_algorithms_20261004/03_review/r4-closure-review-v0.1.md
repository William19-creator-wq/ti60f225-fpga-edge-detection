# R4精确闭包局部合同审阅 v0.1

2026-10-04。READ_ONLY_DESIGN_REVIEW / NOT_READY / NOT_APPROVED / NOT_RUN。阅读[整包](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)→[R4-CLOSURE v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md)B/C/D/E/F/G/H；[资源比较](r4-closure-resource-comparison-v0.1.md)单独说明容量与扫描候选。此报告关闭局部文字歧义，未关闭真实后端、目录、完整bundle/provider或R4整体。

## 1. 实际绑定与读回

| 对象 | 实际SHA256 | bytes及实际阅读 |
|---|---|---|
| [不可变原v0.1](../../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001-v0.1.md) | 4B7F70C49E0E01AF46AE4A76EBE1D0F4150C21281A0E1C53E5A0AD5AFFF87482 | 57485；根实际全文分段读回；作者交接自查与独立协议者均全文读取；复制前后同hash |
| [当前v0.2](../../../planning/design-TRACK4-ALGORITHM-R4-CLOSURE-001.md) | 5B1470198FF6CA4A2CDADD3B7E60A0C4B0C59613956959A256EE7622AC185B11 | 63263；根完整读回与期望修订全文相等、读前后hash相等；独立协议者完整diff并全文读回当前稿、hash前后相等 |
| R2 v0.3 / C0附件 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 / 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844 | CLASS125/CJ142/CS592真实资格；独立协议者重读C0全稿核取消flush与L停ready |
| CONTROL / REPLAY v0.2 | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 / 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B | 独立父job、借用/关闭与软件epoch边界；原消息不修改 |
| 资源比较 | 9B0A2827762FE67E712BB793C7BB2C2D51B3F15355242293421B2CE9DA9C293C | 完整工作集与物理资源证据分开，真实backend仍OPEN |

作者交接自查明确属于作者自查，不称独立审阅。根为独立全文审阅，另有独立协议者原版与最终修订复核；旧版结论不直接套用到当前hash。

## 2. 发现与修订

| 项 | 原问题 / 当前修订 |
|---|---|
| R4C-RF01 / D3 | 原统一要求coord对应index会错拒head>0的READ_QUEUE。现先按op分派：op0/4为pair坐标、op1/2为pixel坐标、op3为QUEUE entry且coord0、op5 index/coord0，之后才寻址。 |
| R4C-RF02 / E4.1 | “对应CLASS归属”可能暗加READ_CLASS破坏操作界。现在由S当前绑定和不可变append provenance证明，不增加读取；C仍核当前echo/entry高位与合法坐标。 |
| R4C-RF03 / D2 | IF01…12三列正文对应两列表头。当前表头/分隔三列相容；原快照保留原字节与已知格式缺陷，不修历史冒称原版通过。 |
| R4C-RF04 / Completion criteria/A-B01 | 原文字可能要求先取得实现/工具证据再批准。现在批准前冻结真实可综合架构、容量/端口/目录/验证计划；获批后实现、运行软件及工具证明，实际工具NOT_RUN不单独形成批准前循环。 |
| R4C-RF05 / D4 | 集中COMPLETE/FAILED/CANCELLED/Q矩阵，显式flags/overflow bit序、首因mask、真ACK settled、完整P/N/token/close；失败真实前缀不强制相等，Q不返未知pin。 |
| R4C-RF06 / IF09/D4/E6 | 正常CLOSE/SETTLE未冻结term时首次cancel记reason10并阻COMPLETE，即使回ALREADY；终态已valid后不改body。ALREADY只表示停止生效，控制ACK独立兑现且不得越过GAP/epoch复用。 |
| R4C-RF07 / D4/E3/T09 | queue_started只在旧SELECT提交GENERAL时置1；BIND.queue_bound/首claim不同，两快路径为0。失败前缀有唯一观测事件。 |
| R4C-RF08 / D4/T02 | LC stream_started取实际SEAL中CJ事务接纳事实；CS内部共同ARM启动是另一事实。CJ已fire而ARM取消可前者1/后者0，不伪装成功。 |

独立协议最终回报：全部上述局部问题已闭合，未发现新增局部协议矛盾；真实B01…05继续OPEN。C0取消flush可撤未交付CLASS且不等外部尾ready出失败CS，与L停止CLASS ready相容。

## 3. 文档算术和集合证明的限度

已独立核LC270/PREPARED277/SEAL863/LC_TERM776/CLJ438/BIND511/RQ324/RSP449/CLOSE294/ACK502/CL_TERM1013及loc48、算法计数150的字段加法；均相等，不是可执行测试或网表结果。

成功GENERAL的K为实际接纳点数，N次seed读、K次claim、K次pop、B次有效邻居读、N次导出读、P次EDGE写及3个phase提交，故closure request=2N+2K+B+P+3；load另P+1。B是未来实际request事件的独立派生值，不新增隐藏寄存器，不与包含越界的neighbor_checks=8K混用。全链≤13N+4与既有保守界相容。两个快路径仍全N导出/真EDGE提交/关闭。

claim永久将非11候选变11且与append成对可见，每pixel至多一次，head≤tail≤N且活动pop完成后才判断结束；因此完整八邻域可达集合及有限性没有改成固定链长/轮数。最新值forward、实际journal/packing/端口仍必须由后端设计兑现，不能拿集合证明当物理实现证明。

生产CLASS2/QUEUE32/EDGE1共9,072,000B；实际Ti60资源映射尚未完成。扫描候选省队列但不免CLASS/原candidate重放、SRC/GRAD/ANN来源与同时寿命/吞吐义务。完整backend、refs目录、不可变provider、完整bundle、生产视频/资源/STA及B05文件/套件继续OPEN。

## 4. 验证与交付状态

本轮仅只读调查、纯文档修订、旧版快照、实际全文读回、字段/容量算术和设计审阅。G/H场景及独立黄金图/台账尚NOT_RUN；未产生业务RTL、模型、功能脚本、TB、工程/约束或业务work目录，没有仿真/综合/PNR/STA/bit、网络安装、硬件下载或数据库执行。

原HDK、规范、R1/R2/BATCH/CONTROL/REPLAY字节及正式状态/Manifest/数据库保持。当前R4-CLOSURE及整包NOT_READY/NOT_APPROVED，不请求未成熟实施批准；成熟整包仍按明确版本、范围及共同基线统一批准后实施。

