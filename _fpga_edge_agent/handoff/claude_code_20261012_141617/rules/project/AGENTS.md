# FPGA_verilog 项目入口

本项目的控制面位于 `_fpga_edge_agent/`。开始项目工作前，必须读取 `_fpga_edge_agent/AGENTS.md`，并按其中顺序读取项目规则和运行提示词。原始 HDK、资料及参考工程保持只读，沿用控制面的审批和人工硬件闸门。

新功能、行为/接口变更、重构、错误修复及 C++/RTL 映射，必须读取本目录 `AI_Agent_代码可理解性规范_增补提案_v0.2.md`。先形成可读回的整体/局部设计、接口与组合检查、中文操作草图、验证计划和双向追踪；达到 READY_FOR_REVIEW 后等待用户明确批准指定设计版本、范围和基线。

批准前不生成业务源码、功能性脚本、可执行测试或 testbench；回复代码块、子 Agent、原型同样受限。配置调整授权不是业务实现授权。任务文档使用 `_fpga_edge_agent/planning/PLAN_TEMPLATE.md`，保存到 `_fpga_edge_agent/planning/design-<task-id>.md`。

详细规范只有上述 v0.2 一份；启动提示词不是长期规则。本文件只负责引导读取，不改变权限、审批设置、数据库或运行时状态。
