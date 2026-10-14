# TRACK4-ALGORITHM-RECOGNITION-NMS-LIFECYCLE-001：DENSE 批次与四行 NMS 快照 v0.1

## A. 状态、范围及计划入口

日期：2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本卡是 RA-B05 的有限衔接设计，不是业务代码、可执行参考或测试，也不是 R4 已完成。
Goal：在完整 1920×1080、512θ×277ρ、32 个 16θ 批次上，保留完整计票与 radius1 二维 NMS，落实每批清零、旧边界保留、四行复制、镜像与 LINE 顺序。Current state：现有 R4R/RA 给出了逻辑容量和组访问，但尚无完整批次/快照实体；旧 EX 的四 RAM 布局不是现行 DDR 实现。Target state：在既有一个 DENSE 和一个四行 NMS packed 对象内形成可组合的有限方案。
Gap / Open questions：NS-B01 真实 LINE_WORK 权限、CLEAR/初始化合并、有效前缀及动态 row gate 的 STORE/O/SC 接线；NS-B02 RA 实际单槽租约及匹配 DDR 可见性/no-future；NS-B03 全机状态/运输/服务预算及共同设计吸收。均 OPEN。本文闭合算法调度选择，未关闭这些实现前提，也不把 RA-B05 整体标成 CLOSED。
Assumptions：仅板卡现有资源及已允许的板载 DDR；完整五基础/六高阶、原目标/负样本/旋转/重叠/缺边要求保持；不恢复已撤回的目标尺度、噪声限制或低分辨率。core 同域 posedge、同步高有效 rst，全部 typed 接口可暂停，单 RC 调用者、单 STORE 在途。
Dependencies / Milestones / Detailed steps：读整体 B→连接 C→接口 D→局部 E→数值/费用 F→场景 G/追踪 H→真实读回/独立审阅→NS-B01…03 联合闭合→指定范围 READY/批准→独立 work 实现验证。State transitions 是本卡局部语义，不改正式 PROJECT_STATE。
Artifacts and hashes：只新增本卡及审阅/进度/追加文档事件；本卡身份由外部检查点登记。没有 Git commit。以下为实际输入，原文保持不改。

| 来源 / 实际读段 | SHA256 |
|---|---|
| [R4R v0.2](design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md)，D3/D7/E4/E10：完整计数/操作/容量/profile | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| [RA v0.1](design-TRACK4-ALGORITHM-RECOGNITION-ACCESS-001.md)，初始化/单槽/组门/真实费用 | 33388EC125981965D070AAF47CBE9B87B6096B9200BD5B917C433068887602BA |
| [PK v0.1](design-TRACK4-ALGORITHM-RECOGNITION-OBJECT-PACKING-001.md)，逐记录/相邻位/末端 | 50EDCEB6FC699B34D81F10195099E6418B563FF9CEE32D77606139B0C148A771 |
| [26 对象字典](../experiments/track4_algorithms_20261004/01_baseline/recognition-packed-record-map-v0.1.json)，DENSE/NMS/LINE 几何 | D40347C332464AC5D01D9D52A48B24484446C57A46E21E4F2F0DD225F6900A51 |
| [DIR v0.1](design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md)，D1/D2/D5/OP04–05 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| [SC v0.1](design-TRACK4-ALGORITHM-STAGE-CAPABILITY-001.md)，D2–5/E5/phase 边界 | 846D6D6E195146EA4A0B00934BD5EE9C24EA60D3180BB6D4F5BAF24E03B689F7 |
| [旧 EX](design-TRACK4-RECOGNITION-EXECUTION-001.md)，178–185：四行与延迟方向顺序，仅逻辑参考 | F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178 |
| [旧 ALGO](design-TRACK4-RECOGNITION-ALGORITHMS-001.md)，159–163：镜像/平票，仅算法参考 | D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB |

