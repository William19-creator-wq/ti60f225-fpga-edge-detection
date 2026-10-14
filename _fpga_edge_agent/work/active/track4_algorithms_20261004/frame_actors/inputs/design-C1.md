# FRAME-ACTORS v1 验证订正 C1

2026-10-10。原 actors_small_001 已实际通过（20并行图像、1已有Source重处理、8协议场景），原源码快照和结果保留。审查发现：Full只生成一个算法图案，TB的next_id取模会使采集B复用A的handle/scope，不符合本卡FA01中“下一帧独立身份”场景。小尺寸20图案没有此问题。

订正范围只在新TB和独立参考：Full另生成一个只用于采集B的RAW/CFA参考，B采用下一frame/handle、Bayer1、Source slot1及独立DB区域；不重复给B生成完整Canny期望，不改变正常算法图像数量或生产RTL。B的真实Source字节必须逐位符合独立CFA，cap DONE handle/scope匹配B；A的算法读回/梯度/class/BFS/result保持原期望。采集B的RAW采用二维独立图案，不以DUT/旧Source回读当期望。

同一沿规则、接口/组合、数值/错误/复位、100MHz组件范围和原FA01..08均不变。该问题属于测试输入缺陷，不能把原单图案重复身份当全尺寸帧间并行证据。修改后重新执行当前53份源的小尺寸、最小尺寸和完整HD，再据当前sim清单综合；原small_001只作为旧测试源码对应证据，不冒称当前测试未变。

冻结清单说明订正：原卡A的“9适配参考旧RPC/top/…”实际56输入清单使用旧RPC/hub/TB/BFM/模型/sim/map/XML/SDC，旧top没有用于新生成的组合顶层；hub原件作为逐字复用生产输入已冻结。实际baseline.json的56项和48runtime是权威清单。本卡不追加生产依赖，也不替换或改写原冻结输入。

语言：Python3.14二维CFA，RAW范围0..1023、uint20两lane；SystemVerilog TB以负的测试ordinal选择独立B输入文件，此ordinal不进入生产端口，负数不参与地址/身份运算。交接条件：生成capture-b.txt/raw/source.bin先完成，TB再选择它；audit只将actual SourceB与该文件比较。中文草图：Full计算新的frame/handle→生成独立RAW/CFA bytes并A64补零→TB加载独立B任务→真实W构成DB→真实cap DONE和实际DB dump→独立比较。非Full继续使用下一图案任务。

追踪：FA01/02/05→load_capture/read_case/normal与generate/audit→FA-T2真实不同身份并行；其它当前小尺寸回归防测试逻辑回归。已保存读回，按用户已有自主执行授权进行验证修正，不索取新的批准、不改正式Manifest/数据库或硬件状态。
