# TRACK4-GEOMETRY-OPERAND-LOAD-001 v1：PM按已资格的静态位界加载操作数

2026-10-11，限定设计-only短卡，按PLAN_TEMPLATE的小任务字段合并。继承用户自主继续、免新长草图/TB及本地审计，ROOT实际读回呈现后再授权独立候选；本轮不生成源码/测试、不跑EDA，不修改main058、原资料、其它候选或硬件状态。

- Goal/Gap：PM每个RAM操作数固定8个16位字、每字READ/CAPTURE两沿；其生产结果已完整385位资格并限定19..94位，却重复读取高位扩展。按原微程序静态类型只读2/3/4/6词，最后补齐128位零/符号扩展；完整192位NUM请求和全部结果资格保留。
- Baseline：PM `candidates/geometry_radius_only_v1/board/rtl/board_geometry_point_math.sv` SHA256 `CC4BF36A1E51325948F12640379346865C48EC5F8778D3C4AAD7209504E64C05`；CF `candidates/circle_refine_radius_only_v1/board/rtl/board_circle_refine.sv` SHA256 `0AC562695ECA432200EC74825D71C093F0D4753AA43A7ACFFFF765D8EFEF7EA4`。不得用旧PM8317或旧CF9412覆盖radius-only分支；两者目前均独立候选，不冒称已整机闭合。
- Scope：拟独立两文件候选。PM追加BOUNDED_OPERAND_LOAD默认0、组合静态last-word/符号属性、最终CAPTURE固定拼接；只改A_CAPTURE/B_CAPTURE的RAM加载结束条件及该沿的128位赋值。CF追加同名默认0参数并仅传递给唯一point_math实例，原ENABLE_RADIUS_ONLY保持。板端未来启用由父整合处理，本卡不新增main实例或NUM核。
- Resource/Dependencies：复用原word[2:0]和operand_a/b两份128寄存器，不新增FF/RAM/DSP/状态/端口。组合静态选择和最终拼接可能增加LUT，实际收益须下一真实工具测量；不把少沿数视为面积通过。

## 静态来源、接口和组合前提

原PLAN必须先核source_a/b<16时register_valid为1；原REG_WRITE仍完整写8词，只在word7置对应valid。该valid只有全部25词NUM_SCAN、metadata/owned及stored_bits扩展资格通过后才建立。每次新EVAL原register_valid清零，不借前一EVAL或部分写入。BOUNDED_OPERAND_LOAD不移动任何生产资格、valid建立或消费/quiet事件。

| RAM source / 实际消费者 | 生产stored_bits及signed | 读取词数 / last-word | 高位补法 |
|---|---|---|---|
| slot0/1，pc2/3/6/7 | pc0/1，signed19 | 2 / 1 | 符号 |
| slot2/3，pc4 | pc2/3，unsigned38 | 3 / 2 | 零 |
| slot4，pc5/16 | pc4，unsigned39 | 3 / 2 | 零 |
| slot6/7，pc8 | pc6/7，signed30 | 2 / 1 | 符号 |
| slot8，pc9 | pc8，signed30 | 2 / 1 | 符号 |
| slot9，pc10 | pc9，unsigned60 | 4 / 3 | 零 |
| slot10，pc17 | pc10，unsigned92 | 6 / 5 | 零 |
| slot11/12，pc13 | pc11/12，unsigned22 | 2 / 1 | 零 |
| slot13，pc15 | pc13，unsigned23 | 2 / 1 | 零 |
| slot14，pc15 | pc14，unsigned32 | 2 / 1 | 零 |
| slot15，pc16 | pc15，unsigned55 | 4 / 3 | 零 |
| slot15，pc17 | pc16，unsigned94 | 6 / 5 | 零 |

属性只由原pc/operand_source静态微程序选择，不新增stored-type快照；slot15必须明确区分pc16前的55位版本与pc17前的94位版本，不能统一取4词。slot5半径和pc17重写slot6比较结果无后续RAM消费者，保持default8的兼容处理，不据无用槽假设删除存储。source>=16原常量直接赋整个128位，不缩短或改写。

新参数0时last-word=7，RAM A/B两路仍各8次READ/CAPTURE，最终赋值保持原移位。参数1仅表中实际合法消费者走短路径，其余RAM source默认8；PLAN非法/未写slot检查保持原失败。源槽扩展界来源是已经完成的25词资格，而非只看低128位或假设高位不存在。

