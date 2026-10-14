# TRACK4-WRITE-BEAT-FIRST-001 v1：共享写接口组合选择树

2026-10-11。短变更卡；仅组合结构调整，数值、事务、周期及外部AXI行为保持。采用用户既有自主实施、本地审计及免新增独立测试授权；不伪记指定版号的人类批准。

- Goal / Current / Gap：052综合和容量通过（60224/60800），真实布线失败。现正文先六路512bit掩码OR，再选四拍之一，形成中央宽互连。
- Baseline：053冻结输入；pair service `A1E79B0C165B9836095A0B044BE95404601B3D1469493F178C1BFC7F7BCBA80B`，bridge `D2DD3EF2DCF6CDD69AB4C83C01148E576E12CD90BCF2C6E73B510AEA9449F7D6`，hub `6F64E2E8E7ED945A32B48FFA0AC2B055617F5E2BC626507BA85329A59A8A9C87`。
- Target / Scope：只改独立候选的上述三文件；主板profile开启，默认通用profile保留。052/053冻结flow、031交付包、原HDK和正式状态不改。
- Interface：pair新增默认0参数BEAT_FIRST_WRITE；bridge新增默认0参数EXTERNAL_NARROW_WRITE、128bit输入line_wdata_beat、2bit输出write_beat_index（直接现beat_index寄存器）。hub仅在FLAT_WRITES和BORROW_WRITE_BODY同时为1时开启新参数。
- Composition：新bridge旁路仅在EXTERNAL_NARROW_WRITE、BORROW_WRITE_BUFFER、USE_RAM_WRITE_BUFFER、NARROW_RAM_READ全部为1时替代动态切片，其他组合均走旧路径。旧512bit端口及正文合法性检查保持。
- Local：24个控制分别为原picks[source]与拍号匹配，mask六源各四个固定128bit切片后OR。分配律保证每位等于原六源512bit OR后取该拍；保留多热OR和零选择，不改为优先选择，不额外对六源各建动态四选一。
- RTL：core上升沿；接受沿仍锁owner/flat mask、桥拍号置0；AW/W/B/REPLY状态、valid/ready、背压、真实Wfire推进、错误/UNKNOWN保持、复位和源正文寿命均不变。拍号来自寄存器，新data不参与ready/状态，不存在组合循环。
- Resources / Open：新部分0FF/0RAM/0DSP是结构判断；LUT与路由实际变化须MAP/PNR，不保证改善。不能据假设删除任何功能或放宽时序。
- Steps / Milestones：候选三文件→静态等价/保持检查→采用→新的整机MAP/PNR/最终STA→实际通过后bit登记。当前不启动任何硬件动作。
- Validation / Trace：用户要求完整整机可实现→共享写接口结构→三文件generate/固定切片→新run输入哈希/实际资源/布线报告；独立测试不新增，已有静态生命周期审查沿用。多热/零mask、四拍索引、背压、UNKNOWN以及通用旧profile为走查边界。
- Failure / Rollback：保留053前源码及候选差异，失败只回退此结构；053按原冻结输入继续，不因等待重启。真实失败输出保留。
- Review / Completion：组合接口、逐拍保持、泛参数条件由根及独立审查核查并读回；没有影响本局部正确性的TBD。软件成功需实际新run的容量、布线与最终时序；完整识别及实物观察仍另列未完成。
