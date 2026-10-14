# 桌面快捷方式修复记录

日期：2026-10-03。来源：用户反馈双击无法打开。

当前状态：第一次 cmd 启动方案经用户再次双击仍失败。现行快捷方式已改为系统 PowerShell 启动，详见本文末尾“第二次修复”。下文第一轮结果作为历史证据保留，不能作为当前桌面双击验收。

## 已确认原因与修复

原快捷方式的 TargetPath 在 Windows 解析后，从英文 Junction 路径变成了含中文的原始 D 盘路径。此前仅验证英文路径的版本查询，未验证双击快捷方式，因此原验收范围不足。

现将原生 `.lnk` 的目标设为系统 `cmd.exe`，参数仅直接启动现有英文别名下的 `vsim.exe -gui`。这使程序路径保留在参数文本中，不再被快捷方式的目标追踪还原。没有新建启动脚本、安装软件或修改仿真源码。命令窗口设置为最小化；不能保证所有子窗口完全无控制台显示。

另外，不带用户现有 MGLS_LICENSE_FILE 的诊断启动确实退出4。已向 Windows 广播读取现有环境配置的通知，没有修改任何持久环境变量值。后续成功测试只在测试进程中载入了现有用户配置，没有改动许可证。

## 实际验证

- 同样的命令调用格式执行版本查询：退出0，Questa 2024.1。
- 通过修正后的桌面 `.lnk` 启动：vsim PID124848，vish PID124712，路径均保持英文别名。
- 启动完成后读取到窗口标题 `Questa Sim-64 2024.1`，窗口句柄137520，Responding=True。未进行像素截图或 GUI 内容检查。
- 再次读回 `.lnk`：目标仍为 `C:\Windows\System32\cmd.exe`。
- 通过 COM Shell.Application 的一次启动探测使该次工具进程退出 -1073740791；随后改用 Start-Process 启动实际快捷方式成功。没有据此推断整个软件包的安全性。
- AppActivate 返回 False，未声称已将窗口置于前台；用户可通过任务栏切换。

直接桌面双击使用的是桌面进程环境；本轮成功探测使用了载入既有用户许可配置的测试进程。已请求用户再次双击确认，尚未以探测结果代替该反馈。

## 证据与回退

- 原快捷方式快照：`SHORTCUT_FAILURE_SNAPSHOT.json`。
- 原 `.lnk` 备份：`QuestaSim_before_fix_225425.lnk`（该版本已知存在启动故障）。
- 当前配置与窗口证据：`SHORTCUT_FIX_RESULT.json`。
- 不继承许可的失败诊断：`gui_probe_no_env_stderr.log`。
- 如需撤销本次修改，可将上述备份恢复到原桌面快捷方式位置；这会恢复已知有问题的入口。所有程序、工作目录及已有许可保持原样。

## 第二次修复：启动时读取已有用户许可环境

用户反馈第一次修复后仍无法双击打开。此前成功的 GUI 测试预先在测试父进程载入了用户许可变量，因此不能证明桌面启动环境有效。广播环境刷新通知也未解决用户实际问题。

现行桌面入口仍是 `C:\Users\34528\OneDrive\Desktop\QuestaSim 2024.1.lnk`。目标改为系统 Windows PowerShell，参数使用 `-NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -Command`。内联启动命令仅执行两项操作：读取现有用户级 `MGLS_LICENSE_FILE` 到本次启动进程；从原有 ASCII Junction 启动 `vsim.exe -gui`，显式使用正常可见窗口与原有工作目录。

这次修改确实增加了两条内联启动命令，属于用户要求的桌面入口修复；没有生成独立脚本文件。快捷方式中不保存许可路径或许可内容，不修改持久环境变量，不绕过执行策略，不运行安装器或补丁，不修改业务源码、测试或硬件。

### 本轮验证

