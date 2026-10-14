# Canny窗口：四行Gaussian、两行NMS与逐沿交接 v0.2

2026-10-04；TRACK4-CANNY-001的局部设计附件，**LOCAL_DESIGN / NOT_APPROVED**。先读[整体02](../02_system/overall-design-layout.md)、[交接03](../03_interfaces/handoffs-and-composition.md)和[Canny主稿](../../../planning/design-TRACK4-CANNY-001.md)B/C/D，再按本页顺序阅读。这里提出窗口执行结构，未生成RTL、参考程序、脚本或testbench，未运行功能验证。

## 1. 边界、事件与表示

生产W=1920/H=1080；静态参数候选W为偶数6…1920、H为5…1080，D=W/2，P=H×D表示pair数，N=2P表示像素数，不能把P与主稿的N混用。小图独立实例，不在任务中改变行长。尺寸、输入顺序/标志和三ID由协调器检查后交付窗口；完整job拒绝/状态端口仍由CN-B06冻结。

所有窗口同core时钟上升沿，输入/输出只按沿前valid与ready交接。真实输入的x_even=2q，y=r；lane0在payload低位，对应偶列，lane1对应下一列。窗口输出的坐标属于中心像素，SOF/EOL/EOF由中心坐标重建，不能直接延用用于补边的当前输入标志。三ID在start时绑定本实例所属job，各级有效事务及控制归属不变。

| 内部连接 | 数据/单位/范围 | 有效与拥有者 |
|---|---|---|
| Msrc→C1 | 每lane unsigned8，pair16；有限原图灰度 | 仅REAL接受；pending持有真实pair、r/q及RAM选择 |
| C1→C2 | 每lane unsigned12，pair24；纵向加权和0…4080 | V1/V2及中心y/q/kind、event_valid同条件推进；不除16 |
| C2→新Sobel | 每lane unsigned8，pair16；完整Gaussian图 | 最后一次舍入后交付；包含全部N像素 |
| C4→NMS窗口 | lane16=bit10:0原始Mgrad，bit12:11 dir，bit15:13=0；pair32 | 低16bit为lane0；只保存幅值/方向，不保存全部Gx/Gy |
| NMS窗口→比较级 | 每lane九个16bit容器，行优先a…i；lane0低144bit，pair288 | 中心为e；邻居幅值均来自抑制前Mgrad；dir只取中心e |

start/flush/rst为同域控制，不等待下游ready，优先级rst>flush>start>正常推进。rst屏蔽接口交接；复位和flush清有效位、pending和phase，关闭该沿全部新RAM读写，不清RAM数据。start只在旧任务局部empty且协调器允许时发出，清历史/算术有效位后进入REAL；接纳start沿不接受首个像素。已有沿前输出握手若与flush重合，仍属于旧job已交付前缀，旧job整体作废；尚未交付内容撤销。独立取消可以禁止输入；由本沿错误形成的flush不能反向抹去触发错误的输入接受事件，避免错误/ready组合环。

## 2. G-W01：Gaussian四行原始数据的存取

四个bank B0…B3，各提供一行D个双像素原灰度的位置；覆写期间同bank不同q可能分别属于新/旧行，不能把整bank始终看成一条完整行。行r的写bank为r模4；当前输入留在pending，历史读值在下一可推进沿使用。每bank的两个lane各用一块1024×8 EFX_RAM10，总计8块；读写模式/有效极性/OUTPUT_REG=0/RE保持等沿用[FRONTEND E3](../../../planning/design-TRACK4-FRONTEND-001.md)的已读物理模型契约。地址q为unsigned10且q<D，未使用地址不访问。每块一读一写，避免同址，不靠READ_FIRST解决碰撞。

发起phase为IDLE、REAL、BOTTOM0、BOTTOM1、TAIL、WAIT_EOF；pending独立记录NONE/REAL/BOTTOM0/BOTTOM1/TAIL及r/q/真实pair/读bank选择。同一沿可以消费旧REAL的最后延迟写，同时发BOTTOM0首个读，不能按新phase误删旧写。

