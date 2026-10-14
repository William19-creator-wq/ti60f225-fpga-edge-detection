# TRACK4-PLATFORM-001：时钟、复位、CDC与引脚设计 v0.1

按[PLAN_TEMPLATE.md](PLAN_TEMPLATE.md)形成；2026-10-04。关联MOD-01及H0/H1/H2/A3/R0需求。**LOCAL_DESIGN，未批准实现，尚不READY。**先读B/C整体，再D交接与组合，再E中文操作草图、F语言契约、G/H验证追踪。此稿不包含可直接执行的RTL、SDC或测试。

## 通用计划字段

- Goal：为1080p单整机建立可解释的时钟/复位、平台故障/恢复、跨域消息与活动pin合同，避免参考工程的clock、GPIO版本和复位语义混用。
- Current state：4颗PLL、原理图/封装/保护IP公开端口已只读核查；新平台逻辑、约束、IP生成及测试均未执行。
- Target state：完整设计经评审、指定批准后，在独立work内实现，再证明CDC、约束、仿真、综合/布局/STA；本稿完成不代表这些已经通过。
- Gap / Open questions：PL-B01…08；冷初始化、受保护端点、断续byte首HS、最终容量/资源/QoS和相邻协议待闭合。
- Assumptions：选V4 Ti60F225/I3生产封装、SC431HAI彩色4lane、显示1920×1080@60；仅软件假定，不替代实物确认。
- Dependencies：现行v0.2，实验00/02/03与已保存FE/FM/Canny/DDR/识别；现有Efinity2026.1.132、Questa2024.1、本机Python；原资料只读。
- Milestones / Detailed steps：来源→整体平台→8交接/组合→局部保持域及CDC→邻接吸收→完整窄预检设计/批准→实现→真实测试/STA；本次止于未批准局部稿。
- State transitions：只记录LOCAL_DESIGN，不改PROJECT_STATE、TASK_LEDGER或数据库。正式DB仍NOT_CONFIGURED。
- Artifacts and hashes：A列来源，当前实际文档/源hash见实验05/document-checks.json；没有bit/hex。
- Validation：PL-T01…16均NOT_RUN；本轮资料和文档审查单列，不冒充功能通过。
- Failure handling：未知旧物理效果进入隔离；不给超时、锁定或cal_done单独赋予“已排空”含义。
- Human approval gates：内容完整且当前阻塞关闭、保存读回呈现后才申请指定版本/范围/基线批准；模型获取/工作副本/构建/DB仍遵守原审批。
- Rollback：保留历史来源和稿，撤回仅本稿/本轮索引，不改原HDK、旧设计及正式状态。
- Completion criteria：完整8要求、端口/时间/复位/CDC/存储、16场景与实际证据；有效批准后才实施；实物步骤不属于本次交付。

## A. 状态与阅读入口

来源：[旧时钟/引脚证据v1](../experiments/track4_full_sw_20261004/01_baseline/platform-clock-pin-evidence-v1.md)→[原理图/封装证据v2](../experiments/track4_full_sw_20261004/01_baseline/board-pin-source-evidence-v2.md)→[摄像头启动/phase证据](../experiments/track4_full_sw_20261004/01_baseline/camera-source-and-phase-evidence-v1.md)。v6归档SHA256为45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C，top/CSI/peri/SDC原字节hash见上述来源页与审计；生产封装XML E58A269F05807655F58FC3AE9DE6F96C0E544E075436E93F5C5EC2322CE2A6BD。

相邻候选：[DDR-SERVICE v0.1](design-TRACK4-DDR-SERVICE-001.md) DS-IF07/OP08；[FM v0.1](design-TRACK4-FRAME-MANAGER-001.md) FM-IF05/06/OP05…08；[识别v0.1](design-TRACK4-RECOGNITION-001.md) MC保持域；旧版本均保持不改。候选新端口不假称已被邻接接受。

批准NOT_APPROVED；总体“按照规则完成完整测试”目标持续有效，不等于批准这份刚形成的v0.1。没有新增批准问题，也不重复已等待的FRONTEND及模型申请。下一允许行动为相邻设计/只读调查和文档复审。

## B. 整体外部行为

| REQ | 外部可检查要求／来源 |
|---|---|
| PL-01 | 固定4PLL及25/27MHz参考来源，明确core100、pixel50、CFG5、vid74.25/148.5/fast742.5、DDR400各域；发端byte单列，频率和相位不靠名称猜。DER-01/08、BL-03 |
| PL-02 | GPIO业务复位、专用配置复位、私有计算rst、物理PHY复位及安全清账分开；旧承诺和引用没有排空/恢复证明就保留。DER-07、DS-IF07 |
| PL-03 | 新job/新scope/发布只在相关端点就绪时允许；优雅排空保留旧授权范围的末段/padding/dirtyWB prepare，故障禁止首次物理proposed；旧valid不被健康门撤销。冷启动依据和暖恢复依据明确。DER-05/07 |
| PL-04 | 多位消息跨域原子保存、握手一次，FIFO有界且不可单端清指针；不可暂停相机满时失败并独立关闭。IF-01/02/03/12 |
| PL-05 | 旧scope身份完整保留、隔离通知不可变；恢复按完整scope/序号及真实证据独立确认，不改旧Q为成功。DS-08、RC-07 |
| PL-06 | 活动pin从资源→封装球号→原理图网络→电压→唯一owner核查；14位DDR地址、KEY1及四路HDMI极性补偿一次。BL-03 |
| PL-07 | HDMI固定速率继续扫描，健康/欠载时走独立本地安全像素；没有HPD/DDC反馈的输出明确N/A。H1、T4-B4 |
| PL-08 | 约束按真实时钟/CDC/端点建立，不复制exclusive或占位；分开文档推算、仿真、综合/STA和实物。R0、DER-08/09 |

