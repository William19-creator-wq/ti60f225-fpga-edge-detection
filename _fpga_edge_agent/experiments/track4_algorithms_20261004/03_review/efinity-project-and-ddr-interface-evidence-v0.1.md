# Efinity 工程入口与 DDR 公开接口补充证据 v0.1

日期：2026-10-04。范围：本机安装、现有工程配置及 C2 活动 DDR 公开调用链的只读核查。本文为证据报告，不是实现设计批准、完整仿真、布局布线或硬件通过证明。本轮没有打开 Efinity GUI、启动新构建、修改工作工程或原 HDK。

## 1. 已有开发环境和板卡配置

本机 `C:/Users/34528/FPGAEdgeLinks/Efinity2026_1/bin/efinity.exe` 实际存在，文件版本为 `2026.1.132`。安装目录的 `examples/helloworld-unified/helloworld.xml` 第 3–7 行选择 Titanium、Ti60F225、C4，第 16 行引用 Ti60F225_kit_pins.isf；这证明随安装已有该器件示例，但官方 kit 的 C4 与引脚配置不能替代 V4 的 I3 工程。

现有独立预检入口如下，两个入口均选择 Titanium / Ti60F225 / I3，顶层为 ti60f225_oob_top：

| 项目 | 控制面内入口 | 配套文件与已实测状态 |
|---|---|---|
| C0 | [ti60f225_oob.xml](../../../work/active/track4_ip_precheck_20261004/C0/ti60f225_oob.xml) | 同目录 peri.xml、SDC 存在；既有 map、官方调试合并、PT 已成功；PNR 在 packer 因 USER1 TDI/TDO 缺失失败，placement、route、STA 未完成 |
| C2 | [ti60f225_oob.xml](../../../work/active/track4_ip_precheck_20261004/C2/ti60f225_oob.xml) | 同目录 peri.xml、SDC 存在；原样工程既有 map 成功；修订时钟分支未执行，未通过整条布局布线与时序检查 |

上表工程链接相对于本文所在目录：`03_review` 向上三层到 `_fpga_edge_agent`。实际入口位于 `D:/大三/FPGA_verilog/_fpga_edge_agent/work/active/track4_ip_precheck_20261004/`。

原始更新资料包亦有现成入口：`Ti60F225_DemoBoard_v4完整资料包-0927更新/Ti60F225_DemoBoard_v4完整资料包-0927更新/10_Ti60f225_sc431hai2hdmi_demo/Ti60f225_sc431hai2hdmi_v1/ti60f225_oob.xml`，配套 peri.xml、SDC 均已按文件清单确认存在；本轮未逐行重读这三份原始文件。原始 HDK 保持只读，后续工程操作使用独立 work 副本。

Efinity 项目 XML 选择 FPGA 型号与时序等级；板卡上的引脚、电压、PLL 和外围接口落在对应外围配置，时钟和 I/O 时序落在约束文件。已有这些文件，是明确的工程起点；C0 SDC 第 78 行附近仍有 USER_PERIOD 占位符，C2 外部 byte clock 尚未闭合，因此文件存在不代表整包最终约束已合格。

既有构建结论引用 [RUN_REPORT](../../track4_full_sw_20261004/05_reviews/ip-precheck/RUN_REPORT.md) 第 3–20、38–46、61–67 行。CSI 在 Questa 编译时缺少可用保护 key，与 Efinity 是否具备 Ti60F225 器件支持是不同证据。XML 首行沿袭的 last_run_state/pass/bitstream 不作为本次运行成功依据。

## 2. 活动 DDR 接口已经具备什么

本节依据 C2 XML 的实际引用及公开 top/子模块调用链：`ti60f225_oob_top/checker0(frame_buffer) → u_ddr_buffer → ddr_wr_buffer/ddr_rd_buffer`，AXI 五通道接到 `u_ddr3_top`。实际控制参数为 DATA128、ADDR32、ID4，物理 DQ16、BANK3、ROW14、COL10，tCK=2500ps、CK_RATIO4、ASYN_AXI_CLK1。

