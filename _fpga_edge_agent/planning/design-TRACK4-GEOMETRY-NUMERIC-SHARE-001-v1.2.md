# TRACK4-GEOMETRY-NUMERIC-SHARE-001 v1.2：lease 与完整 FIT 范围解耦

2026-10-11。READY_FOR_REVIEW；本次只保存修订设计，尚未实施新参数。引用用户持续自主推进、本地审计及免新增独立 TB 授权，不伪称指定版号获批。原 v1.1 卡、原候选、main 和冻结 flow 不改。

- Goal / Gap：ROOT 已确认圆 refine 的既定合同只向 FIT 提交 kind11；E/STATS 的 kind17 不向 FIT 提交，其 det/quality 后续复用唯一 scalar。几何 lease 不应因启用即必然展开七种 FIT；保留显式完整能力，资源收益仍须整机实测。
- Baseline / 阅读：原卡 `planning/design-TRACK4-GEOMETRY-NUMERIC-SHARE-001.md` v1.1（SHA256 `4477A6F22BB0FED8DB032A18C052495FF2A140F8B140F3CFD9E37F2B8ADB5445`）→ NUM 返回字卡 v1.1 → 合并候选 `work/active/track4_board_first_20261011/candidates/geometry_numeric_share_merged_v1/board/rtl/board_recognition_stats.sv`（SHA256 `6A5585168E50DE5D3B607BC917400A7683FEB2E6096D8C517CFDC39577E8A157`）。合并前 main/before SHA256 为 `35B4AB6B70A270FACE0423F433B159FFEADEAFC143AD33B683A67B122FE3808F`。
- Scope / IF01：仅上述 wrapper 后续独立候选新增 bit 参数 `GEOMETRY_FULL_FIT`，默认1；唯一 FIT 的 `LS_TLS_ONLY` 改为 `!(ENABLE_GEOMETRY && GEOMETRY_FULL_FIT)`。其余端口、参数、STATS、共享 scalar 和逐字返回连接不变；不修改 FIT 本体。
- 组合规则：ENABLE_GEOMETRY=0 时任何新参数值均保持原11/12流程；ENABLE_GEOMETRY=1、GEOMETRY_FULL_FIT=1 与 v1.1 相同，原七 kind11/12/13/14/15/17/18 保留；ENABLE_GEOMETRY=1、GEOMETRY_FULL_FIT=0 只准 FIT kind11/12，其他 kind 仍由原 FIT 校验返回 UNSUPPORTED/FRAME_FAIL，不能伪映射成11/12。
- 中文操作草图：父圆协调器计划显式设置 GEOMETRY_FULL_FIT=0 → bind 原 lease → 原 TOKEN/STATS（可用17）→ 仅向 FIT 送真实11/12 → 原 reply/quiet 关闭 → release；未来确需其他 FIT kind 的调用者显式开1，并承担真实资源测量。父级 scalar/索引 owner 调度仍须真实闭合。
- 保留条件：TOKEN低176与请求622借用寿命、STAT ready 前置条件、bind/start互斥、所有真实 quiet/cancel/UNKNOWN 规则、完整585/385检查与25字扫描/12字保存均沿 v1.1，不增周期、快照、算术核或 CDC；返回字不能按 child valid/quiet 清零。
- 验证 / 双向追踪：范围解耦需求→IF01参数与 LS_TLS_ONLY 映射→四组合静态核对；协议不变需求→原 lease/NUM 连接→候选差异限参数和一个常量表达式。ROOT 读回呈现后再指定独立候选实施；不新增 TB、仿真或本轮 EDA，未称工具通过。
- 回退 / 完成：新参数设1恢复 v1.1启用行为，原合并候选及 before 保留；局部参数修订不代表完整圆后端或完整 A6 已完成。
