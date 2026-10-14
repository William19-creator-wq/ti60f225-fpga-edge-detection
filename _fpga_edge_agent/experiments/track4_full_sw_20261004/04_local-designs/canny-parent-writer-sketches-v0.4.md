# Canny父任务、方向流水与顺序writer中文草图 v0.4

2026-10-04；TRACK4-CANNY-001局部附件，**LOCAL_DESIGN / NOT_APPROVED**。先读[主稿](../../../planning/design-TRACK4-CANNY-001.md)B整体行为→C职责→D交接，再读本页job/地址→方向→writer→协调阶段→失败/恢复→验证。[窗口v0.2](canny-window-sketches-v0.2.md)、[存储v0.3](canny-memory-sketches-v0.3.md)继续有效；本页为补充候选，尚未生成RTL、参考程序、功能脚本或testbench，全部业务验证NOT_RUN。

## 1. 整体边界与当前来源

C0锁完整job并及时保存FE/feed/存储证据；C3/C4产生Gaussian上的梯度/方向；fork两支各一次；CLASS/GRAD local terminal及CLASSIFICATION fence等必需证据齐全后才移交状态图；精确闭包或严格等价快路径后，C8把标量状态聚合为EDGE pair，EDGE writer封口/fence后给父终态。C0不分配源/结果/workspace、不发布HDMI bundle、不自造真实DDR排空。

来源为[FRONTEND v1](../../../planning/design-TRACK4-FRONTEND-001.md)、[FM v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)、既有窗口/存储附件及[DDR实际调用链](../01_baseline/ddr-address-and-completion-evidence-v1.md)。FE原三ID/6级Sobel和状态编码不改；FM完整句柄、grant/FE共享租约及MOD-05 fence/恢复仍需相邻稿统一。下面字段、编码和地址是设计提议，不冒充原IP端口或已批准基线。

## 2. P-J01：完整job、绑定及流/控制端口

同core正沿valid&ready接受；所有unsigned，signed梯度另注明。C0仅一个job，提出后payload保持，首像素与job/start分沿。

| job字段 | 位宽与合法性 |
|---|---|
| epoch/frame_id/config_id | 各32；允许0，只按相等匹配 |
| source_slot/source_generation | 3/64；slot0…5，完整句柄不只slot |
| result_slot/result_generation | 2/64；slot0…2 |
| job_sequence/capture_sequence/policy_generation | 各64；全部保存/回显，不互相替代，不按外三ID大小排序 |
| workspace_slot/workspace_generation | 1/64；当前唯一workspace_slot=0 |
| W/H | 各11；W偶数6…1920、H5…1080且等静态实例 |
| median_enable/Tlow/Thigh | 1/11/11；TL≤TH，范围0…2047 |
| retain_grad/recognition_enable | 各1；识别启用必须retain_grad=1 |
| CLASS/QUEUE/GRAD/EDGE | 每区域base32/logical_bytes32/physical_bytes32；关闭GRAD时其描述符全零 |

以上917bit为字段预算，不能当实际FF结果。ID/代次允许0；上层分配器在任何序列或代次耗尽前停止新授权，不能静默回绕。C0不替上层证明跨job身份唯一。

job_ready依据旧IDLE、无旧承诺/逻辑响应/本地借用、无未交付status/恢复屏障；非法配置可被接受后REJECTED，不靠永久ready=0隐性拒绝。eJ锁快照并核验尺寸/配置、槽、描述符、扩宽范围和既有grant；非法job置reject_pending进ABORT_DRAIN，不ARM/FJ、不接像素/DDR；仅在已核验未取得任何绑定，或父实际绑定记录的未启动归还证明齐全后形成REJECTED/drained1，否则继续等待，无法证明则隔离。不得以未核验job句柄释放别的绑定。job字段不是自授权证明：父MOD-04/05绑定记录必须核验完整source/result/workspace/job key与区域权限，并提供本job的FE独占租约和归属路由。具体查询/返回物理端口尚未冻结，仍BLOCKING。

