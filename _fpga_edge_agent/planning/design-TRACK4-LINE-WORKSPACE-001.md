# TRACK4-LINE-WORKSPACE-001 v1：CELL/EXT 单行事务回调

2026-10-11，READY_FOR_PARENT_REVIEW / NOT_IMPLEMENTED。按 PLAN_TEMPLATE 合并短卡。父明确授权本轮仅保存、实际读回此卡；其后由父限定候选实现，当前不生成RW源码、TB、模型或EDA。用户持续自主推进、本地审计和免长草图/独立测试授权沿父任务；不伪称此指定卡已有实施批准。人工硬件闸门不变。

## A/B/C. 目标、来源与边界

- Goal / Target：唯一 `MOD-RW` 完成固定4096项DDR表的 CLEAR、一个 CELL48/EXT80 条目的 UPDATE/READ，保持全部真实子位置及上一预约写回顺序。拟新单文件 `work/active/track4_board_first_20261011/candidates/line_workspace_v1/board/rtl/board_line_workspace.sv`；当前不存在业务before，不伪造hash。
- Current / Gap：RP数学候选已生成，最终SHA `6A39008486EB5ECE401690743DC6DE868E71390955BFD3157C961E0D0893DDC3`，尚未主集成或EDA；没有RW。完整RECT路线仍未READY。本块不做49票/NMS/run/SEG/TLS/PAIR/RECT，不新增NUM、STATS、ANGLE或NUM标签。
- Sources：原R4 E4/E5及其记录表，SHA `AA05866FD496CC73FC45ECCDED7DE2F68EC59037392DA8476A6016CCA3B91257`；ALGORITHMS OP04，SHA `D8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB`；EXECUTION EX-OP04/05，SHA `F664C3C26B25AB33A4885DF5500672D811939B6FCBD650524DC6B21294962178`；当前RECT短卡 SHA `25242C5722176970259AF3E87FA9069590576E1BE1C792E4845AA0DBB8521EC9`。count/min/max/valid及EXT old_count是旧逻辑字段，submask16是已列补充；本卡不改变成员谓词。
- Actual reuse：已读主 `board/rtl/board_native_rpc_arbiter2.sv` SHA `0E8A204EE18E594CDD9AC9D19283408C0BF65D160251A7998F7CCC9A02F35D7F` 的请求选择/接受/回复消费三个事件与drained；主 `board_gradient_store.sv` SHA `6AD8388D53348025F6CAECEFB4441F22954284A383B934F14655D7F2B5C381B9` 的 COMPLETE阶段PACK0…7整块暂存及 ORDERED_PACK；Hough SHA `73ADB9BD92C061621497ED1FED282CDA7D748579DCEAE7504EB78AF32D44E427` 的LINE64/META layout3；STATS协议 SHA `6C1D9F00E60EB42F2F916F3F536F23ECCC2053FD34AAC4A8D0D56C44BED7B511`、geometry wrapper候选 SHA `14228BE6277F5CDC5989D1D002D62C4590514E941BDEF5D55530D76527835A22`。这些接口只定位父交接，RW不实例化统计或数学核。
- Assumptions：单core正沿、共同同步高rst；父有本scope的独占表修改权，取得当前native/PACK物理归属，能暂停点推进；显示/摄像头其它不重叠DDR访问可由现arbiter串行仲裁。父保持POINT05000000及LINE有效前缀；LINE实际8项/64B，非64B一项，阈值与META一致。
- Connection：`RL持有点/冻结成员 → IF01 RW命令 → IF02一行DDR读 → RW行RAM → entry核查/更新 → IF03完整PACK → IF02真实写回复 → IF01 held回调 → RW quiet后下一点`。POINT读回复须先复制到另一个32×16 RAM并真实消费，不能held同一native回复等待RW读/写。
- Dependencies / Open：父工作区33bit范围/不重叠核查、全表CLEAR成功屏障、callback ID序号/PACK owner接入及真实资源尚未闭合；不阻塞此精确局部契约。RW不为父自动授权地址。Milestones：卡实际读回→父限定单候选→静态差异读回→以后父整机EDA。当前停止点为父读回。

