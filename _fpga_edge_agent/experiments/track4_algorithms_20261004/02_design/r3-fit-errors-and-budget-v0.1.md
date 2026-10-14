# 拟合核：首错、状态推进与资源/形成时间预算 v0.1

2026-10-07；关联 FIT 主卡 v0.4。这是代码前设计核查，不是实现、可执行测试或已测性能。所有测试 NOT_RUN。阅读顺序：主卡 B/C/D → 子运算 v0.1 快照及 v0.2 修订 → 本页。

## 1. 依据与确定程度

R3 总稿 v0.2 SHA 6D071B0AADD685E1185A7BA41D58EC33441055D59C1BE7F399CE8C0B011F8C5D 的 D1/D2、E1/E4/E5/E6 是布局、首错与数学分类来源；NUMERIC SHA 17C4A290414970260BBADC7B5286F6C6F5608E3B03E0FF38E08E3E5E1491F39A 的 E4/E5 提供完整值、PSD、坏 normal 与几何域依据。现有 scalar_core.sv 原字节 SHA DAA31292536F4860C23DE5CFAF73AC444CD18B2AB5E9D2ED9C9B8092217EA0F0 已读回，仍只读复用。

原文明确：PSD/坏 normal 为 INTERNAL 帧失败；退化、条件不佳及几何域外为局部拒绝；计数证明被破坏是帧失败。原文没有逐条指定低支持计数的 reason，本版明确提议 n 低于本操作最低支持返回 LOCAL_REJECT/COUNT7，与 n>N 的 FRAME_FAIL/COUNT7 分开。这是待批准的设计决定，不冒充资料原文，也不新增用户目标尺寸限制。

## 2. 共同首错与输出矩阵

先锁请求，CHECK 按以下已发生检查次序推进，失败即锁首错、不执行后项：

| 顺序 | 检查 | outcome/reason |
|---|---|---|
| C01 | W 偶数且 6…1920，H 5…1080 | FRAME_FAIL/COORD3 |
| C02 | version1、owner0、kind 为 11/12/13/14/15/17/18 | FRAME_FAIL/UNSUPPORTED12 |
| C03 | 两 signed flags 与 target 全零 | FRAME_FAIL/FORMAT2 |
| C04 | 本 kind 的高 payload 保留位全零 | FRAME_FAIL/FORMAT2 |
| C05 | 以下输入域表；同操作按 payload 低位字段顺序 | 按下表，不替未计算值制造错误 |

VALUE 为 outcome0/reason0，复合各字段各自编码、高 padding0；LOCAL_REJECT 为 outcome1、FRAME_FAIL 为 outcome2，均 reason 非零且 value385=0；匹配取消在父尚未 HELD 时优先 outcome3/reason0/value0。父旧 HELD body 永远保持，包括取消同 rsp_fire；reset 共同作废另记，不形成假响应。首错只锁一次，后续 private 收尾错误保存到观察账，不能覆盖父已有原因。

同一实际步骤多资格同时失败，沿 R3 E1 的优先：INTERNAL13 → OVERFLOW8 → COUNT7 → GRAD_ZERO1 → DIV_ZERO11 → DEGENERATE4 → ILL_CONDITION5 → GEOM_RANGE6 → CAPACITY9 → PROFILE10 → FORMAT2 → COORD3 → UNSUPPORTED12。跨步骤仍遵守已经执行的先后，此表不能抢先检查后续几何。

| 输入操作 | 先后域检查 | 分类 |
|---|---|---|
| 11/17 | n≤N，然后 n≥3；A/C 已是 unsigned43，D/F 的 signed56 无附加图像来源证明 | n>N 帧 COUNT7；n<3 局部 COUNT7；不对尚未求解中心预裁剪 |
| 12/18 | n≤N，然后 n≥2；其余统计按声明整数域解释 | n>N 帧 COUNT7；n<2 局部 COUNT7；PSD 在计算后核 |
| 13 | normal0 的 nx/ny 各在 ±2^30、二者不全零，然后 normal1 同查；rho 均完整 s18 | 坏 normal 帧 INTERNAL13；不能用 GEOM_RANGE 掩盖非法法线 |
| 14 | nx/ny 同上及非零，随后 x<W、y<H | normal 帧 INTERNAL13；点域帧 COORD3；之后才算/查缓存 K |
| 15 | 四端点是完整 s18 Q4，随后 x<W、y<H | 点域帧 COORD3；端点图外允许，不追加图内条件；零边在算 K 后局部拒绝 |

