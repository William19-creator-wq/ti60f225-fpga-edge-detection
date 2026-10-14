# R1 v1.1 前端仿真操作与证据读回

本文件仅管理已批准的 FE v1 独立前端验证。批准号为 `AP-ALGORITHM-R1-20261004-v1.1`，输入基线为 `ALGO-BL-20261004-v1.1`，22份冻结输入；不代表摄像头、HDMI、DDR、Canny、识别或硬件观察已完成。

## 先整体，再局部

1. 先读 `_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md`，再读其继承的完整 R1 v1 与 `design-TRACK4-FRONTEND-001.md`。FE D 是接口合同，E 是实现时序，F1 是黄金文件格式，G 是验证合同。
2. 独立二维 Python 模型先产生输入、期望、场景清单和 SHA256。它直接计算有限图灰度、排序中值及 Sobel，并分别夹紧两次邻域，不读取 RTL 比较网络、RAM 或状态机生成期望。
3. 五个顶层 TB 选择局部或完整前端，共同检查器在下降沿驱动、上升沿读取沿前真实握手。两 lane 所有交付组都按文件逐行比较，身份、坐标、标记、数值与终止状态分别检查。
4. runner 读取整个 `manifest.json`，审核所有文件路径、hash、固定宽度十六进制、行数与覆盖类别，才编译和逐项仿真。局部调试仍读取完整清单，报告明确写 `PARTIAL_PASS`，不将其当作完整 suite 通过。
5. 查看每 case 的 `result.json`、vsim stdout/stderr、`run.do` 和小图 WLF，再查看 `suite-result.json` 汇总。仿真通过只证明获批的软件合同；布局布线、STA、bit/hex及硬件观察由上层各自收集真实证据。

```text
批准/22份基线 ──hash/bytes──► 独立参考 ──完整manifest──► runner
                                  │                        │
                            input/expected HEX             │
                                  ▼                        ▼
                          五个局部/整核 TB ◄──────── 本次work库
                                  │
                     real fire / 数值 / 协议 / RAM端口
                                  ▼
                 每case JSON、日志、.do、小图WLF ──► suite JSON
```

## 局部接口与交接

| TB | 独立刺激 → 黄金 | 检查的局部合同 | 对应需求/场景 |
|---|---|---|---|
| `tb_rgb_to_y_pair.sv` | RGB48 → Y16 | 两lane定点舍入、3级延迟、元数据和背压 | FE-02 / OP-02 / FT01 |
| `tb_median9_pair.sv` | window144 → M16 | 开/关均9级，512二值窗口、重复值及随机排序黄金 | FE-03 / OP-06 / FT02 |
| `tb_sobel_pair.sv` | window144 → diagnostic84 | M16、edge2、signed GX22/GY22、L1 22同步；严格阈值；6级 | FE-04 / OP-07 / FT03 |
| `tb_window3x3_pair.sv` | Y16 → window144 | 两lane独立有限图replicate，行交接、首/尾/底行 | FE-01/03/04/06 / OP-03…05 / FT04/05 |
| `tb_frontend_frame_pair.sv` | RGB48 → M16+edge2 | 三ID/config锁定、双补边、全帧状态、取消/错误/reset/恢复 | FE-01…08 / OP-01 / FT06…11 |

`frontend_tb_driver.sv` 是五 TB 的内部验证复用模块。K=1…5只选择上表 DUT，W/H传入实际窗口/整核；不改变业务 RTL 的端口或功能。Stimulus/expected从文件流式读取，避免额外完整帧数组。

数值打包严格遵循 FE F1：gray input 12hex / expected 4hex；median 36/4；Sobel 36/21；window 4/36；frontend 12/5且高2bit为0。Sobel expected 低到高依次为 M16、edge2、GX22、GY22、L1 22，每lane signed GX/GY占11bit。空白、短文件、长文件、非小写hex、X/Z、非零高填充都失败。

## 逐拍操作草图

```text
下降沿：保持未接受输入 → 根据声明事件设置气泡/背压/坏输入/取消/reset
       → 合法空闲时才读下一组 → config只在job握手时被DUT锁定
上升沿：先观察沿前旧out fire（包括取消/输入错误沿）
       → 每组读一条黄金并核坐标/标记/三ID → 计实际交付与比较
       → 输入fire计实际接受（坏组也计） → 状态fire核实际计数/位置/代码
下一下降沿：取消输入保持/开启恢复job/按已采样clear清管线
结束：finished + errors=0 + compared=delivered + 全normal数目 + 事件全执行
```