稳定要求：RW-REQ01 全4096清表真实关闭；RW-REQ02 CELL/EXT逐点精确RMW及全部submask；RW-REQ03 canonical记录/128与512高零；RW-REQ04 单预约、借用/反压/真实关闭和UNKNOWN隔离。

## D. 接口与记录

### IF01：一次命令、一次held回调

参数拟 WIDTH=1920、HEIGHT=1080、ADDRESS_BYTES=33'h10000000、BORROW_COMMAND=0。WIDTH/HEIGHT沿原板域；本模块不降低E或场景。无暖cancel/timeout；父停止只停新命令并等已接受命令关闭，共同冷rst才作废未知归属。

| 命令输入 | 位宽与规则 |
|---|---|
| command_valid/ready，command_id | ID176，低96为父锁scope，owner[103:96]必须0。高72是父callback域身份；建议父固定为 `{rw_cold_sequence64,operation_context8}`，不属于NUM C4/C5标签空间。RW回显完整ID，不自造NUM身份或重写父scope。 |
| command_op | u2：0 CLEAR_TABLE；1 UPDATE_ENTRY；2 READ_ENTRY；3非法已知输入错误。 |
| command_table | u1：0 CELL48；1 EXT80；在同一命令内不变。 |
| command_base，command_points | base u32，64B对齐；固定65536B表全范围用33bit加法核≤ADDRESS_BYTES且不回绕。E u21≤WIDTH×HEIGHT；CLEAR/READ允许E0，UPDATE E0已知COUNT失败，未发DDR。 |
| command_index，command_sub，command_old_member | index u12（0…4095），sub u4（0…15），old_member1。CLEAR的index/sub/old须全0；READ的sub/old须0；CELL UPDATE的old须0；EXT UPDATE允许old0/1。 |

默认快照准确 **249bit**：ID176 + op2 + table1 + base32 + E21 + index12 + sub4 + old1。BORROW_COMMAND=1只借同一完整249bit视图，不按command_valid撤销/置零；父从真接受保持全部字段至回调消费且RW quiet，UNKNOWN保持至共同冷rst。默认0接受后可撤原命令输入，但父仍保持物理归属和表所有权至RW quiet。

输出：response_valid/ready、ID176、op2/table1回显、entry80、cleared_entries13、error/drained、quiet、sticky fault/quarantined。READ返回完整canonical低80；CELL高32零。UPDATE返回写回并真正关闭的完整新entry80；CLEAR返回entry0、cleared_entries4096。已知失败entry/cleared_entries零，error1/drained1；UNKNOWN error1/drained0且隔离。空条目是合法全零，不是未执行或错误。response_valid之后所有回应字段及值在反压中不变；fault/quarantined是另列sticky诊断。

父只在匹配ID的真实回应消费且RW quiet之后推进自己的rw_cold_sequence。序号从共同冷rst初始化，不每帧重置；MAX命令可接受一次，实际关闭后父永久禁止新命令、不回绕。RW不另开重复64bit序号寄存器；父没有此保障时不能启用这组callback调用，也不能仅靠RW echo声称身份可重用。RW未接受命令时的异常native回复不得伪造callback。

### IF02/03：原native DDR和无ready PACK

原 req_valid/ready、req_write、addr32；rsp_valid/ready、data512、error、drained，单在途。base+65536用33bit核完才收addr32；条目地址 `base+16·index`，块地址 `base+64·floor(index/4)`，slot=index mod4。没有有损地址截断。

请求地址/write保持到fire及回复真消费，native_pending只在真fire置1、真回复消费清0。drained是现arbiter本调用者真实服务排空，包括空闲态，不把rsp_valid=0当drained。quiet需本地IDLE、无native_pending、无rsp_valid、真实drained、未隔离；若后续适配器不提供空闲态drained，须补真实native_quiet输入，不能硬接1。父的PACK owner保持至命令quiet，其他生产者不得交叉改八槽。

