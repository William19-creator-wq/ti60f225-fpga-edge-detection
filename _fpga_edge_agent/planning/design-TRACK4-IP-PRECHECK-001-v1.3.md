# TRACK4-IP-PRECHECK-001 v1.3：C0 USER1外围声明及专属SDC与实际顶层对齐短卡

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)的小修复短卡。**LOCAL_DESIGN / READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN（v1.3新revision）**。本卡只提出在新的`C0_user1_aligned`副本修改两个文件：删除一棵未被实际顶层使用的USER1外围声明子树，移除原SDC中该不存在接口专属的一项group和十二条活动I/O delay，并重新执行有限预检。原完整十一项目标、原C0–C3矩阵及停止条件沿[已批准v1](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/approved-design-v1.md)；既有v1.1/v1.2批准不自动包含本接口修复。**原SDC第78行CLK_25M的活动`<USER_PERIOD>`非数值占位仍保留、本卡不解决；仅有限USER1修复可评审，不代表原SDC合理、clock/整机READY或STA通过。**

## A. 通用计划字段、范围与阅读入口

- Goal / Target：取消原外围配置对不存在的`jtag_inst1_*`核心端口的要求及该接口专属活动SDC残留，保留原USER2调试和其它约束，再取得新revision真实map、官方debug、PT、PNR/STA终态。
- Current state / Gap：获批v1.2的C0已map PASS、官方debug生成/合并PASS、PT PASS；PNR exit1，packer报告缺少required USER1 TDI/TDO。placement未到达，route/STA未运行。当前USER1声明与原源一致，问题不是官方格式迁移新造。
- Assumptions：只复制当前C0的92项冻结输入；原HDK与现C0都保持。原顶层没有USER1/JTAG实例，原wizard明确USER2；不增加RTL端口、不补常量、不删除所用USER2、不绕过required检查。两文件允许delta仅为D的精确USER1节点及专属SDC，所有其它内容保持。
- Open questions：原SDC第78行活动CLK_25M时钟声明仍有非数值`<USER_PERIOD>`，不允许替换为猜测周期；若解析、clock或STA报错真实停止。其它原样保留的已知覆盖风险为41–52行旧I2C GPIO名、137–140行旧system_spi名、257–272行旧cam_d0/1前缀与top不符，i_cam_ck_CLKOUT定义仍注释、无活动USER2 TCK定义，13/14行waveform与新PT有0.25ns差异，26行core/PHY exclusive关系待完整clock设计。均须真实报告，不扩改、不称合理约束/STA通过。其它兼容/资源/clock错误仍由有限实验输出。Questa保护key仍不可用；C1固定#4、C2外部byteclock及C3依赖阻塞未由本卡解决。
- Dependencies / Baseline：候选IP-PRECHECK-BL-v1.3为当前C0的92项、合计2,876,101B，90项与原源逐字节相同，XML/peri采用已审计的官方兼容迁移。它是**尚含USER1声明及其活动SDC的修复前输入**；未来peri和SDC各自长度/hash均没有生成。XML仍66条design_file及两个ip_info SV源。
- Milestones / Detailed steps：保留旧未批准稿→只读定位与修订短卡/候选manifest保存读回→root独立检查和呈现→指定v1.3/92/两文件delta/新路径批准→新副本冻结→精确节点及SDC修订/两个实测hash→map→官方debug生成/合并→PT→PNR→STA，前阶失败不启动依赖下阶。
- State transitions：本卡READY_FOR_REVIEW、批准NOT_APPROVED、新revision执行NOT_RUN；不改变原失败、H0、正式数据库或PROJECT_STATE。新结果绑定新revision，不覆盖v1.2终态。
- Artifacts and hashes：[候选92清单](../experiments/track4_full_sw_20261004/01_baseline/ip-precheck-inputs-v1.3.json)为82,162B / SHA256 `344ACB1E46F545812917C6820CBD9B94DBD8B01EDF6DDD0AB2DCB29882E9B2E0`。parent v1.2清单SHA256 `B0710CECE3681230CE042F9D1B74933ABE1B103011258415FD67D28D9E13F391`；其原批准设计快照SHA256 `2A0AA04F72BAC738A70B5BA5A3DAE503C1F393478939587A7AAFCEE9F1A95E34`。J记录本次修改前的两份未批准draft快照。
- Validation：D的节点、端口、top/profile及原实际失败已只读核对；候选92项current与original均重新读/hash。新副本、新修订、工具阶段和新revision验证全部未执行。
- Failure handling：基线漂移、目标已存在且归属不符、删除节点非唯一、SDC行内容/计数不符、USER2/profile变化、新依赖、保护IP升级/再生成要求或工具失败均保留实际证据并停止受影响case。不通过改业务、其它clock/SDC或关闭debug得到通过。
- Human approval gates：等待指定批准本卡v1.3、IP-PRECHECK-BL-v1.3/92、`C0_user1_aligned`路径、两个文件的精确USER1删除delta与有限阶段；原本地审计/DB例外只有在本有限修订获批后才按原条件继续，不配置或改正式DB。
- Rollback：保留原HDK、现C0、两次早期map失败及v1.2 map/debug/PT/PNR/Questa全部证据。恢复先核新副本差异与真实工具handle；不覆盖旧输入、不删除旧日志、不通过旧outflow补新证据。
- Completion criteria：本次设计交付是具体可评审兼容性修复。获批后按真实阶段终态报告成功、失败、NOT_RUN或依赖停止，不将外围对齐称完整业务正确、整机交付或硬件通过。

