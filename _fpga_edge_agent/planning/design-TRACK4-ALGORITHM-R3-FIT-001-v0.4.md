# TRACK4-ALGORITHM-R3-FIT-001：拟合、交点与距离设计 v0.4

设计状态：LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。

## 通用计划字段

- Goal：实现kind11/12/13/14/15/17/18，补齐独立圆LS、TLS细线、交点、精确两类距离与最终统计诊断，为完整圆/任意旋转矩形识别服务。
- Current state：kind0–7已交付，kind8/9/10/16设计v1.1待批准；本七项仍仅设计。完整目标和原1080p要求保留。
- Target state：先局部中文语句草图和完整接口，再按指定版本批准实现，模块单测→真实调用链/观察顶层→物理验证→bit登记后停止硬件步骤。
- Gap / Open questions：F-B01私有交接已设计；本版补F-B02父状态/逐项调用与形成预算、F-B04首错候选矩阵；F-B02/04仍需组合审阅，F-B03文件/来源/验证/基线仍未冻，没有READY或实现批准。
- Assumptions：父同域、可暂停、单外部事务；W偶数6…1920/H5…1080，N=W·H。输入是冻结统计或量化几何，不在本核重新选择支撑。
- Dependencies：根v0.2/模板、R3总稿/原NUMERIC、当前scalar原字节；数学补强和手算案例见[数值审查](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/03_review/r3-fit-distance-math-review-v0.1.md)。不以DDR模型为本算术核前置。
- Milestones / Detailed steps：B整体→C交接→D格式→E子操作/slot→F语言/预算→G文件/验证→H追踪→关闭B项→READY→指定批准。
- State transitions：父IDLE→CHECK→PREPARE/ISSUE→WAIT_RETURN→QUALIFY_RETURN→ADVANCE/LOCAL_COMMIT→下步骤或PACK→HELD→IDLE；取消/错误经DRAIN。私有bridge IDLE→CMD_CHECK→SEND→WAIT_CHILD→CHILD_CLOSE→RESULT_HELD→IDLE，未发child时本地结果直接RESULT_HELD。
- Artifacts and hashes：本稿、数值审查、子运算v0.1/v0.2与首错/预算附稿v0.1，引用源hash在A；尚未冻结实施基线、源码/工具清单。
- Validation / Failure handling：G全部NOT_RUN；数值域外/退化与输入/内部破坏分开，私有义务收尾后才能返失败/取消；工具失败保留证据。
- Human approval gates：READY后需明确批准版本/范围/基线与本批本地审计。旧R3 scalar及角度设计都不自动授权本核；正式DB和硬件状态不改。
- Rollback / Completion criteria：未来仅新独立work；原资料/既有实现只读。当前交付标准是可读设计与明确缺口，完整软件完成仍需实际全部实现/验证。

## A. 来源、模块位置与剩余阻塞

本批是A6数值部分，保持NUM_REQ622/RESP585和NUM_ID176，不接旧phase_key或543/540接口。真实来源：R3总稿SHA6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D、NUMERIC SHA17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A；本轮D2/E4–E8与原E4/E5/E6实读。现有scalar_core全文实读，SHA DAA31292536F4860C23DE5CFAF73AC444CD18B2AB5E9D2ED9C9B8092217EA0F0。

| 阻塞 | 下一步与影响 |
|---|---|
| F-B01 / DESIGNED | 本版D2/E6冻结候选交接：原字节scalar、406位命令/403位缓存、独立递增private序号、child关闭后返上层；设计已明确，尚未批准/实现/测试 |
| F-B02 / REVIEW_PENDING | 子运算草图v0.2保留等价floor路线与4项K/M缓存；新增errors-and-budget-v0.1第4/5节11父状态、七kind调用分解及source-derived primitive沿数。TLS最多46、有限边26；父局部控制/取消组合仍需最终审阅 |
| F-B03 | 全文件/参考/TB/probe、随机/确定场景、源码与工具基线未冻结；新增独立容器10782bit（含父待接纳406命令）及25MHz/资源/真实STA路径候选预算，尚未执行/实装 |
| F-B04 / DESIGNED_REVIEW_PENDING | 新附稿第2/3节列共同首错、输入域及每个已形成计算守卫。n低于最少支持提议局部COUNT7，n>N帧COUNT7；坏normal按原文帧INTERNAL，宽商后才局部GEOM_RANGE；待组合审阅，不冒充已批准 |

