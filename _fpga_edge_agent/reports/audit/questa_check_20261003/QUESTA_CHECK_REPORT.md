# QuestaSim 2024.1 实际可用性检查

日期：2026-10-03。请求：检查用户已下载的 QuestaSim 是否可用。

## 结论

已实测可以进行普通 Verilog 编译、展开、批处理仿真、WLF 波形保存及 VCD 导出。条件是使用纯英文路径，并让测试进程继承本机已经配置的用户级许可环境变量。

Efinity 2026.1.132 / FIFO 8.1 的现有受保护源码编译通过；现有 FIFO 测试台与该 IP 的端口配置不一致，展开失败，尚未执行 FIFO 数据比较。本结果不能作为全部 FPGA/IP 环境验收通过。原项目状态未更新为 PASSED。

本报告记录功能实测。许可证来源、有效授权及整个下载包的安全性未验证；六个核心 EXE 的有效签名不能代表整包内其他文件。

## 检查对象和执行边界

- 程序目录：`D:\大三\FPGA_verilog\hbc_questasim\hbc_questasim\Siemens.Questa.Advanced.Simulator.2024.1.Win64-SSQ`。
- `vsim` 实际输出：`Questa Sim-64 vsim 2024.1 Simulator 2024.02 Feb 1 2024`。
- `vlog` 实际输出：`QuestaSim-64 vlog 2024.1 Compiler 2024.02 Feb 1 2024`。
- `vsim.exe`、`vlog.exe`、`vlib.exe`、`vmap.exe`、`vsimk.exe`、`questasim.exe` 的 Authenticode 校验均为 Valid，签名主体 Siemens Industry Software Inc.。哈希另存于本目录清单。
- 直接调用现有程序和既有测试；没有执行安装器、破解补丁或密钥生成器，没有新增或修改 RTL、testbench、功能脚本、厂商工具脚本、驱动、安全设置或全局环境变量。
- 输出仅保存在控制面 `work/active/questa_check_20261003/` 和本报告目录；原程序、原样本和历史测试结果未覆盖。
- 临时将 `Q:` 映射到程序目录、`R:` 映射到控制面 `work/active`。每次开始前确认盘符未占用，每次结束移除本次映射；未建立持久映射。
- PostgreSQL 未参与此次本地检查，未改变数据库配置或正式硬件节点状态。

## 两个实际环境问题

1. 中文路径启动失败：直接从原目录启动 `vsim`、`vlog`、`vlib`，均退出100，报告 `tcl.fs not found`、`TCL has not been initialized`。该文件实际存在。使用临时英文盘符后 `vsim` / `vlog` 版本查询退出0。`vlib` 不支持本次尝试的 `-version`，其后通过实际创建库确认可执行。
2. 运行进程未继承用户环境：当前进程最初没有 `MGLS_LICENSE_FILE`，LED 编译成功，仿真退出4，报告许可环境初始化失败。只读调查发现用户级已有该变量，指向现存本地文件；进程级和机器级未配置。仅在测试进程载入已有用户值后，LED 仿真成功。没有生成、更改或复制许可证，没有记录许可证正文、密钥或完整许可路径。

现有本地许可文件未检测到 SERVER / USE_SERVER 指令；此次没有配置外部许可服务器。未联网下载任何软件。

## 测试与证据

工作输出根为 `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\questa_check_20261003`。

| 项目 | 实际结果 | 证据位置（相对工作输出根） |
|---|---|---|
| 英文路径版本查询 | vsim / vlog 退出0，2024.1 | `ascii_version_probe.json` |
| 创建仿真库 | 退出0 | `plain_rtl/vlib.log`、`plain_rtl/result.json` |
| LED 三个 Verilog 文件编译 | 退出0，0错误、0警告 | `plain_rtl/vlog.log` |
| LED 首次仿真 | 退出4，许可环境缺失，未通过 | `plain_rtl/vsim.log`、`plain_rtl/result.json` |
| LED 继承已有用户配置后复测 | 退出0，81 ns，ENV_SMOKE_PASS，0错误 | `plain_rtl/vsim_user_config.log`、`plain_rtl/result_user_config.json` |
| 波形写入和读取 | WLF 可读取，27个信号，0–81 ns | `plain_rtl/tb_env_user_config.wlf`、`plain_rtl/wave_info.log` |
| 波形导出 | wlf2vcd 退出0，生成 VCD | `plain_rtl/tb_env_user_config.vcd`、`plain_rtl/wave_result.json` |
| 已有语法错误样本 | 按预期失败，退出2，vlog-13069 | `protected_fifo/negative_compile.log` |
| 受保护 FIFO 源码和测试台编译 | 退出0，0错误、0警告 | `protected_fifo/vlog.log` |
| FIFO 展开/仿真 | 退出12，端口不存在，未进入数据比较 | `protected_fifo/vsim.log`、`protected_fifo/result.json` |

LED 复测中的一个警告来自 `+acc` 降低优化程度；日志没有设计错误。许可环境变量的后续版本弃用提示不代表本次退出失败。

## FIFO 失败的源码依据

既有输入目录为 `work/active/environment_acceptance/20260923T090001Z_fifo_compile/`：

- `smoke_fifo_define.svh` 设置 `OPTIONAL_FLAGS=0`。
- `smoke_fifo.sv` 顶层没有 `rd_valid_o` 和 `almost_empty_o` 两个端口。
- `fifo_tb.sv` 第444行起的实例化仍在第453、455行连接这两个端口。
- Efinity 随附 `ipm/ip/efx_fifo_2/ipm/ip_component.xml` 第144–159行规定这两个端口仅在 `OPTIONAL_FLAGS==1` 时生成；该参数不是可用 `+define` 补上的预处理宏。原生成目录中的模型、测试台和 define 与当前样本哈希一致。
- 实际错误为 `vopt-2912`，分别指出上述两个端口不存在；不是此次受保护源码编译失败，也没有通过压制端口错误继续运行。

该项不通过。检查中未改变配置、补端口、修改测试台、添加替身模型或忽略错误。

即使后续修正端口匹配，当前测试台仍存在覆盖限制：第102行把读时钟绑定写时钟，不构成异步时钟验证；没有独立满空断言；应核对完整比较次数和全部错误，不能仅看到一条 PASS 就认可。预期写入512次、读取256次，当前实际比较次数为0。

## 尚未验证与后续边界

- GUI 交互、断点及 GUI 波形操作未验证；本次验证的是命令行波形生成、读取和导出。
- DDR、CSI/MIPI、完整参考工程、时序/SDF 仿真及 Efinity GUI 集成未验证。
- 未将程序搬迁到永久英文安装路径，也未创建持久启动脚本；临时盘符已经清理。
- 若继续修正 FIFO 样本，需要按项目 v0.2 规范形成指定版本的设计/变更卡并经批准，再修改工作副本；此次检查没有业务实现授权。
- 检查结论为“基础 RTL 工具链可用，当前 FIFO 测试失败且整套环境未验收”，不是硬件节点通过或整包安全认证。
