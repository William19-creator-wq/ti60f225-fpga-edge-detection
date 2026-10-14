# FIT实际MAP网表：原生模型附加验证

阅读次序：inputs/native-design.md整体/字段/语句→source-binding-note.json真实网表来源与适配→model/prepare_gate_vectors.py固定选法→tb/tb_fit_native_mapped.sv公开原生监视器→原数学及独立audit→实际run。三个新/适配文件仅为验证，不新增生产模块。

输入23份冻结，运行17份快照。实际MAP网表原SHA 1CD3E8D9A207CE9E962BFA099E545E93BF50FD0ACEFC7099C7E8811F7CA354B3。deps/fit_core_mapped.v只在副本改唯一module名，并将GB18030/CRCRLF归一UTF8/LF；反向声明规范化文本等同原件，所有logic/port/instance/defparam/INIT不改，原登记网表保持。FF/LUT4/ADD/DSP48/RAM10五模型原字节复制当前Efinity2026.1；DSP48所需helper就在同文件，没有替代为理想模型、强制完成或关闭READ_UNKNOWN。

## 完成的真实检查

fit_native_001输入探针、准备、vlib/vlog/vopt、预期非零fatal探针、native_vsim和独立audit均结束。实际vsim/audit退出0、无超时；仿真报告0 error/0 warning。7200秒是预设上限，实际vsim约834秒，不把这个墙钟写作硬件处理时间。17份当前源与快照、23冻结输入及源字节重新核对相符。

选法：原full14517数据及原独立数学保持；全部小group定向181条，11个大(kind,label)组各取四个固定分布位置44条，总225，原顺序/原622身份不变。各kind11/12/13/14/15/17/18为48/44/20/37/30/23/23。selection.json保存所有源索引/SHA和范围；225附加网表检查没有替代或回写旧14517全量RTL结果。

真正整份网表的公开req_ready/rsp_valid/quiet及valid时完整585，在597564个core沿与当前RTL严格相同。监视在posedge后1ns等delta稳定，原接受/消费仍preedge，时钟40ns、无SDF。225数学、302接受/267消费/35reset作废守恒，原37cancel/35reset/5cache及所有父11/桥6/子19状态场景通过，独立数学逐req重算与事务账PASS。max_forming8234是本测试中最大成形周期，不是整机质量/速度界。

旧R3与当前RTL另外597564沿全值/私有/状态比较，1357次局部192、4486helper、45074有效槽全192及3691 PREPARE全406一致。这些私有检查属于RTL两侧，不能误称映射私有槽/所有未选输入验证；原生侧只验证公开功能/时间。

自动推断的常量MUX RAM已作为实际整份网表在这225及原协议场景中执行：W写使能0，RCLK clk、RE/RADDREN1、OUTPUT_REG0，实际defparam/INIT与READ_UNKNOWN原样。本附加范围下没有发现RAM引入公开节拍变化，不升级为全14517网表或物理时序证明。

## 复现、追踪和完整范围

scripts/run_fit_native.ps1 -RunId 新名字，在已安装Questa2024.1/Python运行；源/模型/基线漂移、非零退出或timeout即FAIL，旧run保留。准备器与数学脚本从运行快照执行，full源来自冻结inputs；本次原共享FIT及已登记包没有修改。

NM01→选择/源SHA→NMT1；NM02→监视器/实际public→NMT2/3/4；NM03→真实netlist/models/params→NMT5；runner/metric→NMT6源绑定、探针与终态。源码/草图/注释/测试已核对，理解验收待用户实际作答。

未执行SDF/PNR/STA/板级pins/CDC/实际DDR/camera/完整识别/整机共存/FPS/新bit；100MHz是此前MAP约束目标，不能由40ns原生功能仿真称达标。完整十一项和最终bit继续ACTIVE，正式DB/H0及硬件状态不改，生成最终bit后停止硬件步骤。
