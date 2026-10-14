# 本机 Efinity 打开与使用

2026-10-04：按已批准的 EFINITY-LAUNCH-001 v1.0 修正启动入口，使用已有的固定英文路径。一次试开检测到新的 `Efinity` 主窗口、非零窗口句柄且 `Responding=True`；首次采样仍在初始化，42秒内复查响应正常。随后用户回复“能看到主界面”，完成启动可见性确认。本次未执行编译、仿真或硬件下载；整体环境仍未验收通过。实测证据见 [验证记录](../reports/audit/efinity_launcher_20261004/verification.json) 及同目录 `trial_process_recheck.json`。

## 打开

在资源管理器中双击控制面根目录的 `OPEN_EFINITY.cmd`。它调用安装包自带的 `bin/setup.bat` 配置当前进程，并启动 `efinity.exe`。不安装软件，不改系统 PATH。

安装实际位置：`D:\大三\FPGA_verilog\efinity-2026.1.132-windows-x64.tar\efinity-2026.1.132-windows-x64\efinity\2026.1`。

当前使用已有的固定路径：

- 程序：`C:\Users\34528\FPGAEdgeLinks\Efinity2026_1`。
- 工作目录：`C:\Users\34528\FPGAEdgeLinks\Work\active\gui_led`。
- 局部偏好：上述工作目录内的 `user_dir.ini` 和 `efinity_user/`。

启动器不再依赖、建立或删除 R:，现有盘符映射保持原状。工具、工作目录或局部配置缺失时会显示具体错误并停止；它不会自动重建路径或覆盖配置。打开时保留命令窗口，先关闭 Efinity 及其附属工具，再关闭该窗口。不要删除或移动这些固定路径和它们所指向的原文件。

这些固定路径是本机现有目录链接，原安装文件没有迁移。此前临时R路径的编译记录不能证明本次固定路径的全部工具流程已经验收；后续编译、IP和仿真需各自按批准范围验证。厂商标准方案仍是纯 ASCII 安装和工作路径。

## 打开独立示例

在 Efinity 中选择 Open Project，输入：

`C:\Users\34528\FPGAEdgeLinks\Work\active\gui_led\LED_8bit_Test.xml`

保留 `open_last_project=off`，本次启动检查不会自动恢复工程。以下操作是使用说明，不代表本次已执行或批准构建。

实际工作目录为 `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\gui_led`，从此前成功构建的最小 LED 工作副本复制了9个源文件/配置文件，复制时 SHA256 全部一致，见其中 `copy_manifest.json`。不复制旧编译输出。GUI 副本的 XML 仍带来源工程的历史运行元数据，界面显示的历史 PASS 不算这次编译通过。

来源副本关闭了自动插入调试核，并将布局布线线程数设为2。Ti60F225/C4 是参考工程设置，不能代替实际板卡、速度等级和约束的确认。原始 HDK 与历史验收目录不作为 GUI 编辑目录。

## 基本操作

1. Project 栏双击 `.v` 文件查看代码；打开 `.sdc` 查看时钟约束。
2. Interface Designer 用于引脚、时钟和接口配置。当前仅查看参考设置，最终配置依赖实物确认。
3. Dashboard 的 Automated flow 模式可从综合阶段运行到流程结束；Manual flow 模式可逐阶段运行。各阶段图标和 Console 用于确认完成、警告和错误。
4. 构建结果通常写入当前工作目录的 `outflow`，检查本次日志、时序报告、资源报告和 `.bit/.hex`。Bitstream Generation 是生成文件，与 Programmer 向硬件下载不同。
5. 仿真另需可用的外部仿真器和测试台。本次GUI启动检查不验证仿真器许可、IP兼容性或待批FIFO测试；其状态分别查看对应任务记录。
6. 任何真实下载/烧写和硬件观察仍由人完成；本示例不构成上板授权或硬件通过证据。

## 历史与回退

2026-09-24 曾使用临时R映射启动GUI，检查到 `Efinity` 主窗口且 `Responding=True`；当时Aldec评估许可仍在申请。该日期的启动和许可状态属于历史记录。2026-10-04旧启动器因R已占用直接退出2，本次固定路径修复针对该故障。

本次备份位于 [审计目录](../reports/audit/efinity_launcher_20261004/) 的 `before/`：对应启动器、两项INI和本说明各一份。先关闭本次Efinity实例，再将备份恢复到原位置即可回退；保留GUI产生的用户数据，不删除盘符或目录链接。恢复旧启动器也会恢复旧R占用问题。批准范围与追踪见 [设计卡](../planning/design-EFINITY-LAUNCH-001.md)。

## 来源

- [Efinity 官方安装指南](https://www.efinixinc.com/docs/efinity-installation-v4.1.pdf)，第9页：Windows 启动及 ASCII 路径要求。
- 本机帮助 `doc/topics/efn-run-flow-with-dashboard.html`：Automated/Manual flow。
- 本机帮助 `doc/topics/efn-project-pane.html`：Project 栏文件查看。
