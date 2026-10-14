# R1 Efinity 工程、约束与分阶段操作

2026-10-04建页，2026-10-05实施更新；批准 AP-ALGORITHM-R1-20261004-v1.1，继承 R1 v1 D/E5 与 ALGO-BL-v1.1。只适用独立 R1 1920×1080 软件实验。阅读顺序：整体 R1 B/C→四引脚 D→本页约束及冻结→阶段日志→实际资源/时序审阅→成功后的 bit 登记。005已完成Map/Interface/Pnr及报告审阅；主审核验完整仿真后保存release-gate。修正首次Bit空跑原因后，独立attempt已实际生成bit/hex，结果见本页末尾。

工程入口 project/r1_algorithm.xml；可在 Efinity 的 File/Open Project 选择它，目标应显示 Titanium/Ti60F225/I3，SystemVerilog 2009，顶层 r1_algorithm_top。源码仅本 work 的六个 frontend 和六个 r1 模块；EFX_RAM10 由现装工具识别，不把仿真模型加入综合源码，不引入相机/DDR/HDMI IP。

## 引脚和实际时钟

| 顶层端口 | GPIO资源/球号 | 电气与职责 |
|---|---|---|
| clk_25m | GPIOL_P_08 / J2（package全名GPIOL_P_08_CLK1_P） | 1A，1.8V LVCMOS，单端GCLK输入 |
| key1_n | GPIOR_27 / P13 | BR，3.3V LVCMOS，板上10K上拉，低有效复位输入 |
| led0 | GPIOR_21 / N14 | BR，3.3V LVCMOS，普通输出 |
| led1 | GPIOR_22 / P14 | BR，3.3V LVCMOS，普通输出 |

以上来自获批四pin来源及现装 package XML 的 J2/P13/N14/P14 对照；peri 只新建这四项，不复制VF或整个摄像工程引脚。KEY输入pull_option=none，使用原设计明确的板上10K上拉。官方schema另要求global_unused_config，沿用原格式的未使用pin输入弱上拉默认，不新增其他输出。Interface Designer 中读回 GPIO mode、bank、电压、conn_type=gclk 及球号；最终必须读本 run 生成的 pinout/PT报告确认，表格不是工具通过证据。

SDC在 clk_25m 上创建40ns时钟，不引入PLL或虚拟100MHz。key1_n只到 reset_adapter 的两级异步SR（RTL低有效清零）端点；各get_pins必须恰好一个。官方现装帮助说明 get_pins 基于post-map名称，|是pin分隔符，llength可核collection；若找不到或多匹配必须失败并查 .map.v，不能用空pattern宣布例外正确。现装STA隔离查询已实际读回精确名reset_adapter/reset_release_stage1~FF|SR与reset_adapter/reset_release_stage2~FF|SR，且各SR对应网络key1_n；最终SDC采用这两个精确名，完整post-map扇入/时序仍须本次成功run审阅。

仅切 key1_n→这两个异步SR端点，stage1 Q→stage2 D、stage2→core_rst→算法/RAM路径继续计时。LED没有板外同步采样时钟，是明确静态异步观察端，SDC只对led0/led1输出端点列false_path；不切整个core_clk，不添加multicycle或随意0ns外部delay。内部setup/hold、同步复位/数据路径、clock覆盖及告警须实际审阅。

## 冻结和阶段操作草图

run_r1_build.ps1是唯一新构建入口，位于scripts。RunId只允许字母、数字、下划线与短横线；每个新run位于runs/RunId。先保留本次12份RTL与3份project输入的快照及SHA，再调用工具。原HDK、原工具文件和旧run不改、不清理；同RunId只续未执行阶段，不覆写已有日志。snapshot保存不可改输入，flow保存工具可更新的工作副本，避免工具修改project运行属性破坏冻结证据。

1. Prepare：核有效批准、设计/基线hash、本work与现有ASCII别名关系、12份源码/三个工程文件存在；建立唯一run并冻结输入。
2. Map：只调用现装efx_run.py的map，保存完整日志/退出码。功能测试可以独立仍在进行；这时只有工具检查状态，不宣称功能PASS。
3. Interface：Map成功后生成接口，核四pin/GCLK/电气报告；保存真实日志。
4. Pnr：Map及Interface成功后布局布线并取得工具自身STA报告。检查reset精确端点、有效内部clock覆盖、资源和保持路径，工具退出0仍须实际报告审阅。
5. Bit：仅当数值/协议/生产四job全尺寸/外壳回归全部必要结果通过，而且绑定同一冻结源码、当前run工具审阅通过时执行pgm生成bit/hex文件。pgm是此处的文件生成阶段，不调用program、硬件下载器或调试器。生成后hash和staging登记由Root控制面完成；本runner不伪造硬件状态。

