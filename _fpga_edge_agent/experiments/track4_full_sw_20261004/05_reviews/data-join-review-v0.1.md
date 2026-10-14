# DATA-JOIN v0.1 实际读稿审查

2026-10-04；TRACK4-FULL-SW-001的联合设计审查。**只读设计分析，非RTL评审或功能验证；LOCAL_DESIGN / NOT_APPROVED。**

## 1. 版本与检查范围

[主稿](../../../planning/design-TRACK4-DATA-JOIN-001.md)最终SHA256：

B09B9FEAC91698E2DC482F92EEB287DB172C5D1A9229D7C9DA226B630FB69408。

root实际读取完整文件并与预期文本逐字符匹配：30,340字符；两位独立审查者也实际读回该SHA，分别收束于camera/FE/display和DDR/phase/grant/reader边界。先读取旧FM/DS/Canny父writer/RC/CAM/DP/CJ的实际D/E；旧候选输入字节未改变。初稿SHA为3CF22D9056D850549AC93511BE722F77EF4073B4ADC782AE20E8DC358CF0FBDF，修正后重新读回，不把初稿意见当最终检查。

主稿有8要求、8IF、8中文OP、10INV、24文字TEST、6阻塞项及A–L12节；这些是文档覆盖数，非测试通过数。root对28种消息表示作字段位数加总，全部一致；宽度算术不证明协议、电气、综合或性能。

## 2. 实际发现并修正的问题

| 发现 | 最终修订及实际核对位置 |
|---|---|
| 首SOF重新分配身份与提前ARM/LIVE/scope冲突 | D2/E01先RESERVED锁Origin及配置，真实SOF只采用旧ARM；cfa_phase与DDR phase分名 |
| 无SOF取消等待不存在START，迟到START可能状态倒退 | START_CLOSURE788/794、NO_START_PROVEN/SEEN与真实撤ARM/通知/RX证明；E01/02单调合并，不由计数0推未启动 |
| FE无条件等FS，或INPUT_BAD后held FP永远等ready | D2/E03区分no-session/真实FS/可信reset；独立消费终结后DISCARD未fire项、保留真实fire计数 |
| 子local/status/return与父fence/FREE互等 | D3/E04/05分层leaf_request_closed与DS ACK274；LOCAL231不含fence，PROCESS702/FE1628 return独立，CAM/DP仍status→return |
| grant25预算漏掉旧CLASS/QUEUE/reader SRC授权 | Canny四grant及reader SRC五个旧grant全部RETURN ACK消费后下一沿才授RC九grant，D3/E04 |
| 源COMPLETE/RO可能早于写scope真正结束 | E02纳入CAP phase/grant/scope/mirror关闭ACK；这些关闭不能反向阻CAM return |
| phase子集证书/重复关闭及自身pin造成不当回收或互等 | D3覆盖完整登记集合、CHECKPOINT/CLOSE_GRANTS二择一次；证书和phase自身pin不先为0才给证书/ACK |
| 两FP槽共用交付计数或只“满则停”不保证capture容量 | E03 formed/delivered分离；carry5+word8需预约g2槽，已预约capture继续；bank需本地读pending关闭才重写 |
| 两RETIRING关闭上下文可被覆盖 | D5按两个有限退休对象保留terminal/return上下文与待发资格，独立通道不等无限队列 |
| 退休result等待同源其他BIND/FREEZE导致不必要阻塞 | E07仅等本result端点风险关闭；其他源引用只阻source FREE |
| Canny23个FSM状态误作DDR phase记录 | D3/D5固定保守phase20：6capture+3display+reader1+writer1+Canny4+RC4+diag1 |
| 原174 RAM遗漏reader本地双bank | F新增4到178/256；DS服务段槽、CAM源写bank及RC池没有复用合同，不能抵扣 |

最终两方向复核均确认对应实质修改已落实，限定范围内未发现残留直接矛盾。该结论不覆盖DJ-B01…05的真实外部/算法/服务界，也不表示不存在其他实现错误。

## 3. 设计未知与验收义务分开

已定义的接口反压、迟到、同沿、取消、阶段/容量/引用场景列主稿G，获批后执行，均NOT_RUN。依据v0.2 §6.3/10.3，不要求先生成未获批RTL才能完成设计评审。

仍影响正确性的设计未知：匹配2Gb参数/真实PHY和可见性；真实CSI5.15错误/closure与发端界；cold safe及serializer/相关clock；RC参数实体、数值记录与质量范围；采集尾/行最坏服务及完整资源预算。它们不能改成普通待测或由profile_ref掩盖。正式DB、指定实现/构建授权等另为执行前置，未写入或冒充已批准。

## 4. 当前产物与限制

本轮只新增DATA主稿和本评审，更新既有五个入口/追踪文档；没有新草图附件副本，中文步骤集中在主稿E。前52MD审计原字节保留为[CONTROL-JOIN历史审计](document-checks-control-join-v0.1.json)，当前[文档检查](document-checks.json)须重新绑定54MD及相关哈希。

本轮所有业务实现、可执行测试、真实PHY/校准、综合、pin、PNR/STA、bit/hex均未执行；无网络/下载/安装、数据库或正式状态写入、原资料修改、硬件编程/观察。完整十一项软件目标尚未完成。

后续应关闭当前真实合同和识别数值设计，再呈现可批准的具体版本/范围；不重复已有待答请求，不用再次制作相同文档替代真实进展。用户理解验收待实际作答。

