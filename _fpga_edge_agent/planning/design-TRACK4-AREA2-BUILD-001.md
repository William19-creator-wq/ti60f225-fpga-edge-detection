# TRACK4-AREA2-BUILD-001 v1

2026-10-12，精简构建配置卡，READY_FOR_REVIEW。沿用用户自主继续整机编译与本批本地审计授权，不假称新增逐版人工批准；本增量未执行仿真、安装、网络或硬件操作，沿用人工下载闸门。

- Goal / Current / Gap：061packing72282、062packing72006均超过Ti60容量60800；062实际56830 LUT/22893 FF/230 RAM/155 DSP，代码组合优化仅节省276 XLR。需要更有效的选择树映射及后续结构收缩，不能靠新seed或假报资源通过。
- Scope / Baseline：只将独立work副本主工程track4_board.xml的唯一synthesis param mode从area改area2，保留原UTF8 BOM、XML节点顺序、131 design_file、Ti60F225/I3、引脚/clock/SDC、retiming、所有其它synthesis/PNR/PGM参数。当前XML SHA2CE48ADE7A0717FD8755927C35ED69BA51EE7DDB317E30FFE1806B989F07FDA5。同时整合另卡TRACK4-CIRCLE-WORD-CONSTANTS-001 v1的三份已读回候选；总四份实际输入变化，单独保留其before/diff/hash，不冒称能分离两者收益。
- Source事实：实际读取本机Efinity2026.1.132的bin/efx_map_options.xml，mode合法选项包含area2；doc/topics/syn-options.html正文说明area2采用有助于优化大型多路选择树的方法，area优化面积；cli-map-opts.html列area2。不是网络推断，不下载工具，不修改安装目录。
- Interfaces / Language：配置变化不改RTL逻辑、公开数值/时钟周期或器件接口；工具可改变实现图、资源和延迟，仍必须全map/interface/PNR/最终setup及hold检查后才生成登记可下载bit。不能用综合预估替代实际容量或STA。
- Steps / State：保存当前XML before→仅精确替换mode属性一处→实际diff与XML parse读回→与三RTL一并保存adoption→新run063完整重新map，不reuse mapping，不动062或031冻结源。一次真实测量后根据资源证据决定后续结构方案，不无限同配方重跑。
- Validation / Trace：REQ保留现有完整功能与引脚→唯一map mode参数及既有RTL静态读回→输入hash、工具日志、物理packing/路由/最终STA/bit；检查一处替换、同schema节点顺序/131源码、scope/version/base/before hashes。无新TB或功能脚本。
- Failure / Rollback / Completion：若工具拒绝area2或所得实现更差，恢复仅mode到area，保留失败run；若仍超容量继续收缩共享控制/数据通路，不删圆/矩形路线或降低1080p来改写成功边界。063通过前031仍唯一现成下载版本；实物未下载，无硬件通过证明。正式数据库/硬件状态与原HDK不改。
