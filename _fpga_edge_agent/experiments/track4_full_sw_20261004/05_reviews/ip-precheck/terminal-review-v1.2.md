# v1.2 终态报告的限定复核

2026-10-04。独立协议审阅 Agent 只读核查，未运行构建或修改文件；root 保存本归档。结论为：在以下范围未发现成功误报、范围扩张、C1 因果误归属或基础/调试资源混用。不是整包设计、功能或硬件验收。

| 绑定文件 | 实际阅读范围 | SHA256 |
|---|---|---|
| RUN_REPORT.md | 9659B，全文1–77 | 0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA |
| case-status.json | 1883B，全文1–67 | 125443117AA3514376E34C2B1884CE3023638265CC81C6F192E1DFE10AF69F23 |
| scope-check-v1.2.json | 657B，全文1–14 | A8E33F738DBAA202B85999AA952EB0F0F6EE4078692986D70E142E9B81A335DF |
| 整合设计v0.4（修正Dependencies前） | A/A2 1–99、INT-B01附近205–222、J/K/L225–238 | 698901E49563AD16A077E9AE51D491289102A61A640CD4298FBBD510AAE22812 |
| PIO v0.2 | 新1–5、D4 186–194、实施边界261–279及相关来源 | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 |

核对了PT/PNR console及place.out/rpt全文、merge实际warning/资源/USER2插入段、Questa DUT/审计、原源92项及90项非XML/peri副本、当前bit/hex数量和正式状态摘要。资源分别匹配基础与合并map，DDR父子未重复加；CSI编译失败与未到达DSI未写成成功。C0 pack失败没有写成placement/route通过，PT timing没有替代STA。C1依赖跳过与#4独立物理阻塞分别记录。

发现并修正一处文字遗漏：整合设计Dependencies只列v1/v1.1，root补为v1/v1.1/v1.2，当前hash为9B6ABABA094858E685151903DD7305ECC1313BC2B48B7A46C7C05B0A31CDC2D3。技术内容未改；上表的独立复核绑定修正前稿，不能冒称整包全文复审。

计数澄清：独立审阅说明中把303称为包含汇总。root按实际17:53:00区段重算，方括号记录共304条，最后一条是Found 4 warnings汇总，因此为303事件加1汇总；原报告“303条事件及汇总”保留。这是计数范围澄清，不增加成功结论。

C0 Questa另获第二路只读核：XML65实际HDL加两个IP源顺序共67，15厂商文件、6头文件/6incdir及90输入hash匹配；DUT在CSI385停止，DSI没有实际编译，vopt未执行。该审阅绑定inputs 0CA03729F7A2C9C7CFA419E9CB91022FC9AD009BB7E0EC428116C2E606C6BB83、final E7AC29DDC6F230D35C03301B13ADB13DE71DA41DB36661118A44FDC31E611C1E、DUT log108B6E3BAE8821121623CF1CE8AFF2C029131E37026DCE5094FF29F6D465BF74，不复用为新revision的PASS。

后续新修订仍需独立绑定其设计/基线和具体批准。本归档不批准删除USER1、修改clock、生成算法、功能仿真、bit或操作硬件。
