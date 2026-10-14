# 本地官方接口与复位依据 v1

2026-10-04；关联 TRACK4-FULL-SW-001、DATA-JOIN v0.1 的 DJ-B01…03。**来源核查，不是 IP 行为仿真或设计批准。**原始资料只读。

## 1. 本轮调查与结论

前轮用户指定的 VF 完整嵌套目录与 Demo/Demo 中确有 DDR/PHY、CSI/HDMI 工程；见[补充证据](vf-demo-supplemental-evidence-v1.md)。本轮进一步读取已有 Efinity 2026.1 本地帮助和 VF Ti60 数据手册，定位可直接用于软件工程设计的事实。

root 实际读回下表八个 HTML 的 main 正文、核对十个来源文件 SHA256；两份 PDF 的指定页由只读子审实际读取，root 复核文件身份及 SHA。没有将子审摘要称为 root 全部 PDF 逐页核读。读取范围不包括所有 PDF、私人目录或外网。

结论是可以补齐若干参数、PLL 与 LVDS 时钟限制，以及配置后保持复位的资料依据；仍没有匹配端点的完整 CSI 输出/错误关闭、soft-DDR 写可见/复位后旧效果消失、10bit serializer 关闭合同。DJ-B01…03 仅部分补证，继续 BLOCKING；已定义、获批后执行的测试保持 NOT_RUN，不要求先生成未批准测试证明设计 READY。

## 2. 版本和实际文件

以下 Efinity 相对路径以 C:/Users/34528/FPGAEdgeLinks/Efinity2026_1 为根；这些是实际现有文件，不是待下载地址。

| 编号 | 文件/版本 | SHA256 |
|---|---|---|
| VE-01 | ipm/ip/efx_csi2/efx_csi2_rx/ipm/doc/topics/hlp-mipi-csi2-rx.html；UG-CORE-MIPI-CSI2-RX-v3.2，2025；组件目录5.15 | DD0EA6315A492AC87DA86E7D6F48492F1F2F315FC1B9B1DAAB7D9D5CA1DF6C15 |
| VE-02 | 同目录 mipi-csi2-rx-core-customizing.html | 34B1AEB02FD8C683FE887DB47B381BBE813BE5D10C90674FC100A1D4AA455FA9 |
| VE-03 | ipm/ip/efx_ddr3_soft_controller/ipm/doc/topics/hlp-ddr3-soft-controller.html；UG-CORE-DDR3-CONTROLLER-v2.1，2024；组件目录5.16 | 1394771103FEB7A9FB46724DC0CCB47A9A25AD6EE7EB65295EDCCAEC5D8BBE34 |
| VE-04 | 同目录 ddr3-controller-fd.html | 8F6DF6DAF9A3F462BFFFE8D4A0AD5DCA30971407ECAB390016D0EEF3F8DA332A |
| VE-05 | pt/doc/topics/titanium-pll-1.html；UG-TiINTF-v1.0 | 1E21E09F6B1258F1CDFCAC278620448B6FC2A7779B93CACE11D2DE64A7FEC544 |
| VE-06 | pt/doc/topics/titanium-hsio-as-lvds-1.html；UG-TiINTF-v1.0 | 935F896AE218CFDECE8DC32668E30A2CF243795B64584534582BF0F2EBDD92BC |
| VE-07 | pt/doc/topics/hlp-id-lvds-ti-1.html；UG-TiINTF-v1.0 | C906B2B27E2C635A4519B94CBFBEB9CD249309E7D23BC5E93942FC97E5E8181E |
| VE-08 | pt/doc/topics/create-lvds-interface-tx-ti-1.html；UG-TiINTF-v1.0 | E8B410B5E3F7145B7D2D870C0F3D5B44D2384ED4B67198762599832855A18860 |
| VE-09 | [VF Ti60 datasheet](../../../../VF-Ti60F225_HDK_V2.1_20251009奥唯思赛题4文件包/VF-Ti60F225_HDK_V2.1_20251009/VF-Ti60F225_HDK_V2.1_20251009/03_芯片数据手册/钛金Ti60datasheet-v2_0.pdf)；DSTi60-v2.0，April 2022，70页 | 0AB5A7D4143811668DB8E34C671DE30A97588846E931CD8854FA37AA6144468E |
| VE-10 | doc/pdf/efinity-quantum-ti-primitives-ug.pdf；UG-TIPRIM-v4.0，May 2026，163页 | 302D7BFA3A7C7087424AC029AF0AFA29816AAD674C26F4FAAE86DBB08F5EE0C7 |

VE-01/02 与[已有相机证据](camera-csi-and-config-evidence-v2.md)引用的是同一文件；找到路径不等于获得新版本行为保证。同名不带 -1 的部分 PT 帮助属于 Topaz；本表实际核对 Titanium 正文。组件5.15/5.16、帮助文档v3.2/v2.1是不同版本轴，不能混成“全部IP同一版本”。

## 3. CSI：可以采用的事实与不能推定的行为

VE-01 原HTML第181–184行明确本地帮助只提供 overview，详细指南指向 Support Center；本轮未访问该链接。VE-02 Table 1 / 第217–232、270–309行给出：

- Data Lanes 支持1/2/4/8，默认4；IP core clock参数40–100MHz；HS byteclock参数10–187MHz。
- GENERIC 没有通过 LS/LE 的精确同步，ACCURATE 有该同步选项。
- RXStopState pipeline 使用 HS mode byteclock，补偿解串、读FIFO、同步延迟；参数范围8–15。
- Pack Type 40 支持 RAW10/RAW20 等；只启用所用 pack type 是文档给出的资源建议。
- Pixel sideband 可选；更多细节须 portlist。
- Pixel FIFO 深度256–8192、2的幂；文档要求最小深度大于 HACT×bits_per_pixel/64。1080p RAW10 算术门槛为300个64bit单位，不能把这个式子直接当成新工程实际队列深度或服务期限证明。

