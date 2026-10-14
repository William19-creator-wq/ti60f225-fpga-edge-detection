# TRACK4-GEOMETRY-POINT-MATH-001 v1.1：圆重放逐点评估

2026-10-11。短卡依照 PLAN_TEMPLATE。设计先保存、读回并由 root 呈现，随后按用户持续授权“当你统计完后自行进行，无需我的批准”、整合优先、免新增长中文草图/独立测试和本地审计，在限定 candidate 中实施；本卡不冒称用户批准了此版号。正式状态、数据库、原 HDK、主编译冻结输入及硬件均不修改。

## 整体范围与基线

- Goal / Gap：完整 A6 的 HIST 和圆 A/B/C/D/E 五遍需要同一逐点评估器。MOD-PM 只从 POINT64 v2、中心和角度容差产生 Q4 半径及法线相容性；分区、径向带、计数、拟合、筛选、DDR、标注仍由父协调器承担。这里不宣称完整识别已完成。
- 计划代码：独立 candidate 的 `board/rtl/board_geometry_point_math.sv`；不接入 main XML，不运行新 TB、仿真或 EDA。
- 实读复用：`board/recognition_numeric/scalar_protocol_pkg.sv` SHA256 `40D7FC511C4E481B0B194A2B31D53C18627EC7D420A5B54E17C438E5832D3028`；`scalar_core_words.sv` `1568D08773306D8F56C35E77E399502D4BEADA46D15234D537DFF30BBA7DA4E4`，两者未变。v1 当时只读来源为 `scalar_bridge.sv` `CA1392F51BAC22768B31D7599E8E729017F822DBE13DE01CA9590890DE757DC5`、`board/rtl/board_circle_seeds.sv` `C45B239B359388FE934DE4EA4BCD1A8EDC58CA9BFB78F544BB06C3FC122ED71D`。v1.1 已现场核对共享返回字的新基线：bridge `81BD861C64746F89AEF48AC45EB1E8CD4CAAB948A7676FF364790F67DBACC22F`、SEED `CBD5DA39684C6960C32A4AA44E39427DD62196D4C3C1602529436F88B1FEE2FD`。
- 原核 REQ622 / RSP585、操作数 192 位、完整返回 385 位、原舍入与错误矩阵保留。SEED 调用者高字节 02；FIT bridge 高字节为零扩展 destination 0–15；PM 使用固定 C1，避免混淆。原 owner 字段始终 0。

## 接口与组合契约

IF-EVAL（父 HIST/圆重放 → PM）：`eval_req_valid/ready`；输入 `scope[95:0]`、`seed[7:0]`、`pass[2:0]`、`ordinal[20:0]`、`point[63:0]`、signed `cx/cy[17:0]`（Q4）、`tolerance[15:0]`（0–65535）。输出 `eval_rsp_valid/ready`、原样回显 scope/seed/pass/ordinal、`radius[17:0]`（Q4）、`normal_ok`、`error`、`drained`，以及 `quiet`、粘性 `fault`。pass 为不参与运算的标签；当前父使用 HIST=0、A=1、B=2、C=3、D=4、E=5。

只有父已取得唯一 scalar 的 PM 物理所有权、前任 FIT 包括私有 bridge 的借用结果均 quiet 时，才发起 EVAL。PM ready 仅在本地空闲、child quiet、非耗尽/隔离时为 1。正沿 valid&&ready 接受，单预约无第二在途点。父从接受起保持所有输入字段，直到 EVAL 回复消费且 PM quiet；UNKNOWN 时保持到共同复位。输入正文借用，不另复制点或上下文大包。正常输出 radius/normal/error/drained 连同身份在背压期间保持。

POINT64 v2：Gx signed11 `[10:0]`、Gy signed11 `[21:11]`、dir2 `[23:22]`、零 `[31:24]`、x11 `[42:32]`、y11 `[53:43]`、theta9 `[62:54]`、零 bit63。校验与当前 SEED 的真实 POINT 域一致：保留位零、x<WIDTH、y<HEIGHT、Gx/Gy 在 ±1020、两绝对值和≤1530、梯度非零；ordinal<WIDTH×HEIGHT。零梯度/非法记录为错误，不能作为 normal=true 的有效点。cx/cy 接受完整 s18 Q4，不裁剪到画面内；tolerance 不降低或改变来源参数。

