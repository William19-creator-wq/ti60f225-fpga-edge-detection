# TRACK4-ALGORITHM-R2-001：Canny流段与交接设计 v0.3

2026-10-04；按[PLAN_TEMPLATE](PLAN_TEMPLATE.md)。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN。属于[完整软件设计包](design-TRACK4-ALGORITHM-BATCH-001.md)R2。当前分类图不是完整Canny；精确八邻域闭包、识别和最终覆盖保留R4/R5。

## 通用计划字段

- Goal：把旧Canny数学/窗口规则冻结成不依赖指定器件的独立流段，明确与原FE的唯一交接以及完整分类/梯度输出。
- Current state：原FE/R1保持未实现；C0和OBS最终附件已分别按实际hash双路全文审阅，本版合并OBS记录/终态/真实工程设计；RGB/控制/显示及完整文件合同未冻结，尚未完成全部R2。
- Target state：生产1080p流段和独立参考/测试；R2整体另有RGB对齐、控制/显示算术及真实可观察工程，完整冻结后才能READY。
- Gap：B01/B02/B04仅设计关闭，不代表功能或工具验证；RGB重放与控制/显示B03、完整基线/文件合同B05仍需冻结。
- Assumptions：单core域、可暂停测试源；静态W偶数6…1920、H5…1080；生产W1920/H1080。
- Open questions：见A阻塞表；不以原FE合法4×3暗示本流段支持。
- Dependencies：[原FE](design-TRACK4-FRONTEND-001.md)、[旧Canny](design-TRACK4-CANNY-001.md)、纯算法窗口/方向附件，候选[来源基线v0.3](../experiments/track4_algorithms_20261004/01_baseline/algorithm-r2-baseline-v0.3.json)、[C0中文状态/事件草图](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md)、[OBS草图](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md)及其[最终审阅记录](../experiments/track4_algorithms_20261004/03_review/observer-review-v0.1.md)。
- Milestones：数值→唯一FE所有者→窗口/方向/fork→分类/状态→RGB与控制/显示→物理observer→组合审阅→纳入整包批准。
- Detailed steps：B行为→C路径→D字段→E各MOD事件→F位宽/时间/对应→G/H验证/追踪。
- State transitions：本版LOCAL_DESIGN；A阻塞全部关闭并读回审阅才READY；批准前没有业务源码/TB。
- Artifacts and hashes：ALGO-R2-BL-20261004-v0.3为候选39份来源清单；本版组合审阅绑定r2-review-v0.3，原附件审阅分别绑定C0 hash5403…8844、OBS hash12D0…1847；均非批准/运行PASS，原R1 hash不变。
- Validation：独立25项Gaussian、整图梯度/NMS/分类参考及事件核对；小图/局部延迟不是1080p/STA证据。
- Failure handling：原FE FS不可改写；R2另记失败、已交付前缀和无效后缀，不把失败伪装空成功。
- Human approval gates：待完整设计包具体版本/范围/基线批准；本版未READY，不提出实现请求。
- Rollback：原源/R1只读；仅新增本设计，未来工作在独立r2子目录。
- Completion criteria：流段成功是完整分类/启用梯度P pair及合法FE终态/全部局部empty；T4-A4完成另需精确闭包，R2整体另需RGB/控制/工程设计。

## A. 来源、选择和阻塞

[既有路线](design-TRACK4-ALGORITHM-ROUTE-001.md)R2、原Canny B/E1、[窗口v0.2](../experiments/track4_full_sw_20261004/04_local-designs/canny-window-sketches-v0.2.md)G-W/N-W/C-W、[方向附件](../experiments/track4_full_sw_20261004/04_local-designs/canny-parent-writer-sketches-v0.4.md)第4节为数学/时间来源。旧917bit物理任务、grant、地址区、writer/fence和器件生命周期不继承；本版不讨论指定器件模型。

本版选择外部CJ+原RGB/FP输入的R2 wrapper，内部实例化FE；C0唯一发FE FJ、控制RGB允许、消费FE FS。Msrc137是内部交接，不再同时假定外部FE另有owner。median只在FE执行，Gaussian不再执行一次median。该选择的C0状态/交接已在[附件](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md)逐沿设计并独立审阅，当前不代表R2其他未决部分或完整软件包已READY。

