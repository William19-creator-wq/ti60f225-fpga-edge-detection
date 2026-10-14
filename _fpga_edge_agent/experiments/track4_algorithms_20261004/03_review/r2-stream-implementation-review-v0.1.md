# R2 STREAM IMPLEMENTATION v0.1 独立设计审阅

2026-10-05；审阅者为独立只读子 Agent。本轮结论仅适用于本页绑定的当前流段及 OBS 软件实验范围；不是实现批准、仿真/综合/布局布线 PASS、硬件确认或完整十一项交付。

## 1. 结论与边界

**DESIGN_SCOPE_REVIEW_PASS_WITH_DOCUMENT_CORRECTIONS；全部当前实现与工具验证 NOT_IMPLEMENTED / NOT_RUN。** 实际全文核查当前 365 行设计与相邻 R2/C0/OBS/FILES 合同、实际共享 FE 源和 48 输入新基线后，没有发现需要把 RGB 重放、完整闭包、DDR、识别或生产摄像/HDMI纳入本实验才能消除的当前正确性阻塞。v0.1 的 F2 存在明确 I/O 求和错误，终态 flags 的同沿接线还须明确；本页 RC-01/RC-03 是 Root 形成 READY v1 前的具体文档修正条件。Root 可保全 v0.1 原字节，在新 v1 中落实这些修正及 A–L 阅读表、引用新基线与本评审，然后按唯一根规范完成 READY 自检和指定版本呈现。

本评审不把 v0.1 自行改为 READY，不修改旧 R2 的 B03/B05，不写入 Approval Manifest、正式状态或数据库。新 v1 的实际保存/全文读回/指定范围与基线绑定由 Root 完成，用户批准及本次审计前置按同一次具体对象处理。等待用户批准属于实施闸门，不是未完成的数学设计；未来真实工具结果也是获批后的通过条件，不要求先有 PASS 才能 READY。

审阅选择的范围是：完整 1920×1080 RGB 经原 FE 的灰度/可选中值，形成 Gaussian、新 Sobel、整数方向、双支 fork、NMS/class、启用时完整 grad；C0 保存真实原 FS 与八口账本；三类 typed608 记录、独立 CRC/J flags、可暂停 SRC、四 pin Ti60F225/I3 25MHz工程。class 仍不是最终 Canny edge；本工程不证明实时相机/HDMI60Hz、全帧闭包、识别质量或整包资源/DDR服务通过。

## 2. 实际读取对象和哈希

路径相对控制面 `_fpga_edge_agent/`，`r1/` 表示 `work/active/track4_algorithms_20261004/r1/`。以下“全文”均为本轮工具实际完整输出；FILES 首次输出中段被截后，已补读 L66–133，不以截断输出冒充全文。没有执行任何源文件、模型、TB、向量生成器或 EDA 工具。