符号扩展取最后有效work_q的bit15：signed19/30生产资格保证该词余下高位与完整结果符号一致；unsigned源补零。原num_req_body仍把整个128位操作数按原a_signed/b_signed扩展到192位，再带原target/sign/header/padding形成622位请求；scalar完整格式/192位操作数/385位结果资格不变。PM本身的NUM_SCAN25、REG_WRITE8、response error矩阵/UNKNOWN隔离、num_rsp_word侧带、半径及normal输出均不变。

EVAL全部身份、POINT、中心、tolerance和eval_radius_only保持原借用期限：接受到PM回复消费及quiet，UNKNOWN保持到共同复位。NUM正文仍从NUM_REQUEST接受保持到消费和child quiet，不能按req_valid门控新属性或提前换owner。CF的phase/pm_step原本在PM quiet后变更，传参数不改变此生命周期。

## 局部执行与字序不变量

每个A/B RAM读取仍由现有word从0递增，READ/CAPTURE保持原同步RAM两沿；非最后CAPTURE仍执行原128位移位。最后CAPTURE按固定last-word拼接新work_q及寄存器中刚加载的高部，直接形成完整128位低字在前的操作数：

| 最后word | 新高位扩展数 | 新work_q之后取旧operand的范围 | 完整宽度 |
|---|---|---|---|
| 1 | 96 | 127:112（word0） | 96+16+16=128 |
| 2 | 80 | 127:96（word1..0） | 80+16+32=128 |
| 3 | 64 | 127:80（word2..0） | 64+16+48=128 |
| 5 | 32 | 127:48（word4..0） | 32+16+80=128 |
| 7/default | 不新增扩展 | 127:16（word6..0） | 原16+112=128 |

不能只把循环上限缩短后沿用原8次移位结果：那会让有效低词留在128位顶部且混入旧数据。本卡要求最后沿用上述固定拼接，全部128位一次覆盖；此前旧operand的其它位不进入结果。字序严格保留：最后词位于已加载有效范围最高16位，word0在低16位。不做128位可变移位/掩码，不增宽快照。

完成A的同一CAPTURE沿进入原B_READ，完成B的同一沿进入原NUM_REQUEST；新请求只在拼接更新后出现。停顿、异ID、取消/复位优先级、closed_sequence递增/耗尽、NUM_CONSUME/CLOSE以及RESULT背压均保持原行为。可变延迟变短，调用者仍依valid/ready，不依8词固定等待。

## 周期与未闭合范围

每个RAM操作数精确省2·(8−读取词数)沿。按pc0..17依次为 `0,0,24,24,20,10,12,12,24,24,8,0,0,24,0,24,18,8`，完整18步PM省**232沿**；radius-only前6步省**78沿**。数字只适用于正常完成相应步骤；零半径提前结束、失败及背压按实际步数计算。

E=2,073,600、11ns core时，一次完整全点PM遍省约5.29秒，一次radius-only遍省约1.78秒。HIST+一个峰最大6个完整和4个radius等效遍仅本项省约38.87秒；真实各峰partition和提前拒绝会改变等效次数。该数不包含scalar运算提速，不能当整帧耗时或实时证明；全POINT、多seed、多RAW/SMOOTH峰范围保持。

## 静态场景、追踪、回退与门槛

- STATIC：default0逐8词旧行为；各表项低16词序；signed19/30正负边界、unsigned最高允许位；slot15先55后94；常量源及未写slot失败；新EVAL清valid、前次失败/UNKNOWN；最后B_CAPTURE到NUM_REQUEST正文稳定；全25资格/8词提交不变；radius-only6步与完整18步的原结束分支、eval借用到quiet。只静态审查，不新增TB/功能脚本。
- 追踪：REQ完整数值且快→已资格静态stored_bits→last-word表/最终拼接；REQ旧兼容→default0/常量及default8→旧READ/CAPTURE与错误路径；REQ完整192/385资格→num_req_body/NUM_SCAN/REG_WRITE均不改→原数值接口。
- 产物：ROOT读回呈现后才指定候选；候选保留本两份准确baseline before、卡hash、candidatehash和真实diff。静态审查后父可合并一次真实工具测量；只有容量/路由/STA及人工观察证据存在才登记相应交付状态。
- Rollback：BOUNDED_OPERAND_LOAD关闭或候选before，保留既有radius-only和其它scalar优化；不退回旧基线。无当前设计阻塞，面积/最终性能属待测缺口。
- 当前状态：READY_FOR_REVIEW，未实现、未EDA/TB；原完整A6及实机性能仍未闭合，正式数据库和硬件状态不改。
