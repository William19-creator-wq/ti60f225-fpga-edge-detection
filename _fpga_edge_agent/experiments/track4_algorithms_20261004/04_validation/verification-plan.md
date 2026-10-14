# 算法验证与工具证据路线

权威R1用例是[R1 G](../../../planning/design-TRACK4-ALGORITHM-R1-001.md)和[FRONTEND G](../../../planning/design-TRACK4-FRONTEND-001.md)的FT-01…11。本页是状态/后续范围，不生成可执行测试。

| 批次/证据 | 判定方法 | 当前 |
|---|---|---|
| R1数值 | 独立整图式/普通排序/直接邻域，与每job每lane每坐标逐位比较；四个完整1080p job | PASS：frontend_suite_006，123/123，四job合8,294,400像素、错误0 |
| R1时间 | 气泡/反压/动态外部配置/取消/复位、RAM同址/旧pending/尾部/真实计数 | PASS：完整006含九phase/恢复/STATUS全空；已有WLF读回与T41补验分别保存 |
| R1外壳 | 4种图样/4阈值/kind/median、160bit records/独立CRC、末status、新job与cold reset | COMPLETE：r1_shell_005，两尺寸各69job/64配置、四258图样及typed/CRC通过；三故意fatal退出3 |
| R1工具 | Questa真实终止/计数；生产map/PT/PNR、真实四pin/40ns/全内部STA、告警、bit/hash/staging | PASS：r1_physical_005，3411 XLR/8RAM/0DSP，setup35.381ns/hold0.063ns；真实bitgen_retry_001与staging已登记 |
| R2流段 | 单次Gaussian舍入、新梯度/424方向、NMS相等/外框原幅值、双阈值/中心/fork | NOT_DESIGNED_FOR_IMPLEMENTATION |
| R2显示控制 | 原RGB/edge身份及保持/覆盖优先级、消抖/饱和/配置提交 | NOT_DESIGNED_FOR_IMPLEMENTATION |
| R3数值核 | 独立高精度整数/RNE、192bit根carry、ROM握手、typed拒绝/溢出/保持 | NOT_DESIGNED_FOR_IMPLEMENTATION |
| R4闭包 | 全尺寸长链/斜连接/环/分支/孤立弱边/负例与精确oracle；容量/原子性/终止 | NOT_DESIGNED_FOR_IMPLEMENTATION |
| R4识别 | 全点/同心重叠/旋转/缺边与负例；固定开发集和独立验收集/逐类P/R和IoU匹配 | NOT_DESIGNED_FOR_IMPLEMENTATION |
| R5集成优化 | 同输入比较面积/实际处理/等待/质量/100MHz STA及完整软件功能组合 | NOT_RUN |

主机全图模型不证明Ti60片上可装下工作数据；小尺寸RTL通过不替代全尺寸/资源/时序。protected IP缺失、许可失败、日志缺失、超时或未运行均不能记0/PASS。

R1各原始结果、实际阅读范围和产物SHA见[本批中文验收](../05_delivery/r1-software-acceptance-v1.1.md)。FE005状态元数据失败、物理001…004失败及首次Bit退出0但跳过生成均保留，正式验收只采用最终006/005/005与独立真实生成重试。R1软件通过不升级正式硬件状态，也不覆盖上表后续批次。

随机种子、向量格式/manifest与观察时刻沿原FE F/G。每run有design/source/input/tool/command/hash和明确退出结果；数值/协议检查不能只找PASS字符串。必要测试通过后不无理由重复扩测。