Validation：仅文档、固定整数几何与独立静态审阅；G 全 NOT_RUN。Human approval gates：本卡未 READY，无新实现许可；原 R1/预检本地审计例外不扩展。Rollback：保原输入与正式状态，只撤本候选后续引用。Completion criteria：算法调度、真实权限/效果及全预算组合闭合后才能 READY；获指定批准后才生成代码与验证。

## B. 整体行为、选择及可观察边界

NS-REQ01：每个 batch 的所有 4432 个计数，在该批第一 POINT 投票前真实归零；共 32 次完整 CLEAR。先前批的初始化或已满 initialized_prefix 不等于下一批票数清零。
NS-REQ02：NMS 对象是原始 uint21 票数的四行快照，不是边缘 bitmap，也不是只保峰值。选择 slot0=θ0、slot1=θ1；slot2/3=最近批的末两行。禁止用缺失 halo 当零，或增加隐形全行缓存。
NS-REQ03：成功时每个合法中心 (θ,r) 恰好判一次；ρ0…276、θ 扫描顺序 1…511,0。合格峰必须通过全部 radius1 合法邻居的真实票数比较；已经由支持门或某邻居证明拒绝者可提前结束。大票优先，平票按归一化全局 (θ,r) 小者。line_min_support 来自同一冻结 PROFILE1024，合法至少 2，不临时改门值。
NS-REQ04：跨 π 边界先对整个邻居 ρ 坐标镜像 276−r；ρ 越界只为不存在的邻居提供 0，禁止访问235个padding位置ρ277…511，合法ρ235照常参与。θ0 最后判定不改变其 canonical 平票优先级。
NS-REQ05：snapshot_ready 最后发布；rolling 旧读、held、permit、journal、native 及物理效果真实关闭后才覆盖。NMS 全对象保持合法 mutable，不逐行 SEAL_TABLE；没有新 immutable pin 或虚构版本 token。
NS-REQ06：峰按上述扫描顺序及 ρ 升序 append LINE；原 1024 容量，第 1025 个峰整帧 CAPACITY。完整 LINE 写成功才增加 count/id。所有 512 行、延迟边界与 pending 结束后才 seal LINE；失败/取消不发布前缀成功。

正常路径：本次 NMS 首次全区初始化→batch0 清 DENSE/计票→复制 0/1/14/15→判 1…14→batch1 清 DENSE/计票→用旧 14/15 与新 16/17 判 15/16→判 17…30→旧借用关闭→复制 30/31，依次继续→末批判 495…510→复制 510/511→判 511→判 0→完整 LINE 封存。
反例：同一本地 lane 的旧票 1 未清，在下一批相同 ρ 再投一票得到 2；它混入两个不同全局 θ，不能称当前批合法结果。边界例：(0,0) 与 (511,276) 同票且无更大邻居，canonical θ0 胜；θ511 即使较早扫描也必须被抑制。

## C. 模块职责、连接与唯一拥有者

路径：R4 RC-NMS 协调器→原 OBJ RQ799/KEY287→RA STORE→SC/O 合法 mutable/rounded 许可→现有 DENSE/NMS/LINE DDR；原 RSP872 返回→逐字段核实→本地 row/data/LINE 状态提交。投票仍走完整 DENSE_ADD16，R3 系数和现有投影结构不在本卡改动。
MOD-NS-SCHED 唯一拥有 batch、DENSE ready、四 row 的 globalθ/ready、复制游标、中心/邻居游标和 LINE 推进顺序；不拥有目录 ref/version/grant 分配权。MOD-NS-COPY 每次只保一个 uint21，完整源 READ 后目标 WRITE，完成 277 条才发布一行。MOD-NS-COMPARE 保中心/当前邻居各 21bit，逐邻居比较，无九票数组。
MOD-RA 按单槽 RMW 保护目标相邻位；O/SC 负责真实许可及对象生命周期；物理提供者负责写后可见性和 no-future。row ready 不是 SC snapshot_valid、stage_generation、cap_revision、目录有效前缀或独立对象引用。已有身份锁在完整当前 RC/STORE 上下文；不从最新输入再建。
旧 EX 的四个 20×512 RAM 与 low20/high1 地址只作旧实现比较；当前实际提议仍是 DDR packed NMS1108×21。保守不将 NMS 区 alias 给 CELL，也不借旧四 RAM 预算抵扣当前全机。