C0只向FE提出三ID、median快照、Y_ONLY和threshold=0。RGB base/读取请求由父reader持有；Msrc采用FE的两Y8、x_even11/y11、SOF/EOL/EOF及三ID。每次实际Msrc握手先计数，再核验身份/坐标/标志；坏组不进入Gaussian但保留接纳事实。错误生成的flush不能反馈抹除触发握手的ready；独立cancel、旧abort、rst可禁止新接纳。

| 独立通道 | 候选内容及保持/接受 |
|---|---|
| FE FJ/FS | 完全沿用FE v1；FS接收槽独立于writer/fence/BFS/status ready，真实FS快照保存后才核验 |
| feed_terminal | valid/ready；三ID各32、job_sequence64、source句柄3+64、success1/drained1、actual_pairs21/error3；证明旧RGB请求/返回/适配像素已结束 |
| feed error3 | 0 NONE、1 SOURCE_INVALID、2 READ、3 COUNT、4 ID、5 CALIBRATION、6 RESET、7 INTERNAL；不是MC或相机原码，原始来源另外保留 |
| abort/ack | abort valid/ready、epoch32/job_sequence64、cause2：0人工/1源失败/2策略/3平台；ack valid/ready、相同key及ack2：0 APPLIED、1 ALREADY_ABORTING、2 TOO_LATE_STATUS、3 NO_MATCH |
| 子级start/abort | 同core共同事件，start每job一次；私有未承诺输出/claim/pop由明确共同abort终结，内存valid不受此撤销 |
| 父status | valid/ready，内容一次形成后保持，不能以status消费代替源/结果/workspace回收 |

feed终态及时保存；success要求actual_pairs=P且完整scope匹配，drained证明没有旧输入还能进入FE。FE IDLE/FS不能替代reader排空；feed未关闭则不归还FE输入租约、不接下一job。success0/error0且drained1只表示已取消或从未打开的输入会话，须与C0 reject/abort相符，不计成成功P；无abort时收到这种终态为失败。若父绑定尚未启动reader，也要用明确“无请求/无返回/输入关闭”的归还证据，不伪造成功完整P。拒绝且未启动的job返还仍经父账本确认。

## 3. P-A01：长度、地址与租约草图

尺寸先检查，再用扩宽乘积求N=W×H和P=N/2，核验后才存N21/P21；长度算术先用unsigned32，base+length先扩33bit。物理区间半开，必须不溢出、不重叠、不越容量、且与绑定grant完全对应。访问padding必须也在grant内。

| 区域 | logical_bytes L | physical_bytes A | 对齐/访问 |
|---|---|---|---|
| CLASS | ceil(N/4) | 64ceil(N/256) | base64B；分类writer写全A，cache整线读写 |
| QUEUE | 4N | 16ceil(N/4) | base16B；逻辑entry0…N−1，padding不入队 |
| GRAD | 4N | 16ceil(N/4) | base16B；两lane grad32，保留位零 |
| EDGE | ceil(N/8) | 16ceil(N/128) | base16B；逻辑N个bit，其余零 |

本候选job的physical_bytes等最小A；4KiB allocation_bytes仅分配槽间距，页尾空隙不授给writer，也不要求全写。N30：CLASS L8/A64，QUEUE与GRAD L120/A128，EDGE L4/A16。CLASS后226状态、EDGE后98bit、GRAD最后8B都是明确零padding；不能拿紧凑L授整线权限。源RGB由父持L=3N/A=16ceil(3N/16)，两lane读取跨行仍保持原图坐标。

[地址算术清单](../01_baseline/canny-candidate-address-arithmetic-v0.4.json)是生产1080p候选，不是原IP配置或已授权内存图：

