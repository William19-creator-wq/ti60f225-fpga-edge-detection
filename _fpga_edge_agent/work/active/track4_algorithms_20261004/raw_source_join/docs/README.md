# RAW10 到完整 RGB 源帧的同步软件组合 v1

基线 `RAW-SOURCE-JOIN-BL-20261009-v1`，12份冻结输入。持续自主授权；原HDK、两子模块及旧登记包不改。阅读顺序：planning/design-TRACK4-RAW-SOURCE-JOIN-001.md整体→本父RTL→RAW窗口/插值中文入口→RGB writer内部草图→独立参考与TB→Efinity报告。完整96位scope由父job锁定，不截为64位局部handle。

## 中文内部操作草图

IDLE实际job_fire锁base/handle/scope/phase，先CFG_WRITER/WAIT_WRITER核grant；合法才ARM_RAW，再RUN开放同步RAW pair。RAW实际行RAM与reflect101产生完整窗口，四相位插值RGB48，坐标/markers/handle直接交给writer。writer重排连续RGB，双1KB bank与双packet完成64B真实写回。

父分别消费RAW done和writer done，保存实际计数；两侧谁先结束都不能直接发布父done。RAW输入错误先关闭RAW，再匹配取消writer并等其旧公共请求。writer先错误安全结束时，父打开明确discard出口，接掉RAW已经公开而停住的RGB，再等RAW done。discard单独计数，不能冒充成功源字节。真ERROR优先父CANCEL，held父done全body保持。

未知drain立即隔离整个局部源上下文，停止新输入，不给safe done或新job-ready；外部共同安全复位才可恢复。最后DRAIN读取两closed事实和成功P/P/L/A/lines/discard条件，再输出局部done，仍不是FM COMPLETE或可显示帧发布。

## 实际证据

| 运行 | 几何 | 实际结果 |
|---|---|---|
| raw_source_small_001 | 64×32，四相位×10模式 | 40帧、81,920像素、245,760逻辑B完全一致；13协议场景、4取消、6错误，包括真实held RGB的失败discard；两个子done均出现先结束情况 |
| raw_source_minimum_001 | 4×2 | 40帧、320像素、960逻辑B完全一致；12协议场景 |
| raw_source_6x5_001 | 6×5 | 40帧、1,200像素、3,600逻辑B完全一致；12协议场景 |
| raw_source_seam_001 | 1040×3 | 40帧、124,800像素；跨RAW RAM地址511/512和源bank/64B边界 |
| raw_source_hd_001 | 1920×1080，四相位彩条 | 4帧、8,294,400像素、24,883,200逻辑B完全一致；每帧P=1,036,800，L=A=6,220,800，成功line=97,200 |

独立参考逐二维RAW窗口和CFA计算，随后只按逐像素RGB字节排列，没有模拟bank/carry/FSM。TB逐line payload与最后完整内存比对，所有请求/终态保持、实际accept、错误cancel ID、scope/phase提案变化、写回错误、未知drain及安全共同复位都检查。

raw_source_map_001在Ti60F225/I3实际MAP为8 RAM10、2487 FF、3009 LUT4、255 ADD、0 DSP。四幅1080p合计6,055,026时钟，单帧最大2,236,750时钟；包含测试端随机停顿及20拍写回回执延迟，不换算实物fps。

脚本run_join_sim.ps1指定新RunId，可Width/Height或FullHD；run_join_map.ps1引用通过且hash相同的SimulationRun。project/raw_source_join_component.xml包含父1份、复用子6份RTL，GUI deps镜像不是新增业务模块。runs和登记包保存源码、独立参考、各阶段日志、reference-audit及资源报告。

这是可反压、同clk、已解码RAW输入的软件链路。真实SC431HAI I2C/MIPI/CSI、非暂停FIFO/CDC、RX closure、DDR AXI与phase fence、FM冻结/恢复/发布、显示TMDS/标注、识别和整机资源/引脚/时序/总bit继续完成。此组件100MHz目标尚没有生产PNR/STA/bit，软件line模型也不是匹配2Gb DDR器件模型。