## D. 接口、布局及组合设计检查

| IF | 本卡规定的交接/值域 | 前提、保持及未闭合点 |
|---|---|---|
| NS-IF01 批次 CLEAR | 原 OBJ op2/object8/index0/length4432/payload0；NMS 初次 op2/object9/length1108 | 真实 LINE_WORK writer/prepare 资格及全部 rounded 区范围；CLEAR 逐物理完成后才 ready，不因 REGISTER/RJ 授权；NS-B01 |
| NS-IF02 快照复制 | 原 op0 READ DENSE item=277×local_lane+r，成功RSP value低21/高491零；原 op1 WRITE NMS item=277×row_slot+r，length1，request payload低21/高491零，成功WRITE RSP value全0 | source 每记录≤E；目标采用 RA 邻位保护；成功必须 effect_ok 和正确 KEY，旧部分效果仍记账；NS-B02 |
| NS-IF03 NMS 读取 | 原 op0 READ 当前 DENSE 或已 ready 的 NMS row，length1/payload0 | 路由先匹配全局 θ/当前 batch/row ready，再实际许可；不能用本地 slot 代全局 θ，READ 返回高491零 |
| NS-IF04 LINE append/封存 | 原 op1/object10/index=line_count，完整 LINE64、高448零；结束原 op3/index0/length=count | 票/θ/r/flags0 规范；count≤1024，完整成功后推进；seal 没有代替全部物理 pending/借用关闭 |
| NS-IF05 stage 与收尾 | SC namespace4 值5、stage_index2 值2，完整 H/gen/revision/ref/version/grant/真实 phase | phase 编码和操作白名单仍 SC A3-03/RA-B01；不得硬 cast typed 原因、用软件 reset 清效果或借 source BUNDLE phase |

真实几何：DENSE typed8→descriptor21/base87346688/4432×21/round64=11648B；NMS typed9→descriptor22/base87358400/1108×21/round64=2944B；LINE typed10→descriptor23/base87361408/1024×64/8192B。都沿字典；普通数据、授权 tail、guard 分开。
NMS 四行在同一连续 bitpack 中，行起点相对 bits 为 0/5817/11634/17451；非独立 byte 对齐。row1/2/3 起点在 128bit 单元内偏移 57/114/43，相邻行分别共享 unit45/90/136。覆盖 rolling row2 第一条会读改写含 row1 尾部的 unit90；必须保 θ1 数据。不得按 277×3B 或每行独立对齐重新寻址。
首次初始化之后，batch0 依 slot0→1→2→3 逐行完整写，形成连续 1108 条实际写入证据；未来 slot2/3 完整覆写只更新本地语义 ready/θ。O/STORE 的有效前缀规则与 dynamic row gate 仍须 NS-B01 联合接线；initialized_prefix 满不证明行已来自所需 θ。
选择 LINE_WORK 内 DENSE/NMS 持续 mutable，所有 CLEAR/投票/复制/NMS 的业务子阶段由 STORE 精确校验；不在每批或每行调用全对象 SEAL。若真实 grant/ref/version/access/权限 phase 改变，必须先按 SC fence 结旧义务、由 O 重捕获新资格；本地 row 数据不能据旧 ready 越过新身份。目录版本保持不变只适用于同一合法 mutable 对象及授予，不由本卡保证未冻结的权限矩阵。

## E. 局部状态、不变量与详细中文操作草图