读success回复held时，32词按低到高复制至RW RAM；仅复制完后ready消费。原回复消费后才改RAM/发另一个native事务。复制前后均检查owned pending、valid/error/drained；已知error且drained可真消费后失败；未drained/held valid丢失/无pending回复为UNKNOWN、不冒close。写回复也只有drained才能消费；error1/drained1是已知失败，未知排空不消费。

PACK valid无ready；唯一父保证已 COMPLETE缓冲可逐拍接受，index必须0…7完整连续发，data64。最后index7接受沿写好父暂存，下一状态才发WRITE请求；无同沿抢读旧第8词。UPDATE完整重发64B，另外三个条目保持原样；CLEAR完整64B全零。借父现512bit缓冲只计一次，不在RW复制第二份512FF。

### IF04：固定条目，低bit/低byte在前

| 记录 | 精确bit布局，每项DDR stride128bit |
|---|---|
| CELL48 | count[20:0]；submin[24:21]；submax[28:25]；valid[29]；zero[31:30]；submask[47:32]；zero[127:48]。 |
| EXT80 | count[20:0]；old_count[41:21]；submin[45:42]；submax[49:46]；valid[50]；zero[63:51]；submask[79:64]；zero[127:80]。 |

空项必须完整128bit0。非空：1≤count≤E、valid1、mask非0、min/max分别为mask真实最低/最高置位位置、min≤max，count≥popcount(mask)。EXT还须old_count≤count（空项old0）；保留zero全0。不是只有min/max合法就假设中间填满。逐点UPDATE前检查被读行 **全部四项** 的上述canonical/高零；任何项坏则已知INVARIANT失败，不进行写。READ同样检查整行后才返回目标，不发布未核的有效前缀；CLEAR不信旧内容，完整覆盖全表。

UPDATE语义固定：父仅对当前新成员真实include=1调用；count总加1，mask OR (1<<sub)。CELL old_member必须0；EXT old_count只在同一点满足冻结旧成员时加1，old0只加新count，不能有只加old而不加新count的操作。重复sub仍加count，不重算mask占位次数。min/max是new mask真实极值（空项初次均sub）。count/old先用u22扩展候选核高位、≤E、old≤count，再提交u21；不饱和或回绕。RW不替父重判M0/M1/M2，未知POINT重复/ordinal由RL扫描负责。

CELL双表各4096项、1024整块、65536B；EXT在全coarse及旧预约关闭后才复用CELL0。固定表不存在“只清/只核有效prefix即可成功”：必须全4096项定义，只有CLEAR最后第1024个真实写回复关闭才回应成功。失败时已写DDR前缀不能回滚且不能当完整表使用；父整帧失败并废弃工作区，不把部分清表当成功。

## E. 有限存储与逐拍微表

一个RW RAM10，32×16bit，单同步读/单写，复制32词先全部覆盖后才读取；不复位数据、不用同址WRITE_FIRST假设。行cache与POINT cache是两个同时活的512bit寿命，**预算两个RAM10**，不得合算一个。RW内entry80（UPDATE后要保持到成功回应）与pack64也同时活，不能生命周期假合并；不额外保存entry128/完整512FF。