| 阻塞 | 影响与下一步 |
|---|---|
| R2-B01 | DESIGN_CLOSED：附件§2/6/7冻结CS592、原因/定位/观察优先级及CS消费空隙；独立审阅绑定最终附件hash；代码/测试未运行 |
| R2-B02 | DESIGN_CLOSED：附件§3…8冻结唯一owner、held FJ、共同FP门控、早FS/DERR、旧取消事实、持续cancel及失败排空；21个文字案例，非仿真通过 |
| R2-B03 | 原RGB与最终edge对齐、按键配置、分屏/覆盖子设计未闭合；不把class或固定拍延迟作最终覆盖 |
| R2-B04 | DESIGN_CLOSED：OBS附件§B…I冻结608bit typed记录/19组CRC、公平仲裁/失败终态、生产有效扇出、四pin/40ns/精确reset例外和资源预算；本版IF09…11/OP07纳入交接，真实综合/PNR/STA/bit仍NOT_RUN |
| R2-B05 | 逐源码/参考/测试/接口完整实际基线和语言合同需随上述修订；本候选39份来源不是整包冻结清单 |

## B. 外部行为和数值

| REQ | 精确规则 |
|---|---|
| R2-REQ01 | CJ合法后启动；完整原RGB由FE形成Msrc8；每级输出完整有限图、P组/N像素，lane0偶列/lane1下一列，身份不变 |
| R2-REQ02 | 两轴[1,4,6,4,1]Gaussian，总权重256，所有采样各自夹紧坐标，只有最终floor((sum+128)/256)舍入 |
| R2-REQ03 | 在完整G8图上独立3×3 Sobel；Gx=(c+2f+i)−(a+2d+g)，Gy=(g+2h+i)−(a+2b+c)，新L1和424整数方向 |
| R2-REQ04 | NMS比较原Mgrad；中心>负邻且≥正邻且>0且非外框才保留；外框仅中心分类NONE，历史原幅值不清零 |
| R2-REQ05 | 0≤TL≤TH≤2047；Mnms0→00；>TH→10 STRONG；TL<Mnms≤TH→01 WEAK；其他00。初态不输出11 |
| R2-REQ06 | 每个真实交接一次；bubble不当0；反压全部数据/身份/配置保持；取消保留已交付各支前缀、作废后缀 |
| R2-REQ07 | C0唯一FE/任务owner，FS早接且不被改写；完整流段成功和最终Canny完成分开 |
| R2-REQ08 | 后续原RGB/最终edge按同job/坐标对齐；完整R2设计另含控制/显示，不冒称当前完成 |
| R2-REQ09 | 独立生产流段工程完整观察CLASS125/启用GRAD185/CS592，实际结果有CRC/终态/pad扇出；完整数学和真实工具分别验证，不能以CRC替代图像比较 |

生产D=960、P=1036800 pair、N=2073600 pixel。小图静态6×5是边界实例；CJ W/H必须等于实例，不能job中动态改行长。每级在上一级完整有限图上独立补边，输出SOF/EOL/EOF从中心坐标重建。

方向：Mgrad0→00 H；否则Y×1024≤X×424→H；否则X×1024≤Y×424→10 V；其余Gx/Gy同号01 NW–SE、异号11 SW–NE。X/Y为abs。网格负/正邻居分别H:(x−1,y)/(x+1,y)，NW–SE:(x−1,y−1)/(x+1,y+1)，V:(x,y−1)/(x,y+1)，SW–NE:(x−1,y+1)/(x+1,y−1)。相等侧不随梯度反号改变。

正常：TL=TH没有WEAK；平台0/10/10/0沿同方向保留第一个10。边界：(X,Y)128/53为H、128/54为对角，互换为V/对角。TH≥1530只保证没有STRONG，仍可输出WEAK；未来完整闭包才保证无种子最终edge全0。坏TL>TH或不相容尺寸拒绝，不能交换阈值或偷偷缩图。

## C. 模块与路径

RGB/FP→原FE(Y_ONLY，median按CJ)→IF02 Msrc→G1 Gaussian→IF03 G8→S1独立3×3/六级Sobel→D1…4方向→IF05 held fork→NMS窗口/N1/N2→IF06 class；fork另一支IF05G grad32。所有job/错误/计数/终态汇入C0；不连接完整闭包或显示发布。

