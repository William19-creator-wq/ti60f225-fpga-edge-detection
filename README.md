# Ti60F225 FPGA 图像处理与 DDR 帧缓存

更新日期：2026-10-30。当前功能版本：2026-10-29 DDR 帧缓存完整版（完整 M5 Canny 已启用）。

摄像头采集 → Efinity 官方 DDR3 Soft Controller 5.16 → 完整帧存储 → 按帧读取 → 图像处理 → HDMI 1920×1080@60Hz。

当前已由用户实板确认：M0实时彩色与M5 Canny持续更新；冻结与恢复；冻结后同一源帧调参；最近60帧回放、自动暂停、前后逐帧；A/B双帧彩色比较及退出恢复。A/B各960×540，上下留黑边。

- [操作、地址分配与验收状态](docs/DDR_FRAMEBUFFER_2026-10-29.md)
- [Efinity工程入口](projects/ti60_ddr_framebuffer_20261029/ti60f225_oob.xml)
- [完整匹配源码压缩包](artifacts/ddr-framebuffer-20261029/Ti60F225_DDR_Framebuffer_source.zip)
- [当前比特流](artifacts/ddr-framebuffer-20261029/Ti60F225_DDR_Framebuffer.bit)（下载原始文件后，使用Efinity Programmer执行JTAG下载）
- [SHA256](artifacts/ddr-framebuffer-20261029/SHA256.txt)、[构建与硬件清单](artifacts/ddr-framebuffer-20261029/manifest.json)、[用户实板确认](artifacts/ddr-framebuffer-20261029/hardware-observations.json)
- [ReadAhead 2026-10-28 回退比特流](artifacts/ddr-framebuffer-20261029/Ti60F225_Canny_ReadAhead_20261028.bit)

开发板Ti60F225 DemoBoard V4，摄像头SC431HAI。工具Efinity2026.1.132，官方DDR IP版本5.16。使用板载256MiB DDR3，RAW8保存1920×1080完整图像，64个2MiB源帧槽，保留最多60个完成历史帧；约30fps时片段约2秒。断电或重新下载后重新采集。

三个按键：模式键短按切M0～M5；长按约0.8秒开关菜单；菜单内短按选I0～I6，＋／－调整。I2的P0/P1/P2/P3对应实时/冻结/播放/暂停；I3逐帧，I4/I5选择A/B，I6开关比较。详见操作说明。

构建资源54418/60800 XLR，160/160 DSP，252/256 RAM；最终17组setup与17组hold均通过，最小裕量0.072ns/0.026ns。比特流SHA256：`a8dec524877131305c29e95d43f6a45aa15ffb2b56a07084999d0f6b7d55cca9`。

功能确认、构建时序、性能稳定性分开记录。尚未完成全部P5定量验收，包括受控60秒FPS及基线90%对照、10分钟稳定性、独立高低地址BIST等；屏幕统计字段也未覆盖原计划全部内容。五小时期限未达到。用户接受当前版本并要求停止优化；未完成的遥测草稿、M5_OFF诊断版和失败构建未作为本次推荐版本上传。

解压源码后，用Efinity打开工程XML。部分历史辅助脚本含原开发机路径，不是通用构建入口；不要执行旧的一次性迁移脚本。第三方IP仍需合法安装的Efinity环境，仓库不含工具安装包、个人许可证或凭据。已有历史和第三方权利说明保留。

[更新前的README存档](docs/history/README_before_DDR_20261030.md)。历史文档中的“当前版本”仅指其当时日期，以本页为最新入口。