R4支撑、profile/质量、候选排序、目标去重和生产存储是后续明确范围，不通过此核数值PASS代签。当前可以独立补齐上述内部设计，不需要先实现程序求结果才READY。

## B. 整体外部行为

| REQ | 数值/事务保证 |
|---|---|
| FT01 | 一笔622请求原子接纳，一笔585结果保持至消费，冷reset共同作废单列；不收第二父请求 |
| FT02 | kind11圆中心/n/quality；kind17只n/quality，不算或检查未使用中心 |
| FT03 | kind12规范Q30 normal/tangent、rho/μ/anis/K/M；kind18仅n/anis，无新几何域门 |
| FT04 | kind13两Q30细线全宽交点，一次RNE，平行局部退化，几何域外有原原因不裁剪 |
| FT05 | kind14精确RNE(|f|/sqrtK)与K/M；kind15有限边原N/D与精确RNE sqrt(N/D)，两类K守卫不同 |
| FT06 | 私有算术先完整结果、再类型/几何资格；无回绕/饱和/近似norm直接定inlier；typed目标不足不改变错误语义 |
| FT07 | 匹配取消保留旧child握手/held响应，关闭所有私有义务后父DROP；旧父HELD全文不改；同域冷reset共同作废 |
| FT08 | 独立整数参考、协议/私有调用/slot追踪、实际模块与物理验证；不以旧scalar PASS当新父调度PASS |

样例详见数值审查：圆synthetic中心131072超过s18最高值而诊断58253有效；TLS synthetic μ12000000越域而anis65535有效；K1的有限短边距离合法。样例是代数/表示走查，未运行、不是真实图像质量集。

## C. 整体职责与交接

路径：caller —FT-IF01→父fit_core检查/统计快照→子步骤调度 —FT-IF04→private scalar_bridge —FT-IF05→只读复用scalar_core→完整算术响应→父写当前slot→继续/资格→FT-IF02响应。caller —FT-IF03→父cancel→bridge真实关闭。reset由同域共同作废，KEY外部同步仅未来probe处理。

父拥有外部ID、统计/几何、有限slot、首错和外部结果；bridge拥有一笔私有命令/实际child ID/目的与private序号，child拥有一笔算术快照。不能各自声称对方已消费，不能让同一个调用序号冒充全部私有调用。支持是父R4责任，本核不读点/DDR、维护profile或绘制。

本版选原字节复制scalar核心/pkg，新的bridge和父FSM属于新实现。原19状态数学及字段校验保持，私有scalar接口仍622/585；不另派生无ID算术核。额外403位结果缓存的存储成本在E6明确计入，不能隐入原5732bit预算。

组合检查：父必须在发私有命令前预留目的/结果消费能力；外部rsp_ready不能反向堵住旧child排空。父仅HELD时可外部反压，届时私有计算已结束。取消同沿先计旧cmd/child req/rsp fire，再禁新子命令；已valid child响应按原body收取并DISCARD。

## D. 接口与布局

外部字段沿R3：NUM_ID176/W11/H11/version8/kind5/flags2/target9/payload400；复合flags/target0、version1/owner0。返回原ID/kind/target/outcome/reason/value385，非VALUE全值0。各signed独立二补码，不将整个复合385bit sign_extend。

