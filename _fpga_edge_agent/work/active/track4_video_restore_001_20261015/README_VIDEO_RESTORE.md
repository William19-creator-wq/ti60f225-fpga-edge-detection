# TRACK4-VIDEO-RESTORE-001 v1：上板候选工程

本目录是从 `TRACK4-031-REFINE-001-B02` 复制的独立工程。打开 `track4_board.xml` 查看代码；Efinity 2026.1.132、Ti60F225/I3 完成了 map、interface、PnR、STA 和 bit 生成。原 B02 和官方演示工程没有被覆盖。

## 本版做了什么

- 按官方 SC431HAI→HDMI v7 的 PLL 端口与频率，恢复 `core_clk` 为 100 MHz，并去掉第四 PLL 对整机复位的额外门控；DDR3_PLL 的 `clk_100m` 反馈端口保留。
- 未有已发布帧时，在原 1080p HDMI 时序内送出八色竖向彩条；有效帧出现后在显示帧首切回原 RGB/FIFO 输出。相机寄存器、曝光、去马赛克、颜色增益及算法未改。
- D2–D7 分别显示 `i_arstn`、USER_PLL 锁定、MIPI_TX_PLL 锁定、DDR3_PLL 锁定、视频复位释放、三锁定总复位释放；D0/D1 保留 B02 语义。

只改动了四份构建输入：`track4_board.peri.xml`、`track4_board.sdc`、`rtl/ti60f225_oob_top.v`、`board/rtl/board_frame_display.sv`。199 份输入的哈希清单见控制面 `reports/TRACK4-VIDEO-RESTORE-001/build-01-inputs.sha256`。

## 编译结果与下载文件

- Efinity：map / interface / PnR / pgm 均 PASS，静态时序最差建立 +0.257 ns、保持 +0.029 ns；`core_clk` 100 MHz 建立裕量 +1.331 ns。
- 打包资源：XLR 44,343 / 60,800；RAM 163 / 256；DSP 8 / 160。
- 下载文件：本目录 `outflow/track4_board.bit`。SHA256：`D13B8719D5DDD7CD78697AAFC3DEA635A5BC4ED3D9BBF991C6FF62E78D27B8DE`。
- 同一文件已登记在控制面 `artifacts/staging/TRACK4-VIDEO-RESTORE-001-V1/track4_board.bit`。完整报告：`reports/TRACK4-VIDEO-RESTORE-001/实施与首测说明.md`。
- 本批未运行仿真；软件时序通过不代表实物显示或相机颜色已验证。

## 实物首测

在 Programmer 选 Ti60F225 和板载 JTAG USB Target，加载上面的 **本版 bit** 到 FPGA 临时配置。保持 HDMI、摄像头、板卡供电连接，观察 5 分钟：显示器是否稳定识别 1920×1080@60，屏幕是彩条、相机图、黑画面还是无信号，以及 D0–D7 状态。无帧应先出现彩条；若上电已有已发布帧，可能直接进入原图像路径。不同现象会决定下一步查时钟、帧发布还是色彩，不应先改曝光参数。

当前状态：`WAITING_HUMAN_PROGRAM`，尚未进行本版实物下载和效果验证。