| MOD | 职责/唯一数据owner及界限 |
|---|---|
| R2-MOD-C0 | CJ快照、FE FJ/FS与各接口计数/EOF/错误/status；不是窗口历史owner，也不声称闭包完成 |
| R2-MOD-FE | 依原设计RGB灰度/可选median，kind=Y_ONLY、原阈值0；只C0消费FS，原接口/数值不修改 |
| R2-MOD-G | 四行Msrc历史/纵和/水平历史/最终舍入，拥有pending/phase和5级算术 |
| R2-MOD-S | 新G8两行窗口及六级梯度；不复用pre-Gaussian的梯度结果 |
| R2-MOD-D | 四级20bit整数方向及数值检查；错误寄存通知C0 |
| R2-MOD-FK | 一组held及nms_pending/grad_pending；每支恰好一次，不简单广播valid |
| R2-MOD-N | 两行13bit有效/16bit容器窗口、N1/N2分类；保留原外框梯度 |
| R2-MOD-RGB/CTRL | 后续独立对齐、配置/显示；B03尚未闭合 |
| R2-MOD-OBS | SRC/J/K/reset/LED/独立top；J只拥有外部CJ与源生命周期，K唯一拥有记录/CRC/完整terminal及last快照；不消费FE原FS、不存整帧 |

## D. 候选接口与组合检查

以下逻辑字段可由锁定ctx引用实现，不必逐级重复存96bit；引用有效期必须覆盖所有子级/输出及终态实际消费。字段位宽描述不代替RAM/状态事件。

| IF | 提供方→使用方/逻辑字段 | 前提、事件与检查 |
|---|---|---|
| R2-IF01 | 父→C0 CJ142：epoch/frame/config各32、W/H各11、TL/TH各11、median1、retain_grad1 | valid&ready原子锁；IDLE且旧job全部安全结束；检查尺寸/阈值，接纳沿无像素 |
| R2-IF02 | C0→内部FE FJ；父RGB→原FP74；FE→Gaussian Msrc137；FE→C0原FS | FJ三ID/median来自CJ，kindY_ONLY/T0；FP74=RGB48+x/y22+SOF/EOL/EOF/in_bad4，valid/ready独立，无逐像素ID；Msrc16+共同sideband121；FS仅C0且ready独立流尾排空 |
| R2-IF03 | G→新S窗口：G8 pair16+sideband121=137 | 每一完整中心一次；无提前轴舍入；尺寸/标志/三ID对应 |
| R2-IF04 | 新S→D：两lane各Gx11/Gy11/Mgrad11共66+121=187；D→FK再加两dir共191 | signed梯度、无损L1；D1真实接受后检查值域/abs和，错误不消灭原fire |
| R2-IF04E | D→C0 DERR120：三ID96+loc_valid1+lane1+raw_x/y22 | 单held、valid/ready独立，data_flush不能清未消费错误；布局/位置规则见附件§2.2 |
| R2-IF05 | FK→NMS：两lane16容器+121=153；FK→G消费者：grad64+121=185 | 两支pending独立，已收支不重复；retain_grad0不等G ready或EOF |
| R2-IF06 | N→父class125：class4+121；逐交付派生strong/weak各0…2 | 首lane在低位；计数仅fire增加，完整输出P；不是最终edge |
| R2-IF07 | C0→父CS592：CJ142+原因5+mask32+flags4+定位28+八pair计数168+EOF8+strong/weak42+原FS163 | 附件§2.3/6逐位布局及代码；形成后保持到fire，消费沿不接下一CJ；无FS时snapshot0不表示OK |
| R2-IF08 | 后续原RGB+最终edge→显示像素 | 需要同身份/坐标和独立可暂停重放；当前FP活流的一组RGB tap会锁住FE填窗口，不采用 |
| R2-IF09 | R2→K CLASS125/GRAD185/CS592，分别对应OBS-IF02/03 | K空时选择一个typed ready；CS在旧J FEED/DRAIN时优先，不以P/EOF门控；payload完整放608bit，不截断。SRC观察旧C0 CS valid后注册终结并撤未接纳候选；真实CS fire才由K保存/由J进入TERMINAL |
| R2-IF10 | J→SRC/K job_start；K→J terminal_done/fixture_match/complete_ok/CRC32，对应OBS-IF04/05/07 | 同外部CJ真实fire初始化SRC/K；87逻辑bit前缀和两flags分开，flags只在真实CS fire锁定；第19 CRC处理沿用新值提交，下一J沿才读旧done |
| R2-IF11 | K→J observer_fault_sticky；J→C0 cancel，对应OBS-IF08 | 坏data照计真实fire后停止新data，J保持FEED/DRAIN终态接纳并发cancel；真CS及其CRC结束后才ERROR，不能因sticky先关闭CS接纳 |