| 区域 | base | 分配终点（不含） | 每槽/区分配字节 |
|---|---|---|---:|
| SRC0 | 0x00001000 | 0x005F0000 | 6221824 |
| SRC1 | 0x005F0000 | 0x00BDF000 | 6221824 |
| SRC2 | 0x00BDF000 | 0x011CE000 | 6221824 |
| SRC3 | 0x011CE000 | 0x017BD000 | 6221824 |
| SRC4 | 0x017BD000 | 0x01DAC000 | 6221824 |
| SRC5 | 0x01DAC000 | 0x0239B000 | 6221824 |
| EDGE0 | 0x0239B000 | 0x023DB000 | 262144 |
| EDGE1 | 0x023DB000 | 0x0241B000 | 262144 |
| EDGE2 | 0x0241B000 | 0x0245B000 | 262144 |
| CLASS | 0x0245B000 | 0x024DA000 | 520192 |
| QUEUE | 0x024DA000 | 0x02CC3000 | 8294400 |
| GRAD | 0x02CC3000 | 0x034AC000 | 8294400 |

图像紧凑55209600B，页分配55226368B，增加16768B。低4096B留作隔离测试scratch；不假设PHY校准只访问此页。按假定2Gb容量268435456B，0x034AC000以后213204992B暂未分配，留待识别/其他真实布局设计；不会把未分配区当已授权限。该算术不证明受保护controller的byte映射或容量，需要真实模型读回。

六源沿用FM当前候选，下一SOF写租约期限仍未证明；增加源槽要修订本表，不能把本表当持续采集证明。小尺寸实例重新计算同一分配规则，不使用生产常量长度遮蔽padding问题。

workspace一次归一个Canny/识别job；retain_grad时父登记消费者读租约，识别最后读fence/显式归还前不重新授权同地址/代次。无读消费者也须父确认从未授读且写已排空后释放。C0 status消费只归还局部协议，不解除这些租约；grad不作为当前显示bundle的可变工作图。源BIND及结果引用仍由FM/JOIN维护。

## 4. P-D01：新Sobel、四级方向与分叉

C3在完整Gaussian G8图上使用独立两行3×3窗口，沿用FE F2的复制边界、pending/延迟写、水平跨行和TAIL契约；四RAM预算既有。算术复用FE F4六级时间/位宽，不使用FE F0的任务快照或pre-Gaussian梯度。

S1为四个unsigned9角点和及四个unsigned9中间像素×2；S2为四侧unsigned10；S3先零扩signed11再相减得到Gx/Gy；S4为abs10并延迟原梯度；S5为扩11后abs和Mgrad；S6交付同组Gx/Gy/Mgrad和中心坐标/标志。FE的中心/edge旁路不参与Canny分类。

| 方向级 | 每lane寄存/数值合同 |
|---|---|
| D1 | 原Gx11/Gy11/Mgrad11，梯度先sign_extend到signed12再取绝对值X10/Y10；合法范围0…1020后才窄化 |
| D2 | 原三字段；X/Y先扩unsigned20，各存P384=(X<<8)+(X<<7)、P40=(X<<5)+(X<<3)、P1024=X<<10 |
| D3 | 原三字段，X424/Y424=P384+P40，延迟X1024/Y1024，全部unsigned20 |
| D4 | 原三字段及dir2；Mgrad0→00；否则Y1024≤X424→00；再X1024≤Y424→10；其余梯度同号01/异号11 |

P384≤391680、P40≤40800、P424≤432480、P1024≤1044480，20bit足够。禁止先在10bit内移位；dir边界(128,53)H/(128,54)对角，零分量自然走H/V，Msrc为0不决定dir。D1固定检查signed12绝对值临时≤1020、Mgrad≤1530，以及双abs先扩unsigned12相加后等于zero_extend(Mgrad)；通过后才存X/Y10。错误实际D1握手照记、不投递该组D2，并经寄存DIR_VALUE事件给C0，不反馈本沿ready。此前合法各级/fork旧真实前缀仍登记，再由共同abort清私有valid；新增组合检查成本另计。

各级存同中心x_even11/y11及三标志；三ID/阈值/句柄引用C0不可变快照，不引用已消费FS后的FE快照。D1…4以“D4空或本沿D4可交付”为共同推进条件；旧级形成新级，无输入插valid气泡，停顿全部保持。尾排空不依赖新in_valid，EOF后不接受额外pair；四valid全空不能单独成功。