| 被消费的真实行r | 可用旧历史/本组当前值 | 为中心行形成的五个纵向样本 |
|---|---|---|
| 0、1 | 仅完成当前pair延迟写 | 不输出纵和，不读取未建立的历史参与计算 |
| 2 | 行0、行1、当前行2 | 0/0/0/1/2，中心y=0 |
| 3 | 行0、行1、行2、当前行3 | 0/0/1/2/3，中心y=1 |
| ≥4 | r−4、r−3、r−2、r−1、当前r | 中心y=r−2 |

每次允许推进，先用旧pending与旧RAM读回形成V1，并提交旧REAL的唯一延迟写，再按旧发起phase决定新请求；无新事件时pending变NONE。pending.r指真实输入行，V1/V2.y指纵和中心行：REAL r2/r3变为y0/y1，r≥4变为y=r−2，BOTTOM0/1变为H−2/H−1。r0/r1只存原图，r2起只对实际需要且已建立的历史bank使能读；顶部重复来自同一有效样本复制。r≥4读最旧bank后再在下一推进沿覆写同组，纵向计算读取覆写前值。

持续输入时同bank的新读是q+1而旧写是q；跨行是读0、写D−1；D≥3使地址不同。真实输入气泡时旧pending仍可消费并写一次，新pending为空；不能把气泡当黑像素，也不能保留有效pending再重复写。停顿时RE/WCLKE/WE均为0，RAM读输出与pending保持，恢复沿先消费它，再发新读。

底部两次重放只读最终四行H−4…H−1：BOTTOM0为中心H−2，五行H−4/H−3/H−2/H−1/H−1；BOTTOM1为中心H−1，五行H−3/H−2/H−1/H−1/H−1。重复末行取同一bank读值。每次发D组，重放自身不写；首BOTTOM0读q0可与旧REAL末q的延迟写同沿，地址不同且当前组所需末行q0早已写好。BOTTOM0末q与BOTTOM1首q同沿交接只读，无修改。

## 3. G-W02：12bit水平历史与右侧补边

输入纵和按中心行y、组q顺序到达。水平历史col0/col1/col2/col3为四个unsigned12列值，共48bit，另有所属中心行、组号和有效位；与算术寄存级H1/H2/H3明确区分。两lane的运算共用这份连续列历史，不各自建立独立断开的窗口。

首q0的两个值a=v0、b=v1只建立历史[v0,v0,v0,v1]，不输出。q≥1到达a=v2q、b=v2q+1时，lane0五列取[col0,col1,col2,col3,a]，lane1取[col1,col2,col3,a,b]，中心列分别2q−2/2q−1；随后历史变为[旧col2,旧col3,a,b]。q1因旧历史复制v0，恰好实现两列左补边。

下一中心行q0到达时，先用旧行历史形成旧行末pair：lane0为[col0,col1,col2,col3,col3]，lane1为[col1,col2,col3,col3,col3]；同时用新a/b建立新行[v0,v0,v0,v1]。输出坐标仍为旧行W−2/W−1，新历史归新行。末BOTTOM1之后发一个TAIL类型事件，经与纵和相同的V1/V2控制延迟到水平级，仅用旧历史形成最终右补边pair并清历史有效位。TAIL没有新Msrc、没有RAM读写，也不增加真实输入计数。

## 4. G-W03：五个算术寄存器与统一推进

选择Gaussian模块内统一advance=末级H3为空或该沿会被下游接收；这是本模块局部推进，不冻结整个FRONTEND/Canny链。所有pending、RAM使能、V1/V2、水平历史及H1/H2/H3在这个条件下推进；REAL输入ready依据旧phase=REAL及advance，rst和独立控制取消/flush可直接禁用。由本沿真实接受后发现错误而形成的flush不反馈参与该输入ready生成，只禁止合法投递/该沿RAM操作并清有效状态。advance为0时全部保持，RAM使能为0。advance为1且没有新有效事件时相应首级插入气泡，旧级仍推进，内部BOTTOM/TAIL无需上游valid即可发起。

