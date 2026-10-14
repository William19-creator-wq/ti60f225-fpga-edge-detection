# V4 四键、LED 与复位来源证据 v1

2026-10-04。状态：LOCAL_SOURCE_EVIDENCE；NOT_APPROVED；所有功能验证 NOT_RUN。本页仅保存 CONTROL 的板级来源和静态占用检查，不代替 CONTROL/PLATFORM 设计审查、当前工程生成、STA 或实物验证。原 HDK、PDF、工具数据库及既有文档均未修改；本轮没有生成业务源码、功能脚本、testbench，没有运行仿真、构建或网络动作。

本轮复核控制面入口、根规范 v0.2 和 PLAN_TEMPLATE 的 SHA256 均与已读版本相同，沿用其顺序读取及审批/人工硬件闸门。根规范 SHA256 为 `4E4680716458F75BDA157E6FD2E2D13D09A9E85B5A4F5F7FF0D906170C7BADB2`；控制面 AGENTS 为 `6C8C36BFDDF1E41E61E5C2E67D3C78B37AE0A01C16235E214969BB90EFD3A937`；模板为 `99B7DA32B92C225AA333637A2F4F4F5B8DF3307C914677C9C2DB77DB1BA7DE79`。本文保存不改变审批状态、数据库或运行时状态。

## 1. 实际来源及读取边界

路径别名展开如下。

- `V4ROOT` = `D:/大三/FPGA_verilog/Ti60F225_DemoBoard_v4完整资料包（赛题1~3直接使用））/Ti60F225_DemoBoard_v4`。
- `EFROOT` = `C:/Users/34528/FPGAEdgeLinks/Efinity2026_1`。
- `AUDITTXT` = `D:/大三/FPGA_verilog/_fpga_edge_agent/reports/audit/environment_20260923/pdf_evidence/TI60F225I3-V4 DEMO板软硬件设计说明-260920.txt`。

| 来源 | SHA256 | 本轮实际读取范围 |
|---|---|---|
| V4ROOT/Ti60F225A_V4_SCH.pdf，14 个 PDF 页 | 855CD587BE22D49686E82036FC57CF02290644C2AF8996B0C3B2620E36FD830F | 页6、8、9重新提取文字并在内存渲染核对像素；页3电源网络沿用同 hash 的既有来源 v2 |
| 工程根/TI60F225I3-V4 DEMO板软硬件设计说明-260920.pdf | 426A577CC3A544546F2BF1AD60A1F233541B7D6361764794E48B11ADA0C2E4F2 | 重核原 PDF hash；使用既有文本的用户 IO 表和旧按键测试表 |
| AUDITTXT | E960652618C834AF079D67A188E4F8825E08222BEE4C0A1D520064E83B41AFE8 | 678–707、889–899 行及页分隔；没有把印刷页码当 PDF 物理页码 |
| V4ROOT/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v6.rar | 45DEC9993BF3CD25F8CF45055D9A8206B50A4256BF8E5685C1E9EAF008F6B19C | 仅 tar 流式读取 XML、peri、公开 top、SDC，不解包或解密保护主体 |
| EFROOT/pt/db/devicemap.csv | 1568427EBD8839D5A35F44DFCC332CD37F9831FEC3EC515610A126EA427E8AD9 | 第49行 Ti60F225 的封装映射 |
| EFROOT/pt/db/package/opx_218x322_b16_d10_b225.xml | E58A269F05807655F58FC3AE9DE6F96C0E544E075436E93F5C5EC2322CE2A6BD | 第2行封装名及4、50、53、102–106行球号映射 |
| EFROOT/pt/db/die/opx_218x322_b16_d10.xml | E48633E2BE50401FDDB030E20B4E37649B8AF4278C3CADEEA20C438E6C91CFA5 | 所选 GPIO 实例、pad/bank 与6523–6538行允许电压 |
| EFROOT/pt/db/timing_models/opx_218x322_b16_d10_b225.xml | D7779F14DC8F4E9047C28D85A6A911029A1676128D5DD94ED8D7AED5A0A22587 | 15–18行 I3 条目；不运行 STA |
| [板级来源 v2](board-pin-source-evidence-v2.md) | 333DDB7EE245B18C03E1CE3479C2D98D381A8C6ED28919CC16A670AC5719B23F | 实际读回所选 camera/DDR/HDMI 活动球号和板电源网络 |