正常：配置冷安全初始化→PLL合格→域释放→DDR初始化/校准→CDC会话对齐→READY；相机配置不等待尚不存在的byte边沿，未arm输入丢弃，下一完整SOF才采集。

边界：相机处于LP时byte停钟，是协议允许的Discontinuous，不作为普通掉锁；CFG/control继续配置。故障：AW已提出后core或DDR掉锁，不能拉低held AW、忘记W数据或将槽FREE；若无法证明实际效果，旧scope隔离，显示按仍可运行的视频域输出安全像素。视频时钟自身丢失时无法承诺仍然60Hz输出，只能记录故障并恢复后重启完整扫描。

普通功能复位不自动重置DDR PHY。真正配置复位会重新配置器件，软件无法靠原寄存器追认旧账；重新冷启动不得保留旧图有效性。

## C. 模块职责与整体连接

| MOD（均属系统MOD-01） | 职责/拥有者 | 不负责事项 |
|---|---|---|
| PL-CLOCK-PINS | 固定PLL、生成关系及pin配置；DDR动态相位控制仍归PHY | 不调算法、不把SDC例外当CDC电路 |
| PL-SUPERVISOR | AON25上的冷初始化依据、健康、reset流程、故障和旧scope镜像；唯一修改平台epoch及AON自有health/fault序号；外部请求序号由其唯一发送者分配 | 不凭cal_done推断排空，不代替FM引用/服务真实终结 |
| PL-DOMAIN-RESET | 各域私有reset同步释放及admit边界；保持域明确排除暖reset | 不将所有reset合成一根门清账 |
| PL-CDC-TRANSPORT | 有限mailbox/FIFO和会话关闭；运输ACK、业务完成分开 | 不替显示APPLIED、源COMPLETE或DDR B成功 |

整体路径：25/27参考→4PLL→各域；KEY1/lock/cal→AON25 supervisor→抑制新业务/请求关闭→FM与DDR/client保持域结账→允许私有rst与会话重建。scope建立前把完整身份镜像到AON，关闭时先完成真实排空再撤镜像。相机/显示的数据和控制按IF07跨域，错误通知独立于满数据FIFO。每个保持端点还有sticky stop_new：故障异步置位、合法本域同步释放；core停钟后再来边沿时它仍为1，不等旧admit1快照被新mailbox覆盖才抑制新授权。只阻止新接纳/授权，不撤已held的AXI有效拍；具体异步置位原语/时序仍PL-B01。

沿用TL0 core100，不自动改用DDR反馈100；四PLL已占满，不追加第五PLL。AON25使用已存在25MHz输入直接作为控制域，合法GCLK路径与冷初始化必须在PL-B01实证。不设计未经证明的逻辑门控时钟或运行时clock mux。

源与显示分别不能由下游停顿暂停MIPI/TMDS；因此错误隔离与安全输出有独立路径，不让等待消息锁住DDR或VSYNC。整体图和此阅读次序实际保存后向用户呈现；当前准备的是相邻闭合及复审，不是实现。

## D. 接口与组合检查

### D1. 域、时钟及pin合同

所有域在上升沿计算/提交；DDR物理/HDMI serializer可能双沿，由专用IP合同决定，不改成普通posedge逻辑。domain_mask16约定：bit0 AON25，1 core100，2 CFG5，3 CSIbyte，4 CSIpixel50，5 video-pair74.25，6 HDMIpixel148.5，7 HDMIfast742.5，8 SDRAM400，9 DDRtx400，10 DDRtx-edge400，11 DDRrx400，12 CSIcontrol（实际同core100）；13…15保留0。逻辑隔离位不虚构独立时钟。

| 域/PLL | 来源事实与拟保留关系 | 就绪条件与边界 |
|---|---|---|
| DDR3_PLL/TR0 | ref25；4路400与feedback100；shift3/sel5/ena1由ddr3_top独占，三路动态相位初值0 | lock有效、PHY初始化/校准；90edge名称不是固定90° |
| MIPI_TX_PLL/TL0 | ref25；core100；原TX500/125本次不输出DSI | core稳定；保持已有AXI/core连线，跨DDR400由受保护端点另验 |
| USER_PLL/BL0 | ref27；74.25、148.5、54fb、742.5（phase2） | 成对/逐pixel/fast保持相关生成关系；不得全局exclusive |
| pll_inst4/BR0 | ref25；pixel50、CFG5；旧peri reset/locked名字为空 | 必须真实绑定reset/lock及生成报告，不能把top同名端口当证明 |
| CSIbyte/control | byte由摄像头CK；CSI5.15 byte参数70、control100，SDC byte100 | 发端模式未闭合；LP停钟不套连续clock watchdog |
| AON25 | 输入25直接控制保持域 | 无第五PLL；若AON自身停钟，不能自证恢复 |

HDMI候选总2200×1125×60=148.5Mpixel/s，pair74.25；10bit符号half-rate742.5双沿=1.485Gb/s。SDC小数13.468/6.734/1.347ns只是旧配置，最终用真实生成关系及相位。RAW接入4×50=200Mpixel/s峰值与FE2×100相等；不等于无停顿全帧保证。

活动pin完整表见来源v2。逻辑reset KEY1/P13低有效，CRESET_N/J5专用；CLK25 J2、CLK27 H2；DDR A0…13/DQ16/DQS2/DM2/SSTL1.5，A14/15排除活动bus；HDMI3A/1.8V四路板PN交换，候选在码字边界唯一取反；camera2A/2B1.2V、I²C/reset TR3.3V。HPD/DDC/EDID/CEC因NC为N/A。模组电平、GPIO复位到XSHUTDN映射未确定，不能填写假定FPC序号。