| 对象 | 真实范围 | SHA256 |
|---|---|---|
| `planning/design-TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001-v0.1.md` | 全文 L1–365；62,197 B | `669D023A170D48C35FFAB7DEA983B6575F3E4A0E72037594076CAF78FC43A747` |
| `experiments/track4_algorithms_20261004/01_baseline/algorithm-r2-stream-baseline-v1.json` | 完整 JSON；48 实际路径逐项 bytes/hash 核查 | `F7CF4DF2F8CE8A5874C33E7B9DEA997A6A09BCF0C417282D7D6DD4DAE8A93E7E` |
| `planning/design-TRACK4-ALGORITHM-R2-001.md` v0.3 | 全文 L1–224 | `416213C0EE50A11FEE6BFE6AD76F38A718684CF2D388450A9618DE557A93A5A2` |
| `planning/design-TRACK4-ALGORITHM-R2-FILES-001.md` | 全文 L1–183，含补读 | `E782BF056218D6B95FDA424FEDABD57FCE2CE1CFF58F20156D67B06508F02842` |
| `experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md` | 全文 L1–259 | `5403B591E47300228C5D60A8D94FAF3A3984C6A3236790042C6AD266CF7C8844` |
| 同目录 `canny-observer-project-sketches-v0.1.md` | 全文 L1–186 | `12D0BBEE823279B097D348E5EDFED8F7BC53FE17596B902E002CA420B6111847` |
| `planning/design-TRACK4-FRONTEND-001.md` | L86–127；实际端口/FE错误及共享诊断合同 | `45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114` |
| `r1/rtl/frontend/frontend_frame_pair.sv` | 全文 L1–149 | `3B8022D4B6D540DB2B186D997AF710B439F704061A9BFA91BB21DF92336B9864` |
| `r1/rtl/frontend/window3x3_pair.sv` | 全文 L1–149 | `6E8B3B9D2CA22B93BFEFBE08D35CE96BB5B38530C5A1311472ECBD269AFD9321` |
| `r1/rtl/frontend/sobel_pair.sv` | 全文 L1–120 | `1BF1247EF68B5573DFA3E8C64191D090507B1C0ED10589EF24157E9366A740DD` |
| `r1/rtl/frontend/rgb_to_y_pair.sv` | 全文 L1–84 | `D98A5ADA8711B0920F7AB7CBE5CFF1DCB8B3BAA302A3A45F9407747353CE1C31` |
| `r1/rtl/frontend/median9_pair.sv` | 全文 L1–146 | `C9FB7D69F2BF286EA8AA707ECA2EC9D34A364658E9D100E338E92DE791ADDE8F` |
| `r1/rtl/frontend/line_store_pair.sv` | 全文 L1–33 | `5C9F41A260CC9792F4900DEBB96CD8FC9AAB7F0094C2BAC3A08D8D4BCC40E65F` |
| `r1/rtl/r1/reset_sync.sv` | 全文 L1–9 | `2E3BBDA931097E8E7FC0B67FFD87D677DB242B9D623FD6BEE6BED71637127FFE` |
| `r1/model/frontend_reference.py` | L1–143；只采用灰度/中值纯函数，不运行原 CLI | `4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A` |
| `r1/project/r1_algorithm.xml` | 全文；仅现有 schema/设备/语言来源 | `709F0B5E0001B66F076EAB3C7B11A2E65BD98A5AA46CBDC6EE273C96955E07FC` |
| `r1/project/r1_algorithm.peri.xml` | 全文；实际 IO 标准/GCLK/零实例 registry | `AC804C0D8032FB8134394A14A7DC903AB78A46119D9DFDE0AFE524FD7BD6A1C0` |
| `r1/project/r1_algorithm.sdc` | 全文；40ns/精确两 SR/静态 LED 例外 | `0F06ED5E8B4023837268E237E6C743DA964712EA3580E1C262C6B8711DE5E1D5` |

已在前一只读任务按入口有序实际读取控制 AGENTS、规则、运行提示、配置、正式状态/ledger、数据库说明与 Manifest；本轮同版本元数据在 48 项核查中全一致。唯一根规范本轮相关实际阅读为 L49–166、L437–534；工作流全文。板级来源仅关键词定向实读所选四 pin、电压、封装和来源冲突，未声称重新读原 PDF/全原理图。

## 3. 整体范围、文件与来源检查

| 检查 | 实际依据与结论 |
|---|---|
| 当前范围可隔离 | 新卡 A3 L73–86 明确 B03、完整 A4/R4、RC/DDR/LOAD-GRAD 和生产 R5 均 OUT_OF_SCOPE/OPEN；B/G仍要求当前生产尺寸完整输出与真实工具，未用未来缺口替当前流段基本职责 |
| 31 新文件 | C L119–149：13 个新 RTL/SV +3 model +2 runner +3 project =21 非 TB；10 个 TB；合31。没有隐含第四模型或未列生产 test harness |
| 20 物理 SV | 新13（包括 package）+共享 FE6+reset1=20；同物理文件只编译一次、多实例拥有独立历史/valid；原 RAM 仿真模型仅仿真编译，不入 Efinity 综合源码 |
| 共享 FE 不变 | 新卡 L113、D1及实际 FE 顶层：Y_ONLY=0/T0，原 FJ/FP/FO/FS保持；原 M/edge明确剥 edge2，原 FS163仅 C0 保存，不改原原因码 |
| newS 真实适配 | 实际 window L35/117–119确实使用输入 x/y/eof；新卡 D4 明确新增22bit受限 caller 游标与 marker 选择，而非假称共享源本来已经本地寻址 |
| 模型独立 | 共享 Python L54–83只给纯 gray/median；新 Gaussian二维25项、newS完整二维式、NMS直接原 M 图，与 RTL RAM ring/pending独立；CRC逐bit608与32步硬件网络独立 |
| 新基线角色 | 实际48/48 bytes/hash一致；当前治理明确 no_r2_approval，两个旧 JSON仅历史元数据，不递归宣称历史治理 hash 等于当前，也不继承 R1 授权/审计例外 |
| 不循环 hash | 新baseline不含待审卡或本评审本身，由Root另关联具体 READY 版本及审阅SHA；这是明确分离设计输入冻结与批准对象，不是遗漏业务源码。31新文件本来是未来批准后产物，当前不能预填假源码hash |

