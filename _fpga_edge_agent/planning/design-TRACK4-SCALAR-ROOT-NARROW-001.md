# TRACK4-SCALAR-ROOT-NARROW-001 v1：小输入开方采用两字循环

2026-10-11，限定设计-only短卡。用户自主继续、免新增长草图/TB及本地审计授权持续；ROOT读回呈现后再指定独立candidate实施。本卡不生成业务源码、不修改main或058冻结输入、不启动EDA/TB，不缩分辨率、几何场景、输入精度或结果资格。

- Goal：当前已采用SPARSE_INITIALIZE和ROOT_SKIP_ZERO_PREFIX，小输入开方降到20对，但每轮SHIFT/TRIAL/COMPARE/BIT仍处理13个16位字。仅对完整original_a[191:40]为零的合法kind4/7，用2字执行这些内部循环，保留13字结果复制、25字组装及全部385位资格检查。
- Current/Baseline：实际读回main `board/recognition_numeric/scalar_core_words.sv` SHA256 `6266734BEDD5CD1439355CC2153AE4B3FB0630079CADF9097433D9A0F89E4037`；main `board/rtl/board_algorithm_rpc.sv` SHA256 `7F4B21CE09F81FBF2236E54000748B32FD522F889AD4997860292B3E5544EE93`。这是058实际冻结的已合并初始化/零前缀基线，不能复制旧057版本覆盖。
- Scope：拟独立candidate两文件。core新增默认false参数ROOT_NARROW_WORDS及组合2/13词选择，仅替换下表七处begin_words的词数实参；RPC仅在实际唯一scalar实例开启该参数。保留所有现有参数、窄输入字/返回字侧带、物理地址、操作类型、初始carry、resume状态与握手。其它scalar种类、PM/CF/HIST/FIT/ANGLE/DDR及历史run不改。
- Gap/Dependencies：独立候选尚未实现，实际LUT/时序未测。main容量由父处理058，本卡不是容量或实时性通过证明；唯一实现前条件是ROOT实际读回/呈现并授权该候选范围。

## 接口、组合检查与准确修改位置

无新数据端口、schema、FF、RAM、DSP或时钟。新参数默认0，内部root循环词数恒13；启用时仅完整A高152位为零才选2，否则13。快路径只在原CHECK已通过的kind4/7调用，保留完整192位输入、WH/version/kind/target/sign/padding/B全192零检查及原错误优先级。root_small谓词不使用低位截断、PM stored_bits或req_valid；original_a仍取原owned请求。

| 现有状态/调用 | 操作与读写银行 | 本卡词数实参 | 保持项 |
|---|---|---|---|
| ROOT_SHIFT | SHIFT_TWO，BR→BR；输入原A pair | 2或13 | 取pair、initial carry、ROOT_TRIAL |
| ROOT_TRIAL | SHIFT_TWO，BROOT→BT；initial carry1 | 2或13 | 形成4·root+1、ROOT_COMPARE |
| ROOT_COMPARE | COMPARE_WORDS，BR与BT | 2或13 | 高到低比较、ROOT_DECIDE |
| ROOT_DECIDE接受分支 | SUB_WORDS，BR−BT→BR | 2或13 | comparison/accepted_bit、ROOT_BIT |
| ROOT_BIT | SHIFT_ONE，BROOT→BROOT | 2或13 | accepted_bit初始carry、ROOT_NEXT |
| ROOT_ROUND | COMPARE_WORDS，BR与BROOT | 2或13 | rem>root的原RNE判定 |
| ROOT_ROUND_DECIDE上舍入分支 | ADD_WORDS，BROOT+BZERO+1→BROOT | 2或13 | ROOT_RESULT、完整进位界 |

ROOT_RESULT的COPY_WORDS **固定13**，RESULT_SIGN及ASSEMBLE/QUALIFY保持原路径。DISPATCH原20/96对选择不改；ROOT_NARROW_WORDS与ROOT_SKIP_ZERO_PREFIX独立相容：若后者关闭，完整高零输入的前76个00 pair仍可用2字执行，数值仍等价；本基线二者均启用时周期公式按20轮计算。大输入仍96对×13词。

BORROW_HEADER/BORROW_PAYLOAD调用者从真实接受到响应消费且quiet保持原622正文和新旧侧带；关闭借用参数时沿用原内部快照。组合root_small在该所有权期间稳定，不新增或省掉快照。valid/ready、cancel匹配/优先级、drain及HELD背压不变；计算更早结束属于可变延迟，已公开VALUE不会因随后取消撤回。

