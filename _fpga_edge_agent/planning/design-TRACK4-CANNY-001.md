# TRACK4-CANNY-001：完整Canny数值、连接、存储与父任务设计 v0.4

2026-10-04；**LOCAL_DESIGN / NOT_APPROVED**。本稿按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)编写，细化完整软件实验MOD-08及IF-08/09/10；数值选择、缓存和消息交接均为设计提议。尚未生成业务源码、参考实现、脚本或可执行测试，也未执行仿真、综合或布局布线。

## 通用计划字段

- Goal：在Ti60F225/1920×1080整机中完成Gaussian→梯度/方向→NMS→双阈值→精确八邻域滞后连接，供显示和圆/矩形识别使用。
- Current state：整体架构v0.1、FRONTEND v1、FRAME-MANAGER v0.1存在；Canny尚未实现。数学/所有权/有限性、窗口逐沿、cache/queue及父任务/方向/writer候选已保存；917bit job、23阶段和12区地址算术已有草图，真实父grant/fence/恢复、DDR及全机性能仍待闭合。
- Target state：完整且可批准的Canny局部设计，然后在指定批准范围内实现、逐位/协议测试、完整1080p及资源性能比较。
- Gap：窗口/存储/父任务与顺序writer已补齐候选设计输入；尚须与MOD-04/05/09/10/11统一实际grant/feed/租约/fence/恢复端口并冻结基线，真实PHY/地址映射与资源性能仍有缺口，见CN-B01…08。
- Assumptions：同域可反压的双像素流，目标100MHz；慢任务读完整源，采集独立继续。HDMI60Hz不代表Canny60fps。
- Open questions：实际父grant/fence/安全恢复端口、内存服务实证/上界、六源期限及识别租约、串行cache优化与实际性能；不恢复用户撤回的识别场景限制。
- Dependencies：[完整主计划](design-TRACK4-FULL-SW-001.md)、现行v0.2、FRONTEND、帧所有权、MOD-05/09/10/11相邻设计及匹配器件/PHY验证。
- Milestones：数值/连接选择→窗口/缓存/交接闭合→独立审查/冻结基线→READY→指定批准→实现/实际验证→整机整合。
- Detailed steps：A/B明确范围→C连接→D交接→E中文步骤和资源→F语言/映射→G/H验证追踪→I门槛。
- State transitions：当前LOCAL_DESIGN；不因数学公式或章节齐全升级READY；当前实施范围为空。
- Artifacts and hashes：原24项与FE28项输入使用既有清单；本稿及新审阅记录由05文档检查登记，不伪造Git commit或实施批准。
- Validation：只读设计/组合审查和文档读回；CN-T01…26为文字场景，全部未运行。
- Failure handling：任务失败不输出完整成功图；停止新增请求、结清已提出突发、排空后归还；不以超时清成FREE。
- Human approval gates：本稿尚有阻塞，不请求实现批准；FRONTEND实现及官方模型获取的既有申请独立待答。
- Rollback：仅本设计和实验索引/审阅文档；不改原HDK、正式DB/状态或FE冻结输入。
- Completion criteria：完整阶段、精确闭包、数值/时间/存储/取消契约、有限资源和独立验证均闭合，保存读回呈现后才READY；实际完成还需获批实现和真实测试。

## A. 状态、来源与批准边界

关联T4-A4及T4-A1/A6、DER-01…08。范围含Canny前级、分类状态图、工作队列、精确闭包和最终打包边缘；可选梯度工作图为识别依赖。CSI/RAW/Debayer、共享FRONTEND、相机非反压适配、物理DDR/PHY、识别决策及HDMI扫描不由本批实现，但接口必须满足其前提。

来源：[官方要求归纳](../docs/requirements/TRACK4_REQUIREMENTS.md)T4-A4、[整体02](../experiments/track4_full_sw_20261004/02_system/overall-design-layout.md)、[系统03](../experiments/track4_full_sw_20261004/03_interfaces/handoffs-and-composition.md)、[FRONTEND v1](design-TRACK4-FRONTEND-001.md)、[帧管理v0.1](design-TRACK4-FRAME-MANAGER-001.md)、[DDR事实](../experiments/track4_full_sw_20261004/01_baseline/ddr-address-and-completion-evidence-v1.md)。原资料来源/哈希在[整体清单](../experiments/track4_full_sw_20261004/01_baseline/baseline-manifest.json)和[FE输入清单](../experiments/track4_full_sw_20261004/01_baseline/frontend-baseline-v1.json)。

Gaussian尺寸、整数方向、NMS相等规则、阈值语义、状态/队列布局是本任务提议，不冒充官方逐位定义；官方要求全部阶段，但未指定这些具体数值选择。原资料只读、正式节点/数据库和硬件人工闸门继续有效。没有指定版本/范围批准，不生成代码或testbench。

## B. 整体外部行为与数值约定

输入为同任务的完整有限Msrc图，即FRONTEND Y_ONLY交付的灰度/可选中值结果，不把其edge=0视为Canny边缘。Msrc为8bit灰度，Mgrad=abs(Gx)+abs(Gy)为抑制前11bit幅值，Mnms为NMS输出；三者不能混用。生产1920×1080；小尺寸验证候选W为偶数6…1920、H为5…1080，窗口完整契约闭合后冻结。FRONTEND允许的更小尺寸不自动等于本批合法：组合入口必须在启动前拒绝W<6或H<5，不能通过只选择大图测试掩盖这个边界。所有输出保持原图坐标、两lane行优先顺序和三ID；外框像素的Canny分类/边缘明确为0。

尺寸提议与FRONTEND相同，按实例静态W/H参数生成；小图是独立仿真实例，生产仍1920×1080。job携带W/H必须等于该实例参数，不支持任务中动态改变行长；字段和候选拒绝路径见E6，CN-B06仍须统一父真实绑定归还。本稿不以参数范围文字宣称新窗口已经支持全部尺寸。