PDF 页6/8/9的页面标题分别为 Sheet 5/7/8 of 13；本文同时记录 PDF 物理页和 Sheet，避免两种编号混用。内存 PDF 分析使用已安装的 bundled Python `C:/Users/34528/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` 及 pypdf/pypdfium2；未安装依赖，未保存新的提取脚本或渲染文件。

v6 成员的相对路径统一带 `Ti60f225_sc431hai2hdmi_v6/` 前缀。下列原始成员字节 hash 沿用[显示来源 v1](display-hdmi-and-fetch-evidence-v1.md)的逐成员审计；本轮重新核对归档 hash，并重新流读相关行，没有把 PowerShell 字符串重新编码后的 hash 当成成员原始字节 hash。

| 归档成员 | 字节数 | 原始成员 SHA256 |
|---|---:|---|
| ti60f225_oob.xml | 13967 | 20B2CF104F8F21864831F23678326FDC491AC5BA3FB8359AD2C8CC775B2DC528 |
| ti60f225_oob.peri.xml | 75065 | 43EF0B302AE8197DF3394E24CD108AC1D82E8E0FBCF08B91778448F90C578E2B |
| ti60f225_oob.sdc | 41630 | 7DEA948873E6BBAA2FDA92E4E26C67F5CF0FD435A26D3B53BFAA46659B3325FF |
| rtl/ti60f225_oob_top.v | 35587 | 33FDB4DA60060BC65417399E9FAE45D1B28D0DC803E390DBC36C62E315B86BB9 |

## 2. 证据等级与四个用户按键

本文的等级只表示已取得的来源类型，不表示工程通过。

- S1：所选原理图的实际 net、元件和球号文字/像素。
- S2：所选 Ti60F225 封装/die/电压/I3 数据库条目支持。
- S3：所选 v6 公开配置或 source 中存在的绑定/行为。
- S4：新工程工具生成、CDC/STA、仿真或实物结果。本轮均未取得。

| 用户按键 | 开关及上拉 | FPGA 球号 / pad | bank / 板网 / 候选 IO 标准 | 本轮证据 | 当前 v6 的绑定边界 |
|---|---|---|---|---|---|
| KEY0 | SW0；R226=10K/1% | C4 / GPIOL_07 | TL / 3.3V / 3.3 V LVCMOS 输入 | S1：PDF页6、8；S2：package53、die5340/6168/6531–6538 | 全 peri 没有 GPIOL_07 组件；新 CONTROL 绑定尚未生成 |
| KEY1 | SW1；R100=10K/1% | P13 / GPIOR_27 | BR / 3.3V / 3.3 V LVCMOS 输入 | S1：PDF页6、8；S2：package106、die5533/6227/6523–6530；S3：peri274–275 | 当前名称 i_arstn，直接承担原始 PLL/CSI 复位，见§5 |
| KEY2 | SW2；R101=10K/1% | N13 / GPIOR_24 | BR / 3.3V / 3.3 V LVCMOS 输入 | S1：PDF页6、8；S2：package104、die5503/6224/6523–6530 | 全 peri 没有 GPIOR_24 组件；新 CONTROL 绑定尚未生成 |
| KEY3 | SW3；R225=10K/1% | A3 / GPIOL_03 | TL / 3.3V / 3.3 V LVCMOS 输入 | S1：PDF页6、8；S2：package50、die5310/6165/6531–6538 | 全 peri 没有 GPIOL_03 组件；新 CONTROL 绑定尚未生成 |

电路事实：四键均由对应 10K 上拉接 VCC_3V3，开关闭合接地，故电路定义的空闲为高、按下为低。该极性是原理图推导；实物接点、上拉电压、弹跳时长及逻辑阈值未测量。PDF页8 U11E 标 TL、U11K 标 BR，对应上述四个球号；不是按名称猜测输入。