## 4. 数值、同fire错误与恢复

新卡 B/F和 R2 B/F 一致：Gaussian两个轴权重[1,4,6,4,1]、总256，仅末次(sum+128)>>8；sum≤65280、含舍入≤65408，可用 unsigned16。Sobel每 lane signed11 ±1020、L1≤1530，方向乘积先扩20，最大1020×1024=1044480；424边界/零/四象限与固定负正邻约定一致。NMS在原 M 上中心>负邻、≥正邻、>0且非框才保留，分类严格TH/TL，不把外框历史先清0。

真实 FE source L37–46/112–118 确认：bad FP仍是真实接受并增 in，数值路径不投坏组，原 FS code2/原坐标保留；原旧 FO fire仍计 out。C0 L87/102–114/172 保证外 FP和 FE FP同一事件、FS比较用旧计数+当沿真 fire、私有后缀随后旧 ABORT flush，而非用新错误组合撤销触发 fire。

新卡 D4 L191–195 的 caller q10/r11/done1只在实际G8 fire推进，窗口收到 canonical x=2q/y=r/三 marker，C0观察未改的raw metadata。raw odd/2047/提前EOF/错ID被同沿记录；错误沿原地址仍 q<D，下一旧ABORT周期禁使能/清后缀。stall不推进、cancel同沿旧 G8 fire照计、rst同沿fire0。真实共享window的assert范围/碰撞检查仍有效，不需要修改FE、窗口源或FS以通过MD测试。

生产 sourcefault：(floor(1080/2)×960)+2=518402真实RGB接受，定位stage1/lane0/x2/y540，原FS2、CS first5/mask bit5。OBS L72独立核SRC/原FS关联、各口拓扑、两支K账、EOF0和fixture_match1/complete_ok0，不把所有前缀固定为一个hex，也不抄CS计数作黄金。HD-F在同DUT真实CS/CRC结束后不reset，新的k128/130从头覆盖有效历史，恢复必须完整数值/CS0/CRC；全域rst则旧job无CS期待，与cancel不同。

DERR保持与empty顺序也相容：坏值D1接受计S口但不投D2；data_flush/start不清未消费错误，C0独立err_ready先消费再等全empty；旧held FJ遇cancel仍须接受后再真实取消。没有引入通过假FS/CS/done、force状态或改统计期望消除等待的路径。

## 5. 608记录、CRC与终态flags重点

记录宽度与位序闭合：2 type +592 CS +14零=608；CLASS高481零、GRAD高421零；统一side121与OBS CLASS/GRAD原位号一致。每旧K空只一ready，CS优先且不以P/EOF门控；rr只在真实data fire后转向另一支。错误data照记账/CRC，再sticky→J cancel，保持FEED/DRAIN接真CS，最后CRC/done后才ERROR。retain0支valid/pending/count/EOF0不等ready。

捕获e0不CRC；e1…e19依旧shift高32按bit31→0非反射poly04C11DB7、初FFFFFFFF、明确mod2^32；e19用新CRC并最终xorFFFFFFFF提交STATUS快照，下一J沿看注册done，下一capture最早e20。黄金使用真实仲裁record序逐bit算，不静态拼class图后grad图；完整数学仍逐坐标/两lane独立比较，CRC不能代数学结果证明。

