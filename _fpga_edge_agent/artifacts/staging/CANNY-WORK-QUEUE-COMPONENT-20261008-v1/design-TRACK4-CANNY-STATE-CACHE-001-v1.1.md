# TRACK4-CANNY-STATE-CACHE-001 v1.1：取消交接修订卡

2026-10-08；整体v1、模块职责/布局/line RPC继续有效。v1源及suite_002/map_002快照保留；当前按用户持续授权自行实施新版本，不重复索取批准。

问题/证据：queue故障或任务取消时，cache可能在CLAIM等待queue容量；v1无私有取消输入，核心等待state_rsp，导致无法结清。这是当前正确性问题，不能等整机碰运气。

整体SC05增加：abort_private_valid/abort_job_id64是父端已经匹配当前job的共同取消事件，同时送cache和queue；错ID忽略。事件作废尚未承诺的内部claim，不撤已提出line RPC，也不改held rsp。正常任务算法/缓存布局和数值不变。

局部旧状态草图：锁abort_sticky；新业务只错误，FLUSH关闭作废job。在非公开RPC/回复的计算状态停止扩展并rsp_error；WORD/WB已RE仍下一沿capture；MEM_REQUEST继续held到接受，MEM_WAIT等drained，错误优先，未知仍QUARANTINE。FILL安装遇取消禁止WE和valid发布。

CLAIM特殊沿：若旧claim_valid&&claim_ready，cache/queue WE仍同时提交，正常claimed1回复（核心的cancel已另锁，整job不发布）；若ready0而共同abort，则该沿无WE，两端私有槽共同作废，cache下一沿返回error1。这项事件是明确的内部取消例外，普通stall仍保持valid/body，不允许仅一端撤回。

公共line valid和held rsp不随abort修改；回复若已经valid仍保持。共同rst不代替物理drain。FLUSH遇已知abort/fault可直接丢未提出dirty并返回error，已提出RPC已在之前终结，不发新的失败job写回。cfg仍在关闭/回复消费以后才能接。

测试SC-T09：错ID；CLAIM ready0取消；CLAIM与ready同沿取消成对提交；请求提出未接时取消保持；待line响应取消等待；FILL安装中取消不发布；held rsp取消不改；之后关闭/新ID恢复。逐项记录真实握手与队列claim数量。SC-T01…05重跑，同unit源变化故重新MAP核8RAM；SC-T06…08待组合/物理DDR。

追踪：SC05→abort_sticky/CLAIM/MEM_WAIT/私有pending→RTL新增两个输入与控制分支→SC-T09；原SC01…04→原测试保持。无当前单元阻塞；保存读回后按持续授权进入IMPLEMENTING。输入SHA及v1对比记录在工作目录baseline-v1.1.json，正式DB/状态不改。
取消回复字段补齐：rsp_aborted1与rsp_error一起保持，区分已排空的私有作废与真实存储错误；真实line_error优先且aborted0，drained0仍无正常回复。直接接核心时，join adapter只在已经登记同job取消时把aborted回复映射为非数值的取消收尾（对原HY输入以old0/claimed0/error0结束，HY的cancel_sticky保证结果CANCEL，这些占位不作读值发布）；未登记取消遇aborted按服务协议错失败。已经claim同沿commit则仍正常claimed回复，由核心自身取消；不能把真实line_error改成取消。后续adapter必须实测该对应关系。