| REQ | 规则/来源 |
|---|---|
| CN-01 | T4-A4：所有五阶段完整存在；最终边缘等于强种子在强/弱候选图中的八邻域可达集合 |
| CN-02 | T4-A4：默认5×5二项式Gaussian，轴系数1/4/6/4/1；总权重256，仅最终+128后右移8，边界按有限Msrc图坐标夹紧 |
| CN-03 | T4-B3/A4：对Gaussian图构造新的3×3 Sobel，Gx/Gy signed11，幅值为abs和unsigned11，方向采用下述整数规则 |
| CN-04 | T4-A4：NMS比较抑制前Mgrad图，中心Mgrad>负向邻居且Mgrad≥正向邻居并Mgrad>0才令Mnms=Mgrad，否则Mnms=0，外框也抑制为0 |
| CN-05 | T4-A4：0≤Tlow≤Thigh≤2047；Mnms=0为NONE，Mnms>Thigh为STRONG，Tlow<Mnms≤Thigh为WEAK，其余NONE |
| CN-06 | T4-A4：全部强边作为种子，每候选最多接纳/入队一次；长链、环、分支、斜连接不截断 |
| CN-07 | DER-04/05：队列容量N、全帧任务和缓存有限；无固定轮次近似，最终结束需逻辑队列空与必需物理事务排空 |
| CN-08 | DER-01/03：配置、源/结果句柄、三ID不可变；源/算法/输出fence由MOD-10汇合，Canny完成不是显示发布 |
| CN-09 | DER-06/07：取消/错误不发布；已提出/接受的DDR突发必须完成，复位epoch不代替物理排空 |
| CN-10 | DER-08：比较真实资源、事务量和处理时间；共享行核、块缓存、邻居合并和安全快路径用于优化，不能缩减完整性或偷换显示fps |

图像坐标x向右、y向下。方向编码00=H，01=NW–SE，10=V，11=SW–NE；它们表示要比较的网格邻居，不用含糊的数学角度名称代替坐标。

令X=abs(Gx)、Y=abs(Gy)。Mgrad=0时方向00；否则若(Y×1024)≤(X×424)则H；否则若(X×1024)≤(Y×424)则V；其余Gx/Gy同号为NW–SE、异号为SW–NE。这是明确的424/1024整数分界，参考模型须使用相同整数比较，不能用atan结果替代。Gx/Gy某分量为0时必走H或V分支；不能因中心Msrc=0就强制方向00。

| 方向 | 负向邻居 | 正向邻居 |
|---|---|---|
| H | (x−1,y) | (x+1,y) |
| NW–SE | (x−1,y−1) | (x+1,y+1) |
| V | (x,y−1) | (x,y+1) |
| SW–NE | (x−1,y+1) | (x+1,y−1) |

NMS相等策略固定由网格负/正方向决定，不随梯度反号翻转。沿同一量化方向的[0,10,10,0]平台保留第一个10；全零/全等幅值没有正的严格局部极大。任意方向变化和复杂拐角仍须逐图测试，不能据此宣称所有输入都绝对单像素宽。

正常样例：一段超过高阈值的强边连着很长的弱链，完整链都保留；断开一个像素后远端无强种子的弱段全删除。边界样例：Tlow=Thigh无WEAK；Thigh≥1530没有强边，最终全0；(X,Y)=(128,53)归H，(128,54)归对角。坏配置Tlow>Thigh拒绝该job，不静默交换。

## C. 模块职责与整体连接

整体路径：FRONTEND Y_ONLY→C1四行/纵向Gaussian→C2水平Gaussian/单次舍入→C3新3×3窗口和Sobel→C4方向与分叉→C5幅值/方向两行窗口、NMS/分类→分类图写入fence→C6强种子及工作队列→C7精确八邻域连接→C8最终边缘打包/输出fence。C4的另一支在识别启用时写grad32工作图，识别读取fence后才可重用。

| 单元 | 职责、拥有者及界限 |
|---|---|
| C0任务协调 | 锁配置/三ID/句柄，及时消费FRONTEND终态，管理Canny各阶段和取消；不拥有源/结果最终回收 |
| C1/C2 Gaussian | 原8bit四行历史、12bit纵和和水平列历史；有限图补边，输出完整G8；不提前舍入 |
| C3梯度 | Gaussian的独立3×3窗口和Sobel；可复用计划F4算术/协议，不能复用pre-Gaussian的实时梯度数值 |
| C4方向/分叉 | 同坐标Gx/Gy/Mgrad/dir，保存各消费者尚未接收状态；不让一支停顿导致另一支重复消费 |
| C5 NMS/分类 | 只存Mgrad11+dir2邻域，输出每像素2bit初态及strong/weak数量；不在未完成分类上开始连接 |
| C6/C7连接 | 独占该job的状态缓存及队列；原子接纳/入队、精确遍历；不让识别/显示并发读取可变分类图 |
| C8边缘导出 | 全图行优先导出完整1bit边缘，包括显式0；写完成后给C0证据，不自行发布bundle |

复用调查：FRONTEND F4已设计六级Sobel并同拍交付Gx/Gy/L1，可在新Gaussian窗口后实例化其算术职责；F2可复用3×3 Y8窗口的契约。[窗口附件v0.2](../experiments/track4_full_sw_20261004/04_local-designs/canny-window-sketches-v0.2.md)另行规定5×5四行及13bit NMS的RAM布局和执行，不把既有8bit契约当作已支持这些宽度。IP/RAM原模型保持只读；模块尚未实现，不能称已有可复用代码。

优化选择：先纵向加权后水平加权，四行只保存原Msrc8，避免四行保存12bit水平中间值。梯度在分叉支路单独写图，NMS窗口只保留13bit，避免两行保存全部35bit Gx/Gy/Mgrad/dir。工作区一次只归一个Canny/识别job；grad32由父登记识别读租约，最后读fence及显式归还前不能重用；当前显示bundle不借用可变grad工作图。

## D. 接口与组合检查

以下为候选事务契约，未冻结完整RTL端口。所有非梯度字段unsigned；跨模块payload停顿保持。

| IF | 提供方→使用方；候选内容/位宽 | 前提、接受及保证 |
|---|---|---|
| CN-IF01 | 父→C0：917bit不可变job，三ID32×3、完整source/result/workspace句柄与64bit序列、W/H11×2、median1/TL/TH11×2、retain/recognition及四组base/L/A32 | 完整字段见E6/P-J01；同域valid&ready后核验范围及真实绑定，非法job不start/FJ/访问，走reject_pending/ABORT_DRAIN；仅可信未绑定或实际未启动返还证据齐全才REJECTED/drained1。描述符不是自授权，父grant端口仍阻塞 |
| CN-IF02 | FRONTEND→C1：两Msrc8共16bit、x_even11/y11、SOF/EOL/EOF、三ID | 仅实际握手推进历史/计数；与FJ接纳分沿；预处理终态独立及时接收；不能因FRONTEND尺寸合法就绕过Canny组合尺寸校验 |
| CN-IF03 | C3→C4：Gx/Gy每lane signed11、Mgrad11及中心坐标/标志/ctx身份 | 新Gaussian窗口后六级Sobel，四级方向流水D1…4先验证数值再扩20bit移位比较；末级容量驱动气泡/排空与保持，dir2及原梯度同组，见P-D01 |
| CN-IF04 | C4→NMS及grad writer：已对齐的Mgrad11/dir2、grad32及同中心标志 | 独立pending位/缓冲记录每支是否已接受；两支都完成才替换暂存事务；禁简单广播valid加两ready相与 |
| CN-IF05 | 分类/梯度/队列/边缘↔MOD-05及C0：内存事务、writer local_terminal、stage fence | MC-M01保持byteaddr32/nbeats7=1…64/tag16/128bit；P-W/P-F规定bank/两个共享W槽、每writer独立LOCAL_OK先于C0 fence、mask/完整scope。虚拟tag不接physical ID4；真实grant/fence/响应与slave仍未证，旧bank_sw不替代 |
| CN-IF06 | C5/C6→C7：分类2bit图、强种子/队列、strong/weak计数 | CLASS/必要GRAD local terminal已保存且CLASSIFICATION fence成功后才移交；GENERAL种子全N扫描/原子claim及SEED fence后才BFS。状态图唯一拥有者；队列逻辑可见性不等于DDR提交 |
| CN-IF07 | C7/C8→识别/完成汇合：完整边缘与可选grad32描述符、终态/计数/fence | 输出恰好N像素；识别只读已完成同任务图；成功空边缘合法，失败不可伪装空图 |
| CN-IF08 | 父/C0/子级：start、FE FJ/FS、feed_terminal、abort/ack、empty/status、安全恢复 | P-J/P-C规定各端口/23阶段/原因及冻结快照，独立保存FE/feed/local终态；ack不冻结后台。功能rst冲刷私有流但MC保持域继续valid/payload/pending与实际记账。恢复另需完整旧scope证明/返还事件；相邻实际端口仍BLOCKING |

