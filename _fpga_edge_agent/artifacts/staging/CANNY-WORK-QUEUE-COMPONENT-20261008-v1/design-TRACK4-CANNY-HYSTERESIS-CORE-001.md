# TRACK4-CANNY-HYSTERESIS-CORE-001 v1：精确八邻域核心

## 通用计划与授权（2026-10-08）

Goal：补齐T4-A4尚无代码的强/弱图八邻域闭包核心，不把前级双阈值当完整Canny。
Current state：R2已交付Gaussian/梯度/方向/NMS/分类；cache/外存queue和生产DDR仍未实现。本单元独立控制算法，复用原Canny设计的精确连接数学和N容量队列。
Target state：分类图服务和FIFO队列服务具有下述合同后，核心输出完整N个边缘及终态；没有固定轮次截断。
Gap：实际cache、DDR服务、帧身份完整adapter、与R2交接/性能仍随后整合；TB服务只是行为模型。
Assumptions：静态W偶数6…1920、H5…1080，N=W×H；单任务、同clock、可以反压。64bit实验job_id用于独立匹配，生产完整job另需adapter保持，不能截完整身份使用。
Open questions：本单元合同无未知；DDR器件/生产clock不纳入本单元正确性前提。
Dependencies：Canny v0.4 CN01/06/07、memory草图v0.3 SC-M02/queue数学、R2已完成分类数值、规范v0.2。
Milestones/Detailed steps：整体→服务接口→状态/中文草图→RTL/独立BFS→小图协议与1080p验证→后续cache/整机。
State transitions/approval：保存读回/READY后按用户“当你统計完后自行进行, 无需我的批准”直接实施；沿用本地审计，不再请求逐模块批准。
Artifacts：work/active/track4_algorithms_20261004/hysteresis_core；新run与SHA清单、实际覆盖报告；原Canny大稿/HDK不改。
Validation：HY-T01…08；仿真服务不声称实际DDR通过。
Failure handling：错误/取消停止新服务操作；已提出请求保持并收真实终结；不输出成功完整图，调用方作废已输出前缀。
Human hardware gates：不下载/烧写，不改数据库/正式状态，不安装或访问网络。
Rollback：保留失败run；只改本独立work单元。
Completion：精确算法和协议证明；生产存储/时序/FPS未完成时明确标注。

## A—C 整体外部行为与职责

HY01：输入分类0=NONE、1=WEAK、2=STRONG，服务内部3=CLAIMED。遍历全部强种子，再FIFO遍历八邻域，最终edge恰为强种子在强/弱图中的可达集合。初始外框由R2为0，本算法即使边界有候选也只访问画面内坐标，独立数学不要求强制清框。
HY02：每候选最多claim/入队一次，queue容量N，enqueue_count≤N，pop_count≤enqueue_count；strong遍历后不会残留2。
HY03：同一job只接一次，尺寸静态。全部成功时输出按i=0…N−1的N个边缘像素及同64bit实验ID；无强边全0，弱链不限制长度。
HY04：可暂停服务/输出，正文/索引保持；异步系统不直接连此同clock接口。cancel同ID止新增请求，错误与取消不覆盖已经held终态。
HY05：独立参考用Python deque泛洪、无需RTL队列/状态组织；逐像素和队列账、反压/取消/复位真实比较。

核心只拥有索引、seed/neighbor/export状态、计数及一个操作；分类服务唯一拥有2bit图/atomic claim，queue服务唯一拥有N深FIFO。两服务真实硬件实现待后续。数据路径：job→全部CLAIM_STRONG→push→pop→八个CLAIM_WEAK/push→queue逻辑空→逐点READ_STATE/输出→成功终态。状态3在claim响应以前写入完成，因此后续重复邻居不会再次claim。

## D 服务接口与组合检查

所有valid/ready同clk沿，fire=沿前valid&&ready；提出后整个body不可变至fire。至多一个分类或queue操作 live，不并发；服务回复保持至核心ready，回复只在真实操作完成且写可见/承诺已排空后给出。err=1仍代表该操作已安全终结，未知排空时不得回复，父端另行隔离。这个合同不能自动当DDR原IP事实。

IF-HY01：job_valid/ready、job_id64；cancel_valid/cancel_id64；rst高同步须共同复位核心和两服务，暖单端reset禁止。终态done_valid/ready、done_job_id64、outcome2（0成功/1失败/2取消）、reason8（0正常/1分类协议/2queue协议/3服务错误）、enqueue_count22/pop_count22/output_count22，提出后保持。
IF-HY02：state_req_valid/ready，op2（0READ、1CLAIM_STRONG、2CLAIM_WEAK），index21<N；state_rsp_valid/ready，old_state2、claimed1、error1。CLAIM_STRONG仅旧2时原子改3/claimed1；CLAIM_WEAK仅旧1时改3/claimed1；READ不改且claimed0。核心逐项核claimed与old一致，强扫描看到初始3失败，弱扫描看到残2失败。
IF-HY03：queue_req_valid/ready，push1（1push、0pop），index21（pop规范0）；queue_rsp_valid/ready，index21（push回原索引、pop回FIFO最早索引）、error1。服务事先在job初始化为空/N容量；核心本地tail/pop_count决定何时pop，不发送空pop。每claim成功后push终结才算enqueue；push失败使整任务失败，不能发布不完整图。
IF-HY04：pixel_valid/ready、index21、edge1、job_id64。输出公开后保持；取消仍须消费已公开一像素再终结，父writer取消须提供排空ready并作废前缀。done成功仅所有N输出fire之后；完成不是父DDR输出fence或显示发布。