driver 不把 flush 组合接入 ready/valid；取消/输入错误沿已有旧输出交付仍计数。旧job失败后，独立 follow_up 在同一 DUT 无 reset 开启新job，使用新身份/配置/黄金；reset场景重开同一完整输入与黄金，从0核对新帧，旧RAM不得泄漏。STATUS背压检查payload稳定，期间不准接纳job/input或输出。

STATUS另直接检查DUT `all_empty`：三算术有效位必须空、两窗口必须IDLE且无pending/水平有效/输出有效。它检查实际内部状态，避免只由F0外部out_valid被关掉就推断所有旧历史已清。

对真实 RAM 端口观察 `rd_en/rd_addr/recent_wr_en/older_wr_en/pending_q`，统计实际读/写，对每次地址范围、同地址碰撞与clear期间操作进行检查。K5分别观察中值前和Sobel前的两套窗口。使用原厂只读 `efx_ram10.v`，不替换成行为RAM。

取消/reset的phase事件使用实际内部信号，达到目标才触发，超时未达到即失败：F1/median/Sobel看各自valid_pipe非空；window_a/b_fill看实际REAL_PENDING且pending_row=0；REPLAY/Tail看对应窗口实际replay_phase=2/3。`phase_hits`记录实际命中的bit，不根据scenario名字填写。

FT07固定 LFSR taps31/21/1/0，每下降沿更新；input bit0、output bit1，各类连续随机暂停最多8拍。输入valid已提出后必须保持到接纳；额外气泡只能在下一组前插入。

## 在现有 Questa 中运行

在项目 PowerShell 中执行，RunId必须尚不存在：

```powershell
& '_fpga_edge_agent/work/active/track4_algorithms_20261004/r1/scripts/run_frontend_sim.ps1' -RunId frontend_acceptance_001
```

诊断单类时可加 `-CasePattern 'FT04-*'`。runner读取完整模型清单，报告为局部通过；正式完整验收去掉该参数，必须包含所有FT01…11及四个1920×1080完整生产job，每job1,036,800组。

运行输出位置为 `r1/sim/frontend/runs/<RunId>/`：

- `vectors/manifest.json`及所有HEX：完整参考输入。
- `work/`：本次独立 Questa 库。
- `reference/vlib/vlog`对应 stdout/stderr 日志：工具真实退出码在suite JSON。
- `<case_id>/events.txt`：13列事件协议；`run.do`是实际执行的命令文件。
- `<case_id>/result.json`：真实 accepted/delivered/compared、numeric/protocol错误、status、恢复数、event数、phase bit、RAM操作和延迟。
- `<case_id>/trace.wlf`：小图记录交接及RAM端口，完整图不记录RAM阵列。
- `suite-result.json`：22项hash、原厂模型hash、编译输入hash、完整manifest hash与验证、逐项PASS/FAIL和实际工具退出码。

事件列从左到右为：code、trigger、index、cycles、field、value、when、epoch、frame、config、median、kind、threshold。code1…9对应气泡、背压、坐标、标记、bad、cancel、reset、配置改变、状态背压；trigger0=input，1=output，2=STATUS，3=actual phase。正常输入不是用事件脚本生成，由输入文件和真实握手推进。`when=fire`保留取消沿旧输出交付；`when=before`保留既有背压。

runner只沿用已有 ASCII Tool/Work junction；现有 Process 许可缺失时临时读取 User MGLS_LICENSE_FILE并复制到runner进程，finally恢复，不输出其值或读取许可文件，不改User/Machine设置。每个子工具有墙钟超时，TB另有有限拍数超时。失败停止当前完整suite，保留该run全部证据，修改后使用新RunId。

## 当前可核查证据与限制

`tb_compile_001/vlog.log`：原厂模型、六核心、共同driver和五TB统一编译退出0，Errors0/Warnings0。该run首个vsim退出4，Process许可配置缺失；不作数值通过证明。

`window_smoke_002/result.json`：4×3窗口真实接受6、交付6、比较6，数值/协议错误0，RAM reads16/writes10，首输出−首输入=5=D+3，尾输出−首输入=10=N+D+2。该次成功日志仍有inline onerror/onbreak两条命令警告；runner改为保存独立run.do，后续以新run验证，不抹去旧证据。

`frontend_suite_001…003`保留runner启动失败记录，未执行数值仿真。`frontend_suite_004`参考生成审计因未canonical的ASCII junction源码路径失败，保存INCOMPLETE及退出2；模型作者已修复，目录边界没有放宽。