| 寄存级 | 基于旧状态形成新值 | unsigned位宽/界限 |
|---|---|---|
| V1 | 五样本外侧和、近侧和、中心×6；近侧后续×4 | 外/近9bit≤510；中心项11bit≤1530；保留同中心元数据 |
| V2 | 外侧和+4×近侧和+中心项 | 先扩12bit再移位/相加，纵和12bit≤4080 |
| H1 | 水平操作G-W02产生五样本的外侧和、未乘4的近侧和、中心×6 | 保存外/近13bit≤8160、中心项15bit≤24480 |
| H2 | 合并水平外侧和+4×近侧和+中心项 | 各项先扩16bit，近侧移2再相加；近侧加权≤32640，总和16bit≤65280 |
| H3 | (旧H2总和+128)右移8 | 16bit加法≤65408，输出8bit；唯一舍入 |

V1计算时读取旧RAM结果；V2只读旧V1；水平/H1只读旧V2及旧水平历史，H2只读旧H1，H3只读旧H2。不能把中文步骤的顺序视为同沿串穿五级。V1/V2各有event_valid及kind：COLUMNS表示有效纵和事件，TAIL表示有效控制事件；TAIL的event_valid=1但数值字段不使用。warmup或没有旧pending才插event_valid=0气泡。水平历史仅在有效COLUMNS/TAIL更新，气泡不能重复使用旧V2；H1遇首q0只建历史，输出valid=0，遇TAIL才形成末pair。BOTTOM数据是合法中心pair。H1/H2/H3的SOF/EOL/EOF、x/y和身份与数值一起冻结/推进。

有限控制表示：bank编号2bit、phase/pending_kind各3bit、q10bit、r/y11bit、x_even11bit、pair计数21bit（界限P）、三ID各32bit。V1每lane保存9/9/11bit三个项，V2每lane12bit，H1每lane13/13/15bit三个项，H2每lane16bit，H3每lane8bit；有效位与事件kind另存。水平col0…3共48bit，归属y11/q10及有效位；pending保存真实pair16、q/r与读bank选择。以上列出有界表示，不是已综合寄存器数量或完整父端口编码。

## 5. G-W04：无停顿边沿表及局部结束

以下是假定start已完成、首个真实pair在e0接受、真实输入无气泡、输出持续ready、内部无flush的设计推导；不计父级等待和DDR。P为pair数量。

| 边沿 | 请求/旧pending与流水事件 |
|---|---|
| e0…e(2D−1) | 接受原图r0/r1，延迟写，无纵和输出 |
| e(2D) | 接受r2/q0、读已建立历史 |
| e(2D+1) | q0进入V1；请求r2/q1 |
| e(2D+2) | q0进入V2；q1进入V1 |
| e(2D+3) | 水平级用q0建历史；q1进入V2 |
| e(2D+4) | q1使首pair(0,0)进入H1 |
| e(2D+5)/(2D+6)/(2D+7) | 首pair进入H2/H3、随后最早实际交付 |
| eP | 发BOTTOM0/q0，提交旧REAL末pair唯一延迟写 |
| e(P+D) | 发BOTTOM1/q0 |
| e(P+2D−1) | 发BOTTOM1末q |
| e(P+2D) | 末q进入V1，同时TAIL事件入pending |
| e(P+2D+1)/(P+2D+2) | 末q进入V2/水平H1，TAIL依次进入V1/V2 |
| e(P+2D+3) | 水平级消费TAIL，最终pair进入H1 |
| e(P+2D+4)/(P+2D+5)/(P+2D+6) | 最终pair进入H2/H3、随后最早交付EOF |

W6/H5时D3/P15，首e13、末e27，共15pair；HD候选首e1927，末e1038726，100MHz分别19.27µs/10.38726ms。这是设计估算，未仿真。首pair形成后无气泡/停顿时每沿可交付一pair，不在每行之间固定插空。

WAIT_EOF不再接真实输入或新读。最后H3实际EOF交付、所有pending/算术有效位为空且水平历史已清后才能回IDLE并声明局部empty；沿前empty为0时父协调器不能同沿提前复用。输入EOF接受、最后计算形成、输出EOF交付、局部empty、DDR写fence分别是不同证据。缺失输入/永不ready由父任务取消政策处理，不自行超时成功。

