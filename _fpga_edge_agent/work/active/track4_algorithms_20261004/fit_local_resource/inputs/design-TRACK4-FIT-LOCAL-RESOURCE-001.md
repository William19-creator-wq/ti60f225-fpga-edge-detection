# FIT局部宽整数资源优化 v1

- Goal：推进原五基础/六高阶/1080p在Ti60F225/I3共存，压缩真实几何FIT占用，不缩小数值域或识别范围。
- Current state：STATS独立实物构建52619 XLR，显示组合35502 LUT+Canny27109 LUT尚未证明能合并。原FIT已有唯一串行算术核及逻辑槽宽度压缩；实际work_slot FF共1791位，不是源声明3072位，不再重写存储。
- Target state：相同622/585接口、七类FIT数值/错误/取消/复位/缓存和逐沿时序；只把已canonical槽的局部取负及边界运算缩到有证明的宽度，然后显式还原192位。
- Gap：当前实际网表含多份193位unary_minus/sub和line边界运算，未由重复sign位自动缩小。
- Assumptions：所有有效槽先经过原fits_return/fits_slot与canonical_slot；未valid不使用。原非法消息/缺槽仍同首因拒绝，不能依赖异常输入不发生而放宽公共校验。
- Open questions：本当前局部数值与接口无未知；最终FPGA总资源/FPS/PNR/STA/bit另继续，不能从一个压缩实验证明整包已装下。
- Dependencies：下列真实9输入，FIT r3/r4源码SHA逐项完全一致；现有Questa/Efinity/Python，不安装或联网。
- Milestones：整体/接口/中文局部草图→READY读回呈现→独立work/fit_local_resource→同输入旧/新逐沿与独立数学→同器件/设置两次MAP→实测差值登记。
- Detailed steps：保持原数值资格/状态/槽写入，只新增内部定宽helper与替换对应局部表达式；TB复用原完整场景并新增旧实例每沿比较，原数学/向量不改。
- State transitions：READY_FOR_REVIEW v1；用户“统计后自行进行，无需批准”及本地审计例外持续覆盖软件实现；不是伪造逐版新批准或正式Manifest/PG状态。
- Artifacts and hashes：6份自写/适配文件（RTL/TB/两个运行器/XML/SDC）；4原样RTL+2原样数学脚本+1只改module名的旧RTL参考，共13源/工程。10冻结输入（下面9+本设计）。旧参考仅module fit_core→fit_core_original改名以同时展开，不计新增功能核，不在生产MAP里共存。
- Validation：旧/新req_ready/rsp_valid/quiet与真实622/585/子请求/子返回/合法局部提交逐沿相同，原独立大整数七类数学与非法/取消/reset/cache参考继续；同条件旧/新实际MAP定量，阶段不冒充时序通过。
- Failure handling：若不能保持全值或时序等价，修复实现；不得改旧核、独立参考、种子或容差。若资源不减少，记录结果并重新选择优化，不声称节省。
- Human approval gates：软件自主/本地例外，不变正式DB/H0，无PNR/bit/硬件操作。
- Rollback：全新work副本，不改原HDK、r3/r4/正在运行的display_scan、已登记staging。
- Completion criteria：本局部等价/真实MAP差值，原完整项目继续ACTIVE。

## A 基线与阅读

先B整体外部不变→C/D模块及相容接口→E中文定宽操作→F语法时间→G/H验证追踪，再看实现。源SHA：

- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r4_stats\rtl\fit_core.sv` `0072A6B007B93955CFBFE932A55E258935D636C806E54A3572D153EC08034BF7`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r4_stats\rtl\scalar_core.sv` `DAA31292536F4860C23DE5CFAF73AC444CD18B2AB5E9D2ED9C9B8092217EA0F0`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r4_stats\rtl\scalar_bridge.sv` `795E4C03C08A422B1C155E725299C33F2A71ED78DC9C8F1AE8BDEB1499E8BEA5`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r4_stats\rtl\fit_protocol_pkg.sv` `5A08A84E9EA6DBEC93A91CE3234A200CD18E860A943701011832C60CFF941A9D`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r4_stats\rtl\scalar_protocol_pkg.sv` `40D7FC511C4E481B0B194A2B31D53C18627EC7D420A5B54E17C438E5832D3028`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r3_fit\tb\tb_fit_core.sv` `78A23AA78D2973E172633E5B7C9BA545BC46AE7BD0D795EBC1A614661FA28725`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r3_fit\model\fit_reference.py` `19BA4A274A059FBC6D760808553CD84149CA24A262E1EFB100BAD72739CF4EA5`
- `D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_algorithms_20261004\r3_fit\model\fit_vectors.py` `FC1E13849054D14FBF27417341729DD08DC647A6C7E4CBE51BE0CF1C7EFF4CF8`
- `D:\大三\FPGA_verilog\AI_Agent_代码可理解性规范_增补提案_v0.2.md` `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`

本文件保存读回后复制冻结，原fit_core作为inputs/original-fit_core.sv保存字节；deps/fit_core_original.sv仅声明名适配，其余字节与原始一致。

## B 整体行为及样例

FR01：原FIT kinds11/12/13/14/15/17/18全部保留，622请求valid&&ready接受、585终态holding到真实ready；ID176、W/H、版本/错误/round-nearest-even完全相同。原门槛/超界/负零/退化/缓存不改。
FR02：任何有效canonical槽s的实际数学值v，完整192展开表示等于s位低部和一位符号高部；new局部结果必须与原192表达式全位相同，不能只比最终18/32/65位。same cycle不新增等待或流水。
FR03：所有原共享scalar调用/目的/保留/取消/响应/quiet逐沿相同。局部优化不得撤已published消息、提前消费、改变首因/合法/非法返回。
FR04：比较实际旧/新MAP原语数，使用相同Ti60F225/I3、speed/retiming0/seq_opt0和100MHz组件约束；未执行PNR/STA/bit，不报告实现Fmax达标或全系统共存。

普通例：槽11为canonical signed32（slot最大32）v=-2147483648，局部取负必须成为完整192的+2147483648，随后原32signed目标仍拒绝溢出，不能窄32后仍负。边界例：槽0最大67，v=-2^67时先用69位（多一位幅度裕量）取负，得到+2^67，再扩192，和原完整192相同。无valid槽结果可以是X，但原required_slots先抑制提交，不利用X制造正常结果。

## C/D 模块、接口和组合

M1 fit_core局部helper；其余state/canonical_slot/slot_valid/ScalarBridge/ScalarCore原样。外部IF1 req622、rsp585、cancel176/quiet无新口，无有损转换。内部IF2局部192→原plan_local/command operand192；IF3原406 scalar命令→Bridge622→Scalar585→Bridge403全位序不变，不能收窄到低部再作fits检查。M2独立TB包含旧命名参考和新DUT共时钟/刺激，旧参考仅测试，不产生双硬件生产核；M3旧独立数学/向量只读。

相容检查：槽源仍原canonical_slot，N(s)见原slot_maximum_bits，0/1/2/8/10/11的N分别67/89/88/132/37/32，N最大132；full192原值区间[-2^N,2^N-1]。先构造signed N+2，其中原value[191]重复两位+低N；取负范围[-(2^N-1),2^N]严格可表示，符号扩展回192与原完整取负全位相同。不是利用新接口窄化任意外部192整数。

W/H11的v∈[0,2047]，构造signed12的{0,v}再减1，范围[-1,2046]；扩回192，v0时全ones也等于原192 unsigned减一的回绕位模式。实际合法W/H原CHECK范围不变。

line kind14 slot3在step12经完整scalar target21 unsigned资格，step18/23/24写回仍u21且原local fits在提交前检查。step24 upper/lower直接复用已批准line_odd_boundary(q21,upper)；2q+1∈[1,2^22-1]，q>0时2q-1同22位；q0 lower由原分支覆盖写0且跳到25，保持顺序，不把q0 underflow当值。原line_neighbor22保进位资格仍不变。

## E 中文内部操作与语句安排

E1 在已有function区新增local_negate(slot,value)：case仅0/1/2/8/10/11常量调用，每分支局部logic signed [N+1:0] expanded/negative，expanded={$重复两位原高符号,原低N}；negative=-expanded；返回{{192-(N+2){negative最高位}},negative}。其它索引default沿原-full192，当前核心没有新增调用。顺序是先扩大一位再取负，不能先低N取负后补号。

E2 coordinate_last(v11)：局部signed12 extended={0,v}；last=extended-12'sd1；显式符号扩192。替换TLS step44/45原W/H减一，不改命令的sb0或目标44bit。

E3 原plan里的完整槽取负，逐一替换为local_negate(常量槽号,对应work_slot)。保留32位输出field表达式-plan_value片段，因为其原本就是规定32位，不属于本次宽算术。kind14 step24 phase0/4换line_odd_boundary，保原q0/qualify/nextstep覆盖优先级。所有needing/target/signed/branch照旧，不移动到另一个沿。

E4 always_ff主体不改，状态PREPARE/LOCAL_COMMIT仍读旧valid/旧槽及完整返回，canonical写的目的及事件一致；reset不清数据槽的原有效性隔离保持。取消优先覆盖提交，HELD正文不热变。helper不拥有历史，逻辑展开无副作用。

## F RTL与数值映射契约

SystemVerilog；数字在运算前显式signed和宽度，concat默认unsigned故先$signed，负号在N+2局部域；扩展到192才接原计划数据，原full385资格仍原样，不省略检查。combin函数仅blocking，无新always_ff/锁存/历史。core单上升沿，原req/rsp/fire、气泡/反压、复位、配置与缓存、identity、无新CDC完全相同；DUT/旧核同25MHz测试clock，MAP单100MHz约束只用于可比预算，不声称100MHz实现已通过。外部图像内存不涉及，新RAM/DSP不申请。C++生产代码N/A；原Python大整数定义是独立数学，不逐句跟RTL。

对应：旧/新均同实际622接纳，完整585及所有中间真实scalar Q/R/Bridge结果与合法local192提交相同；位逐位、每沿同，0容差。另按原数学字段定义比终态，不能把旧RTL等价独自当数学正确。任意invalid/uninitialized数据不宣称相等，但合法visible/held正文必须相等。

## G/H 实施、验证及追踪

6输出：rtl/fit_core.sv、tb/tb_fit_resource.sv、scripts/run_resource_sim.ps1、scripts/run_resource_map.ps1、project/fit_resource_component.xml/.sdc。4原RTL+2数学原样复制；旧FIT声明适配另有明确原始摘要；baseline10输入。所有PID/argv/超时/fatal非零/finished/源快照保留，新RunId不覆盖。

RT01 原fit_vectors generate固定全部种子和seven kinds，全原tb数值/错误/取消/reset/cache/资格/内部state覆盖运行，独立audit-core逐数据/租约检查；语法通过不能替代。
RT02 每个非reset沿，旧/新外部握手/quiet相同；有效rsp全585、有效child_req全622/valid/ready、child_rsp全585/valid/ready和真正local_submit full192相同，accepted/consumed等所有原账保留。原先可达状态cancel/reset仍完整，不缩短集省工作。
RT03 目标helper的定向全范围角点：每N正/负零、±1、边界/powers/random的canonical192旧负号全位相等；W/H0/1/2047和q0/max21边界、原q0覆盖次序检查。子运算原数学向量不改。
RT04 同设置旧/new实际MAP、原语/netlist SHA与报告比，三原地方“声明范围/实际primitive/相对差值”分开；若没有节省明确说未达优化目标。无板级IO/布局/时序/bit或硬件。

FR01/03→M1 IF1/3/E4→原always_ff/bridge→RT01/02；FR02→M1 IF2/E1/2/3→helper/plan局部→RT02/03；FR04→工程/运行器→RT04。反向每新helper只对应原局部表达式，不夹带新算法。

## I/J/K/L 门槛、授权和记录

十项：B整体/边界；C职责/复用9真源；D完整接口与数学相容；E逐语句/沿内部；F A数值 B时钟 C握手 D气泡 E保持 F不变延迟 G不变复位 H不变配置 I原槽存储 J全身份 K无新CDC L器件/预算；B/D正常与最负/q0走查；G/H实施验证双向；当前无阻塞；本文件保存读回呈现；v1/6输出/10输入清楚。READY_FOR_REVIEW自检不代表用户理解或测试完成。持续自主软件授权及本地例外覆盖，正式状态不伪改。

已有实际证据改变初步方向：源声明3072槽位实际已1791FF，故不另重写存储。当前只改有可检查数学证明的局部宽运算，若实现发现新边界先变更卡。完成后用README和实际测试/两个MAP/登记报告更新真实范围；理解验收待实际作答；完整识别、DDR/CSI/root及全FPGA资源/PNR/STA/bit继续，不缩成局部成功。