分类像素i=y×W+x用2bit：00 NONE、01 WEAK、10尚未接纳STRONG、11 ACCEPTED_EDGE。初始C5不产生11。四像素打包一byte，i模4的状态在bit[2r+1:2r]；末byte未用bit为0。最终边缘像素i在byte内bit[i模8]，剩余位0；两lane都计入总数，不能省略0像素。

识别grad32候选布局：bit[10:0] Gx二补码，bit[21:11] Gy二补码，bit[23:22]方向，bit[31:24]=0；地址base+4i，低byte lane对应低地址字节的逻辑契约由MOD-05适配。幅值可从梯度精确重算，不额外保存一整幅幅值图。NMS丢弃点也保留其原梯度，但识别选择最终边缘点时应按同坐标取值。

组合约束：FRONTEND状态必须及时存入父任务，不能要求其等Canny完成才消费。分类fence之后状态缓存成为唯一修改者；不得绕缓存读旧DDR。结果发布仍需源有效和全部必需输出fence；Canny job OK不代替这些保证。DDR写地址提出前应备齐所选完整burst的数据，取消不能清掉已承诺的剩余W拍；未提出的部分积累可在job作废后丢弃。

阶段fence还有明确封口顺序：停止新增该阶段业务写，完成全部尾部打包/dirty writeback并把剩余请求实际交付内存服务，再建立覆盖这些已交付请求的fence，全部规定响应成功后才通过。若fence快照先于尚未接受的最后writeback，它不能证明阶段完成。前级empty、请求已接受、响应已排空分别保留证据，不用一个计数0混称。

## E. 局部数据、操作草图与有限性

### E1. 数值与存储表示

Gaussian纵和V的范围0…4080，用12bit；横向对V按同轴权重加权，未舍入总和0…65280，用16bit；加128后最大65408，仍16bit，右移8得到G8。移位/相加前按目标宽度零扩展，不能让8bit或12bit表达式先溢出。纵向和不写DDR，不提前除16。

Sobel四侧unsigned10最大1020；相减前扩展成signed11，梯度−1020…1020。绝对值unsigned10，求和前扩成11bit，L1联合上界1530。方向乘424=256+128+32+8，乘1024为移位；两边比较前统一unsigned20，因为1020×1024=1,044,480<2^20。不得对signed负梯度直接作无符号移位比较。

N=2,073,600。分类图518,400B；最终边缘259,200B；grad32可选8,294,400B；32bit队列容量N为8,294,400B。队列候选entry使用x11/y11及高10bit零，避免pop后做除1920；状态地址由y×W+x按足够宽度计算，静态尺寸可用常量移位加法，越界检查先于地址窄化。

与整体v0.1预算的差异：grad32比原“幅值16bit+方向8bit”合计多2,073,600B；新提议不要求保存一幅灰度图或单独visited图。若采用六RGB源、三1bit结果及单份class/queue/grad工作区，紧凑小计为55,209,600B，尚不含对齐、DDR保留区、识别工作区和其他图像。最终地址图必须重新核算，不能引用旧55,468,800B便宣称新布局不重叠。若选择增加源槽或保留多份grad，另增相应容量和租约。

物理权限范围不能只授紧凑字节数：状态区至少向上补到64B整线，queue/grad/edge至少补到16B整拍，基址按其访问粒度对齐。小图N不一定是4或8的倍数，partial末拍只能访问本工作区已授的padding，不能覆盖相邻图；逻辑数量仍为N，不把填充entry/bit计为有效。生产N恰为4/8/256的倍数也不能代替小图范围证明；CN-B07的最终地址图要显式记录逻辑长度、物理长度和padding。

head/tail为单job单调计数，各21bit可表示0…N；非环形，无回绕。head≤tail≤N，队列存放entry索引0…N−1；只有head<tail才可pop，tail=N后不得push。占用为tail−head，差值先按更宽类型检查。逻辑tail、物理committed_tail和未提交append缓冲须区分，具体候选结构见E4。

### E2. 不变量

窗口和流段的详细执行以[窗口附件v0.2](../experiments/track4_full_sw_20261004/04_local-designs/canny-window-sketches-v0.2.md)G-W01…04、N-W01/02、C-W01/02为本稿E3的展开：P=N/2是pair数量；仅V1/V2事件valid可以携带无数值TAIL；NMS缓存保留外框原始Mgrad，仅中心外框分类为NONE。CN-OP01/02/03/04/08按附件逐沿/优先级执行，相关整体数量及取消不变量保持。

| INV | 条件/理由 |
|---|---|
| CN-INV01 | 每级只对实际接受推进，数据/坐标/三ID一起保持；气泡不作为0像素 |
| CN-INV02 | Gaussian仅一次舍入，Sobel使用Gaussian邻域而不是pre-Gaussian梯度 |
| CN-INV03 | 分类阶段产出N状态，初始11不存在，外框NONE |
| CN-INV04 | 分类完成/fence先于闭包；可变状态图只有一个缓存/更新拥有者 |
| CN-INV05 | 01/10→11与成功入队成对；同像素最多接纳一次，不能用未提交DDR旧值重复入队 |
| CN-INV06 | head≤tail≤N；每个逻辑已入队entry都在已提交DDR或受保护本地缓冲内可见 |
| CN-INV07 | 状态/队列缓存的读改写、替换和归还不丢脏数据或读取过期版本 |
| CN-INV08 | 成功等于精确闭包导出N边缘且全部输出fence成立；队列空只是计算条件之一 |
| CN-INV09 | 分叉每个消费者恰好消费一次，已提出burst在取消后仍有完整数据来源 |
| CN-INV10 | 失败/复位隔离旧物理事务，不发布旧策略/旧epoch；计数或超时不能代替fence |

