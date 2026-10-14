# DENSE v0.3：真实提供者边界、管理源复用与关闭顺序限定审阅

2026-10-05。LOCAL_DOCUMENT_REVIEW / NOT_READY / NOT_APPROVED / NOT_IMPLEMENTED / NOT_RUN。本轮没有新增软件验证结果，不改原五基础/六高阶及1080p、512θ、完整21bit/NMS和原质量要求。

先读[主设计](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001.md) B整体→C职责→D交接→E中文草图→F预算→G/H场景与追踪；再核[数字v0.3](dense-batch-native-numbers-v0.3.json)。[v0.2精确快照](../../../planning/design-TRACK4-ALGORITHM-DENSE-BATCH-NATIVE-001-v0.2.md)保留旧设计身份；历史附件、审阅及事件没有回填。

| 本轮交付 | 行数 / bytes | SHA256 |
|---|---:|---|
| 主卡v0.3 | 304 / 52761 | E47EDE2359FC21C2EE36AB91DB87DA311E355AF92B6016C08B4B1AF7867F0854 |
| 数字v0.3 | 419 / 15097 | 6CFDF10E2AFEB8A291A24004370B6F85DAAA261DA4565E9C516CF2033F31EA19 |
| v0.2精确快照 | 256 / 44444 | CCD1849F6DE1B375693664757CD60C661401F436D52C1EFDF8A03EEFF241E2E2 |

## 有限设计修正与含义

1. 原v0.2把DATA来源借用保留至group退还，与JL88/96要求END/退休前DATA引用为空冲突。现D2/E3按真实prepare/effects/state完成→封DATA门/结引用→独立历史及visible/no-future/END→307正确消费→entry/group退休与GAP→释放CONTROL内容/身份。CONTROL不授新数据访问，UNKNOWN仍须新的实际关闭证明；不是给尚可访问的DATA改名。
2. D4/E0只为固定同core RC↔STORE管理口选择唯一不可变CMD550。STORE与RC私有各独立108动态尾；STORE在真CMD fire锁独立adminseq64，RC先核实际ACK658再捕尾。RC先完成私有处理、STORE再撤本次真实借用/ACK元数据、RC后续GAP才覆写源，双方不互等req_live。旧批次callback先结独立批次账；新RETIRE以自身binding形成ACK。
3. CTX986不含原CLEAR_KEY/tx_seq。现明确RC持久KEY287/lease64/live1和STORE持久KEY287共639bit；不能从已退CMD或新caller重建。实际BEGIN receipt所属、partial expected及责任移交仍OPEN，不能仅凭owned1认定新实例或保证能发RETIRE。
4. 补DN-T17/T18文字场景及REQ06反向追踪；全部未运行。审阅后的两处预算措辞明确纯body减少1650，计入14控制和64binding后所列管理字段减少1572。

## 资源与事件核算

管理550+108×2+14+64=844；持久639；所列927+844+639+986+1466+3466+192=8520，JL六entry及六group增量78后为8598。旧9531未列新增639，表面差933不能称同口径完整FF节省；58028原生产子集已含CONTROL4097，不能与这些异范围字段直接相加。

16个512×20 bank、双WE、三沿导出及32批728块方案不变。186/194是部分RAM分支；8598是所选字段而非全机FF。管理/数据/许可93376单向fire、clear8864地址沿、export425472最小间隔都不等实际帧时间。通用消息RAM仅有容量比较，没有采纳；原RA保持槽/assembly/DDR预清费用继续保留。

## 实际核读及独立范围

root实际读主卡修改前v0.3全1–304、JSON全1–419；末三行237/277/291修改后逐行读回，其余字节差异由逆向检查核对。root另读DIR92–113/133–142、CR125–139、实例预算50–81、JL77–103、BK109–129、RAW130–142、DDR资格1–81和待批模型请求全25行。组合输出被截断的内容没有计作全文。

三位独立只读审阅先在304行/52696B、SHA071504A227B0D5E7ED068F23E353035C77C574B1659E53E056AB920D6528A20B上完成：numeric核76–85/122–142/211–216/234–241及JSON全419行/8来源；semantics核63–109/111–304；cost核79–153/156–162/186–202/234–240并对照JL87–103、BK111–128。末次只核237/277/291及语义265–277，最终SHA按上表登记，结论不扩到未审范围。

| 实际依据 | SHA256 |
|---|---|
| DIR / CR | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA / 487576F7A4DE4B0C3CBAB21ADDF09271ABD1C1E6E1BE6C9DD2BC5146697277E2 |
| JL / BK / RAW | 68308B965400E50B367C7B2D73BA13F777D78501B29047D0B3F3F010E056FDB5 / 2055E6E89AEC07BD1CD8D0048F1961232650D0E7043E1689CF12C7C6D692F060 / 7704C56C6BA653A56E9F27816092E8088786BB05885BF2B613E39F9C4AB6C9DD |
| DDR资格 / 模型请求 | 2C6B710213B6894C05B3F6922CCB1A6AF23BAF5B98B90DE65473FE7A27EB6559 / 422C7423FBFE91827CF7B9E5736DE73B2A0290CB704CA9F2CBF64BA9D0D2615B |

## 未完成与后续最小工作

DN-B01：实际O/SC安装、CTX可信view/撤销、BEGIN receipt所属、partial expected/迁移及真实quiet消息仍未冻结。DN-B02：DN专用prepared/sole-writer effects/物理可见与无未来效果/END/退休桥仍未冻结；DDR Q0即使编译展开通过也不证明该合同。DN-B03：完整唯一实例及失败/取消/allocator exhausted/运输/CDC/assembly字段、端口服务、处理时间与STA仍未完成。

应先在同卡闭合这些具体来源与消息，补完整资源和处理时间账，达到共同指定版本/范围/基线的READY后按[唯一v0.2规范](../../../../AI_Agent_代码可理解性规范_增补提案_v0.2.md)§10.4取得实施批准。R2/Q0原待答批准不重复发问；R1授权和本地审计例外不扩用。原始资料、工具、正式state/Manifest/任务账本/数据库/硬件不改。

本轮有限结论：所审范围无新确定等待环或算术错误，三处具体缺口已修订；实际提供者和完整fit仍OPEN，完整十一项未完成。R1既有123/123、综合/PNR/STA及bit交付保持有效，bit后无硬件步骤。本轮不是新仿真/综合/布线/时序/bit证据。
