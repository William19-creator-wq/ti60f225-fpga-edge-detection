# TRACK4-RGB-SOURCE-WRITER-001 v1.1：双packet显式寄存器与综合后字节验证

2026-10-09。沿用 v1 所有端口、字节数学、bank/RPC关闭、范围及用户持续自主授权；先保存读回此修订，再改组织并复验。原 v1 基线和失败/警告运行不覆盖，正式DB/硬件保持。

Goal/Current/Target/Gap：RTL六模式与最小/整bank/完整1080p已通过；Efinity map_001 报告动态数组部分写的 `packet_data__D` 若干非驱动位接地，实际FF少于双512bit holding要求。必须消除该不明确映射并用综合后的电路实际比对RGB字节；不能仅以MAP exit0闭合。

整体职责、接口、grant、marker、计数、取消、unknown隔离均不变。局部改为两个明确512bit寄存器 packet0/packet1，选择slot后按 pending_lane 的8项case写固定64bit切片；reset只重置这两个寄存器的内容，不清RAM。公共数据按packet_head选择，两slot的预约/发布/归还仍由原FSM控制。把数据寄存器独立always_ff，避免数组内动态部分写推断成多维逻辑memory。

中文操作草图：声明packet0、packet1；组合公开wdata=head?packet1:packet0；时钟沿安全旧read_pending且!stop_new时，先选旧pending_slot，再8项case选旧pending_lane，唯一对应切片接旧RAM Q。主FSM只拥有slot状态/计数，不再同时写packet数据。其它语句旧状态规则不变。双向追踪SW02→显式holding→原T03反压/双slot→T06 MAP警告检查及综合后实际字节。

验证计划：新RunId复跑34×19、4×2、6×5、512×2整bankEOF、510×2带carry与padding、1920×1080；在Ti60F225/I3重新MAP。另生成POSTMAP模式TB，只有公开端口检查，禁用RTL内部状态观察；固定生产参数1920×1080，用现有官方FF/LUT/ADD/RAM仿真模型加载实际.map.v，一幅完整帧的所有RPC和6,220,800字节与独立参考一致才登记。此为无SDF功能等价实测，不等同时序仿真、实物DDR或生产PNR/STA。

Milestones：保存/readback READY→8项固定切片→RTL复验→MAP→POSTMAP→归档。Failure/Rollback：保留map_001及small_001/002，无法匹配时继续修复不登记通过。Artifacts：原work/rgb_source_writer；新增postmap runner，基线v1.1添加此设计及4份官方宏模型。Human gates：无硬件操作。Open questions：本局部无新待批问题，实际DDR/CSI带宽与整机任务继续。