| kind | payload低到高 | VALUE低到高 |
|---|---|---|
| 11 | n21/A43/B s44/C43/D s56/F s56/det_min16/zero121 | cx s18/cy s18/n21/quality16/zero312 |
| 12 | n21/Sx s33/Sy s33/Sxx43/Syy43/Sxy s44/anis_min16/zero167 | nx/ny/tx/ty各s32，rho/μ各s18，anis16/K65/M33/zero107 |
| 13 | 两组nx s32/ny s32/rho s18共164/zero236 | xQ4 s18/yQ4 s18/zero349 |
| 14 | nx s32/ny s32/rho s18/x11/y11/zero296 | q21/K65/M33/zero266 |
| 15 | Ax/Ay/Bx/By各s18 Q4、x11/y11/zero306 | N78/D39/q19/zero249 |
| 17 | n21/A43/B s44/C43/D s56/F s56/zero137 | n21/quality16/zero348 |
| 18 | n21/Sx s33/Sy s33/Sxx43/Syy43/Sxy s44/zero183 | n21/anis16/zero348 |

所有数量与padding已按400/385求和；n上界N、原图point x/y域、normal守卫及首错见新增F-B04附稿，仍需组合审阅。独立核不追加目标尺寸/个数/噪声的验收硬界限。

### D2. 父到bridge、bridge到child的明确接口

| IF | 方向/低位到高位布局及事件 |
|---|---|
| FT-IF04命令 | 父→bridge：destination8/op3/a_signed1/b_signed1/target9/A192/B192，共406bit；cmd_valid/cmd_ready各1，正沿fire原子接纳。parent目的0…15对应工作槽，bridge不解码槽语义 |
| FT-IF04结果 | bridge→父：destination8/outcome2/reason8/value385，共403bit；result_valid/result_ready各1。RESULT_HELD body不变，实际fire后下一沿才接新命令 |
| FT-IF04取消 | 父→bridge abort1；只作用于唯一当前命令或本沿cmd_fire。父已按外部完整NUM_ID判断匹配。abort=当前父取消，或已有父错误需关闭私有义务；不得把错外部ID转为abort |
| FT-IF05请求 | bridge→原scalar：622bit，W1920/H1080/version1/kind={高2零,op3}/flags/target/payload={A192,B192,zero16}；root操作B必须由父给0，bridge不静默改输入 |
| FT-IF05响应 | 原scalar→bridge：原585bit及valid/ready；匹配完整private_ID176、kind5、target9和结果矩阵，原body真实采样/消费后再缓存403bit |
| FT-IF06 | 同域clk/rst，rst同步高且父/bridge/child/caller/consumer共同作废；child_quiet从真实原scalar取得。bridge_quiet仅IDLE且child_quiet且非rst |

private_ID176低到高为epoch32=1/frame32=0/config32=1/owner8=0/call_seq64/destination8。这是桥内部纯算术运行域，沿用已交付scalar观察核的合法数值context；不是外部图像job身份。其W/H固定合法值不参与primitive数学，父自己的W/H仍用于n/坐标/几何。private序号从0开始，在实际child_req_fire才增加，全冷reset重新开始独立运行域，正常操作不因更换父job而重置。MAX序号可以真实发一次，然后exhausted置1、计数保持MAX；以后的已接纳bridge命令本地FRAME_FAIL/CAPACITY9，绝不回绕。

桥保存已接受命令406bit、next_seq64、实际pending_seq64；其余private ID字段从上述常量和旧命令destination构造，不额外复制176bit。父完整外部ID只在held_request中持有；从桥cmd_fire到桥result_fire/quiet，父必须保持此context和目的预约，取消也不提前释放。验证日志在真实私有fire记录当前父ID与private ID的映射，不以destination冒充序号。

验证记录必须同时有接口域outer_fit/private_scalar和节点名，两个域的176bit位模式偶然相等也不能混为同一个事务；当前child只有桥一个入口，没有外部NUM调用并发共享。未来整包共享同一算术核时需独立设计仲裁/映射，不能直接并接这两个域。

隔离bridge测试允许静态RESET_SEQUENCE参数，默认0；可设MAX−1验证尾两次接受和第三次CAPACITY。生产fit_core实例固定默认0，参数不是运行时控制端口，测试不可force真实私有计数。所有固定ID复用只有整域冷reset、旧义务共同作废的例外，不适用于有外部DDR债的暖复位。