Bit还须明确把输入绑定到同run的flow/work_pnr/r1_algorithm.lbf：先按physical-audit中已核SHA读回原文件与审阅副本，再传source及dest；不让工具从新建空work_pgm猜输入。首次005误给空work_pgm，原厂脚本记录“Flow skipped: Bitgen was not executed!”而返回0，Bit.no-artifact.json明确登记缺产物失败。修正保持17份冻结输入与release-gate不变，仅新增-BitAttempt bitgen_retry_001，将start/result/stdout/stderr放到bit-attempts/bitgen_retry_001，原Bit四文件不改。调用前bit/hex必须不存在；调用后两份均须存在、字节数大于0且保存SHA，退出0本身不够。工具会改写主flow log，原PNR完整log已保存在005的隔离审阅副本，补充记录关联原SHA。

现装 efx_run.py 的compile/full会包含pgm；本runner不采用这些快捷flow，避免必要验证未通过先产生bit。现装工具环境按本地bin/setup.bat只对子进程设置；EFINITY_USER_DIR_INI必须是现有本地文件，QT插件与平台目录按原setup引用。许可沿用本机原配置，不读取或打印许可内容，不安装、不联网。实际命令、输入hash、结束/退出码由run记录；XML/peri可能被工具更新的运行属性逐阶段另记before/after hash，最终物理报告仍须读回；失败保存日志并停止该阶段，不接后续bit。

以下是获准启动条件满足后由Root执行的示例，r1_impl_001仅示例RunId，本页没有执行这些命令。第一行创建冻结；后续行只能在相应前序成功后逐行执行，Bit还须通过下述真实gate。

```powershell
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_impl_001 -Stage Prepare
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_impl_001 -Stage Map
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_impl_001 -Stage Interface
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_impl_001 -Stage Pnr
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_impl_001 -Stage Bit
```

GUI人工观察顺序是：Questa波形核ready/valid停顿及伴随数据→Efinity层级核两窗口/8个RAM及三个算术流水→Interface pinout核四球与电气→post-map查两级SR精确名及扇入→STA读setup/hold/内部未约束路径→确认全部必要结果后登记bit。本软件批次不安排实体下载或签认板上现象。

Bit读取同run的release-gate.json。Root只在实测完成后汇总schema_version=1、批准/基线/设计hash，frontend的FT-01…11与四种median/kind组合各完整1080p结果，r1的R1-T02…05/四图样258方图/64小图job/CRC检查，以及implementation的资源、四pin、例外和setup/hold检查。frontend.manifest_path/result_path、r1.result_path及implementation的pin_report_path/sta_report_path/map_report_path各与SHA实际重新核对。source_hashes的path相对work根；12RTL、参考与原厂模型必须对应冻结/实际文件。implementation另列project_sha256/peri_sha256/sdc_sha256及ram10_count=8/dsp_count=0/xlr_count≤8000。这个gate保存真实证据关联，不代替oracle或创建PASS。

## 实际结果和可读回证据

最终run为r1_physical_005：17份当前/冻结文件逐件hash一致，原厂RAM仿真模型也一致；Map、Interface、Pnr实际退出0，完整timing.rpt在40ns约束下setup余量35.381ns、hold余量0.063ns。packed place.rpt计3411/60800 XLR、8/256 RAM10、0/160 DSP、1 GBUF、0 RBUF，满足R1的8RAM/0DSP/≤8000XLR预算。map.rpt计2305FF、1886 LUT4、575 ADD、78 SRL8；综合与packed XLR是不同计数。PT及pinout实际确认J2/P13/N14/P14、电压、KEY无内部上拉、LED驱动4；PLL/MIPI/LVDS无实例。工具列四个clkmux资源槽，但只分配一个clk_25m输出，不能解释成四个时钟。

同run的diagnostics/postroute_audit_001在完整布局布线副本上运行原厂efx_sta，实际退出0。all_registers collection=2391、all_clocks=1；2391不是FF数量，等于本设计2305FF+78SRL8+8RAM的对象数量。原厂全局check_timing报告no_clock=0、unconstrained_internal_endpoints=0、multiple_clock=0；无外部delay的KEY及两LED明确归在三项已批准异步例外，未另有缺约束端口。精确SR各匹配1且连接key1_n；Q1→D2 setup/hold为39.527/0.124ns，Q2→core的12条定向报告最小35.642/0.403ns，Q2→全部8RAM定向报告最小35.916/0.803ns。定向报告证明同步复位路径仍计时；整个内部覆盖以全局报告为准，不能把12条定向报告说成逐一枚举了全部寄存器。

