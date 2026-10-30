# Ti60 DDR 帧缓存候选工程

更新时间：2026-10-29 18:15。独立候选；ReadAhead 源码和回退比特流未修改。

## 已接入的实现
- Efinity Catalog DDR3 Soft Controller 5.16，Ti60F225、DDR3 x16、256 MiB、400 MHz。保留官方配置和生成文件，顶层实际实例为 u_frame_ddr3。
- 64 个 2 MiB RAW8 帧槽（0x08000000–0x0fffffff），完整 1920×1080 帧经 EOF、尺寸和全部 B 响应检查后提交，最多保存 60 个历史帧。
- 冻结、实时恢复、固定片段按时间戳回放、暂停和逐帧选择已接入原始图像读取链路。选择前取得读取资格，读事务和预取数据排空后才换帧。
- A/B 复用原 Bayer 转彩色链路，2×2 平均为 960×540；缓存为 RGB32（高字节零），每张 2,073,600 字节。四个 2 MiB 槽位于 0x02000000–0x027fffff。两张写完后原子发布，逐行 A/B 读出，y=270..809 显示，上下黑边。准备期间显示 PREPARING。
- M5 快照以首个有效像素的 64 位源帧号和槽号标识。采集、预处理、跟踪和两个结果槽持有 RAW 源槽，防止历史淘汰后覆盖。冻结可直接选择当前结果对应的源槽。
- 冻结/暂停时，结果发布按源帧号和最新参数版本过滤；过时结果返回拒绝通知，工作器保留前台结果槽并复用后台槽。匹配的完整结果在帧边界替换。此处已有聚焦测试，尚无整机功能证据。

## 操作
模式键长按进入/退出菜单；短按选项目，+/- 修改。菜单 I0=滤波，I1=增强，I2=状态（P0实时、P1冻结、P2回放、P3暂停），I3=历史位置，I4=A选择，I5=B选择，I6=比较开关。历史位置以十六进制显示。菜单外仍是 M0–M5 和阈值。
回放自动显示原始彩色；暂停后可处理。比较时不启动新的 Canny 作业。新 OSD 标记为 B301，32 像素字距用于减少逻辑开销。

## 构建证据与限制
| 构建 | 实际结果 |
|---|---|
| catalog_build | 官方 DDR 控制器替换版，PNR/时序/bit 通过；不含历史/比较；未上板 |
| history_display_build | 历史帧顶层综合通过，243 RAM；后续功能已超出此源码 |
| comparison_build | A/B 顶层综合通过，253 RAM；PNR 因 62736 XLR > 60800 失败 |
| source_identity_fit_build | 关闭旧采样调试核并共享 OSD 后综合通过；PNR 报缺少必需的 jtag_inst1_TDI 接口连接 |
| reprocess_fit_build | 包含 M5 发布过滤及32像素 OSD 的综合在运行；仍是 JTAG 旁路修正前源码，不能直接作为当前源码的最终构建 |

当前源码已用 TDI→TDO 保留未使用的 JTAG 用户链连接；需在新的构建目录重综合。旧增益/伽马 VIO 原本不控制图像，已停用旧采样调试核；JTAG 配置下载独立。所有旧失败日志、源快照保留。

## 必要验证
通过的定向记录在 verification/frame_history：完整1080p采集和读写、帧占用环绕、回放/冻结选择、完整缩略图像素平均与DDR背压、双缩略图行序、比较成对发布和返回实时排空、源帧身份/混帧拒绝、锁定源帧的新参数结果发布。
- thumbnail-capture.log
- comparison-read-corrected-model.log（首轮测试模型未清掉已握手末拍，失败日志也保留）
- comparison-control.log（对应新增直接冻结端口之前的控制器版本）
- source-identity-with-model.log（首轮缺 DSP 仿真模型的失败保留）
- playback-direct-freeze.log
- locked-result-publication-fixed-test.log（首轮测试任务使用保留字的编译错误保留）

尚未通过：最新源码的完整构建、布局资源/时序、官方 DDR 实板低/高地址测试、M0–M5及三项帧功能的实板观察、吞吐和稳定性。完整错误计数的 OSD 展示、回放时长展示仍需补齐。不能以组件测试或旧比特流证明整机通过。

## 回退与交付边界
只进行 DDR 易失存储和授权的 JTAG 临时下载，不固化 Flash。
ReadAhead 回退 bit SHA256：756fafaa7af677a6f8dbf9deeab9a30a0e4902c765b0011c6c25449410028562。
目前唯一新 bit 是控制器替换版（catalog_build），不是完整帧功能交付。当前任务未操作硬件。
生成/接线一次性脚本不能重跑；以 RTL 和检查点为准。尤其不要运行 record_progress.py、connect_compare.py、connect_compare_top.py、connect_canny_source_identity.py。