IF-NUM（PM ↔ 父唯一 scalar）：`num_req_valid/ready/body[621:0]`、`num_rsp_valid/ready/body[584:0]`、`num_quiet`。所有 header、A/B 及有效 ID 自 child 接受起保持到真实回复消费及 child quiet，满足 BORROW_HEADER/PAYLOAD。请求最大 target：普通运算 192、SQRT_RNE 97、COMPARE 2；完整 192 位按实际有符号性由 128 位工作值扩展，上 16 位 payload padding 为零，sqrt 的 B 全零。

v1.1 仅增加默认 0 的 `SHARED_RETURN_WORDS`，输出 `num_rsp_word_index[4:0]`、输入 `num_rsp_word16[15:0]`。启用时 NUM_SCAN 以 scan_word、REG_WRITE 以零扩展 word 驱动游标，其他状态游标为 0；直接使用父端唯一返回字选择树，不在 PM 另建完整 385 位动态选择树。scan_word=24 时依 PM 原 signed extension 补齐高 15 位，只取共享字 bit0 作为 value384。默认 0 保持完整正文的原局部选择方式；完整 585 位接口、低 metadata、原 bit584 符号来源、25 字资格和错误矩阵均保留。返回侧带不得用 valid/quiet 门控丢失 held 数据，正文借用/关闭边界不改。不扩成 input-word 优化，仍是一 RAM、两个 128 位 operand 和同一 scalar。

NUM_ID=`{8'hC1,closed_sequence[63:0],8'd0,scope[95:0]}`。closed_sequence 只在本次真实回复消费后的 child quiet 关闭沿推进，当前 ID 因而不需要第二份 pending 快照；不能在点、seed、pass 或 job 开始时重置。仅共同冷复位清零。最大序号可使用一次，关闭后锁定 exhausted，不能回绕复用。若同一个已接受 EVAL 还需要下一数值调用，回复 error/drained=true；若 MAX 恰是最后一步，该 EVAL 可照常成功交付。MAX 关闭后锁定容量 fault，后续 eval_req_ready=0，父按 fault 停止；不制造没有 EVAL 握手的回复。quiet 仍只报告真实在途关闭，不由 ready=false 推断。外层 scope/seed/pass/ordinal 保持和回显建立完整映射，不把它们截短塞入 NUM_ID。单一 caller 的序号不重复；物理所有者枚举不写入 owner8。

## 数值规则与内部次序

REQ-PM1：dx=16x−cx、dy=16y−cy；D2=dx²+dy²；radius=RNEsqrt(D2)。REQ-PM2：cross=Gx·dy−Gy·dx；normal_ok 当 D2 非零，且 `cross²·65535² ≤ tolerance²·(Gx²+Gy²)·D2`。等号通过。零径 radius=0、normal=false，无除法。不能替换为错误的 dot/cos 门，不能对半径截成 17 位。

| 值 | 保存资格 / 说明 |
|---|---|
| dx、dy | signed19；先扩展再相减 |
| dx²、dy²、D2 | unsigned38、38、39 |
| Gx·dy、Gy·dx、cross | signed30；合法坐标/中心/梯度边界证明 cross 可装入 s30，不靠截断 |
| cross²、Gx²、Gy²、G2 | unsigned60、22、22、23 |
| tolerance²、65535² | unsigned32；后者精确常数 4294836225 |
| 左式、右式 | unsigned92、94；乘法仍经同一 192 位 scalar |
| radius | unsigned18；1080p 下 dx 的绝对值≤161776、dy 的绝对值≤148336，D2≤48175043072，RNEsqrt≤219489<2^18 |

MOD-PM 使用一块同步 16-bit 工作 RAM：16 个完整 128-bit slot，共 128 words/2048 bits；两个 128-bit operand 暂存按同步读的 READ/CAPTURE 两沿加载，整个 child 借用期禁止重装。所有 slot 每个 EVAL 都由实际写入和 valid 位建立，不复位 RAM 正文。短固定 micro 次序可由常量 case 描述，无新乘法核、独立 scalar、385/512 位 FF 回复快照或额外可写程序 RAM。

按依赖执行最多 18 次调用：dx、dy、dx²、dy²、D2、sqrt；Gy·dx、Gx·dy、cross、cross²、左式；Gx²、Gy²、G2、tolerance²、tolerance²·G2、完整右式、compare。16 slot 分别保存前 16 项，右式复用最后临时 slot；compare 使用已失效的乘积 slot。radius 在 sqrt 资格通过后仅保存 18 位，normal 在最终 compare 通过后仅保存一位。D2=0 在 sqrt 关闭后直接返回 normal=false。