新工作路径只计划为`D:\大三\FPGA_verilog\_fpga_edge_agent\work\active\track4_ip_precheck_20261004\C0_user1_aligned`，ASCII调用别名可沿现有Work junction。当前不存在该目录，本轮不创建。阅读顺序A/B整体→C/D连接证据→E操作草图→F/G/H契约/验证/追踪→I指定批准。

## B. 被修正的整体外部行为

IP-REQ01要求真实可恢复输入；原D的C0条款要求保留被引用业务和debug；IP-REQ04要求clock/net/reset/V4引脚及约束问题可解释；IP-REQ05要求编译、资源、PT/PNR/STA证据分开；IP-REQ06要求指定批准与失败停止。本卡增加派生IP-REQ07：外围USER链声明及专属活动SDC必须对应本revision实际核心端口，仅移除不存在USER1的声明和专属残留，保持原使用的USER2探针与接口。**原IP-REQ02是ASYN1/ASYN0及bridge测量矩阵，不是保留debug；本卡不重新定义或改变REQ02/03。**准确来源为已批准v1第44–49行、D第61行及H第124/126/127行。

触发为获批后在新副本运行现装工具。修订前，PT生成USER1的11项fabric接口要求，TDI/TDO为required，但业务RTL和官方USER2合并网表均没有`jtag_inst1_*`端口，packer失败；原SDC另有13行活动USER1引用，尚未获得STA结果。修订后，预期新PT不再生成USER1这11项要求，新SDC活动USER1引用为0，仍生成完整USER2要求并与新官方合并网表连接。删除范围仅为fabric USER1外围声明及D的专属SDC残留；板卡专用JTAG物理引脚、IO bank、业务端口、其它约束和原USER2链没有本卡变更入口。

正常样例：92项匹配→唯一USER1子树及专属SDC精确删除→新debug保持USER2/4096/探针→新接口CSV无USER1且USER2完整→PNR/STA实际终态决定结果。边界样例：匹配节点0个或多于1个、SDC原行/十二条计数不符，说明输入/选择不符，停止而不放宽匹配；如果新派生dbg.peri仍有USER1，停止，不沿用或手工补修旧派生物。错误样例：required USER1错误消失而CLK_25M占位或另一clock/资源/约束错误出现，保留新失败；不能称PNR/STA已完成。原取消要求只停止新阶段，已启动阶段通过真实handle确认终态并保留产物。

## C. 职责与整体交接

MOD-INPUT（IP-REQ01）拥有当前92项来源、原源追踪和副本身份；MOD-CASE（IP-REQ04/07）仅拥有新base peri指定USER1子树及新SDC专属残留删除/实测delta；MOD-TOOLS（IP-REQ04/05/07、原D的C0义务）用冻结wizard生成新debug RTL/profile/VDB、合并并生成PT/PNR/STA产物；MOD-REPORT（IP-REQ05/06）按revision/attempt/phase记录退出码、输入/产物hash、警告和覆盖限制。

