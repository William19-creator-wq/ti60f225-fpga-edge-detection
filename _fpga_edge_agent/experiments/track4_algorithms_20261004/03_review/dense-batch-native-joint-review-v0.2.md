# DENSE片上批次联合修订 v0.2：有限静态审阅

2026-10-05。结论：本轮形成明确的管理/数据/许可/JL接口、20bit包装和逐沿中文草图；三个具体问题已修正。状态仍为 NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN，不能把静态审阅当整包软件验证。

先读[整体设计](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md)的B/C，再读D交接、E操作草图、F预算，最后核[数字附件](dense-batch-native-numbers-v0.2.json)及G/H测试与追踪。历史[v0.1精确快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.1.md)保留，旧报告和事件不回填。

| 本轮对象 | 实际身份 |
|---|---|
| 最终设计v0.2 | 256行 / 44444B / SHA256 CCD1849F6DE1B375693664757CD60C661401F436D52C1EFDF8A03EEFF241E2E2 |
| 数字附件v0.2 | 310行 / 10169B / SHA256 D00C10E214D556E6D87BA46E9C57CDFC6FC0BAF1C72533EAD307C34689D10CA9 |
| 原设计v0.1精确快照 | 185行 / 28838B / SHA256 A2184F1CFACC9DC46939A1BD9AC82188758C55FD0C4620FDE7A2BAD5CE21043B |

## 已修正的具体问题

1. 当前公开 EFX_RAM10 模型的20bit词分为两个10bit写半部。WE0/WE1都必须随wr_en启用；R1的8bit模板不能直接复制，单半写会使1023→1024成为0。选OUTPUT_REG0、同步读后下一沿捕获、无同址同沿RE/WE；复位只门禁访问/视图，内存仍须真实CLEAR。DN-T13文字场景已追踪，未运行。
2. NMS跨批末行等待下一批首行；若DENSE退休等待这个数学判断，而下一批又等待退休才能清零，则成等待环。E4明确本批实际DENSE读者/复制关闭后可退休，延迟行交给原NMS快照；θ511/0及LINE结束仍保留。DN-T15未运行。
3. 初稿让BEGIN最后安装才分配lease，但部分查询/borrow/guard失败可能需要非零lease清账。D1/E1现规定首次可能外逃责任前预留非零lease，partial/UNKNOWN失败保owned1/原lease；完整实际安装才WAIT_CLEAR。纯本地且无租约/外部责任的拒绝才可owned0。DN-T14未运行。

管理550/658采用验证后ready，末ACK形成不等待自身消费；FLUSH成功只是READ_PREPARED，真正匹配消费、运输静止和GAP之后才NMS_READY。DNKEY298、数据426/307、许可811/922、CTX986及JL tagged最大槽已逐字段列明；专用内部写来源不伪装成原公开op1，实际许可和效果提供者仍未闭合。

导出按f0读、f1捕获、f2检查/追加/进cursor三个沿，满128bit后整个reservoir保留到块效果/END及entry/group/运输真实关闭。完整32批最低导出尺度425472、清地址8864，均为无stall局部尺度，非实测墙钟时间。

## 实际读回及独立审阅范围

root最终设计按1–90、91–175、176–256核读，组合输出中被截断部分另单独重新展示；数字附件310行全文核读。root来源实际段为SC86–118、SM55–98、NS35–70、公开模型25–58/100–120/254–415、R1 line_store_pair全文33行；本地两RAM说明root只核hash，具体段由numeric审查。当前项目入口/配置/状态/账本/数据库要求/Approval Manifest已读取；详细规范不是新审批。

| 独立审阅者 | 实际最终范围与限定结论 |
|---|---|
| dense_native_numeric | 卡83–86、111–115、117–150、165–196、214–219；数字附件全文此前已读、最终身份不变。双WE、同步Q、e0…e8、三沿导出和数值未见新缺陷；非整卡协议验收 |
| dense_semantics_compare | 卡76–90、110–116、216；确认部分BEGIN租约缺口已修正，该限定范围无新冲突；不认证真实DDR提供者 |
| dense_cost_compare | 最终D2 87–106、F3 188–194及85/112/216，JSON全文；43项独立整数核算匹配。字段/零填充/9453+78=9531/JL13157与备选13187准确；不是完整FF/fit |

三者最终均核256行/44444B同一SHA；JSON身份同一D00C…。没有用单人局部段冒充全机实现检查。

## 成本、保护边界与尚缺证据

新增具名holding为9453bit，JL六entry槽+72、六group槽+6，总增量9531；valid/失败ledger/实际源view/物理回调/控制等仍OPEN。新增16RAM使已列分支186/194，仍为部分预算。完整512θ/21bit投票与原1080p/识别质量不降；主候选保FIRST INIT和32次DDR CLEAR，不凭空扣旧字段/服务。

本轮预追加44项保护hash一致；R1 22、R2 48、Q0 44冻结条目bytes/hash均一致（Q0=31 files+4 tools+9 contexts）。首次元数据检查错用不存在的inputs数组，输出错误且未形成基线结论；已改按真实files/tools/contexts只读重查，最终bad均为空。此过程无持久执行脚本或业务测试。

真实资格安装/可信CTX借用与撤销、专用source到sole journal的prepared/effects/physical-visible/no-future/END、旧责任/元数据关闭及完整唯一实例/服务/STA仍DN-B01…03。必须把这些有限项合到共同指定设计版本与基线才可READY；字段已写不代替接线证明。

R1原批准软件交付123/123、PNR/STA/bit保持；R2和DDR Q0原具体批准问题仍待答。本轮无新源码/功能脚本/参考/TB、仿真/综合/PNR/STA/bit、数据库、网络下载安装或硬件动作；正式state/ledger/Manifest不改，本地R1审计例外不扩用。完整五基础/六高阶尚未完成。