桥的子响应矩阵：VALUE0/reason0；FRAME_FAIL2/reason2/3/8/11/12/13且value0；CANCEL_DROP3/reason0/value0且该命令确有abort。其余outcome/reason、错ID/kind/target或非VALUE非零payload为INTERNAL13。实际原始child响应在监控账中保留，不能被bridge错误码替代原事实。格式合法的child FRAME_FAIL保留其reason返回父，由父已发生首错和取消规则分类；本地序号耗尽为CAPACITY9。

桥有独立403bit缓存，消费child不等待父result_ready。child消费后还要见真实child_quiet才允许暴露桥响应；这只关闭已认证单事务纯算术FSM的私有范围，不证明外部物理对象或DDR关闭。隔离fake-child错误刺激若不能关闭，测试应失败并保留未决状态，不能称已完成匹配调用。

## E. 局部中文步骤、slot与有限循环

本版补充的七项[逐子运算与寄存器复用草图](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r3-fit-suboperation-sketch-v0.2.md)按LS→TLS→交点→法线距离→有限边排序，具体列私有target/目的/局部提交与诊断跳过路径。该附稿尚待完整审阅，不是已生成程序或微码。

### E1. 接纳、错误与结果

IDLE沿前fire锁完整外部消息；CHECK按尺寸→版本/owner/kind→flags/target→padding→本操作输入规则。错误不进入后项，取消覆盖未暴露错误而不改HELD。EXECUTE只使用当前已完成私有响应，完整值通过高位/符号检查再写目的；下一状态才能读新slot。PACK后HELD，外部fire后下一沿复用。

只存一笔输入/外部输出，拟复用16×192 typed工作slot；每步说明哪slot旧值仍活、哪个可覆盖。完整385 child结果不能直接低192截入工作区；检查后才收。超过192位的中间值若有必须先改变调度/容器设计，不能隐藏一个额外全宽缓存。

### E2. 圆LS/诊断

按逐步骤表顺序：输入计数与统计资格→T=A+C→AC和B²→s89 Δ/trace资格→T²→条件full交叉乘→Q4 Nx/Ny分子→完整RNE商→s18几何检查→完整quality→结果。kind17在T/Δ资格后直接quality，不走Nx/Ny。父中心商不请求target18，先保足够宽signed商，再分类GEOM_RANGE，见数值审查。

slot初案：w0T、w1Δ、w2T²、w3质量分子、w4Nx、w5Ny、w6/7两Q4分子、w8/9宽中心商、w10quality；暂存产品与后续写入寿命待逐子指令表明确。统计从原payload读取，不再锁第二份全统计。

### E3. TLS/诊断

形成s67 Cxx/Cyy/Cxy，先核Cxx/Cyy非负/域并分别收u64；Cxy保留s67做全宽PSD，成功后才查/收s65→u/v/D→Rq16→完整各向异性门/anis。kind18止于此，输出n/anis。kind12继续t85/L86→t<<30的宽商→规范normal→唯一t=(ny,-nx)→rho/μ完整单次RNE→s18检查→K/M→结果。

slot初案沿总R3：w0/1/2协方差（Cxy在PSD前s67）；w3/4 u/v；w5 D；w6 Rq16；w7/8 t；w9 L；w10/11 normal；w12 K；w13 M；w14 rho；w15 μ/anis可分字段。过期u/v或t何时可覆盖及trace/PSD临时值须F-B02列齐，不能假设16槽天然够用。

### E4. 交点/直线距离

两个normal分别全域/K守卫。交点先完整den，0局部退化；负den先扩位同时变号分子/分母。RNE完整商后s18域外分类，不能私有target18抢先变算术错误。

直线距离先f/K/M→q0→F4/上下奇平方乘K→至多±1修正→再次双边资格→输出q21/K/M。严格使用数值审查中的even/odd等号规则，不能拿近似q0直接决定inlier。正常坏normal原文为INTERNAL帧失败；这和有限边短K不相同。

