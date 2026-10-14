# 共享DDR服务实际读稿审查 v0.1

2026-10-04；TRACK4-DDR-SERVICE-001 / DOC-20261004-DDR / READBACK-01。主设计v0.1、主计划v0.8；**LOCAL_DESIGN / NOT_APPROVED**。本页记录磁盘文档、既有源码/模型与独立只读审阅，不是RTL或器件仿真。

## 1. 阅读入口与职责边界

[DDR主设计](../../../planning/design-TRACK4-DDR-SERVICE-001.md)按PLAN_TEMPLATE A–L保存：先B整体行为、C职责，再D身份/授权/接口与相邻差异，E逐段/封口/恢复中文操作草图，F数值/逐沿/服务界，G/H验证追踪，I阻塞。8项要求、8接口、8操作、10不变量、16文字场景均可定位；业务测试全部NOT_RUN。

服务管理scope/grant/permit、完整段、真实AXI响应和安全归还证据。FM最终引用、图像完整/识别结果及显示发布仍在相邻模块。14叶prepare/req与7方向数据分开；物理R/W各最多一个owner并存是候选，实际IP尚未证明。

## 2. 三方向实际读稿发现与修正

三位独立审阅者实际读取保存稿，再有界核对root修订；不把旧消息建议当作实际文件通过。以下修正已写入主稿，原FE/FM/Canny及附件未改。

| 方向/涉及位置 | 实际问题 | 主稿修正 |
|---|---|---|
| 物理/存储；OP04/05/06 | min2预取与只备首拍矛盾；RESP失败遗漏owner释放；预取时取消不再有B/R | 首min(2,n)全部capture才AW，W valid+pending≤2；COUNT/ID/LAST正确即可physical_done；未proposed预留在pending/输出归还后撤owner，不等不存在响应 |
| 并发/终态；OP03/06 | 坏COLLECT不收满会永久等待；终结后RAM capture复活valid；新valid与cancel同沿冲突 | 首格式错安全失败；terminal_fire后的旧capture DISCARDED；旧物理valid继续，未提出者cancel/rst/fault禁止首次提出 |
| 返回/生命周期；IF04/OP06 | 客户端等池FREE、服务等release形成循环；ACK消费前重用 | release只等本地借用和服务输出/pending/held结束；池仍由record持有，RELEASED ack消费才统一归还，下一沿复用 |
| 终态顺序；OP06 | 末响应与cancel同沿的优先级、held R行为不清 | 未提出终态按未知排空/错误/明确取消/成功排序；旧终态不变，held R保持至joint终结 |
| 身份/权限；D1/E1a | mask清掉历史J；坏grant ERROR_ONLY释放又要求grant有效 | PROCESS/DISPLAY保留历史J；mask只授当前租约；ERROR_ONLY按原record释放实际取得scope/phase，grant_ref/pool_slot_valid保护未取得资源 |
| 阶段/公平；C/F1 | 每scope一个记录与32子账本冲突；14叶请求套7次机会界；关闭phase0影响另一client | 32个(scope/client/phase)记录，7×4=28bit关闭图；req14叶RR、数据方向7路RR，机会界分开 |
| 封口/fence；OP07 | 服务seal先禁prepare、再要求dirtyWB会死锁；OUTPUT漏CLASS导出读 | producer_close→尾段/脏WB全部prepare/req→不再产生请求→服务seal；旧承诺继续；OUTPUT包含实际CLASS读及EDGE写 |
| 元数据/快照；E1/E1a | scope623+token64超过phase640；grant mask没有代次；逐字读动态计数不一致 | phase仅引用scopeH68；pin实际grant代次；冷518+122=640、热381+3=384；同沿合并后原子640staging再串行写，Q快照独立live账本 |
| 排空计数；E1a | terminal消费与引用回收易混淆 | terminal_seen/physical_done单存；terminal_count为RELEASED ack实际消费数；先归还本地/服务借用再释放阶段pin |

ERROR_ONLY许可保留有效scope/phase归属但不授非法地址访问；无效scope/phase在prepare直接DENIED，没有假的service_seq/段或fence。stream rst不等被冲刷的未启动W来源，合法安全失败与未知排空隔离分开；已提出物理承诺保持完整排空。

这些是文字设计纠错；未运行故障注入、仿真或性能测试，不能据复审将状态改READY。

## 3. 位数、模式与已列资源

J身份486、scope623、grant241、请求头198+permit68=266、terminal301、release288、cancel body692/ack697，均按实际字段算术。SourceOrigin195允许同源冻结重处理改变job/config/policy；完整身份匹配不等于仅slot相同。

[实际RAM模型来源](../01_baseline/ddr-service-ram-evidence-v1.md)核20×512、地址9、WE双10bit、同步读/下一沿capture。R/W独立池各7条带，共14RAM10；scope身份1、32phase冷记录2，共metadata3，服务17块。Canny已列44+服务17=61/256=23.828125%，先前58只是数据池相关小计。热元数据、输出/640staging及控制FF另计；平台/相机/显示/识别未计，尚非整机实际资源/放置结果。

Canny候选12区页分配55,226,368B保持原文件；地址非重叠不能证明真实DDR映射。单方向RR7次、请求RR14次及Canny条件乘积35/14均是机会界；真实DDR等待/刷新/干扰、六源EOF→FREE和显示lead仍无有限实测上界。

## 4. 用户指定两目录的实际来源复核

VF长根11,672展开文件中24个模型+24个4096Mb参数头；两个SC1336 ZIP各567成员、各1模型。Demo长根5,254展开文件，IMX219 ZIP568成员内1模型/4096Mb头，另7z6成员为Python/TFLite/H5。合计27份模型均Micron v1.74默认den4096Mb/x16，SHA256 AF83D644D4471A88E9D732AED012BF486FEE75BE79031660452F576FD56F20EA。

模型第97/98行的密度/数据宽度、第99行速度头及第122/123行2Gb分支均已实际读取。模型主体存在，2Gb分支依赖的2048Mb参数头不在这次检查范围；4Gb头ROW15/COL10/DQ16不能代替目标2Gb。Demo的控制器ddr3_parameter.vh有ROW14/COL10/BANK3/DQ16，但它不描述Micron器件行为和完整时序。精确路径/成员位置见[来源记录](review-and-blockers.md)。

本轮没有改原文件、解压写回、下载或联网。DDR源缺口是匹配MT41J128M16JT-125的2048Mb参数/器件时序依赖及明确配置；真实受保护控制器/PHY校准仿真仍必需，不能只改宏假称通过。

## 5. 真实状态、未解决项与检查边界

DS-B01…08继续包括2Gb依赖、真实物理映射/RESP/可见性、每方向并存/R承接/W连续、FM/显示/采集端口、六源与显示期限、识别AUX及全机资源、冷初始化/热恢复、MC/Canny新旁带统一。D3显式列旧相邻稿差异，本轮不把03/FE/FM/Canny变成新批准基线。

[当前文档审计](document-checks.json)验证路径/相对链接/ID/模板/算术/选定输入hash。前轮[Canny v0.4检查](document-checks-canny-v0.4.json)保留历史哈希，不用于证明本轮索引现状。

业务源码、功能脚本、testbench、实际功能仿真、综合、PNR/STA、bit/hex均未生成/未运行；正式DB/PROJECT_STATE/TASK_LEDGER及硬件观察不改。官方模型获取与FRONTEND v1两项原问题继续待答，不重建申请。下一允许工作是相邻契约/平台/识别设计与真实依赖闭合；实施仍等完整无阻塞设计和指定批准。