E1 建立：锁当前完整 H/PROFILE/已 committed POINT E，等待 LINE_WORK 真资格。四 row ready=0、DENSE ready=0、rows_done=0、late0done=0。NMS 全 rounded 初清真实完成后才允许第一个 packed WRITE；只初始化当前对象，guard/历史结果不清。
E2 每批：先把 DENSE ready 置0，确认上一批所有 DENSE 读取/复制/旧请求与效果已闭合，再提出全 CLEAR。完整匹配成功、真实可见且前缀齐全只建立本批零值/可RMW资格，DENSE ready仍0；FSM进入已CLEAR后的系数/投票阶段，不另假造一份初始化证据。16 系数真实锁定后扫描全部 E POINT；每点的 DENSE_ADD16 完成才推进 ordinal。末点全部效果关闭后的后续沿才置 DENSE ready=1，进入只读计票结果阶段，NMS/copy不得早读。E=0 仍 CLEAR，各计数真0、不造投票，在真实clear/系数及空遍义务闭合后同样置ready。
E3 复制一行：将目标 row ready 置0，保它的旧 θ 只作诊断；核无旧行读者/在途/borrow/held。cursor0…276，真实 source READ→验 canonical/≤E→保存 operand21→真实 WRITE 同一 count 至 row_slot 对应项→核效果成功并闭合该操作→cursor++。operand21从源READ真实消费后保持到目标WRITE发布/fire及结果校核/该操作闭合；目标WRITE已held时cancel仍兑现，尚未published时可按ABORT停后缀并保持半行ready0。消费RSP不等raw/native/permit引用自动关闭。全部 277 条、末 RSP 及实际 permit/journal/effects 闭合后，后续沿写 rowθ 与 ready=1。任何失败不发布半行。覆盖 row2/3 的共享单元保 first0/1 与相邻 row 的最新位。
E4 batch0：票全部结束后依次复制 local_lane0/1/14/15 到 slot0/1/2/3。完成 θ1…14，每 θ 按 ρ0…276 调 E6；其邻行都在当前 DENSE。θ0/15 延迟，不能置它们的完成事实。确认 DENSE 旧使用闭合才开始 batch1 CLEAR。
E5 batch b=1…31：新批票全部结束；先判旧末 θ16b−1，左/中心取 slot2/3、右取新 DENSE lane0；再判新首 θ16b，左取旧 slot3、中心/右取 DENSE lane0/1。继续 θ16b+1…16b+14，邻行在 DENSE。旧 rolling 全部请求/响应/permit/borrow/effects 真关闭后，依次复制新 lane14/15 至 slot2/3，更新它们的 θ。前后两行不凭 copy 请求发出就 ready；任何旧债未知则停/隔离，不下一批 CLEAR。
E6 判一个中心：根据 θ 与当前 batch/row 标识选择真实 source，READ 中心 count21；每次中心/邻票READ先核完整KEY/成功/effect_ok/high491零及票≤E，非法值是帧级错误，不按低票早退。中心票小于 line_min_support 则拒峰，等于门仍进入比较；否则按固定邻居 (dθ,dρ)=(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1) 依次比较。先以 signed11 形成 θ+dθ、signed10 形成 r+dρ；ρ 不在0…276只提供不存在邻居0；跨 θ0/511 对合法邻居整个 ρ 镜像，再收 θ9/ρ9。邻票更大或相等且其 canonical(θ,r)更小则中心被抑制，可提前结束余下比较。相等判定按全局 canonical key，不用扫描先后/row_slot。仍合格才完整 append LINE，保持中心值至写真实成功；每中心结清全部旧义务才下一 ρ。
E7 末边界：b31 已判495…510且真实复制510/511后，判 θ511，左/中取 slot2/3，右取固定 slot0 且镜像整个邻居 ρ；再判 θ0，左取 slot3 且镜像，中心/右取 slot0/1。每行完成全部277中心及其 LINE 写后 rows_done++；全流程 rows_done=512、late0done=1，全部义务空，才允许 LINE SEAL。batch31只转末边界/完成，不把batch5加一回绕为0；late0done只在θ0真整行结束时置位。slot0/1 不在此之前覆盖，NMS/DENSE 对象不自行 free。
E8 失败/取消/复位：同沿先记旧 fire/实际效果，再 sticky 失败并下一旧 ABORT 停未发表后缀；已经 held 的 READ/WRITE/DENSE_ADD/RSP/NUM 保持并兑现。CLEAR/copy 部分成功只留真实前缀，row ready 不发布；未知 no-future 保 Q 和原身份，不以 late ACK 自动复活行。真正旧 LINE 前缀保诊断，未 complete 不发布 bundle。同步 rst 时 fire0；暖复位不假清 DDR/row/pin/台账，遵原全机隔离。

