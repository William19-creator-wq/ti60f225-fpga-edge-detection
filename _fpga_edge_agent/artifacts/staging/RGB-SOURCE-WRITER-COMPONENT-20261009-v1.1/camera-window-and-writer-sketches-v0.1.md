# CAMERA 窗口、源 writer 与 live FE 草图 v0.1

2026-10-04；TRACK4-CAMERA-001 附件；**LOCAL_DESIGN / NOT_APPROVED / NOT_READY**。本页仅设计合同、中文步骤、算术和待验证场景；没有生成 RTL、功能脚本或 testbench，没有运行功能测试、编译、综合、STA 或硬件操作。原 HDK 与工具资料保持只读。

阅读次序：§1 外部行为与交接→§2 数值及 Bayer→§3 双线窗口→§4 源 writer→§5 live FE→§6 预算及场景→§7 未闭合项。父 CAMERA 主稿负责完整任务生命周期、CSI 包判定、配置、平台及 FM 端口；本页不另建 scope/grant 版本。

来源：[CAMERA 模式/phase 证据](../01_baseline/camera-source-and-phase-evidence-v1.md)、[PLATFORM v0.1](../../../planning/design-TRACK4-PLATFORM-001.md)、[FE v1](../../../planning/design-TRACK4-FRONTEND-001.md)、[DDR-SERVICE v0.1](../../../planning/design-TRACK4-DDR-SERVICE-001.md)、[FM v0.1](../../../planning/design-TRACK4-FRAME-MANAGER-001.md)。原 v6 的 debayer_top_2to1、line_buffer、raw_to_rgb、rgb_gain_v1 已流式只读：P_DEPTH8、无 ready、依赖旧 READ_FIRST/DE 推进与 LEGACY 首行分支，输出和注释有差异；它们只作来源事实，不作新 RAW10/phase/边界/吞吐的正确性证明。

## 1. 整体行为、身份与组合

生产 W=1920、H=1080，N=WH=2,073,600 像素、D=W/2=960 pair/line、P=N/2=1,036,800 pair/frame。局部设计测试域为偶数 W∈[4,1920]、H∈[2,1080]；不支持 W2，整机 FE/Canny 调用另取各自合法尺寸的交集。不以此图尺寸域恢复已撤回的识别对象尺寸限制。

路径：CSI/CDC及包到pair适配→RAW10 双线/3×3窗口→bilinear三级算术→有限 RGB 保持槽→mandatory 源 writer；只有源 writer 实际接纳 RGB 后，才复制一份给可选 live FE 队列。DDR重读路径必须重建同一 canonical RGB，live 与重读的灰度数值因此一致。

| 交接 | 内容、接受与保证 |
|---|---|
| CW-IF01 父→局部 start/abort | 父锁定 SourceOrigin、真实 CAPTURE scope/grant、配置代次、phase、W/H及借用路由；start与首数据分沿。身份/phase不得随 CSR 或下一帧输入改变 |
| CW-IF02 适配→RAW窗口 | 复用父稿RAWPAIR114：RAW20、x_even11/y11、SOF/EOL/EOF3、bad1及scopeH68；lane0低10/lane1高10。正常 valid/ready 接纳一次；CA2先保存真实开始/结束资格，行末pair等真实EOL、末行再等真实EOF才提出完整body；包适配不向 CSI 提供 ready |
| CW-IF03 窗口→算术 | 两个3×3窗口共180bit，每lane9个 unsigned10，行优先 a…i；lane0低90bit、lane1高90bit，a为该lane最低10bit。中心坐标/标志共同保持 |
| CW-IF04 算术→源 writer | 复用父稿RGB142：canonical RGB48、coords22、markers3、bad1及scopeH68；RGB valid/ready 的真实 fire 是源 writer 计数和 FE 复制的唯一事件。正常bad0，坏输入锁定失败；不能把bad1省略成未传字段 |
| CW-IF05 源 writer↔DDR | 使用 DS-IF02…06 原有 prepare/permit/req/W/terminal/release/ACK/seal/fence；client0 CAPTURE，仅写 region4 RGB_SOURCE 的真实已授范围 |
| CW-IF06 父→FE FJ-01 | 原 FE job110：三ID96、median1、kind2、threshold11；不添加相机尺寸字段到原 FJ。FE 尺寸由其实际设计参数和上层相容检查处理 |
| CW-IF07 live队列→FE FP-01 | 完整 payload74：RGB48+coords22+SOF/EOL/EOF3+in_bad1；valid/ready是握手线，不计入payload。FEjob身份引用锁定ctx，不逐项改写 |
| CW-IF08 局部→父证据 | 各自独立保存窗口/流数量及关闭、writer封口/局部terminal、真实FE FS及支路关闭；父另汇合源判定/DDR fence，不让通知ready阻塞旧排空 |