| 步/状态 | 当前输入/旧状态、真实沿动作、后继 |
|---|---|
| IDLE→CHECK | command真fire才取得预约；默认快照249，borrow不复制；公共输出无回应。CHECK先核参数/owner/op/规范字段/33bit表范围/E；错误不发DDR，形成已知失败。 |
| CLEAR_PREP→ZERO_PACK | block10从0开始；每拍PACK0…7 data0，共8实际接受沿；第7后才WRITE_REQUEST。此路不读旧RAM或DDR。 |
| READ_REQUEST→READ_WAIT | UPDATE/READ一次读块；ready fire置pending。WAIT无valid可任意停顿。valid且drained且无error开始copy；已知error真消费后失败；drained0→UNKNOWN。 |
| COPY32→READ_RELEASE | copy_index0…31，每实际沿RAM[copy_index]写rsp_data相应16bit；rsp_ready0，held回复保证稳定。最后词写沿之后进RELEASE，次沿才ready真消费；无读回复借用残留。异常时抑制RAM写、不发布局部cache。 |
| ITEM_READ→ITEM_CAPTURE→ITEM_CHECK | 四项slot0…3，各词0…7。每词一个READ沿给固定RAM地址，再一个CAPTURE沿使用已得q。低五词组同一个entry80，上三词核零；CELL词3/4全零且词1[15:14]保留零；EXT词3[15:3]保留零。第8词capture后另CHECK沿核规范，不能用旧entry漏最后词。全部四项核完只存累计bad，不另存目标。 |
| CHECK_LINE→TARGET_READ→TARGET_CAPTURE | 行合法后，目标slot再低到高完整8词、各READ/CAPTURE一沿；第8词之后才进TARGET_CHECK。目标RAM未改且再次读全，私有entry80现在就是目标。 |
| TARGET_CHECK→READ_RESULT / UPDATE_PLAN | READ返回完整目标80。UPDATE根据原目标及锁sub/old计算u22候选、mask、极值及零；资格失败无DDR写，成功更新私有目标80，下一状态才STORE8使用新值。 |
| STORE8 | 目标slot的8个16bit词逐沿写RAM，来源固定canonical `{48'd0,entry80}`；CELL高32也规范零。所有8词完成再发RAM读，禁止依同址读写返回语义。 |
| PACK_READ→PACK_CAPTURE→PACK_EMIT | 32词低到高，一词READ沿/一词CAPTURE沿；每4词shift成pack64，第四capture后另EMIT沿PACK当前index。完整index0…7后才WRITE_REQUEST；entry80仍保存用于成功回调。 |
| WRITE_REQUEST→WRITE_WAIT | 请求真fire置pending，64B父暂存保持；WAIT无valid停顿。drained回复真消费：error1已知失败；success对UPDATE形成结果，对CLEAR第0…1022块递增块地址再ZERO_PACK，第1023块形成cleared4096成功。 |
| RESULT | 冻结ID/op/table/entry/cleared/error/drained到response真消费。消费之后才IDLE，quiet还须native真空闲。全表/下一点推进是父在quiet后的动作，不提前切scope、点或表。 |
| UNKNOWN_RESULT→ISOLATED | UNKNOWN不消费归属不明native回复，error1/drained0回调一次且held；回调消费后隔离，ready/quiet均0，借用正文持有至共同rst。无已接受命令的UNKNOWN直接ISOLATED，无假回应。 |

ITEM_READ的全四项遍历可用一个entry80扫描寄存器加一个目标80保留寄存器；两者在扫描其它项时同时活，必须诚实计 **160bit**，不是上面目标80就能单寄存器完成。允许替代为整行核完后重读目标8词以只用一个80bit扫描/目标寄存器（增加16内沿，不改外部握手）；本卡选择 **先全四项核完，再重读目标**，因此只用一个entry80。READ再次目标8词后直接回应；UPDATE再次目标8词后计算、STORE8、PACK。首次四项扫描后只存规范累计bad，不借旧entry取目标。

晚异常优先级：共同rst最高、同时禁接受/RAM WE/PACK/native请求；其余任何无pending回复、复制中held协议破坏置sticky fault/quarantined。尚未valid可形成UNKNOWN。**已处RESULT且valid的late异常不能撤valid、改已发布body/数值/error/drained或换成另一回复**：只置late_isolate并保留held回应；真实回应消费沿若late_isolate或本沿late异常就进ISOLATED，不能先IDLE接受下一条。父看到sticky隔离必须废弃本帧，旧成功回应不授权复用坏端口。无本地自动重试、取消或伪造排空。

正常路径没有来源未写先读：UPDATE/READ总copy全32词；CLEAR从不使用cache；所有目标写完成才PACK；PACK32词全读完后WRITE；写失败不发布条目success。连续同cell或同block的下一命令一定在上次write true close和callback quiet以后重新DDR read，能看到上次写回，不依旁路或缓存一致性猜测。

## F/G/H. RTL、成本、文字场景与追踪

