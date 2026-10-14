# native行消费→连续DE→六模式画面 v1

- Goal：实现完整scan中的真实视频行消费：每bank原子借行、前两项真实native读预留、每拍双像素DE、缺行/取消清理、renderer末尾再真正归还；用同一bundle连续完整帧验证。
- Current state：display_fetch v1.2已登记（核心/运输/真正GEN），rows和renderer已验证；完整scan v0.1的native消费尚无代码。上一轮是PROGRESS，检查点v14/245文件/无运行中任务。
- Target state：新的可复用单bank display_row_streamer，最终scan三实例共享一个renderer；实际核心取数/三native银行/此消费者/renderer/timing的六模式同一bundle整帧软件链。
- Gap：父候选/repeat仲裁、owner/handoff全scope关闭仍需完成；本包明确实现其中SC04及SC06的消费义务，不代替原五基础/六高阶的完成目标。
- Assumptions：父通过真正615成功回执给543 reserve_ticket；其完整帧/scan/行身份在显示时隙给479 display_demand；每行首DE给display_start。native row_ticket在borrow至实际release/其后验证期间稳定。新请求/lookup RO来自本包明确数学byte-slave父fixture，真实owner/handoff生产仲裁随后接入。
- Open questions：父三银行deadline/候选取消/no-future通知、实际DDR/PHY/QoS、生产top/资源/PNR/STA/bit继续推进；单bank当前接口和顺序无未定语义。
- Dependencies：fetch RTL3+原样依赖11（含测试byte slave）、renderer1、生产1080p pair timing1共16份依赖；规范v0.2、SCANv0.1和本设计、fetch README为冻结设计输入。
- Milestones：整体/连接→精确接口/中文语句草图→保存读回呈现READY→冻结→7自写文件→小/最小/HD六模式连续帧及故障→Ti60F225/I3组件MAP→登记。
- Detailed steps：先实现消费者及实际父fixture TB/独立参考，再真实联合仿真；不伪造prepared、native数据/closed或GEN。
- State transitions：READY_FOR_REVIEW；沿用户“当你统计完后自行进行，无需我的批准”的持续独立软件授权实施，本地审计例外有效，正式DB/硬件状态不改。不是新逐版人工批准记录。
- Artifacts and hashes：独立 work/display_row_stream，计划7自写：rtl/display_row_streamer.sv、tb/tb_row_stream.sv、model/stream_reference.py、scripts/run_stream_sim.ps1/run_stream_map.ps1、project/display_row_stream_component.xml/.sdc；输入/README/日志/快照/登记另列。实现前所有依赖和设计实际SHA冻结。
- Validation：真实reserve/read/pop/release/return、实际AXI/native、全54bit与RGB/控制/错误逐位；单bundle六模式完整HD帧，非回压DE；实际故障/取消/停顿/尾部；组件MAP不冒充整包时序。
- Failure handling：已显示前缀不能撤回；首行没准备黑整行，中途坏数据黑剩余。已承诺未接受read不撤，真实credit清空后DISCARDED；未知身份/多余response/失去owned/坏release永久Q不造关闭。
- Human approval gates：无需逐版软件批准；原资料/已登记源只读，独立副本；无安装/网络/硬件，最终bit之后停止。
- Rollback：独立新增包，各次attempt及前置设计保留。
- Completion criteria：当前真实行消费与same-bundle软件连续帧/组件MAP；完整scan、实际owner权利/关闭、摄像头CRC、DDR动态、原复杂识别和最终生产工程未由此完成。

## B/C 整体行为和模块连接

RS01：reserve_valid/ready与native row_valid/ready同一video边沿一次接受。543 reserve_ticket必须与实际native row_ticket全文相等且GEN非0，成功后只借稳定native票据，不复制543；reserve_discard说明迟到/不用的真实行。匹配错误消费到owned后永久Q保占用，不假装丢掉不存在的行。

RS02：成功借行先发native地址0、1，issued达到2且响应0真实有效/无错，prepared才1。native有count/pending两个credit；prepared时可为count1+pending1，不需要第三个响应槽。hold期间不pop，直到真正首DE或discard。

RS03：display_start必须是父为本银行选择的首DE/x_even0。prepared/owned、543低479与display_demand、响应地址0都正确才在同一边沿pop0并给renderer S0。随后连续每DE一对，响应地址=display_x_even/2=shown_count、完整需求吻合；同沿pop和发下一RE保持native两项预留。输出pixel_valid和identity_good与真正响应及54bit对齐，没有下游ready；固定扫描不能等待RAM。

