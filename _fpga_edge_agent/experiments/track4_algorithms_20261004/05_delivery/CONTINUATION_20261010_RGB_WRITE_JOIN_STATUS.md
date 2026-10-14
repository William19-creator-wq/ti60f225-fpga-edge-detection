# 2026-10-10：实际RGB写帧到共享AXI写链路

完整目标仍是1080p/Ti60F225/I3/SC431HAI、现有板卡资源、五基础与六高阶，允许板载DDR，bit之后停止硬件步骤。本轮确有新增实现及真实运行结果，完整目标尚未完成。

本轮新增rgb_axi_write_join组合核心、TB/公开端口observer、独立数值/事件账参考、两个运行脚本、XML/SDC，共7份自写业务/验证/工程文件。四个实际RTL及厂商原生RAM模型原样复用；11份基线已冻结。此前Efinity查看请求准备了23份相同hash查看副本，但窗口保持最小化，未验证GUI工程页已打开；查看副本不计新增算法代码。

五个正仿真共77场景，通过真实编译/优化、真实fatal拒绝、RTL和独立审计：34×19及4×2各32场景，512×2和510×2各6帧，完整1920×1080一帧。HD核对全部1036800像素对/6220800RGB字节/97200camera写RPC，加4096并发算法写，总101296 AW/405184 W/101296 B；实测2937927 core cycles是在数学AXI byte slave调度下，未证明真实DDR或整机FPS。

cancel、四种输入错误、整帧地址容量/拒绝、CFG/DONE holding、错BID/晚旧B、live backend停用、算法Q时camera PUBLIC未接纳借用、safe DONE受另一Q影响及可信共同cold reset联合场景均有实际公开事件/逐沿保持断言。错误已发W保留物理内存副作用；UNKNOWN禁止伪造safe closure。公共observer不读取内部bank/carry/packet作为期望。

Efinity join_map_001在XML parser拒绝阶段exit1，原因是top_vhdl_arch出现在design_file列表之前，原始失败目录保留。XML1卡先读回，只修工程顺序，9份功能源不改。join_map_002实际MAP exit0：2600 LUT4、2075 FF、55 ADD、4 RAM10、0 DSP/SRL；网表/报告一致。新增组合层只有一个rejected_cfg~FF，actual桥的512 snapshot FF没有重复。14综合警告已分类：四态guard折常量、无用信号/循环变量删除、小descriptor数组映射逻辑；不冒称亚稳态检测或无警告。

组件登记到`artifacts/staging/RGB-AXI-WRITE-JOIN-COMPONENT-20261010-v1`，源码与当前5 suite/12源工程快照、日志和所有新登记内容SHA核对完成，compiled Questa libraries排除。原HDK/安装/旧登记包只读；正式数据库NOT_CONFIGURED、H0及TASK_LEDGER未改，继续沿用获准本地审计例外。没有硬件操作、此组件没有PNR/STA/bit或mapped组合动态证明。

阅读顺序：planning的RGB join v1总体/端口/中文操作→XML1卡→work/rgb_axi_write_join/README→rtl组合→四deps→model/TB→runs与resource-result→staging manifest。前向及反向追踪定位在README第6节。

下一项实际工作是统一camera写、algorithm混合读写及display读的生产hub，保留旧回执/物理尾部和UNKNOWN所有权；连接实际生产算法与帧权限/发布/Freeze/Offer/Apply/Retire。需要在设计中处理跨read/write全局隔离：不能把另一通道Q直接变成backend_enable0从而损坏旧安全承诺，不能让已公开camera packet被撤回。

仍未完成：生产帧控制/FrameRef authority及最坏DDR/display QoS、CSI CRC/晚错误/rx_close/溢出正确性、原范围复杂识别、匹配2Gb/x16动态DDR模型/PHY、STATS等整机共享资源及性能方案、最终生产top/引脚/CDC/PNR/STA/bit。缺DDR资料不会阻止上述其他软件工作，不能用本包通过代替整个FPGA完成。
