# PREFETCH v1 J4：最小图 early-LAST 场景修正

min_002 的第70场景失败，原因是测试刺激：4像素RGB第0行12字节向16对齐只需1 beat，第1 beat的LAST=1本来正确，不能称“提前LAST”。RTL正确完成，测试却要求Q。

中文草图：仅把early-LAST场景的source_y由0换为1；最小4×2图第1行从byte12至24，向外对齐为[0,32)，确有2 beat。对第0 beat注入LAST=1才能形成可观测协议错误。W6/10/20/1920同样至少2 beat。其他错ID、缺LAST、enable-loss及正常数据合同不改。独立参考按job所给坐标重新计算合法span，不硬编码“所有RGB行至少2 beat”。旧失败保存。

PF03/06 → TB scenario15真实ARLEN>=1 → min/窄行/HD独立审计。依自主授权读回后只修刺激、重新绑定源，不修改RTL或生产范围；J4作为额外输入冻结。
