# R1 三个算术模块：实施入口与中文操作读回

2026-10-04；适用批准 AP-ALGORITHM-R1-20261004-v1.1。完整 R1 v1 的 SHA256 为 F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00，修订卡 v1.1 为 DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0；继承 FRONTEND v1（45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114）。本页在生成模块前保存，记录批准范围内的具体命名和操作映射。未改变公共行为、级数或数值规则。

阅读次序：R1 B/C 的整体作用→FRONTEND D 的两像素交接→本页共同流控→灰度三步→中值九步→Sobel 六步→对应源码与独立测试。边界复制由两个 window3x3_pair 承担，这三个模块只计算已经完整提供的两 lane 数据。

共同接口 clk/rst/frame_start/flush/in_valid/in_ready/out_valid/out_ready/empty 为单 core 上升沿域。rst 同步高有效；rst=1 时组合 in_ready/out_valid=0。flush/frame_start 仅在采样沿优先清空 valid，不组合屏蔽旧 ready/valid；这样错误触发的输入握手不会被 flush 反向取消，取消/错误沿已经交付的旧输出仍可计数。F0 对坏事务不向灰度投递。

`pipeline_advance` 表示末级为空或该沿将真实被接收。只有它为1才推进本模块全部算术、中心、坐标、标志和 valid；输入无效时首级插入气泡，其余旧级继续排空。它为0时全部阶段保持。rst/flush/frame_start 无论停顿均清 valid，数据位由 valid 隔离，不依赖逐位清零。`empty` 表示 valid 全0。输入在 e[k] 接受时，p级末结果在 e[k+p−1] 后有效，下游最早 e[k+p] 接受；气泡/停顿按实际推进事件计算。

两 lane 都是低位 lane0、高位 lane1；RGB 的每 lane 为 R高8/G中8/B低8。窗口每 lane 72bit，a…i 行优先，每项8bit，a低位/i高位。x_even/y各11bit是原图中心坐标，SOF/EOL/EOF与它们一起寄存。没有第二套 frame ID；F0 持有唯一当前 job 身份直到 status 消费。

## 灰度：rgb_to_y_pair

对应 FE-02、OP-02，测试 FT-01/06/11。稳定符号：`rgb_weighted_terms`、`gray_round`、`pipeline_advance`。

1. 一级先将R/G/B各扩为16bit，再用77=64+8+4+1、150=128+16+4+2、29=16+8+4+1形成三个移位加法项，范围19635/38250/7395。
2. 二级基于旧一级形成 R项+G项 和 B项+128，仍各16bit。
3. 三级把旧二级相加，取[15:8]输出每 lane Y。最大65408，小于65536；只有最后固定取位舍入，没有乘法器、除法器或饱和。

所有坐标/标志共三级；纯绿得到149，等通道RGB=q得到q。`out_y_pair` 是实际第三级寄存器，不连接当前RGB。

## 中值：median9_pair

对应 FE-03/05/06、OP-06，测试 FT-02/06/07/08/11。稳定符号：`row_order`、`median_candidates`、`center_bypass`。F0 供给整 job 稳定的 median_enable；第九级据这个稳定配置在中值与已经延迟九级的中心之间提交结果，输出停顿期间没有组合配置选择。

两 lane 各自执行以下19个8bit比较器。各级仅保存下一步确实使用的候选值；比较产生的min/max同属一个比较器，重复值保留原数值。

| 级 | 基于旧级的操作 | 每lane比较器 |
|---|---|---:|
| M1 | 三行各比较a/b，第三项同行传递 | 3 |
| M2 | 三行旧较大值与第三项比较交换 | 3 |
| M3 | 三行旧两较小值比较，得到L/M/H | 3 |
| M4 | L0/L1取max，H0/H1取min，M0/M1取min/max，第三行各项传递 | 3 |
| M5 | 与L2/H2合并形成A/C；中间分支取min(旧max,M2) | 3 |
| M6 | B=max(旧min,旧中间分支)，A/C传递 | 1 |
| M7 | A/B取min/max，C传递 | 1 |
| M8 | 旧max与C取min，旧min传递 | 1 |
| M9 | 余下两项取max，作为中值 | 1 |

中心e按九级传递。median_enable=0仍走全部九级；没有直接旁路窗口或降低延迟。独立参考用普通排序取第五项，不能复制网络作oracle。

## Sobel：sobel_pair

对应 FE-04/05/06、OP-07，测试 FT-03/06/07/08/11。稳定符号：`side_sums`、`signed_gradient`、`l1_magnitude`、`threshold_compare`。F0 给出整 job 稳定 output_kind/threshold。

1. S1形成(c+i)/(a+g)/(g+i)/(a+c)四组9bit角点和，与2f/2d/2h/2b四项9bit中间项；先扩9bit后加。
2. S2各角点和+中间项形成右/左/下/上10bit和，范围0…1020。
3. S3将每个侧和先零扩为11bit再解释为signed，相减得Gx/Gy，范围−1020…1020。
4. S4基于11bit有符号梯度取绝对值，得到10bit unsigned；合法输入不含−1024。原Gx/Gy继续寄存。
5. S5先把两个绝对值扩为11bit再相加，得到L1；真实联合上界1530。原梯度继续寄存。
6. S6寄存L1与严格L1>threshold的edge；kind0固定edge0，kind1应用比较。中心、梯度诊断、L1及全部伴随同时到达第六级。

`out_gx_pair/out_gy_pair` 各22bit，分别有两个11bit二补码 lane；整个22bit组不作为一个有符号数。`out_l1_pair` 两个11bit unsigned lane。诊断从S6寄存器输出，不能把S3/S5实时值接到挂起输出。

## 文件与验证状态

实现文件限定 rtl/frontend/rgb_to_y_pair.sv、median9_pair.sv、sobel_pair.sv。源码生成和本页读回后由本批统一仿真、综合及物理检查记录验证；不把文件存在、比较器计数或算术推导当作测试。core_precompile_001实际编译原厂EFX_RAM10与六核心，退出0/Errors0/Warnings0；r1_precompile_001对全12RTL的vlog/vopt通过。最终frontend_suite_006经Root独立验收123/123 PASS，四个完整1920×1080作业合比较8294400像素，数值和协议错误0；r1_shell_005的四258图样、两类小图外壳及CRC检查通过。r1_physical_005实际Map/Interface/Pnr退出0，40ns目标setup余量35.381ns、hold0.063ns，内部无时钟/未约束/多时钟均0，packed3411XLR/8RAM10/0DSP。主审核验release-gate后，bitgen_retry_001实际生成bit/hex；详细来源、失败保留和文件SHA见efinity-operation.md及runs/r1_physical_005记录。以上仅R1软件批次，不含实体验收或其余算法/生产接口实现。
