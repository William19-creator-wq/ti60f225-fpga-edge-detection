# R2 C0：任务、取消、错误与终态操作草图 v0.1

2026-10-04。设计补充稿 / NOT_APPROVED / NOT_RUN；附属于[R2主计划](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)，本附件本身不是完整R2的READY声明。只规定单core域流段；完整八邻域闭包、识别、RGB重放、实际工程另有设计。本版改变新R2提议，不修改[原FE v1](../../../planning/design-TRACK4-FRONTEND-001.md)、R1设计或其接口。

## 1. 先看整体与所有者

父提供CJ142和原FP74 RGB，C0唯一锁定job、提出并保持原FE FJ110、允许RGB、消费原FE FS163。FE输出去掉Y_ONLY的恒零edge后成为Msrc137，再依次经过Gaussian、新Sobel、方向、held fork；一支进入NMS/分类，另一支按retain_grad交付梯度。C0观察各接口的真实交接，记录错误并最终交付CS592。父不能另发FE job、消费其FS或给FE私有frame_start。

同一job最多一份CJ快照。内部借用这份三ID/尺寸/阈值时，快照一直保留到CS实际消费；FE局部结束、最后一个输入、某支EOF或暂时empty都不能释放它。所有私有数据及未消费错误清空后，才允许下一份CJ。当前class00/01/10是分类结果，不是最终edge，也不表示完整Canny完成。

本附件对应R2-REQ01/06/07、R2-IF01/02/04/06/07，补R2-B01/B02。独立审阅前这两项仍未关闭；RGB/控制/显示B03、observer/工程B04、完整基线/文件合同B05继续保留。

| 唯一owner | 数据/职责 | 释放或更新事件 |
|---|---|---|
| C0 | CJ快照、FJ held、FE启动事实、原FS快照、各接口计数/EOF/第一原因/终态 | CJ实际接受初始化；真实事件更新；CS消费后释放 |
| FE | 原FJ/FP/FO/FS生命周期及其窗口历史 | 按原FE v1，C0只使用原端口 |
| G/S/D/FK/N | 各自窗口、算术valid、pending、held及局部empty | 本域共同start建立新归属；data_flush清数据有效性 |
| D错误槽 | 一份不可变DIR_VALUE通知 | 真实错误交接或全局rst；data_flush不能抹去 |
| 父/未来源适配 | RGB来源归属、旧job数据剔除、CS/结果使用 | FP无逐像素ID，不能让旧源残留进入下一FJ |

## 2. 无实现体接口及布局

所有接口属于同一clk上升沿；同步高有效rst时全部ready/valid输出为0，因此复位沿没有fire。一般fire=沿前valid且ready且非rst；输出形成、输出实际交付及终态形成是不同事件。valid/ready不计入下述payload位宽。字段低位在前，所有坐标/计数unsigned；签名只给契约，不是RTL实现。

### 2.1 CJ142、原FE和数据接口

| CJ字段 | 位段/位宽 | 单位/范围/保证 |
|---|---|---|
| epoch / frame / config | 31:0 / 63:32 / 95:64，各32 | 相等判身份，不作大小排序；未排空前不重用 |
| W / H | 106:96 / 117:107，各11 | 必须等于静态实例；偶W6…1920，H5…1080 |
| TL / TH | 128:118 / 139:129，各11 | 0≤TL≤TH≤2047，未缩放L1 |
| median / retain_grad | 140 / 141，各1 | 全job不变；median只由FE执行 |

C0提出原FJ110：三ID96、median1、output_kind2=Y_ONLY、threshold11=0；无新增FE尺寸端口，实例尺寸静态相同。原FP74=RGB48+x_even11+y11+SOF/EOL/EOF/in_bad4，不含身份。FP来源valid/payload在等待时保持，只有实际FP接受、明确job作废/终结或全局rst可以结束旧候选；来源隔离不能只靠坐标相同。

原FO139=M16+edge2+sideband121；Msrc137只剥去edge2，无图像数值损失。sideband121=三ID96+x_even11+y11+SOF/EOL/EOF3。G8为137，Sobel为187，Direction为191，NMS输入为153，class为125，grad为185，沿R2主计划的lane/layout定义；不得用这些新位宽改原FP74。

原FS163原子保存：code3+三ID96+in_pairs21+out_pairs21+error_x11+error_y11。逻辑低位布局为code2:0、epoch34:3、frame66:35、config98:67、in119:99、out140:120、error_x151:141、error_y162:152。它是新CS中嵌入原端口字段的布局，不宣称原FE有打包163bit端口。

### 2.2 DERR120：独立保持的方向错误通知