fork保存每lane Gx11/Gy11/Mgrad11/dir2共70bit，加坐标/标志25及valid/两pending。旧两支只输出旧held，各自实际接受一次；全部旧pending本沿释放才接新组，新pending覆盖旧清位，新组不透传。retain_grad=0时grad_pending/valid=0，grad_ready不参与容量/结束；不伪造该支EOF/fence。

同条件推导：F4窗口在e[k]接纳，S6在e[k+5]后有效，D1 e[k+6]接纳，D4 e[k+9]后有效，fork e[k+10]接纳，分支最早e[k+11]。若G8在e0…e[P−1]连续，C3窗口首D+3/末P+D+2，fork分支首D+14/末P+D+13。未计FE、ARM、DDR、writer/BFS；没有运行波形，不把它相加成整机固定延迟。

方向数据寄存约708bit、坐标/标志100bit、valid4，fork约98bit；无DSP设计目标，未综合。各模块靠自己的末级容量推进，不用整链ready统一冻结。由本沿错误形成的flush不能组合反馈到其握手ready锥；旧真实交付逐接口计数，私有valid清除不清writer承诺来源。

## 5. P-W01/P-W02/P-W03：CLASS、GRAD、EDGE顺序writer

入口均为完整两lane：CLASS pair4、GRAD pair64、EDGE pair2及偶数x/y、SOF/EOL/EOF；共用C0身份。成功各接P组/N像素，EOL不刷新打包字。每次实际握手先计接纳数，再核验预期坐标/标志/身份/值域；只有合法组写RAM和推进合法计数。CLASS初态11非法，GRAD各lane高8必须0。valid0无作用，stall保持全部payload；坏组不能通过反馈ready抹掉接纳事实。

CLASS/EDGE分阶段共享1块512×16 RAM10，两个256word半bank，每bank512B/最多32拍。carry16/bit_count5初值0：CLASS每pair放4bit，四pair整字WE；EDGE每pair放2bit，八pair整字WE。合法EOF沿先完成当沿应有整字写再关输入；carry非空下一沿提交尾word、高位0，carry为空不写dummy word。EOF恰写满bank则seal该bank并禁止再开空bank；无真实数据不发零长请求。CLASS bank容2048像素，EDGE容4096；只存真实word，A范围其余padding由冻结长度生成零，不读未初始化RAM。

GRAD用3块512×16并行，低24bit/lane组成pair48；lane0低24、lane1高24，各连续16bit段存一块。地址{bank2,pair_slot7}，4个128pair bank；每bank存768B有效位、重建1024B/64拍。每次真实pair一沿三块整字写；每beat读两个pair48，恢复各grad32高8零。尾bank奇数pair时高64bit half为0，不读无效槽。GRAD EOF直接冻结有效pair数，不等待CE carry或另一支EOF；若EOF恰满bank，不另建空bank。

所有RAM OUTPUT_REG=0/同core，整字WE；GRAD三块共地址/使能。只读SEALED bank、只写OPEN bank，返回空间含未capture预留；回收下一沿才重新分配。两个CE或四GRAD bank均占用则入口反压，后台不随入口停止。

每bank冻结owner/global byte offset、真实/物理长度、segment位置和借用。CE物理长度为min(512,A−bank_byte_offset)，GRAD为min(1024,A−bank_byte_offset)，只对正长度建descriptor；真实数据以外固定零，不增加P/N。满时使用末次合法接纳后的长度seal；CE尾bank有非空carry则待提交后seal，carry为空直接seal，GRAD依据冻结有效pair数直接seal、不等carry。每writer只选最早sealed范围；≤64拍及4KiB分最多2段，段内index/last重新计数。完整数据来源（真实RAM+固定零）备齐才提出req；提出后的owner/tag/addr/nbeats保持，W最早req_fire后提出。

三个顺序writer共享两个128bit W槽，FIFO每槽含tag16/index7/last及有效/预留；仅当前锁定write_owner/segment可组拍，不能预塞另一writer或尚未提出后段造成单live与FIFO头部互等。CLASS/EDGE每beat至多8次16bit读，GRAD至多2次并行pair48读；grant预留具体slot/lane或half，下一沿capture，两个槽占满则停RE但已有pending仍capture。W严格按段内index有序，stall不覆盖；可在一个槽待交付时组另一个。无停顿及充分空间时条件8沿/beat或2沿/beat，不含首拍/请求/响应等待，不证明物理W气泡许可或整机fps。

