# CAMERA v0.1 实际读稿与来源复核

2026-10-04；TRACK4-CAMERA-001；LOCAL_DESIGN / NOT_APPROVED。本记录是设计分析与文档检查，不是RTL、I²C实测、仿真、综合、PNR/STA或硬件通过。

## 1. 实际审读范围与版本

[相机主稿](../../../planning/design-TRACK4-CAMERA-001.md)按模板A–L，8项要求、8项主交接、8项中文操作、10不变量、24项文字场景及双向追踪；[窗口/writer附件](../04_local-designs/camera-window-and-writer-sketches-v0.1.md)另有CW接口、数值/逐沿/组拍/FE关闭及12项文字场景；[来源v2](../01_baseline/camera-csi-and-config-evidence-v2.md)保留原v1并记录活动CSI5.15与另一生成件、公开端口/帮助和配置链缺口。

三个独立审读方向实际从磁盘读稿，分别审CSI/身份/关闭、CFG/跨域/重试、窗口/writer/FE。根代理再核归档/本地帮助来源、全部字段加总、资源及主附件一致性；所有业务场景均NOT_RUN。审读中间稿哈希不同于末修稿，不能把早稿确认冒充晚稿证据；末修实际读回及当前检查绑定如下。

| 文件 | 最终SHA256 |
|---|---|
| CAMERA主稿 | F9E595439A9F4D8F6DBB0A31B682D1A52928C1109C8A10FCEEA2B587D899F45C |
| 窗口/writer附件 | 443A7E4DEAE2056EB2A82D8753D63C236723FE91814C39243C72D9F1301DD696 |
| CSI/配置来源v2 | 7FCC316A187864CB52B74C23415852F1E7F9B848CCF9F4844C57B5EEA08787CD |

## 2. 独立发现与已保存修正

| 方向 | 发现 | 文档修正与边界 |
|---|---|---|
| CFG成功 | STOP不能依赖停流后的观察/读回；不同attempt不能复用旧证据 | kind2 arm0；attempt只0/1/2，失败第2终结，清本attempt ID/mask/ROM/连续帧；READY是资格快照，不是ARM完成 |
| CFG→ARM | 本域eligible清0不证明像素端旧ARM已撤销 | GATE202/ACK208逐级CFG→core→pixel；新配置/STOP动作前取得撤销业务ACK；late READY不能打开sticky停止门 |
| 重试与观察 | 请求/cfggen相同，晚到旧观察或reset release可被误用 | OBS392含attempt和window_seq；START260/ACK266从本次verify后新SOF计帧；physical210每attempt新token |
| I²C | 旧上层只看TIP、读dout无赋值；正常STOP/AL/主机NACK不能混淆 | 四从机ACK、RXR捕获、CR地址6/SR地址4、真实STOP/BUSY/tBUF；正常主机最后NACK；AL释放，无物理关闭证据Q |
| CSI表达 | 互斥type或一个metadata tuple不能覆盖全部同沿事件 | NORM192独立flags，跨scope/row/tuple串行拆项；short16本profile保留0、原短包valid不能猜；PL189需下一版本吸收 |
| 真实边界 | control-only EOL/EOF可能晚于末payload，无法回写已交付pair | 独立RAWPAIR114 end_pair等真实EOL，末行再等EOF；不占原record堵后续control；新行合法已EOL只hold，不误报错 |
| 消费关闭 | closure邮箱可先于数据FIFO到，producer关闭≠consumer排空 | RX_CLOSURE363携累计提交watermark；scope入口基线/ordinal从1、consumer≥；旧NORM/pending/odd/end_pair/CA3一起关闭才drained1 |
| 关闭互等 | status/return等待scope或mirror CLOSE、PREPARE借用等FINAL可成环 | status→独立return/ACK（不等CLOSE）→DS关闭→mirror；PREPARE归局部payload借用并QUIESCED，身份/通知pin留到FINAL |
| 窗口数值 | 双轮舍入、BGR旧格式、复制RAW边界会产生不一致 | RAW10四phase、reflect101、单轮量化/9bit饱和、canonical R高8及DDR逐字节重排 |
| 组拍/回收 | 跨4KiB后段可能重读word0、第一子段ACK过早FREE | segment_byte_offset/8；正常全部子段关闭，失败未proposed后段可作废；bank借用/pending归还后回收 |
| W终结 | “held W永不可撤”与显式失败drained终态矛盾 | 正常保持，匹配kind1/2 terminal_fire可共同作废未接受逻辑W，pending capture后DISCARD；kind3不解隔离，物理承诺仍真实结清 |
| 早取消 | 功能rst可能丢唯一RGB EOF而writer等EOF | 独立local_abort锁失败、同沿旧fire照记；未提出COLLECT/carry明确作废，不假补L内像素或EOF |
| live FE | payload73漏bad、满时同址RE/WE依赖未证明返回、IDLE cancel忽略FJ | 完整FP74、容器80高6零；count0不RE、1…511地址不同，旧512满仍overflow；heldFJ先接纳后ACTIVE cancel |
| 局部/fence | 请求封口与local_terminal混用会使父互等 | 两独立证据；封口后父可发seal/fence，旧W/B/ACK继续，local_closed不等fence；FE FS独立消费 |

