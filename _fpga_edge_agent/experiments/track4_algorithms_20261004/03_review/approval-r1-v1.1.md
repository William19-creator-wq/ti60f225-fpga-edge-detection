# R1 v1.1 实现、工具执行与本地审计批准

批准来源：当前用户聊天结构化回复，questionItemId `['request_user_input_async','call_Dgewe1KRP9bFqqLEfr1ELWQF',0]`（实际原始标识见下）。用户原文：**批准 R1 v1.1 及本次本地审计例外**。

原始 questionItemId：`["request_user_input_async","call_Dgewe1KRP9bFqqLEfr1ELWQF",0]`。

批准对象：[TRACK4-ALGORITHM-R1-001 v1.1](../../../planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md)，SHA256 `DD2CCF11D0FEEE7CCFE8A3A679B004B5CD33998A2D7B3B2F79306911793B21E0`，继承完整 [R1 v1](../../../planning/design-TRACK4-ALGORITHM-R1-001.md) A/H 范围，原完整设计 SHA256 `F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00`；[ALGO-BL-20261004-v1.1](../01_baseline/algorithm-baseline-v1.1.json)，22项，SHA256 `DA97EA25F9DD8193913967965A2E0874CAD1E7A307F11337272BF910AA1D3DE4`。保存后实际重解析新基线，22份零不一致；审批冻结快照与批准前正式清单hash相同。

批准问题原文：是否批准 TRACK4-ALGORITHM-R1-001 v1.1、ALGO-BL-20261004-v1.1（22份输入）：按完整 R1 v1 A/H 范围生成灰度/中值/Sobel RTL、独立参考、TB、运行脚本及 Ti60F225/I3 四引脚25MHz工程，执行1080p仿真、综合、布局布线、时序检查，必要检查通过后生成并登记比特流；同时允许本次独立软件实验采用本地审计（PostgreSQL尚未配置，正式数据库和硬件状态不改）？修订卡：_fpga_edge_agent/planning/design-TRACK4-ALGORITHM-R1-001-v1.1.md。获批后我会边实施验证边继续后续设计，生成比特流后停止硬件步骤。

范围：指定独立 work 内的六份前端 RTL、独立参考/五前端TB/runner、图样/监督/CRC/LED/复位/top、三外壳/组件TB及参考/runner、四pin25MHz project/peri/SDC/构建runner；现装工具仿真、综合、接口生成、布局布线、STA，必要检查成功后bit/hex和staging/报告/hash登记。独立work `_fpga_edge_agent/work/active/track4_algorithms_20261004/r1/`。

本地审计例外仅本次独立 R1 软件实验：允许本地 JSONL、报告和 Side-effect ledger；PostgreSQL仍未配置，不执行正式 DB 或硬件节点状态转换；PROJECT_STATE、TASK_LEDGER、hardware_nodes不改。本次真实批准加入现有 Manifest 的 scoped_approvals，不扩张旧预检批准。

排除：后续 Canny/识别/生产摄像/HDMI/DDR业务实现、保护IP生成或升级、模型修改、下载/安装/网络、数据库操作、硬件编程/观察。后续纯设计继续。当前仅记录真实授权，功能/工具检查尚未运行；不得据批准即报PASS。
