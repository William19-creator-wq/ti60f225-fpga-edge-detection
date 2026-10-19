# 当前状态（2026-10-19）

推荐基线是 `TRACK4-V7-ALGORITHM-BRIDGE-001`，不是最新尝试的 DISPLAY-HALF。完整操作和下一步见[交接说明](HANDOFF_2026-10-19.md)。

| 版本 | 软件证据 | 实机证据 | 接手结论 |
|---|---|---|---|
| BGGR-WB | 黑电平／BGGR 通道增益验证与构建通过 | 用户确认颜色恢复；同光源白纸正常 | 颜色回退基线，尚无后续像素顺序修正 |
| FPS | 计数器仿真、构建通过 | 三次抓取：1920×1080，约 12.660 FPS | 独立测量版，不代表所有后续 bit 已复测 |
| PIXEL-ORDER | 实际 ser2par/DDR buffer/par2ser 链对照，连续／气泡／回压；每版本 11,520 像素 | 用户细线对照：条纹完整，中间稍软／细彩边，下方实时 | 修正每四像素交换；不宣称所有清晰度问题均解决 |
| ALGORITHM-BRIDGE | 全尺寸两帧 4,147,200 像素逐像素比对；模式、故障、复位；setup ≥0.464 ns，hold ≥0.026 ns | 2026-10-18 用户：“五区都实时变化，边缘位置正常” | **推荐基线** |
| ALGORITHM-CONTROL | 全尺寸三帧 6,220,800 像素；七模式小图、消抖、故障；setup ≥0.231 ns，hold ≥0.027 ns | 未取得针对该 bit 的验收 | 待验证候选，不能借用五分区的实机通过 |
| DISPLAY-HALF | 构建与时序通过；setup ≥0.410 ns，hold ≥0.027 ns | 用户明确报告黑屏无信号并要求回退 | **失败，停止推荐** |

## 证据索引

- [五分区实机反馈](../_fpga_edge_agent/reports/TRACK4-V7-ALGORITHM-BRIDGE-001/hardware-live-five-region-20261018.json)、[软件检查](../_fpga_edge_agent/reports/TRACK4-V7-ALGORITHM-BRIDGE-001/checks.json)、[构建与 bit 清单](../_fpga_edge_agent/artifacts/staging/TRACK4-V7-ALGORITHM-BRIDGE-001/manifest.json)。
- [按键版说明与验证范围](../_fpga_edge_agent/reports/TRACK4-V7-ALGORITHM-CONTROL-001/按键与同画面对照_交付说明.md)。
- [真实帧率结果](../_fpga_edge_agent/reports/TRACK4-V7-FPS-001/实际采集帧率结果_20261018.md)。三个抓取文件每份重复发送一个最近完整帧的统计包，不是 189 个独立帧样本；参考时钟使用配置的 50 MHz，未外部校准。
- [BGGR 校准](../_fpga_edge_agent/reports/TRACK4-V7-BGGR-WB-001/calibration.json)、[颜色实机反馈](../_fpga_edge_agent/reports/TRACK4-V7-BGGR-WB-001/hardware-color-observation-001.json)。
- [像素顺序链路证据](../_fpga_edge_agent/reports/TRACK4-V7-PIXEL-ORDER-001/data-path-evidence.json)、[官方 v7 来源对照](../_fpga_edge_agent/reports/TRACK4-V7-PIXEL-ORDER-001/official-v7-origin.json)。
- [本次源码哈希核对](export/20261019/source-input-verification.json)、[导出文件清单](export/20261019/included-files.csv)。

## 仍未证明

HDMI 1920×1080@60Hz 不等于相机采集 60 FPS，也不等于镜头能分辨对应的细节。当前五分区 bit 的采集 FPS、长时间稳定性、丢帧情况和算法实机数值一致性仍需测量。完整 Canny、冻结重处理和形状识别尚未接入推荐基线。原 031/refine 不出相机画面的根因未闭环，不能写成“重构 demo10 后已全部修好”。

历史 manifest 中的 `WAITING_HUMAN_PROGRAM`、`hardware_passed:false` 是登记时的快照；后到的实机反馈单独保存，不篡改旧证据。正式 PostgreSQL 未配置；本次只做本地审计与 GitHub 交接更新。