D1实际接受某组后检查两lane的abs范围/M一致性；坏组仍计入Sobel交接，不进入D2，并产生一份DERR。原因固定DIR_VALUE，不另放code。DERR120=三ID96+loc_valid1+lane1+raw_x11+raw_y11；低位为x10:0、y21:11、lane22、loc_valid23、epoch55:24、frame87:56、config119:88。

两lane同时坏选择lane0；否则选择第一个坏lane。x_even+lane用unsigned12临时计算；若可用11bit表示，则loc_valid1，保存该实际像素x和原y。loc_valid表示有可表示的观测位置，不保证在画面内；错误位置不得夹紧到合法画面。若12bit结果超2047，loc_valid0且lane/x/y全0。单纯metadata错误由C0在Sobel实际交接处记录，不能用DIR_VALUE代替STREAM_COORD。

DERR产生后valid/payload保持；旧错误槽有效时不接新的D1输入，即使本沿err_ready为1也不同时替换，避免覆盖。C0在拥有CJ的ARM/WAIT_FE/RUN/DRAIN/ABORT_DRAIN独立err_ready=1，不依赖任何数据ready、EOF或D.empty。DERR实际消费时先保存原因/位置及检查身份，再清槽。DERR错误身份另外加STREAM_ID；第一原因由第6节事件先后规则决定。

data_flush清D数据四级，不清未消费DERR；新start也不能用来丢弃它。只有DERR fire或全局rst清该错误槽。D.empty同时要求四级data valid空且DERR槽空；C0必须先消费错误再等待全empty，不能反过来。

### 2.3 CS592：父可实际读回的流段终态

| CS字段 | 位段/位宽 | 语义 |
|---|---|---|
| 完整CJ快照 | 141:0，142 | 原接纳配置/尺寸/身份，非法CJ也原样保留 |
| first_reason | 146:142，5 | 0为本流段OK；其他为第6节代码 |
| observed_reason_mask | 178:147，32 | 第1…18原因按位OR；bit0及19…31恒0 |
| fe_started / fe_status_seen / stream_started / cancel_seen | 179 / 180 / 181 / 182，4 | 真实FJ接受 / 真实FS保存 / 共同start发生 / 有效外部取消观测 |
| loc_valid / stage / lane / raw_x / raw_y | 183 / 187:184 / 188 / 199:189 / 210:200，28 | 第一原因观测位置；无位置则loc_valid0、stage15、lane/x/y0 |
| RGB / Msrc / G8 / Sobel计数 | 231:211 / 252:232 / 273:253 / 294:274，各21 | 每接口真实pair fire累计，失败时不要求相等 |
| Direction / NMS_in / class / grad计数 | 315:295 / 336:316 / 357:337 / 378:358，各21 | grad关闭应0；不是像素数量 |
| observed_eof_mask | 386:379，8 | 位0…7依次以上八接口；只在实际fire且payload.eof1时置位 |
| strong_pixels / weak_pixels | 407:387 / 428:408，各21 | class实际交付的10/01像素贡献0…2，不计未交付held |
| 原FE FS快照 | 591:429，163 | 完整不可改写；fe_status_seen0时全0只表示未观察，不能解释为FE OK |

总位宽142+5+32+4+28+168+8+42+163=592。strong+weak先零扩unsigned22求和，正常应≤N。CS字段第一次形成后全部保持，直到父实际接受；CS等待时不重采配置、不接受新CJ、不因后续cancel改变结果。消费沿只回IDLE，下一沿才可接受CJ。592bit不能沿用R1的160bit观察记录；新observer另由B04冻结。

## 3. C0状态、旧事实与控制边界

生产D=960、P=D×H=1036800pair、N=W×H=2073600pixel。P/N在合法静态展开得到，不用运行期除法推坐标。每接口有自己的21bit计数和q/r期望游标：q10、r11，q=D−1后到下一行；bad metadata也是真实交接，但进入错误后不再要求补齐后续游标。计数增加用22bit临时先检查再窄化；流段在首次多余组后转abort，失败前缀至多P+1，未发生21bit回绕。

C0保存ctx_live、stream_started、fe_started、fj_pending、fe_status_seen、fe_cancel_sent、cancel_seen、eight observed/legal EOF mask、first_reason/mask/location、各计数和strong/weak。fe_started只由真实FJ fire置1；fe_cancel_sent记录先前C0向已启动且尚未呈现FS的FE断言cancel的控制沿（该沿旧FS valid=0），是辨别原FS CANCELLED的依据。消费当前已held FS的边沿新cancel不能说明该FS的形成原因；归因只读旧fe_cancel_sent。ctx_live在CJ fire建立，到CS fire释放。RAM内容不清零，由start/flush有效性隔离。