## 6. N-W01：NMS的两行16bit容器存储

这里的16bit是13bit有效数据的容器。原RAM10的16bit原生模式仅512地址，不足生产D=960，所以每lane拆成低byte和高byte两块1024×8；一行两lane共4块，两行共8块。byte0保存Mgrad[7:0]；byte1的低3bit保存Mgrad[10:8]、bit4:3保存dir、bit7:5为0。四个byte平面共用同一rd/wr使能、地址和pending，禁止各自反压。合并时仍为lane16/pair32，无有损转换。HD逻辑历史49,920bit、容器61,440bit、8bit模式可寻址总容量65,536bit、占用8块RAM10名义81,920bit是四种口径，不能混称使用量。

recent/older所有权及REAL→REPLAY→TAIL→WAIT_EOF、延迟写和读输出保持沿用FRONTEND E3/E4的两行算法，数据宽度按上述拆分扩展。r0写recent不输出；r1用recent/recent/当前构造三列；r≥2用older/recent/当前；消费REAL时写当前到recent，并在r≥1把旧recent写older。REAL末组的旧延迟写与新REPLAY q0并存；底行重放older/recent/recent，重放本身不写。

每个垂直列是上/中/下三个16bit容器，共48bit。水平历史L/C0/C1共144bit：首有效行q0令L=C0=首列、C1=第二列；q≥1时lane0取旧L/C0/C1，lane1取旧C0/C1与新首列；随后L=旧C1，C0/C1=新两列。下一行q0或最终TAIL先生成旧行末pair，lane1右列复制C1；新行q0同时建立新历史。输出每lane按三行×三列排为a…i，a容器位于该lane最低16bit，i位于最高16bit；容器内Mgrad/dir不能被当作纯16bit幅值比较。

窗口推进条件为输出寄存器空或将交付；停顿关闭8块RAM的全部读写并保持pending/所有byte读回/水平历史/输出。气泡仍消费已有pending一次，尾重放独立排空；start/flush及同沿输出交付语义见第1节。window empty要求phase=IDLE、pending=NONE、水平/输出有效位清零；start后REAL即使尚未有首像素也不为空，普通valid=0不代表结束。输出EOF交付沿前empty仍为0，沿后满足清空条件才可能为1，父级最早下一沿采样。连续输入e0开始时，窗口首交付e(D+3)、末e(P+D+2)，W6/H5为e6…e20。只证明该窗口局部，不据此宣布整条Canny延迟。

## 7. N-W02：窗口到分类的两级交接

比较级N1从实际接受的完整窗口提取中心Mgrad/dir及主稿规定方向的负/正邻居幅值：H为d/f，NW–SE为a/i，V为b/h，SW–NE为g/c。锁存中心坐标、外框标志及TL/TH配置快照；dir来自中心e容器，幅值比较只取容器bit10:0。C4输入和NMS历史仍保留外框的原始Mgrad；相邻内圈可能需要比较这些值，不能提前把外框幅值置0。N2基于旧N1比较中心>负邻、中心≥正邻、中心>0且不在外框；满足才有Mnms=中心，否则为0，外框只在这里抑制。再按严格>TH、>TL的主稿规则形成两lane各2bit初态。N2的整个payload和计数贡献停顿保持，strong/weak统计只在分类pair实际交付时各增加0…2，不因保持valid重复累计。

分类pair为4bit，lane0在低2bit；strong/weak贡献各2bit且取0…2，与中心x/y各11bit、SOF/EOL/EOF一起valid&ready交付。各窗口clk/rst/start/flush和握手/empty均为1bit；rst同步高有效。三ID可引用C0不可变快照而不逐级存96bit，但该快照必须保持到全部子级/物理承诺排空及父status消费，不能引用FRONTEND当前外部job字段。TL/TH各11bit来自这份固定job快照；方向级/父终态完整端口仍未冻结。