配置路径为原HDK→现C0兼容迁移→IF01新92项副本→IF05 USER1声明/实际top及IF06专属SDC对齐→IF02新官方工具阶段→IF03终态/资源→IF04整体设计证据。USER2路径为冻结wizard→新官方debug RTL和tool profile→新merged VDB/derived peri→新PT接口CSV→PNR。它们必须属于同一个新revision；旧派生dbg.peri仍含USER1，不能混入。

本修复没有新增运行期像素流、队列、反馈或状态机；缓存/死锁/流控设计沿原源码，本卡只改变静态外围声明的组合前提。整体选择是保留实际USER2调试并移除不被使用的USER1要求；不是修改算法或新clock架构。

## D. 准确接口、节点清单与组合核查

IF01输入合同为候选manifest中的`path/relative_path/bytes/sha256`当前C0身份，另存`original_path/original_bytes/original_sha256`。修复前90项无迁移差异；两个已存在迁移输入如下。新副本应先与候选92条全部匹配，随后才发生IF05/06两文件delta；修复前清单不能被写成修复后hash。

| 文件 | 当前C0 bytes / SHA256 | 原HDK SHA256与既有迁移 |
|---|---|---|
| ti60f225_oob.xml | 15074 / 5F0CF2C013F945974052FFE796D68E84815C9F5C02B9CF37EA44086221BFED3A | 571E5A03A7CCC46D2B15CF9D3DCAAA1BC1A874CB3E0908330599891457867BE8；169元素对照仅root sw_version变2026.1.132及序列化 |
| ti60f225_oob.peri.xml | 74485 / 2FF6846870EAB4FD1CF190FA11377C7DAE891A693404E7510916AFC801AA4D23 | 9D378EFF67AC34F88F78A41341A1451E8F3B87B246434DDEDA12C7295A100CAE；root版本/日期、gen_pin排序/15空项清除、5个空默认dly_clock_name |

peri迁移证据见[C0-peripheral-format-delta](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C0-peripheral-format-delta.json)，812B / SHA256 `81782F62769C64AB42373AF8EBEC956849A422D6D23F7CF8D58A8572E084F4DC`：256配置元素与实际pin语义保持，非本卡新行为。本轮原92项重新hash均匹配；未把迁移当作删除USER1的授权。

IF05提供方是新副本base peri的静态声明，使用方是官方PT/packer与实际合并顶层。准确命名空间为`http://www.efinixinc.com/peri_design_db`，文中alias为`efxpt`；真实根元素为`efxpt:design_db`，其`name`属性才是`ti60f225_oob`。唯一选择路径是`/efxpt:design_db/efxpt:jtag_info/efxpt:jtag[@name='jtag_inst1' and @jtag_def='JTAG_USER1']`，已在当前DOM实际验证命中1。不要把XML的name属性误作根元素名。

IF05拟改文件为新副本`ti60f225_oob.peri.xml`。删除当前base 421–435的整棵`jtag`子树：两属性`name=jtag_inst1`、`jtag_def=JTAG_USER1`；下唯一`gen_pin`容器；11个pin。共13元素，当前全部500元素。保留父`jtag_info`及其它所有配置；不修改旧C0、原HDK或已派生dbg.peri。第二个允许文件仅为以下IF06。

| 删除pin名 | type_name | 核心方向 / 位宽 | 现CSV定位 |
|---|---|---|---|
| jtag_inst1_CAPTURE | CAPTURE | input / 1 | 302 |
| jtag_inst1_DRCK | DRCK | input / 1 | 303 |
| jtag_inst1_RESET | RESET | input / 1 | 304 |
| jtag_inst1_RUNTEST | RUNTEST | input / 1 | 305 |
| jtag_inst1_SEL | SEL | input / 1 | 306 |
| jtag_inst1_SHIFT | SHIFT | input / 1 | 307 |
| jtag_inst1_TCK | TCK | input / 1 | 308 |
| jtag_inst1_TDI | TDI | required input / 1 | 309 |
| jtag_inst1_TMS | TMS | input / 1 | 311 |
| jtag_inst1_UPDATE | UPDATE | input / 1 | 312 |
| jtag_inst1_TDO | TDO | required output / 1 | 310 |

