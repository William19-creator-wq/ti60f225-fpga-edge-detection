# Side-effect Policy

外部副作用必须先拥有 operation_id、idempotency_key、approval_id 和参数哈希，再写入 Side-effect Ledger。进程恢复时先查询账本，不重放未知是否已提交的动作。