N=W·H 的最大乘积 2073600 收 u21；CHECK 的尺寸资格先成立，再用已锁 W/H 求 N。请求 ID 各字段除 owner 外是关联身份，不附加非零限制。

## 3. 七项计算守卫：只检查已形成值

| 操作/步骤 | 真值守卫与次序 | 失败分类 |
|---|---|---|
| LS L04 | 完整 s89 Δ≤0 | LOCAL_REJECT/DEGENERATE4 |
| LS L04 后 | T>0；Δ>0 且 unsigned A/C 已使 T>0，仍核这个派生不变量 | 违反为 FRAME_FAIL/INTERNAL13 |
| LS L09，仅11 | 完整 4Δ·65535 < det_min·T²；等号通过 | LOCAL_REJECT/ILL_CONDITION5 |
| LS L18/L19，仅11 | 宽商106先符合其 typed 域，再查 cx s18，成功后才查 cy s18 | 几何域外 LOCAL_REJECT/GEOM_RANGE6；不请求 child target18 |
| LS L20 | 完整 quality17 ≤65535，分母 T²>0 | 派生不变量破坏 FRAME_FAIL/INTERNAL13；17 不计算中心 |
| TLS T10 | Cxx/Cyy 完整 s67 先核非负，分别收 u64 | 负值 FRAME_FAIL/INTERNAL13；合法非负值若不容 typed 域为帧 OVERFLOW8 |
| TLS T13 | 原 s67 Cxy 的平方与 CxxCyy 全宽 PSD；成功才查/收 Cxy s65 | PSD 破坏帧 INTERNAL13；后续 typed 域不足帧 OVERFLOW8 |
| TLS T14/T20 | trace0，然后 D0；不拿未形成的 D 抢先拒绝 | LOCAL_REJECT/DEGENERATE4 |
| TLS T25，仅12 | 完整 anis 门左<右；等号通过 | LOCAL_REJECT/ILL_CONDITION5 |
| TLS T26 | 完整 anis17 ≤65535 | FRAME_FAIL/INTERNAL13；18 到此诊断 PACK，不进入后续几何 |
| TLS T34/36/38/39/40 | L>0；归一商 tx/ty 分量在 ±2^30；扩 s33 取负并规范方向 | 派生 normal/根不变量破坏 FRAME_FAIL/INTERNAL13；不裁剪 normal |
| TLS T51/T56 | 宽 rho 商70，查 s18；成功才算/查 μ 商70 的 s18 | LOCAL_REJECT/GEOM_RANGE6；二者独立一次 RNE |
| TLS T59/T60 | K≥2^58，M>0；此前已核规范 normal 域 | FRAME_FAIL/INTERNAL13 |
| 交点，分母前 | 完成 normal0 的 K 与守卫，再 normal1 的 K 与守卫；每条两个平方/ADD | K 小于2^58 帧 INTERNAL13；不要求重新规范输入方向 |
| 交点 I03/I13/I14 | den0；否则扩位同号变换；完整 x 商83 查 s18，成功才查 y | den0 局部 DEGENERATE4；几何越域局部 GEOM_RANGE6 |
| 法线距离 D03/D04 | miss 算 K、M；hit 取完整有效缓存 K/M，仍核 K≥2^58/M>0 | FRAME_FAIL/INTERNAL13；hit 不绕过前述格式/normal/点域 |
| 法线距离 D23/D24 | 修正最多一次；q u21；完整最终上下资格，q0 不形成负 odd | 资格破坏帧 INTERNAL13；不进行第二轮修正或无界迭代 |
| 有限边 F07/F11 | K0；否则用 s40 z 与 zero_extend40 K 判断端点/内部 | K0 局部 DEGENERATE4；没有 Q30 K 下界 |
| 有限边 F13/F14/F19 | 原 N/D、D>0，floor 商37、floor 根19及最终 q19 | typed 真值不足帧 OVERFLOW8；D≤0 是内部不变量破坏 INTERNAL13 |
| 有限边 F20/F21 | 原4N与全宽 odd²D 的上/下资格，q0跳下界 | FRAME_FAIL/INTERNAL13；不改原 N/D 表示 |

