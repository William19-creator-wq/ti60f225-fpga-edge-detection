# TRACK4-ALGORITHM-R2-FILES-001：流段与OBS逐文件合同 v0.1

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。属于[R2主稿v0.3](design-TRACK4-ALGORITHM-R2-001.md)B05；本页冻结候选文件职责，不宣称B05或整包闭合。

## 通用计划字段

- Goal：生成代码前明确R2核心流段及OBS的每个计划文件、复用来源、类型、语言、验证入口和报告边界。
- Current state：C0/OBS附件已审阅；R2 v0.3合并，代码/工作目录不存在；B03控制显示及完整整包交接未冻结。
- Target state：每个计划文件有单一职责、具体IF/中文草图、独立期望/协议检查及生产证明归属，获整包批准后连续实现。
- Gap：本页待独立审閱；B03新模块及R3/R4/R5跨批集成不能从本流段文件表推定完成。
- Assumptions：SV2009、已有Python3.14.6标准库、同core域和可暂停来源；生产W1920/H1080，流段合法静态W偶数6…1920/H5…1080。
- Open questions：B03完整文件/语言合同、真实工具许可/命令及实测资源时序；不以增加文件掩盖未决接口。
- Dependencies：[原FRONTEND](design-TRACK4-FRONTEND-001.md)D/E/F1/G/H、[R1](design-TRACK4-ALGORITHM-R1-001.md)A/H、[C0](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md)、[OBS](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md)。
- Milestones：来源/文件合同→读回审閱→B03及跨批文件并入B05→共同实际基线→整包READY/批准→生成/验证。
- Detailed steps：B边界→C复用/文件→D交接→E中文推进→F语言/向量→G验证→H追踪。
- State transitions：本页LOCAL_DESIGN；不修改正式H0/Manifest/数据库；待完整相关设计和批准才IMPLEMENTING。
- Artifacts and hashes：来源由当前R2候选39清单绑定；本页实际hash另记审阅，不伪造业务源码hash或Git commit。
- Validation：模板/字段/链接/来源检查属文档；所有未来测试均NOT_RUN。
- Failure handling：未冻结接口停止对应实现；许可/工具/比较失败保留事实，不换期望、force完成或缩小生产尺寸。
- Human approval gates：完整软件设计包指定版本/范围/基线；工作副本/构建/审计前置沿用既有审批。
- Rollback：仅控制面文档；未来只在批准独立work，原HDK/工具/参考只读。
- Completion criteria：完整B05还须B03文件、跨批使用和独立审阅；本页完成不等于B05关闭。

## A. 位置和版本

计划root为 _fpga_edge_agent/work/active/track4_algorithms_20261004/r2/，当前不存在。以下r2内相对路径均是未来产物，不能点击不存在的路径当已有源码。源文件只在work，不放入experiments文档目录。

复用的R1/FE来源必须是整包明确批准的同一版本：FRONTEND设计SHA256 45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114，R1 F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00。R2最新主稿在设计继续修订时另核hash；此处引用不能冻结未来可变主稿。无用户实施批准。

## B. 外部行为和可判断结果

FILES-REQ01：核心与观察器文件恰实现R2/C0/OBS已声明行为，不新增第二个FE owner、不截断142/592/185bit、不以class代替最终edge。
FILES-REQ02：模型独立计算完整数学；TB用真实握手核前缀/身份/取消/终态，完整成功生产图逐像素比较。
FILES-REQ03：运行器明确有限case、参数、退出/超时/日志/版本/产物路径；缺运行或只出现PASS字符串都不是通过。
FILES-REQ04：真实生产工程按四pin/40ns/精确例外验证，bit后登记停止；测试参数不进入生产工程。
FILES-REQ05：B03及完整Canny/识别/摄像显示文件另按冻结接口补齐，当前不虚构完整软件清单。

