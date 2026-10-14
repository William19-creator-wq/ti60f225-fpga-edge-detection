# B03控制—完整结果重放交接审阅 v0.1

2026-10-04；DESIGN_REVIEW_ONLY / NOT_READY / NOT_APPROVED / NOT_RUN。本文记录实际独立审阅、局部修订和仍需父设计提供的交接，不是新增业务实现授权，不关闭B03/B05或完整软件包。

## 1. 阅读次序与实际输入

[整包v0.3](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)B/C/D → [R2主稿v0.3](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)B03 → [控制v0.2](../../../planning/design-TRACK4-ALGORITHM-CONTROL-001.md)B/C/D/E → [重放v0.2](../../../planning/design-TRACK4-ALGORITHM-REPLAY-001.md)B/C/D/E → 本交接检查 → 各稿F/G/H。整体先说明使用者看见什么，局部再说明owner、消息和逐沿行为；软件执行与Efinity结果随后单独证明。

| 实际文件 | SHA256 / bytes | 本次证据 |
|---|---|---|
| CONTROL v0.1原稿快照 | 04DA76F3C5309B2E78F7F1A349A28D60AC731D4BFB0DEDD28C6649BC043F384F / 49164 | 两路实际全文独立审阅；[原稿](../../../planning/design-TRACK4-ALGORITHM-CONTROL-001-v0.1.md)按修改前字节直接复制，同hash |
| REPLAY v0.1原稿快照 | 8359B4BF9336C286B43A225AFDDB334B9768FD44CDDADCDEB259261387CA3E70 / 43103 | 两路实际全文独立审阅；[原稿](../../../planning/design-TRACK4-ALGORITHM-REPLAY-001-v0.1.md)同hash快照 |
| CONTROL v0.2当前 | 2C2CB80224DF2E5DD4E61CD38E21430E0A60CCA162161481E8A59A0982383107 / 51859 | 根实际全文读回与预期完全相等，读前后hash不变；两路最终修订实际全文复核，旧局部意见关闭 |
| REPLAY v0.2当前 | 7187B09DDE3B652C169E632C87E0DBF7FB14FCE51F9AB428CF789394AB24D68B / 46304 | 根实际全文读回与预期完全相等，读前后hash不变；两路最终修订实际全文复核，旧局部意见关闭 |
| R2 v0.3 | 416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2 / 29268 | 既有两路最终全文审阅，C0/OBS设计合并；B03/B05仍OPEN |
| BATCH v0.3 | 3703F34574E18CC23AD61BA8823848A3981F42353B69A81ECA418AF524BF35A7 / 13615 | 既有两路最终全文审阅，整包仍NOT_READY |
| R2-FILES v0.1 | E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842 / 24178 | 数值代理实际全文最终复核，oracle独立rows和直接NMS窗口入口两意见关闭；全文件/套件/timeout/跨批仍OPEN |

原39来源清单的实际路径/hash/bytes全部吻合；它是R2历史候选输入，不含新两稿或本文，不冒称已冻结完整实施基线。新稿自己的来源hash不自包含；当前文档检查另记录真实hash。

## 2. 实际发现与修订

协议代理r2_terminal_protocol_review和数值代理r2_terminal_numeric_review均实际全文读取两份v0.1，读取前后hash一致；审阅没有执行RTL或数学实现。

