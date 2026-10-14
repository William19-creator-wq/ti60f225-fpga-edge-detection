# 生产行全局交接候选有限审阅 v0.1

2026-10-04。当前完整十一项仍未实现/验证；本记录只是来源、字段、有限身份与关闭检查，不是功能仿真或整个设计通过证明。候选入口为 [PRODUCTION-ROW-HANDOFF](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md)。

## 实际输入与阅读范围

原卡33063B，SHA256 **888987F0EC9E75CB931E06D21BFD216C90265991F640589566F8CDB54AFC391F**，保存在 [原字节快照](../../../planning/design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001-v0.1-before-mode0-scope.md)。root实际全文读回原卡；数值审阅实际读D1–D4 L69–124，协议审阅实际读L73–143。没有把未阅读章节称为独立全文评审。

修订卡34042B，SHA256 **F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67**。修订仅D2 L98/L100与J记录：root实际读回L94–104、207–216；数值审阅仅实际核L98/L100/L215；协议审阅实际比较原快照与修订，读前后hash一致。最终全文没有重新由两位独立审阅者逐行阅读。

上游来源实测保持：PB0C0EE05D…FFC63E40、ROW1C3E3910…F7A3B2C8、SCAN3D43D459…E31138E243、PIO39EA4322…C4C2DE10、RAW7704C56C…4AB6C9DD。RAW实际64846B/367行，与旧摘要中的其它hash不同；以当前文件为准。root读取ROW全文、PB当前及前序同hash全文、SCAN/PIO指定段、整合v0.8入口与I/K；因并行工具外层输出截断的片段不冒称本轮全文读到。

只读对象/后端审阅实际范围：RAW L51–60、83–99、109–126、130–158、164–176、238–244、254–274；PB L44–80、100–110、138–150；VIEW L76–83、133–151；REPLAY L67–78、97–111。后两源实测hash分别C7641627…E440DFF2C、7187B09D…24D68B，未用旧PC/UART合同提供新DDR关闭证书。

## 数值与权限结论

候选REGISTER906/914、OPEN387/459、ASSIGN409/581、FETCH315/TERM342/ACK350、FILL323/331、PRIVATE_RETURN545/553、CLOSE491/499的逐字段位宽相等。新增逻辑body下界12796＋6240＝19036，FETCH2014后21050，加七组last cache7405后28455；旧五RowCtx4325独立并列时32780。valid/FSM/ledger/sequence/目录/R_ROUTE/CDC及物理资源均未包含，不能报告为FF占用或全机fit。

独立row_seq与caller assign_seq不合并，五份64bit关联320确有必要。行计数11、全exec burst14、全exec R19在每目标成功分配一次及错误停止新行的条件下足以容纳1080/8640/437400。单burst合法范围必须先核plane：RGB5760/EDGE240/ANN480B及16B、4KiB、count≤128；decoded_words最大128/120/240，不拿9bit容纳非法EDGE/ANN1024词。FILL九计数对应overflow9，CLOSE六计数对应overflow6。

原稿存在同一确定反例：OPEN无target_y且每exec一份loan，但D2将mode0逐行001/010误写成OPEN权限。首行仅借001将使目标540的EDGE010没有权限。修订明确OPEN整exec并集011，ASSIGN逐行001/010核历史source_y与子集，关闭了这个限定反例；消息位数和容量不变。

## 生命周期有限结论

- REGISTER906可由唯一V核并实际消费完整成功PREPARE ACK后产生，无需为重复其非生产字段改成1043。该来源责任不能用于证明未知PREPARE grant。四独立STOP槽按实际D slot保存早到通知，REGISTER容量不依STOP排空。
- CORE旧目录另核正确报告ACK/本地债与借用已闭；新注册由真实新PREPARE对应D旧槽实际FREE。因此指定段落没有必须增加UNREGISTER族的反例；完整CDC接线仍未验证。
- 晚FULL仍接纳结账并退未读input；已经形成ROW valid而未fire也走原472族，不能改成私有RETURN。免KEY164的545依赖真实out目录持久保存KEY164↔472关联，运输ACK不是该目录。
- loan按源读/fill/route关闭先返，已复制银行/P/ctx另管；CORE producer_rows取正确完整OWNED证据，D取其本域ROW接纳，assignment/WE/CDC入队不代它。指定段落未发现等out整体FREE才能返loan的环。

对象审阅明确：BULK loan只能真实完成bundle目录O授予并登记，byte permit、DDR/fetch/IMPORT不能自授。RAW logical_commit、typed success、whole-plane commit、物理B/R结束、route退出及loan归还是不同范围；16B RMW锁须覆盖全部真实访问者与已初始化rounded span。UNKNOWN写不能由发送W拍数补造精确prefix；RAW CLOSE也不自动退O borrow/parent。

## 保留未决与实际动作

明确拒OPEN无loan的最终CORE_CLOSE编码、实体O/plane scope与旧RAW/VIEW映射、完整错误矩阵、持久关联目录、真实DDR effects/校准/模型与保护key、四域CDC/epoch、所有控制body的RAM/FF映射、调度及最坏服务/全机资源/文件基线仍OPEN。旧源稿没有吸收本卡字段，不能将本记录当直接接线或实施许可。

本轮实际写入只有新卡、原稿同hash快照、本记录与README入口/原字节快照及追加本地审计。没有业务源码、功能脚本、参考程序、TB、新work、构建/仿真/综合/PNR/STA/bit、网络/安装、正式状态/数据库或硬件动作。NOT_READY/NOT_APPROVED/NOT_IMPLEMENTED保持；后续沿完整目标补目录、服务与资源，不以本次有限审阅代十一项验收。