正常例：相同R1 FE源码在r2 wrapper的Y_ONLY实例输出M，R2在G8上另实例化window3x3/Sobel诊断梯度通道，经方向/NMS输出class；K同时观察真实grad/CS。边界例：retain0禁止等待grad ready，但CLASS和真实CS仍必须完整核验。失败例：源半帧bad后真实CS/短前缀被观察，完整图比较明确不适用，但下一完整job仍须恢复；不写成完整成功。

## C. 唯一职责与候选文件

R1共有六RTL：frontend_frame_pair、rgb_to_y_pair、line_store_pair、window3x3_pair、median9_pair、sobel_pair，原H路径为r1/rtl/frontend/。R2编译引用其同一物理文件一次，不另复制一套；R1原顶层/S/J/K不并入R2生产top。reset复用r1/rtl/r1/reset_sync.sv的相同合同，R2只实例化自己的两级释放链，顶层只有一个reset driver。

| 计划r2文件 | 唯一职责/稳定符号 | 合同与验证入口 |
|---|---|---|
| rtl/r2/r2_protocol_pkg.sv | CJ/CS/DERR及typed记录的命名位宽/编码/布局常量，不拥有job、不做算法 | R2 D/C0§2/OBS B；包先编译，布局算术与独立解码测试 |
| rtl/r2/canny_stream_top.sv | 唯一连接FE/C0/G/S/D/FK/N；导出CJ/FP/CLASS/GRAD/CS，不直接显示 | R2 IF01…07/C0；tb_canny_stream_top |
| rtl/r2/canny_stream_controller.sv | C0七状态、job_snapshot/fe_cancel_sent/真实八口计数/原FS/错误/CS | C0全部状态/优先/CASE；tb_canny_stream_controller |
| rtl/r2/gaussian5x5_pair.sv | 四行历史/读pending/纵和/横历史/最终舍入/尾重放，输出G8 | R2 OP02及采纳G-W；tb_gaussian5x5_pair |
| rtl/r2/gradient_direction_pair.sv | D1检查/abs、D2…4整数方向、独立held DERR | R2 OP03/C0 DIR；tb_gradient_direction_pair |
| rtl/r2/canny_fork_pair.sv | 单held+两pending，独立实际fire，不拥有job生命周期 | R2 OP04/IF05；tb_canny_fork_pair |
| rtl/r2/nms_window_pair.sv | 两行16bit容器历史/byte平面/288bit pair窗口及中心标志 | R2 OP05/采纳N-W；tb_nms_window_pair |
| rtl/r2/nms_classify_pair.sv | 两级比较/外框抑制/严格TLTH/class，无全帧闭包 | R2 OP05；tb_nms_classify_pair |
| rtl/r2/r2_pattern_pair_source.sv | 锁定图样/故障/q/r/FP held，真实输入fire推进 | OBS C/OP01；tb_r2_pattern_pair_source |
| rtl/r2/r2_job_supervisor.sv | CJ提出/源终结/正常与故障flags/取消/终态CRC反馈/k耗尽 | OBS C/OP03及C10；tb_r2_observer_supervisor |
| rtl/r2/r2_result_crc_observer.sv | typed仲裁/608record/19分组CRC/前缀检查/完整CS/last | OBS B/D/OP02/04；tb_r2_observer_supervisor |
| rtl/r2/r2_led_status.sv | last_complete_ok与滚动CRC到两LED，单driver/enable | OBS OP05/F；tb_r2_algorithm_top |
| rtl/r2/r2_algorithm_top.sv | SRC/J/K/R2/reset/LED及四个真实pin，不引用旧R1外壳 | OBS A/F；tb_r2_algorithm_top/生产map/PT/STA |
| model/canny_stream_reference.py | 独立完整Y/M/G8/Gx/Gy/Mgrad/dir/NMS/class数学，返回新结果 | R2共同数值/逐图oracle |
| model/r2_observer_reference.py | 图样纯公式/608布局/逐bitCRC/独立fixture终态规则 | OBS共同数值，禁复制32bit展开/FSM |
| model/r2_vectors.py | 输入值域/套件/manifest/向量I/O/CLI；不承担数学推导 | FILES F/G，异常/数量/hash/目录验证 |
| scripts/run_r2_sim.ps1 | 已有工具定位/编译/展开/有限cases/实测结果/日志与WLF | FILES-REQ03；不构建旧整机、不安装或改许可 |
| scripts/run_r2_build.ps1 | 生产PT/综合/PNR/STA/bit阶段及完整日志/结果核查 | FILES-REQ04/OBS-T08/09；失败即停bit |
| project/r2_algorithm.xml | Ti60F225/I3/SV2009、生产参数、唯一源码和顶层 | 不能引用sim/model，实际project schema实施时核 |
| project/r2_algorithm.peri.xml | J2/P13/N14/P14及bank/GCLK/方向/电气 | OBS F及原R1 D/E5软件引脚证据 |
| project/r2_algorithm.sdc | 40ns clock和两级CLR精确异步例外，其余内部路径计时 | OBS F；不得以慢CRC放宽多周期 |

