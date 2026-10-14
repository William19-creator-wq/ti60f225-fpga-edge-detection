# 2026-10-09：官方CSI RAW10实际数字接收通过

本轮完成3份自写验证输入：TB、独立Python参考、运行脚本，累计177份业务/验证文件；不是177个模块。官方ModelSim依赖47份和原VGA源单列，不重复算自写代码。

csi_raw_small_005的20×8两帧80组/320像素及csi_raw_hd_001的1920×1080一帧518400组/2073600像素全部10位、数量、顺序一致。三时钟control100MHz/byte约70MHz/pixel50MHz，真实官方TX编码→四laneLP/HS→真实官方RX解码，没有stub。有效拍实测PPC4、上24位0、DT2B/VC0/WC2400/HSVS1，没有未知字段。原short字段在payload期间也为2400，不能据它直接取当前帧编号。

本轮定位并修复测试脚本的-GWIDTH覆盖所有同名参数的问题。它破坏了IP内部递减WIDTH的合法递归，失败来自脚本，不称原厂模型有错；改用唯一PROBE_WIDTH/HEIGHT/FRAMES，完整官方源码实际展开、fatal出口、动态仿真和独立审计通过，原厂保护体未改。失败001…004保留，005/HD当前源绑定后登记。

输入修订v1.4有56份冻结来源，含官方RX/TX XML中ModelSim完整fileSet；活动编译/源清单51份。新staging包CSI-RAW10-MODEL-PROBE-20261009-v1.4有186登记条目。此次13份组件Manifest共5257条文件重新逐一SHA检查，漂移0；20份前批新源和本轮3份源实核。本轮没有伪称重跑全部177份或全部旧104份工作源，旧证据保持。

阅读：planning/design-TRACK4-CSI-MODEL-PROBE-001.md（J1…J4）→work/active/track4_algorithms_20261004/csi_model_probe/docs/README.md→TB公开端口/图像公式/源关闭→独立参考与三域日志→runs两次当前PASS→staging冻结副本。

这次是软件模型证据，没有新增FPGA生产RTL、综合/PNR/STA/bit；也未证明活动C2嵌入体完整等价、真实SC431HAI/模拟PHY、可选pixel sideband、CRC故障归属、接收closure。正常输出末payload33053670ns、像素VS下降33124890ns相差71220ns，只是观测，不等于闭合证明。

接下来依据实际四像素RAW10口继续采集适配与CDC/源写整合，同时补错误及帧末归属；继续帧管理、冻结恢复、显示/TMDS/标注、完整复杂识别与算术复用，最终收敛整机资源/处理时间/生产top/引脚/时钟/PNR/STA/bit。板载2Gb/x16 DDR匹配动态模型缺口仍未关闭，不阻止其他代码推进，不降低1080p或原识别要求。

用户自主授权、本地审计继续；不改原HDK/安装/冻结包/正式DB/state、不联网或安装、无硬件操作。完整目标ACTIVE，最终bit后停硬件步骤。
