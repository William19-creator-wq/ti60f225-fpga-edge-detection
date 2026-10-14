# 软件—硬件协同工作流

## 代码生成前的设计与批准

新功能、行为/接口变更、重构、错误修复和 C++/RTL 映射，先读[唯一现行规范 v0.2](../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)，用[任务模板](../planning/PLAN_TEMPLATE.md)保存 `planning/design-<task-id>.md`。纯只读审查不要求补批历史代码；小变更可缩为短卡，但不省略必要契约或批准。

1. 调查实际要求和基线，先写系统边界可观察的行为、样例/反例与 REQ。
2. 划分 MOD 职责和整体连接，明确 IF 的参数/端口、前提和保证；逐连接检查语义、时间、数量/身份、资源及失败/复位相容性。用正常及边界/失败输入作端到端走查。
3. 向用户展示整体设计及未决事项，再补局部数据、状态、不变量和详细中文操作草图。按规范 §8–9 分开 C++、RTL 与跨语言契约；不能用共同数值规则代替硬件执行契约。
4. 补齐实施计划、验证场景/期望来源和双向追踪；关键未知解决或隔离在范围外后，按 §10.3 自检、保存、读回并呈现指定版本，标记 `READY_FOR_REVIEW`。
5. 在这里停止，等待用户明确批准设计版本、实现范围及相关基线。记录真实批准来源与条件；自检完成、编译许可、笼统旧计划都不代替批准。批准前不生成业务实现、可执行测试或 testbench，包括委托、代码块和原型。
6. 有效设计批准且其他既有审批允许后，进入实现；可先生成测试。设计边界变化先进入 DESIGN_REVISION、修订并重新获准；交付检查文档、注释、实际代码及测试一致性，分层记录验证与理解验收。

这些设计状态是任务 Markdown 标签，独立于下方运行时状态机；详见 [STATE_MACHINE.md](STATE_MACHINE.md)。正式节点执行仍要求 PostgreSQL 和原审批有效。准备获准的硬件编译时，显式读取[节点 Skill](../skills/fpga-hardware-node-gate/SKILL.md)。

## 节点闭环

```text
READY
  -> PRECHECKED
  -> SOURCE_APPROVED
  -> BUILDING
  -> ARTIFACT_READY
  -> WAITING_HUMAN_PROGRAM
  -> WAITING_HUMAN_OBSERVATION
  -> ANALYZING
  -> PASSED | REWORK_REQUIRED | BLOCKED
```

每一次转换都写入 PostgreSQL `events` 和本地 JSONL。没有数据库连接时，运行应停止；配置验证和离线事件格式验证可以独立进行。

## 节点定义

本页为通用节点闭环。赛题四完整任务拆解、依赖和验收见 [TRACK4_WORKFLOW.md](workflows/TRACK4_WORKFLOW.md)，正式需求出处见 [TRACK4_REQUIREMENTS.md](requirements/TRACK4_REQUIREMENTS.md)。以下基础节点不是项目全部范围。

| 节点 | 软件目标 | 人工硬件验收 |
| --- | --- | --- |
| H0_BASELINE | 确认板卡、FPGA、相机、接口、显示、Efinity 和基线哈希 | 人工确认实物与连接 |
| H1_DISPLAY_BASELINE | 编译已知 HDMI/彩条或显示基线 | 画面稳定、时钟和输出正常 |
| H2_CAMERA_STREAM | 建立摄像头配置、采集和显示链路 | 有效视频、无明显丢帧/错位 |
| H3_GRAYSCALE | 接入灰度处理 | 灰度画面稳定、时序未破坏 |
| H4_WINDOW_AND_SOBEL | 接入行缓存、3×3 窗口和 Sobel | 边缘响应与有效区对齐 |
| H5_THRESHOLD_DISPLAY | 阈值化和原图/边缘显示 | 输出稳定、可重复观察并满足比赛目标 |
| A1_MEDIAN_FILTER | 灰度后、Sobel 前的 3×3 中值与并行排序网络 | 椒盐抑制、边缘保留、旁路对比 |
| A2_LIVE_THRESHOLD | 按键/拨码消抖、阈值寄存器与上下限 | 实时调节响应正确 |
| A3_DDR_FRAMEBUFFER | 板型匹配的 DDR IP、帧读写、冻结/恢复 | 校准正常、整帧稳定、无撕裂 |
| A4_CANNY | 高斯、梯度、非极大值抑制、双阈值、滞后连接 | 连续单像素边缘与 Sobel 对比 |
| A5_COLOR_OVERLAY | 原始彩色与边缘同帧同坐标叠加 | 彩色正确、运动边缘无错位 |
| A6_SHAPE_RECOGNITION | 轮廓/几何特征、圆/矩形判别与标注 | 目标和负样例识别、误检漏检记录 |
| R0_RELEASE | 功能组合回归、性能与完整交付 | 人工最终下载、长期稳定和演示验收 |

## 人工闸门

Agent 生成 bit/hex 后必须：

1. 计算哈希并保存构建命令、版本、日志和报告。
2. 复制登记产物到 `artifacts/staging/`，不删除 Efinity 原输出。
3. 写入 `WAITING_HUMAN_PROGRAM` 事件和审批请求。
4. 停止执行，等待人工下载。
5. 接收聊天中的下载结果和观察描述。
6. 生成 `observations/incoming/<node>-<timestamp>.md`、`observations/structured/` 结构化记录与事件。
7. 依据观察进入通过、返工或阻断。

## 环境协助

Agent 可以检查环境并给出命令。安装、升级、驱动、网络和设备操作必须先创建工具申请并等待批准。中文路径风险只记录和建议迁移，不自动复制、删除或重命名原工程。
