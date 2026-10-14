# Orchestration Specification

主 Agent 负责计划、状态、审批和汇总。只读角色只有在工作可独立、输出可验证且不会并行写同一正式对象时才可启用。

默认编排：

```text
Main Agent → read-only inspection → deterministic validator → human gate → Main Agent
```

多角色失败、冲突或输出 Schema 不一致时，主 Agent 停止并记录异常。