测试文件在sim/r2/：tb_gaussian5x5_pair.sv、tb_gradient_direction_pair.sv、tb_canny_fork_pair.sv、tb_nms_window_pair.sv、tb_nms_classify_pair.sv、tb_canny_stream_controller.sv、tb_canny_stream_top.sv、tb_r2_pattern_pair_source.sv、tb_r2_observer_supervisor.sv、tb_r2_algorithm_top.sv。未来若需要测试公共纯decoder，只在上述合适TB核包布局，不为一个bit断言额外建框架。

这是核心流段+OBS清单；B03的新按键/config/renderer/replay文件尚待其设计并入，不能据本表将B05标READY。

## D. 逐连接及复用的必要适配

| IF | 上游→下游及逻辑payload | 明确适配/保持/结束 |
|---|---|---|
| FILES-IF01 | 外CJ142/FP74→C0/FE | 同R2 IF01/02；C0唯一FJ/FS owner；FP原接口无三ID，归属锁定ctx |
| FILES-IF02 | FE FO139→Gaussian Msrc137→新G8窗口 | FO edge2明确丢弃，M16+side121保留；ctx直到CS实际消费，不将其借用提前释放 |
| FILES-IF03 | 原window3x3_pair的144窗口及中心25→原sobel_pair→D S187 | 每个内部模块三ID由本job不可变ctx关联；F4诊断Gx/Gy/L1各22与out_valid/ready同组，按lane11拼66+side121；私有S采用SOBEL/T0，中心M/edge不用，不修改共享F4端口或FE默认行为 |
| FILES-IF04 | D191→FK→N153 / GRAD185 | N为两lane各16bit幅值/方向容器；grad为两lane各32bit signed布局；不能按同一个payload解释 |
| FILES-IF05 | N153→NW409→CLASS125 | NW=两个9×16bit窗口288+side121，lane0低144、每lanea最低16/i最高16；N1/N2消费一次，不把窗口读回当新像素 |
| FILES-IF06 | DERR120/真实接口事件/原FS163→C0→CS592 | 计数与错误沿前实际fire；DERR独立held/ready，data_flush不撤未消费错误；CS原字段保持 |
| FILES-IF07 | CLASS/GRAD/CS→K608→CRC/last→LED | OBS三typed口/位序/仲裁/19沿/flags合同；J不另保存完整CS；真实terminal_done后才新job |
| FILES-IF08 | reset/项目/peri/SDC→所有本域模块 | 全域同步高rst/fire屏蔽；只有KEY到两级CLR异步；无虚拟算法pin |

