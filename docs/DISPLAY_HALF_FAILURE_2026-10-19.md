# 960×540 显示尝试：失败归档

状态更新于 2026-10-19。用户对新版本的明确反馈为：“请用回上一个版本的，这个新版本的输出结果是显示器黑屏无信号”。因此 `TRACK4-V7-DISPLAY-HALF-001` 不属于有效显示基线，停止推荐。

失败 bit SHA256：`e36ce92c7fb770355c34cf6f817e9f75e91919f190ea8061ef530aeef00c44e2`。源码保存在 [`track4_v7_display_half_001_20261018`](../_fpga_edge_agent/work/active/track4_v7_display_half_001_20261018)，原构建记录在[staging](../_fpga_edge_agent/artifacts/staging/TRACK4-V7-DISPLAY-HALF-001)。本次 Release 不含该 bit。

原 manifest 记录的是软件构建通过、等待人工下载的时间点，不能用它否定后来的实测失败。没有本次回退后用户确认恢复的记录。

需要检查的实现：它把 CVO 有效区设为 960×540，并通过扩大前后肩保持总计 2200×1125，同时在 DDR 前对 RAW 做降采样。这不等于在标准 1080p 有效区内居中显示 960×540 RGB；总周期相同不足以证明显示器能接受这种有效区/模式。RAW 隔行/列抽样也存在破坏 Bayer 相位的风险。这两点是代码复核方向，**不是已通过实测确认的黑屏根因**。

接手先回退 `v7_algorithm_bridge_001_v1_20261018.bit`。后续缩小功能应单独验证标准 HDMI 有效区、同步/消隐、RGB 采样与 Bayer 处理，不与算法迁入混做。