`do_handler_001…003`保留仿真失败处理的真实试验：`-onfinish exit`对fatal也可能退出0；`+acc`后原厂无timeunit会触发load错误。最终用编译参数`-timescale 1ns/1ps`、`-onfinish stop`和独立.do里检查TB `done`，正常退出0，故意错误黄金退出1/finished=false、真实交付1/比较1/数值错误1。正常+acc保留vopt-10587减优化警告，不隐去。

`frontend_suite_005`已生成123场景、306文件、8,322,536行hex，四完整生产job的独立参考总计8,294,400像素；实际仿真止于FT05结构检查FAIL，前57项PASS。FT05真实12/12/12、errors0、RAM32/20通过，但旧清单把无FS的window填status0，而TB记录NA/-1，不能把它冒充F0 OK。模型作者只修正该metadata为NA，数学与原RTL未改，最终完整suite必须使用新manifest/sourcehash。

`run_protocol_probe.ps1 -ProbeId <新ID>`是Root指定的小图诊断：新库、新TBhash、新日志，只读005数学黄金，动态挑选FT05、FT08、FT09、FT10；旧FT05状态明确按NA合同检查，诊断结果仅能为`SUPPLEMENTAL_PASS`。探针复用本工作区runner的纯函数定义，不执行runner主流程、不给外部数据作为代码，不修改旧向量。新`STATUS all_empty`断言在该诊断先验证，然后默认完整入口重生全部黄金执行新suite。

`protocol_probe_001/probe-result.json`实际44/44 `SUPPLEMENTAL_PASS`，覆盖全部指定类别、九个真实phase以及正常/错误/取消终止时内部全空。窗口B REPLAY：cancel旧8+恢复20=28组，reset旧7+恢复20=27组；TAIL：cancel旧12+恢复20=32组，reset旧11+恢复20=31组，数值/协议错误均0。区别来自取消沿旧out真实交付，而reset屏蔽该沿传输。

`frontend_suite_006/suite-result.json`现已实际完整`PASS`：123/123、full_manifest=true、runtime_input_hashes_unchanged=true、runner退出0。正确新FT05 NA清单、306文件/8,322,536行hex均核对；22冻结输入及两批准设计卡另行校核。本次18项运行输入前后hash一致，126次子工具调用均退出0。

四个FT11完整1920×1080作业均各接受/交付/比较1,036,800组双像素，status0、数值/协议错误0，合计8,294,400像素；每job cycles=1,038,747，首/尾相对首输入1944/1,038,743拍，与D=960、N=1,036,800的无停顿公式一致。实际每job RAM reads=4,151,040、writes=4,145,280。全部必要正常、背压、配置、错误、取消、reset、九phase及恢复场景成功。

driver冻结hash为`D219A6F508EEE68D69B5209A7B8EAF953EE863112E6FF51250147B6128F9A46D`；runner为`AD3093150FA061AF8A020911C02F329D93E025C1D2D49E15EF8E748C825E33AD`。原厂EFX模型文件未改；`+acc`的vopt-10587减优化警告保留在真实日志，不声称所有日志warning为0。源文件、仿真/诊断/观察均在当前分工内，未由本验证步骤执行Efinity、正式DB或硬件操作。

小图查看顺序：先看`result.json`真实计数和错误，再看`run.do`确认本次驱动/日志范围；用Questa打开`trace.wlf`，把clk、valid/ready、输入/输出index、实际phase和RAM端口并排观察。上升沿valid&&ready为一次真实交接；气泡中index不进、背压中payload保持；reset/cancel之后的STATUS要结合all_empty与下一job完整恢复结果读回。完整1080日志不追踪整个RAM数组。

`observations/wlf_readback_001/readback.md`含实际只读采样的中文观察表：FT05气泡/跨行/背压/底行重放，及FT10窗口B TAIL取消/reset/完整恢复。三个`-view`/`examine -time`查询均退出0，原WLF before/after hash相同；这份工具采样与Agent读回不代替用户本人理解验收。

`border_discriminator_002`为Root指定的FT06补验：同4×3 ramp、T=41，m0/m1均全6组M+edge真实数值比对、status0、错误0。其`readback/corner-readback.json`从实际整核WLF读取unused_l1：像素0/3/8/11在有效ready=1的334/344/374/384ns，m0四角L1全44/edge全1，m1四角L1全40/edge全0；两个查询退出0，WLF hash不变。T=41使双补边反例具有判别力，区别于原T=4都为edge1。001保留审计路径数组拼接失败，正式专项证据为002；专项不代替006完整suite。

前端软件验证已完成FE F1/G必要场景。R1整包由Root继续聚合外壳、工程综合/布局布线/STA/产物的实际证据，并按控制面保留用户理解与硬件观察的相应状态。