Gaussian四bank各一份原line_store_pair，合8RAM。NMS每行low/high byte分别一份line_store_pair，两行共4实例/8RAM；low plane的pair低8为lane0低byte、高8为lane1低byte，high plane同理重组为每lane16，所有使能/地址同事件。新G8窗口两行共4RAM，FE8结构预算合28RAM。不为了保预算而keep无用逻辑；实际合法裁剪和必需行历史分别核查。

同名共享SV模块只编译一次。C0的私有start/data_flush到R2新窗口/Sobel，与FE自己的start/flush不能串成第二owner；同一物理源码可多实例，各实例历史/valid独立。RAM地址永远受q/phase约束，不从未经核验payload直接选bank/地址。

## E. 中文操作和实施次序

FILES-OP01：先核整包指定批准/有效来源hash/工作副本权限/数据库前置及许可→建立唯一新run目录→核R1共享源码版本→编译vendor RAM模型和共享FE一次，再编译R2包/子级/C0/wrapper及外壳；源码读回和符号关联登记，不将文件存在视为实现通过。

FILES-OP02：先按G分别验证Gaussian/方向/NMS/fork和C0真实事件→wrapper小图组合→完整生产数学→SRC/J/K typed错误/取消/终态→真实R2生产fault和恢复。观察器测试可驱typed端口，整体验证必须实际接C0，不能force其FS/CS/done。

FILES-OP03：数值模型先核输入范围/长度/维度→调用独立整图计算→按坐标导出各阶段→manifest最后COMPLETE。TB握手记录独立数值/协议账本；成功恰P组、故障按预声明前缀政策及真实事件核验，不能抄CS计数作自身监测。

FILES-OP04：真实生产工程编译后核PT/综合/资源/算法到CRC到pad扇出→PNR→完整STA/setup/hold/精确例外→全部必需条件成立才bit。保留各阶段原日志/退出码/警告/报告及source hash；bit产物登记staging后停止。

FILES-OP05：任一失败立即报告具体case/首错/数量/工具阶段，不自动修改manifest/期望，不清理旧目录；设计边界变化先回对应REQ/IF/OP，再修订审阅。B03/全帧/生产视频未冻结期间，不把本地流段通过扩成全任务通过。

## F. 语言、向量与对应

SV2009可综合子集、沿前fire/沿后非阻塞提交、显式signed lane和先扩位；所有子级沿R2 F/C0§9/OBS G的RTL A–L，位宽/保持/取消/ctx/存储与时序分别按D定位。共用代码不意味着共用实例状态。Python3.14.6标准库；C++未选用，N/A。纯函数先验证完整输入，拒绝bool冒充整数、超范围、坏尺寸/数组长度，不改原输入，不共享可写结果；I/O只在r2_vectors调用层。整数任意精度后显式核理论界限，导出signed11先核−1020…1020再二补码；无浮点atan或隐式截断。

模型候选接口为canny_stream_image(rgb,width,height,median_enabled,tl,th)：返回新字典y/m/g8/gx/gy/mgrad/direction/nms/classes，各长度W×H；median/tl/th非法整次拒绝。gray/median调用同版本frontend_reference的纯数学接口；G8直接25项夹紧卷积，Sobel直接整图邻域式，NMS直接原Mgrad邻居，不复制RTL ring/pending/19比较器。参考同文件另提供纯数学入口nms_windows_image(mgrad,direction,width,height)：先核完整长度/合法尺寸/整数Mgrad0…1530、direction0…3，再对每个(x,y)各自clamp九个原图坐标，将每项Mgrad/dir组合成规范16bit容器，返回新建行优先list、每元素为a…i九项不可变tuple。它保留外框原幅值、高3bit0，不作NMS抑制，不复制RAM/byte平面/水平历史；vectors仅把两个相邻窗口按FILES-IF05打包288bit并附sideband。NMS窗口单元期望由此直接数学入口产生，非从DUT读回导出。参考保留完整图，不受retain影响；retain只决定硬件该支是否必需比较。CRC参考逐bit608、非反射poly04C11DB7/job初FFFFFFFF/终态末xorFFFFFFFF；独立于RTL32bit分组。

