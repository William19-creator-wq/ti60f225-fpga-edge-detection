# 识别访问结构有限审阅（v0.1，2026-10-05）

状态：LOCAL_DOCUMENT_REVIEW / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。入口为[RA访问设计卡](../../../planning/design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md)→[PK几何卡](../../../planning/design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md)→[打包字典](../01_baseline/recognition-packed-record-map-v0.1.json)。只证明文档选择和静态算式，未实施接口或软件测试。

## 1. 有限选择及改变的下一步

选择按对象首次合法阶段的全round64/16B顺序INIT，保留算法复用CLEAR；RJ admission、REGISTER和ACTIVE本身不授任意清零。E=0 COMMIT不新造数据访问，但本方案构造前POINT预清实际费用照计。阶段SEAL和永久immutable分开，旧引用全静止及真实新资格才允许复用。
选择单pack sequencer、一个真正leased journal槽逐lane复用、持续全DENSE组门；580assembly的512postimage字段用于收集/patch，阶段/引用不重叠才复用，不追加四个银行或免费借BK assembly。下一lane只有前lane真写可见和END/引用空后才读新后端，单B不足；无免费forwardcache。
共同来源存在重要差异：原RAW全16prepare及DIR OP05 L153全postimage/一次logical_commit流程，需只对RC DENSE联合吸收新lane-retire分支；其他actor原合同保持。当前仍RA-B02，旧源码与文档没有改，不能因为“串行允许”而跳过这个组合审查。
发现R4R272未明确每新DENSE batch清零；RA E7提出32批各清全部4432计数及尾零。NMS四行跨batch/theta511-0的copy/valid/version及旧引用关闭还须RA-B05修订，未把增加CLEAR当完整NMS验证。

## 2. 静态实占与服务对账

RC自有RQ799/RSP872/assembly580=2251bit，17项具名控制合101，共2352bit部分热状态。完整tuple/transport/permits/FPI/DR/seq/exhaust/cutoff、失败冻结/close及全部控制未落账，不能当全部FF/XLR。DIR候选journal16×29=464word/9280bit/1RAM及176bit效果账保留；RC拟租29word，租约尚未提供，不扣RAM。
生产journal576为address32/length7/postimage512/state2/cause6/zero17，尾4pad成580；word27更新保postimage高11及其余位。旧RAW26bit字段不可直接沿用生产地址。init_cursor29加16先30bit核范围；incoming written7先核0…16再存5。
普通WRITE或一个DENSE lane按29WE+29RE+1stateWE为59native issues；16lane944（480WE/464RE），READ/INIT/admin不套59。普通WRITE最大4R+4W/128B；DENSE最大32distinct16B跨度，RMW为32R+32W/1024B。这些是数量，不是cycle/墙钟/fps。
物理DENSE item=277×local_lane+rho（lane0…15），global theta=16batch+lane只做算法系数/NMS身份；原KEY index仍batch与point_ordinal。合法接口rho数组使全部16lane的count offset127、各跨2单元，达到结构32上界；不声称该向量来自真实同一个POINT。
21private初次round64 415104B/25944unit，加POINT1036800/ANN32400/当前RECORD256，合1095400个16B写。DENSE每batch728unit，32批23296unit/372736B；若容量比较已含第一清，则31额外22568unit/361088B。HIST/COVER等复用清另计；不包括只读输入、另两历史RECORD、guard或未授spare。

## 3. 实际读回与意见处理

Root完整初卡1…115，SHA36D3C278DC64ED756C83D9960939D1889698AA56ADBD4840EE108841E20EB21D；后实际定向核27/29/47/50/53/61/68/72/75/76/85/111。最终114行/20710B/SHA33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA，末尾空行减少不添加语义变更。
三位独立读者production_directory_numeric、load_grad_point_pin_review、quality_recipe_static_counts均实际初卡全文1…115；最终语义/协议读者定向上述12行及状态段，数值读者定向53/61/68/75/76/85。最终各报告hash33388…02BA，未发现指定差异的新确定缺陷；不冒称最终全文重读。
已处理意见：namespace明确4bit/值5；本地lane寻址与globaltheta分开；E=0不倒扣已选INIT；59仅WRITE/RMW；DIR153仅RC内部差异；sealed版本复用需新资格。Root另补cursor扩位、written范围再窄化、租约仅拟议措辞。2352/native/init数量保持。

## 4. 限制、守护及下一步

RA-B01逐phase/op及INIT/prefix/admin；RA-B02真实槽租约、lane-retire、原因翻译及DIR共同来源差异；RA-B03真实DDR可见性/no-future；RA-B04完整实例/控制及时间；RA-B05批次清零及NMS快照。全部OPEN；本卡不可READY且不申请本版实现审批。
R1 22、R2 48、Q0 44项重新逐bytes/hash核对全一致，原10正式/交付/bit/hex守护一致；正确PG配置键只查存在性仍false。无Q0/R2 work或确认live EDA handle、无新指定批准，不能把聊天待答记verified wait。上一目标回合为ACTUAL_PROGRESS（PK字典），本回合为ACTUAL_PROGRESS（明确局部结构、费用及真实共同合同/算法复用缺口），不只是重述状态。
本轮没有新增业务RTL/C++/参考/功能脚本/TB/可执行测试、EDA、bit、硬件、网络或安装；Manifest、正式state/ledger/数据库及原资料未变。后续先把上述finite bridge/权限/快照完整化，再READY/指定批准/实现验证；已有R2/Q0问题不重复。完整五基础/六高阶软件目标尚未实现并验证完毕。

