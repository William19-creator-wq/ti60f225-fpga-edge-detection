# 2026-10-09：六源三结果帧所有权核心完成软件与映射验证

本轮新增8份业务/验证文件，累计194份，不是194个模块。源码在独立work/active/track4_algorithms_20261004/frame_owner，中文设计在planning/design-TRACK4-FRAME-OWNER-CORE-001.md（J1–J3及K），阅读说明在该单元docs/README.md。先设计/读回后生成，用户自主授权继续，无需逐项批准。

实际实现六源、三结果、latest/freeze独立保留、完整handle/Origin/CJ、单OFFERED发布、DISPLAY与最多两RETIRING、IO/producer/consumer未知时隔离、错误/迟到/重复归还不释放新代次、近64bitmax不回绕。冻结新OFFER还须同freeze source；APPLY保留视频已发生事实，真实视频路由屏障仍下一批联接。内部压缩表示用唯一不可变源槽重建完整身份和静态描述符，对外没有截短。

当前三个RTL run（生产1920×1080描述符几何873事件、4×2几何873事件、near-max17事件）和实际优化map.v+官方EFX_FF/LUT4的873事件，共2636命令独立租约集合/回复/状态/身份/holding审计通过，编译/展开/仿真0errors/0warnings。此单元不传像素，不将HD命名当作新增1080p像素链证据；前轮官方CSI及采集适配像素证据保留。

Ti60F225/I3 MAP实际9624 LUT4/2623 FF/0RAM/ADD/SRL/DSP。初版16773 LUT/5061 FF，LUT减少42.62%、FF减少48.17%。实际网表协议也通过，未用RTL替代mapped DUT；未跑布局后延迟/STA。工具冗余信号移除警告公开保存，没有latch/undriven/blackbox/error警告。最终整体资源不能把所有独立组件直接相加当作合成结论。

staging FRAME-OWNER-CORE-COMPONENT-20261009-v1.2有170条登记文件，8份自写源、2原生模型、1真实网表，9份冻结输入，4次当前PASS。15份Manifest全部5677条文件逐SHA漂移0；124份已登记增量工作主源核对漂移0。前70份基础批沿用历史实测，本轮没有重跑全部194份。

快照B/core影子A、NO_ACTIVE和首次源冻结是按接口合同驱动的TB事件，未参与实际视频域、VSYNC、CDC或真实预取器。六WRITING满池与D+R+R及单OFFERED拥塞实测；六不同角色同时满池没有在此TB重建；NO_SOURCE/ALREADY收据分支没有单独触发。继续实际显示原子路由/VSYNC/snapshot hold/退休与此账本联接，再完成预取/TMDS/同源overlay与标注、完整复杂识别/共享算术、全机资源/吞吐及单一top/pins/clocks/PNR/STA/最终bit。

真实2Gb/x16 DDR匹配动态模型、CSI CRC/迟到错误rx_close、活动C2完整等价仍未解决；不让它们停止独立软件推进，也不伪称真实闭合。整个目标ACTIVE。原HDK/安装/旧冻结包/正式DB/H0状态未改，无硬件操作；最终bit后停止硬件步骤。