| 旧状态 | ready/valid与允许事件 | 本沿提交和下一状态 |
|---|---|---|
| IDLE | 只有CJ ready，需旧私有流和DERR均空；FP/FJ/CS关闭 | CJ fire锁142并清诊断。非法尺寸/阈值记原因→ABORT_DRAIN；合法→ARM。旧IDLE的cancel忽略，即使同沿CJ fire |
| ARM | FP/FJ关闭；已锁CJ | cancel则记1→ABORT_DRAIN且不start；否则本沿共同start一次，stream_started1，建立held FJ→WAIT_FE |
| WAIT_FE | 已提出FJ valid/payload保持到fire；FP关闭，错误通知/FS按拥有事实接收 | FJ fire置fe_started1、清fj_pending→RUN；若cancel/错误优先→ABORT_DRAIN，但同沿实际FJ接受仍保存；未接受held不能撤 |
| RUN | 只有旧stream_started与fe_started同时真才开放FP；数据链自行推进；FS独立接收 | FP第P组实际接受后→DRAIN，不再开放输入；错误/取消→ABORT_DRAIN，真实沿前各接口交接照记 |
| DRAIN | FP关闭；尾重放、class/启用grad继续；FS/DERR独立接收 | 全部正常条件满足且无本沿新错/cancel→锁CS OK→STATUS；错误或终止数量缺口→ABORT_DRAIN |
| ABORT_DRAIN | FP关闭，禁止新start；held FJ仍保持直到实际接受；私有data_flush为1；FS/DERR可独立接收 | 已启动FE从可见旧fe_started的沿开始持续cancel至FS接收；失败排空条件满足后锁CS→STATUS；不等P/N或EOF |
| STATUS | 只CS valid，payload保持；其余CJ/FJ/FP关闭；cancel忽略 | CS fire释放ctx并回IDLE；该沿不得接下一CJ |

原FE FS ready仅依赖非rst、旧fe_started1、该job的FS缓存空及C0拥有ctx；不依赖私有empty、class/grad ready、P计数或EOF。原FS接收后缓存满，直到本CS消费才释放，不为了等一个“正确FS”重复接收。FS身份、保留code、计数不符也保存真实快照并判错，不篡改成C0原因。

ARM共同start只发给G/S/D/FK/N，FE的start仅来自原FJ。已提出FJ由fj_pending管理，即使从WAIT_FE进入ABORT也保持；全局rst是允许撤销的唯一例外。FJ最早在ARM start边沿后的WAIT_FE可接受；FP最早在实际FJ接受后的RUN边沿接受，不允许同沿首像素。

C0的外部cancel在ARM/WAIT_FE/RUN/DRAIN/ABORT有效；旧IDLE/STATUS忽略。FP许可为旧RUN且旧stream_started/fe_started、非rst且非有效外部cancel；发给FE的FP valid与返回父的FP ready都由同一许可门控，外部fire与FE fire严格同一事件。ABORT接纳held FJ后，即使旧外部FP valid仍高，也不得有未被C0记录的FE输入。RUN的FP ready可由独立外部cancel直接屏蔽，与原FE一致。fe_cancel在旧fe_started且本job未收FS时，对有效外部cancel或ABORT_DRAIN为1；FJ接受同沿旧fe_started0，不能假称该沿FE ACTIVE已经被取消，必须在随后ACTIVE沿发cancel。

## 4. 真实交接、EOF与排空

| 序号/bit | 计数事件 | 值域/位置检查owner | EOF及局部empty界限 |
|---|---|---|---|
| 0 RGB | 原FP→FE的真实fire，也是外部FP fire；两者完全相同 | FE检查in_bad/预期坐标/标志；C0只计数/记录观测EOF及核原FS | 坏FP也计数；最后接受P组可进入DRAIN但不能据此OK |
| 1 Msrc | 原FE FO→G真实fire，剥edge无另一次事件 | C0核三ID、中心坐标、标志/数量 | FE自身empty由其原FS表明；不以FO暂无valid代替 |
| 2 G8 | G→S窗口真实fire | C0核metadata；数值由独立参考验证 | G.empty含phase IDLE、pending NONE、V1/V2/H1…3及水平历史有效性空 |
| 3 Sobel | S→D1真实fire | C0核metadata；D1核数值 | S.empty含窗口历史/读回/pending空及六级valid空 |
| 4 Direction | D4→FK真实fire | C0核metadata；dir/layout沿主计划 | D.empty还包含未消费错误槽 |
| 5 NMS_in | FK→NMS真实fire | C0核metadata/16bit容器高3位0 | FK.empty=held无效且两pending0，不用任一支ready推断 |
| 6 class | N→父真实fire | C0核metadata、class非11；计strong/weak | N.empty含窗口phase/pending/历史/输出及N1/N2空 |
| 7 grad | FK→父真实fire，仅retain_grad1 | C0核metadata、grad32高8位0/梯度值域 | 关闭时valid/pending/计数/EOF均0，父grad_ready无作用 |