不变量：已 ready 的 fixed row0/1 在本局部完成前不改；ready 的 rolling θ 只能是当前保留批末两行且读旧行前完整匹配；DENSE 开始每批是全零、新票只来自该批每 POINT 每 θ 一次；中心序列是1…511,0的双射，不能重复判边界；第1025峰不是截断成功；row ready 只是有数据的本地证据，不是物理许可或 immutable token。
局部阶段候选：IDLE、WAIT_PERMISSION、INIT_NMS、CLEAR_DENSE、LOAD_COEFF、VOTE、EFFECT_FENCE、COPY_READ、COPY_WRITE、SNAPSHOT_READY、NMS_CENTER_READ、NMS_NEIGHBOR_READ、NMS_COMPARE、LINE_WRITE、ROW_DONE、RETIRE_OLD_HALO、COPY_NEXT_ROLLING、BATCH_DONE、WRAP511、WRAP0、ALL_PEAKS_DONE、ABORT、DRAIN、Q；24 个语义状态可用5bit，24…31非法。不是每个状态必定一时钟，具体沿/握手由真实提供者界定。

## F. 语言、表示、费用与时间契约

RTL A/J 数值：票 uint21≤E≤2073600，比较精确；copy cursor9 可表示完成端277；row slot2、source lane4、batch5合法0…3/0…15/0…31；rows_done10 可表示512。θ运算前 signed11、ρ前 signed10，域查后才收9bit；item=277×lane/slot+r 先至少13bit，再核 DENSE<4432/NMS<1108，最后进入 index32。LINE count11 表示1024完成端，既有真实 count owner 不由本卡创造第二 writer。
RTL B–F：同 core posedge，fire 为沿前 valid&&ready&&!rst；capture 沿不穿透新请求，末响应沿只记事实，后续旧状态空才发布 ready/推进。valid0不是票0；停顿保持当前完整 KEY/body/θ/r/cursor/profile，取消不撤 held。中心/邻居比较按原事务对应，局部状态数/issue数不是延迟保证。
RTL G/H/I：复位与配置沿 E1/E8；PROFILE 全调用冻结。首次全区初始化、每批 clear 与逐记录 latest 必须真实；只选一 operand 和中心寄存器，不有九票数组、免费 forwarding、完整上一批缓存或外接存储。whole-object initialized_prefix、当前 row ready 和物理可见性分别检查。K 同域无新增 CDC；生产 DDR/相机/显示跨域仍整包 OPEN。L 全机 RAM/FF/DSP/时序未完成，不由此局部证明 fit。
选定局部部分状态142bit＝四行(θ9+ready1)40＋中心21/operand21 共42＋copy_cursor9/dest2/source_lane4/centerθ9/centerρ9/neighbor_step4/suppress1/rows_done10/state5/batch5/dense_ready1/late0done1 共60。它只是本算法 worker 的具名部分，不含既有 RC RQ/RSP/完整H/profile、投影/系数/NUM、LINE count/body、关闭/失败/seq/history或 RA2352/运输；不等总 FF/XLR，也不从旧估算扣 RAM。operand 在 copy 与 neighbor 不重叠阶段复用，中心读取及 LINE 判定期间独立保持。