**RC-01：Root READY v1应明确沿前组合终态候选和K的共存mask。** 当前新卡IF09 L170/E5 L231、OBS IF07 L57/C L72已经要求J检查flags在同一次CS fire交K锁定；这排除了“J在该沿NBA更新终态flags寄存器，K同沿读取旧寄存值”的实现。固定 J 端口 L181 没有 raw CLASS/GRAD valid，不能假设 J 已接线取得 typed 共存事实。在 v1 明示：接纳沿之前，J从当前稳定CS、已结账K87和J/SRC旧账得到 combinational terminal_fixture_match/terminal_complete_ok candidate；候选不参与CS ready。K从自己已有三typed口检查 STATUS 与 CLASS/GRAD valid 共存，对J的两候选作共存mask；发生共存仍接CS，但两最终有效flags锁0并记协议错。同一次CS fire，K锁最终两flags与CS592；不新增J外端口、不让K读取同沿新NBA flags寄存器、不借后续C0释放ctx重算。J若另保存候选诊断，不能将未mask候选冒充K的最终flags；终态之后依据K保存并提交的有效flags。e19提交只用K独立保存的CS/最终flags与新CRC。

这是已有同fire语义的可实施明确化，不是要求新增全局模块、第二CS owner或先跑仿真。v0.1正文原字节保全，由Root在v1落实；G中OBS-B/R、HD-F和TOP-HD应真实覆盖旗标锁定及之后C0端口变化不污染last。

**RC-02：Root v1宜给显式当前A–L索引表。** 新卡D/E/F已经提供数值、采样/fire、valid、保持、有限service、复位、配置、存储、身份、CDC边界及实现预算；R2 F/C0§9/OBS G的A–L表也全文可追。将当前D4 delta和四pin边界集中列出只是阅读明确化，不改变scope或增加实现审批前运行条件。

## 6. 有限套件、case和timeout核查

| 核查 | 算式/结论 |
|---|---|
| stream必需186 | G44+D49+F6+NW12+NC24+C021+MD24+HD4+HD-F2=186；HD-F每case两job不冒充新增case |
| observer必需44 | B14+R24+SRC4+TOP-S1+TOP-HD1=44；合230实际仿真case |
| 245评估记录 | 230+V12+P-FATAL3=245；故意fatal是失败监测探针，不能记普通算法PASS；子恢复/reset job另记录，不用case一行掩盖 |
| G44 | 2常量+9位置×4幅值36+ramp1+1920×5 ramp1+4 phase停顿=44；脉冲(1,1)对中心(3,2)权重4，30/31/32/33→120/124/128/132→0/0/1/1，反例不依角点clamp伪权重 |
| D49 | 10tuple×四符号40+9错误=49；W8/H5为D4/P20pair，已纠正24pair误数；DERR定位/held/恢复不同于数学方向通过 |
| NC24 | 四方向×六profile；两lane可用当前/下一数值，但两lane共享当前case同一TLTH快照，避免fixture给单个job两套阈值 |
| MD24 | 六raw变异×普通/held8/cancel/rst四schedule；禁止force时钟/ready/valid/C0账或终态；注入只在已列TB内raw metadata指定字段 |
| 四HD配置 | k0→median0/retain0/pattern0；k5→1/0/1；k10→0/1/2；k15→1/1/3，均TL0/TH64/fault0；生产各stage完整P，而非以小图代替 |
| 生产fault与恢复 | k64/66：fault1、median0、retain0/1；恢复k128/130 fault0、对应retain保持。真J生产k64序列未运行的覆盖边界已明示；由真top小图128配置+生产真实SRC fault组合核，不伪称真J生产fault已经测试 |
| SRC258 | P=(258/2)×258=33282；奇半幅129及x31/32/128/129/255/256覆盖，图样mod256仅源合同，不扩算法溢出 |

有限cycle政策从声明活动/驱动开始，U/MD/C0为8192+128D+128T；K正常R=P(1+retain)+1、fault保守2(P+1)+1，C=32768+128D+48R_limit+16P×job_count；TOP-S逐job求和并明确额外7job warmup/reset成本。单生产retain1代入为116277296cycles=4.65109184s模拟时间，与原约116.3M/4.65s一致；retain0为66510896cycles。6×5的D3/P15，正常retain0/1及fault每job分别34160/34880/34976沿；k0…127有32正常retain0、32正常retain1及64fault，逐job为4447744沿，再另加声明的额外reset成本，不把这些成本充实际成功job。墙钟单元15min、完整HD或两job HD-F 4h、模型/编译/物理各阶段具体deadline。它们是有限失败监测预算，不是已证明最大算法延迟/fps；未命中phase、超限、日志缺字段、比较量不足或工具非零均不能PASS，失败保留旧run。

