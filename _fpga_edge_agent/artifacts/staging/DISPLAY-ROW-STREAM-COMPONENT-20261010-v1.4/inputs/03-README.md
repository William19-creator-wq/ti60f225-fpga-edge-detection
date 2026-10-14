# 显示取数：核心行服务与跨时钟运输（软件交付 v1.2）

本包补上完整显示扫描所需的“视频需求→核心真正取数→完整收据”和银行代次、引用账本。三个自写 RTL 已生成；实际 native RAM/AXI 动态测试和 Ti60F225/I3 的两个组件综合均已执行。完整视频行仲裁、owner/handoff/renderer 的同一帧联合、真实 DDR、生产顶层布局布线/时序/bit 继续推进。本包不是整工程完成证明。

用户授权“当你统计完后自行进行，无需我的批准”用于继续独立软件实现；沿已批准本地审计例外，正式 PostgreSQL、H0/硬件状态和原资料不改。

## 1. 阅读次序与文件分类

1. `inputs/00-design-TRACK4-DISPLAY-SCAN-CORE-001.md`：生成前冻结 v1；先外部 FC01–07，再模块/交接，再中文逐沿草图与 FT1–5。
2. `inputs/01-design-TRACK4-DISPLAY-SCAN-001.md`：完整扫描的 v0.1 草稿，明确仍未实现的整体工作；不能把 DRAFT 当实现事实。
3. `inputs/05-…J1.md`、`inputs/06-…J2.md`：测试补充和实际发现的测试刺激修正；先设计、读回、呈现再修改验证源码，原失败保留。
4. `rtl/display_fetch_pkg.sv`：完整身份/包位序；`display_fetch_link.sv`：两域运输；`display_scan_prefetch_core.sv`：真正银行/IO/行发布与归还。
5. `deps/`：11份原样冻结依赖，其中 AXI 字节 slave 是测试环境，不是生产 DDR。
6. `tb/`：真实核心联合 TB、主动错包的运输 TB；`model/fetch_reference.py`：独立字节数学/实际握手事件审计；`scripts/`：仿真与组件 MAP；`project/`：两个 XML top 和同一 SDC。
7. `runs/`：每次独立尝试的原始源码快照、进程/时间/参数/退出码、完整日志和参考结果；本 README 汇总实际事实。

分类数：**11份自写业务/验证文件，3个自写 RTL；11份复制依赖，合计22份源码/工程文件；18项冻结输入**。设计、README、日志、源码快照和登记清单另算，不能称为“模块数”。旧 baseline.json / v1.1 与最新 baseline-v1.2.json 都保留。

## 2. 整体交接与完整身份

```text
video 481需求 holding
 → link atomic481（源包保留，core claim一次）
 → core CHECK/LOOKUP（真正GEN stamp和父942/permission）
 → 原reader/header → 实际native rows fill/ACK
 → 实际AXI AR/R与native WR
 → publish，或安全abort/真实内部return，或未知Q
 → core 615收据 holding → link atomic615
 → video实际消费 → ACK回core → idle同步回video

已发布row → video真实native RE/pop → 真release
 → core return_valid保持 → 父真正消费 → GEN+1、行引用清掉
```

request481=`{bank2,demand479}`；demand高到低为 sequence64/scan64/result64/policy64/Origin195/target_y11/source_y11/mode3/mask3。core插入真正GEN64组成原543票据。receipt615完整携带 bank/ticket/status/granted/outcome/reason/drained/returned/计数。frame_ref387逐字段取 sequence/result/policy/Origin，不能截断、哈希或直接截票据一段代替。

bank忙看真正 core bank 状态；视频 owned0、release提出、已消费收据都不代表该银行已经能重新分配。GEN仅正常或内部abort的**真正 core return fire**推进，最大值归还后 exhausted，不回绕。三银行之外没有第四行/帧像素 RAM。

## 3. 中文内部操作与语句组织

package的 packed struct 明确每份身份和位序，两个纯函数仅提取 frame_ref。link 的 continuous assign 描述何时可接/可送，两个原子 mailbox 保存完整源包；分域 always_ff 保存 busy/current、取消电平、claim、响应ACK等待和永久Q，复位/单bit回传为两级同步。普通时序寄存器非阻塞赋值，组合无隐式 latch。

核心的组合块统一形成 fill/write/publish/abort/return 端口及 scope 查询；时序状态机按 IDLE→CHECK→LOOKUP→HEADER→ROW_FILL/ROW_ACK→START_READER→RUN→RESULT推进。原reader已经锁住942/543，核心不额外复制完整942；调用方必须把481 payload 借用保持到核心收据真正接受，link的原请求未提前ACK提供此前提。

LOOKUP是可取消的父端只读查询：没真正 ready/fire 之前不安装引用或产生IO，cancel可改成NoStarted；lookup真正 fire 与 reader job fire 同沿。字段/权限失败不发AR。核心ready依enable及reader ready；**一直禁用会不接受新请求**，status7用于已经claim而尚未启动时的enable丢失。

实际fill OK才锁该bank完整387引用；reader所有IO/producer关闭后才publish。安全失败须实际abort并消费内部return后才给returned1/drained1。错ID/LAST或活动禁用造成Q时，保占用/引用、drained0，不把迟尾或恢复enable当关闭证明。

普通return和新claim同沿：两者读取旧值，新请求得到旧busy/GEN的BUSY收据；沿后真实return推进代次，下一请求才见新GEN。收据及原包holding不会因晚cancel改变。

local_scope_live包含当前服务/收据holding/Q和已授行引用；transport_live另包含尚未实际消费ACK的请求。它们是局部事实，**不能直接送owner RETIRE**；完整scan仍要证明视频credit/owned/renderer尾部与无未来请求全部关闭。

