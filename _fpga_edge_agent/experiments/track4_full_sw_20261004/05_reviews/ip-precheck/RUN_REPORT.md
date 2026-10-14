# 已批准 IP 预检：v1.2 实际终态

2026-10-04；Efinity 2026.1.132、Questa 2024.1、Ti60F225/I3。**有限预检按停止条件收束，存在失败；完整十一项工程未完成。** 实际批准及原字节设计快照见[批准 v1](approval-v1.md)、[输入修订 v1.1](approval-v1.1.md)、[输入修订 v1.2](approval-v1.2.md)。C0 最终采用获批 92 输入；没有扩展算法实现、功能 testbench、保护 IP 升级、bit/hex 或硬件范围。

阅读顺序：阶段结果→资源→失败因果→时钟与仿真限制→输入、命令和审计。机器可读终态见[case-status](case-status.json)。

## 实际阶段与结果

| Case / 输入 | 已执行的真实结果 | 下游终态与限制 |
|---|---|---|
| C0 attempt1 / 89 | map exit1，遗漏两个原 I²C 头文件 | 首次日志保留 |
| C0 attempt2 / 获批 91 | map exit1，遗漏顶层选择的原 Panel 初始化 MEM | 第二次日志保留；不是 DDR 保护 IP 不可综合的证据 |
| C0 attempt3 / 获批 92 | map exit0；官方调试生成/合并 exit0；PT 外围接口 exit0、有 LVDS 间距警告；PNR exit1 | Packer 缺 USER1 TDI/TDO；placement 未到达、route/STA NOT_RUN |
| C0 Questa | 15 份真实厂商行为模型 vlog exit0；67 项 DUT 命令 vlog exit2 | 第 66 项 CSI 385 行无 key；第 67 项 DSI 未到达；vopt NOT_RUN |
| C1 | 未执行或修改 | SKIPPED_DEPENDENCY_C0；另有 PLL #4 固定 regional 的独立设计阻塞 |
| C2.original / v6 实际 60 引用、135 输入 | map exit0；15 厂商行为模型 vlog exit0；59 项 DUT 命令 vlog exit2 | CSI 459 行无 key；vopt NOT_RUN；原设计此 revision 仅原样编译/综合 |
| C2.clock-corrected | 未执行 | CLOCK_UNRESOLVED，按批准设计停止 PT/PNR/STA 分支 |
| C3 | 未执行 | SKIPPED_DEPENDENCY_C2_CLOCK；不推测 ASYN0 资源 |

两个早期遗漏是 root 清单准备错误，已按明确输入修订批准恢复原字节。第三次 C0 已越过综合及外围接口阶段，但没有完成布局布线。map PASS 不提供摄像、DDR 校准、帧缓存内容、识别质量或完整十一功能实现证明。没有实际 STA 报告；PT PLL timing report 不能替代 route 后 STA。

## C0 资源与保留调试

基础 map 来源：[attempt3 报告快照](C0-attempt3-logs/ti60f225_oob.map.rpt)，Elapsed synthesis 94s。调试合并后来源：[实际 ti60f225_oob_top.map.rpt](../../../../work/active/track4_ip_precheck_20261004/C0/outflow/ti60f225_oob_top.map.rpt)，Elapsed synthesis 100s；PNR 使用该新 `.dbg.vdb`，不能用基础 map 数量代替保留调试后的整体数量。

| 资源 | C0 基础 map | C0 官方调试合并后 |
|---|---:|---:|
| RAM10 / DPRAM10 | 134 / 4 | 156 / 4 |
| FF / LUT4 | 7414 / 10773 | 8783 / 12858 |
| ADD / SRL8 | 1698 / 1134 | 2027 / 1175 |

基础层级 DDR 父 31 RAM 已含桥子 9；CSI 4、frame_buffer 15、DSI 76、Debayer 4、Panel 4、DVI 2。DDR FIFO 的 8 块被优化为零 ROM，不能当成完整 DDR 功能预算或普遍省额。合并阶段 CSV 为工具层级估计，不能代替最终 resource summary。当前未跑 ASYN0，节约仍 UNKNOWN。

