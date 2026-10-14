# ModelSim 许可证与版本兼容性排查

日期：2026-09-23。结论：**尚未修复；不能把环境标为成功。** 当前版本是 ModelSim SE-64 10.1c（2012.07），不是免费的 Starter Edition。

最新选型见[当前 IP 仿真器与合法许可](../tools/SIMULATOR_SELECTION.md)：主选通用 Siemens Questa，学校正式授权优先；备选 Aldec 官方评估。具体发行版及本机仿真仍待验收。旧10.1c即使补齐许可也不能据此通过当前FIFO兼容性验收。

## 本机证据

- 进程、用户、系统均未设置 `LM_LICENSE_FILE`、`MGLS_LICENSE_FILE`；没有发现对应的 FLEXlm 注册项。没有输出变量内容或许可证密钥。
- 安装目录（排除激活/破解工具目录）、`C:\flexlm`、`C:\MentorGraphics\Licensing` 的常规许可证文件检查没有找到对应候选。这不是全磁盘穷尽检查，也不能据此断言用户从未获得许可证。
- 原始 `vsim` 测试退出4，提示许可证环境无效；`vlog` 能编译普通 LED RTL 并不代表 `vsim` 有许可。
- 未指定产品的 `lmutil lmdiag` 默认命中了另一软件的本机许可服务；它的退出0不能作为 ModelSim 许可通过证据。未修改该服务、许可证、系统变量或注册表。
- 新增 Efinity FIFO 8.1 编译实测：10.1c 对参数化位宽转换语法报错，并报告 protected region 缺少合适密钥。**所以解决许可证与解决新 IP 兼容性是两件都要做的事。** 没有删除、解密或绕过厂商保护代码。

证据：[许可证诊断](../reports/audit/environment_acceptance/20260923T084403Z_license/license_diagnosis.json)、[FIFO 编译错误](../reports/audit/environment_acceptance/20260923T090001Z_fifo_compile/fifo_vlog.log)、[原始仿真错误](../reports/audit/environment_20260923/simulation_vsim.txt)。

## 官方说明与适用范围

1. 随本机 SE 10.1c 提供的 [ModelSim SE Installation and Licensing Guide](<D:/modelism_/modelsim/Modelsim 10.1c/Modelsim 10.1c/docs/pdfdocs/modelsim_se_install.pdf>) PDF 12–14 页要求设置 `LM_LICENSE_FILE` 或 `MGLS_LICENSE_FILE`；客户端使用管理员提供的端口和主机。手册说明该版本不能仅依赖许可注册项。
2. [Siemens 安装说明](https://support.sw.siemens.com/en-US/okba/KB000157383_EN_US/Batch-Mode-Install-and-Uninstall-of-Questa-on-Windows-and-Linux-Platforms/media/6f60b873-4feb-43bb-9607-bb954b99ea23.pdf) 区分新版本的 `SALT_LICENSE_SERVER` 与旧版本的 `MGLS_LICENSE_FILE`。不能把新 Questa 配置直接套给2012年的 ModelSim。
3. [Efinix 软件说明](https://www.efinixinc.com/products-efinity.html) 列出支持的仿真流程和免费 Efinity 许可；**Efinity 许可不等于 ModelSim 许可**。
4. [Efinity 安装指南 v4.1](https://www.efinixinc.com/docs/efinity-installation-v4.1.pdf) 用于当前2026环境；[Icarus 官方安装指南](https://steveicarus.github.io/iverilog/usage/installation.html) 和 [Windows 分发页](https://bleyer.org/icarus/) 用于备选工具核实。Icarus可用于普通RTL，但不能据Efinity一般支持声明推断所有加密IP均可仿真。

## 有正式许可证时的修复路径

1. 向学校/单位管理员确认覆盖的产品、版本、Verilog/SystemVerilog 功能、期限以及绑定要求。许可证文件、密码和密钥不发到聊天。
2. 按管理员提供的信息，在本机为测试进程设置正确变量，指向真实许可文件或 `端口@服务器`。不猜端口、不借用其他产品的服务器，也不把占位值写入系统环境。
3. 使用显式目标执行产品对应的许可诊断；浮动许可再检查服务器和厂商守护进程状态、DNS/VPN/端口及可用席位。只有存在有效目标时才做这些检查。
4. 从该进程运行普通RTL测试台：复位和输出断言通过、退出码0；故意失败的断言必须产生非0结果；生成可读的VCD/WLF波形。
5. 用当前 Efinity 的原语、FIFO/BRAM 和后续实际选用的 DDR/CSI IP 重跑兼容测试。若10.1c仍不支持，应使用获授权且与这些模型兼容的仿真器版本，或由厂商提供匹配模型。不能仅通过变更许可变量解决语法/加密格式问题。
6. 在测试成功后才考虑是否持久保存用户级配置，避免污染其他软件的许可环境。

## 没有对应许可时

可向学校/单位获取可用的 ModelSim/Questa 许可，或使用普通 RTL 的免费仿真器。备选 Icarus/GTKWave 已登记[工具申请](../tools/REQUEST_SIMULATOR_20260923.md)，尚未获准、没有下载。它不能被当作已经解决厂商加密 IP 仿真的完整替代品。任何新的商业仿真器或 Efinity 版本下载也必须另行声明并获准。

本机 `D:\2025.2` 虽有 Vivado/Vitis 目录，但本轮未找到 xvlog/xelab/xsim 可执行入口；没有把目录存在当成可用的替代仿真环境。
