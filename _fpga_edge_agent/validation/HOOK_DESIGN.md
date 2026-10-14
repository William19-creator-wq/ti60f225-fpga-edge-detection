# Hook Design

Host 支持的 Hook 事件必须先核验，不能假设所有平台一致。

当前只定义逻辑 Hook，不自动安装 Host Hook：

- `SessionStart`：轻量检查目录和状态。
- `PreToolUse`：检查审批、路径和副作用。
- `PostToolUse`：记录结果、哈希和验证。
- `PreCompact`：保存状态、审批、异常和检查点。
- `Stop`：运行最终结构和安全检查。
- `SessionEnd`：生成交接报告，但不承担唯一持久化责任。

Hook 失败时进入异常处理，不循环重试，不降低验证标准。
