# FRAME-ACTORS 构建入口内部修正 C2

2026-10-10，FA08/FA-T5。actors_map_001 的 shell 实际 exit1：派生脚本把旧源码清单数量52全局替换为53时，同时把用户路径34528改成34538；仿真前提文件因错误路径不存在，未启动 Efinity MAP、未产生网表，也未修改RTL或任何已运行仿真快照。原工具输出记录到该attempt的控制观察报告，不能称为综合算法失败。

修正只改run_actors_map.ps1的taskRoot和toolRoot回到已验证的C:/Users/34528/FPGAEdgeLinks入口。53份sim源数量、56份MAP输入、先核查实际sim PASS/current SHA、独立快照/日志/超时/返回码及无硬件动作保持不变。中文步骤：使用实际已存在的工作根→读取small_002 suite-result→核查53份源→新attempt snapshot→官方Efinity map→读实际资源。该次错误没有活进程可继续，修正后选actors_map_002新attempt；仍在运行的min/HD仿真源不改。

类型和运行契约：PowerShell7纯字面路径，用户目录不参与源码数量替换；无RTL数值/接口/状态/时钟变化。追踪FA08→run_actors_map.taskRoot/toolRoot→FA-T5实际网表报告；下一步按既有自主软件授权执行，不改正式审批、数据库或硬件状态。