FP输入归属于C0/FJ锁定的当前job；来源适配负责剔除旧job遗留数据并保留in_bad，不能凭重复坐标识别像素来源。Msrc/G8等内部逻辑共同sideband121=IDs96+x_even11+y11+SOF/EOL/EOF3。gradient每lane32bit的Gx[10:0]、Gy[21:11]、dir[23:22]、高8bit0，pair低32bit为lane0。NMS lane16则Mgrad[10:0]/dir[12:11]/高3bit0，不能混淆两种布局，也不能把16bit容器整体当幅值。

组合正常走查：CJ→共同ARM→FE FJ→RGB实际接受→完整Msrc/G8→新S/D→每支一次→class/启用grad各P和EOF→局部empty及真实FE OK/三ID/P计数→自身status。至少末EOF后的后续沿才观察全部旧已锁事实；原FS及时独立消费。附件§3…8按实际事件补齐成功/失败路径，B01/B02只关闭设计问题；整包其他合同仍未冻结。

错误走查：FE提前OK而class堵塞时保存原FS，保持ctx继续排尾；cancel与FE OK同沿保存真实FE OK但R2失败；FJ提出未接纳时取消不能撤未允许的held FJ，需接纳后后续ACTIVE取消；各已交付前缀保留。方向坏值在D1实际接受后不投D2，寄存DIR_VALUE，不能组合反馈ready抹掉触发事件。

## E. 局部中文操作草图

### R2-OP01：任务、启动与终态

C0冻结设计IDLE→ARM→WAIT_FE→RUN→DRAIN→STATUS，错误/取消走ABORT_DRAIN→STATUS；详见[C0附件](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md)§3/7/8，旧v0.1保存在[不可变快照](design-TRACK4-ALGORITHM-R2-001-v0.1.md)。IDLE收合法CJ并锁所有字段；ARM下一沿对私有流子级共同start，清有效位/归属，首像素仍禁。C0自己提出原FE FJ并保持；只有stream_started与FE接纳成为旧已置位事实后允许RGB推进。Msrc内部接受只属于这份ctx。非法CJ不启动FE/RAM。
独立FS缓存空且本job拥有FE时接收真实FS，包括ABORT_DRAIN；先保存再核验，不能等class/grad/NMS结束才ready。记录每个实际接口计数/EOF，stream_empty在首数据前也可能为真，不能单独触发成功。成功须七个必需口（及启用grad）的P/合法EOF、原FE真实OK、全部局部empty及无错误；提前失败只等held FJ义务、真实FS（若FE已启动）及私有data/DERR清空，不等P/EOF。first_reason/位置按首次观察边沿和同沿优先级锁定；CS592在成功或失败排空条件成立的后续结算沿形成；旧取消归因和持续cancel结束见附件§5/6。

### R2-OP02：四行Gaussian及唯一舍入

G拥有4个bank、q10/r11、pending kind/数据/读回、V1/V2、四列12bit水平历史、H1/H2/H3。start清有效性不清RAM。只真实fire推进输入行/列，r0/r1建历史；r2形成中心0的0/0/0/1/2行，r3形成中心1的0/0/1/2/3，之后r−4…r为中心r−2。
每允许advance沿先消费旧pending/旧RAM结果并做唯一延迟写，再发新读；读q+1与旧写q，跨行读0/写D−1，D≥3避免同址。气泡仍消费旧pending一次，不重复写。停顿RAM所有使能0、读回/pending保持。
纵V1保存外/近两项与中心×6，V2得12bit纵和；水平q0只建左复制历史，q≥1形成旧中心pair，下一行q0同时交付旧行右补边并建立新历史。V2、H1、H2、H3分别只用旧级；只有H3执行(sum+128)>>8。
末真实行后BOTTOM0/1只读最终四行形成H−2/H−1；TAIL是有效控制事件、没有Msrc数值或RAM操作、不计输入。EOF实际交付和所有pending/算术有效位空才局部empty；详见旧G-W01…04逐沿表。

