# Event Delivery Policy

本地事件至少一次追加写入；Event ID 和 payload hash 用于去重。事件乱序时按 occurred_at 和 event_id 审计，不能覆盖旧事件。外部 Webhook 当前不启用。