上述不足以证明实际输出每拍像素数、40bit RAW10 尾拍/有效字节、sideband 与像素的逐拍归属、CRC/ECC/缺包归帧、abort后旧数据已排空以及 START_CLOSURE 所需接收入口关闭。继续以真实 wrapper/配置/匹配模拟模型和完整文档证据消除此缺口，不能由参数名称自行补全。

## 4. DDR：已有结构概述不能代替匹配端点的 fence

VE-03 原HTML第179–182行同样明确 overview。VE-04 第173–187行及两幅结构图列出 instruction RAM、main controller、arbiter、64-depth读写buffer和 DQ input auto-calibration。

这是结构来源，未给出可用于本项目直接承诺的 B 响应后写读可见、fence实现、reset后先前写事务物理效果已消失或重新校准完成关闭旧事务的合同。Titanium硬 LPDDR4/4x 帮助中另有提前返回B的描述，但不是 V4 使用的 soft-DDR3 端点，不能移植为此处的证据。

[已有 VF/Demo 核查](vf-demo-supplemental-evidence-v1.md)确认 controller/PHY 存在，而相关 Micron 模型缺匹配2Gb参数头；两项事实分别保留。仅改容量宏、用4Gb头、跳过校准或用行为AXI slave都不能证明真实2Gb器件/PHY已经通过。

## 5. 冷启动与PLL

VE-09 PDF相关页已读：p51–52 Power Up / Configuration，p64 Table62及脚注17/18；p43 Table24、p62 Table60/61。来源原文支持：

1. 电源上电及进入user mode有顺序要求。CDONE高后，建议继续保持 system interface reset 至少 tUSER=25µs；JTAG还涉及 ENTERUSER。该条件应进入 PLATFORM 冷启动设计及获批后波形验收，不能因为配置结束立即开放业务。
2. PLL RSTN低有效，最小脉宽10ns；p62给出最大500 PFD周期lock-in，并明确表值为 preliminary。不能将该值写成对任意失clock恢复都成立的运行超时。
3. VE-05 Table1 要求参考clock稳定后释放PLL reset；动态切换reference时保持reset。LOCKED异步，其高/低脉宽可短于CLKOUT周期；普通双FF采样本身不能保证捕获每个故障脉冲。
4. VE-05对Ti35/Ti60说明CLKOUT4仅进入top/bottom regional clock等限制；时钟选择须核对实际peri/器件，不仅比较频率算术。

VE-10 p21–22 的 EFX_FF 支持同步/异步SR、SR_VALUE和相应优先级；**SR_VALUE默认0不构成上电Q自动为0的保证**。AON初始状态的可靠来源、板上reset链、失clock时的保持/释放仍需依据；不通过清除账本掩盖旧物理承诺。

上述作为 PLATFORM/DATA 冷启动修订的来源约束，尚未修改原 PLATFORM v0.1 冻结字节或生成新RTL。

## 6. HDMI/LVDS能直接核查的时钟规则

VE-06 Table1/3 与Figure4、VE-07/08正文，以及VE-09 p31/33、VE-10 p107–109共同支持：

- parallel数据在SLOWCLK域交给TX；half-rate使用FASTCLK双沿；示例图为8bit。
- Titanium支持10bit serialization；half-rate需偶数宽度；TX RST用于复位serializer。
- half-rate serial clock = parallel clock×serialization/2。148.5MHz与10bit对应742.5MHz fast clock、1.485Gbps数据率；这是关系算术，未证明本工程STA或板信号质量通过。
- serial/parallel须同PLL；fast相位设置为45°–135°，同侧lane/参考clock有降低skew的建议；不同方向允许的PLL资源见VE-07 Table3。

资料仍不保证10bit的准确首字装载、reset/flush期限、pair→pixel与TMDS寄存器的实际边沿关系，以及停clock后旧引用已经消失。DISPLAY的消息确认或DS授权不能由这些物理参数替代关闭证明。普通8bit图与同名原语不自动证明10bit行为。实际设计须保持 DJ-B03，匹配模型/完整指南/真实验证缺一不可。

## 7. 对当前行动的影响与验证边界

| 对应缺口 | 本轮新证据怎样改变后续行动 | 尚需证据 |
|---|---|---|
| DJ-B01 DDR | 本地soft帮助已定位且确认为overview；不再把未找到控制器当理由 | 2Gb参数及端点实际读写/校准、B后可见、旧效果关闭合同 |
| DJ-B02 CSI | GENERIC/HS pipeline/Pack40/sideband限制已明确，复用相同SHA来源 | 真实PPC/尾拍/错误归帧/关闭合同 |
| DJ-B03 cold/HDMI | 冷启动至少25µs依据、异步LOCKED、half-rate/samePLL/相位关系明确 | AON初值、故障捕获及10bit旧pipeline关闭 |
| RC数值 | 不由硬件帮助推出识别数值或95%质量 | 独立数值稿、候选覆盖/分段/配置实体、实际开发及独立质量 |
| 执行前置 | 本轮仅使用现有只读工具与控制面文档写入 | 指定版本/范围批准、原构建授权及数据库健康 |

没有创建新下载/联网/安装申请，也没有重复既有模型或FRONTEND请求。业务代码、功能脚本、可执行测试、真实IP仿真、综合、引脚工程、PNR/STA和bit/hex仍未生成/未运行。资料分析不等于执行验收；本次软件完整目标未完成。
