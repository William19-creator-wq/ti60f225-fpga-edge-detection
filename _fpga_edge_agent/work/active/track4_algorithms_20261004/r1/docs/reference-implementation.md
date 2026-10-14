# R1 独立数学参考与向量交接

版本：R1 v1.1 已批范围；本记录日期 2026-10-05。实现只位于 `model/frontend_reference.py`、`model/r1_pattern_crc_reference.py`。数值参考不读取 RTL，不复制 RTL 排序网络、RAM 时序或状态机；协议事件交给测试台在实际握手上执行。

## 1. 先整体，再局部

```text
有限 RGB 图（二维坐标）
  └─灰度公式 → 完整 Y 图
      └─二维夹紧邻域 + 普通排序 → 完整 M 图
          └─再次从 M 夹紧邻域 → gx、gy、L1、edge
              ├─固定宽度 hex 文件 → FT-01…11 manifest → 五类前端 TB
              └─R1 图样 / k 配置 → FO/FS 160 bit record
                  └─独立逐 bit CRC → running CRC 文件 → 三类 R1 TB
```

局部之间传递新列表和不可变 RGB 元组。Median bypass 也返回新列表，避免下游修改污染输入。灰度、Median、Sobel 的纯函数不写文件；`SuiteWriter` / CLI 单独负责文件和证据管理。维度要求偶数 W=4…1920、H=3…1080；像素数量必须恰好为 W×H，字段越界、bool 伪装整数、非法 kind、阈值或坐标均拒绝。

## 2. 局部数学与边界

灰度为 `(77R+150G+29B+128)//256`。Median 从九个夹紧到画面边界的样本普通排序，取第五个；Sobel 使用 **M 图自己的第二次夹紧边界**，`gx=(c+2f+i)-(a+2d+g)`、`gy=(g+2h+i)-(a+2b+c)`、`L1=abs(gx)+abs(gy)`，判边为严格 `L1>T`。Y_ONLY 的 edge 全零，M 不变。该实现先构建完整二维结果，再打包，独立于硬件行流水顺序。

R1 的 k 选择 median=k[0]、kind=k[1]、pattern=k[3:2]、T=(0,64,512,1530)[k[5:4]]，身份为 epoch=1、frame_id=config_id=k。四个图样是坐标 RGB、垂直半幅、水平半幅、bit5 checker。每个 FO record 为高 21 个零位加 `{eof,eol,sof,config_id,frame_id,epoch,y,x_even,edge,M}`；FS record 为高 19 个零位加 `{config_id,frame_id,epoch,out_pairs,in_pairs,code}`。诊断 error_x/y 不属于 FS CRC 摘要。

CRC 从 FFFFFFFF 开始，每个 record 按 bit159→0 输入，使用多项式 04C11DB7 左移递推，最终 xor FFFFFFFF。另一个自检用逐 byte 多项式长除法，对同一完整 record 序列交叉检查。二者只表达数学，不模拟 observer 的 160 个时钟；每条硬件 record 的 running CRC 由文件提供。

## 3. 固定文件合同和 manifest

| TB 类型 | 输入有效位 / 每行 hex | 黄金有效位 / 每行 hex |
|---|---:|---:|
| rgb | RGB48 / 12 | Y16 / 4 |
| median | 两个九邻域 FW144 / 36 | M16 / 4 |
| sobel | FW144 / 36 | M16+edge2+gx22+gy22+L1pair22=84 / 21 |
| window | Y16 / 4 | FW144 / 36 |
| frontend | RGB48 / 12 | M16+edge2=18 / 5，高两位必须为零 |
| R1 observer | record160 / 40 | running CRC32 / 8 |

每个文件逐行小写 hex、无前缀、精确位宽、无 X/Z；FW 的 lane0 低 72 bit，各邻域 a…i 从低位到高位排列。输入/黄金都完整保存。负例中可比较的是真实交付的数值前缀，不能把完整黄金行数误当错误 job 的交付数。

FE schema_version=1 manifest 为每个 case 保存安全唯一 case_id、TB 类型、W/H、配置/身份、输入/黄金相对文件名、位宽、完整行数、SHA256、scenario、必要 follow_up。`events` 指定输入/输出下标、accepted/before/fire 或真实 phase；TB 必须观测对应实际状态，不能只根据标签宣称覆盖。FT-08 配置锁定、取消/错误后的恢复包含完整独立 follow_up 图与新身份。Reset 复跑同一完整输入/黄金，不给旧 job 伪造终端。

生成开始立即写 INCOMPLETE manifest；只有重新检查所有文件的安全路径、精确格式、有效高位、EOF 行数、hash、全部 FT-01…11 和四个完整 1080p 配置组合后，才写 COMPLETE。运行目录必须新建，不覆盖旧目录。ASCII junction 调用会先 resolve 到实际路径，再检查工作根边界与 source evidence；该处理不放宽可写范围。

## 4. 操作草图与完整固定场景

先读取批准设计/manifest → 用新 RunId 生成全部向量 → 检查 COMPLETE 与计数/hash → TB 按 manifest 逐项运行 → 用实际 fire/held/状态和黄金文件比较 → 保存 JSON、日志、WLF → 汇总。参考模型不向 RTL 提供期望成功脉冲。