| 静态数量（未执行） | 真实含义与不能混用的范围 |
|---|---|
| DENSE32×728=23296 次16B零写，372736B | 32 批算法全 CLEAR。若第一实际 CLEAR 同时完成首次初始化，仅记一次；与原一次容量清账合并后新增31×728=22568写/361088B。合并的真实资格/事件仍 NS-B01；若另执行 provider INIT 必须另记费用，不能凭 prefix 免算法 CLEAR |
| NMS round64 初清184次16B写/2944B | 初始容量清账已含该一次时不能重复相加；rolling 覆写277条，不额外清整对象、不能破坏 fixed 两行 |
| 4+31×2=66行，66×277=18282条复制 | DENSE source READ_ITEM 18282、NMS WRITE_ITEM 18282；不是旧66×291 native word，也不是66个DDR事务 |
| source span21152；dest span21152 | DENSE lanes0/1各一次、14/15各32次：277条 spans各320/320/320/321。NMS rows0/1各一次、2/3各32次：320/320/321/320。按每条实际 bitpack，含跨单元记录 |
| 63456次16B data传输/1015296B | source READ21152＋dest保护READ21152＋dest WRITE21152；选朴素逐record服务、未加入共单元缓存；不含请求响应、清零、LINE及NMS比较读取 |
| 18282×59=1078638 native journal issues | 每条普通 snapshot WRITE29WE+29RE+1状态WE，共548460WE/530178RE；源 READ/clear/admin不按59，native数不等cycle或DDR拍 |
| 512×277=141824中心 | 每中心至少一次真实 READ；小于门可早退。所有合法九邻含中心的逻辑读取上界为512×3×(275×3+2×2)=1273344，非中心1131520；两ρ端少越界邻居。早退会少读，实际计事件；每21bit record至多2×16B仅几何上界 |

NMS末字节高4bit零、round16尾3B及round64再32B保持0；不把行边界当新padding。复制量和比较量不是 POINT投票/完整矩形六遍的处理时间预算。每调用的实际时间包括资格/fence、CLR、32全E投票、66复制、所有中心/实际邻居、LINE写/封存/关闭、反压；未有真实服务上界则没有成功墙钟保证，更不承诺显示60Hz等于识别fps。
跨语言三份契约：共同数值采用本中心/镜像/平票/顺序及原R3；硬件采用实际握手、mutable保护和效果；未来独立参考比较全局票数、峰集合和既定 LINE 顺序/身份，协议 checker 另核延迟/停顿/取消。C++ 标准/源码/参考/TB未生成；不得将一次软件循环当物理可见性或 RAM端口证据。

## G. 验证计划（纯场景，NOT_RUN）

| TEST | 输入/事件 / 目标 | 期望、依据及检查方法 |
|---|---|---|
| NS-T01 | 连续两batch各同一本地rho投票；E=0；首次INIT另有无 | 新批计数只来自该批，E=0全0；32 CLEAR及真实额外INIT逐事件收费，REQ01/E2/F |
| NS-T02 | θ14/15/16/17依次有高票，旧rolling读取停顿 | 判15后判16、旧引用关再覆写；全512每中心恰一次，REQ02/03/E5 |
| NS-T03 | θ0/r0与511/r276等票；(0,0)的(-1,+1)邻居 | θ0胜，邻居归一化(511,275)，不是mirror(r)+1；旧ALGO/E6/7 |
| NS-T04 | row2首项跨unit90，θ1末项非零；copy277末回复迟到 | 相邻θ1位保留，ready在末效果/引用关后的后续沿才置；PK/DIR/E3 |
| NS-T05 | 支持门等于票；邻居同票/更大；ρ0/276外域 | 门≥精确，tie用全局key，非法ρ不访问；比对独立二维NMS，不把padding当中心 |
| NS-T06 | LINE第1024/1025峰；θ0最后产生峰 | 1024完整合法、1025失败；编号按1…511,0/r升，不隐形排序，E7/REQ06 |
| NS-T07 | CLEAR/快照半途cancel，held、wrong echo、UNKNOWN及暖rst | 旧债真实兑现、部分row不ready、未知保Q/原身份，不抹旧台账，R4/RA/SC/E8 |
| NS-T08 | mutable同版本rolling覆写；尝试一行SEAL/换ref或revision | 一行不走whole SEAL；权限变更先真实fence，全行语义和O有效前缀分开，NS-B01闭合后执行 |