每个返回写槽前通用资格：匹配已预约 destination、合法 child matrix、385 完整表示与其 signed/unsigned target 相容、全值可规范扩展进192槽。错目的/错误矩阵/缺失槽资格/COMPARE code3 为 INTERNAL13；合法 child FRAME_FAIL 保留原 reason（2/3/8/11/12/13）；bridge 本地序号耗尽 CAPACITY9。无法取得 child quiet 不能伪造完成响应。每个负乘积的平方都先查非负，再按 u 类型使用；本页不删除 child 原 target 溢出检查。

两个正常失败走查：LS synthetic 的 Δ/条件成立而 cx=131072 越 s18，在 cx 守卫局部 GEOM_RANGE，不继续 cy；相同统计 kind17 跳几何输出 quality58253。TLS synthetic 的 PSD/D/normal/rho 成立而 μ=12000000 越域，在 μ 守卫拒绝；kind18 在 anis65535 已结束。它们仍是手算，未运行。

## 4. 父调度的状态与一槽提交

候选父状态 IDLE、CHECK、PREPARE、ISSUE、WAIT_RETURN、QUALIFY_RETURN、ADVANCE、LOCAL_COMMIT、DRAIN、PACK、HELD，共11种、4bit；子步骤编号 u7 足够，本版表最高 T61。路径及资格：

1. IDLE 只锁一笔622请求、清当前 slot/字段有效性；旧缓存保留。CHECK 从旧请求核上述次序；不因无效 slot 默认0而继续。
2. PREPARE 用已有效工作槽或 held payload 锁406命令，并预约目的；ISSUE 保持 cmd_valid/body 到 cmd_fire，不撤回已经提出的消息。桥 IDLE 且原 child quiet，正常没有第三方占用。
3. WAIT_RETURN 看旧桥结果 valid 才去 QUALIFY_RETURN；QUALIFY_RETURN 真正 result_fire，核旧缓存，成功只写唯一192槽及其有效位；ADVANCE 下一沿才读取新值、改变步骤或选择 LOCAL_COMMIT。错误锁首错进 DRAIN，不写业务槽。
4. LOCAL_COMMIT 对 SHIFT/MOVE/NEG/字段写入各一提交沿；多个 MOVE/NEG 分别推进子阶段，u<0 的 t 交换、normal 反号及 rho/μ字段均不得同沿读新写值。缓存安装是独立 entry 的原子更新，不能把它算成第二个工作槽写；取消同沿抑制安装。
5. 匹配取消在尚未 HELD 时锁 outer_cancel；停止未发布命令，已 valid 命令仍兑现握手。父分别保存 command_published（已经提出尚未接受）与 cmd_pending（已接受尚未返回）资格；取消进入 DRAIN 时保留已发布406命令及valid到真实 cmd_fire，再等待/消费对应缓存。DRAIN 的 result_ready 固定具备接收能力，独立 DISCARD，不看外部 rsp_ready、不写 slot；两命令资格全清且 bridge_quiet 真成立才 PACK。关闭内部错误时保留首错，不能把自己的 bridge abort 误报成外部取消。
6. PACK 只使用已经完成且有效的字段，错误/DROP 的385值为0；进入 HELD 后最早下一沿消费。HELD 后消费才回 IDLE，再下一沿接新请求；cold reset 对父/桥/child共同清有效性，统计真实 reset_aborted。

父 held ID 从接纳直到响应消费/冷作废保持；子 private_seq 只在真实 child_req_fire 推进。一个父请求无并发第二 fit，有效命令预约1、缓存返回1。工作槽有效性与 w15 两字段有效性独立，各次消费和 reset 在观察账可追踪。状态/slot guard、子步骤路径、取消≤8沿与形成沿预算均是未来仿真检查对象，不是已验证事实。

