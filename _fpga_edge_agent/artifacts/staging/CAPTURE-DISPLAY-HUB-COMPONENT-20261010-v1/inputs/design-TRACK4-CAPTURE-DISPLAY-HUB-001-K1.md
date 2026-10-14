# TRACK4-CAPTURE-DISPLAY-HUB-001 v1.2 / K1：仲裁器回执与物理服务回执分线

## 整体与事实

目标及 DH01..06/T1..5 保持 v1.1：实际 RAW→RGB 写回→实际 reader→完整 Canny，以及独立旧 Source 的两遍显示读取共享实际 AXI128。首轮 capture_display_small_001 已终止，vsim exit=1、timed_out=false，case0/phase7 watchdog 报 Q=x。失败目录、52份源码快照和全部日志保留。

源码核查发现新 core 把 line_rpc_arbiter2 的 rsp_data/rsp_error/rsp_drained（该仲裁器的寄存输出）和 line_rdata/line_error/line_drained（来自 hub 的输入）接到同一组 algorithm_* 线上。这不是透明别名：实际仲裁器在 WAIT_RESPONSE 接纳 hub 回复，保存正文，随后在 REPLY 向锁定客户端交付。两组线合并导致两个输出驱动一线，正常回复不能可靠闭合。原已登记 capture 父用分开的内外回执线，没有这个错误。

## 接口及局部中文操作草图

1. 外部 algorithm_rdata[511:0]/algorithm_error/algorithm_drained 仅由 hub 驱动，继续接仲裁器 line_rdata/line_error/line_drained 输入。
2. 新定义 client_rdata[511:0]/client_error/client_drained，唯一驱动者是仲裁器 rsp_data/rsp_error/rsp_drained 输出。它们接实际 reader 和 Canny 的回复正文输入。
3. 客户端 rsp_valid[1:0]、rsp_ready[1:0]仍按仲裁器锁定 owner 分发。只有该客户端真实回复 fire 消耗寄存正文；另一客户端不因为公共正文改变而接纳回复。客户端 valid停顿期间，仲裁器保存的正文保持。
4. camera 独立请求/回执、算法请求/方向、hub方向锁、父控制 FF、CJ/Origin/base/参数、取消及 J1 的既成 DONE 保持都不改。新增的是514位连线，不新增514位 FF 或缓存；原仲裁器已有514位回执寄存器。
5. 注释明确外部返回与客户端持有回执的两个时间阶段。仿真期在客户端有效回复上检查正文/错误/drained没有X/Z；无效回复周期不检查数据有效性，不把四态断言解释为物理亚稳态检测。

## 验证与追踪

DH01/IF2→仲裁器 WAIT_RESPONSE 到 REPLY 的公开事务→两个client的line返回接线→T1/T2全部RGB/FP/梯度/class初代/BFS/queue/result/status及真实总线账。正常每图第二遍显示竞争仍必需。T3方向/回执停顿和T4实际父取消/错误仍执行。不能只凭去除X或compile通过判定修复成功。

先执行新 attempt capture_display_small_002（20同源图+T4协议），再按当前源码执行6×5边界、生产1920×1080以及实际组件MAP。必要独立hub T3仍须实现和审计，没有运行就保留未完成。所有旧失败保留，当前源码与每次快照双向哈希绑定。

本卡加入第56份冻结设计输入；原55份冻结输入另存 inputs/baseline-v1.1-55.json。45份运行依赖不变、52份仿真源和55份MAP源/工程不变、10份自写文件数不变。sim runner仅将冻结输入检查55改56，不扩大运行权限。当前无需要用户决定的接口未知项。

## 门槛和授权

整体、交接、语句组织、位宽、保存/接受事件、复位、验证、失败保留及双向追踪已有实际内容；READY_FOR_REVIEW v1.2。保存后实际读回，呈现入口，再在新work修复。沿用用户“当你统计完后自行进行，无需我的批准”及已批准本批本地审计例外，用户授权优先于默认逐版本等待。正式数据库/H0/硬件状态不改；不编程硬件；完整FPGA目标保持ACTIVE。
