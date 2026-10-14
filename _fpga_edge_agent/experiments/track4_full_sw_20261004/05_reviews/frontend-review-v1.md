# TRACK4-FRONTEND-001 v1：设计复核记录

日期2026-10-04。对象为 [局部主设计](../../../planning/design-TRACK4-FRONTEND-001.md)，输入基线 [FE-BL-20261004-v1](../01_baseline/frontend-baseline-v1.json)。本记录是设计分析与文档检查，不是功能测试通过，也不是用户批准。

## 审查分工与实际结论

三个子审查均实际读取落盘主稿，只进行设计/只读工作，未生成实现或可执行测试。

| 范围 | 审查者 | 实际核查与结果 |
|---|---|---|
| 窗口/存储/逐拍 | frontend_window_design | recent/older延迟写与新读不同址；REAL末组写和REPLAY q0读可同沿；72bit水平历史足够；TAIL及EOF交付后empty自洽；确认首输出e(2D+24)、末e(N+2D+23)；设计无剩余结构阻塞 |
| 数值/排序/映射 | frontend_numeric_design | 灰度范围/纯绿149，19比较器九级中值，Sobel1530联合上界、严格>阈值、两次补边手算与独立整图参考正确；数值设计无剩余阻塞 |
| 生命周期/软件边界 | frontend_boundary_review | job/像素分沿、取消沿已交付计数、STATUS不可变、局部OK与整机发布区别、上游适配责任明确；补齐脚本/向量接口后可进入READY收尾 |

## 已根据复核修正

1. 固定采用灰度3级、中值9级、Sobel6级；没有把早期2/4/5级建议混入最终沿号。
2. 纯绿255的灰度为149；Sobel真实联合幅值上界1530；均有手算和位宽依据。
3. Gx/Gy在S3之后、L1在S5之后继续延迟到S6，诊断端口有名字和逐lane二补码布局。
4. start/flush/empty明确属于F1/F2/F3/F4流模块；F2R只承担RAM端口，pending有效性由F2拥有。
5. 错输入触发的flush不反向屏蔽触发它的ready，避免组合环；取消沿真实旧输出握手仍计交付，但job作废。
6. X/Z检查仅针对握手控制、状态和被使用的有效payload，无效payload仍按契约忽略。
7. Python参数、返回布局、5类向量位布局、signed编码、CLI、新run/vectors目录、manifest及逐case比较计数已明确。
8. 正常frontend case才要求N/OK；其他单元没有F0 status，以声明计数和本地排空判定。reset撤销旧job，不要求旧job返回CANCELLED。
9. 固定随机种子与生成方法；输入一旦提出就保持至握手，随机气泡不能破坏ready/valid。
10. FT-11明确覆盖中值开/关与Y_ONLY/SOBEL的四个组合；中值测试噪声参数不被转用为已撤回的识别验收边界。

## 本批适用性与整机剩余工作

本批可独立审阅的范围是同域可反压处理核、参考与单元/组合仿真。它细化完整工程的MOD-06/07，并为Canny提供Y输入；没有删除其他基础或高阶要求。

DDR匹配2Gb模型/PHY校准、CSI峰值/FIFO/CDC、板级时钟引脚、帧槽与DDR服务、消抖、完整Canny、识别及HDMI仍需各自局部设计与真实软件证据。单元完成不能更新它们为PASS。原HDK、工具目录、正式PROJECT_STATE/TASK_LEDGER/数据库未改。

## 证据与批准

28项输入已哈希冻结，父整体布局与接口仍为v0.1；局部主设计为v1。最终文件、链接、段落/追踪编号、输入漂移及无业务实现检查由本目录document-checks记录给出。相关结果将按实际检查写入，不以本文自述代替文件检查。

用户批准：**NOT_APPROVED**。理解验收：待检验。业务代码、参考模型、脚本、testbench、编译/仿真、综合、布局布线、STA、bitstream：**尚未生成或运行**。