MC写方向单live，CLASS/GRAD/EDGE及queue/cacheWB采用有限轮转候选，owner在req提出时锁到段终结及本地借用归还；read_owner独立。CLASS/GRAD可独立封满发送，不能等另一支也满/EOF。fork已收支清pending，停另一支不重复已收数据。completion_ready不依赖fork、输入、claim或阶段成功；全局最低后台服务仍待MOD-05实证。

## 6. P-F01：封口、fence与writer终态

各writer保留不同证据：合法EOF且P/N正确→CE必要carry提交或GRAD直接seal、padding及所有bank封口→最后计划segment实际req_fire、无未提出业务→全部success/drained/actual_beats正确、物理A写完、W槽/RAM pending结清→独立LOCAL_OK local_terminal。LOCAL_OK只证明本writer的图与客户端事务完成，不含stage fence。C0先保存各local_terminal，再提出并汇合scope fence，fence成功单独保存，不要求writer回送含fence的第二次成功；末W/empty或计数0不代替。

local_terminal_valid/ready候选携带region3、完整job key/ctx引用、kind2（0 LOCAL_OK、1 REJECTED_NOT_STARTED、2 FAILED_DRAINED、3 QUARANTINED）、actual_pairs21/legal_pixels21/physical_done_bytes32、drained1/error3；形成后保持。C0每writer一个证据槽，ready只依赖该槽容量，独立于phase/fence/stream_empty/其他writer；GRAD可在STREAM先结束也及时保存。未启动支用required=0免除，不制造终态。

CLASS/EDGE共享RAM切换须CLASS LOCAL_OK已由C0消费、CLASSIFICATION fence成功、全部旧CE bank/tag及三writer共用W槽/pending结清。EXPORT首次发独立EDGE start，start沿不接EDGE pair/不发C8读，edge_started成为旧置位后才导出。CLASS末EOF沿不复用，不清RAM数组；writer local_terminal生成不依赖stage fence。

取消/错误禁止新增输入/未提出segment；实际旧握手照记，未承诺carry/bank可作废。已提出req及数据来源保持至合法终结；已grant读继续capture。失败drained terminal按MC-M01共同终结未接受逻辑W槽；已物理承诺必须先已排空。作废回收只等实际已提出段及借用，不等未提出后段，第一段成功后取消仍不能称整bank/图成功。drained0保留tag/bank/ctx及租约隔离，stream rst不得丢承诺数据。

跨4KiB文字场景须独立授合法测试grant，不能沿用页对齐生产表冒充跨界：CLASS512B/base低0xFC0→4+28拍；GRAD1024B/低0xFF0→1+63；EDGE512B/低0xFF0→1+31；N30 CLASS64B/低0xFC0→4拍恰边界，GRAD128B/低0xFF0→1+7，EDGE16B/低0xFF0→1拍恰边界。所有段内index重启、无空洞/零长段。

C0最多一条fence live，phase2=0 CLASSIFICATION(CLASS+必要GRAD)、1 SEED(CLASS/QUEUE)、2 CLOSURE(CLASS/QUEUE含读排空)、3 OUTPUT(EDGE)。required/seen/success/drained各4bit；快路径免除seed/closure位保持0，OUTPUT引用已锁GRAD成功证据。fence必须绑定完整job/scope且覆盖最后实际接受请求；token/服务序号及真实物理端口仍BLOCKING，不能用候选mask证明原controller保证。

新增writer存储4 RAM10，两个W槽数据256bit、carry16+count5、单RAM pending、2 CE+4 GRAD bank元数据及计数另计。已列FE/Canny窗口/cache/queue/writer累计44 RAM10，44/256=17.1875%；旧40仅前四类小计。MOD-05物理R/W缓冲、平台/显示/识别和完整ctx/控制仍另计，未综合/布线。

## 7. P-C01：启动、有限阶段与精确快路径

