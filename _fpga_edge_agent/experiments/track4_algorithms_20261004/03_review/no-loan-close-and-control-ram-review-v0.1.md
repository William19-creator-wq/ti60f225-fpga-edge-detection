# 无借用关闭与控制 RAM：实际有限复核 v0.1

2026-10-04。设计分析/只读核查；功能测试、完整仿真、综合、布局布线、STA及bit均未执行。完整十一项仍未完成，所有候选未获实现批准。

## 实际输入与阅读范围

| 输入 | 真实摘要/大小 | 复核范围与结论限制 |
|---|---|---|
| [无借用关闭候选v0.1](../../../planning/design-TRACK4-ALGORITHM-NO-LOAN-CLOSE-001.md) | 最终3E075B87350009EAF391D937C176D34070A7C6EE97157C1A5F1B0F8BEA7E653E；22000B/184行 | root实际读回正文，并分别复核精确位域与最后class1编码delta；独立最终只核L68–77，不冒称全文最终稿复审 |
| 位域补充后的中间卡 | 643A193939CCBE46DB4751766D07F1CE8624FC999C2885868E5093D6FF55B20B；21681B/182行 | 协议agent实际核D1/D2位域及L64–87；随后只改class1忙类理由，位域和容量未改；此hash是中间读取身份，不是当前文件 |
| [唯一实例/RAM报告](production-unique-resource-and-control-ram-v0.1.md) | F3D84B4AB57CF457139C238B3F5988E73F3092BB94D7AFB6D0998BFEC2657C47；9619B/100行 | root全文读回；数值agentL23–92（第2–4节）；原语agentL51–93（第4节），各限定输入前后hash一致 |
| 原SCAN/HANDOFF | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243／F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 | root本轮完整读回；协议agent原SCAN L95–102/114–120/150–155，HANDOFF L86–100/112–120/128–142；来源不改 |

本次协作均限制为只读/文字，禁止业务源码、功能脚本、可执行测试、TB、工程构建与原HDK写入。独立协议agent为r2_terminal_protocol_review；数值与原语agent为r2_terminal_numeric_review及row_math_source_review。此前原始草稿的有限D/E/G/J阅读不能冒充最终全文复审。

## 发现、修订与实际结论

1. **否定证据缺口**：never_opened只覆盖从未发布OPEN；明确拒绝后的路径未编码。原granted0/STALE也不能证明旧请求未成功。候选增加原始决定class2及有界折叠，把409中原位改为no_loan_proved，N/R/G/U分别处理。实体目录/effects提供方仍OPEN。
2. **位索引澄清**：GRANT尾增2bit后，旧459整体在[460:2]，原字段绝对索引上移2；root修正“字段不挪动”的歧义。协议agent在643A输入核461/409/417布局正确，proved仍bit87。最后delta不改这些位域。
3. **忙类编码澄清**：原class1允许status2 BUSY搭任意非零reason，包括FIELD。修订为status2只配BUSY3/CLOSING_BUSY7/CAPACITY18，其它合法原始拒绝用status3，reason0及FIELD/status2非法。协议agent实际读最终L68–77，确认该歧义消除；没有因此宣布全部错误矩阵完成。
4. **资源口径去重**：DDR39含PHY22/桥17，ROW40含input/RX/output，FE共享仍有条件。原map89=85 RAM10+4 DPRAM10；153/156/164只是混合RAM类候选，不是153个已实现RAM10或fit证明。数值agent在报告第2–4节未发现新的算术反例。
5. **词对齐边界**：新GRANT461由23→24独立20bit词，七cache378→379；整组拼接848仍43词、总373不变。323关联加cache得新696/13920或702/14040，两RAM只在容量上可放；SCAN340word一RAM同样仅容量成立。两位独立有限核对均未发现算术错项。
6. **未省略的义务**：wide held/private、Q即时快照、热身份、端口仲裁、seq/真实目录/CDC仍另计。模型1R1W、WE两半10bit、同步读、RST不清mem和同址未授权限制保留，没有运行模型或证明时序/FF节省。

## 保留的下一步与边界

先完成完整实体目录、持久记录组提交/替换保护、即时held/private/热状态账本、R_ROUTE/W_CTX与所有真实seq/计数/CDC，再与camera/算法/显示的最坏服务合并。新协议及RAM候选尚未被整合v0.8、SCAN或HANDOFF吸收；联合冻结后才可评价READY和指定版本批准。

本报告保存真实限定检查及其差异；既有IP预检仍TERMINAL_WITH_FAILURES。没有新增算法work、业务实现、可执行测试、sim/map/PNR/STA/bit/hex、网络安装、数据库/正式PROJECT_STATE/Approval Manifest或硬件动作。用户未作答的理解验收仍待检验。
