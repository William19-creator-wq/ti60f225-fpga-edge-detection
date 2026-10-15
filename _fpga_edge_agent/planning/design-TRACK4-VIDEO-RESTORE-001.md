# TRACK4-VIDEO-RESTORE-001：先恢复自研工程的 HDMI 基础输出

## A. 状态与阅读入口

- **版本/状态**：v1，2026-10-15，READY_FOR_REVIEW；尚未批准实现，尚未修改源码。
- **目标**：以 REFINE B02 为输入，在新的 `work/` 独立副本中恢复官方 v7 已工作的 PLL 连接；让无已发布图像时的 HDMI 输出有明确彩条；用 D2–D7 标出关键启动状态。完成综合、布局布线、时序检查、bit 登记后停在人工下载闸门。
- **本版不处理**：摄像头 RAW 帧发布、FIFO 溢出恢复、Canny/识别吞吐、Bayer 相位及白平衡校准。它们应在 HDMI 稳定出信号并得到本版灯态后定位；本版不宣称解决偏紫/偏绿或已能显示摄像头图像。
- **依据**：[2026-10-15 研究报告](../reports/video_research_20261015/摄像头出图与偏色问题研究_20261015.md)；用户实测：新摄像头在官方 v6/v7 可出画面，031/refine 无信号/待机。官方 v7 作为 PLL/引脚参考，只读。
- **基线 B02**：`work/active/track4_board_refine_from031_20261013/`；原 bit SHA256 `63906ed2a32f595069f1d7b738cc9106f03d8d638e83a504fe85fd1250c371a2`。项目无 Git 仓库，不虚构 commit。受影响输入文件 SHA256：

  | 文件（相对 B02） | SHA256 |
  |---|---|
  | `track4_board.xml` | `23900ECE10F36D28992C81783EA672497EBBADB7FF9510DE2BF66B97A4F21471` |
  | `track4_board.peri.xml` | `307780EF671DA2F44D310F5949D43C3473F393C66D64A024E6597FC3DE51E7C8` |
  | `track4_board.sdc` | `18C64734D6592F929ECD05C229C4DCA0F669CF2E3252A87C6B89D65EBA094977` |
  | `rtl/ti60f225_oob_top.v` | `915481A3E6E38DA44E3408FA1A0B85856B02303B61DF96DDDB27A38EE147C931` |
  | `board/rtl/board_frame_display.sv` | `800D455A40E87D82E7D9215101B3423F5C5D73DCCE81164ACCE5211612052CBC` |

- **参考哈希**：官方 v7 `ti60f225_oob.peri.xml` SHA256 `884225E0EA6554EBA62192CA03D49F8265121E069830FA09EE41694980148605`，`ti60f225_oob.sdc` SHA256 `7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF`。只读取相关 PLL/引脚设置，不覆盖原包。
- **边界条件**：本设计没有影响实现正确性的未决技术项；实际是哪颗 PLL 或哪条视频路径出问题，正是上板诊断目标。PostgreSQL 仍未配置，实施/构建须在用户批准本任务本地追加审计例外后进行；不写正式数据库或正式节点状态。
- **批准记录**：用户“根据这个改吧”授权依据研究报告制定修复方案；该话说在本 v1 形成前，不登记为对本版本及范围的明确批准。`APPROVAL_MANIFEST.yaml` 尚无本任务条目。
- **下一步允许行动**：阅读/评审本设计；获指定版本、范围、B02 基线和本地审计例外批准后，才建立实施副本和修改 RTL/约束。

## B. 整体行为和边界

| REQ | 外部可观察行为 | 失败/边界 |
|---|---|---|
| VR-1 | JTAG 下载后，视频时钟及复位释放，HDMI 显示器能持续识别 1920×1080@60。 | 某 PLL 未锁时允许无图，但相应诊断灯指出位置；不把画面黑或花判作 HDMI 无信号。 |
| VR-2 | 尚无已发布帧时，1080p 有效区显示八条固定竖向彩条；帧发布后从下一个视频帧起回到 B02 原有输出。 | `has_frame` 在视频帧中途变化不得撕裂半帧；FIFO 欠读时仍沿用原黑像素处理。 |
| VR-3 | D2–D7 直接反映复位/锁定/视频释放状态；D0/D1 沿用 B02。 | 灯是诊断，不代替示波器或 HDMI 验收；`led[2..7]` 使用官方 v7 同引脚和 1.8 V 配置。 |

