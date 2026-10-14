# 点集统计到 FIT：代码阅读与操作草图

2026-10-08；STATS v1.1已通过FAST批次批准，22份文件已生成。最终仿真为runs/stats_suite_005，物理stats_physical_002的Map/Interface/Pnr/Sta/Bit全部退出0；bit/hex已生成，紧接本次文档更新登记至ALGORITHM-R4-STATS-20261008-v1，实际状态/hash以manifest为准；未执行硬件操作。

阅读顺序：[整体/接口/局部原设计](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R4-STATS-001.md) → [字段与资格](../rtl/stats_protocol_pkg.sv) → [统计流水线](../rtl/stats_core.sv) → [真实来源、交接和观察](../rtl/stats_probe_top.sv) → [独立数学](../model/stats_reference.py) → [测试场景及来源审核](../model/stats_vectors.py) → [core/真实FIT测试](../tb/tb_stats_core.sv) → [probe及序号尾域](../tb/tb_stats_probe.sv)。

## 整体和接口

来源先START锁W/H/kind/threshold/ID/E，然后按(y,x)严格递增发POINT，最后同ID END或ABORT。token262、STAT632、原NUM622、原RESP585分别解释，不能混用。include0仍是扫描记录；valid0是气泡。stat_valid公开后正文保持到stat_ready。

core只做集合统计，来源负责选择哪些点include；原FIT负责退化、条件数、几何求解和诊断。少点/空集合是合法统计VALUE，仍真实交给FIT，由FIT判LOCAL_COUNT。这里没有候选选取、圆/矩形分类或DDR对象释放。

## 内部次序

stats_protocol_pkg按位图→START检查→完整s57资格→NUM打包组织。qualify_commit把n资格放在五项字段资格之前；任何失败整点不提交。五槽的真正目标宽度随LS/TLS模式检查，不能先截到字段再检查。

stats_core先声明拥有者与四级寄存器，再计算当前token资格/完整贡献/完整候选，最后一个时序块更新。POINT在t0存S0的a/b/x/y/中心坐标，t1存五个乘积，t2形成d，t3形成ad/bd，t4同时提交五槽和n。每级只依旧valid使用旧数据。raw_seen按真正POINT fire推进，included_count按合法提交推进；两数不能互代。

同ID合法ABORT优先抑制本沿提交；旧提交资格错误早于当前新token错误；已有首因保持。END只关来源，不清流水线，DRAIN排旧点，PACK读取上沿最终统计，再HELD等待消费。没有关闭的源不会因为点数够了就被伪造终态。

probe三个拥有者分别是token来源、STAT→原FIT注册交接、585bit观察。source_lfsr只在POINT真正接受时推进；公开POINT不能因fault重写。错误关闭后不发FIT，合法STAT则把真实622位请求交给唯一原FIT。真正rsp_fire/observer_fire后才移交共享响应字；连续585沿移位完成CRC，才允许下一START。

原scalar_protocol_pkg、fit_protocol_pkg、scalar_core、scalar_bridge、fit_core、reset_sync和fit_reference保持原字节。没有复制第二scalar实例。

## 当前验证和复现

stats_suite_005覆盖1024个常规集合、固定非法字段/退化/取消反例、四次完整1080p POINT扫描，补有ABORT与第一提交同沿、DRAIN/PACK/HELD复位及新尺寸/kind/ID恢复。核及真实FIT组合分别比较完整STAT/NUM/RESP；原始33字节实际fire流保留并逐字节核对。

pipeline账核eligible=commit+discard+reset_aborted；请求账核accepted=STAT consumed+reset_aborted；probe另核token/STAT/NUM/RESP/observer/CRC的真实事件。probe为64job+reset4job，尾域实例从MAX−1真实执行两job后HALT。恶意无界源的PROTOCOL_STUCK保留设计/静态守卫，未把它写成已动态覆盖。

Efinity打开project/stats_probe.xml查看九RTL、Ti60F225/I3、四pin25MHz配置。复现工具操作用scripts/run_stats_sim.ps1和run_stats_build.ps1，以新RunId保留日志。Questa首先看token_valid/ready/op、raw_seen/included_count/pipeline_valid，再看stat_body、request_slot、fit_rsp_body和CRC；先定位原ID与ordinal，再看数学字段。

ST01/06/07→core状态、probe拥有者→T05…08/11；ST02/03/08→四级与qualify_commit→T01/02/09/10；ST04/05→字段/include/622交接→T03/04/09；ST09→独立参考、四TB、三个runner/工程→T09…12。物理结果及bit登记完成后补入实际路径，完整十一项和整体共存性能另闭合。

## 实际物理证据和登记

最终仿真：1,084集合、8,337,408 POINT，core与真实FIT组合分别逐位比较；1,046真实FIT调用，关闭最慢5沿；pipeline账eligible=4,167,243，committed=4,167,214/discarded=24/reset_aborted=5。probe及尾序号MAX−1/MAX均通过，PROTOCOL_STUCK恶意无界源仍仅静态守卫。

stats_physical_002：Ti60F225/I3、25MHz，52,619/60,800 XLR（86.54%）、0 RAM、12 DSP；setup20.917ns/hold0.089ns，内部无时钟/未约束/多时钟均0。40份实际数据/复位setup和hold报告非空、slack非负，DSP中的S1/S3寄存器按实际cell检查；子运算的返回源为fitting/child_rsp_body（response_value映射名），不能从full中间结果越过寄存器检查。

原stats_physical_001的FF-only检查失败及sta_mapped_002少一组实际返回路径的尝试均保留；没有覆盖旧失败日志。最终脚本和source快照一致。四pin实验：J2参考GCLK/1A1.8V，P13 key1_n/N14/P14 LED为BR3.3V/4mA。复位只有两级异步SR例外，未切真实级间/到core数据路径。

[本包登记manifest](D:/大三/FPGA_verilog/_fpga_edge_agent/artifacts/staging/ALGORITHM-R4-STATS-20261008-v1/artifact-manifest.json)记录22份源码、完整仿真、40份命名物理路径和bit/hex。原输出保持。独立包资源已经很高，后续全机需去实验观察源、共享/压缩拟合与宽运算，再实际综合/布线，不能从独立25MHz通过推定整机100MHz或全部算法同时装得下。