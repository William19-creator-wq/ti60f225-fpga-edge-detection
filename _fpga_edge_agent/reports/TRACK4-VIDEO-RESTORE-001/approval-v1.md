# TRACK4-VIDEO-RESTORE-001 v1 批准记录

- 日期：2026-10-15，聊天用户回复原文：“批准”。
- 指向：紧接 Codex 请求“批准 TRACK4-VIDEO-RESTORE-001 v1，按 B02 基线实施、构建并允许本次本地审计例外”。
- 获批前设计 SHA256：`573B57C2FE487AB700FB524FB28B51B31B5B7B91A8AEDE260848A8FFAB325099`。
- 输入基线：B02；`baseline-b02-inputs.sha256`，199 项，SHA256 `9E3C1B5A919B53B55F8498A867E191CDAEB78595BB12E3BB2D5E5BE55F3E4009`。
- 范围：设计卡 VR-1..3，独立工作副本内改 PLL/顶层、SDC、显示彩条、诊断灯；Efinity 综合、布局布线、时序及 bit 登记。
- 审计：本次控制面本地追加审计例外；正式 PostgreSQL 未配置，不写正式数据库及项目节点状态。
- 硬件：下载和现象观察由用户完成；本批准不包含 Agent 下载 FPGA/Flash。
