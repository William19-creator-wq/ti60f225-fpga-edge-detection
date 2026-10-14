# TRACK4-FIT-DSP-DIRECT-001 v1：FIT DSP 输入按实际写条纹选择

2026-10-12，精简设计-only卡，状态 READY_FOR_REVIEW，供 ROOT 读回呈现。继承用户自主继续、免新增长草图/TB及本地审计授权；本轮仅保存规划，ROOT 指定独立候选前不生成业务代码、不修改 main/061 冻结输入、不启动 EDA/TB，不更改硬件或正式数据库状态。

- Goal / Current / Gap：现有 FIT 的 385bit `scalar_value_next` 已通过 DSP 的原 CE 规定真实写沿，但 DI 仍重复受 reset、matching_cancel、计划资格和非写半 bank 的置零选择控制。只简化这些无 CE 沿的数据选择，保留完整 192bit 操作数、385bit 结果资格和全部现有计算。候选与资源实测尚未完成。
- Baseline：实际 main 及 `runs/board_compile_061/flow/` 读回一致：`board/recognition_numeric/fit_core.sv` SHA256 `875083D9835283FCABA45372A08BE2CF2B8056AA99F310F24DA15135565242F6`；`board/rtl/board_recognition_stats.sv` SHA256 `14228BE6277F5CDC5989D1D002D62C4590514E941BDEF5D55530D76527835A22`。不得用旧 before 覆盖已合入的 geometry lease、NUM 返回字口及 LS_TLS_ONLY 保护。
- Scope / Target：仅上述两源的独立 candidate。FIT 新增 `DIRECT_DSP_INPUT`，默认 0；仅新 flag 为 1 且 `DSP_OPERAND_RESULT` 为 1 时使用下表条纹 DI。STATS 的唯一 `fitting` 实例仅增加该参数为 1，保留全部现有参数、端口和连接。默认关闭及 DSP 关闭时继续原路径。
- Dependencies / Open questions：原 `scalar_value_next`、`scalar_value_write` 和每条 `word_write` 原文保留，FF 分支全不动；原 EFX_DSP48 参数、CE、CLK、RST、padding 与输出连接全不动。尚无实际净面积/时序收益，数百 LUT 仅是待测机会，不保证容量或布线通过。

## 接口、来源与真实采样表

无新数据端口、消息格式、时钟、存储、寄存器或周期。REQ/RSP 仍 622/585bit；操作数为两个完整 192bit，公共暂存/结果为完整 385bit。`H` 表示采样沿前原 `scalar_or_final_value`；`F` 表示原 `plan_value`。

`A` 的 192bit 数据精确沿用原 LOAD_A 三分支顺序：`USE_WORD_SLOTS && operand_is_slot` 时为 `{slot_word_q,H[191:16]}`；否则 `local_shared && !SERIAL_LOCAL_MOVES` 时为原 `local_loaded_value` 按 `held_local_shift` 左移；否则为原 `selected_operand`。`B` 精确沿用原 LOAD_B：字槽时为 `{slot_word_q,H[383:208]}`，否则为原 `selected_operand`。不删默认参数组合的局部取负/移位支路，不把 192bit 输入窄化。

定义原公共写资格 `G` 为 `!rst && !(matching_cancel && state != IDLE)`；表内 PREPARE 写资格为 `G && plan_class == 2`（原 ROM/class0/class1 分支均不写），DRAIN 写资格为 `G && !command_published && !cmd_pending && bridge_quiet`。这些只是读回原 CE 的说明，不改表达式或优先级。

| 条纹与全 bank 位域 | PREPARE 的真实 CE / DI | LOAD_A 的真实 CE / DI | LOAD_B 的真实 CE / DI | DRAIN 的真实 CE / DI |
|---|---|---|---|---|
| 0–4；各 36bit，整体覆盖 H[179:0] | 上述 PREPARE 资格 / F 对应 36bit | G / A 对应 36bit | 0 / 不采样 | 上述 DRAIN 资格 / 全零 |
| 5；H[215:180] | 上述 PREPARE 资格 / F[215:180] | G / 高 24bit H[215:192]，低 12bit A[191:180] | G / 高 24bit B[23:0]，低 12bit H[191:180] | 上述 DRAIN 资格 / 全零 |
| 6–9；H[359:216] | 上述 PREPARE 资格 / F 对应 36bit | 0 / 不采样 | G / 依次 B[59:24]、B[95:60]、B[131:96]、B[167:132] | 上述 DRAIN 资格 / 全零 |
| 10；带 padding 的 [395:360] | 上述 PREPARE 资格 / 高 11bit 零、F[384:360] | 0 / 不采样 | G / 高 11bit 零、原 H[384]、B[191:168] | 上述 DRAIN 资格 / 全零 |

