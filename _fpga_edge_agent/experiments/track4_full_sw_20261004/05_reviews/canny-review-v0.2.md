# Canny v0.2：窗口与流段只读设计审查

2026-10-04；[主稿v0.2](../../../planning/design-TRACK4-CANNY-001.md)及[中文窗口/交接草图](../04_local-designs/canny-window-sketches-v0.2.md)保持LOCAL_DESIGN/NOT_APPROVED。这里记录设计分析、真实文档修订和读回，全部业务验证未运行。

## 1. 整体到局部的变化

数值链及精确八邻域闭包不变；本次补齐C1/C2 Gaussian、C5 NMS和C0/C4流段交接的具体执行输入。原FRONTEND v1与28项输入、FRAME-MANAGER v0.1、原HDK保持不变；完整目标仍为5基础+6高阶到bit/hex。

| 独立审查 | 具体结果与修订 |
|---|---|
| Gaussian窗口 | 四bank r模4延迟写、顶部r2/r3、两次底部重放、水平四旧列及五级算术的事件表一致；补valid TAIL、col历史与H算术分名、真实r与中心y分名、同bank覆写时不同地址行归属、控制优先级及有限表示 |
| NMS窗口/分类 | 16bit容器需按8bit平面组成8 RAM，输出288bit；两级分类条件延迟一致；补外框历史保留原Mgrad、只中心抑制、容器只取幅值位比较、中心dir邻居索引、贡献按实际分类交付累计 |
| 父流段/分叉 | 补eJ锁配置后ARM/start、FJ提出/接纳/取消、FE status独立及时保存及不可变性；各EOF/empty/writer封口/fence分开；fork旧交付后同沿新接纳以新pending覆盖旧清位，不透传新组；最终读回收紧独立flush可关ready、本沿错误flush不反抹触发握手，补合法start/empty/追踪回路 |

Gaussian审查的末组反例已处理：TAIL虽然没有新数值，但V1/V2必须event_valid=1，否则W6/H5只能交付14pair并等待EOF。NMS审查的外框反例已处理：若在历史中提前清零外框，内圈比较可能改变；外框只在N2中心判定时抑制。

## 2. 条件推导及未验证范围

D=W/2，P=HD，N=2P。输入从e0连续、全部ready、无flush时，Gaussian首e(2D+7)/末e(P+2D+6)；NMS窗口首e(D+3)/末e(P+D+2)，分类再2沿。W6/H5分别为Gaussian e13…e27、NMS窗口e6…e20、分类e8…e22，各15pair。这些只读推导不是已运行波形，不能相加成尚未冻结的整条Canny延迟。

T15…18加入Gaussian ring/TAIL、NMS byte/外框、父启动/FE状态、fork old/new；T01…18全部NOT_RUN。共享FE及已列Canny候选仍为40 RAM10，其他平台/显示/识别、实际逻辑/时序/吞吐未证。

CN-B01/02已获得详细窗口执行输入，仍需与CN-B06的完整端口和批准基线统一复核。CN-B03…08继续阻塞：cache/queue物理FSM及partial、MOD-05真实地址/响应/fence/后台服务、完整job/status/原因优先级、方向级、地址/租约及真实性能。窗口设计一致不等于整机READY。

## 3. 用户补充目录的再次读回

VF代表展开模型再次读回，SHA256仍为AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA；Demo的IMX219 ZIP再次直接列目录/读模型文本。两者第97/98行默认den4096Mb/x16，第122/123行的2Gb分支仍依赖缺失的2048Mb_ddr3_parameters.vh。既有24+2+1份模型检索记录及精确定位见[模型复核](review-and-blockers.md)。本次没有下载、解压写回或运行原工程。

## 4. 当前审计与实施门槛

[当前检查](document-checks.json)登记本次文件/链接/ID及真实输入hash。旧21份文档快照保存在[document-checks-canny-v0.1.json](document-checks-canny-v0.1.json)，不能证明修改后的主稿/索引。

FRONTEND实现及官方DDR模型获取仍各有原待答申请；没有新批准证据，本次不重复发起。未生成业务代码、可执行验证、编译/仿真、综合/PNR/STA或bit/hex，未改正式状态/数据库；用户理解验收仍待实际反馈。
