# VF-Ti60F225 软件环境检查

检查日期：2026-09-23。实际根目录 `D:\大三\FPGA_verilog`；文字中另一写法 `D:\大三\FPGA\_verilog` 不存在。VF 是此次检查的参考平台，尚未被确认是用户实物。

**结论：可以进行资料审查、工程引用检查和 HDL 编译；尚不能宣称开发环境已全部就绪。** Efinity 依赖导入/CLI 参数解析通过，ModelSim 的实际仿真因许可环境失败，完整 Efinity 构建、器件/IP 兼容、硬件下载和观察均未验证。

## 本机实测

| 项目 | 发现与试跑 | 判定边界 |
|---|---|---|
| 主机 | Windows 11 家庭中文版 64位，10.0.26200；Ryzen 9 8940HX，16核32线程；约15.3GiB可见内存；检查初始可用约2.7GiB | 本机能力存在，但当时可用内存偏少；构建前重新检查 |
| 磁盘 | 检查初始 C 盘约187GiB、D盘约110GiB可用；最新快照见 host_inventory.json | 不把瞬时余量当固定保证 |
| MSVC | Visual C++ 2022 x64 Minimum/Additional Runtime 14.50.35719 | 满足本地 Efinity readme 列出的运行库种类；未等同完整构建通过 |
| Efinity | 已有解压包 2026.1.132，manifest build 2026-05-30；自带 Python 3.11.10 | 尚未确认用户正式使用的版本；没有新安装 |
| Efinity Python | 仅对测试子进程按 setup.bat 设置 PYTHONHOME/相关路径；PyQt6.QtCore 与器件数据库模块导入成功 | 无环境直接运行脚本曾缺少 encodings；不是重新安装 Python 的证据 |
| Efinity CLI | 只调用命令行参数解析函数，返回帮助成功 | 没启动完整入口、GUI、综合、布局布线、STA、bitgen，也没验证许可或器件数据库内容 |
| ModelSim | 发现离 PATH 的 SE-64 10.1c（2012.07）；版本查询正常 | 不能因 PATH 无 vsim 就判定未安装；与新 Efinity IP 模型兼容性未测 |
| VF LED 试跑 | 独立副本 vlib、vlog 退出0；包含原始 top、LED 模块和本地复位测试台 | 仅 HDL 编译成功；没有执行到行为断言 |
| 仿真启动 | vsim 退出4，`Unable to checkout a license` / `Invalid license environment` | 仿真阻断；需配置有效合法许可或以后批准替代工具，未绕过许可 |
| Python/Git | 系统 Python 3.14.6；Codex 自带3.12.14；Git 2.55.0.windows.3 | Efinity 继续使用自身3.11.10，避免混用依赖 |
| 下载器/UART | 本次匹配 FTDI/FT232/223/423、CH340/341、Efinix、相关 USB VID 未发现连接设备或匹配签名驱动记录 | 不代表驱动库必然未安装；未连接实物时无法验证下载链路 |
| PostgreSQL | 连接变量是否存在只记录布尔值，不输出凭据；PATH 未找到 psql/pg_dump；未连接数据库、未执行迁移 | 正式运行时尚未验收，不得降级到 SQLite 或伪造成功 |

精确路径与返回码见 [environment_probe.json](environment_probe.json)，仿真证据见 [simulation_probe.json](simulation_probe.json) 和 [simulation_vsim.txt](simulation_vsim.txt)，主机最新只读快照见 [host_inventory.json](host_inventory.json)。

Efinity 当前目录为：

```text
D:\大三\FPGA_verilog\efinity-2026.1.132-windows-x64.tar\efinity-2026.1.132-windows-x64\efinity\2026.1
```

ModelSim 目录为：

```text
D:\modelism_\modelsim\Modelsim 10.1c\Modelsim 10.1c\win64
```

`D:\2025.2` 是 AMD Vivado/Vitis 工具目录，不是 Efinity；里面的 Java、编译器不能直接认定为 Sapphire 软件环境。系统 PATH 未找到某工具与整机未安装是两回事。

## VF 参考工程检查

读取了 VF HDK 基础/图像示例的 31 个主工程 XML，逐项检查列出的 RTL、SDC、IP settings 路径，没有发现缺失引用。此检查没有覆盖每个目录中所有任意 XML，也不代表顶层、语法、IP版本、电压或时序通过。

LED 示例标记 2023.2.307.5.10；HDMI/AR0135 等多个示例标记 2023.1.150.3.11；另有 2022.2 工程。历史 `last_run_state=pass` 仅为旧输出元数据。当前 2026.1 是否兼容必须在工作副本中完整重编译；不复用旧网表作为当前验证。

选定示例器件为 Ti60F225，部分使用 C4 timing model；资料中板芯片标注 Ti60F225I3。需要核实器件等级与工具时序模型的对应关系，不能自动改名后宣称兼容。

Efinity 本地 setup.bat/脚本对非 ASCII 路径有警告，当前路径含中文。该警告不是已证实必然失败；正式构建建议使用经确认的 ASCII 工具与工作目录。现有路径和 HDK 没有移动、删除或重命名。

本地 readme 对 Ti60 推荐8GB（其说明含OS和线程配置）；当前剩余内存低于该数值。编译前应释放可用内存并据实选择线程数，不能仅看总内存16GB就判定资源充足。

## 资料覆盖与适用范围

用户指定的10个根目录 PDF 共308页已提取文字，保存页码和文件SHA256。赛题四基础/高阶页、相机 MIPI 表、板级框图和关键接口页做了图像复核。文字提取完成不等于每个图表、二进制文件和视频都逐项理解。

- [reading_ledger.json](pdf_evidence/reading_ledger.json)：10个PDF的路径、页数、SHA256及提取范围。
- [赛题四需求](../../../docs/requirements/TRACK4_REQUIREMENTS.md)：五类基础与六项高阶，含PDF页码。
- [硬件与TinyML证据](../../../docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md)：VF/V4、相机、屏幕、软件版本与未知项。
- [完整工作流](../../../docs/workflows/TRACK4_WORKFLOW.md)：环境、基础、高阶和提交的独立验收门。

## 下一步及停止点

1. 用户已确认实物尚未确定，当前继续以 VF 参考检查环境；实物确定后再核对板卡、相机、转接板、显示连接。VF 与 V4 的 DDR、Bank、时钟和下载器分开建档。
2. 解决 ModelSim 有效许可环境后重跑已有测试台；若选择其他仿真器，先提交具体工具申请再下载。仅版本查询成功不算修复。
3. 确认 Efinity 版本与 ASCII 工作位置；如需复制/安装到控制面外，先说明路径与影响。原始 HDK 始终保留。
4. 以独立 LED 工程完成首个获准的综合/布局布线/时序/产物验证，再由人下载观察；成功后推进 HDMI 彩条。
5. 正式 Agent 节点运行前补齐 PostgreSQL 和运行时验收。现有目录、Schema、文档和静态校验不代表数据库/审批强制拦截/恢复已实际部署。

本次只做本地检查、控制面文档更新和隔离 HDL 编译/仿真启动测试；没有下载、安装、升级、修改系统 PATH/注册表、连接外部数据库、运行 FPGA 构建或访问硬件。测试中的环境变量仅属于子进程。