- 子 Agent 对候选命令只做 PowerShell AST 解析：两条语句，零语法错误；没有读取许可值或启动程序。
- 真实启动前确认测试父进程没有 `MGLS_LICENSE_FILE`，且没有运行中的 Questa 实例。
- 通过 `Start-Process` 打开实际桌面 `.lnk`，没有在测试父进程注入许可变量；等待15秒后出现 `vish` PID119416 和 `vsim` PID127484。
- `vish` 主窗口标题为 `Questa Sim-64 2024.1`，句柄4593610，Responding=True。这证明本次自动化启动产生了响应中的主窗口；未做像素或界面内容检查。
- 启动后读回快捷方式，目标仍为系统 PowerShell，内联命令保留字面变量名，没有将许可值展开到参数中。
- 证据文件为 `SHORTCUT_ENV_FIX_RESULT.json`；第一轮 `SHORTCUT_FIX_RESULT.json` 仅保留为历史结果。
- 已请求用户关闭测试窗口并手动双击再次确认；当前用户双击结果为 PENDING，不能标记完全验收。

### 本轮回退与依赖

本轮备份为 `QuestaSim_before_env_fix_231123.lnk`。将其复制回原桌面快捷方式可恢复第一次 cmd 方案；该方案已知在用户环境下仍失败。原软件、现有许可与全局配置未变更。现行入口依赖已有用户许可配置和 LocalAppData 下两个 ASCII Junction 持续有效。

## 结束状态：手动入口尚未修复

用户确认第二轮以及临时诊断入口均仍未打开。Windows PowerShell 400/403事件确认用户点击确实启动了正确的命令，但未生成预期诊断日志；不能据此确定根因。进程事件订阅被系统拒绝访问，未提权或更改权限。独立自动启动可持续运行，且已通过 computer-use 真实截图确认 Questa 主菜单、库列表和命令提示符，因此此前 PixelInspection 未执行仅适用于第一轮。

用户通过物理 Escape 停止 Computer Use 后，已停止界面操作。清理时把桌面快捷方式从临时诊断版恢复为 QuestaSim_before_diagnostic.lnk 中的双语句 PowerShell 启动版；移除了临时多层 cmd 和日志重定向。该版本自动启动成功但用户手动双击失败，不能标记已修复。原软件、许可、全局环境及工程源码未更改。下一步需要继续定位 Explorer 手动启动与自动启动的差异；任务仍未完成。

## 可见启动诊断（2026-10-03 23:33）

用户询问下一步后继续只读调查，未操作电脑界面。现只把桌面原快捷方式的 `-WindowStyle Hidden` 改为 `-NoExit -WindowStyle Normal`，并把快捷方式窗口方式设为正常。两条实际启动命令保持不变；不自动启动测试，避免混入用户点击证据。

已读回确认 NoExit 存在、Hidden 已去除。配置证据在 VISIBLE_DIAGNOSTIC_CONFIG.json，备份为 QuestaSim_before_visible_diagnostic_233323.lnk。当前状态是 VISIBLE_DIAGNOSTIC_PENDING_USER，尚未修复或验收。下一步由用户双击入口，把留下的 PowerShell 窗口错误文字或截图提供回来；若窗口完全未出现，也需区分记录。恢复该备份即可撤销本轮诊断显示设置。

## 用户截图定位到 WorkingDirectory（2026-10-03 23:36）

用户提供可见启动窗口截图，明确显示 Start-Process 对 WorkingDirectory 抛出 DirectoryNotFoundException。该次启动在创建 Questa 进程之前失败，不能将此错误归因为 Questa 许可证。

原工作目录 QuestaWork 是 Junction，工具进程中 Test-Path 与 Directory.Exists 均返回真，fsutil确认目标为控制面 work/active/questa_desktop；用户交互进程却报告无效。两种上下文差异的底层原因仍未确定。

本次创建真实目录 C:\Users\34528\AppData\Local\FPGAEdgeLinks\QuestaGuiWork，并把原桌面.lnk的 WorkingDirectory 属性和内联 Start-Process 的对应参数都改成此真实ASCII目录。原工作目录、原Junction、程序目录及许可保持不变。此目录仅作为GUI启动工作目录；不把它视为业务RTL/C++修改路径的授权。

