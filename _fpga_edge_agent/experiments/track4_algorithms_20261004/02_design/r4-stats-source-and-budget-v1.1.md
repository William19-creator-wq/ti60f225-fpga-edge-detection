# R4 STATS：真实测试源、消费者与完整容器预算 v1.1

2026-10-08；纯设计/NOT_IMPLEMENTED/NOT_RUN，补主卡ST-B01/B02。接口沿主卡token262/STAT632/NUM622/RESP585；没有新业务源码。v0.1保留历史字节，v1补齐有限状态、quiet/故障进展、所有权移交和LED映射。

## 1. 整体位置

stats_probe_top包含同域真实token源、stats_core、注册交接适配者、唯一原fit_core（内含唯一原scalar）、585位CRC观察器和原reset_sync。源码均走真实valid/ready，不预写统计或伪造FIT结果。source在旧统计/数值义务和观察完成前不发下一START。

## 2. 来源字段与每沿更新

静态W1920/H1080/version1/owner0。NUM_ID低到高epoch1/frame0/config1/owner0/current_seq64/destination0。destination不是kind；kind用seq低2位映射11/12/17/18。next_seq只随真实START fire推进，MAX只允许用一次后exhausted；不回绕。共同cold reset可作废整套本地上下文，软件账以reset段另分，不宣称生产epoch恢复。

32位LFSR初值0x43106025；下一值左移1低位填旧bit31 xor bit21 xor bit1 xor bit0。仅真实POINT fire推进，不随停顿/START/END/ABORT/结果推进。所有计算使用旧LFSR/旧cursor；先算下一值，真实fire后才提交。

START E=32+旧LFSR[8:0]（32…543），四kind threshold0，reserved0。其W按下节bad profile可为7；其余正常1080p。header valid后全文保持到fire，成功后锁current_seq、E、threshold；来源检查不借DUT累加器或中间算术。

第一点x=旧LFSR[9:0]，y=旧LFSR[19:10]；若y540改为541。随后每POINT fire令x_next=x+17；若≥1920则减1920、y加1。E最多543、x0≤1023/y0≤1023，最多跨5行，y≤1028<1080；(y,x)严格递增。生产允许全N，probe只采有限实际点；全N另由主核/真实组合测试覆盖，不把这个采样称完整场景。

POINT ordinal=当前cursor低21位；include=旧LFSR[22]或cursor<3。Gx=x−960、Gy=y−540，先在s12减，再核域收s11；Gx∈[−960,959]、Gy∈[−540,539]，保证合法并使所有点的LS法线穿过(960,540)。初始y≠540，头三个必含，前两x相差17且同y，因此LS非平行、原LS中心恰为Q4(15360,8640)。TLS仍使用实际中心坐标统计。点不被宣称位于真实圆上，或一定由Canny产生。

token_slot262由来源拥有。POINT fire后若已有fault或预定ABORT，下一token为ABORT；否则cursor_next<E时用下一位置/下一LFSR组装POINT，达到E时组装END。END声明已真实发送的POINT数，unused0。已公开POINT不能因看到fault重写；fault来时先兑现它，再发ABORT。END/ABORT fire后来源等待结果，不能追加新POINT或新的ABORT；已公开END必须兑现，不能改成ABORT。source_phase用u3明确五态：START_OFFER、POINT_OFFER、CLOSE_OFFER、WAIT_OBSERVATION、HALT。默认FIRST_SEQUENCE=0时复位即准备seq0/seed的START；START真fire才锁current_seq/E/threshold/首坐标并更新next_seq，随后POINT_OFFER；CLOSE_OFFER只发布已冻结END或ABORT，fire后WAIT_OBSERVATION。观察器585位最后bit已处理的真实done沿后才准备下一START；exhausted则HALT。HALT无新valid，共同reset才能恢复；不再添加第二token槽或job队列。

START维度乘积在stats CHECK中以完整u22形成并作E资格；E不从每个POINT动态重新解释。fault提示出现后的源进展明确为兑现一个已有公开token并用原ID关闭，故合法测试源即使故障也不会逼近u22 raw_seen容量；恶意无界源走主卡PROTOCOL_STUCK，不能借回绕结束。

