# TRACK4-CAPTURE-DISPLAY-HUB-001 v1.4 / J2：公开总线采样沿与独立审计恢复

## 整体与具体失败证据

HD_001的真实RTL仿真退出0、未超时，完成38474363周期；全部1036800对RAW/FP、2073600像素结果及两遍6220800字节旧Source已在独立审计的图像部分比较通过。随后总线账在cycle3394的OVERLAP标记失败：3380已接受AW，3387旧display RLAST，3393接受新的display AR；3394收到匹配B，同时记录数学slave的并行标记。沿前读与写均在途，B交接之后写已关闭。原检查器先处理B再检查标记，仅用沿后状态，错误否定了合法沿前并行。

这只修独立观察的采样解释；RTL、TB、所有物理响应、数值及图像生成、实际MAP工程均不变。不能删除真实总线数据核对或把旧FAIL改成PASS。完整目标仍为全部五基础六高阶生产FPGA，当前组件登记仍等待完整独立审计。

## 局部语句与不变量

按case/cycle分组公共账。进入一个新采样沿时，保存由先前真实AW/AR及B/RLAST重建的读/写在途布尔值。该沿按既有顺序核对全部物理数据、BID/RID/LAST/范围，再处理OVERLAP：须沿前两个归属都在途，或当前沿真实接纳之后两个归属均在途。B完成所在沿允许标记表达沿前状态；不允许凭标记制造任何新归属。

另独立累计具有记录的沿前双归属证据，要求大于0，不以数学slave内部状态或PASS字段作为证明。所有完整128bit R/W和请求身份/范围、字节效果、33类公共协议审计、所有数值图像比较保持原样。

## 恢复已有仿真的严格范围

既有run_capture_sim.ps1增加可选ReuseSimulationRun参数；默认仍执行全部生成、编译、展开、两个fatal探针、hub和capture仿真及独立审计。恢复只允许旧generate/vlib/vlog/vopt/fatal_probe/hub_vopt/hub_fatal_probe/hub_vsim/capture_vsim全部真实终止、无timeout，fatal为失败退出且含实际标记，其余退出0、日志SHA匹配，旧两个finished metrics为true。原suite允许仅因audit失败；不接受RTL仿真失败、仍运行、丢失日志或源码漂移。

当前52源快照仍建立并hash检查。旧52快照逐份hash检查；除独立审计model和运行组织script外，另外50份actual RTL/TB/native RAM/六参考依赖必须与当前逐份SHA相同。旧与新model从文件开头到audit_hub声明之前（imports、generate_capture/layout/generate等）规范化换行后逐字相同，证明同源RAW/CFA/R2/BFS和图像生成未变。尺寸、full和实际采集protocol选择与旧向量/metrics一致。

新独立run复制旧顶层完整数据、vectors、public traces、metrics及过程证据，逐份记录原路径/副本SHA；保留旧52执行source manifest及快照哈希关系，新的52审计源单列。写simulation-reuse.json明确原run、两份改变仅为审计/组织、50份不变和生成前缀相同；运行新独立audit并当前源/快照检查后，新的suite可以PASS，同时明确simulation_reused_from与完整真实执行出处。原HD_001/small等suite及所有记录保持原状，不能把审计重放说成重新仿真。

先新attempt重审计HD_001及保存公开账，再当前版本正常运行小图/6×5。最终组件MAP以当前HD审计恢复PASS的52源建立55源工程快照，保证最终归档有当前验证源绑定。重复综合用于闭合已修订验证源的最终登记关系，不是声称RTL资源发生改变。

## 门槛与追踪

DH03/IF4→公开AW/AR建立、B/RLAST关闭→采样沿前/沿后账→J2正常B完成反例及全HD全部事务；T1/T2/T3/T4/T5其余要求保持v1.3。恢复不得改变失败/结束定义、UNKNOWN旧borrow、参数、图像或物理动作。副本只在新work run，原失败保留；正式DB/H0/硬件不改。

本卡加入第58冻结输入，原57baseline另存inputs/baseline-v1.3-57.json；45runtime、10自写、52仿真/55MAP数不变。READY_FOR_REVIEW v1.4，先保存读回并呈现，再按用户持续自主软件和本批local audit授权实施。无新的功能或硬件授权请求。
