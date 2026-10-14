# RA-C0 v1：连续赋值的声明次序修正

原设计仍为TRACK4-FRAME-READ-AUTHORITY-001 v1，15项冻结输入不变。authority_small_001实际vlog退出2：RTL第25行先引用running，第38行才声明；Questa因此报告Undefined variable和already declared。原attempt/9源快照/日志保留。

RA06的running仍为原reset_pipe==0，lookup_ready仍为running&&!cmd_valid&&!reply_valid。只把连续赋值移到已有wire running声明之后，不改变接口、采样、优先级、状态、权限、复位或资源选择。按规范§11.1属于声明组织的内部调整，不是新的行为设计。E第3步仍依旧账本查询，D的ready契约保持。

先读回本卡，再移动该句；新attempt重新vlog/vopt/实际sim/audit，原失败不覆盖。源码对应RA06/RA08和RA-T1..7；当前没有活跃工具，下一次执行采用修正后的真实9源SHA。不伪造新的用户批准；沿用持久自主软件范围及本地审计例外。
