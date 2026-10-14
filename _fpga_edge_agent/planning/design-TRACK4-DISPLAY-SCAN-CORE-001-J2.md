# DISPLAY-SCAN-CORE 验证刺激修正 J2

- Goal / Current state：J1 的 `_002` 小/最小测试在第70项等待，因为测试把 enable 在发视频请求前置0。源码实际 service_claim_ready 明确依赖 enable 及原 reader_job_ready；这是不接受新需求，尚不具备可回复的借用请求。原 FT3 的“启动前”必须有实际 claim 才有615终态。
- Target state / Gap：测试在实际 service_valid&&service_claim_ready 的上升沿之后，于下一个下降沿置 enable0，下一上升沿 CHECK 使用0，预期仍 status7/outcome1/granted0/drained1/零IO，随后恢复继续。生产 RTL、拒绝期望、接口和禁用机制不改。
- Assumptions / Open questions / Dependencies：原v1与J1有效；没有新设计未知。J1运输六包测试已PASS；link MAP运行中无需修改其冻结源。
- Milestones / Detailed steps / State transitions：保存读回呈现本卡至 READY_FOR_REVIEW→自主软件授权实施仅 scenario29 时序→独立新 `_003` 运行；追加本地审计。原 `_002` 明确因测试刺激错误停止，保全部源码/日志，不包装成通过。
- Artifacts and hashes：J1冻结baseline-v1.1保持17项；新baseline-v1.2加入本卡为第18项；sim runner只改读取本基线。TB实际禁用移到request accepted及真实core claim后，不改变任何已通过原case的期望。
- Validation / Failure handling：小/最小、full615与实际native/AXI/真实归还独立参考；原 `_002` 从start.json核PID、开始时间和vsim名称后只终止对应模拟器，runner收集非零/失败。不删除旧attempt、不终止无关进程。
- Human approval gates / Rollback / Completion criteria：沿用户“统计后自行、无需批准”与本地审计例外，正式状态/DB/硬件不动；源码快照可回看；叶验证随后登记，整目标继续。

## 组合、中文草图及追踪

JREQ1→IF2 actual claim→CHECK：enable1让link真正接视频请求，核心真的claim后原atomic继续借用holding；下降沿enable0→CHECK NoStarted→615实际两域回执→恢复enable1，GEN不动。reader尚未lookup/job消费，无AR、无native FILL/WR。若enable一直0，ready保持0且调用方应保持valid/完整payload；不能在没有接受前要求业务完成回复。

TB scenario29：不在prepare时关enable；待真实claim沿→下降沿关enable→照原验证status7和零副作用。独立参考仍按真实claim和回执审计，无放宽。宽度/时钟/复位/holding/身份全沿原v1/J1，文档/代码双向位置为 run_case scenario29、service_claim_ready/CHECK、FT3/JREQ1。所有当前受影响门槛有实际内容；保存读回呈现后执行，不冒充新逐版人工批准。
