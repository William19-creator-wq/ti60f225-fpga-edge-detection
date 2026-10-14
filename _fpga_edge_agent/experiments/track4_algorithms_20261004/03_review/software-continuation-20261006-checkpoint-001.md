# 2026-10-06 软件续作检查点 001

本记录是控制面只读核查的结果，不是新实施批准。R2 的最终交付以 `work/active/track4_algorithms_20261004/r2/docs/DELIVERY.md`、`runs/integration-checkpoint-005.json` 和 `artifacts/staging/ALGORITHM-R2-20261006-v1/artifact-manifest.json` 为准。

## 已完成与当前范围

R2 已交付 31 份实现文件，其中 13 份 RTL；230 项软件测试通过，包括实际 1080p 输入、故障恢复和默认尺寸顶层。独立 25 MHz 工程完成综合、接口生成、布局布线、时序检查及 bit/hex 生成登记。完整五项基础及六项高阶仍未全部完成；完整滞后连接、形状识别、生产摄像头/DDR/HDMI、冻结/叠加和整包性能验证继续进行。这里不把独立四引脚工程当作整板工程。

最新有效用户边界允许板载 DDR3，要求仅使用现有板卡资源。旧候选 R3 中“停止指定外部存储器件工作”的文字是历史范围，不是当前用户指令。该候选尚未获批，保持原字节；后续新卡采用最新范围。

## DDR Q0 的实际核查

- 设计：TRACK4-DDR-Q0-001 v1，SHA256 `C71025F22C68E29858C57175E9976924D063A2BCE52BE1FBEDA8FD531467087D`，全文读回。
- 基线：DDR-Q0-BL-20261005-v1，SHA256 `9460D055EFDD83D228F05DAB28632DDFFCE785CB096F84C288800F218B56A4E1`。
- 实际遍历 files 31、tools 4、contexts 9，共 44 项；逐项路径存在、bytes 和 SHA256 均匹配，漂移 0 项。本记录不以旧的 31 项检查冒称 44 项。
- Q0 work 根不存在；没有创建副本、编译库、执行 Questa、推进仿真或运行 Efinity。
- live Manifest 无 Q0 指定批准，R2 聊天批准只授权流段。已通过本轮异步问题呈现 Q0 v1 的单次编译/合法展开和本批本地审计请求；答复待收到。
- Q0 成功只能证明指定输入能够编译和展开。真实 AXI 读写、匹配 DRAM 模型、PHY、容量/带宽、故障及完成语义属于后续验证，仍未执行。

## 独立可继续的工作

R3 的 kind 0–7 整数算术不需要 DDR、ROM 角表或识别候选调度。将其独立成模块实施卡可以先进行单元验证；R4 owner/调用适配、LS/TLS、角表生成和整机仲裁由后续卡承担，不伪称已经闭合。本轮只进行设计文档工作，不生成未经批准的 RTL、参考程序、脚本或 TB。

活跃工具会话：无。正式数据库、PROJECT_STATE、TASK_LEDGER、hardware_nodes 和原 HDK 保持原状态。总目标仍 ACTIVE；上一轮 R2 为实际实现进展，本轮为后续设计与批准准备。

后续补充：已完成 TRACK4-ALGORITHM-R3-SCALAR-001 v1 的独立设计卡及26项冻结输入，全文读回/呈现后由 `r3-scalar-design-readback-v1.md` 记 READY_FOR_REVIEW。该范围为kind0–7、13份业务文件和14类验证场景；仍未批准/未实现/未运行。DDR Q0的44项输入在本轮末复查仍0漂移。新卡不修改历史R3、DDR或R2冻结来源。
