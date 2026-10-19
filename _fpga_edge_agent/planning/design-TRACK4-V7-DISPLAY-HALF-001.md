# TRACK4-V7-DISPLAY-HALF-001 设计卡

- 任务 ID / 关联节点：TRACK4-V7-DISPLAY-HALF-001；H1/H2/H3/A1/A2 依赖
- 设计版本：v1；2026-10-18
- 当前阶段：APPROVED_FOR_IMPLEMENTATION（依据用户本轮“缩小为原来的二分之一”并选择“显示为居中 960×540”）
- 目标范围：保持 HDMI 总时序为 1920×1080，实时画面显示为居中 960×540，四周黑边；保留当前算法按键、白平衡和实时链路。
- 非目标：不改变相机视野、镜头焦距、白平衡、帧率目标；不修改原始资料；不自动下载或烧录。
- 基线：`work/active/track4_v7_algorithm_control_001_20261018`；当前源码事实：HACT/VACT=1920/1080，frame_buffer O_FRAME_WIDTH=960 是 16 位打包字数，cvo PIXEL_NUM=2；当前无 zoom/scale/crop 参数。
- 用户授权：本轮明确选择“显示为居中 960×540（推荐）”；沿用此前“无需我的批准，按你的见解写代码测试”的实现授权及本地审计例外。

## A. 整体外部行为

- REQ-DH-01：输出 TMDS 仍使用 1920×1080 总时序，避免显示器重新识别模式。
- REQ-DH-02：有效图像占 960×540，居中于 1920×1080；左/右各 480 像素黑边，上/下各 270 行黑边。
- REQ-DH-03：图像取原相机帧的 2 倍抽取（最近邻），不插值，不拉伸；源 1920×1080 映射到 960×540。
- REQ-DH-04：输入、帧同步、算法按键和复位保持连续工作；无源帧时输出黑色有效区。
- REQ-DH-05：未通过仿真、综合、布局布线和时序检查前，不登记可下载 bit；通过后进入 WAITING_HUMAN_PROGRAM，由用户手动下载并观察。

正常样例：源帧左上像素映射到输出坐标 (480,270)，源 (1918,1078) 映射到 (1439,809)，其余 active 坐标为黑。
边界样例：源行/帧尚未准备好时不读未初始化 DDR，输出黑色并保持 HDMI 同步。

## B. 模块与接口

```text
MIPI -> raw_half_decimator -> frame_buffer/DDR -> cvo_axi -> HDMI
algorithm path remains on the camera RGB stream and feeds its existing display result
```

- IF-DH-01：raw_half_decimator 到 frame_buffer，16-bit 两像素打包、每行 480 words、`i_vs/i_de` 保持帧/有效数据语义。
- IF-DH-02：frame_buffer 到 cvo_axi，仍为 16-bit、每行 480 words、每帧 540 行；黑边由 cvo 的 960×540 active timing 产生，HDMI 总时序不改变。
- IF-DH-03：配置静态采样，生效于 bitstream 配置；无运行时可变缩放寄存器。

实现选择：在 MIPI 写 DDR 前做 2×最近邻 decimation，保留偶数源行，并从每个 32-bit 输入拍输出 P0/P2 两个像素。这样 frame_buffer 的输入为 16-bit、每行 480 words、共 540 行；cvo 保持 HDMI 2200×1125 总时序，active 设为 960×540，从而形成居中黑边。

## C. RTL 契约与组合检查

- 16-bit word 中的两字节顺序沿用现有 cvo 输入顺序，保证颜色通道身份不变。
- 黑边 words 为零值；`tlast` 只在每个 480-word 输出行末产生；`tuser` 只在帧首行首 word 产生。
- 复位清空控制状态，禁止在首个完整 DDR 帧可读前发布旧行；无反压时每个 HDMI active 行连续交付 480 words。
- 组合检查：2200×1125 HDMI timing 与 480-word AXIS 行长度相容；算法桥接按 960×540 坐标工作，显示 active 区域与该尺寸一致，避免改变算法窗口尺寸。

