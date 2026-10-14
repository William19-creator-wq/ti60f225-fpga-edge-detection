# RAW10 彩色流 v1：实际行 RAM、边界与四相位插值

本包按 `design-TRACK4-RAW10-COLOR-STREAM-001.md` 和用户持续自主授权实现；基线为 `RAW10-COLOR-STREAM-BL-20261008-v1`，9 份输入。原 HDK、旧 R1 与已登记组件均保持原样。代码阅读顺序：整体 `raw10_color_stream` → 两像素窗口 `raw10_window_pair` → 行存储 `raw10_line_store_pair` → 复用的 `raw10_debayer_pair`。独立参考和测试分别在 model、tb，运行入口在 scripts，组件工程在 project。

## 中文内部操作草图

先接纳 job 并锁定 64 位 handle 与 Bayer phase；ARM 建立空窗口，RUN 按真实握手接收每拍两颗 RAW10。第一行只填 RAM；第二行建立顶边镜像，后续行按旧行/当前行输出 3×3 窗口。两份行历史各分成偶、奇像素 RAM，4 个 1024×10 EFX_RAM10；不清 RAM 数组，新的行有效性隔离旧帧。同步 RAM 返回使用 read_pending 及一个窗口 holding 槽，下游停顿时停止新读写，已返回的旧数据保留到实际消费。

上下边界使用 reflect101，左右边界分别反射到列 1 与 W−2；最后一行通过 REPLAY 完成。每个窗口保持 10 位 RAW 精度，插值在一次最终量化后输出 canonical RGB48={R1,G1,B1,R0,G0,B0}。四个 Bayer 相位由 job 锁定，中途改变输入 phase 不改变该帧。

坏输入仍按原 ready 计一次 accepted，随后不写窗口；错误优先级为 bad、handle、坐标、marker。取消停止新输入，私有窗口清退；已经公开的 RGB 保持到消费者真实接收。旧同步读返回只能消费或登记 discard 一次；完成状态等待窗口与公开 RGB 全部关闭。未知 DDR 借用不属于本模块接口，后续源 writer 与父生命周期处理。

## 实际验证

| 运行 | 几何与场景 | 实际结果 |
|---|---|---|
| raw_color_small_002 | 34×19，四相位×10 模式 | 40 帧、25,840 像素，逐窗口/RGB/坐标/marker/handle 一致 |
| raw_color_minimum_001 | 4×2，四相位×10 模式 | 40 帧、320 像素；最小尺寸及边界一致 |
| raw_color_6x5_001 | 6×5，四相位×10 模式 | 40 帧、1,200 像素；后续 Canny 合法最小交集 |
| raw_color_seam_001 | 1040×3，四相位×10 模式 | 40 帧、124,800 像素；实际 RAM 地址跨 511/512 |
| raw_color_hd_001 | 1920×1080 彩条，四相位 | 4 帧、8,294,400 像素、4,147,200 窗口 pair 全部一致 |

普通尺寸测试另覆盖 4 类输入错误、8 类取消、反压、held done、错误 cancel ID 与安全共同复位。4×2 的 RUN 输入停顿取消不可达，覆盖其余 7 类；不伪造不可达状态。1080p 每帧 accepted/window/output 均为 1,036,800 pair，无 discard；各帧用时 2,136,158 / 2,134,655 / 2,135,227 / 2,134,581 个仿真时钟。它们含测试端随机间隙，不直接等同实物摄像头帧率。

`raw_color_map_001` 在 Ti60F225/I3 上完成 Efinity 组件 MAP：4 RAM10、640 FF、1,044 LUT4、200 ADD、0 DSP。仅综合组件内部逻辑；100MHz 是组件输入目标，还没有该组件的生产引脚、布局布线、静态时序或比特流证明。

## 复跑与观察

在 scripts 使用 `run_raw_color_sim.ps1`，指定全新的 RunId；默认 34×19，可指定 Width/Height 或 FullHD。原运行目录保留，失败日志也不覆盖。随后以通过且源 hash 相同的 SimulationRun 运行 `run_raw_color_map.ps1`。runs 中的 reference-audit.json、actual-results.txt、源清单及 Efinity map 报告形成追踪证据。实际 `.rgb` 文件是 canonical RGB48 的小端字节，即 B0/G0/R0/B1/G1/R1；显示软件需按此重排，DDR 源 writer 将另转换成 R/G/B 连续字节。

本包接收已经解码的同步 RAW10 pair。真实 SC431HAI I2C、MIPI/CSI、不可反压 FIFO/CDC、RGB 源写回与 RX closure、DDR phase fence、帧发布及整机资源/时序继续闭合；本包通过不表示这些已经完成。生成总比特流之后的硬件操作仍不执行。