pin原属性只有name/type_name/is_bus=false，没有dir/mode属性；表中方向由实际接口CSV和USER核心接口含义核对，都是控制位，无signed/像素/字节缩放。删除前声明要求11核心端口，删除后取消这11项要求，不生成替代端口。原top 42–214端口表及全文JTAG/USER1/USER2/jtag_inst匹配为0；67个实际DUT文本对jtag_inst1/JTAG_USER1也为0。原top保持34765B / SHA256 `0ACCF23D67A2E5360C91DDCD36563C5E90A682BE52B071B18F2B8F0F40DF5AA9`。

保留IF02中的USER2由原wizard确定：16595B / SHA256 `52B3CFD44B6311F1B1386124B781CE56EB0090A220E08E78B6AE359916F1DB04`。la0为cal_done(1bit,CLK_5M)，la1为data1/data2/clk/data0四组TMDS(各10bit,hdmi_tx_slow_clk,9:0)；两core均4096、input_pipeline1、capture_control=false、DATA AND TRIGGER；session USER2。当前工具profile仅两个随机UUID不同，其余core/连接/session相同。新生成也须做全语义比较，允许新官方UUID，但必须让tool profile与fresh RTL UUID对应，不用空mark_debug profile。

当前derived peri 436–450的`jtag_inst2_autodbg__ / JTAG_USER2`及11个`jtag_inst2_autodbg_<TYPE>__`必须在新派生中完整保留。实际merged RTL的190–200为10 input＋TDO output，CSV 313–323相应完整，320/321仍required。顺序、bit宽、探针domain和采样深度不能改变；新派生USER1必须为0、新USER2必须为1。顶层本来没有USER1，此修改不改变业务RTL数据数量、数值、帧归属或运行期配置采样，但改变外围声明接口，须指定新批准。

IF03失败合同来自实际[place.out](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C0-pnr-logs/ti60f225_oob.place.out)：21/22缺required jtag_inst1_TDI/TDO，23计2个错误，30/31 packer/flow失败，2235B / SHA256 `452410821A2EEBCF374C8C1A5FCCCC1E4B61CFC3A42425015D7E603D605CA7AF`。新修订仅针对这个已定位组合不满足条件；原其它missing/warning、LVDS间距、保护实现体、资源/clock/STA问题不因这项修改成为PASS。

IF06提供方是新副本`ti60f225_oob.sdc`，使用方是同revision的官方工具及STA。修复前为41,339B，SHA256 `18D030F58DF66A2E3604699A5AFA7AC9E1C8A50D5F930969507BB57BBF14C32E`，与原源字节相同。该文件全USER1引用21行=13活动＋8注释；原25行唯一活动clock_groups含i_soc_clk、i_mipi_rx_pclk、jtag_inst1_TCK三个group，仅移除末尾` -group {jtag_inst1_TCK}`，保留`set_clock_groups -exclusive  -group {i_soc_clk} -group {i_mipi_rx_pclk}`的其余字符。原57–68行恰为十二条仅属于USER1的活动I/O delay：TDO output max/min=0.134/−0.075；CAPTURE、RESET、UPDATE input clock_fall max/min=0.322/0.187；SEL=0.279/0.162；SHIFT=0.388/0.225，clock全部为jtag_inst1_TCK。删除这十二条整行，不将数值或接口迁移给USER2。精确原行文本见候选JSON的`planned_revision_changes`；原行号仅定位，内容/计数必须同时匹配，不盲按行号删。

IF06后置为新SDC活动USER1引用0；8条原注释引用在原29/31/33/56/70/71/72/74行，连同全部其它行、注释、编码和换行原样保留。没有其它活动USER1引用；这只闭合当前可见USER1专属约束，不能证明所有时钟合理。**原第78行`create_clock -period <USER_PERIOD> [get_ports {CLK_25M}]`是确定存在的活动非数值周期，保持范围外；后续若解析/clock/STA失败必须记录真实错误并停止，不猜周期、不删除它、不扩大SDC修正范围。**新peri与新SDC必须作为同revision输入再跑工具；未来两个文件bytes/hash均未知。

## E. 局部中文操作草图与不变量