C0在内部真实交接处观察metadata；每接口以独立旧q/r判断当前x_even、y及SOF/EOL/EOF；不能用另一路游标。内部三ID必须等CJ。只有实际fire推进计数/游标、置observed EOF；valid高等待不重复统计，valid0数据不解释为零。

observed EOF只说明看见eof1；另外保存legal EOF事实，需该fire为第P组、坐标为(W−2,H−1)、三ID及标志合法。错误早EOF也置observed bit但判STREAM_MARKER；最后组缺EOF即时判STREAM_MARKER，不等待以后补EOF。原FP合法性由原FS OK保证，C0按其第P组/末坐标/标志记录legal EOF，原FS非OK仍保持观测事实。错误坐标或身份组仍计真实前缀。

class11组仍增加class pair计数；该lane不计strong/weak，其他合法lane仍按真实交付记录。strong/weak是已交付前缀的诊断，不表示失败job可发布。两计数之和用22bit检查；合法完整分类其和≤N，不自动把余数全部当弱边。

空与正常完成不同：窗口start之后phase=REAL，即使尚无首数据也不是empty。Gaussian末两行BOTTOM replay、水平尾组和TAIL必须完成；TAIL是控制事件，不是第九种输入，不增加任何pair计数。DERR未接收时D.empty为0。

取消或已寄存错误使C0进入ABORT_DRAIN；从随后可见该旧状态的周期起data_flush=1，私有数据ready/valid均屏蔽为0，并在该边沿清pending、窗口/算术valid、水平有效性与phase，RAM使能0、内容不清。DERR valid/ready独立保持。导致转abort的前一个边沿全部真实旧fire先计入，不由新错误组合反馈ready而消失；尚未交付的数据撤销，是明确作废例外。flush持续至失败终态形成，防止尾重放自行复活。

本附件明确覆盖旧窗口附件中“输入错误当沿禁RAM”的父控制描述：C0对内部metadata错误使用下一旧ABORT周期data_flush，原FE对自身FP错误仍依原契约当沿flush。G/S/N窗口RAM地址只来自各自受限q游标（0≤q<D）、固定bank和有限phase，不使用未经核验的payload x/y作地址；正常/边界重放也核q<D。坏metadata接受沿最多访问当前合法q，随后flush停使能，因此这次延迟清理不允许越界RAM请求。payload坐标用于C0核验和诊断，不能用于未经范围检查的读写。

第一方向坏值来自D1真实接受，在该沿后形成DERR；该沿已交付的其他旧数据照计。C0到随后DERR真实接受才观察DIR_VALUE，因此某个较早到达的FE/流metadata错误可以先成为first_reason；不假造全系统“最早物理原因”。

## 5. 成功、失败和等待必须分开

正常CS reason0同时要求以下旧事实，且该沿没有新错误/有效cancel：

1. CJ尺寸/阈值合法，stream_started、fe_started、fe_status_seen均1，held FJ已释放。
2. 原FS code0、三ID匹配；原in/out计数分别等实际RGB/Msrc计数且都等P。
3. 七个必需接口计数各P，legal EOF mask低7位全1；observed mask也必须包含这些位。
4. retain_grad1时grad也计数P且legal/observed bit7均1；retain_grad0时该支valid/pending/count/EOF均0，不检查父ready。
5. G/S/D/FK/N全部empty，DERR已消费，无待保存的FS/错误。strong/weak合法、扩宽和≤N。
6. first_reason0且mask0。至少最后必需接口EOF交付后的后续边沿才可依据已锁计数/empty形成CS。

FE已真实OK、全部私有流确实empty却计数/必需EOF缺失，判STREAM_COUNT进入abort，而非挂起等待已不会出现的尾部；本检查仅在旧DRAIN且已启动/已有FS等事实齐备时发生，不把初始empty当缺口。消费当前FS/最后数据的同沿不使用新值直接成功。

失败CS形成条件：first_reason非0；没有尚未接纳的held FJ义务；FE从未启动或者该FE真实FS已保存；私有data empty且DERR槽已实际清空；无本沿尚待合并的新原因/FS/DERR交接。cancel首次有效观察置cancel_seen并加mask bit1；cancel_seen已1的持续电平不产生新的待合并原因，仍持续门控/取消FE，因此可在cancel一直为1时形成失败CS，不被重复取消困在ABORT。失败不要求完整P/N、任一路EOF或各支计数相等。若held FJ仍待ready，保持等待；若父从不接CS则保持STATUS。不能伪造FE终态或把错误转空成功。