## 3. 正常与故障profile

seq[3]=0是正常；seq[3]=1按低2位选择：

| kind/低2位 | 固定故障与合法收尾 |
|---|---|
| 11/0 | START W7；源仍兑现已发布POINT，看到fault后发ABORT；保原COORD3首错 |
| 12/1 | 正常POINT完成，END.declared_seen=真实数+1；END仍关闭源，统计FRAME_COUNT7 |
| 17/2 | ordinal2的POINT payload[66]=1；已发布后不得改，兑现下一旧POINT后ABORT；FORMAT2 |
| 18/3 | 发送ordinal0…3四点后主动ABORT，不是错误cleanup；无首错时CANCEL_DROP/NONE |

硬件正常递推不断重复这两profile，所有kind均有真实统计和数值调用路径。TB先观察64个闭合source job，再共同reset观察4个新job；另MAX−1尾域两次START后HALT。四kind的数量、STAT/NUM接受/消费、取消/reset和最终CRC分别计，不用CRC单独证明每点正确。

## 4. 注册交接与消费者

一份NUM请求槽622、一份响应/观察共享字585。适配状态声明u4，明确六态：STAT_WAIT、FIT_OFFER、FIT_WAIT、FIT_QUIET、OBS_OFFER、OBS_BITS。STAT_WAIT预留两个单槽寿命，stat_ready不依赖observer释放其他对象，当前source job的START已fire后才可接收其统计终态。StatsOut真实fire时检查原ID/kind/元数据及outcome矩阵；VALUE把完整622请求锁入槽后才FIT_OFFER，全文保持到真实FIT req_fire。n太少是合法统计，不能在适配者用FIT.check_request的LOCAL_COUNT把它误当统计格式失败。非VALUE不发FIT请求，按原REQ身份格式化错误/DROP响应，转FIT_QUIET。

统计层矩阵：VALUE/NONE且原kind11/12/17/18、flags/target/unused全0；FRAME_FAIL只用FORMAT/COORD/COUNT/OVERFLOW/UNSUPPORTED/INTERNAL且payload400全0；CANCEL_DROP/NONE且payload400全0；LOCAL_REJECT不合法。所有原ID/维度/version/kind与source START快照相等；不从body冒认新上下文。破坏矩阵/身份时消费旧stat后以原source预期ID/字段构造FRAME_FAIL/INTERNAL，proto_fault置1，不发FIT。原source W/H/version/kind可由当前seq/profile及冻结常量重建，E/threshold已有槽；不暗加另一份上下文。

FIT_OFFER的真实req_fire后进入FIT_WAIT，原请求槽直到观察完成都不释放。FIT_WAIT具备预约响应容量，不依赖外部观察ready。真实rsp_fire核完整ID/kind/target和原FIT矩阵，保存原585位响应；协议异常消费旧返回后形成原请求INTERNAL错误，不伪造原child输出。FIT_QUIET确认真实fit_quiet及stats_quiet后才OBS_OFFER，不能以固定等待替代实际quiet。probe中原FIT cancel_valid固定0/cancel_id固定0，stats ABORT不另造FIT请求；真实组合TB另按原FIT合同驱动取消并消费/discard。其间来源不换current_seq/上下文。

response_word585在OBS_OFFER时由适配者持有，valid/body不变。内部observer_ready=!rst且移位器未处理旧字，obs_fire=OBS_OFFER&&observer_ready；TB可施加ready反例以检查保持，物理probe通常立即接纳。真实observer_fire把所有权转给观察器、bit_count置0，才进入OBS_BITS；从下一沿开始每沿移位，不再对外宣称原response valid。CRC32初值0xffffffff，poly0x04c11db7；每沿feed旧response_word[584] xor旧CRC[31]，CRC左移后按feed异或poly，response_word左移补0。bit_count0…584，共585沿，最后沿用新CRC更新摘要并返回STAT_WAIT，done为该真实最后沿的组合事件，不添加一份done缓存。只有完整观察结束才下一START。