分类/queue由调用方独占到done消费，其他writer不得修改该job图。job_ready仅IDLE，已held done不接新job。job与同IDcancel同沿接纳后直接取消，不发服务。错误优先于在该响应沿检测的cancel；held结果不改变。无超时伪成功。
N≤2073600，index21、N计数22；邻居先验证x/y边界，随后形成索引，不把跨行+1误当右邻居。64bit实验ID仅用于独立端到端测试，生产父合同必须适配完整身份。

## E 局部中文语句草图

先声明phase(SEED/BFS/EXPORT)、current_index/seed_index/export_index、neighbor3、queue计数和请求锁存，再定义状态IDLE/SEED_NEXT/POP_NEXT/DIVIDE/COORD/NEXT_NEIGHBOR/STATE_REQUEST/STATE_WAIT/QUEUE_REQUEST/QUEUE_WAIT/PIXEL_HELD/DONE_HELD。
时序先处理共同reset；非reset先锁matching_cancel，不改正在公开的请求。新任务锁ID/清计数，SEED_NEXT向分类服务提CLAIM_STRONG。请求只有一个owner/purpose，STATE_REQUEST在fire后进WAIT；WAIT只在真实rsp fire推进，核error/claimed后strong成功进入push，其他合法状态推进seed。每个seed恰一次，末seed成功push也必须先收ack再开始BFS。
POP_NEXT若pop_count==enqueue_count转EXPORT；否则发FIFO pop。回复核index并增加pop_count，用21次移位减法把线性i除以常数W得到y/余数x，避免综合出宽组合除法器；最后一沿写商/余数，下一COORD才读。neighbor顺序(-1,-1),(0,-1),(1,-1),(-1,0),(1,0),(-1,1),(0,1),(1,1)。边界检查后用i±W±1，不另乘y×W。
NEXT_NEIGHBOR合法时CLAIM_WEAK，成功后push同索引，ack再推进neighbor；不成功直接下一邻居。第8个完成才返回POP_NEXT。队列只存21bit索引，生产外部queue按32bit条目，分类cache仍2bit，不改原17.5MB逻辑工作集为每点32bit分类。
EXPORT每i发READ_STATE；只接受0/1/3，2说明seed阶段不完整而失败。edge=(old_state==3)，将index/edge保存在一个输出槽。PIXEL_HELD等待fire，count++后下一个；末点fire才SUCCESS。此顺序不能将done早于最后像素。
取消在未提出新请求的计算状态直接形成取消；REQUEST即使尚未fire也保持，必须收ack再取消；WAIT须终结；PIXEL_HELD不得撤回，fire后取消；DONE_HELD忽略后来的cancel。reset作废在途必须父服务共同清空，不能拿同步reset证明物理DDR已排空。

## F 数值/语言/资源

SystemVerilog/同上升沿；无生成时钟/功能delay。索引算术signed23先扩展，边界坐标signed13；移位除法rem12/full_trial13、商21，21次有限迭代。N/计数用22bit，append前若count>=N失败；不回绕。TB在沿后观察输出，服务在沿前准备valid/ready。
核心无图像RAM/DSP，估计小量FF/比较加减；准确资源和clock只有实际综合/PNR后填写。存储所需原N深queue和状态cache不会因接口抽象消失，真实硬件预算由服务另闭合。该逐节点基线先证明精确性，缓存/邻居合并及坐标换算优化随后比较，不预称达成FPS。
Python数学模型和实际RTL流按job/index对应，完整输出逐位比较；任务取消/失败允许前缀但不计成功。保持、请求数、写可见、重复入队和队列容量另由动态服务TB与审计证明。

## G—H 验证及追踪

HY-T01：无种子、全强、孤立弱、长蛇链、环/分支/对角、跨行伪邻居、四边角；独立BFS逐点相等。HY-T02：固定seed随机小图，所有索引/队列FIFO/claimed唯一性守卫。
HY-T03：分类/queue请求及回复、像素/终态随机停顿，公开正文保持。HY-T04：计算、未接请求、待响应、待pixel/终态的同ID/错ID取消；已承诺必须终结。
HY-T05：非法初始3、残strong、claim标记错误、queue越界/错push回显、服务err；无成功终态。HY-T06：各主要阶段共同reset与不同job重新初始化，旧任务不输出伪完成。HY-T07：完整1080p全无种子、长链/有种子图，记录实际周期/请求量；未运行时明确NOT_RUN。HY-T08：综合、生产服务适配、R2整合、STA/bit另逐步执行，不假称本批已覆盖。
HY01/02→核心seed/pop/neighbor→rtl/hysteresis_core.sv→T01/02/07；HY03/04→锁存/输出/取消→T03…06；HY05→model/hysteresis_reference.py、tb/tb_hysteresis_core.sv、runner/实际日志→所有审核；code反向只对应这些合同。后续图cache/queue是明确待实现，不用TB行为替代硬件。

## I—L 自检与交付

整体/职责/接口/局部/语言/组合/验证/追踪/无单元阻塞/版本授权十项有实际内容，保存读回后实现。本稿隔离独立算法核心，原父句柄/DDRcache/生产链路仍须闭合。work docs按实际代码/状态/测试结果填入；完整Canny只在R2+核心+真实服务整合后宣称通过。用户理解验收待反馈。
首轮TB修订（hysteresis_core_001保留）：Questa的SystemVerilog %04d将文件序号用空格补宽，与Python的零补宽不同，导致fixture未打开。改用两端一致的不补宽十进制文件名；读取前显式fopen检查。只修测试文件交接，RTL/算法合同不变，重跑新RunId。