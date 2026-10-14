# Ti60F225 V4 图像边缘检测工程

基于 Ti60F225 DemoBoard V4、SC431HAI 彩色 MIPI 摄像头和板载 DDR3 的 FPGA 图像处理项目，目标覆盖赛题四的五项基础与六项高阶功能。本库保存截至 **2026年10月14日** 的代码、设计、验证证据、比特流索引和实物调试问题。

**当前状态：多个算法与接口组件已完成软件验证，整机有通过综合、布局布线和时序检查的版本；HDMI 彩条已在实物显示，主板侧 I²C 电平检查已通过，但相机仍无地址应答，真实摄像头图像与完整复杂识别尚未验收。**

## 从这里开始

1. [当前成果与剩余工作](docs/CURRENT_STATUS.md)：区分组件、整机编译、实物效果。
2. [摄像头调试记录](docs/CAMERA_DEBUG.md)：花屏、无 ACK、复位对照与最新电压结果。
3. [打开代码与使用 Efinity](docs/GETTING_STARTED.md)：工程入口、下载设置与旧版引脚注意事项。
4. [未解决问题](docs/OPEN_ISSUES.md)：后续定位和验收条件。
5. [仓库内容与导出边界](docs/REPOSITORY_CONTENTS.md)：源文件清单、Release 比特流与未上传的生成文件。
6. [第三方来源](docs/THIRD_PARTY.md)：原厂 IP、资料和项目代码的来源边界。

## 主要代码入口

| 内容 | 仓库位置 |
|---|---|
| 灰度、中值、Sobel、窗口、阈值、Canny、数值拟合、采集显示及帧服务组件 | [_fpga_edge_agent/work/active/track4_algorithms_20261004](./_fpga_edge_agent/work/active/track4_algorithms_20261004) |
| 已通过整机物理实现的历史 031 工程 | [_fpga_edge_agent/work/active/track4_board_debug_031_20261011](./_fpga_edge_agent/work/active/track4_board_debug_031_20261011) |
| 031 后续精简与引脚修订 B02 工程 | [_fpga_edge_agent/work/active/track4_board_refine_from031_20261013](./_fpga_edge_agent/work/active/track4_board_refine_from031_20261013) |
| 更完整识别和冻结重处理的开发主线及失败构建记录 | [_fpga_edge_agent/work/active/track4_board_first_20261011](./_fpga_edge_agent/work/active/track4_board_first_20261011) |
| 已完成实物电平检查的相机诊断工程 | [_fpga_edge_agent/work/active/track4_camera_bus_level_001_20261013](./_fpga_edge_agent/work/active/track4_camera_bus_level_001_20261013) |
| Claude 的持续复位高低对照工程 | [_fpga_edge_agent/work/active/track4_cam_rst_static_001_20261014](./_fpga_edge_agent/work/active/track4_cam_rst_static_001_20261014) |
| 设计、操作草图、审批和任务追踪 | [_fpga_edge_agent/planning](./_fpga_edge_agent/planning) |
| 已登记软件组件和交付清单 | [_fpga_edge_agent/artifacts/staging](./_fpga_edge_agent/artifacts/staging) |
| 实物观察与原始测量 | [_fpga_edge_agent/observations/structured](./_fpga_edge_agent/observations/structured) |

## 验证结果如何阅读

独立组件通过仿真或综合，不等于完整整机通过；生成 bit，也不等于实际摄像头、识别或性能达标。不同版本的验证状态分别保存在各自清单中，开发主线的新源码不能借用 031 的成功结果。

历史文档保留当时状态与原机器绝对路径。正式 PostgreSQL 和 `PROJECT_STATE.json`、`TASK_LEDGER.csv` 没有随获批的本地实验同步更新，因此这些旧状态文件不能替代上述最新成果说明。原始源码和历史报告未被改写为“全部完成”。

## 比特流

已生成的 bit/hex 通过本仓库 **Releases** 提供。使用 [比特流路径和 SHA256 索引](docs/export/bitstream-paths.csv) 找到对应工程与压缩包中的文件；压缩包包含历史版本及失败或未验收版本，下载前必须按 [工程入口说明](docs/GETTING_STARTED.md) 选择。

本仓库按用户要求创建为私有仓库，未给所有第三方代码附加统一开源许可证。