### R2-OP03：新Sobel与整数方向

S在完整G8上独立复制3×3边界，两行窗口的历史/pending/右补边和TAIL沿原FE F2契约。六级算术为四角/中点加权→四侧和→signed相减→abs并延迟原梯度→扩宽abs和→同组交付。
D1先sign_extend至signed12，取绝对值临时并检查≤1020、Mgrad≤1530且等双abs之和，通过才窄化X/Y10；坏值fire照记、不投D2、寄存错误。D2先扩20再算384/40/1024项，D3合424项，D4按B顺序出dir。每模块末级容量决定自身advance；无新输入插bubble并排尾，不冻结整链，不用Msrc是否0决定dir。

### R2-OP04：分叉

FK只有旧held和两pending。两支valid分别由旧held_valid与旧pending决定，展示同一旧payload；各支fire只清自己的pending。旧空或本沿所有旧pending能释放才接受下一组；同沿新pending初始化覆盖旧清位，新组不透传。retain_grad0时该支pending/valid0，ready不参与容量/结束。flush撤私有未交付数据，真实沿前交付各支分别计数。

### R2-OP05：NMS、分类与统计

N拥有两行recent/older的16bit容器，按高/低byte拆RAM，所有平面共同事件。每窗口9容器/lane144bit、pair288bit，中心e取dir，邻居只取Mgrad11；H d/f、NW–SE a/i、V b/h、SW–NE g/c。外框历史保留原幅值。
N1实际接受完整窗口，锁中心/邻居/配置/坐标；N2基于旧N1做严格负向、非严格正向比较及外框抑制，然后严格双阈值分类。N1/N2统一advance来自N2容量，held全部payload保持；strong/weak贡献只有class实际交付计入C0，held valid不能重复累加。尾重放不增加真实输入；class EOF与empty分开。

### R2-OP06：RGB、控制的待完成交接

原FE FO没有原RGB；不接固定拍移位或一组活流tap。最终Canny edge需R4全图导出后与同源RGB重放按三ID/坐标匹配；独立可暂停同序重放才可用两个held汇合。不匹配明确失败，反压保持；其容量/重放/错误与显示配置另成子设计。
控制/显示的纯来源见[来源整理](../experiments/track4_algorithms_20261004/02_design/control-display-source-contracts-v0.1.md)：8preset/6业务mode、精确手势、原灰度和mode0两遍偶行访问已明确；新配置owner、dispatcher、重放plan及失败终态仍为B03，不能直接将CFG212连CJ142。

### R2-OP07：独立完整记录和工程观察

按[OBS附件](../experiments/track4_algorithms_20261004/02_design/canny-observer-project-sketches-v0.1.md)A→B接口→C源/终态→D逐沿→E预算→F工程→G/H/I验证追踪执行设计。J只提出CJ142并锁k派生图样/median/retain/TLTH/fault；生产W1920/H1080不变，C0仍是内部FE唯一owner。k不回绕，半帧故障只在指定pair持in_bad直到真实fire，不 force终态。

K空时有CS优先；无CS时CLASS/GRAD按真实fire轮转公平仲裁，grad关闭时不参与。接纳沿锁608bit记录但不更新CRC；之后19沿依旧shift[607:576]每沿独立处理32bit，最后沿必须使用新CRC形成终态快照。最早下一capture为第20沿，不因busy声明多周期例外。完整CS在真实CS fire由K保存，J只锁判定flags并进入TERMINAL；source则在观察旧C0 CS valid的沿注册source_terminated/撤未接纳候选，不等待CRCbusy结束后的CS fire。这是SRC保持规则的明示终结例外，不能将两个事件合并。

正常complete_ok需真实全源、七必需口/启用grad的P/EOF、完整CJ/CS/FE flags/计数及前缀观察一致。固定半帧故障fixture_match另核reason5/定位/真实短前缀关系/全部EOF0；即使fixture_match1，complete_ok0且LED0灭。CRC不是数学正确性证明，完整逐像素oracle另跑。observer坏data后J不立即ERROR：先向C0取消，仍接受真实CS，终态CRC提交后才进入ERROR；覆盖OBS-C10。