### D2. 8个交接与无实现体字段

除物理时钟/异步锁存外，消息均valid/ready：fire=边沿前两者都1；valid一旦提出，直到fire保持所有payload。运输ACK代表接收保存，业务终态另行发送。

| IF | 提供方→使用方、字段/单位 | 接受、保证与失效条件 |
|---|---|---|
| PL-IF01 | pins/PLL/PHY→SUPERVISOR：参考clock、KEY1、四lock、cal_done单bit；PHY相位shift3/sel5/ena1由DDR PHY→PLL，supervisor不产生这些相位值 | 单bit同步/故障锁存及sticky stop_new；实际失锁边沿不确定进入Q，不假定检测零延迟；byte LP另判 |
| PL-IF02 | SUPERVISOR→各域：health147=epoch32/seq64/alive_mask16/released_mask16/fault_mask16/core_admit1/ddr_admit1/video_safe1 | 每域保存完整快照；旧held物理valid与返还ready不经admit组合门；端点就绪ACK独立 |
| PL-IF03 | 请求方↔SUPERVISOR：reset_request117=seq64/kind2/mask16/expected_epoch32/reason3；receipt/done各原body+status2/error4=123 | kind0私有/1优雅全业务/2故障恢复/3非法。receipt status0ACCEPTED/1ALREADY/2BUSY/3NO_MATCH；done另表0APPLIED/1FAILED/2QUARANTINED/3NO_CHANGE；receipt不是完成 |
| PL-IF04 | FM/service↔AON镜像：register688=seq64/op1/full_scope623，reply694=原body/status2/error4；快照manifest133=seq64/epoch32/scope_mask16/domain_mask16/count5，entry712=seq64/scope_mask16/index4/count5/full_scope623 | open完成镜像ACK后才能授对应物理承诺；close真实排空后才撤镜像。镜像op0OPEN/1CLOSE，reply status0APPLIED/1ALREADY/2BUSY/3NO_MATCH；成功reply仅在安装/关闭已提交后。重复同body幂等，BUSY可原seq重试；错代次不改旧身份。快照0…16项、count=popcount(mask)、index4就是实际scope_slot、按slot递增 |
| PL-IF05 | SUPERVISOR→FM/service：fault136=seq64/epoch32/domain_mask16/cause_mask8/frozen_scope_mask16；FM/service回逐scope证据 | 首次通知形成后不可变，后续故障进独立live记录；无响应不是成功 |
| PL-IF06 | SUPERVISOR↔保持端点：recovery_prepare/recovery_final各808=recovery_seq64/fault_seq64/fault_epoch32/full_scope623/domain_mask16/evidence_mask8/content_policy1；各自done携原body+status2/error4=814 | 完整身份及fault关联匹配。evidence bit0旧物理效果消失/1客户端承诺终结/2 CDC旧会话终结/3局部借用归还/4 clock合格/5 DDR校准，6…7保留0。物理恢复隔离新PHY AXI输入，直到全部旧exposed valid被PREPARE身份处置才重开，不能让旧AW/AR/W在新PHY再产生效果。PREPARE需0x11；只授权身份匹配端点安全处置旧held数据/引用并回QUIESCED，不解Q或授新承诺。FINAL需0x3F；全部done消费后才释放镜像借用。默认content_policy0作废旧图，1拒绝，不能仅cal_done放行 |
| PL-IF07 | CDC端点↔TRANSPORT：D3列mailbox/两个数据FIFO，session_epoch32、握手及独立关闭证据 | 完整身份和会话相符才交付；暖reset不单端清指针/ack；数据满仍能传错误与关闭 |
| PL-IF08 | PLATFORM→display：视频三相关clock、私有reset、video_safe快照和故障；display→平台：端点已隔离/流水与租约关闭证据 | video clock合法时不暂停扫描；安全像素是独立本地图案，不能读取失效DDR。clock丢失时只保证恢复程序，不保证不中断显示 |

seq均unsigned64，递增前用65bit检查，耗尽拒绝新授权并故障，不回绕；旧已提出消息继续兑现。epoch unsigned32耗尽同理，未结旧scope不允许改epoch伪装新会话。error4候选0NONE、1BAD_FIELD、2SEQ_BODY、3CLOCK_MISSING、4PROOF_PENDING、5EXHAUSTED、6UNSUPPORTED、7PROTOCOL，8…15保留非法；receipt BUSY不登记为已应用，可按相同seq/body重试，已ACCEPTED相同body回ALREADY且原done仍独立兑现。reset请求复用seq但body不同失败不改平台状态。

序号预算与唯一分配者：reset_request由MOD-12有序控制发送者分配，receipt/done回显不另申请seq；mirror由可信FM发送者分配，接纳OPEN前预留两个连续id，OPEN用P、CLOSE用P+1（65bit核验，不能溢出），AON保存匹配的关闭id，镜像重复按各自(op,seq,body)核验。AON在进入READY前预留下一首次fault/snapshot token和停止健康通知token；这些token未有保证就不授新scope。已有scope的recovery_seq复用该scope已保存OPEN token，连同fault_seq/fault_epoch/full_scope及PREPARE/FINAL类型构成唯一恢复身份，不在故障时再申请新序号。重复和各done沿用原token；health/fault预算不足只禁止后续READY/新授权，现有CLOSE/故障/恢复/返还均有预留token。不得只保住已提出消息却把尚需提出的收尾锁在耗尽之后。