### E5. 有限边距离

全宽p/d/K/z/c→K0退化→按z≤0/≥K/内部形成原N/D→DIV_FLOOR_U求t=floor(N/D)→SQRT_FLOOR求k=floor(sqrt(t))→完整4N与(2k+1)²D比较及ties-even→最终两边资格→原N78/D39/q19输出。因k²为整数，floor(sqrt(floor(N/D)))=floor(sqrt(N/D))，没有近似或少量位截断。原19轮二分作为独立参考/等价对照，不生成两套RTL。不能对短边施加Q30 K守卫。

真实整数几何两类距离不能到half-integer，推导见数值审查；等号政策由隔离helper合成输入验证，不能以非法normal/force私有结果冒充主DUT覆盖。

### E6. 私有交接、取消与reset

桥按旧状态case、非阻塞提交：

1. IDLE的cmd_ready只在非rst且真实child_quiet时1，不组合依赖abort；cmd_fire锁406bit，sticky_abort取本沿abort，进入CMD_CHECK。父不因取消撤回已valid的命令。
2. CMD_CHECK先考虑本命令abort：尚未暴露child_req_valid时可直接形成本地DROP；否则若exhausted为1形成本地CAPACITY；均无child接受。合法普通命令进入SEND，child_req_body从锁定命令和next_seq组装。
3. SEND保持全部622bit至真实child_req_fire，abort不撤valid。child_cancel_id此时用当前请求的private ID，child_cancel_valid随本命令sticky/current abort。接受沿先记真实fire、pending_seq和目的，next_seq加一或MAX置exhausted，再进入WAIT_CHILD。
4. WAIT_CHILD已有预留缓存，child_rsp_ready=1，不看父result_ready；真实rsp_fire时先记原响应并核完整ID/kind/target/矩阵。若命令abort，缓存DROP；否则缓存合法原结果或INTERNAL错误，进入CHILD_CLOSE。child本身已valid的body没有被重写，只是桥在尚未暴露自己的结果时选择其终态。
5. CHILD_CLOSE等待真实child_quiet，期间可把尚未valid的桥私有值/错误改为DROP。确认后进入RESULT_HELD，下一沿父才能真实result_fire；无真实quiet不得开始新命令。实际原scalar在其rsp_fire后提交QUIET，这个检查不以时间沉默替代。
6. RESULT_HELD全文403bit保持；abort不能重写任何旧outcome。父在结果有资格时观察WAIT，然后在QUALIFY_RETURN沿读取旧缓存、核宽度/类型并同时fire，将唯一目标写入slot；下一状态才读取新slot。取消/DRAIN时父result_ready保持接收能力，消费后DISCARD，不写业务slot。
7. result_fire后桥IDLE；bridge_quiet依真实child_quiet。父保持独立406位待接纳命令与command_published资格，取消DRAIN也须兑现旧valid；只有command_published=0、cmd_pending=0且桥quiet时允许PACK外部终态。桥不能把形成自己的valid当父已消费；父也不能把child消费当桥缓存已释放。

父abort同沿先登记旧cmd/child req/rsp/result fire，再停未发布的新子运算。若父未HELD且外部匹配取消，优先CANCEL_DROP；若仅内部已有首错，桥可abort旧私有计算，但父收尾后仍返回原首错而不是伪外部取消。已valid的父HELD全文保持。正常原scalar、固定返回缓存及父DRAIN无外部反压依赖时，从新外部取消到父DROP设计上界8个core沿；子核心停止到child结果、桥关闭/缓存、父消费/quiet/PACK分别计。工具/协议违例或无法关闭时不能把8沿当强行删除义务的许可，属于未来验证失败/未决。

共同cold reset才可清在途有效性，父/bridge/child/consumer一起记录作废。普通cancel不清旧身份/计数，不等待普通外部destination ready；隔离故障测试和真实原child结果分别记。桥位容器预算：cmd406、cache403、next/pending序号128、有限state/sticky/exhausted/资格约7bit，944bit，冻结候选上界1000bit；没有第二命令、第二结果队列或额外parent_ID副本。父总资源仍F-B03，不能用此局部预算当全核综合结果。