每个局部引擎同一时刻一个锁定输入上下文。旧 pending、RGB、FE队列、FJ/FS、writer 段或局部 terminal 尚未结清时不覆盖其 ctx。SourceOrigin195和跨 CAPTURE/PROCESS 同源比较沿用 DDR正文；不要求两个不同用途 scope 的完整 J486 相等，也不以frame_id或槽号替代代次。是否允许下一帧提前接纳及父绑定容量仍由父稿/期限证明决定。

非法输入实际握手先计入已接纳数，再锁错误；坏pair不进入窗口。不由本沿坏数据反馈组合地抹去其 ready/fire。独立 abort 可禁止新接纳；旧真实 DDR/FE/输出事件仍按各自合同计入。窗口局部 OK、FE OK、writer局部 OK 均不是源 COMPLETE。

**CA2上游迟到边界合同。** 行末x=W−2的完整pair从原record移入独立114bit end_pair holding，等待同scope/row的真实EOL；末行还须真实EOF。等待资格期间不提出其RAWPAIR valid，不能先交无末标志的pair、再修改一个已held或已交付body。EOL/EOF允许位于后续payload_valid0的NORM控制记录；end_pair不能继续占住原record并阻塞读取这些记录。CA2继续以有界192bit record holding接收/解析控制；正常EOL数量W、odd为空、SOF/SOL开始资格及末行EOF全部核验后，才附末标志、提出不可变114bit body，直到CA3实际fire。旧行未关时的新行payload是协议错误；已关旧行但end_pair仍未交付时，也只能在实际有限record holding内保存后续记录，不覆盖end_pair或跨行重排。缺失/错身份边界走父独立abort，不按像素计数伪造EOL/EOF；旧holding及pending按消费水位/身份关闭。

## 2. Bayer、边界与整数数值

### CW-N01 四 phase 与 bilinear

phase2 是锁定帧配置，候选编码如下；真实模组读出相位仍需来源/实物确认，不默认把0或旧 LEGACY 当真相。

| phase | y偶：x偶/x奇 | y奇：x偶/x奇 |
|---|---|---|
| 0 RGGB | R / G_R | G_B / B |
| 1 GRBG | G_R / R | B / G_B |
| 2 GBRG | G_B / B | R / G_R |
| 3 BGGR | B / G_B | G_R / R |

G_R的左右邻点为R，G_B的左右邻点为B。每个窗口用其**输出中心**的 x/y 奇偶及phase选颜色：R/B中心本色取中心、G取四正交邻点、另一色取四对角邻点；G中心保留G，R/B按上表取两水平或两垂直邻点。两lane分别处理，不把一个整组 RAW20 当signed值。原 gain/gamma 不隐式带入本数值合同；是否加入新显式增益/黑电平配置由父稿另定。

### CW-N02 reflect101 与单轮舍入

RAW读取坐标映射：x=-1→1、x=W→W-2；y=-1→1、y=H→H-2，其余保持图内原坐标。映射保留虚拟邻点的奇偶及CFA颜色；不裁去首末行列。首输出行取(top,mid,bot)=(row1,row0,row1)，末行取(H-2,H-1,H-2)。普通灰度的clamp复制不能直接用于RAW Bayer：纯红图的红角点会把红样本放进缺失绿邻点。

