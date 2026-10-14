# Active-HDL 安装与现有测试验证申请

日期：2026-10-03。用户要求检查已下载软件能否使用。安装包静态检查已完成，签名有效，文件大小与用户提供的官网下载页一致；尚未发现已安装的 Active-HDL，未开展许可签出或实际仿真。

- Request ID: `REQ-ACTIVEHDL-20261003`
- Tool: Aldec Active-HDL Windows x64 主程序
- Version: 下载页及文件名为 `17.0.291.10042`；安装器 ProductVersion/FileVersion 为 `17.0`，实际安装后的详细 build 待核实。
- Source: `D:\RF_PDF\三期\Active-HDL_17.0.291.10042_x64_main_setup.exe`；下载来源元数据为 `www.aldec.com`，独立 Authenticode 校验为 Valid，签名主体 Aldec Inc。
- Reason: 完成普通 RTL 与当前 Efinity 受保护 FIFO 模型的实际编译、展开、运行检查；仅检查下载文件不能证明仿真可用。
- Current capability gap: 常规卸载注册表、PATH、默认 Aldec 路径和 C/D 根/Program Files 目录中未发现安装；ALDEC_LICENSE_FILE/LM_LICENSE_FILE 环境变量未配置，所查 FLEXlm 注册表无 ALDEC_LICENSE_FILE。未据此推断用户从未获得许可邮件。
- Proposed installation path: `D:\Aldec\Active-HDL-17.0`，以安装器支持情况为准；如必须改到其他位置，先说明。
- Files and permissions: 写入上述程序目录、Windows 安装登记/卸载信息、快捷方式和安装器必要临时文件；可能要求 UAC 管理员确认。已有版本如被发现，先停止避免覆盖。
- Validation output: 仅在控制面 `work/active/active_hdl_20261003/` 创建编译库、日志及波形，在 `reports/audit/active_hdl_20261003/` 保存脱敏检查记录；原 RTL、testbench、Efinity 原语/IP及下载包只读。不生成新业务实现或可执行测试。
- Network destinations: 本申请不新增在线下载授权；先使用已下载包。许可若为远程服务器，须由用户确认合法来源及具体连接方式，不把凭据或服务器信息写入公开记录。
- Expected side effects: 主程序安装、注册表/卸载登记、快捷方式、临时文件；仿真时本地编译缓存/波形与许可临时签出归还。具体大小以安装器显示为准，当前D盘剩余约101.6 GiB，仅作空间快照，不作为厂商磁盘需求。
- Excluded actions: 不安装网页上仅标明 Efinity 2025.2.288.3 的独立库包；不降级 Efinity；不更改全局 PATH/许可环境变量；不安装许可服务器、驱动、额外依赖、插件/MCP；不强制重启，不操作硬件。安装器若强制要求额外组件/服务/在线下载，先记录并等待额外批准。
- License handling: 先确认用户是否已经收到许可证及本机保存位置/获取方式；不要求把许可证正文、密钥或密码发到聊天。需要持久许可配置时，单独说明具体变更；能使用进程级配置时优先使用。
- Rollback: 通过程序自身/Windows正式卸载入口卸载本次 Active-HDL；保留原包、既有 Efinity/ModelSim 和审计数据。共享组件、临时目录不盲删。若未实际安装则不进行卸载。
- Validation after use: 核实安装版本和CLI帮助 → 许可可用性 → 现有 `tb_env.v` 普通RTL测试及波形 → 现有 `fifo_tb.sv`/生成IP与本机 Efinity 模型的编译、展开、运行。检查通过标记、错误、超时及覆盖范围，不把程序启动、下载签名或一个FIFO样本的成功扩大成全部IP可用。
- Approval status: `PENDING`
- Human decision: 待用户对上述安装及既有测试范围明确批准。

## 既有测试复核与验收边界

以下是只读复核结果，尚未在 Active-HDL 中运行：

1. 普通 RTL：复用 `work/active/environment_probe_20260923/` 的 `led_water_display.v`、`LED_8bit_Test.v`、`tb_env.v`，仿真顶层 `tb_env`。必须正常结束、出现 `ENV_SMOKE_PASS`，且无 `ENV_FAIL_*` / `ENV_SMOKE_FAIL` 或工具错误。该样本只覆盖两次复位和首个 LED 图案，不覆盖完整流水灯循环；进程退出零不能单独作为通过证据。
2. 编译失败识别：复用 `work/active/environment_acceptance/20260923T090001Z_fifo_compile/intentional_syntax_error.v`，预期编译失败。该样本不属于业务功能开发，不修改原文件。
3. 受保护 IP：复用上述 FIFO 目录的 `smoke_fifo.sv`、`smoke_fifo_define.svh`、`fifo_tb.sv`，仿真顶层 `fifo_tb`。检查编译、展开、许可、运行、全部数据比较及正常结束。测试配置预期写入512次、读取256次；只有零错误、实际完成预期比较才可记录样本通过，不能仅检索一条 PASS。
4. FIFO 覆盖限制：测试台把 `rd_clk_i` 接到 `wr_clk`，不构成异步时钟验证；没有独立满空断言。当前受保护文件含 Aldec 接收者条目，仅证明保护封装包含该厂商，不证明 Active-HDL 17 实际可用。结果不外推到 DDR、CSI/MIPI 或全部 IP。
5. GUI与集成：波形显示、波形保存和 Efinity 调用分别记结果。Efinity 2026.1 随附 `doc/topics/efn-simulate-aldec.html` 及 `scripts/efx_run_sim.py` 有 Aldec 支持，但脚本只专门识别 Active-HDL 16；17会进入其他分支并关闭 GUI 参数。独立仿真通过后仍须另测集成，不能直接宣布整套环境通过。

历史目录内的 `msim.sh` 会删除旧输出，`modelsim.do` 含 ModelSim 专用选项，均不直接执行；不修改厂商集成脚本来绕过上述差异。新增脚本、RTL、testbench或工程修改如成为必要步骤，另行提交设计与范围，不由本申请默许。

## 包检查证据

- 文件大小：867350784 bytes，与截图下载页一致。
- SHA256：`a2f8d79b059cb5be98b3465cbd22d8a93786927bdbab3453c5ef9498ddbbf3f2`
- MD5：`3e5e3dd2f237753f8aae2a99a35d038d`；未取得网页 MD5 按钮的值，未宣称两者已比对。
- Authenticode：Valid；Aldec Inc，Sectigo 时间戳签名。
- 系统：Windows 11 家庭版 中文版，10.0.26200，64位；这不是厂商对该具体系统build的支持认证。
- 本次未执行安装器、FlexNetHostIDExe、数据库或硬件操作。

审批依据：`config/AGENTS.md` 的“任何下载、安装、升级……都必须先登记并等待批准”，以及 `config/APPROVAL_MANIFEST.yaml` 的 `install_or_upgrade_software` 条目。用户的检查请求授权本次调查，不用于取消该安装闸门。