其它状态每条原 CE 均为 0。新 DI 不再重复添加 G、plan_class 或无效半 bank 的资格门控：条纹 0–4 的 PREPARE 取 F、DRAIN 取零、其它情况可直接取 A；条纹 6–10 同理取 B 及表内 bit384/padding；条纹 5 按 PREPARE/LOAD_A/LOAD_B 精确选择，其它取零。CE=0 时 DI 变化仅是内部组合值，不构成数据写入，不改变公开消息。

bit384 在 LOAD_B **保持原 H[384]**，不是 B 的符号位或常量；LOAD_A 不写条纹 10。条纹 5 同沿必须保留另一半原位，不得从同沿新 A/B 或下一状态值猜测。385bit 输出的映射仍为条纹 0–9 的全部 36bit及条纹 10 的低 25bit；高 11bit padding 固定零。

## 生命周期、精度与组合检查

原 DSP 仅 O_REG 开启且 O_REG_USE_CE=1、O_REG_USE_RST=0；在每条 CE 为 1 的边沿，新 DI 与原 `padded_value` 对应位逐位相同。复位/匹配取消仍通过原 CE 禁写；数据 bank 原本不复位，本卡也不改变。DRAIN 仍在已发命令和待回复均关闭、bridge_quiet 后清全部 385bit；PREPARE 只在原完成计划提交最终值。HELD 期间 CE 仍为 0，VALUE/error/identity 及背压保持原样。

原状态机、命令和 slot 有效性、借用请求至回复消费且 quiet 的契约、NUM 元数据门控及完整返回扫描、错误优先级和取消排空均不改。STATS 的 `LS_TLS_ONLY(!(ENABLE_GEOMETRY && GEOMETRY_FULL_FIT))` 表达式及 geometry bind/release 连接保留，不趁本卡启用新种类或改变场景。DDR 区域、256 种子、峰表、图像尺寸与时钟也不变；本卡不是完整 A6 或实时性闭合证明。

## 实施、验证、追踪与恢复

- Milestones / Detailed steps：ROOT 读回呈现 → 指定两源独立 candidate，保存这两个真实 before 与 change-record → 仅参数/DI 分支/唯一父实例参数差异 → 定向静态审查 → ROOT 决定临时合入一次整机工具测量。不得写入 061 flow 或原 HDK。
- Validation（未执行）：核 default0/DSP0 原 DI 路径；全部四类条纹的 PREPARE/A/B/DRAIN 真实 CE 写数据；条纹 5 跨 192bit边界；条纹 10 bit384=0/1；复位及匹配取消同沿 CE=0；PREPARE 非完成计划不采样；DRAIN 未 quiet 不清零；HELD/借用正文稳定。仅文字场景与后续静态审查，不新增 TB/功能脚本。
- 双向追踪：REQ 保持功能/完整精度 → 原 A/B/F/H 精确字段及条纹表 → FIT 的 DSP DI 分支；REQ 保持写沿/错误/协议 → 原 scalar_value_write/word_write/FF/FSM 不动 → default0、cancel、DRAIN、HELD 场景；REQ 单份实例实施 → STATS fitting 参数 → 全部 geometry/NUM/LS_TLS_ONLY 原连接核对。
- Failure handling / Rollback：如任一有效写沿不等价、出现新存储/周期、候选偏离这两源或工具收益为负，则停止/关闭 DIRECT_DSP_INPUT；恢复仅本候选差异，不回退已采用的 GEOM/NUM/其他优化。正式工具通过前不登记新硬件下载版本，软件失败不算硬件新版本。
- Artifacts and hashes / Completion：候选须记录本卡 hash、上述两个基线 hash、before/final hash与实际 diff。当前只有本设计文档；未实现、未 EDA/TB/硬件观察。候选静态通过不等于综合/布局布线/最终 STA 通过。
- Human approval gates：用户持续自主实施与本地审计授权沿用；不冒称本卡已获新增逐版人工批准。此轮下一允许行动仅 ROOT 读回/呈现和限定候选授权；下载与实体观察仍人工。
