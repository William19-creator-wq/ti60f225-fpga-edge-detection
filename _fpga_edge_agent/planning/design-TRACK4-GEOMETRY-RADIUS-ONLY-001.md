# TRACK4-GEOMETRY-RADIUS-ONLY-001 v1：逐点评估按需停止于半径

2026-10-11。READY_FOR_REVIEW，短设计尚未编码。引用用户持续自主推进、本地审计及免新增独立 TB 授权；不伪称指定版号获批，不改当前 PM/CF/main、057 或原候选。

- Goal / Gap：CF 的 B/c1、C/c0、D/c0、D/c2 只使用完整 Q4 半径，不用法线参与该阶段资格；停止这些调用的法线十二步，保留其原成员谓词、半径数学、完整数值资格和真实关闭。
- Baseline / 阅读：PM 卡 `planning/design-TRACK4-GEOMETRY-POINT-MATH-001.md` v1.1（SHA256 `008567B7187157BADEFA8C5C0F56ADC603CB61342AAC309B174FF2D7CE06537D`）→ CF 卡 `planning/design-TRACK4-CIRCLE-REFINE-001.md` v1（`AB183515BCA0DA293179B0E578B023F3653D98AB6CE5C68F68C5CD539A3B28AB`）→ 实际 PM `work/active/track4_board_first_20261011/candidates/geometry_point_math_v1/board/rtl/board_geometry_point_math.sv`（`83172157F710AB694F11782E73E0C75914B0B906415F9B8B507E120A3579CB21`）。未来只复制 PM 到新的 `candidates/geometry_radius_only_v1/board/rtl/board_geometry_point_math.sv`，保存 before/记录；父 CF 接线另属后续限定实施。
- IF01：新增 bit 参数 `ENABLE_RADIUS_ONLY` 默认0，新增输入 `eval_radius_only` 一位；追加声明以保留已有参数/端口顺序。effective 为 `ENABLE_RADIUS_ONLY && eval_radius_only`。默认关闭时该新输入未连接也不影响原十八步及零径流程。
- 借用合同：新位是 EVAL 正文的一部分，合法调用者给明确0/1，从 EVAL 真接受保持到 EVAL 回复消费且 PM quiet，UNKNOWN 时保持到共同复位。与原 scope/seed/pass/ordinal/point/center/tolerance 同寿命，直接借用，不新增快照。不能仅在 PM 的 NUM 回复消费后切位，也不能仅按 pass 标签推断此位。
- 算术：effective=1 时仍顺序执行 pc0…5 的 dx、dy、两平方、D2 和原 SQRT_RNE；保留 s19 差、u39 D2、u18 radius、sqrt target97、unsigned18 返回资格，不收成17位。不执行 pc6…17 的法线计算；输出 normal_ok 明确0表示未计算，父只算半径的阶段不得用它作资格。effective=0 保留原 cross 平方式、容差和等号规则。
- 实际关闭点：pc5 在 REG_WRITE 的 word==7 才写 radius18，之前已完成全部25字资格并写原8字 slot；仍经 NUM_CONSUME 真回复消费，再到 NUM_CLOSE 等 num_quiet。只扩展现 pc5 零径终止条件为“零径或 effective”；该成功终止时显式 normal_ok=0、drained=1，进入原 RESULT 后才公开 EVAL valid。不得跳过 pc5 的 NUM_SCAN/REG_WRITE 或提前在 sqrt 数值可见时发布。
- 错误与序号：NUM_CLOSE 仍先推进真实关闭序号/锁 MAX，再优先处理 numeric_failed；known error、异 ID UNKNOWN、不消费他人回复、隔离、LOCAL_CLOSE、fault、MAX可最后一次成功且禁止回绕、背压及共同复位均不改。零半径的原快捷关闭和 normal=false 保留；未计算法线不是错误，也不伪造 normal=true。
- CF 布尔分配：1仅为 B/c1、C/c0、D/c0、D/c2；0为 HIST/c0、A/c0、B/c0、C/c1、D/c1、E/c2。B/c0与D/c1仍重放原 normal 成员，HIST/A/E仍需 normal，不能整遍 B/C/D 统一置1。父保持各子阶段位直到 PM quiet 后才进入下一中心调用。
- 中文操作草图：父锁 EVAL 及该子阶段布尔位 → 原六条距离数值指令逐项完整校验/提交/消费/quiet → pc5 真关闭后只算半径的调用直接发布 radius、normal0 → 父只取 radius、消费回复并等 PM quiet → 下一子阶段；需要法线的调用继续原 pc6…17。
- 性能 / 资源：单 seed、一个未提前拒绝峰且按全点扫描的指令上界由 HIST+9PM 的 `10×18=180` 降为 `6×18+4×6=132` 次 scalar/点；两次选中后的调用本来只覆盖成员，实际可能更少。多峰上界为各 seed 求和 `E×(18+114×峰数)`，未含 FIT/STATS/CR/ANGLE、DDR、加载/资格/关闭，不是132个 core 沿或实时证明。不宣称128、速度达标或面积必省；一位组合分支且不加存储，实际工具成本仍待测。
- 验证 / 双向追踪：按需距离需求→IF01/pc5终止→default0、开1位0、开1位1/零径静态核对；数学不变→pc0…5/完整资格→原 radius18 和 NUM closing；原成员不变→CF分配→仅四子阶段不用 normal。重点 pc5 known fail/UNKNOWN/最后序号、结果背压及子阶段位持有；不新建或运行 TB、仿真、EDA。
- 回退 / 完成：参数0恢复原 PM 行为，未来 before 保留。ROOT 读回呈现后再限定独立候选编码；局部优化不代表圆五遍、RPC 接入、容量/时序、实时性或完整 A6 完成。
