# 算法路线与R1 v1设计审阅

2026-10-04。**有限R1 READY_FOR_REVIEW / NOT_APPROVED / NOT_RUN**。路线整体/完整十一项未READY、未完成。只读审查和文档核对不是功能测试或工具实现。

## 当前范围与保存读回

[整体路线 v1](../../../planning/design-TRACK4-ALGORITHM-ROUTE-001.md)→[R1 v1](../../../planning/design-TRACK4-ALGORITHM-R1-001.md)→[新基线](../01_baseline/algorithm-baseline-v1.json)。R1是旧前端数值/窗口/握手及新规则图样/结果摘要/真实四pin25MHz工程，原RGB对齐/Canny/识别/具体外存器件不在本批。

root最终实际全文读回：
R1 F33A700DE0B76A8415E220204C9DB4E5C013878D2249A20CAEDDF62B3096BC00，27440 B；
ROUTE 2D082374D56754CE4D38654B4945D3D736FABD9C5F36FE8E47759CEBCF90E9AE，10243 B。
正文与预期逐字一致。最初保存多一空白行、后续整体替换规范化结尾空白的差异已单独定位，不把格式差异当语义审查通过。

## 独立审阅的实际版本与范围

| 方向 | 实际读取对象/版本 | 结果与后续确认 |
|---|---|---|
| 算法/前端 | 初R1 84E9EF5DB8FA0DF440583E7BD4D38F5D3FB33BE7E6E20387EB6AF5840623357A和ROUTE 40CC936D49AFB2E61A3BD50597CA47FDB51206166314C67A5049C775E5D4BD04全文；原FE 45BBC86A…59114 | FE继承、全尺寸、25MHz/10ns、RGB排除成立；发现两级async-clear例外歧义，实际复核E2A61…87FA7 D/E4/E5后关闭 |
| 板级/外壳 | R1 7D6478F881125D5710E9DA7E1537CCA8A208599B7D808DB08C547D86FD6CC77E全文1–251行及上述ROUTE全文1–103行 | 所提出三问题均已关闭：提前失败FS/N等待环、LED身份失败门控、图样31/32和255/256分支验证；无当前有限设计阻塞 |
| 流控补充 | 原FE/Canny/Display/Control来源及R1 E2A61…87FA7全文 | 提出FO应在FEED/DRAIN都接，FS提前失败不可等N/EOF；修订D/E2/E3/IF06落实。最终标签版本不冒称由所有审阅者全文审核 |

root最终版本只在7D6478…CC77E基础上更新有限READY标签与门槛/状态说明，操作语义未再次改动。最终全文由root实际读回；他人审阅绑定上述实际版本与范围。

## 关闭的具体问题

1. KEY只连接两级async-clear，D1=1/D2=Q1；例外精确列两个CLR，不制造KEY→D1，不屏蔽Q1→D2/Q2→FE及内部路径。
2. FO在K空且FEED/DRAIN均接；FS在前缀CRC排空后消费，不将N/EOF当错误终态接纳门槛。真实FS终结source，CRC完成/good才继续或ERROR。
3. good包括原code/三ID/计数/正常DRAIN与源EOF，由FS消费锁定并随CRC提交；LED0门控last_good，错ID的原OK不能重新点亮。
4. FS160bit只是code/三ID/两计数摘要，不含error_xy；原FE错误坐标仍由FT-09/协议验证核对，没改接口。
5. S另用258×258单元用例实际命中31→32、255→256和128→129；外壳故障组件用typed端口激励，不force真实FE status/done。
6. 捕获沿不处理新record，随后160沿、最后用新CRC、接纳间隔至少161；外壳低速与核吞吐/HDMI60Hz分开。
7. R1当前真实25MHz/四pin/40ns与100MHz仿真/未来性能目标分开，生产综合网表须实测防裁掉。

## 设计门槛和执行前置

R1 B行为/样例、C职责/连接、D接口/组合/内部owner、E中文步骤/状态/不变量、F RTL A–L和三份对应契约、G验证、H双向追踪、I指定版本/范围/基线均有实际内容；当前有限设计无剩余正确性阻塞。文档/基线检查记录另存本目录 document-checks.json。

R1-T01…08、FT所有软件测试、当前综合/PT/PNR/STA/bit均NOT_RUN。8RAM10/≤8000XLR为预算，未测；源码/工作副本不存在，原源/正式Manifest/H0/数据库未改。

等待用户指定R1 v1、A/H范围、ALGO-BL-20261004-v1批准。数据库未配置；独立本地JSONL/报告/副作用审计例外尚未批准，不能默认绕过。当前不请求旧器件模型/IP预检审批。理解验收待用户反馈。
