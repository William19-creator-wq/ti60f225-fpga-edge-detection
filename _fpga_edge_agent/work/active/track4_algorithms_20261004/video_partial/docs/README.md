# 摄像头采集整理与 HDMI 呈现：代码和操作入口

2026-10-08；VIDEO-PARTIAL v1 / FAST-BL-20261008-v1。已批准并实现15份文件，完整软件验证、Ti60F225/I3独立综合/接口生成/布局布线/已布线STA通过，实验bit/hex已登记。实物操作未执行。原冻结设计仍保留历史审阅状态；当前结果以本页和实际run为准。

## 先看整体，再看模块

采集路径：模拟已解码RAW10双像素 → camera_capture_normalizer → RAW/8bit预览/坐标/帧号/好坏帧终态。呈现路径：video_timing_1080p_pair → 源坐标请求 → 调用方当拍数据 → video_compare_presenter → 同拍寄存的RGB/DE/HS/VS。

组合验证将采集模块的实际输出保存为软件帧数组，再用它提供灰度和边缘样本。RGB是独立合成彩色图案；边缘样本是相邻亮度差阈值，供测试呈现接口。这里没有将RAW预览称作去马赛克彩色，也没有将显示样本称作完整Canny。

阅读次序：[整体及原草图](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-VIDEO-PARTIAL-001.md) → [采集代码](../rtl/camera_capture_normalizer.sv) → [扫描计数](../rtl/video_timing_1080p_pair.sv) → [模式和颜色](../rtl/video_compare_presenter.sv) → [组合观察顶层](../rtl/video_partial_probe_top.sv) → [采集测试](../tb/tb_camera_capture_normalizer.sv) → [呈现测试](../tb/tb_video_compare_presenter.sv)。

## 内部语句和交接草图

采集模块：先定义四个状态和最后坐标常量；组合块只决定等待SOF/活动帧的错误优先级；时序块先清本拍valid脉冲，再处理实际in_valid。第一组合格SOF分配ID、输出坐标0/0，并把下次输入坐标存为2/0。正常行尾将下次x置0并推进y。非法组不输出像素，而给旧帧失败终态；下一合规SOF恢复。气泡保持payload和计数。最后ID允许当前帧完整结束，此后HALT，不回绕。

扫描模块：h_count/v_count保存当前位置；组合译码当前DE/HS/VS/坐标；时序块推进下一位置。每帧1100×1125拍，每拍两个像素。时序不因来源缺数据暂停。

呈现模块：effective_mode在帧头取cfg_mode，其他拍取frame_mode；这样首组和后续组使用同一帧模式。source_x0/source_x1/source_y先给调用方当前请求；四分支计算两像素颜色，最后同一个时序块将颜色和控制一起寄存。分屏每侧横向压缩2倍，边界960不跨双像素组。真实同步RAM需要未来预取适配，不可直接假定零延迟。

probe采用原两级reset_sync。自主RAW和颜色源驱动真实单元，数据、坐标、帧身份及终态折入checksum供LED观察。它只有四个独立实验引脚。

## 已执行证据

- 仿真：runs/video_suite_002，camera实际1,036,800组/2,073,600像素与独立参考逐字节相等；26个小图、气泡、错误、恢复、最大ID和复位检查通过。
- 呈现：4种模式、8,294,400像素、4,950,000扫描拍逐项比对；帧中改变cfg不改变当前帧；probe完成4个好帧。真fatal运行退出非零，正常运行和独立审核退出0。
- 物理：runs/video_physical_001，853/60800 XLR、0 RAM、0 DSP；25MHz setup35.894ns/hold0.098ns；内部无时钟、未约束、多时钟均0；五组实际数据D路径及复位同步路径非空且通过。
- 引脚：J2/1A/1.8V/GCLK，P13 KEY、N14/P14 LED/BR/3.3V/4mA。工具将J2时钟显示为clk_25m.P、GPIOL_P_08_CLK1_P，已经由PT报告核对。
- 登记：[VIDEO-PARTIAL-20261008-v1](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/VIDEO-PARTIAL-20261008-v1/artifact-manifest.json)，213份hash绑定文件；原Efinity输出保留，未下载或烧写。

## 软件画面和 GUI 操作

[彩条](../runs/video_suite_002/actual-mode0.png)、[RAW亮度预览](../runs/video_suite_002/actual-mode1.png)、[灰度/边缘分屏](../runs/video_suite_002/actual-mode2.png)、[合成RGB红边叠加](../runs/video_suite_002/actual-mode3.png)全部来自实际RTL输出，而后导出PNG。

在Efinity打开project/video_partial.xml，确认Ti60F225、I3、顶层video_partial_probe_top。源码按工程列表查看；打开video_partial.sdc可见40ns时钟和仅两级异步SR/两LED的例外。要复现原结果，查看runs/video_physical_001中的各阶段argv、stdout/stderr和快照；新实验使用新RunId，不覆盖旧报告。布局结果、pinout和timing都在flow/outflow；额外STA在sta/outflow。

Questa波形优先看in_valid/in_sof/in_eol、pixel_valid/x_even/y/frame_id、frame_end_valid/good；呈现看frame_start/cfg_mode/frame_mode、source_x0/source_x1和out_rgb_pair/out_de。先找帧头，再找行尾和分屏958/960边界，最后查看错误/气泡，避免只凭截图判时序。

VP01→capture→VI-T01/02→camera-result/audit_camera；VP02→timing→VI-T03→presenter-result；VP03→presenter→VI-T04→四幅实际图；VP04→软件fixture和probe→VI-T05→实际capture-gray.bin及4帧观察；VI-T06→15份源码/工程/runner→release-gate及登记manifest。

真实CSI/MIPI解包、去马赛克、CDC/FIFO、DDR帧服务、74.25MHz生产时钟和TMDS发送还需后续实现/验证。本独立25MHz结果不宣称真实HDMI接口或摄像头链路已经通过。
