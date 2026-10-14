# 可选仿真工具申请（尚未批准）

状态：PENDING。仅登记，不下载、不安装。

2026-09-23 选型更新：本申请仅保留为普通 RTL 的可选辅助工具。当前受保护 IP 的主选方案转至 [SIMULATOR_SELECTION.md](SIMULATOR_SELECTION.md)，不以本申请代替 Questa/Aldec 的版本核对、许可获取及安装授权。

后续实测补充：当前Efinity FIFO8.1包含加密模型，旧ModelSim还存在语法/密钥兼容错误。因此本申请只解决普通RTL与波形的候选能力，不能保证厂商加密IP仿真，不能用安装Icarus作为整体环境验收成功的依据。

原因：现有 ModelSim SE 10.1c 无已确认的有效许可证，仿真不能启动。仍可继续查找/配置学校或单位提供的合法 ModelSim 许可。

备选：Icarus Verilog Windows x64，包名 `iverilog-v14-20260804-x64_setup.exe`，发布页列示25.7MB，包含GTKWave（包内具体版本待检查）。用途为RTL编译、执行测试台、导出/查看波形；Efinity厂商明确支持Icarus流程，但仍须用本机IP模型实测兼容。

- 来源与网络目标：https://bleyer.org/icarus/ ，Efinix文档列出的Windows分发站；项目官方：https://steveicarus.github.io/iverilog/usage/installation.html 。只获取这个版本，不自动升级。
- 拟安装目录：`D:\FPGA_tools\iverilog_20260804`（ASCII路径）；安装包和SHA256记录保存到控制面 `artifacts/staging/tool_downloads/`。
- 权限：优先用户级/无管理员；不改系统PATH、不装驱动、不装服务、不执行硬件下载。若安装器要求超出这些权限，停止说明。
- 副作用：工具目录和安装器卸载登记；可能有GTKWave依赖文件、快捷方式。尽可能关闭文件关联和全局PATH选项。
- 回滚：按安装器卸载登记卸载，或在确认没有登记副作用后清理专属目录；保留报告与下载哈希。
- 预计输出：iverilog/vvp/GTKWave可执行文件、库、测试编译物、VCD波形、运行日志、版本和SHA256清单。
- 验收：正确测试台必须通过；故意错误断言必须失败；VCD中时钟/复位/输出有实际跃迁；Efinity原语、存储及拟用IP另做兼容验证。不能用编译成功替代仿真成功。

授权依据：此前用户要求额外工具先声明再下载；本申请等待明确批准。没有把“搜索解决许可证”和“执行最小测试”视为下载安装新工具的授权。