eJ接纳合法job，不接Msrc；最早eJ+1共同ARM实际生效，再提出FE FJ；eF接受FJ，最早eF+1在stream_started与fe_job_accepted均为旧置位状态后开放Msrc。start被rst/有效abort覆盖不置started；不因FE提前IDLE而重发。FJ尚未提出可不再提出，已提出则保持至接纳后在ACTIVE沿取消，接纳同沿cancel不能代替后续取消。

| phase5（候选编码0…22） | 退出条件，均看旧已锁证据 |
|---|---|
| 0 RECOVERY_LOCK | 安全初始化或匹配旧scope的恢复证明 |
| 1 IDLE | job真实接受 |
| 2 ARM | 共同start真实生效 |
| 3 FE_OFFER | FJ接受，abort仍结清已提出FJ |
| 4 STREAM | 最后Msrc EOF实际交付 |
| 5 STREAM_DRAIN | FE实际OK、必需EOF/计数、stream_started、所有流empty |
| 6 CLASS_SEAL | CLASS/必要GRAD尾打包、请求实际交付/完成、本地排空 |
| 7 CLASS_FENCE | 分类scope成功fence |
| 8 PATH_SELECT | 锁strong/weak并选互斥路径 |
| 9 SEED_SCAN | GENERAL全部N操作结果结清 |
| 10 SEED_SEAL | queue尾seal、state dirty flush、所有已发请求/借用结清 |
| 11 SEED_FENCE | fence成功，c=tail=seed_count=strong |
| 12 BFS | head=tail且无active pop/邻居/claim/miss/pending、pin归还 |
| 13 CLOSURE_SEAL | queue/state尾提交、读写及本地排空 |
| 14 CLOSURE_FENCE | fence成功且head=tail=c |
| 15 EXPORT | 独立EDGE start后，edge_started旧置位；edge_pixels=N/edge_EOF_seen、partial/pair均空、无SC req/pending/result |
| 16 EDGE_SEAL | EDGE padding封口、请求交付/完成、本地排空 |
| 17 EDGE_FENCE | output scope成功fence |
| 18 DONE_CHECK | 全部自身必需证据、匹配feed成功/P及关闭/排空已锁，无本沿abort/error |
| 19 ABORT_FE | 停输入并结清FJ/真实FS或独立FE reset证据 |
| 20 ABORT_DRAIN | feed/请求/逻辑消息/RAM pending/借用及实际绑定返还证明齐全；reject_pending无子级启动才REJECTED |
| 21 QUARANTINED | 等独立安全恢复，status消费不回IDLE |
| 22 STATUS | 仅OK/REJECTED/FAILED_DRAINED；不可变status消费后只回IDLE，下沿才接job；Q在phase21报告/消费仍锁住 |

stream_empty为Gaussian、新Sobel窗口/算术、方向、fork、NMS窗口/N1N2 empty合取。首次数据前全空不完成；最后EOF同沿不跳阶段或复用。FS随时独立保存真实code/ID/in_pairs/out_pairs/错误坐标；OK要求两计数P且等C0 Msrc数量，FE状态形成后不可回写。

path2：0 GENERAL、1 NO_STRONG、2 NO_WEAK、3非法。分类/fence后strong=0优先NO_STRONG，strong>0且weak=0为NO_WEAK，其余GENERAL；两快路径仍完成FE/分类/必要GRAD及N边缘/fence。

NO_STRONG按完整坐标生成0 pair，不读state/queue；NO_WEAK只经SC READ_STATE将初始10→1、00→0，01/11为阶段错，不seed/dirty写。GENERAL对全部N点CLAIM_STRONG，结果含state_before2/claimed1：10必须原子claim，00/01不入队，初始11报错；仅结果实际交付推进扫描，提交计数必须等strong。seed seal/fence后才BFS，BFS看到10为错，活动pop未结时暂时head=tail不能结束。