full_scope623与DDR当前定义一致，含handle68/kind2/binding_mask3/J486/parent_lease_seq64；不以scope_slot4或截断seq替代完整身份。AON16镜像条目高17bit零的640容器，scope状态/代次与pending另存FF。D3的外部父bundle完整字段仍须FM/显示设计吸收，不能只用总位宽宣称接口相容。

关联生命周期：一次fault136的seq就是同次manifest/entry的snapshot_sequence，epoch冻结一致；scope_mask/count/seq/epoch在该组消息中固定；entry必须匹配manifest，漏项/重复项不能凑满成功，空集合只完成manifest。凡故障可能走PHY复位，保守冻结全部当前valid镜像；禁新OPEN保证集合不再增长。PREPARE与FINAL用两个独立类型/通道，回显同一recovery_seq/fault_seq/fault_epoch/full_scope；同fault每scope最多一个恢复流程，重复同body回已登记阶段结果，错body拒绝。平台保存该关联直到最终done消费、snapshot cold借用/held消息结束及mirror CLOSE ACK结清。platform_epoch全局只在所有旧scope结束后更新；每条CDC另有link_session32，只在该链路两端旧会话关闭（queued全部消费/身份安全处置、pending/holding/held及借用均清）后，由固定发送端提新session，双方确认再递增生效，与全局epoch分开。未把session放进189/168每条record；整个未清空FIFO及接收holding固定绑定一个不可变link_session，旧会话在任何排队项尚存时不换绑定。不清一端指针/序号造新session；计数耗尽禁止重开。

### D3. CDC目录、存储及数量

| 通道 | 域/候选运输 | 内容与边界 |
|---|---|---|
| PLATFORM-CONTROL | AON↔core及各端点，depth1 mailbox | IF02…06完整body；每方向一个未结运输，业务done可用独立邮箱避免互等 |
| CAPTURE-LEASE | core→pixel50，depth1 mailbox | 完整SourceOrigin/源描述符、scopeH68/grantH69、W/H、控制seq；准确最终编码在CAMERA/FM闭合，不把195位Origin候选当已冻结端口 |
| CAMERA-PIXEL | pixel50→core100，depth1024 asyncFIFO | record189=RAW64/type3/ppc4/DT6/VC2/VCX2/WC16/short16/error8/scopeH68；正常最多4像素，type及ppc合法码由CAMERA最终定；不向CSI提供ready |
| CAPTURE-FAULT | pixel50→core，独立depth1邮箱 | 旧scope/Origin、错误、已接前缀和关闭证据；overflow后禁止新帧arm，保持该错误直至运输ACK（转移通知所有权），重新arm另需旧scope关闭与接收业务容量，避免第二错误覆盖 |
| CAMERA-CONFIG | core↔CFG5，双向独立depth1 | seq64/config_generation64/address16/data8/op3；ACK/NACK及cfg_done不是运输ACK |
| DISPLAY-OFFER/CONTROL/EVENT | core↔pair74.25，独立mailbox | 完整DISPLAY scope/三图描述符/颜色布局及序号；换active前预留实际APPLIED业务持有槽，运输ACK不代表core已消费，不能用它假定下一事件容量；APPLIED先于对应RETIRE_DRAINED，freeze/hold移交独立；最终编码待显示稿 |
| DISPLAY-PIXEL | core→pair74.25，depth512 asyncFIFO候选 | record168=RGB48/EDGE2/ANN4/markers3/coords22/scopeH68/pair_index21；每项对应同一pair与bundle，不混图；物理扫描不等FIFO，迟到项须按预期scope/坐标/pair_index识别丢弃，超前项保持而当前槽用安全像素，精确恢复边界在DISPLAY稿闭合 |
| HEALTH | async input→AON/目标域 | 单bit三级同步候选、保持/toggle事件；不可对623bit逐位同步 |

asyncFIFO使用二进制本地指针+Gray跨域：1024深地址10/wrap1共11bit，512深地址9/wrap1共10bit；满/空只从同步到本域的远端指针判，不能看同沿远端fire。写端根据旧满状态确定本沿accept；读端每次RE预留holding，pending保存原会话和地址，下一沿capture。每端读holding候选2项，valid+reserved≤2；已RE数据不能被暖reset忘记。非法record使源/显示失败，不用数值零冒充valid。

20×512 native dual-clock能力/推断仍待工具证据：record189封装200bit（高11零）×1024需20块，record168封装180bit（高12零）×512需9块；AON镜像640×16需1块，共30候选RAM。仅在此双FIFO方案下，已列119+30=149/256=58.203125%，不含显示行bank、采集Debayer等尚未列模块（Canny44已含其FE/窗口RAM，不能重复加算）；不是全机利用率。显示也可能改为带所有权的双clock行bank运输，届时修改IF07及资源预算，不能把9块FIFO和替代方案偷偷同时/互斥计数。

mailbox发送方先固定body再翻请求toggle，直到应答同步回来保持；接收方请求同步后，只有旧私有槽空或本沿实际业务消费才把完整稳定body拷入并回运输ACK；否则不ACK、不覆盖旧body。未交付业务的私有槽仍拥有body，发送方不能以运输ACK推断接收端可容纳下一业务事件。两端会话关闭证明成立后才共同重置toggle/指针。不得在单端rst后把默认相同toggle当旧消息已处理。

### D4. 逐连接与端到端走查

