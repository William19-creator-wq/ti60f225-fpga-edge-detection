# production actor access pin61 与四 D0 loan 的有限审阅

2026-10-05；纯中文设计审阅，NOT_READY_FOR_REVIEW / NOT_APPROVED / NOT_IMPLEMENTED。本记录不改旧 planning 卡，不生成生产 RTL、TB 或脚本。61来自本轮 Root 的未冻结候选消息，不是旧来源已证明的事实。R1 软件实现已另行交付最终 r1_shell_005，不能升格为本生产结构的验证。

## 1. 实际有限阅读证据

按控制入口重读/绑定已读规则，R1运行前后22冻结输入含根AGENTS、控制AGENTS与唯一根v0.2均实际hash不变。本次只读以下段与相应定向检索；不是全文联合重审。

| 原文件 | 实际段 / 行 | SHA256 |
|---|---|---|
| design-TRACK4-ALGORITHM-PRODUCTION-DIRECTORY-001.md | D2–D4 L94–128；定向检索L155/157/214/215 | 201E4AB9A5DF7D7E2ECFA96707D1A455367B955CD1E74940197C5A990692FFAA |
| design-TRACK4-ALGORITHM-CONTROL-RECORD-RAM-001.md | C/D1 L54–75；E相关L138–147，定向L132 | 4F3454BC6467136DFAABE0590A4308AA4BD51E7160529BEFF12A7227143BC662 |
| design-TRACK4-ALGORITHM-PRODUCTION-ROW-HANDOFF-001.md | D L94–100；E L136–140；定向loan/RETURN来源 | F0E52EE46843C1E9782E52A6AE1891F7AD125D064EA5CB44555AAF7806524C67 |
| design-TRACK4-ALGORITHM-R4-RECOGNITION-001.md | D1/D2 L102–119，D3定向L130/134 | AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257 |
| design-TRACK4-ALGORITHM-PRODUCTION-IO-001.md | D接口L144–153；资源L176–182 | 39EA4322BB89B21D8CD73F36AF7D630936C7B7F2B53691532765034DC4C2DE10 |

这些来源在本次末尾重新hash，值与表一致。文中“原文”均指这些实际范围；下面带“候选”是新增联合设计要求。

## 2. 先整体区分寿命与访问资格

原目录D3 L110区分owner/base、父引用、信用、版本和访问pin；L108要求原holder全文/真实phase/pending/权限。不能把VIEW父ref、PLAN keeper或SCAN snapshot存在，直接解释为新DDR读取grant；也不能删掉这些寿命层来省资源。

候选整条路径为：实际holder分配并冻结原请求/独立代次 → O按原完整对象/version/phase分配访问pin → 后代ROW/R_ROUTE/RX只借原许可 → 原DDR/journal/native/held/effects关闭 → O冻结本份返回决定、真实一次减计数 → 保留RETURN/ACK/冷记录/退休元数据 → 原所有运输与退休CMD/ACK闭合后才能复用holder与pin槽。返回成功、物理对象FREE、pin槽可复用是三个事件。

RING_LATEST候选只保base寿命，access pin=0；若它需要普通字节读，必须另经COPY或明确新访问actor。目录原holder_kind6的存在不能偷授RING_LATEST READ。CURRENT/old PLAN keeper等同理只按自己的父/快照寿命保留。

## 3. 61的算术与必要额度规则

| Root候选 cohort | 上界 | 成为上界需要的实际规则 |
|---|---:|---|
| SOURCE | 8 | 原目录L127的7成功+1预检；reserved/closing/returned_metadata/Q均占本角色/槽，不加“旧metadata免费槽” |
| ALGORITHM | 32 | LOAD/GRAD3 + CLOSURE3 + RC26；每项包含旧held/effect/return metadata，旧权限与关闭记录全闭合才新grant |
| 四exec full-plane loan | 12 | 四真实D0 loan×最多3plane；ROW/R_ROUTE/RX借原grant，不重复ACQUIRE；closing与D0退休未闭合也占四额度 |
| 单COPY | 2 | ring READ+SRC WRITE，包括其closing/return metadata；旧COPY退完才新COPY |
| CAMERA | 3 | futureARM/current/closing各一真实权限；旧PIO仅两ctx，需明确增量合同 |
| RECORD observer | 1 | 单独真实接口、holder、phase、关闭与额度，原RC RECORD业务对象不自动提供reader接口 |
| 独立REPLAY | 3 | SRC/EDGE/ANN，旧组三pin/返回元数据全退出才下一组，不能current3+closing3 |
| 合计 | 61 | 8+32+12+2+3+1+3 |

RC D3 L134确有object0…25：EDGE、GRAD、POINT、21个workspace对象、ANN、RECORD。POINT已经是object2，不能再为POINT读/写转换机械增加两pin；同一pin access READ/WRITE/RMW的变更必须真实结束全部旧ordinary child/effect/held/metadata后重新授予，禁止旧WRITE仍在closing时当作可原地覆盖的READ资格。RC RJ2257与BIND的source元数据/profile资格仍须明确是寿命/base引用还是另有访问pin，不能为达到26隐含删原义务。快速闭包即使队列为空，已分配QUEUE权限仍在闭包三pin额度中，除非联合稿给出真实never-granted分类。

