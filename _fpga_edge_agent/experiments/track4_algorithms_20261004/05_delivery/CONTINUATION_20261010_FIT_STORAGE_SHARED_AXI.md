# FIT存储/选择器优化和实际读仲裁进度

按持续“统计后自行进行，无需批准”授权推进，本轮继续先中文整体/局部语句草图、接口/组合检查、保存读回呈现，再冻结输入和写代码。本地审计例外沿用；正式DB/H0/state与硬件不改。五基础/六高阶、1080p、Ti60F225/I3、SC431HAI及原完整识别目标没有降低，完整目标ACTIVE。

## 本轮真正完成

两组独立版本各新增/适配六个业务/验证文件，不重复计原样复制的底层和数学模型。两版完整14517个原数学向量均PASS、真实vsim/audit退出0且无超时。每版与独立原R3对照51195951个沿，全公共622/585、真实子622/585/桥403、122639次局部192提交相同；4486 helper角点、37取消、35复位、5缓存和11/6/19完整状态覆盖通过。每版新增4014455次有效槽全192比较；共享版再有321333次真实PREPARE全406命令和计划控制比较。每版10个当前源/运行快照SHA重新核对。

两次当前Efinity MAP均真正结束、退出0、无超时；报告与网表原语计数相符，各13源快照相符。实际flow设备/选项和SDC检查相同：Ti60F225/I3、speed、retiming0、seq_opt0、100MHz目标；工程名称和路径不同。原两参考MAP为前轮已测基准，本轮重核其网表/报告SHA，没有虚构重新运行。

| 独立FIT版本 | LUT4 | ADD | FF | DSP48 | RAM10 |
|---|---:|---:|---:|---:|---:|
| 原R3基准 | 44405 | 3657 | 8357 | 2 | 0 |
| 局部算术v1 | 43501 | 2696 | 8357 | 2 | 0 |
| 定宽物理槽 | 37020 | 2696 | 7076 | 2 | 0 |
| 定宽槽+共用选择器 | 32794 | 2696 | 7076 | 2 | 1 |

定宽槽相对局部v1减少6481 LUT/1281 FF；共享再减少4226 LUT并增加1 RAM。相对原R3累计减少11611 LUT/961 ADD/1281 FF且增加1 RAM。槽存储实测1791个FF，计数只匹配原语实例行，不重复计算含cell属性的行；不同STATS父上下文预算仍需单独实测。

新增RAM是Efinity自动推断的常量MUX：实际EFX_RAM10 WCLK/WCLKE/WADDREN/WE固定0，RCLK=clk、RE/RADDREN=1、OUTPUT_REG=0、WRITE_MODE=READ_UNKNOWN，INIT存在。RTL没有新增同步ROM接口；该推断的实际网表节拍还未做原生动态验证，本版没有采用为生产已验证版本。不能用RTL全量PASS代替网表周期或PNR/STA。每次MAP的6 warning（3冗余信号、3小缓存逻辑映射）及全部原日志保留。

两个新登记软件产物分别124与126项，总250项均重新核验字节；原参考模块改过声明和LF/CRLF，只有规范化换行后相同，不能称原始字节只改module名。原HDK、安装和旧产物只读。

## 实际接口的新代码

AXI读仲裁草图v1已保存读回呈现，8输入冻结；一个RTL已生成。端0显示ID2/最多64拍、端1算法ID0/4拍，共用一个128bit AXI读口；显示/算法3:1机会公平、完整49位AR锁定保持、R按真实owner路由，错误RID/早晚LAST/无owner返回永久Q并保留占用；enable不清旧承诺。它不读取或伪造DDR物理模型。

这个新模块仍只有RTL，另外六份TB/独立参考/两脚本/工程文件、实际编译/仿真/综合尚未生成或执行；不能称读仲裁已通过。后续继续同一草图，无需新的逐版批准；若语义修改先修短卡。

## 阅读次序

1. planning/design-TRACK4-FIT-TYPED-SLOTS-001.md→work/active/track4_algorithms_20261004/fit_typed_slots/README.md→TS02/03/04→TB/数学→resource-map-comparison.json和两个实际runs。
2. planning/design-TRACK4-FIT-OPERAND-SHARE-001.md→fit_operand_shared/README.md→47来源码/operand_source/task/末尾406拼接→PREPARE对照→数学→MAP及自动RAM说明。
3. planning/design-TRACK4-AXI-READ-ARBITER-001.md→axi_read_arbiter2/rtl/axi_read_arbiter2.sv；设计中的后六计划文件尚未生成，测试NOT_RUN。

以上路径相对于控制面。282是累计自写业务/验证文件数，包含脚本/TB/工程，不是282个硬件模块或完成率。此轮13个新增，其中12个完成全量RTL测试及组件MAP，1个仲裁RTL尚未测。212个当前增量主文件SHA重新核对；另70个早期基础源没有在这轮全部重跑。

## 下一步及完整缺口

本轮所有启动工具已真正结束，无需恢复或重启。优先补共享FIT实际RAM网表等价与AXI读仲裁独立测试/实际MAP；把获实测的优化带入点集统计父上下文，再闭合读写仲裁/lookup权威/帧发布控制。

已有独立组件的资源不能直接升为整机共存证据。生产Source/result/OFFER/APPLY/FREEZE/RETIRE、真实RO lookup、AXI写仲裁和QoS、CSI CRC/末包错误/rx_close/活动C2、原任意旋转/短边缺失/遮挡/重叠/最多4目标识别、匹配DDR2Gb模型及PHY、一个生产top/总资源/FPS/板型引脚/时钟/CDC/PNR/STA/最终bit仍未完成。本轮未生成新bit，未做硬件动作；最终bit之后仍停止硬件步骤。