### E3. 中文操作草图

**CN-OP01 接纳。** 先检查旧状态空闲、旧物理事务/本地读回全部排空，eJ锁完整job并检查配置/尺寸/范围及父绑定；非法路径不清别人缓存或解除未核验句柄。合法ARM时才初始化该job状态，完整事件见P-J01/P-C01。head=tail=committed_tail=0；append/readcache有效范围失效，状态cache的valid/dirty/pin/pending失效，不清整块RAM。line_id/tag未包含基址/代次，因此新job必须完成这个有效性隔离，不能命中上一job的11；旧事务未结时不得先清元数据伪装空闲。子级start完成后接收FRONTEND输出。job接纳沿的cancel不能代替后续ACTIVE取消。FRONTEND終态即时保存，后级继续处理尾数据时不阻塞其status消费。

**CN-OP02 高斯。** 接收Msrc组时按真实坐标读取所需旧四行，用pending记录读结果/当前组；没有可推进条件时禁止新RAM读写使能，保持地址、pending及历史，不能保持上一拍RE/WE为1而重复发起读写。上边界重复首行，底边界重放末行，水平方向夹紧首/末列。先对每列五Msrc按1/4/6/4/1计算未舍入纵和，再按同权重对五纵和求总和，最后+128右移8。每像素输出中心坐标。四行循环覆盖、最后两行重放、首末列跨lane和五级算术逐沿见附件G-W01…04；父端口/批准基线仍由CN-B01/CN-B06统一冻结，不借用3×3已有证明。

**CN-OP03 梯度/分叉。** 对完整Gaussian图重新构造3×3窗口，按六级Sobel形成Gx/Gy/Mgrad。C4方向按P-D01四级先检查范围、20bit乘分解/比较并延迟原字段对齐。暂存一组全部字段，并设置NMS_pending和必要的grad_pending；某支首次握手只清自己的位，两位清完后才释放/替换该组。梯度保存关闭时grad_pending初值0。取消前及取消同沿基于沿前valid&ready完成的单支交付仍计入该支实际数量，不能重复或抹除；两支的已交付前缀可以不同。

**CN-OP04 NMS/分类。** 抑制前Mgrad/方向两行窗口给中心及所选邻居，不能读取已被邻居NMS清零的幅值；外框历史仍为原Mgrad，只有外框中心或Mgrad=0令Mnms=0。否则按固定负向>、正向≥判断保留，得到Mnms，再对Mnms作严格双阈值产生00/01/10。仅分类pair实际交付时增加strong/weak计数，打包所有像素含0。EOF后等待前级empty、CLASS及必需GRAD独立LOCAL_OK被C0保存、CLASSIFICATION fence成功，再允许下一阶段读取；writer封口不等fence。

**CN-OP05 种子。** strong=0时精确结果全0；weak=0时精确结果仅初始strong，这两条快路径由集合定义证明，不缩减其他输入。一般路径遍历全部N状态，所有10强边先确认队列可接纳，再在唯一状态拥有者中把它改11并入队；状态标记/append完成必须成对。全部种子形成后seal尾append、写回dirty状态并等待完整阶段fence，使committed_tail=tail、所有种子状态可见，再启动BFS。此后出现10说明阶段或一致性错误，不能继续当合法未扫描种子。

**CN-OP06 精确连接。** head<tail时读取该entry的合法x/y，交给活动pop寄存器后head增加一次；按固定顺序检查八邻居：NW、N、NE、W、E、SW、S、SE。先判断坐标合法，禁止线性索引跨行；00或11不入队，10报阶段/一致性错误。01且有队列容量时在同一拥有者中接纳为11并追加一次。读取不能绕过脏缓存；append尚未提交的entry不能从旧DDR读取。每邻居结清后推进到下一邻居，八项检查完成后解除pin并清活动pop，再pop下一entry；内存停顿保持当前坐标/操作，不跳过未检查项。

**CN-OP07 结束/导出。** head=tail且无活动pop/未完成邻居/入队/缓存替换后，闭包逻辑结束。一般路径先seal尾append、写回dirty状态并等全部阶段fence，再由同一状态拥有者顺序导出：11为1，no-weak快路径初始10为1，no-strong全0。所有N像素均形成边缘，末byte补0；不可把未访问弱边作为边缘。C8先独立start EDGE，再按P-C01容量/预留把标量聚成完整pair；EDGE LOCAL_OK和OUTPUT fence、FE/feed匹配关闭及全计数证据后给C0 OK。工作区只能由父实际租约账本回收，识别仍需grad时保留至最后读归还，不以Canny status消费释放。

**CN-OP08 取消/错误。** 禁止生成新请求，结束/冲刷未交付像素和本地未提出的积累；取消同沿真实发生的各像素/DDR握手照常分别登记，整job作废。已提出valid请求必须保持至接受/合法终结，已发AW必须补齐全部W拍并等B响应。状态/队列未提交数据可在任务作废后丢弃，但不能提前清仍用于结清突发的缓冲。排空后报告失败并由帧所有权回收；DDR无响应则隔离，不能超时后假OK。新job不与旧请求或可变缓存共享地址。

### E4. 缓存、终止与资源比较

全帧1bit visited需要2,073,600bit。按10,240bit/RAM10满打包只是至少203块的容量下界；按原生8192×1/512×16常规组织需要254块，不能视为在256块整机中可免费容纳。它还未计窗口、平台FIFO和显示，因此默认选择DDR的2bit原地状态+有界块缓存。

候选状态缓存为8KiB、128条64B线、4way×32set；每线覆盖256个连续raster像素，包含4个128bit DDR beat。linear=i=y×W+x，line_id=i>>8为13bit，set低5bit、tag高8bit；生产line_id为0…8099。它不是256像素的二维方块。每way的2KiB用两个RAM10 512×16组织，四way共8块；16bit字包含8个状态，一条线32字。元数据约128×(tag8+valid/dirty/pin/busy)+32组PLRU3bit，约1.7kbit寄存器，仅为结构估算。

同一pop的三行邻居各至多跨两线，总计至多6线；在W≤1920时线ID跨度≤16，32set下这些不同线不互相映射到同一set。可以把当前pop涉及线pin到八邻居完成再解除，避免本pop重复装填。单状态拥有者不同时启动另一pop；不得把这个局部集合性质推广为整帧高命中率保证。

