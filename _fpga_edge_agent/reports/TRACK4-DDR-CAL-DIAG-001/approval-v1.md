# TRACK4-DDR-CAL-DIAG-001 v1 批准记录

- 日期：2026-10-15。
- 用户回复原文：“批准该版本、范围与本地审计例外”。
- 指向的审批问题：`TRACK4-DDR-CAL-DIAG-001 v1`，设计卡 SHA256 `70F1669BD04AFAEBA1296D6107DCC343404C05A0C13421BC139D08023354AF8B`；199 份输入基线清单 SHA256 `5BA384670C173E425E95037B08D67355EA034F054B7F81412FFD6A712247674A`。
- 范围：新的独立工作副本，仅一份顶层 RTL 灯态诊断修改，Efinity map/interface/PnR/STA/pgm，通过后生成并登记临时 bit。
- 审计：本批控制面本地追加记录例外；正式 PostgreSQL、`PROJECT_STATE.json` 和硬件节点状态不改。
- 人工闸门：Agent 不进行 JTAG/Flash 下载或代替用户报告灯态。