上电/复位时视频关闭；三个必要 PLL 锁定后，顶层沿用原约 0.9 秒的 `vid_rst_n` 延迟；无帧呈彩条。有帧且在视频帧首锁定后沿用原 RGB/FIFO 显示。断电或复位丢弃彩条切换状态及未完成帧。实物验收先看显示器是否持续有 1080p60 信号，至少观察 5 分钟，再看 D2–D7。是否有摄像头画面和颜色是否正确属于后续工作。

## C. 职责与整体连接

```text
25 MHz / 27 MHz 板载时钟
  → [IF-1] peri.xml 内 DDR3_PLL / MIPI_TX_PLL / USER_PLL / pll_inst4
  → [IF-2] 顶层三路 locked 与 vid_rst_n → HDMI 编码器/板级视频复位
                                       ↘ D2–D7 状态灯 [IF-4]
摄像头/算法/DDR 发布的 has_frame（核心域）
  → [IF-3] display 内两级同步+视频帧首选择 → 原 RGB 或无帧彩条
  → 原有 74.25 MHz 双像素到 148.5 MHz TMDS 编码路径 → HDMI
```

- **MOD-P（Efinity 外围配置）**：按 v7 接回四 PLL 的端口及反馈，DDR3_PLL 提供 `clk_100m` 反馈但 DDR 控制器 `core_clk` 由 MIPI_TX_PLL 的 `core_clk` 供给；新增官方 v7 现成 LED 2–7 pin。IP 本体及相机配置不改。
- **MOD-T（板级顶层）**：移除第四锁定门控，接 DDR 核心时钟，映射诊断灯；保留现有编码器、色通路和原 D0/D1 行为。
- **MOD-D（显示模块）**：只在视频域新增无帧彩条选择，现有扫描、DDR 请求、像素 FIFO 与 `rgb_vs/rgb_hs/rgb_de` 时序不改。
- **MOD-S（约束）**：使 `core_clk=100 MHz` 与 PLL 输出端口匹配；`clk_100m` 保留为 DDR3_PLL 反馈端口，不能照抄旧 v0.3 提议将其从 SDC 删除；视频及 DDR I/O 原有细约束保持。
- **组合检查**：官方 v7 的 DDR3_PLL `clk_100m` 反馈输出与顶层同名端口相接，避免删去 pll_inst4 的同名输出后留下悬空时钟；DDR 控制器的 `axi_clk` 与 `core_clk` 最终同源；`has_frame` 只作为单比特慢变状态跨域，RGB 多位数据仍通过原异步 FIFO。LED 2–7 的板端 IO/电压与官方 v7 逐项相同。没有新的资源反馈环或阻塞路径。

## D. 接口卡与交接检查