每分量的样本数 d∈{1,2,4}、样本和 S，最终 **RGB8=min(255,floor((S+2d)/(4d)))**；只在缩至8bit时舍入一次，不先圆整RAW10均值再圆整到8bit。

| d | S最大值 | 加偏置最大值/最小所需宽度 | 最终取整 |
|---|---|---|---|
| 1 | 1023 | 1025 / unsigned11 | 加2后右移2 |
| 2 | 2046 | 2050 / unsigned12 | 加4后右移3 |
| 4 | 4092 | 4100 / unsigned13 | 加8后右移4 |

所有加法先零扩；A1可统一存unsigned12的六个和，A2统一扩unsigned13加偏置后取unsigned9结果0…256；A3将256饱和255后缩为8bit。全RAW常数c产生三个同值分量；c=2输出1。两邻样本0/3的缺失分量输出0，双轮舍入会1，应作为明确差异场景。

canonical RGB48固定为 **{R1,G1,B1,R0,G0,B0}**：R0[23:16]、G0[15:8]、B0[7:0]，R1[47:40]、G1[39:32]、B1[31:24]。DDR连续字节另为 **R0,G0,B0,R1,G1,B1**；二者必须由明确字节选择重排，不能将canonical 48bit直接当little-endian DDR字节向量。例R0/G0/B0=11/22/33、R1/G1/B1=44/55/66（hex）：canonical=445566112233，DDR依次11 22 33 44 55 66。旧 Debayer 的{B,G,R}及旧HDMI bypass R/B交换只记来源事实。

## 3. 双线窗口、pending与尾排空

### CW-W01 物理组织与接纳

recent/older各D×20bit；每行两个native20×512 RAM10组成1024地址，q10、page=q[9]、本页addr=q[8:0]。生产960…1023不访问。共4 RAM10，有效38400bit、物理40960bit；不清RAM阵列，不依同址READ_FIRST。每条stripe WE=11整20bit，OUTPUT_REG=0，RCLK/WCLK均core100；这些模式来源与实际工具映射分别记录。

发起阶段候选IDLE→REAL→REPLAY→TAIL→WAIT_DRAIN；pending_kind另记FILL/REAL/REPLAY，不能以当前发起阶段猜旧pending是否要WE。row0为FILL，只延迟写recent；row1忽略未初始化older，其垂直三行取(current,recent,current)；row≥2取(older,recent,current)。REPLAY取(older,recent,older)，不创建新写，但其发起沿仍可提交旧REAL的末写。

每沿至多一个RAW接纳/读事件、一个旧pending捕获与延迟写；recent和older各有一个读口、一个写口，page命中由各自保存的地址决定。两个60bit垂直holding按顺序输出，每次RE先指定slot并预留，valid+reserved≤2。pending保存q/y/page/kind/当前RAW20/目标slot及锁定ctx引用。FILL有自己的20bit pending，不发布垂直token。旧pending可捕获并让出资格的同沿允许下一发起。

### CW-W02 逐沿读写及反压

**eK发RE，RAM输出在eK后稳定；eK+1沿前RDATA是此次读回。** eK+1同时：将这些旧RDATA采入已预留的垂直slot；以沿前当前RAW pending写recent[q]，以沿前旧recent RDATA写older[q]（FILL不写older）。**不能用eK+1才形成的新capture寄存器值作为该沿WE数据。** 若选择再晚一沿写，必须重新核所有地址、预留及逐沿表，不能静默混用。

持续流中同沿RE q+1/WE q，跨行RE0/WE D-1；D≥2所以同一物理RAM若读写都使能，地址不同。q511→512时capture仍选pending旧page，不选新的RE page。已RE的capture和旧延迟写具有预留目的地，后级stall不能遗失它们；两个holding占满且本沿无可消费项时停止新RE/新输入。水平模块仅在其窗口输出槽空或本沿实际被算术接纳时消费旧垂直token，不能读取刚在该沿capture的新值。

### CW-W03 水平历史、跨行与EOF