连续retain1 CRC R=2073601，20R=41472020沿=1.6588808s@25MHz；retain0 R=1036801，20R=20736020沿=0.8294408s。所选48R另有启动/尾/有限停顿余量，但不得当时限证明。

**RC-03：F2 L259 的精确I/O求和必须在v1纠正。** 原稿列出20+36+36+48+49+40+104+33+48却写514，实际和为414B/pair；P1036800时每HD九文件为429235200B，八个不同生产job为3433881600B。原532915200/4263321600分别沿错误514多算；不是实测结果，也不能继续称精确账本正确。父Agent并行只读手算复核独立指出此项，本评审在其反馈后纠正了首次保存时照录原数的错误。原vectors6GB、其它日志/产物另10GB、启动前核16GB磁盘预算仍更保守，修正不降低预算、不缩图、不改被审v0.1原字节。内存真实峰值仍获批后测，主机容量不代FPGA RAM。

当前明确采用四OBS公式作生产HD场景，单元另外覆盖脉冲/有限扰动与方向边界；不能把这四图称为所有未来Canny/识别质量样本或已运行旧R2的全部远期图像分布。此边界不影响当前已声明有限实验的READY判断。

## 7. 四pin、资源与批准后物理条件

实际R1 project为Titanium/Ti60F225/I3/SV2009；peri J2的GPIOL_P_08为1A/1.8V GCLK，P13/GPIOR_27 BR3.3V key低有效/上拉来源，N14/GPIOR_21及P14/GPIOR_22 BR3.3V输出drive4；新scope不混其他板版或新增CSI/DDR/HDMI引脚。软件来源链与所选四pin一致，仍不是实物确认。

共享reset实际两级异步清0、同clk两沿释放、core只同步高rst；业务rst屏蔽fire，RAM不整片reset。40ns覆盖全部正常算法/RAM/CRC/同步链，KEY例外只有精确两`~FF|SR`且各恰一，stage1Q→stage2D及stage2→core正常计时；静态LED只有两个pad端例外，无虚拟0ns IO或CRC multicycle。新post-map端点漂移应失败查回，不接受空集合。

28RAM=FE8+G8+newS4+NMS8是未优化结构预算；≤22000XLR及DSP0是目标，不能由R1的3411/8RAM或608bit长度推已装得下。C0CS592、Kshift608、terminalCS592、lastCS592共2384bit是不同存活职责，不冒称全FF预算。允许FE Y_ONLY无用逻辑合法裁剪，但需真实分层容量/算法到CRC到pad扇出及必要全图数值证据，不能用keep/CRC非零证明数学保留。

批准后PHY必须报告真实Map/PT/PNR/STA、四球/bank/GCLK电气、必要算法有效路径、setup/hold/时钟与内部未约束检查、警告/原日志及同冻结源。全部必要功能及物理条件成功才bit，真实同run `.lbf`/periphery输入/bit/hex非空hash登记后停止。现装工具/许可慢或缺失属于真实执行失败，未经批准不安装/联网/换key/改vendor源或缩生产尺寸。

## 8. 交付状态与下一步

本页只读源、静态字段/数量/合同与基线核查，再新增指定评审Markdown；无业务源码、模型、TB、功能脚本、向量、仿真/编译/综合/PT/PNR/STA/bit、网络、数据库或硬件动作。旧输入与被审v0.1哈希必须保持，本页自身SHA在保存后外部读回报告，不构造自包含hash。

当前scope独立设计审阅在上述文档修正条件下通过。Root完成RC-01沿前candidate及K共存mask明确化、RC-03 I/O算术纠正、RC-02当前A–L阅读索引和指定新baseline/READY对象的实际读回后，可呈现用户进行一次具体批准；R1授权与本地审计例外不自动扩展到R2。获批后按新卡G3推进全部230+15评估、生产物理条件与真实产物；失败仍保原run。未来B03、完整闭包/识别/DDR服务和生产IO继续OPEN，人工理解与硬件观察不得由本评审代签。
