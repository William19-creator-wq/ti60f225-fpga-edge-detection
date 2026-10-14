# 视频域原子交接、VSYNC换帧与冻结保持 v1

- Goal：把已实现帧槽账本连接到真实独立视频时钟域的换帧与冻结控制，完成当前软件实验的生产交接RTL。
- Current state：frame_owner v1+J3的RTL/MAP/postMAP已登记；旧DISPLAY v0.1是未实施候选，现无实际CDC/路由模块。
- Target state：原子mailbox、视频路由、取消/闭合、真实1080p扫描边界及frame_owner组合测试，Ti60F225/I3 MAP。
- Gap：消息/VSYNC/snapshot hold无代码；真实DDR行预取与TMDS另接，不能将本单元当完整显示。
- Assumptions：core100MHz、video pair74.25MHz；prepared/closed是视频域已资格化的带身份视图，由后续row/prefetch叶模块提供真实证据。
- Open questions：物理DDR动态模型、行预取服务/QoS、最终CDC约束/引脚/STA仍待整机；不阻塞该条件接口模块，不虚构这些已通过。
- Dependencies：当前frame_owner pkg/RTL、video_timing_1080p_pair实际计数、v0.2及旧显示/帧管理资料；全部copy只在新work。
- Milestones：设计读回呈现→RTL/参考/TB→异步/取消/组合及生产扫描→MAP→登记。
- Detailed steps：B整体→C职责→D接口→E中文操作→F语言→G/H验证追踪。
- State transitions：READY_FOR_REVIEW读回后按用户“自行进行, 无需我的批准”实施，保留设计前置；正式DB/state不动。
- Artifacts and hashes：baseline.json冻结设计/依赖；run源绑定、非零fatal探针、失败保留，不覆盖旧RunId。
- Validation：两域真实握手、消息逐位/唯一性/保持、VS边界、冻结引用移交、配合owner、时钟停止及MAP。
- Failure handling：未证明关闭不造CANCELED闭合；时钟/业务超时隔离并保留消息、active及租约，只有共同安全冷复位清除。
- Human approval gates：已有自主软件授权/本地审计例外有效；无安装/网络/硬件步骤，最终bit后停。
- Rollback：新work/active/track4_algorithms_20261004/display_handoff；原HDK/安装/旧包和旧owner源不改。
- Completion criteria：当前单元真实软件/MAP闭合；整体11功能/物理显示/最终PNR/STA/bit继续完整目标。

## A. 范围、来源及文件

TRACK4-DISPLAY-HANDOFF-001 v1，关联A3/A5/H1。按当前实际owner的command941/reply942接口，旧1963/623候选不冒充已接通。owner完整source_handle64、result_handle64、Origin195、CJ142、body400、policy64、slot3/2均保留。输入owner源已冻结于FRAME-OWNER-CORE-COMPONENT-20261009-v1.2，copy不改变旧工作源。

计划自写11份：rtl/display_handoff_pkg.sv、atomic_mailbox.sv、display_route.sv、display_handoff.sv；tb/tb_atomic_mailbox.sv、tb/tb_display_handoff.sv；model/handoff_reference.py；scripts/run_handoff_sim.ps1/run_handoff_map.ps1；project/display_handoff_component.xml/.sdc。文档/原样依赖单列。

## B. 外部行为与可判断样例

DH01：core同域valid/ready接纳一个完整1137bit请求，一个business请求在途；异步mailbox保持整个包直到真正消费，无逐位同步数据。
DH02：合法OFFER在真实VS上升的消隐边界，且row0完整资格及旧退役容量成立时，原子换active整包。不得在frame_start/首DE沿更新。等待期间重复旧active；扫描不由此模块反压。
DH03：FREEZE_PREPARE在VS边界选择视频域真实沿前active，建立snapshot_hold并发送完整快照。core先调用owner FREEZE并保留源，再以匹配cause/源/Origin的FREEZE_COMMIT放hold；核心影子不参与选择。
DH04：NO_ACTIVE由视频返回，owner选择latest或等首源；COMMIT可以先绑定零源等待，再以同cause和新seq绑定第一个真实源。冻结未commit或零源时不接受新OFFER；冻结新offer须同冻结源与当前policy。
DH05：RESUME在VS边界生效，policy递增；core收到后再owner RESUME，释放FREEZE不释放display/BIND。快速冻结恢复按prepare→owner pin→commit→resume顺序结清，不能抹去held消息。
DH06：匹配当前sequence的core取消脉冲锁成level独立跨域，不等堵住的请求通道。未应用OFFER停止新预取，等待带seq/result/Origin/policy的实际candidate_closed才回CANCELED且closed=1。已发布APPLIED/SNAPSHOT回复不会因迟取消改变。
DH07：字段/身份/状态错误不改active。错误OFFER回复closed=0，不能据错误码推断物理预取已排空；调用者独立关闭并归还owner租约。正常APPLIED旧result通知只登记退役，真实RETIRE仍等IO/consumer closed。
DH08：heartbeat/业务默认50500000 core周期超时、扫描ID耗尽或VS在DE内触发时隔离；不清消息、active或引用。不把超时当闭合。安全冷复位仅平台确认所有旧访问停止/关闭后共同assert。