| 审阅项 | v0.1具体缺口 | v0.2文字修订 / 关联验证 |
|---|---|---|
| HB-F01 / REPLAY D4/E2.3 | 正确RR清credit后，RRslot仍满且JOIN暂停，只有“不覆盖credit”不足以防同seq重复创建RQ | 建立held即置issued_current_seq；新建要求required、issued0、旧held空/credit0/RRslot空。真实JOIN清已消费slot、推进游标/下一组标记；下一旧RUN沿才建新RQ。BR-T06覆盖RR到达但显示暂停 |
| HB-F02 / REPLAY E1/E2.1 | last_admitted保存但更新事件/拒旧是否下调未明确；PLAN epoch变化可能被误读为重建授权 | 仅完整合法VALIDATE准入原子推进两高水位；非法不改，OPEN拒绝仍消耗已准入ID。首次合法准入锁父授权session的bound_epoch；异epoch拒绝、不清借用/高水位。跨优雅reset授权消息保持BR-B02。BR-T15 |
| HB-F03 / REPLAY D2/E2/E4/E5 | 成功RR/CLOSE_ACK/RELEASE_ACK没有统一suffix reason0门槛，status0/released1但reason13可能被最小文字实现接纳 | 明确成功status0/reason0，释放还需released1；合法失败reason非0，非法或非规范不成为证书，不清borrow。ACK所echo的CLOSE.reason与suffix分开。BR-T11 |
| HB-F04 / CONTROL E2/E4/E5 | config默认0与first commit、当前值/next值、reset_seq在软件epoch切换的保留范围未逐项冻结 | E5分配表：config/drev/algorithm首增1，proposal/frame/event首号0；reset next/exhausted跨软件epoch保留，UI/SET及其他本epoch状态仅真关闭后重建。最大一次使用、无回绕，last-cache合法重复保留。AC-T11/12 |
| HB-N01 / settled成功数量 | 不是新的设计缺陷：原合同已有request=E、cutoff=request、actual_request=cutoff、settled=actual_request | D5显式写source_settled=E[p]、未启用口0，便于RT/T01直接核；不把raw/good/settled混成同一计数 |

根对24项CONTROL/REPLAY消息字段求和独立核对，全部等于正文名义位宽。RT1171=616+64+2+5+32+69+26+252+21+21+63；CLOSE338/ACK437及source_settled63没有漏项；这只是文档算术。hex位宽与高padding记录于[当前检查](document-checks-r2-v0.3.json)，尚未成为完整向量schema或执行结果。

最终修订稿独立审阅已收到：协议代理和数值代理均实际全文读取CONTROL 2C2C…3107及REPLAY 7187…D68B，读取前后hash不变；确认HB-F01…04本地意见关闭，没有发现本次修订新增的局部协议/数值/字段矛盾。协议代理还实际核两份v0.1快照hash一致。这是绑定当前修订hash的设计审阅，不是实现批准、仿真或形式证明；四项本地修订不能代替下面六类父交接。

## 3. 必需交接及唯一owner

| 连接 / 责任 | 两稿当前相容的部分 | 尚须联合冻结的具体动作与证据 |
|---|---|---|
| HB-IF01 CFG→J | CONTROL唯一CFG owner；完整旧C形成J657，同沿commit/job用旧C；C0内部FE唯一owner保持 | R3完整不可变profile实体、R4收集器准备/子级terminal。非零profile_ref不是实体证明；stream CS0不是完整Canny |
| HB-IF02 J/V→completed bundle O | J/V保存原job/source/CFG及完整平面要求；REPLAY只借已COMPLETE且同job/source/render的bundle | R4必须定义真实COMPLETE谓词、bundle registry、完整SRC/最终EDGE/ANN provider及保存/返还。VIEW对象引用与P borrow是不同持有层，分别归还；不是V valid清0就可回收 |
| HB-IF03 V→PLAN616 | 原render112、mode/lane/灰度/颜色/优先一致；生产1920×1080保持 | 指定唯一适配owner和source_image_id/result_id/render_generation/display_id/plan_id各唯一分配者；命名字段逐项构造job96/render/profile/W/H。source_handle不是source_image_id，edge/ANN handle不是result_id，config/proposal不是render_generation；禁止位向量强制转换/低位截取 |
| HB-IF04 三plane重放 | 每口独立RQ/credit/RR、只读完整图、mode0 SRC/EDGE各P/2；无liveRGB tap等待edge | R4实际provider须保证坐标读取、服务错误后已held RQ最终兑现、独立CLOSE能取得accepted/raw/settled/last_seq/四关闭位。client的证明消费独立于其good/credit/JOIN/OUT |
| HB-IF05 CANCEL128→224及RT返还 | J取消与plan取消各有真实匹配身份；取消ACK仅表示接纳；published消息不撤，真实前缀保留 | 适配owner保存V所对应的完整PLAN，不能用最新C或新ID取消旧plan。RT/RELEASE_ACK之后还须VIEW父引用真实归还；RT status3/drained0或未知OPEN义务不能当全部对象结束，即使RT borrow字段0 |
| HB-IF06 软件reset/epoch与生产边界 | CONTROL先quiesce→真terminal/返还→epoch；REPLAY Q保留义务，方向相容 | 新epoch授权及所有owner/provider接纳事件须联合冻结；旧terminal消费/GAP/所有borrow及未知OPEN结清后才允许P高水位重建。Q使父FAULT_WAIT，不能广播reset_commit伪造关闭。R5另证明多域/固定视频/物理reset，当前单core硬rst不是外部事务排空证据 |

