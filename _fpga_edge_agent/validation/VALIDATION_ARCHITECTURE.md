# Validation Architecture

Validator 是确定性、只读、可重复的检查；不会修改业务数据或降低验收标准。

当前层级：

1. Required structure：目录、必需文件和链接。
2. Schema：JSON、CSV、迁移清单和事件字段。
3. State transition：只允许 `docs/STATE_MACHINE.md` 中的转换。
4. Artifact：路径、大小、SHA256、来源、节点和生命周期。
5. Permission：路径、工具、网络和人工闸门。
6. Full validation：汇总检查并输出机器码和人工摘要。

实现入口：`runtime/validate_control_plane.py`。未来增加的验证器应放在 `validation/validators/` 并提供故障 Fixture。