- PL01→DDR：保留独立TL100/DDR400，ASYN_AXI_CLK=1、CK_RATIO=4仅参数事实；受保护端点兼容/校准仍PL-B02，不能以同ref25替代跨域证明。
- PL02→client：private_reset不触碰MC held req/W/R、assembler/carry、RAM pending、borrowed bank及terminal/release/fence；各模块需提交确切保持域清单，不能只保留service。
- PL04→FM：镜像ACK发生在grant/permit前；关scope先真实排空再撤镜像。新增FM/service因果顺序尚未吸收，列PL-B03，保持原设计版本。
- PL07→camera：未arm帧丢弃不建立借槽；满数据FIFO会使已借源失败，独立FAULT通知及关闭必须结清，不遗失EOF。
- PL07/08→display：运输ACK≠APPLIED，写B/fence≠本地预取成功。旧行bank、输出pipeline、R段及carry都不能跨RETIRE_DRAINED遗留借用；最终display合同待补。
- 若1080p line缓存方案采用SRC/EDGE/ANN两行，14块候选与6480B/line只是来源推算；candidate首行与active current/next不能同时挤进两个bank。24bit/20bit拆段尾值须移交descriptor独立carry后解除service record借用，不等下一段才release造成自锁。

正常N1：service预留scope_handle/完整身份而未授grant/permit→mirror OPEN→ACK→service open/permit→采集/计算/显示→terminal/release/fence/所有借用关闭→mirror CLOSE→ACK→槽下一沿可复用。边界B1：receipt与故障同沿，实际已保存镜像的完整身份保留；故障同沿未提交valid的pending OPEN固定回BUSY/PROOF_PENDING，后续不得再生成成功OPEN reply；已经同沿提交的条目先合并入镜像再冻结。已授者绝不丢。冻结CLOSE回BUSY不登记成功，不能撤valid/借用；恢复FINAL done实际消费且旧cold/held归还后才可正常CLOSE。失败F1：cal在AW/W中途掉落，仍合法时登记真实fire；不能确认效果则Q，fault快照drained0，时钟/cal恢复后也不自动解Q，走独立PL06证明。

## E. 局部详细设计与中文操作草图

### E1. 数据/状态、不变量

AON拥有platform_epoch32、reset_seq64/fault_seq64、健康mask、16镜像valid/gen/state与640×16冷RAM、一个OPEN/CLOSE pending及冻结快照迭代器。各域拥有私有release三级寄存器、endpoint_ready与mailbox/FIFO本地会话；原DDR/client拥有实际承诺账本。快照不另复制16份完整scope，冻结镜像条目借用；关闭/替换冻结条目须等对应recovery_done/旧借用归还，故snapshot期间不能默默覆盖RAM。

主状态候选BOOT_LOCK→LOCK_QUALIFY→DOMAIN_RELEASE→DDR_CAL→SESSION_ALIGN→READY；优雅复位STOP_NEW→CLIENT_DRAIN→SCOPE_CLOSE→PRIVATE_RESET→SESSION_ALIGN；未知故障FAULT_ISOLATE→WAIT_CLOCK→SNAPSHOT→PHY_RECOVERY→PROOF_WAIT→RECOVERY_DONE→SESSION_ALIGN。状态编码拟5bit，非法态故障并抑制新业务，不清旧账。

| INV | 恒成立的候选规则 |
|---|---|
| PL-INV01 | 新物理承诺对应完整、已ACK的AON镜像身份 |
| PL-INV02 | admit禁新job/scope及故障首次proposed；优雅尾义务有范围内例外，旧valid/payload和实际账本不因healthy/rst撤销 |
| PL-INV03 | scope/grant/gen复用晚于所有旧引用/消息/物理效果与镜像关闭ACK |
| PL-INV04 | fault、snapshot、done一经提出直到接受保持；通知快照不追随live变化 |
| PL-INV05 | 恢复按完整旧scope和seq匹配，0x3F证据各有真实来源，不从超时推导 |
| PL-INV06 | mailbox原子，运输/应用/归还为不同事件，单端reset不造ACK |
| PL-INV07 | FIFO每项只写一次/读一次；RE reserve与holding不超过容量，pending会话不丢 |
| PL-INV08 | CSI不可反压；已借源overflow失败并独立结清，未借源才可直接丢帧 |
| PL-INV09 | related HDMI clocks保留真实相位/频率关系，极性补偿仅一处 |
| PL-INV10 | 设计/算术≠功能/STA/硬件证据，序号和资源不隐式回绕/扩容 |

### E2. 八项中文操作草图（同沿先看旧状态）

**PL-OP01 选择时钟和pin。** 先核选定V4/生产封装、原理图网络、电压、唯一owner；形成4PLL固定表与活动pin表。A14/15从活动bus排除，KEY1与CRESET_N分开，HDMI补偿唯一。生成报告前只是候选。约束目标跟真实新层次和生成时钟重建，不沿用旧坐标名字。

**PL-OP02 冷启动和域释放。** 冷安全初始化依据先成立；否则不从未知FF“自选READY”。25控制域保持输出禁止新业务；分别等待连续64个AON边沿采到所需lock有效，计数7bit0…64，掉落清资格。此2.56µs仅候选稳定观察窗，不代替PLL厂家锁定/相位要求。建立BR真实绑定，先释放CFG5/control100并允许相机配置，byte没有HS边沿则本域release尚未完成；不等byte_ready才放XSHUTDN。各域私有reset异步assert、至少三级本域同步release并ACK；DDR初始化/校准成立及CDC会话对齐后才READY。首HS未arm帧丢弃，下一完整SOF才授采集。每步超时只告错，不造cal或drained。

**PL-OP03 有序复位请求。** 旧状态空闲且seq/epoch/mask合法才保存body并ACCEPTED，BUSY/错代次不修改账本。与其同沿已有MC/client fire照实际计入；kind0/1停止下一新job、输入/算法扩展和offer，但保留当前旧job/phase已授权范围内的有限末段/padding/dirtyWB prepare/req，local_quiesced之后才seal关闭prepare；kind2故障停止首次物理proposed，已授permit/held逻辑请求通过失败结账或PREPARE身份恢复终结。请求已保存后运输源可释放body，平台done仍独立持有。重复同body不重复执行；同seq不同body拒绝。按kind进入优雅排空或故障流程；不存在“按下KEY1就清全部RAM/valid”。

