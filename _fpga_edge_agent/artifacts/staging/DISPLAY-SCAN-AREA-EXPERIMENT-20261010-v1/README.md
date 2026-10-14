# 显示组合面积策略实验

先读inputs/design-TRACK4-SCAN-AREA-EXPERIMENT-001.md的整体、交接和中文操作，再读scripts/run_scan_area.ps1的输入核验→源快照→XML单参数差异→真实进程→结束核验，最后看runs/实际资源报告。只有1份新功能运行脚本，没有新增生产RTL；37份输入冻结，原display_scan的源码、已完成HD仿真、原MAP及注册产物只读。

生产1920×1080的scan_hd_001已真正完成并通过独立参考。本实验保持全部RTL和SDC字节，只在独立flow XML中把综合mode从speed改为area或area2。两份XML将mode恢复speed后的规范化内容相同，差异文件保存原和新XML SHA。Ti60F225/I3、100/74.25MHz组件约束、retiming0/seq_opt0和其余工程设置不变。

scan_area_001实际Efinity MAP exit0、无超时：34415 LUT4、23325 FF、835 ADD、19 RAM10、1 DSP48、0 SRL8，由报告和实际网表原语核对。原speed为35502 LUT/23324 FF，其余相同，area减少1087 LUT（3.06%）、增加1 FF。它不表示更快；未执行这个新网表动态、PNR/STA或bit。26个工具warning和原err日志全部保留，未屏蔽。32份本次源/快照结束SHA全相符，configuration-diff.other_xml_equal=true。

scan_area2_001同一实际进程正常完成、exit0/无超时：35502 LUT4、23324 FF、835 ADD、19 RAM10、1 DSP48、0 SRL8，和原speed资源完全相同，未获得节省；运行器及报告记录实际约1274秒综合墙钟。没有因观察间隔重启或删掉零收益尝试。它也有26项warning、32源/快照结束SHA匹配、XML其它字段相等。两个模式各自真实报告/网表都保留；只有area在本次组件面积上有收益，是否作为最终设置还需全top动态和PNR/STA，不立即宣称更快或整机已装下。

运行入口：既有PowerShell7执行scripts/run_scan_area.ps1 -RunId 新名称 -Mode area或area2，已用名称拒绝覆盖。输入来自原已验证MAP/HD，缺源或SHA漂移在启动前报错。最终单FPGA总资源/速度、摄像头/DDR/root/复杂识别、物理CDC/引脚/布局时序与最终bit仍继续；本实验不能代替这些证据。正式PG/H0/状态及硬件不改变。