实际布线trace是flow/outflow/r1_algorithm.troutingtraces，route.out L50写明文件名；458582字节，原输出与审阅副本SHA均为99757F036FA5C00A0C775E55B9CDEF650A9F454F64CE2ADB715DEC1E8B663093。audit.log显示digest8937495032920176369及Successfully reloaded trace。arguments中的r1_algorithm.route并不存在，不作为输入证据；真实vdb/place/interface/SDC/trace/primplace/net_proto/io_place/lbf共9对均实际hash一致。执行Tcl首行沿用004注释，真实绝对参数、输入和报告属于005。原厂write_sdc产物把四条false_path拼在一行，禁止重新加载；正式有效输入始终是snapshot/project/r1_algorithm.sdc，SHA0F06ED5E8B4023837268E237E6C743DA964712EA3580E1C262C6B8711DE5E1D5。

综合42条warning分为20条EFX-0200冗余函数/循环临时量及有意不用的窗口标志、低坐标位，22条EFX-0657小型固定流水数组映射逻辑；实际两窗口仍各4RAM。PNR主日志261行无ERROR/WARNING。现有ASCII junction解析回中文原路径，wrapper每阶段保留non-ASCII提示，没有屏蔽。数值/协议结论另由完整仿真支撑：Root实际验收frontend_suite_006共123/123 PASS，四1080p作业每项1036800 pairs、合8294400像素且numeric/protocol=0；r1_shell_005四种258图样及4×3/8×5外壳各69job、CRC无误。release-gate已按真实结果保存并读回，SHA EB1AC16F3014146FF6B473B63C581EDA052B9EE3D41E94AA390C547FA55C9FF5。

实际成功生成记录位于bit-attempts/bitgen_retry_001，重试仅调用pgm文件生成。明确输入flow/work_pnr/r1_algorithm.lbf为480729字节、SHA22DE3B96DDAD6C2A3C6FDA82F418A83AE1F00E1A520E729161004F69DF134428。tool log写明Using source file、Using periphery source file、Generating bit file和Finished generating hex；exit0、artifact_check_pass=true。flow/outflow/r1_algorithm.bit为1731456字节，SHA F55F973B54355A70B65F914448F8A6E6E4431C672312DF954D3042B0DCFFB321；r1_algorithm.hex为1731516字节，SHA06907FBFCD7824AA387A3A84914F46603483FD6202E18B793A004420EDF560AD。有效操作为：

```powershell
pwsh -NoProfile -File C:\Users\34528\FPGAEdgeLinks\Work\active\track4_algorithms_20261004\r1\scripts\run_r1_build.ps1 -RunId r1_physical_005 -Stage Bit -BitAttempt bitgen_retry_001
```

上述attempt已经执行，禁止再次运行同名attempt或覆盖产物。原首次Bit四记录保留；physical-audit.json是生成前不可改记录，pgm后来改写主flow/outflow/r1_algorithm.log，其21466字节原PNR内容仍完整保存于diagnostics/postroute_audit_001/outflow/r1_algorithm.log，SHA114DACE0D9F25B260B5F9985BA1EB6058E06984B426756DDE5A8D1537F5DCD54。后续补充记录关联原副本及真实pgm日志，不把历史audit中的主log hash当成生成后当前文件hash。staging与最终控制面登记由Root处理；没有实体program/下载或板上验收。本批通过范围仅是R1灰度/中值/Sobel独立软件验证，不能据此宣布完整11项完成。

旧失败run全部保留：001/002的Map0、Interface1分别是MIPI和PLL空registry缺失；按本机Ti60 LED_8bit_Test.peri.xml与官方peri_design_db.xsd只补五个零实例空registry，未复制参考功能或pin。003 Map0/Interface0/Pnr1是SR regexp零匹配，隔离实际查询后改用精确名。004 Map0/Interface0/Pnr1是把check_timing报告命令放在SDC加载阶段；005将报告命令移到数据库加载完成的独立审阅Tcl，约束仍仅40ns及四项精确例外。这些配置内部修正不改批准数学、接口或电气边界，不修改旧快照与失败日志。
