# R2 流段 v1：代码与软件验收交付

2026-10-06。状态：**本批 R2 软件实验已完成，停止在 bit/hex 后**。用户批准 R2 流段 v1 与本批本地审计例外；批准设计和48份输入基线保持不变。完整五基础、六高阶的整机目标尚未完成。

## 已经做成什么

| 项目 | 实际结果 |
|---|---|
| 代码与文件 | 31份计划文件全部生成：13份R2 RTL、3份独立参考/向量模型、10份TB、2份运行脚本、3份工程/约束；复用7份R1 RTL，物理源码共20份 |
| 算法流段 | 灰度/可选中值→5×5高斯→新Sobel梯度→整数方向→双分支→NMS窗口→非极大值抑制/双阈值分类；C0控制，SRC/J/K/reset/LED软件实验顶层 |
| 仿真 | 230项不同必要case通过；135局部数值、21控制器、24真链metadata、4完整1080p模式、2完整1080p真实源故障/不复位恢复、38观察器、4图案源、TOP-S与TOP-HD |
| TOP-S | 真实J/SRC/K，128完整job，64正常与64真实源故障；另5个warmup完成、k5忙时KEY复位中止1job。累计134 start/FS，133 CS/CRC终态与source_stop，2次reset进入 |
| TOP-HD | 未覆盖默认参数的1920×1080顶层：七必要口各1,036,800组，GRAD关闭为0；1,036,800个NW窗口；1,036,801条608位记录；独立CRC ee1881f7，真实k1/START |
| RAM真实观察 | TOP-HD读使能29,043,840、写使能22,800,000、十二组银行检查248,902,008次；范围/同址读写碰撞错误0。结构仿真28 RAM10，固定Y_ONLY综合合法裁剪为26 |
| 输入/退出保护 | 12输入拒绝case、25子事件；3故意fatal探针实际非零退出且无成功JSON；不充当230普通case |
| Efinity | 2026.1.132，Ti60F225/I3；Map、Interface、PNR、独立已布线时序查询、Bit均实际退出0 |
| 资源 | 10,106 XLR/60,800（16.62%），26 RAM10/256（10.16%），DSP0；map为5,738 FF、6,228 LUT4、1,334 ADD、166 SRL8 |
| 时序 | 单时钟25MHz/40ns；setup余量29.956ns、hold余量0.030ns；内部未约束、无时钟、多时钟检查均0 |
| 产物 | 同run已布线LBF生成非空bit/hex，已复制校验并登记到staging；未下载、未实物观察、未更新正式数据库或硬件节点状态 |

230是不同case数；TOP-S的128job、fault恢复及reset前缀分别记账，未重复加进230。G2汇总明确区分实际计数、由完整逐位比较推得的EOF/事件，以及不存在接口的N/A；没有用空值补零宣称测量完成。

## 先整体，再局部的阅读次序

1. 看[模块连接、中文操作草图及语句组织](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/docs/module-code-reading.md)：先数据走向，再各模块职责/接口/局部步骤。
2. 看[生产实验顶层](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/rtl/r2/r2_algorithm_top.sv)与[canny_stream_top](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/rtl/r2/canny_stream_top.sv)：定位父连接、配置快照、原metadata送C0、局部RAM游标和各握手。
3. 按FE→G→新S→D→FK→NW→NC阅读，随后读C0/J/SRC/K。数值位宽及608/592/142等布局集中于r2_protocol_pkg.sv；独立二维数学与逐bitCRC参考在model目录，不镜像RTL状态机。
4. 各数值模块对应sim/r2中的同名单元TB，J/K/reset/LED由supervisor及TOP测试覆盖；先看正常/边界数值，再看stall、flush、reset与新身份恢复。C0使用组件fixture；MD/HD使用真算法链；OBS使用typed组件fixture，三者范围不同。
5. 最后读[完整G2证据](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/runs/g2-context-review-003.json)、[最终生成门槛](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/runs/r2_physical_002/release-gate.json)与[产物登记](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R2-20261006-v1/artifact-manifest.json)。由case_id可反查需求、fixture、实际结果、工具退出、源码快照和独立审计。

