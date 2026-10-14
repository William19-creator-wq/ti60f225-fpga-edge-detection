# FIT v1 最终代码—草图—验证核对

授权：FIT v1、45输入基线及本批本地审计例外。阅读次序：冻结整体设计 → module-code-reading → qualification/placement-operation-sketch → 本核对 → VERIFICATION → 最终交付记录。冻结设计保持原字节；本页记录实际实现，不追写成获批前已运行。

## 十九份业务文件与双向追踪

| 文件 | 实际职责/关键符号 | 设计要求与验证 |
|---|---|---|
| rtl/scalar_protocol_pkg.sv | 原标量消息定义，原字节 | FT01/07，私有原始请求/响应独立审核 |
| rtl/scalar_core.sv | 原0…7算术核心，原字节 | FT01/06/07，321307次已消费私有响应逐笔核整数期望 |
| rtl/reset_sync.sv | 原两级同步释放，原字节 | FT01/08，共同复位及真实级间Q→D |
| rtl/fit_protocol_pkg.sv | 字段、格式/首错、完整385资格、打包和奇偶政策 | FT01/06，T01…08/helper |
| rtl/scalar_bridge.sv | 私有序号、锁命令、保缓存、确认child quiet后发布 | FT01/07，T07/08与34项桥检查 |
| rtl/fit_core.sv | 11父状态、16逻辑192槽、LS/TLS/交点/两类距离/诊断、4项纯数学缓存 | FT02…07，T01…09/取消/复位/缓存/每次真实局部192等价 |
| rtl/fit_probe_top.sv | 动态384位源、两输入profile、实际fire、585位逐位CRC消费者 | FT08，T09/10的1056笔来源/结果/CRC |
| model/fit_reference.py | 完整整数式、直接有理距离二分、primitive_reference | FT08，独立总结果及私有原始结果期望 |
| model/fit_vectors.py | 固定种子向量、真实点集/合成统计分账、两身份域事件及CRC审核 | FT08，14517向量/独立账/1056来源 |
| tb/tb_fit_helpers.sv | 隔离等号/奇偶及完整高位、typed、normal域 | T05/06/07，不冒充真实几何half样本 |
| tb/tb_scalar_bridge.sv | 原child与隔离故障分账、最大序号边界、完整值、保持/quiet | T07/08，34项/真实24调用/隔离9调用 |
| tb/tb_fit_core.sv | 完整585比对、真实外部/私有账、状态取消/reset/cache、槽/局部表示不变量 | T01…09，14517/37/35/5及28804实际局部提交等价 |
| tb/tb_fit_probe_top.sv | 真实顶层来源/消费观测与复位后恢复 | T09/10，1024+32笔 |
| scripts/run_fit_sim.ps1 | 新attempt、致错非零、finished、独立审核、19源始末一致 | FT08/T09；最终fit_suite_012 All PASS |
| scripts/run_fit_build.ps1 | 同源快照/前置门槛、分阶段进程和日志、PNR/STA/Bit发布闸门 | FT08/T10；最终物理验证另见VERIFICATION |
| scripts/postroute.tcl | 精确复位网络、内部覆盖、12段真实Q→D及setup/hold | T10；空集合/空实际报告不允许发布 |
| project/fit_probe.xml | Ti60F225/I3、七RTL、25MHz独立probe工程 | T10，Map/Interface/PNR |
| project/fit_probe.peri.xml | J2/P13/N14/P14引脚与I/O电压 | T10，实际PT/pinout读回 |
| project/fit_probe.sdc | 单40ns clock，仅KEY→两个异步SR及LED输出例外 | T10，无核心/整个reset/multicycle例外 |

## 组合及语句组织核对

622外部请求和585外部响应与设计一致；私有桥406/403一致。父锁上下文，原child自己的私有64位序号只随真实请求接受递增；外部ID不等于工作槽目的。原child只导入scalar包，父/桥/probe只导入fit包。

PREPARE读旧有效槽，锁完整待交接命令；QUALIFY_RETURN先核真实完整返回再一沿写唯一槽；ADVANCE下一状态才读新槽。局部操作同样LOCAL_COMMIT一沿一槽。16×192逻辑槽未缩成另一套近似数学，高位只按已批准typed表示共享相同FF。LINE/FINITE局部算术先扩必要位再操作，结果仍完整192资格，进位不能提前丢弃。

取消不撤已经发布valid，不重写HELD。桥先消费child返回，再确认child quiet，最后发布自己的缓存；父DRAIN独立于外部反压。共同cold reset清有效性并分账作废。4项缓存不存frame/point/结果ID；普通取消保留既有有效纯数学项，取消同安装抑制新项，冷复位清valid。

参考总结果使用直接整数公式与有理中点搜索，未从DUT槽或相同子状态机推导期望；真实私有结果另外用primitive整数模型核。失败、主动中断、部分诊断与完整PASS分别保留。只有所有发布门槛通过且bit/hex实际生成并登记，才算这批软件交付闭合。

## 完成边界

本核对覆盖七类几何数值运算。完整识别候选/支撑/去重、完整Canny滞后连接、DDR动态资格、SC431HAI/HDMI/CDC/阈值/冻结/叠加和整包性能/质量仍未由本批证明。理解验收未有用户作答，记待检验；实体硬件未操作、正式数据库/状态未改。