| IF | 提供→使用；类型/域 | 前提与保证；复位/失效 |
|---|---|---|
| IF-1 | `CLK_25M`→MIPI_TX_PLL/DDR3_PLL/pll_inst4；`CLK_27M`→USER_PLL。输出 `core_clk` 100 MHz、视频 74.25/148.5 MHz、DDR 物理时钟及 `clk_100m` DDR 反馈，均 1-bit 时钟。 | 采用官方 v7 相同反馈、分频和端口名字；Efinity periphery 生成后，顶层端口与 `.peri.xml`/SDC 清单一致。实际频率以生成/STA 报告核对。 |
| IF-2 | PLL locked/i_arstn→顶层 `w_arstn`、`vid_rst_n`，均 1-bit 高有效。 | `w_arstn` 由 MIPI_TX、DDR3、USER 三路锁定决定；原延迟计数到终值才释放 `vid_rst_n`。第四 PLL 不再额外门控所有系统复位。任一必要锁定掉落时按原异步复位路径重新启动。 |
| IF-3 | 核心域 `has_frame`→视频域 `show_frame`；1-bit；`rgb_pair[47:0]` 为两个 RGB888 像素，低 24 位为左像素；`rgb_de/hs/vs` 保持原扫描时序。 | `has_frame` 经两级触发器同步，视频帧首把同步值锁入 `show_frame`；`show_frame=0` 且 active 时按 `scan_x` 输出八色彩条；为 1 时用原 FIFO 命中条件与像素。无 ready/反压，视频每个上升沿连续输出一对像素。 |
| IF-4 | 顶层状态→D2…D7，1-bit 组合电平。 | D2=`i_arstn`，D3=`user_pll_locked`，D4=`i_pll_locked`，D5=`pll_locked`，D6=`vid_rst_n`，D7=`w_arstn`；D0/D1 不变。独立于视频像素有效性。 |

逐连接走查：上电三个锁定后 IF-2 使视频退出复位，IF-3 无帧时扫描连续输出彩条，IF-4 全部应亮；即便 DDR `cal_done=0`，只要 DDR PLL 已锁且视频复位释放，彩条不需访存。若 USER_PLL 不锁，D3/D7/D6 不亮且显示器无信号，先查时钟；若 D2–D7 亮且仍无信号，转向 TMDS 引脚/编码器链；若有信号但无相机画面，进入另一个任务查帧发布。

## E. 局部中文操作草图

1. **PLL/顶层**：读取 B02 外围配置，与 v7 同名实例逐字段比较，只修改上文列出的反馈、端口和分频：MIPI_TX_PLL `core_clk` 分频回 20，反馈也是 `core_clk`；pll_inst4 只保留相机/5 MHz 输出，不再导出 `clk_100m`/锁定/复位；DDR3_PLL 反馈输出恢复名为 `clk_100m`。顶层去掉 pll_inst4 锁定及复位端口，`w_arstn` 用三路锁定，DDR 核心时钟接 `core_clk`。灯组合直连，不能借用算法状态推断锁定。
2. **显示**：`safe_reset_n=0` 时两级同步寄存器和 `show_frame` 清零，已有扫描计数/输出按原逻辑复位。每个视频时钟上升沿，以旧的 `has_frame_meta` 更新同步末级；只在当前旧 `h=0,v=0` 的帧首，以旧的同步末级更新 `show_frame`。在每个有效区拍，用本帧锁定的 `show_frame` 选择：0 为按水平坐标分成八段的 RGB888 彩条，两像素颜色一致；1 为原 `fifo_valid && matching` 命中像素，否则原黑像素。`rgb_vs/hs/de` 保持原寄存器更新表达与边界。下游在下一上升沿采样前一上升沿更新后的 RGB/同步信号。
3. **约束**：`core_clk` 由 11 ns 改为 10 ns；`clk_100m` 仍约束 10 ns，但它的来源改为 DDR3_PLL 反馈；核心与 DDR 物理时钟按 IP 的异步 CDC 关系分组，不给未核实数据路径加宽松例外。原 HDMI TMDS 时序约束保留并复查解析。

局部不变量：`show_frame` 整个显示帧保持不变；0..1919 的八段各 240 像素，边界正好落在双像素拍；彩条选择不额外发起 DDR 请求或改变既有 FIFO 读写条件；PLL/时钟端口在 periphery、顶层和 SDC 三处一致。正常例：无已发布帧、三锁定都为 1 → 先出现彩条且 D3–D7 亮。边界例：`has_frame` 在一帧中途从 0 到 1 → 此帧完整彩条，下一帧起可输出旧数据通路；若视频 FIFO 暂无匹配数据，保持有信号的黑像素。

## F. RTL 与映射契约