## 数值不变量、存储与局部顺序

先完成原CHECK和本次初始化，再进入原ABS/DISPATCH；每个成功kind4/7请求都把BR[0..12]与BROOT[0..12]写成新零。SPARSE路径明确32..44、80..92，参数关闭的完整256初始化也覆盖这些地址。高11词不依赖复位或前次值；前次取消即使留脏，下一成功请求仍先全部写零。低2词循环不触碰高11词，因此ROOT_RESULT复制13词时高位严格为零。

令j为已处理pair数、R为当前floor根、M为余数。不变量0≤R≤2^j−1、0≤M≤2R。A<2^40，最多20个有效pair：最后一步前j≤19，BR的SHIFT_TWO最大4M+3≤2^22−5，BT=4R+1≤2^21−3；减法后余数≤2·新根≤2^21−2，BROOT最终≤2^20−1。32位两词足够容纳所有中间值，不发生被丢弃的第33位carry/borrow。

ROOT_ROUND沿用整数根的严格rem>R判定；(R+1/2)^2=R²+R+1/4，整数A没有正好半点，所以原RNE上舍入条件不变。上舍入根最多2^20，需要21位，仍装入两词，ADD的末carry为0。BZERO低2词本次为新零；高11词无须参与该加法。完整385结果的OVERFLOW/target扩展检查仍逐25词执行。

BT高11词在两词快路径可能保持旧内容，但只被本卡两词COMPARE读取低2词，ROOT_RESULT不读BT；不能把它们当本次有效输出。之后的大输入走13词ROOT_TRIAL，先完整覆盖BT13再比较，因此没有跨请求污染。begin_words仍重设comparison/carry；高零词的旧比较跳过等价于原读零，不依据前次comparison决定结果。

## 周期、资源与未闭合范围

现20轮每轮4×(13×2)+6=110沿，接受减法另26；两词后4×(2×2)+6=22沿，接受减法另4。设q为floor根的置1数（0..20），u为上舍入事件0/1：kind4每次精确省 **1782+22q+22u** 沿（含RNE比较省22）；kind7每次省 **1760+22q**。ROOT_RESULT/COPY、初始化、组装、资格、PM加载/保存和NUM关闭均未省略。

仅kind4这部分，11ns core周期、E=2,073,600的一次完整PM遍可再省40.65–51.19秒；5或9次等效root遍分别约203–256或366–461秒。这些是被移除沿的换算，不能当整个帧耗时或满足性能指标。多seed、多raw/smooth peak仍按实际PM次数增长。

结构不增加存储/宏资源；可共享已存在的完整高152判零，仅在七处选择2/13词数，组合控制LUT/路由成本仍须工具测量。若此计数选择影响时序/面积或静态界不成立，停止并回退新参数，不加入并行核或缩减任务。

## 验证、追踪、恢复与门槛

- STATIC场景：default0全部13；小A0/1/2/完全平方/上舍入边界；A=2^40−1两词且rounded root=2^20；A=2^40及最高位1回退13；先大输入或取消后再小输入、高11词每次新零；小输入后大输入BT完整覆写；非法unary先原错误；ROOT任意状态cancel、HELD反压/body保持。仅静态场景，不新增TB/功能脚本。
- 双向追踪：REQ保持全精度的更快执行→完整高152谓词/根余数界→七处begin_words词数；REQ完整结果及兼容→default0/13词COPY/25词组装资格/原CHECK→ROOT_RESULT和QUALIFY均不改；REQ隔离前次值→初始化BR/BROOT13零、BT读取范围与大输入覆盖→STATIC跨请求场景。
- 恢复：新参数关闭即七处回原13，或按独立candidate before两文件恢复；不得倒退既有SPARSE/ROOT_PREFIX/输入字/返回字改动。候选须记录本卡hash、真实058基线hash、before和最终hash、七处实际diff。父静态审查后可临时合并作一次真实工具测量，容量/路由/最终STA通过才登记新下载版本。
- Human gates：继承用户自主实施/本地审计；本轮仅短卡，尚未获ROOT限定candidate实施指令，不生成代码。硬件下载与观察仍人工，数据库及硬件状态不变。
- 当前状态：READY_FOR_REVIEW供ROOT读回呈现；尚未实现、未EDA/TB、完整A6及最终性能未闭合。
