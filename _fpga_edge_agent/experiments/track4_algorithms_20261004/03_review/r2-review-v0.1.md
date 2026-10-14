# R2 v0.1 与完整设计包的审阅记录

2026-10-04。R2 LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_RUN；整包GLOBAL_DESIGN / NOT_READY。设计调查和文档核对不是功能仿真、综合或STA。

## 当前版本

[R2 v0.1](../../../planning/design-TRACK4-ALGORITHM-R2-001.md)实际SHA256：
6B9C02C04662AAA10EC69CD12391AAFCD2E3D41F1E80809A604069534F167FAA，22380 B。
[整包v0.1](../../../planning/design-TRACK4-ALGORITHM-BATCH-001.md)实际SHA256：
EB17002246C7D4426BF34C6AF166E1228EBF5E6650E2C0156A045A719D0BA710，13065 B。
[R2候选来源基线](../01_baseline/algorithm-r2-baseline-v0.1.json)实际SHA256：
563DA1F84007D89487CBCD0BFEA3BCC2A82979A69EFB9B4EB7F24829D7B0B34F，27份来源；不是整包批准或最终源码基线。

## 两方向实际审阅及修正

| 方向 | 实际版本与范围 | 结论 |
|---|---|---|
| 数值 | 初R2全文204行，SHA1769873BC23B12806BB0E46B5A15BA5E4AC224F756AE9D76ADB13CFE7D2B1614 | Gaussian/NewSobel/424/NMS/阈值、字段加总、20+8 RAM结构预算与LOCAL范围无数值矛盾；没有核准原FP来源声称 |
| 协议 | 初R2同1769873…全文、BATCH同EB1700…全文 | C0唯一owner/分类分层/五项缺口明确；发现原FP错称169而漏in_bad |
| 协议修正读回 | 当前6B9C02…的IF02第79行、来源第87行、T08第167行 | 原FP74及in_bad/无逐像素ID/旧job来源隔离/错误场景已关闭此具体矛盾，未升级READY |
| root | 当前R2/整包/入口/草图/说明/候选基线保存全文读回 | 与最终预期逐字比较；最后差异仅FP定义、来源说明和T08，数值合同未变 |

原FE实际SHA45BBC86A67FE6FC3D0D7078AD3AFD377CED6CFE9C5E4E5FAB706883C72859114，第97–100行：RGB48+坐标22+SOF/EOL/EOF/in_bad4=74bit，valid/ready独立。第115行：内部身份引用锁定ctx，输入适配先剔除旧任务数据。Msrc137是原FO去edge2后的内部逻辑，不能拿它或其他逻辑sideband改写原FP。

root已实际读该来源，纠正IF02并增加in_bad/坐标/标志错误测试文字。初数值审阅169的算术加总相容不等于与真实原接口相容；两种证据明确区分。未修改原FE/R1。

## 未关闭的范围

R2-B01终态字段/错误优先级、B02取消全部事件、B03 RGB/控制/显示、B04 observer/工程/资源、B05完整冻结追踪均保留。不得将C0 owner选择或数学已清楚写成整体无阻塞。
R2仅产生完整分类和按配置输出的梯度；无STRONG仍可有WEAK。精确八邻域闭包、最终edge、识别和最终Canny覆盖继续R4/R5。原RGB一entry活流tap有填窗口等待环；有限held只适用于证明过的独立重放。

当前20RAM10流段、加FE合28和0DSP是预算/目标；真实综合、防裁剪、pin/PNR/STA/bit未运行。软件/算法核吞吐、CRC观察速度和HDMI刷新率分开证明。

## 当前允许行动

继续完成设计/审阅和中文步骤，不生成业务RTL/参考/功能脚本/TB。整套必需设计完成后统一呈现具体版本/范围/基线审批；原R1请求只覆盖R1。数据库例外仍未批准，正式Manifest/状态/数据库不变。用户的批准含义问题不是实施授权。