普通例：owner OFFER B→core接纳→video保存candidate→row0 seq/scan/result/Origin/policy准确且retire_capacity1→VS沿整体active=B→APPLIED带旧A handle→core owner APPLY→A由真实旧读关闭后RETIRE。
边界：video已B、core尚A，FREEZE_PREPARE返回B，先加FREEZE再放snapshot hold。取消与准备同时VS到达，取消优先，保持A；无closed则不回闭合成功。故障：video clock停、core仍在运行，隔离且旧pending不变；恢复时钟不自动解除Q。

## C. 职责与连接

```text
core请求 → M0 request atomic_mailbox(core→video) → M1 display_route
M1回复 → M0 response atomic_mailbox(video→core) → core回复/owner转换
core matching cancel → 保持level/两FF → M1独立取消
video timing VS上升/DE → M1；row0资格/closed(完整身份) → M1
M1 candidate/active/换帧旧result → 后续row/prefetch/render；owner仍唯一拥有槽账本
```

M0 generic WIDTH1..1207仅transport，拥有src payload、req/ack toggles、各域运行及pending，不判断帧业务；目的域data直接读稳定源holding，valid通过两FFreq及本地pending资格，不再复制一个宽目标寄存器。
M1 route拥有当前请求、真实active、冻结源/Origin、snapshot、policy/scan、回复holding；不算像素/不替叶模块造row0或闭合。
M2 display_handoff拥有core business忙、匹配取消、heartbeat/业务计时及Q；两个mailbox与route组合。请求busy直到core reply消费且video完成回复ACK、回idle的往返同步，再接下一请求；取消不会误作用下一代。

## D. 精确消息与相容交接

request1137从高到低kind3/sequence64/cause64/target_policy64/bundle942。kind0OFFER、1FREEZE_PREPARE、2FREEZE_COMMIT、3RESUME，4..7非法。sequence非0且按video last_sequence递增，不回绕；cause只commit有，匹配尚在冻结会话的prepare sequence。control prepare/resume target=current_policy+1，commit target=current，offer bundle.policy=target=current。

response1207：kind3/status3/sequence64/cause64/policy64/bundle942/previous_result64/has_active1/snapshot_held1/candidate_closed1。status0成功（kind分别APPLIED/SNAPSHOT/COMMITTED/RESUMED）、1FIELD、2IDENTITY、3STATE、4CANCELED、5EXHAUSTED。失败不授予访问权；closed仅当前offer的候选义务，永不表示旧active排空。APPLIED bundle为新完整OFFER；SNAPSHOT bundle为真实active（无则0）；commit/resume不热改active的旧配置/旧result policy。所有holding字段保持到实际交付。

OFFER bundle要求owner reply.op5/status0，source/result非0、slot合法、Origin的capture_seq/gen等于source_handle且slot匹配、CJ frame/epoch对应Origin、W/H与静态几何一致、low≤high、render mode0..5/split=H/2及三desc与owner固定布局完整相等。SRC始终存在；mode1/2 EDGE0，仅mode5 ANN非0。bundle非法绝不expose为可读candidate。

prepare/resume bundle/cause均0；commit bundle必须owner FREEZE reply.op9/status0/policy=current。若snapshot有active，commit的source/result/Origin/CJ/body/slots必须与原snapshot完整一致（op/policy按control转换）；若NO_ACTIVE则接受合法source-only或规范零源（Origin/CJ/body/result0、slot7/3）。已绑定非0冻结源不允许换成另一个源；等首源时可从0绑定一次。

输入prepared_valid是video-owned row0完整资格视图，不是接收队列；seq64/result64/Origin195/policy64/scan_token64均匹配candidate且scan=oldscan+1，并retire_capacity1，才在VS沿应用；stale/wrong字段仅不就绪。输出prepare_selected为真实应用脉冲，rowowner延长对应bank/row生命周期至读完。核心预取可从core合法请求接纳时开始，取消须停止新增并以完全匹配closed_valid证明全部读/返回/row/pipeline关闭；router不自行推断。candidate outputs属于video域，后续core预取必须另经原子计划/row运输，不能直接采多位输出。

