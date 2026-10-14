# SCAN核心行服务与原子运输 v1

- Goal：实现完整scan所需的核心481bit需求→真实GEN/lookup/AXI/row→615bit收据与代次/引用账本。
- Current state：SCAN整体v0.1仍在补视频仲裁；core路径可精确独立闭合，原prefetch无远程需求/代次分配。
- Target state：两域原子单请求、实际native三bank/AXI、真实代次推进、明确NoStarted和Q，供完整scan使用。
- Gap：新增pkg、fetch_link、scan_prefetch_core；不由TB伪造row fill/done/closed。
- Assumptions：核心父按原owner OFFER/DISPLAY/RETIRING真实RO引用提供lookup942/permission，并保每行引用至真实归还；整体scan稍后提供无未来请求证明。
- Open questions：视频scan状态/全scope关闭运输、真实DDR/PHY/QoS仍整体待完成，不阻塞此明确父端口服务。
- Dependencies：v0.2、SCANv0.1、原prefetch源码与动态证据、rows3 INIT_GENERATION、原子mailbox；原样冻结。
- Milestones：整体/接口/中文操作读回→3RTL/TB/参考/2脚本/XML/SDC九文件→仿真/真实MAP→登记。
- Detailed steps：外部行为→两域连接→字段/借用→核心逐沿关闭/代次→验证/追踪→代码。
- State transitions：READY_FOR_REVIEW。本次依用户自主软件授权读回/呈现后实施，无逐版批准等待；本地审计例外保留，正式状态不改。
- Artifacts and hashes：work/display_fetch；九份自写：display_fetch_pkg.sv/display_fetch_link.sv/display_scan_prefetch_core.sv、tb_fetch_core.sv、fetch_reference.py、run_fetch_sim.ps1/run_fetch_map.ps1、display_fetch_component.xml/.sdc。依赖/README/设计/日志单列。
- Validation：真实需求/收据与AR/R/nativeWR/read/release/return，全GEN/FrameRef/holding/取消/拒绝/Q，小/最小/HD宽行、近max；当前Ti60F225/I3 MAP。
- Failure handling：未知d0、保银行/当前scope、不接新需求；NoStarted d1只说明该需求没有发IO，不授权别的scope或全DDR复用。
- Human approval gates：自主软件/本地审计，原资料只读，无新安装/网络/硬件；最终bit之后止步。
- Rollback：独立新包，无冻结组件修改。
- Completion criteria：核心行服务软件/MAP；完整SCAN/owner-handoff/renderer、TMDS/DDR器件/摄像头关闭/识别/最终top时序bit继续全范围推进。

## A/B 外部行为

FC01：request481高→低{bank2,demand479}，demand={sequence64,scan64,result64,policy64,Origin195,target_y11,source_y11,mode3,mask3}。core实际GEN64前置形成ticket543。frame_ref387={sequence64,result64,policy64,Origin195}逐字段提取，不cast连续区间。原有票据字段和位序不变。

FC02：receipt615高→低{bank2,ticket543,status3,row_granted1,outcome2,reason8,drained1,row_returned1,prepared11,delivered11,read_beats32}。status0实际授FILL，1FIELD/2PERMISSION/3BUSY/4ROW_REJECT/5CANCEL_BEFORE_START/6EXHAUSTED/7DISABLED_BEFORE_START。正常status0最终outcome0/1/2/3仍沿原prefetch；其余均row_granted0、prepared/delivered/read_beats0、row_returned0/drained1，outcome通常1，取消前未启动为2。reason FIELD1/PERMISSION5/CANCEL128/CLOCK4，其余status已给原因可0。NoStarted的ticket.GEN为接受时真正核心计数，非法bank为0；不假称已占用或归还一行。

FC03：每bank nextGEN初INIT_GENERATION，真正normal core return消费或internal abort return消费才+1，最大值归还后exhausted、不回绕。银行忙以实际rows3.core_busy为准；busy拒绝不影响旧行，不因owned0就授新代次。已授FILL时锁bank frame_ref；正常发布后保持到真实归还。旧lookup/数据改变不能改reader已锁ctx或615 holding。

