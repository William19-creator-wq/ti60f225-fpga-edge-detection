# TRACK4-CAPTURE-DISPLAY-HUB-001 v1.3 / T3：独立公共客户端验证补全

## 整体、边界和事实

继承v1.2的生产1080p、实际采集/Canny和两遍旧Source显示要求。K1修复后capture_display_small_002真实PASS：20图、18采集协议、401750周期、1235AW/4940W/1235B、784算法AR/83显示AR/8108R、36真实算法与显示读竞争周期。当前缺口是v1明确要求的独立hub T3，不能用整合正常图或旧read/write组件测试代替。

T3只实例实际video_memory_hub及既有数学双向byte slave，容量32768字节、无DUT私有状态期望。追加tb_video_memory_hub_protocol到现有slave TB文件，仍只有两份TB源、10自写文件、52仿真/55MAP源与45复用依赖。原始HDK、已登记包不改；不增加真实DDR、FrameRef、CSI或整机通过声称。

## 客户端、语句及时间草图

客户端驱动都在负沿；正沿前valid&&ready才交接。camera/algorithm请求一旦公开，valid/addr/data/方向保持至fire或可信common cold。负沿issue提出，逐正沿等ready、负沿撤valid；回执ready初始0，看到真实valid后核对正文并停顿至少7沿再消费。拒绝或UNKNOWN也必须真实回执，不能由test自行制造closed。

写正文逐字节来自确定的地址与salt整数公式；读期望来自独立初始化公式及此前真实W写入。Display显示数据逐字核对已授权、不与当前写竞争的旧区域。正常8192B span从0x2ff0开始，必须分段、跨4KiB并停顿；数据/终态全部消费后才算成功。模拟slave保留一读一写独立在途，不能用私有DUT状态制造AXI响应。

公共逐沿账记录case/cycle、5位controls、camera request546/reply4、algorithm request547/reply516、span48、display word130/done13、AW51/W147/B8/AR51/R137和diagnostics8，均二进制全正文。独立Python解析：每个端口保持；accepted请求归属；只有真实AW/W/B或AR/R才改变存储/确认物理闭合；读取完整128bit与byte memory相符；safe read回复512bit来自该实际读；safe write回复需真正B，非法已知参数则没有物理事务。UNKNOWN通知消费保留借用，不因物理idle清除算法live。

独立检查器从公共请求和总线记录重建内存，不读取数学slave数组或DUT内部状态，不按TB的PASS字段自证。每个case的预期结果固定在测试场景表，额外核对数量、因果及全部字节。X/Z仅case29方向/case30未接纳camera正文作为负样本，其余有效已接受正文必须已知。reset同一正沿覆盖hub和slave，允许终止旧借用，不能推广为生产暖reset许可。

## 场景表与相容检查

1读方向锁+held回复时改变未公开提案；2写方向锁；3并行16camera写、12algorithm写和8192显示span压力；4camera写后算法真实读回。

5..8 algorithm已知非法地址（非64B对齐、超32768容量、32位末端、容量尾部不对齐）安全错误/no AXI；9..13 display非法对齐/0/15/8193bytes/越界安全错误；14合法末端16B。

15公开held AR之后cancel仍保持AR并完成旧burst；16held display data之后cancel仍保持数据；17BRESP错误safe drain；18RRESP错误safe drain；19wrongBID UNKNOWN；20wrongRID UNKNOWN；21earlyLAST UNKNOWN；22lateLAST UNKNOWN；23实际write在途backend停用UNKNOWN；24read在途停用UNKNOWN。

25producer本地Q时并行旧camera写和算法读仍safe收尾；26camera safe回执已持有后独立readQ不得污染；27算法safe read回执已持有后独立writeQ不得污染；28writeQ时已经获准的旧8192显示span继续合法AR分段和完整显示；29未知算法方向无接纳隔离；30未知camera写正文无接纳隔离；31已经公开safe read回执之后enable暂低仍保持safe正文；32两方向在途共同cold；33cold之后新正常读恢复。

所有Q场景检查三个新应用接纳均禁止，旧通知可消费且全正文保持；UNKNOWN算法通知消费后live仍1。25/26/27/28分别证明跨方向Q与真实enable区别，28的Q后AR仅属于此前span借用。3必须实际读写重叠，不能仅分别完成读和写。32/33共用重置既有许可，不使初始拒绝变为硬件恢复证明。

## 执行、追踪及门槛

TB任务和Python独立审计追加于现有两源；runner每次均编译/展开新top、执行真实fatal拒绝探针、独立hub仿真，再实际capture仿真与两套独立审计。T3不能再可选读取hub-protocol-result；要求33场景及独立公共账PASS，HD/min同一当前源码也运行T3。Python还要求actual_read_contention>0，防止只有显示或算法分别服务。

DH03/IF2→1/2/3/4方向与接纳/回执；DH02/IF3/4→9..16/18/20..22/28的span及真实字节；DH04/05/IF5→23..31的阻新、旧保持和跨方向Q；DH06→5..14/29/30/32/33参数、四态和common cold。自写文件及原新core/hub均由52源SHA绑定；最新小图/6×5/完整1920×1080通过后才组件MAP，记录真实资源与未完成生产范围。

本卡第57冻结输入，原56份baseline另存inputs/baseline-v1.2-56.json；runtime源计数不变。详细语句、端口、位宽、接受/交付、旧borrow、独立验证和异常恢复均已有可讨论内容，无本T3范围BLOCKING，READY_FOR_REVIEW v1.3。保存读回、呈现后按持续自主软件及本批local audit授权实施，正式DB/H0/硬件不改；完整目标ACTIVE。
