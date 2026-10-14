# SCAN-002 内部身份保存修订 v1.1

当前M1尚未生成。核对真实handoff时，active_changed可观察沿的active_bundle已是新对象，previous_result只含64bit句柄；因此不能从该输入重建旧active完整Origin/policy/sequence。v1 E1的active_sequence64不足以在所有旧银行已经归还时记录oldRef387。

按SC26/27，M1保存一份current_active_ref387（包括sequence64/result64/policy64/Origin195），在真实active_changed沿先将旧值入old关闭槽，再提交candidate新ref；有效active.sequence从这份ref抽取。该387位是控制身份，不新增像素存储，也不裁字段。其余481/388/545接口、2关闭槽、DE/scheduler/ROI与closure语义不变。

组合检查：active_changed当沿effective_ref用稳定candidate sequence和已更新active_bundle，使新首行不会因保存值仍旧而被discard；old关闭槽永远来自沿前current_active_ref，第一active该值0不生成旧关闭。三consumer/renderer不变。中文操作为“先按旧current_ref安排关闭槽；再current_ref<=新完整ref”，两项NBA使用旧值，与代码packed字段一致。

验证SC21..27/ST21..24加入A→B后所有旧银行已空的切帧，观察oldClosed仍含正确387，owner RETIRE不得用新Origin。追踪：SC26→M1 current_active_ref→IF21/25→old_close→ST21/23。保存读回呈现后按持续自主软件授权生成M1；本地审计例外有效，无正式DB或硬件修改。

READY_FOR_REVIEW v1.1：修订局部状态/基线，读回；非测试通过、不伪造新批准。baseline v1.1 =原25冻结输入+本卡1份，共26；保留原baseline.json和已生成不受影响的scope_fence。
