# 同帧行扫描与真实关闭联接 v0.1

- Goal：连接owner/handoff、标准AXI预取、native三bank与六模式renderer，让同一bundle跨完整帧的实际软件输出闭合。
- Current state：以上五个组件分别已验证，renderer已含六HD帧及实际MAP功能动态；实际scan需求运输/行选择/deadline/旧帧关闭仍缺源码。
- Target state：保持生产1920×1080约60Hz时隙，三bank向前预取、不可回压扫描、首行真正prepared、取消和旧帧归还真实关闭。
- Gap：不能再由TB直接提供prepared/closed或伪造行票据、RGB数据、io_closed。核心代次必须从实际row return推进。
- Assumptions：父核心控制器持有旧DISPLAY和候选OFFER的真实RO引用；lookup通过明确端口提供原owner不可变bundle及权限；标准AXI byte slave证明软件动态，真实DDR QoS/PHY和TMDS仍单列。
- Open questions：本v0.1尚须明确逐拍仲裁/回执优先级、frame关闭握手和首行错过VS的完整状态图；这些属于本Agent下一步设计，不能默默补全进代码，也不需要用户另给批准。
- Dependencies：已登记prefetch v1.3、renderer v1.1、handoff v1.1、owner v1.2、native rows/atomic/RAM；实际源码核读，不修改冻结组件。
- Milestones：补齐本局部设计至READY→冻结共同版本输入→生成代码→真实AXI/三bank/renderer/handoff/owner整帧→MAP→登记。
- Detailed steps：整体B/C→精确D接口→E视频时隙/核心握手→F位宽/CDC/预算→G/H独立验证/追踪→读回→自主实施。
- State transitions：DRAFT_NOT_READY_FOR_IMPLEMENTATION。已有“统计后自行进行，无需批准”及本地审计授权；没有因等待逐版用户批准而停工，本稿不足的设计由Agent继续补齐。
- Artifacts and hashes：work/display_scan拟12份自写：pkg、fetch_link、scan_prefetch_core、scan_video、scan_component五RTL，两TB、独立参考、两脚本及XML/SDC。输入/报告/README另列，最终清单在READY版冻结。
- Validation：真实481bit demand/615bit收据、完整票据/地址/gen、真实AR/R/WR/read/release/return、六模式完整帧、VS切换/取消/冻结/晚到/Q，实际资源。
- Failure handling：行开始未准备便黑该整行并记录underrun，晚行discard，不把迟到数据移到当前坐标；中途发现错误则保留已经输出的前缀、黑剩余时隙并记录部分行失败，不可能撤回既有像素。未知IO/响应保Q和引用，绝不造closed1。
- Human approval gates：延续自主软件授权/本地例外；没有新安装、网络或硬件动作；最终bit之后止步。
- Rollback：新独立包，原HDK/已登记组件及原输入只读。
- Completion criteria：本同帧扫描软件/MAP，不缩小五基础六高阶；DDR硬件动态/摄像头CRC与晚错/生产并行控制/复杂识别/总top资源/PNR/STA/bit继续推进。

## B/C 整体行为与已核事实

SC01：实际handoff只有在VS上升且DE0、candidate row0 genuinely prepared并有retire capacity时改变active；prepared核sequence/target_scan/result/policy/Origin。candidate_target_scan=scan_token+1会在每VS变化，即使候选未切换。禁止给旧row0改ticket以伪称准备了新scan。

SC02：视频对新行先借真实row_ticket543；全frame reference={sequence64,result64,policy64,Origin195}共387bit，加scan64及target_y/source_y/mode/mask为479bit行需求。core负责实际GEN64，video不能把release提出或owned0当核心槽已空。最终job ticket543=GEN64+需求479。

SC03：core用481bit {bank2,demand479}接需求，真实lookup/permission/reader header/row fill后运行AXI。正常行保持occupied至真实core return消费；内部abort消费真实return后GEN推进；header拒绝不消耗代次。gen最大值成功归还后exhausted，不回绕。

