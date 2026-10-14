# 连续RGB源帧读回 v1

按planning/design-TRACK4-RGB-FRAME-READER-001.md、基线RGB-FRAME-READER-BL-20261009-v1（4份输入）及持续自主授权实现。阅读整体接口→rtl的两个完整holding/cursor→取消与公开FP→独立参考/TB→工具证据。没有改旧源码、HDK、DB或硬件。

中文草图：每条64B read先预约完整512bit槽，两个明确寄存器保持immutable返回；FIFO head/tail、cursor每准备一pair加6。cursor60/62时跨line合并两槽，58时恰吃完当前槽，行间没有另插padding。源低地址R/G/B还原canonical RGB48，再用旧x/y/ordinal构造FP74={bad0,EOF/EOL/SOF,y,x,RGB}。prepared与真实output分别计数，公开FP是完整快照，line用尽可回收；FP必须消费才闭合输出借用。

取消停新预取/准备，保持旧REQUEST和旧FP；旧read回执被明确DISCARD一次。安全memory ERROR优先cancel；unknown保留owner，禁止safe done及新job，外部共同安全rst才恢复。正常只输出P pair，padding不变像素；最后FP实际接收及所有公共read关闭以后才清私有padding槽并done。

最终运行全部PASS：reader_small_001（34×19、6模式、10协议、5取消、safe error/unknown、cursor60/62各80次）、reader_minimum_001（4×2）、reader_6x5_001（6×5）、reader_bank_eof_001（512×2）、reader_hd_001（1920×1080）。完整HD的1,036,800个FP pair和97,200条line逐位一致；独立参考按逐像素数学造FP，没有复制cursor FSM。

reader_map_001实际Ti60F225/I3组件MAP：0 RAM、1384 FF、2058 LUT4、26 ADD、0 DSP。100MHz SDC为目标；没有此组件的生产PNR/STA/bit。两个512bit holding是真实FF，未把它们谎计为RAM；实际网表无RAM原语作为0登记证据。

复跑scripts/run_reader_sim.ps1指定新RunId，可Width/Height或FullHD；run_reader_map.ps1引用通过且hash相同的SimulationRun；project/rgb_frame_reader_component.xml在Efinity打开。runs中的source-manifest、reference-audit、actual-results、FP文件与日志可逐项复核。源grant不改写及完整SourceOrigin/DSscope pin由外层承担；后续采集→AXI→真实reader→Canny组合正在实现，真实PHY和FM发布仍另外验证。
