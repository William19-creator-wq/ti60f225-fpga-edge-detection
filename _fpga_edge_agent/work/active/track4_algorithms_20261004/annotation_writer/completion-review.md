# 标注帧组件完成核对

本批生产RTL、真实存储协议测试、账本授权读回、独立字节与因果审计、Efinity组件综合已完成。整体赛题五基础/六高阶的整机软件目标仍未完成。

| 当前实际运行 | 图像/协议场景 | 比较像素 | 结果 |
|---|---:|---:|---|
| annotation_small_002，34×20 | 6帧＋27协议 | 4080 | 实际Questa＋独立审计PASS |
| annotation_min_001，4×2 | 6帧＋27协议 | 48 | 实际Questa＋独立审计PASS |
| annotation_hd_001，1920×1080 | 1完整帧 | 2073600 | 全1080行、全部头部/标签/尾部字节PASS |
| annotation_map_002 | 当前writer默认1080p | 不作为动态仿真 | 实际Efinity MAP退出0 |

合计67个场景、13帧、1212行、2077728比较像素。67次任务接纳与配置回执中，20次配置被拒且未启动写入；43次安全DONE；4次UNKNOWN工作没有安全DONE，只在共同冷复位后恢复。以上不能混为67次正常完成。

REQ与证据对应：

- AW01：10类坏配置在两种小尺寸均拒绝，无AW或DONE；正常任务由真实 R_WORKING 分配回执启动。合法字段不证明旧回执仍有权限，正式父控制器仍需只派发新鲜分配。
- AW02：正常帧66个512位头块全部由实际AW/4W/B写入；第66个回执前不接受body；两个头部身份/索引错误不发对应写请求。
- AW03：所有标签0..3、全3→全0、同slot重用无复位、位置/稀疏公式、body index/handle/last错误、尾部补零均验证。整帧连续打包，不按行pad。
- AW04：TB逐拍核查配置回执、RPC、DONE、AW/W/AR和像素输出的反压保持；独立日志只数真实fire，未将stall重复计数。
- AW05：header未接受RPC、实际W、等B、body公开RPC、private尾部、ack和同沿header/cancel等阶段的取消通过；旧handle取消忽略，原公开请求履约后才完成。
- AW06：头/body BRESP错误、错误优先于取消、头/body wrongBID未知闭合通过；UNKNOWN没有伪造drained或DONE。隔离恢复采用共同cold，不是单模块复位。安全DONE在有效期间不改正文。
- AW07：实际头部成功回执数、body接受数、成功body回执数、Result/scope/Origin、outcome/reason逐项比较。reason bit0保留；bit1头部格式、bit2body格式、bit3存储、bit4子cfg防御。
- AW08：独立Python从公开请求及AW/W/B重建ANN实际字节，再核对全头/全图/全部padding；从真实owner命令推导查询许可、核对returned bundle；严格核对每行最小A16读取范围、4KiB拆分、AR/R字节因果、每个输出所需字节已返回。R_WORKING/DONE查询拒绝，OFFERED/DISPLAY精确查询许可，错sequence/Origin拒绝。

完整1080p实际AW8166、W32664、B8166、AR9357、R437400。8166个写事务恰为66头部＋8100标签，每帧522624字节。完整场景4104724个数学后端时钟周期；本批没有真实DDR延迟或摄像头吞吐，因此不把该周期数声明为物理FPS。

综合资源从当前生成网表逐实例计数，并与实际map.rpt核对：2100 LUT4、1669 FF、52 ADD，无RAM/DSP。只是annotation_frame_writer组件；不能把组件资源简单相加认定全Ti60能装下。10ns SDC为组件预检输入，未完成PNR/STA，不宣称100MHz物理闭合。

警告完整保留：warn.log含3条EFX-0011 VERI-WARNING记录和1条EFX-0200；其中一条总结工具报告100个post-synthesis网表warning。X/Z输入检查在二值综合中为常真；不可当作物理四值检测。写模块不使用render颜色、retain字段及line_rdata，工具提示优化未使用端口。未把这些记录改称“零警告”。

失败和恢复：annotation_small_001在协议8真实TB watchdog退出1，C1修正测试gate/fault等待真实body阶段，未修改生产RTL或期望；annotation_map_001真实XML解析退出1，C2调整design_file元素顺序，第二次MAP通过。原源码snapshot和全部失败日志保留；所有当前运行末尾源hash均检查，没有运行期间修改实际仿真源码。

范围限制：Source/EDGE及其完成在本批是已声明夹具；ANN是真正写入。头部载荷是不透明数据运输，尚未实现复杂识别元数据生成。正式自动发布父控制器、相机CSI完整采集、共享显示总线/扫描整合、板载DDR模型/PHY动态资格、整机资源/FPS及最终引脚/CDC/PNR/STA/bit仍需后续继续。

理解验收暂无用户作答，待检验；正式数据库、Manifest/H0硬件状态不改，硬件下载及观察没有执行。资料、旧已登记组件保持原样。