- **语言/工具**：顶层 Verilog 2001；显示模块 SystemVerilog；Ti60F225/I3、现有 Efinity 项目及 IP 版本。C++ 与软件数值参考无本任务变更，跨语言映射 N/A。
- **数值/身份**：RGB 固定 8-bit unsigned/通道，无算术溢出；水平坐标由原 11-bit `scan_x` 表达偶数像素，八段边界 0/240/…/1680/1920。每个双像素拍只输出当前帧的一对像素；无压缩或重排。
- **时钟/CDC/复位**：`has_frame` 核心域→两级同步→视频域帧首锁存；不直接跨域使用多位颜色/坐标。异步低有效 `safe_reset_n` 清同步和扫描状态，同域释放后正常运行；PLL locked 作为现有复位条件，保持 reset_ctrl 原行为。
- **流控/缓冲**：HDMI 不可反压，始终按扫描推进；无帧彩条只占组合逻辑及少量 FF，不加 BRAM/DSP；DDR/FIFO 原有握手、满空、结果时序均不改变。`has_frame=1` 但 FIFO 无匹配时输出黑像素而不停止同步。
- **时序预算**：100 MHz core、74.25 MHz 双像素、148.5 MHz encoder 与现有 TMDS 快钟。B02 在 11 ns core 下有正裕量，但 10 ns 与本次外围重生成后必须以新 STA 为准；若 setup/hold 为负，不能把失败版本称为可上板。

## G. 获批后实施与验证计划

1. 核对上表哈希；在 `work/active/track4_video_restore_001_20261015/` 建独立副本（源代码、IP/工程输入；不覆盖 B02/官方）。若源哈希变化，停下更新基线。
2. 改 `track4_board.peri.xml`、`rtl/ti60f225_oob_top.v`、`track4_board.sdc`、`board/rtl/board_frame_display.sv`；项目 XML 仅在外围端口生成确有需要时作同范围适配，不引入新 IP。
3. 检查 diff、端口/pin、SDC 解析；运行 Efinity map、interface、PnR、STA、pgm。仅若必要检查通过生成 bit 并登记到 `artifacts/staging/`。日志和哈希进本地追加审计；正式 DB/PROJECT_STATE 不动。
4. 到 `WAITING_HUMAN_PROGRAM` 停止；由用户下载、观察并反馈 HDMI 是否识别 1080p60、五分钟内有无掉线、D0–D7 状态，以及是否出现彩条或原图。观察失败按灯态定位下一项，不盲改曝光/识别算法。

| TEST | 要求/接口 | 场景与通过标准 | 当前 |
|---|---|---|---|
| VR-T1 | VR-1/IF-1/IF-2 | 配置/顶层/SDC 的 PLL 输出和复位端口一致；与 v7 的目标频率吻合；无悬空 `clk_100m`。 | 未运行 |
| VR-T2 | VR-3/IF-4 | pinout LED 2–7 与官方 v7 GPIO、电压逐项一致，D0/D1 不变；状态映射查源码。 | 未运行 |
| VR-T3 | VR-2/IF-3 | 静态审查帧首同步/八段边界、无帧不访存新增路径；现有仿真能力可用时做局部仿真，不为此次生成新 testbench。 | 未运行 |
| VR-T4 | VR-1/VR-2 | 综合、布局布线、时序无失败，所有预期时钟有约束，bit 与输入哈希登记。 | 未运行 |
| VR-T5 | VR-1/VR-2/VR-3 | 用户下载后 HDMI 稳定有信号 ≥5 分钟，观察彩条/原图与 D2–D7；若核心 PLL/DDR 未锁，按灯态判诊断而非判摄像头失败。 | 等人工 |

## H. 双向追踪与评审门槛

| REQ→MOD | IF/草图 | 拟改文件 | TEST | 反向必要性 |
|---|---|---|---|---|
| VR-1→MOD-P/T/S | IF-1/2，PLL/顶层/约束 | `.peri.xml`、顶层、`.sdc` | T1/T4/T5 | 每个 PLL/时钟/SDC 改动仅服务于恢复官方稳定启动 |
| VR-2→MOD-D | IF-3，视频域帧首选择 | `board_frame_display.sv` | T3/T4/T5 | 同步/选择寄存器只服务于无帧可见的 HDMI 验收 |
| VR-3→MOD-P/T | IF-4，诊断灯 | `.peri.xml`、顶层 | T2/T4/T5 | 六根灯线只服务于定位启动状态 |