候选缓存阶段为LOOKUP→必要的脏victim写回/响应→FILL→WORD_READ→CHECK→有容量时STATE_AND_ENQUEUE_COMMIT。miss期间保留当前邻居，不发第二个业务更新；fill收齐4beat并按16bit逐字写入后才设置valid/tag。dirty victim保持数据/标签直到规定写回成功，错误使整job失败。读改写周期不得与同址RAM读并行，不能依赖模型同址未定义值；enqueue暂存有容量后，状态写11和队列接纳才可原子提交。完整RAM映射、逐沿状态、pin/PLRU及失败分支已在存储附件SC-M01…03形成候选；仍需CN-B06的完整父端口/基线统一。

队列候选为两个append半银行（合计512×32、2RAM10，每半256entry/1KiB）加512×32只读prefetch缓存（2RAM10），局部队列共4块。head/tail/committed_tail各21bit，0≤head≤tail≤N且0≤committed_tail≤tail；优化forward允许head暂时超过committed_tail，不能维持错误的head≤committed_tail不变量。

每个未提交entry由带全局索引范围的一个append/sealed银行保留；seal后不可改写，完整选定burst备齐才发地址。一条逻辑write descriptor在途，必须按最早未提交区间发送，新增有效起点等于旧committed_tail；物理起点可因保留至多3个prefix稍早，不能跳过较早未提交数据。遇4KiB按已备数据分段，全部B成功才把committed_tail提高到真实valid_end，不能按末W或第一段B提前推进。银行可复用还须forward/组拍的本地读结果及sideband已被捕获，且后续partial所需prefix已移交；B只结清DDR，不替代本地借用归还。

head<committed_tail才可从DDR读取；否则在head<tail时只能从拥有该索引的本地银行forward。已pop的entry仍保留到B及本地读归还/必要prefix移交完成，不因head增长释放银行；迟到B错误使job失败，不发布任何已推测处理的结果。银行满可反压新入队，DDR组拍与forward共享读口须公平推进，不能相互等空。

保守partial策略是seal尾银行并等B后再读；单条弱链上逐entry采用这个策略会退化为每项fence，不能当最终优化。优化候选优先forward，在种子→BFS和最终结束时再强制seal剩余尾部并排空。若采用完整16B末拍零填未有效entry，后续append必须保留并原值重写此前已提交的至多3个prefix entry；这些旧entry不可改变，committed_tail只包括实际有效项。读cache记录抓取时的提交范围，tail后来增长不能扩展旧cache有效范围，超出旧范围需forward或重读对应尾beat。v0.3采用完整16B拍和滑动银行候选，prefix占256槽内、新增容量256−p；逻辑写按≤64拍/4KiB拆段，取消只结清已提出段，descriptor失败时c不推进。Q-M01…03规定共享口、回收及旧cache范围；不能隐含依赖未证明的掩码支持。

有限性证明：每次接纳把非11候选永久改为11且入队一次，成功job无反向状态变化；最多N次入队/pop，每pop最多8个合法邻居检查，所以不依赖固定迭代次数，有限图上最终终止。这个证明假设内存最终响应；DDR永久停顿触发故障/隔离而不是“算法无限合法运行”。若队列已达N仍出现新可接纳像素，说明协议/状态一致性错误，不能静默截断。

窗口资源推算：Gaussian原8bit四行8RAM10；新Sobel窗口4；NMS13bit按每lane两8bit容器组织两行8；Canny前级增量20，加共享FRONTEND8为28块。状态cache8、queue银行/prefetch4为旧小计40块；P-W新增CLASS/EDGE共享1块及GRAD3块后累计44 RAM10（17.1875%器件块数）。MOD-05物理响应缓冲/平台/显示/识别及装拆拍/控制寄存器另计，尚无整机可放置承诺。移位加法目标不用DSP实现Gaussian/方向；实际XLR/时序仍须综合/PNR。

比较计划：3×3 Gaussian少4块但滤波跨度较小；默认5×5不因方便退回3×3，模糊也可能降低细小相邻边缘分离度，实际质量需比较。精确连接比较单邻居串行、16B/64B线、同pop pin复用和queue forward，保留no-strong/no-weak快路径，不降低精确性。N×8=16,588,800次邻居检查，仅一检查/100MHz理想下需165.888ms；完整矩形有效有向邻接上界8N−6W−6H+4=16,570,804，均未计seed/导出、读改写、DDR及公平服务。

16B无命中每邻居读为265.4208MB；64B线在每pop≤6线且最坏全miss时读上界6N×64=796.2624MB，可比16B更差。一般路径每次dirty写回至少消费一次唯一01/10→11更新，粗上界N×64=132.7104MB；这不含初始分类、seed/final扫描等流量。queue理想每entry4B写+4B读为16.5888MB/满N；无forward单链partial每项读写16B可达66.3552MB并逐项等B。命中率和本地forward收益必须实测；不能仅凭2bit布局/8KiB缓存宣称已经减少总线交易或达到最优fps。

### E5. 存储局部草图展开

[存储附件v0.3](../experiments/track4_full_sw_20261004/04_local-designs/canny-memory-sketches-v0.3.md)按MC-M01客户端合同→SC-M01映射→SC-M02有限状态→SC-M03原子claim/取消→Q-M01银行/prefix→Q-M02组拍/读口→Q-M03 pop/prefetch→MC-M02阶段/资源阅读。它展开CN-OP05…08及IF05/06/08，不另建状态图拥有者。

cache每沿只发一个RAM读或写，WB允许捕获旧读并发下一读；hit/FILL安装建立pin，FLUSH写回与替换按保存用途分别返回。cancel与claim同沿仍成对cache WE/queue WE，与末字安装同沿则禁止valid发布。8KiB cache共8块512×16、1632bit元数据及512bit linebuf，其他记录另计。

queue两个append半bank共享1R1W，prefetch为独立512entry cache，共4 RAM10。prefix占现有槽，避免259槽/65拍越界；prefetch至多128拍按接口拆为最多3段，每段完成及本段借用结清即可开始下一段，不等整cache发布而自锁。早失败drained terminal共同终结未接受逻辑拍；未知物理排空仍隔离，不释放tag/租约。

串行命中claim下一操作最早e7，165.888ms仅“一检查一拍”的理想比较；后续同字最新值旁路/邻居归组、seed/导出连续扫描及后台服务需实测比较，旧40RAM小计未含E6新增writer4块或MOD-05物理响应缓冲/全平台/识别。

### E6. 父任务、方向与writer展开

[父任务/writer附件v0.4](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md)按P-J01完整job/feed/abort→P-A01逻辑/物理长度与租约→P-D01六级Sobel/四级方向→P-W01/02/03顺序writer→P-F01独立local terminal/fence→P-C01有限阶段/精确快路径→P-C02冻结终态/复位保持/恢复阅读。它展开CN-OP01/03/04/07/08，窗口v0.2及存储v0.3作为不变附件继续有效。

