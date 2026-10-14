# 行消费 v1.2：测试帧查询的真实动态绑定

- Goal / Current state：stream_small_001 / stream_min_001已编译/展开，运行到第17帧（保留FAIL），Q检查报错。实际scope日志从第1帧一直是含X的旧frame0；`wire query_ref=...demand_for_y(0)`只有常量函数参数，continuous assign没有随函数内隐读的bundle/frame_id更新。不是消费者或native提前释放的证据，独立参考也会拒绝这种X身份。
- Target state / Gap：TB用always_comb直接读取当前frame_id及bundle.result/policy/origin形成完整387bit查询；不用常量函数调用暗藏动态依赖。测试帧有效时明确assert query_ref无X；独立参考scope事件还核其全文等于该帧设计输入demand0提取的frame_ref。
- Assumptions / Dependencies / Open questions：生产消费者RTL和全部16依赖不变；原v1/J1设计有效。baseline-v1.2加本卡为第22冻结输入，old `_001` 两次完整源码/日志/已输出二进制都保留，不计通过。无其它未定接口。
- Milestones / Detailed steps / State transitions：保存读回呈现READY→自主授权改TB/参考/runner基线→新 `_002` 小/最小完整重跑→HD及必要MAP；不降低Q/范围/像素/closure期望，不等待逐版用户批准。
- Artifacts and hashes / Validation：现有source-snapshot是变更前真实完整20源。修复只有query_ref表达方式、X检查与独立frame_ref比对、sim runner读新基线；Source图像、54bit/像素、credit/GEN/尾部/输出期望仍不改。
- Failure handling / Human approval gates / Rollback / Completion criteria：保留失败；控制面本地审计例外、原资料只读、正式DB/硬件状态不改，无外部动作。当前leaf与整goal边界沿v1，全goal继续。

## 中文草图、语言/组合与追踪

每次父打开新的固定帧，make_bundle已更新完整来源身份；组合查询明确由 sequence64=既定BASE+frame_id、result64/policy64/Origin195按顺序组成387。core_scope_query_valid为1，在实际bank引用或服务未关闭时live1，真正return后live0，四个Q场景仍必须live1。ready、valid、复位和实际源输入无变；SV always_comb展开真实读集，软件参考由设计输入提取而不从待测查询反推期望。RS06→真实query/retained refs→Q/结束scope→TEST_FRAME_FULL_REF：无X、全文相等、与真实归还账本一致。当前受影响十项门槛有内容；保存读回呈现后自主实施，实际结果随后登记。
