# FIT v0.5 读回与下一次终审入口

2026-10-07；作者和本次静态读回均为root，未委托独立审查，不声称仿真/综合通过。

## 已读回与核查

主卡v0.5全文读回，27600B/SHA89311FECB77A6AB0F0D05DE19C9B66869EC45A28893BCA1209E37BA5A1E00CF5；新增validation-and-probe-v0.1全文读回。原v0.4按字节保存，SHA413567CD284704A4827B7AE03A07B41401DAC2A2FC667E625F70EBC0856CC96B。

原3RTL的协议/真实core/reset源码，以及3个原scalar工程/SDC原字节核查；原core SHA DAA31292536F4860C23DE5CFAF73AC444CD18B2AB5E9D2ED9C9B8092217EA0F0。既有scalar批准明确排除本LS/TLS/完整识别实现，故本轮未将旧“批准”扩展。

44项只读输入清单FIT-INPUT-REVIEW-20261007-v0.5为6份seed（3RTL/3原工程）、10个现有工具入口、28份设计/规则/证据，文件SHA E4C2C36218BEA8F77BA7AECAF55113915617EF6FDD229FF6CBA744758046D7A5。保存后逐项按真实文件重新hash，44项0漂移、0缺失；它不是实施基线，不授权生成代码。独立r3_fit work仍不存在。另核ANGLE v1.1已冻结34项，0漂移，设计未改。

## 本轮改变了下一步的依据

- 已明确19文件与真正的子接口；fit_core分别实例化private_bridge/private_arithmetic，桥可独立连真实或fault-source child，不需要force内部生产实例。
- 七kind正常来源与完整typed扰动交替；外req/fire、旧ID/LED事件、585位CRC消费和seq不回绕都有具体操作，不是单纯心跳顶层。
- 独立LINE/FINITE参考直接使用有理平方边界，不复制DUT q0/M或floor取根路径；真实原child与隔离故障账分开。
- 推导两合法主输入，使LINE q0=2分别精确修正到1与3。输入域/K、RNE M、精确阈值方向已手推；必须由未来仿真实际验证，不能把证明记录当测试PASS。
- 增补原source统计构造乘法后DSP候选16，显式覆盖v0.4附稿的未具体source时DSP8；FF容器10782不变。重要选择仍在未批准设计内，不改已交付模块。

## 终审应逐项完成，不能只删NOT_READY

1. F-B02：从LS/TLS/交点/LINE/FINITE表逐项核目标位数、signed标记、385收192资格、每个slot消费后才覆盖；TLS的anis/rho/μ、交点两K与den、缓存hit/miss两路径必须具体读回。父局部非等待步骤与16沿桥余量/1024局部余量应由有限路径表支撑，cancel≤8在每个真实握手阶段作端到端走查。
2. F-B04：将主卡CHECK/计算顺序与首错矩阵逐连接对照，特别是COUNT局部/帧两类、PSD/K为INTERNAL、宽商后GEOM_RANGE、已HELD保持及未暴露取消优先。不以工具exit0代替这项设计判断。
3. F-B03：对19文件反向核职责/TEST，最终稿明确SV语言组织与包命名空间（父/桥使用fit包，原child只使用scalar包，跨包名显式限定，避免双wildcard常量歧义）；核probe两个profile的精确位段与旧源形成顺序、独立审核和物理数据路径，不让缓存/宽数值路径被静态常量替代。
4. 十项门槛逐项有依据后保存最终版本、实际读回；再单独冻结指定实施基线并重新核所有输入，不能将本v0.5清单的hash照抄给已变化的新设计。

最终设计若READY需呈现指定版本、范围、基线和本批本地审计例外，等待真实人工批准后才生成业务源码/参考/运行脚本/TB/工程。当前本轮产物仍纯文档/静态元数据。完整1080p、全部十一项及原识别质量目标保持未完成；ANGLE/DDR获取的待批准事项没有收到新答复，不作权限改变。