半帧后源永久停止、父永久不给data ready，且无cancel时可以合法等待；不引入未声明的自动超时。取消后私有流不依赖父class/grad ready排空，但仍须真实原FS和错误交接。保证有限结束的环境前提是：已提出的FE job最终接纳、FE按原契约响应取消、core持续时钟；CS释放另需父最终ready。

## 6. 原因码、定位与同沿优先级

| code / mask bit | 名称 | 触发/定位 |
|---|---|---|
| 0 | OK | 无错误，mask bit0恒0；无位置 |
| 1 | CANCELLED_EXTERNAL | 旧有效状态观察cancel；无位置 |
| 2 | BAD_SIZE | CJ尺寸不等静态实例或超范围；无像素位置，CS stage15 |
| 3 | BAD_THRESHOLD | CJ TL>TH；无像素位置，CS stage15 |
| 4 | FE_CANCELLED_UNEXPECTED | FS code1且旧fe_cancel_sent=0；当前FS消费沿新cancel不参与归因；无位置 |
| 5 | FE_INPUT_BAD | 原FS code2；stage1、lane0，原error_x/y |
| 6 | FE_COORD_ERROR | 原FS code3；stage1、lane0，原error_x/y，不夹紧 |
| 7 | FE_MARKER_ERROR | 原FS code4；stage1、lane0，原error_x/y |
| 8 | FE_BAD_CONFIG | 原FS code5；无位置；合法R2发固定合法FJ不应出现 |
| 9 | FE_COUNT_ERROR | 原FS code6；无位置 |
| 10 | FE_STATUS_PROTOCOL | 原FS错误身份/code7/原in-out不等C0已观测前缀；无像素位置 |
| 11 | DIR_VALUE | 真实DERR接受；采用其代表像素位置/valid |
| 12 | STREAM_ID | 内部实际交接ID不等CJ或DERR ID错；可保存该事务原位置 |
| 13 | STREAM_COORD | 内部实际交接不等该口预期偶列/行；原lane0坐标 |
| 14 | STREAM_MARKER | 内部实际交接SOF/EOL/EOF不等该口预期；原lane0坐标 |
| 15 | STREAM_COUNT | 内部多于P；或真实OK+全empty却必需数量/EOF缺口；多余组可定位，缺口无位置 |
| 16 | CLASS_VALUE | class实际交接某lane为11；选坏lane原实际像素位置 |
| 17 | CLASS_STATS | 计数/宽和超过N或内部派生统计不变量失败；无位置 |
| 18 | GRAD_LAYOUT | 实际grad容器高8位非0或梯度超范围；选坏lane实际位置 |
| 19…31 | RESERVED | 不生成，mask恒0 |

原FS code1仅在旧fe_cancel_sent=1时解释为C0先前取消引发：保留原code1但不添加4；旧flag0时即使当前FS消费沿外部cancel1，仍添加4，first可按同沿优先级为1。C0的first_reason不会改写为FE CANCELLED。code2…6始终按表另外加入mask。若同一原FS有protocol错误又非OK，两项都加入mask，以10为同沿首选。

stage4bit编码：0 JOB、1 RGB、2 Msrc、3 G8、4 Sobel、5 DIRECTION（D1通知/D4监测）、6 NMS_in、7 class、8 grad、9 FEstatus、10 DRAIN、15无位置；11…14保留。无位置统一stage15，stage0/9/10只是审阅事件类型，不与loc_valid0一起另塞一个可解读像素stage。定位是实际坏事务/像素的原坐标，不代表预期坐标；元数据位置不是合法画面保证。lane错误选lane0优先，x加lane先扩12；不能表示则无位置。first_reason/location第一次锁定后不再改；mask继续累积直到CS首次形成。

首次是“C0第一次观察错误的边沿”；不同来源的源头发生时刻不作跨模块推断。同一首次观察沿只选一个first_reason，其余原因仍进mask。顺序为：全局rst（丢弃整job，无CS）> 外部cancel > FE_STATUS_PROTOCOL > 原FS非OK > DIR_VALUE > STREAM_ID > STREAM_COORD > STREAM_MARKER > CLASS_VALUE > GRAD_LAYOUT > STREAM_COUNT > CLASS_STATS > 正常OK。CJ同沿尺寸/阈值均坏则2优先、mask同时含2/3；旧IDLE的cancel无效。相同原因来自多口时按RGB→Msrc→G8→Sobel→DERR→Direction→NMS_in→class→grad；DERR在Sobel之后、D4输出之前，二者均stage5；相同口两lane选0。STATUS之后任何新cancel/数据不是当前job的新原因。

