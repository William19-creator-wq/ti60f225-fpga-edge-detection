# 显示/算法AXI读仲裁：实际代码与操作

阅读次序：inputs/design-v1.md整体/接口→inputs/design-J1.md四态资格→inputs/design-J2.md双源压力扩展→rtl/axi_read_arbiter2.sv→tb全总线场景→model独立事件账→实际runs及resource-result.json。中文名称：AR为读地址承诺，R为返回拍，Q为失去可信归属后保留占用。

端0是display_span_axi的ID2/1..64拍；端1是axi_line_bridge的ID0/4拍，数据128位。一次只允许一个实际物理burst；显示/算法3:1指可用仲裁机会，不是时间期限。49位AR先锁定、保持至物理ARfire，上游ready恰在真实物理接受沿；R原128位数据/ID/RESP/LAST只路由唯一owner。disable只阻新选择，原AR/R承诺继续；错误RID/早晚LAST/无owner/请求违约永久Q且occupied保持，不能靠错误末拍、超时或业务disable回收。

## 当前真实证据

七份业务/验证文件已生成。read_arbiter_002完整26类场景通过，真实vsim/audit退出0，无超时；5792个沿的全49/135总线与独立事件账相符，181物理AR、2933完整128bit字、248 AR停顿沿、1479 R停顿沿、1次同AR沿早到R、26个非OK RESP、9个四态输入沿。两次双源压力的实际grant均严格0001重复8次；单显示完整1..64拍以及算法32个4拍burst。wrongRID、早/晚LAST、无owner、字段错误、上游body改变、valid=X和ID=X均按原首因Q保留；最后Q没有被伪称释放。

冷reset测试同时复位模拟DDR/客户端/核心，记录84个reset行、6个已有burst作废；这不代表真实板上暖reset排空已验证。输入源是受控协议slave及数学byte图，不是真实DDR动态模型。两个实际叶的端口和保持策略已读审相容，但尚未实例化联合测试，不能称真实leaf组合/显示期限/QoS通过。

read_arbiter_map_001真实Efinity MAP退出0，无超时，Ti60F225/I3/speed/retiming0/seq_opt0/100MHz目标；报告及网表计数一致：199 LUT4、72 FF、51 ADD、0 RAM/DSP/SRL。7个当前源/工程快照SHA相符。唯一warning为循环变量冗余，原日志保留。组件没有板级IO/PNR/STA/bit或新网表动态，100MHz只是约束目标。

## 失败历史和精确修订

read_arbiter_001原26场景逐沿/事件账没有发现不一致，但实际2457字未达到预设>2500覆盖下界，因此audit/suite FAIL。这条失败和原源码快照全部保留。J2扩展两个持续双源压力而未降低下界、删例或改RTL；当前2933字满足。J1在测试前修正未知valid及资格检测，初始未测RTL单独保留。

J2“runner不变”指业务编译/仿真/独立审核流程不变；新增J2冻结输入后，run_read_sim.ps1的行政输入数守卫确由9改10，实际SHA因此变化。J2文件影响表漏列这一行政守卫，本文纠正，冻结卡及旧run原字节不改，不声称runner字节不变。当前baseline v1.2共10冻结输入。

## 运行和后续

使用现有PowerShell执行scripts/run_read_sim.ps1 -RunId 新名字；全PASS后scripts/run_read_map.ps1 -RunId 另一新名字 -SimulationRun 仿真名字。旧尝试不覆盖，运行源在进程存活时不编辑。工具来自现有Questa2024.1和Efinity2026.1 ASCII路径，无新安装/网络/硬件动作。

RA01/03→pending/full49及输入资格→T1/3/4/5；RA02→display_credit→T2；RA04→owner/full135/remaining→T1/3/6；RA05→Q/首因/occupied→T5/6/7；TB/model/scripts/工程→T8源绑定和工具。正文/注释/实际口已核对；理解验收待用户实际作答。

后续接实际display_span_axi与axi_line_bridge联合验证，再接根DDR读写仲裁与帧/lookup控制。完整十一项/1080p/任意旋转及遮挡识别、真实DDR/CSI、整机资源和时序、最终bit仍ACTIVE，正式数据库/H0/state与硬件不改。
