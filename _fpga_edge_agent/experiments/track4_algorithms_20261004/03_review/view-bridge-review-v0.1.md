# VIEW-BRIDGE v0.2 独立交接审阅实录 v0.1

2026-10-04。DOCUMENT_REVIEW；整包 NOT_READY / NOT_APPROVED，业务实现与运行验证 NOT_RUN。本文只记录实际发生的文档审阅，不是接口合并、运行许可或实现通过证明。

## 审阅对象与实际范围

- 主稿：[VIEW-BRIDGE v0.2](../../../planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001.md)，64477 bytes，SHA256 `C764162767F3C3A5308C2534DC95090CC8E7D9F83DA2A2AA1E96AA3E440DFF2C`。
- 原稿不可变快照：[v0.1](../../../planning/design-TRACK4-ALGORITHM-VIEW-BRIDGE-001-v0.1.md)，57827 bytes，SHA256 `F3126B2A4EBC36A92B274CCB897BD9C0230A9F2DA9F9BF77D3244B13119E2928`。
- 中间修订：SHA256 `36E67E5CF77BEA4C39935C5536B314731B5CD03238E7FADD5511E45D400E8AC0`，63490 bytes。它不是当前主稿。
- 独立审阅者：`/root/r2_terminal_protocol_review`。实际读取原稿、完整中间修订差异及相关章节；最后实际比较 C764 主稿与36E67的完整逐行差异，复读D3a、F-B与I节，报告仅第157、218、327、386行变化，读前后hash一致。
- 根Agent复核：实际分段读取原稿，修订保存后全文读回与预期文字逐字比对；本轮重新读取当前主稿，确认仍为C764、64477 bytes及预期全文一致。正文位宽计算为设计文档算术，未运行协议仿真。

审阅范围是新增桥协议与修订的文档内部一致性及相邻已知前提；没有审阅或证明尚不存在的RTL、真实provider、目录、物理布局或全帧性能。

## 发现、修改与关闭依据

| 编号 | 原有问题 | 当前设计及实际审阅结论 |
| --- | --- | --- |
| VB-RF01 | SRC已注册但J尚未启动时，缺少能返还原图的真实关闭路径；不能借不存在的J/JOB_TERM或虚构job0完成清理 | D3a增加独立PREJOB_SOURCE_RETURN160/ACK172；只在从未真实转移且provider的全部读写、在途及保持效果关闭后返还。转移成立则沿真实J对象路径，不混用S_ONLY |
| VB-RF02 | 已发布的source_offer86原合同要求保持；未建立撤销授权便直接撤offer会违约 | D3a增加PREJOB_OFFER_REVOKE160/ACK168。接纳沿先记录旧offer的真实fire；任何真实转移都返回TRANSFERRED。只有真实REVOKED回执授权撤offer，之后还须观察派生revoke_idle才返源 |
| VB-RF03 | 中间稿把接纳、后续校验与offer抑制写得不够确定，校验前仍可能真实转移 | C764规定接纳沿登记临时source接纳屏障，从第一后沿周期生效；后续校验继续以所有真实fire为准。合法REVOKED保持屏障直至回执消费且旧offer为0；非法/NO_MATCH在自身回执消费后解除临时屏障。失败隔离仍记录后续真实转移 |
| VB-RF04 | PLAN_EXIT形成可能与同沿新接纳CANCEL或新生成ACK冲突；保持EXIT时也可能引入新取消义务 | D段、E段规定EXIT形成依据真实RT已消费、GAP与本地空状态；同沿新控制fire/ACK形成阻止EXIT。EXIT保持期间CANCELready为0；EXIT消费后迟到取消为NO_MATCH，全部控制槽清空后才允许NEXTPLAN |
| VB-RF05 | CL_TERM仅证明闭包owner引脚/请求已关闭，不证明CLASS、QUEUE、GRAD、POINT与scratch全部实际回收；下一帧因此可能重复占用容量 | COMPLETE_CERT同宽352改为schema2，将原保留位拆为private_refs_retired1/zero3。仅在实际分配集合的全部私有目录引用已归还/退役后允许COMMIT；最终SRC/EDGE/ANN等仍按真正父引用/借用生命周期持有 |
| VB-RF06 | F-B统一接纳约定及I节版本可能与新增临时屏障、v0.2主稿不一致 | C764明确F-B的窄例外仅为source接纳控制限定，不执行原图释放或借用查找；I节同步v0.2。独立复核未发现此次修订新增矛盾 |

上述“关闭”只表示对应文字矛盾已修正并被实际复核。独立审阅原意为“未发现此次修订新增矛盾”，不扩大为整包、所有相邻实体或全部协议正确性的证明。

## 保持的契约与设计算术

- PREJOB撤销与返还使用独立命名空间，不能仅因body同宽而解释成旧OBJECT_RETURN或CANCEL。
- `revoke_idle = RXempty && ACKempty`为当前真实槽状态的派生观察，不增加寄存器，也不能由source_ready、自报已关闭或计数归零替代。
- COMPLETE_CERT的schema版本改变，下游须按schema2校验；当前CONTROL、REPLAY尚未实际合并新增PLAN_EXIT、epoch及撤销接口。
- 新增holding预算197位（S27、J170），当前桥候选合计5880位；这是设计容器预算，不是综合FF测量，也不包含未知真实provider容量。
- PREJOB160/168/160/172、PLAN_EXIT267、VIEW_TERM497及COMPLETE_CERT352的字段算术已核对；所有未来TEST均NOT_RUN。
- 撤回的目标尺寸、数量、对比度、噪声和遮挡硬边界未重新加入；完整1920×1080、全八邻域Canny与识别质量目标仍保留。

## 仍未关闭的整体义务与下一顺序

1. 将新增body、状态及退出/epoch授权规则按唯一owner合并到CONTROL、REPLAY和实际R4provider；逐连接及端到端复查后才能关闭B03。
2. 冻结真实对象目录、分配集合、引用释放/退役实体及元数据容量，证明private_refs_retired来自实际返还记录；VB-B02及R4C-B02仍OPEN。
3. 完成识别、源图/梯度/点集与最终对象的全部生命周期、容量、吞吐及错误清理设计；不能用主机数组或不存在的provider关闭物理资源。
4. 完成R5生产摄像头、显示、CDC、引脚/时钟/时序、实际RAM/FF映射与B05文件及验证编排。
5. 整套设计满足规范并达到READY_FOR_REVIEW后，提交指定版本、范围和基线，等待明确批准，再执行获准实现和软件验证。

本次只新增审阅文档；原HDK、正式状态、审批Manifest、数据库及运行时事件未修改；没有生成业务代码、脚本、TB、工程或约束，没有执行仿真、综合、PNR、STA、bit、安装、网络或硬件操作。