SC04：视频在行开始前需要owned且前两个native响应已预留，才能整行按DE持续pop/request；首行prepared至少要看真实响应address0/error0。每个renderer输入与实际rd_response fire是同一时隙、同一full ticket、同一source_y。两寄存级后输出，不能把RAM读完当输出已消费。

SC05：候选在旧最后几行已预取完成后服务row0；同一三bank中可保候选row0和旧active下次扫描row0，以在候选迟到/取消时继续旧图。候选选中则旧repeat行discard；错过VS则旧candidate row0按旧ticket真实discard/归还，再以新target_scan重新预取，不能热改身份。

SC06：candidate取消先停止该scope新需求，已提出未接受的valid不撤；在途请求精确取消并等待实际回执。已发布行先吸收旧native响应、真正DISCARDED release、真正core return。视频无owned/读credit/renderer旧输出/运输债，核心无该scope请求/IO/row占用/回执债才闭合；未知不出closed1。

SC07：active换帧后旧frame_ref保持至全部旧义务消失，才给父可用于RETIRE的全身份闭合通知。全局freeze新policy不能改旧active bundle.policy；旧result的重复扫描依原不可变policy。父处理真正APPLY/FREEZE/RETIRE，不能用视频影子替代核心实际引用。

已核源码事实：atomic_mailbox支持1..1207bit，源holding稳定至真正dst消费和ACK；row_bank的同步native RE有pending及两个响应slot，rd_ready按count+pending-pop<2预留；正常release须served=P且pending/count空，DISCARDED可提前但同样必须pending/count空。rows3有INIT_GENERATION参数，prefetch wrapper未暴露它；新scan_prefetch_core直接复用row_reader+rows3公开接口并传一致INIT_GENERATION，不修改原wrapper。

## D 候选精确接口及组合

M0 pkg：frame_ref387={sequence64,result64,policy64,Origin195}；demand479高→低为sequence64/scan64/result64/policy64/Origin195/target_y11/source_y11/mode3/mask3，保持既有ticket低479位顺序，frame_ref要逐字段抽取而不能直接cast一个连续区间。fetch_request481={bank2,demand479}；receipt615={bank2,ticket543,status3,row_granted1,outcome2,reason8,drained1,row_returned1,prepared11,delivered11,read_beats32}，高→低。所有身份64bit不截短；mode/mask沿既有六mode及mode0 source_y规则。

M1 fetch_link：video demand valid/ready/481、cancel level、receipt valid/ready/615；core service request valid/ready/481与结果615。请求原子holding至service实际终态和结果成功进入返回mailbox；返回消费ACK回到core后才idle。core_idle两FF回video再允许下一个需求，cancel两FF回core仅作用当前稳定请求，旧cancel不会串到下一包。core/video同safe冷复位，两FF各域释放；不新增异步宽数据直接采样。

M2 scan_prefetch_core：核心service请求、父lookup valid/ready/demand479、bundle942/permitted、标准128bit AXI；真实三bank视频接口及core return。等待lookup握手不随输入改ctx；拒绝无AR、无row_granted。派发GEN取本核心真实计数，银行忙status3可重试、不释放旧行；invalid/permission/exhausted和未知分别明确。新module复用既有reader及rows3，关闭协调按prefetch原已验证路径，增加GEN维护与明确未started收据。父permission必须随真实frame RO引用有效，不从字段相等自行授权。

M3 scan_video：handoff的candidate/active/prepare_selected/scan_token/cancel及完整bundles，真实三bankrow/read/release，需求/收据；输出prepared/closed全字段和renderer同步输入。输出旧scope闭合通知独立holding给父，不能靠一次pulse遗漏归还。采用行需求时将完整387bit身份绑定，已有银行ticket可稳定借用而不复制三个543bit包；禁止额外第四行或帧像素缓存。

M4 component：M1/M2/M3+原renderer，生产视频时序端口/核心lookup/真实DDR口/父闭合端口；handoff/owner在完整联合TB真实实例，生产顶层稍后接业务控制器。各模块源只从独立副本编译。

