# RGB 源帧写入 v1.1

基线 `RGB-SOURCE-WRITER-BL-20261009-v1.1`，12份冻结输入；持续自主授权和本地审计。先读 planning 的整体设计 v1，再读 v1.1 的组拍语句组织修订；随后阅读 rtl/rgb_source_writer.sv、rgb_source_ram_word.sv、model、tb、scripts、project。旧运行和原 HDK 不改。

## 中文内部草图和接口交接

job 接纳时锁 base 与 64位 handle，核对完整 A64=64ceil(3WH/64) 授权区。canonical RGB48={R1,G1,B1,R0,G0,B0} 在输入真正握手后重排为连续 R0/G0/B0/R1/G1/B1；例如445566112233变为DDR字节11/22/33/44/55/66。carry容器和新6byte组合成112bit临时值，每pair最多写一次64bit RAM word，余下carry在跨bank时保留。

两bank各128×64word=1KB，四块512×20 RAM10，最高16位恒0。FREE分配→FILL实际WE→SEALED不可变→DRAIN读出；只能在最后一条真正成功回执及全部pending/packet借用关闭后FREE，不在最后RE或最后W时提前复用。EOF先append实际pair，再补carry和A64范围内的零；最后partial descriptor为整64B，不发空请求。

两个packet各明确512bit寄存器，先预约，再从同步RAM读取8个word。旧read_pending沿接旧Q，8项固定case写切片；新RE可同沿继续。第八个返回后才发布packet；公共512bit请求从REQUEST直到真实response都保持body。slot只有回执才退休。旧RAM返回取消时登记DISCARD一次，不凭清数组伪造关闭。

坏输入实际accepted一次但不append；bad/handle/坐标/marker优先。取消停止新私有动作，已经公开的line继续排空；真实内存错误优先取消。drained0保留owner并隔离，无安全done/job-ready。done是局部写回终态；外层还要RX closure、DDR phase fence、FM源发布。

## 已执行测试

| 最终运行 | 数据与覆盖 | 结果 |
|---|---|---|
| source_small_004 | 34×19，6模式，7取消、4坏输入+写回错误、未知drain、held回复/终态、32位合法端点 | 全字节及padding一致，16协议场景 |
| source_minimum_002 | 4×2，6模式 | 最小几何与A64 padding一致 |
| source_6x5_002 | 6×5，6模式 | carry和padding一致 |
| source_bank_eof_002 | 512×2，6模式，L=3072 | EOF恰整bank、两bank满及复用一致 |
| source_partial_bank_002 | 510×2，6模式，L=3060/A=3072 | 最后carry与padding、两bank满一致 |
| source_hd_002 | 1920×1080，独立空间RGB图 | 1,036,800 pair、6,220,800B、97,200条实际成功line，全部一致 |
| source_postmap_hd_001 | 直接加载source_map_002的实际.map.v和官方FF/LUT/ADD/RAM模型 | 同一完整1080p所有6,220,800B一致，1,388,252时钟，与RTL同场景相同 |

source_map_002的Ti60F225/I3实际组件资源：4 RAM10、1512 FF、2006 LUT4、55 ADD、0 DSP。source_map_001的动态数组部分写产生非驱动接地警告，未作为合格登记；v1.1改为两个明确寄存器及固定case后该警告消除，综合后全帧实测通过。small_001/002保留测试端推进和故障注入时序修订前的中断记录，不覆盖失败。

## 人工复跑和边界

先以全新RunId运行scripts/run_source_sim.ps1（可Width/Height或FullHD）；检查suite-result/reference-audit/actual-results和源hash。随后run_source_map.ps1引用通过且源码相同的SimulationRun。最后run_source_postmap.ps1引用实际MappingRun，在固定生产1920×1080参数下验证整个综合后电路。project/rgb_source_writer_component.xml可在Efinity打开Ti60F225/I3组件工程。

实际.rgb是连续RGB和授权padding，可供离线观察；不是发送给HDMI的TMDS流。综合后仿真没有SDF，不证明静态时序或实物DDR动态正确；本组件100MHz SDC只给目标。生产引脚/PNR/STA/总bit、AXI桥、RX closure/FM发布、不可反压CSI/FIFO/CDC和帧率性能仍在后续整体工程验证。
