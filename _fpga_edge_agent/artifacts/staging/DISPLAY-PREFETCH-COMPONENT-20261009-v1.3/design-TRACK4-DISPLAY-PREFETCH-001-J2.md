# PREFETCH v1 J2：首次编译和测试入口修复

首次 small_001 编译发现 SV 在使用 span_q、serial_valid、meta_pending 前尚未声明，已将原有声明前置；没有改变电路行为、端口、存储、状态或数值合同。small_002 的 55 个完整场景及独立参考已通过。

HD/minimum 的运行入口在进入工具前失败：PowerShell 的 Width 参数 ValidateSet(6,10,20) 同时限制了脚本内部赋值，1920 和 4 无法写入。中文草图：Width 保留为用户的小图选项，只在局部 RunWidth 中形成最后几何；HD/minimum 更新 RunWidth，而不改写被校验的 Width。传给顶层 TEST_PF_W 的是 RunWidth，库原语参数仍不被递归覆盖。其失败目录和日志保留；原始资料不变。

PF01/02/07 → TB 几何与独立脚本的参数合同 → min/6/10/20/1920 宽实际编译、动态及参考检查。此次为内部声明/验证入口调整，按自主软件授权保存并读回后实施，不增加功能范围；原 v1/J1 输入保持原样，J2 作为额外冻结输入。
