# FIT v1 实施实录

授权：当前用户「批准」，对应FIT v1、45项基线和本批本地审计例外。设计、基线及旧三份RTL保持冻结。只写独立work，本轮未联网、未改正式数据库/状态或原资料。

已生成19份业务文件及中文阅读说明。首次父/桥/pkg编译0错误0警告；独立手算/表示探针通过。`fit_suite_001`的helper、真实/隔离bridge和fatal退出探针通过，core在sequence124的TLS竖直线case失败；没有声称该attempt或整包通过。

`fit_field_diagnostic_001`保留原失败并加一条字段观察。记录显示当期payload的Sxx和直接pf返回均为0，但组合命令仍带上一笔Sxx=2。随后将pf改为显式payload输入，消除嵌套task/function隐式消息依赖；数学、接口、槽/缓存结构、首错和预算均沿获批v1。这是使实现符合原草图的内部修正，不降低要求。诊断临时打印已移除，失败证据仍在旧attempt。

`fit_suite_002`的14517数值已完成，随后reset TB在解除rst的同一时刻立即读quiet而误判；加组合稳定采样后，`fit_suite_003`完整通过。没有把失败attempt冒充PASS。

首次Map（fit_physical_001）exit0，FF9388/LUT44488/ADD4682/DSP8/RAM0，未布局/未发布。资格检查按qualification-operation-sketch等价改用192位规范候选与完整385位比较；未改变精度、接口、状态或存储。

fit_suite_004在实际进程消失后确认为INCOMPLETE_INTERRUPTED，未取得退出/完成证据，原文件保留。恢复核对19源及45输入零漂移，runner增记精确PID/创建时刻/argv，便于后续恢复。

新增缓存定向检查的首次失败来自TB将ADVANCE索引6误写为QUALIFY_RETURN；取消实际发生在安装之后。cache_diagnostic_001记录cache1/关闭3沿，未把这当新RTL错误。改用枚举名后cache_diagnostic_002五场景及108笔真实私有调用独立审核通过。最终新增桥最大值/最负值/延迟quiet检查，fit_suite_007完整通过：14517数值，37取消，35在途reset，5缓存，34桥，1056来源/响应/CRC；11/6/19状态均观察到。原3份RTL字节仍一致。

第二次Map（fit_physical_002）exit0，FF9388/LUT41644/ADD4294/DSP8/RAM0；LUT减2844、ADD减388。这是综合证据，实际XLR、布局和时序仍须后续检查。source-manifest绑定fit_suite_007的19文件，SHA39E22F01FB43ECC68411A5E8307741BA2F056103914D69BC7B504888247F12D9。

后续：处理实际失败，闭合仿真及协议证据后执行同源Efinity物理验证。资源/时间候选仍按v1：XLR≤50000、RAM0、DSP≤16；25MHz、内部未约束0、setup/hold非负、实际数据D路径。未经这些证据不生成bit。

第三次物理attempt fit_physical_003绑定fit_suite_009；Map为7984FF/33933LUT/4294ADD/8DSP/0RAM，Interface通过。PNR实际exit0，50661/60800 XLR（83.32%）、routing8585，setup20.552ns/hold0.035ns。可装入芯片，但仍超过批准50000门槛661，没有bit。

独立Sta首次失败因work_sta缺路由trace。sta_repair_001复制原trace后成功读取路由数据库，但端点OR正则失配，退出1。两次都不是时序通过。内部脚本按FT-T10改为原trace复制及单模式分别查询后合并；新sta_repair_002只诊断旧003路由，不作为新源的发布证据。

placement-operation-sketch第二轮草图先保存/读回，再按原u21/u19局部子运算宽度实施odd/q±1的显式扩展，原完整385返回及192资格/槽不改。TB增加最大值进位与每次真实局部提交的原192位表达式对照。新完整attempt fit_suite_010进行中，后续物理验证必须绑定其全部19源；没有扩大行为、接口、状态、存储、缓存、数值精度或目标分辨率。

fit_suite_010完整PASS，14517数值与原全部协议/来源审核不变，额外28804次完整192位局部提交等价。sta_repair_002退出1：accepted_command逻辑名实际被保存为child_req_body接口别名。对实际map.v FF读回后调整命令/结果别名和cache工具生成前缀；仅查询派生sta_query_003退出0，12对端点均非空。完整值返回再限定child_rsp_body[200…584]；K/M缓存名加数组开括号以排除cache_key。011因支持脚本最终收紧主动中断并保留，不计完整PASS；新的最终19源全套attempt为fit_suite_012。原数学、RTL和已通过010数值字节不改；重新运行是为了绑定所有运行支持与工程文件。

fit_suite_012完整All/finished/PASS，source-manifest SHA24B95D66C244D36FF9195B94357277DC6285B0CBD645C42B80F52C070553A1B3。14517/37取消/35复位/5缓存/34桥/1056来源与CRC/28804局部等价均实际通过。物理004第一次调用因probe尚未完成、suite-result未落盘，被前置门槛拒绝，未创建物理目录或调用Efinity；等待整套结果后才重试成功。

fit_physical_004绑定012，Map实际exit0：7990FF/33221LUT/3718ADD/8DSP/0RAM。较003 LUT−712、ADD−576、FF+6，不把它当最终XLR。Interface实际exit0，PNR进行中；后续STA及发布按实际结果记录。新的mapped-data-register-review.json读回实际FF名字，防止再次借逻辑名猜测端点。

004 PNR exit0：48329 XLR（79.49%）、routing7537、RAM0/DSP8，setup20.721ns/hold0.035ns。较003少2332 XLR，通过v1的50000门槛。独立STA exit0、610.286秒；12对数据端点及28份数据/复位报告、内部覆盖0、四pin均读回通过。发布审核首次严格flow XML字节比对发现工具格式重排，未写发布PASS；随后逐节点/属性/文本/顺序比较证实全部配置语义相等，保留两个实际hash。不放宽RTL/SDC/peri字节一致要求。正式release-gate PASS绑定49份证据，随后启动Bit生成；未做硬件操作。
