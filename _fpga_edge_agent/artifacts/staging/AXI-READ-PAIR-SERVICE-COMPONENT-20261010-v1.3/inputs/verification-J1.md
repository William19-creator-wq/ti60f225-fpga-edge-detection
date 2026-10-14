# 联合读服务 J1：复位观察与通知先于旧尾

2026-10-10，v1/T1 的验证实现修正，生产 RTL/接口/预算均不变。READY_FOR_REVIEW，按持续自主软件/local audit授权执行。pair_service_001真实compile/elab与vsim退出0，TB38场景8325沿完成，但audit在首个rst=1行读取尚未经过复位边沿的Q=x而失败；保留原失败文件，不能称整包PASS。

整体：共同同步冷rst首沿前保存FF尚未知，只契约化禁止握手；正沿后建立初值。检查器先判rst，验证所有rst门控握手为0、作废明示共同cold的应用/物理记录，再解析非reset的Q字段。不把复位前x转0或允许正常阶段x。主RTL不改。

局部：独立应用账与物理账分开。物理AR接受时保存对应应用身份引用，其生命至可信尾或共同冷reset；Q通知已被应用取走不表示物理归属消失。RF从物理账绑定的旧应用重建数值，不从当前应用表为空推断closed。busUnknown始终保留，非reset各Q/occupied严格检查，所有完整正文/数量仍核对。

测试：wrongRID及lateLAST先消费真实UNKNOWN/drained0通知，再发送正确ID旧尾，确认旧R仍可流动、busQ/occupied保留、新申请仍禁止；早LAST保持真实leaf停止Rready并消费notice。保留38场景和所有正常/边界/背压，增强次序而非删除场景或降低门槛。TB finish_outputs后不得再次等待已消费的通知。

RP03/04→物理账身份/通知与尾交接→reference bus保存app及reset解析、fault_case通知次序→RPT5/6。冻结原9+本J1=10，sim输入守卫仅9→10；MAP源快照仍10。保存/读回/呈现后修改，保留失败及旧baseline9。无新DDRx/PNR/STA/bit/硬件证明；理解验收待用户作答。