L/C0/C1为三个垂直列，每列3×10bit，共90bit，另存其输出行/中心pair索引与valid。首q0不输出窗口，设置C0=新首列、C1=新第二列、L=新C1（左reflect）。同一行q≥1：lane0用旧L/C0/C1，lane1用旧C0/C1及新首列；输出中心是旧pair，随后L=旧C1、C0/C1=新两列。

新输出行q0到达：旧历史先形成上一行最后pair，lane0仍L/C0/C1，lane1右列取旧C0（右reflect）；再按新q0初始化下一行历史。两件事同沿提交但归属不同输出行。末帧TAIL不读RAM、不接外部像素，只按同一右reflect形成最终末pair并清历史有效位。SOF/EOL/EOF从窗口中心坐标生成，不沿用当前读入行的标志。

合法输入EOF后不再接真实RAW；必须重读末两行D次形成最后完整输出行，再消费最终TAIL。各slot/pending/carry与A1/A2/A3/RGB输出共同结清，输出P且末EOF实际交付后，至少下一沿确认empty才形成窗口/流局部OK。不能用输入EOF或开始时全empty成功。

### CW-W04 三级算术与无停顿示例

A1形成六个样本和及d选择，A2扩宽偏置/固定右移，A3饱和并写两个RGB保持槽之一。算术以输出容量决定整体推进，valid/中心/标志共同保持；空输入插气泡，输入valid0不妨碍旧流水及TAIL排空。两个RGB槽是有限FF，按pair_index顺序交付，不覆盖held项。

下面采用“capture到垂直holding后最早下一沿给水平”的明确候选；e0接首完整RAWPAIR114，输入每沿一pair、所有下游就绪。**这是CA3边界的无停顿条件例：每个114bit输入已经带真实、核验且固定的SOF/EOL/EOF资格，CA2迟到control等待已完成。** e(P−1)表示CA3实际接受完整末pair/EOF的沿，不是CSI最后data到达沿。真实EOL/EOF后到或CA2/end_pair停顿必须插入相应气泡，不能套此沿号宣称PHY/CSI实测延迟，也不能依本表从计数生成末flag。

| 沿 | 接纳/RE/旧WE | 水平/算术及输出 |
|---|---|---|
| e0 | FILL row0/q0，保存RAW pending | 无窗口 |
| e1 | 写recent row0/q0，FILL q1 | 无窗口 |
| eD | 写row0末q；REAL row1/q0 RE | 无窗口，RE0/WE D-1不同址 |
| e(D+1) | capture row1/q0并延迟写；RE row1/q1 | 首垂直holding有效 |
| e(D+2) | capture q1；可发下一RE | 水平消费旧q0，建立首行历史 |
| e(D+3) | 继续 | 消费q1，首窗口row0/q0在沿后有效 |
| e(D+4…6) | 继续 | A1、A2、A3依次提交；首RGB沿后有效 |
| e(D+7) | 继续 | 源writer最早实际接纳首RGB；FE复制同一次fire |
| e(P-1) | 接真实末RAW/EOF、REAL末q RE | 不能关闭旧pending |
| eP | capture末REAL/WE，REPLAY q0 RE | 末行重读与旧延迟写并存 |
| e(P+D-1) | 最后REPLAY RE | 后续capture/水平仍在途 |
| e(P+D+2) | 最终TAIL，无新RE/外部输入 | 最后一组窗口沿后有效 |
| e(P+D+6) | 无新真实RAW | 源writer最早实际接纳最后RGB/EOF |

按这个候选，首尾RGB fire之间恰P组；气泡、反压、包事件及frame间隔会改变沿号但不能改变正常总数。普通取消/坏输入停止新窗口发起；已RE的pending仍按旧ctx捕获至DISCARD并归还预留，不重新置正常valid。源writer已经取得的副本与DDR保持域继续独立结账。未知物理排空服从平台PREPARE/FINAL，不以清本地valid替代。

## 4. RGB源 writer：字节打包、完整段与回收

### CW-S01 两bank/64bit word及append