## 7. 中文操作草图（同沿旧事实，沿后提交）

C0-OP01 接纳：先依据旧IDLE、全empty决定CJ ready；真实CJ fire时原子锁142，清计数/游标/mask/FS_seen/启动事实。核尺寸与TL/TH，坏则锁原因并转abort，不启动任何RAM/FE；好则转ARM。同沿FP关闭，cancel按旧IDLE忽略。

C0-OP02 提出与接纳：旧ARM无cancel的边沿共同start并准备FJ held。下一WAIT_FE周期展示held，ready低保持全部FJ字段。真实FJ fire只置fe_started并解除held；下一RUN周期才允许FP。若该WAIT_FE边沿cancel且FJ fire，同样保存实际FE启动并转abort，随后对已ACTIVE的FE发cancel。

C0-OP03 输入与流水：RUN的FP ready只反映原FE接纳且非独立cancel/rst；外FP fire恰等FE FP fire。FE负责bad/坐标/标志；C0依各真实内部fire独立计数/游标/EOF和class统计，错误候选先保存，不从新错误组合回馈ready。末第P组FP接纳后关闭新输入，进入DRAIN，让本地尾事件继续。

C0-OP04 早FS：只要旧fe_started且缓存空便给FS ready。真实FS fire原样保存163，再核身份/code及前缀计数；不等class/grad EOF，不改其原code。当沿有数据真实fire时，核原FS计数用“旧计数+本沿真实fire”的22bit临时观测值，避免同沿合法最后交接被误判；正常CS仍不得同沿用新FS完成。缺少匹配FS不是可以丢掉该FS并重等的理由。

C0-OP05 接错误：DERR ready独立拥有ctx即开放。真实error fire把原因/位置/mask加入观察集合，错误槽清空；各计数仍按该沿旧有效信号记录。data_flush不能提前清此通知。若本沿FS/cancel同时到达，按第6节选择第一次原因，而不是谁在程序文字中先赋值。

C0-OP06 作废与排空：本沿观察到有效cancel/错误后转abort；下一旧ABORT周期屏蔽私有data ready/valid并assert data_flush，撤未交付后缀，禁RAM使能。旧held FJ继续展示，接受后下一ACTIVE沿cancel FE。持续独立收真实FS和DERR；保留所有实际计数和第一原因。等第5节失败条件，另一个结算沿锁CS，绝不补P/EOF。

C0-OP07 正常结束：旧DRAIN先核已锁完整计数、legal EOF、FS、全empty和统计；该沿若还有任何新错/cancel则转abort。若末接口刚交付或FS刚保存，至少下一沿才核旧事实。完整成立锁reason0/CS；若真正OK+全empty但缺口成立则reason15作废。

C0-OP08 终态与复位：旧STATUS只保持CS；父ready低不重算CRC/配置/终态；CS fire只回IDLE，下一沿可CJ。全局rst优先并屏蔽全部fire，C0/FE/私有流和DERR共同复位、无旧CS；RAM残留隔离。复位与取消不同，复位无需为旧job输出终态。

## 8. 必须读回的具体并发走查