公开控制器端口有完整 AW/W/B/AR/R 的 ready、valid、响应及 LAST 信号；公开 master 已采用 SIZE4、INCR、ID0、全 16 位 WSTRB，并按 `(LEN+1)×16` 增加 byte 地址。这些事实支持以现有控制器作为生产存储的适配起点。控制器行为体受保护，公开端口本身不证明所有长度、掩码、停顿与完成语义均已验证。

| 实际源码事实 | 对后续设计的影响 |
|---|---|
| 写 master 第 325–328 行在新帧同步时清 AWVALID/WVALID；第 409 行以末 W 握手推进 burst；第 425 行固定 BREADY；BID/BVALID 不参与行为，活动 framebuffer 未接 BRESP | 原 master 不能直接提供完整写响应核验、写错误、暖取消排空或“只允许一笔已发出写 burst”的证据 |
| 读 master 第 239–245 行按 RVALID 采样；第 280–285 行 FIFO 周期复位时清 AR/R 状态、正常固定 RREADY；第 304 行按 RVALID 与 RLAST 结束 | 原 master 没有证明任意 R 停顿、精确拍数、RID/RRESP 校验与旧读关闭 |
| cal_done 在公开 top 中用于 LED/debug；视频释放使用 w_confdone 与延迟计数 | 必须独立设计与核验校准完成后的生产准入，不能将视频复位延迟当作校准证据 |
| 公开 ddr3_top 没有命名的 fence/drained 完成端口 | FIFO 空、末 W、bank 切换、刷新 ACK 不能直接充当新算法需要的全部读写副作用关闭证明 |
| top 的 MAX_VID_WIDTH=960 未由 frame_buffer 向 ddr_buffer 继续转传，后者采用默认 1920×1080、I_VID_WIDTH32 | 活动 bank stride 为 8,294,912 byte；新地图须按真实下层参数制定，不能按 top 的 960 推算 |

上述是原链的证据边界，不据此推断板卡无法实现任务。新的存储适配、完整响应核验、校准准入及关闭合同仍属于待设计、批准、实现和验证的部分。PB-B01 保持 OPEN，本轮不修改 PB/ROW/SCAN 设计版本。

## 3. 阅读与哈希记录

root 本轮实际读取入口规则及配置；C0 XML 1–105、C0 SDC 1–110；按指定关键字定位 C0 peri；安装示例 XML 1–24；RUN_REPORT 的指定检索命中；C2 DDR 参数全文；写 master 310–346、386–428；读 master 230–247、270–319。其他公开调用链与 cal_done/stride 结论由只读子审阅实际阅读定位，未冒称 root 逐行重读所有源。DDR 保护正文不解密、不将加密内容解释为公开实现。

| 文件 | root 本轮实际 SHA256 |
|---|---|
| C0 ti60f225_oob.xml | 5F0CF2C013F945974052FFE796D68E84815C9F5C02B9CF37EA44086221BFED3A |
| C2 ti60f225_oob.xml | D67BFF492FDE948FDA71B8A9905218B6A5A07E7CA6BFA278CB266E0140299DE8 |
| C2 ddr3_parameter.vh | 688995BA379237B1DAA428CCB119B564C3DCB760227F75F2FE86B8D50A41DE80 |
| 既有 RUN_REPORT.md | 0A2EA29AAC6E6716E32361FA5402B14DF82DF781EA1300C4DCF8FFC910A5BDCA |
| 正式 PROJECT_STATE.json | 87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558 |

只有本证据报告与本地追加审计记录属于本轮写入。无业务源码、功能脚本、测试/TB、IP 重生成、工程修订、构建、bit/hex、数据库、网络、安装或硬件动作。完整十一项任务仍未完成。