N1/N2采用本模块统一推进条件“末级为空或将交付”，气泡不形成状态；class writer不ready经比较级反压窗口，窗口再反压C4的NMS支。若窗口输入e0开始连续、无气泡/停顿/flush且全部ready，首分类最早e(D+5)、末e(P+D+4)；这两级没有改变每行像素数。分类EOF交付及比较级empty依次成立后，分类writer仍需封口/尾拍/响应fence，不能直接启动BFS。

## 8. 局部不变量、文字验证与追踪

G-W01…04承担CN-02及CN-INV01/02/09；N-W01/02承担CN-04/05及CN-INV01/03/09。主稿CN-OP02/04应按本页执行，而不是另写相冲突的草图。raw历史不含上job有效位、重放不增加真实计数、每输出pair的两个中心连续、同bank同时读写地址不同、停顿使能为0、EOF仅交付一次是局部检查条件。

新增文字场景CN-T15：W6/H5每行/每列不同值，r2/r3、ring覆写、两个底部中心、跨行末pair及TAIL；分别在REAL末写/首BOTTOM、V2 q0/q1、H3 EOF停顿或插气泡/flush，核查请求与唯一延迟写、首末边沿、P pair/中心及独立25项卷积。手算样例Msrc(r,x)=16r+x的G8五行依次为[6,7,8,9,10,11]、[17,18,19,20,21,22]、[32,33,34,35,36,37]、[47,48,49,50,51,52]、[58,59,60,61,62,63]，属于预期值推导。总pair数由H(D−1)个同行结果+(H−1)个跨行末组+1个TAIL=HD证明。

新增文字场景CN-T16：Mgrad=255/256/1023/1024/1530与四个dir交叉，recent/older/重放/跨行、各byte同时停顿、四方向平台、较大外框幅值与内圈中心比较；核查高低byte合并/保留位零、D+3及分类D+5局部延迟、P数量、贡献只按交付累计和独立邻居参考。两场景及既有CN-T01…14全部未运行，不生成可执行验证。

Gaussian→新Sobel使用完整G8图，不能借原Msrc的外侧窗口代替；新Sobel再建立自己的有限3×3边界。C4的梯度写图与NMS窗口分别握手；方向级和分叉的精确端口/级数、父任务生命周期、DDR fence仍未完全冻结，因此本页不相加出整条固定延迟，也不关闭CN-B03…08。40块RAM预算中的Gaussian8/NMS8保持不变；额外寄存器/逻辑与时序未综合。

## 9. C-W01/02：父任务流段与分叉的交接

本节细化CN-OP01/03/04/08及CN-IF08，仍为父接口冻结前的提议。C0拥有单job完整快照、stream_started、fe_job_proposed/accepted、fe_status_seen（各1bit）、完整FE状态快照、abort_pending及原因；各流连接的pair计数分别21bit、EOF实际交付标志分别1bit。FE快照包括code3、三ID各32bit、in/out计数各21bit、错误坐标各11bit。FE计数和分类pair计数比较P；分类strong/weak及边缘像素数量比较N。父错误码/同沿原因优先级在CN-B06，不擅自编码。

**C-W01 启动与完成证据。** eJ接受并检查父job，锁住配置/尺寸/句柄，该沿不接像素；只有合法配置且无abort才进入独立ARM沿eS（最早eJ+1），依据旧已锁快照向所有流子级发一次共同stream_start，该沿仍不接像素。start未被rst/flush覆盖才置stream_started，非法job不启动子级。FE的FJ另以同一快照valid&ready接纳，提出后等待时保持。C0只有在stream_started和fe_job_accepted都成为旧已置位状态后才开放Msrc接受。每job只发一次start，输入静止或FE status消费都不重发；FE提前回IDLE不释放C0的借用/快照。

取消后尚未提出FE FJ可以不启动FE，父层记录“未启动”而非伪造FE CANCELLED；已提出未接受的FJ按保持义务等待接纳，再在后续ACTIVE沿取消。与模式命令同沿已接纳的父job/FJ按旧配置登记；FE在IDLE忽略cancel，不能只在FJ接纳沿发一个取消脉冲。父abort优先于成功，真实沿前各流输出/DDR接受仍逐接口登记，剩余局部数据flush，已提出burst仍由writer结清。