四条native20×512 RAM10并行组成80bit word，payload低64、高16固定0。bank0 word地址0…127，bank1地址128…255；256…511不访问。每bank128个64bit word=1024B**payload**、1280B存储容器；4RAM物理40960bit，不能把payload大小当原语占用。每bank元数据含状态、源ctx、全局byte起点、真实/物理字节数、已写word数、segment游标和借用计数，均另算FF。

输入按canonical字段抽出6字节R0/G0/B0/R1/G1/B1，按DDR地址递增顺序append。carry记录未写的≤7字节及其流byte位置，carry_count3先扩4bit再加6，sum_count4最大13；112bit临时容器可装旧carry+6B≤13B。一次正常pair fire最多产生一次64bit WE：不足8B只保存carry；达到8B写最低8B，余数继续carry。未fire不append、不复制FE、不计pair。正常6B输入可达carry0/2/4/6，但按≤7作有界合同。

in_ready必须先确认本沿可能产生的64WE目的地可写；无可写bank时，不接受一个会需要WE的pair。写满第128word则seal旧bank，残余carry仍属于本帧后续字节，不能丢弃或塞成旧bank第129word。FREE→FILL→SEALED→DRAIN→RETURN_PENDING→FREE，回收至少下一沿供新写；SEALED后的数据/长度/ctx不可修改。一个bank读旧sealed段、另一bankappend可并行，各stripe一个RE和一个WE且地址不同；不假设两个读用途同沿获得一个读口。

### CW-S02 EOF、padding与地址分段

L=3WH，A=16ceil(L/16)；grant的logical/physical范围依DDR正文，不能以L允许整拍越界。合法最后RGB/EOF先执行其真实append，再关闭RGB输入：carry非空在后续沿提交尾64word，高位补零；若最后物理word数为奇数，再提交一个完整零64word，使A覆盖的16B完整拍备齐。carry空且物理word数为偶数不写dummy。EOF恰满bank且没有后续carry/padding，不开空bank、不发零长请求。已有满bank不可被EOF尾流程覆盖。

生产L=A=6,220,800B，恰6075个1024B满bank载荷，尾无padding；局部W4/H2有L24/A32，第三word为真实8B，第四word补8B零。padding最多A-L≤15B，只有A范围有访问权，页分配余量不是writer权限。

每个SEALED bank全部物理word已在不可变RAM中存在，才能提出其prepare/req；不必额外复制整1KiB寄存器。段选择使用unsigned33末端核验：16B对齐、1≤nbeats≤64、段≤1024B、不跨4KiB、落入真实grant物理范围。bank若跨4KiB最多拆两段；只有当前段独占client0/W record，下一段等当前terminal、local借用关闭及RELEASED ACK消费之后才prepare。示例byte起点0x0FF0、bank1024B：先1拍至0x1000，再63拍；起点0x0C00则64拍恰到0x1000，不能再加一拍。实际源base通常页对齐，仍检查而不由本地bank地址推断。

prepare/permit/req266、tag16、phase2、receipt_seq64、完整terminal301/release288/ACK沿用当前DDR稿；不自造物理ID或新的scope。W最早req_fire之后提出。服务先COLLECT完整逻辑段，且满足其物理首min(2,n)预取条件后才AW；客户端“源数据备齐”不等于物理AW已接受或写成功。

### CW-S03 同步组拍、双holding与借用

两个128bit W保持槽，各有固定segment/tag/seq、beat_index、last、valid及两个64bit half的reserved/captured标志。开始第一half的RE前先预留整个目标槽；槽valid或有half预留均算占用，最多两槽。每stripe每沿最多一个RE，全局read pending一个，保存bank/word/slot/half/beat_index/ctx/借用；不以当前调度owner猜旧capture。