917bit job、23个phase5编码、32种reason5及status/feed/ack候选明确保存范围。坏job不启动且必须取得父真实绑定返还；GRAD早结束也独立保存，不能等CLASS阶段才接。快路径fence required=1001、GENERAL=1111；未启动支不造EOF/终态/fence。

CLASS/EDGE共享一个512×16 RAM两半bank，GRAD三块并行保存每lane低24bit并恢复32bit；每writer按自身EOF seal，整满末bank不新建空bank。三writer仅当前write_owner组拍到两个128bit W槽，pending预留随停顿保持；LOCAL_OK证明本writer已完成后C0才提出stage fence，避免互等。共享RAM进入EXPORT时独立EDGE start，首start沿不发读或交付pair。

[生产地址候选JSON](../experiments/track4_full_sw_20261004/01_baseline/canny-candidate-address-arithmetic-v0.4.json)列六源/三结果/CLASS/QUEUE/GRAD的12区；页分配55,226,368B，比紧凑55,209,600B多16,768B。低4KiB保留不替代PHY校准地址证明；实际job权限只含最小物理A，页空隙未授writer。数学不重叠不证明真实byte/row/bank映射或六源持续接纳期限。

功能rst只冲刷私有流；已提出MC req/W valid、完整ctx/银行/linebuf/W来源、读pending及记账在保持域继续。drained0形成不可变隔离快照，后续live排空不改status；恢复要匹配完整旧scope并独立返还事件。实际MOD-04/05恢复/grant/fence接口仍阻塞，不能凭设计清计数或保留寄存值假装安全。

## F. 语言、执行与独立参考契约

计划SystemVerilog2009同域RTL；C++本批不选用，相关对象/异常条款不适用。候选Python3.14.6标准库整图参考用于获批后测试，当前没有参考代码或向量。纯计算不得读写原输入，返回新数组；范围/长度/尺寸/配置先检查，任意精度整数按B/E显式验证有限结果。

数学参考以完整有限图直接25项高斯卷积、直接3×3 Sobel、整数方向、邻居NMS和集合/图遍历闭包计算，不复制RTL四行ring、缓存tag或队列指针。导出的图逐像素完全相等，无浮点容差。硬件协议另用事件日志核查实际接受、每分支一次、缓存/队列可见性、终态和排空，不用函数运行完毕代替物理完成。

| RTL项目 | 本批契约/尚缺 |
|---|---|
| A 数值 | B/E的8/12/16/20bit unsigned及11bit signed；移位前扩展，唯一高斯舍入；head/tail受N约束不回绕 |
| B 时钟/观察 | 目标core100MHz上升沿接受/提交，testbench更新稳定后观察；实际PLL/STA仍待平台 |
| C 接受/交付 | valid&ready；Canny源读取可暂停；job与首像素分沿，两个消费者各自一次 |
| D valid/推进 | 气泡不改历史，边界补值来自合法有限图，不将valid0当黑像素 |
| E 反压 | 子级/sideband/RAM pending同条件保持；DDR停顿可传回源读取，但不传到相机采集 |
| F 延迟/吞吐 | 窗口附件给条件局部边沿：Gaussian首2D+7/末P+2D+6；NMS窗口首D+3/末P+D+2，分类再2沿；P-D01给六级Sobel→四级方向→fork条件沿号，父阶段受DDR/FE/feed证据驱动，不相加成整条固定总延迟 |
| G 复位 | P-C02功能rst仅冲刷私有流，MC保持域继续valid/payload/pending/真实记账；完整旧scope安全恢复及独立返还前禁重用，counts_final按实际required及已观测计数收敛、未收FS不伪造，初始safe_init不凭未知FF值 |
| H 配置 | 完整快照贯穿同job，TL/TH不逐像素变；同沿旧任务按旧配置，坏配置拒绝 |
| I 存储 | N队列、2bit状态、grad/edge独立布局；存储附件给唯一cache、1R1W映射、整线padding、原子claim及滑动bank/分段terminal；真实服务、父端口及地址grant仍阻塞 |
| J 身份 | 全部N坐标/三ID，输出含显式0；grad与NMS同源Gaussian，非法邻居不跨行 |
| K CDC | Canny核本批同域；DDR/显示跨域由相邻模块，不能因同域核正确宣称整机CDC完成 |
| L 实现 | Ti60F225 I3/Efinity2026.1.132/Questa2024.1候选；44块为共享FE/Canny窗口/cache/queue/writer候选，MOD-05/平台/显示/识别及控制另计；无实测报告 |

软件结果↔硬件事务以三ID/坐标匹配；成功job应有N输入Msrc、N分类和N最终边缘，保留梯度时N个grad32。取消/失败按每个接口分别比较已交付前缀及整体作废；NMS和grad两支前缀长度允许不同，各自不能重复、丢失或错配，不能要求缺失后缀被补成合法图。软件参考API、向量格式、runner、种子及停止条件待完整接口后的批准版本明确，不在当前草稿偷偷生成可执行测试。

## G. 实施与验证计划（文字、未执行）

次序：统一窗口/缓存/queue/父任务/writer及MOD-04/05/09/10/11实际交接→独立审阅和基线→READY/指定批准→Gaussian与新梯度→NMS/分类→精确连接→组合/整机性能。计划文件职责为`rtl/canny/gaussian5_pair.sv`、`canny_gradient_pair.sv`、`canny_nms_pair.sv`、`canny_state_cache.sv`、`canny_work_queue.sv`、`canny_hysteresis.sv`、`canny_frame.sv`及三个顺序writer职责；文件均未生成，具体拆分在完整设计版本冻结。

