# FIT v1 软件验证证据

授权版本FIT v1，输入基线ALGO-R3-FIT-BL-20261007-v1（45项）。当前软件attempt：runs/fit_suite_012，完整All/finished/PASS，源manifest SHA24B95D66C244D36FF9195B94357277DC6285B0CBD645C42B80F52C070553A1B3。19份源在开始/结束两次hash一致；三个原RTL严格原字节。局部软件证明，不是整包、实机或识别质量证明。

| 观察 | 实际证据 |
|---|---|
| 七kind数值 | 14517笔完整585位比对；11/12/13/14/15/17/18分别1064/1060/2064/4129/4122/1039/1039 |
| 形成时间 | 独立审核最大8234 core沿，测试上限16384；25MHz对应329.36µs，仅单笔数值形成，不是帧FPS |
| 流控/取消/reset | 37取消、35在途共同reset，父11/桥6/原child19状态均观察到；HELD旧body保持 |
| 外部真实义务 | accepted14594=consumed14559+reset_aborted35；最终live0 |
| 私有真实义务 | accepted321326=consumed321307+reset_aborted19；每笔原始primitive响应用独立整数式核对，最终live0 |
| 缓存定向 | 取消同M资格沿不安装；cold miss22调用；跨frame/rho/point hit18；TLS规范安装后hit18；reset清valid |
| 桥独立检查 | 34项、真实child调用24、隔离fault调用9；静态MAX−1尾域2次真实调用后CAPACITY；完整385大值/最负192及quiet延迟257沿 |
| helper政策 | 192项等号/奇偶政策及完整高位、typed边界、normal输入域；人工等号不混为主几何真实half覆盖 |
| 真实硬件源/消费 | 1024笔+reset后32笔；完整622来源/585响应/逐位CRC独立审核；VALUE577/LOCAL238/FRAME_FAIL241；最后CRC74096f9d |
| 致错退出 | expected FIT fatal probe退出1、finished未置位，不生成成功结果；常规完成及独立审核均退出0 |

阅读原证据：runs/fit_suite_012/source-manifest.json → suite-result.json → core/probe-audit.json → 原stdout/stderr/result及vectors/manifest.json → numeric-observed.tsv、outer/private-events.tsv和probe-observed.tsv。两种身份域命名outer_fit/private_scalar，不将相同176位模式混为一个事务；J是无在途共同cold reset，Z才计reset_aborted。

009额外在每次私有和局部槽提交检查声明typed宽度覆盖、优化表示与原完整192位逐位相等。原16×192逻辑接口/算法不变；不是丢弃高位求近似结果。

012保留全部旧检查，并核28804次LINE/FINITE真实局部提交与原192位表达式逐位相等。u21相邻数最大值进位保留为u22并由原u21资格拒绝；u22/u20奇数边界及零特例单独检查。010同RTL全套通过；011为支持端点最终收紧而主动中断，记录退出−1，不计PASS。

数值输入包含独立图内点集、宽typed合成统计和完整1080p坐标域。复杂识别目标旋转/遮挡/重叠/负图及原性能要求由后续整包验证承担，未用这些数值向量代替。

fit_physical_002 Map为9388FF/41644LUT/4294ADD/8DSP/0RAM，Interface通过；Pnr需要62814/60800 XLR而失败，未发布。003 PNR完成但50661 XLR超过50000批准门槛；独立STA支持诊断失败保留。当前完整19源的物理attempt为fit_physical_004，绑定012；Map/Interface/Pnr/Sta及bit登记按实际结果另记，未完成前不写PASS。

004的Map、Interface、Pnr、Sta全部实际exit0。最终48329/60800 XLR（79.49%）、RAM0、DSP8；25MHz setup20.721ns/hold0.035ns。独立STA实际610.286秒，12段数据路径共24份setup/hold报告，另4份复位报告；28份均有实际非空路径和非负裕量。12段目的均为真实FF的D端、Data Path实际含Q；结果只检查完整值域、缓存只检查K/M数组，没有用CE/CLK/SR取代数据路径。

内部no_clock/unconstrained_internal_endpoints/multiple_clock均0；完整覆盖只列KEY输入和两个LED既有例外。两个异步SR网络实际key1_n；级间Q1→D2 setup39.528ns。引脚实际J2时钟1A/1.8V/GCLK，P13 KEY及N14/P14 LED为BR/3.3V，LED驱动4mA。这里只证明四引脚独立probe配置，不代表生产相机/DDR/HDMI引脚。

source/snapshot全部19字节一致，实际7份RTL及peri/SDC也一致。Efinity重排flow工程XML的声明、空标签空格和末尾换行；解析后逐节点、属性、文本、顺序全部相等，真实工具文件及原快照各有hash。STA和PNR的vdb/place/trace/interface字节一致，work_sta trace也与原路由一致。physical-evidence-review.json与release-gate.json绑定49份真实证据；发布检查PASS后才启动Bit，生成和登记结果见最终交付。