已读回确认目录存在且不是ReparsePoint、旧工作路径引用移除、NoExit可见诊断保持。证据见 WORKDIR_FIX_RESULT.json，备份为 QuestaSim_before_workdir_fix_233620.lnk。当前等待用户手动双击验证；未自动启动另一组GUI混入证据，不能标记完全修复。回退时可恢复该.lnk备份，保留新目录内任何已生成文件，不自动清理。

## 找到 AppData 路径重定向差异（2026-10-03 23:40）

用户在改为真实目录 QuestaGuiWork 后仍收到 WorkingDirectory 无效，Windows PowerShell 400事件证实这次启动已使用新目录，排除了仍点到旧参数的解释。

进一步只读检查发现，工具所见 C:\Users\34528\AppData\Local\FPGAEdgeLinks 对应文件实际同时出现在 C:\Users\34528\AppData\Local\Packages\OpenAI.Codex_2p2nqsd0c76g0\LocalCache\Local\FPGAEdgeLinks。两条路径下 QuestaGuiWork 的 fsutil File ID 均为 0x0000000000000000003a000000098751；两条程序入口 vsim.exe 的 File ID 均为 0x0000000000000000000200000012f0ec，创建时间也对应。这提供了工具进程的 AppData 文件访问被应用包重定向的直接证据。此前工具侧目录存在性检查不能证明普通桌面进程可用。

修正：在 C:\Users\34528\FPGAEdgeLinks 下创建程序 Junction Questa2024_1，仍指向原程序目录；创建真实目录 QuestaGuiWork 仅用于GUI启动。更新原桌面.lnk的执行程序参数、工作目录参数、WorkingDirectory属性和IconLocation，完全移除旧AppData\Local\FPGAEdgeLinks引用。不搬动、不复制安装软件；不修改许可、持久环境变量、安全策略、原工程或源码。旧应用缓存内入口保留，不自动删除。

证据见 SHARED_PATH_FIX_RESULT.json；备份为 QuestaSim_before_shared_path_fix_234022.lnk。已读回新路径存在且快捷方式使用一致路径，保留NoExit可见诊断。用户手动验证仍待反馈；尚未将此修正标记完全验收。

## 用户确认与长期英文入口（2026-10-03 至 10-04）

用户最新明确反馈“可以打开了”，并要求处理长期英文路径、先提交 FIFO 修正方案。该确认针对共享路径版桌面入口；此前各轮失败与待反馈条目保留为历史，不代表当前状态。

本轮沿用 `C:\Users\34528\FPGAEdgeLinks`，保留 Questa2024_1 程序 Junction 和真实 QuestaGuiWork 启动目录；新增 Work、Reports、Efinity2026_1 Junction，分别指向控制面工作副本、报告和现有 Efinity。没有复制/移动安装软件或原资料；避免 AppData 应用包路径重定向及临时盘符依赖。目标清单见 [LOCAL_TOOL_PATHS.json](../../../tools/LOCAL_TOOL_PATHS.json)。

撤去临时 NoExit，并隐藏启动用的 PowerShell；Questa 的 Start-Process 仍使用正常窗口。两条启动命令和既有进程级许可载入方式保持不变，无持久环境/许可修改。保存已确认可打开的诊断显示版 `QuestaSim_confirmed_visible_234750.lnk`，恢复该备份即可恢复诊断窗口而保持共享路径。最终隐藏启动器版本尚无第二次人工确认，本轮未另启动 GUI 混入用户反馈。

已检查英文别名目标与快捷方式；新英文入口的 vsim/vlog 版本查询均退出0、版本2024.1。未重启验证。路径指向原中文目录，部分工具可能解析回真实路径，仍须后续具体任务验证；不将别名建立视为所有工具兼容性通过。

后续 FIFO 方案保存在控制面 `planning/design-FIFO-SMOKE-001.md`；本轮没有生成该测试实现或运行仿真，也没有修改正式节点/数据库。状态为桌面用户确认通过、路径配置完成、FIFO等待指定方案批准、整体环境未验收。新路径只读检查证据见 `../fifo_design_20261003/configuration_checks.json`。