| TEST | 覆盖/输入 | 期望来源及通过条件 | 状态 |
|---|---|---|---|
| CN-T01 | 常量/脉冲/边界5×5卷积 | 直接25项整图卷积；常量不变，逐像素G8一致 | 未运行 |
| CN-T02 | 唯一像素30处于总权重4的位置 | 最终floor((120+128)/256)=0，抓出按轴提前舍入得到1的错误 | 未运行 |
| CN-T03 | Sobel符号/极值、Gaussian坐标 | 同核参考，signed/abs/L1准确，diag对齐同中心 | 未运行 |
| CN-T04 | 424/1024边界、零分量、四象限 | (128,53)H、(128,54)对角；参考用整数规则，不用atan | 未运行 |
| CN-T05 | 平台/反号/四方向、外框 | 固定负向>正向≥，平台第一点，外框0；复杂角点逐图保留失败 | 未运行 |
| CN-T06 | TL/TH相等、0/1530/2047、坏配置 | 严格>分类；相等无弱，强0/弱0快路径同完整图闭包 | 未运行 |
| CN-T07 | 全弱无强、孤立弱、长蛇形链、斜连/环/分支 | 独立八邻域图可达集合，长度不截断，每点最多入队一次 | 未运行 |
| CN-T08 | N容量、dense/稀疏、边界邻居 | head/tail合法，no-weak快路径正确，不跨行、不截断 | 未运行 |
| CN-T09 | cache命中/冲突/脏替换、fill/writeback停顿；连续job同line/tag但不同源/代次 | 唯一状态版本，先接纳后不重复；新job有效性隔离，不命中旧11；与直接集合参考一致 | 未运行 |
| CN-T10 | append未提交、head追tail、prefetch部分有效范围；1/2/3 entry尾拍，小图N非4倍数；B与本地read/prefix移交重合 | 读取最新entry；提交保持连续前缀，银行B及本地借用结清后复用；prefix不变，padding不越界，填充值不增加tail | 未运行 |
| CN-T11 | grad/NMS两支随机独立反压、单支已消费另一支停顿时取消 | 每支每坐标恰好一次，同payload/三ID；失败可有不同前缀，无重复/丢失 | 未运行 |
| CN-T12 | 取消同末输出/AW后、复位/响应错/无响应 | 已提出burst数据仍齐，正常排空/故障隔离；无错误成功图 | 未运行 |
| CN-T13 | 完整1080p、有/无中值及梯度保存；识别最后读fence延迟；FRONTEND合法但Canny非法小尺寸 | 各级N数量、字节布局、fence和逐位结果；FE status及时消费；grad读未归还不重用，小尺寸在启动前拒绝 | 未运行 |
| CN-T14 | 同输入资源/流水/cache/邻居合并比较 | 真XLR/RAM/DSP/STA、DDR交易、计算/等待周期及fps；显示60Hz单独报告 | 未运行 |
| CN-T15 | W6/H5、ring/top/bottom/水平跨行/TAIL，各关键处气泡/停顿/flush | 附件G-W01…04及独立25项卷积；首e13末e27的条件推导、P数量、唯一延迟写、末组与下一job隔离 | 未运行 |
| CN-T16 | NMS 255/256/1023/1024/1530×四dir、byte平面、较大外框邻居/内圈、replay/tail/分类反压 | 附件N-W01/02及独立邻居参考；仅中心外框抑制、窗口D+3/分类D+5、真实交付计数 | 未运行 |
| CN-T17 | 首数据前全空、ARM/start、FE早OK、FE OK与cancel、FJ提出/接纳交错 | 附件C-W01；完整快照和FE状态保存、全空不提前成功、接纳后取消不能只发IDLE沿脉冲 | 未运行 |
| CN-T18 | fork单支已收、旧释放与新接纳同沿、旧空/禁止穿透、各EOF、grad关闭、flush | 附件C-W02；分支各一次、新pending覆盖旧清位、同job替换、实际前缀与整体作废 | 未运行 |
| CN-T19 | cache索引/padding、同字更新、pin/PLRU、WB替换/FLUSH、失败排空、末字安装同cancel | SC-M01…03；最新11、映射/权限正确，失败不等假success，半线不发布 | 未运行 |
| CN-T20 | prefix0…3/256−p容量、4KiB分段、两bank满、B与forward同沿、旧cache padding | Q-M01…03；c连续前缀、source保持、共享口公平，借用归还后回收 | 未运行 |
| CN-T21 | 16B/1…64拍/4KiB/溢出、tag/segment、R/W保持、早ACCESS terminal、fence顺序 | MC-M01；物理排空先于失败终结、段内计数、段间不等整对象回收而自锁；真实PHY另为门槛 | 未运行 |
| CN-T22 | claim同cancel、queue满、各segment提出前后取消、forward后迟到B错、旧job未排空 | SC/Q/MC；成对提交、后台独立推进、失效job不发布、未知隔离不重用地址 | 未运行 |
| CN-T23 | 917bit job核验/非法已绑定reader预取、ARM/FJ/首数据分沿、EXPORT start/gather替换、FE早OK/feed未关闭、Q消费/旧scope恢复、平台abort、GENERAL导出10、rst遇held req/W或读pending/completion/fence | P-J01/P-C01/02；正确拒绝/返还、计数快照及快路径1001/GENERAL1111 fence，无提前OK或复用 | 未运行 |
| CN-T24 | N30/跨行carry、CE2/GRAD4 bank满、双W槽、EOF恰满/无空请求、4KiB段间取消/早terminal、local terminal/fence/CLASS→EDGE | P-W01…03/P-F01及附件准确分段；恰P/N/A，padding0，末segment及借用结清后回收，local terminal不等fence | 未运行 |
| CN-T25 | 最小物理A与页allocation区别、32/33bit溢出、错句柄/重叠、小图/1080p12区、grad最后读 | P-A01/地址JSON；区间、权限及租约正确，数学不重叠不冒充真实slave映射证明 | 未运行 |
| CN-T26 | 424边界/零/四象限、非法abs/Mgrad、两lane不同dir、四级气泡/停顿/flush、单支已收/grad关闭/EOF | P-D01；六级Sobel+四方向字段/坐标相容，真实接纳后错误寄存、不反馈ready；各支一次，关闭支不造EOF | 未运行 |

局部数值与整条协议互补；小图通过不代表1080p。行为存储模型只验证访问协议，匹配2Gb真实器件/PHY/校准另为整机硬门槛。测试种子/工具许可/runner尚未冻结，不把文档中的场景当已运行记录。

## H. 双向追踪

| REQ | MOD/IF/OP/INV | 计划核心职责 | TEST | 实际代码/证据 |
|---|---|---|---|---|
| CN-01/02 | 08；IF02；OP02；INV01/02；附件G-W01…04 | gaussian5_pair | T01/02/13/15 | 待实现/未运行 |
| CN-03 | 06/08；IF03；OP03；INV02；P-D01 | canny_gradient_pair | T03/04/26 | 待实现/未运行 |
| CN-04/05 | 08；IF04/06；OP04；INV03；附件N-W01/02 | canny_nms_pair | T05/06/16 | 待实现/未运行 |
| CN-06/07 | 08；IF05/06；OP05/06/07；INV04…08；SC-M01…03/Q-M01…03/P-C01/P-W/P-F | state_cache/work_queue/hysteresis及导出writer | T07…10/19/20/22…24 | 待实现/未运行 |
| CN-08 | 04/08/10；IF01/04/07/08；OP01/03/07；INV01/08；C-W01/02/MC-M01/02/P-J01/P-A01/P-C/P-F | canny_frame完成汇合/分叉及父绑定 | T11/13/17/18/21…25 | 待实现/未运行 |
| CN-09 | 04/05/08；IF08；OP08；INV09/10；C-W01/02/MC-M01/02/SC-M03/Q-M02/03/P-C02/P-F01 | canny_frame及全部客户端排空 | T12/17/18/21…25 | 待实现/未运行 |
| CN-10 | 05/08/09；全部IF；E4/E6/P-D/P-W | 同职责的结构/流量比较 | T14/24/26 | 推算/未测 |