FC04：LOOKUP接受父bundle/permission的同沿实际reader job fire；reader锁942/543，不重复存942。父lookup_valid是请求，lookup_ready及bundle/permission是同沿回送；核心仅在reader可接受时给lookup_valid。权限假时仍读header但无AR/行授予，status2。lookup等待可匹配cancel直接NoStarted，未消耗父lookup或GEN。

FC05：reader字段OK后实际rows fill/ACK、消费reader CFG_REPLY才读取。实际WR→所有producer/IO关闭→publish或abort/actual local return→收据。旧AR/R/out holding继续真实消费；wrongID/LAST/活动enableloss沿reader Q/d0，不自动清；late drain不把Q改安全。

FC06：两mailbox481/615，视频单inflight。请求dst ACK仅与实际615成功进入返回mailbox同沿，返回真消费/ACK回core后才core_idle，两FF回video后再接下包。cancel level只在本inflight锁定、两FF回core并保持至返回消费；回执完整echo demand及bank，错echo或GEN0却row_granted为协议Q，视频Q两FF回core禁止新请求。源holding/结果holding绝不为取消或超时撤valid。

FC07：core scope_query_ref387输出local_scope_live：该scope正在服务/held reply/Q，或已授FILL/已发布bank的引用尚未真实归还。link另输出transport_live及完整transport_ref，直到响应ACK或Q结束前不清。两项只是局部事实，父还需视频owned/native credit/renderer尾部/无未来请求证明；此叶不生成可直接RETIRE的整帧closed1。

样例：bank0/g1请求A→真实lookup/FILL/AXI/960WR/publish→615成功，video读/实际release，core return_ready0时g仍1/local_scope_live1，新请求BUSY；真实core return消费后g2并live0，再请求B用g2。预启动cancel→status5/row_granted0/d1，不加GEN；实际授FILL后cancel→status0/outcome2，真正abort return后g+1/row_returned1。错LAST则保FILL/Q、d0、GEN不动。

## C/D 模块及精确交接

M0 display_fetch_pkg：公开四struct/状态编码及frame_ref函数，不能截195bit Origin。M1 link：视频/核心运输与echo/隔离，不生成业务done；M2 core：真实GEN/lookup/rows协调、core return和scope引用。原reader/span/meta/rows/atomic/native模型原样依赖。

```text
video request481 holding → atomic481 → M1 claim一次/保持原请求
 → M2 CHECK/LOOKUP → 原reader锁942/543 → 实际rows3 fill/ACK
 → 原AXI/meta/RGB → 实际WR → publish 或 abort/true return
 → M2不可变615 → atomic615 → video actual消费/ACK
 → core_idle同步后下一请求
独立normal return → 父真实消费 → GEN/row_ref更新
```

IF1 video_clk/core_clk/safe_reset_n；video_request_valid/ready/data481、video_cancel1、video_receipt_valid/ready/data615、video_busy/quarantined；cancel在request fire同沿也锁定。回执依真实配对保持，source ready不代表结果已被人/视频观察。

IF2 core service_valid/claim_ready/request481，service_cancel1，receipt_valid/ready/data615。M2借原atomic source holding：claim后至receipt真实消费，request481虽valid可0，但payload必须保持；这是明确借用接口。link请求dst不提前ACK保证它；独立TB遵守该借用。M2只为NoStarted锁64bit GEN stamp，reader已接受后用其saved_ticket，无重复完整481/942。Q时reader ctx及scope保持至共同safe冷复位，caller不能借通知消费改成复用。

IF3 lookup_valid output/lookup_ready input、lookup_demand479 output、lookup_bundle942/lookup_permitted input；仅LOOKUP有效，holding需求不变。实际ready/fire同沿必须reader_job_ready且permission/body由父锁定引用来源；非grant不能从合法地址自行变成grant。

IF4 AXI AR/R沿原span128bit/ID2/16B/≤64拍/4KiB/地址33bit范围；rows三个完整视频row/read/release和core return通道沿原包。return_ready来自父，M2观察同一真实fire，不能额外伪造消费。return票据已经由rows核完整当前票据，M2再核GEN与该bank frame_ref，异常Q不能推进自己的GEN。

IF5 scope_query_valid/ref387→local_scope_live；return和abort-return发生沿前仍live，沿后推进；service receipt holding仍live，含正常row可能已经归还的情况。transport_ref取当前稳定request frame_ref，不从热video input重建；transport_live受未返回ACK或永久Q约束。

