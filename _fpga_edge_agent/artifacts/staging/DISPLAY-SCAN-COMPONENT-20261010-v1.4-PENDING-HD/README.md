# 完整三银行扫描与真实帧交接（v1.4，HD验证进行中）

阅读从inputs/design-TRACK4-DISPLAY-SCAN-002.md的整体行为、模块和接口开始，再读E中文逐沿操作与F语言契约。J1补保存完整旧active身份；J2补结束观察；Q1/Q2定义真正错误RID的隔离检查。rtl三模块为实际scan调度、scope关闭握手和组合顶层；deps原样冻结已通过的owner/handoff/取数/native/消费者/renderer；tb不输入任何伪造prepared/closed。

当前10份自写业务/验证文件：3 RTL、2 TB、1独立Python参考、2工具运行器、XML/SDC各1。22份原样依赖，共32份源码/工程；最终baseline-v1.4共29冻结输入。正常运行器使用未改的baseline-v1.2（27输入），Q补充使用v1.4；两个批次的三个生产RTL完全相同，HD和MAP进行中也没有修改运行源。旧设计/旧baseline/失败001保留。

## 实际内部交接

真实owner建立OFFER及Source保留，核心control1137跨handoff到video候选。scan用一个寄存器481保持请求，三个银行FREE才创建；真实615成功与native543同时reserve。三个原消费者各自预读2个真实credit，真实首响应才prepared。实际VS消费全身份资格后active整体切换；当前完整FrameRef保存一份，切换沿先把旧值放两槽关闭队列，再锁新值。

每行首DE以全文479匹配银行并锁物理选择，随后每时钟双像素真实native pop，renderer按不可变112配置走S0/S1。正常行申请完成后优先下一扫描旧图repeat0，再候选0；候选迟到错过VS，旧票据不改，兑现已承诺的请求、真实discard/return后在新scan重申请。缺行/中途失败由原消费者黑屏规则处理，DE不回压。

video release不是银行FREE。实际核心消费Return545才推进GEN，把相同545经独立原子邮箱送video；全文吻合、owned0且consumer局部义务0才能消费通知并FREE，下一沿再分配。旧FrameRef没有未来任务、481、银行、读信用或尾部，才提交388={old标识,ref387}。

scope_fence把388送core，用真实prefetch查询、fetch运输与同身份Return通知ACK合并live；全0才old_closed387向父保持。父真正消费后388回应回video，关闭槽才能清。候选取消也走相同真实fence，完整closed反馈handoff后才能取消完成。未知错RID保Q及所有引用，绝不伪造closed。

## 当前实际验证

scan_small_002、scan_min_001、scan_w6_001、scan_w10_001四套实际Questa/独立参考均PASS：每套17个完整扫描及末个可检查前缀，六种mode均有完整实际active帧，8次真实VS切换、70 owner事务、7次实际oldClosed/RETIRE、1次候选错过VS、2次取消、20周期旧通知背压。真实freeze在视频已B但owner仍A时pin B，COMMIT/RESUME后旧active.policy保持不变。RGB48、全部同步/x/y/error、native54/GEN/fulltuple与实际return、owner租约、首行实际owned/head/两credit全检查。

scan_fault_001实际首R拍RID=3（期望2），Questa与独立行政审计PASS，原owner参考6事务PASS。组合/engine永久Q，真实source COMPLETE/result OFFERED引用保留、运输仍live，没有oldClosed或candidateClosed/控制回应。其unknown_io_closed=false是预期事实，不能误当排空通过。完整PID/参数/日志/26份源码快照保留。

scan_small_001 RTL18帧exit0，owner参考PASS，但结束日志漏最后transport下降导致独立scan FAIL；J2只修观察时刻，不改变任何关闭/像素判据。001源码/日志/二进制保留。初次scan_compile_001仅语法通过，19个数组输入默认类型提示；正式编译明确net输入0errors/0warnings，不以语法当动态证据。

scan_map_001实际Ti60F225/I3组合顶层MAP exit0：EFX_RAM10=19、FF=23324、LUT4=35502、ADD=835、DSP48=1、SRL8=0。它包括handoff、fetch、三native银行、三个消费者、renderer、scan/fence及Return运输；真实owner仍在联合TB，生产业务控制器另接。实际warn共26项：20冗余信号、4小cache/代次表逻辑映射、1个不使用的lookup_bundle[610]输入、1项post-synthesis汇总（132条未用输入/输出警告）；err只有工具头，未隐藏。31份MAP快照和四套112份仿真快照均匹配当前输入，无生产源码漂移。没有当前组件PNR/STA/bit/板级pin或物理CDC证据。

scan_hd_001正在执行，统一生产1920×1080、1100×1125时隙及全部上述正常/切换/取消/冻结场景；必须等真正finished、实际exit0与独立参考PASS后才记HD通过。工具会从运行开始的28份源副本编译并审计，每次RunId不可覆盖。运行命令在既有pwsh：run_scan_sim.ps1 -RunId 新名，-Minimum或-Width 6/10为参数边界，-HD为原生产分辨率；MAP入口run_scan_map.ps1 -RunId 新名 -SimulationRun 当前SHA匹配的PASS运行。故障TB由现有Questa逐stage运行，证据在scan_fault_001，不增加重复运行器。

## 边界与后续

Source输入是已完成数学byte-slave，ANN是码型，非真实摄像头/识别产物；lookup由实际owner保留状态的TB父提供，不是已完成生产控制器。理想AXI调度不证明DDR refresh/QoS。最终active保持持续显示对象及三个预读银行，停止在实际无AXI后，未声明这些引用已释放。完整扫描及末前缀数量以实际metrics为准。

HD、组合停钟后恢复/近最大值/布局后动态尚待相应证据，叶已有覆盖不能自动放大为本组合所有场景通过。生产Source/result/RO控制、真实DDR动态参数与仲裁、CSI CRC/晚错、原完整复杂识别、共享资源和单Ti60F225生产top/引脚/时钟/CDC/PNR/STA/最终bit继续原完整目标。35502 LUT只是本显示组合，不能据它声称加上Canny/识别仍装得下。用户理解验收待实际作答，软件自主继续及本地审计例外适用，正式PG/H0/硬件状态不改。
