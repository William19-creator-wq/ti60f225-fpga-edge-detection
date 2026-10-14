# Canny OBS v0.1 设计审阅记录

2026-10-04；DESIGN_REVIEW_ONLY / NOT_APPROVED / NOT_RUN。仅关闭本附件已发现的设计审阅问题；R2主稿仍v0.2、B03/B04/B05仍OPEN，整包NOT_READY。

## 1. 实际版本与范围

按[整包v0.2](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)→[R2主稿v0.2](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)→[C0草图](../02_design/canny-stream-controller-sketches-v0.1.md)→[OBS最终附件](../02_design/canny-observer-project-sketches-v0.1.md)阅读。OBS是可暂停的算法观察工程设计，尚未合并回主稿。其引脚和时序内容是拟实施约束，未由工具验证。

| 文档 | 实际SHA256 | 证据范围 |
|---|---|---|
| OBS最终附件v0.1 | 12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847 | 26753B；全文读回、预期文本一致；两路最终全文审阅 |
| 控制/显示来源整理v0.1 | 192D9DCED0F1189E6804423040BA45FDAD6DAE8F00B9D87893DE31E649DD91A0 | 9835B；来源整理及尚缺合同，未冻结新实现接口 |
| OBS候选35来源清单 | 0EAD5B16404B21C0E0B2005AA89BFAEE29F143B3CF447FF15E0EE86C4FA9F196 | 来源hash/bytes逐项核对；不是完整软件批准基线 |
| 当前R2主稿v0.2 | 71F741C609F3DC5A045C7510AEB846EA9899F8965E7AE98CDDD2101321082B2B | 本轮未改；不能因附件审阅自动关闭B04 |

## 2. 审阅发现与修订

审阅包含608bit记录、32bit CRC分组、CLASS/GRAD真实fire仲裁、CS保存/提交、正常及半帧源故障、取消恢复、J/K交接、数值/前缀统计、资源副本、四pin和40ns约束计划。这里是人工式设计走查，没有运行RTL或测试程序。

| 草稿发现 | 最终合同及定位 |
|---|---|
| 完整CS的J/K保存职责及副本数不一致 | K独占完整terminal CS，另保存last CS；J锁定判定flags及源计数。明确C0 CS592、K工作记录608、K终态CS592、last CS592合计2384逻辑bit |
| observer sticky后J立即ERROR会关闭真CS接纳资格 | J保持FEED/DRAIN，取消当前C0并等待真实CS，再等待该记录CRC完成；TERMINAL结束后才能ERROR。OBS-C10明确该路径 |
| IF07/IF08的字段和追踪不完整 | K→J为87个逻辑bit的并行字段，不宣称另一个packed bus；J→K锁定terminal_fixture_match、terminal_complete_ok；IF08及操作追踪补齐 |
| 成功/故障判断缺独立前缀关系和上下界 | 成功必须实际完整源、分支计数/EOF及CS相符；固定半帧故障允许真实短前缀但检查拓扑、错误位置、计数及无EOF，不能判作成功 |
| 验证矩阵与综合裁剪表述不够明确 | 生产全像素median×retain四组合及故障/下一任务恢复单列；允许FE Y_ONLY无用历史结构被合法裁剪，检查必要历史与数学，不要求恰好保留预算RAM数 |

最终协议审阅代理r2_terminal_protocol_review实际全文复核绑定12D0…1847：CS保存所有权、IF07/08、终态接纳和C10问题关闭，未发现新增协议等待环；NOT_READY/NOT_APPROVED/NOT_RUN状态准确。

最终数值审阅代理r2_terminal_numeric_review实际全文复核绑定同一12D0…1847，并核对候选基线0EAD…F196：未发现新增数值、记录、计数、资源副本或pin/SDC合同冲突。两路均为只读审阅，未写业务代码、测试或工程。

## 3. 检查和保留项

[文档检查v0.1](document-checks-observer-v0.1.json)记录对应版本的链接、表格、围栏、全文读回、35来源hash/bytes及CASE/TEST/OP/IF计数。10个CASE、9个TEST、5个OP、8个IF均是文档条目；TEST仍NOT_RUN。

记录服务预算为19个CRC分组、相邻capture至少20周期。25MHz下grad-on完整任务预算1.6588808秒、grad-off为0.8294408秒；这是固定记录数推导，不是实测吞吐。125/185/592bit合同统一封装为608bit记录，资源仍是设计预算，CRC组合深度必须未来由真实STA检查。

B04附件问题可在本范围记录为已审阅，仍须R2主稿组合回写、版本更新和检查后才能评估B04设计关闭。B03只完成来源合同整理；配置owner、调度、重放及显示交接尚待设计。B05、完整闭包、识别和生产视频集成仍待补齐，整包未READY，不发起未成熟设计的实施批准。

业务源码、模型、TB、功能脚本、project/peri/SDC均未生成；仿真、综合、PNR、STA、bit均NOT_RUN。工作目录不存在。数据库未配置；此记录仅设计文档，不修改正式状态/Manifest/数据库，不启动正式Agent流程。原HDK只读，无新安装、网络或硬件动作。
