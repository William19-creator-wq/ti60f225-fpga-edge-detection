# TRACK4-GEOMETRY-FAST-PM-001 v1：一个DSP复用的精确逐点半径与法线

2026-10-11，design-only短卡。继承用户自主继续、免新长草图/TB及本地审计；ROOT实际读回呈现后才授权独立候选。本轮不编码、不跑EDA/TB、不改main058，不降低1920×1080、POINT数量、seed/peak范围或原几何场景。

- Goal：PM目前每点6或18次通用192位NUM调用。增加默认关闭FAST_POINT_MATH，启用时在PM内部用**一个EFX_DSP48的无符号16×16乘法、一个工作RAM及串行控制**完成同一整数式；原NUM继续服务SEED/FIT/CR，不新增第二个NUM核。
- Baseline：PM `candidates/geometry_radius_only_v1/board/rtl/board_geometry_point_math.sv` SHA256 `CC4BF36A1E51325948F12640379346865C48EC5F8778D3C4AAD7209504E64C05`；CF `candidates/circle_refine_radius_only_v1/board/rtl/board_circle_refine.sv` SHA256 `0AC562695ECA432200EC74825D71C093F0D4753AA43A7ACFFFF765D8EFEF7EA4`。这是radius-only实际候选；不叠未实施的operand-load卡，不回退至旧PM/CF。
- Scope：拟独立两文件候选。PM追加FAST_POINT_MATH默认0并用generate保留完整旧分支、另置fast局部分支；CF追加默认0同名参数传到唯一PM实例。EVAL/NUM端口和旧参数不变；此卡不负责主RPC租用接入、圆五遍/FIT/CR修改或主板启用。
- Current gaps：fast分支未实现；实际LUT/FF/布线/STA、CF整体资源及运行时间未测。058基线DSP154/160、RAM225/256只表示此模块至少一个DSP有名义预算，不能保证加入完整几何后端后装下或实时。

## 外部接口、默认兼容与所有权前置

EVAL输入scope96/seed8/pass3/ordinal21/POINT64/center signed18 Q4/tolerance16，返回radius18、normal_ok/error/drained及相同身份，保持原valid/ready、borrow、quiet/fault语义。参数0走旧6/18步共享NUM、完整622/585及25词结果资格，连UNKNOWN/ISOLATED和序号耗尽行为原样；参数1只改变本地计算实现和可变延迟。

参数1时PM不提出NUM请求、不消费NUM回复，num_req_valid/num_rsp_ready恒0、num_req_body/word_index输出确定0。必须仍先取得CF的PM owner lease：eval_req_ready只在本地IDLE且num_quiet时成立，CF继续在PM_REQUEST前提出numeric_owner_request=1，不能按pm_num_valid=0认为无需租用或已经结束。NUM/STATS/FIT外层及borrowed正文必须quiet，父授予PM物理owner后才允许EVAL；期间不得把共享NUM转给CR/FIT或换POINT/中心。

CF现有PM_WAIT消费真实EVAL回复，PM_CLOSE等待pm_quiet&&num_quiet后再改phase/pm_step、POINT、numeric_owner；该关闭顺序保持。父geometry lease管理器需明确：grant1可服务不发NUM的PM；owner释放依PM quiet而非NUM quiet单独成立；故障/UNKNOWN沿用CF隔离路径；旧NUM返回word索引不能被快PM冒用。主RPC尚未接入，本卡不宣称这一前置已整机满足。

原EVAL全部正文由父保持到回复消费及PM quiet；UNKNOWN保持到共同复位。正常known错误只在本地作业已停止且num_quiet后发布drained=1；fast执行期间若共享NUM出现不属于本地作业的active/回复（违反已获quiet lease），不得消费或替它宣布释放，发布error/drained=0并在回复消费后隔离。默认分支的原异ID/matrix故障处理不改。PM没有本地取消端口，不新增取消接口；原复位冲刷和fault保持规则保留。

原closed_sequence64/exhausted规则保留为“已关闭逻辑算术步骤”：各本地步骤资格提交/已知失败关闭时推进一次，对应旧pc0..5或0..17；非法POINT在CHECK失败不推进。MAX同旧置fault/exhausted，最后步骤允许当前回复完成、后续请求被禁止，中途耗尽走已知失败。不会凭本地计算去重或复位序号延长原许可。

## 完整数值、符号与资格证明

POINT合法性沿用全部原检查：reserved位、x/y在WIDTH/HEIGHT内、gx/gy signed11且绝对值≤1020、|gx|+|gy|≤1530、梯度非零、ordinal<WIDTH×HEIGHT；非法输入在任何算术前拒绝。中心接受整个signed18范围，不限制场景；tolerance接受整个u16范围。

