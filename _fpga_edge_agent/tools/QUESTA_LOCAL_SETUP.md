# Questa 本机英文路径

更新：2026-10-04（路径设置始于 10-03）。本次用户已确认桌面入口可以打开。以下是固定路径别名，不是重新安装或搬迁软件。

## 使用入口

桌面继续使用 `QuestaSim 2024.1`。原始程序、工作副本和报告的实际位置记录在 [LOCAL_TOOL_PATHS.json](LOCAL_TOOL_PATHS.json)，下列路径均为 ASCII。

| 用途 | 长期入口 | 性质 |
|---|---|---|
| Questa 2024.1 | `C:\Users\34528\FPGAEdgeLinks\Questa2024_1` | Junction，指向现有程序 |
| Efinity 2026.1 | `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1` | Junction，指向现有工具 |
| GUI 启动目录 | `C:\Users\34528\FPGAEdgeLinks\QuestaGuiWork` | 实体目录，仅作启动工作目录 |
| 工程工作副本 | `C:\Users\34528\FPGAEdgeLinks\Work` | Junction，指向控制面 `work/` |
| 报告 | `C:\Users\34528\FPGAEdgeLinks\Reports` | Junction，指向控制面 `reports/` |

以后获批的仿真从 `Work\active\<任务目录>` 运行，输出保留在对应任务内。不要把 GUI 启动目录当作任意业务修改的授权路径。打开既有任务时用其英文路径；本次 FIFO 新任务目录尚未创建，须等设计批准。

这些别名不依赖临时 Q:/R: 盘符，也不放在受到应用包重定向影响的 AppData 中。保留 D: 下的原工具目录和控制面目录；移动或删除目标会使别名失效。某些工具可能将别名解析回中文路径，所以仍需实际任务验证，不能仅凭目录存在就宣称所有 IP 均支持。

## 快捷方式与环境

桌面文件为 `C:\Users\34528\OneDrive\Desktop\QuestaSim 2024.1.lnk`。它调用系统 PowerShell，只在本次启动进程读取已有用户级 `MGLS_LICENSE_FILE`，然后启动英文入口下的 `win64\vsim.exe -gui`。快捷方式两处工作目录均为上表的 `QuestaGuiWork`。

本次已撤去临时 `-NoExit`，隐藏启动用的 PowerShell 窗口，Questa 主窗口仍使用正常显示方式。未修改持久环境变量、许可文件、软件程序、安全策略或驱动；不把许可值存入文档。`LOCAL_TOOL_PATHS.json` 是供人和 Agent 显式读取的登记表，不会自动配置应用程序，也不是自动加载的宿主规则。

## 已核实和未核实

- 用户已确认调整到共享英文路径后的桌面入口能打开；随后仅撤掉诊断显示设置，最终隐藏启动器版本尚无第二次人工确认。
- 已读回快捷方式、实体目录与各 Junction 的目标；通过新英文入口查询 `vsim`、`vlog` 均为 2024.1，退出码 0。
- 本轮没有再启动 GUI，没有生成 FIFO、编译或运行新仿真；没有重启电脑验证。
- 历史普通 RTL 仿真通过，FIFO 展开因端口配置不匹配失败。新任务见 [FIFO-SMOKE-001 v1.0](../planning/design-FIFO-SMOKE-001.md)，整体环境仍为 `NOT_ACCEPTED`。

## 回退与证据

已确认可打开、保留诊断窗口的快捷方式备份为 [QuestaSim_confirmed_visible_234750.lnk](../reports/audit/questa_desktop_20261003/QuestaSim_confirmed_visible_234750.lnk)。需要恢复诊断显示时，将该备份复制回原桌面快捷方式位置。它使用同一共享英文路径，不需要恢复已知失效的 AppData 入口。

所有历史路径、工具和资料均保留。后续如需撤销别名，先确认其为预期 Junction 且目标位于登记路径，再只移除别名本身；不要递归删除目标。GUI 工作目录可能含用户文件，不能随别名清理。审计历史见 [SHORTCUT_FIX_REPORT.md](../reports/audit/questa_desktop_20261003/SHORTCUT_FIX_REPORT.md)。
