# 显示原子交接：阅读、运行与证据

本单元自写11份文件：4 RTL、2 TB、1独立Python参考、2脚本、XML/SDC各1；依赖原样复制、文档与运行日志另计。它把六源三结果账本连接到真实独立视频域的换帧和冻结控制，尚不读取DDR像素、不发送TMDS。

按次序阅读：`planning/design-TRACK4-DISPLAY-HANDOFF-001.md` B整体→C职责/连线→D完整接口→E两域中文操作→F/G/H语言与验证→J1网表补充→本文件→RTL→TB/参考→runs。所有路径属于`D:\大三\FPGA_verilog\_fpga_edge_agent`，当前代码在`work\active\track4_algorithms_20261004\display_handoff`。

## 整体及局部的实际交接

core提交完整1137bit消息→request_link保持源数据并通过req/ack跨域→display_route在视频域保存请求→核完整owner942身份及描述符→合法候选等待带seq/scan/result/Origin/policy的真实row0资格→消隐VS上升切整包→response_link保持完整1207bit回复→core实际消费→视频收到transport ACK回idle→下一事务。

`display_handoff_pkg.sv`规定完整位序和状态，不缩短64bit身份。`atomic_mailbox.sv`用两个控制同步器及源holding；目的只在同步req资格下读取稳定整包。`display_route.sv`用IDLE/CHECK/WAIT_OFFER/CANCEL_DRAIN/WAIT_FREEZE/WAIT_RESUME/SEND_RESPONSE/WAIT_ACK表达业务，只有真实消隐VS更改active；`display_handoff.sv`拥有core in-flight、匹配取消、心跳/业务watchdog和永久隔离。中文注释定位DH01..08。

冻结次序：视频快照沿前实际active→snapshot hold→core先owner FREEZE建立源保留→匹配cause/完整身份COMMIT才放hold→必要时对同源新配置再OFFER→RESUME在VS生效→core owner RESUME。即使core还以为是A，画面已B时快照和pin都必须B。NO_ACTIVE可以绑定已有latest，或先commit规范零源、第一帧真正被owner pin后再绑定一次。COMMIT被取消仍保留hold，不允许越过未提交阶段直接RESUME。

取消是独立保持level，不等拥塞请求通道。未应用候选只有完整匹配的实际closed才返回CANCELED.closed1；错误OFFER返回closed0。换帧回复里的previous_result只通知旧对象进入退役，仍需真实IO/consumer闭合才owner RETIRE。测试用受控资格/闭合输入证明这些条件逻辑，没有把TB闭合信号当实际DDR证明。

共同safe_reset_n仅在平台确认全部旧访问停止后使用；不允许单端warm reset。时钟停/业务等不到row0/扫描编号耗尽/VS发生在DE中时隔离并保留义务；恢复时钟或迟到回复不会重新授予新请求。

## 当前软件结果

- 最新RTL：handoff_hd_003、handoff_small_002、handoff_scan_003、handoff_policymax_002、handoff_scanmax_002、handoff_seqmax_002。
- 邮箱：mailbox_1_002、mailbox_64_002、mailbox_1137_002、mailbox_1207_003；两种时钟速率/宽度，气泡、保持、停钟及共同复位。
- 实际MAP：handoff_map_001；网表回归handoff_postmap_001。包级接口/RTL与MAP冻结哈希相同，后续只增补TB/运行器的网表分支。
- 以上11次仿真共92个core请求/回复、22次真实视频域整包更换、189次owner命令，全部逐字段与独立参考核对。4种邮箱共接纳780/交付776条，4条在共同安全复位中明确作废；全部payload bit检查。
- scan_003复用实际1920×1080 timing，两个VS间为1,237,500个双像素周期，始终在DE外切换。TB pair周期13.468ns，间隔16.666650ms，近似74.25MHz/60Hz；未输出或核查实际屏幕像素。
- Ti60F225/I3 MAP：7328FF、6958LUT4、57ADD，RAM/SRL/DSP均0；实际网表原语核对与报告相符，warn/err无诊断。编译/展开/仿真0errors/0warnings。没有当前组件PNR/STA/bit、板级引脚或物理CDC证据。
- RTL fast TB用8192周期验证watchdog；实际MAP默认50500000周期。PostMap跳过两个加速超时场景，验证其余28事务及DE错误边界；不称默认0.505s超时已在网表动态测完。

## 操作草图

1. 先查看baseline-v1.1.json及上述suite-result/reference-audit；旧RunId不得覆盖。直接改源后旧证据不自动有效。
2. 在PowerShell调用已有pwsh运行器，生产几何回归参数是`-RunId 新名字`；小几何加`-Small`；真实扫描加`-FullScan`；三个边界分别`-Limit 1/2/3`。邮箱加`-Mailbox -MailboxWidth 1/64/1137/1207`，需要相反速率则`-SwapClocks`。
3. 运行脚本绝对路径为`C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\display_handoff\scripts\run_handoff_sim.ps1`，宿主pwsh为`C:\Users\34528\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe`。脚本创建独立runs目录、核冻结SHA、记录PID/argv/时限、先证实fatal返回非零再正常仿真，独立参考不过即失败。
4. 打开Efinity工程`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_handoff\project\display_handoff_component.xml`：器件Ti60F225、速度I3、顶层display_handoff，core100MHz/video约74.25MHz。此为component MAP工程，不能把大量业务端口直接当板卡IO约束。
5. 综合运行器同目录`run_handoff_map.ps1 -RunId 新MAP名字 -SimulationRun 已PASS且当前SHA相符的RTL run`。它冻结源码到run snapshot/flow，再调用现有Efinity --flow map，不执行下载。查看Map.result、map.rpt、res.csv、warn/err及实际map.v。
6. 网表回归加`-PostMap -MapRun handoff_map_001`，只允许生产几何和普通序列；替换DUT为冻结真实map.v及原样官方FF/LUT4/ADD模型，独立owner参考仍检查租约。当前冻结map与另一次MAP不同则明确拒绝。
7. 原始HDK、安装和已冻结staging保持只读；记录都留在控制面work/local JSONL，正式数据库与H0状态未改。没有硬件下载/观察操作。

下一步：实现真实三行bank/资格/关闭与行预取，接入同源渲染和TMDS；继续完整复杂识别、共享算术、总顶层资源/吞吐、真实DDR/CSI闭合、板级引脚/CDC/PNR/STA/最终bit。用户理解验收待实际作答；整个五基础六高阶目标继续ACTIVE。