四pin及复位沿原R1软件资料：J2 clk25m、P13 key1_n、N14/P14 LED。40ns覆盖算法/RAM/CRC和同步释放路径，异步KEY例外仅到两级CLR，stage1 Q→stage2 D及core_rst正常计时；LED采用enable，不造派生clock。≤22000XLR、28RAM结构预算、0DSP目标待实际测量；允许FE Y_ONLY无用逻辑合法裁剪，必需数学/历史/有效结果扇出须实际核验。此top不承诺摄像输入或HDMI60Hz，完整R5义务保留。

## F. 数值、RTL A–L和对应

| 数值 | 类型与最大值 |
|---|---|
| Msrc/G8 | unsigned8≤255 |
| Gaussian纵外/近、中心×6、V | unsigned9≤510、unsigned11≤1530、unsigned12≤4080 |
| Gaussian横外/近、中心×6、sum、sum+128 | unsigned13≤8160、unsigned15≤24480、unsigned16≤65280/65408 |
| Sobel四侧、Gx/Gy、abs、Mgrad | unsigned10≤1020、signed11±1020、unsigned10、unsigned11≤1530联合上界 |
| 方向384/40/424/1024乘积 | unsigned20≤391680/40800/432480/1044480，移位前扩展 |
| 组/像素计数 | unsigned21可覆盖P及N；输出单位明确，禁pair/pixel混用 |

| RTL A–L | 当前合同/未决 |
|---|---|
| A | 上表先扩展、单次非负半值向上Gaussian；不是RNE，非回绕；dir检查先于窄化 |
| B | 单core上升沿按沿前握手；TB更新稳定后观察；10ns功能仿真候选不是100MHz STA证据 |
| C | valid&ready，源可暂停，CJ/start/FJ/首数据分沿；FE唯一owner是C0 |
| D | bubble无数值，不改历史/计数；有效TAIL是控制事件，不能和bubble混用 |
| E | 各级末容量推进，全payload/pending/读回/配置保持，两分支只消费一次 |
| F | 无停顿局部Gaussian首2D+7/末P+2D+6；3×3窗口首D+3/末P+D+2，NMS分类再2沿；不相加成固定整链延迟 |
| G | rst同步高有效屏蔽fire并清data/err；C0 metadata错误下一旧ABORT周期data_flush只清私有数据，DERR保持；RAM只由受限q/phase寻址，原FE自身错误时刻不变；旧交付照计 |
| H | CJ原子快照，TL/TH与median整job不变；FE median只执行一次；动态按键生效B03 |
| I | Gaussian8、新S窗口4、NMS8共20 RAM10；加FE8共28结构预算，1024×8/1R1W/避免同址/读输出保持 |
| J | 生产全部N，lane/中心/重建标志、ctx直到真实terminal消费；grad/class前缀可不同 |
| K | 当前算法同域；未来外部按键/源/display域需同步/FIFO合同，不能宣称CDC通过 |
| L | SV2009、Ti60F225/I3/既有工具；独立OBS25MHz/40ns、≤22000XLR/28RAM结构预算/0DSP目标；必要行历史和合法裁剪分别登记，PNR/STA/实际资源未测 |

共同数值契约：Python标准库参考直接25项卷积、直接整图Sobel、整数比较、邻居NMS与分类，不复制ring/pending。返回新结果，不改输入；范围/长度/配置先核验，有限结果位宽显式比较，不用浮点atan。
硬件执行契约：E各advance/旧状态/读回/沿前fire独立验证，计算形成、交付、EOF、empty、status是不同事件。
对应契约：以三ID/中心坐标比对完整成功图每阶段逐位相等；grad关闭明确免除，取消分别比已交付前缀/整体作废，不补缺失后缀为成功。原RGB不是Msrc，最终edge不是class。CS592/DERR120及终态时间schema见附件§2/9，OBS时间/记录/对应按附件G已明确；RGB/控制及完整文件合同仍待B03/B05补充后整体READY。

## G. 验证和实施计划（文字，未运行）