基础综合当前 warn 区段有 303 条事件及汇总，完整保留；主要风险有 frame_buffer 的 16/24 位连接、从未更新的下降沿检测寄存器、浮空 i_hs、三处 latch、未驱动 PLL reset/LED、校准内部信号接地及零 ROM 优化。本实验没有功能修复。非 ASCII 路径、IV 告警也完整保留。

[调试配置核对](C0-debug-profile-check.json)确认原 wizard SHA256 `52B3CFD44B6311F1B1386124B781CE56EB0090A220E08E78B6AE359916F1DB04` 不变。官方新 profile 仅两条随机 UUID 更新；排除 UUID 后，两 core、connections、vdbs、session 完全相同，保持 4096 深度、5 组探针、两时钟域、USER2、pipeline1。helper 实际使用新 tool profile 与新 RTL 对应，未用空 mark_debug profile 替代。92 输入只冻结原 profile，不包括历史 debug_top/VDB；新 debug_top.v 是官方产物。

## C0 PNR 失败因果与接口检查

[PT console](C0-interface-console.log)实际生成 interface.csv、pinout、LPF、PT timing、PBN 等。警告为 TMDS clock 附近 GPIOR_P_09 的 LVDS 间距。PT 查询 bitstream 支持、生成外围配置不是完整 bitstream flow；工作目录 bit/hex 数量仍为 0。

[PNR console](C0-pnr-console.log)、[place.out](C0-pnr-logs/ti60f225_oob.place.out)、[place.rpt](C0-pnr-logs/ti60f225_oob.place.rpt)：interface.csv 读取成功，packer 2.4928131s 后因 required 的 jtag_inst1_TDI/TDO 缺失失败。place.rpt 存在不表示 placement 已通过。

只读因果核查确定不一致来自冻结原参考：原 top 42–214 端口表及全文没有 jtag_inst1/bscan 实例；原 peri 451–463 却声明 JTAG_USER1。原 XML 已启用自动调试，原 profile 指定 USER2。本次官方 dbg.peri 421–433 保留 USER1，436–448 新增 USER2；dbg.map.v 190–200 有 USER2，全文无 USER1。interface.csv 309/310 要求 USER1 TDI/TDO，320/321 对应 USER2，place.out 21/22 正好报 USER1 缺失。不是本次格式迁移新造的问题。

原 top SHA256 `0ACCF23D67A2E5360C91DDCD36563C5E90A682BE52B071B18F2B8F0F40DF5AA9` 与副本完全一致；原 peri SHA256 `9D378EFF67AC34F88F78A41341A1451E8F3B87B246434DDEDA12C7295A100CAE`；实际 interface.csv `DB76BBCAD2D2ADBBF3B523C5F56191CD7B14482754F800599DB0F034742B2AC2`，place.out `452410821A2EEBCF374C8C1A5FCCCC1E4B61CFC3A42425015D7E603D605CA7AF`。当前批准仅保留调试/外围并适配格式；删除 USER1、改 JTAG 用户、补端口或关闭调试没有已证明的仅格式修正，未实施。

## C2.original 资源与功能限制

来源：[map 报告](../../../../work/active/track4_ip_precheck_20261004/C2/outflow/ti60f225_oob.map.rpt)2783–2802及层级 CSV，Elapsed synthesis 132s。

| 资源 | 实测数量 |
|---|---:|
| RAM10 / DPRAM10 | 85 / 4 |
| FF / LUT4 | 10840 / 18363 |
| ADD / SRL8 | 1591 / 1164 |
| DSP48 / GBUFCE | 4 / 1 |

DDR 父 39 RAM 含桥子 17；CSI 11、frame_buffer 28、debug 2，不重复相加。实际 CSI 为 XML 选中的 5.15/FIFO1024/HS_BYTE70/core100/Discontinuous/PACK15，未换旁置 5.16。参考丢弃 RAW10 低位、未观察完整 metadata/error，当前 CSI 资源不是完整生产 NORM 的上界。原警告含 CRC 优化、未驱动 MIPI 输出、校准信号接地、gamma 异步读映射逻辑、8 条端口未连接以及 ser2par_v1 三条静态除零返回 x；功能影响尚未验证。