## D. 验证计划

1. 静态：检查源/目标 word 数、黑边坐标、tlast/tuser、帧/行计数和复位。
2. 仿真：合成带编号测试帧，验证四边黑边、(480,270) 和 (1439,809) 映射、无错行/重复行；验证至少 3 帧连续输出。
3. Efinity：map、place/route、timing；记录资源、setup/hold、CDC/异步输入告警。
4. 产物：bit SHA256、日志、manifest、报告；状态停在 WAITING_HUMAN_PROGRAM。
5. 实机：只由用户手动下载，观察是否保持 1920×1080 识别、画面居中 960×540、实时变化和无错行。

## E. 风险、回滚和停止条件

- 风险：现有 frame_buffer/DDR 读取器是顺序帧流，无法无代价地随机行采样；若验证显示为截断、停帧或错行，立即回滚到 v7_algorithm_control_001 基线。
- 回滚：不修改基线目录；删除/弃用本任务副本和 staging 产物即可。
- 停止条件：DDR 行地址无法可靠重排、仿真出现未初始化读、Efinity 时序失败、产物哈希变化或需要自动下载时停止并记录。

## 双向追踪

- REQ-DH-01 -> `ti60f225_oob_top.v` HFP/HSP/HBP/VFP/VSP/VBP 与 cvo timing。
- REQ-DH-02/03 -> `raw_half_decimator.v`、frame_buffer 的 480×540 计数及 cvo 的 960×540 active timing。
- REQ-DH-04 -> 现有 frame_buffer、cvo、算法桥接和 reset 连接。
- REQ-DH-05 -> `checks.json`、`delivery.json`、artifact manifest、硬件闸门记录。

### 当前事实与未知

- 已知：当前 top 的 HDMI 总时序为 2200×1125，active 参数 960×540；frame_buffer 每行 480 个 16-bit words；cvo 每 word 2 pixels。
- 已知：当前 v7 algorithm path 没有 zoom/crop 参数。
- 已解决：不依赖 DDR 随机行地址，在 MIPI 写入前完成固定 2:1 抽取。

## 2026-10-18 实现与构建记录

实现采用 `rtl/raw_half_decimator.v`，在 MIPI 写 DDR 前对已验证的 1920×1080 RAW10 字节流进行 2:1 最近邻抽取：保留偶数源行，并在每个 32-bit 输入字中保留偶数输入字的 P0/P2 两个像素，输出每行 480 个 16-bit words（960 像素），共 540 行。HDMI 总时序保持 2200×1125，active 区域为 960×540，时序参数产生左右各 480 像素、上下各 270 行的黑边。算法桥接同步使用 960×540 坐标。

2026-10-18 在纯 ASCII 路径 `C:/Users/34528/FPGAEdgeLinks/track4_v7_display_half_001_20261018` 完成 Efinity 2026.1.132 构建：map PASS、interface PASS、PNR PASS、pgm bitstream PASS。时序报告最小 setup slack 0.410 ns，最小 hold slack 0.027 ns。产物登记于 `artifacts/staging/TRACK4-V7-DISPLAY-HALF-001`，状态为 WAITING_HUMAN_PROGRAM；未执行硬件下载。

中间版本 SHA256：`EB9925BD439393EBA132449C94607352EB4FE9328B0E93514D447BA396E1271D`；最终 half3 bit SHA256 见下方更正。

### 实现更正

基线 MIPI 接收每行是 480 个 32-bit 输入拍，每拍含四个 8-bit 像素分量；因此水平 2:1 的正确做法是每拍输出一个 16-bit `{P0,P2}`，只丢弃奇数源行，不再丢弃奇数输入拍。前一轮生成的中间 bit 未下载、已被本次构建覆盖。

当前最终 bit SHA256：`E36CE92C7FB770355C34CF6F817E9F75E91919F190EA8061EF530AEEF00C44E2`。

最终 half3 时序报告的最小 setup slack 为 0.410 ns，最小 hold slack 为 0.027 ns。




