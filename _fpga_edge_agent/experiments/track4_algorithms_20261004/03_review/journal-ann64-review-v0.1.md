# JOURNAL 租约与 ANN64 输出 v0.1：有限静态审阅

2026-10-05。LOCAL_DESIGN / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。仅设计、固定位宽算术和文档身份审阅；不是可执行测试、实现批准或整机适配证明。

## 1. 阅读入口与最终身份

先读[JL整体/租约/归还草图](../../../planning/design-TRACK4-ALGORITHM-JOURNAL-LEASE-001.md)，再读[ANN64整体/整块写/覆盖草图](../../../planning/design-TRACK4-ALGORITHM-ANN64-OUTPUT-001.md)，最后按各卡G/H检查验证计划和追踪。共同真实桥及完整费用未闭合，不请求批准本候选。
JL：161行/27234B/SHA68308B965400E50B367C7B2D73BA13F777D78501B29047D0B3F3F010E056FDB5。ANN：109行/15956B/SHAB2F3F63CDE4CA254DA2851AB7D164110554C8EF3B6E68D5107724E1A43CFB694。

## 2. 实际读回与审阅范围

Root读JL初稿1–58及59–161全文，初稿SHAAEC5D59409A9F757204083B7449F58A42248089E2B4BB478F717A6D6D9FF64F5；修后实际读82/108/109/123，未称最终全文重读。语义子审 /root/production_directory_numeric 初稿1–161全文，最终82/108/109/123实际重核。
Root与协议子审 /root/production_directory_numeric/load_grad_point_pin_review 均读ANN初稿1–109全文，初稿SHA344033DF2E5C6187EDD2BE4F9E2F3971B72C791D5B22A6564372C9C6B0B836A9。作者 /root/production_directory_numeric/quality_recipe_static_counts 初稿全文读回，随后仅15/20修订读回，过渡SHAE45A356FA43B29D45A4F65217CFA546924410AB176AFDE36F7A4BC784EDF3986。
Root最终15/20/55/56/59实际读回；协议子审对55/56/59澄清先给有限设计认可，最终文件的实际delta读回以本轮文档事件补记。没有以作者自查替代独立全文审阅，也没有最终ANN全文重读声明。
Root本轮实际有限来源读取：RA26–51/57–77/106–114、DIR128–155、BK63–132、RAW164–184/240–256、SC104–118及具体reason命中、SM具名阶段/费用行。此前完整读取沿用；组合输出被截断的DDR预算/rg结果不记全文阅读。

## 3. 发现与已落实的修订

JL新增唯一JPOOL职责、RC entry七body与group五body、完整tuple/真实许可/单调序号及后续旧状态归还门。ordinary先真实872消费，再退entry/group；DENSE逐lane退entry但保wholegroup至末872/关联关闭，实际STORE外部READ/SEAL隔离仍需真实桥，单journal mutex不替代。
独立审阅发现单cold27_latch不能同时保护旧BK两live entry。最终只选RC当前单entry/完整ENV的20bit+valid1；BK继续实际完整assembly及状态WE完成后再切另一entry，adapter/费用未闭合，不用单RC latch抵扣BK。重复合法STATE_WORD更新保持postimage高11位，不添加隐藏READ。
ANN新增候选op6 WRITE_ANN64/object21/phase14/length64，每块低128bit完整覆盖64个2bit、高384零，选完整16B覆写省目的旧READ。原799/872只同宽；R4R/SM/SC/RA/JL当前版本仍未共同吸收此行为，原op6仍非法。SC count64逻辑范围不代真实fullspan租约。
修正ANN来源旧SM hash与“JL未保存”描述，引用当前实际身份。进一步明确STORE覆盖前缀是wholeblock protocol-success：write/state/pad、可见/no-future、正确END及无已锁first_failure均真后才推进；END失败保真实written/FULL/UNKNOWN历史而不推进。真实成功872已published/held之后cancel不撤回复、不倒扣已成功前缀，整帧失败另记。
INIT仍独立实际执行；不跳空块/F0，不减完整N、64RECORD或几何质量要求。ANN退租沿ordinary，不套DENSE逐lane提前退槽。

## 4. 固定数值及证据限度

JL选两端各请求/回复max槽及独立ENV/GENV：2×(937+965+1262+1271)+2×(847+1247)=13058bit，RC latch另21，共13079具名部分bit；不是完整FF/XLR。消息格式之和entry6107/group6219不作为实际存储预算。原16×29×20=9280bit pool及176效果账保留，实际完整实例/冷热/端口尚待闭合。
ANN：2073600/64=32400块，每行30；59×32400=1911600 native issues，旧59N=122342400。数据W32400×16=518400B，旧保护R+W=66355200B；分别1/64 native及1/128局部数据字节。独立INIT仍32400写；RECORD仍3776 issues及8192B，输出两类合1915376 issues。179bit只是pack128/count7/两prefix22字段，不称完整FF。
上述费用不含控制、真实权限/END、ROW读取、INIT、DDR等待或完整算法；没有处理fps、服务上界、资源fit、综合/PNR/STA证明。JL-B01…04和AN-B01…03均OPEN，未达READY。

## 5. 守护、记录与下一步

21项来源/正式/既有交付hash核验相符；R1 22/R2 48/Q0 44真实输入bytes/hash相符，R2/Q0 work不存在，PG配置presence false、EDA进程为空。第一次遍历误把R1工具说明对象当输入项，已按各基线真实schema修正并重核；不存在新增输入缺失结论。
本轮只新增两候选卡/本报告、进度追加及文档JSONL；旧HDK/源码/基线/R1交付、Manifest/PROJECT_STATE/TASK_LEDGER/DB/硬件不改，R1审计例外未扩用。没有新业务源码/参考/TB/功能脚本、EDA/bit或硬件操作。
下一步是共同真实prepared/许可/消费/效果关闭桥和完整实例/资源/服务预算，再形成指定READY版本；R2/Q0已有审批问题仍待答。完整五基础/六高阶软件实现与整包验证未完成，本轮实际有限设计进展不替代该目标。

