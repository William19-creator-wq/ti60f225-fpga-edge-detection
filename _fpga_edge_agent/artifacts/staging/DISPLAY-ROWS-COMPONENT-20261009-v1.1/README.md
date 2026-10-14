# 三行缓存：实际实现与运行次序

本单元有11份自写文件：4 RTL、2 TB、1独立参考、2脚本、XML/SDC各1。原样依赖7份及设计/规范输入另计。代码位于`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_rows`。

阅读顺序：planning/design-TRACK4-DISPLAY-ROWS-001.md的B整体→C连接→D接口→E中文操作→F语言→G/H追踪→J1/J2/J3验证观察修订→pkg/RAM/bank/rows3→两个TB及参考→当前runs及MAP。主设计是代码前已保存/读回版本，J卡及实际结果不覆盖旧输入和失败run。

## 先看整体，再看内部

父预取器取得合法结果租约→提交fill543→bank锁完整ticket并holding回复→父消费OK后顺序写960条54bit→全部写入且父io/producer实际闭合才publish→原子资格到视频→实际接纳row建立借用→native同步RE/pending/两holding→真正消费数据→无在途时release→原子return到core→父真正消费→下一沿FREE，generation递增/耗尽。三个bank分别容纳current/next/candidate，固定3个，没有第四个。

`display_row_pkg.sv`规定ticket543、return545及record格式；`row_ram54.sv`用3 stripe×2 depth原生RAM实现每bank54×1024，地址bit9选depth，低9是字地址；`display_row_bank.sv`拥有core状态FREE/CHECK/REPLY/FILL/PUBLISH/WAIT_RETURN/RETURN_LOCAL/Q，视频owned、issued/served、pending与两holding；`display_rows3.sv`只例化3个独立bank与通道。

ticket保留generation/sequence/scan/result/policy各64bit、Origin195、target/source行各11bit、mode3、mask3。pair54高到低为ann4/edge2/rgb48；lane0低位，每RGB24为R/G/B。mode0上下比较映射偶数source_y，其余1:1；mask按mode0所在半屏或mode1/2/3/4/5的001/001/010/011/111严格核对。

核心写错代/错顺序Q，不发WE、不假归还；不足记录或未知io/producer闭合不publish/abort。错误读返回零/error、不RE、不补完整数量；错误release只报下一周期错误脉冲，不释放owned。CONSUMED必须全部合法记录真正消费；DISCARDED可部分读，但RE pending及holding必须空。共同safe reset只用于父已实际停止所有旧访问时；RAM不清，用资格屏蔽旧内容。读时钟停止仍保留core busy，不允许写入重用。

## 当前真实证据与限制

- 6个当前PASS：rows_small_005、rows_hd_003、rows_min_003、rows_max_003、rows_join_small_002、rows_join_hd_002。
- 合计1,040,036次write接纳、1,037,132次read响应，其中12个明确错误读；3个已静止借用在安全共同复位作废，单独计数。HD独立行循环正常读取1080×960=1,036,800个双像素record，全部54bit与独立公式一致，等价2,073,600个正常像素记录。复位作废行不补正常读取数量。
- 三bank并发填/读/持有归还；连续读请求、两holding停顿/最后record、少一条记录、未知闭合、字段/代次、部分abort、错写Q、停视频钟及共同安全复位、64bit max不回绕已动态检查。
- 组合TB把实际完整row0资格接到handoff；错误scan先不切换，合法scan切A；B取消在真实native读response holding期间不能release/closed，消费最后record→row真实归还→core-to-video原子关闭票据→handoff才CANCELED.closed1，A保持。两种几何各2个完整填充行、1次native读取；这两个组合run不是两幅完整显示图像或真实DDR预取。
- rows_map_001实际Ti60F225/I3：18RAM10、5754FF、4964LUT4、249ADD、0SRL/DSP；18RAM与设计预算一致。MAP warning/error文件无诊断。当前业务RTL/pkg/project与MAP snapshot一致，后续只补TB/参考/runner验证分支。
- vlog有10条多维packed输入端口默认var提示（vlog-13314），保留原日志；展开/仿真0errors/0warnings，无latch/undriven/blackbox诊断。参考审计失败及TB超时/保留字编译失败均保留，不能把这些早期run算当前PASS。
- 本单元没有postMAP/PNR/STA/bit、物理CDC及板级引脚证据。父提供io/producer闭合是明确前置，不以TB信号声称真实DDR闭合；真实DDR fetch/QoS、scan controller、renderer/TMDS继续整合。

## 中文操作草图

1. 查看baseline-v1.1.json（12份冻结输入），先核当前源码与成功run的source-manifest；新RunId不能覆盖旧目录。原样安装/HDK/旧staging保持只读。
2. pwsh运行器为`C:\Users\34528\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\powershell\pwsh.exe`；脚本绝对路径为`C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\display_rows\scripts\run_rows_sim.ps1`。
3. 常规参数`-RunId 新名字`跑20×8/24行；`-HD`跑1920×1080/1080行；`-Minimum`跑4×2；`-NearMax`每bank从64bit最大代次完成一行后停止授予，验证无回绕。小几何只做边界回归，生产目标保持1080p。
4. `-Join`运行真实row/handoff组合；`-Join -HD`用生产行宽/高度字段。脚本独立vlib/vlog/vopt、fatal退出探针、正常vsim和Python参考；每阶段记录PID/argv/时限/日志与SHA，失败不写PASS。
5. 在Efinity打开`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\display_rows\project\display_rows_component.xml`，器件Ti60F225/I3、顶层display_rows3，core100MHz/video约74.25MHz。此为component MAP，业务通道不是板卡引脚。
6. 同目录`run_rows_map.ps1 -RunId 新名字 -SimulationRun 当前已PASS的leaf run`冻结实际源/工程，再调用现有Efinity map；看Map.result、map.rpt、res.csv、warn/err和实际map.v。当前MAP尚未跑布局或生成新bit。
7. 保存本地审计与staging，正式PostgreSQL/H0状态不改，没有硬件操作。用户已授权继续，后续设计仍先形成中文草图/读回，再生成和验证。

下一步完成真实RGB/EDGE/ANN行预取/返回解析与scan调度，把输入闭合资格交给实际服务提供；再接渲染/TMDS、复杂识别共享算术及总top资源/吞吐/pins/clocks/CDC/PNR/STA/最终bit。整个五基础六高阶目标保持ACTIVE，理解验收待实际作答。
