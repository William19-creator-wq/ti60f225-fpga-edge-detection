# TRACK4-SCALAR-SPARSE-INIT-001 v1：按实际运算访问初始化

2026-10-11。PLAN_TEMPLATE小修复短卡，设计-only。用户自主继续及免新增长草图/TB授权持续；ROOT读回呈现后才指定独立candidate实施，不新增批准问题。本卡不降低1080p、点数、种子、峰、五遍或目标范围，不生成业务源码/测试/EDA。

- Goal：同一个192/385位scalar仅初始化本次运算后续会有效读取的地址，消除256地址全清的固定开销。新增默认关闭SPARSE_INITIALIZE参数，有效条件SPARSE_INITIALIZE&&AREA_RAM_WORDS。默认0或AREA=0严格原256沿路径，开启后仅允许初始化延迟变化，原NUM请求/响应、数值、错误/取消/quiet及所有完整格式/结果资格不变。
- Baseline：main board/recognition_numeric/scalar_core_words.sv SHA256 `73F230DFB7B2D2F12A3220C8EE4FC4FF4B8C90E18AD916E3E05D24C084BA31F0`；main board/rtl/board_algorithm_rpc.sv SHA256 `E692D5D88836034A6825B82D0778524CDC5A6F6531A662E66ACD0FEBBEF3161D`。拟独立candidate仅这两文件：core跳过无效初始化地址，RPC实际scalar参数开启；前两项输入/返回字共享保持。原资料、056/057输入、PM/geometry/callback/HIST只读。
- Evidence：PM candidate geometry_point_math_v1/board/rtl/board_geometry_point_math.sv SHA256 `83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21`。非零径完整路径pc0…17实际11次MUL、5次ADD/SUB、1次SQRT_RNE、1次COMPARE；每次仍请求全192位target（SQRT97/COMPARE2），完整385返回核查。半径零可在pc5已真实关闭后提前结束，不能据此假称通常18调用减少。

## IF01 精确地址表与操作

沿原memory_left/right同沿双写、原write_data和initialize_index物理地址；仅CHECK初始地址、INITIALIZE下一物理地址与结束沿改变，复用原8位initialize_index，不增加状态/游标FF、存储或DSP。按照下表升序逐段写，段尾跳至下一段起点，最后一地址写入沿之后进入原ABS_A。每次新请求都按自身kind重新准备所有必要地址，不依旧请求留下的零。

| kind | 初始化物理地址（闭区间） | 沿数 | 建立的不变量 |
|---|---|---:|---|
| 0 MUL | 0…11，16…27，96…120 | 49 | A12/B12真实字，BP25全零后累加；零乘行保留旧产品字是本次新零/累加，非旧请求数据 |
| 1/2 ADD/SUB | 0…11，16…27 | 24 | A/B12真实字；ADD_WORD0…12及ADD_EXTEND13…24在组装前覆盖完整BP25 |
| 5 COMPARE | 0…11，16…27，97…120 | 48 | A/B12真实字；COMPARE_SAVE始终写BP0，所以只需BP1…24先零 |
| 6 DIV_FLOOR | 0…11，16…28，32…44，48…60，109…120 | 63 | A12、B12且BB+12零、BR13/BQ13零；DIV_RESULT写BP0…12，BP13…24先零 |
| 3 DIV_RNE | 同kind6，另224…236 | 76 | 同上，RNE ADD_WORDS可能读取BZERO13，必须每请求零写 |
| 7 SQRT_FLOOR | 32…44，80…92，109…120 | 38 | BR13/BROOT13零；ROOT_RESULT写BP0…12，其高12先零；A从原请求直接取pair |
| 4 SQRT_RNE | 同kind7，另224…236 | 51 | 同上，ROOT_ROUND可能ADD_WORDS，BZERO13必须零 |

0…11和16…27仍用原A/B初始化字（可用已接输入侧带），其余表内地址仍写0。kind3/6的地址28必须零，完整13字除数比较不能读旧第13字。未知kind由原CHECK拒绝，不进入快速初始化。默认分支保持原0…255，原generic非AREA逻辑不改。

## IF02 地址依赖和等价证明

