# A64帧账本与完整显示扫描

阅读顺序：[整体、接口和中文操作草图](control/design-v1.md) → [组合顶层](rtl/display_owned_scan.sv) → [显示组合](rtl/display_scan_component.sv) → route/handoff与prefetch → `deps/display_row_reader.sv` → 原native/video/fence模块。所有原始副本和依赖SHA在 `baseline.json`；本包不改旧work或HDK。

```
唯一真实帧账本：OFFER绑定sequence、完整FrameRef逐次查询
                          ↓
跨域handoff → 真实row0准备资格 → 消隐VS切帧
                          ↓
A64描述校验 → 16B AXI行读取 → 三native行银行
                          ↓
视频固定扫描 → 六种显示模式renderer
                          ↓
旧FrameRef实际scope fence → closed → 实际RETIRE
```

这里的64字节是帧空间分配粒度；AXI仍是128bit/16字节一拍，行跨度按实际字节边界计算。旧route的16字节校验已由明确FRAME_ALIGNMENT参数替代，生产顶层统一64。三个校验入口的参数必须一致。

34×20与4×2两次实际仿真、独立数值/身份/时序审计已经通过。每次完整显示17帧和第18帧前缀，覆盖六种mode、错过VS、两类取消、冻结实际已切换对象、COMMIT/RESUME、7次真实旧帧closed与RETIRE。lookup由实际owner生成，TB中的影子权限已移除。

完整1920×1080的 `owned_scan_hd_001` 已实际退出0，独立审计退出0，suite/reference均PASS：17完整帧和第18帧前缀、22231390时隙、37324800个active像素比较、18373次实际owner lookup。当前组合MAP已经退出0：47017 LUT4、25707 FF、773 ADD、19 RAM10、1 DSP；见 [实际资源](resource-result.json) 与 [进度核对](completion-review.md)。当前综合不代表整机资源/PNR/STA或比特流完成。

测试内存是独立二维RGB/EDGE/ANN公式输入fixture。TB手动SOURCE_EOF/END和RESULT_END只建立数学输入租约；真实相机及算法生产仍须在最终父顶层接入。当前同时存在实际AXI、native、renderer、冻结和scope fence验证，不能将这些证据扩大为真实DDR PHY、CSI CRC、复杂识别或整个硬件通过。

运行入口为 `scripts/run_owned_scan_sim.ps1` 和 `scripts/run_owned_scan_map.ps1`；Efinity可打开 `project/owned_scan_component.xml`，器件Ti60F225/I3、顶层display_owned_scan。该文件是组件工程，宽控制/调试端口仍需在板级顶层内部连线后约束实际引脚。

当前三次仿真、实际MAP和冻结输入的current/snapshot SHA已重新核对。本包登记为 DISPLAY-OWNED-A64-COMPONENT-20261010-v1，只代表此组件的软件证据。后续接Result自动调度/发布/回收控制、相机输入和真实算法生产，共享同一个owner；统一综合后减少资源开销。整体目标保持五基础和六高阶，仍在进行。