反向核对各候选文件均由上表需求驱动。需要修改阈值、方向、NMS、queue或fence时同时修改B/D/E及相应TEST，不通过删失败或改参考定义给自己判PASS。实际符号/哈希/命令在获批后K登记。

## I. 门槛、阻塞与审查

| ID | 正确性缺口/影响 | 解决路线 |
|---|---|---|
| CN-B01 | 四行ring/两次底部重放/水平跨lane/五级算术/TAIL事件/首末沿已在附件形成设计输入；完整父端口/批准基线尚待统一 | 逐沿及W6/H5数量已只读复核，结合CN-B06冻结start/flush/身份/实际基线；未实施或仿真 |
| CN-B02 | NMS16bit容器拆8bit RAM平面、288bit窗口/两级分类/外框原梯度已形成设计输入；方向/分叉父接口尚待统一 | 附件N-W01/02明确局部首末沿和empty；结合CN-B06冻结完整sideband/端口；未实施或仿真 |
| CN-B03 | SC-M01…03形成RAM映射、有限FSM/pin、WB用途/失败及同沿候选；父端口/批准基线仍未统一 | 与CN-B05/06/07统一操作/结果/terminal、地址授权及真实可见性，未实施/仿真 |
| CN-B04 | Q-M01…03形成256−p容量、共享口、forward/prefetch/分段承诺和回收候选；完整服务/父端口仍未冻结 | 与MC-M01、claim共同事件、全局grant及服务实证统一，文字场景均未运行 |
| CN-B05 | MOD-05实际地址/byte lane/响应/outstanding/fence及最低后台服务未知 | 内存局部契约与匹配器件/PHY实际预检，不用axi_ram替代器件门槛 |
| CN-B06 | P-J/P-C已形成完整917bit job、23阶段、feed/ack/status及复位保持候选；实际父grant/FE/feed租约、fence/恢复端口和基线未统一 | 与FRONTEND/FM/MOD-05/完成汇合冻结实际端口/绑定证据，不把候选schema当已存在IP能力 |
| CN-B07 | P-A形成12区页分配及最小物理A候选；真实地址映射/容量、六源期限、识别最后读/全局租约仍未证 | MOD-04/05/09/10/11统一grant/描述符生命周期并实际验证，增加源槽/多grad须重算布局 |
| CN-B08 | 实际资源/时序/吞吐与复杂识别质量的分配未证 | 获批后同输入比较，保留失败；不把44块或165.888ms推算当验收 |

数值和图闭包的设计理由已有内容，整体职责、中文草图、组合反例及验证追踪已形成；方向/writer和父阶段逐沿已有候选，最终相邻物理接口、存储实证及“无当前正确性阻塞”仍不满足。本批保持LOCAL_DESIGN，尚未形成READY基线，也没有实现批准。独立审阅结果在实验05登记，设计审查不等于功能/时序验证。

## J. 变更与恢复

本稿相对整体v0.1细化默认5×5、纵向先算/单次舍入、424整数方向、NMS固定相等策略、严格双阈值、2bit原地状态/缓存、单调队列和grad32图。这些是批准前提议；下一整体版本需吸收图布局/预算和相邻契约，不能默改已冻结FE输入。

v0.2相对本稿v0.1增加窗口/流段附件：四行ring与两次底部重放、五级算术及有效TAIL、col历史/中心坐标、NMS8bit物理平面和288bit输出、两级分类及外框原幅值、ARM/start/FS及时保存/fork旧新提交。新增T15…18；资源RAM40预算不变、方向级及DDR接口未冻结，整体仍LOCAL_DESIGN。v0.1文档审计保存在[历史快照](../experiments/track4_full_sw_20261004/05_reviews/document-checks-canny-v0.1.json)，旧hash不证明修订后的文件。

v0.3增加[存储附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-memory-sketches-v0.3.md)：实际RAM映射/FSM与WB用途、pin/安装取消、原子claim、256槽内prefix/共享口、逐segment承诺/早失败terminal、prefetch旧有效范围及段内tag退休；新增T19…22。CN-B03/04获得具体候选输入，父接口/真实服务/地址/性能仍阻塞。前轮23份文档审计保存在[历史快照v0.2](../experiments/track4_full_sw_20261004/05_reviews/document-checks-canny-v0.2.json)，窗口附件v0.2继续有效。

v0.4增加父任务/writer附件及12区地址算术：完整917bit job、六级新Sobel/四方向、共享CLASS/EDGE与24bit GRAD银行、两个W槽、独立LOCAL_OK先于fence、23阶段/精确快路径、不可变结果/原因、拒绝返绑定及MC复位保持/安全恢复。新增T23…26；RAM从旧小计40加writer4至44。前轮25份文档审计保存为[历史快照v0.3](../experiments/track4_full_sw_20261004/05_reviews/document-checks-canny-v0.3.json)，旧窗口v0.2/存储v0.3/FE/FM不改，当前实际外部依赖及全机资源性能仍阻塞。

FRONTEND v1的Y_ONLY及F4语义保持原样；Canny新增窗口不等于修改已有内核批准范围。恢复时核对最新设计/真实审批/输入hash/已执行证据后继续，不能从聊天摘要假定本稿可直接实施。

## K. 实现及验证实录

只有只读调查、设计文档写入和读回；没有新业务RTL、Python参考、功能脚本、testbench、编译、仿真、综合、PNR/STA、bit/hex、数据库记录或人工硬件观察。软件完成未证，整机目标未完成。

## L. 阅读与交付

先读主计划及02整体，随后本稿B数值/样例→C数据流→D交接→E3中文步骤与窗口附件→E4有限性/资源→E5存储附件→E6父job/地址/方向/writer/阶段/status/恢复→F/G/H映射/测试→I阻塞。附件先读整体边界，再读Gaussian、NMS、父流段/fork；人工观察含高斯舍入、TAIL末pair、外框原幅值比较、平台NMS、长弱链和head追上未提交tail。没有用户作答，理解验收待检验。

完整事务路径为：完整源M→Gaussian→同坐标新梯度→两支各一次→NMS/分类fence→强种子→精确闭包→N像素边缘fence→可选识别最后读→MOD-10汇合发布。文档/注释/代码/测试的一致性验收在实际实现后进行，当前不存在可声称已通过的业务产物。
