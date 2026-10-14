# TRACK4-IP-PRECHECK-001 v1.1：C0遗漏原头文件的输入修订短卡

2026-10-04；按PLAN_TEMPLATE的小修复短卡。**READY_FOR_REVIEW / NOT_APPROVED**。此卡仅修订C0/C1输入闭包，完整外部行为、C0–C3矩阵、限制和中文步骤继续采用[批准设计v1](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approved-design-v1.md)，不新增算法或仿真激励。v1已获得的本地审计例外及其条件保持；原89份清单保留，不覆盖。

## A / 通用计划字段：实际证据、边界与状态

Goal/Target：把参考v1源码实际包含的两份原文件补入冻结清单后，重新从可恢复输入执行C0；只有C0按原矩阵成功才继续C1。Current/Gap：获批89份副本map于2026-10-04 17:33真实退出1，日志指出无法打开`timescale.v`及`i2c_master_defines.v`，尚未到成功资源报告；错误不是DDR保护IP不可综合证据。Dependency/Baseline：IP-PRECHECK-BL-v1.1为原89份逐字节相同＋下表2份，共91；XML设计引用仍66项。Assumptions/Open：不借头文件恢复改变I2C行为，原工具保护key、debug产物及clock结果仍按v1失败保留。Milestones/Steps：实际失败与源定位→此卡/91清单读回→指定v1.1批准→work中加入两原文件/冻结delta→重新map及原规定阶段→报告终态。State：仅软件预检，不改H0/正式DB/硬件状态。Artifacts：新候选JSON及本卡，执行日志沿原报告目录。Failure：任何再失败保留全部日志，未知不伪补。Approval：等待v1.1及91输入批准，不擅自把清单变更说成已批准。Rollback：保留原89输入和首次失败，不覆盖原HDK。Completion：限定预检终态；不表示整机、比特流或硬件完成。

| 新增原文件（相对原v1工程） | 长度B | SHA256 |
|---|---:|---|
| rtl/cam_i2c_ctrl/i2c_master/timescale.v | 813 | D98DD66323E809EE4BC88896063327802CA13241B5742A5E25DB17DB17A40A4C |
| rtl/cam_i2c_ctrl/i2c_master/i2c_master_defines.v | 4071 | B6DCF92C66C3DC80192206621E732F0474709579662EE09943E48DB0077F302E |

候选清单：[91输入IP-PRECHECK-BL-v1.1](../experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.1.json)。原批准89清单hash `1B336732334C4453FEA720351FF45910B0D9367B1089C4A89713815CCE790DC3`；原批准设计hash `130481D499D68F4F2F43C6C6731D0E088E4333D4B701C22E1E37C2CCD65BD2E8`。

## B–D：被修正要求、接口与组合检查

IP-REQ01/IP-IF01要求独立副本具有真实输入闭包。原清单把`.v`头文件漏在外，公开源`i2c_master_bit_ctrl.v:141/144`、`byte_ctrl.v:83/86`、`top.v:87/90`各以活动include引用两文件；原HDK里两文件均实际存在。C0 map日志`C0/outflow/ti60f225_oob.err.log`及`C0-map-console.log`保留原错误与退出码；原源码未改。

MOD-INPUT增加两项源hash/copy；MOD-CASE/TOOLS/REPORT职责及全部业务连接保持v1。只恢复被引用原字节，不新增定义、改宏值、改变语言标准、调时钟、关闭debug、删除IP、换旁置设置或改变C0–C3依赖。C2原样输入已经含这两文件，其实际引用仍60项；不借本修订改变C2的CSI频率未知。C0首次失败不能用后续成功覆盖；分别标attempt1/attempt2及输入hash。新源变化只在C0/C1，与C2/C3来源不混用。

## E–F：中文操作草图与语言契约

批准后先确认91份源长度/hash→检查C0现有89输入与首次日志完好→把两份原字节文件复制到各自同名相对位置→再核91长度/hash，记录delta→使用已有`--flow map`显式命令；后续按v1保留debug、只选interface/PNR/STA明确阶段，不调用compile/full/pgm→任一失败停止该case，保留所有日志、源hash和真实handle→C1只从成功C0派生。若独立debug阶段尚需未授权改变，记录停止，不关debug凑结果。

这两份属于预处理输入，复制后宏、timescale、数值位宽及所有RTL采样/流控/复位/配置/存储/CDC与v1原HDK语义相同；不产生新C++/RTL实现体或测试/TB。Questa范围仍仅实际DUT和厂商原语编译/展开，无激励或器件校准。未实际编译前只说修复输入闭包，不称行为等价已验证。

## G–H：验证计划与双向追踪

| TEST / REQ | 验证与期望 | 当前证据/状态 |
|---|---|---|
| IP-T01 / REQ01 / INPUT–IF01 | 原89完全相同，新增两份只取原HDK字节；91均hash匹配，无新原源写入 | 只读源hash完成；work补入NOT_RUN |
| IP-T02 / REQ02 / CASE–TOOLS | C0从91输入重新map，退出码和完整层级据实，不预判成功/省RAM | C0首次89输入FAIL；91重试NOT_RUN |
| IP-T05/T06 / REQ05/06 / REPORT | 首次失败及每阶段日志均保留，debug/key/clock问题不绕过；真实终态后才重试 | 原首次退出1及日志已保留；后续NOT_RUN |

实际修改入口只MOD-INPUT原两文件copy、C0/C1输入清单；每个新增输入反向来自三个公开I2C模块include。工具命令仍绑定原v1设计，资源/STA等报告不能用旧编译物补缺。

## I–J：评审与恢复

①外部行为保持v1；②职责边界B–D；③实际include/原字节连接；④E有确定操作/失败；⑤F不改变RTL契约；⑥遗漏反例及91闭包检查；⑦G/H证据与计划；⑧两原文件已找到，无此卡输入未知，后续工具未知是原实验结果；⑨保存实际读回后呈现；⑩v1.1/IP-PRECHECK-BL-v1.1/91、原矩阵及范围明确。仅此输入修订达到READY_FOR_REVIEW，整机仍NOT_READY。

重新批准依据：原用户明确批准89输入的指定基线；本卡将批准输入集合变为91。项目唯一规范§11.2要求“更改……批准范围，必须暂停受影响的代码生成”，随后“更新整体与局部文档和追踪后，再取得对新版本的批准”。在本卡批准前不补入这两份work源码，不把原批准扩成任意新基线。有效原v1批准的独立C2工作继续，无需重复确认。

## K–L：实录与阅读顺序

实际完成：保留v1批准快照/89复核/副本/首次C0失败；只读定位两真实头文件并新建91候选清单。尚未：91输入的work修改和重试。阅读顺序A失败/新输入→B–D闭包影响→E操作→G验证→I限定批准。中文操作解释与工具实际结果分别保留；理解验收待用户反馈。本卡不申请算法实现、bit/hex、下载/安装/联网或硬件操作。