- 原BA0/BB16/BR32/BQ48/BT64/BROOT80/BP96/BZERO224；常量BPRODUCT160没有活动读写，不因名字分配零写。
- NEG_WORDS将alu_right强制0；SHIFT_ONE/TWO、COPY_WORDS的数据不使用右侧BZERO读值。只有RNE的ADD_WORDS真正需要BZERO13，不能将RNE零写也删去。COPY过程未使用的carry/读口可能保存不同旧值，但下一有效调用会重设carry或覆盖数据，不能进入任何结果/错误判断。
- DIV的BT13由DIV_ROUND完整SHIFT写后才比较；ROOT的BT13每轮由ROOT_TRIAL完整SHIFT写后才比较，无需先清BT。所有同步RAM有效数据均在原WORD_READ等读等待之后使用；取消/错误时未覆盖的数据不能发布VALUE。
- ADD/SUB在BP最后一写沿后进入ASSEMBLE；COMPARE无论符号分支如何都先COMPARE_SAVE；DIV/ROOT的低BP13先COPY，完整25字负号转换/组装/资格检查仍保留。MUL BP25必须全清，不能只清低typed宽度。
- 完整WH/version/kind/target/AS/BS/padding16/B192zero及错误优先级全部原样；A/B192包括符号高字不省略。完整385资格、溢出、高零/符号、舍入和COMPARE合法值保持；不新增窄数值schema。
- 原请求正文仍保持到真实响应消费+quiet；输入侧带不按req_valid门控。复位/取消禁写、HELD不撤回、DRAIN/错误矩阵及borrowed结果生命周期不改。省略的地址只能是本kind从未有效读取或先完整覆盖的地址，不能省略业务输出。

## 周期公式、资源与尚未闭合

PM完整18调用初始化：原18×256=4608沿；新11×49+5×24+51+48=758沿，每点省3850沿（83.55%）。初始化时间公式为`PM评估次数 × 初始化沿数 / f_core`，不能作为整机完成时间。

以f_core=90.909MHz计算，E=2,073,600且等效5次PM全点遍时初始化525.53s→86.45s，9次时945.96s→155.61s；E=20,000一次PM全点遍为1.014s→0.167s。五遍算法可能因重放成员评估次数不同产生5…9次PM等效遍，数字仅覆盖该初始化部分，不能隐去其它循环、HIST、多种子/多峰/DDR或显示等待。

实际慢项保留：SQRT当前96轮，每轮四次13-word READ/USE及6控制沿=110沿，发生减法再加26；MUL12行的纯乘积循环为`24+37z`沿（z为绝对值A的非零16位行数），非零行仍乘12个B字。每次scalar另外完整组装25字/50沿、AREA资格25字/50沿；PM再25字检查和8字保存。只优化初始化不能证明满足识别性能。

后续最小方向（本卡不实施）：ROOT前导零pair跳过，保持大输入96轮；或同scalar按真实绝对值word-count减少MUL行列，完整BP清零及高385资格仍保留。后者必须处理负数绝对值计数、末carry新地址与全部385扩展，不可直接用target/stored_bits裁切输入。新窄PM并行核需替18操作及所有边界且新增调度，DSP当前154/160附近、physical已超397，不能无预算随意另加或偷占尚在使用的DSP。

本次估计仅新增kind/地址跳转组合逻辑，复用原游标，无新增宏/存储；LUT/布线开销必须工具实测。任意精度大输入仍支持，最坏循环未减少；用户拒绝的缩图像/1FPS路线不采用，完整性能目标仍未闭合。

## 验证、追踪和回退

- 定向STATIC：每kind fresh/上次任意旧RAM、ADD末扩展、MUL全零/负数/最大输入、COMPARE符号捷径、DIV地址28/近半RNE、ROOT BT覆盖/RNE BZERO、取消在每段跳转或末写、默认0与AREA0、之后切不同kind。仅场景和地址依赖检查，不新增TB/执行脚本；实际时序/资源/响应逐位证明仍需后续有效工具证据。
- 追踪：REQ等价→上表每个有效读前新写/原完整格式与385资格；REQ速度→CHECK/INITIALIZE原游标跳段→758沿公式；REQ兼容→默认false/AREA guard→原完整256地址。反向每个被跳过地址均能对应先覆盖或不使用的证明。
- ROOT实际读回呈现后才限定独立candidate两文件实现，保留before/hash/change-record；主工程和历史run不改。静态复核后可临时采用以测真实资源/时序，但无工具通过不登记硬件版本。回退默认关闭或恢复两份before。
- 当前阶段：设计已保存供实际读回；未源码、未EDA、未硬件，完整A6与最终性能不能据此判完成。
