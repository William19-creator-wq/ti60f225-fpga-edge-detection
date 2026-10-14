# RECOGNITION-EXECUTION v0.1 实际读审

2026-10-04；关联TRACK4-FULL-SW-001主计划v0.18。范围仅设计/只读原文件/字段算术/文档QA，**不是功能测试**。

## 1. 实际版本与范围

[执行主稿](../../../planning/design-TRACK4-RECOGNITION-EXECUTION-001.md)最终SHA256：
F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178。

root从实际磁盘全文读取初版27029字符、与预期文本逐字符一致，分两段核读；随后逐项读回receipt和五处澄清，最终27699字符整文仍与预期精确一致。7REQ/4IF/9OP/8INV/15文字场景/12模板段/7追踪行。原ALGORITHMS D8C、NUMERIC17C4、DATA B09B、RC D972字节保持。

P1方向实际全文读712A8698A39376CFCD55242250C7E3D6183696A10B0711AF0E1E75C98459E45E，并独立核对最终F664保存版本及五处差异；限定范围未发现剩余直接矛盾。
P3/数据方向已实际全文读712A版本，确认job/receipt/status、702/708身份、DONE、模式、coverage/VC/FINAL和row/carry/spool相容；随后实际确认最终F664保存版本及五处澄清，与要求一致，未发现新增直接矛盾。未变章节的核读结论保持有效。

这些是设计分析，不能证明所有输入、工具映射或真实IP行为正确。

## 2. 具体修正及可复查反例

- 旧“遍历全部294528 pair”会在anchor不足768、尤其E0时误解为读空槽；改为按有效anchor_count枚举a<b，数量a(a−1)/2≤294528。
- root统一receipt status2/error4到DATA_CONTROL既有枚举；完整body相等且旧ctx仍pin才ALREADY，BUSY/拒绝无效果。296个16bit块比较末11bit；比较和相应receipt未闭合不清旧ctx。
- global容器只规定嵌套组低到高，scope/grant内部仍保持原版本顺序；避免把DATA高到低字段反转后以相同位数冒充相容。
- c0容器48明确为18+18+8+1+3，输出seed_id13高5常零；无额外FF暗藏。
- status raw valid0关联字段归零；OK descriptor与实际已授ANN grant匹配，坏输入回执不能赋予释放权。
- CELL count/submin/submax无法恢复同cell真实gap；新增16bit私有submask，借关闭后的NMS4+未启用PAIR4，逻辑zero2/zero13保持零。
- FINE state跨combined379/380、word18/19；COMMIT接受不等20WE完成，增加DONE157复用RESP541槽及完整record锁/发布沿。
- 规范法线必须同步t/μ/区间/端点censored符号与顺序；第三/五遍fit后第六遍仍重放冻结M2。
- coverage的绝对投影bin可能因远图外端点超4096；以j−j_base寻址。真实可见窗及首尾部分长度采用精确根式门；ceil长度、count或occupied/span不代替真实并集。
- 第四圆遍若按新c2选成员会变n；准确重放冻结c1/r1。tile末9bin若提前判峰会切裂平台，19raw及平台状态跨tile保持。
- row不能直接作为等待未来生成数据的物理W源；独立1024B SEALED spool使已提出W供料与未来row解耦，copy与FORMAT真实接受分开记录。

## 3. 实际静态核算

15项字段/容器求和全部一致：RC_BIND4731、receipt693、STATUS965、context384、circle6069、Rrecord384、bank160、plateau82、SEG physical400、PAIR64、coverage metadata320、P2增3911、P3增2392、已列29168FF及225RAM。
VC2048×20=40960word→80RAM；四coverage每侧4096bit→205word；可见对角线2202.907…px→span≤2204；ANN522624B→32664拍/511段。均为文档字段算术，不执行识别场景。

全机RAM候选225/256保持；29168bit只已列局部与绑定容器，32个logical乘法和宽scalar不构成全机DSP/STA结果。P1最坏约1.431TB、P2约408.217GB、P3约67.948GB点流量保留为性能问题，未称实时满足。
旧算法18场景、独立同类P/R≥95%要求和撤回硬边界的决策保持，新增15场景全部NOT_RUN。

## 4. 原始资料及控制状态

再次实际只读VF精确嵌套目录和Demo/Demo，已有DDR controller/IP/PHY/校准/模型/约束，范围内缺2048Mb器件参数头；默认4Gb/x16模型与V4 2Gb/x16适配不能以控制器地址几何代替。来源见[VF/Demo证据](../01_baseline/vf-demo-supplemental-evidence-v1.md)，未重新写原证据或解压/联网。

前59MD算法审计保存[原字节历史](document-checks-recognition-algorithms-v0.1.json) SHA A46564AB028EB93E3E897446AD5EA076FA1F9A3DDCDD2EB95869ED44E717CDD4。当前文档/源角色复核见[document-checks](document-checks.json)。正式H0/state/ledger/Manifest/DB不改，数据库URL/psql/服务实际均未配置；未新增批准问题。

## 5. 结论与尚未完成

AG-B01内部地址/word/原子提交/成员/coverage/row执行已形成集中候选；D1 packed合同与J差异仍须父联合版本显式吸收。AG-B02全机FF/DSP、真实服务期限/性能优化，AG-B03获批后独立质量执行，AG-B04真实外部合同/许可/批准/DB继续保留。

主稿LOCAL_DESIGN/NOT_READY/NOT_APPROVED；完整软件goal仍ACTIVE，本轮实际设计与读审为PROGRESS。未生成业务代码、功能脚本、可执行参考或TB；仿真/真实PHY/综合/pin/PNR/STA/bit/hex全部NOT_RUN。不能以设计文件齐全把完整任务标为完成。