段内第j拍读bank_base_word+segment_byte_offset/8+2j及其下一word；segment_byte_offset是该段在本bank内的16B对齐偏移，bank_base_word为0或128。先RE低地址word，下一沿preedge capture低64；可同沿RE下一word，再下一沿capture高64后该槽在沿后才有效。跨4KiB后段不能重新从bank word0读：0x0FF0示例第二段从本bank word2开始，最后一拍读word126/127。W data[63:0]是低地址word，data[127:64]是下一word；last仅j=nbeats-1。例如eR首half RE，e(R+1)低capture/第二half RE，e(R+2)高capture，e(R+3)最早W fire。充分预留时e(R+2)还能发下一拍低half RE，因此条件上可每2沿形成一拍；W严格beat_index有序。满槽停止新RE，既有pending仍捕获，stall不覆盖或反复交付旧W。

源bank保持不可变。正常回收须本bank所有计划段均已提出并得到成功terminal及RELEASED ACK消费，且本地RE/capture/half/W保持借用结清；只发送release或只见末W/B不能FREE。release的local_drained1要求本段assembler/pending/held借用为零，**不要求仍分配的源bank先FREE**，避免等待ACK的循环。正常部分段结清后继续读同bank后段，不把“当前已提出段都结束”当整bank正常完成。失败/取消可将尚未提出后段标为作废，已提出段结账且本地借用关闭后安全丢弃整bank。

显式cancel/早失败时：未提出后段可作废，不等待它们得到不存在的terminal。已提出的prepare/permit/req及物理proposed规则按DDR正文兑现，terminal kind1/2的握手共同作废未接受held W；之前保持其旧payload，不自行撤valid。terminal_fire同沿或之后旧pending capture进入DISCARD，归还预留而不复活Wvalid。kind3仅隔离通知，不能释放bank/scope；独立平台恢复证据才处置旧借用。错误应及时消费独立terminal，不能因Wready为0或bank未FREE而不接终态。

### CW-S04 封口、局部终态与父fence

正常顺序：最后RGB/EOF真实接纳→carry/零padding全部写完→最后bank seal→全部应有segment prepare/req真实交付、未提出permit已归还→保存“不会再prepare/req”的封口证据→父发阶段seal/fence并独立等待→各段terminal/release ACK及本地借用结清→writer local_terminal→父汇合源判定、local_terminal与成功fence→源COMPLETE。已受理段的W/B排空可与父fence等待重叠。

writer local_terminal只证明P个RGB/EOF、L/A字节账本、请求/逻辑W及响应和本地排空；**它不等待父fence返回**。封口证据及local_terminal各自有独立有限保持槽，不能让父等writer、writer又等需其封口才能提出的fence。各计数只按实际fire累加；word_count8可表0…128、word_index7表0…127、beat_count7可表0…64、bytecount/地址32先扩33检查。bad EOF/缺EOF、early error/取消不等完整图，形成失败/取消关闭证据，结清已经提出段后保存失败drained终态；未知排空保持隔离。

## 5. live FE：完整74bit队列及非阻塞采集

### CW-F01 有限存储与实际FE端口

原FE FJ-01 payload110=三ID96+median1+kind2+threshold11；FP-01 payload73=RGB48+coords22+markers3，**加in_bad1后完整payload为74bit**。本附件队列采用512×80，四条native20×512，低74有效、高6零；不是73bit少存bad。正常RGB项的in_bad=0；晚到源错误不回写历史entry，走独立整支abort。父若提供与真实pair对应的bad1必须按字段保存，不将它丢弃为0。entry引用一个锁定PROCESS/FE ctx，ctx含FJ三ID/配置及同源绑定，不能由当前CAPTURE的部分字段临时猜FE job。

队列addr9、读写wrap指针各10、count10可表0…512；均core100，不创建额外CDC。两个74bit读holding及一个RE pending先预留目标slot，valid+reserved≤2，RE沿后RAM输出稳定、下一沿preedge capture。队列head在RE后转成holding所有权；父关闭时必须同时计queued、pending、holding、已提出FJ/FP及真实FS，不能只见RAM指针相等就说empty。

### CW-F02 复制、溢出和FE终结

