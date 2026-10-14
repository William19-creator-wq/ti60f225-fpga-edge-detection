# 同一幅 RAW 图像从采集到完整 Canny 的软件组合

本批设计版本 v1.1。Ti60F225/I3，生产参数 1920×1080。用户已授权“当你统计完后自行进行，无需我的批准”；仍先保存、读回中文设计，再生成独立 work 代码。设计入口为 `_fpga_edge_agent/planning/design-TRACK4-CAPTURE-CANNY-AXI-001.md`。

## 先看整体，再沿连接读局部

```text
RAW10 两像素 + 坐标/标志/句柄
  ↓ raw_source_join（已有8个行/源写RAM）
彩色 RGB 源 → 64B写请求 ────┐
                           │ 内层source_group
RGB源 reader ← 64B读请求 ───┘
  ↓ FP74真实源像素                 ↓ 外层memory_group
完整 Canny/R2/分类/滞后连接 → 64B请求┘
                                 ↓ axi_line_bridge
                              128bit AXI，4拍/64B
                                 ↓ 实际字节内存测试端点
```

测试只从最上面的 RAW 输入；期望 FP 只用于检查，不向 Canny 驱动图像。所有源图、分类、队列、最终状态和边缘结果都从同一个 AXI 端点实际读出。固定 64B 请求适配成 4 个 16B AXI 拍。

阅读次序：父 `rtl/capture_canny_axi.sv` 的端口与 `legal` → 子实例/两层仲裁/桥 → 父 `always_ff` → 原 `raw_source_join` → `rgb_frame_reader` → `canny_full_top` → 各模块已有中文设计。数学参考是 `model/capture_reference.py`，事件和保持检查是 `tb/tb_capture_canny_axi.sv`；最后读运行目录的实际审计和 MAP。

## 外部输入、内部交接和数值

| 对象 | 具体含义与接受时刻 |
|---|---|
| CJ142 | `[95:0]={config32,frame32,epoch32}`；W `[106:96]`、H `[117:107]`、TL `[128:118]`、TH `[139:129]`、median140、retain141；`job_valid && job_ready`上升沿锁定 |
| SourceOrigin195 | `[2:0]`源槽0…5、`[66:3]`源代次64、`[98:67]`epoch32、`[130:99]`frame32、`[194:131]`采集序号64；frame/epoch与CJ一致，其余完整字段原样保存 |
| job_handle64 | 局部子模块路由句柄；不能代替完整SourceOrigin或外层授权 |
| RAW20 | 低10位像素0、高10位像素1，值0…1023；x_even/y各11位，markers={EOF,EOL,SOF}，bad/handle同时锁；只在`in_valid && in_ready`推进 |
| FP74 | 低48为`{R1,G1,B1,R0,G0,B0}`；x_even `[58:48]`、y `[69:59]`、SOF70/EOL71/EOF72/bad73；来自连续源RGB字节，无逐行填充 |
| RX关闭事件 | 独立valid/ready；必须完整origin和handle都相等才记rx_seen。good是运输/CRC质量，不能代替像素数量或源写完成 |
| grad185 | 沿用完整Canny的梯度/方向/坐标/scope/标志；retain为1时逐对输出，grad_ready可反压并必须接收旧输出 |
| done | scope96、Origin195、outcome2、reason32、数量和CS592快照保持到done_ready；真实源/读回/Canny关闭与匹配RX事件都齐全才公开 |

全部接口为同一 clk 的上升沿事件。rst是共同同步高有效复位；需要外层证明真实运输和存储公共事务已经安全，不能用本地复位消除实际DDR在途请求。

四个base按64B对齐，端点扩为33位再算；默认物理容量256MiB，六对区间互斥。源容量`64ceil(3N/64)`，分类`64ceil(N/256)`，队列`64ceil(N/16)`，结果`64ceil(N/64)`。生产完整源6,220,800字节；仅最后一条不足64B时填0，填充不变成像素。CJ的W/H必须匹配参数、W为偶数6…1920、H5…1080、TL≤TH。非法任务会锁输入身份并给ERROR，但不启动子模块或AXI。

## 按状态读内部语句组织

