# SCAN-RESERVATION v0.1 原稿有限审阅

2026-10-04。本报告保存实际只读审阅结果，未实施修订，未生成业务源码、脚本、测试或 testbench，未启动 GUI、综合或仿真。设计仍 NOT_READY、NOT_APPROVED；完整十一项工程未完成。

绑定原稿：[SCAN 设计](../../../planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md)，33581 B／223 行，SHA256 `BE543B4348AF71D5AD5338A6EB3B8FA26316DE8BCC23673A86B1CBF93A989F37`。三名独立审阅者实际全文读取，前后哈希一致。报告不适用于尚未保存或尚未读取的后续修订。

## 有限数值结果

CTX840×4＝3360；PREPARE841/979、KEY256、CTRL327/335、EVENT1021、CORE409/417、DISPOSE322/330、ARM_SET642/650、record198、STOP_NOTICE262/270 位宽算术一致。D3 列出的 body 合计26486 bit 是下界，不是完整控制状态、目录、CDC、资源或全机 fit 证明。F 残留19448应在后续修订中同步。

四 ctx、两个 future 含未选 closing、三输出 bank／两输入 bank、VSYNC 前旧 READY／ARM 资格以及同沿新资格不穿透，在声明的条件下数值一致。59.259259、608.700337、608.619529、623.434343 µs及双首行810拍、1440逻辑写事件、5760 native lane WE算术一致，不能证明最坏服务。

PREPARE 精确去重还要求每 ctx 保留原请求身份。若从 CTX 重建原841 bit请求，至少另留 prepare_seq64、原 route_kind1、hint_was_zero1，共66 bit／ctx、四份264 bit；当前角色不能替代原 route。也可保存完整请求，但实际采用及预算尚未冻结。全局 transport 单槽不能代替四 ctx 的持有。

新增独立 scan_ref_valid 若采用，六个固定 slot各增加1 bit，76→77，原96＋80＋6×76＝632变为638；这是候选修订算术，原 PIO 卡尚未修改。这六位不能代替其他容器的身份、pending或引用状态。

## 原稿中尚未修订的协议与生命周期问题

1. ARM group缺少选择／过期后的membership终态。若等 ctx DISPOSE 才解引用，而 DISPOSE 又等 group解引用，会互等；保持到 selected退休也会挡下一帧 ARM。后续需明确边界结果实际转交 ctx 后关闭membership，独立 held ACK／cache仍持有原文；其实际容量及重复应答范围另列。
2. DISPOSE前“私有pin完成”须区分临时event/control引用与持久base execution pin。持久pin保护仍存活ctx，须保留到成功DISPOSE_ACK实际消费后，不能因borrow关闭而提前归还父base。
3. D、physical pool与snapshot的实际closed_before/applied证据须汇入原七owner中的V owner0 ACK。V核心域先更新不能代报视频域D已应用新epoch，也不能隐增第八owner。下级接线仍SC-B01/02 OPEN。
4. Q缺少合法通知路径。现有kind只有APPLIED/CLOSED/RETIRED，kind3非法；合法CORE_CLOSE若报unknown/Q且loan未关闭，未采用future不能发APPLIED，八facts不足不能发CLOSED，也不能发RETIRED。后续须定义独立Q事件及真实前缀/facts；消费不能伪造CLOSED或授予RETIRE/DISPOSE/FREE。
5. 落选原因未确定。IF09要求命名原因，现有表没有NOT_SELECTED；后续须明确使用CANCELLED5及status2，或新增专有码，不能留给实现猜测。
6. ARM失败后哪些已登记ctx进入closing、旧ARM transport与group缓存怎样分别持有，仍须明确。没有把拟议修复当成已完成事实。

## 限定结论与继续条件

原稿明示的四完整ctx、future含closing、target不retag、两physical bundle含keeper/snapshot/unknown、旧实际画面snapshot先于ADOPT、同link physical frame_seq跨软件epoch保留，有限审阅未发现新的结构反例。高水位只约束新准入，不拒绝已经准入而后来被选择的较小exec token。

三个bank在两个未来首行占用后，旧尾行和未选route仍需及时真实关闭；snapshot可延长oldclosing。资源、服务、真实接口及审批阻塞SC-B01…04保持OPEN。该稿不是整包协议通过，也不是资源fit、连续显示时限、仿真、布局布线或比特流通过。

## 本次用户问题的环境核验

本机`C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/bin/efinity.exe`存在，FileVersion为2026.1.132。现有[C0项目](../../../work/active/track4_ip_precheck_20261004/C0/ti60f225_oob.xml)明确Titanium／Ti60F225／I3，SHA256 `5F0CF2C013F945974052FFE796D68E84815C9F5C02B9CF37EA44086221BFED3A`。其同目录peri、SDC及DDR3/camera/display引用实际存在。原来源是V4资料包的10_Ti60f225_sc431hai2hdmi_demo／Ti60f225_sc431hai2hdmi_v1；0927资料包另有07_Ti60F225_MIPI_C2D_Demo／Ti60f225_csi2dsi_sc431hai_v3.4项目。

安装目录还实际带helloworld-unified／helloworld.xml，目标Ti60F225／C4及Ti60F225_kit_pins.isf，属于官方kit示例；其引脚不能直接作为V4板配置。实际读取本机官方Open Project说明，其操作为启动Efinity、点击Open Project、选择项目XML、Open。本次未启动GUI，不声称GUI打开已经实测成功。

既有[预检终态](../../track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md)保持：C0综合通过，USER1 TDI/TDO冲突导致PNR packer失败，placement/route/STA未完成；CSI保护模型无可用key导致Questa DUT编译失败。这些是具体工程/工具兼容问题，不是缺少Ti60F225环境的证据。