实际已有video_timing_1080p_pair：h0..1099/v0..1124，DE在h<960/v<1080，HS[1004,1026)，VS v[1084,1089)。用vs&&!old_vs作为vsync_tick，下一有效帧还有41行blank；frame_start发生在首DE，不能作为当前换页沿。scan_token64只在合格VS tick递增（初0），ROW候选使用下一token，不用旧准备重标新scan。VS tick与DE同时则Q、无切换。

Core request/response handshake均core正沿；prepared/closed/VS/active均video正沿。两域common safe_reset_n异步assert、两沿release。源holding数据在req提出至ack往返稳定，destination只在同步req+pending资格后采样；物理整合需source数据最大延迟≤2个destination周期及保持/CDC报告，不能用全false_path作证明。当前SDC只MAP目标100MHz/74.25MHz。

## E. 局部中文操作草图

### E1 transport
src_ready要求自身release、目标running两FF可见、无pending；src fire锁WIDTH数据、req toggle翻转、pending1。dst两FF同步req，见新值且无pending→锁seen_req并valid1，数据从稳定src holding给出；dst fire清valid并ack=seen_req。src两FF见ack==req后才pending0，下一个fire才可改data。复位同时清资格/toggle，不清图像；单端warm reset禁止。

### E2 video route
IDLE在reply transport source ready时接受请求，锁包、消费唯一seq，检kind/字段/状态。有效OFFER保存candidate→WAIT_OFFER；若取消level见1则CANCEL_DRAIN，cancel_candidate=1且不再允许apply。WAIT_OFFER每VS基于旧scan计算next_scan，核prepared全部身份及retire容量，满足则快照旧result、active=整新bundle、形成APPLIED holding；取消优先。

WAIT_FREEZE每VS选沿前active、保存snapshot/prepare_seq/frozen_source/Origin、policy=目标，frozen1/committed0/hold=has_active，形成SNAPSHOT。目标域hold直到匹配commit；core消耗snapshot transport ACK本身不等owner pin，仍不放hold。COMMIT原子核匹配，owner已先pin，committed1、hold0、必要时绑定首源，形成COMMITTED。WAIT_RESUME只有已commit无hold，VS沿解除frozen/源、policy更新，形成RESUMED。

CANCEL_DRAIN只有closed full identity匹配后形成CANCELED/closed1，active不变；错误closed忽略。控制在VS前取消没有候选新读义务，回CANCELED但不撤旧active/freeze；commit取消保留原hold，会话须重试commit后resume。SEND_RESPONSE保持全部1207直到response mailbox接纳，WAIT_ACK保持业务/active/会话并不接新cmd；reply mailbox source重新ready表明core实际消费，才IDLE。迟取消不改held回复。scan计数独立推进，业务等待不暂停物理扫描。

### E3 core wrapper
request fire锁inflight/sequence并清cancel；匹配cancel pulse锁level至reply消费。request_ready还需同步video idle与request mailbox ready，防旧cancel跨代。response valid来自回复mailbox，core实际消费清inflight/cancel；video真正ACK后idle同步才允许下一请求。

video每256clock翻转heartbeat（8bit prescaler可回绕，仅诊断，不是身份），core两FF见变化清alive timer；core release后无变化到watchdog或inflight计时到watchdog则永久Q并保存错误seq/reason。video scan耗尽/错误边界Q同步至core同样隔离。恢复clock可运输旧reply但不清Q、不授新请求。冷安全reset才清。

不变量：mailbox一条接纳一条消费，无重复/撕裂；active只VS blank更改；全部同源bundle原子；hold放开前core已pin；candidate未closed不制造归还；旧published回复稳定；三结果容量由owner限制，router不发第四个结果租约。

## F. RTL/参考契约

sv_09、enum/packed pkg，always_ff非阻塞更新，组合全赋值。A1137/1207/942、64bit无回绕身份及显式32bitdesc/11bit几何；B两域正沿、TB负沿驱动、握手观察沿前；C源/目标真实fire；D气泡不推进消息；Eholding全包保持；F两FF+pending资格+业务VS/closed+ACK往返，吞吐为控制事务非像素；G共同safe冷复位及独立同步release；H接受时锁全部snapshot；I单req/resp/candidate/active有限容器、没数据则旧帧/safe由renderer；J全Origin/CJ/source/result/policy/scan；K稳定bundle mailbox、cancel/heartbeat/idle两FF，不逐位同步大包；L Ti60F225/I3 MAP，最终总资源/CDC/PNR/STA尚未证明。

