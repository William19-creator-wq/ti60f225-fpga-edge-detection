# DISPLAY-ROWS v1 J1：abort测试台等待事件修正

证据：rows_small_001编译/展开0错误，24个正常行实际读写/归还完成；日志最后ABORT在7815000ps已经fire。TB在io_closed变1后等待ready变高，连续赋值尚未更新就进入等待，下一周期state已RETURN_LOCAL、ready已低，因此漏掉已发生的fire，100ms suite watchdog失败。原失败run完整保留。

修正仅TB：监视actual abort_valid&&abort_ready增加每bank abort_fires；驱动方在改变io资格前记录旧计数，等待actual计数变化才撤valid。所有ready/valid操作以实际fire决定，遵守DR06，业务接口/RTL不改。suite watchdog根据测试几何/行数计算保守上界，让小测试停滞迅速失败，HD仍有足够仿真周期；不更改器件watchdog。

中文草图：负沿锁旧abort计数→提出stable abort/gen并给真实闭合资格→等监视器记录上升沿fire→下一负沿撤valid→检查完整DISCARDED holding及父消费→下一代填充。T3/DR06→tb监视/abort场景→新RunId及独立参考。依用户自行继续及本地审计授权，保存读回后实施；没有新增批准要求，不改已登记包。