**PL-OP04 scope镜像安装/关闭。** AON接OPEN保存完整scope及slot/gen，原slot有旧未结或冻结借用则拒绝。逐32个20bit字写640容器，高17零，32周期=1.28µs@25MHz；完成后提交valid并固定ACK，FM/service收到ACK后下一沿才可授物理承诺。CLOSE仅接受完整匹配且FM/service排空证据成立的body；冻结条目回BUSY且不记成功、不撤valid或pin。恢复FINAL done实际消费且旧cold/held借用归还后才能重试。普通CLOSE commit撤valid→ACK消费→下一沿允许复用。RAM RE保存slot/word/purpose/seq，下一沿capture；同址读写错开，不依赖碰撞模式。新增OPEN与fault竞争先登记实际握手；fault冻结优先于尚未提交的OPEN，后者回BUSY/PROOF_PENDING并终止安装，不会在之后补成功ACK。若OPEN本沿已经提交valid，先合并再冻结；冻结同沿CLOSE不提交清valid。未成功reply绝不授物理承诺。

**PL-OP05 正常暖复位。** 禁新job/新scope/输入扩展/offer但保留MC全部旧承诺，旧授权当前phase的有限尾段/padding/dirtyWB prepare/req仍允许，不开下一算法阶段；client先停止计算扩展，完成已承诺尾值/dirty WB，再关请求代次；等真实terminal、release ACK、fence、本地pending/借用与CDC消息结清→关scope/镜像→assert对应私有reset→本域同步release→联合会话对齐→done APPLIED。不能先清数据源再等service，不能先全禁prepare或seal再需要末WB。没有排空证据转OP06，不回READY。

**PL-OP06 故障与冻结旧集合。** lock/cal健康变化锁存并抑制新增；采样/同步延迟内可能发生的真实承诺仍计入镜像和账本。合法时钟尚在则继续收旧R/B和返还；不确定实际物理边沿/响应则冻结Q。AON镜像保留旧身份，冻结scope_mask/epoch并按slot递增发送manifest/entry/fault；新fault写live而不改已held通知。丢core clock时暂不能读取其真实排空证明，等恢复后核对；超时不清Q。

**PL-OP07 两阶段逐scope恢复。** 合法clock重新资格，由明确PHY恢复程序先证明冻结集合的旧物理效果消失；新PHY的AXI epoch隔离保持关闭，旧exposed AW/AR/W留在旧账本而不能进入重启后的PHY，物理恢复本身不等于新请求重开；0x11（物理消失＋clock合格）成立后，给完整旧scope发recovery_prepare808。端点先核fault/epoch/seq/完整身份，在stop_new保持1的条件下，将已被物理恢复取消的held req/W/R及RAM pending按身份安全终结/丢弃、归还旧借bank/descriptor与CDC消息；此处是独立恢复授权，不是普通暖rst或伪造AXI fire。保持旧Q通知和恢复live账本，回QUIESCED（prepare_done814，status0；错误1FAILED/2WAIT_PROOF/3NO_MATCH）。

平台收齐service及各实际client/CDC的QUIESCED并核对local无借用，再汇总bit1/2/3，clock/cal保持有效才形成recovery_final808（0x3F）。接收端复查完整关联，执行最终旧有效性处置并回final_done814（status0APPLIED/1ALREADY/2WAIT_PROOF/3NO_MATCH）。全部受影响旧scope的PREPARE QUIESCED之前不得重开新PHY AXI入口；后续校准可在其隔离条件下完成，真实顺序必须由IP证明。所有final_done真实消费、旧cold/pending/held/snapshot引用消失后释放mirror pin，随后CLOSE/ACK才能复用；不因发送done就放pin。旧QUARANTINED通知仍drained0。默认重校准作废旧图，FM重建源；所有旧scope/消息结束后才改全局epoch，链路各自双端关闭后更新link_session与READY。未取得0x11先停，不能让客户无授权放bank；未取得0x3F保持Q，不能为等borrowed-bank归还而省略PREPARE。真实PHY物理消失证明和局部恢复端口仍PL-B02/03。

**PL-OP08 CDC收发与安全输出。** mailbox先固定body、请求同步、接收私有保存、运输ACK，再业务APPLIED/done；相机FIFO根据旧满/空和holding预留读写，停顿保持item。满时锁源错误并关闭arm，独立FAULT邮箱持有，不靠丢失EOF结束。显示FIFO空或DDR失效用本地安全pixel，HS/VS/DE按视频扫描继续；layout/cfg/bundle不混。byte LP无边沿保持本域同步器，首HS不接受旧会话。会话flush只在两端关闭且无pending/held/引用时联合初始化，检测单侧rst作为故障。

相邻反例：client5 rst时其point/scatter/final/row bank可能仍被旧W借用，平台不能只保留service FIFO却清客户端RAM/pending。显示一R live时，段末4B carry若仍归service旧record，下一段被旧release阻挡；必须转为descriptor值副本，非借用状态，再独立结账。这两处反馈已写D4，待邻接稿吸收。

## F. 语言与跨语言契约

本任务为RTL/SV2009候选，工具版本见A；没有C++实现，所有权/RAII等N/A。Python只用于获批后的独立事件参考，不在本轮生成模型。

