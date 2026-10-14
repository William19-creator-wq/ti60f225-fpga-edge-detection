# Agent Role Catalog

默认只使用一个主 Agent。当前不创建持久 Subagent，以免并行写入同一状态或产物。

可在未来经批准启用的只读角色：

- `project_mapper`：读取工程、列出来源和冲突。
- `build_reviewer`：读取编译日志和报告。
- `hardware_observer`：只整理人工提供的硬件现象，不接触设备。
- `artifact_reviewer`：验证哈希、结构和生命周期。
- `recovery_reviewer`：检查检查点、审批和副作用账本。

每个角色必须声明读取范围、写入范围、允许工具、拒绝工具、输出 Schema 和完成条件。
