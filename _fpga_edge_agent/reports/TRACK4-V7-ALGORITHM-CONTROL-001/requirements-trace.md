# 实现与验证追踪

当前RTL仿真通过；构建状态见checks.json，上板状态见delivery.json及后续硬件记录。

| 要求 | 实现 | 验证证据 |
|---|---|---|
| C1 全帧七模式与按键循环 | v7_algorithm_control / video_pair | control-result；sim-small/hud；sim-full的GRAY、MEDIAN、DIFF三帧 |
| C2 同帧同坐标差值×8饱和 | video_pair.display_pixel | Python数值参考逐像素；small/full；fault回退 |
| C3 阈值、消抖、饱和与启动按住 | control / key_press_debouncer / live_threshold_control | control-result N=2/4/31，生产20ms参数代码核对；管脚由interface生成pinout复核 |
| C4 帧边界配置与字幕同步 | video_pair.frame_* / scan_memory / status_pixel | small/hud/full帧中配置变更；HUD文字、数字及状态逐像素 |
| C5 扫描连续与异常恢复 | 原桥接行标签/固定延迟/回退 | sim-fault、hud_fault、reset；full同步与实际串行化；periphery-check |

源码反查：control及两份复用按键模块对应C1/C3；status_pixel对应C4；video_pair变更对应C2/C4；顶层与peri/SDC对应C3/C5。相机、DDR、去马赛克及六个前端算法保持基线哈希。

构建修正仅涉及工程XML中design_file的顺序、peri XML中三个新增comp_gpio的位置；源数值行为未变，因此没有重复已通过且输入哈希相同的RTL仿真。
