# 实施记录

## 2026-10-18

- 复制154项上版构建输入及两份原有按键控制源码，全部核对SHA256；新增两份生产RTL。当前158项输入。
- 接线复核发现原refine与可用v7的复位键不同。保持v7 KEY0=C4复位，KEY1=P14新增加阈值，KEY2=N14减阈值，KEY3=A3模式；其余peri结构逐节点保持。
- 仿真第一次在中文物理路径下建立Questa库，vlog内部数据库无法打开。保留失败日志，改从已有ASCII目录联接运行，新的sim_control库成功；没有替换项目审计数据库或安装工具。
- 控制testbench初稿使用了SystemVerilog保留字sequence作为数组名；改为mode_order后重新编译并通过N=2/4/31的消抖测试。
- 完整1920×1080三帧逐像素参考通过，6,220,800像素、3,712,505个同步时钟检查；灰度/中值/差值三模式，字幕开启，帧中修改配置不影响当前帧，延迟4402拍。
- 首次Efinity map在解析工程XML时失败：新增design_file放在top_vhdl_arch等元素之后，不符合Efinity要求的元素顺序。移动到所有design_file所在区段末尾，保留失败map.out及旧输入清单；没有修改RTL数值行为。第二次map正在执行，结果以构建日志为准。
- 上一BRIDGE-001的五区实时变化和边缘对齐已收到用户明确确认，另行记录在该节点hardware-live-five-region-20261018.json；不把此反馈挪用为本按键版上板通过。
- 第二次map成功。Interface Designer还要求peri中的comp_gpio位于bus声明之前；初稿末尾追加节点不符合此顺序。调整三节点位置，逐节点核查其余外设完全不变，仅重跑interface/pnr，不重新执行已通过且输入未变的RTL仿真。

- Interface XML order correction: vendor pt/bin/schema/gpio_design.xsd lines 18–35 requires all comp_gpio before global_unused_config, then bus. Moving only before bus was insufficient. Three new GPIO nodes moved before global_unused_config; no attributes or baseline GPIO changed. Previous failed evidence retained.