RS04：首DE未准备，整行黑；中途DE间断、响应缺失、错地址/票据、discard，保已经显示前缀、剩余黑，停止新增RE并DRAIN。reserve_discard直接DRAIN且无新RE。晚于deadline才到的publication由父用reserve_discard清理，父不能拿迟到行补当前坐标。非zero身份错为error3，缺数据/取消为error1；renderer自己的配置/坐标错仍原error2。

RS05：已提但未接受的native request保持valid/GEN/address到真实fire，cancel不撤。issued只在真实RE fire加1，popped在真实response fire加1，shown仅真正DE正确pop加1。DRAIN吸收全部已接受response及未接受promise，无未来RE；全部credit关闭和renderer尾部已空后才提出release，kind固定holding：全P正确显示为CONSUMED0，否则DISCARDED1。最后正确pixel接受E_n，S1更新E_n+1，下游消费E_n+2；tail两位覆盖这两个沿，归还保守在更后沿，不早清。

RS06：release valid/ready真实发生后VERIFY_RELEASE，下一video边沿确认owned已经0且无release_error，才IDLE/local_live0。坏release、借行中owned意外0、未发RE却多余response→永久Q，保持现有promise/引用，共同qualified safe reset才作废。local_live/ref仅本银行消费者事实；core真正return、transport ACK及父no-future/其它银行/renderer全局义务还须分别证明。

```text
真正video615成功收据/原request匹配 → reserve543
 → native row借用 → RE0/1真实响应 → prepared
 → 父首DE/479身份 → 正确native pop54 → 单renderer S0/S1 → 连续画面
 → 最后两输出沿/真实credit清空 → release/owned验证
 → 原核心真正return → 原GEN账本
```

自写M1只负责一个银行的这条生命周期；最终父三实例可同时primed候选/旧repeat/当前行，共享renderer。native/core/link/renderer/timing原样依赖。父并不因prepared就有整帧关闭权，也不把本包fixture当实际owner权限。

## D 精确接口及组合检查

IF1 video_clk/safe_reset_n，异步assert/两FFrelease；与native相同safe冷复位。图像W4..1920偶、H2..1080偶，P=W/2≤960。无C++映射/无新增像素存储，Python是独立数学和事件参考。

IF2 reserve_valid/ready、reserve_ticket543、reserve_discard1，真实video valid&&ready；调用方holding全部payload，ready只在IDLE、native row_valid、!owned且域running时给。row_ready来自同一实际reserve；row_ticket是原native公开稳定543。接受之后原票据有效期覆盖整个borrow/尾部/release验证，父reserve可释放。

IF3 prepared1，display_start1、display_de1、display_x_even11、display_demand479、discard1；均video域。父只对所选bank给display_de及首start，当前479准确包含帧、scan、坐标/mode/mask，事务绑定全字段；参数/语义沿fetch pkg和原mode0 source_y。没有ready；display_de连续P拍，否则丢弃余行。配置render112由父同帧bundle给共享renderer，不由消费者另复制。whole-scope选择/RO/更换active发生在DE0，由后续完整scan负责。

IF4 单bank native read_valid/ready、GEN64、addr10、response_valid/ready/data54/addr10/error1；release_valid/ready/GEN64/kind2/error1；源和响应valid停顿保持。reserve时无旧credit；read实际同步RE，输出pending后到两槽，真实响应反压保持。消费者不会向可用信用之外提交RE，issued< P，DRAIN清实际信用。native行返回GEN由真正core consumption推进，消费者不猜GEN。

IF5 pixel_pair54、pixel_valid1、identity_good1（仅所选DE有意义），quarantined1、local_live1/ref387、line_error2、shown11/issued11/popped11诊断。正确像素是同沿rd_response fire，其误差不容忍，末尾按真实renderer两阶段预算。line_error在reserve初清/结束保到下一reserve；release一旦提出不被晚discard改kind。local_ref借native票据逐字段提取，live时父不能采热reserve或新active重建旧身份。

正常走查：核心publish与615同源，父同时等待真正row_valid+615好包→同沿reserve/收据消费→RE0/1→真实prepared→首DE pop0/request2→每DE输出准确54bit→尾部/信用真实空→release/owned0→core真实return更新GEN→下一y+3请求。最小P2不会发地址2，两个像素对直接完成。

