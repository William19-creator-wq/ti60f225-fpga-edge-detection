# R5本地工具、器件与观察引脚证据 v0.1

2026-10-04。READ_ONLY_EVIDENCE；整包 NOT_READY / NOT_APPROVED；新工程仿真、PT、综合、PNR、STA及bit均NOT_RUN。本页为后续设计提供实际资料，不是环境全项验收或生产视频通过证明。

## 1. 范围、来源与读取方法

本轮根Agent实际读取当前devicemap的Ti60F225行、完整225球封装表/时序模型、efx_run.bat、既有板引脚证据、Questa检查报告/清单和LOCAL_TOOL_PATHS；实际读取map/pnr文件VersionInfo并重算六个Questa二进制SHA。独立只读审查者 `/root/canny_state_cache_detail/dp_join_check` 另外核对工具路径目标、旧非DDR VF LED/HDMI参考。

当前工具根为 `C:/Users/34528/FPGAEdgeLinks/Efinity2026_1`。以下工具数据库路径均相对此根；工程报告路径相对控制面。原资料只读，本轮没有启动工具程序、执行许可证探测或读取/打印许可证正文。

| 实际来源 | SHA256 | 能支持的事实 |
| --- | --- | --- |
| pt/db/devicemap.csv | 1568427EBD8839D5A35F44DFCC332CD37F9831FEC3EC515610A126EA427E8AD9 | 第49行Ti60F225对应opx_218x322_b16_d10_b225；ES/M另有行，不能混选 |
| pt/db/package/opx_218x322_b16_d10_b225.xml | E58A269F05807655F58FC3AE9DE6F96C0E544E075436E93F5C5EC2322CE2A6BD | 225-ball FBGA、Final；四球号映射实际存在 |
| pt/db/timing_models/opx_218x322_b16_d10_b225.xml | D7779F14DC8F4E9047C28D85A6A911029A1676128D5DD94ED8D7AED5A0A22587 | I3为final、0.95V且不是default；必须显式选择I3，不沿用默认C4 |
| bin/efx_run.bat | 46CCF2D36DB0FB6CAA50778E69E11391687DEB5B5BDA079B6541482853A1BE1A | 调用随附Python及scripts/efx_run.py，保留返回码；不等CLI已运行成功 |
| [LOCAL_TOOL_PATHS](../../../tools/LOCAL_TOOL_PATHS.json) | 46764CF7FF64ECAACF869960527A7785327B5217F2A08FEB0203C608EC14382E | 既有本地工具路径配置，本轮未改配置 |
| [板引脚来源v2](../../track4_full_sw_20261004/01_baseline/board-pin-source-evidence-v2.md) | 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F | 先前原理图/封装核对记录；本轮只采用与本任务相关的时钟、KEY和LED部分 |
| [硬件工具证据](../../../docs/requirements/HARDWARE_AND_TOOLCHAIN_EVIDENCE.md) | BBAB7A4F14360CD7452272ED801A21E4ECD318BFED490FAB7FF454979B73C0C9 | 已有摄像头、模组/转接板、CSI/HDMI来源入口；不证明新生产工程 |

工具bin/efx_map.exe和efx_pnr.exe当前文件VersionInfo均为2026.1.132。版本信息读取与运行 `--version` 是不同证据，本轮仅前者。

## 2. 四引脚独立观察候选

| 端口 | 球号／工具pad | 候选电气及来源 |
| --- | --- | --- |
| clk_25m | J2／GPIOL_P_08_CLK1_P | bank1A，板网1.8V，单端LVCMOS GCLK，40ns输入时钟 |
| key1_n | P13／GPIOR_27 | BR，3.3V输入，板记录10K上拉、按下低；输入进入既定同步/复位路径 |
| led0 | N14／GPIOR_21 | BR，3.3V输出，静态观察规则按R1/OBS |
| led1 | P14／GPIOR_22 | BR，3.3V输出，静态观察规则按R1/OBS |

球号/pad来自本輪直接读封装表；电压、板网和按键电路含义来自上述既有来源记录。板原理图文件SHA为 `855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F`。本轮没有重新逐页读取PDF，未把来源记录中的旧任务调查扩展为本任务所排除器件的调查。

R1/OBS已设计25MHz/40ns候选、KEY同步/复位释放与LED观察约束。新的peri、SDC和工程仍未生成，PT合法性、同步路径STA以及pin绑定报告都待获批后实际验证。四引脚能支撑独立观察工程，不能证明完整图像输入、全Canny、识别、视频吞吐或生产摄像头/HDMI连接已实现。

## 3. Questa较新历史实录与当前二进制

