# SCAN v0.2／ROW v0.2／整合 v0.8 有限复核

2026-10-04。设计增量已保存、读回并接入；NOT_READY／NOT_APPROVED／NOT_IMPLEMENTED。没有算法源码、功能性脚本、TB、新工具构建、正式状态/数据库改动或硬件操作。完整五基础、六高阶、1080p、完整Canny和原识别要求保持，整包目标未完成。

## 输入与实际阅读范围

| 输入 | 实际摘要／字节 | 证据范围 |
|---|---|---|
| [原SCAN v0.1快照](../../../planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001-v0.1-before-lifecycle-review.md) | BE543B4348AF71D5AD5338A6EB3B8FA26316DE8BCC23673A86B1CBF93A989F37／33581B／223行 | 原全文审阅及反例已保存[原报告](scan-reservation-review-v0.1.md)，不当作新稿通过 |
| [v0.2容量措辞前快照](../../../planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001-v0.2-before-capacity-wording.md) | 05CBA3441C538EB9D9C7BE061A7FD26D3289E57BBE6199B1A700CC857D5E1769／43392B／245行 | 数值实际73–128、176–193、235–241；协议75–129、132–155、166–175、197–230、235–242；生命周期38–52、56–85、98、104–124、140–154、166–174、235–241。读前后摘要稳定 |
| [最终SCAN v0.2](../../../planning/design-TRACK4-ALGORITHM-SCAN-RESERVATION-001.md) | 3D43D45976E3172514A17D5FC53BE869CC9A4BC52F01B3DF339E21E31138E243／43548B／245行 | 与05稿唯一内容行差异L85；生命周期实际读81–85、142–146并比较快照，协议实际83–86，数值定向85；其余继承上行有限范围，不称最终全文重新审阅 |
| [ROW v0.2](../../../planning/design-TRACK4-ALGORITHM-ROW-PIPELINE-001.md) | 1C3E3910583099F4201297540FAD52BFCF69635838B9F3AA0D317308F7A3B2C8／29116B／217行 | 数值26–44、81–99、134–142、144–163、165–181、203–209；协议81–101、203–210 |
| [整合v0.8](../../../planning/design-TRACK4-ALGORITHM-INTEGRATION-001.md) | C7179AADB408D5CB49D28B6649EBBC21E602E20675F5E36246BAAB3132B334DF／51540B／271行 | 数值44–51、234–245；协议23–51、115–132、154–160、234–243、253–267；均首尾摘要稳定，不称全文通过 |

根实际读取SCAN 05稿及最终L85；工具输出合并曾截断110–125，另实际补读109–128，未将截断段当已阅读。ROW/整合原稿已读，当前增量通过真实Compare-Object及定向段落读回核对。三名审阅者均只做授权的文字/只读工作，不经委托生成业务实现。

## 本次解决的有限设计问题

- ARM group在目标边界决定真正提交各ctx后关闭membership，不等ctx DISPOSE；已复制ACK和1292bit cache不持execution pin。历史armed1只重放历史结果，不重装group或授读；真实held运输继续履约。
- PREPARE以存活ctx的不可变摘要精确重建成功结果，失败有独立有限cache；淘汰后的旧seq返回STALE，不同seq BUSY重试不重新解释原请求。失败请求高水位不使已成功ctx/group失效。
- kind3 QUARANTINED允许报告真实前缀和facts，即使不足以证明CLOSED；保留已held普通事件，下一序最多3且不回绕。Q观察立即阻尚未发布的DISPOSE成功承诺，不等待Q通知；成功ACK发布后不可撤，之后故障归独立parent/link健康路径。
- 临时private event/control引用在提出DISPOSE前结束，持久base execution pin保持到正确成功ACK实际消费。V不等未定义FREE消息，D自己的分配器在后续旧资格沿核真FREE；父RETURN仍须其它真实子引用闭合。
- V owner0须汇合D、physical pool和snapshot真实匹配closed_before/applied，核心域影子不能代报视频域已应用；原七owner不增第八。确切下级消息/CDC仍OPEN。
- 最终L85明确收尾状态与容量归属分离：old_closing旧未空时，结束当帧的ctx继续占current额度/use_data,image_valid0，不形成第二old_closing。旧实际画面snapshot在边界先建立pin，再执行ADOPT/SAFE，直到真实RELEASE_ACK保护旧parent。

上述指定范围有限复核未发现新确定反例。它关闭的是原稿对应的文字合同缺口，不是动态协议、实际接线或正常持续显示的通过证明。

## 数值与预算限度

26486＋ARM cache1292＋PREPARE cache1820＝29598bit消息/记录body，已含四CTX3360。成功PREPARE摘要66×4＝264；Q快照111×4＝444，metadata合708；两类列出30306bit。Q可变111与保留的不可变/固定910合EVENT1021；valid/issued等状态仍另计。adapter六slot各增加ref_valid1，632→638bit另列，不重复计入708。

五RowCtx865×5＝4325与四scan840×4＝3360用途不同；1219bit数学payload、局部消息3000、原ROW消息11508各自保持范围。input18＋RX7＋output15＝40 RAM10只为payload候选。没有由这些下界推断总FF、器件fit或100MHz时序；也没有无证扣除原PIO或重复相加3360。

## 接入、授权与下一项真实工作

整合IF10/11/12、OP06和ROW D1/IF06/J现在引用提前exec、四scan及独立physical frame；两physical bundle仅是父对象容量。原PIO/PROFILE/VIEW文件保持冻结hash，由SCAN J和整合接口显式覆盖生产语义。旧ROW90E980与整合5FA045快照保留，原有限审阅仍只绑定其输入。

下一项仍是全局bulk/ROW_ASSIGN/父目录及恢复、下级epoch真实消息/CDC、三bank旧尾行/未选首行周转、两个未来首行和row1/持续行最坏服务、camera/COPY/算法份额、全机RAM/FF/DSP/时钟及确切文件/模型基线。SC-B01…04、RP-B01…05、INT-B01…06均保留，不以新增文档关闭它们。

用户既有IP预检v1/v1.1/v1.2及本地审计例外仍仅其原scope；pending v1.3和Gate卡/manifest保持原hash，无批准或新work。详细规范v0.2 §10.3/10.4仍要求设计无当前阻塞并获指定版本/范围批准才生成业务实现。本轮只使用已有控制面文档/报告/追加本地事件权限，正式PROJECT_STATE摘要保持87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558。

阅读顺序：整合A/B/C→ROW B/C/D/E→SCAN B/C/D/E→G/H验证追踪→本报告的限定与未完成项。软件测试、综合、PNR、STA、bit及用户理解验收均待实际证据。
