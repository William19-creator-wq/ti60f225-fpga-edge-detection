# 打开代码与使用 Efinity

先阅读[当前成果](CURRENT_STATUS.md)。仓库保留原工程结构；导出过程没有重新编译或修改RTL和约束。历史脚本与日志含原机器路径，运行脚本前需检查自己的Efinity/Questa路径、ASCII别名和工作目录。

## 工程入口

在Efinity主窗口选择 Open Project 打开XML。Programmer用于加载bit，不能把它当作源码工程编辑器。

| 目的 | XML位置及状态 |
|---|---|
| 精简后的整机修订版B02 | `_fpga_edge_agent/work/active/track4_board_refine_from031_20261013/track4_board.xml`；软件构建通过，实际效果未验收 |
| 历史031整机源码 | `_fpga_edge_agent/work/active/track4_board_debug_031_20261011/track4_board.xml`；保留原引脚和缺陷用于追溯，见下节 |
| 主板I²C电平检查 | `_fpga_edge_agent/work/active/track4_camera_bus_level_001_20261013/ti60f225_oob.xml`；本次已完成主板侧实测 |
| 原相机身份探测 | `_fpga_edge_agent/work/active/track4_camera_id_001_20261013/ti60f225_oob.xml` |
| RST高电平限时对照 | `_fpga_edge_agent/work/active/track4_camera_rst_compare_001_20261013/ti60f225_oob.xml` |
| Claude持续RST高低对照 | `_fpga_edge_agent/work/active/track4_cam_rst_static_001_20261014/ti60f225_oob.xml` |
| 原厂v7独立副本 | `_fpga_edge_agent/work/active/camera_official_diag_20261013_v7/Ti60f225_sc431hai2hdmi_v7/ti60f225_oob.xml` |
| 灰度/中值/Sobel独立实验 | `_fpga_edge_agent/work/active/track4_algorithms_20261004/r1/project/r1_algorithm.xml`；实验probe引脚不能当成生产板接口 |

布局布线与综合的缓存、波形及大型中间网表未放入Git。现有XML直接引用的必要源文件另行补入，未改写源码。对54份工程XML的design_file引用检查见[源码引用检查](export/project-source-reference-check.json)：主要工程的引用存在，开发目录中旧的 `track4_board_first_20261011/ti60f225_oob.xml` 缺 `debug_top.v`，需要按debug profile由Efinity生成；该旧XML不是当前 `track4_board.xml`。原构建方式见对应脚本和日志。克隆后未在另一台机器重新验证全部工程，因此保留工具路径和依赖检查为使用前步骤。

## 已知031引脚问题

031曾将KEY1/KEY2与D0/D1的P13/N13/P14/N14对应关系混淆。原README没有被改写，不能据其旧按键说明操作新板。B02已在peri中修订：KEY1/SW1复位为P14，KEY2/SW2为N14，D0为P13，D1为N13。官方v7及相机诊断的逻辑复位通常用SW0/C4，具体以各工程peri和设计为准。

KEY3对应板上SW3、A3；CRESET_N是配置复位，不是普通用户按键。独立四引脚算法probe的实验分配与生产整机不同。

## Programmer设置

这套已实测下载器使用：

- Board Profile：Generic Board Profile Using FT4232H。
- USB Target：local Quad RS232-HS，VID0403/PID6011。
- 驱动：已授权安装的JTAG B／Interface1 libusbK。
- Programming Mode：JTAG。
- Device Select：1／0x10660A79。
- JTAG Clock：6MHz；Shared未勾选。

Interface0/SPI缺驱动提示不等于当前JTAG B不能下载。本项目近期只临时JTAG下载；断电后程序不保留，没有确认烧入Flash。

从Release按 [索引](export/bitstream-paths.csv) 解压相应blob，恢复原文件名并核SHA256，再在Programmer选择它。日志必须明确出现对应路径、`Device is in user mode!` 和 `Programming operation completed.`；不同bit的灯义不同。

当前相机仍无ACK，不能期待任意整机bit下载后立即得到正确摄像头画面。显示器识别1080p/60Hz说明显示扫描信息，不表示算法每秒处理60帧。
