# Ti60F225 V4 视频恢复版：TRACK4-VIDEO-RESTORE-001 v1

**当前入口**：本目录是从 REFINE-001 B02 派生的独立软件修复版。请先阅读同目录的 [README_VIDEO_RESTORE.md](README_VIDEO_RESTORE.md)；下面内容仅是保留的 B02 历史说明，里面的 bit 哈希、LED 范围和构建结论不代表当前版本。

# REFINE-001 B02 历史说明（基于 031）

在 Efinity 中用 Open Project 打开本目录的 track4_board.xml，顶层为 track4_board_top，共 109 个源码入口。

- 代码：rtl、algorithm、board、ip；
- 外围与引脚：track4_board.peri.xml（与 031 完全相同）；
- 时序约束：track4_board.sdc。
- 建议使用 ASCII 路径打开：`C:\Users\34528\FPGAEdgeLinks\Work\active\track4_board_refine_from031_20261013`。

本目录是 031 调试版（`track4_board_debug_031_20261011`）的独立副本。031 原目录和原 bit 未改。设计与批准记录：控制面 `planning/design-TRACK4-031-REFINE-001.md`（v0.1，用户 2026-10-13 批准）。

## 相对 031 的改动

| 编号 | 文件 | 改动 | 原因 |
|---|---|---|---|
| C1 | board/rtl/board_algorithm_rpc.sv，track4_board.xml | 移除未上屏的识别数值链：gradient_store、POINT、统计/拟合、锚点，以及它们的访存仲裁器；Canny/Sobel 访存口直连 | 省约 1.6 万 XLR；消除模式 5 的 POINT 末包缺陷和由此引发的整机停机。屏幕上的框和 C/R 由 board_shape_tracker 产生，未改 |
| C2 | rtl/csi_rx_controller.sv | `PACK_TYPE` 15→1，只保留 RAW10 解包器 | 本设计只接 RAW10，省资源 |
| C3 | track4_board.sdc | 补 HDMI TMDS 发送端和摄像头 MIPI 数据通道的 I/O 延迟约束（取自界面生成模板）；修正 hdmi_tx_fast_clk 的波形 | 031 中这些路径未被时序分析覆盖 |
| C4 | rtl/cam_i2c_ctrl/i2c/i2c_master_reg_rom.v | 曝光 0x1BBF→0x0BAD（=2989，即 VTS 为 1500 时手册允许的上限） | 031 的取值超出数据手册范围 |
| C5 | board/rtl/board_frame_display.sv | 帧请求翻转的跨时钟同步由 2 级改为 3 级 | 避免多位帧标签偶发采错，导致整帧黑屏 |
| C6 | README.md，handoff.json | 本说明 | — |

C1 只从工程列表中移除了 15 个文件，文件本身仍在 board/recognition_numeric 和 board/rtl 下，未删除。board_native_rpc_arbiter2.sv 仍被 Canny 使用，保留在工程中。

## 编译结果

**B02（v0.2，第 2 次编译，2026-10-13，当前版本）**：在 B01 基础上只改 peri.xml 中 4 个引脚（见下节"按键与 LED"）。

- 综合、界面生成、布局布线、bit 生成全部通过。
- 资源：XLR 44,177/60,800（72.7%）。
- 时序：建立最差 +0.253 ns，core_clk +1.854 ns，保持最差 +0.023 ns，无负裕量路径。
- 下载文件：outflow/track4_board.bit，SHA256 `63906ed2a32f595069f1d7b738cc9106f03d8d638e83a504fe85fd1250c371a2`。
- 登记位置：控制面 `artifacts/staging/TRACK4-031-REFINE-001-B02/`。
- 未运行：仿真、实物验证。

**B01（v0.1，第 1 次编译，已作废）**：
- 结果：XLR 44,177；建立最差 +0.408 ns；TMDS 输出 +5.23 ns，摄像头 HS 输入 +8.40 ns。
- 实物：黑屏，显示器无任何提示。原因推断为沿用了 031 的错误复位引脚（P13 实为 D0 灯）。
- bit SHA256 `1e3fe7f9…6c8`，不要再使用。

## 按键与 LED（v0.2 起按说明书表格，已由实物 D0 证实）

| 板上标识 | 球位 / GPIO | 本工程信号 | 作用 |
|---|---|---|---|
| KEY0 | C4 / GPIOL_07 | key_inc_n | 加阈值 |
| KEY1 | P14 / GPIOR_22 | i_arstn | 复位（同时复位 4 个 PLL） |
| KEY2 | N14 / GPIOR_21 | key_dec_n | 减阈值 |
| KEY3 | A3 / GPIOL_03 | key_mode_n | 短按切换模式，长按约 0.22 秒冻结/恢复 |
| D0 | P13 / GPIOR_27 | led[0] | DDR 校准完成后闪烁 |
| D1 | N13 / GPIOR_24 | led[1] | 熄灭 = 正常；闪烁 = 冻结；常亮 = 故障 |

- 依据：官方 v7 工程把 led[0] 接 GPIOR_27，用户实测 D0 闪烁，说明 P13 是 D0。031 和 B01 按原理图文字层接反了。
- 模式依次为：0 彩色、1 灰度、2 灰度/Sobel 分屏、3 Canny、4 红色叠加、5 几何候选。上电默认模式 4。
- KEY0+KEY2 同按切换 Bayer 相位，默认相位 1。

## 状态与限制

- 当前状态 WAITING_HUMAN_PROGRAM：编译通过，不代表实物通过。
- 实物通过之前，031 仍是交付基准。
- 仍待首测现象决定的项目：按键/LED 引脚、Bayer 默认相位、CSI 时钟模式、DDR 读写带宽余量、摄像头帧率。
- 模式 5 是官方简易识别：最多 4 个框，C/R 由长宽比和梯度方向分布判断。不包含复杂圆拟合或任意旋转矩形识别。
- 旧文件 031已知限制补充.txt、实物首测说明_031.txt 描述的是 031。其中"模式 5 POINT 缺陷"一条在本版已不适用。