因此，资料支持四个独立用户按键来源，无须把单键菜单或未证明的第五个用户键/UART当成现有交互硬件。但本文没有确定手势时长、阈值步长、配置生效边界或冻结协议；这些须由 CONTROL 局部设计及其组合检查规定。

## 3. LED0/LED1 与独立配置复位

| 来源项 | 实际球号 / pad | 电气与等级 | 当前配置/行为 |
|---|---|---|---|
| LED0 | N14 / GPIOR_21，BR/3.3V | PDF页6：R96=100K 到 Q12 MMBT3904 基极、D0/R248=4.7K 接 VCC_3V3；PDF页8球号；package102、die5473/6221；S1+S2+S3 | peri287–289 输出3.3 V LVCMOS；top364 为 cal_done 条件下的 cnt[24] 心跳 |
| LED1 | P14 / GPIOR_22，BR/3.3V | PDF页6：R97=100K 到 Q13 MMBT3904 基极、D26/R249=4.7K 接 VCC_3V3；PDF页8球号；package103、die5483/6222；S1+S2+S3 | peri290–292 输出3.3 V LVCMOS；公开 top 有 led[3:0] 端口，但本轮全文检查仅找到 led[0] 的赋值 |
| 独立 RESET_N 开关 | CRESET_N=J5，专用配置脚 | PDF页9/Sheet8：R113=100K 上拉 VCCIO1A、开关闭合接地；U13 SSP61CC1502MR 也连接 CRESET_N；package4；S1+S2 | 配置复位，不属于四个普通 KEY 的输入端口；不表示业务事务已排空 |

LED0/1 的 NPN 低侧驱动电路支持“GPIO高使晶体管导通并点亮”的候选极性。这是电路推断，没有实测亮度、导通电流或开关波形。两灯的旧输出绑定可提供候选引脚来源，但新状态反馈必须有唯一 driver；不能在旧 cal_done 心跳之外添加第二个 LED0 driver，也不能把 LED1 的端口/引脚存在当作旧设计已经正确驱动它的证据。

其余 LED 不作为本轮 CONTROL 的选定输出：peri293–295 把 led[2] 放在 GPIOR_28/R14，而原理图页8的该网是 UART_RX_3V3；peri296–298 把 led[3] 放在 GPIOR_25/P15。原理图页8 P15 与页9 N2/GPIOL_P_02_CSI 均出现 LED3 同名网，且涉及 BR/3.3V 与1A/1.8V；没有 PCB/netlist或实物核对来解释该重复。不能据这几项资料宣称全部八灯已有唯一且兼容的驱动映射，或把 R14 当作额外控制反馈输出。

专用 CRESET_N 的实体开关与四个用户键在原理图上独立。它能够直接触发配置层级复位；任何按键业务交互、软件意义的 warm reset、旧 scope drain/ACK 都不得以按过该开关作为完成证据。

## 4. Ti60F225 / I3 / OPX 225-ball 的支持范围

devicemap.csv 第49行把 `Ti60F225` 映射到 `opx_218x322_b16_d10_b225` 条目；package 第2行名称为 `225-ball FBGA`、status=Final。上述球号在该实际封装 XML 中都有唯一映射，不借用 Ti60F225ES 或其他封装的映射。die 中六个所选 GPIO 均有 periphery_instance 与 Configurable io_pad_map，所选 KEY0/KEY3 位于 TL_CORNER，KEY1/KEY2/LED0/LED1 位于 BR_CORNER。

die6523–6530 为 BR_CORNER，6531–6538 为 TL_CORNER，均明确允许 `3.3 V LVCMOS`，且 default 也是该标准。板电源网络同 hash 来源 v2 的 PDF页3记录 BR/TL 固定3.3V；v6 peri14–15也配置 BR/TL 为3.3 V LVCMOS。三者在该电压选项上相符。

