# TRACK4-FRAME-PUBLISH-001 v1 / C1：声明顺序修正

来源：`frame_publish/runs/publish_compile_001/vlog.stdout.log` 两项错误，同一个 `matching_cancel` 在首次表达式使用之后才声明，Questa先报告未定义，再报告重复声明。原失败run、source snapshot及日志保留。

范围：仅把该wire声明/初始化移到 `sequence_ready` 连续赋值之前。不改变信号名、表达式、采样时刻、状态、接口、数值、错误语义或任何FP01..08边界；依赖16份原冻结输入保持不变。关联MOD1/IF01/IF04/TEST T06。

中文草图：先声明组合匹配事实（cancel有效、token相等、当前处于工作态），后面的sequence接受条件借用同一事实；状态更新仍在core上升沿。此修正没有新增组合路径或寄存器。

READY_FOR_REVIEW；沿用用户“当你統計完后自行进行, 无需我的批准”的持续软件授权及本地审计例外，保存、读回、呈现后进行。新run `publish_compile_002` 检查实际vlib/vlog出口及current/snapshot SHA；编译通过不代表动态验证、综合、整机或硬件通过。其他文件不改，正式数据库/H0/Manifest不改。
