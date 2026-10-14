# TRACK4-LINE-RUN-REDUCE-001 v1

2026-10-12，短卡 READY_FOR_REVIEW。沿用户自主继续、本地审计及免新增长草图/独立测试授权；ROOT实际读回呈现后仅生成candidates/line_run_reduce_v1/board/rtl/board_line_run_reduce.sv，不改主工程或063冻结输入，不假称新增指定版人工批准。

- Goal / Current / Target / Gap：矩形RW已完成单行CELL/EXT存取，RL全coarse/TLS仍未实现。本增量把RW按0…4095顺序返回的canonical entries归并成全部真实投影run；不是完整coarse协调器或矩形识别。按RECTANGLE v1 E2/E3及RECOGNITION-ALGORITHMS的cell=floor(tQ4/16)+2048、run_gap旧值48Q4和真实coverage定义实现通用流归并。父仍须发RW READ、匹配回复/关闭、消费本run、决定SEG或extension选择及整帧发布。
- Baseline：RECTANGLE卡SHA25242C5722176970259AF3E87FA9069590576E1BE1C792E4845AA0DBB8521EC9；ALGORITHMS卡SHAD8C45B02032DCA210265441118EA3AB7EF88DD2E549E15386082FCC6928057AB；RW源码SHA19406D25638E5C87C3A2CB4851C3B1BF876D02F65D555FF96658C70B04677467，CELL48/EXT80布局及四项/64B不改。

## 接口、局部和数值

同core正沿、同步高有效共同rst，无DDR/NUM/STATS/ANGLE/CDC端口，不持有任何外部物理预约。start&&start_ready锁table_kind1、point_limit21、run_gap16、coverage_min16、minimum_support21；输入后不再读实时配置。POINT限≤2073600、support非零且≤2073600，gap≥15（保证同cell内不需再拆submask）；非法START已接受后known error DONE，不产生run。E0允许全部空CELL，minimum_support不要求≤E。

entry_valid/ready、entry80；输出cell_index12就是父下一RW READ地址，不另接不可靠last。父对相同cell_index只交付一次匹配READ回复，不跳空cell，完整交付4096项；先消费真实RW回应并确认quiet，再读取下一项。CELL字段count21/min4/max4/valid1/pad2/mask16/pad32，EXT字段count21/old_count21/min4/max4/valid1/pad13/mask16。无效空项全80位0；非空canonical检查count≤E、old≤count、mask非零/minmax与mask真实极值一致、popcount≤count、pad零、valid1。CELL的old=0。全四态输入的X/Z不具有成功保证，仿真/硬件域仅已知有效entry。

位置t=16*(cell_index−2048)+sub，为signed18，完整域[-32768,32767]。按cell升序扫；相邻非空cell的新min−旧max严格大于锁gap时结束旧run，等于gap继续。空cell不增加count/occupied，也不丢旧run。全表total21仅在entry_fire累加count，22位扩展核≤E，边界重试不重复计数；run count22扩展求和并核≤E/21位；old_count22同核≤新count；occupied13累加到发布前核可收12位；maxgap18记录跨occupied cells实际差，同cell还核mask连续置位之间的最大差，不能仅用min/max估计。

每run记录tlo/thi signed18、total21/shared21、occupied12/maxgap18，另输出covered17/span17/eligible。coverage精确长度为16*(occupied−1)−first_submin+last_submax，span=thi−tlo：占据每个1px cell的区间并集扣去首尾超出[tlo,thi]的部分，单cell得到max−min。规范非空run须covered≤span，span≤65535。比较covered*65535≥span*coverage_min，不先舍入分数；两乘32位（covered/span先完整核≤65535），右侧16×16允许工具DSP，左侧65535用移位减法。eligible仅表示total≥minimum_support、occupied≥2、span>0且coverage门通过；所有run均发布，父自行沿原算法选择，不静默漏run。

状态：READY/DONE/ERROR接受START→SCAN逐项真实entry_fire→边界出现时暂不接受下一非空entry，转VALIDATE旧run→在VALIDATE检查完整occupied/span/covered后才进入PUBLISH→真实run_valid&&run_ready消费后清旧run，回SCAN，同一上游entry保持直到接受；最后idx4095接受后若有run则VALIDATE并标final，消费后DONE，否则直接DONE。最后一项本身触边界时先交旧run，再接受最后项，再交最后run。VALIDATE提供每run一个固定资格沿，尤其最后entry的非阻塞更新/occupied容量必须在valid之前检查，不能在已PUBLISH时撤回无效run。PUBLISH期间所有run字段/eligible/配置/索引稳定。非法entry在SCAN真实接受后error DONE，已发run属于未提交前缀，父必须把整表/整帧结果作废。复位作废本次逻辑流，由父统一复位相邻ROW/RW；无未知物理归属也不伪造DDRdrained。

## 实施、验证、追踪、预算

- Steps：实际读回呈现→单文件实现→源码/diff静态走查→登记候选。后续RL接入及XML/fullEDA另按实际范围；063仍只编译131既有源。
- Validation场景：全空；单cell多sub；相邻/空cell间隔gap等于及大于；同cell稀疏mask内部gap；最后项空/非空/边界；输出背压同entry重试；count/old/occupied容量；所有pad/min/max格式；coverage首末截断/单cell零span；reset/START配置锁存。仅源码静态审查，不生成TB/功能脚本。
- 追踪：原真实run/coverage需求→cell位置/连续置位gap/首末截断与整数交叉乘→SCAN/PUBLISH；RW canonical布局及准确idx→entry80验证/cell_index→4096次接受与最后flush；不截前缀成功→error DONE→父整表作废契约。
- Budget / Failure / Rollback：一套run寄存器约180位及配置约75位/索引12/全表total21/有限状态，约290FF估计；无RAM、无第二NUM、乘法最多一DSP估计，LUT/时序未测。父必须重新计入资源，不因063面积失败把此候选当已接入。发现字段/边界/coverage错误即停止候选并修订，原HDK/031/063保留。
- Completion：单文件与完整静态读回可交付候选，但RL、TLS、PAIR/RG/RV、FINAL/ANN/整机和实物均仍未完成。人工下载与正式数据库状态不改。
