# Idempotency Policy

本项目 Agent 禁止设备写入；人工下载不由 Side-effect Ledger 自动执行。未来任何数据库迁移、外部发布或设备动作都必须使用稳定幂等键、提交状态和补偿/回滚记录。