| 场景 | 独立向量 / TB 所需行为 |
|---|---|
| FT-01 | 手算颜色、灰阶、固定随机 RGB；numeric seed=0x431 |
| FT-02 | 全 512 个二值九邻域、重复值、随机邻域；median 与 bypass |
| FT-03 | Sobel 方向、镜像、L1±1 阈值、0/2047 字域 |
| FT-04 | W4/H3、W8/H3、W10/H5 夹紧窗口与行交接 |
| FT-05 | input bubble、output stall、真实 RAM 返回/邻行检查 |
| FT-06 | 双边界 Median→Sobel 与 bypass 完整小图 |
| FT-07 | 各位置 bubble/stall、独立协议 LFSR 随机流控 |
| FT-08 | 活动 job 配置扰动，下一 job 无 reset 完整采用新配置 |
| FT-09 | bad/坐标/marker/多错误优先级/非法 kind，合法新 job 恢复 |
| FT-10 | 输入接受后、输出 fire/held、F1/两窗口 fill/replay/tail/median/sobel 的取消与 reset，状态 late cancel |
| FT-11 | 四个完整 1920×1080 job，m0Y/m1Y/m0Sobel/m1Sobel，各 1,036,800 pairs |

椒盐固定 seed=0x1060，在128背景上每像素概率0.0025黑、0.0025白。协议随机流控由 TB 使用独立 LFSR 和每八沿强制机会，不能复用数值随机数组替代实际停顿。

## 5. 已实测的参考证据

实际 Python：`D:\py___\python.exe`，3.14.6，使用 `-B`，不安装依赖。手算 RGB 黑/白/红/绿/蓝为0/255/77/149/29；全256灰阶核对；512二值窗口的最大 L1=1530。W4/H3 梯度 Median 为 `[1,2,3,3,10,11,12,13,20,20,21,22]`，四角第二边界 L1 都为40，bypass 为44。九种非法参数被拒绝，bypass 无别名。CRC 双算法的空/零 record/六 record/逆序为00000000、b1d9abf0、0e17263f、8b30e5ee；64种 k 配置组合完整。

实路径参考运行 `model/runs/reference-20261005-02/vectors/manifest.json` 已 exit0、COMPLETE：123 cases、306 files、8,322,536 hex lines、4 production jobs、8,294,400 expected pixels。manifest SHA256：`BF6B6E1ADACA5ADD2752694F0F7F3B61F68D2CA6E2480416115EAB28E8394F89`。该历史运行在路径 canonical 修复之前生成，保留原 source evidence；数值未修改，新 ASCII 路径运行由 FE runner 另留目录。

ASCII 调用的 `sim/r1/runs/r1_shell_002/r1-vectors/manifest.json` 已 exit0、COMPLETE：128个普通 job、1,792个完整 record、4个258×258图样合计133,128 pairs、8个组件场景合计46 records。manifest SHA256：`46B4E06A80685B7CEF0A3FC12A64C22108840636BD15EAE57A7FCAA67733B450`。W4/H3 k0/k63 final CRC=aafba670/b8675e5e；W8/H5 k0/k63=9cefc250/1e00dcd8。每个文件自己的完整 hash/计数均在 manifest，可核全部值。

路径修复后的 ASCII 调用也已完成全部参考生成：`sim/frontend/runs/frontend_suite_005/vectors/manifest.json` 为 COMPLETE，SHA256 `4F159E92A304DC118EC802B5BBD20D04D0E7B4388E87CBA342E3C90638AEF6DB`；123 cases / 306 files / 8,322,536 hex lines / 四完整1080p job。source_evidence 的两模型与该次生成的历史冻结源一致，当前元数据变更见下一段。该证据属于参考生成，五类前端 RTL 仿真的最终汇总由 FE runner 单独给出。

上述005参考生成时两源 SHA256：FE `35A50A891937D41A19E8FDE5AE970675411576E2EB77EC088F89C705A48CD4DA`；R1 `AED312302C8A5F7E961720D09C5F402C27A09D0A94AC08F0EA49102E18724208`。随后真实FT05检查发现window单元不产生F0状态，scenario默认0错误；只把该项status明确为NA，数值和RTL未改。当前FE SHA为 `4D81E977D1A8633B20497A1BA5A6E664D63E5730652380684B68BBB65D955D7A`；旧005与历史证据保留，新006完整FE参考/仿真由其runner另存。R1最终 `r1_shell_005` 已按此当前源新目录运行并冻结20项输入，详见验证报告。

本次随后实际读回当前源的 `sim/frontend/runs/frontend_suite_006/vectors/manifest.json`：COMPLETE，SHA256 `CCB3EA9ADFE953960F669BB2A4149AB285582765ED7201F2791EE3D822A9A38D`，123 cases / 306 files / 8,322,536 hex lines / 四完整1080p job；FT05 expected_status明确NA，FE source evidence为当前4D81E977…D955D7A。这里仅确认参考生成完成；006的实际RTL协议/数值仿真汇总仍由FE runner单独报告。

原厂 EFX_RAM10 hash 为 `DD8DB45116A67B9754920856DC380EB2DC73CA51E0A6A62CC74CDA01C0E31A33`，仅记录测试依赖，不参与数值黄金计算，也未修改。

## 6. 双向追踪与结论范围

FE v1 F1/G → `frontend_reference.py` 纯函数/文件生成/manifest验证 → FT-01…11；R1 v1 §C 图样、record、CRC → `r1_pattern_crc_reference.py` → 128 job 与四 source-only；R1 v1.1 继承22 baseline → 两模块与本报告。scenario → FE TB 是协议交接；R1 files → 三 R1 TB 是记录/CRC交接，实际测试结果见 `r1-verification.md`。参考 COMPLETE 证明公式、完整向量和文件合同；RTL 数值、协议、综合、布局布线分别需要各自实际工具证据。