| 项目 | 本任务合同 |
|---|---|
| A 数值 | D2固定宽度/编码，seq扩65、epoch扩33；FIFO地址/Gray11或10；640高17零；越界/非法码失败不截断 |
| B 时钟/观察 | 普通域posedge、基于旧状态fire/new状态提交；TB未来在NBA后稳定观察；serializer/DDR双沿依真实专用IP |
| C 接受/交付 | 消息valid&ready，ACK/应用/排空独立；CSI无ready，video固定扫描，不从可暂停模型推断 |
| D valid/推进 | 空无数值含义；未arm输入不借槽；invalid不推进输入逻辑接受索引，错误关闭另行推进；显示物理扫描坐标每视频槽继续，迟到pair不能横移补进下一槽 |
| E 反压/保持 | held body/item/pending原会话稳定，健康门不撤旧valid；接收预留后才发RE；CSI满失败 |
| F 延迟/吞吐 | 同步至少3目标沿候选、mailbox往返无固定延迟；scope32写沿；64 AON资格沿；FIFO容量和串行相位未实测 |
| G 复位 | 冷safe依据与暖private隔离，async assert/sync release；保持域/旧mirror/FIFO只在安全关闭后清 |
| H 配置 | pin/clock静态；mode/layout/cfg随父bundle快照；reset body按接纳时epoch；PHY动态相位唯一owner |
| I 存储 | D3候选30RAM、scope冷RAM1R/1W控制器、双FIFO pending/holding；端口/dual-clock及全机预算仍BLOCKING |
| J 身份 | 完整scope623及handle/gen/seq、源/图/坐标/pair_index，不以槽号或颜色猜帧；image内容失效另标 |
| K CDC | D3同步器/mailbox/GrayFIFO；两端关闭与会话绑定；related视频clock另走真实生成约束 |
| L 实现 | 4PLL、25/27/100/50/5/74.25/148.5/742.5/400候选；无第五PLL；真实pin/STA/IP兼容和资源未运行 |

共同参考是事件账本/身份/顺序/容量，不模拟电气亚稳态。硬件执行单独验证采样、保持、同步、复位和真实PHY/serializer；软件结果对应每个seq/full_scope/session/坐标与实际fire，错会话不比较为成功。逻辑模型不能证明模拟电气、PLL抖动、CDC MTBF或STA。

约束设计：建立25/27参考与真实PLL generated clocks；明确DDR动态phase合法模式。只给已识别同步器/GrayFIFO相应路径例外，检查Gray总线时延/偏斜；普通组合多位总线不能被false path隐藏。旧USER_PERIOD、JTAG clock/延时、坐标型reference_pin、byte70/100和exclusive全部逐项重新核对；N/A端口有来源，未运行SDC解析或STA。

## G. 实施与验证计划（未执行）

先关闭PL-B并完成CAMERA/DISPLAY/FM/DDR新端口吸收→窄平台预检范围/基线冻结→READY/指定批准→独立work实现clock_reset_supervisor、domain_reset_bridge、cdc_mailbox、cdc_pixel_fifo及pin/clock配置；这些仅计划名，不表示文件已生成。保护IP/2Gb器件验证需已批准模型材料和执行授权，不能仅写行为存储替代。

| TEST | 目标/输入与事件 | 期望/依据及观察 | 状态 |
|---|---|---|---|
| PL-T01 | PL01/03：冷启动、四PLL不同锁定次序 | 未合格不接job，BR lock有真实绑定；NBA后事件检查 | NOT_RUN |
| PL-T02 | PL02/04：无byte边沿启动后首HS | CFG/control可先运行，首未arm帧丢弃，新完整SOF采集，无启动环 | NOT_RUN |
| PL-T03 | PL01/03：逐个PLL掉锁、AON自身停钟 | 可用域隔离；视频停钟不伪称60Hz；恢复无自动FREE | NOT_RUN |
| PL-T04 | PL02/05：AW held、W半段、R/B到达时cal掉落 | 实际fire登记、held不撤，未知进Q，旧图不发布 | NOT_RUN |
| PL-T05 | PL02/05：client5 RAM RE后rst，旧W仍借bank | pending/carry/借用保留，terminal/release独立结清 | NOT_RUN |
| PL-T06 | PL04：mailbox快慢clock/停顿/重复seq错body | 原子一次、receipt不替done，错误不改别人状态 | NOT_RUN |
| PL-T07 | PL04：capture FIFO满且EOF也来 | 独立错误/关闭，无永久占源或静默成功 | NOT_RUN |
| PL-T08 | PL04：单端FIFO rst、pending RE、旧toggle | 不能造ACK/空证明；两端关闭后会话重建 | NOT_RUN |
| PL-T09 | PL05：mirror OPEN写32沿及fault同沿 | 未ACK无物理新承诺；冻结集合含全部可能旧效果 | NOT_RUN |
| PL-T10 | PL05：16scope snapshot、错gen恢复、借用阻塞 | manifest/count/index及fault关联完整，PREPARE才准处置旧借用、新PHY不重吃旧valid，FINAL才解保持，错消息不清Q，原Q状态不可变 | NOT_RUN |
| PL-T11 | PL02/05：优雅复位末WB与seal/release | 尾义务先关请求；无互等、done后才READY | NOT_RUN |
| PL-T12 | PL07/04：freeze/offer同VSYNC、返回事件反压 | 真实旧active先快照，有序事件及hold不丢；欠载迟到pair不横移、超前保持；FM/显示合同 | NOT_RUN |
| PL-T13 | PL01/07：74.25→148.5→742.5位序/phase/reset | 两lane顺序、10bit符号双沿、R/G/B与控制一致；protected实际仿真 | NOT_RUN |
| PL-T14 | PL06：pin重复/旧KEY0/14地址/HDMI反相两次 | 静态报告拒绝矛盾；实际最终电气及封装报告 | NOT_RUN |
| PL-T15 | PL03/05：seq64/epoch32耗尽与旧held消息 | 新授权禁止，已有OPEN保有CLOSE/故障/恢复预留token，旧义务兑现，不回绕或误匹配 | NOT_RUN |
| PL-T16 | PL08：真实CSI/DDR/serializer展开、全机CDC/SDC/资源/STA | 分开模型与真实PHY、clock例外/约束覆盖及PNR；日志证明 | NOT_RUN |

