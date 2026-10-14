# ANNOTATION-WRITER C1：只修正 body 场景的测试调度

- 基线：v1、18份冻结输入、annotation_small_001/source-snapshot；设计外部边界及生产RTL不改。沿用用户软件自主执行及本地审计授权。
- 事实：实际 vlib/vlog/vopt 正常，fatal probe拒绝通过；正常帧、配置拒绝、协议0..7通过。协议8触发TB watchdog并退出1。最后一个头部输入已接受不等于其实际回执已闭合。TB立刻 rpc_open=0，阻塞该头块事务，然后等待 body_ready，形成自锁。
- 同一缺陷会影响协议10的body BRESP错误、UNKNOWN1的body wrongBID：在最后header闭合前设置fault_kind，会把错误注入头部阶段。
- REQ/IF：AW02/03、IF03b/04；不修改writer、不修改原期望、不放宽T04/T05。等待真实header66闭合以及子cfg ack，公开body_ready成立后才关RPC或注入body错误。
- 中文操作草图：完成66次header输入 → 等待公开body_ready实际可接受（其前提由writer的66回执和真实子cfg握手建立）→下降沿提交测试gate/fault变化 →发送body →保持原取消/错误/UNKNOWN期望。
- 实施：只新增TB内部等待任务并用于协议8、协议10、UNKNOWN1；日志和原失败snapshot不改。本卡额外冻结到inputs/control/C1-v1.md，原18份不重写。
- 验证：新RunId重跑同一完整小尺寸33场景；原失败永保留。生产RTL hash必须与首次snapshot相同；之后再跑最小尺寸/fullHD/MAP。
- 前述诊断试图检查PID61340后再停止，但Get-Process确认其已不存在，没有执行Stop-Process；write_stdin返回工具退出1，实际vsim日志明确watchdog退出。不存在仅因观察超时而重启。
- READY_FOR_REVIEW：原因、接口、草图、范围、期望均清楚；读回后依持续授权实施。正式数据库/Manifest/硬件状态不变。