| 逻辑步骤 | 精确表示/上界 | 后续用途 |
|---|---|---|
| dx=x·16−cx，dy=y·16−cy | signed19；扩展后减，不先截断 | 平方和cross |
| dx²、dy² | unsigned38 | D2 |
| D2=dx²+dy² | unsigned39；加法前扩39 | 根及法线右式 |
| gy·dx、gx·dy | signed30；先绝对值乘，再准确二补码恢复 | cross差 |
| cross=gx·dy−gy·dx | signed30；差运算先扩31后核30 | cross² |
| cross² | unsigned60 | 左式 |
| left=cross²·4294836225 | unsigned92，常数准确为65535² | 最终比较 |
| gx²、gy²、G2=gx²+gy² | unsigned22、22、23 | 右式 |
| tolerance² | unsigned32 | 右式 |
| tolerance²·G2 | unsigned55 | 右式 |
| right=tolerance²·G2·D2 | unsigned94 | 最终比较 |

WIDTH≤1920、HEIGHT≤1080时，|dx|≤161776、|dy|≤148336；因此D2≤161776²+148336²<2^36。cross的绝对值≤(|gx|+|gy|)·max(|dx|,|dy|)≤1530·161776<2^28，明确装入signed30；不能仅因两项各signed30就把减法截成30。所有中间值都按表完整域保存，乘法先保足m+n词并检查域外高位，不把低18/64位当全部结果。

工作结果存128位八词槽，生产有效性只在域资格完全通过后建立。每次EVAL清valid，不清整个RAM；乘法工作银行八词每次清零、每个新结果八词完整提交，先前请求/取消的脏高词不进入有效结果。正负结果按二补码完整保存。符号乘法对负源先按固定合法词数逐词取反加1；A从低到高各行转换一次，B在每行重设转换carry并从低到高，零与最小允许负值不误判。转换词同时累积完整有效A/B非零标志，最终负积扩展必须是sign异或且两者非零；不能把负数乘零的结果扩展成全1。mul_sum=P32+旧积16+carry16≤2^32−1，原33位超界检查保留；每行carry写i+n，较早行未写此地址，高词不被覆盖丢失。

本地结果的资格与原stored_bits逐位规则相同：unsigned域外全0；signed域外必须是结果符号的重复，符号边界/minimum-negative及负零都按最终完整二补码判。128位槽以上到385位是已经证明的零/符号扩展，不能省掉低128内域外检查。可把每个已完整域结果视为同值的virtual385，证明与原NUM VALUE一致；**fast分支没有伪造NUM回复，也不声称实际跑了旧25词NUM扫描**。参数0原25词扫描完全保留；共享scalar/FIT/CR的192/385格式、资格与精度均不改。启用本地路径不是允许给通用NUM裁切192位输入。

## 单DSP、单RAM的局部次序

固定微次序仍对应旧pc0..17。CHK→dx/dy→两平方→D2→ROOT/RNE→（radius0或radius-only则关闭）→两梯度乘积→cross→square/left→两梯度平方/G2→tolerance²/temp/right→完整94位比较→关闭→EVAL held。每一步完整域检查后才置目的slot有效并关闭逻辑序号；失败不发布部分数值为成功。

一个EFX_DSP48用NORMAL/unsigned模式做16×16→32，A19/B18高补零。初版采用当前已证实的全组合tie-off规则：A/B/P/W/O/C/OP寄存0、SHIFTER0、P右对齐、W_SEL=P/N_SEL=CONST0，CLK/CE/RST/SHIFT_ENA全0；外部16/32位临时寄存器按状态捕获，不新增第二乘法器。不要把全组合CLK接clk重现VDB-9038。实际读回本地sim_models/verilog/efx_dsp48.v：NORMAL是19×18→37，ALIGN_RIGHT零扩展到48，W_SEL=P直接取乘积；输入高补零后精确低32，其余位零。现gray提供全组合tie-off、Hough提供NORMAL模式参照，具体新组合尚未EDA。

一个EFX_RAM10，20位端口保存低16数据高4补0，512词容量；16×8结果词加独立8词乘法工作区共136词/2176有效bit。本地efx_ram10.v明确20位为512词、简单一读一写端口；同clk、OUTPUT_REG0、READ_FIRST，顺序读取A/B和旧积，读值捕获后再写，无依赖同沿碰撞响应。W/R地址保持9位，真实写与读使能按状态；所有写入同时受!rst、本地active与NUM lease仍quiet/无异响应约束，错误隔离沿停止写入。复位只冲刷valid/FSM不清数据，不能推导成两个复制RAM。