v6 project XML 4–6行选择 Titanium / Ti60F225 / I3。精确 b225 timing model15–18行存在 I3、status=final、voltage=0.95V，max/min表分别采用 tscale1.2075/0.7。这里的0.95V为所选 timing-model 的电压字段，不能当作 BR/TL 的 VCCIO 电压。I3 条目存在也不是新 CONTROL 时序已经收敛的证明。

这可以闭合“候选球号在所选设备封装内存在、可作 GPIO、bank 支持所选3.3V”的静态来源链。没有运行 Interface Designer、IP生成、综合、布局或 STA，没有新工程 pinout、电气报告或 I3 时序结果，因此不记录为新引脚工程合法性 PASS。

## 5. 板说明冲突与 KEY1 raw reset 冲突

板说明的用户 IO 表位于 PDF物理页34/印刷页33；既有提取文本的页分隔在678行，正文683行写“4个LED和两个按键”，实际随后列四键/八灯。689–705行的部分键灯绑定与所选原理图不一致。

| 项目 | 板说明用户 IO 表 | 当前所选原理图 PDF页8 | 与 v6 配置的对应 |
|---|---|---|---|
| KEY0 | C4 / GPIOL_07 | 相同 | 当前 v6 未绑定；旧 v1 的 i_arstn 曾放此处，不沿用旧信号行为 |
| KEY1 | P14 / GPIOR_22，txt690 | P13 / GPIOR_27 | v6 i_arstn 在 P13，与原理图一致 |
| KEY2 | N14 / GPIOR_21，txt691 | N13 / GPIOR_24 | v6 未绑定 N13；N14 已给 led[0] |
| KEY3 | A3 / GPIOL_03 | 相同 | 当前 v6 未绑定 |
| LED0 | P13 / GPIOR_27，txt698 | N14 / GPIOR_21 | v6 led[0] 在 N14，与原理图一致 |
| LED1 | N13 / GPIOR_24，txt699 | P14 / GPIOR_22 | v6 led[1] 在 P14，与原理图一致 |

旧按键测试表 txt891、897–899 再次沿用上述手册 KEY1/KEY2 绑定，不能当作当前 V4/v6 的独立一致佐证。以上只是选定资料之间的冲突；没有实物测量来证明哪份资料对应用户手中板子的修订。当前设计建议使用原理图和 v6 互相一致的四键/两灯映射，并保留实际板版号核对闸门。

v6 raw reset 的直接事实：peri274–275 将 i_arstn 输入绑定 GPIOR_27/KEY1/P13，且 is_register=false。top58声明 i_arstn；339–342直接把它接四个 PLL 的 RSTN；382/384接 CSI reset_n/reset_byte_HS_n；807–813又用于 LCD_POWER 和 MIPI DP reset 输出。top338由各锁定信号生成 w_arstn，不能消除这些直接 KEY1 复位路径。

因此在保留上述 source 行为时，KEY1 按下会同时改变原始时钟/CSI复位，不能作为普通 mode/median/freeze 交互键。候选设计必须明确把四键采样收归 CONTROL 的唯一 AON 输入 owner，并让平台复位按已设计的类型化恢复协议独立控制；该改变仍受 v0.2 指定版本/范围/基线批准门槛约束。本页没有改动 top/peri，也没有宣称该冲突已被实现消除。当前 PLATFORM 文档已将 KEY1 描述为逻辑复位请求；四键交互方案还需要下一设计版本明确该职责调整，避免文档 owner 与 source raw reset 同时被误认成有效实现。

## 6. 与 camera / DDR / HDMI 的静态占用检查

检查范围是本轮实际全文件流读的 v6 peri，以及实际读回的 board-pin-source-evidence-v2 所选活动球号清单；未执行放置合法性检查。对 GPIOL_03、GPIOL_07、GPIOR_24、GPIOR_21、GPIOR_22、GPIOR_27 的全 peri 检索只得到 i_arstn、led[0]、led[1] 三个已有组件，没有前三个新键的组件绑定。

