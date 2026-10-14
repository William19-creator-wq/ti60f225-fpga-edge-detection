# 六源三结果联合稿：实际限定复核 v0.1

2026-10-04；Node TRACK4-ALGORITHM-SLOT-JOIN-001。以下由主 Agent 根据实际协作返回记录保存。设计分析、算术复核与实际RTL/仿真/综合/PNR/STA分别记账；本文不是实施批准，完整工程仍NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED。

## 1. 对象和修订对应

| 对象 | 字节与SHA256 | 实际核读范围 |
|---|---|---|
| [布局JSON](../01_baseline/production-slot-layout-v0.1.json) | 11516B，9B4E4A2E70257714FD09CA33E63D4FB00581763E06F166EE03FFAA4AE1C42D75 | 数值审阅全文；主Agent全文读回、定向地址算术 |
| [信用关闭修订前精确快照](../../../planning/design-TRACK4-ALGORITHM-SLOT-JOIN-001-v0.1-before-credit-close.md) | 26386B，7711DF9929780113E927856C950BEF631E92CF8DB52DF2E2E916BC468D1E997F | 数值审阅全文、协议审阅全文；主Agent分段全文读回 |
| [VIEW分支修订前精确快照](../../../planning/design-TRACK4-ALGORITHM-SLOT-JOIN-001-v0.1-before-view-credit-branch.md) | 29423B，E9BA7C54A9AA56D1A2832B4E19A1D03376A9AC72F692A2EF71B990C9BE48ACEE | 协议审阅214行全文，读前后hash一致；数值仅新增D2/F/T01–T03；主Agent实际读回变更 |
| [当前联合稿](../../../planning/design-TRACK4-ALGORITHM-SLOT-JOIN-001.md) | 29682B，6BC159677B861E382E3CAA10164CC96B768FAF047734791EFCE3AD9B5AA995FA | 主Agent实际读回OP04；仅该段在E9稿之后改变，协议最终实际核D2 L86–106/OP04 L136及完整差异，读前后hash稳定 |

旧输入实际来源核读：PERFORMANCE v0.2 A6CF179175A06195391C484745C3BC0E880A50303F5D8838C09BE843E9B87469、PIO v0.2 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10、整合v0.4 9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3。两名审阅者此前实际全文读取三份；数值另核R4R对象编码，协议另核CONTROL/VIEW。协议子审阅实际全文读取CONTROL313行、VIEW410行，绑定2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107及C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C，没有冒称核读其未读的PERF/PIO。

## 2. 数值审阅：实际7711全文及9B4布局

审阅者 `/root/r2_terminal_numeric_review` 实际全文读取两对象，限定核查未找到新的数值矛盾。

1. 八大区首尾连续、不重叠，base/end均64B对齐；终点0x05440000。Logical合73,781,629B，物理88,342,528B＝84.25MiB；128MiB生产区余45,875,200B。metadata等尚未计入。
2. private实际编码3…20及23…25，共21对象；CELL11两half不多计对象。三持久RECORD均为object22，分别对应结果槽0/1/2。private logical414,973B、rounded415,104B；AUX加全部guard为428,928B，结束0x053A8B80，余619,648B。逐条logical_end、physical_data_end及guard相等、不重叠。
3. KEY162、RETURN167/175、SOURCE_OFFER182、BIND883/1083、ABORT327/337、AUX_REGISTER295/303及AUX_RETURN293/305均等于各字段位宽和。
4. 三J历史1971bit、三扫描ctx2040bit、ROW双端body11508bit下界算术正确，未被正文误称完整综合利用率。
5. source索引3bit仅0…5、结果索引2bit仅0…2。F0/64/65和F7值域条件一致；六源/三结果/两物理路由场景没有增加隐藏槽。建议T01显式枚举非法source6/7、result3；根已在后续稿补入。
6. PROFILE128只预留容量、不授C.profile_ref资格；guard不授普通访问；RECORD不随private退休释放，正文与JSON一致。

此结论不关闭目录、错误矩阵、生产服务或全机预算。审阅者未写文件、执行编译、仿真或其他功能工具。

## 3. 协议审阅：7711反例和E9实际全文

审阅者 `/root/r2_terminal_protocol_review` 对7711全文发现真实遗漏：D2规定O最多一份未结束信用，却未规定成功COMMIT如何结束该信用。若直到整个bundle退休才结束，A持续显示将阻挡为FREE槽B分配信用；若BIND_ACK就删除KEY，则后续ABORT失去身份。主Agent保存7711精确快照后，补D2/E/F/T02/T03；没有实施业务代码。

E9稿实际214行全文、读前后hash一致，审阅者报告：

- D2明确RETURN、ABORT成功ACK消费和成功COMMIT/匹配REPLY消费三条结束路径；REPLY由原R4接收方消费，与原VIEW方向相容。
- BIND不结束事务；新旧KEY分别保存，810bit下界正确；COMPLETE实体和历史继续保留，下一信用等待后续旧资格。
- cancel/quiesce履约旧held；下一信用不授接新source资格。原信用结束遗漏已在限定文字审读中关闭，没有找到新增实质协议矛盾。
- OP04仍有一处可避免的箭头歧义：把发下一信用串在当前VIEW父grant之前，三槽全占用时可能被理解成当前结果等不存在的FREE信用。建议改成互不等待的两条独立分支。

主Agent保存E9精确快照，仅将OP04改成当前VIEW推进与另一FREE槽新信用各自独立，形成6BC当前稿；其他段与JSON不变。协议审阅者随后实际核D2 L86–106、OP04 L136及完整差异，确认29682B/6BC、读前后hash稳定，返回“当前结果发布与下一信用明确互不等待，原顺序歧义已关闭，与D2一致；本次限定复核未发现新矛盾”。这是6BC限定复核，不冒称6BC重新全文审读；B01…05及整包NOT_READY保持，审阅者未写文件或执行工具阶段。

## 4. 数值新增段限定复核：E9

`/root/r2_terminal_numeric_review` 实际核读E9的D2、F及T01–T03，返回准确29423B/E9摘要；未发现新增数值或KEY容器矛盾。KEY＝32＋64＋2＋64＝162；J未花费162、当前BUILD162、O三个历史486，合810bit payload。O信用held、请求/ACK与状态另计。sourcefire转存后，新信用独立保存，不覆盖旧BUILD；COMMIT/REPLY成功消费结束事务但保留bundle，接新source仍等待旧J终态/scratch。BIND_ACK、拒绝COMMIT、错echo、Q不结束信用；非法槽6/7和3场景与范围相等。

该结论只覆盖上述新增段落；7711全文及9B4布局结论仍绑定旧hash。没有修改文件或运行实现、测试、构建。6BC仅OP04文字改变，没有新增位宽/地址/容器字段；不将这一差异事实冒充新的数值全文审读。

## 5. 门槛和证据边界

SJ-B01…05的真实目录/provider/错误矩阵、epoch profile、共享/冻结源政策、生产bulk/DDR服务期限、全机RAM10/FF/DSP/PLL和完整文件/schema/GT冻结仍OPEN。文字反例补清和容量算术不能替代功能仿真、综合、PNR/STA、bit、摄像和识别质量证据。

本轮仅保存设计、纯数据布局、快照、阅读入口和实际审阅报告。没有算法work、业务源码/runner/模型/TB、工程/约束生成或新工具构建；未改变有限预检v1.2终态、待批准v1.3/Gate设计、原资料、Manifest、正式状态或数据库。当前软件整包目标仍未完成。
