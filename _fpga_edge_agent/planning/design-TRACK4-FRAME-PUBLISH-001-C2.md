# TRACK4-FRAME-PUBLISH-001 v1 / C2：补足输入拒绝与提交边界测试

当前26场景 `publish_small_001` 已实际仿真与独立审计退出0。复核FP01/03/05时发现缺少显式Source、非法字段及公开END后取消/停止的具体测试，尚不把该证据称为整个v1覆盖完整。保留已通过run及snapshot。

本修订只增加原v1范围内的8个TB/独立参考场景，RTL不改：非法mode、非法CJ尺寸、显式COMPLETE Source、错误Origin、显式WRITING Source拒绝；good END已公开后取消应保持END7并在真实回执后DROP2；已公开good END后halt同样持有并在已知安全关闭后DROP2/QUARANTINED完成；显示已真实提交后晚到cancel应继续APPLY和正常completion，不能释放显示对象。

中文草图：输入拒绝从真实Source回复形成explicit handle/Origin，保持至请求fire后更改输入，观察真实ALLOC拒绝且没有job。held END先停owner接受，再交付真实DONE，等待公开RESULT_END后改变cancel/halt；解除接受后检查真实END/回执/DROP/回执顺序。晚到cancel以真实显示回执为触发，不凭TB计时假定提交。独立模型保留集合账本，通过公共事件检查顺序和状态，无RTL状态机复制。

关联FP01→IF01/03→T01/04/06；FP03/05→IF02/03/05/08→T03/04。实际core10ns/video14ns，Questa、A64 owner/handoff及producer/row0/closed fixture身份不变；参数1080p仅元数据范围验证。新 `publish_small_002`、minimum/HD及MAP使用新冻结snapshot，不把旧26场景run套用到新源码。

READY_FOR_REVIEW；保存、读回、呈现并冻结本卡后按既有持续软件授权与本地审计例外进行。用户没有新的单独C2回复，不伪造批准。FP业务接口/边界不变；独立参考增加halt后已知安全DROP证明，未知END0仍无安全完成。正式数据库/H0/Manifest及硬件不改。