C8固定一个partial lane0和一个完整pair记录；SC发读前预留返回空间，pending计占用。lane0只在partial空时收；lane1仅在partial有效、同一行紧邻列且完整pair空或本沿被writer接收时收。旧pair交付/新pair形成同沿，新payload/valid覆盖旧清位，writer只看旧pair；SC响应ready只依旧容量，不反馈身份/坐标错误。SC响应接受推进读索引，EDGE writer接受才加edge_pixels2。GENERAL仅11→1、00/01→0，遇10登记实际SC握手后报EXPORT_STATE/作废，不生成对应EDGE bit、不反馈抹除ready；NO_WEAK按上述初态规则。GENERAL edge_ones=tail，NO_WEAK=strong，NO_STRONG=0；writer停顿不重复扫描。

## 8. P-C02：结果、原因、取消及恢复

status_result2：0 OK、1 REJECTED、2 FAILED_DRAINED、3 QUARANTINED；完整917bit job可引用锁定ctx而非重复副本。payload另有drained1/counts_final1/path2、end_phase5/first_error_phase5、first_reason5/terminal_reason5/cause_mask32、abort_cause2/valid1；stream_started、FE proposed/accepted/seen/reset_applied、feed_terminal_seen/feed_no_session证明；实际FS/feed快照；逐流pair_count21/EOF1；strong/weak/seed/edge_pixels/edge_ones/head/tail/c各21；四组fence mask4；错误坐标11×2/valid1、原MC error3/region3/tag16/valid1。邻居诊断若保留用24bit覆盖8N。各记录有界，ctx保持至全部物理/本地/消息和status结清。

reason5候选：0 NONE；1 BAD_CONFIG、2 BAD_GRANT、3 CANCELLED、4 POLICY_CANCEL、5 SOURCE_FAILED、6 FE_FAILED、7 FE_ID、8 FE_COUNT、9 MSRC_ID、10 MSRC_COORD、11 MSRC_MARKER、12 STREAM_COUNT、13 CLASS_STATE、14 SEED_COUNT、15 QUEUE_STATE、16 CACHE_STATE、17 EXPORT_STATE、18 EDGE_COUNT；19 MC_ACCESS、20 MC_RESP、21 MC_COUNT_LAST、22 MC_TAG、23 MC_CALIBRATION、24 MC_RESET_PROTOCOL、25 FENCE_FAILED、26 DRAIN_UNPROVED、27 INTERNAL、28 DIR_VALUE、29 WRITER_PROTOCOL、30 FEED_ID、31 RECOVERY_PROTOCOL。cause_mask为unsigned32对应reason位，NONE不置位；原FE/feed/MC码独立保留。

先记最早观察沿；同沿依以下明确顺序取first_reason：26/31/24/23→22/21/20/19/25/2→15/16/14/17/13/18/28/29/27→30/5/6/7/8/9/10/11/12→1→4/3。cause_mask保留全部原因。后续排空失败可在status提出前升级terminal_reason/result；提出后payload不改。人工及普通平台abort映射CANCELLED并保留abort_cause；源/策略映射5/4，真正复位/恢复协议故障才24/31。迟到/错目标abort返回ACK，不取消下一job；ACK停顿不冻结排空。

私有流在rst沿屏蔽；不受stream rst清除的MC保持域仍持续登记其所有真实req/W/R/completion/fence握手及pending捕获。其余沿先登记旧真实流/claim/pop、保存FE/feed/完成，再合并错误，失败优先于正常推进/OK；claim同cancel仍成对WE，安装末字同abort不发布valid。OK只证明本批必需证据，不等于源有效或显示发布。FAILED_DRAINED所有相关承诺/借用/feed已结清；REJECTED无业务子级启动且父绑定可安全返还；counts_final1仅声明已观测接口账本计数已收敛，不声明缺失FS/feed数量已知：所有仍可改变这些计数的接口关闭，MC/本地pending结清，包含形成同沿真实旧握手。FE/feed按实际已启动/已绑定required范围取得终结证据；未启动只用可信未启动/无残留归还证明，已接受FJ的FE须匹配真实FS或实际fe_reset_applied关闭证据，后者保持fe_status_seen=0/FS快照无效；绑定feed须匹配其终态或父真实未打开/无残留证明。不存在的FS/feed不制造数量或成功，feed_no_session不是success/P。正常OK仍要求完整真实FE OK及feed成功/P和关闭。QUARANTINED为独立冻结的非最终数量快照drained0/counts_final0；保持域live账本可继续排空，但不得改已提出status，消费仍锁ctx/租约。

