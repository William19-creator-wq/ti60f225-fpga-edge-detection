# R1 v1.1 并行实现与验证实录

用户已批准R1 v1.1和本次本地审计例外，见[原始授权记录](approval-r1-v1.1.md)及正式Manifest scoped AP-ALGORITHM-R1-20261004-v1.1。当前本批DONE_STOP_AFTER_BIT；[中文交付及真实最终证据](../05_delivery/r1-software-acceptance-v1.1.md)另存。下文按历史时点保留原前缀，不能把其中“待运行”当当前最终状态；不是完整十一项完成报告。

Root实际完整重读R1 v1、旧22输入JSON与review-v1；逐份实际hash/大小发现21一致，唯一正式Manifest由1390B/A582…变化为5099B/A2CB…，内容是三个用户IP预检批准。保存该现版本冻结快照并修订22项ALGO-BL-v1.1；重新解析保存JSON，22份零不一致。新卡完整读回。完整R1 v1 F33A…和FRONTEND v1 45BBC…保持不变；有限修订卡仅治理证据冻结和并行说明，不改算法/外壳/数值/接口/预算。

| 对象 | 已读回/核对 SHA256 |
|---|---|
| R1 v1.1 修订卡 | DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0 |
| ALGO-BL-20261004-v1.1 | DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4 |
| 批准前Manifest冻结快照 | A2CB08F30903D9324CBCEB59631AA30D5001B4EE8745222B3A76DC5A12AA1E75 |

已读项目WORKFLOW及硬件节点Skill；按用户批准采用本地审计，正式数据库/H0/硬件节点状态不改。本地ASCII Work/Reports junction目标实际核对。原厂模型只读，没有新junction、安装/网络或硬件操作。

已创建批准的独立r1目录。Root生成line_store_pair.sv/window3x3_pair.sv/frontend_frame_pair.sv；另一方向实现三个算术RTL，独立方向实现两参考模型，测试方向实现五TB/runner。各自仅写获批工作根中的分工文件，未覆盖原HDK。源码不是已通过功能检查。

实际首个静态编译 run window_precompile_001：Questa vlib退出0；vlog实际编译原厂EFX_RAM10、line_store_pair、window3x3_pair，退出0/Errors0/Warnings0。完整日志在[work编译日志](../../../work/active/track4_algorithms_20261004/r1/runs/window_precompile_001/vlog.log)。这只是编译证据；vopt/vsim、FT-01…11、R1-T01…08、综合/PT/布局布线/STA/bit均尚未验收。现装efinity.exe --help退出0仅返回GUI选项，后续应按现装efx_run工具实际CLI，不冒称已构建。

后续纯设计的有限pin核查：POINT构造使用EDGE读、GRAD读、POINT写，属于RC对象集合的子借用；RC26 union、LOAD/GRAD3、CLOSURE3、SOURCE8、COPY2、camera3、四exec12、RECORD观察1、独立REPLAY3合计61只是新增候选额度算术，不是已证同时存活上界。权限转换、旧metadata/未知效果保留、camera future ARM实际holder/body与服务仍须冻结；RING_LATEST作为base保护不授读也不等于FREE。详细来源/读取范围将随后续卡保存，当前不把61当已验证资源结论。

接下来按成熟批次真实数值/协议回归推进，再做生产参数四pin工程、真实资源/PT/布局/时序。失败保留原日志并修正批准范围内问题，不生成成功bit；完整后续设计继续。原完整任务目标保持，未做实体验收或理解代签。

## 后续实际检查前缀（2026-10-05读回）

Root已完整读回三个算术RTL及六外壳RTL；core_precompile_001实际六核心vlog退出0、Errors0/Warnings0；r1_precompile_001实际12RTL加原厂EFX_RAM10 vlog/vopt退出0、Errors0/Warnings0，生产默认参数顶层实际展开成功。五前端TB/common driver由测试方向实际编译退出0，未据此推定功能通过。

首次vsim退出4是许可环境未继承，保留失败run。Root仅核Process/User/Machine配置存在性，未输出值：User MGLS_LICENSE_FILE是既有本地文件，Process缺失。按已批FE G沿用进程级本机配置、执行后恢复，不改持久环境或许可证。

Root实际读回window_smoke_002/result.json与vsim.log：W4/H3输入/输出/比较6组，numeric_errors=protocol_errors=0，finished=true；RAM reads16/writes10；首输入cycle2、首输出7、末输出12，符合D+3及N+D+2。最终Questa计Errors0/Warnings0，但正文有onerror/onbreak“for use within macro”警告，已要求runner写实际.do并保留该命令警告。只有这个窗口case取得当前功能证据，全套FT及R1工具/bit仍未验收。

原首次审计有缺失vlib空输出文件的无效hash条目；原事件保留，EV-ALGORITHM-R1-v1.1-AUDIT-CORRECTION-001明确修正：vlib实际空stdout现保存为0B日志，14份实际文件重新逐个核hash、无空hash。该纠正不改变编译结果，不删除旧记录。

## 最终并行收敛（2026-10-05）

Root已读回最终FE006（123/123，四完整1080p合8,294,400像素）、外壳005（两尺寸各69job/64配置、四258图样及typed/CRC）及物理005（Map/Interface/Pnr真实0、完整pin/STA/内部coverage），必要检查通过且源码对应。packed为3411 XLR、8 RAM10、0 DSP，40ns setup35.381ns/hold0.063ns。

首次Bit退出0但无产物实际登记FAIL_NO_ARTIFACT；修正仅明确绑定同run已布线LBF，bitgen_retry_001真实生成bit/hex，两份文件和staging副本大小/SHA一致。17份实现快照与22份批准输入零变化；release-gate及首次阶段/物理失败历史不改。正式PROJECT_STATE/TASK_LEDGER原hash保持、PG本地例外沿用，无硬件动作。

并行后续纯设计新增生产目录pin61与stage-holder复核：原共享M1可容三stage元数据2965bit，但需要真实REGISTER/权限快照、归还与LOAD/GRAD接线等合同；不把空间算术当整机可装下或吞吐证明。这些工作不生成后续业务源码，不扩张R1批准范围。