## E/F 中文逐沿操作与RTL合同

核心：IDLE实际claim→锁GEN stamp、清row_granted/cancel/终态控制→CHECK按bank/真实busy/exhausted/enable/cancel给NoStarted或LOOKUP。LOOKUP先检查cancel/enable；否则仅reader ready时提出lookup；真实fire同时提出reader job，锁{GEN,demand}/bundle。HEADER等待reader字段；坏header消费CFG回复后给拒绝holding，未授row；好字段保持CFG，到实际ROW_FILL/ROW_ACK。fill ACK全文ticket必须与reader保存一致；OK沿row_granted1、scope_ref[bank]锁完整frame_ref，再消费reader CFG开始RUN；fill拒绝用匹配cancel关闭reader后status4，不加GEN。

RUN直接把reader out fire接native WR；真实done0才提publish，actual publish fire后捕获不可变终态控制并消费reader done，计数/票据仍稳定借reader until新job。安全done1/2则ABORT_REQUEST→实际abort→ABORT_RETURN；内部return真实消费时核全文ticket/kind1并更新GEN/ref，随后消费reader done/给收据。done3或d0只给Q通知、不提abort，收据真消费后永久Q。

NoStarted与header拒绝收据锁status/outcome/reason及GEN stamp，数学计数0；普通收据用reader保存票据及停止后不再更新的计数。同沿core normal return和新claim：旧busy优先给BUSY，收据锁旧GEN，沿后旧return推进；下一真实请求才见新GEN。普通return和内部abort-return不同bank可同沿推进，不能同bank重复推进。scope_query按沿前事实，不把cancel意图当close。

link：video request fire锁video_current481/inflight/cancel；两FF后的core request仅claim一次。core receipt真fire同时req ACK并进入WAIT_RESPONSE_ACK；响应source_ready重新true证明实际消费ACK，才允许idle。video receipt fire先核bank/低479 echo/合法授予GEN，锁Q或清inflight/cancel；core_idle经过同步且req source ready才新请求。若video clock停，回复holding及transport_live保持；共同reset才作废，并单列不算正常关闭。

SV_09、always_ff非阻塞、组合全默认；GEN/seq/scan/result/policy64、Origin195、request481/receipt615、票据543，无窄化身份。metadata/RGB/AXI宽位照原核定；GEN只先比较max再+1。core reset异步assert/两FFrelease，各domain相同safe_reset_n；不得清RAM伪装关闭。循环固定3bank；预计既有19RAM不增pixel RAM，控制/代次/scope FF/LUT需真实MAP，整体Ti60装载和QoS不据组件相加推定。

## G/H 验证/追踪与实现边界

FT1：所有mode、小/最小/HD宽行真实AXI byte slave/native full54读，GEN正确、完整479/543/615 echo；主测试多个bank保持、回执先/row先、RT holding、lookup stall/热改拒绝，独立Python按数学源/包字典审计。
FT2：Core return_ready0后仍busy/live，真实pop才GEN推进；父不同scope查询、在服务/holding/发布/内部abort各阶段真实计数，near-max共同INIT_GEN实际native银行不回绕。
FT3：预claim/LOOKUP/AR held/R held/最后out/结果holding取消，NoStarted与granted后终态严格分开；bad字段/permission/busy/exhausted无新AR；RESP安全失败有真R/LAST+abort return。
FT4：wrongID/early/missingLAST/enableloss永久Q；迟尾/恢复enable/已通知消费不再开新请求；video clock暂停不能假transport ACK，reset受控模型停止旧IO后单列作废。
FT5：源快照/哈希/fatal非零/Questa、Ti60F225/I3真实MAP；测试父lookup来自明确fixture RO承诺，完整owner权利/scan/DDR动态另在整体联合验证，不冒充已完成。

FC01/02→M0/full echo→FT1/3；FC03/07→M2 GEN/ref/true return→FT1/2/4；FC04/05→M2/原reader/rows→FT1/3/4；FC06→M1/atomic→FT1/3/4。源码、TB、参考和日志反向标同编号。整体接口/组合/中文语句/语言合同/预算/测试/追踪/输入来源/边界十项已有内容、叶无未定语义；全文保存读回并呈现后按自主授权编码。当前未生成本叶代码/运行结果，不把核心叶当完整scan或总目标完成。
