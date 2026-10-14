# SCAN-002 未知DDR响应传播检查 Q1 v1

现有四套边界联合测试已实际PASS；HD和MAP确认为正在运行（Questa PID20748、Efinity PID9380），不修改其28份运行源、31份MAP快照或基线v1.2。当前ST24的未知响应传播仍未在组合顶层动态检查，本补充完成这项，不以正常通过替代。

边界/要求SC27：真实标准AXI收到了错误RID，prefetch应隔离、组合Q应传播，candidate取消不得返回closed1，未闭合/未发布源与结果保持实际owner OFFERED及Source pin。不是软件超时造释放、不是强制RTL内部Q。输入来自实际axi_read_byte_slave既有fault_mode=1（本地源码将再核读确定编码），非DDR PHY证据。

组合和局部：新增独立tb/tb_scan_faults.sv一份，共同安全初始复位→真实owner ALLOC_SOURCE/EOF/END→ALLOC_RESULT/END/OFFER，固定合法mode1、W20/H8数学Source→真实control HC_OFFER→core lookup只在真实owner OFFERED保留且全文匹配才授权→真实AR/R握手注入既有slave错误RID→观察至少一个actual wrongRID握手、组合Q、原服务引用live。随后匹配sequence cancel，继续64+周期及VS消隐tick；任何control response/oldClosed/candidateClosed/free source/result都是失败。保持未知债/引用，写EXPECTED_QUARANTINE事实后结束软件仿真，不作硬件观察或reset清义务。

RTL不变，仅测试源码；TB刺激negedge、真实握手posedge，multibit全宽；不存在TB prepared/closed赋值。测试成功要求actual wrongRID而非设fault开关本身、Q及阻止释放同时成立，独立行政审计读真实AR/R/owner事件与最终metrics，owner原参考重放全部实际命令。原子运输/复位/数值契约沿v1.2；最后明确未知AXI未闭合，不能算安全排空。scope_fence未知输入从实际prefetch/global传播，不由TB输入强制。

验证入口使用现有Questa逐stage管理员调用，完整PID/argv/源码快照/stdout/stderr/exit/finished保留；不另复制一个运行器。现有Python owner参考原样执行，本检查日志另独立核对初始/最终状态和RID。原正常/HD/MAP源无漂移。baseline v1.3=原27冻结输入+本卡=28；当前自写9→10（增加1 TB），复制依赖22不变。

中文操作与双向：SC27→IF22/25/E3 core_fault→真实AXI错误→组合Q/无关闭→tb_scan_faults实际脚本与记录→ST24。READY_FOR_REVIEW Q1 v1，持续用户自主软件授权及本地审计例外覆盖，保存读回呈现后实施；不要求再批准、不假称整体任务或DDR动态已完成。