## 5. 最大私有调用数与形成沿

以下是成功最深分支的手工逐步骤计数，输入拒绝及较早退出只会减少调用。ADD/SUB 合并列，根列区分两种 primitive。所有已发义务仍必须真实收尾。

| kind | MUL | ADD/SUB | DIV | SQRT_RNE | SQRT_FLOOR | COMPARE | 总数 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 11 LS | 9 | 4 | 3 | 0 | 0 | 1 | 17 |
| 17 LS诊断 | 4 | 2 | 1 | 0 | 0 | 0 | 7 |
| 12 TLS | 23 | 13 | 5 | 3 | 0 | 2 | 46 |
| 18 TLS诊断 | 11 | 6 | 1 | 1 | 0 | 1 | 20 |
| 13 交点，含两 K 守卫 | 10 | 5 | 2 | 0 | 0 | 0 | 17 |
| 14 法线距离 miss | 13 | 3 | 1 | 1 | 0 | 4 | 22 |
| 14 法线距离 hit | 11 | 2 | 1 | 0 | 0 | 4 | 18 |
| 15 有限边，B端点且 q>0 | 12 | 9 | 1 | 0 | 1 | 3 | 26 |

TLS 分段总数为 T01…26 的22 + t/normal 的7 + rho 的9 + μ的4 + K/M的4 =46；诊断跳过 anis_min 的 MUL/COMPARE 且止于 T26，故20。有限边 base10 + B端点5 + tail11 =26；内部为25，A端点24。LINE 的四 COMPARE 来自初次低/高两界加最终低/高两界，其合法路径未必每次全部执行，表取保守上界。

现有 scalar 的 request_fire 沿 e0 到 rsp_valid 首次沿后成立（不含之后 rsp_ready 等待）的静态状态计数如下。MUL 每次有23 INIT、144 PART、23 EMIT、1 LAST、1 DONE，共192执行沿；普通共同 CHECK/SETUP/QUALIFY/PACK 四沿。ROOT 每次96 PAIR、1 START，内部平方同一192沿单元，RNE三平方/FLOOR两平方。DIV 为192 BIT、1 CHECK、1 ROUND。没有根据测得 max677 倒推出全部输入上界。

| primitive | source-derived 形成沿 |
|---|---:|
| MUL | 196 |
| ADD/SUB | 18 |
| COMPARE | 5 |
| DIV_RNE/DIV_FLOOR_U | 198 |
| SQRT_RNE | 677 |
| SQRT_FLOOR | 485 |

仅对真实原 child、同域无复位/取消、无外部仲裁适用；错误提前退出没有更长循环。将 PREPARE/ISSUE、桥 CHECK/SEND、真实响应消费/quiet、父 QUALIFY/ADVANCE 等另按每调用≤16沿作保守预约；其余输入检查/每项局部写/分支/缓存/最终 PACK 合计暂定≤1024沿（实际路径须在代码读回和仿真收紧/核对，不能额外加入1024轮业务循环）。由此完整预算：

| kind | 原 child 加权沿 | 16×调用 + 1024 后的候选上界 | 25MHz下时间预算 |
|---|---:|---:|---:|
| 11 | 2435 | 3731 | 149.24µs |
| 17 | 1018 | 2154 | 86.16µs |
| 12 | 7773 | 9533 | 381.32µs |
| 18 | 3144 | 4488 | 179.52µs |
| 13 | 2446 | 3742 | 149.68µs |
| 14 miss | 3497 | 4873 | 194.92µs |
| 14 hit | 2410 | 3722 | 148.88µs |
| 15 | 3212 | 4652 | 186.08µs |

独立 fit 候选形成上限统一16384个 core 沿（655.36µs），验证按真实外部 req_fire 至 rsp_valid 首次形成沿观测，每笔记实际 child 次数、slot写、cache hit/miss/install。16384 是本核测试的截止预算，不是合成后时钟、识别FPS或新增硬件超时丢请求许可；超预算测试失败保留live记录。外部 HELD 等待不计，可无限。形成预算的局部控制部分尚需代码生成前 F-B02 最终状态读回，故本稿没有单独宣布 READY。

