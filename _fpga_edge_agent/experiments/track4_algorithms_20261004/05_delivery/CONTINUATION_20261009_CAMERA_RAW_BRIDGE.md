# 2026-10-09：生产CSI四像素采集适配完成

本轮新增9份业务/验证文件（2个RTL、2个TB、独立Python参考、2个runner、Ti60F225工程和SDC），累计186份，不是186个模块。50份依赖不重复计自写。设计先保存/读回再生成，见planning/design-TRACK4-CAMERA-RAW-BRIDGE-001.md及J1/K；详细中文阅读说明见work/active/track4_algorithms_20261004/camera_raw_bridge/docs/README.md。

实际官方CSI TX编码→四lane→RX解码→生产128bit异步FIFO→RAW20两像素口，1080p一帧2073600像素全部10位/身份/坐标/顺序/标记精确；直接1080p两帧4147200像素亦通过。五个当前源码run共27终态、6222428像素独立参考通过，另一次holding旧pair的共同冷复位作废单列。21场景覆盖非法PPC/DT/VC/WC、短长行/提前帧末/额外行、rx_fault、正确/错误handle取消及显式discard、overflow隔离、像素clock停止、SOF同首有效拍、HS/VS同下降、帧末取消与复位重用。最低4×2和FIFO16/512/1024也分别覆盖；不是降低1080p目标。

MAP当前源Ti60F225/I3 exit0：14RAM10、1439FF、1394LUT4、0ADD/SRL/DSP，原生RAMREAD_UNKNOWN。24个上位非RAW10输入被裁掉的警告公开保留。组件SDC核心100/像素50MHz，未进行生产IO/CDC物理约束、PNR/STA/bit，不把宽内部接口当板级引脚。

新staging CAMERA-RAW-BRIDGE-COMPONENT-20261009-v1.1有250登记条目、59源（9自写+50依赖）、53份冻结输入及五次当前PASS证据。14份Manifest全部5507条文件逐SHA检查漂移0，116份已登记增量主工作源逐SHA核对漂移0。前70份基础批沿用已有证据，本轮没有重跑全部186份。

shape_complete/drained仅说明本地帧形状/前缀退休，reception_verified恒0；真实CSI CRC/迟到包错误closure、active C2完整等价、实际SC431HAI/模拟PHY仍未证。父capture_canny_axi的独立rx_close要求保留。板载2Gb/x16 DDR匹配动态参数模型缺口仍未解决，其他独立软件继续。

下一批先完成有限源/结果槽账本、原子发布/实际active冻结及退役引用，接显示预取与TMDS，再推进完整复杂识别与共享算术，最后收敛单一生产top、资源/吞吐、引脚/时钟、PNR/STA/最终bit。本轮真实CSI口与算法口的适配完成，完整摄像头→DDR→Canny→显示同一生产top尚未完成。

用户自主授权/本地审计继续，原HDK/安装/旧冻结包/正式DB/state不改，无网络/下载/硬件动作，目标ACTIVE；最终bit后停止硬件步骤。