| 完成证据 | C0使用前提/不能替代的证据 |
|---|---|
| fe_status_seen | FS真实握手后保存，检查三ID/code及P计数；不能只看FE IDLE |
| 流EOF交付/计数 | 每接口单独登记，NMS/grad两支取消前缀可不同；形成EOF不是交付 |
| stream_empty | Gaussian、新Sobel窗口/算术、方向、fork、NMS窗口/比较级局部empty合取；首数据前算术也可能全空，不能单独触发成功 |
| writer封口/fence | 停止新写、尾拍/剩余请求交付，再取得相应全部响应成功；局部flush/empty不能代替 |
| 分类可移交seed | FE不可变OK且身份/计数相符，分类P pair和必需grad P pair交付，必需EOF/局部结束，class/grad分别封口并fence；grad关闭显式免除该支，不伪造其EOF |
| C0局部OK | 还需精确闭包结束、最终N像素及自身全部必需fence/排空；源有效和可发布资格仍由MOD-10汇合 |

C0至少在最后必需EOF交付后的一个后续沿观察旧已锁EOF/计数及stream_empty，不与末EOF握手同沿复用。父快照保持到全部子级和物理承诺排空、父status实际消费；下一job端口空隙及完整终态规则仍在CN-B06冻结。

FS-01接收独立于Gaussian/NMS empty、分类fence、BFS/识别和最终输出：C0已拥有该FE job且状态缓存空时允许status交接，ABORT_DRAIN仍消费终态以避免等待环。保存后再检查，身份错为父协议失败。FE OK与C0 cancel同沿应保存真实FE OK，C0自身失败；迟到源/DDR错误也不回写已形成的不可变FE status。

**C-W02 分叉旧组与新组。** fork只有一个held payload及held_valid/nms_pending/grad_pending；empty要求三者全为0。两支valid只由旧held_valid及各自旧pending产生，均展示旧payload。每支旧实际握手只清自己的pending；已接收支valid=0，不再参与待释放条件，另一支可继续等待。旧held为空，或旧所有pending在本沿都可交付时，才有接纳同job下一pair的容量；新payload只沿后进入held，不在同沿透传消费者。

若旧组全部释放并同沿接纳新组，新payload及新pending初始化覆盖旧清位结果：NMS pending=1，grad pending=retain_grad；不得让旧分支的清位清掉新pending。仅释放而未接纳则清held及pending。flush最终清本地有效位并禁止新接纳，但旧真实交付仍登记；start不接新pair，rst屏蔽传输。接纳本job EOF后不再收额外pair；替换容量不能被用于跨job提前启动。

新增文字CN-T17：首数据前算术全空、共同start与首输入分沿、FE早OK而Canny尾部阻塞、FE OK与取消同沿、FJ提出/接纳与取消交错。新增CN-T18：分支独立反压/单支已收、旧两支释放与新组接纳同沿、旧空接纳禁止透传、两支EOF、grad关闭、取消同沿。两者未运行，分别检验快照/状态证据及old/new提交顺序；完整job/status、方向最终级数、父阶段/原因优先级、DDR安全排空、地址/租约继续BLOCKING。

## 10. 修订与阅读回路

本页细化v0.1尚缺的CN-B01/02执行草图，采用五个Gaussian算术寄存器、NMS两级比较及8bit RAM平面结构；这些是新的设计提议，不能冒充已有FE批准或实现。主稿与索引同步到v0.2，原FRONTEND v1/28项输入及FRAME-MANAGER v0.1不修改。按窗口草图→主稿F/G/H→05审查→当前文档检查读回；窗口逻辑经独立审查后仍要在完整端口和基线冻结时复核。

尚未完成代码—注释—文档一致性、功能仿真、综合/PNR/STA或bit/hex交付；理解验收也需用户实际反馈。修改补边、布局、推进、延迟、启动/取消/FE状态或分叉时，回到本页对应G-W/N-W/C-W、主稿CN接口/操作及T15…18一起修订。