局部文字事件→相邻组合→真实工具/PHY→完整1080p，层次互补。种子、准确IP许可/观察周期、最坏期限尚未冻结；不伪造执行日志。0x3F证明各来源需可审计实际事件，超时仅告失败。

## H. 双向追踪

| REQ | MOD/IF/草图/不变量 | 计划文件职责（未生成） | TEST/期望来源 | 实际证据 |
|---|---|---|---|---|
| PL-01 | CLOCK；IF01/08；OP01/02；INV09 | clock/pin配置 | T01/02/03/13/16；来源表/IP | 只读来源，业务未运行 |
| PL-02 | RESET/SUP；IF03/06；OP03/05/07；INV02/03 | domain_reset_bridge | T04/05/08/11；DS08/RC07 | 待实现 |
| PL-03 | SUP；IF02/03；OP02/03；INV01/02/10 | clock_reset_supervisor | T01/03/06/15；接纳事件 | 待实现 |
| PL-04 | CDC；IF07；OP08；INV06/07/08 | cdc_mailbox/pixel_fifo | T02/06/07/08/12；容量与会话 | 待实现 |
| PL-05 | SUP；IF04/05/06；OP04/06/07；INV01/03/04/05 | mirror/recovery保持域 | T04/05/09/10/11/15；完整身份 | 待实现 |
| PL-06 | CLOCK-PINS；IF01/08；OP01；INV09 | peri/pin配置 | T14/16；原理图/封装 | 资料映射已核对 |
| PL-07 | CDC/显示邻接；IF07/08；OP08；INV06/09 | safety输出边界 | T03/12/13；固定扫描 | 待实现 |
| PL-08 | 全部；F/G；INV10 | 约束/验证职责 | T16；真实报告与层次 | 未运行 |

反向：四候选RTL职责分别映射上述REQ/IF/OP/TEST；scope镜像是PL05派生，不为无关代码新增空需求。真实文件/符号/hash/日志获批后补，不用行号或假Git替代。

## I. 门槛与评审

①行为/样例B；②职责/来源C/A；③字段/CDC/相容D；④状态/10INV/8草图E；⑤RTL A–L与三份映射F；⑥D4端到端、G/H覆盖；⑦实施/验证/追踪G/H；⑧**不满足，PL-B01…08**；⑨本次保存后实际读回/呈现与三方向审查在实验05；⑩v0.1/范围清楚，但实现基线未冻结。因此不标READY、不申请本稿业务实现批准。

| BLOCKING | 当前影响与补齐方法 |
|---|---|
| PL-B01 | AON冷安全初始化、lock故障锁存、BR reset/lock、停止clock与同步释放的真实器件/工具合同；须本地IP文档及窄预检，不能由未知FF自证 |
| PL-B02 | 2Gb器件依赖、受保护CSI/DDR/编码器Questa兼容、PHY相位/校准；既有模型申请待答 |
| PL-B03 | AON mirror/open/close/recovery与FM/DDR真实端口未吸收，完整旧client/CDC承诺证明及暖保持清单未冻结 |
| PL-B04 | byte70/100、相机发端/首HS、模组reset/电平/EXTCLK与配置成功合同；CAMERA设计继续 |
| PL-B05 | 两FIFO双clock原语/深度与最坏突发/关闭；显示行bank或像素FIFO选择、端点完整编码；容量失败不能冒充稳定吞吐 |
| PL-B06 | related HDMI phase/编码延迟/位序、最终SDC例外及generated节点/约束覆盖未实测 |
| PL-B07 | 当前peri14地址位/电气/HDMI common-mode合法性及软件pin生成报告未运行；实物确认另保留人工闸门 |
| PL-B08 | 全机RAM/XLR/DSP/PLL及采集/显示/算法仲裁期限、恢复硬边界尚未闭合；预算不是综合证明 |

## J. 变更与恢复

首次平台稿从旧source表细化4PLL/12域、暖保持/冷初始化、完整scope镜像/恢复、FIFO/mailbox及pin证据。新mirror ACK前授承诺禁止、receipt/done分开、故障不可变及独立恢复均需邻接新版本；不沿用旧稿批准。恢复读取本稿、sourcehash/05审查及真实授权；如果改FIFO/clock/复位/端口，先修订设计和重新评审，不隐式实现。

## K. 实录

只读归档/source/PDF/封装与算术已进行，来源A/D及实验01。保存、实际读回、审查结果由05记录。RTL/脚本/可执行testbench、IP生成/编译、业务仿真、综合、PNR/STA、bit/hex、实机、正式DB/状态写入均未执行。理解验收待用户实际作答，不把文档讲解当作已理解。

## L. 交付与阅读

阅读B正常/边界→C控制保持路径→D域/pin/8交接/CDC→E八项操作→F约束→G/H验证追踪→I实际阻塞。复位需求变化由PL02/05→IF03…06→OP05…07→T04/05/09/10/11/15修订；硬件模式变化由PL01/06→来源/pin/clock→T13/14/16修订。

此稿交付平台候选设计与来源闭合，不交付业务代码/仿真通过或整机bit。后续CAMERA/DISPLAY及FM/DDR统一接口后再回此稿关闭阻塞；所有最终文档、端口、RTL、测试需按实际文件重新核对。