## 6. 全核有限容器与物理门槛

| 所有者/数据 | 容器上界 bit | 说明 |
|---|---:|---|
| 原 scalar core | 2532 | 沿原已批准候选预算；实际源码时序声明求和2363，其余169为原余量；不复制原 probe |
| 父 held request | 622 | ID/W/H/统计均引用这一份 |
| 父结果 | 395 | value385/outcome2/reason8，输出ID/kind/target引用 held request |
| 父待接纳子命令 | 406 | PREPARE锁命令、ISSUE/DRAIN保持到cmd_fire；桥另存其已接受命令，不能把两份隐藏合并 |
| 16 工作槽 | 3072 | 16×192，一沿一槽写 |
| 工作/复合字段资格 | 18 | slot valid16、w15 anis/μ valid2 |
| 父有限控制余量 | 256 | FSM4/step7、subphase、cmd_pending、目的预约、cancel/首错/模式/typed规则及候选辅助位；实际声明逐项核，不能藏数据数组 |
| private bridge | 1000 | cmd406/cache403/两64序号及≤63控制位，无第二 parent body |
| 4项 K/M cache | 654 | 4×163+replacement2，原子安装，reset只清有效资格 |
| fit 核小计 | 8955 | 是有限 bit 容器，不是 Map FF/XLR |
| 拟观察 source/consumer/reset | 1827 | 暂沿 scalar probe 容器上限：384源/622请求/585响应/seq64/CRC32/index10/control128/reset2；具体七kind合法来源待 F-B03 |
| 独立整工程候选总计 | 10782 | mux/LUT/ADD/时钟/reset扇出另由 Map/PNR 测 |

只实例化一份原16×16乘法算术核，不并行复制46算术引擎。工作槽/cache 明确 FF 实现候选，无 ROM/大帧RAM；native RAM 预算0，DSP候选≤8，XLR候选≤50000且不得超过芯片硬容量。它们是独立 probe 的失败门槛，不能借已测 scalar16190 XLR 相加推定 fit 实装；综合优化、192槽 mux、符号扩展和控制扇出都可能改变结果。

25MHz候选，Ti60F225/I3；独立四pin先沿已验证 scalar 板卡资料 J2/P13/N14/P14 的时钟/KEY/两LED电气设计，最终 SDC/工程在 F-B03 定稿。需要实测 setup/hold≥0、内部 unconstrained/no_clock/multiple_clock0、真实工作槽/桥缓存/child/cache/source→consumer 的 Q→D 路径；只允许已说明的 KEY 两输入异步复位点及 LED 外部输出例外。不用大范围 false_path 掩盖算法。Map/Interface/PNR/STA 有效通过才生成并登记 bit/hex，然后停止硬件步骤。

此独立 FF/DSP/RAM 与形成预算不包含 ANGLE、R1/R2、DDR、生产相机/HDMI/CDC、完整识别的支撑遍历/候选/去重/绘图。完整任务性能、存储、资源与质量仍未证明，不能从单笔TLS时间推算整帧FPS。

## 7. 验证与未闭合事项

FT-T01…06 应补全本页每个共同格式/输入域/计算守卫的反例、相邻界值、组合错误首因；合法完整385与非VALUE0、诊断跳过几何、caller错误与隔离fake-child错误分账。FT-T07/08逐个父/桥/child状态取消与 reset，包含已经 valid 时同 fire、错cancel ID、MAX尾两次/第三容量、DRAIN无外部ready依赖，观察真实关闭而非计时删除。FT-T09逐笔检查上表调用数/形成沿、随机与确定case独立参考、缓存路径；FT-T10物理数据路径不能因LED心跳通过而替代结果。

本页将 F-B04 改为 DESIGNED_REVIEW_PENDING；F-B02 已有状态/计数/形成候选但仍需最终组合审阅；F-B03 尚需完整文件/七kind source/参考/TB/seed/工具清单及冻结基线。未获指定批准，不生成业务 RTL、参考、脚本、TB 或功能实验。原 scalar、ANGLE及其基线不改，正式DB/硬件状态不变。