功能rst与首次安全初始化分开，不假设FF上电值。功能rst只屏蔽job/私有流/发布等非承诺交接、清C1…C5私有valid并进入RECOVERY_LOCK；不能屏蔽已提出MC req/W valid。完整ctx/status、MC账本/tag、承诺bank/linebuf/W来源与pending在保持域保存，已提出valid/payload保持，已grant RAM读继续capture，已承诺W的组拍/请求响应与账本继续运行；保持域RAM读输出也不接会丢pending结果的stream reset。仅共同合法terminal或真实安全恢复证明可终結承诺；真实PHY不等stream rst自动排空。

FE v1真实rst会清局部job/status；C0记录fe_reset_applied，fe_status_seen仍仅真实FS握手，不能造FE OK/CANCELLED，此位不代替feed/DDR排空。若status已提出，rst屏蔽输出后仍保留原payload，解除rst继续交付，父平台屏障阻止旧OK发布。

safe_recovery_grant valid/ready候选：has_old_scope1、完整旧job/source/result/workspace key、physical_drained/feed_closed/logical_terminal/safe_ready/calibrated证明；旧scope逐字段匹配。无旧scope初始化只能依据平台已证明冷启动/无残留端点承诺的safe_init，不凭未知或清零的scope_valid自选。接受证明并完成本地清理后，独立recovery_done valid/ready向FM回同scope返还；既有quarantine status drained0不改写。旧status与恢复事件均结清且安全条件成立后才IDLE。实际保持域/平台证明/保护IP硬复位行为仍BLOCKING。

## 9. 验证与双向追踪，全部未运行

| TEST | 新步骤/输入与期望 |
|---|---|
| CN-T23 | P-J01/C01/C02：非法job已有reader预取且归还延迟、ARM/FJ/首数据分沿、EXPORT start/gather同沿替换、FE早OK/feed未drained、未启动required/reset后FS无效、GENERAL导出10、多错误/平台abort/status停顿/Q消费与旧scope恢复、快路径required mask1001/GENERAL1111；rst遇held req/W、RAM grant后待capture、MC completion/fence同沿；不造状态/排空，不提前成功或复用 |
| CN-T24 | P-W01…03/F01：N30 padding、跨行carry、GRAD保留位、CE2/GRAD4 bank满、两个W槽、rst遇held W/组拍pending、4KiB段间取消/早terminal、CLASS→EDGE复用；恰P/N/A，借用和提出段结清才返还 |
| CN-T25 | P-A01：物理最小A与页allocation区分、32/33bit溢出、错句柄/别区域重叠、小图/生产表、grad消费者最后读；数学区间合法不当真实slave证明 |
| CN-T26 | P-D01：424边界/零分量/四象限、两lane不同dir、D2/D3/D4气泡/停顿/flush、单支已收/GRAD关闭、EOF；同Gx/Gy/Mgrad/dir/坐标，对齐与分支各一次 |

CN-01…05→C3/C4/C5→IF03/04→P-D01及窗口→INV01…03→T03…06/16/18/26；CN-06/07→state/queue/C8→IF05/06→P-C01/P-W/P-F→INV04…08→T07…10/19/20/23/24；CN-08/09→C0/writer/父reader→IF01/05/07/08→P-J/P-A/P-C/P-F→INV08…10→T12/13/21…25；CN-10→E预算/P-D/P-W→T14/24/26。实际符号/哈希/测试待指定批准后登记。

本批补CN-B06/07的完整候选输入及方向/顺序writer；真实MOD-05/2Gb PHY、fence/恢复/父grant端口、FE/feed租约、六源期限、识别租约和全机性能仍未闭合。本页不因端口表/有限状态齐全而READY，不恢复用户撤回的识别边界。原FE/FM、窗口v0.2和存储v0.3保持不变。
