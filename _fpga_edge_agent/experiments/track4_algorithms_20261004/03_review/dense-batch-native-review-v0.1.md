# 完整 DENSE 片上批次候选的有限审阅 v0.1

2026-10-05。只完成文档/数学/协议静态审阅；NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本报告不关闭完整十一项目标，不是新的实现批准、测试结果或全机资源/性能证明。

阅读[设计与中文草图](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md) B→C→D→E→F，再查[数字附件](dense-batch-native-numbers-v0.1.json)。来源原文、正式状态/审批和原冻结输入保持；R1既有软件交付不重新测试。

## 1. 有限结论与选择

当前逐票DDR路线对32E组做512E entry和30208E journal native操作。只bulk化WORD保留每lane59次native及DDR/END。候选采用每批16个native512×20 bank与每lane唯一高位marker，精确恢复277个21bit计数，全部512θ不减少；全E投票后冻结本地表，以728个16B普通单成员内部写入组覆盖整个11648B对象，再确认真实关闭才开放NMS。

主候选16B保普通member16/done1宽度，32批固定23296entry、1374464 journal native、2935296 JL单向fire。新增16RAM使原部分170/178分支成为186/194；本地bank操作另有1024E+283648，原FIRST INIT与32DDR CLEAR费用保留。64B仅成本比较，不能自动省四倍DDR字节。完整owner/source/provider与实例/FF/DSP/服务仍OPEN，没有声称满足处理fps或全机fit。

## 2. 保存、真实读回与有限独立评审

| 审阅者 / 实际范围 | 结论与限制 |
|---|---|
| root：初始设计1–70、71–140、141–186分段全文；最终L97及JSON1–198全文 | A–L状态、草图/追踪和数字读回；没有运行实现 |
| dense_native_numeric：初始设计1–186、JSON1–198全文；最终95–101 | marker总票不变量、22bit加法、同步native条件下e4真实提交/取消、927字段、148bit容量、尾零和五组算术样本未见明确错误 |
| dense_semantics_compare：初始设计1–186全文；最终L97 | 成功域/new source/许可/读门/取消保持均明确需共同修订，没冒充原兼容或批准；实际provider未审证 |
| dense_cost_compare：最终设计104–129及少量定位句、JSON1–198全文 | 20固定量＋5样本各10项独立整数核算均匹配；明确非全卡/全接口审阅、非EDA验证 |

初始设计28544B/186行/SHA79E7A79E8144BF69843D5D70246C72F589692CE035AEAF05D25362A7D1044FFD。数值评审指出L97的chunk形成/移位关系可能误读为免费128bit保持槽，root在保存候选阶段仅改该句：整个148bit reservoir冻结，直到块实际效果/END/entry/group退还/旧运输/GAP全关闭，才移动低128bit并继续追加/RE；adapter另需保持副本则补DN-B03预算。没有改927字段或成本。

最终设计28838B/185行/SHA A2184F1CFACC9DC46939A1BD9AC82188758C55FD0C4620FDE7A2BAD5CE21043B。numeric实际在内存恢复旧L97并补末尾LF得到旧字节/hash，证明其余正文未改；少一行是末尾空行移除。数值/协议评审各实际确认最终delta与身份；cost另读回最终104–129。不能把初版全文审阅冒充最终全文单次审阅。

数字附件6209B/198行/SHA DFB78F6478CCCEA463C6131D248FD453AA78CBECA05D73DD6D994C15C83FE87E，全过程不变。conditionalBytes样本不含主候选另保留的372736B DDR CLEAR，FIRST INIT/NMS/NUM/其他phase/adapter管理和等待也未纳入。

## 3. 仍需共同设计的有限项

1. DN-B01：真实batch安装/租约、POINT资格、native/DDR权威成功域与STORE/O/SC动态最新读门；最小570字段不是完整wire或成本。
2. DN-B02：可信内部packed-span overwrite到RA/JL/physical的真实来源、新内部mode、whole-span许可、prepared/state/可见/no-future/END及退休桥。公开op1(object8)仍禁止，不能伪造原799。
3. DN-B03：同步native包装真实延迟、各端保持/expected/valid/取消/复位/借用实例、完整RAM/FF/DSP/时序及整帧服务预算。

设计卡DN-T01…12全为后续文字场景、未运行。本轮无业务源码/功能脚本/参考/可执行测试/TB、仿真/综合/PNR/STA/bit，亦无DB/硬件/网络/下载/安装或保护IP体读取。审批/正式状态保持，本地文档检查点不复用R1审计例外。

## 4. 源与基线检查

保存前35项来源/状态/既有交付guard均匹配。R1 v1.1的22份、R2 stream v1的48份、DDR Q0 v1的44份输入分别按实际长度和SHA复核，无不匹配；新候选未加入任何冻结记录。PostgreSQL环境变量仅核存在性为false，无内容读取/写入；当时EDA进程匹配列表为空。最终文档/旧prefix/追加事件身份由唯一外部检查点登记。

R1 APPROVED/DONE_STOP_AFTER_BIT，IP预检原失败终态保留；R2/Q0 READY但原指定批准尚未到达，不重复发问。下一工作是上述有限共同接口与预算吸收，不继续凭空增加通用卡片、不拿文档数量当实现完成，也不降低原功能范围。