批准前只保留旧未批准draft、修订本卡和候选JSON。获指定批准后：①核版本/92基线/两文件delta/路径与本地审计例外条件；②核原C0、原失败和原HDK不变，确认新目标没有冲突；③逐条重新核current来源92项，再只复制这92个文件及所需父目录，不带outflow、work_syn、work_dbg、work_pt、work_pnr、questa_compile、旧debug_top/VDB或历史接口产物；④在新副本删除前重新核92项hash，记录新revision身份；⑤用真实namespace和双属性精确选择USER1，要求唯一、子树13元素/pin11项与D完全相同，同时核SDC原25行、57–68十二条全文/计数和13活动引用，任何不符停止；⑥只删除该子树与D指定SDC末尾group/十二条整行，保留父和所有其它内容，peri按DOM语义比对、SDC按精确行/字节比对，真实保存读回后记录两个新hash，90个其它输入仍匹配当前候选；⑦从干净输出执行map，真实终态成功后才用冻结wizard官方生成新RTL/tool profile并合并，禁止保护IP重生成/升级；⑧检查USER2/profile语义、fresh输出身份，PT必须使用本revision新derived peri、新SDC与新合并网表；⑨核新base/derived/CSV无USER1、新SDC活动USER1为0且原注释/其它约束完整，derived与CSV的USER2完整（base原来不含USER2，由官方helper新增），IO/bank/业务声明及其它clock关系不变，随后才PNR/STA；⑩逐阶段保存原始日志、退出码、产物hash和警告，含CLK_25M占位在内的任何失败停止下游，不拼接旧报告。

不变量：复制时全部92项按当前候选固定（其中90项与原源字节相同）；未来修复仅peri、SDC两文件可变，其余90项相对当前候选字节不变，不能把修复后的SDC仍称原样；新base唯一语义delta为13元素USER1子树删除，新SDC唯一delta为D的一项末尾group及十二条整行删除；原USER2/4096/5探针/两个domain完整；无旧派生物借用；其它clock/CDC/SDC/IO/业务不变；每个结果能反向定位新revision和真实输入。工具后续只允许原已审计的无语义版本/序列化兼容变化，发现其它pin/net/配置改变先停，不把“官方工具生成”概括为任意许可。

本修复没有同沿数据接受、新ready/valid或新reset；静态声明在工具展开前生效。现有复位、排空、CDC、存储及控制副作用沿原RTL保持，不能借外围对齐宣称其正确。取消时不启动新阶段，已在运行阶段确认真实终态后保留产物；恢复重新检查批准、hash、节点delta与工具handle。

## F. 语言、数值与硬件执行边界

C++与共同数值模型N/A：无模型/算法/业务实现体或跨语言映射改变。软件文档操作顺序仅是文件/工具的执行顺序，不代表RTL边沿。结果对应为静态peri USER链端口→新合并RTL核心端口→新PT接口CSV→packer真实检查，并由同revision新SDC供时钟/时序检查；按namespace/name/type/方向/位宽/profile及指定约束精确比对，无近似误差。

RTL §8.2 A数值/J身份：11项控制端口各1bit，删除声明没有替代数据，像素数值/身份沿原源码；B时钟/K CDC：仅删除不存在USER1的专属SDC引用，不改实际clock/net/domain、其它SDC或复位同步，CLK_25M占位仍未知；C接受/D推进/E反压/F延迟：不新增运行期协议，原路径保持，吞吐和延迟尚未由本实验验证；G复位/H配置：静态peri/SDC改变只在重新工具展开时生效，不是运行期动态写配置；I存储：无新增RAM/队列/初始化策略，原Panel及全部MEM保持；L实现：现装Efinity2026.1.132、Ti60F225/I3、原SV_09/VHDL2008、原protected源和settings，重新综合/布局后资源实测，不能拿v1.2数量直接标新revision通过。

Questa新revision状态NOT_RUN：DUT字节没有改变，不重复已证实相同输入的无key编译；沿[C0原实际编译证据](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/C0-questa-final-result.json)记录原vendor PASS、DUT CSI385 key失败、DSI未到达、vopt NOT_RUN。引用是已有兼容性限制，不是v1.3编译/展开PASS。新修订仍不产生TB、激励、vsim/run或功能仿真。

## G. 实施与验证计划（新revision未运行）