| 已选子系统 | 现有活动资源范围 | 与四键/两灯静态关系 |
|---|---|---|
| CAMERA | CSI在2A/2B；GPIO SCL=D12/GPIOR_20、SDA=B14/GPIOR_18、reset=C12/GPIOR_16，TR/3.3V；见来源v2§5和 peri277–286/299–301 | 没有相同球号或上述六个 GPIO 资源；KEY1 raw CSI reset 是行为冲突，不能因无 pin 重叠而忽略 |
| DDR | 来源v2§3列出的3B/4A/4B活动球号和VREF；peri97–272/302–306 | 没有四键/两灯球号；所选BR/TL3.3V没有改变DDR bank1.5V；真实2Gb/PHY仍未知 |
| HDMI | 3A/1.8V，CLK H12/H13、D0 F15/G15、D1 G14/H14、D2 F13/G13；来源v2§4 | 没有四键/两灯球号；没有让控制输出成为 serializer 的第二 owner |
| 既有状态反馈 | led[0]=N14、led[1]=P14，peri287–292 | 新 CONTROL/PLATFORM 须替换旧 driver 职责，并指定唯一输出 owner；不能并行驱动旧心跳 |

结论限于所选公开资料中的球号/资源/电压无直接重叠。它不证明新 peri 的完整约束合法性、CDC、路由或 I3 时序。对 v6 SDC 全文的 i_arstn、led[、六个 GPIO 名字字面检索为0匹配；字面没有匹配不等于没有更宽泛的时序例外，更不能证明新异步键输入已获完整约束。

## 7. 可用设计输入与仍需闭合的项

可向 CONTROL 主稿提供的输入事实为：四个独立低有效键，KEY0=C4、KEY1=P13、KEY2=N13、KEY3=A3；两路候选高有效 LED0=N14/LED1=P14；独立 J5/CRESET_N 配置复位。CONTROL 可以在此基础上提出 AON25 同步、消抖、互斥手势和状态反馈合同；这些是新设计候选，不能说已在参考 top 内实现。无须额外假设 UART 或其他按钮。

| 本地未闭合项 | 必要证据/文档动作 | 本轮状态 |
|---|---|---|
| CK-B01 实物修订与电气 | 人工核对真实 V4 板修订、四键网/上拉电压及两灯极性；解释板说明与原理图差异 | HARDWARE_PENDING；NOT_RUN；属于比特流之后人工闸门，本次采用预设V4资料基线的软件设计/实现不以硬件到货为前提 |
| CK-B02 新引脚与 I3 约束 | 指定批准范围后生成新 peri/pinout，检查六个唯一 owner、3.3V IO、异步输入同步边界及 I3 CDC/STA | BLOCKING；NOT_RUN |
| CK-B03 KEY1 原始复位解绑 | CONTROL/PLATFORM 下一局部/整体版本明确四键普通交互及平台恢复职责，核查旧 PLL/CSI/LCD/MIPI DP 直接 raw reset 路径；批准后才可实现 | BLOCKING；当前 source 未改 |
| CK-B04 LED owner及未选输出 | LED0/1指定唯一 driver；清除对旧心跳/未赋值LED1功能的误认；其他LED/R14及LED3重复网不在本轮选定输出内 | BLOCKING；NOT_RUN |
| CK-B05 手势和系统生效边界 | 主设计规定 press/release/long/double互斥、上电已按住、多键、队列满及旧配置/冻结请求pending的处理；与FM/DISPLAY/CAMERA状态消息及平台恢复合成检查 | 仅设计输入；无业务实现/验证 |
| CK-B06 实际板级验证 | 指定审批与人工硬件闸门后验证实体交互、电压/极性/弹跳、时钟/复位恢复、真实DDR/CSI/HDMI依赖 | HARDWARE_PENDING；NOT_RUN；属于比特流之后人工闸门，本次工作止于比特流，不作为当前软件工作的前置要求 |

本页新增来源可以支持后续设计，不宣称 READY_FOR_REVIEW、批准实施或硬件成功。所有功能性测试、testbench、综合、IP生成、STA和实物操作均为 NOT_RUN。