INV-B01一桥cmd只一个终态、共同reset作废单列；B02 child seq只随child_req_fire推进且不回绕；B03 SEND原请求保持、RESULT_HELD原缓存保持；B04 child响应消费先于child_quiet确认，先于桥valid，先于父result_fire，先于父slot下一状态使用；B05父context借用至桥关闭；B06所有旧fire在abort同沿仍记，未关闭不复用；B07 bridge接受=本地已交付+child结果已交付+live+reset作废，child接受/真实返回/匹配返回另分账。

## F. 语言与工程预算

本版新增[首错、状态与预算附稿v0.1](D:/大三/FPGA_verilog/_fpga_edge_agent/experiments/track4_algorithms_20261004/02_design/r3-fit-errors-and-budget-v0.1.md)：共同/逐操作矩阵→父11状态→逐项调用→现有child形成沿→全核容器→真实物理范围。它明确区分资料事实、待批准设计与未测预算；F-B02/03/04只按其实际闭合程度更新。

拟SV2009/Python整数参考，无C++/浮点。RTL A数值为D/E及附稿全宽guard；B正沿旧值/沿后提交；C/D外部和私有真实fire分别计；E held与预约返回不受外部stall阻塞；F计算沿/最大私有步数见预算附稿、局部组合仍F-B02；G共同同步cold reset与cancel分开；H所有threshold/W/H快照；I16slot和一结果、子运算表明确寿命、真实实现待核；J父/私有ID显式映射；K核同域/外部CDC不在本核；L25MHz/资源候选已列、最终工程/工具清单待F-B03。

共同数值、硬件执行、软件↔真实事务三份对应必须分别实现。参考直接大整数公式/整数平方根/精确有理平方比较，不照抄子状态机。slot≈3072bit只是候选存储，不当实际FF/旧5732bit总预算；bridge候选1000bit上界、4项K/M缓存654bit、child/body/观察顶层均另计，DSP/RAM/XLR与最长运算在冻结前列清。

新的候选预算：fit核8955bit＋观察核1827bit=10782bit容器，父待接纳406位命令和桥已接纳406位命令分别计，无大帧RAM；DSP≤8/RAM0/XLR≤50000为未来独立物理门槛。kind11/12/13/14miss/14hit/15/17/18最多private调用17/46/17/22/18/26/7/20；source-derived加权形成＋保守桥/父余量最高TLS9533沿，统一验证截止16384沿，25MHz候选。外部HELD等待不计，不合成强行超时删除；这些不证明整机资源/FPS。完整来源计数、假设与尚待审阅局部上界见附稿第5/6节。

## G. 实施与文字验证计划（尚未完整冻结）

候选文件职责：fit_protocol_pkg、fit_core、scalar_bridge、原字节scalar_core/pkg、reset_sync、fit_probe_top；独立fit_reference/fit_vectors、helpers/bridge/core/probe TB、sim/build/STA和三工程。具体文件名/总数、是否另复制scalar数学参考、private ID种子/边界testbench、实际probe来源与物理路径还未冻结，故不能生成。