在当前两稿中，CTRL reset_seq由KEY_OWNER唯一分配且在软件epoch切换保留；P高水位属于已授权epoch的plan/display序列。两者不能互作替代。job96的三个命名字段与各消息packed布局须在适配schema明列，不能仅因都96bit而直接连线。

## 4. 中文端到端走查与人工观察点

正常：按键→完整D接受→旧D形成P→旧P提交C→真实job锁旧C→选定stream与必要final子级真实成功→R4提交完整bundle→VIEW采用历史V→适配层形成新PLAN→O授予borrow→三个需要的plane按同source坐标请求→RR各进入预留slot→issued仍1，即使OUT暂停也不重复请求→JOIN推进→四级渲染→OUT真实交付P组→各source真实CLOSE证书→borrow实际返还→RT成功→VIEW父引用按约定归还。末两层归还交接仍HB-IF02/05，不能用此走查文字称它已存在。

出错：坏SRC echo真实fire→raw加1/credit保留→下一ABORT禁止新JOIN/RQ→旧held RQ/P4继续履约→不等credit即可向source发正确CLOSE→正确settled/closed证书以失败结credit→本地引用空后返还borrow→FAILED_DRAINED。若suffix reason、ledger或真实关闭不成立，则Q保留borrow/未知OPEN义务；父软件reset仍FAULT_WAIT。完成一个错误RT不等于已经安全释放。

同沿：P提交与job接纳用旧C；错误与OUT交付均计旧真实fire；算法屏障不反悔当沿已移交的V。模式0只改变显示访问，不把处理算法降成540行；SRC最后上半pair没有display EOF，EDGE首个下半pair没有display SOF。人工阅读先看这些事件，再看内部状态名，不能只看最终LED/CRC。

未来验证须包含HB-F01…04和六类交接的普通、边界、取消、错误、隔离与软件epoch恢复；当前只有两稿G/H的文字场景。独立数学图、真实接口账本、网表资源/STA与bit各自提供直接证据。

## 5. 状态与下一步

CONTROL/REPLAY均LOCAL_DESIGN/NOT_READY/NOT_APPROVED/NOT_RUN。R2主稿与BATCH未被本文升级；B03/B05仍OPEN。继续R3独立数值核、R4实际逻辑对象/完整算法与交接，再补B05共同文件/schema/套件/timeout，最后R5资源性能/摄像与固定视频及生产约束。

完整RGB/CLASS/GRAD/QUEUE等逻辑容量不能被本局部“0整帧RAM”隐去；主机数组不等于Ti60片上资源。完整1080p、圆/任意旋转矩形及质量目标不缩小，不恢复撤回的识别硬边界，不以资源填满作为优化目标，不调查停止关注的外部存储器件。

本轮未创建业务工作目录、业务源码/参考/TB/功能脚本/project/peri/SDC，未仿真/综合/PNR/STA/bit；原HDK、正式Manifest/状态/数据库不修改，无新安装/网络/硬件操作。整包成熟后再集中提交具体版本集合/范围/基线供明确批准，当前不请求未成熟实现批准。
