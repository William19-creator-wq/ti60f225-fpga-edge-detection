# Observability Specification

PostgreSQL 保存结构化运行数据，本地 JSONL 保存追加式事件归档，`reports/` 保存派生视图。

- Log：发生了什么。
- Trace：一次 Session/Turn 的端到端路径。
- Metric：数量、比率、成本和时延。
- Progress：节点当前进度。
- Decision：为什么作出决定。
- Checkpoint：中断后如何恢复。
- Audit：谁在何时改变了什么。
- Alert：什么需要即时关注。

每个 Run 关联 goal、plan、agent、tools、skills、输入/输出产物、前后状态、审批、异常、耗时和验证结果。敏感信息只保存摘要和哈希。