mandatory源writer fire是复制事件：只有该沿已接纳RGB，且本帧live支路enabled、旧queued_count<512时才WE一份74bit。旧FIFO full时即使同沿RE移出head也不作WE旁路，因为旧读写地址相同，会依赖未证明的同址结果；该候选仍按overflow关闭FE支路。欲复用这一个credit须另设延期写槽、预留及身份合同，不在本版隐加。queued_count=0不发RE，1…511时同沿RE/WE地址不同。writer stall时RGB及sideband保持，不因每沿valid高重复入FE。源writer的ready不与FE ready/队满组合相与。

若本次writer fire时live队满，锁定支路OVERFLOW/已复制及已FP接受前缀，关闭本帧FE复制并取消整FE任务，mandatory采集继续。已有队列/pending/holding按授权取消关闭，不把漏项转成正常EOF或成功。即使FE变IDLE，也不在同一帧中段重新arm；下一完整SOF是否有新FE任务由父重新决策。普通算法跳帧、live容量失败、capture/source失败分别记录。

FJ已提出未接受必须保持；FE在IDLE忽略cancel，因此必须让旧FJ结清接受，再在后续ACTIVE沿提交cancel，不能只在FJ接受沿打一拍cancel。只有旧FJ已接受的后续沿且FP数据可用时才实际FP交付；同沿新FJ和首FP不交付。FE真实FS独立及时保存，其ready不依writer/fence/队列空；FS已形成后不回写code/count。后来源无效由父撤发布资格，不伪造另一FS。

正常FE支路必须FP恰P、完整标志、真实FS OK及队列/pending/holding关闭，另等父同源合法/全部算法fence才可发布。局部H2等FE非法尺寸仅用于CAMERA独立测试，不启动FE；生产1920×1080由FE参数及父绑定核验。FE只读输入副本，不能因它取消而释放源writer正在使用的CAPTURE bank/permit。

## 6. 有限资源、期限与待验证场景

| 新CAMERA存储 | RAM10及明确范围 |
|---|---|
| 配置ROM | 1块候选；配置表/布局/是否复用原ROM由父稿冻结，本页不生成ROM内容 |
| RAW recent/older | 4块20×512，两个1024×20行容器，生产各960有效pair |
| 源writer | 4块20×512并行80bit；两bank各128×64 payload，高16零，unused256…511不访问 |
| live FE FIFO | 4块20×512并行80bit；512项、74有效bit、高6零 |
| CAMERA新增小计 | 13RAM10；不再加PLATFORM已列20块CAMERA-PIXEL CDC |
| 全部已列候选 | 149+13=162/256=63.28125%；不是综合通过或全机完整资源 |

已数窗口核心数据寄存器632bit：RAW pending20、双垂直holding120、水平历史90、双窗口180、A1和72、A2结果54、双RGB槽96；坐标/phase选择/valid/reserved/控制与完整ctx另计。writer另有112bit append暂存、双128W槽256bit及bank/half/pending元数据；FE双74holding至少148bit及控制/完整FJ110另计。完整XLR、组合加法/选择及STA预算未闭合，不把这些payload位数冒充综合FF统计。

CA2属于上述632bit窗口核心之外：主稿已显式两个192bit NORM record holding、一个独立114bit end_pair及一个10bit odd样本，三项数据至少384+114+10=508bit FF。read pending/预留、pair发射游标、odd身份与开始/末边界资格、held输出sideband、scope/link/消费水位及计数另计；不将508当CA2完整FF或新增RAM，不暗中借用CA3垂直holding来等待控制记录。

2pixel×100MHz=200Mpixel/s峰值，RGB源数据峰值600MB/s；1080p源每帧6,220,800B。4pixel×50MHz也为200Mpixel/s，但包事件、窗口/EOF尾、writer读口、DDR停顿均会造成积压。PLATFORM外部1024 record FIFO最多4096像素，对应20.48µs消费量；live512pair FIFO对应1024像素、5.12µs消费量，均只是容量换算。未证真实CSI/DDR/FE最坏停顿及下一SOF前关闭期限；不能把源writer条件2沿/beat或平均带宽当稳定采集证明。