## 4. 实际测试（最新同一验证源码）

|运行|尺寸/用途|核心场景|真实54bit WR|真实54bit read|AR|R|
|---|---|---:|---:|---:|---:|---:|
|fetch_small_003|20×8|74|475|470|94|230|
|fetch_min_003|4×2|74|94|94|94|118|
|fetch_w6_001|6×8，非整字节边界|74|143|141|94|135|
|fetch_w10_001|10×8，非整字节边界|74|237|235|94|154|
|fetch_hd_002|1920×1080宽行、1080基础行|1118|1047525|1047360|6223|311060|
|fetch_max_002|GEN从FFFFFFFFFFFFFFFD开始|4|30|30|9|18|
|合计|只计上述最新6次|1418|1048504|1048330|6608|311715|

Questa vlog/vopt均0错误，fatal探针实际非零，实际仿真退出0及finished=true；每次独立 Python 参考均PASS。全部54bit（RGB48/EDGE2/ANN4）、地址/完整身份/AR段、R字节与ID/LAST、发布/abort/真正归还及GEN账本由事件审计，1282次scope查询。五次实际视频暂停各200核心沿、五次同沿真实return/claim覆盖。GEN最大值不wrap，第四次明确EXHAUSTED。

覆盖模式0–5、字段/权限/忙拒绝、LOOKUP停顿与接受后父bundle改变、预启动/AR/R取消、晚cancel不可倒改已形成收据、615 holding、三个bank同时保持、core return ready0下仍保引用、RESP安全失败及wrong ID/early/missing LAST/enableloss的Q。最大值测试不复用一般故障分支。

运输专测 `fetch_transport_002` 6包：正常NoStarted停钟/回执holding，wrong bank、wrong Origin高位、granted-GEN0、outcome3、drained0；逐包实际claim/核心收据/video消费均各一次，五错误最终双域Q保transport_ref和live，正确包真ACK后才idle。独立参考按请求和预先规定的故障构造完整期望，不读取link内部状态计算答案。此父是主动注错fixture，与真实核心联合结果分开。

`fetch_small_002` / `fetch_min_002` 明确 **FAIL/STOPPED_INVALID_TEST_STIMULUS**：测试在claim前关enable，却等status7；等待发生在无接受之前。核PID/进程开始时间后终止这两次vsim，runner保exit=-1、FAIL与完整源码；J2移到真实claim后下降沿关enable，零IO/status7期望未放宽。原 `_001` 已通过运行与 `fetch_transport_001` 亦保留，不重复计进最新总数。

HD测试是跨全高度的独立宽行，包含不同结果/源身份，**尚不是同一bundle经owner/handoff/扫描的完整帧**。字节slave是数学图案，ANN生产者/复杂形状识别未由此实现；真实DDR refresh/QoS也未由此验证。metrics里的ideal_mode5_cycles=0是未测项，不是性能结果。

## 5. 当前 Efinity 真实综合

|独立top/运行|RAM10|FF|LUT4|ADD|DSP|SRL|
|---|---:|---:|---:|---:|---:|---:|
|display_scan_prefetch_core / fetch_map_001|19|9452|17066|439|1|0|
|display_fetch_link / fetch_link_map_001|0|1623|384|0|0|0|

两次MAP均exit0。**核心top没有实例化link，两份报告必须分别读**；未按standalone相加宣称整系统装得下。core warn包含冗余loop信号去除、三个小RGB cache和代次表映射逻辑、既有reader不消费的配置输入与post-synthesis 132 warnings；这些保留原日志，不静默过滤。两个err.log只有工具开始头，无实际ERROR；link warn无实际warning。

MAP冻结生产 RTL/依赖/XML/SDC与当前相同；之后只补/修TB、参考、sim/map runner，旧MAP完整snapshot与旧运行证明都保留。原 `_001` 四次源快照是先按当时manifest哈希核实后补存，标为source-verified-snapshot；新运行一开始复制source-snapshot并从副本编译/审计，前后核哈希。没有用当前测试冒充旧源码。

XML可在Efinity打开对应Ti60F225/I3组件；SDC的100MHz核心/约74.25MHz视频仅是目标时钟预算，组件没有板级引脚。**本包没有执行生产PNR/STA、没有SDF/post-map动态、没有生成bit、没有硬件动作。** 实际整体FF/LUT/RAM、真实输出时序和引脚闭合要在生产top完成后检查。

## 6. 复跑与修改入口

使用已安装的PowerShell7，运行 `scripts/run_fetch_sim.ps1 -RunId 新名字`；几何选择 `-HD` / `-Minimum` / `-Width 6或10或20`，代次 `-NearMax`；运输选择 `-Transport`。每次新RunId，禁止覆盖旧attempt。

MAP使用 `scripts/run_fetch_map.ps1 -RunId 新名字 -SimulationRun 本包成功运行`；core默认，link用 `-Link`。脚本先校验真实成功及所有源SHA、复制snapshot，再调用现有Efinity，只执行map。若准备更改公开行为，先修设计/中文草图/追踪；随后代码与独立期望分开检查。修改GEN规则查FC03/core return，运输/取消查FC06/link，字段位序查FC01/02/package；测试对应FT/JREQ，不从文件数推断覆盖。

本包最终需求→代码→证据：FC01/02→package四struct及core receipt→六次完整615审计；FC03/07→generation_stamp/generations/bank_ref/真实return/scope→真实归还、同沿、1282query、near-max；FC04/05→lookup/header/RUN/abort/RESULT→真实AXI/native和拒绝/取消/Q；FC06→link两mailbox/ACK/current/Q→实际联合+运输六包。反向定位每个核心寄存器和分支仍对应这些职责；无用户作答，理解验收待检验，不阻塞软件继续。
