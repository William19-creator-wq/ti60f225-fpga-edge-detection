# 分类状态缓存：真实RTL与操作入口 v1.1

2026-10-08。依据持续软件实现授权，实际实现8份源码/参考/TB/脚本/组件工程文件；最新版state_cache_suite_004、state_cache_small_001与组件state_cache_map_004通过。真实DDR/生产顶层/PNR/STA/bit尚未执行，组件内部line512端口没有分配为板卡引脚。

## 先整体，再交接与局部

[整体v1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-CANNY-STATE-CACHE-001.md) → [共同取消修订v1.1](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-CANNY-STATE-CACHE-001-v1.1.md) → rtl/state_cache_ram16.sv（同步RAM）→ rtl/canny_state_cache.sv（布局、lookup、读/capture、claim、WB/FILL/FLUSH）→ model/state_cache_reference.py（独立字节图）→ tb/tb_state_cache.sv（实际RAM/line/claim事件）→ 两运行脚本。

路径：配置/base/job → 一个逻辑op → four-way lookup → 实际RAM RE/下一沿capture → READ或共同claim WE → held回应。miss路径先把dirty旧64B读齐并真实写回，再完整读新线，32沿安装完才valid。queue在cache claim同沿写entry，HY下一次push只确认，不能追加第二份。

4way×32set×64B=8KiB缓存，拆8块512×16；满1080p分类图实际仍约518400B外存。index21，word=i[7:3]/slot=i[2:0]，tag=i[20:13]/set=i[12:8]；base/端点先扩33bit。新配置只能旧job关闭后接；不清RAM数据，以valid隔离未知旧内容。

## 已执行证据

- state_cache_suite_004：两个1920×1080地址域job，11528逻辑操作；最终16200条64B外存线与独立字节图相同；2514常规原子claim，另4次故障/取消场景旧claim均准确计账，总2518。
- 覆盖i7/8、255/256、4095/4096、N−1/N，四way同set替换、同字不同slot更新、重复claim、完整flush/换base与job，随机ready/回应停顿。
- 十类私有取消：错ID、阻塞claim、claim同沿真实fire、已提出未接RPC、待回应、半线安装、held回复、真实错误优先、旧WORD/WB RE capture；已公开RPC不撤回，内部共同作废与真实服务错误分开由rsp_aborted诊断。
- 合法最高地址端点恰2^32、非对齐/越上端拒绝；安全读写错误、未知drained隔离、不覆旧job、半线安装共同reset恢复通过。共同reset模型不代表实际DDR暖复位安全。
- state_cache_small_001：6×5最小域、两个job/8464操作，完整64B物理线中N之外padding保持0；同样十项取消及错误/地址检查通过。
- 组件MAP：Efinity2026.1/Ti60F225/I3，实际8 EFX_RAM10（每块16bit读/写、同步读），2097 FF、6665 LUT4、79 ADD、零DSP。合成循环变量冗余信号警告为消除integer迭代索引；实际RAM/meta/linebuf保留。资源是综合结果，不能直接称布局后XLR总数。

首次Map_001因runner缺本机EFINITY_USER_DIR_INI失败，_002起已补齐；原日志保留。v1 suite_001/002和Map_002保留，取消修订后的最终输入由suite_004/Map_004绑定。未覆盖旧失败证据。

## 人工查看和复现

Questa先看cfg/job/base与req/rsp fire，随后selected_set/way/tag、valid/dirty、WORD_READ/WORD_CAPTURE/RAM RE/Q，再看claim_valid/ready与ram_we同沿，最后line_req/response和FLUSH。取消时检查abort_job_id、abort_sticky、rsp_aborted及held保持；未知drained看QUARANTINE。

组件Efinity工程project/state_cache_component.xml可打开Ti60F225/I3及两RTL；state_cache_component.sdc仅预综合100MHz目标，不是已布线时序证据。当前707输入/644输出多为内部接口，不是最终芯片引脚设计；总工程内部连接后再运行真正接口生成/PNR/STA。

脚本run_state_cache_sim.ps1选新RunId，Small开关运行最小尺寸；run_state_cache_map.ps1需指定已PASS的SimulationRun和新RunId。每次记录原进程/参数/退出码、快照和SHA，不覆盖历史。

## 后续交接

[外存queue设计](D:/大三/FPGA_verilog/_fpga_edge_agent/planning/design-TRACK4-CANNY-WORK-QUEUE-001.md)已经读回，下一步实现两追加bank/确认/forward/prefetch/后端仲裁，接cache+HY，再接R2。64B RPC还需实际共享仲裁/128bit AXI bridge及匹配DDR动态模型。SC-T06…08完整Canny组合、生产布线时序和真实DDR仍NOT_RUN。理解验收待用户实际反馈。