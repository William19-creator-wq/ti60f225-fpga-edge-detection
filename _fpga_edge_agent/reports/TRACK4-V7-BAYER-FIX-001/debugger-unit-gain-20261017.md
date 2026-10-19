# BAYER-FIX 现有 VIO 等增益对照配置

记录时间：2026-10-17 19:27 +08:00。

用户明确授权：“你來配置吧”。本次范围为现有 Debugger 的三路增益配置，不包含重新下载、逻辑分析仪采样或 RTL 修改。沿用本批本地审计例外，未写正式数据库或项目状态。

通过 computer-use / @oai/sky 操作 Efinity Debugger，载入 C:/Users/34528/FPGAEdgeLinks/Work/active/track4_v7_bayer_fix_001_20261017/debug.json。原生文件对话框首次不接受正斜杠路径，换为 Windows 反斜杠后导入成功。

Debugger 识别目标为 1 - 0x10660a79，USB 为 Quad RS232-HS (0403:6011)。19:21:42 连接 USER1。连接后 VIO 显示初始值 r_gain=0118、g_gain=00ff、b_gain=015c、gamma_sel=0；其中 b_gain 是本次界面观察值，不能用配置文件预设值替代。

逐项双击 Value，输入十六进制 0100，按 Enter 提交。最终三项均显示黑色正常字体 0100，已退出紫色斜体待提交状态；gamma_sel 保持二进制 0。没有启动 Run、没有重新烧写，也没有更改源码或 debug.json 文件。连接后的 Console 未出现新错误。

本记录证明 UI 提交已完成，不替代独立硬件探针回读；当前 bit 身份仍沿用用户对候选文件的反馈，未重新编程核验。画面是否仍实时变化、偏紫是否减轻，等待用户观察。不能据此认定白平衡已校准或偏色已修复。
