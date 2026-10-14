# 结果自动发布控制：当前实现进度

阅读顺序：[整体、接口与中文草图](control/design-v1.md) → [组合顶层](rtl/frame_publish_control.sv) → [结果管理](rtl/frame_result_manager.sv) → [旧帧回收](rtl/frame_result_retire.sv) → [共享命令仲裁](rtl/frame_owner_command_arbiter4.sv)。

四个RTL、仿真入口脚本、Ti60F225/I3组件XML和10ns SDC共7份业务/工程文件已生成。实际 `publish_compile_002` 的vlib/vlog均退出0，15份当前输入及snapshot SHA一致；这是编译通过，尚未运行动态验证或综合。计划10份文件，剩余TB、独立参考、MAP脚本共3份待生成。16份设计/参考输入已在业务实现前冻结，其中10份运行依赖；不修改已有显示HD运行、HDK或旧组件。

首次 `publish_compile_001` 编译因 `matching_cancel` 声明在首次使用之后报错，原尝试保留。已按 [C1修正草图](control/design-C1.md) 仅移动声明顺序，不改变接口或行为；新尝试编译成功。没有将编译结果冒称协议、图像、时序或资源通过。

正常事务：请求 → 真实ALLOC_RESULT/OK → producer job及真实DONE（RGB/灰度模式为合法空义务）→ RESULT_END/OK → 全局sequence → OFFER/OK → 实际显示回执 → APPLY/OK → 引用登记 → completion。旧对象需完整oldclosed及真实RETIRE/OK才释放；未知关闭永久隔离，只能共同cold恢复。

producer与显示通过接口连接实际模块。本批计划的端点fixture只能证明控制语义；未来父顶层仍需接真实Canny、识别/标注、扫描及统一冻结控制。Source帧管理复用capture_owned；实际owner只有一份。完整系统资源、DDR PHY、MIPI、板级时序及最终比特流未完成。