| TEST | 输入/事件、目标与期望 | 方法/通过条件 |
|---|---|---|
| R2-T01 | Gaussian常量0/255、角/边脉冲、单值30位于纵系数4/横系数1，sum120应G0；31/32/33覆盖124/128/132 | 独立25项逐位比较，抓提前轴舍入；R2-REQ02/OP02 |
| R2-T02 | 6×5 Msrc(r,x)=16r+x，G五行6…11、17…22、32…37、47…52、58…63；ring/top/bottom/TAIL停顿 | 正好P组/中心，局部首末沿在限定条件匹配；REQ01/02/06 |
| R2-T03 | 水平/竖直/斜阶跃与镜像；窗口0/0/0，0/任意/255，0/255/255得Gx=Gy765/M1530 | 新G8梯度逐位，signed/abs联合上界；REQ03 |
| R2-T04 | 424边界/等号、四象限/零、lane不同；坏abs/M不一致 | dir/寄存错误/真实fire对应，禁错误组合反馈；REQ03/06 |
| R2-T05 | 四方向平台、外框200/内圈100、幅值255/256/1023/1024/1530 | NMS原幅值/byte重组/阈值恰等及两侧，统计只fire；REQ04/05 |
| R2-T06 | 完整1080p常量/结构斜边/固定种子噪声，median两状态，retain_grad两状态 | 逐阶段N像素/每必需接口P及EOF；小图不能代替；REQ01…07 |
| R2-T07 | 每级bubble/held EOF/reset/flush，不同job/配置、分支独立反压和同沿替换 | 数据/标志/身份保持，计数不重复，旧历史不泄漏；REQ06 |
| R2-T08 | FE早OK/class尾堵、取消与FS同沿、held FJ取消、FP坏/缺EOF、4×3拒绝、grad关闭、持续cancel/坏坐标RAM | 依附件C01…21/T01…08核CS592、真实前缀、旧取消归因/无P失败结束；REQ06/07；NOT_RUN |
| R2-T09 | 原RGB活流一entry tap等待反例、独立RGB/final-edge重放错key/反压；按键配置 | 禁死锁拓扑；最终overlay逐像素/帧生效期待待B03；REQ08 |
| R2-T10 | 生产参数真实网表/资源/算法有效扇出，PT/pin/PNR/40ns候选STA、bit | 按OBS-T08/09取得全部真实证据；必要历史/合法裁剪分开，不能以预算或虚拟IO作通过；NOT_RUN |
| R2-T11 | 608bit三类型/19 CRC分组/公平仲裁、正常及早错误、sticky取消后真CS、生产四组合与故障恢复 | OBS-C01…10/T01…07逐位/真实fire核对，独立CRC与数学oracle；正常complete_ok与故障fixture_match分开；NOT_RUN |

获完整设计批准后，计划在work/active/track4_algorithms_20261004/r2/生成Gaussian/方向/fork/NMS/协调器/新wrapper、独立参考、单元/整图/协议测试及实际工程。原FE代码是未来R1实现的相同批准版本复用，不称现在已有代码。OBS工程行为/约束按新附件，精确参考/TB/runner路径及全文件合同待补B05，精确status按C0附件，不在此偷偷生成可执行原型。

## H. 双向追踪

| REQ/来源 | MOD/IF/步骤 | 计划文件/稳定符号（未生成） | TEST | 当前证据 |
|---|---|---|---|---|
| R2-REQ01/T4-B1/A4 | C0/FE/G，IF01…03，OP01/02 | canny_stream_top.sv、canny_stream_controller.sv / job_snapshot/真实计数 | T02/T06/T08 | 设计/owner新提议 |
| R2-REQ02/CN-02/G-W | G/IF03/OP02 | gaussian5x5_pair.sv / pending/V1/V2/H1…3/phase | T01/T02/T06 | 数值/窗口来源 |
| R2-REQ03/CN-03/P-D | S/D/IF04/OP03 | 原window3x3_pair、sobel_pair；gradient_direction_pair.sv / D1…4 | T03/T04/T06 | 数值来源，未实现 |
| R2-REQ04/CN-04/N-W | N/IF05/06/OP05 | nms_window_pair.sv、nms_classify_pair.sv / recent/older/N1/N2 | T05/T06 | 原幅值合同 |
| R2-REQ05/CN-05 | N/C0/IF06/OP05 | TL/TH/class/strong_count/weak_count | T05/T06 | 严格比较，未实现 |
| R2-REQ06/DER | 全部/FK，IF02…07/OP01…05及C0-OP01…08 | canny_fork_pair.sv / held/两pending/fire | T04/T07/T08及C0-T01…08 | C0设计独立审阅；全部运行未执行 |
| R2-REQ07/原FE/C-W | C0/IF02/04E/07/OP01及附件§2…8 | fe_status_snapshot/r2_status/fe_cancel_sent/错误与计数 | T06/T08及C0-T01…08 | CS592/DERR120设计闭合；未实现/未运行 |
| R2-REQ08/T4-B4/A2/A5 | RGB/CTRL，IF08/OP06 | 对齐/控制/显示文件与符号待独立设计 | T09 | B03未闭合 |
| R2-REQ09/派生工程要求/B5 | OBS/IF09…11/OP07及OBS-OP01…05 | r2_pattern_pair_source/r2_job_supervisor/r2_result_crc_observer/reset_sync/r2_algorithm_top及工程 | T10/T11及OBS-T01…09 | B04仅设计关闭；608bit/终态/四pin/时序预算已审阅，NOT_RUN |

