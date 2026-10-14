---
name: fpga-hardware-node-gate
description: "对一个 FPGA 软件—硬件节点执行预检、获批编译、产物登记、人工下载等待、观察记录和状态关闭。"
---

# FPGA Hardware Node Gate

## Trigger

当当前节点需要生成 bit/hex 并在真实板卡上观察时触发。

## Do not trigger

仅做资料阅读、静态代码审查或学习规划时不触发。

## Inputs

节点 ID、指定版本的任务设计及实现范围、相关基线和真实批准证据、源码/工作副本及构建批准、工具版本、约束、目标板卡和人工验收标准。涉及业务代码生成时先读取[设计规范 v0.2](../../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)和[设计流程](../../docs/WORKFLOW.md)；只有标题、旧计划或编译授权不能替代设计批准。

## Procedure

1. 检查硬件身份、工作副本哈希和数据库健康。
2. 检查前置节点及既有审批。核对 `planning/design-<task-id>.md` 的设计版本、范围、基线与批准是否仍有效；准备新增/修改业务实现或测试而缺少有效设计批准时，停在设计/评审阶段，不生成代码。已存在且未修改的基线构建不要求补批其历史实现，但仍须工作副本/构建批准。设计批准不替代工具、数据库、源码和编译审批。
3. 在 `work/` 中执行获准编译。
4. 对 bit/hex、日志和报告计算 SHA256。
5. 登记到 `artifacts/staging/`、事件归档和 PostgreSQL。
6. 停止在 `WAITING_HUMAN_PROGRAM`。
7. 人工下载后，由人反馈现象。
8. 保存原始观察和结构化观察，进入 `ANALYZING`。
9. 依据证据进入 `PASSED`、`REWORK_REQUIRED` 或 `BLOCKED`。

## Forbidden

Skill 不得下载、烧写 FPGA/Flash、操作调试器、跳过人工观察或把编译成功当作硬件通过。不得经 testbench、原型、回复代码块或子 Agent 绕过设计批准；设计边界变化时先修订复核，重新获准后再继续受影响实现。

## Validator

`runtime/validate_control_plane.py`、Artifact Manifest 校验、状态转换校验和人工观察完整性校验。

上述控制面静态检查只证明其实际覆盖的结构/字段；设计门槛依赖文档与人工评审，运行时、数据库及硬件闸门仍需各自证据，不能从静态通过推定。此 Skill 保持原项目位置，由工作流显式读取，本次未安装为宿主自动发现技能。