| CASE | 起点及逐沿事件 | 确定结果 |
|---|---|---|
| C0-C01 | 非法4×3 CJ，同时TL>TH | 两原因入mask，first2；未start/FE未启动，计数/EOF/FS快照0，排空后失败CS |
| C0-C02 | 合法CJ；旧ARM cancel | 不提出FJ、不start，first1；无需伪造FS，失败CS |
| C0-C03 | WAIT_FE held FJ、FE ready0；cancel | FJ仍valid/payload不变，转abort；等真实接纳；下一ACTIVE cancel；收FS1，再失败CS |
| C0-C04 | WAIT_FE FJ fire与cancel同沿 | fe_started1、FP无fire；随后cancel；原FS1保留，first1，无unexpected4 |
| C0-C05 | RUN某FP in_bad fire；FE提前形成FS2 | FP计入坏组；未合法转FE计算。收原FS2，first5；私有flush，不要求各接口达到P/EOF |
| C0-C06 | RUN末FP缺EOF | 原FE返回FS4；observed bit0不置；first7；不补EOF，不等待P之后新输入 |
| C0-C07 | FE已OK且class尾held/grad尾held | 早存FS0；ctx保留，继续正常尾流；相应EOF实际fire且所有empty之后才CS0 |
| C0-C08 | DRAIN cancel与原FS0、class真实fire同沿 | FS0原样保存，class计数/统计增加；first1；下一abort撤未交付后缀，不改FE原码 |
| C0-C09 | retain_grad0，父grad_ready恒0 | grad valid/count/EOF/pending恒0，不等该支；正常必需mask7F |
| C0-C10 | D1坏值同时旧D4/FK/Nclass有真实fire | 坏Sobel组照计、不进D2；旧交付照计；DERR次沿hold/实际接收；后flush不能抹该错误 |
| C0-C11 | 正常路径FS0+全部empty，但某必需计数/EOF缺口 | reason15，无位置；失败结束，不停在永久DRAIN |
| C0-C12 | FS错误ID/保留code7或不符前缀计数 | 保存唯一原FS，reason10；不再等一份替代正确FS |
| C0-C13 | 已有first11后收到FS1（因C0 cancel） | first11保持，原FS1保留，不新加4；失败仍要真实FS/全empty |
| C0-C14 | STATUS CS ready0，同时cancel | 所有592bit/valid保持；cancel忽略；消费沿不可接受下一CJ |
| C0-C15 | CS刚消费，父下一CJ已valid且旧FP候选未剔除 | 下一CJ可按空闲事件接受；来源必须先隔离旧FP，否则源违反合同，不以重复坐标证明来源正确 |
| C0-C16 | 任意held FJ/数据/DERR/CS时全局rst | 全部fire0、清所属有效性、无旧终态；新start不会引用旧RAM历史 |
| C0-C17 | 同沿多口坏ID/坐标/标志，class lane1=11 | 所有原因入mask；第一原因按优先级，定位先上游；class组与合法lane统计照计 |
| C0-C18 | 原FS0与其最后FO→Msrc fire同沿的接口故障注入 | 原FSout比较旧Msrc+本沿fire，合法不误报；正常完成仍等下一结算沿 |
| C0-C19 | 旧fe_cancel_sent0、已有held FS1，本沿首次外cancel且FS fire | first1、mask同时1/4；FS1原样保存，不能用当前cancel消掉unexpected4 |
| C0-C20 | cancel进入abort后一直为1，直到CS被接受 | cancel_seen1后不重复制造新原因；照收FS/DERR并排空，形成CS且保持，STATUS忽略持续cancel |
| C0-C21 | 内部metadata x/y越画面且真实接受后才进入abort | 真实计数/原位置保存；RAM只读写本地合法q，不按坏坐标寻址；下一旧ABORT周期使能0 |

这些是设计走查/未来场景，不是已运行测试。永不ready的等待必须与死锁区分：自有FS/DERR ready不得依赖尾部；外部永久拒绝数据时，等待或明确cancel是合同允许行为。

## 9. RTL A–L、软件参考与对应合同

| 项 | 本附件实际契约 |
|---|---|
| A 数值 | CJ142/CS592/FS163/DERR120；计数21、增加/统计和22；坐标lane增加12临时；先检查再窄化；不回绕 |
| B 时钟 | 单core上升沿沿前fire、沿后状态；TB稳定驱动后采样；10ns只是功能仿真候选 |
| C 接受/交付 | CJ/start/FJ/FP分沿；八data fire独立；FS/DERR独立接收；CS fire不可同沿新CJ |
| D valid/推进 | bubble不计，窗口内部TAIL不计；start不等首输入；EOF观测与合法/数量分别记录 |
| E 反压 | held FJ/CS/错误及各data sideband保持；只有声明的cancel/abort/reset撤未交付data；FJ不随abort撤 |
| F 延迟/吞吐 | 本控制不许组合CJ→FJ→首FP透传；无停顿成功至少最后必需EOF后的沿；失败结算另沿；永久ready拒绝无固定周期承诺 |
| G 复位 | 同步高有效rst全域屏蔽fire且清data/err/status；data_flush仅ABORT清私有数据，错误槽保留 |
| H 配置 | CJ真实接纳原子快照；TL/TH/median/retain不受运行外部变更；ctx到CS消费有效 |
| I 存储 | 一FJ held、一FS163、一DERR120、一CS592及计数/游标，RAM内容无清零；单job无动态分配 |
| J 身份 | 无逐FP IDs，来源隔离有责任方；内部三ID和中心游标逐口匹配；失败各口前缀可不同 |
| K CDC | 本附件无跨域；真实source/buttons/display CDC由后续设计，不能直接连不可暂停相机 |
| L 实现 | SV2009/Ti60F225目标；监测寄存器及CS宽度纳B04预算，未综合/STA，不用本稿证明资源通过 |

Python独立参考只做完整图数学与分类，不模拟C0环形RAM；协议预期另由事件记录计算真实每接口前缀、FS原快照/首次观察原因、优先级和592bit打包，必须独立核字段布局。它返回结果/诊断，不偷偷把失败前缀补为完整图。C++本批未选择，故C++所有权/映射合同N/A，不生成C++实现。