CRC是连续摘要，不能每个job重新初值。共同rst清CRC/bit_count和所有有效性；独立审核按相同reset段重建。LED0组合映射CRC[7] xor CRC[23]，无额外LED寄存器，最后移位沿后自动反映新CRC；LED1为24位heartbeat的bit23。heartbeat可周期回绕，仅为观察，不用于事务身份或结账。

## 5. 不丢字段的全体容器预算

下表为拟声明的逻辑bit容器，非综合FF、XLR或实测。组合计划/常数不冒充FF；同槽寿命复用明确列出。

| 新stats_core项 | bit |
|---|---:|
| 原ID176与START payload84 | 260 |
| raw_seen22/n21/五56槽 | 323 |
| 旧x11/y11/row资格1 | 23 |
| 状态3/closing_abort1/首错valid1/reason8 | 13 |
| S0六s12 | 72 |
| S1三s24产品/ax-by两s24/a-b两s12/X2-Y2两s12 | 168 |
| S2三s24/ds25/a-b两s12/X2-Y2两s12 | 145 |
| S3三s24/ad-bd两s37/X2-Y2两s12 | 170 |
| 四valid | 4 |
| STAT_RESULT632 | 632 |
| 合计 | 1810 |

| 新probe项 | bit |
|---|---:|
| token262、next/current_seq各64、exhausted1、LFSR32、cursor22、x/y各11、E21、threshold16、source_phase3 | 507 |
| NUM槽622、response_word585、适配状态4、协议错1 | 1212 |
| CRC32/bit_count10/heartbeat24 | 66 |
| 两级原reset_sync | 2 |
| 合计 | 1787 |

原FIT冻结v1的全核候选上界8955bit，来源为已冻结主设计F（已经含其bridge、唯一scalar、四项cache），不再加旧probe或另一scalar。联合保守容器8955+1810+1787=12552bit。stats七状态仍3bit，quiet/fault输出为状态与已有reason的组合映射，done和固定LED选择为组合信号，不多计寄存器。raw_seen越域拒写，不暗加高位计数或循环时代替身份。stats实际模式字段高位可被工具合并，但预算不预先扣这些收益。

原FIT物理48329 XLR含其旧probe/路由，不是可直接再加新stats的全机预算。新source替换旧fit_probe；新scope原六RTL字节不改。候选联合门槛XLR≤56000/RAM0/DSP≤32/25MHz、setup/hold≥0、内部未约束/无clock/多clock0、真实数据D端与四pin验证。未运行时不能声称已经装下或符合全机fps。

## 6. 形成沿、关闭与验证范围

四级统计pipeline与提交依主卡，POINT t0→t4提交。关闭输入END后最后旧点t+3提交、t+4离DRAIN、t+5 PACK后形成valid；要求≤6沿，外部token停顿/输出held另计。ABORT也须管线排尾，不把取消当立即清pending。错误源仍必须用原ID END/ABORT关闭。

适配者约定stat_result_fire后注册NUM、等真req_fire、等待原FIT结果并确认quiet再发表585位观察；FIT计算仍按原已验证16384沿上限，额外注册/关闭余量应在最终测试卡逐沿固定。source的每点可连续交付，不以观察器阻塞数学返回。

R4的真实对象、DDR/源关闭和父上下文寿命是后续生产适配义务；本局部token结束不销毁POINT，不冒写O/VIEW证书。本稿只闭合本独立来源/数学/保持和资源声明，没有执行仿真或构建。

## 7. v1.1：可复现尾域测试起点

FIRST_SEQUENCE unsigned64默认0，物理工程固定0；合法范围0…2^64−1，仅TB尾域实例用MAX−1。共同reset按该参数置next_seq、清current_seq/exhausted，token槽准备同一序号的START；其余所有字段/算法/真实fire更新及有限状态不变。主probe仍64job+reset4job，尾域独立两job使用MAX−1/MAX，必须关闭和完整观察后HALT；不以force改变已公开消息/在途身份。参数是常量，没有新寄存器预算；实际数值仍由独立来源账推导，不从DUT读状态作为黄金。
