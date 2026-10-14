# TRACK4-SCALAR-ROOT-PREFIX-001 v1：小输入跳过开方零前缀

2026-10-11，独立设计-only短卡。用户自主继续及免新长草图/TB授权持续，ROOT读回呈现后限定candidate实施；本轮不写源码/测试/EDA。不缩图像、候选、输入精度或目标范围，不将缩短计算延迟解释为完整识别性能通过。

- Goal：当前PM每个完整点18调用中kind4只有一次，但scalar固定96对bit，每轮四个13字READ/USE及6控制沿=110沿，减法另26。PM该radicand已完整核39位；采用默认关闭参数ROOT_SKIP_ZERO_PREFIX，**只在完整original_a[191:40]==0时从20对开始，否则仍96对**。40位门是数值快路径资格，不拒绝任何192位大输入，不改变target97、RNE/FLOOR或385位资格。
- Baseline：main board/recognition_numeric/scalar_core_words.sv `73F230DFB7B2D2F12A3220C8EE4FC4FF4B8C90E18AD916E3E05D24C084BA31F0`；main board/rtl/board_algorithm_rpc.sv `E692D5D88836034A6825B82D0778524CDC5A6F6531A662E66ACD0FEBBEF3161D`。PM只读SHA `83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21`。
- Scope：拟独立candidate两文件，core新增默认false参数并仅改kind4/7 DISPATCH给原root_remaining赋20或96，RPC实际scalar参数开启。初始化、READ/USE、所有循环体、格式/错误/舍入/资格/取消/borrow规则保持；不叠改SPARSE_INITIALIZE、不改PM/回调/HIST/geometry/原资料/历史run。后续与初始化候选合并须按实际采用后的SHA重新核小差异。

## 接口、等价不变量与组合检查

没有新数据端口、请求schema、握手、状态、FF、RAM、DSP或时钟。参数默认0使DISPATCH仍原96；kind0/1/2/3/5/6全部原样。完整WH/version/kind/target/AS/BS/padding/Bzero等CHECK仍先执行，只有通过原CHECK才进入快路径；kind4/7合法输入无signed标志且B全零。original_a仍完整192位，不取stored_bits/低截断近似判范围。

启动时BR13和BROOT13已逐请求初始化为0（原256初始化及SPARSE方案都保证）。若A高152位零，旧循环前76个pair皆00：ROOT_SHIFT后BR0；ROOT_TRIAL把BT完整写1；比较BR0<BT1不减法；ROOT_BIT保持BROOT0。所以跳过该前缀后的BR/BROOT与旧完全一致。BT可能不同，但下一ROOT_TRIAL覆盖全13字之后才有效读取；比较/carry也由原begin_words重设，不能把旧未使用值当有效状态。

原ROOT_SHIFT按(root_remaining−1)×2取原A的pair，因此20开始完整处理A[39:0]；原96路径处理全部A[191:0]。高位非零保留96对，不截断。ROOT_ROUND的余数>根判断、可能ADD BZERO、COPY BP、RESULT_SIGN、25字组装和完整385位资格保持原样；0/完整平方/近半界/最大输入的返回逐位一致。

原owned请求保持到真实响应消费及scalar quiet；快路径谓词不按req_valid门控，不增加采样快照。RST与matching cancel优先级及HELD保留原协议。计算更早达到HELD是允许的可变延迟，调用者只能用原valid/ready交付，不能依固定96轮延迟换正文/所有者。取消按真实发布时间判断：已公开的VALUE不撤回，随后取消仍履约；不能把旧/新核同绝对周期取消时因发布时间不同造成的VALUE/DROP差异误判为数学结果不等价。

## 周期公式、资源与不足

小输入精确移除76个不发生减法的零前缀轮，每次kind4/7省76×110=8360个core沿，其余RNE/COPY/组装/资格开销不变。PM每个原合法39位radicand必走20路径；完整192位大输入仍96，没有伪缩位。

时间仅此部分：`kind4/7次数 × 8360 / f_core`。90.909MHz、E20,000一次PM全点遍省1.8392s；E2,073,600五等效遍省953.43s。数字不是帧总耗时，也不代表所有种子/峰完成；DDR、18调用的其它运算、HIST和多候选仍可能长期等待。

组合资源只增加完整upper152判零及原7位root_remaining的20/96选择；不做192位priority encoder或新增并行核。实际LUT/路由及计时收益仍需工具测量；最新057 SYNTH PASS但physical61201/60800，超401（LUT44137/FF20098/RAM225/DSP154），不能凭小逻辑估计保证装下。后续MUL动态真实绝对值word-count可减少行列，但不能按typed结果宽度裁切输入，尚未在本卡闭合。

## 验证、追踪与交付门槛

- STATIC场景：参数0；A0/1/2/完整平方/最近整数根边界；A=2^40−1走20与A=2^40走96；A最高位1走96；非法unary高B/sign先FORMAT；取消在DISPATCH/首对/末对/HELD；原body借用与提前HELD背压。仅设计/静态走查，不新增TB或性能脚本。
- 双向追踪：REQ快而精确→完整高152判零/BR+BROOT不变式→kind4/7 DISPATCH原计数器选择；REQ兼容→default0/完整192回退/原385资格→所有旧数值/错误路径。实现后记录before/设计hash/candidatehash和实际diff；无源码/工具通过不声称完成。
- ROOT读回呈现后才指定candidate；静态复核后可临时采用测实机工具，只有容量/路由/最终STA通过才登记新下载版本。与SPARSE合并另核真实SHA；回退参数关闭或原before。硬件下载/观察仍人工。
- 当前状态：设计已保存供读回；未实现、未EDA，完整性能目标和完整A6仍未闭合。
