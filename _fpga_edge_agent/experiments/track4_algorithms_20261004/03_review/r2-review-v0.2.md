# R2 v0.2 / C0终态设计审阅记录

2026-10-04；DESIGN_REVIEW_ONLY / NOT_APPROVED / NOT_RUN。本记录绑定实际文件hash，不把文档检查写成RTL/仿真/综合通过。完整包和R2均仍NOT_READY。

## 1. 范围、阅读入口和真实版本

先读[完整包v0.2](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)B/C/D，再读[R2主稿v0.2](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)、[C0附件v0.1最终稿](../02_design/canny-stream-controller-sketches-v0.1.md)。旧[R2 v0.1](../../../planning/design-TRACK4-ALGORITHM-R2-001-v0.1.md)和[整包v0.1](../../../planning/design-TRACK4-ALGORITHM-BATCH-001-v0.1.md)为实际同hash快照；旧审计按旧版本看，不套到当前文件。

| 文件/范围 | 实际SHA256 | 证据性质 |
|---|---|---|
| R2主稿v0.2 | 71F741C609F3DC5A045C7510AEB846EA9899F8965E7AE98CDDD2101321082B2B | 保存全文读回、预期文本逐字匹配；两路最终全文审阅 |
| C0附件最终稿 | 5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844 | 32502B/259行；两路最终全文复核 |
| 候选来源基线v0.2 | C3D68E50C0A3F6760347B236AF6722A98AFEE175FE669FDCEBDD1CB0199E623D | 30份实际来源hash/bytes匹配；不是整包批准或所有业务文件最终基线 |
| R2历史v0.1 | 6B9C02C04662AAA10EC69CD12391AAFCD2E3D41F1E80809A604069534F167FAA | 原22380B快照；历史审阅入口 |
| 整包历史v0.1 | EB17002246C7D4426BF34C6AF166E1228EBF5E6650E2C0156A045A719D0BA710 | 原13065B快照；不覆写旧版本 |

## 2. 初稿审閱发现及实际修订

C0初稿实际hash为D48D5593E5714F73DA90D55FCD7D54A32BEF331A2199DAA1E2AA706A29466F74。两位独立审阅代理r2_terminal_protocol_review、r2_terminal_numeric_review实际读取规则、原FE与窗口/方向来源后全文阅读该稿；均指出取消因果错误。

| 发现 | 修订后的具体合同 | 文字场景 |
|---|---|---|
| 将当前FS消费沿新cancel解释为先前形成FS1的原因 | FS1只读旧fe_cancel_sent；记录控制沿要求旧FE已启动且旧FS valid0。当前首次cancel+held FS1仍添加unexpected4 | C19：first1、mask1/4；原FS保持 |
| 持续cancel可能每沿被当未合并新错而不能结束 | cancel_seen已置位后持续电平不产生新原因；仍控制FE取消/输入禁用，允许失败CS形成 | C20 |
| 新C0选下一ABORT周期flush，与旧窗口父清理文字未区分 | 本附件覆盖新C0 metadata错误时刻；原FE自身FP错误契约不改。RAM只用0≤q<D的本地游标/phase，不按坏payload坐标寻址 | C21 |
| D4输出metadata错误缺明确stage及同原因DERR排序 | stage5 DIRECTION涵盖D1通知/D4监测；同原因上游顺序Sobel→DERR→Direction | §6 |
| ABORT后接纳held FJ可能让旧外部FP候选绕过C0计数 | 同一C0许可共同门控FE FP valid和父FP ready；外/FE实际fire完全一致 | §3、OP03 |

两路对最终C0 hash5403…全文复核：上述问题关闭，未发现新增协议/数值/排空阻塞。具体审阅范围包括单owner、七状态、FJ held、早FS、独立DERR、八口真实前缀、观测/合法EOF、正常/失败条件、位宽与位置、终态保持及消费空隙。不是机器执行或形式证明。

主稿第一次合并hash12F4C12D9CDDEC019ED27D6031DE4BEC613116BE1BE75113F8271A7FE578CF27，两路亦实际全文检查。协议审阅建议区分“首次原因锁定”与“CS排空后形成”，两路提醒候选来源数需同步。修订两处后主稿最终hash71F7…经两路再次实际全文复核，未发现新冲突；不是只依赖旧稿审阅。

## 3. 结论与保留问题

R2-B01、R2-B02为DESIGN_CLOSED：CS592/DERR120/原FS163/CJ142连续布局、错误码/mask/定位/同沿优先级、单owner与取消/失败结束有可读回细节并独立审閱。592bit终态/185bit梯度不能装入R1的160bit观察记录；B04仍需要新observer，不能沿用旧CRC作为验证。

R2-B03 RGB/最终edge重放对齐、按键/显示合同；B04 observer/实际工程/pin/SDC/资源；B05完整业务文件/基线及语言合同，均仍OPEN。完整闭包/识别/生产视频集成也未因此完成。不得将R2-B01/B02关闭解释为R2或整包READY。

## 4. 实际文档检查与未执行边界

本轮保存后进行了全文读回与预期文本比较、CJ142/DERR120/CS592的连续字段算术检查、21个CASE/8个TEST/8个中文OP计数、Markdown链接/表格/围栏检查，以及候选30来源hash/bytes核对。第一次链接检查准确发现本审閱文件尚未写入；保存本记录后须重新检查，并把最终结果存入[文档检查v0.2](document-checks-r2-v0.2.json)。只有对应版本的最终检查可以使用。

此处TEST是未来验证计划，NOT_RUN。业务源码、参考模型、TB、功能脚本、project/peri/SDC未生成；工作树仍不存在。功能仿真、综合、PNR、STA、bit未执行。数据库未配置；本记录仅设计检查文档，不运行正式Agent数据库流程、不采用SQLite、不伪造Manifest/H0/硬件状态。无新安装/网络/硬件操作，原HDK只读。

阅读顺序按整包→R2整体→C0接口/状态→局部真实交接→完成/失败→中文OP/并发CASE→语言/验证/追踪。继续B03/B04/B05和R3/R4/R5设计，完整包成熟后统一呈现具体版本/范围/基线；当前不提出未成熟方案的实施审批。