向量沿FE F1的UTF-8无BOM/ASCII小写hex/无0x/一行一pair/严格行数与EOF。套件名r2-stream-v1、r2-observer-v1，case_id/RunId仅字母数字下划线短横线；目录必须新建、路径限新run目录内，拒绝绝对向量路径/..。manifest含schema1、实际设计/全部引用RTL/模型/vendor模型hash、suite/固定种子、尺寸/三ID/TLTH/median/retain/pattern/fault/scenario、stimulus/expected数量及输入/阶段期望文件hash，最后才COMPLETE。每个向量文件另记独立文件条目{kind,bits,digits,rows,sha256,schema_version,path}，rows为正整数且必须等于该文件实际行数；无文件的可选分支明确标NOT_REQUIRED，不用空文件/rows=null暗示完整。不能把job的expected_pairs与oracle文件行数混用。

| 向量kind | 有效bit / hex字符数 | 未用高位及位序 |
|---|---|---|
| cj | 142 / 36 | 两高bit0；按C0 CJ低位表 |
| fp | 74 / 19 | 两高bit0；按原FP，像素无逐pairID |
| msrc/g8 | 137 / 35 | 三高bit0；pair16+side121 |
| sobel | 187 / 47 | 一高bit0；两laneGx/Gy/Mgrad66+side121 |
| direction | 191 / 48 | 一高bit0；按R2 IF04 |
| nms_input | 153 / 39 | 三高bit0；两个16容器+side121 |
| nms_window | 409 / 103 | 三高bit0；按FILES-IF05 |
| class | 125 / 32 | 三高bit0；按OBS CLASS低位字段 |
| grad | 185 / 47 | 三高bit0；按OBS GRAD低位字段 |
| derr | 120 / 30 | 无高padding；按C0布局 |
| cs | 592 / 148 | 无高padding；原FS错误字段完整 |
| record | 608 / 152 | 记录自身typed padding按OBS；不添加另一份status截断 |

新向量schema FILES-F-SCHEMA-v0.1统一定义：某阶段有效payload为B bit时，低B位放payload；其后x_even为[B+10:B]、y为[B+21:B+11]、epoch为[B+53:B+22]、frame为[B+85:B+54]、config为[B+117:B+86]，SOF/EOL/EOF依次B+118/B+119/B+120。Msrc/G8的B16、S187的B66、D191的B70、N输入的B32、NW409的B288、CLASS的B4、GRAD的B64。该统一向量打包不修改原共享FE/F4端口；适配器明确从原独立端口组装/拆分。

S低66位按lane0 bits32:0、lane1 bits65:33，各lane Gx[10:0]/Gy[21:11]/Mgrad[32:22]。D保留相同低66位，再dir0[67:66]/dir1[69:68]；不能把新增dir挤入原signed梯度。N输入每lane16为Mgrad[10:0]/dir[12:11]/高3bit0；NW每lane9项row-major a…i、每项沿同一16容器。CLASS/GRAD的低payload及sideband由本公式还原的位号必须与OBS B逐位一致。CJ/DERR/CS完全采用C0现有逐位表，不另创建不同同名schema。

各阶段sideband逻辑布局由此表明示，软件导出同时给schema名称/版本，不因两个payload都含121bit而猜字段位置。原F4三对22bit诊断值按Gx pair/Gy pair/L1 pair解包；D输入两个lane各Gx11/Gy11/Mgrad11的语义组织不能直接把66bit物理总线原封接错顺序。