自检 ①行为/边界/样例：B、E；②职责/复用：C；③端口与组合：D；④状态/不变量/中文草图：E；⑤RTL/映射：F；⑥端到端与覆盖：D、E；⑦实施/验证/追踪：G、H；⑧本范围无未决技术阻塞：A；⑨已保存并读回，呈现位置为本文；⑩版本、范围和 B02 哈希：A。**状态 READY_FOR_REVIEW，并非获批或已测试。**

批准后只执行本版 VR-1..3。若上板已显示有信号但仍不见相机内容，另立摄像头帧发布与色彩校正设计；不把这两类结果写成本版失败或成功的替代证据。用户若要求改变本版接口、复位策略或排查范围，先修订版本再实现。

## I. 批准实录（2026-10-15，批准后追加；不改变 v1 技术设计）

- 本文获批前 SHA256：`573B57C2FE487AB700FB524FB28B51B31B5B7B91A8AEDE260848A8FFAB325099`。
- 用户在呈现本设计及范围、本地审计例外的提问后回复原文：“批准”。按上下文明确指向 `TRACK4-VIDEO-RESTORE-001 v1`、B02 基线、VR-1..3、独立副本修改及 Efinity 构建/bit 登记，并允许本次本地追加审计；不含自动硬件下载。
- 源码输入清单：`../reports/TRACK4-VIDEO-RESTORE-001/baseline-b02-inputs.sha256`，199 项，清单 SHA256 `9E3C1B5A919B53B55F8498A867E191CDAEB78595BB12E3BB2D5E5BE55F3E4009`。实施前已核对本版明确列出的五个关键文件哈希相同。
- 状态：`APPROVED_FOR_IMPLEMENTATION`，限本版范围；本地审计例外只覆盖此独立软件修复及其构建登记，正式数据库与硬件节点状态不改。

## J. v1 实施及软件验证实录（批准后追加；不改变设计范围）

- 在独立工作副本 `work/active/track4_video_restore_001_20261015/` 完成四份构建输入修改；与 B02 的 199 份输入清单逐一复核，只有设计指定的四份不同，未发现遗漏。
- VR-T1：外围端口、顶层和 SDC 匹配；最终 STA 列出 `core_clk` 100 MHz、视频 74.25/148.5 MHz 和 DDR 400 MHz。PASS。
- VR-T2：Efinity pinout 列出 D2–D7 与官方 v7 对应的 GPIO/1.8 V，D0/D1 保留原映射；顶层赋值逐一核对。PASS。
- VR-T3：源码静态走查两级 `has_frame` 同步、视频帧首锁存、八段彩条与原 FIFO 命中条件；本批未运行仿真。静态检查 PASS，动态仿真未运行。
- VR-T4：Efinity 2026.1.132 Ti60F225/I3 的 map、interface、PnR、pgm 均 PASS；STA 最差 setup +0.257 ns、hold +0.029 ns，100 MHz 核心 setup +1.331 ns。资源 XLR 44,343/60,800，RAM 163/256，DSP 8/160。bit SHA256 `D13B8719D5DDD7CD78697AAFC3DEA635A5BC4ED3D9BBF991C6FF62E78D27B8DE`，已登记于 `artifacts/staging/TRACK4-VIDEO-RESTORE-001-V1/`。PASS。
- VR-T5：等待用户进行实物临时下载和 ≥5 分钟观察。当前仅为上板候选，不能把软件 PASS 写成视频/相机实物 PASS。
- 证据：`reports/TRACK4-VIDEO-RESTORE-001/实施与首测说明.md`、`build-01-inputs.sha256`、`build-01-console.log`、最终 timing/pinout/place 报告及 staging `artifact-manifest.json`。节点停在 `WAITING_HUMAN_PROGRAM`；正式 PostgreSQL 与项目硬件状态均未修改。
