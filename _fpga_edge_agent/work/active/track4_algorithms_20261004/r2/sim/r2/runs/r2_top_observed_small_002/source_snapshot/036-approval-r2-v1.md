# R2 流段 v1 实施批准实录

批准来源：2026-10-05 当前用户直接聊天。用户原文：**批准 R2 流段 v1 及本批本地审计例外**。本记录引用真实回复，不代替正式数据库状态。

批准对象：[TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001 v1](../../../planning/design-TRACK4-ALGORITHM-R2-STREAM-IMPLEMENTATION-001.md)，批准时 SHA256 `1728A3163F600CE7F85075BB5704154827FC3B7A0698E0EA6CC0CADA98CDFB27`；ALGO-R2-STREAM-BL-20261005-v1 的48份输入，基线文件 SHA256 `F7CF4DF2F8CE8A5874C33E7B9DEA997A6A09BCF0C417282D7D6DD4DAE8A93E7E`。批准前阅读摘要是 [模块代码组织入口](../02_design/r2-module-first-reading-v1.md)。批准原设计保持字节不变，旧 NOT_APPROVED 是批准前时态；本记录作为任务的实施批准补充。

批准问题范围：按先模块代码和单测、再短链整合、再物理验证，实施原设计 A/H/G 的高斯、梯度方向、NMS及双阈值分类、控制与测试外壳；生成 RTL、独立参考、TB、运行脚本和工程，执行1080p仿真、综合、布局布线、时序检查，通过必要检查后生成并登记比特流。独立工作路径 `_fpga_edge_agent/work/active/track4_algorithms_20261004/r2/`，31个计划新增文件与7个R1共享RTL；不修改共享源或原资料。

本地审计例外仅本批 R2 独立软件实验：允许控制面本地 JSONL、Side-effect Ledger、报告和产物登记；PostgreSQL尚未配置，不写正式数据库、PROJECT_STATE、TASK_LEDGER、hardware_nodes或旧 Approval Manifest。既有正式 Manifest 保持原样，本批准实录与用户聊天作为本批指定授权来源，不扩用R1例外。

排除：完整Canny滞后连接、识别、摄像头/DDR/HDMI生产实现，保护IP重生成或升级，原厂模型修改，下载/安装/联网，正式数据库操作，硬件编程及观察代签。生成登记bit后停止硬件步骤。批准本身不构成实现、仿真、综合或时序PASS。

本次恢复已重新核对48份输入，零差异；开始按现有草图逐模块编码。发生实质契约变化才修订对应设计，普通编码与纠错沿用此指定批准。