这仅是有条件cohort上界，不是normal服务或容量证明。64表中3余槽不能自动吸收第四camera context、REPLAY旧组三metadata、第二COPY或新observer。若允许任何此类重叠，61需重新计算；不能用CAPACITY拒绝正常目标替代约束与吞吐证明。

## 4. 四 D0 loan 的真实owner、mask与返回

原CONTROL RAM L58、L69：D0 loan唯一业务owner为O，四份原OPEN387+borrow64=451，base184/207/230/253，各23词。RAM engine只保存记录，不决定权限或返回；ROW不能成为第二writer，O也不能由D0 valid0推出never-created。

原HANDOFF L98：OPEN mask是整exec并集，mode0=011，mode1/2=001，mode3=010，mode4=011，mode5=111。原OPEN无target_y，mode0前540行RGB001、后540行EDGE010；L100要求逐行mask是原OPEN并集子集。完整plane ref/version/base/capacity/commit/pin/父登记另在真实目录，451不是全部对象目录。候选四loan各保存同一整exec mask的至多3pin，不能把首行001存成全loan范围。

原CONTROL RAM L132明确O可在D0尚valid0/写中时已真实创建loan；先真实目录/pins，再写23词，再写OPEN缓存，之后对外GRANT。候选必须预留整mask的所有pin与回执/冷记录资格后建立唯一loan，途中STOP保同一次创建事实；不能因body部分写入而创建第二次。若分步grant，partial真实授予必须记录并独立返还，不能回无pin失败后遗失已授权限。

原L138：BULK_CLOSE真实决定先冻结，正确cache memory ACK后ACK499对外；实体FREE与回复/value-cache独立。原L143–145：RETIRE_RECORD锁旧完整record逐词比较，撤valid后仍等正确RETIRE ACK和残存CMD/DATA/ACK/pending再复用。此规则不要求本次RETIRE CMD/ACK先消失，也不要求依赖退休才能形成的最终FREE先成立。候选四份额度必须包含“已经返pin但D0仍RETURNED_METADATA”的旧loan；typed cache只是完成值副本时可以与原holder脱钩，但应明确已无原记录借用，重放不得复活grant。

原HANDOFF L138/L140明确whole loan先真实关闭source读/fill/route，再返O，不等output银行整体FREE；已发布ROW须真实OWNED及producer ACK通路闭合，CORE_CLOSE才可冻结。不得反向规定“output完全FREE才能返loan”，也不能因INPUT_RETURN或末R便提前返whole loan。归还metadata应保存原OPEN/borrow、整mask、各原ref/version/grant、原phase/关闭决定与当前运输/退休事实；具体cold/hot分布与唯一writer仍是新联合稿义务。

## 5. 精确最小反例

1. **recognition_id0误当不存在。** RC D1 L104–108允许授权epoch第一recognition_id=0；H160=JID96/recognition_id64。目录D3 L106的holder_generation要求独立非零。直接把recognition_id填generation会拒绝第一合法RC，或把它当NONE丢义务。`recognition_id+1`也会在最大合法FFFFFFFFFFFFFFFF溢成0。候选须独立nonzero generation allocator＋exhausted，完整原H160/RJ另存并逐字段核；generation/index/epoch只有回链资格，不能代H160。

2. **mode0首行mask替整loan。** 借RGB001，前540行合法，目标540请求EDGE失败；新补grant会变原loan身份且无法用旧OPEN451正确归还。必须初始整loan011，逐行001/010分别授权。

3. **returned loan免费复用。** 四loan均已BULK_CLOSE决定，四D0退休ACK被stall，若因pin count降到0便开放四个新exec，会有四旧metadata+四新holder，四D0容量及12plane候选立即失效。应复用屏障包含旧冷记录/返回/运输/pending，独立完成值cache脱钩须有真实复制关闭事实。

4. **child重复ACQUIRE。** 四mode5已有12plane grant，若一个ROW又对三个plane ACQUIRE，形成15；再叠加其它cohort可能超64。ROW/R_ROUTE/RX必须借原grant且whole loan返回前证明这些引用全部闭合，不得自授新parent pin。

5. **相同holder slot换代。** 旧CLOSING return还在held，实体slot被新actor复用；若lookup只比较slot/epoch甚至H160低位，旧RETURN可能减新pin。必须完整ref/version/grant/borrow/holder-generation核，旧主体独立保留到真实闭合；unknown不减计数、不清表。

6. **camera第三资格偷用两ctx。** 原PIO L179仅current+closing两份280。旧closing未退出、current正在写时为nextSOF预留futureARM，需要第三份真实body/pin/ACK与独立deadline/旧会话路由；不能只改pin算术3而复用旧current记录，或等closing结束再ARM并声称no-loss。

## 6. 本轮结论与剩余范围

61算术可作为新候选的检查目标，但依赖上述每cohort旧metadata额度、独立代次、原loan整mask、共享子引用和不可穿透提交。原DIR-B02/03未关闭；camera第三ctx、RECORD observer、各算法stage完整实际holder/消息、权限转换、返回hot事实、generation allocator/耗尽、native端口仲裁与全文比较成本必须在联合稿具体列出。五ring复用deadline与DDR实际服务、提前ARM/no-loss和全机热FF/CDC/实际布局时序仍需独立证明，本记录不以外部服务OPEN否定内部候选，也不以61<64声称READY/fit/可持续。
