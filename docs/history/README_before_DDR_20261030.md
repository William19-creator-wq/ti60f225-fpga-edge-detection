# Ti60F225 V4 相机图像与边缘检测工程

截至 **2026-10-19**，推荐从 **v7 五分区算法桥接版**继续：已恢复相机颜色、修正每四像素的顺序，并接入自研灰度、3×3 中值和 Sobel。用户已确认“五区都实时变化，边缘位置正常”。这不是整套赛题功能的最终验收。

**不要使用最新文件名来判断可用版本。960×540 缩小显示版上板后黑屏无信号，已撤回推荐；按键版只有软件验证，尚待实机验收。** 用户已要求回退五分区版，但最后一次回退后的画面尚无确认。

## 接手入口

1. [最新交接说明](docs/HANDOFF_2026-10-19.md)：版本选择、架构、已解决与未解决的问题。
2. [当前状态与证据](docs/CURRENT_STATUS.md)：实机、仿真、时序及帧率分开记录。
3. [打开、构建和下载](docs/GETTING_STARTED.md)：推荐工程和工具环境。
4. [本次 Release：推荐 bit 与颜色回退 bit](https://github.com/William19-creator-wq/ti60f225-fpga-edge-detection/releases/tag/handoff-2026-10-19)。
5. [未完成工作](docs/OPEN_ISSUES.md)、[导出范围](docs/REPOSITORY_CONTENTS.md)、[第三方来源](docs/THIRD_PARTY.md)。

## 主要工程

| 工程 | 状态与用途 |
|---|---|
| [ALGORITHM-BRIDGE](./_fpga_edge_agent/work/active/track4_v7_algorithm_bridge_001_20261018/ti60f225_oob.xml) | **推荐基线**：全尺寸五分区，颜色／灰度／中值／Sobel／红色边缘叠加 |
| [ALGORITHM-CONTROL](./_fpga_edge_agent/work/active/track4_v7_algorithm_control_001_20261018/ti60f225_oob.xml) | 候选：七模式、差值×8、按键阈值及字幕；未实机验收 |
| [BGGR-WB](./_fpga_edge_agent/work/active/track4_v7_bggr_wb_001_20261017/ti60f225_oob.xml) | 已验证颜色回退；早于像素顺序修正 |
| [FPS](./_fpga_edge_agent/work/active/track4_v7_fps_001_20261017/ti60f225_oob.xml) | 实测相机 1920×1080、约 12.660 FPS；HDMI 配置 1080p60 |
| [PIXEL-ORDER](./_fpga_edge_agent/work/active/track4_v7_pixel_order_001_20261018/ti60f225_oob.xml) | 实际数据打包链像素顺序修正和细线对照 |
| [历史自研组件库](./_fpga_edge_agent/work/active/track4_algorithms_20261004) | Canny、帧服务、拟合等后续迁入来源；不是当前整机已接入功能 |

缩小版源码只作为[失败案例](docs/DISPLAY_HALF_FAILURE_2026-10-19.md)保留，不提供推荐下载。原 031/refine 整机仍保留供差异分析；其 DDR/无相机画面问题没有因 v7 成功而自动闭环。

本次上传不修改业务 RTL，不执行新的构建或硬件下载。已有构建输入与 bit 的 SHA256、仿真报告、RAW/FPS 测量和实物文字反馈一起保存。历史绝对路径指向原开发机器，接手时需调整工具与输出目录；正式数据库和旧状态文件不能替代本页的版本状态。仓库当前为公开，原厂版权及保护块保留，未对第三方内容附加统一开源许可证。
