# R3整数算术 v1 实施批准实录

2026-10-06，来源为本聊天的用户直接回复：**批准**。前一问及紧接的解释明确DDR Q0与R3整数算术两项范围，并说明两项可以一起批准；此回复批准两项及对应本批本地审计例外。

批准对象：TRACK4-ALGORITHM-R3-SCALAR-001 v1，设计SHA256 `9DD32B5A5D6106F026C4B099EB6824DAE49DF55766D446A1DF4D8855ABFEE304`；ALGO-R3-SCALAR-BL-20261006-v1，26项，基线SHA256 `44ADE6D5C03C138C2A5BF2B039409B738351B923B85FB81B4F085BBC1B220741`。本轮26项核对0漂移，work根不存在。

按原卡F生成kind0–7的整数乘/加减/除/根/比较模块、独立参考、TB、运行脚本及四pin25MHz Ti60F225/I3工程，13业务文件；模块单测→观察顶层整合→综合/接口生成/布局布线/时序→必要门槛通过后的bit/hex与staging登记。新根 `work/active/track4_algorithms_20261004/r3_scalar`。复用reset_sync按冻结字节复制，不改R1/R2共享源或原HDK。

本批允许本地JSONL/Side-effect ledger/报告/产物登记，正式数据库、PROJECT_STATE、TASK_LEDGER和硬件节点状态不改。原设计与基线保持原字节；此实录附于任务设计并引用真实聊天，不伪称正式Manifest/数据库已更新。硬件操作、下载/安装/联网、原保护IP变更，以及完整识别/角表/LS-TLS/生产接口等后续实现不进入此范围。到bit/hex后停止硬件步骤。