| 场景 | 可检查期望；全部NOT_RUN |
|---|---|
| CW-T01 四phase纯R/G/B、彩条及全RAW常量 | 首点/内点/四角颜色按显式CFA；reflect101无clamp串色；canonical/DDR字节逐项核对 |
| CW-T02 单轮舍入0/3、边界1023和偏置 | 中间扩宽正确，9bit256饱和255；不混双轮参考 |
| CW-T03 W4/H2与生产1920×1080 | 完整W/H，不裁边；P输入/P窗口/P RGB，最后EOF只一次；局部H2不启动FE |
| CW-T04 RE后stall、page511/512、跨行RE0/WE末q | capture和WE取preedge RDATA及pending旧page，同址禁止，holding≤2，无丢重 |
| CW-T05 REAL末写与REPLAY同沿、最终TAIL、无新valid | 旧写照pending_kind结清，最后行reflect重读、不等新像素排空 |
| CW-T06 canonical字段与6B→8B carry、满bank跨pair | 字节顺序R0/G0/B0/R1/G1/B1；carry不丢，≤1正常WE/pair，无第129word |
| CW-T07 EOF carry、奇数word补零、完整bankEOF | L/A区分、≤15B padding；没有空bank/零请求或读未初始化word |
| CW-T08 0x0FF0 1+63拍、0x0C00 64拍 | 每段16对齐/≤64/不跨4KiB，header稳定，33bit端点不溢出 |
| CW-T09 双W槽满、half RE后失败terminal、release ACK停顿 | 具体槽预留，capture DISCARD不复活held，bank不因release提出而回收，未提出后段不自锁 |
| CW-T10 FE旧full同沿RE/新RGB、queued/pending/holding满与FJ同沿overflow | 完整74bit；旧full不WE同址，源采集继续；旧FJ后续ACTIVE取消，FS真实独立保存，支路失败不冒充OK |
| CW-T11 源错/缺EOF/晚源错/暖reset/未知DDR效果 | 不等不存在EOF；旧源writer义务保留，晚错拒发布；未知效果维持Q及平台恢复 |
| CW-T12 行末data后到control-only EOL/EOF、末pair持有及CA3 stall | CA2独立114bit end_pair等真实边界才valid，控制读取不被它堵住；真实末flag同payload固定，缺/错边界独立abort，不计数伪造；CA3示例沿号相应推迟 |

追踪：CW-IF02/03→CW-N/W及CA2迟到边界合同→T01…05/12；CW-IF04/05→CW-S→T06…09/11；CW-IF06/07→CW-F→T10/11；CW-IF01/08→身份、local_terminal/父fence及所有关闭场景。未来代码/测试位置由获批主稿指定，本页没有暗示这些文件存在。

## 7. 当前BLOCKING与恢复阅读

- CW-B01：真实模组phase/裁剪mirror顺序、RAW lane/ppc及包到pair前提、迟到EOL/EOF与CA2 end_pair/控制记录有界交接、完整配置/增益/黑电平决策未闭合；来源猜测不是颜色证明。主稿CA2合同是设计要求，不是actual IP已满足证据。
- CW-B02：native20×512各用途映射、双线/FE队列1R1W、page mux及100MHz算术/反馈时序未实测。
- CW-B03：writer prepare/req/terminal/release/封口证据与父CAMERA/FM真实端口、cancel/恢复保持域、独立证据容量尚待组合吸收；本页沿用当前DDR合同，不修改邻稿。
- CW-B04：源writer条件吞吐、mandatory与live支路最坏积压、真实CSI/DDR期限及下一SOF前容量证明缺失，溢出处理不代替稳定吞吐验收。
- CW-B05：全机FF/XLR、RAM片段、DSP/PLL及所有FIFO/bank同时占用未有真实工具报告，162仅已列小计。

恢复先读本页及当前父CAMERA/FE/DDR/PLATFORM实际版本与批准证据；位序、边界、舍入、pending/WE时序、bank/队列容量或接口变化均先修订设计并复审。保存/读回/hash属于文档证据，不能升级为功能测试或READY。
