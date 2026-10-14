# 角度和投影：实际代码阅读入口

2026-10-08；ANGLE v1.1已通过FAST批次批准，20份计划文件已生成。独立常数审核514分量/1024word通过；最终仿真angle_suite_003、物理angle_physical_003通过；bit/hex已生成，紧接本次文档更新登记至ALGORITHM-R3-ANGLE-20261008-v1。登记状态与文件哈希以对应artifact-manifest.json为准；未执行硬件操作。

整体次序：[原中文设计](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R3-ANGLE-001.md) → [622/585位字典](../rtl/angle_protocol_pkg.sv) → [数学小单元](../rtl/angle_math.sv) → [两同步ROM](../rtl/angle_rom.sv) → [唯一事务状态机](../rtl/angle_core.sv) → [真实来源/585bit观察](../rtl/angle_probe_top.sv) → [独立常数与线性角参考](../model/angle_reference.py) → [数值/协议测试](../tb/tb_angle_core.sv)。

core接纳后锁完整请求；CHECK按尺寸、版本/owner/kind、flags/target/padding、坐标/向量域、零向量顺序检查。PREP把向量折入上半平面，保留half；SELECT/三word读/两乘积/DECIDE二分；RECOVER保留θu10，再形成kind8的θ9或kind9的fullbin/sector，避免先截θu而破坏1024回绕。

另一支先读两word系数，在s17恢复交换/符号；投影先完整形成X2/Y2，两个全乘积恢复符号后相加，在绝对值域RNE，再核q/r域。kind16实际复用QUALIFY从已寄存C/S填value，再PACK，便于保证不在同沿读刚写的系数；外部96沿上界、数值和接口不变，属于内部语句组织细化。

rom_pending/rom_word_index和product_pending/product_destination表示真正预约，不能只看ROM或乘积数据存在。capture先结旧预约，新RE/start只预约下一目的。取消禁止新私有发出，旧返回仍capture并丢弃；PACK/HELD公开以后不能改写已经valid的结果。DROP_WAIT有有限旧返回，不等下游ready。共同复位清资格，不清ROM内容。

Machin/递推Taylor生成器与另一π恒等式/直接幂阶乘参考都用Fraction，无浮点sin/cos。两表各512行；绝对初始化路径明确，跨机器移植另需调整。软件验证、独立物理与整机帧率分别记录；本模块不判定识别成功。

AN01/05→协议/保持/取消/复位→AN-T07…10；AN02→ROM/折叠/二分/恢复→T01…04；AN03→s17系数/s30投影/RNE→T05/06；AN04→两ROM及证书→T01；AN07/08→三个TB、真实probe、工程/工具/登记→T11/12。后续结果用实际run补齐本页。

## 实际验证与 Efinity 操作

最终angle_suite_003：32,851数值场景，最慢结果形成77沿；26项取消、24项复位；ROM预约/返回/复位账与私有乘法账闭合；probe真实1,056请求/响应/585bit观察CRC核对。常数生成与独立参考分别使用不同π恒等式和不同Taylor组织，不使用浮点。

angle_physical_003：Map/Interface/Pnr/Sta/Bit全部退出0；Ti60F225/I3，25MHz，3,087 XLR、2 RAM10、2 DSP；setup34.210ns/hold0.035ns，内部无时钟/未约束/多时钟均0。44份命名setup/hold报告逐份有真实路径且slack非负，含两ROM地址/返回、DSP产品、投影符号/求和、二分数据及比较使能。映射RAM的40×256 INIT位逐word与两份512行.mem比较，1024word完全相同。

旧angle_physical_002仍保留：cross到lo/hi D查不到路径；实际数据D来自mid，cross控制CE，最终脚本分开检查，未将旧缺报告写成通过。RAM的无driver警告已通过实际初始化逐word核对；PREP的10→9窄化仅在合法目标385…511分支产生1…127，范围安全。真实不同参数仍应重新验证。

Efinity打开project/angle_probe.xml，确认Ti60F225/I3、angle_probe_top和两.mem路径。四pin实验配置：J2参考时钟1A1.8V GCLK、P13 key1_n、N14/P14 LED，BR3.3V输出4mA。查看flow/outflow下mapped网表、pinout、resource和timing，再看sta/outflow的分组报告。25MHz结果不能替代整机100MHz或HDMI74.25MHz证明。

Questa先看req/rsp fire及owner/ID，再看rom_pending/rom_word_index、product_pending/destination、state、lo/hi/mid、C/S、projection_sum/rounded_q；有取消时检查旧预约收尾和held不改变。复现scripts/run_angle_sim.ps1和run_angle_build.ps1须新RunId保留全部尝试。

[登记manifest](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R3-ANGLE-20261008-v1/artifact-manifest.json)关联本包20份source、完整仿真、44份物理路径与bit/hex。完整识别决策和全机共存性能仍待整合。