独立Python按真实两域外部日志检查实际core请求/回复、video VS/active变更/scan身份和snapshot/cancel/closed因果；不照抄RTL next寄存器。与owner组合用旧独立租约参考检查command/reply及引用；本批无C++。参考相等无像素容差；真正图像像素/TMDS验证另批，不把控制测试当完整视频。

## G/H. 实施、测试与双向追踪

先冻结及读回→pkg/mailbox/router/top→参考/TB/scripts→局部+组合+生产真实扫描→MAP→登记。

| 测试 | REQ/接口/事件 | 期望 |
|---|---|---|
| HT1 | DH01 mailboxes WIDTH1/64/1137/1207，两频率/相位、气泡、长stall | 所有bit/数量/顺序稳定无重复，双端safe reset |
| HT2 | DH02 actual 1080p timing，sourceA→B，prepared错误字段/oldscan/retire满 | 只在VS blank切整包，记录真实扫描与60Hz周期 |
| HT3 | DH03/04 owner组合，videoB/coreA，NO_ACTIVE有/无latest及首源 | snapshot真实B，owner pin后commit释放hold |
| HT4 | DH05/06 快速freeze/resume，取消/ready同VS，latecancel held回复，wrongseq及wrongclosed | 无误切换/无假closed，所有控制握手结清 |
| HT5 | DH07非法field/identity/policy/commit cause、重复消息 | oldactive和holding保持，错误closed0不冒回收 |
| HT6 | DH08 clocks停止/恢复、prepared永不ready、scan/seq/policy near-max、DE内假tick | Q保留所有义务，无自动新请求/无回绕 |
| HT7 | DH01..08 当前源Ti60 MAP | 实际资源、原语/警告，未跑部分明确 |

DH01→atomic_mailbox/top→HT1；DH02/07→route验证/WAIT_OFFER→HT2/5；DH03/04/05→route snapshot/commit/resume+owner转换→HT3/4；DH06→top cancel/route drain→HT4；DH08→top timer/route scan guard→HT6；pkg/runner/project承担位序及源绑定→HT7。实际证据初始未运行，后填K。

## I/J/K/L. 门槛、变更与交付

十项由B/C/D/E/F/G/H及A范围/冻结清单提供实质内容；保存、全文读回及聊天入口后，在用户自主授权下实施。不假称用户逐版批准、不改原数据库/Manifest。该条件接口设计无当前阻塞；叶row/DDR/physicalCDC与最终完整链清楚待续。

修订先短卡读回，历史失败保持。初始无源码/未运行。阅读B整体→C/D交接→E两域操作→pkg/RTL→两TB及独立参考→runs/MAP/staging；理解验收待实际作答，不用考试阻塞授权工程。最终本单元交付不替代完整11项、复杂识别、总top/引脚/PNR/STA/bit。


## K. 2026-10-09实际交付核对

11份自写文件已生成，原样owner/timing依赖与J1原生模型/网表单列。最新6个RTL场景及4邮箱、1实际网表回归共11次PASS：92个完整请求/回复、22次视频域整包换帧、189个owner事件；780/776邮箱记录和4个明确冷复位作废。所有当前外部消息/资格/快照/hold/取消/错误/租约独立参考审计通过。真实1080p timing每VS间1237500 pair周期，无DE换帧。原始版本的早期run仍留存，不混入当前计数。

Ti60F225/I3 handoff_map_001成功7328FF/6958LUT/57ADD/0RAM/SRL/DSP，无工具warning/error诊断。current RTL/pkg/project与MAP snapshot一致；J1改变TB及runner验证分支，不改变硬件逻辑。实际map DUT回归28事务、54owner事件；名义50500000周期watchdog动态未跑，8192加速RTL场景已跑。PostMap FullScan可执行但本批未跑，不拿control测试代像素、物理CDC、PNR/STA/bit。

冻结baseline-v1.1为13份输入。详见当前work/display_handoff/docs/README.md及各run。当前单元为DELIVERED_SOFTWARE_COMPONENT，五基础六高阶总体未完成，真实row0/closed来自后续预取/row单元，TB条件证据不替代实体DDR/HDMI。仍遵守硬件闸门，正式DB/H0不改。本轮设计前置、代码注释/接口、参考/测试与DH01..08核对；理解验收待实际作答，不另索批准。
