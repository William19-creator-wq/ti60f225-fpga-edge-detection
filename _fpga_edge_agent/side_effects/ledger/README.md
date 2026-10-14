# Side-effect Ledger

结构化账本位于 PostgreSQL `side_effect_ledger`，本地事件归档保存状态变化。账本状态至少包括 `PLANNED`、`EXECUTING`、`COMMITTED`、`FAILED`、`COMPENSATED`。