成功case expected_pairs=P；故障case预先声明prefix_policy和expected_reason/定位/输入注入，阶段/输出完整数量不适用时expected_pairs=null，不运行后改manifest。此null仅表示不要求完整硬件交付量，每个已声明oracle文件的rows仍必须明确非空。正常和真实源fault的完整数学oracle每阶段rows=P，实际已交付前缀按坐标查这份完整图，不要求故障DUT交付或比较所有P行；输入刺激文件的rows独立描述候选数量，不从实际接受数推断。typed组件fixture的期望文件按其预声明事务数设rows，不套图像P。所有文件在测试前严格读取/校验声明条数和EOF，文件验证不代表每条被硬件接受。实际输出前缀仍以原完整数学图相同坐标比较，独立事件账本核上下界/EOF/错误/CS；真实fault的CS可依调度有不同前缀，不伪造一份固定CS期望：manifest保存不可变terminal_policy，独立TB口事件账本及参考规则计算所需计数/码/位置/EOF关系，再比实际CS；不得直接复制DUT CS字段生成期望。cs/record固定hex期望用于预声明的typed组件fixture。对故意注入坏payload的typed组件case，只在声明的字段/位置豁免对应数学检查，其余协议照常失败。同步rst作废旧job不期待CS，随后完整新job必须正确。超P/非法class等无效记录用预声明typed期望核错误，不伪称其完整数学图有效。

共同数值/硬件执行/对应三份分别沿R2 F和OBS G；数学期望按三ID/中心坐标逐lane查表，延迟不作为身份。CASE/TEST都仍是文字计划。

## G. 验证与运行器边界

| TEST | 目标和输入/期望 | 直接通过条件及未来文件 |
|---|---|---|
| FILES-T01 | 文件清单/重复模块/包布局/向量高位/严格行数；按D/F | 编译引用唯一源码、所有bits/解码正确、无额外或短条目；全部单元TB/向量CLI |
| FILES-T02 | Gaussian/方向/fork/NMS各普通/边界/停顿/flush、共享RAM地址/读回 | R2-T01…07逐位/事件；各相应单元TB，不靠wrapper单个CRC |
| FILES-T03 | C0七状态/早FS/DERR/held FJ/旧cancel事实/错误并发/CS held | C0-C01…21及T01…08，独立口账本；tb_canny_stream_controller |
| FILES-T04 | 真实wrapper6×5及其他合法边界、全1920×1080 median×retain四组合 | R2-T06/07/08，生产每必需口P、每像素逐阶段比较；tb_canny_stream_top |
| FILES-T05 | SRC图样/64普通+64fault小job、W258/H258、typed CRC/仲裁/C10 | OBS-T01…06，各record/CS/flags/原FS逐位；SRC及observer/supervisor TB |
| FILES-T06 | 真实生产半帧fault retain两态及故障后新job | OBS-T07真实短前缀/定位/EOF0/CS关系及新历史恢复；tb_r2_algorithm_top和wrapper |
| FILES-T07 | Questa编译/展开/真实执行/结果结构/超时及许可错误 | required case全部finished/compared量达标/无未豁免错误，缺任何项非零；run_r2_sim |
| FILES-T08 | 生产PT/map/PNR/STA/bit及原日志/hash | OBS-T08/09真实pin/路径/资源/必要历史/合法裁剪与产物，bit后停止；run_r2_build |

所有TEST NOT_RUN。通用核测试可10ns时钟；真实外壳reset/LED时基及物理工程40ns/25MHz，不能把10ns仿真当100MHz实现通过。固定数学/协议种子继承FE0x431/0x1060，协议调度每下降沿更新独立LFSR并最多8沿连续人为停顿，已经提出held valid不能因随机位撤销；非法case只豁免指定注入。生产四组合覆盖结构边缘/斜边/固定种子扰动，不靠常量0的单帧通过，精确向量套件表仍需独立审阅。

run路径固定r2/sim/r2/runs/<RunId>/，先建run根，模型新建其不存在的vectors子目录；编译库/WLF/log/result/hash都在run内。build路径r2/build/runs/<RunId>/新建，不覆盖历史。调用工具参数逐项传入，禁止字符串拼接再交另一shell；不运行原HDK含删除脚本、不安装/换仿真器/改全局许可/写工具目录。

