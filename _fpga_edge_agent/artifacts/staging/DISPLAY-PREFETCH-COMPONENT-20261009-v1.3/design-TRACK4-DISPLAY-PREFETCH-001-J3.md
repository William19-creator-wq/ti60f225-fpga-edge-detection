# PREFETCH v1 J3：独立测试覆盖补齐

首轮动态已证 55 场景、六模式及实际54bit写/读；审阅发现原验证计划的 CJ/policy/行坐标/零票据拒绝以及三bank同时占用尚未直接覆盖，不以已实现断言冒充实测。

中文草图：补上坏 CJ 几何、policy/result不匹配、source_y错误、非法bank/source slot、零sequence/scan/generation、非法bundle op和ANN allocation；每个只改变一处字段，holding拒绝且无AR/WR/started done。连续保留三条不同bank的已发布行，然后对第三bank提交合法新票据得到BUSY，最后逐条以其原始case/ticket读取归还。独立日志的读/归还case由该条旧行保存，不使用最后提交job的编号；参考在全日志结束后检查每个job，允许真实延迟归还。

随后保留bank0/1两行，第三bank新job与前一行真实视频read/release/return并行，core AR/WR仍记录新job、video记录旧行。三bank代次只有真正return消费后增加，旧行RAM不会因新bundle变化而改变。现有 RTL 不调整，补测试台与独立参考的可观测身份；相应源绑定重新运行并保留先前尝试。按自主软件授权读回后执行。
