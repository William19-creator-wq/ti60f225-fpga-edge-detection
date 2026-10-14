# TRACK4-CAM-ID-001 v1 独立静态审查

日期：2026-10-13。审查者：board_connector_readonly 子 Agent。结论：在本次审阅范围内未发现阻塞实现的问题。仅进行源码、配置和哈希只读核对；未运行测试、综合、布局布线或硬件操作。此结论不能代替根任务的构建结果及人工读灯。

依据：`approved-design-v1.md` 冻结设计；`planning/design-TRACK4-CAM-ID-001.md` 末尾用户批准记录；CAM-ID-BL-20261013-v1（161 项）。实施目录：`work/active/track4_camera_id_001_20261013/`。

## 审查结果

| 检查 | 证据与结论 |
|---|---|
| R1 四笔与启动 | `camera_id_probe.sv:22` 的 21 位 2,020,000 拍启动计数可容纳目标值；PREPARE（204 行）固定 0x30/3107、0x30/3108、0x32/3107、0x32/3108，tag 为 1–4；ISSUE/WAIT_REPLY 不改请求正文。100 MHz 下约 20.2 ms。 |
| R2 位级协议复用 | `i2c_register_master.sv` 与批准冻结源完全同哈希；req_read 固定 1、req_data 固定 0、cancel 禁用。读取包含写地址及寄存器指针、重复 START、读地址、数据、主机 NACK 和 STOP。143 行从机 ACK 和 153 行主机结束 NACK 的语义分开。 |
| R3 身份资格 | M1 61 行检查 outcome=0、reason=NONE、drained=1、ack_mask=1111、非隔离；156 行另要求已握手且完整 tag 匹配。两地址独立存放字节和有效位；247 行 NEXT 使用上一拍已提交数据，只有两有效位齐全且 ID=CD6B 才点正确 ID 灯。单字节成功、ID 错或普通 NACK 都不能点匹配灯。ACK 灯可保留故障之前已取得的地址 ACK，符合设计。 |
| R4 总期限与终态 | 25 位可容纳 25,250,000 拍，饱和计数不回绕。86 行期限到达禁止新请求；186 行期限、非预期回复、236 行错误 tag/异常回复转 FAULT。只允许第四笔合格终结回复同沿或其 NEXT 提交拍完成；其他中间事务不延期。DONE/FAULT 吸收，不能自动重试；FAULT 立即门控驱动并禁用主控。 |
| R5 LED | 顶层 364 行 D0 心跳表达式和原计数器不变；375–381 行依次连接 started、address30_ack、id30_match、address32_ack、id32_match、all_done、bus_fault。无新跨域反馈。 |
| R6 单驱动/OE/复位 | 顶层 515 行只实例化新的 camera_id_probe；旧配置实例和其 5 MHz 复位计数器移除。534–537 行 SCL/SDA OUT 固定 0、OE=drive_low。peri 的 IN/OUT/OE 均无寄存器和 I/O 时钟；原 OE 极性不变。M1 78 行复位链异步置位/同步释放，93–94 行外部复位立即屏蔽驱动；原 `o_cam_rst_p=~w_arstn`（533 行）原样保留。 |
| R6 引脚/工程 | XML 只按 pkg/master/probe 顺序添加三源和末尾换行。peri、SDC 哈希不变。当前 pinout CSV 确认 D0–D7 为 P13/N13/G3/N2/G4/E1/E2/M2，SW0=C4，SDA=B14、SCL=D12、相机 RESET=C12。无按键被增改为输出。 |

静态边界走查：两个地址都 NACK 时，各次只有正常 NACK 且 drained 才转 NEXT；四笔结束 D6=1、D7=0、ID 灯均灭。错误 tag、未释放回复或主控隔离导致 D7=1、停止后续事务。第四笔成功时先提交低字节，下一拍再形成 ID 资格和 D6，未见非阻塞赋值旧数据问题。

## 文件一致性

对 161 项批准清单逐项读取哈希：157 项相同；只有顶层和工程 XML 两项为预期变更；旧 outflow bit/hex 两项未复制到本版目录，避免把旧产物视为新构建结果。新增调度文件是批准增量。MIPI/DDR/HDMI、原有其他 RTL、peri 和 SDC 未见源文件变化。

| 文件 | 本次审查 SHA256 |
|---|---|
| rtl/cam_id_probe/camera_id_probe.sv | 5D37F89B7EBEDD4C1D756A1D514FF8F3EB8F99297A2BAB4A7B6CEEFF806B143C |
| rtl/cam_id_probe/i2c_register_master.sv | 2758C14AF94790640B5F46996A08E9CB6AB06D60086AD197F475DB6E46A74636 |
| rtl/cam_id_probe/sc431hai_profile_pkg.sv | 3E0BE2ECB802751EEDD2FD9A36F72C87D976AC0EFA6CAC5DD271D794F8C91FA3 |
| rtl/ti60f225_oob_top.v | 1B81A86A6C4C0228D3D2D446F602D28EAD256CBEDCE0C193210EC297CBEA6BC1 |
| ti60f225_oob.xml | 3F1B65FE118163975A0EFC46DFE68188D74A9645BD38F2A140FCEA9BC91D9389 |
| ti60f225_oob.peri.xml | 884225E0EA6554EBA62192CA03D49F8265121E069830FA09EE41694980148605 |
| ti60f225_oob.sdc | 17952FC61901C186F3518E2A0F4E523DE58A72CAC6DBF34591EB0C8E80892873 |

## 保留限制

本轮没有新增动态测试，极端回复/tag/期限情形的结论来自静态走查。历史主控测试不能当作本轮新调度的动态证据。当前 pinout 的读取仅核对引脚映射，不替代全流程完成证据。最终资源、时序及产物哈希由根任务构建后登记。异步外部总线的电气边沿、模组内部复位/SID/电平转换、摄像头图像均不由此次审查证明；无 ACK 不能单独判坏件。保持已批准的复位极性限制，不提出未经证据支持的翻转。