实施计划：先联合补R4R272/273及SC真实LINE_WORK操作/有效前缀/row gate、RA初始化和租约→完整budget/读回READY→指定版本/范围/基线及原审计许可→仅work内未来RC NMS调度/STORE动态资格/独立参考/TB→仿真→完整工程综合/P&R/STA/bit。文件名/符号在整包READY基线中冻结；本卡不生成实现或测试。

## H. 双向追踪

| REQ/来源 | MOD / IF / 中文步骤 | 拟议实现单元（未生成） | TEST/实际证据 |
|---|---|---|---|
| 01，R4R272缺每批CLEAR/RA64 | SCHED/RA，IF01/E1–2 | batch初始化与明确CLEAR事件 | T01/T07；仅文档及数量 |
| 02/05，R4R211/旧EX182–183 | COPY/SCHED，IF02/03/05/E3–5 | 四rowθ/ready、逐record复制、旧halo gate | T02/T04/T08；未实现/运行 |
| 03/04，旧ALGO163/R4R273 | COMPARE，IF03/E6–7 | 中心/邻居整数归一化与tie | T03/T05；文档走查 |
| 06，R4R273/LINE64 | SCHED，IF04/E6–8 | 顺序append/全结束seal/失败台账 | T06/T07；未实现/运行 |
| 所有，实际资源/时序要求 | 全owner，F/D及原完整预算 | 固定有限state/真实服务计数 | T01/04/08；142部分账，非全机fit |

反向：每个新增row/状态/值只支撑batch保留、NMS正确性和真实费用；未来实现/TB回指REQ/IF/E/TEST。不给原目标额外门槛；不把顺序等价误推成后续 proposal/预算等价。

## I–L. 门槛、变化、实录与交付阅读

门槛①整体/边界、②责任/复用、④局部草图、⑦验证追踪及⑩范围/来源已写；③真实许可/⑤全预算/⑥完整组合/⑧无阻塞未满足NS-B01…03；⑨需保存后实际读回及独立审阅登记。NOT_READY，不请求批准未成熟整包。依据[唯一规范§10.4](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)“默认需要用户明确批准指定版本与范围”，本卡没有实现授权。
J 变化：提出显式每batch CLEAR、四行原始票数DDR复制、局部row-last-ready、1…511,0的LINE顺序及无逐行SEAL。R4R272/273与原SC/RA/目录尚未修改或联合吸收，旧输入保持。此选择不重用旧SORTED、旧4RAM/CELL alias、假phase或免费cached row；若改theta0先出、加整表缓存/行对齐或每行version，须同步字段/费用/追踪并重审。
K 实录：本轮只有纯设计与静态几何/文档审阅，无新业务源码、可执行测试/参考/TB、EDA、bit或硬件；数据库/Manifest/正式state/task及R1输入不改。完整五基础/六高阶仍未全部软件交付。R2/Q0既有指定请求待答，不重复提问，也不据goal continuation推定获批。
L 阅读顺序：B整体时间路径→C owner→D交接/地址→E批次与镜像草图→F部分状态/实际费用→G场景→H追踪→I缺口。中文“快照”指当前四行票数的真实副本；“ready”仅本地行有效；“封存”是整个LINE实际SEAL。功能验证未运行、理解验收待用户实际检验，讲解不等已理解。