| TEST | 已明确文字场景；全部NOT_RUN |
|---|---|
| FT-T01 | LS平行Δ0、条件等号/两侧、n最少与>N、正负完整中心/几何域边界；独立全宽式 |
| FT-T02 | TLS水平/竖直/斜线、u正负、PSD失败、trace/D0、normal反号、rho/μ一次舍入、anis门等号 |
| FT-T03 | 两个明确synthetic诊断案例：完整几何拒绝但kind17/18只诊断有效；不当真实图像覆盖 |
| FT-T04 | 交点den0/负den/近平行、宽商GEOM_RANGE与child算术溢出分层；法线字段/K守卫 |
| FT-T05 | q0近阈值/真实±1修正、精确资格/nearest不比q；隔离等号政策，不要求非法主normal产生VALUE；缓存cold/hit/四key/第五key替换、不同job/位置/rho、TLS规范安装、取消同安装与joint reset |
| FT-T06 | K1短边、z0/K边界、端点/内部、四边等距、floor除/根精确中点与独立19步predicate对照、N1/D2与N1/D5；整数几何half不可达分层 |
| FT-T07 | 私有command/req/rsp长stall、错返回ID/kind/target的隔离monitor反例、目的/slot有效性及不覆盖；不伪称真实child错误路径 |
| FT-T08 | 父cancel同私有fire/held、所有阶段与cold reset、计数耗尽不回绕、真实义务关闭后DROP |
| FT-T09 | 全1080p域及合成全宽统计、固定seed随机合法点集生成统计、独立参考/原响应计账、真正非零fatal退出 |
| FT-T10 | 真实probe所有七kind实际来源/消费者/CRC、复位恢复；同源物理资源/未约束/数据D路径与合理pins/STA，门槛通过才bit |

详细确定case/seed/采样规则/覆盖、工具entry/hash、runner失败/致错守卫及恢复路径需F-B03。没有这些不标READY。

## H. 双向追踪

FT01/07→父/bridge/child、IF01/02/03/04/05、E1/E6及预算附稿第2/4节、T07/08；FT02→LS/诊断E2、附稿第3/5节、T01/03；FT03→TLS/诊断E3、附稿第3/5节、T02/03；FT04→交点E4、附稿第3节、T04；FT05→两类距离E4/E5、子运算v0.2、T05/06；FT06→全值/窄化E/F及首错附稿第2/3节、T01…06；FT08→参考/probe/运行器及资源/时间附稿第5/6节、T09/10。实际符号/文件与反向逐单元表在F-B02/03闭合时回填，当前没有源码定位。

## I. 十项门槛与停止点

①B整体有内容；②C职责/复用已调查并选定；③D外部/私有布局及E6组合已明确；④E及附稿11状态/槽/首错有内容、组合审阅仍B02/04；⑤F语言/独立容器与形成预算已列、实施核对未做；⑥附稿正常/失败走查、原child计数有源码依据；⑦G/H文件/验证/追踪未完整；⑧尚F-B02/03/04；⑨保存读回及用户可查看，但不等于READY；⑩v0.4范围明确、实施基线未冻。结论NOT_READY，当前不请求该七项实施批准。

## J–L. 修订、实录与阅读

新纯设计，原来源/批准/已交付scalar和待批angle不变。v0.1原15556B/SHA D348769A2827DEB3C9125D3012F0537BAC1249126003495458344B9331D811C5保存为design-TRACK4-ALGORITHM-R3-FIT-001-v0.1.md；v0.2 SHA FC3D1AEB8A81A7B3EDACEC5808830D29A0ACDFDD7DFE5D54C661A8F029E27296保存为design-TRACK4-ALGORITHM-R3-FIT-001-v0.2.md；v0.3原23488B/SHA0DF72BF7E0F59FE426F399D53E4C9B8563E1CA2C862C59646B5EBA30C6E7F937保存为design-TRACK4-ALGORITHM-R3-FIT-001-v0.3.md。v0.3选等价floor路线/KM缓存；v0.4补首错/11父状态/逐项调用及形成/容器预算，并同步LS步骤次序与实际表一致。外部布局/完整目标不变；低支持COUNT分类是明确待批准提议，实际延迟/资源未测、未READY。恢复从源hash、附稿、B项、实际审批与源码差异开始；未来freeze后重要变化先修订指定批准。当前只保存文档，无RTL/参考/功能脚本/TB/EDA/bit/硬件/网络/DB。

按B→C→D→E1共同事务→E2圆→E3 TLS→E4/5距离→E6真实私有交接→F/G/H/I阅读。最终完整识别、Canny滞后连接、DDR生产资格、相机/HDMI/CDC/阈值/冻结/叠加及整包性能仍未完成；当前局部数学与设计不代替完整软件实现证明。
