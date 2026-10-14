# Canny父任务/方向/writer设计复审 v0.4

2026-10-04；TRACK4-CANNY-001。范围：[主稿v0.4](../../../planning/design-TRACK4-CANNY-001.md)、[父任务/writer附件](../04_local-designs/canny-parent-writer-sketches-v0.4.md)、[地址算术候选](../01_baseline/canny-candidate-address-arithmetic-v0.4.json)。状态LOCAL_DESIGN/NOT_APPROVED；只读设计审查，全部CN-T01…26为未运行文字场景。

## 1. 三方向审阅及实际修正

| 方向 | 初审/读回发现 | 当前设计修正 |
|---|---|---|
| 父任务/状态/取消 | 非法job可能已有父reader绑定；进入EXPORT即读会越过EDGE start；C8返回槽未预留；Q不能消费后回IDLE；平台abort不能自动报复位故障 | reject_pending→ABORT_DRAIN并核验可信未绑定/未启动返还，禁用未核验句柄；独立EDGE start与旧edge_started；partial/pair与pending容量、同沿替换；Q留phase21、冻结快照；CANCELLED+abort_cause |
| writer/共享口/封口 | “成功”含fence会与C0互等；GRAD可先结束；EOF整满可能新建空bank；两W槽可能为其他owner预塞；通用carry措辞误套GRAD | 每writer独立LOCAL_OK及C0证据槽先于stage fence；GRAD在STREAM也收终态；EOF满bank不另开空bank/零长请求；两槽只组当前owner段；CE必要carry后seal，GRAD按有效pair直接seal |
| 数值/连接/复位 | D1非法signed值需在窄化前检查；保留寄存值却rst屏蔽MC valid仍违背保持；counts_final和晚feed错可能落在旧OK之后；Q live计数不能改status | signed12 abs/unsigned12 abs和核验后存10bit；MC保持域继续req/W valid/payload/pending capture与实际账本；DONE_CHECK要求真实FE/feed成功及关闭；Q快照和live排空分开 |

实际附件读回后再补：counts_final按实际已启动/已绑定required终结证据及已观测计数收敛定义；未收FS/未打开feed保持无效，不造成功数量，实际FE reset关闭证据不能冒充FS。GENERAL导出遇10实际SC握手后报EXPORT_STATE且不生成EDGE bit；新增held req/W、RAM grant→capture及completion/fence同rst文字场景。

## 2. 预算与地址算术边界

917bit job、23个phase5编码、四方向20bit中间范围及局部沿号为设计推导。窗口/cache/queue旧小计40 RAM10；writer新增共享CLASS/EDGE1块、GRAD3块后累计44/256=17.1875%。两个共享W槽128×2及ctx/银行元数据、MOD-05物理缓冲、平台/显示/识别另计，未综合或放置。

12区半开页分配从0x1000连续至0x034AC000，全4KiB对齐、无数学重叠。1080p紧凑/最小物理55,209,600B；页分配55,226,368B；页额外16,768B。加低地址保留4096B后末址55,230,464B；假定容量268,435,456B，未分配213,204,992B。最小物理A与allocation间隙分开；低4KiB保留不证明PHY校准访问范围。六源期限、真实byte/row/bank映射与grant仍待证。

跨4KiB场景独立授权测试地址：CLASS512B/0xFC0→4+28拍；GRAD1024B/0xFF0→1+63；EDGE512B/0xFF0→1+31；N30 CLASS64B/0xFC0→4恰边界、GRAD128B/0xFF0→1+7、EDGE16B/0xFF0→1恰边界。它们是预期，不是已跑器件结果。

## 3. 当前门槛与文件核验

前轮25份文档检查保存在[历史v0.3](document-checks-canny-v0.3.json)，当前[检查记录](document-checks.json)重新绑定本轮文档。检查涵盖读回、相对链接、代码围栏、A–L/需求/接口/操作/不变量/26测试编号、地址JSON算术和输入hash；不能据这些格式/算术检查认证真实接口相容或功能通过。

FRONTEND v1/28输入、FM v0.1、窗口v0.2、存储v0.3及原资料不变。用户指定VF/Demo展开目录重查确认24个VF默认4Gb/x16模型和24个4096Mb头，仍无独立2048Mb头；先前含三份压缩包的27模型记录沿用其明确范围。无解压写入、联网或下载。

真实MOD-04/05/09/10/11 grant/feed租约/fence/保持域及恢复协议、匹配2Gb PHY仿真、全机资源/时序/性能与识别工作范围尚未闭合；本批不标READY。未获得本稿实施批准，没有生成业务源码、功能脚本、可执行测试或testbench，没有运行编译、仿真、综合、PNR/STA或bit/hex。既有FRONTEND实现及官方模型获取两项申请继续待答，未重复提问。