实际读取[2026-10-03检查报告](../../../reports/audit/questa_check_20261003/QUESTA_CHECK_REPORT.md)，SHA `D3F094DC430DC1073EBB36F7576710A05E0491DE393D177F28D49839642FEECD`；[检查清单](../../../reports/audit/questa_check_20261003/CHECK_MANIFEST.json)，SHA `872D8CE65B8E159233F0E2E6AAC6C99E76DB1B2758645BB7DD1E762A26A33449`。

报告记载Questa2024.1在ASCII路径、继承既有用户许可环境后，普通LED Verilog编译/展开/81ns仿真/WLF及VCD成功。直接Unicode路径曾失败，不能跳过路径处理。受保护FIFO样例源码编译通过，但旧TB与可选端口配置不匹配，展开失败且没有数据比较。整个环境当时仍未验收，不能仅引用9月旧许可失败断言当前普通仿真必然不可用，也不能把81ns LED结果扩大为新算法长时仿真成功。

本轮重算以下六个当前二进制SHA，全部与上述清单相等：

| 程序 | 当前SHA256 |
| --- | --- |
| vsim.exe | A893E1C83FF79961CD9FB72C6C1710A9CAAE9DAC65CEF4F79BC4C62BE312F362 |
| vlog.exe | 811964DA06AF9EEF280B9D1BC433082D5EB5515AF7541A6DEDED26475BA79297 |
| vlib.exe | 5896477CBEF1DBC150DEFAFC0D16D108B4D20A1C1F1982B31B2B9A9A511E012B |
| vmap.exe | 704FF5B2E82FAA210C3062635136A7DD2D07B6FFA62B68749A550C4E0B81794B |
| vsimk.exe | D0A646418474A5A5D737F0565F979A1A11E52636DDF09D9015DF58EBC1283EF6 |
| questasim.exe | DBE101C3AE95D173444BDB5B059760642A1E27A5A62BBC3EB261931F1E82A28C |

这里只证明文件仍一致；许可来源/授权未在该检查中核实，新算法许可取得、退出码、wave、完整判定和长期稳定性仍须在允许的正式验证中留证。本轮未改许可环境、未输出许可路径或内容、未运行仿真。

## 4. 旧非DDR参考的边界

独立只读审查者实际核对VF同名三级根下 `06-FPGA_HDL_Basic-2023.2`：

- `01_LED_8bit_Test/LED_8bit_Test.xml` SHA `A7E901F8FCA1ACF0C82BDE35356B0F9089E42553F2B4E69ED62687961D93795C`：Ti60F225/C4、Efinity2023.2.307.5.10。其VIP_System.sdc SHA `FAFF4C30833BF9EDC2B85BF6DA9D06F92F8E08981F28409B17FB93618C40EB67`，旧10.4167ns PLL时钟，IOdelay仅注释。
- `07_Ti60_HDMI_1080P_Lvds_Test/Ti60_HDMI_1080P_Test.xml` SHA `22F2C75D4B0146E9A7CBF4E1DD2DE5963BA07CC7B5EB76A73AACF93049074220`：C4/2023.1.150.3.11。peri SHA `798E5CDB19E9B21BC41716AC615612B2A62A51FBB5E8C18A39FC56853B9012E2`，四路10bit half-rate LVDS；SDC SHA `1B80A37EEC6663094ED964BCBFCED0B58ACF19A395F42AA87EE1C56A70CD3241`，旧150/750MHz。

以上是参考结构和旧结果来源。9月最小C4/VF LED构建成功、原XML历史pass均不能移作新I3/V4整包证据；旧serializer配置不能证明新148.5/742.5MHz的位序、极性、复位、CDC或STA。

## 5. 下一设计与验证顺序

1. 冻结真实可综合完整算法架构、全帧对象/后端、时钟域、接口及生产profile，分清赛题需求、软件验证条件与既有候选新增义务；不降低分辨率、精确闭包或识别质量目标。
2. 按实际工具版本冻结新工程文件、I3选择、peri/pin、电气、时钟及例外约束设计；生产摄像/显示/CDC与全机存储吞吐仍OPEN。
3. 形成独立数学/协议参考、完整输入与GT、case/timeout/退出码/波形/日志和产物判定设计，达到整包READY后提交统一版本、范围和基线。
4. 获准后再实际生成工作副本并执行编译、仿真、综合、PT、PNR、STA和bit，分别留真实覆盖证据；bit后按本次用户范围停止，不进行下载或硬件操作。

正式数据库仍NOT_CONFIGURED，正式项目仍WAITING_FOR_HARDWARE_BASELINE。本页未更改正式状态、审批、数据库或runtime日志；软件假设Ti60F225/I3与SC431HAI不冒充实物确认。所有业务实现、功能性脚本、TB、工程/约束与新工具运行均未发生。