硬件时间合同：真实fire才推进，旧数据可在转abort的边沿交付，data_flush下一旧ABORT周期撤余项；错误交接独立于empty；成功只核已锁事实。对应合同：用CJ三ID和各接口真实pair序号/原坐标关联参考；完整CS0才逐图比较，失败比较各自前缀、CS字段和作废后缀政策；rst取消整job比较且不期待旧CS。

## 10. 实施、验证与双向追踪（未生成/未运行）

获完整设计批准后才在独立r2路径实现canny_stream_controller.sv、canny_stream_top.sv，及gradient_direction_pair.sv的DERR槽。先生成接口/状态/计数，再组合FE与私有流；业务脚本、模型、TB路径由B05最终冻结，本附件不生成它们。

| TEST | 覆盖/输入 | 期望/观察/失败标准 | 状态 |
|---|---|---|---|
| C0-T01 | C01/02，合法最小6×5和生产1920×1080 | CJ快照/无FE事实/拒绝状态正确；沿前及沿后核事件，不以空输出OK | NOT_RUN |
| C0-T02 | C03/04，FJ held backpressure和cancel每个交接位置 | 不撤held、无FP同沿透传、真实FS取消；原FJ110保持到fire | NOT_RUN |
| C0-T03 | C05/06/12/13/19/20，FP坏/坐标/标志/FS故障注入及持续cancel | 原FS不可改写、真实坏输入计数、失败不等待P/EOF、reason/mask/loc准确 | NOT_RUN |
| C0-T04 | C07/08/09，class/grad尾独立ready及取消+FS+class | 各前缀/EOF独立，早FS不死锁，关闭grad不等待，ctx直到CS消费 | NOT_RUN |
| C0-T05 | C10/11/17/18/21，DERR/多个新原因/缺口/同沿FS/坏metadata寻址 | DERR hold且flush不清，旧fire保留，首次观察/同沿优先级与临时计数匹配 | NOT_RUN |
| C0-T06 | C14/15/16，CS反压/换job/全局rst | 592bit保持、CS消费后空隙、无旧源泄漏、rst接口无fire且无旧终态 | NOT_RUN |
| C0-T07 | 全部payload打包，包括FS未观察、非法位置、32bit mask | 独立逐位schema核592/120/142宽度；高保留位0；观测EOF不能冒充合法EOF | NOT_RUN |
| C0-T08 | 整图R2-T06及每级bubble/随机停顿 | 各必需P/合法EOF、prefix记录、EOF后全empty；完整1080p不能被6×5代替 | NOT_RUN |

| REQ/派生责任 | MOD/IF/步骤 | 计划符号与文件 | TEST/反向必要性 |
|---|---|---|---|
| R2-REQ01/07 job与唯一FE owner | C0/CJ/FJ/FP，OP01…04 | job_snapshot/fj_pending/fe_started/fe_status_snapshot；controller/top | T01…04，禁止额外FE owner |
| R2-REQ06保留真实前缀 | C0/各口，OP03/06 | pair_counts/observed_eof/legal_eof/cursors | T03…05/T08，不用公共计数假造各支相等 |
| R2-REQ03/06方向错误 | D/C0/DERR，OP05 | error_pending/error_payload/err_fire | T05/T07，不被data_flush或empty等待抹掉 |
| R2-REQ05统计 | N/C0/class，OP03 | strong_pixels/weak_pixels/first_reason | T04/05/08，非法class仍计pair |
| R2-REQ07终态/取消 | C0/CS/FS，OP06…08 | first_reason/reason_mask/fe_cancel_sent/status_payload | T02…07，原FS和上层失败有不同owner |
| 派生复位/来源隔离 | C0/父/全部私有流，OP08 | ctx_live/stream_started/empty/FP gate | T06/T08，RAM残留不当新图 |

## 11. 版本、审阅及阅读次序

来源为实际R2 v0.1（SHA256 6B9C02C04662AAA10EC69CD12391AAFCD2E3D41F1E80809A604069534F167FAA）、原FE v1、旧窗口v0.2/方向v0.4；来源SHA随新候选基线和审阅记录保存。未继承旧物理任务/writer/器件控制。初稿保存后需实际读回、字段算术检查及独立协议/数值审阅；任何意见修订以新hash再审，不将调查结论当最终稿通过。

阅读顺序：本1整体→2接口→3状态→4局部真实事件→5完成条件→6错误规则→7中文步骤→8具体走查→9执行/对应→10验证/追踪。R2主计划再据实际审阅结果回写B01/B02；B03…05保留。完整包仍NOT_READY/NOT_APPROVED；业务实现、功能仿真、综合、PNR、STA、bit全部未执行。
