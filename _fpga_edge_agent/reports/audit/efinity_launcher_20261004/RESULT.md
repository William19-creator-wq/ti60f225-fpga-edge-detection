# EFINITY-LAUNCH-001 v1.0 启动修复记录

日期：2026-10-04。用户在具体方案后回复“继续”，批准4文件修复与一次GUI试开；引用见 `implementation_approval.json`，不是数据库或Approval Manifest记录。

## 原因与实施

旧入口在R盘存在时直接退出2。实际R盘已经指向Work/active，和旧入口期待的工程根不同。因此旧入口尚未进入Efinity就停止了；该证据不涉及许可证或软件损坏判断。

手工修改仅包含：

1. `../../../OPEN_EFINITY.cmd` 改用已有 `C:\Users\34528\FPGAEdgeLinks\Efinity2026_1` 和 `Work\active\gui_led`；不创建、释放或依赖R盘；缺路径与启动失败保留可见提示及非零返回。
2. `../../../work/active/gui_led/user_dir.ini` 修改一处用户目录前缀。
3. `../../../work/active/gui_led/efinity_user/app.ini` 修改两处项目路径前缀，保留 `open_last_project=off`。
4. `../../../operations/EFINITY_GUI_QUICKSTART.md` 更新现行路径、实测范围、历史与回退说明。

以上文字路径均以控制面对应文件为准；备份按文件名存放在 `before/`。Efinity运行时另外写入自己的项目局部偏好（例如style.ini、pgm配置）及 `efinity_user/log/`，属于批准的GUI试开副作用，保留这些数据。未由Agent打开/保存工程、构建、仿真、下载或烧写。

## 实测与边界

| 检查 | 结果 | 实际证据 |
|---|---|---|
| T1 路径、映射、原setup | 通过 | 固定目录与目标存在；原厂setup SHA256不变；已有Q/R映射不变 |
| T2 局部配置 | 通过 | setup后覆盖局部INI；3处预定路径替换；自动恢复工程仍关闭；cmd为ASCII无BOM、CRLF |
| T3 单次GUI启动 | 通过，包括人工可见性确认 | 启动前无Efinity；PID 128336；标题 ` Efinity`；复查句柄8719860、Responding=True。首次初始化采样未响应，42秒内复查正常；用户随后回复“能看到主界面” |
| T4 失败和退出路径 | 只读审查通过 | 缺文件、环境缺失、pushd失败、非零启动返回均处理；动态故障注入及GUI关闭后的退出码未验证 |
| T5 差异与回退 | 通过 | 写前5项基线匹配；4份备份；61项工作包文件哈希保持不变；独立只读审查无实质问题 |

`trial_launch.json`记录单次启动；`trial_stdout.log`、`trial_stderr.log`为启动日志；`trial_process_observation.json`与`trial_process_recheck.json`分别记录首次与复查窗口状态。`verification.json`保存最终检查和修正文件哈希；各 `*.diff` 与备份提供可读回差异。

未采集窗口像素；实际可见性依据用户随后回复“能看到主界面”，记录在 `verification.json`。启动器等待本次GUI退出，不能把运行中的空退出码写成0；未将正常退出列作已验证。GUI可打开不代表编译、IP、外部仿真器、许可、数据库或硬件已经验收；这些状态未推进。

## 回退

先由用户关闭本次Efinity及附属工具，再将 `before/OPEN_EFINITY.cmd`、`before/user_dir.ini`、`before/app.ini`、`before/EFINITY_GUI_QUICKSTART.md` 复制回各自原位置。保留GUI生成的日志和用户数据，不删除或修改盘符、目录链接、源安装。恢复旧入口也会恢复原R占用故障。此次没有修改业务源码、业务测试、XML或约束，无需业务回滚。