| TEST / 目标 | 初始条件与检查 | 期望来源及通过/停止条件 | 状态 |
|---|---|---|---|
| IP-T01-v1.3 / REQ01 / IF01 | 新副本复制前后92项逐份bytes/hash，90项原样，XML/peri候选固定，无旧产物 | 真实候选manifest；任何漂移/冲突停，不换来源 | NOT_RUN |
| IP-T07-NODE / REQ07 / IF05 | 正常唯一USER1；边界0/多匹配、pin/属性不同 | D精确XPath实际命中1/13元素/11pin；只允许唯一子树删除，其他情况不改 | NOT_RUN |
| IP-T07-SDC / REQ04/07 / IF06 | 原25行与57–68十二条全文相符；其它USER1注释、CLK_25M占位保留 | 只删除指定group/整行，活动USER1=0，全部非目标字节相同；不符停；占位解析/clock/STA失败据实保留 | NOT_RUN |
| IP-T07-COMPOSE / 原D C0义务、REQ04/05/07 / IF02/05/06 | 原wizard新官方生成/合并/PT；旧derived含USER1作为误用反例 | USER1=0、USER2=1且11端口完整，新SDC同revision；4096/5探针/domain/pipeline保持 | NOT_RUN |
| IP-T07-FLOW-v1.3 / REQ04/05/07 / IF02/03 | map→debug→PT→PNR/STA，前阶成功才后阶 | 原真实required失配消失；其它错误仍据实FAIL/NOT_RUN，不预定PASS | NOT_RUN |
| IP-T05/T06-v1.3 / REQ05/06 / IF03/04 | key/IPregen/profile/clock/许可错误与取消/恢复；保留每阶段日志 | 原设计停止条件、精确输入/命令/时间/退出；无bit/hex和硬件动作 | NOT_RUN |
| IP-T07-UNCHANGED / REQ01/04/07 / IF05/06 | 删除后非USER1配置、其它90项及SDC非目标字节对照 | 两文件精确delta；无新增实际clock/CDC/IO/bank/DDR/CSI/profile变化 | NOT_RUN |

这些是文字场景与验证计划，不是可执行测试。原C1只有C0新revision成功才具有原依赖前提，但Ti60固定PLL#4仅regional的独立阻塞仍有效，不改输出号或新clock路线；C2.clock-corrected外部byte频率未知继续CLOCK_UNRESOLVED，C3继续依赖停止。本卡不夹带它们的调整或重试授权。

## H. 双向追踪

| REQ / 来源 | MOD与IF / 局部入口 | 计划文件/符号 | TEST与实际证据 |
|---|---|---|---|
| IP-REQ01 / 原v1输入契约 | INPUT / IF01 / E①–④ | 新92副本与实际delta记录，尚未生成 | T01；候选current/original hash |
| IP-REQ07 / 本次真实PNR失配与USER1声明/专属SDC对齐要求 | CASE/TOOLS / IF05/06、IF02 / E⑤–⑨ | 新base peri唯一jtag_inst1/JTAG_USER1子树；新SDC指定group/十二条；新官方派生产物 | T07-NODE/SDC/COMPOSE/UNCHANGED；原place.out21–23、D top/profile/SDC证据 |
| 原D C0义务；IP-REQ04 / 已批准v1第61/47/126行 | CASE/TOOLS / IF02/06 / E⑥–⑨ | 保留业务/debug/真实clock关系；仅USER1专属SDC delta | T07-SDC/COMPOSE/UNCHANGED；USER2冻结字段、SDC原hash |
| IP-REQ05 / 原工具证据分开及限制 | TOOLS/REPORT / IF02/03 / E⑦–⑩ | 新map/debug/PT/PNR/STA产物；尚未执行 | T07-FLOW；旧各阶段真实终态 |
| IP-REQ05/06 / 原真实终态与指定批准 | REPORT / IF03/04 / E⑩、I | 新revision日志/本地审计，尚未生成 | T05/06；旧失败独立保留 |

反向每个拟删pin都来自原USER1同名声明及CSV要求；每个拟删SDC片段只含该USER1 clock/端口并映射IF06/T07-SDC/REQ04/07；每个保留USER2端口来自原wizard/新官方连接；没有无关代码单元或业务实现入口。未来两文件修订反向到REQ07/04，阶段报告反向到本revision/基线/真实phase，不由旧map/PT/Questa结果代替；REQ02仍仅原ASYN矩阵，不挪用于debug保留。

## I. 门槛、呈现与指定批准

