# 打开、构建与上板

当前推荐基线为 [`_fpga_edge_agent/work/active/track4_v7_algorithm_bridge_001_20261018/ti60f225_oob.xml`](../_fpga_edge_agent/work/active/track4_v7_algorithm_bridge_001_20261018/ti60f225_oob.xml)。不要从 DISPLAY-HALF 开始，也不要把历史 031 工程的 bit 与这里的源码混用。

## 先复现实机基线

1. 从 [handoff-2026-10-19 Release](https://github.com/William19-creator-wq/ti60f225-fpga-edge-detection/releases/tag/handoff-2026-10-19) 下载 `v7_algorithm_bridge_001_v1_20261018.bit` 和 `SHA256SUMS.txt`，用 PowerShell `Get-FileHash -Algorithm SHA256 <bit文件>` 核对。
2. 硬件匹配 Ti60F225 DemoBoard V4、SC431HAI 接 J4、HDMI 输出。保持已工作的电源与连接；若需改接相机排线，先断电。
3. 断开 Debugger 的 JTAG 会话，打开 Efinity Programmer。选择 `Quad RS232-HS`、JTAG、设备 `1 - 0x10660a79`，加载推荐 bit。沿用先前成功的 6MHz JTAG 设置。
4. 点击下载，等日志 `Programming operation completed` 后观察画面。该流程是 JTAG 临时配置，不是 Flash 固化。五分区应按颜色／灰度／中值／Sobel／红边叠加显示；遮挡或移动镜头时各区都应实时。
5. 记录实际文件哈希、下载结果、画面与边缘对齐。若 USB/JTAG 报错或画面停帧，先停止重复采样、断开调试会话；会话历史中有仅断开不足以恢复、重新下载后恢复的情况。

## 构建与仿真

使用 Efinity 2026.1.132，Ti60F225、I3。在完整源码目录打开 XML，保留 `ip/`、`rtl/`、`algorithm/`、顶层 `debug_top.v`、寄存器 `.mem`、约束 `.sdc` 与 `.peri.xml` 的相对位置。新克隆机器的工具生成接口/缓存需由工具重新生成；本次只核对项目引用和源文件哈希，未在新机器重建。

已有脚本在推荐工程 `tests/`：

- `run_sim.py`：Python/NumPy 参考与 Questa，支持 small/fault/reset/full；依赖 Efinity `efx_ram10.v` 模型，并抽取实际顶层串行化逻辑。
- `run_build.py`：依次调用 Efinity map、interface、pnr、pgm；这里 pgm 是生成 bit 的工具流程，不会执行板卡烧录。
- `check_build.py`、`review_warnings.py`、`register.py`：构建核查与既有登记流程。

这些历史脚本含 `C:/Users/34528/FPGAEdgeLinks/…` 与 `D:/大三/FPGA_verilog/…` 绝对路径，接手者必须先在工作副本中调整工具路径、报告输出路径和父基线引用。不要直接运行 `prepare.py`/`integrate.py` 覆盖当前已验证快照；它们是当时生成工程的历史步骤。Windows 原厂工具流程会移除 `PYTHONUTF8`，以使用系统编码解码子进程输出，相关失败与重跑日志保留在 reports。

构建后检查 setup/hold、警告变化、完整测试结果，再关联新 bit 的 SHA256；不能把原 bit 的成功报告套用于修改后的工程。项目规则入口仍为根目录 `AGENTS.md` 和 `_fpga_edge_agent/AGENTS.md`。原厂加密 IP 与工具许可由使用者本机环境提供。

历史 10 月 15 日恢复/DDR 诊断路线见 [旧交接](HANDOFF_2026-10-15.md)，只用于复盘旧自研版本的无图问题。