| 父phase | 中文操作与下一步 |
|---|---|
| 0 IDLE | 接纳并锁CJ/Origin/phase/handle/四base，清本job计数；检查全部范围。非法或同沿取消进入DRAIN；合法进入START_SOURCE |
| 1 START_SOURCE | 保持源job提案，真实子ready沿才标s_started。取消也不能撤提案；已启动后交付单次源取消事件 |
| 2 CAPTURE | 只向源输入提供RAW接受条件；记录独立RX关闭事件。源实际done保存计数并转WAIT_RX或DRAIN |
| 3 WAIT_RX | 源写已关闭仍可等待迟到CRC/运输事件；只有source OK和matching RX good同时成立才启动Canny |
| 4 START_CANNY | 保持完整CJ与三base到真实Canny接纳；mark c_started |
| 5 START_READER | 保持源base/handle到真实reader接纳；mark r_started |
| 6 WAIT_READER_CFG | 消费实际reader配置应答；合法进PROCESS，拒绝进ERROR/DRAIN |
| 7 PROCESS | reader真实FP送Canny，reader与分类/Canny随机访问共用唯一AXI。reader早完成后父可进DRAIN，Canny继续完成剩余分类/连接/结果写 |
| 8 DRAIN | 等所有已启动子实际done和RX关闭。Canny先失败时，父明确接收并丢弃reader旧FP，计discarded_fp；旧公共请求仍要实际回应 |
| 9 DONE | 全部身份/状态/计数保持；done消费后才能新job。成功要求各对数量P、结果N、无discard |
| 10 QUARANTINE | 任一子/仲裁/桥发现无法证明排空则隔离，保持上下文，无安全done及新job资格 |

`s_started/r_started/c_started`表示确实发出的子任务；`s_closed/r_closed/c_closed`表示对应真实终态已接收。没启动的子初值closed=1；不是凭空生成done。`rx_seen`只能被完整匹配的实际RX握手置1。`stopping`保留停止新工作，`s_cancel_sent`把取消电平转换成源父所需的一次采样事件；来源子自己保留停止状态。读回/Canny支持原电平取消。

两层仲裁都在IDLE选一个请求并保存owner和512bit公开body，再REQUEST→WAIT_RESPONSE→REPLY。只有回复真正交给原owner才释放。不确定drained=0的回复消费后仍隔离。外部AXI桥分别保存AW/W/B或AR/R上下文，不接受第二条无容量请求。

reason位集：0非法job、1 RX质量错误、2源ERROR、3读回ERROR、4 Canny ERROR、5成功数量不一致；真正ERROR优先CANCEL，多错误保留。错误输入的接受、停止新输入、旧输出交付、物理公共关闭和父完成是不同事件。

## 一幅图像的完整例子

先提供完整CJ/Origin与互不重叠base，等待job握手，随后可改变外部提案。等待CAPTURE真正in_ready后逐对提交RAW；源用真实行RAM反射边界插值RGB，再通过实际AXI写源图。RX事件可以先到，也可以源done后到；错误身份不能关闭本源。源done和良好RX同时成立后，reader实际读取同一段RGB，跨64B边界组合像素，送R2形成分类，再由实际cache/queue/HY完成八邻域滞后连接并实际写结果。最后所有子done、数量和公共关闭齐全，父才提供done。

取消时先停止新RAW/读回工作；正在保持的AW/W/AR/FP继续保持。能证明已回应的错误是ERROR；无法证明身份或末拍排空的错误是隔离。显示用的完整帧发布、冻结恢复以及完整授权/fence由后续生产整合承担，本组件的局部关闭不能直接当作跨域帧发布证据。

## 如何运行、如何看证据

已存在本机工具：Questa2024.1、Efinity2026.1、Python；脚本使用现有ASCII junction，保留原中文工作路径和所有旧attempt。每次RunId必须新建，不能覆盖。

在工程根的PowerShell中运行本目录 `scripts/run_capture_sim.ps1 -RunId 新名字`；完整尺寸加`-FullHD`。专项几何加`-Width 6 -Height 109`。先通过suite-result和独立reference-audit，再用`run_capture_map.ps1 -RunId 新综合名字 -SimulationRun 已通过的仿真名字`。最终MAP必须与当前所有仿真源码摘要一致。

每个runs子目录包含输入摘要、进程启动/退出、stdout/stderr、fatal出口探针、实际像素/内存结果、独立审计及终态。进程退出0不能代替reference-audit；未结束不能登记PASS。HDK和已登记产物始终只读。

当前实际通过：capture_small_010，34×19、20图像、34协议，12,920像素；capture_narrow_001，6×109、20图像、34协议，13,080像素，真实held-FP故障witness=1、discard=1。两者分别覆盖正常和最小宽度/多行事件。

capture_hd_001：完整1920×1080，2,073,600像素、1,036,800对，源字节6,220,800；实际源写/读各97,200条，全部AW138,846/AR114,544/W555,384/R458,176/B138,846；边缘1078、discard0、36,811,963作业拍，独立审计PASS。capture_map_001：实际46 RAM10、21,976 FF、27,109 LUT4、1,776 ADD、166 SRL8、0DSP，exit0；警告为冗余删除和常量小数组映射逻辑，未见未驱动接地/锁存警告。MAP不是生产时序或帧率证据。

理解验收尚无用户实际作答；这一状态不阻塞已授权实现。生产CSI/真实DDR控制器动态/帧发布/显示/识别/最终PNR、STA和总bit尚未由本组件证明。