这些修正是设计合同的闭合，不证明外部保护IP或真实模组已满足合同。

## 3. 数值、容量与原文边界

本稿字段逐项加总：CFG186/receipt192/terminal274；OBS392/control260/ACK266；physical210、GATE202/ACK208；lease1048、ARM284/ACK290；NORM192、closure363；RAWPAIR114、RGB142；LIVE438、CAPTURE808。旧DDR scope623/grant241/req266/W152/terminal301/release288/ACK293和FE FJ110/FP74保持一致。握手线不计payload。

RAW最大1023、和/偏置上界1025/2050/4100需11/12/13bit，移位结果9bit可256需饱和。生产N=2,073,600/P=1,036,800/L=A=6,220,800B；6B→8B packer无WE分支可留6B、通用carry≤7B，WE分支余≤5B。两1024B bank满帧共6075次容器载荷。尾pad只在真实A−L范围；正常完整数据/flags与失败前缀分别验。

新增RAM ROM1+RAW4+源writer4+FE4=13；既有149包含camera CDC20，累计162/256仅已列候选63.28125%。CA3核心数据632bit、CA2已列holding/末pair/odd至少508bit，完整6ctx/mailbox/控制与XLR另计；不冒充综合资源。1024×4pixel为20.48µs消费量、FE512pair为5.12µs，只容量算术，不是吸收最坏DDR停顿的证明。

原配置表stream-on后19次写与Group Hold最多10不能混成一次提交；实际活动CSI是rtl5.15，另一5.16/settings非活动。root直接读本地customizing原文：GENERIC是without accurate synchronization timing via LS/LE，不据此保证某个行同步精确边沿；具体HS/VS/包到规范flags继续B01。

## 4. 保留阻塞与实际阶段

CAM-B01/B02真实CSI输出/短包有效/错误归属/CRC关闭、B03父/FM/DS/PL新端口吸收、B04匹配2Gb/PHY、B05真实模组reset/EXTCLK/SID/FAE生效/phase/增益、B06无背压期限与六源/QoS、B07全部FF/RAM原语/STA、B08批准及正式DB均未关闭。因此保持LOCAL_DESIGN，不能标READY或生成业务源码/TB。

本轮新增来源/主稿/附件/本记录，主计划与索引升v0.11；原FE/FM/Canny/DDR/识别/PL及冻结来源不修改。此前36份平台审计字节相同另存[历史快照](document-checks-platform-v0.1.json)，当前检查重新绑定本轮文件、链接、ID与输入哈希，kind仍DOCUMENT_CHECKS_NOT_FUNCTIONAL_TESTS。既有两项待答问题没有新增授权，不重复提问；本轮没有网络/下载或正式DB/状态变化。