一条正常任务：J在CJ fire沿锁k和配置，同时SRC启动；C0的ARM/FJ先建立FE与私有窗口的上下文，FP仅在真实ready时交接。每级只按自己的接受/交付事件推进，停止时payload连同坐标/三ID/marker保持；Gaussian及新S/NW存储按本地有限游标寻址。NC输出两像素分类，可选GRAD分支各自只交付一次。K每次真实fire记录608位，capture沿后用19个32位chunk算CRC；真实CS592在数据收尾后捕获，最终chunk提交新CRC及终态，随后真实J沿进入下一k。坏源k64由真实in_bad/FS2结束，保留已交付前缀、CS5/mask32/原错误位置，CRC仍完整；恢复验证与reset中止另记，不能伪装完整帧。

## 软件运行与人工观察

- Efinity工程入口是[r2_algorithm.xml](D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/project/r2_algorithm.xml)。现有脚本已通过CLI执行，工程指定Ti60F225/I3、r2_algorithm_top、SV2009和默认1080p。四pin仅实验时钟/KEY/LED：J2/1A/1.8V时钟，P13 KEY与N14/P14 LED为BR/3.3V；LED drive4。具体证据在physical-audit与pinout/PT报告。
- 仿真脚本为scripts/run_r2_sim.ps1，参数RunId/Suite/CasePattern。RunId必须全新，禁止覆盖旧run。局部阅读可筛选U-G001；整包观察可筛选TOP-S001，生产默认观察筛选TOP-HD001。筛选运行始终标PARTIAL_PASS，最终230闭合由release-gate唯一case表核对。
- 现有运行器绑定本机ASCII junction、Questa/Efinity/Python及现有许可。staging/source保存38份精确代码副本供审计；运行器路径尚未做跨机器便携适配。原HDK、厂商RAM模型和R1共享源保持只读。
- 软件波形先看sim/r2/runs/r2_top_observed_small_002/TOP-S001/trace.wlf，再看r2_top_observed_hd_001/TOP-HD001/trace.wlf。关注chosen/dut的rst、job_start、CJ、valid/ready、J k/state、K busy/chunk_index/record_shift、真实CS、last_crc及LED。具体RAM/hold量由结果JSON直接观察，WLF没有记录全部RAM内容。
- 用户实际阅读理解验收仍待检验；工具运行与代码解释不代签人工理解或硬件现象。本次到bit/hex为止，不要求执行硬件步骤。

## 保留的失败与性能边界

新增TOP保持监视首轮在k64停源后错误延续上一沿候选义务，r2_top_observed_small_001保留exit1。修正为停源沿取消下一沿的FP held义务，生产RTL不改，r2_top_observed_small_002重跑全部128job通过。历史CRLF、参考RGB布局、缺观察权限和旧STA查询失败均保留在原run，当前验收使用修复后实际证据，没有删除失败或放宽比较。

TOP-HD实际20,741,840沿，0.8296736秒@25MHz，是可暂停规则源及每记录20沿的串行CRC实验结果；不是摄像头持续输入或HDMI显示帧率结论。该批证明流段在Ti60F225上可实现且这份40ns约束闭合；生产吞吐、DDR带宽/仲裁、缓冲、CDC及整机时序须后续整合验证。

## 整个赛题仍剩下什么

完整8邻域滞后连接、圆/任意旋转矩形识别数值与调度、板载DDR实际对象存储与通信、SC431HAI摄像头/HDMI/CDC、冻结与恢复、生产阈值控制、彩色叠加，以及全部功能整包的资源/性能与引脚时序闭合尚未完成。用户最新允许使用板卡现有DDR3；旧候选稿中的排除DDR或停止器件调查字样不能覆盖此授权。此次R2批准本身排除这些业务实现；接下来先在现有设计中闭合具体接口和中文草图，按有效项目规则提交明确设计版本/范围/基线，不重复索取本批R2许可。