每一调用：加载操作数 → req 握手 → 等待真实 held 回复 → 检查完整 ID/kind/target/outcome/reason → 按 25 个 16-bit 片段核验所有 385 位的符号扩展/零扩展 → 写入完整 8-word slot → 真实消费回复 → 等 child quiet → 关闭序号推进 → 下一项。正负符号资格采用完整返回的 bit384，按存储域边界核验，不从低位猜符号。COMPARE 只接受值 0/1/2，normal 为 compare≠2；非法 3 为错误。没有完整资格不能窄化或发布成功。

## 失败、释放、复位与资源

- 本地非法输入或耗尽且没有子请求：error=1、radius=0、normal=false，若 child 已 quiet 则 drained=true。耗尽锁定到共同复位；不循环等待一个不会再生成的 ID。
- 本次 ID 的 FRAME_FAIL / CANCEL_DROP 按原完整矩阵核验（错误正文必须全零；取消仅对应真实已声明取消）。本模块没有本地取消/超时接口，取消为 N/A；未声明取消出现 CANCEL_DROP 也是错误。确认是本 ID 的错误回复可消费，等 child quiet 后只发 drained=true 的错误。kind/target/资格失败也不变成数值成功。
- 回复 ID 不相符属于 UNKNOWN：不消费别人的回复、不强清 owner、不假造 quiet；发布 error=1/drained=false，粘性 fault，EVAL 消费后仍隔离到共同复位。没有回复或未 quiet 时持续等待，不能凭 elapsed time 宣告 drained。
- 所有接口同一 core 正沿/共同同步 rst，复位关闭 valid、清控制/资格/冷序号；父和唯一 scalar 必须同时复位，否则 BORROW 不可安全提前释放。无新 CDC、引脚、时钟、DDR 副作用。quiet 反映真实关闭，不用 exhausted 的 ready=0 冒充未关闭；UNKNOWN 保持 quiet=false。
- 结构预算仅估计：1 RAM、0 新 DSP，两个 128-bit operand、64-bit 序号、18-bit 半径和控制/资格 FF。18 个串行 scalar 调用会有可观处理时间；此卡不声称 FPS、资源或时序达标，实际 whole-board 结果仍待后续。

## 走查、追踪与停止点

REQ-PM1 → EVAL/距离 6 步/RAM 资格 → 计划 MOD-PM 数值状态；REQ-PM2 → 法线 12 步/比较 → 同模块后半段；派生身份/释放要求 → EVAL 持有、NUM_ID、关闭状态。反向看所有 RAM/序号/资格/错误状态均承担这些数值或交接保证，未加独立拟合或筛选行为。

文字场景（未执行、不新增 TB）：x=10,y=20,cx=160,cy=320,Gx=1,Gy=0，得到 radius0/normalfalse；x=11,y=20、同中心、Gx=1,Gy=0 得 radius16/normaltrue，即使 tolerance0 也因 cross0 通过；同径 Gx=0,Gy=1/tolerance0 得 normalfalse。另走查 s18 中心极值、比较等号、完整高位溢出、req/rsp 背压、同 scope 的下一 point/job 不重置序号、MAX 最后一次关闭、异 ID 隔离、共同复位。

这些是设计分析，非仿真事实。当前局部端口、数值及借用契约无 TBD；父 scalar owner 和完整圆后端的实际接入仍在本卡范围外。root 已读回、呈现并限定 candidate 单文件实施；保留当前 056 实际综合及 main。v1.1 同步当前共享返回字侧带并明确 MAX 关闭时的 ready/quiet 语义；数值及 EVAL 身份未变。理解验收未检验，完整 A6/矩形/标注/实物效果未完成。

## 限定实施实录

已生成 `work/active/track4_board_first_20261011/candidates/geometry_point_math_v1/board/rtl/board_geometry_point_math.sv`，最多 18 calls、单 128-word 工作 RAM、两份 128-bit operand、默认关闭的 shared-return-word、C1/64-bit 关闭序号及原完整资格均可定位。定向静态读回核对 micro 次序/slot 依赖、位宽/符号扩展、共享字 24 的补位、借用期 PC/operand/ID 保持、MAX 与 UNKNOWN 关闭、无本地乘法核和基数字面量邻接问号。没有新增或运行测试、EDA、整机接入；运行正确性、资源及时序仍未验证。哈希与授权范围记录在 candidate 的 `change-record.json`。