CLI参数/范围错退出2；I/O/内部校验/子进程非零/许可失败/超时/缺报告退出1；只有完整必需集合及结果结构达标退出0。每case至少report case_id、accepted各口/observed EOF、delivered/compared、numeric_errors、protocol_errors、reason、finished；status字段记录真实值而非期望替换。仿真器console/WLF/tool版号及实际退出保留；不得靠最后一行PASS认定。

超时必须有限且基于manifest数量与注入停顿：OBS record每条20沿服务加窗口尾/启动/终态，成功最多2P+1条；故障按已声明源位置及有限各级容量另预算，不能等待P。原进程挂起由run_r2_sim所启动的具体句柄超时处理，不杀不相关进程。首次实施需将确切模拟cycle上限和wall deadline写入run manifest；许可缺失或模型不支持保留失败，未经批准不换工具。工具真实命令/报告格式由现装CLI只读核对后按批准范围实施，不在本页伪造已执行命令。

bit仅在全部必需功能/生产物理条件满足后允许生成。复制产物的既有审批仍需满足；未来staging登记source/project/peri/SDC/工具/命令/退出/原报告/bit hash与范围，validated/canonical或硬件PASS不自动升级。

## H. 双向追踪

| REQ | 文件组/IF/OP | TEST | 当前实际证据 |
|---|---|---|---|
| FILES-REQ01 / R2-REQ01…09 | RTL表/FILES-IF01…08/OP01 | T01…06 | C0/OBS及R2设计，0源码 |
| FILES-REQ02 / R2数值/OBS-REQ05 | 三model文件/IF02…07/OP02/03 | T02…06 | 独立算法/向量文字合同，未执行 |
| FILES-REQ03 / B5 | sim各TB/run_r2_sim/OP01…03/05 | T01…07 | 有限case/退出/目录合同，未生成 |
| FILES-REQ04 / OBS-REQ04/05 | project三文件/run_r2_build/OP04 | T08 | 40ns/四pin设计，工具未运行 |
| FILES-REQ05 / 全十一项 | B03/R3/R4/R5另补文件及接口 | 对应整包BAT-T03…07 | OPEN，不冒称完整交付 |

反向每个C表文件回本表及主R2/附件的具体责任。实际代码/hash/源码符号/波形/报告路径仅获批后填写；目前稳定符号是计划名，不是假造实现位置。

## I. 门槛与审阅

行为/职责/接口、复用调查、中文顺序、语言/向量/验证/追踪已给实质内容；本页尚待独立审閱及完整向量套件/确切timeout/工具引用核对，B03及跨批文件仍缺。因此NOT_READY，B05仍OPEN，不向用户请求本页实施批准。继承模板十项门槛，不把文件表齐全当全部局部语义完成。

## J. 变更与恢复

新增候选文件合同不改R1/FE共享设计。若F4診断端口、NMS byte布局、包schema、源隔离、向量位序/错误政策、工具/目录或计数上限改变，先回D/F/G修订并审閱；重大行为变化不能沿旧批准。恢复实际读回当前主稿、附件、来源和批准，再核引用的共享源码hash。

## K. 实录

本轮仅设计文档、只读来源及文档核对；业务源码/参考模型/TB/功能脚本/project/peri/SDC未生成，仿真/综合/PNR/STA/bit NOT_RUN。原HDK/正式Manifest/H0/数据库保持；不调查指定器件、不安装/网络/硬件操作。

## L. 中文阅读次序

整包B/C/D→R2整体→C0/OBS→本B目标→C文件责任→D真实交接→E推进→F三份语言/向量→G核验→H反向定位。获批后在每个文件首部中文注释说明其IF/输入/旧状态/保持/结束和稳定符号，配合真实操作记录，不能复制全部设计思考作注释。当前理解验收待用户反馈。