## Questa 与时钟边界

[C0 编译审计](C0-questa-final-result.json)记录本地 vmap/vlib、真实厂商原语及实际 DUT 的精确 argv/时间/退出码。[C0 DUT 日志](C0-questa-DUT-vlog.log)与[C2 DUT 日志](C2-questa-DUT-vlog.log)都在 CSI 保护区报告无可用解密 key，随后报两个保护区语法错误。没有 TB、激励、vopt、vsim/run 或器件校准，厂商库不是空 stub。C0 第 67 项 DSI 尚未实际编译，不声称通过。

C1 独立物理阻塞由现装官方文档 pt/doc/topics/hlp-id-clock-src-regional-global.html:225–229 确定：Ti35/Ti60 输出 0–3 为 global，#4 仅顶部/底部 regional interface。文件 SHA256 `AC8E357452224DE77C40464320A8A78E3A13E449977BA2371C541398C2D123D4`；pll_device_service.py:1042–1049 同样注明 Ti60 #4 fixed regional。批准固定 #4 同 net 的 gclk 候选不能实施；改 PLL 输出、分频或 core 来源是新的结构选择，尚未实施。本发现不等于 FPGA 或 DDR 算法路线不可实现。

[C2 clock 审查](C2-clock-and-simulation-scope-review.md)区分外部 DPHY byte、core 与 PLL 输出。SDC 的 USER_PERIOD 可按 25MHz 来源提出 40ns 修订，但外部 byte 频率未闭合；未把旧 100MHz 假设改成生成参数 70MHz 伪称正确，也未删路径或增加假异步例外。C2.clock-corrected 与 C3 按批准停止条件保持未执行。

## 输入、命令、审计与后续

92 manifest 保留批准前原字节及历史状态字段，当前授权由 approval-v1.2 和 Manifest 记录证明。源 92/92 匹配；C0 90 个非 XML/peri 输入字节不变。官方迁移 project XML 工具版本/序列化及 peri 工具版本、gen_pin 排序/15 个空 gen_pin、5 个空默认 dly_clock_name；[peri 审计](C0-peripheral-format-delta.json)确认 256 个配置元素及实际生成 pin 语义保持，[输入核对](C0-post-interface-input-check.json)保存所有摘要。没有改 Bank、PLL 频率、网络或保护 IP。C2 原 134/135 字节不变、XML 子元素保持的审计继续有效。

真实 flow 为 map、官方 debugger generation/merge、PT、pnr；未调用默认 compile/full 或完整 pgm。实际副作用与退出时间见[追加账本](side-effects.jsonl)。Questa 子任务终态后由 root 按真实 start/end 对账追加，不冒造先前 EXECUTING 记录。正式事件在原 session JSONL；本地审计例外只服务有限预检，不证明 PostgreSQL 健康，不授权整包业务。

[范围检查 v1.2](scope-check-v1.2.json)：bit/hex/bitbin/hexbin 为 0；正式 PROJECT_STATE SHA256 仍 `87BF105C9DA5C9304A3D7675520E1CA324D4CE51A055DA18FF3DA4B7665B2558`。未改原 HDK、正式数据库/状态，未联网/下载/安装或操作硬件。attempt、debug/PT/PNR/Questa 日志分别保存；旧报告快照为 RUN_REPORT-before-v1.2-terminal.md。

后续设计须处理实际 JTAG 连接选择、Ti60 可实现的 core 时钟、CSI 仿真输入和外部 byte 约束；整包资源与生产服务仍 OPEN。影响行为/接口/重要结构的改变按唯一 v0.2 §11.2 先形成具体修订再申请指定批准。旧限定审查绑定旧 hash，不声称已经审阅本报告新增终态。