固定m/n由表中生产类型和当前操作角色决定，非零高词数最多A4/B3；带符号源先取其完整有效最高词的符号，不用未资格的低位猜符号。每个partial次序为B_READ→B_CAPTURE（绝对值词）→P_READ→P_CAPTURE（同时DSP乘积捕获）→ACCUM_WRITE；A每行READ/CAPTURE，末行词carry单独写。每个乘法先清八词P，最后八词READ/CAPTURE提交并核域，避免可变大位宽乘法、宽FF operand或额外RAM。

ROOT从完整39位D2做20对restoring整数根（最高bit39补0）。每对从RAM同步读对应16位词并取准确pair；用root20/rem22，candidate_rem=(rem<<2)|pair、trial=(root<<2)|1，比较后可减，root追加accepted bit。数值不变量rem≤2·root，20对时candidate_rem<2^22，trial<2^21，全部先扩足22位，无第23位被截。RNE仅rem>root才+1；整数输入不可能恰好半根，和原ROUND规则相同。最后对rounded root做完整18位零扩展资格后才给radius。radius0原提前结束/normal0保留。

normal_ok严格是left≤right；双方扩到同一94位、等号通过，不用近似除法/浮点、角度阈值或低64比较。比较按高到低六词进行，92位左式高2位明确零，非法域外结果报告已知error，不饱和、不回绕。

## 周期、面积估计及限制

完整PM有11次乘法：静态16位partial数量依次4/4/2/2/4/8/1/1/1/4/12，共43；行数合计21。上述调度每MUL约26+3m+5mn沿（清P8、提交/资格16、起止2、行读取/末carry3、partial5），11项约564沿，负源预取符号最多约16沿；dx/dy、加减、ROOT约20×3+舍入/提交、最终六词比较及关闭另约200沿。**设计预算完整PM800–1000沿、radius-only250–300沿**，含本地资格及序号关闭，实际FSM完成后再精算；不是工具/实机测值。

11ns core下，E=2,073,600的一次完整全点遍预算约18.2–22.8秒，radius-only约5.7–6.8秒。HIST+一个峰最多6个完整/4个radius等效遍，纯PM预算约132–164秒；多峰按真实条件调用增长，上界可写E·[1000·H+6200·P]·11ns，其中H为seed HIST数、P为RAW/SMOOTH峰总数（条件分区使实际次数更小）。**全1080p密集边缘/多峰仍可能分钟至小时，尚未证明实时**；DDR/STATS/FIT/CR/ANGLE及其它处理未计入，不把该范围藏成低分辨率测试。

相对旧PM：1RAM保持，新增1DSP；prune旧两份128operand和NUM packing/25词扫描选择，但新增root42位、partial/carry/read16/32临时及控制，估计约200–350FF级，实际可能增减。combinational22/32位ALU、静态源/地址选择及检查可能需数百至约1500LUT；这里只是实施前预算，不保证省净LUT或装下。单PM接058仅名义DSP155、RAM226，其它新模块另预算；11ns ROOT比较减法和DSP捕获路径需实际STA，不先提高时钟。

## 静态场景、追踪与实施门槛

- STATIC：default0旧NUM逐差异；FAST合法POINT/中心完整边界；gx/gy±1020及L1=1530；dx/dy正负零、signed30边界证明；多词carry、最小负值和负零；完全平方/根上舍入/最大合法D2；tolerance0/65535；left=right/临界前后；radius-only与零半径；八词全部域资格及跨EVAL脏RAM；借用持有/背压、序号MAX、unexpected共享NUM quarantine、reset。无新增TB/EDA。
- 追踪：原PM1/PM2精确式→完整内部位界/单DSP学校乘/ROOT-RNE/94位比较；原EVAL身份/释放→同端口borrow/CF lease/quiet/UNKNOWN；旧兼容→FAST_POINT_MATH默认0保留原共享NUM。每个新增FSM/存储步骤只服务上述要求。
- 实施顺序：ROOT先核读本卡数值及lease边界→授权独立两文件候选，保留准确before/卡hash/实际diff→静态审查原分支、全部域与最坏partial/字序→父再决定整合一次真实资源/STA测量。不能仅一DSP余量即主板启用；新的下载版本仍须真实编译/最终STA通过。
- 回退：FAST_POINT_MATH关闭或本候选before，保留既有radius-only和scalar sparse/root改动。失败不偷偷转近似算法、降低候选或精度。硬件下载/观察仍人工，正式DB不改。
- 当前状态：READY_FOR_REVIEW，业务源码未生成、未EDA/TB/实机。完整A6、资源和最终吞吐仍待闭合。