①B整体行为与正常/边界/错误例；②C职责及复用调查；③D准确节点/端口/SDC与top/profile组合；④E确定中文步骤/不变量；⑤F适用硬件契约与N/A理由；⑥D/G局部和端到端场景；⑦G/H实施、验证、双向追踪；⑧这项修复的输入、唯一节点及专属SDC、来源和两文件允许delta已闭合，CLK_25M占位明确保留，后续工具未知仍是有限测量结果；⑨本卡与候选实际保存/全文读回后供root独立审读并呈现；⑩v1.3/92/新路径/两文件范围明确。仅本有限修复READY_FOR_REVIEW，不升级整体clock/SDC/整包状态。

原v1/v1.1/v1.2批准保持其已执行范围；本次删除明确外围接口声明及其专属活动SDC，不属于旧范围内纯格式迁移。唯一[规范v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)§11.2规定：“更改公共接口、错误语义、输入范围、输出数量／顺序、状态有效性、数值近似、延迟／流控、复位、配置采样、CDC、重要存储策略或批准范围，必须暂停受影响的代码生成。”并规定：“更新整体与局部文档和追踪后，再取得对新版本的批准。”本卡据此等待用户明确批准指定v1.3、92基线、两文件精确delta、新路径和有限阶段，而不代用户批准。

下一项允许行动为root审读/呈现与一次指定批准。没有新的原始用户批准记录，不把本卡、JSON、独立静态审阅或原批准写成新批准。若获批，原本地审计/DB例外只继续服务此有限预检及其原条件，正式审批/数据库/硬件闸门不改。

## J. 变更与恢复

修改前未批准[短卡快照](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/v1.3-draft-peri-only-design.md)为21,952B / SHA256 `10E548E0FC8CC2076CC43882859E4BF8F4C72B91B9BE097E60E730F64598BA37`；[JSON快照](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/v1.3-draft-peri-only-inputs.json)为78,141B / SHA256 `6BA5141A693B41AD6CA69BD6AE6CBF3BD9E32222670F366C773440ADD3D65289`。两份只作已取代、未批准、未运行draft历史，不是当前审批输入。

旧输入保留原USER1声明及专属SDC，真实工具已证明required核心端口缺失，静态审阅另确认专属活动SDC残留。本卡在提交批准前把该两文件范围一起闭合，保留实际USER2，影响REQ04/07、IF05/06、T07；不是补空端口、改调试用户或关debug。复制前92输入仍取当前C0，旧base/SDC/derived证据原样保留，未来两个文件hash不预造。

恢复阅读指定批准、本卡、92清单、旧失败、新副本冻结、两文件实际delta及真实阶段handle；禁止把旧派生物复制进新revision。任何新增源、不同节点删除、不同SDC片段或probe/其它clock/IO变化须重新记录影响和指定审阅，不能借本卡扩大范围。

## K. 实际记录与证据限制

本轮只读完成：读取模板、原批准/终态、准确REQ来源和规范§11.2；重hash当前92输入及原92来源；读官方XML/peri迁移审计；核真实根/namespace/XPath、唯一13元素/11pin、top零USER1、冻结USER2语义、原CSV/packer错误；全文静态核SDC专属13活动引用/8注释及独立CLK_25M占位。独立子审阅复核同一接口与REQ事实。仅保留两份旧draft快照、修订本卡和纯数据候选JSON并全文读回，没有创建新work、删除节点/约束、生成RTL/功能脚本/模型/TB、运行综合/仿真/布局工具或写正式状态/DB。

原有限终态见[RUN_REPORT](../experiments/track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)，本轮读取时9659B / SHA256 `0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA`。它包含原PNR失败及原Questa不兼容，不是新revision结果。v1.3实际实施、产物和验证全部NOT_RUN；future repaired hash保留未知，不能提前计算或填造。

## L. 交付与阅读说明

当前交付是这份修订短卡和仍为改前输入的92候选基线，另保留两份旧未批准draft快照。先读B理解原失配，再读D看到准确节点/11端口、专属SDC删除和保留USER2/其它约束，读E/G知道获批后从干净输入到真实终态的顺序，最后读I确认指定批准对象。删除后能否完成布局/STA仍须实测，已知CLK_25M周期占位未解决；算法、生产摄像/显示服务、识别质量和完整十一项交付不由本卡证明。理解验收待用户实际反馈，不把讲解当已经理解或批准。