取消走查：PRIME已有2真实RE、ready被父/DE压住→discard，响应逐一真实pop，若另有stalled request先等actual fire，再等response，未发过的地址不增信用；tail为空才DISCARDED。RUN中取消保此前正确prefix和两输出沿。最后正确pair已经完成后到的discard不改full-CONSUMED终态。

## E/F 中文局部草图与SV语句组织

数据仅phase3、issued/popped/shown各11、pending_request1、tail2、complete1、release_kind2、line_error2及display_error2；543和54bit借依赖holding。line_error属于当前borrow，reserve初清；display_error属于正在扫描的整行，只在新的display_start或本行失败时更新，下一行的提前reserve不能倒改旧失败行剩余的黑色错误身份。IDLE/PRIME/RUN/DRAIN/RELEASE/VERIFY_RELEASE/Q用enum；always_comb全默认形成接口，always_ff非阻塞只在真实事件计数，不多驱动、不复位RAM。

IDLE同沿reserve/row：核全文+非0GEN，计数0/tail0、complete0；错包Q，reserve_discard则DRAIN，否则PRIME。PRIME发0/1，count通过fire推进；prepared hold真实首response；start时按所有旧条件判断，成功首pop+请求2进入RUN，失败DRAIN/error并黑此DE。discard优先于尚未接受的显示，但不撤既有read promise。

RUN逐DE核完整需求/坐标/响应；正确pop形成54bit、shown+1并需要时发新RE，最后一个正确pair锁complete1并DRAIN。没有DE或出现缺失/错身份/取消，锁error转DRAIN。DRAIN只pop和兑现既有request，绝不生成新request；issued==popped、pending0、tail0且owned正常时锁release_kind进RELEASE。RELEASE全文借ticket.GEN、kind holding直到fire；VERIFY下一边沿核owned0/error0再IDLE，否则Q。

request promise生成依据当前要prime或正确stream pop；若valid&& !ready，pending_request置1、地址直接取未增加的issued_count而稳定。pending只在真实fire清，cancel/Q不能清。tail每video边沿推进有效/气泡，真实pixel输入才标本银行旧源；renderer消费E_n+2之前至少保持借行，不以native pop完当画面已经交付。错response/address可以DRAIN该已知credit，未知额外response或owner丢失不可假结账。GEN/所有帧身份不窄化，10bit地址/11bit计数显式转换；循环/预算无额外RAM。

预计M1无RAM/DSP，控制几十FF和全文比较LUT需实MAP；单bank资源不能当最终三bank+core/renderer/fulltop资源。目标video13.468ns、core10ns沿已用SDC，组件无pin，仅MAP不代表STA/物理CDC。

## G/H 实施、验证与双向追踪

STV1：实际fetch/native3+三个M1+renderer，父只发真实需求和reserve/DE，六mode固定一份bundle/scan跨每个完整frame，全部54bit native pop和RGB/HS/VS/DE/x/y/error与独立数学比较；HD保持1920×1080生产时隙，小/最小用明确测试时隙不代替HD验收。
STV2：prime持首响应、最低P2/6/10像素边界、三bank轮转，真core return后才允许下次请求，实际GEN及完整615/ticket；连续DE不插人工读取停顿，输出无ready。
STV3：首行未准备、late reserve_discard、PRIME/RUN取消、read request stall期间取消不撤、response缺失/错地址/错身份、DE间断、release holding/错误；已显示prefix不倒改；scope和tail最早关闭沿及Q不重新借。
STV4：共同safe reset资格在受控slave停止旧IO后测试、视频时钟停/恢复、near-max来源沿原fetch证据；本包主要新增消费路径，不重复声称全部物理证明。Questa fatal非零/完成标志/源快照、独立参考、当前Ti60 MAP，失败attempt保留。

RS01→reserve/row/borrow→M1 IDLE→STV1/2/3；RS02→PRIME/native slots→prepared→STV1/2；RS03/04→DE完整479/54与错误/prefix→RUN/DRAIN/renderer→STV1/3；RS05→pending/三计数/tail/release→STV1/2/3；RS06→VERIFY/Q/local_ref→真实release/return/查询→STV2/3/4。所有新增7文件都承接这些当前职责，实际位置/结果在README和日志补入。

十项生成门槛：整体行为及边界、职责和真实复用、精确参数接口/组合、逐沿中文草图、不变量/语言契约、正常与取消走查、实施/验证/双向追踪、当前无未定语义、保存读回呈现、版本/来源/范围清楚均有实际内容。READY后沿持续软件授权生成，不等待新的用户逐版批准。未实现/未运行不能提前标通过，完整父控制/DDR/识别仍保留全目标。