数值无舍入：22bit加/33bit地址检查后收窄；mask16/极值4与记录同域。单clk同步rst，无新增CDC；valid0不把RAM正文当0。RAM读写按上述分阶段，气泡和背压不推进游标/身份。未引入C++或跨语言模型，因本卡仅现RTL事务协议；数学谓词仍由RP/RL负责。

资源预算（非实测）：RW1 RAM10逻辑512bit；默认snapshot249 + entry80 + pack64 + addr32 + block/cursor/状态/标记约60…90 = **485…515 FF**；borrow去249但不保证实际XLR下降。POINT缓存另1 RAM，另点64及游标由RL计；父现PACK512只复用不重复计，不能把它当零资源凭空消失。32选1的DDR16词选择和四项规范逻辑会用LUT，具体面积、路由、Fmax仅以后实际工具给出；无新DSP/NUM。

无stall时，UPDATE有两次native事务（64B读+64B写）、copy32沿、整行四项读128沿、目标再读16沿、STORE8沿、PACK读64沿+8 EMIT沿及有限检查/请求沿；不是一次函数调用等于一cycle。CLEAR1024真实write、8192 PACK沿及每块真实请求/回复等待；READ一个read，copy32+整行读128+目标重读16及检查。外部stall无限时无固定完成时间，不能以初步代码宣称实时。

| 文字场景（未运行，不生成TB） | 要求/接口与期望 |
|---|---|
| 空表初加sub15、再加sub1、重复sub15 | REQ02/03 IF04：count1/2/3，mask8000/8002/8002，min15/1/1 max15；重复不填中间。 |
| EXT新点old0再old1 | REQ02：count1/2，old0/1；old只随新count同次更新，empty old0。 |
| count=E或old>count、mask/extrema或任意行高零坏 | REQ02/03：候选扩展/全行规范失败，消费已drained读后已知失败；不发write，不截断或发布未核prefix。 |
| CLEAR末块背压或失败 | REQ01/04：第1023块成功真回复消费以前无success；失败前缀不当整表成功；1024写全部close后4096。 |
| 同cell连续命令、native read held期间换POINT/发RW | REQ02/04：上次write/回调/quiet后重读；父必须先copy POINT并消费，违反双缓存次序不可集成。 |
| PACK第7与WRITE、借用输入/response反压 | REQ03/04：第7先接受次状态才write；249字段和80回应保持；无ready PACK父容量前提必须满足。 |
| unknown drained0、无pending回复、RESULT晚异常、coldrst | REQ04：不伪close，不制造未接受回应；已valid不撤/不改，消费后隔离；共同rst禁WE并作废旧预约。 |

反向追踪：计划CHECK/地址与canonical字段→REQ03/IF01/04；CLEAR/ZERO_PACK/W_CLOSE→REQ01；COPY/ITEM/UPDATE/STORE/PACK→REQ02/03；pending/RESULT/UNKNOWN/late_isolate→REQ04。每核心单元都有此对应；不生成无关算法。以上为文字检查计划，尚未模拟、编译、综合或硬件验证。

## I/J/K/L. 门槛、恢复与交付

接口/各字段、局部微表/两个缓存寿命、全128/512零和真实关闭、错误/晚异常及文字追踪已在本卡可读；完整后端、父接入、资源实测与人工效果仍明确未完成。当前不存在阻塞此独立RW定义的数学缺口，但它不能自己补齐未设计RL/RECT。

本版完成保存后须实际读回、计算SHA并呈现给父；父未读回并限定candidate编码前不实现。本轮没有业务文件、运行脚本、TB、EDA、新主XML、数据库或硬件操作。获批后仅候选一个新RTL文件，原资料/031/058/059 frozen不可改；取消候选/不接main是可逆恢复，已写DDR不能自动回滚，实物步骤仍人工。

完成条件：本卡实际读回及父限定范围只是允许候选实施；真正交付还需源码一致性、父整包native/PACK/ID接入及必要实际EDA证据，不把静态可读当完整矩形识别或实物通过。阅读次序：RECT整体B/C→本卡D记录/接口→E微表→以后单候选源码；没有理解验收作答，用户已理解状态待检验。
