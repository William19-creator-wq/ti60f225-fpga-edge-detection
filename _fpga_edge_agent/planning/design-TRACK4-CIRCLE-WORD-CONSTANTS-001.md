# TRACK4-CIRCLE-WORD-CONSTANTS-001 v1

2026-10-12，短变更卡，READY_FOR_REVIEW；继承用户“自行进行无需批准”、免新增长草图/独立测试与本地审计例外，不声称本卡获得新的逐版人工批准。只在独立候选生成三份自写文件，ROOT实际读回呈现后实施；062冻结输入、031交付包及原HDK不改。

- Goal / Current / Gap：061全圆整机综合成功但packing72282/60800失败；CR自身1730 LUT、427 FF、1 RAM。旧CR为每个常量来源生成完整128位多路选择，再一次加载A/B；改为16位常量词复用已有八字移位加载器。保持数学、128位全部符号扩展和原NUM192/385资格，不减少输入范围、候选数或算法步骤。收益尚未测量，本卡不能单独保证解决11482缺口。
- Baseline：当前main/062的CR SHA9785CCF94B22BC0898B32B80E36B20BD2FAAB262DEBF547FFAB7D71DEFC17D03，CF SHAF4DFA1899D15A061C5E1437C27C58609F112FCC2136661DBDEFDFE4A31ADD3E7，RPC SHA35AEB6B51F957388D60EEADDF81B298433C4E6661B03D098872E1968928A99EE。候选路径candidates/circle_word_constants_v1；只改此三份RTL。
- Target / Scope：CR追加WORD_CONSTANTS默认0；CF追加REDUCE_WORD_CONSTANTS默认0并只透传给唯一CR；RPC的唯一CF实例显式1。default0保留原128bit constant_source与单次常量加载，其它数值/DDR/STATS/ANGLE/FIT/PM、FAST/RADIUS flags不动。

## 接口、局部与语言契约

公开端口/消息不改。同core正沿，command ID/op/data仍借用至response消费且CR quiet；UNKNOWN保持至共同冷复位。每个PLAN原来就置word0。WORD_CONSTANTS1时，常量来源与RAM来源同样经过A_READ/A_CAPTURE或B_READ/B_CAPTURE共八个词：每个CAPTURE移入当前16bit，word7完成后进入下一个操作数或NUM_REQUEST。低词先入，八次之后word0在[15:0]、word7在[127:112]；没有第二个bank/RAM/NUM核，也不在NUM在途时重装A/B。NUM_REQUEST前两个完整128bit已安装；原signed到192bit扩展、REQ622、RSP585/全25词资格/八词REG_WRITE、结果消费/真实quiet、冷序号MAX、失败与held回复完全保留。

常量词必须从下表原字段直接分常量case选择，不先生成128bit再动态切片。unsigned高词零；signed最后一个部分词及后续词按原字段符号扩展。默认非法source的词零，与原constant_source一致。

| command_op / source | 原完整字段 | 16bit词及高字 |
|---|---|---|
| 任意 /30,31,32,33 | 65535,4,16,64 | word0分别ffff/4/16/64，其余0 |
| 0 /16 | command_data[38:0] unsigned39 | [15:0]、[31:16]、{9零,[38:32]}，其余0 |
| 0 /17 | [59:39] unsigned21 | [54:39]、{11零,[59:55]}，其余0 |
| 1 /16 | [77:60] unsigned18 | [75:60]、{14零,[77:76]}，其余0 |
| 1 /17,19 | [48:38] /[59:49] signed11 | word0补5符号位，其余全符号 |
| 1 /18,20 | [18:0] /[37:19] signed19 | low16，[2:0]余位补13符号，其余全符号 |
| 2或4 /16,17 | [20:0] /[41:21] unsigned21 | low16，余5位补11零，其余0 |
| 3 /16,18 | [63:21] /[150:108] unsigned43 | 两完整词，余11位补5零，其余0 |
| 3 /17 | [107:64] signed44 | 两完整词，余12位补4符号，其余全符号 |
| 4 /18 | [94:42] unsigned53 | 三完整词，余5位补11零，其余0 |
| 4 /19 | [101:95] unsigned7 | word0补9零，其余0 |
| 4 /21,22,23 | [138:123]/[154:139]/[170:155] unsigned16 | word0原字段，其余0 |

常量加载原来每操作数READ/CAPTURE两沿，候选每操作数16沿，故每个常量操作数增加14沿，每NUM微步最多28沿。RAM操作数加载、NUM算术、资格与公开返回值不变；不声明周期等价。command_ready在真实quiet前仍低，停顿不推进数值/PC。额外循环有固定八词上界，不改变成功/局部拒绝/整帧失败集合，私有RAM读数据在常量分支无效但不当作数值使用。复位、clock/CDC、取消契约均沿原实现。C++不适用。

## 实施、检查、追踪与关闭

- Milestones / Detailed steps：ROOT读回呈现→保存三份before→追加默认0参数/16词函数/仅A与B加载分支/两级父flag→实际diff读回→父按真实资源决定接入一次新run。不得改062 flow或其它旧候选。
- Validation：逐对照所有字段/常量的word0…7，特别signed11/19/44负数及部分词；正负零、最大值；八次移位词序；default0全文旧路径；每次PC真quiet后才改source；外国NUM回复不消费；MAX不能启动下一NUM；HELD回应与UNKNOWN保持。只源码/diff静态读回，不生成TB或功能脚本。
- 双向追踪：完整整数与数值域→原constant_source字段→新constant_word16表；真实请求身份/归还→原NUM_REQUEST…NUM_CLOSE原文→仅加载前的固定八词循环；原兼容与主板使用→CR/CF参数默认0及RPC显式1。
- Budget / Failure：FF/RAM/DSP不新增，复用原word3bit、operandA/B各128bit；新增组合formatter16bit，工具净LUT/路径尚未知。任一字段或有效序错误即停止，回退仅新flag，不退已合入circle/FAST/其它优化。若工具收益不足，转更大共享通路设计，不能删功能或假报能装下。
- Artifacts / Completion：真实三份before/final hashes、实际diff与授权来源登记。静态通过不是仿真/整机通过；最终仍需PNR/STA/bit。实际下载/观察人工，未下载031不登记硬件通过。整体目标及矩形/FINAL/ANN继续未完成。
