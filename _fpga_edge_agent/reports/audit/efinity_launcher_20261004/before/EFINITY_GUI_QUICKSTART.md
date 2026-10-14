# 本机 Efinity 打开与使用

2026-09-24：已用现有 Efinity 2026.1.132 启动 GUI，检查到 `Efinity` 主窗口进程且 `Responding=True`。没有执行本轮编译、仿真或硬件下载；整体环境仍未验收通过。

## 打开

在资源管理器中双击控制面根目录的 `OPEN_EFINITY.cmd`。它调用安装包自带的 `bin/setup.bat` 配置当前进程，并启动 `efinity.exe`。不安装软件，不改系统 PATH。

安装实际位置：`D:\大三\FPGA_verilog\efinity-2026.1.132-windows-x64.tar\efinity-2026.1.132-windows-x64\efinity\2026.1`。

为避开已实测的中文路径问题，启动器临时建立 `R:` → 工程根目录。`R:` 已被占用时直接停止，不覆盖。正常关闭 Efinity 后由启动器释放映射；如果手动启动时显示命令窗口，请不要提前关掉它，并先关闭 Efinity 的附属工具。不要同时运行另一套使用 `R:` 的环境验收脚本。

这是本机已验证启动及曾验证编译的路径规避方式，不是将安装文件迁移到了英文目录。厂商推荐的标准方案仍是纯 ASCII 安装和工作路径。

## 打开独立示例

在 Efinity 中选择 Open Project，输入：

`R:\_fpga_edge_agent\work\active\gui_led\LED_8bit_Test.xml`

实际工作目录为 `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\gui_led`，从此前成功构建的最小 LED 工作副本复制了9个源文件/配置文件，复制时 SHA256 全部一致，见其中 `copy_manifest.json`。不复制旧编译输出。GUI 副本的 XML 仍带来源工程的历史运行元数据，界面显示的历史 PASS 不算这次编译通过。

来源副本关闭了自动插入调试核，并将布局布线线程数设为2。Ti60F225/C4 是参考工程设置，不能代替实际板卡、速度等级和约束的确认。原始 HDK 与历史验收目录不作为 GUI 编辑目录。

## 基本操作

1. Project 栏双击 `.v` 文件查看代码；打开 `.sdc` 查看时钟约束。
2. Interface Designer 用于引脚、时钟和接口配置。当前仅查看参考设置，最终配置依赖实物确认。
3. Dashboard 的 Automated flow 模式可从综合阶段运行到流程结束；Manual flow 模式可逐阶段运行。各阶段图标和 Console 用于确认完成、警告和错误。
4. 构建结果通常写入当前工作目录的 `outflow`，检查本次日志、时序报告、资源报告和 `.bit/.hex`。Bitstream Generation 是生成文件，与 Programmer 向硬件下载不同。
5. 仿真另需可用的外部仿真器和测试台。Aldec 评估许可申请目前正在处理，尚未认定仿真可用。
6. 任何真实下载/烧写和硬件观察仍由人完成；本示例不构成上板授权或硬件通过证据。

## 来源

- [Efinity 官方安装指南](https://www.efinixinc.com/docs/efinity-installation-v4.1.pdf)，第9页：Windows 启动及 ASCII 路径要求。
- 本机帮助 `doc/topics/efn-run-flow-with-dashboard.html`：Automated/Manual flow。
- 本机帮助 `doc/topics/efn-project-pane.html`：Project 栏文件查看。
