# PREFETCH v1 J1：终态holding及故障优先级核对

生成后、首次运行前检查发现：reader必须只发布一次Q通知；后续span尾响应/恢复enable不能重新提出或改写已发布原因/计数；同沿安全RESP失败优先于取消。实现对照PF05/06修正这些条件，不改变接口/位宽/范围。

中文草图：首次Q锁outcome/reason及截止read_beats；旧out holding真实消费、native pending关闭后通知有效；notice消费清valid，继续旧span drain/command但不再创建通知或更新终态。安全失败与取消同沿以span outcome1为准。enable在CHECK/CFG_REPLY/DONE阶段不推翻已发布ACK/安全完成；已经开始预取的phase失效才隔离。后续physical drain不补成drained1。

PF05/06→reader终态/错误优先/边界phase→T2/T3 holding/late事件场景。首次实测仍未运行，依自主授权保存读回后修正，J1冻结为本批额外输入；无硬件或原资料动作。
