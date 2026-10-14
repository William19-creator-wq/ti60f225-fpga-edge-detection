# DDR Q0 v1 实施批准实录

2026-10-06，来源为本聊天的用户直接回复：**批准**。紧接该回复之前，用户询问DDR Q0与R3算术两项批准的内容；助手逐项说明具体范围、设计版本及本批本地审计例外，并明确两项可以一起批准。因此本回复批准两项所呈现范围，不扩展到后续未批准功能。

批准对象：TRACK4-DDR-Q0-001 v1，设计SHA256 `C71025F22C68E29858C57175E9976924D063A2BCE52BE1FBEDA8FD531467087D`；DDR-Q0-BL-20261005-v1，44项，基线SHA256 `9460D055EFDD83D228F05DAB28632DDFFCE785CB096F84C288800F218B56A4E1`。本轮核44项，0漂移，独立work根不存在。

允许在 `work/active/track4_ddr_q0_20261005/v1` 复制31份冻结文件、派生本地INI/库映射、单次直接调用既有Questa编译/合法展开真实ddr3_top、保存诊断/报告/元数据。不生成新RTL、功能脚本、TB、模型，不运行vsim或动态仿真，不执行Efinity/bit，不补依赖或失败后自动重试，不改保护IP、原资料、安装、许可或硬件。

本批允许本地JSONL/报告/副作用审计，PostgreSQL未配置；正式DB、PROJECT_STATE、TASK_LEDGER、hardware_nodes不改。原批准设计/基线及live Manifest保持原字节，此实录引用真实聊天作为指定范围授权，不冒称正式DB或Manifest已登记。旧NOT_APPROVED是批准前状态；实施事实写新报告。
