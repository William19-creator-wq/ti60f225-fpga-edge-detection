# Context Policy

区分 Instruction、Working Context、Session Memory、Durable Project State、Artifact、Log/Trace 和检索索引。聊天上下文不是正式事实源；正式状态来自 `state/` 和 PostgreSQL。

每次压缩上下文前必须保存 Goal、Plan、State、审批、异常、Side-effect Ledger 和 Artifact 引用。
