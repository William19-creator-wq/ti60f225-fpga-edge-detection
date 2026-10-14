# R1：整体连接、逐步人工观察与源码追踪

当前批准为R1 v1.1/ALGO-BL-v1.1，继承完整v1。先读控制面完整设计B/C/D，再读本页、窗口/算术实现说明，最后读各真实run报告；源码和测试分别解释数值与实际事件。

## 整体与局部交接

顶层`rtl/r1/r1_algorithm_top.sv`只提供clk_25m/key1_n/led0/led1。由reset_adapter产生同步core reset；supervisor提出FJ；source按完整快照提出FP；core形成FO/FS；observer接纳完整160bit记录；leds读取最后完成的CRC/身份/计数检查。所有数据路径同25MHz，取消只在通用core测试，外壳cancel固定0。

1. reset：测试先拉key1_n低至少4沿，再释放。观察reset_adapter.reset_release_stage1/2，第一沿释放stage1、第二沿stage2，核心随后看到同步复位释放。只验证软件波形，不签认板上按键。
2. START：观察supervisor.job_sequence及job_valid/job_ready。真实job_start锁source.job_snapshot，并把observer.crc_state设FFFFFFFF；这个沿不接RGB。
3. FEED：观察source.accepted_q/accepted_row和FP四标志。in_ready低时图样/坐标保持；实际FP握手才前进。source_last_fire是真实末组接纳，不能用候选EOF代替。
4. core：先看gray→window_before_median→median→window_before_sobel→sobel；两个窗口各自构建完整有限图。灰度/M/edge及中心坐标通过共同FO握手，不能从各流水级当前值拼成结果。细节见window-frame-implementation和arithmetic-implementation。
5. observer：FO真实接纳沿只锁record_hold并计data_pairs；后续160沿从bit159到bit0更新CRC。record_bit_index归0时使用shifted_crc，清busy；下一沿才可接下一记录。busy必须继续推进，即使source没有valid。
6. DRAIN/FS：源末组接纳后仍接FO。FE形成FS，等前缀记录CRC完成再消费；提前失败同样允许接，不等待N/EOF。真实终态记录包含code/三ID/in/out，不包含error_xy；后者由通用core测试另核。
7. TERMINAL：observer的终态CRC全部处理后产生terminal_crc_done/terminal_good；supervisor才开始下一job、ERROR或EXHAUSTED。最后CRC/tag/status/good快照在新job中保持；错身份/计数的原OK不得被重写成成功。
8. LED：led0只表示最后完整job身份/计数合格；独立黄金逐像素比较仍必须成功。led1用同域clock enable轮流读CRC位，不产生分频clock；25MHz观察外壳每组至少161沿，低速不代表生产显示fps。

## 文件次序与双向追踪

| 要求/接口/草图 | 实际文件与稳定符号 | 测试归属 |
|---|---|---|
| R1-REQ01/02，FE F0…F4/F2R | rtl/frontend六文件及各实现说明；model/frontend_reference.py | FT-01…11 / R1-T01 |
| R1-REQ03，IF01/06，OP01 | pattern_pair_source.sv：job_snapshot/accepted_q/accepted_row/rgb_at；r1_job_supervisor.sv：job_sequence/supervision_state/source_eof_accepted | R1-T02/04 |
| R1-REQ03，IF02/03/06，OP02 | result_crc_observer.sv：record_hold/record_bit_index/crc_state/shifted_crc/last_good | R1-T03/04/06 |
| R1-REQ04，IF04/05，OP03 | reset_sync.sv：reset_release_stage1/2；r1_led_status.sv：display_enable_count/crc_display_index | R1-T04/06/07 |
| R1-REQ04/05/06，OP04/05 | r1_algorithm_top.sv；project/r1_algorithm.xml/.peri.xml/.sdc；scripts/run_r1_build.ps1 | R1-T06…08 |
| 独立期望/执行/退出 | model/r1_pattern_crc_reference.py；sim/r1三TB；scripts/run_r1_sim.ps1 | R1-T02…05 |

模型/测试/runner已按批准范围生成并完成必要检查；实际证据为frontend_suite_006、r1_shell_005、r1_physical_005与bitgen_retry_001，不由表格存在推定。

## 历史实际检查前缀

- window_precompile_001：原厂EFX_RAM10与line_store/window编译，Errors0/Warnings0。
- core_precompile_001：六核心全部编译，Errors0/Warnings0。
- r1_precompile_001：12RTL加原厂模型全部编译、生产默认参数顶层vopt展开，两个阶段退出0/Errors0/Warnings0；尚非功能仿真。
- window_smoke_002：Questa实际W4/H3窗口，accepted/delivered/compared均6，numeric/protocol均0，RAM reads16/writes10，首输出−首输入5、末输出−首输入10。status=-1表示单元没有F0终态；不能改写成整帧OK。日志含onerror/onbreak宏使用警告，后续runner改用实际.do文件，不遗漏这些警告。

首次vsim许可失败退出4保留；启动进程没有继承已存在的User MGLS_LICENSE_FILE。后续只在当前runner进程继承现有用户设置并finally恢复，不修改持久环境、不读取或输出许可内容。窗口仿真成功是当前实测，不用历史GUI打开结果代替。

## 最终验收及观察位置

上述前缀之后，完整FE006的123/123和四1080pjob均真实通过，合计8,294,400像素、数值/协议错误0；R1外壳005两尺寸各69job/64配置、四258图样与typed/逐记录CRC通过。FE STATUS all_empty和九个真实cancel/reset阶段及恢复均检查。细节、失败保留和原始路径见frontend-verification、r1-verification。

Questa波形先打开sim/frontend/observations/wlf_readback_001/readback.md，沿实际列出的FT05与窗口B TAIL波形查看ready/valid、pending_q、RAM使能、phase、all_empty及恢复status。已保存真实采样不代用户理解；T41四角补验从sim/frontend/runs/border_discriminator_002/readback/corner-readback.json进入，对照旁路44/1与中值40/0。

Efinity打开project/r1_algorithm.xml，再读runs/r1_physical_005的物理报告与diagnostics/postroute_audit_001：Map/Interface/Pnr均0，3411 XLR/8RAM/0DSP，40ns setup35.381ns/hold0.063ns，内部无未约束端点。具体四pin、例外、告警和不能重新加载的工具SDC展示见efinity-operation，不为人工查看覆盖原run。

真实release-gate核全部必要结果及同源hash后放行；首次pgm返回0但空跑的记录保留，明确同run LBF输入后的bitgen_retry_001实际生成bit/hex。软件状态DONE_STOP_AFTER_BIT，产物与来源已登记在控制面artifacts/staging/ALGORITHM-R1-20261005-v1.1/artifact-manifest.json；完整中文交付入口为experiments/track4_algorithms_20261004/05_delivery/r1-software-acceptance-v1.1.md。正式状态/DB/硬件未改，未执行实体步骤；完整十一项仍未完成。