候选组合走查：owner完整结果OFFER且父保RO→真实handoff candidate→481请求→core lookup/GEN/FILL→实际AXI/WR/publish→原子row→前两个native响应→prepared full tuple→真实VS active_changed→DE从native响应进入renderer→最后响应/旧S0/S1输出/真实release/return→旧scope closed→父RETIRE。

安全失败：RESP失败、ID/LAST正确结束→internal abort return→615 drained1/row_returned1，GEN真实推进，video不会等待不存在的row。unknown：615 outcome3/drained0、row_granted视真实事实，槽不再用，闭合保持0。取消前未started必须独立明确无row占用，不能输出“已经归还了一条行”。

## E/F 下一步必须完成的局部草图

核心代次表仅3×64及exhausted；以实际return fire或internal abort-return fire推进。core_busy/exhausted/quarantined直接取rows3公开事实，避免靠video时钟猜银行状态。异常tuple/GEN归还不能结账。M2要逐沿规定CHECK→LOOKUP→reader ACK→row fill/ACK→RUN→publish或abort/return→结果holding，结果接受与请求ACK不可互等自身输出。

视频需补齐每bank EMPTY/WAIT/PREFILLED/READING/DRAIN/RELEASE及scope class，行deadline、成功/晚行/错数据整行处理，candidate与active repeat的具体仲裁。native响应队列已经提供两个holding，不再加完整行。renderer最后输入E_n，S1在E_(n+1)形成，下游在E_(n+2)采样；scope借用至少跨这两个沿，旧流水空后才closed。

frame_ref按全387比较；demand和615握手保持，bank<3/y<H/合法mode/mask/sy后才访问数组。GEN使用64，不以VIDEO release提前推进；bit/地址/plane仍由原reader32/33bit核范围。core100MHz/video约74.25MHz；原prefetch是19RAM，scan计划不增pixel RAM，仍须MAP实测。FF/LUT/CDC额外控制暂待局部状态确定。

尚未READY的具体项目：确认三个银行布局在旧最后一行/candidate/旧repeat占用时的确定选择；收据先到或row先到两种次序；VS错过及取消的来源运输闭合、closed holding消费边界；每时隙native request/pop/read error与整行black的精确优先级；无active启动黑色诊断与underrun计数区别。下一版先写明这些，不边猜边生成RTL。

## G/H 验证与追踪

ST1：完整真实AXI→三bank→native→renderer，固定bundle/scan六模式整帧，与独立源数学图每像素和所有控制比较；打印实际需求/收据/AR/R/WR/read/release/return/闭合。

ST2：真实owner/handoff/C0–APPLY，迟到row0错过一次VS后不能切，下一新票据才切；旧repeat继续、全部旧义务真正关闭才RETIRE。取消在请求未接受/AR held/R held/已发布row/native holding/S1末像素/结果holding分别核全tuple和closed。

ST3：freeze快照实际video active，旧active policy不被新global policy替换；COMMIT/RESUME按原协议与原source绑定。父lookup未授权/错误body/忙/代次等拒绝无AR；源slot/resultslot复用前要求全部ref归还。

ST4：延迟预算/连续HD时隙、预取银行占满、return_ready stall、收据stall、core/video clock stop、wrong ID/LAST Q、迟响应不倒改Q，安全共同reset单列作废；near-max GEN/scan/seq不回绕。真实DDR refresh/QoS仍待匹配模型和最终仲裁，不拿理想byte slave作为硬件带宽证明。

ST5：共同源冻结/fatal非零/独立参考/当前Ti60F225 MAP及总资源；不把叶组件相加当全系统已装得下，也不称本包通过板级PNR/STA/bit。

SC01/05→M3与handoff→ST2；SC02/03→M0/1/2 GEN/full tuple→ST1/3/4；SC04→M3/native/renderer→ST1/4；SC06/07→M1/2/3与父RO/RETIRE→ST2/3/4。所有接口和逐沿仲裁需在READY版完成反向定位，当前未代码、未测试、未综合。