每个拟新增单元有真实需求或派生接口责任；反向禁止把旧物理task/writer或分类伪边缘塞入本流段。整体闭包/识别继续[整包D](design-TRACK4-ALGORITHM-BATCH-001.md)，不删除其质量/终止/存储义务。

## I. 当前门槛

数值规则、主要路径、窗口/方向/分叉草图、C0终态及OBS工程已有实际内容。两份附件最终hash经两路全文复核，本版组合回写仅关闭B01/B02/B04设计问题；B03/B05仍存在，LOCAL_DESIGN不能标READY。OBS原附件保留写入时的“待审阅/回写”措辞，其后来审阅事实以绑定12D0…1847的审阅记录为准；不能将旧时态误作当前已执行。主稿保存后核链接/表格/字段/39来源hash与独立相容性，见[本次审阅](../experiments/track4_algorithms_20261004/03_review/r2-review-v0.3.md)；设计检查不产生运行PASS。
当前无用户批准本版或整包，不能生成业务实现、功能脚本、参考/TB或跑工具；也不另发本未READY版本的审批问题。

## J. 变更与恢复

采用原Canny数值而去掉旧物理父任务依赖；R2 wrapper拟内含FE、C0唯一owner，原R1/FE文件不修改。若后续选择外部FE接口须重新修订IF02与状态，不把两种owner混用。改变补边/舍入/方向/相等/阈值、ctx、取消或RGB存储时回核B/D/E/F/G/H。
v0.2新增[C0附件](../experiments/track4_algorithms_20261004/02_design/canny-stream-controller-sketches-v0.1.md)：CS592/DERR120、旧取消归因、持续cancel、共同FP许可、下一ABORT flush及本地q地址约束；覆盖旧窗口父控制清理文字，原FE自身错误时刻不改。恢复核[历史v0.1](design-TRACK4-ALGORITHM-R2-001-v0.1.md)/最新版本/来源/批准；候选基线不是整包冻结。

v0.3纳入OBS最终附件及实际审阅，新增IF09…11/OP07/REQ09/T11；新记录是608bit而非R1 160bit，CS接纳和sticky排空交接明确，R1保持原hash。v0.2实际同hash保存在[历史快照](design-TRACK4-ALGORITHM-R2-001-v0.2.md)，旧30/35来源清单和旧审计按其当时版本使用；当前候选39清单用此快照取代可变主稿作为来源，不制造自引用hash。

## K. 实录

仅数学与接口调查、新文档/候选基线；0业务源码/模型/TB/功能脚本/工程，全部功能仿真/综合/PNR/STA/bit NOT_RUN。原源/正式Manifest/H0/数据库不变，无DDR器件、新安装/网络工作。20/28 RAM、≤22000XLR和0DSP仍是预算/目标；允许合法裁剪且核必需历史/真实扇出。

## L. 阅读和操作路径

完整设计包B/C/D→本B外部数值→C模块→D交接→OP01任务→OP02窗口→OP03方向→OP04分叉→OP05分类→OP06未决交接→OP07观察工程→F/G/H。旧窗口/方向附件只展开被采纳的纯算法章节，旧物理来源不构成本版实施前置。后续实际源码/波形/GUI/日志位置在获批实施后补回，当前理解验收待用户反馈。
